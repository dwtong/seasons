ZONE_LENGTH = 64 -- buffer zone per voice, factor of 2
ROLL_LENGTH = 8 -- pre/post roll at start and end of zones
MIN_LOOP_SIZE = 0.05 -- 50ms/20hz

voice = {}
local defaults = {
  PRE_LEVEL = 0.3,
  INPUT_LEVEL = 1.0,
  SEND_LEVEL = 0.0,
  REC_LEVEL = 1.0,
  LEVEL = 0.5
}

sync_rates = {}
for i=1,9 do sync_rates[i] = 1/(9-i) end -- 1/8 to 1/1
for i=1,7 do sync_rates[i+8] = i+1 end -- 1 to 8

local spec = {
  ZONE_START = controlspec.def{
    min=0, max=ZONE_LENGTH, warp='lin', step=0.1,
    default=0, quantum=0.001, wrap=false, units='s'
  },
  ZONE_LENGTH = controlspec.def{
    min=0.1, max=ZONE_LENGTH, warp='lin', step=0.1,
    default=ZONE_LENGTH, quantum=0.001, wrap=false, units='s'
  },
  FADE_TIME = controlspec.def{
    min=0, max=10, warp='lin', step=0.1,
    default=0.1, quantum=0.01, wrap=false, units='s'
  },
  SLEW = controlspec.def{
    min=0, max=60, warp='lin', step=0.1,
    default=0.5, quantum=0.001, wrap=false, units='s'
  },
  RESONANCE = controlspec.def{
    min=1, max=100, warp='exp', step=0.1,
    default=1, quantum=0.01, wrap=false
  },
}

function voice.setall(param, value)
  for v=1,4 do params:set(v..param, value) end
end

function voice.zone_start(v)
  -- FIXME surely this is inefficient
  zone = params.lookup[v.."zone"] and params:get(v.."zone") or v
  return (zone-1)*ZONE_LENGTH + zone*ROLL_LENGTH
end

function voice.zone_end(v) return voice.zone_start(v) + ZONE_LENGTH end
function voice.is_rec(v) return params:get(v.."togglerec") == 1 end

function voice.sync_rate(v)
  return sync_rates[params:get(v.."syncbase")] * sync_rates[params:get(v.."syncmult")] + params:get(v.."syncoffset")
end

function voice.init_softcut(v)
  print("init voice "..v.." softcut")
  sc.level_input_cut(1, v, defaults.INPUT_LEVEL)
  sc.level_input_cut(2, v, defaults.INPUT_LEVEL)

  sc.enable(v, 1)
  sc.buffer(v, 1)
  sc.play(v, 1)

  sc.level(v, defaults.LEVEL)
  sc.rate(v, 1.0)
  sc.pan(v, 0)
  sc.pre_level(v, defaults.PRE_LEVEL)
  sc.rec_level(v, defaults.REC_LEVEL)

  sc.loop(v, 1)
  sc.position(v, voice.zone_start(v))
  sc.loop_start(v, voice.zone_start(v))
  sc.loop_end(v, voice.zone_end(v))
  sc.rec(v, 1)

  sc.phase_quant(v, 0.05) -- adjust to change performance impact
  sc.event_phase(update_position)
  sc.poll_start_phase()

  for vdest=1, VOICE_COUNT do
    if vdest ~= v then sc.level_cut_cut(v, vdest, defaults.SEND_LEVEL) end
  end

  sc.post_filter_rq(v, 1)
  sc.post_filter_dry(v, 1)
  sc.post_filter_bp(v, 0)
  sc.post_filter_lp(v, 0)
  sc.post_filter_hp(v, 0)
end

function voice.init_params(v)
  print("init voice "..v.." params")
  params:add_group("voice "..v.." params", 39)

  params:add_separator("PLAY")

  params:add_control(v.."level", "level", controlspec.UNIPOLAR)
  params:set_action(v.."level", function(n)
    sc.level(v, n)
    param_callback(v.."level", n)
  end)
  params:set(v.."level", defaults.LEVEL)

  params:add_control(v.."levelslew", "level slew", spec.SLEW)
  params:set_action(v.."levelslew", function(n)
    sc.level_slew_time(v, n)
    param_callback(v.."levelslew", n)
  end)

  params:add_control(v.."pan", "pan", controlspec.PAN)
  params:set_action(v.."pan", function(n)
    sc.pan(v, n)
    param_callback(v.."pan", n)
  end)
  -- FIXME for testing
  -- pans = {-1.0, -0.5, 0.5, 1}
  -- params:set(v.."pan", pans[v])

  params:add_control(v.."panslew", "pan slew", spec.SLEW)
  params:set_action(v.."panslew", function(n)
    sc.pan_slew_time(v, n)
    param_callback(v.."panslew", n)
  end)

  params:add_number(v.."rate", "rate", -16, 16, 1)
  params:hide(v.."rate")
  params:set_action(v.."rate", function(n)
    print("set rate "..v.." to "..n)
    sc.rate(v, n)
  end)

  local function set_rate(callback_param)
    -- MusicUtil = require("musicutil")
    -- musicutil.interval_to_ratio (interval)
    -- FIXME probably incorrect calculations
    local oct = 2^params:get(v.."rateoct")
    local semi = 1/12*params:get(v.."ratesemi")*oct
    local detune = 0.1*params:get(v.."ratedetune")*oct
    local reverse = params:get(v.."togglereverse") == 1 and -1 or 1
    local rate = (oct + semi + detune) * reverse
    params:set(v.."rate", rate)
    param_callback(v..callback_param, n)
  end

  params:add_binary(v.."togglereverse", "toggle reverse (K3)", "toggle", 0)
  params:set_action(v.."togglereverse", function(n) set_rate("togglereverse") end)

  params:add_number(v.."rateoct", "rate (+oct)", -3, 3, 0)
  params:set_action(v.."rateoct", function(n) set_rate("rateoct") end)

  params:add_number(v.."ratesemi", "rate (+semi)", 0, 11, 0)
  params:set_action(v.."ratesemi", function(n) set_rate("ratesemi") end)

  params:add_number(v.."ratedetune", "rate (+detune)", 0, 100, 0)
  params:set_action(v.."ratedetune", function(n) set_rate("ratedetune") end)

  params:add_control(v.."rateslew", "rate slew", spec.SLEW)
  params:set_action(v.."rateslew", function(n)
    sc.rate_slew_time(v, n)
    param_callback(v.."rateslew", n)
  end)

  params:add_separator("REC")

  params:add_binary(v.."togglerec", "toggle rec (K3)", "toggle", 1)
  params:set_action(v.."togglerec",function(x)
    if x == 1 then
      sc.rec_level(v, params:get(v.."reclevel"))
      sc.pre_level(v, params:get(v.."prelevel"))
    else
      sc.rec_level(v, 0)
      sc.pre_level(v, 1.0) -- preserve current buffer contents
    end
  end)

  -- params:add_binary(v.."freeze", "freeze (K3)", "momentary", 0)
  -- params:set_action(v.."freeze",function(x)
  --   if x == 1 then
  --     -- set loop start, end to within x of current position
  --     -- somehow deal with position resets from clock
  --   else
  --     -- restore previous loop, position sync settings
  --   end
  -- end)

  params:add_control(v.."reclevel", "rec level", controlspec.UNIPOLAR)
  params:set(v.."reclevel", defaults.REC_LEVEL)
  params:set_action(v.."reclevel", function(n)
    if voice.is_rec(v) then sc.rec_level(v, n) end
  end)

  params:add_control(v.."prelevel", "pre level", controlspec.UNIPOLAR)
  params:set(v.."prelevel", defaults.PRE_LEVEL)
  params:set_action(v.."prelevel", function(n)
    if voice.is_rec(v) then sc.pre_level(v, n) end -- preserve all contents if not recording
    param_callback(v.."prelevel", n)
  end)

  params:add_control(v.."recslew", "rec/pre slew", spec.SLEW)
  params:set_action(v.."recslew", function(n)
    sc.recpre_slew_time(v, n)
    param_callback(v.."recslew", n)
  end)

  params:add_separator("FILTER")

  params:add_binary(v.."togglefilter", "toggle filter (K3)", "toggle", 1)
  params:set_action(v.."togglefilter",function(x)
    if x == 1 then
      local fc = params:get(v.."filter")
      filter.cutoff(v, fc)
    else
      sc.post_filter_dry(v, 1)
      sc.post_filter_lp(v, 0)
      sc.post_filter_bp(v, 0)
      sc.post_filter_hp(v, 0)
    end
  end)

  params:add_number(v.."filter", "filter cutoff", -100, 100, 0)
  params:set_action(v.."filter", function(n)
    filter.cutoff(v, n)
    param_callback(v.."filter", n)
  end)

  params:add_control(v.."filterq", "filter resonance", spec.RESONANCE)
  params:set_action(v.."filterq", function(n)
    sc.post_filter_rq(v, 1/n)
    param_callback(v.."filterq", n)
  end)

  -- FIXME default needs to be > 0
  params:add_control(v.."filterslew", "filter slew", spec.SLEW)
  params:set_action(v.."filterslew", function(n)
    filter.slew_time(v, n)
    param_callback(v.."filterslew", n)
  end)


  params:add_separator("LOOP")

  -- params:add_binary(v.."toggleloop", "toggle loop (K3)", "toggle", 1)
  -- params:set_action(v.."toggleloop",function(x)
  --   sc.loop(v, x)
  --   if x == 1 then
  --     -- FIXME ugh, do this a better way so it doesn't reset playhead position and loop
  --     params:set(v.."zone", params:get(v.."zone"))
  --   end
  -- end)

  params:add_number(v.."zone", "buffer zone", 1, 4, v)
  params:set_action(v.."zone", function(n)
    sc.position(v, voice.zone_start(n))
    sc.loop_start(v, voice.zone_start(n))
    sc.loop_end(v, voice.zone_end(n))
  end)

  params:add_trigger(v.."clearzone", "clear buffer zone")
  params:set_action(v.."clearzone", function()
    local z = params:get(v.."zone")
    sc.buffer_clear_region_channel(1, voice.zone_start(z) - ROLL_LENGTH, ZONE_LENGTH + 2 * ROLL_LENGTH, 1, 0)
  end)

  params:add_control(v.."loopstart", "loop start", spec.ZONE_START)
  params:set_action(v.."loopstart", function(n)
    local loop_start = voice.zone_start(v)+n
    local loop_end = loop_start+params:get(v.."looplength")
    sc.loop_start(v, loop_start)
    sc.loop_end(v, loop_end)
    param_callback(v.."loopstart", n)
  end)

  params:add_control(v.."looplength","loop length", spec.ZONE_LENGTH)
  params:set_action(v.."looplength", function(n)
    sc.loop_end(v, params:get(v.."loopstart")+n)
    param_callback(v.."looplength", n)
  end)

  params:add_control(v.."fadetime", "fade time", spec.FADE_TIME)
  params:set_action(v.."fadetime", function(n)
    sc.fade_time(v, n)
    param_callback(v.."fadetime", n)
  end)

  params:add_separator("CLOCK")

  params:add_option(v.."syncbase", "sync base", sync_rates, 8)
  params:add_option(v.."syncmult", "sync mult", sync_rates, 8)
  params:add_control(v.."syncoffset", "sync offset", controlspec.UNIPOLAR)

  params:add_separator("SENDS")

  params:add_control(v.."sendlevelall", "send to all level", controlspec.UNIPOLAR)
  params:set(v.."sendlevelall", defaults.SEND_LEVEL)
  params:set_action(v.."sendlevelall", function(n)
    for vdest=1, VOICE_COUNT do
      if vdest ~= v then
        params:set(v.."sendlevel"..vdest, n)
        if norns.menu.status() then _menu.rebuild_params() end
      end
    end
    param_callback(v.."sendlevelall", n)
  end)

  for vdest=1, VOICE_COUNT do
    if vdest ~= v then
      params:add_control(v.."sendlevel"..vdest, "send to voice "..vdest.." level", controlspec.UNIPOLAR)
      params:set(v.."sendlevel"..vdest, defaults.SEND_LEVEL)
      params:set_action(v.."sendlevel"..vdest, function(n) sc.level_cut_cut(v, vdest, n) end)
    end
  end

  params:add_separator("INPUT")

  params:add_control(v.."linputlevel", "ext input level L", controlspec.UNIPOLAR)
  params:set(v.."linputlevel", defaults.INPUT_LEVEL)
  params:set_action(v.."linputlevel", function(n) sc.level_input_cut(1, v, n) end)

  params:add_control(v.."rinputlevel", "ext input level R", controlspec.UNIPOLAR)
  params:set(v.."rinputlevel", defaults.INPUT_LEVEL)
  params:set_action(v.."rinputlevel", function(n) sc.level_input_cut(2, v, n) end)
end

function voice.init_actions(v)
  -- local sync = v
  -- clock.run(perform_action, actions.reset_head, sync, v)
  -- rates = s{v, s{v*5}:every(4)}
  -- rate_fn = s{v, v, v, v*4}

  -- action_fn = function ()
  --   local pos = voice.zone_start(v) + params:get(v.."loopstart")
  --   sc.position(v, pos)
  -- end

  -- rate_fn = function() return params:get(v.."syncrate") end
  -- offset_fn = function() return params:get(v.."syncoffset") end

  -- clock_sync_action(action_fn, rate_fn, offset_fn, v)
end

return voice

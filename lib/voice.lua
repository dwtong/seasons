ZONE_LENGTH = 64 -- buffer zone per voice, factor of 2
ROLL_LENGTH = 8 -- pre/post roll at start and end of zones
MIN_LOOP_SIZE = 0.05 -- 50ms/20hz

voice = {}
local defaults = {
  PRE_LEVEL = 0.5,
  INPUT_LEVEL = 1.0,
  SEND_LEVEL = 0.0,
  REC_LEVEL = 1.0,
  LEVEL = 0.0,
  FADE_AMOUNT = 0.25,
}

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
    default=0.5, quantum=0.01, wrap=false, units='s'
  },
  SLEW = controlspec.def{
    min=0, max=60, warp='lin', step=0.1,
    default=0.0, quantum=0.001, wrap=false, units='s'
  },
}

function voice.zone_start(v)
  -- FIXME surely this is inefficient
  zone = params.lookup[v.."zone"] and params:get(v.."zone") or v
  return (zone-1)*ZONE_LENGTH + zone*ROLL_LENGTH
end

function voice.zone_end(v) return voice.zone_start(v) + ZONE_LENGTH end
function voice.is_rec(v) return params:get(v.."togglerec") == 1 end

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
  params:add_group("voice "..v.." params", 36)

  params:add_separator("PLAY")

  params:add_control(v.."level", "level", controlspec.UNIPOLAR)
  params:set(v.."level", defaults.LEVEL)
  params:set_action(v.."level", function(n) sc.level(v, n) end)

  params:add_control(v.."levelslew", "level slew", spec.SLEW)
  params:set_action(v.."levelslew", function(n) sc.level_slew_time(v, n) end)

  params:add_control(v.."pan", "pan", controlspec.PAN)
  params:set_action(v.."pan", function(n) sc.pan(v, n) end)
  -- FIXME for testing
  pans = {-1.0, -0.5, 0.5, 1}
  params:set(v.."pan", pans[v])

  params:add_control(v.."panslew", "pan slew", spec.SLEW)
  params:set_action(v.."panslew", function(n) sc.pan_slew_time(v, n) end)

  params:add_number(v.."rate", "rate", 0.125, 16, 1)
  params:hide(v.."rate")
  params:set_action(v.."rate", function(n) sc.rate(v, n) end)

  local function set_rate(oct, semi, detune)
    oct = 2^oct
    local rate = oct + 1/12*semi*oct + 0.1*detune*oct
    params:set(v.."rate", rate)
  end

  params:add_number(v.."rateoct", "rate (+oct)", -3, 3, 0)
  params:set_action(v.."rateoct", function(n) set_rate(n, params:get(v.."ratesemi"), params:get(v.."ratedetune")) end)

  params:add_number(v.."ratesemi", "rate (+semi)", 0, 11, 0)
  params:set_action(v.."ratesemi", function(n) set_rate(params:get(v.."rateoct"), n, params:get(v.."ratedetune")) end)

  params:add_number(v.."ratedetune", "rate (+detune)", 0, 100, 0)
  params:set_action(v.."ratedetune", function(n) set_rate(params:get(v.."rateoct"), params:get(v.."ratesemi"), n) end)

  params:add_control(v.."rateslew", "rate slew", spec.SLEW)
  params:set_action(v.."rateslew", function(n) sc.rate_slew_time(v, n) end)

  params:add_control(v.."fadetime", "fade time", spec.FADE_TIME)
  params:set_action(v.."fadetime", function(n) sc.fade_time(v, n) end)

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

  params:add_control(v.."reclevel", "rec level", controlspec.UNIPOLAR)
  params:set(v.."reclevel", defaults.REC_LEVEL)
  params:set_action(v.."reclevel", function(n)
    if voice.is_rec(v) then sc.rec_level(v, n) end
  end)

  params:add_control(v.."prelevel", "pre level", controlspec.UNIPOLAR)
  params:set(v.."prelevel", defaults.PRE_LEVEL)
  params:set_action(v.."prelevel", function(n)
    if voice.is_rec(v) then sc.pre_level(v, n) end -- preserve all contents if not recording
  end)

  params:add_control(v.."recslew", "rec/pre slew", spec.SLEW)
  params:set_action(v.."recslew", function(n) sc.recpre_slew_time(v, n) end)

  params:add_separator("FILTER")

  params:add_binary(v.."togglefilter", "toggle filter (K3)", "toggle", 1)
  params:set_action(v.."togglefilter",function(x)
    if x == 1 then
      local fc = params:get(v.."filter")
      print(fc)
      filter.translate_fc_to_filters(v, fc)
    else
      sc.post_filter_dry(v, 1)
      sc.post_filter_lp(v, 0)
      sc.post_filter_bp(v, 0)
      sc.post_filter_hp(v, 0)
    end
  end)

  params:add_number(v.."filter", "filter cutoff", -100, 100, 0)
  params:set_action(v.."filter", function(n) filter.translate_fc_to_filters(v, n) end)

  params:add_number(v.."filterq", "filter resonance", 1, 100, 1)
  params:set_action(v.."filterq", function(n)
    sc.post_filter_rq(v, 1/n)
  end)

  params:add_separator("LOOP")

  params:add_binary(v.."toggleloop", "toggle loop (K3)", "toggle", 1)
  params:set_action(v.."toggleloop",function(x) sc.loop(v, x) end)

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
    sc.loop_start(v, loop_start)
    sc.loop_end(v, loop_start+params:get(v.."looplength"))
  end)

  params:add_control(v.."looplength","loop length", spec.ZONE_LENGTH)
  params:set_action(v.."looplength", function(n)
    sc.loop_end(v, params:get(v.."loopstart")+n)
  end)


  params:add_separator("CLOCK")

  -- TODO change test values
  params:add_control(v.."syncrate", "sync rate", spec.ZONE_LENGTH)
  params:set(v.."syncrate", v*3)

  -- TODO change test values
  params:add_control(v.."syncoffset", "sync offset", spec.ZONE_LENGTH)
  params:set(v.."syncoffset", v*0.2)

  params:add_separator("SENDS")

  params:add_control(v.."levelcutcutall", "send to all level", controlspec.UNIPOLAR)
  params:set(v.."levelcutcutall", defaults.SEND_LEVEL)
  params:set_action(v.."levelcutcutall", function(n)
    for vdest=1, VOICE_COUNT do
      if vdest ~= v then
        params:set(v.."levelcutcut"..vdest, n)
        if norns.menu.status() then _menu.rebuild_params() end
      end
    end
  end)

  for vdest=1, VOICE_COUNT do
    if vdest ~= v then
      params:add_control(v.."levelcutcut"..vdest, "send to voice "..vdest.." level", controlspec.UNIPOLAR)
      params:set(v.."levelcutcut"..vdest, defaults.SEND_LEVEL)
      params:set_action(v.."levelcutcut"..vdest, function(n) sc.level_cut_cut(v, vdest, n) end)
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

  action_fn = function ()
    local pos = voice.zone_start(v) + params:get(v.."loopstart")
    sc.position(v, pos)
  end

  rate_fn = function() return params:get(v.."syncrate") end
  offset_fn = function() return params:get(v.."syncoffset") end

  clock_sync_action(action_fn, rate_fn, offset_fn, v)
end

return voice

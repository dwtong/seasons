ZONE_LENGTH = 64 -- buffer zone per voice, factor of 2
ROLL_LENGTH = 8 -- pre/post roll at start and end of zones

voice = {}
local defaults = {
  PRE_LEVEL = 0.8,
  SEND_LEVEL = 0.0,
  REC_LEVEL = 1.0,
  LEVEL = 0.5,
  FADE_AMOUNT = 0.25
}

function voice.zone_start(v) return (v-1)*ZONE_LENGTH + v*ROLL_LENGTH end
function voice.zone_end(v) return v*ZONE_LENGTH + v*ROLL_LENGTH  end
function voice.is_rec(v) return params:get(v.."togglerec") == 1 end

function sync_time(v) return v*2-v*0.1 end

function voice.init_softcut(v)
  print("init voice "..v.." softcut")
  sc.level_input_cut(1, v, 1.0)
  sc.level_input_cut(2, v, 1.0)

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

  for vdest=1, VOICE_COUNT do
    if vdest ~= v then sc.level_cut_cut(v, vdest, defaults.SEND_LEVEL) end
  end

  -- nice filter defaults from halfsecond
  sc.filter_dry(v, 0.125);
  sc.filter_fc(v, 1200);
  sc.filter_lp(v, 0);
  sc.filter_bp(v, 1.0);
  sc.filter_hp(v, 0.0);
  sc.filter_rq(v, 2.0);
  sc.phase_quant(v, 0.05) -- adjust to change performance impact
  sc.event_phase(update_position)
  sc.poll_start_phase()
end

function voice.init_params(v)
  print("init voice "..v.." params")
  params:add_group("voice "..v, 13)

  params:add_separator("LEVELS")

  params:add_control(v.."pan", "pan", controlspec.PAN)
  params:set_action(v.."pan", function(n) sc.pan(v, n) end)
  -- for testing
  pans = {-1.0, -0.5, 0.5, 1}
  params:set(v.."pan", pans[v])

  -- TODO rec_rate and play_rate - option for play_rate to follow rec_rate
  -- params:add_option(v.."rate", v.." rate", rates, 10)
  params:add_control(v.."rate", "rate", controlspec.PAN)
  params:set_action(v.."rate", function(n) sc.rate(v, n) end)

  params:add_control(v.."level", "level", controlspec.UNIPOLAR)
  params:set(v.."level", defaults.LEVEL)
  params:set_action(v.."level", function(n) sc.level(v, n) end)

  params:add_control(v.."reclevel", "rec level", controlspec.UNIPOLAR)
  params:set(v.."reclevel", defaults.REC_LEVEL)
  params:set_action(v.."reclevel", function(n)
    if voice.is_rec(v) then sc.rec_level(v, n) end -- only adjust value if already recording
  end)

  params:add_control(v.."prelevel", "pre level", controlspec.UNIPOLAR)
  params:set(v.."prelevel", defaults.PRE_LEVEL)
  params:set_action(v.."prelevel", function(n)
    if voice.is_rec(v) then sc.pre_level(v, n) end -- preserve all contents if not recording
  end)

  params:add_control(v.."fadeamount", "fade amount", controlspec.UNIPOLAR)
  params:set_action(v.."fadeamount", function(n)
    -- TODO this function will also need to be called when changing the loop size - eventually won't use ZONE_LENGTH constant
    -- also need to take into account whether we are using position changes or loop changes - don't want a long loop but short position
    local fade_time = sync_time(v)*n
    sc.fade_time(v, fade_time) -- TODO fade time maps to clock rate
  end)
  params:set(v.."fadeamount", defaults.FADE_AMOUNT)

  params:add_separator("ACTIONS")

  params:add_binary(v.."togglerec", "toggle rec (K3)", "toggle", 1)
  params:set_action(v.."togglerec",function(x)
    if x == 1 then
      sc.rec_level(v, params:get(v.."reclevel"))
      sc.pre_level(v, params:get(v.."prelevel"))
      -- TODO reenable after adding rate params
      -- sc.rate(v, 1.0)
    else
      sc.rec_level(v, 0)
      sc.pre_level(v, 1.0) -- preserve current buffer contents
      -- TODO reenable after adding rate params
      -- sc.rate(v, params:get(v.."rate")) -- allows for pitch shifting when playing back
    end
  end)

  params:add_separator("SENDS")

  for vdest=1, VOICE_COUNT do
    if vdest ~= v then
      params:add_control(v.."levelcutcut"..vdest, "send to voice "..vdest.." level", controlspec.UNIPOLAR)
      params:set(v.."levelcutcut"..vdest, defaults.SEND_LEVEL)
      params:set_action(v.."levelcutcut"..vdest, function(n) sc.level_cut_cut(v, vdest, n) end)
    end
  end
end

function voice.init_actions(v)
  local sync = sync_time(v)
  clock.run(perform_action, actions.reset_head, sync, v)
end

return voice

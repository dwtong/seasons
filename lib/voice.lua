ZONE_LENGTH = 64 -- buffer zone per voice, factor of 2
ROLL_LENGTH = 8 -- pre/post roll at start and end of zones

voice = {}
local defaults = {
  PRE_LEVEL = 0.5,
  REC_LEVEL = 1.0,
  LEVEL = 0.6
}

function voice.zone_start(v) return (v-1)*ZONE_LENGTH + v*ROLL_LENGTH end
function voice.zone_end(v) return v*ZONE_LENGTH + v*ROLL_LENGTH  end
function sync_time(v) return v*8 end

function voice.init_softcut(v)
  sc.level_input_cut(1, v, 1.0)
  sc.level_input_cut(2, v, 1.0)

  sc.enable(v, 1)
  sc.buffer(v, 1)
  sc.fade_time(v, 0.01) -- TODO fade time maps to clock rate
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
  params:add_group("voice "..v, 7)

  params:add_control(v.."pan", v.." pan", controlspec.PAN)
  params:set_action(v.."pan", function(n) sc.pan(v, n) end)
  -- for testing
  -- pans = {-1.0, -0.5, 0.5, 1}
  -- params:set(v.."pan", pans[v])

  -- TODO rec_rate and play_rate - option for play_rate to follow rec_rate
  -- params:add_option(v.."rate", v.." rate", rates, 10)
  params:add_control(v.."rate", v.." rate", controlspec.PAN)
  params:set_action(v.."rate", function(n) sc.rate(v, n) end)

  params:add_control(v.."level", v.." level", controlspec.UNIPOLAR)
  params:set(v.."level", defaults.LEVEL)
  params:set_action(v.."level", function(n) sc.level(v, n) end)

  params:add_control(v.."reclevel", v.." rec level", controlspec.UNIPOLAR)
  params:set(v.."reclevel", defaults.REC_LEVEL)
  params:set_action(v.."reclevel", function(n) sc.rec_level(v, n) end)

  params:add_control(v.."prelevel", v.." pre level", controlspec.UNIPOLAR)
  params:set(v.."prelevel", defaults.PRE_LEVEL)
  params:set_action(v.."prelevel", function(n) sc.pre_level(v, n) end)

  params:add_control(v.."fadeamount", v.." fade amount", controlspec.UNIPOLAR)
  params:set_action(v.."fadeamount", function(n)
    -- TODO this function will also need to be called when changing the loop size - eventually won't use ZONE_LENGTH constant
    -- also need to take into account whether we are using position changes or loop changes - don't want a long loop but short position
    local fade_time = sync_time(v)*n
    sc.fade_time(v, fade_time) -- TODO fade time maps to clock rate
    print(v.." fade time: "..fade_time)
  end)
  params:set(v.."fadeamount", 1.0)

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
    -- TODO only call this when actually viewing the menu
    -- _menu.rebuild_params()
  end)
end

function voice.init_actions(v)
  local sync = sync_time(v)
  print(v.." sync time: "..sync)
  clock.run(perform_action, actions.reset_head, sync, v)
end

return voice

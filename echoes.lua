--- echoes
--
-- four tap clocked delay/looper

sc = softcut
voices = 4
zone_length = 60 -- buffer zone per voice
pans = {-1.0, -0.5, 0.5, 1}
default_pre = 0.5 -- TODO move to params

function init()
  audio.level_cut(1)
  audio.level_adc_cut(1)

  for v=1, voices do
    init_softcut(v)
    init_params(v)
    clock.run(reset_head, v)
  end

  -- TODO enable this after setting sane defaults
  -- params:bang()

  -- crow.input[1].mode("change", 2.0, 0.25, "rising")
  -- crow.input[2].mode("change", 2.0, 0.25, "rising")
  -- crow.input[1].change = toggle_freeze
  -- crow.input[2].change = flip_rate
end

function init_softcut(v)
  local start = (v-1) * zone_length

  sc.level_input_cut(1, v, 1.0)
  sc.level_input_cut(2, v, 1.0)

  sc.enable(v, 1)
  sc.buffer(v, 1)
  sc.level(v, 0.2)
  sc.play(v, 1)
  sc.rate(v, 1.0)
  sc.pan(v, 0)
  sc.loop(v, 1)
  sc.position(v, start)
  sc.loop_start(v, start)
  sc.loop_end(v, start + zone_length)
  sc.rec(v, 1)
  sc.rec_level(v, 1.0)
  sc.pre_level(v, default_pre)

  -- nice filter defaults from halfsecond
  sc.filter_dry(v, 0.125);
  sc.filter_fc(v, 1200);
  sc.filter_lp(v, 0);
  sc.filter_bp(v, 1.0);
  sc.filter_rq(v, 2.0);

  -- params for testing
  sc.pan(v, pans[v])
end

function init_params(v)
  params:add_separator("voice "..v)

  params:add_control(v.."pan", v.." pan", controlspec.PAN)
  params:set_action(v.."pan", function(n) sc.pan(v, n) end)

  -- TODO add sane rates
  -- params:add_option(v.."rate", v.." rate", rates, 10)
  params:add_control(v.."rate", v.." rate", controlspec.PAN)
  params:set_action(v.."rate", function(n) sc.rate(v, n) end)

  params:add_control(v.."level", v.." level", controlspec.DB)
  params:set_action(v.."level", function(n) sc.level(v, util.dbamp(n)) end)

  params:add_binary(v.."freeze", "freeze (K3)", "toggle", 0)
  params:set_action(v.."freeze",function(x)
    -- TODO handle rate changes when toggling freeze
    if x == 1 then
      sc.rec_level(v, 0)
      sc.pre_level(v, 1.0) -- preserve current buffer contents
    else
      sc.rec_level(v, 1.0)
      sc.pre_level(v, default_pre)
    end
    _menu.rebuild_params()
  end)
end

function reset_head(v)
  while true do
    -- TODO change playback rate
    clock.sync(v)
    -- TODO calculate correctly depending on rate etc
    -- if params:get(v.."rate") < 0 then
    --   position = vbuffer * v -- playing in reverse, start at end of buffer zone
    -- else
    --   position = vbuffer * v - vbuffer -- start at start of buffer zone
    -- end
    sc.position(v, (v-1) * zone_length)
  end
end

function toggle_freeze()
  for v=1, voices do
    local state = params:get(v.."freeze")
    params:set(v.."freeze", math.abs(state-1))
  end
end

function flip_rate()
  for v=1, voices do
    local rate = params:get(v.."rate")
    sc.rate(v, -rate)
  end
end


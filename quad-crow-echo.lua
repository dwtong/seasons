--- echoes
-- six voice free running delay

sc = softcut

offset = 1
voices = 4
vbuffer = sc.BUFFER_SIZE/voices

rates = {
  -4,
  -2,
  -1,
  -0.5,
  -0.25,
  -0.125,
  0.125,
  0.25,
  0.5,
  1,
  2,
  4
}


function init()
  audio.level_cut(1)
  audio.level_adc_cut(1)

  crow.input[1].change = toggle_freeze
  crow.input[1].mode("change", 2.0, 0.25, "rising")

  crow.input[1].change = flip_rate
  crow.input[1].mode("change", 2.0, 0.25, "rising")

  for v=1, voices do
    start = vbuffer * v - vbuffer

    sc.level_input_cut(1, v, 1.0)
    sc.level_input_cut(2, v, 1.0)
    sc.enable(v, 1)
    sc.buffer(v, 1)
    sc.level(v, 0.2)
    sc.play(v, 1)
    sc.rate(v, 1-0.01*v)
    sc.pan(v, -0.9 + v*0.25)
    sc.position(v, start)
    sc.loop(v, 1)
    sc.loop_start(v, start)
    sc.loop_end(v, start + vbuffer)
    sc.rec(v, 1)
    sc.rec_level(v, 1.0)
    sc.pre_level(v, 0.2)

    sc.post_filter_dry(v, 0)
    sc.post_filter_lp(v, 1)
    sc.post_filter_fc(v, 440)

    add_params(v)

    -- clock per voice
    clock.run(reset_heads, v)
  end

  params:bang()
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

function reset_heads(v)
  while true do
    clock.sync(1/v)

    if params:get(v.."rate") < 0 then
      position = vbuffer * v -- playing in reverse, start at end of buffer zone
    else
      position = vbuffer * v - vbuffer -- start at start of buffer zone
    end

    sc.position(v, position)
    -- print("reset "..v)
  end
end

function add_params(v)
  params:add_separator("voice "..v)

  params:add_control(v.."pan", v.." pan", controlspec.PAN)
  params:set_action(v.."pan", function(n) sc.pan(v, n) end)

  params:add_option(v.."rate", v.." rate", rates, 10)
  params:set_action(v.."rate", function(n) sc.rate(v, rates[n]) end)

  params:add_control(v.."level", v.." level", controlspec.DB)
  params:set_action(v.."level", function(n) sc.level(v, util.dbamp(n)) end)

  params:add_control(v.."filter", v.." filter", controlspec.FREQ)
  params:set_action(v.."filter", function(n) sc.post_filter_fc(v, n) end)

  params:add_binary(v.."freeze", "freeze", "toggle",1)
  params:set_action(v.."freeze",function(x)
    if x == 0 then
      sc.rec_level(v, 0)
      sc.pre_level(v, 1.0)
      -- sc.rate(v, params:get(v.."rate"))
      sc.rate(v, 2) -- rec at rate 1 to allow pitch shifting when toggling
    elseif x == 1 then
      sc.rec_level(v, 1.0)
      sc.pre_level(v, 0.2)
      sc.rate(v, 1.0) -- rec at rate 1 to allow pitch shifting when toggling
    end
    _menu.rebuild_params()
  end)

  -- params:add_binary(voice.."_rec_toggle", voice.." rec toggle (K3)", "toggle", 1)
  -- params:set_action("toggle",function(x)
  --   if x == 0 then
  --     sc.rec_level(v, 0)
  --     -- sc.pre_level(v, 0)
  --   elseif x == 1 then
  --     sc.rec_level(v, 1.0)
  --     -- sc.pre_level(v, 0.2)
  --   end
  --   _menu.rebuild_params()
  -- end)
end

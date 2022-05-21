--- echoes
--
-- four tap clocked delay/looper

s = require 'sequins'
sc = softcut

voices = 4
zone_length = 60 -- buffer zone per voice
pans = {-1.0, -0.5, 0.5, 1}
default_pre = 0.5 -- TODO move to params
voice_states = {}

function init()
  sc.buffer_clear()
  audio.level_cut(1)
  audio.level_adc_cut(1)

  for v=1, voices do
    init_softcut(v)
    init_params(v)
    clock.run(reset_head, v)

    -- params for testing
    if v == 1 then
      sc.pan(v, pans[v])
      sc.level(v, 0.8)
      voice_states[v] = {}
      voice_states[v].sfreeze = s{1,0}:every(v)
    end
  end

  -- TODO enable this after setting sane defaults
  -- params:bang()

  crow.input[1].mode("change", 2.0, 0.25, "rising")
  -- crow.input[2].mode("change", 2.0, 0.25, "rising")
  crow.input[1].change = toggle_freeze
  -- crow.input[2].change = flip_rate
end

function init_softcut(v)
  local start = (v-1) * zone_length

  sc.level_input_cut(1, v, 1.0)
  sc.level_input_cut(2, v, 1.0)

  sc.enable(v, 1)
  sc.buffer(v, 1)
  sc.level(v, 0.2)
  sc.fade_time(v, 0.5)
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
  sc.filter_hp(v, 0.0);
  sc.filter_rq(v, 2.0);
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
    if x == 1 then
      sc.rec_level(v, 0)
      sc.pre_level(v, 1.0) -- freeze current buffer contents
      sc.rate(v, -2)
      -- sc.rate(v, params:get(v.."rate")) -- allows for pitch shifting when frozen
    else -- record
      sc.rec_level(v, 1.0)
      sc.pre_level(v, default_pre)
      sc.rate(v, 1)
      -- sc.rate(v, 1.0)
    end
    _menu.rebuild_params()
  end)
end

function redraw()
  screen.clear()

  -- screen.move(10, voices*10+10)
  -- screen.text("rec position:")
  -- screen.move(118,voices*10+10)
  -- screen.text_right(string.format("%.2f", positions[5]))

  for v=1, voices do
    screen.move(10, v*10)
    screen.text(v.." frozen:")
    screen.move(118,v*10)
    local frozen = params:get(v.."freeze") == 1
    -- local state = if frozen then "play" else "rec" end
    screen.text_right(string.format('%q', frozen))
  end

  screen.move(10, voices*10+20)
  if trig_text then screen.text("trigger!") end

  screen.update()
end

function reset_head(v)
  while true do
    clock.sync(v)
    local zone_start = (v-1) * zone_length

    if params:get(v.."freeze") then--and params:get(v.."rate") < 0 then
      -- frozen and playing in reverse, start at end of buffer zone
      local position = zone_start + v/(clock.get_tempo()/60) -- TODO don't use 'v' for clock.sync
      sc.position(v, position)
    else
      -- start at start of buffer zone
      sc.position(v, zone_start)
    end
  end
end

function toggle_freeze()
  print("toggle freeze")
  for v=1, voices do
    voice_states[v].sfreeze()
    -- peek is a workaround because sfreeze() doesn't always return a number
    local state = voice_states[v].sfreeze:peek()
    -- local state = math.abs(params:get(v.."freeze")-1) -- flip between zero and one
    -- TODO for this to work, need to fix loop start/end based on rate
    -- if state == 1 then flip_rate(v) end
    params:set(v.."freeze", state)
  end

  clock.run(function()
    trig_text = true
    redraw()
    clock.sleep(0.2)
    trig_text = false
    redraw()
  end)
end

function flip_rate(v)
  -- for v=1, voices do
  local rate = params:get(v.."rate")
  sc.rate(v, -rate)
  -- end
end

function r()
  norns.script.load(norns.state.script)
end

--- echoes
--
-- four tap clocked delay/looper

s = require 'sequins'
voice = include 'lib/voice'
sc = softcut

VOICE_COUNT = 4
voices = {}

function init()
  sc.buffer_clear()
  audio.level_cut(1)
  audio.level_adc_cut(1)

  for v=1, VOICE_COUNT do
    voices[v] = { actions = {} }
    voice.init_softcut(v)
    voice.init_params(v)
    clock.run(reset_head, v)

    -- params for testing
    if v == 1 then
      -- pans = {-1.0, -0.5, 0.5, 1}
      -- params:set(v.."pan", pans[v])
      params:set(v.."pan", -1.0)
      params:set(v.."level", 0.9)
      voices[v].actions.toggle_rec = s{1,0}:every(v)
    end
  end

  -- TODO enable this after setting sane defaults
  -- params:bang()

  -- TODO crow init that also fires when plugged in
  crow.input[1].mode("change", 2.0, 0.25, "rising")
  -- crow.input[2].mode("change", 2.0, 0.25, "rising")
  crow.input[1].change = toggle_rec
  -- crow.input[2].change = flip_rate
end

function redraw()
  screen.clear()

  for v=1, #voices do
    screen.move(10, v*10)
    screen.text(v.." frozen:")
    screen.move(118,v*10)
    local frozen = params:get(v.."togglerec") == 1
    -- local state = if frozen then "play" else "rec" end
    screen.text_right(string.format('%q', frozen))
  end

  screen.move(10, #voices*10+20)
  if trig_text then screen.text("trigger!") end

  screen.update()
end

function reset_head(v)
  while true do
    clock_sync = v -- TODO param
    clock.sync(clock_sync)
    local recording = params:get(v.."togglerec") == 1
    local rate = params:get(v.."rate")

    if not recording and rate < 0 then
      print('play backwards')
      -- playing in reverse, start at end of buffer zone
      local position = voice.zone_start(v) + clock_sync/(clock.get_tempo()/60)
      sc.position(v, position)
    else
      -- start at start of buffer zone
      sc.position(v, voice.zone_start(v))
    end
  end
end

function toggle_rec()
  for v=1, #voices do
    voices[v].actions.toggle_rec()
    -- peek is a workaround because using sequins:every(x) doesn't always return a number
    local state = voices[v].actions.toggle_rec:peek()
    params:set(v.."togglerec", state)
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
  -- for v=1, #voices do
  local rate = params:get(v.."rate")
  sc.rate(v, -rate)
  -- end
end

function r()
  norns.script.load(norns.state.script)
end

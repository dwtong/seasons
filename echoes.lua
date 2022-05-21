--- echoes
--
-- four tap clocked delay/looper

s = require 'sequins'
Voice = include 'lib/voice'
sc = softcut

VOICE_COUNT = 4
pans = {-1.0, -0.5, 0.5, 1}
voices = {}

function init()
  sc.buffer_clear()
  audio.level_cut(1)
  audio.level_adc_cut(1)

  for v=1, VOICE_COUNT do
    voice = Voice.new(v)
    voices[v] = voice
    clock.run(reset_head, voice)

    -- params for testing
    sc.pan(v, pans[v])
    sc.level(v, 0.8)
    voices[v].sfreeze = s{1,0}:every(v)
  end

  -- TODO enable this after setting sane defaults
  -- params:bang()

  -- TODO crow init that also fires when plugged in
  crow.input[1].mode("change", 2.0, 0.25, "rising")
  -- crow.input[2].mode("change", 2.0, 0.25, "rising")
  crow.input[1].change = toggle_freeze
  -- crow.input[2].change = flip_rate
end

function redraw()
  screen.clear()

  for v=1, #voices do
    screen.move(10, v*10)
    screen.text(v.." frozen:")
    screen.move(118,v*10)
    local frozen = params:get(v.."freeze") == 1
    -- local state = if frozen then "play" else "rec" end
    screen.text_right(string.format('%q', frozen))
  end

  screen.move(10, #voices*10+20)
  if trig_text then screen.text("trigger!") end

  screen.update()
end

function reset_head(voice)
  while true do
    clock.sync(voice.clock_sync)

    if params:get(voice.id.."freeze") and params:get(voice.id.."rate") < 0 then
      -- frozen and playing in reverse, start at end of buffer zone
      local position = voice.zone_start + voice.clock_sync/(clock.get_tempo()/60)
      sc.position(voice.id, position)
    else
      -- start at start of buffer zone
      sc.position(voice.id, voice.zone_start)
    end
  end
end

function toggle_freeze()
  for v=1, #voices do
    voices[v].sfreeze()
    -- peek is a workaround because sfreeze() doesn't always return a number
    local state = voices[v].sfreeze:peek()
    -- local state = math.abs(params:get(v.."freeze")-1) -- flip between zero and one
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
  -- for v=1, #voices do
  local rate = params:get(v.."rate")
  sc.rate(v, -rate)
  -- end
end

function r()
  norns.script.load(norns.state.script)
end

--- echoes
--
-- four tap clocked delay/looper

s = require 'sequins'
voice = include 'lib/voice'
sc = softcut

VOICE_COUNT = 4
voices = {}
positions = {}

function init()
  sc.buffer_clear()
  audio.level_cut(1)
  audio.level_adc_cut(1)

  for v=1, VOICE_COUNT do
    voices[v] = { actions = {} }
    voice.init_softcut(v)
    voice.init_params(v)
    clock.run(reset_head, v)
    positions[v] = 0
    sc.phase_quant(v, 0.01) -- adjust to change performance impact
    sc.event_phase(update_positions)
    sc.poll_start_phase()

    -- params for testing
    -- if v == 1 then
      pans = {-1.0, -0.5, 0.5, 1}
      params:set(v.."pan", pans[v])
      -- params:set(v.."pan", -1.0)
      params:set(v.."level", 0.7)
      voices[v].actions.toggle_rec = s{1,0}:every(v)
      sc.fade_time(v, v/2) -- TODO fade time maps to clock rate
    -- end

  end
  -- TODO enable this after setting sane defaults
  -- params:bang()

  -- TODO crow init that also fires when plugged in
  crow.input[1].mode("change", 2.0, 0.25, "rising")
  -- crow.input[2].mode("change", 2.0, 0.25, "rising")
  crow.input[1].change = toggle_rec
  -- crow.input[2].change = flip_rate

  -- testing with jf
  sca = s{0,2,4,7,9}
  octave = s{0,0,0,1,1,1}
  crow.ii.jf.mode(1)
  clock.run(function ()
    i = 1
    while true do
      crow.ii.jf.play_note(sca()/12 + octave(), 5)
      clock.sync(1)
    end
  end)
end

function update_positions(i, pos)
  positions[i] = pos - 1
  redraw()
end

function redraw()
  screen.clear()
  for v=1, #voices do
    screen.move(10, v*10)
    screen.text(v.." position:")
    screen.move(118,v*10)
    screen.text_right(string.format("%.1f", positions[v] - voice.zone_start(v) + 1))
  end

  screen.move(10, #voices*10+20)
  if trig_text then screen.text("trigger!") end

  screen.update()
end

num = 1
dem = 8

function reset_head(v)
  while true do
    clock_sync = v - v*0.1 -- TODO param
    -- clock.sync(t, offset)
    print(clock_sync)
    clock.sync(clock_sync)
    -- local recording = params:get(v.."togglerec") == 1
    -- local rate = params:get(v.."rate")

    -- if not recording and rate < 0 then
    --   print('play backwards')
    --   -- playing in reverse, start at end of buffer zone
    --   -- TODO use clock.get_beat_sec() instead?
    --   local position = voice.zone_start(v) + clock_sync/(clock.get_tempo()/60)
    --   sc.position(v, position)
    -- else
    --   -- start at start of buffer zone
      sc.position(v, voice.zone_start(v))
    -- end
  end
end

function toggle_rec()
  for v=1, #voices do
    voices[v].actions.toggle_rec()
    -- peek is a workaround because using sequins:every(x) doesn't always return a number
    -- FIXME using peek will not "skip" values but rather "hold" them
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

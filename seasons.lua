--- seasons
--
-- time evolving sound // sound evolving time

s = require 'sequins'
voice = include 'lib/voice'
actions = include 'lib/actions'
cr = include 'lib/crow'
sc = softcut

VOICE_COUNT = 4
voices = {}

function init()
  sc.buffer_clear()
  audio.level_cut(1)
  audio.level_adc_cut(1)

  params:add_separator("VOICES")

  for v=1, VOICE_COUNT do
    voices[v] = {
      position = 0
    }
    voice.init_softcut(v)
    voice.init_params(v)
    voice.init_actions(v)
  end

  norns.crow.add = cr.init() -- crow

  -- testing with jf
  sca = s{0,2,4,7,9}
  octave = s{0,0,0,1,1,1}
  crow.ii.jf.mode(1)
  clock.run(function()
    i = 1
    while true do
      crow.ii.jf.play_note(sca()/12 + octave(), 2)
      clock.sync(1)
    end
  end)
end

function update_position(v, pos)
  voices[v].position = pos - 1
  redraw()
end

function perform_action(fn, rate, ...)
  while true do
    clock.sync(rate)
    fn(...)
  end
end

function redraw()
  screen.clear()
  for v=1, #voices do
    screen.move(10, v*10)
    screen.text(v.." position:")
    screen.move(118,v*10)
    screen.text_right(string.format("%.1f", voices[v].position - voice.zone_start(v) + 1))
  end

  screen.move(10, #voices*10+20)
  if cr.trig_text then screen.text("trigger!") end

  screen.update()
end

num = 1
dem = 8

function reset_head(v)
  while true do
    clock_sync = v - v*0.1 -- TODO param
    -- clock.sync(t, offset)
    clock.sync(clock_sync)
  end
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

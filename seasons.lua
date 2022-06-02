--- seasons
--
-- time evolving sound // sound evolving time

s = require 'sequins'
voice = include 'lib/voice'
actions = include 'lib/actions'
faderfox = include 'lib/faderfox'
filter = include 'lib/filter'
_crow = include 'lib/crow'
sc = softcut

-- testing
offset = 0

VOICE_COUNT = 4
voices = {}

function init()
  faderfox.init()

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

    -- testing
    clock.run(function()
      while true do
        local sync = sync_rates[params:get(v.."syncrate")]
        local offset = params:get(v.."syncoffset")
        sync = util.clamp(sync, 0.001, 100)
        clock.sync(sync + offset)
        actions.reset_loop(v)
      end
    end)
  end

  -- echo values to faderfox after setting up voice params
  faderfox.init_values()

  norns.crow.add = _crow.init -- crow
  _crow.init()

  midi.add = function(device)
    if device.name == "Faderfox EC4" then
      faderfox.init()
      faderfox.init_values()
    end
  end
end

function update_position(v, pos)
  voices[v].position = pos - 1
  redraw()
end

function param_callback(param_id, new_value)
  faderfox.echo(param_id, new_value)
end

function enc(n, d)
  if n == 1 then
    delta_all("level", d)
  elseif n == 2 then
    delta_all("filter", d)
  elseif n == 3 then
    delta_all("prelevel", d)
  end
end

function delta_all(param, delta, step)
  step = step or 1
  for v=1, #voices do
    params:delta(v..param, delta*step)
  end
end

-- callback functions can be sequins, or other functions that return values
function clock_sync_action(action_fn, rate_fn, offset_fn, ...)
  local args = ...

  return clock.run(function()
    while true do
      clock.sync(rate_fn() + offset_fn())
      action_fn(args)
    end
  end)
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
  if _crow.trig_text then screen.text("trigger!") end

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
  -- this won't work currently, need octave + semitone rate
  -- local rate = params:get(v.."rate")
  -- sc.rate(v, -rate)
  -- end
end

-- thanks @tyleretters
function re()
  norns.script.load(norns.state.script)
end


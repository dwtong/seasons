--- norns softcut loops synced with crow

sc = softcut

fade_time = 1
length = sc.BUFFER_SIZE

positions = {}
cut_points = {}
voices = 4 -- number of playheads, max 5

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

  sc.buffer_clear()

  for v=1, voices+1 do
    sc.enable(v, 1)
    sc.buffer(v, 1)

    sc.level(v, 0.0)
    sc.position(v, 1)
    sc.play(v, 1)
    sc.rate(v, 1)
    sc.loop(v, 1)
    sc.loop_start(v, 1)
    sc.loop_end(v, length)
    sc.fade_time(v, fade_time)
    sc.phase_quant(v, 0.005) -- adjust to change performance impact

    sc.post_filter_dry(v, 0)
    sc.post_filter_lp(v, 1)
    sc.post_filter_fc(v, 440)

    add_params(v)
    positions[v] = 0
    cut_points[v] = 0
  end

  -- last voice is rec voice
  rec_voice = voices + 1
  sc.level_input_cut(1, rec_voice, 1.0)
  sc.level_input_cut(2, rec_voice, 1.0)
  sc.rec(rec_voice, 1)
  sc.rec_level(rec_voice, 1.0)
  sc.pre_level(rec_voice, 0.0)

  sc.event_phase(update_positions)
  sc.poll_start_phase()

  crow.input[1].mode("change", 1, 0.1, "rising")
  crow.input[1].change = change

  -- -- testing
  -- sc.level(1, 0.3)
  -- sc.rate(1, 1.5)
  -- sc.pan(1, -1.0)
  -- sc.level(2, 0.3)
  -- sc.rate(2, -1.5)
  -- sc.pan(2, 1.0)
  -- sc.level(3, 0.3)
  -- sc.rate(3, 0.5)
  -- sc.pan(3, -0.5)
  -- sc.level(4, 0.3)
  -- sc.rate(4, -0.5)
  -- sc.pan(4, 0.5)
end

function update_positions(i, pos)
  positions[i] = pos - 1
  redraw()
end

rec_position = 0
prev_position = 0
trig_text = false
step = -1 -- needed to start at 1

function change(v, x)
  prev_position = rec_position
  rec_position = positions[voices+1]

  step = step % voices + 1

  for v=1, voices do
    if step == v then
      sc.position(v, prev_position)
      sc.loop_start(v, prev_position)
      sc.loop_end(v, rec_position)
      cut_points[v] = prev_position
    end
  end

  clock.run(function()
    trig_text = true
    clock.sleep(0.2)
    trig_text = false
  end)
end

function redraw()
  screen.clear()

    screen.move(10, voices*10+10)
    screen.text("rec position:")
    screen.move(118,voices*10+10)
    screen.text_right(string.format("%.2f", positions[5]))

  for v=1, voices do
    screen.move(10, v*10)
    screen.text(v.." cut:")
    screen.move(118,v*10)
    screen.text_right(string.format("%.2f", cut_points[v]))
  end

  screen.move(10, voices*10+20)
  if trig_text then screen.text("trigger!") end

  screen.update()
end

function add_params(voice)
  params:add_separator("voice "..voice)

  params:add_control(voice.."_pan", voice.." pan", controlspec.PAN)
  params:set_action(voice.."_pan", function(n) sc.pan(voice, n) end)

  -- params:add_control(voice.."_rate", voice.." rate", controlspec.RATE)
  params:add_option(voice.."_rate", voice.." rate", rates, 10)
  params:set_action(voice.."_rate", function(n) sc.rate(voice, rates[n]) end)

  params:add_control(voice.."_level", voice.." level", controlspec.DB)
  params:set_action(voice.."_level", function(n) sc.level(voice, util.dbamp(n)) end)

  params:add_control(voice.."_filter", voice.." filter", controlspec.FREQ)
  params:set_action(voice.."_filter", function(n) sc.post_filter_fc(voice, n) end)
end

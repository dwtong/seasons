--- delay based on softcut

-- IDEAS
-- multi voices
-- filters
-- position modulation
-- rate modulation
-- level modulation
-- overdubbing/feedback
-- fade time fun

sc = softcut
voices = 3

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

t1 = 1/4
t2 = 1
p = 1


default_rate = rates[10]

function init()
  -- external input into softcut
	audio.level_adc_cut(1)

  -- init voices
  for v=1,voices do
    sc.enable(v, 1)
    sc.buffer(v, 1)
    sc.level(v, 0.5)
    sc.voice_sync(1, v, 0)
    -- sc.level_slew_time(v,0.5)
  end

  -- voices looped playback
  for v=1,voices do
    -- add_params(v)

    sc.loop(v, 1)
    sc.loop_start(v, 1)
    sc.loop_end(v, sc.BUFFER_SIZE)
    -- sc.position(v, 1)
    sc.play(v, 1)
    -- sc.rate(v, default_rate)
    sc.rate(v, 1)
  end

  -- voice 1 rec
  sc.level_input_cut(1, 1 ,1.0)
  sc.rec(1, 1) -- enable recording on voice 1
  sc.rec_level(1, 1.0)
  sc.pre_level(1, 0.5) -- overdub/feedback level - 0 for none, 1.0 for full?

  -- voice 1 playback
  -- sc.pan(1, 1)
  -- sc.rate(1, 4)

  -- voice 2 playback
  sc.pan(2, -1)
  sc.pan(3, 1)
  -- sc.rate(2, 1)
  -- sc.voice_sync(1, 2, 1)
  
  sc.position(1, 3)
  sc.position(2, 2.5)
  sc.position(3, 1.5)

  -- voice 3 playback
  -- sc.pan(3, 1)
  sc.rate(2, 0.85)
  sc.rate(3, 0.5)


  -- voice 4 playback
  -- sc.pan(4, -0.2)
  -- sc.rate(4, -0.5)


  -- voice 5 playback
  -- sc.pan(5, 0.2)
  -- sc.rate(5, 0.5)
  
  -- clock.run(function()
  --   while true do
  --     sc.position(1, p)
  --     clock.sync(t1)
  --   end
  -- end)
  
  sc.event_position(function(v,p)
    print(v..":"..p)
  end)
  
  clock.run(function()
    while true do
      -- sc.position(2, p)
      -- print("======")
      query_position()
      clock.sync(t2)
    end
  end)
end

function query_position()
  print(sc.query_position(1))
  print(sc.query_position(2))
  print(sc.query_position(3))
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
end

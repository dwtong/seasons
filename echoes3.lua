--- echoes
-- four voice one bar clocked looper

sc = softcut

t = 4
offset = 1

function init()
  audio.level_cut(1)
  audio.level_adc_cut(1)
  sc.level_input_cut(1, 1, 1.0)
  sc.level_input_cut(2, 1, 1.0)
  
  sc.enable(1, 1)
  sc.buffer(1, 1)
  sc.level(1, 1.0)
  
  sc.position(1, 1)
  sc.play(1, 1)
  sc.rate(1, 1)
  sc.loop(1, 1)
  sc.loop_start(1, 1)
  sc.loop_end(1, sc.BUFFER_SIZE)
  
  sc.rec(1, 1)
  sc.rec_level(1, 1.0)
  sc.pre_level(1, 0.2)
  
  sc.enable(2, 1)
  sc.buffer(2, 1)
  sc.level(2, 1.0)
  
  sc.position(2, 1)
  sc.play(2, 1)
  sc.rate(2, 1)
  sc.pan(2, -1)
  sc.loop(2, 1)
  sc.loop_start(2, 1)
  sc.loop_end(2, sc.BUFFER_SIZE)
  sc.voice_sync(1, 2, 1)
  
  sc.enable(3, 1)
  sc.buffer(3, 1)
  sc.level(3, 1.0)
  
  sc.position(3, 1)
  sc.play(3, 1)
  sc.rate(3, 1)
  sc.pan(3, 1)
  sc.loop(3, 1)
  sc.loop_start(3, 1)
  sc.loop_end(3, sc.BUFFER_SIZE)
  sc.voice_sync(1, 3, 3)
  
  clock.run(reset_head)
end

function reset_head()
  while true do
    clock.sync(t)
    print("to 1!")
    -- sc.position(2, 1)
    -- sc.voice_sync(1, 2, offset)
    query_position()
  end
end

function query_position()
  print(sc.query_position(1))
  print(sc.query_position(2))
  print(sc.query_position(3))
end
--- echoes
-- four voice one bar clocked looper

sc = softcut

t = 4
offset = 1/4

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
  sc.rate(1, 0.95)
  sc.loop(1, 1)
  sc.loop_start(1, 1)
  sc.loop_end(1, sc.BUFFER_SIZE)
  
  sc.rec(1, 1)
  sc.rec_level(1, 1.0)
  sc.pre_level(1, 0.2)
  
  clock.run(reset_head)
end

function reset_head()
  while true do
    clock.sync(t - offset)
    print("to 1!")
    sc.position(1,1)
  end
end
--- echoes
-- six voice free running delay

sc = softcut

offset = 1
voices = 6
vbuffer = sc.BUFFER_SIZE/voices

function init()
  audio.level_cut(1)
  audio.level_adc_cut(1)
  
  for v=1, voices do
    start = vbuffer * v - vbuffer
    
    sc.level_input_cut(1, v, 1.0)
    sc.level_input_cut(2, v, 1.0)
    sc.enable(v, 1)
    sc.buffer(v, 1)
    sc.level(v, 0.2)
    sc.play(v, 1)
    sc.rate(v, 1-0.01*v)
    sc.pan(v, -0.9 + v*0.25)
    sc.position(v, start)
    sc.loop(v, 1)
    sc.loop_start(v, start)
    sc.loop_end(v, start + vbuffer)
    sc.rec(v, 1)
    sc.rec_level(v, 1.0)
    sc.pre_level(v, 0)
    
    -- clock per voice
    clock.run(reset_heads, v)
  end
end

function reset_heads(v)
  while true do
    clock.sleep(v*0.25)
    sc.position(v, vbuffer * v - vbuffer)
    print("reset "..v)
  end
end

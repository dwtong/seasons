--- echoes

sc = softcut
voices = 1

function init()
  print('hello')

  audio.level_cut(1)
  audio.level_adc_cut(1)

  for v=1, voices do
    sc.level_input_cut(1, v, 1.0)
    sc.level_input_cut(2, v, 1.0)

    sc.enable(v, 1)
    sc.buffer(v, 1)
    sc.level(v, 0.2)
    sc.play(v, 1)
    sc.rate(v, 1.0)
    sc.pan(v, 0)
    sc.position(v, 1)
    sc.loop(v, 1)
    sc.loop_start(v, 1)
    sc.loop_end(v, 1.2)
    sc.rec(v, 1)
    sc.rec_level(v, 1.0)
    sc.pre_level(v, 0.7)
  end
end

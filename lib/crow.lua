_crow = {}

_crow.trig_text = false

function _crow.init()
  crow.reset()
  print("init crow")
  crow.input[1].mode("change", 2.0, 0.25, "rising")
  -- crow.input[2].mode("stream")
end

crow.input[1].change = function()
  trig_text = true
  redraw()
  clock.sleep(0.2)
  trig_text = false
  redraw()
end


return _crow

action_fn = function(v) sc.position(v, voice.zone_start(v) + params:get(v.."loopstart")) end
clock.run(function() while true do for v=1,4 do clock.sleep(v); action_fn(v) end end end)

new_clock = clock.run(function()
  while true do -- repeat indefinitely, could also set number of repeats
    clock.sync(1/4) -- set sync time, this could be parameterised or sequins'd
    actions.reset_position(v)
  end
end)


oct = s{-1,0,2,1,2,0,0}
c1 = clock.run(function() while true do clock.sync(1/5); actions.reset_loop(1) end end)
c2 = clock.run(function() while true do clock.sleep(3); actions.flip_filter(1) end end)
c3 = clock.run(function() while true do clock.sleep(3); actions.flip_pan(1) end end)
c4 = clock.run(function() while true do clock.sync(2); actions.seq_rate_oct(1, oct) end end)


crow.ii.jf.mode(1)
sca = s{0,2,4,7,9}
oct = s{0,0,0,1,1,1}
vel = 2
cjf = clock.run(function() while true do actions.play_note(sca, oct, vel); clock.sync(1) end end)

actions = {}

function actions.reset_loop(v, length)
  local position = voice.zone_start(v) + params:get(v.."loopstart")
  if params:get(v.."ratereverse") == 1 then position = position + length end
  sc.position(v, position)
end

function actions.toggle_rec(v)
  local state = math.abs(params:get(v.."togglerec") - 1)
  params:set(v.."togglerec", state)
end

function actions.reverse(v)
  local state = params:get(v.."")
  params:set(v.."togglerec", state)
end

function actions.flip_pan(v)
  params:set(v.."pan", -params:get(v.."pan"))
end

function actions.toggle_filter(v)
  local state = math.abs(params:get(v.."togglefilter") - 1)
  params:set(v.."togglefilter", state)
end

function actions.flip_filter(v)
  params:set(v.."filter", -params:get(v.."filter"))
end

function actions.seq_rate_oct(v, seq)
  params:set(v.."rateoct", seq())
end

crow.ii.jf.mode(1)
-- sca = s{0,2,4,7,9}
-- oct = s{0,0,0,1,1,1}
oct = s{0}
sca = s{0}
vel = 2
function actions.play_note(sca, oct, vel)
  crow.ii.jf.play_note(sca()/12 + oct(), vel)
end

return actions

actions = {}

function actions.reset_loop(v)
  sc.position(v, voice.zone_start(v) + params:get(v.."loopstart"))
end

function actions.toggle_rec(v)
  local state = math.abs(params:get(v.."togglerec") - 1)
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

return actions

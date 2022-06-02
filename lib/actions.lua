actions = {}

local function toggle_param(v, param)
  local state = math.abs(params:get(v..param) - 1)
  params:set(v..param, state)
end

local function flip_param(v, param)
  params:set(v..param, -params:get(v..param))
end

local function sequence_param(v, param, seq)
  params:set(v..param, seq())
end

function actions.reset_loop(v, length)
  local position = voice.zone_start(v) + params:get(v.."loopstart")
  if params:get(v.."togglereverse") == 1 then position = position + length end
  sc.position(v, position)
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

function actions.toggle_rec(v) toggle_param(v, "togglerec") end
function actions.toggle_reverse(v) toggle_param(v, "togglereverse") end
function actions.toggle_filter(v) toggle_param(v, "togglefilter") end

function actions.flip_filter(v) flip_param(v, "filter") end
function actions.flip_pan(v) flip_param(v, "pan") end

return actions

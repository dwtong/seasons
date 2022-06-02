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

local function reset_loop(v, length)
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
function play_note(sca, oct, vel)
  crow.ii.jf.play_note(sca()/12 + oct(), vel)
end

local function toggle_rec(v) toggle_param(v, "togglerec") end
local function toggle_reverse(v) toggle_param(v, "togglereverse") end
local function toggle_filter(v) toggle_param(v, "togglefilter") end

local function flip_filter(v) flip_param(v, "filter") end
local function flip_pan(v) flip_param(v, "pan") end

return {
  reset_loop = reset_loop,
  play_note = play_note,
  toggle_rec = toggle_rec,
  toggle_reverse = toggle_reverse,
  toggle_filter = toggle_filter,
  flip_filter = flip_filter,
  flip_pan = flip_pan
}

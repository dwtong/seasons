actions = {}

local function toggle_param(v, param)
  if v then
    local state = math.abs(params:get(v..param) - 1)
    params:set(v..param, state)
  else
    for v=1,VOICE_COUNT do toggle_param(v, param) end
  end
end

local function flip_param(v, param)
  if v then
    params:set(v..param, -params:get(v..param))
  else
    for v=1,VOICE_COUNT do flip_param(v, param) end
  end
end

local function sequence_param(v, param, seq)
  if v then
    params:set(v..param, seq())
  else
    for v=1,VOICE_COUNT do sequence_param(v, param, seq) end
  end
end

function actions.reset_loop(v, length)
  if v then
    local position = voice.zone_start(v) + params:get(v.."loopstart")
    if params:get(v.."togglereverse") == 1 then position = position + length end
    sc.position(v, position)
  else
    for v=1,VOICE_COUNT do actions.reset_loop(v, length) end
  end
end

function actions.toggle_rec(v) toggle_param(v, "togglerec") end
function actions.toggle_mute(v) toggle_param(v, "togglemute") end
function actions.toggle_reverse(v) toggle_param(v, "togglereverse") end
function actions.toggle_filter(v) toggle_param(v, "togglefilter") end

function actions.flip_filter(v) flip_param(v, "filter") end
function actions.flip_pan(v) flip_param(v, "pan") end

return actions

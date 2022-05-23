actions = {}

function actions.reset_head(v, position)
  position = position or voice.zone_start(v)
  -- local recording = params:get(v.."togglerec") == 1
  -- local rate = params:get(v.."rate")

  -- if not recording and rate < 0 then
  --   print('play backwards')
  --   -- playing in reverse, start at end of buffer zone
  --   -- TODO use clock.get_beat_sec() instead?
  --   local position = voice.zone_start(v) + clock_sync/(clock.get_tempo()/60)
  --   sc.position(v, position)
  -- else
  --   -- start at start of buffer zone
  -- end
  sc.position(v, position)
end

function actions.toggle_rec(v)
  -- TODO should call this something better than actions
  -- local state= voices[v].actions.toggle_rec()
  -- workaround: using sequins:every returns an empty table on 'skip' states
  -- if type(state) == 'number' then
  --   params:set(v.."togglerec", state)
  -- end

  local state = math.abs(params:get(v.."togglerec") - 1)
  params:set(v.."togglerec", state)
end

return actions

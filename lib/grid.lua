_grid = {}
_grid.dirty = true
g = grid.connect()

local toggled = {}
for x=1,16 do
  toggled[x] = {}

  for y=1,8 do
    toggled[x][y] = 0
  end
end

local callbacks = {}
for x=1,16 do callbacks[x] = {} end

alt = false
pos = {1,1,1,1}
bright = {1,1,1,1}

function _grid.init()
  clock.run(grid_redraw_clock)

  for v=1,4 do
    clock.run(function()
      while true do
        pos[v] = pos[v] % 4 + 1
        for b=1,10 do
          bright[v] = b
          local steps = 10 * 4 -- 9 levels of brightness, 4 buttons
          clock.sync(voice.sync_rate(v)/steps)
          _grid.dirty = true
        end
      end
    end)
  end

  for v=1,4 do
    x = (v-1)*4+1
    callbacks[x][2] = function(state)
      if alt then actions.toggle_rec() else actions.toggle_rec(v) end
    end

    callbacks[x+1][2] = function(state)
      if alt then actions.toggle_mute() else actions.toggle_mute(v) end
    end
  end
end

function grid_redraw_clock()
  while true do
    if _grid.dirty then
      grid_redraw()
      _grid.dirty = false
    end
    clock.sleep(1/30)
  end
end

function grid_redraw()
  -- ticker
  for v=1,4 do
    offset = (v-1)*4
    for x = 1,4 do
      local brt = 1
      if x == pos[v] - 1 then brt = 10 - bright[v] end
      if x == 4 and pos[v] == 1 then brt = 10 - bright[v] end
      if x == pos[v] then brt = 10 end
      g:led(x+offset, 1, brt)
    end
  end

  -- rec
  for v=1,4 do
    x = (v-1)*4+1
    local brt = voice.is_rec(v) and 10 or 6
    g:led(x, 2, brt)
  end

  -- mutes
  for v=1,4 do
    x = (v-1)*4+2
    local brt = voice.is_muted(v) and 6 or 10
    g:led(x, 2, brt)
  end


  local brt = alt and 8 or 4
  g:led(1, 8, brt)

  g:refresh()
end

function toggle(x, y)
  new = math.abs(toggled[x][y] - 1)
  toggled[x][y] = new
  _grid.dirty = true

  return new
end

function g.key(x, y, z)
  -- print(x..' '..y..' '..z)

  if x == 1 and y == 8 then alt = (z == 1) end

  if z == 1 then
    state = toggle(x, y)
    if callbacks[x][y] then callbacks[x][y](state) end
  end

  _grid.dirty = true
end

return _grid

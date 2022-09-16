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

local alt = false

function _grid.init()
  clock.run(grid_redraw_clock)

  for v=1,4 do
    x = (v-1)*4+1
    callbacks[x][2] = function(state)
      if alt then
        actions.toggle_rec()
      else
        actions.toggle_rec(v)
      end
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
  -- zones
  for x=1,16 do
    brt = 4
    g:led(x, 1, 4)
  end

  -- selected zones
  g:led(1, 1, 8)
  g:led(6, 1, 8)
  g:led(11, 1, 8)
  g:led(16, 1, 8)

  -- rec
  for v=1,4 do
    x = (v-1)*4+1
    local brt = voice.is_rec(v) and 10 or 6
    g:led(x, 2, brt)
  end

  -- mutes
  for v=1,4 do
    x = (v-1)*4+2
    local brt = 6
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

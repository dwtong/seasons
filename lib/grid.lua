_grid = {}
g = grid.connect()

function _grid.init()
  grid_dirty = false

  toggled = {} -- meta-table to track the state of the grid keys
  brightness = {} -- meta-table to track the brightness of each grid key
  counter = {} -- meta-table to hold counters to distinguish between long and short press
  for x = 1,16 do -- for each x-column (16 on a 128-sized grid)...
    toggled[x] = {} -- create an x state tracker,
    brightness[x] = {} -- create an x brightness,
    counter[x] = {} -- create a x state counter.
    for y = 1,8 do -- for each y-row (8 on a 128-sized grid)...
      toggled[x][y] = false -- create a y state tracker,
      brightness[x][y] = 15 -- create a y brightness.
      -- counters don't need futher initialization because they start as nil...
      -- counter[x][y] = nil
    end
  end

  clock.run(grid_redraw_clock)
end

function g.key(x,y,z)
  if z == 1 then -- if a grid key is pressed...
    counter[x][y] = clock.run(long_press,x,y) -- start the long press counter for that coordinate!
  elseif z == 0 then -- otherwise, if a grid key is released...
    if counter[x][y] then -- and the long press is still waiting...
      clock.cancel(counter[x][y]) -- then cancel the long press clock,
      short_press(x,y) -- and execute a short press instead.
    end
  end
end

function short_press(x,y) -- define a short press
  if not toggled[x][y] then -- if the coordinate isn't toggled...
    toggled[x][y] = true -- toggle it on,
    brightness[x][y] = 8 -- set brightness to half.
  elseif toggled[x][y] and brightness[x][y] == 8 then -- if the coordinate is toggled and half-bright
    toggled[x][y] = false -- toggle it off.
    -- we don't need to set the brightness to 0, because off LED will not be turned back on once we redraw
  end
  grid_dirty = true -- flag for redraw
end

function long_press(x,y) -- define a long press
  clock.sleep(0.5) -- a long press waits for a half-second...
  -- then all this stuff happens:
  if toggled[x][y] then -- if key is toggled, then...
    brightness[x][y] = brightness[x][y] == 15 and 8 or 15 -- flip brightness 8->15 or 15->8.
  end
  counter[x][y] = nil -- clear the counter
  grid_dirty = true -- flag for redraw
end

function grid_redraw()
  g:all(0)
  for x = 1,16 do
    for y = 1,8 do
      if toggled[x][y] then -- if coordinate is toggled on...
        g:led(x,y,brightness[x][y]) -- set LED to coordinate at specified brightness.
      end
    end
  end
  g:refresh()
end

function grid_redraw_clock()
  while true do
    if grid_dirty then
      grid_redraw()
      grid_dirty = false
    end
    clock.sleep(1/30)
  end
end

return _grid

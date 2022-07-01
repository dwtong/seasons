_grid = {}
g = grid.connect()

i = 1
bright = 4

local function quadrant_offset(quadrant)
  if quadrant == 1 then
    return 0, 0
  elseif quadrant == 2 then
    return 8, 0
  elseif quadrant == 3 then
    return 0, 4
  elseif quadrant == 4 then
    return 8, 4
  end
end

local function quadrant(x, y)
  if x > 8 and y > 4 then
    return 4
  elseif y > 4 then
    return 3
  elseif x > 8 then
    return 2
  else
    return 1
  end
end

local function qled(x, y, quadrant, brightness)
  local offset_x, offset_y = quadrant_offset(quadrant)
  g:led(x + offset_x, y + offset_y, brightness)
end

function _grid.init()
  grid_dirty = true
  clock.run(grid_redraw_clock)

  clock.run(function()
    while true do
      i = i % 8 + 1
      for b=4,8 do
        bright = b
        clock.sleep(0.1)
        grid_dirty = true
      end
      clock.sleep(0.5)
    end
  end)
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

function grid_redraw()
  for q=1,4 do
    local offset_x, offset_y = quadrant_offset(q)
    for x = 1,8 do
      local brt = 4
      if x < i then brt = 8 end
      if x == i then brt = bright end
      qled(x, 1, q, brt)
    end -- ticker

    -- if q == 1 or q == 3 then -- left side
      for x = 1,3 do qled(x, 2, q, 6) end -- sc rates
      for x = 5,7 do qled(x, 2, q, 6) end -- pan
      for x = 1,2 do qled(x, 3, q, 6) end
      for x = 5,6 do qled(x, 3, q, 6) end
    -- else --right side
    --   for x = 2,4 do qled(x, 2, q, 6) end -- sc rates
    --   for x = 6,8 do qled(x, 2, q, 6) end -- pan
    --   for x = 3,4 do qled(x, 3, q, 6) end
    --   for x = 7,8 do qled(x, 3, q, 6) end
    -- end

    qled(1, 4, 3, 9) -- alt key
  end

  g:refresh()
end

function g.key(x, y, z)
  print(x..' '..y..' '..z)
end

return _grid

-- function _grid.init()
--   grid_dirty = false

--   toggled = {} -- meta-table to track the state of the grid keys
--   brightness = {} -- meta-table to track the brightness of each grid key
--   counter = {} -- meta-table to hold counters to distinguish between long and short press
--   for x = 1,16 do -- for each x-column (16 on a 128-sized grid)...
--     toggled[x] = {} -- create an x state tracker,
--     brightness[x] = {} -- create an x brightness,
--     counter[x] = {} -- create a x state counter.
--     for y = 1,8 do -- for each y-row (8 on a 128-sized grid)...
--       toggled[x][y] = false -- create a y state tracker,
--       brightness[x][y] = 15 -- create a y brightness.
--       -- counters don't need futher initialization because they start as nil...
--       -- counter[x][y] = nil
--     end
--   end

--   clock.run(grid_redraw_clock)
-- end

-- function g.key(x,y,z)
--   if z == 1 then -- if a grid key is pressed...
--     counter[x][y] = clock.run(long_press,x,y) -- start the long press counter for that coordinate!
--   elseif z == 0 then -- otherwise, if a grid key is released...
--     if counter[x][y] then -- and the long press is still waiting...
--       clock.cancel(counter[x][y]) -- then cancel the long press clock,
--       short_press(x,y) -- and execute a short press instead.
--     end
--   end
-- end

-- function short_press(x,y) -- define a short press
--   if not toggled[x][y] then -- if the coordinate isn't toggled...
--     toggled[x][y] = true -- toggle it on,
--     brightness[x][y] = 8 -- set brightness to half.
--   elseif toggled[x][y] and brightness[x][y] == 8 then -- if the coordinate is toggled and half-bright
--     toggled[x][y] = false -- toggle it off.
--     -- we don't need to set the brightness to 0, because off LED will not be turned back on once we redraw
--   end
--   grid_dirty = true -- flag for redraw
-- end

-- function long_press(x,y) -- define a long press
--   clock.sleep(0.5) -- a long press waits for a half-second...
--   -- then all this stuff happens:
--   if toggled[x][y] then -- if key is toggled, then...
--     brightness[x][y] = brightness[x][y] == 15 and 8 or 15 -- flip brightness 8->15 or 15->8.
--   end
--   counter[x][y] = nil -- clear the counter
--   grid_dirty = true -- flag for redraw
-- end

-- function grid_redraw()
--   g:all(0)
--   for x = 1,16 do
--     for y = 1,8 do
--       if toggled[x][y] then -- if coordinate is toggled on...
--         g:led(x,y,brightness[x][y]) -- set LED to coordinate at specified brightness.
--       end
--     end
--   end
--   g:refresh()
-- end

-- function grid_redraw_clock()
--   while true do
--     if grid_dirty then
--       grid_redraw()
--       grid_dirty = false
--     end
--     clock.sleep(1/30)
--   end
-- end

-- return _grid

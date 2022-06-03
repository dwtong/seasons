view = {}
voice_options = {'1', '2', '3', '4', '*'}
selected_voice = 1

view.pages = {
  'loops',
  'levels',
  'filters',
  'actions',
  'clock',
  'crow',
  'lfo'
}

view.active_page = 1
view.menu_level = 2
-- view.list_position = 1

-- FONTS (f=face, s=size)
-- main menu
-- f44 s14
-- f43 s14

-- local function draw_main_menu()
-- end


local function visible_page_list()
  local visible_pages = {}
  local min, max = 1, 4

  if view.active_page > 4 then
    min, max = 5, 8
  end

  for i=min,max do
    table.insert(visible_pages, view.pages[i])
  end

  return visible_pages
end

local function draw_list_menu()
  screen.font_face(1)
  screen.font_size(8)
  local page_list = visible_page_list()

  -- screen.level(5)
  -- screen.move(38, 0)
  -- screen.line(38, 63)
  -- screen.stroke()

  for i, page in ipairs(page_list) do
    screen.level(5)

    if page == view.pages[view.active_page] then
      screen.rect(0, i*12-7+i, 35, 10)
      screen.level(5)
      if view.menu_level == 2 then
        screen.fill()
        screen.move(4, i*13)
        screen.level(0)
      elseif view.menu_level == 3 then
        screen.stroke()
        screen.move(4, i*13)
        screen.level(5)
      end
      screen.text(page)
    else
      screen.move(4, i*13)
      screen.text(page)
    end
  end
end

local function draw_page()
  print(view.pages[view.active_page])
  screen.font_face(38)
  screen.font_size(18)
  screen.level(5)
  screen.move(60, 30)
  screen.text(view.pages[view.active_page])
end

function view.redraw()
  screen.clear()

  if menu_level == 1 then
    -- draw_main_menu()
  else
    draw_list_menu()
    draw_page()
  end

  screen.update()
end

return view

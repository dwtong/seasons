view = {}
voice_options = {'1', '2', '3', '4', '*'}
selected_voice = 1

view.pages = {
  'loops',
  'levels',
  'filters',
  'actions'
}

view.active_page = 1
view.menu_level = 2

-- FONTS (f=face, s=size)
-- main menu
-- f44 s14
-- f43 s14

-- local function draw_main_menu()
-- end

local function draw_list_menu()
  screen.font_face(1)
  screen.font_size(8)

  for i, page in ipairs(view.pages) do
    screen.level(5)

    if i == view.active_page then
      screen.rect(2, i*12-7+i, 33, 10)
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

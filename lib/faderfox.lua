ff = {}
cc_map = {
  level = 1,
  pan = 2,
  rateoct = 3,
  filter = 4
}


local function init()
  -- workaround: sometimes midi.devices table has empty values, so #midi.devices doesn't work
  for i=1,16 do
    if midi.devices[i] and midi.devices[i].name == "Faderfox EC4" then
      print("connecting faderfox")
      -- FIXME don't hardcode this to midi device one
      ff = midi.connect()
    end
  end

end

local function echo(param_id, new_value)
  if ff then
    local p_voice = string.sub(param_id, 1, 1)
    local p_name = string.sub(param_id, 2, -1)
    local range = params:get_range(param_id)
    local val = math.floor(util.linlin(range[1], range[2], 0, 127, new_value))

    print("ch: "..p_voice..", cc: "..cc_map[p_name].." val: "..val)
    -- cc, value, midi channel
    ff:cc(cc_map[p_name], val, p_voice)
  end
end

local function init_values()
  if ff then
    print("attempting to init values")
    print(cc_map)
    for name, cc in pairs(cc_map) do
      for v=1, VOICE_COUNT do
        print("init "..name..v)
        local param_id = v..name
        local new_value = params:get(param_id)
        echo(param_id, new_value)
      end
    end
  else
    print("faderfox not detected")
  end
end

  return {
    init = init,
    echo = echo,
    is_present = is_present,
    init_values = init_values
  }

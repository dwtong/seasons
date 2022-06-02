ff = {}
cc_map = {
  -- ff group 1
  level = 1,
  pan = 2,
  prelevel = 3,
  sendlevelall = 4,

  -- ff group 2
  loopstart = 5,
  looplength = 6,
  fadetime = 7,
  clockoffset = 8,

  -- ff group 3
  filter = 9,
  filterq = 10,
  filterslew = 11,
  -- filtertype = 12,

  -- ff group 4
  levelslew = 13,
  recslew = 14,
  panslew = 15,
  -- rateslew = 16,
}

local connected = false

local function init()
  -- workaround: sometimes midi.devices table has empty values, so #midi.devices doesn't work
  for i=1,16 do
    if midi.vports[i] and midi.vports[i].name == "Faderfox EC4" then
      print("connecting faderfox")
      -- FIXME don't hardcode this to midi device one
      ff = midi.connect()
      connected = true
    end
  end

end

local function echo(param_id, new_value)
  if connected then
    local p_voice = string.sub(param_id, 1, 1)
    local p_name = string.sub(param_id, 2, -1)
    local range = params:get_range(param_id)
    local val = math.floor(util.linlin(range[1], range[2], 0, 127, new_value))

    -- cc, value, midi channel
    ff:cc(cc_map[p_name], val, p_voice)
  end
end

local function init_values()
  if connected then
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

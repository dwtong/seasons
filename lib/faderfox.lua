faderfox = {}
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
  syncoffset = 8,

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

function faderfox.init()
  -- workaround: sometimes midi.devices table has empty values, so #midi.devices doesn't work
  for i=1,16 do
    if midi.vports[i] and midi.vports[i].name == "Faderfox EC4" then
      print("connecting faderfox")
      ff = midi.connect(midi.vports[i].id)
      connected = true
    end
  end

end

function faderfox.echo(param_id, new_value)
  local p_name = string.sub(param_id, 2, -1)
  local midi_channel = string.sub(param_id, 1, 1)
  local midi_cc = cc_map[p_name]

  if connected and midi_cc then
    local range = params:get_range(param_id)
    local value = math.floor(util.linlin(range[1], range[2], 0, 127, new_value))

    ff:cc(midi_cc, value, midi_channel)
  end
end

function faderfox.init_values()
  if connected then
    print("init faderfox values")
    for name, cc in pairs(cc_map) do
      for v=1, VOICE_COUNT do
        local param_id = v..name
        local new_value = params:get(param_id)
        faderfox.echo(param_id, new_value)
      end
    end
  else
    print("faderfox not detected")
  end
end

return faderfox

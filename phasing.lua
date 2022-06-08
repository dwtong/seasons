max = 5 -- volts
min = -5 -- volts
shift = 5 -- brings range up to 0 - 10
range = max - min

function clamp(i)
  print((i + shift) % (max + shift))
end

function phase(v)
  clamp(v)
  clamp(v+range*0.25)
  clamp(v+range*0.5)
  clamp(v+range*0.75)
end

phase(0)

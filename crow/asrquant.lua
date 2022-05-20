--- quantised "analog" shift register
--
-- input[1] - trigger
-- input[2] - signal to sample
-- output[1-4] - last four sampled values

public{volts = {0,0,0,0}}
public{x=1}

function init()
  input[1].mode('change', 1.0, 0.1, 'rising')
  for i=1,4 do output[i].scale{} end
end

input[1].change = function()
  public.x = public.x + 1
  -- public.volts = {1,2,3,4}
  -- table.insert(public.volts, 1, input[2].volts) -- prepend new value
  -- table.remove(public.volts) -- drop oldest value
  -- t = {input[2].volts}

  -- for k,v in ipairs(public.volts) do
  --   if k < 4 then
  --     t[k + 1] = v
  --   end
  -- end

  -- public.volts = t

  -- for i=1,4 do
    -- FIXME some of these volts are different - different output types?
    -- applying scales to all outputs should help with this
    -- output[i].volts = public.volts[i]
  -- end
end



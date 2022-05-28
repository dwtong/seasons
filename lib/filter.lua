--- multimode/dj style morphing filter for softcut
--- thanks for the help @dan_derks

local SC_VOICES = 6 -- softcut supports 6 voices
local FC_STEPS = 200 -- 200 steps from lowest to highest filter cutoff
local SLEW_FPS = 10 -- frames per second for slew

local voices = {}

for v=1, SC_VOICES do
  voices[v] = {
    clock = nil,
    value = 0,
    slew_time = 0
  }
end

local function apply_filter_cutoff(voice, fc_pos)
  local lp = 0
  local hp = 0
  local dry = 1

  if fc_pos >= 0 then -- CW: HP
    softcut.post_filter_fc(voice, util.linexp(0, 100, 400, 6000, fc_pos))
    if fc_pos <= 40 then
      dry = util.linlin(0, 40, 1, 0, fc_pos)
      hp = util.linlin(0, 40, 0, 1, fc_pos)
      softcut.post_filter_dry(voice, dry)
      softcut.post_filter_hp(voice, hp)
    else
      if dry ~= 0 then
        dry = 0
        softcut.post_filter_dry(voice, dry)
      end
      if lp > 0 then
        lp = 0
        softcut.post_filter_lp(voice, lp)
      end
    end
  elseif fc_pos <= 0 then -- CCW: LP
    softcut.post_filter_fc(voice, util.linexp(-100, 0, 20, 8000, fc_pos))
    if fc_pos >= -40 then
      dry = util.linlin(-40, 0, 0, 1, fc_pos)
      lp = util.linlin(-40, 0, 1, 0, fc_pos)
      softcut.post_filter_dry(voice, dry)
      softcut.post_filter_lp(voice, lp)
    else
      if dry ~= 0 then
        dry = 0
        softcut.post_filter_dry(voice, dry)
      end
      if hp > 0 then
        hp = 0
        softcut.post_filter_hp(voice, hp)
      end
    end
  end
end

local function cutoff(voice, new_value)
  local f = voices[voice]
  local sleep = f.slew_time/FC_STEPS * 1/SLEW_FPS
  local inc = 1/SLEW_FPS

  if new_value < f.value then inc = -inc end -- decrement if new value is lower than current value
  if f.clock then clock.cancel(f.clock) end -- stop any existing changes


  f.clock = clock.run(function()
    repeat
      clock.sleep(sleep)
      f.value = f.value + inc
      apply_filter_cutoff(voice, f.value)
    until math.floor(f.value) == math.floor(new_value)
  end)
end

local function slew_time(voice, slew_time)
  voices[voice].slew_time = slew_time
end

return {
  cutoff = cutoff,
  slew_time = slew_time
}

--- multimode/dj style morphing filter
--- thanks for the help @dan_derks

local filter = {}

function filter.translate_fc_to_filters(voice, fc_pos)
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

return filter

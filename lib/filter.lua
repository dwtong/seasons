file = _path.audio.."tehn/whirl1.aif"
rate = 1.0
lp = 0
hp = 0
dry = 1
fc_pos = 0
level = 1

function init()
  audio.level_adc_cut(1)

  softcut.buffer_clear()
  softcut.buffer_read_mono(file,0,1,-1,1,1)

  softcut.enable(1,1)
  softcut.buffer(1,1)
  softcut.level(1,level)
  softcut.rate(1,rate)
  softcut.loop(1,1)
  softcut.loop_start(1,1)
  softcut.position(1,1)
  softcut.play(1,1)

  softcut.loop_end(1,3.42)
  softcut.loop_end(2,1.25)

  softcut.post_filter_dry(1,dry)
  softcut.post_filter_rq(1,1)
  
end

function enc(n,d)
  if n==1 then
    rate = util.clamp(rate+d/100,-4,4)
    softcut.rate(1,rate)
  elseif n==3 then
    fc_pos = util.clamp(fc_pos + d,-100,100)
    translate_fc_to_filters(fc_pos)
  end
  redraw()
end

function translate_fc_to_filters(fc_pos)
  if fc_pos >= 0 then -- CW: HP
    softcut.post_filter_fc(1,util.linexp(0,100,400,6000,fc_pos))
    if fc_pos <= 40 then
      dry = util.linlin(0,40,1,0,fc_pos)
      hp = util.linlin(0,40,0,1,fc_pos)
      softcut.post_filter_dry(1,dry)
      softcut.post_filter_hp(1,hp)
    else
      if dry ~= 0 then
        dry = 0
        softcut.post_filter_dry(1,dry)
      end
      if lp > 0 then
        lp = 0
        softcut.post_filter_lp(1,lp)
      end
    end
  elseif fc_pos <= 0 then -- CCW: LP
    softcut.post_filter_fc(1,util.linexp(-100,0,20,8000,fc_pos))
    if fc_pos >= -40 then
      dry = util.linlin(-40,0,0,1,fc_pos)
      lp = util.linlin(-40,0,1,0,fc_pos)
      softcut.post_filter_dry(1,dry)
      softcut.post_filter_lp(1,lp)
    else
      if dry ~= 0 then
        dry = 0
        softcut.post_filter_dry(1,dry)
      end
      if hp > 0 then
        hp = 0
        softcut.post_filter_hp(1,hp)
      end
    end
  end
end

function key(n,z)
  if z == 1 then
    level = level == 1 and 0 or 1
    softcut.level(1,level)
  end
end

function redraw()
  screen.clear()
  screen.move(10,30)
  screen.text("rate: ")
  screen.move(118,30)
  screen.text_right(string.format("%.2f",rate))
  screen.move(10,40)
  screen.text("filter tilt: ")
  screen.move(118,40)
  local display_tilt = "neutral"
  if fc_pos > 0 then
    display_tilt = "hp: "..fc_pos.."%"
  elseif fc_pos < 0 then
    display_tilt = "lp: "..math.abs(fc_pos).."%"
  end
  screen.text_right(display_tilt)
  screen.move(10,50)
  screen.update()
end
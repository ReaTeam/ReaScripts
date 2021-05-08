-- @description Pomodoro
-- @author vo
-- @version 1.0
-- @link GitHub https://github.com/evgazloy/reaper-pomodoro
-- @screenshot
--   Fullscreen https://i.ibb.co/PDvpWBh/main-full.png
--   Main https://i.ibb.co/Z8Cr1tF/main.png
-- @donation Donate via PayPal https://paypal.me/evgazloy
-- @about
--   [Read about the Pomodoro technique](https://en.wikipedia.org/wiki/Pomodoro_Technique)  
--   [Instruction](https://github.com/evgazloy/reaper-pomodoro)

local gui = {}
local vo = "vo_pomodoro"

function init()
  gui.settings = {}
  gui.settings.color = {}
  gui.settings.color.text = 0xeef5db -- Color of text and border in rgb
  gui.settings.color.back = 0x264653 -- Color of background in rgb
  gui.settings.color.progress = 0x2a9d8f -- Color of progress bar while working
  gui.settings.color.progress_break = 0xe76f51 -- Color of progress bar while resting
  gui.settings.font_size = 20 -- Countdown font size
  
  gui.settings.margins = 4
  gui.settings.docker_id = 257        -- try 0, 1, 257, 513, 1027 etc.
  
  local x, y, w, h = 0, 0, 200, 100
  
  if reaper.HasExtState(vo, "idx") then
    gui.settings.docker_id = tonumber(reaper.GetExtState(vo, "idx"))
  end
  
  if reaper.HasExtState(vo, "wx") then
    x = tonumber(reaper.GetExtState(vo, "wx"))
  end
  
  if reaper.HasExtState(vo, "wy") then
    y = tonumber(reaper.GetExtState(vo, "wy"))
  end
  
  if reaper.HasExtState(vo, "ww") then
    w = tonumber(reaper.GetExtState(vo, "ww"))
  end
  
  if reaper.HasExtState(vo, "wh") then
    h = tonumber(reaper.GetExtState(vo, "wh"))
  end

  timer = {}
  timer.settings = {}
  
  timer.settings.work = -1
  timer.settings.break_short = -1
  timer.settings.break_long = -1
  timer.settings.count = -1
  
  if reaper.HasExtState(vo, "work") then
    timer.settings.work = tonumber(reaper.GetExtState(vo, "work"))
  end
  
  if reaper.HasExtState(vo, "short") then
    timer.settings.break_short = tonumber(reaper.GetExtState(vo, "short"))
  end
  
  if reaper.HasExtState(vo, "long") then
    timer.settings.break_long = tonumber(reaper.GetExtState(vo, "long"))
  end
  
  if reaper.HasExtState(vo, "count") then
    timer.settings.count = tonumber(reaper.GetExtState(vo, "count"))
  end

  local s = false
  if (not limit(timer.settings.work)) then
    timer.settings.work = 25
    s = true
  end
  
  if(not limit(timer.settings.break_short)) then
    timer.settings.break_short = 5
    s = true
  end
  
  if(not limit(timer.settings.break_long)) then
    timer.settings.break_long = 15
    s = true
  end
  
  if(not limit(timer.settings.count)) then
    timer.settings.count = 4
    s = true
  end

  set_t = {}
  update_temp_set()
  if s then save() end
  
  mouse = {
    l_state = false,
    r_state = false,
    i = 0,
    y = 0
  }
  
  reaper.atexit(save_gui)
  
  gfx.init("", w, h, gui.settings.docker_id, x, y)
  gfx.setfont(1,"Arial Bold", gui.settings.font_size, "b")
  gfx.setfont(2,"Arial Bold", 12)
  gfx.clear = 3355443

  progress = {}
  progress.count = 0
  progress.flash = false
  timer.enabled = false
  timer.settings.visible = false
  reset_to_work()
  g_time = 0
  
  gfx.setfont(2)
  titles = {"Work", "Short", "Long", "Count"}
  min_w, min_h = 0, 0
  for i = 1, 4 do
    local sw, sh = gfx.measurestr(titles[i])
    min_w = min_w + sw
    min_h = math.max(min_h, sh)
  end
  
  gfx.setfont(1)
  local min_main_w, min_main_h = gfx.measurestr("55:55")
  min_w = math.max(min_w, min_main_w) + 7 * gui.settings.margins
  min_h = math.max(2 * min_h, min_main_h) + 3 * gui.settings.margins
  
  mainloop()
end

function limit(x)
  return (x > 0) and (x < 100)
end

function save()
  timer.settings.work = set_t[1]
  timer.settings.break_short = set_t[2]
  timer.settings.break_long = set_t[3]
  timer.settings.count = set_t[4]
  
  reaper.SetExtState(vo, "work", tostring(timer.settings.work), 1)
  reaper.SetExtState(vo, "short", tostring(timer.settings.break_short), 1)
  reaper.SetExtState(vo, "long", tostring(timer.settings.break_long), 1)
  reaper.SetExtState(vo, "count", tostring(timer.settings.count), 1)
  save_gui()
end

function save_gui()
  idx, x, y, w, h = gfx.dock(-1, 1, 1, 1, 1)
  
  reaper.SetExtState(vo, "idx", tostring(idx), 1)
  reaper.SetExtState(vo, "wx", tostring(x), 1)
  reaper.SetExtState(vo, "wy", tostring(y), 1)
  reaper.SetExtState(vo, "ww", tostring(w), 1)
  reaper.SetExtState(vo, "wh", tostring(h), 1)
end

function set_color(color)
  gfx.set(((color & 0xff0000) >> 16) / 255, ((color & 0xff00) >> 8) / 255, (color & 0xff) / 255)
end

function update_timer_max()
  timer.enabled = false
  timer.max = timer.min * 60
  progress.v = 0
end

function reset_to_work()
  timer.min = timer.settings.work
  timer.sec = 0
  timer.br = false
  update_timer_max()
end

function reset_to_short()
  timer.min = timer.settings.break_short
  timer.sec = 0
  timer.br = true
  update_timer_max()
end

function reset_to_long()
  timer.min = timer.settings.break_long
  timer.sec = 0
  timer.br = true
  update_timer_max()
end

function reset()
  progress.count = 0
  progress.flash = false
  reset_to_work()
end

function next_period()
  if (timer.br == false) then
    reaper.Main_OnCommand(1016, 0)
    if (progress.count == timer.settings.count - 1) then
      reset_to_long()
    else
      reset_to_short()
    end
    progress.count = progress.count + 1
  else
    if (progress.count == timer.settings.count) then
      progress.count = 0
    end
    reset_to_work()
  end
end

function time()
  gfx.drawstr(string.format("%02d", timer.min) .. ":" .. string.format("%02d", timer.sec), 5, gfx.x + progress.w, gfx.y + progress.h)
  
  local curTime = reaper.time_precise()
  if (curTime - g_time > 1) then
    g_time = curTime
    
    if timer.enabled then
      timer.sec = timer.sec - 1
      if (timer.sec < 0) then
        timer.sec = 59
        timer.min = timer.min - 1
        if (timer.min < 0) then 
          next_period()
          progress.flash = true
        end
      end
      progress.v = (timer.max - (timer.min * 60 + timer.sec)) / timer.max
    else
      if progress.flash then
        if (progress.v > 0) then progress.v = 0 else progress.v = 1 end
      end
    end
  end
end

function update_temp_set()
  set_t[1] = timer.settings.work
  set_t[2] = timer.settings.break_short
  set_t[3] = timer.settings.break_long
  set_t[4] = timer.settings.count
end

function menu()
  local x, y = gfx.x, gfx.y
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  if timer.settings.visible then
    local r = gfx.showmenu("Save|Cancel")
    if (r == 1) then 
      save()
      reset()
    end
    
    if (r == 1) or (r == 2) then timer.settings.visible = false end
  else
    local m = "Skip|Reset||Settings"
    if (gfx.dock(-1) & 1 == 0) then m = m .. "|Dock" end
    local r = gfx.showmenu(m)
    if (r == 1) then
      next_period()
      progress.flash = false
    elseif (r == 2) then
      local acc = gfx.showmenu("#Reset timer?||Yes|No")
      if acc == 2 then reset() end
    elseif (r == 3) then
      update_temp_set()
      timer.settings.visible = true
    elseif (r == 4) then dock()
    end
    gfx.x, gfx.y = x, y
  end
end

function left_click()
  if timer.settings.visible == false then
    progress.flash = false
    timer.enabled = not timer.enabled
  end
end

function isMouse()
  local r, b
  if timer.settings.visible then
    r, b = settings_w, settings_h
  else
    r, b = progress.w, progress.h
  end
        
  return (gfx.mouse_x > gfx.x) and (gfx.mouse_x < r + gfx.x) and 
    (gfx.mouse_y > gfx.y) and (gfx.mouse_y < b + gfx.y)
end

function mouse_move()
  if (mouse.i > 0) and (mouse.i < 5) then
    local d, _ = math.modf((gfx.mouse_y - mouse.y) / 4)
    if d ~= 0 then
      local n = set_t[mouse.i] - d
      if limit(n) then set_t[mouse.i] = n end
      mouse.y = gfx.mouse_y
    end
  end
end

function dock()
  local idx = gfx.dock(-1)
  idx = idx | 1
  gfx.dock(idx)
end

function mainloop()
  gfx.x = gui.settings.margins
  gfx.y = gui.settings.margins
  set_color(gui.settings.color.text)
  
  
  if gfx.w < min_w then gfx.w = min_w end
  if gfx.h < min_h then gfx.h = min_h end
  
  local count_h = 4
 
  progress.w = gfx.w - 2 * gui.settings.margins
  progress.h = gfx.h - 3 * gui.settings.margins - count_h
  gfx.rect(gfx.x, gfx.y, progress.w, progress.h)
  
  settings_w, settings_h = gfx.w - 2 * gui.settings.margins, gfx.h - 2 * gui.settings.margins
  
  if (gfx.mouse_cap == 1) and isMouse() then
    if(mouse.l_state == false) then
      mouse.i = math.ceil(gfx.mouse_x / (settings_w / 4))
      mouse.y = gfx.mouse_y
    end
    
    mouse.l_state = true
  else
    if (gfx.mouse_cap == 2) and isMouse() then
      mouse.r_state = true
    else
      if (gfx.mouse_cap == 0) then
        if isMouse() then
          if mouse.l_state then
            left_click()
          end
        
          if mouse.r_state then
            menu()
          end
        end
        
        mouse.l_state = false
        mouse.r_state = false
        mouse.i = 0
      end
    end
  end
  
  if timer.settings.visible then
    gfx.rect(gfx.x, gfx.y, settings_w, settings_h)
    set_color(gui.settings.color.back)
    gfx.x, gfx.y = gfx.x + 1, gfx.y + 1
    settings_w, settings_h = settings_w - 2, settings_h - 2
    gfx.rect(gfx.x, gfx.y, settings_w, settings_h)
    
    local w, h = settings_w / 4, settings_h / 2;
    local x, y = gfx.x, gfx.y
    gfx.setfont(2)
    for i = 1, 4 do
      set_color(gui.settings.color.text)
      
      gfx.x = x +(i - 1) * w
      gfx.y = y
      if i ~= 4 then
        gfx.line(gfx.x + w, y, gfx.x + w, y + settings_h)
      end
      
      if i == mouse.i then
        set_color(gui.settings.color.progress_break)
      end
      
      gfx.drawstr(titles[i], 9, gfx.x + w, gfx.y + h)
      
      gfx.x = x +(i - 1) * w
      gfx.y = y + settings_h / 2
      gfx.drawstr(set_t[i], 1, gfx.x + w, gfx.y + h)
      
      if (mouse.l_state) then
        mouse_move()
      end
    end
  else
    gfx.setfont(1)
    margins = gui.settings.margins / math.ceil(timer.settings.count / 10)
    local count_w = ((progress.w - (timer.settings.count - 1) * margins) / timer.settings.count)
    dw = ((progress.w - (math.floor(timer.settings.count * count_w) + (timer.settings.count - 1) * margins)) / 2)
    local x = gfx.x
    local y = gfx.y + progress.h + gui.settings.margins
  
    for i = 1, timer.settings.count do
      if (i < progress.count + 1) then
        set_color(gui.settings.color.progress)
      else
        set_color(gui.settings.color.back)
      end
    
      local d = 0
      if (i == 1) then d = dw end
      if (i == timer.settings.count) then count_w = gfx.x + progress.w - x end
      gfx.rect(x, y, count_w + d, count_h)
      x = x + math.floor(count_w + d + margins)
    end
  
    gfx.x = gfx.x + 1
    gfx.y = gfx.y + 1
    progress.w = progress.w - 2
    progress.h = progress.h - 2
    set_color(gui.settings.color.back)
    gfx.rect(gfx.x, gfx.y, progress.w, progress.h)
  
    if (timer.br == false) then
      set_color(gui.settings.color.progress)
    else
      set_color(gui.settings.color.progress_break)
    end
  
    gfx.rect(gfx.x, gfx.y, progress.w * progress.v, progress.h)
  
    set_color(gui.settings.color.text)
    time()
  end
 
  gfx.update()
  if gfx.getchar() ~= -1 then reaper.defer(mainloop) end
end

init()

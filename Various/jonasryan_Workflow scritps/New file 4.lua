-- @noindex

-- button paramters
local win_w, win_h = 450, 200
local btn_w, btn_h = 110, 40

local btn1_label = "From Start"
local btn2_label = "From End"
local btn_pos_x, btn_pos_y = 30, 120
local btn_2_pos_x = btn_pos_x + 190

-- button state trackers
local btn1_down = false
local btn2_down = false

-- slider parameters
local slider_x, slider_y, slider_w, slider_h = 30, 90, 300, 25
local slider_min, slider_max = 0, 5
local slider_val = 1.0
local dragging = false

-- checkbox (across tracks)
local cb_across_tracks = true
local cb_x, cb_y = 30, 25
local cb_size = 20

-- checkbox 2 (all items)
local cb_all_items = false
local cb2_x, cb2_y = 30, 55

local function cascade_items_custom(step_seconds, atStart, all_items, across_tracks)
  local numSel = reaper.CountSelectedMediaItems(0)
  if all_items == true then
    numSel = reaper.CountMediaItems(0)
  end

  if numSel == 0 then
    reaper.ShowMessageBox("No items selected.", "Cascade items", 0)
    return
  end

  local items = {}
  for i = 0, numSel - 1 do
    local it = reaper.GetSelectedMediaItem(0, i)
    if all_items == true then
      it = reaper.GetMediaItem(0, i)
    end
    local pos = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
    local tr = reaper.GetMediaItem_Track(it)
    local trNum = reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")
    local len = reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
    items[#items+1] = {it=it, pos=pos, trNum=trNum, len=len}
  end

  if across_tracks == false then
    -- sort by start time, then track number
    table.sort(items, function(a,b)
      if a.pos == b.pos then
        return a.trNum < b.trNum
      else
        return a.pos < b.pos
      end
    end)
  else 
    -- sort by start track number, then across time
    table.sort(items, function(a,b)
      if a.trNum == b.trNum then
        return a.pos < b.pos
      else 
        return a.trNum < b.trNum
      end
    end)
  end

  -- reposition: each item starts after the previous item's end + step_seconds
  if atStart == true then
    local curPos = items[1].pos
    for i, entry in ipairs(items) do
      reaper.SetMediaItemInfo_Value(entry.it, "D_POSITION", curPos)
      curPos = curPos + step_seconds
    end
  elseif atStart == false then
    local curPos = items[1].pos
    for i, entry in ipairs(items) do
      reaper.SetMediaItemInfo_Value(entry.it, "D_POSITION", curPos)
      curPos = curPos + entry.len + step_seconds
    end
  end

  reaper.UpdateArrange()
end

local function draw_slider()
  -- background track
  gfx.set(0.8,0.8,0.8,1)
  gfx.rect(slider_x, slider_y + slider_h/3, slider_w, slider_h/3, 1)

  -- handle
  local handle_x = slider_x + (slider_val - slider_min)/(slider_max - slider_min) * slider_w - 5
  gfx.set(0.3,0.6,0.9,1)
  gfx.rect(handle_x, slider_y, 10, slider_h, 1)

  -- display value
  gfx.set(0,0,0,1)
  gfx.x, gfx.y = slider_x + slider_w + 10, slider_y
  gfx.drawstr(string.format("%.2f s", slider_val))
end

local function handle_slider(mx, my, lb)
  -- check if mouse is inside handle or slider bar
  local handle_x = slider_x + (slider_val - slider_min)/(slider_max - slider_min) * slider_w - 5
  if lb == 1 and not dragging then
    if (mx >= handle_x and mx <= handle_x + 10 and my >= slider_y and my <= slider_y + slider_h) or
       (mx >= slider_x and mx <= slider_x + slider_w and my >= slider_y and my <= slider_y + slider_h) then
      dragging = true
    end
  end

  if lb == 0 then dragging = false end

  if dragging then
    -- update slider value based on mouse x
    slider_val = slider_min + ((mx - slider_x) / slider_w) * (slider_max - slider_min)
    -- clamp dat
    if slider_val < slider_min then slider_val = slider_min end
    if slider_val > slider_max then slider_val = slider_max end
  end
end

local function draw_checkbox()
  --checkbox 1 (across tracks?)
  gfx.set(0.9, 0.9, 0.9, 1)
  gfx.rect(cb_x, cb_y, cb_size, cb_size, 0)
  if cb_across_tracks then
    gfx.set(0.2, 0.8, 0.2, 1)
    gfx.rect(cb_x + 4, cb_y + 4, cb_size - 8, cb_size - 8, 1)
  end
  gfx.set(1, 1, 1, 1) -- white text
  gfx.x, gfx.y = cb_x + cb_size + 8, cb_y + 2
  gfx.drawstr("Cascade (or track-local)")

  -- checkbox 2 (all items?)
  gfx.set(0.9, 0.9, 0.9, 1)
  gfx.rect(cb2_x, cb2_y, cb_size, cb_size, 0)
  if cb_all_items then
    gfx.set(0.2, 0.8, 0.2, 1)
    gfx.rect(cb2_x + 4, cb2_y + 4, cb_size - 8, cb_size - 8, 1)
  end
  gfx.set(1, 1, 1, 1) -- white text
  gfx.x, gfx.y = cb2_x + cb_size + 8, cb2_y + 2
  gfx.drawstr("All items? (or selected)")
end

-- Function to handle checkbox input
local function handle_checkbox(mx, my, lb, mouse_click)
  if mouse_click then
    if mx >= cb_x and mx <= cb_x + cb_size and my >= cb_y and my <= cb_y + cb_size then
      cb_across_tracks = not cb_across_tracks
    end
    if mx >= cb2_x and mx <= cb2_x + cb_size and my >= cb2_y and my <= cb2_y + cb_size then
      cb_all_items = not cb_all_items
    end
  end
end

-- track previous mouse button state
local prev_lb = 0

local function gui_loop()
  local mx, my = gfx.mouse_x, gfx.mouse_y
  local lb = gfx.mouse_cap & 1

  -- handle slider input
  handle_slider(mx, my, lb)

  -- draw header
  gfx.set(1,1,1,1)
  gfx.x, gfx.y = 30, 5
  gfx.drawstr("Cascade Items", 0)

  -- draw buttons
  gfx.set(0.7,0.7,0.7,1)
  gfx.rect(btn_pos_x,btn_pos_y,btn_w,btn_h,1)
  gfx.rect(btn_2_pos_x,btn_pos_y,btn_w,btn_h,1)

  gfx.set(0,0,0,1)
  gfx.x, gfx.y = btn_pos_x+10, btn_pos_y+10
  gfx.drawstr(btn1_label)
  gfx.x, gfx.y = btn_2_pos_x+10, btn_pos_y+10
  gfx.drawstr(btn2_label)

  draw_slider()

  -- draw slider value at the right
  gfx.set(1,1,1,1)
  gfx.x, gfx.y = slider_x + slider_w + 10, slider_y + 3
  gfx.drawstr(string.format("%.2f seconds", slider_val))

  -- Button 1 logic
  if mx >= btn_pos_x and mx <= btn_pos_x+btn_w and my >= btn_pos_y and my <= btn_pos_y+btn_h then
    if lb == 1 and not btn1_down then
      btn1_down = true
      local step = slider_val
      reaper.Undo_BeginBlock()
      cascade_items_custom(step, true, cb_all_items, cb_across_tracks)
      reaper.Undo_EndBlock("Cascade selected items (1s)", -1)
    elseif lb == 0 then
      btn1_down = false
    end
  end

  -- Button 2 logic
  if mx >= btn_2_pos_x and mx <= btn_2_pos_x +btn_w and my >= btn_pos_y and my <= btn_pos_y+btn_h then
    if lb == 1 and not btn2_down then
      btn2_down = true
      local step = slider_val
      reaper.Undo_BeginBlock()
      cascade_items_custom(step, false, cb_all_items, cb_across_tracks)
      reaper.Undo_EndBlock("Cascade selected items (custom)", -1)
    elseif lb == 0 then
      btn2_down = false
    end
  end

  -- checkbox logic
  local mx, my = gfx.mouse_x, gfx.mouse_y
  local lb = gfx.mouse_cap & 1
  local mouse_click = lb == 1 and prev_lb == 0
  prev_lb = lb

  handle_checkbox(mx, my, lb, mouse_click)
  draw_checkbox()


  gfx.update()
  if gfx.getchar() >= 0 then
    reaper.defer(gui_loop)
  end
end

-- run
gfx.init("Cascade GUI with custom seconds", win_w, win_h)
gui_loop()


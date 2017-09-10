-- @description PL9-amagalma_Source Time Position Tool v2
-- @author PL9, modified by amagalma (v2)
-- @version 2
-- @about
--   # Tool that shows cursor position in relation to the item take's Source time
--
--   - v2: remembers last position and window size
--   - v2: resizeable via mouse-wheel
--   - v2: edit cursor can be moved to any user-defined source time position
--   - v2: directory where source file resides can be opened in explorer/finder
--   - v2: tooltips

local reaper = reaper
local change, fontsize
local Section = "Source time position v2"
local Key = "fontsize"
local btn_down = false
local version = 2

--[[
 * Changelog:
 * v2 (2017-09-10)
  + remembers last position and window size
  + resizeable via mouse-wheel
  + edit cursor can be moved to any user-defined source time position
  + directory where source file resides can be opened in explorer/finder
  + tooltips
--]]


--------------------------------------------------------------------------------------------

function MouseOn(x, y, text, tooltip)
  local mouseon
  local LeftClick = false
  if text then
    local mx, my = gfx.mouse_x, gfx.mouse_y
    local _, posx, posy, _, _ = gfx.dock(-1, 0, 0, 0, 0)
    local long = gfx.measurestr(text)
    if mx > x and mx < x + long and my > y and my < y + fontsize then
      mouseon = true
      if tooltip then
        reaper.TrackCtl_SetToolTip(tooltip, posx+mx+8, posy+my+fontsize*2, true)
      end
      if gfx.mouse_cap & 1 == 1 and not btn_down then
        btn_down = true
      elseif gfx.mouse_cap & 1 == 0 and btn_down then
        btn_down = false
        LeftClick = true
      end
    else
      if tooltip then
        reaper.TrackCtl_SetToolTip("", posx+mx+8, posy+my+fontsize*2, true)
      end
    end
  end
  return mouseon, LeftClick
end

--------------------------------------------------------------------------------------------

function show_edit_cursor_position(x, y)
  gfx.x, gfx.y = x, y
  gfx.a, gfx.r, gfx.g, gfx.b = 0.6, 1, 1, 1
  gfx.printf("Edit Cursor Position:    ")
  gfx.a = 1 -- brighter
  local ec_pos = reaper.format_timestr_pos(reaper.GetCursorPosition(), "", 5)
  if ec_pos:match("^%-") then -- alignment
    gfx.printf(ec_pos)
  else
    gfx.printf(" "..ec_pos)
  end
end

--------------------------------------------------------------------------------------------

function show_source_time_position(x, y, item, take)
  local item_pos, item_length, edit_cursor_pos, take_start_offset, take_playrate
  local active_take_number, stp, proj_offset, stp_pos, stp_pos_forpars
  local text = "Source Time Position:   "
  local tooltip = "Click to navigate to specified source time position"
  gfx.x, gfx.y = x, y
  gfx.a, gfx.r, gfx.g, gfx.b = 0.7, 1, 1, 0 -- yellow
  local mouseon, leftclick = MouseOn(x, y, text, tooltip)
  if mouseon then
    gfx.a = 0.85
  else
    gfx.a = 0.7
  end
  gfx.printf(text)
  if item then
    item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    edit_cursor_pos = reaper.GetCursorPosition()
    proj_offset = reaper.GetProjectTimeOffset(0, 0)
    -- edit cursor is within item
    if item_pos <= edit_cursor_pos and (item_pos + item_length) >= edit_cursor_pos then
      if take then
        take_start_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
        take_playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
        active_take_number = reaper.GetMediaItemTakeInfo_Value(take, "IP_TAKENUMBER")
        gfx.a = 1 -- brighter
        stp = (edit_cursor_pos - item_pos) * take_playrate + take_start_offset - proj_offset
        stp_pos = reaper.format_timestr_pos(stp, "", 5)
        stp_pos_forpars = reaper.format_timestr_pos(stp, "", 0)
        gfx.printf(stp_pos)
      end
      if leftclick then
        local retvals_csv = stp_pos:gsub(":", ",")
        local title = "Navigate to source time position"
        local ok, retvals = reaper.GetUserInputs(title, 4, "hours:,minutes:,seconds:,frames:", retvals_csv)
        if ok then
          local t = {}
          for number in string.gmatch(retvals, "%d+,?") do t[#t+1] = number:match("%d+") end
          local framerate, _ = reaper.TimeMap_curFrameRate(0)
          if string.match(t[1], "%d") and
             tonumber(t[2]) < 59 and tonumber(t[2]) >= 0 and
             tonumber(t[3]) < 59 and tonumber(t[3]) >= 0 and
             tonumber(t[4]) < framerate and tonumber(t[4]) >= 0
          then
            stp = reaper.parse_timestr_pos(table.concat(t, ":"), 5)
            edit_cursor_pos = item_pos + (stp - take_start_offset + proj_offset) / take_playrate
            reaper.SetEditCurPos(edit_cursor_pos, true, false)
          else
            reaper.MB([[
Hints : 
          - try appropriate numbers (0-59) 
          - check if frames number is valid (less than ]]..framerate..[[)
          (framerate of this project is ]]..framerate..")", "No valid input!", 0)
          end
        end
      end
    else -- edit cursor is not within item
      gfx.a, gfx.r, gfx.g, gfx.b = 1, 1, 0, 0 -- red
      gfx.printf("edit cursor position not within selected item")
    end
  end
end

--------------------------------------------------------------------------------------------

function show_take_name(x, y, item, take)
  gfx.x, gfx.y = x, y
  gfx.a, gfx.r, gfx.g, gfx.b = 0.7, 1, 1, 0 -- yellow
  gfx.printf("Take name: ")
  gfx.a = 1 -- brighter text
  if item and take then
    local take_name = reaper.GetTakeName(take)
    gfx.printf(take_name)
  else -- no selected item or item has no takes
    gfx.r, gfx.g, gfx.b = 1, 0, 0
    gfx.printf("No selected item (or empty item)")
  end
end

--------------------------------------------------------------------------------------------

function show_number_of_takes_in_item(x, y, item, take)
  local active_take_number
  gfx.x, gfx.y = x, y
  gfx.r, gfx.g, gfx.b =  1, 1, 0 -- yellow
  local mouseon, leftclick = MouseOn(x, y, text, tooltip)
  if mouseon then
    gfx.a = 0.85
  else
    gfx.a = 0.7
  end
  gfx.printf("Active take: ")
  if item then
    if take then
      active_take_number = reaper.GetMediaItemTakeInfo_Value(take, "IP_TAKENUMBER")
      gfx.a = 1
      gfx.printf("%d", active_take_number + 1)
      gfx.printf(" of ")
      gfx.printf("%d", reaper.CountTakes(item))
    end
  end
end

--------------------------------------------------------------------------------------------

function show_take_filename(x, y, take)
  gfx.x, gfx.y = x, y
  gfx.a, gfx.r, gfx.g, gfx.b = 0.7, 1, 1, 0 -- yellow
  gfx.printf("Take Filename: ")
  if take then
    if reaper.TakeIsMIDI(take) then
      gfx.x, gfx.y = x, y + fontsize*1.15
      gfx.a, gfx.r, gfx.g, gfx.b = 0.85, 1, 0.4, 0.3 -- redish      
      gfx.printf("(take is MIDI)")
    else
      local filename = reaper.GetMediaSourceFileName(reaper.GetMediaItemTake_Source(take), "")
      local tooltip = "Click to navigate to directory of file"
      gfx.x, gfx.y = x, y + fontsize*1.15
      gfx.r, gfx.g, gfx.b = 1, 0.4, 0.3 -- redish
      local mouseon, leftclick = MouseOn(x, y + fontsize*1.15, filename, tooltip)
      if mouseon then
        gfx.a = 0.85
      else
        gfx.a = 0.7
      end
      gfx.printf(filename)
      if leftclick then
        local separator, action, path
        if string.match(reaper.GetOS(), "Win")  == "Win" then
          path = string.match(filename, ".+\\"):gsub("\\", "\\\\")
          os.execute('start "" "'..path..'"')
          --reaper.ExecProcess('cmd.exe /C start "" "'..path..'"', 0)
        else
          path = string.match(filename, ".+/")
          os.execute('open "" "'..path..'"')
        end
      end
    end
  end
end

--------------------------------------------------------------------------------------------

local function MousewheelToFontsize()
  local wheel = gfx.mouse_wheel
  if wheel > 0 then
    fontsize = fontsize + 1
    if fontsize > 30 then
      fontsize = 30
      change = false
    else
      change = true
      reaper.SetExtState(Section, Key, fontsize, 1)
    end
    gfx.mouse_wheel = 0
  elseif wheel < 0 then
    fontsize = fontsize -1
    if fontsize < 17 then
      fontsize = 17
      change = false
    else
      change = true
      reaper.SetExtState(Section, Key, fontsize, 1)
    end
    gfx.mouse_wheel = 0
  end
end

--------------------------------------------------------------------------------------------

function main()
  local mx, my = gfx.mouse_x, gfx.mouse_y 
  local sel_item = reaper.GetSelectedMediaItem(0, 0)
  local active_take
  if sel_item then
    active_take = reaper.GetActiveTake(sel_item)
  end
  show_edit_cursor_position(fontsize/2, fontsize/2)
  show_source_time_position(fontsize/2, gfx.y + gfx.texth, sel_item, active_take)
  show_take_name(fontsize/2, gfx.y + gfx.texth, sel_item, active_take)
  show_number_of_takes_in_item(fontsize/2, gfx.y + gfx.texth, sel_item, active_take)
  show_take_filename(fontsize/2, gfx.y + gfx.texth, active_take)
  gfx.update()
  MousewheelToFontsize()
  if change then
    gfx.quit()
    init()
    main()
    change = false
  else
    local char = gfx.getchar()
    if (char ~= 27 and char >= 0) and not change then
      reaper.defer(main)
    else
      local _, x, y, _, _ = gfx.dock(-1, 0, 0, 0, 0)
      reaper.SetExtState(Section, "x", tostring(x), 1)
      reaper.SetExtState(Section, "y", tostring(y), 1)      
      gfx.quit()
   end
  end
end

--------------------------------------------------------------------------------------------

function init()
  local x,y
  local HasState = reaper.HasExtState(Section, Key)
  if not HasState then
    fontsize = 20
  else
    fontsize = tonumber(reaper.GetExtState(Section, Key))
  end
  HasState = reaper.HasExtState(Section, "x")
  if not HasState then
    x = 0
  else
    x = tonumber(reaper.GetExtState(Section, "x"))
  end
  y = reaper.HasExtState(Section, "y")
  if not HasState then
    y = 0
  else
    y = tonumber(reaper.GetExtState(Section, "y"))
  end
  gfx.setfont(1, "Arial", fontsize)
  local long = "Source Time Position:   edit cursor position not within selected item"
  local w, h = gfx.measurestr(long)
  gfx.init("PL9-amagalma Source Time Position Tool (v"..version..")", w + fontsize, fontsize*7, 0, x, y)
  change = false
end

--------------------------------------------------------------------------------------------
init()
main()

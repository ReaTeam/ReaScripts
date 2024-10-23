-- @description Search for the selected action in the Action List, or the open script in the IDE, in ReaPack
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma


local function GetSelectedActionFromActionList()
  local hWnd_action = reaper.JS_Window_Find("Actions", true)
  if not hWnd_action then return end
  local restore_column_state = false
  local hWnd_LV = reaper.JS_Window_FindChildByID(hWnd_action, 1323)
  local lv_header = reaper.JS_Window_HandleFromAddress(reaper.JS_WindowMessage_Send(hWnd_LV, "0x101F", 0,0,0,0)) -- 0x101F = LVM_GETHEADER
  local lv_column_count = reaper.JS_WindowMessage_Send(lv_header, "0x1200" ,0,0,0,0) -- 0x1200 = HDM_GETITEMCOUNT
  local third_item = reaper.JS_ListView_GetItemText(hWnd_LV, 0, 3)
  if lv_column_count < 4 or third_item == "" or third_item:find("[\\/:]") then
    -- show Command ID column
    reaper.JS_WindowMessage_Send(actions, "WM_COMMAND", 41170, 0, 0, 0)
    restore_column_state = true
  end
  -- get selected count & selected indexes
  local sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(hWnd_LV)
  if sel_count == 0 then
    return
  end
  local index = string.match(sel_indexes, '[^,]+')
  local desc = reaper.JS_ListView_GetItemText(hWnd_LV, tonumber(index), 1):gsub(".+: ", "", 1)
  return desc:gsub("(.*_)(.*)(%.%a+)$", "%2")
end


local script = GetSelectedActionFromActionList()
if not script then
  local IDE = reaper.JS_Window_Find( " - ReaScript Development Environment", false )
  if IDE then
    local title = reaper.JS_Window_GetTitle( IDE )
    script = title:gsub("([^%.]*)(%.%a%a%a? %- ReaScript Development Environment)$", "%1")
    script = script:gsub("(.*_)(.*)", "%2")
  end
end

if script then
  reaper.ReaPack_BrowsePackages( script )
end
reaper.defer(function() end)

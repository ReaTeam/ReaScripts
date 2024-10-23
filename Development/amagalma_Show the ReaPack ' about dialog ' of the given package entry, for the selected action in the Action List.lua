-- @description Show the ReaPack ' about dialog ' of the given package entry, for the selected action in the Action List
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about
--   Shows the ReaPack " about dialog " of the given package entry, for the selected action in the Action List
--
--   - JS_ReaScriptAPI is required


local function GetSelectedActionPathFromActionList()
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
  local index = tonumber(string.match(sel_indexes, '[^,]+'))
  local path = reaper.JS_ListView_GetItemText(hWnd_LV, index, 4)
  if path ~= "" then
    local sep = package.config:sub(1,1)
    local name = reaper.JS_ListView_GetItemText(hWnd_LV, index, 1):gsub(".+: ", "", 1)
    local absolute
    if string.match(reaper.GetOS(), "Win") then
      if path:match("^%a:\\") or path:match("^\\\\") then
        absolute = true
      end
    else -- unix
      absolute = path:match("^/")
    end
    if absolute then
      return path .. sep .. name
    else
      return reaper.GetResourcePath() .. sep .. "Scripts" .. sep .. path .. sep .. name
    end
  end
end


local path = GetSelectedActionPathFromActionList()
if path and reaper.file_exists( path ) then
  local entry, err = reaper.ReaPack_GetOwner( path )
  if entry then
    reaper.ReaPack_AboutInstalledPackage( entry )
    reaper.ReaPack_FreeEntry( entry )
  end
  if err and err ~= ""then
    reaper.MB(err, "ReaPack Message:", 0)
  end
end
reaper.defer(function() end)

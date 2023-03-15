-- @description Get number (count) of all actions in the Action List
-- @author amagalma & Edgemeal
-- @version 1.01
-- @changelog - Do not include Main (alt recording) actions in Total number 
-- @about - Requires JS_ReaScriptAPI


-- Check if JS_ReaScriptAPI is installed
if not reaper.APIExists("JS_Window_Find") then
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "JS_ReaScriptAPI Installation", 0 )
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then
    reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else
    reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
end


local function SetComboBoxIndex(hwnd, index)
  local id = reaper.JS_Window_AddressFromHandle(reaper.JS_Window_GetLongPtr(hwnd, "ID")) 
  reaper.JS_WindowMessage_Send(hwnd, "CB_SETCURSEL", index,0,0,0)
  reaper.JS_WindowMessage_Send(reaper.JS_Window_GetParent(hwnd), "WM_COMMAND", id, 1, reaper.JS_Window_AddressFromHandle(hwnd), 0)
end

local opened = false
if reaper.GetToggleCommandState( 40605 ) ~= 1 then
  reaper.Main_OnCommand(40605, 0) -- Show action list
  opened = true
end


local action = reaper.JS_Window_Find("Actions", true)
local cbobox = reaper.JS_Window_FindChildByID(action, 1317)
local count = reaper.JS_WindowMessage_Send(cbobox, "CB_GETCOUNT", 0,0,0,0)
local cur_sel = reaper.JS_WindowMessage_Send(cbobox, "CB_GETCURSEL", 0,0,0,0)
local lv = reaper.JS_Window_FindChildByID(action, 1323)
local filter = reaper.JS_Window_FindChildByID( action, 1324 )
local title = reaper.JS_Window_GetTitle( filter )


local function GetCount()
  local total = 0
  reaper.ClearConsole()
  for i = 0, count-1 do
    SetComboBoxIndex(cbobox, i)
    local num = reaper.JS_ListView_GetItemCount(lv)
    if i ~=1 then total = total + num end
    reaper.ShowConsoleMsg(reaper.JS_Window_GetTitle(cbobox) .. " : " .. num .. " actions\n")
  end
  reaper.ShowConsoleMsg("\nTotal number of actions: " .. total .. "\n\n")
  if not opened then
    SetComboBoxIndex(cbobox, cur_sel)
  end
end


local function Finish()
  if opened then
    reaper.JS_Window_Destroy( action )
  end
  return reaper.defer(function() end)
end


local start = reaper.time_precise()
local function wait()
  if reaper.time_precise() > start + 1 then
    GetCount()
    reaper.JS_Window_SetTitle( filter, title )
    return Finish()
  else
    reaper.defer(wait)
  end
end


if title ~= "" then
  reaper.JS_Window_SetTitle( filter, "" )
  wait()
else
  GetCount()
  return Finish()
end

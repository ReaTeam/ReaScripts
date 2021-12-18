-- @description Get number of all actions in the Action List
-- @author amagalma
-- @version 1.00
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

if reaper.GetToggleCommandState( 40605 ) ~= 1 then
  reaper.Main_OnCommand(40605, 0) -- Show action list
end
local hWnd_action = reaper.JS_Window_Find("Actions", true)
local hWnd_LV = reaper.JS_Window_FindChildByID(hWnd_action, 1323)
local filter = reaper.JS_Window_FindChildByID( hWnd_action, 1324 )
local title = reaper.JS_Window_GetTitle( filter )

local function ShowCount()
  reaper.ShowConsoleMsg( reaper.JS_ListView_GetItemCount( hWnd_LV ) .. " actions in the Action List.\n")
end

local start = reaper.time_precise()
local function wait()
  if reaper.time_precise() > start + 1 then
    ShowCount()
    reaper.JS_Window_SetTitle( filter, title )
    return reaper.defer(function() end)
  else
    reaper.defer(wait)
  end
end

if title ~= "" then
  reaper.JS_Window_SetTitle( filter, "" )
  wait()
else
  ShowCount()
  return reaper.defer(function() end)
end

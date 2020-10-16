-- @description Delete and retain selected items in project
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showthread.php?t=243487
-- @donation https://www.paypal.me/amagalma
-- @about
--   Runs action "Item: Remove items" (40006).  If Project Bay's setting "Automatically retain items when removed from project" is set to off, the script opens Project Bay, sets the setting to on, then runs action 40006 and sets the setting back to off (in effect deleting but retaining the items if they were removed from the project).
--
--   Notes:
--   -The script will Show the Project Bay window if not already open
--   - Requires JS_ReaScriptAPI to run
--   - If for some reason, it doesn't work well, try increasing the delay value inside the script
--   - If the delete action is undone, the items will stay in retained mode


-- USER SETTING --------------------------------------------------------------------------
local delay = 0.3 -- if not working properly, try increasing value to 0.33, 0.35, 0.38 etc
-- it will make action slower, but fail safe
------------------------------------------------------------------------------------------


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


local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt == 0 then return end


local retain_enabled = tonumber(({reaper.BR_Win32_GetPrivateProfileString( "projbay",
                       "filterflag", "", reaper.get_ini_file())})[2]) & 8 == 8

if not retain_enabled then

    delay = delay >= 0.3 and delay or 0.3

    -- Show project bay window if not open
    local focused_win = reaper.JS_Window_GetFocus()
    local hwnd = reaper.JS_Window_Find( "Project Bay", true )
    local open
    if not hwnd then
      reaper.Main_OnCommand(41157, 0)
      hwnd = reaper.JS_Window_Find( "Project Bay", true )
      open = true
    end

    local options = reaper.JS_Window_FindChildByID( hwnd, 1545 ) or
                    reaper.JS_Window_FindChild( hwnd, "Options", true )

    local function Click(selection)
      reaper.JS_WindowMessage_Post(options, "WM_LBUTTONDOWN", 0x0001, 0, 5, 5)
      reaper.JS_WindowMessage_Post(options, "WM_LBUTTONUP", 0x0000, 0, 5, 5)
      reaper.JS_Window_SetFocus( options )
      for i = 1, selection do
        reaper.JS_WindowMessage_Post(options, "WM_KEYDOWN", 0x28, 0, 0, 0)
      end
      reaper.JS_WindowMessage_Post(options, "WM_KEYDOWN", 0x0D, 0, 0, 0)
    end

    local start = reaper.time_precise() + (open and 0.4 or 0.1)
    local begin, go_step1, go_step2, go_step3, done = true

    local function loop()
      local time = reaper.time_precise()
      if go_step3 and time > start then
        Click(11) -- Click Retain
        done = true
      elseif go_step2 and time > start then
        reaper.Main_OnCommand(40006, 0) -- Remove items
        go_step2, go_step3 = nil, true
        start = time + delay
      elseif go_step1 then
        Click(11) -- Click Retain
        go_step1, go_step2 = nil, true
        start = time + delay
      elseif begin and time > start then
        go_step1 = true
        begin = nil
      end
      if not done then
        reaper.defer(loop)
      else
        reaper.JS_Window_SetFocus( focused_win )
        return
      end
    end

    loop()

else

    reaper.Main_OnCommand(40006, 0) -- Remove items

end

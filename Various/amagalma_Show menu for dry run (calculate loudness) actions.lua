-- @description Show menu for dry run (calculate loudness) actions
-- @author amagalma
-- @version 1.02
-- @changelog Added option to calculate for Selected Items
-- @link https://forum.cockos.com/showthread.php?t=239556
-- @screenshot https://i.ibb.co/9w5VJwZ/dry-run-menu.gif
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Shows a menu with all the dry run actions at the mouse cursor
--
--   - Requires JS_ReaScriptAPI


if not reaper.APIExists( "JS_Window_Find" ) then
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "You need to install the JS_ReaScriptAPI", 0 )
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
end

local t = {
  { "#Calculate loudness via dry run render|" },
  { "Master Mix", 42440 },
  { "Selected Tracks", 42438 },
  { "Selected Tracks (mono)", 42447 },
  { "Selected Items", 42468 },
  { "Selected Items (including take/track FX and settings)|", 42437 },
  { ">Within Time Selection" },
  { "Master Mix", 42441 },
  { "Selected Tracks", 42439 },
  { "<Selected Tracks (mono)", 42448 },
}

local menu = ""
for i = 1, #t do
  menu = menu .. t[i][1] .. "|"
end
local title = "hidden " .. reaper.genGuid()
gfx.init( title, 0, 0, 0, 0, 0 )
local hwnd = reaper.JS_Window_Find( title, true )
if hwnd then
  reaper.JS_Window_Show( hwnd, "HIDE" )
end
gfx.x, gfx.y = gfx.mouse_x-52, gfx.mouse_y-70
local selection = gfx.showmenu(menu)
gfx.quit()

if selection > 0 then
  if selection > 6 then selection = selection + 1 end
  if t[selection][2] then
    reaper.Main_OnCommand(t[selection][2], 0)
  end
end
reaper.defer(function() end)

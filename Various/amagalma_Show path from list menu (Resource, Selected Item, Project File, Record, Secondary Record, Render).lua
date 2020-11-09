-- @description Show path from list menu (Resource, Selected Item, Project File, Record, Secondary Record, Render)
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showthread.php?t=239556
-- @screenshot https://i.ibb.co/vhMDkZn/Show-path-from-list-menu.gif
-- @donation https://www.paypal.me/amagalma
-- @about
--   Shows the chosen item's path from the list:
--   - Reaper Resources path
--   - Selected Item path
--   - Project File path
--   - Record path
--   - Secondary Record path
--   - Render path
--
--   - Requires JS_ReaScriptAPI and SWS extensions


if not reaper.APIExists( "JS_Window_Find" ) then
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "You need to install the JS_ReaScriptAPI", 0 )
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
end

local t = {
      {"#Show path in explorer/finder|"},
      {"Reaper Resources path", 40027},
      {"Selected Item path", '_S&M_OPEN_ITEM_PATH'},
      {"Project File path", '_S&M_OPEN_PRJ_PATH'},
      {"Record path", 40024},
      {"Secondary Record path", 40028},
      {"Render path", '_AUTORENDER_OPEN_RENDER_PATH'},
}

local menu = ""
for i = 1, #t do
  menu = menu .. t[i][1] .. "|"
end

local proj_file = ({reaper.EnumProjects( -1 )})[2]

local title = "Hidden gfx window for showing the paths showmenu"
gfx.init( title, 0, 0, 0, 0, 0 )
local hwnd = reaper.JS_Window_Find( title, true )
local out = 0
if hwnd then
  out = 7000
  reaper.JS_Window_Move( hwnd, -out, -out )
end
out = reaper.GetOS():find("OSX") and 0 or out
gfx.x, gfx.y = gfx.mouse_x-52+out, gfx.mouse_y-70+out
local selection = gfx.showmenu(menu)
gfx.quit()

if selection > 0 then
  if selection == 4 and proj_file ~= "" then
    reaper.CF_LocateInExplorer( proj_file )
  else
    reaper.Main_OnCommand(reaper.NamedCommandLookup(t[selection][2]), 0)
  end
end
reaper.defer(function() end)

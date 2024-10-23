-- @description Go to marker (choose from menu list)
-- @author amagalma
-- @version 1.03
-- @changelog Fix menu placement for OSX (again)
-- @donation https://www.paypal.me/amagalma
-- @about
--   Displays a menu list at the mouse cursor with all markers in project in a timeline order. Navigates to the chosen marker.
--
--   - Requires JS_ReascriptAPI


if not reaper.APIExists( "JS_Window_Find" ) then
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "You need to install the JS_ReaScriptAPI", 0 )
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
end

local _, num_markers = reaper.CountProjectMarkers( 0 )
if num_markers < 1 then
  reaper.MB("There are no markers in the project.", "Not any markers...", 0)
  return reaper.defer(function() end)
end

local markers = {}
local cur_pos = reaper.GetCursorPosition()
local idx = -1
while true do
  idx = idx + 1
  local ok, isrgn, pos, _, name, markrgnindexnumber = reaper.EnumProjectMarkers( idx )
  if ok == 0 then
    break
  else
    if not isrgn then
      if math.abs(cur_pos - pos) < 0.001 then
        markers[#markers+1] = {cur = true, name = name, idx = markrgnindexnumber}
      else
        markers[#markers+1] = {name = name, idx = markrgnindexnumber}
      end
    end
  end
end

local menu = "#GO TO MARKER:|#[ ID ]        [ Name ]||"
for m = 1, #markers do
  local space = "                "
  space = space:sub( tostring(markers[m].idx):len()*2 )
  menu = menu .. (markers[m].cur and "!" or "") .. markers[m].idx .. space .. (markers[m].name == "" and "(unnamed)" or markers[m].name) .."|"
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
  reaper.GoToMarker( 0, selection-2, true )
end
reaper.defer(function() end)

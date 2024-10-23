-- @description Choose active take for item under mouse (show menu)
-- @author amagalma
-- @version 1.02
-- @changelog Fix menu placement for OSX (again)
-- @donation https://www.paypal.me/amagalma
-- @about
--   Displays a menu with all the takes (and their names) available for the item under the mouse cursor.
--   Selection sets the take as active.
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

local x, y = reaper.GetMousePosition()
local item, take = reaper.GetItemFromPoint( x, y, true )
if not take then return reaper.defer(function() end) end

local takes = {}
local active_tk = reaper.GetActiveTake( item )
local take_cnt = reaper.CountTakes( item )
for tk = 0, take_cnt-1 do
  local take = reaper.GetMediaItemTake( item, tk )
  local name = reaper.GetTakeName( take )
  if take == active_tk then
    takes[tk+1] = {tk = take, name = name, act = true}
  else
    takes[tk+1] = {tk = take, name = name}
  end
end


local menu = "#CHOOSE TAKE:|#[ ID ]        [ Name ]||"
for tk = 1, #takes do
  local space = "                "
  space = space:sub( tostring(tk):len()*2 )
  menu = menu .. (takes[tk].act and "!" or "") ..tk .. space .. (takes[tk].name == "" and "(unnamed)" or takes[tk].name) .."|"
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
  reaper.SetActiveTake( reaper.GetMediaItemTake( item, selection-3 ) )
  reaper.UpdateArrange()
  reaper.Undo_OnStateChange2( 0, string.format("Set take %i active", selection-2) )
end
reaper.defer(function() end)

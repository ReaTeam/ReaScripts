-- @description Set project grid (via dropdown menu)
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showthread.php?t=239556
-- @donation https://www.paypal.com/paypalme/amagalma
-- @about
--   # Set project grid (via dropdown menu)
--
--   - Displays a dropdown menu at mouse cursor position where you can choose a grid setting
--   - Requires JS_ReaScriptAPI


if not reaper.APIExists( "JS_Window_Find" ) then
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "You need to install the JS_ReaScriptAPI", 0 )
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
end

local m =
{
  {1, "1/1    -  whole note"},
  {-1/2, ">1/2    -  half note"},
  {3/4, "3/4  -  dotted half note"},
  {1/2, "1/2  -  half note"},
  {1/3, "<1/3  -  half note triplet"},
  {-1/4, ">1/4    -  quarter note"},
  {3/8, "3/8  -  dotted quarter note"},
  {1/4, "1/4  -  quarter note"},
  {1/6, "<1/6  -  quarter note triplet"},
  {-1/8, ">1/8    -  eighth note"},
  {3/16, "3/16  -  dotted eighth note"},
  {1/8, "1/8    -  eighth note"},
  {1/12, "<1/12  -  eighth note triplet"},
  {-1/16, ">1/16  -  sixteenth note"},
  {3/32, "3/32  -  dotted sixteenth note"},
  {1/16, "1/16  -  sixteenth note"},
  {1/24, "<1/24  -  sixteenth note triplet"},
  {-1/32, ">1/32  -  thirty-second note"},
  {3/64, "3/64  -  dotted thirty-second note"},
  {1/32, "1/32  -  thirty-second note"},
  {1/48, "<1/48  -  thirty-second note triplet"},
  {-1/64, ">1/64  -  sixty-fourth note"},
  {3/128, "3/128  -  dotted sixty-fourth note"},
  {1/64, "1/64    -  sixty-fourth note"},
  {1/96, "<1/96    -  sixty-fourth note triplet"}
}

local _, division = reaper.GetSetProjectGrid( 0, 0, 0, 0, 0 )

local menu = "#Set grid to :||"
for i = 1, #m do
  local togglestate
  if m[i][1] < 0 then
    local d = -m[i][1]
    if d * 1.5 == division or division == d * (2/3) or d == division then
      togglestate = "!"
    else
      togglestate = ""
    end
  else
    togglestate = m[i][1] == division and "!" or ""
  end
  menu = menu .. togglestate .. m[i][2] .. "|"
end

local title = "Hidden gfx window for showing the grid showmenu"
gfx.init( title, 0, 0, 0, 0, 0 )
local hwnd = reaper.JS_Window_Find( title, true )
local out = 0
if hwnd then
  out = 7000
  reaper.JS_Window_Move( hwnd, -out, -out )
end
local x, y = reaper.GetMousePosition()
gfx.x, gfx.y = x-40+out, y-40+out
local selection = gfx.showmenu(menu)
gfx.quit()

if selection > 0 then
  if selection < 3 then
    selection = 1
  else
    selection = selection + math.floor(selection/3) - 1
  end
  reaper.SetProjectGrid( 0, m[selection][1] )
end
reaper.defer(function() end)

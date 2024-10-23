-- @noindex
-- @version 1.05

if not reaper.APIExists( "JS_Window_Find" ) then
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "You need to install the JS_ReaScriptAPI", 0 )
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
end


local chosen_selection = tonumber(reaper.GetExtState("amagalma_Split at mouse cursor position", "selection")) or 3
local xfadeposition = tonumber(reaper.GetExtState("amagalma_Split at mouse cursor position", "xfadeposition")) or 1
local snaptogrid = tonumber(reaper.GetExtState("amagalma_Split at mouse cursor position", "snaptogrid")) or 0
local ignoregrouping = tonumber(reaper.GetExtState("amagalma_Split at mouse cursor position", "ignoregrouping")) or 0

local t = {
      {"#Selection after split:"},
      {"no change of selection", 1},
      {"select left", 2},
      {"select right", 3},
      {""},
      {"#Auto crossfade position:"},
      {"on the left side", 1},
      {"centered at mouse cursor position", 0.5},
      {"on the right side", 0},
      {"|#Respect snap and grouping settings:"},
      {"snap to grid is respected", snaptogrid},
      {"item grouping is respected", ignoregrouping},
}


local menu = '#"amagalma_Split at mouse cursor position" Settings||'
for i = 1, #t do
  local check = ""
  if i > 1 and i < 5 then
    if chosen_selection == i-1 then check = "!" end
  elseif i > 6 and i < 10 then
    if xfadeposition == t[i][2] then check = "!" end
  elseif i == 11 then
    if snaptogrid == 1 then check = "!" end
  elseif i == 12 then
    if ignoregrouping == 0 then check = "!" end
  end
  menu = menu .. check .. t[i][1] .. "|"
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


if selection > 2 and selection <= 5 then
  reaper.SetExtState("amagalma_Split at mouse cursor position", "selection", t[selection-1][2], true)
elseif selection > 6 and selection < 10 then
  reaper.SetExtState("amagalma_Split at mouse cursor position", "xfadeposition", t[selection][2], true)
elseif selection == 11 then
  reaper.SetExtState("amagalma_Split at mouse cursor position", "snaptogrid", 1 - snaptogrid, true)
elseif selection == 12 then
  reaper.SetExtState("amagalma_Split at mouse cursor position", "ignoregrouping", 1 - ignoregrouping, true)
end
reaper.defer(function() end)

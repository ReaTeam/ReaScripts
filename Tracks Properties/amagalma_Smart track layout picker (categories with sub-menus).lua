-- @description Smart track layout picker (categories with sub-menus)
-- @author amagalma
-- @version 1.03
-- @changelog Fix menu placement for OSX (again)
-- @link https://forum.cockos.com/showthread.php?t=230114
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Smart track layout picker (categories with sub-menus)
--
--   - Displays a pop-up menu with all the available tcp/mcp layouts for the track under the mouse cursor or for the selected tracks, categorized in sub-menus
--   - Smart undo naming
--   - Requires JS_ReascriptAPI


if not reaper.APIExists( "JS_Window_Find" ) then
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "You need to install the JS_ReaScriptAPI", 0 )
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
end


local track_at_mouse, context = reaper.BR_TrackAtMouseCursor()
local tracks = {}
local current_layout, _ = "[--not specified--]"
if track_at_mouse then
  tracks[1] = track_at_mouse
end
local track_cnt = reaper.CountSelectedTracks( 0 )
for i = 0, track_cnt-1 do
  local track = reaper.GetSelectedTrack( 0, i )
  if track_at_mouse ~= track then
    tracks[#tracks+1] = track
  end
end
if #tracks == 0 then return reaper.defer(function() end ) end


local function alphanumsort(o)
  -- http://notebook.kulchenko.com/algorithms/alphanumeric-natural-sorting-for-humans-in-lua
  local function padnum(d) return ("%03d%s"):format(#d, d) end
  table.sort(o, function(a,b)
    return tostring(a):gsub("%d+",padnum) < tostring(b):gsub("%d+",padnum) end)
  return o
end


local layout_parm
if context == 0 or context == 2 then
  layout_parm = "P_TCP_LAYOUT"
  context = "tcp"
else
  layout_parm = "P_MCP_LAYOUT"
  context = "mcp"
end
if #tracks == 1 then
  _, current_layout = reaper.GetSetMediaTrackInfo_String( tracks[1], layout_parm, "", false )
end


local i = 0
local t = {}
repeat
  local retval, name = reaper.ThemeLayout_GetLayout( context, i)
  i = i + 1
  if retval and name ~= "" then
    local words = {}
    local previous = ""
    local max_word = nil
    for separator, word in name:gmatch("([%s-_]*)([^%s-_]+)") do
      local scalar = previous .. (separator or "") .. word
      words[#words+1] = scalar
      if t[scalar] then
        max_word = scalar
        t[scalar][#t[scalar]+1] = name
      else
        t[scalar] = { [1] = name }
      end
      previous = scalar
    end
    for w = 1, #words do
      if max_word and words[w] ~= max_word then
        t[words[w]] = nil
      end
    end
  end
until not retval


for menu, tabl in pairs(t) do
  if #tabl > 1 then
    alphanumsort(tabl)
    for i = #tabl, 1, -1 do
      if t[tabl[i]] and tabl[i] ~= menu then
        t[tabl[i]] = nil
      end
    end
  end
end
words = nil
local n = {}
for section in pairs(t) do
  n[#n+1] = section
end
alphanumsort(n)


local r = 2
local register = {[r] = ""}
local menu = "#" .. context:upper() .. " LAYOUTS|" .. (current_layout == "" and "!" or "") .. "Global layout default|"
for i = 1, #n do
  if #t[n[i]] == 1 then
    menu = menu .. (n[i] == current_layout and "!" or "") .. n[i] .. "|"
    r = r + 1
    register[r] = n[i]
  else
    menu = menu .. ">" .. n[i] .. "|"
    for j = 1, #t[n[i]] do
      menu = menu .. (j == #t[n[i]] and "<" or "").. (t[n[i]][j] == current_layout and "!" or "") .. t[n[i]][j] .. "|"
      r = r + 1
      register[r] = t[n[i]][j]
    end
  end
end

local title = "hidden " .. reaper.genGuid()
gfx.init( title, 0, 0, 0, 0, 0 )
local hwnd = reaper.JS_Window_Find( title, true )
if hwnd then
  reaper.JS_Window_Show( hwnd, "HIDE" )
end
gfx.x, gfx.y = gfx.mouse_x-40, gfx.mouse_y-40
local selection = gfx.showmenu(menu)
gfx.quit()


if selection > 0 then
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  for i = 1, #tracks do
    reaper.GetSetMediaTrackInfo_String( tracks[i], layout_parm, register[selection], true)
  end
  reaper.PreventUIRefresh(-1)
  local undo = "Set " .. context:upper() .. " layout to global default"
  if register[selection] ~= "" then
    undo = "Set " .. context:upper() .. " layout to " .. register[selection]
  end
  reaper.Undo_EndBlock( undo, 1 )
else
  return reaper.defer(function() end)
end

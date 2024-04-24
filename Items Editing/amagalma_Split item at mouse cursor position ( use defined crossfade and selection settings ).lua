-- @description Split item at mouse cursor position ( use defined crossfade and selection settings )
-- @author amagalma
-- @version 1.05
-- @changelog 
--       - Add ignore grouping setting
-- @provides [main] amagalma_Split item at mouse cursor position ( use defined crossfade and selection settings )/amagalma_Split item at mouse cursor position ( Define crossfade and selection settings ).lua > amagalma_Split item at mouse cursor position ( Define crossfade and selection settings ).lua
-- @donation https://www.paypal.me/amagalma
-- @about
--   Splits item(s) under mouse cursor at the mouse cursor position according to the settings defined by additional settings script. Settings for:
--   - Selection: left, right or no change
--   - Automatic crossfades: to the left, centered or to the right
--   - Respect or not Snap to Grid
--   - Respect or not item grouping


local x, y = reaper.GetMousePosition()
local item_mouse = reaper.GetItemFromPoint( x, y, true )
if not item_mouse then return end

-------------------------

local selection = {
  [1] = 40757, -- Split items at edit cursor (no change selection)
  [2] = 40758, -- Split items at edit cursor (select left)
  [3] = 40759 -- Split items at edit cursor (select right)
}

local chosen_selection = tonumber(reaper.GetExtState("amagalma_Split at mouse cursor position", "selection")) or 3
local xfadeposition = tonumber(reaper.GetExtState("amagalma_Split at mouse cursor position", "xfadeposition")) or 1
-- xfadeposition : 1 = left, 0.5 = center, 0 = right
local snaptogrid = tonumber(reaper.GetExtState("amagalma_Split at mouse cursor position", "snaptogrid")) == 1
local ignoregrouping = tonumber(reaper.GetExtState("amagalma_Split at mouse cursor position", "ignoregrouping")) == 1

-------------------------

local hzoomlevel = reaper.GetHZoomLevel()
local arrangeview = reaper.JS_Window_FindChildByID( reaper.GetMainHwnd(), 1000 )
local _, left, _, right = reaper.JS_Window_GetClientRect( arrangeview ) -- without scrollbars
local mousepos = reaper.GetSet_ArrangeView2( 0, false, left, right ) +
                 (x + reaper.JS_Window_ScreenToClient( arrangeview, 0, 0 )) / hzoomlevel


local function GetExpectedXFadeLength()

  local take = reaper.GetActiveTake( item_mouse )
  if not take then -- empty item
    return 0
  else
    local source_type = reaper.GetMediaSourceType( reaper.GetMediaItemTake_Source( take ), "" )
    if source_type == "MIDI" or source_type == "VIDEOEFFECT" then 
      return 0
    end
  end

  local xfadetime = tonumber(({reaper.get_config_var_string( "defsplitxfadelen" )})[2])
  if not xfadetime then
    error('Could not retrieve "defsplitxfadelen" from reaper.ini')
  end
  local splitautoxfade = tonumber(({reaper.get_config_var_string( "splitautoxfade" )})[2])

  local restricted_len_by_perc = ((right - left)*0.5) / hzoomlevel
  local restricted_by_px = (splitautoxfade and (splitautoxfade & 256 == 256)) and
                           (tonumber(({reaper.get_config_var_string( "splitmaxpix" )})[2])) / hzoomlevel
  local restricted_len = (restricted_by_px and restricted_by_px < restricted_len_by_perc) and
                          restricted_by_px or restricted_len_by_perc
  if hzoomlevel >= 96000 then -- nofade
    return 0
  else
    if xfadetime <= restricted_len then -- fade
      return xfadetime
    else -- restrict
      return restricted_len
    end
  end
end

-------------------------

if chosen_selection == 2 then -- fix: 40758 crossfades left!
  xfadeposition = xfadeposition - 1
end

local cur_pos = reaper.GetCursorPosition()

reaper.PreventUIRefresh( 1 )
reaper.Undo_BeginBlock()

if ignoregrouping and reaper.GetToggleCommandState( 1156 ) == 1 then
  reaper.Main_OnCommand(1156, 0) -- Toggle item grouping and track media/razor edit grouping
  reenable = true
end

reaper.SetEditCurPos( (snaptogrid and reaper.SnapToGrid( 0, mousepos ) or mousepos ) - 
                      (xfadeposition * GetExpectedXFadeLength()), false, false )
reaper.Main_OnCommand( selection[chosen_selection], 0 )

reaper.SetEditCurPos( cur_pos, false, false )

if reenable then
  reaper.Main_OnCommand(1156, 0) -- Toggle item grouping and track media/razor edit grouping
end

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()
reaper.Undo_EndBlock( "Split items", 4 )

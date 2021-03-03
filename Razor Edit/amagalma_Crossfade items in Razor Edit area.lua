-- @description Crossfade items in Razor Edit area
-- @author amagalma
-- @version 1.00
-- @screenshot https://i.ibb.co/Bgx3X62/crossfade-items-in-razor-edit-area.gif
-- @donation https://www.paypal.me/amagalma
-- @about
--   Turns the RE area into a crossfade between the items that are inside it. Works with up to two items per track.
--
--   You can set inside the script if you want to keep the RE area or not and force a specific crossfade shape (otherwise the one set in Reaper Preferences is used).


-- USER SETTINGS --------------------------------------------------------
local xfadeshape = nil -- enter a valid number (0-7) or enter nil to apply the shape set in Reaper Preferences
local remove_RE_area = true -- keeps or removes the RE area (true/false)
-------------------------------------------------------------------------


local track_cnt = reaper.CountTracks(0)
if track_cnt == 0 then return reaper.defer(function() end) end

if xfadeshape and (xfadeshape < 0 or xfadeshape > 7) then
  xfadeshape = nil
end
if not xfadeshape then
  xfadeshape = tonumber(({reaper.get_config_var_string( "defxfadeshape" )})[2]) or 7
end

local tracks_with_RE, tr = {}, 0

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh( 1 )

for t = 0, track_cnt - 1 do
  local track = reaper.GetTrack(0, t)
  local _, area = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
  if area ~= "" then
    local areaS, areaE = area:match("(%S+) (%S+)")
    areaS, areaE = tonumber(areaS), tonumber(areaE)
    local item_cnt = reaper.CountTrackMediaItems(track)
    local items = {}
    local i = 0
    local continue = true
    while i ~= item_cnt do
      local item = reaper.GetTrackMediaItem(track, i)
      local Start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local End = Start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      if (Start >= areaS and Start < areaE) or 
           (End >= areaS and Start < areaE) or
          (Start <= areaS and End >= areaE) then
        items[#items+1] = {item, Start, End}
      end
      if Start >= areaE or #items > 2 then break end
      i = i + 1
    end
    if #items == 2 then
      tr = tr + 1
      tracks_with_RE[tr] = track
      reaper.BR_SetItemEdges( items[1][1], items[1][2], areaE )
      reaper.SetMediaItemInfo_Value( items[1][1], "D_FADEOUTLEN_AUTO", areaE - areaS )
      reaper.SetMediaItemInfo_Value(items[1][1], "C_FADEOUTSHAPE", xfadeshape)
      reaper.BR_SetItemEdges( items[2][1], areaS, items[2][3] )
      reaper.SetMediaItemInfo_Value( items[2][1], "D_FADEINLEN_AUTO", areaE - areaS )
      reaper.SetMediaItemInfo_Value(items[2][1], "C_FADEINSHAPE", xfadeshape)
    end
  end
end

if remove_RE_area then
  for i = 1, tr do
    reaper.GetSetMediaTrackInfo_String(tracks_with_RE[i], "P_RAZOREDITS", "", true)
  end
end

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()
reaper.Undo_EndBlock( "Crossfade items in RE area", (remove_RE_area and 1 or 0)|4 )

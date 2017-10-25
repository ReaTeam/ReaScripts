-- @description amagalma_Script: Implode items across tracks into takes (remove empty tracks)
-- @author amagalma
-- @version 1.1
-- @about
--   # Script: Implodes items across tracks into takes, removes empty tracks and inherits their height (optional)
--
-- @screenshot http://stash.reaper.fm/30479/amagalma_Implode%20items%20across%20tracks%20into%20takes%20%28remove%20empty%20tracks%29.gif

--[[
 * Changelog:
 * v1.1 (2017-10-08)
  + takes now inherit their previous displayed color
  + you can set in the script if you want the resulting track to inherit all removed tracks' heights combined or not
--]]


--------------------------------------------------------------------------------------------------

------------------------------- USER SETTINGS --------------------------------------------
local inherit = 1 -- set to 1 to inherit all removed tracks' heights combined, 0 to not  -
------------------------------------------------------------------------------------------

local reaper = reaper
local item_cnt = reaper.CountSelectedMediaItems(0)
local colors = {}

--------------------------------------------------------------------------------------------------

function Main()
  local firsttrack = reaper.GetMediaItem_Track( reaper.GetSelectedMediaItem(0, 0) )
  reaper.Main_OnCommand(40297,0) -- Track: Unselect all tracks
  for i = 0, item_cnt-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    reaper.SetTrackSelected(reaper.GetMediaItemTrack(item), true)
    if reaper.GetMediaItem_Track( reaper.GetSelectedMediaItem(0, i) ) ~= firsttrack then
      local color = reaper.GetDisplayedMediaItemColor( item )
      local source = reaper.GetMediaItemTake_Source(reaper.GetActiveTake( item ))
      colors[#colors+1] = {source = source, color = color}
    end
  end  
  reaper.Main_OnCommand(40438, 0) -- Take: Implode items across tracks into takes
  -- inherit colors
  item_cnt = reaper.CountSelectedMediaItems(0)
  for i = 0, item_cnt-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local takes_cnt = reaper.CountTakes( item )
    for j = 0, takes_cnt-1 do
      local take = reaper.GetMediaItemTake( item, j )
      local source = reaper.GetMediaItemTake_Source(take)
      for k = 1, #colors do
        if source == colors[k].source then
          local color = colors[k].color
          reaper.SetMediaItemTakeInfo_Value( take, "I_CUSTOMCOLOR", color|0x1000000)
          break
        end
      end
    end
  end
  local track_cnt = reaper.CountSelectedTracks(0)
  local total_h = 0
  for i = track_cnt-1, 0, -1  do
    local track = reaper.GetSelectedTrack(0, i)
    local tcp_h = reaper.GetMediaTrackInfo_Value(track, "I_WNDH")
    total_h = total_h + tcp_h
    if reaper.CountTrackMediaItems(track) == 0 then
      reaper.DeleteTrack(track)
    end
  end
  -- inherit tracks' height
  if inherit == 1 then
    local track = reaper.GetSelectedTrack(0,0)
    reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", total_h)
  end
end

--------------------------------------------------------------------------------------------------

if item_cnt > 1 then
  reaper.Undo_BeginBlock()
  Main()
  reaper.TrackList_AdjustWindows(0)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Implode items across tracks into takes (remove empty tracks)", 1|4|8)
end

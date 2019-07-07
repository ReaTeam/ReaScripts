-- @description SUBPROJECT - Fix markers
-- @author nvk
-- @version 0.9beta
-- @changelog beta
-- @about
--   # Game Audio Workflow
--
--   A collection of scripts designed to improve workflow for common game audio tasks such as item editing, renaming, folder creation, and subproject management. Click [here](https://www.youtube.com/c/NickvonKaenel) for more information.

--[[
 * ReaScript Name: Script: nvk_SUBPROJECT - Fix markers
 * Description: Will move subproject start and end markers to time selection/item selection/all items/cursor depending on context
 * Author: Nick von Kaenel
 * Author Website: nickvonkaenel.com
 * Special thanks (for contributing code): X-Raym , ausbaxter, me2beats
 * Repository Website: https://github.com/NickvonKaenel/ReaScripts
 * REAPER: 5.979
 * Extensions: SWS/S&M 2.10.0
 * Version: 0.9beta
--]]


function SelectAllItemsExceptVideoInSubprojectRange()
  reaper.Main_OnCommand(40289, 0) --unselect all items
  tracks = reaper.CountTracks(0)
  for i=0, tracks-1 do
    track = reaper.GetTrack(0, i)
    retval, trackname = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "something", false)
    trackname = string.upper(trackname)
    if trackname ~= "VIDEO" then
      track_items_count = reaper.CountTrackMediaItems(track)
      for i=0, track_items_count-1 do
        item = reaper.GetTrackMediaItem(track,i)
        reaper.SetMediaItemSelected(item,true)
      end
    end
  end
end


function RemoveSubprojectMarkers()
  y=0
  while y==0 do

    retval, num_markersOut, num_regionsOut = reaper.CountProjectMarkers(0)
    a=0
    i=0
    while i<num_markersOut+num_regionsOut do
          retval2, isrgnOut, posOut, rgnendOut, nameOut, idexnum = reaper.EnumProjectMarkers(i)
      if isrgnOut==false then      
        if nameOut=="=START" then
          reaper.DeleteProjectMarker(0, idexnum, false)
        a=1
        end
        if nameOut=="=END" then
          reaper.DeleteProjectMarker(0, idexnum, false)
        a=1
        end  
      end
      i=i+1
    end
    if a==0 then
      y=1
    end 
  end
end



reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)


startOut, endOut = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
pos =  reaper.GetCursorPosition()

RemoveSubprojectMarkers()

if startOut==endOut then
  reaper.Main_OnCommand(40290, 0) --set time selection to items
  startOut, endOut = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if startOut==endOut then
    SelectAllItemsExceptVideoInSubprojectRange()
    reaper.Main_OnCommand(40290, 0) --set time selection to items
    startOut, endOut = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if startOut==endOut then
      reaper.AddProjectMarker(0, false, pos, 0, "=START", 1)
      reaper.AddProjectMarker(0, false, pos+5, 0, "=END", 2)
    else
      reaper.AddProjectMarker(0, false, startOut, 0, "=START", 1)
      reaper.AddProjectMarker(0, false, endOut, 0, "=END", 2)
    end
  else
    reaper.AddProjectMarker(0, false, startOut, 0, "=START", 1)
    reaper.AddProjectMarker(0, false, endOut, 0, "=END", 2)
  end
else
  reaper.AddProjectMarker(0, false, startOut, 0, "=START", 1)
  reaper.AddProjectMarker(0, false, endOut, 0, "=END", 2)
end

reaper.Main_OnCommand(40020, 0)  --remove time selection
reaper.Main_OnCommand(40289, 0)  --deselect all items


reaper.PreventUIRefresh(-1)

reaper.Undo_EndBlock("nvk_SUBPROJECT - Fix markers", 0)
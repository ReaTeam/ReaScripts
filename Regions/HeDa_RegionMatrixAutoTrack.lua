-- @version 0.1
-- @author Hector Corcin (HeDa)
-- @changelog
--   + init beta release
-- @description Automatically assigns a track with a certain name to all Regions in the Region Render Matrix
-- @link Forum Thread http://forum.cockos.com/showthread.php?t=180502
-- @website https://reaper.hector-corcin.com



--options:------------------------------------------------------------------------------------
name_of_track = "capture"
---------------------------------------------------------------------------------------


function FindTrackWithName(name)
  local tr
  for i=0, reaper.CountTracks(0)-1 do
    tr = reaper.GetTrack(0,i)
    local retval, trackname = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)  
    if trackname == name then 
      return tr, i
    end
  end
end
track = FindTrackWithName(name_of_track)
if track then 
	retval, num_markersOut, num_regionsOut = reaper.CountProjectMarkers(0)
	local i=0
	for f=0, num_markersOut+num_regionsOut-1 do
		retval, isrgnOut, posOut, rgnendOut, nameOut, markrgnindexnumberOut, colorOut = reaper.EnumProjectMarkers2(0, f)
		if isrgnOut then 
			reaper.SetRegionRenderMatrix(0, i+1, track, 1)
			i=i+1
		end
	end
end

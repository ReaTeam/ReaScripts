--[[
Description: Create folder to contain selected tracks
Version: 1.0.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Initial release
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
  Creates a new track to serve as a folder parent for the selected tracks,
  prompting the user for a name. The selected tracks must be contiguous and at
  the same folder depth for the script to behave properly.
--]]

-- Licensed under the GNU GPL v3

-- retval, retvals_csv = reaper.GetUserInputs( title, num_inputs, captions_csv, retvals_csv )
local ret, parentName = reaper.GetUserInputs("Create folder...", 1, "Parent name:", "")
if not ret then return end

local firstSel = reaper.GetSelectedTrack(0, 0)
if not firstSel then return end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh( 1 )

local idx = reaper.GetMediaTrackInfo_Value(firstSel, "IP_TRACKNUMBER") - 1
reaper.InsertTrackAtIndex(idx, true)
local parent = reaper.GetTrack(0, idx)

--[[
  I_FOLDERDEPTH : int * : folder depth change (0=normal, 1=track is a folder parent,
  -1=track is the last in the innermost folder, -2=track is the last in the innermost
  and next-innermost folders, etc
]]--

reaper.GetSetMediaTrackInfo_String( parent, "P_NAME", parentName, true )
reaper.SetMediaTrackInfo_Value( parent, "I_FOLDERDEPTH", 1, true )

local lastSel = reaper.GetSelectedTrack(0, reaper.CountSelectedTracks(0) - 1)

local curDepth = reaper.GetMediaTrackInfo_Value( lastSel, "I_FOLDERDEPTH" )
local newDepth = (curDepth == 0) and (curDepth - 1) or -1

reaper.SetMediaTrackInfo_Value( lastSel, "I_FOLDERDEPTH", newDepth, true )

reaper.PreventUIRefresh( -1 )

reaper.TrackList_AdjustWindows( false )
reaper.UpdateArrange()

reaper.Undo_EndBlock("Create folder to contain selected tracks", 0)

--[[
	This script is part of Lokasenna_Adjust ReaSamplomatic 5000 Pitch Offset.lua
	NoIndex: true
--]]

-- Licensed under the GNU GPL v3


---- RS5K Pitch Offset values ----

local val = 0.5				-- RS5K's Pitch Offset default value
local param = 15			-- RS5K's Pitch Offset parameter

local retval, tracknumberOut, itemnumberOut, fxnumberOut = reaper.GetFocusedFX() 

-- Adjust for the track given by GetFocusedFX being zero-based
local track = reaper.GetTrack( 0, tracknumberOut - 1 )

if not retval or retval == 0 then
	
	return 0 
	
elseif retval == 1 then

	reaper.TrackFX_SetParam( track, fxnumberOut, param, val )

elseif retval == 2 then

	local takenumberOut, fxnumberOut = fxnumberOut & 0xFFFF, fxnumberOut >> 16
	local item = reaper.GetTrackMediaItem( track, itemnumberOut )

	if not item then return 0 end

	local take = reaper.GetMediaItemTake( item, takenumberOut )
	
	if not take then return 0 end
	
	reaper.TakeFX_SetParam( take, fxnumberOut, param, val )
		
end

reaper.Undo_EndBlock("Adjust ReaSamplomatic 5000 Pitch Offset: Reset to 0.0", -1)
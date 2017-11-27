--[[
Description: Adjust RS5k pitch offset
Version: 1.3
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	- Added preliminary support for relative MIDI
	- Now uses a more accurate multiplier internally; prev. versions
	would add a cent of error every 13 semitones or so.
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Provides hotkey/MIDI functionality to adjust the pitch of a sample
	in ReaSamplomatic 5000
	
	For use with MIDI CCs, bind a control knob to one of the Up actions
	and set it for Relative control. Binding a CC to the Down actions 
	will work backwards.
Extensions:
Provides:
	[main] Lokasenna_Adjust ReaSamplomatic 5000 Pitch Offset/*.lua
--]]

-- Licensed under the GNU GPL v3


---- RS5K Pitch Offset values ----

local undo_str = (add or 0.01) .. " semitones"

-- Preliminary support for relative MIDI control
local new_val, fn, sID, cID, mode, res, val = reaper.get_action_context()

local frac =  0.0000625002384186
local add = (add or 0.01) * 100 * frac * ((mode > 0 and val ~= 0) and (math.abs(val) / val) or 1)
local param = 15			-- RS5K's Pitch Offset parameter

local retval, tracknumberOut, itemnumberOut, fxnumberOut = reaper.GetFocusedFX()

-- Adjust for the track given by GetFocusedFX being zero-based
local track = reaper.GetTrack( 0, tracknumberOut - 1 )

if not retval or retval == 0 then
	
	return 0 
	
elseif retval == 1 then

	local val, minvalOut, maxvalOut = reaper.TrackFX_GetParam( track, fxnumberOut, param )
	reaper.TrackFX_SetParam( track, fxnumberOut, param, val + add )

elseif retval == 2 then

	local takenumberOut, fxnumberOut = fxnumberOut & 0xFFFF, fxnumberOut >> 16
	local item = reaper.GetTrackMediaItem( track, itemnumberOut )

	if not item then return 0 end

	local take = reaper.GetMediaItemTake( item, takenumberOut )
	
	if not take then return 0 end
	
	local val, minvalOut, maxvalOut = reaper.TakeFX_GetParam( take, fxnumberOut, param )
	reaper.TakeFX_SetParam( take, fxnumberOut, param, val + add )
		
end

reaper.Undo_EndBlock("Adjust ReaSamplomatic 5000 Pitch Offset: "..undo_str, -1)

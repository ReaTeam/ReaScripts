--[[
Description: Create mix bus and reroute all top-level tracks to it
Version: 1.1.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Make sure sends are at unity gain, post-fader
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Inserts a new track at track #1, labelled "Mix Bus", then
    reroutes all top-level tracks to it that are currently sending 
    out to the Master track.
	
	i.e. the tracks listed with a * would have their Master/Parent
	send disabled, and would instead send to the Mix Bus:
	
	Master
	--Mix Bus <-- new track
	--Reverb bus *
	--NY Comp bus *
	--Drums *
	----Kick
	----Snare
	--Bass *
	--Guitars *
	----Guitar L
	----Guitar R
    
    This will only work properly for mono/stereo audio. Reaper makes
    multichannel support impractical. :(
--]]

-- Licensed under the GNU GPL v3

local function dMsg(str)
	if debug_mode then reaper.ShowConsoleMsg(tostring(str).."\n") end
end

reaper.Undo_BeginBlock()

reaper.PreventUIRefresh( 1 )

-- Create a new track @ idx 1, labelled Mix Bus
-- reaper.InsertTrackAtIndex( 1, true )
reaper.InsertTrackAtIndex(0, true)
local bus = reaper.GetTrack(0, 0)
retval, __ = reaper.GetSetMediaTrackInfo_String( bus, "P_NAME", "Mix Bus", true )

-- Loop through all tracks in the project
for i = 1, reaper.GetNumTracks() - 1 do
	
	dMsg("looking at track "..i)
	
	local tr = reaper.GetTrack(0, i)
	
	dMsg("\tdepth = "..reaper.GetTrackDepth(tr))
	dMsg("\tp_send = "..tostring( reaper.GetMediaTrackInfo_Value(tr, "B_MAINSEND") ) )
	

	-- If top-level and has Master Out enabled...
	-- reaper.GetTrackDepth( MediaTrack track ) and -- reaper.GetMediaTrackInfo_Value( MediaTrack tr, "B_MAINSEND" )
	if reaper.GetTrackDepth(tr) == 0 and reaper.GetMediaTrackInfo_Value(tr, "B_MAINSEND") then	
	
		dMsg("\trerouting")
		
		--[[
		-- Get the track's channel info
		local chans = reaper.GetMediaTrackInfo_Value(tr, "I_NCHAN")
		local offset = reaper.GetMediaTrackInfo_Value(tr, "C_MAINSEND_OFFS")
		]]--
	
		-- Disable Master Out
		reaper.SetMediaTrackInfo_Value(tr, "B_MAINSEND", 0)
		
		-- Add a post-fader send to idx 1
		local send = reaper.CreateTrackSend(tr, bus)

        -- Make sure send is at unity, post-fader (overriding default send values)
        reaper.SetTrackSendInfo_Value(tr, 0, send, "D_VOL", 1)
        reaper.SetTrackSendInfo_Value(tr, 0, send, "I_SENDMODE", 0)
		
	end
	
end

reaper.PreventUIRefresh( -1 )

reaper.TrackList_AdjustWindows( false )
reaper.UpdateArrange()

reaper.Undo_EndBlock("Create mix bus and route all top-level tracks to it", 0)


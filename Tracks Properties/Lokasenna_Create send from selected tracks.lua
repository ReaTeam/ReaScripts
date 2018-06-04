--[[
Description: Create send from selected tracks
Version: 1.00
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
    Initial release
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
    Prompts for a track number, then creates sends to that track
    from every selected track.
--]]

-- Licensed under the GNU GPL v3

local function Main()

    local num_tracks = reaper.CountSelectedTracks(0)

    if num_tracks == 0 then return end

    -- Prompt for destination track + offer chance to edit sel.
    -- retval, retvals_csv reaper.GetUserInputs( title, num_inputs, captions_csv, retvals_csv )
    local ret, dest_num = reaper.GetUserInputs("Create sends to...", 1, "Destination track #:", "")
    
    if not ret or not tonumber(dest_num) then return end
    
    local dest = reaper.GetTrack(0, tonumber(dest_num) - 1)
    
    reaper.Undo_BeginBlock()
    
    -- For each selected track
    local sel = {}
    for i = 0, num_tracks - 1 do
        
        local sel = reaper.GetSelectedTrack(0, i)

        -- Create a default send
        --reaper.CreateTrackSend( tr, desttrInOptional )
        reaper.CreateTrackSend(sel, dest)
        
    end
    
    reaper.Undo_EndBlock("Create send from selected tracks", -1)
    
end

Main()
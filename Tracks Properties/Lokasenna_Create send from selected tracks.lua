--[[
Description: Create send from selected tracks
Version: 1.10
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
    Accepts a track number or track name
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
    local ret, dest_val = reaper.GetUserInputs("Create sends to...", 1, "Destination track # or name:", "")
    
    if not ret then return end
    
    local dest
    
    -- Track number?
    if tonumber(dest_val) then 
        dest = reaper.GetTrack(0, tonumber(dest_val) - 1)
        
    -- Track name?
    elseif tostring(dest_val) then
    
        for i = 0, reaper.GetNumTracks() - 1 do
            
            local track = reaper.GetTrack(0, i)
            local ret, name = reaper.GetTrackName(track, "")
            if ret and name == tostring(dest_val) then
                dest = track
            end
            
        end
    
    end

    if not dest then return end
    
    reaper.Undo_BeginBlock()
    
    reaper.PreventUIRefresh(1)
    
    -- For each selected track
    local sel = {}
    for i = 0, num_tracks - 1 do
        
        local sel = reaper.GetSelectedTrack(0, i)

        -- Create a default send
        --reaper.CreateTrackSend( tr, desttrInOptional )
        reaper.CreateTrackSend(sel, dest)
        
    end
    
    reaper.PreventUIRefresh(-1)
    reaper.UpdateTimeline()
    
    reaper.Undo_EndBlock("Create send from selected tracks", -1)
    
end

Main()
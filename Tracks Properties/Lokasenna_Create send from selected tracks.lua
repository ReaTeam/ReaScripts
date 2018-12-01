--[[
Description: Create send from selected tracks
Version: 1.40
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
    Fix: Post-fader option got lost
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
    Prompts for a track number, then creates sends to that track
    from every selected track
Provides:
    . > Lokasenna_Create send from selected tracks (post-fader).lua
    . > Lokasenna_Create send from selected tracks (post-FX).lua
    . > Lokasenna_Create send from selected tracks (pre-FX).lua
    
--]]

-- Licensed under the GNU GPL v3
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local mode = string.match(script_name, "%((.+)%)")

local modes = {
  ["post-fader"] = 0,  
  ["pre-FX"] = 1,
  ["post-FX"] = 3,
}

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
                break
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
        
        -- Skip any tracks that are already sending to the destination
        local num_sends = reaper.GetTrackNumSends(sel, 0)
        if num_sends and num_sends > 0 then
            for i = 1, num_sends do
                --reaper.BR_GetMediaTrackSendInfo_Track( track, category, sendidx, trackType )            
                if dest == reaper.BR_GetMediaTrackSendInfo_Track(sel, 0, i-1, 1) then goto skip end       
            end
        end

        -- Create a default send
        --reaper.CreateTrackSend( tr, desttrInOptional )
        local idx = reaper.CreateTrackSend(sel, dest)
        
        if modes[mode] then
            reaper.SetTrackSendInfo_Value(sel, 0, idx, "I_SENDMODE", modes[mode])
        end
        
        ::skip::
        
    end
    
    reaper.PreventUIRefresh(-1)
    reaper.UpdateTimeline()
    
    reaper.Undo_EndBlock("Create send from selected tracks", -1)
    
end

Main()
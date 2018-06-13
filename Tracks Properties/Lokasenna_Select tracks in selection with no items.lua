--[[
Description: Select tracks in selection with no items
Version: 1.00
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
    Initial release
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
    Extends the behavior of "Xenakios/SWS: Select tracks with no items"
    to only look within the currently selected tracks
--]]

-- Licensed under the GNU GPL v3



local function Main()
    
    local new_sel = {}
    
    -- Get number of selected tracks
    local num_sel = reaper.CountSelectedTracks(0)
    
    if num_sel == 0 then return end
    
    reaper.PreventUIRefresh(1)
    
    -- For each selected track
    for i = 1, num_sel do
    
        local track = reaper.GetSelectedTrack(0, i - 1)
        
        -- If it's empty..
        if reaper.CountTrackMediaItems(track) == 0 then
        
            -- Add to new_sel
            new_sel[#new_sel + 1] = track
            
        end
        
    end
    
    -- Deselect all tracks
    reaper.Main_OnCommand(40297, 0)    
    
    -- Select tracks in new_sel    
    for k, tr in pairs(new_sel) do
        
        reaper.SetTrackSelected(tr, true)
        
    end
    
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    
end

Main()
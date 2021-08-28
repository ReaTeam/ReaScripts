-- @description Show VCA Followers of selected VCA Leader
-- @author Airon
-- @version 1.0
-- @changelog Initial release
-- @website https://forum.cockos.com/showthread.php?t=255631
-- @about
--   Checks if the selected track is a VCA Leader, shows all tracks that are a VCA Follower to it and hides all other tracks.
--
--   - Check if the selected track is a vca leader
--   - Get the group association bitfield for the VCA Leader  which gets you a 32-bit integer. Each bit represents one of the 32 possible groups. A secondary function checks the next 32 groups.
--   - Unselected all tracks
--   - Compare the bitfield of VOLUME_VCA_LEAD of the leader to VOLUME_VCA_FOLLOW
--   - Select the tracks where those bitfields match
--   - Show only selected tracks and hide all others

--[[
* Licence: GPL v3
* FULL AUTHOR LIST:
*   Airon, NoFish
--]]

-- reset variables
local groups = {}
local i=0
local track = 0
local vca_followers = 0
local vca_leaders = 0
local attributename = "VOLUME_VCA_FOLLOW"
local ctr = reaper.CountTracks(0)
local vca_l_lo=0
local vca_l_hi=0
local vca_f_lo=0
local vca_f_hi=0

if reaper.CountSelectedTracks(0) ~= nil then
    track = reaper.GetSelectedTrack(0,0)
    vca_l_lo = reaper.GetSetTrackGroupMembership(track,"VOLUME_VCA_LEAD" , 0, 0)
    vca_l_hi = reaper.GetSetTrackGroupMembershipHigh(track,"VOLUME_VCA_LEAD" , 0, 0)
    if vca_l_lo~=0 or  vca_l_hi~=0 then   -- it's a vca leader
        vca_leaders = 1
        reaper.Main_OnCommand(40297,0)    -- unselect all tracks
    end

    if vca_leaders ~= 0 then
        reaper.Undo_BeginBlock()
        reaper.TrackList_AdjustWindows (false)
        reaper.PreventUIRefresh(1)
        for i = 1, ctr do
            track = reaper.GetTrack(0,i-1)
            if track ~= nil then
                -- check for VCA Follower flag for groups 1-32 and 33-64
                  local vca_f_lo = reaper.GetSetTrackGroupMembership(track,attributename , 0, 0)
                  local vca_f_hi = reaper.GetSetTrackGroupMembershipHigh(track,attributename , 0, 0)
                
                -- bitwise AND of the group bitfields for the
                -- leaders VOLUME_VCA_LEAD and the followers VOLUME_VCA_FOLLOW
                -- produces a non-zero results only if they share vca group assignments
                if vca_f_lo&vca_l_lo ~=0 or vca_f_hi&vca_l_hi ~=0 then
                    reaper.SetTrackSelected(track, true)
                    vca_followers = 1
                end
            end
            
        end
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWSTL_SHOWEX"),0) -- show selected tracks hide all others
        reaper.Main_OnCommand(40297,0)    -- unselect all tracks
        reaper.CSurf_SetTrackListChange()
        reaper.TrackList_UpdateAllExternalSurfaces()
        reaper.TrackList_AdjustWindows(true)
        reaper.PreventUIRefresh(-1)
        reaper.Undo_EndBlock("Show VCA Followers of selected track", 0)
    end
end

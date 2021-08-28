-- @description Show VCA Leaders and hide all other tracks
-- @author Airon
-- @version 1.0
-- @changelog Initial Release
-- @website https://forum.cockos.com/showthread.php?t=255631
-- @about
--   Show VCA Leaders and hide all other tracks.
--
--   Mixers require fast access across dozens or even hundreds of tracks with the least amount of work. With VCA groups, this is possible,  even through several Leader/Follower layers.
--   This script works for track visibility on the arrangement, mixer and on control surfaces.
--
--   How it works:
--   - Unselect all tracks
--   - Check each track if it is a vca leader
--   - Select those tracks
--   - Show only selected tracks and hide all others

--[[
* Licence: GPL v3
* FULL AUTHOR LIST:
    Airon, NoFish
--]]

-- reset variables
local ctr = reaper.CountTracks(0)
local i=0
local track=nil
local vca_leaders = 0
local vcalead = "VOLUME_VCA_LEAD"
local vcalo = 0
local vcahi = 0
reaper.Undo_BeginBlock()
reaper.TrackList_AdjustWindows (false)
reaper.PreventUIRefresh(1)

if ctr ~= nil then
    reaper.Main_OnCommand(40297,0) -- unselect all tracks
    for i = 1, ctr do
        local track = reaper.GetTrack(0,i-1)
        if track ~= nil then
            -- check for VCA Leader flag
            vcalo = reaper.GetSetTrackGroupMembership(track,vcalead , 0, 0)
            vcahi = reaper.GetSetTrackGroupMembershipHigh(track,vcalead , 0, 0)
            if vcalo~=0 or  vcahi~=0 then   -- vca leader?
                reaper.SetTrackSelected(track, true)
                vca_leaders = 1
            end
        end
    end
end -- ctr (CountTracks)

if vca_leaders == 1 then
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWSTL_SHOWEX"),0) -- show selected, hide all others
    reaper.Main_OnCommand(40297,0)    -- unselect all tracks
end
reaper.CSurf_SetTrackListChange()
reaper.TrackList_UpdateAllExternalSurfaces()
reaper.TrackList_AdjustWindows(true)
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Show only VCA Leaders", 0)

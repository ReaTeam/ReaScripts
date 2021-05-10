-- @description Mute - unmute tracks per region by Region Render Matrix
-- @author Michel de Joode
-- @version 1.0
-- @changelog Initial release
-- @link Github https://github.com/micheldejoode/reaper-scripts/tree/main/Mute_unmute_tracks
-- @about
--   #Mute - unmute tracks per region by Region Render Matrix
--
--   Regions are a very powerful tool in Reaper, especially when used with the SWS Region Playlist. 
--
--   This script extends this functionality by letting you mute / unmute tracks per region by using the Region Render Matrix. The script runs in the background and will watch for region changes. You can terminate the script at the Actions menu.
--
--   With this script you can easily create buildups by copying some regions and then mute / unmute tracks in the Region Render Matrix.
--
--   Instructions:
--   1. create some tracks
--   2. create some regions
--   3. start the script (could be at every step)
--   4. Optional but recommended: start the Region Playlist (add your regions and set the loop counts, and press play)
--   5. use the Region Render Matrix to mute / unmute tracks per region
--
--   Tip: it works best by disabling this setting in Options --> Audio --> Mute/Solo  "Do not process muted tracks". If not, you can hear some distortion on switching regions while playing.



local oldregion

function mute_tracks() 
-- get current region-id
markeridx, region_idx = reaper.GetLastMarkerAndCurRegion( 0,reaper.GetPlayPosition2() )
region_idx = region_idx+1

--only execute code if region has changed
if region_idx ~= oldregion then

oldregion = region_idx
counttracks = reaper.CountTracks(0)
muted_tracks = {}
-- mute tracks which are marked in region render matrix
for index = 0, counttracks do -- for all tracks
track = reaper.EnumRegionRenderMatrix(0, region_idx, index) 
if track ~= nil then
reaper.SetMediaTrackInfo_Value(track, 'B_MUTE', 1)
muted_tracks[index] = track
end -- end if track ~= nil
end -- end for index =0


for index = 0, counttracks do --unmute tracks except muted tracks
isin = 0
for i = 0, counttracks do
if reaper.GetTrack(0, index) == muted_tracks[i] then
isin = 1
end -- end if gettrack
end -- end for i 

if isin == 0 then -- if the track is not muted, unmute track

track = reaper.GetTrack(0, index)
if track ~= nil then
reaper.SetMediaTrackInfo_Value(track, 'B_MUTE', 0)
end -- end if track
end -- end for do unmute tracks
end
end -- if region other than oldregion
end -- end function mute_tracks


-- defer this script
function deferscript()
   if reaper.GetPlayState() == 1 then
    mute_tracks()
    reaper.defer(deferscript)
    else
    reaper.defer(deferscript)
  end
end
deferscript()

-- @description Apply track volume to Items
-- @author Neftovsky
-- @version 1.0
-- @about
--   Apply track volume to Items
--
--       Applies selected track volume to its items (takes) and resets track fader to 0 dB.
--       Compensates item volume (Pre-FX) based on track fader volume.
--
--       Usage:
--       1. Select tracks.
--       2. Run the script.
--       3. Track volume resets to 0 dB, item volumes adjust accordingly.

local selected_track_count = reaper.CountSelectedTracks(0)

if selected_track_count > 0 then
    for t = 0, selected_track_count - 1 do
        local track = reaper.GetSelectedTrack(0, t)
        
        if track then
            local track_volume = reaper.GetMediaTrackInfo_Value(track, "D_VOL")
            
            local item_count = reaper.CountTrackMediaItems(track)
            for i = 0, item_count - 1 do
                local item = reaper.GetTrackMediaItem(track, i)
                if item then
                    local take = reaper.GetActiveTake(item)
                    if take then
                        local item_vol = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
                        local compensated_vol = item_vol * track_volume
                        reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", compensated_vol)
                    end
                end
            end
            
            reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1.0)
        end
    end
else
    reaper.ShowMessageBox("No tracks selected!", "Error", 0)
end

reaper.UpdateArrange()

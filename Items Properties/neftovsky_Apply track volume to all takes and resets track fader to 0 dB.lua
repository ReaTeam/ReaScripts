-- @description Apply track volume to all takes and resets track fader to 0 dB
-- @author Neftovsky
-- @version 1.1
-- @about
--   Apply track volume to all takes and resets track fader to 0 dB
--
--       Applies selected track volume to all takes in items and resets track fader to 0 dB.
--       Adjusts take volume (Pre-FX) without affecting item volume.
--
--       Usage:
--       1. Select tracks.
--       2. Run the script.
--       3. Track volume resets to 0 dB, all take's volumes adjust accordingly.

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
                    local take_count = reaper.CountTakes(item)
                    for tk = 0, take_count - 1 do
                        local take = reaper.GetTake(item, tk)
                        if take then
                            local item_vol = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL")
                            local compensated_vol = item_vol * track_volume
                            reaper.SetMediaItemTakeInfo_Value(take, "D_VOL", compensated_vol)
                        end
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

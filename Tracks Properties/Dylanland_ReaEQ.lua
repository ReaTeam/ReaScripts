-- @description ReaEQ Will Putney Preset
-- @author Dylan Land
-- @version 1.0
-- @changelog First Release/Test
-- @provides . > ReaEQ_Will_Putney

-- Will Putney Knocked Loose Guitar Track Setup
-- ReaScript for REAPER
-- Creates a guitar track with professional EQ settings

-- Script info
local script_name = "Will Putney Knocked Loose Guitar Setup"
local script_version = "1.0"

-- Start undo block
reaper.Undo_BeginBlock()

-- Insert new track
reaper.InsertTrackAtIndex(reaper.CountTracks(0), false)
local track = reaper.GetTrack(0, reaper.CountTracks(0) - 1)

-- Set track name
reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "Guitar - Will Putney Style", true)

-- Set track color (dark red for metal guitars)
reaper.SetTrackColor(track, reaper.ColorToNative(150, 50, 50)|0x1000000)

-- Add ReaEQ plugin
local fx_index = reaper.TrackFX_AddByName(track, "ReaEQ", false, -1)

-- Configure ReaEQ parameters for Will Putney Knocked Loose style
if fx_index >= 0 then
    -- Band 1: High Pass at 90Hz, -12dB, Q=0.7
    reaper.TrackFX_SetParam(track, fx_index, 0, 1)      -- Band 1 enabled
    reaper.TrackFX_SetParam(track, fx_index, 1, 5)      -- Band 1 type (High Pass)
    reaper.TrackFX_SetParam(track, fx_index, 2, 90/20000) -- Band 1 frequency (normalized)
    reaper.TrackFX_SetParam(track, fx_index, 3, 0.5 + (-12/48)) -- Band 1 gain (normalized)
    reaper.TrackFX_SetParam(track, fx_index, 4, 0.7/10) -- Band 1 Q (normalized)
    
    -- Band 2: Bell at 120Hz, -2.5dB, Q=1.2
    reaper.TrackFX_SetParam(track, fx_index, 5, 1)      -- Band 2 enabled
    reaper.TrackFX_SetParam(track, fx_index, 6, 0)      -- Band 2 type (Bell)
    reaper.TrackFX_SetParam(track, fx_index, 7, 120/20000) -- Band 2 frequency
    reaper.TrackFX_SetParam(track, fx_index, 8, 0.5 + (-2.5/48)) -- Band 2 gain
    reaper.TrackFX_SetParam(track, fx_index, 9, 1.2/10) -- Band 2 Q
    
    -- Band 3: Bell at 400Hz, -3dB, Q=1.0
    reaper.TrackFX_SetParam(track, fx_index, 10, 1)     -- Band 3 enabled
    reaper.TrackFX_SetParam(track, fx_index, 11, 0)     -- Band 3 type (Bell)
    reaper.TrackFX_SetParam(track, fx_index, 12, 400/20000) -- Band 3 frequency
    reaper.TrackFX_SetParam(track, fx_index, 13, 0.5 + (-3/48)) -- Band 3 gain
    reaper.TrackFX_SetParam(track, fx_index, 14, 1.0/10) -- Band 3 Q
    
    -- Band 4: Bell at 1250Hz, +2dB, Q=1.0
    reaper.TrackFX_SetParam(track, fx_index, 15, 1)     -- Band 4 enabled
    reaper.TrackFX_SetParam(track, fx_index, 16, 0)     -- Band 4 type (Bell)
    reaper.TrackFX_SetParam(track, fx_index, 17, 1250/20000) -- Band 4 frequency
    reaper.TrackFX_SetParam(track, fx_index, 18, 0.5 + (2/48)) -- Band 4 gain
    reaper.TrackFX_SetParam(track, fx_index, 19, 1.0/10) -- Band 4 Q
    
    -- Band 5: Bell at 3500Hz, -2dB, Q=2.0
    reaper.TrackFX_SetParam(track, fx_index, 20, 1)     -- Band 5 enabled
    reaper.TrackFX_SetParam(track, fx_index, 21, 0)     -- Band 5 type (Bell)
    reaper.TrackFX_SetParam(track, fx_index, 22, 3500/20000) -- Band 5 frequency
    reaper.TrackFX_SetParam(track, fx_index, 23, 0.5 + (-2/48)) -- Band 5 gain
    reaper.TrackFX_SetParam(track, fx_index, 24, 2.0/10) -- Band 5 Q
    
    -- Band 6: Bell at 6500Hz, -3dB, Q=2.0
    reaper.TrackFX_SetParam(track, fx_index, 25, 1)     -- Band 6 enabled
    reaper.TrackFX_SetParam(track, fx_index, 26, 0)     -- Band 6 type (Bell)
    reaper.TrackFX_SetParam(track, fx_index, 27, 6500/20000) -- Band 6 frequency
    reaper.TrackFX_SetParam(track, fx_index, 28, 0.5 + (-3/48)) -- Band 6 gain
    reaper.TrackFX_SetParam(track, fx_index, 29, 2.0/10) -- Band 6 Q
    
    -- Band 7: Low Pass at 10500Hz, -12dB, Q=0.7
    reaper.TrackFX_SetParam(track, fx_index, 30, 1)     -- Band 7 enabled
    reaper.TrackFX_SetParam(track, fx_index, 31, 3)     -- Band 7 type (Low Pass)
    reaper.TrackFX_SetParam(track, fx_index, 32, 10500/20000) -- Band 7 frequency
    reaper.TrackFX_SetParam(track, fx_index, 33, 0.5 + (-12/48)) -- Band 7 gain
    reaper.TrackFX_SetParam(track, fx_index, 34, 0.7/10) -- Band 7 Q
    
    -- Set track volume to -6dB for headroom
    reaper.SetMediaTrackInfo_Value(track, "D_VOL", reaper.DB2SLIDER(-6))
    
    -- Arm track for recording
    reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 1)
    
    -- Set input to first input
    reaper.SetMediaTrackInfo_Value(track, "I_RECINPUT", 0)
    
    -- Select the track
    reaper.SetTrackSelected(track, true)
    
    -- Show message
    reaper.ShowMessageBox("Guitar track created with Will Putney Knocked Loose EQ settings!\n\n" ..
                         "Track Features:\n" ..
                         "• 7-band professional EQ curve\n" ..
                         "• Tight low-end filtering\n" ..
                         "• Mid-range clarity\n" ..
                         "• Controlled high frequencies\n" ..
                         "• Armed for recording\n" ..
                         "• -6dB volume for headroom", 
                         script_name, 0)
else
    reaper.ShowMessageBox("Error: Could not add ReaEQ plugin", "Error", 0)
end

-- Update arrange view
reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()

-- End undo block
reaper.Undo_EndBlock(script_name, -1)

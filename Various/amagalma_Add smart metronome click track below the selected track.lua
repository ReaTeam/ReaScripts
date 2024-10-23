-- @description Add smart metronome click track below the selected track
-- @author amagalma
-- @version 1.02
-- @changelog
--   - If no track is selected then the click track is inserted as the first in the project
--   - Show ReaGate's Threshold and Dry parameters on the TCP of the click track
-- @donation https://www.paypal.me/amagalma
-- @about
--   Adds a track below the selected track with a click source for at least 220secs or more if the project is bigger.
--
--   The click track has ReaGate loaded and its volume will depend on the volume of the audio coming to its sidechain on channels 3&4. So, the metronome will play louder if the sidechain is louder and softer if it is softer ( in order to avoid bleed from the click track into the recording)


reaper.Undo_BeginBlock()
reaper.PreventUIRefresh( 1 )

-- Add metronome track
local track = reaper.GetSelectedTrack( 0, 0 )
local track_id = track and reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" ) or 0
reaper.InsertTrackAtIndex( track_id, false )
track = reaper.GetTrack( 0, track_id )
reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "Metronome", true )
reaper.SetMediaTrackInfo_Value( track, "I_NCHAN", 4 )
reaper.SetOnlyTrackSelected( track )

-- Add ReaGate and configure
local fxid = reaper.TrackFX_AddByName( track, "ReaGate", false, -1)
reaper.TrackFX_Show( track, fxid, 1 )
reaper.TrackFX_SetParam( track, fxid, 0, 0.00562341325 ) -- 0 thresh -45dB
reaper.TrackFX_SetParam( track, fxid, 1, 0 )-- 1 attack 0
local bpm, bpi = reaper.GetProjectTimeSignature2( 0 )
reaper.TrackFX_SetParam( track, fxid, 2, (60/bpm*bpi/5)*0.5 ) -- 2 release to half measure
reaper.TrackFX_SetParam( track, fxid, 7, 0.0018450184725225 )-- 7 signin Aux Inputs
reaper.TrackFX_SetParam( track, fxid, 9, 0.063095733523369 )-- 9 dry -24dB
reaper.SNM_AddTCPFXParm( track, fxid, 0 )
reaper.SNM_AddTCPFXParm( track, fxid, 9 )
reaper.SetMediaTrackInfo_Value( track, "I_HEIGHTOVERRIDE", 108 )


-- Add click
local cur_pos = reaper.GetCursorPosition()
reaper.SetEditCurPos( 0, false, false)
reaper.Main_OnCommand(40013, 0) -- Insert click source
reaper.SetEditCurPos( cur_pos, false, false)
local item = reaper.GetSelectedMediaItem( 0, 0 )
local take = reaper.GetActiveTake( item )
reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "Click track with smart volume level", true)
reaper.SetMediaItemInfo_Value( item, "D_POSITION", 0 )
local proj_len = reaper.GetProjectLength( 0 )
reaper.SetMediaItemInfo_Value( item, "D_LENGTH", proj_len > 220 and proj_len or 220 )

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()

-- Messages for user action
reaper.MB("Please, send the track(s) that you want to affect the metronome track's volume to the \z
metronome track's receive channels 3&4.\n\nSet ReaGate's Threshold and Dry levels to taste.", "Action required by user", 0)
reaper.Main_OnCommand(40914, 0) -- Set first selected track as last touched track
reaper.Main_OnCommand(40293, 0) -- View routing and I/O for current/last touched track

reaper.Undo_EndBlock( "Add smart metronome track", 1|2|4 )

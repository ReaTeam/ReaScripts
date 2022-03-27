-- @description Set media playback offset for selected tracks
-- @author Mordi
-- @version 1.0
-- @about Sets the media playback offset for all selected tracks, in milliseconds.

SCRIPT_NAME = "Set media playback offset for selected tracks"

reaper.ClearConsole()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

-- Get current playback offset of first selected track
firstSelectedTrack = reaper.GetSelectedTrack(0, 0)
if firstSelectedTrack == nil then
  return
end

existingFlag = reaper.GetMediaTrackInfo_Value(firstSelectedTrack, "I_PLAY_OFFSET_FLAG")
existingOffset = 0
if existingFlag == 0 then
  existingOffset = reaper.GetMediaTrackInfo_Value(firstSelectedTrack, "D_PLAY_OFFSET") * 1000 -- Convert to milliseconds
end

-- Get input offset in seconds
retval, offsetInput = reaper.GetUserInputs(SCRIPT_NAME, 1, "Playback offset (ms)", existingOffset)

if retval == false then
  return
end

-- Convert to seconds
offsetInput = offsetInput / 1000

-- Begin undo-block
reaper.Undo_BeginBlock2(0)

-- Loop through selected tracks
for i = 0, reaper.CountSelectedTracks(0)-1 do
  -- Get track
  track = reaper.GetSelectedTrack(0, i)
  
  -- Set playback offset
  reaper.SetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG", 0&2)
  retval, stringNeedBig = reaper.SetMediaTrackInfo_Value(track, "D_PLAY_OFFSET", offsetInput)
end

-- End undo-block
reaper.Undo_EndBlock2(0,SCRIPT_NAME,-1)

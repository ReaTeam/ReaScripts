-- @description 7R MIDI Auto Send
-- @author 7thResonance
-- @version 0.2
-- @changelog Initial Script
-- @screenshot Track with Realearn filter and Hardware Send https://i.postimg.cc/HspB7Z3p/Screenshot-2025-05-19-020704.png
-- @about
--   MIDI Auto Send
--
--   Original Script made by Heda. This script allows to send MIDI back to hardware faders. (assuming it supports midi receives and motorised faders positioning themselves)
--
--   Creates a MIDI Send from selected track to "Hardware Feedback Track"
--   Auto Creates track when script is first ran.
--
--   Save the track as part of the default template with the appropriate filters and hardware send. 
--   Disable master send of the hardware feedback track.
--
--   - Does not create send if its a Folder.
--   - has a delay of 500 ms to create a send.
--   - Need track selection undo points.
--
--   Modified by 7thResonance

-- Function to check or create "Hardware Feedback Track" in the current project
function ensureHardwareFeedbackTrack()
    local feedbackTrack
    for i = 0, reaper.CountTracks(0) - 1 do
      local track = reaper.GetTrack(0, i)
      local _, trackName = reaper.GetTrackName(track, "")
      if trackName == "Hardware Feedback Track" then
        feedbackTrack = track
        break
      end
    end
  
    if not feedbackTrack then
      reaper.Undo_BeginBlock()
      reaper.InsertTrackAtIndex(reaper.CountTracks(0), false)
      feedbackTrack = reaper.GetTrack(0, reaper.CountTracks(0) - 1)
      reaper.GetSetMediaTrackInfo_String(feedbackTrack, "P_NAME", "Hardware Feedback Track", true)
      reaper.Undo_EndBlock("Create Hardware Feedback Track", -1)
    end
    return feedbackTrack
end
  
-- Function to remove all sends from a track to "Hardware Feedback Track"
function removeMIDISends(track, feedbackTrack)
    if track and feedbackTrack then
      for sendIdx = reaper.GetTrackNumSends(track, 0) - 1, 0, -1 do
        local sendTrack = reaper.BR_GetMediaTrackSendInfo_Track(track, 0, sendIdx, 1)
        if sendTrack == feedbackTrack then
          reaper.RemoveTrackSend(track, 0, sendIdx)
        end
      end
    end
end
  
-- Function to create a MIDI-only send to "Hardware Feedback Track"
function setupMIDISend(selectedTrack, feedbackTrack)
    if selectedTrack and feedbackTrack then
      local sendIdx = reaper.CreateTrackSend(selectedTrack, feedbackTrack)
      reaper.SetTrackSendInfo_Value(selectedTrack, 0, sendIdx, "I_SRCCHAN", -1) -- All MIDI channels
      reaper.SetTrackSendInfo_Value(selectedTrack, 0, sendIdx, "I_DSTCHAN", 0)  -- Destination to channel 1
      reaper.SetTrackSendInfo_Value(selectedTrack, 0, sendIdx, "I_MIDIFLAGS", 1) -- MIDI only
    end
end
  
-- Function to monitor track selection and manage MIDI sends
function monitorTrackSelection()
    local currentTime = reaper.time_precise()
    if currentTime - lastRunTime < 0.5 then -- Run every 0.5 seconds (2 times per second)
        reaper.defer(monitorTrackSelection)
        return
    end
    lastRunTime = currentTime

    -- Ensure "Hardware Feedback Track" exists
    local feedbackTrack = ensureHardwareFeedbackTrack()
  
    -- Get the currently selected track
    local selectedTrack = reaper.GetSelectedTrack(0, 0)
  
    -- If the selection has changed
    if selectedTrack ~= lastSelectedTrack then
      -- Remove MIDI sends from the previously selected track
      if lastSelectedTrack and reaper.ValidatePtr2(0, lastSelectedTrack, "MediaTrack*") then
        removeMIDISends(lastSelectedTrack, feedbackTrack)
      end
  
      -- Set up MIDI send for the newly selected track, but only if it's not a folder track
      if selectedTrack and reaper.GetTrackName(selectedTrack, "") ~= "Hardware Feedback Track" then
        local isFolder = reaper.GetMediaTrackInfo_Value(selectedTrack, "I_FOLDERDEPTH")
        if isFolder <= 0 then -- Only proceed if not a folder track (folder depth <= 0)
          removeMIDISends(selectedTrack, feedbackTrack) -- Clean any existing sends
          setupMIDISend(selectedTrack, feedbackTrack)
        end
      end
  
      -- Update the last selected track
      lastSelectedTrack = selectedTrack
    end
  
    reaper.defer(monitorTrackSelection)
end
  
-- Initialize
lastSelectedTrack = nil
lastRunTime = 0
monitorTrackSelection()

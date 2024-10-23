-- @description Arranged Live Looping
-- @author ilovemedia
-- @version 1.0
-- @changelog First release!
-- @link Arranged Live Looping - Instructions and Examples https://ilovemedia.es/arranged-live-looping-for-reaper/
-- @about
--   # Arranged Live Looping
--
--   ## Main Features
--   * Hands-free live looping
--   * Supports both MIDI and audio
--   * Auto-punch on each record item
--   * Repeat recording sections wherever you want, even on other tracks with different parameters or instruments
--   * Automatically select any track using markers
--
--   ## Prepare your template for live looping
--   * Create your template tracks (MIDI and/or audio). MIDI tracks should be set to `Record: MIDI overdub or replace`.
--   * Regardless of whether it will be an audio or MIDI track, create new MIDI items (`Insert → New MIDI Item`) for the areas where you want to record and for the areas where the recorded content will be repeated. Playback items can be added to any track, and their length can be different. If the playback items are longer, they will loop.
--   * In the `Item Properties -> Take Name` you need to modify the name of each take according to the following guidelines:
--   For the items you want to convert into recording zones, add the word `record` at the end of their name.
--   For the items from which you want to copy the content, use the same name as the record item, but replace record with `playback` at the end of the name. Keep the rest of the name identical.
--   * Create markers at the points where you want to select another track. Name the markers with the exact name of the track you want to select.

--======================================================================

-- START VARIABLES--
local playPos
local punchStarted = false
local isMIDI = false
local recordName = "record"
local playbackName = "playback"
local audioInputs = {0, 1, 1024}
--[[
  In this case, the audio inputs are 0 (input 1), 1 (input 2), or 1024 (stereo).
  If you have other audio inputs, you will need to add them to the previous array.
  On line 434, you can see how to check the numbers corresponding to your audio inputs.
  Search  --reaper.ShowConsoleMsg(trackType .. "\n") and remove "--"
--]]

--======================================================================

-- ITEM COLOR --

-- Define a function to set the color of a given media item.
function SetItemColor(item, color)
    -- Use the SetMediaItemInfo_Value function to change the item's color.
    reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
end

-- Define the main function to change the color of media items based on their names.
function ChangeColor()
  -- Start a loop that will iterate through all the media items in the project.
  for i = 0, reaper.CountMediaItems(0) - 1 do
    -- Get each media item in turn.
    local item = reaper.GetMediaItem(0, i)
    -- Get the active take for the current media item.
    local take = reaper.GetActiveTake(item)

    -- Proceed only if the current media item has an active take.
    if take ~= nil then
        -- Get the name of the media item.
        local _, item_name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)

        -- Check if the item's name contains the string "playblack".
        if string.find(item_name, playbackName) ~= nil then
            -- If it does, change the item's color to green.
            SetItemColor(item, reaper.ColorToNative(0, 255, 0)|0x1000000)

        -- Check if the item's name contains the string "record".
        elseif string.find(item_name, recordName) ~= nil then
            -- If it does, change the item's color to red.
            SetItemColor(item, reaper.ColorToNative(255, 0, 0)|0x1000000)
        end
     end
  end
end


--======================================================================

-- Define the function to set looping for media items based on their names.
function UnloopRedLoopGreen()
  -- Start a loop that will iterate through all the media items in the project.
  for i = 0, reaper.CountMediaItems(0) - 1 do
    -- Get each media item in turn.
    local item = reaper.GetMediaItem(0, i)
    -- Get the active take for the current media item.
    local take = reaper.GetActiveTake(item)

    -- Proceed only if the current media item has an active take.
    if take ~= nil then
        -- Get the name of the media item.
        local _, takeName = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)

        -- Check if the item's name contains the string "playback".
        if string.find(takeName, playbackName) ~= nil then
          -- If it does, set the item to loop.
          reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 1)

        -- Check if the item's name contains the string "record".
        elseif string.find(takeName, recordName) ~= nil then
          -- If it does, set the item not to loop.
          reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 0)

        end
     end
  end
end

--======================================================================

function AutomaticRecordArm()
  for i = 0, reaper.CountTracks(0) - 1 do
    -- Get the track
    local track = reaper.GetTrack(0, i)
    if track ~= nil  then
      for i = 0, reaper.CountTrackMediaItems(track) - 1 do
        local item = reaper.GetTrackMediaItem(track, i)-- Get the name of the media item.
        local take = reaper.GetActiveTake(item)
        local _, takeName = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
        if string.find(takeName, recordName) ~= nil then
          reaper.SetMediaTrackInfo_Value(track, "B_AUTO_RECARM", 1)
          --reaper.SetMediaTrackInfo_Value(track, "I_RECMODE", 7) --   Record: MIDI Overdub
          break
        end
      end
    end
  end
end

--======================================================================

function RecordOn()
  -- Check the current play state.
  local playState = reaper.GetPlayState()
  -- If play state is 1 (playing without recording), activate recording for the new track.
  if playState == 1 then
    reaper.Main_OnCommand(1013, 0)
  end
end

function RecordOff()
  -- Check the current play state.
  local playState = reaper.GetPlayState()
  -- If play state is 5 (recording)
  if playState == 5 then
    -- stop recording
    reaper.Main_OnCommand(1013, 0)
  end
end


--======================================================================

-- Define a function to change the time selection according to the "record" media item on the selected track.
function ChangeTimeSelection()
  RecordOn()
   -- Get the selected track.
  local track = reaper.GetSelectedTrack(0, 0)

  -- If a track is selected...
  if track ~= nil then
    -- Get the name of the track.
    local _, trackName = reaper.GetTrackName(track)

    -- Get the number of media items on the track.
    local itemCount = reaper.GetTrackNumMediaItems(track)

    -- Iterate through the media items on the track.
    for i = 0, itemCount - 1 do
      -- Get each media item in turn.
      local item = reaper.GetTrackMediaItem(track, i)
      -- Get the active take of the media item.
      local itemTake = reaper.GetActiveTake(item)
      -- Get the name of the take.
      local itemName = reaper.GetTakeName(itemTake)

      -- If the name of the take contains the string "record"...
      if string.find(itemName, recordName) ~= nil then
        -- Get the start time of the media item.
        local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        -- Get the end time of the media item.
        local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

         -- select the next or current record item in that track
        if itemStart >= playPos or (playPos > itemStart and playPos<itemEnd) then
          -- Set the time selection to the start and end times of the media item.
          reaper.GetSet_LoopTimeRange(true, false, itemStart, itemEnd, false)

          -- Update the arrangement to reflect the change in time selection.
          reaper.UpdateArrange()
          -- Exit the function since we've found the "record" media item and changed the time selection.
          return
        end
      end
    end
  end

  -- If no "record" media item was found, clear the time selection.
  reaper.GetSet_LoopTimeRange(true, false, 0, 0, false)
  RecordOff()
  -- Update the arrangement to reflect the change in time selection.
  reaper.UpdateArrange()
end


--======================================================================
-- WHEN TRACKS SELECTION CHANGE --
function onTrackSelectionChange()
  -- This function will be called when the selected track changes.
  punchStarted = false

  -- Check if the track is MIDI or audio.
  CheckIfMIDIorAudio()

  -- Change the time selection.
  ChangeTimeSelection()
end
--======================================================================

-- Define a global variable to store the previously selected track.
local prevTrack = reaper.GetSelectedTrack(0, 0)

-- Define a function to check if the selected track has changed.
function CheckTrackSelectionChange()
    -- Get the currently selected track.
    local currentTrack = reaper.GetSelectedTrack(0, 0)

    -- If a track is currently selected and it's different from the previously selected track...
    if currentTrack ~= nil and currentTrack ~= prevTrack then
        -- Call a custom function (which you would need to define separately) when the track selection changes.
        onTrackSelectionChange()
        -- Update the previously selected track to the currently selected track.
        prevTrack = currentTrack
    end

    -- Use the defer function to schedule the CheckTrackSelectionChange function to run again after all other scripts and processes have run.
    reaper.defer(CheckTrackSelectionChange)
end


--======================================================================

-- Define a function to check if the project is currently recording.
function CheckRecording()
  -- Get the play state of the project (1 for recording, 0 for not recording).
  recCount = reaper.GetPlayState() & 1

  -- Get the start and end times of the current time selection.
  timeSelectionStart, timeSelectionEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

  -- Check if the project is recording and if the current play position is within the time selection.
  if recCount == 1 and reaper.GetPlayPosition() >= timeSelectionStart and reaper.GetPlayPosition() < timeSelectionEnd then
    -- If the project wasn't already "punching in" (i.e., recording within the time selection)...
    if not punchStarted then
      -- Start "punching in".
      punchStarted = true
      -- Call a custom function (which you would need to define separately) to perform actions when "punching in" starts.
      onPunchIn()
    end
  -- If the project was "punching in" but is no longer recording or is no longer within the time selection...
  elseif punchStarted then
    -- Stop "punching in".
    punchStarted = false
    -- Call a custom function (which you would need to define separately) to perform actions when "punching in" stops.
    onPunchOut()
  end

  -- Use the defer function to schedule the CheckRecording function to run again after all other scripts and processes have run.
  reaper.defer(CheckRecording)
end



--======================================================================

--- Define a function to fill a MIDI playback item.
function CopyMidiSource()

  -- Get the currently selected track.
  local selectedTrack = reaper.GetSelectedTrack(0, 0)

  -- Check if a track is selected.
  if selectedTrack ~= nil then

    -- Initialize variables to store the items and takes for recording and looping.
    local recordItem = nil
    local recordTake = nil
    local destinationItem = nil
    local destinationTake = nil

    -- Get the number of items in the selected track.
    local numItems = reaper.CountTrackMediaItems(selectedTrack)

    -- Iterate over all items in the selected track.
    for i = 0, numItems - 1 do
      local item = reaper.GetTrackMediaItem(selectedTrack, i)
      local take = reaper.GetActiveTake(item)
      local takeName = reaper.GetTakeName(take)

      -- If the take name contains "record", store this as the record item and take.
      if string.find(takeName, recordName) ~= nil then
        recordItem = item
        recordTake = reaper.GetActiveTake(recordItem)
        local customSourceName =  string.gsub(takeName, recordName, "")
        PasteMidi(recordTake, customSourceName)
      end

    end

    -- If the project is currently "punching in" (i.e., recording within the time selection),
    -- defer the CopyMidiSource function to run again after all other scripts and processes have run.
    if punchStarted then
        reaper.defer(CopyMidiSource)
    end

  end

  -- Update the arrange view to reflect any changes made by the script.
  reaper.UpdateArrange()

end

function PasteMidi(recordTake, customSourceName)
  for i = 0, reaper.CountMediaItems(0) - 1 do
    -- Get each media item in turn.
    local item = reaper.GetMediaItem(0, i)
    -- Get the active take for the current media item.
      local take = reaper.GetActiveTake(item)
      -- Proceed only if the current media item has an active take.
      if take ~= nil then
          local takeName = reaper.GetTakeName(take)
          local pasteName = customSourceName .. playbackName
          if takeName == pasteName then
            destinationItem = item
            destinationTake = reaper.GetActiveTake(destinationItem)
            local _, recordMIDI = reaper.MIDI_GetAllEvts(recordTake, "")
            reaper.MIDI_SetAllEvts(destinationTake, recordMIDI)
          end
      end
  end
end

--======================================================================

-- Define a function to fill an audio playback item.
function CopyAudioSource()

    -- Get the recently recorded audio item.
    local sourceItem = reaper.GetSelectedMediaItem(0, 0)
    local firstTake = reaper.GetTake(sourceItem, 0)
    local firstTakeName = reaper.GetTakeName(firstTake)

    local sourceTake = reaper.GetActiveTake(sourceItem)

    reaper.GetSetMediaItemTakeInfo_String(sourceTake, "P_NAME", firstTakeName, true) -- Rename with the same name

    -- Crop the active take and glue items within time selection.
    reaper.Main_OnCommand(40131, 0) -- Crop to active take
    reaper.Main_OnCommand(42432, 0) -- Glue items within time selection

    reaper.Main_OnCommand(40636, 0) -- Loop item source so all subsequent items will loop

    local customSourceName =  string.gsub(firstTakeName, recordName, "")

    PasteAudio(customSourceName)

    -- Update the arrange view to reflect any changes made by the script.
    reaper.UpdateArrange()

end

function PasteAudio(customSourceName)

  for i = 0, reaper.CountMediaItems(0) - 1 do
    -- Get each media item in turn.
    local item = reaper.GetMediaItem(0, i)
    -- Get the active take for the current media item.
      local take = reaper.GetActiveTake(item)
      -- Proceed only if the current media item has an active take.
      if take ~= nil then
          local takeName = reaper.GetTakeName(take)
          local sourceName = customSourceName .. recordName
          local pasteName = customSourceName .. playbackName

          if string.find(takeName, "glued") ~= nil then
            reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", sourceName , true) -- Rename with the original source name
          end

          if takeName == pasteName then
            -- Save the item's position and length, then delete the item.
            local itemTrack = reaper.GetMediaItemTrack(item)
            local trackNumber = reaper.GetMediaTrackInfo_Value(itemTrack, "IP_TRACKNUMBER")
            local destinationTrack = reaper.GetTrack(0, trackNumber - 1)
            local itemPosition = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            reaper.DeleteTrackMediaItem(reaper.GetMediaItem_Track(item), item)

            -- Duplicate the item.
            reaper.Main_OnCommand(41295, 0) -- Duplicate items

            -- Get the newly pasted item.
            local pastedItem = reaper.GetSelectedMediaItem(0, 0)
            if pastedItem ~= nil then
              local pastedTake = reaper.GetActiveTake(pastedItem)
              reaper.GetSetMediaItemTakeInfo_String(pastedTake, "P_NAME", customSourceName..playbackName, true) -- Rename take
              -- Set the position and length of the pasted item.

              reaper.MoveMediaItemToTrack(pastedItem, destinationTrack)
              reaper.SetMediaItemPosition(pastedItem, itemPosition, false)
              reaper.SetMediaItemInfo_Value(pastedItem, "D_LENGTH", itemLength)
            end
          end
      end
  end
end

--======================================================================

-- Define a function to check if a track is MIDI or audio.
function CheckIfMIDIorAudio()
  -- Get the currently selected track.
  local selectedTrack = reaper.GetSelectedTrack(0, 0)

  -- If a track is selected,
  if  selectedTrack ~= nil then

    -- Get the track type
    local trackType = reaper.GetMediaTrackInfo_Value(selectedTrack, "I_RECINPUT")

    --[[
    To determine the number corresponding to an input, such as a track associated with an audio channel,
    uncomment the following line (by removing --), execute the script, and select the tracks you wish to verify.--]]

    --reaper.ShowConsoleMsg(trackType .. "\n")

    --By default, I consider it as a MIDI track.
    isMIDI = true
    --if it is an audio track (if it is in the audioInputs array at the beginning of this code), it's marked as non-MIDI.
    for i = 1, #audioInputs do
      if trackType == audioInputs[i] then
        isMIDI = false
        break
      end
    end
  end
end


--======================================================================
-- Get playPost current value
function CheckCurrentPosition()
  -- Get the current play state
  local playState = reaper.GetPlayState()

  -- Get the current play position
  playPos = reaper.GetPlayPosition()

  -- If playback is stopped, get the edit cursor position instead
  if playState == 0 then
      playPos = reaper.GetCursorPosition()
  end

end

--=====================================================================

-- CHECK MARKER NAMES TO CHANGE THE SELECTED TRACK
function CheckMarkers()

  CheckCurrentPosition()

  -- Get the last marker and current region at the play position
  local markerIdx, _, _, _, markerName = reaper.GetLastMarkerAndCurRegion(0, playPos)

  -- If there's a marker at the play position
  if markerIdx ~= -1 then
      -- Get the marker name
      local _, _, _, _, markerName, _ = reaper.EnumProjectMarkers(markerIdx)

      -- If the marker has a name
      if markerName then
          -- Iterate over all tracks
          for i = 0, reaper.CountTracks(0) - 1 do
              -- Get the track
              local track = reaper.GetTrack(0, i)
              -- Get the track name
              local _, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
              -- If the track name matches the marker name, select the track and end the loop
              if trackName == markerName then
                  reaper.SetOnlyTrackSelected(track)
                  break
              end
          --end
        end

      else
          --reaper.ShowConsoleMsg("Last marker name: nil\n")
      end
  else
      --reaper.ShowConsoleMsg("No marker at current play position\n")
  end

  -- Defer the execution of the CheckMarkers function
  reaper.defer(CheckMarkers)

end


--======================================================================


-- START ACTIONS --

-- Set record mode to auto-punch.
reaper.Main_OnCommand(40076, 0)

-- Apply initial color settings.
ChangeColor()

-- Set items to loop or not depending on whether their names are "record" or "playback".
UnloopRedLoopGreen()

--Automatically set record arm when track is selected if it has a "record" item
AutomaticRecordArm()

-- Check markers for automatic track changes (only for live).
CheckMarkers()

-- Set the initial time selection for the selected track.
ChangeTimeSelection()

-- Start a listener to check if the selected track changes.
CheckTrackSelectionChange()

-- Start a listener to check if recording is happening.
CheckRecording()

-- Check if the track is MIDI or audio.
CheckIfMIDIorAudio()




-- WHEN CURSOR IS BETWEEN PUNCH IN AND PUNCH OUT --
function onPunchIn()
    -- If the track is MIDI, fill the MIDI playback item on punch in.
    if isMIDI then
      CopyMidiSource()
    end
end

function onPunchOut()
    -- Get the current play state.
    local playState = reaper.GetPlayState()

    -- If play state is 5 (recording)
    if playState == 5 then
        -- stop recording
        reaper.Main_OnCommand(1013, 0)

        -- If the track is MIDI, fill the MIDI playback item on punch out.
        -- Otherwise, fill the audio playback item.
        if isMIDI then
          CopyMidiSource()
        else
            CopyAudioSource()
        end
        ChangeColor()
        ChangeTimeSelection()
        -- Move edit cursor to play cursor
        reaper.Main_OnCommand(40434, 0)
    end
end

--=======================

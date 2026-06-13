-- @description AutoDuck
-- @author Marco Steinebach
-- @version 26.01
-- @about
--   This Script is especially useful to make voice Overs, like Podcasts, Trailers, etc.
--   You Need at least two tracks in your current Project.
--   One Music track and one speech track.
--   Split the speech track into separate items. Every time an item on the speech track beginns,
--   the Music track will be ducked, its volume is faded down, as Long as the item Plays.
--   After the item is finished, the Music track's volume is restored to its original volume.
--
--   Internally, a volume envelope is created, with Automation Points arround each item.
--
--   You can specify
--
--   - how much (in DB) the Music track should be ducked,
--
--   - the outer fade down and fade up time
--
--   - the inner fade down and fade up time.  
--     This is the time the track is still ducked, though the item has began to Play.  
--     This gives a more natural Fading effect.

--[[
  AutoDuck for Reaper - Copyright 2026 by Marco Steinebach <studio@windyradio.de
  Version: 26.01
  
  the script needs a music track and a speech track directly underneath it.
  The ducking occures arround every item on the speech track, by setting envelope points.
  Focus the music track, then start the script.
]]--

scriptName = "AutoDuck" --for loading and saving user parameters within the project, and undo-description

--All output texts of the script are in the following table
txt = {}
--MessageBox titles
txt.error = "Error!"
txt.info = "Information"
txt.question = "question"
--error messages
txt.eNoMusicSpeechTrack = "Cannot find the %s track!\n" ..
  "Please focus the music track, with speech track underneath it, then restart the script."
txt.eNoEnvelope = "Could'nt get a volume envelope for the music track!"
txt.eNoTracks = "There are no tracks in current project."
txt.eOnlyOneTrack = "You need at least two tracks in current project!"
txt.eEmpty = "The field %s must not be empty!"
txt.eNoNumber = "The text %s in field %s is not a number!"
txt.eSaving = "Error saving user parameters!"
txt.eFirstItem = "There is not enough space left to the first item to perform the operation."
txt.eSpaceBetweenItems = "There is not enough space between Items %d and %d to perform the operation."
--questions
txt.qTrackNames = "Music track is %s and speech track is %s.\n" ..
  "correct?"
--informational
txt.iIncorrectTracks = "focus the music track and make sure, that the track with speech is underneath it."
txt.iAborted = "Script aborted!"
txt.iTotalPoints = "Created %d envelope points.\n" ..
  "AutoDuck finished!"
--texts for the select user values dialog
txt.dTitle = "Specify values for auto ducking"
txt.dReduceDB = "duck amount in DB"
txt.dOuterFadeDown = "outer fade down length"
txt.dOuterFadeUp = "outer fade up length"
txt.dInnerFadeDown = "inner fade down length"
txt.dInnerFadeUp = "inner fade up length"
txt.dShape = "Shape (0=linear; 1=square; 2=slow start/end; 3=fast start; 4=fast end"

function main()
  --are at least two tracks int he current project?
  if not checkTrackCount() then
    return
  end--if
  --The music track should be the one which is focused at script start.
  local musicTrack = reaper.GetSelectedTrack (0, 0)
  if not musicTrack then
    reaper.ShowMessageBox (string.format (txt.eNoMusicSpeechTrack, "music"), txt.error, 0)
    return
  end--if
  --speechTrack has to be the next one in track list, get the number of music track to find the second one
  local musicTrackNumber = reaper.GetMediaTrackInfo_Value(musicTrack, "IP_TRACKNUMBER")
  --this track number is 1 based, so nothing needs to be added to find the speech track
  local speechTrack = reaper.GetTrack (0, musicTrackNumber)
  if not speechTrack then
    reaper.ShowMessageBox (string.format (txt.eNoMusicSpeechTrack, "speech"), txt.error, 0)
    return
  end--if
  --get the names of music and speech track for display
  if not trackNamesOk(musicTrack, speechTrack) then
    return
  end--if
  --get all values needed for the auto duck from the user.
  params = {} --global table of all parameters the user can specify
  loadParams() --loads the values from current project, fills params with standard values if there are no values
  if not getUserValues(speechTrack) then
    --user has canceled the dialog
    return
  end--if
  
  --now all values are there and checked - let's do the changes.
  --let's grab a volume envelope, if any
  volumeEnvelopeActivated = false -- will be set to true, if checkVolumeEnvelope creates a new one
  reaper.Undo_BeginBlock()
  local envelope = checkVolumeEnvelope (musicTrack)
  if not envelope then
    reaper.ShowMessageBox(txt.eNoEnvelope, txt.error, 0)
    reaper.Undo_EndBlock (scriptName, -1)
    return
  end--if
  local totalPoints = createEnvelopePoints (speechTrack, envelope)
  if volumeEnvelopeActivated then
    --The volume envelope has been activated during the script run, deactivate it.
    reaper.Main_OnCommand (40406, 0) --Track: Toggle track volume envelope visible
  end--if
  reaper.Undo_EndBlock (scriptName, -1)
  saveParams() --saves the values for autoducking entered by the user in current project
  reaper.ShowMessageBox (string.format (txt.iTotalPoints, totalPoints), txt.info, 0)
end--main

function checkTrackCount()
--checks if at least two tracks are in the project, returns true
  local nTracks = reaper.CountTracks (0)
  if nTracks == 0 then
    reaper.ShowMessageBox (txt.eNoTracks, txt.error, 0)
    return false
  elseif nTracks < 2 then
    reaper.ShowMessageBox (txt.eOnlyOneTrack, txt.error, 0)
    return false
  else
    return true
  end--if
end--checkTrackCount

function trackNamesOk (musicTrack, speechTrack)
--asks the user if the correct music and speech track have been selected.
--returns false if user answers no.
  --get names of speech and music track
  local musicTrackName = ""
  local speechTrackName = ""
  _, musicTrackName = reaper.GetTrackName (musicTrack)
  _, speechTrackName = reaper.GetTrackName (speechTrack)
  if reaper.ShowMessageBox (string.format (txt.qTrackNames, musicTrackName, speechTrackName), txt.question, 4) == 7 then
    --user has answered no
    reaper.ShowMessageBox(txt.iIncorrectTracks, txt.info, 0)
    return false
  end--if
  return true
end--trackNamesOk

function getValue(s, x, key, fieldName)
--belongs to getUserValues
--looks for the xth value from the csv-formatted string s.
--if it's filled and can be converted to a number, params[key] is filled with the value.
--returns true, if the entered text was a number
  --jump to the desired value in the string
  local pos = 0
  for i = 1, x-1 do
    pos = string.find (s, ",", pos+1)
  end--for
  pos = pos + 1 --begin of desired value
  if string.sub (s, pos, 1) == "," then --empty value
    reaper.ShowMessageBox (string.format (txt.eEmpty, fieldName), txt.error, 0)
    return false
  end--if
  local value = string.sub (s, pos, string.find (s, ",", pos)-1)
  local numValue = tonumber(value)
  if not numValue then
    reaper.ShowMessageBox (string.format (txt.eNoNumber, value, fieldName), txt.error, 0)
    return false
  end--if
  params[key] = numValue
  return true
end--getValue

function checkSpaceBetweenItems (track)
--checks if there is enough space arround the items to perform the autoDuck.
  --collect start- and endpositions for all items
  local startPos = {}
  local endPos = {}
  local curItem = nil
  local itemsOnTrack = reaper.CountTrackMediaItems(track)
  for i = 0, itemsOnTrack-1 do
    curItem = reaper.GetTrackMediaItem (track, i)
    startPos[i] = reaper.GetMediaItemInfo_Value(curItem, "D_POSITION")
    endPos[i] = startPos[i] + reaper.GetMediaItemInfo_Value(curItem, "D_LENGTH")
  end--for
  --check if there's enough space left to the first item
  if startPos[0]-params.outerFadeDown < 0 then
    reaper.ShowMessageBox (txt.eFirstItem, txt.error, 0)
    return false
  end--if
  --check the space between the other items, start with item 2, which has number 1
  for i = 1, itemsOnTrack-1 do
    if startPos[i]-endPos[i-1] < params.outerFadeUp+params.outerFadeDown then
      reaper.ShowMessageBox (string.format (txt.eSpaceBetweenItems, i, i+1), txt.error, 0)
      return false
    end--if
  end--for
  return true
end--checkSpaceBetweenItems

function getUserValues(speechTrack)
--Displays the dialog for getting the needed values from the user.
--returns false, if user aborted the dialog, true otherwise
  repeat
    local retVal, userValues = reaper.GetUserInputs (
      txt.dTitle,
      6,
      string.format ("%s:,%s:,%s:,%s:,%s:,%s:", 
        txt.dReduceDB,
        txt.dOuterFadeDown,
        txt.dOuterFadeUp,
        txt.dInnerFadeDown,
        txt.dInnerFadeUp,
        txt.dShape),
      string.format ("%s,%s,%s,%s,%s,%s",
        params.reduceDB,
        params.outerFadeDown,
        params.outerFadeUp,
        params.innerFadeDown,
        params.innerFadeUp,
        params.shape))
    if not retVal then
      --user has canceled the dialog
      reaper.ShowMessageBox (txt.iAborted, txt.info, 0)
      return false
    end--if
    userValues = userValues .. "," --put a comma to the end, so getValue don't have to know the end of the string
  until getValue(userValues, 1, "reduceDB", txt.dReduceDB) and
    getValue(userValues, 2, "outerFadeDown", txt.dOuterFadeDown) and
    getValue(userValues, 3, "outerFadeUp", txt.dOuterFadeUp) and
    getValue(userValues, 4, "innerFadeDown", txt.dInnerFadeDown) and
    getValue(userValues, 5, "innerFadeUp", txt.ddInnerFadeUp) and
    getValue(userValues, 6, "shape", txt.dShape) and
    checkSpaceBetweenItems (speechTrack)
  return true
end--getUserValues

function checkVolumeEnvelope(track)
--[[if there's already a volume envelope on the music track, it will be made visible, if it's not visible.
    If not, a new one will be created, by making it visible and use it.
    Returns the envelope, nil if an error occured.
]]--
  local envelope = nil
  local envelopesOnTrack = reaper.CountTrackEnvelopes (track)
  local envelopeName = ""
  local i = 0
  --check if there is already a volume envelope, if so, use it, but make it visible
  while i < envelopesOnTrack do
    envelope = reaper.GetTrackEnvelope (track, i)
    _, envelopeName = reaper.GetEnvelopeName (envelope)
    if envelopeName == "Volume" then
      local isVisible = ""
      _, isVisible = reaper.GetSetEnvelopeInfo_String (envelope, "VISIBLE", "", false)
      if isVisible == "0" then
        volumeEnvelopeActivated = true
        reaper.Main_OnCommand (40406, 0) --Track: Toggle track volume envelope visible
      end--if
      --envelope is a volume envelope and is visible, return it.
      return envelope
    end--if
    i = i + 1
  end--while
  --no volume envelope found, let's get one
  reaper.Main_OnCommand (40406, 0) --Track: Toggle track volume envelope visible
  --now we have a volume envelope, let's find it.
  envelopesOnTrack = reaper.CountTrackEnvelopes (track)
  i = 0
  while i < envelopesOnTrack do
    envelope = reaper.GetTrackEnvelope (track, i)
    _, envelopeName = reaper.GetEnvelopeName (envelope)
    if envelopeName == "Volume" then
      volumeEnvelopeActivated = true
      return envelope
    end--if
    i = i + 1
  end--while
  --newly created volume envelope was not found...
  return nil
end--checkVolumeEnvelope

function createEnvelopePoints (track, envelope)
--creates all the necessary points on the volume envelope.
--returns the number of created envelope points.
  local zeroDB = reaper.DB2SLIDER(0)
  local reduceDB = reaper.DB2SLIDER(params.reduceDB)
  local curItem = nil
  local itemsOnTrack = reaper.CountTrackMediaItems(track)
  local totalPoints = 0
  for i = 0, itemsOnTrack-1 do
    curItem = reaper.GetTrackMediaItem (track, i)
    local startPosition = reaper.GetMediaItemInfo_Value(curItem, "D_POSITION")
    local endPosition = startPosition + reaper.GetMediaItemInfo_Value(curItem, "D_LENGTH")
    reaper.InsertEnvelopePoint (envelope, startPosition-params.outerFadeDown, zeroDB, params.shape, 0, false, true)
    reaper.InsertEnvelopePoint (envelope, startPosition+params.innerFadeDown, reduceDB, params.shape, 0, false, true)
    reaper.InsertEnvelopePoint (envelope, endPosition-params.innerFadeUp, reduceDB, params.shape, 0, false, true)
    reaper.InsertEnvelopePoint (envelope, endPosition+params.outerFadeUp, zeroDB, params.shape, 0, false, true)
    totalPoints = totalPoints + 4
  end--for
  reaper.Envelope_SortPoints (envelope)
  return totalPoints
end--createEnvelopePoints

function loadParams()
--fills the params table with default values, tries to load values from current project.
  --fill params with default values, if no values stored in current project.
  params.reduceDB = "-18"
  params.outerFadeDown = "0.5"
  params.outerFadeUp = "0.5"
  params.innerFadeDown = "1"
  params.innerFadeUp = "1"
  params.shape = "2" --slow start/end
  local value = ""
  --load values from current project
  for key,x in pairs(params) do
    _, value = reaper.GetProjExtState (0, scriptName, key)
    if value ~= "" then
      params[key] = value
    end--if
  end--for
end--loadFromFile

function saveParams()
--saves the params into current project
  for key,value in pairs(params) do
    if reaper.SetProjExtState (0, scriptName, key, value) == 0 then
      reaper.ShowMessage(txt.eSaving, txt.error, 0)
    end--if
  end--for
end--saveToFile

main()

--Resample Notes - render selected MIDI notes, load sample to ReaSamplOmatic5000

--Midi Editor script to automatically copy selected notes to new item, apply fx, 
--load sample to sampler, set root note in sampler, remove new item, mute origally selected notes in original item
--and insert root note in the corresponding possition. 
--Basically. There are several options here so you can change the behavior to suit your needs. See [USER SETTINGS] section below.

--This is the main script. Can be launched from a preset/GUI script or by itself.
--Please, keep this script name as "daodan_Resample notes.lua" for launching from preset/GUI script.

--Have fun!

function UserSettings()

  --[USER SETTINGS]-----------------------------------
  
  --output--
  loadToSampler = 1 --set 1 to load to rs5k, 0 to keep in arrange. set 2 for both (load to rs5k and keep in arrange). -1 to disable rendering (midi notes will still be copied)
  samplerPreset = '' -- Set to 'Preset name' to load 'Preset name' preset in rs5k before setting root note and loading new sample. Keep as '' to load defaul preset
  useNewTrack = 0 -- set 1 to insert rs5k/rendered audio to new track
  keepTakes = 1 --1 to keep copied midi and rendered audio (before and after reverse) in takes in new item. Makes sense only when sample is keeped in arrange (only final take loaded to sampler)
  
  --root note--
  insertRootNote = 1 --set 1 to insert root note in MIDI item when sample loaded in rs5k
  useOrigItemToInserRootNote = 1 --1 to insert root note in original midi item. Auto disabled when useNewTrack = 1 (because there is no point in inserting root note at orig track midi when rs5k is on another)
  disableAutoCorrectOverlap = 1 --1 to disable Automatically correct overlapping notes option. Used (only) when root note inserted in orig item to prevent deletion of notes
  getRootNoteMode = 0 --how to get root note. 0 - lowest note, 1 - user input, 2 - fixed (fixedRootNote) 
  fixedRootNote = 60 --value used when root note fixed or when no slected notes in user input mode
  midiChannel = 1 --midi channel for inserted root note and rs5k. If set to 0 then all channels used in rs5k and ch1 used for inserted note
  
  --reverse fun--
  reverseNotes = 0 -- set 1 to reverse notes before rendering to audio
  reverseSample = 0 --set 1 to reverse sample before loading to rs5k. "Item: Reverse items to new take" action used
  shiftReversedSampleLeft = 0 --set to 1 to move item/note left to align reversed sample end to orig start. Useful for "Swell FX"
  
  --sample lenght--
  overrideApplyFxTail = 0 -- set 1 to override "Tail length when using Apply FX to items" value (Preferences > Media)
  applyFxTail = 0 -- value used to temporary override Apply Fx tail length when overrideApplyFxTai l = 1
  useFullSample = 0 -- set 1 to include apply fx tail in resampled item. Affects both item in arrange and sampler
  
  --source--
  selectedNotesOnly = 1 -- set 1 to solo selected notes before render. Other value to use all notes within time selection.
  ignoreTimeSelection = 0 --set 1 to not use original time selection to set copy midi/render section. Otherwise section auto set to selected notes if selectedNotesOnly enabled and to all notes if selectedNotesOnly is disabled
  
  --post-processing--
  muteOrigNotes = 1 --1 to mute orig notes
  bypassOrigFx = 1 --set 1 to bypass all fx on orig track beafore rs5k
  
  preRenderAction = 0 -- run any action/script before rendering MIDI copy. Here selected item is a copy of selected notes from original item placed on original track.
                      --0 - no action, 
                      --1 - main section, 2 - midi editor section
                     
  preRenderActionID = '' -- pre-render action id. Place inside ''. For example: '40515' or '_SWS_ITEMCUSTCOL1' or ''
  
  postRenderAction = 0 -- run any action/script after rendering MIDI copy, before loading to sampler. Here selected item is rendered (audio) item placed on original track or new track if useNewTrack = 1
                       --0 - no action, 
                       --1 - main section, 2 - midi editor section
                     
  postRenderActionID = '' -- post-render action id. Place inside ''. For example: '40515' or '_SWS_ITEMCUSTCOL1' or ''
  
  postProcAction = 0 -- run any action/script after this script.
                     --0 - no action, 
                     --1 - main section, 2 - midi editor section
                     
  postProcActionID = '' -- post-action id. Place inside ''. For example: '40515' or '_SWS_ITEMCUSTCOL1' or ''
  
  --[USER SETTINGS END]-------------------------------
end

if not externalRun then UserSettings() end --check if run from preset/GUI script, use user settings from this script if not
if wasRunToGetPresetFromGUI then return end --exit after loading user settings if was run to get preset

--FUNCTIONS--
function say(sayStr,sayTitleStr) --show message
  if not sayStr then sayStr = 'Please, select notes and time from MIDI Editor' end
  if not sayTitleStr then sayTitleStr = 'Resample Notes' else sayTitleStr = 'Resample Notes: '..tostring(sayTitleStr) end
  reaper.ShowMessageBox(tostring(sayStr), sayTitleStr, 0)
end

function runAction(action, actionID)
  if actionID and actionID ~= '' then
  
    if action == 1 then --Main section
      reaper.Main_OnCommand(reaper.NamedCommandLookup(actionID), 0)
      
    elseif action == 2 then --MIDI Editor section
      reaper.MIDIEditor_LastFocused_OnCommand(reaper.NamedCommandLookup(actionID), 0)
  
    end
      
  end
end

function addFx(fx, fxName, fxPreset)--fx for track or take fx
  -------------
end

function runActionAndOrAddFx(order, action, actionID, fx, fxName, fxPreset)--order defines what first action or add fx
  if order == 0 then
    runAction(action,actionID)
    addFx(fx, fxName, fxPreset)
  else
    addFx(fx, fxName, fxPreset)
    runAction(action,actionID)
  end
end

function CheckSelNotes(t) --t for take
  retval, notes, ccs, sysex = reaper.MIDI_CountEvts(t)
  for i = 0, notes-1 do
    retval, sel, muted, startppqposOut, endppqposOut, chan, pitch, vel = reaper.MIDI_GetNote(t, i)
    if sel == true then break end
  end
  if notes == 0 or sel == false then return end --return if no notes or no selected notes 
  return 1
end

function GetEditableMidiTakes(ME)--ME for Midi Editor
  local takes_T = {}
  if ME then
    local takeCount = 0
    while true do
      local take = reaper.MIDIEditor_EnumTakes(ME, takeCount, true)
      if not take then break end
      takeCount = takeCount + 1
      takes_T[takeCount] = take
    end
    
    return takes_T
  end
end

function GetSelectedItemsTakes()
  local takes_T = {}
  local takeCount = 0
  local itemCount = reaper.CountMediaItems(0)
  if itemCount>0 then
    for i=0, itemCount-1 do
      local item = reaper.GetMediaItem(0, i)
      if reaper.IsMediaItemSelected(item) then
        local take = reaper.GetActiveTake(item)
        if take then
          takeCount = takeCount+1
          takes_T[takeCount] = take
        end
      end
    end
  else
    return
  end
  
  return takes_T
end

function GetTimeSel()
  local timeSelStartTime, timeSelEndTime = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  if timeSelStartTime == timeSelEndTime then return end
  return timeSelStartTime, timeSelEndTime
end

function Init() --check midi editor, takes, selected notes and time selection
  
  origMidiEditor = reaper.MIDIEditor_GetActive()
  if not origMidiEditor then say(_, 'No MIDI Editor') return end --return if no midi editor
  
  origTakes_T = GetEditableMidiTakes(origMidiEditor)
  if not origTakes_T[1] then say(_, 'No take in MIDI Editor') return end --return if no take in midi editor
  
  for i=1, #origTakes_T do if CheckSelNotes(origTakes_T[i]) then selNotesExist = true break end end
  if (not selNotesExist) and (selectedNotesOnly == 1) then say(_, 'No selected notes') return end --return if no selected note
  
  reaper.Main_OnCommand(40289, 0)-- Item: Unselect (clear selection of) all items
  reaper.Main_OnCommand(40297,0)--Track: Unselect (clear selection of) all tracks
  
  for i = 1, #origTakes_T do --select items with takes from midi editor to copy this items by time selection, select track by those items
    local item = reaper.GetMediaItemTake_Item(origTakes_T[i])
    reaper.SetMediaItemSelected(item, 1 )--select items of 
    reaper.SetTrackSelected(reaper.GetMediaItem_Track(item), 1)
  end
  
  if reaper.CountSelectedTracks(0)>1 then say('Multiple tracks are not supported', 'Sorry') return end --return if multiple tracks
  
  origEditCursor = reaper.GetCursorPosition()--save orig cursor position to restore it back at exit
  origTrack = reaper.GetSelectedTrack(0,0)--save orig track to use later
  
  workTimeSelStart, workTimeSelEnd = GetTimeSel() --get time selection to work with
  origTimeSelStart, origTimeSelEnd = workTimeSelStart, workTimeSelEnd --save original time selection to restore
  
  --if muteOrigNotes==1 and selectedNotesOnly == 0 then select all notes within time selection to be able to mute them by selection
  if  muteOrigNotes==1 and selectedNotesOnly == 0 then reaper.MIDIEditor_OnCommand(origMidiEditor,40746) end --Edit: Select all notes in time selection
  
  --check if time sel exist. If not or ignoreTimeSel==1 then set to items. If exist then check is it outside of items. If so set to items too, If not keep original time sel
  if ignoreTimeSelection == 1 or not workTimeSelStart then 
    reaper.Main_OnCommand(40290,0)--Time selection: Set time selection to items
    workTimeSelStart, workTimeSelEnd = GetTimeSel()--save as work time sel
    --set ignoreTimeSelection 1 so later script work the same for this option and if no ts was set, for example in copy notes section
    ignoreTimeSelection = 1 -- so when time selection set to notes script keep this selection in CopyNotesToNewItem() instead of reverting back
  else
    reaper.Main_OnCommand(40290,0)--Time selection: Set time selection to items
    newTsStart, newTsEnd = GetTimeSel()----save new time sel
    if workTimeSelEnd <= newTsStart+0000.1 or newTsEnd-0000.1 < workTimeSelStart then --if orig time sel is outside of new time sel (set to items)
      workTimeSelStart, workTimeSelEnd = GetTimeSel()                                 --then save new time sel as work time sel
      ignoreTimeSelection = 1 --same reason as in previous 
    else
      reaper.GetSet_LoopTimeRange( true, false, workTimeSelStart, workTimeSelEnd, false )--otherwise revert to previous work time selection
    end
  end 
  return 1
end

function DeleteUnselectedNotes(t) --t for take
  retval, notes, ccs, sysex = reaper.MIDI_CountEvts(t)--count all notes in take
  for k = notes-1, 0, -1 do --delete selected notes from the end
    retval, sel, muted, startppqposOut, endppqposOut, chan, pitch, vel = reaper.MIDI_GetNote(t, k)
    if sel == false then reaper.MIDI_DeleteNote(t, k) end
  end
end

function MuteSelectedNotes(t) --t for take
  retval, notes, ccs, sysex = reaper.MIDI_CountEvts(t)--count all notes in take
  for k = notes-1, 0, -1 do --delete selected notes from the end
    retval, sel, muted, startppqposOut, endppqposOut, chan, pitch, vel = reaper.MIDI_GetNote(t, k)
    if sel == true then reaper.MIDI_SetNote( t, k, _, 1, _, _, _, _, _, _) end
  end
end

function CopyNotesToNewItem()
  --disable conflicting options
  trimWasOn=reaper.GetToggleCommandState(41117)--Options: Trim content behind media items when editing
  if trimWasOn==1 then reaper.Main_OnCommand(41117, 0)  end --trim content disable
  
  --copy midi items section by ts
  reaper.Main_OnCommand(40060,0)--Item: Copy selected area of items
  reaper.SetEditCurPos( workTimeSelStart, false, false ) --set edit cursor to start of time selection
  reaper.Main_OnCommand(40914,0)--Track: Set first selected track as last touched track
  reaper.Main_OnCommand(42398,0)--Item: Paste items/tracks
  reaper.Main_OnCommand(41613,0)--Item: Remove active take from MIDI source data pool (unpool)
  
  newTakes_T = GetSelectedItemsTakes()
  
  --remove unselected notes from new items takes
  if selectedNotesOnly == 1 then
    if not newTakes_T[1] then say('Something wrong','no take') return end
    for i=1, #newTakes_T do
      DeleteUnselectedNotes(newTakes_T[i])
    end
  end
  
  --glue item to open in MIDI editor to set time selection to first/last note
  reaper.Main_OnCommand(40362,0)--Item: Glue items, ignoring time selection

  newTakes_T = GetSelectedItemsTakes()
  --check if any notes exist inside new item
  --if not then delete new item and return
  retval, notes, ccs, sysex = reaper.MIDI_CountEvts(newTakes_T[1])
  if notes == 0  then 
    say('No MIDI notes inside time selection','Empty section copied')
    reaper.Main_OnCommand(40006,0)--Item: Remove items-- remove new item
    return 
  end
  
  reaper.Main_OnCommand(40153, 0)--Item: Open in built-in MIDI editor--without it next does not work
  
  reaper.MIDIEditor_LastFocused_OnCommand(40003,0)--Edit: Select all notes
  reaper.MIDIEditor_LastFocused_OnCommand(40752,0)--Edit: Set time selection to selected notes
  
  newTsStart, newTsEnd = GetTimeSel()--save new time sel
  
  --if ignore ts is on then save new time sel as work time sel (change start, end)
  --else keep end of work ts (change start only)
  if ignoreTimeSelection == 1 then 
    workTimeSelStart, workTimeSelEnd = newTsStart, newTsEnd --save new start as work ts start
  else
    workTimeSelStart = newTsStart --save new start as work ts start
    reaper.GetSet_LoopTimeRange( true, false, workTimeSelStart, workTimeSelEnd, false )--set time selection
  end
  
  reaper.Main_OnCommand(40508, 0)--Item: Trim items to selected area
  reaper.Main_OnCommand(42432,0)--Item: Glue items within time selection
  
  reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0,0), 'B_LOOPSRC', 0 ) --disable item looping
  
  --reverse selected notes before rendering
  reaper.MIDIEditor_LastFocused_OnCommand(40003,0)--Edit: Select all notes
  if reverseNotes == 1 then reaper.MIDIEditor_LastFocused_OnCommand(40902,0) end--Edit: Reverse selected events
  
  newTakes_T = GetSelectedItemsTakes()--get final midi take

  --rename new item to new beautiful name
  retval, origTrackName = reaper.GetSetMediaTrackInfo_String(origTrack, 'P_NAME', "", false)
  reaper.GetSetMediaItemTakeInfo_String(newTakes_T[1], 'P_NAME', origTrackName..' [resampled]', true)
  
  if trimWasOn==1 then reaper.Main_OnCommand(41117, 0) end--trim content enable back
  
  return newTakes_T[1] --return new take (with copied notes, processed)

end

function GetRootNote(t) --t for take
  if getRootNoteMode == 2 or loadToSampler<1 then return fixedRootNote end --return fixed root note if mode is 2 (or if no sampler loading)
  
  if getRootNoteMode == 1 then 
    midiEditorWasDocked=reaper.GetToggleCommandStateEx(32060,40018)
    if midiEditorWasDocked==1 then reaper.MIDIEditor_LastFocused_OnCommand(40018, 0) end --undock midi editor because it's blocked by messege box if it's docked and user can't select root note
    reaper.ShowMessageBox("Please, select root note and click OK.", "Resample Note", 0)--show window so user can select root note from ME
    if midiEditorWasDocked==1 then reaper.MIDIEditor_LastFocused_OnCommand(40018, 0) end --dock back if was docked
  end 
  
  retval, notes, ccs, sysex = reaper.MIDI_CountEvts(t)
  minPitch = 128
  for k = 0, notes-1 do
    retval, sel, muted, startppqposOut, endppqposOut, chan, pitch, vel = reaper.MIDI_GetNote(t, k)
    
    if sel == true then
      minPitch = math.min(minPitch,pitch)
    end
  end
  if minPitch == 128 then return fixedRootNote end --if no notes selected use fixedRootNote for toor note
  return minPitch
end

function LoadSelItemToSampler (rn) --rn for root note
  
  if loadToSampler<1 then return end
  
  local item = reaper.GetSelectedMediaItem(0, 0)
  local track = reaper.GetMediaItemTrack(item)
  local take = reaper.GetActiveTake(item)
  local takeSource = reaper.GetMediaItemTake_Source(take)
  local file = reaper.GetMediaSourceFileName(takeSource, '')
  
  local sourceStartOffset = reaper.GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
  local sourceLength =reaper.GetMediaSourceLength( takeSource )
  local itemLength = reaper.GetMediaItemInfo_Value( item, 'D_LENGTH' )
  
  fx = reaper.TrackFX_AddByName( track, 'ReaSamplomatic5000', false, -1 )--add rs5k
  
  reaper.TrackFX_SetPreset( track, fx, samplerPreset )--load rs5k preset if specified 
  
  reaper.TrackFX_SetNamedConfigParm(track, fx, 'FILE0', file) --load sample
  reaper.TrackFX_SetNamedConfigParm(track, fx, 'DONE', '')    --load sample
  retval, noteStart = reaper.TrackFX_GetFormattedParamValue(  track, fx, 3,'' )
  if rn then reaper.TrackFX_SetParamNormalized(track, fx, 5, 0.5-(rn-noteStart)*0.00625 )end -- set Pith@start (root note)
  
  reaper.TrackFX_SetParamNormalized(track, fx, 7, midiChannel/16)    --set MIDI channel
  
  --set start/end like in item--
  reaper.TrackFX_SetParamNormalized(track, fx, 13, sourceStartOffset/sourceLength)
  reaper.TrackFX_SetParamNormalized(track, fx, 14, (sourceStartOffset+itemLength)/sourceLength)
  
  if loadToSampler ~= 2 then
    reaper.Main_OnCommand(40006,0)--Item: Remove items
  end
  
  return
end

function RenderSelItem()
  
  if loadToSampler < 0 then --return if loadToSampler set to 'no render'. bypass fxs and move item to new track before that if set
    
    if bypassOrigFx==1 then reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_FXBYPALL2"), 0) end--SWS/S&M: Bypass all FX for selected track
    
    if useNewTrack == 1 then--move sel item to new track
      reaper.Main_OnCommand(40001,0) --insert new track
      reaper.Main_OnCommand(40118,0) --Item edit: Move items/envelope points down one track/a bit
    end
    return 
  end
  
  reaper.SetMediaItemInfo_Value( reaper.GetSelectedMediaItem(0,0), 'B_LOOPSRC', 0 ) --disable item looping
  
  --apply fx (render to audio) with custom apply fx tail if enabled
  if overrideApplyFxTail==1 then --set custom apply fx tail lenght if any--
    origApplyFxTail=reaper.SNM_GetIntConfigVar('applyfxtail',1)
    reaper.SNM_SetIntConfigVar('applyfxtail', applyFxTail)
  end
  reaper.Main_OnCommand(40209, 0)--Item: Apply track/take FX to items
  if overrideApplyFxTail == 1 then reaper.SNM_SetIntConfigVar('applyfxtail', origApplyFxTail) end --set previous apply fx tail value
  
  local item = reaper.GetSelectedMediaItem(0, 0)
  
  if useFullSample == 1 then reaper.Main_OnCommand(42228, 0) end --Item: Set item start/end to source media start/end --show full source
  
  if reverseSample == 1 then --render reversed
    reaper.Main_OnCommand(40270, 0) --Item: Reverse items to new take --RENDERS reverse to new take
  end
  
  if keepTakes ~= 1 then reaper.Main_OnCommand(40131, 0) end --Take: Crop to active take in items. Keep final take only.
  
  if bypassOrigFx==1 then reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_FXBYPALL2"), 0) end--SWS/S&M: Bypass all FX for selected track
  
  if useNewTrack == 1 then--move sel item (rendered audio) to new track
    reaper.Main_OnCommand(40001,0) --insert new track
    reaper.Main_OnCommand(40118,0) --Item edit: Move items/envelope points down one track/a bit
  end
  
  if reverseSample == 1 and shiftReversedSampleLeft == 1 then --move item to align end to orig start and save time selection for root note inser shifted
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_MOVEITEMSLEFTBYLEN"), 0)--Xenakios/SWS: Move selected items left by item length
  end
  
  reaper.Main_OnCommand(40290,0)--Time selection: Set time selection to items
  workTimeSelStart, workTimeSelEnd = GetTimeSel()--update time sel save in case item is moved
  
end

function InsertRootNoteInTimeSel (insRN)
  
  if insertRootNote ~= 1 or loadToSampler < 1 then return end
  
  if midiChannel == 0 then chan = 0 else chan = midiChannel-1 end
  
  --disable conflicting options
  trimWasOn=reaper.GetToggleCommandState(41117)--Options: Trim content behind media items when editing
  if trimWasOn==1 then reaper.Main_OnCommand(41117, 0)  end --trim content disable
  
  if useOrigItemToInserRootNote == 1 and useNewTrack ~=1 then --check what item from orig items exist within start point (where start of work ts and new item)
    
    for i=1, #origTakes_T do 
      local item = reaper.GetMediaItemTake_Item(origTakes_T[i])
      local itemStart = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
      local itemEnd = itemStart+reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
      if workTimeSelStart>=itemStart-0.0000000001 and workTimeSelStart<itemEnd then -- item start < ts start < item end
        take = origTakes_T[i]
        break 
      end
    end
    
    --open proper orig item take in midi editor to disable autocorrect overlapping
    reaper.Main_OnCommand(40289,0)--Item: Unselect (clear selection of) all items
    reaper.SetMediaItemSelected(reaper.GetMediaItemTake_Item(take) , 1)
    reaper.Main_OnCommand(40153, 0)--Item: Open in built-in MIDI editor
    
    if disableAutoCorrectOverlap == 1 then
      if reaper.GetToggleCommandStateEx(32060,40681)==1 then reaper.MIDIEditor_LastFocused_OnCommand(40681, 0) end --disable if was enabled
    end
    
    --get ppq pos from work time sel
    startPpqPos=reaper.MIDI_GetPPQPosFromProjTime(take, workTimeSelStart)
    endPpqPos=reaper.MIDI_GetPPQPosFromProjTime(take, workTimeSelEnd)
    --get loop (source) length in ppq
    takePpqLength = reaper.BR_GetMidiSourceLenPPQ(take)
    
    --if startPpq position (note start) is outside first loop then shift whole area (start and end) to the first loop
    if startPpqPos >= takePpqLength then
      local ostatok = startPpqPos%takePpqLength --remainder of division
      local midiLoopCount = (startPpqPos-ostatok)/takePpqLength --number of loop repetitions at startPpqPos
      --move start/end left (to the first loop) by souce (loop) lenght * number of repetitions
      startPpqPos = startPpqPos - takePpqLength*midiLoopCount
      endPpqPos   =   endPpqPos - takePpqLength*midiLoopCount
    end
    
    --if endPpq position (note end) is outside loop then set it to source length (prevent notes from extending source)
    if endPpqPos > takePpqLength then endPpqPos = takePpqLength end
    
    --finaly... insert note
    reaper.MIDI_InsertNote( take, true, false, startPpqPos, endPpqPos, chan, insRN, 127)
    
  else
    --just insert new item and note in it
    reaper.Main_OnCommand(40214, 0)--Insert new MIDI item...
    take = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, 0))
    --insert note by work time sel
    startPpqPos=reaper.MIDI_GetPPQPosFromProjTime(take, workTimeSelStart)
    endPpqPos=reaper.MIDI_GetPPQPosFromProjTime(take, workTimeSelEnd)
    reaper.MIDI_InsertNote( take, true, false, startPpqPos, endPpqPos, chan, insRN, 127)
    
    --rename to beautiful name
    reaper.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '[root note '..rootNote..']', true)
    
  end
  
  --enable disabled options back
  if trimWasOn==1 then reaper.Main_OnCommand(41117, 0) end--trim content enable back

end

function MuteOrigSelNotes()
  if muteOrigNotes ~= 1 then return end
  
  for i=1, #origTakes_T do
    MuteSelectedNotes(origTakes_T[i])
  end
  
end

--MAIN--
function main ()
  reaper.PreventUIRefresh(1)
  
  if not Init() then return end
  midiCopyTake = CopyNotesToNewItem()
  if not midiCopyTake then 
    --say('Copy failed','') 
    return 
  end
  rootNote = GetRootNote(midiCopyTake)
  
  runActionAndOrAddFx(0, preRenderAction, preRenderActionID, 0, 0, 0)--pre-render action
  
  RenderSelItem()
  
  runActionAndOrAddFx(0, postRenderAction, postRenderActionID, 0, 0, 0)--post-render action
  
  LoadSelItemToSampler(rootNote)
  MuteOrigSelNotes()
  InsertRootNoteInTimeSel(rootNote)
  
  runActionAndOrAddFx(0, postProcAction, postProcActionID, 0, 0, 0)--post action
  
  reaper.SetEditCurPos(origEditCursor,0,0)--restore edit cursor
  reaper.GetSet_LoopTimeRange( true, false, origTimeSelStart, origTimeSelEnd, false )--restore time selection
  
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  
end

reaper.Undo_BeginBlock()
  main()
reaper.Undo_EndBlock("Resample notes",-1)

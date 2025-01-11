-- @noindex

--Resample Notes - render selected MIDI notes, load sample to ReaSamplOmatic5000

--Midi Editor script to automatically copy selected notes to new item, apply fx, 
--load sample to sampler, set root note in sampler, remove new item, mute origally selected notes in original item
--and insert root note in the corresponding possition. 
--Basically. There are several options here so you can change the behavior to suit your needs. See [USER SETTINGS] section below.

--This is a preset script. Can run main script (Resample Notes Main.lua) with [USER SETTINGS]. 
--Can be used to load preset from GUI script.

--Please keep list of variables in user setting section same as in main script 
--and keep this script in "Resample Notes Presets" folder and keep "Resample Notes Presets" folder in the same folder with the main script.
--Have fun!

  --[USER SETTINGS]-----------------------------------
  
  --output--
  loadToSampler = 0 --set 1 to load to rs5k, 0 to keep in arrange. set 2 for both (load to rs5k and keep in arrange). -1 to disable rendering (midi notes will still be copied)
  samplerPreset = '' -- Set to 'Preset name' to load 'Preset name' preset in rs5k before setting root note and loading new sample. Keep as '' to load defaul preset
  useNewTrack = 1 -- set 1 to insert rs5k/rendered audio to new track
  keepTakes = 0 --1 to keep copied midi and rendered audio (before and after reverse) in takes in new item. Makes sense only when sample is keeped in arrange (only final take loaded to sampler)
  
  --root note--
  insertRootNote = 0 --set 1 to insert root note in MIDI item when sample loaded in rs5k
  useOrigItemToInserRootNote = 0 --1 to insert root note in original midi item. Auto disabled when useNewTrack = 1 (because there is no point in inserting root note at orig track midi when rs5k is on another)
  disableAutoCorrectOverlap = 1 --1 to disable Automatically correct overlapping notes option. Used (only) when root note inserted in orig item to prevent deletion of notes
  getRootNoteMode = 0 --how to get root note. 0 - lowest note, 1 - user input, 2 - fixed (fixedRootNote) 
  fixedRootNote = 60 --value used when root note fixed or when no slected notes in user input mode
  midiChannel = 1 --midi channel for inserted root note and rs5k. If set to 0 then all channels used in rs5k and ch1 used for inserted note
  
  --reverse fun--
  reverseNotes = 1 -- set 1 to reverse notes before rendering to audio
  reverseSample = 1 --set 1 to reverse sample before loading to rs5k. "Item: Reverse items to new take" action used
  shiftReversedSampleLeft = 0 --set to 1 to move item/note left to align reversed sample end to orig start. Useful for "Swell FX"
  
  --sample lenght--
  overrideApplyFxTail = 0 -- set 1 to override "Tail length when using Apply FX to items" value (Preferences > Media)
  applyFxTail = 0 -- value used to temporary override Apply Fx tail length when overrideApplyFxTai l = 1
  useFullSample = 0 -- set 1 to include apply fx tail in resampled item. Affects both item in arrange and sampler
  
  --source--
  selectedNotesOnly = 1 -- set 1 to solo selected notes before render. Other value to use all notes within time selection.
  ignoreTimeSelection = 0 --set 1 to not use original time selection to set copy midi/render section. Otherwise section auto set to selected notes if selectedNotesOnly enabled and to all notes if selectedNotesOnly is disabled
  
  --post-processing--
  muteOrigNotes = 0 --1 to mute orig notes
  bypassOrigFx = 0 --set 1 to bypass all fx on orig track beafore rs5k
  
  preRenderAction = 1 -- run any action/script before rendering MIDI copy. Here selected item is a copy of selected notes from original item placed on original track.
                     --0 - no action, 
                     --1 - main section, 2 - midi editor section
  preRenderActionID = '_RSbf34ecd31fd45b6da47b33e43f1163b290054f9d' -- pre-render action id. Place inside ''. For example: '40515' or '_SWS_ITEMCUSTCOL1' or ''
  
  postRenderAction = 1 -- run any action/script after rendering MIDI copy, before loading to sampler. Here selected item is rendered (audio) item placed on original track or new track if useNewTrack = 1
                     --0 - no action, 
                     --1 - main section, 2 - midi editor section
  postRenderActionID = '40515' -- post-render action id. Place inside ''. For example: '40515' or '_SWS_ITEMCUSTCOL1' or ''
  
  postProcAction = 1 -- run any action/script after this script.
                     --0 - no action, 
                     --1 - main section, 2 - midi editor section
  postProcActionID = '_RSef79b5e542b53b347cfd37f660305fa33bbc69ae' -- post-action id. Place inside ''. For example: '40515' or '_SWS_ITEMCUSTCOL1' or ''
  
  --[USER SETTINGS END]-------------------------------



if wasRunToGetPresetFromGUI then return end --exit after loading user settings if was run to get preset

--RUN MAIN SCRIPT-----------------------
local dir = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")
local goback = "..\\"
local mainScript = "Resample Notes Main.lua"
externalRun = 'preset script'

dofile(dir..goback..mainScript)
  

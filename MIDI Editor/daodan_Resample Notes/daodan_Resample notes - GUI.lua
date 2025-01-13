if not reaper.ImGui_GetBuiltinPath then
  return reaper.MB('ReaImGui is not installed or too old.', 'Resample notes GUI', 0)
end

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9.3'
local ctx = ImGui.CreateContext('Resample notes GUI')

local runButColI = 0
local mainScript = "daodan_Resample notes.lua"
local GUIPrefsFile = "Resample notes - GUI [prefs].lua"
local dir = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")

local presetsFolder = "Resample Notes Presets"
newPresetNameDef = 'new preset - no name.lua'
newPresetName = newPresetNameDef
local varsChanged = false
local openNewPresetNameDialog = false

local face = "...............................................::-=+*#%@@@%#*+-::...............................:::-\n::.....................................::--=++**#####%%###%%@@@#*=:.............................:::-\n::.................................::::-+#%%@@@@@@@@@@@@@@@@@@@@@@@*-:..........................:::-\n.................................:.:-+*##%%@@@@@@@@@@@@@@@@@@@@@@@@@@*-:........................:::-\n:...............................:=+*##%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@+:.......................:::-\n:...........................:-:-++##%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-:.....................::-=\n:........................::-+*##%%%@@@@@@@@@@@@@@@@@@@@@@@%#*******####***=:....................::-=\n:......................:::=#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#*********#*###*=:...................::-=\n:....................::::+@@@@@@@@@@@@@@@@@@@@#####@@@@@@@@@@@@@@@@@@@@@@@@%+:..................::-=\n:::.................:.:-*@@@@@@@@@@@@%*+++**++=---=+*%@@@@@@@@@@@@@@@@@@@@@@@+:.................::-+\n:::..................::+@%@@@@@@@@@*=-::::::::::::--=+*%@@@@@@@@@@@@@@@@@@@@@@+:.................:-+\n:....................:-#%@@@@@@@@%+-:::::::::::::::--=+*%@@@@@@@@@@@@@@@@@@@@@%+:...............::-*\n::..................:-=@@@@@@@@@@+-:::::::::::::::::--=+#@@@@@@@@@@@@@@@@@@@@@@@=:..............::-#\n::.:................:-*%@@@@@@@@*=-::::::::::::::::::--+*%@@@@@@@@@@@@@@@@@@@@@@@-..............::=%\n:::.................:-%@@@@@@@@%+-:::::::::::::::::::--=*%@@@@@@@@@@@@@@@@@@@@@@@%-.............::=@\n:::.:...............:-%%@@@@@@@#=-::::::::::::::::::---=*%@@@@@@@@@@@@@@@@@@@@@@@@+:............:-+@\n::::::..............:-+@@@@@@@@*=-::::::::::::::::::---=+#@@@@@@@@@@@@@@@@@@@@@@@@*-:...........:-+@\n::::::..............::-*@@@@@@@*=::::::::::::::::::::--=+*@@@@@@@@@@@@@@@@@@@@@@@@%-:...........:-*@\n::::::................:-+@@@@@@*-::::::::::::::::::::--==*@@@@@@@@@@@@@@@@@@@@@@@@@+:...........:-#@\n::::::.................:-=#@@@@*=::::::::::::::::::::--=+*%@@@@@@@@@@@@@@@@@@@@@@@@@=...........:-%@\n:::::::.................::-+@@@%=--:::::::::::::::::--=+*%@@@@@@@@@@@@@@@@@@@@@@@@@@@:..........:-@@\n:::::::::.................:-%@@@#++++=-::::::::::-=+*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@..........:=@@\n::::.:::...................:=@@@%==+===++=------=*%%@@##%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.........:=@@\n:::::::.....................:+%@@--=--*@@+=-::-=#@@%#=+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:........:*@@\n::::::......................-:@%*-::--:-==-:::-+%#*===-=*##@@@@@@@@@@@@@@@@@@@@@@@@@@@%:........:%@@\n:::::::::....................%=*--:::------:::-+##*+====+*##**%%@@@@@@@@@@@@@@@@@@@@@@%-........:@@@\n::::::::::..................::-=.:::::::::::::-=##+===========+##@@@@@@@@@@@@@@@@@@@@@+:........:@@@\n::::::::::..................:.:=.:::::::::::::-+##*==--------==+#@@@@@@@@@@@@@@@@@@@@@=:........-@@@\n::::::::::.................:..:-:.::::::::::::-+##*+=--------==*#@@@@@@@@@@@@@@@@@@@@*-:........-@@@\n::::::::::....................:.:.=::::::--:::-+##%%+-------==*#%@@@@@@@@@@@@@@@@*@@@=::........+@@@\n:::::::::::.....................--==:::---::::-=+**#%%=----==+*%@@@@@@@@@@@@@@@@=+@@*:::........*%%%\n:::::::::::......................==@:----:::::-=++*%%%%+====+*#%@@@@@@@@@@@%@@@+:-#==:::........=-==\n:::::::::::......................::@*::----:::-+%@@@@%#+=====+##@@@@@@@@@@@*=---::-::...........::::\n:::::::::::.........................@*:------==+#%%#*+++++===+%@@@@@@@@@@@@*::.:.:..:.............::\n::::::::::::.........................:-:-:::---=+++*+======-=#@@@@@@@@@@@@@%=-:::...................\n::::::::::::.........................:=@=-::::-----==-=-==+*%@@@@@@@@@@@@@@@@#=-::................::\n:::::::::::::.......................:*@@@=::::-++===----=+#@@@@@@@@@@@@@@@@@@@@*=-::::::::::::::::::\n:::::::::::::............::::::---=+%@@@@%=------=======+#@@@@@@@@@@@@@@@@@@@@@@@%++==--------------\n::::::::::::::....:::::--=*#%%@@@@@@@@@@@@%+========++*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*******++++===\n::::::::::::::::::--=*%%%@@@@@@@@@@@@@@@@@@*++++**+*##%@%###%%###%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##\n::::::::::::::::--+#@@@@@@@@@@@@@@@@@@@@@@@#=-:::------==========+*#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n::::::::::::::--=*@@@@@@@@@@@@@@@@@@@@@@@@@%=-:::::::-----------==+*##%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@\n::::::::::--==+*@@@@@@@@@@@@@@@@@@@@@@@@@@@@+--:::::::--::::::---==+******#@@@@@@@@@@@@@@@@@@@@@@@@@\n:::::::--=+*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=-::::::::------------==++++*@@@@@@@@@@@@@@@@@@@@@@@@@@\n:::::--=+*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*=:::::::::::::::------====+%@@@@@@@@@@@@@@@@@@@@@@@@@@\n::::--=*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=-:::::::::::::::------=+#@@@@@@@@@@@@@@@@@@@@@@@@@@@\n::::-=*@@%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+-::::::::::::::::----+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n:::::-+**+++*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*=-::::::::::::::---+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n:::::-=++====+*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*=-:::::::::::::-#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n------=**+==++*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=--::::::::=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n=====++*###**#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*=---=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n==**##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

local settingsDescriptions_T = {
  --output--
  settingDescript_loadToSampler = "set 1 to load to rs5k, 0 to keep in arrange. \nset 2 for both (load to rs5k and keep in arrange).\n-1 to disable rendering (midi notes will still be copied)",
  settingDescript_samplerPreset = "set to 'Preset name' to load 'Preset name' preset in rs5k before setting root note and loading new sample",
  settingDescript_useNewTrack = "set 1 to insert rs5k/rendered audio to new track",
  settingDescript_keepTakes = "1 to keep copied midi and rendered audio (before and after reverse) in takes in new item. Makes sense only when sample is keeped in arrange (only final take loaded to sampler)",
  
  --root note--
  settingDescript_insertRootNote = "set 1 to insert root note in MIDI item when sample loaded in rs5k",
  settingDescript_useOrigItemToInserRootNote = "1 to insert root note in original midi item. Auto disabled when useNewTrack = 1 (because there is no point in inserting root note at orig track midi when rs5k is on another)",
  settingDescript_disableAutoCorrectOverlap = "1 to disable Automatically correct overlapping notes option. Used (only) when root note inserted in orig item to prevent deletion of notes",
  settingDescript_getRootNoteMode = "how to get root note. 0 - lowest note, 1 - user input, 2 - fixed (fixedRootNote)",
  settingDescript_fixedRootNote = "value used when root note fixed or when no slected notes in user input mode",
  settingDescript_midiChannel = "midi channel for inserted root note and rs5k. If set to 0 then all channels used in rs5k and ch1 used for inserted note",
  
  --reverse fun--
  settingDescript_reverseNotes = "set 1 to reverse notes before rendering to audio",
  settingDescript_reverseSample = "set 1 to reverse sample before loading to rs5k. 'Item: Reverse items to new take' action used",
  settingDescript_shiftReversedSampleLeft = "set to 1 to move item/note left to align reversed sample end to orig start. Useful for 'Swell FX'",
  
  --sample lenght--
  settingDescript_overrideApplyFxTail = "set 1 to override 'Tail length when using Apply FX to items' value (Preferences > Media)",
  settingDescript_applyFxTail = "value used to temporary override Apply FX tail length when overrideApplyFxTai l = 1",
  settingDescript_useFullSample = "set 1 to include apply fx tail in resampled item. Affects both item in arrange and sampler.\nwhen cropped you can still extent it later, the actual audio is preserved",
  
  --source--
  settingDescript_selectedNotesOnly = "set 1 to solo selected notes before render. Other value to use all notes within time selection.",
  settingDescript_ignoreTimeSelection = "set 1 to not use original time selection to set copy midi/render section. Section will be auto set to selected notes if selectedNotesOnly enabled and to all notes if selectedNotesOnly is disabled",
  
  --post-processing--
  settingDescript_muteOrigNotes = "1 to mute orig notes",
  settingDescript_bypassOrigFx = "set 1 to bypass all fx on orig track beafore rs5k",
  
  settingDescript_preRenderAction = "run any action/script before rendering MIDI copy.\nHere selected item is a copy of selected notes from original item placed on original track.\n\n0 - no action\n1 - main section, 2 - midi editor section",
  settingDescript_preRenderActionID = " pre-render action id",
  
  settingDescript_postRenderAction = "run any action/script after rendering MIDI copy, before loading to sampler.\nHere selected item is rendered (audio) item placed on original track or new track if useNewTrack = 1\n\n0 - no action\n1 - main section, 2 - midi editor section",
  settingDescript_postRenderActionID = " post-render action id",
  
  settingDescript_postProcAction = "run any action/script after this script\n\n0 - no action\n1 - main section, 2 - midi editor section",
  settingDescript_postProcActionID = "post action id",
}

function get_dir_files(dir_path)
  local files = {}
  local i = 0
  while true do
      local file_name = reaper.EnumerateFiles(dir_path, i)
      if not file_name then break end
      --local file_path = dir_path ..file_name
      local file_path = file_name
      table.insert(files, file_path)
      i = i + 1
  end
  return files
end

function getDefaultSettingsFromMain()
  
  externalRun = nil
  wasRunToGetPresetFromGUI=true
  
  --check if GUIPrefsFile exist. load prefs if so
  local checkMainFile = io.open( dir..mainScript, "r" )
  if checkMainFile then
    --> File Found. dofile
    io.close(checkMainFile)
    dofile(dir..mainScript)
    return 1
  else
    reaper.ShowMessageBox('The main script ['..mainScript..'] not found.\nPlease, place it here: '..dir,'Resample notes GUI',0)
    return
  end
end

function getPresets()
  presetsList = get_dir_files(dir..presetsFolder)
end

function setGUIprefs()
  --check if GUIPrefsFile exist. load prefs if so
  local fh = io.open( dir..GUIPrefsFile, "r" )
  if fh then
    --> File Found. dofile
    io.close(fh)
    dofile(dir..GUIPrefsFile)
  end

  --load default GUI prefs if
  --not specified in [prefs] file                  defaults
      if closeOnRun    == nil then    closeOnRun = false --
  end if topmost       == nil then       topmost = true  --
  end if defaultPreset == nil then defaultPreset = nil   --
  end if helpMarks     == nil then     helpMarks = true  -----------------
  end if open_prepost_actions == nil then  open_prepost_actions = false --
--end if dump5         == nil then         dump3 = false -----------------
      end                                                --
  ---------------------------------------------------------
end

function run()
  --RUN MAIN SCRIPT-----------------------
  
  wasRunToGetPresetFromGUI = false
  externalRun = 'GUI'
  dofile(dir..mainScript)
end

function HelpMarker(desc)
  if helpMarks == true then
    ImGui.SameLine(ctx)
    ImGui.TextDisabled(ctx, '(?)')
  end
  if ImGui.BeginItemTooltip(ctx) then
    ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 35.0)
    ImGui.Text(ctx, desc)
    ImGui.PopTextWrapPos(ctx)
    ImGui.EndTooltip(ctx)
  end
end

function ToolTip(desc)
  if ImGui.BeginItemTooltip(ctx) then
    ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 35.0)
    ImGui.Text(ctx, desc)
    ImGui.PopTextWrapPos(ctx)
    ImGui.EndTooltip(ctx)
  end
end

function HSV(h, s, v, a)
  local r, g, b = ImGui.ColorConvertHSVtoRGB(h, s, v)
  return ImGui.ColorConvertDouble4ToU32(r, g, b, a or 1.0)
end

function applyMousewheel(value, min, max, speed)
  local wheel, hwheel = ImGui.GetMouseWheel(ctx)
  local ctrl = reaper.ImGui_GetKeyMods(ctx) & reaper.ImGui_Mod_Ctrl() ~= 0
  if wheel ~= 0 then
    local oldval = value
    if not value then value = 0 end --for items that can be nil, preset box for example
    if ctrl and speed then speed = speed*0.5 end --apply ctrl modifier only if speed was specified (curently used only for overr tail lenght)
    if not speed then speed = 1 end --default speed
    value = value + math.ceil(wheel * speed)
    local valCalc = math.max(min, math.min(value, max))
    if oldval ~= valCalc then varsChanged = true end --if value changed
    return valCalc
  end
 
  if reaper.ImGui_IsItemEdited(ctx) then varsChanged = true end
  return value
end

local LookDisPopCount = 0
function LooksDisabled(begend) -- 1 - begin, 0 - end
 
  frameBgColor = ImGui.GetColor( ctx, ImGui.Col_FrameBg, alpha_mulIn )
  disabledTextColor = ImGui.GetColor( ctx, ImGui.Col_TextDisabled, alpha_mulIn )
  if begend > 0 then
    LookDisPopCount = 0
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, frameBgColor) LookDisPopCount=LookDisPopCount+1
    ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab,  frameBgColor) LookDisPopCount=LookDisPopCount+1
    ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive,  frameBgColor) LookDisPopCount=LookDisPopCount+1
    ImGui.PushStyleColor(ctx, ImGui.Col_Text,  disabledTextColor) LookDisPopCount=LookDisPopCount+1
  else
    ImGui.PopStyleColor(ctx, LookDisPopCount)
  end
end

function writeGUIPrefsFile()
  --write GUI settings
  if defaultPreset ~= nil then
    defaultPresetStr = "'"..defaultPreset.."'"
  else
    defaultPresetStr = "nil"
  end
  local settingsString = 
          "closeOnRun = "..tostring(closeOnRun)
..'\n'..  "topmost = "..tostring(topmost)
..'\n'..  "defaultPreset = "..defaultPresetStr
..'\n'..  "helpMarks = "..tostring(helpMarks)
..'\n'..  "open_prepost_actions = "..tostring(open_prepost_actions)
--..'\n'..  "dump5 = "..tostring(dump5)
  
  local file = assert(io.open(dir..GUIPrefsFile, 'w'))
  file:write(settingsString)
  file:close()
  
end

function writePresetToFile()
  --write current settings to preset
  
  presetFileStringCode = ([[
--Resample Notes - render selected MIDI notes, load sample to ReaSamplOmatic5000

--Midi Editor script to automatically copy selected notes to new item, apply fx, 
--load sample to sampler, set root note in sampler, remove new item, mute origally selected notes in original item
--and insert root note in the corresponding possition. 
--Basically. There are several options here so you can change the behavior to suit your needs. See [USER SETTINGS] section below.

--This is a preset script. Can run main script (daodan_Resample notes.lua) with [USER SETTINGS]. 
--Can be used to load preset from GUI script.

--Please keep list of variables in user setting section same as in main script 
--and keep this script in "Resample Notes Presets" folder and keep "Resample Notes Presets" folder in the same folder with the main script.
--Have fun!

  --[USER SETTINGS]-----------------------------------
  
  --output--
  loadToSampler = %q --set 1 to load to rs5k, 0 to keep in arrange. set 2 for both (load to rs5k and keep in arrange). -1 to disable rendering (midi notes will still be copied)
  samplerPreset = '%s' -- Set to 'Preset name' to load 'Preset name' preset in rs5k before setting root note and loading new sample. Keep as '' to load defaul preset
  useNewTrack = %q -- set 1 to insert rs5k/rendered audio to new track
  keepTakes = %q --1 to keep copied midi and rendered audio (before and after reverse) in takes in new item. Makes sense only when sample is keeped in arrange (only final take loaded to sampler)
  
  --root note--
  insertRootNote = %q --set 1 to insert root note in MIDI item when sample loaded in rs5k
  useOrigItemToInserRootNote = %q --1 to insert root note in original midi item. Auto disabled when useNewTrack = 1 (because there is no point in inserting root note at orig track midi when rs5k is on another)
  disableAutoCorrectOverlap = %q --1 to disable Automatically correct overlapping notes option. Used (only) when root note inserted in orig item to prevent deletion of notes
  getRootNoteMode = %q --how to get root note. 0 - lowest note, 1 - user input, 2 - fixed (fixedRootNote) 
  fixedRootNote = %q --value used when root note fixed or when no slected notes in user input mode
  midiChannel = %q --midi channel for inserted root note and rs5k. If set to 0 then all channels used in rs5k and ch1 used for inserted note
  
  --reverse fun--
  reverseNotes = %q -- set 1 to reverse notes before rendering to audio
  reverseSample = %q --set 1 to reverse sample before loading to rs5k. "Item: Reverse items to new take" action used
  shiftReversedSampleLeft = %q --set to 1 to move item/note left to align reversed sample end to orig start. Useful for "Swell FX"
  
  --sample lenght--
  overrideApplyFxTail = %q -- set 1 to override "Tail length when using Apply FX to items" value (Preferences > Media)
  applyFxTail = %q -- value used to temporary override Apply Fx tail length when overrideApplyFxTai l = 1
  useFullSample = %q -- set 1 to include apply fx tail in resampled item. Affects both item in arrange and sampler
  
  --source--
  selectedNotesOnly = %q -- set 1 to solo selected notes before render. Other value to use all notes within time selection.
  ignoreTimeSelection = %q --set 1 to not use original time selection to set copy midi/render section. Otherwise section auto set to selected notes if selectedNotesOnly enabled and to all notes if selectedNotesOnly is disabled
  
  --post-processing--
  muteOrigNotes = %q --1 to mute orig notes
  bypassOrigFx = %q --set 1 to bypass all fx on orig track beafore rs5k
  
  preRenderAction = %q -- run any action/script before rendering MIDI copy. Here selected item is a copy of selected notes from original item placed on original track.
                     --0 - no action, 
                     --1 - main section, 2 - midi editor section
  preRenderActionID = '%s' -- pre-render action id. Place inside ''. For example: '40515' or '_SWS_ITEMCUSTCOL1' or ''
  
  postRenderAction = %q -- run any action/script after rendering MIDI copy, before loading to sampler. Here selected item is rendered (audio) item placed on original track or new track if useNewTrack = 1
                     --0 - no action, 
                     --1 - main section, 2 - midi editor section
  postRenderActionID = '%s' -- post-render action id. Place inside ''. For example: '40515' or '_SWS_ITEMCUSTCOL1' or ''
  
  postProcAction = %q -- run any action/script after this script.
                     --0 - no action, 
                     --1 - main section, 2 - midi editor section
  postProcActionID = '%s' -- post-action id. Place inside ''. For example: '40515' or '_SWS_ITEMCUSTCOL1' or ''
  
  --[USER SETTINGS END]-------------------------------



if wasRunToGetPresetFromGUI then return end --exit after loading user settings if was run to get preset

--RUN MAIN SCRIPT-----------------------
local dir = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")
local goback = "..\\"
local mainScript = "daodan_Resample notes.lua"
externalRun = 'preset script'

dofile(dir..goback..mainScript)
  ]]):format(loadToSampler,samplerPreset,useNewTrack,
  keepTakes,insertRootNote,useOrigItemToInserRootNote,
  disableAutoCorrectOverlap,getRootNoteMode,fixedRootNote,
  midiChannel,reverseNotes,reverseSample,shiftReversedSampleLeft,
  overrideApplyFxTail,applyFxTail,useFullSample,selectedNotesOnly,
  ignoreTimeSelection,muteOrigNotes,bypassOrigFx,
  preRenderAction,preRenderActionID,
  postRenderAction,postRenderActionID,
  postProcAction,postProcActionID)
  
  --write settings to preset script
  local fullNewPrestPath = dir..presetsFolder..'\\'..newPresetName
  
  local file = assert(io.open(fullNewPrestPath, 'w'))
  file:write(presetFileStringCode)
  file:close()
  
  --update presets and presets combo
  getPresets()
  for i=1, #presetsList do
    if newPresetName == presetsList[i] then
      current_item_preset = i --set presets combo current item to new preset name
    end
  end
  
  varsChanged = false
  
end

function SetAsDefaultPreset()
  if current_item_preset then
    if current_item_preset > 0 then
      defaultPreset=presetsList[current_item_preset]
    else
      defaultPreset=nil
    end
  else
    defaultPreset=nil
  end
end

function onClose()
  writeGUIPrefsFile()
end

function SplitFilename(strFilename)
  -- Returns the Path, Filename, and Extension as 3 values
  return string.match(strFilename, "(.-)([^\\]-([^\\%.]+))$")
end

local function Init()
  prefsApplyFxTail = reaper.SNM_GetIntConfigVar('applyfxtail',1)--get value from reaper preferences>media>tail length when using apply fx to items
  setGUIprefs()
  if not getDefaultSettingsFromMain() then return end
  getPresets()
  --load default preset if any
  if defaultPreset ~= nil then 
    for i=1, #presetsList do
      if string.find(presetsList[i], defaultPreset, 1, true) then --find default preset in presets list
        current_item_preset = i
        local presetLoad = presetsList[current_item_preset]
        wasRunToGetPresetFromGUI=true
        dofile(dir..presetsFolder..'\\'..presetLoad)
        varsChanged = false
        break
      end
    end
  end
  
  --load list of rs5k presets
  loadRS5kPresets()
  initSamplerPresetComboBox()
  return 1
end

function loadRS5kPresets()
    rs5kPresetsNames_T = {}
    local rs5kPresetFile = "\\presets\\vst-reasamplomatic.ini"
    local resourcePatch = reaper.GetResourcePath()
    local presetFile = resourcePatch..rs5kPresetFile
    local file = io.open(presetFile, "r")
    if not file then
        return  -- Could not open the file, exit the function
    end
    
    local currentPreset = nil
    for line in file:lines() do
        if line:match("^%[Preset%d+%]") then
            presetFound = true
        elseif presetFound and line:match("^Name=") then
            -- Extract the preset name
            presetName = line:match("^Name=(.+)$")
            table.insert(rs5kPresetsNames_T, presetName)
        end
    end
    
    file:close()
end

function initSamplerPresetComboBox()
  --load default preset if any
  if samplerPreset ~= nil then
    if samplerPreset == '' then
      current_item_sampler_preset = 0
    else
      for i=1, #rs5kPresetsNames_T do
        if string.find(rs5kPresetsNames_T[i], samplerPreset, 1, true) then --find preset in presets list
          current_item_sampler_preset = i
          break
        end
      end
    end
  end
end

function ActionNameFromIdToolTip(section, id)
      if section == 1 then
        local actionName = reaper.kbd_getTextFromCmd(reaper.NamedCommandLookup(id), 0)
        if actionName == '' then actionName = 'no action' end
        ToolTip(actionName)
      elseif section == 2 then
        local actionName = reaper.kbd_getTextFromCmd(reaper.NamedCommandLookup(id), 32060)
        if actionName == '' then actionName = 'no action' end
        ToolTip(actionName)
      end
end

local function myWindow()
  
  local rv
  
  --TITLE----------------------------------------------------------------------------------------------------
  
  --title right click menu---------------------------------
  if ImGui.BeginPopupContextItem(ctx) then
    rv, closeOnRun = ImGui.Checkbox(ctx, 'close on run', closeOnRun)
    rv, topmost = ImGui.Checkbox(ctx, 'always on top', topmost)
    rv, helpMarks = ImGui.Checkbox(ctx, 'help marks', helpMarks)
    if itsTime then rv, showFace = ImGui.Checkbox(ctx, 'face', showFace) end
    
    ImGui.EndPopup(ctx)
  end
  
  --RUN and PRESETS BOX -------------------------------------------------------------------------------------
  
  --set item width for preset box (and run button)
  ImGui.PushItemWidth(ctx, ImGui.GetFontSize(ctx) * -5)
  
  --RUN! button--------------------------------------------
  ImGui.PushStyleColor(ctx, ImGui.Col_Button,        HSV(runButColI / 7.0, 0.6, 0.6, 1.0))
  ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, HSV(runButColI / 7.0, 0.7, 0.7, 1.0))
  ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,  HSV(runButColI / 7.0, 0.8, 0.8, 1.0))
    if ImGui.Button(ctx, 'RUN!') then 
      run()
      runButColI = runButColI+1 
      if closeOnRun == true then shouldClose = true end
    end
  ImGui.PopStyleColor(ctx, 3)
  ImGui.SameLine(ctx)
  
  --presets combo------------------------------------------
  local combo_items = presetsList
  local changeMark = ''
  local changeMarkSymbl = '*'
  if varsChanged then changeMark = changeMarkSymbl end
  -- Pass in the preview value visible before opening the combo (it could technically be different contents or not pulled from items[])
  local combo_preview_value = combo_items[current_item_preset]
  oldValue = current_item_preset
  if ImGui.BeginCombo(ctx, 'preset'..changeMark, combo_preview_value) then
    for i,v in ipairs(combo_items) do
      local is_selected = current_item_preset == i
      if ImGui.Selectable(ctx, combo_items[i], is_selected) then
        current_item_preset = i
      end
      if ImGui.IsMouseClicked(ctx, 0) then
        oldValue=nil
      end
      -- Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
      if is_selected then
        ImGui.SetItemDefaultFocus(ctx)
      end
    end
    ImGui.EndCombo(ctx)
  end
  if varsChanged then ToolTip('preset was modified') end
  if ImGui.IsItemHovered(ctx) then current_item_preset = applyMousewheel(current_item_preset, 1, #combo_items,-1) end
  
  
  --load preset if combo item changed----------------------
  if current_item_preset~=oldValue then 
    if current_item_preset>0 then
      local presetLoad = presetsList[current_item_preset]
      
      wasRunToGetPresetFromGUI=true
      
      --check if preset file exist. load  if so
      local checkPresetFile = io.open( dir..presetsFolder..'\\'..presetLoad, "r" )
      if checkPresetFile then
        --> File Found. dofile
        io.close(checkPresetFile)
        dofile(dir..presetsFolder..'\\'..presetLoad)
        
        initSamplerPresetComboBox()
        
        varsChanged = false
      else
        reaper.ShowMessageBox('This preset is no longer available: '..dir..presetsFolder..'\\'..presetLoad,'Resample notes GUI',0)
        getPresets()
        current_item_preset = 0
        varsChanged = true
      end
    
    end
    
  end

  --right click preset box menu----------------------------
  if ImGui.BeginPopupContextItem(ctx) then
    if ImGui.Button(ctx, 'save new') then
      ImGui.CloseCurrentPopup(ctx)
      newPresetName = ''
      --newPresetName = newPresetNameDef
      openNewPresetNameDialog = true
    end
    
    if ImGui.Button(ctx, 'resave current') then
      newPresetName = presetsList[current_item_preset]
      openNewPresetNameDialog = true
      ImGui.CloseCurrentPopup(ctx)
    end
    
    if varsChanged == false then
      if ImGui.Button(ctx, 'set as default') then
        SetAsDefaultPreset()
        ImGui.CloseCurrentPopup(ctx)
      end
    end
    
    if ImGui.Button(ctx, 'open presets folder') then
      reaper.CF_ShellExecute(dir..presetsFolder)
      ImGui.CloseCurrentPopup(ctx)
    end
    
    if ImGui.Button(ctx, 'load factory defaults') then
      getDefaultSettingsFromMain()
      current_item_preset=0
      initSamplerPresetComboBox()
      varsChanged = false
      ImGui.CloseCurrentPopup(ctx)
    end
    ToolTip('from main script')
    
    ImGui.EndPopup(ctx)
  end
  
  --pop item width for preset box (and run button)
  ImGui.PopItemWidth(ctx)
  
  --SECTIONS-------------------------------------------------------------------------------------------------
  
  --set item width for other items
  ImGui.PushItemWidth(ctx, ImGui.GetFontSize(ctx) * -14)
  
  --output section-----------------------------------------------------------------------
  ImGui.SeparatorText(ctx, 'output')
  
  --loadToSampler------------------------------------------
  local elements_loadToSampler = { 'no render' ,'keep in arrange', 'load to rs5k', 'both' }
  local current_elem_loadToSampler = elements_loadToSampler[loadToSampler+2] or 'not set'
  local max_loadToSampler = (#elements_loadToSampler)-2
  rv, loadToSampler = ImGui.SliderInt(ctx, 'sampler/arrange', loadToSampler, -1, max_loadToSampler, '%d '..current_elem_loadToSampler)
  if ImGui.IsItemHovered(ctx) then loadToSampler = applyMousewheel(loadToSampler, -1, max_loadToSampler) end
  
  
  HelpMarker(settingsDescriptions_T.settingDescript_loadToSampler)

  
  --samplerPreset------------------------------------------
  
  if loadToSampler < 1 then LooksDisabled(1) end
  
  --combo box----------------------------------------------------------------
  local combo_preview_value = rs5kPresetsNames_T[current_item_sampler_preset] or 'default'
  oldValue_sampler_preset = current_item_sampler_preset
  if ImGui.BeginCombo(ctx, 'sampler preset', combo_preview_value) then
    for i,v in ipairs(rs5kPresetsNames_T) do
      local is_selected = current_item_sampler_preset == i
      if ImGui.Selectable(ctx, rs5kPresetsNames_T[i], is_selected) then
        current_item_sampler_preset = i
      end

      -- Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
      if is_selected then
        ImGui.SetItemDefaultFocus(ctx)
      end
    end
    ImGui.EndCombo(ctx)
  end

  if ImGui.IsItemHovered(ctx) then current_item_sampler_preset = applyMousewheel(current_item_sampler_preset, 1, #rs5kPresetsNames_T,-1) end

  --load preset if combo item changed----------------------
  if current_item_sampler_preset~=oldValue_sampler_preset then
    varsChanged = true
    --reaper.ClearConsole()
    --reaper.ShowConsoleMsg(current_item_preset..'\n')
    if current_item_sampler_preset>0 then
      samplerPreset = rs5kPresetsNames_T[current_item_sampler_preset]
    end
  end
  
  --right click preset box menu----------------------------
  if ImGui.BeginPopupContextItem(ctx) then
    
    if ImGui.Button(ctx, 'default preset') then
      current_item_sampler_preset = 0
      ImGui.CloseCurrentPopup(ctx)
    end
    
    if ImGui.Button(ctx, 'update list') then
      loadRS5kPresets()
      --initSamplerPresetComboBox()
      ImGui.CloseCurrentPopup(ctx)
    end
    
    ImGui.EndPopup(ctx)
  end
  
  
  ------------------------------------------------------------------------
  
  
  HelpMarker(settingsDescriptions_T.settingDescript_samplerPreset)
  if loadToSampler < 1 then LooksDisabled(0) end
  
  --useNewTrack--------------------------------------------
  local elements_useNewTrack = { 'use same track', 'use new track' }
  local current_elem_useNewTrack = elements_useNewTrack[useNewTrack+1] or 'not set'
  local max_useNewTrack = (#elements_useNewTrack)-1
  rv, useNewTrack = ImGui.SliderInt(ctx, 'track', useNewTrack, 0, max_useNewTrack, '%d '..current_elem_useNewTrack)
  if ImGui.IsItemHovered(ctx) then useNewTrack = applyMousewheel(useNewTrack, 0, max_useNewTrack) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_useNewTrack)

  --keepTakes----------------------------------------------
  local elements_keepTakes = { 'keep final take', 'keep all takes'}
  local current_elem_keepTakes = elements_keepTakes[keepTakes+1] or 'not set'
  local max_keepTakes = (#elements_keepTakes)-1
  rv, keepTakes = ImGui.SliderInt(ctx, 'keep takes', keepTakes, 0, max_keepTakes, '%d '..current_elem_keepTakes)
  if ImGui.IsItemHovered(ctx) then keepTakes = applyMousewheel(keepTakes, 0, max_keepTakes) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_keepTakes)
  
  --root note section--------------------------------------------------------------------
  if loadToSampler < 1 then LooksDisabled(1) end
  ImGui.SeparatorText(ctx, 'root note')

  --insertRootNote-----------------------------------------
  local elements_insertRootNote = { 'do not insert', 'insert'}
  local current_elem_insertRootNote = elements_insertRootNote[insertRootNote+1] or 'not set'
  local max_insertRootNote = (#elements_insertRootNote)-1
  rv, insertRootNote = ImGui.SliderInt(ctx, 'insert root note', insertRootNote, 0, max_insertRootNote, '%d '..current_elem_insertRootNote)
  if ImGui.IsItemHovered(ctx) then insertRootNote = applyMousewheel(insertRootNote, 0, max_insertRootNote) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_insertRootNote)
  
  if insertRootNote == 0 then LooksDisabled(1) end
  
  --useOrigItemToInserRootNote-----------------------------
  if useNewTrack == 1 then LooksDisabled(1) end
  local elements_useOrigItemToInserRootNote = { 'in new item', 'in orig item'}
  local current_elem_useOrigItemToInserRootNote = elements_useOrigItemToInserRootNote[useOrigItemToInserRootNote+1] or 'not set'
  local max_useOrigItemToInserRootNote = (#elements_useOrigItemToInserRootNote)-1
  rv, useOrigItemToInserRootNote = ImGui.SliderInt(ctx, 'where to insert', useOrigItemToInserRootNote, 0, max_useOrigItemToInserRootNote, '%d '..current_elem_useOrigItemToInserRootNote)
  if ImGui.IsItemHovered(ctx) then useOrigItemToInserRootNote = applyMousewheel(useOrigItemToInserRootNote, 0, max_useOrigItemToInserRootNote) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_useOrigItemToInserRootNote)
  if useNewTrack == 1 then LooksDisabled(0) end
  
  --disableAutoCorrectOverlap------------------------------
  
  if useOrigItemToInserRootNote ~= 1 then LooksDisabled(1) end
  local elements_disableAutoCorrectOverlap = { 'auto-correct notes enabled', 'auto-correct notes disabled'}
  local current_elem_disableAutoCorrectOverlap = elements_disableAutoCorrectOverlap[disableAutoCorrectOverlap+1] or 'not set'
  local max_disableAutoCorrectOverlap = (#elements_disableAutoCorrectOverlap)-1
  rv, disableAutoCorrectOverlap = ImGui.SliderInt(ctx, 'disable auto-correct', disableAutoCorrectOverlap, 0, max_disableAutoCorrectOverlap, '%d '..current_elem_disableAutoCorrectOverlap)
  if ImGui.IsItemHovered(ctx) then disableAutoCorrectOverlap = applyMousewheel(disableAutoCorrectOverlap, 0, max_disableAutoCorrectOverlap) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_disableAutoCorrectOverlap)
  if useOrigItemToInserRootNote ~= 1 then LooksDisabled(0) end
  
  --getRootNoteMode----------------------------------------
  local elements_getRootNoteMode = { 'lowest note', 'user input', 'fixed'}
  local current_elem_getRootNoteMode = elements_getRootNoteMode[getRootNoteMode+1] or 'not set'
  local max_getRootNoteMode = (#elements_getRootNoteMode)-1
  rv, getRootNoteMode = ImGui.SliderInt(ctx, 'get root note by', getRootNoteMode, 0, max_getRootNoteMode, '%d '..current_elem_getRootNoteMode)
  if ImGui.IsItemHovered(ctx) then getRootNoteMode = applyMousewheel(getRootNoteMode, 0, max_getRootNoteMode) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_getRootNoteMode)
  
  --fixedRootNote------------------------------------------
  if getRootNoteMode == 0 then LooksDisabled(1) end
  local max_fixedRootNote = 127
  rv, fixedRootNote = ImGui.InputInt(ctx, 'fixed root note', fixedRootNote)
  if ImGui.IsItemHovered(ctx) then fixedRootNote = applyMousewheel(fixedRootNote, 0, max_fixedRootNote) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_fixedRootNote)
  if getRootNoteMode == 0 then LooksDisabled(0) end
  --midiChannel--------------------------------------------
  local max_midiChannel = 16
  rv, midiChannel = ImGui.InputInt(ctx, 'midi channel', midiChannel)
  if ImGui.IsItemHovered(ctx) then midiChannel = applyMousewheel(midiChannel, 0, max_midiChannel) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_midiChannel)
  
  if insertRootNote == 0 then LooksDisabled(0) end
  if loadToSampler < 1 then LooksDisabled(0) end
  
  --reverse fun section------------------------------------------------------------------
  ImGui.SeparatorText(ctx, 'reverse fun')
  
  --reverseNotes-------------------------------------------
  local elements_reverseNotes = { 'do not reverse', 'reverse notes'}
  local current_elem_reverseNotes = elements_reverseNotes[reverseNotes+1] or 'not set'
  local max_reverseNotes = (#elements_reverseNotes)-1
  rv, reverseNotes = ImGui.SliderInt(ctx, 'reverse notes', reverseNotes, 0, max_reverseNotes, '%d '..current_elem_reverseNotes)
  if ImGui.IsItemHovered(ctx) then reverseNotes = applyMousewheel(reverseNotes, 0, max_reverseNotes) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_reverseNotes)
  
  if loadToSampler < 0 then LooksDisabled(1) end
  
  --reverseSample------------------------------------------
  local elements_reverseSample = { 'do not reverse', 'reverse sample'}
  local current_elem_reverseSample = elements_reverseSample[reverseSample+1] or 'not set'
  local max_reverseSample = (#elements_reverseSample)-1
  rv, reverseSample = ImGui.SliderInt(ctx, 'reverse sample', reverseSample, 0, max_reverseSample, '%d '..current_elem_reverseSample)
  if ImGui.IsItemHovered(ctx) then reverseSample = applyMousewheel(reverseSample, 0, max_reverseSample) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_reverseSample)
  
  --shiftReversedSampleLeft--------------------------------
  if reverseSample == 0 then LooksDisabled(1) end
  local elements_shiftReversedSampleLeft = { 'do not touch.', 'shift left'}
  local current_elem_shiftReversedSampleLeft = elements_shiftReversedSampleLeft[shiftReversedSampleLeft+1] or 'not set'
  local max_shiftReversedSampleLeft = (#elements_shiftReversedSampleLeft)-1
  rv, shiftReversedSampleLeft = ImGui.SliderInt(ctx, 'shift reversed left', shiftReversedSampleLeft, 0, max_shiftReversedSampleLeft, '%d '..current_elem_shiftReversedSampleLeft)
  if ImGui.IsItemHovered(ctx) then shiftReversedSampleLeft = applyMousewheel(shiftReversedSampleLeft, 0, max_shiftReversedSampleLeft) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_shiftReversedSampleLeft)
  if reverseSample == 0 then LooksDisabled(0) end
  
  --sample lenght section----------------------------------------------------------------
  ImGui.SeparatorText(ctx, 'sample lenght')
  
  --overrideApplyFxTail------------------------------------
  local elements_overrideApplyFxTail = { 'prefs tail ('..prefsApplyFxTail..' ms)', 'override tail'}
  local current_elem_overrideApplyFxTail = elements_overrideApplyFxTail[overrideApplyFxTail+1] or 'not set'
  local max_overrideApplyFxTail = (#elements_overrideApplyFxTail)-1
  rv, overrideApplyFxTail = ImGui.SliderInt(ctx, 'override apply fx tail', overrideApplyFxTail, 0, max_overrideApplyFxTail, '%d '..current_elem_overrideApplyFxTail)
  if ImGui.IsItemHovered(ctx) then overrideApplyFxTail = applyMousewheel(overrideApplyFxTail, 0, max_overrideApplyFxTail) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_overrideApplyFxTail)
  
  --applyFxTail--------------------------------------------
  if overrideApplyFxTail == 0 then LooksDisabled(1) end
  local max_applyFxTail = 10000
  rv,applyFxTail = ImGui.DragInt     (ctx, 'overrided tail length', applyFxTail, 3,         0   , max_applyFxTail,'%d ms')
  if ImGui.IsItemHovered(ctx) then applyFxTail = applyMousewheel(applyFxTail, 0, max_applyFxTail, 100) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_applyFxTail)
  if overrideApplyFxTail == 0 then LooksDisabled(0) end
  
  --useFullSample------------------------------------------
  local elements_useFullSample = { 'use cropped', 'use full'}
  local current_elem_useFullSample = elements_useFullSample[useFullSample+1] or 'not set'
  local max_useFullSample = (#elements_useFullSample)-1
  rv, useFullSample = ImGui.SliderInt(ctx, 'use full sample', useFullSample, 0, max_useFullSample, '%d '..current_elem_useFullSample)
  if ImGui.IsItemHovered(ctx) then useFullSample = applyMousewheel(useFullSample, 0, max_useFullSample) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_useFullSample)
  
  if loadToSampler < 0 then LooksDisabled(0) end
  
  --source section---------------------------------------------------------------
  ImGui.SeparatorText(ctx, 'source')
  
  --selectedNotesOnly--------------------------------------
  local elements_selectedNotesOnly = { 'notes inside time selection', 'selected notes only'}
  local current_elem_selectedNotesOnly = elements_selectedNotesOnly[selectedNotesOnly+1] or 'not set'
  local max_selectedNotesOnly = (#elements_selectedNotesOnly)-1
  rv, selectedNotesOnly = ImGui.SliderInt(ctx, 'selected notes only', selectedNotesOnly, 0, max_selectedNotesOnly, '%d '..current_elem_selectedNotesOnly)
  if ImGui.IsItemHovered(ctx) then selectedNotesOnly = applyMousewheel(selectedNotesOnly, 0, max_selectedNotesOnly) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_selectedNotesOnly)
  
  --ignoreTimeSelection------------------------------------
  local elements_ignoreTimeSelection = { 'use time selection', 'ignore time selection'}
  local current_elem_ignoreTimeSelection = elements_ignoreTimeSelection[ignoreTimeSelection+1] or 'not set'
  local max_ignoreTimeSelection = (#elements_ignoreTimeSelection)-1
  rv, ignoreTimeSelection = ImGui.SliderInt(ctx, 'ignore time selection', ignoreTimeSelection, 0, max_ignoreTimeSelection, '%d '..current_elem_ignoreTimeSelection)
  if ImGui.IsItemHovered(ctx) then ignoreTimeSelection = applyMousewheel(ignoreTimeSelection, 0, max_ignoreTimeSelection) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_ignoreTimeSelection)
  
  --post-processing section--------------------------------------------------------------
  ImGui.SeparatorText(ctx, 'mute/bypass orig')
  
  --muteOrigNotes------------------------------------------
  local elements_muteOrigNotes = { 'do not touch notes', 'mute notes'}
  local current_elem_muteOrigNotes = elements_muteOrigNotes[muteOrigNotes+1] or 'not set'
  local max_muteOrigNotes = (#elements_muteOrigNotes)-1
  rv, muteOrigNotes = ImGui.SliderInt(ctx, 'mute orig notes', muteOrigNotes, 0, max_muteOrigNotes, '%d '..current_elem_muteOrigNotes)
  if ImGui.IsItemHovered(ctx) then muteOrigNotes = applyMousewheel(muteOrigNotes, 0, max_muteOrigNotes) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_muteOrigNotes)
  
  --bypassOrigFx-------------------------------------------
  local elements_bypassOrigFx = { 'do not touch fxs', 'bypass fxs'}
  local current_elem_bypassOrigFx = elements_bypassOrigFx[bypassOrigFx+1] or 'not set'
  local max_bypassOrigFx = (#elements_bypassOrigFx)-1
  rv, bypassOrigFx = ImGui.SliderInt(ctx, 'bypass orig fx', bypassOrigFx, 0, max_bypassOrigFx, '%d '..current_elem_bypassOrigFx)
  if ImGui.IsItemHovered(ctx) then bypassOrigFx = applyMousewheel(bypassOrigFx, 0, max_bypassOrigFx) end
  
  HelpMarker(settingsDescriptions_T.settingDescript_bypassOrigFx)
  
  ImGui.SetNextItemOpen(ctx, open_prepost_actions, ImGui.Cond_Once)
  open_prepost_actions = ImGui.CollapsingHeader(ctx, 'pre/post-render actions')
  if open_prepost_actions then
    
    ImGui.SeparatorText(ctx, 'pre-render (MIDI)')

      --preRenderAction-----------------------------------------
      local elements_preRenderAction = { 'no action', 'main section', 'midi editor section'}
      local current_elem_preRenderAction = elements_preRenderAction[preRenderAction+1] or 'not set'
      local max_preRenderAction = (#elements_preRenderAction)-1
      rv, preRenderAction = ImGui.SliderInt(ctx, 'pre-render action', preRenderAction, 0, max_preRenderAction, '%d '..current_elem_preRenderAction)
      if ImGui.IsItemHovered(ctx) then preRenderAction = applyMousewheel(preRenderAction, 0, max_preRenderAction) end
      
      HelpMarker(settingsDescriptions_T.settingDescript_preRenderAction)
      
      --preRenderActionID---------------------------------------
      if preRenderAction == 0 then LooksDisabled(1) end
      
      rv, preRenderActionID = ImGui.InputTextWithHint(ctx, 'pre-render action ID', 'action/script id', preRenderActionID)
      if ImGui.IsItemDeactivatedAfterEdit( ctx ) then varsChanged = true end
      
      --tooltip with action name
      ActionNameFromIdToolTip(preRenderAction,preRenderActionID)
      
      if preRenderAction == 0 then LooksDisabled(0) end
      
      --right click action preRenderActionID menu----------------------------
      if ImGui.BeginPopupContextItem(ctx) then
        
        if ImGui.Button(ctx, 'paste') then
          preRenderActionID = ImGui.GetClipboardText(ctx)
          ImGui.CloseCurrentPopup(ctx)
        end
        
        ImGui.EndPopup(ctx)
      end
      
    ImGui.SeparatorText(ctx, 'post-render (before loading to sampler)')

      --postRenderAction-----------------------------------------
      local elements_postRenderAction = { 'no action', 'main section', 'midi editor section'}
      local current_elem_postRenderAction = elements_postRenderAction[postRenderAction+1] or 'not set'
      local max_postRenderAction = (#elements_postRenderAction)-1
      rv, postRenderAction = ImGui.SliderInt(ctx, 'post-render action', postRenderAction, 0, max_postRenderAction, '%d '..current_elem_postRenderAction)
      if ImGui.IsItemHovered(ctx) then postRenderAction = applyMousewheel(postRenderAction, 0, max_postRenderAction) end
      
      HelpMarker(settingsDescriptions_T.settingDescript_postRenderAction)
      
      --postRenderActionID---------------------------------------
      if postRenderAction == 0 then LooksDisabled(1) end

      rv, postRenderActionID = ImGui.InputTextWithHint(ctx, 'post-render action ID', 'action/script id', postRenderActionID)
      if ImGui.IsItemDeactivatedAfterEdit( ctx ) then varsChanged = true end
      
      --tooltip with action name
      ActionNameFromIdToolTip(postRenderAction,postRenderActionID)
      
      if postRenderAction == 0 then LooksDisabled(0) end
      
      --right click action postRenderActionID menu----------------------------
      if ImGui.BeginPopupContextItem(ctx) then
        
        if ImGui.Button(ctx, 'paste') then
          postRenderActionID = ImGui.GetClipboardText(ctx)
          ImGui.CloseCurrentPopup(ctx)
        end
        
        ImGui.EndPopup(ctx)
      end
      
    ImGui.SeparatorText(ctx, 'post process')
    
      --postProcAction-----------------------------------------
      local elements_postProcAction = { 'no action', 'main section', 'midi editor section'}
      local current_elem_postProcAction = elements_postProcAction[postProcAction+1] or 'not set'
      local max_postProcAction = (#elements_postProcAction)-1
      rv, postProcAction = ImGui.SliderInt(ctx, 'post-process action', postProcAction, 0, max_postProcAction, '%d '..current_elem_postProcAction)
      if ImGui.IsItemHovered(ctx) then postProcAction = applyMousewheel(postProcAction, 0, max_postProcAction) end
      
      HelpMarker(settingsDescriptions_T.settingDescript_postProcAction)
      
      --postProcActionID---------------------------------------
      if postProcAction == 0 then LooksDisabled(1) end

      rv, postProcActionID = ImGui.InputTextWithHint(ctx, 'post-process action ID', 'action/script id', postProcActionID)
      if ImGui.IsItemDeactivatedAfterEdit( ctx ) then varsChanged = true end
      
      --tooltip with action name
      ActionNameFromIdToolTip(postProcAction,postProcActionID)
      
      if postProcAction == 0 then LooksDisabled(0) end
      
      --right click action postProcActionID menu----------------------------
      if ImGui.BeginPopupContextItem(ctx) then
        
        if ImGui.Button(ctx, 'paste') then
          postProcActionID = ImGui.GetClipboardText(ctx)
          ImGui.CloseCurrentPopup(ctx)
        end
        
        ImGui.EndPopup(ctx)
      end
      
  end
  
  ----------------------------------------------
  if showFace == true then ImGui.Text(ctx, face)end
  ----------------------------------------------
  
  --pop item width for other items
  ImGui.PopItemWidth(ctx)
  
  --MODAL DIALOGS--------------------------------------------------------------------------------------------
  
  --SAVE PRESET DIALOG---------------------------
  if openNewPresetNameDialog == true then ImGui.OpenPopup(ctx, 'save preset') end
  
  --save preset new file name dialog
  if ImGui.BeginPopupModal(ctx, 'save preset', nil, ImGui.WindowFlags_AlwaysAutoResize) then
    hintText_NewName = 'preset name.lua'
    
    --set keyboard focus to text input
    if ImGui.IsWindowAppearing(ctx) then
      ImGui.SetKeyboardFocusHere(ctx)
    end
    rv, newPresetName = ImGui.InputTextWithHint(ctx, 'preset name', hintText_NewName, newPresetName)
    
    if (ImGui.Button(ctx, 'OK', 120, 0) or ImGui.IsKeyPressed(ctx, ImGui.Key_Enter)) and newPresetName ~= '' then

      local _,name,extension = SplitFilename(newPresetName)
      if string.lower(extension) ~= 'lua' or string.lower(name) == 'lua' then newPresetName = newPresetName..'.lua' end
      
      writePresetToFile()
      
      openNewPresetNameDialog = false
      ImGui.CloseCurrentPopup(ctx) 
    end
    
    --cancel-----------
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Cancel', 120, 0) or ImGui.IsKeyPressed(ctx, ImGui.Key_Escape) then 
      openNewPresetNameDialog = false
      ImGui.CloseCurrentPopup(ctx) 
    end
    
    ImGui.EndPopup(ctx)
    
  end
  
end

local function loop()
  
  ImGui.SetNextWindowSize(ctx, 410, 0.0, ImGui.Cond_FirstUseEver)
  
  local window_flags = ImGui.WindowFlags_None
  --if no_titlebar       then window_flags = window_flags | ImGui.WindowFlags_NoTitleBar            end
  --if not no_menu       then window_flags = window_flags | ImGui.WindowFlags_MenuBar               end
  --if no_collapse       then window_flags = window_flags | ImGui.WindowFlags_NoCollapse            end
  if topmost           then window_flags = window_flags | ImGui.WindowFlags_TopMost               end
  if true              then window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse     end
  
  local visible, open = reaper.ImGui_Begin(ctx, 'Resample Notes', true, window_flags)
  if visible then
    myWindow()
    ImGui.End(ctx)
  end
  if open and not shouldClose then
    reaper.defer(loop)
  else
    onClose()
  end
end

if not Init() then return end
if tonumber(os.date("%H")) < 5 then itsTime = 1 end
reaper.defer(loop)

-- @description Create MIDI Morse Message Item at edit cursor position, grid length duration, first selected/last touched/ or first track
-- @author amagalma_mespotine
-- @version 1.1
-- @changelog
--   - Added: Greek and Cyrillic character support (but unfortunately do not work due to a Reaper bug)
--   - updated ReaPack info
-- @link
--   https://forum.cockos.com/showthread.php?t=245504
--   https://mespotin.uber.space/Mespotine/
-- @donation
--   https://www.paypal.me/amagalma
--   https://mespotin.uber.space/Mespotine/mespotine-unterstuetzen/


local track = reaper.GetSelectedTrack(0, 0) or (reaper.GetLastTouchedTrack() or reaper.GetTrack(0, 0))
if not track then return end
local ok, answer = reaper.GetUserInputs("Create (International) Morse Code Message", 2,
"Enter Message :,(1: Latin, 2: Greek, 3: Cyrillic) :,extrawidth=100,separator=\n", "\n1")
if not ok then return end

local valid = {["1"] = true, ["2"] = true, ["3"] = true}
local InputString, Lang = answer:match("(.+)\n([123])")
if not InputString or not valid[Lang] then return end
if Lang == "1" then InputString = InputString:upper() 
else
  reaper.MB( "Unfortunately, there is currently a bug in Reaper with Greek and Cyrillic characters.\n\z
  When the bug is fixed the script will work for these alphabets too! Sorry!!", "Error..", 0 )
  return
end

local M = {
  ["A"] = {". -", 5},
  ["B"] = {"- . . .", 9},
  ["C"] = {"- . - .", 11},
  ["D"] = {"- . .", 7},
  ["E"] = {".", 1},
  ["F"] = {". . - .", 9},
  ["G"] = {"- - .", 9},
  ["H"] = {". . . .", 7},
  ["I"] = {". .", 3},
  ["J"] = {". - - -", 13},
  ["K"] = {"- . -", 9},
  ["L"] = {". - . .", 9},
  ["M"] = {"- -", 7},
  ["N"] = {"- .", 5},
  ["O"] = {"- - -", 11},
  ["P"] = {". - - .", 11},
  ["Q"] = {"- - . -", 13},
  ["R"] = {". - .", 7},
  ["S"] = {". . .", 5},
  ["T"] = {"-", 3},
  ["U"] = {". . -", 7},
  ["V"] = {". . . -", 9},
  ["W"] = {". - -", 9},
  ["X"] = {"- . . -", 11},
  ["Y"] = {"- . - -", 13},
  ["Z"] = {"- - . .", 11},

  ["0"] = {"- - - - -", 19},
  ["1"] = {". - - - -", 17},
  ["2"] = {". . - - -", 15},
  ["3"] = {". . . - -", 13},
  ["4"] = {". . . . -", 11},
  ["5"] = {". . . . .", 9},
  ["6"] = {"- . . . .", 11},
  ["7"] = {"- - . . .", 13},
  ["8"] = {"- - - . .", 15},
  ["9"] = {"- - - - .", 17},

  ["Ä"] = {". - . -", 11},
  ["Á"] = {". - - . -", 15},
  ["À"] = {". - - . -", 15},
  ["Å"] = {". - - . -", 15},
  ["CH"] = {"- - - -", 15},
  ["È"] = {". - . . -", 13},
  ["É"] = {". . - . .", 11},
  ["Ñ"] = {"- - . - -", 17},
  ["Ö"] = {"- - - .", 13},
  ["Ü"] = {". . - -", 11},
  ["ß"] = {". . . - - . .", 17},

  [" "] = {"             ", 13},
  ["="] = {"- . . . -", 13},
  ["!"] = {"- . - . - -", 19},
  ['"'] = {". - . . - .", 15},
  ["'"] = {". - - - - .", 19},
  ["("] = {"- . - - .", 15},
  [")"] = {"- . - - . -", 19},
  ["+"] = {". - . - .", 13},
  [","] = {"- - . . - -", 19},
  ["-"] = {"- . . . . -", 15},
  ["."] = {". - . - . -", 17},
  ["/"] = {"- . . - .", 13},
  [":"] = {"- - - . . .", 17},
  [";"] = {"- . - . - .", 17},
  ["?"] = {". . - - . .", 15},
  ["@"] = {". - - . - .", 17},
  ["_"] = {". . - - . -", 17}
}

-- Greek
local G = {
  ["Α"] = M["A"],
  ["Ά"] = M["A"],
  ["α"] = M["A"],
  ["ά"] = M["A"],
  ["Β"] = M["B"],
  ["β"] = M["B"],
  ["Γ"] = M["G"],
  ["γ"] = M["G"],
  ["Δ"] = M["D"],
  ["δ"] = M["D"],
  ["Ε"] = M["E"],
  ["Έ"] = M["E"],
  ["ε"] = M["E"],
  ["έ"] = M["E"],
  ["Ζ"] = M["Z"],
  ["ζ"] = M["Z"],
  ["Ή"] = M["H"],
  ["Ή"] = M["H"],
  ["η"] = M["H"],
  ["ή"] = M["H"],
  ["Θ"] = M["C"],
  ["θ"] = M["C"],
  ["Ι"] = M["I"],
  ["Ί"] = M["I"],
  ["Ϊ"] = M["I"],
  ["ι"] = M["I"],
  ["ί"] = M["I"],
  ["ϊ"] = M["I"],
  ["Κ"] = M["K"],
  ["κ"] = M["K"],
  ["Λ"] = M["L"],
  ["λ"] = M["L"],
  ["Μ"] = M["M"],
  ["μ"] = M["M"],
  ["Ν"] = M["N"],
  ["ν"] = M["N"],
  ["Ξ"] = M["X"],
  ["ξ"] = M["X"],
  ["Ο"] = M["O"],
  ["Ό"] = M["O"],
  ["ο"] = M["O"],
  ["ό"] = M["O"],
  ["Π"] = M["P"],
  ["π"] = M["P"],
  ["Ρ"] = M["R"],
  ["ρ"] = M["R"],
  ["Σ"] = M["S"],
  ["σ"] = M["S"],
  ["ς"] = M["S"],
  ["Τ"] = M["T"],
  ["τ"] = M["T"],
  ["Υ"] = M["Y"],
  ["Ύ"] = M["Y"],
  ["Ϋ"] = M["Y"],
  ["υ"] = M["Y"],
  ["ύ"] = M["Y"],
  ["ϋ"] = M["Y"],
  ["Φ"] = M["F"],
  ["φ"] = M["F"],
  ["Χ"] = M["CH"],
  ["χ"] = M["CH"],
  ["Ψ"] = M["Q"],
  ["ψ"] = M["Q"],
  ["Ω"] = M["W"],
  ["Ώ"] = M["W"],
  ["ω"] = M["W"],
  ["ώ"] = M["W"],
  [";"] = M["?"],
}

-- Cyrillic
local C = {
  ["А"] = M["A"],
  ["Б"] = M["B"],
  ["В"] = M["W"],
  ["Г"] = M["G"],
  ["Д"] = M["D"],
  ["Е"] = M["E"],
  ["Ж"] = M["V"],
  ["З"] = M["Z"],
  ["И"] = M["I"],
  ["І"] = M["I"],
  ["Й"] = M["J"],
  ["К"] = M["K"],
  ["Л"] = M["L"],
  ["М"] = M["M"],
  ["Н"] = M["N"],
  ["О"] = M["O"],
  ["П"] = M["P"],
  ["Р"] = M["R"],
  ["С"] = M["S"],
  ["Т"] = M["T"],
  ["У"] = M["U"],
  ["Ф"] = M["F"],
  ["Х"] = M["H"],
  ["Ц"] = M["C"],
  ["Ч"] = M["Ö"],
  ["Ш"] = M["CH"],
  ["Щ"] = M["Q"],
  ["Ь"] = M["X"],
  ["Ъ"] = M["X"],
  ["Ы"] = M["Y"],
  ["Ь"] = M["Y"],
  ["Э"] = M["É"],
  ["Є"] = M["É"],
  ["Ю"] = M["Ü"],
  ["Я"] = M["Ä"],
  ["Ї"] = M["-"]
}

local Morse = Lang == "1" and M or (Lang == "2" and G or C)
local InputString_len = InputString:len()
local OutputString = ""
local i = 0
local total_str_length = 0
while true do
  i = i + 1
  local k = InputString:sub(i,i)
  if k == "C" and InputString:sub(i+1,i+1) == "H" then
    k = "CH"
    i = i + 1
  end
  if Morse[k] or M[k] then
    OutputString = OutputString .. (Morse[k][1] or M[k][1]) .. "   "
    total_str_length = total_str_length + (Morse[k][2] or M[k][2]) + 3
  else
    reaper.MB( k .. " is not a valid Morse Code character", "Invalid character!", 0 )
    return
  end
  if i == InputString_len then break end
end
OutputString = OutputString:sub(1,-4)
total_str_length = total_str_length - 3

-- Insert MIDI item at edit cursor position with Morse message

local cur_pos = reaper.GetCursorPosition()
local miditicksperbeat = tonumber(({reaper.get_config_var_string( "miditicksperbeat" )})[2])
local grid_in_QN = (({reaper.GetSetProjectGrid( 0, 0, 0, 0, 0 )})[2]) * 4
local dur = miditicksperbeat*grid_in_QN
local cur_pos_QN = reaper.TimeMap_timeToQN( cur_pos )
local item = reaper.CreateNewMIDIItemInProj( track, cur_pos_QN, cur_pos_QN + total_str_length*grid_in_QN, true )
local take = reaper.GetActiveTake( item )
local pos_ppq = reaper.MIDI_GetPPQPosFromProjTime( take, cur_pos )
local len = #OutputString
local i = 0
while true do
  i = i + 1
  local l = OutputString:sub( i, i )
  local duration
  if l == "-" then
    duration = pos_ppq + dur*3
    reaper.MIDI_InsertNote( take, false, false, pos_ppq, duration, 1, 71, 100, true )
  elseif l == "." then
    duration = pos_ppq + dur
    reaper.MIDI_InsertNote( take, false, false, pos_ppq, duration, 1, 71, 100, true )
  else -- l == " " then
    duration = pos_ppq + dur
  end
  pos_ppq = duration
  if i == len then break end
end
reaper.MIDI_Sort( take )
reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "Message: " .. InputString, true )
reaper.Undo_OnStateChange( "Create Morse Code Item" )

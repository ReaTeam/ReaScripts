-- @description Create MIDI Morse Message Item at edit cursor position, grid length duration, first selected/last touched/ or first track
-- @author amagalma_mespotine
-- @version 1.5
-- @changelog
--   - Full automatic Latin/Greek/Cyrillic character support!
--   - Take markers for every character
-- @link
--   https://forum.cockos.com/showthread.php?t=245504
--   https://mespotin.uber.space/Mespotine/
-- @donation
--   https://www.paypal.me/amagalma
--   https://mespotin.uber.space/Mespotine/mespotine-unterstuetzen/


local track = reaper.GetSelectedTrack(0, 0) or (reaper.GetLastTouchedTrack() or reaper.GetTrack(0, 0))
if not track then return end
local ok, InputString = reaper.GetUserInputs("Create Morse Code Message (Latin/Greek/Cyrillic support)", 1,
"Enter Message :,extrawidth=120", "")
if not ok or InputString == "" then return end

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
  ["ẞ"] = {". . . - - . .", 17},

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
-- Latin small letters
  M["a"] = M["A"]
  M["b"] = M["B"]
  M["c"] = M["C"]
  M["d"] = M["D"]
  M["e"] = M["E"]
  M["f"] = M["F"]
  M["g"] = M["G"]
  M["h"] = M["H"]
  M["i"] = M["I"]
  M["j"] = M["J"]
  M["k"] = M["K"]
  M["l"] = M["L"]
  M["m"] = M["M"]
  M["n"] = M["N"]
  M["o"] = M["O"]
  M["p"] = M["P"]
  M["q"] = M["Q"]
  M["r"] = M["R"]
  M["s"] = M["S"]
  M["t"] = M["T"]
  M["u"] = M["U"]
  M["v"] = M["V"]
  M["w"] = M["W"]
  M["x"] = M["X"]
  M["y"] = M["Y"]
  M["z"] = M["Z"]
  M["ä"] = M["Ä"]
  M["á"] = M["Á"]
  M["à"] = M["À"]
  M["å"] = M["Å"]
  M["ch"] = M["CH"]
  M["è"] = M["È"]
  M["é"] = M["É"]
  M["ñ"] = M["Ñ"]
  M["ö"] = M["Ö"]
  M["ü"] = M["Ü"]
  M["ß"] = M["ẞ"]

-- Greek --------
  M["Α"] = M["A"]
  M["Ά"] = M["A"]
  M["α"] = M["A"]
  M["ά"] = M["A"]
  M["Β"] = M["B"]
  M["β"] = M["B"]
  M["Γ"] = M["G"]
  M["γ"] = M["G"]
  M["Δ"] = M["D"]
  M["δ"] = M["D"]
  M["Ε"] = M["E"]
  M["Έ"] = M["E"]
  M["ε"] = M["E"]
  M["έ"] = M["E"]
  M["Ζ"] = M["Z"]
  M["ζ"] = M["Z"]
  M["Η"] = M["H"]
  M["Ή"] = M["H"]
  M["η"] = M["H"]
  M["ή"] = M["H"]
  M["Θ"] = M["C"]
  M["θ"] = M["C"]
  M["Ι"] = M["I"]
  M["Ί"] = M["I"]
  M["Ϊ"] = M["I"]
  M["ι"] = M["I"]
  M["ί"] = M["I"]
  M["ϊ"] = M["I"]
  M["ΐ"] = M["I"]
  M["Κ"] = M["K"]
  M["κ"] = M["K"]
  M["Λ"] = M["L"]
  M["λ"] = M["L"]
  M["Μ"] = M["M"]
  M["μ"] = M["M"]
  M["Ν"] = M["N"]
  M["ν"] = M["N"]
  M["Ξ"] = M["X"]
  M["ξ"] = M["X"]
  M["Ο"] = M["O"]
  M["Ό"] = M["O"]
  M["ο"] = M["O"]
  M["ό"] = M["O"]
  M["Π"] = M["P"]
  M["π"] = M["P"]
  M["Ρ"] = M["R"]
  M["ρ"] = M["R"]
  M["Σ"] = M["S"]
  M["σ"] = M["S"]
  M["ς"] = M["S"]
  M["Τ"] = M["T"]
  M["τ"] = M["T"]
  M["Υ"] = M["Y"]
  M["Ύ"] = M["Y"]
  M["Ϋ"] = M["Y"]
  M["υ"] = M["Y"]
  M["ύ"] = M["Y"]
  M["ϋ"] = M["Y"]
  M["Φ"] = M["F"]
  M["φ"] = M["F"]
  M["Χ"] = M["CH"]
  M["χ"] = M["CH"]
  M["Ψ"] = M["Q"]
  M["ψ"] = M["Q"]
  M["Ω"] = M["W"]
  M["Ώ"] = M["W"]
  M["ω"] = M["W"]
  M["ώ"] = M["W"]
  M[";"] = M["?"]

-- Cyrillic -----
  M["А"] = M["A"]
  M["Б"] = M["B"]
  M["В"] = M["W"]
  M["Г"] = M["G"]
  M["Д"] = M["D"]
  M["Е"] = M["E"]
  M["Ж"] = M["V"]
  M["З"] = M["Z"]
  M["И"] = M["I"]
  M["І"] = M["I"]
  M["Й"] = M["J"]
  M["К"] = M["K"]
  M["Л"] = M["L"]
  M["М"] = M["M"]
  M["Н"] = M["N"]
  M["О"] = M["O"]
  M["П"] = M["P"]
  M["Р"] = M["R"]
  M["С"] = M["S"]
  M["Т"] = M["T"]
  M["У"] = M["U"]
  M["Ф"] = M["F"]
  M["Х"] = M["H"]
  M["Ц"] = M["C"]
  M["Ч"] = M["Ö"]
  M["Ш"] = M["CH"]
  M["Щ"] = M["Q"]
  M["Ь"] = M["X"]
  M["Ъ"] = M["X"]
  M["Ы"] = M["Y"]
  M["Ь"] = M["Y"]
  M["Э"] = M["É"]
  M["Є"] = M["É"]
  M["Ю"] = M["Ü"]
  M["Я"] = M["Ä"]
  M["Ї"] = M["-"]
  M["а"] = M["A"]
  M["б"] = M["B"]
  M["в"] = M["W"]
  M["г"] = M["G"]
  M["д"] = M["D"]
  M["е"] = M["E"]
  M["ж"] = M["V"]
  M["з"] = M["Z"]
  M["и"] = M["I"]
  M["і"] = M["I"]
  M["й"] = M["J"]
  M["к"] = M["K"]
  M["л"] = M["L"]
  M["м"] = M["M"]
  M["н"] = M["N"]
  M["о"] = M["O"]
  M["п"] = M["P"]
  M["р"] = M["R"]
  M["с"] = M["S"]
  M["т"] = M["T"]
  M["у"] = M["U"]
  M["ф"] = M["F"]
  M["х"] = M["H"]
  M["ц"] = M["C"]
  M["ч"] = M["Ö"]
  M["ш"] = M["C"]
  M["щ"] = M["Q"]
  M["ь"] = M["X"]
  M["ъ"] = M["X"]
  M["ы"] = M["Y"]
  M["ь"] = M["Y"]
  M["э"] = M["É"]
  M["є"] = M["É"]
  M["ю"] = M["Ü"]
  M["я"] = M["Ä"]
  M["ї"] = M["-"]


local msg_chars = {}
local total_str_length = 0
local c = 0
for byte_pos, char in utf8.codes(InputString) do
  local char_utf8 = utf8.char(char)
  if not M[char_utf8] then
    reaper.MB( char_utf8 .. " is not a character in our table.. Sorry!", "Invalid character! Aborting..", 0 )
    return
  end
  if char_utf8:upper() == "H" and (msg_chars[c] and (msg_chars[c][1]) == M["C"][1] .. "   ") then
    char_utf8 = "CH"
  else
    c = c + 1
  end
  msg_chars[c] = {M[char_utf8][1] .. "   ", char_utf8}
  total_str_length = total_str_length + M[char_utf8][2] + 3
end

msg_chars[c][1] = msg_chars[c][1]:sub(1,-4)
total_str_length = total_str_length - 3

local cur_pos = reaper.GetCursorPosition()
local miditicksperbeat = tonumber(({reaper.get_config_var_string( "miditicksperbeat" )})[2])
local grid_in_QN = (({reaper.GetSetProjectGrid( 0, 0, 0, 0, 0 )})[2]) * 4
local dur = miditicksperbeat*grid_in_QN
local cur_pos_QN = reaper.TimeMap_timeToQN( cur_pos )
local item = reaper.CreateNewMIDIItemInProj( track, cur_pos_QN, cur_pos_QN + total_str_length*grid_in_QN, true )
local take = reaper.GetActiveTake( item )
local pos_ppq = reaper.MIDI_GetPPQPosFromProjTime( take, cur_pos )
for m = 1, c do
  reaper.SetTakeMarker( take, m, msg_chars[m][2],
                      reaper.MIDI_GetProjTimeFromPPQPos( take, pos_ppq ) - cur_pos, nil )
  local len = #msg_chars[m][1]
  local i = 0
  while true do
    i = i + 1
    local l = msg_chars[m][1]:sub( i, i )
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
end
reaper.MIDI_Sort( take )
reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "Message: " .. InputString, true )
reaper.Undo_OnStateChange( "Create Morse Code Item" )

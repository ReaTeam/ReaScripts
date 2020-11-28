-- @description Create MIDI Morse Message Item at edit cursor position, grid length duration, first selected/last touched/ or first track
-- @author amagalma_mespotine
-- @version 1.00
-- @link
--   https://forum.cockos.com/showthread.php?t=245504
--   https://mespotin.uber.space/Mespotine/
-- @donation https://www.paypal.me/amagalma


local track = reaper.GetSelectedTrack(0, 0) or (reaper.GetLastTouchedTrack() or reaper.GetTrack(0, 0))
if not track then return end
local ok, InputString = reaper.GetUserInputs("Create (International) Morse Code Message", 1,
                        "Enter Message :,extrawidth=100", "")
if not ok then return end

InputString = InputString:upper()

local MorseTable = {
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
                    ["CH"] = {"- - - -", 15},
                    ["Å"] = {". - - . -", 15},
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

local InputString_len = InputString:len()
local OutputString = ""
local i = 1
local total_str_length = 0
while true do
  local k = InputString:sub(i,i)
  if k == "C" and InputString:sub(i+1,i+1) == "H" then
    k = "CH"
    i = i + 1
  end
  if MorseTable[k][1] then
    OutputString = OutputString .. MorseTable[k][1] .. "   "
    total_str_length = total_str_length + MorseTable[k][2] + 3
  else
    reaper.MB( k .. " is not a valid International Morse Code character", "Invalid character!", 0 )
    return
  end
  i = i + 1
  if i > InputString_len then break end
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
local i = 1
while true do
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
  if i == len then break else i = i + 1 end
end
reaper.MIDI_Sort( take )
reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", "Message: " .. InputString, true )
reaper.Undo_OnStateChange( "Create Morse Code Item" )

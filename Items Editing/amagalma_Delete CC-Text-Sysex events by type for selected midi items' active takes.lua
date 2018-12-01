--[[
ReaScript name: amagalma_Delete CC-Text-Sysex events by type for selected midi items' active takes.lua
Version: 1.1
Author: amagalma
About:
  # Deletes MIDI events by type (except notes) of the active takes of the selected items
     - requires Lokasenna's GUI
--]] 

--[[
 * Changelog:
 * v1.1(2018-11-16)
  + bugfix, working properly now
--]]

--------------------------------------------------------------------------------------

local reaper = reaper

-- Load Lokasenna GUI
local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
  reaper.MB("Couldn't load the Lokasenna_GUI library. Please run 'Set Lokasenna_GUI v2 library path.lua' in the Lokasenna_GUI folder.", "Whoops!", 0)
  return
end
loadfile(lib_path .. "Core.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Options.lua")()
if missing_lib then return 0 end

-- CC Names
local cc_name = {
[0] = "Bank Select (MSB)",
[1] = "Modulation Wheel",
[2] = "Breath controller",
[4] = "Foot Pedal (MSB)",
[5] = "Portamento Time (MSB)",
[6] = "Data Entry (MSB)",
[7] = "Volume (MSB)",
[8] = "Balance (MSB)",
[10] = "Pan position (MSB)",
[11] = "Expression (MSB)",
[12] = "Effect Control 1 (MSB)",
[13] = "Effect Control 2 (MSB)",
[14] = "Undefined",
[15] = "Undefined",
[16] = "General Purpose Slider 1",
[17] = "General Purpose Slider 2",
[18] = "General Purpose Slider 3",
[19] = "General Purpose Slider 4",
[32] = "Bank Select (LSB)",
[33] = "Modulation Wheel (LSB)",
[34] = "Breath controller (LSB)",
[36] = "Foot Pedal (LSB)",
[37] = "Portamento Time (LSB)",
[38] = "Data Entry (LSB)",
[39] = "Volume (LSB)",
[40] = "Balance (LSB)",
[42] = "Pan position (LSB)",
[43] = "Expression (LSB)",
[44] = "Effect Control 1 (LSB)",
[45] = "Effect Control 2 (LSB)",
[64] = "Hold Pedal (on/off)",
[65] = "Portamento (on/off)",
[66] = "Sustenuto Pedal (on/off)",
[67] = "Soft Pedal (on/off)",
[68] = "Legato Pedal (on/off)",
[69] = "Hold 2 Pedal (on/off)",
[70] = "Sound Variation",
[71] = "Timbre/Resonance",
[72] = "Sound Release Time",
[73] = "Sound Attack Time",
[74] = "Brightness/Frequency Cutoff",
[75] = "Sound Control 6",
[76] = "Sound Control 7",
[77] = "Sound Control 8",
[78] = "Sound Control 9",
[79] = "Sound Control 10",
[80] = "General Purpose Button 1",
[81] = "General Purpose Button 2",
[82] = "General Purpose Button 3",
[83] = "General Purpose Button 4",
[91] = "Effects Level",
[92] = "Tremolo Level",
[93] = "Chorus Level",
[94] = "Celeste Level",
[95] = "Phaser Level",
[96] = "Data Button increment",
[97] = "Data Button decrement",
[98] = "Non-registered Parameter (LSB)",
[99] = "Non-registered Parameter (MSB)",
[100] = "Registered Parameter (LSB)",
[101] = "Registered Parameter (MSB)",
}

local function reversePairs( aTable ) -- https://love2d.org/forums/viewtopic.php?t=77064#p161353
  local keys = {}
  for k,v in pairs(aTable) do keys[#keys+1] = k end
  table.sort(keys, function (a, b) return a>b end)
  local n = 0
  return function ( )
    n = n + 1
    return keys[n], aTable[keys[n] ]
  end
end

local function no_undo()
  reaper.defer(function () end)
end

--------------------------------------------------------------------------------------

-- Store the active takes of the selected midi items
local midi_takes = {}
local midi_takes_cnt = 0
local itemcnt = reaper.CountSelectedMediaItems( 0 )
if itemcnt == 0 then 
  reaper.MB( "Please select at least one item", "Message", 0 )
  no_undo() return end
for i = 0, itemcnt-1 do
  local item = reaper.GetSelectedMediaItem( 0, i )
  local take = reaper.GetActiveTake( item )
  if take and reaper.TakeIsMIDI( take ) then
    local _, _, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts( take )
    if ccevtcnt > 0 or textsyxevtcnt > 0 then
      midi_takes[reaper.BR_GetMediaItemTakeGUID( take )] = {cc = {}, st = {}}
      midi_takes_cnt = midi_takes_cnt + 1
    end
  end
end

if midi_takes_cnt < 1 then
  reaper.MB( "No non-note events found in any of the selected items' active takes.", "Operation aborted", 0 )
  no_undo() return
else
  -- Create the table categories that will receive the events to be deleted
  local pitch = {}
  local pitch_cnt = 0
  local bank_program = {}
  local bank_program_cnt = 0
  local ch_pressure = {}
  local ch_pressure_cnt = 0
  local text = {}
  local text_cnt = 0
  local sysex = {}
  local sysex_cnt = 0
  local cc = {}
  
  -- Store the events
  for guid in pairs(midi_takes) do
    local take = reaper.GetMediaItemTakeByGUID( 0, guid )
    local _, _, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts( take )
    -- Categorize each event by its type and then by takes
    for i = 0, ccevtcnt-1 do
      local  _, _, _, _, chanmsg, _, number = reaper.MIDI_GetCC( take, i )
      if chanmsg == 176 then -- CC
        if not cc[number] then
          cc[number] = {}
          cc[number][guid] = {}
          cc[number][guid][i] = true
          cc[number].cnt = 1
        else
          cc[number].cnt = cc[number].cnt + 1
          if not cc[number][guid] then
            cc[number][guid] = {}
          end
          cc[number][guid][i] = true
        end
      elseif chanmsg == 192 then -- Bank Program
        bank_program_cnt = bank_program_cnt + 1
        if not bank_program[guid] then
          bank_program[guid] = {}
        end
        bank_program[guid][i] = true
      elseif chanmsg == 208 then -- Channel Pressure
        ch_pressure_cnt = ch_pressure_cnt + 1
        if not ch_pressure[guid] then
          ch_pressure[guid] = {}
        end
        ch_pressure[guid][i] = true
      elseif chanmsg == 224 then -- Pitch
        pitch_cnt = pitch_cnt + 1
        if not pitch[guid] then
          pitch[guid] = {}
        end
        pitch[guid][i] = true
      end
    end
    
    for i = 0, textsyxevtcnt-1 do
      local _, _, _, _, evtype = reaper.MIDI_GetTextSysexEvt( take, i)
      if evtype == -1 then
        sysex_cnt = sysex_cnt + 1
        if not sysex[guid] then
          sysex[guid] = {}
        end
        sysex[guid][i] = true
      else
        text_cnt = text_cnt + 1
        if not text[guid] then
          text[guid] = {}
        end
        text[guid][i] = true
      end
    end 
  end
  
  -- Calculate how many different categories have been found
  local categories = {}
  local todelete = {}
  if pitch_cnt > 0 then
    categories[#categories+1] = "Pitch"
    todelete[#todelete+1] = pitch
  end
  if bank_program_cnt > 0 then
    categories[#categories+1] = "Bank and/or Program"
    todelete[#todelete+1] = bank_program
  end
  if ch_pressure_cnt > 0 then
    categories[#categories+1] = "Channel Pressure"
    todelete[#todelete+1] = ch_pressure
  end
  if text_cnt > 0 then
    categories[#categories+1] = "Text"
    todelete[#todelete+1] = text
    todelete[#todelete].text = true
  end
  if sysex_cnt > 0 then
    categories[#categories+1] = "Sysex"
    todelete[#todelete+1] = sysex
    todelete[#todelete].sysex = true
  end
  -- Name the CCs found
  for index in pairs(cc) do
    todelete[#todelete+1] = cc[index]
    if cc_name[index] then
      categories[#categories+1] = "CC #" .. index .. " - " .. cc_name[index]
    else
      categories[#categories+1] = "CC #" .. index
    end
  end
  
  -- GUI functions ---------------------------------------------------------------------
  
  local check_to_delete = {}
  function check_to_del()
    if #categories == 1 then
      check_to_delete[1] = GUI.Val("Checklist")
    else
      check_to_delete = GUI.Val("Checklist")
    end
  end
  
  function delete_all()
    reaper.PreventUIRefresh( 1 )
    for guid in pairs(midi_takes) do
      local take = reaper.GetMediaItemTakeByGUID( 0, guid )
      local _, _, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts( take )
      for i = ccevtcnt-1, 0, -1 do
        reaper.MIDI_DeleteCC( take, i )
      end
      for i = textsyxevtcnt-1, 0, -1  do
        reaper.MIDI_DeleteTextSysexEvt( take, i )
      end
    end
    reaper.PreventUIRefresh( -1 )
    reaper.Undo_OnStateChange( "Delete all MIDI events except notes for selected items" )
    gfx.quit()
  end
  
  function do_action()
    -- check which categories are selected
    for i = 1, #check_to_delete do
      if check_to_delete[i] == true then
        -- add events to be deleted for each take in a table according to type (cc or sys/txt)
        for guid, table in pairs(todelete[i]) do
          -- check if they are TEXT/SYSEX
          if todelete[i]["sysex"] == true or todelete[i]["text"] == true then
            if guid ~= "sysex" and guid ~= "text" then
              for id, v in pairs(table) do
                midi_takes[guid].st[id] = true
              end
            end
          else -- is CC
            if guid ~= "cnt" then
              for id,v in pairs(table) do
                midi_takes[guid].cc[id] = true
              end
            end
          end
        end
      end
    end
    reaper.PreventUIRefresh( 1 )
    -- iterate midi takes deleting selected MIDI event types
    for guid, table in pairs(midi_takes) do
      local take = reaper.GetMediaItemTakeByGUID( 0, guid )
      -- delete CC
      for k,v in reversePairs(table.cc) do
        reaper.MIDI_DeleteCC( take, k )
      end
      -- delete SYS/TXT
      for k,v in reversePairs(table.st) do
        reaper.MIDI_DeleteTextSysexEvt( take, k )
      end
    end
    reaper.PreventUIRefresh( -1 )
    reaper.Undo_OnStateChange( "Delete MIDI events by type in selected items" )
    gfx.quit()
  end 
  
  -- GUI -------------------------------------------------------------------------------
  
  GUI.name = "Delete MIDI events by type"
  GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 352, 120 + 20*#categories
  GUI.anchor, GUI.corner = "screen", "C"
  
  GUI.New("Cancel", "Button", {
      z = 11,
      x = 92,
      y = GUI.h-48,
      w = 64,
      h = 24,
      caption = "Cancel",
      font = 2,
      col_txt = "white",
      col_fill = "elm_frame",
      func = gfx.quit
  })
  
  GUI.New("OK", "Button", {
      z = 11,
      x = 16,
      y = GUI.h-48,
      w = 64,
      h = 24,
      caption = "OK",
      font = 2,
      col_txt = "white",
      col_fill = "elm_frame",
      func = do_action
  })
  
  GUI.New("All", "Button", {
      z = 11,
      x = 168,
      y = GUI.h-48,
      w = 80,
      h = 24,
      caption = "Delete all",
      font = 2,
      col_txt = "white",
      col_fill = "elm_frame",
      func = delete_all
  })
  
  GUI.New("Checklist", "Checklist", {
      z = 11,
      x = 16,
      y = 16,
      w = 320,
      h = 48 + 20*#categories,
      caption = "MIDI event types found (select to delete):",
      optarray = categories,
      dir = "v",
      pad = 8,
      font_a = 2,
      font_b = 2,
      col_txt = "white",
      col_fill = "elm_fill",
      bg = "wnd_bg",
      frame = true,
      shadow = true,
      swap = nil,
      opt_size = 16
  })
  
  function force_size()
    gfx.quit()
    gfx.init(GUI.name, GUI.w, GUI.h, GUI.dock, GUI.x, GUI.y)
    GUI.cur_w, GUI.cur_h = GUI.w, GUI.h
  end
  GUI.onresize = force_size
  
  GUI.func = check_to_del
  GUI.Init()
  GUI.Main()
end

--[[
ReaScript name: js_Select CC lanes to show in selected MIDI items.lua
Version: 0.92
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Extensions:  SWS/S&M 2.8.3 or later
Donation: https://www.paypal.me/juliansader
Provides: main=main,midi_editor,midi_inlineeditor
About:
  # DESCRIPTION
  
  REAPER does not provide native actions to select which CC lanes to display inside MIDI items in the arrange view, or even in the inline MIDI editor.
  By default, CC lane display is linked to the last-used settings in the (full, not inline) MIDI editor, for each item individually. 
  Therefore, to change CC lane visibility, the user has to open the MIDI editor for each item, and apply the change in the MIDI editor.
  
  This script provides a much faster way to select CC lanes visibility for all selected MIDI items simultaneously.
  
  The script's GUI shows all CC lanes, and also indicates which CC types are used by the selected items.

  # INSTRUCTIONS
  
  CC lanes can be selected by clicking with the mouse, or by using these shortcuts for commonly used CC types:
  
      v = Velocity
      p = Pitchbend
      m = CC1, Modwheel
      e = CC11, Expression
      s = CC64, Sustain (sostenuto) pedal
      n = Notation
      t = Text
      b = Bank/program select
      
      c = Clear all
      u = Show only used lanes
      esc   = Exit without applying changes
      enter = Exit and apply changes
]] 

--[[
  Changelog:
  * v0.90 (2018-01-13)
    + Initial Release
  * v0.91 (2018-01-13)
    + Fix: item under mouse is not open in inline editor
  * v0.92 (2018-01-13)
    + Show startup tips
]]


-- USER AREA
-- Settings that the user can customize

    colorForeground = {0.8, 0.8, 0, 1}
    colorUsedClear  = {1, 0.5, 0, 1} --{0.8, 0.8, 0, 1}
    colorApply      = {1, 0.5, 0, 1}
    colorBackground = {0.1, 0.1, 0.1, 1}
    
    itemsToEdit = "all selected" -- "under mouse" or "all selected"
    
-- End of USER AREA


------------------------------------------------------------------------
------------------------------------------------------------------------

-- All item pointers and their state chunks will be stored in this table
local tChunks = {}

-- Some constants
VEL = 160
OFF = 161
NOTATION = 162
PITCH = 163
PROGRAM = 164
CHANPRESS = 165
BANKPROG = 166
TEXT = 167
SYSEX = 168
USED = 187
CLEAR = 189
APPLY = 191

BORDER = 10 -- GUI border, in pixels
                  
-- The GUI indexes CC lanes differently than the state chunk, in order to display them in a nice sequence.
local tNames = {[0] = "Bank Select (MSB)",
                [1] = "Mod Wheel (MSB)",
                [2] = "Breath (MSB)", 
                [4] = "Foot Pedal (MSB)",
                [5] = "Portamento (MSB)",
                [6] = "Data Entry (MSB)",
                [7] = "Volume (MSB)",
                [8] = "Balance (MSB)",
                [10] = "Pan (MSB)",
                [11] = "Expression (MSB)",
                [12] = "Control 1 (MSB)",
                [13] = "Control 2 (MSB)",
                [32] = "Bank Select (LSB)",
                [33] = "Mod Wheel (LSB)",
                [34] = "Breath (LSB)", 
                [36] = "Foot Pedal (LSB)",
                [37] = "Portamento (LSB)",
                [38] = "Data Entry (LSB)",
                [39] = "Volume (LSB)",
                [40] = "Balance (LSB)",
                [42] = "Pan (LSB)",
                [43] = "Expression (LSB)",
                [64] = "Sustain Pedal (on/off)",
                [65] = "Portamento (on/off)",
                [66] = "Sostenuto (on/off)",
                [67] = "Soft Pedal (on/off)",
                [68] = "Legato Pedal (on/off)",
                [69] = "Hold Pedal 2 (on/off)",
                [70] = "Sound Variation",
                [71] = "Timbre Content",
                [72] = "Release Time",
                [73] = "Attack Time",
                [74] = "Brightness",
                [84] = "Portamento Control",
                [91] = "External FX Depth",
                [92] = "Tremolo Depth",
                [93] = "Chorus Depth",
                [94] = "Detune Depth",
                [95] = "Phaser Depth",
                [96] = "Data Increment",
                [97] = "Data Decrement",
                
                
                [VEL] = "Velocity",
                [OFF] = "Off Velocity",
                [NOTATION] = "Notation",
                [PITCH] = "Pitchbend",
                [PROGRAM] = "Program",
                [CHANPRESS] = "Channel Pressure",
                [BANKPROG] = "Bank/Program select",
                [TEXT] = "Text",
                [SYSEX] = "Sysex",
                [USED] = "Show only used lanes",
                [CLEAR] = "Clear all",
                [APPLY] = "Apply"
              }
              for i = 128, 159 do
                  if tNames[i-128] then tNames[i] = tNames[i-128]:gsub("MSB", "14bit") end
              end

-- The GUI indexes CC lanes differently than the state chunk, in order to display them in a nice sequence.
-- This table cross-references GUI index to chunk VELLANE number.
local tCrossRefGUIToChunk = { [VEL] = -1,
                              [OFF] = 167,
                              [NOTATION] = 166,
                              [PITCH] = 128,
                              [PROGRAM] = 129,
                              [CHANPRESS] = 130,
                              [BANKPROG] = 131,
                              [TEXT] = 132,
                              [SYSEX] = 133
                            }
                            for i = 128, 159 do
                                tCrossRefGUIToChunk[i] = i+6
                            end
                  
local tCrossRefChunkToGUI = {}
                            for i, k in pairs(tCrossRefGUIToChunk) do
                                tCrossRefChunkToGUI[k] = i
                            end
            
tToggles = {} -- Which CC lanes in GUI are toggled?

tUsedCCs = {} -- Which CC lanes are used in selected items?

local tNumbers = {} -- True CC lanes (excluding velocity, pitch etc) are displayed with their numbers in the MIDI editor's CC selection dropdown list. The GUI will display these numbers.
                 for i = 0, 127 do
                     tNumbers[i] = string.format("%i", i)
                 end
                 for i = 128, 128+31 do
                     tNumbers[i] = string.format("%i", i-128) .. "/" .. string.format("%i", i-96)
                 end
     
local tShortcuts = {[118] = function() tToggles[VEL] = not tToggles[VEL] end, -- v = velocity
                    [112] = function() tToggles[PITCH] = not tToggles[PITCH] end, -- p = pitchbend
                    [109] = function() tToggles[1] = not tToggles[1] end, -- m = modwheel
                    [101] = function() tToggles[11] = not tToggles[11] end, -- e = expression
                    [115] = function() tToggles[64] = not tToggles[64] end, -- s = sustain (sostenuto) pedal
                    [98]  = function() tToggles[BANKPROG] = not tToggles[BANKPROG] end, -- b = bank/program select
                    [110] = function() tToggles[NOTATION] = not tToggles[NOTATION] end, -- n = notation
                    [116] = function() tToggles[TEXT] = not tToggles[TEXT] end,
                    [99]  = function() tToggles = {} end, -- c = clear all
                    [117] = function() tToggles = {} for i,k in pairs(tUsedCCs) do tToggles[i] = k end end -- u = show only used lanes
                   }             


------------------------
function setColor(color)
    gfx.set(color[1], color[2], color[3], color[4])
    --gfx.set(color>>16, (color>>8)&0xFF, color&0xFF, 1)
end

-------------------------------
function toggleLaneUnderMouse()
    local column = math.floor(((gfx.mouse_x-BORDER)/(gfx.w-2*BORDER)) * 6)
    local row    = math.floor(((gfx.mouse_y-BORDER)/(gfx.h-2*BORDER)) * 32)
    if column >= 0 and column <= 5 and row >= 0 and row <= 31 then
        local lane = 32*column + row
        if lane <= 168 or tNames[lane] then -- skip the rows in rightmost column between CC lanes and clear/used/apply buttons
            tToggles[lane] = not tToggles[lane]
        end
    end
end

------------------
function drawGUI()
    setColor(colorBackground)
    gfx.rect(0, 0, gfx.w, gfx.h, true)
    for fontSize = 8, 20 do
        gfx.setfont(1, "arial", fontSize)
        local width = gfx.measurestr("wwwwwwwwwwwwwwwwwww")
        if gfx.texth*32 > gfx.h-BORDER-BORDER or width*6 > gfx.w-BORDER-BORDER then
            gfx.setfont(1, "arial", fontSize-1)
            break
        end
    end
    local columnWidth = (gfx.w-2*BORDER)/6
    local rowHeight   = (gfx.h-2*BORDER)/32
    local rectWidth   = math.floor(columnWidth*0.9)
    local rectHeight  = math.floor(rowHeight*0.94)
    for column = 0, 5 do
        for row = 0, 31 do
            gfx.x = BORDER + column*columnWidth
            gfx.y = BORDER + row*rowHeight
            local lane = 32*column + row
            if lane == 187 or lane == 189 then
                setColor(colorUsedClear)
                gfx.rect(gfx.x, gfx.y, rectWidth, rectHeight, true)
                setColor(colorBackground)
                gfx.drawstr(tNames[lane], 5, gfx.x+rectWidth-1, gfx.y+rectHeight-1)
            elseif lane == 191 then
                setColor(colorApply)
                gfx.rect(gfx.x, gfx.y, rectWidth, rectHeight, true)
                setColor(colorBackground)
                gfx.drawstr(tNames[lane], 5, gfx.x+rectWidth-1, gfx.y+rectHeight-1)
            else
                if tUsedCCs[lane] then str = "● " else str = "   " end
                if tNumbers[lane] then str = str .. tNumbers[lane] .. ":" end
                if tNames[lane] then str = str .. tNames[lane] end
                if tToggles[lane] then
                    setColor(colorForeground)
                    gfx.rect(gfx.x, gfx.y, rectWidth, rectHeight, true)
                    setColor(colorBackground)
                    gfx.drawstr(str, 4, gfx.x+rectWidth-1, gfx.y+rectHeight-1)
                else
                    setColor(colorForeground)
                    gfx.drawstr(str, 4, gfx.x+rectWidth-1, gfx.y+rectHeight-1)
                end
            end
        end
    end
    gfx.update()
end

------------------------
function findUsedLanes()
    
    tCrossRefStatusToGUI = {[0x90] = VEL, -- note-on
                              [0xC0] = BANKPROG, -- program change, open bank/program select lane instead
                              [0xD0] = CHANPRESS, -- Channel pressure
                              [0xE0] = PITCH, -- Pitchbend
                              --[0xFF] = 132, -- text event
                              --[0xF0] = 133 -- sysex
                              --[ = 166 - notation
                             }
    tUsedCCs = {} -- Clear table                   
          
    for item, chunk in pairs(tChunks) do
     
        -- Find all CC types
        for status, lane in chunk:gmatch("\n[eE] [%-%d]+ (%w%w) (%w%w) ") do
            status = tonumber(status, 16) & 0xF0
            lane   = tonumber(lane, 16)
            if status == 0xB0 then
                if lane == 0 or lane == 32 then -- Bank select MSB and LSB.  Open Bank/Progam Select lane instead.
                    tUsedCCs[BANKPROG] = true
                elseif lane ~= 0x7b then
                    tUsedCCs[lane] = true
                end
            elseif tCrossRefStatusToGUI[status] then
                tUsedCCs[tCrossRefStatusToGUI[status]] = true
            end
        end
        
        -- Any notation events?
        if chunk:match("\n<[xX] [%-%d]+ 0 %d+ %-1") then
            tUsedCCs[NOTATION] = true
        end
        
        -- Any text events?
        if chunk:match("\n<[xX] [%-%d]+ 0 0 0") then
            tUsedCCs[TEXT] = true
        end
        
        -- Any sysex events?
        if chunk:match("\n<[xX] [%-%d]+ 0 %w%w") then
            tUsedCCs[SYSEX] = true
        end
    end
end

--------------------------------------
function applyTogglesToAllItemChunks()
    -- In order to calculate take heights, must know whether taes are displayed in stacked lanes.
    local takesAreShownInLanes = (reaper.GetToggleCommandStateEx(0, 40435) == 1)
    
    for item, chunk in pairs(tChunks) do
        -- Calculate lane height
        local numLanes = 0
        for i = 0, 168 do -- use for i instead of pairs, to skip CLEAR, USED and APPLY toggles
            if tToggles[i] then numLanes = numLanes + 1 end
        end
        
        -- Assemble new VELLANE string
        local newVELLANEstr = ""
        if numLanes == 0 then
            newVELLANEstr = "\nVELLANE -1 0 0" -- A MIDI editor should always have at least one lane, otherwise SetItemStateChunk will fail. If no used lanes, just velocity with 0 height
        else
            -- Calculate inline editor lane height, based on item and take height in pixels
            local itemHeight = reaper.GetMediaItemInfo_Value(item, "I_LASTH")
            local takeHeight = takesAreShownInLanes and itemHeight/reaper.CountTakes(item)
                                                    or itemHeight
            inlineCCLaneHeight = math.floor(math.min(takeHeight/4, (takeHeight/2)/numLanes)) -- Fill one third of take height with CC lanes, except if single lane, then only one quarter.
            
            -- Calculate MIDI editor lane height, based on MIDI editor window size in CFGEDIT field
            local MIDIEditorUpperY, MIDIEditorBottomY = chunk:match("CFGEDIT [%-%.%d]+ [%.%-%d]+ [%.%-%d]+ [%.%-%d]+ [%.%-%d]+ [%.%-%d]+ [%.%-%d]+ [%.%-%d]+ [%.%-%d]+ [%.%-%d]+ [%.%-%d]+ [%.%-%d]+ [%.%-%d]+ ([%.%-%d]+) [%.%-%d]+ ([%.%-%d]+)")
            MIDIEditorUpperY, MIDIEditorBottomY = tonumber(MIDIEditorUpperY), tonumber(MIDIEditorBottomY)
            if MIDIEditorUpperY and MIDIEditorBottomY then -- These values don't exist until a MIDI editor has been opened
                local MIDIEditorHeight = math.abs((MIDIEditorUpperY - MIDIEditorBottomY)*0.8) -- *0.8 to pproximate toolbar height?
                MIDIEditorCCLaneHeight = math.floor(math.min(MIDIEditorHeight/4, (MIDIEditorHeight/3)/numLanes))
            else
                MIDIEditorCCLaneHeight = 50
            end
            
            local laneHeightStr = " " .. string.format("%i", MIDIEditorCCLaneHeight) .. " " .. string.format("%i", inlineCCLaneHeight)
                    
            -- Do 160 to 168 first, since I prefer these lane to be on top
            for lane = 160, 168 do
                if tToggles[lane] then
                    chunkLaneNumber = tCrossRefGUIToChunk[lane] or lane
                    newVELLANEstr = newVELLANEstr .. "\nVELLANE " .. string.format("%i", chunkLaneNumber) .. laneHeightStr
                end
            end
            for lane = 0, 159 do
                if tToggles[lane] then
                    chunkLaneNumber = tCrossRefGUIToChunk[lane] or lane
                    newVELLANEstr = newVELLANEstr .. "\nVELLANE " .. string.format("%i", chunkLaneNumber) .. laneHeightStr
                end
            end
        end
        
        -- Replace existing VELLANE field
        chunk = chunk:gsub("\nVELLANE [^\n]+", "") -- Remove all existing CC lane fields
        chunk = chunk:gsub("(\nIGNTEMPO [01] [^\n]+)", "%1" .. newVELLANEstr) -- Assume that all take chunks must have IGNTEMPO field
        
        reaper.SetItemStateChunk(item, chunk, false)
    end
end

-----------------------
function getAllChunks()
    -- REAPER's own GetItemStateChunk is buggy!  Can't load large chunks!  So must use SWS's SNM_GetSetObjectState.
    local fastStr = reaper.SNM_CreateFastString("")
    
    if itemsToEdit == "under mouse" then
        if not reaper.APIExists("BR_GetMouseCursorContext") then
            reaper.MB("This scripts requires the SWS/S&M extension, which can be downloaded from\n\nwww.sws-extension.org", "ERROR", 0)
            reaper.SNM_DeleteFastString(fastStr)
            return
        end
        
        local item = reaper.BR_ItemAtMouseCursor()
        if reaper.ValidatePtr2(0, item, "MediaItem*") then
            local chunkOK = reaper.SNM_GetSetObjectState(item, fastStr, false, false)
            if chunkOK then 
                local chunk = reaper.SNM_GetFastString(fastStr)
                tChunks[item] = chunk
            end
        else -- check if mouse is perhaps over MIDI editor
            local window, segment, details = reaper.BR_GetMouseCursorContext()
            if window == "midi_editor" then
                local editor = reaper.MIDIEditor_GetActive()
                if editor ~= nil then
                    local take = reaper.MIDIEditor_GetTake(editor)
                    if reaper.ValidatePtr2(0, take, "MediaItem_Take*") then
                        local item = reaper.GetMediaItemTake_Item(take)
                        if reaper.ValidatePtr2(0, item, "MediaItem*") then
                            local chunkOK = reaper.SNM_GetSetObjectState(item, fastStr, false, false)
                            if chunkOK then
                                local chunk = reaper.SNM_GetFastString(fastStr)
                                tChunks[item] = chunk
        end end end end end end

    else -- itemsToEdit == "all selected"
        for i = 0, reaper.CountSelectedMediaItems(0)-1 do
            local item = reaper.GetSelectedMediaItem(0, i)
            if reaper.ValidatePtr2(0, item, "MediaItem*") then
                local chunkOK = reaper.SNM_GetSetObjectState(item, fastStr, false, false)
                if chunkOK then
                    local chunk = reaper.SNM_GetFastString(fastStr)
                    tChunks[item] = chunk
    end end end end
    
    reaper.SNM_DeleteFastString(fastStr)
end

----------------------
function countChunks()
    local count = 0
    for item, chunk in pairs(tChunks) do
        count = count + 1
    end
    return count
end

---------------------------------------
function setTogglesToCurrentlyVisible()
    for item, chunk in pairs(tChunks) do
        for chunkLane in chunk:gmatch("\nVELLANE ([%-%d]+) ") do
            GUILane = tCrossRefChunkToGUI[tonumber(chunkLane)] or tonumber(chunkLane)
            tToggles[GUILane] = true
        end
    end
end

---------------
function loop()
    gfx.update()
    c = gfx.getchar()
    
    if c == -1 or c == 27 then -- GUI closed or ESC: quit without applying
        return
    elseif c == 13 then -- enter
        applyTogglesToAllItemChunks()
        return
    elseif tShortcuts[c] then
        tShortcuts[c]()
        drawGUI()
    elseif gfx.w ~= prevW or gfx.h ~= prevH then -- GUI resized
        prevW, prevH = gfx.w, gfx.h
        drawGUI()
    elseif gfx.mouse_cap&1 == 1 and not mouseAlreadyDown then -- left mouse click
        mouseAlreadyDown = true
        toggleLaneUnderMouse()
        if tToggles[APPLY] then
            applyTogglesToAllItemChunks()
            return
        elseif tToggles[CLEAR] then
            tToggles = {}
        elseif tToggles[USED] then
            tToggles = {} 
            for i = 0, 170 do tToggles[i] = tUsedCCs[i] end
        end
        drawGUI()
    elseif gfx.mouse_cap&1 == 0 then
        mouseAlreadyDown = false
    end
    
    reaper.runloop(loop)
end

---------------
function exit()
    gfx.quit()
    reaper.UpdateArrange()
    reaper.Undo_OnStateChange2(0, "Select CC lanes to show") 
end


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

-- Get mouse position and chunks before showing startup tips (since mouse will move)
getAllChunks()
numChunks = countChunks()
if numChunks == 0 then return elseif numChunks == 1 then setTogglesToCurrentlyVisible() end
findUsedLanes()

-- Show new version tips
lastTipVersion = tonumber(reaper.GetExtState("Select CC lanes to show", "Last tip version")) or 0
if lastTipVersion < 0.92 then
    reaper.MB([[CC lanes can be selected by clicking with the mouse, or by using these shortcuts for commonly used CC types:
  
    v = Velocity
    p = Pitchbend
    m = CC1, Modwheel
    e = CC11, Expression
    s = CC64, Sustain (sostenuto) pedal
    n = Notation
    t = Text
    b = Bank/program select
    
    c = Clear all
    u = Show only used lanes
    esc   = Exit without applying changes
    enter = Exit and apply changes
  
(This startup tip will only be displayed once. For more information, please refer to the Description and Instructions inside the script file.)]], "Startup tips: v0.92", 0)

    reaper.SetExtState("Select CC lanes to show", "Last tip version", 0.92, true)
end

-- Start the GUI!
gfx.init("Select CC lanes to show", 960, 504, 0)
drawGUI()

reaper.atexit(exit)
loop()

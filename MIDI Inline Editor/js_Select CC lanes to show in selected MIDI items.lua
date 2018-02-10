--[[
ReaScript name: js_Select CC lanes to show in MIDI item under mouse.lua
Version: 0.98
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Screenshot: https://stash.reaper.fm/32685/js_Select%20CC%20lanes%20to%20show%20-%20screenshot.png
Extensions:  SWS/S&M 2.8.3 or later
Donation: https://www.paypal.me/juliansader
Provides: [main=main,midi_editor,midi_inlineeditor] .
About:
  # DESCRIPTION
  
  REAPER does not provide native actions to select which CC lanes to display inside MIDI items in the arrange view, or even in the inline MIDI editor.
  By default, CC lane display is linked to the last-used settings in the (full, not inline) MIDI editor, for each item individually. 
  Therefore, to change CC lane visibility, the user has to open the MIDI editor for each item, and apply the change in the MIDI editor.
  
  This script provides a much faster way to select CC lanes visibility while working in the MIDI Inline Editor.
  
  The script's GUI lists all CC lanes, and also indicates which CC types are used by the items.
  (Note: the latter feature does not yet work in items with external .mid source files.)
  
  The GUI can be resized, and the last-used dimensions will be recalled when the script is run again.
  # INSTRUCTIONS
  
  CC lanes can be selected by clicking with the mouse, or by using these shortcuts for commonly used CC types:
  
      v = Velocity
      p = Pitchbend
      m = CC1, Modwheel
      e = CC11, Expression
      h = CC64, Hold/Sustain pedal
      1-9 = CCs 1-9
      n = Notation
      t = Text
      s = Sysex
      b = Bank/program select
      
      c = Clear all
      u = Show only used lanes
      esc = Exit without applying changes
      enter or a = Exit and apply changes
]] 

--[[
  Changelog:
  * v0.90 (2018-01-13)
    + Initial Release
  * v0.91 (2018-01-13)
    + Fix: item under mouse is not open in inline editor
  * v0.92 (2018-01-13)
    + Show startup tips
  * v0.93 (2018-01-13)
    + Recall last-used GUI dimensions
  * v0.94 (2018-01-14)
    + Script automatically installed in Main, MIDI editor and Inline Editor sections
  * v0.95 (2018-01-14)
    + If called from main MIDI editor, re-focus editor after exit
  * v0.96 (2018-01-25)
    + Automatically load customized CC names if all items are in single track
  * v0.97 (2018-02-09)
    + Minimum lane height in MIDI editor
  * v0.98 (2018-02-10)
    + Distinguish notation and text events more accurately
]]


-- USER AREA
-- Settings that the user can customize

    colorForeground = {0.8, 0.8, 0, 1}
    colorUsedClear  = {1, 0.5, 0, 1} --{0.8, 0.8, 0, 1}
    colorApply      = {1, 0, 0, 1}
    colorBackground = {0.08, 0.08, 0.08, 1}
    
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
                [64] = "Hold Pedal (on/off)",
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
                    [104] = function() tToggles[64] = not tToggles[64] end, -- h = hold/sustain pedal
                    [49]  = function() tToggles[1] = not tToggles[1] end,
                    [50]  = function() tToggles[2] = not tToggles[2] end,
                    [51]  = function() tToggles[3] = not tToggles[3] end,
                    [52]  = function() tToggles[4] = not tToggles[4] end,
                    [53]  = function() tToggles[5] = not tToggles[5] end,
                    [54]  = function() tToggles[6] = not tToggles[6] end,
                    [55]  = function() tToggles[7] = not tToggles[7] end,
                    [56]  = function() tToggles[8] = not tToggles[8] end,
                    [57]  = function() tToggles[9] = not tToggles[9] end,
                    [58]  = function() tToggles[BANKPROG] = not tToggles[BANKPROG] end, -- b = bank/program select
                    [110] = function() tToggles[NOTATION] = not tToggles[NOTATION] end, -- n = notation
                    [116] = function() tToggles[TEXT] = not tToggles[TEXT] end,
                    [115] = function() tToggles[SYSEX] = not tToggles[SYSEX] end,
                    [99]  = function() tToggles = {} end, -- c = clear all
                    [117] = function() tToggles = {} for i,k in pairs(tUsedCCs) do tToggles[i] = k end end -- u = show only used lanes
                   }             

helpText = [[CC lanes can be selected by clicking with the mouse, or by using these shortcuts for commonly used CC types:
  
    v = Velocity
    p = Pitchbend
    m = CC1, Modwheel
    e = CC11, Expression
    h = CC64, Hold/Sustain pedal
    1-9 = CCs 1-9
    n = Notation
    t = Text
    s = Sysex
    b = Bank/program select
    
    c = Clear all
    u = Show only used lanes
    esc   = Exit without applying changes
    enter or a = Exit and apply changes
    
The GUI can be resized, and the last-used dimensions will be recalled when the script is run again.]]

tips092 = helpText .. "\n\nTo view these tips again, right-click in the script GUI."
                   .. "\n\nFor more information, please refer to the Description and Instructions inside the script file."

  

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
            if lane == 187 or lane == 189 then -- Draw the "Only used" and "Clear" buttons separately with 3D shadows
                setColor(colorUsedClear)
                gfx.line(gfx.x, gfx.y, gfx.x+rectWidth-1, gfx.y)
                gfx.line(gfx.x, gfx.y, gfx.x, gfx.y+rectHeight-1)
                gfx.r, gfx.g, gfx.b = gfx.r*0.8, gfx.g*0.8, gfx.b*0.8 -- a bit darker
                gfx.rect(gfx.x+1, gfx.y+1, rectWidth-2, rectHeight-2, true)
                gfx.r, gfx.g, gfx.b = gfx.r*0.7, gfx.g*0.7, gfx.b*0.7 -- a bit darker
                gfx.line(gfx.x, gfx.y+rectHeight-1, gfx.x+rectWidth-1, gfx.y+rectHeight-1)
                gfx.line(gfx.x+rectWidth-1, gfx.y+1, gfx.x+rectWidth-1, gfx.y+rectHeight-1)
                setColor(colorBackground)
                gfx.drawstr(tNames[lane], 5, gfx.x+rectWidth-1, gfx.y+rectHeight-1)
            elseif lane == 191 then -- "Apply" button
                setColor(colorApply)
                gfx.line(gfx.x, gfx.y, gfx.x+rectWidth-1, gfx.y)
                gfx.line(gfx.x, gfx.y, gfx.x, gfx.y+rectHeight-1)
                gfx.r, gfx.g, gfx.b = gfx.r*0.8, gfx.g*0.8, gfx.b*0.8 -- a bit darker
                gfx.rect(gfx.x+1, gfx.y+1, rectWidth-2, rectHeight-2, true)
                gfx.r, gfx.g, gfx.b = gfx.r*0.7, gfx.g*0.7, gfx.b*0.7 -- a bit darker
                gfx.line(gfx.x, gfx.y+rectHeight-1, gfx.x+rectWidth-1, gfx.y+rectHeight-1)
                gfx.line(gfx.x+rectWidth-1, gfx.y+1, gfx.x+rectWidth-1, gfx.y+rectHeight-1)
                setColor(colorBackground)
                gfx.drawstr(tNames[lane], 5, gfx.x+rectWidth-1, gfx.y+rectHeight-1)
            else
                if tUsedCCs[lane] then str = "● " else str = "   " end
                if tNumbers[lane] then str = str .. tNumbers[lane] .. ": " end
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
        if chunk:match("\n<[xX] [%-%d]+ [^\n]-\n/w9") then
            tUsedCCs[NOTATION] = true
        end
        
        -- Any text events?
        if chunk:match("\n<[xX] [%-%d]+ 0 0 0") then
            tUsedCCs[TEXT] = true
        end
        
        -- Any sysex events?
        if chunk:match("\n<[xX] [%-%d]+ [^\n]-\n[^/]") then
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
                MIDIEditorCCLaneHeight = math.floor(math.max(25, math.min(MIDIEditorHeight/4, (MIDIEditorHeight/3)/numLanes)))
            else
                MIDIEditorCCLaneHeight = 50
            end
            
            local laneHeightStr = " " .. string.format("%i", MIDIEditorCCLaneHeight) .. " " .. string.format("%i", inlineCCLaneHeight)
                    
            -- Do 160 to 168 first, since I prefer these lanes to be on top
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
                editor = reaper.MIDIEditor_GetActive() -- Not local, so that script can check whether called from main MIDI editor
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
  
    -- Check whether items have MIDI takes
    for item, chunk in pairs(tChunks) do
        if not chunk:find("<SOURCE MIDI") then tChunks[item] = nil end
    end
end

----------------------
function countChunksAndTracks()
    local tTracks = {}
    local numChunks, numTracks = 0, 0
    for item, chunk in pairs(tChunks) do
        numChunks = numChunks + 1
        local track = reaper.GetMediaItemTrack(item)
        if reaper.ValidatePtr2(0, track, "MediaTrack*") then
            if not tTracks[track] then
                tTracks[track] = true
                numTracks = numTracks + 1
            end
        end
    end
    return numChunks, numTracks
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
    elseif c == 13 or c == 97 then -- enter or a: apply and quit
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
    elseif gfx.mouse_cap&2 == 2 and not mouseAlreadyDown then -- right mouse click
        reaper.MB(helpText, "Help:  Select CC lanes to show", 0)
    elseif gfx.mouse_cap&1 == 0 then
        mouseAlreadyDown = false
    end
    
    reaper.runloop(loop)
end

-----------------------------
function getCCNamesForTrack()
    local item, chunk = next(tChunks)
    if reaper.ValidatePtr2(0, item, "MediaItem*") then
        channelStr = chunk:match("\nCFGEDIT [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ (%d+) ")
        channel = tonumber(channelStr)
        if not channel then channel = 0 end
        local track = reaper.GetMediaItemTrack(item)
        if reaper.ValidatePtr2(0, track, "MediaTrack*") then
            for cc = 0, 127 do
                local name = reaper.GetTrackMIDINoteNameEx(0, track, cc+128, 0)
                if name then
                    tNames[cc] = name
    end end end end
    
    -- Update 14bit CC lane names.  14bit lanes will only have names if the MSB and LSB lanes have similar names.
    for i = 128, 159 do
        if type(tNames[i-128]) == "string"
        and type(tNames[i-96]) == "string" 
        and tNames[i-128]:gsub("%s", "") ~= ""
        and tNames[i-128]:gsub("[mlsbMLSB%s%p%c]", "") == tNames[i-96]:gsub("[mlsbMLSB%s%p%c]", "") 
        then 
            tNames[i] = tNames[i-128]:gsub("MSB", ""):gsub("msb", ""):gsub("[%p%s%c]*$", "") .. " (14bit)"
        else
            tNames[i] = nil
        end
    end
end

---------------
function exit()
    -- Find and store the last-used dimensions of the GUI window, so that it can be re-opened at the same position
    if type(prevW) == "number" and type(prevH) == "number" then
        reaper.SetExtState("Select CC lanes to show", "Last dimensions", string.format("%i", math.floor(prevW+0.5)) .. "," .. string.format("%i", math.floor(prevH+0.5)), true)
    end
  
    gfx.quit()
    reaper.UpdateArrange()
  
    -- Re-focus MIDI editor (current API can unfortunately not focus inline editor)
    if editor and reaper.APIExists("SN_FocusMIDIEditor") then
        reaper.SN_FocusMIDIEditor()
    end
  
    reaper.Undo_OnStateChange2(0, "Select CC lanes to show") 
end


------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- Here execution starts!
-- function main()

-- Get mouse position and chunks before showing startup tips (since mouse will move)
getAllChunks()

numChunks, numTracks = countChunksAndTracks()
if numChunks == 0 then -- no selected items
    return 
elseif numChunks == 1 then -- only one item, so can customize
    setTogglesToCurrentlyVisible() 
end

-- If only one track, can customize CC names
if numTracks == 1 then getCCNamesForTrack() end

findUsedLanes()

-- Show new version tips
lastTipVersion = tonumber(reaper.GetExtState("Select CC lanes to show", "Last tip version")) or 0
if lastTipVersion < 0.92 then
    reaper.MB(tips092, "Startup tips: v0.92", 0)
    reaper.SetExtState("Select CC lanes to show", "Last tip version", 0.92, true)
end

-- Start the GUI!
lastWidth, lastHeight = (reaper.GetExtState("Select CC lanes to show", "Last dimensions")):match("(%d+),(%d+)")
if lastWidth and lastHeight then
    GUIWidth, GUIHeight = tonumber(lastWidth), tonumber(lastHeight)
else
    GUIWidth, GUIHeight = 960, 504
end
gfx.init("Select CC lanes to show", GUIWidth, GUIHeight, 0)
drawGUI()

reaper.atexit(exit)
loop()

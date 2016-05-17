--[[
 * ReaScript Name:  2-sided warp (and stretch) selected events in lane under mouse.
 * Description:  A simple script for warping and stretching the positions of MIDI events.
 *               The script only affects events in the MIDI editor lane under the mouse cursor.
 *               NB: Useful for changing a linear CC ramp into more complex logistic-type curves.
 *               NB: Useful for accelerating and decelerating a series of evenly spaced notes, as is typical in a trill.
 * Instructions:  The script must be linked to a shortcut key.  
 *                To use, 1) select MIDI events to be stretched,  
 *                        2) position mouse in lane, *within* range of CC events 
 *                        3) press shortcut key, and
 *                        4) move mouse left or right to stretch to the corresponding side,
 *                           move mouse up or down to warp towards or away from mouse.
 *                        5) To exit, move mouse out of CC lane, or press shortcut key again.
 * Screenshot: 
 * Notes: 
 * Category: 
 * Author: juliansader
 * Licence: GPL v3
 * Forum Thread: 
 * Forum Thread URL: http://forum.cockos.com/showthread.php?t=176878
 * Version: 1.0
 * REAPER: 5.20
 * Extensions: SWS/S&M 2.8.3
]]
 

--[[
 Changelog:
 * v1.0 (2016-05-15)
    + Initial Release
]]

editor = reaper.MIDIEditor_GetActive()
take = reaper.MIDIEditor_GetTake(editor)
window, segment, details = reaper.BR_GetMouseCursorContext()

-- Mouse must be positioned in CC lane
if details ~= "cc_lane" then return(0) end

-- ! SWS documentation is incorrect: NO retval is returned
-- ! by BR_GetMouseCursorContext_MIDI()
-- The 'type' of the second variable returned can perhaps distinguish between 
--     versions of this function.
_, test, mouseLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI() 
if type(test) == boolean then
    reaper.ShowConsoleMsg("Error: Probably incompatible SWS version")
    return(0)
end

-- The selected events will be divided into two arrays:
--    those positioned to the left of the mouse, and those to the right,
--    so that they can be warped separately
mouseStartTime = reaper.BR_GetMouseCursorContext_Position()
mouseStartPPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouseStartTime)
eventsL = {}
eventsR = {}

--------------------------------------------------------------------
-- Find events in mouse lane.
-- sysex and text events are weird, so use different "Get" function

-- mouseLane = "CC lane under mouse cursor (CC0-127=CC, 0x100|(0-31)=14-bit CC, 
-- 0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 
-- 0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity)"

if mouseLane == 0x206 or mouseLane == 0x205 -- sysex and text events
    then
    eventIndex = reaper.MIDI_EnumSelTextSysexEvts(take, -1)
    while(eventIndex ~= -1) do
        _, _, _, eventPPQpos, eventType, msg = reaper.MIDI_GetTextSysexEvt(take, eventIndex)
        if (mouseLane == 0x206 and eventType == -1) -- only sysex
        or (mouseLane == 0x205 and eventType ~= -1) -- only text events
            then
            if eventPPQpos <= mouseStartPPQpos then
                table.insert(eventsL, {index = eventIndex,
                                       PPQ = eventPPQpos,
                                       msg = msg,
                                       type = 0xF})
            else
                table.insert(eventsR, {index = eventIndex,
                                       PPQ = eventPPQpos,
                                       msg = msg,
                                       type = 0xF})
            end           
        end
        eventIndex = reaper.MIDI_EnumSelTextSysexEvts(take, eventIndex)
    end

else  -- all other event types that are not sysex or text

    eventIndex = reaper.MIDI_EnumSelEvts(take, -1)
    while(eventIndex ~= -1) do
    
        _, _, _, eventPPQpos, msg = reaper.MIDI_GetEvt(take, eventIndex, true, true, 0, "")
        msg1=tonumber(string.byte(msg:sub(1,1)))
        msg2=tonumber(string.byte(msg:sub(2,2)))
        eventType = msg1>>4

        -- Now, select only event types that correspond to mouseLane:
        if (0 <= mouseLane and mouseLane <= 127 -- CC, 7 bit (single lane)
            and msg2 == mouseLane and eventType == 11)
        or (256 <= mouseLane and mouseLane <= 287 -- CC, 14 bit (double lane)
            and (msg2 == mouseLane-256 or msg2 == mouseLane-224) and eventType ==11) -- event can be from either MSB or LSB lane
        or ((mouseLane == 0x200 or mouseLane == 0x207) -- Velocity or off-velocity
            and (eventType == 9 or eventType == 8)) -- note on or note off
        or (mouseLane == 0x201 and eventType == 14) -- pitch
        or (mouseLane == 0x202 and eventType == 12) -- program select
        or (mouseLane == 0x203 and eventType == 13) -- channel pressure (after-touch)
        or (mouseLane == 0x204 and eventType == 12) -- Bank/Program select - Bank select
        or (mouseLane == 0x204 and eventType == 12) -- Bank/Program select - Program select
        or (mouseLane == 0x204 and eventType == 11 and msg2 == 0) -- Bank/Program select - Bank select MSB
        or (mouseLane == 0x204 and eventType == 11 and msg2 == 32) -- Bank/Program select - Bank select LSB
            then
            if eventPPQpos <= mouseStartPPQpos then
                table.insert(eventsL, {index = eventIndex,
                                       PPQ = eventPPQpos,
                                       msg = msg,
                                       type = 0xF})
            else
                table.insert(eventsR, {index = eventIndex,
                                       PPQ = eventPPQpos,
                                       msg = msg,
                                       type = 0xF})
            end             
        end
        eventIndex = reaper.MIDI_EnumSelEvts(take, eventIndex)
    end
end    

--------------------------------------------------------------
-- If too few events are selected, there is nothing to warp
if (#eventsL + #eventsR < 3)
or (256 <= mouseLane and mouseLane <= 287 and #eventsL + #eventsR < 6)
or (mouseLane == 0x204 and #eventsL + #eventsR < 6)
    then return(0) 
end

------------------------------------------------------------------------------------------
-- Find first and last PPQ of events
-- Take care if mouse position is outside range of events, and eventsL or eventsR is emtpy
if #eventsL > 0 then
    tempFirstPPQ = eventsL[1].PPQ
    tempLastPPQ = eventsL[1].PPQ
    for i=2, #eventsL do
        if eventsL[i].PPQ < tempFirstPPQ then tempFirstPPQ = eventsL[i].PPQ
        elseif eventsL[i].PPQ > tempLastPPQ then tempLastPPQ = eventsL[i].PPQ
        end
    end
    firstPPQposL = tempFirstPPQ
    lastPPQposL = tempLastPPQ
    PPQrangeL = mouseStartPPQpos - firstPPQposL
end

if #eventsR > 0 then
    tempFirstPPQ = eventsR[1].PPQ
    tempLastPPQ = eventsR[1].PPQ
    for i=2, #eventsR do
        if eventsR[i].PPQ < tempFirstPPQ then tempFirstPPQ = eventsR[i].PPQ
        elseif eventsR[i].PPQ > tempLastPPQ then tempLastPPQ = eventsR[i].PPQ
        end
    end
    firstPPQposR = tempFirstPPQ
    lastPPQposR = tempLastPPQ
    PPQrangeR = lastPPQposR - mouseStartPPQpos  
end

if #eventsL > 0 and #eventsR > 0 then
    eventsPPQrange = lastPPQposR - firstPPQposL
elseif #eventsL == 0 then
    eventsPPQrange = PPQrangeR
elseif #eventsR == 0 then
    eventsPPQrange = PPQrangeL
end

---------------------------------------------------------------------------
-- Finally, here is the warping function that will be looped by 'deferring'

function loop_warpStretch()
    _, _, newDetails = reaper.BR_GetMouseCursorContext()
    _, _, newMouseLane, newMouseLaneValue, _ = reaper.BR_GetMouseCursorContext_MIDI()
    -- Function exits if mouse is moved out of CC lane
    if newDetails ~= "cc_lane" or newMouseLane ~= mouseLane then --or newMouseLaneValue==-1 then
        return(0)
    end
    mouseNewTime = reaper.BR_GetMouseCursorContext_Position()
    mouseNewPPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouseNewTime)
    -- Prevent warping and stretcthing out of original PPQ range of events
    --if mouseNewPPQpos >= lastPPQposR then mouseNewPPQpos = lastPPQposR-1 end
    --if mouseNewPPQpos <= firstPPQposL then mouseNewPPQpos = firstPPQposL+1 end
    
    -- The warping uses a power function, and the power variable is determined
    --     by calculating to what power 0.5 must be raised to reach the 
    --     mouse's deviation  mouse's deviation above or below the middle of the CC lane.
    -- Why use absolute value?  Since power>1 gives a nicer, more 'musical looking'
    --     shape than power<1.     
    -- Remember to check whether lane is 7 bit, or 14 bit or pitchbend.
    if (256 <= mouseLane and mouseLane <= 287) -- 14 bit CC
    or (mouseLane == 0x201) then -- pitchbend 
        mouseDirection = newMouseLaneValue-8192
        mouseWarp = 0.5 + math.abs(mouseDirection)/16384
    else
        mouseDirection = newMouseLaneValue-64
        mouseWarp = 0.5 + math.abs(mouseDirection)/128
    end
    -- Prevent warping too much, so that all CCs don't end up in a solid block
    if mouseWarp > 0.99 then mouseWarp = 0.99
    --elseif mouseWarp < 0.01 then mouseWarp = 0.01
    end
    power = math.log(mouseWarp, 0.5)
    
    if #eventsL > 0 then
        stretchedPPQrangeL = mouseNewPPQpos - firstPPQposL
        stretchFactorL = stretchedPPQrangeL/PPQrangeL
    end
    if #eventsR > 0 then
        stretchedPPQrangeR = lastPPQposR - mouseNewPPQpos
        stretchFactorR = stretchedPPQrangeR/PPQrangeR
    end
    
    -- Draw the events in eventsL
    for i=1, #eventsL do
        -- First, stretch linearly:
        newPPQpos = firstPPQposL + (eventsL[i].PPQ - firstPPQposL)*stretchFactorL
        -- Then, warp using power function:
        if mouseDirection > 0 then
            newPPQpos = firstPPQposL + (((newPPQpos - firstPPQposL)/stretchedPPQrangeL)^power)*stretchedPPQrangeL
        elseif mouseDirection < 0 then
            newPPQpos = mouseNewPPQpos - (((mouseNewPPQpos - newPPQpos)/stretchedPPQrangeL)^power)*stretchedPPQrangeL
        end
        
        if mouseLane == 0x205 or mouseLane == 0x206 then
            reaper.MIDI_SetTextSysexEvt(take, eventsL[i].index, nil, nil, newPPQpos, nil, eventsL[i].msg, true)
        else    
            reaper.MIDI_SetEvt(take, eventsL[i].index, nil, nil, newPPQpos, eventsL[i].msg, true) -- Strange: according to the documentation, msg is optional
        end
    end
    
    -- Draw the events in eventsR
    for i=1, #eventsR do
        -- First, stretch linearly:
        newPPQpos = lastPPQposR - (lastPPQposR - eventsR[i].PPQ)*stretchFactorR
        -- Then, warp using power function:
        if mouseDirection > 0 then
            newPPQpos = lastPPQposR - (((lastPPQposR - newPPQpos)/stretchedPPQrangeR)^power)*stretchedPPQrangeR
        elseif mouseDirection < 0 then
            newPPQpos = mouseNewPPQpos + (((newPPQpos - mouseNewPPQpos)/stretchedPPQrangeR)^power)*stretchedPPQrangeR
        end
      
        if mouseLane == 0x205 or mouseLane == 0x206 then
            reaper.MIDI_SetTextSysexEvt(take, eventsR[i].index, nil, nil, newPPQpos, nil, eventsR[i].msg, true)
        else    
            reaper.MIDI_SetEvt(take, eventsR[i].index, nil, nil, newPPQpos, eventsR[i].msg, true) -- Strange: according to the documentation, msg is optional
        end
    end
    
    -- Loop the function continuously
    reaper.defer(loop_warpStretch)
end -- function loop_warpStretch()

-----------------------------------------------------------------------

function exit()
    reaper.MIDI_Sort(take)
    if mouseLane == 0x206 then
        undoString = "2-sided warp and stretch events: Sysex"
    elseif mouseLane == 0x205 then
        undoString = "2-sided warp and stretch events: Text events"
    elseif 0 <= mouseLane and mouseLane <= 127 then -- CC, 7 bit (single lane)
        undoString = "2-sided warp and stretch events: 7 bit CC, lane ".. tostring(mouseLane)
    elseif 256 <= mouseLane and mouseLane <= 287 then -- CC, 14 bit (double lane)
        undoString = "2-sided warp and stretch events: 14 bit CC, lanes ".. tostring(mouseLane-256) .. "/" .. tostring(mouseLane-224)
    elseif mouseLane == 0x200 or mouseLane == 0x207 then -- Velocity or off-velocity
        undoString = "2-sided warp and stretch events: Notes"
    elseif mouseLane == 0x201 then -- pitch
        undoString = "2-sided warp and stretch events: Pitchwheel"
    elseif mouseLane == 0x202 then -- program select
        undoString = "2-sided warp and stretch events: Program Select"
    elseif mouseLane == 0x203 then -- channel pressure (after-touch)
        undoString = "2-sided warp and stretch events: Channel Pressure"
    elseif mouseLane == 0x204 then -- Bank/Program select - Program select
        undoString = "2-sided warp and stretch events: Bank/Program Select"
    else              
        undoString = "2-sided warp and stretch events"
    end -- if mouseLane ==
    
    reaper.Undo_OnStateChange(undoString, -1)
end

reaper.atexit(exit)

loop_warpStretch()


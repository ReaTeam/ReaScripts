-- @description Link Multichannel FXs Parameters
-- @author Alberto V5
-- @version 1.0
-- @changelog First release. Supports VST and VST3.
-- @about
--   # Link Multichannel FXs Parameters
--
--   This script converts any plugin with external sidechain capabilities into a multichannel FX in order to ease the workflow of processing multiple channels for stem delivery.
--
--   This script finds the last touched FX on the selected Track and creates multiple copies of it, then links all the copies to the original and sets up multichannel routing so each FX is connected to a different pair of channels but all of them receive sidechain input from the last pair of pins.
--
--   Recommended use is to create a new track and insert a new FX, then load any presets or change any parameters for a start and then run this script. You can then route your multi-tracks or buses into the channels of this new track. Then tweak the parameters of the first FX as you would normally do and the rest will follow because they are linked as if you had linked them manually but this script already did all the prep work for you.
--
--   Key features:
--   1. JSFX is not yet supported.
--   2. VST and VST3 supported and tested.
--   3. Pop up menus for user input.
--   4. Modify the global variables at the top of the script for extra functionalities
--   5. This doesn't link across tracks as it's not a Reaper feature, other scripts out there do that!
--
--   Know issues:
--   1. Some FXs don't let settings like oversampling or linear phase to be linked so set those before running this script!
--   2. Some FXs don't support modifying or linking values from outside their interface so there is no way around that!
--   3. Because the FXs are in series even if passing through the unmapped pins, the PDC remains as if they were in series anyway so the total PDC of the track can increase dramatically.
--
--   Reach out if you would like me to support JSFX or add other features.

-- Link Multichannel FX Parameters
-- MIT License

-- Copyright (c) 2022 AlbertoV5

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

--avq5ac1@gmail.com

-- Customize these if you like:
REARRANGE_FX_WINDOWS = false
MODIFY_CHANNEL_COUNT = true
SET_PIN_MAPPINGS = true
LINK_PARAMETERS = true

FX_RANGE = {0,6}
FX_PARAM_RANGE = {0,9999}
SCREEN_WIDTH = {0, 1920}
SCREEN_HEIGHT = {0, 1080}

-- Attributes
MB_TITLE = "Link Multichannel FX Parameters"
SELECTED_TRACK = nil
FX_NAME = ""
TRACK_STATE_CHUNK = ""

--
-- Utility functions
--

function Print(message)
    return reaper.ShowConsoleMsg(tostring(message).."\n")
end

function Split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function Join(array, delimiter)
    fxStringNew = ""
    for i = 1, #array, 1 do
        fxStringNew = fxStringNew..array[i]..delimiter
    end
    return fxStringNew:sub(1, -2)
end

function GetUserInput_Int(message)
    local retval, response = reaper.GetUserInputs(MB_TITLE, 1, message, "")
    if retval then return math.floor(tonumber(response)) else return 0 end
end

function GetUserInput_YesNo(message)
    if reaper.MB(message, MB_TITLE, 4) == 6 then return true else return false end
end

--
-- General Functions
--

-- Deals with strings that contain separators but have no line breaks, example: <text<text>text
local function cleanArray(dirtyArray, condition, separator)
    local array = {}
    local c = 2
    while (c < #dirtyArray+1) do
        if dirtyArray[c]:find(condition) == nil then
            table.insert(array, dirtyArray[c]..separator..dirtyArray[c + 1])
            c = c + 2
        else
            table.insert(array, dirtyArray[c])
            c = c + 1
        end
    end
    return array
end

-- Uses the size of the window to position it in the screen within the other FXs
local function calculateFxWindowPosition(floatPosString, fxPosition)
    local s = " "
    local array = Split(floatPosString, s)
    local w = tonumber(array[4])
    local h = tonumber(array[5])


    local columns = math.floor(SCREEN_WIDTH[2]/w)
    local rows = math.floor(SCREEN_HEIGHT[2]/h)

    local column = math.floor(fxPosition/rows)
    local row = fxPosition - (column*rows)

    local x = SCREEN_WIDTH[1] + (w * column)
    local y = SCREEN_HEIGHT[1] + (h * row)

    return "FLOATPOS "..tostring(x)..s..tostring(y)..s..tostring(w)..s..tostring(h)
end

-- Template for Program Env https://github.com/ReaTeam/Doc/blob/master/State%20Chunk%20Definitions
local function defineProgramEnv(fxParamIndex, fxPosition)

    local programEnv = "<PROGRAMENV "..tostring(fxParamIndex)..":"..tostring(fxParamIndex).." 0\nPARAMBASE 0\nLFO 0\nLFOWT 1 1\nAUDIOCTL 0\nAUDIOCTLWT 1 1\nPLINK 1 "
    programEnv = programEnv..tostring(0)..":"..tostring(-fxPosition).." "

    return programEnv..tostring(fxParamIndex)..":"..tostring(fxParamIndex).." 0\nMODWND 0 232 146 580 423\n>\n"
end

-- Insert new line at exact index
local function insertLineInString(fxString, index, newLine)
    local array = Split(fxString, "\n")
    table.insert(array, #array+index, newLine)
    return Join(array, "\n")
end

-- Avoid unnecesary iterations later on
local function checkForFxParamLimit()
    local fxParamMax = reaper.TrackFX_GetNumParams(SELECTED_TRACK, FX_RANGE[1])
    if FX_PARAM_RANGE[2] > fxParamMax then FX_PARAM_RANGE = {FX_PARAM_RANGE[1], fxParamMax} end
end

local function modifyChannelCount()
    return reaper.SetMediaTrackInfo_Value(SELECTED_TRACK, "I_NCHAN", FX_RANGE[2]*2) 
end

local function getTrackStateChunk()
    RETVAL, TRACK_STATE_CHUNK = reaper.GetTrackStateChunk(SELECTED_TRACK, "", true)
    return RETVAL
end

local function setTrackStateChunk()
    local retval = reaper.SetTrackStateChunk(SELECTED_TRACK, TRACK_STATE_CHUNK, true)
    return retval
end

local function getLastTouchedFX()
    local retval, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
    local retval, fxName = reaper.TrackFX_GetFXName(SELECTED_TRACK, fxnumber)
    FX_RANGE[1] = fxnumber
    FX_NAME = fxName
    return retval
end

local function getSelectedTrack()
    if reaper.CountSelectedTracks(0) == 0 then return false end
    SELECTED_TRACK = reaper.GetSelectedTrack(0,0)
    return true
end

--
-- State chunk functions
--
-- Functions designed to receive a state chunk like string and modify it
local CHUNKER = {
    -- Create multiple Program Env as a string. fxStringArray checks if string is last element on TrackStateChunk
    linkParameters = function(fxString, fxPosition)
        if fxPosition == FX_RANGE[1] or fxPosition > FX_RANGE[2] then
            return fxString
        end
    
        local programEnvs = ""
        for i = FX_PARAM_RANGE[1], FX_PARAM_RANGE[2], 1 do
            programEnvs = programEnvs..defineProgramEnv(i, fxPosition)
        end
    
        local fxStringArray = Split(fxString, "\n")
    
        if fxStringArray[#fxStringArray-1] == ">" then
            return insertLineInString(fxString, -2, programEnvs:sub(1, -2))
        end
    
        return insertLineInString(fxString, -1, programEnvs:sub(1, -2))
    end,
    -- Replaces FloatPos with new x, y values
    rearrangeFloatingWindows = function(fxString, fxPosition)
        local subArray = Split(fxString, "\n")
            
        for i = 1, #subArray, 1 do
            if subArray[i]:sub(1,8) == "FLOATPOS" then
                subArray[i] = calculateFxWindowPosition(subArray[i], fxPosition)
            end
        end
        return Join(subArray, "\n")
    end
}
--
-- Main functions
--
-- Set the mappings of all the FXs in the track in sequence, Sidechain key at the end https://forum.cockos.com/showpost.php?p=2123875&postcount=2
local function setPinMappings()

    local numberOfFXs = reaper.TrackFX_GetCount(SELECTED_TRACK)

    --Bit shift these values to start from a different channel, SC at the end
    local pinL, pinR = 1, 2
    local sidechainL, sidechainR = pinL << (numberOfFXs-1)*2, pinR << (numberOfFXs-1)*2

    for fxNum = 0, numberOfFXs-1 do
        reaper.TrackFX_SetPinMappings(SELECTED_TRACK, fxNum, 0, 2, sidechainL,0)
        reaper.TrackFX_SetPinMappings(SELECTED_TRACK, fxNum, 0, 3, sidechainR,0)
        reaper.TrackFX_SetPinMappings(SELECTED_TRACK, fxNum, 0, 0, pinL,0) --pin l in
        reaper.TrackFX_SetPinMappings(SELECTED_TRACK, fxNum, 0, 1, pinR,0) --pin r in
        reaper.TrackFX_SetPinMappings(SELECTED_TRACK, fxNum, 1, 0, pinL,0) --pin l out
        reaper.TrackFX_SetPinMappings(SELECTED_TRACK, fxNum, 1, 1, pinR,0) --pin r out

        pinL = pinL * 4
        pinR = pinR * 4
    end

end

-- Opens and closes FX in order for Reaper to update the TrackStateChunk for arranging windows later
local function createCopiesOfFX()
    for i = 1, FX_RANGE[2]-1, 1 do
        reaper.TrackFX_CopyToTrack(SELECTED_TRACK, FX_RANGE[1], SELECTED_TRACK, FX_RANGE[1]+i, false)
        if REARRANGE_FX_WINDOWS then
            reaper.TrackFX_Show(SELECTED_TRACK, FX_RANGE[1]+i, 3)
            reaper.TrackFX_Show(SELECTED_TRACK, FX_RANGE[1]+i, 2)
        end
    end
end

-- Returns a modified TrackStateChunk. Pass a function so it is called within the loop.
local function modifyTrackStateChunk(method)

    local chunks = cleanArray(Split(TRACK_STATE_CHUNK, "<"), "\n", "<")
    local fxPosition = FX_RANGE[1]

    for i=1, #chunks, 1 do

        local header = Split(chunks[i], "\n")[1]

        if header:sub(1, 3) == "VST" then
            chunks[i] = method(chunks[i], fxPosition)
            fxPosition = fxPosition + 1
        end

        -- Work in progress
        if header:sub(1, 2) == "JS" then
            local jsBehavesDifferently = "idk"
        end
    end

    TRACK_STATE_CHUNK = "<"..Join(chunks, "<")
end

-- Main focused on verifying as much as possible
function Main()

    if not getSelectedTrack() then
        return reaper.MB("No Tracks Selected", MB_TITLE, 0)
    end
    if not getLastTouchedFX() then
        return reaper.MB("Could not find last touched FX", MB_TITLE, 0)
    end
    if GetUserInput_YesNo("Copy "..FX_NAME.."?", MB_TITLE) then
        FX_RANGE[2] = GetUserInput_Int("Copies of "..FX_NAME:sub(1,12), MB_TITLE) + 1
        createCopiesOfFX()
    else
        FX_RANGE[2] = GetUserInput_Int("Amount of FXs to link: ", MB_TITLE)
    end

    checkForFxParamLimit()

    if not getTrackStateChunk() then
        return reaper.MB("Could not obtain track state chunk", MB_TITLE, 0)
    end
    if REARRANGE_FX_WINDOWS then
        modifyTrackStateChunk(CHUNKER.rearrangeFloatingWindows)
    end
    if LINK_PARAMETERS then
        modifyTrackStateChunk(CHUNKER.linkParameters)
    end
    if not setTrackStateChunk() then
        return reaper.MB("Couldn't change track state chunk", MB_TITLE, 0)
    end
    if MODIFY_CHANNEL_COUNT then
        modifyChannelCount()
    end
    if SET_PIN_MAPPINGS then
        setPinMappings()
    end

    reaper.MB("Success", MB_TITLE, 0)

end

Main()


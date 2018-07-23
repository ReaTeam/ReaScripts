--[[
    Description: Adjust ReaSamplomatic 5000 pitch offset
    Version: 2.0.1
    Author: Lokasenna
    Donation: https://paypal.me/Lokasenna
    Changelog:
        Fix: FX name changes when loading a sample, script couldn't find it
    Links:
        Lokasenna's Website http://forum.cockos.com/member.php?u=10417
    About:
        Hotkey/MIDI functionality for adjusting the pitch of ReaSamplomatic 5000,
        offering a number of different options to suit different workflows.

        For use with MIDI CCs, bind a control knob to one of the Up actions
        and set it for Relative control. Binding a CC to the Down actions
        will work backwards.
    MetaPackage: true
    Provides:
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of ReaSamplomatic 5000 instances in selected tracks - Down 0.01 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of ReaSamplomatic 5000 instances in selected tracks - Down 0.1 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of ReaSamplomatic 5000 instances in selected tracks - Down 0.05 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of ReaSamplomatic 5000 instances in selected tracks - Down 0.5 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of ReaSamplomatic 5000 instances in selected tracks - Down 1 semitone.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of ReaSamplomatic 5000 instances in selected tracks - Reset to 0.0 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of ReaSamplomatic 5000 instances in selected tracks - Up 0.01 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of ReaSamplomatic 5000 instances in selected tracks - Up 0.1 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of ReaSamplomatic 5000 instances in selected tracks - Up 0.05 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of ReaSamplomatic 5000 instances in selected tracks - Up 0.5 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of ReaSamplomatic 5000 instances in selected tracks - Up 1 semitone.lua

        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of focused ReaSamplomatic 5000 - Down 0.01 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of focused ReaSamplomatic 5000 - Down 0.1 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of focused ReaSamplomatic 5000 - Down 0.05 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of focused ReaSamplomatic 5000 - Down 0.5 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of focused ReaSamplomatic 5000 - Down 1 semitone.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of focused ReaSamplomatic 5000 - Reset to 0.0 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of focused ReaSamplomatic 5000 - Up 0.01 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of focused ReaSamplomatic 5000 - Up 0.1 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of focused ReaSamplomatic 5000 - Up 0.05 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of focused ReaSamplomatic 5000 - Up 0.5 semitones.lua
        [main] . > Lokasenna_Adjust ReaSamplomatic 5000 pitch offset/Lokasenna_Adjust pitch offset of focused ReaSamplomatic 5000 - Up 1 semitone.lua

    Donation: https://www.paypal.me/Lokasenna
]]--

local MODE_FOCUSED = 0
local MODE_ALLSELECTED = 1

local PARAM_NUMBER = 15 -- RS5K's Pitch Offset parameter
local PARAM_MULTIPLIER =  0.0000625002384186    -- RS5K's internal value == 0.01 semitones

dm = false

local function dMsg(str)
   if dm then reaper.ShowConsoleMsg(tostring(str) .. "\n") end
end




local function parse_script_name()

    local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")

    local script_mode
    if string.match(script_name, "focused ReaSamplomatic") then
        script_mode = MODE_FOCUSED
    elseif string.match(script_name, "selected tracks") then
        script_mode = MODE_ALLSELECTED
    else
        return
    end
    
    local dir
    if string.match(script_name, " %- Up") then
        dir = 1
    elseif string.match(script_name, " %- Down") then
        dir = -1
    elseif string.match(script_name, " %- Reset") then
        dir = 0
    else
        return
    end

    local adjust_amt = string.match(script_name, "%s([%d%.]+)%ssemitone")
    if adjust_amt then
        adjust_amt = tonumber(adjust_amt) * dir
    else
        return
    end

    return script_mode, adjust_amt

end


local function convert_adjust_amt(adjust_amt)

    local new_val, fn, sID, cID, mode, res, val = reaper.get_action_context()
    return adjust_amt * 100 * PARAM_MULTIPLIER * ((mode > 0 and val ~= 0) and (math.abs(val) / val) or 1)

end


local function is_RS5K(name)

    name = string.lower(name)
    if string.match(name, "reasamplomatic") 
    or  string.match(name, "rs5k") then
        return true
    end

end


local function adjust_FX(media, istrack, idx, adjust_amt)

    local get = istrack and reaper.TrackFX_GetParam or reaper.TakeFX_GetParam
    local set = istrack and reaper.TrackFX_SetParam or reaper.TakeFX_SetParam

    local val, minvalOut, maxvalOut = get( media, idx, PARAM_NUMBER )

    set( media, idx, PARAM_NUMBER, (adjust_amt ~= 0) and val + adjust_amt or 0.5)

end




------------------------------------
-------- Focused Instance ----------
------------------------------------


local function get_FX_take(fxnumberOut)

    return fxnumberOut >> 16, fxnumberOut & 0xFFFF

end


local function take_FX_is_RS5K(take, idx)

    local retval, name = reaper.TakeFX_GetFXName(take, idx, "")
    return retval and is_RS5K(name)


end


local function adjust_focused(adjust_amt)

    local retval, tracknumberOut, itemnumberOut, fxnumberOut = reaper.GetFocusedFX()

    -- Adjust for the track given by GetFocusedFX counting from 1
    local track = reaper.GetTrack( 0, tracknumberOut - 1 )

    if not retval or retval == 0 then
        
        return
        
    elseif retval == 1 then

        adjust_FX(track, true, fxnumberOut, adjust_amt)

    elseif retval == 2 then

        local takenumberOut, fxnumberOut = get_FX_take(fxnumberOut)

        local item = reaper.GetTrackMediaItem( track, itemnumberOut )
        if not item then return end

        local take = reaper.GetMediaItemTake( item, takenumberOut )
        if not take then return end

        if take_FX_is_RS5K(take, fxnumberOut) then adjust_FX(take, false, fxnumberOut, adjust_amt) end

    end

end




------------------------------------
-------- Selected Tracks -----------
------------------------------------


local function SelectedTracks(proj, idx)

    if not idx then return SelectedTracks, proj or 0, -1 end

    idx = idx + 1
    local track = reaper.GetSelectedTrack(proj, idx)

    if track then return idx, track end

end


local function track_FX_is_RS5K(track, idx)

    local retval, name = reaper.TrackFX_GetFXName(track, idx, "")
    return retval and is_RS5K(name)


end


local function adjust_selected_tracks(adjust_amt)

    for idx, track in SelectedTracks() do

        for i = 0, reaper.TrackFX_GetCount(track) - 1 do

            if track_FX_is_RS5K(track, i) then adjust_FX(track, true, i, adjust_amt) end

        end

    end

end




local function Main()

    reaper.Undo_BeginBlock()

    local script_mode, adjust_amt = parse_script_name()
    if not (script_mode and adjust_amt) then return end

    --script_mode, adjust_amt = MODE_ALLSELECTED, 0.01
    dMsg("got mode: " .. tostring(script_mode))
    dMsg("got amt: " .. tostring(adjust_amt))

    adjust_amt = convert_adjust_amt(adjust_amt)

    if script_mode == MODE_FOCUSED then
        adjust_focused(adjust_amt)
    elseif script_mode == MODE_ALLSELECTED then
        adjust_selected_tracks(adjust_amt)
    end

    reaper.Undo_EndBlock("Adjust ReaSamplomatic 5000 pitch offset", -1)

end

Main()










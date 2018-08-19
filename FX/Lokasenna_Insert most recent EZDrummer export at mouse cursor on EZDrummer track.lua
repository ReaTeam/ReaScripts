--[[
    Description: Insert most recent EZDrummer export at mouse cursor on EZDrummer track
    Version: 1.0.0
    Author: Lokasenna
    Donation: https://paypal.me/Lokasenna
    Changelog:
        Initial Release
    Links:
        Forum Thread 
        Lokasenna's Website http://forum.cockos.com/member.php?u=10417
    About:
        On Linux, EZDrummer is unable to drag-and-drop MIDI loops into Reaper.
        This script provides a simple workaround: Drag a loop out of EZD, as
        normal, run the script, and the MIDI will be inserted on your EZD track 
        at the current mouse position (snapped to grid).
    Donation: https://www.paypal.me/Lokasenna
]]--

-- Change this line to the correct path:
local EZD_path = "~/.wine/drive_c/ProgramData/Toontrack/EZdrummer/"

local function Msg(str)
   reaper.ShowConsoleMsg(tostring(str) .. "\n")
end


local function findEZDTrack()

    for i = 0, reaper.GetNumTracks()-1 do
      
        local tr = reaper.GetTrack(0,i)
        local idx = reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")
        local _, name = reaper.GetTrackName(tr, "")
        if reaper.TrackFX_GetByName(tr, "EZdrummer", false) > -1 then
            --Msg("found on track " .. tostring(idx) .. ": " .. tostring(name))
            return tr
        end
        
    end

end

local function getEZDPath()

    local path = reaper.GetExtState("Lokasenna", "EZDrummer export path")
    if path and path ~= "" then return path end

    local ret, str = reaper.GetUserInputs(
        "Enter path:", 
        1, 
        "EZDrummer export path:,extrawidth=256", EZD_path)
    --Msg(tostring(str))
    if ret then
        reaper.SetExtState("Lokasenna", "EZDrummer export path", str, true)
        return str
    end

    --return path

end

local function getLastExport()

    local path = getEZDPath()
    if not path then return end

    --local str = reaper.ExecProcess( cmdline, -1 )
    local f = io.popen("ls -t " .. path .. "/*.mid")
    if not f then return end

    for line in f:lines() do
        return line
    end

end


local function setPosToMouse()

    reaper.SetEditCurPos(
        reaper.SnapToGrid(0, reaper.BR_PositionAtMouseCursor(true)), 
        false, 
        false)

end

local function Main()

    local track = findEZDTrack()
    if not track then return end
    
    local file = getLastExport()
    if not file then return end
    
    setPosToMouse()
    reaper.SetOnlyTrackSelected(track)
    reaper.InsertMedia(file, 8)

end

Main()

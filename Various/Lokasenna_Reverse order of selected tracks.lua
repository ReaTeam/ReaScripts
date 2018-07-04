--[[
    Description: Reverse order of selected tracks
    Version: 1.0.0
    Author: Lokasenna
    Donation: https://paypal.me/Lokasenna
    Changelog:
        Initial Release
    Links:
        Lokasenna's Website http://forum.cockos.com/member.php?u=10417
    About:
        Reverses the order of selected tracks. i.e. if 1-16 are selected then
        1 -> 16, 2 -> 15 ... 15 -> 2, 16 -> 1.

        NOTE: Will only work correctly with contiguous selections (no gaps).
    
]]--

dm = false
local function dMsg(str)
    if dm then reaper.ShowConsoleMsg(tostring(str) .. "\n") end
end


local function Main()

    local num_tracks = reaper.CountSelectedTracks(0)
    if num_tracks == 0 then return end
    
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    dMsg("Got " .. num_tracks .. " tracks")

    -- Make a table of mediatracks and current track numbers {tr = ..., idx = ...}
    local old = {}
    for i = 0, num_tracks - 1 do

        local tr = reaper.GetSelectedTrack(0, i)
        local idx = math.floor(reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER"))

        old[i] = {tr = tr, idx = idx}

        local ret, name = reaper.GetTrackName(tr, "")
        dMsg("\t" .. idx .. ": " .. name .. " -> " .. #old)

    end

    dMsg("Reordering...")

    for i = #old, 0, -1 do

        local ret, name = reaper.GetTrackName(old[i].tr, "")
        local idx = old[#old - i].idx
        dMsg("Moving " .. tostring(name) .. " to " .. tonumber(idx))
        reaper.SetOnlyTrackSelected(old[i].tr)
        reaper.ReorderSelectedTracks( old[#old - i].idx, 0 )

    end

    reaper.Undo_EndBlock("Reverse order of selected tracks", -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateTimeline()

end

Main()
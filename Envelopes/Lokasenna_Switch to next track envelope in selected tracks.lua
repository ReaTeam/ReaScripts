--[[
    Description: Switch to next track envelope in selected tracks
    Version: 1.0.0
    Author: Lokasenna
    Donation: https://paypal.me/Lokasenna
    Changelog:
        Initial Release
    Links:
        Lokasenna's Website http://forum.cockos.com/member.php?u=10417
    About:
        Allows you to flip through the main track envelopes (Volume, Pan,
        Width, Trim, Mute) one at a time, closing the others to avoid
        clutter.

        Note: Requires Reaper v5.95 or higher.
    Donation: https://www.paypal.me/Lokasenna
]]--


dm = false
local function dMsg(str)
   if dm then reaper.ShowConsoleMsg(tostring(str) .. "\n") end
end


local env_IDs = {
    ["Volume"] = 41866,
    ["Pan"] = 41868,
    ["Width"] = 41870,
    ["Trim Volume"] = 42020,
    ["Mute"] = 41871
}

local env_names = {
    "Volume",
    "Pan",
    "Width",
    "Trim Volume",
    "Mute",
}


local function set_env_chunk_visibility(chunk, show)

    local state = {chunk:match("(VIS) (.-) (.-) (.-)$")}
    state[2] = show and 1 or 0
    return chunk:gsub("VIS.-$", table.concat(state, " "))

end

local function get_env_chunk_visibility(chunk)

    return chunk:match("VIS (%S+)") == "1"

end


local function Main()

    -- Get selected MediaTracks
    local tracks = {}
    local count = reaper.CountSelectedTracks(0)
    if count == 0 then return end

    dMsg("count = " .. count)
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    for i = 1, count do
        tracks[i] = reaper.GetSelectedTrack(0, i-1)
    end

    local env_to_show

    for i = 1, #tracks do
        local track = tracks[i]
        for env_idx, name in ipairs(env_names) do

            local env = reaper.GetTrackEnvelopeByName(track, name)
            if env then
                local ret, chunk = reaper.GetEnvelopeStateChunk(env, "", false)
                if not env_to_show and get_env_chunk_visibility(chunk) then
                    env_to_show = env_names[env_idx % #env_names + 1]
                    dMsg("found env to show: " .. env_to_show)
                end
                dMsg("hiding track " .. i+1 .. ", env: " .. name)
                reaper.SetEnvelopeStateChunk(env, set_env_chunk_visibility(chunk, false))
            end

        end

    end

    env_to_show = env_to_show or "Volume"
    dMsg("\tto show: " .. env_to_show)       

    for _, track in pairs(tracks) do
        dMsg("applying to " .. _)
        reaper.SetOnlyTrackSelected(track)
        reaper.Main_OnCommand( env_IDs[env_to_show], 0 )    
    end
    
    -- Restore the track selection
    for _, track in pairs(tracks) do
        reaper.SetTrackSelected(track, true)
    end

    reaper.Undo_EndBlock("Switch to next track envelope in selected tracks", 0)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()

end

Main()
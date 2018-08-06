--[[
    Description: Set item start and end (spot mode)
    Version: 1.0.0
    Author: Lokasenna
    Donation: https://paypal.me/Lokasenna
    Changelog:
        Initial Release
    Links:
        Lokasenna's Website http://forum.cockos.com/member.php?u=10417
    About:
        Prompts for a start and end time from the user, then sets the selected
        item appropriately. Intended as a replacement for Pro Tools' "spot mode".
    Donation: https://www.paypal.me/Lokasenna
]]--



dm = false
local function dMsg(str)
   if dm then reaper.ShowConsoleMsg(tostring(str) .. "\n") end
end


-- seconds -> "HH:MM:SS (24H)"
-- Wrapped to 0 for each day
local function timeToString(t, twelve)

    dMsg("\ttime to string: " .. t)

    local h = math.modf(t / 3600)
    local left = t - h*3600
    local m = math.modf(left / 60)
    local s = left - m*60

    dMsg("\tgot h: " .. h .. ", m: " .. m .. ", s: " .. s)

    h = h % 24

    local suff = ""
    if twelve then

        suff = (h > 11 and " PM" or " AM")
        if h > 12 then 
            h = h - 12
        elseif h == 0 then
            h = 12
        end

    end


    return string.format("%02d", h) .. ":" .. string.format("%02d", m) .. ":" .. string.format("%0.6f", s) .. suff

end


function string.mmatch(str, pattern)

    local ret = {}
    for match in string.gmatch(str, pattern) do
        ret[#ret+1] = match
    end

    return table.unpack(ret)

end


-- "HH:MM:SS" (24h) -> seconds
local function stringToTime(str)

    local h, m, s = str:mmatch("([^:]+)")
    if not h then
        return
    elseif h and m then
        s = m
        m = h
        h = 0
    else
        s = h
        m = 0
        h = 0    
    end
    
    dMsg("stringToTime: " .. str)
    dMsg("\th, m, s = " .. h .. ", " .. m .. ", " .. s)
    dMsg("\treturning " .. h*3600+m*60+s.."\n")
    return h*3600 + m*60 + s

end


local function getTimes(item)

    local t_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local t_end = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") + t_start
    t_start, t_end = timeToString(t_start), timeToString(t_end)
-- retval, retvals_csv = reaper.GetUserInputs( title, num_inputs, captions_csv, retvals_csv )
    local ret, csv = reaper.GetUserInputs("Set item start and end", 2, "Start (s):,End (s):,extrawidth=48", t_start .. "," .. t_end)
    ret_start, ret_end = csv:match("([^,]+),([^,]+)")
    if not ret_start or not ret_end then return end

    return stringToTime(ret_start), stringToTime(ret_end)

end



local function Main()

    local item = reaper.GetSelectedMediaItem(0, 0)
    if not item then return end

    local t_start, t_end = getTimes(item)
    if not t_start then return end

    reaper.SetMediaItemInfo_Value(item, "D_POSITION", t_start)
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", t_end - t_start)

end

Main()
--[[
    Description: Show only specified tracks
    Version: 1.1.0
    Author: Lokasenna
    Donation: https://paypal.me/Lokasenna
    Changelog:
        Add: Options to find all matches and include children
        Add: Separate options for the TCP and MCP
        Add: Exported files prompt for a name rather than generating one
    Links:
        Lokasenna's Website http://forum.cockos.com/member.php?u=10417
    About:
        Allows quickly setting the visibility of multiple tracks based on a name search
        and several options.

        Also allows exporting of specific settings as a standalone action.
]]--

-- BEGIN FILE COPY HERE

local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
local script_filename = ({reaper.get_action_context()})[2]:match("([^/\\]+)$")


local function Msg(str)
    reaper.ShowConsoleMsg(tostring(str) .. "\n")
end


local function sanitize_filename(name)
    return string.gsub(name, "[^%w%s_]", "-")
end


-- Returns true if the individual words of str_b all appear in str_a
local function fuzzy_match(str_a, str_b)
    
    if not (str_a and str_b) then return end
    str_a, str_b = string.lower(tostring(str_a)), string.lower(tostring(str_b))
    
    --Msg("\nfuzzy match, looking for:\n\t" .. str_b .. "\nin:\n\t" .. str_a .. "\n")
    
    for word in string.gmatch(str_b, "[^%s]+") do
        --Msg( tostring(word) .. ": " .. tostring( string.match(str_a, word) ) )
        if not string.match(str_a, word) then return end
    end

    return true
    
end



local function is_match(str, tr_name, tr_idx)

    if tonumber(str) then

        -- Force an integer until/unless I come up with some sort of multiple track syntax
        str = math.floor( tonumber(str) )
        return str == tr_idx

    elseif tostring(str) then

        return fuzzy_match(tr_name, tostring(str))

    end

end

local function get_settings()

    local search = GUI.Val("txt_search")
    local opts = GUI.Val("chk_options")
    local apply = GUI.Val("chk_apply")

    return {
        search = search,
        all = opts[1],
        children = opts[2],
        tcp = apply[1],
        mcp = apply[2]
    }


end


local function get_tracks_to_show(settings)

    -- settings = {search = str, all = bool, children = bool, mcp = bool, tcp = bool}
    local tracks = {}
    local len_tracks = 0

    for i = 1, reaper.CountTracks(0) do

        local tr = reaper.GetTrack(0, i - 1)
        local _, name = reaper.GetTrackName(tr, "")
        local idx = reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")
        local ischild = reaper.GetTrackDepth(tr) > 0

        if is_match(settings.search, name, idx) and not (ischild and settings.nochildren) then
            tracks[idx] = true
            len_tracks = len_tracks + 1
            if not settings.all then break end
        else
            tracks[idx] = false
        end

    end

    return tracks

end


local function set_visibility(tracks, settings)

    if not tracks or #tracks == 0 then return end

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    for i = 1, reaper.CountTracks(0) do

        local tr = reaper.GetTrack(0, i - 1)
        if settings.tcp then
            reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINTCP", tracks[i] and 1 or 0)
        end
        if settings.mcp then
            reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINMIXER", tracks[i] and 1 or 0)
        end

    end

    reaper.PreventUIRefresh(-1)
    reaper.Undo_EndBlock("Show only specified tracks", -1)

    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()

end


if script_filename ~= "Lokasenna_Show only specified tracks.lua" then
    
    local tracks = get_tracks_to_show(settings)
    if tracks then
        set_visibility( tracks, settings )
    else
        reaper.MB("Error reading the script's settings. Make sure you haven't edited the script at all.", "Whoops!", 0)
    end
    
    return
    
end



-- END FILE COPY HERE


local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please run 'Set Lokasenna_GUI v2 library path.lua' in the Lokasenna_GUI folder.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Window.lua")()
GUI.req("Modules/Window - GetUserInputs.lua")()


-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end







------------------------------------
-------- Button functions ----------
------------------------------------


local function btn_go()
    
    local settings = get_settings()
    local tracks = get_tracks_to_show(settings)
    set_visibility(tracks, settings)
    
end


local function get_settings_to_export()

    local settings = get_settings()
    local strs = {
        'local settings = {',
        '\tsearch = "' .. settings.search .. '",',
        '\tall = ' .. tostring(settings.all) .. ',',
        '\tchildren = ' .. tostring(settings.children) .. ',',
        '\ttcp = ' .. tostring(settings.tcp) .. ',',
        '\tmcp = ' .. tostring(settings.mcp) .. ',',
        '}'
    }

    return table.concat(strs, "\n")

end


local function continue_export(alias)

    if not alias then return end
    alias = alias[1]
    if alias == "" then return end

    -- Copy everything from the file between the ReaPack header and GUI stuff
    local file_in, err = io.open(script_path .. script_filename, "r")
    if err then
        reaper.MB("Error opening source file:\n" .. tostring(err), "Whoops!", 0)
        return
    end

    local arr, copying = {}    
    --make sure to add a header tag, "generated by" etc.
    arr[1] = "-- This script was generated by " .. script_filename .. "\n"

    arr[2] = "\n" .. get_settings_to_export() .. "\n"

    for line in file_in:lines() do
        
        if copying then
            if string.match(line, "-- END FILE COPY HERE") then break end
            arr[#arr + 1] = line
        elseif string.match(line, "-- BEGIN FILE COPY HERE") then 
            copying = true
        end 
        
    end


    local name = "Lokasenna_Show only specified tracks - " .. alias

    -- Write the file
    local name_out = sanitize_filename(name) .. ".lua"
    local file_out, err = io.open(script_path .. name_out, "w")
    if err then
        reaper.MB("Error opening output file:\n" .. script_path..name_out .. "\n\n".. tostring(err), "Whoops!", 0)
        return
    end    
    file_out:write(table.concat(arr, "\n"))
    file_out:close()

    -- Register it as an action
    local ret = reaper.AddRemoveReaScript( true, 0, script_path .. name_out, true )
    if ret == 0 then
        reaper.MB("Error registering the new script as an action.", "Whoops!", 0)
        return
    end

    reaper.MB(  "Saved current settings and added to the action list:\n" .. name_out, "Done!", 0)

end


local function btn_export()

    GUI.GetUserInputs("Saving settings", {"Name for this preset:"}, {""}, continue_export, 0)
    
end




------------------------------------
-------- GUI Elements --------------
------------------------------------


GUI.name = "New script GUI"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 320, 200
GUI.anchor, GUI.corner = "mouse", "C"


GUI.New("txt_search", "Textbox", {
    z = 11,
    x = 128.0,
    y = 16.0,
    w = 160,
    h = 20,
    caption = "Name must match:",
    cap_pos = "left",
    font_a = 3,
    font_b = "textbox",
    color = "txt",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})

GUI.New("chk_options", "Checklist", {
    z = 11,
    x = 48.0,
    y = 56.0,
    w = 128,
    h = 72,
    caption = "Options",
    optarray = {"Find all", "No children"},
    dir = "v",
    pad = 4,
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = true,
    shadow = true,
    swap = nil,
    opt_size = 20
})

GUI.New("chk_apply", "Checklist", {
    z = 11,
    x = 192.0,
    y = 56.0,
    w = 80,
    h = 72,
    caption = "Apply to:",
    optarray = {"TCP", "MCP"},
    dir = "v",
    pad = 4,
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = true,
    shadow = true,
    swap = nil,
    opt_size = 20
})

GUI.New("btn_go", "Button", {
    z = 11,
    x = 80.0,
    y = 152.0,
    w = 48,
    h = 24,
    caption = "Go!",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = btn_go
})

GUI.New("btn_export", "Button", {
    z = 11,
    x = 144.0,
    y = 152.0,
    w = 96,
    h = 24,
    caption = "Export action",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = btn_export
})




GUI.Init()
GUI.Main()
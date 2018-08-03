--[[
    Description: Show only specified tracks
    Version: 1.2.1
    Author: Lokasenna
    Donation: https://paypal.me/Lokasenna
    Changelog:
        Fix: Compatibility with font changes in GUI library
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




------------------------------------
-------- Search Functions ----------
------------------------------------


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

    if str:sub(1, 1) == "#" then

        -- Force an integer until/unless I come up with some sort of multiple track syntax
        str = tonumber(str:sub(2, -1))
        return str and (math.floor( tonumber(str) ) == tr_idx)

    elseif tostring(str) then

        return fuzzy_match(tr_name, tostring(str))

    end

end


-- Returns an array of MediaTrack == true for all parents of the given MediaTrack
local function recursive_parents(track)

    if reaper.GetTrackDepth(track) == 0 then 
        return {[track] = true}
    else
        local ret = recursive_parents( reaper.GetParentTrack(track) )
        ret[track] = true
        return ret
    end

end


local function get_children(tracks)

    local children = {}
    for idx in pairs(tracks) do

        local tr = reaper.GetTrack(0, idx - 1)
        i = idx + 1
        while true do

            children[i] = recursive_parents( reaper.GetTrack(0, i-1) )[tr] == true
            if not children[i] then break end
            local _, name = reaper.GetTrackName(reaper.GetTrack(0, i-1), "")
            i = i + 1
        end
    end

    return children

end


local function get_parents(tracks)

    local parents = {}
    for idx in pairs(tracks) do

        local tr = reaper.GetTrack(0, idx - 1)
        for tr in pairs( recursive_parents(tr)) do
            parents[ math.floor( reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER") ) ] = true
        end

    end

    return parents

end


local function merge_tables(...)

    local tables = {...}
    if not tables[2] then return tables[1] end

    local ret = {}
    for i = #tables, 1, -1 do
        for k, v in pairs(tables[i]) do
            ret[k] = v
        end
    end

    return ret

end


local function get_tracks_to_show(settings)
    --[[
        settings = {
            search = str,

            matchmultiple = bool, 
            matchonlytop = bool,
            showchildren = bool,
            showparents = bool,

            mcp = bool, 
            tcp = bool
        }
    ]]--
    local matches

    -- Find all matches
    for i = 1, reaper.CountTracks(0) do

        local tr = reaper.GetTrack(0, i - 1)
        local _, name = reaper.GetTrackName(tr, "")
        local idx = math.floor( reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER") )
        local ischild = reaper.GetTrackDepth(tr) > 0

        if is_match(settings.search, name, idx) and not (ischild and settings.matchonlytop) then

            if not matches then matches = {} end
            matches[idx] = true
            if not settings.matchmultiple then break end

        end

    end

    -- Didn't get any matches
    if not matches then return matches end

    local parents = settings.showparents and get_parents(matches)
    local children = settings.showchildren and get_children(matches)

    return merge_tables(matches, parents or nil, children or nil)

end


local function set_visibility(tracks, settings)

    if not tracks then return end
    --if not tracks or #tracks == 0 then return end

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




------------------------------------
-------- Standalone startup --------
------------------------------------


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





------------------------------------
-------- Go! Button ----------------
------------------------------------


local function get_settings()

    local search = GUI.Val("txt_search")
    local opts = GUI.Val("chk_options")
    local apply = GUI.Val("chk_apply")

    return {
        search = search,
        matchmultiple = opts[1],
        matchonlytop = opts[2],
        showchildren = opts[3],
        showparents = opts[4],
        tcp = apply[1],
        mcp = apply[2]
    }


end


local function btn_go()
    
    local settings = get_settings()
    local tracks = get_tracks_to_show(settings)
    set_visibility(tracks, settings)
    
end




------------------------------------
-------- Export button -------------
------------------------------------


local function table_to_code(settings)

    local strs = {
        'local settings = {'
    }

    for k, v in pairs(settings) do
        local param = type(v) == "boolean"  and tostring(v) 
                                            or  ('"' .. tostring(v) .. '"')
        strs[#strs+1] = '\t' .. k .. ' = ' .. param .. ','
    end

    strs[#strs+1] = '}'

    return table.concat(strs, "\n")

end


local function get_settings_to_export()

    return table_to_code( get_settings() )
    
end


local function sanitize_filename(name)
    return string.gsub(name, "[^%w%s_]", "-")
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
-------- GUI Stuff -----------------
------------------------------------


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


GUI.name = "Show only specified tracks"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 320, 336
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
    font_b = "monospace",
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
    w = 224,
    h = 112,
    caption = "Options",
    optarray = {"Match more than one track", "Match only top-level tracks", "Show children of matches", "Show parents of matches"},
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
    x = 112.0,
    y = 192.0,
    w = 96,
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
    y = 284.0,
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
    y = 284.0,
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
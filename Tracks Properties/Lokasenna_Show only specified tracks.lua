--[[
    Description: Show only specified tracks
    Version: 1.5.1
    Author: Lokasenna
    Donation: https://paypal.me/Lokasenna
    Changelog:
        Fix: Expand error message when the library is missing
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


local function merge_tables(...)

  local tables = {...}

  local ret = {}
  for i = #tables, 1, -1 do
      if tables[i] then
          for k, v in pairs(tables[i]) do
              if v then ret[k] = v end
          end
      end
  end

  return ret

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
        local i = idx + 1
        while i <= reaper.CountTracks(0) do
            children[i] = recursive_parents( reaper.GetTrack(0, i-1) )[tr] == true
            if not children[i] then break end
            i = i + 1
        end
    end

    return children

end


local function get_parents(tracks)

    local parents = {}
    for idx in pairs(tracks) do

        local tr = reaper.GetTrack(0, idx - 1)
        for nextParent in pairs( recursive_parents(tr)) do
            parents[ math.floor( reaper.GetMediaTrackInfo_Value(nextParent, "IP_TRACKNUMBER") ) ] = true
        end

    end

    return parents

end


local function get_top_level_tracks()

    local top = {}
    for i = 1, reaper.CountTracks() do
        if reaper.GetTrackDepth( reaper.GetTrack(0, i-1) ) == 0 then
            top[i] = true
        end
    end

    return top
end


local function get_siblings(tracks)

    local siblings = {}
    for idx in pairs(tracks) do

        local tr = reaper.GetTrack(0, idx - 1)
        local sibling_depth = reaper.GetTrackDepth(tr)

        if sibling_depth > 0 then
            local parent = reaper.GetParentTrack(tr)

            local children = get_children( {[reaper.GetMediaTrackInfo_Value(parent, "IP_TRACKNUMBER")] = true} )
            for child_idx in pairs(children) do

                -- Can't use siblings[idx] = ___ here because we don't want to set existing
                -- siblings to false
                if reaper.GetTrackDepth( reaper.GetTrack(0, child_idx-1) ) == sibling_depth then
                    siblings[child_idx] = true
                end

            end

        else

            -- Find all top-level tracks
            siblings = merge_tables(siblings, get_top_level_tracks())

        end

    end

    return siblings

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
    local matches = {}

    -- Abort if we don't need to be doing this
    if not (settings.tcp or settings.mcp) then return nil end

    -- Find all matches
    for i = 1, reaper.CountTracks(0) do

        local tr = reaper.GetTrack(0, i - 1)
        local _, name = reaper.GetTrackName(tr, "")
        local idx = math.floor( reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER") )
        local ischild = reaper.GetTrackDepth(tr) > 0

        if is_match(settings.search, name, idx) and not (ischild and settings.matchonlytop) then

            matches[idx] = true
            if not settings.matchmultiple then break end

        end

    end

    -- Hacky way to check if length of a hash table == 0
    for k in pairs(matches) do
        if not k then return {} end
    end

    local parents = settings.showparents and get_parents(matches)
    local children = settings.showchildren and get_children(matches)
    local siblings = settings.showsiblings and get_siblings(matches)

    return merge_tables(matches, parents, children, siblings)

end

local function select_first_visible_MCP()
  for i = 1, reaper.CountTracks(0) do
    local tr = reaper.GetTrack(0, i - 1)
    if reaper.IsTrackVisible(tr, true) then
      reaper.SetOnlyTrackSelected(tr)
      break
    end
  end
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

    if settings.mcp then
      select_first_visible_MCP()
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

    local tracks = settings and get_tracks_to_show(settings)
    if tracks then
        set_visibility( tracks, settings )
    else
        reaper.MB(
          "Error reading the script's settings. Make sure you haven't edited the script or changed its filename.", "Whoops!", 0)
    end

    return

end



-- END FILE COPY HERE





------------------------------------
-------- Go! Button ----------------
------------------------------------


local function get_settings()

    local search = GUI.Val("txt_search")
    local matchopts = GUI.Val("chk_matchopts")
    local showopts = GUI.Val("chk_showopts")
    local apply = GUI.Val("chk_apply")

    return {
        search = search,
        matchmultiple = matchopts[1],
        matchonlytop = matchopts[2],
        showchildren = showopts[1],
        showparents = showopts[2],
        showsiblings = showopts[3],
        tcp = apply[1],
        mcp = apply[2]
    }


end


local function apply_settings()

    local settings = get_settings()
    local tracks = get_tracks_to_show(settings)
    set_visibility(tracks, settings)

end


local function btn_go()
    apply_settings()
end

local function update_realtime()
    if GUI.Val("chk_realtime") then apply_settings() end
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
-------- Show Tracks buttons -------
------------------------------------

local function btn_showTCP()

    --_SWSTL_SHOWALLTCP
    reaper.Main_OnCommand( reaper.NamedCommandLookup("_SWSTL_SHOWALLTCP"), 0)

end

local function btn_showMCP()

    --_SWSTL_SHOWALLMCP
    reaper.Main_OnCommand( reaper.NamedCommandLookup("_SWSTL_SHOWALLMCP"), 0)

end





------------------------------------
-------- GUI Stuff -----------------
------------------------------------


local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack, then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Window.lua")()
GUI.req("Classes/Class - Label.lua")()
GUI.req("Modules/Window - GetUserInputs.lua")()


-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end


GUI.name = "Show only specified tracks"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 320, 512
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

GUI.New("chk_matchopts", "Checklist", {
    z = 11,
    x = 64,
    y = 56.0,
    w = 192,
    h = 72,
    caption = "Match:",
    optarray = {"More than one track", "Only top-level tracks"},
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

GUI.New("chk_showopts", "Checklist", {
    z = 11,
    x = 64,
    y = 144,
    w = 192,
    h = 96,
    caption = "Show:",
    optarray = {"Children of matches", "Parents of matches", "Siblings of matches"},
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
    x = 64,
    y = 256,
    w = 192,
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

GUI.New("chk_realtime", "Checklist", {
    z = 11,
    x = 64,
    y = 344,
    w = 192,
    h = 32,
    caption = "",
    optarray = {"Apply changes in real-time"},
    dir = "v",
    pad = 4,
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = true,
    swap = nil,
    opt_size = 20
})

GUI.New("lbl_realtime", "Label", {
    z = 11,
    x = 128.0,
    y = 376,
    caption = "(Not advisable for large projects!!)",
    font = 3,
    color = "txt",
    bg = "wnd_bg",
    shadow = true
})

GUI.New("btn_go", "Button", {
    z = 11,
    x = 16,
    y = 416,
    w = 140,
    h = 24,
    caption = "Go!",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = btn_go
})

GUI.New("btn_export", "Button", {
    z = 11,
    x = 164,
    y = 416,
    w = 140,
    h = 24,
    caption = "Export preset",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = btn_export
})

GUI.New("btn_showTCP", "Button", {
    z = 11,
    x = 16,
    y = 448,
    w = 140,
    h = 24,
    caption = "Show all tracks in TCP",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = btn_showTCP
})

GUI.New("btn_showMCP", "Button", {
    z = 11,
    x = 164,
    y = 448,
    w = 140,
    h = 24,
    caption = "Show all tracks in MCP",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = btn_showMCP
})

GUI.elms.txt_search.last_val = ""
function GUI.elms.txt_search:ontype()
    GUI.Textbox.ontype(self)
    if self.retval ~= self.last_val then
        update_realtime()
        self.last_val = self.retval
    end
end

function GUI.elms.chk_matchopts:onmouseup()
    GUI.Checklist.onmouseup(self)
    update_realtime()
end

function GUI.elms.chk_showopts:onmouseup()
    GUI.Checklist.onmouseup(self)
    update_realtime()
end

function GUI.elms.chk_apply:onmouseup()
    GUI.Checklist.onmouseup(self)
    update_realtime()
end



GUI.Init()

GUI.elms.lbl_realtime.x = (GUI.w - GUI.elms.lbl_realtime.w) / 2

GUI.Main()

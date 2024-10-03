-- @description Track icon selector
-- @author Reapertips & Sexan
-- @version 1.07
-- @changelog
--   Show Console message with unsupported image path
-- @provides
--   reatips_Track icon selector/Menu.png
--   reatips_Track icon selector/Reset.png
-- @screenshot
--   https://i.imgur.com/bFK2HYk.png
--   https://i.imgur.com/MabMOW1.png
-- @about
--   # Track Icon Selector
--   Created by Reapertips and Sexan
--
--   The Track Icon Selector is a tool designed to streamline the process of applying custom icons to your tracks in REAPER. By scanning REAPER's "track_icons" folder, the script automatically populates a user-friendly interface with icons and their categories.
--
--   ## Key Features:
--
--   - Intuitive Interface: Quickly browse and select icons from a visually appealing interface.
--   - Instant Search: Efficiently find specific icons using the built-in search function.
--   - Categorization: Organize icons into categories for easy navigation.
--   - Customizable Icons: Resize icons to fit your preferences and customize their appearance.
--   - Sidebar Preferences: Control whether the sidebar opens automatically on script launch
--   - Dockable Window: Conveniently dock the script window to the left of your tracks for easy access.
--   - Yellow Outline Around Used Icons: Instantly identify tracks that already have icons applied.
--
--   ## Creating and Modifying Categories:
--
--   To create or modify categories for your icons, navigate to the following REAPER folder:
--
--   REAPER Folder > Data > track_icons
--   Within this folder, create or modify folders to represent your desired categories. The script will automatically recognize these folders as categories in the sidebar, allowing you to filter icons based on their assigned categories.

-- @license GPL v3

if not reaper.ImGui_GetBuiltinPath then
    reaper.ShowMessageBox("Script needs ReaImGui.\nPlease Install it in next window", "MISSING DEPENDENCIES", 0)
    reaper.ReaPack_BrowsePackages('^ReaImGui:')
    return
end

local r                      = reaper
package.path                 = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local getinfo                = debug.getinfo(1, 'S');
local script_path            = getinfo.source:match [[^@?(.*[\/])[^\/]-$]];
local os_separator           = package.config:sub(1, 1)
local imgui                  = require "imgui" "0.9.3"
local reaper_path            = r.GetResourcePath()

local COLORS                 = {
    ["win_bg"] = 0x282828ff,
    ["sidebar_col"] = 0x2c2c2cff,
    ["hover_col"] = 0x3c6191ff,
    ["outline_col"] = 0xffcb40ff,
    ["text_active"] = 0xf1f2f2ff,
    ["text_inactive"] = 0x999B9Fff
}

local ALWAYS_SHOW_CATEGORIES = false
local QUIT_ON_SELECT         = false
local TOOLTIPS               = true
local ESC_TO_QUIT            = true
local CURRENT_ZOOM           = 1
local WANT_FOCUS             = true

local function PrintTraceback(err)
    local byLine = "([^\r\n]*)\r?\n?"
    local trimPath = "[\\/]([^\\/]-:%d+:.+)$"
    local stack = {}
    for line in string.gmatch(err, byLine) do
        local str = string.match(line, trimPath) or line
        stack[#stack + 1] = str
    end
    r.ShowConsoleMsg(
        "Error: " .. stack[1] .. "\n\n" ..
        "Stack traceback:\n\t" .. table.concat(stack, "\n\t", 3) .. "\n\n" ..
        "Reaper:       \t" .. r.GetAppVersion() .. "\n" ..
        "Platform:     \t" .. r.GetOS()
    )
end

local function PDefer(func)
    r.defer(function()
        local status, err = xpcall(func, debug.traceback)
        if not status then
            PrintTraceback(err)
        end
    end)
end

function StringToTable(str)
    local f, err = load("return " .. str)
    return f ~= nil and f() or nil
end

if r.HasExtState("TRACK_ICONS4", "STORED_DATA") then
    local stored = r.GetExtState("TRACK_ICONS4", "STORED_DATA")
    if stored ~= nil then
        local storedTable = StringToTable(stored)
        if storedTable ~= nil then
            COLORS["win_bg"] = storedTable.win_col
            COLORS["sidebar_col"] = storedTable.sidebar_col
            COLORS["hover_col"] = storedTable.hover_col
            COLORS["text_active"] = storedTable.text_active
            COLORS["text_inactive"] = storedTable.text_inactive
            COLORS["outline_col"] = storedTable.outline_col
            ALWAYS_SHOW_CATEGORIES = storedTable.ALWAYS_SHOW_CATEGORIES
            QUIT_ON_SELECT = storedTable.QUIT_ON_SELECT
            ESC_TO_QUIT = storedTable.ESC_TO_QUIT ~= nil and storedTable.ESC_TO_QUIT or ESC_TO_QUIT
            TOOLTIPS = storedTable.TOOLTIPS
            CURRENT_ZOOM = storedTable.CURRENT_ZOOM ~= nil and tonumber(storedTable.CURRENT_ZOOM) or CURRENT_ZOOM
        end
    end
end

local OPEN_CATEGORIES = ALWAYS_SHOW_CATEGORIES

local MAIN_PNG_TBL = {
    [-1] = { dir = "Root" },
    [0] = { dir = "All Icons" }
}
local FILTERED_PNG

local icon_size = 32

r.set_action_options(1)

local ctx = imgui.CreateContext('Track icon selector')
local WND_W, WND_H = 500, 500
local FLT_MIN, FLT_MAX = imgui.NumericLimits_Float()

local SYSTEM_FONT_FACTORY = imgui.CreateFont('sans-serif', 12, imgui.FontFlags_Bold)
imgui.Attach(ctx, SYSTEM_FONT_FACTORY)

local menu_png_path = script_path .. "/reatips_Track icon selector/Menu.png"
local rest_png_path = script_path .. "/reatips_Track icon selector/Reset.png"
local menu_icon = imgui.CreateImage(menu_png_path)
local reset_icon = imgui.CreateImage(rest_png_path)
imgui.Attach(ctx, menu_icon)
imgui.Attach(ctx, reset_icon)

local png_path_track_icons = "/Data/track_icons"

function SerializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0
    local tmp = string.rep(" ", depth)
    if name then
        if type(name) == "number" and math.floor(name) == name then
            name = "[" .. name .. "]"
        elseif not string.match(name, '^[a-zA-z_][a-zA-Z0-9_]*$') then
            name = string.gsub(name, "'", "\\'")
            name = "['" .. name .. "']"
        end
        tmp = tmp .. name .. " = "
    end
    if type(val) == "table" then
        tmp = tmp .. "{"
        for k, v in pairs(val) do
            tmp = tmp .. SerializeTable(v, k, skipnewlines, depth + 1) .. ","
        end
        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end
    return tmp
end

function TableToString(table)
    return SerializeTable(table)
end

local function GetDirFilesRecursive(dir, tbl, filter)
    for index = 0, math.huge do
        local path = r.EnumerateSubdirectories(dir, index)
        if not path then break end
        tbl[#tbl + 1] = { dir = path, {} }
        GetDirFilesRecursive(dir .. os_separator .. path, tbl[#tbl], filter)
        if #tbl[#tbl] == 0 then
            tbl[#tbl] = nil
        end
    end

    for index = 0, math.huge do
        local file = r.EnumerateFiles(dir, index)
        if not file then break end
        if file:find(filter, nil, true) then
            if dir == reaper_path .. png_path_track_icons then
                table.insert(MAIN_PNG_TBL[-1], { name = dir .. os_separator .. file, short_name = file })
            else
                tbl[#tbl + 1] = { name = dir .. os_separator .. file, short_name = file }
            end
            table.insert(MAIN_PNG_TBL[0], { name = dir .. os_separator .. file, short_name = file })
        end
    end
end

GetDirFilesRecursive(reaper_path .. png_path_track_icons, MAIN_PNG_TBL, ".png")

table.sort(MAIN_PNG_TBL,
function(a, b)
        if a.dir and b.dir then return a.dir:lower() < b.dir:lower() end
        return false
    end)

local largest_name = 0
imgui.PushFont(ctx, SYSTEM_FONT_FACTORY)
for i = -1, #MAIN_PNG_TBL do
    if MAIN_PNG_TBL[i].dir then
        local cur_size = imgui.CalcTextSize(ctx, "  " .. MAIN_PNG_TBL[i].dir)
        largest_name = cur_size > largest_name and cur_size or largest_name
    end
    table.sort(MAIN_PNG_TBL[i],
        function(a, b)
            if a.name and b.name then return a.name:lower() < b.name:lower() end
            return false
        end)
end
largest_name = largest_name + imgui.GetStyleVar(ctx, imgui.StyleVar_FramePadding) * 2
imgui.PopFont(ctx)

local function RefreshImgObj()
    for i = 1, #FILTERED_PNG do
        if FILTERED_PNG[i].img_obj then
            FILTERED_PNG[i].img_obj = nil
        end
    end
end

local old_t, old_filter
local function FilterActions(actions, filter_text)
    if old_filter == filter_text then
        return old_t
    end
    local t = {}
    for i = 1, #actions do
        local action = actions[i]
        if action.name then
            local name = action.short_name:lower()
            local found = true
            for word in filter_text:gmatch("%S+") do
                if not name:find(word:lower(), 1, true) then
                    found = false
                    break
                end
            end
            if found then
                table.insert(t, action)
            end
        end
    end
    old_filter = filter_text
    old_t = t
    return t
end

local function DrawTooltips(str)
    if imgui.BeginTooltip(ctx) then
        imgui.Text(ctx, str)
        imgui.EndTooltip(ctx)
    end
end

local PNG_FILTER = ''
local cur_category = 0
local function PngSelector(button_size)
    local ww = imgui.GetWindowSize(ctx)

    imgui.PushStyleColor(ctx, imgui.Col_Text, COLORS["text_active"])
    imgui.PushStyleColor(ctx, imgui.Col_ChildBg, COLORS["win_bg"])
    imgui.PushStyleColor(ctx, imgui.Col_Button, COLORS["win_bg"])
    imgui.PushStyleColor(ctx, imgui.Col_FrameBg, COLORS["sidebar_col"])

    imgui.BeginGroup(ctx)
    if imgui.ImageButton(ctx, "menu_icon", menu_icon, 12, 12) then
        OPEN_CATEGORIES = not OPEN_CATEGORIES
    end

    imgui.SameLine(ctx)
    if imgui.IsPopupOpen(ctx, "R_CTX") then
        local minx, miny = imgui.GetItemRectMin(ctx)
        local maxx, maxy = imgui.GetItemRectMax(ctx)
        imgui.DrawList_AddRect(DRAW_LIST, minx, miny, maxx, maxy, COLORS["outline_col"], 0, 0, 2)
    end

    if imgui.IsItemHovered(ctx) then
        DrawTooltips("Toggle Categories Panel")
        if imgui.IsMouseClicked(ctx, 1) then
            imgui.OpenPopup(ctx, "R_CTX")
        end
    end
    if imgui.ImageButton(ctx, "reset_icon", reset_icon, 12, 12) then
        if #TRACKS > 0 then
            r.Undo_BeginBlock2(nil)
            for i = 1, #TRACKS do
                r.GetSetMediaTrackInfo_String(TRACKS[i], "P_ICON", "", true)
            end
            r.Undo_EndBlock2(nil, "Removed Track Icon", 1)
        end
    end

    if imgui.IsItemHovered(ctx) then
        DrawTooltips("Remove Track Icon")
    end
    imgui.SameLine(ctx)
    imgui.SetNextItemWidth(ctx, 50)
    RV_SLD, CURRENT_ZOOM = imgui.SliderInt(ctx, "Size\t", CURRENT_ZOOM, 1, 5, "")
    if RV_SLD then
        SaveSettings()
    end
    button_size = button_size * (CURRENT_ZOOM == 1 and 1 or CURRENT_ZOOM / 1.5)

    if imgui.IsItemHovered(ctx) and not imgui.IsItemActive(ctx) then
        DrawTooltips("Increase/Decrease Icon Size")
    end

    if not OPEN_CATEGORIES and ww > largest_name or (OPEN_CATEGORIES and ww > (largest_name)) then
        imgui.SameLine(ctx, 0, 0)
    end
    imgui.SetNextItemWidth(ctx, -FLT_MIN - 15)
    if WANT_FOCUS then
        imgui.SetKeyboardFocusHere(ctx)
        WANT_FOCUS = nil
    end
    RV_F, PNG_FILTER = imgui.InputTextWithHint(ctx, "##input2", "Search Icons", PNG_FILTER)
    imgui.SameLine(ctx, 0, 0)

    imgui.PushStyleColor(ctx, imgui.Col_Button, COLORS["sidebar_col"])
    if imgui.Button(ctx, "X") then
        PNG_FILTER = ''
        NEED_REFRESH = true
    end
    imgui.PopStyleColor(ctx)
    if imgui.IsItemHovered(ctx) then
        DrawTooltips("Clear Search")
    end

    FILTERED_PNG = FilterActions(MAIN_PNG_TBL[cur_category], PNG_FILTER)
    if RV_F or NEED_REFRESH or RV_SLD then
        RefreshImgObj()
        if NEED_REFRESH then NEED_REFRESH = nil end
    end
    local item_spacing_x, item_spacing_y = imgui.GetStyleVar(ctx, imgui.StyleVar_ItemSpacing)
    item_spacing_x = item_spacing_y
    imgui.PushStyleVar(ctx, imgui.StyleVar_ItemSpacing, item_spacing_y, item_spacing_y)
    local buttons_count = #FILTERED_PNG
    local window_visible_x2 = ({ imgui.GetWindowPos(ctx) })[1] +
        ({ imgui.GetWindowContentRegionMax(ctx) })[1]
    imgui.PushStyleColor(ctx, imgui.Col_Button, COLORS["win_bg"])

    if imgui.BeginChild(ctx, "filtered_pngs_list", 0, 0) then
        for n = 0, #FILTERED_PNG - 1 do
            local image = FILTERED_PNG[n + 1].name
            local stripped_name = FILTERED_PNG[n + 1].short_name

            imgui.PushID(ctx, n)
            if not imgui.ValidatePtr(FILTERED_PNG[n + 1].img_obj, 'ImGui_Image*') then
                if not pcall(function() FILTERED_PNG[n + 1].img_obj = imgui.CreateImage(image) end) then  
                    r.ShowConsoleMsg("Unsupported image : " .. image .. "\n\n")
               end
            end

            if imgui.ImageButton(ctx, "##png_select", FILTERED_PNG[n + 1].img_obj, button_size, button_size, 0, 0, 1, 1) then
                if #TRACKS > 0 then
                    r.Undo_BeginBlock2(nil)
                    for i = 1, #TRACKS do
                        r.GetSetMediaTrackInfo_String(TRACKS[i], "P_ICON", image, true)
                    end
                    r.Undo_EndBlock2(nil, "Changed Track Icon", 1)
                    if QUIT_ON_SELECT then
                        WANT_CLOSE = true
                    end
                    LAST_ICON = image
                    CUR_ICON = image
                end
            end
            if imgui.IsItemActive(ctx) and imgui.IsMouseDragging(ctx, 0) and imgui.BeginDragDropSource(ctx) then
                imgui.Image(ctx, FILTERED_PNG[n + 1].img_obj, button_size, button_size)
                dnd_image = image
                imgui.EndDragDropSource(ctx)
            end

            if imgui.IsItemHovered(ctx) and TOOLTIPS then
                DrawTooltips(stripped_name)
            end

            local minx, miny = imgui.GetItemRectMin(ctx)
            local maxx, maxy = imgui.GetItemRectMax(ctx)
            if CUR_ICON == image then
                if LAST_ICON ~= CUR_ICON then
                    SCROLL_TO_IMG = true
                    LAST_ICON = CUR_ICON
                end
                imgui.DrawList_AddRect(DRAW_LIST, minx, miny, maxx, maxy, COLORS["outline_col"], 0, 0, 2)
                if SCROLL_TO_IMG then
                    SCROLL_TO_IMG = nil
                    imgui.SetScrollHereY(ctx)
                end
            end


            local next_button_x2 = maxx + item_spacing_x + button_size

            if n + 1 < buttons_count and next_button_x2 < window_visible_x2 then
                imgui.SameLine(ctx)
            end

            imgui.PopID(ctx)
        end
        imgui.EndChild(ctx)
    end
    imgui.PopStyleVar(ctx)
    imgui.PopStyleColor(ctx, 5)
    imgui.EndGroup(ctx)

    if imgui.IsMouseReleased(ctx, 0) and dnd_image then
        local rv_track, info = r.GetThingFromPoint(r.GetMousePosition())
        if rv_track and info:find("tcp") or info:find("mcp") then
            r.Undo_BeginBlock2(nil)
            r.GetSetMediaTrackInfo_String(rv_track, "P_ICON", dnd_image, true)
            r.Undo_EndBlock2(nil, "Changed Track Icon", 1)
        end
        dnd_image = nil
    end
end

local function Categories()
    local item_spacing_x = imgui.GetStyleVar(ctx, imgui.StyleVar_ItemSpacing)
    imgui.PushStyleVar(ctx, imgui.StyleVar_ItemSpacing, item_spacing_x, 20)
    imgui.PushStyleColor(ctx, imgui.Col_ChildBg, COLORS["sidebar_col"])
    if imgui.BeginChild(ctx, "PM_INSPECTOR", largest_name) then
        imgui.SetCursorPosY(ctx, imgui.GetCursorPosY(ctx) + 8)
        for i = 0, #MAIN_PNG_TBL do
            if i ~= PREV_CATEGORY then
                if MAIN_PNG_TBL[i].sel then
                    imgui.PushStyleColor(ctx, imgui.Col_Text, COLORS["text_active"])
                else
                    imgui.PushStyleColor(ctx, imgui.Col_Text, COLORS["text_inactive"])
                end
            else
                imgui.PushStyleColor(ctx, imgui.Col_Text, COLORS["text_active"])
            end
            if MAIN_PNG_TBL[i].dir then
                if imgui.Selectable(ctx, "  " .. MAIN_PNG_TBL[i].dir, cur_category == i, nil) then
                    cur_category = i
                    NEED_REFRESH = true
                    old_filter = nil
                end
            end
            if imgui.IsItemHovered(ctx) then
                MAIN_PNG_TBL[i].sel = true
            else
                MAIN_PNG_TBL[i].sel = nil
            end
            if i ~= PREV_CATEGORY then
                if MAIN_PNG_TBL[i].sel then
                    imgui.PopStyleColor(ctx)
                else
                    imgui.PopStyleColor(ctx)
                end
            else
                imgui.PopStyleColor(ctx)
            end
        end
        imgui.EndChild(ctx)
    end
    if cur_category ~= PREV_CATEGORY then
        PREV_CATEGORY = cur_category
    end
    imgui.PopStyleVar(ctx)
    imgui.PopStyleColor(ctx)
end

function SaveSettings()
    local data = TableToString({
        win_col = COLORS["win_bg"],
        win_col_alt = COLORS["win_bg_alt"],
        hover_col = COLORS["hover_col"],
        sidebar_col = COLORS["sidebar_col"],
        outline_col = COLORS["outline_col"],
        text_active = COLORS["text_active"],
        text_inactive = COLORS["text_inactive"],
        ALWAYS_SHOW_CATEGORIES = ALWAYS_SHOW_CATEGORIES,
        QUIT_ON_SELECT = QUIT_ON_SELECT,
        ESC_TO_QUIT = ESC_TO_QUIT,
        TOOLTIPS = TOOLTIPS,
        CURRENT_ZOOM = CURRENT_ZOOM
    })
    r.SetExtState("TRACK_ICONS4", "STORED_DATA", data, true)
end

local function DrawRClickCtx()
    if imgui.BeginPopup(ctx, "R_CTX") then
        if imgui.BeginMenu(ctx, "Customize") then
            local RV_UPDATED
            RV_COL1, COLORS["win_bg"] = imgui.ColorEdit4(ctx, "Primary background color", COLORS["win_bg"],
                imgui.ColorEditFlags_NoInputs)
            RV_COL2, COLORS["sidebar_col"] = imgui.ColorEdit4(ctx, "Secondary background color", COLORS["sidebar_col"],
                imgui.ColorEditFlags_NoInputs)
            RV_COL3, COLORS["hover_col"] = imgui.ColorEdit4(ctx, "Hover icon color", COLORS["hover_col"],
                imgui.ColorEditFlags_NoInputs)
            RV_COL4, COLORS["outline_col"] = imgui.ColorEdit4(ctx, "Selected outline color", COLORS["outline_col"],
                imgui.ColorEditFlags_NoInputs)
            RV_COL5, COLORS["text_active"] = imgui.ColorEdit4(ctx, "Text active color", COLORS["text_active"],
                imgui.ColorEditFlags_NoInputs)
            RV_COL6, COLORS["text_inactive"] = imgui.ColorEdit4(ctx, "Text Inactive color", COLORS["text_inactive"],
                imgui.ColorEditFlags_NoInputs)
            if RV_COL1 or RV_COL2 or RV_COL3 or RV_COL4 or RV_COL5 or RV_COL6 then
                RV_UPDATED = true
            end
            if imgui.MenuItem(ctx, "Reset to Default", nil) then
                COLORS["win_bg"] = 0x282828ff
                COLORS["sidebar_col"] = 0x2c2c2cff
                COLORS["hover_col"] = 0x3c6191ff
                COLORS["outline_col"] = 0xffcb40ff
                COLORS["text_active"] = 0xf1f2f2ff
                COLORS["text_inactive"] = 0x999B9Fff
                SaveSettings()
            end
            if RV_UPDATED then
                SaveSettings()
            end
            imgui.EndMenu(ctx)
        end
        if imgui.BeginMenu(ctx, "Preferences") then
            if imgui.MenuItem(ctx, "Show sidebar by default", nil, ALWAYS_SHOW_CATEGORIES == true) then
                ALWAYS_SHOW_CATEGORIES = not ALWAYS_SHOW_CATEGORIES
                SaveSettings()
            end
            if imgui.MenuItem(ctx, "Quit after applying icon", nil, QUIT_ON_SELECT == true) then
                QUIT_ON_SELECT = not QUIT_ON_SELECT
                SaveSettings()
            end
            if imgui.MenuItem(ctx, "Quit after pressing ESC", nil, ESC_TO_QUIT == true) then
                ESC_TO_QUIT = not ESC_TO_QUIT
                SaveSettings()
            end
            if imgui.MenuItem(ctx, "Show file name on icon hover", nil, TOOLTIPS == true) then
                TOOLTIPS = not TOOLTIPS
                SaveSettings()
            end
            imgui.EndMenu(ctx)
        end
        if imgui.MenuItem(ctx, "Dock to LEFT") then
            SET_DOCK_ID = -2
        end
        if imgui.MenuItem(ctx, "Undock") then
            SET_DOCK_ID = 0
        end
        imgui.EndPopup(ctx)
    end
end

local function PushTheme()
    imgui.PushStyleColor(ctx, imgui.Col_ButtonHovered, COLORS["hover_col"])
    imgui.PushStyleColor(ctx, imgui.Col_HeaderHovered, COLORS["hover_col"])
    imgui.PushStyleColor(ctx, imgui.Col_ScrollbarBg, COLORS["win_bg"])
end

local function CheckKeys()
    ESC = imgui.IsKeyReleased(ctx, imgui.Key_Escape)
    CTRL = imgui.GetKeyMods(ctx) == imgui.Mod_Ctrl
    Z = imgui.IsKeyPressed(ctx, imgui.Key_Z)
    if ESC and ESC_TO_QUIT then WANT_CLOSE = true end
    if CTRL and Z then
        r.Main_OnCommand(40029, 0)
    end
end

imgui.SetNextWindowSizeConstraints(ctx, WND_H, WND_W, FLT_MAX, FLT_MAX)
local function main()
    if SET_DOCK_ID then
        imgui.SetNextWindowDockID(ctx, SET_DOCK_ID)
        SET_DOCK_ID = nil
    end

    TRACKS = {}
    for i = 1, r.CountSelectedTracks2(nil, true) do
        TRACKS[#TRACKS + 1] = r.GetSelectedTrack2(nil, i - 1, true)
    end
    imgui.PushStyleColor(ctx, imgui.Col_WindowBg, COLORS["win_bg"])
    imgui.PushStyleColor(ctx, imgui.Col_TitleBgActive, COLORS["win_bg"])
    local visible, p_open = imgui.Begin(ctx, 'Track Icons', true)
    imgui.PopStyleColor(ctx, 2)
    if visible then
        CheckKeys()
        imgui.PushFont(ctx, SYSTEM_FONT_FACTORY)
        PushTheme()
        DRAW_LIST = imgui.GetWindowDrawList(ctx)
        if #TRACKS == 1 then
            RV_I, CUR_ICON = r.GetSetMediaTrackInfo_String(TRACKS[1], "P_ICON", "", false)
        else
            CUR_ICON = nil
        end
        if OPEN_CATEGORIES then
            Categories()
            imgui.SameLine(ctx)
        end
        PngSelector(icon_size)
        DrawRClickCtx()
        imgui.PopStyleColor(ctx, 3)
        imgui.PopFont(ctx)
        imgui.End(ctx)
    end
    if WANT_CLOSE then p_open = false end
    if p_open then
        PDefer(main)
    end
end

PDefer(main)

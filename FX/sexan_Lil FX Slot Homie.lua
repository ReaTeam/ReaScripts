-- @description Lil FX Slot Homie
-- @author Sexan
-- @version 1.0
-- @link https://forum.cockos.com/showthread.php?p=2680992#post2680992

local SLOT = 1

local r = reaper

local ctx = r.ImGui_CreateContext('Lil FX Slot Homie', r.ImGui_ConfigFlags_NavEnableKeyboard())

function FX_NAME(str)
    local vst_name
    for name_segment in str:gmatch('[^%,]+') do
        if name_segment:match("(%S+) ") then
            if name_segment:match('"(JS: .-)"') then
                vst_name = name_segment:match('"JS: (.-)"') and "JS:" .. name_segment:match('"JS: (.-)"') or nil
            else
                vst_name = name_segment:match("(%S+ .-%))") and "VST:" .. name_segment:match("(%S+ .-%))") or nil
            end
        end
    end
    if vst_name then return vst_name end
end

function GetFileContext(fp)
    local str = "\n"
    local f = io.open(fp, 'r')
    if f then
        str = f:read('a')
        f:close()
    end
    return str
end

-- Fill function with desired database
function Fill_fx_list()
    local tbl_list   = {}
    local tbl        = {}

    local vst_path   = r.GetResourcePath() .. "/reaper-vstplugins64.ini"
    local vst_str    = GetFileContext(vst_path)

    local vst_path32 = r.GetResourcePath() .. "/reaper-vstplugins.ini"
    local vst_str32  = GetFileContext(vst_path32)

    local jsfx_path  = r.GetResourcePath() .. "/reaper-jsfx.ini"
    local jsfx_str   = GetFileContext(jsfx_path)

    local au_path    = r.GetResourcePath() .. "/reaper-auplugins64-bc.ini"
    local au_str     = GetFileContext(au_path)

    local plugins    = vst_str .. vst_str32 .. jsfx_str .. au_str

    for line in plugins:gmatch('[^\r\n]+') do tbl[#tbl + 1] = line end

    -- CREATE NODE LIST
    for i = 1, #tbl do
        local fx_name = FX_NAME(tbl[i])
        if fx_name then
            tbl_list[#tbl_list + 1] = fx_name
        end
    end
    return tbl_list
end

local FX_LIST = Fill_fx_list()
local function Lead_Trim_ws(s) return s:match '^%s*(.*)' end

local function Filter_actions(filter_text)
    filter_text = Lead_Trim_ws(filter_text)
    local t = {}
    if filter_text == "" then return t end
    for i = 1, #FX_LIST do
        local action = FX_LIST[i]
        local name = action:lower()
        local found = true
        for word in filter_text:gmatch("%S+") do
            if not name:find(word:lower(), 1, true) then
                found = false
                break
            end
        end
        if found then t[#t + 1] = action end
    end
    return t
end

local function AddFxToTracks(fx)
    if r.CountTracks(0) == 1 and r.CountSelectedTracks(0) == 0 then
        local track = r.GetTrack(0, 0)
        r.TrackFX_AddByName(track, fx, false, -1000 - (SLOT - 1))
        return
    end
    for t = 1, r.CountSelectedTracks(0, 0) do
        r.TrackFX_AddByName(r.GetSelectedTrack(0, t - 1), fx, false, -1000 - (SLOT - 1))
    end
end

local keys = {
    r.ImGui_Key_1(),
    r.ImGui_Key_2(),
    r.ImGui_Key_3(),
    r.ImGui_Key_4(),
    r.ImGui_Key_5(),
    r.ImGui_Key_6(),
    r.ImGui_Key_7(),
    r.ImGui_Key_8(),
    r.ImGui_Key_9(),
    r.ImGui_Key_GraveAccent(),
    r.ImGui_Key_0()
}

local function CheckKeyNumbers()
    CTRL = r.ImGui_IsKeyDown(ctx, r.ImGui_Key_LeftCtrl())
    if not CTRL then return end
    for i = 1, #keys do
        if r.ImGui_IsKeyPressed(ctx, keys[i]) then
            SLOT = i < 10 and i or 100
        end
    end
end

local function AllowChildFocus(i)
    if ALLOW_IN_LIST and not PASS_FOCUS then
        if i == 1 then
            r.ImGui_SetKeyboardFocusHere(ctx)
            PASS_FOCUS = true
        end
    end
end

local filter_h = 60
local MAX_FX_SIZE = 300
function FilterBox()
    CheckKeyNumbers()
    r.ImGui_SetNextWindowSize(ctx, 0, filter_h)
    if r.ImGui_BeginPopup(ctx, "popup") then
        r.ImGui_Text(ctx, "ADD TO SLOT : " .. (SLOT < 100 and tostring(SLOT) or "LAST"))
        r.ImGui_PushItemWidth(ctx, MAX_FX_SIZE)
        if r.ImGui_IsWindowAppearing(ctx) then r.ImGui_SetKeyboardFocusHere(ctx) end
        -- IF KEYBOARD FOCUS IS ON CHILD ITEMS SET IT HERE
        if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Escape()) then r.ImGui_SetKeyboardFocusHere(ctx) end
        _, FILTER = r.ImGui_InputText(ctx, '##input', FILTER)
        if r.ImGui_IsItemFocused(ctx) then
            ALLOW_IN_LIST, PASS_FOCUS = nil, nil
            -- IF FOCUS IS ALREADY HERE CLOSE POPUP
            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Escape()) then r.ImGui_CloseCurrentPopup(ctx) end
        end

        local filtered_fx = Filter_actions(FILTER)
        filter_h = #filtered_fx == 0 and 60 or (#filtered_fx > 40 and 20 * 17 or (17 * #filtered_fx) + 55)

        if r.ImGui_BeginChild(ctx, "aaaaa") then
            -- DANCING AROUND SOME LIMITATIONS OF SELECTING CHILDS
            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_DownArrow()) then
                if not ALLOW_IN_LIST then ALLOW_IN_LIST = true end
            end
            for i = 1, #filtered_fx do
                AllowChildFocus(i)
                r.ImGui_PushID(ctx, i)
                if r.ImGui_Selectable(ctx, filtered_fx[i], true, nil, MAX_FX_SIZE) then
                    AddFxToTracks(filtered_fx[i])
                end
                r.ImGui_PopID(ctx)
            end
            r.ImGui_EndChild(ctx)
        end
        r.ImGui_EndPopup(ctx)
        r.defer(FilterBox)
    end
end

local function loop()
    r.ImGui_OpenPopup(ctx, 'popup')
    r.ImGui_SetNextWindowPos(ctx, r.ImGui_PointConvertNative(ctx, r.GetMousePosition()))
    FilterBox()
end

r.defer(loop)

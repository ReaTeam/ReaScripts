-- @description SendBox
-- @author smandrap
-- @version 1.1.1
-- @changelog # shim for reaimgui 0.9
-- @about Allows to create sends/receives using a Cubase-like track Searchbox.


local r = reaper

dofile(reaper.GetResourcePath() ..
  '/Scripts/ReaTeam Extensions/API/imgui.lua') '0.8'

local function init()

    local function api_check()

        local sws_ok = r.APIExists("CF_GetSWSVersion")
        local imgui_ok = r.APIExists("ImGui_GetVersion")

        if not sws_ok then
            r.MB('SWS extensions are required for this script to work.\nGet them at https://www.sws-extension.org\n',
                'Error', 0)
        end
        if not imgui_ok then
            r.MB('ReaImGui is required for this script to work.\nGet it on ReaPack.\n', 'Error', 0)
        end

        return sws_ok and imgui_ok
    end

    local function load_resources()

        local divider = r.GetOS():match("Win.*") and '\\' or '/'

        local script_names = {}
        local resources_folder = ""

        local script_folder = debug.getinfo(1).source:match("@?(.*[\\|/])")

        if #script_names > 0 then
            for _, s in ipairs(script_names) do
                local script = resources_folder .. divider .. s -- 1. The target script path relative to this file. If no folder, then it means preset file is right to the target script.
                local script_path = script_folder .. script -- This can be erased if you prefer enter absolute path value above.

                if r.file_exists(script_path) then
                    dofile(script_path)
                else
                    reaper.MB("Some files are missing.\n Please reinstall the script\n Can't find " .. script_path,
                        "Error", 0)
                    return false
                end
            end
        end

        return true
    end

    return api_check() and load_resources()
end

if not init() then
    return
end

local MAX_CHAN_NUM = 64

local GuiData = {
    ctx = r.ImGui_CreateContext('SendBox', r.ImGui_ConfigFlags_NavEnableKeyboard() | r.ImGui_ConfigFlags_DockingEnable()),

    TreeFlags = {
        base = r.ImGui_TreeNodeFlags_OpenOnArrow() | r.ImGui_TreeNodeFlags_DefaultOpen(),
        leaf = r.ImGui_TreeNodeFlags_OpenOnArrow() | r.ImGui_TreeNodeFlags_DefaultOpen() | r.ImGui_TreeNodeFlags_Leaf() |
            r.ImGui_TreeNodeFlags_NoTreePushOnOpen()
    },

    TableFlags = r.ImGui_TableFlags_Borders(),

    firstFrame = true,
    selectionMade = false,
    showChanSelector = false,

    searchboxBuffer = '',

    selectedInTree = {}
}

local mode = 0 -- 0 = send, 1 = receive
local send_position = 0 -- 0 = post-fader, 1= pre-FX, 3 = post-FX

local dst_channel = 0
local src_channels = {}
src_channels[0] = true -- Set default source to 1-2

local function TrimString(str)
    return str:match '^%s*(.*%S)' or ''
end

local function ProcessTrackSelectionTable()
    local track_idx = {}
    for i = 0, #GuiData.selectedInTree do
        if GuiData.selectedInTree[i] == true then
            table.insert(track_idx, i)
        end
    end
    return track_idx
end

local function ProcessChanSelectionTable()
    local chan_ids = {}

    for i = 0, MAX_CHAN_NUM - 1, 2 do
        if src_channels[i] then
            table.insert(chan_ids, i)
        end
    end

    return chan_ids

end

local function SetSrcTrackChannels(track, selected_channels)
    n_chan = r.GetMediaTrackInfo_Value(track, 'I_NCHAN')

    if n_chan < selected_channels[#selected_channels] + 2 then
        r.SetMediaTrackInfo_Value(track, 'I_NCHAN', selected_channels[#selected_channels] + 2)
    end
end

local function SetDstTrackChannels(track, selected_channel)
    n_chan = r.GetMediaTrackInfo_Value(track, 'I_NCHAN')

    if n_chan < selected_channel + 2 then
        r.SetMediaTrackInfo_Value(track, 'I_NCHAN', selected_channel + 2)
    end
end

local function StartSendCreation()

    sel_track_count = r.CountSelectedTracks(0)

    dest_tracks = ProcessTrackSelectionTable()
    chan_ids = ProcessChanSelectionTable()

    for i = 0, sel_track_count - 1 do
        current = r.GetSelectedTrack(0, i)

        for _, v in ipairs(dest_tracks) do
            dest = r.GetTrack(0, v)

            if mode == 0 then

                -- SEND MODE
                SetSrcTrackChannels(current, chan_ids)
                SetDstTrackChannels(dest, dst_channel)

                for _, src in ipairs(chan_ids) do

                    send_idx = r.CreateTrackSend(current, dest)

                    r.BR_GetSetTrackSendInfo(current, 0, send_idx, 'I_SRCCHAN', true, src)
                    r.BR_GetSetTrackSendInfo(current, 0, send_idx, 'I_DSTCHAN', true, dst_channel)
                    r.BR_GetSetTrackSendInfo(current, 0, send_idx, 'I_SENDMODE', true, send_position)
                end
            else
                -- RECEIVE MODE
                SetSrcTrackChannels(dest, chan_ids)
                SetDstTrackChannels(current, dst_channel)

                for _, src in ipairs(chan_ids) do

                    send_idx = r.CreateTrackSend(dest, current)

                    r.BR_GetSetTrackSendInfo(dest, 0, send_idx, 'I_SRCCHAN', true, src)
                    r.BR_GetSetTrackSendInfo(dest, 0, send_idx, 'I_DSTCHAN', true, dst_channel)
                    r.BR_GetSetTrackSendInfo(dest, 0, send_idx, 'I_SENDMODE', true, send_position)

                end
            end
        end
    end
end

-------------GUI-------------

local function GUI_DrawChanSelectorWindow()

    visible, open = r.ImGui_Begin(GuiData.ctx, 'Ch Selector Tester', true)

    if visible then
        if r.ImGui_CollapsingHeader(GuiData.ctx, 'Source Channels') then

            r.ImGui_BeginTable(GuiData.ctx, 'SourceTable', 4, GuiData.TableFlags)
            r.ImGui_PushStyleVar(GuiData.ctx, r.ImGui_StyleVar_SelectableTextAlign(), 0.5, 0.5)
            for i = 0, MAX_CHAN_NUM - 1, 2 do
                r.ImGui_TableNextColumn(GuiData.ctx)

                rv, src_channels[i] = r.ImGui_Selectable(GuiData.ctx, (i + 1) .. '-' .. (i + 2), src_channels[i])
            end
            r.ImGui_PopStyleVar(GuiData.ctx)
            r.ImGui_EndTable(GuiData.ctx)

        end

        if r.ImGui_CollapsingHeader(GuiData.ctx, 'Destination Channels') then

            r.ImGui_BeginTable(GuiData.ctx, 'DestTable', 4, GuiData.TableFlags)
            r.ImGui_PushStyleVar(GuiData.ctx, r.ImGui_StyleVar_SelectableTextAlign(), 0.5, 0.5)
            for i = 0, MAX_CHAN_NUM - 1, 2 do
                r.ImGui_TableNextColumn(GuiData.ctx)

                r.ImGui_Selectable(GuiData.ctx, (i + 1) .. '-' .. (i + 2), i == dst_channel)
                if r.ImGui_IsItemClicked(GuiData.ctx) then
                    dst_channel = i
                end

            end
            r.ImGui_PopStyleVar(GuiData.ctx)
            r.ImGui_EndTable(GuiData.ctx)

        end

        if r.ImGui_Button(GuiData.ctx, 'Run') and not GuiData.selectionMade then
            StartSendCreation()
            GuiData.selectionMade = true
        end

        r.ImGui_End(GuiData.ctx)
    end

    return open
end

local function GUI_DrawMenuBar()

    r.ImGui_BeginMenuBar(GuiData.ctx)
    if r.ImGui_BeginMenu(GuiData.ctx, 'Mode: ' .. (mode == 0 and 'S' or 'R')) then
        r.ImGui_MenuItem(GuiData.ctx, 'Send', nil, mode == 0, true)
        if r.ImGui_IsItemClicked(GuiData.ctx) then
            mode = 0
        end

        r.ImGui_MenuItem(GuiData.ctx, 'Receive', nil, mode == 1, true)
        if r.ImGui_IsItemClicked(GuiData.ctx) then
            mode = 1
        end

        r.ImGui_Separator(GuiData.ctx)

        r.ImGui_MenuItem(GuiData.ctx, 'Post-Fader', nil, send_position == 0, true)
        if r.ImGui_IsItemClicked(GuiData.ctx) then
            send_position = 0
        end
        r.ImGui_MenuItem(GuiData.ctx, 'Pre-Fader', nil, send_position == 3, true)
        if r.ImGui_IsItemClicked(GuiData.ctx) then
            send_position = 3
        end

        r.ImGui_MenuItem(GuiData.ctx, 'Pre-FX', nil, send_position == 1, true)
        if r.ImGui_IsItemClicked(GuiData.ctx) then
            send_position = 1
        end

        r.ImGui_EndMenu(GuiData.ctx)
    end

    r.ImGui_SameLine(GuiData.ctx)
    if r.ImGui_SmallButton(GuiData.ctx, 'Clear') then
        GuiData.selectedInTree = {}
    end

    if r.ImGui_SmallButton(GuiData.ctx, 'Channels') then
        GuiData.showChanSelector = not GuiData.showChanSelector
    end

    r.ImGui_EndMenuBar(GuiData.ctx)
end

local function GUI_DrawCollapseButtons()
    local open_action = -1

    r.ImGui_PushStyleVar(GuiData.ctx, r.ImGui_StyleVar_FrameRounding(), 10)

    if r.ImGui_ArrowButton(GuiData.ctx, 'collapse_all', 2) then
        open_action = 0
    end
    r.ImGui_SameLine(GuiData.ctx)
    if r.ImGui_ArrowButton(GuiData.ctx, 'expand_all', 3) then
        open_action = 1
    end

    r.ImGui_PopStyleVar(GuiData.ctx)
    return open_action
end

local function GUI_DrawSearchBar()
    -- Give focus to the search bar on first frame
    if GuiData.firstFrame then
        r.ImGui_SetKeyboardFocusHere(GuiData.ctx)
        GuiData.firstFrame = false
    end

    -- rv, user_input = r.ImGui_InputText(gui.ctx, 'Search', user_input)
    r.ImGui_PushID(GuiData.ctx, '-------SearchBar')
    rv, GuiData.searchboxBuffer = r.ImGui_InputTextWithHint(GuiData.ctx, '', 'Search', GuiData.searchboxBuffer)
    r.ImGui_PopID(GuiData.ctx)

end

local function GUI_DrawTrackTree(open_action)
    if r.ImGui_BeginChild(GuiData.ctx, 'ChildWindow', 0, 0, false) then
        local parent_open, depth, open_depth = true, 0, 0

        local function DoOpenAction()
            if open_action ~= -1 then
                r.ImGui_SetNextItemOpen(GuiData.ctx, open_action ~= 0)
            end
        end

        for i = 0, r.GetNumTracks() - 1 do
            local track = r.GetTrack(nil, i)
            local rv, name = r.GetTrackName(track)

            if string.match(string.lower(name), "(" .. TrimString(GuiData.searchboxBuffer) .. ")") then

                local depth_delta = r.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH')
                depth_delta = math.max(depth_delta, -depth) -- prevent depth + delta being < 0
                local is_folder = depth_delta > 0

                if parent_open or depth <= open_depth then
                    -- close previously open deeper folders
                    for level = depth, open_depth - 1 do
                        r.ImGui_TreePop(GuiData.ctx)
                        open_depth = depth
                    end

                    if GuiData.selectedInTree[i] == nil then
                        GuiData.selectedInTree[i] = false
                    end

                    node_flags = is_folder and GuiData.TreeFlags.base or GuiData.TreeFlags.leaf

                    if GuiData.selectedInTree[i] == true then
                        node_flags = node_flags | r.ImGui_TreeNodeFlags_Selected()
                    end

                    local track_color = r.ImGui_ColorConvertNative(r.GetTrackColor(track))
                    r.ImGui_ColorButton(GuiData.ctx, 'color', track_color,
                        r.ImGui_ColorEditFlags_NoAlpha() | r.ImGui_ColorEditFlags_NoTooltip(), 12, 12)

                    r.ImGui_SameLine(GuiData.ctx)

                    DoOpenAction()

                    r.ImGui_PushID(GuiData.ctx, i) -- disambiguate if two tracks in the same level have the same name
                    parent_open = r.ImGui_TreeNode(GuiData.ctx, name, node_flags)
                    r.ImGui_PopID(GuiData.ctx)

                    if r.ImGui_IsItemClicked(GuiData.ctx) then
                        if r.ImGui_IsMouseDoubleClicked(GuiData.ctx, 0) and not GuiData.selectionMade then
                            GuiData.selectedInTree[i] = true
                            StartSendCreation()
                            GuiData.selectionMade = true
                        else
                            GuiData.selectedInTree[i] = not GuiData.selectedInTree[i]
                        end
                    end

                end

                depth = depth + depth_delta
                if is_folder and parent_open then
                    open_depth = depth
                end
            end
        end

        for level = 0, open_depth - 1 do
            r.ImGui_TreePop(GuiData.ctx)
        end
        r.ImGui_EndChild(GuiData.ctx)
    end
end

local function frame()

    r.ImGui_SetNextWindowSize(GuiData.ctx, 300, 400, r.ImGui_Cond_Always())
    local visible, open = r.ImGui_Begin(GuiData.ctx, 'SendBox', true, r.ImGui_WindowFlags_MenuBar())

    if visible then

        GUI_DrawMenuBar()

        if GuiData.showChanSelector then
            GuiData.showChanSelector = GUI_DrawChanSelectorWindow()
        end

        open_action = GUI_DrawCollapseButtons()
        r.ImGui_SameLine(GuiData.ctx)
        GUI_DrawSearchBar()
        GUI_DrawTrackTree(open_action)

        r.ImGui_End(GuiData.ctx)
    end

    if not GuiData.selectionMade and open then
        r.defer(frame)
    else
        r.ImGui_DestroyContext(GuiData.ctx)
    end
end

r.Undo_BeginBlock()

r.defer(frame)

r.Undo_EndBlock("Manup-Create Track Sends", -1)

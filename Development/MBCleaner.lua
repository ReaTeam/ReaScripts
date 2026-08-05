-- @description MBCleaner
-- @author vovvee
-- @version 1.0
-- @about
--   # MBCleaner
--
--   Clean Project Media & Backups
--
--   A project-aware media cleaner for REAPER.
--   Scans the project directory for unused media files and project backups, helps identify wasted disk space, and lets you safely remove what’s no longer needed.
--
--   Features:
--
--   Detects unused media files in the project folder
--
--   Scans and manages project backup files
--
--   Dry Run mode for safe testing before deletion
--
--   Fast search and filtering across media files
--
--   Clear overview of disk usage and selected items
--
--   Designed to make project cleanup transparent, controlled, and safe.

-- @description Clean Unused Project Files (Fix Stack Pop)
-- @version 5.0
-- @author vovvee
-- @about MBCleaner

local r = reaper
local ctx = r.ImGui_CreateContext('MBCleaner')

-- СОСТОЯНИЕ
local state = {
    files = {},
    backups = {}, -- New: Backups list
    total_size = 0,
    selected_size = 0,
    dry_run = true,
    scan_needed = true,
    filter = "",
    -- Sorting state
    sort_key = "name", 
    sort_asc = true,
    active_tab = 1, -- 1: Clean, 2: Backups
    files_sort = { key = "name", asc = true },
    backups_sort = { key = "date", asc = false } -- Default date desc for backups
}

local allowed_ext = {['.wav']=true, ['.mp3']=true, ['.flac']=true, ['.aiff']=true, ['.ogg']=true}
local sep = package.config:sub(1,1)

----------------------------------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
----------------------------------------------------------------------

local function GetVal(key)
    if type(key) == "function" then return key() end
    return key
end

local function get_file_mod_time(path)
    -- Try lfs
    local success, lfs = pcall(require, "lfs")
    if success and lfs then
        return lfs.attributes(path, "modification") or 0
    end
    -- Fallback for macOS/Linux
    local handle = io.popen("stat -f %m \"" .. path .. "\"")
    if handle then
        local result = handle:read("*a")
        handle:close()
        return tonumber(result) or 0
    end
    return 0
end

local function format_date(timestamp)
    if not timestamp or timestamp == 0 then return "-" end
    return os.date("%Y-%m-%d %H:%M", timestamp)
end

local function format_size(bytes)
    if not bytes or bytes == 0 then return "0 B" end
    if bytes < 1024 * 1024 then return string.format("%.1f KB", bytes / 1024) end
    return string.format("%.1f MB", bytes / (1024 * 1024))
end

local function escape_lua_pattern(s)
    return s:gsub("([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
end

local function normalize_path(path)
    if not path then return "" end
    local p = path:gsub("\\", "/")
    -- Strip trailing slash
    if p:sub(-1) == "/" then p = p:sub(1, -2) end
    return p
end

local function get_directory_only(full_path)
    local n_full = normalize_path(full_path)
    local dir = n_full:match("^(.*)/[^/]*$")
    if dir then return dir end
    return n_full
end

local function GetProjectLocation()
    -- Try to get the exact .rpp path
    local proj, projfn = r.EnumProjects(-1)
    if projfn and projfn ~= "" then
        -- Extract directory from full path
        local dir = projfn:match("(.*)[\\/].*$")
        if dir then return dir end
    end
    -- Fallback
    return r.GetProjectPath()
end

local function ShowFileContextMenu(file, id_suffix)
    if r.ImGui_BeginPopupContextItem(ctx, "ctx_" .. id_suffix) then
        if r.ImGui_MenuItem(ctx, "Show in Finder/Explorer") then
            r.CF_LocateInExplorer(file.path)
        end
        r.ImGui_EndPopup(ctx)
    end
end

local function truncate_path_head(path, max_chars)
    if not path then return "" end
    if #path <= max_chars then return path end
    return "..." .. path:sub(-max_chars)
end

local function ScanFiles()
    -- r.ShowConsoleMsg("--- Starting Scan ---\n")
    state.files = {}
    state.backups = {}
    state.total_size = 0
    
    local proj_path = GetProjectLocation()
    if not proj_path or proj_path == "" then 
        -- r.ShowConsoleMsg("Error: Project path is empty. Please save the project.\n")
        return 
    end
    
    -- Normalize project path for consistency
    proj_path = normalize_path(proj_path)
    state.current_proj_path = proj_path -- Store for GUI display
    -- r.ShowConsoleMsg("Project Root: " .. proj_path .. "\n")
    
    local used = {}
    for i = 0, r.CountMediaItems(0) - 1 do
        local item = r.GetMediaItem(0, i)
        for t = 0, r.CountTakes(item) - 1 do
            local take = r.GetMediaItemTake(item, t)
            if take then
                local src = r.GetMediaItemTake_Source(take)
                if src then
                    local parent = r.GetMediaSourceParent(src)
                    local final_src = parent ~= nil and parent or src
                    local fn = r.GetMediaSourceFileName(final_src, "")
                    if fn ~= "" then 
                        used[normalize_path(fn):lower()] = true 
                    end
                end
            end
        end
    end

    local function search(path)
        local idx = 0
        while true do
            local f = r.EnumerateFiles(path, idx)
            if not f then break end
            local ext = f:match("^.+(%..+)$")
            if ext and allowed_ext[ext:lower()] then
                local full = path .. "/" .. f
                if not used[normalize_path(full):lower()] then
                    local f_ptr = io.open(full, "rb")
                    local size = f_ptr and f_ptr:seek("end") or 0
                    if f_ptr then f_ptr:close() end
                    local date = get_file_mod_time(full)
                    table.insert(state.files, {name=f, path=full, size=size, date=date, selected=false})
                end
            end
            idx = idx + 1
        end
        local d_idx = 0
        while true do
            local d = r.EnumerateSubdirectories(path, d_idx)
            if not d then break end
            if d ~= "reapeaks" and d ~= "." and d ~= ".." then search(path .. "/" .. d) end
            d_idx = d_idx + 1
        end
    end

    search(proj_path)
    
    -- Scan Backups (Recursive)
    local function search_backups(path)
        local idx = 0
        while true do
            local f = r.EnumerateFiles(path, idx)
            if not f then break end
            -- Check extension with pattern
            if f:lower():match("%.rpp%-bak$") then
                local full = path .. "/" .. f
                local f_ptr = io.open(full, "rb")
                local size = f_ptr and f_ptr:seek("end") or 0
                if f_ptr then f_ptr:close() end
                local date = get_file_mod_time(full)
                table.insert(state.backups, {name=f, path=full, size=size, date=date, selected=false})
            end
            idx = idx + 1
        end
        local d_idx = 0
        while true do
            local d = r.EnumerateSubdirectories(path, d_idx)
            if not d then break end
            if d ~= "reapeaks" and d ~= "." and d ~= ".." then search_backups(path .. "/" .. d) end
            d_idx = d_idx + 1
        end
    end
    
    search_backups(proj_path)

    -- r.ShowConsoleMsg("Scan complete. Files: " .. #state.files .. ", Backups: " .. #state.backups .. "\n")
    for _, f in ipairs(state.files) do state.total_size = state.total_size + f.size end
    state.scan_needed = false
end

local function SortList(list, sort_state)
    table.sort(list, function(a, b)
        local va = a[sort_state.key]
        local vb = b[sort_state.key]
        if type(va) == "string" then va = va:lower() end
        if type(vb) == "string" then vb = vb:lower() end
        if sort_state.asc then return va < vb else return va > vb end
    end)
end

local function DrawFakeWaveform(draw_list, x, y, w, h, seed)
    local segments = 10
    local seg_w = w / segments
    math.randomseed(seed)
    for i = 0, segments - 1 do
        local val = math.random() * (h * 0.65)
        local color = 0x555555FF 
        r.ImGui_DrawList_AddRectFilled(draw_list, x + (i * seg_w) + 1, y + (h/2) - (val/2), x + ((i+1) * seg_w) - 1, y + (h/2) + (val/2), color)
    end
end

----------------------------------------------------------------------
-- GUI
----------------------------------------------------------------------

local function loop()
    -- СТЕК ЦВЕТОВ (НАЧАЛО: 13 Push)
    r.ImGui_PushStyleColor(ctx, GetVal(r.ImGui_Col_WindowBg),       0x1A1A1AFF) -- 1
    r.ImGui_PushStyleColor(ctx, GetVal(r.ImGui_Col_Button),         0x333333FF) -- 2
    r.ImGui_PushStyleColor(ctx, GetVal(r.ImGui_Col_FrameBg),        0x252525FF) -- 3
    r.ImGui_PushStyleColor(ctx, GetVal(r.ImGui_Col_CheckMark),      0x52D6B1FF) -- 4
    r.ImGui_PushStyleColor(ctx, GetVal(r.ImGui_Col_FrameBgActive),  0x3A8C75FF) -- 5
    r.ImGui_PushStyleColor(ctx, GetVal(r.ImGui_Col_Header),         0x2A2A2AFF) -- 6
    -- New Colors for Dark Title
    r.ImGui_PushStyleColor(ctx, GetVal(r.ImGui_Col_TitleBg),        0x1F1F1FFF) -- 7
    r.ImGui_PushStyleColor(ctx, GetVal(r.ImGui_Col_TitleBgActive),  0x1F1F1FFF) -- 8
    -- Tab Colors
    r.ImGui_PushStyleColor(ctx, GetVal(r.ImGui_Col_Tab) or 33,                0x1F1F1FFF) -- 9
    r.ImGui_PushStyleColor(ctx, GetVal(r.ImGui_Col_TabHovered) or 34,         0x383838FF) -- 10
    r.ImGui_PushStyleColor(ctx, GetVal(r.ImGui_Col_TabActive) or 35,          0x2A2A2AFF) -- 11
    r.ImGui_PushStyleColor(ctx, GetVal(r.ImGui_Col_TabUnfocused) or 36,       0x1F1F1FFF) -- 12
    r.ImGui_PushStyleColor(ctx, GetVal(r.ImGui_Col_TabUnfocusedActive) or 37, 0x2A2A2AFF) -- 13
    
    r.ImGui_PushStyleVar(ctx, GetVal(r.ImGui_StyleVar_FrameRounding), 4)
    r.ImGui_PushStyleVar(ctx, GetVal(r.ImGui_StyleVar_WindowRounding), 4)
    
    r.ImGui_SetNextWindowSize(ctx, 800, 600, GetVal(r.ImGui_Cond_Appearing))
    local visible, open = r.ImGui_Begin(ctx, 'MBCleaner', true, GetVal(r.ImGui_WindowFlags_NoResize))
    
    if visible then
        -- Top Bar
        if state.current_proj_path then
            r.ImGui_TextColored(ctx, 0x666666FF, "PATH: " .. state.current_proj_path)
            r.ImGui_Separator(ctx)
        end
        
        if r.ImGui_Button(ctx, " REFRESH ") or state.scan_needed then ScanFiles() end
        r.ImGui_SameLine(ctx)
        local _, new_dry = r.ImGui_Checkbox(ctx, "DRY RUN", state.dry_run)
        state.dry_run = new_dry
        
        r.ImGui_SameLine(ctx)
        r.ImGui_TextColored(ctx, 0x888888FF, " | ")
        r.ImGui_SameLine(ctx)
        
        if r.ImGui_BeginTabBar(ctx, "MainTabs") then
            -- TAB 1: UNUSED FILES
            if r.ImGui_BeginTabItem(ctx, " UNUSED FILES ") then
                state.active_tab = 1
                r.ImGui_TextColored(ctx, 0x666666FF, "COUNT: " .. #state.files)
                
                r.ImGui_SameLine(ctx, r.ImGui_GetWindowWidth(ctx) - 350)
                r.ImGui_SetNextItemWidth(ctx, 120)
                local f_changed, new_f = r.ImGui_InputText(ctx, "##filter", state.filter)
                if f_changed then state.filter = new_f end
                r.ImGui_SameLine(ctx)
                r.ImGui_TextColored(ctx, 0x444444FF, "search")
                
                r.ImGui_SameLine(ctx)
                if r.ImGui_Button(ctx, "ALL") then
                    for _, f in ipairs(state.files) do f.selected = true end
                end
                r.ImGui_SameLine(ctx)
                if r.ImGui_Button(ctx, "NONE") then
                    for _, f in ipairs(state.files) do f.selected = false end
                end

                if r.ImGui_BeginChild(ctx, 'file_scroll', 0, -90) then
                    local t_flags = GetVal(r.ImGui_TableFlags_RowBg) | GetVal(r.ImGui_TableFlags_ScrollY) | GetVal(r.ImGui_TableFlags_SizingFixedFit) | GetVal(r.ImGui_TableFlags_Resizable)
                    if r.ImGui_BeginTable(ctx, 'nvk_table', 6, t_flags) then
                        r.ImGui_TableSetupColumn(ctx, "X", GetVal(r.ImGui_TableColumnFlags_WidthFixed), 30)
                        r.ImGui_TableSetupColumn(ctx, "WAV", GetVal(r.ImGui_TableColumnFlags_WidthFixed), 60)
                        r.ImGui_TableSetupColumn(ctx, "NAME", GetVal(r.ImGui_TableColumnFlags_WidthStretch), 0)
                        r.ImGui_TableSetupColumn(ctx, "DATE", GetVal(r.ImGui_TableColumnFlags_WidthFixed), 110)
                        r.ImGui_TableSetupColumn(ctx, "FOLDER", GetVal(r.ImGui_TableColumnFlags_WidthStretch), 0)
                        r.ImGui_TableSetupColumn(ctx, "SIZE", GetVal(r.ImGui_TableColumnFlags_WidthFixed), 75)
                        
                        -- Headers
                        r.ImGui_TableNextRow(ctx)
                        r.ImGui_TableSetColumnIndex(ctx, 2)
                        if r.ImGui_Button(ctx, "NAME") then state.files_sort.key="name"; state.files_sort.asc=not state.files_sort.asc; SortList(state.files, state.files_sort) end
                        r.ImGui_TableSetColumnIndex(ctx, 3)
                        if r.ImGui_Button(ctx, "DATE") then state.files_sort.key="date"; state.files_sort.asc=not state.files_sort.asc; SortList(state.files, state.files_sort) end
                        r.ImGui_TableSetColumnIndex(ctx, 4)
                        if r.ImGui_Button(ctx, "FOLDER") then state.files_sort.key="path"; state.files_sort.asc=not state.files_sort.asc; SortList(state.files, state.files_sort) end
                        r.ImGui_TableSetColumnIndex(ctx, 5)
                        if r.ImGui_Button(ctx, "SIZE") then state.files_sort.key="size"; state.files_sort.asc=not state.files_sort.asc; SortList(state.files, state.files_sort) end

                        local sel_size = 0
                        local proj_path = r.GetProjectPath()
                        local safe_proj_path = escape_lua_pattern(proj_path)
                        for i, file in ipairs(state.files) do
                            if state.filter == "" or file.name:lower():find(state.filter:lower()) then
                                r.ImGui_TableNextRow(ctx, 22)
                                r.ImGui_TableSetColumnIndex(ctx, 0)
                                local _, v = r.ImGui_Checkbox(ctx, "##s"..i, file.selected)
                                file.selected = v
                                if file.selected then sel_size = sel_size + file.size end

                                r.ImGui_TableSetColumnIndex(ctx, 1)
                                local x, y = r.ImGui_GetCursorScreenPos(ctx)
                                DrawFakeWaveform(r.ImGui_GetWindowDrawList(ctx), x, y + 2, 55, 16, i * 13)
                                
                                r.ImGui_TableSetColumnIndex(ctx, 2)
                                r.ImGui_Text(ctx, file.name)
                                ShowFileContextMenu(file, "f_"..i)
                                r.ImGui_TableSetColumnIndex(ctx, 3)
                                r.ImGui_TextColored(ctx, 0xAAAAAAFF, format_date(file.date))
                                r.ImGui_TableSetColumnIndex(ctx, 4)
                                local dir_path = get_directory_only(file.path)
                                local short_path = truncate_path_head(dir_path, 35) -- Keep last ~35 chars
                                r.ImGui_TextColored(ctx, 0x888888FF, short_path)
                                if r.ImGui_IsItemHovered(ctx) then
                                    r.ImGui_SetTooltip(ctx, dir_path)
                                end
                                r.ImGui_TableSetColumnIndex(ctx, 5)
                                r.ImGui_TextColored(ctx, 0x666666FF, format_size(file.size))
                            end
                        end
                        state.selected_size = sel_size
                        r.ImGui_EndTable(ctx)
                    end
                    r.ImGui_EndChild(ctx)
                end

                r.ImGui_Separator(ctx)
                r.ImGui_TextColored(ctx, 0x888888FF, "Waste: " .. format_size(state.total_size))
                r.ImGui_TextColored(ctx, 0x52D6B1FF, "Selected: " .. format_size(state.selected_size))
                
                local btn_label = state.dry_run and "TEST (DRY RUN)" or "DELETE SELECTED FILES"
                local btn_col = state.dry_run and 0x333333FF or 0x882222FF
                
                r.ImGui_PushStyleColor(ctx, GetVal(r.ImGui_Col_Button), btn_col)
                if r.ImGui_Button(ctx, btn_label, -1, 40) then
                    if state.selected_size > 0 then
                        local count = 0
                        for _, f in ipairs(state.files) do
                            if f.selected and not state.dry_run then
                                if os.remove(f.path) then 
                                    os.remove(f.path..".reapeaks")
                                    count = count + 1
                                end
                            end
                        end
                        state.scan_needed = true
                        if not state.dry_run then r.MB("Cleaned " .. count .. " files.", "MBCleaner", 0) end
                    end
                end
                r.ImGui_PopStyleColor(ctx, 1)
                
                r.ImGui_EndTabItem(ctx)
            end

            -- TAB 2: BACKUPS
            if r.ImGui_BeginTabItem(ctx, " BACKUPS ") then
                state.active_tab = 2
                r.ImGui_TextColored(ctx, 0x666666FF, "COUNT: " .. #state.backups)
                r.ImGui_SameLine(ctx)
                if r.ImGui_Button(ctx, "ALL##bk") then for _, f in ipairs(state.backups) do f.selected = true end end
                r.ImGui_SameLine(ctx)
                if r.ImGui_Button(ctx, "NONE##bk") then for _, f in ipairs(state.backups) do f.selected = false end end
                
                if r.ImGui_BeginChild(ctx, 'backup_scroll', 0, -90) then
                     local t_flags = GetVal(r.ImGui_TableFlags_RowBg) | GetVal(r.ImGui_TableFlags_ScrollY) | GetVal(r.ImGui_TableFlags_SizingFixedFit) | GetVal(r.ImGui_TableFlags_Resizable)
                     if r.ImGui_BeginTable(ctx, 'nvk_table_backups', 4, t_flags) then
                        r.ImGui_TableSetupColumn(ctx, "X", GetVal(r.ImGui_TableColumnFlags_WidthFixed), 30)
                        r.ImGui_TableSetupColumn(ctx, "NAME", GetVal(r.ImGui_TableColumnFlags_WidthStretch), 0)
                        r.ImGui_TableSetupColumn(ctx, "DATE", GetVal(r.ImGui_TableColumnFlags_WidthFixed), 120)
                        r.ImGui_TableSetupColumn(ctx, "SIZE", GetVal(r.ImGui_TableColumnFlags_WidthFixed), 75)
                        
                        r.ImGui_TableNextRow(ctx)
                        r.ImGui_TableSetColumnIndex(ctx, 1)
                        if r.ImGui_Button(ctx, "NAME##b") then state.backups_sort.key="name"; state.backups_sort.asc=not state.backups_sort.asc; SortList(state.backups, state.backups_sort) end
                        r.ImGui_TableSetColumnIndex(ctx, 2)
                        if r.ImGui_Button(ctx, "DATE##b") then state.backups_sort.key="date"; state.backups_sort.asc=not state.backups_sort.asc; SortList(state.backups, state.backups_sort) end
                        r.ImGui_TableSetColumnIndex(ctx, 3)
                        if r.ImGui_Button(ctx, "SIZE##b") then state.backups_sort.key="size"; state.backups_sort.asc=not state.backups_sort.asc; SortList(state.backups, state.backups_sort) end

                        local sel_size_bk = 0
                        for i, file in ipairs(state.backups) do
                             r.ImGui_TableNextRow(ctx, 22)
                             r.ImGui_TableSetColumnIndex(ctx, 0)
                             local _, v = r.ImGui_Checkbox(ctx, "##bk"..i, file.selected)
                             file.selected = v
                             if file.selected then sel_size_bk = sel_size_bk + file.size end

                             r.ImGui_TableSetColumnIndex(ctx, 1)
                             r.ImGui_Text(ctx, file.name)
                             ShowFileContextMenu(file, "b_"..i)
                             r.ImGui_TableSetColumnIndex(ctx, 2)
                             r.ImGui_TextColored(ctx, 0xAAAAAAFF, format_date(file.date))
                             r.ImGui_TableSetColumnIndex(ctx, 3)
                             r.ImGui_TextColored(ctx, 0x666666FF, format_size(file.size))
                        end
                        state.selected_size_bk = sel_size_bk
                        r.ImGui_EndTable(ctx)
                     end
                     r.ImGui_EndChild(ctx)
                end
                
                r.ImGui_Separator(ctx)
                r.ImGui_TextColored(ctx, 0x52D6B1FF, "Selected: " .. format_size(state.selected_size_bk or 0))
                
                local btn_label = state.dry_run and "TEST (DRY RUN)" or "DELETE BACKUPS"
                local btn_col = state.dry_run and 0x333333FF or 0x882222FF
                r.ImGui_PushStyleColor(ctx, GetVal(r.ImGui_Col_Button), btn_col)
                if r.ImGui_Button(ctx, btn_label, -1, 40) then
                     if state.selected_size_bk and state.selected_size_bk > 0 then
                        local count = 0
                        for _, f in ipairs(state.backups) do
                            if f.selected and not state.dry_run then
                                if os.remove(f.path) then count = count + 1 end
                            end
                        end
                        state.scan_needed = true
                        if not state.dry_run then r.MB("Deleted " .. count .. " backups.", "NVK Cleaner", 0) end
                    end
                end
                r.ImGui_PopStyleColor(ctx, 1)

                r.ImGui_EndTabItem(ctx)
            end
            r.ImGui_EndTabBar(ctx)
        end
        
        r.ImGui_End(ctx)
    end
    
    r.ImGui_PopStyleVar(ctx, 2)
    r.ImGui_PopStyleColor(ctx, 13) -- 13 Pushed Colors
    
    if open then r.defer(loop) end
end

r.defer(loop)


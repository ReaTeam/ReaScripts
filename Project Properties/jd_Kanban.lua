-- @description Kanban
-- @author Julyday
-- @version 1.0.1
-- @changelog
--   ### Added
--   - Project change detection and automatic task reloading when switching between projects
--   - Graceful handling of unsaved projects with user prompt to save before proceeding
--   - Support for storing tasks directly in project files using REAPER's extended state system
--   - Automatic project dirty marking when tasks are modified
--
--   ### Changed
--   - **BREAKING**: Replaced INI file storage with REAPER's `SetProjExtState`/`GetProjExtState` system
--   - Tasks are now stored inside the project file instead of adjacent INI files
--   - Improved project path handling using `EnumProjects(-1)` instead of `GetProjectPath()`
--   - Enhanced project state monitoring with `GetProjectStateChangeCount()`
--
--   ### Fixed
--   - Resolved issues with `GetProjectPath()` referring to global media directory instead of per-project paths
--   - Fixed script behavior when active project changes while script is running
--   - Improved handling of project tab switching and "Open..." dialog interactions
-- @about
--   # Kanban
--   Graphical interface for managing project tasks in REAPER as a Kanban board.
--   ## Features:
--   - Three columns: "Backlog", "To Do", "Done"
--   - Create tasks by right-clicking in a column
--   - Edit tasks by right-clicking on an existing task
--   - Drag tasks between columns and reorder within columns
--   - Delete tasks with the X button
--   - Automatic saving to tasks.ini file
--   - Support for multi-line text and word wrapping
--   - Visual task status indicators
--   - Scroll content with mouse wheel
--
--   Donations (crypto):
--   USDT (TRC20) - TTYgm2v1PV6hXYnqNu6hZb9ddu6TSqzZkU
--   USDT (ERC20) - 0x481728FD856603ECaB8b222DFC2428E67Fd92E4E
--   Bitcoin (BTC) - 18viyeLPCSYosz1bVw3aavC189Y2jE3SFm
--   Toncoin (TON) - UQAqtnyzZxDpGB6Os0HbSG1LZdq57MxDXIGoNFyGDvHHZPB8
--   Etherium (ETH) - 00x481728FD856603ECaB8b222DFC2428E67Fd92E4E
--   TRON     (TRX) - TVXuH9mJgDsRkb1CzBSHCdMKC7eRKxcqei


reaper.set_action_options(1)

-- Get current project and handle unsaved projects
local proj, project_path = reaper.EnumProjects(-1)
if #project_path == 0 then
    if reaper.MB('      The project must be saved\n\n      before the script can work.\n\n\t     Save now?', 'Kanban', 4) == 6 then
        reaper.Main_SaveProject(0, false) -- forceSaveAsIn false, but for unsaved project doesn't matter
        proj, project_path = reaper.EnumProjects(-1)
        if #project_path == 0 then -- user closed Save dialogue without saving
            return reaper.defer(function() do return end end)
        end
    else -- user declined the prompt
        return reaper.defer(function() do return end end)
    end
end

local current_project = proj
local ext_name = "Kanban"
local window_w, window_h = 1280, 900
local column_w = window_w / 3
local task_height = 40
local font_size = 16
local column_titles = {"Backlog", "To Do", "Done"}
local columns = {{}, {}, {}}
local drag_task = nil
local rename_task = nil
local font = nil
local font_bold = nil
local clicked_x_button = false
local header_height = 44
local scroll_y = 0
local scroll_speed = 30
local max_scroll = 0
local is_scrolling = false
local last_scroll_y = 0
local last_wheel = 0
local click_count = 0
local last_click_x, last_click_y, last_click_col = 0, 0, 0
local last_mouse_state = 0
local click_timer = 0
local project_state_change_count = 0
local colors = {
    background = {0.15, 0.16, 0.21, 1.0},
    foreground = {0.67, 0.70, 0.75, 1.0},
    comment = {0.39, 0.45, 0.64, 1.0},
    selection = {0.27, 0.28, 0.35, 1.0},
    accent = {0.2, 0.55, 1.0, 1.0},
    column_bg = {0.16, 0.17, 0.22, 1.0},
    column_header = {0.24, 0.28, 0.41, 1.0},
    task_bg = {0.21, 0.23, 0.28, 1.0},
    task_border = {0.31, 0.33, 0.43, 1.0},
    task_hover = {0.24, 0.26, 0.31, 1.0},
    todo = {0.54, 0.91, 0.99, 1.0},
    inprogress = {0.74, 0.58, 0.98, 1.0},
    done = {0.31, 0.98, 0.48, 1.0},
    delete = {1.0, 0.33, 0.33, 1.0},
}
local column_status_colors = {
    colors.todo,
    colors.inprogress,
    colors.done
}
local function format_text_lines(text, max_width)
    local lines = {}
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    local current_line = ""
    for _, word in ipairs(words) do
        local test_line = current_line .. (current_line == "" and "" or " ") .. word
        local text_w = gfx.measurestr(test_line)
        if text_w > max_width then
            table.insert(lines, current_line)
            current_line = word
        else
            current_line = test_line
        end
    end
    if current_line ~= "" then
        table.insert(lines, current_line)
    end
    return lines
end
local Task = {}
Task.__index = Task
function Task.new(text, column)
    local self = setmetatable({}, Task)
    self.text = text
    self.column = column
    self.x = 0
    self.y = 0
    self.width = column_w - 20
    self.height = task_height
    self.done = (column == 3)
    self.hover = false
    self.lines = {}
    self:calculate_height()
    return self
end
function Task:calculate_height()
    self.lines = format_text_lines(self.text, self.width - 40)
    gfx.setfont(1)
    local line_height = gfx.texth + 2
    local text_height = #self.lines * line_height
    local min_padding = 20
    self.height = math.max(task_height, text_height + min_padding)
end
function Task:draw(gfx)
    if self.y + self.height < header_height then return end
    local column_offset = (self.column - 1) * column_w
    local x = self.x + column_offset + 10
    local y = self.y
    local radius = 6
    local bg_color
    if self.column == 1 then
        bg_color = {0.21, 0.23, 0.29, 1.0}
    elseif self.column == 2 then
        bg_color = {0.22, 0.22, 0.29, 1.0}
    else
        bg_color = {0.21, 0.24, 0.28, 1.0}
    end
    if self.hover then
        bg_color = {bg_color[1] + 0.05, bg_color[2] + 0.05, bg_color[3] + 0.05, bg_color[4]}
    end
    local visible_height = self.height
    local visible_y = y
    if y < header_height then
        visible_height = self.height - (header_height - y)
        visible_y = header_height
    end
    gfx.set(table.unpack(bg_color))
    gfx.rect(x, visible_y, self.width, visible_height)
    local status_color
    if self.column == 1 then
        status_color = colors.todo
    elseif self.column == 2 then
        status_color = colors.inprogress
    else
        status_color = colors.done
    end
    gfx.set(table.unpack(status_color))
    gfx.rect(x, visible_y, 4, visible_height)
    gfx.set(table.unpack(colors.task_border))
    gfx.rect(x, visible_y, self.width, visible_height, false)
    gfx.set(table.unpack(colors.delete))
    local x_size = 10
    local x_x = self.x + column_offset + self.width - x_size - 10
    local x_y = visible_y + 15
    gfx.line(x_x, x_y, x_x + x_size, x_y + x_size)
    gfx.line(x_x + x_size, x_y, x_x, x_y + x_size)
    gfx.setfont(1)
    if self.done then
        gfx.set(table.unpack(colors.foreground))
        local line_height = gfx.texth + 2
        local start_y = visible_y + 15
        for i, line in ipairs(self.lines) do
            local text_x = self.x + column_offset + 20
            local text_y = start_y + (i-1) * line_height
            gfx.x = text_x
            gfx.y = text_y
            gfx.drawstr(line)
            gfx.set(table.unpack(colors.done))
            gfx.line(text_x, text_y + gfx.texth/2, text_x + gfx.measurestr(line), text_y + gfx.texth/2)
        end
    else
        gfx.set(table.unpack(colors.foreground))
        local line_height = gfx.texth + 2
        local start_y = visible_y + 15
        for i, line in ipairs(self.lines) do
            gfx.x = self.x + column_offset + 20
            gfx.y = start_y + (i-1) * line_height
            gfx.drawstr(line)
        end
    end
end
function Task:contains(x, y)
    local column_offset = (self.column - 1) * column_w
    return x >= self.x + column_offset + 10 and
           x <= self.x + column_offset + 10 + self.width and
           y >= self.y and
           y <= self.y + self.height
end
function Task:contains_x_button(x, y)
    local column_offset = (self.column - 1) * column_w
    local x_size = 10
    local x_x = self.x + column_offset + self.width - x_size - 10
    local x_y = self.y + 15
    return x >= x_x and x <= x_x + x_size and
           y >= x_y and y <= x_y + x_size
end
function load_tasks()
    columns = {{}, {}, {}}

    -- Load tasks from project extended state
    for col = 1, 3 do
        local retval, task_data = reaper.GetProjExtState(current_project, ext_name, "column_" .. col)
        if retval == 1 and task_data ~= "" then
            -- Parse tasks from stored data
            for task_text in task_data:gmatch("[^\n]+") do
                if task_text ~= "" then
                    table.insert(columns[col], Task.new(task_text, col))
                end
            end
        end
    end

    update_task_positions()
end
function save_tasks()
    -- Save tasks to project extended state
    for col = 1, 3 do
        local task_data = ""
        for i, task in ipairs(columns[col]) do
            if i > 1 then
                task_data = task_data .. "\n"
            end
            task_data = task_data .. task.text
        end
        reaper.SetProjExtState(current_project, ext_name, "column_" .. col, task_data)
    end

    -- Mark project as dirty to indicate changes
    reaper.MarkProjectDirty(current_project)
end
function check_project_changes()
    local new_proj, new_path = reaper.EnumProjects(-1)
    local new_state_count = reaper.GetProjectStateChangeCount(new_proj)

    -- Check if project changed
    if new_proj ~= current_project then
        current_project = new_proj
        if #new_path == 0 then
            -- Project is not saved, close the script
            reaper.ShowMessageBox("Project changed to unsaved project. Closing Kanban.", "Info", 0)
            gfx.quit()
            return false
        end
        load_tasks() -- Reload tasks from new project
        return true
    end

    -- Update state change count
    if new_state_count ~= project_state_change_count then
        project_state_change_count = new_state_count
    end

    return false
end
function update_task_positions()
    local max_content_height = 0
    for col = 1, 3 do
        local current_y = header_height
        for _, task in ipairs(columns[col]) do
            task:calculate_height()
            task.x = 0
            task.y = current_y - scroll_y
            task.column = col
            task.done = (col == 3)
            current_y = current_y + task.height + 10
        end
        if #columns[col] > 0 then
            local last_task = columns[col][#columns[col]]
            local col_height = last_task.y + last_task.height + scroll_y
            max_content_height = math.max(max_content_height, col_height)
        end
    end
    max_scroll = math.max(0, max_content_height - window_h + 100)
    scroll_y = math.min(scroll_y, max_scroll)
end
function get_column_at(x)
    return math.min(3, math.max(1, math.floor(x / column_w) + 1))
end
function draw()
    gfx.set(table.unpack(colors.background))
    gfx.rect(0, 0, window_w, window_h, true)
    gfx.setfont(2)
    for i = 1, 3 do
        local x = (i - 1) * column_w
        local column_color
        if i == 1 then
            column_color = colors.todo
        elseif i == 2 then
            column_color = colors.inprogress
        else
            column_color = colors.done
        end
        gfx.set(table.unpack(colors.column_header))
        gfx.rect(x, 0, column_w, header_height)
        gfx.set(table.unpack(column_status_colors[i]))
        gfx.rect(x, 0, column_w, 4)
        gfx.set(0.95, 0.95, 0.95, 1.0)
        local title_w, title_h = gfx.measurestr(column_titles[i])
        gfx.x = x + (column_w - title_w) / 2
        gfx.y = 15
        gfx.drawstr(column_titles[i])
    end
    local scrollbar_width = 10
    local scrollbar_x = window_w - scrollbar_width
    local scrollbar_height = window_h - header_height - 10
    local scrollbar_y = header_height + 5
    local scrollbar_thumb_height = math.max(30, scrollbar_height * (window_h / (max_scroll + window_h)))
    local scrollbar_thumb_y = scrollbar_y + (scroll_y / max_scroll) * (scrollbar_height - scrollbar_thumb_height)
    gfx.set(0.2, 0.2, 0.2, 0.5)
    gfx.rect(scrollbar_x, scrollbar_y, scrollbar_width, scrollbar_height)
    gfx.set(0.4, 0.4, 0.4, 0.8)
    gfx.rect(scrollbar_x, scrollbar_thumb_y, scrollbar_width, scrollbar_thumb_height)
    local mx, my = gfx.mouse_x, gfx.mouse_y
    for col = 1, 3 do
        for _, task in ipairs(columns[col]) do
            task.hover = task:contains(mx, my)
        end
    end
    gfx.setfont(1)
    for col = 1, 3 do
        for _, task in ipairs(columns[col]) do
            task:draw(gfx)
        end
    end
    if drag_task then
        local old_column = drag_task.column
        local old_x = drag_task.x
        drag_task.column = get_column_at(gfx.mouse_x)
        drag_task.x = 0
        drag_task.y = gfx.mouse_y - task_height / 2
        drag_task.done = (drag_task.column == 3)
        drag_task.hover = true
        drag_task:draw(gfx)
        drag_task.column = old_column
        drag_task.x = old_x
    end
    gfx.update()
end
function get_clipboard_text()
    if reaper.APIExists("CF_GetClipboard") then
        local clipboard_text = reaper.CF_GetClipboard() or ""
        clipboard_text = clipboard_text:gsub(",", "~~COMMA~~")
        return clipboard_text
    end
    return ""
end
function restore_commas(text)
    if text then
        return text:gsub("~~COMMA~~", ",")
    end
    return text
end
function add_new_task(column, text)
    if not text or text == "" then return end
    text = restore_commas(text)
    text = text:gsub("|", ",")
    local task = Task.new(text, column)
    table.insert(columns[column], task)
    update_task_positions()
    save_tasks()
end
function remove_task(task)
    for col = 1, 3 do
        for i, t in ipairs(columns[col]) do
            if t == task then
                table.remove(columns[col], i)
                update_task_positions()
                save_tasks()
                return
            end
        end
    end
end
function move_task(task, to_column)
    for i, t in ipairs(columns[task.column]) do
        if t == task then
            table.remove(columns[task.column], i)
            break
        end
    end
    task.column = to_column
    task.done = (to_column == 3)
    table.insert(columns[to_column], task)
    update_task_positions()
    save_tasks()
end
function rename_task_dialog(task)
    local use_clipboard = (gfx.mouse_cap & 4) == 4
    local default_text = task.text
    if use_clipboard and reaper.APIExists("CF_GetClipboard") then
        local clipboard_text = reaper.CF_GetClipboard()
        if clipboard_text and clipboard_text ~= "" then
            default_text = clipboard_text:gsub(",", "~~COMMA~~")
        end
    else
        default_text = default_text:gsub(",", "~~COMMA~~")
    end
    local retval, new_text = reaper.GetUserInputs("Rename task", 1, "New name:,extrawidth=400", default_text)
    if retval then
        new_text = restore_commas(new_text)
        new_text = new_text:gsub("|", ",")
        if new_text ~= "" then
            task.text = new_text
            task:calculate_height()
            update_task_positions()
            save_tasks()
        end
    end
end
function init()
    gfx.init("Kanban Board - Project Tasks", window_w, window_h)
    gfx.setfont(1, "Arial", font_size)
    gfx.setfont(2, "Arial", font_size + 4, "b")
    gfx.clear = 0
    project_state_change_count = reaper.GetProjectStateChangeCount(current_project)
    load_tasks()
end
function debug_message(message)
    reaper.ShowConsoleMsg(message .. "\n")
end
function get_task_index_at_position(column, y_pos)
    local tasks = columns[column]
    if #tasks == 0 then
        return 1
    end
    if y_pos < tasks[1].y then
        return 1
    end
    if y_pos > tasks[#tasks].y + task_height then
        return #tasks + 1
    end
    for i = 1, #tasks do
        local task = tasks[i]
        local task_mid = task.y + task_height / 2
        if y_pos < task_mid then
            return i
        end
        if i == #tasks or (y_pos >= task_mid and y_pos < tasks[i+1].y) then
            return i + 1
        end
    end
    return #tasks + 1
end
function handle_mouse_click()
    local mouse_state = gfx.mouse_cap & 1
    local right_mouse_state = gfx.mouse_cap & 2
    local mx, my = gfx.mouse_x, gfx.mouse_y
    local col = get_column_at(mx)
    if mouse_state == 1 and last_mouse_state == 0 then
        clicked_x_button = false
        local clicked_task = nil
        for _, task in ipairs(columns[col]) do
            if task:contains(mx, my) then
                clicked_task = task
                break
            end
        end
        if clicked_task then
            if clicked_task:contains_x_button(mx, my) then
                clicked_x_button = true
                remove_task(clicked_task)
            else
                drag_task = clicked_task
            end
        end
    end
    if mouse_state == 0 and last_mouse_state == 1 and drag_task then
        local new_col = get_column_at(mx)
        if new_col ~= drag_task.column then
            move_task(drag_task, new_col)
        else
            local old_index = 0
            for i, task in ipairs(columns[new_col]) do
                if task == drag_task then
                    old_index = i
                    break
                end
            end
            if old_index > 0 then
                table.remove(columns[new_col], old_index)
                local new_index = get_task_index_at_position(new_col, my)
                table.insert(columns[new_col], new_index, drag_task)
                update_task_positions()
                save_tasks()
            end
        end
        drag_task = nil
    end
    if right_mouse_state == 2 and last_mouse_state & 2 == 0 and not drag_task then
        local clicked_task = nil
        for _, task in ipairs(columns[col]) do
            if task:contains(mx, my) then
                clicked_task = task
                break
            end
        end
        if clicked_task then
            rename_task_dialog(clicked_task)
        elseif my > header_height then
            local default_text = get_clipboard_text()
            local retval, task_text = reaper.GetUserInputs("New Task", 1, "Task name:,extrawidth=400", default_text)
            if retval and task_text ~= "" then
                add_new_task(col, task_text)
            end
        end
    end
    last_mouse_state = gfx.mouse_cap
end
function handle_scrolling()
    local mx, my = gfx.mouse_x, gfx.mouse_y
    local mouse_state = gfx.mouse_cap & 1
    local wheel = gfx.mouse_wheel
    if wheel ~= last_wheel then
        local delta = wheel - last_wheel
        scroll_y = math.max(0, math.min(max_scroll, scroll_y - delta * scroll_speed))
        update_task_positions()
        last_wheel = wheel
    end
    local scrollbar_width = 10
    local scrollbar_x = window_w - scrollbar_width
    local scrollbar_height = window_h - header_height - 10
    local scrollbar_y = header_height + 5
    if mx >= scrollbar_x and mx <= window_w and my >= scrollbar_y and my <= scrollbar_y + scrollbar_height then
        if mouse_state == 1 and not is_scrolling then
            is_scrolling = true
        end
    end
    if is_scrolling then
        if mouse_state == 1 then
            if my >= scrollbar_y and my <= scrollbar_y + scrollbar_height then
                local ratio = (my - scrollbar_y) / scrollbar_height
                scroll_y = math.max(0, math.min(max_scroll, ratio * max_scroll))
                update_task_positions()
            end
        else
            is_scrolling = false
        end
    end
end
function main()
    -- Check if project changed
    if check_project_changes() then
        -- Project changed, tasks were reloaded
        draw()
        local char = gfx.getchar()
        if char == -1 then
            gfx.quit()
            return
        end
        if char ~= 27 and char >= 0 then
            reaper.defer(main)
        end
        return
    end

    handle_scrolling()
    handle_mouse_click()
    if reaper.time_precise() - click_timer > 0.5 then
        click_count = 0
        click_timer = reaper.time_precise()
    end
    draw()
    local char = gfx.getchar()
    if char == -1 then
        gfx.quit()
        return
    end
    if char ~= 27 and char >= 0 then
        reaper.defer(main)
    end
end
init()
main()

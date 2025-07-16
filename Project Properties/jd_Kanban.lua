-- @description Kanban
-- @author Julyday
-- @version 1.0.2
-- @changelog
--   ### Added
--      - Deadline and completed time stamps in 'To Do' and 'Done' colums respectively
--      - Different color for ovedue tasks in 'To Do' column
--      - Arbitrary new line support in task text
--      - Improved task box click animation
--      - Tasks moved between columns are inserted into the new column at the mouse cursor position
--      - Header right-click menu with options to chronologically sort tasks in 'To Do' and 'Done' 
--         columns, restore default window size, batch delete tasks, jump to top/bottom/left/right edge,
--        export/import tasks
--      - Verticial scrollbar has been redesigned into a swipe track which doesn't have 
--        a thumb and doesn't depend on window size. Scroll amount depends on the
--        distance between initial and final mouse curror y coordinate
--      - Horizontal scroll swipe track
--      - Storage and recall of window size, coordinates, dock state and scroll position.
--        When switching between project tabs only the scroll states are recalled.
--      - Restoration of the window focus when task dialogue closes or tasks are imported
--      - Prevention of window resize beyond maximum dimensions
--      - Clock in the header
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



--[[

TIME STAMP

Backlog - no time stamp support
To Do - optional deadline, the dialogie is autofilled with current date and time, 
if date field is empty time is ignored, if time field is empty, defaults 
to 00:00; time stamp which predates the current or equal to it isn't allowed
Done - optional date of completion, the dialogie is autofilled with current date and time, 
any time stamp is allowed

When a task is moved to Done column it gets time stamped with the current time;
When it's moved to 'Backlog' column time stamp is cleared, if any.

An overdue task in 'To Do' column is colored reddish. Obviously only tasks
with a set deadline can become overdue. This will also be the case if a task
is moved from 'Done' column to 'To Do' and its time stamp predates the current one.

'To Do' and 'Done' column tasks can be sorted by right clicking their header and
clicking SORT CHRONOLOGICALLY in the pop-up menu

The task list can be scrolled all the way to the top/bottom via right click
context menu within column header

Default window dimensions can be restored via right click context menu within 
column header.

Task text can be arbitrarily formatted as multi-line through the use of \n operator.
To be recognized it must be preceded and/or followed by space. It can be attached
to the end of a preceding or to the start of the following word. The operator itself
isn't rendered in the output text

When project is reloaded while the script is running, the window contents aren't updated.
They are when the script launched after project reload or after it's terminated and re-launched.


TASKS EXPORT/IMPORT

Tasks can be exported globally or per column to a 'Kanban tasks.txt' file via header 
right click context menu. The file is created automatically in the project directory
if project has an .RPP file or on the Desktop if the project doesn't yet have an .RPP file.
On export if 'Kanban tasks.txt' file already exists at the target location, its content
will be overwritten.

]]



-- reaper.set_action_options(1) -- OLD
  if reaper.set_action_options then reaper.set_action_options(1) end -- MOD // to account for versions older than 7, terminate script if relaunched

-- Get current project and handle unsaved projects
local current_project, current_project_path = reaper.EnumProjects(-1)
--[[ OLD
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
]]

local ext_name = "Kanban"
local window_w, window_h = 1280, 900
----- NEW START -------------------------
-- fall back on the user screen resolution if different from the default values
local lt, top, rt, bot = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, false) -- false - work area, false - the entire screen // https://forum.cockos.com/showthread.php?t=195629#4
local max_w, max_h = rt-lt, bot-top -- bot and top seem to be reversed on Mac
local window_w, window_h = math.min(window_w, max_w), math.min(window_h, max_h)
window_w = window_w%3 > 0 and window_w - window_w%3 + 3 or window_w -- ensure that default window width is a multiple of 3 because there're 3 columns; +3 gives next multiple, without it gives previous multiple
local current_width = gfx.w
------ NEW END -------------------------
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
local header_x = 0 -- NEW
local vert_scroll_pos = header_height -- NEW
local horiz_scroll_pos = header_x -- NEW
local scroll_y = 0
local scroll_speed = 30
local max_scroll = 0
-- local is_scrolling = false -- OLD
-- the following two variables ensure that once mouse has latched onto the scroll track
-- the mouse cursor can move away from it while the left mouse button is held down
-- and scroll will continue to work
local is_vert_scrolling -- NEW
local is_horiz_scrolling -- NEW
-- local last_scroll_y = 0 -- OLD, not used anywhere in the original code
local last_wheel = 0
-- local click_count = 0 -- OLD, doesn't affect anything
local last_click_x, last_click_y, last_click_col = 0, 0, 0
local last_mouse_state = 0
local click_timer = 0 -- NOT USED IN THIS MOD
-- local project_state_change_count = 0 -- OLD, doesn't affect anything
local wnd_x, wnd_y, wnd_w, wnd_h, dock -- NEW
local colors = {
    background = {0.15, 0.16, 0.21, 1.0}, -- task box main color
    foreground = {0.67, 0.70, 0.75, 1.0}, -- task box text color
    comment = {0.39, 0.45, 0.64, 1.0}, -- NOT USED ANYWHERE
    selection = {0.27, 0.28, 0.35, 1.0}, -- NOT USED ANYWHERE
    accent = {0.2, 0.55, 1.0, 1.0}, -- NOT USED ANYWHERE
    column_bg = {0.16, 0.17, 0.22, 1.0}, -- NOT USED ANYWHERE
    column_header = {0.24, 0.28, 0.41, 1.0},
    task_bg = {0.21, 0.23, 0.28, 1.0}, -- NOT USED ANYWHERE
    task_border = {0.31, 0.33, 0.43, 1.0},
    task_hover = {0.24, 0.26, 0.31, 1.0}, -- NOT USED ANYWHERE
    todo = {0.54, 0.91, 0.99, 1.0}, -- 'Backlog' task left edge ribbon color
    inprogress = {0.74, 0.58, 0.98, 1.0}, -- 'To Do' task left edge ribbon color
    done = {0.31, 0.98, 0.48, 1.0}, -- 'Done' task left edge ribbon color
    delete = {1.0, 0.33, 0.33, 1.0}, -- X delete button color
   hover_delete = {1.0, 0.33, 0.63, 0.8} -- X delete button color on mouse hoveer over task box // NEW
}
local column_status_colors = {
    colors.todo,
    colors.inprogress,
    colors.done
}
--[[ OLD, no arbitrary multi-line support
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
]]
local function format_text_lines(text, max_width) -- MOD, supports multi-line task text with \n operator
    local lines = {}
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    local current_line = ""
    for _, word in ipairs(words) do
      local line_break = word:match[[\n]] -- must be literal to disambiguate from control character \n, OR word:find('\n', 1, plain)
      local line_break_prefix = #word > 2 and word:match('^'..[[\n]]) -- line break char is attached to a word at its beginning  // same explanation of the syntax and alternative
      word = word:gsub(line_break or '','')
        local test_line = current_line .. (current_line == "" and "" or " ") .. word
        local text_w = gfx.measurestr(test_line)
        if text_w > max_width or line_break then
        current_line = line_break and not line_break_prefix and test_line or current_line
            table.insert(lines, current_line)
            current_line = line_break and not line_break_prefix and '' or word
        else
            current_line = test_line
        end
    end
    if current_line ~= "" then -- add outstanding text left over after loop exit
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
 -- self.x = 0 -- OLD
   self.x = header_x < 0 and header_x or 0 -- MOD // respect horizontal scroll
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
function overdue_color(self, bg_col) -- NEW
local date, time = self.text:match('\t(.-)\t(.+)')
  if date then
  local day, month, year, hour, min = self.text:match('(%d+)/(%d+)/(%d+)\t(%d+):(%d+)')
  local time_stamp_Unix = os.time({year=tonumber(year),month=tonumber(month),
  day=tonumber(day),hour=tonumber(hour),min=tonumber(min)})
    if time_stamp_Unix < os.time() then -- task is overdue
      if bg_col then bg_col[1] = 0.5 end -- increase intensity of red
    return bg_col or {1, 0, 0, 1} -- reddish for background and red for the status ribbon
    end
  end
end
function Task:draw(gfx)
    if self.y + self.height < header_height then return end -- no drawing of invisible task boxes
    local column_offset = (self.column - 1) * column_w
    local x = self.x + column_offset + 10
    local y = self.y
    local radius = 6 -- NOT USED ANYWHERE
    local bg_color -- task box main color
    if self.column == 1 then
        bg_color = {0.21, 0.23, 0.29, 1.0}
    elseif self.column == 2 then
     -- bg_color = {0.22, 0.22, 0.29, 1.0} -- OLD
    --- MOD START -------------------------
    local bg_col = {0.22, 0.22, 0.29, 1.0}
    bg_color = overdue_color(self, bg_col) or bg_col
    ---- MOD END --------------------------
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
    gfx.set(table.unpack(bg_color)) -- task box fill color
    gfx.rect(x, visible_y, self.width, visible_height) -- task box
    local status_color -- task box left edge ribbon color
    if self.column == 1 then
        status_color = colors.todo
    elseif self.column == 2 then
     -- status_color = colors.inprogress -- OLD
      status_color = overdue_color(self) or colors.inprogress -- MOD
    else
        status_color = colors.done
    end
   -- task box left edge ribbon
    gfx.set(table.unpack(status_color))
    gfx.rect(x, visible_y, 4, visible_height)
   -- task box border
    gfx.set(table.unpack(colors.task_border))
--  gfx.rect(x, visible_y, self.width, visible_height, false) -- OLD
   gfx.rect(x, y, self.width, self.height, false) -- MOD, ensures that when task box goes behind the header the top edge of the box frame becomes invisible instead of having the frame follow the box visible height and remain within view, complemented by drawing headers after task boxes inside draw()
   -- task box delete X button
   local X_color = self.hover and colors.hover_delete or colors.delete -- MOD
 -- gfx.set(table.unpack(colors.delete)) -- OLD
   gfx.set(table.unpack(X_color)) -- MOD
    local x_size = 10
    local x_x = self.x + column_offset + self.width - x_size - 10
 -- local x_y = visible_y + 15 -- OLD, causes X button to lag behind the scroll when the box goes behind the header
   local x_y = y + 15 -- MOD, hard link the X button y coordinate to task box y coordinate, so that they hide behind the header in sync, complemented by drawing headers after task boxes inside draw()
    gfx.line(x_x, x_y, x_x + x_size, x_y + x_size)
    gfx.line(x_x + x_size, x_y, x_x, x_y + x_size)
    gfx.setfont(1)
    if self.done then -- 'Done' column tasks text
     -- gfx.set(table.unpack(colors.foreground)) -- OLD, moved to within the loop below
        local line_height = gfx.texth + 2
     -- local start_y = visible_y + 15 -- OLD, same issue as with the delete X button above
      local start_y = y + 15 -- MOD, same solution
        for i, line in ipairs(self.lines) do
      gfx.set(table.unpack(colors.foreground)) -- MOD, sets text color for each new line to override strikethrough line color set at the end of each loop cycle
            local text_x = self.x + column_offset + 20
            local text_y = start_y + (i-1) * line_height
            gfx.x = text_x
            gfx.y = text_y
            gfx.drawstr(line)
            gfx.set(table.unpack(colors.done)) -- strikethrough line color
            gfx.line(text_x, text_y + gfx.texth/2, text_x + gfx.measurestr(line), text_y + gfx.texth/2) -- strikethrough line
        end
    else -- 'Backlog' and 'To Do' columns tasks text
        gfx.set(table.unpack(colors.foreground))
        local line_height = gfx.texth + 2
     -- local start_y = visible_y + 15 -- OLD, same issue as with the delete X button and with Done tasks above
       local start_y = y + 15 -- MOD, same solution
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
function import_tasks(col) -- MOD of a function used in v1.0.0 of the script
local proj, proj_path = reaper.EnumProjects(-1)
local Win = reaper.GetOS():match('Win')
local env_var = Win and 'USERPROFILE' or 'HOME'
local path = #proj_path > 0 and proj_path:match('.+[\\/]') or os.getenv(env_var) -- fall back on Desktop path is no saved project
local sep = path:match('[\\/]')
path = path..(#proj_path > 0 and '' or path:match('[\\/]')..'Desktop')
local ret, file = reaper.GetUserFileNameForRead(path, 'Tasks file', '.txt')
  if not ret then return end -- aborted by the user
local append
local col_title = col and '"'..column_titles[col]..'"'
local tasks_exist = col and #columns[col] > 0 or not col and #columns[1]+#columns[2]+#columns[3] > 0
local comment = '\n\n(if there\'re no tasks to replace with,\nthe current tasks won\'t be deleted)'
local resp = tasks_exist and reaper.MB('YES — append to '..(col_title or 'current')..' tasks\n\n'
..'NO — replace '..(col_title or 'all')..' tasks'.. comment, 'Import Kanban tasks', 3) -- no dialogue with options if no tasks to replace because appending in this case doesn't make sense
  if resp == 2 then return -- aborted by user
  elseif resp == 6 then append = 1
  end
local t = {{}, {}, {}} -- using temporary table to avoid deletion of current tasks if no tasks get to be imported
  for line in io.lines(file) do
    local column, text = line:match("(%d):(.+)")
    column = column and column+0
    if column and text and (col and col == column or not col) then
      if column > 0 and column < 4 then
         table.insert(t[column], Task.new(text, column))
      end
    end
   end
  if col and #t == 0 or not col and #t[1]+#t[2]+#t[3] == 0 then
  reaper.MB('No tasks to import', 'Kanban', 0) return end

local longest_t = get_longest_column(columns)
local column_orig_len = col and #columns[col]
local longest_col_idx = longest_t == columns[col] and col
  local function get_last_y(t)
  return #t > 0 and t[#t].y+t[#t].height > header_height and t[1].y
  end
local Y_t = {get_last_y(columns[1]), get_last_y(columns[2]), get_last_y(columns[3])}

  if not append then -- replace
    for i=col or 1, col or 3 do
      if #t[i] > 0 then -- prevent replacing tasks with nothing, i.e. deleting them, if there's no relevant data to import into the column, applies to import tasks to all columns
      columns[i] = {table.unpack(t[i])}
      end
    end
  else -- append
    for i=col or 1, col or 3 do
      for k, task in ipairs(t[i]) do

      table.insert(columns[i], task)
      end
    end
  end

local scroll_pos
  if not col and not append then -- all columns are imported replacing current tasks    
    for i=1,3 do
      if #t[i] == 0 and Y_t[i] then -- nothing was imported into the column i so it remained unaffacted and its top task Y coordinate can be used as the scroll position reference for restoration provided its last task box wasn't scrolled beyond the header
      scroll_pos = Y_t[i]
      break end
    end
    if scroll_pos then
      for i=col or 1, col or 3 do
      restore_vert_scroll_position(columns[i], scroll_pos)
      end
    else -- scroll is reset when tasks for all columns are imported replacing the current ones without available scroll position reference
    update_task_positions()
    end
  else
  local t = (append or col and #columns[col] >= column_orig_len and Y_t[col]) and columns -- always restore if tasks are appended per column or for all columns; when specific column tasks are replaced only restore when the replaced column becomes longer after the replacament provided it wasn't originally scrolled beyond the header
  scroll_pos = append and longest_t and longest_t[1].y or col and #columns[col] >= column_orig_len and Y_t[col] or header_height

    if t then -- only restore scroll position when appending or when the replacement content is longer than the replaced, because if replacemwnt content is shorter than the replaced, restoration of the scroll position won't be possible
      for i=col or 1, col or 3 do
      restore_vert_scroll_position(columns[i], scroll_pos) -- only used with the alternative t expression above
      end
    else -- column tasks are replaced and after replacement it becomes shorter or becomes longer but originally was scrolled beyond the header
     update_task_positions()
    end
  end
restore_gfx_wnd_focus()
end
function export_tasks(col) -- MOD of a function used in v1.0.0 of the script
local proj, proj_path = reaper.EnumProjects(-1)
local Win = reaper.GetAppVersion():match('Win')
local env_var = Win and 'USERPROFILE' or 'HOME'
local path = #proj_path > 0 and proj_path:match('.+[\\/]') or os.getenv(env_var) -- fall back on Desktop path is no saved project
local sep = path:match('[\\/]')
local file = io.open(path..sep..(#proj_path > 0 and '' or 'Desktop'..sep)..'Kanban tasks.txt', "w")

  if not file then
    reaper.ShowMessageBox("Failed to open file for tasks export", "Error", 0)
    return
  end
  for col = col or 1, col or 3 do -- if col argument is false all columns are exported
    for _, task in ipairs(columns[col]) do
      file:write(tostring(col) .. ":" .. task.text .. "\n")
    end
  end
file:close()
end
--[[ OLD
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
]]
function check_project_changes() -- MOD
    local new_proj, new_path = reaper.EnumProjects(-1)

    -- Check if project changed
    if new_proj ~= current_project or new_path ~= current_project_path then
     if new_proj ~= current_project then -- tabs switch
     reaper.SetExtState(tostring(current_project), 'SCROLL_POSITION', vert_scroll_pos..';'..horiz_scroll_pos, false) -- persist false // MOD, store scroll position of the outgoing project
       current_project = new_proj
     end
     if new_path ~= current_project_path then -- new project has been loaded under the current tab
     init()
     current_project_path = new_path
     end
     load_tasks() -- Reload tasks from new project

    -- recall scroll position of the incoming project
    local scroll_pos = reaper.GetExtState(tostring(new_proj), 'SCROLL_POSITION')
    local vert_scroll_pos, horiz_scroll_pos = scroll_pos:match('([%-%d%.]+);([%-%d%.]+)')
      if vert_scroll_pos then
        for i=1,3 do
        restore_vert_scroll_position(columns[i], vert_scroll_pos+0)
        end
      end
      if gfx.dock(-1)&1 ~= 1 then -- recall horiz scroll pos unless docked
        if horiz_scroll_pos then
        update_x_coordinate(columns, horiz_scroll_pos+0)
        end
      end
      return true
    end
return false
end
function update_task_positions()
    local max_content_height = 0
    for col = 1, 3 do
        local current_y = header_height
        for _, task in ipairs(columns[col]) do
            task:calculate_height()
        --  task.x = 0 -- OLD
        task.x = header_x < 0 and header_x or 0 -- MOD // respect horizontal scroll
            task.y = current_y - scroll_y
            task.column = col
            task.done = (col == 3)
            current_y = current_y + task.height + 10 -- 10 is pad between task boxes
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
function restore_vert_scroll_position(t, column_h) -- NEW
local column_h = column_h or t[1] and t[1].y
  if column_h then
    for k, task in ipairs(t) do
    task.y = column_h
    column_h = column_h + task.height + 10 -- +10 is pad between task boxes; calculate at the end of the loop cycle for the next one to prevent adding task.height+10 before setting its y coordinate which would happen if the calculation were done at the beginning of the cycle
    end
  end
end
function get_column_at(x)
--  return math.min(3, math.max(1, math.floor(x / column_w) + 1)) -- OLD
   return math.min(3, math.max(1, math.floor((x - header_x) / column_w) + 1)) -- MOD // respect horizontal scroll
end
function draw() -- draw the contents of the main window
    gfx.set(table.unpack(colors.background)) -- window background color
    gfx.rect(0, 0, window_w, window_h, true) -- window background fill  
  --[-[--- MOD START -------------------------
  -- draw task boxes before headers so that
  -- their components such as close X button
   --  and text get hidden behind headers when
  -- the task box y cordinate becomes smaller
  -- than the header height
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
   --]]---- MOD END -------------------------
   -- header
   gfx.setfont(2)
    for i = 1, 3 do
    -- local x = (i - 1) * column_w -- OLD
      local x = header_x + (i - 1) * column_w -- MOD
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
        gfx.set(table.unpack(column_status_colors[i])) -- column ribbon color
        gfx.rect(x, 0, column_w, 4) -- column ribbon shape
        gfx.set(0.95, 0.95, 0.95, 1.0)
        local title_w, title_h = gfx.measurestr(column_titles[i])
        gfx.x = x + (column_w - title_w) / 2
        gfx.y = 15
        gfx.drawstr(column_titles[i])
    end
     ----- NEW START -------------------------
    -- clock
    gfx.setfont(3, 'Arial', 14)
    gfx.x = 10
    gfx.y = 5
    gfx.set(table.unpack(colors.foreground))
    gfx.drawstr(os.date('%a %d-%m-%y %I:%M:%S %p'))
    gfx.setfont(2) -- restore font for column title
    ------ NEW END -------------------------

--[[ OLD, scroll track drawing moved to the buttom of the function, so that it always overlays task boxes when the window is shrunk along the x axis
   local scrollbar_width = 10
   local scrollbar_x = window_w - scrollbar_width
   local scrollbar_height = window_h - header_height - 10
   local scrollbar_y = header_height + 5
   local scrollbar_thumb_height = math.max(30, scrollbar_height * (window_h / (max_scroll + window_h)))
    local scrollbar_thumb_y = scrollbar_y + (scroll_y / max_scroll) * (scrollbar_height - scrollbar_thumb_height)
   gfx.set(0.2, 0.2, 0.2, 0.5)
   gfx.set(1, 0.0, 0.0, 1) -------- TEMP
    gfx.rect(scrollbar_x, scrollbar_y, scrollbar_width, scrollbar_height) -- scrollbar track
    gfx.set(0.4, 0.4, 0.4, 0.8)
   gfx.set(0, 1, 1, 1) -------- TEMP
    gfx.rect(scrollbar_x, scrollbar_thumb_y, scrollbar_width, scrollbar_thumb_height) -- scrollbar thumb
 --]]
--[[ OLD, task boxes are drawn after the headers which makes their elements such as close X button and text displayed over the header when task box y coordinate becomes smaller than the header height, i.e. task box gets hidden, so moved to top
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
  --]]
    if drag_task then -- actualy true not exactly on drag but on a task box click, initialized inside handle_mouse_click()

    if gfx.mouse_y < header_height or gfx.mouse_y - y_delta < header_height then return end -- MOD // prevent dragging task box over the header thereby preventing some glitches // y_delta var is initialized in handle_mouse_click()
        local old_column = drag_task.column
        local old_x = drag_task.x
        drag_task.column = get_column_at(gfx.mouse_x)
     -- drag_task.x = 0 -- OLD
     -- drag_task.y = gfx.mouse_y - task_height / 2 -- OLD // the amount of task box animation when clicked depends on mouse position and on default box height and the difference from the original box y coordinate can be pretty significant which doesn't look good
      drag_task.x = header_x < 0 and header_x or 0 -- MOD // respect horizontal scroll
      drag_task.y = gfx.mouse_y - y_delta -- MOD // animate on mouse click
        drag_task.done = (drag_task.column == 3)
        drag_task.hover = true
        drag_task:draw(gfx)
        drag_task.column = old_column
        drag_task.x = old_x
   end
   --- MOD START -------------------------
   -- draw scroll track
   -- do away with scroll thumb, scroll is performed
   -- by swiping along the scroll track;
   -- placed after all task box drawing so that it always
   -- overlays task boxes when the window is shrunk along the x axis
   local scrollbar_width = 10
   local scrollbar_x = gfx.w - scrollbar_width
   local scrollbar_height = gfx.h
   local scrollbar_y = header_height
   gfx.set(0.4, 0.4, 0.4, 0.8)
    gfx.rect(scrollbar_x, scrollbar_y, scrollbar_width, scrollbar_height) -- vertical scrollbar track
    if gfx.w < window_w then
    gfx.rect(0, scrollbar_height-15, scrollbar_x, 15) -- horizontal scrollbar track -- NEW
    end
   ---- MOD END -------------------------
    gfx.update()
end
function get_clipboard_text()
    if reaper.APIExists("CF_GetClipboard") then
        local clipboard_text = reaper.CF_GetClipboard() or ""
    --  clipboard_text = clipboard_text:gsub(",", "~~COMMA~~") -- OLD
        return clipboard_text
    end
    return ""
end
--[[--------- OLD, UNUSED
function restore_commas(text)
    if text then
        return text:gsub("~~COMMA~~", ",")
    end
    return text
end
]]
function task_dialogue(col, default_text, want_new_task, err) ---- NEW
local default_text = want_new_task and not err and default_text:gsub('\t','') or default_text
local field_cnt = col == 1 and 1 or 3
local cur_year, cur_month, cur_day, cur_hour, cur_min = os.date('%Y'), os.date('%m'), os.date('%d'), os.date('%H'), os.date('%M')
local field_label = 'Task name:'
local field_labels = col == 1 and field_label or col > 1 and field_label..',Date (dd/mm/yyyy):,Time (hh:mm):'
or field_label..',Date:,Time:'
--[[ version with time stamp auto-fill
local field_cont = col == 1 and default_text -- in column BACKLOG load stored text if exists or from the clipboard when creating new task
or col > 1 and (want_new_task and not err and default_text..'\t'..cur_day..'/'..cur_month..'/'..cur_year..'\t'..cur_hour..':'..cur_min
or default_text) -- in columns TO DO and DONE only load current time stamp when creating a new task, otherwise load stored content
or ''
--]]
local field_cont = default_text

local col_type = col == 1 and 'Backlog' or col == 2 and 'To Do' or 'Done'
local title = col > 1 and '  [date and time are optional]' or ''
title = (want_new_task and 'New "' or '"')..col_type..'" Task'..title
local retval, task_text = reaper.GetUserInputs(title, field_cnt, field_labels..",extrawidth=400,separator=\t", field_cont)
  if not retval then return end
local task_txt, date, time = task_text:match('^(.-)\t') or task_text, task_text:match('\t(.*)\t'), task_text:match('\t.-\t(.*)')
  if #task_txt > 0 and col > 1 and want_new_task then -- only validate date and time when creating a new task under TO DO and DONE columns
  local err = #date:gsub(' ','') > 0 and not date:match('^%s*%d%d/%d%d/%d%d%d%d') and 'Invalid date format.'
  or #date:gsub(' ','') > 0 and #time:gsub(' ','') > 0 and not time:match('^%s*%d%d:%d%d') and 'Invalid time format.'
    if err then reaper.MB(err, 'Kanban', 0)
    return false, task_text -- will trigger dialogue reload outside of the function    
    elseif #date > 0 and col == 2 then -- error only applies to new tasks in TO DO column, tasks in DONE column can be created under any time stamp
    local day, month, year = date:match('^%s*(%d%d)/(%d%d)/(%d%d%d%d)')
    local hours, minutes = time:match('^%s*(%d%d):(%d%d)')
    hours, minutes = hours or '00', minutes or '00' -- if time isn't specified fall back on the very beginning of the day
    local deadline = '\n\nDeadline cannot be in the past.'
    local inv_mon, inv_day, inv_hr, inv_min = 'Invalid month number.', 'Invalid day.', 'Invalid hours value.', 'Invalid minutes value.'    
    local err = year+0 < cur_year+0 and 'Invalid year.'..deadline
    or (not (month+0 < 13 and month+0 > 0) and inv_mon or year+0 == cur_year+0 and month+0 < cur_month+0 and inv_mon..deadline)
    or (day+0 < 1 or day+0 > 30 and (month+0 < 8 and month+0%2 == 0 or month+0 > 7 and month+0%2 > 0) and inv_day
    or year+0 == cur_year+0 and month+0 == cur_month+0 and day+0 < cur_day+0 and inv_day..deadline)
      if date == os.date('%d/%m/%Y') then -- hours and minutes can only be invalid if deadline date is equal to current date
      err = (not (hours+0 > -1 and hours+0 < 25) and inv_hr or hours+0 < cur_hour+0 and inv_hr..deadline)
      or (not (minutes+0 > -1 and minutes+0 < 60) and inv_min
      or hours+0 == cur_hour+0 and (minutes+0 < cur_min+0 and inv_min..deadline 
      or minutes+0 == cur_min+0 and col == 2 and inv_min..'\n\nDeadline cannot be now.'))
      end
      if err then reaper.MB(err, 'Kanban', 0)
      return false, task_txt..'\t'..day..'/'..month..'/'..year..'\t'..hours..':'..minutes  -- will trigger dialogue reload outside of the function
      end
    end
  end

date = date and #date > 0 and date
time = date and time and (#time > 0 and time or '00:00')
return true, task_txt..(date and '\t'..date or '')..(time and '\t'..time or '') -- will allow the routine to proceed to add_new_task() inside handle_mouse_click() or to task update inside rename_task_dialog()
end
function add_new_task(column, text)
    if not text or text == "" then return end
   --[[ OLD
    text = restore_commas(text)
    text = text:gsub("|", ",")
  --]]
    local task = Task.new(text, column)
    table.insert(columns[column], task)
--  update_task_positions() -- OLD
   ----- MOD START -------------------------
   local longest_t = get_longest_column(columns)
   restore_vert_scroll_position(columns[column], longest_t and longest_t[1].y or header_height) -- ensuring that the very first task becomes immediately visible after being added because it's created with its y coordinate being 0, i.e. beyond the header; using longest column top task y coordinate as a reference but any populated column will do besides the one the new task has been added to because it may be the only task in this column and if content is already scrolled its y coordinate being 0 cannot be used as an accurate reference
   ------ MOD END -------------------------
    save_tasks()
end
function remove_task(task)
    for col = 1, 3 do
        for i, t in ipairs(columns[col]) do
            if t == task then
          local top_y = columns[col][1].y -- NEW // ensures column top y coordinate restoration, if the top task has been deleted
                table.remove(columns[col], i)
             -- update_task_positions() -- OLD
           restore_vert_scroll_position(columns[col], top_y) -- NEW
                save_tasks()
                return
            end
        end
    end
end
function update_time_stamp(task, to_column) -- NEW
  if to_column == 3 then
  -- when moved to Done time stamp with current time
  task.text = (task.text:match('^.-\t') or task.text..'\t')..os.date('%d/%m/%Y')..'\t'..os.date('%H:%M')
  elseif to_column == 1 and task.text:match('\t') then
  -- when moved to Backlog clear time stamp if any
  task.text = task.text:match('^(.-)\t')
  end
return task
end
--function move_task(task, to_column) -- OLD, move task to another column
function move_task(task, to_column, target_idx) -- MOD, move task to another column
local old_idx = 0
    for i, t in ipairs(columns[task.column]) do
        if t == task then
            table.remove(columns[task.column], i)
        old_idx = i
        break
        end
    end
   ----- MOD START -------------------------
   task = update_time_stamp(task, to_column)
   task:calculate_height() -- this originally is used inside update_task_positions() which has been excluded
   ------ MOD END -------------------------
    task.column = to_column
    task.done = (to_column == 3)
--[[ OLD
   table.insert(columns[to_column], task) -- inserts the moved task at the end of the target column
   update_task_positions()
 --]]
  ----- MOD START -------------------------
  table.insert(columns[to_column], target_idx, task) -- inserts the moved task at the mouse cursor in the new column 
  -- get the top y coordinate of a column
  -- other than to_column which may have been
  -- initially empty and if the content is scrolled
  -- its only task box top y coordinate may be well
  -- below header height
  local top_y
    for i=1,3 do
      if i ~= to_column and #columns[i] > 0 then
      top_y = columns[i][1].y
      break end
    end
  -- update
  top_y = (old_idx == 1 or not top_y) and header_height or top_y -- if top task box was moved or no top_y coordinate was retrieved in the above loop because there's only one populated column, use header height as base coordinate for scroll restoration because the top box y coordinate won't be reliable, otherwise use whatever the top y coordinate which was retrieved in the above loop
    for i=1,3 do
    restore_vert_scroll_position(columns[i], top_y)
    end
   ------ MOD END -------------------------
    save_tasks()
end
function rename_task_dialog(task, col)
    local use_clipboard = (gfx.mouse_cap & 4) == 4 -- Ctrl/Cmd(+right click)
    local default_text = task.text
    if use_clipboard and reaper.APIExists("CF_GetClipboard") then
        local clipboard_text = reaper.CF_GetClipboard()
        if clipboard_text and clipboard_text:gsub(' ','') ~= "" then
          -- default_text = clipboard_text:gsub(",", "~~COMMA~~") -- OLD
        default_text = clipboard_text:gsub("\n", "")..(default_text:match('\t.*') or '') -- MOD
        end
    else
    --  default_text = default_text:gsub(",", "~~COMMA~~") -- OLD
    end

--   local retval, new_text = reaper.GetUserInputs("Rename task", 1, "New name:,extrawidth=400", default_text) -- OLD
   local retval, new_text = task_dialogue(col, default_text, want_new_task) -- MOD // want_new_task nil, date and time aren't validated
    if retval then
   --[[ OLD
        new_text = restore_commas(new_text)
        new_text = new_text:gsub("|", ",")
        if new_text ~= "" then
    ]]
      if new_text:gsub(' ','') ~= "" then -- only update if name field is filled out
            task.text = new_text
            task:calculate_height()
            update_task_positions()
            save_tasks()
        end
    end
end
function monitor_window_properties() -- NEW
-- to store in extended state with atexit() when the script is terminated
local wnd_open = gfx.getchar() > -1 -- not really necessary in this script because when window is closed the script is aborted
dock = wnd_open and gfx.dock(-1) or dock or 0
  if dock&1 ~= 1 then -- only update window dimensions and coordinates when undocked, because docked window dimensions and coordinates don't need storing, the dimensions are stored in reaper.ini, this ensures that window original props are restored once undocked
  wnd_w, wnd_h = table.unpack((wnd_open or not wnd_w) and {gfx.w, gfx.h} or {wnd_w, wnd_h}) 
  wnd_x, wnd_y = table.unpack(wnd_open and {gfx.clienttoscreen(0,0)} or {wnd_x, wnd_y})
  end

current_project = wnd_open and reaper.EnumProjects(-1) or current_project -- also updated inside check_project_changes()
local a, b, c = columns[1], columns[2], columns[3]
vert_scroll_pos = a[1] and a[1].y or b[1] and b[1].y or c[1] and c[1].y or header_height
horiz_scroll_pos = header_x
end
function init()
----- MOD START -------------------------
local extra_h_px = 28+23+4 -- 28 is taskbar height on windows, 23 is height of the window top bar and 4 px is bottom edge width not accounted for in gfx window dimensions
local retval, window_data = reaper.GetProjExtState(current_project, ext_name, "Kanban window")
local x, y, w, h, dock, vert_scroll_pos, horiz_scroll_pos = window_data:match(('([%-%d%.]+);'):rep(6)..'([%-%d%.]+)')
x, y, w, h, dock, vert_scroll_pos, horiz_scroll_pos = x or 0, y or 0, w or window_w, h or window_h-extra_h_px, dock and dock or 0, vert_scroll_pos or header_height, horiz_scroll_pos or 0
------ MOD END --------------------------
  -- gfx.init("Kanban Board - Project Tasks", window_w, window_h) -- OLD
    gfx.init("Kanban Board - Project Tasks", w, h, dock+0, x-4, y-23) -- MOD // 4 is with of the window right edge, 23 is height of the window top bar not accounted for in gfx window dimensions
    gfx.setfont(1, "Arial", font_size)
    gfx.setfont(2, "Arial", font_size + 4, "b")
    gfx.clear = 0
 -- project_state_change_count = reaper.GetProjectStateChangeCount(current_project) -- OLD, doesn't affect anything    
   load_tasks()
   ----- MOD START -------------------------
   current_width = gfx.w -- ensures that horiz scroll position isn't reset with update_x_coordinate_at_window_width_change() when the window is scrolled all the way to the right edge, by preventing 'current_width < gfx.w' condition becoming true right after script launch
   wnd_x, wnd_y, wnd_w, wnd_h = x+0, y+0, w+0, h+0
    for i=1,3 do
    restore_vert_scroll_position(columns[i], vert_scroll_pos+0)
    end
   update_x_coordinate(columns, horiz_scroll_pos+0)
   ------ MOD END --------------------------
end
function debug_message(message)
    reaper.ShowConsoleMsg(tostring(message) .. "\n")
end
function get_task_index_at_position(column, y_pos) -- used to move task within column
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
function get_longest_column(columns) -- NEW
local Y, t = 0
  for i=1,3 do
    for k, task in ipairs(columns[i]) do
      if task.y > Y then Y, t = task.y, columns[i] end
    end
  end
return Y > 0 and t
end
function update_x_coordinate(columns, scroll_x) -- NEW
-- used to set/restore horiz scroll position
header_x = header_x + scroll_x
  for i=1,3 do
    for k, task in ipairs(columns[i]) do
    task.x = task.x + scroll_x
    end
  end
end
function tasks_are_sorted(t, field, dir) -- NEW
-- field is a string or integer, name of a field in the associative array
-- or field index in an indexed array
-- dir is integer, sorting direction to be evaluated
-- 1 - ascending, 2 descending
---------------------------------
-- collect values from the orig table into temp table t2
local t2 = {}
  for k, tab in ipairs(t) do -- here original t contains nested tables in all of which the required value is stored in the field 'value'
  t2[k] = tab[field]
  end
local t2_concat = table.concat(t2,',') -- convert into string before sorting
local asc, desc = dir == 1, dir == 2
-- if ascending the function isn't needed but leaving it for consistency
table.sort(t2, function(a,b) return asc and a < b or desc and a > b end) -- sort the temp table
return t2_concat == table.concat(t2,',') -- compare before and after sorting
end
function sort_table(t, start_idx, end_idx, field, descending) -- NEW
-- t is an INDEXED table;
-- start_idx, end_idx limit table range within which
-- values must be sorted;
-- field is a string, name of a field in an associative array
-- if the table t consists of nested associative arrays,
-- if field is invalid, indexed values in table t will be sorted, if any;
-- descending is boolean to sort in descending order;
-- the algo is probably terribly inefficient, but for relatively short tables is fine
local compare = descending and math.max or math.min
local start_idx = start_idx and start_idx > 0 and start_idx ~= #t and start_idx or 1
local end_idx = end_idx and end_idx <= #t and end_idx ~= 1 and end_idx or #t
  for i=start_idx, end_idx do -- advance by 1 and evaluate values from index i onwards
  local result = math.huge*(descending and -1 or 1)
    for ii=i,end_idx do
    local v = t[ii]
    local value = field and type(v) == 'table' and v[field] or not field and v
      if value then
      result = compare(value, result)
        if result == value then
        v = field and type(v) == 'table' and v or value -- if nested table move the entire table
        table.remove(t,ii)
        table.insert(t,i,v) -- move to the index, value at which is currently being evaluated
        end
      end
    end
  end
return t
end
function format_menu_item(condition, name) -- NEW
local i = 0
return (condition and '#' or '')..(name):gsub('.','%0 ')
end
function right_click_menu(columns, col, longest_col) -- NEW

-- evaluate sorting
local non_sortable = true
local t = columns[col]

  if col > 1 and longest_col then -- only applies to columns To Do and Done; when no tasks longest_col is false
  local Unix_time = os.time({year=3000, month=1, day=1}) -- tasks without time stamp will be assigned distant future time stamp, initially meant to make them end up at the bottom of the sorted list and to simplify table.sort operation because otherwise they would lack Unix_time field and the function would error out, but after realizing that table.sort is inherently unstable and this trick won't help to maintain the order of tasks without time stamp, the distant Unix time stamp will only aid in evaluating whether the table is sorted; max future year Lua seems to support is 3000, minimum is 1970, > 3001 and < 1970 produces error, 3001 sets off endless loop
  local timestamp_exists
    for k, task in ipairs(t) do
    local date = task.text:match('\t(.-)\t')
      if date then
      local day, month, year, hour, min = task.text:match('(%d+)/(%d+)/(%d+)\t(%d+):(%d+)')
      local Unix_time = os.time({year=(year+0),month=(month+0),day=(day+0),hour=(hour+0),min=(min+0)})
      timestamp_exists = 1
      task.Unix_time = Unix_time
      else
      task.Unix_time = Unix_time
      end
    end

  local sorted = tasks_are_sorted(t, 'Unix_time', 1) -- field 'Unix time', 1 descending order
  non_sortable = #t == 0 or sorted or not timestamp_exists

  end

-- evaluate scroll position
local scrolled_to_top, scrolled_to_bottom

  for i=1,3 do
    for k, task in ipairs(columns[i]) do
    if k == 1 and task.y == header_height then scrolled_to_top = 1 end -- do not exit here to account for a scenario of a single task in which case this will allow scrolled_to_bottom var to also become true
    if k == #columns[i] and task.y == header_height then scrolled_to_bottom = 1 break end
    end
  end

-- evaluate window size
local window_size_differs = gfx.w ~= window_w or gfx.h+23+4 ~= window_h-28 -- 28 is taskbar height on windows, 23 is height of the window top bar and 4 px is bottom edge width not accounted for in gfx window dimensions

local no_tasks = #columns[1]+#columns[2]+#columns[3] == 0
local no_column_tasks = #t == 0
local col_title = '"'..column_titles[col]:upper()..'"'

local menu = format_menu_item(non_sortable,'SORT CHRONOLOGICALLY') -- gray out the option when empty column or sorted or no tasks with time stamp, in the latter case this will prevent tasks with no time stamp from being swapped in an already sorted list which is still caused by table.sort() despite their having the same Unix time value
..'|'..format_menu_item(not window_size_differs or gfx.dock(-1)&1 == 1, 'RESTORE DEFAULT WINDOW SIZE') -- gray out if no difference or window is docked
..'|'..(longest_col and '' or '#')..('CLEAR TASKS (via dialogue)'):gsub('.','%0 ')
..'||>'..format_menu_item(no_tasks, 'EXPORT TASKS')..'|'..format_menu_item(no_column_tasks, col_title..' COLUMN') -- gray out if first argument is true, here and below
..'|<'..format_menu_item(false, ' ALL COLUMNS')
..'|>'..format_menu_item(false,'IMPORT TASKS')..'|'..format_menu_item(false, col_title..' COLUMN')
..'|<'..format_menu_item(false, ' ALL COLUMNS')
..'||'..format_menu_item(scrolled_to_top or not longest_col,'JUMP TO TOP')
..'|'..format_menu_item(scrolled_to_bottom or not longest_col,'JUMP TO BOTTOM')
..'||'..format_menu_item(gfx.w < window_w and header_x == 0 or gfx.w >= window_w,'JUMP TO LEFT EDGE')
..'|'..format_menu_item(gfx.w < window_w and gfx.w-header_x == window_w or gfx.w >= window_w,'JUMP TO RIGHT EDGE')

gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y -- ensures that the menu is opened at the mouse cursor
local output = gfx.showmenu(menu)

  if output == 0 or gfx.getchar() < 0 then return end -- gfx.getchar() ensures that if the window was closed while the menu was still open, all menu clicks are ignored, otherwise the content may still be affected, especially with the clear tasks option

  if output == 2 then -- restore default window size
  local x, y = gfx.clienttoscreen(0,0)
  x = (x-4+window_w+4 > max_w or x-4 < 0) and max_w-window_w-8-(max_w-window_w-8)/2 or x-4 -- 8 is width of right and left borders not accounted for in window_w, 4 is right border width which isn't accounted for in gfx client coordinates, centering the window if in original size it sticks beyond the screen border on the sides
  local extra_h_px = 28+23+4 -- 28 is taskbar height on windows, 23 is height of the window top bar and 4 px is bottom edge width not accounted for in gfx window dimensions
  gfx.init('', window_w, window_h-extra_h_px, 0, x, 0)
  update_x_coordinate(columns, 0-header_x)
  elseif output == 3 then -- delete tasks dialogue
  local resp = reaper.MB('YES — current column ('..column_titles[col]..') tasks\n\nNO — all tasks', 'Clear Kanban tasks', 3)
    if resp == 6 then -- YES
    columns[col] = {}
    elseif resp == 7 then -- NO
      for i=1,3 do
      columns[i] = {}
      end
    end
  elseif output > 3 and output < 6 then -- export
  export_tasks(output == 4 and col)
  elseif output > 5 and output < 8 then -- import
  import_tasks(output == 6 and col)
  elseif output > 7 and output < 10 then -- jump to top/bottom
  local column_h = output == 8 and header_height or longest_col[1].y+header_height-longest_col[#longest_col].y
    for i=1,3 do
    restore_vert_scroll_position(columns[i], column_h)
    end
  elseif output > 9 and output < 12 then -- jump left/right
  local scroll_x = output == 10 and header_x*-1 or gfx.w - (header_x + window_w)
  update_x_coordinate(columns, scroll_x)
  else -- sort
  local column_h = t[1].y -- base coordinate, accounting for negative y coordinate of the top task box, storing before re-ordering the table
  -- bring all time stamped tasks to the top of the table
  -- and calculate range to only sort within range of fields with the time stamp
  -- because stock table.sort() also sorts some fields with identical unix time, i.e. is unstable
  local range_end = 0
    for i=1, #t do
    local task = t[i]
      if task.text:match('\t(.-)\t') then
      table.remove(t,i)
      table.insert(t,1,task)
      range_end = range_end+1
      end
    end
  t = sort_table(t, 1, range_end, 'Unix_time')
  restore_vert_scroll_position(t, column_h)
  end
save_tasks()
end
function restore_gfx_wnd_focus() -- NEW
local wnd_x, wnd_y = gfx.clienttoscreen(0,0)
local w, h, dock = gfx.w, gfx.h, gfx.dock(-1)
  if dock&1 ~= 1 then -- only when undocked, when docked focus loss isn't a problem
  gfx.quit()
  gfx.init("", w, h, 0, wnd_x-4, wnd_y-23) -- 4 and 23 px are width of gfx window right/left/bottom frame and the top bar which aren't accounted for in gfx window coordinates // https://www.askjf.com/?q=5895s https://forum.cockos.com/showpost.php?p=2493416&postcount=40
  end
end
function handle_mouse_click()

    ----- MOD START -------------------------
    if gfx.mouse_x >= gfx.w-10 and gfx.mouse_x <= gfx.w and gfx.mouse_y >= header_height -- ignore when cursor is within the vertical scroll track
    or gfx.w < window_w and gfx.mouse_y >= gfx.h-15
    and gfx.mouse_y <= gfx.h and gfx.mouse_x < gfx.w-10 -- ignore mouse click when cursor is within the visible horizontal scroll track
    or gfx.mouse_y < header_height and gfx.mouse_cap & 1 == 1 -- ignore left mouse click on the header
    or is_horiz_scrolling or is_vert_scrolling -- set to true inside handle_scrolling() function // prevent targeting task boxes once scrolling has been registered
    then return end
    ------ MOD END -------------------------

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
           ----- MOD START -------------------------
           -- used in draw() to keep task box y coordinate
           -- at constant distance from the mouse during
           -- dragging while ensuring moderate animation
           -- of only 5 px in reponse to click;
           -- task box y coordinate must be calculated relative
           -- to mouse because it's dragged around
           drag_task.y = drag_task.y + 5
           y_delta = my - drag_task.y
           ------ MOD END -------------------------
            end
        end
    end
    if mouse_state == 0 and last_mouse_state == 1 and drag_task then
        local new_col = get_column_at(mx)
        if new_col ~= drag_task.column then -- move to another column
      --  move_task(drag_task, new_col) -- OLD
        ----- MOD START -------------------------
        -- store the task within the new table exactly
        -- where it was dropped
        local target_idx = get_task_index_at_position(new_col, my)
        move_task(drag_task, new_col, target_idx)
        ------ MOD END -------------------------
        else -- move within the column
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
          -- update_task_positions() -- OLD
          ----- MOD START -------------------------
          -- in this modified script update_task_positions()
          -- resets scroll position, while restore_vert_scroll_position()
          -- isn't suitable when the content isn't scrolled and
          -- the very first task box is clicked which makes it change
          -- its y coordinate to simulate animation, so restore_vert_scroll_position()
          -- function expecting a genuine y coordinate of the top task box
          -- gets the wrong value and scroll position restoration goes haywire
           local t = columns[new_col]
            if t[1].y >= header_height and t[1].y < header_height+t[1].height then
            update_task_positions()
            else
            local cur_top_task = columns[new_col][old_index]
            local top_y = old_index == 1 and cur_top_task.y - cur_top_task.height - 10 -- if top task is moved calculate its old y coordinate using new top task which replaced it, this accounts for possibility of scrolling while re-ordering tasks especially in 'Done' column possible by dragging the task while the mouse cursor is within the vertical scroll track; if the moved task is other than the top one, y coordinate of the top task in the column will be used inside the function
            restore_vert_scroll_position(t, top_y)
            end
          ------ MOD END -------------------------
          save_tasks()
            end
        end
        drag_task = nil
    end
   ----- NEW START -------------------------
   -- must be placed before next condition
   -- because if the content is scrolled up
   -- the mouse position will also match a task
   -- box at the top, triggering task renaming;
   -- menu won't load if no columns
   if right_mouse_state == 2 and col and gfx.mouse_y > 0 and gfx.mouse_y < header_height then
   right_click_menu(columns, col, get_longest_column(columns))
   return
   end
   ------ NEW END -------------------------
    if right_mouse_state == 2 and last_mouse_state & 2 == 0 and not drag_task then
        local clicked_task = nil
        for _, task in ipairs(columns[col]) do
            if task:contains(mx, my) then
                clicked_task = task
                break
            end
        end
        if clicked_task then
            rename_task_dialog(clicked_task, col)
        restore_gfx_wnd_focus() -- NEW // when dealing with GetUserInputs dialogue gfx window focus is lost and scroll targets main REAPER window
        elseif my > header_height then
            local default_text = get_clipboard_text()
      --[[ -- OLD
      local retval, task_text = reaper.GetUserInputs("New Task", 1, "Task name:,extrawidth=400", default_text)
        if retval and task_text ~= "" then
        add_new_task(col, task_text)
            end
        ]]
       ----- MOD START -------------------------
       local err
       ::RETRY::
       local retval, text = task_dialogue(col, default_text, 1, err) -- want_new_task true
         if not retval and text then default_text = text; err = 1; goto RETRY
         elseif retval and text:match('^%S+\t?') then -- only create task when name field is filled out, accounting for time stamp data
         add_new_task(col, text)
         restore_gfx_wnd_focus() -- when dealing with GetUserInputs dialogue gfx window focus is lost and scroll targets main REAPER window
         end
       ------ MOD END -------------------------
        end
    end
    last_mouse_state = gfx.mouse_cap
end
function handle_scrolling()
    local mx, my = gfx.mouse_x, gfx.mouse_y
    local mouse_state = gfx.mouse_cap & 1

   ----- NEW START -------------------------
   -- stores mouse last y coordinate before left click,
   -- ensures that the scroll isn't triggered immediately
   -- on scroll bar click because it causes the content
   -- to jump to a mew position without any scroll movement,
   -- and is used to determine scrollbar distance and direction
    if mouse_state ~= 1 then
    last_click_y = my
    last_click_x = mx
    end
   ------ NEW END -------------------------

    local wheel = gfx.mouse_wheel -- vertical mousewheel
   --[[ OLD
    if wheel ~= last_wheel then
        local delta = wheel - last_wheel
        scroll_y = math.max(0, math.min(max_scroll, scroll_y - delta * scroll_speed))
        update_task_positions()
        last_wheel = wheel
    end
  --]]
  ----- MOD START -------------------------
    if wheel ~= 0 then
    local a, b, c = columns[1], columns[2], columns[3]
    local top_task_y = a[1] and a[1].y or b[1] and b[1].y or c[1] and c[1].y
    a, b, c = a[1] and a[#a].y or 0, b[1] and b[#b].y or 0, c[1] and c[#c].y or 0
    local longest_col_y = math.max(math.max(a, b), c)
      if top_task_y then -- prevents error when no tasks
      local scroll_y = wheel/120 * scroll_speed
      -- prevent scroll going past the top task and last task in the longest column
      scroll_y = (wheel > 0 and top_task_y+scroll_y > header_height
      or wheel < 0 and longest_col_y+scroll_y < header_height) and 0 or scroll_y
      -- adjust scroll when it overshoots header height, by the difference 
      -- between header height and the new task y coordinate
      scroll_y = scroll_y == 0 and (wheel > 0 and header_height-top_task_y+scroll_y
      or wheel < 0 and header_height-longest_col_y+scroll_y) or scroll_y
        if scroll_y ~= 0 then
          for i=1,3 do
            for k, task in ipairs(columns[i]) do
            task.y = task.y+scroll_y
            end
          end
        end
      gfx.mouse_wheel = 0
      end
    end
  ------ MOD END -------------------------

--[[ OLD
    local scrollbar_width = 10
   local scrollbar_x = window_w - scrollbar_width
   local scrollbar_height = window_h - header_height - 10
   local scrollbar_y = header_height + 5
    if mx >= scrollbar_x and mx <= window_w and my >= scrollbar_y and my <= scrollbar_y + scrollbar_height then -- mouse is within the scrollbar
  ]]
  ----- MOD START -------------------------
  local scrollbar_width = 10
  local scrollbar_x = gfx.w - scrollbar_width
  local scrollbar_height = gfx.h - header_height
  -- not is_horiz_scrolling and not is_vert_scrolling conditions ensure that a type
  -- of scroll won't be activated when the mouse cursor crosses into its scroll track while
  -- another type of scroll is active
  -- is_vert_scrolling and is_horiz_scrolling vars allow continue scrolling 
  -- after the mouse cursor has been moved away from the scroll track
  local vert_scroll = not is_horiz_scrolling and (mx >= scrollbar_x and mx <= gfx.w and my >= header_height or is_vert_scrolling) -- mouse is within the vertical scroll track
  local horiz_scroll = not is_vert_scrolling and (my >= gfx.h-15 and my <= gfx.h and mx < scrollbar_x and gfx.w < window_w or is_horiz_scrolling) -- mouse is within the horizontal scroll track while window size is smaller than the default
  --  if vert_scroll or horiz_scroll then
  ------ MOD END -------------------------
    --[[ -- OLD
        if mouse_state == 1 and not is_scrolling
      and (vert_scroll and last_click_y and last_click_y ~= my -- MOD
      or horiz_scroll and last_click_x and last_click_x ~= mx) -- MOD
      then -- left mouse button is held down
            is_scrolling = true
      end
      ]]
      ----- MOD START -------------------------
      if mouse_state == 1 then
        if not is_vert_scrolling and vert_scroll and last_click_y and last_click_y ~= my
        then
        is_vert_scrolling = not is_horiz_scrolling
        elseif not is_horiz_scrolling and horiz_scroll and last_click_x and last_click_x ~= mx
        then
        is_horiz_scrolling = not is_vert_scrolling
        end
      end
      ------ MOD END -------------------------
  --  if is_scrolling then -- OLD
    if vert_scroll or horiz_scroll then -- MOD
        if mouse_state == 1 then
          --[[ OLD
         if my >= scrollbar_y and my <= scrollbar_y + scrollbar_height then -- mouse is within the scrollbar
        local ratio = (my - scrollbar_y) / scrollbar_height
            scroll_y = math.max(0, math.min(0, ratio * max_scroll))
       --]]
      ----- MOD START -------------------------
      -- does away with graphic scrollbar
      -- only relies on difference between mouse y coordinate
      -- within the space allocated to scrollbar
      -- so it can be clicked anywhere along the y axis
      local a, b, c = columns[1], columns[2], columns[3]
        if vert_scroll then
        --  if my >= header_height then -- mouse is within the scrollbar // REDUNDANT
        local top_task_y = a[1] and a[1].y or b[1] and b[1].y or c[1] and c[1].y
        a, b, c = a[1] and a[#a].y or 0, b[1] and b[#b].y or 0, c[1] and c[#c].y or 0
        local longest_col_y = math.max(math.max(a, b), c)
          if top_task_y then -- prevents error when no tasks // OR 'not top_task_y then return end'
          local scroll_y = last_click_y - my
          -- adjust scroll when it overshoots header height, by the difference
          -- between header height and the new task y coordinate
          -- prevents overshoot and ensures that the scroll is full, without leaving it
          -- a couple of pixels short of the destination if aborted earlier to prevent overshoot like VERSION 1
            if scroll_y > 0 and top_task_y == header_height
            or scroll_y < 0 and longest_col_y == header_height then return end
          scroll_y = scroll_y > 0 and top_task_y+scroll_y > header_height and header_height - top_task_y
          or scroll_y < 0 and longest_col_y+scroll_y < header_height and header_height - longest_col_y
          or scroll_y
            if scroll_y ~= 0 then
              for i=1,3 do
                for k, task in ipairs(columns[i]) do
                task.y = task.y+scroll_y
                end
              end
             end
          last_click_y = my -- ensures that scrolling doesn't continue after initial mouse movement while the mouse state remains 1 
          end
        elseif horiz_scroll then
        local scroll_x = last_click_x - mx
        -- adjust scroll when it overshoots window left or right edge, by the difference
        -- between edge coordinate and the new task x coordinate
        -- prevents overshoot and ensures that the scroll is full, without leaving it
        -- a couple of pixels short of the destination if aborted earlier to prevent overshoot like VERSION 1
          if scroll_x < 0 and gfx.w - header_x == window_w
          or scroll_x > 0 and header_x == 0 then return end
        scroll_x = scroll_x < 0 and header_x + window_w < gfx.w
        and gfx.w - (header_x + window_w)
        or scroll_x > 0 and header_x + scroll_x > 0 and header_x*-1 or scroll_x
          if scroll_x ~= 0 then
          update_x_coordinate(columns, scroll_x)
          end
        last_click_x = mx -- ensures that scrolling doesn't continue after initial mouse movement while the mouse state remains 1
         ------ MOD END -------------------------
        end
        else
         -- is_scrolling = false -- OLD
        is_vert_scrolling, is_horiz_scrolling = nil
        end
    end
end
function update_x_coordinate_at_window_width_change() -- NEW
-- when width of the window shrunk along the x axis is increased
-- whether docked or not
  if header_x < 0 and gfx.w < window_w and current_width < gfx.w then
    if header_x*-1 + gfx.w >= window_w -- this condition ensures that the content scroll position is only adjusted when the window right edge reaches header's right edge (if not already aligned) thereby attaching the right edge of the content to window's right edge, this is purely a design choice, if the conditon is disabled the left edge of the content gets to be attached to the window right edge and the scroll position gets adjusted immediately with window width increase
    then
    local scroll_x = gfx.w - current_width
    scroll_x = header_x + scroll_x <= 0 and scroll_x or header_x*-1 -- preventing overshoot
    update_x_coordinate(columns, scroll_x)
    end
  end
current_width = gfx.w
end
function prevent_window_excessive_expansion() -- NEW
-- prevent window resize beyond the max size
local wnd_x, wnd_y = gfx.clienttoscreen(0,0)
  if gfx.dock(-1)&1 ~= 1 and (gfx.w > window_w or gfx.h > window_h) then -- only when undocked
  gfx.init("", window_w, window_h, 0, wnd_x-4, wnd_y-23) -- 4 and 23 px are width of gfx window right/left/bottom frame and the top bar which aren't accounted for in gfx window coordinates // https://www.askjf.com/?q=5895s https://forum.cockos.com/showpost.php?p=2493416&postcount=40
  end
end
function main()

local char = gfx.getchar() -- MOD

    -- Check if project changed
  --[[ OLD
    if check_project_changes() then
        -- Project changed, tasks were reloaded
        draw()
    -- local char = gfx.getchar() -- OLD
   -- if char == -1 then -- OLD
     if char == 27 or char == -1 then -- MOD
            gfx.quit()
            return
        end
        if char ~= 27 and char >= 0 then -- not Esc and accessible to keyboard input, keep running            
        reaper.defer(main)
        end
        return
   end
  --]]

   check_project_changes() -- MOD
   prevent_window_excessive_expansion() -- NEW
   monitor_window_properties() -- NEW
    handle_scrolling()
    handle_mouse_click()
   update_x_coordinate_at_window_width_change() -- NEW
 --[[ OLD, doesn't affect anything
    if reaper.time_precise() - click_timer > 0.5 then
        click_count = 0
        click_timer = reaper.time_precise()
    end
  ]]
    draw()
 --  local char = gfx.getchar() -- OLD
 --  if char == -1 then -- OLD
   if char == 27 or char == -1 then -- MOD
        gfx.quit()
        return
    end
    if char ~= 27 and char >= 0 then -- not Esc and accessible to keyboard input, keep running
        reaper.defer(main)
    end
end
init()
main()


reaper.atexit(function() if reaper.ValidatePtr(current_project, 'ReaProject*') then reaper.SetProjExtState(current_project, ext_name, "Kanban window", wnd_x..';'..wnd_y..';'..wnd_w..';'..wnd_h..';'..dock..';'..vert_scroll_pos..';'..horiz_scroll_pos) end end) -- NEW // ValidatePtr() ensures that there's no error when REAPER is closed while the script is running because othwerwise current_project var will become invalid and will trigger an error


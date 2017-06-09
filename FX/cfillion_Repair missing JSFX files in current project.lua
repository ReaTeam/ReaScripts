-- @description Repair missing JSFX files in the current project
-- @author cfillion
-- @version 1.0
-- @link https://cfillion.ca
-- @donation https://www.paypal.me/cfillion/10
-- @about
--   # Repair missing JSFX files in the current project
--
--   This script scans the current project file for broken JSFX references
--   and prompts for the new location of each unique missing JSFX found.
--
--   A fixed copy of the project file is created (OriginalName-jsfix.RPP).
--
--   This script supports JSFX located either in the resource folder or
--   in the project directory.

local global_dir = reaper.GetResourcePath() .. '/Effects/'
local title = ({reaper.get_action_context()})[2]:match('([^/\\_]+).lua$')
local bucket = {}

-- no undo point for this script
reaper.defer(function() end)

function file_exists(fn)
  local file = io.open(fn, 'rb')

  if file then
    io.close(file)
    return true
  else
    return false
  end
end

function saw(jsfx)
  for i,entry in ipairs(bucket) do
    if jsfx == entry.name then
      return true
    end
  end

  return false
end

-- http://stackoverflow.com/a/34953646
function escape(pattern)
  return pattern:gsub("([^%w])", "%%%1")
end

if reaper.IsProjectDirty(0) ~= 0 then
  local btn = reaper.ShowMessageBox([[Project is modified. Do you want to save changes before repairing missing JSFX files?
Unsaved changes will not be included in the fixed copy.]], title, 3)

  if btn == 6 then
    reaper.Main_SaveProject()
  elseif btn == 2 then
    return
  end
end

local _, project_fn = reaper.EnumProjects(-1, '', 0)
local project_dir = project_fn:match('^(.-)[^/\\]+$') .. 'Effects/'

local project_io, error = io.open(project_fn, 'rb')
if not project_io then
  reaper.ShowMessageBox(
    string.format('Could not open project file "%s" (%s).',
    project_fn, error), title, 0)
  return
end
  
local chunk, modified = project_io:read('*all'), false
project_io:close()

function scan(pattern, start, stop)
  local from, to

  while true do
    from, to = chunk:find('<JS ' .. pattern, (from or 0) + 1)
    if not from then break end

    local token = chunk:sub(from, to):sub(5)
    local jsfx = token:sub(start, stop)
    local file, dir

    if jsfx:sub(1, 10) == "<Project>/" then
      dir = project_dir
      file = jsfx:sub(11)
    else
      dir = global_dir
      file = jsfx
    end

    if not saw(jsfx) and not file_exists(dir .. file) then
      table.insert(bucket, {name=jsfx, path=dir, token=token})
    end
  end
end

scan('"[^\n]-"', 2, -2)
scan('[^"\x20]+', 1, -1)

if #bucket == 0 then
  reaper.ShowMessageBox('No missing JSFX were found. Nothing to do!', title, 0)
  return
end

for i,old in ipairs(bucket) do
  local title = string.format('Looking for "%s"', old.name)
  local ok, new = reaper.GetUserFileNameForRead(old.path, title, '*.jsfx')

  if ok then
    new = new:sub(old.path:len() + 1)
    if old.path == project_dir then
      new = '<Project>/' .. new
    end

    old_pt = string.format('<JS %s', old.token)
    new_pt = string.format('<JS "%s"', new)

    chunk = chunk:gsub(escape(old_pt), new_pt)
    modified = true
  end
end

if not modified then
  reaper.ShowMessageBox('Repair process aborted by user request.', title, 0)
  return
end

new_fn = project_fn:gsub('%.(%w+)$', '-jsfix.%1')
local new_io, error = io.open(new_fn, 'wb')
if not new_io then
  reaper.ShowMessageBox(
    string.format('Could not write project file "%s" (%s).',
    new_fn, error), title, 0)
  return
end
new_io:write(chunk)
new_io:close()

reaper.Main_openProject(new_fn)

-- @noindex
-- @author Ben Talagan Babut
-- @license MIT
-- @about This is a part of Mouse cursor library

-- This action is technically not made for end users, it's purpose is to regenerate
-- the list of corresponding pairs cursor names <> ids so that they can be integrated to
-- the library

package.path    = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
package.path    = package.path .. ";" .. (reaper.GetResourcePath() .. "/Scripts/ReaTeam Scripts/Development/talagan_Mouse cursor library") .. '/?.lua'

local cursor_lookup = require "mouse_cursor_library/spec/spec"
local cursor_names  = {}

for cursor_name, _ in pairs(cursor_lookup) do
  cursor_names[#cursor_names+1] = cursor_name
end

table.sort(cursor_names)

local RANGE_START   = - 20000
local RANGE_END     = 50000

local function setCursorByNameAndTest(cursor_name)
  gfx.setcursor(nil, cursor_name)
  gfx.update()

  local current_cursor = reaper.JS_Mouse_GetCursor()

  for id = RANGE_START, RANGE_END, 1 do
    local cursor = reaper.JS_Mouse_LoadCursor(id)
    if cursor == current_cursor then
      reaper.ShowConsoleMsg(cursor_name .. "=" .. id .. ",\n")
      return
    end
  end

  reaper.ShowConsoleMsg("*** Failed to find an ID for " .. cursor_name .. "\n")
end

gfx.init("Cursor bruteforcer", 100, 100)

local started = false
local function loop()
  if started then
    for _, cursor_name in ipairs(cursor_names) do
      setCursorByNameAndTest(cursor_name)
    end
    started = false
    reaper.ShowConsoleMsg("Done\n")
    gfx.quit()
  end
  if gfx.mouse_cap == 1 then
    started = true
  end
  reaper.defer(loop)
end

reaper.ShowConsoleMsg("Click in the GFX window to start the cursor brutforce.\n")
reaper.defer(loop)

-- @noindex
-- @author Ben Talagan Babut
-- @license MIT
-- @about This is a part of Mouse cursor library

local cursor_lookup = require "mouse_cursor_library/spec/spec"

local function loadMouseCursorByName(cursor_name, do_not_try_to_load_custom_cursors)
    local id = cursor_lookup[cursor_name]
    if not id then
        error("Trying to fetch an unexisting cursor '" .. cursor_name "' !")
    end

    if not do_not_try_to_load_custom_cursors then
      local cursor = reaper.JS_Mouse_LoadCursorFromFile(reaper.GetResourcePath() .. "/Cursors/" .. cursor_name .. ".cur")
      if cursor then return cursor end
    end

    return reaper.JS_Mouse_LoadCursor(id)
end

return {
  loadMouseCursorByName = loadMouseCursorByName
}

-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local LaunchContext = {}
LaunchContext.__index = LaunchContext

function LaunchContext:new()
  local instance = {}
  setmetatable(instance, self)
  instance:_initialize()
  return instance
end

local function stringToBytes(str)
    local bytes = {}
    for i = 1, #str do
        bytes[i] = string.byte(str, i)
    end
    return bytes
end

local function bytesToString(bytes)
    return string.char(table.unpack(bytes))
end

local function JS_VKeys_GetStateWithoutModifiers(cutoff)
    local bs = stringToBytes(reaper.JS_VKeys_GetState(cutoff))
    bs[16] = 0
    bs[17] = 0
    bs[18] = 0
    bs[91] = 0
    return bytesToString(bs)
end

function LaunchContext:_initialize()
    local is_new_value,filename,section,cmd,mode,resolution,val ,ctxstr = reaper.get_action_context()
    self.focused_hwnd                       = reaper.JS_Window_GetFocus()

    self.launch_time                        = reaper.time_precise()
    self.shortcut_check_time                = self.launch_time - 0.1

    -- JS_VKeys_GetState is not reliable for modifiers, we split
    -- What's down at startup into two : modifiers and the rest
    self.calling_shortcut                   = JS_VKeys_GetStateWithoutModifiers(self.shortcut_check_time)
    self.calling_modifiers                  = reaper.JS_Mouse_GetState(4|8|16|32)

    self.context_string                     = ctxstr

    self.key_down_count = 0
    for i=1, 255 do
        if self.calling_shortcut:byte(i) ~= 0 then
            self.key_down_count = self.key_down_count + 1
        end
    end

    -- Following technique is not reliable if the MIDI Editor has focus
    -- self.is_launched_by_keyboard_shortcut   = ctxstr:find("key:")

    self.is_launched_by_keyboard_shortcut = (self.key_down_count > 0)
end

function LaunchContext:isLaunchedByKeyboardShortcut()
    return self.is_launched_by_keyboard_shortcut
end

function LaunchContext:isShortcutStillPressed()
    -- Compare modifiers / Compare the rest
    local current_keymap    = JS_VKeys_GetStateWithoutModifiers(self.shortcut_check_time)
    local current_modifiers = reaper.JS_Mouse_GetState(4|8|16|32)

    return (current_keymap == self.calling_shortcut) and (current_modifiers == self.calling_modifiers)
end

return LaunchContext

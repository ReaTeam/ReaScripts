-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local lastKnownFocus = {};

local function IsActiveMidiEditorFocused()
  local me  = reaper.MIDIEditor_GetActive()
  local f   = reaper.JS_Window_GetFocus();
  while f do
    if f == me then
      return true
    end
    f = reaper.JS_Window_GetParent(f);
  end
  return false
end

local function IsArrangeViewFocused()
  return (reaper.GetCursorContext() >= 0);
end


local function TrackFocus()
  if IsActiveMidiEditorFocused() then
    lastKnownFocus = { element = 'MIDIEditor' }
  elseif IsArrangeViewFocused() then
    lastKnownFocus = { element = 'ArrangeView', context = reaper.GetCursorContext() }
  else
    -- Simply ignore, we don't want to give back focus to this
  end
end

local function RestoreFocus()

  local hwnd = reaper.GetMainHwnd();
  reaper.JS_Window_SetFocus(hwnd);

  if lastKnownFocus.element == 'MIDIEditor' then
    reaper.JS_Window_SetFocus(reaper.MIDIEditor_GetActive());
  elseif lastKnownFocus.element == 'ArrangeView' then
    reaper.SetCursorContext(lastKnownFocus.context)
  else
    -- We don't know how to restore focus in a better way
  end
end

local function LastKnownFocus()
  return lastKnownFocus
end

return {
  IsActiveMidiEditorFocused = IsActiveMidiEditorFocused,
  IsArrangeViewFocused      = IsArrangeViewFocused,
  TrackFocus                = TrackFocus,
  RestoreFocus              = RestoreFocus,
  LastKnownFocus            = LastKnownFocus
}

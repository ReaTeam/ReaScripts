-- @description Restore foreground window
-- @author Edgemeal
-- @version 1.0
-- @about
--   Call this script from a keyboard shortcut.
--   Mainly useful for floating FX and similar windows.
--   Companion script: Maximize foreground window.

if not reaper.APIExists("JS_WindowMessage_Post") then
  reaper.MB("js_ReaScriptAPI extension is required for this script.", "Missing API", 0)
else
  -- Get foreground window, if child of reaper then maximize it.
  local hwnd = reaper.JS_Window_GetForeground()
  if reaper.JS_Window_GetParent(hwnd) == reaper.GetMainHwnd() then 
    reaper.JS_WindowMessage_Post(hwnd, "WM_SYSCOMMAND", 0xF120, 0, 0, 0) 
  end
end

reaper.defer(function () end)
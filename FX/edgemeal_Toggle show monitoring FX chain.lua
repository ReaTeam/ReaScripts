-- @description Toggle show monitoring FX chain
-- @author Edgemeal
-- @version 1.02
-- @changelog
--   Fix for MacOS - Now closes window.
--   Show monitor if docked but not the selected tab.
--   Additional checking to identify target window.

function FindWindow(window_titles, child_id, child_must_visible)
  local arr = reaper.new_array({}, 128)
  for i = 1, #window_titles do
    local title = reaper.JS_Localize(window_titles[i], 'common')
    reaper.JS_Window_ArrayFind(title, true, arr)
    local handles = arr.table()
    for j = 1, #handles do
      local hwnd = reaper.JS_Window_HandleFromAddress(handles[j]) -- window handle
      local child_hwnd =  reaper.JS_Window_FindChildByID(hwnd, child_id) -- child handle
      if child_hwnd then -- child control found
        if child_must_visible and not reaper.JS_Window_IsVisible(child_hwnd) then -- child must be visible
          return nil
        else
          return hwnd
        end
      end
    end
  end
end

function Main()
  local t = {'FX: Monitoring','FX: Monitoring [BYPASSED]'} -- titlebar text(s) to find
  local hwnd = FindWindow(t, 1076, true) -- 1076 = child id to find, true = child must be visible, i.e., docked but tab not selected.
  if not hwnd then
    reaper.Main_OnCommand(41882, 0) -- View: Show monitoring FX chain
  else -- close fx monitor window
    reaper.JS_Window_Destroy(hwnd) -- Tested Win7 & MacOS 10.12.
  end
end

if not reaper.APIExists("JS_Window_Find") then
  reaper.MB("js_ReaScriptAPI extension is required for this script.", "Missing API", 0)
else
  Main()
end

reaper.defer(function () end)

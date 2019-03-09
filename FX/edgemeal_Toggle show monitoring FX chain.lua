-- @description Toggle show monitoring FX chain
-- @author Edgemeal
-- @version 1.0

function Main()
  local title = reaper.JS_Localize('FX: Monitoring', 'common')
  local hwnd = reaper.JS_Window_Find(title, true)
  if not hwnd then
    title = reaper.JS_Localize('FX: Monitoring [BYPASSED]', 'common')
    hwnd = reaper.JS_Window_Find(title, true)
  end
  if not hwnd then -- show fx monitoring
    reaper.Main_OnCommand(41882, 0) -- View: Show monitoring FX chain 
  else -- close fx monitor window
    reaper.JS_WindowMessage_Post(hwnd, "WM_CLOSE", 0,0,0,0)
  end
end

if not reaper.APIExists("JS_Window_Find") then
  reaper.MB("js_ReaScriptAPI extension is required for this script.", "Missing API", 0)
else
  Main()
end

reaper.defer(function () end)
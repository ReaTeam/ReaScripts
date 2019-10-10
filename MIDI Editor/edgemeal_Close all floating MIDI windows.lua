-- @description Close all floating MIDI windows
-- @author Edgemeal
-- @version 1.0
-- @provides [main=main] .

function Main()
  local ret, list = reaper.JS_MIDIEditor_ListAll() -- get list of midi editors
  if ret < 1 then return end -- no MEs found or error
  local rea_hwnd = reaper.GetMainHwnd() -- reaper hwnd
  for adr in list:gmatch("[^,]+") do -- loop thru list
    local hwnd = reaper.JS_Window_HandleFromAddress(adr) -- convert address to handle
    if reaper.JS_Window_GetParent(hwnd) == rea_hwnd then -- midi window is floating (not docked).
      reaper.JS_Window_Destroy(hwnd) -- close floating midi window.
    end
  end
end

if not reaper.APIExists("JS_Localize") then
  reaper.MB("js_ReaScriptAPI extension is required for this script.", "Missing API", 0)
else
  Main()
end
reaper.defer(function () end)


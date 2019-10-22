-- @description Toggle Snap Grid Settings
-- @author Edgemeal
-- @version 1.0
-- @donation Donate via PayPal https://www.paypal.me/Edgemeal

function Main()
  local found = false
  local arr = reaper.new_array({}, 1024)
  local title = reaper.JS_Localize("Snap/Grid Settings", "common")
  reaper.JS_Window_ArrayFind(title, true, arr)
  local adr = arr.table()
  for j = 1, #adr do
    local hwnd = reaper.JS_Window_HandleFromAddress(adr[j])
    if reaper.JS_Window_FindChildByID(hwnd, 1182) then -- verify window, must also have control ID#.
      reaper.JS_Window_Destroy(hwnd) -- close window
      found = true
      break
    end
  end
  if not found then reaper.Main_OnCommand(40071, 0) end -- Options: Show snap/grid settings
end

if not reaper.APIExists('JS_Localize') then
  reaper.MB("js_ReaScriptAPI extension is required for this script.", "Missing API", 0)
else
  Main()
end
reaper.defer(function () end)

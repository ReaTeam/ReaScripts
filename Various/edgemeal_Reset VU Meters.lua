-- @description Reset VU Meters
-- @author Edgemeal
-- @version 1.21
-- @provides [windows] .
-- @screenshot Example https://stash.reaper.fm/34070/Reset%20VU%20Meters.gif
-- @about For Windows only!

function Main()
  reaper.Main_OnCommand(40527, 0) -- View: Clear all peak indicators
   
  local adrs = {}
   
  function Get_hWnds(title)
    local hwnds = reaper.new_array({}, 100)
    reaper.JS_Window_ArrayFind(title, false, hwnds)
    for k,v in pairs(hwnds.table()) do table.insert(adrs, v) end
  end
   
  -- get main windows,
  Get_hWnds("FX: ")
  Get_hWnds("VST: ")
  Get_hWnds("JS: ")
  Get_hWnds(" - Track ")
  Get_hWnds(" - Item ")
      
  -- loop thru main windows, get childs,
  for i = 1, #adrs do
    local arr = reaper.new_array({}, 255)
    reaper.JS_Window_ArrayAllChild(reaper.JS_Window_HandleFromAddress(adrs[i]), arr)
    local childs = arr.table()
    -- loop thru childs, find and reset vu meters
    for j = 1, #childs do
      childs[j] = reaper.JS_Window_HandleFromAddress(childs[j])
      if reaper.JS_Window_GetClassName(childs[j], "", 13) == "REAPERvertvu" then
        reaper.JS_WindowMessage_Post(childs[j], "WM_LBUTTONDOWN", 1, 0, 0, 0)
        reaper.JS_WindowMessage_Post(childs[j], "WM_LBUTTONUP", 0, 0, 0, 0)
      end
    end
  end
end

if not reaper.APIExists("JS_Window_ArrayFind") then
  reaper.MB("js_ReaScriptAPI extension is required for this script.", "Missing API", 0)
else
  Main()
end

reaper.defer(function () end)
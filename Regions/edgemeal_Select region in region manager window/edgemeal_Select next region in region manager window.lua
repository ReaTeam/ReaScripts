-- @noindex

function GetRegions(lv, cnt)
  local t = {}
  for i = 0, cnt-1 do
    if reaper.JS_ListView_GetItemText(lv, i, 1):match("R%d") then
      t[#t+1]= i
    end
  end
  return t
end
function Main()
  -- Open region/marker manager window if not found,
  local title = reaper.JS_Localize('Region/Marker Manager', 'common')
  local manager = reaper.JS_Window_Find(title, true)
  if not manager then
    reaper.Main_OnCommand(40326, 0) -- View: Show region/marker manager window
    manager = reaper.JS_Window_Find(title, true)
  end
  if manager then
    reaper.DockWindowActivate(manager)      -- OPTIONAL: Select/show manager if docked
    reaper.JS_Window_SetForeground(manager) -- OPTIONAL: Set focus on Manager window
    local lv = reaper.JS_Window_FindChildByID(manager, 1071)
    local item_cnt = reaper.JS_ListView_GetItemCount(lv)
    local region_indexes = GetRegions(lv, item_cnt)
    local sel_region = region_indexes[1]
    if sel_region then
      for i = 1, #region_indexes do -- get current selection & increment
        local sel = reaper.JS_ListView_GetItemState(lv, region_indexes[i])
        if sel > 1 then
          sel_region = region_indexes[i+1]
          if sel_region == nil then sel_region = region_indexes[1] end
          break
        end
      end
      reaper.JS_ListView_SetItemState(lv, -1, 0x0, 0x2)         -- unselect all items
      reaper.JS_ListView_SetItemState(lv, sel_region, 0xF, 0x3) -- select item @ index
      reaper.JS_ListView_EnsureVisible(lv, sel_region, false) -- OPTIONAL: scroll item into view
      reaper.JS_Window_SetFocus(lv)                           -- OPTIONAL: set input focus on ListView
    end
  end
end
if not reaper.APIExists('JS_Localize') then
  reaper.MB('js_ReaScriptAPI extension is required for this script.', 'Extension Not Found', 0)
else
  reaper.defer(Main)
end

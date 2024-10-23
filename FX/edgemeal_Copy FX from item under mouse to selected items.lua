-- @description Copy FX from item under mouse to selected items
-- @author Edgemeal
-- @version 1.01
-- @changelog
--   Select source FX by name from menu (if more then one).
--   Special Thanks to amagalma, https://forum.cockos.com/showthread.php?t=239556
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=239565
-- @donation Donate https://www.paypal.me/Edgemeal
-- @about See forum link.

function Main()
  -- get item/active take under mouse
  local src_item = reaper.BR_ItemAtMouseCursor()
  if src_item == nil then return end
  local src_take = reaper.GetActiveTake(src_item)
  if src_take == nil then return end
  local cnt = reaper.TakeFX_GetCount(src_take)
  if cnt == 0 then return end -- abort if no source FX
  -- get source fx index
  local src_fx = 0
  if cnt > 1 then -- more then one FX, let user select FX from menu
    local x, y = reaper.GetMousePosition()
    local FXs = {}  -- source fx names
    for fx = 0, cnt-1 do
      retval, name = reaper.TakeFX_GetFXName(src_take, fx, "")
      FXs[fx+1] = {name = name}
    end
    local menu = "#Copy source FX:||"
    for fx = 1, #FXs do
      local space = "                "
      space = space:sub( tostring(fx):len()*2 )
      menu = menu .. (FXs[fx].act and "!" or "") ..fx .. space .. (FXs[fx].name == "" and "(unnamed)" or FXs[fx].name) .."|"
    end
    local title = "! Hidden window for menu !"
    gfx.init( title, 0, 0, 0, 0, 0 )
    local hwnd = reaper.JS_Window_FindTop( title, true )
    local out = 0
    if hwnd then
      out = 7000
      reaper.JS_Window_Move( hwnd, -out, -out )
    end
    gfx.x, gfx.y = x-52+out, y-70+out
    src_fx = gfx.showmenu(menu)-2
    gfx.quit()
    if src_fx < 0 then return end
  end
  -- set dest fx index from user
  local retval, str = reaper.GetUserInputs("Paste FX to selected items", 1, "Paste to FX slot # (-1 = last)", "-1")
  if not retval then return end
  local dest_fx = tonumber(str)
  if dest_fx > 0 then dest_fx = dest_fx-1 end
  -- copy source fx to dest fx
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()
  local itemCount =  reaper.CountSelectedMediaItems(0)
  for i = 0, itemCount-1 do
    local dest_item = reaper.GetSelectedMediaItem(0,i)
    if dest_item and dest_item ~= src_item then
      local dest_take = reaper.GetActiveTake(dest_item)
      if dest_take then
        reaper.TakeFX_CopyToTake(src_take, src_fx, dest_take, dest_fx, false) -- false=copy, true=move
      end
    end
  end
  reaper.Undo_EndBlock('Copy FX from item under mouse to selected items', -1)
  reaper.PreventUIRefresh(-1)
end

if not reaper.APIExists('JS_Window_FindTop') then
  reaper.MB('js_ReaScriptAPI extension is required for this script.', 'Missing API', 0)
else
  Main()
end
reaper.defer(function () end)

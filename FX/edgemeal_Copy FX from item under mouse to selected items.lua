-- @description Copy FX from item under mouse to selected items
-- @author Edgemeal
-- @version 1.0
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=239565
-- @donation Donate https://www.paypal.me/Edgemeal
-- @about See forum link.

function Main()
  -- get item/active take under mouse
  local src_item = reaper.BR_ItemAtMouseCursor()
  if src_item == nil then return end
  local src_take = reaper.GetActiveTake(src_item)
  if src_take == nil then return end
  if reaper.TakeFX_GetCount(src_take) == 0 then return end -- ignore if no source FX

  -- get source fx index
  local src_fx = 0
  if reaper.TakeFX_GetCount(src_take) > 1 then -- more then one FX, ask user for source slot #
    local retval, str = reaper.GetUserInputs("Copy Take FX", 1, "Copy source FX from slot #", "1")
    if not retval then return end
    src_fx = tonumber(str)-1
    if src_fx < 0 then return end
  end
  -- set dest fx index from user
  local retval, str = reaper.GetUserInputs("Paste Take FX", 1, "Paste to FX slot # (-1=last)", "-1")
  if not retval then return end
  local dest_fx = tonumber(str)
  if dest_fx > 0 then  dest_fx=dest_fx-1 end
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

Main()
reaper.defer(function () end)

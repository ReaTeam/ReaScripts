-- @description Select non-locked items in time selection
-- @author Edgemeal
-- @version 1.0
-- @link Forum https://forum.cockos.com/showthread.php?t=225526
-- @donation Donate https://www.paypal.me/Edgemeal

function Main()
  reaper.Main_OnCommand(40717, 0)
  local cnt = reaper.CountSelectedMediaItems()
  if cnt == 0 then return end
  for i = cnt-1, 0, -1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    if reaper.GetMediaItemInfo_Value(item, 'C_LOCK', 0) == 1 then
      reaper.SetMediaItemInfo_Value(item, 'B_UISEL', 0)
    end
  end
  reaper.UpdateArrange()
end

Main()

-- @description Cycle item last selected take up-down
-- @author Edgemeal
-- @version 1.00
-- @metapackage
-- @provides
--   [main] . > edgemeal_Cycle item last selected take up.lua
--   [main] . > edgemeal_Cycle item last selected take down.lua
-- @donation Donate https://www.paypal.me/Edgemeal
-- @about REAPER cycle next/previous take action cycle all selected takes, but I often want to cycle only the last selected take of the selected item, and came up with this.

function Main()
  local count = reaper.CountSelectedMediaItems(0)
  local item = reaper.GetSelectedMediaItem(0, count-1)
  if item == nil then return end

  local direction = -1
  local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
  if name:match(" down") then direction = 1 end
  local new_index = 0
  local take_count = reaper.CountTakes(item)
  local active_take = reaper.GetActiveTake(item)
  for n = 0, take_count-1 do
    if active_take == reaper.GetTake(item, n) then
      new_index = n + direction
      break
    end
  end
  if new_index < 0 then
    new_index = take_count-1
  elseif new_index > take_count-1 then
    new_index = 0
  end
  reaper.SetActiveTake(reaper.GetTake(item, new_index))
  reaper.UpdateArrange()
end

Main()
reaper.defer(function() end)

--[[
ReaScript name: js_Sort takes by LUFS.lua
Version: 1.01
Changelog:
  + Check for SWS extension.
  + Sort loudest at top.
Author: juliansader
Website: https://forum.cockos.com/showthread.php?t=253025
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION

  Sort takes of selected items by LUFS.
]]

if not reaper.NF_AnalyzeTakeLoudness_IntegratedOnly then reaper.MB("This script requires the SWS/S&M extension.", "ERROR", 0) return end

reaper.Undo_BeginBlock2(0)

tItems = {}

-- Get LUFS for each take
for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    item = reaper.GetSelectedMediaItem(0, i)
    tItems[item] = {}
    for t = 0, reaper.CountTakes(item)-1 do
        take = reaper.GetTake(item, t)
        if take then
            retval, lufsIntegrated = reaper.NF_AnalyzeTakeLoudness_IntegratedOnly(take)
            if retval then
                table.insert(tItems[item], {take = take, lufs = lufsIntegrated})
            end
        end
    end
end

reaper.PreventUIRefresh(1)

-- Sort takes
for item, tTakes in pairs(tItems) do
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect all items
    reaper.SetMediaItemSelected(item, true)
    -- First sort inside table, then apply to item
    -- This sorts loudest take on top. To sort loudest take at bottom, simply change > to <.
    table.sort(tTakes, function(a, b) return (a.lufs > b.lufs) end) 
    for t = #tTakes, 1, -1 do
        reaper.SetActiveTake(tTakes[t].take)
        reaper.Main_OnCommand(41380, 0) -- Item: Move active takes to top
    end
end

-- Restore original item selection
for item in pairs(tItems) do
    reaper.SetMediaItemSelected(item, true)
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

reaper.Undo_EndBlock2(0, "Sort takes by LUFS", -1)

-- @description Toggle take two mono to stereo play (doubletrack mode)
-- @author myrrc
-- @version 1.0
-- @about For media item with two takes, toggle between playing one take a time and both takes playing panned100% left and right (doubletrack mode, useful for guitars).


function msg(...) reaper.ShowConsoleMsg(string.format("%s\n", string.format(...))) end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

if reaper.CountSelectedMediaItems(0) ~=1 then return msg("Only one media item must be selected") end
item = reaper.GetSelectedMediaItem(0, 0)

if reaper.GetMediaItemNumTakes(item) ~= 2 then return msg("Media item must contain two takes") end
left, right = reaper.GetMediaItemTake(item, 0), reaper.GetMediaItemTake(item, 1)

reaper.SetMediaItemInfo_Value(item, "B_ALLTAKESPLAY", reaper.GetMediaItemInfo_Value(item, "B_ALLTAKESPLAY") ~ 1)
reaper.SetMediaItemTakeInfo_Value(left, "D_PAN", math.floor(reaper.GetMediaItemTakeInfo_Value(left, "D_PAN") + 1) % -2)
reaper.SetMediaItemTakeInfo_Value(right, "D_PAN", math.floor(reaper.GetMediaItemTakeInfo_Value(right, "D_PAN") + 1) % 2)

reaper.Undo_EndBlock("Toggle pair take mode", -1)
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)

-- @description Set items snap offset to max peak
-- @author Rodilab
-- @version 1.2
-- @about This script requires SWS extension.

script_name = "Set items snap offset to max peak"

----------------------------------------
-- Debug
----------------------------------------

function Debug()
  if reaper.APIExists('NF_GetMediaItemMaxPeakAndMaxPeakPos') then
    return true
  else
    reaper.ShowMessageBox("Please install \"SWS extension\" : https://www.sws-extension.org", 'Error',0)
    return false
  end
end

----------------------------------------
-- Main
----------------------------------------

function main()
  count = reaper.CountSelectedMediaItems(0)
  if count > 0 then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    for i=0, count-1 do
      local item = reaper.GetSelectedMediaItem(0, i)
      rv, maxPeakPos = reaper.NF_GetMediaItemMaxPeakAndMaxPeakPos(item)
      if rv  and rv > -150 then
        reaper.SetMediaItemInfo_Value(item, 'D_SNAPOFFSET', maxPeakPos)
      end
    reaper.Undo_EndBlock(script_name, 0)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    end
  end
end

if Debug() then
  main()
end

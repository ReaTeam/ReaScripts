-- @description Set items snap offset to max peak
-- @author Rodilab
-- @version 1.1
-- @about This script requires "spk77_Get max peak val and pos from take_function", please install it first.

script_name = "Set items snap offset to max peak"

----------------------------------------
-- Debug
----------------------------------------

do
  local separ = package.config:sub(1,1)
  local script_path = reaper.GetResourcePath()..separ..'Scripts'..separ..'X-Raym Scripts'..separ..'Functions'..separ..'spk77_Get max peak val and pos from take_function.lua'
  if reaper.file_exists(script_path) then
    dofile(script_path)
  else
    reaper.ShowMessageBox("Please install \"spk77_Get max peak val and pos from take_function.lua\"", "Error",0)
    if reaper.APIExists('ReaPack_BrowsePackages') then
      reaper.ReaPack_BrowsePackages('spk77_Get max peak val and pos from take_function.lua')
    end
    return
  end
end

----------------------------------------
-- Main
----------------------------------------

count = reaper.CountSelectedMediaItems(0)
if count > 0 then
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  for i=0, count-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    rv, max_peak_val, peak_sample_pos = get_sample_max_val_and_pos(take, false, false, false)
    if rv then
      reaper.SetMediaItemInfo_Value(item, 'D_SNAPOFFSET', peak_sample_pos )
    end
  reaper.Undo_EndBlock(script_name,0)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  end
end

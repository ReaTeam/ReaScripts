--[[
   * ReaScript Name: Toggle selecting all items on track under mouse cursor
   * Lua script for Cockos REAPER
   * Author: EvilDragon
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
_, _, _ = reaper.BR_GetMouseCursorContext()
track = reaper.BR_GetMouseCursorContext_Track()

if track ~= nil then
  num_items = reaper.GetTrackNumMediaItems(track)

  if num_items > 0 then
    reaper.Undo_BeginBlock()
    reaper.Main_OnCommand(40289, 0)

    first_item = reaper.GetTrackMediaItem(track, 0)
    first_item_sel =  reaper.IsMediaItemSelected(first_item)

    for i = 0, num_items - 1 do
      item = reaper.GetTrackMediaItem(track, i)
      reaper.SetMediaItemSelected(item, not first_item_sel)
    end

    reaper.Undo_EndBlock("Toggle selecting all items on track under mouse cursor", 0)
  end 
end

reaper.UpdateArrange()

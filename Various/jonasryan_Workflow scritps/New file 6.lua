-- @noindex

function main()
  local total_count, num_markers, num_regions = reaper.CountProjectMarkers(0)
  if num_regions == 0 then
    reaper.ShowMessageBox("No regions in project.", "Error", 0)
    return
  end

  local markersData = {}
  reaper.Undo_BeginBlock()

  for i = 0, total_count - 1 do
    local ok, isrgn, rgn_start, rgn_end, name, idx = reaper.EnumProjectMarkers(i)
    if ok and isrgn then
      local counter = 1
      local num_items = reaper.CountMediaItems(0)

      for j = 0, num_items - 1 do
        local it = reaper.GetMediaItem(0, j)
        local it_pos = reaper.GetMediaItemInfo_Value(it, "D_POSITION")

        if it_pos > rgn_start and it_pos < rgn_end then
          local marker_name = "#" .. tostring(counter)
          local object = { pos = it_pos, name = marker_name }
          markersData[#markersData + 1] = object
          counter = counter + 1
        end
      end
    end
  end

  -- Add markers after collecting all positions
  for j = 1, #markersData do
    reaper.AddProjectMarker(0, false, markersData[j].pos, 0, markersData[j].name, -1)
  end

  reaper.Undo_EndBlock("Add numbered # markers at items in all regions", -1)
end

main()

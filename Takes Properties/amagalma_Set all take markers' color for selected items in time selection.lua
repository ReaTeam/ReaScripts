-- @description Set all take markers' color for selected items in time selection
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about Sets the color of all take markers which fall inside the time selection, for all takes of all selected items


local ts_start, ts_end = reaper.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
if ts_start == ts_end then return end

local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt == 0 then return end

local ok, color = reaper.GR_SelectColor()

local undo = false
if ok == 1 then
  reaper.PreventUIRefresh( 1 )
  for i = 0, item_cnt-1 do
		local item = reaper.GetSelectedMediaItem( 0, i )
		local take_cnt = reaper.CountTakes( item )
		if take_cnt > 0 then
			local item_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
			for tk = 0, take_cnt-1 do
				local take = reaper.GetMediaItemTake( item, tk )
				local marker_cnt = reaper.GetNumTakeMarkers( take )
				if marker_cnt > 0 then
					local start_offset = reaper.GetMediaItemTakeInfo_Value( take, "D_STARTOFFS" )
					for m = 0, marker_cnt-1 do
						local position, name = reaper.GetTakeMarker( take, m )
						local project_pos = position - start_offset + item_pos
						if ts_start <= project_pos and project_pos <= ts_end then
							reaper.SetTakeMarker( take, m, name, nil, color|0x1000000 )
							undo = true
						end
					end
				end
			end
		end
  end
	reaper.PreventUIRefresh( -1 )
	reaper.UpdateArrange()
end

if undo then
	reaper.Undo_OnStateChangeEx( "Set take marker color", 4, -1 )
end

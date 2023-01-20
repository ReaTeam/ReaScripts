-- @description Split media items at Razor Edit area edges (crossfades to the left of the splits)
-- @author amagalma
-- @version 2.0
-- @changelog Added Fixed Lanes support
-- @donation https://www.paypal.me/amagalma
-- @about Like the native action of the Razor edit area left click context, but with the difference that it always creates crossfades to the left of the area edges.

local floor = math.floor

local function GetRazorEditEdgesPerTrack()
  local RazorEdges, track_cnt = {}, 0
  for i = 0, reaper.CountTracks(0)-1 do
    local track = reaper.GetTrack(0, i)
    local _, area = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS_EXT", "", false)
    if area ~= "" then
      local first_item = reaper.GetTrackMediaItem( track, 0 )
      if first_item then
        local fixed_lanes = reaper.GetMediaTrackInfo_Value( track, "I_FREEMODE" ) == 2
        local lane_height
        if fixed_lanes then
          lane_height = reaper.GetMediaItemInfo_Value( first_item, "F_FREEMODE_H" )
        else
          lane_height = 1
        end
        track_cnt = track_cnt + 1
        RazorEdges[track_cnt] = {track = track, lane = {}, numberOfLanes = floor(1/lane_height+0.5)}
        for tuple in string.gmatch(area, "[^,]+") do
          for st, en, env, y_top, y_bot in string.gmatch(tuple, "(%S+) (%S+) (%S+) (%S+) (%S+)") do
            if env == '""' then
              if lane_height == 1 then
                local num = 0
                if not RazorEdges[track_cnt].lane[1] then
                  RazorEdges[track_cnt].lane[1] = {n = 0}
                else
                  num = RazorEdges[track_cnt].lane[1].n
                end
                num = num + 1 ; RazorEdges[track_cnt].lane[1].n = num
                RazorEdges[track_cnt].lane[1][num] = tonumber(st)
                num = num + 1 ; RazorEdges[track_cnt].lane[1].n = num
                RazorEdges[track_cnt].lane[1][num] = tonumber(en)
              else
                local upper_RE_lane = floor( tonumber(y_top) / lane_height + 1.5 )
                local lower_RE_lane = floor( tonumber(y_bot) / lane_height + 0.5 )
                for lane = upper_RE_lane, lower_RE_lane do
                  local num = 0
                  if not RazorEdges[track_cnt].lane[lane] then
                    RazorEdges[track_cnt].lane[lane] = {n = 0}
                  else
                    num = RazorEdges[track_cnt].lane[lane].n
                  end
                  num = num + 1 ; RazorEdges[track_cnt].lane[lane].n = num
                  RazorEdges[track_cnt].lane[lane][num] = tonumber(st)
                  num = num + 1 ; RazorEdges[track_cnt].lane[lane].n = num
                  RazorEdges[track_cnt].lane[lane][num] = tonumber(en)
                end
              end
            end
          end
        end
      end
    end
  end
  -- Remove same starts and ends to make it work like native split action
  for tr = 1, track_cnt do
    if RazorEdges[tr].numberOfLanes ~= 1 then
      for lane, Edges in pairs(RazorEdges[tr].lane) do
        if Edges.n > 2 then
          local prev_edge = Edges[Edges.n - 1]
          for ed = Edges.n-2, 2, -2 do
            if prev_edge == Edges[ed] then
              table.remove(Edges, ed+1)
              table.remove(Edges, ed)
              Edges.n = Edges.n - 2
            end
            prev_edge = Edges[ed-1]
          end
        end
      end
    end
  end
  return RazorEdges, track_cnt
end

local RazorEdges, TracksWithEdges_cnt = GetRazorEditEdgesPerTrack()
if TracksWithEdges_cnt == 0 then return reaper.defer(function() end) end

-----------------------------------------------------------------------------------------

local Items = {}
local function GetItems()
  for tr = 1, TracksWithEdges_cnt do
    local track = RazorEdges[tr].track
    local item_cnt = reaper.CountTrackMediaItems(track)
    if item_cnt > 0 then
      Items[tr] = {lane = {}}
      for it = 0, item_cnt-1 do 
        local item = reaper.GetTrackMediaItem(track, it)
        local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_end = item_pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local isEmpty = reaper.CountTakes( item ) == 0
        local isMidi = (not isEmpty) and ( reaper.TakeIsMIDI( reaper.GetActiveTake( item ) ) )
        local item_lane = 1
        if RazorEdges[tr].numberOfLanes ~= 1 then
          item_lane =
          floor(reaper.GetMediaItemInfo_Value( item, "F_FREEMODE_Y" ) * RazorEdges[tr].numberOfLanes + 1.5)
        end
        if RazorEdges[tr].lane[item_lane] then
          local num = 0
          if not Items[tr].lane[item_lane] then
            Items[tr].lane[item_lane] = {n = 0}
          else
            num = Items[tr].lane[item_lane].n
          end
          num = num + 1 ; Items[tr].lane[item_lane].n = num
          Items[tr].lane[item_lane][num] = 
          { item = item, _pos = item_pos, _end = item_end, moveXfade = ( ((not isEmpty) and (not isMidi)) ) }
        end
      end
    end
  end
end

GetItems()

-----------------------------------------------------------------------------------------

local function SplitAtEdges( RazorEdges, TracksWithEdges_cnt, Items )
  local xfadetime = 0
  if reaper.GetToggleCommandState( 40912 ) == 1 then -- -- Auto-crossfade on split enabled
    xfadetime = tonumber(({reaper.get_config_var_string( "defsplitxfadelen" )})[2]) or 0.01
  end
  for tr = 1, TracksWithEdges_cnt do
    for lane, Edges in pairs(RazorEdges[tr].lane) do
      local current_edge = Edges.n
      local Item = Items[tr].lane[lane]
      local it = Item.n
      while it ~= 0 do
        while current_edge ~= 0 do
          local split_pos = RazorEdges[tr].lane[lane][current_edge] - (Item[it].moveXfade and xfadetime or 0)
          if split_pos > Item[it]._pos and split_pos < Item[it]._end then
            local new_item = reaper.SplitMediaItem( Item[it].item, split_pos )
            if current_edge % 2 == 1 then reaper.SetMediaItemSelected( new_item, true ) end
            current_edge = current_edge - 1
          elseif split_pos >= Item[it]._end then
            current_edge = current_edge - 1
          elseif split_pos <= Item[it]._pos then
            break
          end
        end
        it = it - 1
      end
    end
    reaper.GetSetMediaTrackInfo_String(RazorEdges[tr].track, "P_RAZOREDITS", "", true)
  end
end

-----------------------------------------------------------------------------------------

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh( 1 )
SplitAtEdges( RazorEdges, TracksWithEdges_cnt, Items )
reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()
reaper.Undo_EndBlock( "Split at razor edit edges", 1|4 )

-- @description Split media items at Razor Edit area edges (crossfades to the left of the splits)
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about Like the native action of the Razor edit area left click context, but with the difference that it always creates crossfades to the left of the area edges.


local function GetRazorEditEdgesPerTrack()
  local RazorEdges, cnt = {}, 0
  for i = 0, reaper.CountTracks(0)-1 do
    local track = reaper.GetTrack(0, i)
    local _, area = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    if area ~= "" then
      cnt = cnt + 1
      RazorEdges[cnt] = {track, {}, n = 0} -- [1] track ptr, [2] areas table, n = area edge count
      for st, en, env in string.gmatch(area, "(%S+) (%S+) (%S+)") do
        if env == '""' then
          RazorEdges[cnt].n = RazorEdges[cnt].n + 1
          RazorEdges[cnt][2][RazorEdges[cnt].n] = tonumber(st)
          RazorEdges[cnt].n = RazorEdges[cnt].n + 1
          RazorEdges[cnt][2][RazorEdges[cnt].n] = tonumber(en)
        end
      end
    end
  end
  return RazorEdges, cnt
end

local RazorEdges, RazorEdges_cnt = GetRazorEditEdgesPerTrack()
if RazorEdges_cnt == 0 then return reaper.defer(function() end) end

-----------------------------------------------------------------------------------------

local function SplitAtEdges( RazorEdges, RazorEdges_cnt )
  local xfadetime = tonumber(({reaper.get_config_var_string( "defsplitxfadelen" )})[2]) or 0.01
  for tr = 1, RazorEdges_cnt do
    local track = RazorEdges[tr][1]
    local item_cnt = reaper.CountTrackMediaItems(track)
    if item_cnt ~= 0 then
      local current_edge = RazorEdges[tr].n
      local it = item_cnt-1
      while it ~= -1 do
        local item = reaper.GetTrackMediaItem(track, it)
        local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_end = item_pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        while current_edge ~= 0 do
          local split_pos = RazorEdges[tr][2][current_edge] - xfadetime
          if split_pos > item_pos and split_pos < item_end then
            reaper.SplitMediaItem( item, split_pos )
            current_edge = current_edge - 1
          elseif split_pos >= item_end then
            current_edge = current_edge - 1
          elseif split_pos <= item_pos then
            break
          end
        end
        it = it - 1
      end
    end
    reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", true)
  end
end

-----------------------------------------------------------------------------------------

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh( 1 )

if reaper.GetToggleCommandState( 40912 ) ~= 1 then
  reaper.Main_OnCommand(40912, 0) -- Toggle auto-crossfade on split
  restore = true
end

SplitAtEdges( RazorEdges, RazorEdges_cnt )

if restore then
  reaper.Main_OnCommand(40912, 0) -- Toggle auto-crossfade on split
end

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()
reaper.Undo_EndBlock( "Split at razor edit edges", 1|4 )

-- @description Remove all item fades within Razor Edit areas
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Removes all item fades within Razor Edit areas
--
--   - You can set inside the script if you want to remove or keep the RE areas (default: remove)
--   - Smart undo creation


-- USER SETTINGS --------------------------------------------------------
local remove_RE_area = true -- keeps or removes the RE area (true/false)
-------------------------------------------------------------------------


local track_cnt = reaper.CountTracks(0)
if track_cnt == 0 then return end

local undo = false
local tracks_with_RE = {}
local max = math.max

local function removeFadeIn( item )
  reaper.SetMediaItemInfo_Value( item, "D_FADEINLEN", 0 )
  reaper.SetMediaItemInfo_Value( item, "D_FADEINLEN_AUTO", 0 )
end

local function removeFadeOut( item )
  reaper.SetMediaItemInfo_Value( item, "D_FADEOUTLEN", 0 )
  reaper.SetMediaItemInfo_Value( item, "D_FADEOUTLEN_AUTO", 0 )
end

reaper.PreventUIRefresh( 1 )
for tr = 0, track_cnt - 1 do
  local track = reaper.GetTrack(0, tr)
  local _, areas = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
  if areas ~= "" then
    local area_table, ar_cnt = {}, 0
    local itemidx = 0
    for area_start, area_end in string.gmatch(areas, "(%S+) (%S+) %S+%s?") do
      ar_cnt = ar_cnt + 1
      area_table[ar_cnt] = { tonumber(area_start), tonumber(area_end) }
    end
    for i = 0, reaper.CountTrackMediaItems( track ) - 1 do
      local item = reaper.GetTrackMediaItem( track, i )
      local item_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local item_end = item_pos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
      local fadein_len = max( reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN" ),
                              reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN_AUTO" ) )
      local fadeout_len = max( reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN" ),
                              reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN_AUTO" ) )
      for ar = 1, ar_cnt do
        if fadein_len > 0 then
          local fade_end = item_pos + fadein_len
          if fade_end < area_table[ar][1] or item_pos > area_table[ar][2] then
            -- do nothing
          else -- intersection
            if not undo then
              reaper.Undo_BeginBlock()
              undo = true
            end
            removeFadeIn( item )
            tracks_with_RE[track] = true
          end
        end
        if fadeout_len > 0 then
          local fade_start = item_end - fadeout_len
          if fade_start > area_table[ar][2] or item_end < area_table[ar][1] then
            -- do nothing
          else -- intersection
            if not undo then
              reaper.Undo_BeginBlock()
              undo = true
            end
            removeFadeOut( item )
            tracks_with_RE[track] = true
          end
        end
      end
    end
  end
end

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()

if undo then
  if remove_RE_area then
    for track in pairs( tracks_with_RE ) do
      reaper.GetSetMediaTrackInfo_String( track, "P_RAZOREDITS", "", true )
    end
  end
  reaper.Undo_EndBlock( "Remove all fades within RE areas", ( remove_RE_area and 1 or 0)|4 )
else
  reaper.defer( function() end )
end

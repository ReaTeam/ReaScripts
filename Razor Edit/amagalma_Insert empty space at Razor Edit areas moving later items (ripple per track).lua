-- @description Insert empty space at Razor Edit areas moving later items (ripple per track)
-- @author amagalma
-- @version 1.01
-- @changelog Fixed action misbehaving when already in Ripple mode
-- @link https://forum.cockos.com/showthread.php?t=266539
-- @donation https://www.paypal.me/amagalma
-- @about Similar to native "Insert empty space at time selection (moving later items)" but works with Razor Edits and ripples per track.


-- Check for razor edits
local razor_edits_exist = false
for i = 0, reaper.CountTracks(0) - 1 do
  local track = reaper.GetTrack(0, i)
  local _, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
  if area ~= "" then
    razor_edits_exist = true
    break
  end
end
if not razor_edits_exist then return reaper.defer(function() end) end

local items = {}
for i = 0, reaper.CountMediaItems( 0 )-1 do
  items[reaper.GetMediaItem(0, i)] = true
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh( 1 )

local editing_per_track = reaper.GetToggleCommandState( 40310 ) == 1
local editing_all_tracks = reaper.GetToggleCommandState( 40311 ) == 1

if not editing_per_track then
  reaper.Main_OnCommand( 40310, 0 )
end

reaper.Main_OnCommand(40142, 0) -- Insert empty item

for i = 0, reaper.CountMediaItems( 0 )-1 do
  local item = reaper.GetMediaItem(0, i)
  if not items[item] then
    reaper.SetMediaItemSelected( item, true )
  end
end
reaper.Main_OnCommand(40309, 0) -- Set ripple editing off
reaper.Main_OnCommand(40006, 0) -- Remove items

if editing_all_tracks then
  reaper.Main_OnCommand( 40311, 0 ) -- Set ripple editing all tracks
elseif editing_per_track then
  reaper.Main_OnCommand( 40310, 0 ) -- Set ripple editing per track
else
  reaper.Main_OnCommand(40309, 0) -- Set ripple editing off
end

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()
reaper.Undo_EndBlock("Insert empty space at razor edits (moving later items)", 1|4|8)

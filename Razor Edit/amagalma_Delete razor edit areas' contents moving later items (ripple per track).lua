-- @description Delete razor edit areas' contents moving later items (ripple per track)
-- @author amagalma
-- @version 1.0
-- @link https://forum.cockos.com/showthread.php?t=266539
-- @donation https://www.paypal.me/amagalma
-- @about Similar to native "Remove contents of time selection (moving later items)" but works with razor edit areas and ripples per track.

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

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh( 1 )

local editing_per_track = reaper.GetToggleCommandState( 40310 ) == 1
local editing_all_tracks = reaper.GetToggleCommandState( 40311 ) == 1

if not editing_per_track then
  reaper.Main_OnCommand( 40310, 0 )
  restore = true
end

reaper.Main_OnCommand(40312, 0) -- Remove selected area of items

if restore then
  if editing_all_tracks then
    reaper.Main_OnCommand( 40311, 0 )
  else
    reaper.Main_OnCommand(40309, 0) -- Set ripple editing off
  end
end

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()
reaper.Undo_EndBlock("Remove RE contents moving later items", 1|4|8)

-- @description Toggle visibility of empty non-folder tracks
-- @version 1.1
-- @author cfillion
-- @link
--   cfillion.ca https://cfillion.ca/
--   Forum Thread http://forum.cockos.com/showthread.php?t=187651
-- @donation https://www.paypal.me/cfillion
-- @provides
--   [main] .
--   [main] . > cfillion_Toggle visibility of empty non-folder tracks matching '•'.lua
-- @changelog
--   Fixed embarassing typo in the name ('visiblity' -> 'visibility')
--   Added a "matching '•'" variant of the script at the request of blumpy
-- @about
--   # Toggle visibility of empty non-folder tracks
--
--   This script toggles the TCP and MCP visibility of tracks matching all of the
--   following criteria:
--
--   - Track has no FX on it
--   - Track does not contain any media item
--   - Track has no envelopes
--   - Track is not a folder
--   - Track is not record armed
--
--   A variant of the script is provided which additionally requires tracks to
--   contain the character • (bullet) in their name. Custom variants can be
--   created by copying the script with the desired track name search string
--   between the apostrophes in the filename.

local UNDO_STATE_TRACKCFG = 1
local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local empty_tracks, setVisible = {}, 0
local match = script_name:match("matching '([^']+)'")

for ti=0,reaper.CountTracks()-1  do
  local track = reaper.GetTrack(0, ti)

  local fx_count   = reaper.TrackFX_GetCount(track)
  local item_count = reaper.CountTrackMediaItems(track)
  local env_count  = reaper.CountTrackEnvelopes(track)
  local depth      = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
  local is_armed   = reaper.GetMediaTrackInfo_Value(track, "I_RECARM")
  local name       = ({reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)})[2]
  local matches    = (function()
    if not match or name:find(match) then
      return 0
    else
      return 1
    end
  end)()

  if fx_count + item_count + env_count + math.max(depth, 0) + is_armed + matches == 0 then
    local mcpVis = reaper.GetMediaTrackInfo_Value(track, 'B_SHOWINMIXER')
    local tcpVis = reaper.GetMediaTrackInfo_Value(track, 'B_SHOWINMIXER')

    if mcpVis + tcpVis == 0 then
      setVisible = 1
    end

    table.insert(empty_tracks, track)
  end
end

if #empty_tracks == 0 then return reaper.defer(function() end) end

reaper.Undo_BeginBlock()

for i,track in ipairs(empty_tracks) do
  reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINMIXER', setVisible)
  reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', setVisible)
end

reaper.Undo_EndBlock(script_name, UNDO_STATE_TRACKCFG)

reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()

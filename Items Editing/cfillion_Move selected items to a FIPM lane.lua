-- @description Move selected items to a FIPM lane
-- @version 1.0
-- @author cfillion
-- @website
--   cfillion.ca https://cfillion.ca
--   Request Thread https://forum.cockos.com/showthread.php?t=200756
-- @donate https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD&item_name=FIPM+-+Move+selected+items+to+a+given+lane
-- @about
--   This script provides a set of two actions for moving the selected media
--   items to the top or bottom FIPM lane of the track. Each lane is half of the
--   track's height.
--
--   FIPM (Free Item Positioning Mode) is enabled on the tracks as required.
-- @provides
--   [main] . > cfillion_Move selected items to top FIPM lane (half track height).lua
--   [main] . > cfillion_Move selected items to bottom FIPM lane (half track height).lua

local script_name = ({reaper.get_action_context()})[2]:match('([^/\\_]+).lua$')

reaper.Undo_BeginBlock()

for ii=0,reaper.CountSelectedMediaItems(0)-1 do
  local item = reaper.GetSelectedMediaItem(0, ii)
  local track = reaper.GetMediaItemTrack(item)
  
  if reaper.GetMediaTrackInfo_Value(track, 'B_FREEMODE') ~= 1 then
    reaper.SetMediaTrackInfo_Value(track, 'B_FREEMODE', 1)
  end

  local y, h = 0, 0.5
  if script_name:match('bottom') then
    y = 0.5
  end
  
  reaper.SetMediaItemInfo_Value(item, 'F_FREEMODE_Y', y)
  reaper.SetMediaItemInfo_Value(item, 'F_FREEMODE_H', h)
end

reaper.UpdateTimeline()
reaper.Undo_EndBlock(script_name, -1)

-- Description: Unselect first/last selected item
-- Version: 1.0
-- Author: FnA
-- Changelog: Initial release
-- Link: Forum Thread http://forum.cockos.com/showthread.php?t=191368
-- About:
--   This package script makes two actions in Action List, shown in "Provides:" below
--   selected items are indexed left to right before advancing to next track
-- MetaPackage: true
-- Provides:
--   [main] . > FnA_Unselect First Selected Item.lua
--   [main] . > FnA_Unselect Last Selected Item.lua

local filename = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local isFirst = filename:match("First")

---------------------------------------------------
local r = reaper
if isFirst then
  function Fn_Unselect_First()
    local csi = r.CountSelectedMediaItems(0)
    if csi > 0 then
      r.SetMediaItemSelected(r.GetSelectedMediaItem(0,0), false)
      r.UpdateArrange()
    end
  end
  Fn_Unselect_First()
else
  function Fn_Unselect_Last()
    local csi = r.CountSelectedMediaItems(0)
    if csi > 0 then
      r.SetMediaItemSelected(r.GetSelectedMediaItem(0,csi-1), false)
      r.UpdateArrange()
    end
  end
  Fn_Unselect_Last()
end

function NoUndoPoint() end 
reaper.defer(NoUndoPoint)

--[[
ReaScript name: js_Convert all stretch markers in take under mouse to slopes with starting rate 1.0, to protect transients.lua
Version: 1.01
Author: juliansader
Screenshot: https://stash.reaper.fm/32594/Convert%20all%20stretch%20markers%20to%20slopes.JPG
Website: https://forum.cockos.com/showthread.php?p=1932922&postcount=77
Extensions:  SWS/S&M 2.8.3 or later
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION
  
  A script for easy, one-click conversion of stretch markers in take under mouse to 
  slopes with starting rate 1.0.  
  
  By setting a starting rate of 1.0, time-stretching artefacts on the transient immediately after the marker are minimized.
  
  (Of course, as is the case for any time-stretch tactic, other artefacts may still arise.)

  For easy use during editing, this script can be linked to a mouse modifier (such as shift+ctrl+double click) in the "Media item stretch marker" context.
]] 

--[[
  Changelog:
  * v1.00 (2018-01-01)
    + Initial Release.
  * v1.01 (2018-01-01)
    + Little undo tweak.
]]

if not reaper.APIExists("BR_TakeAtMouseCursor") then
    reaper.MB("This script requires the SWS/S&M extension, which can be downloaded from\n\nwww.sws-extension.org", "ERROR", 0)
    return
end
take = reaper.BR_TakeAtMouseCursor()
if not reaper.ValidatePtr2(0, take, "MediaItem_Take*") then return end
numStretchMarkers = reaper.GetTakeNumStretchMarkers(take)
if numStretchMarkers == 0 then return end
for s = 0, numStretchMarkers-2 do
    _, takePos, sourcePos = reaper.GetTakeStretchMarker(take, s)
    _, nextTakePos, nextSourcePos = reaper.GetTakeStretchMarker(take, s+1)
    -- The API slope paramater is different from the slope value given in the mouse cursor tooltip.
    -- A bit of experimentation gave this formula (for slopes starting with playrate 1.00):
    slope = 1-(nextTakePos-takePos)/(nextSourcePos-sourcePos)
    reaper.SetTakeStretchMarkerSlope(take, s, slope)
end
item = reaper.GetMediaItemTake_Item(take)
reaper.UpdateItemInProject(item)
reaper.Undo_OnStateChange_Item(0, "Convert stretch markers to slopes", item)




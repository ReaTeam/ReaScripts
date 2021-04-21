--[[
ReaScript name: js_Razor edit - Enclose selected media items and automation items in minimal razor areas.lua
Version: 1.00
Changelog:
  + Initial release.
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION
  
  REAPER currently has limited functionality for moving, copying or duplicating selected Media Items together with selected Automation Items.
  
  This script offers a workaround: the MIs and AIs can be enclosed within minimal razor areas, and razor editing functions can then be used to move or copy the items together.
]]
reaper.Undo_BeginBlock2(0)
tS = {}
for t = 0, reaper.CountTracks(0)-1 do
    track = reaper.GetTrack(0, t)
    for e = 0, reaper.CountTrackEnvelopes(track)-1 do
        env = reaper.GetTrackEnvelope(track, e)
        guidOK, guid = reaper.GetSetEnvelopeInfo_String(env, "GUID", "", false)
        for ai = 0, reaper.CountAutomationItems(env)-1 do
            if reaper.GetSetAutomationItemInfo(env, ai, "D_UISEL", 0, false) ~= 0 then
                left = reaper.GetSetAutomationItemInfo(env, ai, "D_POSITION", 0, false)
                right = left + reaper.GetSetAutomationItemInfo(env, ai, "D_LENGTH", 0, false)
                tS[track] = (tS[track] or "") .. string.format([[%.16f %.16f "%s" ]], left, right, guid)
            end
        end
    end
end
for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    item = reaper.GetSelectedMediaItem(0, i)
    left = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    right = left + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    track = reaper.GetMediaItemTrack(item)
    tS[track] = (tS[track] or "") .. string.format([[%.16f %.16f "" ]], left, right)
end
for track, str in pairs(tS) do
    reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", str, true)
end
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "Enclose items in minimal razor areas", -1)

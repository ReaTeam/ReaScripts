--[[
   * ReaScript Name: Show tracknames in console
   * Lua script for Cockos REAPER
   * Author: nofish
   * Author URI: http://forum.cockos.com/member.php?u=6870
   * Licence: GPL v3
   * Version: 1.0
]]
  
--[[ 
List tracknames in console
Version: 1.0

see http://forum.cockos.com/showpost.php?p=1597751&postcount=6
a mod from http://forum.cockos.com/showpost.php?p=1596059&postcount=26

if tracks selected it lists only the selected tracks,
otherwise it lists all tracks
--]]


function msg(m)
  reaper.ShowConsoleMsg(tostring(m) .. "\n")
end
     
-- check if any tracks are selected
count_sel_track = reaper.CountSelectedTracks(0)
if count_sel_track ~= 0 then -- check if any track is selected
  counttrack = reaper.CountSelectedTracks(0)
else -- if no track is selected
  counttrack = reaper.CountTracks(0)
end
if counttrack ~= nil then
  for i = 1, counttrack do
  if count_sel_track ~= 0 then
    track = reaper.GetSelectedTrack(0,i-1)
  else
    track = reaper.GetTrack(0,i-1)
  end
    if track ~= nil then
    -- get track number for current track
    trackNumber = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
    trackNumber = math.ceil(trackNumber) -- strip the decimals
    
    _, trackname = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
    if trackname == '' then name = 'Track '..trackNumber else name = 'Track '..trackNumber..' - '..trackname end
    msg (name)
    end -- if tr not nil
  end -- loop tr
end -- counttrack

    
 
    
  


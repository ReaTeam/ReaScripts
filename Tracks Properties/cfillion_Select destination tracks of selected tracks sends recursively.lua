-- @description Select destination tracks of selected tracks sends recursively
-- @version 1.0.1
-- @author cfillion
-- @link Forum Thread http://forum.cockos.com/showthread.php?t=183638
-- @changelog Disable undo point creation

local function highlight(track)
  for i=0,reaper.GetTrackNumSends(track, 0)-1 do
    local target = reaper.BR_GetMediaTrackSendInfo_Track(track, 0, i, 1)

    reaper.SetTrackSelected(target, true)
    highlight(target)
  end
end

local function main()
  for i=0,reaper.CountSelectedTracks(0)-1 do
    local track = reaper.GetSelectedTrack(0, i)
    highlight(track)
  end
end

reaper.defer(main)

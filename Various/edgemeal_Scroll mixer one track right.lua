-- @description Scroll mixer one track right
-- @author Edgemeal
-- @version 1.0
-- @link Forum https://forum.cockos.com/showthread.php?t=227183
-- @donation Donate https://www.paypal.me/Edgemeal

function ScrollOneTrackRight()
  local t = {}
  local tr_count = reaper.CountTracks(0)-1
  for i = 0, tr_count do
    local track = reaper.GetTrack(0,i)
    if track and reaper.IsTrackVisible(track, true) then
      t[#t+1] = track
    end
  end
  local tr = reaper.GetMixerScroll()
  for i = 1, #t-1 do
    if tr == t[i] then
      reaper.SetMixerScroll(t[i+1])
      break
    end
  end
end
ScrollOneTrackRight()
reaper.defer(function () end)
-- @description Disable multichannel metering on selected tracks
-- @author Edgemeal
-- @version 1.0
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=208982

-- Disable multichannel metering on selected tracks
-- Edgemeal
-- v1.0
-- https://forum.cockos.com/showthread.php?t=208982

local tracks = reaper.CountSelectedTracks()
if tracks == 0 then return end

--init_time = reaper.time_precise() -- For benchmarking code.

reaper.PreventUIRefresh(1)

-- get selected tracks
trk={}
for i = 0, tracks-1 do
  trk[i+1] = reaper.GetSelectedTrack(0, i)
end

reaper.Main_OnCommand(40297, 0)  -- Track: Unselect all tracks

-- disable multichannel for selected tracks
for i = 1, #trk do 
  local ret, str = reaper.GetTrackStateChunk(trk[i],"",false) 
  for line in str:gmatch('[^\r\n]+') do
    if line == 'VU 2' then -- multichannel metering is on.
      reaper.SetTrackSelected(trk[i], true)
      reaper.Main_OnCommand(41726, 0) -- Track: Toggle full multichannel metering
      reaper.SetTrackSelected(trk[i], false)
      break 
    elseif line:find("TRACKHEIGHT ") then -- went past where VU line normally is so skip to next track.
      break 
    end
  end
end

-- restore selected tracks
for i = 1, #trk do  
  reaper.SetTrackSelected(trk[i], true)
end

reaper.PreventUIRefresh(-1)

-- >>> For benchmarking code,...
-- duration = reaper.time_precise() - init_time
-- reaper.ShowConsoleMsg(tostring(duration) .. "\n")
-- <<<
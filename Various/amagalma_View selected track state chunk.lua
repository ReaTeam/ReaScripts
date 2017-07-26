-- @description amagalma_View selected track state chunk
-- @author amagalma
-- @version 1.0
-- @about
--   # Opens the selected track's state chunk


-----------
Save = 0 -- Set to 1 if you want the file not to be erased
-----------
----------------------------
fullpath = "C:/chunk.txt" -- Set path and filename here (Save must be set to 1)
----------------------------

local reaper = reaper

local function WriteChunkToFile()
  local track = reaper.GetSelectedTrack(0,0)
  if track then
    local _, chunk = reaper.GetTrackStateChunk(track, "", true)
    local file = io.open(fullpath, "w+")
    file:write(chunk)
    io.close(file)
    reaper.BR_Win32_ShellExecute("edit", fullpath, nil, nil, 3)
    start = reaper.time_precise()
    function main()
      local time = reaper.time_precise()
      if time-start < 1 then
        reaper.defer(main)
      else
        os.remove(fullpath)
      end
    end
    if Save == 0 then
    main()
    end
  end
end

WriteChunkToFile()
function NoUndoPoint() end
reaper.defer(NoUndoPoint)

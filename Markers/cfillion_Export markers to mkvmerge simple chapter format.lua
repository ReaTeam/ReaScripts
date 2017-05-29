-- @description Export markers to mkvmerge simple chapter format
-- @author cfillion
-- @version 1.0
-- @website http://cfillion.ca
-- @donation https://www.paypal.me/cfillion
-- @about
--   # Usage Instructions
--
--   1. Create your markers
--   2. Run this script
--   3. Paste the generated text into a text file
--   4. Run the following command to merge your video with the chapter text file:
--     `mkvmerge input.mov --chapters chapters.txt --default-language eng -o output.mpv

local next_index = 0

reaper.ClearConsole()

while true do
  -- marker = {retval, isrgn, pos, rgnend, name, markrgnindexnumber, color}
  local marker = {reaper.EnumProjectMarkers3(0, next_index)}

  next_index = marker[1]
  if next_index == 0 then break end

  if not marker[2] then -- it's not a region
    local time = marker[3]
    hour = math.floor(time / 3600)
    time = time % 3600
    min = math.floor(time / 60)
    time = time % 60
    sec = math.floor(time)
    ms = math.floor((time % 1) * 1000)
  
    reaper.ShowConsoleMsg(
      string.format("CHAPTER%02d=%02d:%02d:%02d.%03d\nCHAPTER%02dNAME=%s\n",
      marker[6], hour, min, sec, ms, marker[6], marker[5]))
  end
end

reaper.defer(function() end) -- disable undo point

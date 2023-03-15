-- @description Paste text from clipboard to selected tracks names (separate by newline)
-- @author Mordi
-- @version 1.0
-- @changelog Initial release.
-- @screenshot https://i.imgur.com/SZqNCDZ.gif
-- @about
--   # Paste text from clipboard to selected tracks names (separate by newline)
--
--   Made for copying an asset list from Google Docs into Reaper. Each line is copied to each selected track.
--
--   Should work in any OS, but only tested on Windows. There are differences in how an OS stores linebreaks in strings.

SCRIPT_NAME = "Paste text from clipboard to selected tracks names"

reaper.ClearConsole()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

-- Separate clipboard text into array
clipboardArray = {}
clipboard = reaper.CF_GetClipboard()

index = 0
while #clipboard > 0 do

  -- Find newline position
  newlineStart, newlineEnd = clipboard:find("\r\n") -- Windows style
  if newlineStart == nil then
    newlineStart, newlineEnd = clipboard:find("\n") -- Unix style
  end
  if newlineStart == nil then
    -- Set newline start and end to end of string
    newlinesStart = #clipboard
    newlineEnd = #clipboard
  end
  
  -- Extract substring
  clipboardArray[index] = clipboard:sub(0, newlineStart)
  
  -- Remove extracted string from clipboard string
  clipboard = clipboard:sub(newlineEnd + 1)
  
  index = index + 1
end

-- Get number of selected tracks
selNum = reaper.CountSelectedTracks(0)

-- Begin undo-block
reaper.Undo_BeginBlock2(0)

-- Loop through selected tracks
renameNum = 0
for i = 0, selNum-1 do
  -- Get track
  track = reaper.GetSelectedTrack(0, i)
  
  -- Set new name
  retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", clipboardArray[i], true)
  
  renameNum = i + 1
  
  if i >= #clipboardArray then
    break
  end
end

-- Notify how many tracks were renamed
str = renameNum .. " track(s) were renamed.\n"

-- Notify if any lines were left unused
if #clipboardArray > selNum then
  unusedNum = #clipboardArray - selNum + 1
  str = str .. "\n" .. unusedNum .. " lines were left unused.\n"
  for i = 0, unusedNum - 1 do
    str = str .. "\n" .. clipboardArray[selNum + i]
  end
end

reaper.ShowMessageBox(str, SCRIPT_NAME, 0)

-- End undo-block
reaper.Undo_EndBlock2(0,SCRIPT_NAME,-1)

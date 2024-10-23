-- @description Go To Timecode
-- @author AZ
-- @version 1.1
-- @changelog minor fixes for initial placement defining
-- @provides az_Go To Timecode/TimecodeInput_Module_AZ.lua
-- @about
--   # Go To Timecode
--
--   Fastest timecode jump ever
--
--   - New large interface
--   - Special timecode mode without frames value
--   - Beat and ruler modes
--   - Offset option for timecode mode
--   - Use +/- for relative jump
--   - Use spase to reset captured value
--
--   Thanks Claudiohbsantos for first version in code, which help me to figure out how to code it and how to improve.


-----------           --------------
----------- USER AREA --------------

cur_shift = -2 -- Value in seconds (-2 by default). Offset cursor early or later from typed value.
init_format = 5 -- H:M:S = 5; Beats = 2; Ruler = -1 (Look "parse_timestr_pos" API function describe)
------------------------------------
------------------------------------

function msg(s) reaper.ShowConsoleMsg(tostring(s)..'\n') end

function get_script_path()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  return script_path
end

function goToTimecode(inputInSeconds)
  reaper.SetEditCurPos2(0,inputInSeconds,true,false);
end

function onSuccessfulInput(inputInSeconds) 
  if inputInSeconds then
    goToTimecode(inputInSeconds + real_cur_shift)
  end
  
end

function prequire(...)
    local status, lib = pcall(require, ...)

    if (status) then return lib end
    --Library failed to load, so perhaps return `nil` or something?
    return nil
end

local script_path = get_script_path()
--local libraryPath = string.match(script_path,"(.*[\\/]).*[\\/]$").."Libraries/"
package.path = package.path .. ";" .. script_path  .."az_Go To Timecode/?.lua"
--package.path = package.path .. ";" .. libraryPath  .."Go To Time/?.lua"
requireStatus = prequire("TimecodeInput_Module_AZ")

if requireStatus then
  initGUI(235,"Go To Timecode")

  offset = tonumber(reaper.GetExtState( "GoToTimecode_AZ", "o"))
  --reaper.ShowConsoleMsg("found offset = "..offset.."\n")
  if not offset then
    offset = 1
  end
  
  if offset == 1 then
    real_cur_shift = cur_shift
  else
    real_cur_shift = 0
  end
  
  reaper.gmem_attach('GoToTimecode_AZ')

  reaper.gmem_write(1,init_format ) -- default parse_mode
  --parse_mode = reaper.gmem_read(1 )

  defaulTimeInSeconds = reaper.GetCursorPositionEx(0)
  runTimecodeInputBox()
  reaper.defer(function() end)
else
  reaper.ShowMessageBox("The script is missing the TimecodeInput_Module to function. Please reinstall this script from Reapack","Error: Library Missing",0)
end


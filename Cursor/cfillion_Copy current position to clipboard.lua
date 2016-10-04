-- @description Copy current cursor/playback position to clipboard
-- @version 1.0
-- @author cfillion

local FORMAT = -1

-- Possible formats:
-- -1=project default
--  0=time
--  1=measures.beats + time
--  2=measures.beats
--  3=seconds
--  4=samples
--  5=h:m:s:f

local function iswindows()
  return reaper.GetOS():find('Win') ~= nil
end

local function ismacos()
  return reaper.GetOS():find('OSX') ~= nil
end

local function copy(text)
  local tool

  if ismacos() then
    tool = 'pbcopy'
  elseif iswindows() then
    tool = 'clip'
  end

  local proc = assert(io.popen(tool, 'w'))
  proc:write(text)
  proc:close()
end

local function position()
  if reaper.GetPlayState() & 1 == 0 then
    return reaper.GetCursorPosition()
  else
    return reaper.GetPlayPosition2()
  end
end

copy(reaper.format_timestr_len(position(), '', 0, FORMAT))

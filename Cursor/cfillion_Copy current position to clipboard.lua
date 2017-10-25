-- @description Copy current cursor/playback position to clipboard
-- @version 1.0.2
-- @author cfillion
-- @changelog update to use my new cross-platform clipboard API function (SWS v2.9.5+)

local FORMAT = -1

-- Possible formats:
-- -1=project default
--  0=time
--  1=measures.beats + time
--  2=measures.beats
--  3=seconds
--  4=samples
--  5=h:m:s:f

local function position()
  if reaper.GetPlayState() & 1 == 0 then
    return reaper.GetCursorPosition()
  else
    return reaper.GetPlayPosition2()
  end
end

reaper.CF_SetClipboard(reaper.format_timestr_len(position(), '', 0, FORMAT))
reaper.defer(function() end) -- disable creation of undo point

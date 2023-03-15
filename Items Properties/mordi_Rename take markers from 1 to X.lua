-- @description Rename take markers from 1 to X
-- @author Mordi
-- @version 1.0
-- @screenshot Example https://i.imgur.com/38IPjtG.gif
-- @about
--   # Rename take markers from 1 to X
--
--   Useful for variations in sound effects that are consolidated into a single file. The will be named 1, 2, 3, etc. Overwrites any existing names.
--
--   Note that it does not work on WAV cues, only on take markers.

SCRIPT_NAME = "Rename take markers from 1 to X"

reaper.ClearConsole()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function GetSelectedItemsData()
  local t={}
  for i=1, reaper.CountSelectedMediaItems(0) do
    t[i] = {}
    local item = reaper.GetSelectedMediaItem(0, i-1)
    if item ~= nil then
      t[i].item = item
      t[i].pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      
      t[i].take = reaper.GetActiveTake(item)
      retval, t[i].name = reaper.GetSetMediaItemTakeInfo_String(t[i].take, "P_NAME", "", false)
    end
  end
  return t
end

data = GetSelectedItemsData()
if #data == 0 then return end

-- Begin undo-block
reaper.Undo_BeginBlock2(0)

for i=1, #data do
  takeNum = reaper.GetNumTakeMarkers(data[i].take)
  for n=0, takeNum-1 do
    time = reaper.GetTakeMarker(data[i].take, n)
    reaper.SetTakeMarker(data[i].take, n, tostring(1 + n))
  end
end

-- End undo-block
reaper.Undo_EndBlock2(0,SCRIPT_NAME,-1)

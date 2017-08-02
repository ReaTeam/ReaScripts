-- @description amagalma_Toggle active take volume envelope visible for all items in project
-- @author amagalma
-- @version 1.01
-- @about
--   # Toggles visibility of take volume envelopes for all takes of all items in project
--
--   - Equivalent to Start+Shift+Hyphen ("Show/hide Clip Gain Line") in Pro Tools
--   - Does not create undo points by default. Easily changeable in the end of the script.

--[[
 * Changelog:
 * v1.01 (2017-0-11)
  + fixed bug that would crop to active take when hiding empty envelope of first and active take in a multitake item
--]]


local reaper = reaper
local add = "<VOLENV\nACT 1\nVIS 1 1 1\nLANEHEIGHT 0 0\nARM 0\nDEFSHAPE 0 -1 -1\nPT 0 1 0\n>"
local remove = "<VOLENV\nACT 1\nVIS 1 1 1\nLANEHEIGHT 0 0\nARM 0\nDEFSHAPE 0 %-1 %-1\nPT 0 1 0\n>\n"


local function CreateItemVolEnv(item)
  local _, chunk = reaper.GetItemStateChunk(item, "", false)
  local add2 = ">\n"..add.."\n>"
  local newchunk = chunk:gsub(">\n>", add2, 1)
  if not string.match(chunk, "<VOLENV") then
    reaper.SetItemStateChunk(item, newchunk, false)
  end
end


local function RemoveItemVolEnv(item)
  local newchunk = string.gsub(chunk, remove, "")
  reaper.SetItemStateChunk(item, newchunk, false)
end


local function CreateActiveTakeVolEnv(item)
  local _, chunk = reaper.GetItemStateChunk(item, "", false)
  local add2 = "\n"..add
  local _, startafter = string.find(chunk, "TAKE SEL")  
  local point, _ = string.find(chunk, ">", startafter)
  local first = string.sub(chunk, 1, point)
  local second = string.sub(chunk, point+1)
  local newchunk = first..add2..second
  reaper.SetItemStateChunk(item, newchunk, false)
end


local function RemoveActiveTakeVolEnv(item)
  local startrem, endrem = string.find(chunk, remove, startafter)  
  local first = string.sub(chunk, 1, startrem-1)
  local second = string.sub(chunk, endrem+1)
  local newchunk = first..second
  startafter = nil
  reaper.SetItemStateChunk(item, newchunk, false)
end


local function HideTakeVolEnv(take)
  local VolEnv = reaper.GetTakeEnvelopeByName(take,"Volume")
  if VolEnv then
    local _, chunk = reaper.GetEnvelopeStateChunk(VolEnv, "")      
    local newchunk = string.gsub(chunk, "VIS 1", "VIS 0")
    reaper.SetEnvelopeStateChunk(VolEnv, newchunk, false)
  end
end


local function ShowTakeVolEnv(take)
  local VolEnv = reaper.GetTakeEnvelopeByName(take,"Volume")
  if VolEnv then
    local _, chunk = reaper.GetEnvelopeStateChunk(VolEnv, "")      
    local newchunk = string.gsub(chunk, "VIS 0", "VIS 1")
    reaper.SetEnvelopeStateChunk(VolEnv, newchunk, false)
  end
end


local function SaveSelectedItemsToTable(table)
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    table[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
end


local function RestoreSelectedItemsFromTable(table)
  for _, item in ipairs(table) do
   reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
  end
end


local function UnselectAllItems()
  while (reaper.CountSelectedMediaItems(0) > 0) do
    reaper.SetMediaItemSelected(reaper.GetSelectedMediaItem(0, 0), false)
  end
end


local function ToggleTakeVolEnvVisible()
  local show = 0
  local all_items = reaper.CountMediaItems(0)
  if all_items == 0 then goto donothing end
  if all_items > 0 then
  SaveSelectedItemsToTable(table)
  -- Find if any of the items has its vol env hidden
    for i = 0, all_items-1 do
      local item = reaper.GetMediaItem(0, i)
      local take = reaper.GetActiveTake(item)
      if take then
        local VolEnv = reaper.GetTakeEnvelopeByName(take, "Volume")
        if not VolEnv then
          show = 1
          goto dostuff
        else
          local _, chunk = reaper.GetEnvelopeStateChunk(VolEnv, "")
          local visible = string.match(chunk, "\nVIS (%d).-\n")
          if visible == "0" then
            show =1
            goto dostuff
          end   
        end
      end
    end
  end
  ::dostuff::
  for i = 0, all_items-1 do
    local item = reaper.GetMediaItem(0, i)
    local take_cnt = reaper.CountTakes(item)
    if take_cnt > 0 then
      active_take = reaper.GetActiveTake(item)
      for j = 0, take_cnt-1 do
        take = reaper.GetMediaItemTake(item, j)
        if take_cnt > 1 then reaper.SetActiveTake(take) end
        local VolEnv = reaper.GetTakeEnvelopeByName(take, "Volume")
        if not VolEnv then
          if show == 1 then 
            if take_cnt == 1 then CreateItemVolEnv(item)
            elseif take_cnt > 1 then CreateActiveTakeVolEnv(item)
            end
          end
        else
          if show == 1 then ShowTakeVolEnv(take)
          elseif show == 0 then 
            if take_cnt == 1 then
              _, chunk = reaper.GetItemStateChunk(item, "", false)
              if string.find(chunk, remove) then
                RemoveItemVolEnv(item)
                chunk = nil
              else
                HideTakeVolEnv(take)
              end
            elseif take_cnt > 1 then
              _, chunk = reaper.GetItemStateChunk(item, "", false)
              _, startafter = string.find(chunk, "TAKE SEL")
              _ = nil
              if not startafter then 
                startafter = string.find(chunk, ">\n<VOLENV")-10 
              end
              if string.find(chunk, remove, startafter) then
                RemoveActiveTakeVolEnv(item)
                chunk = nil
              else
                HideTakeVolEnv(take)
              end
            end
          end      
        end
      end
      reaper.SetActiveTake(active_take)
    end
  end
  RestoreSelectedItemsFromTable(table)
  ::donothing::
end

-- Uncomment undos if you want Undo points to be created
--reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
ToggleTakeVolEnvVisible()
reaper.PreventUIRefresh(-1)
--reaper.Undo_EndBlock("Toggle active take volume envelope visible", -1)
-- Comment the line below if you have uncommented the Undo lines
function NoUndoPoint() end ; reaper.defer(NoUndoPoint)

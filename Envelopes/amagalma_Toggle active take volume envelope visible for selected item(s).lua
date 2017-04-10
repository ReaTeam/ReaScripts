-- @description amagalma_Toggle active take volume envelope visible for selected item(s)
-- @author amagalma
-- @version 1.01
-- @about
--   # Toggles visibility of (active) take volume envelopes for the selected item(s)
--
--   - Does not create undo points by default. Easily changeable in the end of the script.

--[[
 * Changelog:
 * v1.01 (2017-04-10)
  + made the action substantially faster when many items (>500) are selected
--]]

local reaper = reaper
local add = "<VOLENV\nACT 1\nVIS 1 1 1\nLANEHEIGHT 0 0\nARM 0\nDEFSHAPE 0 -1 -1\nPT 0 1 0\n>"
local remove = "\n<VOLENV\nACT 1\nVIS 1 1 1\nLANEHEIGHT 0 0\nARM 0\nDEFSHAPE 0 %-1 %-1\nPT 0 1 0\n>"


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
  local first = string.sub(chunk, 1, startrem)
  local second = string.sub(chunk, endrem)
  local newchunk = first..second
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


local function ToggleTakeVolEnvVisible()
  local show = 0
  local sel_items = reaper.CountSelectedMediaItems(0)
  if sel_items == 0 then goto donothing end
  if sel_items > 0 then
  -- Find if any of the selected items has its vol env hidden
    for i = 0, sel_items-1 do
      local item = reaper.GetSelectedMediaItem(0, i)
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
  for i = 0, sel_items-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take_cnt = reaper.CountTakes(item)
    local take = reaper.GetActiveTake(item)
    if take then
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
            if string.find(chunk, remove) ~= nil then
              RemoveItemVolEnv(item)
              chunk = nil
            else
              HideTakeVolEnv(take)
            end
          elseif take_cnt > 1 then
            _, chunk = reaper.GetItemStateChunk(item, "", false)
            local _, startafter = string.find(chunk, "TAKE SEL")
            if string.find(chunk, remove, startafter) ~= nil then
              RemoveActiveTakeVolEnv(item)
              chunk = nil
            else
              HideTakeVolEnv(take)
            end
          end
        end      
      end
    end
  end
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

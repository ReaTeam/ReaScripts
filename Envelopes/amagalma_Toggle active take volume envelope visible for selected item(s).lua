-- @description amagalma_Toggle active take volume envelope visible for selected item(s)
-- @author amagalma
-- @version 2.01
-- @about
--   # Toggles visibility of (active) take volume envelopes for the selected item(s)
--
--   - Does not create undo points by default. Easily changeable in the end of the script.

--[[
 * Changelog:
 * v2.01 (2017-04-14)
  + small improvement
 * v2.0 (2017-04-14)
  + Complete re-write of the code. No more depending on buggy actions
 * v1.02 (2017-04-11)
  + fixed bug that would crop to active take when hiding empty envelope of first and active take in a multitake item
 * v1.01 (2017-04-10)
  + made the action substantially faster when many items (>500) are selected
--]]


local reaper = reaper

local function ToggleVisibility(item)
  local take_cnt = reaper.CountTakes(item)
  if take_cnt > 0 then
    local take = reaper.GetActiveTake(item)
    local act_take_guid = reaper.BR_GetMediaItemTakeGUID(take)
    local GetChunk = reaper.GetItemStateChunk    
    local _, chunk = GetChunk(item, "", true)
    local def_env = {"<VOLENV","ACT 1","VIS 1 1 1","LANEHEIGHT 0 0","ARM 0","DEFSHAPE 0 -1 -1","PT 0 1 0",">"}
    local t = {}
    local function helper(line) table.insert(t, line) return "" end
    helper((chunk:gsub("(.-)\r?\n", helper)))
    local found = 0
    for i in pairs(t) do
      if string.match(t[i], act_take_guid:gsub("-", "%%-")) then
        found = i ; break
      end
    end
    local VolEnvStart, defaultexists, VisLine, insert_here = 0, 1, 0, 0
    for i = found, #t do
      if t[i]:match("TAKE") or (t[i] == ">" and t[i-1] == ">") then 
        insert_here = i ; defaultexists = 0 break -- No Volume Envelope exists for the active take
      end
      if t[i]:match("<VOLENV") then VolEnvStart = i break end -- Volume Envelope exists
    end
    if VolEnvStart > 0 then
      for j = 1, #def_env do -- Check if existing Volume envelope is the default
        if j ~= 6 then -- We don't care if DEFSHAPE matches
          if not t[VolEnvStart+j-1]:find(def_env[j]) then defaultexists = 0 end
        end
        if string.match(t[VolEnvStart+j-1], "VIS %d 1 1") then VisLine = VolEnvStart+j-1 end
      end
    end
    if insert_here ~= 0 then -- VolEnv does not exist, so create default
      for i = #def_env, 1, -1 do
        table.insert(t, insert_here, def_env[i])
      end
    else -- VolEnv exists
      if defaultexists == 0 then -- Toggle visibility
        t[VisLine] = t[VisLine]:gsub("(VIS%s)(%d)", function(a,b) return a .. (b~1) end)
      else -- Remove Default envelope
        for i = 1, #def_env do
          table.remove(t, VolEnvStart)
        end
      end
    end
    local SetChunk = reaper.SetItemStateChunk
    SetChunk(item, table.concat(t, "\n"), true) -- Write the table to the item chunk
  end
end


local function Main()
  local sel_items = reaper.CountSelectedMediaItems(0)
  if sel_items > 0 then
    for i = 0, sel_items-1 do
      local item = reaper.GetSelectedMediaItem(0, i)
      ToggleVisibility(item)
    end
  end
end


-- Uncomment undos if you want Undo points to be created
--reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.PreventUIRefresh(-1)
--reaper.Undo_EndBlock("Toggle active take volume envelope visible", -1)
-- Comment the line below if you have uncommented the Undo lines
function NoUndoPoint() end ; reaper.defer(NoUndoPoint)

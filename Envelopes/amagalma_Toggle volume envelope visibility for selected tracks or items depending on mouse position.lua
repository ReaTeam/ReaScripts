-- @description Toggle volume envelope visibility for selected tracks/items depending on mouse position
-- @author amagalma
-- @version 1.002
-- @about
--   # Toggles volume envelope visibility for the selected tracks or items
--
--   - If mouse is over Arrange, then it toggles selected items' volume envelopes' visibility
--   - If mouse is over TCP, then it toggles selected tracks' volume envelopes' visibility
--   - Undo point is created if needed and is named accordingly

--[[
 * Changelog:
 * v1.002 (2018-07-30)
  + fixed avoiding to create undo when no tracks or no items are selected
--]]

------------------------------------------------------------------------------------------------

local reaper = reaper
local done

------------------------------------------------------------------------------------------------

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
        if def_env[j] ~= (t[VolEnvStart+j-1]) then defaultexists = 0 end
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
    reaper.SetItemStateChunk(item, table.concat(t, "\n"), true) -- Write table to item chunk
  end
end

------------------------------------------------------------------------------------------------

local function SetItemTakeVolEnvVis()
  local sel_items = reaper.CountSelectedMediaItems(0)
  if sel_items > 0 then
    reaper.PreventUIRefresh( 1 )
    for i = 0, sel_items-1 do
      local item = reaper.GetSelectedMediaItem(0, i)
      ToggleVisibility(item)
    end
    reaper.PreventUIRefresh( -1 )
    done = "items"
  end
end

------------------------------------------------------------------------------------------------

-- get details for stuff under mouse cursor
local window, segment, details = reaper.BR_GetMouseCursorContext()

-- If mouse is over TCP, toggle volume envelope for selected tracks
if string.match(window, "tcp") and reaper.CountSelectedTracks2( 0, true) > 0 then
  reaper.Main_OnCommand(40406, 0) -- Track: Toggle track volume envelope visible
  done = "tracks"
-- If mouse is over Arrange, toggle volume envelope for selected items
elseif string.match(window, "arrange") then
  SetItemTakeVolEnvVis()
end

-- Undo point creation -------------------------------------------------------------------------

if done == "tracks" then
  reaper.Undo_OnStateChangeEx2( 0, "Toggle sel tracks volume envelope visibility", 1, -1 )
elseif done == "items" then
  reaper.Undo_OnStateChangeEx2( 0, "Toggle sel items volume envelope visibility", 1|4, -1 )
else
  local function NoUndoPoint() end 
  reaper.defer(NoUndoPoint)
end

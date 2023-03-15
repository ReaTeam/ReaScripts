-- @description Toggle volume envelope visibility for selected tracks/items depending on mouse position or last context
-- @author amagalma
-- @version 1.2
-- @changelog
--   - Re-design of toggle code
--   - Fixed: working with MIDI items
--   - Fixed: working when there are other envelopes
--   - Added: If mouse is not over Arrange or TCP then it works according to last context
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Toggles volume envelope visibility for the selected tracks or items
--
--   - If mouse is over Arrange, then it toggles selected items' volume envelopes' visibility
--   - If mouse is over TCP, then it toggles selected tracks' volume envelopes' visibility
--   - If mouse is elsewhere it toggles according to last context
--   - Undo point is created if needed and is named accordingly

------------------------------------------------------------------------------------------------

local done

local function ToggleVisibility(item)
  local take_cnt = reaper.CountTakes(item)
  if take_cnt > 0 then
    local take = reaper.GetActiveTake(item)
    local act_take_guid = reaper.BR_GetMediaItemTakeGUID(take)
    local _, chunk = reaper.GetItemStateChunk(item, "", true)
    local t = {}
    local l = 0
    local equilibrium = 0
    local activate_equilibrium = false
    local foundTake = false
    local record = true
    local insert = 0
    local search_source, search_sm, search_takefx, search_newpdc = true, false, false, false
    local vol_env_found = false
    local vol_points = 0
    local vol_end = 0
    local visLine = 0
    local defaultEnv = false
    for line in chunk:gmatch("[^\n]+") do
      l = l + 1
      t[l] = line
      if not foundTake then
        if line:find(act_take_guid:gsub("-", "%%-") .. "$") then
          foundTake = l
        end
      end
      if record and foundTake then
        if search_source and line:find("^<SOURCE") then
          activate_equilibrium = true
        end
        if search_sm and line:find("^SM ") then
          insert = l
          search_sm = false
        end
        if search_takefx and line:find("^<TAKEFX") then
          search_sm = false
          activate_equilibrium = true
        end
        if search_newpdc and line:find("^TAKE_FX_") then
          insert = l
          search_newpdc = false
        end
        if not vol_env_found and not search_source then
          if line == "<VOLENV" then
            insert = l - 1
            search_sm, search_takefx, search_newpdc = false, false, false
            vol_env_found = true
            vol_points = reaper.CountEnvelopePoints( reaper.GetTakeEnvelopeByName( take, "Volume" ) )
            activate_equilibrium = true
          elseif line == "<PANENV" or line == "<MUTEENV" or line == "<PITCHENV" then
            insert = l - 1
            record = false
          end
        end
        if activate_equilibrium then
          if line:find("^<") then
            equilibrium = equilibrium + 1
          elseif line == ">" then
            equilibrium = equilibrium - 1
          end
          if vol_env_found then
            if visLine == 0 and line:find("^V") then
              visLine = l
            elseif vol_points == 1 and not defaultEnv and line == "PT 0 1 0" then
              defaultEnv = true
            end
          end
          if equilibrium == 0 then
            activate_equilibrium = false
            if search_source then
              search_source = false
              search_sm, search_takefx = true, true
              insert = l
            elseif search_takefx then
              search_takefx = false
              search_newpdc = true
              insert = l
            elseif vol_env_found then
              vol_end = l
              record = false
            end
          end
        end
        if line == "TAKE" or line == "TAKE SEL" then
          record = false
        end
      end
    end
    if vol_env_found then
      if defaultEnv then
        chunk = table.concat(t, "\n", 1, insert) .. "\n" .. table.concat(t, "\n", vol_end+1)
      else
        t[visLine] = t[visLine]:gsub("VIS (%d)", function(a) return "VIS " .. (a~1) end)
        chunk =  table.concat(t, "\n")
      end
    else
      chunk = table.concat(t, "\n", 1, insert) ..
      "\n<VOLENV\nACT 1\nVIS 1 1 1\nLANEHEIGHT 0 0\nARM 0\nDEFSHAPE 0 -1 -1\nPT 0 1 0\n>\n" ..
      table.concat(t, "\n", insert+1)
    end
    reaper.SetItemStateChunk(item, chunk, true)
    done = "items"
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
  end
end

------------------------------------------------------------------------------------------------

-- get details for stuff under mouse cursor or last context
local window, segment, details = reaper.BR_GetMouseCursorContext()

-- If mouse is over TCP, toggle volume envelope for selected tracks
if string.match(window, "tcp") and reaper.CountSelectedTracks2( 0, true) > 0 then
  reaper.Main_OnCommand(40406, 0) -- Track: Toggle track volume envelope visible
  done = "tracks"
-- If mouse is over Arrange, toggle volume envelope for selected items
elseif string.match(window, "arrange") then
  SetItemTakeVolEnvVis()
else
  context = reaper.GetCursorContext2( true )
  if context ~= 1 then
    reaper.Main_OnCommand(40406, 0) -- Track: Toggle track volume envelope visible
  else
    SetItemTakeVolEnvVis()
  end
end

-- Undo point creation -------------------------------------------------------------------------

if done == "tracks" then
  reaper.Undo_OnStateChangeEx2( 0, "Toggle sel tracks volume envelope visibility", 1, -1 )
elseif done == "items" then
  reaper.Undo_OnStateChangeEx2( 0, "Toggle sel items volume envelope visibility", 1|4, -1 )
else
  reaper.defer( function() end )
end

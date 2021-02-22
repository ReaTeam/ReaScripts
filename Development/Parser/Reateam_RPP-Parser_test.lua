--[[
 * ReaScript Name: RPP Parser Test
 * Author: X-Raym
 * Repository: ReaTeam/RPP-Parser
 * Licence: GPL v3
 * REAPER: 5.0
 * Version: 1.0
--]]

function Msg( val )
  if reaper.ShowConsoleMsg then
    reaper.ShowConsoleMsg(tostring(val).."\n") -- if called from REAPER
  else
    print( val ) -- if called from console
  end
end

script = "Reateam_RPP-Parser.lua" -- Parser file relative path.

-- Get Script Path
script_folder = debug.getinfo(1).source:match("@?(.*[\\|/])")
script_path = script_folder .. script -- This can be erased if you prefer enter absolute path value above.

dofile( script_path )

if reaper then
  -- Run the Script
  if reaper.file_exists( script_path ) then
    dofile( script_path )
  else
    reaper.MB("Missing parent script.\n" .. script_path, "Error", 0)
    return
  end

  reaper.ClearConsole()
end

-- TEST CODE 1 --------------------
-- Parse an existing .rpp file ---

--[[
path = script_folder .. "INPUT.rpp" -- Path to your initial .rpp
root = ReadRPP(path) -- Parse the RPP
--]]

-- TEST CODE 2 --------------------
-- Generate a rpp from scratch ----

root = CreateRPP() -- Create the root

local index = 0
tracks={}
for j = 1, 5 do
  local track = AddRChunk(root, {"TRACK"}) -- Add track
  table.insert(tracks, track)
  local name = AddRNode(track, {"NAME", j}) -- Add track name
  for i = 1, 1 do
    index = index + 1
    local item = AddRChunk(track, {"ITEM"}) -- Add item
    local position = AddRNode(item, {"POSITION", i-1}) -- Add item position
    local length = AddRNode(item, {"LENGTH", "1"}) -- Add length
    local notes = AddRChunk(item, {"NOTES"}) -- Add notes
    notes:setTextNotes("This is a multiline text.\nOr is it?")
    local notes_text = notes:getTextNotes()
  end
end

-- Copy a node
-- tracks[6] = tracks[5]:copy()

-- Remove a node
-- tracks[5] = tracks[4]:remove()


-- WRITE CODE ------------------
local time_a = reaper.time_precise()

output_path = script_folder .. "OUTPUT.rpp"
output_retval, output_message = WriteRPP(output_path, root)

local time_b = reaper.time_precise()
benchmark = time_b - time_a
Msg("benchmark: " .. benchmark .. "s")

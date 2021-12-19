-- @description Replace string in marker and region names
-- @author Mordi
-- @version 1.0
-- @changelog Initial release.
-- @about After pressing "Ok", a dialog appears with a list of all affected markers/regions, which lets you cancel if need be.

SCRIPT_NAME = "Replace string in marker and region names"

reaper.ClearConsole()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

reaper.Undo_BeginBlock()

-- Get input
retval, retvals_csv = reaper.GetUserInputs(SCRIPT_NAME, 2, "Find,Replace with,extrawidth=100", "")

-- Validate input
if retval == false then
  return
end

_, commaCount = retvals_csv:gsub(",", ",")
if commaCount > 1 then
  reaper.ShowMessageBox("Unfortunately, commas are not supported by this script...", SCRIPT_NAME, 0)
  return
end

if retvals_csv:sub(0, 1) == "," then
  reaper.ShowMessageBox("This script won't work if the 'Find' field is empty.", SCRIPT_NAME, 0)
  return
end

-- Separate values
commaPos = retvals_csv:find(",")
findStr = retvals_csv:sub(0, commaPos - 1)
replacementStr = retvals_csv:sub(commaPos + 1, #retvals_csv)

-- Get markers and regions
retval, marker_count, rgn_count = reaper.CountProjectMarkers(0)

if marker_count + rgn_count == 0 then
  reaper.ShowMessageBox("No markers or regions found.", SCRIPT_NAME, 0)
  return
end

listStr = ""
oldNames = {}
newNames = {}
markerIndexes = {}
rgnends = {}
positions = {}
isrgns = {}

index = 0

-- Loop through, get name and replace
for i = 0, marker_count+rgn_count-1 do
  retval, isrgn, pos, rgnend, name, markrgnindexnumber, col = reaper.EnumProjectMarkers3(0, i)
  newName, occurrences = name:gsub(findStr, replacementStr)
  if (occurrences > 0) then
    
    oldNames[index] = name
    newNames[index] = newName
    markerIndexes[index] = markrgnindexnumber
    rgnends[index] = rgnend
    positions[index] = pos
    isrgns[index] = isrgn
    
    
    index = index + 1
    listStr = listStr .. "\n" .. name .. " = " .. newName
  end
end

-- Check if any names matched
if index == 0 then
  reaper.ShowMessageBox("No matches for '" .. findStr .. "'", SCRIPT_NAME, 0)
  return
end

-- Check if user wants to move forward with renaming
retval = reaper.ShowMessageBox(index .. " markers and regions will be renamed. Okay?\n" .. listStr, SCRIPT_NAME, 4)

-- Apply new names
if retval == 6 then
  for i = 0, #markerIndexes do
    reaper.SetProjectMarker(markerIndexes[i], isrgns[i], positions[i], rgnends[i], newNames[i])
  end
end

reaper.Undo_EndBlock(SCRIPT_NAME, 0)

-- @description amagalma_Find action or script name by its Command ID
-- @author amagalma
-- @version 1.0
-- @about
--   # Returns the action/script name of the given ID
--   - Script gets information from ActionList.txt created by SWS/S&M: Dump action list (all but custom actions)
--   - The script calls this action to create the said file.
--   - You can run this script as many times as you want without the need to create ActionList.txt for two hours.
--   - If ActionList.txt is older than two hours then you are prompted to update it

-------------------------------------------------------------------------------------

local reaper = reaper
local path = reaper.GetResourcePath()
local separ = string.match(reaper.GetOS(), "Win") and "\\" or "/"
local version = reaper.GetAppVersion()
local ok = false
local lines = {}
local time = os.time()
local found = false
local retry = false 

-------------------------------------------------------------------------------------

function createActionList()
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_DUMP_CUST_ACTION_LIST"), 0)
  local file = io.open (path .. separ .. "ActionList.txt")
  for line in file:lines() do
    lines[#lines+1] = line
  end
  file:close()
  local temp = io.open('temp.txt', 'w')
  temp:write("version: " .. version .. "  time: " .. time .. "\n")
  for _, line in ipairs(lines) do
    temp:write(line.."\n")
  end
  temp:close()
  os.remove("ActionList.txt")
  os.rename('temp.txt', "ActionList.txt")
  ok = true
end

-------------------------------------------------------------------------------------

::START::
local file = io.open (path .. separ .. "ActionList.txt")
if not file then
  -- create file and save in it the current version number
  if retry ~= true then
    reaper.MB( "For this action to work, a file named ActionList.txt must exist in your Reaper.exe's path. This file currently does not exist, therefore it will be created (this will be done only once). Just click 'Save' at the next dialog without changing anything. Thanks!", "Requirements..", 0 )
  end
  createActionList()
else
  -- check if it has updated info (check against current version)
  for line in file:lines() do
    lines[#lines+1] = line
  end
  file:close()
  if lines[1]:match(version) and os.time() - lines[1]:match("time: (%d+)") < 7200 then
    ok = true
  else
    lines = nil
    lines = {}
    os.remove("ActionList.txt")
    reaper.MB( "For best results, your ActionList.txt must get updated. Please, press Enter/Return as many times as required. Thanks!", "Update..", 0)
    createActionList()
  end
end
if ok then
  local ok2, id = reaper.GetUserInputs( "Find name of action/script by its Command ID", 1, "Enter Command ID: , extrawidth=120", "")
  if ok2 then
    id = id:match("^%s*(.-)%s*$") -- strip spaces
    for i = 3, #lines do
      if lines[i]:find("\t"..id.."\t") then
        local Section, Id, Action = lines[i]:match("(.+)\t(.+)\t(.+)")
        reaper.MB( Action .. "\n\nSection: " .. Section .. "\n\n(name copied to clipboard)", "Action name is:", 0 )
        reaper.CF_SetClipboard( Action )
        found = true
        --break
      end
    end
    if not found then
      local ok3 = reaper.MB("Could not match the given ID to an action/script present in your action list. Perhaps you mistyped or the ActionList.txt is outdated.\nDo you want to update your ActionList.txt and retry?", "Not found! Update and retry?", 4)
      if ok3 == 6 then
        lines = nil
        lines = {}
        time = os.time()
        os.remove(path .. separ .. "ActionList.txt")
        retry = true
        goto START
      end
    end
  end
end
reaper.defer(function () end )

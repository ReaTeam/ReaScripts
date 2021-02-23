-- @description Display all referenced media files in all projects residing in a folder path
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showthread.php?t=249852
-- @donation https://www.paypal.me/amagalma
-- @about
--   Displays a list with all the media files that are referenced in all the rpp and rpp-bak files that reside in the same user chosen folder.
--
--   Displays the number of projects found, the number of media files found, the number of total references for each media file and the number of projects that this media file is referenced in.
--
--   - Requires JS_ReaScriptAPI and RPP-Parser


dofile(reaper.GetResourcePath() ..
[[\Scripts\ReaTeam Scripts\Development\RPP-Parser\Reateam_RPP-Parser.lua]])
if not RChunk then return end

-- Get default rec path and browse for look-up folder
local folder
do
  local file = io.open( reaper.get_ini_file() )
  local content = file:read"*all"
  file:close()
  local path = content:match("\ndefrecpath=(.-)\n")
  path = path and path .. "\\" or ""
  local retval, fold = reaper.JS_Dialog_BrowseForFolder( "Choose folder:", path )
  if retval ~= 1 or not fold or fold == "" then
    return
  else
    folder = fold
  end
end

-- Find all rpp and rpp-bak in folder
local projects = {}
local projects_cnt = 0
do
  local i = 0
  while true do
    local project = reaper.EnumerateFiles( folder, i )
    if not project then
      break
    else
      if project:match("%.rpp%-?b?a?k?$") then
        projects_cnt = projects_cnt + 1
        projects[projects_cnt] = project
      end
      i = i + 1
    end
  end
end

if projects_cnt == 0 then
  reaper.ShowConsoleMsg("No .rpp or .rpp-bak files in this folder!\n")
  return
end

-- Registry of found files
local files, file_cnt = {}, 0
local registry = {}
local longest_str = 0

local function RegisterFile(name, new_record)
  if not registry[name] then
    registry[name] = {1, 1}
    file_cnt = file_cnt + 1
    files[file_cnt] = name
    local str_len = #name
    if str_len > longest_str then
      longest_str = str_len
    end
  else
    if new_record then
      registry[name][2] = registry[name][2] + 1
    end
    registry[name][1] = registry[name][1] + 1
  end
end

reaper.ClearConsole()

-- Find files
for p = 1, projects_cnt do
  local proj_path = folder .. "\\" .. projects[p]
  local root = ReadRPP(proj_path)
  if root then
    local new_record = true
    reaper.ShowConsoleMsg("Parsing " .. proj_path .. "\n")
    local tracks = root:findAllChunksByName("TRACK")
    if tracks then
      for tr = 1, #tracks do
        local items = tracks[tr]:findAllChunksByName("ITEM")
        if items then
          for i = 1, #items do
            local sources = items[i]:findAllChunksByName("SOURCE")
            if sources then
              for s = 1, #sources do
                local node = sources[s]:findFirstNodeByName("FILE")
                if node then 
                  local name = node:getToken(2).token
                  if name:match('^.:[\\/]') then
                    RegisterFile(name, new_record)
                  else
                    RegisterFile(folder .. name, new_record)
                  end
                  new_record = false
                end
              end
            end
            local sources_alt = items[i]:findAllChunksByName("SRCFN")
            if sources_alt then
              for s = 1, #sources_alt do
                local node = sources_alt[s]:findFirstNodeByName("FILE")
                if node then
                  local name = node:getToken(2).token
                  if name:match("$.:[\\/]") then
                    RegisterFile(name, new_record)
                  else
                    RegisterFile(folder .. name, new_record)
                  end
                  new_record = false
                end
              end
            end
          end
        end
      end
    end
  end
end

-- Display stats
reaper.ClearConsole()
local log, l = {}, 0
reaper.ShowConsoleMsg("========================== REPORT ==========================\n\n")
if #files > 0 then
  reaper.ShowConsoleMsg(#files .. ' referenced media files in ' .. projects_cnt ..
  ' projects in "' .. folder .. '" :\n\n')
  longest_str = longest_str + 3
  for f = 1, file_cnt do
    local space = longest_str-#files[f]
    space = (" "):rep(space)
    local plural = registry[files[f]][1] > 1 and "s" or ""
    local plural2 = registry[files[f]][2] > 1 and "s" or ""
    local space2 = plural == "s" and "" or " "
    l = l + 1
    log[l] = string.format("  %03i) %s%s%5i reference%s %sin %3i file%s\n",
    f, files[f], space, registry[files[f]][1], plural, space2, registry[files[f]][2], plural2)
  end
  reaper.ShowConsoleMsg(table.concat(log))
else
  reaper.ShowConsoleMsg("No media files referenced in " .. projects_cnt .. " projects!\n")
end
reaper.ShowConsoleMsg("\n====================== END OF REPORT =======================\n\n")

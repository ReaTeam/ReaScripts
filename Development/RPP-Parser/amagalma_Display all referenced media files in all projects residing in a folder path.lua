-- @description Display all referenced media files in all projects residing in a folder path
-- @author amagalma
-- @version 1.1
-- @changelog
--   - Fix for OSX/Linux
--   - Searches in all sub-folders of the set folder
--   - Better report (displays all projects that each media file is referenced in)
--   - Files/paths that are no more available are denoted with double asterisks (**)
-- @link https://forum.cockos.com/showthread.php?t=249852
-- @donation https://www.paypal.me/amagalma
-- @about
--   Displays a list with all the media files that are referenced in all the rpp and rpp-bak files that reside in the same user chosen folder (searches ALL sub-folders of folder).
--
--   Displays the number of projects found, the number of media files found, the number of total references for each media file and a list of the projects that each media file is referenced in. Files/paths that are no more available are denoted with double asterisks (**).
--
--   - Requires JS_ReaScriptAPI and RPP-Parser


dofile(reaper.GetResourcePath() ..
[[\Scripts\ReaTeam Scripts\Development\RPP-Parser\Reateam_RPP-Parser.lua]])
if not RChunk then return end

local sep = package.config:sub(1,1) -- OS separator

-- Get default rec path and browse for look-up folder
local folder
do
  local _, path = reaper.BR_Win32_GetPrivateProfileString( "reaper", "defrecpath", "", reaper.get_ini_file() )
  path = path ~= "" and path .. sep or ""
  local retval, fold = reaper.JS_Dialog_BrowseForFolder( "Choose folder:", path )
  if retval ~= 1 or not fold or fold == "" then
    return reaper.defer(function() end )
  else
    folder = fold
  end
end

local function GetAllProjectFiles(dir, files)
  -- based on functions by FeedTheCat
  local files = files or {}
  local sub_dirs = {}
  local sub_dirs_cnt = 0
  repeat
    local sub_dir = reaper.EnumerateSubdirectories(dir, sub_dirs_cnt)
    if sub_dir then
      sub_dirs_cnt = sub_dirs_cnt + 1
      sub_dirs[sub_dirs_cnt] = dir .. sep .. sub_dir
    end
  until not sub_dir
  for dir = 1, sub_dirs_cnt do
    GetAllProjectFiles(sub_dirs[dir], files)
  end

  local file_cnt = #files
  local i = 0
  repeat
    local file = reaper.EnumerateFiles(dir, i)
    if file then
      i = i + 1
      if file:match("%.[Rr][Pp]+%-?[Bb]?[Aa]?[Kk]?$") then
        file_cnt = file_cnt + 1
        files[file_cnt] = dir .. sep .. file
      end
    end
  until not file
  return files, file_cnt
end


-- Find all rpp and rpp-bak in folder
local projects, projects_cnt = GetAllProjectFiles( folder )

if projects_cnt == 0 then
  reaper.ShowConsoleMsg("No .rpp or .rpp-bak files in this folder!\n")
  return reaper.defer(function() end )
end

-- Registry of found files
local files, file_cnt = {}, 0
local registry = {}
local longest_str = 0

local function RegisterFile(name, new_record, index)
  if not registry[name] then
    registry[name] = {1, {index}}
    file_cnt = file_cnt + 1
    files[file_cnt] = name
    local str_len = #name
    if str_len > longest_str then
      longest_str = str_len
    end
  else
    if new_record then
      registry[name][2][#registry[name][2]+1] = index
    end
    registry[name][1] = registry[name][1] + 1
  end
end

reaper.ClearConsole()

-- Find files
for p = 1, projects_cnt do
  local root = ReadRPP(projects[p])

  if root then
    local new_record = true
    reaper.ShowConsoleMsg("Parsing " .. projects[p] .. "  (" .. p .. ")\n")
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
                    RegisterFile(name, new_record, p)
                  else
                    RegisterFile(folder .. sep .. name, new_record, p)
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
                    RegisterFile(name, new_record, p)
                  else
                    RegisterFile(folder .. sep .. name, new_record, p)
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
local log, l = {}, 0
reaper.ShowConsoleMsg("\n\n========================== REPORT ==========================\n\n")
if #files > 0 then
  local avail = true
  reaper.ShowConsoleMsg(#files .. ' referenced media files in ' .. projects_cnt ..
  ' projects in "' .. folder .. '" :\n\n')
  longest_str = longest_str + 3
  for f = 1, file_cnt do
    local space = longest_str-#files[f]
    space = (" "):rep(space)
    local plural = registry[files[f]][1] > 1 and "s" or ""
    local plural2 = #registry[files[f]][2] > 1 and "s" or ""
    local space2 = plural == "s" and "" or " "
    local exist = reaper.file_exists(files[f]) and "  " or "**"
    if avail and exist == "**" then
      avail = false
    end
    l = l + 1
    log[l] = string.format("%s%03i) %s%s%5i reference%s %sin file%s:  %s\n", exist,
    f, files[f], space, registry[files[f]][1], plural, space2, plural2, table.concat(registry[files[f]][2], ", "))
  end
  if not avail then
    log[l+1] = "\n\n**: File or path no more available!\n"
  end
  reaper.ShowConsoleMsg(table.concat(log))
else
  reaper.ShowConsoleMsg("No media files referenced in " .. projects_cnt .. " projects!\n")
end
reaper.ShowConsoleMsg("\n====================== END OF REPORT =======================\n\n")

reaper.defer(function() end)

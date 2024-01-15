-- @description ReaLauncher
-- @author solger
-- @version 2.5.4
-- @changelog
--   + General: Changed the default double click behavior setting for new installs from 'Show prompt' to 'Load'
--   + Project Lists: Bugfix to consider file extensions in both upper and lower case when accessing files (.rpl and .RPL) 
--   + Tabs: Bugfix for using the mousewheel to scroll through the tabs
--   + UI: Improvements in the display of some label texts
-- @screenshot https://forum.cockos.com/showthread.php?t=208697
-- @about
--   # ReaLauncher
--
--   A custom version of the startup prompt window for loading (recent) projects, project/track templates and more. With a bunch of additional features.
--
--   Uses 'Lokasenna's GUI library v2 for Lua' as base: https://forum.cockos.com/showthread.php?t=177772. Big thanks to Lokasenna for his work!!
--
--   ## Main features
--     - Separate tabs for [Recent Projects], (.rpp) [Project Templates], (.rtracktemplate) [Track Templates], (.rpp) [Projects], (.rpl) [Project Lists], (.rpp-bak) [Backups] and (.pdf) [Docs]
--     - Option to set custom folder paths for [Project Templates] and [Track Templates] - which are scanned in addition to the default template folder locations
--     - Option to set custom folder paths for the [Projects], [Project Lists], [Backups] and [Docs] tabs
--     - List filter in each tab that supports the use of multiple search words separated by a 'space' character
--     - File paths can be shown/hidden and also displayed optionally in the status bar
--     - Sorting options
--     - [Favorites] tab to list and manage bookmarked favorites of each tab
--     - [Follow Actions] tab to set Actions that are triggered after certain operations (New Tab, Load Project, etc.)
--     - Global functions accessible via main button panel or context menu: [Open Project], [New Project], [New Tab], [Load in Tab], [Load] and [Insert]
--     - Selection and loading of multiple entries at once (multi-select via mouse is already part of Lokasenna's GUI library)
--     - 'Keep open' checkbox to toggle the automatic window closing behavior after Load/New/Insert operations
--     - Different tab selector styles (Tabstrip or Dropdown)
--     - Scalable and resizeable window
--     - Customizable colors
--
--   ## Features that require SWS Extensions (2.9.8 or higher):
--     - [Recent Projects] tab for listing and managing recent project entries (with functions to remove selected entries and to clear the entire list)
--     - 'Last Active' project functions to check for and load last active project tabs
--     - [Locate in Explorer/Finder] button to navigate to the location(s) of selected files in Explorer or Finder
--     - [Docs] tab for listing .pdf files
--     - Setup of predefined Reaper Theme Slots and the possibility to switch between them (uses SWS Resources)
--
--   ## Features that require js_ReaScriptAPI (0.991 or higher):
--     - Function to preview attached 'demo' audio files (supported file extensions: .wav, .flac, .mp3 and .ogg)
--     - Option for adding folder paths in the [Options] tab via a 'Browse' dialog (besides copy & pasting paths manually)
--     - Additional sorting options by date
--
--   ## Discussion thread
--
--   https://forum.cockos.com/showthread.php?t=208697

----------------------------------------------------------------------------------------------------
local ConfigFlags = {
----------------------------------------------------------------------------------------------------
  showDebugMessages = false,          -- enables/disables console debug messages      (true | false)
  listFilesInDebugMessages = false,   -- list scanned files in debug messages         (true | false)
----------------------------------------------------------------------------------------------------
  enableAutoRefresh = true,           -- enables/disables automatic tab refresh       (true | false)
  setfirstTabToLoad = 0,              -- the id of the tab to focus at launch          (0 = default)
  resetFiltersAtLaunch = false,       -- reset filter entries in all tabs at launch   (true | false)
  resetListDisplayAtLaunch = false,   -- reset date and paths display at launch       (true | false)
----------------------------------------------------------------------------------------------------
  enableFileCaching = true,           -- enables/disables file caching                (true | false)
  enableSubfolderCaching = true,      -- enables/disables subfolder caching           (true | false)
  enableEmptySubfolderFilter = true,  -- enables/disables subfolder filter            (true | false)
----------------------------------------------------------------------------------------------------
  enableAudioPreview = true,          -- enables/disables audio preview               (true | false)
  enableCustomColorOptions = true,    -- enables/disables custom color options        (true | false)
  enableHiDPIModeOptions = true,      -- enables/disables HiDPI mode options          (true | false)
  enableKeyShortcuts = true,          -- enables/disables key shortcuts               (true | false) 
  enableSortModeOptions = true        -- enables/disables sort mode options           (true | false)
----------------------------------------------------------------------------------------------------
}
----------------------------------------------------------------------------------------------------
-- Loading Lokasenna's GUI library v2
-------------------------------------
local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
  if not reaper.file_exists(lib_path .. "Core.lua") or not lib_path or lib_path == "" then
    reaper.MB("Couldn't load Lokasenna_GUI library.\n\n1) Please install 'Lokasenna's GUI library v2 for Lua' via ReaPack\n\n2) Then run the 'Set Lokasenna_GUI v2 library path.lua' script in the Action List", "Whoops!", 0)
  return
end

loadfile(lib_path .. "Core.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Frame.lua")()
GUI.req("Classes/Class - Knob.lua")()
GUI.req("Classes/Class - Label.lua")()
GUI.req("Classes/Class - Listbox.lua")()
GUI.req("Classes/Class - Menubox.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Tabs.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Window.lua")()
if missing_lib then return 0 end

--------------------------
-- String Helper functions
--------------------------
local function MsgDebug(str)
  if ConfigFlags.showDebugMessages then reaper.ShowConsoleMsg("\t" .. tostring(str) .. "\n") end
end

local function MsgStatusBar(message)
  if message ~= nil then
    GUI.Val("main_statusbar", message)
    GUI.elms.main_statusbar:fade(8, 1, 30)
  end
end

------------------------------------------
-- Reaper resource paths and version infos
------------------------------------------
appname = "solger_ReaLauncher"

osversion = reaper.GetOS()
MsgDebug("OS:\t\t\t" .. osversion)
local reaperVersionString = reaper.GetAppVersion()
MsgDebug("Reaper:\t\t\t" .. reaperVersionString)
if reaperVersionString:match("x64") then
  bitversion = string.sub(reaperVersionString, #reaperVersionString - 2, #reaperVersionString)
  reaperversion = string.sub(reaperVersionString, 1, #reaperVersionString - (reaperVersionString:reverse()):find("%/"))
else
  bitversion = "x86"
  reaperversion = reaperVersionString
end

resourcePath = reaper.GetResourcePath()
if resourcePath == nil then reaper.MB(tostring("Could not retrieve the Reaper resource path!"), "Error", 0)
else MsgDebug("Resource path:\t\t" .. resourcePath) end

reaperIniPath = reaper.get_ini_file()
MsgDebug("Reaper ini:\t\t" .. reaperIniPath)

if osversion:find("Win") then
  trackTemplatePath = resourcePath .. "\\TrackTemplates"
  projectTemplatePath = resourcePath .. "\\ProjectTemplates"
  pathSeparator = "\\"
else
  trackTemplatePath = resourcePath .. "/TrackTemplates"
  projectTemplatePath = resourcePath .. "/ProjectTemplates"
  pathSeparator = "/"
end

MsgDebug("Lokasenna_GUI:\t\t" .. (GUI.version or "v2.x"))

---------------------
-- File I/O functions
---------------------
local FileTypes = {
  backup = ".rpp-bak",
  docs = ".pdf",
  rpl = ".rpl",
  rpp = ".rpp",
  tracktemplate = ".rtracktemplate"
}

local function GetFolderName(filepath)
  local index = (filepath:reverse()):find("%\\") or (filepath:reverse()):find("%/")
  if index ~= nil then return string.sub(filepath, (#filepath - index) + 2, #filepath)
  else return filepath end
end

local function IsNotNullOrEmpty(str)
  return str ~= nil and str ~= ""
end

-------------------
-- Extensions check
--------------------
local function CheckForSWS()
    if reaper.APIExists("BR_Win32_GetPrivateProfileString") then
      if reaper.CF_GetSWSVersion == nil then MsgDebug("SWS:\t\t\tolder than v2.10")
      else MsgDebug("SWS:\t\t\tv" .. reaper.CF_GetSWSVersion(swsversion)) end
      return true
    else
      MsgDebug("SWS:\t\t\t not found")
      return false
    end
end

local function CheckForJSAPI()
  local jsapifile
    if osversion:find("Win") and bitversion == "x64" then jsapifile = "UserPlugins/reaper_js_ReaScriptAPI64.dll" -- Windows 64-bit
      elseif osversion:find("Win") then jsapifile = "UserPlugins/reaper_js_ReaScriptAPI32.dll" -- Windows 32-bit
      elseif osversion:find("arm") then jsapifile = "UserPlugins/reaper_js_ReaScriptAPI64ARM.dylib" -- macOS ARM
      elseif osversion:find("OSX") then jsapifile = "UserPlugins/reaper_js_ReaScriptAPI64.dylib" -- macOS
      else jsapifile = "UserPlugins/reaper_js_ReaScriptAPI64.so" -- Linux
  end

  if not reaper.ReaPack_GetOwner or not reaper.file_exists(resourcePath .. pathSeparator .. jsapifile) then
    MsgDebug("JS_ReascriptAPI:\t\t not found")
  else
    local owner = reaper.ReaPack_GetOwner(jsapifile)
    if owner then
      MsgDebug("JS_ReascriptAPI:\t\tv" .. ({reaper.ReaPack_GetEntryInfo(owner)})[7])
      reaper.ReaPack_FreeEntry(owner)
      return true
    end
  end
  return false
end

local SWSinstalled = CheckForSWS()
local JSAPIinstalled = CheckForJSAPI()

-------------------
-- Helper functions
-------------------
function RL_Benchmark_Start(function_name, ...)
  MsgDebug("Benchmark start")
  benchmarkStart = reaper.time_precise()
end

function RL_Benchmark_Stop()
  MsgDebug("Benchmark end - Execution time:" .. reaper.time_precise() - benchmarkStart)
end

local function CheckForDuplicates(table, value)
  for i = 1, #table do
    if table[i] == value then return true end
  end
  return false
end

local function JoinTables(t1, t2)
  for k, v in ipairs(t2) do t1[#t1 + 1] = v end
  return t1
end

local function GetSelectionTable(selected)
  if type(selected) == "number" then selected = {[selected] = true} end
  local selectedVals = {}
  for k, v in pairs(selected) do selectedVals[#selectedVals + 1] = k end
  return selectedVals
end

local function GetSubTableByNameKey(table)
  local subTable = {}
  for i = 1, #table do subTable[i] = table[i].name end
  return subTable
end

local function GetSubTableByPathKey(table)
  local subTable = {}
  for i = 1, #table do subTable[i] = table[i].path end
  return subTable
end

----------------------------------------------------------------------------------------------
-- Enumerate all (sub-)directories and files of a given path
-- Adapted versions of code snippets found in the Reaper forum. Thanks to mpl and Lokasenna :)
----------------------------------------------------------------------------------------------
local function GetFileExtension(fileName, charLength)
  return string.lower(string.sub(fileName, #fileName - charLength, #fileName))
end

local function GetFilenameWithoutPath(filepath)
  if osversion:find("Win") then return filepath:match("([^\\]-([^.]+))$") -- Windows: get (fileName.extension) substring
  else
    local index = (filepath:reverse()):find("%/") -- macOS / Linux
    if index ~= nil then return string.sub(filepath, (#filepath - index) + 2, #filepath)
    else return filepath end
  end
end

local function GetFiles(path, folderExclusionIndex, fileExtensionFilter, pathChildIndex)
  local tree = {}
  local pathChild
  local subDirIndex, fileIndex = 0, 0
  
  if pathChildIndex == nil then pathChildIndex = 0 end
  if path ~= nil then
    repeat -- get files in subfolders
      if CheckFileScanMaxDirCount(folderExclusionIndex, subDirIndex) then 
        pathChild = reaper.EnumerateSubdirectories(path, subDirIndex)
        if pathChild and not IsExcludedFolder(folderExclusionIndex, pathChild) then
          pathChildIndex = pathChildIndex + 1
          if CheckFileScanMaxDirDepth(folderExclusionIndex, pathChildIndex) then 
            local tmpPath = GetFiles(path .. pathSeparator .. pathChild, folderExclusionIndex, fileExtensionFilter, pathChildIndex)
            for i = 1, #tmpPath do
              if GetFileExtension(GetFilenameWithoutPath(tmpPath[i]), #fileExtensionFilter - 1) == fileExtensionFilter then tree[#tree + 1] = tmpPath[i] end
            end
          end
        end
        subDirIndex = subDirIndex + 1
        pathChildIndex = 0
      else
        pathChild = nil
      end
    until not pathChild

    repeat -- get files in parent folder
      local fileFound = reaper.EnumerateFiles(path, fileIndex)
        if fileFound and GetFileExtension(fileFound, #fileExtensionFilter - 1) == fileExtensionFilter then
          tree[#tree + 1] = path .. pathSeparator .. fileFound
        end
        fileIndex = fileIndex + 1
    until not fileFound
  end

  return tree
end

local function RemoveExtension(fileName, fileType)
  if fileName == nil then return "" else return string.sub(fileName, 1, #fileName - #fileType) end
end

local function RemoveWhiteSpaces(s)
  if s ~= nil then return s:match("^%s*(.-)%s*$") end
end

local function GetDirectoryPath(filepath)
  if filepath == nil then return "" end
  local index = (filepath:reverse()):find("%/") -- macOS / Linux
  if osversion:find("Win") then index = (filepath:reverse()):find("%\\") end -- Windows
  if index == nil then return ""
  else return string.sub(filepath, 1, #filepath - index) end
end

local function FolderContainsRelevantFiles(path, extensionFilter)
  if not ConfigFlags.enableEmptySubfolderFilter then return true end
  local currentFiles = GetFiles(path, 0, extensionFilter)
  local relevantFiles = {}
  for c = 1, #currentFiles do relevantFiles[#relevantFiles + 1] = currentFiles[c] end
  if relevantFiles == nil or #relevantFiles == 0 then return false else return true end
end

local function GetSubFolders(path, folderExclusionIndex, extensionFilter)
  local subDirTree, subDirFiles = {}, {}
  local subDirIndex, dirIndex = 0, 0
  local subDirChild
  
  if pathChildIndex == nil then pathChildIndex = 0 end
  if path ~= nil then
    repeat
      if CheckFileScanMaxDirCount(folderExclusionIndex, subDirIndex) then 
        subDirChild = reaper.EnumerateSubdirectories(path, subDirIndex)
        if subDirChild and not IsExcludedFolder(folderExclusionIndex, subDirChild) then
          pathChildIndex = pathChildIndex + 1
          if CheckFileScanMaxDirDepth(folderExclusionIndex, pathChildIndex) then 
            local tmpPath, _ = GetSubFolders(path .. pathSeparator .. subDirChild, folderExclusionIndex, extensionFilter)
              for i = 1, #tmpPath do
                subDirTree[#subDirTree + 1] = tmpPath[i]
                subDirFiles[#subDirFiles + 1] = RL.subfolderIndent .. GetFolderName(tmpPath[i])
              end
            end
        end
        subDirIndex = subDirIndex + 1
        pathChildIndex = 0
      else
       subDirChild = nil
      end
    until not subDirChild

    repeat
      local subfolderFound = reaper.EnumerateSubdirectories(path, dirIndex)
        if subfolderFound and not IsExcludedFolder(folderExclusionIndex, subfolderFound) then
          if FolderContainsRelevantFiles(path .. pathSeparator .. subfolderFound, extensionFilter) then
            subDirTree[#subDirTree + 1] = path .. pathSeparator .. subfolderFound
            subDirFiles[#subDirFiles + 1] = RL.subfolderIndent .. subfolderFound
          end
        end
        dirIndex = dirIndex + 1
    until not subfolderFound
  end

  return subDirTree, subDirFiles
end

local function SplitMultiPaths(pathString)
  local pathTable = {}
  pathString:gsub("[^;]*", function(p) pathTable[#pathTable + 1] = p:match("^%s*(.-)%s*$") end)
  return pathTable
end

function IsExcludedFolder(exclusionIndex, folderName)
  local folderExlusionTable
  if exclusionIndex == TabID.ProjectTemplates then folderExlusionTable = FileScanExclusions.ProjectTemplates
  elseif exclusionIndex == TabID.TrackTemplates then folderExlusionTable = FileScanExclusions.TrackTemplates
  elseif exclusionIndex == TabID.CustomProjects then folderExlusionTable = FileScanExclusions.CustomProjects
  elseif exclusionIndex == TabID.ProjectLists then folderExlusionTable = FileScanExclusions.ProjectLists
  elseif exclusionIndex == TabID.Backups then folderExlusionTable = FileScanExclusions.Backups
  elseif exclusionIndex == TabID.Docs then folderExlusionTable = FileScanExclusions.Docs end
  
  if folderExlusionTable == nil then return false end
  for e = 1, #folderExlusionTable do if folderName == folderExlusionTable[e] then return true end end
  return false
end

function CheckFileScanMaxDirCount(exclusionIndex, subDirIndex)
  local scanMaxDirCount = 0
  if exclusionIndex == TabID.ProjectTemplates then scanMaxDirCount = FileScanSettings.projectTemplates_maxSubDirRange
  elseif exclusionIndex == TabID.TrackTemplates then scanMaxDirCount = FileScanSettings.trackTemplates_maxSubDirRange
  elseif exclusionIndex == TabID.CustomProjects then scanMaxDirCount = FileScanSettings.projects_maxSubDirRange
  elseif exclusionIndex == TabID.ProjectLists then scanMaxDirCount = FileScanSettings.projectLists_maxSubDirRange
  elseif exclusionIndex == TabID.Backups then scanMaxDirCount = FileScanSettings.backups_maxSubDirRange
  elseif exclusionIndex == TabID.Docs then scanMaxDirCount = FileScanSettings.docs_maxSubDirRange end

  if scanMaxDirCount == 0 or (scanMaxDirCount > 0 and subDirIndex < scanMaxDirCount) then return true else return false end
end

function CheckFileScanMaxDirDepth(exclusionIndex, pathChildIndex)
  local scanMaxDirDepth = 0
  if exclusionIndex == TabID.ProjectTemplates then scanMaxDirDepth = FileScanSettings.projectTemplates_maxSubDirDepth
  elseif exclusionIndex == TabID.TrackTemplates then scanMaxDirDepth = FileScanSettings.trackTemplates_maxSubDirDepth
  elseif exclusionIndex == TabID.CustomProjects then scanMaxDirDepth = FileScanSettings.projects_maxSubDirDepth
  elseif exclusionIndex == TabID.ProjectLists then scanMaxDirDepth = FileScanSettings.projectLists_maxSubDirDepth
  elseif exclusionIndex == TabID.Backups then scanMaxDirDepth = FileScanSettings.backups_maxSubDirDepth
  elseif exclusionIndex == TabID.Docs then scanMaxDirDepth = FileScanSettings.docs_maxSubDirDepth end

  if scanMaxDirDepth == 0 or (scanMaxDirDepth > 0 and pathChildIndex < scanMaxDirDepth) then return true else return false end
end

local function GetSubListSize()
  if GUI.elms.main_tabs.state == TabID.ProjectTemplates then return #GUI.elms.tab_projectTemplates_subfolders.list
    elseif GUI.elms.main_tabs.state == TabID.TrackTemplates then return #GUI.elms.tab_trackTemplates_subfolders.list
    elseif GUI.elms.main_tabs.state == TabID.CustomProjects then return #GUI.elms.tab_customProjects_subfolders.list
    elseif GUI.elms.main_tabs.state == TabID.ProjectLists and GUI.elms.tab_projectLists_listboxRPL then return #GUI.elms.tab_projectLists_listboxRPL.list
    elseif GUI.elms.main_tabs.state == TabID.ProjectLists and not GUI.elms.tab_projectLists_listboxRPL then return 0
    elseif GUI.elms.main_tabs.state == TabID.Backups then return #GUI.elms.tab_backups_subfolders.list
    elseif GUI.elms.main_tabs.state == TabID.Docs then return #GUI.elms.tab_docs_subfolders.list
    elseif GUI.elms.main_tabs.state == TabID.Favorites then return #GUI.elms.tab_favorites_categories.list
  end
end

local function GetMainListSize()
  if GUI.elms.main_tabs.state == TabID.RecentProjects then return #GUI.elms.tab_recentProjects_listbox.list
    elseif GUI.elms.main_tabs.state == TabID.ProjectTemplates then return #GUI.elms.tab_projectTemplates_listbox.list
    elseif GUI.elms.main_tabs.state == TabID.TrackTemplates then return #GUI.elms.tab_trackTemplates_listbox.list
    elseif GUI.elms.main_tabs.state == TabID.CustomProjects then return #GUI.elms.tab_customProjects_listbox.list
    elseif GUI.elms.main_tabs.state == TabID.ProjectLists then return #GUI.elms.tab_projectLists_listboxProjects.list
    elseif GUI.elms.main_tabs.state == TabID.Backups then return #GUI.elms.tab_backups_listbox.list
    elseif GUI.elms.main_tabs.state == TabID.Docs then return #GUI.elms.tab_docs_listbox.list
    elseif GUI.elms.main_tabs.state == TabID.Favorites then return #GUI.elms.tab_favorites_listbox.list
  end
end

local function ShowFileCount()
  local fileCount = GetMainListSize()
  if fileCount ~= nil then MsgStatusBar("Files: " .. fileCount) end
end

local function GetLastModifiedDate(filePath)
  if JSAPIinstalled then
    -- retval, size, accessedTime, modifiedTime, cTime, deviceID, deviceSpecialID, inode, mode, numLinks, ownerUserID, ownerGroupID
    retval, _, _, modifiedTime, _, _, _, _, _, _, _, _ = reaper.JS_File_Stat(filePath)
    if retval == 0 then return modifiedTime else return "" end
  else
    return ""
  end
end

----------------------------
-- Locate in Explorer/Finder
----------------------------
local function ShowLocation_RecentProject()
  if GetMainListSize() > 0 then
  local vals = GetSelectionTable(GUI.Val("tab_recentProjects_listbox"))
  if #vals == 0 then MsgStatusBar("No files selected in list")
    else
      for p = 1, #vals do
        if FilterActive.RecentProjects then reaper.CF_LocateInExplorer(RecentProjects.filteredItems[vals[p]].path) 
        else reaper.CF_LocateInExplorer(RecentProjects.items[vals[p]].path) end
      end
    end
  end
end

local function ShowLocation_ProjectTemplates()
  if GetMainListSize() > 0 then
    local vals = GetSelectionTable(GUI.Val("tab_projectTemplates_listbox"))
    if #vals == 0 then reaper.CF_LocateInExplorer(projectTemplatePath)
    else
     for p = 1, #vals do
        if FilterActive.ProjectTemplates then reaper.CF_LocateInExplorer(ProjectTemplates.filteredItems[vals[p]].path)
        else reaper.CF_LocateInExplorer(ProjectTemplates.items[vals[p]].path) end
      end
    end
  end
end

local function ShowLocation_TrackTemplates()
  if GetMainListSize() > 0 then
    local vals = GetSelectionTable(GUI.Val("tab_trackTemplates_listbox"))
    if #vals == 0 then reaper.CF_LocateInExplorer(trackTemplatePath)
    else
      for p = 1, #vals do
        if FilterActive.TrackTemplates then reaper.CF_LocateInExplorer(TrackTemplates.filteredItems[vals[p]].path)
        else reaper.CF_LocateInExplorer(TrackTemplates.items[vals[p]].path) end
      end
    end
  end
end

local function ShowLocation_CustomProject()
  if GetMainListSize() > 0 then
    local vals = GetSelectionTable(GUI.Val("tab_customProjects_listbox"))
    if #vals == 0 then
      if GUI.Val("paths_txtCustomProjectsPath") == "" then MsgStatusBar("No files selected in list")
      else reaper.CF_LocateInExplorer(GUI.Val("paths_txtCustomProjectsPath")) end
    else
      for p = 1, #vals do
        if FilterActive.CustomProjects then reaper.CF_LocateInExplorer(CustomProjects.filteredItems[vals[p]].path)
        else reaper.CF_LocateInExplorer(CustomProjects.items[vals[p]].path) end
      end
    end
  end
end

local function ShowLocation_ProjectList()
  if GetMainListSize() > 0 then
    local vals = GetSelectionTable(GUI.Val("tab_projectLists_listboxProjects"))
    if #vals == 0 then
      if GUI.Val("paths_txtProjectsListsPath") == "" then MsgStatusBar("No files selected in list")
      else reaper.CF_LocateInExplorer(GUI.Val("paths_txtProjectsListsPath")) end
    else
      for p = 1, #vals do
        if FilterActive.ProjectLists then reaper.CF_LocateInExplorer(ProjectLists.filteredProjectItems[vals[p]].path)
        else reaper.CF_LocateInExplorer(ProjectLists.projectItems[vals[p]].path) end
      end
    end
  end
end

local function ShowLocation_Backups()
  if GetMainListSize() > 0 then
    local vals = GetSelectionTable(GUI.Val("tab_backups_listbox"))
    if #vals == 0 then
      if GUI.Val("paths_txtBackupsPath") == "" then MsgStatusBar("No files selected in list")
      else reaper.CF_LocateInExplorer(GUI.Val("paths_txtBackupsPath")) end
    else
      for p = 1, #vals do
        if FilterActive.Backups then reaper.CF_LocateInExplorer(Backups.filteredItems[vals[p]].path)
        else reaper.CF_LocateInExplorer(Backups.items[vals[p]].path) end
      end
    end
  end
end

local function ShowLocation_Docs()
  if GetMainListSize() > 0 then
    local vals = GetSelectionTable(GUI.Val("tab_docs_listbox"))
    if #vals == 0 then
      if GUI.Val("paths_txtDocsPath") == "" then MsgStatusBar("No files selected in list")
      else reaper.CF_LocateInExplorer(GUI.Val("paths_txtDocsPath")) end
    else
      for p = 1, #vals do
        if FilterActive.Docs then reaper.CF_LocateInExplorer(Docs.filteredItems[vals[p]].path)
        else reaper.CF_LocateInExplorer(Docs.items[vals[p]].path) end
      end
    end
  end
end

local function ShowLocation_Favorites()
  if GetMainListSize() > 0 then
    local vals = GetSelectionTable(GUI.Val("tab_favorites_listbox"))
    if #vals == 0 then MsgStatusBar("No files selected in list")
    else
      for p = 1, #vals do
        if FilterActive.Favorites then reaper.CF_LocateInExplorer(Favorites.filteredItems[vals[p]].path)
        else reaper.CF_LocateInExplorer(Favorites.items[vals[p]].path) end
      end
    end
  end
end

local function Global_OpenInExplorer()
  if SWSinstalled then
    if GUI.elms.main_tabs.state == TabID.RecentProjects then ShowLocation_RecentProject()
      elseif GUI.elms.main_tabs.state == TabID.ProjectTemplates then ShowLocation_ProjectTemplates()
      elseif GUI.elms.main_tabs.state == TabID.TrackTemplates then ShowLocation_TrackTemplates()
      elseif GUI.elms.main_tabs.state == TabID.CustomProjects then ShowLocation_CustomProject()
      elseif GUI.elms.main_tabs.state == TabID.ProjectLists then ShowLocation_ProjectList()
      elseif GUI.elms.main_tabs.state == TabID.Backups then ShowLocation_Backups()
      elseif GUI.elms.main_tabs.state == TabID.Docs then ShowLocation_Docs()
      elseif GUI.elms.main_tabs.state == TabID.Favorites then ShowLocation_Favorites()
    end
  end
end

-----------------------------
-- Path Display and Tab Focus
-----------------------------
function ShowSubfolderPanel(tabIndex)
  if tabIndex > 1 then return RL.activeSubPanels[tabIndex - 1] else return false end
end

local function Global_UpdateSubfolderPathDisplay()
    if not RL.showSubFolderPaths then
      if GUI.elms.main_tabs.state == TabID.ProjectTemplates and ShowSubfolderPanel(TabID.ProjectTemplates) then GUI.elms.tab_projectTemplates_subfolders.list = SubfolderNames.projectTemplates
      elseif GUI.elms.main_tabs.state == TabID.TrackTemplates and ShowSubfolderPanel(TabID.TrackTemplates) then GUI.elms.tab_trackTemplates_subfolders.list = SubfolderNames.trackTemplates
      elseif GUI.elms.main_tabs.state == TabID.CustomProjects and ShowSubfolderPanel(TabID.CustomProjects) then GUI.elms.tab_customProjects_subfolders.list = SubfolderNames.customProjects
      elseif GUI.elms.main_tabs.state == TabID.ProjectLists and ShowSubfolderPanel(TabID.ProjectLists) then GUI.elms.tab_projectLists_listboxRPL.list = ProjectLists.rplFiles
      elseif GUI.elms.main_tabs.state == TabID.Backups and ShowSubfolderPanel(TabID.Backups) then GUI.elms.tab_backups_subfolders.list = SubfolderNames.backups
      elseif GUI.elms.main_tabs.state == TabID.Docs and ShowSubfolderPanel(TabID.Docs) then GUI.elms.tab_docs_subfolders.list = SubfolderNames.docs
      end
    else
      if GUI.elms.main_tabs.state == TabID.ProjectTemplates and ShowSubfolderPanel(TabID.ProjectTemplates) then GUI.elms.tab_projectTemplates_subfolders.list = SubfolderPaths.projectTemplates
        elseif GUI.elms.main_tabs.state == TabID.TrackTemplates and ShowSubfolderPanel(TabID.TrackTemplates) then GUI.elms.tab_trackTemplates_subfolders.list = SubfolderPaths.trackTemplates
        elseif GUI.elms.main_tabs.state == TabID.CustomProjects and ShowSubfolderPanel(TabID.CustomProjects) then GUI.elms.tab_customProjects_subfolders.list = SubfolderPaths.customProjects
        elseif GUI.elms.main_tabs.state == TabID.ProjectLists and ShowSubfolderPanel(TabID.ProjectLists) then GUI.elms.tab_projectLists_listboxRPL.list = ProjectLists.rplPaths
        elseif GUI.elms.main_tabs.state == TabID.Backups and ShowSubfolderPanel(TabID.Backups) then GUI.elms.tab_backups_subfolders.list = SubfolderPaths.backups
        elseif GUI.elms.main_tabs.state == TabID.Docs and ShowSubfolderPanel(TabID.Docs) then GUI.elms.tab_docs_subfolders.list = SubfolderPaths.docs
      end
    end

    if GUI.elms.main_tabs.state == TabID.ProjectTemplates and ShowSubfolderPanel(TabID.ProjectTemplates) then GUI.elms.tab_projectTemplates_subfolders:redraw()
      elseif GUI.elms.main_tabs.state == TabID.TrackTemplates and ShowSubfolderPanel(TabID.TrackTemplates) then GUI.elms.tab_trackTemplates_subfolders:redraw()
      elseif GUI.elms.main_tabs.state == TabID.CustomProjects and ShowSubfolderPanel(TabID.CustomProjects) then GUI.elms.tab_customProjects_subfolders:redraw()
      elseif GUI.elms.main_tabs.state == TabID.ProjectLists and ShowSubfolderPanel(TabID.ProjectLists) then GUI.elms.tab_projectLists_listboxRPL:redraw()
      elseif GUI.elms.main_tabs.state == TabID.Backups and ShowSubfolderPanel(TabID.Backups) then GUI.elms.tab_backups_subfolders:redraw()
      elseif GUI.elms.main_tabs.state == TabID.Docs and ShowSubfolderPanel(TabID.Docs) then GUI.elms.tab_docs_subfolders:redraw()
    end
end

local function RL_SetFocusedTab(tabIndex)
  if tabIndex == nil or tabIndex > TabID.Layout then tabIndex = 1 end
  GUI.Val("main_tabs", tabIndex)
  if RL.tabSelectorStyle == 2 then GUI.Val("main_menuTabSelector", tabIndex) end 

  if tabIndex == TabID.Options and TabSelectionIndex[TabID.Options] > 1 then
    Global_ShowOptionsTab()
    return
  end
  
  GUI.Val("main_checklistSaveAsNewVersion", {false})
  GUI.Val("tab_favorites_checklistSaveAsNewVersion", {false})
  RL.projectTemplateLoadMode, RL.saveAsNewVersionMode = 1, 0

  MsgStatusBar("")
  GUI.elms.main_statusbar.tooltip = ""

  if ConfigFlags.enableSortModeOptions then
    if JSAPIinstalled then 
      if tabIndex == TabID.RecentProjects or tabIndex == TabID.ProjectLists then GUI.elms.main_sortMode.optarray = { "First", "Last", "A - Z", "Z - A", "Newest", "Oldest" }
      else GUI.elms.main_sortMode.optarray = { "A - Z", "Z - A", "Newest", "Oldest" } end
    else
      if tabIndex == TabID.RecentProjects or tabIndex == TabID.ProjectLists then GUI.elms.main_sortMode.optarray = { "First", "Last", "A - Z", "Z - A" }
      else GUI.elms.main_sortMode.optarray = { "A - Z", "Z - A" } end
    end
    GUI.Val("main_sortMode", RL.sortModeIndex[GUI.elms.main_tabs.state] or 1)
  end

  RL.forceRescan = false
  if ConfigFlags.enableAutoRefresh and not RL.skipOperationOnResize and not RL.showLastActiveProjects and tabIndex <= TabID.Favorites then
    for i = 1, #ListBoxElements do ListBoxElements[i].list = {} end
    RL_Func_TabRefresh[tabIndex].call()
    Global_UpdateListDisplay()
    Global_UpdateFilter()
    Global_UpdateSortMode()
    Global_UpdateSubfolderPathDisplay()
  end

  reaper.SetExtState(appname, "window_tabfocus", GUI.elms.main_tabs.state, 1)
end

---------------
-- List display
---------------
local function UpdateListDisplay_RecentProjects()
  if RL.showFullPaths then 
    if FilterActive.RecentProjects then
      if RL.showDate then for i = 1, #RecentProjects.filteredItems do RecentProjects.filteredDisplay[i] = RecentProjects.filteredItems[i].date .. " | " .. RecentProjects.filteredItems[i].path end
      else for i = 1, #RecentProjects.filteredItems do RecentProjects.filteredDisplay[i] = RecentProjects.filteredItems[i].path end end
    else
      if RL.showDate then for i = 1, #RecentProjects.items do RecentProjects.display[i] = RecentProjects.items[i].date .. " | " .. RecentProjects.items[i].path end
      else for i = 1, #RecentProjects.items do RecentProjects.display[i] = RecentProjects.items[i].path end end
    end 
  else
    if FilterActive.RecentProjects then
      if RL.showDate then for i = 1, #RecentProjects.filteredItems do RecentProjects.filteredDisplay[i] = RecentProjects.filteredItems[i].date .. " | " .. RecentProjects.filteredItems[i].name end
      else for i = 1, #RecentProjects.filteredItems do RecentProjects.filteredDisplay[i] = RecentProjects.filteredItems[i].name end end
    else
      if RL.showDate then for i = 1, #RecentProjects.items do RecentProjects.display[i] = RecentProjects.items[i].date .. " | " .. RecentProjects.items[i].name end
      else for i = 1, #RecentProjects.items do RecentProjects.display[i] = RecentProjects.items[i].name end end
    end
  end
  if FilterActive.RecentProjects then GUI.elms.tab_recentProjects_listbox.list = RecentProjects.filteredDisplay else GUI.elms.tab_recentProjects_listbox.list = RecentProjects.display end
  GUI.elms.tab_recentProjects_listbox:redraw()
end

local function UpdateListDisplay_ProjectTemplates()
  if RL.showFullPaths then 
    if FilterActive.ProjectTemplates then
      if RL.showDate then for i = 1, #ProjectTemplates.filteredItems do ProjectTemplates.filteredDisplay[i] = ProjectTemplates.filteredItems[i].date .. " | " .. ProjectTemplates.filteredItems[i].path end 
      else for i = 1, #ProjectTemplates.filteredItems do ProjectTemplates.filteredDisplay[i] = ProjectTemplates.filteredItems[i].path end end
    else
      if RL.showDate then for i = 1, #ProjectTemplates.items do ProjectTemplates.display[i] = ProjectTemplates.items[i].date .. " | " .. ProjectTemplates.items[i].path end
      else for i = 1, #ProjectTemplates.items do ProjectTemplates.display[i] = ProjectTemplates.items[i].path end end
    end
  else
    if FilterActive.ProjectTemplates then
      if RL.showDate then for i = 1, #ProjectTemplates.filteredItems do ProjectTemplates.filteredDisplay[i] = ProjectTemplates.filteredItems[i].date .. " | " .. ProjectTemplates.filteredItems[i].name end
      else for i = 1, #ProjectTemplates.filteredItems do ProjectTemplates.filteredDisplay[i] = ProjectTemplates.filteredItems[i].name end end
    else
      if RL.showDate then for i = 1, #ProjectTemplates.items do ProjectTemplates.display[i] = ProjectTemplates.items[i].date .. " | " .. ProjectTemplates.items[i].name end
      else for i = 1, #ProjectTemplates.items do ProjectTemplates.display[i] = ProjectTemplates.items[i].name end end
    end
  end
  if FilterActive.ProjectTemplates then GUI.elms.tab_projectTemplates_listbox.list = ProjectTemplates.filteredDisplay else GUI.elms.tab_projectTemplates_listbox.list = ProjectTemplates.display end
  GUI.elms.tab_projectTemplates_listbox:redraw()
end

local function UpdateListDisplay_TrackTemplates()
  if RL.showFullPaths then
    if FilterActive.TrackTemplates then
      if RL.showDate then for i = 1, #TrackTemplates.filteredItems do TrackTemplates.filteredDisplay[i] = TrackTemplates.filteredItems[i].date .. " | " .. TrackTemplates.filteredItems[i].path end 
      else for i = 1, #TrackTemplates.filteredItems do TrackTemplates.filteredDisplay[i] = TrackTemplates.filteredItems[i].path end end
    else
      if RL.showDate then for i = 1, #TrackTemplates.items do TrackTemplates.display[i] = TrackTemplates.items[i].date .. " | " .. TrackTemplates.items[i].path end 
      else for i = 1, #TrackTemplates.items do TrackTemplates.display[i] = TrackTemplates.items[i].path end end
    end
  else
    if FilterActive.TrackTemplates then
      if RL.showDate then for i = 1, #TrackTemplates.filteredItems do TrackTemplates.filteredDisplay[i] = TrackTemplates.filteredItems[i].date .. " | " .. TrackTemplates.filteredItems[i].name end 
      else for i = 1, #TrackTemplates.filteredItems do TrackTemplates.filteredDisplay[i] = TrackTemplates.filteredItems[i].name end end
    else
      if RL.showDate then for i = 1, #TrackTemplates.items do TrackTemplates.display[i] = TrackTemplates.items[i].date .. " | " .. TrackTemplates.items[i].name end 
      else for i = 1, #TrackTemplates.items do TrackTemplates.display[i] = TrackTemplates.items[i].name end end
    end
  end
  if FilterActive.TrackTemplates then GUI.elms.tab_trackTemplates_listbox.list = TrackTemplates.filteredDisplay else GUI.elms.tab_trackTemplates_listbox.list = TrackTemplates.display end
  GUI.elms.tab_trackTemplates_listbox:redraw()
end

local function UpdateListDisplay_CustomProjects()
  if RL.showFullPaths then
    if FilterActive.CustomProjects then
      if RL.showDate then for i = 1, #CustomProjects.filteredItems do CustomProjects.filteredDisplay[i] = CustomProjects.filteredItems[i].date .. " | " .. CustomProjects.filteredItems[i].path end
      else for i = 1, #CustomProjects.filteredItems do CustomProjects.filteredDisplay[i] = CustomProjects.filteredItems[i].path end end
    else
      if RL.showDate then for i = 1, #CustomProjects.items do CustomProjects.display[i] = CustomProjects.items[i].date .. " | " .. CustomProjects.items[i].path end
      else for i = 1, #CustomProjects.items do CustomProjects.display[i] = CustomProjects.items[i].path end end
    end
  else
    if FilterActive.CustomProjects then
      if RL.showDate then for i = 1, #CustomProjects.filteredItems do CustomProjects.filteredDisplay[i] = CustomProjects.filteredItems[i].date .. " | " .. CustomProjects.filteredItems[i].name end
      else for i = 1, #CustomProjects.filteredItems do CustomProjects.filteredDisplay[i] = CustomProjects.filteredItems[i].name end end
    else
      if RL.showDate then for i = 1, #CustomProjects.items do CustomProjects.display[i] = CustomProjects.items[i].date .. " | " .. CustomProjects.items[i].name end
      else for i = 1, #CustomProjects.items do CustomProjects.display[i] = CustomProjects.items[i].name end end
    end
  end
  if FilterActive.CustomProjects then GUI.elms.tab_customProjects_listbox.list = CustomProjects.filteredDisplay else GUI.elms.tab_customProjects_listbox.list = CustomProjects.display end
  GUI.elms.tab_customProjects_listbox:redraw()
end

local function UpdateListDisplay_ProjectLists()
  if RL.showFullPaths then
    if FilterActive.ProjectLists then
      if RL.showDate then for i = 1, #ProjectLists.filteredProjectItems do ProjectLists.filteredDisplay[i] = ProjectLists.filteredProjectItems[i].date .. " | " .. ProjectLists.filteredProjectItems[i].path end
      else for i = 1, #ProjectLists.filteredProjectItems do ProjectLists.filteredDisplay[i] = ProjectLists.filteredProjectItems[i].path end end
    else
      if RL.showDate then for i = 1, #ProjectLists.projectItems do ProjectLists.display[i] = ProjectLists.projectItems[i].date .. " | " .. ProjectLists.projectItems[i].path end
      else for i = 1, #ProjectLists.projectItems do ProjectLists.display[i] = ProjectLists.projectItems[i].path end end
    end
  else
    if FilterActive.ProjectLists then
      if RL.showDate then for i = 1, #ProjectLists.filteredProjectItems do ProjectLists.filteredDisplay[i] = ProjectLists.filteredProjectItems[i].date .. " | " .. ProjectLists.filteredProjectItems[i].name end
      else for i = 1, #ProjectLists.filteredProjectItems do ProjectLists.filteredDisplay[i] = ProjectLists.filteredProjectItems[i].name end end
    else
      if RL.showDate then for i = 1, #ProjectLists.projectItems do ProjectLists.display[i] = ProjectLists.projectItems[i].date .. " | " .. ProjectLists.projectItems[i].name end
      else for i = 1, #ProjectLists.projectItems do ProjectLists.display[i] = ProjectLists.projectItems[i].name end end
    end
  end
  if FilterActive.ProjectLists then GUI.elms.tab_projectLists_listboxProjects.list = ProjectLists.filteredDisplay else GUI.elms.tab_projectLists_listboxProjects.list = ProjectLists.display end
  GUI.elms.tab_projectLists_listboxProjects:redraw()
end

local function UpdateListDisplay_Backups()
  if RL.showFullPaths then
    if FilterActive.Backups then
      if RL.showDate then for i = 1, #Backups.filteredItems do Backups.filteredDisplay[i] = Backups.filteredItems[i].date .. " | " .. Backups.filteredItems[i].path end
      else for i = 1, #Backups.filteredItems do Backups.filteredDisplay[i] = Backups.filteredItems[i].path end end
    else
      if RL.showDate then for i = 1, #Backups.items do Backups.display[i] = Backups.items[i].date .. " | " .. Backups.items[i].path end
      else for i = 1, #Backups.items do Backups.display[i] = Backups.items[i].path end end
    end
  else
    if FilterActive.Backups then
      if RL.showDate then for i = 1, #Backups.filteredItems do Backups.filteredDisplay[i] = Backups.filteredItems[i].date .. " | " .. Backups.filteredItems[i].name end
      else for i = 1, #Backups.filteredItems do Backups.filteredDisplay[i] = Backups.filteredItems[i].name end end
    else
      if RL.showDate then for i = 1, #Backups.items do Backups.display[i] = Backups.items[i].date .. " | " .. Backups.items[i].name end
      else for i = 1, #Backups.items do Backups.display[i] = Backups.items[i].name end end
    end
  end
  if FilterActive.Backups then GUI.elms.tab_backups_listbox.list = Backups.filteredDisplay else GUI.elms.tab_backups_listbox.list = Backups.display end
  GUI.elms.tab_backups_listbox:redraw()
end

local function UpdateListDisplay_Docs()
  if RL.showFullPaths then
    if FilterActive.Docs then
      if RL.showDate then for i = 1, #Docs.filteredItems do Docs.filteredDisplay[i] = Docs.filteredItems[i].date .. " | " .. Docs.filteredItems[i].path end
      else for i = 1, #Docs.filteredItems do Docs.filteredDisplay[i] = Docs.filteredItems[i].path end end
    else
      if RL.showDate then for i = 1, #Docs.items do Docs.display[i] = Docs.items[i].date .. " | " .. Docs.items[i].path end
      else for i = 1, #Docs.items do Docs.display[i] = Docs.items[i].path end end
    end
  else
    if FilterActive.Docs then
      if RL.showDate then for i = 1, #Docs.filteredItems do Docs.filteredDisplay[i] = Docs.filteredItems[i].date .. " | " .. Docs.filteredItems[i].name end
      else for i = 1, #Docs.filteredItems do Docs.filteredDisplay[i] = Docs.filteredItems[i].name end end
    else
      if RL.showDate then for i = 1, #Docs.items do Docs.display[i] = Docs.items[i].date .. " | " .. Docs.items[i].name end
      else for i = 1, #Docs.items do Docs.display[i] = Docs.items[i].name end end
    end
  end
  if FilterActive.Docs then GUI.elms.tab_docs_listbox.list = Docs.filteredDisplay else GUI.elms.tab_docs_listbox.list = Docs.display end
  GUI.elms.tab_docs_listbox:redraw()
end

local function UpdateListDisplay_Favorites()
  if RL.showFullPaths then
    if FilterActive.Favorites then
      if RL.showDate then for i = 1, #Favorites.filteredItems do Favorites.filteredDisplay[i] = Favorites.filteredItems[i].date .. " | " .. Favorites.filteredItems[i].path end
      else for i = 1, #Favorites.filteredItems do Favorites.filteredDisplay[i] = Favorites.filteredItems[i].path end end
    else
      if RL.showDate then for i = 1, #Favorites.items do Favorites.display[i] = Favorites.items[i].date .. " | " .. Favorites.items[i].path end
      else for i = 1, #Favorites.items do Favorites.display[i] = Favorites.items[i].path end end
    end
  else
    if FilterActive.Favorites then
      if RL.showDate then for i = 1, #Favorites.filteredItems do Favorites.filteredDisplay[i] = Favorites.filteredItems[i].date .. " | " .. Favorites.filteredItems[i].name end
      else for i = 1, #Favorites.filteredItems do Favorites.filteredDisplay[i] = Favorites.filteredItems[i].name end end
    else
      if RL.showDate then for i = 1, #Favorites.items do Favorites.display[i] = Favorites.items[i].date .. " | " .. Favorites.items[i].name end
      else for i = 1, #Favorites.items do Favorites.display[i] = Favorites.items[i].name end end
    end
  end
  if FilterActive.Favorites then GUI.elms.tab_favorites_listbox.list = Favorites.filteredDisplay else GUI.elms.tab_favorites_listbox.list = Favorites.display end
  GUI.elms.tab_favorites_listbox:redraw()
end

function Global_UpdateListDisplay()
  if JSAPIinstalled then RL.showDate = GUI.Val("main_checklistDate") else RL.showDate = false end
  RL.showFullPaths = GUI.Val("main_checklistPaths")
  if not RL.skipOperationOnResize then 
    if GUI.elms.main_tabs.state == TabID.RecentProjects then UpdateListDisplay_RecentProjects()
      elseif GUI.elms.main_tabs.state == TabID.ProjectTemplates then UpdateListDisplay_ProjectTemplates()
      elseif GUI.elms.main_tabs.state == TabID.TrackTemplates then UpdateListDisplay_TrackTemplates()
      elseif GUI.elms.main_tabs.state == TabID.CustomProjects then UpdateListDisplay_CustomProjects()
      elseif GUI.elms.main_tabs.state == TabID.ProjectLists then UpdateListDisplay_ProjectLists()
      elseif GUI.elms.main_tabs.state == TabID.Backups then UpdateListDisplay_Backups()
      elseif GUI.elms.main_tabs.state == TabID.Docs then UpdateListDisplay_Docs()
      elseif GUI.elms.main_tabs.state == TabID.Favorites then UpdateListDisplay_Favorites()
    end
  end
end

-----------------
-- Sort functions
-----------------
function Global_CycleSortMode(isSortCycleReversed)
  if ConfigFlags.enableSortModeOptions and GUI.elms.main_tabs.state <= TabID.Favorites then 
    local sortMode = GUI.Val("main_sortMode")
    if isSortCycleReversed then
      if sortMode - 1 >= 1 then
        GUI.Val("main_sortMode", sortMode - 1)
        RL.sortModeIndex[GUI.elms.main_tabs.state] = sortMode - 1
      else  
        GUI.Val("main_sortMode", #GUI.elms.main_sortMode.optarray)
        RL.sortModeIndex[GUI.elms.main_tabs.state] = #GUI.elms.main_sortMode.optarray
      end
    else
      if sortMode + 1 <= #GUI.elms.main_sortMode.optarray then
        GUI.Val("main_sortMode", sortMode + 1)
        RL.sortModeIndex[GUI.elms.main_tabs.state] = sortMode + 1
      else  
        GUI.Val("main_sortMode", 1)
        RL.sortModeIndex[GUI.elms.main_tabs.state] = 1
      end
    end
    Global_UpdateSortMode()
  end
end

function Global_UpdateSortMode()
  if ConfigFlags.enableSortModeOptions and not RL.skipOperationOnResize then
    local sortMode = RL.sortModeIndex[GUI.elms.main_tabs.state]
    -- recent projects
    if GUI.elms.main_tabs.state == TabID.RecentProjects then
      if sortMode == 1 then
        if RL.showLastActiveProjects then FillLastActiveProjects(false) else RL_Func_TabRefresh[GUI.elms.main_tabs.state].call() end
      elseif sortMode == 2 then
        if RL.showLastActiveProjects then FillLastActiveProjects(true) else RefreshRecentProjects(true) end
      else
        if FilterActive.RecentProjects then Global_SortEntries(GUI.elms.main_tabs.state, RecentProjects.filteredItems, sortMode, true)
        else Global_SortEntries(GUI.elms.main_tabs.state, RecentProjects.items, sortMode, false) end
        GUI.elms.tab_recentProjects_listbox:redraw()
      end
    -- project lists
    elseif GUI.elms.main_tabs.state == TabID.ProjectLists then
      if sortMode == 1 then UpdateProjectListSelection(false) 
      elseif sortMode == 2 then UpdateProjectListSelection(true)
      else 
        if FilterActive.ProjectLists then Global_SortEntries(GUI.elms.main_tabs.state, ProjectLists.filteredProjectItems, sortMode, true)
        else Global_SortEntries(GUI.elms.main_tabs.state, ProjectLists.projectItems, sortMode, false) end
        GUI.elms.tab_projectLists_listboxProjects:redraw() 
      end
    else
      -- project templates
      if GUI.elms.main_tabs.state == TabID.ProjectTemplates then
        if FilterActive.ProjectTemplates then Global_SortEntries(GUI.elms.main_tabs.state, ProjectTemplates.filteredItems, sortMode, true)
        else Global_SortEntries(GUI.elms.main_tabs.state, ProjectTemplates.items, sortMode, false) end
        GUI.elms.tab_projectTemplates_listbox:redraw()
      -- track templates
      elseif GUI.elms.main_tabs.state == TabID.TrackTemplates then
        if FilterActive.TrackTemplates then Global_SortEntries(GUI.elms.main_tabs.state, TrackTemplates.filteredItems, sortMode, true)
        else Global_SortEntries(GUI.elms.main_tabs.state, TrackTemplates.items, sortMode, false) end
        GUI.elms.tab_trackTemplates_listbox:redraw()
      -- projects
      elseif GUI.elms.main_tabs.state == TabID.CustomProjects then
        if FilterActive.CustomProjects then Global_SortEntries(GUI.elms.main_tabs.state, CustomProjects.filteredItems, sortMode, true)
        else Global_SortEntries(GUI.elms.main_tabs.state, CustomProjects.items, sortMode, false) end
        GUI.elms.tab_customProjects_listbox:redraw()
      -- backups
      elseif GUI.elms.main_tabs.state == TabID.Backups then
        if FilterActive.Backups then Global_SortEntries(GUI.elms.main_tabs.state, Backups.filteredItems, sortMode, true)
        else Global_SortEntries(GUI.elms.main_tabs.state, Backups.items, sortMode, false) end
        GUI.elms.tab_backups_listbox:redraw()
      -- docs
      elseif GUI.elms.main_tabs.state == TabID.Docs then
        if FilterActive.Docs then Global_SortEntries(GUI.elms.main_tabs.state, Docs.filteredItems, sortMode, true)
        else Global_SortEntries(GUI.elms.main_tabs.state, Docs.items, sortMode, false) end
        GUI.elms.tab_docs_listbox:redraw()
      -- favorites
      elseif GUI.elms.main_tabs.state == TabID.Favorites then
        if FilterActive.Favorites then Global_SortEntries(GUI.elms.main_tabs.state, Favorites.filteredItems, sortMode, true)
        else Global_SortEntries(GUI.elms.main_tabs.state, Favorites.items, sortMode, false) end
        GUI.elms.tab_favorites_listbox:redraw()
      end
    end
    reaper.SetExtState(appname, "window_sortmode", table.concat(RL.sortModeIndex, ","), 1)
    Global_UpdateListDisplay()
    if JSAPIinstalled then AudioPreviewCheckForFile(GUI.elms.main_tabs.state) end
  end
end

function Global_SortEntries(tabfocus, tableToSort, sortMode, isFiltered)
    if ((tabfocus == TabID.RecentProjects or tabfocus == TabID.ProjectLists) and sortMode == 3) or (tabfocus > TabID.RecentProjects and sortMode == 1) then
      table.sort(tableToSort, function(a, b) return a.name:lower() < b.name:lower() end) -- sort alphabetically ascending
    elseif ((tabfocus == TabID.RecentProjects or tabfocus == TabID.ProjectLists) and sortMode == 4) or (tabfocus > TabID.RecentProjects and sortMode == 2) then
      table.sort(tableToSort, function(a, b) return b.name:lower() < a.name:lower() end) -- sort alphabetically descending 
    elseif ((tabfocus == TabID.RecentProjects or tabfocus == TabID.ProjectLists) and sortMode == 5) or (tabfocus > TabID.RecentProjects and sortMode == 3) then
      table.sort(tableToSort, function(a, b) return b.date:lower() < a.date:upper() end) -- sort by date descending (newest 'last modified' first) 
    elseif ((tabfocus == TabID.RecentProjects or tabfocus == TabID.ProjectLists) and sortMode == 6) or (tabfocus > TabID.RecentProjects and sortMode == 4) then
      table.sort(tableToSort, function(a, b) return a.date:lower() < b.date:lower() end) -- sort by date ascending (oldest 'last modified' first)
  end
end

--------------
-- Cache Files
--------------
local filePathAndPrefix = debug.getinfo(1,'S').source:match[[^@?(.*[\/])[^\/]-$]] .. appname

local CacheFile = {
  MainSection = 1,
  ProjectTemplates = filePathAndPrefix .. "_Cache_ProjectTemplates.ini",
  TrackTemplates = filePathAndPrefix .. "_Cache_TrackTemplates.ini",
  CustomProjects = filePathAndPrefix .. "_Cache_Projects.ini",
  ProjectLists = filePathAndPrefix .. "_Cache_ProjectLists.ini",
  Backups = filePathAndPrefix .. "_Cache_Backups.ini",
  Docs = filePathAndPrefix .. "_Cache_Docs.ini",
}

local SubpanelFile = {
  MainSection = 1,
  ProjectTemplates = filePathAndPrefix .. "_Subpanel_ProjectTemplates.ini",
  TrackTemplates = filePathAndPrefix .. "_Subpanel_TrackTemplates.ini",
  CustomProjects = filePathAndPrefix .. "_Subpanel_Projects.ini",
  ProjectLists = filePathAndPrefix .. "_Subpanel_ProjectLists.ini",
  Backups = filePathAndPrefix .. "_Subpanel_Backups.ini",
  Docs = filePathAndPrefix .. "_Subpanel_Docs.ini",
}

local FavoritesFile = {
  filePathAndPrefix .. "_Favorites_RecentProjects.ini",
  filePathAndPrefix .. "_Favorites_ProjectTemplates.ini",
  filePathAndPrefix .. "_Favorites_TrackTemplates.ini",
  filePathAndPrefix .. "_Favorites_Projects.ini",
  filePathAndPrefix .. "_Favorites_ProjectLists.ini",
  filePathAndPrefix .. "_Favorites_Backups.ini",
  filePathAndPrefix .. "_Favorites_Docs.ini",
}

function RL_ClearFile(fileName)
  local file = io.open(fileName, "w")
  if not file then return nil end
  file:close()
  return true
end

local function AddFileSectionEntries(file, sectionName, entries)
  if entries == nil then return end
  file:write("[" .. sectionName .. "]\n")
  for e = 1, #entries do file:write(entries[e] .. "\n") end
  file:write("[[" .. sectionName .. "]]\n")
end

function RL_WriteFavorites(fileName, sectionName, entries)
  local favExists, favEntries = RL_ReadFromFile(fileName, CacheFile.MainSection)
  local file = io.open(fileName, "w")
  if not file then return nil end

  if favExists and #favEntries > 0 then
    local entriesToAdd = {}
    for e = 1, #entries do
      if not CheckForDuplicates(favEntries, entries[e]) then entriesToAdd[#entriesToAdd + 1] = entries[e] end
    end
    JoinTables(favEntries, entriesToAdd)
    AddFileSectionEntries(file, CacheFile.MainSection, favEntries)
  else
    AddFileSectionEntries(file, CacheFile.MainSection, entries)
  end
  
  file:close()
end

function RL_WriteToFileCache(fileName, sectionName, entries, clearCache)
  if not ConfigFlags.enableFileCaching or entries == nil then return end
  MsgDebug(">> WRITE to '" .. fileName .. "'")

  if clearCache then 
    local file = io.open(fileName, "w")
    if not file then return nil end
    AddFileSectionEntries(file, CacheFile.MainSection, entries)
    file:close()
  else
    -- append to existing entries
    local allExists, tAll = RL_ReadFromFile(fileName, CacheFile.MainSection)
    local lastExists, tLast = false, nil

    if sectionName ~= CacheFile.MainSection then lastExists, tLast = RL_ReadFromFile(fileName, sectionName) end
    local file = io.open(fileName, "w")
    if not file then return nil end

    -- both sections 'Main' and 'Last' exist
    if allExists and lastExists then
      if sectionName == CacheFile.MainSection then 
        AddFileSectionEntries(file, CacheFile.MainSection, entries)
        AddFileSectionEntries(file, sectionName, tLast)
      else
        AddFileSectionEntries(file, CacheFile.MainSection, tAll)
        AddFileSectionEntries(file, sectionName, entries)
      end
    -- only section 'Main' exists
    elseif allExists and not lastExists then
      if sectionName == CacheFile.MainSection then
        AddFileSectionEntries(file, CacheFile.MainSection, entries)
      else
        AddFileSectionEntries(file, CacheFile.MainSection, tAll)
        AddFileSectionEntries(file, sectionName, entries)
      end
    -- only section 'Last' exists
    elseif not allExists and lastExists then
      if sectionName == CacheFile.MainSection then
        AddFileSectionEntries(file, CacheFile.MainSection, entries)
        AddFileSectionEntries(file, sectionName, tLast)
      else
        AddFileSectionEntries(file, sectionName, entries)
      end
    else -- no section exists
      if sectionName == CacheFile.MainSection then AddFileSectionEntries(file, CacheFile.MainSection, entries)
      else AddFileSectionEntries(file, sectionName, entries) end
    end

    file:close()
  end
end

function RL_WriteToSubfolderCache(fileName, sectionName, entries)
  if not ConfigFlags.enableSubfolderCaching then return end
  MsgDebug(">> WRITE to '" .. fileName .. "'")
  RL_ClearFile(fileName)

  local file = io.open(fileName, "w")
  if not file then return nil end
  if entries ~= nil and #entries > 0 then AddSubfolderSectionEntries(file, sectionName, entries) end
  file:close()
end

function RL_ReadFromFile(fileName, sectionName)
  MsgDebug("<< READ from '" .. fileName .. "' | Section: " .. sectionName)
  local file = io.open(fileName, "r")
  if not file then MsgDebug("\tCannot read file or file does not exist yet") return false, nil end
  local entries = {}
  local lineNumber, startIndex, endIndex = 0, 0, 0

  for line in file:lines() do
    if #line > 1 then
      entries[#entries + 1] = line
      lineNumber = lineNumber + 1
      if line == "[" .. sectionName .. "]" then startIndex = lineNumber + 1
      elseif line == "[[" .. sectionName .. "]]" then
          endIndex = lineNumber - 1
          break
      end
    end
  end
  file:close()

  local results = {}
  for e = startIndex, endIndex do results[#results + 1] = entries[e] end
  
  if results ~= nil and #results > 0 then return true, results
  else return false, nil end
end

function RL_ReadFromFileCache(fileName, sectionName)
  if not ConfigFlags.enableFileCaching or RL.forceRescan then return false, _ end
  return RL_ReadFromFile(fileName, sectionName)
end

function RL_ReadFromSubfolderCache(fileName, sectionName)
  if not ConfigFlags.enableSubfolderCaching or RL.forceRescan then return false, _ end
  return RL_ReadFromFile(fileName, sectionName)
end

------------------
-- Listbox content
------------------
RecentProjects = {
  maxIndex,
  items = {},
  filteredItems = {},
  display = {},
  filteredDisplay = {}
}

local function AddRecentProjectEntries(fullPath, e)
  if fullPath ~= "" then
    if not CheckForDuplicates(GetSubTableByPathKey(RecentProjects.items), fullPath) then
      e = e + 1
      RecentProjects.items[e] = {
        name = RemoveExtension(GetFilenameWithoutPath(fullPath), FileTypes.rpp),
        path = fullPath,
        date = GetLastModifiedDate(fullPath)
      }
      if ConfigFlags.listFilesInDebugMessages then MsgDebug(e .. ": " .. fullPath) end
    end
  end
  return e
end

local function GetRecentProjectEntries(p, recentFirst)
  local e = 0
  if recentFirst then -- iterate through recent entries from newest to oldest
    repeat 
      p = p - 1
      local _, fullPath = reaper.BR_Win32_GetPrivateProfileString("recent", "recent" .. string.format("%02d", p), "noEntry", reaperIniPath)
      e = AddRecentProjectEntries(fullPath, e)
    until p == 1
  else -- iterate through recent entries from oldest to newest
    local c = 0
    repeat
      c = c + 1
      local _, fullPath = reaper.BR_Win32_GetPrivateProfileString("recent", "recent" .. string.format("%02d", c), "noEntry", reaperIniPath)
      e = AddRecentProjectEntries(fullPath, e)
    until c == p - 1
  end
end

local function FillRecentProjectsListbox(recentFirst)
  RecentProjects.items = {}
  local lastEntry = false
  local p = 0

  -- get recent project count
  repeat
    p = p + 1
    local _, value = reaper.BR_Win32_GetPrivateProfileString("recent", "recent" .. string.format("%02d", p), "noEntry", reaperIniPath)
    if value == "noEntry" then
      lastEntry = true
      break
    end
  until (lastEntry)

  -- no [Recent] section exists yet
  if (p == 1 and lastEntry) then return end

  -- iterate through entries
  RecentProjects.maxIndex = p - 1
  GetRecentProjectEntries(p, recentFirst)

  Global_UpdateListDisplay()
  GUI.elms.tab_recentProjects_listbox:redraw()
  ShowFileCount()
end

-------------------------------
-- Subdirectory paths and names
-------------------------------
local function GetSubFolderEntries(defaultPath, customPath, folderExclusionIndex, extensionFilter)
  local subDirPaths, subDirFiles = {}, {}
  local tempFolders, tempFiles

  if defaultPath == "All" then subDirPaths, subDirFiles = {"< All >"}, {"< All >"}
  elseif IsNotNullOrEmpty(defaultPath) then
    subDirPaths, subDirFiles = {"< All >"}, {"< All >"}

    subDirPaths[2] = defaultPath
    subDirFiles[2] = "< " .. GetFolderName(defaultPath) .. " >"

    local tempFolders, tempFiles = GetSubFolders(defaultPath, folderExclusionIndex, extensionFilter)
    JoinTables(subDirPaths, tempFolders)
    JoinTables(subDirFiles, tempFiles)
  end

  if IsNotNullOrEmpty(customPath) then
    local multiPaths = SplitMultiPaths(customPath)
    for m = 1, #multiPaths do
      local currentPath = multiPaths[m]
      subDirPaths[#subDirPaths + 1] = currentPath
      subDirFiles[#subDirFiles + 1] = "< " .. GetFolderName(currentPath) .. " >"

      local tempFolders, tempFiles = GetSubFolders(currentPath, folderExclusionIndex, extensionFilter)
      JoinTables(subDirPaths, tempFolders)
      JoinTables(subDirFiles, tempFiles)
    end
  end

  return subDirPaths, subDirFiles
end

---------------------------
-- Project Template Listbox
---------------------------
ProjectTemplates = {
  items = {},
  filteredItems = {},
  display = {},
  filteredDisplay = {}
}

SubfolderPaths = {
  projectTemplates = {},
  trackTemplates = {},
  customProjects = {},
  backups = {},
  docs = {}
}

SubfolderNames = {
  projectTemplates = {},
  trackTemplates = {},
  customProjects = {},
  backups = {},
  docs = {}
}

local function FillProjectTemplateListBoxBase(tempTemplates)
  ProjectTemplates.items, ProjectTemplates.display = {}, {}
  local pos = 1

  for i = 1, #tempTemplates do
    if ConfigFlags.listFilesInDebugMessages then MsgDebug(tempTemplates[i]) end
    ProjectTemplates.items[pos] = {
      name = RemoveExtension(GetFilenameWithoutPath(tempTemplates[i]), FileTypes.rpp),
      path = tempTemplates[i],
      date = GetLastModifiedDate(tempTemplates[i])
    }
    pos = pos + 1
  end

  Global_UpdateListDisplay()
  GUI.elms.tab_projectTemplates_listbox:redraw()
  ShowFileCount()
end

function GetProjectTemplateFiles()
  local tempTemplates = GetFiles(projectTemplatePath, TabID.ProjectTemplates, FileTypes.rpp)
  if #CustomPaths.ProjectTemplates > 1 then
    local multiPaths = SplitMultiPaths(CustomPaths.ProjectTemplates)
    for m = 1, #multiPaths do JoinTables(tempTemplates, GetFiles(multiPaths[m], TabID.ProjectTemplates, FileTypes.rpp)) end
  end
  if #tempTemplates == 0 then
    return false, nil
  else
    return true, tempTemplates
  end
end

local function FillProjectTemplateListbox()
  local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.ProjectTemplates, CacheFile.MainSection)
  if cacheExists then FillProjectTemplateListBoxBase(cacheTable)
  else
    local retval, tempTemplates = GetProjectTemplateFiles()
    if retval then 
      FillProjectTemplateListBoxBase(tempTemplates)
      RL_WriteToFileCache(CacheFile.ProjectTemplates, CacheFile.MainSection, GetSubTableByPathKey(ProjectTemplates.items), false)
    end
  end
end

-------------------------
-- Track Template Listbox
-------------------------
TrackTemplates = {
  items = {},
  filteredItems = {},
  display = {},
  filteredDisplay = {}
}

local function FillTrackTemplateListboxBase(tempTemplates)
  TrackTemplates.items, TrackTemplates.display = {}, {}
  local pos = 1
  for i = 1, #tempTemplates do
    if ConfigFlags.listFilesInDebugMessages then MsgDebug(tempTemplates[i]) end
    TrackTemplates.items[pos] = {
      name = RemoveExtension(GetFilenameWithoutPath(tempTemplates[i]), FileTypes.tracktemplate),
      path = tempTemplates[i],
      date = GetLastModifiedDate(tempTemplates[i])
    }
    pos = pos + 1
  end
  Global_UpdateListDisplay()
  GUI.elms.tab_trackTemplates_listbox:redraw()
  ShowFileCount()
end

function GetTrackTemplateFiles()
  local tempTemplates = GetFiles(trackTemplatePath, TabID.TrackTemplates, FileTypes.tracktemplate)
  if #CustomPaths.TrackTemplates > 1 then
    local multiPaths = SplitMultiPaths(CustomPaths.TrackTemplates)
    for m = 1, #multiPaths do JoinTables(tempTemplates, GetFiles(multiPaths[m], TabID.TrackTemplates, FileTypes.tracktemplate)) end
  end
  if #tempTemplates == 0 then
    return false, _
  else
    return true, tempTemplates
  end
end

local function FillTrackTemplateListbox()
  local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.TrackTemplates, CacheFile.MainSection)
  if cacheExists then FillTrackTemplateListboxBase(cacheTable)
  else
    local retval, tempTemplates = GetTrackTemplateFiles()
    if retval then 
      FillTrackTemplateListboxBase(tempTemplates)
      RL_WriteToFileCache(CacheFile.TrackTemplates, CacheFile.MainSection, GetSubTableByPathKey(TrackTemplates.items), false)
    end
  end
end

-------------------------
-- Custom Project Listbox
-------------------------
CustomProjects = {
  items = {},
  filteredItems = {},
  display = {},
  filteredDisplay = {}
}

local function FillCustomProjectsListboxBase(dirFiles, pos)
  for i = 1, #dirFiles do
    if ConfigFlags.listFilesInDebugMessages then MsgDebug(dirFiles[i]) end
    CustomProjects.items[pos] = {
      name = RemoveExtension(GetFilenameWithoutPath(dirFiles[i]), FileTypes.rpp),
      path = dirFiles[i],
      date = GetLastModifiedDate(dirFiles[i])
    }
    pos = pos + 1
  end

  Global_UpdateListDisplay()
  GUI.elms.tab_customProjects_listbox:redraw()
  ShowFileCount()

  return pos
end

local function FillCustomProjectsListbox()
  CustomProjects.items = {}
  local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.CustomProjects, CacheFile.MainSection)
  if cacheExists then FillCustomProjectsListboxBase(cacheTable, 1)
  else
    if #CustomPaths.Projects > 1 then
      local multiPaths = SplitMultiPaths(CustomPaths.Projects)
      for m = 1, #multiPaths do FillCustomProjectsListboxBase(GetFiles(multiPaths[m], TabID.CustomProjects, FileTypes.rpp), 1) end
      RL_WriteToFileCache(CacheFile.CustomProjects, CacheFile.MainSection, GetSubTableByPathKey(CustomProjects.items), false)
    end
  end
end

------------------------
-- Project Lists Listbox
------------------------
ProjectLists = {
  rplFiles = {},
  rplPaths = {},
  projectItems = {},
  filteredProjectItems = {},
  display = {},
  filteredDisplay = {}
}

local function InvertElementOrder(arr)
  local e1, e2 = 1, #arr
  while e1 < e2 do
    arr[e1], arr[e2] = arr[e2], arr[e1]
    e1 = e1 + 1
    e2 = e2 - 1
   end
end

local function RPL_ParseRPLFile(selected, listInReverse)
  ProjectLists.projectItems, ProjectLists.display = {}, {}
  for i = 1, #selected do
    local file = io.open(ProjectLists.rplPaths[selected[i]] .. pathSeparator .. ProjectLists.rplFiles[selected[i]] .. FileTypes.rpl, "r")
    if not file then
      file = io.open(ProjectLists.rplPaths[selected[i]] .. pathSeparator .. ProjectLists.rplFiles[selected[i]] .. string.upper(FileTypes.rpl), "r")
    end
    if not file then return nil end
    for line in file:lines() do
      if #line > 1 then
        if not CheckForDuplicates(GetSubTableByPathKey(ProjectLists.projectItems), line) then
          ProjectLists.projectItems[#ProjectLists.projectItems + 1] = {
            name = RemoveExtension(RemoveWhiteSpaces(GetFilenameWithoutPath(line)), FileTypes.rpp),
            path = line,
            date = GetLastModifiedDate(line)
          }
        end
      end
    end
    file:close()
  end

  if listInReverse then
    InvertElementOrder(ProjectLists.projectItems)
  end

   GUI.elms.tab_projectLists_listboxProjects.list = GetSubTableByNameKey(ProjectLists.projectItems)
end

function RPL_FillProjectListFromTable(cacheTable, listInReverse)
  ProjectLists.projectItems, ProjectLists.display = {}, {}
  for i = 1, #cacheTable do
    ProjectLists.projectItems[#ProjectLists.projectItems + 1] = {
      name = RemoveExtension(RemoveWhiteSpaces(GetFilenameWithoutPath(cacheTable[i])), FileTypes.rpp),
      path = cacheTable[i],
      date = GetLastModifiedDate(cacheTable[i])
    }
  end
  if listInReverse then
    InvertElementOrder(ProjectLists.projectItems)
  end
  GUI.elms.tab_projectLists_listboxProjects.list = GetSubTableByNameKey(ProjectLists.projectItems)
end

------------------------
-- Backups Lists Listbox
------------------------
Backups = {
  items = {},
  filteredItems = {},
  display = {},
  filteredDisplay = {}
}

local function FillBackupsListboxBase(dirFiles, pos)
  for i = 1, #dirFiles do
    if ConfigFlags.listFilesInDebugMessages then MsgDebug(dirFiles[i]) end
    Backups.items[pos] = {
      name = RemoveExtension(GetFilenameWithoutPath(dirFiles[i]), FileTypes.backup),
      path = dirFiles[i],
      date = GetLastModifiedDate(dirFiles[i])
    }
    pos = pos + 1
  end

  GUI.elms.tab_backups_listbox.list = GetSubTableByNameKey(Backups.items)
  Global_UpdateListDisplay()
  ShowFileCount()

  return pos
end

local function FillBackupsListbox()
  local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.Backups, CacheFile.MainSection)
  if cacheExists then FillBackupsListboxBase(cacheTable, 1)
  else
    if #CustomPaths.Backups > 1 then
      Backups.items = {}
      local multiPaths = SplitMultiPaths(CustomPaths.Backups)
      local pos = 1
      for m = 1, #multiPaths do pos = FillBackupsListboxBase(GetFiles(multiPaths[m], TabID.Backups, FileTypes.backup), pos) end
      RL_WriteToFileCache(CacheFile.Backups, CacheFile.MainSection, GetSubTableByPathKey(Backups.items), false)
    end
  end
end

---------------
-- Docs Listbox
---------------
Docs = {
  items = {},
  filteredItems = {},
  display = {},
  filteredDisplay = {}
}

local function FillDocsListboxBase(dirFiles, pos)
  for i = 1, #dirFiles do
    if ConfigFlags.listFilesInDebugMessages then MsgDebug(dirFiles[i]) end
    Docs.items[pos] = {
      name = RemoveExtension(GetFilenameWithoutPath(dirFiles[i]), FileTypes.docs),
      path = dirFiles[i],
      date = GetLastModifiedDate(dirFiles[i])
    }
    pos = pos + 1
  end

  GUI.elms.tab_docs_listbox.list = GetSubTableByNameKey(Docs.items)
  Global_UpdateListDisplay()
  ShowFileCount()

  return pos
end

local function FillDocsListbox()
  local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.Docs, CacheFile.MainSection)
  if cacheExists then FillDocsListboxBase(cacheTable, 1)
  else
    if #CustomPaths.Docs > 1 then
      Docs.items = {}
      local multiPaths = SplitMultiPaths(CustomPaths.Docs)
      local pos = 1
      for m = 1, #multiPaths do pos = FillDocsListboxBase(GetFiles(multiPaths[m], TabID.Docs, FileTypes.docs), pos) end
      RL_WriteToFileCache(CacheFile.Docs, CacheFile.MainSection, GetSubTableByPathKey(Docs.items), false)
    end
  end
end

----------------------------------
-- Fill the listboxes with entries
----------------------------------
CustomPaths = {
  ProjectTemplates = reaper.GetExtState(appname, "custompath_projecttemplates"),
  TrackTemplates = reaper.GetExtState(appname, "custompath_tracktemplates"),
  Projects = reaper.GetExtState(appname, "custompath_projects"),
  ProjectLists = reaper.GetExtState(appname, "custompath_projectlists"),
  Backups = reaper.GetExtState(appname, "custompath_backups"),
  Docs = reaper.GetExtState(appname, "custompath_docs")
}

-----------------------------------
-- New project/tab button functions
-----------------------------------
local function Global_CheckWindowPinState()
  if not GUI.Val("main_checklistWindowPin") then gfx.quit() end
end

local function Global_ShowProjectOpenDialog()
  reaper.Main_OnCommand(40025, 0) -- File: Open project
  Global_CheckWindowPinState()
end

function Global_ShowPathInStatusbar(tabIndex)
  if GUI.Val("options_checklistShowPathsInStatusbar") then
    local selectedPath = ""
    if tabIndex == TabID.RecentProjects and GetMainListSize() > 0 then
      if FilterActive.RecentProjects then selectedPath = RecentProjects.filteredItems[TabSelectionIndex[TabID.RecentProjects]].path
      else selectedPath = RecentProjects.items[TabSelectionIndex[TabID.RecentProjects]].path end
    elseif tabIndex == TabID.ProjectTemplates and GetMainListSize() > 0 then
      if FilterActive.ProjectTemplates then selectedPath = ProjectTemplates.filteredItems[TabSelectionIndex[TabID.ProjectTemplates]].path
      else selectedPath = ProjectTemplates.items[TabSelectionIndex[TabID.ProjectTemplates]].path end
    elseif tabIndex == TabID.TrackTemplates and GetMainListSize() > 0 then
      if FilterActive.TrackTemplates then selectedPath = TrackTemplates.filteredItems[TabSelectionIndex[TabID.TrackTemplates]].path
      else selectedPath = TrackTemplates.items[TabSelectionIndex[TabID.TrackTemplates]].path end
    elseif tabIndex == TabID.CustomProjects and GetMainListSize() > 0 then
      if FilterActive.CustomProjects then selectedPath = CustomProjects.filteredItems[TabSelectionIndex[TabID.CustomProjects]].path
      else selectedPath = CustomProjects.items[TabSelectionIndex[TabID.CustomProjects]].path end
    elseif tabIndex == TabID.ProjectLists and GetMainListSize() > 0 then
      if FilterActive.ProjectLists then selectedPath = ProjectLists.filteredProjectItems[TabSelectionIndex[TabID.ProjectLists]].path
      else selectedPath = ProjectLists.projectItems[TabSelectionIndex[TabID.ProjectLists]].path end
    elseif tabIndex == TabID.Backups and GetMainListSize() > 0 then
      if FilterActive.Backups then selectedPath = Backups.filteredItems[TabSelectionIndex[TabID.Backups]].path
      else selectedPath = Backups.items[TabSelectionIndex[TabID.Backups]].path end
    elseif tabIndex == TabID.Docs and GetMainListSize() > 0 then
      if FilterActive.Docs then selectedPath = Docs.filteredItems[TabSelectionIndex[TabID.Docs]].path
      else selectedPath = Docs.items[TabSelectionIndex[TabID.Docs]].path end
    elseif tabIndex == TabID.Favorites and GetMainListSize() > 0 then
      if FilterActive.Favorites then selectedPath = Favorites.filteredItems[TabSelectionIndex[TabID.Favorites]].path
      else selectedPath = Favorites.items[TabSelectionIndex[TabID.Favorites]].path end
    end
    if GUI.Val("options_menuShowPathsInStatusbar") == 2 then selectedPath = GetDirectoryPath(selectedPath) .. pathSeparator end
    MsgStatusBar(selectedPath .. "      ")
    GUI.elms.main_statusbar.tooltip = selectedPath 
  end
end

function Global_TriggerFollowAction(elementName)
  local commandID = GUI.Val(elementName)
  if IsNotNullOrEmpty(commandID) then 
    if tonumber(commandID) ~= nil then reaper.Main_OnCommand(commandID, 0) else reaper.Main_OnCommand(reaper.NamedCommandLookup(commandID), 0) end
  end
end

local function Global_NewProject()
  reaper.Main_OnCommand(40023, 0) -- File: New project
  if GUI.Val("options_checklistOpenPropertiesOnNewProject") then reaper.Main_OnCommand(40021, 0) end -- File: Project settings
  Global_TriggerFollowAction("actions_txtFollowAction_NewProject")
  RL_SetStartTab("onAction")
  Global_CheckWindowPinState()
end

local function Global_NewTab()
  reaper.Main_OnCommand(40859, 0) -- New project tab
  if GUI.Val("options_checklistOpenPropertiesOnNewProject") then reaper.Main_OnCommand(40021, 0) end -- File: Project settings
  Global_TriggerFollowAction("actions_txtFollowAction_NewTab")
  RL_SetStartTab("onAction")
  Global_CheckWindowPinState()
end

local function Global_NewTabIgnoreDefaultTemplate()
  reaper.Main_OnCommand(41929, 0) -- New project tab (ignore default template)
  if GUI.Val("options_checklistOpenPropertiesOnNewProject") then reaper.Main_OnCommand(40021, 0) end -- File: Project settings
  RL_SetStartTab("onAction")
  Global_CheckWindowPinState()
end

local function Global_Load(tabmode, selectedFile, fileCount)
  if selectedFile ~= nil then
    if tabmode then
        reaper.Main_OnCommand(41929, 0) -- New project tab (ignore default template)
        reaper.Main_openProject(selectedFile)
        if GUI.Val("main_checklistSaveAsNewVersion") or GUI.Val("tab_favorites_checklistSaveAsNewVersion") or RL.saveAsNewVersionMode == 1 then
          reaper.Main_OnCommand(41895, 0) -- [Main] - File: Save new version of project (automatically increment project name)
        end
        Global_TriggerFollowAction("actions_txtFollowAction_LoadProjectInTab")
        if JSAPIinstalled then AudioPreviewStopAll() end
    else
      if fileCount > 1 then reaper.Main_OnCommand(41929, 0) end -- New project tab (ignore default template)
      reaper.Main_openProject(selectedFile)
      if GUI.Val("main_checklistSaveAsNewVersion") or GUI.Val("tab_favorites_checklistSaveAsNewVersion") or RL.saveAsNewVersionMode == 1 then
        reaper.Main_OnCommand(41895, 0) -- [Main] - File: Save new version of project (automatically increment project name)
      end
      if fileCount > 1 then Global_TriggerFollowAction("actions_txtFollowAction_LoadProjectInTab") else Global_TriggerFollowAction("actions_txtFollowAction_LoadProject") end
      if JSAPIinstalled then AudioPreviewStopAll() end
    end
  end
end

local function Global_ProjectTemplateLoadBase(template)
  if template ~= nil then
    if RL.isNewTemplateLoadLogicSupported then
      -- logic for Reaper versions 5.983 or higher
      if RL.projectTemplateLoadMode == 1 then reaper.Main_openProject("template:" .. template) -- load as template
      else reaper.Main_openProject(template) end -- open template file for editing
    else
      -- logic for Reaper versions older than 5.983
      reaper.Main_openProject(template) -- open template file for editing
      if RL.projectTemplateLoadMode == 1 then reaper.Main_OnCommand(40022,0) end -- File: Save project as
    end
    if JSAPIinstalled then AudioPreviewStopAll() end
  end
end

local function Global_ProjectTemplateLoad(template, templateCount)
  if templateCount > 1 then reaper.Main_OnCommand(41929, 0) end -- New project tab (ignore default template)
  Global_ProjectTemplateLoadBase(template)
end

function RL_Mouse_DoubleClick(currentTab)
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local dcOption = GUI.Val("options_menuDoubleClick")
  -- show prompt
  if dcOption == 1 then
    local doubleClickMenuEntries = "1 - Load|2 - Load in Tab"
    if currentTab == TabID.TrackTemplates then doubleClickMenuEntries = "1 - Insert|2 - Insert in Tab" end
    if JSAPIinstalled then doubleClickMenuEntries = doubleClickMenuEntries .. "|#|3 - Audio Preview" end
    local DoubleClickMenu = gfx.showmenu(doubleClickMenuEntries)
    if DoubleClickMenu == 1 then RL_Func_LoadElement[currentTab].call()
      elseif DoubleClickMenu == 2 then RL_Func_LoadElementInTab[currentTab].call()
      elseif DoubleClickMenu == 3 then AudioPreviewToggleState()
    end
  -- perform action directly
  elseif dcOption == 2 then RL_Func_LoadElement[currentTab].call()
  elseif dcOption == 3 then RL_Func_LoadElementInTab[currentTab].call()
  elseif dcOption == 4 then AudioPreviewToggleState() end
end

----------------------------------
-- Recent project button functions
----------------------------------
local function Load_RecentProject_Base(tabmode)
  if GetMainListSize() > 0 then
    local vals = GetSelectionTable(GUI.Val("tab_recentProjects_listbox"))
    for p = 1, #vals do
      if FilterActive.RecentProjects then Global_Load(tabmode, RecentProjects.filteredItems[vals[p]].path, p)
      else Global_Load(tabmode, RecentProjects.items[vals[p]].path, p) end
    end
    GUI.Val("tab_recentProjects_listbox",{})
    Global_CheckWindowPinState()
  end
end

local function Load_RecentProject()
  Load_RecentProject_Base(false)
end

local function LoadInTab_RecentProject()
  Load_RecentProject_Base(true)
end

-------------------
-- Load Last Active
-------------------
if SWSinstalled then
  LastActiveProjects = {
    tabCount = 0,
    lastProject = "",
    projectTabs = {}
  }
  
  function FillLastActiveProjects(listInReverse)
    RL_SetFocusedTab(TabID.RecentProjects)
    GUI.elms.tab_recentProjects_btnLastActiveProject.color = FilterColor.active
    GUI.elms.tab_recentProjects_btnLastActiveProject:init()
    RecentProjects.items, RecentProjects.display = {}, {}
    local e = 0;

    if IsNotNullOrEmpty(LastActiveProjects.tabCount) and tonumber(LastActiveProjects.tabCount) then
      for i = 1, tonumber(LastActiveProjects.tabCount) do
        local projectTabPath = LastActiveProjects.projectTabs[i]
        if IsNotNullOrEmpty(projectTabPath) then 
          if ConfigFlags.listFilesInDebugMessages then MsgDebug(projectTabPath) end
          e = AddRecentProjectEntries(projectTabPath, e)
        end
      end
    end

    if listInReverse then InvertElementOrder(RecentProjects.items) end

    Global_UpdateListDisplay()
    GUI.elms.tab_recentProjects_listbox:redraw()
    ShowFileCount()
  end
end

function RL_Context_LastActiveProjects()
  if GUI.elms.main_tabs.state <= TabID.Favorites then
    _, LastActiveProjects.lastProject = reaper.BR_Win32_GetPrivateProfileString("REAPER", "lastproject", "noEntry", reaperIniPath)
    _, LastActiveProjects.tabCount = reaper.BR_Win32_GetPrivateProfileString("REAPER", "projecttabs", "noEntry", reaperIniPath)

    local menuEntries = {}
    if IsNotNullOrEmpty(LastActiveProjects.lastProject) and LastActiveProjects.lastProject ~= "noEntry" then menuEntries[1] = "1 - Load last active project (" .. GetFilenameWithoutPath(LastActiveProjects.lastProject) .. ")"
    else menuEntries[1] = "#1 - Load last project" end

    LastActiveProjects.projectTabs = {}
    if tonumber(LastActiveProjects.tabCount) and tonumber(LastActiveProjects.tabCount) > 0 then
      for i = 1, tonumber(LastActiveProjects.tabCount) do
        local _, projectTabPath = reaper.BR_Win32_GetPrivateProfileString("REAPER", "projecttab" .. i, "noEntry", reaperIniPath)
        if (IsNotNullOrEmpty(projectTabPath) or projectTabPath ~= "noEntry") and not CheckForDuplicates(LastActiveProjects.projectTabs, projectTabPath) then
          LastActiveProjects.projectTabs[#LastActiveProjects.projectTabs + 1] = projectTabPath
        end
      end
      if #LastActiveProjects.projectTabs > 0 then 
        menuEntries[#menuEntries + 1] = "2 - Load all last active project tabs (count: " .. #LastActiveProjects.projectTabs .. ")"
        menuEntries[#menuEntries + 1] = "3 - Show projects in lists"
      end
    else
      menuEntries[#menuEntries + 1] = "#2 - Load all last active project tabs"
      menuEntries[#menuEntries + 1] = "#3 - Show projects in list"
    end

    if #menuEntries == 1 and menuEntries[1] == "#1 - Load last project" then
      MsgStatusBar("No last active projects found")
      return
    end

    gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
    local RMBmenu = gfx.showmenu(table.concat(menuEntries, "||"))
    if RMBmenu == 1 then Global_Load(false, LastActiveProjects.lastProject, 1)
      elseif RMBmenu == 2 then for p = 1, #LastActiveProjects.projectTabs do Global_Load(true, LastActiveProjects.projectTabs[p], #LastActiveProjects.projectTabs) end
      elseif RMBmenu == 3 then 
        RL.showLastActiveProjects = true
        FillLastActiveProjects(false)
    end
  end
end

----------------------------------
-- Custom project button functions
----------------------------------
local function Load_CustomProject_Base(tabmode)
  if GetMainListSize()> 0 then
    local vals = GetSelectionTable(GUI.Val("tab_customProjects_listbox"))
    for p = 1, #vals do
      if FilterActive.CustomProjects then Global_Load(tabmode, CustomProjects.filteredItems[vals[p]].path, p)
      else Global_Load(tabmode, CustomProjects.items[vals[p]].path, p) end
      
    end

    GUI.Val("tab_customProjects_listbox",{})
    Global_CheckWindowPinState()
  end
end

local function Load_CustomProject()
  Load_CustomProject_Base(false)
end

local function LoadInTab_CustomProject()
  Load_CustomProject_Base(true)
end

---------------------------
-- Project Template buttons
---------------------------
local function Load_ProjectTemplate_Base(tabmode)
  if GetMainListSize() > 0 then
    local vals = GetSelectionTable(GUI.Val("tab_projectTemplates_listbox"))
    for p = 1, #vals do
      if FilterActive.ProjectTemplates then
        if tabmode then
          reaper.Main_OnCommand(41929, 0) -- New project tab (ignore default template)
          Global_ProjectTemplateLoadBase(ProjectTemplates.filteredItems[vals[p]].path)
        else
          Global_ProjectTemplateLoad(ProjectTemplates.filteredItems[vals[p]].path, p)
        end
      else
        if tabmode then
          reaper.Main_OnCommand(41929, 0) -- New project tab (ignore default template)
          Global_ProjectTemplateLoadBase(ProjectTemplates.items[vals[p]].path)
        else
          Global_ProjectTemplateLoad(ProjectTemplates.items[vals[p]].path, p)
        end
      end
    end
    GUI.Val("tab_projectTemplates_listbox",{})
    Global_TriggerFollowAction("actions_txtFollowAction_LoadProjectTemplate")
    Global_CheckWindowPinState()
  end
end

local function Load_ProjectTemplate()
  Load_ProjectTemplate_Base(false)
end

local function LoadInTab_ProjectTemplate()
  Load_ProjectTemplate_Base(true)
end

----------------------------------
-- Track Template button functions
----------------------------------
local function Load_TrackTemplate_Base(tabmode)
  if GetMainListSize() > 0 then
    local selectedTrackTemplate
    local vals = GetSelectionTable(GUI.Val("tab_trackTemplates_listbox"))
    for p = 1, #vals do
      if FilterActive.TrackTemplates then selectedTrackTemplate = TrackTemplates.filteredItems[vals[p]].path
      else selectedTrackTemplate = TrackTemplates.items[vals[p]].path end
      if selectedTrackTemplate ~= nil then
        if tabmode then reaper.Main_OnCommand(41929, 0) end -- New project tab (ignore default template)
        reaper.Main_openProject(selectedTrackTemplate)
      end
    end
    Global_TriggerFollowAction("actions_txtFollowAction_InsertTrackTemplate")
    Global_CheckWindowPinState()
  end
end

local function Load_TrackTemplateInTab()
  Load_TrackTemplate_Base(true)
end

local function Load_TrackTemplate()
  Load_TrackTemplate_Base(false)
end

--------------------------------
-- Project List button functions
--------------------------------
local function Load_ProjectListProject_Base(tabmode)
  if GetMainListSize() > 0 then
    local vals = GetSelectionTable(GUI.Val("tab_projectLists_listboxProjects"))
    for p = 1, #vals do
      if FilterActive.ProjectLists then Global_Load(tabmode, RemoveWhiteSpaces(ProjectLists.filteredProjectItems[vals[p]].path), p)
      else Global_Load(tabmode, RemoveWhiteSpaces(ProjectLists.projectItems[vals[p]].path), p) end
    end
    GUI.Val("tab_projectLists_listboxProjects",{})
    Global_CheckWindowPinState()
  end
end

local function Load_ProjectListProject()
  Load_ProjectListProject_Base(false)
end

local function LoadInTab_ProjectListProject()
  Load_ProjectListProject_Base(true)
end

---------------------------------
--- Backups List button functions
---------------------------------
local function Load_BackupFile_Base(tabmode)
  if GetMainListSize() > 0 then
    local vals = GetSelectionTable(GUI.Val("tab_backups_listbox"))
    for p = 1, #vals do
      if FilterActive.Backups then Global_Load(tabmode, RemoveWhiteSpaces(Backups.filteredItems[vals[p]].path), p) 
      else Global_Load(tabmode, RemoveWhiteSpaces(Backups.items[vals[p]].path), p) end
    end
    GUI.Val("tab_backups_listbox",{})
    Global_CheckWindowPinState()
  end
end

local function Load_BackupFile()
  Load_BackupFile_Base(false)
end

local function LoadInTab_BackupFile()
  Load_BackupFile_Base(true)
end

--------------------
--- Scroll functions
--------------------
local function ScrollToTop(element)
  if element ~= nil and element.wnd_h ~= nil and element.wnd_y ~= nil then
    element.wnd_y = GUI.clamp(1, element.wnd_y - element.wnd_h, math.max(#element.list - element.wnd_h + 1, 1))
    element:redraw()
  end
end

local function ScrollToBottom(element)
  if element ~= nil and element.wnd_h ~= nil and element.wnd_y ~= nil then
    element.wnd_y = GUI.clamp(#element.list, element.wnd_h - element.wnd_y, math.max(#element.list - element.wnd_h + 1, 1))
    element:redraw()
  end
end

local function Scroll(element, listIndex, direction)
  if element and element.wnd_h ~= nil and element.wnd_y ~= nil then
    if listIndex > (element.wnd_h - 2) then
      element.wnd_y = GUI.clamp(1, element.wnd_y + direction, math.max(#element.list - element.wnd_h + 1, 1))
    elseif listIndex > 4 then
      element.wnd_y = GUI.clamp(1, element.wnd_y - element.wnd_h, math.max(#element.list - element.wnd_h + 1, 1))
    end
    element:redraw()
  end
end

-------------------
-- Filter functions
-------------------
FilterActive = {
  RecentProjects = false,
  ProjectTemplates = false,
  TrackTemplates = false,
  CustomProjects = false,
  ProjectLists = false,
  Backups = false,
  Docs = false,
  Favorites = false
}

FilterColor = {
  active = "elm_fill",
  inactive = "txt"
}

local function escapeSpecialCharacters(x)
  return (x:gsub('%%', '%%%%')
           :gsub('^%^', '%%^')
           :gsub('%$$', '%%$')
           :gsub('%(', '%%(')
           :gsub('%)', '%%)')
           :gsub('%.', '%%.')
           :gsub('%[', '%%[')
           :gsub('%]', '%%]')
           :gsub('%*', '%%*')
           :gsub('%+', '%%+')
           :gsub('%-', '%%-')
           :gsub('%?', '%%?'))
end

local replaceMatchString = function (c)
  return "[" .. string.lower(c) .. string.upper(c) .. "]"
end

local function GetSearchTable(searchString)
  local searchTable = {}
  for match in string.gmatch(searchString, "[^%s]+") do -- space separator
    searchTable[#searchTable + 1] = string.gsub(escapeSpecialCharacters(match), "%a", replaceMatchString)
  end
  return searchTable
end

-------------------------
-- Filter Recent Projects
-------------------------
local function Filter_RecentProject_Apply()
  RecentProjects.filteredItems, RecentProjects.filteredDisplay = {}, {}
  local searchList, searchStr = {}, GUI.Val("tab_recentProjects_txtFilter")
  if #searchStr > 0 then
    FilterActive.RecentProjects = true
    GUI.elms.tab_recentProjects_txtFilter.color, GUI.elms.tab_recentProjects_btnFilterClear.color = FilterColor.active, FilterColor.active
    GUI.elms.tab_recentProjects_btnFilterClear:init()

    if #RecentProjects.display > 0 then searchList = RecentProjects.display
    else if RL.showFullPaths then searchList = GetSubTableByPathKey(RecentProjects.items) else searchList = GetSubTableByNameKey(RecentProjects.items) end end

    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          if not CheckForDuplicates(GetSubTableByNameKey(RecentProjects.filteredItems), RecentProjects.items[i].name) then
            RecentProjects.filteredItems[#RecentProjects.filteredItems + 1] = {
              name = RecentProjects.items[i].name,
              path = RecentProjects.items[i].path,
              date = GetLastModifiedDate(RecentProjects.items[i].path)
            }
          end
        end
      end
    end
  else
    FilterActive.RecentProjects = false
    GUI.elms.tab_recentProjects_txtFilter.color, GUI.elms.tab_recentProjects_btnFilterClear.color = FilterColor.inactive, FilterColor.inactive
    GUI.elms.tab_recentProjects_btnFilterClear:init()
  end
  Global_UpdateListDisplay()
  ShowFileCount()
  GUI.Val("tab_recentProjects_listbox",{})
  ScrollToTop(ListBoxElements[GUI.elms.main_tabs.state])
end

local function Filter_RecentProject_Clear()
  GUI.Val("tab_recentProjects_txtFilter", "")
  Filter_RecentProject_Apply()
end

---------------------------
-- Filter Project Templates
---------------------------
local function Filter_ProjectTemplate_Apply()
  ProjectTemplates.filteredItems, ProjectTemplates.filteredDisplay = {}, {}
  local searchList, searchStr = {}, GUI.Val("tab_projectTemplates_txtFilter")
  if #searchStr > 0 then
    FilterActive.ProjectTemplates = true
    GUI.elms.tab_projectTemplates_txtFilter.color, GUI.elms.tab_projectTemplates_btnFilterClear.color = FilterColor.active, FilterColor.active
    GUI.elms.tab_projectTemplates_btnFilterClear:init()
    
    if #ProjectTemplates.display > 0 then searchList = ProjectTemplates.display
    else if RL.showFullPaths then searchList = GetSubTableByPathKey(ProjectTemplates.items) else searchList = GetSubTableByNameKey(ProjectTemplates.items) end end
    
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          if not CheckForDuplicates(GetSubTableByNameKey(ProjectTemplates.filteredItems), ProjectTemplates.items[i].name) then
            ProjectTemplates.filteredItems[#ProjectTemplates.filteredItems + 1] = {
              name = ProjectTemplates.items[i].name,
              path = ProjectTemplates.items[i].path,
              date = GetLastModifiedDate(ProjectTemplates.items[i].path)
            }
          end
        end
      end
    end
  else
    FilterActive.ProjectTemplates = false
    GUI.elms.tab_projectTemplates_txtFilter.color, GUI.elms.tab_projectTemplates_btnFilterClear.color = FilterColor.inactive, FilterColor.inactive
    GUI.elms.tab_projectTemplates_btnFilterClear:init()
  end
  Global_UpdateListDisplay()
  ShowFileCount()
  GUI.Val("tab_projectTemplates_listbox",{})
  ScrollToTop(ListBoxElements[GUI.elms.main_tabs.state])
end

local function Filter_ProjectTemplate_Clear()
  GUI.Val("tab_projectTemplates_txtFilter", "")
  Filter_ProjectTemplate_Apply()
end

-------------------------
-- Filter Track Templates
-------------------------
local function Filter_TrackTemplate_Apply()
  TrackTemplates.filteredItems, TrackTemplates.filteredDisplay = {}, {}
  local searchList, searchStr = {}, GUI.Val("tab_trackTemplates_txtFilter")
  if #searchStr > 0 then
    FilterActive.TrackTemplates = true
    GUI.elms.tab_trackTemplates_txtFilter.color, GUI.elms.tab_trackTemplates_btnFilterClear.color = FilterColor.active, FilterColor.active
    GUI.elms.tab_trackTemplates_btnFilterClear:init()

    if #TrackTemplates.display > 0 then searchList = TrackTemplates.display
    else if RL.showFullPaths then searchList = GetSubTableByPathKey(TrackTemplates.items) else searchList = GetSubTableByNameKey(TrackTemplates.items) end end
    
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          if not CheckForDuplicates(GetSubTableByNameKey(TrackTemplates.filteredItems), TrackTemplates.items[i].name) then
            TrackTemplates.filteredItems[#TrackTemplates.filteredItems + 1] = {
              name = TrackTemplates.items[i].name,
              path = TrackTemplates.items[i].path,
              date = GetLastModifiedDate(TrackTemplates.items[i].path)
            }
          end
        end
      end
    end
  else
    FilterActive.TrackTemplates = false
    GUI.elms.tab_trackTemplates_txtFilter.color, GUI.elms.tab_trackTemplates_btnFilterClear.color = FilterColor.inactive, FilterColor.inactive
    GUI.elms.tab_trackTemplates_btnFilterClear:init()
  end
  Global_UpdateListDisplay()
  ShowFileCount()
  GUI.Val("tab_trackTemplates_listbox",{})
  ScrollToTop(ListBoxElements[GUI.elms.main_tabs.state])
end

local function Filter_TrackTemplate_Clear()
  GUI.Val("tab_trackTemplates_txtFilter", "")
  Filter_TrackTemplate_Apply()
end

------------------
-- Filter Projects
------------------
local function Filter_CustomProjects_Apply()
  CustomProjects.filteredItems, CustomProjects.filteredDisplay = {}, {}
  local searchList, searchStr = {}, GUI.Val("tab_customProjects_txtFilter")
  if #searchStr > 0 then
    FilterActive.CustomProjects = true
    GUI.elms.tab_customProjects_txtFilter.color, GUI.elms.tab_customProjects_btnFilterClear.color = FilterColor.active, FilterColor.active
    GUI.elms.tab_customProjects_btnFilterClear:init()

    if #CustomProjects.display > 0 then searchList = CustomProjects.display
    else if RL.showFullPaths then searchList = GetSubTableByPathKey(CustomProjects.items) else searchList = GetSubTableByNameKey(CustomProjects.items) end end
    
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          if not CheckForDuplicates(GetSubTableByNameKey(CustomProjects.filteredItems), CustomProjects.items[i].name) then
            CustomProjects.filteredItems[#CustomProjects.filteredItems + 1] = {
              name = CustomProjects.items[i].name,
              path = CustomProjects.items[i].path,
              date = GetLastModifiedDate(CustomProjects.items[i].path)
            }
          end
        end
      end
    end
  else
    FilterActive.CustomProjects = false
    GUI.elms.tab_customProjects_txtFilter.color, GUI.elms.tab_customProjects_btnFilterClear.color = FilterColor.inactive, FilterColor.inactive
    GUI.elms.tab_customProjects_btnFilterClear:init()
  end
  Global_UpdateListDisplay()
  ShowFileCount()
  GUI.Val("tab_customProjects_listbox",{})
  ScrollToTop(ListBoxElements[GUI.elms.main_tabs.state])
end

local function Filter_CustomProjects_Clear()
  GUI.Val("tab_customProjects_txtFilter", "")
  Filter_CustomProjects_Apply()
end

-----------------------
-- Filter Project Lists
-----------------------
local function Filter_ProjectLists_Apply()
  ProjectLists.filteredProjectItems, ProjectLists.filteredDisplay = {}, {}
  local searchList, searchStr = {}, GUI.Val("tab_projectLists_txtFilter")
  if #searchStr > 0 then
    FilterActive.ProjectLists = true
    GUI.elms.tab_projectLists_txtFilter.color, GUI.elms.tab_projectLists_btnFilterClear.color = FilterColor.active, FilterColor.active
    GUI.elms.tab_projectLists_btnFilterClear:init()
    
    if #ProjectLists.display > 0 then searchList = ProjectLists.display
    else if RL.showFullPaths then searchList = GetSubTableByPathKey(ProjectLists.projectItems) else searchList = GetSubTableByNameKey(ProjectLists.projectItems) end end
    
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          if not CheckForDuplicates(GetSubTableByNameKey(ProjectLists.filteredProjectItems), ProjectLists.projectItems[i].name) then
            ProjectLists.filteredProjectItems[#ProjectLists.filteredProjectItems + 1] = {
              name = ProjectLists.projectItems[i].name,
              path = ProjectLists.projectItems[i].path,
              date = GetLastModifiedDate(ProjectLists.projectItems[i].path) }
          end
        end
      end
    end
  else
    FilterActive.ProjectLists = false
    GUI.elms.tab_projectLists_txtFilter.color, GUI.elms.tab_projectLists_btnFilterClear.color = FilterColor.inactive, FilterColor.inactive
    GUI.elms.tab_projectLists_btnFilterClear:init()
  end
  Global_UpdateListDisplay()
  ShowFileCount()
  GUI.Val("tab_projectLists_listboxProjects",{})
  ScrollToTop(ListBoxElements[GUI.elms.main_tabs.state])
end

local function Filter_ProjectLists_Clear()
  GUI.Val("tab_projectLists_txtFilter", "")
  Filter_ProjectLists_Apply()
end

-----------------
-- Filter Backups
-----------------
local function Filter_Backups_Apply()
  Backups.filteredItems, Backups.filteredDisplay = {}, {}
  local searchList, searchStr = {}, GUI.Val("tab_backups_txtFilter")
  if #searchStr > 0 then
    FilterActive.Backups = true
    GUI.elms.tab_backups_txtFilter.color, GUI.elms.tab_backups_btnFilterClear.color = FilterColor.active, FilterColor.active
    GUI.elms.tab_backups_btnFilterClear:init()

    if #Backups.display > 0 then searchList = Backups.display
    else if RL.showFullPaths then searchList = GetSubTableByPathKey(Backups.items) else searchList = GetSubTableByNameKey(Backups.items) end end

    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          if not CheckForDuplicates(GetSubTableByNameKey(Backups.filteredItems), Backups.items[i].name) then
            Backups.filteredItems[#Backups.filteredItems + 1] = {
              name = Backups.items[i].name,
              path = Backups.items[i].path,
              date = GetLastModifiedDate(Backups.items[i].path)
            }
          end
        end
      end
    end
  else
    FilterActive.Backups = false
    GUI.elms.tab_backups_txtFilter.color, GUI.elms.tab_backups_btnFilterClear.color = FilterColor.inactive, FilterColor.inactive
    GUI.elms.tab_backups_btnFilterClear:init()
  end
  Global_UpdateListDisplay()
  ShowFileCount()
  GUI.Val("tab_backups_listbox",{})
  ScrollToTop(ListBoxElements[GUI.elms.main_tabs.state])
end

local function Filter_Backups_Clear()
  GUI.Val("tab_backups_txtFilter", "")
  Filter_Backups_Apply()
end

--------------
-- Filter Docs
--------------
local function Filter_Docs_Apply()
  Docs.filteredItems, Docs.filteredDisplay = {}, {}
  local searchList, searchStr = {}, GUI.Val("tab_docs_txtFilter")
  if #searchStr > 0 then
    FilterActive.Docs = true
    GUI.elms.tab_docs_txtFilter.color, GUI.elms.tab_docs_btnFilterClear.color = FilterColor.active, FilterColor.active
    GUI.elms.tab_docs_btnFilterClear:init()

    if #Docs.display > 0 then searchList = Docs.display
    else if RL.showFullPaths then searchList = GetSubTableByPathKey(Docs.items) else searchList = GetSubTableByNameKey(Docs.items) end end
    
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          if not CheckForDuplicates(GetSubTableByNameKey(Docs.filteredItems), Docs.items[i].name) then
            Docs.filteredItems[#Docs.filteredItems + 1] = {
              name = Docs.items[i].name,
              path = Docs.items[i].path,
              date = GetLastModifiedDate(Docs.items[i].path)
            }
          end
        end
      end
    end
  else
    FilterActive.Docs = false
    GUI.elms.tab_docs_txtFilter.color, GUI.elms.tab_docs_btnFilterClear.color = FilterColor.inactive, FilterColor.inactive
    GUI.elms.tab_docs_btnFilterClear:init()
  end
  Global_UpdateListDisplay()
  ShowFileCount()
  GUI.Val("tab_docs_listbox",{})
  ScrollToTop(ListBoxElements[GUI.elms.main_tabs.state])
end

local function Filter_Docs_Clear()
  GUI.Val("tab_docs_txtFilter", "")
  Filter_Docs_Apply()
end

-------------------
-- Filter Favorites
-------------------
local function Filter_Favorites_Apply()
  Favorites.filteredItems, Favorites.filteredDisplay = {}, {}
  local searchList, searchStr = {}, GUI.Val("tab_favorites_txtFilter")
  if #searchStr > 0 then
    FilterActive.Favorites = true
    GUI.elms.tab_favorites_txtFilter.color, GUI.elms.tab_favorites_btnFilterClear.color = FilterColor.active, FilterColor.active
    GUI.elms.tab_favorites_btnFilterClear:init()
    
    if #Favorites.display > 0 then searchList = Favorites.display
    else if RL.showFullPaths then searchList = GetSubTableByPathKey(Favorites.items) else searchList = GetSubTableByNameKey(Favorites.items) end end
    
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          if not CheckForDuplicates(GetSubTableByNameKey(Favorites.filteredItems), Favorites.items[i].name) then
            Favorites.filteredItems[#Favorites.filteredItems + 1] = {
              name = Favorites.items[i].name,
              path = Favorites.items[i].path,
              date = GetLastModifiedDate(Favorites.items[i].path)
            }
          end
        end
      end
    end
  else
    FilterActive.Favorites = false
    GUI.elms.tab_favorites_txtFilter.color, GUI.elms.tab_favorites_btnFilterClear.color = FilterColor.inactive, FilterColor.inactive
    GUI.elms.tab_favorites_btnFilterClear:init()
  end
  Global_UpdateListDisplay()
  ShowFileCount()
  GUI.Val("tab_favorites_listbox",{})
  ScrollToTop(ListBoxElements[GUI.elms.main_tabs.state])
end

local function Filter_Favorites_Clear()
  GUI.Val("tab_favorites_txtFilter", "")
  Filter_Favorites_Apply()
end

function Global_UpdateFilter()
  if not RL.skipOperationOnResize then 
    if GUI.elms.main_tabs.state == TabID.RecentProjects then Filter_RecentProject_Apply()
      elseif GUI.elms.main_tabs.state == TabID.ProjectTemplates then Filter_ProjectTemplate_Apply()
      elseif GUI.elms.main_tabs.state == TabID.TrackTemplates then Filter_TrackTemplate_Apply()
      elseif GUI.elms.main_tabs.state == TabID.CustomProjects then Filter_CustomProjects_Apply()
      elseif GUI.elms.main_tabs.state == TabID.ProjectLists then Filter_ProjectLists_Apply()
      elseif GUI.elms.main_tabs.state == TabID.Backups then Filter_Backups_Apply()
      elseif GUI.elms.main_tabs.state == TabID.Docs then Filter_Docs_Apply()
      elseif GUI.elms.main_tabs.state == TabID.Favorites then Filter_Favorites_Apply()
    end
  end
end

local function RL_Keys_ClearFilter()
  if GUI.elms.main_tabs.state == TabID.RecentProjects then Filter_RecentProject_Clear()
    elseif GUI.elms.main_tabs.state == TabID.ProjectTemplates then Filter_ProjectTemplate_Clear()
    elseif GUI.elms.main_tabs.state == TabID.TrackTemplates then Filter_TrackTemplate_Clear()
    elseif GUI.elms.main_tabs.state == TabID.CustomProjects then Filter_CustomProjects_Clear()
    elseif GUI.elms.main_tabs.state == TabID.ProjectLists then Filter_ProjectLists_Clear()
    elseif GUI.elms.main_tabs.state == TabID.Backups then Filter_Backups_Clear()
    elseif GUI.elms.main_tabs.state == TabID.Docs then Filter_Docs_Clear()
    elseif GUI.elms.main_tabs.state == TabID.Favorites then Filter_Favorites_Clear()
  end
end

function RebuildCache()
  MsgDebug("-------- Cache rebuild: started --------")
  RL_Func_RebuildCache[GUI.elms.main_tabs.state].call()
  Global_UpdateSortMode()
  MsgDebug("-------- Cache rebuild: finished --------")
end

----------------------------
-- Listbox Refresh functions
----------------------------
function RefreshRecentProjects(listInReverse)
  RL.showLastActiveProjects = false
  if SWSinstalled then
    GUI.elms.tab_recentProjects_btnLastActiveProject.color = FilterColor.inactive
    GUI.elms.tab_recentProjects_btnLastActiveProject:redraw()
    GUI.elms.tab_recentProjects_btnLastActiveProject:init()
    if listInReverse then 
      MsgDebug("\nRefresh Recent Projects - oldest first")
      FillRecentProjectsListbox(false)
    else
      MsgDebug("\nRefresh Recent Projects - newest first")
      FillRecentProjectsListbox(true)
    end
  else MsgStatusBar("This tab requires SWS Extensions") end
end

local function RefreshProjectTemplates()
  MsgDebug("\nRefresh Project Templates")
  if ShowSubfolderPanel(TabID.ProjectTemplates) then
    local cacheExists, cacheTable = RL_ReadFromSubfolderCache(SubpanelFile.ProjectTemplates, SubpanelFile.MainSection)
    if cacheExists then
      SubfolderPaths.projectTemplates, SubfolderNames.projectTemplates = {"< All >"}, {"< All >"}
      for c = 1, #cacheTable do
        SubfolderPaths.projectTemplates[#SubfolderPaths.projectTemplates + 1] = cacheTable[c]
        if IsNotNullOrEmpty(CustomPaths.ProjectTemplates) then
          local multiPaths = SplitMultiPaths(CustomPaths.ProjectTemplates)
          local foundMatchingFolderName = false
          for m = 1, #multiPaths do if cacheTable[c] == multiPaths[m] then foundMatchingFolderName = true break end end
          if foundMatchingFolderName or c == 1 then SubfolderNames.projectTemplates[#SubfolderNames.projectTemplates + 1] = "< " .. GetFolderName(cacheTable[c]) .. " >"
          else SubfolderNames.projectTemplates[#SubfolderNames.projectTemplates + 1] = RL.subfolderIndent .. GetFolderName(cacheTable[c]) end
        else
          SubfolderPaths.projectTemplates, SubfolderNames.projectTemplates = GetSubFolderEntries(projectTemplatePath, CustomPaths.ProjectTemplates, TabID.ProjectTemplates, FileTypes.rpp)
          if not RL.showSubFolderPaths then GUI.elms.tab_projectTemplates_subfolders.list = SubfolderNames.projectTemplates
          else GUI.elms.tab_projectTemplates_subfolders.list = SubfolderPaths.projectTemplates end
        end
      end
    else
      SubfolderPaths.projectTemplates, SubfolderNames.projectTemplates = GetSubFolderEntries(projectTemplatePath, CustomPaths.ProjectTemplates, TabID.ProjectTemplates, FileTypes.rpp)
      if not RL.showSubFolderPaths then GUI.elms.tab_projectTemplates_subfolders.list = SubfolderNames.projectTemplates
      else GUI.elms.tab_projectTemplates_subfolders.list = SubfolderPaths.projectTemplates end
      RL_WriteToSubfolderCache(SubpanelFile.ProjectTemplates, SubpanelFile.MainSection, SubfolderPaths.projectTemplates)
    end
    
    Global_UpdateSubfolderPathDisplay()
    GUI.Val("tab_projectTemplates_subfolders", TabParentSelectionIndex[TabID.ProjectTemplates])
    UpdateProjectTemplateSubDirSelection()
  else
    FillProjectTemplateListbox()
  end
  ShowFileCount()
end

local function RefreshTrackTemplates()
  MsgDebug("\nRefresh Track Templates")
  if ShowSubfolderPanel(TabID.TrackTemplates) then
    local cacheExists, cacheTable = RL_ReadFromSubfolderCache(SubpanelFile.TrackTemplates, SubpanelFile.MainSection)
    if cacheExists then
      SubfolderPaths.trackTemplates, SubfolderNames.trackTemplates = {"< All >"}, {"< All >"}
      for c = 1, #cacheTable do
        SubfolderPaths.trackTemplates[#SubfolderPaths.trackTemplates + 1] = cacheTable[c]
        if IsNotNullOrEmpty(CustomPaths.TrackTemplates) then
          local multiPaths = SplitMultiPaths(CustomPaths.TrackTemplates)
          local foundMatchingFolderName = false
          for m = 1, #multiPaths do if cacheTable[c] == multiPaths[m] then foundMatchingFolderName = true break end end
          if foundMatchingFolderName or c == 1 then SubfolderNames.trackTemplates[#SubfolderNames.trackTemplates + 1] = "< " .. GetFolderName(cacheTable[c]) .. " >"
          else SubfolderNames.trackTemplates[#SubfolderNames.trackTemplates + 1] = RL.subfolderIndent .. GetFolderName(cacheTable[c]) end
        else
          SubfolderPaths.trackTemplates, SubfolderNames.trackTemplates = GetSubFolderEntries(trackTemplatePath, CustomPaths.TrackTemplates, TabID.TrackTemplates, FileTypes.tracktemplate)
          if not RL.showSubFolderPaths then GUI.elms.tab_trackTemplates_subfolders.list = SubfolderNames.trackTemplates
          else GUI.elms.tab_trackTemplates_subfolders.list = SubfolderPaths.trackTemplates end
        end
      end
    else
      SubfolderPaths.trackTemplates, SubfolderNames.trackTemplates = GetSubFolderEntries(trackTemplatePath, CustomPaths.TrackTemplates, TabID.TrackTemplates, FileTypes.tracktemplate)
      if not RL.showSubFolderPaths then GUI.elms.tab_trackTemplates_subfolders.list = SubfolderNames.trackTemplates
      else GUI.elms.tab_trackTemplates_subfolders.list = SubfolderPaths.trackTemplates end
      RL_WriteToSubfolderCache(SubpanelFile.TrackTemplates, SubpanelFile.MainSection, SubfolderPaths.trackTemplates)
    end

    Global_UpdateSubfolderPathDisplay()
    GUI.Val("tab_trackTemplates_subfolders", TabParentSelectionIndex[TabID.TrackTemplates])
    UpdateTrackTemplateSubDirSelection()
  else
    FillTrackTemplateListbox()
  end
  ShowFileCount()
end

local function RefreshCustomProjects()
  MsgDebug("\nRefresh Projects")
  if IsNotNullOrEmpty(CustomPaths.Projects) then
    if ShowSubfolderPanel(TabID.CustomProjects) and #CustomPaths.Projects > 1 then
      local cacheExists, cacheTable = RL_ReadFromSubfolderCache(SubpanelFile.CustomProjects, SubpanelFile.MainSection)
      if cacheExists then
        SubfolderPaths.customProjects, SubfolderNames.customProjects = {"< All >"}, {"< All >"}
        for c = 1, #cacheTable do
          SubfolderPaths.customProjects[#SubfolderPaths.customProjects + 1] = cacheTable[c]
          local multiPaths = SplitMultiPaths(CustomPaths.Projects)
          local foundMatchingFolderName = false
          for m = 1, #multiPaths do if cacheTable[c] == multiPaths[m] then foundMatchingFolderName = true break end end
          if foundMatchingFolderName or c == 1 then SubfolderNames.customProjects[#SubfolderNames.customProjects + 1] = "< " .. GetFolderName(cacheTable[c]) .. " >"
          else SubfolderNames.customProjects[#SubfolderNames.customProjects + 1] = RL.subfolderIndent .. GetFolderName(cacheTable[c]) end
        end
      else
        SubfolderPaths.customProjects, SubfolderNames.customProjects = GetSubFolderEntries("All", CustomPaths.Projects, TabID.CustomProjects, FileTypes.rpp)
        if not RL.showSubFolderPaths then GUI.elms.tab_customProjects_subfolders.list = SubfolderNames.customProjects 
        else GUI.elms.tab_customProjects_subfolders.list = SubfolderPaths.customProjects end
        RL_WriteToSubfolderCache(SubpanelFile.CustomProjects, SubpanelFile.MainSection, SubfolderPaths.customProjects)
      end

      Global_UpdateSubfolderPathDisplay()
      GUI.Val("tab_customProjects_subfolders", TabParentSelectionIndex[TabID.CustomProjects])
      UpdateCustomProjectSubDirSelection()
    else
      FillCustomProjectsListbox()
    end
    ShowFileCount()
  else
    MsgStatusBar("No Paths set for Projects")
  end
end

local function RefreshProjectList()
  MsgDebug("\nRefresh Project Lists")
  if #CustomPaths.ProjectLists > 1 then
    ProjectLists.projectItems = {}
    ProjectLists.rplPaths, ProjectLists.rplFiles = {"< All >"}, {"< All >"}
    local cacheExists, cacheTable = RL_ReadFromSubfolderCache(SubpanelFile.ProjectLists, SubpanelFile.MainSection)
    if cacheExists then
      for c = 1, #cacheTable do
        ProjectLists.rplFiles[#ProjectLists.rplFiles + 1] = RemoveExtension(GetFilenameWithoutPath(cacheTable[c]), FileTypes.rpl)
        ProjectLists.rplPaths[#ProjectLists.rplPaths + 1] = GetDirectoryPath(cacheTable[c])
      end
    else
      local subfolderCacheFiles = {}
      local multiPaths = SplitMultiPaths(CustomPaths.ProjectLists)
      for m = 1, #multiPaths do 
        local projectListFiles = GetFiles(multiPaths[m], TabID.ProjectLists, FileTypes.rpl)
        for i = 1, #projectListFiles do
          subfolderCacheFiles[#subfolderCacheFiles + 1] = projectListFiles[i]
          if ConfigFlags.listFilesInDebugMessages then MsgDebug(projectListFiles[i]) end
          local rplName = RemoveExtension(GetFilenameWithoutPath(projectListFiles[i]), FileTypes.rpl)
          if IsNotNullOrEmpty(rplName) then
            ProjectLists.rplFiles[#ProjectLists.rplFiles + 1] = rplName
            ProjectLists.rplPaths[#ProjectLists.rplPaths + 1] = GetDirectoryPath(projectListFiles[i])
          end
        end
      end
      RL_WriteToSubfolderCache(SubpanelFile.ProjectLists, SubpanelFile.MainSection, subfolderCacheFiles)
    end
   
    if ShowSubfolderPanel(TabID.ProjectLists) then
      GUI.elms.tab_projectLists_listboxRPL.list = ProjectLists.rplFiles
      GUI.Val("tab_projectLists_listboxRPL", TabParentSelectionIndex[TabID.ProjectLists])
      if RL.sortModeIndex[GUI.elms.main_tabs.state] == 2 then UpdateProjectListSelection(true) else UpdateProjectListSelection(false) end
    else
      local allRPLProjects = {}
      for v = 2, #ProjectLists.rplFiles do allRPLProjects[v - 1] = v end
      RPL_ParseRPLFile(allRPLProjects, false)
      TabSelectionIndex[TabID.ProjectLists] = 1
      GUI.Val("tab_projectLists_listboxProjects", {1})
      Global_UpdateListDisplay()
      ShowFileCount()
    end
  else
    MsgStatusBar("No Paths set for Project Lists")
  end
end

local function RefreshBackups()
  MsgDebug("\nRefresh Backups")
  if IsNotNullOrEmpty(CustomPaths.Backups) then
    if ShowSubfolderPanel(TabID.Backups) and #CustomPaths.Backups > 1 then
      local cacheExists, cacheTable = RL_ReadFromSubfolderCache(SubpanelFile.Backups, SubpanelFile.MainSection)
      if cacheExists then
        SubfolderPaths.backups, SubfolderNames.backups = {"< All >"}, {"< All >"}
        for c = 1, #cacheTable do
          SubfolderPaths.backups[#SubfolderPaths.backups + 1] = cacheTable[c]
          local multiPaths = SplitMultiPaths(CustomPaths.Backups)
          local foundMatchingFolderName = false
          for m = 1, #multiPaths do if cacheTable[c] == multiPaths[m] then foundMatchingFolderName = true break end end
          if foundMatchingFolderName or c == 1 then SubfolderNames.backups[#SubfolderNames.backups + 1] = "< " .. GetFolderName(cacheTable[c]) .. " >"
          else SubfolderNames.backups[#SubfolderNames.backups + 1] = RL.subfolderIndent .. GetFolderName(cacheTable[c]) end
        end
      else
        SubfolderPaths.backups, SubfolderNames.backups = GetSubFolderEntries("All", CustomPaths.Backups, TabID.Backups, FileTypes.backup)
        if not RL.showSubFolderPaths then GUI.elms.tab_backups_subfolders.list = SubfolderNames.backups
        else GUI.elms.tab_backups_subfolders.list = SubfolderPaths.backups end
        RL_WriteToSubfolderCache(SubpanelFile.Backups, SubpanelFile.MainSection, SubfolderPaths.backups)
      end

      Global_UpdateSubfolderPathDisplay()
      GUI.Val("tab_backups_subfolders", TabParentSelectionIndex[TabID.Backups])
      UpdateBackupsSubDirSelection()
    else
      FillBackupsListbox()
    end
    ShowFileCount()
  else
    MsgStatusBar("No Paths set for Backups")
  end
end

local function RefreshDocs()
  if SWSinstalled then
    MsgDebug("\nRefresh Docs")
    if IsNotNullOrEmpty(CustomPaths.Docs) then
      if ShowSubfolderPanel(TabID.Docs) and #CustomPaths.Docs > 1 then
        local cacheExists, cacheTable = RL_ReadFromSubfolderCache(SubpanelFile.Docs, SubpanelFile.MainSection)
        if cacheExists then
          SubfolderPaths.docs, SubfolderNames.docs = {"< All >"}, {"< All >"}
          for c = 1, #cacheTable do
            SubfolderPaths.docs[#SubfolderPaths.docs + 1] = cacheTable[c]
            local multiPaths = SplitMultiPaths(CustomPaths.Docs)
            local foundMatchingFolderName = false
            for m = 1, #multiPaths do if cacheTable[c] == multiPaths[m] then foundMatchingFolderName = true break end end
            if foundMatchingFolderName or c == 1 then SubfolderNames.docs[#SubfolderNames.docs + 1] = "< " .. GetFolderName(cacheTable[c]) .. " >"
            else SubfolderNames.docs[#SubfolderNames.docs + 1] = RL.subfolderIndent .. GetFolderName(cacheTable[c]) end
          end
        else
          SubfolderPaths.docs, SubfolderNames.docs = GetSubFolderEntries("All", CustomPaths.Docs, TabID.Docs, FileTypes.docs)
          if not RL.showSubFolderPaths then GUI.elms.tab_docs_subfolders.list = SubfolderNames.docs
          else GUI.elms.tab_docs_subfolders.list = SubfolderPaths.docs end
          RL_WriteToSubfolderCache(SubpanelFile.Docs, SubpanelFile.MainSection, SubfolderPaths.docs)
        end
      
        Global_UpdateSubfolderPathDisplay()
        GUI.Val("tab_docs_subfolders", TabParentSelectionIndex[TabID.Docs])
        UpdateDocsSubDirSelection()
      else
        FillDocsListbox()
      end
      ShowFileCount()
    else
      MsgStatusBar("No Paths set for Docs")
    end
  else
    MsgStatusBar("This tab requires SWS Extensions")
  end
end

-------------------
-- Set custom paths
-------------------
local function Path_Set_ProjectTemplateFolder()
  if GUI.Val("paths_txtProjectTemplatesPath") == "" then
    CustomPaths.ProjectTemplates = ""
    ProjectTemplates.items = {}
    ProjectTemplates.filteredItems, ProjectTemplates.filteredDisplay = {}, {}
    GUI.Val("paths_txtProjectTemplatesPath", "")
    GUI.elms.tab_projectTemplates_listbox.list = {}
    GUI.elms.paths_txtProjectTemplatesPath.tooltip = ".RPP Project Templates\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3"
    reaper.DeleteExtState(appname, "custompath_projecttemplates", 1)
    RL_ClearFile(CacheFile.ProjectTemplates)
    RL_ClearFile(SubpanelFile.ProjectTemplates)
    MsgStatusBar("Project Templates paths removed")
  else
    reaper.SetExtState(appname, "custompath_projecttemplates", GUI.Val("paths_txtProjectTemplatesPath"), 1)
    CustomPaths.ProjectTemplates = GUI.Val("paths_txtProjectTemplatesPath")
    GUI.elms.paths_txtProjectTemplatesPath.tooltip = ".RPP Project Templates\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3\n\nCurrent: " .. GUI.Val("paths_txtProjectTemplatesPath")
    MsgStatusBar("Project Template paths set / scanned")
  end
  
  if ConfigFlags.enableFileCaching then RL_ScanProjectTemplateFiles() end
  if ConfigFlags.enableSubfolderCaching then RL_ScanProjectTemplateSubfolders() end
  RL_ShowProgressIndicator(TabID.ProjectTemplates, false)
end

local function Path_Set_TrackTemplateFolder()
  if GUI.Val("paths_txtTrackTemplatesPath") == "" then
    CustomPaths.TrackTemplates = ""
    TrackTemplates.items = {}
    TrackTemplates.filteredItems, TrackTemplates.filteredDisplay = {}, {}
    GUI.Val("paths_txtTrackTemplatesPath", "")
    GUI.elms.tab_trackTemplates_listbox.list = {}
    GUI.elms.paths_txtTrackTemplatesPath.tooltip = ".RTrackTemplate Track Templates\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3"
    reaper.DeleteExtState(appname, "custompath_tracktemplates", 1)
    RL_ClearFile(CacheFile.TrackTemplates)
    RL_ClearFile(SubpanelFile.TrackTemplates)
    MsgStatusBar("Track Templates paths removed")
  else
    reaper.SetExtState(appname, "custompath_tracktemplates", GUI.Val("paths_txtTrackTemplatesPath"), 1)
    CustomPaths.TrackTemplates = GUI.Val("paths_txtTrackTemplatesPath")
    GUI.elms.paths_txtTrackTemplatesPath.tooltip = ".RTrackTemplate Track Templates\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3\n\nCurrent: " .. GUI.Val("paths_txtTrackTemplatesPath")
    MsgStatusBar("Track Templates paths set / scanned")
  end
  
  if ConfigFlags.enableFileCaching then RL_ScanTrackTemplateFiles() end
  if ConfigFlags.enableSubfolderCaching then RL_ScanTrackTemplateSubfolders() end
  RL_ShowProgressIndicator(TabID.TrackTemplates, false)
end

local function Path_Set_CustomProjectFolder()
  if GUI.Val("paths_txtCustomProjectsPath") == "" then 
    CustomPaths.Projects = ""
    CustomProjects.items = {}
    CustomProjects.filteredItems, CustomProjects.filteredDisplay = {}, {}
    GUI.Val("paths_txtCustomProjectsPath", "")
    GUI.elms.tab_customProjects_listbox.list = {}
    GUI.elms.paths_txtCustomProjectsPath.tooltip = ".RPP Projects\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3"
    reaper.DeleteExtState(appname, "custompath_projects", 1)
    RL_ClearFile(CacheFile.CustomProjects)
    RL_ClearFile(SubpanelFile.CustomProjects)
    MsgStatusBar("Projects paths removed")
  else
    reaper.SetExtState(appname, "custompath_projects", GUI.Val("paths_txtCustomProjectsPath"), 1)
    CustomPaths.Projects = GUI.Val("paths_txtCustomProjectsPath")
    GUI.elms.paths_txtCustomProjectsPath.tooltip = ".RPP Projects\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3\n\nCurrent: " .. GUI.Val("paths_txtCustomProjectsPath")
    if ConfigFlags.enableFileCaching then RL_ScanCustomProjectFiles() end
    MsgStatusBar("Projects paths set / scanned")
  end
  
  if ConfigFlags.enableSubfolderCaching then RL_ScanCustomProjectSubfolders() end
  RL_ShowProgressIndicator(TabID.CustomProjects, false)
end

local function Path_Set_ProjectListFolder()
  if GUI.Val("paths_txtProjectsListsPath") == "" then
    CustomPaths.ProjectLists = ""
    ProjectLists.projectItems = {}
    ProjectLists.filteredProjectItems, ProjectLists.rplFiles = {}, {}
    GUI.Val("paths_txtProjectsListsPath", "")
    if GUI.elms.tab_projectLists_listboxRPL ~= nil then GUI.elms.tab_projectLists_listboxRPL.list = {} end
    GUI.elms.tab_projectLists_listboxProjects.list = {}
    GUI.elms.paths_txtProjectsListsPath.tooltip = ".RPL Project Lists\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3"
    reaper.DeleteExtState(appname, "custompath_projectlists", 1)
    RL_ClearFile(CacheFile.ProjectLists)
    RL_ClearFile(SubpanelFile.ProjectLists)
    MsgStatusBar("Project Lists paths removed")
  else
    reaper.SetExtState(appname, "custompath_projectlists", GUI.Val("paths_txtProjectsListsPath"), 1)
    CustomPaths.ProjectLists = GUI.Val("paths_txtProjectsListsPath")
    GUI.elms.paths_txtProjectsListsPath.tooltip = ".RPL Project Lists\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3\n\nCurrent: " .. GUI.Val("paths_txtProjectsListsPath")
    if ConfigFlags.enableFileCaching then RL_ScanProjectListFiles() end
    MsgStatusBar("Project Lists paths set / scanned")
  end

  if ConfigFlags.enableSubfolderCaching then RL_ScanProjectListSubfolders() end
  RL_ShowProgressIndicator(TabID.ProjectLists, false)
end

local function Path_Set_BackupsFolder()
  if GUI.Val("paths_txtBackupsPath") == "" then
    CustomPaths.Backups = ""
    Backups.items = {}
    Backups.filteredItems, Backups.filteredDisplay = {}, {}
    GUI.Val("paths_txtBackupsPath", "")
    GUI.elms.tab_backups_listbox.list = {}
    GUI.elms.paths_txtBackupsPath.tooltip = ".RPP-BAK Backups\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3"
    reaper.DeleteExtState(appname, "custompath_backups", 1)
    RL_ClearFile(CacheFile.Backups)
    RL_ClearFile(SubpanelFile.Backups)
    MsgStatusBar("Backups paths removed")
  else
    reaper.SetExtState(appname, "custompath_backups", GUI.Val("paths_txtBackupsPath"), 1)
    CustomPaths.Backups = GUI.Val("paths_txtBackupsPath")
    GUI.elms.paths_txtBackupsPath.tooltip = ".RPP-BAK Backups\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3\n\nCurrent: " .. GUI.Val("paths_txtBackupsPath")
    if ConfigFlags.enableFileCaching then RL_ScanBackupsFiles() end
    MsgStatusBar("Backups paths set / scanned")
  end

  if ConfigFlags.enableSubfolderCaching then RL_ScanBackupsSubfolders() end
  RL_ShowProgressIndicator(TabID.Backups, false)
end

local function Path_Set_DocsFolder()
  if GUI.Val("paths_txtDocsPath") == "" then
    CustomPaths.Docs = ""
    Docs.items = {}
    Docs.filteredItems, Docs.filteredDisplay = {}, {}
    GUI.Val("paths_txtDocsPath", "")
    GUI.elms.tab_docs_listbox.list = {}
    GUI.elms.paths_txtDocsPath.tooltip = ".PDF Docs\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3"
    reaper.DeleteExtState(appname, "custompath_docs", 1)
    RL_ClearFile(CacheFile.Docs)
    RL_ClearFile(SubpanelFile.Docs)
    MsgStatusBar("Docs paths removed")
  else
    reaper.SetExtState(appname, "custompath_docs", GUI.Val("paths_txtDocsPath"), 1)
    CustomPaths.Docs = GUI.Val("paths_txtDocsPath")
    GUI.elms.paths_txtDocsPath.tooltip = ".PDF Docs\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3\n\nCurrent: " .. GUI.Val("paths_txtDocsPath")
    if ConfigFlags.enableFileCaching then RL_ScanDocsFiles() end
    MsgStatusBar("Docs paths set / scanned")
  end

  if ConfigFlags.enableSubfolderCaching then RL_ScanDocsSubfolders() end
  RL_ShowProgressIndicator(TabID.Docs, false)
end

----------------
-- Layer z index
----------------
local LayerIndex = {
  Overlay = 1,
  Main = 2,
  Global = 3,
  RecentProjects = 4,
  ProjectTemplates = 5,
  TrackTemplates = 6,
  CustomProjects = 7,
  ProjectLists = 8,
  Docs = 9,
  Backups = 10,
  Favorites = 11,
  Paths = 12,
  ScanSettings = 13,
  Layout = 14,
  Actions = 15,
  Options = 16,
  Help = 17,
  SaveAsNewVersion = 18,
  SpecialOption = 19,
  VersionInfo = 20,
  OptionsMenu = 21,
  ConfirmDialogContent = 30,
  ConfirmDialogWindow = 31
}

RL = {
  activeSubPanels = {},
  dialogKeyMode = false,
  fontSizes = { 30, 18, 14, 14, 14, 12 },
  forceRescan = false,
  isNewTemplateLoadLogicSupported = false,
  keyInputActive = true,
  lastFolderPath = "",
  listboxFontSize = 14,
  minHeight = 355,
  minWidth = 532,
  projectTemplateLoadMode = 1,
  retinaMode = 0,
  saveAsNewVersionMode = 0,
  scaleFactor = 1.6,
  scaleMin = 1.0,
  scaleMax = 5.0,
  scaleStepSize = 0.2,
  showButtonPanel = true, 
  showDate = false,
  showFullPaths = false,
  showLastActiveProjects = false,
  showSubFolderPaths = false,
  showTooltips = false,
  skipOperationOnResize = false,
  sortModeIndex = { 1, 1, 1, 1, 1, 1, 1, 1 },
  subfolderIndent = "   ",
  tabSelectorStyle = 1,
  windowToggleShortcut = nil
}

if reaper.GetExtState(appname, "window_tabselectorstyle") ~= "" then
  if tonumber(reaper.GetExtState(appname, "window_tabselectorstyle")) then RL.tabSelectorStyle = tonumber(reaper.GetExtState(appname, "window_tabselectorstyle")) end
end

if reaper.GetExtState(appname, "window_showmainbuttonpanel") ~= "" then
  RL.showButtonPanel = (reaper.GetExtState(appname, "window_showmainbuttonpanel") == "true" and true or false)
end

if RL.showButtonPanel then
  RL.minWidth = 563
  if RL.tabSelectorStyle == 1 then RL.minHeight = 370 else RL.minHeight = 349 end
else
  RL.minWidth, RL.minHeight = 420, 228
end

-- check if the Reaper version number is 5.983 or higher (where the new template load logic is supported)
if IsNotNullOrEmpty(reaperversion) then 
  local majorVersionNumber = reaperversion:match("[^.]+")
  if tonumber(majorVersionNumber) and tonumber(majorVersionNumber) >= 6 then
    RL.isNewTemplateLoadLogicSupported = true
  elseif (reaperversion:match("5.99") or reaperversion:match("5.98[3-9]")) then
    RL.isNewTemplateLoadLogicSupported = true
  else
    RL.isNewTemplateLoadLogicSupported = false
  end
end

-- SWS block begin
  if SWSinstalled then
    -----------------------
    -- Theme slot functions
    -----------------------
    local ThemeSlots = {
      maxCount = 5,
      items = "----,1,2,3,4,5"
    }

    local function ThemeSlot_Setup()
      reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_SHOW_RESVIEW_THEME"), 0) -- SWS/S&M: Open/close Resources window (themes)
    end

    local function ThemeSlot_Load()
      themeslot = GUI.Val("main_menuThemeslot")
      if themeslot < 5 then reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_LOAD_THEME" .. themeslot - 1), 0) -- SWS/S&M: Resources - Load theme, slot#
      else reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_LOAD_THEMEl"), 0) end 
    end

    function RL_Draw_ThemeSlotSelector(alignment)
      if RL.showButtonPanel then 
        GUI.New("main_lblThemeslot", "Label", LayerIndex.Global, GUI.w - (140 * RL.scaleFactor) + (RL.scaleFactor * 11), footerY + (2 * RL.scaleFactor), "Reaper Theme", false, 3)
        GUI.New("main_menuThemeslot", "Menubox", LayerIndex.Global, GUI.w - (60 * RL.scaleFactor) + (RL.scaleFactor * 10), footerY + (2 * RL.scaleFactor), 34 * RL.scaleFactor, 15 * RL.scaleFactor, "", ThemeSlots.items, 8)
        GUI.elms.main_menuThemeslot.tooltip = "Set up and switch between different Reaper Theme Slots\n\nSlot number and descriptions can be set in\n[Layout / Colors]"
        GUI.elms.main_menuThemeslot.align = alignment
        
        function GUI.elms.main_menuThemeslot:onmousedown()
          GUI.Menubox.onmouseup(self)
          ThemeSlot_Load()
        end
        
        function GUI.elms.main_menuThemeslot:onwheel()
          GUI.Menubox.onwheel(self)
          ThemeSlot_Load()
        end
      end
    end

    function ThemeSlot_GetNames()
      local themeSlotNames = {}

      if GUI.Val("layout_themeslot_number") == nil then ThemeSlots.maxCount = 5
      else ThemeSlots.maxCount = GUI.Val("layout_themeslot_number") end
      for i = 1, ThemeSlots.maxCount do themeSlotNames[i] = GUI.Val("layout_themeslot_" .. i) or " " end
      
      ThemeSlots.items = " ---"
      for t = 1, ThemeSlots.maxCount do ThemeSlots.items = ThemeSlots.items .. ",  " .. t .. "   " .. themeSlotNames[t] end
      
      local themeSlotAliases = themeSlotNames[1]
      for t = 2, ThemeSlots.maxCount do themeSlotAliases = themeSlotAliases .. "," .. themeSlotNames[t] end
      
      return themeSlotAliases
    end

    local function ThemeSlot_SaveNames()
      reaper.SetExtState(appname, "themeslot_aliases", ThemeSlot_GetNames(), 1)
      RL_Draw_ThemeSlotSelector(0)
      MsgStatusBar("Theme Descriptions saved")
    end

    local function ThemeSlot_Indicator()
      local selected = tonumber(reaper.GetExtState(appname, "themeslot_max"))
      if selected == nil then selected = 5 else GUI.Val("layout_themeslot_number", selected) end
      for i = 1, 5 do ThemeSlotTextBoxes[i].color = "none" end 
      for i = 1, selected do ThemeSlotTextBoxes[i].color = "white" end
    end

    function RL_Draw_ThemeSlotOptions()
      themeslotOffset = 0
      if osversion:find("OSX") then themeslotOffset = 10 end
      
      GUI.New("layout_frame_2", "Frame", LayerIndex.Layout, 94 * RL.scaleFactor, tabSelectorPadding + themeslotOffset + 230 * RL.scaleFactor, GUI.w, 2 * RL.scaleFactor, false, true)
      GUI.New("layout_themeslot_Setup", "Button", LayerIndex.Layout, 1.6 * optionspad_left, tabSelectorPadding + themeslotOffset + 236 * RL.scaleFactor, 65 * RL.scaleFactor, 15 * RL.scaleFactor, "Theme Slots", ThemeSlot_Setup)
      GUI.New("layout_themeslot_Save", "Button", LayerIndex.Layout, 1.6 * optionspad_left + 68 * RL.scaleFactor, tabSelectorPadding + themeslotOffset + 236 * RL.scaleFactor, 35 * RL.scaleFactor, 15 * RL.scaleFactor, "Save", ThemeSlot_SaveNames)
      GUI.New("layout_themeslot_number", "Menubox", LayerIndex.Layout, 1.6 * optionspad_left + 108 * RL.scaleFactor, tabSelectorPadding + themeslotOffset + 236 * RL.scaleFactor, 38 * RL.scaleFactor, 16 * RL.scaleFactor, "", "1,2,3,4,5")
      GUI.elms.layout_themeslot_number.align = 1
      
      for i = 1, ThemeSlots.maxCount do
        GUI.New("layout_themeslot_" .. i, "Textbox", LayerIndex.Layout, 4.3 * optionspad_left, tabSelectorPadding + themeslotOffset + 210 * RL.scaleFactor + (25 * RL.scaleFactor) + (16 * (i - 1) * RL.scaleFactor), 146 * RL.scaleFactor, 15 * RL.scaleFactor, i, 8)
      end

      ThemeSlotTextBoxes = { GUI.elms.layout_themeslot_1, GUI.elms.layout_themeslot_2, GUI.elms.layout_themeslot_3, GUI.elms.layout_themeslot_4, GUI.elms.layout_themeslot_5 }
      ThemeSlot_Indicator()

      function GUI.elms.layout_themeslot_number:onmousedown()
        GUI.Menubox.onmouseup(self)
        ThemeSlot_GetNames()
        RL_Draw_ThemeSlotSelector(0)
        reaper.SetExtState(appname, "themeslot_max", tostring(GUI.Val("layout_themeslot_number")), 1)
        ThemeSlot_Indicator()
      end
      
      function GUI.elms.layout_themeslot_number:onwheel()
        GUI.Menubox.onwheel(self)
        ThemeSlot_GetNames()
        RL_Draw_ThemeSlotSelector(0)
        reaper.SetExtState(appname, "themeslot_max", tostring(GUI.Val("layout_themeslot_number")), 1)
        ThemeSlot_Indicator()
      end

      for i = 1, ThemeSlots.maxCount do
        local tSlots = GUI.elms["layout_themeslot_" .. i]
        function tSlots:onmousedown()
          GUI.Textbox.onmousedown(self)
          RL.keyInputActive = false
        end
      end

    end

    -----------------------------
    -- Recent Projects management 
    -----------------------------
    function RecentProjects_RemoveEntry()
      local removedEntries = {}
      local vals = GetSelectionTable(GUI.Val("tab_recentProjects_listbox"))
      for i = 1, #vals do
        if FilterActive.RecentProjects then selectedProject = RecentProjects.filteredItems[vals[i]].path
        else selectedProject = RecentProjects.items[vals[i]].path end

        local lastEntry = false
        local p = 0

        repeat
          p = p + 1
          local recentPathTag = "recent" .. string.format("%02d", p)
          local _, keyValue = reaper.BR_Win32_GetPrivateProfileString("recent", recentPathTag, "noEntry", reaperIniPath)
          if keyValue == "noEntry" then 
            lastEntry = true
            break
          end
          
          if keyValue == selectedProject then
            removedEntries[#removedEntries + 1] = recentPathTag
            reaper.BR_Win32_WritePrivateProfileString("Recent", recentPathTag, " ", reaperIniPath) 
            MsgDebug("Recent Projects | removed " .. recentPathTag .. " | " .. selectedProject)
          end
        until (lastEntry)
      end

      GUI.Val("tab_recentProjects_listbox", {})
      RecentProjects.items, RecentProjects.filteredItems, RecentProjects.display, RecentProjects.filteredDisplay = {}, {}, {}, {}
      RefreshRecentProjects(false)
      UpdateListDisplay_RecentProjects()
      Filter_RecentProject_Apply()
    end

    function RecentProjects_ClearList()
      for k = 1, RecentProjects.maxIndex do reaper.BR_Win32_WritePrivateProfileString("Recent", "recent" .. string.format("%02d", k), " ", reaperIniPath) end
      MsgDebug("Recent Projects | list cleared")
      RecentProjects.items, RecentProjects.filteredItems, RecentProjects.display, RecentProjects.filteredDisplay = {}, {}, {}, {}
      RefreshRecentProjects(false)
      Filter_RecentProject_Clear()
    end
  end
-- SWS block end

------------------
-- Window settings
------------------
GUI.name = "ReaLauncher"
GUI.anchor, GUI.corner = "mouse", "C" -- Center on "mouse" or "screen"
GUI.x, GUI.y = 0, 0

---------------------------------------------
-- Show version display only on specific tabs
---------------------------------------------
GUI.Draw_Version = function()
  if GUI.elms.main_tabs.state <= TabID.Favorites then return end
  GUI.font("version")
  GUI.color("txt")

  if not GUI.version then return 0 end
  str = "RL 2.5.4 | Lokasenna_GUI " .. GUI.version
  str_w, str_h = gfx.measurestr(str)
  if osversion:find("OSX") then gfx.x = GUI.w - (255 * RL.scaleFactor) else gfx.x = GUI.w - (260 * RL.scaleFactor) end
  gfx.y = GUI.h - (15.5 * RL.scaleFactor)
  gfx.drawstr(str)
end

-----------------------------------------------------------------------------
-- Override tooltip function for handling macOS coordinates (inverted y-axis)
-----------------------------------------------------------------------------
GUI.settooltip = function(str)
  if RL.showTooltips then
    if not str or str == "" then return end
    local x, y = gfx.clienttoscreen(0, 0)
    if osversion:find("OSX") then
      local mouseX, mouseY = reaper.GetMousePosition()
      reaper.TrackCtl_SetToolTip(str, mouseX + 16, mouseY + 16, true)
    else
      reaper.TrackCtl_SetToolTip(str, x + GUI.mouse.x + 16, y + GUI.mouse.y + 16, true)
    end
    GUI.tooltip = str
  else
    GUI.cleartooltip()
  end
end

--------------------
-- Scaling functions
--------------------
local function RL_InitElementScaling(sf)
  if sf ~= nil then RL.scaleFactor = sf
  else
    if RL.scaleFactor > 1.2 then
      RL.scaleFactor = 2
      GUI.w, GUI.h = (RL.minWidth + 100) * RL.scaleFactor, RL.minHeight * RL.scaleFactor
    else
      RL.scaleFactor = 1
      GUI.w, GUI.h = RL.minWidth, RL.minHeight
    end
  end

  local fonts = GUI.get_OS_fonts()
  GUI.fonts = {
    {fonts.sans, RL.fontSizes[1] * RL.scaleFactor}, -- title
    {fonts.sans, RL.fontSizes[2] * RL.scaleFactor}, -- header
    {fonts.sans, RL.fontSizes[3] * RL.scaleFactor}, -- label
    {fonts.sans, RL.fontSizes[4] * RL.scaleFactor}, -- value
    monospace = {fonts.mono, RL.fontSizes[5] * RL.scaleFactor},
    version = {fonts.sans, RL.fontSizes[6] * RL.scaleFactor, "i"}
  }

  GUI.load_window_state(appname)
end

local function RL_CheckStoredScaleFactor()
  local storedScaleFactor = tonumber(reaper.GetExtState(appname, "window_scalefactor"))
  if storedScaleFactor ~= nil and storedScaleFactor > 0 then
    RL.scaleFactor = storedScaleFactor
    RL_InitElementScaling(RL.scaleFactor)
  end
end

local function RL_SetWindowParameters()
  -- button size
  btn_w = 132 * RL.scaleFactor
  btn_h = 24 * RL.scaleFactor
  -- global element indents
  optionspad_left = 65 * RL.scaleFactor
  pad_left = 4 * RL.scaleFactor
  pad_top = 36 * RL.scaleFactor
  topY = 7 * RL.scaleFactor
  listbox_top = 28 * RL.scaleFactor
  listbox_h = GUI.h - (71 * RL.scaleFactor)
  btn_pad_top = 129 * RL.scaleFactor
  btn_main_top = 33 * RL.scaleFactor
  btn_main_pad = 0
  btn_tab_top = 191 * RL.scaleFactor
  if RL.showButtonPanel then listbox_w = GUI.w - (144 * RL.scaleFactor) else listbox_w = GUI.w - 2 * pad_left end
  -- button indents
  btn_pad_left = listbox_w + (8 * RL.scaleFactor)
  btn_pad_add = 29 * RL.scaleFactor
  -- refresh buttons
  refreshW = 40 * RL.scaleFactor
  refreshH = 15 * RL.scaleFactor
  refreshX = pad_left 
  refreshY = GUI.h - (38 * RL.scaleFactor)
  -- filter textbox
  filterH = 20 * RL.scaleFactor
  filterX = 122 * RL.scaleFactor
  filterY = 4.5 * RL.scaleFactor
  filterW = (listbox_w * 0.52)
  -- path display box
  pathX = pad_left + 43 * RL.scaleFactor
  footerY = GUI.h - (40 * RL.scaleFactor)
  tabSelectorPadding = 0
  -- adjustments when using tabstrip
  if RL.tabSelectorStyle == 1 then
    pad_top = 30 * RL.scaleFactor
    topY = 24 * RL.scaleFactor
    listbox_top = 48 * RL.scaleFactor
    listbox_h = GUI.h - (92 * RL.scaleFactor)
    btn_pad_top = 150 * RL.scaleFactor
    btn_main_top = 42 * RL.scaleFactor
    btn_main_pad = 20
    btn_tab_top = 210 * RL.scaleFactor
    filterX = pad_left
    filterY = 24 * RL.scaleFactor
    filterW = (listbox_w * 0.6)
  end
end

function InitSubPanels()
  local t1, t2, t3, t4, t5, t6 = string.match(reaper.GetExtState(appname, "window_showsubfolderpanel"), "([%a]+),([%a]+),([%a]+),([%a]+),([%a]+),([%a]+)")
  RL.activeSubPanels = {
    tostring(t1) == "true" and true or false,
    tostring(t2) == "true" and true or false,
    tostring(t3) == "true" and true or false,
    tostring(t4) == "true" and true or false,
    tostring(t5) == "true" and true or false,
    tostring(t6) == "true" and true or false,
    true
  }
end

RL_InitElementScaling(nil)
RL_CheckStoredScaleFactor()
RL_SetWindowParameters()
InitSubPanels()

--------------------
-- Main GUI Elements
--------------------
local subselectionindices = {}
for match in reaper.GetExtState(appname, "window_subselection"):gmatch("([^,%s]+)") do subselectionindices[#subselectionindices + 1] = tonumber(match) end
if #subselectionindices == 0 then subselectionindices = { 1, 1, 1, 1, 1, 1, 1, 1 } end
TabParentSelectionIndex = subselectionindices

TabSelectionIndex = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }

TabID = {
  RecentProjects = 1,
  ProjectTemplates = 2,
  TrackTemplates = 3,
  CustomProjects = 4,
  ProjectLists = 5,
  Backups = 6,
  Docs = 7,
  Favorites = 8,
  Help = 9,
  Options = 10,
  Paths = 11,
  ScanSettings = 12,
  Actions = 13,
  Layout = 14,
  OptionsMenu = 15
}

TabLabels = {
  "Recent Projects",
  "Project Templates",
  "Track Templates",
  "Projects",
  "Project Lists",
  "Backups",
  "Docs",
  "Favorites",
  "Help",
  "Options",
  "",
  "",
  "",
  ""
}

MainLabels = {
  "Recent Projects",
  "Project Templates",
  "Track Templates",
  "Projects",
  "Project Lists",
  "Backups",
  "Docs",
  "Favorites",
  "Help",
  "Options"
}

OptionLabels = {
  "General",
  "Paths",
  "Scan Settings",
  "Follow Actions",
  "Layout / Colors"
}

if not ConfigFlags.enableCustomColorOptions then OptionLabels[5] = "Layout" end

---------------------------------
-- Audio preview section elements
---------------------------------
local AudioPreview = {
  active = false,
  channelIndex = 0,
  fileName = "",
  fileExtension = "",
  lastPlayed = "",
  statusText = nil
}

local function RL_Draw_PreviewSection()
  if not ConfigFlags.enableAudioPreview then return end

  GUI.New("main_previewVolKnob", "Knob", LayerIndex.Global, 4.8 * pathX + (RL.scaleFactor * 15), footerY + (1.2 * RL.scaleFactor), 18 * RL.scaleFactor, "Volume", 0, 100, 50, 1)
  GUI.elms.main_previewVolKnob.col_head = "elm_frame"
  GUI.elms.main_previewVolKnob.col_body = "none"
  GUI.elms.main_previewVolKnob.cap_y = - (4.5 * RL.scaleFactor + (18 * RL.scaleFactor)) + (2 * RL.scaleFactor) - 5
  GUI.elms.main_previewVolKnob.font_b = GUI.fonts[6]
  GUI.elms.main_previewVolKnob.vals = false
  GUI.elms.main_previewVolKnob.tooltip = "Audio Preview Section\n\n" ..
                                          "- Set the volume (in %) via Left Drag or Mousewheel \n" ..
                                          "- Double Click on the knob starts/stops the preview\n\n" ..
                                          "Color states:\n  - SILVER: preview file available for the selected entry\n  - HIGHLIGHT COLOR: preview playing"

  local pos = 1
  local stereoChannels = {}

  for c = 1, reaper.GetNumAudioOutputs(), 2 do
    stereoChannels[pos] = c .. "/" .. c + 1
    pos = pos + 1
  end

  GUI.New("main_previewStatusLabel", "Label", LayerIndex.Global, 5.3 * pathX + (RL.scaleFactor * 15), footerY + 2 * RL.scaleFactor, "Preview", false, 4, "elm_frame")
  GUI.New("main_previewChannels", "Menubox", LayerIndex.Global, 6.3 * pathX + (RL.scaleFactor * 15), footerY + (2 * RL.scaleFactor), 51 * RL.scaleFactor, 15 * RL.scaleFactor, "", table.concat(stereoChannels, ","), 8)
  GUI.elms.main_previewChannels.col_txt = "elm_frame"
  GUI.elms.main_previewChannels.align = 1
  GUI.elms.main_previewChannels.tooltip = "Audio Preview Section\n\nSet the audio channel(s) used for preview playback"
  
  local function SetPreviewChannel(channel)
    if channel and #channel > 0 then AudioPreview.channelIndex = tonumber(string.sub(channel, 1, #channel - channel:reverse():find("/"))) - 1
    else AudioPreview.channelIndex = 1 end
  end

  function GUI.elms.main_previewChannels:onmousedown()
    GUI.Menubox.onmouseup(self)
    SetPreviewChannel(stereoChannels[GUI.Val("main_previewChannels")])
  end
    
  function GUI.elms.main_previewChannels:onwheel()
    GUI.Menubox.onwheel(self)
    SetPreviewChannel(stereoChannels[GUI.Val("main_previewChannels")])
  end

  function GUI.elms.main_previewVolKnob:redraw()
    GUI.Knob.redraw(self)
    self.caption = self.retval
  end

  function GUI.elms.main_previewVolKnob:ondrag()
    local lastColor = GUI.elms.main_previewVolKnob.col_head
    GUI.Knob.ondrag(self)
    AudioPreviewChangeVolKnobColor("none", lastColor)
    self.caption = self.retval
  end

  function GUI.elms.main_previewVolKnob:onwheel()
    local lastColor = GUI.elms.main_previewVolKnob.col_head
    GUI.Knob.onwheel(self)
    AudioPreviewChangeVolKnobColor("none", lastColor)
    self.caption = self.retval
  end

  function GUI.elms.main_previewVolKnob:ondoubleclick()
    GUI.Listbox.ondoubleclick(self)
    AudioPreviewToggleState()
  end

  GUI.elms.main_previewVolKnob:init()
  GUI.elms.main_previewVolKnob:redraw()
end

-------------------------
-- Context main functions
-------------------------
local function RL_Context_Main_GetLockState()
  if GetMainListSize() == 0 then return "#" else return "" end
end

local function RL_Context_Main_GetBaseEntries(isLocked, menuEntries)
  local firstEntry = "1 - Add to Favorites" 
  if GUI.elms.main_tabs.state == TabID.Favorites then firstEntry = "1 - Remove from Favorites" end
  if SWSinstalled then menuEntries = menuEntries .. "|#|>0 - Reaper Theme|" .. string.gsub(ThemeSlot_GetNames(), ",", "|") end
  return isLocked .. firstEntry .. "|#|" .. isLocked .. "2 - Locate in Explorer/Finder|3 - Open Project|#|4 - New Project|#|5 - New Tab|6 - New Tab Ignore Template|#" .. menuEntries
end

local function RL_Context_Main_Default(isLocked, menuEntries)
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local RMBmenu = gfx.showmenu(RL_Context_Main_GetBaseEntries(isLocked, menuEntries))
  if RMBmenu == 1 then Favorites_Add()
    elseif RMBmenu == 2 then Global_OpenInExplorer()
    elseif RMBmenu == 3 then Global_ShowProjectOpenDialog()
    elseif RMBmenu == 4 then Global_NewProject()
    elseif RMBmenu == 5 then Global_NewTab()
    elseif RMBmenu == 6 then Global_NewTabIgnoreDefaultTemplate()
    elseif RMBmenu == 7 then RL_Func_LoadElementInTab[GUI.elms.main_tabs.state].call()
    elseif RMBmenu == 8 then RL_Func_LoadElement[GUI.elms.main_tabs.state].call()
    elseif RMBmenu == 9 then LoadThemeSlotFromContextMenu(9, RMBmenu)
    elseif RMBmenu == 10 then LoadThemeSlotFromContextMenu(9, RMBmenu)
    elseif RMBmenu == 11 then LoadThemeSlotFromContextMenu(9, RMBmenu)
    elseif RMBmenu == 12 then LoadThemeSlotFromContextMenu(9, RMBmenu)
    elseif RMBmenu == 13 then LoadThemeSlotFromContextMenu(9, RMBmenu)
  end
end

local function RL_Context_Main_SpecialToggle(isLocked, menuEntries)
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local RMBmenu = gfx.showmenu(RL_Context_Main_GetBaseEntries(isLocked, menuEntries))
  if RMBmenu == 1 then Favorites_Add()
    elseif RMBmenu == 2 then Global_OpenInExplorer()
    elseif RMBmenu == 3 then Global_ShowProjectOpenDialog()
    elseif RMBmenu == 4 then Global_NewProject()
    elseif RMBmenu == 5 then Global_NewTab()
    elseif RMBmenu == 6 then Global_NewTabIgnoreDefaultTemplate()
    elseif RMBmenu == 7 then RL_Func_LoadElementInTab[GUI.elms.main_tabs.state].call()
    elseif RMBmenu == 8 then RL_Func_LoadElement[GUI.elms.main_tabs.state].call()
    elseif RMBmenu == 9 then ToggleSpecialOptionsFromContextMenu(RMBmenu)
    elseif RMBmenu == 10 then LoadThemeSlotFromContextMenu(10, RMBmenu)
    elseif RMBmenu == 11 then LoadThemeSlotFromContextMenu(10, RMBmenu)
    elseif RMBmenu == 12 then LoadThemeSlotFromContextMenu(10, RMBmenu)
    elseif RMBmenu == 13 then LoadThemeSlotFromContextMenu(10, RMBmenu)
    elseif RMBmenu == 14 then LoadThemeSlotFromContextMenu(10, RMBmenu)
  end
end

local function RL_Context_Main_RecentProjects()
  if not RL.showButtonPanel then
    local isLocked = RL_Context_Main_GetLockState()

    local menuEntries = "|" .. isLocked .. "7 - Load in Tab|" .. isLocked .. "8 - Load|#|"
    if RL.saveAsNewVersionMode == 1 then menuEntries = menuEntries .. isLocked .. "!9 - [ Save as New Version ] ON"
    else menuEntries = menuEntries .. isLocked .. "9 - [ Save as New Version ] OFF" end

    RL_Context_Main_SpecialToggle(isLocked, menuEntries)
  end
end

local function RL_Context_Main_ProjectTemplates()
  if not RL.showButtonPanel then
    local isLocked = RL_Context_Main_GetLockState()
    
    local menuEntries = "|" .. isLocked .. "7 - Load in Tab|" .. isLocked .. "8 - Load|#|"
    if RL.projectTemplateLoadMode == 0 then menuEntries = menuEntries .. isLocked .. "!9 - [ Edit Template Mode ] ON"
    else menuEntries = menuEntries .. isLocked .. "9 - [ Edit Template Mode ] OFF" end
    
    RL_Context_Main_SpecialToggle(isLocked, menuEntries)
  end
end

local function RL_Context_Main_TrackTemplates()
  if not RL.showButtonPanel then
    local isLocked = RL_Context_Main_GetLockState()
    local menuEntries = "|" .. isLocked .. "7 - Insert in Tab|" .. isLocked .. "8 - Insert"
    RL_Context_Main_Default(isLocked, menuEntries)
  end
end

local function RL_Context_Main_CustomProjects()
  if not RL.showButtonPanel then
    local isLocked = RL_Context_Main_GetLockState()
    
    local menuEntries = "|" .. isLocked .. "7 - Load in Tab|" .. isLocked .. "8 - Load|#|"
    if RL.saveAsNewVersionMode == 1 then menuEntries = menuEntries .. isLocked .. "!9 - [ Save as New Version ] ON"
    else menuEntries = menuEntries .. isLocked .. "9 - [ Save as New Version ] OFF" end
    
    RL_Context_Main_SpecialToggle(isLocked, menuEntries)
  end
end

local function RL_Context_Main_ProjectLists()
  if not RL.showButtonPanel then
    local isLocked = RL_Context_Main_GetLockState()
    
    local menuEntries = "|" .. isLocked .. "7 - Load in Tab|" .. isLocked .. "8 - Load|#|"
    if RL.saveAsNewVersionMode == 1 then menuEntries = menuEntries .. isLocked .. "!9 - [ Save as New Version ] ON"
    else menuEntries = menuEntries .. isLocked .. "9 - [ Save as New Version ] OFF" end
    
    RL_Context_Main_SpecialToggle(isLocked, menuEntries)
  end
end

local function RL_Context_Main_Backups()
  if not RL.showButtonPanel then
    local isLocked = RL_Context_Main_GetLockState()
    local menuEntries = "|" .. isLocked .. "7 - Load in Tab|" .. isLocked .. "8 - Load"
    RL_Context_Main_Default(isLocked, menuEntries)
  end
end

local function RL_Context_Main_Docs()
  if not RL.showButtonPanel then
    local isLocked = RL_Context_Main_GetLockState()
    local menuEntries = "|" .. isLocked .. "7 - Open"
    
    gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
    local RMBmenu = gfx.showmenu(RL_Context_Main_GetBaseEntries(isLocked, menuEntries))
    if RMBmenu == 1 then Favorites_Add()
      elseif RMBmenu == 2 then Global_OpenInExplorer()
      elseif RMBmenu == 3 then Global_ShowProjectOpenDialog()
      elseif RMBmenu == 4 then Global_NewProject()
      elseif RMBmenu == 5 then Global_NewTab()
      elseif RMBmenu == 6 then Global_NewTabIgnoreDefaultTemplate()
      elseif RMBmenu == 7 then RL_Func_LoadElementInTab[GUI.elms.main_tabs.state].call()
      elseif RMBmenu == 8 then LoadThemeSlotFromContextMenu(8, RMBmenu)
      elseif RMBmenu == 9 then LoadThemeSlotFromContextMenu(8, RMBmenu)
      elseif RMBmenu == 10 then LoadThemeSlotFromContextMenu(8, RMBmenu)
      elseif RMBmenu == 11 then LoadThemeSlotFromContextMenu(8, RMBmenu)
      elseif RMBmenu == 12 then LoadThemeSlotFromContextMenu(8, RMBmenu)
    end
  end
end

local function RL_Context_Main_Favorites()
  if not RL.showButtonPanel then
    local isLocked = RL_Context_Main_GetLockState()
    
    local menuEntries = "|" .. isLocked .. "7 - Load in Tab|" .. isLocked .. "8 - Load|#|"
    if RL.saveAsNewVersionMode == 1 then menuEntries = menuEntries .. isLocked .. "!9 - [ Save as New Version ] ON"
    else menuEntries = menuEntries .. isLocked .. "9 - [ Save as New Version ] OFF" end
    
    local selectedFavCategory = TabParentSelectionIndex[TabID.Favorites]
    if selectedFavCategory == 2 then
      menuEntries = "|" .. isLocked .. "7 - Load in Tab|" .. isLocked .. "8 - Load|#|"
      if RL.projectTemplateLoadMode == 0 then menuEntries = menuEntries .. isLocked .. "!9 - [ Edit Template Mode ] ON"
      else menuEntries = menuEntries .. isLocked .. "9 - [ Edit Template Mode ] OFF" end
    elseif selectedFavCategory == 3 then menuEntries = "|" .. isLocked .. "7 - Insert in Tab|" .. isLocked .. "8 - Insert"
    elseif selectedFavCategory == 6 then menuEntries = "|" .. isLocked .. "7 - Load in Tab|" .. isLocked .. "8 - Load"
    elseif selectedFavCategory == 7 then menuEntries = "|" .. isLocked .. "7 - Open" end
    
    gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
    local RMBmenu = gfx.showmenu(RL_Context_Main_GetBaseEntries(isLocked, menuEntries))
    if RMBmenu == 1 then RL_ConfirmDialog_RemoveFavoritesEntry()
      elseif RMBmenu == 2 then Global_OpenInExplorer()
      elseif RMBmenu == 3 then Global_ShowProjectOpenDialog()
      elseif RMBmenu == 4 then Global_NewProject()
      elseif RMBmenu == 5 then Global_NewTab()
      elseif RMBmenu == 6 then Global_NewTabIgnoreDefaultTemplate()
      elseif RMBmenu == 7 then RL_Func_LoadElementInTab[GUI.elms.main_tabs.state].call()
      elseif RMBmenu == 8 then
        if selectedFavCategory == 7 then LoadThemeSlotFromContextMenu(8, RMBmenu) else RL_Func_LoadElement[GUI.elms.main_tabs.state].call() end
      elseif RMBmenu == 9 then
        if selectedFavCategory ~= TabID.TrackTemplates or selectedFavCategory ~= TabID.Backups then ToggleSpecialOptionsFromContextMenu(RMBmenu) end
        if selectedFavCategory == TabID.Docs then LoadThemeSlotFromContextMenu(8, RMBmenu)
        elseif selectedFavCategory == TabID.TrackTemplates or selectedFavCategory == TabID.Backups then LoadThemeSlotFromContextMenu(9, RMBmenu) end
      elseif RMBmenu == 10 then
        if selectedFavCategory == TabID.Docs then LoadThemeSlotFromContextMenu(8, RMBmenu)
        elseif selectedFavCategory == TabID.TrackTemplates or selectedFavCategory == TabID.Backups then LoadThemeSlotFromContextMenu(9, RMBmenu)
        else LoadThemeSlotFromContextMenu(10, RMBmenu) end
      elseif RMBmenu == 11 then
        if selectedFavCategory == TabID.Docs then LoadThemeSlotFromContextMenu(8, RMBmenu)
        elseif selectedFavCategory == TabID.TrackTemplates or selectedFavCategory == TabID.Backups then LoadThemeSlotFromContextMenu(9, RMBmenu)
        else LoadThemeSlotFromContextMenu(10, RMBmenu) end
      elseif RMBmenu == 12 then
        if selectedFavCategory== TabID.Docs then LoadThemeSlotFromContextMenu(8, RMBmenu)
        elseif selectedFavCategory == TabID.TrackTemplates or selectedFavCategory == TabID.Backups then LoadThemeSlotFromContextMenu(9, RMBmenu)
        else LoadThemeSlotFromContextMenu(10, RMBmenu) end
      elseif RMBmenu == 13 then
        if selectedFavCategory == TabID.TrackTemplates or selectedFavCategory == TabID.Backups then LoadThemeSlotFromContextMenu(9, RMBmenu)
        else LoadThemeSlotFromContextMenu(10, RMBmenu) end
      elseif RMBmenu == 14 then
        if selectedFavCategory ~= TabID.TrackTemplates or selectedFavCategory ~= TabID.Backups or selectedFavCategory ~= TabID.Docs then LoadThemeSlotFromContextMenu(10, RMBmenu) end
    end
  end
end

local function RL_Context_Main_Relay()
  if GUI.elms.main_tabs.state == TabID.RecentProjects then RL_Context_Main_RecentProjects()
  elseif GUI.elms.main_tabs.state == TabID.ProjectTemplates then RL_Context_Main_ProjectTemplates()
  elseif GUI.elms.main_tabs.state == TabID.TrackTemplates then RL_Context_Main_TrackTemplates()
  elseif GUI.elms.main_tabs.state == TabID.CustomProjects then RL_Context_Main_CustomProjects()
  elseif GUI.elms.main_tabs.state == TabID.ProjectLists then RL_Context_Main_ProjectLists()
  elseif GUI.elms.main_tabs.state == TabID.Backups then RL_Context_Main_Backups()
  elseif GUI.elms.main_tabs.state == TabID.Docs then RL_Context_Main_Docs()
  elseif GUI.elms.main_tabs.state == TabID.Favorites then RL_Context_Main_Favorites()
  end
end

function ToggleSpecialOptionsFromContextMenu(selectedMenuIndex)
  if GUI.elms.main_tabs.state == TabID.RecentProjects then RL.saveAsNewVersionMode = (1 - RL.saveAsNewVersionMode)
    elseif GUI.elms.main_tabs.state == TabID.ProjectTemplates then RL.projectTemplateLoadMode = (1 - RL.projectTemplateLoadMode)
    elseif GUI.elms.main_tabs.state == TabID.CustomProjects then RL.saveAsNewVersionMode = (1 - RL.saveAsNewVersionMode)
    elseif GUI.elms.main_tabs.state == TabID.ProjectLists then RL.saveAsNewVersionMode = (1 - RL.saveAsNewVersionMode)
    elseif GUI.elms.main_tabs.state == TabID.Favorites then
      local selectedFavCategory = TabParentSelectionIndex[TabID.Favorites]
      if selectedFavCategory == 2 then RL.projectTemplateLoadMode = (1 - RL.projectTemplateLoadMode)
      elseif selectedFavCategory == 1 or selectedFavCategory == 4 or selectedFavCategory == 5 then RL.saveAsNewVersionMode = (1 - RL.saveAsNewVersionMode) end
    end
end

function LoadThemeSlotFromContextMenu(firstIndex, selectedMenuIndex)
  local selectedThemeSlot = 1 + math.floor(selectedMenuIndex - firstIndex)
  if selectedThemeSlot <= 5 then reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_LOAD_THEME" .. selectedThemeSlot), 0) end -- SWS/S&M: Resources - Load theme, slot#
end

function RL_ToggleTooltips()
  RL.showTooltips = not RL.showTooltips
  if RL.showTooltips then
    GUI.elms.main_btnToggleTooltips.color = FilterColor.active
    reaper.SetExtState(appname, "window_showtooltips", "true", 1)
    MsgStatusBar("Tooltips ON")
  else 
    GUI.elms.main_btnToggleTooltips.color = FilterColor.inactive
    reaper.SetExtState(appname, "window_showtooltips", "false", 1)
    MsgStatusBar("Tooltips OFF")
  end
  GUI.elms.main_btnToggleTooltips:redraw()
  GUI.elms.main_btnToggleTooltips:init()
end

----------------
-- Main elements
----------------
local function RL_Draw_Main()
  if RL.tabSelectorStyle == 1 then -- tabstrip style
    GUI.New("main_tabs", "Tabs", LayerIndex.Main, 0, 0, 95 * RL.scaleFactor, 20 * RL.scaleFactor, TabLabels, 16)
    GUI.elms.main_tabs.col_tab_b = "elm_bg"
    if GUI.elms.main_menuTabSelector ~= nil then GUI.elms.main_menuTabSelector:delete() end
    function GUI.elms.main_tabs:onmousedown()
      GUI.Tabs.onmousedown(self)
      if (GUI.elms.main_tabs.state > TabID.Options) then RL_SetFocusedTab(self.retval)
      else
        GUI.Val("main_menuTabSelector", GUI.elms.main_tabs.state)
        RL_SetFocusedTab(GUI.elms.main_tabs.state)
      end
    end
    function GUI.elms.main_tabs:onwheel()
      GUI.Tabs.onwheel(self)
      if (self.retval > TabID.Favorites) then RL_SetFocusedTab(TabID.Favorites)
      else
        GUI.Val("main_menuTabSelector", GUI.elms.main_tabs.state)
        RL_SetFocusedTab(GUI.elms.main_tabs.state)
      end
    end
    function GUI.elms.main_tabs:onmouser_down()
      GUI.Tabs.onmouser_down(self)
      gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
      local RMBmenu = gfx.showmenu(table.concat(MainLabels, "|"))
      if RMBmenu >= 1 and RMBmenu <= #MainLabels then RL_SetFocusedTab(RMBmenu) end
    end
  else -- dropdown style
    GUI.New("main_tabs", "Tabs", LayerIndex.Main, 0, 0, 95 * RL.scaleFactor, 20 * RL.scaleFactor, " , , , , , , , , , , , , , ", 16)
    GUI.elms.main_tabs.col_tab_b = "elm_bg"
    GUI.elms.main_tabs.h, GUI.elms.main_tabs.tab_h = 0, 0
    GUI.New("main_menuTabSelector", "Menubox", LayerIndex.Main, pad_left, 4.5 * RL.scaleFactor, (125 * RL.scaleFactor) - (10 * RL.scaleFactor), 20 * RL.scaleFactor, "", MainLabels, 8)
    GUI.elms.main_menuTabSelector.align = 1
    function GUI.elms.main_menuTabSelector:onmousedown() GUI.Menubox.onmouseup(self) RL_SetFocusedTab(GUI.Val("main_menuTabSelector")) end
    function GUI.elms.main_menuTabSelector:onwheel() GUI.Menubox.onwheel(self) RL_SetFocusedTab(GUI.Val("main_menuTabSelector")) end
  end

  GUI.elms.main_tabs:update_sets({
      [TabID.RecentProjects] = { LayerIndex.Overlay, LayerIndex.Global, LayerIndex.RecentProjects, LayerIndex.SaveAsNewVersion, LayerIndex.SpecialOption },
      [TabID.ProjectTemplates] = { LayerIndex.Overlay, LayerIndex.Global, LayerIndex.ProjectTemplates, LayerIndex.SpecialOption },
      [TabID.TrackTemplates] = { LayerIndex.Overlay, LayerIndex.Global, LayerIndex.TrackTemplates, LayerIndex.SpecialOption },
      [TabID.CustomProjects] = { LayerIndex.Overlay, LayerIndex.Global, LayerIndex.CustomProjects, LayerIndex.SaveAsNewVersion, LayerIndex.SpecialOption },
      [TabID.ProjectLists] = { LayerIndex.Overlay, LayerIndex.Global, LayerIndex.ProjectLists, LayerIndex.SaveAsNewVersion, LayerIndex.SpecialOption },
      [TabID.Backups] = { LayerIndex.Overlay, LayerIndex.Global, LayerIndex.Backups, LayerIndex.SpecialOption },
      [TabID.Docs] = { LayerIndex.Overlay, LayerIndex.Global, LayerIndex.Docs, LayerIndex.SpecialOption },
      [TabID.Favorites] = { LayerIndex.Overlay, LayerIndex.Global, LayerIndex.Favorites },
      [TabID.Help] = { LayerIndex.Overlay, LayerIndex.VersionInfo, LayerIndex.Help },
      [TabID.OptionsMenu] = { LayerIndex.Overlay, LayerIndex.VersionInfo, LayerIndex.Paths, LayerIndex.ScanSettings, LayerIndex.Options, LayerIndex.Actions, LayerIndex.Layout },
      [TabID.Options] = { LayerIndex.Overlay, LayerIndex.VersionInfo, LayerIndex.OptionsMenu, LayerIndex.Options },
      [TabID.Paths] = { LayerIndex.Overlay, LayerIndex.VersionInfo, LayerIndex.OptionsMenu, LayerIndex.Paths },
      [TabID.ScanSettings] = { LayerIndex.Overlay, LayerIndex.VersionInfo, LayerIndex.OptionsMenu, LayerIndex.ScanSettings },
      [TabID.Actions] = { LayerIndex.Overlay, LayerIndex.VersionInfo, LayerIndex.OptionsMenu, LayerIndex.Actions },
      [TabID.Layout] = { LayerIndex.Overlay, LayerIndex.VersionInfo, LayerIndex.OptionsMenu, LayerIndex.Layout }
    })

  GUI.New("main_statusbar", "Label", LayerIndex.Overlay, pad_left, GUI.h - (16 * RL.scaleFactor), "", false, 4)

  GUI.New("main_lblPaths", "Label", LayerIndex.Global, 3.65 * pathX + (RL.scaleFactor * 5), footerY + (2.85 * RL.scaleFactor), "Paths", false, 3)
  GUI.New("main_checklistPaths", "Checklist", LayerIndex.Global, 4.25 * pathX + (RL.scaleFactor * 8), footerY + (3 * RL.scaleFactor), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "", "", 0)
  GUI.elms.main_checklistPaths.shadow = false
  GUI.elms.main_checklistPaths.opt_size = 15 * RL.scaleFactor
  GUI.elms.main_checklistPaths:init()

  function GUI.elms.main_checklistPaths:onmouseup()
    GUI.Checklist.onmouseup(self)
    Global_UpdateListDisplay()
  end

  if ConfigFlags.enableSortModeOptions then 
    GUI.New("main_sortMode", "Menubox", LayerIndex.Global, pad_left + 53 * RL.scaleFactor, footerY + (2 * RL.scaleFactor), 61 * RL.scaleFactor, 15 * RL.scaleFactor, "", "A - Z,Z - A", 8)
    GUI.elms.main_sortMode.align = 1
    GUI.elms.main_sortMode.tooltip = "Sort options"

    function GUI.elms.main_sortMode:onmousedown()
      GUI.Menubox.onmouseup(self)
      RL.sortModeIndex[GUI.elms.main_tabs.state] = math.floor(self.retval)
      Global_UpdateSortMode()
    end
    
    function GUI.elms.main_sortMode:onwheel()
      GUI.Menubox.onwheel(self)
      RL.sortModeIndex[GUI.elms.main_tabs.state] = math.floor(self.retval)
      Global_UpdateSortMode()
    end
  end

  GUI.New("main_checklistWindowPin", "Checklist", LayerIndex.Global, GUI.w - (24 * RL.scaleFactor) + (RL.scaleFactor * 5), topY + (1.2 * RL.scaleFactor) + ((RL.tabSelectorStyle - 1) * (0.2 * btn_main_pad)), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "", "h", 0)
  GUI.elms.main_checklistWindowPin.shadow = false
  GUI.elms.main_checklistWindowPin.opt_size = 15 * RL.scaleFactor
  GUI.elms.main_checklistWindowPin:init()

  if RL.showButtonPanel then
    if SWSinstalled then GUI.New("main_btnOpenInExplorer", "Button", LayerIndex.Global, btn_pad_left, 2 * btn_main_top, btn_w, btn_h, "Locate in Explorer/Finder", Global_OpenInExplorer) end
    
    GUI.New("main_btnAddToFavorites", "Button", LayerIndex.SpecialOption, btn_pad_left, (2 * btn_main_top) - (32 * RL.scaleFactor), btn_w, btn_h, "Add to Favorites", Favorites_Add)
    GUI.elms.main_btnAddToFavorites.tooltip = "Add the selected file(s) to the [Favorites]"
    
    GUI.New("main_btnOpenProject", "Button", LayerIndex.Global, btn_pad_left, (2 * btn_main_top) + (29 * RL.scaleFactor), btn_w, btn_h, "Open Project", Global_ShowProjectOpenDialog) 

    GUI.New("main_btnNewProject", "Button", LayerIndex.Global, btn_pad_left, btn_pad_top, btn_w, btn_h, "New Project", Global_NewProject) 
    GUI.New("main_btnNewProjectTab", "Button", LayerIndex.Global, btn_pad_left, btn_pad_top + btn_pad_add, (btn_w * 0.5) - 5, btn_h, "New Tab", Global_NewTab) 
    GUI.New("main_btnNewTabIgnoreTemplate", "Button", LayerIndex.Global, btn_pad_left + (btn_w * 0.5) + 5, btn_pad_top + btn_pad_add, (btn_w * 0.5) - 5, btn_h, "New Tab IT", Global_NewTabIgnoreDefaultTemplate)

    GUI.New("main_lblSaveNewVersion", "Label", LayerIndex.SaveAsNewVersion, GUI.w - (144 * RL.scaleFactor) + (RL.scaleFactor * 11), (255 + btn_main_pad) * RL.scaleFactor, "Save as New Version", false, 3)
    GUI.New("main_checklistSaveAsNewVersion", "Checklist", LayerIndex.SaveAsNewVersion, GUI.w - (34 * RL.scaleFactor) + (RL.scaleFactor * 10), (252 + btn_main_pad) * RL.scaleFactor + (RL.scaleFactor * 2), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "", "h", 0)
    GUI.elms.main_checklistSaveAsNewVersion.shadow = false
    GUI.elms.main_checklistSaveAsNewVersion.opt_size = 15 * RL.scaleFactor
    GUI.elms.main_checklistSaveAsNewVersion:init()
  
    GUI.New("main_lblWindowpin", "Label", LayerIndex.Global, GUI.w - (82 * RL.scaleFactor) + (RL.scaleFactor * 5), topY + (1.2 * RL.scaleFactor) + ((RL.tabSelectorStyle - 1) * (0.2 * btn_main_pad)), "Keep open", false, 3)
  else
    if GUI.elms.main_btnOpenInExplorer ~= nil then GUI.elms.main_btnOpenInExplorer:delete() end
    if GUI.elms.main_btnOpenProject ~= nil then GUI.elms.main_btnOpenProject:delete() end
    if GUI.elms.main_btnNewProject ~= nil then GUI.elms.main_btnNewProject:delete() end
    if GUI.elms.main_btnNewProjectTab ~= nil then GUI.elms.main_btnNewProjectTab:delete() end
    if GUI.elms.main_btnNewTabIgnoreTemplate ~= nil then GUI.elms.main_btnNewTabIgnoreTemplate:delete() end
  end

  function Global_ShowHelpTab() RL_SetFocusedTab(TabID.Help) end
  GUI.New("main_frame_footervertical_2", "Frame", LayerIndex.Global, GUI.w - (216 * RL.scaleFactor), GUI.h - (16 * RL.scaleFactor), 1.5 * RL.scaleFactor, 14 * RL.scaleFactor, false, false)
  GUI.New("main_btnHelp", "Label", LayerIndex.Global, GUI.w - (211 * RL.scaleFactor), GUI.h - (16 * RL.scaleFactor), "Help", false, 3)
  function GUI.elms.main_btnHelp:onmouseup() GUI.Label.onmouseup(self) Global_ShowHelpTab() end
  
  function Global_ShowOptionsTab() RL_SetFocusedTab(TabID.Help + TabSelectionIndex[TabID.Options]) end
  GUI.New("main_frame_footervertical_3", "Frame", LayerIndex.Global, GUI.w - (184.5 * RL.scaleFactor), GUI.h - (16 * RL.scaleFactor), 1.5 * RL.scaleFactor, 14 * RL.scaleFactor, false, false)
  GUI.New("main_btnOptions", "Label", LayerIndex.Global, GUI.w - (178.5 * RL.scaleFactor), GUI.h - (16 * RL.scaleFactor), "Options", false, 3)
  function GUI.elms.main_btnOptions:onmouseup() GUI.Label.onmouseup(self) Global_ShowOptionsTab() end

  GUI.New("main_frame_footervertical_4", "Frame", LayerIndex.Global, GUI.w - (136 * RL.scaleFactor), GUI.h - (16 * RL.scaleFactor), 1.5 * RL.scaleFactor, 14 * RL.scaleFactor, false, false)

  function ButtonScaleFontDown() RL_ScaleListboxFontSizeDown() end
  GUI.New("main_scaleFontDown", "Label", LayerIndex.Global, GUI.w - (130 * RL.scaleFactor), GUI.h - (15.5 * RL.scaleFactor), "A", false, 3)
  function GUI.elms.main_scaleFontDown:onmouseup() GUI.Label.onmouseup(self) ButtonScaleFontDown() end
  
  function ButtonScaleFontUp() RL_ScaleListboxFontSizeUp() end
  GUI.New("main_scaleFontUp", "Label", LayerIndex.Global, GUI.w - (116 * RL.scaleFactor), GUI.h - (18.5 * RL.scaleFactor), "A", false, 2)
  function GUI.elms.main_scaleFontUp:onmouseup() GUI.Label.onmouseup(self) ButtonScaleFontUp() end

  GUI.New("main_frame_footervertical_5", "Frame", LayerIndex.Main, GUI.w - (100 * RL.scaleFactor), GUI.h - (16 * RL.scaleFactor), 1.5 * RL.scaleFactor, 14 * RL.scaleFactor, false, false)

  function ButtonScaleDown() RL_ScaleInterfaceDown() end
  GUI.New("main_scaleInterfaceDown", "Label", LayerIndex.Main, GUI.w - (92 * RL.scaleFactor), GUI.h - (16.5 * RL.scaleFactor), "-", false, 3)
  function GUI.elms.main_scaleInterfaceDown:onmouseup() GUI.Label.onmouseup(self) ButtonScaleDown() end
  
  function ButtonScaleToggle() RL_ScaleInterfaceToggle() end
  GUI.New("main_scaleInterfaceToggle", "Label", LayerIndex.Main, GUI.w - (80.5 * RL.scaleFactor), GUI.h - (16.5 * RL.scaleFactor), "[  ]", false, 3)
  function GUI.elms.main_scaleInterfaceToggle:onmouseup() GUI.Label.onmouseup(self) ButtonScaleToggle() end

  function ButtonScaleUp() RL_ScaleInterfaceUp() end
  GUI.New("main_scaleInterfaceUp", "Label", LayerIndex.Main, GUI.w - (60 * RL.scaleFactor), GUI.h - (16.5 * RL.scaleFactor), "+", false, 3)
  function GUI.elms.main_scaleInterfaceUp:onmouseup() GUI.Label.onmouseup(self) ButtonScaleUp() end
  
  GUI.New("main_frame_footervertical_6", "Frame", LayerIndex.Main, GUI.w - (46 * RL.scaleFactor), GUI.h - (16 * RL.scaleFactor), 1.5 * RL.scaleFactor, 14 * RL.scaleFactor, false, false)

  GUI.New("main_btnToggleTooltips", "Label", LayerIndex.Main, GUI.w - (41.5 * RL.scaleFactor), GUI.h - (16 * RL.scaleFactor), "Tooltips", false, 3)
  function GUI.elms.main_btnToggleTooltips:onmouseup() GUI.Label.onmouseup(self) RL_ToggleTooltips() end
  
  if JSAPIinstalled then
    RL_Draw_PreviewSection()

    GUI.New("main_lblDates", "Label", LayerIndex.Global, 2.6 * pathX + (RL.scaleFactor * 5), footerY + (2.85 * RL.scaleFactor), "Date", false, 3)
    GUI.New("main_checklistDate", "Checklist", LayerIndex.Global, 3.1 * pathX + (RL.scaleFactor * 8), footerY + (3 * RL.scaleFactor), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "", "", 0)
    GUI.elms.main_checklistDate.shadow = false
    GUI.elms.main_checklistDate.opt_size = 15 * RL.scaleFactor
    GUI.elms.main_checklistDate:init()
    function GUI.elms.main_checklistDate:onmouseup() GUI.Checklist.onmouseup(self) Global_UpdateListDisplay() end
  end

  if SWSinstalled then
    RL_Draw_ThemeSlotSelector(0)
    GUI.New("main_frame_footervertical_1", "Frame", LayerIndex.Global, GUI.w - (278 * RL.scaleFactor), GUI.h - (16 * RL.scaleFactor), 1.5 * RL.scaleFactor, 14 * RL.scaleFactor, false, false)
    GUI.New("tab_recentProjects_btnLastActiveProject", "Label", LayerIndex.Global, GUI.w - (277.5 * RL.scaleFactor) + (RL.scaleFactor * 5), GUI.h - (16 * RL.scaleFactor), "Last Active", false, 3)
    function GUI.elms.tab_recentProjects_btnLastActiveProject:onmouseup() GUI.Label.onmouseup(self) RL_Context_LastActiveProjects()
    end
  end
end

local function RL_Draw_Frames()
  if RL.showButtonPanel then
    GUI.New("main_frame_top", "Frame", LayerIndex.Global, pad_left, listbox_top, GUI.w - pad_left, 2 * RL.scaleFactor, false, true)
    GUI.New("main_frame_side_2", "Frame", LayerIndex.Global, pad_left + listbox_w, (60 + btn_main_pad) * RL.scaleFactor, GUI.w - pad_left - listbox_w, 2 * RL.scaleFactor, true, true)
    GUI.New("main_frame_side_3", "Frame", LayerIndex.Global, pad_left + listbox_w, (123 + btn_main_pad) * RL.scaleFactor, GUI.w - pad_left - listbox_w, 2 * RL.scaleFactor, true, true)
    GUI.New("main_frame_side_4", "Frame", LayerIndex.Global, pad_left + listbox_w, (185 + btn_main_pad) * RL.scaleFactor, GUI.w - pad_left - listbox_w, 2 * RL.scaleFactor, true, true)
    GUI.New("main_frame_side_5", "Frame", LayerIndex.Global, pad_left + listbox_w, (248 + btn_main_pad) * RL.scaleFactor, GUI.w - pad_left - listbox_w, 2 * RL.scaleFactor, true, true)
    GUI.New("main_frame_side_6", "Frame", LayerIndex.Global, pad_left + listbox_w, (274 + btn_main_pad) * RL.scaleFactor, GUI.w - pad_left - listbox_w, 2 * RL.scaleFactor, true, true)
    GUI.New("main_frame_bottom_1", "Frame", LayerIndex.Global, pad_left, GUI.h - (45* RL.scaleFactor), GUI.w - pad_left, 2 * RL.scaleFactor, false, true)
  else
    GUI.New("main_frame_top", "Frame", LayerIndex.Global, pad_left, listbox_top, GUI.w - (2 * pad_left), 2 * RL.scaleFactor, false, true)
    GUI.New("main_frame_bottom_1", "Frame", LayerIndex.Global, pad_left, GUI.h - (45 * RL.scaleFactor), GUI.w - (2 * pad_left), 2 * RL.scaleFactor, false, true)

    if GUI.elms.main_frame_side_2 ~= nil then GUI.elms.main_frame_side_2:delete() end
    if GUI.elms.main_frame_side_3 ~= nil then GUI.elms.main_frame_side_3:delete() end
    if GUI.elms.main_frame_side_4 ~= nil then GUI.elms.main_frame_side_4:delete() end
    if GUI.elms.main_frame_side_5 ~= nil then GUI.elms.main_frame_side_5:delete() end
    if GUI.elms.main_frame_side_6 ~= nil then GUI.elms.main_frame_side_6:delete() end
  end
    
  GUI.New("main_frame_footer_vertical_1", "Frame", LayerIndex.Global, 4.6 * pathX + (RL.scaleFactor * 15), GUI.h - (42 * RL.scaleFactor), 1.5 * RL.scaleFactor, 22 * RL.scaleFactor, false, false)
  GUI.New("main_frame_footer_vertical_2", "Frame", LayerIndex.Global, 7.6 * pathX + (RL.scaleFactor * 15), GUI.h - (42 * RL.scaleFactor), 1.5 * RL.scaleFactor, 22 * RL.scaleFactor, false, false)
  GUI.New("main_frame_bottom_2", "Frame", LayerIndex.Main, 0, GUI.h - (19 * RL.scaleFactor), GUI.w, 1.5 * RL.scaleFactor, false, false)
end

---------------------------------------------------
-- Override Window functions with minor adjustments
---------------------------------------------------
function GUI.Window:drawwindow()
  local x, y, w, h = self.x, self.y, self.w, self.h
  local cs = self.close_size
  local off = (self.title_height * (0.5 * RL.scaleFactor) - cs) / 2 + 2 -- adjusted value

  -- Copy the pre-drawn bits
  gfx.blit(self.buffs[1], 1, 0, 0, 0, w, h, x, y)
  if not self.noclose then gfx.blit(self.buffs[2], 1, 0, self.hoverclose and cs or 0, 0, cs, cs, x + w - cs - off, y + off) end
end

function GUI.Window:init()
  local x, y, w, h = self.x, self.y, self.w, self.h
  -- buffs[3] will be filled at :open
  self.buffs = self.buffs or GUI.GetBuffer(3)
  local th, cs = self.title_height * (0.5 * RL.scaleFactor), self.close_size -- adjusted value

  -- Window frame/background
  gfx.dest = self.buffs[1]
  gfx.setimgdim(self.buffs[1], -1, -1)
  gfx.setimgdim(self.buffs[1], w, h)

  GUI.color("elm_frame")
  GUI.roundrect(0, 0, w - 2, h - 2, 4, true, true)

  GUI.color("wnd_bg")
  gfx.rect(4, th + 4, w - 10, h - (th + 10), true)

  -- [Close] button
  gfx.dest = self.buffs[2]
  gfx.setimgdim(self.buffs[2], -1, -1)
  gfx.setimgdim(self.buffs[2], 2*cs, cs)

  GUI.font(2)
  local str_w, str_h = gfx.measurestr("x")

  local function draw_x(x, y, w)
    gfx.line(x, y, x + w - 1, y + w - 1, false)
    gfx.line(x, y + 1, x + w - 2, y + w - 1, false)
    gfx.line(x + 1, y, x + w - 1, y + w - 2, false)
    gfx.line(x, y + w - 1, x + w - 1, y, false)
    gfx.line(x, y + w - 2, x + w - 2, y, false)
    gfx.line(x + 1, y + w - 1, x + w - 1, y + 1, false)
  end

  -- Background
  GUI.color("elm_frame")
  gfx.rect(0, 0, 2*cs, cs, true)

  GUI.color("txt")
  draw_x(2, 2, cs - 4)

  -- Mouseover circle
  GUI.color("elm_fill")
  GUI.roundrect(cs, 0, cs - 1, cs - 1, 4, true, true)

  GUI.color("wnd_bg")
  draw_x(cs + 2, 2, cs - 4)
end

function GUI.Window:drawcaption()
  GUI.font(2)
  GUI.color("txt")
  local str_w, str_h = gfx.measurestr(self.caption)
  gfx.x = self.x + (self.w - str_w) / 2
  gfx.y = self.y + (pad_top + self.title_height - str_h) / 2 + 1 -- adjusted value
  gfx.drawstr(self.caption)
end
----------
-- Dialogs
----------
Dialog = {
  mode,
  id,
  input,
  message,
  parameter
}

local function RL_Dialog_Open()
  RL.dialogKeyMode = true
  if Dialog.mode == "Confirm" then
    RL_InitConfirmDialog() 
    GUI.elms.confirmDialog_window:open()
  end
end

local function RL_Dialog_Close()
  RL.dialogKeyMode = false

  if Dialog.mode == "Confirm" then
    GUI.elms.confirmDialog_window:close()

    GUI.elms.confirmDialog_window:ondelete()
    GUI.elms.confirmDialog_label:ondelete()
    GUI.elms.confirmDialog_btnOK:ondelete()
    GUI.elms.confirmDialog_btnCancel:ondelete()
  end
end

local function RL_Dialog_OK()
  if Dialog.mode == "Confirm" then
    -- recent projects
    if Dialog.id == "RemoveRecentEntry" then RecentProjects_RemoveEntry() end
    if Dialog.id == "ClearRecentList" then RecentProjects_ClearList() end
    -- favorites
    if Dialog.id == "RemoveFavoritesEntry" then Favorites_RemoveEntry() end
    if Dialog.id == "ClearFavoritesList" then Favorites_ClearList() end
  end
  RL_Dialog_Close()
end

local function RL_ConfirmDialog_RemoveRecentEntry()
  Dialog.mode = "Confirm"
  Dialog.id = "RemoveRecentEntry"
  Dialog.caption = "Remove selected entries?"
  RL_Dialog_Open()
end

local function RL_ConfirmDialog_ClearRecentList()
  Dialog.mode = "Confirm"
  Dialog.id = "ClearRecentList"
  Dialog.caption = "Clear Recent Projects list?"
  RL_Dialog_Open()
end

function RL_ConfirmDialog_RemoveFavoritesEntry()
  local vals = GetSelectionTable(GUI.Val("tab_favorites_listbox"))
  if #vals == 0 then MsgStatusBar("No files selected in list")
  else
    Dialog.mode = "Confirm"
    Dialog.id = "RemoveFavoritesEntry"
    Dialog.caption = "Remove selected entries?"
    RL_Dialog_Open()
  end
end

local function RL_ConfirmDialog_ClearFavoritesList()
  Dialog.mode = "Confirm"
  Dialog.id = "ClearFavoritesList"
  Dialog.caption = "Clear this Favorites list?"
  RL_Dialog_Open()
end

function RL_InitConfirmDialog(dialogType)
  local dialogWidth = GUI.w * 0.75
  local dialogHeight = GUI.h * 0.3
  local dialogButtonWidth = GUI.w * 0.3 - pad_left
  local dialogButtonHeight = 16 * RL.scaleFactor
  local footerY = dialogHeight * 0.5

  GUI.New("confirmDialog_window", "Window", LayerIndex.ConfirmDialogWindow, 0, 0, dialogWidth, dialogHeight, "", {LayerIndex.ConfirmDialogContent, LayerIndex.ConfirmDialogWindow})
  GUI.New("confirmDialog_label", "Label", LayerIndex.ConfirmDialogContent, 2 * pad_left, (26 * RL.scaleFactor), "", false, 3)
  GUI.New("confirmDialog_btnCancel", "Button", LayerIndex.ConfirmDialogContent, 2 * pad_left, footerY, dialogButtonWidth, dialogButtonHeight, "Cancel", RL_Dialog_Close)
  GUI.New("confirmDialog_btnOK", "Button", LayerIndex.ConfirmDialogContent, dialogWidth - (3 * pad_left) - dialogButtonWidth, footerY, dialogButtonWidth, dialogButtonHeight, "OK", RL_Dialog_OK)
  
  GUI.elms_hide[LayerIndex.ConfirmDialogContent] = true
  GUI.elms_hide[LayerIndex.ConfirmDialogWindow] = true

  function GUI.elms.confirmDialog_window:onopen()
    self:adjustelm(GUI.elms.confirmDialog_label)
    self:adjustelm(GUI.elms.confirmDialog_btnCancel)
    self:adjustelm(GUI.elms.confirmDialog_btnOK)
    GUI.Val("confirmDialog_label", Dialog.message)
    self.caption = Dialog.caption
  end

  GUI.elms.confirmDialog_btnOK.col_fill = "wnd_bg"
  GUI.elms.confirmDialog_btnOK:init()
  GUI.elms.confirmDialog_btnCancel.col_fill = "wnd_bg"
  GUI.elms.confirmDialog_btnCancel:init()
end

------------------------
-- Tab - Recent Projects
------------------------
local function RL_Draw_TabRecentProjects()
  GUI.New("tab_recentProjects_btnRefresh", "Button", LayerIndex.RecentProjects, refreshX, refreshY, refreshW, refreshH, "Refresh", RefreshRecentProjects)
  GUI.New("tab_recentProjects_txtFilter", "Textbox", LayerIndex.RecentProjects, filterX, filterY, filterW, filterH, "", 8)
  GUI.elms.tab_recentProjects_txtFilter.tab_idx = 1
  GUI.New("tab_recentProjects_btnFilterClear", "Label", LayerIndex.RecentProjects, filterX + filterW + 10, filterY + (filterH * 0.1), "x", false, 3)
  function GUI.elms.tab_recentProjects_btnFilterClear:onmouseup() GUI.Label.onmouseup(self) Filter_RecentProject_Clear() end

  GUI.New("tab_recentProjects_listbox", "Listbox", LayerIndex.RecentProjects, pad_left, listbox_top, listbox_w, listbox_h, "", true)
  GUI.elms.tab_recentProjects_listbox.tab_idx = 2
  GUI.Val("tab_recentProjects_listbox", {1})

  if RL.showButtonPanel then
    GUI.New("tab_recentProjects_btnLoadInTab", "Button", LayerIndex.RecentProjects, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_RecentProject)
    GUI.New("tab_recentProjects_btnLoad", "Button", LayerIndex.RecentProjects, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_RecentProject)
  else
    if GUI.elms.tab_recentProjects_btnLoadInTab ~= nil then GUI.elms.tab_recentProjects_btnLoadInTab:delete() end
    if GUI.elms.tab_recentProjects_btnLoad ~= nil then GUI.elms.tab_recentProjects_btnLoad:delete() end
  end

  function GUI.elms.tab_recentProjects_listbox:onmousedown()
    TabSelectionIndex[TabID.RecentProjects] = self:getitem(GUI.mouse.y)
    Global_ShowPathInStatusbar(TabID.RecentProjects)
    if JSAPIinstalled then AudioPreviewCheckForFile(TabID.RecentProjects) end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_recentProjects_listbox:ondoubleclick()
    GUI.Listbox.ondoubleclick(self)
    RL_Mouse_DoubleClick(TabID.RecentProjects)
  end
  
  if SWSinstalled then 
    function GUI.elms.tab_recentProjects_listbox:onmouser_down()
      RL_Context_RecentProjects()
      GUI.Listbox.onmouser_down(self)
    end

    function GUI.elms.tab_recentProjects_listbox:onmousem_down()
      RL_Context_Main_RecentProjects()
      GUI.Listbox.onmousem_down(self)
    end
  end

  function RL_Context_RecentProjects()
    if RL.showLastActiveProjects then return end
    if GetMainListSize() > 0 then
      gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
      local vals = GetSelectionTable(GUI.Val("tab_recentProjects_listbox"))
      if #vals == 0 then
        if gfx.showmenu("1 - Clear entire list") == 1 then RL_ConfirmDialog_ClearRecentList() end
      else
        local RMBmenu = gfx.showmenu("1 - Remove selected entries|#|2 - Clear entire list")
        if RMBmenu == 1 then RL_ConfirmDialog_RemoveRecentEntry()
          elseif RMBmenu == 2 then RL_ConfirmDialog_ClearRecentList()
        end
      end
    end
  end

  function GUI.elms.tab_recentProjects_txtFilter:ontype()
      GUI.Textbox.ontype(self)
      Filter_RecentProject_Apply()
  end

  function GUI.elms.tab_recentProjects_txtFilter:lostfocus()
    RL.keyInputActive = true
    TabSelectionIndex[TabID.RecentProjects] = 0
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.tab_recentProjects_txtFilter:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end
end

--------------------------
-- Tab - Project Templates
--------------------------
local function RL_Draw_TabProjectTemplates()
  GUI.New("tab_projectTemplates_btnRefresh", "Button", LayerIndex.ProjectTemplates, refreshX, refreshY, refreshW, refreshH, "Refresh", RebuildCache)
  GUI.New("tab_projectTemplates_txtFilter", "Textbox", LayerIndex.ProjectTemplates, filterX, filterY, filterW, filterH, "", 8)
  GUI.elms.tab_projectTemplates_txtFilter.tab_idx = 1
  GUI.New("tab_projectTemplates_btnFilterClear", "Label", LayerIndex.ProjectTemplates, filterX + filterW + 10, filterY + (filterH * 0.1), "x", false, 3)
  function GUI.elms.tab_projectTemplates_btnFilterClear:onmouseup() GUI.Label.onmouseup(self) Filter_ProjectTemplate_Clear() end

  function GUI.elms.tab_projectTemplates_btnRefresh:onmouser_up()
    GUI.Button.onmouser_up(self)
    RefreshProjectTemplates()
  end

  if ShowSubfolderPanel(TabID.ProjectTemplates) then GUI.New("tab_projectTemplates_listbox", "Listbox", LayerIndex.ProjectTemplates, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  else GUI.New("tab_projectTemplates_listbox", "Listbox", LayerIndex.ProjectTemplates, pad_left, listbox_top, listbox_w, listbox_h, "", true) end
  GUI.elms.tab_projectTemplates_listbox.tab_idx = 2
  GUI.Val("tab_projectTemplates_listbox", {1})
  
  if RL.showButtonPanel then
    GUI.New("tab_projectTemplates_btnLoadInTab", "Button", LayerIndex.ProjectTemplates, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_ProjectTemplate)
    GUI.New("tab_projectTemplates_btnLoad", "Button", LayerIndex.ProjectTemplates, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_ProjectTemplate)

    GUI.New("tab_projectTemplates_lblEditMode", "Label", LayerIndex.ProjectTemplates, GUI.w - (140 * RL.scaleFactor) + (RL.scaleFactor * 10), (255 + btn_main_pad) * RL.scaleFactor, "Edit Template Mode", false, 3)
    GUI.New("tab_projectTemplates_checklistEditMode", "Checklist", LayerIndex.ProjectTemplates, GUI.w - (38 * RL.scaleFactor) + (RL.scaleFactor * 10), (252 + btn_main_pad) * RL.scaleFactor + (RL.scaleFactor * 2), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "", "h", 0)
    GUI.elms.tab_projectTemplates_checklistEditMode.shadow = false
    GUI.elms.tab_projectTemplates_checklistEditMode.opt_size = 15 * RL.scaleFactor
    GUI.elms.tab_projectTemplates_checklistEditMode:init()

    function GUI.elms.tab_projectTemplates_checklistEditMode:onmousedown()
      RL.projectTemplateLoadMode = GUI.Val("tab_projectTemplates_checklistEditMode")
    end
  else
    if GUI.elms.tab_projectTemplates_btnLoadInTab ~= nil then GUI.elms.tab_projectTemplates_btnLoadInTab:delete() end
    if GUI.elms.tab_projectTemplates_btnLoad ~= nil then GUI.elms.tab_projectTemplates_btnLoad:delete() end
    if GUI.elms.tab_projectTemplates_lblEditMode ~= nil then GUI.elms.tab_projectTemplates_lblEditMode:delete() end
    if GUI.elms.tab_projectTemplates_checklistEditMode ~= nil then GUI.elms.tab_projectTemplates_checklistEditMode:delete() end
  end

  if ShowSubfolderPanel(TabID.ProjectTemplates) then
    GUI.New("tab_projectTemplates_subfolders", "Listbox", LayerIndex.ProjectTemplates, pad_left, listbox_top, listbox_w/3, listbox_h, "", true)
  
    function GUI.elms.tab_projectTemplates_subfolders:onmousedown()
      if GUI.elms.tab_projectTemplates_subfolders then 
        TabParentSelectionIndex[TabID.ProjectTemplates] = self:getitem(GUI.mouse.y)
        GUI.Listbox.onmousedown(self)
        UpdateProjectTemplateSubDirSelection()
      end
    end

    function UpdateProjectTemplateSubDirSelection()
      if GetSubListSize() > 0 then 
        if TabParentSelectionIndex[TabID.ProjectTemplates] == 1 then 
          FillProjectTemplateListbox()
          Filter_ProjectTemplate_Apply()
        else 
          local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.ProjectTemplates, TabParentSelectionIndex[TabID.ProjectTemplates])
          if cacheExists then FillProjectTemplateListBoxBase(cacheTable)
          else
            if RL.showSubFolderPaths then FillProjectTemplateListBoxBase(GetFiles(GUI.elms.tab_projectTemplates_subfolders.list[TabParentSelectionIndex[TabID.ProjectTemplates]], TabID.ProjectTemplates, FileTypes.rpp)) 
            else FillProjectTemplateListBoxBase(GetFiles(SubfolderPaths.projectTemplates[TabParentSelectionIndex[TabID.ProjectTemplates]], TabID.ProjectTemplates, FileTypes.rpp)) end
            RL_WriteToFileCache(CacheFile.ProjectTemplates, TabParentSelectionIndex[TabID.ProjectTemplates], GetSubTableByPathKey(ProjectTemplates.items), false)
          end
        end
        TabSelectionIndex[TabID.ProjectTemplates] = 1
        GUI.Val("tab_projectTemplates_listbox", {1})
      end
    end
  end

  function GUI.elms.tab_projectTemplates_listbox:onmousedown()
    TabSelectionIndex[TabID.ProjectTemplates] = self:getitem(GUI.mouse.y)
    Global_ShowPathInStatusbar(TabID.ProjectTemplates)
    if JSAPIinstalled then AudioPreviewCheckForFile(TabID.ProjectTemplates) end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_projectTemplates_listbox:onmousem_down()
    RL_Context_Main_ProjectTemplates()
    GUI.Listbox.onmousem_down(self)
  end

  function GUI.elms.tab_projectTemplates_listbox:ondoubleclick()
    GUI.Listbox.ondoubleclick(self)
    RL_Mouse_DoubleClick(TabID.ProjectTemplates)
  end
  
  function GUI.elms.tab_projectTemplates_txtFilter:ontype()
    GUI.Textbox.ontype(self)
    Filter_ProjectTemplate_Apply()
  end

  function GUI.elms.tab_projectTemplates_txtFilter:lostfocus()
    RL.keyInputActive = true
    TabSelectionIndex[TabID.ProjectTemplates] = 0
    GUI.Textbox.lostfocus(self)
  end
  
  function GUI.elms.tab_projectTemplates_txtFilter:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end
  
end

------------------------
-- Tab - Track Templates
------------------------
local function RL_Draw_TabTrackTemplates()
  GUI.New("tab_trackTemplates_btnRefresh", "Button", LayerIndex.TrackTemplates, refreshX, refreshY, refreshW, refreshH, "Refresh", RebuildCache)
  GUI.New("tab_trackTemplates_txtFilter", "Textbox", LayerIndex.TrackTemplates, filterX, filterY, filterW, filterH, "", 8)
  GUI.elms.tab_trackTemplates_txtFilter.tab_idx = 1
  GUI.New("tab_trackTemplates_btnFilterClear", "Label", LayerIndex.TrackTemplates, filterX + filterW + 10, filterY + (filterH * 0.1), "x", false, 3)
  function GUI.elms.tab_trackTemplates_btnFilterClear:onmouseup() GUI.Label.onmouseup(self) Filter_TrackTemplate_Clear() end
  
  function GUI.elms.tab_trackTemplates_btnRefresh:onmouser_up()
    GUI.Button.onmouser_up(self)
    RefreshTrackTemplates()
  end

  if ShowSubfolderPanel(TabID.TrackTemplates) then GUI.New("tab_trackTemplates_listbox", "Listbox", LayerIndex.TrackTemplates, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  else GUI.New("tab_trackTemplates_listbox", "Listbox", LayerIndex.TrackTemplates, pad_left, listbox_top, listbox_w, listbox_h, "", true) end
  GUI.elms.tab_trackTemplates_listbox.tab_idx = 2
  GUI.Val("tab_trackTemplates_listbox", {1})

  if RL.showButtonPanel then 
    GUI.New("tab_trackTemplates_btnInsertInTab", "Button", LayerIndex.TrackTemplates, btn_pad_left, btn_tab_top, btn_w, btn_h, "Insert in Tab", Load_TrackTemplateInTab)
    GUI.New("tab_trackTemplates_btnInsert", "Button", LayerIndex.TrackTemplates, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Insert", Load_TrackTemplate)
  else
    if GUI.elms.tab_trackTemplates_btnInsertInTab ~= nil then GUI.elms.tab_trackTemplates_btnInsertInTab:delete() end
    if GUI.elms.tab_trackTemplates_btnInsert ~= nil then GUI.elms.tab_trackTemplates_btnInsert:delete() end
  end

  if ShowSubfolderPanel(TabID.TrackTemplates) then 
    GUI.New("tab_trackTemplates_subfolders", "Listbox", LayerIndex.TrackTemplates, pad_left, listbox_top, listbox_w/3, listbox_h, "", true)
    
    function GUI.elms.tab_trackTemplates_subfolders:onmouseup()
      if GUI.elms.tab_trackTemplates_subfolders then 
        TabParentSelectionIndex[TabID.TrackTemplates] = self:getitem(GUI.mouse.y)
        GUI.Listbox.onmouseup(self)
        UpdateTrackTemplateSubDirSelection()
      end
    end
  
    function UpdateTrackTemplateSubDirSelection()
      if GetSubListSize() > 0 then
        if TabParentSelectionIndex[TabID.TrackTemplates] == 1 then 
          FillTrackTemplateListbox()
          Filter_TrackTemplate_Apply()
        else
          local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.TrackTemplates, TabParentSelectionIndex[TabID.TrackTemplates])
          if cacheExists then FillTrackTemplateListboxBase(cacheTable)
          else
            if RL.showSubFolderPaths then FillTrackTemplateListboxBase(GetFiles(GUI.elms.tab_trackTemplates_subfolders.list[TabParentSelectionIndex[TabID.TrackTemplates]], TabID.TrackTemplates, FileTypes.tracktemplate))
            else FillTrackTemplateListboxBase(GetFiles(SubfolderPaths.trackTemplates[TabParentSelectionIndex[TabID.TrackTemplates]], TabID.TrackTemplates, FileTypes.tracktemplate)) end
            RL_WriteToFileCache(CacheFile.TrackTemplates, TabParentSelectionIndex[TabID.TrackTemplates], GetSubTableByPathKey(TrackTemplates.items), false)
          end
        end
        TabSelectionIndex[TabID.TrackTemplates] = 1
        GUI.Val("tab_trackTemplates_listbox", {1})
      end
    end
  end
  
  function GUI.elms.tab_trackTemplates_listbox:onmousedown()
    TabSelectionIndex[TabID.TrackTemplates] = self:getitem(GUI.mouse.y)
    Global_ShowPathInStatusbar(TabID.TrackTemplates)
    if JSAPIinstalled then AudioPreviewCheckForFile(TabID.TrackTemplates) end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_trackTemplates_listbox:onmousem_down()
    RL_Context_Main_TrackTemplates()
    GUI.Listbox.onmousem_down(self)
  end

  function GUI.elms.tab_trackTemplates_listbox:ondoubleclick()
    GUI.Listbox.ondoubleclick(self)
    RL_Mouse_DoubleClick(TabID.TrackTemplates)
  end
  
  function GUI.elms.tab_trackTemplates_txtFilter:ontype()
     GUI.Textbox.ontype(self)
     Filter_TrackTemplate_Apply()
  end

  function GUI.elms.tab_trackTemplates_txtFilter:lostfocus()
    RL.keyInputActive = true
    TabSelectionIndex[TabID.TrackTemplates] = 0
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.tab_trackTemplates_txtFilter:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end
end

-----------------
-- Tab - Projects
-----------------
local function RL_Draw_TabCustomProjects()
  GUI.New("tab_customProjects_btnRefresh", "Button", LayerIndex.CustomProjects, refreshX, refreshY, refreshW, refreshH, "Refresh", RebuildCache)
  GUI.New("tab_customProjects_txtFilter", "Textbox", LayerIndex.CustomProjects, filterX, filterY, filterW, filterH, "", 8)
  GUI.elms.tab_customProjects_txtFilter.tab_idx = 1
  GUI.New("tab_customProjects_btnFilterClear", "Label", LayerIndex.CustomProjects, filterX + filterW + 10, filterY + (filterH * 0.1), "x", false, 3)
  function GUI.elms.tab_customProjects_btnFilterClear:onmouseup() GUI.Label.onmouseup(self) Filter_CustomProjects_Clear() end

  function GUI.elms.tab_customProjects_btnRefresh:onmouser_up()
    GUI.Button.onmouser_up(self)
    RefreshCustomProjects()
  end

  if ShowSubfolderPanel(TabID.CustomProjects) then GUI.New("tab_customProjects_listbox", "Listbox", LayerIndex.CustomProjects, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  else GUI.New("tab_customProjects_listbox", "Listbox", LayerIndex.CustomProjects, pad_left, listbox_top, listbox_w, listbox_h, "", true) end
  GUI.elms.tab_customProjects_listbox.tab_idx = 2
  GUI.Val("tab_customProjects_listbox", {1})

  if RL.showButtonPanel then
    GUI.New("tab_customProjects_btnLoadInTab", "Button", LayerIndex.CustomProjects, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_CustomProject)
    GUI.New("tab_customProjects_btnLoad", "Button", LayerIndex.CustomProjects, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_CustomProject)
  else
    if GUI.elms.tab_customProjects_btnLoadInTab ~= nil then GUI.elms.tab_customProjects_btnLoadInTab:delete() end
    if GUI.elms.tab_customProjects_btnLoad ~= nil then GUI.elms.tab_customProjects_btnLoad:delete() end
  end

  if ShowSubfolderPanel(TabID.CustomProjects) then 
    GUI.New("tab_customProjects_subfolders", "Listbox", LayerIndex.CustomProjects, pad_left, listbox_top, listbox_w/3, listbox_h, "", true)

    function GUI.elms.tab_customProjects_subfolders:onmousedown()
      if GUI.elms.tab_customProjects_subfolders then 
        TabParentSelectionIndex[TabID.CustomProjects] = self:getitem(GUI.mouse.y)
        GUI.Listbox.onmousedown(self)
        UpdateCustomProjectSubDirSelection()
      end
    end
  
    function UpdateCustomProjectSubDirSelection()
      if GetSubListSize() > 0 then
        if TabParentSelectionIndex[TabID.CustomProjects] == 1 then 
          FillCustomProjectsListbox()
          Filter_CustomProjects_Apply()
        else
          if RL.showSubFolderPaths then
            if TabParentSelectionIndex[TabID.CustomProjects] == 1 then
              FillCustomProjectsListbox()
            else
              CustomProjects.items, CustomProjects.display = {}, {}
              local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.CustomProjects, TabParentSelectionIndex[TabID.CustomProjects])
              if cacheExists then FillCustomProjectsListboxBase(cacheTable)
              else
                FillCustomProjectsListboxBase(GetFiles(GUI.elms.tab_customProjects_subfolders.list[TabParentSelectionIndex[TabID.CustomProjects]], TabID.CustomProjects, FileTypes.rpp), 1)
                RL_WriteToFileCache(CacheFile.CustomProjects, TabParentSelectionIndex[TabID.CustomProjects], GetSubTableByPathKey(CustomProjects.items), false)
              end
            end
          else
            CustomProjects.items, CustomProjects.display = {}, {}
            FillCustomProjectsListboxBase(GetFiles(SubfolderPaths.customProjects[TabParentSelectionIndex[TabID.CustomProjects]], TabID.CustomProjects, FileTypes.rpp), 1)
            RL_WriteToFileCache(CacheFile.CustomProjects, TabParentSelectionIndex[TabID.CustomProjects], GetSubTableByPathKey(CustomProjects.items), false)
          end
        end
        TabSelectionIndex[TabID.CustomProjects] = 1
        GUI.Val("tab_customProjects_listbox", {1})
      end
    end
  end

  function GUI.elms.tab_customProjects_listbox:onmousedown()
    TabSelectionIndex[TabID.CustomProjects] = self:getitem(GUI.mouse.y)
    Global_ShowPathInStatusbar(TabID.CustomProjects)
    if JSAPIinstalled then AudioPreviewCheckForFile(TabID.CustomProjects) end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_customProjects_listbox:onmousem_down()
    RL_Context_Main_CustomProjects()
    GUI.Listbox.onmousem_down(self)
  end

  function GUI.elms.tab_customProjects_listbox:ondoubleclick()
    GUI.Listbox.ondoubleclick(self)
    RL_Mouse_DoubleClick(TabID.CustomProjects)
  end
    
  function GUI.elms.tab_customProjects_txtFilter:ontype()
     GUI.Textbox.ontype(self)
     Filter_CustomProjects_Apply()
  end

  function GUI.elms.tab_customProjects_txtFilter:lostfocus()
    RL.keyInputActive = true
    TabSelectionIndex[TabID.CustomProjects] = 0
    GUI.Textbox.lostfocus(self)
  end
  
  function GUI.elms.tab_customProjects_txtFilter:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end
end

-----------------------------
-- Tab - Project Lists (.rpl)
-----------------------------
local function RL_Draw_TabProjectLists()
  GUI.New("tab_projectLists_btnRefresh", "Button", LayerIndex.ProjectLists, refreshX, refreshY, refreshW, refreshH, "Refresh", RebuildCache)
  GUI.New("tab_projectLists_txtFilter", "Textbox", LayerIndex.ProjectLists, filterX, filterY, filterW, filterH, "", 8)
  GUI.elms.tab_projectLists_txtFilter.tab_idx = 1
  GUI.New("tab_projectLists_btnFilterClear", "Label", LayerIndex.ProjectLists, filterX + filterW + 10, filterY + (filterH * 0.1), "x", false, 3)
  function GUI.elms.tab_projectLists_btnFilterClear:onmouseup() GUI.Label.onmouseup(self) Filter_ProjectLists_Clear() end

  function GUI.elms.tab_projectLists_btnRefresh:onmouser_up()
    GUI.Button.onmouser_up(self)
    RefreshProjectList()
  end

  if ShowSubfolderPanel(TabID.ProjectLists) then
    GUI.New("tab_projectLists_listboxRPL", "Listbox", LayerIndex.ProjectLists, pad_left, listbox_top, listbox_w/3, listbox_h, "", true)
    GUI.elms.tab_projectLists_listboxRPL.tab_idx = 2
    GUI.elms.tab_projectLists_listboxRPL.list = ProjectLists.rplFiles
    GUI.Val("tab_projectLists_listboxRPL", {1})

    function GUI.elms.tab_projectLists_listboxRPL:onmouseup()
      if GUI.elms.tab_projectLists_listboxRPL then 
        TabParentSelectionIndex[TabID.ProjectLists] = self:getitem(GUI.mouse.y)
        GUI.Listbox.onmouseup(self)
        if RL.sortModeIndex[GUI.elms.main_tabs.state] == 2 then UpdateProjectListSelection(true) else UpdateProjectListSelection(false) end
      end
    end

    GUI.New("tab_projectLists_listboxProjects", "Listbox", LayerIndex.ProjectLists, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  else
    GUI.New("tab_projectLists_listboxProjects", "Listbox", LayerIndex.ProjectLists, pad_left, listbox_top, listbox_w, listbox_h, "", true)
  end

  function GUI.elms.tab_projectLists_listboxProjects:onmousem_down()
    RL_Context_Main_ProjectLists()
    GUI.Listbox.onmousem_down(self)
  end
 
  if RL.showButtonPanel then
    GUI.New("tab_projectLists_btnLoadInTab", "Button", LayerIndex.ProjectLists, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_ProjectListProject)
    GUI.New("tab_projectLists_btnLoad", "Button", LayerIndex.ProjectLists, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_ProjectListProject)
  else
    if GUI.elms.tab_projectLists_btnLoadInTab ~= nil then GUI.elms.tab_projectLists_btnLoadInTab:delete() end
    if GUI.elms.tab_projectLists_btnLoad ~= nil then GUI.elms.tab_projectLists_btnLoad:delete() end
  end

  function UpdateProjectListSelection(listInReverse)
    if (ShowSubfolderPanel(TabID.ProjectLists) and GetSubListSize() > 0) then
      if TabParentSelectionIndex[TabID.ProjectLists] == 1 or not ShowSubfolderPanel(TabID.ProjectLists) then
        local vals = GUI.elms.tab_projectLists_listboxRPL.list
        if #vals > 0 then
          local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.ProjectLists, CacheFile.MainSection)
          if cacheExists then RPL_FillProjectListFromTable(cacheTable, listInReverse)
          else
            ProjectLists.projectItems, ProjectLists.display = {}, {}
            allRPLProjects = {}
            for v = 2, #vals do allRPLProjects[v - 1] = v end
            RPL_ParseRPLFile(allRPLProjects, listInReverse)
            TabSelectionIndex[TabID.ProjectLists] = 1
            GUI.Val("tab_projectLists_listboxProjects", {1})
            RL_WriteToFileCache(CacheFile.ProjectLists, TabParentSelectionIndex[TabID.ProjectLists], GetSubTableByPathKey(ProjectLists.projectItems), false)
            Global_UpdateListDisplay()
            ShowFileCount()
          end
        end
      else
        local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.ProjectLists, TabParentSelectionIndex[TabID.ProjectLists])
        if cacheExists then RPL_FillProjectListFromTable(cacheTable, listInReverse)
        else 
          if GetSubListSize() > 0 then
            ProjectLists.projectItems, ProjectLists.display = {}, {}
            RPL_ParseRPLFile(GetSelectionTable(GUI.Val("tab_projectLists_listboxRPL")), listInReverse)
            TabSelectionIndex[TabID.ProjectLists] = 1
            GUI.Val("tab_projectLists_listboxProjects", {1})
            RL_WriteToFileCache(CacheFile.ProjectLists, TabParentSelectionIndex[TabID.ProjectLists], GetSubTableByPathKey(ProjectLists.projectItems), false)
            Global_UpdateListDisplay()
            ShowFileCount()
          end
        end
      end
    end
  end

  function GUI.elms.tab_projectLists_listboxProjects:onmousedown()
    TabSelectionIndex[TabID.ProjectLists] = self:getitem(GUI.mouse.y)
    if JSAPIinstalled then AudioPreviewCheckForFile(TabID.ProjectLists) end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_projectLists_listboxProjects:ondoubleclick()
    GUI.Listbox.ondoubleclick(self)
    RL_Mouse_DoubleClick(TabID.ProjectLists)
  end

  function GUI.elms.tab_projectLists_txtFilter:ontype()
    GUI.Textbox.ontype(self)
    Filter_ProjectLists_Apply()
  end

  function GUI.elms.tab_projectLists_txtFilter:lostfocus()
    RL.keyInputActive = true
    TabSelectionIndex[TabID.ProjectLists] = 0
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.tab_projectLists_txtFilter:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end

end -- of RL_Draw_TabProjectLists
---------------------------
-- Tab - Backups (.rpp-bak)
---------------------------
local function RL_Draw_TabBackups()
  GUI.New("tab_backups_btnRefresh", "Button", LayerIndex.Backups, refreshX, refreshY, refreshW, refreshH, "Refresh", RebuildCache)
  GUI.New("tab_backups_txtFilter", "Textbox", LayerIndex.Backups, filterX, filterY, filterW, filterH, "", 8)
  GUI.elms.tab_backups_txtFilter.tab_idx = 1
  GUI.New("tab_backups_btnFilterClear", "Label", LayerIndex.Backups, filterX + filterW + 10, filterY + (filterH * 0.1), "x", false, 3)
  function GUI.elms.tab_backups_btnFilterClear:onmouseup() GUI.Label.onmouseup(self) Filter_Backups_Clear() end

  function GUI.elms.tab_backups_btnRefresh:onmouser_up()
    GUI.Button.onmouser_up(self)
    RefreshBackups()
  end

  if ShowSubfolderPanel(TabID.Backups) then GUI.New("tab_backups_listbox", "Listbox", LayerIndex.Backups, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  else GUI.New("tab_backups_listbox", "Listbox", LayerIndex.Backups, pad_left, listbox_top, listbox_w, listbox_h, "", true) end
  GUI.elms.tab_backups_listbox.tab_idx = 2
  GUI.Val("tab_backups_listbox", {1})

  if RL.showButtonPanel then
    GUI.New("tab_backups_btnLoadInTab", "Button", LayerIndex.Backups, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_BackupFile)
    GUI.New("tab_backups_btnLoad", "Button", LayerIndex.Backups, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_BackupFile)
  else
    if GUI.elms.tab_backups_btnLoadInTab ~= nil then GUI.elms.tab_backups_btnLoadInTab:delete() end
    if GUI.elms.tab_backups_btnLoad ~= nil then GUI.elms.tab_backups_btnLoad:delete() end
  end

  if ShowSubfolderPanel(TabID.Backups) then
    GUI.New("tab_backups_subfolders", "Listbox", LayerIndex.Backups, pad_left, listbox_top, listbox_w/3, listbox_h, "", true)

    function GUI.elms.tab_backups_subfolders:onmousedown()
      if GUI.elms.tab_backups_subfolders then 
        TabParentSelectionIndex[TabID.Backups] = self:getitem(GUI.mouse.y)
        GUI.Listbox.onmousedown(self)
        UpdateBackupsSubDirSelection()
      end
    end
  
    function UpdateBackupsSubDirSelection()
      if GetSubListSize() > 0 then
        if TabParentSelectionIndex[TabID.Backups] == 1 then 
          FillBackupsListbox()
          Filter_Backups_Apply()
        else 
          if RL.showSubFolderPaths then 
            if TabParentSelectionIndex[TabID.Backups] == 1 then 
              FillBackupsListbox()
            else
              Backups.items, Backups.display = {}, {}
              local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.Backups, TabParentSelectionIndex[TabID.Backups])
              if cacheExists then FillBackupsListboxBase(cacheTable, 1)
              else
                FillBackupsListboxBase(GetFiles(GUI.elms.tab_backups_subfolders.list[TabParentSelectionIndex[TabID.Backups]], TabID.Backups, FileTypes.backup), 1)
                RL_WriteToFileCache(CacheFile.Backups, TabParentSelectionIndex[TabID.Backups], GetSubTableByPathKey(Backups.items), false)
              end
            end
          else
            Backups.items, Backups.display = {}, {}
            FillBackupsListboxBase(GetFiles(SubfolderPaths.backups[TabParentSelectionIndex[TabID.Backups]], TabID.Backups, FileTypes.backup), 1)
            RL_WriteToFileCache(CacheFile.Backups, TabParentSelectionIndex[TabID.Backups], GetSubTableByPathKey(Backups.items), false)
          end
        end
        TabSelectionIndex[TabID.Backups] = 1
        GUI.Val("tab_backups_listbox", {1})
      end
    end
  end

  function GUI.elms.tab_backups_listbox:onmousedown()
    TabSelectionIndex[TabID.Backups] = self:getitem(GUI.mouse.y)
    Global_ShowPathInStatusbar(TabID.Backups)
    if JSAPIinstalled then AudioPreviewCheckForFile(TabID.Backups) end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_backups_listbox:onmousem_down()
    RL_Context_Main_Backups()
    GUI.Listbox.onmousem_down(self)
  end

  function GUI.elms.tab_backups_listbox:ondoubleclick()
    GUI.Listbox.ondoubleclick(self)
    RL_Mouse_DoubleClick(TabID.Backups)
  end
    
  function GUI.elms.tab_backups_txtFilter:ontype()
    GUI.Textbox.ontype(self)
    Filter_Backups_Apply()
  end

  function GUI.elms.tab_backups_txtFilter:lostfocus()
    RL.keyInputActive = true
    TabSelectionIndex[TabID.Backups] = 0
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.tab_backups_txtFilter:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end
end

-------------
-- Tab - Docs
-------------
function Load_DocFile()
  if GetMainListSize() > 0 then
    local selectedDocFile
    local vals = GetSelectionTable(GUI.Val("tab_docs_listbox"))
    for p = 1, #vals do
      if FilterActive.Docs then selectedDocFile = RemoveWhiteSpaces(Docs.filteredItems[vals[p]].path)
      else selectedDocFile = RemoveWhiteSpaces(Docs.items[vals[p]].path) end
      if selectedDocFile ~= nil then 
        reaper.CF_ShellExecute(selectedDocFile)
      end
    end 
    Global_CheckWindowPinState()
  end
end

local function RL_Draw_TabDocs()
  GUI.New("tab_docs_btnRefresh", "Button", LayerIndex.Docs, refreshX, refreshY, refreshW, refreshH, "Refresh", RebuildCache)
  GUI.New("tab_docs_txtFilter", "Textbox", LayerIndex.Docs, filterX, filterY, filterW, filterH, "", 8)
  GUI.elms.tab_docs_txtFilter.tab_idx = 1
  GUI.New("tab_docs_btnFilterClear", "Label", LayerIndex.Docs, filterX + filterW + 10, filterY + (filterH * 0.1), "x", false, 3)
  function GUI.elms.tab_docs_btnFilterClear:onmouseup() GUI.Label.onmouseup(self) Filter_Docs_Clear() end

  function GUI.elms.tab_docs_btnRefresh:onmouser_up()
    GUI.Button.onmouser_up(self)
    RefreshDocs()
  end

  if ShowSubfolderPanel(TabID.Docs) then GUI.New("tab_docs_listbox", "Listbox", LayerIndex.Docs, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  else GUI.New("tab_docs_listbox", "Listbox", LayerIndex.Docs, pad_left, listbox_top, listbox_w, listbox_h, "", true) end
  GUI.elms.tab_docs_listbox.tab_idx = 2
  GUI.Val("tab_docs_listbox", {1})

  if RL.showButtonPanel then
    GUI.New("tab_docs_btnOpen", "Button", LayerIndex.Docs, btn_pad_left, btn_tab_top + (20 * RL.scaleFactor) - (5 * RL.scaleFactor), btn_w, btn_h, "Open", Load_DocFile)
  else
    if GUI.elms.tab_docs_btnOpen ~= nil then GUI.elms.tab_docs_btnOpen:delete() end
  end

  if ShowSubfolderPanel(TabID.Docs) then
    GUI.New("tab_docs_subfolders", "Listbox", LayerIndex.Docs, pad_left, listbox_top, listbox_w/3, listbox_h, "", true)
  
    function GUI.elms.tab_docs_subfolders:onmousedown()
      if GUI.elms.tab_docs_subfolders then 
        TabParentSelectionIndex[TabID.Docs] = self:getitem(GUI.mouse.y)
        GUI.Listbox.onmousedown(self)
        UpdateDocsSubDirSelection()
      end
    end

    function UpdateDocsSubDirSelection()
      if GetSubListSize() > 0 then 
        if TabParentSelectionIndex[TabID.Docs] == 1 then 
          FillDocsListbox()
          Filter_Docs_Apply()
        else 
          if RL.showSubFolderPaths then 
            if TabParentSelectionIndex[TabID.Docs] == 1 then 
              FillDocsListbox()
            else
              Docs.items, Docs.display = {}, {}
              local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.TrackTemplates, TabParentSelectionIndex[TabID.Docs])
              if cacheExists then
                FillDocsListboxBase(cacheTable)
              else
                FillDocsListboxBase(GetFiles(GUI.elms.tab_docs_subfolders.list[TabParentSelectionIndex[TabID.Docs]], TabID.Docs, FileTypes.docs), 1)
                RL_WriteToFileCache(CacheFile.Docs, TabParentSelectionIndex[TabID.Docs], GetSubTableByPathKey(Docs.items), false)
              end
            end
          else
            Docs.items, Docs.display = {}, {}
            FillDocsListboxBase(GetFiles(SubfolderPaths.docs[TabParentSelectionIndex[TabID.Docs]], TabID.Docs, FileTypes.docs), 1)
            RL_WriteToFileCache(CacheFile.Docs, TabParentSelectionIndex[TabID.Docs], GetSubTableByPathKey(Docs.items), false)
          end
        end
        TabSelectionIndex[TabID.Docs] = 1
        GUI.Val("tab_docs_listbox", {1})
      end
    end
  end

  function GUI.elms.tab_docs_listbox:onmousedown()
    TabSelectionIndex[TabID.Docs] = self:getitem(GUI.mouse.y)
    Global_ShowPathInStatusbar(TabID.Docs)
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_docs_listbox:onmousem_down()
    RL_Context_Main_Docs()
    GUI.Listbox.onmousem_down(self)
  end

  function GUI.elms.tab_docs_listbox:ondoubleclick()
    GUI.Listbox.ondoubleclick(self)
    Load_DocFile()
  end
    
  function GUI.elms.tab_docs_txtFilter:ontype()
    GUI.Textbox.ontype(self)
    Filter_Docs_Apply()
  end

  function GUI.elms.tab_docs_txtFilter:lostfocus()
    RL.keyInputActive = true
    TabSelectionIndex[TabID.Docs] = 0
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.tab_docs_txtFilter:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end
end

------------------
-- Tab - Favorites
------------------
Favorites = {
  items = {},
  filteredItems = {},
  display = {},
  filteredDisplay = {}
}

local function RefreshFavorites()
  MsgDebug("\nRefresh Favorites")
  GUI.Val("tab_favorites_categories", TabParentSelectionIndex[TabID.Favorites])
  FillFavoritesListbox()
end

function Load_Favorites_Base(tabmode)
  if GetMainListSize() > 0 then
    local category = TabParentSelectionIndex[TabID.Favorites]
    local selectedEntry
    local vals = GetSelectionTable(GUI.Val("tab_favorites_listbox"))
    for p = 1, #vals do
      if FilterActive.Favorites then selectedEntry = RemoveWhiteSpaces(Favorites.filteredItems[vals[p]].path)
      else selectedEntry = RemoveWhiteSpaces(Favorites.items[vals[p]].path) end
      if selectedEntry ~= nil then
        if category == TabID.TrackTemplates then
          if tabmode then reaper.Main_OnCommand(41929, 0) end -- New project tab (ignore default template)
          reaper.Main_openProject(selectedEntry)
        elseif category == TabID.ProjectTemplates then
          if tabmode then
            reaper.Main_OnCommand(41929, 0) -- New project tab (ignore default template)
            Global_ProjectTemplateLoadBase(selectedEntry)
          else
            Global_ProjectTemplateLoad(selectedEntry, p)
          end
        elseif category == TabID.Docs then reaper.CF_ShellExecute(selectedEntry)
        elseif category == TabID.RecentProjects or category == TabID.CustomProjects or category == TabID.ProjectLists or category == TabID.Backups then
          Global_Load(tabmode, selectedEntry, p)
        end
      end
    end 
    Global_CheckWindowPinState()
  end
end

function LoadInTab_FavoritesFile()
  Load_Favorites_Base(true)
end

function Load_FavoritesFile()
  Load_Favorites_Base(false)
end

function RL_Draw_FavoritesButtons()
  local selection = TabParentSelectionIndex[TabID.Favorites]

  -- draw buttons
  if selection == TabID.RecentProjects or selection == TabID.ProjectTemplates or selection == TabID.CustomProjects or selection == TabID.ProjectLists or selection == TabID.Backups then
    if GUI.elms.tab_favorites_btnOpen ~= nil then GUI.elms.tab_favorites_btnOpen:delete() end
    if GUI.elms.tab_favorites_btnInsertInTab ~= nil then GUI.elms.tab_favorites_btnInsertInTab:delete() end
    if GUI.elms.tab_favorites_btnInsert ~= nil then GUI.elms.tab_favorites_btnInsert:delete() end
    if RL.showButtonPanel then
      GUI.New("tab_favorites_btnLoadInTab", "Button", LayerIndex.Favorites, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_FavoritesFile)
      GUI.New("tab_favorites_btnLoad", "Button", LayerIndex.Favorites, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_FavoritesFile)
    else
      if GUI.elms.tab_favorites_btnLoadInTab ~= nil then GUI.elms.tab_favorites_btnLoadInTab:delete() end
      if GUI.elms.tab_favorites_btnLoad ~= nil then GUI.elms.tab_favorites_btnLoad:delete() end
    end
    if GUI.elms.tab_favorites_btnLoadInTab ~= nil then
      GUI.elms.tab_favorites_btnLoadInTab.col_fill = "wnd_bg"
      GUI.elms.tab_favorites_btnLoadInTab:init()
    end
    if GUI.elms.tab_favorites_btnLoad ~= nil then
      GUI.elms.tab_favorites_btnLoad.col_fill = "wnd_bg"
      GUI.elms.tab_favorites_btnLoad:init()
    end
  elseif selection == TabID.TrackTemplates then
    if GUI.elms.tab_favorites_btnLoadInTab ~= nil then GUI.elms.tab_favorites_btnLoadInTab:delete() end
    if GUI.elms.tab_favorites_btnLoad ~= nil then GUI.elms.tab_favorites_btnLoad:delete() end
    if GUI.elms.tab_favorites_btnOpen ~= nil then GUI.elms.tab_favorites_btnOpen:delete() end
    GUI.New("tab_favorites_btnInsertInTab", "Button", LayerIndex.Favorites, btn_pad_left, btn_tab_top , btn_w, btn_h, "Insert in Tab", LoadInTab_FavoritesFile)
    GUI.New("tab_favorites_btnInsert", "Button", LayerIndex.Favorites, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Insert", Load_FavoritesFile)
    if GUI.elms.tab_favorites_btnInsertInTab ~= nil then
      GUI.elms.tab_favorites_btnInsertInTab.col_fill = "wnd_bg"
      GUI.elms.tab_favorites_btnInsertInTab:init()
    end
    if GUI.elms.tab_favorites_btnInsert ~= nil then
      GUI.elms.tab_favorites_btnInsert.col_fill = "wnd_bg"
      GUI.elms.tab_favorites_btnInsert:init()
    end
  elseif selection == TabID.Docs then
    if GUI.elms.tab_favorites_btnLoadInTab ~= nil then GUI.elms.tab_favorites_btnLoadInTab:delete() end
    if GUI.elms.tab_favorites_btnLoad ~= nil then GUI.elms.tab_favorites_btnLoad:delete() end
    if GUI.elms.tab_favorites_btnInsertInTab ~= nil then GUI.elms.tab_favorites_btnInsertInTab:delete() end
    if GUI.elms.tab_favorites_btnInsert ~= nil then GUI.elms.tab_favorites_btnInsert:delete() end
    GUI.New("tab_favorites_btnOpen", "Button", LayerIndex.Favorites, btn_pad_left, btn_tab_top + (20 * RL.scaleFactor) - (5 * RL.scaleFactor), btn_w, btn_h, "Open", Load_FavoritesFile)
    if GUI.elms.tab_favorites_btnOpen ~= nil then
      GUI.elms.tab_favorites_btnOpen.col_fill = "wnd_bg"
      GUI.elms.tab_favorites_btnOpen:init()
    end
  end

  -- draw checkboxes
  if selection == TabID.ProjectTemplates then
    if GUI.elms.tab_favorites_lblSaveNewVersion ~= nil then GUI.elms.tab_favorites_lblSaveNewVersion:delete() end
    if GUI.elms.tab_favorites_checklistSaveAsNewVersion ~= nil then GUI.elms.tab_favorites_checklistSaveAsNewVersion:delete() end
    if RL.showButtonPanel then 
      GUI.New("tab_favorites_lblEditMode", "Label", LayerIndex.Favorites, GUI.w - (140 * RL.scaleFactor) + (RL.scaleFactor * 10), (254 + btn_main_pad) * RL.scaleFactor, "Edit Template Mode", false, 3)
      GUI.New("tab_favorites_checklistEditMode", "Checklist", LayerIndex.Favorites, GUI.w - (38 * RL.scaleFactor) + (RL.scaleFactor * 10), (252 + btn_main_pad) * RL.scaleFactor + (RL.scaleFactor * 2), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "", "h", 0)
      GUI.elms.tab_favorites_checklistEditMode.shadow = false
      GUI.elms.tab_favorites_checklistEditMode.opt_size = 15 * RL.scaleFactor
      GUI.elms.tab_favorites_checklistEditMode:init()
      
      function GUI.elms.tab_favorites_checklistEditMode:onmousedown()
        RL.projectTemplateLoadMode = GUI.Val("tab_favorites_checklistEditMode")
      end
    end
  elseif selection == TabID.RecentProjects or selection == TabID.CustomProjects or selection == TabID.ProjectLists then
    if GUI.elms.tab_favorites_lblEditMode ~= nil then GUI.elms.tab_favorites_lblEditMode:delete() end
    if GUI.elms.tab_favorites_checklistEditMode ~= nil then GUI.elms.tab_favorites_checklistEditMode:delete() end
    if RL.showButtonPanel then 
      GUI.New("tab_favorites_lblSaveNewVersion", "Label", LayerIndex.Favorites, GUI.w - (144 * RL.scaleFactor) + (RL.scaleFactor * 11), (255 + btn_main_pad) * RL.scaleFactor, "Save as New Version", false, 3)
      GUI.New("tab_favorites_checklistSaveAsNewVersion", "Checklist", LayerIndex.Favorites, GUI.w - (34 * RL.scaleFactor) + (RL.scaleFactor * 10), (252 + btn_main_pad) * RL.scaleFactor + (RL.scaleFactor * 2), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "", "h", 0)
      GUI.elms.tab_favorites_checklistSaveAsNewVersion.shadow = false
      GUI.elms.tab_favorites_checklistSaveAsNewVersion.opt_size = 15 * RL.scaleFactor
      GUI.elms.tab_favorites_checklistSaveAsNewVersion:init()
    else
      if GUI.elms.tab_favorites_lblSaveNewVersion ~= nil then GUI.elms.tab_favorites_lblSaveNewVersion:delete() end
      if GUI.elms.tab_favorites_checklistSaveAsNewVersion ~= nil then GUI.elms.tab_favorites_checklistSaveAsNewVersion:delete() end
    end
  elseif selection == TabID.TrackTemplates or selection == TabID.Backups or selection == TabID.Docs then
    if GUI.elms.tab_favorites_lblSaveNewVersion ~= nil then GUI.elms.tab_favorites_lblSaveNewVersion:delete() end
    if GUI.elms.tab_favorites_checklistSaveAsNewVersion ~= nil then GUI.elms.tab_favorites_checklistSaveAsNewVersion:delete() end
    if GUI.elms.tab_favorites_lblEditMode ~= nil then GUI.elms.tab_favorites_lblEditMode:delete() end
    if GUI.elms.tab_favorites_checklistEditMode ~= nil then GUI.elms.tab_favorites_checklistEditMode:delete() end
  end
end

local function RL_Draw_TabFavorites()
  GUI.New("tab_favorites_btnRefresh", "Button", LayerIndex.Favorites, refreshX, refreshY, refreshW, refreshH, "Refresh", RefreshFavorites)
  GUI.New("tab_favorites_txtFilter", "Textbox", LayerIndex.Favorites, filterX, filterY, filterW, filterH, "", 8)
  GUI.elms.tab_favorites_txtFilter.tab_idx = 1
  GUI.New("tab_favorites_btnFilterClear", "Label", LayerIndex.Favorites, filterX + filterW + 10, filterY + (filterH * 0.1), "x", false, 3)
  function GUI.elms.tab_favorites_btnFilterClear:onmouseup() GUI.Label.onmouseup(self) Filter_Favorites_Clear() end

  GUI.New("tab_favorites_categories", "Listbox", LayerIndex.Favorites, pad_left, listbox_top, listbox_w/3, listbox_h, "", true)
  GUI.elms.tab_favorites_categories.multi = false

  local FavoriteCategories = {}
  for i = 1, TabID.Docs do FavoriteCategories[i] = MainLabels[i] end
  GUI.elms.tab_favorites_categories.list = FavoriteCategories

  GUI.New("tab_favorites_listbox", "Listbox", LayerIndex.Favorites, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  GUI.elms.tab_favorites_listbox.list = GetSubTableByNameKey(Favorites.items)
  GUI.elms.tab_favorites_listbox.list.tab_idx = 2
  GUI.Val("tab_favorites_listbox", {1})
  
  if RL.showButtonPanel then 
    GUI.New("tab_favorites_btnRemoveFromFavorites", "Button", LayerIndex.Favorites, btn_pad_left, (2 * btn_main_top) - (32 * RL.scaleFactor), btn_w, btn_h, "Remove from Favorites", RL_ConfirmDialog_RemoveFavoritesEntry)
    GUI.elms.tab_favorites_btnRemoveFromFavorites.tooltip = "Remove the selected file(s) from the [Favorites]"
  else
    if GUI.elms.tab_favorites_btnRemoveFromFavorites ~= nil then GUI.elms.tab_favorites_btnRemoveFromFavorites:delete() end
  end

  RL_Draw_FavoritesButtons()

  function GUI.elms.tab_favorites_categories:onmousedown()
    if GUI.elms.tab_favorites_categories then 
      TabParentSelectionIndex[TabID.Favorites] = self:getitem(GUI.mouse.y)
      TabSelectionIndex[TabID.Favorites] = 0
      RL.projectTemplateLoadMode, RL.saveAsNewVersionMode = 1, 0
      GUI.Listbox.onmousedown(self)
      FillFavoritesListbox()
      Filter_Favorites_Clear()
      ShowFileCount()
    end
  end

  function GUI.elms.tab_favorites_listbox:onmouser_down()
    RL_Context_Favorites()
    GUI.Listbox.onmouser_down(self)
  end

  function GUI.elms.tab_favorites_listbox:onmousem_down()
    RL_Context_Main_Favorites()
    GUI.Listbox.onmousem_down(self)
  end

  function RL_Context_Favorites_AddProjects(mode, currentSelection)
    local transferredProjects = {}
    if mode == "current" then
      local retval, projectFile = reaper.EnumProjects(-1, "")
      if retval and IsNotNullOrEmpty(projectFile) and not CheckForDuplicates(transferredProjects, projectFile) then
        transferredProjects[#transferredProjects + 1] = projectFile
        RL_WriteFavorites(FavoritesFile[currentSelection], CacheFile.MainSection, transferredProjects)
        RefreshFavorites()
      end
    elseif mode == "all" then
      local projTab, lastProject = 0, false
      while not lastProject do
        local retval, projectFile = reaper.EnumProjects(projTab, "")
        if retval then
          if IsNotNullOrEmpty(projectFile) and not CheckForDuplicates(transferredProjects, projectFile) then transferredProjects[#transferredProjects + 1] = projectFile end
          projTab = projTab + 1
        else
          lastProject = true
          RL_WriteFavorites(FavoritesFile[currentSelection], CacheFile.MainSection, transferredProjects)
          RefreshFavorites()
        end
      end
    end
  end

  function RL_Context_Favorites()
    local currentSelection = TabParentSelectionIndex[TabID.Favorites]
    if currentSelection ~= TabID.TrackTemplates and currentSelection ~= TabID.Backups and currentSelection ~= TabID.Docs then
      gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
      if GetMainListSize() > 0 then
        local vals = GetSelectionTable(GUI.Val("tab_favorites_listbox"))
        if #vals == 0 then
          local RMBmenu = gfx.showmenu("1 - Add current project tab|2 - Add all project tabs|#|3 - Clear entire list")
          if RMBmenu == 1 then RL_Context_Favorites_AddProjects("current", currentSelection)
            elseif RMBmenu == 2 then RL_Context_Favorites_AddProjects("all", currentSelection)
            elseif RMBmenu == 3 then RL_ConfirmDialog_ClearFavoritesList()
          end
        else
          local RMBmenu = gfx.showmenu("1 - Add current project tab|2 - Add all project tabs|#|3 - Remove selected entries|4 - Clear entire list")
          if RMBmenu == 1 then RL_Context_Favorites_AddProjects("current", currentSelection)
            elseif RMBmenu == 2 then RL_Context_Favorites_AddProjects("all", currentSelection)
            elseif RMBmenu == 3 then if GetMainListSize() == 1 then RL_ConfirmDialog_ClearFavoritesList() else RL_ConfirmDialog_RemoveFavoritesEntry() end
            elseif RMBmenu == 4 then RL_ConfirmDialog_ClearFavoritesList()
          end
        end
      else
        local RMBmenu = gfx.showmenu("1 - Add current project tab|2 - Add all project tabs")
        if RMBmenu == 1 then RL_Context_Favorites_AddProjects("current", currentSelection)
          elseif RMBmenu == 2 then RL_Context_Favorites_AddProjects("all", currentSelection)
        end
      end
    end
  end

  function GUI.elms.tab_favorites_listbox:ondoubleclick()
    GUI.Listbox.ondoubleclick(self)
    RL_Mouse_DoubleClick(TabID.Favorites)
  end

  function GUI.elms.tab_favorites_listbox:onmousedown()
    TabSelectionIndex[TabID.Favorites] = self:getitem(GUI.mouse.y)
    Global_ShowPathInStatusbar(TabID.Favorites)
    if JSAPIinstalled then AudioPreviewCheckForFile(TabID.Favorites) end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_favorites_txtFilter:ontype()
    GUI.Textbox.ontype(self)
    Filter_Favorites_Apply()
  end

  function GUI.elms.tab_favorites_txtFilter:lostfocus()
    RL.keyInputActive = true
    TabSelectionIndex[TabID.Favorites] = 0
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.tab_favorites_txtFilter:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end
  
  function FillFavoritesListbox()
    Favorites.items, Favorites.display = {}, {}
    GUI.elms.tab_favorites_listbox.list = {}

    local selection = TabParentSelectionIndex[TabID.Favorites]
    if selection == TabID.RecentProjects or selection == TabID.ProjectTemplates or selection == TabID.CustomProjects then fileExtension = FileTypes.rpp
      elseif selection == TabID.TrackTemplates then fileExtension = FileTypes.tracktemplate 
      elseif selection == TabID.ProjectLists then fileExtension = FileTypes.rpl
      elseif selection == TabID.Backups then fileExtension = FileTypes.backup
      elseif selection == TabID.Docs then fileExtension = FileTypes.docs
    end

    local cacheExists, favTable = RL_ReadFromFile(FavoritesFile[selection], CacheFile.MainSection)
    if cacheExists then
      for k, v in pairs(favTable) do
        Favorites.items[#Favorites.items + 1] = {
          name = RemoveExtension(RemoveWhiteSpaces(GetFilenameWithoutPath(v)), fileExtension),
          path = v,
          date = GetLastModifiedDate(v)
        }
      end
      TabSelectionIndex[TabID.Favorites] = 1
      GUI.Val("tab_favorites_listbox", {1})
      Global_UpdateListDisplay()
    end
    RL_Draw_FavoritesButtons()
  end
end

function Favorites_Add()
  local favEntries = {}
  local currentTab = GUI.elms.main_tabs.state

  -- recent projects
  if currentTab == TabID.RecentProjects then 
    if GetMainListSize() > 0 then
      local vals = GetSelectionTable(GUI.Val("tab_recentProjects_listbox"))
      for p = 1, #vals do
        if FilterActive.RecentProjects then selectedProject = RecentProjects.filteredItems[vals[p]].path
        else selectedProject = RecentProjects.items[vals[p]].path end
        if selectedProject ~= nil then favEntries[#favEntries + 1] = selectedProject end
      end
    end
  -- project templates
  elseif currentTab == TabID.ProjectTemplates then
    if GetMainListSize() > 0 then
      local vals = GetSelectionTable(GUI.Val("tab_projectTemplates_listbox"))
      for p = 1, #vals do 
        if FilterActive.ProjectTemplates then selectedProjectTemplate = ProjectTemplates.filteredItems[vals[p]].path
        else selectedProjectTemplate = ProjectTemplates.items[vals[p]].path end
        if selectedProjectTemplate ~= nil then favEntries[#favEntries + 1] = selectedProjectTemplate end
      end
    end
  -- track templates
  elseif currentTab == TabID.TrackTemplates then
    if GetMainListSize() > 0 then
      local selectedTrackTemplate
      local vals = GetSelectionTable(GUI.Val("tab_trackTemplates_listbox"))
      for p = 1, #vals do
        if FilterActive.TrackTemplates then selectedTrackTemplate = TrackTemplates.filteredItems[vals[p]].path
        else selectedTrackTemplate = TrackTemplates.items[vals[p]].path end
        if selectedTrackTemplate ~= nil then favEntries[#favEntries + 1] = selectedTrackTemplate end
      end
    end
  -- projects
  elseif currentTab == TabID.CustomProjects then
    if GetMainListSize() > 0 then
      local vals = GetSelectionTable(GUI.Val("tab_customProjects_listbox"))
      for p = 1, #vals do
        if FilterActive.CustomProjects then selectedProject = CustomProjects.filteredItems[vals[p]].path
        else selectedProject = CustomProjects.items[vals[p]].path end
        if selectedProject ~= nil then favEntries[#favEntries + 1] = selectedProject end
      end
    end
  -- project lists
  elseif currentTab == TabID.ProjectLists then
    if GetMainListSize() > 0 then
      local vals = GetSelectionTable(GUI.Val("tab_projectLists_listboxProjects"))
      for p = 1, #vals do
        if FilterActive.ProjectLists then selectedProjectListProject = RemoveWhiteSpaces(ProjectLists.filteredProjectItems[vals[p]].path)
        else selectedProjectListProject = RemoveWhiteSpaces(ProjectLists.projectItems[vals[p]].path) end
        if selectedProjectListProject ~= nil then favEntries[#favEntries + 1] = selectedProjectListProject end
      end
    end
  -- backups
  elseif currentTab == TabID.Backups then
    if GetMainListSize() > 0 then
      local vals = GetSelectionTable(GUI.Val("tab_backups_listbox"))
        for p = 1, #vals do
          if FilterActive.Backups then selectedBackupFile = RemoveWhiteSpaces(Backups.filteredItems[vals[p]].path)
          else selectedBackupFile = RemoveWhiteSpaces(Backups.items[vals[p]].path) end
          if selectedBackupFile ~= nil then favEntries[#favEntries + 1] = selectedBackupFile end
      end
    end
  -- docs
  elseif currentTab == TabID.Docs then
    if GetMainListSize() > 0 then
      local selectedDocFile
      local vals = GetSelectionTable(GUI.Val("tab_docs_listbox"))
      for p = 1, #vals do
        if FilterActive.Docs then selectedDocFile = Docs.filteredItems[vals[p]].path
        else selectedDocFile = Docs.items[vals[p]].path end
        if selectedDocFile ~= nil then favEntries[#favEntries + 1] = selectedDocFile end
      end
    end
  end

  if #favEntries > 0 then
    RL_WriteFavorites(FavoritesFile[currentTab], CacheFile.MainSection, favEntries)
    MsgStatusBar("Added to Favorites")
  end
end

function Favorites_RemoveEntry()
  local selectionTable = GetSelectionTable(GUI.Val("tab_favorites_listbox"))
  if #selectionTable == 0 then MsgStatusBar("No files selected in list")
  else
    local currentFavFile = FavoritesFile[TabParentSelectionIndex[TabID.Favorites]]
    local cacheExists, favTable = RL_ReadFromFile(currentFavFile, CacheFile.MainSection)
    if cacheExists then
      local entriesToKeep = {}
      for f = 1, #favTable do
        if IsNotNullOrEmpty(favTable[f]) then
          local foundMatch = false
          for s = 1, #selectionTable do
            local selectedFavoritesFile
            if FilterActive.Favorites then selectedFavoritesFile = Favorites.filteredItems[selectionTable[s]].path
            else selectedFavoritesFile = Favorites.items[selectionTable[s]].path end
            if favTable[f] == selectedFavoritesFile then
              foundMatch = true
              break
            end
          end
          if not foundMatch then entriesToKeep[#entriesToKeep + 1] = favTable[f] end 
        end
      end

      if #entriesToKeep > 0 then
        Favorites_ClearList()
        RL_WriteFavorites(currentFavFile, CacheFile.MainSection, entriesToKeep)
        RefreshFavorites()
      end
    end
  end
end

function Favorites_ClearList()
  if RL_ClearFile(FavoritesFile[TabParentSelectionIndex[TabID.Favorites]]) then RefreshFavorites() end
end

---------------
-- Tab - Layout
---------------
-- default GUI.colors: wnd_bg = {64, 64, 64, 255} / tab_bg = {56, 56, 56, 255} / elm_bg = {48, 48, 48, 255} / elm_frame = {96, 96, 96, 255} /
-- elm_fill = {64, 192, 64, 255} / elm_outline = {32, 32, 32, 255} / txt = {192, 192, 192, 255} / shadow = {0, 0, 0, 48} / faded = {0, 0, 0, 64}
local function RL_Draw_TabLayout()
  if ConfigFlags.enableCustomColorOptions then
    function RL_Reset_Colors()
      GUI.colors.elm_fill = { 64 / 255, 192 / 255, 64 / 255, 1 }
      GUI.colors.txt = { 192 / 255, 192 / 255, 192 / 255, 1 }
      GUI.colors.wnd_bg = { 64 / 255, 64 / 255, 64 / 255, 1 }
      GUI.colors.elm_bg = { 48 / 255, 48 / 255, 48 / 255, 1 }

      reaper.SetExtState(appname, "window_color_elmfill", "", 1)
      reaper.SetExtState(appname, "window_color_txt", "", 1)
      reaper.SetExtState(appname, "window_color_wndbg", "", 1)
      reaper.SetExtState(appname, "window_color_elmbg", "", 1)

      GUI.elms.colors_frame_elmFill.color = GUI.colors.elm_fill
      GUI.elms.colors_frame_txt.color = GUI.colors.txt
      GUI.elms.colors_frame_wndBg.color = GUI.colors.wnd_bg
      GUI.elms.colors_frame_elmBg.color = GUI.colors.elm_bg

      RL_Init_Colors_Highlight()
      RL_Init_Colors_TextElements()
      RL_Init_Colors_ElementBackground()
      RL_Init_Colors_Button()
    end
    
    GUI.New("colors_btnResetColors", "Button", LayerIndex.Layout, 4.0 * optionspad_left, tabSelectorPadding + 2.5 * 38 * RL.scaleFactor, 98 * RL.scaleFactor, 18 * RL.scaleFactor, "Reset Colors", RL_Reset_Colors)
    GUI.elms.colors_btnResetColors.tooltip = "Reset color scheme to default colors"
    
    GUI.New("colors_lbl_elmFill", "Label", LayerIndex.Layout, 4.4 * optionspad_left, tabSelectorPadding + 3.1 * 38 * RL.scaleFactor, "Highlight color", false, 3)
    GUI.New("colors_frame_elmFill", "Frame", LayerIndex.Layout, 4 * optionspad_left, tabSelectorPadding + 3.1 * 38 * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor)
    GUI.elms.colors_frame_elmFill.tooltip = "Set a custom highlight color"
    
    GUI.New("colors_lbl_txt", "Label", LayerIndex.Layout, 4.4 * optionspad_left, tabSelectorPadding + 3.6 * 38 * RL.scaleFactor, "Text color", false, 3)
    GUI.New("colors_frame_txt", "Frame", LayerIndex.Layout, 4 * optionspad_left, tabSelectorPadding + 3.6 * 38 * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor)
    GUI.elms.colors_frame_txt.tooltip = "Set a custom text color"
    
    GUI.New("colors_lbl_elmBg", "Label", LayerIndex.Layout, 4.4 * optionspad_left, tabSelectorPadding + 4.1 * 38 * RL.scaleFactor, "Element Background color", false, 3)
    GUI.New("colors_frame_elmBg", "Frame", LayerIndex.Layout, 4 * optionspad_left, tabSelectorPadding + 4.1 * 38 * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor)
    GUI.elms.colors_frame_elmBg.tooltip = "Set a custom element background color"
    
    GUI.New("colors_lbl_wndBg", "Label", LayerIndex.Layout, 4.4 * optionspad_left, tabSelectorPadding + 4.6 * 38 * RL.scaleFactor, "Window Background color", false, 3)
    GUI.New("colors_frame_wndBg", "Frame", LayerIndex.Layout, 4 * optionspad_left, tabSelectorPadding + 4.6 * 38 * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor)
    GUI.elms.colors_frame_wndBg.tooltip = "Set a custom window background color"

    GUI.New("colors_lbl_infotext", "Label", LayerIndex.Layout, 4.0 * optionspad_left, tabSelectorPadding + 5.3 * 38 * RL.scaleFactor, "(Layout and color changes require a restart)", false, 3)
    
    function GUI.elms.colors_frame_elmFill:draw() GUI.Frame.draw(self) DrawFrameColor(self) end
    function GUI.elms.colors_frame_elmFill:onmouseup() OpenColorPicker(self, "elm_fill") DrawFrameColor(self) end

    function GUI.elms.colors_frame_txt:draw() GUI.Frame.draw(self) DrawFrameColor(self) end
    function GUI.elms.colors_frame_txt:onmouseup() OpenColorPicker(self, "txt") DrawFrameColor(self) end

    function GUI.elms.colors_frame_wndBg:draw() GUI.Frame.draw(self) DrawFrameColor(self) end
    function GUI.elms.colors_frame_wndBg:onmouseup() OpenColorPicker(self, "wnd_bg") DrawFrameColor(self) end

    function GUI.elms.colors_frame_elmBg:draw() GUI.Frame.draw(self) DrawFrameColor(self) end
    function GUI.elms.colors_frame_elmBg:onmouseup() OpenColorPicker(self, "elm_bg") DrawFrameColor(self) end

    function DrawFrameColor(self)
      local x, y, w, h = self.x + 1, self.y + 1, self.w - 2, self.h - 2
      GUI.color(self.color)
      gfx.rect(x, y, w, h, true)
      if self.col_user then
        GUI.color(self.col_user)
        gfx.rect(x + 1, y + 1, w - 2, h - 2, true)
      end
      GUI.color("black")
      gfx.rect(x, y, w, h, false)
    end
    
    function OpenColorPicker(self, colorElement)
      local retval, outColor = reaper.GR_SelectColor()
      if retval ~= 0 then
        local r, g, b = reaper.ColorFromNative(outColor)
        self.col_user = {r / 255, g / 255, b / 255}
        local colorString = r .. "," .. g .. "," .. b
        if colorElement == "elm_fill" then
          GUI.colors.elm_fill = self.col_user
          reaper.SetExtState(appname, "window_color_elmfill", colorString, 1)
          RL_Init_Colors_Highlight()
          elseif colorElement == "txt" then
            GUI.colors.txt = self.col_user
            reaper.SetExtState(appname, "window_color_txt", colorString, 1)
            RL_Init_Colors_TextElements()
          elseif colorElement == "wnd_bg" then
            GUI.colors.wnd_bg = self.col_user
            reaper.SetExtState(appname, "window_color_wndbg", colorString, 1)
            RL_Init_Colors_Button()
          elseif colorElement == "elm_bg" then
            GUI.colors.elm_bg = self.col_user
            reaper.SetExtState(appname, "window_color_elmbg", colorString, 1)
            RL_Init_Colors_ElementBackground()
          end
        GUI.redraw_z[self.z] = true
      end
    end
  end

  if RL.tabSelectorStyle == 2 then GUI.New("layout_frame_top", "Frame", LayerIndex.Layout, 0, listbox_top, GUI.w, 2 * RL.scaleFactor, false, true) end
  
  GUI.New("layout_lblTabSelectorStyle", "Label", LayerIndex.Layout, 1.6 * optionspad_left, tabSelectorPadding + 34 * RL.scaleFactor, "Tab Selector style", false, 3)
  GUI.New("layout_menuTabSelectorStyle", "Menubox", LayerIndex.Layout, 3.4 * optionspad_left, tabSelectorPadding + 34 * RL.scaleFactor, 100 * RL.scaleFactor, 15 * RL.scaleFactor, "", "Tabstrip,Dropdown", 8)
  GUI.elms.layout_menuTabSelectorStyle.align = 1
  GUI.Val("layout_menuTabSelectorStyle", RL.tabSelectorStyle)
  
  function GUI.elms.layout_menuTabSelectorStyle:onmousedown()
    GUI.Menubox.onmouseup(self)
    reaper.SetExtState(appname, "window_tabselectorstyle", GUI.Val("layout_menuTabSelectorStyle"), 1)
    RL.tabSelectorStyle = GUI.Val("layout_menuTabSelectorStyle")
    Global_Redraw()
  end
  
  function GUI.elms.layout_menuTabSelectorStyle:onwheel()
    GUI.Menubox.onwheel(self)
    reaper.SetExtState(appname, "window_tabselectorstyle", GUI.Val("layout_menuTabSelectorStyle"), 1)
    RL.tabSelectorStyle = GUI.Val("layout_menuTabSelectorStyle")
    Global_Redraw()
  end
  
  GUI.New("layout_lblButtonPanelStyle", "Label", LayerIndex.Layout, 1.6 * optionspad_left, tabSelectorPadding + 52 * RL.scaleFactor, "Main Panel style", false, 3)
  GUI.New("layout_menuButtonPanelStyle", "Menubox", LayerIndex.Layout, 3.4 * optionspad_left, tabSelectorPadding + 52 * RL.scaleFactor, 100 * RL.scaleFactor, 15 * RL.scaleFactor, "", "Buttons,Context Menu", 8)
  GUI.elms.layout_menuButtonPanelStyle.align = 1
  if RL.showButtonPanel then GUI.Val("layout_menuButtonPanelStyle", 1) else GUI.Val("layout_menuButtonPanelStyle", 2) end
  
  function GUI.elms.layout_menuButtonPanelStyle:onmousedown()
    GUI.Menubox.onmouseup(self)
    if GUI.Val("layout_menuButtonPanelStyle") == 1 then 
      reaper.SetExtState(appname, "window_showmainbuttonpanel", "true", 1)
      RL.showButtonPanel = true
    else
      RL.showButtonPanel = false
      reaper.SetExtState(appname, "window_showmainbuttonpanel", "false", 1)
    end
    Global_Redraw()
  end
  
  function GUI.elms.layout_menuButtonPanelStyle:onwheel()
    GUI.Menubox.onwheel(self)
    if GUI.Val("layout_menuButtonPanelStyle") == 1 then 
      reaper.SetExtState(appname, "window_showmainbuttonpanel", "true", 1)
      RL.showButtonPanel = true
    else
      RL.showButtonPanel = false
      reaper.SetExtState(appname, "window_showmainbuttonpanel", "false", 1)
    end
    Global_Redraw()
  end
  
  if ConfigFlags.enableHiDPIModeOptions then
    GUI.New("layout_lblRetinaMode", "Label", LayerIndex.Layout, 1.6 * optionspad_left, tabSelectorPadding + 70 * RL.scaleFactor, "HiDPI Mode", false, 3)
    GUI.New("layout_menuRetinaMode", "Menubox", LayerIndex.Layout, 3.4 * optionspad_left, tabSelectorPadding + 70 * RL.scaleFactor, 100 * RL.scaleFactor, 15 * RL.scaleFactor, "","Auto,Default,Retina")
    GUI.elms.layout_menuRetinaMode.align = 1
    GUI.elms.layout_menuRetinaMode.tooltip = "Sets the gfx.ext_retina flag for HiDPI/Retina support\n\n[Auto]: Detect flag automatically\n[Default] or [Retina]: Set flag manually\n\nSet the flag to [Default] if there are any problems with using the other options\n\nRestart required for the changes to take effect"
    
    function GUI.elms.layout_menuRetinaMode:onmousedown()
      GUI.Menubox.onmouseup(self)
      reaper.SetExtState(appname, "window_hidpimode", GUI.Val("layout_menuRetinaMode"), 1)
    end
    
    function GUI.elms.layout_menuRetinaMode:onwheel()
      GUI.Menubox.onwheel(self)
      reaper.SetExtState(appname, "window_hidpimode", GUI.Val("layout_menuRetinaMode"), 1)
    end
  end

  GUI.New("layout_frame_1", "Frame", LayerIndex.Layout, 94 * RL.scaleFactor, tabSelectorPadding + 89 * RL.scaleFactor, GUI.w, 2 * RL.scaleFactor, false, true)
  
  GUI.New("layout_lblShowSubfolderPanel", "Label", LayerIndex.Layout, 1.6 * optionspad_left, tabSelectorPadding + 1.35 * 70 * RL.scaleFactor, "Show (left) Sub Panels", false, 3)
  GUI.New("layout_checklistShowSubfolderPanel", "Checklist", LayerIndex.Layout, 1.6 * optionspad_left, tabSelectorPadding + 1.6 * 70 * RL.scaleFactor, 126 * RL.scaleFactor, 106 * RL.scaleFactor, "", "Project Templates,Track Templates,Projects,Project Lists,Backups,Docs", "v", 5)
  GUI.elms.layout_checklistShowSubfolderPanel.shadow = false
  GUI.elms.layout_checklistShowSubfolderPanel.opt_size = 15 * RL.scaleFactor
  GUI.elms.layout_checklistShowSubfolderPanel.font_a = GUI.fonts[4]
  GUI.Val("layout_checklistShowSubfolderPanel", RL.activeSubPanels)
  GUI.elms.layout_checklistShowSubfolderPanel.frame = false
  GUI.elms.layout_checklistShowSubfolderPanel:init()
  
  if SWSinstalled then RL_Draw_ThemeSlotOptions() end
end

--------------
-- Tab - Paths
--------------
local function OpenJSBrowseDialog(textBoxID, caption)
  if JSAPIinstalled then
    local retval, selectedFolder = reaper.JS_Dialog_BrowseForFolder(caption, RL.lastFolderPath)
    if retval == 1 then
      RL.lastFolderPath = selectedFolder
      local oldPath = GUI.Val(textBoxID)
      if IsNotNullOrEmpty(oldPath) then GUI.Val(textBoxID, oldPath .. ";" .. selectedFolder)
      else GUI.Val(textBoxID, selectedFolder) end
    end
  end
end

function Path_Browse_ProjectTemplateFolder()
  OpenJSBrowseDialog("paths_txtProjectTemplatesPath", "Containing (.RPP) Project Templates")
end

function Path_Browse_TrackTemplateFolder()
  OpenJSBrowseDialog("paths_txtTrackTemplatesPath", "Containing (.RTrackTemplate) Track Templates")
end

function Path_Browse_CustomProjectFolder()
  OpenJSBrowseDialog("paths_txtCustomProjectsPath", "Containing (.RPP) Projects")
end

function Path_Browse_ProjectListFolder()
  OpenJSBrowseDialog("paths_txtProjectsListsPath", "Containing (.RPL) Project Lists")
end

function Path_Browse_BackupsFolder()
  OpenJSBrowseDialog("paths_txtBackupsPath", "Containing (.RPP-BAK) Backups")
end

function Path_Browse_DocsFolder()
  OpenJSBrowseDialog("paths_txtDocsPath", "Containing (.PDF) Docs")
end

function RL_ShowProgressIndicator(elementIndex, isActive)
  if ConfigFlags.enableFileCaching or ConfigFlags.enableSubfolderCaching then 
    if isActive then
      if elementIndex == 1 then GUI.elms.paths_btnRescanAllPaths.col_txt = FilterColor.active
        elseif elementIndex == 2 then GUI.elms.paths_btnProjectTemplatesSet.col_txt = FilterColor.active
        elseif elementIndex == 3 then GUI.elms.paths_btnTrackTemplatesSet.col_txt = FilterColor.active
        elseif elementIndex == 4 then GUI.elms.paths_btnCustomProjectsSet.col_txt = FilterColor.active
        elseif elementIndex == 5 then GUI.elms.paths_btnProjectListsSet.col_txt = FilterColor.active
        elseif elementIndex == 6 then GUI.elms.paths_btnBackupsSet.col_txt = FilterColor.active
        elseif elementIndex == 7 then GUI.elms.paths_btnDocsSet.col_txt = FilterColor.active
      end
    else
      if elementIndex == 1 then GUI.elms.paths_btnRescanAllPaths.col_txt = FilterColor.inactive
        elseif elementIndex == 2 then GUI.elms.paths_btnProjectTemplatesSet.col_txt = FilterColor.inactive
        elseif elementIndex == 3 then GUI.elms.paths_btnTrackTemplatesSet.col_txt = FilterColor.inactive
        elseif elementIndex == 4 then GUI.elms.paths_btnCustomProjectsSet.col_txt = FilterColor.inactive
        elseif elementIndex == 5 then GUI.elms.paths_btnProjectListsSet.col_txt = FilterColor.inactive
        elseif elementIndex == 6 then GUI.elms.paths_btnBackupsSet.col_txt = FilterColor.inactive
        elseif elementIndex == 7 then GUI.elms.paths_btnDocsSet.col_txt = FilterColor.inactive
      end
    end

    GUI.elms.paths_btnRescanAllPaths:redraw()
    GUI.elms.paths_btnRescanAllPaths:init()
    GUI.elms.paths_btnProjectTemplatesSet:redraw()
    GUI.elms.paths_btnProjectTemplatesSet:init()
    GUI.elms.paths_btnTrackTemplatesSet:redraw()
    GUI.elms.paths_btnTrackTemplatesSet:init()
    GUI.elms.paths_btnCustomProjectsSet:redraw()
    GUI.elms.paths_btnCustomProjectsSet:init()
    GUI.elms.paths_btnProjectListsSet:redraw()
    GUI.elms.paths_btnProjectListsSet:init()
    GUI.elms.paths_btnBackupsSet:redraw()
    GUI.elms.paths_btnBackupsSet:init()
    GUI.elms.paths_btnDocsSet:redraw()
    GUI.elms.paths_btnDocsSet:init()
  end
end

-------------
-- Scan Files
-------------
function RL_ScanProjectTemplateFiles()
  local retval, tempTemplates = GetProjectTemplateFiles()
  if retval then
    RL_WriteToFileCache(CacheFile.ProjectTemplates, CacheFile.MainSection, tempTemplates, true)
    MsgDebug("Project Templates rescan completed")
  end
end

function RL_ScanTrackTemplateFiles()
  local retval, tempTemplates = GetTrackTemplateFiles()
  if retval then
    RL_WriteToFileCache(CacheFile.TrackTemplates, CacheFile.MainSection, tempTemplates, true)
    MsgDebug("Track Templates rescan completed")
  end
end

function RL_ScanCustomProjectFiles()
  if #CustomPaths.Projects > 1 then
    local tempProjects = {}
    local multiPaths = SplitMultiPaths(CustomPaths.Projects)
    for m = 1, #multiPaths do JoinTables(tempProjects, GetFiles(multiPaths[m], TabID.CustomProjects, FileTypes.rpp)) end
    RL_WriteToFileCache(CacheFile.CustomProjects, CacheFile.MainSection, tempProjects, true)
    MsgDebug("Projects rescan completed")
  end
end

function RL_ScanProjectListFiles()
  if #CustomPaths.ProjectLists > 1 then
    local tempRPL, tempProjectFiles = {}, {}
    local multiPaths = SplitMultiPaths(CustomPaths.ProjectLists)
    for m = 1, #multiPaths do JoinTables(tempRPL, GetFiles(multiPaths[m], TabID.ProjectLists, FileTypes.rpl)) end
   
    for r = 1, #tempRPL do 
      local file = io.open(tempRPL[r], "r")
      if not file then return nil end
      for line in file:lines() do
        if #line > 1 then
          if not CheckForDuplicates(tempProjectFiles, line) then tempProjectFiles[#tempProjectFiles + 1] = line end
        end
      end
      file:close()
    end
    
    RL_WriteToFileCache(CacheFile.ProjectLists, CacheFile.MainSection, tempProjectFiles, true)
    MsgDebug("Project Lists rescan completed")
  end
end

function RL_ScanBackupsFiles()
  if #CustomPaths.Backups > 1 then
    local tempBackups = {}
    local multiPaths = SplitMultiPaths(CustomPaths.Backups)
    for m = 1, #multiPaths do JoinTables(tempBackups, GetFiles(multiPaths[m], TabID.Backups, FileTypes.backup)) end
    RL_WriteToFileCache(CacheFile.Backups, CacheFile.MainSection, tempBackups, true)
    MsgDebug("Backups rescan completed")
  end
end

function RL_ScanDocsFiles()
  if #CustomPaths.Docs > 1 then
    local tempDocs = {}
    local multiPaths = SplitMultiPaths(CustomPaths.Docs)
    for m = 1, #multiPaths do JoinTables(tempDocs, GetFiles(multiPaths[m], TabID.Docs, FileTypes.docs)) end
    RL_WriteToFileCache(CacheFile.Docs, CacheFile.MainSection, tempDocs, true)
    MsgDebug("Docs rescan completed")
  end
end

------------------
-- Scan Subfolders
------------------
function RL_ScanProjectTemplateSubfolders()
  if ShowSubfolderPanel(TabID.ProjectTemplates) then
    SubfolderPaths.projectTemplates, SubfolderNames.projectTemplates = {}, {}
    SubfolderPaths.projectTemplates, SubfolderNames.projectTemplates = GetSubFolderEntries(projectTemplatePath, CustomPaths.ProjectTemplates, TabID.ProjectTemplates, FileTypes.rpp)
    RL_WriteToSubfolderCache(SubpanelFile.ProjectTemplates, SubpanelFile.MainSection, SubfolderPaths.projectTemplates)
  end
end

function RL_ScanTrackTemplateSubfolders()
  if ShowSubfolderPanel(TabID.TrackTemplates) then 
    SubfolderPaths.trackTemplates, SubfolderNames.trackTemplates = {}, {}
    SubfolderPaths.trackTemplates, SubfolderNames.trackTemplates = GetSubFolderEntries(trackTemplatePath, CustomPaths.TrackTemplates, TabID.TrackTemplates, FileTypes.tracktemplate)
    RL_WriteToSubfolderCache(SubpanelFile.TrackTemplates, SubpanelFile.MainSection, SubfolderPaths.trackTemplates)
  end
end

function RL_ScanCustomProjectSubfolders()
  if ShowSubfolderPanel(TabID.CustomProjects) then 
    SubfolderPaths.customProjects, SubfolderNames.customProjects = {}, {}
    SubfolderPaths.customProjects, SubfolderNames.customProjects = GetSubFolderEntries("All", CustomPaths.Projects, TabID.CustomProjects, FileTypes.rpp)
    RL_WriteToSubfolderCache(SubpanelFile.CustomProjects, SubpanelFile.MainSection, SubfolderPaths.customProjects)
  end
end

function RL_ScanProjectListSubfolders()
  if ShowSubfolderPanel(TabID.ProjectLists) then
    local foundFiles = {}
    local multiPaths = SplitMultiPaths(CustomPaths.ProjectLists)
    for m = 1, #multiPaths do 
      local projectListFiles = GetFiles(multiPaths[m], TabID.ProjectLists, FileTypes.rpl)
      for p = 1, #projectListFiles do foundFiles[#foundFiles + 1] = projectListFiles[p] end
    end
    RL_WriteToSubfolderCache(SubpanelFile.ProjectLists, SubpanelFile.MainSection, foundFiles)
  end
end

function RL_ScanBackupsSubfolders()
  if ShowSubfolderPanel(TabID.Backups) then 
    SubfolderPaths.backups, SubfolderNames.backups = {}, {}
    SubfolderPaths.backups, SubfolderNames.backups = GetSubFolderEntries("All", CustomPaths.Backups, TabID.Backups, FileTypes.backup)
    RL_WriteToSubfolderCache(SubpanelFile.Backups, SubpanelFile.MainSection, SubfolderPaths.backups)
  end
end

function RL_ScanDocsSubfolders()
  if ShowSubfolderPanel(TabID.Docs) then
    SubfolderPaths.docs, SubfolderNames.docs = {}, {}
    SubfolderPaths.docs, SubfolderNames.docs = GetSubFolderEntries("All", CustomPaths.Docs, TabID.Docs, FileTypes.docs)
    RL_WriteToSubfolderCache(SubpanelFile.Docs, SubpanelFile.MainSection, SubfolderPaths.docs)
  end
end

function AddSubfolderSectionEntries(file, sectionName, entries)
  if entries == nil then return end
  file:write("[" .. sectionName .. "]\n")
  for e = 1, #entries do
    if entries[e] ~= "< All >" then file:write(entries[e] .. "\n") end
  end
  file:write("[[" .. sectionName .. "]]\n")
end

local function RL_RescanAllPaths()
  if ConfigFlags.enableFileCaching then 
    RL_ScanProjectTemplateFiles()
    RL_ScanTrackTemplateFiles()
    RL_ScanCustomProjectFiles()
    RL_ScanProjectListFiles()
    RL_ScanBackupsFiles()
    RL_ScanDocsFiles()
    MsgDebug("File rescan completed")
  end

  if ConfigFlags.enableSubfolderCaching then 
    RL_ScanProjectTemplateSubfolders()
    RL_ScanTrackTemplateSubfolders()
    RL_ScanCustomProjectSubfolders()
    RL_ScanProjectListSubfolders()
    RL_ScanBackupsSubfolders()
    RL_ScanDocsSubfolders()
    MsgDebug("Subfolder rescan completed")
  end
  
  MsgStatusBar("Rescan of all paths completed")
  RL_ShowProgressIndicator(1, false)
end

local function RL_Draw_TabPaths()
  local paths_textBoxWidth = 265
  local paths_buttonText = "Set"

  if JSAPIinstalled then
    GUI.New("paths_btnProjectTemplatesBrowse", "Button", LayerIndex.Paths, GUI.w - 84 * RL.scaleFactor, tabSelectorPadding + 1.25 * (30 * RL.scaleFactor), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "+", Path_Browse_ProjectTemplateFolder)
    GUI.New("paths_btnTrackTemplatesBrowse", "Button", LayerIndex.Paths, GUI.w - 84 * RL.scaleFactor, tabSelectorPadding + 2.05 * (30 * RL.scaleFactor), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "+", Path_Browse_TrackTemplateFolder)
    GUI.New("paths_btnCustomProjectsBrowse", "Button", LayerIndex.Paths, GUI.w - 84 * RL.scaleFactor, tabSelectorPadding + 2.85 * (30 * RL.scaleFactor), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "+", Path_Browse_CustomProjectFolder)
    GUI.New("paths_btnProjectListsBrowse", "Button", LayerIndex.Paths, GUI.w - 84 * RL.scaleFactor, tabSelectorPadding + 3.65 * (30 * RL.scaleFactor), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "+", Path_Browse_ProjectListFolder)
    GUI.New("paths_btnBackupsBrowse", "Button", LayerIndex.Paths, GUI.w - 84 * RL.scaleFactor, tabSelectorPadding + 4.45 * (30 * RL.scaleFactor), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "+", Path_Browse_BackupsFolder)
    GUI.New("paths_btnDocsBrowse", "Button", LayerIndex.Paths, GUI.w - 84 * RL.scaleFactor, tabSelectorPadding + 5.25 * (30 * RL.scaleFactor), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "+", Path_Browse_DocsFolder)
    paths_textBoxWidth = 284
  end

  if ConfigFlags.enableFileCaching or ConfigFlags.enableSubfolderCaching then
    GUI.New("paths_lblInfo", "Label", LayerIndex.Paths, 196 * RL.scaleFactor, tabSelectorPadding + 6.15 * (30 * RL.scaleFactor), "Path changes are applied with the [Set] buttons", false, 4)
    paths_buttonText = "Set / Scan" 

    GUI.New("paths_btnRescanAllPaths", "Button", LayerIndex.Paths, GUI.w - (64 * RL.scaleFactor), tabSelectorPadding + 6.12 * (30 * RL.scaleFactor), 55 * RL.scaleFactor, 15 * RL.scaleFactor, "Rescan all")
    GUI.elms.paths_btnRescanAllPaths.tooltip = "Rebuild the file cache for all tabs"

    function GUI.elms.paths_btnRescanAllPaths:onmousedown()
      RL_ShowProgressIndicator(1, true)
      GUI.Button.onmousedown(self)
      reaper.defer(RL_RescanAllPaths)
    end
  end

  if RL.tabSelectorStyle == 2 then GUI.New("paths_frame_top", "Frame", LayerIndex.Paths, 0, listbox_top, GUI.w, 2 * RL.scaleFactor, false, true) end
  GUI.New("paths_txtProjectTemplatesPath", "Textbox", LayerIndex.Paths, 196 * RL.scaleFactor, tabSelectorPadding + 1.2 * (30 * RL.scaleFactor), GUI.w - paths_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, "Project Templates", 12)
  GUI.New("paths_btnProjectTemplatesSet", "Button", LayerIndex.Paths, GUI.w - 64 * RL.scaleFactor, tabSelectorPadding + 1.25 * (30 * RL.scaleFactor), 55 * RL.scaleFactor, 15 * RL.scaleFactor, paths_buttonText)
  function GUI.elms.paths_btnProjectTemplatesSet:onmousedown()
    RL_ShowProgressIndicator(TabID.ProjectTemplates, true)
    GUI.Button.onmousedown(self)
    reaper.defer(Path_Set_ProjectTemplateFolder)
  end

  GUI.New("paths_txtTrackTemplatesPath", "Textbox", LayerIndex.Paths, 196 * RL.scaleFactor, tabSelectorPadding + 2.0 * (30 * RL.scaleFactor), GUI.w - paths_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, "Track Templates", 12)
  GUI.New("paths_btnTrackTemplatesSet", "Button", LayerIndex.Paths, GUI.w - 64 * RL.scaleFactor, tabSelectorPadding + 2.05 * (30 * RL.scaleFactor), 55 * RL.scaleFactor, 15 * RL.scaleFactor, paths_buttonText)
  function GUI.elms.paths_btnTrackTemplatesSet:onmousedown()
    RL_ShowProgressIndicator(TabID.TrackTemplates, true)
    GUI.Button.onmousedown(self)
    reaper.defer(Path_Set_TrackTemplateFolder)
  end

  GUI.New("paths_txtCustomProjectsPath", "Textbox", LayerIndex.Paths, 196 * RL.scaleFactor, tabSelectorPadding + 2.8 * (30 * RL.scaleFactor), GUI.w - paths_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, "Projects", 12)
  GUI.New("paths_btnCustomProjectsSet", "Button", LayerIndex.Paths, GUI.w - 64 * RL.scaleFactor, tabSelectorPadding + 2.85 * (30 * RL.scaleFactor), 55 * RL.scaleFactor, 15 * RL.scaleFactor, paths_buttonText)
  function GUI.elms.paths_btnCustomProjectsSet:onmousedown()
    RL_ShowProgressIndicator(TabID.CustomProjects, true)
    GUI.Button.onmousedown(self)
    reaper.defer(Path_Set_CustomProjectFolder)
  end

  GUI.New("paths_txtProjectsListsPath", "Textbox", LayerIndex.Paths, 196 * RL.scaleFactor, tabSelectorPadding + 3.6 * (30 * RL.scaleFactor), GUI.w - paths_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, "Project Lists", 12)
  GUI.New("paths_btnProjectListsSet", "Button", LayerIndex.Paths, GUI.w - 64 * RL.scaleFactor, tabSelectorPadding + 3.65 * (30 * RL.scaleFactor), 55 * RL.scaleFactor, 15 * RL.scaleFactor, paths_buttonText)
  function GUI.elms.paths_btnProjectListsSet:onmousedown()
    RL_ShowProgressIndicator(TabID.ProjectLists, true)
    GUI.Button.onmousedown(self)
    reaper.defer(Path_Set_ProjectListFolder)
  end

  GUI.New("paths_txtBackupsPath", "Textbox", LayerIndex.Paths, 196 * RL.scaleFactor, tabSelectorPadding + 4.4 * (30 * RL.scaleFactor), GUI.w - paths_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, "Backups", 12)
  GUI.New("paths_btnBackupsSet", "Button", LayerIndex.Paths, GUI.w - 64 * RL.scaleFactor, tabSelectorPadding + 4.45 * (30 * RL.scaleFactor), 55 * RL.scaleFactor, 15 * RL.scaleFactor, paths_buttonText)
  function GUI.elms.paths_btnBackupsSet:onmousedown()
    RL_ShowProgressIndicator(TabID.Backups, true)
    GUI.Button.onmousedown(self)
    reaper.defer(Path_Set_BackupsFolder)
  end

  GUI.New("paths_txtDocsPath", "Textbox", LayerIndex.Paths, 196 * RL.scaleFactor, tabSelectorPadding + 5.2 * (30 * RL.scaleFactor), GUI.w - paths_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, "Docs", 12)
  GUI.New("paths_btnDocsSet", "Button", LayerIndex.Paths, GUI.w - 64 * RL.scaleFactor, tabSelectorPadding + 5.25 * (30 * RL.scaleFactor), 55 * RL.scaleFactor, 15 * RL.scaleFactor, paths_buttonText)
  function GUI.elms.paths_btnDocsSet:onmousedown()
    RL_ShowProgressIndicator(TabID.Docs, true)
    GUI.Button.onmousedown(self)
    reaper.defer(Path_Set_DocsFolder)
  end

  function GUI.elms.paths_txtProjectTemplatesPath:onmousedown() GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.paths_txtTrackTemplatesPath:onmousedown()   GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.paths_txtCustomProjectsPath:onmousedown()   GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.paths_txtProjectsListsPath:onmousedown()    GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.paths_txtBackupsPath:onmousedown()          GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.paths_txtDocsPath:onmousedown()             GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  
  function GUI.elms.paths_txtProjectTemplatesPath:lostfocus()   RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.paths_txtTrackTemplatesPath:lostfocus()     RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.paths_txtCustomProjectsPath:lostfocus()     RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.paths_txtProjectsListsPath:lostfocus()      RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.paths_txtBackupsPath:lostfocus()            RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.paths_txtDocsPath:lostfocus()               RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
end

----------------------
-- Tab - Scan Settings
----------------------
FileScanSettings = {
  projectTemplates_excludedFolders = "",
  projectTemplates_maxSubDirDepth = 0,
  projectTemplates_maxSubDirRange = 0,
  trackTemplates_excludedFolders = "",
  trackTemplates_maxSubDirDepth = 0,
  trackTemplates_maxSubDirRange = 0,
  projects_excludedFolders = "",
  projects_maxSubDirDepth = 0,
  projects_maxSubDirRange = 0,
  projectLists_excludedFolders = "",
  projectLists_maxSubDirDepth = 0,
  projectLists_maxSubDirRange = 0,
  backups_excludedFolders = "",
  backups_maxSubDirDepth = 0,
  backups_maxSubDirRange = 0,
  docs_excludedFolders = "",
  docs_maxSubDirDepth = 0,
  docs_maxSubDirRange = 0,
}

FileScanExclusions = {
  ProjectTemplates = {},
  TrackTemplates = {},
  CustomProjects = {},
  ProjectLists = {},
  Backups = {},
  Docs = {}
}

function Set_ExcludedFolders_ProjectTemplates()
  if GUI.Val("scansettings_txtProjectTemplates") == "" then
    FileScanSettings.projectTemplates_excludedFolders = ""
    FileScanExclusions.ProjectTemplates = {}
    reaper.DeleteExtState(appname, "scan_projecttemplates_excludedfoldernames", 1)
    GUI.elms.scansettings_txtProjectTemplates.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3"
  else
    FileScanSettings.projectTemplates_excludedFolders = GUI.Val("scansettings_txtProjectTemplates")
    FileScanExclusions.ProjectTemplates = SplitMultiPaths(FileScanSettings.projectTemplates_excludedFolders)
    reaper.SetExtState(appname, "scan_projecttemplates_excludedfoldernames", GUI.Val("scansettings_txtProjectTemplates"), 1)
    GUI.elms.scansettings_txtProjectTemplates.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3\n\nCurrent: " .. GUI.Val("scansettings_txtProjectTemplates")
  end

  FileScanSettings.projectTemplates_maxSubDirDepth = tonumber(GUI.Val("scansettings_txtProjectTemplates_MaxScanDepth")) or 0
  FileScanSettings.projectTemplates_maxSubDirRange = tonumber(GUI.Val("scansettings_txtProjectTemplates_MaxScanSubDirs")) or 0
  reaper.SetExtState(appname, "scan_projecttemplates_limits", FileScanSettings.projectTemplates_maxSubDirDepth .. "," .. FileScanSettings.projectTemplates_maxSubDirRange, 1)
  MsgStatusBar("Scan Settings for Project Templates updated")
end

function Set_ExcludedFolders_TrackTemplates()
  if GUI.Val("scansettings_txtTrackTemplates") == "" then
    FileScanSettings.trackTemplates_excludedFolders = ""
    FileScanExclusions.TrackTemplates = {}
    reaper.DeleteExtState(appname, "scan_tracktemplates_excludedfoldernames", 1)
    GUI.elms.scansettings_txtTrackTemplates.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3"
  else
    FileScanSettings.trackTemplates_excludedFolders = GUI.Val("scansettings_txtTrackTemplates")
    FileScanExclusions.TrackTemplates = SplitMultiPaths(FileScanSettings.trackTemplates_excludedFolders)
    reaper.SetExtState(appname, "scan_tracktemplates_excludedfoldernames", GUI.Val("scansettings_txtTrackTemplates"), 1)
    GUI.elms.scansettings_txtTrackTemplates.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3\n\nCurrent: " .. GUI.Val("scansettings_txtTrackTemplates")
  end

  FileScanSettings.trackTemplates_maxSubDirRange = tonumber(GUI.Val("scansettings_txtTrackTemplates_MaxScanSubDirs")) or 0
  FileScanSettings.trackTemplates_maxSubDirDepth = tonumber(GUI.Val("scansettings_txtTrackTemplates_MaxScanDepth")) or 0
  reaper.SetExtState(appname, "scan_tracktemplates_limits", FileScanSettings.trackTemplates_maxSubDirDepth .. "," .. FileScanSettings.trackTemplates_maxSubDirRange, 1)
  MsgStatusBar("Scan Settings for Track Templates updated")
end

function Set_ExcludedFolders_CustomProjects()
  if GUI.Val("scansettings_txtCustomProjects") == "" then
    FileScanSettings.projects_excludedFolders = ""
    FileScanExclusions.CustomProjects = {}
    reaper.DeleteExtState(appname, "scan_projects_excludedfoldernames", 1)
    GUI.elms.scansettings_txtCustomProjects.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3"
  else
    FileScanSettings.projects_excludedFolders = GUI.Val("scansettings_txtCustomProjects")
    FileScanExclusions.CustomProjects = SplitMultiPaths(FileScanSettings.projects_excludedFolders)
    reaper.SetExtState(appname, "scan_projects_excludedfoldernames", GUI.Val("scansettings_txtCustomProjects"), 1)
    GUI.elms.scansettings_txtCustomProjects.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3\n\nCurrent: " .. GUI.Val("scansettings_txtCustomProjects")
  end

  FileScanSettings.projects_maxSubDirDepth = tonumber(GUI.Val("scansettings_txtCustomProjects_MaxScanDepth")) or 0
  FileScanSettings.projects_maxSubDirRange = tonumber(GUI.Val("scansettings_txtCustomProjects_MaxScanSubDirs")) or 0
  reaper.SetExtState(appname, "scan_projects_limits", FileScanSettings.projects_maxSubDirDepth .. "," .. FileScanSettings.projects_maxSubDirRange, 1)
  MsgStatusBar("Scan Settings for Projects updated")
end

function Set_ExcludedFolders_ProjectLists()
  if GUI.Val("scansettings_txtProjectsLists") == "" then
    FileScanSettings.projectLists_excludedFolders = ""
    FileScanExclusions.ProjectLists = {}
    reaper.DeleteExtState(appname, "scan_projectlists_excludedfoldernames", 1)
    GUI.elms.scansettings_txtProjectsLists.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3"
  else
    FileScanSettings.projectLists_excludedFolders = GUI.Val("scansettings_txtProjectsLists")
    FileScanExclusions.ProjectLists = SplitMultiPaths(FileScanSettings.projectLists_excludedFolders)
    reaper.SetExtState(appname, "scan_projectlists_excludedfoldernames", GUI.Val("scansettings_txtProjectsLists"), 1)
    GUI.elms.scansettings_txtProjectsLists.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3\n\nCurrent: " .. GUI.Val("scansettings_txtProjectsLists")
  end

  FileScanSettings.projectLists_maxSubDirDepth = tonumber(GUI.Val("scansettings_txtProjectsLists_MaxScanDepth")) or 0
  FileScanSettings.projectLists_maxSubDirRange = tonumber(GUI.Val("scansettings_txtProjectsLists_MaxScanSubDirs")) or 0
  reaper.SetExtState(appname, "scan_projectlists_limits", FileScanSettings.projectLists_maxSubDirDepth .. "," .. FileScanSettings.projectLists_maxSubDirRange, 1)
  MsgStatusBar("Scan Settings for Project Lists updated")
end

function Set_ExcludedFolders_Backups()
  if GUI.Val("scansettings_txtBackups") == "" then
    FileScanSettings.backups_excludedFolders = ""
    FileScanExclusions.Backups = {}
    reaper.DeleteExtState(appname, "scan_backups_excludedfoldernames", 1)
    GUI.elms.scansettings_txtBackups.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3"
  else
    FileScanSettings.backups_excludedFolders = GUI.Val("scansettings_txtBackups")
    FileScanExclusions.Backups = SplitMultiPaths(FileScanSettings.backups_excludedFolders)
    reaper.SetExtState(appname, "scan_backups_excludedfoldernames", GUI.Val("scansettings_txtBackups"), 1)
    GUI.elms.scansettings_txtBackups.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3\n\nCurrent: " .. GUI.Val("scansettings_txtBackups")
  end

  FileScanSettings.backups_maxSubDirDepth = tonumber(GUI.Val("scansettings_txtBackups_MaxScanDepth")) or 0
  FileScanSettings.backups_maxSubDirRange = tonumber(GUI.Val("scansettings_txtBackups_MaxScanSubDirs")) or 0
  reaper.SetExtState(appname, "scan_backups_limits", FileScanSettings.backups_maxSubDirDepth .. "," .. FileScanSettings.backups_maxSubDirRange, 1)
  MsgStatusBar("Scan Settings for Backups updated")
end

function Set_ExcludedFolders_Docs()
  if GUI.Val("scansettings_txtDocs") == "" then
    FileScanSettings.docs_excludedFolders = ""
    FileScanExclusions.Docs = {}
    reaper.DeleteExtState(appname, "scan_docs_excludedfoldernames", 1)
    GUI.elms.scansettings_txtDocs.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3"
  else
    FileScanSettings.docs_excludedFolders = GUI.Val("scansettings_txtDocs")
    FileScanExclusions.Docs = SplitMultiPaths(FileScanSettings.docs_excludedFolders)
    reaper.SetExtState(appname, "scan_docs_excludedfoldernames", GUI.Val("scansettings_txtDocs"), 1)
    GUI.elms.scansettings_txtDocs.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3\n\nCurrent: " .. GUI.Val("scansettings_txtDocs")
  end

  FileScanSettings.docs_maxSubDirDepth = tonumber(GUI.Val("scansettings_txtDocs_MaxScanDepth")) or 0
  FileScanSettings.docs_maxSubDirRange = tonumber(GUI.Val("scansettings_txtDocs_MaxScanSubDirs")) or 0
  reaper.SetExtState(appname, "scan_docs_limits", FileScanSettings.docs_maxSubDirDepth .. "," .. FileScanSettings.docs_maxSubDirRange, 1)
  MsgStatusBar("Scan Settings for Docs updated")
end

local function RL_Draw_TabPaths_ScanSettings()
  GUI.New("scansettings_lblExcludedFolders", "Label", LayerIndex.ScanSettings, 196 * RL.scaleFactor, tabSelectorPadding + 6.15 * (30 * RL.scaleFactor), "Excluded folder names | Depth limit | Range limit", false, 4)
  if RL.tabSelectorStyle == 2 then GUI.New("scansettings_frame_top", "Frame", LayerIndex.ScanSettings, 0, listbox_top, GUI.w, 2 * RL.scaleFactor, false, true) end
  
  GUI.New("scansettings_txtProjectTemplates", "Textbox", LayerIndex.ScanSettings, 196 * RL.scaleFactor, tabSelectorPadding + 1.2 * (30 * RL.scaleFactor), GUI.w - 310 * RL.scaleFactor, 20 * RL.scaleFactor, "Project Templates", 12)
  GUI.New("scansettings_txtProjectTemplates_MaxScanDepth", "Textbox", LayerIndex.ScanSettings, GUI.w - 110 * RL.scaleFactor, tabSelectorPadding + 1.2 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_txtProjectTemplates_MaxScanSubDirs", "Textbox", LayerIndex.ScanSettings, GUI.w - 78 * RL.scaleFactor, tabSelectorPadding + 1.2 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_btnProjectTemplates", "Button", LayerIndex.ScanSettings, GUI.w - 44 * RL.scaleFactor, tabSelectorPadding + 1.25 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 15 * RL.scaleFactor, "Set", Set_ExcludedFolders_ProjectTemplates)

  GUI.New("scansettings_txtTrackTemplates", "Textbox", LayerIndex.ScanSettings, 196 * RL.scaleFactor, tabSelectorPadding + 2.0 * (30 * RL.scaleFactor), GUI.w - 310 * RL.scaleFactor, 20 * RL.scaleFactor, "Track Templates", 12)
  GUI.New("scansettings_txtTrackTemplates_MaxScanDepth", "Textbox", LayerIndex.ScanSettings, GUI.w - 110 * RL.scaleFactor, tabSelectorPadding + 2.0 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_txtTrackTemplates_MaxScanSubDirs", "Textbox", LayerIndex.ScanSettings, GUI.w - 78 * RL.scaleFactor, tabSelectorPadding + 2.0 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_btnTrackTemplates", "Button", LayerIndex.ScanSettings, GUI.w - 44 * RL.scaleFactor, tabSelectorPadding + 2.05 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 15 * RL.scaleFactor, "Set", Set_ExcludedFolders_TrackTemplates)

  GUI.New("scansettings_txtCustomProjects", "Textbox", LayerIndex.ScanSettings, 196 * RL.scaleFactor, tabSelectorPadding + 2.8 * (30 * RL.scaleFactor), GUI.w - 310 * RL.scaleFactor, 20 * RL.scaleFactor, "Projects", 12)
  GUI.New("scansettings_txtCustomProjects_MaxScanDepth", "Textbox", LayerIndex.ScanSettings, GUI.w - 110 * RL.scaleFactor, tabSelectorPadding + 2.8 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_txtCustomProjects_MaxScanSubDirs", "Textbox", LayerIndex.ScanSettings, GUI.w - 78 * RL.scaleFactor, tabSelectorPadding + 2.8 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_btnCustomProjects", "Button", LayerIndex.ScanSettings, GUI.w - 44 * RL.scaleFactor, tabSelectorPadding + 2.85 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 15 * RL.scaleFactor, "Set", Set_ExcludedFolders_CustomProjects)

  GUI.New("scansettings_txtProjectsLists", "Textbox", LayerIndex.ScanSettings, 196 * RL.scaleFactor, tabSelectorPadding + 3.6 * (30 * RL.scaleFactor), GUI.w - 310 * RL.scaleFactor, 20 * RL.scaleFactor, "Project Lists", 12)
  GUI.New("scansettings_txtProjectsLists_MaxScanDepth", "Textbox", LayerIndex.ScanSettings, GUI.w - 110 * RL.scaleFactor, tabSelectorPadding + 3.6 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_txtProjectsLists_MaxScanSubDirs", "Textbox", LayerIndex.ScanSettings, GUI.w - 78 * RL.scaleFactor, tabSelectorPadding + 3.6 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_btnProjectLists", "Button", LayerIndex.ScanSettings, GUI.w - 44 * RL.scaleFactor, tabSelectorPadding + 3.65 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 15 * RL.scaleFactor, "Set", Set_ExcludedFolders_ProjectLists)

  GUI.New("scansettings_txtBackups", "Textbox", LayerIndex.ScanSettings, 196 * RL.scaleFactor, tabSelectorPadding + 4.4 * (30 * RL.scaleFactor), GUI.w - 310 * RL.scaleFactor, 20 * RL.scaleFactor, "Backups", 12)
  GUI.New("scansettings_txtBackups_MaxScanDepth", "Textbox", LayerIndex.ScanSettings, GUI.w - 110 * RL.scaleFactor, tabSelectorPadding + 4.4 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_txtBackups_MaxScanSubDirs", "Textbox", LayerIndex.ScanSettings, GUI.w - 78 * RL.scaleFactor, tabSelectorPadding + 4.4 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_btnBackups", "Button", LayerIndex.ScanSettings, GUI.w - 44 * RL.scaleFactor, tabSelectorPadding + 4.45 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 15 * RL.scaleFactor, "Set", Set_ExcludedFolders_Backups)
  
  GUI.New("scansettings_txtDocs", "Textbox", LayerIndex.ScanSettings, 196 * RL.scaleFactor, tabSelectorPadding + 5.2 * (30 * RL.scaleFactor), GUI.w - 310 * RL.scaleFactor, 20 * RL.scaleFactor, "Docs", 12)
  GUI.New("scansettings_txtDocs_MaxScanDepth", "Textbox", LayerIndex.ScanSettings, GUI.w - 110 * RL.scaleFactor, tabSelectorPadding + 5.2 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_txtDocs_MaxScanSubDirs", "Textbox", LayerIndex.ScanSettings, GUI.w - 78 * RL.scaleFactor, tabSelectorPadding + 5.2 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_btnDocs", "Button", LayerIndex.ScanSettings, GUI.w - 44 * RL.scaleFactor, tabSelectorPadding + 5.25 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 15 * RL.scaleFactor, "Set", Set_ExcludedFolders_Docs)

  function GUI.elms.scansettings_txtProjectTemplates:onmousedown()                GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.scansettings_txtTrackTemplates:onmousedown()                  GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.scansettings_txtCustomProjects:onmousedown()                  GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.scansettings_txtProjectsLists:onmousedown()                   GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.scansettings_txtBackups:onmousedown()                         GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.scansettings_txtDocs:onmousedown()                            GUI.Textbox.onmousedown(self) RL.keyInputActive = false end

  function GUI.elms.scansettings_txtProjectTemplates_MaxScanSubDirs:onmousedown() GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.scansettings_txtTrackTemplates_MaxScanSubDirs:onmousedown()   GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.scansettings_txtCustomProjects_MaxScanSubDirs:onmousedown()   GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.scansettings_txtProjectsLists_MaxScanSubDirs:onmousedown()    GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.scansettings_txtBackups_MaxScanSubDirs:onmousedown()          GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.scansettings_txtDocs_MaxScanSubDirs:onmousedown()             GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  
  function GUI.elms.scansettings_txtProjectTemplates_MaxScanDepth:onmousedown()   GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.scansettings_txtTrackTemplates_MaxScanDepth:onmousedown()     GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.scansettings_txtCustomProjects_MaxScanDepth:onmousedown()     GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.scansettings_txtProjectsLists_MaxScanDepth:onmousedown()      GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.scansettings_txtBackups_MaxScanDepth:onmousedown()            GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  function GUI.elms.scansettings_txtDocs_MaxScanDepth:onmousedown()               GUI.Textbox.onmousedown(self) RL.keyInputActive = false end
  
  function GUI.elms.scansettings_txtProjectTemplates:lostfocus()                  RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.scansettings_txtTrackTemplates:lostfocus()                    RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.scansettings_txtCustomProjects:lostfocus()                    RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.scansettings_txtProjectsLists:lostfocus()                     RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.scansettings_txtBackups:lostfocus()                           RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.scansettings_txtDocs:lostfocus()                              RL.keyInputActive = true GUI.Textbox.lostfocus(self) end

  function GUI.elms.scansettings_txtProjectTemplates_MaxScanSubDirs:lostfocus()   RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.scansettings_txtTrackTemplates_MaxScanSubDirs:lostfocus()     RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.scansettings_txtCustomProjects_MaxScanSubDirs:lostfocus()     RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.scansettings_txtProjectsLists_MaxScanSubDirs:lostfocus()      RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.scansettings_txtBackups_MaxScanSubDirs:lostfocus()            RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.scansettings_txtDocs_MaxScanSubDirs:lostfocus()               RL.keyInputActive = true GUI.Textbox.lostfocus(self) end

  function GUI.elms.scansettings_txtProjectTemplates_MaxScanDepth:lostfocus()     RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.scansettings_txtTrackTemplates_MaxScanDepth:lostfocus()       RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.scansettings_txtCustomProjects_MaxScanDepth:lostfocus()       RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.scansettings_txtProjectsLists_MaxScanDepth:lostfocus()        RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.scansettings_txtBackups_MaxScanDepth:lostfocus()              RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
  function GUI.elms.scansettings_txtDocs_MaxScanDepth:lostfocus()                 RL.keyInputActive = true GUI.Textbox.lostfocus(self) end
end

----------------
-- Tab - Actions
----------------
function GetActionName(actionCommandID)
  if SWSinstalled then return reaper.CF_GetCommandText(0, reaper.NamedCommandLookup(actionCommandID)) end
end

local function RL_Draw_TabActions()
  if RL.tabSelectorStyle == 2 then GUI.New("actions_frame_top", "Frame", LayerIndex.Actions, 0, listbox_top, GUI.w, 2 * RL.scaleFactor, false, true) end

  function Action_Set_NewProject()
    local actionValue = GUI.Val("actions_txtFollowAction_NewProject")
    reaper.SetExtState(appname, "followaction_newproject", actionValue, 1)
    GUI.elms.actions_txtFollowAction_NewProject.tooltip = GetActionName(actionValue)
    if actionValue == "" then MsgStatusBar("Follow Action removed") else MsgStatusBar("Follow Action set") end
  end

  function Action_Set_NewTab()
    local actionValue = GUI.Val("actions_txtFollowAction_NewTab")
    reaper.SetExtState(appname, "followaction_newtab", actionValue, 1)
    GUI.elms.actions_txtFollowAction_NewTab.tooltip = GetActionName(actionValue)
    if actionValue == "" then MsgStatusBar("Follow Action removed") else MsgStatusBar("Follow Action set") end
  end

  function Action_Set_LoadProject()
    local actionValue = GUI.Val("actions_txtFollowAction_LoadProject")
    reaper.SetExtState(appname, "followaction_loadproject", actionValue, 1)
    GUI.elms.actions_txtFollowAction_LoadProject.tooltip = GetActionName(actionValue)
    if actionValue == "" then MsgStatusBar("Follow Action removed") else MsgStatusBar("Follow Action set") end
  end

  function Action_Set_LoadProjectInTab()
    local actionValue = GUI.Val("actions_txtFollowAction_LoadProjectInTab")
    reaper.SetExtState(appname, "followaction_loadprojectintab", actionValue, 1)
    GUI.elms.actions_txtFollowAction_LoadProjectInTab.tooltip = GetActionName(actionValue)
    if actionValue == "" then MsgStatusBar("Follow Action removed") else MsgStatusBar("Follow Action set") end
  end

  function Action_Set_ProjectTemplate()
    local actionValue = GUI.Val("actions_txtFollowAction_LoadProjectTemplate")
    reaper.SetExtState(appname, "followaction_loadprojecttemplate", actionValue, 1)
    GUI.elms.actions_txtFollowAction_LoadProjectTemplate.tooltip = GetActionName(actionValue)
    if actionValue == "" then MsgStatusBar("Follow Action removed") else MsgStatusBar("Follow Action set") end
  end

  function Action_Set_TrackTemplate()
    local actionValue = GUI.Val("actions_txtFollowAction_InsertTrackTemplate")
    reaper.SetExtState(appname, "followaction_inserttracktemplate", actionValue, 1)
    GUI.elms.actions_txtFollowAction_InsertTrackTemplate.tooltip = GetActionName(actionValue)
    if actionValue == "" then MsgStatusBar("Follow Action removed") else MsgStatusBar("Follow Action set") end
  end

  GUI.New("actions_lblActionsHeader", "Label", LayerIndex.Actions, 230 * RL.scaleFactor, tabSelectorPadding + 6.15 * (30 * RL.scaleFactor), "Insert an Action Command ID to be triggered after", false, 4)

  GUI.New("actions_txtFollowAction_NewProject", "Textbox", LayerIndex.Actions, 230 * RL.scaleFactor, tabSelectorPadding + 1.2 * (30 * RL.scaleFactor), GUI.w - 280 * RL.scaleFactor, 20 * RL.scaleFactor, "New Project", 20)
  GUI.New("actions_btnFollowAction_NewProject", "Button", LayerIndex.Actions, GUI.w - 44 * RL.scaleFactor, tabSelectorPadding + 1.2 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 18 * RL.scaleFactor, "Set", Action_Set_NewProject)

  GUI.New("actions_txtFollowAction_NewTab", "Textbox", LayerIndex.Actions, 230 * RL.scaleFactor, tabSelectorPadding + 2.0 * (30 * RL.scaleFactor), GUI.w - 280 * RL.scaleFactor, 20 * RL.scaleFactor, "New Tab", 20)
  GUI.New("actions_btnFollowAction_NewTab", "Button", LayerIndex.Actions, GUI.w - 44 * RL.scaleFactor, tabSelectorPadding + 2.0 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 18 * RL.scaleFactor, "Set", Action_Set_NewTab)

  GUI.New("actions_txtFollowAction_LoadProject", "Textbox", LayerIndex.Actions, 230 * RL.scaleFactor, tabSelectorPadding + 2.8 * (30 * RL.scaleFactor), GUI.w - 280 * RL.scaleFactor, 20 * RL.scaleFactor, "Load Project", 20)
  GUI.New("actions_btnFollowAction_LoadProject", "Button", LayerIndex.Actions, GUI.w - 44 * RL.scaleFactor, tabSelectorPadding + 2.8 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 18 * RL.scaleFactor, "Set", Action_Set_LoadProject)

  GUI.New("actions_txtFollowAction_LoadProjectInTab", "Textbox", LayerIndex.Actions, 230 * RL.scaleFactor, tabSelectorPadding + 3.6 * (30 * RL.scaleFactor), GUI.w - 280 * RL.scaleFactor, 20 * RL.scaleFactor, "Load Project in Tab", 20)
  GUI.New("actions_btnFollowAction_LoadProjectInTab", "Button", LayerIndex.Actions, GUI.w - 44 * RL.scaleFactor, tabSelectorPadding + 3.6 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 18 * RL.scaleFactor, "Set", Action_Set_LoadProjectInTab)
  
  GUI.New("actions_txtFollowAction_LoadProjectTemplate", "Textbox", LayerIndex.Actions, 230 * RL.scaleFactor, tabSelectorPadding + 4.4 * (30 * RL.scaleFactor), GUI.w - 280 * RL.scaleFactor, 20 * RL.scaleFactor, "Load Project Template", 20)
  GUI.New("actions_btnFollowAction_LoadProjectTemplate", "Button", LayerIndex.Actions, GUI.w - 44 * RL.scaleFactor, tabSelectorPadding + 4.4 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 18 * RL.scaleFactor, "Set", Action_Set_ProjectTemplate)
  
  GUI.New("actions_txtFollowAction_InsertTrackTemplate", "Textbox", LayerIndex.Actions, 230 * RL.scaleFactor, tabSelectorPadding + 5.2 * (30 * RL.scaleFactor), GUI.w - 280 * RL.scaleFactor, 20 * RL.scaleFactor, "Insert Track Template", 20)
  GUI.New("actions_btnFollowAction_InsertTrackTemplate", "Button", LayerIndex.Actions, GUI.w - 44 * RL.scaleFactor, tabSelectorPadding + 5.2 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 18 * RL.scaleFactor, "Set", Action_Set_TrackTemplate)

  function GUI.elms.actions_txtFollowAction_NewProject:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end

  function GUI.elms.actions_txtFollowAction_NewTab:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end

  function GUI.elms.actions_txtFollowAction_LoadProject:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end

  function GUI.elms.actions_txtFollowAction_LoadProjectInTab:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end

  function GUI.elms.actions_txtFollowAction_LoadProjectTemplate:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end

  function GUI.elms.actions_txtFollowAction_InsertTrackTemplate:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end

  function GUI.elms.actions_txtFollowAction_NewProject:lostfocus()
    RL.keyInputActive = true
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.actions_txtFollowAction_NewTab:lostfocus()
    RL.keyInputActive = true
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.actions_txtFollowAction_LoadProject:lostfocus()
    RL.keyInputActive = true
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.actions_txtFollowAction_LoadProjectInTab:lostfocus()
    RL.keyInputActive = true
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.actions_txtFollowAction_LoadProjectTemplate:lostfocus()
    RL.keyInputActive = true
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.actions_txtFollowAction_InsertTrackTemplate:lostfocus()
    RL.keyInputActive = true
    GUI.Textbox.lostfocus(self)
  end
end

----------------
-- Tab - Options
----------------
function RL_Draw_SavePromptOption()
  GUI.New("options_checklistPromptToSave", "Checklist", LayerIndex.Options, 1.6 * optionspad_left, tabSelectorPadding + 10 + (2.40 * 50 - 18) * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "Prompt to save on new project", "v", 0)
  GUI.elms.options_checklistPromptToSave.shadow = false
  GUI.elms.options_checklistPromptToSave.opt_size = 15 * RL.scaleFactor
  GUI.elms.options_checklistPromptToSave:init()
  GUI.elms.options_checklistPromptToSave.tooltip = "Toggles the 'Prompt to save on new project' option under Preferences > Project"
  
  -- load last state from preferences
  local dt = reaper.SNM_GetIntConfigVar("newprojdo", -1)
  if dt&1 == 1 then GUI.Val("options_checklistPromptToSave", {true}) else GUI.Val("options_checklistPromptToSave", {false}) end

  function GUI.elms.options_checklistPromptToSave:onmousedown()
    GUI.Checklist.onmouseup(self)
    local dt = reaper.SNM_GetIntConfigVar("newprojdo", -1)
    if dt&1 == 1 then reaper.SNM_SetIntConfigVar("newprojdo", dt&~1) else reaper.SNM_SetIntConfigVar("newprojdo", dt|1) end
  end
end

local function RL_Draw_TabOptions()
  if RL.tabSelectorStyle == 2 then GUI.New("tab_options_listbox", "Listbox", LayerIndex.OptionsMenu, pad_left, listbox_top, 90 * RL.scaleFactor, listbox_h, OptionLabels, true)
  else GUI.New("tab_options_listbox", "Listbox", LayerIndex.OptionsMenu, pad_left, pad_top, 85 * RL.scaleFactor, listbox_h, OptionLabels, true) end
  
  GUI.elms.tab_options_listbox.multi = false

  function GUI.elms.tab_options_listbox:onmousedown()
    TabSelectionIndex[TabID.Options] = self:getitem(GUI.mouse.y)
    reaper.SetExtState(appname, "window_optionfocus", tostring(TabSelectionIndex[TabID.Options]), 1)
    RL_SetFocusedTab(TabID.Help + TabSelectionIndex[TabID.Options])
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_options_listbox:onmouseup()
    TabSelectionIndex[TabID.Options] = self:getitem(GUI.mouse.y)
    reaper.SetExtState(appname, "window_optionfocus", tostring(TabSelectionIndex[TabID.Options]), 1)
    RL_SetFocusedTab(TabID.Help + TabSelectionIndex[TabID.Options])
    GUI.Listbox.onmouseup(self)
  end
  
  if RL.tabSelectorStyle == 2 then GUI.New("options_frame_top", "Frame", LayerIndex.Options, 0, listbox_top, GUI.w, 2 * RL.scaleFactor, false, true) end

  GUI.New("options_frame_2", "Frame", LayerIndex.Options, 94 * RL.scaleFactor, tabSelectorPadding + 10 + 69 * RL.scaleFactor, GUI.w - 90 * RL.scaleFactor, 2 * RL.scaleFactor, false, true)
  GUI.New("options_frame_3", "Frame", LayerIndex.Options, 94 * RL.scaleFactor, tabSelectorPadding + 10 + 96 * RL.scaleFactor, GUI.w - 90 * RL.scaleFactor, 2 * RL.scaleFactor, false, true)
  GUI.New("options_frame_4", "Frame", LayerIndex.Options, 94 * RL.scaleFactor, tabSelectorPadding + 10 + 142 * RL.scaleFactor, GUI.w - 90 * RL.scaleFactor, 2 * RL.scaleFactor, false, true)

  local doubleClickEntries = "Show Prompt,Load,Load in Tab"
  if JSAPIinstalled then doubleClickEntries = "Show Prompt,Load,Load in Tab,Audio Preview" end

  GUI.New("layout_lblStartTab", "Label", LayerIndex.Options, 1.95 * optionspad_left, tabSelectorPadding + 10 + (0.95 * 50 - 18) * RL.scaleFactor, "Start Tab", false, 3)
  if osversion:find("Win") then
    GUI.New("options_menuStartTab", "Menubox", LayerIndex.Options, 3.63 * optionspad_left, tabSelectorPadding + 10 + (0.95 * 50 - 18) * RL.scaleFactor, 125 * RL.scaleFactor, 15 * RL.scaleFactor, "", 
          "Last focused,>Load specific tab,Recent Projects,Project Templates,Track Templates,Projects,Project Lists,Backups,Docs,<Favorites,>(A)uto-switch on new project/tab to,(A) Recent Projects,(A) Project Templates,(A) Track Templates,(A) Projects,(A) Project Lists,(A) Backups,(A) Docs,(A) Favorites", 8)    
          
    GUI.New("layout_lblDoubleClick", "Label", LayerIndex.Options, 1.95 * optionspad_left, tabSelectorPadding + 10 + (1.35 * 50 - 18) * RL.scaleFactor, "Double Click Behavior", false, 3)
    GUI.New("options_menuDoubleClick", "Menubox", LayerIndex.Options, 3.63 * optionspad_left, tabSelectorPadding + 10 + (1.35 * 50 - 18) * RL.scaleFactor, 125 * RL.scaleFactor, 15 * RL.scaleFactor, "", doubleClickEntries, 8)
  else
    GUI.New("options_menuStartTab", "Menubox", LayerIndex.Options, 3.95 * optionspad_left, tabSelectorPadding + 10 + (0.95 * 50 - 18) * RL.scaleFactor, 125 * RL.scaleFactor, 15 * RL.scaleFactor, "", 
            "Last focused,>Load specific tab,Recent Projects,Project Templates,Track Templates,Projects,Project Lists,Backups,Docs,<Favorites,>(A)uto-switch on new project/tab to,(A) Recent Projects,(A) Project Templates,(A) Track Templates,(A) Projects,(A) Project Lists,(A) Backups,(A) Docs,(A) Favorites", 8)    

    GUI.New("layout_lblDoubleClick", "Label", LayerIndex.Options, 1.95 * optionspad_left, tabSelectorPadding + 10 + (1.45 * 48 - 18) * RL.scaleFactor, "Double Click Behavior", false, 3)
    GUI.New("options_menuDoubleClick", "Menubox", LayerIndex.Options, 3.95 * optionspad_left, tabSelectorPadding + 10 + (1.45 * 48 - 18) * RL.scaleFactor, 125 * RL.scaleFactor, 15 * RL.scaleFactor, "", doubleClickEntries, 8)
  end
  GUI.elms.options_menuStartTab.align = 1
  GUI.elms.options_menuDoubleClick.align = 1

  function GUI.elms.options_menuStartTab:onmousedown()
    GUI.Menubox.onmouseup(self)
    reaper.SetExtState(appname, "window_starttab", GUI.Val("options_menuStartTab"), 1)
  end

  function GUI.elms.options_menuStartTab:onwheel()
    GUI.Menubox.onwheel(self)
    reaper.SetExtState(appname, "window_starttab", GUI.Val("options_menuStartTab"), 1)
  end

  function GUI.elms.options_menuDoubleClick:onmousedown()
    GUI.Menubox.onmouseup(self)
    reaper.SetExtState(appname, "mouse_doubleclick", GUI.Val("options_menuDoubleClick"), 1)
  end

  function GUI.elms.options_menuDoubleClick:onwheel()
    GUI.Menubox.onwheel(self)
    reaper.SetExtState(appname, "mouse_doubleclick", GUI.Val("options_menuDoubleClick"), 1)
  end

  GUI.New("layout_lblShowPathsInStatusbar", "Label", LayerIndex.Options, 1.95 * optionspad_left, tabSelectorPadding + 10 + (1.9 * 50 - 18) * RL.scaleFactor, "Show paths in status bar", false, 3)
  GUI.New("options_checklistShowPathsInStatusbar", "Checklist", LayerIndex.Options, 1.6 * optionspad_left, tabSelectorPadding + 10 + (1.9 * 50 - 18) * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "", "v", 0)
  GUI.elms.options_checklistShowPathsInStatusbar.shadow = false
  GUI.elms.options_checklistShowPathsInStatusbar.opt_size = 15 * RL.scaleFactor
  GUI.elms.options_checklistShowPathsInStatusbar:init()

  if osversion:find("Win") then
    GUI.New("options_menuShowPathsInStatusbar", "Menubox", LayerIndex.Options, 3.85 * optionspad_left, tabSelectorPadding + 10 + (1.9 * 50 - 18) * RL.scaleFactor, 110 * RL.scaleFactor, 15 * RL.scaleFactor, "", "Path and File,Path only", 8)
  else
    GUI.New("options_menuShowPathsInStatusbar", "Menubox", LayerIndex.Options, 3.95 * optionspad_left, tabSelectorPadding + 10 + (1.9 * 50 - 18) * RL.scaleFactor, 125 * RL.scaleFactor, 15 * RL.scaleFactor, "", "Path and File,Path only", 8) 
  end
  GUI.elms.options_menuShowPathsInStatusbar.align = 1

  function GUI.elms.options_menuShowPathsInStatusbar:onmousedown()
    GUI.Menubox.onmouseup(self)
    reaper.SetExtState(appname, "window_showpathsinstatusbarmode", GUI.Val("options_menuShowPathsInStatusbar"), 1)
  end

  function GUI.elms.options_menuShowPathsInStatusbar:onwheel()
    GUI.Menubox.onwheel(self)
    reaper.SetExtState(appname, "window_showpathsinstatusbarmode", GUI.Val("options_menuShowPathsInStatusbar"), 1)
  end

  GUI.New("options_checklistOpenPropertiesOnNewProject", "Checklist", LayerIndex.Options, 1.6 * optionspad_left, tabSelectorPadding + 10 + (2.80 * 50 - 18) * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "Open properties on new project", "v", 0)
  GUI.elms.options_checklistOpenPropertiesOnNewProject.shadow = false
  GUI.elms.options_checklistOpenPropertiesOnNewProject.opt_size = 15 * RL.scaleFactor
  GUI.elms.options_checklistOpenPropertiesOnNewProject:init()

  GUI.New("options_checklistWindowToggle", "Checklist", LayerIndex.Options, 1.6 * optionspad_left, tabSelectorPadding + 10 + (3.35 * 50 - 18) * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "Enable window toggle key", "v", 0)
  GUI.elms.options_checklistWindowToggle.shadow = false
  GUI.elms.options_checklistWindowToggle.opt_size = 15 * RL.scaleFactor
  GUI.elms.options_checklistWindowToggle:init()

  GUI.New("options_txtWindowToggleShortcut", "Textbox", LayerIndex.Options, 4 * optionspad_left, tabSelectorPadding + 10 + (3.35 * 50 - 20) * RL.scaleFactor, 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  function GUI.elms.options_txtWindowToggleShortcut:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end

  function GUI.elms.options_txtWindowToggleShortcut:lostfocus()
    RL.keyInputActive = true
    GUI.Textbox.lostfocus(self)
  end

  GUI.New("options_btnSetWindowToggleShortcut", "Button", LayerIndex.Options, 4.6 * optionspad_left, tabSelectorPadding + 10 + (3.35 * 50 - 18) * RL.scaleFactor, 30 * RL.scaleFactor, 16 * RL.scaleFactor, "Set", SetWindowToggleShortcut)

  if SWSinstalled then RL_Draw_SavePromptOption() end
end

----------------------
-- Key Shortcut Toggle
----------------------
function SetWindowToggleShortcut()
  local charValue = string.byte(GUI.Val("options_txtWindowToggleShortcut"))
  RL.windowToggleShortcut = charValue
  reaper.SetExtState(appname, "window_toggleshortcut", tostring(charValue), 1)
  if GUI.Val("options_txtWindowToggleShortcut") == "" then MsgStatusBar("Toggle shortcut removed") else MsgStatusBar("Toggle shortcut set") end
end

-------------
-- Tab - Help
-------------
local helpContentLeft = {
  [[
  Keep (window) open
  
  Select prev | next tab
  Select tab directly
  
  Help
  Options
  Favorites]]
  ,
  [[
  Filter - jump in | out
  Filter - clear
  
  Sub panel - prev | next
  Sub panel - first | last
  
  Main panel - prev | next
  Main panel - first | last]]
  ,
  [[
  Locate in Explorer/Finder
  Open Project
  
  New Project
  New Tab
  New Tab Ignore Template
  
  Load in Tab
  Load]]
  ,
  [[
  Refresh list / file cache
  Reload list
  
  Last active projects
  Add | remove Favorites
  Toggle Audio Preview
  
  Prev | next project tab
  Close current project tab]]
  ,
  [[
  Toggle paths in sub | main panel
  Toggle sort mode
  Toggle date display
  Toggle tooltips
  
  Scale list font size down | up
  Toggle window scaling size
  Scale window size down | up
  
  Main menu (middle click)
  Context menu (right click)]]
  ,
  [[]]
  ,
  [[
  << Requires js_ReaScriptAPI >>
  
  Place a WAV, FLAC, MP3 or OGG audio file with identical name into the same folder as the project or template file. Examples:
    - Demo-Project.rpp | Demo-Project.wav
    - Test.RTrackTemplate | Test.mp3
  
  o Select a preview output channel (by default 1/2) and adjust the volume knob (in %) via Left Drag or Mousewheel
  o Start/Stop preview via Key Shortcut or Double Click (on the volume knob)
  o Status colors: Silver (preview available) / Highlight color (preview playing)]]
  ,
  [[
  << Requires SWS Extensions >>
  
  (1) Search for 'Script: solger_ReaLauncher.lua' in the Action List *
  (2) Right Click on the entry and 'Copy selected action command ID' *
  (3) Open 'Extensions > Startup actions > Set global startup action'
  (4) Paste the copied command ID into the input field and confirm via [OK]
  (5) Open 'Options > Preferences > General'
  (6) Set 'Open project(s) on startup' to one of the [New project] options ** 
  
  * Or add the script to a Custom Action and copy the ID of this one
  ** Instead of [Prompt] that shows the standard startup window]]
  ,
  [[
  Favorites can be added from each tab via the [Add to Favorites] option in the main panel/menu or via Key Shortcut.
  
  Entries can be removed in the [Favorites] tab via the [Remove from Favorites] option or by using the same Key Shortcut.
  
  RIGHT CLICK on the Favorites listbox opens the context menu to: 
    o Add current project tab
    o Add all project tabs
    o Remove selected entries
    o Clear entire list]]
  ,
  [[
  Follow Actions are triggered after the operation to which they are assigned.
  
  (1) Copy the ID of a single (Custom) Action from the Action List via: Right Click > 'Copy selected action command id'
  (2) Then paste the copied ID into the input field and apply it with the [Set] button
  
  Assigning Custom Actions has the advantage that any adjustments can be made directly in the Custom Action without changing the command ID of the Follow Action itself.]]
  ,
  [[
  << Requires SWS Extensions >>
  
  Accessible via the 'Last Active' button in the status bar or via Key Shortcut.
  
  If any stored last active project tabs are found, context menu options are:
    o Load last project
    o Load all last active project tabs
    o Show projects in list
    
  The last option temporarily lists the projects (without duplicates) in the [Recent Projects] tab.
  Switching back to listing the recent projects is done via a [Refresh].
  ]]
  ,
  [[
  Selection of multiple list entries via mouse:
  
    o Select adjacent entries with SHIFT + LEFT CLICK
    o Select non-adjacent entries with CTRL/CMD + LEFT CLICK
      
  Loading a single entry directly is possible via Double Click - if set in [Options] ]]
  ,
  [[
  Possible by holding the global key combination while loading:
  
    o CTRL + SHIFT (Windows & Linux)
    o CMD + SHIFT  (macOS)
  
  Or by using the 'Open with FX offline' option in the [Open Project] window]]
  ,
  [[
  (1) Enter multiple paths separated by a semicolon (path1;path2;path3)
  (2) Set and scan the given path(s) with the [Set / Scan] buttons
  
  A rebuild of the file cache can be triggered:
    o Via the [Set / Scan] buttons for each tab
    o Via left click on the [Refresh] button
    o [Rescan all] rebuilds the file cache for all tabs at once
    
  << Requires js_ReaScriptAPI >>
      Additional [+] buttons to add folders via 'Browse' dialog]]
  ,
  [[
  << Requires SWS Extensions >>
  
  RIGHT CLICK on the Recent Projects listbox opens the context menu to: 
  
    o Remove selected entries
    o Clear entire list]]
  ,
  [[
    Optional settings to speed up the file scanning process of the given [Paths]:
      
    o Excluded folder names (separated by a semicolon)
        Folder with the given names (name1;name2) are excluded from the scan 
    
    o Range depth (0 = no limit)
        Limit the (sub)folder scan depth level
        
    o Range limit (0 = no limit)
        Limit the number of folders scanned in each depth level]]
}

local helpContentRight = {
  [[
  W
  
  LEFT | RIGHT
  1, 2, 3, 4, 5, 6, 7
  
  F1
  F2
  F3 or 0]]
  ,
  [[
  TAB | TAB or ENTER
  BACKSPACE
  
  SHIFT + UP | DOWN
  SHIFT + HOME | END
  
  UP | DOWN
  HOME | END]]
  ,
  [[
  L
  O
  
  N
  T or + 
  SHIFT + T or /
  
  SHIFT + ENTER
  ENTER]]
  ,
  [[
  F5
  SHIFT + F5
  
  A
  F  
  SPACE or *
  
  X | V
  C or -]]
  ,
  [[
  SHIFT + P | P
  S or SHIFT + S
  D
  I
  
  F8 | F9
  F10
  F11 | F12
  
  M (when buttons are hidden)
  SHIFT + M]]
  ,
  [[]]
  ,
  [[]]
  ,
  [[]]
  ,
  [[]]
  ,
  [[]]
  ,
  [[]]
  ,
  [[]]
  ,
  [[]]
  ,
  [[]]
  ,
  [[]]
}

local function RL_Draw_TabHelp()
  local helpTabPadding = listbox_top
  if RL.tabSelectorStyle == 1 then helpTabPadding = pad_top end

  GUI.New("help_frame_top", "Frame", LayerIndex.Help, 0, helpTabPadding, GUI.w, 2 * RL.scaleFactor, false, true) 

  GUI.New("tab_help_listbox", "Listbox", LayerIndex.Help, pad_left, helpTabPadding + 5, 104 * RL.scaleFactor, listbox_h, 
    "Key Shortcuts (1/5),Key Shortcuts (2/5),Key Shortcuts (3/5),Key Shortcuts (4/5),Key Shortcuts (5/5),---,Audio Preview,Default Launcher,Favorites,Follow Actions,Last Active Projects,Listbox multi-select,Load with FX offline,Paths,Recent Projects,Scan Settings",
    true)
  GUI.elms.tab_help_listbox.multi = false

 function RL_Draw_HelpFrames()
    local selectedMenuIndex = 1
    local vals = GetSelectionTable(GUI.Val("tab_help_listbox"))
    if #vals > 0 then selectedMenuIndex = vals[1] end
    if selectedMenuIndex < 6 then
      if GUI.elms.help_frameMain ~= nil then GUI.elms.help_frameMain:delete() end
      GUI.New("help_frameLeft", "Frame", LayerIndex.Help, 108 * RL.scaleFactor, helpTabPadding + 2.4 * RL.scaleFactor, GUI.w * 0.65 - (108 * RL.scaleFactor), GUI.h - (52 * RL.scaleFactor), false, false)
      GUI.New("help_frameRight", "Frame", LayerIndex.Help, (GUI.w * 0.65) - 20, helpTabPadding + 2.4 * RL.scaleFactor, GUI.w * 0.45, GUI.h - (52 * RL.scaleFactor), false, false)
      GUI.elms.help_frameLeft.pad, GUI.elms.help_frameRight.pad = 5 * RL.scaleFactor, 5 * RL.scaleFactor
      GUI.Val("help_frameLeft", GUI.word_wrap(helpContentLeft[selectedMenuIndex], 4, GUI.elms.help_frameLeft.w - 1.5 * RL.scaleFactor * GUI.elms.help_frameLeft.pad, 0, 2))
      GUI.Val("help_frameRight", GUI.word_wrap(helpContentRight[selectedMenuIndex], 4, GUI.elms.help_frameRight.w - 1.5 * RL.scaleFactor * GUI.elms.help_frameRight.pad, 0, 2))
    else
      if GUI.elms.help_frameLeft ~= nil then GUI.elms.help_frameLeft:delete() end
      if GUI.elms.help_frameRight ~= nil then GUI.elms.help_frameRight:delete() end
      GUI.New("help_frameMain", "Frame", LayerIndex.Help, 108 * RL.scaleFactor, helpTabPadding + 2.4 * RL.scaleFactor, GUI.w - 5 - (108 * RL.scaleFactor), GUI.h - (52 * RL.scaleFactor), false, false)
      GUI.elms.help_frameMain.pad = 2 * RL.scaleFactor
      GUI.Val("help_frameMain", GUI.word_wrap(helpContentLeft[selectedMenuIndex], 4, GUI.elms.help_frameMain.w - 1.5 * RL.scaleFactor * GUI.elms.help_frameMain.pad, 0, 2))
    end
    TabSelectionIndex[TabID.Help] = selectedMenuIndex
    reaper.SetExtState(appname, "window_helpfocus", tostring(selectedMenuIndex), 1)
  end

  function GUI.elms.tab_help_listbox:onmousedown()
    GUI.Listbox.onmousedown(self)
    RL_Draw_HelpFrames()
  end
  
  function GUI.elms.tab_help_listbox:onmouseup()
    GUI.Listbox.onmouseup(self)
    RL_Draw_HelpFrames()
  end

   GUI.Val("tab_help_listbox", {[1] = true})
   if reaper.GetExtState(appname, "window_helpfocus") ~= "" then GUI.Val("tab_help_listbox", {[tonumber(reaper.GetExtState(appname, "window_helpfocus"))] = true}) end
   RL_Draw_HelpFrames()

  if SWSinstalled then
    if RL.tabSelectorStyle == 2 then GUI.New("help_btnThread", "Button", LayerIndex.Help, GUI.w - (75 * RL.scaleFactor), 4.7 * RL.scaleFactor, 70 * RL.scaleFactor, 18 * RL.scaleFactor, "Forum thread") 
    else GUI.New("help_btnThread", "Button", LayerIndex.Help, pad_left, GUI.h - 50 * RL.scaleFactor, 70 * RL.scaleFactor, 18 * RL.scaleFactor, "Forum thread") end
    function GUI.elms.help_btnThread:onmousedown()
      GUI.Button.onmousedown(self)
      reaper.CF_ShellExecute([[https://forum.cockos.com/showthread.php?t=208697]])
    end
  end
end

-----------
-- Tooltips
-----------
local function RL_Draw_Tooltips()
  if RL.tabSelectorStyle == 2 then GUI.elms.main_menuTabSelector.tooltip = "Tab Navigation\n\nNavigate to different tabs by mouse click, mouse wheel or using the defined keyboard shortcuts - see [Help]" end
  GUI.elms.main_lblPaths.tooltip = "Show/hide file paths in the list"
  GUI.elms.main_checklistPaths.tooltip = "Show/hide file paths in the list"
 
  GUI.elms.tab_recentProjects_btnRefresh.tooltip = "Refresh the list"
  GUI.elms.tab_recentProjects_txtFilter.tooltip = "Filter Section\n\nFilter the list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_recentProjects_btnFilterClear.tooltip = "Filter Section\n\nClear the filter field"
  
  GUI.elms.tab_projectTemplates_btnRefresh.tooltip = "Left Click: Refresh the list\n\nRight Click: Rebuild the file cache"
  GUI.elms.tab_projectTemplates_txtFilter.tooltip = "Filter Section\n\nFilter the list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_projectTemplates_btnFilterClear.tooltip = "Filter Section\n\nClear the filter field"
  
  GUI.elms.tab_trackTemplates_btnRefresh.tooltip = "Left Click: Refresh the list\n\nRight Click: Rebuild the file cache"
  GUI.elms.tab_trackTemplates_txtFilter.tooltip = "Filter Section\n\nFilter the list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_trackTemplates_btnFilterClear.tooltip = "Filter Section\n\nClear the filter field"
  
  GUI.elms.tab_customProjects_btnRefresh.tooltip = "Left Click: Refresh the list\n\nRight Click: Rebuild the file cache"
  GUI.elms.tab_customProjects_txtFilter.tooltip = "Filter Section\n\nFilter the list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_customProjects_btnFilterClear.tooltip = "Filter Section\n\nClear the filter field"

  GUI.elms.tab_projectLists_btnRefresh.tooltip = "Left Click: Refresh the list\n\nRight Click: Rebuild the file cache"
  GUI.elms.tab_projectLists_txtFilter.tooltip = "Filter Section\n\nFilter the list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_projectLists_btnFilterClear.tooltip = "Filter Section\n\nClear the filter field"
  
  GUI.elms.tab_backups_btnRefresh.tooltip = "Left Click: Refresh the list\n\nRight Click: Rebuild the file cache"
  GUI.elms.tab_backups_txtFilter.tooltip = "Filter Section\n\nFilter the list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_backups_btnFilterClear.tooltip = "Filter Section\n\nClear the filter field"
  
  GUI.elms.tab_docs_btnRefresh.tooltip = "Left Click: Refresh the list\n\nRight Click: Rebuild the file cache"
  GUI.elms.tab_docs_txtFilter.tooltip = "Filter Section\n\nFilter the list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_docs_btnFilterClear.tooltip = "Filter Section\n\nClear the filter field"

  GUI.elms.tab_favorites_btnRefresh.tooltip = "Refresh the list"
  GUI.elms.tab_favorites_txtFilter.tooltip = "Filter Section\n\nFilter the list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_favorites_btnFilterClear.tooltip = "Filter Section\n\nClear the filter field"
  
  GUI.elms.paths_btnProjectTemplatesSet.tooltip = "Set the given paths for .RPP Project Templates\n\nAnd/or rebuild the file cache for this tab"
  GUI.elms.paths_btnTrackTemplatesSet.tooltip = "Set/Scan the given paths for .RTrackTemplate Track Templates\n\nAnd/or rebuild the file cache for this tab"
  GUI.elms.paths_btnCustomProjectsSet.tooltip = "Set/Scan the given paths for .RPP Projects\n\nAnd/or rebuild the file cache for this tab"
  GUI.elms.paths_btnProjectListsSet.tooltip = "Set/Scan the given paths for .RPL Project Lists\n\nAnd/or rebuild the file cache for this tab"
  GUI.elms.paths_btnBackupsSet.tooltip = "Set/Scan the given path for .RPP-BAK Backups\n\nAnd/or rebuild the file cache for this tab"
  GUI.elms.paths_btnDocsSet.tooltip = "Set/Scan the given path for .PDF Docs\n\nAnd/or rebuild the file cache for this tab"

  GUI.elms.scansettings_txtProjectTemplates_MaxScanSubDirs.tooltip = "Limit the number of subfolders scanned in each depth level\n\n0 = all subfolders are scanned"
  GUI.elms.scansettings_txtTrackTemplates_MaxScanSubDirs.tooltip = "Limit the number of subfolders scanned in each depth level\n\n0 = all subfolders are scanned"
  GUI.elms.scansettings_txtCustomProjects_MaxScanSubDirs.tooltip = "Limit the number of subfolders scanned in each depth level\n\n0 = all subfolders are scanned"
  GUI.elms.scansettings_txtProjectsLists_MaxScanSubDirs.tooltip = "Limit the number of subfolders scanned in each depth level\n\n0 = all subfolders are scanned"
  GUI.elms.scansettings_txtBackups_MaxScanSubDirs.tooltip = "Limit the number of subfolders scanned in each depth level\n\n0 = all subfolders are scanned"
  GUI.elms.scansettings_txtDocs_MaxScanSubDirs.tooltip = "Limit the number of subfolders scanned in each depth level\n\n0 = all subfolders are scanned"

  GUI.elms.scansettings_txtProjectTemplates_MaxScanDepth.tooltip = "Limit how many subfolder depth levels are scanned\n\n0 = all subfolder depth levels are scanned"
  GUI.elms.scansettings_txtTrackTemplates_MaxScanDepth.tooltip = "Limit how many subfolder depth levels are scanned\n\n0 = all subfolder depth levels are scanned"
  GUI.elms.scansettings_txtCustomProjects_MaxScanDepth.tooltip = "Limit how many subfolder depth levels are scanned\n\n0 = all subfolder depth levels are scanned"
  GUI.elms.scansettings_txtProjectsLists_MaxScanDepth.tooltip = "Limit how many subfolder depth levels are scanned\n\n0 = all subfolder depth levels are scanned"
  GUI.elms.scansettings_txtBackups_MaxScanDepth.tooltip = "Limit how many subfolder depth levels are scanned\n\n0 = all subfolder depth levels are scanned"
  GUI.elms.scansettings_txtDocs_MaxScanDepth.tooltip = "Limit how many subfolder depth levels are scanned\n\n0 = all subfolder depth levels are scanned"
  
  GUI.elms.scansettings_btnProjectTemplates.tooltip = "Set/update the given scan settings for Project Templates" 
  GUI.elms.scansettings_btnTrackTemplates.tooltip = "Set/update the given scan settings for Track Templates" 
  GUI.elms.scansettings_btnCustomProjects.tooltip = "Set/update the given scan settings for Projects" 
  GUI.elms.scansettings_btnProjectLists.tooltip = "Set/update the given scan settings for Project Lists" 
  GUI.elms.scansettings_btnBackups.tooltip = "Set/update the given scan settings for Backups" 
  GUI.elms.scansettings_btnDocs.tooltip = "Set/update the given scan settings for Docs" 

  GUI.elms.layout_lblShowSubfolderPanel.tooltip = "Toggles the visibility of the subfolder/list panels on the left\n\nRestart required for the changes to take effect"
  GUI.elms.layout_checklistShowSubfolderPanel.tooltip = "Toggles the visibility of the subfolder/list panels on the left\n\nRestart required for the changes to take effect"
  GUI.elms.layout_lblButtonPanelStyle.tooltip = "Toggles the visibility of the main (button) panel on the right. If hidden, these functions are accessible via Middle Click menu\n\nRestart required for the changes to take effect"
  
  GUI.elms.main_scaleFontDown.tooltip = "Scaling Section\n\nScaling the list font size down"
  GUI.elms.main_scaleFontUp.tooltip = "Scaling Section\n\nScaling the list font size up"
  GUI.elms.main_scaleInterfaceDown.tooltip = "Scaling Section\n\nScaling the window size down"
  GUI.elms.main_scaleInterfaceToggle.tooltip = "Scaling Section\n\nToggle between a small and big window size"
  GUI.elms.main_scaleInterfaceUp.tooltip = "Scaling Section\n\nScaling the window size up"

  GUI.elms.main_checklistWindowPin.tooltip = "Window Pin\n\nKeep the window open after load/insert operations"

  if RL.showButtonPanel then
    GUI.elms.main_lblWindowpin.tooltip = "Window Pin\n\nKeep the window open after load/insert operations"
    GUI.elms.main_btnNewProjectTab.tooltip = "Add new project tab"
    GUI.elms.main_btnNewTabIgnoreTemplate.tooltip = "Add new project tab\n(ignore default template)"
    GUI.elms.main_btnNewProject.tooltip = "Create new project"
    GUI.elms.main_btnOpenProject.tooltip = "Show the 'Open project' window"
    local ttLoadFXoffline = "Load with FX offline:\n  - Hold CTRL + SHIFT (Windows & Linux)\n  - Hold CMD + SHIFT (macOS)\n  - Via the option in the [Open Project] window"
    GUI.elms.tab_recentProjects_btnLoadInTab.tooltip = "Load selected recent project(s) in tab(s)\n\n" .. ttLoadFXoffline
    GUI.elms.tab_recentProjects_btnLoad.tooltip = "Load selected recent project(s)\n\n" .. ttLoadFXoffline
    GUI.elms.tab_customProjects_btnLoadInTab.tooltip = "Load the selected project(s) in tab(s)\n\n" .. ttLoadFXoffline
    GUI.elms.tab_customProjects_btnLoad.tooltip = "Load the selected project(s)\n\n" .. ttLoadFXoffline
    GUI.elms.tab_projectTemplates_btnLoadInTab.tooltip = "Load selected project template(s) in tab(s)\n\n" .. ttLoadFXoffline
    GUI.elms.tab_projectTemplates_btnLoad.tooltip = "Load selected project templates(s)\n\n" .. ttLoadFXoffline
    GUI.elms.tab_projectLists_btnLoadInTab.tooltip = "Load the selected project(s) in tab(s)\n\n" .. ttLoadFXoffline
    GUI.elms.tab_projectLists_btnLoad.tooltip = "Load the selected project(s)\n\n" .. ttLoadFXoffline
    GUI.elms.tab_backups_btnLoadInTab.tooltip = "Load the selected backup(s) in tab(s)\n\n" .. ttLoadFXoffline
    GUI.elms.tab_backups_btnLoad.tooltip = "Load the selected backup(s)\n\n" .. ttLoadFXoffline
    GUI.elms.tab_trackTemplates_btnInsertInTab.tooltip = "Insert selected track template(s) in a new tab"
    GUI.elms.tab_trackTemplates_btnInsert.tooltip = "Insert selected track template(s)"

    GUI.elms.main_lblSaveNewVersion.tooltip = "Save the loaded project(s) with an\nincremented version number: _1, _2, ..."
    GUI.elms.main_checklistSaveAsNewVersion.tooltip = "Save the loaded project(s) with an\nincremented version number: _1, _2, ..."

    GUI.elms.tab_projectTemplates_lblEditMode.tooltip = "Check to open project template in edit mode"
    GUI.elms.tab_projectTemplates_checklistEditMode.tooltip = "Check to open project template in edit mode"
  end

  if JSAPIinstalled then
    GUI.elms.paths_btnProjectTemplatesBrowse.tooltip = "Browse for Project Templates folders"
    GUI.elms.paths_btnTrackTemplatesBrowse.tooltip = "Browse for Track Templates folders"
    GUI.elms.paths_btnCustomProjectsBrowse.tooltip = "Browse for Projects folders"
    GUI.elms.paths_btnProjectListsBrowse.tooltip = "Browse for Project Lists folders" 
    GUI.elms.paths_btnBackupsBrowse.tooltip = "Browse for Backups folders"
    GUI.elms.paths_btnDocsBrowse.tooltip = "Browse for Docs folders"
  end

  if SWSinstalled and RL.showButtonPanel then
    GUI.elms.main_btnOpenInExplorer.tooltip = "Locate the selected files in Explorer/Finder"
  end
end

--------------------------
-- Color element functions
--------------------------
function RL_Init_Colors_Button()
  local buttonElements = {
    GUI.elms.tab_recentProjects_btnRefresh, GUI.elms.tab_projectTemplates_btnRefresh, GUI.elms.tab_trackTemplates_btnRefresh, GUI.elms.tab_customProjects_btnRefresh,
    GUI.elms.tab_projectLists_btnRefresh, GUI.elms.tab_backups_btnRefresh, GUI.elms.tab_docs_btnRefresh, GUI.elms.tab_favorites_btnRefresh, 
    GUI.elms.paths_btnProjectTemplatesSet, GUI.elms.paths_btnTrackTemplatesSet, GUI.elms.paths_btnCustomProjectsSet,
    GUI.elms.paths_btnProjectListsSet, GUI.elms.paths_btnBackupsSet, GUI.elms.paths_btnDocsSet,
    GUI.elms.scansettings_btnProjectTemplates, GUI.elms.scansettings_btnTrackTemplates, GUI.elms.scansettings_btnCustomProjects,
    GUI.elms.scansettings_btnProjectLists, GUI.elms.scansettings_btnBackups, GUI.elms.scansettings_btnDocs,
    GUI.elms.actions_btnFollowAction_NewProject, GUI.elms.actions_btnFollowAction_NewTab,
    GUI.elms.actions_btnFollowAction_LoadProject, GUI.elms.actions_btnFollowAction_LoadProjectInTab,
    GUI.elms.actions_btnFollowAction_LoadProjectTemplate, GUI.elms.actions_btnFollowAction_InsertTrackTemplate, GUI.elms.paths_btnRescanAllPaths,
    GUI.elms.options_btnSetWindowToggleShortcut
  }

  if RL.showButtonPanel then
    buttonElements[#buttonElements + 1] = GUI.elms.main_btnOpenProject
    buttonElements[#buttonElements + 1] = GUI.elms.main_btnNewProjectTab
    buttonElements[#buttonElements + 1] = GUI.elms.main_btnNewTabIgnoreTemplate
    buttonElements[#buttonElements + 1] = GUI.elms.main_btnNewProject
    buttonElements[#buttonElements + 1] = GUI.elms.main_btnAddToFavorites
    buttonElements[#buttonElements + 1] = GUI.elms.tab_recentProjects_btnLoadInTab
    buttonElements[#buttonElements + 1] = GUI.elms.tab_recentProjects_btnLoad
    buttonElements[#buttonElements + 1] = GUI.elms.tab_projectTemplates_btnLoadInTab
    buttonElements[#buttonElements + 1] = GUI.elms.tab_projectTemplates_btnLoad
    buttonElements[#buttonElements + 1] = GUI.elms.tab_trackTemplates_btnInsertInTab
    buttonElements[#buttonElements + 1] = GUI.elms.tab_trackTemplates_btnInsert
    buttonElements[#buttonElements + 1] = GUI.elms.tab_customProjects_btnLoadInTab
    buttonElements[#buttonElements + 1] = GUI.elms.tab_customProjects_btnLoad
    buttonElements[#buttonElements + 1] = GUI.elms.tab_projectLists_btnLoadInTab
    buttonElements[#buttonElements + 1] = GUI.elms.tab_projectLists_btnLoad
    buttonElements[#buttonElements + 1] = GUI.elms.tab_backups_btnLoadInTab
    buttonElements[#buttonElements + 1] = GUI.elms.tab_backups_btnLoad
    buttonElements[#buttonElements + 1] = GUI.elms.tab_docs_btnOpen
    buttonElements[#buttonElements + 1] = GUI.elms.tab_favorites_btnRemoveFromFavorites
  end

  if ConfigFlags.enableCustomColorOptions then buttonElements[#buttonElements + 1] = GUI.elms.colors_btnResetColors end

  if JSAPIinstalled then
    buttonElements[#buttonElements + 1] = GUI.elms.paths_btnProjectTemplatesBrowse
    buttonElements[#buttonElements + 1] = GUI.elms.paths_btnTrackTemplatesBrowse
    buttonElements[#buttonElements + 1] = GUI.elms.paths_btnCustomProjectsBrowse
    buttonElements[#buttonElements + 1] = GUI.elms.paths_btnProjectListsBrowse
    buttonElements[#buttonElements + 1] = GUI.elms.paths_btnBackupsBrowse
    buttonElements[#buttonElements + 1] = GUI.elms.paths_btnDocsBrowse
  end

  if SWSinstalled then 
    if RL.showButtonPanel then buttonElements[#buttonElements + 1] = GUI.elms.main_btnOpenInExplorer end
    buttonElements[#buttonElements + 1] = GUI.elms.help_btnThread
    buttonElements[#buttonElements + 1] = GUI.elms.layout_themeslot_Setup
    buttonElements[#buttonElements + 1] = GUI.elms.layout_themeslot_Save
  end

  for b = 1, #buttonElements do
    buttonElements[b].col_fill = GUI.colors.wnd_bg
    buttonElements[b]:init()
  end
end

function RL_Init_Colors_Highlight()
  local checklistElements = {
    GUI.elms.main_checklistWindowPin, GUI.elms.main_checklistPaths, GUI.elms.options_checklistOpenPropertiesOnNewProject,
    GUI.elms.options_checklistShowPathsInStatusbar,GUI.elms.layout_checklistShowSubfolderPanel
  }

  if SWSinstalled then
    checklistElements[#checklistElements + 1] = GUI.elms.options_checklistPromptToSave
    checklistElements[#checklistElements + 1] = GUI.elms.options_checklistWindowToggle
  end

  if JSAPIinstalled then checklistElements[#checklistElements + 1] = GUI.elms.main_checklistDate end

  for c = 1, #checklistElements do checklistElements[c]:init() end
end

function RL_Init_Colors_TextElements()
  local textElements = {
    GUI.elms.tab_recentProjects_btnFilterClear, GUI.elms.tab_projectTemplates_btnFilterClear, GUI.elms.tab_trackTemplates_btnFilterClear, GUI.elms.tab_customProjects_btnFilterClear,
    GUI.elms.tab_projectLists_btnFilterClear, GUI.elms.tab_backups_btnFilterClear, GUI.elms.tab_docs_btnFilterClear,GUI.elms.tab_favorites_btnFilterClear,
    GUI.elms.main_statusbar, GUI.elms.main_lblPaths, GUI.elms.colors_lbl_elmFill, GUI.elms.colors_lbl_txt, GUI.elms.colors_lbl_elmBg, GUI.elms.colors_lbl_wndBg, GUI.elms.colors_lbl_infotext,
    GUI.elms.layout_lblStartTab, GUI.elms.layout_lblDoubleClick, GUI.elms.layout_lblShowPathsInStatusbar,
    GUI.elms.layout_lblTabSelectorStyle, GUI.elms.layout_lblButtonPanelStyle, GUI.elms.layout_lblShowSubfolderPanel,
    GUI.elms.scansettings_lblExcludedFolders, GUI.elms.actions_lblActionsHeader, GUI.elms.paths_lblInfo,
    GUI.elms.main_btnHelp, GUI.elms.main_btnOptions, GUI.elms.main_scaleFontDown, GUI.elms.main_scaleFontUp,
    GUI.elms.main_scaleInterfaceDown, GUI.elms.main_scaleInterfaceToggle, GUI.elms.main_scaleInterfaceUp, GUI.elms.main_btnToggleTooltips
  }

  if RL.showButtonPanel then
    textElements[#textElements + 1] = GUI.elms.main_lblSaveNewVersion
    textElements[#textElements + 1] = GUI.elms.main_lblWindowpin
    textElements[#textElements + 1] = GUI.elms.tab_projectTemplates_lblEditMode
    textElements[#textElements + 1] = GUI.elms.tab_favorites_lblEditMode
    textElements[#textElements + 1] = GUI.elms.tab_favorites_lblSaveNewVersion
  end

  if SWSinstalled then
    textElements[#textElements + 1] = GUI.elms.main_lblThemeslots
    textElements[#textElements + 1] = GUI.elms.tab_recentProjects_btnLastActiveProject
  end

  if JSAPIinstalled then
    textElements[#textElements + 1] = GUI.elms.main_previewStatusLabel
    textElements[#textElements + 1] = GUI.elms.main_lblDates
  end

  if ConfigFlags.enableHiDPIModeOptions then textElements[#textElements + 1] = GUI.elms.layout_lblRetinaMode end

  for t = 1, #textElements do textElements[t]:init() end
end

function RL_Init_Colors_ElementBackground()
  for p = 1, #ParentListBoxElements do
    if ParentListBoxElements[p] ~= nil then 
      ParentListBoxElements[p].col_fill = GUI.colors.elm_fill
      ParentListBoxElements[p]:init()
    end
  end

  for l = 1, #ListBoxElements do
    ListBoxElements[l].col_fill = GUI.colors.elm_fill
    ListBoxElements[l]:init()
  end

  local inputElements = {
    -- MenuBox
    GUI.elms.main_sortMode, GUI.elms.layout_menuRetinaMode, GUI.elms.options_menuStartTab, GUI.elms.options_menuDoubleClick, GUI.elms.options_menuShowPathsInStatusbar,
    GUI.elms.layout_menuTabSelectorStyle, GUI.elms.layout_menuButtonPanelStyle, 
    -- TextBox
    GUI.elms.tab_recentProjects_txtFilter, GUI.elms.tab_projectTemplates_txtFilter, GUI.elms.tab_trackTemplates_txtFilter, GUI.elms.tab_customProjects_txtFilter,
    GUI.elms.tab_projectLists_txtFilter, GUI.elms.tab_backups_txtFilter, GUI.elms.tab_docs_txtFilter, GUI.elms.tab_favorites_txtFilter,
    GUI.elms.paths_txtProjectTemplatesPath, GUI.elms.paths_txtTrackTemplatesPath, GUI.elms.paths_txtCustomProjectsPath,
    GUI.elms.paths_txtProjectsListsPath, GUI.elms.paths_txtBackupsPath, GUI.elms.paths_txtDocsPath,
    GUI.elms.scansettings_txtProjectTemplates, GUI.elms.scansettings_txtProjectTemplates_MaxScanSubDirs, GUI.elms.scansettings_txtProjectTemplates_MaxScanDepth,
    GUI.elms.scansettings_txtTrackTemplates, GUI.elms.scansettings_txtTrackTemplates_MaxScanSubDirs, GUI.elms.scansettings_txtTrackTemplates_MaxScanDepth,
    GUI.elms.scansettings_txtCustomProjects, GUI.elms.scansettings_txtCustomProjects_MaxScanSubDirs, GUI.elms.scansettings_txtCustomProjects_MaxScanDepth,
    GUI.elms.scansettings_txtProjectsLists, GUI.elms.scansettings_txtProjectsLists_MaxScanSubDirs, GUI.elms.scansettings_txtProjectsLists_MaxScanDepth,
    GUI.elms.scansettings_txtBackups, GUI.elms.scansettings_txtBackups_MaxScanSubDirs, GUI.elms.scansettings_txtBackups_MaxScanDepth,
    GUI.elms.scansettings_txtDocs, GUI.elms.scansettings_txtDocs_MaxScanSubDirs, GUI.elms.scansettings_txtDocs_MaxScanDepth,
    GUI.elms.actions_txtFollowAction_NewProject, GUI.elms.actions_txtFollowAction_NewTab, GUI.elms.actions_txtFollowAction_LoadProject,
    GUI.elms.actions_txtFollowAction_LoadProjectInTab, GUI.elms.actions_txtFollowAction_LoadProjectTemplate, 
    GUI.elms.actions_txtFollowAction_InsertTrackTemplate, GUI.elms.options_txtWindowToggleShortcut,
  }

  if RL.tabSelectorStyle == 2 then inputElements[#inputElements + 1] = GUI.elms.main_menuTabSelector end 

  if SWSinstalled then
    inputElements[#inputElements + 1] = GUI.elms.layout_themeslot_number
    inputElements[#inputElements + 1] = GUI.elms.main_menuThemeslot
  end 

  if JSAPIinstalled then inputElements[#inputElements + 1] = GUI.elms.main_previewChannels end 

  for m = 1, #inputElements do
    if inputElements[m] ~= nil then inputElements[m]:init() end
  end
end

function RL_InitCustomColors()
  if ConfigFlags.enableCustomColorOptions then 
    local elementColors = {}
    for match in reaper.GetExtState(appname, "window_color_elmfill"):gmatch("([^,%s]+)") do elementColors[#elementColors + 1] = tonumber(match) end
    if #elementColors > 0 then GUI.colors.elm_fill = {elementColors[1] / 255, elementColors[2] / 255, elementColors[3] / 255} end

    elementColors = {}
    for match in reaper.GetExtState(appname, "window_color_txt"):gmatch("([^,%s]+)") do elementColors[#elementColors + 1] = tonumber(match) end
    if #elementColors > 0 then GUI.colors.txt = {elementColors[1] / 255, elementColors[2] / 255, elementColors[3] / 255} end

    elementColors = {}
    for match in reaper.GetExtState(appname, "window_color_wndbg"):gmatch("([^,%s]+)") do elementColors[#elementColors + 1] = tonumber(match) end
    if #elementColors > 0 then GUI.colors.wnd_bg = {elementColors[1] / 255, elementColors[2] / 255, elementColors[3] / 255} end

    elementColors = {}
    for match in reaper.GetExtState(appname, "window_color_elmbg"):gmatch("([^,%s]+)") do elementColors[#elementColors + 1] = tonumber(match) end
    if #elementColors > 0 then GUI.colors.elm_bg = {elementColors[1] / 255, elementColors[2] / 255, elementColors[3] / 255} end

    GUI.elms.colors_frame_elmFill.color = GUI.colors.elm_fill
    GUI.elms.colors_frame_txt.color = GUI.colors.txt
    GUI.elms.colors_frame_wndBg.color = GUI.colors.wnd_bg
    GUI.elms.colors_frame_elmBg.color = GUI.colors.elm_bg

    GUI.elms.main_lblPaths:init()
    GUI.elms.main_statusbar:init()
    GUI.elms.layout_lblButtonPanelStyle:init()
    GUI.elms.layout_lblShowSubfolderPanel:init()
    GUI.elms.colors_lbl_elmBg:init()
    GUI.elms.colors_lbl_elmFill:init()
    GUI.elms.colors_lbl_txt:init()
    GUI.elms.colors_lbl_wndBg:init()
    GUI.elms.actions_lblActionsHeader:init()
    GUI.elms.scansettings_lblExcludedFolders:init()

    if GUI.elms.help_frameMain ~= nil then GUI.elms.help_frameMain:init() end
    if GUI.elms.help_frameLeft ~= nil then GUI.elms.help_frameLeft:init() end
    if GUI.elms.help_frameRight ~= nil then GUI.elms.help_frameRight:init() end

    if JSAPIinstalled and ConfigFlags.enableAudioPreview then GUI.elms.main_previewStatusLabel:init() end

    if showButtonPanel then
      GUI.elms.main_lblWindowpin:init()
      GUI.elms.main_lblSaveNewVersion:init()
      GUI.elms.tab_projectTemplates_lblEditMode:init()
      if GUI.elms.tab_favorites_lblSaveNewVersion ~= nil then GUI.elms.tab_favorites_lblSaveNewVersion:init() end
      if GUI.elms.tab_favorites_lblEditMode ~= nil then GUI.elms.tab_favorites_lblEditMode:init() end
    end
    
    RL_Init_Colors_Highlight()
    RL_Init_Colors_ElementBackground()
    RL_Init_Colors_TextElements()
    RL_Init_Colors_Button()
  end
end

------------------
-- Redraw function
------------------
function RL_RedrawAll()
  RL_Draw_Main()

  RL_Draw_TabRecentProjects()
  RL_Draw_TabProjectTemplates()
  RL_Draw_TabTrackTemplates()
  RL_Draw_TabCustomProjects()
  RL_Draw_TabProjectLists()
  RL_Draw_TabBackups()
  RL_Draw_TabDocs()
  RL_Draw_TabFavorites()

  RL_Draw_TabLayout()
  RL_Draw_TabActions()
  RL_Draw_TabOptions()
  RL_Draw_TabPaths_ScanSettings()
  RL_Draw_TabPaths()
  RL_Draw_TabHelp()
  
  RL_Draw_Frames()
  RL_Draw_Tooltips()
  RL_Init_Colors_Button()
end
RL_RedrawAll()

function RL_SetStartTab(operationMode)
  local firstTab = tonumber(ConfigFlags.setfirstTabToLoad)
  if firstTab > 0 then -- load tab from ConfigFlags value
    if firstTab <= #TabLabels then RL_SetFocusedTab(firstTab) else RL_SetFocusedTab(#TabLabels) end 
  else
    if operationMode == "onUpdate" then RL_SetFocusedTab(tonumber(reaper.GetExtState(appname, "window_tabfocus")))
    else
      local selectedTabOption = GUI.Val("options_menuStartTab")
      if selectedTabOption == 1 then RL_SetFocusedTab(tonumber(reaper.GetExtState(appname, "window_tabfocus"))) -- load last focused
        -- always load specific tab
      elseif selectedTabOption >= 3 and selectedTabOption <= 11 and operationMode == "onStart" then RL_SetFocusedTab(selectedTabOption - 2)
      elseif selectedTabOption >= 12 and selectedTabOption <= 19 then
      -- either load a specific tab (on new project or new tab) or the last focused tab
          if IsNotNullOrEmpty(reaper.GetProjectName(-1)) then RL_SetFocusedTab(tonumber(reaper.GetExtState(appname, "window_tabfocus")))
          else RL_SetFocusedTab(selectedTabOption - 11) end
      end
    end
  end
end

-----------------
-- Load ExtStates
-----------------
local function RL_ExtStates_Load(operationMode)
  GUI.Val("main_checklistWindowPin", {(reaper.GetExtState(appname, "window_pin") == "true" and true or false)}) 
  
  if (reaper.GetExtState(appname, "window_showtooltips") == "true" and true or false) then
    GUI.elms.main_btnToggleTooltips.color = FilterColor.active
    GUI.elms.main_btnToggleTooltips:init()
    RL.showTooltips = true
  end

  if ConfigFlags.enableSortModeOptions and IsNotNullOrEmpty(reaper.GetExtState(appname, "window_sortmode")) then
    local sortIndices = {}
    for sortMatch in reaper.GetExtState(appname, "window_sortmode"):gmatch("([^,%s]+)") do sortIndices[#sortIndices + 1] = tonumber(sortMatch) end
    if #sortIndices == 8 then RL.sortModeIndex = sortIndices end
    GUI.Val("main_sortMode", RL.sortModeIndex[GUI.elms.main_tabs.state] or 1)
  end
  
  GUI.Val("options_menuStartTab", tonumber(reaper.GetExtState(appname, "window_starttab")))
  RL_SetStartTab(operationMode)

  local isButtonPanelVisible = reaper.GetExtState(appname, "window_showmainbuttonpanel")
  if isButtonPanelVisible == "" then
    isButtonPanelVisible = true
    GUI.Val("layout_menuButtonPanelStyle", 1)
  else
    isButtonPanelVisible = (reaper.GetExtState(appname, "window_showmainbuttonpanel") == "true" and true or false)
    if isButtonPanelVisible then GUI.Val("layout_menuButtonPanelStyle", 1) else GUI.Val("layout_menuButtonPanelStyle", 2) end
  end
  
  local mouseDoubleClick = reaper.GetExtState(appname, "mouse_doubleclick")
  if mouseDoubleClick == "" then mouseDoubleClick = 2 end
  if mouseDoubleClick == "4" and not JSAPIinstalled then mouseDoubleClick = 2 end
  GUI.Val("options_menuDoubleClick", mouseDoubleClick)

  GUI.Val("options_checklistOpenPropertiesOnNewProject", {(reaper.GetExtState(appname, "project_showproperties") == "true" and true or false)}) 

  GUI.Val("options_checklistWindowToggle", {(reaper.GetExtState(appname, "window_togglemode") == "true" and true or false)}) 
  RL.windowToggleShortcut = tonumber(reaper.GetExtState(appname, "window_toggleshortcut"))
  if RL.windowToggleShortcut ~= nil then GUI.Val("options_txtWindowToggleShortcut", string.char(RL.windowToggleShortcut)) end

  GUI.Val("options_checklistShowPathsInStatusbar", {(reaper.GetExtState(appname, "window_showpathsinstatusbar") == "true" and true or false)}) 
  local pathInStatusBarMode = reaper.GetExtState(appname, "window_showpathsinstatusbarmode")
  if pathInStatusBarMode == "" then pathInStatusBarMode = 1 end
  GUI.Val("options_menuShowPathsInStatusbar", pathInStatusBarMode)
  
  if not ConfigFlags.resetListDisplayAtLaunch then 
    GUI.Val("main_checklistPaths", {(reaper.GetExtState(appname, "window_showpaths") == "true" and true or false)})
    Global_UpdateListDisplay()
  end
  
  if JSAPIinstalled then 
    GUI.Val("main_previewVolKnob", tonumber(reaper.GetExtState(appname, "preview_vol")))
    AudioPreview.channelIndex = tonumber(reaper.GetExtState(appname, "preview_channel"))
    GUI.Val("main_previewChannels",tonumber(reaper.GetExtState(appname, "preview_channelmenuitem")))

    if not ConfigFlags.resetListDisplayAtLaunch then 
      GUI.Val("main_checklistDate", {(reaper.GetExtState(appname, "window_showdate") == "true" and true or false)})
      RL.showDate = GUI.Val("main_checklistDate")
    end
  end

  if GUI.elms.main_tabs.state <= TabID.Favorites then Global_UpdateListDisplay() end

  if not ConfigFlags.resetFiltersAtLaunch then
    GUI.Val("tab_recentProjects_txtFilter", reaper.GetExtState(appname, "filter_recentprojects"))
    GUI.Val("tab_projectTemplates_txtFilter", reaper.GetExtState(appname, "filter_projecttemplates"))
    GUI.Val("tab_trackTemplates_txtFilter", reaper.GetExtState(appname, "filter_tracktemplates"))
    GUI.Val("tab_customProjects_txtFilter", reaper.GetExtState(appname, "filter_projects"))
    GUI.Val("tab_projectLists_txtFilter", reaper.GetExtState(appname, "filter_projectlists"))
    GUI.Val("tab_backups_txtFilter", reaper.GetExtState(appname, "filter_backups"))
    GUI.Val("tab_docs_txtFilter", reaper.GetExtState(appname, "filter_docs"))
    GUI.Val("tab_favorites_txtFilter", reaper.GetExtState(appname, "filter_favorites"))
    Global_UpdateFilter()
  end
  
  GUI.elms.paths_txtProjectTemplatesPath:val(reaper.GetExtState(appname, "custompath_projecttemplates"))
  GUI.elms.paths_txtTrackTemplatesPath:val(reaper.GetExtState(appname, "custompath_tracktemplates"))
  GUI.elms.paths_txtCustomProjectsPath:val(reaper.GetExtState(appname, "custompath_projects"))
  GUI.elms.paths_txtProjectsListsPath:val(reaper.GetExtState(appname, "custompath_projectlists"))
  GUI.elms.paths_txtBackupsPath:val(reaper.GetExtState(appname, "custompath_backups"))
  GUI.elms.paths_txtDocsPath:val(reaper.GetExtState(appname, "custompath_docs"))
  
  GUI.elms.paths_txtProjectTemplatesPath.tooltip = ".RPP Project Templates\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3\n\nCurrent: ".. GUI.Val("paths_txtProjectTemplatesPath")
  GUI.elms.paths_txtTrackTemplatesPath.tooltip = ".RTrackTemplate Track Templates\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3\n\nCurrent: ".. GUI.Val("paths_txtTrackTemplatesPath")
  GUI.elms.paths_txtCustomProjectsPath.tooltip = ".RPP Projects\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3\n\nCurrent: ".. GUI.Val("paths_txtCustomProjectsPath")
  GUI.elms.paths_txtProjectsListsPath.tooltip = ".RPL Project Lists\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3\n\nCurrent: ".. GUI.Val("paths_txtProjectsListsPath")
  GUI.elms.paths_txtBackupsPath.tooltip = ".RPP-BAK Backups\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3\n\nCurrent: ".. GUI.Val("paths_txtBackupsPath")
  GUI.elms.paths_txtDocsPath.tooltip = ".PDF Docs\n\nEnter one or multiple paths separated by a semicolon\nExample: path1;path2;path3\n\nCurrent: " .. GUI.Val("paths_txtDocsPath")

  GUI.elms.actions_txtFollowAction_NewProject:val(reaper.GetExtState(appname, "followaction_newproject"))
  GUI.elms.actions_txtFollowAction_NewTab:val(reaper.GetExtState(appname, "followaction_newtab"))
  GUI.elms.actions_txtFollowAction_LoadProject:val(reaper.GetExtState(appname, "followaction_loadproject"))
  GUI.elms.actions_txtFollowAction_LoadProjectInTab:val(reaper.GetExtState(appname, "followaction_loadprojectintab"))
  GUI.elms.actions_txtFollowAction_LoadProjectTemplate:val(reaper.GetExtState(appname, "followaction_loadprojecttemplate"))
  GUI.elms.actions_txtFollowAction_InsertTrackTemplate:val(reaper.GetExtState(appname, "followaction_inserttracktemplate"))

  GUI.elms.scansettings_txtProjectTemplates:val(reaper.GetExtState(appname, "scan_projecttemplates_excludedfoldernames"))
  GUI.elms.scansettings_txtTrackTemplates:val(reaper.GetExtState(appname, "scan_tracktemplates_excludedfoldernames"))
  GUI.elms.scansettings_txtCustomProjects:val(reaper.GetExtState(appname, "scan_projects_excludedfoldernames"))
  GUI.elms.scansettings_txtProjectsLists:val(reaper.GetExtState(appname, "scan_projectlists_excludedfoldernames"))
  GUI.elms.scansettings_txtBackups:val(reaper.GetExtState(appname, "scan_backups_excludedfoldernames"))
  GUI.elms.scansettings_txtDocs:val(reaper.GetExtState(appname, "scan_docs_excludedfoldernames"))

  FileScanSettings.projectTemplates_excludedFolders = GUI.Val("scansettings_txtProjectTemplates")
  GUI.elms.scansettings_txtProjectTemplates.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3\n\nCurrent: " .. GUI.Val("scansettings_txtProjectTemplates")
  FileScanExclusions.ProjectTemplates = SplitMultiPaths(FileScanSettings.projectTemplates_excludedFolders)

  FileScanSettings.trackTemplates_excludedFolders = GUI.Val("scansettings_txtTrackTemplates")
  GUI.elms.scansettings_txtTrackTemplates.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3\n\nCurrent: " .. GUI.Val("scansettings_txtTrackTemplates")
  FileScanExclusions.TrackTemplates = SplitMultiPaths(FileScanSettings.trackTemplates_excludedFolders)

  FileScanSettings.projects_excludedFolders = GUI.Val("scansettings_txtCustomProjects")
  GUI.elms.scansettings_txtCustomProjects.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3\n\nCurrent: " .. GUI.Val("scansettings_txtCustomProjects")
  FileScanExclusions.CustomProjects = SplitMultiPaths(FileScanSettings.projects_excludedFolders)

  FileScanSettings.projectLists_excludedFolders = GUI.Val("scansettings_txtProjectsLists")
  GUI.elms.scansettings_txtProjectsLists.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3\n\nCurrent: " ..  GUI.Val("scansettings_txtProjectsLists")
  FileScanExclusions.ProjectLists = SplitMultiPaths(FileScanSettings.projectLists_excludedFolders)

  FileScanSettings.backups_excludedFolders = GUI.Val("scansettings_txtBackups")
  GUI.elms.scansettings_txtBackups.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3\n\nCurrent: " .. GUI.Val("scansettings_txtBackups")
  FileScanExclusions.Backups = SplitMultiPaths(FileScanSettings.backups_excludedFolders)

  FileScanSettings.docs_excludedFolders = GUI.Val("scansettings_txtDocs")
  GUI.elms.scansettings_txtDocs.tooltip = "Enter one or multiple folder names separated by a semicolon that should be excluded from the scan\n\nExample: name1;name2;name3\n\nCurrent: " .. GUI.Val("scansettings_txtDocs")
  FileScanExclusions.Docs = SplitMultiPaths(FileScanSettings.docs_excludedFolders)

  scanMaxSettings = {}
  for match in reaper.GetExtState(appname, "scan_projecttemplates_limits"):gmatch("([^,%s]+)") do scanMaxSettings[#scanMaxSettings + 1] = tonumber(match) end
  GUI.elms.scansettings_txtProjectTemplates_MaxScanDepth:val(scanMaxSettings[1] or 0)
  GUI.elms.scansettings_txtProjectTemplates_MaxScanSubDirs:val(scanMaxSettings[2] or 0)
  FileScanSettings.projectTemplates_maxSubDirDepth = scanMaxSettings[1] or 0
  FileScanSettings.projectTemplates_maxSubDirRange = scanMaxSettings[2] or 0

  scanMaxSettings = {}
  for match in reaper.GetExtState(appname, "scan_tracktemplates_limits"):gmatch("([^,%s]+)") do scanMaxSettings[#scanMaxSettings + 1] = tonumber(match) end
  GUI.elms.scansettings_txtTrackTemplates_MaxScanDepth:val(scanMaxSettings[1] or 0)
  GUI.elms.scansettings_txtTrackTemplates_MaxScanSubDirs:val(scanMaxSettings[2] or 0)
  FileScanSettings.trackTemplates_maxSubDirDepth = scanMaxSettings[1] or 0
  FileScanSettings.trackTemplates_maxSubDirRange = scanMaxSettings[2] or 0

  scanMaxSettings = {}
  for match in reaper.GetExtState(appname, "scan_projects_limits"):gmatch("([^,%s]+)") do scanMaxSettings[#scanMaxSettings + 1] = tonumber(match) end
  GUI.elms.scansettings_txtCustomProjects_MaxScanDepth:val(scanMaxSettings[1] or 0)
  GUI.elms.scansettings_txtCustomProjects_MaxScanSubDirs:val(scanMaxSettings[2] or 0)
  FileScanSettings.projects_maxSubDirDepth = scanMaxSettings[1] or 0
  FileScanSettings.projects_maxSubDirRange = scanMaxSettings[2] or 0

  scanMaxSettings = {}
  for match in reaper.GetExtState(appname, "scan_projectlists_limits"):gmatch("([^,%s]+)") do scanMaxSettings[#scanMaxSettings + 1] = tonumber(match) end
  GUI.elms.scansettings_txtProjectsLists_MaxScanDepth:val(scanMaxSettings[1] or 0)
  GUI.elms.scansettings_txtProjectsLists_MaxScanSubDirs:val(scanMaxSettings[2] or 0)
  FileScanSettings.projectLists_maxSubDirDepth = scanMaxSettings[1] or 0
  FileScanSettings.projectLists_maxSubDirRange = scanMaxSettings[2] or 0

  scanMaxSettings = {}
  for match in reaper.GetExtState(appname, "scan_backups_limits"):gmatch("([^,%s]+)") do scanMaxSettings[#scanMaxSettings + 1] = tonumber(match) end
  GUI.elms.scansettings_txtBackups_MaxScanDepth:val(scanMaxSettings[1] or 0)
  GUI.elms.scansettings_txtBackups_MaxScanSubDirs:val(scanMaxSettings[2] or 0)
  FileScanSettings.backups_maxSubDirDepth = scanMaxSettings[1] or 0
  FileScanSettings.backups_maxSubDirRange = scanMaxSettings[2] or 0

  scanMaxSettings = {}
  for match in reaper.GetExtState(appname, "scan_docs_limits"):gmatch("([^,%s]+)") do scanMaxSettings[#scanMaxSettings + 1] = tonumber(match) end
  GUI.elms.scansettings_txtDocs_MaxScanDepth:val(scanMaxSettings[1] or 0) 
  GUI.elms.scansettings_txtDocs_MaxScanSubDirs:val(scanMaxSettings[2] or 0)
  FileScanSettings.docs_maxSubDirDepth = scanMaxSettings[1] or 0
  FileScanSettings.docs_maxSubDirRange = scanMaxSettings[2] or 0

  if SWSinstalled then
    GUI.elms.actions_txtFollowAction_NewProject.tooltip = GetActionName(GUI.Val("actions_txtFollowAction_NewProject"))
    GUI.elms.actions_txtFollowAction_NewTab.tooltip = GetActionName(GUI.Val("actions_txtFollowAction_NewTab"))
    GUI.elms.actions_txtFollowAction_LoadProject.tooltip = GetActionName(GUI.Val("actions_txtFollowAction_LoadProject"))
    GUI.elms.actions_txtFollowAction_LoadProjectInTab.tooltip = GetActionName(GUI.Val("actions_txtFollowAction_LoadProjectInTab"))
    GUI.elms.actions_txtFollowAction_LoadProjectTemplate.tooltip = GetActionName(GUI.Val("actions_txtFollowAction_LoadProjectTemplate"))
    GUI.elms.actions_txtFollowAction_InsertTrackTemplate.tooltip =GetActionName(GUI.Val("actions_txtFollowAction_InsertTrackTemplate"))

    GUI.Val("themeslot_max", tonumber(reaper.GetExtState(appname, "themeslot_max")))
    local themeSlots = {}
    for match in string.gmatch(reaper.GetExtState(appname, "themeslot_aliases"), "[^,]+") do themeSlots[#themeSlots + 1] = string.lower(match) end
    for i = 1, 5 do GUI.Val("layout_themeslot_" .. i, themeSlots[i]) end
    ThemeSlot_GetNames()
    RL_Draw_ThemeSlotSelector(0)
  end
 
  if ConfigFlags.enableHiDPIModeOptions then 
    local dpiMode = reaper.GetExtState(appname, "window_hidpimode")
    if dpiMode == "" then dpiMode = 1 end
    GUI.Val("layout_menuRetinaMode", dpiMode)
  end

  local lastOptionFocus = reaper.GetExtState(appname, "window_optionfocus")
  if lastOptionFocus == "" or not tonumber(lastOptionFocus) then lastOptionFocus = 1 end
  TabSelectionIndex[TabID.Options] = tonumber(lastOptionFocus)
  GUI.Val("tab_options_listbox", {[TabSelectionIndex[TabID.Options]] = true})
end

-----------------
-- Save ExtStates
-----------------
function RL_ExtStates_Save()
  GUI.save_window_state(appname)
  reaper.SetExtState(appname, "window_pin", tostring(GUI.Val("main_checklistWindowPin")), 1)
  reaper.SetExtState(appname, "window_scalefactor", tostring(RL.scaleFactor), 1)
  reaper.SetExtState(appname, "window_listboxfontsize", tostring(RL.listboxFontSize), 1)
  reaper.SetExtState(appname, "window_tabfocus", GUI.elms.main_tabs.state, 1)
  reaper.SetExtState(appname, "window_subselection", table.concat(TabParentSelectionIndex, ","), 1)
  reaper.SetExtState(appname, "window_showpaths", tostring(GUI.Val("main_checklistPaths")), 1)
  reaper.SetExtState(appname, "window_showpathsinstatusbar", tostring(GUI.Val("options_checklistShowPathsInStatusbar")), 1)
  reaper.SetExtState(appname, "window_togglemode", tostring(GUI.Val("options_checklistWindowToggle")), 1)
  reaper.SetExtState(appname, "project_showproperties", tostring(GUI.Val("options_checklistOpenPropertiesOnNewProject")), 1)

  local activePanels = {}
  local panelTable = GUI.Val("layout_checklistShowSubfolderPanel")
  for i = 1, #panelTable do activePanels[i] = tostring(panelTable[i]) end
  reaper.SetExtState(appname, "window_showsubfolderpanel", table.concat(activePanels, ","), 1)
  
  reaper.SetExtState(appname, "filter_recentprojects", GUI.Val("tab_recentProjects_txtFilter"), 1)
  reaper.SetExtState(appname, "filter_projecttemplates", GUI.Val("tab_projectTemplates_txtFilter"), 1)
  reaper.SetExtState(appname, "filter_tracktemplates", GUI.Val("tab_trackTemplates_txtFilter"), 1)
  reaper.SetExtState(appname, "filter_projects", GUI.Val("tab_customProjects_txtFilter"), 1)
  reaper.SetExtState(appname, "filter_projectlists", GUI.Val("tab_projectLists_txtFilter"), 1)
  reaper.SetExtState(appname, "filter_backups", GUI.Val("tab_backups_txtFilter"), 1)
  reaper.SetExtState(appname, "filter_docs", GUI.Val("tab_docs_txtFilter"), 1)
  reaper.SetExtState(appname, "filter_favorites", GUI.Val("tab_favorites_txtFilter"), 1)

  if SWSinstalled then
    reaper.SetExtState(appname, "themeslot_max", tostring(GUI.Val("layout_themeslot_number")), 1)
  end
  
  if JSAPIinstalled then 
    reaper.SetExtState(appname, "window_showdate", tostring(GUI.Val("main_checklistDate")), 1)
    
    reaper.SetExtState(appname, "preview_vol", tostring(GUI.Val("main_previewVolKnob")), 1)
    if AudioPreview.channelIndex == nil then AudioPreview.channelIndex = 0 end
    reaper.SetExtState(appname, "preview_channel", AudioPreview.channelIndex, 1)
    reaper.SetExtState(appname, "preview_channelmenuitem", tostring(GUI.Val("main_previewChannels")), 1)
  end
end

----------------
-- Audio Preview
----------------
if JSAPIinstalled then
  local AudioPreviewFileTypes = { ".wav", ".flac", ".mp3", ".ogg" } -- ordered by priority from left to right

  function AudioPreviewToggleState()
    if AudioPreview.active then AudioPreviewStopAll()
    else AudioPreviewStart() end
  end

  function AudioPreviewChangeVolKnobColor(bodyColor, headColor)
    GUI.elms.main_previewVolKnob.col_body = bodyColor
    GUI.elms.main_previewVolKnob.col_head = headColor
    GUI.elms.main_previewVolKnob:init()
    GUI.elms.main_previewVolKnob:redraw(self)

    if headColor == "elm_frame" then GUI.elms.main_previewVolKnob.col_txt = "txt"
    else GUI.elms.main_previewVolKnob.col_txt = headColor end
    GUI.elms.main_previewVolKnob:init()
    
    GUI.elms.main_previewChannels.col_txt = headColor
    GUI.elms.main_previewChannels.col_cap = headColor
    GUI.elms.main_previewChannels:init()
    
    GUI.elms.main_previewStatusLabel.color = headColor
    GUI.elms.main_previewStatusLabel:init()
  end
  
  function IsFilterActive(currentTab)
    if currentTab == TabID.RecentProjects then return FilterActive.RecentProjects
      elseif currentTab == TabID.ProjectTemplates then return FilterActive.ProjectTemplates
      elseif currentTab == TabID.TrackTemplates then return FilterActive.TrackTemplates
      elseif currentTab == TabID.CustomProjects then return FilterActive.CustomProjects
      elseif currentTab == TabID.ProjectLists then return FilterActive.ProjectLists
      elseif currentTab == TabID.Backups then return FilterActive.Backups
      elseif currentTab == TabID.Favorites then return FilterActive.Favorites
    end
  end

function AudioPreviewCheckForFile(currentTab)
    if not ConfigFlags.enableAudioPreview then return end

    if currentTab and currentTab <= TabID.Favorites and currentTab ~= TabID.Docs then 
      local selectedIndex = TabSelectionIndex[currentTab]
      if selectedIndex ~= nil and selectedIndex > 0 then
        local AudioPreviewElements = {}
        if currentTab == TabID.RecentProjects then AudioPreviewElements = { RecentProjects.items, RecentProjects.filteredItems }
          elseif currentTab == TabID.ProjectTemplates then AudioPreviewElements = { ProjectTemplates.items, ProjectTemplates.filteredItems }
          elseif currentTab == TabID.TrackTemplates then AudioPreviewElements = { TrackTemplates.items, TrackTemplates.filteredItems }
          elseif currentTab == TabID.CustomProjects then AudioPreviewElements = { CustomProjects.items, CustomProjects.filteredItems }
          elseif currentTab == TabID.ProjectLists then AudioPreviewElements = { ProjectLists.projectItems, ProjectLists.filteredProjectItems }
          elseif currentTab == TabID.Backups then AudioPreviewElements = { Backups.items, Backups.filteredItems, }
          elseif currentTab == TabID.Favorites then AudioPreviewElements = { Favorites.items, Favorites.filteredItems }
        end

        local selectedPreviewElement = AudioPreviewElements[1][selectedIndex]
        if IsFilterActive(currentTab) then selectedPreviewElement = AudioPreviewElements[2][selectedIndex] end

        if AudioPreviewElements[1][selectedIndex] ~= nil then
          for t = 1, #AudioPreviewFileTypes do
            if selectedPreviewElement == nil then AudioPreview.fileName = "emptyList"
            else
              AudioPreview.fileExtension = AudioPreviewFileTypes[t]
              if selectedPreviewElement.name then
                if IsFilterActive(currentTab) and AudioPreviewElements[2][selectedIndex].path then
                  AudioPreview.fileName = GetDirectoryPath(AudioPreviewElements[2][selectedIndex].path) .. pathSeparator .. selectedPreviewElement.name .. AudioPreview.fileExtension
                else
                  if AudioPreviewElements[1][selectedIndex].path then 
                    AudioPreview.fileName = GetDirectoryPath(AudioPreviewElements[1][selectedIndex].path) .. pathSeparator .. selectedPreviewElement.name .. AudioPreview.fileExtension
                  end
                end
              end
            end
            if AudioPreview.fileName ~= "emptyList" and reaper.file_exists(AudioPreview.fileName) then break end
          end

          AudioPreviewChangeVolKnobColor("none", "elm_frame")
          GUI.elms.main_previewStatusLabel.tooltip = ""

          if reaper.file_exists(AudioPreview.fileName) then
            AudioPreviewChangeVolKnobColor("none", "silver")
            AudioPreview.statusText = selectedPreviewElement.name .. AudioPreview.fileExtension
            GUI.elms.main_previewStatusLabel.tooltip = "Preview file available\n\n" .. AudioPreview.statusText

            if AudioPreview.fileName == AudioPreview.lastPlayed and AudioPreview.active then
              AudioPreviewChangeVolKnobColor("none", "elm_fill")
              GUI.elms.main_previewStatusLabel.tooltip = "Currently playing\n\n" .. AudioPreview.statusText
            end
          end
        end
      end
    end
  end

  function AudioPreviewStart()
    if AudioPreview.fileName ~= nil and reaper.file_exists(AudioPreview.fileName) then
      local previewVol = (GUI.Val("main_previewVolKnob") / 100)
      if previewVol == nil or previewVol > 1 then previewVol = 1 end
  
      reaper.Xen_StopSourcePreview(-1)

      local startOutputChannel = 0
      if AudioPreview.channelIndex ~= nil and AudioPreview.channelIndex > 0 then startOutputChannel = AudioPreview.channelIndex end
      reaper.Xen_StartSourcePreview(reaper.PCM_Source_CreateFromFile(AudioPreview.fileName), previewVol, false, startOutputChannel)
      
      AudioPreview.active = true
      AudioPreview.lastPlayed = AudioPreview.fileName
      AudioPreviewChangeVolKnobColor("none", "elm_fill")
      if AudioPreview.statusText ~= nil then
        MsgStatusBar("Audio Preview started ")
        GUI.elms.main_previewStatusLabel.tooltip = "Currently playing\n\n" .. AudioPreview.statusText
      end
    end
  end

  function AudioPreviewStopAll()
    reaper.Xen_StopSourcePreview(-1)
    AudioPreviewChangeVolKnobColor("none", "elm_frame")
    GUI.elms.main_previewStatusLabel.tooltip = ""
    MsgStatusBar("Audio Preview stopped")

    if AudioPreview.active and AudioPreview.fileName ~= AudioPreview.lastPlayed then AudioPreviewStart()
    elseif AudioPreview.active then AudioPreview.active = false end
  end

end

---------------------
-- Key Input - Tables
---------------------
GUI.chars = {
  ESC = 27,
  RETURN = 13,
  BACKSPACE = 8,
  TAB = 9,
  SPACE = 32,
  -- middle block
  INSERT = 6909555,
  DELETE = 6579564,
  HOME = 1752132965,
  END = 6647396,
  PAGEUP = 1885828464,
  PAGEDOWN = 1885824110,
  UP = 30064,
  DOWN = 1685026670,
  LEFT = 1818584692,
  RIGHT = 1919379572,
  -- operators
  MULTIPLY = 42,
  PLUS = 43,
  MINUS = 45,
  DIVIDE = 47,
  -- numbers
  N0 = 48, 
  N1 = 49,
  N2 = 50,
  N3 = 51,
  N4 = 52,
  N5 = 53,
  N6 = 54,
  N7 = 55,
  N8 = 56,
  N9 = 57, 
  -- characters
  m = 77,
  p = 80,
  s = 83,
  t = 84,
  A = 97,
  C = 99,
  D = 100,
  F = 102,
  I = 105,
  L = 108,
  M = 109,
  N = 110,
  O = 111,
  P = 112,
  Q = 113,
  S = 115,
  T = 116,
  V = 118,
  W = 119,
  X = 120,
  -- function keys
  F1 = 26161,
  F2 = 26162,
  F3 = 26163,
  F4 = 26164,
  F5 = 26165,
  F6 = 26166,
  F7 = 26167,
  F8 = 26168,
  F9 = 26169,
  F10 = 6697264,
  F11 = 6697265,
  F12 = 6697266
}

GUI.modifier = {
  NONE = 0,
  CTRL = 1,
  SHIFT = 2,
  ALT = 3
}

-------------------------------
-- Key Input - Helper functions
-------------------------------
local TabParentListBox = {
  "",
  "tab_projectTemplates_subfolders",
  "tab_trackTemplates_subfolders",
  "tab_customProjects_subfolders",
  "tab_projectLists_listboxRPL",
  "tab_backups_subfolders",
  "tab_docs_subfolders",
  "tab_favorites_categories"
}

local TabListBox = {
  "tab_recentProjects_listbox",
  "tab_projectTemplates_listbox",
  "tab_trackTemplates_listbox",
  "tab_customProjects_listbox",
  "tab_projectLists_listboxProjects",
  "tab_backups_listbox",
  "tab_docs_listbox",
  "tab_favorites_listbox",
  "tab_help_listbox",
  "tab_options_listbox"
}

local TabFilter = {
  GUI.elms.tab_recentProjects_txtFilter,
  GUI.elms.tab_projectTemplates_txtFilter,
  GUI.elms.tab_trackTemplates_txtFilter,
  GUI.elms.tab_customProjects_txtFilter,
  GUI.elms.tab_projectLists_txtFilter,
  GUI.elms.tab_backups_txtFilter,
  GUI.elms.tab_docs_txtFilter,
  GUI.elms.tab_favorites_txtFilter
}

-------------------
-- Listbox elements
-------------------
local function InitListBoxElements()
  ParentListBoxElements = {
    nil,
    GUI.elms.tab_projectTemplates_subfolders,
    GUI.elms.tab_trackTemplates_subfolders,
    GUI.elms.tab_customProjects_subfolders,
    GUI.elms.tab_projectLists_listboxRPL,
    GUI.elms.tab_backups_subfolders,
    GUI.elms.tab_docs_subfolders,
    GUI.elms.tab_favorites_categories,
    GUI.elms.tab_help_listbox,
    GUI.elms.tab_options_listbox
  }

  ListBoxElements = {
    GUI.elms.tab_recentProjects_listbox,
    GUI.elms.tab_projectTemplates_listbox,
    GUI.elms.tab_trackTemplates_listbox,
    GUI.elms.tab_customProjects_listbox,
    GUI.elms.tab_projectLists_listboxProjects,
    GUI.elms.tab_backups_listbox,
    GUI.elms.tab_docs_listbox,
    GUI.elms.tab_favorites_listbox
  }
end
InitListBoxElements()

-----------------
-- Parent listbox
-----------------
function SetParentListBoxIndex(tabIndex, selectedElement)
  GUI.Val(TabParentListBox[tabIndex], {[selectedElement] = true})
  TabParentSelectionIndex[tabIndex] = selectedElement

  if ParentListBoxElements[tabIndex] then
    if tabIndex == TabID.ProjectLists then
      if RL.sortModeIndex[GUI.elms.main_tabs.state] == 2 then UpdateProjectListSelection(true) else UpdateProjectListSelection(false) end
      Filter_ProjectLists_Clear()
    else
      if tabIndex == TabID.ProjectTemplates then
        UpdateProjectTemplateSubDirSelection()
        Filter_ProjectTemplate_Clear()
      elseif tabIndex == TabID.TrackTemplates then
        UpdateTrackTemplateSubDirSelection()
        Filter_TrackTemplate_Clear()
      elseif tabIndex == TabID.CustomProjects then
        UpdateCustomProjectSubDirSelection()
        Filter_CustomProjects_Clear()
      elseif tabIndex == TabID.Backups then
        UpdateBackupsSubDirSelection()
        Filter_Backups_Clear()
      elseif tabIndex == TabID.Docs then
        UpdateDocsSubDirSelection()
        Filter_Docs_Clear()
      elseif tabIndex == TabID.Favorites then
        TabSelectionIndex[TabID.Favorites] = 0
        RL.projectTemplateLoadMode, RL.saveAsNewVersionMode = 1, 0
        FillFavoritesListbox()
        Filter_Favorites_Clear()
      end
    end
  end
  Global_UpdateSortMode()
  ShowFileCount()
end

local function RL_Keys_ListboxSelectPreviousParent(currentTab)
  if TabParentSelectionIndex[currentTab] ~= nil and currentTab > 1 and currentTab <= TabID.Favorites then
    local listIndex = TabParentSelectionIndex[currentTab]
    if listIndex - 1 > 0 then
      listIndex = listIndex - 1
      SetParentListBoxIndex(currentTab, listIndex)
      Scroll(ParentListBoxElements[currentTab], listIndex, -1)
    end
  end
end

local function RL_Keys_ListboxSelectNextParent(currentTab)
  if TabParentSelectionIndex[currentTab] ~= nil and currentTab > 1 and currentTab <= TabID.Favorites then
    if ParentListBoxElements[currentTab] then
      local listIndex = TabParentSelectionIndex[currentTab]
      if listIndex + 1 <= #ParentListBoxElements[currentTab].list then
        listIndex = listIndex + 1
        SetParentListBoxIndex(currentTab, listIndex)
        Scroll(ParentListBoxElements[currentTab], listIndex, 1)
      end
    end
  end
end

---------------
-- Main listbox
---------------
function SetListBoxIndex(tabIndex, selectedElement)
  GUI.Val(TabListBox[tabIndex], {[selectedElement] = true})
  TabSelectionIndex[tabIndex] = selectedElement
  if tabIndex == TabID.Help then RL_Draw_HelpFrames() end
  if tabIndex == TabID.Options then
    reaper.SetExtState(appname, "window_optionfocus", tostring(selectedElement), 1)
    RL_SetFocusedTab(TabID.Help + selectedElement)
  end  
  Global_ShowPathInStatusbar(tabIndex)
  if JSAPIinstalled then AudioPreviewCheckForFile(tabIndex) end
end

function RL_Keys_ListboxSelectPrevious(currentTab)
  if currentTab >= TabID.Options and currentTab <= TabID.Layout and TabSelectionIndex[TabID.Options] ~= nil then
    local listIndex = TabSelectionIndex[TabID.Options]
    if listIndex - 1 > 0 then listIndex = listIndex - 1 end
    SetListBoxIndex(TabID.Options, listIndex)
    Scroll(ListBoxElements[TabID.Options], listIndex, -1)
  else
    if TabSelectionIndex[currentTab] ~= nil and currentTab <= TabID.Layout then 
      local listIndex = TabSelectionIndex[currentTab]
      if listIndex - 1 > 0 then listIndex = listIndex - 1 end
      SetListBoxIndex(currentTab, listIndex)
      Scroll(ListBoxElements[currentTab], listIndex, -1)
    end
  end
end

function RL_Keys_ListboxSelectNext(currentTab)
  if currentTab >= TabID.Options and currentTab <= TabID.Layout and TabSelectionIndex[TabID.Options] ~= nil then
    local listIndex = TabSelectionIndex[TabID.Options]
    if listIndex + 1 <= #GUI.elms.tab_options_listbox.list then listIndex = listIndex + 1 end
    SetListBoxIndex(TabID.Options, listIndex)
    Scroll(ListBoxElements[TabID.Options], listIndex, 1)
  else
    if TabSelectionIndex[currentTab] ~= nil and currentTab <= TabID.Layout then
      local listIndex = TabSelectionIndex[currentTab]
      local ListBoxItems = {
        GUI.elms.tab_recentProjects_listbox.list,
        GUI.elms.tab_projectTemplates_listbox.list,
        GUI.elms.tab_trackTemplates_listbox.list,
        GUI.elms.tab_customProjects_listbox.list,
        GUI.elms.tab_projectLists_listboxProjects.list,
        GUI.elms.tab_backups_listbox.list,
        GUI.elms.tab_docs_listbox.list,
        GUI.elms.tab_favorites_listbox.list,
        GUI.elms.tab_help_listbox.list
      }

    if listIndex + 1 <= #ListBoxItems[currentTab] then listIndex = listIndex + 1 end
      SetListBoxIndex(currentTab, listIndex)
      Scroll(ListBoxElements[currentTab], listIndex, 1)
    end
  end
end

--------------------------------
-- Load/Refresh helper functions
--------------------------------
RL_Func_LoadElement = {
  [TabID.RecentProjects] = { call = function() Load_RecentProject() end },
  [TabID.ProjectTemplates] = { call = function() Load_ProjectTemplate() end },
  [TabID.TrackTemplates] = { call = function() Load_TrackTemplate() end },
  [TabID.CustomProjects] = { call = function() Load_CustomProject() end },
  [TabID.ProjectLists] = { call = function() Load_ProjectListProject() end },
  [TabID.Backups] = { call = function() Load_BackupFile() end },
  [TabID.Docs] = { call = function() Load_DocFile() end },
  [TabID.Favorites] = { call = function() Load_FavoritesFile() end }
}

RL_Func_LoadElementInTab = {
  [TabID.RecentProjects] = { call = function() LoadInTab_RecentProject() end },
  [TabID.ProjectTemplates] = { call = function() LoadInTab_ProjectTemplate() end },
  [TabID.TrackTemplates] = { call = function() Load_TrackTemplateInTab() end },
  [TabID.CustomProjects] = { call = function() LoadInTab_CustomProject() end },
  [TabID.ProjectLists] = { call = function() LoadInTab_ProjectListProject() end },
  [TabID.Backups] = { call = function() LoadInTab_BackupFile() end },
  [TabID.Docs] = { call = function() Load_DocFile() end },
  [TabID.Favorites] = { call = function() LoadInTab_FavoritesFile() end }
}

RL_Func_TabRefresh = {
  [TabID.RecentProjects] = { call = function() RefreshRecentProjects(false) end },
  [TabID.ProjectTemplates] = { call = function() RefreshProjectTemplates() end },
  [TabID.TrackTemplates] = { call = function() RefreshTrackTemplates() end },
  [TabID.CustomProjects] = { call = function() RefreshCustomProjects() end },
  [TabID.ProjectLists] = { call = function() RefreshProjectList() end },
  [TabID.Backups] = { call = function() RefreshBackups() end },
  [TabID.Docs] = { call = function() RefreshDocs() end },
  [TabID.Favorites] = { call = function() RefreshFavorites() end }
}

RL_Func_RebuildCache = {
  [TabID.RecentProjects] = { call = function() RefreshRecentProjects(false) end },
  [TabID.ProjectTemplates] = { call = function() RL.forceRescan = true RefreshProjectTemplates() RL.forceRescan = false end },
  [TabID.TrackTemplates] = { call = function() RL.forceRescan = true RefreshTrackTemplates() RL.forceRescan = false end },
  [TabID.CustomProjects] = { call = function() RL.forceRescan = true RefreshCustomProjects() RL.forceRescan = false end },
  [TabID.ProjectLists] = { call = function() RL.forceRescan = true RefreshProjectList() RL.forceRescan = false end },
  [TabID.Backups] = { call = function() RL.forceRescan = true RefreshBackups() RL.forceRescan = false end },
  [TabID.Docs] = { call = function() RL.forceRescan = true RefreshDocs() RL.forceRescan = false end },
  [TabID.Favorites] = { call = function() RefreshFavorites() end }
}

----------------------------
-- Key Input - Main function
-----------------------------
local function RL_Keys_CheckInput()
  if RL.keyInputActive then
    local inputChar = gfx.getchar()
    local modifier = GUI.modifier.NONE
    if GUI.mouse.cap & 4 == 4 then modifier = GUI.modifier.CTRL
      elseif GUI.mouse.cap & 8 == 8 then modifier = GUI.modifier.SHIFT
      elseif GUI.mouse.cap & 16 == 16 then modifier = GUI.modifier.ALT
    end
    
    if RL.dialogKeyMode then
      if inputChar == GUI.chars.ESC then RL_Dialog_Close()
      elseif inputChar == GUI.chars.RETURN then RL_Dialog_OK() end
    else
      -- if inputChar > 0 then MsgDebug("modifier: " .. modifier .. " | key: " .. inputChar) end
      -- close the window when toggle key is pressed
      if GUI.Val("options_checklistWindowToggle") and RL.windowToggleShortcut ~= nil and (inputChar == RL.windowToggleShortcut or inputChar == (RL.windowToggleShortcut + 32)) then
        SetToggleState(0) gfx.quit() return 0
      -- close the window when ESC key is pressed or close function is called
      elseif inputChar == GUI.chars.ESC or inputChar == -1 or GUI.quit then SetToggleState(0) gfx.quit() return 0
      -- select previous tab
      elseif inputChar == GUI.chars.LEFT and GUI.elms.main_tabs.state > 1 then
          if GUI.elms.main_tabs.state <= TabID.Options then RL_SetFocusedTab(GUI.elms.main_tabs.state - 1) else RL_SetFocusedTab(TabID.Options - 1) end
      -- select next tab
      elseif inputChar == GUI.chars.RIGHT then
          if GUI.elms.main_tabs.state < TabID.Options then RL_SetFocusedTab(GUI.elms.main_tabs.state + 1) end
      -- sub and main listbox selection
      elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.UP then RL_Keys_ListboxSelectPreviousParent(GUI.elms.main_tabs.state)
      elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.UP then RL_Keys_ListboxSelectPrevious(GUI.elms.main_tabs.state)
      elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.DOWN then RL_Keys_ListboxSelectNextParent(GUI.elms.main_tabs.state)
      elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.DOWN then RL_Keys_ListboxSelectNext(GUI.elms.main_tabs.state)
      elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.HOME and GUI.elms.main_tabs.state > 1 and GUI.elms.main_tabs.state <= TabID.Favorites then
          SetParentListBoxIndex(GUI.elms.main_tabs.state, 1)
          ScrollToTop(ParentListBoxElements[GUI.elms.main_tabs.state])
      elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.HOME and GUI.elms.main_tabs.state <= TabID.Favorites then
          SetListBoxIndex(GUI.elms.main_tabs.state, 1)
          ScrollToTop(ListBoxElements[GUI.elms.main_tabs.state])
      elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.END and GUI.elms.main_tabs.state > 1 and GUI.elms.main_tabs.state <= TabID.Favorites then
          SetParentListBoxIndex(GUI.elms.main_tabs.state, GetSubListSize())
          ScrollToBottom(ParentListBoxElements[GUI.elms.main_tabs.state])
      elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.END and GUI.elms.main_tabs.state <= TabID.Favorites then
          SetListBoxIndex(GUI.elms.main_tabs.state, GetMainListSize())
          ScrollToBottom(ListBoxElements[GUI.elms.main_tabs.state])
        -- refresh current tab
      elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.F5 and GUI.elms.main_tabs.state <= TabID.Favorites then RL_Func_TabRefresh[GUI.elms.main_tabs.state].call()
      elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.F5 and GUI.elms.main_tabs.state <= TabID.Favorites then RebuildCache()
      -- set focus to filter
      elseif inputChar == GUI.chars.TAB then
          if GUI.elms.main_tabs.state <= TabID.Favorites then
            RL.keyInputActive = false
            TabFilter[GUI.elms.main_tabs.state].focus = true
          end
      -- clear filter
      elseif inputChar == GUI.chars.BACKSPACE then RL_Keys_ClearFilter()
      -- keep window open
      elseif inputChar == GUI.chars.W then 
          if GUI.Val("main_checklistWindowPin") then GUI.Val("main_checklistWindowPin", {false}) else GUI.Val("main_checklistWindowPin", {true}) end
      -- global buttons
      elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.s then Global_CycleSortMode(true)
      elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.S then Global_CycleSortMode(false)
      elseif inputChar == GUI.chars.L and GUI.elms.main_tabs.state <= TabID.Favorites then Global_OpenInExplorer() 
      elseif inputChar == GUI.chars.O then Global_ShowProjectOpenDialog() 
      elseif inputChar == GUI.chars.N then Global_NewProject()
      elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.t or inputChar == GUI.chars.DIVIDE then Global_NewTabIgnoreDefaultTemplate()
      elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.T or inputChar == GUI.chars.PLUS then Global_NewTab() 
      -- toggle path display in sub listbox
      elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.p then
        RL.showSubFolderPaths = not RL.showSubFolderPaths
        Global_UpdateSubfolderPathDisplay()
      -- toggle path display in main listbox
      elseif inputChar == GUI.chars.P then
        if GUI.Val("main_checklistPaths") then GUI.Val("main_checklistPaths", {false}) else GUI.Val("main_checklistPaths", {true}) end
        Global_UpdateListDisplay()
      -- select previous/next project tab
      elseif inputChar == GUI.chars.X then reaper.Main_OnCommand(40862, 0) -- select previous tab
      elseif inputChar == GUI.chars.V then reaper.Main_OnCommand(40861, 0) -- select next tab
      -- close current tab
      elseif inputChar == GUI.chars.C or inputChar == GUI.chars.MINUS then
          reaper.Main_OnCommand(40860, 0)
          Global_CheckWindowPinState()
      -- load (in tab)
      elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.RETURN and GUI.elms.main_tabs.state <= TabID.Favorites then RL_Func_LoadElementInTab[GUI.elms.main_tabs.state].call()
      elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.RETURN and GUI.elms.main_tabs.state <= TabID.Favorites then RL_Func_LoadElement[GUI.elms.main_tabs.state].call()
      -- scaling functions
      elseif inputChar == GUI.chars.F8 then RL_ScaleListboxFontSizeDown()
      elseif inputChar == GUI.chars.F9 then RL_ScaleListboxFontSizeUp()
      elseif inputChar == GUI.chars.F10 then RL_ScaleInterfaceToggle()
      elseif inputChar == GUI.chars.F11 then RL_ScaleInterfaceDown()
      elseif inputChar == GUI.chars.F12 then RL_ScaleInterfaceUp()
      -- main tabs
      elseif inputChar == GUI.chars.N0 then RL_SetFocusedTab(TabID.Favorites)
      elseif inputChar == GUI.chars.N1 then RL_SetFocusedTab(TabID.RecentProjects)
      elseif inputChar == GUI.chars.N2 then RL_SetFocusedTab(TabID.ProjectTemplates)
      elseif inputChar == GUI.chars.N3 then RL_SetFocusedTab(TabID.TrackTemplates) 
      elseif inputChar == GUI.chars.N4 then RL_SetFocusedTab(TabID.CustomProjects)
      elseif inputChar == GUI.chars.N5 then RL_SetFocusedTab(TabID.ProjectLists)
      elseif inputChar == GUI.chars.N6 then RL_SetFocusedTab(TabID.Backups)
      elseif inputChar == GUI.chars.N7 then RL_SetFocusedTab(TabID.Docs)
      -- option tabs
      elseif inputChar == GUI.chars.F1 then RL_SetFocusedTab(TabID.Help)
      elseif inputChar == GUI.chars.F2 then GUI.Val("tab_options_listbox", {[1] = true}) TabSelectionIndex[TabID.Options] = 1 RL_SetFocusedTab(TabID.Options)
      elseif inputChar == GUI.chars.F3 then RL_SetFocusedTab(TabID.Favorites)
      -- favorites
      elseif inputChar == GUI.chars.F then if GUI.elms.main_tabs.state == TabID.Favorites then RL_ConfirmDialog_RemoveFavoritesEntry() else Favorites_Add() end
      -- tooltips
      elseif inputChar == GUI.chars.I then RL_ToggleTooltips()
      -- context menus
      elseif inputChar == GUI.chars.A and SWSinstalled then RL_Context_LastActiveProjects()
      elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.M then RL_Context_Main_Relay()
      elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.m then 
          if GUI.elms.main_tabs.state == TabID.RecentProjects and SWSinstalled then RL_Context_RecentProjects()
          elseif GUI.elms.main_tabs.state == TabID.Favorites then RL_Context_Favorites() end
      end
      -- audio preview
      if JSAPIinstalled and ConfigFlags.enableAudioPreview then
        if inputChar == GUI.chars.SPACE or inputChar == GUI.chars.MULTIPLY then AudioPreviewToggleState() 
        elseif inputChar == GUI.chars.D then 
          if GUI.Val("main_checklistDate") then GUI.Val("main_checklistDate", {false}) else GUI.Val("main_checklistDate", {true}) end
          Global_UpdateListDisplay()
        end
      end
    end
  end
  reaper.defer(RL_Keys_CheckInput)
end

--------------------------
-- Resize/Redraw functions
--------------------------
function RL_RedrawUI()
  RL_SetWindowParameters()
  RL_RedrawAll()
  RL_SetListBoxFontSize()
  RL_ExtStates_Load("onUpdate")
  Global_UpdateSubfolderPathDisplay()
end

----------------------------
-- listbox font size scaling
----------------------------
function RL_ScaleListboxFontSize()
  local fonts = GUI.get_OS_fonts()
  for p = 1, #ParentListBoxElements do
    if (ShowSubfolderPanel(p) or p == #ParentListBoxElements) and ParentListBoxElements[p] ~= nil and p < TabID.Options then
      ParentListBoxElements[p].font_b = {fonts.sans, RL.listboxFontSize * RL.scaleFactor}
      ParentListBoxElements[p]:wnd_recalc()
      ParentListBoxElements[p]:redraw()
    end
  end
  for l = 1, #ListBoxElements do
    ListBoxElements[l].font_b = {fonts.sans, RL.listboxFontSize * RL.scaleFactor}
    ListBoxElements[l]:wnd_recalc()
    ListBoxElements[l]:redraw()
  end
end

function RL_ScaleListboxFontSizeDown()
  if (RL.listboxFontSize - 2) > 10 then
    RL.listboxFontSize = RL.listboxFontSize - 2
    reaper.SetExtState(appname, "window_listboxfontsize", tostring(RL.listboxFontSize), 1)
    RL_ScaleListboxFontSize()
  end
end

function RL_ScaleListboxFontSizeUp()
  if (RL.listboxFontSize + 2) < 36 then
    RL.listboxFontSize = RL.listboxFontSize + 2
    reaper.SetExtState(appname, "window_listboxfontsize", tostring(RL.listboxFontSize), 1)
    RL_ScaleListboxFontSize()
  end
end

function RL_SetListBoxFontSize()
  InitListBoxElements()
  local storedFontSize = tonumber(reaper.GetExtState(appname, "window_listboxfontsize"))
  if storedFontSize ~= nil and storedFontSize > 0 then
    RL.listboxFontSize = storedFontSize
    RL_ScaleListboxFontSize()
  end
end

RL_SetListBoxFontSize()

-------------------------
-- Resize/Scale functions
-------------------------
local function RL_ResizeScaledWidth(wx, wy)
  GUI.w = (RL.minWidth * RL.scaleFactor) - (50 * RL.scaleFactor)
  gfx.quit()
  if RL.retinaMode == 1 then gfx.init("", 0.5 * GUI.w, 0.5 * GUI.h, 0, wx, wy) else gfx.init("", GUI.w, GUI.h, 0, wx, wy) end
  GUI.redraw_z[0] = true 
end

local function RL_ResizeScaledHeight(wx, wy)
  GUI.h = ((RL.minHeight - 80) * RL.scaleFactor) + (50 * RL.scaleFactor)
  gfx.quit()
  if RL.retinaMode == 1 then gfx.init("", 0.5 * GUI.w, 0.5 * GUI.h, 0, wx, wy) else gfx.init("", GUI.w, GUI.h, 0, wx, wy) end
  GUI.redraw_z[0] = true 
end

local function RL_ResizeWidth(wx, wy)
  GUI.w = RL.minWidth
  gfx.quit()
  if RL.retinaMode == 1 then gfx.init("", 0.5 * GUI.w, 0.5 * GUI.h, 0, wx, wy) else gfx.init("", GUI.w, GUI.h, 0, wx, wy) end
  GUI.redraw_z[0] = true 
end

local function RL_ResizeHeight(wx, wy)
  GUI.h = RL.minHeight
  gfx.quit()
  if RL.retinaMode == 1 then gfx.init("", 0.5 * GUI.w, 0.5 * GUI.h, 0, wx, wy) else gfx.init("", GUI.w, GUI.h, 0, wx, wy) end
  GUI.redraw_z[0] = true 
end

local function RL_ScaleWindowUp()
  local _, wx, wy, ww, wh = gfx.dock(-1, 0, 0, 0, 0)
  GUI.w, GUI.h = ww, wh
  RL_RedrawUI()

  if RL.scaleFactor > 1 then 
    if GUI.w < (RL.minWidth * RL.scaleFactor) + (50 * RL.scaleFactor) then RL_ResizeScaledWidth(wx, wy) end
    if GUI.h < ((RL.minHeight - 100) * RL.scaleFactor) + (50 * RL.scaleFactor) then RL_ResizeScaledHeight(wx, wy) end
  else
    if GUI.w < RL.minWidth then RL_ResizeWidth(wx, wy) end
    if GUI.h < RL.minHeight then RL_ResizeHeight(wx, wy) end
  end
end

local function RL_ScaleWindowDown()
  local _, wx, wy, ww, wh = gfx.dock(-1, 0, 0, 0, 0)
  GUI.w, GUI.h = ww, wh
  RL_RedrawUI()

  if RL.scaleFactor > 1 then 
    if GUI.w > (RL.minWidth * RL.scaleFactor) + (50 * RL.scaleFactor) then RL_ResizeScaledWidth(wx, wy) end
    if GUI.h > ((RL.minHeight - 100) * RL.scaleFactor) + (50 * RL.scaleFactor) then RL_ResizeScaledHeight(wx, wy) end
  else
    if GUI.w > RL.minWidth then RL_ResizeWidth(wx, wy) end
    if GUI.h > RL.minHeight then RL_ResizeHeight(wx, wy) end
  end
end

function RL_ScaleInterfaceToggle()
  RL.fontSizes = { 30, 18, 14, 14, 14, 12 } -- default values
  RL.skipOperationOnResize = true
  RL_ExtStates_Save()
  if RL.scaleFactor < 1.5 then
    RL_InitElementScaling(2.0)
    RL_ScaleWindowUp()
  else
    RL_InitElementScaling(1.0)
    RL_ScaleWindowDown()
  end
  RL.skipOperationOnResize = false
end

function RL_ScaleInterfaceUp()
  RL.skipOperationOnResize = true
  if (RL.scaleFactor + RL.scaleStepSize) <= RL.scaleMax then
    RL_InitElementScaling(RL.scaleFactor + RL.scaleStepSize) 
    RL_ExtStates_Save()
    RL_ScaleWindowUp()
  end
  RL.skipOperationOnResize = false
end

function RL_ScaleInterfaceDown()
  RL.skipOperationOnResize = true
  if (RL.scaleFactor - RL.scaleStepSize) >= RL.scaleMin then
    RL_InitElementScaling(RL.scaleFactor - RL.scaleStepSize)
    RL_ExtStates_Save()
    RL_ScaleWindowDown()
  end
  RL.skipOperationOnResize = false
end

function SetToggleState(toggleState)
  local _, _, sectionID, commandID, _, _, _ = reaper.get_action_context()
  reaper.SetToggleCommandState(sectionID, commandID, toggleState)
  reaper.RefreshToolbar2(sectionID, commandID)
end

function Global_Redraw()
  RL_ExtStates_Save()
  local _, wx, wy, ww, wh = gfx.dock(-1, 0, 0, 0, 0)
  local retinaAdjustment = 1.0
  if RL.retinaMode == 1 then retinaAdjustment = 2.0 end
  GUI.w, GUI.h = ww * retinaAdjustment, wh * retinaAdjustment
  RL_RedrawUI()
  if RL.scaleFactor > 1.0 then
    if GUI.w * retinaAdjustment < (((RL.minWidth - 20) * RL.scaleFactor) - (50 * RL.scaleFactor)) * retinaAdjustment then RL_ResizeScaledWidth(wx, wy) end
    if GUI.h * retinaAdjustment < (((RL.minHeight - 80) * RL.scaleFactor) + (50 * RL.scaleFactor)) * retinaAdjustment then RL_ResizeScaledHeight(wx, wy) end
  else
    if GUI.w * retinaAdjustment < RL.minWidth then RL_ResizeWidth(wx, wy) end
    if GUI.h * retinaAdjustment < RL.minHeight then RL_ResizeHeight(wy, wy) end
  end
end

GUI.onresize = Global_Redraw

function SetRetinaMode()
  if ConfigFlags.enableHiDPIModeOptions then
    local retinaMode = GUI.Val("layout_menuRetinaMode")
    if retinaMode == 1 then
      _, dpi = reaper.ThemeLayout_GetLayout("mcp", -3)
      if dpi == "512" then gfx.ext_retina, RL.retinaMode = 1, 1 else gfx.ext_retina, RL.retinaMode = 0, 0 end
    elseif retinaMode == 2 then gfx.ext_retina, RL.retinaMode = 0, 0
    elseif retinaMode == 3 then gfx.ext_retina, RL.retinaMode = 1, 1 end
  else
    gfx.ext_retina, RL.retinaMode = 0, 0
  end
end

--------------------
-- Cleanup functions
--------------------
reaper.atexit(function ()
  SetToggleState(0)
  RL_ExtStates_Save()
  if JSAPIinstalled and ConfigFlags.enableAudioPreview then AudioPreviewStopAll() end
end)

-----------------
-- Main functions
-----------------
GUI.Init()
RL_InitCustomColors()
RL_ExtStates_Load("onStart")
SetRetinaMode()
SetToggleState(1)
if ConfigFlags.enableKeyShortcuts then RL_Keys_CheckInput() end

GUI.func = Main
GUI.freq = 0
GUI.Main()

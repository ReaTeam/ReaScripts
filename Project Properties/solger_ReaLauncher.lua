-- @description ReaLauncher
-- @author solger
-- @version 2.4.1
-- @changelog
--   + Bugfix: Added check for empty lists in the Favorites tab to prevent a possible crash
--   + Bugfix: The script was not terminated properly on exit
--   + UI: The Main (button) Panel on the right wasn't visible by default (visibility of this panel can be toggled on/off in the [Layout / Colors] tab)
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
--     - Sort options
--     - [Favorites] tab to list and manage bookmarked favorites of each tab
--     - [Follow Actions] tab to set Actions that are triggered after certain operations (New Tab, Load Project, etc.)
--     - Global main panel (or main context menu if panel is hidden) for [Locate in Explorer/Finder], [Open Project], [New Project], [New Tab], [Load in Tab], [Load] and [Insert] functions
--     - Selection and loading of multiple entries at once (multi-select via mouse is already part of Lokasenna's GUI library)
--     - 'Keep open' checkbox to toggle the automatic window closing behavior after Load/New/Insert operations
--     - Scalable and resizeable window
--     - Customizable colors
--
--   ## Features that require SWS Extensions (2.9.8 or higher):
--     - [Docs] tab for listing .pdf files
--     - [Recent Projects] tab for listing and managing recent project entries (with functions to remove selected entries and to clear the entire list)
--     - [Locate in Explorer/Finder] button to navigate to the location(s) of selected files in Explorer or Finder
--     - Setup of predefined Reaper Theme Slots and the possibility to switch between them (uses SWS Resources)
--
--   ## Features that require js_ReaScriptAPI (0.991 or higher):
--     - Function to preview attached 'demo' audio files (supported file extensions: .wav, .flac, .mp3 and .ogg)
--     - Option for adding folder paths in the [Options] tab via a 'Browse' dialog (besides copy & pasting paths manually)
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
  enableAutoRefresh = true,           -- skips the automatic refresh in all tabs      (true | false)
  setfirstTabToLoad = 0,              -- the id of the tab that is focused at launch  (0 = last tab)
----------------------------------------------------------------------------------------------------
  enableFileCaching = true,           -- enables/disables file caching                (true | false)
  enableSubfolderCaching = true,      -- enables/disables subfolder caching           (true | false)
  enableEmptySubfolderFilter = true,  -- enables/disables subfolder filter            (true | false)
----------------------------------------------------------------------------------------------------
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
    reaper.MB("Couldn't load the Lokasenna_GUI library.\n\n1) Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack\n\n2) Then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List", "Whoops!", 0)
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
else
  trackTemplatePath = resourcePath .. "/TrackTemplates"
  projectTemplatePath = resourcePath .. "/ProjectTemplates"
end

MsgDebug("Lokasenna_GUI:\t\t" .. (GUI.version or "v2.x"))

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
  if not reaper.ReaPack_GetOwner then
    MsgDebug("JS_ReascriptAPI:\t\t not found")
  else
    local owner
    if osversion:find("Win") and bitversion == "x64" then owner = reaper.ReaPack_GetOwner("UserPlugins/reaper_js_ReaScriptAPI64.dll") -- Windows 64-bit
      elseif osversion:find("Win") then owner = reaper.ReaPack_GetOwner("UserPlugins/reaper_js_ReaScriptAPI32.dll") -- Windows 32-bit
      elseif osversion:find("arm") then owner = reaper.ReaPack_GetOwner("UserPlugins/reaper_js_ReaScriptAPI64ARM.dylib") -- macOS ARM
      elseif osversion:find("OSX") then owner = reaper.ReaPack_GetOwner("UserPlugins/reaper_js_ReaScriptAPI64.dylib") -- macOS
      else owner = reaper.ReaPack_GetOwner("UserPlugins/reaper_js_ReaScriptAPI64.so") -- Linux
    end
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

local function GetPathSeparator()
  if osversion:find("Win") then return "\\" else return "/" end
end

local function GetFolderName(filepath)
  local index = (filepath:reverse()):find("%\\") or (filepath:reverse()):find("%/")
  if index ~= nil then return string.sub(filepath, (#filepath - index) + 2, #filepath)
  else return filepath end
end

local function IsNotNullOrEmpty(str)
  return str ~= nil and str ~= ""
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
            local tmpPath = GetFiles(path .. GetPathSeparator() .. pathChild, folderExclusionIndex, fileExtensionFilter, pathChildIndex)
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
          tree[#tree + 1] = path .. GetPathSeparator() .. fileFound
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
            local tmpPath, _ = GetSubFolders(path .. GetPathSeparator() .. subDirChild, folderExclusionIndex, extensionFilter)
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
          if FolderContainsRelevantFiles(path .. GetPathSeparator() .. subfolderFound, extensionFilter) then
            subDirTree[#subDirTree + 1] = path .. GetPathSeparator() .. subfolderFound
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
    elseif GUI.elms.main_tabs.state == TabID.ProjectLists then return #GUI.elms.tab_projectLists_listboxRPL.list
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
        else reaper.CF_LocateInExplorer(ProjectLists.projectPaths[vals[p]]) end
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

local function Global_UpdateSubfolderPathDisplayMode()
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
  if tabIndex == nil then tabIndex = 1 end
  GUI.Val("main_tabs", tabIndex)
  GUI.Val("main_menuTabSelector", tabIndex)
  GUI.Val("main_checklistSaveAsNewVersion", {false})
  GUI.Val("tab_favorites_checklistSaveAsNewVersion", {false})
  GUI.elms.main_statusbar.tooltip = ""
  MsgStatusBar("")

  RL.projectTemplateLoadMode, RL.saveAsNewVersionMode = 1, 0
  for i = 1, #ListBoxElements do ListBoxElements[i].list = {} end
  if tabIndex == TabID.Layout then MsgStatusBar("Panel and HiDPI Mode changes require a restart") end

  if ConfigFlags.enableSortModeOptions then
    if tabIndex == TabID.RecentProjects then GUI.elms.main_sortMode.optarray = {"Newest", "Oldest", "A - Z", "Z - A"}
    else GUI.elms.main_sortMode.optarray = {"A - Z", "Z - A"} end
  end

  RL.forceRescan = false
  if ConfigFlags.enableAutoRefresh and not RL.skipOperationOnResize and tabIndex <= TabID.Favorites then
    RL_Func_TabRefresh[tabIndex].call()
    Global_UpdateSortMode()
    Global_UpdateSubfolderPathDisplayMode()
    Global_UpdatePathDisplayMode()
  end
end

local function UpdatePathDisplay_RecentProjects(showPaths)
  if showPaths then
    if FilterActive.RecentProjects then GUI.elms.tab_recentProjects_listbox.list = RecentProjects.filteredPaths
    else GUI.elms.tab_recentProjects_listbox.list = RecentProjects.paths end
  else
    if FilterActive.RecentProjects then GUI.elms.tab_recentProjects_listbox.list = RecentProjects.filteredNames
    else GUI.elms.tab_recentProjects_listbox.list = RecentProjects.names end
  end
  GUI.elms.tab_recentProjects_listbox:redraw()
end

local function UpdatePathDisplay_ProjectTemplates(showPaths)
  if showPaths then
    if FilterActive.ProjectTemplates then GUI.elms.tab_projectTemplates_listbox.list = ProjectTemplates.filteredPaths
    else GUI.elms.tab_projectTemplates_listbox.list = ProjectTemplates.paths end
  else
    if FilterActive.ProjectTemplates then GUI.elms.tab_projectTemplates_listbox.list = ProjectTemplates.filteredNames
    else GUI.elms.tab_projectTemplates_listbox.list = ProjectTemplates.names end
  end
  GUI.elms.tab_projectTemplates_listbox:redraw()
end

local function UpdatePathDisplay_TrackTemplates(showPaths)
  if showPaths then
    if FilterActive.TrackTemplates then GUI.elms.tab_trackTemplates_listbox.list = TrackTemplates.filteredPaths
    else GUI.elms.tab_trackTemplates_listbox.list = TrackTemplates.paths end
  else
    if FilterActive.TrackTemplates then GUI.elms.tab_trackTemplates_listbox.list = TrackTemplates.filteredNames
    else GUI.elms.tab_trackTemplates_listbox.list = TrackTemplates.names end
  end
  GUI.elms.tab_trackTemplates_listbox:redraw()
end

local function UpdatePathDisplay_CustomProjects(showPaths)
  if showPaths then
    if FilterActive.CustomProjects then GUI.elms.tab_customProjects_listbox.list = CustomProjects.filteredPaths
    else GUI.elms.tab_customProjects_listbox.list = CustomProjects.paths end
  else
    if FilterActive.CustomProjects then GUI.elms.tab_customProjects_listbox.list = CustomProjects.filteredNames
    else GUI.elms.tab_customProjects_listbox.list = CustomProjects.names end
  end
  GUI.elms.tab_customProjects_listbox:redraw()
end

local function UpdatePathDisplay_ProjectLists(showPaths)
  if showPaths then
    if FilterActive.ProjectLists then GUI.elms.tab_projectLists_listboxProjects.list = ProjectLists.filteredProjectPaths
    else GUI.elms.tab_projectLists_listboxProjects.list = ProjectLists.projectPaths end
  else
    if FilterActive.ProjectLists then GUI.elms.tab_projectLists_listboxProjects.list = ProjectLists.filteredProjectNames
    else GUI.elms.tab_projectLists_listboxProjects.list = ProjectLists.projectNames end
  end
  GUI.elms.tab_projectLists_listboxProjects:redraw()
end

local function UpdatePathDisplay_Backups(showPaths)
  if showPaths then
    if FilterActive.Backups then GUI.elms.tab_backups_listbox.list = Backups.filteredPaths
    else GUI.elms.tab_backups_listbox.list = Backups.paths end
  else
    if FilterActive.Backups then GUI.elms.tab_backups_listbox.list = Backups.filteredNames
    else GUI.elms.tab_backups_listbox.list = Backups.names end
  end
  GUI.elms.tab_backups_listbox:redraw()
end

local function UpdatePathDisplay_Docs(showPaths)
  if showPaths then
    if FilterActive.Docs then GUI.elms.tab_docs_listbox.list = Docs.filteredPaths
    else GUI.elms.tab_docs_listbox.list = Docs.paths end
  else
    if FilterActive.Docs then GUI.elms.tab_docs_listbox.list = Docs.filteredNames
    else GUI.elms.tab_docs_listbox.list = Docs.names end
  end
  GUI.elms.tab_docs_listbox:redraw()
end

local function UpdatePathDisplay_Favorites(showPaths)
  if showPaths then
    if FilterActive.Favorites then GUI.elms.tab_favorites_listbox.list = Favorites.filteredPaths
    else GUI.elms.tab_favorites_listbox.list = Favorites.paths end
  else
    if FilterActive.Favorites then GUI.elms.tab_favorites_listbox.list = Favorites.filteredNames
    else GUI.elms.tab_favorites_listbox.list = Favorites.names end
  end
  GUI.elms.tab_favorites_listbox:redraw()
end

function Global_UpdatePathDisplayMode()
  RL.showFullPaths = GUI.Val("main_checklistPaths")
  UpdatePathDisplay_RecentProjects(RL.showFullPaths)
  UpdatePathDisplay_ProjectTemplates(RL.showFullPaths)
  UpdatePathDisplay_TrackTemplates(RL.showFullPaths)
  UpdatePathDisplay_CustomProjects(RL.showFullPaths)
  UpdatePathDisplay_ProjectLists(RL.showFullPaths)
  UpdatePathDisplay_Backups(RL.showFullPaths)
  UpdatePathDisplay_Docs(RL.showFullPaths)
  UpdatePathDisplay_Favorites(RL.showFullPaths)
end

-----------------
-- Sort functions
-----------------
function Global_CycleSortMode()
  if ConfigFlags.enableSortModeOptions then 
    local sortMode = GUI.Val("main_sortMode")
    if GUI.elms.main_tabs.state == TabID.RecentProjects then
      if sortMode + 1 <= 4 then
        GUI.Val("main_sortMode", sortMode + 1)
        RL.sortModeIndex[GUI.elms.main_tabs.state] = sortMode + 1
      else  
        GUI.Val("main_sortMode", 1)
        RL.sortModeIndex[GUI.elms.main_tabs.state] = 1
      end
    elseif GUI.elms.main_tabs.state <= TabID.Favorites then
      if sortMode == 2 then
        GUI.Val("main_sortMode", 1)
        RL.sortModeIndex[GUI.elms.main_tabs.state] = 1
      else
        GUI.Val("main_sortMode", 2)
        RL.sortModeIndex[GUI.elms.main_tabs.state] = 2
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
      if sortMode == 1 then RL_Func_TabRefresh[GUI.elms.main_tabs.state].call()
      elseif sortMode == 2 then RefreshRecentProjectsReversed()
      else
        if FilterActive.RecentProjects then Sort_Alphabetically(GUI.elms.main_tabs.state, RecentProjects.filteredItems, sortMode, true)
        else Sort_Alphabetically(GUI.elms.main_tabs.state, RecentProjects.items, sortMode, false) end
        GUI.elms.tab_recentProjects_listbox:redraw()
      end
    else
      -- project templates
      if GUI.elms.main_tabs.state == TabID.ProjectTemplates then
        if FilterActive.ProjectTemplates then Sort_Alphabetically(GUI.elms.main_tabs.state, ProjectTemplates.filteredItems, sortMode, true)
        else Sort_Alphabetically(GUI.elms.main_tabs.state, ProjectTemplates.items, sortMode, false) end
        GUI.elms.tab_projectTemplates_listbox:redraw()
      -- track templates
      elseif GUI.elms.main_tabs.state == TabID.TrackTemplates then
        if FilterActive.TrackTemplates then Sort_Alphabetically(GUI.elms.main_tabs.state, TrackTemplates.filteredItems, sortMode, true)
        else Sort_Alphabetically(GUI.elms.main_tabs.state, TrackTemplates.items, sortMode, false) end
        GUI.elms.tab_trackTemplates_listbox:redraw()
      -- projects
      elseif GUI.elms.main_tabs.state == TabID.CustomProjects then
        if FilterActive.CustomProjects then Sort_Alphabetically(GUI.elms.main_tabs.state, CustomProjects.filteredItems, sortMode, true)
        else Sort_Alphabetically(GUI.elms.main_tabs.state, CustomProjects.items, sortMode, false) end
        GUI.elms.tab_customProjects_listbox:redraw()
      -- project lists
      elseif GUI.elms.main_tabs.state == TabID.ProjectLists then
        if FilterActive.ProjectLists then Sort_Alphabetically(GUI.elms.main_tabs.state, ProjectLists.filteredProjectItems, sortMode, true)
        else Sort_Alphabetically(GUI.elms.main_tabs.state, ProjectLists.projectItems, sortMode, false) end
        GUI.elms.tab_projectLists_listboxProjects:redraw()
      -- backups
      elseif GUI.elms.main_tabs.state == TabID.Backups then
        if FilterActive.Backups then Sort_Alphabetically(GUI.elms.main_tabs.state, Backups.filteredItems, sortMode, true)
        else Sort_Alphabetically(GUI.elms.main_tabs.state, Backups.items, sortMode, false) end
        GUI.elms.tab_backups_listbox:redraw()
      -- docs
      elseif GUI.elms.main_tabs.state == TabID.Docs then
        if FilterActive.Docs then Sort_Alphabetically(GUI.elms.main_tabs.state, Docs.filteredItems, sortMode, true)
        else Sort_Alphabetically(GUI.elms.main_tabs.state, Docs.items, sortMode, false) end
        GUI.elms.tab_docs_listbox:redraw()
      -- favorites
      elseif GUI.elms.main_tabs.state == TabID.Favorites then
        if FilterActive.Favorites then Sort_Alphabetically(GUI.elms.main_tabs.state, Favorites.filteredItems, sortMode, true)
        else Sort_Alphabetically(GUI.elms.main_tabs.state, Favorites.items, sortMode, false) end
        GUI.elms.tab_favorites_listbox:redraw()
      end
    end
    reaper.SetExtState(appname, "window_sortmode", table.concat(RL.sortModeIndex, ","), 1)
    if JSAPIinstalled then AudioPreviewCheckForFile(GUI.elms.main_tabs.state) end
  end
end

function Sort_Alphabetically(tabfocus, tableToSort, sortMode, isFiltered)
  if (tabfocus == TabID.RecentProjects and sortMode == 3) or (tabfocus > TabID.RecentProjects and sortMode == 1) then
    table.sort(tableToSort, function(a, b) return a.name:lower() < b.name:lower() end) -- sort ascending
  elseif (tabfocus == TabID.RecentProjects and sortMode == 4) or (tabfocus > TabID.RecentProjects and sortMode == 2) then
    table.sort(tableToSort, function(a, b) return b.name:lower() < a.name:lower() end) -- sort descending
  end

  for i = 1, #tableToSort do
    if tabfocus == TabID.RecentProjects then
      if isFiltered then
        RecentProjects.filteredNames[i] = RecentProjects.filteredItems[i].name
        RecentProjects.filteredPaths[i] = RecentProjects.filteredItems[i].path
      else
        RecentProjects.names[i] = RecentProjects.items[i].name
        RecentProjects.paths[i] = RecentProjects.items[i].path
      end

    elseif tabfocus == TabID.ProjectTemplates then
      if isFiltered then
        ProjectTemplates.filteredNames[i] = ProjectTemplates.filteredItems[i].name
        ProjectTemplates.filteredPaths[i] = ProjectTemplates.filteredItems[i].path
      else
        ProjectTemplates.names[i] = ProjectTemplates.items[i].name
        ProjectTemplates.paths[i] = ProjectTemplates.items[i].path
      end

    elseif tabfocus == TabID.TrackTemplates then
      if isFiltered then
        TrackTemplates.filteredNames[i] = TrackTemplates.filteredItems[i].name
        TrackTemplates.filteredPaths[i] = TrackTemplates.filteredItems[i].path
      else
        TrackTemplates.names[i] = TrackTemplates.items[i].name
        TrackTemplates.paths[i] = TrackTemplates.items[i].path
      end

    elseif tabfocus == TabID.CustomProjects then
      if isFiltered then
        CustomProjects.filteredNames[i] = CustomProjects.filteredItems[i].name
        CustomProjects.filteredPaths[i] = CustomProjects.filteredItems[i].path
      else
        CustomProjects.names[i] = CustomProjects.items[i].name
        CustomProjects.paths[i] = CustomProjects.items[i].path
      end

    elseif tabfocus == TabID.ProjectLists then
      if isFiltered then
        ProjectLists.filteredProjectNames[i] = ProjectLists.filteredProjectItems[i].name
        ProjectLists.filteredProjectPaths[i] = ProjectLists.filteredProjectItems[i].path
      else
        ProjectLists.projectNames[i] = ProjectLists.projectItems[i].name
        ProjectLists.projectPaths[i] = ProjectLists.projectItems[i].path
      end

    elseif tabfocus == TabID.Backups then
      if isFiltered then
        Backups.filteredNames[i] = Backups.filteredItems[i].name
        Backups.filteredPaths[i] = Backups.filteredItems[i].path
      else
        Backups.names[i] = Backups.items[i].name
        Backups.paths[i] = Backups.items[i].path
      end

    elseif tabfocus == TabID.Docs then
      if isFiltered then
        Docs.filteredNames[i] = Docs.filteredItems[i].name
        Docs.filteredPaths[i] = Docs.filteredItems[i].path
      else
        Docs.names[i] = Docs.items[i].name
        Docs.paths[i] = Docs.items[i].path
      end

    elseif tabfocus == TabID.Favorites then
      if isFiltered then
        Favorites.filteredNames[i] = Favorites.filteredItems[i].name
        Favorites.filteredPaths[i] = Favorites.filteredItems[i].path
      else
        Favorites.names[i] = Favorites.items[i].name
        Favorites.paths[i] = Favorites.items[i].path
      end
    end
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
  names = {},
  paths = {},
  filteredItems = {},
  filteredNames = {},
  filteredPaths = {},
}

local function AddRecentProjectEntries(fullPath, e)
  if fullPath ~= "" then
    if not CheckForDuplicates(RecentProjects.paths, fullPath) then
      e = e + 1
      RecentProjects.paths[e] = fullPath
      RecentProjects.names[e] = RemoveExtension(GetFilenameWithoutPath(fullPath), FileTypes.rpp)
      RecentProjects.items[e] = { name = RecentProjects.names[e], path = RecentProjects.paths[e] }
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
  RecentProjects.names, RecentProjects.items, RecentProjects.paths = {}, {}, {}
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

  if #RecentProjects.names > 0 then
    for i = 1, #RecentProjects.names do RecentProjects.items[RecentProjects.names[i]] = RecentProjects.paths[i] end
  end

  Global_UpdatePathDisplayMode()
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
  names = {},
  paths = {},
  filteredItems = {},
  filteredNames ={},
  filteredPaths ={}
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
  ProjectTemplates.items, ProjectTemplates.names, ProjectTemplates.paths  = {}, {}, {}
  local pos = 1

  for i = 1, #tempTemplates do
    if ConfigFlags.listFilesInDebugMessages then MsgDebug(tempTemplates[i]) end
    ProjectTemplates.names[pos] = RemoveExtension(GetFilenameWithoutPath(tempTemplates[i]), FileTypes.rpp)
    ProjectTemplates.paths[pos] = tempTemplates[i]
    ProjectTemplates.items[ProjectTemplates.names[pos]] = tempTemplates[i]
    ProjectTemplates.items[pos] = { name = ProjectTemplates.names[pos], path = ProjectTemplates.paths[pos] }
    pos = pos + 1
  end

  Global_UpdatePathDisplayMode()
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
      RL_WriteToFileCache(CacheFile.ProjectTemplates, TabParentSelectionIndex[TabID.ProjectTemplates], ProjectTemplates.paths, false)
    end
  end
end

-------------------------
-- Track Template Listbox
-------------------------
TrackTemplates = {
  items = {},
  names = {},
  paths = {},
  filteredItems = {},
  filteredNames = {},
  filteredPaths = {}
}

local function FillTrackTemplateListboxBase(tempTemplates)
  TrackTemplates.items, TrackTemplates.names, TrackTemplates.paths  = {}, {}, {}
  local pos = 1

  for i = 1, #tempTemplates do
    if ConfigFlags.listFilesInDebugMessages then MsgDebug(tempTemplates[i]) end
    TrackTemplates.names[pos] = RemoveExtension(GetFilenameWithoutPath(tempTemplates[i]), FileTypes.tracktemplate)
    TrackTemplates.paths[pos] = tempTemplates[i]
    TrackTemplates.items[TrackTemplates.names[pos]] = tempTemplates[i]
    TrackTemplates.items[pos] = { name = TrackTemplates.names[pos], path = TrackTemplates.paths[pos] }
    pos = pos + 1
  end

  Global_UpdatePathDisplayMode()
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
      RL_WriteToFileCache(CacheFile.TrackTemplates, TabParentSelectionIndex[TabID.TrackTemplates], TrackTemplates.paths, false)
    end
  end
end

-------------------------
-- Custom Project Listbox
-------------------------
CustomProjects = {
  items = {},
  names = {},
  paths = {},
  filteredItems = {},
  filteredNames = {},
  filteredPaths = {}
}

local function FillCustomProjectsListboxBase(dirFiles, pos)
  for i = 1, #dirFiles do
    if ConfigFlags.listFilesInDebugMessages then MsgDebug(dirFiles[i]) end
    CustomProjects.names[pos] = RemoveExtension(GetFilenameWithoutPath(dirFiles[i]), FileTypes.rpp)
    CustomProjects.paths[pos] = dirFiles[i]
    CustomProjects.items[CustomProjects.names[pos]] = dirFiles[i]
    CustomProjects.items[pos] = { name = CustomProjects.names[pos], path = CustomProjects.paths[pos] }
    pos = pos + 1
  end

  Global_UpdatePathDisplayMode()
  GUI.elms.tab_customProjects_listbox:redraw()
  ShowFileCount()

  return pos
end

local function FillCustomProjectsListbox()
  local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.CustomProjects, CacheFile.MainSection)
  if cacheExists then FillCustomProjectsListboxBase(cacheTable, 1)
  else
    if #CustomPaths.Projects > 1 then
      CustomProjects.items, CustomProjects.names, CustomProjects.paths = {}, {}, {}
      local multiPaths = SplitMultiPaths(CustomPaths.Projects)
      for m = 1, #multiPaths do FillCustomProjectsListboxBase(GetFiles(multiPaths[m], TabID.CustomProjects, FileTypes.rpp), 1) end
      RL_WriteToFileCache(CacheFile.CustomProjects, TabParentSelectionIndex[TabID.CustomProjects], CustomProjects.paths, false)
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
  projectNames = {},
  projectPaths = {},
  filteredProjectItems = {},
  filteredProjectNames = {},
  filteredProjectPaths = {}
}

local function RPL_ParseRPLFile(selected)
  for i = 1, #selected do
    local file = io.open(ProjectLists.rplPaths[selected[i]] .. GetPathSeparator() .. ProjectLists.rplFiles[selected[i]] .. FileTypes.rpl, "r")
    if not file then return nil end
    for line in file:lines() do
      if #line > 1 then
        if not CheckForDuplicates(ProjectLists.projectPaths, line) then
          ProjectLists.projectPaths[#ProjectLists.projectPaths + 1] = line
        end
      end
    end
    file:close()
  end

  for i = 1, #ProjectLists.projectPaths do
    ProjectLists.projectNames[#ProjectLists.projectNames + 1] = RemoveExtension(RemoveWhiteSpaces(GetFilenameWithoutPath(ProjectLists.projectPaths[i])), FileTypes.rpp)
    ProjectLists.projectItems[ProjectLists.projectNames[i]] = ProjectLists.projectPaths[i]
    ProjectLists.projectItems[#ProjectLists.projectItems + 1] = { name = RemoveExtension(RemoveWhiteSpaces(GetFilenameWithoutPath(ProjectLists.projectPaths[i])), FileTypes.rpp), path = ProjectLists.projectPaths[i]}
  end

   GUI.elms.tab_projectLists_listboxProjects.list = ProjectLists.projectNames
end

function RPL_FillProjectListFromTable(cacheTable)
  ProjectLists.projectPaths, ProjectLists.projectNames, ProjectLists.projectItems = {}, {}, {}
  for i = 1, #cacheTable do
    ProjectLists.projectPaths[#ProjectLists.projectPaths + 1] = cacheTable[i]
    ProjectLists.projectNames[#ProjectLists.projectNames + 1] = RemoveExtension(RemoveWhiteSpaces(GetFilenameWithoutPath(ProjectLists.projectPaths[i])), FileTypes.rpp)
    ProjectLists.projectItems[ProjectLists.projectNames[i]] = ProjectLists.projectPaths[i]
    ProjectLists.projectItems[#ProjectLists.projectItems + 1] = { name = RemoveExtension(RemoveWhiteSpaces(GetFilenameWithoutPath(ProjectLists.projectPaths[i])), FileTypes.rpp), path = ProjectLists.projectPaths[i]}
  end
   GUI.elms.tab_projectLists_listboxProjects.list = ProjectLists.projectNames
end

local function RPL_FillProjectListBoxWithAll()
  local vals = GUI.elms.tab_projectLists_listboxRPL.list
  if #vals > 0 then
    ProjectLists.projectNames, ProjectLists.projectPaths, ProjectLists.projectItems = {}, {}, {}
    allRPLProjects = {}
    for v = 2, #vals do allRPLProjects[v - 1] = v end
    RPL_ParseRPLFile(allRPLProjects)
    TabSelectionIndex[TabID.ProjectLists] = 1
    GUI.Val("tab_projectLists_listboxProjects", {1})
    RL_WriteToFileCache(CacheFile.ProjectLists, TabParentSelectionIndex[TabID.ProjectLists], ProjectLists.projectPaths, false)
  end
  Global_UpdatePathDisplayMode()
  ShowFileCount()
end

local function RPL_FillProjectListBoxFromSelection()
  local vals = GetSelectionTable(GUI.Val("tab_projectLists_listboxRPL"))
  if GetSubListSize() > 0 then
    ProjectLists.projectNames, ProjectLists.projectPaths, ProjectLists.projectItems = {}, {}, {}
    RPL_ParseRPLFile(vals)
    TabSelectionIndex[TabID.ProjectLists] = 1
    GUI.Val("tab_projectLists_listboxProjects", {1})
    RL_WriteToFileCache(CacheFile.ProjectLists, TabParentSelectionIndex[TabID.ProjectLists], ProjectLists.projectPaths, false)
  end
  Global_UpdatePathDisplayMode()
  ShowFileCount()
end

------------------------
-- Backups Lists Listbox
------------------------
Backups = {
  items = {},
  names = {},
  paths = {},
  filteredItems = {},
  filteredNames = {},
  filteredPaths = {}
}

local function FillBackupsListboxBase(dirFiles, pos)
  for i = 1, #dirFiles do
    if ConfigFlags.listFilesInDebugMessages then MsgDebug(dirFiles[i]) end
    Backups.names[pos] = RemoveExtension(GetFilenameWithoutPath(dirFiles[i]), FileTypes.backup)
    Backups.paths[pos] = dirFiles[i]
    Backups.items[Backups.names[pos]] = dirFiles[i]
    Backups.items[pos] = { name = Backups.names[pos], path = Backups.paths[pos] }
    pos = pos + 1
  end

  GUI.elms.tab_backups_listbox.list = Backups.names
  Global_UpdatePathDisplayMode()
  ShowFileCount()

  return pos
end

local function FillBackupsListbox()
  local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.Backups, CacheFile.MainSection)
  if cacheExists then FillBackupsListboxBase(cacheTable, 1)
  else
    if #CustomPaths.Backups > 1 then
      Backups.items, Backups.names, Backups.paths = {}, {}, {}
      local multiPaths = SplitMultiPaths(CustomPaths.Backups)
      local pos = 1
      for m = 1, #multiPaths do pos = FillBackupsListboxBase(GetFiles(multiPaths[m], TabID.Backups, FileTypes.backup), pos) end
      RL_WriteToFileCache(CacheFile.Backups, TabParentSelectionIndex[TabID.Backups], Backups.paths, false)
    end
  end
end

---------------
-- Docs Listbox
---------------
Docs = {
  items = {},
  names = {},
  paths = {},
  filteredItems = {},
  filteredNames = {},
  filteredPaths = {}
}

local function FillDocsListboxBase(dirFiles, pos)
  for i = 1, #dirFiles do
    if ConfigFlags.listFilesInDebugMessages then MsgDebug(dirFiles[i]) end
    Docs.names[pos] = RemoveExtension(GetFilenameWithoutPath(dirFiles[i]), FileTypes.docs)
    Docs.paths[pos] = dirFiles[i]
    Docs.items[Docs.names[pos]] = dirFiles[i]
    Docs.items[pos] = { name = Docs.names[pos], path = Docs.paths[pos] }
    pos = pos + 1
  end

  GUI.elms.tab_docs_listbox.list = Docs.names
  Global_UpdatePathDisplayMode()
  ShowFileCount()

  return pos
end

local function FillDocsListbox()
  local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.Docs, CacheFile.MainSection)
  if cacheExists then FillDocsListboxBase(cacheTable, 1)
  else
    if #CustomPaths.Docs > 1 then
      Docs.items, Docs.names, Docs.paths = {}, {}, {}
      local multiPaths = SplitMultiPaths(CustomPaths.Docs)
      local pos = 1
      for m = 1, #multiPaths do pos = FillDocsListboxBase(GetFiles(multiPaths[m], TabID.Docs, FileTypes.docs), pos) end
      RL_WriteToFileCache(CacheFile.Docs, TabParentSelectionIndex[TabID.Docs], Docs.paths, false)
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
    if GUI.Val("options_menuShowPathsInStatusbar") == 2 then selectedPath = GetDirectoryPath(selectedPath) .. GetPathSeparator() end
    MsgStatusBar(selectedPath)
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
  Global_CheckWindowPinState()
end

local function Global_NewTab()
  reaper.Main_OnCommand(40859, 0) -- New project tab
  if GUI.Val("options_checklistOpenPropertiesOnNewProject") then reaper.Main_OnCommand(40021, 0) end -- File: Project settings
  Global_TriggerFollowAction("actions_txtFollowAction_NewTab")
  Global_CheckWindowPinState()
end

local function Global_NewTabIgnoreDefaultTemplate()
  reaper.Main_OnCommand(41929, 0) -- New project tab (ignore default template)
  if GUI.Val("options_checklistOpenPropertiesOnNewProject") then reaper.Main_OnCommand(40021, 0) end -- File: Project settings
  Global_CheckWindowPinState()
end

local function Global_Load(tabmode, selectedFile, fileCount)
  if selectedFile ~= nil then
    if tabmode then
        reaper.Main_OnCommand(40859, 0) -- New project tab
        reaper.Main_openProject(selectedFile)
        if GUI.Val("main_checklistSaveAsNewVersion") or GUI.Val("tab_favorites_checklistSaveAsNewVersion") or RL.saveAsNewVersionMode == 1 then
          reaper.Main_OnCommand(41895, 0) -- [Main] - File: Save new version of project (automatically increment project name)
        end
        Global_TriggerFollowAction("actions_txtFollowAction_LoadProjectInTab")
        if JSAPIinstalled then AudioPreviewStopAll() end
    else
      if fileCount > 1 then reaper.Main_OnCommand(40859, 0) end -- New project tab
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
    if reaperversion ~= nil and #reaperversion > 1 and ((reaperversion:match("6.")) or reaperversion:match("5.99") or reaperversion:match("5.98[3-9]")) then
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
  if templateCount > 1 then reaper.Main_OnCommand(40859, 0) end -- New project tab
  Global_ProjectTemplateLoadBase(template)
end

function RL_Mouse_DoubleClick(currentTab)
  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local dcOption = GUI.Val("options_menuDoubleClick")
  -- show prompt
  if dcOption == 1 then
    local doubleClickMenuEntries = "1 - Load|2 - Load in Tab"
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
          reaper.Main_OnCommand(40859, 0) -- New project tab
          Global_ProjectTemplateLoadBase(ProjectTemplates.filteredItems[vals[p]].path)
        else
          Global_ProjectTemplateLoad(ProjectTemplates.filteredItems[vals[p]].path, p)
        end
      else
        if tabmode then
          reaper.Main_OnCommand(40859, 0) -- New project tab
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
        if tabmode then reaper.Main_OnCommand(40859, 0) end -- New project tab
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
      if FilterActive.Backups then Global_Load(tabmode, RemoveWhiteSpaces(Backups.filteredPaths[vals[p]]), p) 
      else Global_Load(tabmode, RemoveWhiteSpaces(Backups.paths[vals[p]]), p) end
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

local replaceMatchString = function (c)
  return "[" .. string.lower(c) .. string.upper(c) .. "]"
end

local function GetSearchTable(searchString)
  local searchTable = {}
  for match in string.gmatch(searchString, "[^%s]+") do -- space separator
    searchTable[#searchTable + 1] = string.gsub(match, "%a", replaceMatchString)
  end
  return searchTable
end

-------------------------
-- Filter Recent Projects
-------------------------
local function Filter_RecentProject_Apply()
  RecentProjects.filteredNames, RecentProjects.filteredPaths, RecentProjects.filteredItems = {}, {}, {}
  local searchList = {}
  local searchStr = GUI.Val("tab_recentProjects_txtFilter")
  if #searchStr > 0 then
    FilterActive.RecentProjects = true
    GUI.elms.tab_recentProjects_txtFilter.color = FilterColor.active
    GUI.elms.tab_recentProjects_btnFilterClear.col_txt = FilterColor.active

    if RL.showFullPaths then searchList = RecentProjects.paths else searchList = RecentProjects.names end
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
        for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          RecentProjects.filteredNames[RecentProjects.names[i]] = RecentProjects.paths[i]
          if not CheckForDuplicates(RecentProjects.filteredNames, RecentProjects.names[i]) then
            RecentProjects.filteredNames[#RecentProjects.filteredNames + 1] = RecentProjects.names[i]
            RecentProjects.filteredPaths[#RecentProjects.filteredPaths + 1] = RecentProjects.paths[i]
            RecentProjects.filteredItems[#RecentProjects.filteredItems + 1] = { name = RecentProjects.names[i], path = RecentProjects.paths[i] }
          end
        end
      end
    end
  else
    FilterActive.RecentProjects = false
    GUI.elms.tab_recentProjects_txtFilter.color = FilterColor.inactive
    GUI.elms.tab_recentProjects_btnFilterClear.col_txt = FilterColor.inactive
  end
  
  UpdatePathDisplay_RecentProjects(RL.showFullPaths)
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
  ProjectTemplates.filteredNames, ProjectTemplates.filteredPaths, ProjectTemplates.filteredItems = {}, {}, {}
  local searchList = {}
  local searchStr = GUI.Val("tab_projectTemplates_txtFilter")
  if #searchStr > 0 then
    FilterActive.ProjectTemplates = true
    GUI.elms.tab_projectTemplates_txtFilter.color = FilterColor.active
    GUI.elms.tab_projectTemplates_btnFilterClear.col_txt = FilterColor.active

    if RL.showFullPaths then searchList = ProjectTemplates.paths else searchList = ProjectTemplates.names end
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          ProjectTemplates.filteredNames[ProjectTemplates.names[i]] = ProjectTemplates.names[i]
          if not CheckForDuplicates(ProjectTemplates.filteredNames, ProjectTemplates.names[i]) then
            ProjectTemplates.filteredNames[#ProjectTemplates.filteredNames + 1] = ProjectTemplates.names[i]
            ProjectTemplates.filteredPaths[#ProjectTemplates.filteredPaths + 1] = ProjectTemplates.items[ProjectTemplates.names[i]]
            ProjectTemplates.filteredItems[#ProjectTemplates.filteredItems + 1] = { name = ProjectTemplates.names[i], path = ProjectTemplates.items[ProjectTemplates.names[i]] }
          end
        end
      end
    end
  else
    FilterActive.ProjectTemplates = false
    GUI.elms.tab_projectTemplates_txtFilter.color = FilterColor.inactive
    GUI.elms.tab_projectTemplates_btnFilterClear.col_txt = FilterColor.inactive
  end

  UpdatePathDisplay_ProjectTemplates(RL.showFullPaths)
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
  TrackTemplates.filteredNames, TrackTemplates.filteredPaths, TrackTemplates.filteredItems = {}, {}, {}
  local searchList = {}
  local searchStr = GUI.Val("tab_trackTemplates_txtFilter")
  if #searchStr > 0 then
    FilterActive.TrackTemplates = true
    GUI.elms.tab_trackTemplates_txtFilter.color = FilterColor.active
    GUI.elms.tab_trackTemplates_btnFilterClear.col_txt = FilterColor.active

    if RL.showFullPaths then searchList = TrackTemplates.paths else searchList = TrackTemplates.names end
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          TrackTemplates.filteredNames[TrackTemplates.names[i]] = TrackTemplates.names[i]
          if not CheckForDuplicates(TrackTemplates.filteredNames, TrackTemplates.names[i]) then
            TrackTemplates.filteredNames[#TrackTemplates.filteredNames + 1] = TrackTemplates.names[i]
            TrackTemplates.filteredPaths[#TrackTemplates.filteredPaths + 1] = TrackTemplates.items[TrackTemplates.names[i]]
            TrackTemplates.filteredItems[#TrackTemplates.filteredItems + 1] = { name = TrackTemplates.names[i], path = TrackTemplates.items[TrackTemplates.names[i]] }
          end
        end
      end
    end
  else
    FilterActive.TrackTemplates = false
    GUI.elms.tab_trackTemplates_txtFilter.color = FilterColor.inactive
    GUI.elms.tab_trackTemplates_btnFilterClear.col_txt = FilterColor.inactive
  end

  UpdatePathDisplay_TrackTemplates(RL.showFullPaths)
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
  CustomProjects.filteredNames, CustomProjects.filteredPaths, CustomProjects.filteredItems = {}, {}, {}
  local searchList = {}
  local searchStr = GUI.Val("tab_customProjects_txtFilter")
  if #searchStr > 0 then
    FilterActive.CustomProjects = true
    GUI.elms.tab_customProjects_txtFilter.color = FilterColor.active
    GUI.elms.tab_customProjects_btnFilterClear.col_txt = FilterColor.active

    if RL.showFullPaths then searchList = CustomProjects.paths else searchList = CustomProjects.names end
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          CustomProjects.filteredNames[CustomProjects.names[i]] = CustomProjects.names[i]
          if not CheckForDuplicates(CustomProjects.filteredNames, CustomProjects.names[i]) then
            CustomProjects.filteredNames[#CustomProjects.filteredNames + 1] = CustomProjects.names[i]
            CustomProjects.filteredPaths[#CustomProjects.filteredPaths + 1] = CustomProjects.items[CustomProjects.names[i]]
            CustomProjects.filteredItems[#CustomProjects.filteredItems + 1] = { name = CustomProjects.names[i], path = CustomProjects.items[CustomProjects.names[i]] }
          end
        end
      end
    end
  else
    FilterActive.CustomProjects = false
    GUI.elms.tab_customProjects_txtFilter.color = FilterColor.inactive
    GUI.elms.tab_customProjects_btnFilterClear.col_txt = FilterColor.inactive
  end

  UpdatePathDisplay_CustomProjects(RL.showFullPaths)
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
  ProjectLists.filteredProjectNames, ProjectLists.filteredProjectPaths, ProjectLists.filteredProjectItems = {}, {}, {}
  local searchList = {}
  local searchStr = GUI.Val("tab_projectLists_txtFilter")
  if #searchStr > 0 then
    FilterActive.ProjectLists = true
    GUI.elms.tab_projectLists_txtFilter.color = FilterColor.active
    GUI.elms.tab_projectLists_btnFilterClear.col_txt = FilterColor.active
    
    if RL.showFullPaths then searchList = ProjectLists.projectPaths else searchList = ProjectLists.projectNames end
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          ProjectLists.filteredProjectNames[ProjectLists.projectNames[i]] = ProjectLists.projectNames[i]
          if not CheckForDuplicates(ProjectLists.filteredProjectNames, ProjectLists.projectNames[i]) then
            ProjectLists.filteredProjectNames[#ProjectLists.filteredProjectNames + 1] = ProjectLists.projectNames[i]
            ProjectLists.filteredProjectPaths[#ProjectLists.filteredProjectPaths + 1] = ProjectLists.projectItems[ProjectLists.projectNames[i]]
            ProjectLists.filteredProjectItems[#ProjectLists.filteredProjectItems + 1] = { name = ProjectLists.projectNames[i], path = ProjectLists.projectItems[ProjectLists.projectNames[i]] }
          end
        end
      end
    end
  else
    FilterActive.ProjectLists = false
    GUI.elms.tab_projectLists_txtFilter.color = FilterColor.inactive
    GUI.elms.tab_projectLists_btnFilterClear.col_txt = FilterColor.inactive
  end

  UpdatePathDisplay_ProjectLists(RL.showFullPaths)
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
  Backups.filteredNames, Backups.filteredPaths, Backups.filteredItems = {}, {}, {}
  local searchList = {}
  local searchStr = GUI.Val("tab_backups_txtFilter")
  if #searchStr > 0 then
    FilterActive.Backups = true
    GUI.elms.tab_backups_txtFilter.color = FilterColor.active
    GUI.elms.tab_backups_btnFilterClear.col_txt = FilterColor.active
    
    if RL.showFullPaths then searchList = Backups.paths else searchList = Backups.names end
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          Backups.filteredNames[Backups.names[i]] = Backups.names[i]
          if not CheckForDuplicates(Backups.filteredNames, Backups.names[i]) then
            Backups.filteredNames[#Backups.filteredNames + 1] = Backups.names[i]
            Backups.filteredPaths[#Backups.filteredPaths + 1] = Backups.items[Backups.names[i]]
            Backups.filteredItems[#Backups.filteredItems + 1] = { name = Backups.names[i], path = Backups.items[Backups.names[i]] }
          end
        end
      end
    end
  else
    FilterActive.Backups = false
    GUI.elms.tab_backups_txtFilter.color = FilterColor.inactive
    GUI.elms.tab_backups_btnFilterClear.col_txt = FilterColor.inactive
  end
  
  UpdatePathDisplay_Backups(RL.showFullPaths)
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
  Docs.filteredNames, Docs.filteredPaths, Docs.filteredItems = {}, {}, {}
  local searchList = {}
  local searchStr = GUI.Val("tab_docs_txtFilter")
  if #searchStr > 0 then
    FilterActive.Docs = true
    GUI.elms.tab_docs_txtFilter.color = FilterColor.active
    GUI.elms.tab_docs_btnFilterClear.col_txt = FilterColor.active
    
    if RL.showFullPaths then searchList = Docs.paths else searchList = Docs.names end
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          Docs.filteredNames[Docs.names[i]] = Docs.names[i]
          if not CheckForDuplicates(Docs.filteredNames, Docs.names[i]) then
            Docs.filteredNames[#Docs.filteredNames + 1] = Docs.names[i]
            Docs.filteredPaths[#Docs.filteredPaths + 1] = Docs.items[Docs.names[i]]
            Docs.filteredItems[#Docs.filteredItems + 1] = { name = Docs.names[i], path = Docs.items[Docs.names[i]] }
          end
        end
      end
    end
  else
    FilterActive.Docs = false
    GUI.elms.tab_docs_txtFilter.color = FilterColor.inactive
    GUI.elms.tab_docs_btnFilterClear.col_txt = FilterColor.inactive
  end
  
  UpdatePathDisplay_Docs(RL.showFullPaths)
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
  Favorites.filteredNames, Favorites.filteredPaths, Favorites.filteredItems = {}, {}, {}
  local searchList = {}
  local searchStr = GUI.Val("tab_favorites_txtFilter")
  if #searchStr > 0 then
    FilterActive.Favorites = true
    GUI.elms.tab_favorites_txtFilter.color = FilterColor.active
    GUI.elms.tab_favorites_btnFilterClear.col_txt = FilterColor.active
    
    if RL.showFullPaths then searchList = Favorites.paths else searchList = Favorites.names end
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          Favorites.filteredNames[Favorites.names[i]] = Favorites.names[i]
          if not CheckForDuplicates(Favorites.filteredNames, Favorites.names[i]) then
            Favorites.filteredNames[#Favorites.filteredNames + 1] = Favorites.names[i]
            Favorites.filteredPaths[#Favorites.filteredPaths + 1] = Favorites.paths[i]
            Favorites.filteredItems[#Favorites.filteredItems + 1] = { name = Favorites.names[i], path = Favorites.paths[i] }
          end
        end
      end
    end
  else
    FilterActive.Favorites = false
    GUI.elms.tab_favorites_txtFilter.color = FilterColor.inactive
    GUI.elms.tab_favorites_btnFilterClear.col_txt = FilterColor.inactive
  end
  
  UpdatePathDisplay_Favorites(RL.showFullPaths)
  ShowFileCount()
  GUI.Val("tab_favorites_listbox",{})
  ScrollToTop(ListBoxElements[GUI.elms.main_tabs.state])
end

local function Filter_Favorites_Clear()
  GUI.Val("tab_favorites_txtFilter", "")
  Filter_Favorites_Apply()
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

----------------------------
-- Listbox Refresh functions
----------------------------
function RefreshRecentProjects()
  MsgDebug("-----------------------\nRefresh Recent Projects - newest first")
  if SWSinstalled then
    FillRecentProjectsListbox(true)
    Filter_RecentProject_Apply()
  else MsgStatusBar("This tab requires SWS Extensions") end
end

function RefreshRecentProjectsReversed()
  MsgDebug("-----------------------\nRefresh Recent Projects - oldest first")
  if SWSinstalled then
    FillRecentProjectsListbox(false)
    Filter_RecentProject_Apply()
  else MsgStatusBar("This tab requires SWS Extensions") end
end

local function RefreshProjectTemplates()
  MsgDebug("-----------------------\nRefresh Project Templates")
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
    
    Global_UpdateSubfolderPathDisplayMode()
    GUI.Val("tab_projectTemplates_subfolders", TabParentSelectionIndex[TabID.ProjectTemplates])
    UpdateProjectTemplateSubDirSelection()
  else
    FillProjectTemplateListbox()
  end
  Filter_ProjectTemplate_Apply()
  ShowFileCount()
end

local function RefreshTrackTemplates()
  MsgDebug("-----------------------\nRefresh Track Templates")
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

    Global_UpdateSubfolderPathDisplayMode()
    GUI.Val("tab_trackTemplates_subfolders", TabParentSelectionIndex[TabID.TrackTemplates])
    UpdateTrackTemplateSubDirSelection()
  else
    FillTrackTemplateListbox()
  end
  Filter_TrackTemplate_Apply()
  ShowFileCount()
end

local function RefreshCustomProjects()
  MsgDebug("-----------------------\nRefresh Projects")
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

      Global_UpdateSubfolderPathDisplayMode()
      GUI.Val("tab_customProjects_subfolders", TabParentSelectionIndex[TabID.CustomProjects])
      UpdateCustomProjectSubDirSelection()
    else
      FillCustomProjectsListbox()
    end
    Filter_CustomProjects_Apply()
    ShowFileCount()
  else
    MsgStatusBar("No Paths set for Projects")
  end
end

local function RefreshProjectList()
  MsgDebug("-----------------------\nRefresh Project Lists")
  if #CustomPaths.ProjectLists > 1 then
    ProjectLists.projectItems, ProjectLists.projectNames, ProjectLists.projectPaths = {}, {}, {}
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
      UpdateProjectListSelection()
    else
        local allRPLProjects = {}
        for v = 2, #ProjectLists.rplFiles do allRPLProjects[v - 1] = v end
        RPL_ParseRPLFile(allRPLProjects)
        TabSelectionIndex[TabID.ProjectLists] = 1
        GUI.Val("tab_projectLists_listboxProjects", {1})
    end
    
    Global_UpdatePathDisplayMode()
    ShowFileCount()
    Filter_ProjectLists_Apply()
  else
    MsgStatusBar("No Paths set for Project Lists")
  end
end

local function RefreshBackups()
  MsgDebug("-----------------------\nRefresh Backups")
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

      Global_UpdateSubfolderPathDisplayMode()
      GUI.Val("tab_backups_subfolders", TabParentSelectionIndex[TabID.Backups])
      UpdateBackupsSubDirSelection()
    else
      FillBackupsListbox()
    end
    Filter_Backups_Apply()
    ShowFileCount()
  else
    MsgStatusBar("No Paths set for Backups")
  end
end

local function RefreshDocs()
  if SWSinstalled then
    MsgDebug("-----------------------\nRefresh Docs")
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
      
        Global_UpdateSubfolderPathDisplayMode()
        GUI.Val("tab_docs_subfolders", TabParentSelectionIndex[TabID.Docs])
        UpdateDocsSubDirSelection()
      else
        FillDocsListbox()
      end
      Filter_Docs_Apply()
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
    ProjectTemplates.items, ProjectTemplates.names, ProjectTemplates.paths = {}, {}, {}
    ProjectTemplates.filteredNames, ProjectTemplates.filteredPaths = {}, {}
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
    TrackTemplates.items, TrackTemplates.names, TrackTemplates.paths = {}, {}, {}
    TrackTemplates.filteredNames, TrackTemplates.filteredPaths = {}, {}
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
    CustomProjects.items, CustomProjects.names, CustomProjects.paths = {}, {}, {}
    CustomProjects.filteredNames, CustomProjects.filteredPaths = {}, {}
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
    ProjectLists.projectNames, ProjectLists.projectPaths, ProjectLists.projectItems = {}, {}, {}
    ProjectLists.filteredProjectNames, ProjectLists.rplFiles = {}, {}
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
    Backups.items, Backups.names, Backups.paths = {}, {}, {}
    Backups.filteredNames, Backups.filteredPaths = {}, {}
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
    Docs.items, Docs.names, Docs.paths = {}, {}, {}
    Docs.filteredNames, Docs.filteredPaths = {}, {}
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
  ConfirmDialogContent = 30,
  ConfirmDialogWindow = 31,
}

RL = {
  activeSubPanels = {},
  dialogKeyMode = false,
  fontSizes = { 30, 18, 14, 14, 14, 12 },
  forceRescan = false,
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
  showFullPaths = false,
  showSubFolderPaths = false,
  skipOperationOnResize = false,
  sortModeIndex = { 1, 1, 1, 1, 1, 1, 1, 1 },
  subfolderIndent = "   ",
  windowToggleShortcut = nil
}

if reaper.GetExtState(appname, "window_showmainbuttonpanel") ~= "" then
  RL.showButtonPanel = (reaper.GetExtState(appname, "window_showmainbuttonpanel") == "true" and true or false)
end

if RL.showButtonPanel then RL.minWidth, RL.minHeight = 535, 349 else RL.minWidth, RL.minHeight = 420, 228 end

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
      themeslot = GUI.Val("main_themeslot")
      if themeslot < 5 then reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_LOAD_THEME" .. themeslot - 1), 0) -- SWS/S&M: Resources - Load theme, slot#
      else reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_LOAD_THEMEl"), 0) end 
    end

    function RL_Draw_ThemeSlotSelector(alignment)
      if RL.showButtonPanel then 
        GUI.New("main_themeslot", "Menubox", LayerIndex.Global, GUI.w - (60 * RL.scaleFactor) + (RL.scaleFactor * 10), footerY + (2 * RL.scaleFactor), 34 * RL.scaleFactor, 15 * RL.scaleFactor, "Reaper Theme", ThemeSlots.items, 8)
        GUI.elms.main_themeslot.tooltip = "Set up and switch between different Reaper Theme Slots\n\nSlot number and descriptions can be set in\n[Layout / Colors]"
        GUI.elms.main_themeslot.align = alignment
        
        function GUI.elms.main_themeslot:onmousedown()
          GUI.Menubox.onmouseup(self)
          ThemeSlot_Load()
        end
        
        function GUI.elms.main_themeslot:onwheel()
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
      GUI.New("layout_themeslot_Setup", "Button", LayerIndex.Layout, 2 * pad_left, 162 * RL.scaleFactor, 65 * RL.scaleFactor, 15 * RL.scaleFactor, "Theme Slots", ThemeSlot_Setup)
      GUI.New("layout_themeslot_Save", "Button", LayerIndex.Layout, 2 * pad_left + 68 * RL.scaleFactor, 162 * RL.scaleFactor, 35 * RL.scaleFactor, 15 * RL.scaleFactor, "Save", ThemeSlot_SaveNames)
      GUI.New("layout_themeslot_number", "Menubox", LayerIndex.Layout, 2 * pad_left + 108 * RL.scaleFactor, 162 * RL.scaleFactor, 38 * RL.scaleFactor, 16 * RL.scaleFactor, "", "1,2,3,4,5")
      GUI.elms.layout_themeslot_number.align = 1
      
      for i = 1, ThemeSlots.maxCount do
        GUI.New("layout_themeslot_" .. i, "Textbox", LayerIndex.Layout, 44 * pad_left, 110 * RL.scaleFactor + (25 * RL.scaleFactor) + (16 * (i - 1) * RL.scaleFactor), 146 * RL.scaleFactor, 15 * RL.scaleFactor, i, 8)
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
            reaper.BR_Win32_WritePrivateProfileString("Recent", recentPathTag, "", reaperIniPath)
            MsgDebug("Recent Projects | removed " .. recentPathTag .. " | " .. selectedProject)
          end
        until (lastEntry)
      end

      GUI.Val("tab_recentProjects_listbox", {})
      RefreshRecentProjects()
    end

    function RecentProjects_ClearList()
      for k = 1, RecentProjects.maxIndex do reaper.BR_Win32_WritePrivateProfileString("Recent", "recent" .. string.format("%02d", k), "", reaperIniPath) end
      MsgDebug("Recent Projects | list cleared")
      RefreshRecentProjects()
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
  str = "RL 2.4.1 | Lokasenna_GUI " .. GUI.version
  str_w, str_h = gfx.measurestr(str)
  gfx.x = gfx.w - str_w - 6
  gfx.y = gfx.h - str_h - 4
  gfx.drawstr(str)
end

----------------
-- Label buttons
----------------
function GUI.Button:init()
  self.buff = self.buff or GUI.GetBuffer()
  gfx.dest = self.buff
  gfx.setimgdim(self.buff, -1, -1)
  gfx.setimgdim(self.buff, 2*self.w + 4, self.h + 2)

  if not self.isLabelButton then
    GUI.color(self.col_fill)
    GUI.roundrect(1, 1, self.w, self.h, 4, 1, 1)
    GUI.color("elm_outline")
    GUI.roundrect(1, 1, self.w, self.h, 4, 1, 0)

    local r, g, b, a = table.unpack(GUI.colors["shadow"])
    gfx.set(r, g, b, 1)
    GUI.roundrect(self.w + 2, 1, self.w, self.h, 4, 1, 1)
    gfx.muladdrect(self.w + 2, 1, self.w + 2, self.h + 2, 1, 1, 1, a, 0, 0, 0, 0)
  end
end

-----------------------------------------------------------------------------
-- Override tooltip function for handling macOS coordinates (inverted y-axis)
-----------------------------------------------------------------------------
GUI.settooltip = function(str)
  if not str or str == "" then return end
  local x, y = gfx.clienttoscreen(0, 0)
  if osversion:find("OSX") then
    local mouseX, mouseY = reaper.GetMousePosition()
    reaper.TrackCtl_SetToolTip(str, mouseX + 16, mouseY + 16, true)
  else
    reaper.TrackCtl_SetToolTip(str, x + GUI.mouse.x + 16, y + GUI.mouse.y + 16, true)
  end
  GUI.tooltip = str
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
  pad_left = 4 * RL.scaleFactor
  pad_top = 36 * RL.scaleFactor
  topY = 7 * RL.scaleFactor

  -- listbox size
  listbox_top = 28 * RL.scaleFactor
  if RL.showButtonPanel then listbox_w = GUI.w - (144 * RL.scaleFactor)
  else listbox_w = GUI.w - 2 * pad_left end
  listbox_h = GUI.h - (71 * RL.scaleFactor)

  -- button indents
  btn_pad_left = listbox_w + (8 * RL.scaleFactor)
  btn_pad_top = 129 * RL.scaleFactor
  btn_pad_add = 29 * RL.scaleFactor
  btn_tab_top = 191 * RL.scaleFactor

  -- refresh buttons
  refreshW = 40 * RL.scaleFactor
  refreshH = 15 * RL.scaleFactor
  refreshX = pad_left 
  refreshY = GUI.h - (38 * RL.scaleFactor)

  -- filter textbox
  filterX = 122 * RL.scaleFactor
  filterY = 4.5 * RL.scaleFactor
  filterW = (listbox_w * 0.52)
  filterH = 20 * RL.scaleFactor

  -- path display box
  pathX = pad_left + 43 * RL.scaleFactor
  footerY = GUI.h - (40 * RL.scaleFactor)
end

function InitSubPanels()
  local t1, t2, t3, t4, t5, t6 = string.match(reaper.GetExtState(appname, "window_showsubfolderpanel"), "([%a]+),([%a]+),([%a]+),([%a]+),([%a]+),([%a]+)")
  RL.activeSubPanels = {
    tostring(t1) == "true" and true or false,
    tostring(t2) == "true" and true or false,
    tostring(t3) == "true" and true or false,
    tostring(t4) == "true" and true or false,
    tostring(t5) == "true" and true or false,
    tostring(t6) == "true" and true or false
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

TabSelectionIndex = { 1, 1, 1, 1, 1, 1, 1, 1 }

TabID = {
  RecentProjects = 1,
  ProjectTemplates = 2,
  TrackTemplates = 3,
  CustomProjects = 4,
  ProjectLists = 5,
  Backups = 6,
  Docs = 7,
  Favorites = 8,
  Layout = 9,
  Actions = 10,
  Options = 11,
  ScanSettings = 12,
  Paths = 13,
  Help = 14
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
  "[ Layout / Colors ]",
  "[ Follow Actions ]",
  "[ Options ]",
  "[ Scan Settings ]",
  "[ Paths ]",
  "[ Help ]"
}

if not ConfigFlags.enableCustomColorOptions then TabLabels[9] = "[ Layout ]" end

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
  if JSAPIinstalled then
    GUI.New("main_previewVolKnob", "Knob", LayerIndex.Global, 4 * pathX + (RL.scaleFactor * 15), footerY + (1.2 * RL.scaleFactor), 18 * RL.scaleFactor, "Volume", 0, 100, 50, 1)
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

    GUI.New("main_previewStatusLabel", "Label", LayerIndex.Global, 4.6 * pathX + (RL.scaleFactor * 15), footerY + 2 * RL.scaleFactor, "Preview", false, 4, "elm_frame")
    
    GUI.New("main_previewChannels", "Menubox", LayerIndex.Global, 5.6 * pathX + (RL.scaleFactor * 15), footerY + (2 * RL.scaleFactor), 51 * RL.scaleFactor, 15 * RL.scaleFactor, "", table.concat(stereoChannels, ","), 8)
    GUI.elms.main_previewChannels.col_txt = "elm_frame"
    GUI.elms.main_previewChannels.align = 1
    GUI.elms.main_previewChannels.tooltip = "Audio Preview Section\n\nSet the audio channel(s) used for preview playback"
    
    local function SetPreviewChannel(channel)
      if channel and #channel > 0 then AudioPreview.channelIndex = tonumber(string.sub(channel, 1, #channel - channel:find("/"))) - 1
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

----------------
-- Main elements
----------------
local function RL_Draw_Main()
  GUI.New("main_tabs", "Tabs", LayerIndex.Main, 0, 0, 95 * RL.scaleFactor, 20 * RL.scaleFactor, " , , , , , , , , , , , , , ", 16)
  GUI.elms.main_tabs.col_tab_b = "elm_bg"
  GUI.elms.main_tabs.h, GUI.elms.main_tabs.tab_h = 0, 0
  GUI.New("main_menuTabSelector", "Menubox", LayerIndex.Main, pad_left, 4.5 * RL.scaleFactor, (125 * RL.scaleFactor) - (10 * RL.scaleFactor), 20 * RL.scaleFactor, "", TabLabels, 8)
  GUI.elms.main_menuTabSelector.align = 1
  
  function GUI.elms.main_menuTabSelector:onmousedown()
    GUI.Menubox.onmouseup(self)
    RL_SetFocusedTab(GUI.Val("main_menuTabSelector"))
  end

  function GUI.elms.main_menuTabSelector:onwheel()
    GUI.Menubox.onwheel(self)
    RL_SetFocusedTab(GUI.Val("main_menuTabSelector"))
  end

  GUI.New("main_statusbar", "Label", LayerIndex.Overlay, pad_left, GUI.h - (16 * RL.scaleFactor), "", true, 4)

  GUI.elms.main_tabs:update_sets({
      [TabID.RecentProjects] = { LayerIndex.Overlay, LayerIndex.Global, LayerIndex.RecentProjects, LayerIndex.SaveAsNewVersion, LayerIndex.SpecialOption },
      [TabID.ProjectTemplates] = { LayerIndex.Overlay, LayerIndex.Global, LayerIndex.ProjectTemplates, LayerIndex.SpecialOption },
      [TabID.TrackTemplates] = { LayerIndex.Overlay, LayerIndex.Global, LayerIndex.TrackTemplates, LayerIndex.SpecialOption },
      [TabID.CustomProjects] = { LayerIndex.Overlay, LayerIndex.Global, LayerIndex.CustomProjects, LayerIndex.SaveAsNewVersion, LayerIndex.SpecialOption },
      [TabID.ProjectLists] = { LayerIndex.Overlay, LayerIndex.Global, LayerIndex.ProjectLists, LayerIndex.SaveAsNewVersion, LayerIndex.SpecialOption },
      [TabID.Backups] = { LayerIndex.Overlay, LayerIndex.Global, LayerIndex.Backups, LayerIndex.SpecialOption },
      [TabID.Docs] = { LayerIndex.Overlay, LayerIndex.Global, LayerIndex.Docs, LayerIndex.SpecialOption },
      [TabID.Favorites] = { LayerIndex.Overlay, LayerIndex.Global, LayerIndex.Favorites },
      [TabID.Actions] = { LayerIndex.Overlay, LayerIndex.VersionInfo, LayerIndex.Actions },
      [TabID.Options] = { LayerIndex.Overlay, LayerIndex.VersionInfo, LayerIndex.Options },
      [TabID.ScanSettings] = { LayerIndex.Overlay, LayerIndex.VersionInfo, LayerIndex.ScanSettings },
      [TabID.Paths] = { LayerIndex.Overlay, LayerIndex.VersionInfo, LayerIndex.Paths },
      [TabID.Layout] = { LayerIndex.Overlay, LayerIndex.VersionInfo, LayerIndex.Layout},
      [TabID.Help] = { LayerIndex.Overlay, LayerIndex.VersionInfo, LayerIndex.Help }
  })

  function GUI.elms.main_tabs:onmousedown()
    GUI.Tabs.onmousedown(self)
    GUI.Val("main_menuTabSelector", GUI.elms.main_tabs.state)
    RL_SetFocusedTab(GUI.elms.main_tabs.state)
  end

  function GUI.elms.main_tabs:onwheel()
    GUI.Tabs.onwheel(self)
    GUI.Val("main_menuTabSelector", GUI.elms.main_tabs.state)
    RL_SetFocusedTab(GUI.elms.main_tabs.state)
  end

  GUI.New("main_lblPaths", "Label", LayerIndex.Global, 2.6 * pathX + (RL.scaleFactor * 5), footerY + (2.85 * RL.scaleFactor), "Paths", false, 3)
  GUI.New("main_checklistPaths", "Checklist", LayerIndex.Global, 3.2 * pathX + (RL.scaleFactor * 8), footerY + (3 * RL.scaleFactor), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "", "", 0)
  GUI.elms.main_checklistPaths.opt_size = 15 * RL.scaleFactor
  GUI.elms.main_checklistPaths:init()
  
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

  GUI.New("main_checklistWindowPin", "Checklist", LayerIndex.Global, GUI.w - (24 * RL.scaleFactor) + (RL.scaleFactor * 5), topY, 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "", "h", 0)
  GUI.elms.main_checklistWindowPin.opt_size = 15 * RL.scaleFactor
  GUI.elms.main_checklistWindowPin:init()

  if RL.showButtonPanel then
    if SWSinstalled then GUI.New("main_btnOpenInExplorer", "Button", LayerIndex.Global, btn_pad_left, 66 * RL.scaleFactor, btn_w, btn_h, "Locate in Explorer/Finder", Global_OpenInExplorer) end
    
    GUI.New("main_btnOpenProject", "Button", LayerIndex.Global, btn_pad_left, 95 * RL.scaleFactor, btn_w, btn_h, "Open Project", Global_ShowProjectOpenDialog) 

    GUI.New("main_btnNewProject", "Button", LayerIndex.Global, btn_pad_left, btn_pad_top, btn_w, btn_h, "New Project", Global_NewProject) 
    GUI.New("main_btnNewProjectTab", "Button", LayerIndex.Global, btn_pad_left, btn_pad_top + btn_pad_add, (btn_w * 0.5) - 5, btn_h, "New Tab", Global_NewTab) 
    GUI.New("main_btnNewTabIgnoreTemplate", "Button", LayerIndex.Global, btn_pad_left + (btn_w * 0.5) + 5, btn_pad_top + btn_pad_add, (btn_w * 0.5) - 5, btn_h, "New Tab IT", Global_NewTabIgnoreDefaultTemplate)

    GUI.New("main_btnAddToFavorites", "Button", LayerIndex.SpecialOption, btn_pad_left, 33 * RL.scaleFactor, btn_w, btn_h, "Add to Favorites", Favorites_Add)
    GUI.elms.main_btnAddToFavorites.tooltip = "Add the selected file(s) to the [Favorites]"

    GUI.New("main_lblSaveNewVersion", "Label", LayerIndex.SaveAsNewVersion, GUI.w - (144 * RL.scaleFactor) + (RL.scaleFactor * 11), 255 * RL.scaleFactor, "Save as New Version", false, 3)
    GUI.New("main_checklistSaveAsNewVersion", "Checklist", LayerIndex.SaveAsNewVersion, GUI.w - (34 * RL.scaleFactor) + (RL.scaleFactor * 10), 252 * RL.scaleFactor + (RL.scaleFactor * 2), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "", "h", 0)
    GUI.elms.main_checklistSaveAsNewVersion.opt_size = 15 * RL.scaleFactor
    GUI.elms.main_checklistSaveAsNewVersion:init()
  
    GUI.New("main_lblWindowpin", "Label", LayerIndex.Global, GUI.w - (82 * RL.scaleFactor) + (RL.scaleFactor * 5), topY, "Keep open", false, 3)
  end

  function ButtonScaleUp() RL_ScaleInterfaceUp() end
  function ButtonScaleToggle() RL_ScaleInterfaceToggle() end
  function ButtonScaleDown() RL_ScaleInterfaceDown() end
  GUI.New("main_scaleInterfaceDown", "Button", LayerIndex.Global, GUI.w - (60 * RL.scaleFactor), GUI.h - (17.5 * RL.scaleFactor), refreshW * 0.4, refreshH, "-", ButtonScaleDown)
  GUI.New("main_scaleInterfaceToggle", "Button", LayerIndex.Global, GUI.w - (42 * RL.scaleFactor), GUI.h - (17.5 * RL.scaleFactor), refreshW * 0.4, refreshH, "[  ]", ButtonScaleToggle)
  GUI.New("main_scaleInterfaceUp", "Button", LayerIndex.Global, GUI.w - (24 * RL.scaleFactor), GUI.h - (17.5 * RL.scaleFactor), refreshW * 0.4, refreshH, "+", ButtonScaleUp)
  GUI.elms.main_scaleInterfaceDown.isLabelButton = true
  GUI.elms.main_scaleInterfaceToggle.isLabelButton = true
  GUI.elms.main_scaleInterfaceUp.isLabelButton = true
  GUI.elms.main_scaleInterfaceDown.font = GUI.fonts[2]
  GUI.elms.main_scaleInterfaceToggle.font = GUI.fonts[2]
  GUI.elms.main_scaleInterfaceUp.font = GUI.fonts[2]

  GUI.New("main_frame_footervertical_1", "Frame", LayerIndex.Global, GUI.w - (106 * RL.scaleFactor), GUI.h - (17 * RL.scaleFactor), 1.5 * RL.scaleFactor, 16 * RL.scaleFactor, false, false)
  GUI.New("main_frame_footervertical_2", "Frame", LayerIndex.Global, GUI.w - (60 * RL.scaleFactor), GUI.h - (17 * RL.scaleFactor), 1.5 * RL.scaleFactor, 16 * RL.scaleFactor, false, false)
  GUI.New("main_frame_footervertical_3", "Frame", LayerIndex.Global, GUI.w - (1.5 * pad_left), GUI.h - (17 * RL.scaleFactor), 1.5 * RL.scaleFactor, 16 * RL.scaleFactor, false, false)

  function ButtonScaleFontDown() RL_ScaleListboxFontSizeDown() end
  function ButtonScaleFontUp() RL_ScaleListboxFontSizeUp() end
  GUI.New("main_scaleFontDown", "Button", LayerIndex.Global, GUI.w - (102 * RL.scaleFactor), GUI.h - (16 * RL.scaleFactor), refreshW * 0.5, refreshH, "A", ButtonScaleFontDown)
  GUI.New("main_scaleFontUp", "Button", LayerIndex.Global, GUI.w - (84 * RL.scaleFactor), GUI.h - (17 * RL.scaleFactor), refreshW * 0.5, refreshH, "A", ButtonScaleFontUp)
  GUI.elms.main_scaleFontDown.isLabelButton = true
  GUI.elms.main_scaleFontUp.isLabelButton = true
  GUI.elms.main_scaleFontUp.font = GUI.fonts[2]

  function GUI.elms.main_checklistPaths:onmouseup()
    GUI.Checklist.onmouseup(self)
    Global_UpdatePathDisplayMode()
  end
  
  if SWSinstalled then RL_Draw_ThemeSlotSelector(0) end
  if JSAPIinstalled then RL_Draw_PreviewSection() end
end

local function RL_Draw_Frames()
  if RL.showButtonPanel then
    GUI.New("main_frame_top", "Frame", LayerIndex.Global, pad_left, listbox_top, GUI.w - pad_left, 2 * RL.scaleFactor, false, true)
    GUI.New("main_frame_side_2", "Frame", LayerIndex.Global, pad_left + listbox_w, 60 * RL.scaleFactor, GUI.w - pad_left - listbox_w, 2 * RL.scaleFactor, true, true)
    GUI.New("main_frame_side_3", "Frame", LayerIndex.Global, pad_left + listbox_w, 123 * RL.scaleFactor, GUI.w - pad_left - listbox_w, 2 * RL.scaleFactor, true, true)
    GUI.New("main_frame_side_4", "Frame", LayerIndex.Global, pad_left + listbox_w, 185 * RL.scaleFactor, GUI.w - pad_left - listbox_w, 2 * RL.scaleFactor, true, true)
    GUI.New("main_frame_side_5", "Frame", LayerIndex.Global, pad_left + listbox_w, 248 * RL.scaleFactor, GUI.w - pad_left - listbox_w, 2 * RL.scaleFactor, true, true)
    GUI.New("main_frame_side_6", "Frame", LayerIndex.Global, pad_left + listbox_w, 274 * RL.scaleFactor, GUI.w - pad_left - listbox_w, 2 * RL.scaleFactor, true, true)
    GUI.New("main_frame_bottom_1", "Frame", LayerIndex.Global, pad_left, GUI.h - (45* RL.scaleFactor), GUI.w - pad_left, 2 * RL.scaleFactor, false, true)
  else
    GUI.New("main_frame_top", "Frame", LayerIndex.Global, pad_left, listbox_top, GUI.w - (2 * pad_left), 2 * RL.scaleFactor, false, true)
    GUI.New("main_frame_bottom_1", "Frame", LayerIndex.Global, pad_left, GUI.h - (45 * RL.scaleFactor), GUI.w - (2 * pad_left), 2 * RL.scaleFactor, false, true)
  end
    
    GUI.New("main_frame_bottom_2", "Frame", LayerIndex.Global, 0, GUI.h - (19 * RL.scaleFactor), GUI.w, 1.5 * RL.scaleFactor, false, false)
    GUI.New("main_frame_vertical_1", "Frame", LayerIndex.Global, 3.7 * pathX + (RL.scaleFactor * 15), GUI.h - (42 * RL.scaleFactor), 1.5 * RL.scaleFactor, 22 * RL.scaleFactor, false, false)
    GUI.New("main_frame_vertical_2", "Frame", LayerIndex.Global, 7 * pathX + (RL.scaleFactor * 15), GUI.h - (42 * RL.scaleFactor), 1.5 * RL.scaleFactor, 22 * RL.scaleFactor, false, false)
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
  GUI.New("tab_recentProjects_btnFilterClear", "Button", LayerIndex.RecentProjects, filterX + filterW + 2, filterY + (filterH * 0.25), refreshW * 0.2, refreshH * 0.6, "x", Filter_RecentProject_Clear)
  GUI.elms.tab_recentProjects_btnFilterClear.isLabelButton = true

  GUI.New("tab_recentProjects_listbox", "Listbox", LayerIndex.RecentProjects, pad_left, listbox_top, listbox_w, listbox_h, "", true)
  GUI.elms.tab_recentProjects_listbox.tab_idx = 2
  GUI.elms.tab_recentProjects_listbox.list = RecentProjects.names
  GUI.Val("tab_recentProjects_listbox", {1})

  if RL.showButtonPanel then
    GUI.New("tab_recentProjects_btnLoadInTab", "Button", LayerIndex.RecentProjects, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_RecentProject)
    GUI.New("tab_recentProjects_btnLoad", "Button", LayerIndex.RecentProjects, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_RecentProject)
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
  GUI.New("tab_projectTemplates_btnRefresh", "Button", LayerIndex.ProjectTemplates, refreshX, refreshY, refreshW, refreshH, "Refresh", RefreshProjectTemplates)
  GUI.New("tab_projectTemplates_txtFilter", "Textbox", LayerIndex.ProjectTemplates, filterX, filterY, filterW, filterH, "", 8)
  GUI.elms.tab_projectTemplates_txtFilter.tab_idx = 1
  GUI.New("tab_projectTemplates_btnFilterClear", "Button", LayerIndex.ProjectTemplates, filterX + filterW + 2, filterY + (filterH * 0.25), refreshW * 0.2, refreshH * 0.6, "x", Filter_ProjectTemplate_Clear)
  GUI.elms.tab_projectTemplates_btnFilterClear.isLabelButton = true

  function GUI.elms.tab_projectTemplates_btnRefresh:onmouser_up()
    GUI.Button.onmouser_up(self)
    RL_Func_RebuildCache[GUI.elms.main_tabs.state].call()
  end

  if ShowSubfolderPanel(TabID.ProjectTemplates) then GUI.New("tab_projectTemplates_listbox", "Listbox", LayerIndex.ProjectTemplates, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  else GUI.New("tab_projectTemplates_listbox", "Listbox", LayerIndex.ProjectTemplates, pad_left, listbox_top, listbox_w, listbox_h, "", true) end
  GUI.elms.tab_projectTemplates_listbox.tab_idx = 2
  GUI.elms.tab_projectTemplates_listbox.list = ProjectTemplates.names
  GUI.Val("tab_projectTemplates_listbox", {1})
  
  if RL.showButtonPanel then
    GUI.New("tab_projectTemplates_btnLoadInTab", "Button", LayerIndex.ProjectTemplates, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_ProjectTemplate)
    GUI.New("tab_projectTemplates_btnLoad", "Button", LayerIndex.ProjectTemplates, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_ProjectTemplate)

    GUI.New("tab_projectTemplates_lblEditMode", "Label", LayerIndex.ProjectTemplates, GUI.w - (140 * RL.scaleFactor) + (RL.scaleFactor * 10), 255 * RL.scaleFactor, "Edit Template Mode", false, 3)
    GUI.New("tab_projectTemplates_checklistEditMode", "Checklist", LayerIndex.ProjectTemplates, GUI.w - (38 * RL.scaleFactor) + (RL.scaleFactor * 10), 252 * RL.scaleFactor + (RL.scaleFactor * 2), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "", "h", 0)
    GUI.elms.tab_projectTemplates_checklistEditMode.opt_size = 15 * RL.scaleFactor
    GUI.elms.tab_projectTemplates_checklistEditMode:init()

    function GUI.elms.tab_projectTemplates_checklistEditMode:onmousedown()
      RL.projectTemplateLoadMode = GUI.Val("tab_projectTemplates_checklistEditMode")
    end
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
            RL_WriteToFileCache(CacheFile.ProjectTemplates, TabParentSelectionIndex[TabID.ProjectTemplates], ProjectTemplates.paths, false)
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
  GUI.New("tab_trackTemplates_btnRefresh", "Button", LayerIndex.TrackTemplates, refreshX, refreshY, refreshW, refreshH, "Refresh", RefreshTrackTemplates)
  GUI.New("tab_trackTemplates_txtFilter", "Textbox", LayerIndex.TrackTemplates, filterX, filterY, filterW, filterH, "", 8)
  GUI.elms.tab_trackTemplates_txtFilter.tab_idx = 1
  GUI.New("tab_trackTemplates_btnFilterClear", "Button", LayerIndex.TrackTemplates, filterX + filterW + 2, filterY + (filterH * 0.25), refreshW * 0.2, refreshH * 0.6, "x", Filter_TrackTemplate_Clear)
  GUI.elms.tab_trackTemplates_btnFilterClear.isLabelButton = true
  
  function GUI.elms.tab_trackTemplates_btnRefresh:onmouser_up()
    GUI.Button.onmouser_up(self)
    RL_Func_RebuildCache[GUI.elms.main_tabs.state].call()
  end

  if ShowSubfolderPanel(TabID.TrackTemplates) then GUI.New("tab_trackTemplates_listbox", "Listbox", LayerIndex.TrackTemplates, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  else GUI.New("tab_trackTemplates_listbox", "Listbox", LayerIndex.TrackTemplates, pad_left, listbox_top, listbox_w, listbox_h, "", true) end
  GUI.elms.tab_trackTemplates_listbox.tab_idx = 2
  GUI.elms.tab_trackTemplates_listbox.list = TrackTemplates.names
  GUI.Val("tab_trackTemplates_listbox", {1})

  if RL.showButtonPanel then 
    GUI.New("tab_trackTemplates_btnInsertInTab", "Button", LayerIndex.TrackTemplates, btn_pad_left, btn_tab_top, btn_w, btn_h, "Insert in Tab", Load_TrackTemplateInTab)
    GUI.New("tab_trackTemplates_btnInsert", "Button", LayerIndex.TrackTemplates, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Insert", Load_TrackTemplate)
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
            RL_WriteToFileCache(CacheFile.TrackTemplates, TabParentSelectionIndex[TabID.TrackTemplates], TrackTemplates.paths, false)
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
    Load_TrackTemplate()
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
  GUI.New("tab_customProjects_btnRefresh", "Button", LayerIndex.CustomProjects, refreshX, refreshY, refreshW, refreshH, "Refresh", RefreshCustomProjects)
  GUI.New("tab_customProjects_txtFilter", "Textbox", LayerIndex.CustomProjects, filterX, filterY, filterW, filterH, "", 8)
  GUI.elms.tab_customProjects_txtFilter.tab_idx = 1
  GUI.New("tab_customProjects_btnFilterClear", "Button", LayerIndex.CustomProjects, filterX + filterW + 2, filterY + (filterH * 0.25), refreshW * 0.2, refreshH * 0.6, "x", Filter_CustomProjects_Clear)
  GUI.elms.tab_customProjects_btnFilterClear.isLabelButton = true

  function GUI.elms.tab_customProjects_btnRefresh:onmouser_up()
    GUI.Button.onmouser_up(self)
    RL_Func_RebuildCache[GUI.elms.main_tabs.state].call()
  end

  if ShowSubfolderPanel(TabID.CustomProjects) then GUI.New("tab_customProjects_listbox", "Listbox", LayerIndex.CustomProjects, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  else GUI.New("tab_customProjects_listbox", "Listbox", LayerIndex.CustomProjects, pad_left, listbox_top, listbox_w, listbox_h, "", true) end
  GUI.elms.tab_customProjects_listbox.tab_idx = 2
  GUI.elms.tab_customProjects_listbox.list = CustomProjects.names
  GUI.Val("tab_customProjects_listbox", {1})

  if RL.showButtonPanel then
    GUI.New("tab_customProjects_btnLoadInTab", "Button", LayerIndex.CustomProjects, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_CustomProject)
    GUI.New("tab_customProjects_btnLoad", "Button", LayerIndex.CustomProjects, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_CustomProject)
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
              CustomProjects.items, CustomProjects.names, CustomProjects.paths = {}, {}, {}
              local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.CustomProjects, TabParentSelectionIndex[TabID.CustomProjects])
              if cacheExists then FillCustomProjectsListboxBase(cacheTable)
              else
                FillCustomProjectsListboxBase(GetFiles(GUI.elms.tab_customProjects_subfolders.list[TabParentSelectionIndex[TabID.CustomProjects]], TabID.CustomProjects, FileTypes.rpp), 1)
                RL_WriteToFileCache(CacheFile.CustomProjects, TabParentSelectionIndex[TabID.CustomProjects], CustomProjects.paths, false)
              end
            end
          else
            CustomProjects.items, CustomProjects.names, CustomProjects.paths = {}, {}, {}
            FillCustomProjectsListboxBase(GetFiles(SubfolderPaths.customProjects[TabParentSelectionIndex[TabID.CustomProjects]], TabID.CustomProjects, FileTypes.rpp), 1)
            RL_WriteToFileCache(CacheFile.CustomProjects, TabParentSelectionIndex[TabID.CustomProjects], CustomProjects.paths, false)
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
  GUI.New("tab_projectLists_btnRefresh", "Button", LayerIndex.ProjectLists, refreshX, refreshY, refreshW, refreshH, "Refresh", RefreshProjectList)
  GUI.New("tab_projectLists_txtFilter", "Textbox", LayerIndex.ProjectLists, filterX, filterY, filterW, filterH, "", 8)
  GUI.elms.tab_projectLists_txtFilter.tab_idx = 1
  GUI.New("tab_projectLists_btnFilterClear", "Button", LayerIndex.ProjectLists, filterX + filterW + 2, filterY + (filterH * 0.25), refreshW * 0.2, refreshH * 0.6, "x", Filter_ProjectLists_Clear)
  GUI.elms.tab_projectLists_btnFilterClear.isLabelButton = true

  function GUI.elms.tab_projectLists_btnRefresh:onmouser_up()
    GUI.Button.onmouser_up(self)
    RL_Func_RebuildCache[GUI.elms.main_tabs.state].call()
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
        UpdateProjectListSelection()
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
  end

  function UpdateProjectListSelection()
    if GetSubListSize() > 0 then
      if TabParentSelectionIndex[TabID.ProjectLists] == 1 then
        RPL_FillProjectListBoxWithAll()
      else
        local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.ProjectLists, TabParentSelectionIndex[TabID.ProjectLists])
        if cacheExists then RPL_FillProjectListFromTable(cacheTable)
        else 
          RPL_FillProjectListBoxFromSelection()
          RL_WriteToFileCache(CacheFile.ProjectLists, TabParentSelectionIndex[TabID.ProjectLists], ProjectLists.projectPaths, false)
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
  GUI.New("tab_backups_btnRefresh", "Button", LayerIndex.Backups, refreshX, refreshY, refreshW, refreshH, "Refresh", RefreshBackups)
  GUI.New("tab_backups_txtFilter", "Textbox", LayerIndex.Backups, filterX, filterY, filterW, filterH, "", 8)
  GUI.elms.tab_backups_txtFilter.tab_idx = 1
  GUI.New("tab_backups_btnFilterClear", "Button", LayerIndex.Backups, filterX + filterW + 2, filterY + (filterH * 0.25), refreshW * 0.2, refreshH * 0.6, "x", Filter_Backups_Clear)
  GUI.elms.tab_backups_btnFilterClear.isLabelButton = true

  function GUI.elms.tab_backups_btnRefresh:onmouser_up()
    GUI.Button.onmouser_up(self)
    RL_Func_RebuildCache[GUI.elms.main_tabs.state].call()
  end

  if ShowSubfolderPanel(TabID.Backups) then GUI.New("tab_backups_listbox", "Listbox", LayerIndex.Backups, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  else GUI.New("tab_backups_listbox", "Listbox", LayerIndex.Backups, pad_left, listbox_top, listbox_w, listbox_h, "", true) end
  GUI.elms.tab_backups_listbox.tab_idx = 2
  GUI.elms.tab_backups_listbox.list = Backups.names
  GUI.Val("tab_backups_listbox", {1})

  if RL.showButtonPanel then
    GUI.New("tab_backups_btnLoadInTab", "Button", LayerIndex.Backups, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_BackupFile)
    GUI.New("tab_backups_btnLoad", "Button", LayerIndex.Backups, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_BackupFile)
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
              Backups.items, Backups.names, Backups.paths = {}, {}, {}
              local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.Backups, TabParentSelectionIndex[TabID.Backups])
              if cacheExists then FillBackupsListboxBase(cacheTable, 1)
              else
                FillBackupsListboxBase(GetFiles(GUI.elms.tab_backups_subfolders.list[TabParentSelectionIndex[TabID.Backups]], TabID.Backups, FileTypes.backup), 1)
                RL_WriteToFileCache(CacheFile.Backups, TabParentSelectionIndex[TabID.Backups], Backups.paths, false)
              end
            end
          else
            Backups.items, Backups.names, Backups.paths = {}, {}, {}
            FillBackupsListboxBase(GetFiles(SubfolderPaths.backups[TabParentSelectionIndex[TabID.Backups]], TabID.Backups, FileTypes.backup), 1)
            RL_WriteToFileCache(CacheFile.Backups, TabParentSelectionIndex[TabID.Backups], Backups.paths, false)
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
  GUI.New("tab_docs_btnRefresh", "Button", LayerIndex.Docs, refreshX, refreshY, refreshW, refreshH, "Refresh", RefreshDocs)
  GUI.New("tab_docs_txtFilter", "Textbox", LayerIndex.Docs, filterX, filterY, filterW, filterH, "", 8)
  GUI.elms.tab_docs_txtFilter.tab_idx = 1
  GUI.New("tab_docs_btnFilterClear", "Button", LayerIndex.Docs, filterX + filterW + 2, filterY + (filterH * 0.25), refreshW * 0.2, refreshH * 0.6, "x", Filter_Docs_Clear)
  GUI.elms.tab_docs_btnFilterClear.isLabelButton = true

  function GUI.elms.tab_docs_btnRefresh:onmouser_up()
    GUI.Button.onmouser_up(self)
    RL_Func_RebuildCache[GUI.elms.main_tabs.state].call()
  end

  if ShowSubfolderPanel(TabID.Docs) then GUI.New("tab_docs_listbox", "Listbox", LayerIndex.Docs, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  else GUI.New("tab_docs_listbox", "Listbox", LayerIndex.Docs, pad_left, listbox_top, listbox_w, listbox_h, "", true) end
  GUI.elms.tab_docs_listbox.tab_idx = 2
  GUI.elms.tab_docs_listbox.list = Docs.names
  GUI.Val("tab_docs_listbox", {1})

  if RL.showButtonPanel then GUI.New("tab_docs_btnOpen", "Button", LayerIndex.Docs, btn_pad_left, btn_tab_top + (20 * RL.scaleFactor) - (5 * RL.scaleFactor), btn_w, btn_h, "Open", Load_DocFile) end

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
              Docs.items, Docs.names, Docs.paths = {}, {}, {}
              local cacheExists, cacheTable = RL_ReadFromFileCache(CacheFile.TrackTemplates, TabParentSelectionIndex[TabID.Docs])
              if cacheExists then
                FillDocsListboxBase(cacheTable)
              else
                FillDocsListboxBase(GetFiles(GUI.elms.tab_docs_subfolders.list[TabParentSelectionIndex[TabID.Docs]], TabID.Docs, FileTypes.docs), 1)
                RL_WriteToFileCache(CacheFile.Docs, TabParentSelectionIndex[TabID.Docs], Docs.paths, false)
              end
            end
          else
            Docs.items, Docs.names, Docs.paths = {}, {}, {}
            FillDocsListboxBase(GetFiles(SubfolderPaths.docs[TabParentSelectionIndex[TabID.Docs]], TabID.Docs, FileTypes.docs), 1)
            RL_WriteToFileCache(CacheFile.Docs, TabParentSelectionIndex[TabID.Docs], Docs.paths, false)
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
  names = {},
  paths = {},
  filteredNames = {},
  filteredPaths = {}
}

local function RefreshFavorites()
  MsgDebug("-----------------------\nRefresh Favorites")
  GUI.Val("tab_favorites_categories", TabParentSelectionIndex[TabID.Favorites])
  FillFavoritesListbox()
  Filter_Favorites_Apply()
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
          if tabmode then reaper.Main_OnCommand(40859, 0) end -- New project tab
          reaper.Main_openProject(selectedEntry)
        elseif category == TabID.ProjectTemplates then
          if tabmode then
            reaper.Main_OnCommand(40859, 0) -- New project tab
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
      GUI.New("tab_favorites_lblEditMode", "Label", LayerIndex.Favorites, GUI.w - (140 * RL.scaleFactor) + (RL.scaleFactor * 10), 254 * RL.scaleFactor, "Edit Template Mode", false, 3)
      GUI.New("tab_favorites_checklistEditMode", "Checklist", LayerIndex.Favorites, GUI.w - (38 * RL.scaleFactor) + (RL.scaleFactor * 10), 252 * RL.scaleFactor + (RL.scaleFactor * 2), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "", "h", 0)
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
      GUI.New("tab_favorites_lblSaveNewVersion", "Label", LayerIndex.Favorites, GUI.w - (144 * RL.scaleFactor) + (RL.scaleFactor * 11), 255 * RL.scaleFactor, "Save as New Version", false, 3)
      GUI.New("tab_favorites_checklistSaveAsNewVersion", "Checklist", LayerIndex.Favorites, GUI.w - (34 * RL.scaleFactor) + (RL.scaleFactor * 10), 252 * RL.scaleFactor + (RL.scaleFactor * 2), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "", "h", 0)
      GUI.elms.tab_favorites_checklistSaveAsNewVersion.opt_size = 15 * RL.scaleFactor
      GUI.elms.tab_favorites_checklistSaveAsNewVersion:init()
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
  GUI.New("tab_favorites_btnFilterClear", "Button", LayerIndex.Favorites, filterX + filterW + 2, filterY + (filterH * 0.25), refreshW * 0.2, refreshH * 0.6, "x", Filter_Favorites_Clear)
  GUI.elms.tab_favorites_btnFilterClear.isLabelButton = true

  GUI.New("tab_favorites_categories", "Listbox", LayerIndex.Favorites, pad_left, listbox_top, listbox_w/3, listbox_h, "", true)
  GUI.elms.tab_favorites_categories.multi = false

  local FavoriteCategories = {}
  for i = 1, TabID.Docs do FavoriteCategories[i] = TabLabels[i] end
  GUI.elms.tab_favorites_categories.list = FavoriteCategories

  GUI.New("tab_favorites_listbox", "Listbox", LayerIndex.Favorites, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  GUI.elms.tab_favorites_listbox.list = Favorites.names
  GUI.elms.tab_favorites_listbox.list.tab_idx = 2
  GUI.Val("tab_favorites_listbox", {1})
  
  if RL.showButtonPanel then 
    GUI.New("tab_favorites_btnRemoveFromFavorites", "Button", LayerIndex.Favorites, btn_pad_left, 33 * RL.scaleFactor, btn_w, btn_h, "Remove from Favorites", RL_ConfirmDialog_RemoveFavoritesEntry)
    GUI.elms.tab_favorites_btnRemoveFromFavorites.tooltip = "Remove the selected file(s) from the [Favorites]"
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

  function RL_Context_Favorites()
    if GetMainListSize() > 0 then
      gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
      local vals = GetSelectionTable(GUI.Val("tab_favorites_listbox"))
      if #vals == 0 then
        if gfx.showmenu("1 - Clear entire list") == 1 then RL_ConfirmDialog_ClearFavoritesList() end
      else
        local RMBmenu = gfx.showmenu("1 - Remove selected entries|#|2 - Clear entire list")
        if RMBmenu == 1 then RL_ConfirmDialog_RemoveFavoritesEntry()
          elseif RMBmenu == 2 then RL_ConfirmDialog_ClearFavoritesList()
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
    Favorites.items, Favorites.names, Favorites.paths = {}, {}, {}
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
        Favorites.names[#Favorites.names + 1] = RemoveExtension(RemoveWhiteSpaces(GetFilenameWithoutPath(v)), fileExtension)
        Favorites.paths[#Favorites.paths + 1] = v
        Favorites.items[#Favorites.items + 1] = { name = RemoveExtension(RemoveWhiteSpaces(GetFilenameWithoutPath(v)), fileExtension), path = v}
      end
      TabSelectionIndex[TabID.Favorites] = 1
      GUI.Val("tab_favorites_listbox", {1})
      Global_UpdatePathDisplayMode()
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
        if FilterActive.RecentProjects then selectedProject = RecentProjects.filteredPaths[vals[p]]
        else selectedProject = RecentProjects.paths[vals[p]] end
        if selectedProject ~= nil then favEntries[#favEntries + 1] = selectedProject end
      end
    end
  -- project templates
  elseif currentTab == TabID.ProjectTemplates then
    if GetMainListSize() > 0 then
      local vals = GetSelectionTable(GUI.Val("tab_projectTemplates_listbox"))
      for p = 1, #vals do 
        if FilterActive.ProjectTemplates then selectedProjectTemplate = ProjectTemplates.filteredPaths[vals[p]]
        else selectedProjectTemplate = ProjectTemplates.paths[vals[p]] end
        if selectedProjectTemplate ~= nil then favEntries[#favEntries + 1] = selectedProjectTemplate end
      end
    end
  -- track templates
  elseif currentTab == TabID.TrackTemplates then
    if GetMainListSize() > 0 then
      local selectedTrackTemplate
      local vals = GetSelectionTable(GUI.Val("tab_trackTemplates_listbox"))
      for p = 1, #vals do
        if FilterActive.TrackTemplates then selectedTrackTemplate = TrackTemplates.filteredPaths[vals[p]]
        else selectedTrackTemplate = TrackTemplates.paths[vals[p]] end
        if selectedTrackTemplate ~= nil then favEntries[#favEntries + 1] = selectedTrackTemplate end
      end
    end
  -- projects
  elseif currentTab == TabID.CustomProjects then
    if GetMainListSize() > 0 then
      local vals = GetSelectionTable(GUI.Val("tab_customProjects_listbox"))
      for p = 1, #vals do
        if FilterActive.CustomProjects then selectedProject = ustomProjects.filteredPaths[vals[p]]
        else selectedProject = CustomProjects.paths[vals[p]] end
        if selectedProject ~= nil then favEntries[#favEntries + 1] = selectedProject end
      end
    end
  -- project lists
  elseif currentTab == TabID.ProjectLists then
    if GetMainListSize() > 0 then
      local vals = GetSelectionTable(GUI.Val("tab_projectLists_listboxProjects"))
      for p = 1, #vals do
        if FilterActive.ProjectLists then selectedProjectListProject = RemoveWhiteSpaces(ProjectLists.filteredProjectPaths[vals[p]])
        else selectedProjectListProject = RemoveWhiteSpaces(ProjectLists.projectPaths[vals[p]]) end
        if selectedProjectListProject ~= nil then favEntries[#favEntries + 1] = selectedProjectListProject end
      end
    end
  -- backups
  elseif currentTab == TabID.Backups then
    if GetMainListSize() > 0 then
      local vals = GetSelectionTable(GUI.Val("tab_backups_listbox"))
        for p = 1, #vals do
          if FilterActive.Backups then selectedBackupFile = RemoveWhiteSpaces(Backups.filteredPaths[vals[p]])
          else selectedBackupFile = RemoveWhiteSpaces(Backups.paths[vals[p]]) end
          if selectedBackupFile ~= nil then favEntries[#favEntries + 1] = selectedBackupFile end
      end
    end
  -- docs
  elseif currentTab == TabID.Docs then
    if GetMainListSize() > 0 then
      local selectedDocFile
      local vals = GetSelectionTable(GUI.Val("tab_docs_listbox"))
      for p = 1, #vals do
        if FilterActive.Docs then selectedDocFile = Docs.filteredPaths[vals[p]]
        else selectedDocFile = Docs.paths[vals[p]] end
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
            if FilterActive.Favorites then selectedFavoritesFile = Favorites.filteredPaths[selectionTable[s]] 
            else selectedFavoritesFile = Favorites.paths[selectionTable[s]] end
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

    GUI.New("colors_btnResetColors", "Button", LayerIndex.Layout, 40 * pad_left, 4.7 * RL.scaleFactor, 68 * RL.scaleFactor, 18 * RL.scaleFactor, "Reset Colors", RL_Reset_Colors)
    GUI.elms.colors_btnResetColors.tooltip = "Reset color scheme to default colors"

    GUI.New("colors_lbl_elmFill", "Label", LayerIndex.Layout, 50 * pad_left, 1.6 * 36 * RL.scaleFactor, "Highlight color", false, 3)
    GUI.New("colors_frame_elmFill", "Frame", LayerIndex.Layout, 44 * pad_left, 1.6 * 36 * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor)
    GUI.elms.colors_frame_elmFill.tooltip = "Set a custom highlight color"

    GUI.New("colors_lbl_txt", "Label", LayerIndex.Layout, 50 * pad_left, 2.1 * 36 * RL.scaleFactor, "Text color", false, 3)
    GUI.New("colors_frame_txt", "Frame", LayerIndex.Layout, 44 * pad_left, 2.1 * 36 * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor)
    GUI.elms.colors_frame_txt.tooltip = "Set a custom text color"

    GUI.New("colors_lbl_elmBg", "Label", LayerIndex.Layout, 50 * pad_left, 2.6 * 36 * RL.scaleFactor, "Element Background color", false, 3)
    GUI.New("colors_frame_elmBg", "Frame", LayerIndex.Layout, 44 * pad_left, 2.6 * 36 * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor)
    GUI.elms.colors_frame_elmBg.tooltip = "Set a custom element background color"

    GUI.New("colors_lbl_wndBg", "Label", LayerIndex.Layout, 50 * pad_left, 3.1 * 36 * RL.scaleFactor, "Window Background color", false, 3)
    GUI.New("colors_frame_wndBg", "Frame", LayerIndex.Layout, 44 * pad_left, 3.1 * 36 * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor)
    GUI.elms.colors_frame_wndBg.tooltip = "Set a custom window background color"

    function GUI.elms.colors_frame_elmFill:draw()
      GUI.Frame.draw(self)
      DrawFrameColor(self)
    end
    
    function GUI.elms.colors_frame_elmFill:onmouseup() 
      OpenColorPicker(self, "elm_fill")
      DrawFrameColor(self)
    end

    function GUI.elms.colors_frame_txt:draw()
      GUI.Frame.draw(self)
      DrawFrameColor(self)
    end
    
    function GUI.elms.colors_frame_txt:onmouseup() 
      OpenColorPicker(self, "txt")
      DrawFrameColor(self)
    end

    function GUI.elms.colors_frame_wndBg:draw()
      GUI.Frame.draw(self)
      DrawFrameColor(self)
    end
    
    function GUI.elms.colors_frame_wndBg:onmouseup() 
      OpenColorPicker(self, "wnd_bg")
      DrawFrameColor(self)
    end

    function GUI.elms.colors_frame_elmBg:draw()
      GUI.Frame.draw(self)
      DrawFrameColor(self)
    end
    
    function GUI.elms.colors_frame_elmBg:onmouseup() 
      OpenColorPicker(self, "elm_bg")
      DrawFrameColor(self)
    end

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

  GUI.New("layout_frame_top", "Frame", LayerIndex.Layout, 0, listbox_top, GUI.w, 2 * RL.scaleFactor, false, true)
  GUI.New("layout_frame_left1", "Frame", LayerIndex.Layout, 0, 4.4 * 36 * RL.scaleFactor, 40.4 * pad_left, RL.scaleFactor, false, true)
  GUI.New("layout_frame_vertical", "Frame", LayerIndex.Layout, 40 * pad_left, listbox_top + 2 * RL.scaleFactor, 1.5 * RL.scaleFactor, 32 * pad_left, false, true)
  GUI.New("layout_frame_right1", "Frame", LayerIndex.Layout, 40 * pad_left, 1.45 * 36 * RL.scaleFactor, GUI.w, RL.scaleFactor, false, true)
  GUI.New("layout_frame_right2", "Frame", LayerIndex.Layout, 40 * pad_left, 3.6 * 36 * RL.scaleFactor, GUI.w, RL.scaleFactor, false, true)
  
  GUI.New("layout_checklistShowButtonPanel", "Checklist", LayerIndex.Layout, 44 * pad_left, 34 * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "", "h", 0)
  GUI.New("layout_lblShowButtonPanel", "Label", LayerIndex.Layout, 50 * pad_left, 34 * RL.scaleFactor, "Show (right) Main Button Panel", false, 3)
  GUI.elms.layout_checklistShowButtonPanel.opt_size = 15 * RL.scaleFactor
  GUI.elms.layout_checklistShowButtonPanel:init()

  if ConfigFlags.enableHiDPIModeOptions then 
    GUI.New("layout_menuRetinaMode", "Menubox", LayerIndex.Layout, GUI.w - (72 * RL.scaleFactor), 6 * RL.scaleFactor, 65 * RL.scaleFactor, 15 * RL.scaleFactor, "HiDPI Mode","Auto,Default,Retina")
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

  GUI.New("layout_lblShowSubfolderPanel", "Label", LayerIndex.Layout, 2 * pad_left, 34 * RL.scaleFactor, "Show (left) Sub Panels", false, 3)
  GUI.New("layout_checklistShowSubfolderPanel", "Checklist", LayerIndex.Layout, 2 * pad_left, 1.5 * 34 * RL.scaleFactor, 126 * RL.scaleFactor, 106 * RL.scaleFactor, "", "Project Templates,Track Templates,Projects,Project Lists,Backups,Docs", "v", 5)
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
  local paths_textBoxWidth = 174
  local paths_buttonText = "Set"

  if JSAPIinstalled then
    GUI.New("paths_btnProjectTemplatesBrowse", "Button", LayerIndex.Paths, GUI.w - 84 * RL.scaleFactor, 1.25 * (30 * RL.scaleFactor), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "+", Path_Browse_ProjectTemplateFolder)
    GUI.New("paths_btnTrackTemplatesBrowse", "Button", LayerIndex.Paths, GUI.w - 84 * RL.scaleFactor, 2.05 * (30 * RL.scaleFactor), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "+", Path_Browse_TrackTemplateFolder)
    GUI.New("paths_btnCustomProjectsBrowse", "Button", LayerIndex.Paths, GUI.w - 84 * RL.scaleFactor, 2.85 * (30 * RL.scaleFactor), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "+", Path_Browse_CustomProjectFolder)
    GUI.New("paths_btnProjectListsBrowse", "Button", LayerIndex.Paths, GUI.w - 84 * RL.scaleFactor, 3.65 * (30 * RL.scaleFactor), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "+", Path_Browse_ProjectListFolder)
    GUI.New("paths_btnBackupsBrowse", "Button", LayerIndex.Paths, GUI.w - 84 * RL.scaleFactor, 4.45 * (30 * RL.scaleFactor), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "+", Path_Browse_BackupsFolder)
    GUI.New("paths_btnDocsBrowse", "Button", LayerIndex.Paths, GUI.w - 84 * RL.scaleFactor, 5.25 * (30 * RL.scaleFactor), 15 * RL.scaleFactor, 15 * RL.scaleFactor, "+", Path_Browse_DocsFolder)
    paths_textBoxWidth = 192
  end

  if ConfigFlags.enableFileCaching or ConfigFlags.enableSubfolderCaching then
    paths_buttonText = "Set / Scan" 
    GUI.New("paths_btnRescanAllPaths", "Button", LayerIndex.Paths, GUI.w - (65 * RL.scaleFactor), 4.7 * RL.scaleFactor, 55 * RL.scaleFactor, 18 * RL.scaleFactor, "Rescan all")
    GUI.elms.paths_btnRescanAllPaths.tooltip = "Rebuild the file cache for all tabs"

    function GUI.elms.paths_btnRescanAllPaths:onmousedown()
      RL_ShowProgressIndicator(1, true)
      GUI.Button.onmousedown(self)
      reaper.defer(RL_RescanAllPaths)
    end
  end

  GUI.New("paths_frame_top", "Frame", LayerIndex.Paths, 0, listbox_top, GUI.w, 2 * RL.scaleFactor, false, true)
  GUI.New("paths_txtProjectTemplatesPath", "Textbox", LayerIndex.Paths, 105 * RL.scaleFactor, 1.2 * (30 * RL.scaleFactor), GUI.w - paths_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, "Project Templates", 12)
  GUI.New("paths_btnProjectTemplatesSet", "Button", LayerIndex.Paths, GUI.w - 64 * RL.scaleFactor, 1.25 * (30 * RL.scaleFactor), 55 * RL.scaleFactor, 15 * RL.scaleFactor, paths_buttonText)
  function GUI.elms.paths_btnProjectTemplatesSet:onmousedown()
    RL_ShowProgressIndicator(TabID.ProjectTemplates, true)
    GUI.Button.onmousedown(self)
    reaper.defer(Path_Set_ProjectTemplateFolder)
  end

  GUI.New("paths_txtTrackTemplatesPath", "Textbox", LayerIndex.Paths, 105 * RL.scaleFactor, 2.0 * (30 * RL.scaleFactor), GUI.w - paths_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, "Track Templates", 12)
  GUI.New("paths_btnTrackTemplatesSet", "Button", LayerIndex.Paths, GUI.w - 64 * RL.scaleFactor, 2.05 * (30 * RL.scaleFactor), 55 * RL.scaleFactor, 15 * RL.scaleFactor, paths_buttonText)
  function GUI.elms.paths_btnTrackTemplatesSet:onmousedown()
    RL_ShowProgressIndicator(TabID.TrackTemplates, true)
    GUI.Button.onmousedown(self)
    reaper.defer(Path_Set_TrackTemplateFolder)
  end

  GUI.New("paths_txtCustomProjectsPath", "Textbox", LayerIndex.Paths, 105 * RL.scaleFactor, 2.8 * (30 * RL.scaleFactor), GUI.w - paths_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, "Projects", 12)
  GUI.New("paths_btnCustomProjectsSet", "Button", LayerIndex.Paths, GUI.w - 64 * RL.scaleFactor, 2.85 * (30 * RL.scaleFactor), 55 * RL.scaleFactor, 15 * RL.scaleFactor, paths_buttonText)
  function GUI.elms.paths_btnCustomProjectsSet:onmousedown()
    RL_ShowProgressIndicator(TabID.CustomProjects, true)
    GUI.Button.onmousedown(self)
    reaper.defer(Path_Set_CustomProjectFolder)
  end

  GUI.New("paths_txtProjectsListsPath", "Textbox", LayerIndex.Paths, 105 * RL.scaleFactor, 3.6 * (30 * RL.scaleFactor), GUI.w - paths_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, "Project Lists", 12)
  GUI.New("paths_btnProjectListsSet", "Button", LayerIndex.Paths, GUI.w - 64 * RL.scaleFactor, 3.65 * (30 * RL.scaleFactor), 55 * RL.scaleFactor, 15 * RL.scaleFactor, paths_buttonText)
  function GUI.elms.paths_btnProjectListsSet:onmousedown()
    RL_ShowProgressIndicator(TabID.ProjectLists, true)
    GUI.Button.onmousedown(self)
    reaper.defer(Path_Set_ProjectListFolder)
  end

  GUI.New("paths_txtBackupsPath", "Textbox", LayerIndex.Paths, 105 * RL.scaleFactor, 4.4 * (30 * RL.scaleFactor), GUI.w - paths_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, "Backups", 12)
  GUI.New("paths_btnBackupsSet", "Button", LayerIndex.Paths, GUI.w - 64 * RL.scaleFactor, 4.45 * (30 * RL.scaleFactor), 55 * RL.scaleFactor, 15 * RL.scaleFactor, paths_buttonText)
  function GUI.elms.paths_btnBackupsSet:onmousedown()
    RL_ShowProgressIndicator(TabID.Backups, true)
    GUI.Button.onmousedown(self)
    reaper.defer(Path_Set_BackupsFolder)
  end

  GUI.New("paths_txtDocsPath", "Textbox", LayerIndex.Paths, 105 * RL.scaleFactor, 5.2 * (30 * RL.scaleFactor), GUI.w - paths_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, "Docs", 12)
  GUI.New("paths_btnDocsSet", "Button", LayerIndex.Paths, GUI.w - 64 * RL.scaleFactor, 5.25 * (30 * RL.scaleFactor), 55 * RL.scaleFactor, 15 * RL.scaleFactor, paths_buttonText)
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
  reaper.SetExtState(appname, "scan_tracktemplates_limits", FileScanSettings.trackTemplates_maxSubDirDepth  .. "," .. FileScanSettings.trackTemplates_maxSubDirRange, 1)
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
  GUI.New("scansettings_lblExcludedFolders", "Label", LayerIndex.ScanSettings, 32 * pad_left, 7 * RL.scaleFactor, "Excluded folder names | Depth limit | Range limit", false, 4)
  GUI.New("scansettings_frame_top", "Frame", LayerIndex.ScanSettings, 0, listbox_top, GUI.w, 2 * RL.scaleFactor, false, true)
  
  GUI.New("scansettings_txtProjectTemplates", "Textbox", LayerIndex.ScanSettings, 105 * RL.scaleFactor, 1.2 * (30 * RL.scaleFactor), GUI.w - 220 * RL.scaleFactor, 20 * RL.scaleFactor, "Project Templates", 12)
  GUI.New("scansettings_txtProjectTemplates_MaxScanDepth", "Textbox", LayerIndex.ScanSettings, GUI.w - 110 * RL.scaleFactor, 1.2 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_txtProjectTemplates_MaxScanSubDirs", "Textbox", LayerIndex.ScanSettings, GUI.w - 78 * RL.scaleFactor, 1.2 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_btnProjectTemplates", "Button", LayerIndex.ScanSettings, GUI.w - 44 * RL.scaleFactor, 1.25 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 15 * RL.scaleFactor, "Set", Set_ExcludedFolders_ProjectTemplates)

  GUI.New("scansettings_txtTrackTemplates", "Textbox", LayerIndex.ScanSettings, 105 * RL.scaleFactor, 2.0 * (30 * RL.scaleFactor), GUI.w - 220 * RL.scaleFactor, 20 * RL.scaleFactor, "Track Templates", 12)
  GUI.New("scansettings_txtTrackTemplates_MaxScanDepth", "Textbox", LayerIndex.ScanSettings, GUI.w - 110 * RL.scaleFactor, 2.0 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_txtTrackTemplates_MaxScanSubDirs", "Textbox", LayerIndex.ScanSettings, GUI.w - 78 * RL.scaleFactor, 2.0 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_btnTrackTemplates", "Button", LayerIndex.ScanSettings, GUI.w - 44 * RL.scaleFactor, 2.05 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 15 * RL.scaleFactor, "Set", Set_ExcludedFolders_TrackTemplates)

  GUI.New("scansettings_txtCustomProjects", "Textbox", LayerIndex.ScanSettings, 105 * RL.scaleFactor, 2.8 * (30 * RL.scaleFactor), GUI.w - 220 * RL.scaleFactor, 20 * RL.scaleFactor, "Projects", 12)
  GUI.New("scansettings_txtCustomProjects_MaxScanDepth", "Textbox", LayerIndex.ScanSettings, GUI.w - 110 * RL.scaleFactor, 2.8 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_txtCustomProjects_MaxScanSubDirs", "Textbox", LayerIndex.ScanSettings, GUI.w - 78 * RL.scaleFactor, 2.8 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_btnCustomProjects", "Button", LayerIndex.ScanSettings, GUI.w - 44 * RL.scaleFactor, 2.85 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 15 * RL.scaleFactor, "Set", Set_ExcludedFolders_CustomProjects)

  GUI.New("scansettings_txtProjectsLists", "Textbox", LayerIndex.ScanSettings, 105 * RL.scaleFactor, 3.6 * (30 * RL.scaleFactor), GUI.w - 220 * RL.scaleFactor, 20 * RL.scaleFactor, "Project Lists", 12)
  GUI.New("scansettings_txtProjectsLists_MaxScanDepth", "Textbox", LayerIndex.ScanSettings, GUI.w - 110 * RL.scaleFactor, 3.6 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_txtProjectsLists_MaxScanSubDirs", "Textbox", LayerIndex.ScanSettings, GUI.w - 78 * RL.scaleFactor, 3.6 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_btnProjectLists", "Button", LayerIndex.ScanSettings, GUI.w - 44 * RL.scaleFactor, 3.65 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 15 * RL.scaleFactor, "Set", Set_ExcludedFolders_ProjectLists)

  GUI.New("scansettings_txtBackups", "Textbox", LayerIndex.ScanSettings, 105 * RL.scaleFactor, 4.4 * (30 * RL.scaleFactor), GUI.w - 220 * RL.scaleFactor, 20 * RL.scaleFactor, "Backups", 12)
  GUI.New("scansettings_txtBackups_MaxScanDepth", "Textbox", LayerIndex.ScanSettings, GUI.w - 110 * RL.scaleFactor, 4.4 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_txtBackups_MaxScanSubDirs", "Textbox", LayerIndex.ScanSettings, GUI.w - 78 * RL.scaleFactor, 4.4 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_btnBackups", "Button", LayerIndex.ScanSettings, GUI.w - 44 * RL.scaleFactor, 4.45 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 15 * RL.scaleFactor, "Set", Set_ExcludedFolders_Backups)
  
  GUI.New("scansettings_txtDocs", "Textbox", LayerIndex.ScanSettings, 105 * RL.scaleFactor, 5.2 * (30 * RL.scaleFactor), GUI.w - 220 * RL.scaleFactor, 20 * RL.scaleFactor, "Docs", 12)
  GUI.New("scansettings_txtDocs_MaxScanDepth", "Textbox", LayerIndex.ScanSettings, GUI.w - 110 * RL.scaleFactor, 5.2 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_txtDocs_MaxScanSubDirs", "Textbox", LayerIndex.ScanSettings, GUI.w - 78 * RL.scaleFactor, 5.2 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  GUI.New("scansettings_btnDocs", "Button", LayerIndex.ScanSettings, GUI.w - 44 * RL.scaleFactor, 5.25 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 15 * RL.scaleFactor, "Set", Set_ExcludedFolders_Docs)

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
  GUI.New("actions_frame_top", "Frame", LayerIndex.Actions, 0, listbox_top, GUI.w, 2 * RL.scaleFactor, false, true)

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

  GUI.New("actions_lblActionsHeader", "Label", LayerIndex.Actions, 32 * pad_left, 7 * RL.scaleFactor, "Set an Action Command ID to trigger after:", false, 4)
  GUI.New("actions_txtFollowAction_NewProject", "Textbox", LayerIndex.Actions, 32 * pad_left, 1.2 * (30 * RL.scaleFactor), GUI.w - 175 * RL.scaleFactor, 20 * RL.scaleFactor, "New Project", 20)
  GUI.New("actions_btnFollowAction_NewProject", "Button", LayerIndex.Actions, GUI.w - 44 * RL.scaleFactor, 1.2 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 18 * RL.scaleFactor, "Set", Action_Set_NewProject)

  GUI.New("actions_txtFollowAction_NewTab", "Textbox", LayerIndex.Actions, 32 * pad_left, 2.0 * (30 * RL.scaleFactor), GUI.w - 175 * RL.scaleFactor, 20 * RL.scaleFactor, "New Tab", 20)
  GUI.New("actions_btnFollowAction_NewTab", "Button", LayerIndex.Actions, GUI.w - 44 * RL.scaleFactor, 2.0 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 18 * RL.scaleFactor, "Set", Action_Set_NewTab)

  GUI.New("actions_txtFollowAction_LoadProject", "Textbox", LayerIndex.Actions, 32 * pad_left, 2.8 * (30 * RL.scaleFactor), GUI.w - 175 * RL.scaleFactor, 20 * RL.scaleFactor, "Load Project", 20)
  GUI.New("actions_btnFollowAction_LoadProject", "Button", LayerIndex.Actions, GUI.w - 44 * RL.scaleFactor, 2.8 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 18 * RL.scaleFactor, "Set", Action_Set_LoadProject)

  GUI.New("actions_txtFollowAction_LoadProjectInTab", "Textbox", LayerIndex.Actions, 32 * pad_left, 3.6 * (30 * RL.scaleFactor), GUI.w - 175 * RL.scaleFactor, 20 * RL.scaleFactor, "Load Project in Tab", 20)
  GUI.New("actions_btnFollowAction_LoadProjectInTab", "Button", LayerIndex.Actions, GUI.w - 44 * RL.scaleFactor, 3.6 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 18 * RL.scaleFactor, "Set", Action_Set_LoadProjectInTab)
  
  GUI.New("actions_txtFollowAction_LoadProjectTemplate", "Textbox", LayerIndex.Actions, 32 * pad_left, 4.4 * (30 * RL.scaleFactor), GUI.w - 175 * RL.scaleFactor, 20 * RL.scaleFactor, "Load Project Template", 20)
  GUI.New("actions_btnFollowAction_LoadProjectTemplate", "Button", LayerIndex.Actions, GUI.w - 44 * RL.scaleFactor, 4.4 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 18 * RL.scaleFactor, "Set", Action_Set_ProjectTemplate)
  
  GUI.New("actions_txtFollowAction_InsertTrackTemplate", "Textbox", LayerIndex.Actions, 32 * pad_left, 5.2 * (30 * RL.scaleFactor), GUI.w - 175 * RL.scaleFactor, 20 * RL.scaleFactor, "Insert Track Template", 20)
  GUI.New("actions_btnFollowAction_InsertTrackTemplate", "Button", LayerIndex.Actions, GUI.w - 44 * RL.scaleFactor, 5.2 * (30 * RL.scaleFactor), 30 * RL.scaleFactor, 18 * RL.scaleFactor, "Set", Action_Set_TrackTemplate)

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
  GUI.New("options_checklistPromptToSave", "Checklist", LayerIndex.Options, 2 * pad_left, 10 + (1.45 * 50 - 18) * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "Prompt to save on new project", "v", 0)
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
  GUI.New("options_frame_top", "Frame", LayerIndex.Options, 0, listbox_top, GUI.w, 2 * RL.scaleFactor, false, true)
  GUI.New("options_frame_2", "Frame", LayerIndex.Options, 0, 10 + 48 * RL.scaleFactor, GUI.w, 2 * RL.scaleFactor, false, true)
  GUI.New("options_frame_3", "Frame", LayerIndex.Options, 0, 10 + 93 * RL.scaleFactor, GUI.w, 2 * RL.scaleFactor, false, true)
  GUI.New("options_frame_4", "Frame", LayerIndex.Options, 0, 10 + 119 * RL.scaleFactor, GUI.w, 2 * RL.scaleFactor, false, true)

  local doubleClickEntries = "Show Prompt,Load,Load in Tab"
  if JSAPIinstalled then doubleClickEntries = "Show Prompt,Load,Load in Tab,Audio Preview" end

  if osversion:find("Win") then GUI.New("options_menuDoubleClick", "Menubox", LayerIndex.Options, 33.5 * pad_left, 10 + (0.95 * 50 - 18) * RL.scaleFactor, 91 * RL.scaleFactor, 15 * RL.scaleFactor, "Double Click Behavior", doubleClickEntries, 8)
  else GUI.New("options_menuDoubleClick", "Menubox", LayerIndex.Options, 35 * pad_left, 10 + (0.95 * 50 - 18) * RL.scaleFactor, 91 * RL.scaleFactor, 15 * RL.scaleFactor, "Double Click Behavior", doubleClickEntries, 8) end
  GUI.elms.options_menuDoubleClick.align = 1

  function GUI.elms.options_menuDoubleClick:onmousedown()
    GUI.Menubox.onmouseup(self)
    reaper.SetExtState(appname, "mouse_doubleclick", GUI.Val("options_menuDoubleClick"), 1)
  end

  function GUI.elms.options_menuDoubleClick:onwheel()
    GUI.Menubox.onwheel(self)
    reaper.SetExtState(appname, "mouse_doubleclick", GUI.Val("options_menuDoubleClick"), 1)
  end

  GUI.New("options_checklistShowPathsInStatusbar", "Checklist", LayerIndex.Options, 2 * pad_left, 10 + (2.9 * 50 - 18) * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "Show paths in status bar", "v", 0)
  GUI.elms.options_checklistShowPathsInStatusbar.opt_size = 15 * RL.scaleFactor
  GUI.elms.options_checklistShowPathsInStatusbar:init()
  GUI.New("options_menuShowPathsInStatusbar", "Menubox", LayerIndex.Options, 44 * pad_left, 10 + (2.9 * 50 - 18) * RL.scaleFactor, 98 * RL.scaleFactor, 15 * RL.scaleFactor, "", "Path and File,Path only", 8)
  GUI.elms.options_menuShowPathsInStatusbar.align = 1

  function GUI.elms.options_menuShowPathsInStatusbar:onmousedown()
    GUI.Menubox.onmouseup(self)
    reaper.SetExtState(appname, "window_showpathsinstatusbarmode", GUI.Val("options_menuShowPathsInStatusbar"), 1)
  end

  function GUI.elms.options_menuShowPathsInStatusbar:onwheel()
    GUI.Menubox.onwheel(self)
    reaper.SetExtState(appname, "window_showpathsinstatusbarmode", GUI.Val("options_menuShowPathsInStatusbar"), 1)
  end

  GUI.New("options_checklistOpenPropertiesOnNewProject", "Checklist", LayerIndex.Options, 2 * pad_left, 10 + (1.85 * 50 - 18) * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "Open properties on new project", "v", 0)
  GUI.elms.options_checklistOpenPropertiesOnNewProject.opt_size = 15 * RL.scaleFactor
  GUI.elms.options_checklistOpenPropertiesOnNewProject:init()

  GUI.New("options_checklistWindowToggle", "Checklist", LayerIndex.Options, 2 * pad_left, 10 + (2.35 * 50 - 18) * RL.scaleFactor, 15 * RL.scaleFactor, 15 * RL.scaleFactor, "", "Enable window toggle key", "v", 0)
  GUI.elms.options_checklistWindowToggle.opt_size = 15 * RL.scaleFactor
  GUI.elms.options_checklistWindowToggle:init()

  GUI.New("options_txtWindowToggleShortcut", "Textbox", LayerIndex.Options, 44 * pad_left, 10 + (2.35 * 50 - 20) * RL.scaleFactor, 30 * RL.scaleFactor, 20 * RL.scaleFactor, "", 8)
  function GUI.elms.options_txtWindowToggleShortcut:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end

  function GUI.elms.options_txtWindowToggleShortcut:lostfocus()
    RL.keyInputActive = true
    GUI.Textbox.lostfocus(self)
  end

  GUI.New("options_btnWindowToggleSet", "Button", LayerIndex.Options, 54 * pad_left, 10 + (2.35 * 50 - 18) * RL.scaleFactor, 30 * RL.scaleFactor, 16 * RL.scaleFactor, "Set", SetWindowToggleShortcut)

  if SWSinstalled then RL_Draw_SavePromptOption() end
end

----------------------
-- Key Shortcut Toggle
----------------------
function SetWindowToggleShortcut()
  local charValue = string.byte(GUI.Val("options_txtWindowToggleShortcut"))
  RL.windowToggleShortcut = charValue
  reaper.SetExtState(appname, "window_toggleshortcut", tostring(charValue), 1)
  if GUI.Val("options_txtWindowToggleShortcut") == "" then MsgStatusBar("Toggle shortcut removed")  else MsgStatusBar("Toggle shortcut set") end
end

-------------
-- Tab - Help
-------------
local helpContentLeft = {
  [[
  Select prev | next tab
  Select tab directly
  Favorites
  
  [ Layout / Colors ]
  [ Follow Actions ]
  [ Options ]
  [ Scan Settings ]
  [ Paths ]
  [ Help ] ]]
  ,
  [[
  Keep (window) open
  
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
  Refresh list
  Rebuild file cache
  
  Add | remove Favorites
  Toggle Audio Preview
  
  Prev | next project tab
  Close current project tab]]
  ,
  [[
  Toggle paths in sub | main panel
  Toggle sort mode
  
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
    o Or via Right Click on the [Refresh] button
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
  LEFT | RIGHT
  1, 2, 3, 4, 5, 6, 7
  0
  
  F7
  F6
  F4
  F3
  F2
  F1]]
  ,
  [[
  W
  
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
  /
  
  SHIFT + ENTER
  ENTER]]
  ,
  [[
  F5
  SHIFT + F5
  
  F  
  SPACE or *
  
  X | V
  C or -]]
  ,
  [[
  SHIFT + P | P
  S
  
  F8 | F9
  F10
  F11 | F12
  
  M (if main panel is hidden)
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
  GUI.New("help_frame_top", "Frame", LayerIndex.Help, 0, listbox_top, GUI.w, 2 * RL.scaleFactor, false, true)
  GUI.New("help_menuHelp", "Menubox", LayerIndex.Help, GUI.w * 0.35, 4.5 * RL.scaleFactor, 130 * RL.scaleFactor, 20 * RL.scaleFactor, "",
          "Key Shortcuts (1/5),Key Shortcuts (2/5),Key Shortcuts (3/5),Key Shortcuts (4/5),Key Shortcuts (5/5),,Audio Preview,Default Launcher,Favorites,Follow Actions,Listbox multi-select,Load with FX offline,Paths,Recent Projects,Scan Settings")
  GUI.elms.help_menuHelp.align = 1

  function RL_Draw_HelpFrames(selectedMenuIndex)
    if selectedMenuIndex < 6 then
      if GUI.elms.help_frameMain ~= nil then GUI.elms.help_frameMain:delete() end
      GUI.New("help_frameLeft", "Frame", LayerIndex.Help, 5, listbox_top + RL.scaleFactor, GUI.w * 0.5, GUI.h - (44 * RL.scaleFactor), false, false)
      GUI.New("help_frameRight", "Frame", LayerIndex.Help, (GUI.w * 0.5) - 5, listbox_top + RL.scaleFactor, GUI.w * 0.5, GUI.h - (44 * RL.scaleFactor), false, false)
      GUI.elms.help_frameLeft.pad, GUI.elms.help_frameRight.pad = 5 * RL.scaleFactor, 5 * RL.scaleFactor
      GUI.Val("help_frameLeft", GUI.word_wrap(helpContentLeft[GUI.Val("help_menuHelp")], 4, GUI.elms.help_frameLeft.w - 1.5 * RL.scaleFactor * GUI.elms.help_frameLeft.pad, 0, 2))
      GUI.Val("help_frameRight", GUI.word_wrap(helpContentRight[GUI.Val("help_menuHelp")], 4, GUI.elms.help_frameRight.w - 1.5 * RL.scaleFactor * GUI.elms.help_frameRight.pad, 0, 2))
    else
      if GUI.elms.help_frameLeft ~= nil then GUI.elms.help_frameLeft:delete() end
      if GUI.elms.help_frameRight ~= nil then GUI.elms.help_frameRight:delete() end
      GUI.New("help_frameMain", "Frame", LayerIndex.Help, 5, listbox_top + RL.scaleFactor, GUI.w - 5, GUI.h - (44 * RL.scaleFactor), false, false)
      GUI.elms.help_frameMain.pad = 2 * RL.scaleFactor
      GUI.Val("help_frameMain", GUI.word_wrap(helpContentLeft[GUI.Val("help_menuHelp")], 4, GUI.elms.help_frameMain.w - 1.5 * RL.scaleFactor * GUI.elms.help_frameMain.pad, 0, 2))
    end
  end

  function GUI.elms.help_menuHelp:onmousedown()
    GUI.Menubox.onmouseup(self)
    RL_Draw_HelpFrames(self.retval)
    reaper.SetExtState(appname, "window_helpfocus", tostring(GUI.Val("help_menuHelp")), 1)
  end
  
  function GUI.elms.help_menuHelp:onwheel()
    GUI.Menubox.onwheel(self)
    RL_Draw_HelpFrames(self.retval)
    reaper.SetExtState(appname, "window_helpfocus", tostring(GUI.Val("help_menuHelp")), 1)
  end

  if SWSinstalled then
    GUI.New("help_btnThread", "Button", LayerIndex.Help, GUI.w - (75 * RL.scaleFactor), 4.7 * RL.scaleFactor, 70 * RL.scaleFactor, 18 * RL.scaleFactor, "Forum thread")
    function GUI.elms.help_btnThread:onmousedown()
      GUI.Button.onmousedown(self)
      reaper.CF_ShellExecute([[https://forum.cockos.com/showthread.php?t=208697]])
    end
  end

  local lastHelpFocus = reaper.GetExtState(appname, "window_helpfocus")
  if lastHelpFocus == "" then lastHelpFocus = 1 end
  GUI.Val("help_menuHelp", lastHelpFocus)
  RL_Draw_HelpFrames(tonumber(lastHelpFocus))
end

-----------
-- Tooltips
-----------
local function RL_Draw_Tooltips()
  GUI.elms.main_menuTabSelector.tooltip = "Tab Navigation\n\nNavigate to different tabs by mouse click, mouse wheel or using the defined keyboard shortcuts - see [Help]"
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
  GUI.elms.layout_lblShowButtonPanel.tooltip = "Toggles the visibility of the main (button) panel on the right. If hidden, these functions are accessible via Middle Click menu\n\nRestart required for the changes to take effect"
  
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
    GUI.elms.tab_recentProjects_btnRefresh, GUI.elms.tab_recentProjects_btnFilterClear,
    GUI.elms.tab_projectTemplates_btnRefresh, GUI.elms.tab_projectTemplates_btnFilterClear,
    GUI.elms.tab_trackTemplates_btnRefresh, GUI.elms.tab_trackTemplates_btnFilterClear,
    GUI.elms.tab_customProjects_btnRefresh, GUI.elms.tab_customProjects_btnFilterClear,
    GUI.elms.tab_projectLists_btnRefresh, GUI.elms.tab_projectLists_btnFilterClear,
    GUI.elms.tab_backups_btnRefresh, GUI.elms.tab_backups_btnFilterClear,
    GUI.elms.tab_docs_btnRefresh, GUI.elms.tab_docs_btnFilterClear,
    GUI.elms.tab_favorites_btnRefresh, GUI.elms.tab_favorites_btnFilterClear,
    GUI.elms.paths_btnProjectTemplatesSet, GUI.elms.paths_btnTrackTemplatesSet, GUI.elms.paths_btnCustomProjectsSet,
    GUI.elms.paths_btnProjectListsSet, GUI.elms.paths_btnBackupsSet, GUI.elms.paths_btnDocsSet,
    GUI.elms.scansettings_btnProjectTemplates, GUI.elms.scansettings_btnTrackTemplates, GUI.elms.scansettings_btnCustomProjects,
    GUI.elms.scansettings_btnProjectLists, GUI.elms.scansettings_btnBackups, GUI.elms.scansettings_btnDocs,
    GUI.elms.actions_btnFollowAction_NewProject, GUI.elms.actions_btnFollowAction_NewTab,
    GUI.elms.actions_btnFollowAction_LoadProject, GUI.elms.actions_btnFollowAction_LoadProjectInTab,
    GUI.elms.actions_btnFollowAction_LoadProjectTemplate, GUI.elms.actions_btnFollowAction_InsertTrackTemplate,
    GUI.elms.main_scaleInterfaceDown, GUI.elms.main_scaleInterfaceToggle, GUI.elms.main_scaleInterfaceUp,
    GUI.elms.main_scaleFontDown, GUI.elms.main_scaleFontUp, GUI.elms.paths_btnRescanAllPaths,
    GUI.elms.options_btnWindowToggleSet
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
    GUI.elms.options_checklistShowPathsInStatusbar, GUI.elms.layout_checklistShowButtonPanel, GUI.elms.layout_checklistShowSubfolderPanel
  }

  if SWSinstalled then
    checklistElements[#checklistElements + 1] = GUI.elms.options_checklistPromptToSave
    checklistElements[#checklistElements + 1] = GUI.elms.options_checklistWindowToggle
  end

  for c = 1, #checklistElements do
    checklistElements[c]:init()
  end
end

function RL_Init_Colors_TextElements()
  local textElements = {
    GUI.elms.main_statusbar, GUI.elms.main_lblPaths,
    GUI.elms.colors_lbl_elmFill, GUI.elms.colors_lbl_txt, GUI.elms.colors_lbl_elmBg, GUI.elms.colors_lbl_wndBg,
    GUI.elms.layout_lblShowButtonPanel, GUI.elms.layout_lblShowSubfolderPanel,
    GUI.elms.scansettings_lblExcludedFolders, GUI.elms.actions_lblActionsHeader
  }

  if RL.showButtonPanel then
    textElements[#textElements + 1] = GUI.elms.main_lblSaveNewVersion
    textElements[#textElements + 1] = GUI.elms.main_lblWindowpin
    textElements[#textElements + 1] = GUI.elms.tab_projectTemplates_lblEditMode
    textElements[#textElements + 1] = GUI.elms.tab_favorites_lblEditMode
    textElements[#textElements + 1] = GUI.elms.tab_favorites_lblSaveNewVersion
  end

  if JSAPIinstalled then textElements[#textElements + 1] = GUI.elms.main_previewStatusLabel end

  for t = 1, #textElements do
    textElements[t]:init()
  end
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
    GUI.elms.main_menuTabSelector, GUI.elms.main_sortMode, GUI.elms.help_menuHelp,
    GUI.elms.layout_menuRetinaMode, GUI.elms.options_menuDoubleClick, GUI.elms.options_menuShowPathsInStatusbar,
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
  
  if SWSinstalled then
    inputElements[#inputElements + 1] = GUI.elms.layout_themeslot_number
    inputElements[#inputElements + 1] = GUI.elms.main_themeslot
  end 

  if JSAPIinstalled then inputElements[#inputElements + 1] = GUI.elms.main_previewChannels end 

  for m = 1, #inputElements do
    if inputElements[m] ~= nil then
      inputElements[m]:init()
    end
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
    GUI.elms.layout_lblShowButtonPanel:init()
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

    if JSAPIinstalled then GUI.elms.main_previewStatusLabel:init() end

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

-----------------
-- Load ExtStates
-----------------
local function RL_ExtStates_Load()
  GUI.Val("main_checklistWindowPin", {(reaper.GetExtState(appname, "window_pin") == "true" and true or false)}) 

  if ConfigFlags.enableSortModeOptions and IsNotNullOrEmpty(reaper.GetExtState(appname, "window_sortmode")) then
    local sortIndices = {}
    for sortMatch in reaper.GetExtState(appname, "window_sortmode"):gmatch("([^,%s]+)") do sortIndices[#sortIndices + 1] = tonumber(sortMatch) end
    if #sortIndices == 8 then RL.sortModeIndex = sortIndices end
  end

  if tonumber(ConfigFlags.setfirstTabToLoad) and tonumber(ConfigFlags.setfirstTabToLoad) > 0 and tonumber(ConfigFlags.setfirstTabToLoad) < #TabID then RL_SetFocusedTab(ConfigFlags.setfirstTabToLoad)
  else RL_SetFocusedTab(tonumber(reaper.GetExtState(appname, "window_tabfocus"))) end
  
  local isButtonPanelVisible = reaper.GetExtState(appname, "window_showmainbuttonpanel")
  if isButtonPanelVisible == "" then isButtonPanelVisible = true
  else isButtonPanelVisible = (reaper.GetExtState(appname, "window_showmainbuttonpanel") == "true" and true or false) end
  GUI.Val("layout_checklistShowButtonPanel", {isButtonPanelVisible})
  
  local mouseDoubleClick = reaper.GetExtState(appname, "mouse_doubleclick")
  if mouseDoubleClick == "" then mouseDoubleClick = 1 end
  if mouseDoubleClick == "4" and not JSAPIinstalled then mouseDoubleClick = 1 end
  GUI.Val("options_menuDoubleClick", mouseDoubleClick)

  GUI.Val("options_checklistOpenPropertiesOnNewProject", {(reaper.GetExtState(appname, "project_showproperties") == "true" and true or false)}) 

  GUI.Val("options_checklistWindowToggle", {(reaper.GetExtState(appname, "window_togglemode") == "true" and true or false)}) 
  RL.windowToggleShortcut = tonumber(reaper.GetExtState(appname, "window_toggleshortcut"))
  if RL.windowToggleShortcut ~= nil then GUI.Val("options_txtWindowToggleShortcut", string.char(RL.windowToggleShortcut)) end

  GUI.Val("options_checklistShowPathsInStatusbar", {(reaper.GetExtState(appname, "window_showpathsinstatusbar") == "true" and true or false)}) 
  local pathInStatusBarMode = reaper.GetExtState(appname, "window_showpathsinstatusbarmode")
  if pathInStatusBarMode == "" then pathInStatusBarMode = 1 end
  GUI.Val("options_menuShowPathsInStatusbar", pathInStatusBarMode)
  
  GUI.Val("main_checklistPaths", {(reaper.GetExtState(appname, "window_showpaths") == "true" and true or false)})
  Global_UpdatePathDisplayMode()

  GUI.Val("tab_recentProjects_txtFilter", reaper.GetExtState(appname, "filter_recentprojects"))
  if IsNotNullOrEmpty(GUI.Val("tab_recentProjects_txtFilter")) then
    FilterActive.RecentProjects = true
    Filter_RecentProject_Apply()
  else GUI.elms.tab_recentProjects_txtFilter.color = FilterColor.inactive end
  
  GUI.Val("tab_projectTemplates_txtFilter", reaper.GetExtState(appname, "filter_projecttemplates"))
  if IsNotNullOrEmpty(GUI.Val("tab_projectTemplates_txtFilter")) then
    FilterActive.ProjectTemplates = true
    Filter_ProjectTemplate_Apply()
  end
 
  GUI.Val("tab_trackTemplates_txtFilter", reaper.GetExtState(appname, "filter_tracktemplates"))
  if IsNotNullOrEmpty(GUI.Val("tab_trackTemplates_txtFilter")) then
    FilterActive.TrackTemplates = true
    Filter_TrackTemplate_Apply()
  end
  
  GUI.Val("tab_customProjects_txtFilter", reaper.GetExtState(appname, "filter_projects"))
  if IsNotNullOrEmpty(GUI.Val("tab_customProjects_txtFilter")) then
    FilterActive.CustomProjects = true
    Filter_CustomProjects_Apply()
  end
  
  GUI.Val("tab_projectLists_txtFilter", reaper.GetExtState(appname, "filter_projectlists"))
  if IsNotNullOrEmpty(GUI.Val("tab_projectLists_txtFilter")) then
    FilterActive.ProjectLists = true
    Filter_ProjectLists_Apply()
  end
  
  GUI.Val("tab_backups_txtFilter", reaper.GetExtState(appname, "filter_backups"))
  if IsNotNullOrEmpty(GUI.Val("tab_backups_txtFilter")) then
    FilterActive.Backups = true
    Filter_Backups_Apply()
  end

  GUI.Val("tab_docs_txtFilter", reaper.GetExtState(appname, "filter_docs"))
  if IsNotNullOrEmpty(GUI.Val("tab_docs_txtFilter")) then
    FilterActive.Docs = true
    Filter_Docs_Apply()
  end

  GUI.Val("tab_favorites_txtFilter", reaper.GetExtState(appname, "filter_favorites"))
  if IsNotNullOrEmpty(GUI.Val("tab_favorites_txtFilter")) then
    FilterActive.Favorites = true
    Filter_Favorites_Apply()
  end

  if JSAPIinstalled then 
    GUI.Val("main_previewVolKnob", tonumber(reaper.GetExtState(appname, "preview_vol")))
    AudioPreview.channelIndex = tonumber(reaper.GetExtState(appname, "preview_channel"))
    GUI.Val("main_previewChannels",tonumber(reaper.GetExtState(appname, "preview_channelmenuitem")))
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
  reaper.SetExtState(appname, "window_showmainbuttonpanel", tostring(GUI.Val("layout_checklistShowButtonPanel")), 1)
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
    if currentTab and currentTab <= TabID.Favorites and currentTab ~= TabID.Docs then 
      local selectedIndex = TabSelectionIndex[currentTab]
      if selectedIndex ~= nil and selectedIndex > 0 then
        local AudioPreviewElements = {}
        if currentTab == TabID.RecentProjects then AudioPreviewElements = { RecentProjects.items, RecentProjects.filteredItems, RecentProjects.names, RecentProjects.filteredNames }
          elseif currentTab == TabID.ProjectTemplates then AudioPreviewElements = { ProjectTemplates.items, ProjectTemplates.filteredItems, ProjectTemplates.names, ProjectTemplates.filteredNames }
          elseif currentTab == TabID.TrackTemplates then AudioPreviewElements = { TrackTemplates.items, TrackTemplates.filteredItems, TrackTemplates.names, TrackTemplates.filteredNames }
          elseif currentTab == TabID.CustomProjects then AudioPreviewElements = { CustomProjects.items, CustomProjects.filteredItems, CustomProjects.names, CustomProjects.filteredNames }
          elseif currentTab == TabID.ProjectLists then AudioPreviewElements = { ProjectLists.projectItems, ProjectLists.filteredProjectItems, ProjectLists.projectNames, ProjectLists.filteredProjectNames }
          elseif currentTab == TabID.Backups then AudioPreviewElements = { Backups.items, Backups.filteredItems, Backups.names, Backups.filteredNames }
          elseif currentTab == TabID.Favorites then AudioPreviewElements = { Favorites.items, Favorites.filteredItems, Favorites.names, Favorites.filteredNames }
        end

        local selectedPreviewElement = AudioPreviewElements[3][selectedIndex]
        if IsFilterActive(currentTab) then selectedPreviewElement = AudioPreviewElements[4][selectedIndex] end

        if AudioPreviewElements[1][selectedIndex] ~= nil then
          for t = 1, #AudioPreviewFileTypes do
            if selectedPreviewElement == nil then AudioPreview.fileName = "emptyList"
            else
              AudioPreview.fileExtension = AudioPreviewFileTypes[t]
              local audioDirPath = AudioPreviewElements[1][selectedIndex].path
              if IsFilterActive(currentTab) then audioDirPath = AudioPreviewElements[2][selectedIndex].path end
              AudioPreview.fileName = GetDirectoryPath(audioDirPath) .. GetPathSeparator() .. selectedPreviewElement .. AudioPreview.fileExtension
            end
            if AudioPreview.fileName ~= "emptyList" and reaper.file_exists(AudioPreview.fileName) then break end
          end

          AudioPreviewChangeVolKnobColor("none", "elm_frame")
          GUI.elms.main_previewStatusLabel.tooltip = ""

          if reaper.file_exists(AudioPreview.fileName) then
            AudioPreviewChangeVolKnobColor("none", "silver")
            AudioPreview.statusText = selectedPreviewElement .. AudioPreview.fileExtension
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
  C = 99,
  F = 102,
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
  "tab_favorites_listbox"
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
    GUI.elms.tab_favorites_categories
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
      UpdateProjectListSelection()
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
  Global_ShowPathInStatusbar(tabIndex)
  if JSAPIinstalled then AudioPreviewCheckForFile(tabIndex) end
end

function RL_Keys_ListboxSelectPrevious(currentTab)
  if TabSelectionIndex[currentTab] ~= nil and currentTab <= TabID.Favorites then 
    local listIndex = TabSelectionIndex[currentTab]
    if listIndex - 1 > 0 then listIndex = listIndex - 1 end
    SetListBoxIndex(currentTab, listIndex)
    Scroll(ListBoxElements[currentTab], listIndex, -1)
  end
end

function RL_Keys_ListboxSelectNext(currentTab)
  if TabSelectionIndex[currentTab] ~= nil and currentTab <= TabID.Favorites then
    local listIndex = TabSelectionIndex[currentTab]
    local ListBoxItems = {
      GUI.elms.tab_recentProjects_listbox.list,
      GUI.elms.tab_projectTemplates_listbox.list,
      GUI.elms.tab_trackTemplates_listbox.list,
      GUI.elms.tab_customProjects_listbox.list,
      GUI.elms.tab_projectLists_listboxProjects.list,
      GUI.elms.tab_backups_listbox.list,
      GUI.elms.tab_docs_listbox.list,
      GUI.elms.tab_favorites_listbox.list
    }
  
    if listIndex + 1 <= #ListBoxItems[currentTab] then listIndex = listIndex + 1 end
    SetListBoxIndex(currentTab, listIndex)
    Scroll(ListBoxElements[currentTab], listIndex, 1)
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
  [TabID.RecentProjects] = { call = function() RefreshRecentProjects() end },
  [TabID.ProjectTemplates] = { call = function() RefreshProjectTemplates() end },
  [TabID.TrackTemplates] = { call = function() RefreshTrackTemplates() end },
  [TabID.CustomProjects] = { call = function() RefreshCustomProjects() end },
  [TabID.ProjectLists] = { call = function() RefreshProjectList() end },
  [TabID.Backups] = { call = function() RefreshBackups() end },
  [TabID.Docs] = { call = function() RefreshDocs() end },
  [TabID.Favorites] = { call = function() RefreshFavorites() end }
}

RL_Func_RebuildCache = {
  [TabID.RecentProjects] = { call = function() RefreshRecentProjects() end },
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
      elseif inputChar == GUI.chars.LEFT then
          if GUI.elms.main_tabs.state > 1 then RL_SetFocusedTab(GUI.elms.main_tabs.state - 1) end
      -- select next tab
      elseif inputChar == GUI.chars.RIGHT then
          if GUI.elms.main_tabs.state < TabID.Help then RL_SetFocusedTab(GUI.elms.main_tabs.state + 1) end
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
      elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.F5 and GUI.elms.main_tabs.state <= TabID.Favorites then RL_Func_RebuildCache[GUI.elms.main_tabs.state].call()
      elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.F5 and GUI.elms.main_tabs.state <= TabID.Favorites then RL_Func_TabRefresh[GUI.elms.main_tabs.state].call()
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
      elseif inputChar == GUI.chars.S and GUI.elms.main_tabs.state <= TabID.Favorites and ConfigFlags.enableSortModeOptions then Global_CycleSortMode()
      elseif inputChar == GUI.chars.L and GUI.elms.main_tabs.state <= TabID.Favorites then Global_OpenInExplorer() 
      elseif inputChar == GUI.chars.O then Global_ShowProjectOpenDialog() 
      elseif inputChar == GUI.chars.N then Global_NewProject()
      elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.T or inputChar == GUI.chars.PLUS then Global_NewTab() 
      elseif inputChar == GUI.chars.DIVIDE then Global_NewTabIgnoreDefaultTemplate()
      -- toggle path display in sub listbox
      elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.p then
        RL.showSubFolderPaths = not RL.showSubFolderPaths
        Global_UpdateSubfolderPathDisplayMode()
      -- toggle path display in main listbox
      elseif inputChar == GUI.chars.P then
        if GUI.Val("main_checklistPaths") then GUI.Val("main_checklistPaths", {false}) else GUI.Val("main_checklistPaths", {true}) end
        Global_UpdatePathDisplayMode()
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
      elseif inputChar == GUI.chars.F7 then RL_SetFocusedTab(TabID.Layout)
      elseif inputChar == GUI.chars.F6 then RL_SetFocusedTab(TabID.Actions)
      elseif inputChar == GUI.chars.F4 then RL_SetFocusedTab(TabID.Options)
      elseif inputChar == GUI.chars.F3 then RL_SetFocusedTab(TabID.ScanSettings)
      elseif inputChar == GUI.chars.F2 then RL_SetFocusedTab(TabID.Paths)
      elseif inputChar == GUI.chars.F1 then RL_SetFocusedTab(TabID.Help)
      -- favorites
      elseif inputChar == GUI.chars.F then if GUI.elms.main_tabs.state == TabID.Favorites then RL_ConfirmDialog_RemoveFavoritesEntry() else Favorites_Add() end
      -- context menus
    elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.M then RL_Context_Main_Relay()  
    elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.m then 
          if GUI.elms.main_tabs.state == TabID.RecentProjects and SWSinstalled then RL_Context_RecentProjects()
          elseif GUI.elms.main_tabs.state == TabID.Favorites then RL_Context_Favorites() end
    end
      -- audio preview
      if JSAPIinstalled then
        if inputChar == GUI.chars.SPACE or inputChar == GUI.chars.MULTIPLY then AudioPreviewToggleState() end
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
  RL_ExtStates_Load()
  Global_UpdateSubfolderPathDisplayMode()
end

----------------------------
-- listbox font size scaling
----------------------------
function RL_ScaleListboxFontSize()
  local fonts = GUI.get_OS_fonts()
  for p = 1, #ParentListBoxElements do
    if (ShowSubfolderPanel(p) or p == #ParentListBoxElements) and ParentListBoxElements[p] ~= nil then
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
    RL_ExtStates_Save()
    if RL.scaleFactor < 1.5 then
      RL_InitElementScaling(2.0)
      RL_ScaleWindowUp()
    else
      RL_InitElementScaling(1.0)
      RL_ScaleWindowDown()
    end
  end

function RL_ScaleInterfaceUp()
  if (RL.scaleFactor + RL.scaleStepSize) <= RL.scaleMax then
    RL_InitElementScaling(RL.scaleFactor + RL.scaleStepSize) 
    RL_ExtStates_Save()
    RL_ScaleWindowUp()
  end
end

function RL_ScaleInterfaceDown()
  if (RL.scaleFactor - RL.scaleStepSize) >= RL.scaleMin then
    RL_InitElementScaling(RL.scaleFactor - RL.scaleStepSize)
    RL_ExtStates_Save()
    RL_ScaleWindowDown()
  end
end

function SetToggleState(toggleState)
  local _, _, sectionID, commandID, _, _, _ = reaper.get_action_context()
  reaper.SetToggleCommandState(sectionID, commandID, toggleState)
  reaper.RefreshToolbar2(sectionID, commandID)
end

GUI.onresize = function()
  RL_ExtStates_Save()
  RL.skipOperationOnResize = true

  local _, wx, wy, ww, wh = gfx.dock(-1, 0, 0, 0, 0)
  local retinaAdjustment = 1.0
  if RL.retinaMode == 1 then retinaAdjustment = 2.0 end
  GUI.w , GUI.h = ww * retinaAdjustment, wh * retinaAdjustment
  RL_RedrawUI()

  if RL.scaleFactor > 1.0 then
    if GUI.w * retinaAdjustment < (((RL.minWidth - 20) * RL.scaleFactor) - (50 * RL.scaleFactor)) * retinaAdjustment  then RL_ResizeScaledWidth(wx, wy) end
    if GUI.h * retinaAdjustment < (((RL.minHeight - 80) * RL.scaleFactor) + (50 * RL.scaleFactor)) * retinaAdjustment then RL_ResizeScaledHeight(wx, wy) end
  else
    if GUI.w * retinaAdjustment < RL.minWidth then RL_ResizeWidth(wx, wy) end
    if GUI.h * retinaAdjustment < RL.minHeight then RL_ResizeHeight(wy, wy) end
  end
  
  RL.skipOperationOnResize = false
end

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
  if JSAPIinstalled then AudioPreviewStopAll() end
end)

-----------------
-- Main functions
-----------------
GUI.Init()
RL_InitCustomColors()
RL_ExtStates_Load()
SetRetinaMode()
SetToggleState(1)
if ConfigFlags.enableKeyShortcuts then RL_Keys_CheckInput() end

GUI.func = Main
GUI.freq = 0
GUI.Main()

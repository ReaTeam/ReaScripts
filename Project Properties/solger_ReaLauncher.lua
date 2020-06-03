-- @description ReaLauncher
-- @author solger
-- @version 2.3
-- @changelog
--   + Docs: New [Docs] tab added for listing .PDF document files (folder location is set in the [Options] tab) - opening files requires SWS Extensions installed
--   + General: Added support for additional key shortcuts: close (ESC) and confirm (ENTER) dialogs, open Context Menu (M or 0) in [Recent Projects]
--   + General: Minor bugfix for SWS version check
--   + Options: Added possibility to add folder paths via a 'Browse' dialog (besides manual copy & paste) - requires js_ReaScriptAPI installed
--   + Options: Added option for setting a default DOUBLE-CLICK behavior: [Show Prompt | Load | Load in Tab | Audio Preview]
--   + Project Lists: Added support for usage of multiple folders (set in the [Options] tab)
--   + Project Lists: Duplicate entries are now only listed once
--   + Recent Projects: Fix for preventing a 'not responding' bug if no [Recent] entry section exists in the reaper.ini yet
-- @screenshot https://forum.cockos.com/showthread.php?t=208697
-- @about
--   # ReaLauncher
--
--   A custom version of the startup prompt window for loading (recent) projects, project/track templates and more with additional features.
--
--   Uses 'Lokasenna's GUI library v2 for Lua' as base: https://forum.cockos.com/showthread.php?t=177772. Big thanks to Lokasenna for his work!!
--
--   ## Main features
--     - Separate tabs for [Recent Projects], (.rpp) [Project Templates], (.rtracktemplate) [Track Templates], (.rpp) Projects, (.rpl) [Project Lists], (.rpp-bak) [Backups] and (.pdf) [Docs]
--     - Option to set additional folder paths for [Project Templates] and [Track Templates] (which are used in addition to the default template folders)
--     - Option to set custom folder paths for [Projects], [Project Lists], [Backups] and [Docs] tabs
--     - List filter in each tab that supports the use of multiple search words separated by a 'space' character
--     - Global section with [New Tab], [New Project] and [Open Project] buttons
--     - Selection and loading of multiple entries at once (multi-select via mouse is already part of Lokasenna's GUI library)
--     - File paths can be shown/hidden
--     - 'Keep open' checkbox to switch the automatic closing behavior of the window
--     - Scalable and resizeable window
--
--   ## Features that require SWS Extensions (2.9.8 or higher):
--     - [Docs] tab for listing .pdf files
--     - [Recent Projects] tab for listing and managing the recent projects (with functions to remove selected entries and clearing the entire list)
--     - [Show in Explorer/Finder] button to search for the location of a selected file
--     - Setup of predefined Reaper Theme Slots and the possibility to switch between them (uses SWS Resources)
--
--   ## Features that require js_ReaScriptAPI (0.991 or higher):
--     - Function to preview attached 'demo' audio files (supported file extensions: .wav, .flac, .mp3 and .ogg)
--     - Option for adding folder paths in the [Options] tab via a 'Browse' dialog (besides manual copy & paste)
--
--   ## Discussion thread
--
--   https://forum.cockos.com/showthread.php?t=208697

-------------------------------------------------------------------------------
local showDebugMessages = false -- show console debug messages
local skipRefreshAtLaunch = false -- skip refresh of last focused tab at launch
-------------------------------------------------------------------------------
-- String Helper functions
--------------------------
local function MsgDebug(str)
  if showDebugMessages then
    reaper.ShowConsoleMsg("\t" .. tostring(str) .. "\n")
  end
end

local function MsgStatusBar(message, appendMode, fadeMode, clearMessage)
  if clearMessage then
    GUI.Val("main_statusbar", "")
    GUI.elms.main_statusbar:fade(1, 1, 30)
  else
    if message ~= nil then
      GUI.Val("main_statusbar", "")
      GUI.elms.main_statusbar:fade(1, 1, 30)
      if appendMode then
        GUI.Val("main_statusbar", GUI.Val("main_statusbar") .. " | " .. message)
        GUI.elms.main_statusbar:fade(8, 1, 30)
      else
        GUI.Val("main_statusbar", "|  " .. message)
        if fadeMode then GUI.elms.main_statusbar:fade(8, 1, 30) end
      end
    end
  end
end

------------------------------------------
-- Reaper resource paths and version infos
------------------------------------------
appversion = "2.3"
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
if resourcePath == nil then reaper.ShowMessageBox(tostring("Could not retrieve the Reaper resource path!"), "Error", 0) 
else MsgDebug("Resource path:\t\t" .. resourcePath) end

reaperIniPath = reaper.get_ini_file()
MsgDebug("Reaper ini:\t\t" .. reaperIniPath)

if osversion:find("Win") then
  -- Windows paths
  trackTemplatePath = resourcePath .. "\\TrackTemplates"
  projectTemplatePath = resourcePath .. "\\ProjectTemplates"
else
  -- macOS / Linux paths
  trackTemplatePath = resourcePath .. "/TrackTemplates"
  projectTemplatePath = resourcePath .. "/ProjectTemplates"
end

-------------------------------------
-- Loading Lokasenna's GUI library v2 
-------------------------------------
local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
  if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack, then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Whoops!", 0)
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
if missing_lib then return 0 end -- If any of the requested libraries weren't found, abort the script.

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
    MsgDebug("SWS:\t\t\tNOT FOUND")
    return false
  end
end

local function CheckForJSAPI()
  if not reaper.ReaPack_GetOwner then
    MsgDebug("JS_ReascriptAPI:\t\t NOT FOUND")
  else
    local owner
    if osversion:find("Win") and bitversion == "x64" then
      owner = reaper.ReaPack_GetOwner("UserPlugins/reaper_js_ReaScriptAPI64.dll") -- Windows 64-bit
    elseif osversion:find("Win") then
      owner = reaper.ReaPack_GetOwner("UserPlugins/reaper_js_ReaScriptAPI32.dll") -- Windows 32-bit
    elseif osversion:find("OSX") then
      owner = reaper.ReaPack_GetOwner("UserPlugins/reaper_js_ReaScriptAPI64.dylib") -- macOS
    else 
      owner = reaper.ReaPack_GetOwner("UserPlugins/reaper_js_ReaScriptAPI64.so") -- Linux
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
-- helper functions
-------------------
local function JoinTables(t1, t2)
  for k, v in ipairs(t2) do t1[#t1 + 1] = v end
  return t1
end

local function CheckForDuplicates(table, value)
  local found = false
  for i = 1, #table do
    if table[i] == value then found = true end
  end
  return found
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
  if osversion:find("Win") then return "\\"
  else return "/" end
end

local function FileExists(fileName)
  local tempFile = io.open(fileName, "r")
  return tempFile ~= nil and io.close(tempFile)
end

local function GetFolderName(filepath)
  local index = (filepath:reverse()):find("%\\") or (filepath:reverse()):find("%/")
  if index ~= nil then
    return string.sub(filepath, (#filepath - index) + 2, #filepath)
  else
    return filepath
  end
end

local function IsNotNullOrEmpty(str)
  return str ~= nil and str ~= ""
end

----------------------------------------------------------------------------------------------
-- Enumerate all (sub-)directories and files of a given path
-- Adapted versions of code snippets found in the Reaper forum. Thanks to mpl and Lokasenna :)
----------------------------------------------------------------------------------------------
local function EnumerateFiles(folder)
  local files = {}
  local i = 1
  repeat
    files[i] = reaper.EnumerateFiles(folder, i - 1)
    i = i + 1
  until not retval
  return files
end

local function FolderContainsFiles(path, extensionFilter)
  local fileCount = EnumerateFiles(path)
  if fileCount == nil then
    return false
  else
    for i = 1, #fileCount do
      checkFileName = fileCount[i]
      if IsNotNullOrEmpty(checkFileName) then 
        if string.lower(checkFileName.sub(checkFileName, (#checkFileName + 1) - #extensionFilter)) == string.lower(extensionFilter)  then
          return true;
        end
      end
    end
    return false
  end
end

local function GetSubFolders(path, extensionFilter)
  local subDirTree = {}
  local subDirFiles = {}
  local subDirIndex, dirIndex = 0, 0
  local subDirChild
  
  if path ~= nil then 
    repeat
      subDirChild = reaper.EnumerateSubdirectories(path, subDirIndex)
        if subDirChild then
            local tmpPath, _ = GetSubFolders(path .. GetPathSeparator() .. subDirChild, extensionFilter)
              for i = 1, #tmpPath do
                subDirTree[#subDirTree + 1] = tmpPath[i]
                subDirFiles[#subDirFiles + 1] = GetFolderName(tmpPath[i])
              end
          end
        subDirIndex = subDirIndex + 1
      until not subDirChild
      
      repeat
        local subfolderFound = reaper.EnumerateSubdirectories(path, dirIndex)
          if subfolderFound and FolderContainsFiles(path .. GetPathSeparator() .. subfolderFound, extensionFilter) then
              subDirTree[#subDirTree + 1] = path .. GetPathSeparator() .. subfolderFound
              subDirFiles[#subDirFiles + 1] = subfolderFound
          end
          dirIndex = dirIndex + 1
      until not subfolderFound
  end

  return subDirTree, subDirFiles
end

local function GetFiles(path)
  local tree = {}
  local subDirIndex, fileIndex = 0, 0
  local pathChild

  if path ~= nil then 
    repeat
      pathChild = reaper.EnumerateSubdirectories(path, subDirIndex)
        if pathChild then
          local tmpPath = GetFiles(path .. GetPathSeparator() .. pathChild)
            for i = 1, #tmpPath do
              tree[#tree + 1] = tmpPath[i]
            end
        end
        subDirIndex = subDirIndex + 1
    until not pathChild

    repeat
      local fileFound = reaper.EnumerateFiles(path, fileIndex)
        if fileFound then
          tree[#tree + 1] = path .. GetPathSeparator() .. fileFound
        end
        fileIndex = fileIndex + 1
    until not fileFound
  end
  return tree
end

local function GetFileExtension(fileName, charLength)
  return string.lower(string.sub(fileName, #fileName - charLength, #fileName))
end

local function SplitMultiPaths(pathString)
  local pathTable = {}
  pathString:gsub("[^;]*", function(p) pathTable[#pathTable + 1] = p:match("^%s*(.-)%s*$") end)
  return pathTable
end

local function RemoveExtension(fileName, fileType)
  if fileName == nil then return ""
  else return string.sub(fileName, 1, #fileName - #fileType) end
end

local function RemoveWhiteSpaces(s)
  if s ~= nil then return s:match("^%s*(.-)%s*$") end
end

local function GetDirectoryPath(filepath)
  local index
  if osversion:find("Win") then index = (filepath:reverse()):find("%\\") -- Windows
    else index = (filepath:reverse()):find("%/") -- macOS / Linux
  end
  if index == nil then return ""
  else return string.sub(filepath, 1, #filepath - index) end
end

local function GetLastDirectoryInPath(filepath)
  local index
  if osversion:find("Win") then index = (filepath:reverse()):find("%\\") -- Windows
    else index = (filepath:reverse()):find("%/") -- macOS / Linux
  end
  if index == nil then return ""
  else return string.sub(filepath, (#filepath - index) + 2, #filepath) end
end

local function GetFilenameWithoutPath(filepath)
  if osversion:find("Win") then return filepath:match("([^\\]-([^.]+))$") -- Windows: get (fileName.extension) substring
  else 
    local index = (filepath:reverse()):find("%/") -- macOS / Linux
    if index ~= nil then
      return string.sub(filepath, (#filepath - index) + 2, #filepath)
    else
      return filepath
    end
  end
end

------------------------------------------
-- Open the folder path in Explorer/Finder
------------------------------------------
local function ShowLocationInExplorer(path)
  reaper.CF_LocateInExplorer(path)
end

---------------------------------------------
-- Show in Explorer/Finder - Helper functions
---------------------------------------------
local function ShowLocation_RecentProject()
  if not noRecentProjects then
  local selectedProject
  local vals = GetSelectionTable(GUI.Val("tab_recentProjects_listbox"))

  if #vals == 0 then MsgStatusBar("No files selected in the list!", false, true, false)
    else
      for p = 1, #vals do
        if FilterActive.RecentProjects then selectedProject = RecentProjects.items[RecentProjects.filteredNames[vals[p]]]
        else selectedProject = RecentProjects.items[RecentProjects.names[vals[p]]] end
        ShowLocationInExplorer(selectedProject)
      end
    end
  end
end

local function ShowLocation_ProjectTemplates()
  if not noProjectTemplates then
    local selectedProjectTemplate
    local vals = GetSelectionTable(GUI.Val("tab_projectTemplates_listbox"))

    if #vals == 0 then ShowLocationInExplorer(projectTemplatePath)
    else
     for p = 1, #vals do
        if FilterActive.ProjectTemplates then selectedProjectTemplate = ProjectTemplates.items[ProjectTemplates.filteredNames[vals[p]]]
        else selectedProjectTemplate = ProjectTemplates.items[ProjectTemplates.names[vals[p]]] end
        ShowLocationInExplorer(selectedProjectTemplate)
      end
    end
    else
      ShowLocationInExplorer(projectTemplatePath)
  end
end

local function ShowLocation_TrackTemplates()
  if not noTrackTemplates then
    local selectedTrackTemplate
    local vals = GetSelectionTable(GUI.Val("tab_trackTemplates_listbox"))

    if #vals == 0 then ShowLocationInExplorer(trackTemplatePath)
    else
      for p = 1, #vals do
        if FilterActive.TrackTemplates then selectedTrackTemplate = TrackTemplates.items[TrackTemplates.filteredNames[vals[p]]]
        else selectedTrackTemplate = TrackTemplates.items[TrackTemplates.names[vals[p]]] end
          ShowLocationInExplorer(selectedTrackTemplate)
        end
     end
   else
    ShowLocationInExplorer(trackTemplatePath)
  end
end

local function ShowLocation_CustomProject()
  if not noCustomProjects then
    local vals = GetSelectionTable(GUI.Val("tab_customProjects_listbox"))
      if #vals == 0 then
        if GUI.Val("options_txtCustomProjectsPath") == "" then MsgStatusBar("No files selected in the list!", false, true, false)
        else
          ShowLocationInExplorer(GUI.Val("options_txtCustomProjectsPath"))
        end
      else
        for p = 1, #vals do
          if FilterActive.CustomProjects then selectedProject = CustomProjects.items[CustomProjects.filteredNames[vals[p]]]
          else selectedProject = CustomProjects.items[CustomProjects.names[vals[p]]] end
        ShowLocationInExplorer(selectedProject)
      end
    end
  end
end

local function ShowLocation_ProjectList()
  if not noProjectLists then
    local vals = GetSelectionTable(GUI.Val("tab_projectLists_listboxProjects"))
    if #vals == 0 then
        if GUI.Val("options_txtProjectsListsPath") == "" then MsgStatusBar("No files selected in the list!", false, true, false)
        else
          ShowLocationInExplorer(GUI.Val("options_txtProjectsListsPath"))
        end
      else
      for p = 1, #vals do
        if FilterActive.ProjectLists then selectedProject = ProjectLists.filteredProjectPaths[vals[p]]
        else selectedProject = ProjectLists.projectPaths[vals[p]] end
        ShowLocationInExplorer(selectedProject)
      end
    end
  end
end

local function ShowLocation_Backups()
  if not noBackups then
    local vals = GetSelectionTable(GUI.Val("tab_backups_listbox"))
    if #vals == 0 then
        if GUI.Val("options_txtBackupsPath") == "" then MsgStatusBar("No files selected in the list!", false, true, false)
        else
          ShowLocationInExplorer(GUI.Val("options_txtBackupsPath"))
        end
      else
      for p = 1, #vals do
        if FilterActive.Backups then selectedProject = Backups.filteredPaths[vals[p]]
        else selectedProject = Backups.paths[vals[p]] end
        ShowLocationInExplorer(selectedProject)
      end
    end
  end
end

local function ShowLocation_Docs()
  if not noDocs then
    local vals = GetSelectionTable(GUI.Val("tab_docs_listbox"))
    if #vals == 0 then
        if GUI.Val("options_txtDocsPath") == "" then MsgStatusBar("No files selected in the list!", false, true, false)
        else
          ShowLocationInExplorer(GUI.Val("options_txtDocsPath"))
        end
      else
      for p = 1, #vals do
        if FilterActive.Docs then selectedDoc = Docs.filteredPaths[vals[p]]
        else selectedDoc = Docs.paths[vals[p]] end
        ShowLocationInExplorer(selectedDoc)
      end
    end
  end
end

-----------------------------
-- Path Display and Tab Focus 
-----------------------------
local function RL_GetFocusedTab()
  return GUI.elms.main_tabs.state
end

local showSubfolderPanel = reaper.GetExtState(appname, "window_showsubfolderpanel") == "true" and true or false;
local showSubFolderPaths = false

local function Global_UpdateSubfolderPathDisplayMode()
  if showSubfolderPanel then
    local tabfocus = RL_GetFocusedTab()
    if not showSubFolderPaths then
      if tabfocus == TabID.ProjectTemplates then GUI.elms.tab_projectTemplates_subfolders.list = SubfolderNames.projectTemplates
      elseif tabfocus == TabID.TrackTemplates then GUI.elms.tab_trackTemplates_subfolders.list = SubfolderNames.trackTemplates
      elseif tabfocus == TabID.CustomProjects then GUI.elms.tab_customProjects_subfolders.list = SubfolderNames.customProjects
      elseif tabfocus == TabID.ProjectLists then GUI.elms.tab_projectLists_listboxRPL.list = ProjectLists.rplFiles
      elseif tabfocus == TabID.Backups then GUI.elms.tab_backups_subfolders.list = SubfolderNames.backups
      elseif tabfocus == TabID.Docs then GUI.elms.tab_docs_subfolders.list = SubfolderNames.docs
      end
    else
      if tabfocus == TabID.ProjectTemplates then GUI.elms.tab_projectTemplates_subfolders.list = SubfolderPaths.projectTemplates
        elseif tabfocus == TabID.TrackTemplates then GUI.elms.tab_trackTemplates_subfolders.list = SubfolderPaths.trackTemplates
        elseif tabfocus == TabID.CustomProjects then GUI.elms.tab_customProjects_subfolders.list = SubfolderPaths.customProjects
        elseif tabfocus == TabID.ProjectLists then GUI.elms.tab_projectLists_listboxRPL.list = ProjectLists.rplPaths
        elseif tabfocus == TabID.Backups then GUI.elms.tab_backups_subfolders.list = SubfolderPaths.backups
        elseif tabfocus == TabID.Docs then GUI.elms.tab_docs_subfolders.list = SubfolderPaths.docs
      end
    end

    if tabfocus == TabID.ProjectTemplates then GUI.elms.tab_projectTemplates_subfolders:redraw()
      elseif tabfocus == TabID.TrackTemplates then GUI.elms.tab_trackTemplates_subfolders:redraw()
      elseif tabfocus == TabID.CustomProjects then GUI.elms.tab_customProjects_subfolders:redraw()
      elseif tabfocus == TabID.ProjectLists then GUI.elms.tab_projectLists_listboxRPL:redraw()
      elseif tabfocus == TabID.Backups then GUI.elms.tab_backups_subfolders:redraw()
      elseif tabfocus == TabID.Docs then GUI.elms.tab_docs_subfolders:redraw()
    end
  end
end

local function RL_AutoRefreshTab()
  local selectedTab = RL_GetFocusedTab()
  if (selectedTab < (#MainTabs - 1)) and not IsTabAutoRefreshed[selectedTab] then
    if tabIndex ~= TabID.CustomProjects then IsTabAutoRefreshed[selectedTab] = true end
    RL_Func_TabRefresh[selectedTab].call()
    Global_UpdateSubfolderPathDisplayMode()
  end
  GUI.Val("main_checklistSaveAsNewVersion", {false})
end

local function RL_SetFocusedTab(tabIndex)
  GUI.Val("main_tabs", tabIndex)
  GUI.Val("main_checklistSaveAsNewVersion", {false})
  if not skipRefreshAtLaunch then RL_AutoRefreshTab() end
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

local function Global_UpdatePathDisplayMode()
  if GUI.Val("main_menuPaths") == 1 then showFullPaths = false else showFullPaths = true end
  UpdatePathDisplay_RecentProjects(showFullPaths)
  UpdatePathDisplay_ProjectTemplates(showFullPaths)
  UpdatePathDisplay_TrackTemplates(showFullPaths)
  UpdatePathDisplay_CustomProjects(showFullPaths)
  UpdatePathDisplay_ProjectLists(showFullPaths)
  UpdatePathDisplay_Backups(showFullPaths)
  UpdatePathDisplay_Docs(showFullPaths)
end

---------------------------
-- Show in Explorer - relay
---------------------------
local function Global_OpenInExplorer()
  if SWSinstalled then
    local tabfocus = RL_GetFocusedTab()
    if tabfocus == TabID.RecentProjects then ShowLocation_RecentProject()
      elseif tabfocus == TabID.ProjectTemplates then ShowLocation_ProjectTemplates()
      elseif tabfocus == TabID.TrackTemplates then ShowLocation_TrackTemplates()
      elseif tabfocus == TabID.CustomProjects then ShowLocation_CustomProject()
      elseif tabfocus == TabID.ProjectLists then ShowLocation_ProjectList()
      elseif tabfocus == TabID.Backups then ShowLocation_Backups()
      elseif tabfocus == TabID.Docs then ShowLocation_Docs()
    end
  end
end

------------------
-- Listbox content
------------------
RecentProjects = {
  maxIndex,
  items = {},
  names = {},
  paths = {},
  filteredNames = {},
  filteredPaths = {},
}

local function FillRecentProjectsListbox()
  RecentProjects.names = {}
  RecentProjects.items = {}
  RecentProjects.paths = {}
  RecentProjects.check = {}

  local lastEntry = false
  local recentpathtag = {}
  local e = 0
  local p = 0

  -- get recent project count
  repeat
    p = p + 1
    if p < 10 then recentpathtag[p] = "recent0" .. tostring(p)
    else recentpathtag[p] = "recent" .. tostring(p) end

    local _, value = reaper.BR_Win32_GetPrivateProfileString("recent", recentpathtag[p], "noEntry", reaperIniPath)
    if value == "noEntry" then 
      lastEntry = true;
      break;
    end
  until (lastEntry)

  -- no [Recent] section exists yet
  if (p == 1 and lastEntry == true) then return end

  -- iterate through entries
  RecentProjects.maxIndex = p - 1
  recentpathtag = {}
  repeat
    p = p - 1
    if p < 10 then recentpathtag[p] = "recent0" .. tostring(p)
    else recentpathtag[p] = "recent" .. tostring(p) end

    local _, fullPath = reaper.BR_Win32_GetPrivateProfileString("recent", recentpathtag[p], "noEntry", reaperIniPath)
    if fullPath ~= "" then
      if not CheckForDuplicates(RecentProjects.paths, fullPath) then
        e = e + 1
        RecentProjects.paths[e] = fullPath
        RecentProjects.names[e] = RemoveExtension(GetFilenameWithoutPath(fullPath), FileTypes.rpp)
        MsgDebug(p .. ": " .. fullPath)
      end
    end
  until p == 1

  if #RecentProjects.names == 0 then noRecentProjects = true
  else 
    noRecentProjects = false
    for i = 1, #RecentProjects.names do
      RecentProjects.items[RecentProjects.names[i]] = RecentProjects.paths[i]
    end
  end

  Global_UpdatePathDisplayMode()
  GUI.elms.tab_recentProjects_listbox:redraw()
end

-------------------------------
-- Subdirectory paths and names
-------------------------------
local function GetSubFolderEntries(defaultPath, custompath, extensionFilter)
  local tempFolders, tempFiles
  local subDirPaths = {}
  local subDirFiles = {}

  if defaultPath == "All" then
    subDirPaths = {"< All >"}
    subDirFiles = {"< All >"}
  elseif IsNotNullOrEmpty(defaultPath) then 
    subDirPaths = {"< All >"}
    subDirFiles = {"< All >"}

    subDirPaths[2] = defaultPath
    subDirFiles[2] = "< " .. GetFolderName(defaultPath) .. " >"

    local tempFolders, tempFiles = GetSubFolders(defaultPath, extensionFilter)
    JoinTables(subDirPaths, tempFolders)
    JoinTables(subDirFiles, tempFiles)
  end
  
  if IsNotNullOrEmpty(custompath) then
    local multiPaths = SplitMultiPaths(custompath)
    for m = 1, #multiPaths do
      local currentPath = multiPaths[m]
      subDirPaths[#subDirPaths + 1] = currentPath
      subDirFiles[#subDirFiles + 1] = "< " .. GetFolderName(currentPath) .. " >"

      local tempFolders, tempFiles = GetSubFolders(currentPath, extensionFilter)
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
  filteredNames ={},
  filteredPaths ={}
}

SubDirProjectTemplates = {
  names = {},
  paths = {}
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
  ProjectTemplates.items = {}
  ProjectTemplates.names = {}
  ProjectTemplates.paths = {}
  noProjectTemplates = false
  local pos = 1

  for i = 1, #tempTemplates do
    local fileName = GetFilenameWithoutPath(tempTemplates[i])
    if string.find(GetFileExtension(fileName, #FileTypes.rpp - 1), FileTypes.rpp) then
      MsgDebug(tempTemplates[i])
      ProjectTemplates.names[pos] = RemoveExtension(fileName, FileTypes.rpl)
      ProjectTemplates.items[ProjectTemplates.names[pos]] = tempTemplates[i]
      ProjectTemplates.paths[pos] = tempTemplates[i]
      pos = pos + 1
    end
  end

  Global_UpdatePathDisplayMode()
  GUI.elms.tab_projectTemplates_listbox:redraw()
end

local function FillProjectTemplateListbox()
  local tempTemplates = GetFiles(projectTemplatePath)
  if #custompathProjectTemplates > 1 then
    local multiPaths = SplitMultiPaths(custompathProjectTemplates)
    for m = 1, #multiPaths do JoinTables(tempTemplates, GetFiles(multiPaths[m])) end
  end

  if #tempTemplates == 0 then noProjectTemplates = true
  else FillProjectTemplateListBoxBase(tempTemplates) end
end

-------------------------
-- Track Template Listbox
-------------------------
TrackTemplates = {
  items = {},
  names = {},
  paths = {},
  filteredNames = {},
  filteredPaths = {}
}

local function FillTrackTemplateListboxBase(tempTemplates)
  TrackTemplates.items = {}
  TrackTemplates.names = {}
  TrackTemplates.paths = {}
  noTrackTemplates = false
  local pos = 1

  for i = 1, #tempTemplates do
    local fileName = GetFilenameWithoutPath(tempTemplates[i])
    if GetFileExtension(fileName, #FileTypes.tracktemplate - 1) == FileTypes.tracktemplate then
      MsgDebug(tempTemplates[i])
      TrackTemplates.names[pos] = RemoveExtension(fileName, FileTypes.tracktemplate)
      TrackTemplates.items[TrackTemplates.names[pos]] = tempTemplates[i]
      TrackTemplates.paths[pos] = tempTemplates[i]
      pos = pos + 1
    end
  end

  Global_UpdatePathDisplayMode()
  GUI.elms.tab_trackTemplates_listbox:redraw()
end

local function FillTrackTemplateListbox()
  local tempTemplates = GetFiles(trackTemplatePath)
  if #customPathTrackTemplates > 1 then
    local multiPaths = SplitMultiPaths(customPathTrackTemplates)
    for m = 1, #multiPaths do JoinTables(tempTemplates, GetFiles(multiPaths[m])) end
  end

  if #tempTemplates == 0 then noTrackTemplates = true
  else FillTrackTemplateListboxBase(tempTemplates) end
end

-------------------------
-- Custom Project Listbox
-------------------------
CustomProjects = {
  items = {},
  names = {},
  paths = {},
  filteredNames = {},
  filteredPaths = {}
}

local function FillCustomProjectsListboxBase(dirFiles, pos)
  for i = 1, #dirFiles do
    local fileName = GetFilenameWithoutPath(dirFiles[i])
    if GetFileExtension(fileName, #FileTypes.rpp - 1) == FileTypes.rpp then
      MsgDebug(dirFiles[i])
      CustomProjects.names[pos] = RemoveExtension(fileName, FileTypes.rpp)
      CustomProjects.items[CustomProjects.names[pos]] = dirFiles[i]
      CustomProjects.paths[pos] = dirFiles[i]
      pos = pos + 1
    end
  end

  noCustomProjects = (pos <= 1)
  Global_UpdatePathDisplayMode()
  GUI.elms.tab_customProjects_listbox:redraw()

  return pos
end

local function InitCustomProjectTables()
  CustomProjects.items = {}
  CustomProjects.names = {}
  CustomProjects.paths = {}
end

local function FillCustomProjectsListbox()
  if #custompathProjects > 1 then
    InitCustomProjectTables()
    local multiPaths = SplitMultiPaths(custompathProjects)
    for m = 1, #multiPaths do
      FillCustomProjectsListboxBase(GetFiles(multiPaths[m]), 1)
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
  filteredProjectNames = {},
  filteredProjectPaths = {}
}

local function RPL_ParseRPLFile(selected)
  for i = 1, #selected do
    local file = io.open(ProjectLists.rplPaths[selected[i]] .. GetPathSeparator() .. ProjectLists.rplFiles[selected[i]] .. FileTypes.rpl, "rb")
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
  end

   GUI.elms.tab_projectLists_listboxProjects.list = ProjectLists.projectNames
end

local function RPL_InitProjectListTables()
  ProjectLists.projectNames = {}
  ProjectLists.projectPaths = {}
  ProjectLists.projectItems = {}
end

local function RPL_FillProjectListBoxWithAll()
  local vals = GUI.elms.tab_projectLists_listboxRPL.list
  if #vals > 0 then
    RPL_InitProjectListTables()
    local allRPLProjects = {}
    for v = 2, #vals do allRPLProjects[v - 1] = v end
    RPL_ParseRPLFile(allRPLProjects)
    TabSelectionIndex[TabID.ProjectLists] = 1
    GUI.Val("tab_projectLists_listboxProjects", {1})
  end
  Global_UpdatePathDisplayMode()
end

local function RPL_FillProjectListBox()
  local vals = GetSelectionTable(GUI.Val("tab_projectLists_listboxRPL"))
  if #GUI.elms.tab_projectLists_listboxRPL.list > 0 then
    RPL_InitProjectListTables()
    RPL_ParseRPLFile(vals)
    TabSelectionIndex[TabID.ProjectLists] = 1
    GUI.Val("tab_projectLists_listboxProjects", {1})
  end
  Global_UpdatePathDisplayMode()
end

------------------------
-- Backups Lists Listbox
------------------------
Backups = {
  items = {},
  names = {},
  paths = {},
  filteredNames = {},
  filteredPaths = {}
}

local function FillBackupsListboxBase(dirFiles, pos)
  for i = 1, #dirFiles do
    local fileName = GetFilenameWithoutPath(dirFiles[i])
    if GetFileExtension(fileName, #FileTypes.backup - 1) == FileTypes.backup then
      MsgDebug(dirFiles[i])
      Backups.names[pos] = RemoveExtension(fileName, FileTypes.backup)
      Backups.items[Backups.names[pos]] = dirFiles[i]
      Backups.paths[pos] = dirFiles[i]
      pos = pos + 1
    end
  end

  noBackups = (pos <= 1)
  GUI.elms.tab_backups_listbox.list = Backups.names
  Global_UpdatePathDisplayMode()
  
  return pos
end

local function InitBackupsTables()
  Backups.items = {}
  Backups.names = {}
  Backups.paths = {}
end

local function FillBackupsListbox()
  if #custompathBackups > 1 then
    InitBackupsTables()
    local multiPaths = SplitMultiPaths(custompathBackups)
    local pos = 1
    for m = 1, #multiPaths do
      pos = FillBackupsListboxBase(GetFiles(multiPaths[m]), pos)
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
  filteredNames = {},
  filteredPaths = {}
}

local function InitDocsTables()
  Docs.items = {}
  Docs.names = {}
  Docs.paths = {}
end

local function FillDocsListboxBase(dirFiles, pos)
  for i = 1, #dirFiles do
    local fileName = GetFilenameWithoutPath(dirFiles[i])
    if GetFileExtension(fileName, #FileTypes.docs - 1) == FileTypes.docs then
      MsgDebug(dirFiles[i])
      Docs.names[pos] = RemoveExtension(fileName, FileTypes.docs)
      Docs.items[Docs.names[pos]] = dirFiles[i]
      Docs.paths[pos] = dirFiles[i]
      pos = pos + 1
    end
  end

  noDocs = (pos <= 1)
  GUI.elms.tab_docs_listbox.list = Docs.names
  Global_UpdatePathDisplayMode()

  return pos
end

local function FillDocsListbox()
  if #custompathDocs > 1 then
    InitDocsTables()
    local multiPaths = SplitMultiPaths(custompathDocs)
    local pos = 1
    for m = 1, #multiPaths do
      pos = FillDocsListboxBase(GetFiles(multiPaths[m]), pos)
    end
  end
end

----------------------------------
-- Fill the listboxes with entries
----------------------------------
local function LoadCustomFolderPaths()
  custompathProjectTemplates = reaper.GetExtState(appname, "custompath_projecttemplates") 
  customPathTrackTemplates = reaper.GetExtState(appname, "custompath_tracktemplates")
  custompathProjects = reaper.GetExtState(appname, "custompath_projects")
  custompathProjectLists = reaper.GetExtState(appname, "custompath_projectlists")
  custompathBackups = reaper.GetExtState(appname, "custompath_backups")
  custompathDocs = reaper.GetExtState(appname, "custompath_docs")
end

LoadCustomFolderPaths()

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

local function Global_NewProject()
  reaper.Main_OnCommand(40023, 0) -- File: New project
  Global_CheckWindowPinState() 
end

local function Global_NewTab()
  reaper.Main_OnCommand(40859, 0) -- New project tab
  Global_CheckWindowPinState() 
end

local function Global_NewTabIgnoreDefaultTemplate()
  reaper.Main_OnCommand(41929, 0) -- New project tab (ignore default template)
  Global_CheckWindowPinState()
end

local function Global_SaveAsNewVersion()
  if GUI.Val("main_checklistSaveAsNewVersion") then
    reaper.Main_OnCommand(41895, 0) -- [Main] - File: Save new version of project (automatically increment project name)
  end
end

local function Global_Load(tabmode, selectedFile, fileCount)
  if selectedFile ~= nil then 
    if tabmode then
        reaper.Main_OnCommand(40859, 0) -- New project tab
        reaper.Main_openProject(selectedFile) 
        Global_SaveAsNewVersion()
        RL_CleanupAtExit()
    else
      if fileCount > 1 then reaper.Main_OnCommand(40859, 0) end -- New project tab
      reaper.Main_openProject(selectedFile)
      Global_SaveAsNewVersion()
      RL_CleanupAtExit()
    end
  end
end

local function Global_ProjectTemplateLoadBase(template)
  if template ~= nil then
    if reaperversion ~= nil and #reaperversion > 1 and ((reaperversion:match("6.")) or reaperversion:match("5.99") or reaperversion:match("5.98[3-9]")) then
      -- logic for Reaper versions 5.983 or higher
      if projectTemplateLoadMode == 1 then reaper.Main_openProject("template:" .. template) -- load as template
      else reaper.Main_openProject(template) end -- open template file for editing
    else
      -- logic for Reaper versions older than 5.983
      reaper.Main_openProject(template) -- open template file for editing
      if projectTemplateLoadMode == 1 then reaper.Main_OnCommand(40022,0) end -- File: Save project as
    end
    RL_CleanupAtExit()
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
  if not noRecentProjects then
    local vals = GetSelectionTable(GUI.Val("tab_recentProjects_listbox"))
    for p = 1, #vals do
      if FilterActive.RecentProjects then selectedProject = RecentProjects.items[RecentProjects.filteredNames[vals[p]]]
      else selectedProject = RecentProjects.items[RecentProjects.names[vals[p]]] end
      Global_Load(tabmode, selectedProject, p);
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
  if not noCustomProjects then
    local vals = GetSelectionTable(GUI.Val("tab_customProjects_listbox"))
    for p = 1, #vals do
      if FilterActive.CustomProjects then selectedProject = CustomProjects.items[CustomProjects.filteredNames[vals[p]]]
      else selectedProject = CustomProjects.items[CustomProjects.names[vals[p]]] end
      Global_Load(tabmode, selectedProject, p);
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
  if not noProjectTemplates then
    local vals = GetSelectionTable(GUI.Val("tab_projectTemplates_listbox"))
    for p = 1, #vals do 
      if FilterActive.ProjectTemplates then selectedProjectTemplate = ProjectTemplates.items[ProjectTemplates.filteredNames[vals[p]]]
      else selectedProjectTemplate = ProjectTemplates.items[ProjectTemplates.names[vals[p]]] end
      
      if tabmode then
        reaper.Main_OnCommand(40859, 0) -- New project tab
        Global_ProjectTemplateLoadBase(selectedProjectTemplate)
      else
        Global_ProjectTemplateLoad(selectedProjectTemplate, p)
      end
  end
  
    GUI.Val("tab_projectTemplates_listbox",{})
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
local function Load_TrackTemplate()
  if not noTrackTemplates then
    local selectedTrackTemplate
    local vals = GetSelectionTable(GUI.Val("tab_trackTemplates_listbox"))
    for p = 1, #vals do
      if FilterActive.TrackTemplates then selectedTrackTemplate = TrackTemplates.items[TrackTemplates.filteredNames[vals[p]]]
      else selectedTrackTemplate = TrackTemplates.items[TrackTemplates.names[vals[p]]] end
      if selectedTrackTemplate ~= nil then 
        reaper.Main_openProject(selectedTrackTemplate) 
      end
    end 
    Global_CheckWindowPinState()
  end
end

--------------------------------
-- Project List button functions
--------------------------------
local function Load_ProjectListProject_Base(tabmode)
  if not noProjectLists then
    local vals = GetSelectionTable(GUI.Val("tab_projectLists_listboxProjects"))
    for p = 1, #vals do
      if FilterActive.ProjectLists then selectedProjectListProject = RemoveWhiteSpaces(ProjectLists.filteredProjectPaths[vals[p]])
      else selectedProjectListProject = RemoveWhiteSpaces(ProjectLists.projectPaths[vals[p]]) end
      Global_Load(tabmode, selectedProjectListProject, p);
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
  if not noBackups then
    local vals = GetSelectionTable(GUI.Val("tab_backups_listbox"))
      for p = 1, #vals do
        if FilterActive.Backups then selectedBackupFile = RemoveWhiteSpaces(Backups.filteredPaths[vals[p]])
        else selectedBackupFile = RemoveWhiteSpaces(Backups.paths[vals[p]]) end
        Global_Load(tabmode, selectedBackupFile, p);
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
local function ScrollToTop(tabIndex)
  local element = ListboxElements[tabIndex]
  if element.wnd_h ~= nil and element.wnd_y ~= nil then
    element.wnd_y = GUI.clamp(1, element.wnd_y - element.wnd_h, math.max(#element.list - element.wnd_h + 1, 1))
    element:redraw()
  end
end

local function Scroll(element, listIndex, direction)
  if element and element.wnd_h ~= nil and element.wnd_y ~= nil then
    if listIndex > element.wnd_h then 
      element.wnd_y = GUI.clamp(1, element.wnd_y + direction, math.max(#element.list - element.wnd_h + 1, 1))
      element:redraw()
    end
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
  Docs = false
}

FilterColor = {
  active = "elm_fill",
  inactive = "txt"
}

local replaceMatchString = function (c)
  return "[" .. string.lower(c) .. string.upper(c) .. "]"
end

local function GetSearchTable(searchString)
  searchTable = {}
  for match in string.gmatch(searchString, "[^%s]+") do -- space separator
    searchTable[#searchTable + 1] = string.gsub(match, "%a", replaceMatchString)
  end
  return searchTable
end

-------------------------
-- Filter Recent Projects
-------------------------
local function Filter_RecentProject_Apply()
  RecentProjects.filteredNames = {}
  RecentProjects.filteredPaths = {}
  local searchList = {}
  local searchStr = GUI.Val("tab_recentProjects_txtFilter")
  if #searchStr > 0 then
    FilterActive.RecentProjects = true
    GUI.elms.tab_recentProjects_txtFilter.color = FilterColor.active
    GUI.elms.tab_recentProjects_btnFilterClear.col_txt = FilterColor.active

    if showFullPaths then searchList = RecentProjects.paths else searchList = RecentProjects.names end
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
        for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          RecentProjects.filteredNames[RecentProjects.names[i]] = RecentProjects.paths[i]
          if not CheckForDuplicates(RecentProjects.filteredNames, RecentProjects.names[i]) then
            RecentProjects.filteredNames[#RecentProjects.filteredNames + 1] = RecentProjects.names[i]
            RecentProjects.filteredPaths[#RecentProjects.filteredPaths + 1] = RecentProjects.items[RecentProjects.names[i]]
          end
        end
      end
    end
  else
    FilterActive.RecentProjects = false
    GUI.elms.tab_recentProjects_txtFilter.color = FilterColor.inactive
    GUI.elms.tab_recentProjects_btnFilterClear.col_txt = FilterColor.inactive
  end

  UpdatePathDisplay_RecentProjects(showFullPaths)
  GUI.Val("tab_recentProjects_listbox",{})
  ScrollToTop(TabID.RecentProjects)
end

local function Filter_RecentProject_Clear()
  GUI.Val("tab_recentProjects_txtFilter", "")
  Filter_RecentProject_Apply()
end

---------------------------
-- Filter Project Templates
---------------------------
local function Filter_ProjectTemplate_Apply()
  ProjectTemplates.filteredNames = {}
  ProjectTemplates.filteredPaths = {}
  local searchList = {}
  local searchStr = GUI.Val("tab_projectTemplates_txtFilter")
  if #searchStr > 0 then
    FilterActive.ProjectTemplates = true
    GUI.elms.tab_projectTemplates_txtFilter.color = FilterColor.active
    GUI.elms.tab_projectTemplates_btnFilterClear.col_txt = FilterColor.active
    
    if showFullPaths then searchList = ProjectTemplates.paths else searchList = ProjectTemplates.names end
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          ProjectTemplates.filteredNames[ProjectTemplates.names[i]] = ProjectTemplates.names[i]
          if not CheckForDuplicates(ProjectTemplates.filteredNames, ProjectTemplates.names[i]) then
            ProjectTemplates.filteredNames[#ProjectTemplates.filteredNames + 1] = ProjectTemplates.names[i]
            ProjectTemplates.filteredPaths[#ProjectTemplates.filteredPaths + 1] = ProjectTemplates.items[ProjectTemplates.names[i]]
          end
        end
      end
    end
  else 
    FilterActive.ProjectTemplates = false
    GUI.elms.tab_projectTemplates_txtFilter.color = FilterColor.inactive
    GUI.elms.tab_projectTemplates_btnFilterClear.col_txt = FilterColor.inactive
  end

  UpdatePathDisplay_ProjectTemplates(showFullPaths)
  GUI.Val("tab_projectTemplates_listbox",{})
  ScrollToTop(TabID.ProjectTemplates)
end

local function Filter_ProjectTemplate_Clear()
  GUI.Val("tab_projectTemplates_txtFilter", "")
  Filter_ProjectTemplate_Apply()
end

-------------------------
-- Filter Track Templates
-------------------------
local function Filter_TrackTemplate_Apply()
  TrackTemplates.filteredNames = {}
  TrackTemplates.filteredPaths = {}
  local searchList = {}
  local searchStr = GUI.Val("tab_trackTemplates_txtFilter")
  if #searchStr > 0 then
    FilterActive.TrackTemplates = true
    GUI.elms.tab_trackTemplates_txtFilter.color = FilterColor.active
    GUI.elms.tab_trackTemplates_btnFilterClear.col_txt = FilterColor.active
    
    if showFullPaths then searchList = TrackTemplates.paths else searchList = TrackTemplates.names end
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          TrackTemplates.filteredNames[TrackTemplates.names[i]] = TrackTemplates.names[i]
          if not CheckForDuplicates(TrackTemplates.filteredNames, TrackTemplates.names[i]) then
            TrackTemplates.filteredNames[#TrackTemplates.filteredNames + 1] = TrackTemplates.names[i]
            TrackTemplates.filteredPaths[#TrackTemplates.filteredPaths + 1] = TrackTemplates.items[TrackTemplates.names[i]]
          end
        end
      end
    end
  else
    FilterActive.TrackTemplates = false
    GUI.elms.tab_trackTemplates_txtFilter.color = FilterColor.inactive
    GUI.elms.tab_trackTemplates_btnFilterClear.col_txt = FilterColor.inactive
  end
  
  UpdatePathDisplay_TrackTemplates(showFullPaths)
  GUI.Val("tab_trackTemplates_listbox",{})
  ScrollToTop(TabID.TrackTemplates)
end

local function Filter_TrackTemplate_Clear()
  GUI.Val("tab_trackTemplates_txtFilter", "")
  Filter_TrackTemplate_Apply()
end

------------------
-- Filter Projects
------------------
local function Filter_CustomProjects_Apply()
  CustomProjects.filteredNames = {}
  CustomProjects.filteredPaths = {}
  local searchList = {}
  local searchStr = GUI.Val("tab_customProjects_txtFilter")
  if #searchStr > 0 then
    FilterActive.CustomProjects = true
    GUI.elms.tab_customProjects_txtFilter.color = FilterColor.active
    GUI.elms.tab_customProjects_btnFilterClear.col_txt = FilterColor.active
    
    if showFullPaths then searchList = CustomProjects.paths else searchList = CustomProjects.names end
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          CustomProjects.filteredNames[CustomProjects.names[i]] = CustomProjects.names[i]
          if not CheckForDuplicates(CustomProjects.filteredNames, CustomProjects.names[i]) then
            CustomProjects.filteredNames[#CustomProjects.filteredNames + 1] = CustomProjects.names[i]
            CustomProjects.filteredPaths[#CustomProjects.filteredPaths + 1] = CustomProjects.items[CustomProjects.names[i]]
          end
        end
      end
    end
  else
    FilterActive.CustomProjects = false
    GUI.elms.tab_customProjects_txtFilter.color = FilterColor.inactive
    GUI.elms.tab_customProjects_btnFilterClear.col_txt = FilterColor.inactive
  end

  UpdatePathDisplay_CustomProjects(showFullPaths)
  GUI.Val("tab_customProjects_listbox",{})
  ScrollToTop(TabID.CustomProjects)
end

local function Filter_CustomProjects_Clear()
  GUI.Val("tab_customProjects_txtFilter", "")
  Filter_CustomProjects_Apply()
end

-----------------------
-- Filter Project Lists
-----------------------
local function Filter_ProjectLists_Apply()
  ProjectLists.filteredProjectNames = {}
  ProjectLists.filteredProjectPaths = {}
  local searchList = {}
  local searchStr = GUI.Val("tab_projectLists_txtFilter")
  if #searchStr > 0 then
    FilterActive.ProjectLists = true
    GUI.elms.tab_projectLists_txtFilter.color = FilterColor.active
    GUI.elms.tab_projectLists_btnFilterClear.col_txt = FilterColor.active
    
    if showFullPaths then searchList = ProjectLists.projectPaths else searchList = ProjectLists.projectNames end
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          ProjectLists.filteredProjectNames[ProjectLists.projectNames[i]] = ProjectLists.projectNames[i]
          if not CheckForDuplicates(ProjectLists.filteredProjectNames, ProjectLists.projectNames[i]) then
            ProjectLists.filteredProjectNames[#ProjectLists.filteredProjectNames + 1] = ProjectLists.projectNames[i]
            ProjectLists.filteredProjectPaths[#ProjectLists.filteredProjectPaths + 1] = ProjectLists.projectItems[ProjectLists.projectNames[i]]
          end
        end
      end
    end
  else
    FilterActive.ProjectLists = false
    GUI.elms.tab_projectLists_txtFilter.color = FilterColor.inactive
    GUI.elms.tab_projectLists_btnFilterClear.col_txt = FilterColor.inactive
  end

  UpdatePathDisplay_ProjectLists(showFullPaths)
  GUI.Val("tab_projectLists_listboxProjects",{})
  ScrollToTop(TabID.ProjectLists)
end

local function Filter_ProjectLists_Clear()
  GUI.Val("tab_projectLists_txtFilter", "")
  Filter_ProjectLists_Apply()
end

-----------------
-- Filter Backups
-----------------
local function Filter_Backups_Apply()
  Backups.filteredNames = {}
  Backups.filteredPaths = {}
  local searchList = {}
  local searchStr = GUI.Val("tab_backups_txtFilter")
  if #searchStr > 0 then
    FilterActive.Backups = true
    GUI.elms.tab_backups_txtFilter.color = FilterColor.active
    GUI.elms.tab_backups_btnFilterClear.col_txt = FilterColor.active
    
    if showFullPaths then searchList = Backups.paths else searchList = Backups.names end
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          Backups.filteredNames[Backups.names[i]] = Backups.names[i]
          if not CheckForDuplicates(Backups.filteredNames, Backups.names[i]) then
            Backups.filteredNames[#Backups.filteredNames + 1] = Backups.names[i]
            Backups.filteredPaths[#Backups.filteredPaths + 1] = Backups.items[Backups.names[i]]
          end
        end
      end
    end
  else
    FilterActive.Backups = false
    GUI.elms.tab_backups_txtFilter.color = FilterColor.inactive
    GUI.elms.tab_backups_btnFilterClear.col_txt = FilterColor.inactive
  end
  
  UpdatePathDisplay_Backups(showFullPaths)
  GUI.Val("tab_backups_listbox",{})
  ScrollToTop(TabID.Backups)
end

local function Filter_Backups_Clear()
  GUI.Val("tab_backups_txtFilter", "")
  Filter_Backups_Apply()
end

--------------
-- Filter Docs
--------------
local function Filter_Docs_Apply()
  Docs.filteredNames = {}
  Docs.filteredPaths = {}
  local searchList = {}
  local searchStr = GUI.Val("tab_docs_txtFilter")
  if #searchStr > 0 then
    FilterActive.Docs = true
    GUI.elms.tab_docs_txtFilter.color = FilterColor.active
    GUI.elms.tab_docs_btnFilterClear.col_txt = FilterColor.active
    
    if showFullPaths then searchList = Docs.paths else searchList = Docs.names end
    local searchterms = GetSearchTable(searchStr)
    for t = 1, #searchterms do
      for i = 1, #searchList do
        if string.find(searchList[i], searchterms[t]) then
          Docs.filteredNames[Docs.names[i]] = Docs.names[i]
          if not CheckForDuplicates(Docs.filteredNames, Docs.names[i]) then
            Docs.filteredNames[#Docs.filteredNames + 1] = Docs.names[i]
            Docs.filteredPaths[#Docs.filteredPaths + 1] = Docs.items[Docs.names[i]]
          end
        end
      end
    end
  else
    FilterActive.Docs = false
    GUI.elms.tab_docs_txtFilter.color = FilterColor.inactive
    GUI.elms.tab_docs_btnFilterClear.col_txt = FilterColor.inactive
  end
  
  UpdatePathDisplay_Docs(showFullPaths)
  GUI.Val("tab_docs_listbox",{})
  ScrollToTop(TabID.Docs)
end

local function Filter_Docs_Clear()
  GUI.Val("tab_docs_txtFilter", "")
  Filter_Docs_Apply()
end

local function RL_Keys_ClearFilter()
  local tabfocus = RL_GetFocusedTab()
  if tabfocus == TabID.RecentProjects then Filter_RecentProject_Clear()
    elseif tabfocus == TabID.ProjectTemplates then Filter_ProjectTemplate_Clear()
    elseif tabfocus == TabID.TrackTemplates then Filter_TrackTemplate_Clear()
    elseif tabfocus == TabID.CustomProjects then Filter_CustomProjects_Clear()
    elseif tabfocus == TabID.ProjectLists then Filter_ProjectLists_Clear()
    elseif tabfocus == TabID.Backups then Filter_Backups_Clear()
    elseif tabfocus == TabID.Docs then Filter_Docs_Clear()
  end
end

----------------------------
-- Listbox Refresh functions
----------------------------
local function RefreshRecentProjects()
  MsgDebug("-----------------------\nRefresh Recent Projects")
  if SWSinstalled then
    FillRecentProjectsListbox()
    Filter_RecentProject_Apply()
  else MsgStatusBar("Using the [ Recent Projects ] tab requires SWS Extensions installed!", false, true, false) end
end

local function RefreshProjectTemplates()
  MsgDebug("-----------------------\nRefresh Project Templates")
  -- subfolders
  if showSubfolderPanel then 
    local subDirPaths, subDirFiles = GetSubFolderEntries(projectTemplatePath, custompathProjectTemplates, FileTypes.rpp)
    SubfolderPaths.projectTemplates = subDirPaths
    SubfolderNames.projectTemplates = subDirFiles
  
    if not showSubFolderPaths then GUI.elms.tab_projectTemplates_subfolders.list = subDirFiles
    else GUI.elms.tab_projectTemplates_subfolders.list = subDirPaths end
  
    Global_UpdateSubfolderPathDisplayMode()
    GUI.Val("tab_projectTemplates_subfolders", {1})
  end
  -- main
  FillProjectTemplateListbox()
  Filter_ProjectTemplate_Apply()
end

local function RefreshTrackTemplates()
  MsgDebug("-----------------------\nRefresh Track Templates")
  -- subfolders
  if showSubfolderPanel then
    local subDirPaths, subDirFiles = GetSubFolderEntries(trackTemplatePath, customPathTrackTemplates, FileTypes.tracktemplate)
    SubfolderPaths.trackTemplates = subDirPaths
    SubfolderNames.trackTemplates = subDirFiles
  
    if not showSubFolderPaths then GUI.elms.tab_trackTemplates_subfolders.list = subDirFiles
    else GUI.elms.tab_trackTemplates_subfolders.list = subDirPaths end
    
    Global_UpdateSubfolderPathDisplayMode()
    GUI.Val("tab_trackTemplates_subfolders", {1})
  end
  -- main
  FillTrackTemplateListbox()
  Filter_TrackTemplate_Apply()
end

local msgNoFolderPathSet = "No folder paths set in the [ Options ] tab for "

local function RefreshCustomProjects()
  MsgDebug("-----------------------\nRefresh Custom Projects")
  if IsNotNullOrEmpty(custompathProjects) then
    -- subfolders
    if showSubfolderPanel and #custompathProjects > 1 then 
        local subDirPaths, subDirFiles = GetSubFolderEntries("All", custompathProjects, FileTypes.rpp)
        SubfolderPaths.customProjects = subDirPaths
        SubfolderNames.customProjects = subDirFiles
    
        if not showSubFolderPaths then GUI.elms.tab_customProjects_subfolders.list = subDirFiles
        else GUI.elms.tab_customProjects_subfolders.list = subDirPaths end
        
        Global_UpdateSubfolderPathDisplayMode()
        GUI.Val("tab_customProjects_subfolders", {1})
    end
    -- main
    FillCustomProjectsListbox()
    Filter_CustomProjects_Apply()
  else
    MsgStatusBar(msgNoFolderPathSet .. "[ Projects ]", true, true, false)
  end
end

local function RPL_FillProjectListboxBase(dirFiles)
  local projectListFiles = GetFiles(dirFiles)
  for i = 1, #projectListFiles do
    MsgDebug("d " .. projectListFiles[i])
    local fileName = GetFilenameWithoutPath(projectListFiles[i])
    local rplName = RemoveExtension(fileName, FileTypes.rpl)
    if IsNotNullOrEmpty(rplName) and GetFileExtension(fileName, #FileTypes.rpl - 1) == FileTypes.rpl then
      ProjectLists.rplFiles[#ProjectLists.rplFiles + 1] = rplName
      ProjectLists.rplPaths[#ProjectLists.rplPaths + 1] = GetDirectoryPath(projectListFiles[i])
    end
  end
end

local function RefreshProjectList()
  MsgDebug("-----------------------\nRefresh Project Lists")
  if IsNotNullOrEmpty(custompathProjectLists) then
    if #custompathProjectLists > 1 then
      RPL_InitProjectListTables()
      ProjectLists.rplFiles = {}
      ProjectLists.rplPaths = {}
      ProjectLists.rplFiles[#ProjectLists.rplFiles + 1] = "< All >"
      ProjectLists.rplPaths[#ProjectLists.rplPaths + 1] = "< All >"

      local multiPaths = SplitMultiPaths(custompathProjectLists)
      for m = 1, #multiPaths do
        local fileName = GetLastDirectoryInPath(multiPaths[m])
        RPL_FillProjectListboxBase(multiPaths[m])
      end
      noProjectLists = (#ProjectLists.rplFiles <= 1)
    end
    
    GUI.elms.tab_projectLists_listboxRPL.list = ProjectLists.rplFiles
    Global_UpdatePathDisplayMode()
    Filter_ProjectLists_Apply()
    GUI.Val("tab_projectLists_listboxRPL", {1})
    RPL_FillProjectListBoxWithAll()
  else
    MsgStatusBar(msgNoFolderPathSet .. "[ Project Lists ]", true, true, false)
  end
end

local function RefreshBackups()
  MsgDebug("-----------------------\nRefresh Backups")
  if IsNotNullOrEmpty(custompathBackups) then
    -- subfolders
    if showSubfolderPanel and #custompathBackups > 1 then
        local subDirPaths, subDirFiles = GetSubFolderEntries("All", custompathBackups, FileTypes.backup)
        SubfolderPaths.backups = subDirPaths
        SubfolderNames.backups = subDirFiles
    
        if not showSubFolderPaths then GUI.elms.tab_backups_subfolders.list = subDirFiles
        else GUI.elms.tab_backups_subfolders.list = subDirPaths end
      
        Global_UpdateSubfolderPathDisplayMode()
        GUI.Val("tab_backups_subfolders", {1})
    end
    -- main
    FillBackupsListbox()
    Filter_Backups_Apply()
  else
    MsgStatusBar(msgNoFolderPathSet .. "[ Backups ]", true, true, false)
  end
end

local function RefreshDocs()
  if SWSinstalled then  
    MsgDebug("-----------------------\nRefresh Docs")
    if IsNotNullOrEmpty(custompathDocs) then
      -- subfolders
      if showSubfolderPanel and #custompathDocs > 1 then
        local subDirPaths, subDirFiles = GetSubFolderEntries("All", custompathDocs, FileTypes.docs)
        SubfolderPaths.docs = subDirPaths
        SubfolderNames.docs = subDirFiles
    
        if not showSubFolderPaths then GUI.elms.tab_docs_subfolders.list = subDirFiles
        else GUI.elms.tab_docs_subfolders.list = subDirPaths end
      
        Global_UpdateSubfolderPathDisplayMode()
        GUI.Val("tab_docs_subfolders", {1})
      end
      -- main
      FillDocsListbox()
      Filter_Docs_Apply()
    else
      MsgStatusBar(msgNoFolderPathSet .. "[ Docs ]", true, true, false)
    end
  else
    MsgStatusBar("Opening files on the [ Docs ] tab requires SWS Extensions installed!", false, true, false)
  end
end

---------------------
-- Clear custom paths
----------------------
local function Path_Clear_ProjectTemplateFolder()
  ProjectTemplates.items = {}
  ProjectTemplates.names = {}
  ProjectTemplates.paths = {}
  ProjectTemplates.filteredNames = {}
  ProjectTemplates.pfilteredPathsaths = {}

  GUI.Val("options_txtProjectTemplatesPath", "")
  GUI.elms.tab_projectTemplates_listbox.list = {}
  
  reaper.DeleteExtState(appname, "custompath_projecttemplates",1)
  RefreshProjectTemplates()
  MsgStatusBar("Additional [ Project Templates ] paths removed", false, true, false)
end

local function Path_Clear_TrackTemplateFolder()
  TrackTemplates.items = {}
  TrackTemplates.names = {}
  TrackTemplates.paths = {}
  TrackTemplates.filteredNames = {}
  TrackTemplates.pfilteredPathsaths = {}

  GUI.Val("options_txtTrackTemplatesPath", "")
  GUI.elms.tab_trackTemplates_listbox.list = {}
  
  reaper.DeleteExtState(appname, "custompath_tracktemplates",1)
  RefreshTrackTemplates()
  MsgStatusBar("Additional [ Track Templates ] paths removed", false, true, false)
end

local function Path_Clear_CustomProjectFolder()
  custompathProjects = {}
  InitCustomProjectTables()
  CustomProjects.filteredNames = {}
  CustomProjects.filteredPaths = {}
  
  GUI.Val("options_txtCustomProjectsPath", "")
  GUI.elms.tab_customProjects_listbox.list = {}

  reaper.DeleteExtState(appname, "custompath_projects",1)
  MsgStatusBar("[ Projects ] paths removed", false, true, false)
  RefreshCustomProjects()
end

local function Path_Clear_ProjectListFolder()
  RPL_InitProjectListTables()
  ProjectLists.filteredProjectNames = {}
  ProjectLists.rplFiles = {}
  
  GUI.Val("options_txtProjectsListsPath", "")
  GUI.elms.tab_projectLists_listboxRPL.list = {}
  GUI.elms.tab_projectLists_listboxProjects.list = {}

  reaper.DeleteExtState(appname, "custompath_projectlists",1)
  MsgStatusBar("[ Project Lists ] paths removed", false, true, false)
  RefreshProjectList()
end

local function Path_Clear_BackupsFolder()
  InitBackupsTables()
  Backups.filteredNames = {}
  Backups.filteredPaths = {}
  
  GUI.Val("options_txtBackupsPath", "")
  GUI.elms.tab_backups_listbox.list = {}

  reaper.DeleteExtState(appname, "custompath_backups", 1)
  MsgStatusBar("[ Backups ] paths removed", false, true, false)
  RefreshBackups()
end

local function Path_Clear_DocsFolder()
  InitDocsTables()
  Docs.filteredNames = {}
  Docs.filteredPaths = {}
  
  GUI.Val("options_txtDocsPath", "")
  GUI.elms.tab_docs_listbox.list = {}

  reaper.DeleteExtState(appname, "custompath_docs", 1)
  MsgStatusBar("[ Docs ] paths removed", false, true, false)
  RefreshDocs()
end

-------------------
-- Set custom paths
-------------------
local function Path_Set_ProjectTemplateFolder()
  local custompath_projectTemplates = GUI.Val("options_txtProjectTemplatesPath")
  if custompath_projectTemplates == "" then
    MsgStatusBar("Please enter paths for [ Project Templates ] first!", false, true, false)
  else
    reaper.SetExtState(appname, "custompath_projecttemplates", custompath_projectTemplates, 1)
    RefreshProjectTemplates()
    MsgStatusBar("Project Template path set", false, true, false)
  end
end

local function Path_Set_TrackTemplateFolder()
  local customPathTrackTemplates = GUI.Val("options_txtTrackTemplatesPath")
  if customPathTrackTemplates == "" then
    MsgStatusBar("Please enter paths for [ Track Templates ] first!", false, true, false)
  else
    reaper.SetExtState(appname, "custompath_tracktemplates", customPathTrackTemplates, 1)
    RefreshTrackTemplates()
    MsgStatusBar("Track Templates paths set", false, true, false)
  end
end

local function Path_Set_CustomProjectFolder()
  local custompath_customprojects = GUI.Val("options_txtCustomProjectsPath")
  if custompath_customprojects == "" then 
    MsgStatusBar("Please enter paths for [ Projects ] first!", false, true, false)
  else
    reaper.SetExtState(appname, "custompath_projects", custompath_customprojects, 1)
    RefreshCustomProjects()
    MsgStatusBar("Projects paths set", false, true, false)
  end
end

local function Path_Set_ProjectListFolder()
  local custompathProjectLists = GUI.Val("options_txtProjectsListsPath")
  if custompathProjectLists == "" then
    MsgStatusBar("Please enter paths for [ Project Lists ] first!", false, true, false)
  else
    reaper.SetExtState(appname, "custompath_projectlists", custompathProjectLists, 1)
    RefreshProjectList()
    MsgStatusBar("Project Lists paths set", false, true, false)
  end
end

local function Path_Set_BackupsFolder()
  local custompathBackups = GUI.Val("options_txtBackupsPath")
  if custompathBackups == "" then
    MsgStatusBar("Please enter paths for [ Backups ] first!")
  else
    reaper.SetExtState(appname, "custompath_backups", custompathBackups, 1)
    RefreshBackups()
    MsgStatusBar("Backups paths set", false, true, false)
  end
end

local function Path_Set_DocsFolder()
  local custompathDocs = GUI.Val("options_txtDocsPath")
  if custompathDocs == "" then
    MsgStatusBar("Please enter paths for [ Docs ] first!")
  else
    reaper.SetExtState(appname, "custompath_docs", custompathDocs, 1)
    RefreshDocs()
    MsgStatusBar("Docs paths set", false, true, false)
  end
end

----------------
-- Layer z index
----------------
local LayerIndex = {
  Main = 1,
  Global = 2,
  RecentProjects = 3,
  ProjectTemplates = 4,
  TrackTemplates = 5,
  CustomProjects = 6,
  ProjectLists = 7,
  Docs = 8,
  Backups = 9,
  Options = 10,
  Help = 11,
  SaveAsNewVersion = 12,
  ConfirmDialogContent = 20,
  ConfirmDialogWindow = 21
}

local RL = {
  dialogKeyMode = false,
  fontSizes = { 30, 18, 14, 14, 14, 12 },
  keyInputActive = true,
  lastFolderPath = "",
  minHeight = 442,
  minWidth = 620,
  scaleFactor = 1.0,
  scaleMin = 1.0,
  scaleMax = 3.0,
  scaleStepSize = 0.2
}

-- SWS block begin
if SWSinstalled then
  -----------------------
  -- Theme slot functions
  -----------------------
  local ThemeSlots = {
    maxCount = 5,
    items = "----,1,2,3,4,5"
  }

  -- open the SWS Resource window
  local function ThemeSlot_Setup()
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_SHOW_RESVIEW_THEME"), 0) -- SWS/S&M: Open/close Resources window (themes)
  end

  -- load a Theme from the given slot number
  local function ThemeSlot_Load()
    themeslot = GUI.Val("themeslot")
    if themeslot < 5 then reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_LOAD_THEME" .. themeslot - 1), 0) -- SWS/S&M: Resources - Load theme, slot#
    else reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_LOAD_THEMEl"), 0) end 
  end

  -- draw the UI element
  function RL_Draw_ThemeSlotSelector(alignment)
    GUI.New("themeslot", "Menubox", LayerIndex.Global, GUI.w - (74 * RL.scaleFactor) + (RL.scaleFactor * 10), 346 * RL.scaleFactor + (RL.scaleFactor * 2), 40 * RL.scaleFactor, 20 * RL.scaleFactor, "Reaper Theme", ThemeSlots.items, 8)
    GUI.elms.themeslot.tooltip = "Set up and switch between different Reaper Theme Slots\nSlot number and descriptions can be set in the [Options]"
    GUI.elms.themeslot.align = alignment

    function GUI.elms.themeslot:onmousedown()
      GUI.Menubox.onmouseup(self)
      ThemeSlot_Load()
    end
    
    function GUI.elms.themeslot:onwheel()
      GUI.Menubox.onwheel(self)
      ThemeSlot_Load()
    end
  end

  local function ThemeSlot_GetNames()
    local themeSlotNames = {}

    if GUI.Val("options_themeslot_number") == nil then ThemeSlots.maxCount = 5
    else ThemeSlots.maxCount = GUI.Val("options_themeslot_number") end
    for i = 1, ThemeSlots.maxCount do themeSlotNames[i] = GUI.Val("options_themeslot_" .. i) or " " end
    
    ThemeSlots.items = "----"
    for t = 1, ThemeSlots.maxCount do ThemeSlots.items = ThemeSlots.items .. ",  " .. t .. "   " .. themeSlotNames[t] end
    
    local themeSlotAliases = themeSlotNames[1]
    for t = 2, ThemeSlots.maxCount do themeSlotAliases = themeSlotAliases .. "," .. themeSlotNames[t] end
    
    return themeSlotAliases
  end

  function ThemeSlot_LoadNames()
    ThemeSlot_GetNames()
    RL_Draw_ThemeSlotSelector("0")
  end

  local function ThemeSlot_SaveNames()
    reaper.SetExtState(appname, "themeslot_aliases", ThemeSlot_GetNames(), 1)
    RL_Draw_ThemeSlotSelector("0")
    MsgStatusBar("Theme Slot Descriptions saved", false, true, false)
  end

  local function ThemeSlot_Indicator()
    local selected = tonumber(reaper.GetExtState(appname, "themeslot_max"))
    if selected == nil then selected = 5 else GUI.Val("options_themeslot_number", selected) end
    for i = 1, 5 do ThemeSlotTextBoxes[i].color = "none" end 
    for i = 1, selected do ThemeSlotTextBoxes[i].color = "white" end
  end

  function RL_Draw_ThemeSlotOptions()
    local themeslot_pad_left = 85 * RL.scaleFactor
    local themeslot_pad_top = 338 * RL.scaleFactor - (RL.scaleFactor * 8) 

    GUI.New("options_themeslot_Setup", "Button", LayerIndex.Options, themeslot_pad_left, themeslot_pad_top, 89 * RL.scaleFactor, 20 * RL.scaleFactor, "Edit Theme Slots", ThemeSlot_Setup)
    GUI.New("options_themeslot_Save", "Button", LayerIndex.Options, themeslot_pad_left + 98 * RL.scaleFactor, themeslot_pad_top, 35 * RL.scaleFactor, 20 * RL.scaleFactor, "Save", ThemeSlot_SaveNames)
    GUI.New("options_themeslot_number", "Menubox", LayerIndex.Options, themeslot_pad_left + 140 * RL.scaleFactor, themeslot_pad_top, 38 * RL.scaleFactor, 20 * RL.scaleFactor, "", "1,2,3,4,5")
    GUI.elms.options_themeslot_number.align = 1

    for i = 1, ThemeSlots.maxCount do
      GUI.New("options_themeslot_" .. i, "Textbox", LayerIndex.Options, themeslot_pad_left, themeslot_pad_top + (25 * RL.scaleFactor) + (20 * (i - 1) * RL.scaleFactor), 180 * RL.scaleFactor, 20 * RL.scaleFactor, i, 8)
    end

    ThemeSlotTextBoxes = { GUI.elms.options_themeslot_1, GUI.elms.options_themeslot_2, GUI.elms.options_themeslot_3, GUI.elms.options_themeslot_4, GUI.elms.options_themeslot_5 }
    ThemeSlot_Indicator()

    function GUI.elms.options_themeslot_number:onmousedown()
      GUI.Menubox.onmouseup(self)
      ThemeSlot_LoadNames()
      reaper.SetExtState(appname, "themeslot_max", tostring(GUI.Val("options_themeslot_number")), 1)
      ThemeSlot_Indicator()
    end
    
    function GUI.elms.options_themeslot_number:onwheel()
      GUI.Menubox.onwheel(self)
      ThemeSlot_LoadNames()
      reaper.SetExtState(appname, "themeslot_max", tostring(GUI.Val("options_themeslot_number")), 1)
      ThemeSlot_Indicator()
    end

    for i = 1, ThemeSlots.maxCount do
      local tSlots = GUI.elms["options_themeslot_" .. i]
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
    local recentpathtag = {}
    local removedEntries = {}
    local vals = GetSelectionTable(GUI.Val("tab_recentProjects_listbox"))
    for i = 1, #vals do
      local selectedProject = RecentProjects.items[RecentProjects.names[vals[i]]]
      local lastEntry = false
      local p = 0

      repeat
        p = p + 1
        if p < 10 then recentpathtag[p] = "recent0" .. tostring(p)
        else recentpathtag[p] = "recent" .. tostring(p) end
        
        local _, keyValue = reaper.BR_Win32_GetPrivateProfileString("recent", recentpathtag[p], "noEntry", reaperIniPath)
        if keyValue == "noEntry" then 
          lastEntry = true;
          break;
        end
        
        if keyValue == selectedProject then
          removedEntries[#removedEntries + 1] = recentpathtag[p]
          reaper.BR_Win32_WritePrivateProfileString("Recent", recentpathtag[p], "", reaperIniPath)
          MsgDebug("Recent Projects | removed " .. recentpathtag[p] .. " | " .. selectedProject)
        end
      until (lastEntry)
    end

    GUI.Val("tab_recentProjects_listbox", {})
    RefreshRecentProjects()
  end

  function RecentProjects_ClearList()
    local keyName
      for k = 1, RecentProjects.maxIndex do
        if k < 10 then keyName = "recent0" .. tostring(k)
        else keyName = "recent" .. tostring(k) end
        reaper.BR_Win32_WritePrivateProfileString("Recent", keyName, "", reaperIniPath)
      end
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
local function RL_InitFonts()
  local fonts = GUI.get_OS_fonts()
  GUI.fonts = {
    {fonts.sans, RL.fontSizes[1] * RL.scaleFactor},  -- title
    {fonts.sans, RL.fontSizes[2] * RL.scaleFactor},  -- header
    {fonts.sans, RL.fontSizes[3] * RL.scaleFactor},  -- label
    {fonts.sans, RL.fontSizes[4] * RL.scaleFactor},  -- value
    monospace = {fonts.mono, RL.fontSizes[5] * RL.scaleFactor},
    version =   {fonts.sans, RL.fontSizes[6] * RL.scaleFactor, "i"}
  }
end

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
  RL_InitFonts()
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
  btn_w = 150 * RL.scaleFactor
  btn_h = 28 * RL.scaleFactor

  -- global element indents
  pad_left = 4 * RL.scaleFactor
  pad_top = 30 * RL.scaleFactor

  -- listbox size
  listbox_top = 58 * RL.scaleFactor
  listbox_w = GUI.w - (165 * RL.scaleFactor)
  listbox_h = GUI.h - (78 * RL.scaleFactor)

  -- button indents
  btn_pad_left = listbox_w + (8 * RL.scaleFactor)
  btn_pad_top = 170 * RL.scaleFactor
  btn_pad_add = 35 * RL.scaleFactor
  btn_tab_top = 244 * RL.scaleFactor

  -- refresh buttons
  refreshX = 4 * RL.scaleFactor
  refreshY = pad_top - (2 * RL.scaleFactor)
  refreshW = 20 * RL.scaleFactor
  refreshH = 22 * RL.scaleFactor

  -- filter textbox
  filterX = 65 * RL.scaleFactor - (RL.scaleFactor * 4)
  filterY = pad_top
  filterW = 225 * RL.scaleFactor
  filterH = 20 * RL.scaleFactor

  -- path display box
  pathX = 348
end

RL_InitElementScaling(null)
RL_CheckStoredScaleFactor()
RL_SetWindowParameters()

--------------------
-- Main GUI Elements
--------------------
TabLabels = {
  "Recent Projects",
  "Project Templates",
  "Track Templates",
  "Projects",
  "Project Lists",
  "Backups",
  "Docs",
  "Options",
  "Help"
}

TabOrder = {
  RecentProjects = { 1, "Recent Projects" },
  ProjectTemplates = { 2, "Project Templates" },
  TrackTemplates = { 3, "Track Templates" },
  CustomProjects = { 4, "Projects" },
  ProjectLists = { 5, "Project Lists" },
  Backups = { 6, "Backups" },
  Docs = { 7, "Docs" },
  Options = { 8, "Options" },
  Help = { 9, "Help" }
}

TabID = {
  RecentProjects = TabOrder.RecentProjects[1],
  ProjectTemplates = TabOrder.ProjectTemplates[1],
  TrackTemplates = TabOrder.TrackTemplates[1],
  CustomProjects = TabOrder.CustomProjects[1],
  ProjectLists = TabOrder.ProjectLists[1],
  Backups = TabOrder.Backups[1],
  Docs = TabOrder.Docs[1],
  Options = TabOrder.Options[1],
  Help = TabOrder.Help[1]
}

MainTabs = {
  TabOrder.RecentProjects[2],
  TabOrder.ProjectTemplates[2],
  TabOrder.TrackTemplates[2],
  TabOrder.CustomProjects[2],
  TabOrder.ProjectLists[2],
  TabOrder.Backups[2],
  TabOrder.Docs[2],
  TabOrder.Options[2],
  TabOrder.Help[2]
}

SelectionIndex = {
  RecentProjects = 1,
  ProjectTemplates = 1,
  TrackTemplates = 1,
  CustomProjects = 1,
  ProjectListsProjects = 1,
  Backups = 1,
  Docs = 1
}

ParentSelectionIndex = {
  RecentProjects = 1,
  ProjectTemplates = 1,
  TrackTemplates = 1,
  CustomProjects = 1,
  ProjectListsProjects = 1,
  Backups = 1,
  Docs = 1
}

TabParentSelectionIndex = {
  ParentSelectionIndex.RecentProjects,
  ParentSelectionIndex.ProjectTemplates,
  ParentSelectionIndex.TrackTemplates,
  ParentSelectionIndex.CustomProjects,
  ParentSelectionIndex.ProjectListsProjects,
  ParentSelectionIndex.Backups,
  ParentSelectionIndex.Docs
}

TabSelectionIndex = {
  SelectionIndex.RecentProjects,
  SelectionIndex.ProjectTemplates,
  SelectionIndex.TrackTemplates,
  SelectionIndex.CustomProjects,
  SelectionIndex.ProjectListsProjects,
  SelectionIndex.Backups,
  SelectionIndex.Docs
}

IsTabAutoRefreshed = {
  false,
  false,
  false,
  false,
  false,
  false,
  false
}

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
    local ttPreviewSection = "Audio preview section\n\n" ..
      "- Set the volume (in %) via LEFT DRAG or MOUSEWHEEL \n" ..
      "- DOUBLE CLICK on the knob starts/stops the preview\n\n" ..
      "Color states:\n  - SILVER: preview file available for the selected entry\n  - GREEN: preview playing"

    GUI.New("main_previewVolKnob", "Knob", LayerIndex.Global, GUI.w - (148 * RL.scaleFactor), 66 * RL.scaleFactor, 20 * RL.scaleFactor, "Volume", 0, 100, 50, 1)
    GUI.elms.main_previewVolKnob.col_head = "elm_frame"
    GUI.elms.main_previewVolKnob.col_body = "none"
    GUI.elms.main_previewVolKnob.cap_y = -((11 * RL.scaleFactor) + (9 * RL.scaleFactor)) - (3 * RL.scaleFactor) - 5
    GUI.elms.main_previewVolKnob.font_b = GUI.fonts[6]
    GUI.elms.main_previewVolKnob.vals = false
    GUI.elms.main_previewVolKnob.tooltip = ttPreviewSection

    local pos = 1
    local stereoChannels = {}
    for c = 1, reaper.GetNumAudioOutputs(), 2 do
      stereoChannels[pos] = c .. "/" .. c + 1
      pos = pos + 1
    end

    GUI.New("main_previewStatusLabel", "Label", LayerIndex.Global, GUI.w - (54 * RL.scaleFactor) - 65 * RL.scaleFactor, 68 * RL.scaleFactor, "Preview", false, 4)
    GUI.elms.main_previewStatusLabel.color = "elm_frame"
    GUI.elms.main_previewStatusLabel.tooltip = ttPreviewSection

    GUI.New("main_previewChannels", "Menubox", LayerIndex.Global, GUI.w - (74 * RL.scaleFactor), 66 * RL.scaleFactor, 65 * RL.scaleFactor, 20 * RL.scaleFactor, "", table.concat(stereoChannels, ","))
    GUI.elms.main_previewChannels.col_txt = "elm_frame"
    GUI.elms.main_previewChannels.align = "1"
    GUI.elms.main_previewChannels.tooltip = "Set the audio channel(s) used for preview playback"

    local function SetPreviewChannel(channel)
      AudioPreview.channelIndex = tonumber(string.sub(channel, 1, #channel - channel:find("/"))) - 1
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
      AudioPreviewToggleState()
    end
  
    GUI.elms.main_previewVolKnob:init()
    GUI.elms.main_previewVolKnob:redraw()
  end
end

----------------
-- Main elements
----------------
local function RL_Draw_Main()
  GUI.New("main_tabs", "Tabs", LayerIndex.Main, 0, 0, 95 * RL.scaleFactor, 20 * RL.scaleFactor, MainTabs, 16)
  GUI.elms.main_tabs.col_tab_b = "elm_bg"
  GUI.New("main_appversion", "Label", LayerIndex.Main, pad_left, GUI.h - (16 * RL.scaleFactor), "ReaLauncher " .. appversion, false, 4)
  
  if osversion:find("Win") then GUI.New("main_statusbar", "Label", LayerIndex.Main, pad_left + (85 * RL.scaleFactor), GUI.h - (16 * RL.scaleFactor), "", false, 4)
  else GUI.New("main_statusbar", "Label", LayerIndex.Main, pad_left + (90 * RL.scaleFactor), GUI.h - (16 * RL.scaleFactor), "", false, 4) end

  GUI.elms.main_tabs:update_sets(
    { [TabID.RecentProjects] = { LayerIndex.Global, LayerIndex.RecentProjects, LayerIndex.SaveAsNewVersion },
      [TabID.ProjectTemplates] = { LayerIndex.Global, LayerIndex.ProjectTemplates },
      [TabID.TrackTemplates] = { LayerIndex.Global, LayerIndex.TrackTemplates },
      [TabID.CustomProjects] = { LayerIndex.Global, LayerIndex.CustomProjects, LayerIndex.SaveAsNewVersion },
      [TabID.ProjectLists] = { LayerIndex.Global, LayerIndex.ProjectLists, LayerIndex.SaveAsNewVersion },
      [TabID.Backups] = { LayerIndex.Global, LayerIndex.Backups },
      [TabID.Docs] = { LayerIndex.Global, LayerIndex.Docs },
      [TabID.Options] = { LayerIndex.Options },
      [TabID.Help] = { LayerIndex.Help }
    }
  )

  function GUI.elms.main_tabs:onmousedown()
    GUI.Tabs.onmousedown(self)
    RL_AutoRefreshTab()
  end

  function GUI.elms.main_tabs:onwheel()
    GUI.Tabs.onwheel(self)
    RL_AutoRefreshTab()
  end

  GUI.New("main_menuPaths", "Menubox", LayerIndex.Global, pathX * RL.scaleFactor - (RL.scaleFactor * 5), pad_top, 60 * RL.scaleFactor, 20 * RL.scaleFactor, "Paths", "Hide,Show", 8)
  GUI.elms.main_menuPaths.align = "1"
  
  if SWSinstalled then GUI.New("main_btnOpenInExplorer", "Button", LayerIndex.Global, btn_pad_left, 98 * RL.scaleFactor, btn_w, btn_h, "Show in Explorer/Finder", Global_OpenInExplorer) end
  GUI.New("main_btnOpenProject", "Button", LayerIndex.Global, btn_pad_left, 132 * RL.scaleFactor, btn_w, btn_h, "Open Project", Global_ShowProjectOpenDialog) 

  GUI.New("main_btnNewProject", "Button", LayerIndex.Global, btn_pad_left, btn_pad_top, btn_w, btn_h, "New Project", Global_NewProject) 
  GUI.New("main_btnNewProjectTab", "Button", LayerIndex.Global, btn_pad_left, btn_pad_top + btn_pad_add, (btn_w * 0.5) - 5, btn_h, "New Tab", Global_NewTab) 
  GUI.New("main_btnNewTabIgnoreTemplate", "Button", LayerIndex.Global, btn_pad_left + (btn_w * 0.5) + 5, btn_pad_top + btn_pad_add, (btn_w * 0.5) - 5, btn_h, "New Tab IT", Global_NewTabIgnoreDefaultTemplate)

  GUI.New("main_lblWindowpin", "Label", LayerIndex.Global, GUI.w - (80 * RL.scaleFactor) + (RL.scaleFactor * 5) - 4, 32 * RL.scaleFactor, "Keep open", false, 3)
  GUI.New("main_checklistWindowPin", "Checklist", LayerIndex.Global, GUI.w - (26 * RL.scaleFactor) + (RL.scaleFactor * 5), 30 * RL.scaleFactor + (RL.scaleFactor * 2), 20 * RL.scaleFactor - (5 * RL.scaleFactor), 20 * RL.scaleFactor - (5 * RL.scaleFactor), "", "", "h", 0)
  GUI.elms.main_checklistWindowPin.opt_size = 20 * RL.scaleFactor - (5 * RL.scaleFactor)
  GUI.elms.main_checklistWindowPin:init()

  GUI.New("main_lblSaveNewVersion", "Label", LayerIndex.SaveAsNewVersion, GUI.w - (152 * RL.scaleFactor) + (RL.scaleFactor * 11), 320 * RL.scaleFactor, "Save as New Version", false, 3)
  GUI.New("main_checklistSaveAsNewVersion", "Checklist", LayerIndex.SaveAsNewVersion, GUI.w - (44 * RL.scaleFactor) + (RL.scaleFactor * 11), 318 * RL.scaleFactor + (RL.scaleFactor * 2), 20 * RL.scaleFactor - (5 * RL.scaleFactor), 20 * RL.scaleFactor - (5 * RL.scaleFactor), "", "", "h", 0)
  GUI.elms.main_checklistSaveAsNewVersion.opt_size = 20 * RL.scaleFactor - (5 * RL.scaleFactor)
  GUI.elms.main_checklistSaveAsNewVersion:init()

  function GUI.elms.main_menuPaths:onmousedown()
    GUI.Menubox.onmouseup(self)
    Global_UpdatePathDisplayMode()
  end
  
  function GUI.elms.main_menuPaths:onwheel()
    GUI.Menubox.onwheel(self)
    Global_UpdatePathDisplayMode()
  end
  
  if SWSinstalled then RL_Draw_ThemeSlotSelector("1") end
  if JSAPIinstalled then RL_Draw_PreviewSection() end
end

local function RL_Draw_Frames()
  local framewidth = 2 * RL.scaleFactor
  GUI.New("main_frame_top", "Frame", LayerIndex.Global, 0, 56 * RL.scaleFactor, GUI.w, framewidth, true, true)
  GUI.New("main_frame_side_2", "Frame", LayerIndex.Global, pad_left + listbox_w , 92 * RL.scaleFactor, GUI.w - pad_left - listbox_w, framewidth, true, true)
  GUI.New("main_frame_side_3", "Frame", LayerIndex.Global, pad_left + listbox_w , 164 * RL.scaleFactor, GUI.w - pad_left - listbox_w, framewidth, true, true)
  GUI.New("main_frame_side_4", "Frame", LayerIndex.Global, pad_left + listbox_w , 237 * RL.scaleFactor, GUI.w - pad_left - listbox_w, framewidth, true, true)
  GUI.New("main_frame_side_5", "Frame", LayerIndex.Global, pad_left + listbox_w , 311 * RL.scaleFactor, GUI.w - pad_left - listbox_w, framewidth, true, true)
  GUI.New("main_frame_side_6", "Frame", LayerIndex.Global, pad_left + listbox_w , 340 * RL.scaleFactor, GUI.w - pad_left - listbox_w, framewidth, true, true)
  GUI.New("main_frame_side_7", "Frame", LayerIndex.Global, pad_left + listbox_w , 373 * RL.scaleFactor, GUI.w - pad_left - listbox_w, framewidth, true, true)
end

-----------------
-- Confirm Dialog
-----------------
Dialog = {
  mode,
  id,
  message
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
  end
  RL_Dialog_Close()
end

local function RL_ConfirmDialog_RemoveRecentEntry()
  Dialog.mode = "Confirm"
  Dialog.id = "RemoveRecentEntry"
  Dialog.message = "Remove selected entries?"
  RL_Dialog_Open()
end

local function RL_ConfirmDialog_ClearRecentList()
  Dialog.mode = "Confirm"
  Dialog.id = "ClearRecentList"
  Dialog.message = "Clear Recent Projects list?"
  RL_Dialog_Open()
end

function RL_InitConfirmDialog()
  if SWSinstalled then
    GUI.New("confirmDialog_window", "Window", LayerIndex.ConfirmDialogWindow, 0, 0, 150 * RL.scaleFactor, 90 * RL.scaleFactor, "", {LayerIndex.ConfirmDialogContent, LayerIndex.ConfirmDialogWindow})
    GUI.New("confirmDialog_label", "Label", LayerIndex.ConfirmDialogContent, 20 * RL.scaleFactor - (5 * RL.scaleFactor), 16 * RL.scaleFactor, "", false, 3)
    GUI.New("confirmDialog_btnCancel", "Button", LayerIndex.ConfirmDialogContent, 20 * RL.scaleFactor, 35 * RL.scaleFactor, 40 * RL.scaleFactor, 16 * RL.scaleFactor, "Cancel", RL_Dialog_Close)
    GUI.New("confirmDialog_btnOK", "Button", LayerIndex.ConfirmDialogContent, 90 * RL.scaleFactor, 35 * RL.scaleFactor, 40 * RL.scaleFactor, 16 * RL.scaleFactor, "OK", RL_Dialog_OK)

    GUI.elms_hide[LayerIndex.ConfirmDialogContent] = true
    GUI.elms_hide[LayerIndex.ConfirmDialogWindow] = true

    function GUI.elms.confirmDialog_window:onopen()
      self:adjustelm(GUI.elms.confirmDialog_label)
      self:adjustelm(GUI.elms.confirmDialog_btnCancel)
      self:adjustelm(GUI.elms.confirmDialog_btnOK)
      GUI.Val("confirmDialog_label", Dialog.message)
    end

    GUI.elms.confirmDialog_btnOK.col_fill = "wnd_bg"
    GUI.elms.confirmDialog_btnOK:init()
    GUI.elms.confirmDialog_btnCancel.col_fill = "wnd_bg"
    GUI.elms.confirmDialog_btnCancel:init()
  end
end

------------------------
-- Tab - Recent Projects
------------------------
local function RL_Draw_TabRecentProjects()
  GUI.New("tab_recentProjects_btnRefresh", "Button", LayerIndex.RecentProjects, refreshX, refreshY, refreshW, refreshH, "R", RefreshRecentProjects)
  GUI.New("tab_recentProjects_txtFilter", "Textbox", LayerIndex.RecentProjects, filterX, filterY, filterW, filterH, "Filter", 8)
  GUI.New("tab_recentProjects_btnFilterClear", "Button", LayerIndex.RecentProjects, filterX + filterW + 2, filterY + (filterH * 0.25), refreshW * 0.5, refreshH * 0.5, "x", Filter_RecentProject_Clear)

  GUI.New("tab_recentProjects_listbox", "Listbox", LayerIndex.RecentProjects, pad_left, listbox_top, listbox_w, listbox_h, "", true)
  GUI.elms.tab_recentProjects_listbox.list = RecentProjects.names
  GUI.Val("tab_recentProjects_listbox", {1})

  GUI.New("tab_recentProjects_btnLoadInTab", "Button", LayerIndex.RecentProjects, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_RecentProject)
  GUI.New("tab_recentProjects_btnLoad", "Button", LayerIndex.RecentProjects, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_RecentProject)

  function GUI.elms.tab_recentProjects_listbox:onmousedown()
    TabSelectionIndex[TabID.RecentProjects] = self:getitem(GUI.mouse.y)
    if JSAPIinstalled then AudioPreviewCheckForFile() end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_recentProjects_listbox:ondoubleclick()
    RL_Mouse_DoubleClick(TabID.RecentProjects)
  end
  
  if SWSinstalled then 
    function GUI.elms.tab_recentProjects_listbox:onmouser_down()
      RL_Context_RecentProjects()
      GUI.Listbox.onmouser_down(self)
    end
  end

  function RL_Context_RecentProjects()
    if not noRecentProjects then
      gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
      local vals = GetSelectionTable(GUI.Val("tab_recentProjects_listbox"))
      if FilterActive.RecentProjects or #vals == 0 then
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
projectTemplateLoadMode = 1

local function RL_Draw_TabProjectTemplates()
  GUI.New("tab_projectTemplates_btnRefresh", "Button", LayerIndex.ProjectTemplates, refreshX, refreshY, refreshW, refreshH, "R", RefreshProjectTemplates)
  GUI.New("tab_projectTemplates_txtFilter", "Textbox", LayerIndex.ProjectTemplates, filterX, filterY, filterW, filterH, "Filter", 8)
  GUI.New("tab_projectTemplates_btnFilterClear", "Button", LayerIndex.ProjectTemplates, filterX + filterW + 2, filterY + (filterH * 0.25), refreshW * 0.5, refreshH * 0.5, "x", Filter_ProjectTemplate_Clear)
  
  if showSubfolderPanel then GUI.New("tab_projectTemplates_listbox", "Listbox", LayerIndex.ProjectTemplates, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  else GUI.New("tab_projectTemplates_listbox", "Listbox", LayerIndex.ProjectTemplates, pad_left, listbox_top, listbox_w, listbox_h, "", true) end
  GUI.elms.tab_projectTemplates_listbox.list = ProjectTemplates.names
  GUI.Val("tab_projectTemplates_listbox", {1})

  GUI.New("tab_projectTemplates_btnLoadInTab", "Button", LayerIndex.ProjectTemplates, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_ProjectTemplate)
  GUI.New("tab_projectTemplates_btnLoad", "Button", LayerIndex.ProjectTemplates, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_ProjectTemplate)
   
  GUI.New("tab_projectTemplates_lblEditMode", "Label", LayerIndex.ProjectTemplates, GUI.w - (147 * RL.scaleFactor) + (RL.scaleFactor * 10), 320 * RL.scaleFactor, "Edit Template Mode", false, 3)
  GUI.New("tab_projectTemplates_checklistEditMode", "Checklist", LayerIndex.ProjectTemplates, GUI.w - (44 * RL.scaleFactor) + (RL.scaleFactor * 10), 318 * RL.scaleFactor + (RL.scaleFactor * 2), 20 * RL.scaleFactor - (5 * RL.scaleFactor), 20 * RL.scaleFactor - (5 * RL.scaleFactor), "", "", "h", 0)
  GUI.elms.tab_projectTemplates_checklistEditMode.opt_size = 20 * RL.scaleFactor - (5 * RL.scaleFactor)
  GUI.elms.tab_projectTemplates_checklistEditMode:init()

  if showSubfolderPanel then
    GUI.New("tab_projectTemplates_subfolders", "Listbox", LayerIndex.ProjectTemplates, pad_left, listbox_top, listbox_w/3, listbox_h, "", true)
  
    function GUI.elms.tab_projectTemplates_subfolders:onmousedown()
      if GUI.elms.tab_projectTemplates_subfolders then 
        TabParentSelectionIndex[TabID.ProjectTemplates] = self:getitem(GUI.mouse.y)
        GUI.Listbox.onmouseup(self)
        UpdateProjectTemplateSubDirSelection()
      end
    end

    function UpdateProjectTemplateSubDirSelection()
      if TabParentSelectionIndex[TabID.ProjectTemplates] == 1 then 
        RefreshProjectTemplates()
      else 
        if showSubFolderPaths then
          FillProjectTemplateListBoxBase(GetFiles(GUI.elms.tab_projectTemplates_subfolders.list[TabParentSelectionIndex[TabID.ProjectTemplates]])) 
         else
          FillProjectTemplateListBoxBase(GetFiles(SubfolderPaths.projectTemplates[TabParentSelectionIndex[TabID.ProjectTemplates]]))
         end
      end
      TabSelectionIndex[TabID.ProjectTemplates] = 1
      GUI.Val("tab_projectTemplates_listbox", {1})
    end
  end

  function GUI.elms.tab_projectTemplates_listbox:onmousedown()
    TabSelectionIndex[TabID.ProjectTemplates] = self:getitem(GUI.mouse.y)
    if JSAPIinstalled then AudioPreviewCheckForFile() end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_projectTemplates_listbox:ondoubleclick()
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

  function GUI.elms.tab_projectTemplates_checklistEditMode:onmousedown()
    projectTemplateLoadMode = GUI.Val("tab_projectTemplates_checklistEditMode")
  end
end

------------------------
-- Tab - Track Templates
------------------------
local function RL_Draw_TabTrackTemplates()
  GUI.New("tab_trackTemplates_btnRefresh", "Button", LayerIndex.TrackTemplates, refreshX, refreshY, refreshW, refreshH, "R", RefreshTrackTemplates)
  GUI.New("tab_trackTemplates_txtFilter", "Textbox", LayerIndex.TrackTemplates, filterX, filterY, filterW, filterH, "Filter", 8)
  GUI.New("tab_trackTemplates_btnFilterClear", "Button", LayerIndex.TrackTemplates, filterX + filterW + 2, filterY + (filterH * 0.25), refreshW * 0.5, refreshH * 0.5, "x", Filter_TrackTemplate_Clear)

  if showSubfolderPanel then GUI.New("tab_trackTemplates_listbox", "Listbox", LayerIndex.TrackTemplates, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  else GUI.New("tab_trackTemplates_listbox", "Listbox", LayerIndex.TrackTemplates, pad_left, listbox_top, listbox_w, listbox_h, "", true) end
  GUI.elms.tab_trackTemplates_listbox.list = TrackTemplates.names
  GUI.Val("tab_trackTemplates_listbox", {1})

  GUI.New("tab_trackTemplates_btnInsert", "Button", LayerIndex.TrackTemplates, btn_pad_left, btn_tab_top + (20 * RL.scaleFactor) - (5 * RL.scaleFactor), btn_w, btn_h, "Insert", Load_TrackTemplate)
  
  if showSubfolderPanel then 
    GUI.New("tab_trackTemplates_subfolders", "Listbox", LayerIndex.TrackTemplates, pad_left, listbox_top, listbox_w/3, listbox_h, "", true)
    
    function GUI.elms.tab_trackTemplates_subfolders:onmouseup()
      if GUI.elms.tab_trackTemplates_subfolders then 
        TabParentSelectionIndex[TabID.TrackTemplates] = self:getitem(GUI.mouse.y)
        GUI.Listbox.onmouseup(self)
        UpdateTrackTemplateSubDirSelection()
      end
    end
  
    function UpdateTrackTemplateSubDirSelection()
      if TabParentSelectionIndex[TabID.TrackTemplates] == 1 then 
        RefreshTrackTemplates()
      else 
        if showSubFolderPaths then
          FillTrackTemplateListboxBase(GetFiles(GUI.elms.tab_trackTemplates_subfolders.list[TabParentSelectionIndex[TabID.TrackTemplates]]))
        else
          FillTrackTemplateListboxBase(GetFiles(SubfolderPaths.trackTemplates[TabParentSelectionIndex[TabID.TrackTemplates]]))
        end
      end
      TabSelectionIndex[TabID.TrackTemplates] = 1
      GUI.Val("tab_trackTemplates_listbox", {1})
    end
  end
  
  function GUI.elms.tab_trackTemplates_listbox:onmousedown()
    TabSelectionIndex[TabID.TrackTemplates] = self:getitem(GUI.mouse.y)
    if JSAPIinstalled then AudioPreviewCheckForFile() end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_trackTemplates_listbox:ondoubleclick()
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

-------------------------------
-- Tab - Custom projects folder
-------------------------------
local function RL_Draw_TabCustomProjects()
  GUI.New("tab_customProjects_btnFilter", "Button", LayerIndex.CustomProjects, refreshX, refreshY, refreshW, refreshH, "R", RefreshCustomProjects)
  GUI.New("tab_customProjects_txtFilter", "Textbox", LayerIndex.CustomProjects, filterX, filterY, filterW, filterH, "Filter", 8)
  GUI.New("tab_customProjects_btnFilterClear", "Button", LayerIndex.CustomProjects, filterX + filterW + 2, filterY + (filterH * 0.25), refreshW * 0.5, refreshH * 0.5, "x", Filter_CustomProjects_Clear)
  
  if showSubfolderPanel then GUI.New("tab_customProjects_listbox", "Listbox", LayerIndex.CustomProjects, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  else GUI.New("tab_customProjects_listbox", "Listbox", LayerIndex.CustomProjects, pad_left, listbox_top, listbox_w, listbox_h, "", true) end
  GUI.elms.tab_customProjects_listbox.list = CustomProjects.names
  GUI.Val("tab_customProjects_listbox", {1})

  GUI.New("tab_customProjects_btnLoadInTab", "Button", LayerIndex.CustomProjects, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_CustomProject)
  GUI.New("tab_customProjects_btnLoad", "Button", LayerIndex.CustomProjects, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_CustomProject)

  if showSubfolderPanel then 
    GUI.New("tab_customProjects_subfolders", "Listbox", LayerIndex.CustomProjects, pad_left, listbox_top, listbox_w/3, listbox_h, "", true)

    function GUI.elms.tab_customProjects_subfolders:onmousedown()
      if GUI.elms.tab_customProjects_subfolders then 
        TabParentSelectionIndex[TabID.CustomProjects] = self:getitem(GUI.mouse.y)
        GUI.Listbox.onmouseup(self)
        UpdateCustomProjectSubDirSelection()
      end
    end
  
    function UpdateCustomProjectSubDirSelection()
      if TabParentSelectionIndex[TabID.CustomProjects] == 1 then 
        RefreshCustomProjects()
      else
       
        if showSubFolderPaths then
          if TabParentSelectionIndex[TabID.CustomProjects] == 1 then FillCustomProjectsListbox()
          else
            InitCustomProjectTables()
            FillCustomProjectsListboxBase(GetFiles(GUI.elms.tab_customProjects_subfolders.list[TabParentSelectionIndex[TabID.CustomProjects]]), 1)
          end
        else
          InitCustomProjectTables()
          FillCustomProjectsListboxBase(GetFiles(SubfolderPaths.customProjects[TabParentSelectionIndex[TabID.CustomProjects]]), 1)
        end
      end
      TabSelectionIndex[TabID.CustomProjects] = 1
      GUI.Val("tab_customProjects_listbox", {1})
    end
  end

  function GUI.elms.tab_customProjects_listbox:onmousedown()
    TabSelectionIndex[TabID.CustomProjects] = self:getitem(GUI.mouse.y)
    if JSAPIinstalled then AudioPreviewCheckForFile() end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_customProjects_listbox:ondoubleclick()
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
  GUI.New("tab_projectLists_btnRefresh", "Button", LayerIndex.ProjectLists, refreshX, refreshY, refreshW, refreshH, "R", RefreshProjectList)
  GUI.New("tab_projectLists_txtFilter", "Textbox", LayerIndex.ProjectLists, filterX, filterY, filterW, filterH, "Filter", 8)
  GUI.New("tab_projectLists_btnFilterClear", "Button", LayerIndex.ProjectLists, filterX + filterW + 2, filterY + (filterH * 0.25), refreshW * 0.5, refreshH * 0.5, "x", Filter_ProjectLists_Clear)
 
  GUI.New("tab_projectLists_listboxRPL", "Listbox", LayerIndex.ProjectLists, pad_left, listbox_top, listbox_w/3, listbox_h, "", true)
  GUI.elms.tab_projectLists_listboxRPL.list = ProjectLists.rplFiles
  GUI.Val("tab_projectLists_listboxRPL", {1})

  GUI.New("tab_projectLists_listboxProjects", "Listbox", LayerIndex.ProjectLists, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)

  GUI.New("tab_projectLists_btnLoadInTab", "Button", LayerIndex.ProjectLists, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_ProjectListProject)
  GUI.New("tab_projectLists_btnLoad", "Button", LayerIndex.ProjectLists, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_ProjectListProject)

  function GUI.elms.tab_projectLists_listboxRPL:onmouseup()
    if GUI.elms.tab_projectLists_listboxRPL then 
      TabParentSelectionIndex[TabID.ProjectLists] = self:getitem(GUI.mouse.y)
      GUI.Listbox.onmouseup(self)
      UpdateProjectListSelection()
    end
  end

  function UpdateProjectListSelection()
    if TabParentSelectionIndex[TabID.ProjectLists] == 1 then RPL_FillProjectListBoxWithAll()
    else RPL_FillProjectListBox() end
  end

  function GUI.elms.tab_projectLists_listboxProjects:onmousedown()
    TabSelectionIndex[TabID.ProjectLists] = self:getitem(GUI.mouse.y)
    if JSAPIinstalled then AudioPreviewCheckForFile() end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_projectLists_listboxProjects:ondoubleclick()
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
  GUI.New("tab_backups_btnRefresh", "Button", LayerIndex.Backups, refreshX, refreshY, refreshW, refreshH, "R", RefreshBackups)
  GUI.New("tab_backups_txtFilter", "Textbox", LayerIndex.Backups, filterX, filterY, filterW, filterH, "Filter", 8)
  GUI.New("tab_backups_btnFilterClear", "Button", LayerIndex.Backups, filterX + filterW + 2, filterY + (filterH * 0.25), refreshW * 0.5, refreshH * 0.5, "x", Filter_Backups_Clear)

  if showSubfolderPanel then GUI.New("tab_backups_listbox", "Listbox", LayerIndex.Backups, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  else GUI.New("tab_backups_listbox", "Listbox", LayerIndex.Backups, pad_left, listbox_top, listbox_w, listbox_h, "", true) end
  GUI.elms.tab_backups_listbox.list = Backups.names
  GUI.Val("tab_backups_listbox", {1})

  GUI.New("tab_backups_btnLoadInTab", "Button", LayerIndex.Backups, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_BackupFile)
  GUI.New("tab_backups_btnLoad", "Button", LayerIndex.Backups, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_BackupFile)

  if showSubfolderPanel then
    GUI.New("tab_backups_subfolders", "Listbox", LayerIndex.Backups, pad_left, listbox_top, listbox_w/3, listbox_h, "", true)

    function GUI.elms.tab_backups_subfolders:onmousedown()
      if GUI.elms.tab_backups_subfolders then 
        TabParentSelectionIndex[TabID.Backups] = self:getitem(GUI.mouse.y)
        GUI.Listbox.onmouseup(self)
        UpdateBackupsSubDirSelection()
      end
    end
  
    function UpdateBackupsSubDirSelection()
      if TabParentSelectionIndex[TabID.Backups] == 1 then 
        RefreshBackups()
      else 
        if showSubFolderPaths then 
          if TabParentSelectionIndex[TabID.Backups] == 1 then 
            FillBackupsListbox()
          else
            InitBackupsTables()
            FillBackupsListboxBase(GetFiles(GUI.elms.tab_backups_subfolders.list[TabParentSelectionIndex[TabID.Backups]]), 1)
          end
        else
          InitBackupsTables()
          FillBackupsListboxBase(GetFiles(SubfolderPaths.backups[TabParentSelectionIndex[TabID.Backups]]), 1)
        end
      end
      TabSelectionIndex[TabID.Backups] = 1
      GUI.Val("tab_backups_listbox", {1})
    end
  end

  function GUI.elms.tab_backups_listbox:onmousedown()
    TabSelectionIndex[TabID.Backups] = self:getitem(GUI.mouse.y)
    if JSAPIinstalled then AudioPreviewCheckForFile() end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_backups_listbox:ondoubleclick()
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
  if not noDocs then
    local selectedDocFile
    local vals = GetSelectionTable(GUI.Val("tab_docs_listbox"))
    for p = 1, #vals do
      if FilterActive.Docs then selectedDocFile = Docs.items[Docs.filteredNames[vals[p]]]
      else selectedDocFile = Docs.items[Docs.names[vals[p]]] end
      if selectedDocFile ~= nil then 
        reaper.CF_ShellExecute(selectedDocFile)
      end
    end 
    Global_CheckWindowPinState()
  end
end

function RL_Draw_TabDocs()
  GUI.New("tab_docs_btnRefresh", "Button", LayerIndex.Docs, refreshX, refreshY, refreshW, refreshH, "R", RefreshDocs)
  GUI.New("tab_docs_txtFilter", "Textbox", LayerIndex.Docs, filterX, filterY, filterW, filterH, "Filter", 8)
  GUI.New("tab_docs_btnFilterClear", "Button", LayerIndex.Docs, filterX + filterW + 2, filterY + (filterH * 0.25), refreshW * 0.5, refreshH * 0.5, "x", Filter_Docs_Clear)
 
  if showSubfolderPanel then GUI.New("tab_docs_listbox", "Listbox", LayerIndex.Docs, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  else GUI.New("tab_docs_listbox", "Listbox", LayerIndex.Docs, pad_left, listbox_top, listbox_w, listbox_h, "", true) end
  GUI.elms.tab_docs_listbox.list = Docs.names
  GUI.Val("tab_docs_listbox", {1})

  GUI.New("tab_docs_btnOpen", "Button", LayerIndex.Docs, btn_pad_left, btn_tab_top + (20 * RL.scaleFactor) - (5 * RL.scaleFactor), btn_w, btn_h, "Open", Load_DocFile)

  if showSubfolderPanel then
    GUI.New("tab_docs_subfolders", "Listbox", LayerIndex.Docs, pad_left, listbox_top, listbox_w/3, listbox_h, "", true)
  
    function GUI.elms.tab_docs_subfolders:onmousedown()
      if GUI.elms.tab_docs_subfolders then 
        TabParentSelectionIndex[TabID.Docs] = self:getitem(GUI.mouse.y)
        GUI.Listbox.onmouseup(self)
        UpdateDocsSubDirSelection()
      end
    end

    function UpdateDocsSubDirSelection()
      if TabParentSelectionIndex[TabID.Docs] == 1 then 
        RefreshDocs()
      else 
        if showSubFolderPaths then 
          if TabParentSelectionIndex[TabID.Docs] == 1 then 
            FillDocsListbox()
          else
            InitDocsTables()
            FillDocsListboxBase(GetFiles(GUI.elms.tab_docs_subfolders.list[TabParentSelectionIndex[TabID.Docs]]), 1)
          end
        else
          InitDocsTables()
          FillDocsListboxBase(GetFiles(SubfolderPaths.docs[TabParentSelectionIndex[TabID.Docs]]), 1)
        end
      end
        TabSelectionIndex[TabID.Docs] = 1
        GUI.Val("tab_docs_listbox", {1})
      end
  end

  function GUI.elms.tab_docs_listbox:onmousedown()
    TabSelectionIndex[TabID.Docs] = self:getitem(GUI.mouse.y)
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_docs_listbox:ondoubleclick()
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

----------------
-- Tab - Options
----------------
local function RL_Draw_SavePromptOption(options_pad_top, options_yOffset)
  GUI.New("options_lblPromptToSave", "Label", LayerIndex.Options, GUI.w - 258 * RL.scaleFactor + (RL.scaleFactor * 20), options_pad_top + (7.5 * options_yOffset - 18) * RL.scaleFactor, "Prompt to save on new project", false, 3)
  GUI.New("options_checklistPromptToSave", "Checklist", LayerIndex.Options, GUI.w - 85 * RL.scaleFactor, options_pad_top + (7.5 * options_yOffset - 18) * RL.scaleFactor, 20 * RL.scaleFactor - (5 * RL.scaleFactor), 20 * RL.scaleFactor - (5 * RL.scaleFactor), "", "", "h", 0)
  GUI.elms.options_checklistPromptToSave.opt_size = 20 * RL.scaleFactor - (5 * RL.scaleFactor)
  GUI.elms.options_checklistPromptToSave:init()
  
  local tooltipTogglePromptToSave = "Toggles the 'Prompt to save on new project' option under Preferences > Project"
  GUI.elms.options_lblPromptToSave.tooltip = tooltipTogglePromptToSave
  GUI.elms.options_checklistPromptToSave.tooltip = tooltipTogglePromptToSave
  
  -- load last state set in preferences
  local dt = reaper.SNM_GetIntConfigVar("newprojdo", -1)
  if dt&1 == 1 then
    GUI.Val("options_checklistPromptToSave", {true})
  else
    GUI.Val("options_checklistPromptToSave", {false})
  end

  local function ToggleSavePromptOnNewProject()
    local dt = reaper.SNM_GetIntConfigVar("newprojdo", -1)
    if dt&1 == 1 then
      reaper.SNM_SetIntConfigVar("newprojdo", dt&~1)
    else
      reaper.SNM_SetIntConfigVar("newprojdo", dt|1)
    end
  end

  function GUI.elms.options_checklistPromptToSave:onmousedown()
    GUI.Checklist.onmouseup(self)
    ToggleSavePromptOnNewProject()
  end
end

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
  OpenJSBrowseDialog("options_txtProjectTemplatesPath", "Containing (.RPP) Project Templates")
end

function Path_Browse_TrackTemplateFolder()
  OpenJSBrowseDialog("options_txtTrackTemplatesPath", "Containing (.RTrackTemplate) Track Templates")
end

function Path_Browse_CustomProjectFolder()
  OpenJSBrowseDialog("options_txtCustomProjectsPath", "Containing (.RPP) Projects")
end

function Path_Browse_ProjectListFolder()
  OpenJSBrowseDialog("options_txtProjectsListsPath", "Containing (.RPL) Project Lists")
end

function Path_Browse_BackupsFolder()
  OpenJSBrowseDialog("options_txtBackupsPath", "Containing (.RPP-BAK) Backups")
end

function Path_Browse_DocsFolder()
  OpenJSBrowseDialog("options_txtDocsPath", "Containing (.PDF) Docs")
end

local function RL_Draw_TabOptions()
  local options_yOffset = 50
  local options_pad_top = 0
  local options_textBoxWidth = 125

  if JSAPIinstalled then
    GUI.New("options_btnProjectTemplatesBrowse", "Button", LayerIndex.Options, GUI.w - 66 * RL.scaleFactor, options_pad_top + options_yOffset * RL.scaleFactor, 15 * RL.scaleFactor, 20 * RL.scaleFactor, "+", Path_Browse_ProjectTemplateFolder)
    GUI.New("options_btnTrackTemplatesBrowse", "Button", LayerIndex.Options, GUI.w - 66 * RL.scaleFactor, options_pad_top + 2 * options_yOffset * RL.scaleFactor, 15 * RL.scaleFactor, 20 * RL.scaleFactor, "+", Path_Browse_TrackTemplateFolder)
    GUI.New("options_btnCustomProjectsBrowse", "Button", LayerIndex.Options, GUI.w - 66 * RL.scaleFactor, options_pad_top + 3 * options_yOffset * RL.scaleFactor, 15 * RL.scaleFactor, 20 * RL.scaleFactor, "+", Path_Browse_CustomProjectFolder)
    GUI.New("options_btnProjectListsBrowse", "Button", LayerIndex.Options, GUI.w - 66 * RL.scaleFactor, options_pad_top + 4 * options_yOffset * RL.scaleFactor, 15 * RL.scaleFactor, 20 * RL.scaleFactor, "+", Path_Browse_ProjectListFolder)
    GUI.New("options_btnBackupsBrowse", "Button", LayerIndex.Options, GUI.w - 66 * RL.scaleFactor, options_pad_top + 5 * options_yOffset * RL.scaleFactor, 15 * RL.scaleFactor, 20 * RL.scaleFactor, "+", Path_Browse_BackupsFolder)
    GUI.New("options_btnDocsBrowse", "Button", LayerIndex.Options, GUI.w - 66 * RL.scaleFactor, options_pad_top + 6 * options_yOffset * RL.scaleFactor, 15 * RL.scaleFactor, 20 * RL.scaleFactor, "+", Path_Browse_DocsFolder)
    options_textBoxWidth = 140
  end

  -- custom project template folder
  GUI.New("options_btnProjectTemplatesClear", "Button", LayerIndex.Options, 20, options_pad_top + options_yOffset * RL.scaleFactor, 45 * RL.scaleFactor, 20 * RL.scaleFactor, "Remove", Path_Clear_ProjectTemplateFolder)
  GUI.New("options_txtProjectTemplatesPath", "Textbox", LayerIndex.Options, 68 * RL.scaleFactor, options_pad_top + options_yOffset * RL.scaleFactor, GUI.w - options_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, "Custom .RPP [ Project Templates ] folder", 8)
  GUI.New("options_btnProjectTemplatesSet", "Button", LayerIndex.Options, GUI.w - 44 * RL.scaleFactor, options_pad_top + options_yOffset * RL.scaleFactor, 34 * RL.scaleFactor, 20 * RL.scaleFactor, "Set", Path_Set_ProjectTemplateFolder)
  GUI.elms.options_txtProjectTemplatesPath.cap_pos = "top"

  -- custom track template folder
  GUI.New("options_btnTrackTemplatesClear", "Button", LayerIndex.Options, 20, options_pad_top + 2 * options_yOffset * RL.scaleFactor, 45 * RL.scaleFactor, 20 * RL.scaleFactor, "Remove", Path_Clear_TrackTemplateFolder)
  GUI.New("options_txtTrackTemplatesPath", "Textbox", LayerIndex.Options, 68 * RL.scaleFactor, options_pad_top + 2 * options_yOffset * RL.scaleFactor, GUI.w - options_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, "Custom .RTrackTemplate [ Track Templates ] folder", 8)
  GUI.New("optioptions_btnTrackTemplatesSet", "Button", LayerIndex.Options, GUI.w - 44 * RL.scaleFactor, options_pad_top + 2 * options_yOffset * RL.scaleFactor, 34 * RL.scaleFactor, 20 * RL.scaleFactor, "Set", Path_Set_TrackTemplateFolder)
  GUI.elms.options_txtTrackTemplatesPath.cap_pos = "top"

  -- custom project folder
  GUI.New("options_btnCustomProjectsClear", "Button", LayerIndex.Options, 20, options_pad_top + 3 * options_yOffset * RL.scaleFactor, 45 * RL.scaleFactor, 20 * RL.scaleFactor, "Remove", Path_Clear_CustomProjectFolder)
  GUI.New("options_txtCustomProjectsPath", "Textbox", LayerIndex.Options, 68 * RL.scaleFactor, options_pad_top + 3 * options_yOffset * RL.scaleFactor, GUI.w - options_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, ".RPP [ Projects ] folder", 8)
  GUI.New("options_btnCustomProjectsSet", "Button", LayerIndex.Options, GUI.w - 44 * RL.scaleFactor, options_pad_top + 3 * options_yOffset * RL.scaleFactor, 34 * RL.scaleFactor, 20 * RL.scaleFactor, "Set", Path_Set_CustomProjectFolder)
  GUI.elms.options_txtCustomProjectsPath.cap_pos = "top"

  -- project list folder
  GUI.New("options_btnProjectListsClear", "Button", LayerIndex.Options, 20, options_pad_top + 4 * options_yOffset * RL.scaleFactor, 45 * RL.scaleFactor, 20 * RL.scaleFactor, "Remove", Path_Clear_ProjectListFolder)
  GUI.New("options_txtProjectsListsPath", "Textbox", LayerIndex.Options, 68 * RL.scaleFactor, options_pad_top + 4 * options_yOffset * RL.scaleFactor, GUI.w - options_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, ".RPL [ Project Lists ] folder", 8)
  GUI.New("options_btnProjectListsSet", "Button", LayerIndex.Options, GUI.w - 44 * RL.scaleFactor, options_pad_top + 4 * options_yOffset * RL.scaleFactor, 34 * RL.scaleFactor, 20 * RL.scaleFactor, "Set", Path_Set_ProjectListFolder)
  GUI.elms.options_txtProjectsListsPath.cap_pos = "top"

  -- backup files folder
  GUI.New("options_btnBackupsClear", "Button", LayerIndex.Options, 20, options_pad_top + 5 * options_yOffset * RL.scaleFactor, 45 * RL.scaleFactor, 20 * RL.scaleFactor, "Remove", Path_Clear_BackupsFolder)
  GUI.New("options_txtBackupsPath", "Textbox", LayerIndex.Options, 68 * RL.scaleFactor, options_pad_top + 5 * options_yOffset * RL.scaleFactor, GUI.w - options_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, ".RPP-BAK [ Backups ] folder", 8)
  GUI.New("options_btnBackupsSet", "Button", LayerIndex.Options, GUI.w - 44 * RL.scaleFactor, options_pad_top + 5 * options_yOffset * RL.scaleFactor, 34 * RL.scaleFactor, 20 * RL.scaleFactor, "Set", Path_Set_BackupsFolder)
  GUI.elms.options_txtBackupsPath.cap_pos = "top"

  -- docs folder
  GUI.New("options_btnDocsClear", "Button", LayerIndex.Options, 20, options_pad_top + 6 * options_yOffset * RL.scaleFactor, 45 * RL.scaleFactor, 20 * RL.scaleFactor, "Remove", Path_Clear_DocsFolder)
  GUI.New("options_txtDocsPath", "Textbox", LayerIndex.Options, 68 * RL.scaleFactor, options_pad_top + 6 * options_yOffset * RL.scaleFactor, GUI.w - options_textBoxWidth * RL.scaleFactor, 20 * RL.scaleFactor, ".PDF [ Docs ] folder", 8)
  GUI.New("options_btnDocsSet", "Button", LayerIndex.Options, GUI.w - 44 * RL.scaleFactor, options_pad_top + 6 * options_yOffset * RL.scaleFactor, 34 * RL.scaleFactor, 20 * RL.scaleFactor, "Set", Path_Set_DocsFolder)
  GUI.elms.options_txtDocsPath.cap_pos = "top"

  -- show subfolder panel
  GUI.New("options_lblShowSubfolderPanel", "Label", LayerIndex.Options, GUI.w - 308 * RL.scaleFactor + (RL.scaleFactor * 30), options_pad_top + (7 * options_yOffset - 18) * RL.scaleFactor, "Show subfolder-panel (restart required)", false, 3)
  GUI.New("options_checklistShowSubfolderPanel", "Checklist", LayerIndex.Options, GUI.w - 85 * RL.scaleFactor, options_pad_top + (7 * options_yOffset - 18) * RL.scaleFactor, 20 * RL.scaleFactor - (5 * RL.scaleFactor), 20 * RL.scaleFactor - (5 * RL.scaleFactor), "", "", "h", 0)
  GUI.elms.options_checklistShowSubfolderPanel.opt_size = 20 * RL.scaleFactor - (5 * RL.scaleFactor)
  GUI.elms.options_checklistShowSubfolderPanel:init()
  
  -- double-click behavior
  local menuDoubleClickOptions = "Show Prompt,Load,Load in Tab"
  if JSAPIinstalled then menuDoubleClickOptions = menuDoubleClickOptions .. ",Audio Preview" end
  GUI.New("options_menuDoubleClick", "Menubox", LayerIndex.Options, GUI.w - 158 * RL.scaleFactor, options_pad_top + (8 * options_yOffset - 18) * RL.scaleFactor, 96 * RL.scaleFactor - (5 * RL.scaleFactor), 20 * RL.scaleFactor - (5 * RL.scaleFactor), "Double Click", menuDoubleClickOptions, 8)
  GUI.elms.options_menuDoubleClick.align = "1"

  function GUI.elms.options_menuDoubleClick:onmousedown()
    GUI.Menubox.onmouseup(self)
    reaper.SetExtState(appname, "mouse_doubleclick", GUI.Val("options_menuDoubleClick"), 1)
  end
  
  function GUI.elms.options_menuDoubleClick:onwheel()
    GUI.Menubox.onwheel(self)
    reaper.SetExtState(appname, "mouse_doubleclick", GUI.Val("options_menuDoubleClick"), 1)
  end

  -- theme slot options
  if SWSinstalled then 
    RL_Draw_SavePromptOption(options_pad_top, options_yOffset);
    RL_Draw_ThemeSlotOptions()
  end

  -- enable textbox input
  function GUI.elms.options_txtProjectTemplatesPath:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end

  function GUI.elms.options_txtTrackTemplatesPath:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end

  function GUI.elms.options_txtCustomProjectsPath:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end

  function GUI.elms.options_txtProjectsListsPath:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end

  function GUI.elms.options_txtBackupsPath:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end

  function GUI.elms.options_txtDocsPath:onmousedown()
    GUI.Textbox.onmousedown(self)
    RL.keyInputActive = false
  end

  -- disable textbox input on lost focus
  function GUI.elms.options_txtProjectTemplatesPath:lostfocus()
    RL.keyInputActive = true
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.options_txtTrackTemplatesPath:lostfocus()
    RL.keyInputActive = true
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.options_txtCustomProjectsPath:lostfocus()
    RL.keyInputActive = true
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.options_txtProjectsListsPath:lostfocus()
    RL.keyInputActive = true
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.options_txtBackupsPath:lostfocus()
    RL.keyInputActive = true
    GUI.Textbox.lostfocus(self)
  end
  
  function GUI.elms.options_txtDocsPath:lostfocus()
    RL.keyInputActive = true
    GUI.Textbox.lostfocus(self)
  end
end

-------------
-- Tab - Help
-------------
local helpKeyDescriptions = {
[[
select prev | next tab
select tab directly
- - - - -
help
options
context menu
- - - - -
list refresh
toggle subfolder paths
toggle paths
- - - - -
keep (window) open
window - scale toggle
window - scale down | up]]
,
[[
filter - jump into | out
filter - clear
- - - - -
prev | next subfolder
prev | next in list
- - - - -
load in tab
load
toggle audio preview 
- - - - -
show in explorer/finder
open project
new project
new tab
new tab - ignore template
- - - - -
close current project tab
prev | next project tab]]
}

local helpKeyShortcuts = {
[[
LEFT | RIGHT
1, 2, 3, 4, 5, 6, 7
- - - - -
F1
F2
M , 0
- - - - -
F5
SHIFT + P
P
- - - - -
W
F10
F11 | F12]]
,
[[
TAB | ENTER
BACKSPACE/DELETE
- - - - -
SHIFT + UP | DOWN
UP | DOWN
- - - - -
SHIFT + ENTER
ENTER
SPACE , *
- - - - -
S
O
N
T , + 
/
- - - - -
C , -
X | V]]
}

local helpInfo = {
[[
- - - - - - - - - - - -
Audio preview
- - - - - - - - - - - -
[ Requires js_ReaScriptAPI installed ]
- -
Preparation: Place a WAV, FLAC, MP3 or OGG audio file with identical name into the same folder as the project or template file
- -
  Example: testproject.rpp / testproject.wav
- -
Adjust the preview volume knob (0 - 100 %) via LEFT DRAG or MOUSEWHEEL
- -
Select preview output channels (by default outputs 1/2 are used)
- -
Start & Stop a preview of a selected entry via DOUBLE CLICK on the volume knob or via the SPACE and * key
- -
  Status colors:
  - SILVER: preview file available
  - GREEN: preview file playing
]]
,
[[
- - - - - - - - - - - - - - -
Listbox multi-select 
- - - - - - - - - - - - - - -
Selection of multiple list entries is possible via:
- -
  SHIFT + LEFT CLICK: select adjacent entries
  CTRL/CMD + LEFT CLICK: select non-adjacent entries
- -
Loading a single entry directly is also possible via DOUBLE CLICK
]]
,
[[
- - - - - - - - - - - - - - - - - - - - - -
Load projects with FX offline
- - - - - - - - - - - - - - - - - - - - - - 
Possible by holding the global key combination while loading:
- -
  CTRL + SHIFT (Windows & Linux)
  CMD + SHIFT  (macOS)
- -
Or by using the 'Open with FX offline' option in the [Open Project] window
]]
,
[[
- - - - - - - - - - - - - - -
[ Recent Projects ]
- - - - - - - - - - - - - - -
[ Requires SWS Extensions installed ]
- -
RIGHT CLICK on the Recent Projects listbox opens the (Remove selected entries | Clear entire list) context menu for removing selected entries or clearing the entire list
- -
The 'Remove selected entries' menu option is only available for an unfiltered list
]]
}

local function RL_Draw_TabHelp()
  local threadUrl = [[https://forum.cockos.com/showthread.php?t=208697]]
  local frameOffsetY = 50 * RL.scaleFactor 
  local frameHeight = GUI.h - (75 * RL.scaleFactor)
  local frameWidth = GUI.w/4 + (22 * RL.scaleFactor)
  local framePad = 10 * RL.scaleFactor
  local shortcutEntries = "Key shortcuts (1/2),Key shortcuts (2/2)"
  local helpEntries = "Audio preview,Listbox multi-select,Load with FX offline,Recent Projects"

  GUI.New("help_menuShortcuts", "Menubox", LayerIndex.Help, 5, 26 * RL.scaleFactor, 160 * RL.scaleFactor, 20 * RL.scaleFactor, "", shortcutEntries)
  GUI.elms.help_menuShortcuts.align = "1"
  GUI.New("help_menuHelp", "Menubox", LayerIndex.Help, (2 * frameWidth) - 30, 26 * RL.scaleFactor, 150 * RL.scaleFactor, 20 * RL.scaleFactor, "", helpEntries)
  GUI.elms.help_menuHelp.align = "1"

  GUI.New("help_frameLeft", "Frame", LayerIndex.Help, 5, frameOffsetY, frameWidth, frameHeight, false, false)
  GUI.New("help_frameMiddle", "Frame", LayerIndex.Help, 5 + frameWidth, frameOffsetY, frameWidth - 40, frameHeight, false, false)
  GUI.New("help_frameRight", "Frame", LayerIndex.Help, (2 * frameWidth) - 36, frameOffsetY, (2 * frameWidth) - (80 * RL.scaleFactor), frameHeight, false, false)
  GUI.elms.help_frameLeft.pad = framePad
  GUI.elms.help_frameMiddle.pad = framePad
  GUI.elms.help_frameRight.pad = framePad

  GUI.Val("help_frameLeft", helpKeyDescriptions[1]);
  GUI.Val("help_frameMiddle", helpKeyShortcuts[1]);
  
  GUI.Val("help_menuHelp", 4)
  GUI.Val("help_frameRight", helpInfo[4]);

  if SWSinstalled then
    GUI.New("help_btnThread", "Button", LayerIndex.Help, GUI.w - (100 * RL.scaleFactor), 26 * RL.scaleFactor, 90 * RL.scaleFactor, 18 * RL.scaleFactor, "Forum thread")
    function GUI.elms.help_btnThread:onmousedown()
      GUI.Button.onmousedown(self)
      reaper.CF_ShellExecute(threadUrl)
    end
  end

  function GUI.elms.help_menuShortcuts:onmousedown()
    GUI.Menubox.onmouseup(self)
    GUI.Val("help_frameLeft", helpKeyDescriptions[GUI.Val("help_menuShortcuts")]);
    GUI.Val("help_frameMiddle", helpKeyShortcuts[GUI.Val("help_menuShortcuts")]);
  end
  
  function GUI.elms.help_menuShortcuts:onwheel()
    GUI.Menubox.onwheel(self)
    GUI.Val("help_frameLeft", helpKeyDescriptions[GUI.Val("help_menuShortcuts")]);
    GUI.Val("help_frameMiddle", helpKeyShortcuts[GUI.Val("help_menuShortcuts")]);
  end

  function GUI.elms.help_menuHelp:onmousedown()
    GUI.Menubox.onmouseup(self)
    GUI.Val("help_frameRight", helpInfo[GUI.Val("help_menuHelp")]);
  end
  
  function GUI.elms.help_menuHelp:onwheel()
    GUI.Menubox.onwheel(self)
    GUI.Val("help_frameRight", helpInfo[GUI.Val("help_menuHelp")]);
  end
end

-----------
-- Tooltips
-----------
local function RL_Draw_Tooltips()
  local ttLoadFXoffline = "Load with FX offline:\n  - Hold CTRL + SHIFT (Windows & Linux)\n  - Hold CMD + SHIFT (macOS)\n  - Via the option in the [Open Project] window"
  -- main
  GUI.elms.main_menuPaths.tooltip = "Hide/Show file paths in the list"
  GUI.elms.main_btnNewProjectTab.tooltip = "Add new project tab"
  GUI.elms.main_btnNewTabIgnoreTemplate.tooltip = "Add new project tab\n(ignore default template)"
  GUI.elms.main_btnNewProject.tooltip = "Create new project"
  GUI.elms.main_btnOpenProject.tooltip = "Show the 'Open project' window"
  -- window pin
  local ttWindowPin = "Check this box to keep the window open"
  GUI.elms.main_lblWindowpin.tooltip = ttWindowPin
  GUI.elms.main_checklistWindowPin.tooltip = ttWindowPin
  -- save as new version
  local ttSaveAsNewVersion = "Save the loaded project(s) with an\nincremented version number: _1, _2, ..."
  GUI.elms.main_lblSaveNewVersion.tooltip = ttSaveAsNewVersion
  GUI.elms.main_checklistSaveAsNewVersion.tooltip = ttSaveAsNewVersion
  -- recent projects
  GUI.elms.tab_recentProjects_btnRefresh.tooltip = "Refresh the [Recent Projects] list"
  GUI.elms.tab_recentProjects_txtFilter.tooltip = "Filter the [Recent Projects] list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_recentProjects_btnFilterClear.tooltip = "Clear Filter"
  GUI.elms.tab_recentProjects_btnLoadInTab.tooltip = "Load selected recent project(s) in tab(s)\n\n" .. ttLoadFXoffline
  GUI.elms.tab_recentProjects_btnLoad.tooltip = "Load selected recent project(s)\n\n" .. ttLoadFXoffline
  -- project templates
  GUI.elms.tab_projectTemplates_btnRefresh.tooltip = "Refresh [Project Templates] list"
  GUI.elms.tab_projectTemplates_txtFilter.tooltip = "Filter the [Project Templates] list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_projectTemplates_btnFilterClear.tooltip = "Clear Filter"
  GUI.elms.tab_projectTemplates_btnLoadInTab.tooltip = "Load selected project template(s) in tab(s)\n\n" .. ttLoadFXoffline
  GUI.elms.tab_projectTemplates_btnLoad.tooltip = "Load selected project templates(s)\n\n" .. ttLoadFXoffline
  -- template edit mode
  local tooltip_projectTemplatesEditMode = "Check to open project template in edit mode"
  GUI.elms.tab_projectTemplates_lblEditMode.tooltip = tooltip_projectTemplatesEditMode
  GUI.elms.tab_projectTemplates_checklistEditMode.tooltip = tooltip_projectTemplatesEditMode
  -- track templates
  GUI.elms.tab_trackTemplates_btnRefresh.tooltip = "Refresh the [Track Templates] list"
  GUI.elms.tab_trackTemplates_txtFilter.tooltip = "Filter the [Track Templates] list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_trackTemplates_btnFilterClear.tooltip = "Clear Filter"
  GUI.elms.tab_trackTemplates_btnInsert.tooltip = "Insert selected track template(s)"
  -- projects
  GUI.elms.tab_customProjects_btnFilter.tooltip = "Refresh the [Projects] list"
  GUI.elms.tab_customProjects_txtFilter.tooltip = "Filter the [Projects] list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_customProjects_btnLoadInTab.tooltip = "Load the selected project(s) in tab(s)\n\n" .. ttLoadFXoffline
  GUI.elms.tab_customProjects_btnLoad.tooltip = "Load the selected project(s)\n\n" .. ttLoadFXoffline
  -- project lists
  GUI.elms.tab_projectLists_btnRefresh.tooltip = "Refresh the [Project Lists] list"
  GUI.elms.tab_projectLists_txtFilter.tooltip = "Filter the [Project Lists] list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_projectLists_btnFilterClear.tooltip = "Clear Filter"
  GUI.elms.tab_projectLists_btnLoadInTab.tooltip = "Load the selected project(s) in tab(s)\n\n" .. ttLoadFXoffline
  GUI.elms.tab_projectLists_btnLoad.tooltip = "Load the selected project(s)\n\n" .. ttLoadFXoffline
  -- backups
  GUI.elms.tab_backups_btnRefresh.tooltip = "Refresh the [Backups] list"
  GUI.elms.tab_backups_txtFilter.tooltip = "Filter the [Backups] list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_backups_btnFilterClear.tooltip = "Clear Filter"
  GUI.elms.tab_backups_btnLoadInTab.tooltip = "Load the selected backup(s) in tab(s)\n\n" .. ttLoadFXoffline
  GUI.elms.tab_backups_btnLoad.tooltip = "Load the selected backup(s)\n\n" .. ttLoadFXoffline
  -- project templates path
  GUI.elms.options_btnProjectTemplatesClear.tooltip = "Remove [ Project Templates ] paths"
  GUI.elms.options_btnProjectTemplatesSet.tooltip = "Set given paths for [ Project Templates ]"
  GUI.elms.options_txtProjectTemplatesPath.tooltip = "Enter one or multiple paths (separated by a semicolon) for [ Project Templates ]"
  -- track templates path
  GUI.elms.options_btnTrackTemplatesClear.tooltip = "Remove [ Track Templates ] paths"
  GUI.elms.optioptions_btnTrackTemplatesSet.tooltip = "Set given paths for [ Track Templates ]"
  GUI.elms.options_txtTrackTemplatesPath.tooltip = "Enter one or multiple paths (separated by a semicolon) for [ Track Templates ]"
  -- custom projects path
  GUI.elms.options_btnCustomProjectsClear.tooltip = "Remove [ Projects ] paths"
  GUI.elms.options_btnCustomProjectsSet.tooltip = "Set given paths for [ Projects ]"
  GUI.elms.options_txtCustomProjectsPath.tooltip = "Enter one or multiple paths (separated by a semicolon) for [ Projects ]"
  -- project lists path
  GUI.elms.options_btnProjectListsClear.tooltip = "Remove [ Project Lists ] paths"
  GUI.elms.options_btnProjectListsSet.tooltip = "Set given paths for [ Project Lists ]"
  GUI.elms.options_txtProjectsListsPath.tooltip = "Enter one or multiple paths (separated by a semicolon) for [ Project Lists ]"
  -- backup path
  GUI.elms.options_btnBackupsClear.tooltip = "Remove [ Backups ] paths"
  GUI.elms.options_btnBackupsSet.tooltip = "Set given path for [ Backups ]"
  GUI.elms.options_txtBackupsPath.tooltip = "Enter one or multiple paths (separated by a semicolon) for [ Backups ]"
  -- docs path
  GUI.elms.options_btnDocsClear.tooltip = "Remove [ Docs ] paths"
  GUI.elms.options_btnDocsSet.tooltip = "Set given path for [ Docs ]"
  GUI.elms.options_txtDocsPath.tooltip = "Enter one or multiple paths (separated by a semicolon) for [ Docs ]"
  -- show subfolder panel
  local tooltipSubfolderPanel = "Toggles the visibility of the subfolder-panel\nRestart required for the changes to take effect"
  GUI.elms.options_lblShowSubfolderPanel.tooltip = tooltipSubfolderPanel
  GUI.elms.options_checklistShowSubfolderPanel.tooltip = tooltipSubfolderPanel

  if JSAPIinstalled then
    GUI.elms.options_btnProjectTemplatesBrowse.tooltip = "Browse for [ Project Templates ] folders"
    GUI.elms.options_btnTrackTemplatesBrowse.tooltip = "Browse for [ Track Templates ] folders"
    GUI.elms.options_btnCustomProjectsBrowse.tooltip = "Browse for [ Projects ] folders"
    GUI.elms.options_btnProjectListsBrowse.tooltip = "Browse for [ Project Lists ] folders" 
    GUI.elms.options_btnBackupsBrowse.tooltip = "Browse for [ Backups ] folders"
    GUI.elms.options_btnDocsBrowse.tooltip = "Browse for [ Docs ] folders"
  end

  if SWSinstalled then
    GUI.elms.main_btnOpenInExplorer.tooltip = "Browse to file location"
  end
end

--------------------------
-- Color element functions
--------------------------
local ButtonColor = "wnd_bg"

local function RL_Draw_Colors_Button()
  -- main section
  GUI.elms.main_btnOpenProject.col_fill = ButtonColor
  GUI.elms.main_btnOpenProject:init()
  GUI.elms.main_btnNewProjectTab.col_fill = ButtonColor
  GUI.elms.main_btnNewProjectTab:init()
  GUI.elms.main_btnNewTabIgnoreTemplate.col_fill = ButtonColor
  GUI.elms.main_btnNewTabIgnoreTemplate:init()
  GUI.elms.main_btnNewProject.col_fill = ButtonColor
  GUI.elms.main_btnNewProject:init()
  -- recent projects
  GUI.elms.tab_recentProjects_btnRefresh.col_fill = ButtonColor
  GUI.elms.tab_recentProjects_btnRefresh:init()
  GUI.elms.tab_recentProjects_btnFilterClear.col_fill = ButtonColor
  GUI.elms.tab_recentProjects_btnFilterClear:init()
  GUI.elms.tab_recentProjects_btnLoadInTab.col_fill = ButtonColor
  GUI.elms.tab_recentProjects_btnLoadInTab:init()
  GUI.elms.tab_recentProjects_btnLoad.col_fill = ButtonColor
  GUI.elms.tab_recentProjects_btnLoad:init()
  -- project templates
  GUI.elms.tab_projectTemplates_btnRefresh.col_fill = ButtonColor
  GUI.elms.tab_projectTemplates_btnRefresh:init()
  GUI.elms.tab_projectTemplates_btnFilterClear.col_fill = ButtonColor
  GUI.elms.tab_projectTemplates_btnFilterClear:init()
  GUI.elms.tab_projectTemplates_btnLoadInTab.col_fill = ButtonColor
  GUI.elms.tab_projectTemplates_btnLoadInTab:init()
  GUI.elms.tab_projectTemplates_btnLoad.col_fill = ButtonColor
  GUI.elms.tab_projectTemplates_btnLoad:init()
  -- track templates
  GUI.elms.tab_trackTemplates_btnRefresh.col_fill = ButtonColor
  GUI.elms.tab_trackTemplates_btnRefresh:init()
  GUI.elms.tab_trackTemplates_btnFilterClear.col_fill = ButtonColor
  GUI.elms.tab_trackTemplates_btnFilterClear:init()
  GUI.elms.tab_trackTemplates_btnInsert.col_fill = ButtonColor
  GUI.elms.tab_trackTemplates_btnInsert:init()
  -- custom projects
  GUI.elms.tab_customProjects_btnFilter.col_fill = ButtonColor
  GUI.elms.tab_customProjects_btnFilter:init()
  GUI.elms.tab_customProjects_btnFilterClear.col_fill = ButtonColor
  GUI.elms.tab_customProjects_btnFilterClear:init()
  GUI.elms.tab_customProjects_btnLoadInTab.col_fill = ButtonColor
  GUI.elms.tab_customProjects_btnLoadInTab:init()
  GUI.elms.tab_customProjects_btnLoad.col_fill = ButtonColor
  GUI.elms.tab_customProjects_btnLoad:init()
  -- project list
  GUI.elms.tab_projectLists_btnRefresh.col_fill = ButtonColor
  GUI.elms.tab_projectLists_btnRefresh:init()
  GUI.elms.tab_projectLists_btnFilterClear.col_fill = ButtonColor
  GUI.elms.tab_projectLists_btnFilterClear:init()
  GUI.elms.tab_projectLists_btnLoadInTab.col_fill = ButtonColor
  GUI.elms.tab_projectLists_btnLoadInTab:init()
  GUI.elms.tab_projectLists_btnLoad.col_fill = ButtonColor
  GUI.elms.tab_projectLists_btnLoad:init()
  -- backups
  GUI.elms.tab_backups_btnRefresh.col_fill = ButtonColor
  GUI.elms.tab_backups_btnRefresh:init()
  GUI.elms.tab_backups_btnFilterClear.col_fill = ButtonColor
  GUI.elms.tab_backups_btnFilterClear:init()
  GUI.elms.tab_backups_btnLoadInTab.col_fill = ButtonColor
  GUI.elms.tab_backups_btnLoadInTab:init()
  GUI.elms.tab_backups_btnLoad.col_fill = ButtonColor
  GUI.elms.tab_backups_btnLoad:init()
  -- docs
  GUI.elms.tab_docs_btnRefresh.col_fill = ButtonColor
  GUI.elms.tab_docs_btnRefresh:init()
  GUI.elms.tab_docs_btnFilterClear.col_fill = ButtonColor
  GUI.elms.tab_docs_btnFilterClear:init()
  GUI.elms.tab_docs_btnOpen.col_fill = ButtonColor
  GUI.elms.tab_docs_btnOpen:init()
  -- options - project templates
  GUI.elms.options_btnProjectTemplatesClear.col_fill = ButtonColor
  GUI.elms.options_btnProjectTemplatesClear:init()
  GUI.elms.options_btnProjectTemplatesSet.col_fill = ButtonColor
  GUI.elms.options_btnProjectTemplatesSet:init()
  -- options - track templates
  GUI.elms.options_btnTrackTemplatesClear.col_fill = ButtonColor
  GUI.elms.options_btnTrackTemplatesClear:init()
  GUI.elms.optioptions_btnTrackTemplatesSet.col_fill = ButtonColor
  GUI.elms.optioptions_btnTrackTemplatesSet:init()
  -- options - custom projects
  GUI.elms.options_btnCustomProjectsClear.col_fill = ButtonColor
  GUI.elms.options_btnCustomProjectsClear:init()
  GUI.elms.options_btnCustomProjectsSet.col_fill = ButtonColor
  GUI.elms.options_btnCustomProjectsSet:init()
  -- options - project lists
  GUI.elms.options_btnProjectListsClear.col_fill = ButtonColor
  GUI.elms.options_btnProjectListsClear:init()
  GUI.elms.options_btnProjectListsSet.col_fill = ButtonColor
  GUI.elms.options_btnProjectListsSet:init()
  -- options - backups
  GUI.elms.options_btnBackupsClear.col_fill = ButtonColor
  GUI.elms.options_btnBackupsClear:init()
  GUI.elms.options_btnBackupsSet.col_fill = ButtonColor
  GUI.elms.options_btnBackupsSet:init()
  -- options - docs
  GUI.elms.options_btnDocsClear.col_fill = ButtonColor
  GUI.elms.options_btnDocsClear:init()
  GUI.elms.options_btnDocsSet.col_fill = ButtonColor
  GUI.elms.options_btnDocsSet:init()
  
  if JSAPIinstalled then 
    GUI.elms.options_btnProjectTemplatesBrowse.col_fill = ButtonColor
    GUI.elms.options_btnProjectTemplatesBrowse:init()
    GUI.elms.options_btnTrackTemplatesBrowse.col_fill = ButtonColor
    GUI.elms.options_btnTrackTemplatesBrowse:init()
    GUI.elms.options_btnCustomProjectsBrowse.col_fill = ButtonColor
    GUI.elms.options_btnCustomProjectsBrowse:init()
    GUI.elms.options_btnProjectListsBrowse.col_fill = ButtonColor
    GUI.elms.options_btnProjectListsBrowse:init()
    GUI.elms.options_btnBackupsBrowse.col_fill = ButtonColor
    GUI.elms.options_btnBackupsBrowse:init()
    GUI.elms.options_btnDocsBrowse.col_fill = ButtonColor
    GUI.elms.options_btnDocsBrowse:init()
  end

  if SWSinstalled then 
    -- thread button
    GUI.elms.help_btnThread.col_fill = ButtonColor
    GUI.elms.help_btnThread:init()
    -- open in explorer
    GUI.elms.main_btnOpenInExplorer.col_fill = ButtonColor
    GUI.elms.main_btnOpenInExplorer:init()
    -- themeslot selector
    GUI.elms.options_themeslot_Setup.col_fill = ButtonColor
    GUI.elms.options_themeslot_Setup:init()
    GUI.elms.options_themeslot_Save.col_fill = ButtonColor
    GUI.elms.options_themeslot_Save:init()
  end
end

----------------------
-- Draw function relay
----------------------
local function RL_Draw_Tabs()
  RL_Draw_TabRecentProjects()
  RL_Draw_TabProjectTemplates()
  RL_Draw_TabTrackTemplates()
  RL_Draw_TabCustomProjects()
  RL_Draw_TabProjectLists()
  RL_Draw_TabBackups()
  RL_Draw_TabDocs()
  RL_Draw_TabOptions()
  RL_Draw_TabHelp()
end

local function RL_Draw_AddOns()
  RL_Draw_Tooltips()
  RL_Draw_Colors_Button()
end

-- draw all
RL_Draw_Main()
RL_Draw_Tabs()
RL_Draw_Frames()
RL_Draw_AddOns()

------------------
-- Redraw function
------------------
local function RL_RedrawAll()
  -- main
  GUI.elms.main_tabs:ondelete()
  GUI.elms.main_appversion:ondelete()
  GUI.elms.main_statusbar:ondelete()
  -- main elements
  GUI.elms.main_menuPaths:ondelete()
  if SWSinstalled then GUI.elms.main_btnOpenInExplorer:ondelete() end
  GUI.elms.main_btnNewProjectTab:ondelete()
  GUI.elms.main_btnNewTabIgnoreTemplate:ondelete()
  GUI.elms.main_btnNewProject:ondelete()
  GUI.elms.main_btnOpenProject:ondelete()
  GUI.elms.main_lblWindowpin:ondelete()
  GUI.elms.main_checklistWindowPin:ondelete()
  GUI.elms.main_lblSaveNewVersion:ondelete()
  GUI.elms.main_checklistSaveAsNewVersion:ondelete()
  RL_Draw_Main()
  -- recent projects
  GUI.elms.tab_recentProjects_btnRefresh:ondelete()
  GUI.elms.tab_recentProjects_txtFilter:ondelete()
  GUI.elms.tab_recentProjects_btnFilterClear:ondelete()
  GUI.elms.tab_recentProjects_listbox:ondelete()
  GUI.elms.tab_recentProjects_btnLoadInTab:ondelete()
  GUI.elms.tab_recentProjects_btnLoad:ondelete()
  -- project templates
  GUI.elms.tab_projectTemplates_btnRefresh:ondelete()
  GUI.elms.tab_projectTemplates_txtFilter:ondelete()
  GUI.elms.tab_projectTemplates_btnFilterClear:ondelete()
  GUI.elms.tab_projectTemplates_listbox:ondelete()
  GUI.elms.tab_projectTemplates_btnLoadInTab:ondelete()
  GUI.elms.tab_projectTemplates_btnLoad:ondelete()
  GUI.elms.tab_projectTemplates_lblEditMode:ondelete()
  GUI.elms.tab_projectTemplates_checklistEditMode:ondelete()
  -- track templates
  GUI.elms.tab_trackTemplates_btnRefresh:ondelete()
  GUI.elms.tab_trackTemplates_txtFilter:ondelete()
  GUI.elms.tab_trackTemplates_btnFilterClear:ondelete()
  GUI.elms.tab_trackTemplates_listbox:ondelete()
  GUI.elms.tab_trackTemplates_btnInsert:ondelete()
  -- custom projects
  GUI.elms.tab_customProjects_btnFilter:ondelete()
  GUI.elms.tab_customProjects_txtFilter:ondelete()
  GUI.elms.tab_customProjects_btnFilterClear:ondelete()
  GUI.elms.tab_customProjects_listbox:ondelete()
  GUI.elms.tab_customProjects_btnLoadInTab:ondelete()
  GUI.elms.tab_customProjects_btnLoad:ondelete()
  -- project lists
  GUI.elms.tab_projectLists_btnRefresh:ondelete()
  GUI.elms.tab_projectLists_txtFilter:ondelete()
  GUI.elms.tab_projectLists_btnFilterClear:ondelete()
  GUI.elms.tab_projectLists_listboxRPL:ondelete()
  GUI.elms.tab_projectLists_listboxProjects:ondelete()
  GUI.elms.tab_projectLists_btnLoadInTab:ondelete()
  GUI.elms.tab_projectLists_btnLoad:ondelete()
  -- backups
  GUI.elms.tab_backups_btnRefresh:ondelete()
  GUI.elms.tab_backups_txtFilter:ondelete()
  GUI.elms.tab_backups_btnFilterClear:ondelete()
  GUI.elms.tab_backups_listbox:ondelete()
  GUI.elms.tab_backups_btnLoadInTab:ondelete()
  GUI.elms.tab_backups_btnLoad:ondelete()

  if showSubfolderPanel then
    GUI.elms.tab_projectTemplates_subfolders:ondelete()
    GUI.elms.tab_trackTemplates_subfolders:ondelete()
    GUI.elms.tab_customProjects_subfolders:ondelete()
    GUI.elms.tab_backups_subfolders:ondelete()
  end

  -- options - project templates
  GUI.elms.options_btnProjectTemplatesClear:ondelete()
  GUI.elms.options_btnProjectTemplatesSet:ondelete()
  GUI.elms.options_txtProjectTemplatesPath:ondelete()
  -- options - track templates
  GUI.elms.options_btnTrackTemplatesClear:ondelete()
  GUI.elms.optioptions_btnTrackTemplatesSet:ondelete()
  GUI.elms.options_txtTrackTemplatesPath:ondelete()
  -- options - custom projects
  GUI.elms.options_btnCustomProjectsClear:ondelete()
  GUI.elms.options_btnCustomProjectsSet:ondelete()
  GUI.elms.options_txtCustomProjectsPath:ondelete()
  -- options - project lists
  GUI.elms.options_btnProjectListsClear:ondelete()
  GUI.elms.options_btnProjectListsSet:ondelete()
  GUI.elms.options_txtProjectsListsPath:ondelete()
  -- options - backups
  GUI.elms.options_btnBackupsClear:ondelete()
  GUI.elms.options_btnBackupsSet:ondelete()
  GUI.elms.options_txtBackupsPath:ondelete()
  -- help
  GUI.elms.help_frameLeft:ondelete()
  GUI.elms.help_frameMiddle:ondelete()
  GUI.elms.help_frameRight:ondelete()
  
  if SWSinstalled then
    -- theme slot options
    GUI.elms.options_themeslot_number:ondelete()
    GUI.elms.options_themeslot_1:ondelete()
    GUI.elms.options_themeslot_2:ondelete()
    GUI.elms.options_themeslot_3:ondelete()
    GUI.elms.options_themeslot_4:ondelete()
    GUI.elms.options_themeslot_5:ondelete()
    GUI.elms.options_themeslot_Setup:ondelete()
    GUI.elms.options_themeslot_Save:ondelete()
  end

  if JSAPIinstalled then
    -- audio preview channel selector
    GUI.elms.main_previewStatusLabel:ondelete()
    GUI.elms.main_previewChannels:ondelete()
    -- options
    GUI.elms.options_btnProjectTemplatesBrowse:ondelete()
    GUI.elms.options_btnTrackTemplatesBrowse:ondelete()
    GUI.elms.options_btnCustomProjectsBrowse:ondelete()
    GUI.elms.options_btnProjectListsBrowse:ondelete()
    GUI.elms.options_btnBackupsBrowse:ondelete()
  end
  
  RL_Draw_Tabs()
  RL_Draw_AddOns()
  
  -- frames
  GUI.elms.main_frame_top:ondelete()
  GUI.elms.main_frame_side_2:ondelete()
  GUI.elms.main_frame_side_3:ondelete()
  GUI.elms.main_frame_side_4:ondelete()
  GUI.elms.main_frame_side_5:ondelete()
  GUI.elms.main_frame_side_6:ondelete()
  GUI.elms.main_frame_side_7:ondelete()
  RL_Draw_Frames()
end

--------------------
-- Load Ext settings
--------------------
local function RL_ExtStates_Load()
  GUI.Val("main_checklistWindowPin", {(reaper.GetExtState(appname, "window_pin") == "true" and true or false)}) -- window pin state
  RL_SetFocusedTab(tonumber(reaper.GetExtState(appname, "window_tabfocus"))) -- last selected tab
  GUI.Val("options_checklistShowSubfolderPanel", {(reaper.GetExtState(appname, "window_showsubfolderpanel") == "true" and true or false)}) -- show subfolder panel 
  
  -- double-click behavior
  local mouseDoubleClick = reaper.GetExtState(appname, "mouse_doubleclick")
  if mouseDoubleClick == "" then mouseDoubleClick = 1 end
  if mouseDoubleClick == "4" and JSAPIinstalled == false then mouseDoubleClick = 1 end
  GUI.Val("options_menuDoubleClick", mouseDoubleClick)

  -- load path display
  local showPaths = reaper.GetExtState(appname, "window_showpaths")
  if showPaths == "" then showPaths = 1 end
  GUI.Val("main_menuPaths", tonumber(showPaths))
  Global_UpdatePathDisplayMode()

  -- filter strings
  GUI.Val("tab_recentProjects_txtFilter", reaper.GetExtState(appname, "filter_recentprojects"))
  if IsNotNullOrEmpty(GUI.Val("tab_recentProjects_txtFilter")) then
    FilterActive.RecentProjects = true
    Filter_RecentProject_Apply()
  else GUI.elms.tab_recentProjects_txtFilter.color = FilterColor.inactive end
  
  GUI.Val("tab_projectTemplates_txtFilter", reaper.GetExtState(appname, "filter_projecttemplates") )
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

  if SWSinstalled then
    GUI.Val("themeslot_max", tonumber(reaper.GetExtState(appname, "themeslot_max"))) -- max number of available theme slots
    -- load theme slot aliases
    local themeSlots = {}
    for match in string.gmatch(reaper.GetExtState(appname, "themeslot_aliases"), "[^,]+") do -- comma separator
      themeSlots[#themeSlots + 1] = string.lower(match)
    end
    for i = 1, 5 do GUI.Val("options_themeslot_" .. i, themeSlots[i]) end
    ThemeSlot_LoadNames()
  end

  if JSAPIinstalled then 
    GUI.Val("main_previewVolKnob", tonumber(reaper.GetExtState(appname, "preview_vol"))) -- preview section volume
    AudioPreview.channelIndex = tonumber(reaper.GetExtState(appname, "preview_channel")) -- preview section first output channel index
    GUI.Val("main_previewChannels",tonumber(reaper.GetExtState(appname, "preview_channelmenuitem"))) -- preview section channel menu item
  end

  -- load folder paths
  GUI.elms.options_txtProjectTemplatesPath:val(reaper.GetExtState(appname, "custompath_projecttemplates"))
  GUI.elms.options_txtTrackTemplatesPath:val(reaper.GetExtState(appname, "custompath_tracktemplates"))
  GUI.elms.options_txtCustomProjectsPath:val(reaper.GetExtState(appname, "custompath_projects"))
  GUI.elms.options_txtProjectsListsPath:val(reaper.GetExtState(appname, "custompath_projectlists"))
  GUI.elms.options_txtBackupsPath:val(reaper.GetExtState(appname, "custompath_backups"))
  GUI.elms.options_txtDocsPath:val(reaper.GetExtState(appname, "custompath_docs"))
end

--------------------
-- Save Ext settings
--------------------
local function RL_ExtStates_Save_ElementScaleFactor()
  reaper.SetExtState(appname, "window_scalefactor", tostring(RL.scaleFactor), 1) 
end

local function RL_ExtStates_Save()
  GUI.save_window_state(appname) -- window state
  RL_ExtStates_Save_ElementScaleFactor() -- scale factor for UI elements
  reaper.SetExtState(appname, "window_pin", tostring(GUI.Val("main_checklistWindowPin")), 1) -- window pin state
  reaper.SetExtState(appname, "window_tabfocus", RL_GetFocusedTab(), 1) -- last selected tab
  reaper.SetExtState(appname, "window_showsubfolderpanel", tostring(GUI.Val("options_checklistShowSubfolderPanel")), 1) -- show subfolder panel
  reaper.SetExtState(appname, "window_showpaths", tostring(GUI.Val("main_menuPaths")), 1) -- show/hide paths

  -- filter strings
  reaper.SetExtState(appname, "filter_recentprojects", GUI.Val("tab_recentProjects_txtFilter"), 1)
  reaper.SetExtState(appname, "filter_projecttemplates", GUI.Val("tab_projectTemplates_txtFilter"), 1)
  reaper.SetExtState(appname, "filter_tracktemplates", GUI.Val("tab_trackTemplates_txtFilter"), 1)
  reaper.SetExtState(appname, "filter_projects", GUI.Val("tab_customProjects_txtFilter"), 1)
  reaper.SetExtState(appname, "filter_projectlists", GUI.Val("tab_projectLists_txtFilter"), 1)
  reaper.SetExtState(appname, "filter_backups", GUI.Val("tab_backups_txtFilter"), 1)
  reaper.SetExtState(appname, "filter_docs", GUI.Val("tab_docs_txtFilter"), 1)

  if SWSinstalled then
    reaper.SetExtState(appname, "themeslot_max", tostring(GUI.Val("options_themeslot_number")), 1) -- max number of available theme slots
  end
  
  if JSAPIinstalled then 
    reaper.SetExtState(appname, "preview_vol", tostring(GUI.Val("main_previewVolKnob")), 1) -- preview section volume
    if AudioPreview.channelIndex == nil then AudioPreview.channelIndex = 0 end
    reaper.SetExtState(appname, "preview_channel", AudioPreview.channelIndex, 1) -- preview section first output channel index
    reaper.SetExtState(appname, "preview_channelmenuitem", tostring(GUI.Val("main_previewChannels")), 1) -- preview section channel menu item
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
    GUI.elms.main_previewVolKnob:init();
    GUI.elms.main_previewVolKnob:redraw(self);

    if headColor == "elm_frame" then GUI.elms.main_previewVolKnob.col_txt = "txt"
    else GUI.elms.main_previewVolKnob.col_txt = headColor end
    GUI.elms.main_previewVolKnob:init()
    
    GUI.elms.main_previewChannels.col_txt = headColor
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
    end
  end

  function AudioPreviewCheckForFile()
    local currentTab = RL_GetFocusedTab()
    local selectedIndex = TabSelectionIndex[currentTab]
    local selectedPreviewElement
    local selectedPreviewProject

    local AudioPreviewElements = {
      { RecentProjects.items, RecentProjects.names, RecentProjects.filteredNames },
      { ProjectTemplates.items, ProjectTemplates.names, ProjectTemplates.filteredNames },
      { TrackTemplates.items, TrackTemplates.names, TrackTemplates.filteredNames },
      { CustomProjects.items, CustomProjects.names, CustomProjects.filteredNames },
      { ProjectLists.projectItems, ProjectLists.projectNames, ProjectLists.filteredProjectNames },
      { Backups.items, Backups.names, Backups.filteredNames }
    }

    if IsFilterActive(currentTab) then
      selectedPreviewElement = AudioPreviewElements[currentTab][3][selectedIndex]
      selectedPreviewProject = AudioPreviewElements[currentTab][1][selectedPreviewElement] 
    else
      selectedPreviewElement = AudioPreviewElements[currentTab][2][selectedIndex]
      selectedPreviewProject = AudioPreviewElements[currentTab][1][selectedPreviewElement]
    end

    -- check for supported preview file extensions
    for t = 1, 4 do
      local selectedSourceItem
      if IsFilterActive(currentTab) then selectedSourceItem = AudioPreviewElements[currentTab][3][selectedIndex]
      else selectedSourceItem = AudioPreviewElements[currentTab][2][selectedIndex] end

      if selectedSourceItem == nil then AudioPreview.fileName = "emptyList"
      else
        AudioPreview.fileExtension = AudioPreviewFileTypes[t]
        AudioPreview.fileName = GetDirectoryPath(selectedPreviewProject) .. GetPathSeparator() .. selectedSourceItem .. AudioPreview.fileExtension
      end

      if AudioPreview.fileName ~= "emptyList" and FileExists(AudioPreview.fileName) then
        break
      end
    end

    -- set preview color
    AudioPreviewChangeVolKnobColor("none", "elm_frame")

    if FileExists(AudioPreview.fileName) then
      AudioPreviewChangeVolKnobColor("none", "silver")
      AudioPreview.statusText = selectedPreviewElement .. AudioPreview.fileExtension

      if AudioPreview.fileName == AudioPreview.lastPlayed and AudioPreview.active then 
        AudioPreviewChangeVolKnobColor("none", "elm_fill")
      end
    end
  end

  function AudioPreviewStart()
    if AudioPreview.fileName ~= nil and FileExists(AudioPreview.fileName) then
      local previewVol = (GUI.Val("main_previewVolKnob") / 100)
      if previewVol == nil or previewVol > 1 then previewVol = 1 end
  
      reaper.Xen_StopSourcePreview(-1)

      local startOutputChannel = 0
      if AudioPreview.channelIndex ~= nil and AudioPreview.channelIndex > 0 then startOutputChannel = AudioPreview.channelIndex end
      reaper.Xen_StartSourcePreview(reaper.PCM_Source_CreateFromFile(AudioPreview.fileName), previewVol, false, startOutputChannel)
      
      AudioPreview.active = true
      AudioPreview.lastPlayed = AudioPreview.fileName
      AudioPreviewChangeVolKnobColor("none", "elm_fill")
      if AudioPreview.statusText ~= nil then MsgStatusBar("AUDIO PREVIEW | " .. AudioPreview.statusText, false, false, false) end
    end
  end

  function AudioPreviewStopAll()
    reaper.Xen_StopSourcePreview(-1)
    AudioPreviewChangeVolKnobColor("none", "elm_frame")
    MsgStatusBar("", false, false, true);

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
  -- arrow keys
  UP = 30064,
  DOWN = 1685026670,
  LEFT = 1818584692,
  RIGHT = 1919379572,
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
  p = 80,
  C = 99,
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
  "",
  "",
  "",
  "tab_projectLists_listboxRPL",
  "",
  ""
}

if showSubfolderPanel then
  TabParentListBox = {
    "",
    "tab_projectTemplates_subfolders",
    "tab_trackTemplates_subfolders",
    "tab_customProjects_subfolders",
    "tab_projectLists_listboxRPL",
    "tab_backups_subfolders",
    "tab_docs_subfolders"
  }
end

local TabListBox = {
  "tab_recentProjects_listbox",
  "tab_projectTemplates_listbox",
  "tab_trackTemplates_listbox",
  "tab_customProjects_listbox",
  "tab_projectLists_listboxProjects",
  "tab_backups_listbox",
  "tab_docs_listbox"
}

local TabFilter = {
  GUI.elms.tab_recentProjects_txtFilter,
  GUI.elms.tab_projectTemplates_txtFilter,
  GUI.elms.tab_trackTemplates_txtFilter,
  GUI.elms.tab_customProjects_txtFilter,
  GUI.elms.tab_projectLists_txtFilter,
  GUI.elms.tab_backups_txtFilter,
  GUI.elms.tab_docs_txtFilter
}

-------------------
-- Listbox elements
-------------------
local ParentListBoxElements = {
  nil,
  nil,
  nil,
  nil,
  GUI.elms.tab_projectLists_listboxRPL,
  nil,
  nil
}

if showSubfolderPanel then
  ParentListBoxElements = {
    nil,
    GUI.elms.tab_projectTemplates_subfolders,
    GUI.elms.tab_trackTemplates_subfolders,
    GUI.elms.tab_customProjects_subfolders,
    GUI.elms.tab_projectLists_listboxRPL,
    GUI.elms.tab_backups_subfolders,
    GUI.elms.tab_docs_subfolders,
  }
end

ListboxElements = {
  GUI.elms.tab_recentProjects_listbox,
  GUI.elms.tab_projectTemplates_listbox,
  GUI.elms.tab_trackTemplates_listbox,
  GUI.elms.tab_customProjects_listbox,
  GUI.elms.tab_projectLists_listboxProjects,
  GUI.elms.tab_backups_listbox,
  GUI.elms.tab_docs_listbox
}

-----------------
-- Parent listbox
-----------------
-- select parent list element
local function SetParentListBoxIndex(tabIndex, selectedElement)
  GUI.Val(TabParentListBox[tabIndex], {[selectedElement] = true})
  TabParentSelectionIndex[tabIndex] = selectedElement

  local ParentListBoxItems = {
    nil,
    nil,
    nil,
    nil,
    GUI.elms.tab_projectLists_listboxRPL.list,
    nil,
    nil
  }

  if showSubfolderPanel then
    ParentListBoxItems = {
      nil,
      GUI.elms.tab_projectTemplates_subfolders.list,
      GUI.elms.tab_trackTemplates_subfolders.list,
      GUI.elms.tab_customProjects_subfolders.list,
      GUI.elms.tab_projectLists_listboxRPL.list,
      GUI.elms.tab_backups_subfolders.list,
      GUI.elms.tab_docs_subfolders.list
    }
  end

  if ParentListBoxItems[tabIndex] then
    if tabIndex == TabID.ProjectLists then
      UpdateProjectListSelection()
      Filter_ProjectLists_Clear()
    else
      if showSubfolderPanel then
        local selectedFiles = GetFiles(ParentListBoxItems[tabIndex][selectedElement])
        if tabIndex == TabID.ProjectTemplates then
          UpdateProjectTemplateSubDirSelection(selectedFiles)
          Filter_ProjectTemplate_Clear()
        elseif tabIndex == TabID.TrackTemplates then
          UpdateTrackTemplateSubDirSelection(selectedFiles)
          Filter_TrackTemplate_Clear()
        elseif tabIndex == TabID.CustomProjects then
          UpdateCustomProjectSubDirSelection(selectedFiles)
          Filter_CustomProjects_Clear()
        elseif tabIndex == TabID.Backups then
          UpdateBackupsSubDirSelection(selectedFiles)
          Filter_Backups_Clear()
        elseif tabIndex == TabID.Docs then
          UpdateDocsSubDirSelection(selectedFiles)
          Filter_Docs_Clear()
        end
      end
    end
  end

end

local function RL_Keys_ListboxSelectPreviousParent(currentTab)
  if TabParentSelectionIndex[currentTab] ~= nil and currentTab > 1 and currentTab < #MainTabs - 1 then
    local listIndex = TabParentSelectionIndex[currentTab]
    if listIndex - 1 > 0 then listIndex = listIndex - 1 end
    SetParentListBoxIndex(currentTab, listIndex)
    Scroll(ParentListBoxElements[currentTab], listIndex, -1)
  end
end

local function RL_Keys_ListboxSelectNextParent(currentTab)
  if TabParentSelectionIndex[currentTab] ~= nil and currentTab > 1 and currentTab < #MainTabs - 1 then
    
    local ParentListBoxItems = {
      nil,
      nil,
      nil,
      nil,
      GUI.elms.tab_projectLists_listboxRPL.list,
      nil,
      nil
    }

    if showSubfolderPanel then
      ParentListBoxItems = {
        nil,
        GUI.elms.tab_projectTemplates_subfolders.list,
        GUI.elms.tab_trackTemplates_subfolders.list,
        GUI.elms.tab_customProjects_subfolders.list,
        GUI.elms.tab_projectLists_listboxRPL.list,
        GUI.elms.tab_backups_subfolders.list,
        GUI.elms.tab_docs_subfolders.list
      }
    end
  
    if ParentListBoxItems[currentTab] then
      local listIndex = TabParentSelectionIndex[currentTab]
      if listIndex + 1 <= #ParentListBoxItems[currentTab] then listIndex = listIndex + 1 end
      SetParentListBoxIndex(currentTab, listIndex)
      Scroll(ParentListBoxElements[currentTab], listIndex, 1)
    end
  end
end

------------------
-- Main listbox
------------------
function SetListBoxIndex(tabIndex, selectedElement)
  GUI.Val(TabListBox[tabIndex], {[selectedElement] = true})
  TabSelectionIndex[tabIndex] = selectedElement
  if JSAPIinstalled and tabIndex ~= TabID.Docs then AudioPreviewCheckForFile() end
end

function RL_Keys_ListboxSelectPrevious(currentTab)
  if TabSelectionIndex[currentTab] ~= nil and currentTab < #MainTabs - 1 then 
    local listIndex = TabSelectionIndex[currentTab]
    if listIndex - 1 > 0 then listIndex = listIndex - 1 end
    SetListBoxIndex(currentTab, listIndex)
    Scroll(ListboxElements[currentTab], listIndex, -1)
  end
end

function RL_Keys_ListboxSelectNext(currentTab)
  if TabSelectionIndex[currentTab] ~= nil and currentTab < #MainTabs - 1 then
    local listIndex = TabSelectionIndex[currentTab]
    local ListBoxItems = {
      GUI.elms.tab_recentProjects_listbox.list,
      GUI.elms.tab_projectTemplates_listbox.list,
      GUI.elms.tab_trackTemplates_listbox.list,
      GUI.elms.tab_customProjects_listbox.list,
      GUI.elms.tab_projectLists_listboxProjects.list,
      GUI.elms.tab_backups_listbox.list,
      GUI.elms.tab_docs_listbox.list
    }
  
    if listIndex + 1 <= #ListBoxItems[currentTab] then listIndex = listIndex + 1 end
    SetListBoxIndex(currentTab, listIndex)
    Scroll(ListboxElements[currentTab], listIndex, 1)
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
  [TabID.Docs] = { call = function() Load_DocFile() end }
}

RL_Func_LoadElementInTab = {
  [TabID.RecentProjects] = { call = function() LoadInTab_RecentProject() end },
  [TabID.ProjectTemplates] = { call = function() LoadInTab_ProjectTemplate() end },
  [TabID.TrackTemplates] = { call = function() LoadInTab_TrackTemplate() end },
  [TabID.CustomProjects] = { call = function() LoadInTab_CustomProject() end },
  [TabID.ProjectLists] = { call = function() LoadInTab_ProjectListProject() end },
  [TabID.Backups] = { call = function() LoadInTab_BackupFile() end }
}

RL_Func_TabRefresh = {
  [TabID.RecentProjects] = { call = function() RefreshRecentProjects() end },
  [TabID.ProjectTemplates] = { call = function() RefreshProjectTemplates() end },
  [TabID.TrackTemplates] = { call = function() RefreshTrackTemplates() end },
  [TabID.CustomProjects] = { call = function() RefreshCustomProjects() end },
  [TabID.ProjectLists] = { call = function() RefreshProjectList() end },
  [TabID.Backups] = { call = function() RefreshBackups() end },
  [TabID.Docs] = { call = function() RefreshDocs() end }
}

----------------------------
-- Key Input - Main function
----------------------------
local function RL_Keys_CheckModifiers()
  local modifierKey = GUI.modifier.NONE
  if GUI.mouse.cap & 4 == 4 then modifierKey = GUI.modifier.CTRL
    elseif GUI.mouse.cap & 8 == 8 then modifierKey = GUI.modifier.SHIFT
    elseif GUI.mouse.cap & 16 == 16 then modifierKey = GUI.modifier.ALT
  end
  return modifierKey
end

local function RL_Keys_CheckInput()
  if RL.keyInputActive then
    local currentTab = RL_GetFocusedTab()
    local modifier = RL_Keys_CheckModifiers()
    local inputChar = gfx.getchar()

    if RL.dialogKeyMode then
      if inputChar == GUI.chars.ESC then RL_Dialog_Close()
      elseif inputChar == GUI.chars.RETURN then RL_Dialog_OK() end
    else
      -- default mode
       --if inputChar > 0 then MsgDebug("modifier: " .. modifier .. " / key: " .. inputChar) end
      -- close the window when ESC key is pressed or close function is called
      if inputChar == GUI.chars.ESC or inputChar == -1 or GUI.quit then return 0
        -- select previous tab
        elseif inputChar == GUI.chars.LEFT then 
            if currentTab > 1 then RL_SetFocusedTab(currentTab - 1) end
        -- select next tab
        elseif inputChar == GUI.chars.RIGHT then
            if currentTab < #MainTabs then RL_SetFocusedTab(currentTab + 1) end
        -- sub and main listbox selection
        elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.UP then RL_Keys_ListboxSelectPreviousParent(currentTab)
        elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.UP then RL_Keys_ListboxSelectPrevious(currentTab)
        elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.DOWN then RL_Keys_ListboxSelectNextParent(currentTab)
        elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.DOWN then RL_Keys_ListboxSelectNext(currentTab)
        -- refresh current tab
        elseif inputChar == GUI.chars.F5 and currentTab < (#MainTabs - 1) then RL_Func_TabRefresh[currentTab].call() 
        -- set focus to filter
        elseif inputChar == GUI.chars.TAB then
            if currentTab < (#MainTabs - 1) then
              RL.keyInputActive = false
              TabFilter[currentTab].focus = true
            end
        -- clear filter
        elseif inputChar == GUI.chars.BACKSPACE then RL_Keys_ClearFilter()
        -- keep window open
        elseif inputChar == GUI.chars.W then 
            if GUI.Val("main_checklistWindowPin") then GUI.Val("main_checklistWindowPin", {false}) else GUI.Val("main_checklistWindowPin", {true}) end
        -- global buttons
        elseif inputChar == GUI.chars.S then Global_OpenInExplorer() 
        elseif inputChar == GUI.chars.O then Global_ShowProjectOpenDialog() 
        elseif inputChar == GUI.chars.N then Global_NewProject()
        elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.T or inputChar == GUI.chars.PLUS then Global_NewTab() 
        elseif inputChar == GUI.chars.DIVIDE then Global_NewTabIgnoreDefaultTemplate()
        -- toggle path display in sub listbox
        elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.p then
            showSubFolderPaths = not showSubFolderPaths
            Global_UpdateSubfolderPathDisplayMode()
        -- toggle path display in main listbox
        elseif inputChar == GUI.chars.P then
            if GUI.Val("main_menuPaths") == 1 then GUI.Val("main_menuPaths", 2) else GUI.Val("main_menuPaths", 1) end
            Global_UpdatePathDisplayMode()
        -- select previous/next project tab
        elseif inputChar == GUI.chars.X then reaper.Main_OnCommand(40862, 0) -- select previous tab
        elseif inputChar == GUI.chars.V then reaper.Main_OnCommand(40861, 0) -- select next tab
        -- close current tab
        elseif inputChar == GUI.chars.C or inputChar == GUI.chars.MINUS then
            reaper.Main_OnCommand(40860, 0)
            Global_CheckWindowPinState()
        -- load (in tab)
        elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.RETURN and currentTab < (#MainTabs - 2) then RL_Func_LoadElementInTab[currentTab].call()
        elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.RETURN and currentTab < (#MainTabs - 1) then RL_Func_LoadElement[currentTab].call()
        -- scale interface
        elseif inputChar == GUI.chars.F10 then ScaleInterfaceToggle()
        elseif inputChar == GUI.chars.F11 then ScaleInterfaceDown()
        elseif inputChar == GUI.chars.F12 then ScaleInterfaceUp()
        -- select tab directly
        elseif inputChar == GUI.chars.N1 then RL_SetFocusedTab(TabID.RecentProjects)
        elseif inputChar == GUI.chars.N2 then RL_SetFocusedTab(TabID.ProjectTemplates)
        elseif inputChar == GUI.chars.N3 then RL_SetFocusedTab(TabID.TrackTemplates) 
        elseif inputChar == GUI.chars.N4 then RL_SetFocusedTab(TabID.CustomProjects)
        elseif inputChar == GUI.chars.N5 then RL_SetFocusedTab(TabID.ProjectLists)
        elseif inputChar == GUI.chars.N6 then RL_SetFocusedTab(TabID.Backups)
        elseif inputChar == GUI.chars.N7 then RL_SetFocusedTab(TabID.Docs)
        elseif inputChar == GUI.chars.F2 then RL_SetFocusedTab(TabID.Options)
        elseif inputChar == GUI.chars.F1 then RL_SetFocusedTab(TabID.Help)
        -- context menus
        elseif inputChar == GUI.chars.N0 or inputChar == GUI.chars.M then if currentTab == TabID.RecentProjects then RL_Context_RecentProjects() end
      end
      
      -- audio preview
      if JSAPIinstalled then
        if inputChar == GUI.chars.SPACE or inputChar == GUI.chars.MULTIPLY then AudioPreviewToggleState() end
      end
    end
  end
  reaper.defer(RL_Keys_CheckInput)
end

--------------------
-- Cleanup functions
--------------------
function RL_CleanupAtExit()
  if JSAPIinstalled then AudioPreviewStopAll() end
end

reaper.atexit(function ()
  RL_ExtStates_Save()
  RL_CleanupAtExit()
end)

-------------------
-- Redraw function
------------------
local function RedrawUI()
  RL_SetWindowParameters()
  RL_RedrawAll()
  RL_ExtStates_Load()
  Global_UpdateSubfolderPathDisplayMode()
end

-------------------------
-- Resize/Scale functions
-------------------------
local function ResizeInit(wx, wy)
  gfx.quit()
  gfx.init(GUI.name, GUI.w, GUI.h, 0, wx, wy)
  GUI.redraw_z[0] = true 
end

local function ResizeScaledWidth(wx, wy)
  GUI.w = (RL.minWidth * RL.scaleFactor) - (50 * RL.scaleFactor)
  ResizeInit(wx, wy)
end

local function ResizeScaledHeight(wx, wy)
  GUI.h = ((RL.minHeight - 80) * RL.scaleFactor) + (50 * RL.scaleFactor)
  ResizeInit(wx, wy)
end

local function ResizeWidth(wx, wy)
  GUI.w = RL.minWidth
  ResizeInit(wx, wy)
end

local function ResizeHeight(wx, wy)
  GUI.h = RL.minHeight
  ResizeInit(wx, wy)
end

local function ScaleWindowUp()
  local dock_state, wx, wy, ww, wh = gfx.dock(-1, 0, 0, 0, 0)
  GUI.w, GUI.h = ww, wh
  RedrawUI()

  if RL.scaleFactor > 1 then 
    if GUI.w < (RL.minWidth * RL.scaleFactor) + (50 * RL.scaleFactor) then ResizeScaledWidth(wx, wy) end
    if GUI.h < ((RL.minHeight - 100) * RL.scaleFactor) + (50 * RL.scaleFactor) then ResizeScaledHeight(wx, wy) end
  else
    if GUI.w < RL.minWidth then ResizeWidth(wx, wy) end
    if GUI.h < RL.minHeight then ResizeHeight(wx, wy) end
  end
end

local function ScaleWindowDown()
  local dock_state, wx, wy, ww, wh = gfx.dock(-1, 0, 0, 0, 0)
  GUI.w, GUI.h = ww, wh
  RedrawUI()

  if RL.scaleFactor > 1 then 
    if GUI.w > (RL.minWidth * RL.scaleFactor) + (50 * RL.scaleFactor) then ResizeScaledWidth(wx, wy) end
    if GUI.h > ((RL.minHeight - 100) * RL.scaleFactor) + (50 * RL.scaleFactor) then ResizeScaledHeight(wx, wy) end
  else
    if GUI.w > RL.minWidth then ResizeWidth(wx, wy) end
    if GUI.h > RL.minHeight then ResizeHeight(wx, wy) end
  end
end

function ScaleInterfaceToggle()
    local oldScale = RL.scaleFactor
    RL.fontSizes = { 30, 18, 14, 14, 14, 12 } -- default values
    RL_ExtStates_Save()
    if oldScale < 1.5 then
      RL_InitElementScaling(2.0)
      ScaleWindowUp()
    else
      RL_InitElementScaling(1.0)
      ScaleWindowDown()
    end
  end

function ScaleInterfaceUp()
  if (RL.scaleFactor + RL.scaleStepSize) <= RL.scaleMax then
    RL_InitElementScaling(RL.scaleFactor + RL.scaleStepSize) 
    RL_ExtStates_Save()
    ScaleWindowUp()
  end
end

function ScaleInterfaceDown()
  if (RL.scaleFactor - RL.scaleStepSize) >= RL.scaleMin then
    RL_InitElementScaling(RL.scaleFactor - RL.scaleStepSize)
    RL_ExtStates_Save()
    ScaleWindowDown()
  end
end

------------------
-- Resize function
------------------
GUI.onresize = function()
  RL_ExtStates_Save()
  local dock_state, wx, wy, ww, wh = gfx.dock(-1, 0, 0, 0, 0)
  GUI.w, GUI.h = ww, wh
  RedrawUI()

  -- check minimum window sizw
  if RL.scaleFactor > 1.0 then 
    if GUI.w < ((RL.minWidth - 20) * RL.scaleFactor) - (50 * RL.scaleFactor) then ResizeScaledWidth(wx, wy) end
    if GUI.h < ((RL.minHeight - 80) * RL.scaleFactor) + (50 * RL.scaleFactor) then ResizeScaledHeight(wx, wy) end
  else
    if GUI.w < RL.minWidth then ResizeWidth(wx, wy) end
    if GUI.h < RL.minHeight then ResizeHeight(wx, wy) end
  end
end

-----------------
-- Main functions
-----------------
GUI.Init() 
RL_ExtStates_Load()
RL_Keys_CheckInput()

GUI.func = Main
GUI.freq = 0
GUI.Main()

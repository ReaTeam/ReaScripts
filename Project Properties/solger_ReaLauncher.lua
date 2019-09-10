-- @description ReaLauncher
-- @author solger
-- @version 1.6.2
-- @changelog + Bugfix for handling nil values when saving the output channel the first time to Extstate (saving the first output by default)
-- @screenshot https://forum.cockos.com/showthread.php?t=208697
-- @about
--   # ReaLauncher
--
--   A custom version of the startup prompt window for loading (recent) projects and project/track templates with additional features
--
--   ## Main features
--
--   - Separate tabs for Recent Projects, (.rpp) Project Templates, (.rtracktemplate) Track Templates, (.rpp) Projects, (.rpl) Project Lists and (.rpp-bak) Backups
--   - Option to add additional custom folder paths for Project Templates and Track Templates (which are used in addition to the default template folders)
--   - Option to set custom folder paths for Projects, Project Lists and Backups tabs
--   - List-filter at the top of each tab which supports input of multiple search words separated by a 'space' character
--   - [Show in Explorer/Finder] button for browsing to the folder location of a selected file
--   - Global section with [New Tab], [New Project] and [Open Project] buttons
--   - Option to preview attached 'demo' audio files of project and template files (requires js_ReaScriptAPI)
--   - Selection and loading of multiple entries (multi-select of listbox entries via mouse is already part of Lokasenna's GUI library)
--   - Option to switch between different pre-defined Reaper Theme Slots (requires SWS Extensions)
--   - File paths can be shown/hidden
--   - 'Keep open' checkbox for managing the window auto-close behavior
--   - Resizeable window
--
--   - Uses Lokasenna's GUI library v2 (for LUA) as base: https://forum.cockos.com/showthread.php?t=177772. Big thanks to Lokasenna for his work!!
--
--   ## Discussion thread
--
--   https://forum.cockos.com/showthread.php?t=208697

------------------------------------------------------------------------------------------
local debugEnabled = false -- Set to 'true' in order to show debug messages in the console
------------------------------------------------------------------------------------------
-- String Helper functions
--------------------------
local function MsgDebug(str)
    if debugEnabled then
      reaper.ShowConsoleMsg(tostring(str) .. "\n" )
    end
end

local function MsgError(str)
  reaper.ShowMessageBox(tostring(str), "Error", 0)
end

local function MsgInfo(str)
  reaper.ShowMessageBox(tostring(str),"Info", 0)
end

local function MsgStatusBarClear()
  GUI.Val("main_statusbar", "")
  GUI.elms.main_statusbar:fade(1,1,12)
end

local function MsgStatusBarStatic(message)
  GUI.Val("main_statusbar", "|  " .. message)
end

local function MsgStatusBar(message)
  MsgStatusBarStatic(message)
  GUI.elms.main_statusbar:fade(10,1,12)
end

------------------------------------------
-- Reaper resource paths and version infos
------------------------------------------
appversion = "1.6.2"
appname = "solger_ReaLauncher"

osversion = reaper.GetOS()
local reaperVersionString = reaper.GetAppVersion()
bitversion = string.sub(reaperVersionString, #reaperVersionString - 2, #reaperVersionString)
reaperversion = string.sub(reaperVersionString, 1, #reaperVersionString - (reaperVersionString:reverse()):find("%/"))

reaperIniPath = reaper.get_ini_file()
resourcePath = reaper.GetResourcePath()
if resourcePath == nil then MsgError("Could not retrieve the Reaper resource path!") end

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

-------------------
-- Extensions check
--------------------
-- SWS
function GUI.SWS()
  return reaper.APIExists("BR_Win32_GetPrivateProfileString")
end

-- JS_ReascriptAPI
function GUI.JSAPI()
  local owner
  if osversion:find("Win") and bitversion == "x64" then
    owner = reaper.ReaPack_GetOwner('UserPlugins/reaper_js_ReaScriptAPI64.dll') -- Windows 64-bit
  elseif osversion:find("Win") then
    owner = reaper.ReaPack_GetOwner('UserPlugins/reaper_js_ReaScriptAPI32.dll') -- Windows 32-bit
  elseif osversion:find("OSX") then
    owner = reaper.ReaPack_GetOwner('UserPlugins/reaper_js_ReaScriptAPI64.dylib') -- macOS
  else 
    owner = reaper.ReaPack_GetOwner('UserPlugins/reaper_js_ReaScriptAPI64.so') -- Linux
  end

  if owner then
    local version = ({reaper.ReaPack_GetEntryInfo(owner)})[7]
    reaper.ReaPack_FreeEntry(owner)
    return owner
  end
end

-------------------
-- helper functions
-------------------
-- invert element order
local function InvertElementOrder(arr)
  local e1, e2 = 1, #arr
  while e1 < e2 do
    arr[e1], arr[e2] = arr[e2], arr[e1]
    e1 = e1 + 1
    e2 = e2 - 1
   end
end

-- create a duplicate
local function Duplicate(arr)
  local clone = {}
  local i,v = next(arr, nil)
    while i do
      clone[i] = v
      i,v = next(arr,i)
    end
  return clone
end

-- join tables
local function JoinTables(t1, t2)
  for k,v in ipairs(t2) do table.insert(t1, v) end
  return t1
end

-- check for duplicate values
local function CheckForDuplicates(table, value)
  local found = false
  for i = 1, #table do
    if table[i] == value then
      found = true
    end
  end
  return found
end

-- convert listbox selection values to a table
local function GetSelectionTable(selected)
  if type(selected) == "number" then selected = {[selected] = true} end
  local selectedVals = {}
  for k, v in pairs(selected) do table.insert(selectedVals, k) end
  return selectedVals
end

local function GetTableElementCount(t)
  local count = 0
  for k in pairs(t) do count = count + 1 end
  return count
end

---------------------
-- File I/O functions
---------------------
local FileTypes = {
  bak = ".rpp-bak",
  rpp = ".rpp",
  rpl = ".rpl",
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

----------------------------------------------------------------------------------------
-- Enumerate all (sub-)directories and files of a given path
-- Adapted version of a script found in the Reaper forum. Thanks to mpl and Lokasenna :)
----------------------------------------------------------------------------------------
local function EnumerateFiles(folder)
  local files = {}
  i = 1
  repeat
    files[i] = reaper.EnumerateFiles(folder, i - 1)
    MsgDebug(files[i])
    i = i + 1
  until not retval
  MsgDebug("Enumerate (" .. folder .. ")\n------\n" .. table.concat(files,"\n") .. "\n")
  return files
end

function GetSubDirectories(path)
  local subdirTree = {}
  local subdirIndex, dirIndex = 0, 0
  local subDirChild
  
  if path ~= nil then 
    repeat
      subDirChild = reaper.EnumerateSubdirectories(path, subdirIndex)
        if subDirChild then
          local tmpPath = GetSubDirectories(path .. GetPathSeparator() .. subDirChild)
            for i = 1, #tmpPath do
              table.insert(subdirTree, tmpPath[i])
            end
        end
        subdirIndex = subdirIndex + 1
    until not subDirChild

    repeat
      local fileFound = reaper.EnumerateSubdirectories(path, dirIndex)
        if fileFound then
          subdirTree[#subdirTree + 1] = path .. GetPathSeparator() .. fileFound
        end
        dirIndex = dirIndex + 1
    until not fileFound
  end
  return subdirTree
end

local function GetFiles(path)
  local tree = {}
  local subdirIndex, fileIndex = 0, 0
  local pathChild

  if path ~= nil then 
    repeat
      pathChild = reaper.EnumerateSubdirectories(path, subdirIndex)
        if pathChild then
          local tmpPath = GetFiles(path .. GetPathSeparator() .. pathChild)
            for i = 1, #tmpPath do
              table.insert(tree, tmpPath[i])
            end
        end
        subdirIndex = subdirIndex + 1
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

local function GetFileExtension(filename, charLength)
  return string.lower(string.sub(filename, #filename - charLength, #filename))
end

------------------------------------
-- Get directory from full file path
------------------------------------
local function CheckNilString(str)
  local nStr
  if str == nil then nStr = " " else nStr = str end
  return nStr
end

local function FilterNoCase(s)
  s = string.gsub(s, "%a", function (c)
        return "[" .. string.lower(c) .. string.upper(c) .. "]"
      end)
  return s
end

local function RemoveExtension_RPP(filename)
  return string.sub(filename, 1, #filename - 4)
end

local function RemoveExtension_RPL(filename)
  return string.sub(filename, 1, #filename - 4)
end

local function RemoveExtension_RPP_BAK(filename)
  return string.sub(filename, 1, #filename - 8)
end

local function RemoveExtension_RTrackTemplate(filename)
  return string.sub(filename, 1, #filename - 15)
end

local function RemoveWhiteSpaces(s)
  if s ~= nil then
    return s:match( "^%s*(.-)%s*$" )
  end
end

local function GetDirectoryPath(filepath)
  local index
  if osversion:find("Win") then index = (filepath:reverse()):find("%\\") -- Windows
    else index = (filepath:reverse()):find("%/") -- macOS / Linux
  end
  return string.sub(filepath, 1, #filepath - index)
end

local function GetFilenameWithoutPath(filepath)
  local filename
  if osversion:find("Win") then filename = filepath:match "([^\\]-([^.]+))$" -- Windows: get (filename.extension) substring
    else filename = filepath:match "([^/]-([^.]+))$" -- macOS / Linux: get (filename.extension) substring
  end
  return filename
end

------------------------------------------
-- Open the folder path in Explorer/Finder
------------------------------------------
function ShowLocationInExplorer(path)
  if GUI.SWS() then reaper.CF_ShellExecute(path)
  else
    if osversion:find("OSX") then os.execute('open "" "' .. path .. '"') -- macOS
    elseif osversion:find("Win") then os.execute('start "" "' .. path .. '"') -- Windows
    else os.execute('xdg-open \"' .. path .. '\"') -- Linux
    end
  end
end

---------------------------------------------
-- Show in Explorer/Finder - Helper functions
---------------------------------------------
function ShowLocation_RecentProject()
  if noRecentProjects == false then
  local selectedProject
  local vals = GetSelectionTable(GUI.Val("tab_recentProjects_listbox"))

  if #vals == 0 then MsgStatusBar("No files selected in the list!")
    else
      for p = 1, #vals do
        if FilterActive.RecentProjects == true then selectedProject = RecentProjects.items[RecentProjects.filteredNames[vals[p]]]
        else selectedProject = RecentProjects.items[RecentProjects.names[vals[p]]] end
        ShowLocationInExplorer(GetDirectoryPath(selectedProject))
      end
    end
  end
end

function ShowLocation_ProjectTemplates()
  if noProjectTemplates == false then
    local selectedProjectTemplate
    local vals = GetSelectionTable(GUI.Val("tab_projectTemplates_listbox"))

    if #vals == 0 then ShowLocationInExplorer(projectTemplatePath)
    else
     for p = 1, #vals do
        if FilterActive.ProjectTemplates == true then selectedProjectTemplate = ProjectTemplates.items[ProjectTemplates.filteredNames[vals[p]]]
        else selectedProjectTemplate = ProjectTemplates.items[ProjectTemplates.names[vals[p]]] end
        ShowLocationInExplorer(GetDirectoryPath(selectedProjectTemplate))
      end
    end
    else
      ShowLocationInExplorer(projectTemplatePath)
  end
end

function ShowLocation_TrackTemplates()
  if noTrackTemplates == false then
    local selectedTrackTemplate
    local vals = GetSelectionTable(GUI.Val("tab_trackTemplates_listbox"))

    if #vals == 0 then ShowLocationInExplorer(trackTemplatePath)
    else
      for p = 1, #vals do
        if FilterActive.TrackTemplates == true then selectedTrackTemplate = TrackTemplates.items[TrackTemplates.filteredNames[vals[p]]]
        else selectedTrackTemplate = TrackTemplates.items[TrackTemplates.names[vals[p]]] end
          ShowLocationInExplorer(GetDirectoryPath(selectedTrackTemplate))
        end
     end
   else
    ShowLocationInExplorer(trackTemplatePath)
  end
end

function ShowLocation_CustomProject()
  if noCustomProjects == false then
    local vals = GetSelectionTable(GUI.Val("tab_customProjects_listbox"))
      if #vals == 0 then
        if GUI.Val("options_txtCustomProjectsPath") == "" then MsgStatusBar("No files selected in the list!")
        else
          ShowLocationInExplorer(GUI.Val("options_txtCustomProjectsPath"))
        end
      else
        for p = 1, #vals do
          if FilterActive.CustomProjects == true then selectedProject = CustomProjects.items[CustomProjects.filteredNames[vals[p]]]
          else selectedProject = CustomProjects.items[CustomProjects.names[vals[p]]] end
        ShowLocationInExplorer(GetDirectoryPath(selectedProject))
      end
    end
  end
end

function ShowLocation_ProjectList()
  if noProjectLists == false then
    local vals = GetSelectionTable(GUI.Val("tab_projectLists_listboxProjects"))
    if #vals == 0 then
        if GUI.Val("options_txtProjectsListsPath") == "" then MsgStatusBar("No files selected in the list!")
        else
          ShowLocationInExplorer(GUI.Val("options_txtProjectsListsPath"))
        end
      else
      for p = 1, #vals do
        if FilterActive.ProjectLists then selectedProject = ProjectLists.filteredProjectPaths[vals[p]]
        else selectedProject = ProjectLists.projectPaths[vals[p]] end
        ShowLocationInExplorer(GetDirectoryPath(selectedProject))
      end
    end
  end
end

function ShowLocation_Backups()
  if noBackups == false then
    local vals = GetSelectionTable(GUI.Val("tab_backups_listbox"))
      
    if #vals == 0 then
        if GUI.Val("options_txtBackupsPath") == "" then MsgStatusBar("No files selected in the list!")
        else
          ShowLocationInExplorer(GUI.Val("options_txtBackupsPath"))
        end
      else
      for p = 1, #vals do
        if FilterActive.Backups then selectedProject = Backups.filteredPaths[vals[p]]
        else selectedProject = Backups.paths[vals[p]] end
        ShowLocationInExplorer(GetDirectoryPath(selectedProject))
      end
    end
  end
end

---------------------------
-- Show in Explorer - relay
---------------------------
local function Global_OpenInExplorer()  
  local tabfocus = RL_GetFocusedTab()
  if tabfocus == 1 then ShowLocation_RecentProject() end
  if tabfocus == 2 then ShowLocation_ProjectTemplates() end
  if tabfocus == 3 then ShowLocation_TrackTemplates()  end
  if tabfocus == 4 then ShowLocation_CustomProject() end
  if tabfocus == 5 then ShowLocation_ProjectList() end
  if tabfocus == 6 then ShowLocation_Backups() end
end

--------------------------------------
-- Retrieve key values from reaper.ini 
-----------------------------------------------------------------
-- Slightly adapted version of this script from Carreras Nicolas:
-- https://gist.github.com/bfut/3e738d9b4fc44b746f91999d933ec407
--
-- Reaper forum thread: https://forum.cockos.com/showthread.php?p=1937210
-------------------------------------------------------------------------
local function GetReaperIniKeyValue(key)
  local reaperiniFile = io.open(reaperIniPath,"r")
  for searchLine in reaperiniFile:lines() do
    local searchKey,keyValue = searchLine:match('^([%w|_]+)%s-=%s-(.+)$')
    if searchKey == key then
      reaperiniFile:close()
      return keyValue
     end
   end
  reaperiniFile:close() 
end

---------------------
-- Path Display relay
---------------------
local function Global_TogglePaths()
  if GUI.Val("main_menuPaths") == 1 then GUI.Val("main_menuPaths", 2) 
  else GUI.Val("main_menuPaths", 1) end
  Global_UpdatePathDisplayMode()
end

local function Global_HidePaths()
  GUI.Val("main_menuPaths", {1})
end

function Global_UpdatePathDisplayMode()
  local pathMode = GUI.Val("main_menuPaths")
  if pathMode == 1 then
    -- hide paths
    showFullPaths = false

    if FilterActive.RecentProjects then GUI.elms.tab_recentProjects_listbox.list = RecentProjects.filteredNames
    else GUI.elms.tab_recentProjects_listbox.list = RecentProjects.names end
   
    if FilterActive.ProjectTemplates then  GUI.elms.tab_projectTemplates_listbox.list = ProjectTemplates.filteredNames
    else GUI.elms.tab_projectTemplates_listbox.list = ProjectTemplates.names end

    if FilterActive.TrackTemplates then GUI.elms.tab_trackTemplates_listbox.list = TrackTemplates.filteredNames
    else GUI.elms.tab_trackTemplates_listbox.list = TrackTemplates.names end

    if FilterActive.CustomProjects then GUI.elms.tab_customProjects_listbox.list = CustomProjects.filteredNames
    else GUI.elms.tab_customProjects_listbox.list = CustomProjects.names end

    if FilterActive.ProjectLists then GUI.elms.tab_projectLists_listboxProjects.list = ProjectLists.filteredProjectNames
    else GUI.elms.tab_projectLists_listboxProjects.list = ProjectLists.projectNames end

    if FilterActive.Backups then GUI.elms.tab_backups_listbox.list = Backups.filteredNames
    else GUI.elms.tab_backups_listbox.list = Backups.names end
  else 
    -- show paths
    showFullPaths = true

    if FilterActive.RecentProjects then GUI.elms.tab_recentProjects_listbox.list = RecentProjects.filteredPaths
    else GUI.elms.tab_recentProjects_listbox.list = RecentProjects.paths end
    
    if FilterActive.ProjectTemplates then GUI.elms.tab_projectTemplates_listbox.list = ProjectTemplates.filteredPaths
    else GUI.elms.tab_projectTemplates_listbox.list = ProjectTemplates.paths end

    if FilterActive.TrackTemplates then GUI.elms.tab_trackTemplates_listbox.list = TrackTemplates.filteredPaths
    else GUI.elms.tab_trackTemplates_listbox.list = TrackTemplates.paths end

    if FilterActive.CustomProjects then GUI.elms.tab_customProjects_listbox.list = CustomProjects.filteredPaths
    else GUI.elms.tab_customProjects_listbox.list = CustomProjects.paths end
    
    if FilterActive.ProjectLists then GUI.elms.tab_projectLists_listboxProjects.list = ProjectLists.filteredProjectPaths
    else GUI.elms.tab_projectLists_listboxProjects.list = ProjectLists.projectPaths end

    if FilterActive.Backups then GUI.elms.tab_backups_listbox.list = Backups.filteredPaths
    else GUI.elms.tab_backups_listbox.list = Backups.paths end
  end
  
  GUI.elms.tab_recentProjects_listbox:redraw()
  GUI.elms.tab_projectTemplates_listbox:redraw()
  GUI.elms.tab_trackTemplates_listbox:redraw()
  GUI.elms.tab_customProjects_listbox:redraw()
  GUI.elms.tab_projectLists_listboxProjects:redraw()
  GUI.elms.tab_backups_listbox:redraw()
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

function GetRecentProjectEntryCount()
  local keytag = {}
  local p = 0
  local found = false

  repeat
    p = p + 1
    if p < 10 then keytag[p] = "recent0" .. tostring(p)
    else keytag[p] = "recent" .. tostring(p) end

    if GetReaperIniKeyValue(keytag[p]) == nil then
      found = true
      break
    end
  until (found == true)

  return p
end

function FillRecentProjectsListbox()
  RecentProjects.names = {}
  RecentProjects.items = {}
  RecentProjects.paths = {}
  RecentProjects.check = {}

  local recentpathtag = {}
  local found = false
  local e = 0
  
  local p = GetRecentProjectEntryCount()
  RecentProjects.maxIndex = p - 1
  
  repeat
    p = p - 1
    if p < 10 then recentpathtag[p] = "recent0" .. tostring(p)
    else recentpathtag[p] = "recent" .. tostring(p) end
    
    if GetReaperIniKeyValue(recentpathtag[p]) == nil then
      found = true
      break 
    else
      local fullPath = GetReaperIniKeyValue(recentpathtag[p])
      local filename = GetFilenameWithoutPath(fullPath)

      if CheckForDuplicates(RecentProjects.paths, fullPath) == false and fullPath ~= "removed" then
        e = e + 1    
        RecentProjects.paths[e] = fullPath
        RecentProjects.names[e] = RemoveExtension_RPP(filename)  
      end
    end
  until (found == true)

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

local function FillProjectTemplateSubDirList()
  local subDirList = {'< All Templates >'}
  table.insert(subDirList, projectTemplatePath)
  JoinTables(subDirList, GetSubDirectories(projectTemplatePath))
  table.insert(subDirList, custompathProjectTemplates)
  JoinTables(subDirList, GetSubDirectories(custompathProjectTemplates))
  
  GUI.elms.tab_projectTemplates_subfolders.list = subDirList
  GUI.Val("tab_projectTemplates_subfolders", {1})
end

local function FillProjectTemplateListBoxBase(tempTemplates)
  ProjectTemplates.items = {}
  ProjectTemplates.names = {}
  ProjectTemplates.paths = {}
  noProjectTemplates = false
  local pos = 1

  for i = 1, #tempTemplates do
    local filename = GetFilenameWithoutPath(tempTemplates[i])
    local fileExtension = GetFileExtension(filename, 3)
    
    if string.find(fileExtension, ".rpp") then
      ProjectTemplates.names[pos] = RemoveExtension_RPP(filename)
      ProjectTemplates.items[ProjectTemplates.names[pos]] = tempTemplates[i]
      ProjectTemplates.paths[pos] = tempTemplates[i]
      pos = pos + 1
    end
  end

  Global_UpdatePathDisplayMode()
  GUI.elms.tab_projectTemplates_listbox:redraw()
end

local function FillProjectTemplateListbox()
  -- default project template folder
  local tempTemplates = GetFiles(projectTemplatePath)
  -- custom project template folder
  local tempPath = custompathProjectTemplates
  if #tempPath > 1 then JoinTables(tempTemplates, GetFiles(tempPath)) end

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

local function FillTrackTemplateSubDirList()
  local subDirList = {'< All Templates >'}
  table.insert(subDirList, trackTemplatePath)
  JoinTables(subDirList, GetSubDirectories(trackTemplatePath))
  table.insert(subDirList, customPathTrackTemplates)
  JoinTables(subDirList,  GetSubDirectories(customPathTrackTemplates))

  GUI.elms.tab_trackTemplates_subfolders.list = subDirList
  GUI.Val("tab_trackTemplates_subfolders", {1})
end

local function FillTrackTemplateListboxBase(tempTemplates)
  TrackTemplates.items = {}
  TrackTemplates.names = {}
  TrackTemplates.paths = {}
  noTrackTemplates = false  
  local pos = 1  

  for i = 1 , #tempTemplates do
    local filename = GetFilenameWithoutPath(tempTemplates[i])
    local fileExtension = GetFileExtension(filename, 14)

    if fileExtension == FileTypes.tracktemplate then
      TrackTemplates.names[pos] = RemoveExtension_RTrackTemplate(filename)
      TrackTemplates.items[TrackTemplates.names[pos]] = tempTemplates[i]
      TrackTemplates.paths[pos] = tempTemplates[i]
      pos = pos + 1
    end
  end

  Global_UpdatePathDisplayMode()
  GUI.elms.tab_trackTemplates_listbox:redraw()
end

local function FillTrackTemplateListbox()
  -- default track template folder
  local tempTemplates = GetFiles(trackTemplatePath)
  -- custom track template folder
  local tempPath = customPathTrackTemplates
  if #tempPath > 1 then JoinTables(tempTemplates, GetFiles(tempPath)) end

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

local function FillCustomProjectsSubDirList()
  if #custompathProjects > 1 then 
    local subDirList = {}
    table.insert(subDirList, custompathProjects)
    JoinTables(subDirList, GetSubDirectories(custompathProjects))
    GUI.elms.tab_customProjects_subfolders.list = subDirList
    GUI.Val("tab_customProjects_subfolders", {1})
  end
end

local function FillCustomProjectsListboxBase(dirFiles)
  CustomProjects.items = {}
  CustomProjects.names = {}
  CustomProjects.paths = {}
  local pos = 1

  for i = 1, #dirFiles do
    local filename = GetFilenameWithoutPath(dirFiles[i])
    local fileExtension = GetFileExtension(filename, 3)
    if fileExtension == FileTypes.rpp then
      CustomProjects.names[pos] = RemoveExtension_RPP(filename)
      CustomProjects.items[CustomProjects.names[pos]] = dirFiles[i]
      CustomProjects.paths[pos] = dirFiles[i]
      pos = pos + 1
    end
  end
   if pos > 1 then noCustomProjects = false else noCustomProjects = true end

  Global_UpdatePathDisplayMode()
  GUI.elms.tab_customProjects_listbox:redraw()
end

local function FillCustomProjectsListbox()
  if #custompathProjects > 1 then
    FillCustomProjectsListboxBase(GetFiles(custompathProjects))
  end
end

------------------------
-- Project Lists Listbox
------------------------
ProjectLists = {
  rplFiles = {},
  projectItems = {},
  projectNames = {},
  projectPaths = {},
  filteredProjectNames = {},
  filteredProjectPaths = {}
}

function FillProjectListSelector()
  ProjectLists.projectPaths = {} 
  ProjectLists.projectNames = {}
  ProjectLists.projectItems = {}
  ProjectLists.rplFiles = {}
  rplfolder = custompathProjectLists
  local projectListFiles
  local pos = 1

  if #custompathProjectLists > 1 then
    projectListFiles = GetFiles(rplfolder)
   
    for i = 1, #projectListFiles do
      local filename = GetFilenameWithoutPath(projectListFiles[i])
      local fileExtension = GetFileExtension(filename, 3)
      if fileExtension == FileTypes.rpl then
        ProjectLists.rplFiles[pos] = RemoveExtension_RPL(filename)
        pos = pos + 1
      end
    end
    if pos > 1 then noProjectLists = false else noProjectLists = true end
  end
  
  GUI.elms.tab_projectLists_listboxRPL.list = ProjectLists.rplFiles
  Global_UpdatePathDisplayMode()
end

function ParseRPLFile(selected)
  ProjectLists.projectNames = {}
  ProjectLists.projectPaths = {} 
  ProjectLists.projectItems = {} 

  for i = 1, #selected do
    local rplFile = rplfolder .. "/" .. ProjectLists.rplFiles[selected[i]] .. ".RPL"
    local file = io.open(rplFile, "rb") 
    if not file then return nil end

    for line in file:lines() do
      if #line > 1 then
        table.insert(ProjectLists.projectPaths, line)
      end
    end
    file:close()
  end

  for i = 1, #ProjectLists.projectPaths do
      local filename = RemoveWhiteSpaces(GetFilenameWithoutPath(ProjectLists.projectPaths[i]))
      table.insert(ProjectLists.projectNames, RemoveExtension_RPL(filename))
      ProjectLists.projectItems[ProjectLists.projectNames[i]] = ProjectLists.projectPaths[i]
  end

   GUI.elms.tab_projectLists_listboxProjects.list = ProjectLists.projectNames
end

function FillProjectListBox()
  local vals = GetSelectionTable(GUI.Val("tab_projectLists_listboxRPL"))
  if #GUI.elms.tab_projectLists_listboxRPL.list > 0 then
    ParseRPLFile(vals)
    TabSelectionIndex[5] = 1
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

local function FillBackupsSubDirList()
  local subDirList = {}
  table.insert(subDirList, custompathBackups)
  JoinTables(subDirList, GetSubDirectories(custompathBackups))
  GUI.elms.tab_backups_subfolders.list = subDirList
  GUI.Val("tab_backups_subfolders", {1})
end

local function FillBackupsListboxBase(dirFiles)
  Backups.items = {}
  Backups.names = {}
  Backups.paths = {}
  local pos = 1

  for i = 1, #dirFiles do
    local filename = GetFilenameWithoutPath(dirFiles[i])
    local bakExtension = GetFileExtension(filename, 7)
    if bakExtension == FileTypes.bak then
      Backups.names[pos] = RemoveExtension_RPP_BAK(filename)
      Backups.items[Backups.names[pos]] = dirFiles[i]
      Backups.paths[pos] = dirFiles[i]
      pos = pos + 1
    end
  end

  if pos > 1 then noBackups = false else noBackups = true end
  GUI.elms.tab_backups_listbox.list = Backups.names
  Global_UpdatePathDisplayMode()
end

local function FillBackupsListbox()
  if #custompathBackups > 1 then
    FillBackupsListboxBase(GetFiles(custompathBackups))
  end
end

----------------------------------
-- Fill the listboxes with entries
----------------------------------
function LoadCustomFolderPaths()
  custompathProjectTemplates = reaper.GetExtState(appname, "custompath_projecttemplates") 
  customPathTrackTemplates = reaper.GetExtState(appname, "custompath_tracktemplates")
  custompathProjects = reaper.GetExtState(appname, "custompath_projects")
  custompathProjectLists = reaper.GetExtState(appname, "custompath_projectlists")
  custompathBackups = reaper.GetExtState(appname, "custompath_backups")
end

LoadCustomFolderPaths()

-----------------------------------
-- New project/tab button functions
-----------------------------------
local function Global_CheckWindowPinState()
  if GUI.Val("main_checklist_windowpin") == false then gfx.quit() end
end

local function Global_ToggleWindowPinState()
  if GUI.Val("main_checklist_windowpin") == true then GUI.Val("main_checklist_windowpin", {false}) 
  else GUI.Val("main_checklist_windowpin", {true}) end
end

local function Global_NewProject()
  reaper.Main_OnCommand(40023, 0)
  Global_CheckWindowPinState() 
end

local function Global_NewTab()
  reaper.Main_OnCommand(40859, 0)
  Global_CheckWindowPinState() 
end

local function Global_NewTabIgnoreTemplate()
  reaper.Main_OnCommand(41929, 0)
  Global_CheckWindowPinState()
end

local function Global_CurrentTabClose()
  reaper.Main_OnCommand(40860, 0)
  Global_CheckWindowPinState()
end

local function Global_ProjectTabPrev()
  reaper.Main_OnCommand(40862, 0)
end

local function Global_ProjectTabNext()
  reaper.Main_OnCommand(40861, 0)
end

local function Global_ShowProjectOpenDialog()
  reaper.Main_OnCommand(40025, 0)
  Global_CheckWindowPinState()
end

local function Global_ProjectLoad(project, projectCount)
  if project ~= nil then 
    if projectCount > 1 then reaper.Main_OnCommand(40859, 0) end -- load in tab
    reaper.Main_openProject(project) 
    RL_CleanupAtExit()
  end
end

local function Global_ProjectLoadInTab(project)
  if project ~= nil then 
    reaper.Main_OnCommand(40859, 0)
    reaper.Main_openProject(project) 
    RL_CleanupAtExit()
  end
end

local function Global_Load(tabmode, selectedFile, fileCount)
  if tabmode == true then Global_ProjectLoadInTab(selectedFile)
  else Global_ProjectLoad(selectedFile, fileCount) end
end

local function ProjectTemplate_ShowSaveAsDialog()
  if projectTemplateLoadMode == 1 then 
    reaper.Main_OnCommand(40022,0) -- Save project as dialog
  end
end

local function Global_ProjectTemplateLoadBase(template)
  if template ~= nil then
    if reaperversion ~= nil and #reaperversion > 1 and tonumber(string.sub(reaperversion, 1, 5)) > 5.982 then
      -- logic for Reaper versions 5.983 or  higher
      if projectTemplateLoadMode == 1 then 
        reaper.Main_openProject("template:" .. template)   
      else
        reaper.Main_openProject(template)
      end
    else
      -- logic for Reaper versions older than 5.983
      reaper.Main_openProject(template) 
      ProjectTemplate_ShowSaveAsDialog()
    end
    RL_CleanupAtExit()
  end
end

local function Global_ProjectTemplateLoad(template, templateCount)
  if templateCount > 1 then reaper.Main_OnCommand(40859, 0) end -- load in tab
  Global_ProjectTemplateLoadBase(template)
end

local function Global_ProjectProjectTemplateLoadInTab(template)
  reaper.Main_OnCommand(40859, 0)
  Global_ProjectTemplateLoadBase(template)
end

----------------------------------
-- Recent project button functions
----------------------------------
local function Load_RecentProject_Base(tabmode)
  if noRecentProjects == false then
    local vals = GetSelectionTable(GUI.Val("tab_recentProjects_listbox"))
    for p = 1, #vals do
      if FilterActive.RecentProjects == true then selectedProject = RecentProjects.items[RecentProjects.filteredNames[vals[p]]]
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
  if noCustomProjects == false then 
    local vals = GetSelectionTable(GUI.Val("tab_customProjects_listbox"))
    for p = 1, #vals do
      if FilterActive.CustomProjects == true then selectedProject = CustomProjects.items[CustomProjects.filteredNames[vals[p]]]
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

local  function LoadInTab_CustomProject()
  Load_CustomProject_Base(true)
end

---------------------------
-- Project Template buttons
---------------------------
local function Load_ProjectTemplate_Base(tabmode)
  if noProjectTemplates == false then
    local vals = GetSelectionTable(GUI.Val("tab_projectTemplates_listbox"))
    for p = 1, #vals do 
      if FilterActive.ProjectTemplates == true then selectedProjectTemplate = ProjectTemplates.items[ProjectTemplates.filteredNames[vals[p]]]
      else selectedProjectTemplate =  ProjectTemplates.items[ProjectTemplates.names[vals[p]]] end

      if tabmode == true then Global_ProjectProjectTemplateLoadInTab(selectedProjectTemplate)
      else Global_ProjectTemplateLoad(selectedProjectTemplate, p) end
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
  if noTrackTemplates == false then
    local selectedTrackTemplate
    local vals = GetSelectionTable(GUI.Val("tab_trackTemplates_listbox"))
    for p = 1, #vals do
      if FilterActive.TrackTemplates == true then selectedTrackTemplate = TrackTemplates.items[TrackTemplates.filteredNames[vals[p]]]
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
  if noProjectLists == false then
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
  if noBackups == false then
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

--------------------------
-- Filter update functions
--------------------------
local function UpdateListFilter_RecentProjects()
  if FilterActive.RecentProjects then
    GUI.elms.tab_recentProjects_listbox.list = RecentProjects.filteredNames
  else
    GUI.elms.tab_recentProjects_listbox.list = RecentProjects.names
  end
end

local function UpdateListFilter_ProjectTemplates()
  if FilterActive.ProjectTemplates then
    GUI.elms.tab_projectTemplates_listbox.list = ProjectTemplates.filteredNames
  else
    GUI.elms.tab_projectTemplates_listbox.list = ProjectTemplates.names 
  end
end

local function UpdateListFilter_TrackTemplates()
  if FilterActive.TrackTemplates then
    GUI.elms.tab_trackTemplates_listbox.list = TrackTemplates.filteredNames
  else
    GUI.elms.tab_trackTemplates_listbox.list = TrackTemplates.names
  end
end

local function UpdateListFilter_CustomProjects()
  if FilterActive.CustomProjects then
    GUI.elms.tab_customProjects_listbox.list = CustomProjects.filteredNames
  else
    GUI.elms.tab_customProjects_listbox.list = CustomProjects.names
  end
end

local function UpdateListFilter_ProjectLists()
  if FilterActive.ProjectLists then
    GUI.elms.tab_projectLists_listboxProjects.list = ProjectLists.filteredProjectNames
  else
    GUI.elms.tab_projectLists_listboxProjects.list = ProjectLists.projectNames
  end
end

local function UpdateListFilter_Backups()
  if FilterActive.Backups then
    GUI.elms.tab_backups_listbox.list = Backups.filteredNames
  else
    GUI.elms.tab_backups_listbox.list = Backups.names
  end
end


local function UpdateListFilter_All()
  UpdateListFilter_RecentProjects()
  UpdateListFilter_ProjectTemplates()
  UpdateListFilter_TrackTemplates()
  UpdateListFilter_CustomProjects()
  UpdateListFilter_ProjectLists()
  UpdateListFilter_Backups()
  Global_HidePaths()
end

-------------------
-- Filter functions
-------------------
FilterActive = {
  RecentProjects = false,
  TrackTemplates = false,
  ProjectTemplates = false,
  CustomProjects = false,
  ProjectLists = false,
  Backups = false,
}

local separatorComma = "[^,]+"
local separatorSpace = "[^%s]+"

function GetSearchTable(searchString)
  searchTable = {}
  for match in string.gmatch(searchString, separatorSpace) do
      table.insert(searchTable, FilterNoCase(match))
  end
  return searchTable
end

local function Filter_RecentProject_Apply()
  RecentProjects.filteredNames = {}
  RecentProjects.filteredPaths = {}
  local searchStr = GUI.Val("tab_recentProjects_txtFilter")
  if #searchStr > 0 then
    FilterActive.RecentProjects = true
    searchterms = GetSearchTable(searchStr)

    for t = 1, #searchterms do
        for i = 1, #RecentProjects.names do
        if string.find(RecentProjects.names[i], searchterms[t]) then
          RecentProjects.filteredNames[RecentProjects.names[i]] = RecentProjects.paths[i]

          if CheckForDuplicates(RecentProjects.filteredNames, RecentProjects.names[i]) == false then
            table.insert(RecentProjects.filteredNames, RecentProjects.names[i])
            table.insert(RecentProjects.filteredPaths, RecentProjects.items[RecentProjects.names[i]])
          end
        end
      end
    end
  else
    FilterActive.RecentProjects = false
    Global_UpdatePathDisplayMode()
  end

  UpdateListFilter_RecentProjects()
  GUI.Val("tab_recentProjects_listbox",{})
  ScrollToTop(1)
  Global_HidePaths()
end

local function Filter_ProjectTemplate_Apply()
  ProjectTemplates.filteredNames = {}
  ProjectTemplates.filteredPaths = {}

  local searchStr = GUI.Val("tab_projectTemplates_txtFilter")
  if #searchStr > 0 then
    FilterActive.ProjectTemplates = true
    searchterms = GetSearchTable(searchStr)

    for t = 1, #searchterms do
      for i = 1, #ProjectTemplates.names do
        if string.find(ProjectTemplates.names[i], searchterms[t]) then
          ProjectTemplates.filteredNames[ProjectTemplates.names[i]] = ProjectTemplates.names[i]
          if CheckForDuplicates(ProjectTemplates.filteredNames, ProjectTemplates.names[i]) == false then
            table.insert(ProjectTemplates.filteredNames, ProjectTemplates.names[i])
            table.insert(ProjectTemplates.filteredPaths, ProjectTemplates.items[ProjectTemplates.names[i]])
          end
        end  
      end
    end
  else 
    FilterActive.ProjectTemplates = false
  end

  UpdateListFilter_ProjectTemplates()
  GUI.Val("tab_projectTemplates_listbox",{})
  ScrollToTop(2)
  Global_HidePaths()
end

local function Filter_TrackTemplate_Apply()
  TrackTemplates.filteredNames = {}
  TrackTemplates.filteredPaths = {}
  
  local searchStr = GUI.Val("tab_trackTemplates_txtFilter")
  if #searchStr > 0 then
    FilterActive.TrackTemplates = true
    searchterms = GetSearchTable(searchStr)
  
    for t = 1, #searchterms do
      for i = 1, #TrackTemplates.names do
        if string.find(TrackTemplates.names[i], searchterms[t]) then
          TrackTemplates.filteredNames[TrackTemplates.names[i]] = TrackTemplates.names[i]
          if CheckForDuplicates(TrackTemplates.filteredNames, TrackTemplates.names[i]) == false then
            table.insert(TrackTemplates.filteredNames, TrackTemplates.names[i])
            table.insert(TrackTemplates.filteredPaths, TrackTemplates.items[TrackTemplates.names[i]])
          end
        end
      end
    end
    else
      FilterActive.TrackTemplates = false
      Global_UpdatePathDisplayMode()
    end
  
  UpdateListFilter_TrackTemplates()
  GUI.Val("tab_trackTemplates_listbox",{})
  ScrollToTop(3)
  Global_HidePaths()
end

local function Filter_CustomProjects_Apply()
  CustomProjects.filteredNames = {}
  CustomProjects.filteredPaths = {}
  
  local searchStr = GUI.Val("tab_customProjects_txtFilter")
  if #searchStr > 0 then
    FilterActive.CustomProjects = true
    searchterms = GetSearchTable(searchStr)

    for t = 1, #searchterms do
      for i = 1, #CustomProjects.names do
        if string.find(CustomProjects.names[i], searchterms[t]) then
          CustomProjects.filteredNames[CustomProjects.names[i]] = CustomProjects.names[i]
          if CheckForDuplicates(CustomProjects.filteredNames, CustomProjects.names[i]) == false then
            table.insert(CustomProjects.filteredNames, CustomProjects.names[i])
            table.insert(CustomProjects.filteredPaths, CustomProjects.items[CustomProjects.names[i]])
          end
        end
      end
    end
  else
    FilterActive.CustomProjects = false
    Global_UpdatePathDisplayMode()
  end

  UpdateListFilter_CustomProjects()
  GUI.Val("tab_customProjects_listbox",{})
  ScrollToTop(4)
  Global_HidePaths()
end

local function Filter_ProjectLists_Apply()
  ProjectLists.filteredProjectNames = {}
  ProjectLists.filteredProjectPaths = {}
  
  local searchStr = GUI.Val("tab_projectLists_txtFilter")
  
  if #searchStr > 0 then
    FilterActive.ProjectLists = true
    searchterms = GetSearchTable(searchStr)

    for t = 1, #searchterms do
      for i = 1, #ProjectLists.projectNames do
        if string.find(ProjectLists.projectNames[i], searchterms[t]) then
          ProjectLists.filteredProjectNames[ProjectLists.projectNames[i]] = ProjectLists.projectNames[i]
          if CheckForDuplicates(ProjectLists.filteredProjectNames, ProjectLists.projectNames[i]) == false then
            table.insert(ProjectLists.filteredProjectNames, ProjectLists.projectNames[i])
            table.insert(ProjectLists.filteredProjectPaths, ProjectLists.projectItems[ProjectLists.projectNames[i]])
          end
        end
      end
    end
  else
    FilterActive.ProjectLists = false
    Global_UpdatePathDisplayMode()
  end

  UpdateListFilter_ProjectLists()
  GUI.Val("tab_projectLists_listboxProjects",{})
  ScrollToTop(5)
  Global_HidePaths()
end

local function Filter_Backups_Apply()
  Backups.filteredNames = {}
  Backups.filteredPaths = {}
  
  local searchStr = GUI.Val("tab_backups_txtFilter")
  if #searchStr > 0 then
    FilterActive.Backups = true
    searchterms = GetSearchTable(searchStr)
  
    for t = 1, #searchterms do
      for i = 1, #Backups.names do
        if string.find(Backups.names[i], searchterms[t]) then
          Backups.filteredNames[Backups.names[i]] = Backups.names[i]
          if CheckForDuplicates(Backups.filteredNames, Backups.names[i]) == false then
            table.insert(Backups.filteredNames, Backups.names[i])
            table.insert(Backups.filteredPaths, Backups.items[Backups.names[i]])
          end
        end
      end
    end
    else
      FilterActive.Backups = false
      Global_UpdatePathDisplayMode()
    end
  
  UpdateListFilter_Backups()
  GUI.Val("tab_backups_listbox",{})
  ScrollToTop(6)
  Global_HidePaths()
end

----------------------------
-- Refresh Listbox functions
----------------------------
local function RefreshRecentProjects()
  MsgDebug("Refresh Recent Projects")
  FillRecentProjectsListbox()
end

local function RefreshProjectTemplates()
  MsgDebug("Refresh Project Templates")
  FillProjectTemplateSubDirList()
  FillProjectTemplateListbox()
end

local function RefreshTrackTemplates()
  MsgDebug("Refresh Track Templates")
  FillTrackTemplateSubDirList()
  FillTrackTemplateListbox()
end

local function RefreshCustomProjects()
  MsgDebug("Refresh Custom Projects")
  FillCustomProjectsSubDirList()
  FillCustomProjectsListbox()
end

function RefreshProjectList()
  MsgDebug("Refresh Project Lists")
  FillProjectListSelector()
end

function RefreshBackups()
  MsgDebug("Refresh Backups")
  FillBackupsSubDirList()
  FillBackupsListbox()
end

---------------------
-- Clear custom paths
----------------------
function Path_Clear_ProjectTemplateFolder()
  ProjectTemplates.items = {}
  ProjectTemplates.names = {}
  ProjectTemplates.paths = {}
  ProjectTemplates.filteredNames = {}
  ProjectTemplates.pfilteredPathsaths = {}

  GUI.Val("options_txtProjectTemplatesPath","")
  GUI.elms.tab_projectTemplates_listbox.list = {}
  
  reaper.DeleteExtState(appname, "custompath_projecttemplates",1)
  RefreshProjectTemplates()
  MsgStatusBar("Additional Project Template folder removed")
end

function Path_Clear_TrackTemplateFolder()
  TrackTemplates.items = {}
  TrackTemplates.names = {}
  TrackTemplates.paths = {}
  TrackTemplates.filteredNames = {}
  TrackTemplates.pfilteredPathsaths = {}

  GUI.Val("options_txtTrackTemplatesPath","")
  GUI.elms.tab_trackTemplates_listbox.list = {}
  
  reaper.DeleteExtState(appname, "custompath_tracktemplates",1)
  RefreshTrackTemplates()
  MsgStatusBar("Additional Track Template folder removed")
end

function Path_Clear_CustomProjectFolder()
  custompathProjects = {}
  CustomProjects.items = {}
  CustomProjects.names = {}
  CustomProjects.paths = {}
  CustomProjects.filteredNames = {}
  CustomProjects.filteredPaths = {}
  
  GUI.Val("options_txtCustomProjectsPath","")
  GUI.elms.tab_customProjects_listbox.list = {}

  reaper.DeleteExtState(appname, "custompath_projects",1)
  MsgStatusBar("Custom Projects folder removed")
  RefreshCustomProjects()
end

function Path_Clear_ProjectListFolder()
  ProjectLists.rplFiles = {}
  ProjectLists.projectItems = {}
  ProjectLists.projectNames = {}
  ProjectLists.projectPaths = {}
  ProjectLists.filteredProjectNames = {}

  GUI.Val("options_txtProjectsListsPath","")
  GUI.elms.tab_projectLists_listboxRPL.list = {}
  GUI.elms.tab_projectLists_listboxProjects.list = {}

  reaper.DeleteExtState(appname, "custompath_projectlists",1)
  MsgStatusBar("Project Lists folder removed")
  RefreshProjectList()
end

function Path_Clear_BackupsFolder()
  Backups.items = {}
  Backups.names = {}
  Backups.paths = {}
  Backups.filteredNames = {}
  Backups.filteredPaths = {}
  
  GUI.Val("options_txtBackupsPath", "")
  GUI.elms.tab_backups_listbox.list = {}

  reaper.DeleteExtState(appname, "custompath_backups", 1)
  MsgStatusBar("Backups folder removed")
  RefreshBackups()
end

-------------------
-- Set custom paths
-------------------
function Path_Set_ProjectTemplateFolder()
  local custompath_projectTemplates = GUI.Val("options_txtProjectTemplatesPath")
  if custompath_projectTemplates == "" then
    MsgStatusBar("Please enter a custom [ Project Templates ] folder path first!")
  else
    reaper.SetExtState(appname, "custompath_projecttemplates", custompath_projectTemplates, 1)
    RefreshProjectTemplates()
    MsgStatusBar("Additional Project Template folder set to " .. custompath_projectTemplates)
  end
end

function Path_Set_TrackTemplateFolder()
  local customPathTrackTemplates = GUI.Val("options_txtTrackTemplatesPath")
  if customPathTrackTemplates == "" then
    MsgStatusBar("Please enter a custom [ Track Templates ] folder path first!")
  else
    reaper.SetExtState(appname, "custompath_tracktemplates", customPathTrackTemplates, 1)
    RefreshTrackTemplates()
    MsgStatusBar("Additional Track Templates folder set to " .. customPathTrackTemplates)
  end
end

function Path_Set_CustomProjectFolder()
  local custompath_customprojects = GUI.Val("options_txtCustomProjectsPath")
  if custompath_customprojects == "" then 
    MsgStatusBar("Please enter a custom [ Projects ] folder path first!")
  else
    reaper.SetExtState(appname, "custompath_projects", custompath_customprojects, 1)
    RefreshCustomProjects()
    MsgStatusBar("Custom Projects folder set to " .. custompath_customprojects)
  end
end

function Path_Set_ProjectListFolder()
  local custompathProjectLists = GUI.Val("options_txtProjectsListsPath")
  if custompathProjectLists == "" then
    MsgStatusBar("Please enter a custom [ Project List ] folder path first!")
  else
    reaper.SetExtState(appname, "custompath_projectlists", custompathProjectLists, 1)
    RefreshProjectList()
    MsgStatusBar("Project Lists folder set to " .. custompathProjectLists)
  end
end

function Path_Set_BackupsFolder()
  local custompathBackups = GUI.Val("options_txtBackupsPath")
  if custompathBackups == "" then
    MsgStatusBar("Please enter a custom [ Backups ] folder path first!")
  else
    reaper.SetExtState(appname, "custompath_backups", custompathBackups, 1)
    RefreshBackups()
    MsgStatusBar("Backups folder set to " .. custompathBackups)
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
  Backups = 8,
  Options = 9,
  Help = 10,
  DialogContent = 20,
  DialogWindow = 21
}

-----------------------
-- Theme slot functions
-----------------------
if GUI.SWS() then

  local ThemeSlots = {
    maxCount = 5,
    items = "----,1,2,3,4,5"
  }

  -- open the SWS Resource window
  function ThemeSlot_Setup()
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_SHOW_RESVIEW_THEME"), 0)
  end

  -- load a Theme from the given slot number
  function ThemeSlot_Load()
    themeslot = GUI.Val("themeslot")
    if themeslot < 5 then reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_LOAD_THEME" .. themeslot - 1), 0)
    else reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_LOAD_THEMEl"), 0) end 
  end

  -- draw the UI element
  function RL_Draw_ThemeSlotSelector(alignment)
    GUI.New("themeslot", "Menubox", LayerIndex.Global, btn_pad_left + 90, btn_pad_top + 190, 50, 20, "Reaper Theme:", ThemeSlot_GetItems())
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

  function ThemeSlot_GetNames()
    local themeSlotNames = {}

    if GUI.Val("options_themeslot_number") == nil then ThemeSlots.maxCount = 5
    else ThemeSlots.maxCount = GUI.Val("options_themeslot_number") end
    for i = 1, ThemeSlots.maxCount do themeSlotNames[i] = CheckNilString(GUI.Val("options_themeslot_" .. i)) end
    
    ThemeSlots.items = "----"
    for t = 1, ThemeSlots.maxCount do ThemeSlots.items = ThemeSlots.items  .. ",  " .. t .. "   " .. themeSlotNames[t] end
    
    local themeSlotAliases = themeSlotNames[1]
    for t = 2, ThemeSlots.maxCount do themeSlotAliases = themeSlotAliases .. "," .. themeSlotNames[t] end
    
    return themeSlotAliases
  end

  function ThemeSlot_LoadNames()
    ThemeSlot_GetNames()
    RL_Draw_ThemeSlotSelector("0")
  end

  function ThemeSlot_SaveNames()
    local aliases = ThemeSlot_GetNames()
    reaper.SetExtState(appname, "themeslot_aliases", aliases, 1)
    RL_Draw_ThemeSlotSelector("0")
    MsgStatusBar("Theme Slot Descriptions saved")
  end

  function ThemeSlot_Indicator()
    local selected = tonumber(reaper.GetExtState(appname, "themeslot_max"))
    if selected == nil then selected = 5
    else GUI.Val("options_themeslot_number", selected) end

    for i = 1, 5 do ThemeSlotTextBoxes[i].color = "none" end 
    for i = 1, selected do ThemeSlotTextBoxes[i].color = "white" end
  end

  function RL_Draw_ThemeSlotOptions()
    local themeslot_pad_left = 85
    local themeslot_pad_top = 300

    GUI.New("options_themeslot_number", "Menubox", LayerIndex.Options, themeslot_pad_left + 140, themeslot_pad_top, 38, 20, "Theme Slot Descriptions", "1,2,3,4,5")
    GUI.elms.options_themeslot_number.align = 1

    for i = 1, ThemeSlots.maxCount do
      GUI.New("options_themeslot_" .. i, "Textbox", LayerIndex.Options, themeslot_pad_left, themeslot_pad_top + 25 + (20 * (i -1)), 180, 20, i, 8)
    end

    ThemeSlotTextBoxes = { GUI.elms.options_themeslot_1, GUI.elms.options_themeslot_2,  GUI.elms.options_themeslot_3, GUI.elms.options_themeslot_4, GUI.elms.options_themeslot_5 }
    ThemeSlot_Indicator()
    
    GUI.New("options_themeslot_Setup", "Button", LayerIndex.Options, themeslot_pad_left, themeslot_pad_top + 130, 100, 20, "Edit Theme Slots", ThemeSlot_Setup)
    GUI.New("options_themeslot_Save", "Button", LayerIndex.Options, themeslot_pad_left + 114, themeslot_pad_top + 130, 65, 20, "Save", ThemeSlot_SaveNames)

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
      local tSlots = GUI.elms["options_themeslot_"..i]
      function tSlots:onmousedown()
        GUI.Textbox.onmousedown(self)
        IsKeyInputCheckActive = false
      end
    end

  end

  function ThemeSlot_GetItems()
    return ThemeSlots.items
  end

end

-----------------------------
-- Recent Projects management 
-----------------------------
function RecentProjects_RemoveEntry()
  local vals = GetSelectionTable(GUI.Val("tab_recentProjects_listbox"))
  for i = 1, #vals do
    local selectedProject = RecentProjects.items[RecentProjects.names[vals[i]]]
    local found = false
    local recentpathtag = {}
    local removedEntries = {}
    local p = 0

    repeat
      p = p + 1
      if p < 10 then recentpathtag[p] = "recent0" .. tostring(p)
      else recentpathtag[p] = "recent" .. tostring(p) end
      
      if GetReaperIniKeyValue(recentpathtag[p]) == nil then
          found = true
          break
      else
        local keyValue = GetReaperIniKeyValue(recentpathtag[p])
        if keyValue == selectedProject then
          table.insert(removedEntries, recentpathtag[p])
          reaper.BR_Win32_WritePrivateProfileString("Recent", recentpathtag[p], "removed", reaper.get_ini_file())
          MsgDebug("removed entry: " .. recentpathtag[p])
        end
      end
    until (found == true)
  end
  GUI.Val("tab_recentProjects_listbox", {})
  RefreshRecentProjects()
end

function RecentProjects_ClearList()
  local keyName
    for k = 1, RecentProjects.maxIndex do
      if k < 10 then keyName = "recent0" .. tostring(k)
      else keyName = "recent" .. tostring(k) end
      reaper.BR_Win32_WritePrivateProfileString("Recent", keyName, "", reaper.get_ini_file())
    end
    RefreshRecentProjects()
end

------------------
-- Window settings
------------------
GUI.name = "ReaLauncher"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 720, 470
GUI.anchor, GUI.corner = "mouse", "C" -- Center on "mouse" or "screen"
GUI.load_window_state(appname)

function RL_SetWindowParameters()
  -- button size
  btn_w = 150
  btn_h = 28

  -- global element indents
  pad_left = 10
  pad_top = 30

  -- listbox size
  listbox_top = 58
  listbox_w = GUI.w - 180
  listbox_h = GUI.h - 85

  -- button indents
  btn_pad_left = listbox_w + 18
  btn_pad_top = 140
  btn_pad_add = 35
  btn_tab_top = 252
end

RL_SetWindowParameters()

SelectionIndex = {
  RecentProjects = 1,
  ProjectTemplates = 1,
  TrackTemplates = 1,
  CustomProjects = 1,
  ProjectListsProjects = 1,
  Backups = 1
}

ParentSelectionIndex = {
  RecentProjects = 1,
  ProjectTemplates = 1,
  TrackTemplates = 1,
  CustomProjects = 1,
  ProjectListsProjects = 1,
  Backups = 1
}

--------------------
-- Main GUI Elements
--------------------
MainTabs = {
  "Recent Projects",
  "Project Templates",
  "Track Templates",
  "Projects",
  "Project Lists",
  "Backups",
  "Options",
  "Help"
}

TabParentSelectionIndex = {
  ParentSelectionIndex.RecentProjects,
  ParentSelectionIndex.ProjectTemplates,
  ParentSelectionIndex.TrackTemplates,
  ParentSelectionIndex.CustomProjects,
  ParentSelectionIndex.ProjectListsProjects,
  ParentSelectionIndex.Backups
}

TabSelectionIndex = {
  SelectionIndex.RecentProjects,
  SelectionIndex.ProjectTemplates,
  SelectionIndex.TrackTemplates,
  SelectionIndex.CustomProjects,
  SelectionIndex.ProjectListsProjects,
  SelectionIndex.Backups
}

function RL_GetFocusedTab()
  return GUI.elms.main_tabs.state
end

function RL_SetFocusedTab(tabIndex)
  GUI.Val("main_tabs", tabIndex)
  if RL_GetFocusedTab() < (#MainTabs - 1) then RL_Func_TabRefresh[RL_GetFocusedTab()].call() end
end

local audioPreviewActive = false
local audioPreviewChannel = 0

function RL_Draw_PreviewSection()
  if GUI.JSAPI() then
    GUI.New("main_previewVolKnob", "Knob", LayerIndex.Global, GUI.w - 155, pad_top, 20, "Volume", 0, 100, 50, 1)
    GUI.elms.main_previewVolKnob.cap_x = 26
    GUI.elms.main_previewVolKnob.cap_y = -26
    GUI.elms.main_previewVolKnob.vals = false
    GUI.elms.main_previewVolKnob.tooltip =  "Audio preview section\n\n" ..
                                            "- Output channel can be set in the [Options] Tab\n" ..                                        
                                            "- Turning the knob sets the preview volume (0-100%)\n" ..
                                            "- DOUBLE CLICK on the knob starts/stops the preview\n\n" ..
                                            "Knob color states:\nSILVER: preview available for the selected entry\nGREEN: preview playing"

    local pos = 1
    local stereoChannels = {}
    for c = 1, reaper.GetNumAudioOutputs(), 2 do
      stereoChannels[pos] = c .. "/" .. c + 1
      pos = pos + 1
    end

    GUI.New("main_previewChannels", "Menubox", LayerIndex.Options, GUI.w - 85, pad_top, 65, 20, "Preview ch", table.concat(stereoChannels, ","))
    GUI.elms.main_previewChannels.align = "1"
    GUI.elms.main_previewChannels.tooltip = "Select which channel is used for audio preview"

    local function SetPreviewChannel(channel)
      audioPreviewChannel = tonumber(string.sub(channel, 1, #channel - channel:find("/"))) - 1
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
      if audioPreviewActive == false then self.caption = self.retval end
    end
  
    function GUI.elms.main_previewVolKnob:ondoubleclick()
      AudioPreviewToggleState()
    end
  
    GUI.elms.main_previewVolKnob:redraw()
  end
end

function RL_Draw_Main()
  -- main layer
  GUI.New("main_tabs", "Tabs", LayerIndex.Main, 0, 0, 100, 20, MainTabs, 16)
  GUI.elms.main_tabs.col_tab_b = "elm_bg"
  GUI.New("main_appversion", "Label", LayerIndex.Main, pad_left, GUI.h - 18, "ReaLauncher " .. appversion, false, 4)
  GUI.New("main_statusbar", "Label", LayerIndex.Main, pad_left + 95, GUI.h - 18, "", false, 4)

  -- Tab | Layers
   GUI.elms.main_tabs:update_sets(
     { [1] = {LayerIndex.Global, LayerIndex.RecentProjects},
       [2] = {LayerIndex.Global, LayerIndex.ProjectTemplates},
       [3] = {LayerIndex.Global, LayerIndex.TrackTemplates},
       [4] = {LayerIndex.Global, LayerIndex.CustomProjects},
       [5] = {LayerIndex.Global, LayerIndex.ProjectLists},
       [6] = {LayerIndex.Global, LayerIndex.Backups},
       [7] = {LayerIndex.Options},
       [8] = {LayerIndex.Help}
     }
   )

  function GUI.elms.main_tabs:onmousedown()
    GUI.Tabs.onmousedown(self)
    if RL_GetFocusedTab() < (#MainTabs - 1) then RL_Func_TabRefresh[RL_GetFocusedTab()].call() end
  end

  -- global layer
  GUI.New("main_menuPaths", "Menubox", LayerIndex.Global, 380, pad_top, 60, 20, "Paths", "Hide,Show")
  GUI.elms.main_menuPaths.align = "1"

  GUI.New("main_btnOpenInExplorer", "Button", LayerIndex.Global, btn_pad_left, 64, btn_w, btn_h, "Show in Explorer/Finder", Global_OpenInExplorer)
  GUI.New("main_button_openProject", "Button", LayerIndex.Global, btn_pad_left, 98, btn_w, btn_h, "Open Project", Global_ShowProjectOpenDialog) 

  GUI.New("main_btnNewProject", "Button", LayerIndex.Global, btn_pad_left, btn_pad_top, btn_w, btn_h, "New Project", Global_NewProject) 
  GUI.New("main_btnNewProjectTab", "Button", LayerIndex.Global, btn_pad_left, btn_pad_top + btn_pad_add, btn_w, btn_h, "New Tab", Global_NewTab) 
  GUI.New("main_btnNewTabIgnoreTemplate", "Button", LayerIndex.Global, btn_pad_left, btn_pad_top + 2 * btn_pad_add, btn_w, btn_h, "New Tab Ignore Template", Global_NewTabIgnoreTemplate)
  
  GUI.New("main_label_windowpin", "Label", LayerIndex.Global, GUI.w - 94, 32, "Keep open", false, 3)
  GUI.New("main_checklist_windowpin", "Checklist", LayerIndex.Global, GUI.w - 32, 30, 20, 20, "", "", "h", 0)
 
  function GUI.elms.main_menuPaths:onmousedown()
    GUI.Menubox.onmouseup(self)
    Global_UpdatePathDisplayMode()
  end
  
  function GUI.elms.main_menuPaths:onwheel()
    GUI.Menubox.onwheel(self)
    Global_UpdatePathDisplayMode()
  end
  
  if GUI.SWS() then RL_Draw_ThemeSlotSelector("1") end
  if GUI.JSAPI() then RL_Draw_PreviewSection() end
end

function RL_Draw_Frames()
  local framewidth = 2
  GUI.New("main_frame_top", "Frame", LayerIndex.Global, 0, 56, GUI.w, framewidth, true, true)
  GUI.New("main_frame_side_2", "Frame", LayerIndex.Global, pad_left + listbox_w , 132, GUI.w - pad_left - listbox_w, framewidth, true, true)
  GUI.New("main_frame_side_3", "Frame", LayerIndex.Global, pad_left + listbox_w , 244, GUI.w - pad_left - listbox_w, framewidth, true, true)
  GUI.New("main_frame_side_4", "Frame", LayerIndex.Global, pad_left + listbox_w , 320, GUI.w - pad_left - listbox_w, framewidth, true, true)
  GUI.New("main_frame_side_5", "Frame", LayerIndex.Global, pad_left + listbox_w , 355, GUI.w - pad_left - listbox_w, framewidth, true, true)
  GUI.New("main_frame_side_6", "Frame", LayerIndex.ProjectTemplates, pad_left + listbox_w , 390, GUI.w - pad_left - listbox_w, framewidth, true, true)
end

------------------------
-- Tab - Recent Projects
------------------------
function RL_Draw_TabRecentProjects()
  GUI.New("tab_recentProjects_btnRefresh", "Button", LayerIndex.RecentProjects, 10, pad_top - 2, 20,  22, "R", RefreshRecentProjects)
  GUI.New("tab_recentProjects_txtFilter", "Textbox", LayerIndex.RecentProjects, 75, pad_top, 260, 20, "Filter", 8)

  GUI.New("tab_recentProjects_listbox", "Listbox", LayerIndex.RecentProjects, pad_left, listbox_top, listbox_w, listbox_h,"", true)
  GUI.elms.tab_recentProjects_listbox.list = RecentProjects.names
  GUI.Val("tab_recentProjects_listbox", {1})

  GUI.New("tab_recentProjects_btnLoadInTab", "Button", LayerIndex.RecentProjects, btn_pad_left, btn_tab_top, btn_w,  btn_h, "Load in Tab", LoadInTab_RecentProject)
  GUI.New("tab_recentProjects_btnLoad", "Button", LayerIndex.RecentProjects, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_RecentProject)

  function GUI.elms.tab_recentProjects_listbox:onmousedown()
    TabSelectionIndex[1] = self:getitem(GUI.mouse.y)
    if GUI.JSAPI() then AudioPreviewCheckForFile() end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_recentProjects_listbox:ondoubleclick()
    Load_RecentProject()
  end
  
  local function DrawRightClickMenu()
    if noRecentProjects == false then
      gfx.x = gfx.mouse_x
      gfx.y = gfx.mouse_y

      if FilterActive.RecentProjects then
        local RMBmenu = gfx.showmenu("Clear list")
        if RMBmenu == 1 then RL_ConfirmDialog_ClearList() end
      else
        local RMBmenu = gfx.showmenu("Remove entry|#|Clear list")
        if RMBmenu == 1 then RL_ConfirmDialog_RemoveEntry() end
        if RMBmenu == 2 then RL_ConfirmDialog_ClearList() end
      end
    end
  end

  -- right click context menu
  function GUI.elms.tab_recentProjects_listbox:onmouser_down()
    DrawRightClickMenu()
    GUI.Listbox.onmouser_down(self)
  end

  function GUI.elms.tab_recentProjects_txtFilter:ontype()
      GUI.Textbox.ontype(self)
      Filter_RecentProject_Apply()
  end

  function GUI.elms.tab_recentProjects_txtFilter:lostfocus()
    IsKeyInputCheckActive = true
    TabSelectionIndex[1] = 0
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.tab_recentProjects_txtFilter:onmousedown()
    GUI.Textbox.onmousedown(self)
    IsKeyInputCheckActive = false
  end
end

--------------------------
-- Tab - Project Templates
--------------------------
projectTemplateLoadMode = 1

function RL_Draw_TabProjectTemplates()
  GUI.New("tab_projectTemplates_btnRefresh", "Button", LayerIndex.ProjectTemplates, 10, pad_top-2, 20,  22,"R", RefreshProjectTemplates)
  GUI.New("tab_projectTemplates_txtFilter", "Textbox", LayerIndex.ProjectTemplates, 75, pad_top, 260, 20, "Filter", 8)
  
  GUI.New("tab_projectTemplates_subfolders", "Listbox", LayerIndex.ProjectTemplates, pad_left , listbox_top, listbox_w/3, listbox_h, "", true)

  GUI.New("tab_projectTemplates_listbox", "Listbox", LayerIndex.ProjectTemplates, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  GUI.elms.tab_projectTemplates_listbox.list = ProjectTemplates.names
  GUI.Val("tab_projectTemplates_listbox", {1})

  GUI.New("tab_projectTemplates_btnLoadInTab", "Button", LayerIndex.ProjectTemplates, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_ProjectTemplate)
  GUI.New("tab_projectTemplates_btnLoad", "Button", LayerIndex.ProjectTemplates, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_ProjectTemplate)
   
  GUI.New("tab_projectTemplates_lblEditMode", "Label", LayerIndex.ProjectTemplates, GUI.w - 158, 367, "Edit Template Mode", false, 3)
  GUI.New("tab_projectTemplates_checklistEditMode", "Checklist", LayerIndex.ProjectTemplates, GUI.w - 42, 365, 20, 20, "", "", "h", 0)

  function GUI.elms.tab_projectTemplates_subfolders:onmousedown()
    if GUI.elms.tab_projectTemplates_subfolders then 
      TabParentSelectionIndex[2] = self:getitem(GUI.mouse.y)
      GUI.Listbox.onmouseup(self)
      UpdateProjectTemplateSubDirSelection()
    end
  end

  function UpdateProjectTemplateSubDirSelection()
    if TabParentSelectionIndex[2] == 1 then 
      RefreshProjectTemplates()
    else 
      local selectedList = GUI.elms.tab_projectTemplates_subfolders.list 
      FillProjectTemplateListBoxBase(GetFiles(selectedList[TabParentSelectionIndex[2]]))
    end
    TabSelectionIndex[2] = 1
    GUI.Val("tab_projectTemplates_listbox", {1})
  end

  function GUI.elms.tab_projectTemplates_listbox:onmousedown()
    TabSelectionIndex[2] = self:getitem(GUI.mouse.y)
    if GUI.JSAPI() then AudioPreviewCheckForFile() end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_projectTemplates_listbox:ondoubleclick()
    Load_ProjectTemplate()
  end
  
  function GUI.elms.tab_projectTemplates_txtFilter:ontype()
    GUI.Textbox.ontype(self)
    Filter_ProjectTemplate_Apply()
  end

  function GUI.elms.tab_projectTemplates_txtFilter:lostfocus()
    IsKeyInputCheckActive = true
    TabSelectionIndex[2] = 0
    GUI.Textbox.lostfocus(self)
  end
  
  function GUI.elms.tab_projectTemplates_txtFilter:onmousedown()
    GUI.Textbox.onmousedown(self)
    IsKeyInputCheckActive = false
  end

  function GUI.elms.tab_projectTemplates_checklistEditMode:onmousedown()
    projectTemplateLoadMode = GUI.Val("tab_projectTemplates_checklistEditMode")
  end
end

------------------------
-- Tab - Track Templates
------------------------
function RL_Draw_TabTrackTemplates()
  GUI.New("tab_trackTemplates_btnRefresh", "Button", LayerIndex.TrackTemplates, 10, pad_top-2, 20, 22, "R", RefreshTrackTemplates)
  GUI.New("tab_trackTemplates_txtFilter", "Textbox", LayerIndex.TrackTemplates, 75, pad_top, 260, 20, "Filter", 8)
  
  GUI.New("tab_trackTemplates_subfolders", "Listbox", LayerIndex.TrackTemplates, pad_left , listbox_top, listbox_w/3, listbox_h, "", true)

  GUI.New("tab_trackTemplates_listbox", "Listbox", LayerIndex.TrackTemplates, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  GUI.elms.tab_trackTemplates_listbox.list = TrackTemplates.names
  GUI.Val("tab_trackTemplates_listbox", {1})

  GUI.New("tab_trackTemplates_btnInsert", "Button", LayerIndex.TrackTemplates, btn_pad_left, btn_tab_top + 20, btn_w, btn_h, "Insert", Load_TrackTemplate)
  
  function GUI.elms.tab_trackTemplates_subfolders:onmouseup()
    if GUI.elms.tab_trackTemplates_subfolders then 
      TabParentSelectionIndex[3] = self:getitem(GUI.mouse.y)
      GUI.Listbox.onmouseup(self)
      UpdateTrackTemplateSubDirSelection()
    end
  end

  function UpdateTrackTemplateSubDirSelection()
    if TabParentSelectionIndex[3] == 1 then 
      RefreshTrackTemplates()
    else 
      local selectedList = GUI.elms.tab_trackTemplates_subfolders.list 
      FillTrackTemplateListboxBase(GetFiles(selectedList[TabParentSelectionIndex[3]]))
    end
    TabSelectionIndex[3] = 1
    GUI.Val("tab_trackTemplates_listbox", {1})
  end

  function GUI.elms.tab_trackTemplates_listbox:onmousedown()
    TabSelectionIndex[3] = self:getitem(GUI.mouse.y)
    if GUI.JSAPI() then AudioPreviewCheckForFile() end
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
    IsKeyInputCheckActive = true
    TabSelectionIndex[3] = 0
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.tab_trackTemplates_txtFilter:onmousedown()
    GUI.Textbox.onmousedown(self)
    IsKeyInputCheckActive = false
  end
end

-------------------------------
-- Tab - Custom projects folder
-------------------------------
function RL_Draw_TabCustomProjects()
  GUI.New("tab_customProjects_btnFilter", "Button", LayerIndex.CustomProjects, 10, pad_top-2, 20, 22, "R", RefreshCustomProjects)
  GUI.New("tab_customProjects_txtFilter", "Textbox", LayerIndex.CustomProjects, 75, pad_top, 260, 20, "Filter", 8)
  
  GUI.New("tab_customProjects_subfolders", "Listbox", LayerIndex.CustomProjects, pad_left , listbox_top, listbox_w/3, listbox_h, "", true)

  GUI.New("tab_customProjects_listbox", "Listbox", LayerIndex.CustomProjects, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  GUI.elms.tab_customProjects_listbox.list = CustomProjects.names
  GUI.Val("tab_customProjects_listbox", {1})

  GUI.New("tab_customProjects_btnLoadInTab", "Button", LayerIndex.CustomProjects, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_CustomProject)
  GUI.New("tab_customProjects_btnLoad", "Button", LayerIndex.CustomProjects, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_CustomProject)

  function GUI.elms.tab_customProjects_subfolders:onmousedown()
    if GUI.elms.tab_customProjects_subfolders then 
      TabParentSelectionIndex[4] = self:getitem(GUI.mouse.y)
      GUI.Listbox.onmouseup(self)
      UpdateCustomProjectSubDirSelection()
    end
  end

  function UpdateCustomProjectSubDirSelection()
    if TabParentSelectionIndex[4] == 1 then 
      RefreshCustomProjects()
    else 
      local selectedList = GUI.elms.tab_customProjects_subfolders.list 
      FillCustomProjectsListboxBase(GetFiles(selectedList[TabParentSelectionIndex[4]]))
    end
    TabSelectionIndex[4] = 1
    GUI.Val("tab_customProjects_listbox", {1})
  end

  function GUI.elms.tab_customProjects_listbox:onmousedown()
    TabSelectionIndex[4] = self:getitem(GUI.mouse.y)
    if GUI.JSAPI() then AudioPreviewCheckForFile() end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_customProjects_listbox:ondoubleclick()
    Load_CustomProject()
  end
    
  function GUI.elms.tab_customProjects_txtFilter:ontype()
     GUI.Textbox.ontype(self)
     Filter_CustomProjects_Apply()
  end

  function GUI.elms.tab_customProjects_txtFilter:lostfocus()
    IsKeyInputCheckActive = true
    TabSelectionIndex[4] = 0
    GUI.Textbox.lostfocus(self)
  end
  
  function GUI.elms.tab_customProjects_txtFilter:onmousedown()
    GUI.Textbox.onmousedown(self)
    IsKeyInputCheckActive = false
  end
end

-----------------------------
-- Tab - Project Lists (.rpl)
-----------------------------
function RL_Draw_TabProjectLists()
  GUI.New("tab_projectLists_btnRefresh", "Button", LayerIndex.ProjectLists, 10, pad_top - 2, 20,  22, "R", RefreshProjectList)
  GUI.New("tab_projectLists_txtFilter", "Textbox", LayerIndex.ProjectLists, 75, pad_top, 260, 20, "Filter", 8)
 
  GUI.New("tab_projectLists_listboxRPL", "Listbox", LayerIndex.ProjectLists, pad_left , listbox_top, listbox_w/3, listbox_h, "", true)
  GUI.elms.tab_projectLists_listboxRPL.list = ProjectLists.rplFiles  
  GUI.Val("tab_projectLists_listboxRPL", {1})

  GUI.New("tab_projectLists_listboxProjects", "Listbox", LayerIndex.ProjectLists, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)

  GUI.New("tab_projectLists_btnLoadInTab", "Button", LayerIndex.ProjectLists, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_ProjectListProject)
  GUI.New("tab_projectLists_btnLoad", "Button", LayerIndex.ProjectLists, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_ProjectListProject)
 
  function GUI.elms.tab_projectLists_listboxRPL:onmouseup()
    if GUI.elms.tab_projectLists_listboxRPL then 
      TabParentSelectionIndex[5] = self:getitem(GUI.mouse.y)
      GUI.Listbox.onmouseup(self)
      FillProjectListBox()
    end
  end

  function GUI.elms.tab_projectLists_listboxProjects:onmousedown()
    TabSelectionIndex[5] = self:getitem(GUI.mouse.y)
    if GUI.JSAPI() then AudioPreviewCheckForFile() end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_projectLists_listboxProjects:ondoubleclick()
    Load_ProjectListProject()
  end

  function GUI.elms.tab_projectLists_txtFilter:ontype()
    GUI.Textbox.ontype(self)
    Filter_ProjectLists_Apply()
  end

  function GUI.elms.tab_projectLists_txtFilter:lostfocus()
    IsKeyInputCheckActive = true
    TabSelectionIndex[5] = 0
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.tab_projectLists_txtFilter:onmousedown()
    GUI.Textbox.onmousedown(self)
    IsKeyInputCheckActive = false
  end
end

---------------------------
-- Tab - Backups (.rpp-bak)
---------------------------
function RL_Draw_TabBackups()
  GUI.New("tab_backups_btnRefresh", "Button", LayerIndex.Backups, 10, pad_top-2, 20, 22, "R", RefreshBackups)
  GUI.New("tab_backups_txtFilter", "Textbox", LayerIndex.Backups, 75, pad_top, 260, 20, "Filter", 8)

  GUI.New("tab_backups_subfolders", "Listbox", LayerIndex.Backups, pad_left , listbox_top, listbox_w/3, listbox_h, "", true)

  GUI.New("tab_backups_listbox", "Listbox", LayerIndex.Backups, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
  GUI.elms.tab_backups_listbox.list = Backups.names
  GUI.Val("tab_backups_listbox", {1})

  GUI.New("tab_backups_btnLoadInTab", "Button", LayerIndex.Backups, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_BackupFile)
  GUI.New("tab_backups_btnLoad", "Button", LayerIndex.Backups, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_BackupFile)

  function GUI.elms.tab_backups_subfolders:onmousedown()
    if GUI.elms.tab_backups_subfolders then 
      TabParentSelectionIndex[6] = self:getitem(GUI.mouse.y)
      GUI.Listbox.onmouseup(self)
      UpdateBackupsSubDirSelection()
    end
  end

  function UpdateBackupsSubDirSelection()
    if TabParentSelectionIndex[6] == 1 then 
      RefreshBackups()
    else 
      local selectedList = GUI.elms.tab_backups_subfolders.list 
      FillBackupsListboxBase(GetFiles(selectedList[TabParentSelectionIndex[6]]))
    end
    TabSelectionIndex[6] = 1
    GUI.Val("tab_backups_listbox", {1})
  end

  function GUI.elms.tab_backups_listbox:onmousedown()
    TabSelectionIndex[6] = self:getitem(GUI.mouse.y)
    if GUI.JSAPI() then AudioPreviewCheckForFile() end
    GUI.Listbox.onmousedown(self)
  end

  function GUI.elms.tab_backups_listbox:ondoubleclick()
    Load_BackupFile()
  end
    
  function GUI.elms.tab_backups_txtFilter:ontype()
    GUI.Textbox.ontype(self)
    Filter_Backups_Apply()
  end

  function GUI.elms.tab_backups_txtFilter:lostfocus()
    IsKeyInputCheckActive = true
    TabSelectionIndex[6] = 0
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.tab_backups_txtFilter:onmousedown()
    GUI.Textbox.onmousedown(self)
    IsKeyInputCheckActive = false
  end
end

----------------
-- Tab - Options
----------------
if GUI.SWS() then
  function RL_Draw_SavePromptOption(options_pad_top, options_yOffset)
      GUI.New("options_lblPromptToSave", "Label", LayerIndex.Options, GUI.w - 258, options_pad_top + 6 * options_yOffset - 14, "Prompt to save on new project", false, 3)
      GUI.New("options_checklistPromptToSave", "Checklist", LayerIndex.Options, GUI.w - 85, options_pad_top  + 6 * options_yOffset - 18, 20, 20, "", "", "h", 0)
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
end

function RL_Draw_TabOptions()
  local options_yOffset = 50
  local options_pad_top = 16

  -- custom project template folder
  GUI.New("options_btnProjectTemplatesClear", "Button", LayerIndex.Options, 20, options_pad_top + options_yOffset, 55, 20, "Remove", Path_Clear_ProjectTemplateFolder)
  GUI.New("options_btnProjectTemplatesSet", "Button", LayerIndex.Options, GUI.w - 60, options_pad_top + options_yOffset, 40, 20, "Set", Path_Set_ProjectTemplateFolder)
  GUI.New("options_txtProjectTemplatesPath", "Textbox", LayerIndex.Options, 85, options_pad_top + options_yOffset, GUI.w - 150, 20, "Additional .RPP [ Project Templates ] folder", 8)
  GUI.elms.options_txtProjectTemplatesPath.cap_pos = "top"

  -- custom track template folder
  GUI.New("options_btnTrackTemplatesClear", "Button", LayerIndex.Options, 20, options_pad_top + 2 * options_yOffset, 55, 20, "Remove", Path_Clear_TrackTemplateFolder)
  GUI.New("optioptions_btnTrackTemplatesSet", "Button", LayerIndex.Options, GUI.w - 60, options_pad_top + 2 * options_yOffset, 40, 20, "Set", Path_Set_TrackTemplateFolder)
  GUI.New("options_txtTrackTemplatesPath", "Textbox", LayerIndex.Options, 85, options_pad_top + 2 * options_yOffset, GUI.w - 150, 20, "Additional .RTrackTemplate [ Track Templates ] folder", 8)
  GUI.elms.options_txtTrackTemplatesPath.cap_pos = "top"

  -- custom project folder
  GUI.New("options_btnCustomProjectsClear", "Button", LayerIndex.Options, 20, options_pad_top + 3 * options_yOffset, 55, 20, "Remove", Path_Clear_CustomProjectFolder)
  GUI.New("options_btnCustomProjectsSet", "Button", LayerIndex.Options, GUI.w - 60, options_pad_top + 3 * options_yOffset, 40, 20, "Set", Path_Set_CustomProjectFolder)
  GUI.New("options_txtCustomProjectsPath", "Textbox", LayerIndex.Options, 85, options_pad_top + 3 * options_yOffset, GUI.w - 150, 20, ".RPP [ Projects ] folder", 8)
  GUI.elms.options_txtCustomProjectsPath.cap_pos = "top"

  -- project list folder
  GUI.New("options_btnProjectListsClear", "Button", LayerIndex.Options, 20, options_pad_top + 4 * options_yOffset, 55, 20, "Remove", Path_Clear_ProjectListFolder)
  GUI.New("options_btnProjectListsSet", "Button", LayerIndex.Options, GUI.w - 60, options_pad_top + 4 * options_yOffset, 40, 20, "Set", Path_Set_ProjectListFolder)
  GUI.New("options_txtProjectsListsPath", "Textbox", LayerIndex.Options, 85, options_pad_top + 4 * options_yOffset, GUI.w - 150, 20, ".RPL [ Project Lists ] folder", 8)
  GUI.elms.options_txtProjectsListsPath.cap_pos = "top"

  -- bak files folder
  GUI.New("options_btnBackupsClear", "Button", LayerIndex.Options, 20, options_pad_top + 5 * options_yOffset, 55, 20, "Remove", Path_Clear_BackupsFolder)
  GUI.New("options_btnBackupsSet", "Button", LayerIndex.Options, GUI.w - 60, options_pad_top + 5 * options_yOffset, 40, 20, "Set", Path_Set_BackupsFolder)
  GUI.New("options_txtBackupsPath", "Textbox", LayerIndex.Options, 85, options_pad_top + 5 * options_yOffset, GUI.w - 150, 20, ".RPP-BAK [ Backups ] folder", 8)
  GUI.elms.options_txtBackupsPath.cap_pos = "top"

  if GUI.SWS() then 
    RL_Draw_SavePromptOption(options_pad_top, options_yOffset);
    RL_Draw_ThemeSlotOptions()
  end

  -- enable textbox input
  function GUI.elms.options_txtProjectTemplatesPath:onmousedown()
    GUI.Textbox.onmousedown(self)
    IsKeyInputCheckActive = false
  end

  function GUI.elms.options_txtTrackTemplatesPath:onmousedown()
    GUI.Textbox.onmousedown(self)
    IsKeyInputCheckActive = false
  end

  function GUI.elms.options_txtCustomProjectsPath:onmousedown()
    GUI.Textbox.onmousedown(self)
    IsKeyInputCheckActive = false
  end

  function GUI.elms.options_txtProjectsListsPath:onmousedown()
    GUI.Textbox.onmousedown(self)
    IsKeyInputCheckActive = false
  end

  function GUI.elms.options_txtBackupsPath:onmousedown()
    GUI.Textbox.onmousedown(self)
    IsKeyInputCheckActive = false
  end

  -- disable textbox input on lost focus
  function GUI.elms.options_txtProjectTemplatesPath:lostfocus()
    IsKeyInputCheckActive = true
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.options_txtTrackTemplatesPath:lostfocus()
    IsKeyInputCheckActive = true
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.options_txtCustomProjectsPath:lostfocus()
    IsKeyInputCheckActive = true
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.options_txtProjectsListsPath:lostfocus()
    IsKeyInputCheckActive = true
    GUI.Textbox.lostfocus(self)
  end

  function GUI.elms.options_txtBackupsPath:lostfocus()
    IsKeyInputCheckActive = true
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
filter: jump into | jump out
- - - - -
prev | next in list
prev | next in parent list
load in tab
load
toggle audio preview 
- - - - -
toggle paths
keep (window) open
show in explorer/finder       
open project                  
new project
new tab
new tab ignore template
close current project tab
prev | next project tab
- - - - -
help
options
list refresh ]]
}

local helpKeyShortcuts = {
[[
LEFT | RIGHT
1, 2, 3, 4, 5, 6
- - - - -
TAB | ENTER
- - - - -
UP | DOWN
SHIFT + UP | DOWN
SHIFT + ENTER
ENTER
SPACE  ,  *
- - - - -
P
W
S
O
N
T  ,  + 
/
C  , -
X |  V
- - - - -
F1
F2
F5  ]]
}

local helpInfo = {
[[
- - - - - - - - - - - -
Audio preview
- - - - - - - - - - - -
[ Requires js_ReaScriptAPI installed ]
- - - - -
1) Place a WAV, FLAC, MP3 or OGG audio file with identical name into the same folder as the project or template file.
- - - - -
Example: testproject.RPP / testproject.WAV
- - - - -
2) Select the output channels in the [ Options ]
- - - - -
3) Adjust the volume by turning the preview volume knob (0 - 100 %)
- - - - -
4) Start & Stop a preview of a selected entry via DOUBLE CLICK on the preview volume knob or by using the assigned KEY SHORTCUT
- - - - -
Volume knob status colors:
- SILVER: preview available for selected entry
- GREEN: preview playing
]]
,
[[
- - - - - - - - - - - - - - -
Listbox multi-select 
- - - - - - - - - - - - - - -
Selection of multiple list entries is possible via:
- - - - -
- SHIFT + LEFT CLICK: select adjacent entries
- CTRL/CMD + LEFT CLICK: select non-adjacent entries
- - - - -
Loading a single entry directly is possible via DOUBLE CLICK
]]
,
[[
- - - - - - - - - - - - - - - - - - - - - - - 
Load projects with FX offline
- - - - - - - - - - - - - - - - - - - - - - - 
Either hold the following key combination while loading:
- - - - -
- CTRL + SHIFT (Windows & Linux)
- CMD + SHIFT  (macOS)
- - - - -
Or use the 'Open with FX offline' option in the [Open Project] window
]]
,
[[
- - - - - - - - - - - - - - -
[ Recent Projects ]
- - - - - - - - - - - - - - -
RIGHT CLICK on the Recent Projects listbox opens the context menu for removing selected entries or clearing the entire recent projects list:
- - - - -
- Remove entry
- Clear list
- - - - -
The 'Remove entry' menu option is only available for the unfiltered list
]]
}

function RL_Draw_TabHelp()
  local threadUrl = [[https://forum.cockos.com/showthread.php?t=208697]]
  local frameOffsetY = 50 
  local frameHeight = GUI.h - 75
  local frameWidth = GUI.w/4 + 22
  local framePad = 10

  GUI.New("help_label_left", "Label", LayerIndex.Help, 14, 28, "Action", false, 3)
  GUI.New("help_label_middle", "Label", LayerIndex.Help, 14 + frameWidth, 28, "Shortcut", false, 3)
  GUI.New("help_menu", "Menubox", LayerIndex.Help, (2 * frameWidth) - 30, 26, 150, 20, "","Audio preview,Listbox multi-select,Load with FX offline,Recent Projects")
  GUI.elms.help_menu.align = "1"
  GUI.New("help_btnThread", "Button", LayerIndex.Help, GUI.w - 116, 26, 90, 18, "Forum thread")

  GUI.New("help_frame_left", "Frame", LayerIndex.Help, 5, frameOffsetY, frameWidth, frameHeight, false, false)
  GUI.New("help_frame_middle", "Frame", LayerIndex.Help, 5 + frameWidth, frameOffsetY, frameWidth - 40, frameHeight, false, false)
  GUI.New("help_frame_right", "Frame", LayerIndex.Help, (2 * frameWidth) - 36, frameOffsetY, (2 * frameWidth) - 58, frameHeight, false, false)
  GUI.elms.help_frame_left.pad = framePad
  GUI.elms.help_frame_middle.pad = framePad
  GUI.elms.help_frame_right.pad = framePad

  GUI.Val("help_frame_left", helpKeyDescriptions[1]);
  GUI.Val("help_frame_middle", helpKeyShortcuts[1]);
  GUI.Val("help_frame_right", helpInfo[1]);

  function GUI.elms.help_btnThread:onmousedown()
    GUI.Button.onmousedown(self)
    if GUI.SWS() then reaper.CF_ShellExecute(threadUrl)
    else ShowLocationInExplorer(threadUrl) end
  end

  function GUI.elms.help_menu:onmousedown()
    GUI.Menubox.onmouseup(self)
    GUI.Val("help_frame_right", helpInfo[GUI.Val("help_menu")]);
  end
  
  function GUI.elms.help_menu:onwheel()
    GUI.Menubox.onwheel(self)
    GUI.Val("help_frame_right", helpInfo[GUI.Val("help_menu")]);
  end
end

-----------
-- Tooltips
-----------
function RL_Draw_Tooltips()
  local ttLoadFXoffline = "Loading with FX offline: \n\n- Hold 'CTRL + SHIFT' (Windows & Linux)\n- Hold 'CMD + SHIFT' (macOS)\n- Via the option in the [Open Project] window"
  -- main
  GUI.elms.main_menuPaths.tooltip = "Show/Hide file paths in the list"
  GUI.elms.main_btnOpenInExplorer.tooltip = "Browse to the file location in Explorer/Finder"
  GUI.elms.main_btnNewProjectTab.tooltip = "Add new project tab"
  GUI.elms.main_btnNewTabIgnoreTemplate.tooltip = "Add new project tab (ignore template)"
  GUI.elms.main_btnNewProject.tooltip = "Create new project"
  GUI.elms.main_button_openProject.tooltip = "Show the 'Open project' window"
  -- window pin
  local tooltip_windowpin = "Check to keep the window open"
  GUI.elms.main_label_windowpin.tooltip = tooltip_windowpin
  GUI.elms.main_checklist_windowpin.tooltip = tooltip_windowpin
  -- recent projects
  GUI.elms.tab_recentProjects_btnRefresh.tooltip = "Refresh the [Recent Projects] list"
  GUI.elms.tab_recentProjects_txtFilter.tooltip = "Filter the [Recent Projects] list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_recentProjects_btnLoadInTab.tooltip = "Load selected recent project(s) in tab(s)\n\n" .. ttLoadFXoffline
  GUI.elms.tab_recentProjects_btnLoad.tooltip = "Load selected recent project(s)\n\n" .. ttLoadFXoffline
  -- project templates
  GUI.elms.tab_projectTemplates_btnRefresh.tooltip = "Refresh [Project Templates] list"
  GUI.elms.tab_projectTemplates_txtFilter.tooltip = "Filter the [Project Templates] list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_projectTemplates_btnLoadInTab.tooltip = "Load selected project template(s) in tab(s)\n\n" .. ttLoadFXoffline
  GUI.elms.tab_projectTemplates_btnLoad.tooltip = "Load selected project templates(s)\n\n" .. ttLoadFXoffline
  -- template edit mode
  local tooltip_projectTemplatesEditMode = "Open the project template file for direct editing"
  GUI.elms.tab_projectTemplates_lblEditMode.tooltip = tooltip_projectTemplatesEditMode
  GUI.elms.tab_projectTemplates_checklistEditMode.tooltip = tooltip_projectTemplatesEditMode
  -- track templates
  GUI.elms.tab_trackTemplates_btnRefresh.tooltip = "Refresh the [Track Templates] list"
  GUI.elms.tab_trackTemplates_txtFilter.tooltip = "Filter the [Track Templates] list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_trackTemplates_btnInsert.tooltip = "Insert selected track template(s)"
  -- projects
  GUI.elms.tab_customProjects_btnFilter.tooltip = "Refresh the [Projects] list"
  GUI.elms.tab_customProjects_txtFilter.tooltip = "Filter the [Projects] list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_customProjects_btnLoadInTab.tooltip = "Load the selected project(s) in tab(s)\n\n" .. ttLoadFXoffline
  GUI.elms.tab_customProjects_btnLoad.tooltip = "Load the selected project(s)\n\n" .. ttLoadFXoffline
  -- project lists
  GUI.elms.tab_projectLists_btnRefresh.tooltip = "Refresh the [Project Lists] list"
  GUI.elms.tab_projectLists_txtFilter.tooltip = "Filter the [Project Lists] list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_projectLists_btnLoadInTab.tooltip = "Load the selected project(s) in tab(s)\n\n" .. ttLoadFXoffline
  GUI.elms.tab_projectLists_btnLoad.tooltip = "Load the selected project(s)\n\n" .. ttLoadFXoffline
  -- backups
  GUI.elms.tab_backups_btnRefresh.tooltip = "Refresh the [Backups] list"
  GUI.elms.tab_backups_txtFilter.tooltip = "Filter the [Backups] list by typing in one or multiple words separated by a 'space' character"
  GUI.elms.tab_backups_btnLoadInTab.tooltip = "Load the selected backup(s) in tab(s)\n\n" .. ttLoadFXoffline
  GUI.elms.tab_backups_btnLoad.tooltip = "Load the selected backup(s)\n\n" .. ttLoadFXoffline
  -- project templates path
  GUI.elms.options_btnProjectTemplatesClear.tooltip = "Remove project template folder path"
  GUI.elms.options_btnProjectTemplatesSet.tooltip = "Set the given path as additional project template folder"
  GUI.elms.options_txtProjectTemplatesPath.tooltip = "Enter a custom project template folder path"
  -- track templates path
  GUI.elms.options_btnTrackTemplatesClear.tooltip = "Remove track template folder path"
  GUI.elms.optioptions_btnTrackTemplatesSet.tooltip = "Set the given path as additional track template folder"
  GUI.elms.options_txtTrackTemplatesPath.tooltip = "Enter a custom track template folder path"
  -- custom projects path
  GUI.elms.options_btnCustomProjectsClear.tooltip = "Remove project folder path"
  GUI.elms.options_btnCustomProjectsSet.tooltip = "Set the given path as project folder"
  GUI.elms.options_txtCustomProjectsPath.tooltip = "Enter a custom project folder path"
  -- project lists path
  GUI.elms.options_btnProjectListsClear.tooltip = "Remove project list folder path"
  GUI.elms.options_btnProjectListsSet.tooltip = "Set the given path as project list folder"
  GUI.elms.options_txtProjectsListsPath.tooltip = "Enter a custom project list folder path"
  -- backup path
  GUI.elms.options_btnBackupsClear.tooltip = "Remove backup folder path"
  GUI.elms.options_btnBackupsSet.tooltip = "Set the given path as backup folder"
  GUI.elms.options_txtBackupsPath.tooltip = "Enter a custom backup folder path"
  
  if GUI.SWS() then GUI.elms.themeslot.tooltip = "Switch between different Reaper Theme Slots" end
end

--------------------------
-- Color element functions
--------------------------
local ButtonColor = "wnd_bg"

function RL_Draw_Colors_Button()
  -- main section
  GUI.elms.main_btnOpenInExplorer.col_fill = ButtonColor
  GUI.elms.main_btnOpenInExplorer:init()
  GUI.elms.main_button_openProject.col_fill = ButtonColor
  GUI.elms.main_button_openProject:init()
  GUI.elms.main_btnNewProjectTab.col_fill = ButtonColor
  GUI.elms.main_btnNewProjectTab:init()
  GUI.elms.main_btnNewTabIgnoreTemplate.col_fill = ButtonColor
  GUI.elms.main_btnNewTabIgnoreTemplate:init()
  GUI.elms.main_btnNewProject.col_fill = ButtonColor
  GUI.elms.main_btnNewProject:init()
  -- recent projects
  GUI.elms.tab_recentProjects_btnRefresh.col_fill = ButtonColor
  GUI.elms.tab_recentProjects_btnRefresh:init()
  GUI.elms.tab_recentProjects_btnLoadInTab.col_fill = ButtonColor
  GUI.elms.tab_recentProjects_btnLoadInTab:init()
  GUI.elms.tab_recentProjects_btnLoad.col_fill = ButtonColor
  GUI.elms.tab_recentProjects_btnLoad:init()
  -- project templates
  GUI.elms.tab_projectTemplates_btnRefresh.col_fill = ButtonColor
  GUI.elms.tab_projectTemplates_btnRefresh:init()
  GUI.elms.tab_projectTemplates_btnLoadInTab.col_fill = ButtonColor
  GUI.elms.tab_projectTemplates_btnLoadInTab:init()
  GUI.elms.tab_projectTemplates_btnLoad.col_fill = ButtonColor
  GUI.elms.tab_projectTemplates_btnLoad:init()
  -- track templates
  GUI.elms.tab_trackTemplates_btnRefresh.col_fill = ButtonColor
  GUI.elms.tab_trackTemplates_btnRefresh:init()
  GUI.elms.tab_trackTemplates_btnInsert.col_fill = ButtonColor
  GUI.elms.tab_trackTemplates_btnInsert:init()
  -- custom projects
  GUI.elms.tab_customProjects_btnFilter.col_fill = ButtonColor
  GUI.elms.tab_customProjects_btnFilter:init()
  GUI.elms.tab_customProjects_btnLoadInTab.col_fill = ButtonColor
  GUI.elms.tab_customProjects_btnLoadInTab:init()
  GUI.elms.tab_customProjects_btnLoad.col_fill = ButtonColor
  GUI.elms.tab_customProjects_btnLoad:init()
  -- project list
  GUI.elms.tab_projectLists_btnRefresh.col_fill = ButtonColor
  GUI.elms.tab_projectLists_btnRefresh:init()
  GUI.elms.tab_projectLists_btnLoadInTab.col_fill = ButtonColor
  GUI.elms.tab_projectLists_btnLoadInTab:init()
  GUI.elms.tab_projectLists_btnLoad.col_fill = ButtonColor
  GUI.elms.tab_projectLists_btnLoad:init()
  -- backups
  GUI.elms.tab_backups_btnRefresh.col_fill = ButtonColor
  GUI.elms.tab_backups_btnRefresh:init()
  GUI.elms.tab_backups_btnLoadInTab.col_fill = ButtonColor
  GUI.elms.tab_backups_btnLoadInTab:init()
  GUI.elms.tab_backups_btnLoad.col_fill = ButtonColor
  GUI.elms.tab_backups_btnLoad:init()
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
  -- help
  GUI.elms.help_btnThread.col_fill = ButtonColor
  GUI.elms.help_btnThread:init()
  -- themeslot selector
  if GUI.SWS() then 
    GUI.elms.options_themeslot_Setup.col_fill = ButtonColor
    GUI.elms.options_themeslot_Setup:init()
    GUI.elms.options_themeslot_Save.col_fill = ButtonColor
    GUI.elms.options_themeslot_Save:init()
  end
  -- confirm dialog
  GUI.elms.confirmdialog_btnOK.col_fill = ButtonColor
  GUI.elms.confirmdialog_btnOK:init()
  GUI.elms.confirmdialog_btnCancel.col_fill = ButtonColor
  GUI.elms.confirmdialog_btnCancel:init()
end

function RL_Draw_Fonts()
  GUI.elms.main_appversion.font = {sans, 12, "b"}
  GUI.elms.main_appversion:init()

  GUI.elms.main_statusbar.font = {sans, 12, "b"}
  GUI.elms.main_statusbar:init()
end

-----------------
-- Confirm Dialog
-----------------
ConfirmDialog = {
  type,
  message
}

function RL_ConfirmDialog_RemoveEntry()
  ConfirmDialog.type = "RemoveEntry"
  ConfirmDialog.message = "Remove the selected entries?"
  GUI.elms.confirmdialog_window:open()
end

function RL_ConfirmDialog_ClearList()
  ConfirmDialog.type = "ClearList"
  ConfirmDialog.message = "Clear Recent Projects list?"
  GUI.elms.confirmdialog_window:open()
end

function RL_ConfirmDialog_OK()
  if ConfirmDialog.type == "RemoveEntry" then RecentProjects_RemoveEntry() end
  if ConfirmDialog.type == "ClearList" then RecentProjects_ClearList() end
  GUI.elms.confirmdialog_window:close()
end

function RL_ConfirmDialog_Cancel()
  GUI.elms.confirmdialog_window:close()
end

function RL_InitConfirmDialog()
  GUI.New("confirmdialog_window", "Window", LayerIndex.DialogWindow, 0, 0, 200, 100, "Confirm", {LayerIndex.DialogContent, LayerIndex.DialogWindow})
  GUI.New("confirmdialog_label", "Label", LayerIndex.DialogContent, 24, 16, "", false, 4)
  GUI.New("confirmdialog_btnOK", "Button", LayerIndex.DialogContent, 40, 45, 48, 20, "OK", RL_ConfirmDialog_OK)
  GUI.New("confirmdialog_btnCancel", "Button", LayerIndex.DialogContent, 110, 45, 48, 20, "Cancel", RL_ConfirmDialog_Cancel)
  GUI.elms_hide[LayerIndex.DialogContent] = true
  GUI.elms_hide[LayerIndex.DialogWindow] = true

  function GUI.elms.confirmdialog_window:onopen()
      self:adjustelm(GUI.elms.confirmdialog_btnOK)
      self:adjustelm(GUI.elms.confirmdialog_btnCancel)
      self:adjustelm(GUI.elms.confirmdialog_label)
      self.caption = "Confirm"
      GUI.Val("confirmdialog_label", ConfirmDialog.message )
  end
end

----------------------
-- Draw function relay
----------------------
function RL_Draw_Tabs()
  RL_Draw_TabRecentProjects()
  RL_Draw_TabProjectTemplates()
  RL_Draw_TabTrackTemplates()
  RL_Draw_TabCustomProjects()
  RL_Draw_TabProjectLists()
  RL_Draw_TabBackups()
  RL_Draw_TabOptions()
  RL_Draw_TabHelp()
end

function RL_Draw_Colors()
  RL_Draw_Colors_Button()
end

function RL_Draw_AddOns()
  RL_InitConfirmDialog()
  RL_Draw_Tooltips()
  RL_Draw_Fonts()
  RL_Draw_Colors()
end

function RL_DrawAll()
  RL_Draw_Main()
  RL_Draw_Tabs()
  RL_Draw_Frames()
  RL_Draw_AddOns()
end

RL_DrawAll()

------------------
-- Redraw function
------------------
function RL_RedrawAll()
  -- main
  GUI.elms.main_tabs:ondelete()
  GUI.elms.main_appversion:ondelete()
  GUI.elms.main_statusbar:ondelete()
  -- main elements
  GUI.elms.main_menuPaths:ondelete()
  GUI.elms.main_btnOpenInExplorer:ondelete()
  GUI.elms.main_btnNewProjectTab:ondelete()
  GUI.elms.main_btnNewTabIgnoreTemplate:ondelete()
  GUI.elms.main_btnNewProject:ondelete()
  GUI.elms.main_button_openProject:ondelete()
  GUI.elms.main_label_windowpin:ondelete()
  GUI.elms.main_checklist_windowpin:ondelete()
  RL_Draw_Main()
  -- recent projects
  GUI.elms.tab_recentProjects_btnRefresh:ondelete()
  GUI.elms.tab_recentProjects_txtFilter:ondelete()
  GUI.elms.tab_recentProjects_listbox:ondelete()
  GUI.elms.tab_recentProjects_btnLoadInTab:ondelete()
  GUI.elms.tab_recentProjects_btnLoad:ondelete()
  -- project templates
  GUI.elms.tab_projectTemplates_btnRefresh:ondelete()
  GUI.elms.tab_projectTemplates_txtFilter:ondelete()
  GUI.elms.tab_projectTemplates_subfolders:ondelete()
  GUI.elms.tab_projectTemplates_listbox:ondelete()
  GUI.elms.tab_projectTemplates_btnLoadInTab:ondelete()
  GUI.elms.tab_projectTemplates_btnLoad:ondelete()
  GUI.elms.tab_projectTemplates_lblEditMode:ondelete()
  GUI.elms.tab_projectTemplates_checklistEditMode:ondelete()
  -- track templates
  GUI.elms.tab_trackTemplates_btnRefresh:ondelete()
  GUI.elms.tab_trackTemplates_txtFilter:ondelete()
  GUI.elms.tab_trackTemplates_subfolders:ondelete()
  GUI.elms.tab_trackTemplates_listbox:ondelete()
  GUI.elms.tab_trackTemplates_btnInsert:ondelete()
  -- custom projects
  GUI.elms.tab_customProjects_btnFilter:ondelete()
  GUI.elms.tab_customProjects_txtFilter:ondelete()
  GUI.elms.tab_customProjects_subfolders:ondelete()
  GUI.elms.tab_customProjects_listbox:ondelete()
  GUI.elms.tab_customProjects_btnLoadInTab:ondelete()
  GUI.elms.tab_customProjects_btnLoad:ondelete()
  -- project lists
  GUI.elms.tab_projectLists_btnRefresh:ondelete()
  GUI.elms.tab_projectLists_txtFilter:ondelete()
  GUI.elms.tab_projectLists_listboxRPL:ondelete()
  GUI.elms.tab_projectLists_listboxProjects:ondelete()
  GUI.elms.tab_projectLists_btnLoadInTab:ondelete()
  GUI.elms.tab_projectLists_btnLoad:ondelete()
  -- backups
  GUI.elms.tab_backups_btnRefresh:ondelete()
  GUI.elms.tab_backups_txtFilter:ondelete()
  GUI.elms.tab_backups_subfolders:ondelete()
  GUI.elms.tab_backups_listbox:ondelete()
  GUI.elms.tab_backups_btnLoadInTab:ondelete()
  GUI.elms.tab_backups_btnLoad:ondelete()
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
  GUI.elms.help_frame_left:ondelete()
  GUI.elms.help_frame_middle:ondelete()
  GUI.elms.help_frame_right:ondelete()
  -- theme slot options
  if GUI.SWS() then
    GUI.elms.options_themeslot_number:ondelete()
    GUI.elms.options_themeslot_1:ondelete()
    GUI.elms.options_themeslot_2:ondelete()
    GUI.elms.options_themeslot_3:ondelete()
    GUI.elms.options_themeslot_4:ondelete()
    GUI.elms.options_themeslot_5:ondelete()
    GUI.elms.options_themeslot_Setup:ondelete()
    GUI.elms.options_themeslot_Save:ondelete()
  end
  -- audio preview channel selector
  if GUI.JSAPI() then GUI.elms.main_previewChannels:ondelete() end
  RL_Draw_Tabs()
  RL_Draw_AddOns()
  -- confirm dialog
  GUI.elms.confirmdialog_window:ondelete()
  GUI.elms.confirmdialog_label:ondelete()
  GUI.elms.confirmdialog_btnOK:ondelete()
  GUI.elms.confirmdialog_btnCancel:ondelete()
  RL_InitConfirmDialog()
  -- frames
  GUI.elms.main_frame_top:ondelete()
  GUI.elms.main_frame_side_2:ondelete()
  GUI.elms.main_frame_side_3:ondelete()
  GUI.elms.main_frame_side_4:ondelete()
  GUI.elms.main_frame_side_5:ondelete()
  GUI.elms.main_frame_side_6:ondelete()
  RL_Draw_Frames()
end

--------------------
-- Load Ext settings
--------------------
-- load custom folders paths
local function RL_ExtStates_Load_FolderPaths()
  GUI.elms.options_txtProjectTemplatesPath:val(reaper.GetExtState(appname, "custompath_projecttemplates"))
  GUI.elms.options_txtTrackTemplatesPath:val(reaper.GetExtState(appname, "custompath_tracktemplates"))
  GUI.elms.options_txtCustomProjectsPath:val(reaper.GetExtState(appname, "custompath_projects"))
  GUI.elms.options_txtProjectsListsPath:val(reaper.GetExtState(appname, "custompath_projectlists"))
  GUI.elms.options_txtBackupsPath:val(reaper.GetExtState(appname, "custompath_backups"))
end

-- load theme slot aliases
local function RL_ExtStates_Load_ThemeSlotAliases()
  local themeSlotAliasesString = reaper.GetExtState(appname, "themeslot_aliases")
  local themeSlots = {}
  for match in string.gmatch(themeSlotAliasesString, separatorComma) do table.insert(themeSlots, string.lower(match)) end
  for i= 1, 5 do GUI.Val("options_themeslot_" .. i, themeSlots[i]) end
  ThemeSlot_LoadNames()
end

local function RL_ExtStates_Load()
  local pin = reaper.GetExtState(appname,"window_pin")
  GUI.Val("main_checklist_windowpin", {(pin == "true" and true or false)}) -- window pin state (true = keep window open)
  RL_SetFocusedTab(tonumber(reaper.GetExtState(appname, "window_tabfocus"))) -- last selected tab

  if GUI.SWS() then
    GUI.Val("themeslot_max", tonumber(reaper.GetExtState(appname, "themeslot_max"))) -- max number of available theme slots
    RL_ExtStates_Load_ThemeSlotAliases()
  end

  if GUI.JSAPI() then 
    GUI.Val("main_previewVolKnob", tonumber(reaper.GetExtState(appname, "preview_vol"))) -- preview section volume
    audioPreviewChannel = tonumber(reaper.GetExtState(appname, "preview_channel")) -- preview section first output channel index
    GUI.Val("main_previewChannels",tonumber(reaper.GetExtState(appname, "preview_channelmenuitem"))) -- preview section channel menu item
  end

  RL_ExtStates_Load_FolderPaths()
end

--------------------
-- Save Ext settings
--------------------
local function RL_ExtStates_Save()
  GUI.save_window_state(appname) -- window state
  reaper.SetExtState(appname, "window_pin", tostring(GUI.Val("main_checklist_windowpin")), 1) -- window pin state (true = keep window open)
  reaper.SetExtState(appname, "window_tabfocus", RL_GetFocusedTab(), 1)  -- last selected tab

  if GUI.SWS() then
    reaper.SetExtState(appname, "themeslot_max", tostring(GUI.Val("options_themeslot_number")), 1) -- max number of available theme slots
  end  
  
  if GUI.JSAPI() then 
    reaper.SetExtState(appname, "preview_vol", tostring(GUI.Val("main_previewVolKnob")), 1) -- preview section volume
    if audioPreviewChannel == nil then audioPreviewChannel = 0 end
    reaper.SetExtState(appname, "preview_channel", audioPreviewChannel, 1) -- preview section first output channel index
    reaper.SetExtState(appname, "preview_channelmenuitem", tostring(GUI.Val("main_previewChannels")), 1) -- preview section channel menu item
  end
end

----------------
-- Audio Preview
----------------
if GUI.JSAPI() then
  local AudioPreviewFileTypes = { ".wav", ".flac", ".mp3",".ogg" } -- ordered by priority from left to right

  function AudioPreviewGetSourceFile(currentTab, project, idx, audioExtension)
    local selectedItem
    if currentTab == 1 then selectedItem = RecentProjects.names[idx] 
      elseif currentTab == 2 then selectedItem = ProjectTemplates.names[idx]
      elseif currentTab == 3 then selectedItem = TrackTemplates.names[idx] 
      elseif currentTab == 4 then selectedItem = CustomProjects.names[idx] 
      elseif currentTab == 5 then selectedItem = ProjectLists.projectNames[idx] 
      elseif currentTab == 6 then selectedItem = Backups.names[idx]
    end

    if selectedItem == nil then return 'emptyList'
    else
      return GetDirectoryPath(project) .. GetPathSeparator() .. selectedItem .. audioExtension, audioExtension
    end
  end

  function AudioPreviewToggleState()
    if audioPreviewActive then AudioPreviewStopAll()
    else AudioPreviewStart() end
  end

  function AudioPreviewChangeVolKnobColor(bodyColor, headColor)
    GUI.elms.main_previewVolKnob.col_body = bodyColor
    GUI.elms.main_previewVolKnob.col_head = headColor
    GUI.elms.main_previewVolKnob:init();        
    GUI.elms.main_previewVolKnob:redraw(self);  
  end
  
  function IsFilterActive(currentTab)
    if currentTab == 1 then return FilterActive.RecentProjects
      elseif currentTab == 2 then return FilterActive.ProjectTemplates
      elseif currentTab == 3 then return FilterActive.TrackTemplates
      elseif currentTab == 4 then return FilterActive.CustomProjects
      elseif currentTab == 5 then return FilterActive.ProjectLists
      elseif currentTab == 6 then return FilterActive.Backups
    end
  end

  local audioPreviewFile
  local audioPreviewStatusText = nil

  function AudioPreviewCheckForFile()
    local currentTab = RL_GetFocusedTab()
    local selectedIndex = TabSelectionIndex[currentTab]
    local selectedElement

    if IsFilterActive(currentTab) == false then
      AudioPreviewElements = {
        { RecentProjects.items, RecentProjects.names },
        { ProjectTemplates.items, ProjectTemplates.names },
        { TrackTemplates.items, TrackTemplates.names },
        { CustomProjects.items, CustomProjects.names },
        { ProjectLists.projectItems, ProjectLists.projectNames },
        { Backups.items, Backups.names }
      }
      selectedElement = AudioPreviewElements[currentTab][2][selectedIndex]
      selectedProject = AudioPreviewElements[currentTab][1][selectedElement]
    else
      AudioPreviewElementsFiltered = {
        { RecentProjects.items, RecentProjects.filteredNames },
        { ProjectTemplates.items, ProjectTemplates.filteredNames },
        { TrackTemplates.items, TrackTemplates.filteredNames },
        { CustomProjects.items, CustomProjects.filteredNames },
        { ProjectLists.projectItems, ProjectLists.filteredProjectNames },
        { Backups.items, Backups.filteredNames }
      }
      selectedElement = AudioPreviewElementsFiltered[currentTab][2][selectedIndex]
      selectedProject = AudioPreviewElementsFiltered[currentTab][1][selectedElement] 
    end

    local previewAudioExtension
    for t = 1, #AudioPreviewFileTypes do
      audioPreviewFile, previewAudioExtension = AudioPreviewGetSourceFile(currentTab, selectedProject, selectedIndex, AudioPreviewFileTypes[t])
      
      if audioPreviewFile ~= 'emptyList' and FileExists(audioPreviewFile) then
        break
      end
    end
    
    if FileExists(audioPreviewFile) then
      if audioPreviewActive then AudioPreviewChangeVolKnobColor("elm_fill", "elm_frame")
      else AudioPreviewChangeVolKnobColor("silver", "elm_frame") end
      audioPreviewStatusText = selectedElement .. previewAudioExtension
    else
      AudioPreviewChangeVolKnobColor("elm_frame", "elm_fill")
    end
  end

  function AudioPreviewStart()
    if audioPreviewFile ~= nil and FileExists(audioPreviewFile) then
      AudioPreviewStartPlayback(audioPreviewFile)
    end
  end

  function AudioPreviewStartPlayback(audioFile)
    local previewVol = (GUI.Val("main_previewVolKnob") / 100)
    if previewVol == nil or previewVol > 1 then previewVol = 1 end

    local startOutputChannel = 0
    if audioPreviewChannel ~= nil and audioPreviewChannel > 0 then startOutputChannel = audioPreviewChannel end
    reaper.Xen_StartSourcePreview(reaper.PCM_Source_CreateFromFile(audioFile), previewVol, false, startOutputChannel)    
    
    audioPreviewActive = true
    AudioPreviewChangeVolKnobColor("elm_fill", "elm_frame")
    if audioPreviewStatusText ~= nil then MsgStatusBarStatic("AUDIO PREVIEW | " .. audioPreviewStatusText) end
    
  end

  function AudioPreviewStopAll()
    if audioPreviewActive == true then 
      reaper.Xen_StopSourcePreview(-1)
      audioPreviewActive = false
      AudioPreviewChangeVolKnobColor("elm_frame", "elm_fill")
      MsgStatusBarClear();
    end
  end
end

---------------------
-- Key Input - Tables
---------------------
GUI.chars = {
  ESC       = 27,
  RETURN    = 13,
  TAB       = 9,
  SPACE     = 32,
  -- arrow keys
  UP    = 30064,
  DOWN  = 1685026670,
  LEFT  = 1818584692,
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
  C = 99,
  N = 110,
  O = 111,
  P = 112,
  S = 115,
  T = 116,
  V = 118,
  W = 119,
  X = 120,
  -- function keys
  F1  = 26161,
  F2  = 26162,
  F3  = 26163,
  F4  = 26164,
  F5  = 26165,
  F6  = 26166,
  F7  = 26167,
  F8  = 26168,
  F9  = 26169,
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
TabParentListBox = {
  "",
  "tab_projectTemplates_subfolders",
  "tab_trackTemplates_subfolders",
  "tab_customProjects_subfolders",
  "tab_projectLists_listboxRPL",
  "tab_backups_subfolders"
}

TabListBox = {
  "tab_recentProjects_listbox",
  "tab_projectTemplates_listbox",
  "tab_trackTemplates_listbox",
  "tab_customProjects_listbox",
  "tab_projectLists_listboxProjects",
  "tab_backups_listbox"
}

local TabFilter = {
  GUI.elms.tab_recentProjects_txtFilter,
  GUI.elms.tab_projectTemplates_txtFilter,
  GUI.elms.tab_trackTemplates_txtFilter,
  GUI.elms.tab_customProjects_txtFilter,
  GUI.elms.tab_projectLists_txtFilter,
  GUI.elms.tab_backups_txtFilter
}

-----------------
-- Listbox scroll
-----------------
ParentListBoxElements = {
  nil,
  GUI.elms.tab_projectTemplates_subfolders,
  GUI.elms.tab_trackTemplates_subfolders,
  GUI.elms.tab_customProjects_subfolders,
  GUI.elms.tab_projectLists_listboxRPL,
  GUI.elms.tab_trackTemplates_subfolders,
  GUI.elms.tab_backups_subfolders,
}

ListboxElements = {
  GUI.elms.tab_recentProjects_listbox,
  GUI.elms.tab_projectTemplates_listbox,
  GUI.elms.tab_trackTemplates_listbox,
  GUI.elms.tab_customProjects_listbox,
  GUI.elms.tab_projectLists_listboxProjects,
  GUI.elms.tab_backups_listbox
}

function ScrollToTop(tabIndex)
  local element = ListboxElements[tabIndex]
  if element.wnd_h ~= nil and element.wnd_y ~= nil then
    element.wnd_y = GUI.clamp(1, element.wnd_y - element.wnd_h, math.max(#element.list - element.wnd_h + 1, 1))
    element:redraw()
  end
end

local function ScrollBase(element, listIndex, direction)
  if element.wnd_h ~= nil and element.wnd_y ~= nil then
    if listIndex > element.wnd_h then 
      element.wnd_y = GUI.clamp(1, element.wnd_y + direction, math.max(#element.list - element.wnd_h + 1, 1))
      element:redraw()
    end
  end
end

function ScrollParentListBox(tabIndex, listIndex, direction)
  ScrollBase(ParentListBoxElements[tabIndex], listIndex, direction)
end

function ScrollListBox(tabIndex, listIndex, direction)
  ScrollBase(ListboxElements[tabIndex], listIndex, direction)
end

-----------------
-- Parent listbox
-----------------
-- select parent list element
function SetParentListBoxIndex(tabIndex, selectedElement)
  GUI.Val(TabParentListBox[tabIndex], {[selectedElement] = true})
  TabParentSelectionIndex[tabIndex] = selectedElement

  local ParentListBoxItems = {
    nil,
    GUI.elms.tab_projectTemplates_subfolders.list,
    GUI.elms.tab_trackTemplates_subfolders.list,
    GUI.elms.tab_customProjects_subfolders.list,
    GUI.elms.tab_projectLists_listboxRPL.list,
    GUI.elms.tab_trackTemplates_subfolders.list,
    GUI.elms.tab_backups_subfolders.list,
  }

  local selectedList = ParentListBoxItems[tabIndex]
  local selectedFiles = GetFiles(selectedList[selectedElement])

  if tabIndex == 2 then UpdateProjectTemplateSubDirSelection(selectedFiles) end
  if tabIndex == 3 then UpdateTrackTemplateSubDirSelection(selectedFiles) end
  if tabIndex == 4 then UpdateCustomProjectSubDirSelection(selectedFiles) end
  if tabIndex == 5 then FillProjectListBox(selectedFiles) end
  if tabIndex == 6 then UpdateBackupsSubDirSelection(selectedFiles) end
end

-- previous parent
function SelectPreviousParentIndex(tabIndex, listIndex)
  if listIndex - 1 > 0 then listIndex = listIndex - 1 end
  SetParentListBoxIndex(tabIndex, listIndex)
  ScrollParentListBox(tabIndex, listIndex, -1)
end

function RL_Keys_ListboxSelectPreviousParent(currentTab)
  if TabParentSelectionIndex[currentTab] ~= nil and currentTab > 1 and currentTab < #MainTabs - 1 then
    SelectPreviousParentIndex(currentTab, TabParentSelectionIndex[currentTab])
  end
end

-- next parent
function SelectNextParentIndex(tabIndex, listIndex)
  local ParentListBoxItems = {
    nil,
    GUI.elms.tab_projectTemplates_subfolders.list,
    GUI.elms.tab_trackTemplates_subfolders.list,
    GUI.elms.tab_customProjects_subfolders.list,
    GUI.elms.tab_projectLists_listboxRPL.list,
    GUI.elms.tab_backups_subfolders.list,
  }

  if listIndex + 1 <= #ParentListBoxItems[tabIndex] then listIndex = listIndex + 1 end
  SetParentListBoxIndex(tabIndex, listIndex)
  ScrollParentListBox(tabIndex, listIndex, 1)
end

function RL_Keys_ListboxSelectNextParent(currentTab)
  if TabParentSelectionIndex[currentTab] ~= nil and currentTab > 1 and currentTab < #MainTabs - 1 then
    SelectNextParentIndex(currentTab, TabParentSelectionIndex[currentTab])
  end
end

------------------
-- Default listbox
------------------
-- select list element
function SetListBoxIndex(tabIndex, selectedElement)
  GUI.Val(TabListBox[tabIndex], {[selectedElement] = true})
  TabSelectionIndex[tabIndex] = selectedElement
  if GUI.JSAPI() then AudioPreviewCheckForFile() end
end

-- previous default
function SelectPreviousIndex(tabIndex, listIndex)
  if listIndex - 1 > 0 then listIndex = listIndex - 1 end
  SetListBoxIndex(tabIndex, listIndex)
  ScrollListBox(tabIndex, listIndex, -1)
end

function RL_Keys_ListboxSelectPrevious(currentTab)
  if TabSelectionIndex[currentTab] ~= nil and currentTab < #MainTabs - 1 then 
    SelectPreviousIndex(currentTab, TabSelectionIndex[currentTab])
  end
end

-- next default
function SelectNextIndex(tabIndex, listIndex)
  local ListBoxItems = {
    GUI.elms.tab_recentProjects_listbox.list,
    GUI.elms.tab_projectTemplates_listbox.list,
    GUI.elms.tab_trackTemplates_listbox.list,
    GUI.elms.tab_customProjects_listbox.list,
    GUI.elms.tab_projectLists_listboxProjects.list,
    GUI.elms.tab_backups_listbox.list,
  }

  if listIndex + 1 <= #ListBoxItems[tabIndex] then listIndex = listIndex + 1 end
  SetListBoxIndex(tabIndex, listIndex)
  ScrollListBox(tabIndex, listIndex, 1)
end

function RL_Keys_ListboxSelectNext(currentTab)
  if TabSelectionIndex[currentTab] ~= nil and currentTab < #MainTabs - 1 then
    SelectNextIndex(currentTab, TabSelectionIndex[currentTab])
  end
end

--------------------------------
-- Load/Refresh helper functions
--------------------------------
RL_Func_LoadElement = {
  [1] = { call = function() Load_RecentProject() end },
  [2] = { call = function() Load_ProjectTemplate() end },
  [3] = { call = function() Load_TrackTemplate() end },
  [4] = { call = function() Load_CustomProject() end },
  [5] = { call = function() Load_ProjectListProject() end },
  [6] = { call = function() Load_BackupFile() end },
}

RL_Func_LoadElementInTab = {
  [1] = { call = function() LoadInTab_RecentProject() end },
  [2] = { call = function() LoadInTab_ProjectTemplate() end },
  [3] = { call = function() LoadInTab_TrackTemplate() end },
  [4] = { call = function() LoadInTab_CustomProject() end },
  [5] = { call = function() LoadInTab_ProjectListProject() end },
  [6] = { call = function() LoadInTab_BackupFile() end }
}

RL_Func_TabRefresh = {
  [1] = { call = function() RefreshRecentProjects() end },
  [2] = { call = function() RefreshProjectTemplates() end },
  [3] = { call = function() RefreshTrackTemplates() end },
  [4] = { call = function() RefreshCustomProjects() end },
  [5] = { call = function() RefreshProjectList() end },
  [6] = { call = function() RefreshBackups() end }
}
----------------
-- Tab Selection
----------------
function RL_Keys_SelectTabPrev()
  local currentTab = RL_GetFocusedTab()
  if currentTab > 1 then RL_SetFocusedTab(currentTab - 1) end
end

function RL_Keys_SelectTabNext()
  local currentTab = RL_GetFocusedTab()
  if currentTab < #MainTabs then RL_SetFocusedTab(currentTab + 1) end
end

function RL_Keys_SelectTabDirectly(keyInput)
  if keyInput == GUI.chars.N1 then RL_SetFocusedTab(1)
    elseif keyInput == GUI.chars.N2 then RL_SetFocusedTab(2) -- recent projects
    elseif keyInput == GUI.chars.N3 then RL_SetFocusedTab(3) -- project templates
    elseif keyInput == GUI.chars.N4 then RL_SetFocusedTab(4) -- track templates
    elseif keyInput == GUI.chars.N5 then RL_SetFocusedTab(5) -- custom projects
    elseif keyInput == GUI.chars.N6 then RL_SetFocusedTab(6) -- backups
    elseif keyInput == GUI.chars.F1 then RL_SetFocusedTab(8) -- help
    elseif keyInput == GUI.chars.F2 then RL_SetFocusedTab(7) -- options
  end
end

---------------
-- filter focus
---------------
function RL_Keys_FocusFilter(currentTab)
  IsKeyInputCheckActive = false
  TabFilter[currentTab].focus = true
 end

----------------------------
-- Key Input - Main function
----------------------------
IsKeyInputCheckActive = true

function RL_Keys_CheckModifiers()
  local modifierKey = GUI.modifier.NONE
  if GUI.mouse.cap & 4 == 4 then modifierKey = GUI.modifier.CTRL
    elseif GUI.mouse.cap & 8 == 8 then modifierKey = GUI.modifier.SHIFT
    elseif GUI.mouse.cap & 16 == 16 then modifierKey = GUI.modifier.ALT
  end
  return modifierKey
end

function RL_Keys_CheckInput()
  if IsKeyInputCheckActive then
    local currentTab = RL_GetFocusedTab()
    local modifier = RL_Keys_CheckModifiers()
    local inputChar = gfx.getchar()
    --if inputChar > 0 then MsgDebug("key: " .. inputChar) end

    -- close the window when esc key is pressed or close function is called
    if inputChar == GUI.chars.ESC or inputChar == -1 or GUI.quit == true then return 0
      -- prev/next tab
      elseif inputChar == GUI.chars.LEFT then RL_Keys_SelectTabPrev()
      elseif inputChar == GUI.chars.RIGHT then RL_Keys_SelectTabNext()
      -- parent and child listbox selection
      elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.UP then RL_Keys_ListboxSelectPreviousParent(currentTab)
      elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.UP then RL_Keys_ListboxSelectPrevious(currentTab)
      elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.DOWN then RL_Keys_ListboxSelectNextParent(currentTab)
      elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.DOWN then RL_Keys_ListboxSelectNext(currentTab)
      -- refresh
      elseif inputChar == GUI.chars.F5 and RL_GetFocusedTab() < (#MainTabs - 1) then RL_Func_TabRefresh[RL_GetFocusedTab()].call() 
      -- global buttons
      elseif inputChar == GUI.chars.TAB then RL_Keys_FocusFilter(currentTab) 
      elseif inputChar == GUI.chars.P then Global_TogglePaths() 
      elseif inputChar == GUI.chars.W then Global_ToggleWindowPinState() 
      elseif inputChar == GUI.chars.S then Global_OpenInExplorer() 
      elseif inputChar == GUI.chars.O then Global_ShowProjectOpenDialog() 
      elseif inputChar == GUI.chars.N then Global_NewProject()
      elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.T or inputChar == GUI.chars.PLUS then Global_NewTab() 
      elseif inputChar == GUI.chars.DIVIDE then Global_NewTabIgnoreTemplate()
      -- close and select prev/next project tab
      elseif inputChar == GUI.chars.X then Global_ProjectTabPrev()
      elseif inputChar == GUI.chars.V then Global_ProjectTabNext()
      elseif inputChar == GUI.chars.C or inputChar == GUI.chars.MINUS then Global_CurrentTabClose() 
      -- loading
      elseif modifier == GUI.modifier.SHIFT and inputChar == GUI.chars.RETURN and RL_GetFocusedTab() < (#MainTabs - 1) then RL_Func_LoadElementInTab[currentTab].call()  
      elseif modifier == GUI.modifier.NONE and inputChar == GUI.chars.RETURN and RL_GetFocusedTab() < (#MainTabs - 1) then RL_Func_LoadElement[currentTab].call()  
    end
    
    RL_Keys_SelectTabDirectly(inputChar)
    
    -- audio preview
    if GUI.JSAPI() then
       if inputChar == GUI.chars.SPACE or inputChar == GUI.chars.MULTIPLY then AudioPreviewToggleState() end
    end
  end
  reaper.defer(RL_Keys_CheckInput)
end

-----------------
-- Main functions
------------------
function RL_CleanupAtExit()
  if GUI.JSAPI() then AudioPreviewStopAll() end
end

reaper.atexit(function ()
  RL_ExtStates_Save()
  RL_CleanupAtExit()
end)

local function ResizeInit(wx, wy)
  gfx.quit()
  gfx.init(GUI.name, GUI.w, GUI.h, 0, wx, wy)
  GUI.redraw_z[0] = true 
end

GUI.onresize = function()
  local currentTab = RL_GetFocusedTab()
  local dock_state,wx,wy,ww,wh = gfx.dock(-1,0,0,0,0)
  GUI.w = ww
  GUI.h = wh
  RL_SetWindowParameters()
  RL_RedrawAll()
  RL_ExtStates_Load()
  RL_SetFocusedTab(currentTab)
  -- check for minimum window size
  if GUI.w < 610 then
    GUI.w = 610
    ResizeInit(wx, wy)
  end
  if GUI.h < 480 then
    GUI.h = 480
    ResizeInit(wx, wy)
  end
end

GUI.Init() 
RL_ExtStates_Load()
RL_Keys_CheckInput()

GUI.func = Main
GUI.freq = 0
GUI.Main()

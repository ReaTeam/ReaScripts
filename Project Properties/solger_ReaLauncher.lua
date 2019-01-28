-- @description ReaLauncher
-- @author solger
-- @version 1.0
-- @changelog
--   + Filter: Added support for using multiple search words (separated with a 'space' character)
--   + General code refactoring and improvements
--   + [Project Templates]: Added 'Edit Template Mode' checkbox - if not checked, the 'Save As' window is shown when loading
--   + [Project Lists]: First implementation of (SWS Project List) .RPL file loading support
--   + [Recent Projects]: Duplicate recent project entries are now added only once to the list
--   + [Recent Projects]: Added Right-click menu options 'Remove entry' and 'Clear list'
--   + [Recent Projects]: First implementation of subversion filter (support for file namings with a hyphen or underscore like 'project name-number' or 'project name_number')
--   + Theme Slots (requires SWS Extensions): Added option to switch between different Reaper Theme Slots
--   + Theme Slots (requires SWS Extensions): Option to assign a description to each Theme Slot
--   + Window resizing: Added minimum window size check (to prevent overlapping UI elements)
--   + Window resizing: now with instant update of the UI elements (no restart required anymore to see the changes)
--   + Window: Some general GUI adjustments
-- @screenshot https://forum.cockos.com/showthread.php?t=208697
-- @about
--   # ReaLauncher
--
--   A custom version of the startup prompt window for loading (recent) projects and project/track templates with additional features
--
--   ## Main features
--
--   - Separate tabs for Recent Projects, Project Templates, Track Templates, Projects and .RPL Project Lists
--   - Support for adding custom folder paths
--   - List filter at the top of each tab (supports multiple search words separated with a 'space' character)
--   - [Show in Explorer/Finder] button for browsing to the folder location of a selected file
--   - Global section with [New Tab], [New Project] and [Open Project] buttons
--   - Selection and loading of multiple entries (multi-select of listbox entries is already part of Lokasenna's GUI library)
--   - File paths can be shown/hidden
--   - 'Keep window open' checkbox
--   - Option to switch between Reaper Theme Slots
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
      reaper.ShowConsoleMsg( tostring(str) .. "\n" )
    end
end

local function MsgError(str)
  reaper.ShowMessageBox(tostring(str), "Error", 0)
end

local function MsgInfo(str)
  reaper.ShowMessageBox(tostring(str),"Info", 0)
end

local function MsgStatusBar(message)
  GUI.Val("main_statusbar", "|  " .. message)
  GUI.elms.main_statusbar:fade(6,1,12)
end

------------------------------------------
-- Reaper resource paths and version infos
------------------------------------------
appversion = "1.0"
appname = "solger_ReaLauncher"

osversion =  reaper.GetOS()
local bitversionFull = reaper.GetAppVersion()
bitversion = string.sub(bitversionFull, #bitversionFull-2, #bitversionFull)

reaperIniPath = reaper.get_ini_file()
resourcePath = reaper.GetResourcePath()
if (resourcePath == nil) then MsgError("Could not retrieve the Reaper resource path!") end

if osversion:find("Win") then
  -- Windows paths
  trackTemplatePath = resourcePath .. "\\TrackTemplates"
  projectTemplatePath = resourcePath .. "\\ProjectTemplates"
else
  -- macOS / Linux paths
  trackTemplatePath = resourcePath .. "/TrackTemplates"
  projectTemplatePath = resourcePath .. "/ProjectTemplates"
end

---------------------------------------------------------------------------------------
-- Lokasenna's GUI library v2: 'The Core library must be loaded prior to any classes,  
-- or the classes will throw up errors when they look for functions that aren't there.'
---------------------------------------------------------------------------------------
local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
  if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please run 'Set Lokasenna_GUI v2 library path.lua' in the Lokasenna_GUI folder.", "Whoops!", 0)
  return
end

loadfile(lib_path .. "Core.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Frame.lua")()
GUI.req("Classes/Class - Label.lua")()
GUI.req("Classes/Class - Listbox.lua")()
GUI.req("Classes/Class - Menubox.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Tabs.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Window.lua")()

if missing_lib then return 0 end -- If any of the requested libraries weren't found, abort the script.

-----------------------
-- SWS Extensions check
-----------------------
function GUI.SWS_exists()
  return reaper.APIExists("BR_Win32_GetPrivateProfileString")
end

-------------------------
-- Table helper functions
-------------------------
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
isNotMostRecent = true

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

---------------------
-- File I/O functions
---------------------
-- scan all subdirectories of a given path
-- Found this in the Reaper Forum. Thanks to mpl and Lokasenna :)
local function ScanPath(path)
    local tree = {}
    local subdirindex, fileindex = 0,0
    local path_child

    repeat
      path_child = reaper.EnumerateSubdirectories(path, subdirindex)
        if path_child then
          local tmpPath = ScanPath(path .. "\\" .. path_child)
            for i = 1, #tmpPath do
               table.insert(tree, tmpPath[i])
            end
       end
    subdirindex = subdirindex+1
    until not path_child

    repeat
      local fn = reaper.EnumerateFiles(path, fileindex)
        if fn then
         tree[#tree+1] = path .. "\\" .. fn
        end
      fileindex = fileindex + 1
    until not fn
    return tree
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

local function RemoveExtension_RTrackTemplate(filename)
  return string.sub(filename, 1, #filename - 15)
end

local function RemoveWhiteSpaces(s)
  return s:match( "^%s*(.-)%s*$" )
end

local function GetDirectoryPath(filepath)
  local index
  if osversion:find("Win") then index = (filepath:reverse()):find("%\\") -- Windows
    else index = (filepath:reverse()):find("%/") -- macOS / Linux
  end
  return string.sub(filepath, 1, #filepath-index)
end

local function GetFilenameWithoutPath(filepath)
  local filename
  if osversion:find("Win") then filename = filepath:match "([^\\]-([^.]+))$" -- Windows: get (filename.extension) substring
    else filename = filepath:match "([^/]-([^.]+))$" -- macOS / Linux: get (filename.extension) substring
  end
  return filename
end

-------------------------------------------------
-- Returns a table of files in the specified path
-- Adapted script from this thread: https://forum.cockos.com/showthread.php?t=206933
------------------------------------------------------------------------------------
local FileTypes = {rpp = ".RPP", rpl = ".RPL"}

local function GetFiles(path)
  local files = {}

  if osversion:find("Win") then
    -- Windows
    if bitversion == 'x64' then
      -- Windows (Reaper 64-bit)
      for file in io.popen([[dir "]] .. path .. [[" /a:-d /s /b | sort]]):lines() do
        files[#files + 1] = file
      end
    else
      -- Windows (Reaper 32-bit)
      -- files = EnumerateFiles(path)
      files = ScanPath(path)
    end
    MsgDebug("Get Files (" .. path .. ")\n------\n" .. table.concat(files,"\n").."\n")
  else
    -- macOS / Linux
    for file in io.popen([[find ]] .. path .. [[ -maxdepth 3 -type f -not -name '.*' -not -name '*.reapeaks' -not -name '*.wav']]):lines() do
      files[#files + 1] = file
    end
  end
  return files
end

----------------------------------------------------
-- Return files of a specific type from a given path
----------------------------------------------------
local function GetFilesFromDir(path, type)
  local files = {}

  for file in io.popen([[dir "]] .. path .. [[" /a:-d /s /b | sort]]):lines() do
    local fileExtension = string.sub(file,#file-3,#file)
      if string.find(fileExtension, FilterNoCase(type)) then
        files[#files + 1] = file
      end
    end
    MsgDebug("Get " .. type .. " Files (" .. path .. ")\n------\n" .. table.concat(files,"\n").."\n")
  return files
end

------------------------------------------
-- Open the folder path in Explorer/Finder
------------------------------------------
function ShowLocationInExplorer(path)
  if osversion:find("OSX") then
      os.execute('open "" "' .. path .. '"') -- macOS
  elseif osversion:find("Win") then
      os.execute('start "" "' .. path .. '"') -- Windows
  else
    os.execute('xdg-open \"' .. path .. '\"') -- Linux
  end
end

---------------------------------------------
-- Show in Explorer/Finder - Helper functions
---------------------------------------------
-- recent projects
function ShowLocation_RecentProject()
  if (noRecentProjects == false) then
  local selectedProject
  local vals = GetSelectionTable(GUI.Val("tab1_listbox_recentProjects"))

  if #vals == 0 then MsgStatusBar("No files selected in the list!")
    else
      for p = 1, #vals do
        if FilterActive_RecentProjects == true then selectedProject = RecentProjects.items[RecentProjects.filteredNames[vals[p]]]
        else selectedProject = RecentProjects.items[RecentProjects.names[vals[p]]] end
        ShowLocationInExplorer(GetDirectoryPath(selectedProject))
      end
    end
  end
end

-- project templates
function ShowLocation_ProjectTemplates()
  if (noProjectTemplates == false) then
    local selectedProjectTemplate
    local vals = GetSelectionTable(GUI.Val("tab2_listbox_projectTemplates"))

    if #vals == 0 then ShowLocationInExplorer(projectTemplatePath)
      else
     for p = 1, #vals do
        if FilterActive_ProjectTemplates == true then selectedProjectTemplate = ProjectTemplates.items[ProjectTemplates.filteredNames[vals[p]]]
        else selectedProjectTemplate = ProjectTemplates.items[ProjectTemplates.names[vals[p]]] end
        ShowLocationInExplorer(GetDirectoryPath(selectedProjectTemplate))
      end
    end
    else
      ShowLocationInExplorer(projectTemplatePath)
  end
end

-- track templates
function ShowLocation_TrackTemplates()
  if (noTrackTemplates == false) then
    local selectedTrackTemplate
    local vals = GetSelectionTable(GUI.Val("tab3_listbox_trackTemplates"))

    if #vals == 0 then ShowLocationInExplorer(trackTemplatePath)
    else
      for p = 1, #vals do
        if FilterActive_TrackTemplates == true then selectedTrackTemplate = TrackTemplates.items[TrackTemplates.filteredNames[vals[p]]]
        else selectedTrackTemplate = TrackTemplates.items[TrackTemplates.names[vals[p]]] end
          ShowLocationInExplorer(GetDirectoryPath(selectedTrackTemplate))
        end
     end
   else
    ShowLocationInExplorer(trackTemplatePath)
  end
end

-- custom projects
function ShowLocation_CustomProject()
  local vals = GetSelectionTable(GUI.Val("tab4_listbox_customProjects"))
    if #vals == 0 then
      if GUI.Val("options_textbox_customProjects_path") == "" then MsgStatusBar("No files selected in the list!")
      else
        ShowLocationInExplorer(GUI.Val("options_textbox_customProjects_path"))
      end
    else
      for p = 1, #vals do
        if FilterActive_CustomProjects == true then selectedProject = CustomProjects.items[CustomProjects.filteredNames[vals[p]]]
        else selectedProject = CustomProjects.items[CustomProjects.names[vals[p]]] end
      ShowLocationInExplorer(GetDirectoryPath(selectedProject))
    end
  end
end

-- project lists
function ShowLocation_ProjectList()
  local vals = GetSelectionTable(GUI.Val("tab5_listbox_rplProjects"))
    
  if #vals == 0 then
      if GUI.Val("options_textbox_projectsLists_path") == "" then MsgStatusBar("No files selected in the list!")
      else
        ShowLocationInExplorer(GUI.Val("options_textbox_projectsLists_path"))
      end
    else
     for p = 1, #vals do
      if FilterActive_ProjectLists then selectedProject = ProjectLists.filteredProjectPaths[vals[p]]
      else selectedProject = ProjectLists.projectPaths[vals[p]] end
      ShowLocationInExplorer(GetDirectoryPath(selectedProject))
    end
  end
end

---------------------------
-- Show in Explorer - relay
---------------------------
local function OpenInExplorer()  
  local tabfocus = GUI.Val("main_tabs") 
  if tabfocus == 1 then ShowLocation_RecentProject() end
  if tabfocus == 2 then ShowLocation_ProjectTemplates() end
  if tabfocus == 3 then ShowLocation_TrackTemplates()  end
  if tabfocus == 4 then ShowLocation_CustomProject() end
  if tabfocus == 5 then ShowLocation_ProjectList() end
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
local function HidePaths()
  GUI.Val("main_menubox_paths", {1})
end

function UpdatePathDisplayMode()
  local pathMode = GUI.Val("main_menubox_paths")
  if pathMode == 1 then
    -- hide paths
    showFullPaths = false

    if FilterActive_RecentProjects then GUI.elms.tab1_listbox_recentProjects.list = RecentProjects.filteredNames
    else
       if FilterActive_RecentSubversions then
        GUI.elms.tab1_listbox_recentProjects.list = RecentProjects.subversionNames
       else
        GUI.elms.tab1_listbox_recentProjects.list = RecentProjects.names
      end
    end
   
    if FilterActive_ProjectTemplates then  GUI.elms.tab2_listbox_projectTemplates.list = ProjectTemplates.filteredNames
    else GUI.elms.tab2_listbox_projectTemplates.list = ProjectTemplates.names end

    if FilterActive_TrackTemplates then GUI.elms.tab3_listbox_trackTemplates.list = TrackTemplates.filteredNames
    else GUI.elms.tab3_listbox_trackTemplates.list = TrackTemplates.names end

    if FilterActive_CustomProjects then GUI.elms.tab4_listbox_customProjects.list = CustomProjects.filteredNames
    else GUI.elms.tab4_listbox_customProjects.list = CustomProjects.names end

    if FilterActive_ProjectLists then GUI.elms.tab5_listbox_rplProjects.list = ProjectLists.filteredProjectNames
    else GUI.elms.tab5_listbox_rplProjects.list = ProjectLists.projectNames end

  else 
    -- show paths
    showFullPaths = true

    if FilterActive_RecentProjects then GUI.elms.tab1_listbox_recentProjects.list = RecentProjects.filteredPaths
    else
      if FilterActive_RecentSubversions then
        GUI.elms.tab1_listbox_recentProjects.list = RecentProjects.subversionPaths
      else
        GUI.elms.tab1_listbox_recentProjects.list = RecentProjects.paths
      end
    end
    
    if FilterActive_ProjectTemplates then GUI.elms.tab2_listbox_projectTemplates.list = ProjectTemplates.filteredPaths
    else GUI.elms.tab2_listbox_projectTemplates.list = ProjectTemplates.paths end

    if FilterActive_TrackTemplates then GUI.elms.tab3_listbox_trackTemplates.list = TrackTemplates.filteredPaths
    else GUI.elms.tab3_listbox_trackTemplates.list = TrackTemplates.paths end

    if FilterActive_CustomProjects then GUI.elms.tab4_listbox_customProjects.list = CustomProjects.filteredPaths
    else GUI.elms.tab4_listbox_customProjects.list = CustomProjects.paths end
    
    if FilterActive_ProjectLists then GUI.elms.tab5_listbox_rplProjects.list = ProjectLists.filteredProjectPaths
    else GUI.elms.tab5_listbox_rplProjects.list = ProjectLists.projectPaths end

  end
  
  GUI.elms.tab1_listbox_recentProjects:redraw()
  GUI.elms.tab2_listbox_projectTemplates:redraw()
  GUI.elms.tab3_listbox_trackTemplates:redraw()
  GUI.elms.tab4_listbox_customProjects:redraw()
  GUI.elms.tab5_listbox_rplProjects:redraw()
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
  subversionNames = {},
  subversionPaths = {}
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

-- recent project listbox
function FillRecentProjectsListbox()
  MsgDebug("Get Recent Files: \n------")
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
    
    if GetReaperIniKeyValue(recentpathtag[p]) == nil   then
      found = true
      break 
    else
      local fullPath = GetReaperIniKeyValue(recentpathtag[p])
      local filename = GetFilenameWithoutPath(fullPath)

      if (CheckForDuplicates(RecentProjects.paths, fullPath) == false and fullPath ~= "removed") then
        e = e + 1    
        RecentProjects.paths[e] = fullPath
        RecentProjects.names[e] = RemoveExtension_RPP(filename)  
      end
      
      MsgDebug(fullPath)
    end
  until (found == true)

  if #RecentProjects.names == 0 then noRecentProjects = true
  else 
    noRecentProjects = false  
    for i = 1, #RecentProjects.names do
      RecentProjects.items[RecentProjects.names[i]] = RecentProjects.paths[i]
    end
  end
  MsgDebug("\n")
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

local function FillProjectTemplateListbox()
  ProjectTemplates.items = {}
  ProjectTemplates.names = {}
  ProjectTemplates.paths = {}
  
  ProjectTemplates.paths = GetFiles(projectTemplatePath)
  local tempPath = reaper.GetExtState(appname, "custompath_projecttemplates")
  if #tempPath > 1 then
    JoinTables(ProjectTemplates.paths, GetFiles(tempPath))
  end

  if #ProjectTemplates.paths == 0 then noProjectTemplates = true
  else
    noProjectTemplates = false  

    for i = 1, #ProjectTemplates.paths do
      local filename = GetFilenameWithoutPath(ProjectTemplates.paths[i])
      ProjectTemplates.names[i] = RemoveExtension_RPL(filename)
      -- handling of .RPP-bak files
      if string.sub(filename, #filename-3, #filename) == "-bak" then
        ProjectTemplates.names[i] = string.sub(filename,1,#filename-8) .. "  (.rpp-bak file)"
      else
        ProjectTemplates.items[ProjectTemplates.names[i]] = ProjectTemplates.paths[i]
      end
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
  filteredNames = {},
  filteredPaths = {}
}

local function FillTrackTemplateListbox()
  TrackTemplates.items = {}
  TrackTemplates.names = {}
  TrackTemplates.paths = {}

  TrackTemplates.paths = GetFiles(trackTemplatePath)
  
  local tempPath = reaper.GetExtState(appname, "custompath_tracktemplates")
  if #tempPath > 1 then 
    local customTrackTemplateFiles= GetFiles(tempPath)
    JoinTables(TrackTemplates.paths, customTrackTemplateFiles)
  end
  
    if #TrackTemplates.paths == 0 then noTrackTemplates = true
    else
      noTrackTemplates = false  
    
      for i = 1 , #TrackTemplates.paths do
        TrackTemplates.names[i] = RemoveExtension_RTrackTemplate(GetFilenameWithoutPath(TrackTemplates.paths[i]))
        TrackTemplates.items[TrackTemplates.names[i]] = TrackTemplates.paths[i]
       end
    end
end

----------------------------------------------------------------
-- Filter out latest project version files (if subversion exist)
----------------------------------------------------------------
SubversionDefaults = {}
SubversionNumbers = {
  name = {},
  indexType = {}
}

-- store highest subversion number of a project file
function InsertFileWithHighestSubversion(matchFilename, matchFileversion, indexType)
  local lastversion = SubversionNumbers.name[matchFilename]
  if (lastversion == nil) then lastversion = 0 end 

  if (tonumber(lastversion) < tonumber(matchFileversion)) then
    SubversionNumbers.name[matchFilename] = matchFileversion
    SubversionNumbers.indexType[matchFilename] = indexType
  end 
end

function SplitProjectNameAt(matchString, indexType, indexPosition)
  matchFilename = string.sub(matchString, 0, #matchString - indexPosition)
  matchFileversion = string.sub(matchString, #matchString - indexPosition + 2, #matchString)
  InsertFileWithHighestSubversion(matchFilename, matchFileversion, indexType)
end

-- check project names for subversion
function CheckSubversionIndices(matchString)
  indexHyphen = matchString:reverse():find("-%d")  
  indexUnderscore = matchString:reverse():find("_%d")

  if indexHyphen == nil and indexUnderscore == nil then
    SubversionDefaults[matchString] = 'nosubversion'
  else
    if indexHyphen == nil then indexHyphen = 999 end
    if indexUnderscore == nil then indexUnderscore = 999 end

    if indexHyphen < indexUnderscore then SplitProjectNameAt(matchString, 0, indexHyphen)
    else SplitProjectNameAt(matchString, 1, indexUnderscore) end
  end
end

-- filter only project subversions with the highest number
function CheckFilesForSubversions(table)
  SubversionNumbers.name = {}
  SubversionNumbers.indexType = {}
  SubversionDefaults = {}
  
  RecentProjects.subversionNames = {}
  RecentProjects.subversionPaths = {}

  for i = 1, #table do
    CheckSubversionIndices(table[i])
  end

    -- get the files with a version number
  local p = 1
  for key,val in pairs(SubversionNumbers.name) do
    if (SubversionNumbers.indexType[key] == 0) then
      RecentProjects.subversionNames[p] = key .. "-" .. val
    else
      RecentProjects.subversionNames[p] = key .. "_" .. val
    end
    RecentProjects.subversionPaths[p] = RecentProjects.items[RecentProjects.subversionNames[p]]
    p = p + 1
  end

  -- get the files without a version number
  for key,val in pairs(SubversionDefaults) do
       RecentProjects.subversionNames[p] = key
       RecentProjects.subversionPaths[p] = RecentProjects.items[RecentProjects.subversionNames[p]]
       p = p + 1
  end

end

-- update the recent project tab list depending on the fileNumberFilter box value
function UpdateSubversionFilter()
  local subversionFilterState = GUI.Val("tab1_checklist_subversionFilter")
  if subversionFilterState == true then
    FilterActive_RecentSubversions = true
  else 
    FilterActive_RecentSubversions = false
    CheckFilesForSubversions(RecentProjects.names)
  end
  UpdatePathDisplayMode()
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

local function FillCustomProjectsListbox()
  CustomProjects.names = {}
  CustomProjects.items = {}
  pos = 1
  
  if #custom_path_projects > 1 then
    
   if (osversion:find("Win")) and (bitversion == "x64") then
      --CustomProjects.paths = GetRPPFiles(custom_path_projects)
      CustomProjects.paths = GetFilesFromDir(custom_path_projects, FileTypes.rpp)
   else
      CustomProjects.paths = GetFiles(custom_path_projects)
   end
  
     for i = 1, #CustomProjects.paths do
        local filename = GetFilenameWithoutPath(CustomProjects.paths[i])

        local fileExtension = string.sub(filename,#filename-3,#filename)
        if string.find(fileExtension, FilterNoCase(".RPP"))  then
          CustomProjects.names[pos] = RemoveExtension_RPP(filename)
          CustomProjects.items[CustomProjects.names[pos]] = CustomProjects.paths[i]
          pos = pos + 1
        end
  
        local bakExtension = string.sub(filename,#filename-4,#filename)
        if string.find(bakExtension, FilterNoCase("-BAK")) then
          CustomProjects.names[pos] =  string.sub(filename,1,#filename-8) .. "  (.rpp-bak file)"
          CustomProjects.items[CustomProjects.names[pos]] = CustomProjects.paths[i]
          pos = pos + 1
        end
     end
  end
end

-----------------------
-- Project Lists Listbox
-----------------------
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
  rplfolder = reaper.GetExtState(appname, "custompath_projectlists")
  
  local projectListFiles = {}
  pos = 1

  if #custom_path_projectlists > 1 then
  
    if (osversion:find("Win")) and (bitversion == "x64") then
      projectListFiles = GetFilesFromDir(rplfolder, FileTypes.rpl)
    else
      projectListFiles = GetFiles(rplfolder)
    end
   
    for i = 1, #projectListFiles do
      local filename = GetFilenameWithoutPath(projectListFiles[i])
      local fileExtension = string.sub(filename,#filename-3,#filename)
        if string.find(fileExtension, FilterNoCase(".RPL"))  then
         ProjectLists.rplFiles[pos] = RemoveExtension_RPL(filename)
          pos = pos + 1
        end
    end
  end
end

function ParseRPLFile(selected)
  ProjectLists.projectNames = {}
  ProjectLists.projectPaths = {} 
  ProjectLists.projectItems = {} 

  for i = 1, #selected do
    local rplFile = rplfolder .. "/" .. ProjectLists.rplFiles[selected[i]] .. ".RPL"
    local file = io.open(rplFile, "rb") 
    if not file then return nil end

    for line in file:lines() do table.insert(ProjectLists.projectPaths, line) end
    file:close()
  end

  for i = 1, #ProjectLists.projectPaths do
      local filename = RemoveWhiteSpaces(GetFilenameWithoutPath(ProjectLists.projectPaths[i]))
      table.insert(ProjectLists.projectNames, RemoveExtension_RPL(filename))
      ProjectLists.projectItems[ProjectLists.projectNames[i]] = ProjectLists.projectPaths[i]
  end

   GUI.elms.tab5_listbox_rplProjects.list = ProjectLists.projectNames
end

function FillProjectListBox()
  local vals = GetSelectionTable(GUI.Val("tab5_listbox_rplFiles"))
  if #GUI.elms.tab5_listbox_rplFiles.list > 0 then ParseRPLFile(vals) end
  UpdatePathDisplayMode()
end

function Refresh_ProjectList()
  FillProjectListSelector()
  GUI.elms.tab5_listbox_rplFiles.list = ProjectLists.rplFiles
  UpdatePathDisplayMode()
end

----------------------------------
-- Fill the listboxes with entries
----------------------------------
FillRecentProjectsListbox()
FillTrackTemplateListbox()
FillProjectTemplateListbox()

custom_path_projects = reaper.GetExtState(appname, "custompath_projects")
custom_path_projectlists = reaper.GetExtState(appname, "custompath_projectlists")
FillCustomProjectsListbox()

-----------------------------------
-- New project/tab button functions
-----------------------------------
local function CheckWindowPinState()
  if GUI.Val("main_checklist_windowpin") == false then gfx.quit() end
end

local function Project_New()
  reaper.Main_OnCommand(40023, 0)
  CheckWindowPinState() 
end

local function Project_NewTab()
  reaper.Main_OnCommand(40859, 0)
  CheckWindowPinState() 
end

local function Project_NewTab_IgnoreTemplate()
  reaper.Main_OnCommand(41929, 0)
  CheckWindowPinState()
end

local function Project_OpenDialog()
  reaper.Main_OnCommand(40025, 0)
  CheckWindowPinState()
end

local function Project_Load(project, projectCount)
  -- if more than 1 project is selected, load the other projects in a tab
  if projectCount > 1 then
    reaper.Main_OnCommand(40859, 0)
    reaper.Main_openProject(project) 
  else
    reaper.Main_openProject(project) 
  end
end

local function Project_LoadInTab(project)
  reaper.Main_OnCommand(40859, 0)
  reaper.Main_openProject(project) 
end

-- helper function for loading project templates
local function Load_ProjectTemplate_As_Base()
  if projectTemplateLoadMode == 1 then
    reaper.Main_OnCommand(40022,0) -- Save project as dialog
  end
end

local function ProjectTemplate_Load(template, templateCount)
-- if more than 1 project is selected, load the other projects in a tab 
  if templateCount > 1 then reaper.Main_OnCommand(40859, 0) end
  reaper.Main_openProject(selectedProjectTemplate) 
  Load_ProjectTemplate_As_Base()
end

local function ProjectProjectTemplate_LoadInTab(template)
  reaper.Main_OnCommand(40859, 0)
  reaper.Main_openProject(selectedProjectTemplate) 
  Load_ProjectTemplate_As_Base()
end

----------------------------------
-- Recent project button functions
----------------------------------
-- load recent projects
local function Load_RecentProject()
  if (noRecentProjects == false) then
    local vals = GetSelectionTable(GUI.Val("tab1_listbox_recentProjects"))
    
    for p = 1, #vals do
      if FilterActive_RecentProjects == true then selectedProject = RecentProjects.items[RecentProjects.filteredNames[vals[p]]]
      else 
        if FilterActive_RecentSubversions then selectedProject = RecentProjects.items[RecentProjects.subversionNames[vals[p]]]
        else 
          selectedProject = RecentProjects.items[RecentProjects.names[vals[p]]]
        end
      end
      Project_Load(selectedProject, p)
    end
      
    GUI.Val("tab1_listbox_recentProjects",{})
    CheckWindowPinState()
  end
end

-- load recent projects in tab
local function LoadInTab_RecentProject()
  if (noRecentProjects == false) then
    local vals = GetSelectionTable(GUI.Val("tab1_listbox_recentProjects"))
    
    for p = 1, #vals do
      if FilterActive_RecentProjects == true then selectedProject = RecentProjects.items[RecentProjects.filteredNames[vals[p]]]
      else selectedProject = RecentProjects.items[RecentProjects.names[vals[p]]] end
      Project_LoadInTab(selectedProject)
    end

    GUI.Val("tab1_listbox_recentProjects",{})
    CheckWindowPinState()
  end
end

----------------------------------
-- Custom project button functions
----------------------------------
local function Load_CustomProject_Base(tabmode)
  local vals = GetSelectionTable(GUI.Val("tab4_listbox_customProjects"))
  for p = 1, #vals do
    if FilterActive_CustomProjects == true then selectedProject = CustomProjects.items[CustomProjects.filteredNames[vals[p]]]
    else selectedProject = CustomProjects.items[CustomProjects.names[vals[p]]] end
    
    if tabmode == true then Project_LoadInTab(selectedProject)
    else Project_Load(selectedProject, p) end
  end
  
  GUI.Val("tab4_listbox_customProjects",{})
  CheckWindowPinState()
end

-- load custom projects
local function Load_CustomProject()
  Load_CustomProject_Base(false)
end

-- load custom projects in tab
local  function LoadInTab_CustomProject()
  Load_CustomProject_Base(true)
end

---------------------------
-- Project Template buttons
---------------------------
local function Load_ProjectTemplate_Base(tabmode)
  if (noProjectTemplates == false) then
    local vals = GetSelectionTable(GUI.Val("tab2_listbox_projectTemplates"))

    for p = 1, #vals do 
      if FilterActive_ProjectTemplates == true then selectedProjectTemplate = ProjectTemplates.items[ProjectTemplates.filteredNames[vals[p]]]
      else selectedProjectTemplate =  ProjectTemplates.items[ProjectTemplates.names[vals[p]]] end
      
      if tabmode == true then ProjectProjectTemplate_LoadInTab(selectedProjectTemplate)
      else ProjectTemplate_Load(selectedProjectTemplate, p) end
  end  
    CheckWindowPinState()
  end
end

-- load project templates
local function Load_ProjectTemplate()
  Load_ProjectTemplate_Base(false)
end

-- load project templates in tab
local function LoadInTab_ProjectTemplate()
  Load_ProjectTemplate_Base(true)
end

----------------------------------
-- Track Template button functions
----------------------------------
 local function Load_TrackTemplate()
  if (noTrackTemplates == false) then
    local vals = GetSelectionTable(GUI.Val("tab3_listbox_trackTemplates"))
    for p = 1, #vals do
      if FilterActive_TrackTemplates == true then selectedTrackTemplate = TrackTemplates.items[TrackTemplates.filteredNames[vals[p]]]
      else selectedTrackTemplate = TrackTemplates.items[TrackTemplates.names[vals[p]]] end
      reaper.Main_openProject(selectedTrackTemplate) 
    end 
    CheckWindowPinState()
  end
end  

--------------------------------
-- Project List button functions
--------------------------------
local function Load_ProjectListProject_Base(tabmode)
  local vals = GetSelectionTable(GUI.Val("tab5_listbox_rplProjects"))
  for p = 1, #vals do
    if FilterActive_ProjectLists then selectedProjectListProject = RemoveWhiteSpaces(ProjectLists.filteredProjectPaths[vals[p]])
    else selectedProjectListProject = RemoveWhiteSpaces(ProjectLists.projectPaths[vals[p]]) end

    if tabmode == true then Project_LoadInTab(selectedProjectListProject)
    else Project_Load(selectedProjectListProject, p) end
  end
  
  GUI.Val("tab5_listbox_rplProjects",{})
  CheckWindowPinState()
end

local function Load_ProjectListProject()
  Load_ProjectListProject_Base(false)
end  

-- load project list project in tab
local function LoadInTab_ProjectListProject()
  Load_ProjectListProject_Base(true)
end

--------------------------
-- Filter update functions
--------------------------
-- Recent Projects tab
local function UpdateListFilter_RecentProjects()
  if FilterActive_RecentProjects then
    GUI.elms.tab1_listbox_recentProjects.list = RecentProjects.filteredNames
  else
    GUI.elms.tab1_listbox_recentProjects.list = RecentProjects.names
  end
end

-- Project Templates tab
local function UpdateListFilter_ProjectTemplates()
  if FilterActive_ProjectTemplates then
    GUI.elms.tab2_listbox_projectTemplates.list = ProjectTemplates.filteredNames
  else
    GUI.elms.tab2_listbox_projectTemplates.list = ProjectTemplates.names 
  end
end

-- Track Templates tab
local function UpdateListFilter_TrackTemplates()
  if FilterActive_TrackTemplates then
    GUI.elms.tab3_listbox_trackTemplates.list = TrackTemplates.filteredNames
  else
   GUI.elms.tab3_listbox_trackTemplates.list = TrackTemplates.names
  end
end

local function UpdateListFilter_CustomProjects()
  if FilterActive_CustomProjects then
    GUI.elms.tab4_listbox_customProjects.list = CustomProjects.filteredNames
  else
    GUI.elms.tab4_listbox_customProjects.list = CustomProjects.names
  end
end

local function UpdateListFilter_ProjectLists()
  if FilterActive_ProjectLists then
    GUI.elms.tab5_listbox_rplProjects.list = ProjectLists.filteredProjectNames
  else
    GUI.elms.tab5_listbox_rplProjects.list = ProjectLists.projectNames
  end
end

-- Update Filter on all main_tabs
local function UpdateListFilter_All()
  UpdateListFilter_RecentProjects()
  UpdateListFilter_ProjectTemplates()
  UpdateListFilter_TrackTemplates()
  UpdateListFilter_CustomProjects()
  UpdateListFilter_ProjectLists()
  HidePaths()
end

-------------------
-- Filter functions
-------------------
FilterActive_RecentProjects = false
FilterActive_TrackTemplates = false
FilterActive_ProjectTemplates = false
FilterActive_CustomProjects = false
FilterActive_ProjectLists = false
FilterActive_RecentSubversions = false

local separatorComma = "[^,]+"
local separatorSpace = "[^%s]+"

function filterTable(tableshort, tablefull, searchStr)
  for i = 1, #tableshort do
     if string.find(tableshort[i], searchStr) then
         RecentProjects.filteredNames[tableshort[i]] = tablefull[i]
         table.insert(RecentProjects.filteredNames, tableshort[i])
     end
  end
end

function GetSearchTable(searchString)
  searchTable = {}
  for match in string.gmatch(searchString, separatorSpace) do
      table.insert(searchTable, FilterNoCase(match))
  end
  return searchTable
end

-- filter recent projects
local function Filter_RecentProject_Apply()
  RecentProjects.filteredNames = {}
  RecentProjects.filteredPaths = {}
  local searchStr = GUI.Val("tab1_textbox_filterRecentProjects")
  if (#searchStr > 0) then
    FilterActive_RecentProjects = true
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
    FilterActive_RecentProjects = false
    UpdatePathDisplayMode()
    if FilterActive_RecentSubversions then filterTable(RecentProjects.subversionNames, RecentProjects.subversionPaths, searchStr) end
  end

  UpdateListFilter_RecentProjects()
  GUI.Val("tab1_listbox_recentProjects",{})
  HidePaths()
end

-- filter project templates
local function Filter_ProjectTemplate_Apply()
  ProjectTemplates.filteredNames = {}
  ProjectTemplates.filteredPaths = {}

  local searchStr = GUI.Val("tab2_textbox_filterProjectTemplates")
  if (#searchStr > 0) then
    FilterActive_ProjectTemplates = true
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
    FilterActive_ProjectTemplates = false
  end

  UpdateListFilter_ProjectTemplates()
  GUI.Val("tab2_listbox_projectTemplates",{})
  HidePaths()
end

-- filter track templates
local function Filter_TrackTemplate_Apply()
  TrackTemplates.filteredNames = {}
  TrackTemplates.filteredPaths = {}
  
  local searchStr = GUI.Val("tab3_textbox_filterTrackTemplates")
  if (#searchStr > 0) then
    FilterActive_TrackTemplates = true
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
      FilterActive_TrackTemplates = false
      UpdatePathDisplayMode()
    end
  
  UpdateListFilter_TrackTemplates()
  GUI.Val("tab3_listbox_trackTemplates",{})
  HidePaths()
end

-- filter custom projects
local function Filter_CustomProjects_Apply()
  CustomProjects.filteredNames = {}
  CustomProjects.filteredPaths = {}
  
  local searchStr = GUI.Val("tab4_textbox_filterCustomProjects")
  if (#searchStr > 0) then
    FilterActive_CustomProjects = true
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
    FilterActive_CustomProjects = false
    UpdatePathDisplayMode()
  end

  UpdateListFilter_CustomProjects()
  GUI.Val("tab4_listbox_customProjects",{})
  HidePaths()
end

local function Filter_ProjectLists_Apply()
  ProjectLists.filteredProjectNames = {}
  ProjectLists.filteredProjectPaths = {}
  
  local searchStr = GUI.Val("tab5_textbox_filterProjectLists")
  
  if (#searchStr > 0) then
    FilterActive_ProjectLists = true
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
    FilterActive_ProjectLists = false
    UpdatePathDisplayMode()
  end

  UpdateListFilter_ProjectLists()
  GUI.Val("tab5_listbox_rplProjects",{})
  HidePaths()
end

----------------------------
-- Refresh Listbox functions
----------------------------
local function Refresh_RecentProjects()
  FillRecentProjectsListbox()
  UpdatePathDisplayMode()
  UpdateSubversionFilter()
  GUI.elms.tab1_listbox_recentProjects:redraw()
end

local function Refresh_ProjectTemplates()
  FillProjectTemplateListbox()
  UpdatePathDisplayMode()
  GUI.elms.tab2_listbox_projectTemplates:redraw()
end

local function Refresh_TrackTemplates()
  FillTrackTemplateListbox()
  UpdatePathDisplayMode()
  GUI.elms.tab3_listbox_trackTemplates:redraw()
end

local function Refresh_CustomProjects()
  FillCustomProjectsListbox()
  UpdatePathDisplayMode()
  GUI.elms.tab4_listbox_customProjects:redraw()
end

---------------------
-- Clear custom paths
----------------------
-- clear custom project template path
function Path_Clear_ProjectTemplateFolder()
  ProjectTemplates.items = {}
  ProjectTemplates.names = {}
  ProjectTemplates.paths = {}
  ProjectTemplates.filteredNames = {}
  ProjectTemplates.pfilteredPathsaths = {}

  GUI.Val("options_textbox_projectTemplates_path","")
  GUI.elms.tab2_listbox_projectTemplates.list = {}
  
  reaper.DeleteExtState(appname, "custompath_projecttemplates",1)
  Refresh_ProjectTemplates()
  MsgStatusBar("Additional Project Template folder removed")
end

-- clear custom track template path
function Path_Clear_TrackTemplateFolder()
  TrackTemplates.items = {}
  TrackTemplates.names = {}
  TrackTemplates.paths = {}
  TrackTemplates.filteredNames = {}
  TrackTemplates.pfilteredPathsaths = {}

  GUI.Val("options_textbox_trackTemplates_path","")
  GUI.elms.tab3_listbox_trackTemplates.list = {}
  
  reaper.DeleteExtState(appname, "custompath_tracktemplates",1)
  Refresh_TrackTemplates()
  MsgStatusBar("Additional Track Template folder removed")
end

-- clear custom projects path
function Path_Clear_CustomProjectFolder()
  custom_path_projects = {}
  CustomProjects.items = {}
  CustomProjects.names = {}
  CustomProjects.paths = {}
  CustomProjects.filteredNames = {}
  CustomProjects.filteredPaths = {}
  
  GUI.Val("options_textbox_customProjects_path","")
  GUI.elms.tab4_listbox_customProjects.list = {}

  reaper.DeleteExtState(appname, "custompath_projects",1)
  MsgStatusBar("Custom Projects folder removed")
  Refresh_CustomProjects()
end

-- clear custom project list path
function Path_Clear_ProjectListFolder()
  ProjectLists.rplFiles = {}
  ProjectLists.projectItems = {}
  ProjectLists.projectNames = {}
  ProjectLists.projectPaths = {}
  ProjectLists.filteredProjectNames = {}
  ProjectLists.filteredProjectNames = {}

  GUI.Val("options_textbox_projectsLists_path","")
  GUI.elms.tab5_listbox_rplFiles.list = {}
  GUI.elms.tab5_listbox_rplProjects.list = {}

  reaper.DeleteExtState(appname, "custompath_projectlists",1)
  MsgStatusBar("Project Lists folder removed")
  Refresh_ProjectList()
end

-------------------
-- Set custom paths
-------------------
-- set custom project template path
function Path_Set_ProjectTemplateFolder()
  local custom_path_projectTemplates = GUI.Val("options_textbox_projectTemplates_path")
  if custom_path_projectTemplates == "" then
    MsgStatusBar("Please enter a custom [ Project Templates ] folder path first!")
  else
    reaper.SetExtState(appname, "custompath_projecttemplates",custom_path_projectTemplates, 1)
    Refresh_ProjectTemplates()
    MsgStatusBar("Additional Project Template folder set to " .. custom_path_projectTemplates)
  end
end

-- set  track template path
function Path_Set_TrackTemplateFolder()
  local custom_path_trackTemplates = GUI.Val("options_textbox_trackTemplates_path")
  if custom_path_trackTemplates == "" then
    MsgStatusBar("Please enter a custom [ Track Templates ] folder path first!")
  else
    reaper.SetExtState(appname, "custompath_tracktemplates", custom_path_trackTemplates, 1)
    Refresh_TrackTemplates()
    MsgStatusBar("Additional Track Templates folder set to " .. custom_path_trackTemplates)
  end
end

-- set custom projects path
function Path_Set_CustomProjectFolder()
  local custom_path_customprojects = GUI.Val("options_textbox_customProjects_path")
  if custom_path_customprojects == "" then 
    MsgStatusBar("Please enter a custom [ Projects ] folder path first!")
  else
    reaper.SetExtState(appname, "custompath_projects", custom_path_customprojects, 1)
    Refresh_CustomProjects()
    MsgStatusBar("Custom Projects folder set to " .. custom_path_customprojects)
  end
end

function Path_Set_ProjectListFolder()
  local custom_path_projectlists = GUI.Val("options_textbox_projectsLists_path")
  if custom_path_projectlists == "" then
    MsgStatusBar("Please enter a custom [ Project List ] folder path first!")
  else
    reaper.SetExtState(appname, "custompath_projectlists",custom_path_projectlists, 1)
    Refresh_ProjectList()
    MsgStatusBar("Project Lists folder set to " .. custom_path_projectlists)
  end
end

-----------------------
-- Theme slot functions
-----------------------
-- open the SWS Resource window
function ThemeSlot_Setup()
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_SHOW_RESVIEW_THEME"), 0)
end

-- load a Theme from the given slot number
function ThemeSlot_Load()
  themeslot = GUI.Val("themeslot")
  if themeslot < 5 then
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_LOAD_THEME" .. themeslot-1), 0)
  else
    reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_LOAD_THEMEl"), 0)
  end 
end

-- draw the UI element
function RL_Draw_ThemeSlotSelector(alignment)
  if GUI.SWS_exists() then
    -- elements
    GUI.New("themeslot", "Menubox", 2, btn_pad_left + 90, btn_pad_top + 190, 50, 20, "Reaper Theme:", ThemeSlot_GetItems())
    GUI.elms.themeslot.align = alignment
  
    -- listeners
    function GUI.elms.themeslot:onmousedown()
      GUI.Menubox.onmouseup(self)
      ThemeSlot_Load()
    end
    
    function GUI.elms.themeslot:onwheel()
      GUI.Menubox.onwheel(self)
      ThemeSlot_Load()
    end
  end 
end

ThemeSlots = {
  maxCount = 5,
  items = "----,1,2,3,4,5"
}

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
  MsgStatusBar("Theme Slot Descriptions Saved")
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
  local themeslot_pad_top = 245

  if GUI.SWS_exists() then 
    -- elements
    GUI.New("options_themeslot_number", "Menubox", 8, themeslot_pad_left + 140, themeslot_pad_top, 38, 20, "Theme Slot Descriptions", "1,2,3,4,5")
    GUI.elms.options_themeslot_number.align = 1

    for i = 1, ThemeSlots.maxCount do
      GUI.New("options_themeslot_" .. i, "Textbox", 8, themeslot_pad_left, themeslot_pad_top + 25 + (20 * (i -1)), 180, 20, i, 8)
    end

    ThemeSlotTextBoxes = {  GUI.elms.options_themeslot_1, GUI.elms.options_themeslot_2,  GUI.elms.options_themeslot_3, GUI.elms.options_themeslot_4, GUI.elms.options_themeslot_5 }
    ThemeSlot_Indicator()
    
    GUI.New("options_themeslot_Setup", "Button", 8, themeslot_pad_left, themeslot_pad_top + 130, 100, 20, "Edit Theme Slots", ThemeSlot_Setup)
    GUI.New("options_themeslot_Save", "Button", 8, themeslot_pad_left + 114, themeslot_pad_top + 130, 65, 20, "Save", ThemeSlot_SaveNames)

    -- listeners
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

  end
end

function ThemeSlot_GetItems()
  return ThemeSlots.items
end

---------------------------------
-- Recent Project List Management 
---------------------------------
function RecentProjects_RemoveEntry()
  local vals = GetSelectionTable(GUI.Val("tab1_listbox_recentProjects"))
  selectedProject = RecentProjects.items[RecentProjects.names[vals[1]]]
  local found = false
  local recentpathtag = {}
  local p = 0
  local removedEntries = {}

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
      end
    end
  until (found == true)
  Refresh_RecentProjects()
end

function RecentProjects_ClearList()
  local keyName
    for k = 1, RecentProjects.maxIndex do
      if k < 10 then keyName = "recent0" .. tostring(k)
      else keyName = "recent" .. tostring(k) end
      reaper.BR_Win32_WritePrivateProfileString("Recent", keyName, "", reaper.get_ini_file())
    end
  Refresh_RecentProjects()
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

--------------------
-- Main GUI Elements
--------------------
function RL_Draw_Main()
  -- elements - layer 1
  GUI.New("main_tabs", "Tabs", 1, 0, 0, 100, 20, "Recent Projects, Project Templates, Track Templates, Projects, Project Lists, Options", 16)
  GUI.New("main_appversion", "Label", 1, pad_left, GUI.h - 18, "ReaLauncher " .. appversion, false, 4)
  GUI.New("main_statusbar", "Label", 1, pad_left + 90, GUI.h - 18, "", false, 4)

  -- Tab | Layers
   GUI.elms.main_tabs:update_sets(
     { [1] = {2,3},
       [2] = {2,4},
       [3] = {2,5},
       [4] = {2,6},
       [5] = {2,7},
       [6] = {8},
     }
   )

  -- elements - layer 2
  GUI.New("main_menubox_paths", "Menubox", 2, 380, pad_top, 60, 20, "Paths", "Hide,Show")
  GUI.elms.main_menubox_paths.align = "1"
  
  GUI.New("main_button_openInExplorer", "Button", 2, btn_pad_left, 64, btn_w, btn_h, "Show in Explorer/Finder", OpenInExplorer)
  GUI.New("main_button_openProject", "Button", 2, btn_pad_left, 98, btn_w, btn_h, "Open Project", Project_OpenDialog) 

  GUI.New("main_button_newProject", "Button", 2, btn_pad_left, btn_pad_top, btn_w, btn_h, "New Project", Project_New) 
  GUI.New("main_button_newProjectTab", "Button", 2, btn_pad_left, btn_pad_top + btn_pad_add, btn_w, btn_h, "New Tab", Project_NewTab) 
  GUI.New("main_button_newTabIgnoraTemplate", "Button", 2, btn_pad_left, btn_pad_top + 2 * btn_pad_add, btn_w, btn_h, "New Tab Ignore Template", Project_NewTab_IgnoreTemplate)
  
  GUI.New("main_label_windowpin", "Label", 2, GUI.w - 150, 32, "Keep window open", false, 3)
  GUI.New("main_checklist_windowpin", "Checklist", 2, GUI.w - 40, 30, 20, 20, "", "", "h", 0)
 
  -- listeners
  function GUI.elms.main_menubox_paths:onmousedown()
    GUI.Menubox.onmouseup(self)
    UpdatePathDisplayMode()
  end
  
  function GUI.elms.main_menubox_paths:onwheel()
    GUI.Menubox.onwheel(self)
    UpdatePathDisplayMode()
  end

  RL_Draw_ThemeSlotSelector("1")
end

-- frames
function RL_Draw_Frames()
  local Framewidth = 2
  -- global
  GUI.New("main_frame_top", "Frame", 2, 0, 56, GUI.w, Framewidth, true, true)
  GUI.New("main_frame_side_2", "Frame", 2, pad_left + listbox_w , 132, GUI.w - pad_left - listbox_w, Framewidth, true, true)
  GUI.New("main_frame_side_3", "Frame", 2, pad_left + listbox_w , 244, GUI.w - pad_left - listbox_w, Framewidth, true, true)
  GUI.New("main_frame_side_4", "Frame", 2, pad_left + listbox_w , 320, GUI.w - pad_left - listbox_w, Framewidth, true, true)
  GUI.New("main_frame_side_5", "Frame", 2, pad_left + listbox_w , 355, GUI.w - pad_left - listbox_w, Framewidth, true, true)
  -- recent projects
  GUI.New("main_frame_side_6", "Frame", 3, pad_left + listbox_w , 390, GUI.w - pad_left - listbox_w, Framewidth, true, true)
  -- project templates
  GUI.New("main_frame_side_7", "Frame", 4, pad_left + listbox_w , 390, GUI.w - pad_left - listbox_w, Framewidth, true, true)
end

-----------------------------------
-- Tab 1 Elements - Recent Projects
-----------------------------------
function RL_Draw_Tab1()

 -- elements
  GUI.New("tab1_button_RecentProjectsRefresh", "Button", 3, 10, pad_top - 2, 20,  22, "R", Refresh_RecentProjects)
  GUI.New("tab1_textbox_filterRecentProjects", "Textbox", 3, 75, pad_top, 260, 20, "Filter", 8)
  
  GUI.New("tab1_listbox_recentProjects", "Listbox", 3, pad_left, listbox_top, listbox_w, listbox_h,"", true)
  GUI.elms.tab1_listbox_recentProjects.list = RecentProjects.names

  GUI.New("tab1_button_loadRecentProjectInTab", "Button", 3, btn_pad_left, btn_tab_top, btn_w,  btn_h, "Load in Tab", LoadInTab_RecentProject)
  GUI.New("tab1_button_loadRecentProject", "Button", 3, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_RecentProject)

  GUI.New("tab1_label_subversionFilter", "Label", 3, GUI.w - 152, 367, "Subversion Filter", false, 3)
  GUI.New("tab1_checklist_subversionFilter", "Checklist", 3, GUI.w - 46, 365, 20, 20, "", "", "h", 0)
  
 -- listeners
 function GUI.elms.tab1_checklist_subversionFilter:onmousedown()
    GUI.Checklist.onmouseup(self)  
    UpdateSubversionFilter()
  end
  
  function GUI.elms.tab1_listbox_recentProjects:ondoubleclick()
    Load_RecentProject()
  end
  
  function GUI.elms.tab1_listbox_recentProjects:onmouser_down()
    if (noRecentProjects == false) then
      gfx.x = gfx.mouse_x
      gfx.y = gfx.mouse_y
      local RMBmenu = gfx.showmenu("Remove entry|#|Clear list")
    
      if RMBmenu == 1 then RL_ConfirmDialog_RemoveEntry() end
      if RMBmenu == 2 then RL_ConfirmDialog_ClearList() end
    end
    GUI.Listbox.onmouser_down(self)
  end
  
  function GUI.elms.tab1_textbox_filterRecentProjects:ontype()
     GUI.Textbox.ontype(self)
     Filter_RecentProject_Apply()
  end
end
-------------------------------------
-- Tab 2 Elements - Project Templates
-------------------------------------
projectTemplateLoadMode = 1

function RL_Draw_Tab2()

  -- elements
  GUI.New("tab2_button_projectTemplatesRefresh", "Button", 4, 10, pad_top-2, 20,  22,"R", Refresh_ProjectTemplates)
  GUI.New("tab2_textbox_filterProjectTemplates", "Textbox", 4, 75, pad_top, 260, 20, "Filter", 8)
  
  GUI.New("tab2_listbox_projectTemplates", "Listbox", 4, pad_left, listbox_top, listbox_w, listbox_h, "", true)
  GUI.elms.tab2_listbox_projectTemplates.list = ProjectTemplates.names

  GUI.New("tab2_button_loadProjectTemplateInTab", "Button", 4, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_ProjectTemplate)
  GUI.New("tab2_button_loadProjectTemplate", "Button", 4, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_ProjectTemplate)
   
  GUI.New("tab2_label_projectTemplatesEditMode", "Label", 4, GUI.w - 158, 367, "Edit Template Mode", false, 3)
  GUI.New("tab2_checklist_projectTemplatesEditMode", "Checklist", 4, GUI.w - 42, 365, 20, 20, "", "", "h", 0)

  -- listeners
  function GUI.elms.tab2_listbox_projectTemplates:ondoubleclick()
    Load_ProjectTemplate()
  end
  
  function GUI.elms.tab2_textbox_filterProjectTemplates:ontype()
     GUI.Textbox.ontype(self)
     Filter_ProjectTemplate_Apply()
  end
  
  function GUI.elms.tab2_checklist_projectTemplatesEditMode:onmousedown()
    projectTemplateLoadMode = GUI.Val("tab2_checklist_projectTemplatesEditMode")
  end
  
end
-----------------------------------
-- Tab 3 Elements - Track Templates
-----------------------------------
function RL_Draw_Tab3()

  -- elements
  GUI.New("tab3_button_trackTemplatesRefresh", "Button", 5, 10, pad_top-2, 20, 22, "R", Refresh_TrackTemplates)
  GUI.New("tab3_textbox_filterTrackTemplates", "Textbox", 5, 75, pad_top, 260, 20, "Filter", 8)
  
  GUI.New("tab3_listbox_trackTemplates", "Listbox", 5, pad_left, listbox_top, listbox_w, listbox_h, "", true)
  GUI.elms.tab3_listbox_trackTemplates.list = TrackTemplates.names

  GUI.New("tab3_button_insertTrackTemplate", "Button", 5, btn_pad_left, btn_tab_top + 20, btn_w, btn_h, "Insert", Load_TrackTemplate)
  
   -- listeners
  function GUI.elms.tab3_listbox_trackTemplates:ondoubleclick()
    Load_TrackTemplate()
  end
  
  function GUI.elms.tab3_textbox_filterTrackTemplates:ontype()
     GUI.Textbox.ontype(self)
     Filter_TrackTemplate_Apply()
  end
 
end

----------------------------
-- Tab 4 Elements - Projects
----------------------------
function RL_Draw_Tab4()

  -- elements
  GUI.New("tab4_button_filterCustomProjects", "Button", 6, 10, pad_top-2, 20, 22, "R", Refresh_CustomProjects)
  GUI.New("tab4_textbox_filterCustomProjects", "Textbox", 6, 75, pad_top, 260, 20, "Filter", 8)
  
  GUI.New("tab4_listbox_customProjects", "Listbox", 6, pad_left, listbox_top, listbox_w, listbox_h, "", true)
  GUI.elms.tab4_listbox_customProjects.list = CustomProjects.names

  GUI.New("tab4_button_loadCustomProjectsInTab", "Button", 6, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_CustomProject)
  GUI.New("tab4_button_loadCustomProjects", "Button", 6, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_CustomProject)

  -- listener
  function GUI.elms.tab4_listbox_customProjects:ondoubleclick()
    Load_CustomProject()
  end
    
  function GUI.elms.tab4_textbox_filterCustomProjects:ontype()
     GUI.Textbox.ontype(self)
     Filter_CustomProjects_Apply()
  end
  
end

----------------------------------
-- Tab 5 Elements -  Project Lists
----------------------------------
function RL_Draw_Tab5()

  -- elements
  GUI.New("tab5_button_projectListRefresh", "Button", 7, 10, pad_top - 2, 20,  22, "R", Refresh_ProjectList)
  GUI.New("tab5_textbox_filterProjectLists", "Textbox", 7, 75, pad_top, 260, 20, "Filter", 8)
 
  GUI.New("tab5_listbox_rplFiles", "Listbox", 7, pad_left , listbox_top, listbox_w/3, listbox_h, "", true)
  GUI.elms.tab5_listbox_rplFiles.list = ProjectLists.rplFiles  
 
  GUI.New("tab5_listbox_rplProjects", "Listbox", 7, pad_left + listbox_w/3, listbox_top, listbox_w - listbox_w/3, listbox_h, "", true)
 
  GUI.New("tab5_button_loadRplProjectInTab", "Button", 7, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_ProjectListProject)
  GUI.New("tab5_button_loadRplProject", "Button", 7, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_ProjectListProject)
 
  -- listeners
  function GUI.elms.tab5_listbox_rplFiles:onmouseup()
    if GUI.elms.tab5_listbox_rplFiles then 
      GUI.Listbox.onmouseup(self)
      FillProjectListBox()
    end
  end

  function GUI.elms.tab5_listbox_rplProjects:ondoubleclick()
    Load_ProjectListProject()
  end

  function GUI.elms.tab5_textbox_filterProjectLists:ontype()
    GUI.Textbox.ontype(self)
    Filter_ProjectLists_Apply()
 end

end

---------------------------
-- Tab 6 Elements - Options
---------------------------
function RL_Draw_Tab6()

  local options_yOffset = 50
  local options_pad_top = 16

  -- custom project template folder
  GUI.New("options_button_projectTemplates_clear", "Button", 8, 20, options_pad_top + options_yOffset, 55, 20, "Remove", Path_Clear_ProjectTemplateFolder)
  GUI.New("options_button_projectTemplates_set", "Button", 8, GUI.w - 60, options_pad_top + options_yOffset, 40, 20, "Set", Path_Set_ProjectTemplateFolder)
  GUI.New("options_textbox_projectTemplates_path", "Textbox", 8, 85, options_pad_top + options_yOffset, GUI.w - 150, 20, "Additional [ Project Templates ] folder", 8)
  GUI.elms.options_textbox_projectTemplates_path.cap_pos = "top"

  -- custom track template folder
  GUI.New("options_button_TrackTemplates_clear", "Button", 8, 20, options_pad_top + 2 * options_yOffset, 55, 20, "Remove", Path_Clear_TrackTemplateFolder)
  GUI.New("options_button_TrackTemplates_set", "Button", 8, GUI.w - 60, options_pad_top + 2 * options_yOffset, 40, 20, "Set", Path_Set_TrackTemplateFolder)
  GUI.New("options_textbox_trackTemplates_path", "Textbox", 8, 85, options_pad_top + 2 * options_yOffset, GUI.w - 150, 20, "Additional [ Track Templates ] folder", 8)
  GUI.elms.options_textbox_trackTemplates_path.cap_pos = "top"

  -- custom project folder
  GUI.New("options_button_customProjects_clear", "Button", 8, 20, options_pad_top + 3 * options_yOffset, 55, 20, "Remove", Path_Clear_CustomProjectFolder)
  GUI.New("options_button_customProjects_set", "Button", 8, GUI.w - 60, options_pad_top + 3 * options_yOffset, 40, 20, "Set", Path_Set_CustomProjectFolder)
  GUI.New("options_textbox_customProjects_path", "Textbox", 8, 85, options_pad_top + 3 * options_yOffset, GUI.w - 150, 20, "[ Projects ] folder", 8)
  GUI.elms.options_textbox_customProjects_path.cap_pos = "top"

  -- project list folder
  GUI.New("options_button_projectLists_clear", "Button", 8, 20, options_pad_top + 4 * options_yOffset, 55, 20, "Remove", Path_Clear_ProjectListFolder)
  GUI.New("options_button_projectLists_set", "Button", 8, GUI.w - 60, options_pad_top + 4 * options_yOffset, 40, 20, "Set", Path_Set_ProjectListFolder)

  GUI.New("options_textbox_projectsLists_path", "Textbox", 8, 85, options_pad_top + 4 * options_yOffset, GUI.w - 150, 20, "[ Project Lists ] folder", 8)
  GUI.elms.options_textbox_projectsLists_path.cap_pos = "top"
  
  -- theme slot options
  RL_Draw_ThemeSlotOptions()
end

-----------
-- Tooltips
-----------
function RL_Draw_Tooltips()
  local ttLoadFXoffline = "To load with FX offline: \n\n- Hold 'Ctrl + Shift' (Windows & Linux)\n- Hold 'Cmd + Shift' (macOS)\n- Or use the option in the [Open Project] window"

  -- main
  GUI.elms.main_menubox_paths.tooltip = "Show/Hide file paths in the list"
  GUI.elms.main_button_openInExplorer.tooltip = "Browse to the file location in Explorer/Finder"
  GUI.elms.main_button_newProjectTab.tooltip = "Add new project tab"
  GUI.elms.main_button_newTabIgnoraTemplate.tooltip = "Add new project tab (ignore template)"
  GUI.elms.main_button_newProject.tooltip = "Create new project"
  GUI.elms.main_button_openProject.tooltip = "Show the 'Open project' window"

  local tooltip_windowpin = "Check this box to keep the window open"
  GUI.elms.main_label_windowpin.tooltip = tooltip_windowpin
  GUI.elms.main_checklist_windowpin.tooltip = tooltip_windowpin

  -- recent projects
  GUI.elms.tab1_button_RecentProjectsRefresh.tooltip = "Refresh the [Recent Projects] list"
  GUI.elms.tab1_textbox_filterRecentProjects.tooltip = "Filter the [Recent Projects] list by typing in words"
  GUI.elms.tab1_button_loadRecentProjectInTab.tooltip = "Load selected recent project(s) in tab(s)\n\n" .. ttLoadFXoffline
  GUI.elms.tab1_button_loadRecentProject.tooltip = "Load selected recent project(s)\n\n" .. ttLoadFXoffline
  GUI.elms.tab1_label_subversionFilter.tooltip = "Show only the last project files (if multiple versions exist)"

  -- project templates
  GUI.elms.tab2_button_projectTemplatesRefresh.tooltip = "Refresh [Project Templates] list"
  GUI.elms.tab2_textbox_filterProjectTemplates.tooltip = "Filter the [Project Templates] list by typing in words"
  GUI.elms.tab2_button_loadProjectTemplateInTab.tooltip = "Load selected project template(s) in tab(s)\n\n" .. ttLoadFXoffline
  GUI.elms.tab2_button_loadProjectTemplate.tooltip = "Load selected project templates(s)\n\n" .. ttLoadFXoffline
  
  local tooltip_projectTemplatesEditMode = "Open the project template file for direct editing"
  GUI.elms.tab2_label_projectTemplatesEditMode.tooltip = tooltip_projectTemplatesEditMode
  GUI.elms.tab2_checklist_projectTemplatesEditMode.tooltip = tooltip_projectTemplatesEditMode

  -- track templates
  GUI.elms.tab3_button_trackTemplatesRefresh.tooltip = "Refresh the [Track Templates] list"
  GUI.elms.tab3_textbox_filterTrackTemplates.tooltip = "Filter the [Track Templates] list by typing in words"
  GUI.elms.tab3_button_insertTrackTemplate.tooltip = "Insert selected track template(s)"

  -- projects
  GUI.elms.tab4_button_filterCustomProjects.tooltip = "Refresh the [Projects] list"
  GUI.elms.tab4_textbox_filterCustomProjects.tooltip = "Filter the [Projects] list by typing in words"
  GUI.elms.tab4_button_loadCustomProjectsInTab.tooltip = "Load the selected project(s) in tab(s)\n\n" .. ttLoadFXoffline
  GUI.elms.tab4_button_loadCustomProjects.tooltip = "Load the selected project(s)\n\n" .. ttLoadFXoffline

  -- project lists
  GUI.elms.tab5_button_projectListRefresh.tooltip = "Refresh the [Project Lists] list"
  GUI.elms.tab5_textbox_filterProjectLists.tooltip = "Filter the [Project Lists] list by typing in words"
  GUI.elms.tab5_button_loadRplProjectInTab.tooltip = "Load the selected project(s) in tab(s)\n\n" .. ttLoadFXoffline
  GUI.elms.tab5_button_loadRplProject.tooltip = "Load the selected project(s)\n\n" .. ttLoadFXoffline

  -- options
  GUI.elms.options_button_projectTemplates_clear.tooltip = "Remove project template folder path"
  GUI.elms.options_button_projectTemplates_set.tooltip = "Set the given path as additional project template folder"
  GUI.elms.options_textbox_projectTemplates_path.tooltip = "Enter a custom project template folder path"
  
  GUI.elms.options_button_TrackTemplates_clear.tooltip = "Remove track template folder path"
  GUI.elms.options_button_TrackTemplates_set.tooltip = "Set the given path as additional track template folder"
  GUI.elms.options_textbox_trackTemplates_path.tooltip = "Enter a custom track template folder path"

  GUI.elms.options_button_customProjects_clear.tooltip = "Remove project folder path"
  GUI.elms.options_button_customProjects_set.tooltip = "Set the given path as project folder"
  GUI.elms.options_textbox_customProjects_path.tooltip = "Enter a custom project folder path"

  GUI.elms.options_button_projectLists_clear.tooltip = "Remove project list folder path"
  GUI.elms.options_button_projectLists_set.tooltip = "Set the given path as project list folder"
  GUI.elms.options_textbox_projectsLists_path.tooltip = "Enter a custom project list folder path"

  if GUI.SWS_exists() then
    GUI.elms.themeslot.tooltip = "Switch between different Reaper Theme Slots"
  end
end

--------------------------
-- Color element functions
--------------------------
local ButtonColor = "wnd_bg"

function RL_Draw_Colors_Button()
  -- main section
  GUI.elms.main_button_openInExplorer.col_fill = ButtonColor
  GUI.elms.main_button_openInExplorer:init()
  GUI.elms.main_button_openProject.col_fill = ButtonColor
  GUI.elms.main_button_openProject:init()
  GUI.elms.main_button_newProjectTab.col_fill = ButtonColor
  GUI.elms.main_button_newProjectTab:init()
  GUI.elms.main_button_newTabIgnoraTemplate.col_fill = ButtonColor
  GUI.elms.main_button_newTabIgnoraTemplate:init()
  GUI.elms.main_button_newProject.col_fill = ButtonColor
  GUI.elms.main_button_newProject:init()

  -- recent projects
  GUI.elms.tab1_button_RecentProjectsRefresh.col_fill = ButtonColor
  GUI.elms.tab1_button_RecentProjectsRefresh:init()
  GUI.elms.tab1_button_loadRecentProjectInTab.col_fill = ButtonColor
  GUI.elms.tab1_button_loadRecentProjectInTab:init()
  GUI.elms.tab1_button_loadRecentProject.col_fill = ButtonColor
  GUI.elms.tab1_button_loadRecentProject:init()

  -- project templates
  GUI.elms.tab2_button_projectTemplatesRefresh.col_fill = ButtonColor
  GUI.elms.tab2_button_projectTemplatesRefresh:init()
  GUI.elms.tab2_button_loadProjectTemplateInTab.col_fill = ButtonColor
  GUI.elms.tab2_button_loadProjectTemplateInTab:init()
  GUI.elms.tab2_button_loadProjectTemplate.col_fill = ButtonColor
  GUI.elms.tab2_button_loadProjectTemplate:init()
  
  -- track templates
  GUI.elms.tab3_button_trackTemplatesRefresh.col_fill = ButtonColor
  GUI.elms.tab3_button_trackTemplatesRefresh:init()

  GUI.elms.tab3_button_insertTrackTemplate.col_fill = ButtonColor
  GUI.elms.tab3_button_insertTrackTemplate:init()

  -- custom projects
  GUI.elms.tab4_button_filterCustomProjects.col_fill = ButtonColor
  GUI.elms.tab4_button_filterCustomProjects:init()
  GUI.elms.tab4_button_loadCustomProjectsInTab.col_fill = ButtonColor
  GUI.elms.tab4_button_loadCustomProjectsInTab:init()
  GUI.elms.tab4_button_loadCustomProjects.col_fill = ButtonColor
  GUI.elms.tab4_button_loadCustomProjects:init()

  -- project list
  GUI.elms.tab5_button_projectListRefresh.col_fill = ButtonColor
  GUI.elms.tab5_button_projectListRefresh:init()
  GUI.elms.tab5_button_loadRplProjectInTab.col_fill = ButtonColor
  GUI.elms.tab5_button_loadRplProjectInTab:init()
  GUI.elms.tab5_button_loadRplProject.col_fill = ButtonColor
  GUI.elms.tab5_button_loadRplProject:init()

  -- options
  GUI.elms.options_button_projectTemplates_clear.col_fill = ButtonColor
  GUI.elms.options_button_projectTemplates_clear:init()
  GUI.elms.options_button_projectTemplates_set.col_fill = ButtonColor
  GUI.elms.options_button_projectTemplates_set:init()

  GUI.elms.options_button_TrackTemplates_clear.col_fill = ButtonColor
  GUI.elms.options_button_TrackTemplates_clear:init()
  GUI.elms.options_button_TrackTemplates_set.col_fill = ButtonColor
  GUI.elms.options_button_TrackTemplates_set:init()

  GUI.elms.options_button_customProjects_clear.col_fill = ButtonColor
  GUI.elms.options_button_customProjects_clear:init()
  GUI.elms.options_button_customProjects_set.col_fill = ButtonColor
  GUI.elms.options_button_customProjects_set:init()

  GUI.elms.options_button_projectLists_clear.col_fill = ButtonColor
  GUI.elms.options_button_projectLists_clear:init()
  GUI.elms.options_button_projectLists_set.col_fill = ButtonColor
  GUI.elms.options_button_projectLists_set:init()

  -- themeslot selector
  if GUI.SWS_exists() then 
    GUI.elms.options_themeslot_Setup.col_fill = ButtonColor
    GUI.elms.options_themeslot_Setup:init()
    GUI.elms.options_themeslot_Save.col_fill = ButtonColor
    GUI.elms.options_themeslot_Save:init()
  end

  -- confirm dialog
  GUI.elms.confirmdialog_button_ok.col_fill = ButtonColor
  GUI.elms.confirmdialog_button_ok:init()
  GUI.elms.confirmdialog_button_cancel.col_fill = ButtonColor
  GUI.elms.confirmdialog_button_cancel:init()
end

function RL_Draw_Fonts()
  GUI.elms.main_appversion.font = {sans, 12, "b"}
  GUI.elms.main_appversion:init()

  GUI.elms.main_statusbar.font = {sans, 12, "b"}
  GUI.elms.main_statusbar:init()
end

----------
-- Dialogs
----------
ConfirmDialog =
{
  type,
  message
}

function RL_ConfirmDialog_RemoveEntry()
  ConfirmDialog.type = "RemoveEntry"
  ConfirmDialog.message = "Remove the selected entry?"
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
  GUI.New("confirmdialog_window", "Window", 11, 0, 0, 200, 100, "Confirm", {10, 11})
  GUI.New("confirmdialog_label", "Label", 10, 24, 16, "", false, 4)
  GUI.New("confirmdialog_button_ok", "Button", 10, 40, 45, 48, 20, "OK", RL_ConfirmDialog_OK)
  GUI.New("confirmdialog_button_cancel", "Button", 10, 110, 45, 48, 20, "Cancel", RL_ConfirmDialog_Cancel)
  GUI.elms_hide[10] = true
  GUI.elms_hide[11] = true

  function GUI.elms.confirmdialog_window:onopen()
      self:adjustelm(GUI.elms.confirmdialog_button_ok)
      self:adjustelm(GUI.elms.confirmdialog_button_cancel)
      self:adjustelm(GUI.elms.confirmdialog_label)
      self.caption = "Confirm"
      GUI.Val("confirmdialog_label", ConfirmDialog.message )
  end
end

----------------------
-- Draw function relay
----------------------
function RL_Draw_Tabs()
  RL_Draw_Tab1()
  RL_Draw_Tab2()
  RL_Draw_Tab3()
  RL_Draw_Tab4()
  RL_Draw_Tab5()
  RL_Draw_Tab6()
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
  Refresh_ProjectList()
  UpdateSubversionFilter()
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

  GUI.elms.main_menubox_paths:ondelete()
  GUI.elms.main_button_openInExplorer:ondelete()
  GUI.elms.main_button_newProjectTab:ondelete()
  GUI.elms.main_button_newTabIgnoraTemplate:ondelete()
  GUI.elms.main_button_newProject:ondelete()
  GUI.elms.main_button_openProject:ondelete()
  GUI.elms.main_label_windowpin:ondelete()
  GUI.elms.main_checklist_windowpin:ondelete()
  
  RL_Draw_Main()

  -- recent projects
  GUI.elms.tab1_button_RecentProjectsRefresh:ondelete()
  GUI.elms.tab1_textbox_filterRecentProjects:ondelete()
  GUI.elms.tab1_listbox_recentProjects:ondelete()
  GUI.elms.tab1_button_loadRecentProjectInTab:ondelete()
  GUI.elms.tab1_button_loadRecentProject:ondelete()
  GUI.elms.tab1_label_subversionFilter:ondelete()
  GUI.elms.tab1_checklist_subversionFilter:ondelete()

  -- project templates
  GUI.elms.tab2_button_projectTemplatesRefresh:ondelete()
  GUI.elms.tab2_textbox_filterProjectTemplates:ondelete()
  GUI.elms.tab2_listbox_projectTemplates:ondelete()
  GUI.elms.tab2_button_loadProjectTemplateInTab:ondelete()
  GUI.elms.tab2_button_loadProjectTemplate:ondelete()
  GUI.elms.tab2_label_projectTemplatesEditMode:ondelete()
  GUI.elms.tab2_checklist_projectTemplatesEditMode:ondelete()

  -- track templates
  GUI.elms.tab3_button_trackTemplatesRefresh:ondelete()
  GUI.elms.tab3_textbox_filterTrackTemplates:ondelete()
  GUI.elms.tab3_listbox_trackTemplates:ondelete()
  GUI.elms.tab3_button_insertTrackTemplate:ondelete()

  -- custom projects
  GUI.elms.tab4_button_filterCustomProjects:ondelete()
  GUI.elms.tab4_textbox_filterCustomProjects:ondelete()
  GUI.elms.tab4_listbox_customProjects:ondelete()
  GUI.elms.tab4_button_loadCustomProjectsInTab:ondelete()
  GUI.elms.tab4_button_loadCustomProjects:ondelete()

  -- project lists
  GUI.elms.tab5_button_projectListRefresh:ondelete()
  GUI.elms.tab5_textbox_filterProjectLists:ondelete()
  GUI.elms.tab5_listbox_rplFiles:ondelete()
  GUI.elms.tab5_listbox_rplProjects:ondelete()
  GUI.elms.tab5_button_loadRplProjectInTab:ondelete()
  GUI.elms.tab5_button_loadRplProject:ondelete()

  -- options
  GUI.elms.options_button_projectTemplates_clear:ondelete()
  GUI.elms.options_button_projectTemplates_set:ondelete()
  GUI.elms.options_textbox_projectTemplates_path:ondelete()

  GUI.elms.options_button_TrackTemplates_clear:ondelete()
  GUI.elms.options_button_TrackTemplates_set:ondelete()
  GUI.elms.options_textbox_trackTemplates_path:ondelete()

  GUI.elms.options_button_customProjects_clear:ondelete()
  GUI.elms.options_button_customProjects_set:ondelete()
  GUI.elms.options_textbox_customProjects_path:ondelete()

  GUI.elms.options_button_projectLists_clear:ondelete()
  GUI.elms.options_button_projectLists_set:ondelete()
  GUI.elms.options_textbox_projectsLists_path:ondelete()

  -- theme slot options
  if GUI.SWS_exists() then
    GUI.elms.options_themeslot_number:ondelete()
    GUI.elms.options_themeslot_1:ondelete()
    GUI.elms.options_themeslot_2:ondelete()
    GUI.elms.options_themeslot_3:ondelete()
    GUI.elms.options_themeslot_4:ondelete()
    GUI.elms.options_themeslot_5:ondelete()
    GUI.elms.options_themeslot_Setup:ondelete()
    GUI.elms.options_themeslot_Save:ondelete()
  end

  RL_Draw_Tabs()
  RL_Draw_AddOns()

  -- confirm dialog
  GUI.elms.confirmdialog_window:ondelete()
  GUI.elms.confirmdialog_label:ondelete()
  GUI.elms.confirmdialog_button_ok:ondelete()
  GUI.elms.confirmdialog_button_cancel:ondelete()
  RL_InitConfirmDialog()

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
-- load custom folders paths
local function RL_ExtStates_Load_FolderPaths()
  GUI.elms.options_textbox_projectTemplates_path:val(reaper.GetExtState(appname, "custompath_projecttemplates"))
  GUI.elms.options_textbox_trackTemplates_path:val(reaper.GetExtState(appname, "custompath_tracktemplates"))
  GUI.elms.options_textbox_customProjects_path:val(reaper.GetExtState(appname, "custompath_projects"))
  GUI.elms.options_textbox_projectsLists_path:val(reaper.GetExtState(appname, "custompath_projectlists"))
end

-- load theme slot aliases
local function RL_ExtStates_Load_ThemeSlotAliases()
  local themeSlotAliasesString = reaper.GetExtState(appname, "themeslot_aliases")
  local themeSlots = {}
  
  for match in string.gmatch(themeSlotAliasesString, separatorComma) do
    table.insert(themeSlots, string.lower(match))
  end

  for i= 1, 5 do GUI.Val("options_themeslot_" .. i, themeSlots[i]) end
  ThemeSlot_LoadNames()
end

local function RL_ExtStates_Load()
  local pin = reaper.GetExtState(appname,"window_pin")
  GUI.Val("main_checklist_windowpin", {(pin == "true" and true or false)}) -- window pin state (true = keep window open)
  GUI.Val("main_tabs", tonumber(reaper.GetExtState(appname, "window_tabfocus"))) -- last selected tab

  local subversionsOnly = reaper.GetExtState(appname, "filter_subversion")
  GUI.Val("tab1_checklist_subversionFilter", {(subversionsOnly == "true" and true or false)}) -- subversion filter
  UpdateSubversionFilter()
  
  if GUI.SWS_exists() then
    GUI.Val("themeslot_max", tonumber(reaper.GetExtState(appname, "themeslot_max"))) --  max number of available theme slots
  end

  RL_ExtStates_Load_FolderPaths()
  RL_ExtStates_Load_ThemeSlotAliases()
end

--------------------
-- Save Ext settings
--------------------
local function RL_ExtStates_Save()
  GUI.save_window_state(appname) -- window state
  reaper.SetExtState(appname, "window_pin", tostring(GUI.Val("main_checklist_windowpin")), 1) -- window pin state (true = keep window open)
  reaper.SetExtState(appname, "window_tabfocus", GUI.Val("main_tabs"), 1)  -- last selected tab
  reaper.SetExtState(appname, "filter_subversion", tostring(GUI.Val("tab1_checklist_subversionFilter")), 1)  -- subversion filter

  if GUI.SWS_exists() then
    reaper.SetExtState(appname, "themeslot_max", tostring(GUI.Val("options_themeslot_number")), 1) --  max number of available theme slots
  end  
end

-----------------
-- Main functions
------------------
GUI.Init() 
RL_ExtStates_Load()

GUI.onresize = function()
  local currentTab = tonumber(GUI.Val("main_tabs"))
    local dock_state,wx,wy,ww,wh = gfx.dock(-1,0,0,0,0)
    GUI.w = ww
    GUI.h = wh

    RL_SetWindowParameters()
    RL_RedrawAll()
    RL_ExtStates_Load()

    -- keep the last used tab focused
    GUI.Val("main_tabs", currentTab) 

    -- check for minimum window size
    if GUI.w < 610 then
      GUI.w = 610
      gfx.quit()
      gfx.init(GUI.name, GUI.w, GUI.h, 0, wx, wy)
      GUI.redraw_z[0] = true 
    end
    
    if GUI.h < 420 then
      GUI.h = 420
      gfx.quit()
      gfx.init(GUI.name, GUI.w, GUI.h, 0, wx, wy)
      GUI.redraw_z[0] = true 
    end
end

GUI.func = Main
GUI.freq = 0

reaper.atexit(function ()
  RL_ExtStates_Save()
end)

GUI.Main()

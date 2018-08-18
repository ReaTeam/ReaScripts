-- @description ReaLauncher
-- @author solger
-- @version 0.1.6
-- @changelog
--   + Code update for Linux support
--   + Listbox entries are now kept filtered when switching tabs
--   + Using the [Open in Explorer/Finder] Button on Track/Project Template tabs with empty listboxes also opens the default locations now
--   + [Options]-tab: Added info about multi-select in listboxes
-- @screenshot https://forum.cockos.com/showthread.php?t=208697
-- @about
--   # ReaLauncher 
--
--   A custom version of the startup prompt window for loading (recent) projects and project/track templates with additional features
--
--   ## Main features
--
--   - Separate tabs for Recent Projects, Project Templates and Track Templates
--   - Support for custom Project & Track Template folders (used in addition to the default locations)
--   - Simple list filter at the top of each tab
--   - [Open in Explorer/Finder] button for opening the folder location of the selected file
--   - Global [New Tab], [New Project] and [Open Project] buttons
--   - [Recent Projects]-Tab: 3 different sort options: 'Most Recent' projects at the top, 'Alphabetically' ascending and descending
--   - Selection and loading of multiple entries (multi-select of listbox entries is already part of Lokasenna's GUI library)
--   - File paths can be shown/hidden
--   - 'Keep window open' checkbox at the top right
--   - Resizeable window (currently requires restart of ReaLauncher afterwards)
--   - Experimental: [Projects] tab (projects folder can be set in the [Options])
--
--   - Uses Lokasenna's GUI library v2 (for LUA) as base: https://forum.cockos.com/showthread.php?t=177772. Big thanks to Lokasenna for his work!!
--
--   ## Discussion thread
--
--   https://forum.cockos.com/showthread.php?t=208697

------------------------------------------------------------------------------------------
local debugEnabled = false -- Set to 'true' in order to show debug messages in the console

-----------------------------
-- String Helper functions --
-----------------------------
local function MsgDebug(str)
    if debugEnabled then
      reaper.ShowConsoleMsg( tostring(str) .. "\n" )
    end
end

local function MsgError(str)
  reaper.ShowMessageBox(tostring(str),"Error", 0)
end

local function MsgInfo(str)
  reaper.ShowMessageBox(tostring(str),"Info", 0)
end

local function FilterNoCase(s)
    s = string.gsub(s, "%a", function (c)
          return "[" .. string.lower(c) .. string.upper(c) .. "]"
        end)
    return s
end

---------------------------------------------
-- Reaper resource paths and version infos --
---------------------------------------------
osversion =  reaper.GetOS()
local bitversionFull = reaper.GetAppVersion()
bitversion = string.sub(bitversionFull, #bitversionFull-2, #bitversionFull)
appname = "solger_ReaLauncher"

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

--------------------------------------------------------------------------------------------------------
-- Lokasenna's GUI library v2: 'The Core library must be loaded prior to any classes,
-- or the classes will throw up errors when they look for functions that aren't there.'
--------------------------------------------------------------------------------------------------------
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

if missing_lib then return 0 end -- If any of the requested libraries weren't found, abort the script.

----------------------------
-- Table helper functions --
----------------------------

-- Invert element order
local function InvertElementOrder(arr)
  local e1, e2 = 1, #arr
  while e1 < e2 do
    arr[e1], arr[e2] = arr[e2], arr[e1]
    e1 = e1 + 1
    e2 = e2 - 1
   end
end

-- Make a duplicate
isNotMostRecent = true
  
local function Duplicate(arr)
  cloned = true
  clone = {}

  i,v = next(arr, nil)
    while i do
      clone[i] = v
      i,v = next(arr,i)
    end
  return clone
end  

-- Join tables
function JoinTables(t1, t2)
  for k,v in ipairs(t2) do table.insert(t1, v) end 
  return t1
end

------------------------
-- File I/O functions --
------------------------
----------------------------------------
-- Used for Reaper 32-bit compatibility
----------------------------------------
-- enumerate all files in a given folder
local function EnumerateFiles(folder)
  local files = {}
  local i = 0
    repeat
      local retval = reaper.EnumerateFiles(folder, i)
      MsgDebug("enumerate: " .. folder .. "  |  " .. tostring(retval))

      if not retval then
      -- table.insert(files, tostring(folder) .. "\\" .. tostring(retval))
       table.insert(files,retval)
     end
     i = i + 1
    until not retval
  return files
end

-- scan all subdirectories of a given path
-- Found this in the Reaper Forum. Thanks to mpl and Lokasenna :)
function ScanPath(path)
    local tree = {}
    local subdirindex, fileindex = 0,0    
    local path_child
    
    repeat
      path_child = reaper.EnumerateSubdirectories(path, subdirindex)
        if path_child then 
          -- table.insert(t,path_child)
          local tmpPath = ScanPath(path .. "\\" .. path_child)
            for i = 1, #tmpPath do
              --table.insert(t, path .. "/" .. path_child .. "/" .. tmp[i])
               table.insert(tree, tmpPath[i])
            end
       end
    subdirindex = subdirindex+1
    until not path_child

    repeat
      fn = reaper.EnumerateFiles(path, fileindex)
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
function GetDirectoryPath(filepath)
  if osversion:find("Win") then
    -- Windows
    index = (filepath:reverse()):find("%\\")
  else
    -- macOS / Linux
    index = (filepath:reverse()):find("%/")
  end
  return string.sub(filepath, 1,#filepath-index)
end

-------------------------------------------------
-- Returns a table of files in the specified path
-- Adapted script from this thread: https://forum.cockos.com/showthread.php?t=206933
------------------------------------------------------------------------------------
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

--------------------------------------------------------
-- Return only .RPP and .RPP-BAK files from a given path
--------------------------------------------------------
local function GetRPPFiles(path)
    local files = {}
  
    for file in io.popen([[dir "]] .. path .. [[" /a:-d /s /b | sort]]):lines() do
      local fileExtension = string.sub(file,#file-3,#file)
        if string.find(fileExtension, FilterNoCase(".RPP")) or string.find(fileExtension, FilterNoCase("-BAK")) then
          files[#files + 1] = file
        end
      end
    MsgDebug("Get RPP Files (" .. path .. ")\n------\n" .. table.concat(files,"\n").."\n")
  return files
end

---------------------------------------------
-- Open the folder path in Explorer/Finder --
---------------------------------------------
function OpenLocationInExplorer(path)
  if osversion:find("OSX") then  
    os.execute('open "" "' .. path .. '"') -- macOS
  elseif osversion:find("Win") then  
    os.execute('start "" "' .. path .. '"') -- Windows    
  else
    os.execute('xdg-open \"' .. path .. '\"') -- Linux
  end
end           

---------------------------------------------
-- Open in Explorer/Finder - Helper functions
---------------------------------------------
-- recent projects
local function OpenLocation_RecentProject()
  if (noRecentProjects == false) then
    local selected = GUI.Val("lst_recentProjects")
    if type(selected) == "number" then selected = {[selected] = true} end
  
    local vals = {}
    for k, v in pairs(selected) do table.insert(vals, k) end  

    if #vals == 0 then MsgInfo("No files selected in the list!")
    else
      for p = 1, #vals do
        if RecentProjectFilterActive == true then selectedProject = recentProjects[filteredRecentProjects[vals[p]]]
        else selectedProject = recentProjects[recentProjItemsShort[vals[p]]] end
        OpenLocationInExplorer(GetDirectoryPath(selectedProject))
      end
    end
  end
end

-- project templates
local function OpenLocation_ProjectTemplates()
  if (noProjectTemplates == false) then
    local selected = GUI.Val("lst_projectTemplates")
    if type(selected) == "number" then selected = {[selected] = true} end
  
    local vals = {}
      for k, v in pairs(selected) do table.insert(vals, k) end
   
   if #vals == 0 then OpenLocationInExplorer(projectTemplatePath)
      else
     for p = 1, #vals do 
        if ProjectTemplateFilterActive == true then selectedProjectTemplate = projectTemplateItems[filteredProjectTemplates[vals[p]]]
        else selectedProjectTemplate = projectTemplateItems[projectTemplates[vals[p]]] end
        OpenLocationInExplorer(GetDirectoryPath(selectedProjectTemplate))
      end
    end
    else
      OpenLocationInExplorer(projectTemplatePath)
  end
end

-- track templates
local function OpenLocation_TrackTemplates()
  if (noTrackTemplates == false) then
    local selected = GUI.Val("lst_trackTemplates")
    if type(selected) == "number" then selected = {[selected] = true} end

    local vals = {}
    for k, v in pairs(selected) do table.insert(vals, k)end
   
   if #vals == 0 then OpenLocationInExplorer(trackTemplatePath)
   else
    for p = 1, #vals do
      if TrackTemplateFilterActive == true then selectedTrackTemplate = trackTemplateItems[filteredTrackTemplates[vals[p]]]
      else selectedTrackTemplate = trackTemplateItems[trackTemplates[vals[p]]] end
      OpenLocationInExplorer(GetDirectoryPath(selectedTrackTemplate)) 
    end 
   end
   else
     OpenLocationInExplorer(trackTemplatePath)
  end
end  

-- custom projects
local function OpenLocation_CustomProject()
    local selected = GUI.Val("lst_customProjects")
    if type(selected) == "number" then selected = {[selected] = true} end
    
    local vals = {}
    for k, v in pairs(selected) do table.insert(vals, k) end
    
    if #vals == 0 then
      if GUI.Val("opt_customProjects_Path") == "" then MsgInfo("No files selected in the list!")
      else
        OpenLocationInExplorer(GUI.Val("opt_customProjects_Path"))
      end
    else
      for p = 1, #vals do
        if CustomProjectsFilterActive == true then selectedProject = customProjectItems[filteredCustomProjects[vals[p]]]
        else selectedProject = customProjectItems[customProjects[vals[p]]] end
      OpenLocationInExplorer(GetDirectoryPath(selectedProject))
    end
  end
end

---------------------------
-- Open in Explorer - relay  
---------------------------
local function OpenInExplorer()  
   if GUI.Val("tabs") == 1 then
    OpenLocation_RecentProject()
   end
   if GUI.Val("tabs") == 2 then
    OpenLocation_ProjectTemplates()
   end
   if GUI.Val("tabs") == 3 then
     OpenLocation_TrackTemplates()
   end
   if GUI.Val("tabs") == 4 then
     OpenLocation_CustomProject()
   end
end

-----------------------------------------
-- Retrieve key values from reaper.ini --
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
-- Listbox content --
---------------------
-- recent project listbox
function FillRecentProjectsListbox()
  MsgDebug("Get Recent Files: \n------")
  recentProjItemsShort = {}
  recentProjItemsFull = {}
  recentProjects = {}
  
  local recentpathtag = {}
  local found = false;
  local p = 0
    
  repeat
    p = p + 1
    if p < 10 then recentpathtag[p] = "recent0" .. tostring(p)
    else recentpathtag[p] = "recent" .. tostring(p) end
    
    if GetReaperIniKeyValue(recentpathtag[p]) == nil then
      found = true
      break 
    else
      fullPath = GetReaperIniKeyValue(recentpathtag[p])
      if osversion:find("Win") then
        filename = fullPath:match "([^\\]-([^.]+))$" -- Windows: get (filename.extension) substring
      else
        filename = fullPath:match "([^/]-([^.]+))$" -- macOS / Linux: get (filename.extension) substring
      end
      MsgDebug(fullPath)
      recentProjItemsFull[p] = fullPath
      recentProjItemsShort[p] = string.sub(filename,1,#filename-4) -- get (filename) without .RPP 
      --[[ handling of .RPP-bak files
      if string.sub(recentProjItemsShort[p], #recentProjItemsShort[p]-3, #recentProjItemsShort[p]) == "-bak" then
        recentProjItemsShort[i] =  recentProjItemsShort[i] .. " (backup file)"
      end
      ]]--
    end
  until (found == true)

  if #recentProjItemsShort == 0 then noRecentProjects = true
  else 
    noRecentProjects = false  

    -- Reverse the element order in order to place the most recent entry at the top
    InvertElementOrder(recentProjItemsShort)
    InvertElementOrder(recentProjItemsFull)
  
    for i = 1, #recentProjItemsShort do
      recentProjects[recentProjItemsShort[i]] = recentProjItemsFull[i]
    end
  end
  MsgDebug("\n")
end

---------------------------
-- Project Template Listbox
---------------------------
local function FillProjectTemplateListbox()
  projectTemplateItems = {}
  projectTemplates = {}
  projectTemplateFiles = {}
  
  projectTemplateFiles = GetFiles(projectTemplatePath)
  local tempPath = reaper.GetExtState(appname, "custompath_projecttemplates")
  if #tempPath > 1 then
    local customProjectTemplateFiles = GetFiles(tempPath)
    JoinTables(projectTemplateFiles, customProjectTemplateFiles)
  end

  if #projectTemplateFiles == 0 then
    noProjectTemplates = true
  else
    noProjectTemplates = false  

    for i = 1, #projectTemplateFiles do
      if osversion:find("Win") then
        filename = projectTemplateFiles[i]:match "([^\\]-([^.]+))$" -- Windows: get (filename.extension) substring
      else
        filename = projectTemplateFiles[i]:match "([^/]-([^.]+))$" -- macOS / Linux: (filename.extension) 
      end
  
      projectTemplates[i] = string.sub(filename,1,#filename-4) -- get (filename) without .RPP
      -- handling of .RPP-bak files
      if string.sub(filename, #filename-3, #filename) == "-bak" then
        projectTemplates[i] =  string.sub(filename,1,#filename-8) .. "  (.rpp-bak file)"
      end
      projectTemplateItems[projectTemplates[i]] = projectTemplateFiles[i]
    end
  end
end

-------------------------
-- Track Template Listbox
-------------------------
local function FillTrackTemplateListbox()
  trackTemplateItems = {}
  trackTemplates = {}
  trackTemplateFiles = {}

  trackTemplateFiles = GetFiles(trackTemplatePath)
  
  local tempPath = reaper.GetExtState(appname, "custompath_tracktemplates")
  if #tempPath > 1 then 
    local customTrackTemplateFiles= GetFiles(tempPath)
    JoinTables(trackTemplateFiles, customTrackTemplateFiles)
  end
  
    if #trackTemplateFiles == 0 then
      noTrackTemplates = true
    else
      noTrackTemplates = false  
    
      for i = 1 , #trackTemplateFiles do
        if osversion:find("Win") then
          filename = trackTemplateFiles[i]:match "([^\\]-([^.]+))$" -- Windows: get (filename.extension) substring
        else
          filename = trackTemplateFiles[i]:match "([^/]-([^.]+))$" -- macOS / Linux: (filename.extension) 
        end
        trackTemplates[i] = string.sub(filename,1,#filename-15) -- get (filename) without .RTrackTemplate
        trackTemplateItems[trackTemplates[i]] = trackTemplateFiles[i]
       end
    end
end

-------------------------
-- Custom Project Listbox
-------------------------
local function FillCustomProjectsListbox()
  customProjects = {}
  customProjectItems = {}
  pos = 1
  
  if #custom_path_projects > 1 then
    
   if (osversion:find("Win")) and (bitversion == "x64") then
    customProjectFiles = GetRPPFiles(custom_path_projects)
   else
     customProjectFiles = GetFiles(custom_path_projects)
   end
  
     for i = 1, #customProjectFiles do
        if osversion:find("Win") then
          filename = customProjectFiles[i]:match "([^\\]-([^.]+))$" -- Windows: get (filename.extension) substring
        else
          filename = customProjectFiles[i]:match "([^/]-([^.]+))$" -- macOS / Linux: (filename.extension) 
        end

        -- handling of .RPP files  
        local fileExtension = string.sub(filename,#filename-3,#filename)
        if string.find(fileExtension, FilterNoCase(".RPP"))  then
          customProjects[pos] = string.sub(filename,1,#filename-4) -- get (filename) without .RPP
          customProjectItems[customProjects[pos]] = customProjectFiles[i]
          pos = pos + 1
        end
  
        -- handling of .RPP-bak files
        local bakExtension = string.sub(filename,#filename-4,#filename)
        if string.find(bakExtension, FilterNoCase("-BAK")) then
          customProjects[pos] =  string.sub(filename,1,#filename-8) .. "  (.rpp-bak file)"
          customProjectItems[customProjects[pos]] = customProjectFiles[i]
          pos = pos + 1
        end
     end
  end
end

-------------------------------------
-- Fill the listboxes with entries --
-------------------------------------
FillRecentProjectsListbox()
FillTrackTemplateListbox()
FillProjectTemplateListbox()

custom_path_projects = reaper.GetExtState(appname, "custompath_projects")
FillCustomProjectsListbox()

--------------------------------------
-- New project/tab button functions --
--------------------------------------
local function CheckWindowPinState()
  if GUI.Val("pin_box") == false then gfx.quit() end
end

local function New_Project()
  reaper.Main_OnCommand(40023, 0)
  CheckWindowPinState() 
end

local function New_ProjectTab()
  reaper.Main_OnCommand(40859, 0)
  CheckWindowPinState() 
end

local function New_Project_IgnoreTemplate()
  reaper.Main_OnCommand(41929, 0)
  CheckWindowPinState()
end

local function Open_Project()
  reaper.Main_OnCommand(40025, 0)
  CheckWindowPinState()
end

--------------------------------------
--  Recent project button functions --
--------------------------------------
-- load recent projects
local function Load_RecentProject()
  if (noRecentProjects == false) then
    local selected = GUI.Val("lst_recentProjects")
    if type(selected) == "number" then selected = {[selected] = true} end
  
    local vals = {}
    for k, v in pairs(selected) do table.insert(vals, k) end
  
    for p = 1, #vals do
      if RecentProjectFilterActive == true then selectedProject = recentProjects[filteredRecentProjects[vals[p]]]
      else selectedProject = recentProjects[recentProjItemsShort[vals[p]]] end
      -- if more than 1 project is selected, load the other projects in a tab
      if p > 1 then
        reaper.Main_OnCommand(40859, 0)
        reaper.Main_openProject(selectedProject) 
      else
         reaper.Main_openProject(selectedProject) 
      end
    end
      
    GUI.Val("lst_recentProjects",{})
    CheckWindowPinState()
  end
end

-- load recent projects in tab
local function LoadInTab_RecentProject()
if (noRecentProjects == false) then
  local selected = GUI.Val("lst_recentProjects")
    if type(selected) == "number" then selected = {[selected] = true} end

    local vals = {}
    for k, v in pairs(selected) do table.insert(vals, k)end

    for p = 1, #vals do
      if RecentProjectFilterActive == true then selectedProject = recentProjects[filteredRecentProjects[vals[p]]]
      else selectedProject = recentProjects[recentProjItemsShort[vals[p]]] end
      reaper.Main_OnCommand(40859, 0)
      reaper.Main_openProject(selectedProject) 
    end
  
    GUI.Val("lst_recentProjects",{})
    CheckWindowPinState()
  end
end

-------------------------------------
-- Custom project button functions --
-------------------------------------
-- load custom projects
local function Load_CustomProject()
   
  local selected = GUI.Val("lst_customProjects")
  if type(selected) == "number" then selected = {[selected] = true} end
  
  local vals = {}
  for k, v in pairs(selected) do table.insert(vals, k) end
  
  for p = 1, #vals do
  if CustomProjectsFilterActive == true then selectedProject = customProjectItems[filteredCustomProjects[vals[p]]]
  else selectedProject = customProjectItems[customProjects[vals[p]]] end
  -- if more than 1 project is selected, load the other projects in a tab
    if p > 1 then
      reaper.Main_OnCommand(40859, 0)
      reaper.Main_openProject(selectedProject) 
    else
      reaper.Main_openProject(selectedProject) 
    end
  end
  
  GUI.Val("lst_customProjects",{})
  CheckWindowPinState()
end

-- load custom projects in tab
local function LoadInTab_CustomProject()
    local selected = GUI.Val("lst_customProjects")
    if type(selected) == "number" then selected = {[selected] = true} end
    
    local vals = {}
    for k, v in pairs(selected) do table.insert(vals, k) end
    
    for p = 1, #vals do
      if CustomProjectsFilterActive == true then selectedProject = customProjectItems[filteredCustomProjects[vals[p]]]
      else selectedProject = customProjectItems[customProjects[vals[p]]] end
      reaper.Main_OnCommand(40859, 0)
      reaper.Main_openProject(selectedProject) 
    end
  
    GUI.Val("lst_customProjects",{})
    CheckWindowPinState()
end

------------------------------
-- Project Template buttons --
------------------------------
-- load project templates
local function Load_ProjectTemplate()
  if (noProjectTemplates == false) then
    local selected = GUI.Val("lst_projectTemplates")
    if type(selected) == "number" then selected = {[selected] = true} end
  
    local vals = {}
      for k, v in pairs(selected) do table.insert(vals, k) end
   
    for p = 1, #vals do 
      if ProjectTemplateFilterActive == true then selectedProjectTemplate = projectTemplateItems[filteredProjectTemplates[vals[p]]]
      else selectedProjectTemplate = projectTemplateItems[projectTemplates[vals[p]]] end
      -- if more than 1 project is selected, load the other projects in a tab 
      if p > 1 then
        reaper.Main_OnCommand(40859, 0)
        reaper.Main_openProject(selectedProjectTemplate) 
      else
        reaper.Main_openProject(selectedProjectTemplate) 
     end
  end  
  
    CheckWindowPinState()
  end
end

-- load project templates in tab
local function LoadInTab_ProjectTemplate()
  if (noProjectTemplates == false) then
    local selected = GUI.Val("lst_projectTemplates")
    if type(selected) == "number" then selected = {[selected] = true} end
  
    local vals = {}
      for k, v in pairs(selected) do table.insert(vals, k) end
   
    for p = 1, #vals do 
      if ProjectTemplateFilterActive == true then selectedProjectTemplate = projectTemplateItems[filteredProjectTemplates[vals[p]]]
      else selectedProjectTemplate = projectTemplateItems[projectTemplates[vals[p]]] end
      reaper.Main_OnCommand(40859, 0)
      reaper.Main_openProject(selectedProjectTemplate) 
    end  
    
    CheckWindowPinState()
  end
end

-------------------------------------
-- Track Template button functions --
-------------------------------------
local function Load_TrackTemplate()
  if (noTrackTemplates == false) then
    local selected = GUI.Val("lst_trackTemplates")
    if type(selected) == "number" then selected = {[selected] = true} end
    
    local vals = {}
     for k, v in pairs(selected) do table.insert(vals, k) end
    
    for p = 1, #vals do
      if TrackTemplateFilterActive == true then selectedTrackTemplate = trackTemplateItems[filteredTrackTemplates[vals[p]]]
      else selectedTrackTemplate = trackTemplateItems[trackTemplates[vals[p]]] end
      reaper.Main_openProject(selectedTrackTemplate) 
    end 

    CheckWindowPinState()
  end
end  
  
--------------------
-- Sort functions --
--------------------
-- most recent at the top
local function Sort_MostRecent()
  if isNotMostRecent == false then
    recentProjItemsShort = Duplicate(previousProjectItems)
    GUI.elms.lst_recentProjects.list = previousProjectItems
  end
end

-- alphabetically - ascending
local function Sort_Alphabetically_Ascending()
  if isNotMostRecent then
    previousProjectItems = Duplicate(recentProjItemsShort)
    isNotMostRecent = false
  end
    
  table.sort(recentProjItemsShort, function(a, b) return a:lower() < b:lower() end)
  GUI.elms.lst_recentProjects.list = recentProjItemsShort
end

-- alphabetically - descending
local function Sort_Alphabetically_Descending()
  if isNotMostRecent then
    previousProjectItems = Duplicate(recentProjItemsShort)
    isNotMostRecent = false
  end
    
  table.sort(recentProjItemsShort, function(a, b) return b:lower() < a:lower() end)
  GUI.elms.lst_recentProjects.list = recentProjItemsShort
end

---------------------
-- Sort Mode relay --
---------------------
local function HidePaths()
  GUI.Val("menu_showPath", {1})
end

local function UpdateSortMode()
  local sortMode = GUI.Val("menu_sortMode")
  local alphabetOrder = GUI.Val("menu_sortAlphabetically")  

  if sortMode == 1 then
    GUI.elms.menu_sortAlphabetically.z = 10
    Sort_MostRecent()
  else
    GUI.elms.menu_sortAlphabetically.z = 3
    if alphabetOrder == 1 then
      Sort_Alphabetically_Ascending()
    else
      Sort_Alphabetically_Descending()
    end
  end
  HidePaths()
end

------------------------
-- Path Display relay --
------------------------
function UpdatePathDisplayMode()
  local pathMode = GUI.Val("menu_showPath")
  if pathMode == 1 then
    showFullPaths = false
    GUI.elms.lst_recentProjects.list = recentProjItemsShort
    GUI.elms.lst_projectTemplates.list = projectTemplates
    GUI.elms.lst_trackTemplates.list = trackTemplates
    GUI.elms.lst_customProjects.list = customProjects
  else 
    showFullPaths = true
    GUI.elms.lst_recentProjects.list = recentProjItemsFull
    GUI.elms.lst_projectTemplates.list = projectTemplateFiles
    GUI.elms.lst_trackTemplates.list = trackTemplateFiles
    GUI.elms.lst_customProjects.list = customProjectFiles
  end
  
  GUI.elms.lst_recentProjects:redraw()
  GUI.elms.lst_projectTemplates:redraw()
  GUI.elms.lst_trackTemplates:redraw()
  GUI.elms.lst_customProjects:redraw()
end

-----------------------------
-- Filter update functions --
-----------------------------
-- Recent Projects tab
local function UpdateListFilter_RecentProjects()
  if RecentProjectFilterActive then
    GUI.elms.lst_recentProjects.list = filteredRecentProjects
  else
    UpdateSortMode()
  end
end

-- Project Templates tab
local function UpdateListFilter_ProjectTemplates()
  if ProjectTemplateFilterActive then
    GUI.elms.lst_projectTemplates.list = filteredProjectTemplates
  else
    GUI.elms.lst_projectTemplates.list = projectTemplates 
  end
end

-- Track Templates tab
local function UpdateListFilter_TrackTemplates()
  if TrackTemplateFilterActive then
    GUI.elms.lst_trackTemplates.list = filteredTrackTemplates
  else
   GUI.elms.lst_trackTemplates.list = trackTemplates
  end
end

local function UpdateListFilter_CustomProjects()
  if CustomProjectsFilterActive then
    GUI.elms.lst_customProjects.list = filteredCustomProjects
  else
    GUI.elms.lst_customProjects.list = customProjects
  end
end

-- Update Filter on all Tabs
local function UpdateListFilter_All()
  UpdateListFilter_RecentProjects()
  UpdateListFilter_ProjectTemplates()
  UpdateListFilter_TrackTemplates()
  UpdateListFilter_CustomProjects()
  HidePaths()
end

----------------------
-- Filter functions --
----------------------
RecentProjectFilterActive = false
TrackTemplateFilterActive = false
ProjectTemplateFilterActive = false
CustomProjectsFilterActive = false

-- filter recent projects
local function Filter_RecentProject_Apply()
  filteredRecentProjects = {}
  
  local searchStr = GUI.Val("tb_filterRecentProjects")
  searchStr = FilterNoCase(searchStr) 

  for i = 1, #recentProjItemsShort do
   if string.find(recentProjItemsShort[i], searchStr) then
       filteredRecentProjects[recentProjItemsShort[i]] = recentProjItemsFull[i]
       table.insert(filteredRecentProjects, recentProjItemsShort[i])
   end
 end
 
  RecentProjectFilterActive = true
  UpdateListFilter_RecentProjects()

  GUI.Val("lst_recentProjects",{})
  HidePaths()
end

-- filter project templates
local function Filter_ProjectTemplate_Apply()
  filteredProjectTemplates = {}
  local searchStr = GUI.Val("tb_filterProjectTemplates")
  searchStr = FilterNoCase(searchStr) 

  for i = 1, #projectTemplates do
   if string.find(projectTemplates[i], searchStr) then
      filteredProjectTemplates[projectTemplates[i]] = projectTemplates[i]
      table.insert(filteredProjectTemplates, projectTemplates[i])
   end  
 end
 
  ProjectTemplateFilterActive = true
  UpdateListFilter_ProjectTemplates()

  GUI.Val("lst_projectTemplates",{})
  HidePaths()
end

-- filter track templates
local function Filter_TrackTemplate_Apply()
  filteredTrackTemplates = {}
  
  local searchStr = GUI.Val("tb_filterTrackTemplates")
  searchStr = FilterNoCase(searchStr) 

  for i = 1, #trackTemplates do
   if string.find(trackTemplates[i], searchStr) then
       filteredTrackTemplates[trackTemplates[i]] = trackTemplates[i]
       table.insert(filteredTrackTemplates, trackTemplates[i])
   end
 end

 TrackTemplateFilterActive = true
 UpdateListFilter_TrackTemplates()
  
 GUI.Val("lst_trackTemplates",{})
 HidePaths()
end

-- filter custom projects
local function Filter_CustomProjects_Apply()
  filteredCustomProjects = {}
  
  local searchStr = GUI.Val("tb_filterCustomProjects")
  searchStr = FilterNoCase(searchStr) 

   for i = 1, #customProjects do
     if string.find(customProjects[i], searchStr) then
         filteredCustomProjects[customProjects[i]] = customProjects[i]
         table.insert(filteredCustomProjects, customProjects[i])
     end
   end

--  customProjectItems[customProjects[i]] = customProjectFiles[i]
  CustomProjectsFilterActive = true
  UpdateListFilter_CustomProjects()
  
  GUI.Val("lst_customProjects",{})
  HidePaths()
end

-------------------------------
-- Refresh Listbox functions --
-------------------------------
local function Refresh_RecentProjects()
  FillRecentProjectsListbox()

  if showFullPaths then GUI.elms.lst_recentProjects.list = recentProjItemsFull
  else GUI.elms.lst_recentProjects.list = recentProjItemsShort end

  UpdateSortMode()
  GUI.elms.lst_recentProjects:redraw()
end

local function Refresh_ProjectTemplates()
  FillProjectTemplateListbox()

  if showFullPaths then GUI.elms.lst_projectTemplates.list = projectTemplateFiles
  else GUI.elms.lst_projectTemplates.list = projectTemplates end

  UpdatePathDisplayMode()
  GUI.elms.lst_projectTemplates:redraw()
end

local function Refresh_TrackTemplates()
  FillTrackTemplateListbox()
 
  if showFullPaths then GUI.elms.lst_trackTemplates.list = trackTemplateFiles
  else GUI.elms.lst_trackTemplates.list = trackTemplates end  
 
  UpdatePathDisplayMode()
  GUI.elms.lst_trackTemplates:redraw()
end

local function Refresh_CustomProjects()
  FillCustomProjectsListbox()

  if showFullPaths then GUI.elms.lst_customProjects.list = customProjectFiles
  else GUI.elms.lst_customProjects.list = customProjects end

  UpdatePathDisplayMode()
  GUI.elms.lst_customProjects:redraw()
end

------------------------
-- Clear custom paths --
------------------------
-- clear custom project template path
function Path_Clear_ProjectTemplates()
  GUI.Val(opt_projectTemplates_Path,"")
  GUI.elms.lst_projectTemplates.list = {}
  
  reaper.DeleteExtState(appname, "custompath_projecttemplates",1)
  Refresh_ProjectTemplates()
  MsgInfo("Additional project template folder removed")
end

-- clear custom track template path
function Path_Clear_TrackTemplates()
  GUI.Val(opt_trackTemplates_Path,"")
  GUI.elms.lst_trackTemplates.list = {}
  
  reaper.DeleteExtState(appname, "custompath_tracktemplates",1)
  Refresh_TrackTemplates()
  MsgInfo("Additional track template folder removed")
end

-- clear custom projects path
function Path_Clear_CustomProjects()
  custom_path_projects = {}
  customProjects = {}
  customProjectItems = {}
  GUI.Val(custom_projects_Path,"")
  GUI.elms.lst_customProjects.list = {}

  reaper.DeleteExtState(appname, "custompath_projects",1)
  MsgInfo("Custom project folder removed")
  Refresh_CustomProjects()
end

----------------------
-- Set custom paths --
----------------------
-- set custom project template path
function Path_Set_ProjectTemplates()
  custom_path_projects = GUI.Val("opt_projectTemplates_Path")
  if custom_path_projects == "" then
    MsgInfo("Please enter a custom project template folder path first!")
  else
    reaper.SetExtState(appname, "custompath_projecttemplates",custom_path_projects,1)
    Refresh_ProjectTemplates()
    MsgInfo("Additional project template folder set to " .. custom_path_projects)
  end
end

-- set  track template path
function Path_Set_TrackTemplates()
  custom_path_projects = GUI.Val("opt_trackTemplates_Path")
  if custom_path_projects == "" then
    MsgInfo("Please enter a custom track template folder path first!")
  else
    reaper.SetExtState(appname, "custompath_tracktemplates",custom_path_projects,1)
    Refresh_TrackTemplates()
    MsgInfo("Additional track template folder set to " .. custom_path_projects)
  end
end

-- set custom projects path
function Path_Set_CustomProjects()
  custom_path_projects = GUI.Val("opt_customProjects_Path")
  if custom_path_projects == "" then 
    MsgInfo("Please enter a custom project folder path first!")
  else
    reaper.SetExtState(appname, "custompath_projects",custom_path_projects,1)
    Refresh_CustomProjects()
    MsgInfo("Custom project folder set to " .. custom_path_projects)
  end
end

---------------------
-- Window settings --
---------------------
GUI.name = "ReaLauncher"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 620, 600
GUI.anchor, GUI.corner = "mouse", "C" -- Center on "mouse" or "screen"
GUI.load_window_state(appname)

function SetWindowParameters()
  -- button size
  btn_w = 150
  btn_h = 28

  -- global element indents
  pad_left = 10
  pad_top = 30

  -- listbox size
  listbox_top = 62
  listbox_w = GUI.w - 180
  listbox_h = GUI.h - 65

  -- button indents
  btn_pad_left = listbox_w + 18
  btn_pad_top = 160
  btn_pad_add = 35
  btn_tab_top = 345
end

SetWindowParameters()


ttLoadFXoffline = "To load with FX offline: \n\n- Hold 'Ctrl + Shift' (Windows & Linux)\n- Hold 'Cmd + Shift' (macOS)\n- Or use the option in the [Open Project] window"

---------------------------------
-- Main GUI Elements
---------------------------------
function DrawElements_Main()

  -- layer 1
  GUI.New("tabs", "Tabs", 1, 0, 0, 100, 20, "Recent Projects, Project Templates, Track Templates, Projects, Options", 16)
  
  -- Tab | Layers
   GUI.elms.tabs:update_sets(
     { [1] = {2,3},
       [2] = {2,4},
       [3] = {2,5},
       [4] = {2,6},
       [5] = {7},
     }
   )

  function GUI.elms.tabs:onmousedown()
    GUI.Tabs.onmousedown(self)
    UpdatePathDisplayMode()
    UpdateListFilter_All()
  end

  -- layer 2
  GUI.New("pin_label", "Label", 2, GUI.w - 152, pad_top + 2, "Keep window open:", false, 3)
  GUI.elms.pin_label.tooltip = "Check the box to keep the window open"
  GUI.New("pin_box", "Checklist", 2, GUI.w - 40, pad_top, 20, 20, "", "", "h", 0)
  GUI.elms.pin_box.tooltip = "Check this box to keep the window open"

  GUI.New("menu_showPath", "Menubox", 2, btn_pad_left + 70, 70, 70, 20, "File paths:", "Hide, Show")
  GUI.elms.menu_showPath.tooltip = "Show/Hide file paths in the list"
  
  GUI.New("btn_openInExplorer", "Button", 2, btn_pad_left, 110, btn_w, btn_h, "Open in Explorer/Finder", OpenInExplorer)
  GUI.elms.btn_openInExplorer.tooltip = "Open the selected file location in Explorer/Finder"
  
  GUI.New("btn_newProjectTab", "Button", 2, btn_pad_left, btn_pad_top, btn_w, btn_h, "New Tab", New_ProjectTab) 
  GUI.elms.btn_newProjectTab.tooltip = "Add new project tab"
 
  GUI.New("btn_loadIgnoreTemplate", "Button", 2, btn_pad_left, btn_pad_top + btn_pad_add, btn_w, btn_h, "Ignore Template", New_Project_IgnoreTemplate)
  GUI.elms.btn_loadIgnoreTemplate.tooltip = "Add new project tab (ignore template)"

  GUI.New("btn_newProject", "Button", 2, btn_pad_left, btn_pad_top + 95, btn_w, btn_h, "New Project", New_Project) 
  GUI.elms.btn_newProject.tooltip = "Create new project"
  
  GUI.New("btn_OpenProject", "Button", 2, btn_pad_left, btn_pad_top + 130, btn_w, btn_h, "Open Project", Open_Project) 
   GUI.elms.btn_OpenProject.tooltip = "Open a project file via the 'Open project' window"
  
  -- listeners
  function GUI.elms.menu_showPath:onmousedown()
    GUI.Menubox.onmouseup(self)
    UpdatePathDisplayMode()
  end
  
  function GUI.elms.menu_showPath:onwheel()
    GUI.Menubox.onwheel(self)
    UpdatePathDisplayMode()
  end
    
end

-- frames
local function DrawFrames()
  GUI.New("frame_top",  "Frame", 1, 0, 56, GUI.w, 2, false, true)
  GUI.New("frame_side_1",  "Frame", 2, pad_left + listbox_w , 100, GUI.w - pad_left - listbox_w, 2, true, true)
  GUI.New("frame_side_2",  "Frame", 2, pad_left + listbox_w , 145, GUI.w - pad_left - listbox_w, 2, true, true)
  GUI.New("frame_side_3",  "Frame", 2, pad_left + listbox_w , 240, GUI.w - pad_left - listbox_w, 2, true, true)
  GUI.New("frame_side_4",  "Frame", 2, pad_left + listbox_w , 330, GUI.w - pad_left - listbox_w, 2, true, true)
  GUI.New("frame_side_5",  "Frame", 2, pad_left + listbox_w , 420, GUI.w - pad_left - listbox_w, 2, true, true)
end

--------------------------------------
-- Tab 1 Elements - Recent Projects --
--------------------------------------
function DrawElements_Tab1()

  GUI.New("btn_RecentProjectsRefresh", "Button", 3, 10, pad_top - 2, 20,  22, "R", Refresh_RecentProjects)
  GUI.elms.btn_RecentProjectsRefresh.tooltip = "Refresh [Recent Projects] list"
  
  GUI.New("tb_filterRecentProjects", "Textbox", 3, 80, pad_top, 260, 20, "Filter:", 8)
  GUI.elms.tb_filterRecentProjects.tooltip = "Type something in to filter the [Recent Projects] list"

  GUI.New("menu_sortMode", "Menubox", 3, 385, 30, 110, 20, "Sort:", "Most Recent,Alphabetically")
  GUI.elms.menu_sortMode.tooltip = "Sort options: [Most recent] at the top or [Alphabetically]"
  
  GUI.New("menu_sortAlphabetically", "Menubox", 3, 500, 30, 95, 20, "", ",Ascending,Descending")
  GUI.elms.menu_sortAlphabetically.tooltip = "Sort the list alphabetically ascending or descending"
  GUI.elms.menu_sortAlphabetically.z = 10
 
  GUI.New("lst_recentProjects", "Listbox", 3, pad_left, listbox_top, listbox_w, listbox_h,"", true)
  GUI.elms.lst_recentProjects.list = recentProjItemsShort
 
  GUI.New("btn_loadRecentProjectInTab", "Button", 3, btn_pad_left, btn_tab_top, btn_w,  btn_h, "Load in Tab", LoadInTab_RecentProject)
  GUI.elms.btn_loadRecentProjectInTab.tooltip = "Load selected recent project(s) in tab(s)\n\n" .. ttLoadFXoffline

  GUI.New("btn_loadRecentProject", "Button", 3, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_RecentProject)
  GUI.elms.btn_loadRecentProject.tooltip = "Load selected recent project(s)\n\n" .. ttLoadFXoffline

  -- listeners
  function GUI.elms.lst_recentProjects:ondoubleclick()
    Load_RecentProject()
  end
  
  function GUI.elms.tb_filterRecentProjects:ontype()
     GUI.Textbox.ontype(self)
     Filter_RecentProject_Apply()
  end

  -- sort mode (most recent / alphabetically)
  function GUI.elms.menu_sortMode:onmousedown()
    if (noRecentProjects == false) then
      GUI.Menubox.onmouseup(self)
      UpdateSortMode()
    end
  end
  
  function GUI.elms.menu_sortMode:onwheel()
    if (noRecentProjects == false) then
      GUI.Menubox.onwheel(self)
      UpdateSortMode()
    end
  end
  
  -- sort alphabetically (ascending/descending)
  function GUI.elms.menu_sortAlphabetically:onmousedown()
    if (noRecentProjects == false) then
        GUI.Menubox.onmouseup(self)
        UpdateSortMode()
    end
  end
    
    function GUI.elms.menu_sortAlphabetically:onwheel()
      if (noRecentProjects == false) then
          GUI.Menubox.onwheel(self)
          UpdateSortMode()
      end
    end

end
----------------------------------------
-- Tab 2 Elements - Project Templates --
----------------------------------------
function DrawElements_Tab2()
 
  GUI.New("btn_projectTemplatesRefresh", "Button", 4, 10, pad_top-2, 20,  22,"R", Refresh_ProjectTemplates)
  GUI.elms.btn_projectTemplatesRefresh.tooltip = "Refresh [Project Templates] list"
  
  GUI.New("tb_filterProjectTemplates", "Textbox", 4, 80, pad_top, 260, 20, "Filter:", 8)
  GUI.elms.tb_filterProjectTemplates.tooltip = "Type something in to filter the [Project Templates] list"
  
  GUI.New("lst_projectTemplates", "Listbox", 4, pad_left, listbox_top, listbox_w, listbox_h, "", true)
  GUI.elms.lst_projectTemplates.list = projectTemplates
  
  GUI.New("btn_loadProjectTemplateInTab", "Button", 4, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_ProjectTemplate)
  GUI.elms.btn_loadProjectTemplateInTab.tooltip = "Load selected project template(s) in tab(s)\n\n" .. ttLoadFXoffline
  
  GUI.New("btn_loadProjectTemplate", "Button", 4, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_ProjectTemplate)
  GUI.elms.btn_loadProjectTemplate.tooltip = "Load selected project templates(s)\n\n" .. ttLoadFXoffline

  -- listeners
  function GUI.elms.lst_projectTemplates:ondoubleclick()
    Load_ProjectTemplate()
  end
  
  function GUI.elms.tb_filterProjectTemplates:ontype()
     GUI.Textbox.ontype(self)
     Filter_ProjectTemplate_Apply()
  end
  
end
--------------------------------------
-- Tab 3 Elements - Track Templates --
--------------------------------------
function DrawElements_Tab3()

  GUI.New("btn_trackTemplatesRefresh", "Button", 5, 10, pad_top-2, 20, 22, "R", Refresh_TrackTemplates)
  GUI.elms.btn_trackTemplatesRefresh.tooltip = "Refresh the [Track Templates] list"
 
  GUI.New("tb_filterTrackTemplates", "Textbox", 5, 80, pad_top, 260, 20, "Filter:", 8)
  GUI.elms.tb_filterTrackTemplates.tooltip = "Type something in to filter the [Track Templates] list"

  GUI.New("lst_trackTemplates", "Listbox", 5, pad_left, listbox_top, listbox_w, listbox_h, "", true)
  GUI.elms.lst_trackTemplates.list = trackTemplates
  
  GUI.New("btn_insertTrackTemplate", "Button", 5, btn_pad_left, btn_tab_top + 20, btn_w, btn_h, "Insert", Load_TrackTemplate)
  GUI.elms.btn_insertTrackTemplate.tooltip = "Insert selected track template(s)"
 
  -- listeners
  function GUI.elms.lst_trackTemplates:ondoubleclick()
    Load_TrackTemplate()
  end
  
  function GUI.elms.tb_filterTrackTemplates:ontype()
     GUI.Textbox.ontype(self)
     Filter_TrackTemplate_Apply()
  end
 
end

-------------------------------
-- Tab 4 Elements - Projects --
------------------------------
function DrawElements_Tab4()

  GUI.New("btn_filterCustomProjects", "Button", 6, 10, pad_top-2, 20, 22, "R", Refresh_CustomProjects)
  GUI.elms.btn_filterCustomProjects.tooltip = "Refresh [Projects] list"
 
  GUI.New("tb_filterCustomProjects", "Textbox", 6, 80, pad_top, 260, 20, "Filter:", 8)
  GUI.elms.tb_filterCustomProjects.tooltip = "Type something in to filter the [Projects] list"
  
  GUI.New("lst_customProjects", "Listbox", 6, pad_left, listbox_top, listbox_w, listbox_h, "", true)
  GUI.elms.lst_customProjects.list = customProjects
   
  GUI.New("btn_loadCustomProjectInTab", "Button", 6, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", LoadInTab_CustomProject)
  GUI.elms.btn_loadCustomProjectInTab.tooltip = "Load the selected project(s) in tab(s)\n\n" .. ttLoadFXoffline
  
  GUI.New("btn_loadCustomProject", "Button", 6, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", Load_CustomProject)
  GUI.elms.btn_loadCustomProject.tooltip = "Load the selected project(s)\n\n" .. ttLoadFXoffline
  
  -- listeners
  function GUI.elms.lst_customProjects:ondoubleclick()
    Load_CustomProject()
  end
    
  function GUI.elms.tb_filterCustomProjects:ontype()
     GUI.Textbox.ontype(self)
     Filter_CustomProjects_Apply()
  end
  
end

------------------------------
-- Tab 5 Elements - Options --
------------------------------

function DrawElements_Tab5()

  -- custom project template folder
  GUI.New("opt_projectTemplates_Clear", "Button", 7, 40, pad_top * 4, 55, 20, "Remove", Path_Clear_ProjectTemplates)
  GUI.elms.opt_projectTemplates_Clear.tooltip = "Remove project template folder path"
  
  GUI.New("opt_projectTemplates_Path", "Textbox", 7, 100, pad_top * 4, GUI.w-340, 20, "Additional [Project Templates] folder:", 8)
  GUI.elms.opt_projectTemplates_Path.cap_pos = "top"
  GUI.elms.opt_projectTemplates_Path.tooltip = "Enter a custom project template folder path"

  GUI.New("opt_projectTemplates_Set", "Button", 7, GUI.w - 235, pad_top * 4, 40, 20, "Set", Path_Set_ProjectTemplates)
  GUI.elms.opt_projectTemplates_Set.tooltip = "Set the given path as additional Project Template folder"

  -- custom track template folder
  GUI.New("opt_trackTemplates_Clear", "Button", 7, 40, pad_top * 6, 55, 20, "Remove", Path_Clear_TrackTemplates)
  GUI.elms.opt_trackTemplates_Clear.tooltip = "Remove track template folder path"

  GUI.New("opt_trackTemplates_Path", "Textbox", 7, 100, pad_top * 6, GUI.w-340, 20, "Additional [Track Templates] folder:", 8)
  GUI.elms.opt_trackTemplates_Path.cap_pos = "top"
  GUI.elms.opt_trackTemplates_Path.tooltip = "Enter a custom track template folder path"

  GUI.New("opt_trackTemplates_Set", "Button", 7, GUI.w - 235, pad_top * 6, 40, 20, "Set", Path_Set_TrackTemplates)
  GUI.elms.opt_trackTemplates_Set.tooltip = "Set the given path as additional Track Template folder"

  -- custom project folder
  GUI.New("opt_customProjects_Clear", "Button", 7, 40, pad_top * 8, 55, 20, "Remove", Path_Clear_CustomProjects)
  GUI.elms.opt_customProjects_Clear.tooltip = "Remove project folder path"

  GUI.New("opt_customProjects_Path", "Textbox", 7, 100, pad_top * 8, GUI.w-340, 20, "[Projects] folder:", 8)
  GUI.elms.opt_customProjects_Path.cap_pos = "top"
  GUI.elms.opt_customProjects_Path.tooltip = "Enter a custom project folder path"

  GUI.New("opt_customProjects_Set", "Button", 7, GUI.w - 235, pad_top * 8, 40, 20, "Set", Path_Set_CustomProjects)
  GUI.elms.opt_customProjects_Set.tooltip = "Set the given path as project folder"
 
  GUI.New("opt_description1", "Label", 7, 40, 70, "[Set] or [Remove] custom folder paths for the following tabs: ")
  GUI.elms.opt_description1.font = 3

  GUI.New("opt_description4", "Label", 7, 40, 300, "The [Template] folders are used in addition to the default template folder locations.")
  GUI.elms.opt_description4.font = 3
  
  GUI.New("opt_selectiontext", "Label", 7, 40, 360, "Multi-Select:\n\n- 'Shift + Left Mouse Click':             adjacent listbox entries \n- 'Ctrl/Cmd + Left Mouse Click':     non-adjacent listbox entries\n\n- Loading a single listbox entry directly via 'Double-Click' is also possible")
  GUI.elms.opt_selectiontext.font = 3
  
  GUI.New("frame_options_1",  "Frame", 7, 0 , 340, GUI.w, 2, true, true)

end

-----------------------
-- Draw all elements --
-----------------------
function DrawAllTabs()
  DrawElements_Tab1()
  DrawElements_Tab2()
  DrawElements_Tab3()
  DrawElements_Tab4()
  DrawElements_Tab5()
end

DrawElements_Main()
DrawAllTabs()
DrawFrames()
-----------------------
-- Load Ext settings --
-----------------------
local function Load_ExtSettings()

local pin = reaper.GetExtState(appname,"window_pin")
  GUI.Val("pin_box", {(pin == "true" and true or false)}) -- window pin state (true = keep window open)
  GUI.Val("tabs", tonumber(reaper.GetExtState(appname, "last_tab"))) -- last selected tab

  -- load custom paths
  GUI.elms.opt_projectTemplates_Path:val(reaper.GetExtState(appname, "custompath_projecttemplates"))
  GUI.elms.opt_trackTemplates_Path:val(reaper.GetExtState(appname, "custompath_tracktemplates"))
  GUI.elms.opt_customProjects_Path:val(reaper.GetExtState(appname, "custompath_projects"))
end

-----------------------
-- Save Ext settings --
-----------------------
local function Save_ExtSettings()
  GUI.save_window_state(appname) -- window state
  reaper.SetExtState(appname, "window_pin", tostring(GUI.Val("pin_box")),1) -- window pin state (true = keep window open)
  reaper.SetExtState(appname, "last_tab", GUI.Val("tabs"), 1)  -- last selected tab
end

--------------------
-- Main functions --
--------------------
GUI.Init() 
Load_ExtSettings()

GUI.func = Main
GUI.freq = 0

reaper.atexit(function ()
  Save_ExtSettings()
end)

GUI.Main()

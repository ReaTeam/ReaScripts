-- @description ReaLauncher
-- @author solger
-- @version 0.1.3
-- @changelog
--   + filter is now case-insensitive
--   + last window pin state (pinned/unpinned) is now remembered
--   + last openend tab is now remembered
--   + added 'New project (ignore default template)' button
--   + code improvements for switching back to 'Most recent' sort option
--   + adjustable window size (experimental) - requires restart of ReaLauncher afterwards
--   + adapted file reading function for Reaper 32-bit compatibility
-- @screenshot https://forum.cockos.com/attachment.php?attachmentid=34088&stc=1&d=1530957174
-- @about
--   # ReaLauncher 
--
--   A custom version of the startup prompt window for loading (recent) projects and project/track templates with additional features
--
--   ## Screenshot
--
--   https://forum.cockos.com/attachment.php?attachmentid=34088&stc=1&d=1530957174
--
--   ## Main features
--
--   - Separate Tabs for Recent Projects, Project Templates and Track Templates
--   - Simple pattern-matching filter at the top of each Tab
--   - Global buttons for 'New Tab' and 'New Project'
--   - [Recent Projects]-Tab: 3 different sort options: 'most recent' projects at the top, alphabetically ascending or descending
--   - Selection and loading of multiple entries (multi-selection is already part of Lokasenna's GUI library for LUA)
--   - 'PIN'-box at the top right: keeps the window open when checked
--
--   Uses Lokasenna's GUI library v2 (for LUA) as base: https://forum.cockos.com/showthread.php?t=177772
--   Big thanks to Lokasenna for his work!!

--   ## Discussion thread
--
--   https://forum.cockos.com/showthread.php?t=208697

------------------------------------------------------------------------------------------
local debugEnabled = false -- Set to 'true' in order to show debug messages in the console

----------------------
-- Helper functions --
----------------------
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

bitversion = reaper.GetAppVersion()
bitversion = string.sub(bitversion, #bitversion-2, #bitversion)
appname = "solger_ReaLauncher"

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

-------------------------------
-- Get Reaper resource paths --
-------------------------------
reaperIniPath = reaper.get_ini_file()
resourcePath = reaper.GetResourcePath()
if (resourcePath == nil) then MsgError("Could not retrieve the Reaper resource path!") end

trackTemplatePath = resourcePath .. "/TrackTemplates"
projectTemplatePath = resourcePath .. "/ProjectTemplates"

---------------------------------------
-- Used for Reaper 32-bit compatibility
---------------------------------------
local function EnumerateFiles(folder)
  local files = {}
  local i = 0
    repeat
      local retval = reaper.EnumerateFiles(folder, i)
      table.insert(files, retval)
      i = i + 1
    until not retval
  return files
end

------------------------------------------------------------------------------------
-- Returns a table of files in the specified path
-- Adapted script from this thread: https://forum.cockos.com/showthread.php?t=206933
------------------------------------------------------------------------------------
local function GetFiles(path)
  local files = {}

  if reaper.GetOS():find("OSX") then
    -- macOS
    for file in io.popen([[find ]] .. path .. [[ -maxdepth 1 -type f -not -name '.*']]):lines() do
      files[#files + 1] = file
    end
    else
      if bitversion == 'x64' then
        -- Windows (Reaper 64-bit)
        for file in io.popen([[dir "]] .. path .. [[" /a:-d /s /b | sort]]):lines() do
          files[#files + 1] = file
        end
      else
        -- Windows (Reaper 32-bit)
        files = EnumerateFiles(path)
        for i=1, #files do
          files[#files + 1] = file
        end
      end
      MsgDebug(table.concat(files,"\n").."\n")
  end
  return files
end

-----------------------------------------
-- Retrieve key values from reaper.ini --
---------------------------------------------------------------------------------------------------
-- Slightly adapted version of this script from Carreras Nicolas: https://gist.github.com/bfut/3e738d9b4fc44b746f91999d933ec407
-- Reaper forum thread: https://forum.cockos.com/showthread.php?p=1937210
---------------------------------------------------------------------------------------------------
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

--------------------------
-- Invert element order --
--------------------------
local function InvertElementOrder(arr)
  local e1, e2 = 1, #arr
  while e1 < e2 do
    arr[e1], arr[e2] = arr[e2], arr[e1]
    e1 = e1 + 1
    e2 = e2 - 1
   end
end

----------------------
-- Listbox contents --
----------------------
function FillRecentProjectsListbox()
  recentProjItemsShort = {}
  recentProjItemsFull = {}
  recentProjects = {}
  
  local recentpathtag = {}
  local found = false;
  local p = 0
    
  repeat
    p = p + 1
    if p < 10 then
     recentpathtag[p] = "recent0" .. tostring(p)
    else
     recentpathtag[p] = "recent" .. tostring(p)
    end
    
    if GetReaperIniKeyValue(recentpathtag[p]) == nil then
      found = true
      break 
    else
      fullPath = GetReaperIniKeyValue(recentpathtag[p])
      if reaper.GetOS():find("OSX") then
        filename = fullPath:match "([^/]-([^.]+))$" -- macOS: get (filename.extension) substring
      else
        filename = fullPath:match "([^\\]-([^.]+))$" -- Windows: get (filename.extension) substring
      end
      recentProjItemsFull[p] = fullPath
      recentProjItemsShort[p] = string.sub(filename,1,#filename-4) -- get (filename) without .RPP 
      
      -- handling of .RPP-bak files
      if string.sub(recentProjItemsShort[p], #recentProjItemsShort[p]-3, #recentProjItemsShort[p]) == "-bak" then
        recentProjItemsShort[i] =  recentProjItemsShort[i] .. " (backup file)"
      end
      
    end
  until (found == true)

  if #recentProjItemsShort == 0 then
    noRecentProjects = true
  else
    noRecentProjects = false  
  
    -- Reverse the element order in order to place the most recent entry at the top
    InvertElementOrder(recentProjItemsShort)
    InvertElementOrder(recentProjItemsFull)
  
    for i = 1, #recentProjItemsShort do
      recentProjects[recentProjItemsShort[i]] = recentProjItemsFull[i]
      --table.insert(recentProjects, recentProjItemsShort[i])
    end
  end
end

local function FillProjectTemplateListBox()
  projectTemplateItems = {}
  projectTemplates = {}
  local projectTemplateFiles = GetFiles(projectTemplatePath)

  if #projectTemplateFiles == 0 then
    noProjectTemplates = true
  else
    noProjectTemplates = false  

    for i = 1, #projectTemplateFiles do
      if reaper.GetOS():find("OSX") then
        filename = projectTemplateFiles[i]:match "([^/]-([^.]+))$" -- macOS: (filename.extension) 
      else
        filename = projectTemplateFiles[i]:match "([^\\]-([^.]+))$" -- Windows: get (filename.extension) substring
      end
  
      projectTemplates[i] = string.sub(filename,1,#filename-4) -- get (filename) without .RPP
     
      -- handling of .RPP-bak files
      if string.sub(filename, #filename-3, #filename) == "-bak" then
        projectTemplates[i] =  string.sub(filename,1,#filename-8) .. "  (.rpp-bak file)"
      end
      
      if reaper.GetOS():find("OSX") then
        projectTemplateItems[projectTemplates[i]] = projectTemplatePath .. "/" .. filename
      else
        projectTemplateItems[projectTemplates[i]] = projectTemplateFiles[i]
      end
    --  table.insert(projectTemplateItems, projectTemplateItems[i])
    end
  end
end

local function FillTrackTemplateListBox()
  trackTemplateItems = {}
  trackTemplates = {}  
  local tracktemplateFiles = GetFiles(trackTemplatePath)

  if #tracktemplateFiles == 0 then
    noTrackTemplates = true
  else
    noTrackTemplates = false  
  
    for i = 1, #tracktemplateFiles do
      if reaper.GetOS():find("OSX") then
        filename = tracktemplateFiles[i]:match "([^/]-([^.]+))$" -- macOS: (filename.extension) 
      else
        filename = tracktemplateFiles[i]:match "([^\\]-([^.]+))$" -- Windows: get (filename.extension) substring
      end
  
      trackTemplates[i] = string.sub(filename,1,#filename-15) -- get (filename) without .RTrackTemplate
      trackTemplateItems[trackTemplates[i]] = trackTemplatePath .. "/" .. filename
      -- table.insert(trackTemplateItems, trackTemplateItems[i])
    end
  end
end

-------------------------------------
-- Fill the listboxes with entries --
-------------------------------------
FillRecentProjectsListbox()
FillTrackTemplateListBox()
FillProjectTemplateListBox()

-----------------------------
-- New project/tab buttons --
-----------------------------
local function BTN_New_Project()
  reaper.Main_OnCommand(40023, 0)
  if GUI.Val("pin") == false then gfx.quit() end
end

local function BTN_New_ProjectTab()
  reaper.Main_OnCommand(40859, 0)
  if GUI.Val("pin") == false then gfx.quit() end
end

local function BTN_New_Project_IgnoreTemplate()
  reaper.Main_OnCommand(41929, 0)
  if GUI.Val("pin") == false then gfx.quit() end
end

-----------------------------
--  Recent project buttons --
-----------------------------
local function BTN_RecentProject_Load()
  if (noRecentProjects == false) then
    local selected = GUI.Val("lst_recentProjects")
    if type(selected) == "number" then selected = {[selected] = true} end
  
    local vals = {}
    for k, v in pairs(selected) do
      table.insert(vals, k)
    end
  
    for p = 1, #vals do
    
      if RecentProjectFilterActive == true then
        selectedProject = recentProjects[filteredRecentProjects[vals[p]]]
      else
        selectedProject = recentProjects[recentProjItemsShort[vals[p]]]
      end
  
      -- if more than 1 project is selected, load the other projects in a tab
      if p > 1 then
        reaper.Main_OnCommand(40859, 0)
        reaper.Main_openProject(selectedProject) 
      else
         reaper.Main_openProject(selectedProject) 
      end
    end
      
    GUI.Val("lst_recentProjects",{})
    if GUI.Val("pin") == false then gfx.quit() end
  end
end


local function BTN_RecentProject_LoadInTab()
  if (noRecentProjects == false) then
    local selected = GUI.Val("lst_recentProjects")
    if type(selected) == "number" then selected = {[selected] = true} end

    local vals = {}
    for k, v in pairs(selected) do
      table.insert(vals, k)
    end

    for p = 1, #vals do
    if RecentProjectFilterActive == true then
      selectedProject = recentProjects[filteredRecentProjects[vals[p]]]
    else
      selectedProject = recentProjects[recentProjItemsShort[vals[p]]]
    end
      reaper.Main_OnCommand(40859, 0)
      reaper.Main_openProject(selectedProject) 
    end
  
    GUI.Val("lst_recentProjects",{})
    if GUI.Val("pin") == false then gfx.quit() end
  end
end

------------------------------
-- Project Template buttons --
------------------------------
local function BTN_ProjectTemplate_Load()
  if (noProjectTemplates == false) then
    local selected = GUI.Val("lst_projectTemplates")
    if type(selected) == "number" then selected = {[selected] = true} end
  
    local vals = {}
      for k, v in pairs(selected) do
      table.insert(vals, k)
    end
   
    for p = 1, #vals do 
      if ProjectTemplateFilterActive == true then
       selectedProjectTemplate = projectTemplateItems[filteredProjectTemplates[vals[p]]]
      else
        selectedProjectTemplate = projectTemplateItems[projectTemplates[vals[p]]]
      end
     
      if p > 1 then
        reaper.Main_OnCommand(40859, 0)
        reaper.Main_openProject(selectedProjectTemplate) 
      else
        reaper.Main_openProject(selectedProjectTemplate) 
     end
  end  

    if GUI.Val("pin") == false then gfx.quit() end
  end
end


local function BTN_ProjectTemplate_LoadInTab()
  if (noProjectTemplates == false) then
    local selected = GUI.Val("lst_projectTemplates")
    if type(selected) == "number" then selected = {[selected] = true} end
  
    local vals = {}
      for k, v in pairs(selected) do
      table.insert(vals, k)
    end
   
    for p = 1, #vals do 
      if ProjectTemplateFilterActive == true then
        selectedProjectTemplate = projectTemplateItems[filteredProjectTemplates[vals[p]]]
      else
       selectedProjectTemplate = projectTemplateItems[projectTemplates[vals[p]]]
    end

    reaper.Main_OnCommand(40859, 0)
    reaper.Main_openProject(selectedProjectTemplate) 
  end  

    if GUI.Val("pin") == false then gfx.quit() end
  end
end

----------------------------
-- Track Template buttons --
----------------------------
local function BTN_TrackTemplate_Load()
  if (noTrackTemplates == false) then
    local selected = GUI.Val("lst_trackTemplates")
    if type(selected) == "number" then selected = {[selected] = true} end

    local vals = {}
     for k, v in pairs(selected) do
       table.insert(vals, k)
     end
   
    for p = 1, #vals do
      if TrackTemplateFilterActive == true then
        selectedTrackTemplate = trackTemplateItems[filteredTrackTemplates[vals[p]]]
      else
       selectedTrackTemplate = trackTemplateItems[trackTemplates[vals[p]]]
    end
      reaper.Main_openProject(selectedTrackTemplate) 
   end 
  
   if GUI.Val("pin") == false then gfx.quit() end
  end
end  
  
----------------------
-- Make a duplicate --
----------------------
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

local function UpdateSortMode()
  local sortMode = GUI.Val("menu_sort")
  if sortMode == 1 then
    Sort_MostRecent()
  elseif sortMode == 2 then
    Sort_Alphabetically_Ascending()     
  else
    Sort_Alphabetically_Descending()
  end
end

----------------------
-- Filter functions --
----------------------
local function FilterNoCase(s)
    s = string.gsub(s, "%a", function (c)
          return "[" .. string.lower(c) .. string.upper(c) .. "]"
        end)
    return s
end

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

-----------------------------
-- Filter Remove functions --
-----------------------------
local function BTN_Filter_RecentProject_Remove()
  RecentProjectFilterActive = false
  GUI.Val("lst_recentProjects",{})
--  UpdateListFilter_RecentProjects()
end 

local function BTN_Filter_ProjectTemplate_Remove()
  ProjectTemplateFilterActive = false
  GUI.Val("lst_projectTemplates",{})
--  UpdateListFilter_ProjectTemplates()
end 

local function BTN_Filter_TrackTemplate_Remove()
  TrackTemplateFilterActive = false
  GUI.Val("lst_trackTemplates",{})
--  UpdateListFilter_TrackTemplates()
end 

----------------------------
-- Filter Apply functions --
----------------------------
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
end

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
end

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
end

-------------------------------------------------------------
-- Overwrites the Listbox.lua core function 
-- For adjusting the selection rectangle position under macOS
-------------------------------------------------------------
function GUI.Listbox:drawselection()
  local off_x, off_y = self.x + self.pad, self.y + self.pad
  local x, y, w, h
  w = self.w - 2 * self.pad
  
  GUI.color("elm_fill")
  gfx.a = 0.5
  gfx.mode = 1

  for i = 1, #self.list do
    if self.retval[i] and i >= self.wnd_y and i < self:wnd_bottom() then
      if reaper.GetOS():find("OSX") then
      -- macOS  
        y = off_y + (i * 1.4) + ( (i - self.wnd_y) * self.char_h)
      else
      -- Windows
        y = off_y + (i - self.wnd_y) * self.char_h
      end
      gfx.rect(off_x, y, w, self.char_h, true)
    end
  end  
  gfx.mode = 0
  gfx.a = 1
end

-- Copied from Lokasenna's Theory Helper
--[[if reaper.GetOS():find("OSX") then
  GUI.font = function (fnt)
  local font, size, str = table.unpack( type(fnt) == "table" and fnt or GUI.fonts[fnt])

  if reaper.GetOS():find("OSX") then
    size = math.floor(size * 0.8)
  end
  
  local flags = 0  
  if str then
    for i = 1, str:len() do 
      flags = flags * 256 + string.byte(str, i) 
    end   
  end
    gfx.setfont(1, font, size, flags)
  end
end
]]--

---------------------
-- Window settings --
---------------------
GUI.name = "ReaLauncher"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 620, 600
GUI.anchor, GUI.corner = "mouse", "C" -- Center on "mouse" or "screen"
GUI.load_window_state(appname)

btn_w = 120
btn_h = 28

pad_top = 30
listbox_w = GUI.w - 160
listbox_h = GUI.h - 60

btn_pad_left = listbox_w + 25
btn_pad_top = 160
btn_pad_add = 35
btn_tab_top = 320

-----------------------
-- Main GUI Elements --
-----------------------
GUI.New("tabs", "Tabs", 1, 0, 0, 100, 20, "Recent Projects, Project Templates, Track Templates", 16)
GUI.New("pin", "Checklist", 1, GUI.w - 40, pad_top, 20, 20, "", "", "h", 0)
GUI.New("btn_newProjectTab", "Button", 1, btn_pad_left, btn_pad_top, btn_w, btn_h, "New Tab", BTN_New_ProjectTab) 
GUI.New("btn_loadIgnoreTemplate", "Button", 1, btn_pad_left, btn_pad_top + btn_pad_add, btn_w, btn_h, "Ignore Template", BTN_New_Project_IgnoreTemplate)
GUI.New("btn_newProject", "Button", 1, btn_pad_left, btn_pad_top + (3 * btn_pad_add), btn_w, btn_h, "New Project", BTN_New_Project) 

--  Tab | Layers
GUI.elms.tabs:update_sets(
  { [1] = {3},
    [2] = {4},
    [3] = {5},
    [4] = {6}
  }
)

--------------------------------------
-- Tab 1 Elements - Recent Projects --
--------------------------------------
GUI.New("tb_filterRecentProjects", "Textbox", 3, 80, pad_top, 260, 20, "Filter:", 8)
GUI.New("btn_filterRecentProjectsRemove", "Button", 3, 10, pad_top - 2, 20,  22, "X", BTN_Filter_RecentProject_Remove)
GUI.New("menu_sort", "Menubox", 3, 375, 30, 95, 20, "Sort:", "Most Recent,Ascending,Descending")
GUI.New("lst_recentProjects", "Listbox", 3, 10, 56, listbox_w, listbox_h,"", true)

GUI.New("btn_loadRecentProjectInTab", "Button", 3, btn_pad_left, btn_tab_top, btn_w,  btn_h, "Load in Tab", BTN_RecentProject_LoadInTab)
GUI.New("btn_loadRecentProject", "Button", 3, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", BTN_RecentProject_Load)
GUI.elms.lst_recentProjects.list = recentProjItemsShort

function GUI.elms.lst_recentProjects:ondoubleclick()
  BTN_RecentProject_Load()
end

function GUI.elms.tb_filterRecentProjects:ontype()
   GUI.Textbox.ontype(self)
   Filter_RecentProject_Apply()
end

function GUI.elms.menu_sort:onmousedown()
  if (noRecentProjects == false) then
    GUI.Menubox.onmouseup(self)
    UpdateSortMode()
  end
end

----------------------------------------
-- Tab 2 Elements - Project Templates --
----------------------------------------
GUI.New("tb_filterProjectTemplates", "Textbox", 4, 80, pad_top, 260, 20, "Filter:", 8)
GUI.New("btn_filterProjectTemplatesRemove", "Button", 4, 10, pad_top-2, 20,  22,"X", BTN_Filter_ProjectTemplate_Remove)
GUI.New("lst_projectTemplates", "Listbox", 4, 10, 56, listbox_w, listbox_h, "", true)
GUI.New("btn_loadProjectTemplateInTab", "Button", 4, btn_pad_left, btn_tab_top, btn_w, btn_h, "Load in Tab", BTN_ProjectTemplate_LoadInTab)
GUI.New("btn_loadProjectTemplate", "Button", 4, btn_pad_left, btn_tab_top + btn_pad_add, btn_w, btn_h, "Load", BTN_ProjectTemplate_Load)
GUI.elms.lst_projectTemplates.list = projectTemplates

function GUI.elms.lst_projectTemplates:ondoubleclick()
  BTN_ProjectTemplate_Load()
end

function GUI.elms.tb_filterProjectTemplates:ontype()
   GUI.Textbox.ontype(self)
   Filter_ProjectTemplate_Apply()
end

--------------------------------------
-- Tab 3 Elements - Track Templates --
--------------------------------------

GUI.New("tb_filterTrackTemplates", "Textbox", 5, 80, pad_top, 260, 20, "Filter:", 8)
GUI.New("btn_filterTrackTemplatesRemove", "Button", 5, 10, pad_top-2, 20, 22, "X", BTN_Filter_TrackTemplate_Remove)
GUI.New("lst_trackTemplates", "Listbox", 5, 10, 56, listbox_w, listbox_h, "", true)

GUI.New("btn_loadTrackTemplate", "Button", 5, btn_pad_left, btn_tab_top, btn_w, btn_h, "Insert", BTN_TrackTemplate_Load)
GUI.elms.lst_trackTemplates.list = trackTemplates

function GUI.elms.lst_trackTemplates:ondoubleclick()
  BTN_TrackTemplate_Load()
end

function GUI.elms.tb_filterTrackTemplates:ontype()
   GUI.Textbox.ontype(self)
   Filter_TrackTemplate_Apply()
end

local function Load_ExtSettings()

local pin = reaper.GetExtState(appname,"window_pin")
  GUI.Val("pin", {(pin == "true" and true or false)})
  GUI.Val("tabs", tonumber(reaper.GetExtState(appname, "last_tab")))
end

local function Save_ExtSettings()
  GUI.save_window_state(appname)
  reaper.SetExtState(appname, "window_pin", tostring(GUI.Val("pin")),1)
  reaper.SetExtState(appname, "last_tab", GUI.Val("tabs"), 1) 
end

--------------------
-- Main functions --
--------------------
RecentProjectFilterActive = false
TrackTemplateFilterActive = false
ProjectTemplateFilterActive = false

GUI.Init() 
Load_ExtSettings()

GUI.func = Main
GUI.freq = 0

reaper.atexit(function ()
  Save_ExtSettings()
end)

GUI.Main()

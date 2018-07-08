-- @description ReaLauncher
-- @author solger
-- @version 0.1.1
-- @changelog
--   + changed filter and sort function structure - should now be more CPU friendly
--   + last window position is now stored
-- @screenshot https://forum.cockos.com/attachment.php?attachmentid=34088&stc=1&d=1530957174
-- @about
--   # ReaLauncher 
--
--   A custom version of the startup prompt window for loading (recent) projects and project/track templates
--
--   ## Screenshot
--
--   https://forum.cockos.com/attachment.php?attachmentid=34088&stc=1&d=1530957174
--
--   ## Main features
--
--   - Separate Tabs for Recent Projects, Project Templates and Track Templates
--   - Simple (case-sensitive) pattern-matching filter textboxes at the top of each Tab
--   - Global buttons for 'New Tab' and 'New Project'
--   - [Recent Projects]-Tab: In addition to the default list order, it's also possible to sort the list alphabetically (ascending/descending)
--   - Selection and loading of multiple entries (multi-selection is already part of Lokasenna's GUI library for LUA)
--   - 'Window-pin' checkbox at the top right: when enabled (= default setting) the window is kept open after using any of the [New], [Load] or [Insert] buttons
--
--   ## Discussion thread
--
--   https://forum.cockos.com/showthread.php?t=208697

------------------------------------------------------------------------------------------------------
-- Uses Lokasenna's GUI library v2 (for LUA) as base: https://forum.cockos.com/showthread.php?t=177772
-- Big thanks to Lokasenna for his work!!
------------------------------------------------------------------------------------------------------
local debug_enabled = false; -- Set to 'true' in order to show debug messages in the console

---------------------------------------------------------------------------------------------
-- Lokasenna's GUI library v2
-- Lokasenna: 'The Core library must be loaded prior to any classes, or the classes will throw up errors
-- when they look for functions that aren't there.'
---------------------------------------------------------------------------------------------
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

if reaper.GetOS():find("OSX") then
  -- macOS paths
  trackTemplatePath = resourcePath .. "/TrackTemplates"
  projectTemplatePath = resourcePath .. "/ProjectTemplates"
else
  -- Windows paths
  trackTemplatePath = resourcePath .. "\\TrackTemplates"
  projectTemplatePath = resourcePath .. "\\ProjectTemplates"
end

------------------------------------------------------------------------------------
-- Returns a table of files in the specified path
-- Adapted script from this thread: https://forum.cockos.com/showthread.php?t=206933
------------------------------------------------------------------------------------
local function GetFiles(path)
  local files = {}

  if reaper.GetOS():find("OSX") then
    -- macOS paths
    for file in io.popen([[find ]] .. path .. [[ -maxdepth 1 -type f -not -name '.*']]):lines() do
      files[#files + 1] = file
      if debug_enabled then reaper.ShowConsoleMsg(table.concat(files,"\n").."\n\n\n") end
    end
    else
    -- Windows paths
    for file in io.popen([[dir "]] .. path .. [[" /a:-d /s /b | sort]]):lines() do
      files[#files + 1] = file
      if debug_enabled then reaper.ShowConsoleMsg(table.concat(files,"\n").."\n\n\n") end
    end
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
 function InvertElementOrder(arr)
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
  
  -- Reverse the element order in order to place the most recent entry at the top
  InvertElementOrder(recentProjItemsShort)
  InvertElementOrder(recentProjItemsFull)
  
  for i = 1, #recentProjItemsShort do
    recentProjects[recentProjItemsShort[i]] = recentProjItemsFull[i]
    --table.insert(recentProjects, recentProjItemsShort[i])
  end
end

local function FillProjectTemplateListBox()
  projectTemplateItems = {}
  projectTemplates = {}
  local projectTemplateFiles = GetFiles(projectTemplatePath)

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

local function FillTrackTemplateListBox()
  trackTemplateItems = {}
  trackTemplates = {}  
  local tracktemplateFiles = GetFiles(trackTemplatePath)

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
  if window_pin == false then gfx.quit() end
end

local function BTN_New_ProjectTab()
  reaper.Main_OnCommand(40859, 0)
  if window_pin == false then gfx.quit() end
end

-----------------------------
--  Recent project buttons --
-----------------------------
local function BTN_RecentProject_Load()
  local selected = GUI.Val("lst_recentProjects")
  if type(selected) == "number" then selected = {[selected] = true} end

  local vals = {}
  for k, v in pairs(selected) do
    table.insert(vals, k)
  end

  if debug_enabled then
    for p = 1, #vals do
      reaper.ShowConsoleMsg("vals: '" .. vals[p] .. "'\n")
    end
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
  if window_pin == false then gfx.quit() end
end


local function BTN_RecentProject_LoadInTab()
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
  if window_pin == false then gfx.quit() end
end

------------------------------
-- Project Template buttons --
------------------------------
local function BTN_ProjectTemplate_Load()
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
    
--    GUI.Val("lst_projectTemplates",{})
    if window_pin == false then gfx.quit() end
end


local function BTN_ProjectTemplate_LoadInTab()
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

--    GUI.Val("lst_projectTemplates",{})
    if window_pin == false then gfx.quit() end
end

----------------------------
-- Track Template buttons --
----------------------------
local function BTN_TrackTemplate_Load()
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
  
--   GUI.Val("lst_trackTemplates",{})
   if window_pin == false then gfx.quit() end
end  
  
--------------------
-- Sort functions --
--------------------
local function SortAsc()
    table.sort(recentProjItemsShort, function(a, b) return a:lower() < b:lower() end)
    GUI.elms.lst_recentProjects.list = recentProjItemsShort
end

local function SortDef()
    FillRecentProjectsListbox()
    GUI.elms.lst_recentProjects.list = recentProjItemsShort
end

local function SortDesc()
    table.sort(recentProjItemsShort, function(a, b) return b:lower() < a:lower() end)
    GUI.elms.lst_recentProjects.list = recentProjItemsShort
end

local function UpdateSortMode()
 -- Listbox sort mode: Default (most recent project at the top) / Ascending / Descending
    local sortMode = GUI.Val("menu_sort")
    if sortMode == 1 then
      SortDef()
    elseif sortMode == 2 then
      SortAsc()     
    else
      SortDesc()
    end
end

----------------------
-- Filter functions --
----------------------
local function UpdateListFilter_RecentProjects()
  -- Recent Projects tab
  if RecentProjectFilterActive then
    GUI.elms.lst_recentProjects.list = filteredRecentProjects
  else
   UpdateSortMode()
  end
end

local function UpdateListFilter_ProjectTemplates()
 -- Project Templates tab
  if ProjectTemplateFilterActive then
    GUI.elms.lst_projectTemplates.list = filteredProjectTemplates
  else
    GUI.elms.lst_projectTemplates.list = projectTemplates 
  end
end

local function UpdateListFilter_TrackTemplates()
  -- Track Templates tab
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
  FillRecentProjectsListbox()
  RecentProjectFilterActive = false
  UpdateListFilter_RecentProjects()
  GUI.Val("lst_recentProjects",{})
end 

local function BTN_Filter_ProjectTemplate_Remove()
  ProjectTemplateFilterActive = false
  UpdateListFilter_ProjectTemplates()
--  FillProjectTemplateListBox()
  GUI.Val("lst_projectTemplates",{})
end 

local function BTN_Filter_TrackTemplate_Remove()
  TrackTemplateFilterActive = false
  UpdateListFilter_TrackTemplates()
 -- FillTrackTemplateListBox()
  GUI.Val("lst_trackTemplates",{})
end 

----------------------------
-- Filter Apply functions --
----------------------------
local function BTN_Filter_RecentProject_Apply()
  local searchStr = GUI.Val("tb_filterRecentProjects")
  filteredRecentProjects = {}

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

local function BTN_Filter_ProjectTemplate_Apply()
  local searchStr = GUI.Val("tb_filterProjectTemplates")
  filteredProjectTemplates = {}

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

local function BTN_Filter_TrackTemplate_Apply()
  local searchStr = GUI.Val("tb_filterTrackTemplates")
  filteredTrackTemplates = {}

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
---------------------
-- Window settings --
---------------------
GUI.name = "ReaLauncher"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 600, 500
GUI.anchor, GUI.corner = "mouse", "C" -- Center on "mouse" or "screen"
GUI.load_window_state("solger_ReaLauncher.lua")

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

----------------------------------------
-- Copied from Lokasenna's Theory Helper
----------------------------------------
if reaper.GetOS():find("OSX") then
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

-----------------------
-- Main GUI Elements --
-----------------------
GUI.New("tabs", "Tabs", 1, 0, 0, 100, 20, "Recent Projects, Project Templates, Track Templates", 16)
GUI.New("cklist_wnd", "Checklist", 1, 560, 30, 20, 20, "", "", "h", 0)
GUI.New("btn_newProjectTab", "Button", 1, 485, 150, 100,  28, "New Tab", BTN_New_ProjectTab) 
GUI.New("btn_newProject", "Button", 1, 485, 185, 100,  28, "New Project", BTN_New_Project) 

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
GUI.New("tb_filterRecentProjects", "Textbox", 3, 50, 30, 310, 20, "Filter:", 8)
GUI.New("btn_filterRecentProjects", "Button", 3, 370, 28, 40,  24, "Apply", BTN_Filter_RecentProject_Apply)
GUI.New("btn_filterRecentProjectsRemove", "Button", 3, 420, 28, 20,  24, "X", BTN_Filter_RecentProject_Remove)
GUI.New("menu_sort", "Menubox", 3, 40, 465, 95, 20, "Sort:", "Most Recent,Ascending,Descending")
GUI.New("lst_recentProjects", "Listbox", 3, 10, 56, 460, 400,"", true)

GUI.New("btn_loadRecentProjectInTab", "Button", 3, 485, 250, 100,  28, "Load in Tab", BTN_RecentProject_LoadInTab)
GUI.New("btn_loadRecentProject", "Button", 3, 485, 285, 100, 28, "Load", BTN_RecentProject_Load)
GUI.elms.lst_recentProjects.list = recentProjItemsShort

function GUI.elms.lst_recentProjects:ondoubleclick()
  BTN_RecentProject_Load()
end

function GUI.elms.menu_sort:onmousedown()
  GUI.Menubox.onmouseup(self)
  UpdateSortMode()
end

----------------------------------------
-- Tab 2 Elements - Project Templates --
----------------------------------------
GUI.New("tb_filterProjectTemplates", "Textbox", 4, 50, 30, 310, 20, "Filter:", 8)
GUI.New("btn_filterProjectTemplates", "Button", 4, 370, 28, 40,  24, "Apply", BTN_Filter_ProjectTemplate_Apply)
GUI.New("btn_filterProjectTemplatesRemove", "Button", 4, 420, 28, 20,  24, "X",BTN_Filter_ProjectTemplate_Remove)
GUI.New("lst_projectTemplates", "Listbox", 4, 10, 56, 460, 400, "", true)
GUI.New("btn_loadProjectTemplateInTab", "Button", 4, 485, 250, 100,  28, "Load in Tab", BTN_ProjectTemplate_LoadInTab)
GUI.New("btn_loadProjectTemplate", "Button", 4, 485, 285, 100,  28, "Load", BTN_ProjectTemplate_Load)
GUI.elms.lst_projectTemplates.list = projectTemplates

function GUI.elms.lst_projectTemplates:ondoubleclick()
  BTN_ProjectTemplate_Load()
end
--------------------------------------
-- Tab 3 Elements - Track Templates --
--------------------------------------

GUI.New("tb_filterTrackTemplates", "Textbox", 5, 50, 30, 310, 20, "Filter:", 8)
GUI.New("btn_filterTrackTemplates", "Button", 5, 370, 28, 40,  24, "Apply",BTN_Filter_TrackTemplate_Apply )
GUI.New("btn_filterTrackTemplatesRemove", "Button", 5, 420, 28, 20,  24, "X", BTN_Filter_TrackTemplate_Remove)

GUI.New("lst_trackTemplates", "Listbox", 5, 10, 56, 460, 400, "", true)
GUI.New("btn_loadTrackTemplate", "Button", 5, 485, 250, 100,  28, "Insert", BTN_TrackTemplate_Load)
GUI.elms.lst_trackTemplates.list = trackTemplates

function GUI.elms.lst_trackTemplates:ondoubleclick()
  BTN_TrackTemplate_Load()
end

--------------------
-- Main functions --
--------------------
RecentProjectFilterActive = false
TrackTemplateFilterActive = false
ProjectTemplateFilterActive = false

GUI.onresize = function()
  -- check and force the resize
  local __,x,y,w,h = gfx.dock(-1,0,0,0,0)
  gfx.quit()
  gfx.init(GUI.name, GUI.w, GUI.h, 0, x, y)
  GUI.redraw_z[0] = true
end


local function Main()
  window_pin = GUI.Val("cklist_wnd") -- Get the current window pin state  
  GUI.save_window_state("solger_ReaLauncher.lua")
end

GUI.Val("cklist_wnd",{1}) -- keep the window pinned by default when showing the window
GUI.Init() 

-- Tell the GUI library to run Main on each update loop
-- Individual elements are updated first, then GUI.func is run, then the GUI is redrawn
GUI.func = Main
GUI.freq = 0 -- How often (in seconds) to run GUI.func. 0 = every loop.
GUI.Main()

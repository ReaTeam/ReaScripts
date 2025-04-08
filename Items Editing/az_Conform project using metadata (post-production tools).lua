-- @description Conform project using metadata (post-production tools)
-- @author AZ
-- @version 0.4
-- @link Forum thread https://forum.cockos.com/showthread.php?t=288069
-- @donation Donate via PayPal https://www.paypal.me/AZsound
-- @about
--   # Conform project using metadata
--
--   This script has various features for comfortable work when you get a project from video editor
--
--   - Link source files
--   - Expand channels from field recorder poly-wave files
--   - and more in the feature

function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end

ExtStateName = 'ConformTools_AZ'

--------------------------
function rgbToHex(rgba) -- passing a table with percentage like {100, 50, 20, 90}
  local hexadecimal = '0X'

  for key, value in pairs(rgba) do
    local hex = ''
    if value > 100 or value < 0 then return error('Color must be a percantage value\n between 0 and 100') end
    value = (255/100)*value
    while(value > 0)do
      local index = math.floor(math.fmod(value, 16) + 1)
      value = math.floor(value / 16)
      hex = string.sub('0123456789ABCDEF', index, index) .. hex
    end

    if(string.len(hex) == 0)then
      hex = '00'

    elseif(string.len(hex) == 1)then
      hex = '0' .. hex
    end

    hexadecimal = hexadecimal .. hex
  end

  return hexadecimal
end
------------------------

function addFileNamesToList(list, string )
  for s in string:gmatch("[^\0]+") do table.insert(list, s) end
  if #list > 1 and reaper.GetOS():match("^Win") ~= nil then
    local path = list[1]
    for i= 2, #list do
      list[i] = path..list[i]
    end
    table.remove(list, 1)
    parselistOnce = true
  end
end
-----------------------
function SplitFilename(strFilename)
  -- Returns the Path, Filename, and Extension as 3 values
  return string.match(strFilename, "(.-)([^\\]-([^\\%.]+))$")
end

------------------------

function ValToBool(val)
  if type(val) == 'boolean' or val == nil then return val end
  if type(val) == 'number' and val > 0 then return true end
  if type(val) == 'string' and val ~= ''  and val == 'true' then return true end
  if val == '' then return nil end
  return false
end
------------------------

function MainWindow(OptTable, windowName)
   
  local imgui_path = reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua'
  if not reaper.file_exists(imgui_path) then
    reaper.ShowMessageBox('Please, install ReaImGui from Reapack!', 'No Imgui library', 0)
    return
  end
  dofile(imgui_path) '0.9.3'

  local fontSize = 17
  local ctx, font, fontSep
  local H = fontSize
  local W = fontSize
  local loopcnt = 0
  local esc
  local EDL
  
  local SelItems, TrackList = {}, {}
  
  EDLcontentFlags = reaper.GetExtState(ExtStateName, 'ContentAnalyse')
  
  if EDLcontentFlags ~= "" then
    EDLcontentFlags = tonumber(EDLcontentFlags)
  else EDLcontentFlags = 31
  end
  
  ExpandNoNamedCh = ValToBool( reaper.GetExtState(ExtStateName, 'ExpNoName') )
  if ExpandNoNamedCh == nil then ExpandNoNamedCh = true end
  
  _, TrimLeadingTime = ValToBool( reaper.GetProjExtState(0, ExtStateName, 'TrimLeadingTime') )
  _, TrimOnlyEmptyTime = ValToBool( reaper.GetProjExtState(0,ExtStateName, 'TrimOnlyEmptyTime') )
  _, TrimTime = reaper.GetProjExtState(0, ExtStateName, 'TrimTime')
  
  if TrimLeadingTime == nil then TrimLeadingTime = true end
  if TrimOnlyEmptyTime == nil then TrimOnlyEmptyTime = true end
  
  if TrimTime == '' then TrimTime = '01:00:00:00' end
  
  
  local savedFontSize = tonumber(reaper.GetExtState(ExtStateName, 'FontSize'))
  if type(savedFontSize) == 'number' then fontSize = savedFontSize end
  if not savedFontSize then savedFontSize = fontSize end
  
  
  
  local gui_colors = {
    White = rgbToHex({90,90,90,100}),
    Green = rgbToHex({52,85,52,100}),
    Red = rgbToHex({90,10,10,100}),
    Blue = rgbToHex({30,60,80,100}),
    TitleBg = rgbToHex({30,20,30,100}), 
    Background = rgbToHex({11,14,14,95}),
    Text = rgbToHex({92,92,81.5,100}),
    activeText = rgbToHex({50,95,80,100}),
    ComboBox = {
      Default = rgbToHex({20,25,30,100}),
      Hovered = rgbToHex({35,40,45,80}),
      Active = rgbToHex({42,42,37,100}), 
    },
    Button = {
      Default = rgbToHex({25,30,30,100}),
      Hovered = rgbToHex({35,40,45,100}),
      Active = rgbToHex({42,42,37,100}),
    },
    MainButton = {
      Default = rgbToHex({25,50,40,80}),
      Hovered = rgbToHex({35,60,55,80}),
      Active = rgbToHex({56,56,42,90}),
    }
  }
  ------
  
  local fontName
  ctx = reaper.ImGui_CreateContext(windowName)
  if reaper.GetOS():match("^Win") == nil then
    reaper.ImGui_SetConfigVar(ctx, reaper.ImGui_ConfigVar_ViewportsNoDecoration(), 0)
    fontName = 'sans-serif'
  else
    fontName = 'Calibri'
  end
  
  
  -------------- 
  function frame()
    MIN_luft_ZERO = reaper.parse_timestr_pos('00:00:00:01', 5) / 4
    reaper.ImGui_PushFont(ctx, font)
    
    --About button
    reaper.ImGui_SameLine(ctx, fontSize*25, nil)
    if reaper.ImGui_Button(ctx, 'About - forum page', nil, nil) then
      local doc = ''
      if reaper.CF_ShellExecute then
        reaper.CF_ShellExecute(doc)
      else
        reaper.MB(doc, '?forum page', 0)
      end
    end
    
    if reaper.ImGui_CollapsingHeader(ctx, 'Match files with selected items using metadata', false) then
      
      if reaper.ImGui_Button(ctx, ' Folder to search ') then --msg(iniFolder)
        if not iniFolder then
          local cur_retprj, cur_projfn = reaper.EnumProjects( -1 )
          local path, projfn, extension = SplitFilename(cur_projfn)
          if path then iniFolder = path:gsub('[/\\]$','') end 
        end 
        local ret
        ret, iniFolder = reaper.JS_Dialog_BrowseForFolder( 'Choose folder for search', iniFolder )
        SearchFolder = iniFolder
      end
      
      if SearchFolder and SearchFolder ~= '' then
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.Green)
        reaper.ImGui_Text(ctx, SearchFolder)
        reaper.ImGui_PopStyleColor(ctx,1)
      end
      
      reaper.ImGui_Text(ctx, 'The feature is under development, for a while you can use')
      reaper.ImGui_SameLine(ctx)
      if reaper.ImGui_Button(ctx, 'this', nil, nil) then
        local doc = 'https://forum.cockos.com/showpost.php?p=2827459&postcount=21'
        if reaper.CF_ShellExecute then
          reaper.CF_ShellExecute(doc)
        else
          reaper.MB(doc, '?forum page', 0)
        end
      end
    end
    
    if reaper.ImGui_CollapsingHeader(ctx, 'Create tracks using EDL files', false) then
      
      if reaper.ImGui_Button(ctx, ' Folder to search '..'##2') then --msg(iniFolder)
        if not iniFolder then
          local cur_retprj, cur_projfn = reaper.EnumProjects( -1 )
          local path, projfn, extension = SplitFilename(cur_projfn)
          if path then iniFolder = path:gsub('[/\\]$','') end 
        end 
        local ret
        ret, iniFolder = reaper.JS_Dialog_BrowseForFolder( 'Choose folder for search', iniFolder ) 
        SearchFolder = iniFolder
      end
       
      if SearchFolder and SearchFolder ~= '' then
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.Green)
        reaper.ImGui_Text(ctx, SearchFolder)
        reaper.ImGui_PopStyleColor(ctx,1)
      end

      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_PushFont(ctx, fontSep)
      reaper.ImGui_Text(ctx, 'Note: the project have to be set to the known framerate')
      reaper.ImGui_PopFont(ctx)
      
      if reaper.ImGui_Button(ctx, ' EDL files ') then --msg(iniFolder)
        if not iniFolder then
          local cur_retprj, cur_projfn = reaper.EnumProjects( -1 )
          local path, projfn, extension = SplitFilename(cur_projfn)
          if path then iniFolder = path:gsub('[/\\]$','') end
        end 
        local iniFile = ''
        local extensionList = "EDL file\0*.edl\0Text file\0*.txt\0\0"
        local allowMultiple = true
        local ret, fileNames = reaper.JS_Dialog_BrowseForOpenFiles
        ( 'Choose EDL files', iniFolder, iniFile, extensionList, allowMultiple )
        
        if fileNames ~= '' then
          EDL = {}
          addFileNamesToList(EDL, fileNames) 
        end
      end
      
      showEDLsNames(EDL)
      reaper.ImGui_NewLine(ctx)
      
      --Source tracks
      local choiceSrc
      local change
      reaper.ImGui_Text(ctx, 'Import:')
      
      change, choiceSrc = reaper.ImGui_Checkbox(ctx, 'Video track', EDLcontentFlags & 1)
      if change then EDLcontentFlags = EDLcontentFlags ~1 end
      
      reaper.ImGui_SameLine(ctx)
      change, choiceSrc = reaper.ImGui_Checkbox(ctx, 'Audio 1', (EDLcontentFlags>>1) & 1)
      if change then EDLcontentFlags = EDLcontentFlags  ~ (1<<1) end
      
      reaper.ImGui_SameLine(ctx)
      change, choiceSrc = reaper.ImGui_Checkbox(ctx, 'Audio 2', (EDLcontentFlags>>2) & 1)
      if change then EDLcontentFlags = EDLcontentFlags  ~ (1<<2) end
      
      reaper.ImGui_SameLine(ctx)
      change, choiceSrc = reaper.ImGui_Checkbox(ctx, 'Audio 3', (EDLcontentFlags>>3) & 1)
      if change then EDLcontentFlags = EDLcontentFlags  ~ (1<<3) end
      
      reaper.ImGui_SameLine(ctx)
      change, choiceSrc = reaper.ImGui_Checkbox(ctx, 'Audio 4', (EDLcontentFlags>>4) & 1)
      if change then EDLcontentFlags = EDLcontentFlags  ~ (1<<4) end
      
      reaper.SetExtState(ExtStateName, 'ContentAnalyse', EDLcontentFlags, true)
      
      
      reaper.ImGui_NewLine(ctx)
      
      local ret
      ret, TrimLeadingTime = reaper.ImGui_Checkbox(ctx,'Ignore leading time in EDLs',TrimLeadingTime)
      if ret == true then reaper.SetProjExtState(0,ExtStateName,'TrimLeadingTime', tostring(TrimLeadingTime), true) end 
       
      reaper.ImGui_PushItemWidth(ctx, fontSize*5.5 )
      ret, TrimTime = reaper.ImGui_InputText(ctx, '##1', TrimTime, nil, nil)
      if ret == true then reaper.SetProjExtState(0, ExtStateName,'TrimOldTime', TrimTime, true) end
      reaper.ImGui_SameLine(ctx, nil, fontSize)
      ret, TrimOnlyEmptyTime = reaper.ImGui_Checkbox(ctx,'Only empty time if multiplied##1',TrimOnlyEmptyTime)
      if ret == true then reaper.SetProjExtState(0,ExtStateName,'TrimOnlyEmptyTime', tostring(TrimOnlyEmptyTime), true) end
      
      reaper.ImGui_NewLine(ctx)
      
      if EDL then
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.MainButton.Default)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), gui_colors.MainButton.Hovered)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), gui_colors.MainButton.Active)
      end
      if reaper.ImGui_Button(ctx, 'Create tracks and items') then
         
        if EDL then
          local timeTreshold = 0
      
          if TrimLeadingTime == true and TrimOnlyEmptyTime == false then
            timeTreshold = reaper.parse_timestr_pos( TrimTime, 5 ) - PrjTimeOffset
          end 

          local EdlsTable = AnalyseEDLs(EDL, timeTreshold)
          
          if #EdlsTable.V == 0 and #EdlsTable.A == 0 then
            reaper.ShowMessageBox('There is no valid data in EDL files', 'Warning!',0) 
          else
            CreateTracks(EdlsTable)
          end
           
        end
      end
      if EDL then reaper.ImGui_PopStyleColor(ctx, 3) end
      reaper.ImGui_NewLine(ctx) 
      
    end
    
    if reaper.ImGui_CollapsingHeader(ctx, 'Expand multichannel items to mono items on new tracks', false) then
      local Hsize = fontSize*6
      
      reaper.ImGui_NewLine(ctx)
      reaper.ImGui_SameLine(ctx, fontSize)
      
      local childflags = reaper.ImGui_ChildFlags_AutoResizeX()
      local childL = reaper.ImGui_BeginChild(ctx, 'ChildL', 0, Hsize, childflags) 
      if childL then
        if reaper.ImGui_Button(ctx, 'Analyse') then
          SelItems, TrackList = GetSelItemsPerTrack()
        end
        
        if #SelItems > 0 and #TrackList > 0 then
          reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.MainButton.Default)
          reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), gui_colors.MainButton.Hovered)
          reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), gui_colors.MainButton.Active)
        end
        
        if reaper.ImGui_Button(ctx, 'Expand') then
          Expand(SelItems, TrackList)
        end
        
        if #SelItems > 0 and #TrackList > 0 then reaper.ImGui_PopStyleColor(ctx,3) end
        
        reaper.ImGui_EndChild(ctx)
      end
      
      reaper.ImGui_SameLine(ctx, nil, fontSize)
      
      local rounding = reaper.ImGui_StyleVar_ChildRounding()
      reaper.ImGui_PushStyleVar(ctx, rounding, 5.0)
      local borderflag = reaper.ImGui_ChildFlags_Border()
      local menubarflag = reaper.ImGui_WindowFlags_MenuBar()
      
      local childR = reaper.ImGui_BeginChild(ctx, 'ChildR', 0, Hsize, borderflag, menubarflag)
      if childR then
        if reaper.ImGui_BeginMenuBar(ctx) then
          reaper.ImGui_Text(ctx, 'Metadata track tags that are found:') 
          reaper.ImGui_EndMenuBar(ctx)
        end
        
        local resizeflag = reaper.ImGui_TableFlags_Resizable()
        if reaper.ImGui_BeginTable(ctx, 'channels', 4, resizeflag ) then 
          for i, trackName in ipairs(TrackList) do 
            reaper.ImGui_TableNextColumn(ctx)
            reaper.ImGui_PushStyleVar(ctx, rounding, 5.0)
            _, TrackList[trackName] = reaper.ImGui_Checkbox(ctx, trackName, TrackList[trackName])
            reaper.ImGui_PopStyleVar(ctx)
          end 
          reaper.ImGui_EndTable(ctx)
        end
        
        reaper.ImGui_EndChild(ctx)
      end
      
      reaper.ImGui_PopStyleVar(ctx)
    end
    
    reaper.ImGui_NewLine(ctx)
    if reaper.ImGui_CollapsingHeader(ctx, 'Split items and choose the most valuable mics', false) then
      reaper.ImGui_Text(ctx, 'The feature is under development')
    end
    
    for i, v in ipairs(OptTable) do
      local option = v
      
      if type(option[3]) == 'boolean' then
        local _, newval = reaper.ImGui_Checkbox(ctx, option[1], option[3])
        option[3] = newval
      end
      
      if type(option[3]) == 'number' then 
        reaper.ImGui_PushItemWidth(ctx, fontSize*3 )
        local _, newval =
        reaper.ImGui_InputDouble(ctx, option[1], option[3], nil, nil, option[4]) 
        
        option[3] = newval
      end
      
      if type(option[3]) == 'string' then
        local choice 
        for k = 1, #option[4] do 
          if option[4][k] == option[3] then choice = k end 
        end
        
        reaper.ImGui_Text(ctx, option[1])
        reaper.ImGui_SameLine(ctx, nil, nil)
        
        reaper.ImGui_PushItemWidth(ctx, fontSize*10.3 )
        
        if reaper.ImGui_BeginCombo(ctx, '##'..i, option[3], nil) then
          for k,f in ipairs(option[4]) do
            local is_selected = choice == k
            if reaper.ImGui_Selectable(ctx, option[4][k], is_selected) then
              choice = k
            end
        
            -- Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
            if is_selected then
              reaper.ImGui_SetItemDefaultFocus(ctx)
            end
          end
          reaper.ImGui_EndCombo(ctx)
        end 
        
        option[3] = option[4][choice]
      end
      
      if type(option[3]) == 'nil' then
        reaper.ImGui_PushFont(ctx, fontSep)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.White)
        
        if i ~= 1 then reaper.ImGui_Text(ctx, '' ) end
        reaper.ImGui_SeparatorText( ctx, option[1] )
        
        reaper.ImGui_PopStyleColor(ctx, 1)
        reaper.ImGui_PopFont(ctx)
      end
      
      OptTable[i] = option
    end -- for
    
    reaper.ImGui_NewLine(ctx)
    reaper.ImGui_PushItemWidth(ctx, savedFontSize*5)
    _, savedFontSize = reaper.ImGui_InputInt
    (ctx, 'Font size for the window (default is 17)', savedFontSize)
    
    reaper.ImGui_PopFont(ctx)
  end
  
  --------------
  function loop()
    PrjTimeOffset = -reaper.GetProjectTimeOffset( 0, false )
    
    if not font or savedFontSize ~= fontSize then
      reaper.SetExtState(ExtStateName, 'FontSize', savedFontSize, true)
      fontSize = savedFontSize
      if font then reaper.ImGui_Detach(ctx, font) end
      if fontSep then reaper.ImGui_Detach(ctx, fontSep) end
      font = reaper.ImGui_CreateFont(fontName, fontSize, reaper.ImGui_FontFlags_None()) -- Create the fonts you need
      fontSep = reaper.ImGui_CreateFont(fontName, fontSize-2, reaper.ImGui_FontFlags_Italic())
      reaper.ImGui_Attach(ctx, font)
      reaper.ImGui_Attach(ctx, fontSep)
    end
    
    esc = reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape())
    
    undo = reaper.ImGui_Shortcut(ctx, reaper.ImGui_Mod_Ctrl() | reaper.ImGui_Key_Z(), reaper.ImGui_InputFlags_RouteGlobal())
    
    redo = reaper.ImGui_Shortcut(ctx, reaper.ImGui_Mod_Ctrl() | reaper.ImGui_Mod_Shift() | reaper.ImGui_Key_Z(), reaper.ImGui_InputFlags_RouteGlobal())
    
      reaper.ImGui_PushFont(ctx, font)
      
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), gui_colors.Background)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), gui_colors.TitleBg)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.Text)
      
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.Button.Default)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), gui_colors.Button.Hovered)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), gui_colors.Button.Active)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(), gui_colors.Green)
      
      --Combo box and check box background
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), gui_colors.ComboBox.Default)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), gui_colors.ComboBox.Hovered)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(), gui_colors.ComboBox.Active)
      --Combo box drop down list
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(), gui_colors.ComboBox.Default)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(), gui_colors.ComboBox.Hovered)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(), gui_colors.ComboBox.Active)
      
      local window_flags = reaper.ImGui_WindowFlags_None()
      reaper.ImGui_SetNextWindowSize(ctx, W, H, reaper.ImGui_Cond_Once()) -- Set the size of the windows.  Use in the 4th argument reaper.ImGui_Cond_FirstUseEver() to just apply at the first user run, so ImGUI remembers user resize s2
      
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.White)
      
      local visible, open = reaper.ImGui_Begin(ctx, windowName, true, window_flags)
      reaper.ImGui_PopStyleColor(ctx, 1)
      
      if visible then
          frame()
          reaper.ImGui_SetWindowSize(ctx, 0, 0, nil ) 
          reaper.ImGui_End(ctx)
      end
      
      reaper.ImGui_PopStyleColor(ctx, 13)
      reaper.ImGui_PopFont(ctx) 
      
      if undo then reaper.Main_OnCommandEx(40029,0,0) end
      if redo then reaper.Main_OnCommandEx(40030,0,0) end
      
      --SetExtStates(OptTable)
      if open and not esc then 
        reaper.defer(loop)
      end
      
      loopcnt = loopcnt+1
  end
  -----------
  
 function showEDLsNames(list)
    if list then 
      for i, line in ipairs(list) do
        local path, fn, ext = SplitFilename(line)
        if path then
          iniFolder = path:gsub('[/\\]$','')
          reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.Green)
          reaper.ImGui_Text(ctx, fn)
          reaper.ImGui_PopStyleColor(ctx,1)
        end
      end
    end
  end
  
  ----------
  
  loop(ctx, font)
end

----------------------------------
---------------------------------

function AnalyseEDLs(EDLs, timeTreshold) --table of pathes
  local CommonEDL = { V = {}, A = {}}
  local Splits = {}
  
  for e, EDLfile in ipairs(EDLs) do
    local EdlTable = { V={Splits={} }, A1={Splits={} }, A2={Splits={} }, A3={Splits={} }, A4={Splits={} } }
    local EDLtext = ''
    local items
    local item
    local fadelen
    local clip
    
    for line in io.lines(EDLfile) do
      EDLtext = EDLtext..line..'\n'.." "
    end
    EDLtext = EDLtext..'\n'
    
    for line in EDLtext:gmatch('[^\n]+') do
      --msg('\n  LINE:   '..line)
      local strparts = {}
      for s in line:gmatch('%S+') do
        table.insert(strparts, s)
      end
      
      if #strparts == 0 then
      --or ( line:match("FCM:") and line:match("FRAME") ) then
      
        if item then
          if clip then table.insert(item.Clips, copy(clip))   clip = nil end --clip without name 
          table.insert(items, copy(item))
          item = nil
        end
      
        if items ~= nil and #items > 0 then  --Collect items in tables
        --msg('close ' .. #items)
          for i, v in ipairs(items) do
            --itemscnt = itemscnt +1
            if v.Type == 'B' then
              table.insert(EdlTable.V, copy(v))
              table.insert(EdlTable.A1, copy(v))
              
              FieldMatch(EdlTable.V.Splits,copy(v.DestIn), true)
              FieldMatch(EdlTable.V.Splits,copy(v.DestOut), true)
              
              FieldMatch(EdlTable.A1.Splits,copy(v.DestIn), true)
              FieldMatch(EdlTable.A1.Splits,copy(v.DestOut), true)
            elseif v.Type:match('V') then
              table.insert(EdlTable.V, copy(v))
              FieldMatch(EdlTable.V.Splits,copy(v.DestIn), true)
              FieldMatch(EdlTable.V.Splits,copy(v.DestOut), true)
            end
            
            v.Type = v.Type:gsub('/V', '')
            if v.Type == 'A' then
              table.insert(EdlTable.A1, copy(v))
              FieldMatch(EdlTable.A1.Splits,copy(v.DestIn), true)
              FieldMatch(EdlTable.A1.Splits,copy(v.DestOut), true)
            elseif v.Type == 'A2' then
              table.insert(EdlTable.A2, copy(v))
              FieldMatch(EdlTable.A2.Splits,copy(v.DestIn), true)
              FieldMatch(EdlTable.A2.Splits,copy(v.DestOut), true)
            elseif v.Type == 'AA' then
              table.insert(EdlTable.A1, copy(v))
              table.insert(EdlTable.A2, copy(v))
              
              FieldMatch(EdlTable.A1.Splits,copy(v.DestIn), true)
              FieldMatch(EdlTable.A1.Splits,copy(v.DestOut), true)
              
              FieldMatch(EdlTable.A2.Splits,copy(v.DestIn), true)
              FieldMatch(EdlTable.A2.Splits,copy(v.DestOut), true)
            end
            
            if v.Type2 and v.Type2:match('3') then
              table.insert(EdlTable.A3, copy(v))
              FieldMatch(EdlTable.A3.Splits,copy(v.DestIn), true)
              FieldMatch(EdlTable.A3.Splits,copy(v.DestOut), true)
            end
            
            if v.Type2 and v.Type2:match('4') then
              table.insert(EdlTable.A4, copy(v))
              FieldMatch(EdlTable.A4.Splits,copy(v.DestIn), true)
              FieldMatch(EdlTable.A4.Splits,copy(v.DestOut), true)
            end
          end
          items = nil
        end
        clip = nil
      else --PARSING EDL starts from here -- Create items from text
        
        if string.match(strparts[1], '%d+') and #strparts >= 8 then --msg('open')
          --if tonumber(strparts[1]) == 5 then return end -- for debuging
        
          items = {}
          item = {Type, Type2, Clips={}, DestIn, DestOut}
          
          item.Type = strparts[3]

          item.DestIn = reaper.parse_timestr_pos( strparts[#strparts-1], 5 ) - PrjTimeOffset - timeTreshold
          item.DestOut = reaper.parse_timestr_pos( strparts[#strparts], 5 ) - PrjTimeOffset - timeTreshold

          if not clip then --msg('get clip')
            clip = { name, SrcIn, SrcOut }
            clip.SrcIn = reaper.parse_timestr_pos( strparts[#strparts-3], 5 ) - PrjTimeOffset
            clip.SrcOut = reaper.parse_timestr_pos( strparts[#strparts-2], 5 ) - PrjTimeOffset
          end
          
          if clip.SrcIn >= clip.SrcOut or item.DestIn >= item.DestOut then
            clip.SrcOut = clip.SrcIn + 1 --to be just more then srcIn in next iteration
            item = nil
            --msg('destroy item')
          elseif #strparts >= 9 and string.match(strparts[#strparts-4], '%d+') then
            fadelen = tonumber(strparts[#strparts-4])
            fadelen = reaper.parse_timestr_pos( '00:00:00:'..fadelen, 5 ) - PrjTimeOffset
            
            --if clip then msg('1st clip src in  '..clip.SrcIn) end
            
            clip.SrcOut = clip.SrcIn + fadelen
            table.insert(item.Clips, copy(clip)) --1st clip without name
            
            clip.SrcIn = reaper.parse_timestr_pos( strparts[#strparts-3], 5 ) - PrjTimeOffset
            clip.SrcOut = clip.SrcIn + fadelen
            table.insert(item.Clips, copy(clip)) --2nd clip without name
            
            item.DestOut = item.DestIn + fadelen
            if item then
              table.insert(items, copy(item))
              --msg('item added')
            end
            item.Clips = {}
            
            item.DestIn = item.DestOut
            item.DestOut = reaper.parse_timestr_pos( strparts[#strparts], 5 ) - timeTreshold - PrjTimeOffset
            clip.SrcIn = clip.SrcOut
            clip.SrcOut = reaper.parse_timestr_pos( strparts[#strparts-2], 5 ) - PrjTimeOffset
          end
        end
        
        
        if line:match("CLIP NAME:") and items then
          
          local nameT = {}
          for s in string.gmatch(line, '[^:]+') do
            s = s:gsub('^%s*(.-)%s*$', '%1') --remove spaces at edges
            table.insert(nameT, s)
          end
           
          if #items > 0 then
            for i,v in ipairs(items) do
              local clips = v.Clips
              for j, c in ipairs(clips) do
              --msg('clip '..j)
                
                if c.name == nil then
                  if #nameT == 2 and nameT[2] == 'BL' then
                    c.name = line
                  elseif #nameT == 2 then
                    c.name = nameT[2]
                  end 
                  break
                end
                
              end
            end
          elseif #nameT == 2 then
            clip.name = nameT[2]
          end
          
          if item then
            if clip then
              table.insert(item.Clips, copy(clip))
              clip = nil --clip without name
            end 
            table.insert(items, copy(item)) 
            --msg('item added')
            item = nil
          end
          
        elseif line:match("AUD ") and #strparts <= 3 and items then
          if #items > 0 then
            for i,v in ipairs(items) do
              v.Type2 = line:gsub("AUD", ''):gsub("%s+", '') 
            end
          end
        end
        
      end --end of parsing
      --msg(line)
    end -- end line cycle
    
    for i, v in pairs(EdlTable) do
      if v[1] then
        --table.insert(CommonEDL, EdlTable)
        if EDLcontentFlags & 1 ~= 0 then
          CommonEDL.V['V_'..e] = EdlTable.V
          table.insert(CommonEDL.V, 'V_'..e)
        end
        
        if EDLcontentFlags & 1<<1 ~= 0 then
          CommonEDL.A['A1_'..e] = EdlTable.A1
          table.insert(CommonEDL.A, 'A1_'..e)
        end
        if EDLcontentFlags & 1<<2 ~= 0 then
          CommonEDL.A['A2_'..e] = EdlTable.A2
          table.insert(CommonEDL.A, 'A2_'..e)
        end
        if EDLcontentFlags & 1<<3 ~= 0 then
          CommonEDL.A['A3_'..e] = EdlTable.A3
          table.insert(CommonEDL.A, 'A3_'..e)
        end
        if EDLcontentFlags & 1<<4 ~= 0 then
          CommonEDL.A['A4_'..e] = EdlTable.A4
          table.insert(CommonEDL.A, 'A4_'..e)
        end
        break
      end
    end
  end --end of edl files cycle
  
  --Remove Fades in Audio clips
  --[[
  for name, track in pairs(EdlTable) do
    if name ~= 'V' then
    
      for i, item in ipairs(track) do
        local c = #item.Clips
        while c > 0 do
          local clip = item.Clips[c]
          if clip.name and  clip.name:match('CLIP NAME: BL') then
            table.remove(item.Clips, c)
          end
          c = c-1
        end
      end
      
    end
  end
  ]]
  
  return CommonEDL
end

-------------------------------
function SplitFilename(strFilename) -- Path, Filename, Extension
  return string.match(strFilename, "(.-)([^\\]-([^\\%.]+))$")
end
-------------------------------

function CleanUpEDLs(EdlsTable)
  
  local trackType = {'V','A'}
  --First cleanup all track tables and combine fades and crossfades items with neighbour items
  for k, trType in ipairs(trackType) do
    for e, edlTname in ipairs(EdlsTable[trType]) do
      local trackT = EdlsTable[trType][edlTname]
      local itemsForDel = {}
      
      for i, item in ipairs(trackT) do
        if #item.Clips == 2 then
          
          if item.Clips[1]['name'] then
            if trackT[i-1]['Clips'][#trackT[i-1]['Clips']]['name'] == item.Clips[1]['name'] then
              trackT[i-1]['DestOut'] = item.DestOut
              trackT[i-1]['Clips'][#trackT[i-1]['Clips']]['SrcOut'] = item.Clips[1]['SrcOut']
              table.insert(itemsForDel, i)
            end
          end
          
          if item.Clips[2]['name'] then
            if trackT[i+1]['Clips'][1]['name'] == item.Clips[2]['name'] then
              trackT[i+1]['DestIn'] = item.DestIn
              trackT[i+1]['Clips'][1]['SrcIn'] = item.Clips[2]['SrcIn']
              FieldMatch(itemsForDel, i, true)
            end
          end
          
        end
      end
      
      table.sort(itemsForDel, function(a,b) return (a>b) end)
      for i, idx in ipairs(itemsForDel) do
        table.remove(trackT, idx)
      end
      
    end
  end
  
  ---Remove duplicates--- 
  for k, trType in ipairs(trackType) do
    local refItems = {}
    
    for e, edlTname in ipairs(EdlsTable[trType]) do 
      local trackT = EdlsTable[trType][edlTname] 
      local itemsForDel = {}
      
      for i, item in ipairs(trackT) do
        for ri, refItem in ipairs(refItems) do
          if item.DestIn == refItem.DestIn and item.DestOut == refItem.DestOut
          and item.Clips[1]['name'] == refItem.Clips[1]['name']
          and item.Clips[1]['SrcIn'] == refItem.Clips[1]['SrcIn']
          and item.Clips[1]['SrcOut'] == refItem.Clips[1]['SrcOut'] then 
            FieldMatch(itemsForDel, i, true) 
          end
        end
      end
      
      table.sort(itemsForDel, function(a,b) return (a>b) end)
      for i, idx in ipairs(itemsForDel) do
        table.remove(trackT, idx)
      end
      
      table.move(trackT, 1, #trackT, #refItems+1, refItems)
      
    end
  end
   
end

-------------------------------

function Expand(SelItems, TrackList)
  if TrackList['No name'] ~= nil then
    ExpandNoNamedCh = TrackList['No name']
    reaper.SetExtState(ExtStateName, 'ExpNoName', tostring(TrackList['No name']), true)
  end
  
  local NewTracks = {}
  
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock2(0)
  
  for t, TData in ipairs(SelItems) do
    local tIdx = reaper.GetMediaTrackInfo_Value( TData.Track, 'IP_TRACKNUMBER' )
    local Tracks = {}
    local ItemsToRemove = {}
      
    for t, name in ipairs(TrackList) do
      if TrackList[name] == true then
        UndoString = 'Expand multichannel items - Post pro tools'
        reaper.InsertTrackAtIndex(tIdx, true)
        local track = reaper.GetTrack(0, tIdx)
        local _,_ = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', name, true)
        Tracks[name] = track
        table.insert(NewTracks, track)
        tIdx = tIdx +1
      end
    end
    
    for i, Item in ipairs(TData.Titems) do
    --msg('\n'..Item.name)
    --match channel names with names in TrackList and
      for n, name in ipairs(Item.chnNames) do
        if FieldMatch(TrackList, name) == true then
          local ch = n +2
          local track
          if name ~= 'No name' then track = Tracks[name]
          elseif not Tracks['ch_'..n] and TrackList['No name'] == true then
            reaper.InsertTrackAtIndex(tIdx, true)
            track = reaper.GetTrack(0, tIdx)
            tIdx = tIdx +1
            local _,_ = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', 'ch_'..n, true)
            Tracks['ch_'..n] = track
            table.insert(NewTracks, track)
          elseif Tracks['ch_'..n] then
            track = Tracks['ch_'..n]
          end
          
          if track then
            local newItem = reaper.AddMediaItemToTrack(track)
            reaper.SetMediaItemInfo_Value(newItem, 'D_POSITION', Item.pos)
            reaper.SetMediaItemInfo_Value(newItem, 'D_LENGTH', Item.len)
            reaper.SetMediaItemInfo_Value(newItem, 'D_FADEINLEN', 0 )
            reaper.SetMediaItemInfo_Value(newItem, 'D_FADEOUTLEN', 0 )
            reaper.SetMediaItemInfo_Value(newItem, "D_VOL", Item.vol )
            
            reaper.SetMediaItemInfo_Value(newItem, 'D_FADEINLEN_AUTO', Item.fIn )
            reaper.SetMediaItemInfo_Value(newItem, 'D_FADEOUTLEN_AUTO', Item.fOut )
            
            local take = reaper.AddTakeToMediaItem(newItem)
            local src = reaper.PCM_Source_CreateFromFile(Item.file)
            reaper.SetMediaItemTake_Source( take, src )
            reaper.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', Item.offs )
            local _, _ = reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', Item.name, true )
            
            reaper.SetMediaItemTakeInfo_Value( take, 'I_CHANMODE', ch )
            
            FieldMatch(ItemsToRemove, Item.item, true)
          end
          
        end
      end --chnNames cycle
        
    end -- Track items cycle
    
    for i, item in ipairs(ItemsToRemove) do
      reaper.DeleteTrackMediaItem(TData.Track, item)
    end
    
  end -- Tracks cycle
  
  for t, track in ipairs(NewTracks) do
    if reaper.CountTrackMediaItems(track) == 0 then reaper.DeleteTrack(track) end
  end
  
  if UndoString then
    reaper.UpdateArrange()
    reaper.Undo_EndBlock2(0, UndoString, 1)
  end 
  
end

-------------------------------

function GetSelItemsPerTrack()
  local SI = {}
  local TrackList = {}
  local oldTrack
  
  for i=0, reaper.CountSelectedMediaItems(0) -1 do
    local TData = {Track, Titems={} }
    local Item = {}
    local item = reaper.GetSelectedMediaItem(0,i)
    local iTrack = reaper.GetMediaItemTrack(item)
    
    local take = reaper.GetActiveTake(item)
    local src = reaper.GetMediaItemTake_Source(take)
    
    if src then --is item in range
      Item.file = reaper.GetMediaSourceFileName( src )
      Item.item = item
      Item.pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      Item.len = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
      Item.vol = reaper.GetMediaItemInfo_Value( item, "D_VOL" )
      Item.fIn = reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN_AUTO" )
      Item.fOut = reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN_AUTO" )
      Item.offs = reaper.GetMediaItemTakeInfo_Value( take, "D_STARTOFFS" )
      _, Item.name = reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', '', false )
      Item.chnNumb = reaper.GetMediaSourceNumChannels(src)
      Item.chnNames = {}
      --msg('\n'..Item.name)
      
      for ch = 1, Item.chnNumb do
        local chanTag = "IXML:TRACK_LIST:TRACK:NAME"
        if ch ~= 1 then chanTag = chanTag..':'..ch end
        local ret, str = reaper.GetMediaFileMetadata(src, chanTag)
        --msg(chanTag..' - '..str)
        local use = true
        if str == '' then
          str = 'No name'
          use = ExpandNoNamedCh
        end
        table.insert(Item.chnNames, str)
        if FieldMatch(TrackList, str, true) == false then TrackList[str] = use end
      end
      
    end
    
    if src then
      if iTrack ~= oldTrack then
        oldTrack = iTrack
        TData.Track = iTrack
        table.insert(TData.Titems, Item)
        table.insert(SI, TData)
      else
        table.insert(SI[#SI].Titems, Item )
      end
    end
  end
  
  for i, v in ipairs(TrackList) do
    if v == 'No name' then table.remove(TrackList, i) table.insert(TrackList, 1, v) end
  end
  
  return SI, TrackList
end

-------------------------------

function AddDopTracks(dopTRACKS)
  for i=1,2 do
    local trackT
    if i == 1 then trackT = dopTRACKS.Common else trackT = dopTRACKS.Named end
    
    for t, tr in pairs(trackT) do 
      local track
      local suffix = 1
      
      local prevPos
      local prevEnd
      
      for it, itemData in ipairs(tr) do
      
        if ( not track and not prevPos and not prevEnd)
        or (prevPos >= itemData.pos or prevEnd >= itemData.pos + itemData.length) then
        
          local trName
          if i == 2 and suffix == 1 then
            trName = tr.name
          else
            trName = tr.name ..'_'..suffix 
          end
          
          reaper.InsertTrackInProject( 0, LastTrIdx, 1 )
          track = reaper.GetTrack(0, LastTrIdx)
          local _,_ = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', trName, true) 
          
          LastTrIdx = LastTrIdx+1
          suffix = suffix+1
        end
        
        local newItem = reaper.AddMediaItemToTrack(track)
        reaper.SetMediaItemInfo_Value(newItem, 'D_POSITION', itemData.pos)
        reaper.SetMediaItemInfo_Value(newItem, 'D_LENGTH', itemData.length)
        reaper.SetMediaItemInfo_Value(newItem, 'D_FADEINLEN', 0 )
        reaper.SetMediaItemInfo_Value(newItem, 'D_FADEOUTLEN', 0 )
         
        if itemData.fadeIn then 
          reaper.SetMediaItemInfo_Value(newItem, 'D_FADEINLEN_AUTO', itemData.fadeIn )
        end
        if itemData.fadeOut then 
          reaper.SetMediaItemInfo_Value(newItem, 'D_FADEOUTLEN_AUTO', itemData.fadeOut )
        end
        
        local take = reaper.AddTakeToMediaItem(newItem)
        reaper.SetMediaItemTake_Source( take, itemData.src )
        reaper.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', itemData.offset )
        local _, _ = reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', itemData.name, true )
        
        prevPos = itemData.pos
        prevEnd = itemData.pos + itemData.length
      end
      
    end
    
  end
end

-------------------------------

function CreateTracks(EdlsTable)
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock2(0)
  
  CleanUpEDLs(EdlsTable)
  --------------------
  --Now create tracks and items
  local list_files, list_file_metadata = GetAllFiles({SearchFolder})
  LastTrIdx = reaper.CountTracks(0)
  --msg(#list_files)
  --for f, file in ipairs(list_files) do msg(file) end
  
  local trackType = {'V','A'}
  
  for k, trType in ipairs(trackType) do
    for e, edlTname in ipairs(EdlsTable[trType]) do
      local trackT = EdlsTable[trType][edlTname]
      local dopTRACKS = { Named = {}, Common = {} }
      
      --Create track
      local track
      if #trackT > 0 then
        reaper.InsertTrackInProject( 0, LastTrIdx, 1 )
        track = reaper.GetTrack(0, LastTrIdx)
        local _,_ = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', edlTname, true)
        LastTrIdx = LastTrIdx+1
        
        UndoString = 'Import tracks and media from EDl'
      end
      
      local crossfade
      local maxidx = #trackT
      for i, item in ipairs(trackT) do
        --Create item
        local newItem = reaper.AddMediaItemToTrack(track)
        local fadeInAuto
        local fadeOutAuto
        local match
         
        reaper.SetMediaItemInfo_Value(newItem, 'D_POSITION', item.DestIn)
        reaper.SetMediaItemInfo_Value(newItem, 'D_LENGTH', item.DestOut - item.DestIn)
        reaper.SetMediaItemInfo_Value(newItem, 'D_FADEINLEN', 0 )
        reaper.SetMediaItemInfo_Value(newItem, 'D_FADEOUTLEN', 0 )
         
        if crossfade then
          fadeInAuto = crossfade
          reaper.SetMediaItemInfo_Value(newItem, 'D_FADEINLEN_AUTO', crossfade )
        end
        
        if i ~= maxidx then
          crossfade = item.DestOut - trackT[i+1]['DestIn']
          if crossfade <= MIN_luft_ZERO then crossfade = nil end
        end
        
        if crossfade then
          fadeOutAuto = crossfade
          reaper.SetMediaItemInfo_Value(newItem, 'D_FADEOUTLEN_AUTO', crossfade )
        end
        
        if not edlTname:match('V') then
          --Paste source looking at "BWF:TimeReference"
          local clipStart = item.Clips[1]['SrcIn']
          local clipName = item.Clips[1]['name']
          local path, clipFileName, ext = SplitFilename(clipName)
          
          for s = 1, 2 do
            if match then break end
            for f, file in ipairs(list_files) do 
              local metadataList = list_file_metadata[file]
              local fileMod = file:gsub('-','_'):gsub('+','_'):gsub('*','_')
              local clipNameMod = clipName:gsub('-','_'):gsub('+','_'):gsub('*','_')
              local clipFileNameMod = clipFileName:gsub('.'..ext, ''):gsub('-','_'):gsub('+','_'):gsub('*','_')
              --msg--
              --[[
              if clipName == 'S-10-1-009.WAV'
              and fileMod:match('S_10_1_009.WAV') then msg('\n')
                msg(clipName)
                msg(f..' '..s)
                msg(file)
                if metadataList and metadataList.TAKE and metadataList.SCENE then 
                  msg(metadataList.TAKE) msg(clipNameMod:match(metadataList.TAKE))
                  msg(metadataList.SCENE) msg(clipNameMod:match(metadataList.SCENE))
                end
              end
              ---
              ]]
              
              if( ( metadataList and metadataList.TAKE and metadataList.SCENE )
              and clipNameMod:match(metadataList.TAKE) and clipNameMod:match(metadataList.SCENE)
              )
              or ( fileMod:match(clipNameMod) )
              or ( s == 2 and fileMod:match(clipFileNameMod) ) then
                local newSrc = reaper.PCM_Source_CreateFromFile( file )
                if newSrc then
                  local filematch
                  local srcLen, isQN = reaper.GetMediaSourceLength(newSrc)
                  local splRate = reaper.GetMediaSourceSampleRate(newSrc)
                  
                  if isQN == false then
                    local fileTC = 0
                    if metadataList and metadataList.TC ~= '' then 
                      fileTC = tonumber(metadataList.TC)/splRate
                    end
                    
                    local offset = clipStart - fileTC
                    if offset < 0 then offset = clipStart end
                    
                    if offset + (item.DestOut - item.DestIn) < srcLen then
                      match, filematch = true, true
                      
                      if Opt and Opt.AddNewTrks == true then
                        local trName =  metadataList.TRACKNAME
                        local itemData = {
                                    pos = item.DestIn,
                                    length = item.DestOut - item.DestIn,
                                    fadeIn = fadeInAuto,
                                    fadeOut = fadeOutAuto,
                                    offset = offset,
                                    src = newSrc,
                                    name = clipFileName
                                    }
                        if reaper.GetMediaSourceNumChannels(newSrc) == 1
                        and metadataList.TRACKNAME ~= ''
                        and Opt.SortMonoByNamedTrks == true then
                          if not dopTRACKS.Named[trName] then dopTRACKS.Named[trName] = {} end
                          dopTRACKS.Named[trName]['name'] = trName
                          table.insert(dopTRACKS.Named[trName], itemData)
                        else
                          if not dopTRACKS.Common[1] then dopTRACKS.Common[1] = {} end
                          dopTRACKS.Common[1]['name'] = edlTname
                          table.insert(dopTRACKS.Common[1], itemData)
                        end 
                        
                      else
                        local take = reaper.AddTakeToMediaItem(newItem) 
                        reaper.SetMediaItemTake_Source( take, newSrc )
                        reaper.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', offset )
                        local _, _ = reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', clipFileName, true )
                      end
                    end 
                  end
                  
                  if filematch ~= true then
                    reaper.PCM_Source_Destroy(newSrc)
                  end
                end
              end
              
            end
          end
          
          if reaper.CountTakes( newItem ) == 0 and match == true then
            reaper.DeleteTrackMediaItem(track, newItem)
          end
          
          if match ~= true then
            local _,_ = reaper.GetSetMediaItemInfo_String(newItem, 'P_NOTES', clipName, true)
          end
          
        else --if track is Video one
          local _,_ = reaper.GetSetMediaItemInfo_String(newItem, 'P_NOTES', item.Clips[1]['name'], true)
        end
        
      end -- for item cycle
      
      AddDopTracks(dopTRACKS)
      
    end  
  end

  if UndoString then
    reaper.UpdateArrange()
    reaper.Undo_EndBlock2(0, UndoString, 1)
  end 

end

-------------------------

function save_metadata(source,list_metadata)
  local value_list = {}
  local dop_list = {}
  local _, descBwf = reaper.GetMediaFileMetadata(source,"BWF:Description")
  
  for v in descBwf:gmatch('[^\n]+') do
    local key
    v = v:sub(2) -- removes first lower case letter that differs from file to file and seems to mean nothing
    v = v:gsub('-','_')
    v = v:gsub('+','_')
    v = v:gsub('*','_')
    v = v:gsub('\n','')
    key, v = v:match("%s*([^=]*)%s*%=%s*(.-)%s*$") --Split construction 'key=value' 
    dop_list[key] = v
  end
  
  for i, v in ipairs(list_metadata) do
    for t, tag in ipairs(v[4]) do
      if tag ~= '' then
        local retval,value = reaper.GetMediaFileMetadata(source,tag) 
        if dop_list[v[2]] and value == '' then -- this value has priority higer than the dop_list
          value_list[v[2]] = dop_list[v[2]]
        elseif value ~= '' then
          value = value:gsub('-','_'):gsub('+','_'):gsub('*','_')
          value_list[v[2]] = value
        end
      end
    end
  end
  
  return value_list
end

-------------------------
separ = package.config:sub(1,1)

TagsList = {}
--[[
  "IXML:SPEED:TIMESTAMP_SAMPLES_SINCE_MIDNIGHT_LO",
  "IXML:BEXT:BWF_ORIGINATION_DATE",
  "IXML:PROJECT",
  "IXML:TAPE",
  "IXML:SCENE",
  "IXML:TAKE",
  "BWF:Description",
  "BWF:TimeReference"]]
  
  ---THE LAST TAG (if several tags applied) has the higer priority!---
  local text = 'Timecode'
  table.insert(TagsList, {text, 'TC', true, {"VORBIS:TIME_REFERENCE", "BWF:TimeReference"} })
  local text = 'Project'
  table.insert(TagsList, {text, 'PROJECT', true, {"IXML:PROJECT", ''} })
  local text = 'Date'
  table.insert(TagsList, {text, 'DATE', true, {"IXML:BEXT:BWF_ORIGINATION_DATE", "BWF:OriginationDate"} })
  local text = 'Tape'
  table.insert(TagsList, {text, 'TAPE', true, {"IXML:TAPE", ''} })
  local text = 'Scene'
  table.insert(TagsList, {text, 'SCENE', true, {"IXML:SCENE", ''} })
  local text = 'Take'
  table.insert(TagsList, {text, 'TAKE', true, {"IXML:TAKE", ''} })
  
  local text = 'TrCount'
  table.insert(TagsList, {text, 'TRACKCOUNT', true, {"IXML:TRACK_LIST:TRACK_COUNT", ''} })
   
  local text = 'TrName'
  table.insert(TagsList, {text, 'TRACKNAME', true, {"IXML:TRACK_LIST:TRACK:NAME", ''} })

function GetAllFiles(folderlist,filelist,metadatalist)
  if type(folderlist)   ~= 'table' then return            end
  if type(filelist)     ~= 'table' then filelist     = {} end
  if type(metadatalist) ~= 'table' then metadatalist = {} end 
  local childs = {}
  for i, folder in ipairs(folderlist) do
    reaper.EnumerateFiles(folder,-1) -- Rescan
    local i = 0
    while reaper.EnumerateFiles(folder,i) do
      local filename = reaper.EnumerateFiles(folder,i)
      local file = folder..separ..filename 
      local path, fn, ext = SplitFilename(filename)
      if string.upper(ext) == 'WAV' or string.upper(ext) == 'FLAC'
      or string.upper(ext) == 'MP3' or string.upper(ext) == 'OGG' then
        table.insert(filelist,file)
      end
      
      if string.upper(ext) == 'WAV' or string.upper(ext) == 'FLAC' then
        local tmp_source = reaper.PCM_Source_CreateFromFile(file)
        metadatalist[file] = save_metadata(tmp_source,TagsList)
        reaper.PCM_Source_Destroy(tmp_source)
      end
      i = i + 1
    end
    reaper.EnumerateSubdirectories(folder,-1) -- Rescan
    local i = 0
    while reaper.EnumerateSubdirectories(folder,i) do
      table.insert(childs,folder..separ..reaper.EnumerateSubdirectories(folder,i))
      i = i + 1
    end
  end
  if #childs == 0 then
    return filelist, metadatalist
  else
    return GetAllFiles(childs,filelist,metadatalist)
  end
end

---------------------------
-------------------------

function copy(tbl)
  if type(tbl) ~= "table" then
    return tbl
  end
  local result = {}
  for k, v in pairs(tbl) do 
    result[k] = copy(v)
  end
  return result
end

-------------------------

function FieldMatch(Table,value, AddRemoveFlag) -- can remove only first finded value
  for i=1, #Table do
    if value == Table[i] then
      if AddRemoveFlag == false then table.remove(Table,i) end
      if AddRemoveFlag ~= nil then
        return true, Table
      else return true
      end
    end
  end
  if AddRemoveFlag == true then table.insert(Table, value) end
  if AddRemoveFlag ~= nil then
    return false, Table
  else return false
  end
end

-----------------------------------
--------------START----------------

MainWindow({}, 'Conform project using metadata | Post-production tools')

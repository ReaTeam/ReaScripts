-- @noindex

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
  
  local maxWinW = 100 --doesn't matter if all collased header are closed at start
  local fontSize = 17
  local ctx, font, fontSep
  local H = fontSize
  local W = fontSize
  local loopcnt = 0
  local esc
  local EDL
  
  local SelItems, TrackList = {}, {}
  SuccessItems = {}
  
  local hasPrState, iniFolder = reaper.GetProjExtState(0, ExtStateName, 'SearchFolder')
  if hasPrState ~= 1 then
    iniFolder = nil
  else SearchFolder = iniFolder
  end
  
  for i, v in ipairs(TagsList) do
    if v[1] ~= '' then
      if reaper.HasExtState(ExtStateName, v[2]) then
        v[3] = ValToBool( reaper.GetExtState(ExtStateName, v[2]) )
      end
    end
  end
  
  EDLcontentFlags = reaper.GetExtState(ExtStateName, 'ContentAnalyse')
  
  if EDLcontentFlags ~= "" then
    EDLcontentFlags = tonumber(EDLcontentFlags)
  else EDLcontentFlags = 31
  end
  
  MatchTakeFileName = ValToBool( reaper.GetExtState(ExtStateName, 'MatchTakeFileName') )
  if MatchTakeFileName == nil then MatchTakeFileName = true end
  
  LinkOnlyByTC = ValToBool( reaper.GetExtState(ExtStateName, 'LinkOnlyByTC') )
  if LinkOnlyByTC == nil then LinkOnlyByTC = false end
  
  SincByTC = ValToBool( reaper.GetExtState(ExtStateName, 'SincByTC') )
  if SincByTC == nil then SincByTC = true end
  
  AddNewTrks = ValToBool( reaper.GetExtState(ExtStateName, 'AddNewTrks') )
  if AddNewTrks == nil then AddNewTrks = true end
  
  ExpandNoNamedCh = ValToBool( reaper.GetExtState(ExtStateName, 'ExpNoName') )
  if ExpandNoNamedCh == nil then ExpandNoNamedCh = true end
  
  _, TrimLeadingTime = ValToBool( reaper.GetProjExtState(0, ExtStateName, 'TrimLeadingTime') )
  _, TrimOnlyEmptyTime = ValToBool( reaper.GetProjExtState(0,ExtStateName, 'TrimOnlyEmptyTime') )
  _, TrimTime = reaper.GetProjExtState(0, ExtStateName, 'TrimTime')
  
  if TrimLeadingTime == nil then TrimLeadingTime = true end
  if TrimOnlyEmptyTime == nil then TrimOnlyEmptyTime = true end
  
  if TrimTime == '' then TrimTime = '01:00:00:00' end
  
  local renameStr = reaper.GetExtState(ExtStateName, 'RenameStr')
  if renameStr == '' then renameStr = '@SCENE-T@TAKE_@fieldRecTRACK' end
  
  local noteStr = reaper.GetExtState(ExtStateName, 'NoteStr')
  if noteStr == '' then noteStr = '@NOTE' end
  
  UseTakeMarkerNote = ValToBool( reaper.GetExtState(ExtStateName, 'TakeMarkNote') )
  if UseTakeMarkerNote == nil then UseTakeMarkerNote = true end
  
  
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
  ---Flags---
  local Flags = {}
  Flags.childRounding = reaper.ImGui_StyleVar_ChildRounding()
  Flags.frameRounding = reaper.ImGui_StyleVar_FrameRounding()
  Flags.childBorder = reaper.ImGui_ChildFlags_Border()
  Flags.menubar = reaper.ImGui_WindowFlags_MenuBar()
  Flags.tableResizeflag = reaper.ImGui_TableFlags_Resizable()
  Flags.childAutoResizeX = reaper.ImGui_ChildFlags_AutoResizeX()
  Flags.childAutoResizeY = reaper.ImGui_ChildFlags_AutoResizeY() 
  
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
      local doc = 'https://forum.cockos.com/showthread.php?t=300182'
      if reaper.CF_ShellExecute then
        reaper.CF_ShellExecute(doc)
      else
        reaper.MB(doc, '?forum page', 0)
      end
    end
    
    if reaper.ImGui_CollapsingHeader(ctx, 'Create tracks using EDL files', false) then
      reaper.ImGui_NewLine(ctx)
      reaper.ImGui_SameLine(ctx, fontSize)
      local childflags = Flags.childAutoResizeY | Flags.childAutoResizeX
      local childCreateTracks = reaper.ImGui_BeginChild(ctx, 'ChildCreateTracks', 0, 0, childflags)
      
      if childCreateTracks then
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
        
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_PushFont(ctx, fontSep)
        reaper.ImGui_Text(ctx, 'Note: the project has to be set to the known framerate') 
        reaper.ImGui_PopFont(ctx)
        
        if SearchFolder and SearchFolder ~= '' then
          reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.Green)
          reaper.ImGui_Text(ctx, SearchFolder)
          reaper.ImGui_PopStyleColor(ctx,1)
        end
        
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
        --reaper.ImGui_NewLine(ctx)
        
        --Source tracks
        local childflags = Flags.childAutoResizeY | Flags.childBorder
        local childImportSettings = reaper.ImGui_BeginChild(ctx, 'ChildImportSettings', fontSize*33, 0, childflags, Flags.menubar)
        
        if childImportSettings then
          
          if reaper.ImGui_BeginMenuBar(ctx) then
            reaper.ImGui_Text(ctx, 'Import settings:')
            reaper.ImGui_EndMenuBar(ctx)
          end
           
          reaper.ImGui_PushFont(ctx, fontSep)
          
          local choiceSrc, change
          change, choiceSrc = reaper.ImGui_Checkbox(ctx, 'Video track', EDLcontentFlags & 1)
          if change then EDLcontentFlags = EDLcontentFlags ~1 end
          
          reaper.ImGui_SameLine(ctx, nil, fontSize)
          change, choiceSrc = reaper.ImGui_Checkbox(ctx, 'Audio 1', (EDLcontentFlags>>1) & 1)
          if change then EDLcontentFlags = EDLcontentFlags  ~ (1<<1) end
          
          reaper.ImGui_SameLine(ctx, nil, fontSize)
          change, choiceSrc = reaper.ImGui_Checkbox(ctx, 'Audio 2', (EDLcontentFlags>>2) & 1)
          if change then EDLcontentFlags = EDLcontentFlags  ~ (1<<2) end
          
          reaper.ImGui_SameLine(ctx, nil, fontSize)
          change, choiceSrc = reaper.ImGui_Checkbox(ctx, 'Audio 3', (EDLcontentFlags>>3) & 1)
          if change then EDLcontentFlags = EDLcontentFlags  ~ (1<<3) end
          
          reaper.ImGui_SameLine(ctx, nil, fontSize)
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
          reaper.ImGui_SameLine(ctx, nil, fontSize*1.2)
          ret, TrimOnlyEmptyTime = reaper.ImGui_Checkbox(ctx,'Only empty time if multiplied##1',TrimOnlyEmptyTime)
          if ret == true then reaper.SetProjExtState(0,ExtStateName,'TrimOnlyEmptyTime', tostring(TrimOnlyEmptyTime), true) end
          
          reaper.ImGui_PopFont(ctx)
          reaper.ImGui_EndChild(ctx)
        end
        
        local processing
        if EDL then
          reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.MainButton.Default)
          reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), gui_colors.MainButton.Hovered)
          reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), gui_colors.MainButton.Active)
        end
        
        if reaper.ImGui_Button(ctx, 'Create tracks and items') then
          processing = true
          if EDL then
            local timeTreshold = 0
        
            if TrimLeadingTime == true and TrimOnlyEmptyTime == false then
              timeTreshold = reaper.parse_timestr_pos( TrimTime, 5 ) - PrjTimeOffset
            end 
        
            local EdlsTable = AnalyseEDLs(EDL, timeTreshold)
            
            if #EdlsTable.V == 0 and #EdlsTable.A == 0 then
              reaper.ShowMessageBox('There is no valid data in EDL files', 'Warning!',0) 
            else
              local notMatchedItems = CreateTracks(EdlsTable)
              if #notMatchedItems > 0 then
                msg(#notMatchedItems..' CLIPS FROM EDL HAVE NO MATCH!\n')
                for i, item in ipairs(notMatchedItems) do
                  msg('Track '..item[3]..'  '..reaper.format_timestr_pos(item[1],'',5)..'  '..item[2])
                end
              else
                for i, item in ipairs(SuccessItems) do reaper.SetMediaItemSelected(item, true) end
                SuccessItems = {}
              end
            end
             
          end
        end
        if EDL then reaper.ImGui_PopStyleColor(ctx, 3) end
        if processing then reaper.ImGui_SameLine(ctx, nil, fontSize)
          reaper.ImGui_Text(ctx, 'processing...')
        end
        
        reaper.ImGui_SameLine(ctx, nil, fontSize)
        local ret
        ret, AddNewTrks = reaper.ImGui_Checkbox(ctx, 'Add new tracks instead of takes', AddNewTrks)
        if ret then reaper.SetExtState(ExtStateName, 'AddNewTrks', tostring(AddNewTrks), true) end
        
        reaper.ImGui_NewLine(ctx)
        reaper.ImGui_EndChild(ctx)
      end
    end
    
    if reaper.ImGui_CollapsingHeader(ctx, 'Link files to selected items using metadata', false) then
      reaper.ImGui_NewLine(ctx)
      reaper.ImGui_SameLine(ctx, fontSize)
      local childflags = Flags.childAutoResizeY | Flags.childAutoResizeX
      local childMatchFiles = reaper.ImGui_BeginChild(ctx, 'ChildMatchFiles', 0, 0, childflags)
      if childMatchFiles then
      
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
        
        
        local childflags = Flags.childAutoResizeY | Flags.childAutoResizeX | Flags.childBorder
        local childTags = reaper.ImGui_BeginChild(ctx, 'ChildTags', 0, 0, childflags, Flags.menubar)
        if childTags then
          if reaper.ImGui_BeginMenuBar(ctx) then
            reaper.ImGui_Text(ctx, 'Metadata fields ')
            reaper.ImGui_EndMenuBar(ctx)
          end
          
          for i, v in ipairs(TagsList) do
            if v[1] ~= '' then
              local ret
              ret, v[3] = reaper.ImGui_Checkbox(ctx, v[1], v[3])
              if ret then reaper.SetExtState(ExtStateName, v[2], tostring(v[3]), true) end
            end
          end
          
          reaper.ImGui_EndChild(ctx)
        end
        
        reaper.ImGui_SameLine(ctx)
        
        local w, h = reaper.ImGui_GetItemRectSize(ctx)
        local Wsize = maxWinW - w - fontSize*2
        local childDop = reaper.ImGui_BeginChild(ctx, 'ChildDop', Wsize, 0, Flags.childBorder, Flags.menubar)
        if childDop then
          local ret
          ret, MatchTakeFileName = reaper.ImGui_Checkbox(ctx, 'Match take and file names', MatchTakeFileName)
          if ret then reaper.SetExtState(ExtStateName, 'MatchTakeFileName', tostring(MatchTakeFileName), true) end
          
          if LinkOnlyByTC == true then SincByTC = true end 
          ret, SincByTC = reaper.ImGui_Checkbox(ctx, 'Sync source by timecode', SincByTC)
          if ret then reaper.SetExtState(ExtStateName, 'SincByTC', tostring(SincByTC), true) end
           
          reaper.ImGui_NewLine(ctx) reaper.ImGui_SameLine(ctx, fontSize*1.5)
          
          if SincByTC == false then LinkOnlyByTC = false end
          ret, LinkOnlyByTC = reaper.ImGui_Checkbox(ctx, 'Link files by timecode only if other fields are empty', LinkOnlyByTC)
          if ret then reaper.SetExtState(ExtStateName, 'LinkOnlyByTC', tostring(LinkOnlyByTC), true) end
          
          reaper.ImGui_NewLine(ctx)
          local itemsCnt = reaper.CountSelectedMediaItems(0)
          if itemsCnt > 0 and SearchFolder and SearchFolder ~= '' then
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.MainButton.Default)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), gui_colors.MainButton.Hovered)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), gui_colors.MainButton.Active)
          end
          
          if reaper.ImGui_Button(ctx, '    Link files    ') then
            local selItems, _ = GetSelItemsPerTrack(true, false)
            --RenameTakes(selItems, renameStr, noteStr)
            local notMatchedItems ={}
            if itemsCnt > 0 and SearchFolder and SearchFolder ~= '' then
              notMatchedItems = LinkFiles(selItems)
            end
            if #notMatchedItems > 0 then
              msg(#notMatchedItems..' ITEMS HAVE NO MATCH!\nThey are selected\n')
              for i, item in ipairs(notMatchedItems) do
                msg('Track '..item[3]..'  '..reaper.format_timestr_pos(item[1],'',5)..'  '..item[2])
              end
            else
              for i, item in ipairs(SuccessItems) do reaper.SetMediaItemSelected(item, true) end
              SuccessItems = {}
            end
          end
          
          if itemsCnt > 0 and SearchFolder and SearchFolder ~= '' then
            reaper.ImGui_PopStyleColor(ctx,3)
          end
          
          reaper.ImGui_SameLine(ctx, nil, fontSize)
           
          ret, AddNewTrks = reaper.ImGui_Checkbox(ctx, 'Add new tracks instead of takes', AddNewTrks)
          if ret then reaper.SetExtState(ExtStateName, 'AddNewTrks', tostring(AddNewTrks), true) end
          
          reaper.ImGui_EndChild(ctx)
        end
        
        reaper.ImGui_EndChild(ctx)
      end
    end
    
    
    if reaper.ImGui_CollapsingHeader(ctx, 'Expand multichannel items to mono items on new tracks', false) then
      local Hsize = fontSize*6
      
      reaper.ImGui_NewLine(ctx)
      reaper.ImGui_SameLine(ctx, fontSize)
      
      local childflags = Flags.childAutoResizeX
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
        
        local expand = reaper.ImGui_Button(ctx, 'Expand')
        
        if #SelItems > 0 and #TrackList > 0 then reaper.ImGui_PopStyleColor(ctx,3) end
        
        if expand then
          Expand(SelItems, TrackList)
          TrackList = {}
        end
        
        reaper.ImGui_EndChild(ctx)
      end
      
      reaper.ImGui_SameLine(ctx, nil, fontSize)
      
      local childR = reaper.ImGui_BeginChild(ctx, 'ChildR', 0, Hsize, Flags.childBorder, Flags.menubar)
      if childR then
        if reaper.ImGui_BeginMenuBar(ctx) then
          reaper.ImGui_Text(ctx, 'Metadata track tags that are found:') 
          reaper.ImGui_EndMenuBar(ctx)
        end
         
        if reaper.ImGui_BeginTable(ctx, 'channels', 4, Flags.tableResizeflag ) then 
          for i, trackName in ipairs(TrackList) do 
            reaper.ImGui_TableNextColumn(ctx) 
            _, TrackList[trackName] = reaper.ImGui_Checkbox(ctx, trackName, TrackList[trackName]) 
          end 
          reaper.ImGui_EndTable(ctx)
        end
        
        reaper.ImGui_EndChild(ctx)
      end
       
    end
    
    
    if reaper.ImGui_CollapsingHeader(ctx, 'Rename selected takes using metadata', false) then
      --reaper.ImGui_NewLine(ctx)
      reaper.ImGui_NewLine(ctx)
      reaper.ImGui_SameLine(ctx, fontSize)
      local childflags = Flags.childAutoResizeY | Flags.childAutoResizeX
      local childRenameCollapse = reaper.ImGui_BeginChild(ctx, 'childRenameCollapse', 0, 0, childflags)
      
      if childRenameCollapse then
        local itemsCnt = reaper.CountSelectedMediaItems(0)
        if itemsCnt > 0 then
          reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.MainButton.Default)
          reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), gui_colors.MainButton.Hovered)
          reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), gui_colors.MainButton.Active)
        end
        
        if reaper.ImGui_Button(ctx, 'Rename') then
          local selItems, _ = GetSelItemsPerTrack(true, true)
          RenameTakes(selItems, renameStr, noteStr)
          reaper.SetExtState(ExtStateName, 'RenameStr', renameStr, true)
          reaper.SetExtState(ExtStateName, 'NoteStr', noteStr, true)
        end
        
        if itemsCnt > 0 then reaper.ImGui_PopStyleColor(ctx,3) end
        
        reaper.ImGui_PushItemWidth(ctx, fontSize*23 )
        _, renameStr = reaper.ImGui_InputText(ctx, '    Take name format', renameStr)
        
        reaper.ImGui_PushItemWidth(ctx, fontSize*23 )
        _, noteStr = reaper.ImGui_InputText(ctx, '    Note or Take marker', noteStr)
        
        reaper.ImGui_PushFont(ctx, fontSep)
        local ret
        ret, UseTakeMarkerNote = reaper.ImGui_Checkbox(ctx, 'Use take markers in addition to notes', UseTakeMarkerNote)
        if ret then reaper.SetExtState(ExtStateName, 'TakeMarkNote', UseTakeMarkerNote) end
        reaper.ImGui_PopFont(ctx)
        
        local tagsList = {'@TAPE', '@PROJECT', '@SCENE', '@TAKE', '@prjTRACK', '@NOTE',
                          '@fieldRecTRACK', '@FILE', '@file.EXT', '@CurrentName'}
        
        table.sort(tagsList, function(a, b) return a:upper() < b:upper() end )
        
        local childflags = Flags.childAutoResizeY | Flags.childBorder
        local childTracks = reaper.ImGui_BeginChild(ctx, 'ChildTracks', 0, 0, childflags, Flags.menubar)
        if childTracks then 
          if reaper.ImGui_BeginMenuBar(ctx) then
            reaper.ImGui_Text(ctx, 'Copy tag to clipboard') 
            reaper.ImGui_EndMenuBar(ctx)
          end
          
          reaper.ImGui_PushFont(ctx, fontSep)
          
          maxWinW = reaper.ImGui_GetWindowWidth(ctx)
          local width = 0
          
          for t, tag in ipairs(tagsList) do
            if reaper.ImGui_SmallButton(ctx, tag) then
              reaper.ImGui_SetClipboardText(ctx, tag)
            end
            local w, h = reaper.ImGui_GetItemRectSize(ctx)
            local maxW = maxWinW - w*3
            if width > maxW and t ~= #tagsList then
              width = 0
            else
              reaper.ImGui_SameLine(ctx)
              width = width + w
            end
          end
          reaper.ImGui_PopFont(ctx)
          reaper.ImGui_EndChild(ctx)
        end
        
        reaper.ImGui_EndChild(ctx)
      end
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
    reaper.ImGui_PushItemWidth(ctx, fontSize*5.5)
    _, savedFontSize = reaper.ImGui_InputInt
    (ctx, 'Font size for the window (default is 17)', savedFontSize)
    
    reaper.ImGui_PopFont(ctx)
  end
  
  --------------
  function loop()
    PrjTimeOffset = -reaper.GetProjectTimeOffset( 0, false )
    
    if not font or savedFontSize ~= fontSize then
      if savedFontSize < 7 then savedFontSize = 7 end
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
      reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(), fontSize/4)
      reaper.ImGui_PushStyleVar(ctx, Flags.frameRounding, fontSize/4)
      reaper.ImGui_PushStyleVar(ctx, Flags.childRounding, fontSize/4)
      reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), fontSize/2, fontSize/4)
      
      local visible, open = reaper.ImGui_Begin(ctx, windowName, true, window_flags)
      reaper.ImGui_PopStyleColor(ctx, 1)
      
      if visible then
          maxWinW = reaper.ImGui_GetWindowWidth(ctx)
          frame()
          reaper.ImGui_SetWindowSize(ctx, 0, 0, nil ) 
          reaper.ImGui_End(ctx)
      end
      
      reaper.ImGui_PopStyleColor(ctx, 13)
      reaper.ImGui_PopStyleVar(ctx, 4)
      reaper.ImGui_PopFont(ctx) 
      
      if undo then reaper.Main_OnCommandEx(40029,0,0) end
      if redo then reaper.Main_OnCommandEx(40030,0,0) end
      
      --SetExtStates(OptTable)
      if open and not esc then
        reaper.defer(loop)
      else
        if SearchFolder and SearchFolder ~= '' then
          reaper.SetProjExtState(0, ExtStateName, 'SearchFolder', SearchFolder)
        end
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
  local edlsCnt = #EDLs
  
  for e, EDLfile in ipairs(EDLs) do
    local suffix = ''
    if edlsCnt > 1 then suffix = '_'..e end
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
            elseif v.Type == 'A3' then                    -- for Davinci Resolve
              table.insert(EdlTable.A3, copy(v))
              FieldMatch(EdlTable.A3.Splits,copy(v.DestIn), true)
              FieldMatch(EdlTable.A3.Splits,copy(v.DestOut), true)
            elseif v.Type and v.Type:match('A') then      -- for Davinci Resolve
              table.insert(EdlTable.A4, copy(v))
              FieldMatch(EdlTable.A4.Splits,copy(v.DestIn), true)
              FieldMatch(EdlTable.A4.Splits,copy(v.DestOut), true)
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
          CommonEDL.V['V'..suffix] = EdlTable.V
          table.insert(CommonEDL.V, 'V'..suffix)
        end
        
        if EDLcontentFlags & 1<<1 ~= 0 then
          CommonEDL.A['A1'..suffix] = EdlTable.A1
          table.insert(CommonEDL.A, 'A1'..suffix)
        end
        if EDLcontentFlags & 1<<2 ~= 0 then
          CommonEDL.A['A2'..suffix] = EdlTable.A2
          table.insert(CommonEDL.A, 'A2'..suffix)
        end
        if EDLcontentFlags & 1<<3 ~= 0 then
          CommonEDL.A['A3'..suffix] = EdlTable.A3
          table.insert(CommonEDL.A, 'A3'..suffix)
        end
        if EDLcontentFlags & 1<<4 ~= 0 then
          CommonEDL.A['A4'..suffix] = EdlTable.A4
          table.insert(CommonEDL.A, 'A4'..suffix)
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

function RenameTakes(SelItems, FormatString, NoteFormatString)
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock2(0)
  
  for t, TData in ipairs(SelItems) do
    for i, Item in ipairs(TData.Titems) do 
      local take = reaper.GetActiveTake(Item.item) 
      local patch, fn, ext = SplitFilename(Item.file)
      
      local activeChNames = ''
      for c, name in ipairs(Item.actChnNames) do
        local sep = ', '
        if c == #Item.actChnNames then sep = '' end
        activeChNames = activeChNames ..name..sep 
      end
      
      local function SubTags(str)
        str = str:gsub('@FILE', fn)
        str = str:gsub('@file.EXT', '.'..ext )
        str = str:gsub('@SCENE', Item.metaList.SCENE or '')
        str = str:gsub('@TAKE', Item.metaList.TAKE or '')
        str = str:gsub('@TAPE', Item.metaList.TAPE or '')
        str = str:gsub('@PROJECT', Item.metaList.PROJECT or '')
        str = str:gsub('@NOTE', Item.metaList.NOTE or '')
        str = str:gsub('@prjTRACK', TData.Tname)
        str = str:gsub('@CurrentName', Item.name) 
        str = str:gsub('@fieldRecTRACK', activeChNames)
        return str
      end
      
      local newTakeName = SubTags(FormatString)
      local newNote = SubTags(NoteFormatString)
      
      if newTakeName:gsub('^%s*(.-)%s*$', '%1') ~= '' then --remove spaces at edges
        reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', newTakeName, true )
        UndoString = 'Rename selected takes - post-prod tools'
      end
      
      if newNote:gsub('^%s*(.-)%s*$', '%1') ~= '' then --remove spaces at edges
        reaper.GetSetMediaItemInfo_String( Item.item, 'P_NOTES', newNote, true )
        if UseTakeMarkerNote == true then
          reaper.SetTakeMarker( take, -1, newNote, Item.offs + Item.len/2 )
        end
        UndoString = 'Rename selected takes - post-prod tools'
      end
       
    end
  end
  
  if UndoString then
    reaper.UpdateArrange()
    reaper.Undo_EndBlock2(0, UndoString, 1)
    UndoString = nil
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
        reaper.InsertTrackAtIndex(tIdx, true)
        local track = reaper.GetTrack(0, tIdx)
        local _,_ = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', name, true)
        --green for named mono tracks
        reaper.SetMediaTrackInfo_Value
        (track, 'I_CUSTOMCOLOR',
        reaper.ColorToNative( math.floor(30*2.55), math.floor(60*2.55), math.floor(30*2.55) )|0x1000000)
        
        Tracks[name] = track
        table.insert(NewTracks, track)
        tIdx = tIdx +1
      end
    end
    
    for i, Item in ipairs(TData.Titems) do
    --msg('\n'..Item.name)
    --match channel names with names in TrackList and
      for n, name in ipairs(Item.chnNames) do
        if FieldMatch(TrackList, name) == true and name:upper() ~= TData.Tname:upper() then
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
            
            --green for named mono tracks
            reaper.SetMediaTrackInfo_Value
            (track, 'I_CUSTOMCOLOR',
            reaper.ColorToNative( math.floor(30*2.55), math.floor(60*2.55), math.floor(30*2.55) )|0x1000000)
          elseif Tracks['ch_'..n] then
            track = Tracks['ch_'..n]
          end
          
          local validSrc = reaper.ValidatePtr2(0, Item.src, 'PCM_source*')
          
          if track and validSrc then
            if not UndoString then
              reaper.SelectAllMediaItems(0, false)
              UndoString = 'Expand multichannel items - Post-prod tools'
            end
            local newItem = reaper.AddMediaItemToTrack(track)
            reaper.SetMediaItemSelected(newItem, true)
            reaper.SetMediaItemInfo_Value(newItem, 'D_POSITION', Item.pos)
            reaper.SetMediaItemInfo_Value(newItem, 'D_LENGTH', Item.len)
            reaper.SetMediaItemInfo_Value(newItem, 'D_FADEINLEN', 0 )
            reaper.SetMediaItemInfo_Value(newItem, 'D_FADEOUTLEN', 0 )
            reaper.SetMediaItemInfo_Value(newItem, "D_VOL", Item.vol )
            
            reaper.SetMediaItemInfo_Value(newItem, 'D_FADEINLEN_AUTO', Item.fIn )
            reaper.SetMediaItemInfo_Value(newItem, 'D_FADEOUTLEN_AUTO', Item.fOut )
            
            local take = reaper.AddTakeToMediaItem(newItem) 
            reaper.SetMediaItemTake_Source( take, Item.src )
            reaper.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', Item.offs )
            reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', Item.name, true )
            
            reaper.SetMediaItemTakeInfo_Value( take, 'I_CHANMODE', ch )
            
            FieldMatch(ItemsToRemove, Item.item, true) 
          end
          
        end
      end --chnNames cycle
        
    end -- Track items cycle
    
    for i, item in ipairs(ItemsToRemove) do
      if reaper.ValidatePtr2( 0, item, 'MediaItem*' ) then reaper.DeleteTrackMediaItem(TData.Track, item) end 
    end
    
    if reaper.CountTrackMediaItems(TData.Track) == 0 then reaper.DeleteTrack(TData.Track) end
    
  end -- Tracks cycle
  
  for t, track in ipairs(NewTracks) do
    if reaper.CountTrackMediaItems(track) == 0 then reaper.DeleteTrack(track) end
  end
  
  if UndoString then
    reaper.UpdateArrange()
    reaper.Undo_EndBlock2(0, UndoString, 1)
    UndoString = nil
  elseif #SelItems > 0 then
    reaper.ShowMessageBox('All items are already on their tracks.\nOr there is no valid data - click Analyse again', 'Expand items', 0)
  end
  
end

-------------------------------

function GetSelItemsPerTrack(addMeta, addActiveChNames)
  local SI = {}
  local TrackList = {}
  local oldTrack
  
  for i=0, reaper.CountSelectedMediaItems(0) -1 do
    local TData = {Track, Tname, Titems={} }
    local Item = {}
    local item = reaper.GetSelectedMediaItem(0,i)
    local iTrack = reaper.GetMediaItemTrack(item)
    
    local take = reaper.GetActiveTake(item)
    local src = reaper.GetMediaItemTake_Source(take)
    
    if src then --is item in range
      Item.file = reaper.GetMediaSourceFileName( src )
      Item.src = src
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
      Item.actChnNames = {}
      --msg('\n'..Item.name)
      if addMeta then Item.metaList = save_metadata(src, TagsList) end
      
      if addActiveChNames then
        local chmode = reaper.GetMediaItemTakeInfo_Value( take, "I_CHANMODE" )
        local actChNumb
        local order = 1
        
        if chmode == 0 then
          actChNumb = Item.chnNumb
          chmode = 1
        elseif chmode == 1 or chmode > 66 then
          actChNumb = 2
          chmode = chmode - 66
        elseif chmode == 2 then
          actChNumb = 2
          order = -1
        else
          actChNumb = 1
          chmode = chmode - 2
        end
        
        for ch = 1, actChNumb do
          local chanTag = "IXML:TRACK_LIST:TRACK:NAME"
          if chmode ~= 1 then chanTag = chanTag..':'..string.format("%.0f", chmode) end 
          local ret, str = reaper.GetMediaFileMetadata(src, chanTag)
          if str == '' then str = 'ch '..string.format("%.0f", chmode) end
          table.insert(Item.actChnNames, str)
          chmode = chmode + 1*order
        end
        
      end
      
      
      for ch = 1, Item.chnNumb do
        local chanTag = "IXML:TRACK_LIST:TRACK:NAME"
        if ch ~= 1 then chanTag = chanTag..':'..ch end
        local ret, str = reaper.GetMediaFileMetadata(src, chanTag)
        str = str:upper()
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
        _, TData.Tname = reaper.GetSetMediaTrackInfo_String(iTrack, 'P_NAME', '', false)
        --[[
        if TData.Tname:gsub('^%s*(.-)%s*$', '%1') == '' then --remove spaces at edges
          TData.Tname = 'tr '.. string.format("%.0f", tostring(reaper.GetMediaTrackInfo_Value(iTrack, 'IP_TRACKNUMBER')) )
        end]]
        table.insert(TData.Titems, Item)
        table.insert(SI, TData)
      else
        table.insert(SI[#SI].Titems, Item )
      end
    end
  end
  
  for i, v in ipairs(TrackList) do --move checkbox No name to the first place
    if v == 'No name' then table.remove(TrackList, i) table.insert(TrackList, 1, v) end
  end
  
  return SI, TrackList
end

-------------------------------

function AddDopTracks(dopTRACKS)
  for i=1,2 do
    local trackT
    if i == 1 then trackT = dopTRACKS.Common else trackT = dopTRACKS.Named end
    local suffix = 1
    
    for t, tr in pairs(trackT) do
      local track
      
      reaper.InsertTrackInProject( 0, LastTrIdx, 1 )
      track = reaper.GetTrack(0, LastTrIdx)
      local _,_ = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', tr.name, true)
      
      if i == 1 then --yellow
        reaper.SetMediaTrackInfo_Value
        (track, 'I_CUSTOMCOLOR',
        reaper.ColorToNative( math.floor(70*2.55), math.floor(50*2.55), math.floor(20*2.55) )|0x1000000)
      else --green for named mono tracks
        reaper.SetMediaTrackInfo_Value
        (track, 'I_CUSTOMCOLOR',
        reaper.ColorToNative( math.floor(30*2.55), math.floor(60*2.55), math.floor(30*2.55) )|0x1000000)
      end
      
      LastTrIdx = LastTrIdx+1
      
      for it, itemData in ipairs(tr) do
        
        local newItem = reaper.AddMediaItemToTrack(track)
        table.insert(SuccessItems, newItem)
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
        
      end
      
    end
    
  end
end

-------------------------------

function LinkFiles(SelItems)
  local notMatchedItems = {}
  local NewTracks = {}
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock2(0)
  local list_files, list_file_metadata = GetAllFiles({SearchFolder})
  
  for t, TData in ipairs(SelItems) do
    local tIdx = reaper.GetMediaTrackInfo_Value( TData.Track, 'IP_TRACKNUMBER' )
    LastTrIdx = tIdx
    local Tracks = {}
    local dopTRACKS = { Named = {}, Common = {} }
    
    for i, Item in ipairs(TData.Titems) do
      local fadeInAuto
      local fadeOutAuto
      local itemMatch
      local matchCount = 1
      local recTrackNames = {}
       
      local _, tFname, tFext = SplitFilename(Item.file)
      if tFext then tFname = tFname:gsub('.'..tFext, '') end
      local takeFileNameMod = tFname:gsub('-','_'):gsub('+','__'):gsub('*','_ _'):upper()
      
      local takeNameMod = Item.name:gsub('-','_'):gsub('+','__'):gsub('*','_ _'):upper()
      
      local refPos = 0
      local refSplRate = reaper.GetMediaSourceSampleRate(Item.src)
      if Item.metaList.TC and SincByTC then refPos = tonumber(Item.metaList.TC)/refSplRate end
      
      for f, file in ipairs(list_files) do
        local match
        
        local _, fName, fExt = SplitFilename(file)
        --msg(fName)
        if fExt then fName = fName:gsub('.'..fExt, '') end
        local fNameMod = fName:gsub('-','_'):gsub('+','__'):gsub('*','_ _'):upper()
        
        local fileMetaList = list_file_metadata[file]
        
        for i, v in ipairs(TagsList) do
          if v[1] ~= '' and v[2] ~= 'TC' and v[3] == true then
            if Item.metaList and fileMetaList and Item.metaList[v[2]] and fileMetaList[v[2]] then
              
              if fileMetaList[v[2]]:match(Item.metaList[v[2]])
              --Item metadata can be shorter than in original file if exists only in BWF desription,
              --but not vice verca to avoid extra match in cases like S_02 - S_02A
              then match = true
              else
                match = false
                break
              end
              
            end
          end
        end
        --msg(match)
        if match ~= false and MatchTakeFileName == true then
          if string.upper(fExt) == 'WAV'
          or string.upper(fExt) == 'AIF'
          or string.upper(fExt) == 'FLAC'
          or string.upper(fExt) == 'MP3'
          or string.upper(fExt) == 'MPA'
          or string.upper(fExt) == 'WMA' then
          
            if fNameMod:match(takeFileNameMod)
            or takeFileNameMod:match(fNameMod)
            or fName:match(takeNameMod)
            or takeNameMod:match(fNameMod) then
              match = true
            end
            
          end 
        end
        
        
        if (match or (match == nil and LinkOnlyByTC)) then
          local newSrc = reaper.PCM_Source_CreateFromFile( file )
          if newSrc then
            local srcLen, isQN = reaper.GetMediaSourceLength(newSrc)
            local splRate = reaper.GetMediaSourceSampleRate(newSrc)
            
            if isQN == false then
              local fileTC = 0
              if fileMetaList and fileMetaList.TC and fileMetaList.TC ~= '' and SincByTC then 
                fileTC = tonumber(fileMetaList.TC)/splRate
              end
              
              local offset = refPos - fileTC + Item.offs 
              
              if offset + Item.len <= srcLen and fileTC < refPos + Item.offs + Item.len
              or SincByTC ~= true then
                match, itemMatch = true, true
                if not UndoString then
                  reaper.SelectAllMediaItems(0, false)
                  UndoString = 'Link files to selected items'
                end
                
                if AddNewTrks == true then
                  local trName = fileMetaList.TRACKNAME
                  local chCnt = reaper.GetMediaSourceNumChannels(newSrc)
                  local itemData = {
                              pos = Item.pos,
                              length = Item.len,
                              fadeIn = Item.fIn,
                              fadeOut = Item.fOut,
                              offset = offset,
                              src = newSrc,
                              name = fName..'.'..fExt
                              }
                  
                  if chCnt == 1 and trName ~= ''
                  and trName:upper() ~= TData.Tname:upper() then
                    if not recTrackNames[trName] then recTrackNames[trName] = {} end
                    local adress = trName
                    if #recTrackNames[trName] > 0 then
                      adress = adress..'_'.. tostring(#recTrackNames[trName] +1)
                    end
                    if not dopTRACKS.Named[adress] then dopTRACKS.Named[adress] = {} end
                    dopTRACKS.Named[adress]['name'] = adress
                    table.insert(dopTRACKS.Named[adress], itemData)
                    table.insert(recTrackNames[trName], 1) --paste any data, we need just table size
                  elseif chCnt ~= 1 or trName == '' then
                    local suffix = ''
                    if matchCount > 1 then suffix = '_'..matchCount end
                    if not dopTRACKS.Common[matchCount] then dopTRACKS.Common[matchCount] = {} end
                    dopTRACKS.Common[matchCount]['name'] = TData.Tname..suffix
                    table.insert(dopTRACKS.Common[matchCount], itemData)
                    matchCount = matchCount +1
                  end
                  
                elseif Item.file ~= file then
                  FieldMatch(SuccessItems, Item.item, true)
                  local take = reaper.AddTakeToMediaItem(Item.item)
                  reaper.SetActiveTake(take)
                  reaper.SetMediaItemTake_Source( take, newSrc )
                  reaper.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', offset )
                  local _, _ = reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', fName..'.'..fExt, true )
                end
              else match = false
              end
            end
            
            if match ~= true then
              reaper.PCM_Source_Destroy(newSrc)
            end
          end
        end --if match or LinkOnlyByTC
        
      end --for file cycle
      
      if itemMatch ~= true then
        table.insert(notMatchedItems, {Item.pos, Item.name, TData.Tname} )
        reaper.SetMediaItemSelected(Item.item, true)
      end
    end --Per sel Item cycle
    --[[
    for i, item in ipairs(ItemsToRemove) do
      if reaper.ValidatePtr2( 0, item, 'MediaItem*' ) then reaper.DeleteTrackMediaItem(TData.Track, item) end 
    end]]
    
    AddDopTracks(dopTRACKS)
  end --Per track with sel items cycle
  
  for t, track in ipairs(NewTracks) do
    if reaper.CountTrackMediaItems(track) == 0 then reaper.DeleteTrack(track) end
  end
  
  if UndoString then
    reaper.UpdateArrange()
    reaper.Undo_EndBlock2(0, UndoString, 1)
    UndoString = nil
  end
  
  return notMatchedItems 
end

-------------------------------

function CreateTracks(EdlsTable)
  local notMatchedItems = {}
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
        --yellow
        reaper.SetMediaTrackInfo_Value
        (track, 'I_CUSTOMCOLOR',
        reaper.ColorToNative( math.floor(70*2.55), math.floor(50*2.55), math.floor(20*2.55) )|0x1000000)
        
        if not UndoString then
          UndoString = 'Import tracks and media from EDl'
          reaper.SelectAllMediaItems(0, false)
        end
      end
      
      local crossfade
      local maxidx = #trackT
      for i, item in ipairs(trackT) do
        --Create item
        local newItem = reaper.AddMediaItemToTrack(track)
        local fadeInAuto
        local fadeOutAuto
        local match
        local matchCount = 1
        local recTrackNames = {}
         
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
          --local clipEnd = item.Clips[1]['SrcOut']
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
                    if metadataList and metadataList.TC and metadataList.TC ~= '' then 
                      fileTC = tonumber(metadataList.TC)/splRate
                    end
                    
                    local offset = clipStart - fileTC
                    
                    if offset >= 0 and offset + (item.DestOut - item.DestIn) <= srcLen then
                      match, filematch = true, true
                      
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
                      
                      if reaper.GetMediaSourceNumChannels(newSrc) == 1 and trName ~= ''
                      and AddNewTrks == true then
                        if not recTrackNames[trName] then recTrackNames[trName] = {} end
                        local adress = trName
                        if #recTrackNames[trName] > 0 then
                          adress = adress..'_'.. tostring(#recTrackNames[trName] +1)
                        end
                        if not dopTRACKS.Named[adress] then dopTRACKS.Named[adress] = {} end
                        dopTRACKS.Named[adress]['name'] = adress
                        table.insert(dopTRACKS.Named[adress], itemData)
                        table.insert(recTrackNames[trName], 1) --paste any data, we need just table size
                      elseif AddNewTrks == true and matchCount > 1 then
                        if not dopTRACKS.Common[matchCount-1] then dopTRACKS.Common[matchCount-1] = {} end
                        dopTRACKS.Common[matchCount-1]['name'] = edlTname..'_'..matchCount
                        table.insert(dopTRACKS.Common[matchCount-1], itemData)
                        matchCount = matchCount +1
                      else
                        FieldMatch(SuccessItems, newItem, true)
                        local take = reaper.AddTakeToMediaItem(newItem) 
                        reaper.SetMediaItemTake_Source( take, newSrc )
                        reaper.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', offset )
                        local _, _ = reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', clipFileName, true )
                      end
                      
                    else match = false
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
            table.insert(notMatchedItems, {item.DestIn, clipName, edlTname} )
          end
          
        else --if track is Video one
          local _,_ = reaper.GetSetMediaItemInfo_String(newItem, 'P_NOTES', item.Clips[1]['name'], true)
        end
        
      end -- for item/clip cycle
      
      AddDopTracks(dopTRACKS)
      
    end  
  end

  if UndoString then
    reaper.UpdateArrange()
    reaper.Undo_EndBlock2(0, UndoString, 1)
    UndoString = nil
  end 

  return notMatchedItems
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
  
  ---THE LAST TAG (if several tags applied) has the higer priority!---
  local text = ''
  table.insert(TagsList, {text, 'TC', true, {"VORBIS:TIME_REFERENCE", "BWF:TimeReference"} })
  local text = 'Project'
  table.insert(TagsList, {text, 'PROJECT', false, {"IXML:PROJECT", ''} })
  local text = 'Date'
  table.insert(TagsList, {text, 'DATE', false, {"IXML:BEXT:BWF_ORIGINATION_DATE", "BWF:OriginationDate"} })
  local text = 'Tape'
  table.insert(TagsList, {text, 'TAPE', true, {"IXML:TAPE", ''} })
  local text = 'Scene'
  table.insert(TagsList, {text, 'SCENE', true, {"IXML:SCENE", ''} })
  local text = 'Take'
  table.insert(TagsList, {text, 'TAKE', true, {"IXML:TAKE", ''} })
  
  local text = ''
  table.insert(TagsList, {text, 'TRACKCOUNT', false, {"IXML:TRACK_LIST:TRACK_COUNT", ''} })
   
  local text = ''
  table.insert(TagsList, {text, 'TRACKNAME', false, {"IXML:TRACK_LIST:TRACK:NAME", ''} })

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

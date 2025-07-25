-- @noindex

function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end

ExtStateName = 'ConformTools_AZ'

TrClrs = {}
TrClrs.yellow = reaper.ColorToNative( math.floor(70*2.55), math.floor(50*2.55), math.floor(20*2.55) )
TrClrs.blue = reaper.ColorToNative( math.floor(10*2.55), math.floor(15*2.55), math.floor(40*2.55) )
TrClrs.green = reaper.ColorToNative( math.floor(30*2.55), math.floor(60*2.55), math.floor(30*2.55) )

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


  gui_colors = {
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
  
  if not reaper.APIExists( 'SNM_GetIntConfigVar' ) then
    reaper.ShowMessageBox('Please, install SWS extension!', 'No SWS extension', 0)
    return
  end
  
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
  
  AudToVid = ValToBool( reaper.GetExtState(ExtStateName, 'AudToVid') )
  if AudToVid == nil then AudToVid = false end
  
  MatchTakeFileName = ValToBool( reaper.GetExtState(ExtStateName, 'MatchTakeFileName') )
  if MatchTakeFileName == nil then MatchTakeFileName = true end
  
  FlexLink = ValToBool( reaper.GetExtState(ExtStateName, 'FlexLink') )
  if FlexLink == nil then FlexLink = true end
  
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
        
        reaper.ImGui_SameLine(ctx, nil, fontSize*1.5)
        reaper.ImGui_Text(ctx, 'Set known project framerate')
        reaper.ImGui_SameLine(ctx)
        --reaper.ImGui_PushItemWidth(ctx, fontSize*10.3 )
        local comboflags = reaper.ImGui_ComboFlags_WidthFitPreview() --| reaper.ImGui_ComboFlags_PopupAlignLeft()
        
        if reaper.ImGui_BeginCombo(ctx, '##-1', PrFrRate, comboflags ) then
          local frameRates = {'23.976', '24', '25', '29.97DF', '29.97ND', '30', '48', '50', '60', '75'}
          local choice
          for k,f in ipairs(frameRates) do
            local is_selected = choice == k
            if reaper.ImGui_Selectable(ctx, frameRates[k], is_selected) then
              choice = k
              --Set Prj Frame Rate
              PrFrRate = frameRates[k]
              
              if PrFrRate == '29.97DF' then PrFrRate = 30 PrDropFrame = 1
              elseif PrFrRate == '29.97ND' then PrFrRate = 30 PrDropFrame = 2
              elseif PrFrRate == '23.976' then PrFrRate = 24 PrDropFrame = 2
              else PrFrRate = tonumber(PrFrRate) PrDropFrame = 0
              end
              
              reaper.SNM_SetIntConfigVar( 'projfrbase', PrFrRate )
              reaper.SNM_SetIntConfigVar( 'projfrdrop', PrDropFrame )
              
            end
        
            -- Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
            if is_selected then
              reaper.ImGui_SetItemDefaultFocus(ctx)
            end
          end
          reaper.ImGui_EndCombo(ctx)
        end
        
        
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
        
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_PushFont(ctx, fontSep)
        reaper.ImGui_Text(ctx, 'Note: EDL must be CMX 3600')
        reaper.ImGui_PopFont(ctx)
        
        showEDLsNames(EDL)
         
        --Source tracks
        local childflags = Flags.childAutoResizeY | Flags.childBorder
        local childImportSettings = reaper.ImGui_BeginChild(ctx, 'ChildImportSettings', fontSize*33, 0, childflags, Flags.menubar)
        
        if childImportSettings then
          
          if reaper.ImGui_BeginMenuBar(ctx) then
            reaper.ImGui_Text(ctx, 'Import settings:')
            reaper.ImGui_EndMenuBar(ctx)
          end
           
          reaper.ImGui_PushFont(ctx, fontSep)
          
          local choiceSrc, change, changeSrc
          change, choiceSrc = reaper.ImGui_Checkbox(ctx, 'Video track', EDLcontentFlags & 1)
          if change then EDLcontentFlags = EDLcontentFlags ~1 changeSrc = true end
          
          reaper.ImGui_SameLine(ctx, nil, fontSize)
          change, choiceSrc = reaper.ImGui_Checkbox(ctx, 'Audio 1', (EDLcontentFlags>>1) & 1)
          if change then EDLcontentFlags = EDLcontentFlags  ~ (1<<1) changeSrc = true end
          
          reaper.ImGui_SameLine(ctx, nil, fontSize)
          change, choiceSrc = reaper.ImGui_Checkbox(ctx, 'Audio 2', (EDLcontentFlags>>2) & 1)
          if change then EDLcontentFlags = EDLcontentFlags  ~ (1<<2) changeSrc = true end
          
          reaper.ImGui_SameLine(ctx, nil, fontSize)
          change, choiceSrc = reaper.ImGui_Checkbox(ctx, 'Audio 3', (EDLcontentFlags>>3) & 1)
          if change then EDLcontentFlags = EDLcontentFlags  ~ (1<<3) changeSrc = true end
          
          reaper.ImGui_SameLine(ctx, nil, fontSize)
          change, choiceSrc = reaper.ImGui_Checkbox(ctx, 'Audio 4 + others', (EDLcontentFlags>>4) & 1)
          if change then EDLcontentFlags = EDLcontentFlags  ~ (1<<4) changeSrc = true end
          
          if changeSrc == true then
            reaper.SetExtState(ExtStateName, 'ContentAnalyse', EDLcontentFlags, true)
          end
           
          ret, AudToVid = reaper.ImGui_Checkbox(ctx, 'Create Audio track linked to Video timecode', AudToVid)
          if ret then reaper.SetExtState(ExtStateName, 'AudToVid', tostring(AudToVid), true) end
          
          reaper.ImGui_NewLine(ctx)
          
          ret, FlexLink = reaper.ImGui_Checkbox(ctx, '2nd attempt to link source by name, 3rd by timecode only', FlexLink)
          if ret then reaper.SetExtState(ExtStateName, 'FlexLink', tostring(FlexLink), true) end
          
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
              local notMatchedItems, message = CreateTracks(EdlsTable)
              if message then reaper.ShowMessageBox( message, 'Caution!', 0) end
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
            reaper.ImGui_Text(ctx, ' Metadata fields ')
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
        local wSize = maxWinW - w - fontSize*2
        local childDop = reaper.ImGui_BeginChild(ctx, 'ChildDop', 0, 0, childflags) --, Flags.menubar)
        if childDop then
          local ret
          ret, MatchTakeFileName = reaper.ImGui_Checkbox(ctx, 'Match take and file names', MatchTakeFileName)
          if ret then reaper.SetExtState(ExtStateName, 'MatchTakeFileName', tostring(MatchTakeFileName), true) end
          
          reaper.ImGui_PushFont(ctx, fontSep)
          reaper.ImGui_NewLine(ctx)
          
          ret, FlexLink = reaper.ImGui_Checkbox(ctx, '2nd attempt to link by name, 3rd by timecode only', FlexLink)
          if ret then reaper.SetExtState(ExtStateName, 'FlexLink', tostring(FlexLink), true) end
          
          if LinkOnlyByTC == true then SincByTC = true end 
          ret, SincByTC = reaper.ImGui_Checkbox(ctx, 'Sync source by timecode', SincByTC)
          if ret then reaper.SetExtState(ExtStateName, 'SincByTC', tostring(SincByTC), true) end
           
          reaper.ImGui_NewLine(ctx) reaper.ImGui_SameLine(ctx, fontSize*1.5)
          
          if SincByTC == false then LinkOnlyByTC = false end
          ret, LinkOnlyByTC = reaper.ImGui_Checkbox(ctx, 'Link each file by timecode only if metadata is empty', LinkOnlyByTC)
          if ret then reaper.SetExtState(ExtStateName, 'LinkOnlyByTC', tostring(LinkOnlyByTC), true) end
          
          reaper.ImGui_NewLine(ctx)
          
          reaper.ImGui_PopFont(ctx)
          
          
          local itemsCnt = reaper.CountSelectedMediaItems(0)
          if itemsCnt > 0 and SearchFolder and SearchFolder ~= '' then
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.MainButton.Default)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), gui_colors.MainButton.Hovered)
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), gui_colors.MainButton.Active)
          end
          
          if reaper.ImGui_Button(ctx, '    Link files    ') then
            local selItems, _ = GetSelItemsPerTrack(true, false) 
            local notMatchedItems = {}
            local message
            
            if itemsCnt > 0 and SearchFolder and SearchFolder ~= '' then
              notMatchedItems, message = LinkFiles(selItems)
            end
            if message then reaper.ShowMessageBox( message, 'Caution!', 0) end
            if #notMatchedItems > 0 then
              msg(#notMatchedItems..' ITEMS HAVE NO MATCH!\nThey are selected\n')
              for i, item in ipairs(notMatchedItems) do
                msg('Track '..item[3]..'  '..reaper.format_timestr_pos(item[1],'',5)..'  '..item[2])
                reaper.SetMediaItemSelected(item[4], true)
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
      
      local childflags = Flags.childBorder
      local childR = reaper.ImGui_BeginChild(ctx, 'ChildR', 0, Hsize, childflags, Flags.menubar)
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
        ret, UseTakeMarkerNote = reaper.ImGui_Checkbox(ctx, 'Use take markers in addition to item notes', UseTakeMarkerNote)
        if ret then reaper.SetExtState(ExtStateName, 'TakeMarkNote', UseTakeMarkerNote) end
        reaper.ImGui_PopFont(ctx)
        
        local tagsList = {'@TAPE', '@PROJECT', '@SCENE', '@TAKE', '@prjTRACK', '@NOTE',
                          '@fieldRecTRACK', '@FILE', '@file.EXT', '@CurrentName'}
        
        table.sort(tagsList, function(a, b) return a:upper() < b:upper() end )
        
        maxWinW = reaper.ImGui_GetWindowWidth(ctx)
        
        local childflags = Flags.childAutoResizeY | Flags.childAutoResizeX | Flags.childBorder
        local childTracks = reaper.ImGui_BeginChild(ctx, 'ChildTracks', 0, 0, childflags, Flags.menubar)
        if childTracks then
          if reaper.ImGui_BeginMenuBar(ctx) then
            reaper.ImGui_Text(ctx, 'Copy tag to clipboard')
            reaper.ImGui_EndMenuBar(ctx)
          end
          
          reaper.ImGui_PushFont(ctx, fontSep)
           
          local width = 0
          
          for t, tag in ipairs(tagsList) do
            if reaper.ImGui_SmallButton(ctx, tag) then
              reaper.ImGui_SetClipboardText(ctx, tag)
            end
            local w, h = reaper.ImGui_GetItemRectSize(ctx)
            local maxW = maxWinW - w*2.9
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
    
    MIN_luft_ZERO = ( reaper.parse_timestr_pos('00:00:00:01', 5) - PrjTimeOffset ) / 4
    
    PrFrRate = reaper.SNM_GetIntConfigVar( 'projfrbase', -1 )
    PrDropFrame = reaper.SNM_GetIntConfigVar( 'projfrdrop', -1 )
    
    if PrFrRate == 30 and PrDropFrame == 1 then PrFrRate = '29.97DF'
    elseif PrFrRate == 30 and PrDropFrame == 2 then PrFrRate = '29.97ND'
    elseif PrFrRate == 24 and PrDropFrame == 2 then PrFrRate = '23.976'
    end
    
    if not font or savedFontSize ~= fontSize then
      if savedFontSize < 7 then savedFontSize = 7 end
      if savedFontSize > 60 then savedFontSize = 60 end
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
          
          if UndoString then
            reaper.UpdateArrange()
            reaper.Undo_EndBlock2(0, UndoString, 1)
            UndoString = nil
          end
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
    local EDLtext = {}
    local EDLblocks = {}
    local prevBlockNumber, curBlockNumber = 0, 0
    local itemsList = {}
    local block
    
    for line in io.lines(EDLfile) do
      line = line:gsub('^%s*(.-)%s*$', '%1') --remove spaces at edges
      table.insert(EDLtext, line )
    end
     
    for l, line in ipairs(EDLtext) do
      --msg('\n  LINE:   '..line)
      local lineData = {blockN, strParts={}, Time={}, fadeLen, transition, track, strRest}
      local pattern = '%d%d:%d%d:%d%d:%d%d' 
      
      for time in line:gmatch(pattern) do
        table.insert(lineData.Time, time)
      end 
      
      for t, time in ipairs(lineData.Time) do
        line = line:gsub(time, '')
      end
      
      for s in line:gmatch('%S+') do
        table.insert(lineData.strParts, s)
      end
      
      if #lineData.strParts >= 3 and lineData.strParts[1]:match('%d+') then
        lineData.blockN = lineData.strParts[1]
      end
      
      if #lineData.Time == 4 and #lineData.strParts >= 4 then
      
        if lineData.strParts[#lineData.strParts]:match('%d+') then
          lineData.fadeLen = tonumber(lineData.strParts[#lineData.strParts])
          table.remove(lineData.strParts, #lineData.strParts)
        end
        
        local shift = 1
        if lineData.strParts[#lineData.strParts]:match('F') then
          shift = 3
          lineData.transition = 'KBF'
        elseif lineData.strParts[#lineData.strParts] == 'O'
        or lineData.strParts[#lineData.strParts] == 'B' then
          shift = 2
          lineData.transition = lineData.strParts[#lineData.strParts -1] .. lineData.strParts[#lineData.strParts]
        else
          lineData.transition = lineData.strParts[#lineData.strParts]
        end
         
        lineData.track = lineData.strParts[#lineData.strParts - shift]
        
        if lineData.strParts[1]:match('%d+') then
          curBlockNumber = tonumber( lineData.strParts[1]:match('%d+') )
          lineData.blockN = curBlockNumber
        end
        
      end
      
      lineData.strRest = line
      
      if curBlockNumber ~= prevBlockNumber then
        prevBlockNumber = curBlockNumber
        if block and #block.main > 0 then
          table.insert(EDLblocks, copy(block) )
          block = nil
        end
        if not block then block = { numb, main={}, motion={}, notes={} } end
      end
       
       
      if block then
        block.numb = curBlockNumber
        if #lineData.Time == 4 then table.insert(block.main, lineData)
        elseif #lineData.Time == 1 and lineData.blockN == 'M2' then
          table.insert(block.motion, lineData)
        elseif #lineData.Time == 4 then table.insert(block.main, lineData)
        elseif line:match("CLIP NAME:") or line:match("AUD ") then table.insert(block.notes, line)
        end
      end
      
      if l == #EDLtext and #block.main > 0 then
        table.insert(EDLblocks, copy(block) )
      end
    end
    
    
    for b, block in ipairs(EDLblocks) do
      local item = {Type, Type2, fadeIn, fadeOut, Clips={}, DestIn, DestOut} 
      local clip = { name, SrcIn, SrcOut, PlayRate, RateTC }
      
      if #block.main == 1 then
        for n, noteline in ipairs(block.notes) do
          if noteline:match("CLIP NAME:") then
            local nameT = {}
            for s in noteline:gmatch('[^:]+') do
              s = s:gsub('^%s*(.-)%s*$', '%1') --remove spaces at edges
              table.insert(nameT, s)
            end 
            clip.name = nameT[2]
          elseif noteline:match("AUD ") then
            item.Type2 = noteline:gsub("AUD", ''):gsub("%s+", '')
          end
        end
        if not clip.name or clip.name == 'BL' or clip.name == '' then
          clip.name = '::BLACK::'
        end
        clip.SrcIn = block.main[1]['Time'][1]
        clip.SrcOut = block.main[1]['Time'][2] 
        item.DestIn = block.main[1]['Time'][3]
        item.DestOut = block.main[1]['Time'][4]
        
        clip.SrcIn = reaper.parse_timestr_pos( clip.SrcIn, 5 ) - PrjTimeOffset
        clip.SrcOut = reaper.parse_timestr_pos( clip.SrcOut, 5 ) - PrjTimeOffset
        item.DestIn = reaper.parse_timestr_pos( item.DestIn, 5 ) - timeTreshold -- - PrjTimeOffset
        item.DestOut = reaper.parse_timestr_pos( item.DestOut, 5 ) - timeTreshold -- - PrjTimeOffset
        
        item.Type = block.main[1]['track']
        table.insert(item.Clips, copy(clip) )
        table.insert(itemsList, copy(item) )
        item.Clips = {}
      else
        local itemsCnt = #block.main
        local fadelen
        local transition
        if itemsCnt > 0 then
          fadelen = block.main[itemsCnt]['fadeLen']
          transition = block.main[itemsCnt]['transition']
        end
        
        if fadelen then
          fadelen = reaper.parse_timestr_pos( '00:00:00:'..fadelen, 5 ) - PrjTimeOffset
        end
        
        for i = 1, itemsCnt do
        
          if i == itemsCnt then --Get last name and AUD numbers 
            for n, noteline in ipairs(block.notes) do
              if noteline:match("CLIP NAME:") then
                local nameT = {}
                for s in noteline:gmatch('[^:]+') do
                  s = s:gsub('^%s*(.-)%s*$', '%1') --remove spaces at edges
                  table.insert(nameT, s)
                end 
                clip.name = nameT[2] 
              elseif noteline:match("AUD ") then
                item.Type2 = noteline:gsub("AUD", ''):gsub("%s+", '')
              end
            end
            if not clip.name or clip.name == 'BL' or clip.name == '' or #block.notes == 0 then
              clip.name = '::BLACK::'
            end
          else --Get first name and AUD numbers 
            local n = #block.notes
            while n > 0 do
              local noteline = block.notes[n]
              if noteline:match("CLIP NAME:") then
                local nameT = {}
                for s in noteline:gmatch('[^:]+') do
                  s = s:gsub('^%s*(.-)%s*$', '%1') --remove spaces at edges
                  table.insert(nameT, s)
                end
                clip.name = nameT[2] 
              elseif noteline:match("AUD ") then
                item.Type2 = noteline:gsub("AUD", ''):gsub("%s+", '')
              end 
              n=n-1
            end
            if not clip.name or clip.name == 'BL' or clip.name == '' or #block.notes == 0 then
              clip.name = '::BLACK::'
            end
            
          end
          
          clip.SrcIn = block.main[i]['Time'][1]
          clip.SrcOut = block.main[i]['Time'][2]
          item.DestIn = block.main[i]['Time'][3]
          item.DestOut = block.main[i]['Time'][4]
          
          clip.SrcIn = reaper.parse_timestr_pos( clip.SrcIn, 5 ) - PrjTimeOffset
          clip.SrcOut = reaper.parse_timestr_pos( clip.SrcOut, 5 ) - PrjTimeOffset
          item.DestIn = reaper.parse_timestr_pos( item.DestIn, 5 ) - timeTreshold --  - PrjTimeOffset
          item.DestOut = reaper.parse_timestr_pos( item.DestOut, 5 ) - timeTreshold -- - PrjTimeOffset
          
          item.Type = block.main[i]['track']
           
          if ( transition:match('D') or transition:match('W') )
          and fadelen and i ~= itemsCnt then
            clip.SrcOut = clip.SrcOut + fadelen
            item.DestOut = item.DestOut + fadelen
          end
          
          if transition:match('K') and fadelen and i == itemsCnt then
            if item.DestIn == item.DestOut then 
              item.DestOut = itemsList[#itemsList]['DestOut']
              clip.SrcOut = clip.SrcIn + (item.DestOut - item.DestIn)
            else
              item.DestOut = item.DestOut + fadelen
              clip.SrcOut = clip.SrcOut + fadelen
            end
          end
          
          if transition:match('K') and transition:match('O')
          and fadelen and i == itemsCnt
          and block.main[i]['Time'][3] == block.main[i]['Time'][4] then
            item.DestOut = item.DestIn + fadelen
            clip.SrcOut = clip.SrcIn + fadelen
          end
          
          table.insert(item.Clips, copy(clip) )
          table.insert(itemsList, copy(item) )
          item.Clips = {}
          
        end
      end
    
    end
    
    for i, v in ipairs(itemsList) do
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
      elseif v.Type == 'A4' then                    -- for Davinci Resolve
        table.insert(EdlTable.A4, copy(v))
        FieldMatch(EdlTable.A4.Splits,copy(v.DestIn), true)
        FieldMatch(EdlTable.A4.Splits,copy(v.DestOut), true) 
      elseif v.Type and v.Type:match('A') then      -- for Davinci Resolve
        if not EdlTable[v.Type] then EdlTable[v.Type] = { Splits = {} } end
        table.insert(EdlTable[v.Type], copy(v))
        FieldMatch(EdlTable[v.Type]['Splits'],copy(v.DestIn), true)
        FieldMatch(EdlTable[v.Type]['Splits'],copy(v.DestOut), true)
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
    ------------
    
    --Remove Fades in All items
    for name, track in pairs(EdlTable) do
      for i, item in ipairs(track) do
        local c = #item.Clips 
        while c > 0 do
          local clip = item.Clips[c] 
          if not clip.name or clip.name:match('::BLACK::') then
            if clip.name and clip.name:match('::BLACK::') and c == 1 then
              item.fIn = item.DestOut - item.DestIn
            elseif clip.name and clip.name:match('::BLACK::') and c == 2 then
              item.fOut = item.DestOut - item.DestIn
            end
            table.remove(item.Clips, c)
          end
          
          c = c-1
        end
        
      end
    end
    
    --Remove items with no Clips
    for name, track in pairs(EdlTable) do
      local i = #track
      while i > 0 do
        local item = track[i]
        if #item.Clips == 0 then table.remove(track, i) end
        i = i-1 
      end
    end
    
    
    for key, v in pairs(EdlTable) do
      if v[1] then
        local keyNumb = tonumber(key:match('%d+'))
        if key == 'V' and EDLcontentFlags & 1 ~= 0 then
          CommonEDL.V['V'..suffix] = EdlTable.V
          table.insert(CommonEDL.V, 'V'..suffix)
        elseif keyNumb < 4 then
          if EDLcontentFlags & 1 << keyNumb ~= 0 then
            CommonEDL.A[key..suffix] = EdlTable[key]
            CommonEDL.A[keyNumb] = key..suffix
          end
        elseif EDLcontentFlags & 1<<4 ~= 0 then
          CommonEDL.A[key..suffix] = EdlTable[key]
          CommonEDL.A[keyNumb] = key..suffix
        end
      end
    end
    
  end --end of edl files cycle
  
  return CommonEDL
end

-------------------------------
function SplitFilename(strFilename) -- Path, Filename, Extension
  if type(strFilename) ~= 'string' then return nil end
  return string.match(strFilename, "(.-)([^\\]-([^\\%.]+))$")
end
-------------------------------

function CleanUpEDLs(EdlsTable)
  
  local trackType = {'V','A'}
  
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
  
  --Finally remove excess splits in items
  for k, trType in ipairs(trackType) do
    for e, edlTname in ipairs(EdlsTable[trType]) do
      local trackT = EdlsTable[trType][edlTname]
      
      i = #trackT
      while i > 1 do
        local item = trackT[i]
        local clipName = item.Clips[1]['name']
        
        if trackT[i-1]['Clips'] [#trackT[i-1]['Clips']] ['name'] == clipName
        and math.abs(item.DestIn - trackT[i-1]['DestOut']) < MIN_luft_ZERO
        and math.abs( trackT[i-1]['Clips'] [#trackT[i-1]['Clips']] ['SrcOut'] - item.Clips[1]['SrcIn'] ) < MIN_luft_ZERO then
          trackT[i-1]['DestOut'] = item.DestOut
          trackT[i-1]['Clips'][#trackT[i-1]['Clips']]['SrcOut'] = item.Clips[1]['SrcOut']
          table.remove(trackT, i)
        end
        i = i-1
      end
      
    end
  end
  
  ---Move overlapped items on a free track
  local function moveOverlappedItems()
    local result
  for k, trType in ipairs(trackType) do
    
    for e, edlTname in ipairs(EdlsTable[trType]) do
      local trackT = EdlsTable[trType][edlTname]
      local itemsForDel = {}
      local prevItem = { DestIn = -1, DestOut = 0 }
      
      table.sort(trackT, function(a,b) return a.DestIn < b.DestIn end)
      
      for i, item in ipairs(trackT) do
        local move, moveIdx
        local trackMoveTo
        local nextItemDestIn = item.DestOut
        
        if i < #trackT then nextItemDestIn = trackT[i+1]['DestIn'] end
        
        if ( item.DestIn >= prevItem.DestIn and item.DestOut <= prevItem.DestOut )
        or ( item.DestIn <= prevItem.DestIn and item.DestOut >= prevItem.DestOut )
        or ( math.abs(prevItem.DestOut - nextItemDestIn) < MIN_luft_ZERO ) then
          
          for ed, edlTrName in ipairs(EdlsTable[trType]) do
            if edlTrName ~= edlTname then
              trackMoveTo = EdlsTable[trType][edlTrName] 
              local prevDestOut = 0
              for it, otherItem in ipairs(trackMoveTo) do
                if item.DestIn >= prevDestOut and item.DestOut <= otherItem.DestIn then
                  move = true
                  moveIdx = it
                  break
                end
                prevDestOut = otherItem.DestOut 
              end
              if move then break end
            end
          end
          
        end
        
        if not move then
          prevItem.DestIn = item.DestIn
          prevItem.DestOut = item.DestOut
        else
          table.insert(trackMoveTo, moveIdx, item)
          FieldMatch(itemsForDel, i, true) 
        end
        
      end
      
      table.sort(itemsForDel, function(a,b) return (a>b) end)
      for i, idx in ipairs(itemsForDel) do
        table.remove(trackT, idx)
        result = true
      end
      
      
    end
  end
  return result
  end --function
  
  local done = true
  while done do
    done = moveOverlappedItems()
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
        reaper.SetMediaTrackInfo_Value(track, 'I_CUSTOMCOLOR', TrClrs.green | 0x1000000)
        
        Tracks[name] = track
        table.insert(NewTracks, track)
        tIdx = tIdx +1
      end
    end
    
    for i, Item in ipairs(TData.Titems) do
      local matchedNames = {}
    --msg('\n'..Item.name)
    --match channel names with names in TrackList and
      for n, name in ipairs(Item.chnNames) do
        if FieldMatch(TrackList, name) == true and name:upper() ~= TData.Tname:upper() then 
          local ch = n +2
          local track
          
          if name == 'No name' and not Tracks['ch_'..n] and TrackList['No name'] == true then
            reaper.InsertTrackAtIndex(tIdx, true)
            track = reaper.GetTrack(0, tIdx)
            tIdx = tIdx +1
            local _,_ = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', 'ch_'..n, true)
            Tracks['ch_'..n] = track
            table.insert(NewTracks, track)
            
            --green for named mono tracks
            reaper.SetMediaTrackInfo_Value(track, 'I_CUSTOMCOLOR', TrClrs.green | 0x1000000)
          elseif name == 'No name' and Tracks['ch_'..n] then
            track = Tracks['ch_'..n]
          elseif name == 'DISARMED'
          and not Tracks['DISARMED ch_'..n] and TrackList['DISARMED'] == true then
            reaper.InsertTrackAtIndex(tIdx, true)
            track = reaper.GetTrack(0, tIdx)
            tIdx = tIdx +1
            local _,_ = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', 'DISARMED ch_'..n, true)
            Tracks['DISARMED ch_'..n] = track
            table.insert(NewTracks, track)
            
            --green for named mono tracks
            reaper.SetMediaTrackInfo_Value(track, 'I_CUSTOMCOLOR', TrClrs.green | 0x1000000)
          elseif name == 'DISARMED' and Tracks['DISARMED ch_'..n] then
            track = Tracks['DISARMED ch_'..n]
          elseif name ~= 'No name' and name ~= 'DISARMED' then
            local prevTrackIdx
            local matchCnt = 0
            for _, m in ipairs(matchedNames) do
              if m == name then
                matchCnt = matchCnt + 1
                local prevTrack = Tracks[name]
                prevTrackIdx = reaper.GetMediaTrackInfo_Value( prevTrack, 'IP_TRACKNUMBER' )
              end
            end
            
            if matchCnt > 0 then
              reaper.InsertTrackAtIndex(prevTrackIdx+1, true)
              track = reaper.GetTrack(0, prevTrackIdx+1)
              tIdx = tIdx +1 --increase common new tracks count
              name = name..'_'.. matchCnt+1
              local _,_ = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', name, true)
              Tracks[name] = track
              table.insert(NewTracks, track)
              
              --green for named mono tracks
              reaper.SetMediaTrackInfo_Value(track, 'I_CUSTOMCOLOR', TrClrs.green | 0x1000000)
            else track = Tracks[name]
            end
          end
          
          table.insert(matchedNames, name )
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
    --
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
    local src
    if take then src = reaper.GetMediaItemTake_Source(take) end
    
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
      
      local disarmed = {}
      for ch = 1, Item.chnNumb do
        local cantarTag = "IXML:AATON_CANTAR:ALL_TRK_NAME:DATA:ACTIVE"
        if ch ~= 1 then cantarTag = cantarTag..':'..ch end
        local ret, str = reaper.GetMediaFileMetadata(src, cantarTag)
        if str == "DISARMED" then table.insert(disarmed, ch) end
        
        if str ~= "DISARMED" then
          local chanTag = "IXML:TRACK_LIST:TRACK:NAME"
          local chanTag2 = "IXML:TRACK_LIST_TRACK_NAME"
          if ch ~= 1 then
            chanTag = chanTag..':'.. ch - #disarmed
            chanTag2 = chanTag2..'_'.. ch - #disarmed
          end 
          ret, str = reaper.GetMediaFileMetadata(src, chanTag)
          if str == '' then ret, str = reaper.GetMediaFileMetadata(src, chanTag2) end
          str = str:upper()
        end
        --msg(chanTag..' - '..str)
        local use = true
        if str == '' then
          str = 'No name'
          use = ExpandNoNamedCh
        end
        table.insert(Item.chnNames, str)
        if FieldMatch(TrackList, str, true) == false then TrackList[str] = use end
      end
      
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
          local disarmCnt = 0
          local ret, str
          
          for d, v in ipairs(disarmed) do
            if v < chmode then disarmCnt = disarmCnt +1 end
            if v == chmode then
              str = 'DISARMED ch '..string.format("%.0f", chmode)
              break
            end
          end
          
          if not str then
            local chanTag = "IXML:TRACK_LIST:TRACK:NAME"
            local chanTag2 = "IXML:TRACK_LIST_TRACK_NAME"
            if chmode ~= 1 then
              chanTag = chanTag..':'..string.format("%.0f", chmode - disarmCnt)
              chanTag2 = chanTag2..'_'..string.format("%.0f", chmode - disarmCnt)
            end 
            ret, str = reaper.GetMediaFileMetadata(src, chanTag)
            if str == '' then ret, str = reaper.GetMediaFileMetadata(src, chanTag2) end
            if str == '' then str = 'ch '..string.format("%.0f", chmode) end
          end
          
          table.insert(Item.actChnNames, str)
          chmode = chmode + 1*order
        end
        
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
      
      if tr.name:match('AtoV - ') then
        reaper.SetMediaTrackInfo_Value(track, 'I_CUSTOMCOLOR', TrClrs.blue | 0x1000000)
      elseif i == 1 then --yellow
        reaper.SetMediaTrackInfo_Value(track, 'I_CUSTOMCOLOR', TrClrs.yellow | 0x1000000)
      else --green for named mono tracks
        reaper.SetMediaTrackInfo_Value(track, 'I_CUSTOMCOLOR', TrClrs.green | 0x1000000)
      end
      
      LastTrIdx = LastTrIdx+1
      
      for it, itemData in ipairs(tr) do
        
        local newItem = reaper.AddMediaItemToTrack(track)
        if not tr.name:match('AtoV - ') then table.insert(SuccessItems, newItem) end
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
        reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', itemData.name, true )
        
        if itemData.takemark ~= '' then
          reaper.SetTakeMarker( take, -1, itemData.takemark, itemData.offset + itemData.length/4 )
        end
        
        if itemData.notes ~= '' then
          reaper.GetSetMediaItemInfo_String(newItem, 'P_NOTES', itemData.notes, true)
        end
        
      end
      
    end
    
  end
end

-------------------------------

function LinkFiles(SelItems)
  local notMatchedItems = {}
  local message
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
      
      local attempt
      if FlexLink then attempt = 3 else attempt = 1 end
       
      for a = 1, attempt do
        if itemMatch then break end
        
        for f, file in ipairs(list_files) do
          local match 
          local _, fName, fExt = SplitFilename(file)
          --msg(fName)
          if fExt then fName = fName:gsub('.'..fExt, '') end
          local fNameMod = fName:gsub('-','_'):gsub('+','__'):gsub('*','_ _'):upper()
          
          local fileMetaList = list_file_metadata[file]
          
          if a == 1 then
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
              end --if v[1] ~= '' and so on
              
            end
          end --if a == 1
          --msg(match)
          if ( match ~= false and MatchTakeFileName == true ) or a == 2 then
            if string.upper(fExt) == 'WAV'
            or string.upper(fExt) == 'AIF'
            or string.upper(fExt) == 'FLAC'
            or string.upper(fExt) == 'MP3'
            or string.upper(fExt) == 'OGG'
            or string.upper(fExt) == 'MPA'
            or string.upper(fExt) == 'WMA'
            or string.upper(fExt) == 'MP4'
            or string.upper(fExt) == 'MOV' then
            
              if fNameMod:match(takeFileNameMod) -- src file no ext mod / ref file no ext mod
              or takeFileNameMod:match(fNameMod) -- vice verca
              or fNameMod:match(takeNameMod)       -- src file no ext mod / ref take mod
              or takeNameMod:match(fNameMod) then  -- vice verca
                match = true
              end
              
            end 
          end
          
          
          if (match or (match == nil and LinkOnlyByTC)) or a == 3 then
            local newSrc = reaper.PCM_Source_CreateFromFile( file )
            if newSrc then
              local srcLen, isQN = reaper.GetMediaSourceLength(newSrc)
              local splRate = reaper.GetMediaSourceSampleRate(newSrc)
              local takemark = ''
              
              if isQN == false then
                local fileTC = 0
                if fileMetaList and fileMetaList.TC and fileMetaList.TC ~= ''
                and ( SincByTC or a == 3 ) then
                  fileTC = tonumber(fileMetaList.TC)/splRate
                end
                
                local offset = refPos - fileTC + Item.offs
                
                if a == 2
                and ( offset >= srcLen or fileTC >= refPos + Item.offs + Item.len ) then
                  offset = 0
                  takemark = 'Timecode is wrong! - conform'
                end
                 
                if ( offset < srcLen and fileTC < refPos + Item.offs + Item.len )
                or SincByTC ~= true then
                  match, itemMatch = true, true
                  if not UndoString then
                    reaper.SelectAllMediaItems(0, false)
                    UndoString = 'Link files to selected items'
                  end
                  
                  if a == 3 then takemark = 'Src linked only by timecode! - conform' end
                  
                  if takemark ~= '' then
                    message = "Some items can't be linked properly!"
                    ..'\nBut they was linked with an assumption.'
                    ..'\nLook at the description in the take markers.'
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
                                name = fName..'.'..fExt,
                                takemark = takemark
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
                    if takemark ~= '' then
                      reaper.SetTakeMarker( take, -1, takemark, offset + Item.len/4 )
                    end
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
      end
      
      if itemMatch ~= true then
        table.insert(notMatchedItems, {Item.pos, Item.name, TData.Tname, Item.item} )
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
  
  return notMatchedItems, message
end

-------------------------------

function CreateTracks(EdlsTable)
  local notMatchedItems = {}
  local message
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock2(0)
  
  
  --[[
  ---TEST MESSAGE----
  local trackType = {'V', 'A'}
  
  for k, trType in ipairs(trackType) do
    for e, edlTname in ipairs(EdlsTable[trType]) do
      local trackT = EdlsTable[trType][edlTname]
      msg('\n'..trType..' size is - '..#trackT) msg('')
      for i, item in ipairs(trackT) do
        msg('ITEM '..i) --..' '..item.Type)
        msg('In/Out '..reaper.format_timestr_pos(item.DestIn,'',5) ..' - '.. reaper.format_timestr_pos(item.DestOut,'',5))
        for j, clip in ipairs(item.Clips) do
          local srcIn = reaper.format_timestr_pos(clip.SrcIn,'',5)
          local srcOut = reaper.format_timestr_pos(clip.SrcOut,'',5)
          msg(srcIn..' - '..srcOut..'  '..tostring(clip.name))
        end
      end
      
    end
  end]]
  -------------------
  
  CleanUpEDLs(EdlsTable)
  
  --------------------
  --Now create tracks and items
  local list_files, list_file_metadata = GetAllFiles({SearchFolder})
  LastTrIdx = 0 --reaper.CountTracks(0)
  --msg(#list_files)
  --for f, file in ipairs(list_files) do msg(file) end
  
  local trackType = {'V','A'}
  
  for k, trType in ipairs(trackType) do
    for e, edlTname in ipairs(EdlsTable[trType]) do
      local trackT = EdlsTable[trType][edlTname]
      local dopTRACKS = { Named = {}, Common = {} }
      --msg(edlTname)
      --Create track
      local track
      local trackAtoV
      
      if #trackT > 0 then
        reaper.InsertTrackInProject( 0, LastTrIdx, 1 )
        track = reaper.GetTrack(0, LastTrIdx)
        local _,_ = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', edlTname, true)
        LastTrIdx = LastTrIdx+1
        --yellow
        reaper.SetMediaTrackInfo_Value(track, 'I_CUSTOMCOLOR', TrClrs.yellow | 0x1000000)
        
        if edlTname:match('V') and AudToVid then
          reaper.InsertTrackInProject( 0, LastTrIdx, 1 )
          trackAtoV = reaper.GetTrack(0, LastTrIdx)
          local _,_ = reaper.GetSetMediaTrackInfo_String(trackAtoV, 'P_NAME', 'Audio linked to video - '..edlTname, true)
          LastTrIdx = LastTrIdx+1
          --blue
          reaper.SetMediaTrackInfo_Value(trackAtoV, 'I_CUSTOMCOLOR', TrClrs.blue | 0x1000000)
        end
        
        if not UndoString then
          UndoString = 'Import tracks and media from EDl - post-prod tools'
          reaper.SelectAllMediaItems(0, false)
        end
      end
      
      local crossfade
      local maxidx = #trackT
      for i, item in ipairs(trackT) do
        local newItem
        local newAtVitem
        local fadeInAuto
        local fadeOutAuto
        --msg(item.DestIn ..' '.. #item.Clips)
        local clipStart
        local clipName
        local path, clipFileName, ext
        
        if #item.Clips > 0 then
          clipStart = item.Clips[1]['SrcIn']
          clipName = item.Clips[1]['name']
          path, clipFileName, ext = SplitFilename(clipName)
        end
        
        --Create item
        if (clipStart and clipFileName ) or edlTname:match('V') then
          newItem = reaper.AddMediaItemToTrack(track)
          reaper.SetMediaItemInfo_Value(newItem, 'D_POSITION', item.DestIn)
          reaper.SetMediaItemInfo_Value(newItem, 'D_LENGTH', item.DestOut - item.DestIn)
          reaper.SetMediaItemInfo_Value(newItem, 'D_FADEINLEN', 0 )
          reaper.SetMediaItemInfo_Value(newItem, 'D_FADEOUTLEN', 0 )
        end
        
        if trackAtoV and clipStart then
          newAtVitem = reaper.AddMediaItemToTrack(trackAtoV)
          reaper.SetMediaItemInfo_Value(newAtVitem, 'D_POSITION', item.DestIn)
          reaper.SetMediaItemInfo_Value(newAtVitem, 'D_LENGTH', item.DestOut - item.DestIn)
          reaper.SetMediaItemInfo_Value(newAtVitem, 'D_FADEINLEN', 0 )
          reaper.SetMediaItemInfo_Value(newAtVitem, 'D_FADEOUTLEN', 0 )
        end
        
        if crossfade and newItem then
          fadeInAuto = crossfade
          reaper.SetMediaItemInfo_Value(newItem, 'D_FADEINLEN_AUTO', crossfade )
          if newAtVitem then reaper.SetMediaItemInfo_Value(newAtVitem, 'D_FADEINLEN_AUTO', crossfade ) end
        end
        
        if i ~= maxidx then
          crossfade = item.DestOut - trackT[i+1]['DestIn']
          if crossfade <= MIN_luft_ZERO then crossfade = nil end
        end
        
        if crossfade and newItem then
          fadeOutAuto = crossfade
          reaper.SetMediaItemInfo_Value(newItem, 'D_FADEOUTLEN_AUTO', crossfade )
          if newAtVitem then reaper.SetMediaItemInfo_Value(newAtVitem, 'D_FADEOUTLEN_AUTO', crossfade ) end
        end
        
        if not edlTname:match('V') and newItem then
          local match
          local matchCount = 1
          local recTrackNames = {}
          
          local attempt
          if FlexLink then attempt = 4 else attempt = 1 end
          
          for a = 1, attempt do
            if match then break end
            for f, file in ipairs(list_files) do
              local metadataList = list_file_metadata[file]
              local _, fileName, fileExt = SplitFilename(file)
              local fileMod = file:gsub('-','_'):gsub('+','_'):gsub('*','_')
              local clipNameMod = clipName:gsub('-','_'):gsub('+','_'):gsub('*','_')
              local clipFileNameMod = clipFileName:gsub('.'..ext, ''):gsub('-','_'):gsub('+','_'):gsub('*','_')
              
              if( ( metadataList and metadataList.TAKE and metadataList.SCENE )
              and clipNameMod:match(metadataList.TAKE) and clipNameMod:match(metadataList.SCENE)
              )
              or ( a == 2 and fileMod:match(clipNameMod) )
              or ( a == 3 and fileMod:match(clipFileNameMod) )
              or a == 4 then
                local newSrc = reaper.PCM_Source_CreateFromFile( file )
                if newSrc then
                  local filematch
                  local srcLen, isQN = reaper.GetMediaSourceLength(newSrc)
                  local splRate = reaper.GetMediaSourceSampleRate(newSrc)
                  local takemark = ''
                  local notes = ''
                  
                  if isQN == false then
                    local fileTC = 0
                    if metadataList and metadataList.TC and metadataList.TC ~= '' then 
                      fileTC = tonumber(metadataList.TC)/splRate
                    end
                    
                    local offset = clipStart - fileTC
                    
                    if ( a == 2 or a == 3 )
                    and ( offset < 0 or offset + (item.DestOut - item.DestIn) >= srcLen ) then
                      offset = 0
                      takemark = 'Timecode is wrong! '
                    end
                     
                    if offset >= 0 and offset + (item.DestOut - item.DestIn) < srcLen then
                      match, filematch = true, true
                      
                      if a == 3 then takemark = takemark ..'File format can be vary! - conform' end
                      if a == 4 then takemark = 'Src linked only by timecode! - conform' end
                      if a == 4 then notes = clipName end
                      if a == 2 then takemark = takemark .. '- conform' end
                      
                      local newName = clipFileName
                      if a > 1 then newName = fileName end
                       
                      local trName = metadataList.TRACKNAME
                      local itemData = {
                                  pos = item.DestIn,
                                  length = item.DestOut - item.DestIn,
                                  fadeIn = fadeInAuto,
                                  fadeOut = fadeOutAuto,
                                  offset = offset,
                                  src = newSrc,
                                  name = newName,
                                  takemark = takemark,
                                  notes = notes
                                  }
                       
                      if reaper.GetMediaSourceNumChannels(newSrc) == 1 and trName and trName ~= ''
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
                        
                        local _, _ = reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', newName, true )
                        if itemData.takemark ~= '' then
                          reaper.SetTakeMarker( take, -1, itemData.takemark, itemData.offset + itemData.length/4 )
                        end
                        if a == 4 then
                          reaper.GetSetMediaItemInfo_String(newItem, 'P_NOTES', notes, true)
                        end
                      end
                     
                    end
                  end
                  
                  if filematch ~= true then
                    reaper.PCM_Source_Destroy(newSrc)
                  end
                  
                  if takemark ~= '' then
                    message = "Some items can't be linked properly!"
                    ..'\nBut they was linked with an assumption.'
                    ..'\nLook at the description in the take markers.'
                  end
                  
                end
              end
              
            end -- file cycle
          end -- attempts
          
          if reaper.CountTakes( newItem ) == 0 and match == true then
            reaper.DeleteTrackMediaItem(track, newItem)
          end
          
          if match ~= true then
            local _,_ = reaper.GetSetMediaItemInfo_String(newItem, 'P_NOTES', clipName, true)
            table.insert(notMatchedItems, {item.DestIn, clipName, edlTname} )
          end
          
        else --if track is Video one
          if newItem then
            --if not clipName then clipName = 'BLACK' end 
            local _,_ = reaper.GetSetMediaItemInfo_String(newItem, 'P_NOTES', clipName, true)
          end
          
          if AudToVid and newItem and clipStart then
            local match
            local matchCount = 1
            local recTrackNames = {}
            
            --local clipStart = item.Clips[1]['SrcIn']
            
            for f, file in ipairs(list_files) do
              local metadataList = list_file_metadata[file]
              local newSrc = reaper.PCM_Source_CreateFromFile( file )
              
              if newSrc then
                local filematch
                local srcLen, isQN = reaper.GetMediaSourceLength(newSrc)
                local splRate = reaper.GetMediaSourceSampleRate(newSrc)
                 
                if isQN == false then
                  local fileTC = 0
                  if metadataList and metadataList.TC and metadataList.TC ~= '' then 
                    fileTC = tonumber(metadataList.TC)/splRate 
                    local offset = clipStart - fileTC
                     
                    if offset >= 0 and offset + (item.DestOut - item.DestIn) < srcLen then
                      match, filematch = true, true 
                      local _, fileName, _ = SplitFilename(file)
                      local trName = metadataList.TRACKNAME 
                      local itemData = {
                                  pos = item.DestIn,
                                  length = item.DestOut - item.DestIn,
                                  fadeIn = fadeInAuto,
                                  fadeOut = fadeOutAuto,
                                  offset = offset,
                                  src = newSrc,
                                  name = fileName,
                                  takemark = ''
                                  }
                      
                      if reaper.GetMediaSourceNumChannels(newSrc) == 1 and trName and trName ~= ''
                      and AddNewTrks == true then
                        if not recTrackNames['AtoV - '..trName] then recTrackNames['AtoV - '..trName] = {} end
                        local adress = 'AtoV - '..trName
                        if #recTrackNames['AtoV - '..trName] > 0 then
                          adress = adress..'_'.. tostring(#recTrackNames['AtoV - '..trName] +1)
                        end
                        if not dopTRACKS.Named[adress] then dopTRACKS.Named[adress] = {} end
                        dopTRACKS.Named[adress]['name'] = adress
                        table.insert(dopTRACKS.Named[adress], itemData)
                        table.insert(recTrackNames['AtoV - '..trName], 1) --paste any data, we need just table size
                      elseif AddNewTrks == true and matchCount > 1 then
                        if not dopTRACKS.Common[matchCount-1] then dopTRACKS.Common[matchCount-1] = {} end
                        dopTRACKS.Common[matchCount-1]['name'] = edlTname..'_'..matchCount
                        table.insert(dopTRACKS.Common[matchCount-1], itemData)
                        matchCount = matchCount +1
                      else
                        --FieldMatch(SuccessItems, newItem, true)
                        local take = reaper.AddTakeToMediaItem(newAtVitem) 
                        reaper.SetMediaItemTake_Source( take, newSrc )
                        reaper.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', offset )
                        local _, _ = reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', fileName, true )
                      end
                      
                    else match = false
                    end
                    
                    if filematch ~= true then
                      reaper.PCM_Source_Destroy(newSrc)
                    end
                    
                  end
                   
                end --isQN
              end --if newSrc
            end --files cycle
            
            if reaper.CountTakes( newAtVitem ) == 0 then
              reaper.DeleteTrackMediaItem(trackAtoV, newAtVitem)
            end
            
          end
          
        end
        
      end -- for item/clip cycle
      
      AddDopTracks(dopTRACKS)
      
    end  
  end

  return notMatchedItems, message
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
    if key and v then dop_list[key] = v end
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
  table.insert(TagsList, {text, 'TRACKCOUNT', false, {"IXML:TRACK_LIST:TRACK_COUNT"} })
   
  local text = ''
  table.insert(TagsList, {text, 'TRACKNAME', false, {"IXML:TRACK_LIST:TRACK:NAME"} })

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

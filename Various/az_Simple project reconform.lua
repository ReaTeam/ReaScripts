-- @description Simple project reconform
-- @author AZ
-- @version 0.7.2
-- @changelog - fixed up to 1 ms inaccuracy when creating reference track
-- @link Forum thread https://forum.cockos.com/showthread.php?p=2803375#post2803375
-- @donation Donate via PayPal https://www.paypal.me/AZsound
-- @about
--   # Simple Project Reconform
--   It can be useful for post-production to automatically adapt your project to the new version of video.
--
--   The script is under development, but stable enough to try.
--   All your feedback is appreciated.
--   Read more: https://forum.cockos.com/showthread.php?p=2803375#post2803375

-----------------------------
function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end
-----------------------------
BugTIME = -1

MIN_luft_ZERO = reaper.parse_timestr_pos('00:00:00:01', 5) / 4
--------------------------
function rgbToHex(rgba) -- passing a table with percentage like {100, 50, 20, 90}
  local hexadecimal = '0X'

  for key, value in pairs(rgba) do
    local hex = ''
    if value > 100 or value < 0 then return error('Color must be a percantage value\n between 0 and 100') end
    value = (255/100)*value
    while (value > 0) do
      local index = math.floor(math.fmod(value, 16) + 1)
      value = math.floor(value / 16)
      hex = string.sub('0123456789ABCDEF', index, index) .. hex
    end

    if (string.len(hex) == 0) then
      hex = '00'

    elseif (string.len(hex) == 1) then
      hex = '0' .. hex
    end

    hexadecimal = hexadecimal .. hex
  end

  return hexadecimal
end
-----------------------

ExtStateName = "SimpleReconform_AZ"

function GetExtStates()
  for i, option in ipairs(OptDefaults) do
    if option[3] ~= nil then
      local state = reaper.GetExtState(ExtStateName, option[2])
      
      if state ~= "" then
        local stateType = type(option[3])
        if stateType == 'number' then state = tonumber(state) end
        if stateType == 'boolean' then
          if state == 'true' then state = true else state = false end 
        end
        OptDefaults[i][3] = state
      else
        reaper.SetExtState(ExtStateName, option[2], tostring(option[3]), true)
      end
      
    end
  end
end

---------------------

function SetExtStates()
  for i, option in ipairs(OptDefaults) do 
    if option[3] ~= nil then
      reaper.SetExtState(ExtStateName, option[2], tostring(option[3]), true)
    end
  end
end

---------------------

function OptionsDefaults()
  OptDefaults = {}
  local text
  
  text = 'Content for reconform:'
  table.insert(OptDefaults, {text, 'Separator', nil })
  
  text = 'Reconform visible tracks only'
  table.insert(OptDefaults, {text, 'ReconfOnlyVis', false })
  
  text = 'Master track envelopes'
  table.insert(OptDefaults, {text, 'ReconfMaster', true })
  
  text = 'Locked items'
  table.insert(OptDefaults, {text, 'ReconfLockedItems', true })
  
  text = 'Disabled lanes on fixed lanes tracks'
  table.insert(OptDefaults, {text, 'ReconfDisabledLanes', true })
  
  text = 'Project markers'
  table.insert(OptDefaults, {text, 'ReconfMarkers', true })
  
  text = 'Regions'
  table.insert(OptDefaults, {text, 'ReconfRegions', true })
  
  text = 'Tempo envelope'
  table.insert(OptDefaults, {text, 'ReconfTempo', true })
  
  
  text = 'Processing options:'
  table.insert(OptDefaults, {text, 'Separator', nil })
  
  text = 'Heal gaps if time is consistent'
  table.insert(OptDefaults, {text, 'HealGaps', true })
  
  text = 'Heal splits if time is consistent'
  table.insert(OptDefaults, {text, 'HealSplits', true })
  
  text = 'Fill in gaps using content from the'
  table.insert(OptDefaults, {text, 'FillGaps', "don't fill", {
                                                              'left region',
                                                              'right region',
                                                              "don't fill" 
                                                              } })
  
  text = 'Ignore crossfades, prefer content from the'
  table.insert(OptDefaults, {text, 'IgnoreCrossfades', "don't ignore", {
                                                                        'left region',
                                                                        'right region',
                                                                        "don't ignore" 
                                                                        } })
  
  text = 'Reduce gaps in regions (with care!)'
  table.insert(OptDefaults, {text, 'ReduceGapsRegions', false })
  
end

--------------------------------

function SetOptGlobals()
  Opt = {}
  for i = 1, #OptDefaults do
    local name = OptDefaults[i][2]
    Opt[name] = OptDefaults[i][3]
  end
end

------------------------

function OptionsWindow()
  local imgui_path = reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua'
  if not reaper.file_exists(imgui_path) then
    reaper.ShowMessageBox('Please, install ReaImGui from Reapack!', 'No Imgui library', 0)
    return
  end
  dofile(imgui_path) '0.9.2'
  OptionsDefaults()
  GetExtStates()
  local fontSize = 17
  local ctx, ctxPr, font, fontSep, fontBig
  local H = fontSize
  local W = fontSize
  local loopcnt = 0
  local esc
  local runReconf
  
  local OldEDL
  local NewEDL
  local ReferenceFile 
  REFoffset = 0
  RefTrIdx = 0
  
  EDLcontentFlags = reaper.GetExtState(ExtStateName, 'ContentAnalyse')
  
  if EDLcontentFlags ~= "" then
    EDLcontentFlags = tonumber(EDLcontentFlags)
  else EDLcontentFlags = 31
  end
  
  
  _, old_TrimLeadingTime = reaper.GetProjExtState(0, ExtStateName, 'old_TrimLeadingTime')
  _, old_TrimOnlyEmptyTime = reaper.GetProjExtState(0,ExtStateName, 'old_TrimOnlyEmptyTime')
  _, TrimOldTime = reaper.GetProjExtState(0, ExtStateName, 'TrimOldTime')
  
  if old_TrimLeadingTime ~= "" then
    if old_TrimLeadingTime == 'true' then old_TrimLeadingTime = true
    else old_TrimLeadingTime = false
    end
  else old_TrimLeadingTime = true
  end
  
  if old_TrimOnlyEmptyTime ~= "" then
    if old_TrimOnlyEmptyTime == 'true' then old_TrimOnlyEmptyTime = true
    else old_TrimOnlyEmptyTime = false
    end
  else old_TrimOnlyEmptyTime = true
  end
  
  if TrimOldTime == '' then TrimOldTime = '01:00:00:00' end
  
  _, new_TrimLeadingTime = reaper.GetProjExtState(0, ExtStateName, 'new_TrimLeadingTime')
  _, new_TrimOnlyEmptyTime = reaper.GetProjExtState(0, ExtStateName, 'new_TrimOnlyEmptyTime')
  _, TrimNewTime = reaper.GetProjExtState(0, ExtStateName, 'TrimNewTime')
  
  if new_TrimLeadingTime == "false" then
    new_TrimLeadingTime = false
  else new_TrimLeadingTime = true
  end
  
  if new_TrimOnlyEmptyTime == "false" then
    new_TrimOnlyEmptyTime = false
  else new_TrimOnlyEmptyTime = true
  end
  
  if TrimNewTime == '' then TrimNewTime = '01:00:00:00' end
  
  
  local iniFolder
  
  local OldPrjAAF
  local NewPrjAAF
  local OldPrjPreview
  local NewPrjPreview
  
  _, AnalyseOnlySelTracks = reaper.GetProjExtState(0, ExtStateName, 'AnalyseOnlySelTracks')
  
  if AnalyseOnlySelTracks == "true" then
    AnalyseOnlySelTracks = true
  else AnalyseOnlySelTracks = false
  end
  
  OldPrjStart = 0
  NewPrjStart = nil
  local oldprjOffsetTime = ''
  local newprjOffsetTime = ''
  local SourcePrj
  local SrcPrjPreview
  tracksForImportFlag = 1
  
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
  -------
  ---Flags---
  local Flags = {}
  Flags.childRounding = reaper.ImGui_StyleVar_ChildRounding()
  Flags.frameRounding = reaper.ImGui_StyleVar_FrameRounding()
  Flags.childBorder = reaper.ImGui_ChildFlags_Border()
  Flags.menubar = reaper.ImGui_WindowFlags_MenuBar()
  Flags.tableResizeflag = reaper.ImGui_TableFlags_Resizable()
  Flags.childAutoResizeX = reaper.ImGui_ChildFlags_AutoResizeX()
  Flags.childAutoResizeY = reaper.ImGui_ChildFlags_AutoResizeY()
  
  --------------
  function SplitFilename(strFilename) -- Path, Filename, Extension
    return string.match(strFilename, "(.-)([^\\]-([^\\%.]+))$")
  end
  --------------
  
  function ProjectSelector(Prj, description, prjselpreview)
    local retprj = true
    local path, projfn, extension
    local Projects = {}
    local cur_retprj, cur_projfn = reaper.EnumProjects( -1 )
    local idx = 0
    while retprj do
      retprj, projfn = reaper.EnumProjects( idx )
      if retprj and retprj ~= cur_retprj and projfn ~= '' then
        path, projfn, extension = SplitFilename(projfn) 
        table.insert(Projects, {retprj, projfn})
      end
      idx = idx+1
    end
    
    if cur_retprj == Prj then Prj = nil end
    
    if #Projects > 0 and Prj == nil then
      Prj =           Projects[#Projects][1]
      prjselpreview = Projects[#Projects][2]
    elseif #Projects == 0 then
      prjselpreview = 'Open a named project in another tab'
      Prj = nil
    end
    
    reaper.ImGui_PushItemWidth(ctx, fontSize*23 )
    local choicePrj
    if reaper.ImGui_BeginCombo(ctx, description, prjselpreview, nil) then 
      for k,f in ipairs(Projects) do
        local is_selected = choicePrj == k
        if reaper.ImGui_Selectable(ctx, Projects[k][2], is_selected) then 
          prjselpreview = Projects[k][2]
          Prj = Projects[k][1]
          choicePrj = k
        end
    
        -- Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
        if is_selected then
          reaper.ImGui_SetItemDefaultFocus(ctx)
        end
      end
      reaper.ImGui_EndCombo(ctx)
    end
    
    return Prj, prjselpreview
  end
  
  --------------
  function frame()
    --reaper.ImGui_PushFont(ctx, font)
    
    --About button
    reaper.ImGui_SameLine(ctx, fontSize*25, nil)
    if reaper.ImGui_Button(ctx, 'About - forum page', nil, nil) then
      local doc = 'https://forum.cockos.com/showthread.php?p=2803375#post2803375'
      if reaper.CF_ShellExecute then
        reaper.CF_ShellExecute(doc)
      else
        reaper.MB(doc, 'Simple Project Reconform forum page', 0)
      end
    end
    
    -----EDL section
    if reaper.ImGui_CollapsingHeader(ctx, 'Create reference track using EDL files') then
      reaper.ImGui_NewLine(ctx)
      --Source tracks
      local AnalyseSource = {
      'Video only',
      'Audio only',
      "Both video and audio"
      }
      local choiceSrc
      local change
      reaper.ImGui_Text(ctx, 'Source for analyse') 
      
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

      
      local function addFileNamesToList(list, string )
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
      
      if reaper.ImGui_Button(ctx, ' old EDLs ') then --msg(iniFolder)
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
          OldEDL ={} 
          addFileNamesToList(OldEDL, fileNames) 
        end
      end
      
      local function showEDLsNames(list)
        if list then 
          for i, line in ipairs(list) do
            local path, fn, ext = SplitFilename(line)
            iniFolder = path:gsub('[/\\]$','')
            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.Green)
            reaper.ImGui_Text(ctx, fn)
            reaper.ImGui_PopStyleColor(ctx,1)
          end
        end
      end
      
      showEDLsNames(OldEDL)
      
      if reaper.ImGui_Button(ctx, 'new EDLs') then
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
          NewEDL ={}
          addFileNamesToList(NewEDL, fileNames) 
        end
      end
      
      showEDLsNames(NewEDL)
      
      if reaper.ImGui_Button(ctx, 'old prj reference file') then
        if not iniFolder then
          local cur_retprj, cur_projfn = reaper.EnumProjects( -1 )
          local path, projfn, extension = SplitFilename(cur_projfn)
          if path then iniFolder = path:gsub('[/\\]$','') end
        end
        local iniFile = ''
        local extensionList = "Media file\0*.wav;*.mp3;*.flac;*.aif;*.mpa;*.wma;*.mp4;*.mov;*.m4v;*.webm\0\0"
        local allowMultiple = false
        local ret, fileNames = reaper.JS_Dialog_BrowseForOpenFiles
        ( 'Choose media file', iniFolder, iniFile, extensionList, allowMultiple ) 
        
        if fileNames ~= '' then
          ReferenceFile = {}
          addFileNamesToList(ReferenceFile, fileNames)
        end
      end
      
      reaper.ImGui_SameLine(ctx)
      
      if reaper.ImGui_Button(ctx, 'get from selected item') then
        local file
        
        local selitem = reaper.GetSelectedMediaItem(0,0)
        if selitem then
          local reftake = reaper.GetActiveTake(selitem)
          local src = reaper.GetMediaItemTake_Source(reftake)
          if reaper.GetMediaSourceType( src ) ~= 'MIDI' then
            file = reaper.GetMediaSourceFileName(src)
            REFoffset = reaper.GetMediaItemTakeInfo_Value(reftake, 'D_STARTOFFS')
          end
        end
        
        if file then
          reaper.SetOnlyTrackSelected(reaper.GetMediaItem_Track(selitem))
          ReferenceFile = {}
          addFileNamesToList(ReferenceFile, file)
        end
      end
      
      showEDLsNames(ReferenceFile)
      
      reaper.ImGui_NewLine(ctx)
      
      if OldEDL and NewEDL and ReferenceFile then
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.MainButton.Default)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), gui_colors.MainButton.Hovered)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), gui_colors.MainButton.Active)
      end
      if reaper.ImGui_Button(ctx, 'Analyse and create reference track') then
        local abort
         
        if OldEDL and NewEDL and ReferenceFile then
          local timeTreshold = 0

          if old_TrimLeadingTime == true and old_TrimOnlyEmptyTime == false then
            timeTreshold = reaper.parse_timestr_pos( TrimOldTime, 5 ) - PrjTimeOffset
          end 
          OldEdlTable = AnalyseEDLs(OldEDL, timeTreshold)
          
          if new_TrimLeadingTime == true and new_TrimOnlyEmptyTime == false then
            timeTreshold = reaper.parse_timestr_pos( TrimNewTime, 5 ) - PrjTimeOffset
          else timeTreshold = 0
          end
          NewEdlTable = AnalyseEDLs(NewEDL, timeTreshold)
          
          if #OldEdlTable == 0 and #NewEdlTable == 0 then
            reaper.ShowMessageBox('There is no valid data in all EDL files', 'Warning!',0)
            abort = true
          elseif #OldEdlTable == 0 then
            reaper.ShowMessageBox('There is no valid data in OLD project EDL files', 'Warning!',0)
            abort = true
          elseif #NewEdlTable == 0 then
            reaper.ShowMessageBox('There is no valid data in NEW project EDL files', 'Warning!',0)
            abort = true
          end
          
          if abort ~= true then
            CompResult = CompareEDLs(OldEdlTable, NewEdlTable) 
            if #CompResult == 0 then
              reaper.ShowMessageBox('There ara no matched areas', 'Warning!',0)
              abort = true
            end 
          end
          
          if abort ~= true then CreateRefTrack(CompResult, ReferenceFile) end
        end
      end
      if OldEDL and NewEDL and ReferenceFile then reaper.ImGui_PopStyleColor(ctx, 3) end
      reaper.ImGui_NewLine(ctx)
      reaper.ImGui_NewLine(ctx)
      
      reaper.ImGui_SameLine(ctx, fontSize*3)
      reaper.ImGui_PushFont(ctx, fontSep)
      if reaper.ImGui_CollapsingHeader(ctx, 'Advanced timing options') then
        
        local ret
        reaper.ImGui_NewLine(ctx)
        reaper.ImGui_SameLine(ctx, fontSize*3)
        ret, old_TrimLeadingTime = reaper.ImGui_Checkbox(ctx,'Ignore leading time in OLD EDLs',old_TrimLeadingTime)
        if ret == true then reaper.SetProjExtState(0,ExtStateName,'old_TrimLeadingTime', tostring(old_TrimLeadingTime), true) end 
        
        reaper.ImGui_NewLine(ctx)
        reaper.ImGui_SameLine(ctx, fontSize*3)
        reaper.ImGui_PushItemWidth(ctx, fontSize*5.5 )
        ret, TrimOldTime = reaper.ImGui_InputText(ctx, '##1', TrimOldTime, nil, nil)
        if ret == true then reaper.SetProjExtState(0, ExtStateName,'TrimOldTime', TrimOldTime, true) end
        reaper.ImGui_SameLine(ctx, nil, fontSize)
        ret, old_TrimOnlyEmptyTime = reaper.ImGui_Checkbox(ctx,'Only empty time if multiplied##1',old_TrimOnlyEmptyTime)
        if ret == true then reaper.SetProjExtState(0,ExtStateName,'old_TrimOnlyEmptyTime', tostring(old_TrimOnlyEmptyTime), true) end
        
        ---
        
        reaper.ImGui_NewLine(ctx)
        reaper.ImGui_SameLine(ctx, fontSize*3)
        ret, new_TrimLeadingTime = reaper.ImGui_Checkbox(ctx,'Ignore leading time in NEW EDLs',new_TrimLeadingTime)
        if ret == true then reaper.SetProjExtState(0,ExtStateName,'new_TrimLeadingTime', tostring(new_TrimLeadingTime), true) end 
        
        reaper.ImGui_NewLine(ctx)
        reaper.ImGui_SameLine(ctx, fontSize*3)
        reaper.ImGui_PushItemWidth(ctx, fontSize*5.5 )
        ret, TrimNewTime = reaper.ImGui_InputText(ctx, '##2', TrimNewTime, nil, nil)
        if ret == true then reaper.SetProjExtState(0, ExtStateName,'TrimNewTime', TrimNewTime, true) end
        reaper.ImGui_SameLine(ctx, nil, fontSize)
        ret, new_TrimOnlyEmptyTime = reaper.ImGui_Checkbox(ctx,'Only empty time if multiplied##2',new_TrimOnlyEmptyTime)
        if ret == true then reaper.SetProjExtState(0,ExtStateName,'new_TrimOnlyEmptyTime', tostring(new_TrimOnlyEmptyTime), true) end
      end
      reaper.ImGui_PopFont(ctx)
      reaper.ImGui_NewLine(ctx)
      
      reaper.ImGui_SetWindowSize(ctx, 0, 0, nil )
    end
    --------end of EDL section
    
    if reaper.ImGui_CollapsingHeader(ctx, 'Reconform options') then
      for i, v in ipairs(OptDefaults) do
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
          
          reaper.ImGui_NewLine(ctx)
          reaper.ImGui_SeparatorText( ctx, option[1] )
          
          reaper.ImGui_PopStyleColor(ctx, 1)
          reaper.ImGui_PopFont(ctx)
        end
        
        OptDefaults[i] = option
      end -- for
      reaper.ImGui_SetWindowSize(ctx, 0, 0, nil )
    end -- end of collapsing header
     
    reaper.ImGui_NewLine(ctx)
    
    --Reference track processing
    --reaper.ImGui_PushFont(ctx, fontSep)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.White)
    reaper.ImGui_SeparatorText( ctx, 'Reconform project using reference track' ) 
    reaper.ImGui_NewLine(ctx)
    reaper.ImGui_PopStyleColor(ctx, 1)
    --reaper.ImGui_PopFont(ctx)
    
    if NewPrjStart then
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.MainButton.Default)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), gui_colors.MainButton.Hovered)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), gui_colors.MainButton.Active)
    end
    if reaper.ImGui_Button(ctx, 'Create report markers for gaps, crossfades, splits', nil, nil ) then
      reaper.Undo_BeginBlock2( 0 )
      reaper.PreventUIRefresh( 1 )
      CreateReportMarkers()
      reaper.Undo_EndBlock2( 0, 'Create report markers - Simple reconform', -1 ) 
      reaper.UpdateArrange()
    end
    if NewPrjStart then reaper.ImGui_PopStyleColor(ctx, 3) end
    
    reaper.ImGui_NewLine(ctx)
    reaper.ImGui_Text(ctx, 'To get much faster results') 
    if reaper.ImGui_Button(ctx, 'Set FX on selected items OFFLINE') then
      reaper.Main_OnCommandEx(42353,0,0) --Items: Set all take FX offline for selected media items
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, 'Revert FX on selected items ONLINE') then
      reaper.Main_OnCommandEx(42354,0,0) --Items: Set all take FX online for selected media items
    end
    reaper.ImGui_NewLine(ctx)
    
    --Input box + button
    reaper.ImGui_PushItemWidth(ctx, fontSize*7 )
    
    local fieldState, retOldPrjOffsetTime =
    reaper.ImGui_InputText(ctx, 'Old project position ', reaper.format_timestr_pos( OldPrjStart, '', 5 ), nil, nil) 
    if fieldState == true then
      OldPrjStart = reaper.parse_timestr_pos( retOldPrjOffsetTime, 5 )
    end
    reaper.ImGui_SameLine(ctx, nil, fontSize*0.7)
    reaper.ImGui_PushID(ctx, 1)
    if reaper.ImGui_Button(ctx, 'Get edit cursor', nil, nil ) then
      OldPrjStart = reaper.GetCursorPosition() 
    end
    reaper.ImGui_PopID(ctx)
    
    --Save button
    reaper.ImGui_SameLine(ctx, nil, fontSize*1.25)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.MainButton.Default)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), gui_colors.MainButton.Hovered)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), gui_colors.MainButton.Active)

    runReconf = reaper.ImGui_Button(ctx, 'Reconform', fontSize*8, nil)
    
    reaper.ImGui_PopStyleColor(ctx, 3)
    
    --Input box + button 
    if NewPrjStart then
      newprjOffsetTime = reaper.format_timestr_pos( NewPrjStart, '', 5 )
    end
    local fieldState, retNewPrjOffsetTime =
    reaper.ImGui_InputText(ctx, 'New project position', newprjOffsetTime, nil, nil)
    
    if fieldState == true then
      if retNewPrjOffsetTime ~= '' then
        NewPrjStart = reaper.parse_timestr_pos( retNewPrjOffsetTime, 5 )
      else
        NewPrjStart = nil
        newprjOffsetTime = ''
      end
    end
    
    reaper.ImGui_SameLine(ctx, nil, nil)
    reaper.ImGui_PushID(ctx, 2)
    if reaper.ImGui_Button(ctx, 'Get edit cursor', nil, nil ) then
      NewPrjStart = reaper.GetCursorPosition()
    end
    reaper.ImGui_PopID(ctx)
    
    if NewPrjStart and NewPrjStart <= OldPrjStart then
      reaper.ShowMessageBox('Reconformed project must be placed next to the old version.\nLet it be +1 hour after the Old verion.','Warning!', 0)
      NewPrjStart = OldPrjStart + 3600
    end
    
    --Paste new items for gaps header
    reaper.ImGui_NewLine(ctx)
    if reaper.ImGui_CollapsingHeader(ctx, 'Paste new items for gaps from another project tab') then
       
      SourcePrj, SrcPrjPreview = ProjectSelector(SourcePrj, "Source Project", SrcPrjPreview)
      
      --Source tracks
      local SrcTrks = {
      'All tracks',
      'Selected tracks',
      "Don't import from muted tracks"
      }
      local choiceTrks
      if reaper.ImGui_BeginCombo(ctx, 'Source tracks', SrcTrks[tracksForImportFlag], nil) then 
        for k,f in ipairs(SrcTrks) do
          local is_selected = choiceTrks == k
          if reaper.ImGui_Selectable(ctx, SrcTrks[k], is_selected) then 
            tracksForImportFlag = k
            choiceTrks = k
          end
      
          -- Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
          if is_selected then
            reaper.ImGui_SetItemDefaultFocus(ctx)
          end
        end
        reaper.ImGui_EndCombo(ctx)
      end
      
      --Button for paste items
      reaper.ImGui_Text(ctx, '' ) --space before buttons
      reaper.ImGui_SameLine(ctx, nil, fontSize*24.25)
      if NewPrjStart then
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.MainButton.Default)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), gui_colors.MainButton.Hovered)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), gui_colors.MainButton.Active)
      end
      if reaper.ImGui_Button(ctx, 'Paste Items', fontSize*8, nil ) then
        reaper.Undo_BeginBlock2( 0 )
        reaper.PreventUIRefresh( 1 )
        
        PasteItemsFromPrj(cur_retprj, SourcePrj)
        
        reaper.Undo_EndBlock2( 0, 'Paste new items - Simple reconform', -1 ) 
        reaper.UpdateArrange()
      end
      if NewPrjStart then reaper.ImGui_PopStyleColor(ctx, 3) end
      
      reaper.ImGui_SetWindowSize(ctx, 0, 0, nil )
    end -- end of collapsing header
    
    reaper.ImGui_NewLine(ctx)
    
    --reaper.ImGui_PopFont(ctx)
  end
  
  --------------
  function loop()
    PrjTimeOffset = -reaper.GetProjectTimeOffset( 0, false )
    if reaper.CountSelectedTracks(0) ~= 0 then
      RefTrIdx = reaper.GetMediaTrackInfo_Value( reaper.GetSelectedTrack(0,0), 'IP_TRACKNUMBER' )
    end
    
    esc = reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape())
    
    undo = ( reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_RightCtrl())
           or
           reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_LeftCtrl()) )
           and
           reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Z())
           
    redo = ( reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_RightCtrl())
           or
           reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_LeftCtrl()) )
           and
           reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Z())
           and(
           reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_RightShift())
           or
           reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_LeftShift())
           )
    
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
      
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.White) 
      --
      reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(), fontSize/4)
      reaper.ImGui_PushStyleVar(ctx, Flags.frameRounding, fontSize/4)
      reaper.ImGui_PushStyleVar(ctx, Flags.childRounding, fontSize/4)
      reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), fontSize/2, fontSize/4)
    
      local window_flags = reaper.ImGui_WindowFlags_None()--reaper.ImGui_WindowFlags_MenuBar()
      reaper.ImGui_SetNextWindowSize(ctx, W, H, reaper.ImGui_Cond_Once()) -- Set the size of the windows.  Use in the 4th argument reaper.ImGui_Cond_FirstUseEver() to just apply at the first user run, so ImGUI remembers user resize s2
      
      reaper.ImGui_PushFont(ctx, font)
      
      local visible, open = reaper.ImGui_Begin(ctx, 'Simple Project Reconform', true, window_flags)
      reaper.ImGui_PopStyleColor(ctx, 1)
      
      if visible then
          frame()
          if loopcnt == 0 then reaper.ImGui_SetWindowSize(ctx, 0, 0, nil ) end
          reaper.ImGui_End(ctx)
      end
      
      reaper.ImGui_PopStyleColor(ctx, 13)
      reaper.ImGui_PopStyleVar(ctx, 4)
      reaper.ImGui_PopFont(ctx)
       
      esc = reaper.ImGui_IsKeyReleased(ctx, reaper.ImGui_Key_Escape())
      
      if undo then reaper.Main_OnCommandEx(40029,0,0) end
      if redo then reaper.Main_OnCommandEx(40030,0,0) end

      if open and not esc then
        SetExtStates()
        if runReconf == true then main() end
        reaper.defer(loop)
      end

      loopcnt = loopcnt+1
  end
  -----------------
  local fontName
  ctx = reaper.ImGui_CreateContext('SimpleProjectReconform_AZ')
  ctxPr = reaper.ImGui_CreateContext('progressSPR_AZ')
  if reaper.GetOS():match("^Win") == nil then
    reaper.ImGui_SetConfigVar(ctx, reaper.ImGui_ConfigVar_ViewportsNoDecoration(), 0)
    fontName = 'sans-serif'
  else fontName = 'Calibri'
  end
  font = reaper.ImGui_CreateFont(fontName, fontSize, reaper.ImGui_FontFlags_None()) -- Create the fonts you need
  fontSep = reaper.ImGui_CreateFont(fontName, fontSize-2, reaper.ImGui_FontFlags_Italic())
  fontBig = reaper.ImGui_CreateFont(fontName, fontSize+4, reaper.ImGui_FontFlags_None())
  reaper.ImGui_Attach(ctx, font)
  reaper.ImGui_Attach(ctxPr, font)
  reaper.ImGui_Attach(ctx, fontSep)
  reaper.ImGui_Attach(ctx, fontBig)
  
  loop()
  --reaper.defer(ShowProgress)
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

-------------------------

function CreateRefTrack(Items, file) --each item = {oldstart, oldend, targetpos}
  
  if #Items == 0 then
    local msg = 'There is no matches between EDLs'
    reaper.ShowMessageBox(msg, 'Simple Project Reconform', 0)
    return
  end
  
  file = file[1]
  local startPoint = OldPrjStart
  if NewPrjStart then startPoint = NewPrjStart end
  reaper.Undo_BeginBlock2(0) 
  reaper.InsertTrackAtIndex(RefTrIdx, true)
  local track = reaper.GetTrack(0,RefTrIdx)
  local newSrc = reaper.PCM_Source_CreateFromFile( file )
  
  reaper.SetOnlyTrackSelected(track)
  local _, _ = reaper.GetSetMediaTrackInfo_String( track, 'P_NAME', 'Recomped reference track', true )
  reaper.SelectAllMediaItems(0,false)
  
  local _, takeName, _ = SplitFilename(file)
  local crossfade
  
  --Create project items
  local maxidx = #Items
  for i, item in ipairs(Items) do
    local newItem = reaper.AddMediaItemToTrack(track)
    local take = reaper.AddTakeToMediaItem(newItem) 
     
    reaper.SetMediaItemTake_Source( take, newSrc )
    reaper.SetMediaItemInfo_Value(newItem, 'D_POSITION', item[3] + startPoint)
    reaper.SetMediaItemInfo_Value(newItem, 'D_LENGTH', item[2] - item[1])
    reaper.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', item[1] + REFoffset )
    
    if crossfade then
      reaper.SetMediaItemInfo_Value(newItem, 'D_FADEINLEN_AUTO', crossfade )
    end
    
    if i ~= maxidx then
      if item[3] == Items[i+1][3]
      and item[2] - item[1] == Items[i+1][2] - Items[i+1][1] then
        local showOverlapping = reaper.GetToggleCommandState(40507)
        if showOverlapping == 0 then
          local txt = 'Option "Offset overlapping media items vertically" wil be turn ON'
          reaper.ShowMessageBox(txt,'Be aware!',0)
          reaper.Main_OnCommandEx(40507,0,0) --Options: Offset overlapping media items vertically
        end
      end
      
      crossfade = ( item[3] + (item[2] - item[1]) ) - Items[i+1][3]
      if crossfade <= MIN_luft_ZERO then crossfade = nil end
    end
    
    if crossfade then 
      reaper.SetMediaItemInfo_Value(newItem, 'D_FADEOUTLEN_AUTO', crossfade )
    end
    
    --reaper.SetMediaItemSelected(newItem, true)
    local _, _ = reaper.GetSetMediaItemTakeInfo_String( take, 'P_NAME', takeName, true )
  end
   
  reaper.Undo_EndBlock2(0,'Create reference track via EDls',1)
  reaper.UpdateArrange()
end
-------------------------

function AnalyseEDLs(EDLs, timeTreshold) --table of pathes
  local CommonEDL = {}
  local Splits = {}
  local EdlTable = { V={Splits={} }, A1={Splits={} }, A2={Splits={} }, A3={Splits={} }, A4={Splits={} } }
  
  for e, EDLfile in ipairs(EDLs) do
    local EDLtext = ''
    local items
    local item
    local fadelen
    local clip
    
    --local itemscnt = 0
    
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
  end --end of edl files cycle
  
  --Remove Fades in Audio clips
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
  
  --[[
  msg('\nEDL size is - '..#EdlTable.A1) msg('')
  ---TEST MESSAGE----
  for i, item in ipairs(EdlTable.A1) do
    if item.DestIn > 60 then break end
    msg('ITEM '..i) --..' '..item.Type) 
    msg('In/Out '..reaper.format_timestr_pos(item.DestIn,'',5) ..' - '.. reaper.format_timestr_pos(item.DestOut,'',5))
    for j, clip in ipairs(item.Clips) do
      local srcIn = reaper.format_timestr_pos(clip.SrcIn,'',5)
      local srcOut = reaper.format_timestr_pos(clip.SrcOut,'',5)
      msg(srcIn..' - '..srcOut..'  '..tostring(clip.name))
    end 
  end
  -------------------
  ]]
  --
  
  
  ---Add to the common table content for analyse 
  if EDLcontentFlags & 1 ~= 0 then
    table.move(EdlTable.V, 1, #EdlTable.V, #CommonEDL+1, CommonEDL)
    table.move(EdlTable.V.Splits, 1, #EdlTable.V.Splits, #Splits+1, Splits)
  end
  
  if EDLcontentFlags & 1<<1 ~= 0 then
    table.move(EdlTable.A1, 1, #EdlTable.A1, #CommonEDL+1, CommonEDL)
    for i, v in ipairs(EdlTable.A1.Splits) do FieldMatch(Splits, v, true) end
  end
  
  if EDLcontentFlags & 1<<2 ~= 0 then
    table.move(EdlTable.A2, 1, #EdlTable.A2, #CommonEDL+1, CommonEDL)
    for i, v in ipairs(EdlTable.A2.Splits) do FieldMatch(Splits, v, true) end
  end
  
  if EDLcontentFlags & 1<<3 ~= 0 then
    table.move(EdlTable.A3, 1, #EdlTable.A3, #CommonEDL+1, CommonEDL)
    for i, v in ipairs(EdlTable.A3.Splits) do FieldMatch(Splits, v, true) end
  end
  
  if EDLcontentFlags & 1<<4 ~= 0 then
    table.move(EdlTable.A4, 1, #EdlTable.A4, #CommonEDL+1, CommonEDL)
    for i, v in ipairs(EdlTable.A4.Splits) do FieldMatch(Splits, v, true) end
  end 
  
  --GO HERE IN FUTURE after parsing project info if the Project Analyse used instead of EDL one.
  CleanUpEDL(CommonEDL, Splits)
  
  return CommonEDL
end

-------------------------

function CleanUpEDL(CommonEDL, Splits)

  ---Split all items at all split poins
  table.sort(Splits)
  for i=1, #CommonEDL do
    local item = CommonEDL[i]
    
    for s, v in ipairs(Splits) do
      if item.DestIn < v and v < item.DestOut then
        local newitem = {Type, Clips={}, DestIn, DestOut}
        newitem.Type = item.Type
        for j, c in ipairs(item.Clips) do
          local clip = { name, SrcIn, SrcOut }
          clip.name = c.name
          if c.SrcIn then clip.SrcIn = c.SrcIn end
          if c.SrcOut then
            clip.SrcOut = c.SrcOut - (item.DestOut-v)
            c.SrcIn = clip.SrcOut
          end
          table.insert(newitem.Clips, clip)
        end
        newitem.DestIn = item.DestIn
        newitem.DestOut = v
        
        table.insert(CommonEDL, newitem)
        item.DestIn = v
      end
    end

  end
  --[[
  msg('\nEDL')
  table.sort(CommonEDL, function(a,b) return (a.DestIn < b.DestIn) end)
  for i=1, #CommonEDL do
    local item = CommonEDL[i] 
    --if item.DestIn == BugTIME then
    if item.DestIn > 60 then break end
    msg('\nitem  '..i ..'  '..item.Type)
    msg('In/Out '..reaper.format_timestr_pos(item.DestIn,'',5) ..' - '.. reaper.format_timestr_pos(item.DestOut,'',5))
      for j, clip in ipairs(item.Clips) do
        local srcIn = reaper.format_timestr_pos(clip.SrcIn,'',5)
        local srcOut = reaper.format_timestr_pos(clip.SrcOut,'',5)
        msg(srcIn..' - '..srcOut..'  '..tostring(clip.name))
      end
    --end
  end
  ]]
  
  --Then find items with equal timing and combine Clip lists, remove excess items. 
  for i=1, #CommonEDL-1 do
    local item = CommonEDL[i]
    local n = #CommonEDL
    while n > i do
      local testitem = CommonEDL[n]
      
      if item.DestIn == testitem.DestIn and item.DestOut == testitem.DestOut then
         
        for j, tc in ipairs(testitem.Clips) do
          local add = true
          for k, c in ipairs(item.Clips) do
          
            local srcinDiff, srcoutDiff = 1, 1 --any big enough value
            if tc.SrcIn and c.SrcIn and tc.SrcOut and c.SrcOut then
              srcinDiff = math.abs(tc.SrcIn - c.SrcIn)
              srcoutDiff = math.abs(tc.SrcOut - c.SrcOut)
            end
            
            if tc.name == c.name
            and not tc.SrcIn and not c.SrcIn and not tc.SrcOut and not c.SrcOut then
              add = false
              break
            elseif tc.name == c.name and srcinDiff < MIN_luft_ZERO and srcoutDiff < MIN_luft_ZERO then
              add = false
              break
            end
            
          end
          if add == true then table.insert(item.Clips, copy(tc)) end
        end
        table.remove(CommonEDL, n)
      end
      n = n-1
    end
  end
  
  --Remove clips with nil name
  for i, item in ipairs(CommonEDL) do
    local c = #item.Clips
    while c > 0 do
      local clip = item.Clips[c]
      if clip.name == nil then table.remove(item.Clips, c) end
      c = c-1
    end
  end
  
  table.sort(CommonEDL, function(a,b) return (a.DestIn < b.DestIn) end)
  
  --ADD ITEMS WITH EMPTY "CLIPS" TABLE FOR GAPS IF ANY
  
  
  --[[
  msg('\nEDL size is - '..#CommonEDL) msg('')
  ---TEST MESSAGE----
  for i, item in ipairs(CommonEDL) do
    if item.DestIn > 95 then break end
    --if item.DestIn == BugTIME then
    msg('ITEM '..i) --..' '..item.Type) 
    msg('In/Out '..reaper.format_timestr_pos(item.DestIn,'',5) ..' - '.. reaper.format_timestr_pos(item.DestOut,'',5))
    for j, clip in ipairs(item.Clips) do
      local srcIn = reaper.format_timestr_pos(clip.SrcIn,'',5)
      local srcOut = reaper.format_timestr_pos(clip.SrcOut,'',5)
      msg(srcIn..' - '..srcOut..'  '..tostring(clip.name))
    end
    --end
  end
  -------------------
  ]]

end

-------------------------
-------------------------

function CompareEDLs(OLD, NEW)
  local DiffT = {}
  local CandidatesGroups ={}
  
  local oldLeadEmpty
  local newLeadEmpty
  TrimOldEmpty = 0
  TrimNewEmpty = 0
  
  if #OLD[1]['Clips'] == 0 then oldLeadEmpty = OLD[1]['DestOut']
  else oldLeadEmpty = OLD[1]['DestIn']
  end
  
  if #NEW[1]['Clips'] == 0 then newLeadEmpty = NEW[1]['DestOut']
  else newLeadEmpty = NEW[1]['DestIn']
  end
  
  if oldLeadEmpty
  and old_TrimLeadingTime == true and old_TrimOnlyEmptyTime == true
  and oldLeadEmpty >= reaper.parse_timestr_pos( TrimOldTime, 5 ) - PrjTimeOffset then
    TrimOldEmpty = oldLeadEmpty - math.fmod(oldLeadEmpty / (reaper.parse_timestr_pos(TrimOldTime, 5)-PrjTimeOffset) )
  end
  
  if newLeadEmpty
  and new_TrimLeadingTime == true and new_TrimOnlyEmptyTime == true
  and newLeadEmpty >= reaper.parse_timestr_pos( TrimNewTime, 5 ) then
    TrimNewEmpty = newLeadEmpty - math.fmod(newLeadEmpty / (reaper.parse_timestr_pos(TrimNewTime, 5)-PrjTimeOffset) )
  end
  
  ------
  local function compare_items(newitem, olditem, oi, ni)
    local diffItem = {idxnew, idxold, rate, pos, length, offset, side}
    
    if TrimOldEmpty > olditem.DestIn then return end
    if TrimNewEmpty > newitem.DestIn then return end
    --[[
    if newitem.DestIn == BugTIME then
      msg('\n'..#newitem.Clips)
    end]]
    
    if #newitem.Clips == 0 and #olditem.Clips == 0 then --Item is total black/empty
      --Consider them as matched if they lengthes are equal
      if math.abs((newitem.DestOut - newitem.DestIn) - (olditem.DestOut - olditem.DestIn)) < MIN_luft_ZERO then
        diffItem.idxnew = ni
        diffItem.idxold = oi
        diffItem.rate = 1
        diffItem.pos = newitem.DestIn - TrimNewEmpty
        diffItem.length = newitem.DestOut - newitem.DestIn
        diffItem.offset = olditem.DestIn - TrimOldEmpty
        return diffItem
      else return
      end
    end
    if #newitem.Clips < #olditem.Clips then return end
    
    local possXFlag
    if #newitem.Clips == #olditem.Clips * 2 then possXFlag = true end
    if #newitem.Clips > #olditem.Clips and possXFlag ~= true then return end
     
    local diff1, diff2
    local len1, len2
    local difCount = {}
    local clipVariants = {}
    --
    if newitem.DestIn == BugTIME then
      msg('\n     ITEM CLIPS   '..#newitem.Clips.. '  '.. #olditem.Clips)
    end
    
    for oc, oldClip in ipairs(olditem.Clips) do
    --
      if newitem.DestIn == BugTIME then
        msg('\nOldClip   '..oldClip.name)
        msg(tostring(oldClip.SrcIn)..' - '.. tostring(oldClip.SrcOut))
      end
      for nc, newClip in ipairs(newitem.Clips) do
        local path, file, ext
        if oldClip.name then path, file, ext = SplitFilename(oldClip.name) end
        --
        if newitem.DestIn == BugTIME then
          msg('NewClip   '..newClip.name)
          msg(tostring(newClip.SrcIn)..' - '.. tostring(newClip.SrcOut))
        end
        
        if oldClip.name == newClip.name then 
          local diff, len
          --msg(type(path)..path) msg(type(file)..file) msg(type(ext)..ext) msg('')
          if file == ext then --or not oldClip.name
          --
            if newitem.DestIn == BugTIME then
              msg('file == ext')
              msg('NI  '..newitem.DestOut.." - "..newitem.DestIn)
              msg('OI  '..olditem.DestOut.." - "..olditem.DestIn)
            end
            
            --Old clip is in/out black or graphic/effect - there is no sense to compare src timings
            --Consider them as matched if they lengthes are equal
            if math.abs((newitem.DestOut - newitem.DestIn) - (olditem.DestOut - olditem.DestIn)) < MIN_luft_ZERO then
              diff = 0
              len = newitem.DestOut - newitem.DestIn
              table.insert(clipVariants, {diff, len, nc})
              
              if #difCount == 0 then
                table.insert(difCount, {diff})
              else
                local isMatched
                for i, v in ipairs(difCount) do
                  if v[1] == diff then
                    table.insert(v, diff)
                    isMatched = true
                  end 
                end
                if not isMatched then table.insert(difCount, {diff}) end
              end
            --else return
            end
            --break
          else
          --
            if newitem.DestIn == BugTIME then
              msg(tostring(oldClip.SrcIn < newClip.SrcOut)..'  '..tostring(oldClip.SrcOut > newClip.SrcIn))
            end
            if oldClip.SrcIn < newClip.SrcOut and oldClip.SrcOut > newClip.SrcIn then 
              diff = newClip.SrcIn - oldClip.SrcIn
              --Round diff to frames is there is any inaccuracy
              diff = reaper.parse_timestr_pos( reaper.format_timestr_pos(diff,'',5) , 5)
              
              --if newitem.DestIn == BugTIME then msg('diff found  '..diff) end
              
              len = math.min(newClip.SrcOut, oldClip.SrcOut) - math.max(newClip.SrcIn, oldClip.SrcIn)
              
              --If clips order is messed we need to find the most frequently matched src time difference
              --Accumulate dif-s, len-s and nc into a table
              if len >= MIN_luft_ZERO then
                table.insert(clipVariants, {diff, len, nc})
                
                local isMatched
                for i, v in ipairs(difCount) do
                  if v[1] == diff then
                    table.insert(v, diff)
                    isMatched = true
                  end
                end
                if not isMatched then table.insert(difCount, {diff}) end
                
              end -- end of if len >= MIN_luft_ZERO
               
            end
          end
          --
          if newitem.DestIn == BugTIME then
            msg(diff)
            msg(len)
          end
        else
          --PASTE HERE ASSUMPTION OF VFX if new name include the old one.
        end  --if oldClip.name == newClip.name
        
      end --new clips cycle
    end --old clips cycle
    
    --Choose the most corresponding diff-s and len-s 
    if #clipVariants == 0 then return end --if src time range doesn't match
    
    table.sort(difCount, function (a,b) return #a > #b end )
    
    if not possXFlag and #difCount[1] < #newitem.Clips then return end --Hard matching, all old clips have 1 match
    if possXFlag and #difCount[1] < #newitem.Clips / 2 then return end
    
    --if newitem.DestIn == BugTIME then msg('difcnt' ..tostring(#difCount)) end
    diff1 = difCount[1][1]
    
    if #difCount > 1 then
    
      --if newitem.DestIn == BugTIME then msg('XFLAG' ..tostring(possXFlag)) end
      if possXFlag == true then
        --if newitem.DestIn == BugTIME then msg('difcnt' ..tostring(#difCount[1])..'  '..tostring(#difCount[2])) end
        if #difCount[1] == #difCount[2]
        and #difCount[1] + #difCount[2] == #newitem.Clips then
          diff2 = difCount[2][1]
        else return
        end
      end
    end 
    
    for i, v in ipairs(clipVariants) do
      if diff1 and v[1] == diff1 then
        len1 = v[2] 
      end
      if diff2 and v[1] == diff2 then
        len2 = v[2] 
      end
    end
     
    local ret1, ret2
    
    diffItem.idxnew = ni
    diffItem.idxold = oi
    
    if diff1 then
      diffItem.rate = len1 / (newitem.DestOut - newitem.DestIn)
      diffItem.length = len1
      diffItem.pos = newitem.DestIn - math.min(diff1, 0) - TrimNewEmpty
      diffItem.offset = olditem.DestIn + math.max(diff1, 0) - TrimOldEmpty
      if diff1 and diff2 then diffItem.side = diff1 < diff2 end
      ret1 = copy(diffItem)
    end
    
    if diff2 then
      diffItem.rate = len2 / (newitem.DestOut - newitem.DestIn)
      diffItem.length = len2
      diffItem.pos = newitem.DestIn - math.min(diff2, 0) - TrimNewEmpty
      diffItem.offset = olditem.DestIn + math.max(diff2, 0) - TrimOldEmpty
      diffItem.side = diff1 > diff2
      ret2 = copy(diffItem)
    end
    
    --message--
    if ret1 then
      if newitem.DestIn == BugTIME then
        msg('oldIDX  ' ..oi)
        msg('newIDX  ' ..ni)
      end
    end
    ---
    
    return ret1, ret2
  end --end of compare_items()
  ------
  
  --Create and add diffItems in table with candidates groups
  for ni, newitem in ipairs(NEW) do
    local CandGroup = {}
    
    for oi, olditem in ipairs(OLD) do
      local ret, ret2 = compare_items(newitem, olditem, oi, ni)
      if ret then table.insert(CandGroup, ret) end
      if ret2 then table.insert(CandGroup, ret2) end
    end
    
    if #CandGroup > 0 then table.insert(CandidatesGroups, CandGroup) end
  end
  
  
  --Analyse table with candidates groups
  for g, CandGroup in ipairs(CandidatesGroups) do -- calculate rates
    if #CandGroup > 1 then
    
      for c, diffItem in ipairs(CandGroup) do
        local i = 1
        local stop
        local missXPup = 2
        local missXPdown = 2
        
        while not stop do
          if missXPup > 0 then
            local newitem = NEW[diffItem.idxnew +i]
            local olditem = OLD[diffItem.idxold +i]
            
            if newitem and olditem then
              local ret, ret2 = compare_items(newitem, olditem)
              
              if ret and not ret2 then
                diffItem.rate = diffItem.rate + ret.rate
              elseif ret and ret2 then
                diffItem.rate = diffItem.rate + (ret.rate + ret2.rate)/2
              else missXPup = missXPup -1
              end
            else
              missXPup = 0
            end
          end
          
          
          if missXPdown > 0 then
            local newitem = NEW[diffItem.idxnew -i]
            local olditem = OLD[diffItem.idxold -i]
            
            if newitem and olditem then
              local ret, ret2 = compare_items(newitem, olditem)
              
              if ret and not ret2 then
                diffItem.rate = diffItem.rate + ret.rate
              elseif ret and ret2 then
                diffItem.rate = diffItem.rate + (ret.rate + ret2.rate)/2
              else missXPup = missXPdown -1
              end
            else
              missXPdown = 0
            end
          end
          
          if missXPup == 0 and missXPdown == 0 then stop = true end
          i = i+1
        end -- end of while
        
        --
        --MESSAGE--
        local olditem = OLD[diffItem.idxold]
        local newitem = NEW[diffItem.idxnew]
        
        if newitem.DestIn == BugTIME then
          msg('\n '..c..'  DIFF  '.. diffItem.pos)
          msg('rate  ' ..diffItem.rate)
          msg('length  ' ..diffItem.length)
          msg('  '..diffItem.idxold..' OLDitem  ' ..olditem.DestIn..' - '..olditem.DestOut)
          for i, clip in ipairs(olditem.Clips) do
            local stpos = reaper.format_timestr_pos(clip.SrcIn, '', 5)
            local endpos = reaper.format_timestr_pos(clip.SrcOut, '', 5)
            msg(stpos.. ' - '.. endpos.. '  ' ..clip.name)
          end
          
          msg(' ' ..diffItem.idxnew..' NEWitem  ' ..newitem.DestIn..' - '..newitem.DestOut)
          for i, clip in ipairs(newitem.Clips) do
            local stpos = reaper.format_timestr_pos(clip.SrcIn, '', 5)
            local endpos = reaper.format_timestr_pos(clip.SrcOut, '', 5)
            msg(stpos.. ' - '.. endpos.. '  ' ..clip.name)
          end
        end
        ---------
        
      end -- diffItem's cycle
      
    end
  end
  
  
  --msg('\nCompare Rates')
  for g, CandGroup in ipairs(CandidatesGroups) do -- compare rates
    local candToDel = {}
    
    for c = 1, #CandGroup -1 do
      local diffItem_1 = CandGroup[c]
      if FieldMatch(candToDel, c) == false then
         
        for c2 = c+1, #CandGroup do 
          if FieldMatch(candToDel, c2) == false then
            local diffItem_2 = CandGroup[c2]
            
            --msg--
            if diffItem_1.pos == BugTIME then
              msg('\n '..c..'  diff  '.. diffItem_1.pos)
              msg(' '..c2..'  diff  '.. diffItem_2.pos)
              local olditem_1 = OLD[diffItem_1.idxold]
              local newitem_1 = NEW[diffItem_1.idxnew]
              msg(diffItem_1.pos..' - '.. (diffItem_1.pos + diffItem_1.length))
              msg(diffItem_2.pos..' - '.. (diffItem_2.pos + diffItem_2.length))
              
              msg(diffItem_1.pos + diffItem_1.length - diffItem_2.pos)
            end
            -------
            
            if diffItem_2.pos + diffItem_2.length - diffItem_1.pos > MIN_luft_ZERO
            and diffItem_1.pos + diffItem_1.length - diffItem_2.pos > MIN_luft_ZERO
            and diffItem_1.side == diffItem_2.side then
              --msg--
              if diffItem_1.pos == BugTIME then
                msg('compare') 
              end
              ------
            
              if diffItem_1.rate < diffItem_2.rate then table.insert(candToDel, c) break end
              if diffItem_1.rate > diffItem_2.rate then table.insert(candToDel, c2) end 
            end
          end
        end
        
      end
    end
    
    table.sort(candToDel, function(a,b) return (b < a) end)
    --msg(#CandGroup)
    for i, v in ipairs(candToDel) do
    --[[
      msg('---candidat for del---  '..v)
      msg(CandGroup[v]['rate'])
      msg( reaper.format_timestr_pos(CandGroup[v]['pos'],'',5) )
      msg( reaper.format_timestr_pos(CandGroup[v]['length'],'',5) )
      msg(CandGroup[v]['side'])
      msg('---')
      ]]
      table.remove(CandGroup, v) 
    end
    --msg(#CandGroup) msg('')
  end
  
  for g, CandGroup in ipairs(CandidatesGroups) do --extract good candidates to DiffT
    for c, diffItem in ipairs(CandGroup) do
      --[[
      --MESSAGE--
      --diffItem = {idxnew, idxold, rate, pos, length, offset, side}
      --if diffItem.DestIn == BugTIME then
        msg('\n   diffItem  '..g ..' '..c ..'   '..diffItem.pos..' - ' .. diffItem.pos + diffItem.length)
        msg('New Time  '..NEW[diffItem.idxnew]['DestIn']..' - '..NEW[diffItem.idxnew]['DestOut'])
        msg('Old Time  '..OLD[diffItem.idxold]['DestIn']..' - '..OLD[diffItem.idxold]['DestOut'])
        for _, clip in ipairs(NEW[diffItem.idxnew]['Clips']) do
          local newclipName = clip.name
          local newclipSrcIn = clip.SrcIn
          local newclipSrcOut = clip.SrcOut
          --msg('newclip  '..tostring(newclipSrcIn) ..' - '.. tostring(newclipSrcOut)..' '..tostring(newclipName))
          if newclipSrcIn and newclipSrcOut then
            newclipSrcIn = reaper.format_timestr_pos(newclipSrcIn,'',5)
            newclipSrcOut = reaper.format_timestr_pos(newclipSrcOut,'',5)
            --msg('newclip  '..newclipSrcIn ..' '.. newclipSrcOut..' '..tostring(newclipName))
          end
        end
        
        for _, clip in ipairs(OLD[diffItem.idxold]['Clips']) do
          local oldclipName = clip.name
          local oldclipSrcIn = clip.SrcIn
          local oldclipSrcOut = clip.SrcOut
          --msg('oldclip  '..tostring(oldclipSrcIn) ..' - '.. tostring(oldclipSrcOut)..' '..tostring(oldclipName))
          if oldclipSrcIn and oldclipSrcOut then
            oldclipSrcIn = reaper.format_timestr_pos(oldclipSrcIn,'',5)
            oldclipSrcOut = reaper.format_timestr_pos(oldclipSrcOut,'',5)
            --msg('oldclip  '..oldclipSrcIn ..' '.. oldclipSrcOut..' '..tostring(oldclipName))
          end
        end
        
      --end
      ---------------
      ]]
      --[[
      local olditem = OLD[diffItem.idxold]
      local newitem = NEW[diffItem.idxnew]
      if newitem.DestIn == BugTIME then
        msg('Choosen diff item at  '..diffItem.pos)
      end
      --]]
      
      local item = {} -- areaStart, areaEnd, targetPosition
      item[1] = round(diffItem.offset, 6)
      item[2] = round(diffItem.offset, 6) + round(diffItem.length, 6)
      item[3] = round(diffItem.pos, 6)
      table.insert(DiffT, item)
    end
  end
  
  table.sort(DiffT, function(a,b) return ( a[3] + (a[2]-a[1]) < b[3] + (b[2]-b[1]) ) end) 
  Opt = {}
  Opt.HealGaps = false Opt.HealSplits = true
  --[[
  msg('\n DiffT')
  for i, v in ipairs(DiffT) do
    msg('\n'.. v[3])
    msg( v[1]..' - '..  v[2] )
    --msg( v[3]..' - '.. v[3] + v[2] - v[1] )
  end]]
  
  CleanUpRefItems(DiffT)
  --[[
  msg('\n cleaned DiffT')
  for i, v in ipairs(DiffT) do
    msg( v[3]..' - '.. v[3] + v[2] - v[1] )
  end]]
  
  return DiffT
end

-------------------------
-------------------------

function CreateReportMarkers()
  SetOptGlobals()
  
  if not NewPrjStart then
    reaper.ShowMessageBox('Set the point where reconformed version starts', 'Simple Project Reconform', 0)
    return
  end
  
  local refItems = CollectSelectedItems()
  local tag = ' - SPReconform'
  
  if Opt.HealGaps == true or Opt.HealSplits == true then
    CleanUpRefItems(refItems)
  end
  
  if #refItems == 0 then
    reaper.ShowMessageBox('Please select reference items on a track','Simple Project Reconform', 0)
    return
  end 
  
  if NewPrjStart > refItems[1][3] then
    reaper.ShowMessageBox('New project position can not be later than reference items', 'Simple Project Reconform', 0)
    return
  end
  
  table.sort(Gaps, function (a,b) return (a[1] < b[1]) end )
  
  local track = reaper.GetTrack(0, LastRefTrID)
  local fl = reaper.SetMediaTrackInfo_Value(track, 'I_FREEMODE', 2 )
  local lanesN = reaper.GetMediaTrackInfo_Value(track, 'I_NUMFIXEDLANES')
  --reaper.UpdateTimeline()
  local splits
  local gaps
  local xfades
  
  reaper.SetOnlyTrackSelected(track)
  local splitsTake
  local splcnt = 1
  local xfadecnt = 1
  
  for i, item in ipairs(refItems) do
    local itemPos = item[3]
    local itemEnd = itemPos + item[2] - item[1]
    local prev_itemEnd
    if i>1 then prev_itemEnd = refItems[i-1][3] + refItems[i-1][2] - refItems[i-1][1] end
    
    if itemPos > NewPrjStart or itemPos ~= 0 then -- don't mark as split old project start if start points matched
      if not splits then
        reaper.Main_OnCommandEx(42647,0,0) --Track lanes: Add empty lane at bottom of track
        local splitsItem = reaper.AddMediaItemToTrack(track)
        splitsTake = reaper.AddTakeToMediaItem(splitsItem)
        splits = lanesN 
        lanesN = lanesN +1
        local ret, str = reaper.GetSetMediaTrackInfo_String(track, 'P_LANENAME:'..splits, 'SPLITS', true)
        reaper.SetMediaItemInfo_Value(splitsItem, 'D_POSITION', NewPrjStart)
        reaper.SetMediaItemInfo_Value(splitsItem, 'D_LENGTH', refItems[#refItems][3] + refItems[#refItems][2] - refItems[#refItems][1] - NewPrjStart)
        reaper.SetMediaItemInfo_Value(splitsItem, 'I_FIXEDLANE', splits)
      end
      
      local timetxt = reaper.format_timestr_pos(item[1],'', 5) ..' - '.. reaper.format_timestr_pos(item[2],'', 5)
      reaper.SetTakeMarker(splitsTake, -1, splcnt..' src '..timetxt..tag, itemPos - NewPrjStart)
      splcnt = splcnt +1
    end
    
    if i>1 and prev_itemEnd - itemPos > MIN_luft_ZERO then
      if not xfades then
        reaper.Main_OnCommandEx(42647,0,0) --Track lanes: Add empty lane at bottom of track
        xfades = lanesN
        lanesN = lanesN +1 
        local ret, str = reaper.GetSetMediaTrackInfo_String(track, 'P_LANENAME:'..xfades, 'xFADES', true)
      end
      local xfadeItem = reaper.AddMediaItemToTrack(track)
      local xfadeTake = reaper.AddTakeToMediaItem(xfadeItem)
      reaper.SetMediaItemInfo_Value(xfadeItem, 'D_POSITION', itemPos)
      reaper.SetMediaItemInfo_Value(xfadeItem, 'D_LENGTH', prev_itemEnd - itemPos)
      reaper.SetMediaItemInfo_Value(xfadeItem, 'I_FIXEDLANE', xfades)
      reaper.SetTakeMarker(xfadeTake, -1, 'xfade '..xfadecnt..tag, 0)
      xfadecnt = xfadecnt +1
    end
  end
  
  local gapcnt = 1
  
  for g, gap in ipairs(Gaps) do
    if not gaps then
      reaper.Main_OnCommandEx(42647,0,0) --Track lanes: Add empty lane at bottom of track
      gaps = lanesN
      lanesN = lanesN +1 
      local ret, str = reaper.GetSetMediaTrackInfo_String(track, 'P_LANENAME:'..gaps, 'GAPS', true)
    end
    local gapStart = gap[1]
    local gapEnd = gap[2]
    local gapItem = reaper.AddMediaItemToTrack(track)
    local gapTake = reaper.AddTakeToMediaItem(gapItem)
    reaper.SetMediaItemInfo_Value(gapItem, 'D_POSITION', gapStart)
    reaper.SetMediaItemInfo_Value(gapItem, 'D_LENGTH', gapEnd - gapStart)
    reaper.SetMediaItemInfo_Value(gapItem, 'I_FIXEDLANE', gaps)
    reaper.SetTakeMarker(gapTake, -1, 'gap '..gapcnt..tag, 0)
    gapcnt = gapcnt +1
  end
end

-------------------------

function PasteItemsFromPrj(CurPrj, SrcPrj)
  SetOptGlobals()
  local refItems = CollectSelectedItems()
  
  if Opt.HealGaps == true or Opt.HealSplits == true then
    CleanUpRefItems(refItems)
  end
  
  if #refItems == 0 then
    reaper.ShowMessageBox('Please select reference items on a track','Simple Project Reconform', 0)
    return
  end
  
  if not NewPrjStart then
    reaper.ShowMessageBox('Set the point where reconformed version starts', 'Simple Project Reconform', 0)
    return
  else
    table.insert(Gaps, {NewPrjStart, refItems[1][3]})
  end
  
  local pastedTrks = {}
  local trcntSrc = reaper.CountTracks(SrcPrj)
  
  
  for i = 0, trcntSrc -1 do
    local tr = reaper.GetTrack(SrcPrj, i)
    
    if tracksForImportFlag == 2 then
      if reaper.IsTrackSelected(tr) == false then tr = nil end
    elseif tracksForImportFlag == 3 then
      if reaper.GetMediaTrackInfo_Value(tr, 'B_MUTE') == 1 then tr = nil end
    end
    
    if tr then
      local ret, chunk = reaper.GetTrackStateChunk(tr,'',false)
      reaper.InsertTrackAtIndex( LastRefTrID + #pastedTrks, false )
      local newtr = reaper.GetTrack(CurPrj, LastRefTrID + #pastedTrks)
      reaper.SetTrackStateChunk( newtr, chunk, true )
      table.insert(pastedTrks, newtr)
    end
  end
  
  for t, tr in ipairs(pastedTrks) do
    local itemsToDelete = {}
    local icnt = reaper.CountTrackMediaItems(tr) -1
    
    while icnt >= 0 do
      local item = reaper.GetTrackMediaItem(tr, icnt) 
      local iPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
      local iEnd = iPos + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
      
      for g, gap in ipairs(Gaps) do
        if (iEnd + NewPrjStart) - gap[1] > 0.005 and gap[2] - (iPos + NewPrjStart) > 0.005 then
          reaper.SetMediaItemInfo_Value(item, 'D_POSITION', iPos + NewPrjStart)
          break
        end
      end
      local newiPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
      --msg( newiPos..' '..iPos)
      if newiPos == iPos then table.insert(itemsToDelete, item) end
      
      icnt = icnt -1
    end
    
    for i, item in ipairs(itemsToDelete) do reaper.DeleteTrackMediaItem(tr, item) end
    
  end
  
  reaper.Main_OnCommandEx(40297,0,CurPrj) --Track: Unselect (clear selection of) all tracks
  for t, tr in ipairs(pastedTrks) do
    if reaper.CountTrackMediaItems(tr) == 0 then
      reaper.DeleteTrack(tr)
    else reaper.SetTrackSelected(tr, true)
    end
  end
end

----------------------------
-------------------------

function CollectSelectedItems(TableToAdd,areaStart,areaEnd)
  local ItemsTable = {}
  Gaps = {}
  LastRefTrID = 0
  
  if type(TableToAdd) == 'table' then
    ItemsTable = TableToAdd
  end
  
  if not OldPrjStart then OldPrjStart = 0 end
  
  local prevEnd = NewPrjStart
  local selItNumb = reaper.CountSelectedMediaItems(0)
  for i = 0, selItNumb - 1 do
    local item = reaper.GetSelectedMediaItem(0,i) 
    local take = reaper.GetActiveTake(item)
    local refPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local refLength = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    
    if areaStart and areaEnd then
      if refPos > areaEnd or refPos + refLength < areaStart then take = nil end
    end
    
    if take then
      local src =  reaper.GetMediaItemTake_Source( take )
      local srctype = reaper.GetMediaSourceType( src )
      if srctype ~= 'EMPTY' and srctype ~= 'MIDI' then
        local offset = reaper.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS') + OldPrjStart
        table.insert(ItemsTable, {offset, offset + refLength, refPos})
        
        local tr = reaper.GetMediaItem_Track(item)
        local trID = reaper.GetMediaTrackInfo_Value( tr, 'IP_TRACKNUMBER' ) -1
        
        if LastRefTrID < trID then LastRefTrID = trID end
        
        if prevEnd then
          if refPos - prevEnd > MIN_luft_ZERO then
            table.insert(Gaps, {prevEnd, refPos})
          end
        end
        
        prevEnd = refPos + refLength
      end
    end
    
  end
  return ItemsTable
end

-----------------------------
function round(value, digitsAfterDot) 
  return tonumber(string.format("%."..digitsAfterDot.."f", tostring(value)))
end

-----------------------------
function CleanUpRefItems(Items)
  local i = #Items
  while i>1 do
  --
    local areaStart = round(Items[i][1], 4)
    local areaEnd = round(Items[i][2], 4)
    local targetPos = round(Items[i][3], 4)
    
    local prevAstart = round(Items[i-1][1], 4)
    local prevAend = round(Items[i-1][2], 4)
    local prevTpos = round(Items[i-1][3], 4)
    --[[
    local areaStart = Items[i][1]
    local areaEnd = Items[i][2]
    local targetPos = Items[i][3]
    
    local prevAstart = Items[i-1][1]
    local prevAend = Items[i-1][2]
    local prevTpos = Items[i-1][3]
    ]]
    if Opt.HealGaps == true then
      if  math.abs( (areaStart - (targetPos - prevTpos)) - prevAstart ) < MIN_luft_ZERO then
        Items[i-1][2] = areaEnd
        table.remove(Items,i)
      end
    elseif Opt.HealSplits == true then 
      if math.abs( targetPos - (prevTpos + (prevAend - prevAstart)) ) < MIN_luft_ZERO
      and areaStart == prevAend then
        Items[i-1][2] = areaEnd
        table.remove(Items,i)
      end
    end
    
    i = i - 1
  end
end

-----------------------------
function AdjustRefItems(Items) --adjusts virtual ref items, real track in prj will be safe
  local i = #Items
  while i>0 do
    local areaStart = Items[i][1]
    --local areaEnd = Items[i][2]
    local targetPos = Items[i][3]
    local prevAstart
    local prevAend
    local prevTpos
    
    local prevItemEnd
    
    if i==1 then
      if NewPrjStart then prevItemEnd = NewPrjStart
      else break
      end
    else
      prevAstart = Items[i-1][1]
      prevAend = Items[i-1][2]
      prevTpos = Items[i-1][3]
      
      prevItemEnd = prevTpos + (prevAend - prevAstart)
    end
    
    if prevItemEnd < targetPos then
      if Opt.FillGaps == 'left region' and i ~= 1 then 
        Items[i-1][2] = prevAend + (targetPos - prevItemEnd)
      elseif Opt.FillGaps == 'right region' then
        Items[i][1] = math.max(areaStart - (targetPos - prevItemEnd), 0)
        Items[i][3] = targetPos - (areaStart - Items[i][1] )
      end
    end
    
    if prevItemEnd > targetPos and i ~= 1 then
      if Opt.IgnoreCrossfades == 'left region' then
        Items[i][1] = areaStart + (prevItemEnd - targetPos)
        Items[i][3] = prevItemEnd
      elseif Opt.IgnoreCrossfades == 'right region' then
        Items[i-1][2] = areaStart
      end
    end
    
    i = i - 1
  end
end

-----------------------------

function SetMasterREarea(areaStart, areaEnd)
  local timeString = tostring(areaStart) ..' '.. tostring(areaEnd) ..' '
  
  local track = reaper.GetMasterTrack(0)
  local envcnt = reaper.CountTrackEnvelopes(track)
  local string = ''
  local focused
  for e = 0, envcnt -1 do
    local env = reaper.GetTrackEnvelope(track, e)
    local _, envName = reaper.GetEnvelopeName( env )
    if envName ~= 'Tempo map' then
      if focused ~= true then
        reaper.SetCursorContext( 2, env )
        focused = true
      end
      local  ret, GUID = reaper.GetSetEnvelopeInfo_String( env, 'GUID', '', false )
      string = string .. ' '.. timeString .. ' "'..GUID..'"'
    end
  end
  local ret, string = reaper.GetSetMediaTrackInfo_String( track, 'P_RAZOREDITS', string, true )
  --msg(string)
  
end
-----------------------------

function SetREarea(areaStart, areaEnd)
  local trcnt = reaper.CountTracks(0)
  local timeString = tostring(areaStart) ..' '.. tostring(areaEnd) ..' '
  
  for i = LastRefTrID +1, trcnt -1 do
    local track = reaper.GetTrack(0,i)
    local envcnt = reaper.CountTrackEnvelopes(track)
    --msg(envcnt)
    local string = timeString..'""'
    --[[
    for e = 0, envcnt -1 do
      local env = reaper.GetTrackEnvelope(track, e)
      local  ret, GUID = reaper.GetSetEnvelopeInfo_String( env, 'GUID', '', false )
      string = string .. ' '.. timeString .. ' "'..GUID..'"'
    end]]
    local ret, _ = reaper.GetSetMediaTrackInfo_String( track, 'P_RAZOREDITS', string, true )
    --msg(ret)
  end
  
end

-----------------------------
function CopyTempo(areaStart, areaEnd, pasteTarget)
  --first need to clean target place if there are some TimeSign markers
  local timeMarkToDel = pasteTarget + areaEnd - areaStart
  while timeMarkToDel > pasteTarget do
   local markToDel = reaper.FindTempoTimeSigMarker( 0, timeMarkToDel - 0.002 )
    _, timeMarkToDel, _, _, _, _, _, _ = reaper.GetTempoTimeSigMarker(0, markToDel )
    if timeMarkToDel > pasteTarget then  reaper.DeleteTempoTimeSigMarker( 0, markToDel ) end
  end
  
  -- Now we can copy from source
  local start_num, start_denom, startTempo = reaper.TimeMap_GetTimeSigAtTime( 0, areaStart )
  local end_num, end_denom, endTempo = reaper.TimeMap_GetTimeSigAtTime( 0, areaEnd )
  local _, metr = reaper.TimeMap_GetMetronomePattern( 0, areaEnd, "EXTENDED" )
  local pointTime = areaEnd
  local PointsTable = {}
  local exact = false
  
  table.insert(PointsTable, {
  Time = areaEnd-areaStart, Measure = -1, Beat = -1, BPM = endTempo,
  Tsign_num = end_num, Tsign_denom = end_denom, islinear = false, metr }) 
  
  while pointTime >= areaStart do
    local p = {}
    local point = reaper.FindTempoTimeSigMarker( 0, pointTime )
    local ret
    ret, p.Time, p.Measure, p.Beat, p.BPM, p.Tsign_num, p.Tsign_denom, p.islinear = reaper.GetTempoTimeSigMarker(0, point )
    pointTime = p.Time - 0.002  --2 ms to avoid infinity cycle
    --msg(p.Tsign_num ..' '.. p.Tsign_denom ..' '.. tostring(p.islinear))
    _, p.metr = reaper.TimeMap_GetMetronomePattern( 0, p.Time + 0.002, "EXTENDED" )
    p.Measure = -1
    p.Beat = -1 
    p.Time = p.Time - areaStart  --relative position
    p.flag = reaper.GetSetTempoTimeSigMarkerFlag( 0, point, 0, false ) 
    
    if p.Time == 0 then exact = true end
    if p.Time >= 0 then table.insert(PointsTable, p) end
  end
  
  
  if exact == false then
    local p = {}
    local point = reaper.FindTempoTimeSigMarker( 0, areaStart )
    local ret
    ret, _, _, _, _, _, _, p.islinear = reaper.GetTempoTimeSigMarker(0, point )
    _, p.metr = reaper.TimeMap_GetMetronomePattern( 0, areaStart + 0.002, "EXTENDED" )
    p.Time = 0 --relative position
    p.Measure = -1
    p.Beat = -1
    p.BPM = startTempo
    p.Tsign_num = start_num
    p.Tsign_denom = start_denom
    p.flag = reaper.GetSetTempoTimeSigMarkerFlag( 0, point, 0, false )
    table.insert(PointsTable, p)
  end
  
  --for i, v in pairs(PointsTable) do msg(v.Time) end

  local pNumb = #PointsTable
  
  while pNumb > 0 do
    local p = PointsTable[pNumb]
    
    local set = reaper.SetTempoTimeSigMarker
    (0, -1, p.Time + pasteTarget, p.Measure, p.Beat, p.BPM, p.Tsign_num, p.Tsign_denom, p.islinear )
    if set then
      local newidx = reaper.FindTempoTimeSigMarker( 0, p.Time + pasteTarget + 0.002 )
      if p.flag then _ = reaper.GetSetTempoTimeSigMarkerFlag( 0, newidx, p.flag, true ) end
      if p.metr then
        p.metr = "SET:".. p.metr
        _,_ = reaper.TimeMap_GetMetronomePattern( 0, p.Time + 0.002, p.metr )
      end
    end
    pNumb = pNumb-1
  end
end
-----------------------------

function CopyMarkers(areaStart, areaEnd, pasteTarget)
  local destAreaEnd = pasteTarget + areaEnd - areaStart
  local ret, mcnt, rcnt = reaper.CountProjectMarkers(0)
  local i = ret -1
  while i >= 0 do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)

    if Opt.ReconfMarkers == true and isrgn == false then
      if pos > areaStart and pos < areaEnd then
        local newplace = pasteTarget + pos - areaStart 
        reaper.AddProjectMarker2( 0, isrgn, newplace, rgnend, name, -1, color )
      elseif pos > pasteTarget and pos < destAreaEnd then
        reaper.DeleteProjectMarkerByIndex(0, i)
      end
    end
    
    i = i-1
    
    if Opt.ReconfRegions == true and isrgn == true then
      if pos < areaEnd and rgnend > areaStart then 
        local newplace = math.max(pasteTarget + pos - areaStart, pasteTarget)
        local newrgnend = math.min((pasteTarget + pos - areaStart) + (rgnend - pos), destAreaEnd)
        if not Regions[tostring(markrgnindexnumber)] then
          Regions[tostring(markrgnindexnumber)] = {}
        end
        table.insert(Regions[tostring(markrgnindexnumber)], {newplace, newrgnend, name, color})
      end
      --Here needs to clean place if it's not empty.
      if pos <= destAreaEnd and rgnend > pasteTarget then
        if rgnend > destAreaEnd and pos >= pasteTarget then
         reaper.SetProjectMarker2(0, markrgnindexnumber, true, destAreaEnd, rgnend, name)
        end
        if rgnend <= destAreaEnd and pos < pasteTarget then
         reaper.SetProjectMarker2(0, markrgnindexnumber, true, pos, pasteTarget, name)
        end
        if rgnend <= destAreaEnd and pos >= pasteTarget then
          reaper.DeleteProjectMarker( 0, markrgnindexnumber, true )
        end
        if rgnend > destAreaEnd and pos < pasteTarget then
         reaper.SetProjectMarker2(0, markrgnindexnumber, true, pos, pasteTarget, name)
         reaper.AddProjectMarker2( 0, true, destAreaEnd, rgnend, name, -1, color )
        end
      end 
    end
    
  end
end
-----------------------------

function CreateRegions(refItemsT)
  --Clean up table
  for i, v in pairs(Regions) do
    local r = #v
    while r > 1 do
      local rgnPos = v[r][1]
      local rgnEnd = v[r][2]
      local prevEnd = v[r-1][2]
      if Opt.ReduceGapsRegions == true then
        Regions[i][r-1][2] = rgnEnd
        table.remove(Regions[i], r)
      else
        if rgnPos <= prevEnd then
          Regions[i][r-1][2] = rgnEnd
          table.remove(Regions[i], r)
        end
      end
      r = r-1
    end
  end
  
  --Create regions
  for i, v in pairs(Regions) do
    for k, r in ipairs(v) do
      local idx = reaper.AddProjectMarker2( 0, true, r[1], r[2], r[3], -1, r[4] )
      Regions[i][k][5] = idx
    end
  end
  
  --Heal splits between simillary named regions
  local areaStart = refItemsT[1][3]
  local areaEnd = refItemsT[#refItemsT][3] + refItemsT[#refItemsT][2] - refItemsT[#refItemsT][1]
  local ret, mcnt, rcnt = reaper.CountProjectMarkers(0)

  local m = 0 
  while m < ret do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, m) 
    if math.abs(pos - areaEnd) < 0.0002 or math.abs(rgnend - areaStart) < 0.0002
    and isrgn == true then
      for i, v in pairs(Regions) do
        local r = #v
        while r > 0 do
          local rgnPos = v[r][1]
          local rgnEnd = v[r][2]
          local rgnName = v[r][3]
          local rgnColor = v[r][4] 
          
          if name == rgnName and color == rgnColor then
            if math.abs(pos - areaEnd) < 0.0002 and math.abs(rgnEnd - areaEnd) < 0.0002 then
            --msg('R '..m ..' '.. retval ..' '.. v[r][5])
              reaper.SetProjectMarker2(0, markrgnindexnumber, true, rgnPos, rgnend, name)
              if reaper.DeleteProjectMarker( 0, v[r][5], true ) then

                m = m-1
              end
            elseif math.abs(rgnend - areaStart) < 0.0002 and math.abs(rgnPos - areaStart) < 0.0002 then
            --msg('L '..m ..' '.. retval ..' '.. v[r][5])
              reaper.SetProjectMarker2(0, markrgnindexnumber, true, pos, rgnEnd, name)
              if reaper.DeleteProjectMarker( 0, v[r][5], true ) then
                table.remove(Regions[i],r)
                Regions[tostring(markrgnindexnumber)] = {}
                table.insert(Regions[tostring(markrgnindexnumber)],
                {pos, rgnEnd, name, color, markrgnindexnumber})
                m = m-1
              end
            end
          end --if name...
          
          r = r-1
        end --while r > 0
      end --for in Regions
    end --if edges match
    
   m = m+1
  end --cycle through all markers
  
end
-----------------------------

function SaveAndUnlockItems()
  local parmname = 'P_EXT:'..'SimpleReconf_AZ'..'lock'
  local icnt = reaper.CountMediaItems(0)
  for i = 0, icnt -1 do
    local item = reaper.GetMediaItem(0,i)
    local itemLocked = reaper.GetMediaItemInfo_Value(item, 'C_LOCK')
    if itemLocked == 1 then 
      local ret, str = reaper.GetSetMediaItemInfo_String( item, parmname, tostring(itemLocked), true )
      reaper.SetMediaItemInfo_Value(item, 'C_LOCK', 0)
    end
  end
end

-----------------------------

function RestoreLockedItems()
  local parmname = 'P_EXT:'..'SimpleReconf_AZ'..'lock'
  local icnt = reaper.CountMediaItems(0)
  for i = 0, icnt -1 do
    local item = reaper.GetMediaItem(0,i)
    local ret, str = reaper.GetSetMediaItemInfo_String( item, parmname, tostring(itemLocked), false )
    
    if tonumber(str) == 1 then
      ret, str = reaper.GetSetMediaItemInfo_String( item, parmname, '', true )
      reaper.SetMediaItemInfo_Value(item, 'C_LOCK', 1)
    end
  end
end

-----------------------------

function ToggleDisableLanes(disable) --boolean 
  if disable == false then
    DisLanesTrTable = {}
    CollapsedTrTable = {}
    local trcnt = reaper.CountTracks(0)
    for i = LastRefTrID +1, trcnt -1 do
      local track = reaper.GetTrack(0,i)
      local lanesState = reaper.GetMediaTrackInfo_Value(track, 'C_LANESCOLLAPSED')
      
      if lanesState == 2 then
        table.insert(DisLanesTrTable, track)
        reaper.SetMediaTrackInfo_Value(track, 'C_LANESCOLLAPSED', 1) 
      end
      
      local isFolder = reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1
      local folderState = reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERCOMPACT')
      if isFolder and folderState ~= 0 then
        local t = {}
        t[1] = track
        t[2] = folderState
        table.insert(CollapsedTrTable, t)
        reaper.SetMediaTrackInfo_Value(track, 'I_FOLDERCOMPACT', 0)
      end
      
    end
  else
    for i, track in ipairs(DisLanesTrTable) do
      reaper.SetMediaTrackInfo_Value(track, 'C_LANESCOLLAPSED', 2)
    end
    
    for i, track in ipairs(CollapsedTrTable) do
      reaper.SetMediaTrackInfo_Value(track[1], 'I_FOLDERCOMPACT', track[2])
    end
  end
  
end
-----------------------------

function RemoveExtraPoints(refItems)
  local trCount = reaper.CountTracks(0)
  local transTime = GetPrefs('envtranstime')
  for i = -1, trCount -1 do 
    if i < 0 or i > LastRefTrID then 
      local tr
      if i == -1 then
        tr = reaper.GetMasterTrack(0)
      else
        tr = reaper.GetTrack(0, i)
      end
      local envCount = reaper.CountTrackEnvelopes(tr)
      --msg('\nTrack '..(i+1))
      for e = 0, envCount -1 do
        local env = reaper.GetTrackEnvelope(tr, e)
        local _, name = reaper.GetEnvelopeName(env)
        --msg('\nEnv name  '.. name)
        if name ~= "Tempo map" then
          local pointsToDel = {}
        ----Find Points in gaps
          for k, g in ipairs(Gaps) do
            if g[1] ~= NewPrjStart then
              local leftTime = g[1]
              local rightTime = g[2]
              local idx = reaper.GetEnvelopePointByTimeEx( env, -1, rightTime + 0.0001 )
              local ret, time, value, shape, tension, selected
              time = rightTime
              while time > leftTime do
                ret, time, value, shape, tension, selected = reaper.GetEnvelopePointEx( env, -1, idx )
                if time > leftTime + 0.0001 and time < rightTime - 0.0001 then -- 0.1 ms to avoid some inaccurace 
                  reaper.DeleteEnvelopePointEx( env, -1, idx, true ) 
                end
                idx = idx-1
              end -- points cycle 
            end
          end -- end Gaps cycle
          reaper.Envelope_SortPointsEx( env, -1 )
          
          ----Find extra points at areas borders if they have the same value as others
          local allSplits = {} 
          local prevsplit = 0
          for it, item in ipairs(refItems) do
            local leftTime = item[3]
            local rightTime = item[3] + item[2] - item[1]
            if math.abs(leftTime - prevsplit) > MIN_luft_ZERO then
              FieldMatch(allSplits, leftTime, true)
            end
            FieldMatch(allSplits, rightTime, true)
            prevsplit = rightTime
          end
          
          for s = 2, #allSplits do
            local split = allSplits[s]
            --msg('split '..split)
            local idx = reaper.GetEnvelopePointByTimeEx( env, -1, split  + 0.0001 ) 
            local time, value
            time = split  + 0.0001
            while time > split - transTime - 0.0001 do
              _, time, value, _, _, _ = reaper.GetEnvelopePointEx( env, -1, idx ) 
              if time > split - transTime - 0.0001 then
              --msg(time)
                local _, _, prevvalue, _, _, _ = reaper.GetEnvelopePointEx( env, -1, idx-1 )
                local _, _, nextvalue, _, _, _ = reaper.GetEnvelopePointEx( env, -1, idx+1 )
                --msg('prev '..prevvalue..'   next '..nextvalue)
                if value == prevvalue and value == nextvalue then
                --msg('delete')
                  table.insert(pointsToDel, idx)
                end
              end
              idx = idx-1
            end
          end
          
          ----Remove points---
          table.sort(pointsToDel, function (a,b) return a > b end)
          for p, idx in ipairs(pointsToDel) do
            reaper.DeleteEnvelopePointEx( env, -1, idx, true )
          end
          reaper.Envelope_SortPointsEx( env, -1 )
          
        end -- if not tempo env
      end -- end Env cycle
      
    end --if track is below last reference track
  end --end track cycle
end

-----------------------------

function SeparateEnv()
  EnvsInMediaLane = {}
  
  local trCount = reaper.CountTracks(0)
  for i = -1, trCount -1 do
    local tr
    if i == -1 then
      tr = reaper.GetMasterTrack(0)
    else
      tr = reaper.GetTrack(0, i)
    end
    local envCount = reaper.CountTrackEnvelopes(tr)
    
    for e = 0, envCount -1 do
      local env = reaper.GetTrackEnvelope(tr, e)
      local ret, str = reaper.GetEnvelopeStateChunk( env, '', false )
      local newchunk = ''
      
      if ret then
      
        for s in str:gmatch('[^\n]+') do
          if s:find('VIS') == 1 then
            if s:find('0') then
              table.insert(EnvsInMediaLane, {env, s})
              s = s:gsub('0','1')
            end
          end
          newchunk = newchunk..s..'\n'
        end -- chunk lines cycle
        reaper.SetEnvelopeStateChunk( env, newchunk, true )
      end
      
    end  -- env cycle
    
  end  -- track cycle
end
-----------------------------

function RestoreEnvVis()
  for i, v in pairs(EnvsInMediaLane) do
    local env = v[1]
    local vis = v[2]
    local ret, str = reaper.GetEnvelopeStateChunk( env, '', false )
    local newchunk = ''
    
    if ret then 
      for s in str:gmatch('[^\n]+') do
        if s:find('VIS') == 1 then 
          s = vis
        end
        newchunk = newchunk..s..'\n'
      end
      reaper.SetEnvelopeStateChunk( env, newchunk, true )
    end
    
  end
end
------------------------------

function GetPrefs(key) -- key need to be a string as in Reaper ini file
  local retval, buf = reaper.get_config_var_string( key )
  if retval == true then return tonumber(buf) end
end

-----------------------------

function main()
--return coroutine.create(function()
  ProcessString = 'Initialization'
  --ShowProgress()
  --coroutine.yield(ProcessString)
  SetOptGlobals()
  local editCurPos = reaper.GetCursorPosition()
  Regions = {}
  local refItems = CollectSelectedItems()
  if Opt.HealGaps == true or Opt.HealSplits == true then
    CleanUpRefItems(refItems)
  end
  
  if Opt.IgnoreCrossfades ~= "don't ignore" or Opt.FillGaps ~= "don't fill" then
    AdjustRefItems(refItems)
  end
  
  if #refItems == 0 then
    reaper.ShowMessageBox('Please select reference items on a track','Simple Project Reconform', 0)
    return
  end
  reaper.Undo_BeginBlock2( 0 )
  reaper.PreventUIRefresh( 1 )
  
  ProcessString = 'Preparing'
  --ShowProgress()
  --coroutine.yield(ProcessString)
  
  if Opt.ReconfMaster == true then
    local mtvis = reaper.GetToggleCommandState(40075) --View: Toggle master track visible
    local mtrack = reaper.GetMasterTrack(0)
    local envcnt = reaper.CountTrackEnvelopes(mtrack)
    --msg('envcnt '..envcnt)
    if envcnt > 1 then
      if mtvis == 0 then reaper.Main_OnCommandEx(40075,0,0) end
    else Opt.ReconfMaster = false
    end
  end
  
  if Opt.ReconfLockedItems == true then SaveAndUnlockItems() end
  if Opt.ReconfDisabledLanes == true then ToggleDisableLanes(false) end
  
  local razorAffectsEnvs = reaper.GetToggleCommandState(42459) -- Options: Razor edits in media item lane affect all track envelopes
  if razorAffectsEnvs == 0 then reaper.Main_OnCommandEx(42459, 0, 0) end
  
  reaper.Main_OnCommandEx(reaper.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'),0,0)  --SWS/BR: Focus arrange
  if Opt.ReconfOnlyVis ~= true then
    reaper.Main_OnCommandEx(reaper.NamedCommandLookup('_SWSTL_SHOWALL'),0,0) --SWS: Show all tracks
  end
  reaper.Main_OnCommandEx(41149,0,0) --Envelope: Show all envelopes for all tracks
  SeparateEnv()
  
  local TimeSigCount = 0
  if Opt.ReconfTempo == true then
    TimeSigCount = reaper.CountTempoTimeSigMarkers( 0 )
  end
  
  local splitautoxfade = GetPrefs('splitautoxfade')
  local trimBehRazorFade = splitautoxfade & ~(1<<15)
  trimBehRazorFade = trimBehRazorFade | (1<<6)
  reaper.SNM_SetIntConfigVar( 'splitautoxfade', trimBehRazorFade )
  
  local trimcont = reaper.GetToggleCommandState(41117) --Options: Trim content behind media items when editing
  local trimcontrazor = reaper.GetToggleCommandState(42421)
  --Options: Always trim content behind razor edits (otherwise, follow media item editing preferences)
  
  if trimcont == 1 then reaper.Main_OnCommandEx(41117, 0, 0) end
  if trimcontrazor == 1 then reaper.Main_OnCommandEx(42421, 0, 0) end
  
  local wholeAreaStart = refItems[1][3]
  local wholeAreaEnd = refItems[#refItems][3] + refItems[#refItems][2] - refItems[#refItems][1]
  SetREarea(wholeAreaStart, wholeAreaEnd)
  reaper.Main_OnCommandEx(40697,0,0) --Remove items/tracks/envelope points (depending on focus)
  reaper.Main_OnCommandEx(42406,0,0) --Razor edit: Clear all areas
  
  if TimeSigCount > 1 then
    local prjTempoTimeBase = GetPrefs('tempoenvtimelock') 
    if prjTempoTimeBase ~= 0 then
      local msg = "Timebase for tempo envelope should be set to Time\n"
      .."to avoid of possible effect on the right-hand material.\n\n"
      .."Do you want to set it to Time?"
      local title = "Take care about tempo map!"
      local ret = reaper.ShowMessageBox( msg, title, 3 )
      if ret == 6 then
        reaper.SNM_SetIntConfigVar( 'tempoenvtimelock', 0 )
      elseif ret == 2 then return
      end
    end 
  end
  
   
  for i, item in ipairs(refItems) do --Start reconform cycle 
    ProcessString = "Copying area # " ..i
    --ShowProgress()
    --coroutine.yield(ProcessString)
    local areaStart = item[1]
    local areaEnd = item[2]
    local refPos = item[3]
     
    if TimeSigCount > 1 then
      CopyTempo(areaStart, areaEnd, refPos)
    end
     
    if Opt.ReconfMaster == true then 
      reaper.Main_OnCommandEx(42406,0,0) --Razor edit: Clear all areas
      SetMasterREarea(areaStart, areaEnd)
      reaper.Main_OnCommandEx(40057,0,0)
      --^^Edit: Copy items/tracks/envelope points (depending on focus) ignoring time selection
      reaper.SetEditCurPos2(0, refPos, false, false) 
      reaper.Main_OnCommandEx(42398,0,0) --Item: Paste items/tracks 
    end
    
    reaper.SetOnlyTrackSelected(reaper.GetTrack(0,LastRefTrID +1))
    reaper.Main_OnCommandEx(42406,0,0) --Razor edit: Clear all areas
    SetREarea(areaStart, areaEnd)
    reaper.Main_OnCommandEx(40057,0,0)
    --^^Edit: Copy items/tracks/envelope points (depending on focus) ignoring time selection
    reaper.SetEditCurPos2(0, refPos, false, false)
    reaper.Main_OnCommandEx(42398,0,0) --Item: Paste items/tracks
    
    if Opt.ReconfMarkers == true or Opt.ReconfRegions == true then
      CopyMarkers(areaStart, areaEnd, refPos)
    end
    
  end --End reconform cycle
  
  ProcessString = 'Finishing'
  RemoveExtraPoints(refItems)
  RestoreEnvVis()
  if Opt.ReconfLockedItems == true then RestoreLockedItems() end
  reaper.SelectAllMediaItems(0, false)
  if Opt.ReconfDisabledLanes == true then ToggleDisableLanes(true) end
  
  if Opt.ReconfRegions == true then
    CreateRegions(refItems)
  end
  
  reaper.SNM_SetIntConfigVar( 'splitautoxfade', splitautoxfade )
  if trimcont == 1 then reaper.Main_OnCommandEx(41117, 0, 0) end
  if trimcontrazor == 1 then reaper.Main_OnCommandEx(42421, 0, 0) end
  if razorAffectsEnvs == 0 then reaper.Main_OnCommandEx(42459, 0, 0) end
  reaper.SetEditCurPos2(0, editCurPos, false, false)
   
  UndoString = 'Simple Reconform_AZ'
  if UndoString then
    reaper.Main_OnCommandEx(42406,0,0) --Razor edit: Clear all areas
    reaper.Undo_EndBlock2( 0, UndoString, -1 ) 
    reaper.UpdateArrange()
    ProcessString = 'Reconform finished'
    --ShowProgress()
    --coroutine.yield(ProcessString)
    UndoString = nil
  else reaper.defer(function()end) 
  end
  --end) --end of coroutine
end

-----------------------------
-------START-------------------

OptionsWindow()


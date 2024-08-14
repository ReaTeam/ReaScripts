-- @description Simple project reconform
-- @author AZ
-- @version 0.5
-- @link Forum thread https://forum.cockos.com/showthread.php?t=288069
-- @about
--   # Simple Project Reconform
--   The script is under development, but you can try to use it.
--   Read more: https://forum.cockos.com/showthread.php?t=288069

-----------------------------
function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end
-----------------------------

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
  dofile(imgui_path) '0.8.7.6'
  OptionsDefaults()
  GetExtStates()
  local fontSize = 17
  local ctx, font, fontSep, fontBig
  local H = fontSize
  local W = fontSize
  local loopcnt = 0
  local _, imgui_version_num, _ = reaper.ImGui_GetVersion()

  OldPrjStart = 0
  NewPrjStart = nil
  local oldprjOffsetTime = ''
  local newprjOffsetTime = ''
  local SourcePrj
  local prjselpreview
  tracksForImportFlag = 1

  local esc
  local enter
  local space
  local escMouse
  local enterMouse
  local spaceMouse
  
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
    --[[
    Input = {
      Background = rgbToHex({50,50,50,100}),
      Hover = rgbToHex({10,10,90,100}),
      Text = rgbToHex({90,90,80,100}),
      Label = rgbToHex({90,80,90,100}),
    },]]
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
  
  --------------
  function SplitFilename(strFilename)
    -- Returns the Path, Filename, and Extension as 3 values
    return string.match(strFilename, "(.-)([^\\]-([^\\%.]+))$")
  end
  --------------
  function frame()
    reaper.ImGui_PushFont(ctx, font)
    
    --About button
    reaper.ImGui_SameLine(ctx, fontSize*25, nil)
    if reaper.ImGui_Button(ctx, 'About - forum page', nil, nil) then
      local doc = 'https://forum.cockos.com/showthread.php?t=288069'
      if reaper.CF_ShellExecute then
        reaper.CF_ShellExecute(doc)
      else
        reaper.MB(doc, 'Simple Project Reconform forum page', 0)
      end
    end
    
    reaper.ImGui_Text(ctx, 'EDL reconform may be here in the future...\n'
    ..'For now it based on a reference file, on the take "Start in source" offset.' )
    
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
          --reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.activeText)
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
          --reaper.ImGui_PopStyleColor(ctx)
          
          option[3] = option[4][choice]
        end
        
        if type(option[3]) == 'nil' then
          reaper.ImGui_PushFont(ctx, fontSep)
          reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.White)
          
          reaper.ImGui_Text(ctx, '' )
          reaper.ImGui_SeparatorText( ctx, option[1] )
          
          reaper.ImGui_PopStyleColor(ctx, 1)
          reaper.ImGui_PopFont(ctx)
        end
        
        OptDefaults[i] = option
      end -- for
      reaper.ImGui_SetWindowSize(ctx, 0, 0, nil )
    end -- end of collapsing header
    
    reaper.ImGui_Text(ctx, '' ) --vertical space
    
    --Reference track processing
    if reaper.ImGui_Button(ctx, 'Create report markers for gaps, crossfades, splits', nil, nil ) then
      reaper.Undo_BeginBlock2( 0 )
      reaper.PreventUIRefresh( 1 )
      CreateReportMarkers()
      reaper.Undo_EndBlock2( 0, 'Create report markers - Simple reconform', -1 ) 
      reaper.UpdateArrange()
    end
    
    reaper.ImGui_Text(ctx, '' ) --vertical space
    
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
    if enter == true then
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.MainButton.Active)
    end
    enterMouse = reaper.ImGui_Button(ctx, 'Reconform', fontSize*8, nil)
    if enter == true then reaper.ImGui_PopStyleColor(ctx, 1) end
    reaper.ImGui_PopStyleColor(ctx, 3)
    
    --Input box + button 
    if NewPrjStart then
      newprjOffsetTime = reaper.format_timestr_pos( NewPrjStart, '', 5 )
    end
    local fieldState, retNewPrjOffsetTime =
    reaper.ImGui_InputText(ctx, 'New project position', newprjOffsetTime, nil, nil) 
    if newprjOffsetTime ~= '' and fieldState == true then
      NewPrjStart = reaper.parse_timestr_pos( retNewPrjOffsetTime, 5 )
    end
    reaper.ImGui_SameLine(ctx, nil, nil)
    reaper.ImGui_PushID(ctx, 2)
    if reaper.ImGui_Button(ctx, 'Get edit cursor', nil, nil ) then
      NewPrjStart = reaper.GetCursorPosition()
    end
    reaper.ImGui_PopID(ctx)
    
    --Paste new items for gaps header
    reaper.ImGui_Text(ctx, '' ) --vertical space
    if reaper.ImGui_CollapsingHeader(ctx, 'Paste new items for gaps from another project tab') then
      --Project selector
      local retprj = true
      local path, projfn, extension
      local Projects = {}
      local cur_retprj, cur_projfn = reaper.EnumProjects( -1 )
      local idx = 0
      while retprj ~= nil do
        retprj, projfn = reaper.EnumProjects( idx )
        if retprj and retprj ~= cur_retprj and projfn ~= '' then
          path, projfn, extension = SplitFilename(projfn)
          table.insert(Projects, {retprj, projfn})
        end
        idx = idx+1
      end
      
      if cur_retprj == SourcePrj then SourcePrj = nil end
      
      if #Projects > 0 and SourcePrj == nil then
        SourcePrj = Projects[#Projects][1]
        prjselpreview = Projects[#Projects][2]
      elseif #Projects == 0 then
        prjselpreview = 'Open a named project in another tab'
        SourcePrj = nil
      end
      
      reaper.ImGui_PushItemWidth(ctx, fontSize*23 )
      local choicePrj
      if reaper.ImGui_BeginCombo(ctx, 'Source project', prjselpreview, nil) then 
        for k,f in ipairs(Projects) do
          local is_selected = choicePrj == k
          if reaper.ImGui_Selectable(ctx, Projects[k][2], is_selected) then 
            prjselpreview = Projects[k][2]
            SourcePrj = Projects[k][1]
            choicePrj = k
          end
      
          -- Set the initial focus when opening the combo (scrolling + keyboard navigation focus)
          if is_selected then
            reaper.ImGui_SetItemDefaultFocus(ctx)
          end
        end
        reaper.ImGui_EndCombo(ctx)
      end
      
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
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.MainButton.Default)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), gui_colors.MainButton.Hovered)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), gui_colors.MainButton.Active)
      if reaper.ImGui_Button(ctx, 'Paste Items', fontSize*8, nil ) then
        reaper.Undo_BeginBlock2( 0 )
        reaper.PreventUIRefresh( 1 )
        
        PasteItemsFromPrj(cur_retprj, SourcePrj)
        
        reaper.Undo_EndBlock2( 0, 'Paste new items - Simple reconform', -1 ) 
        reaper.UpdateArrange()
      end
      reaper.ImGui_PopStyleColor(ctx, 3)
      
      reaper.ImGui_SetWindowSize(ctx, 0, 0, nil )
    end -- end of collapsing header
    
    reaper.ImGui_Text(ctx, '' ) --space before buttons
    
    --Esc button
    --[[
    reaper.ImGui_SameLine(ctx, fontSize*2, fontSize)
    if esc == true then
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.Button.Active)
    end
    escMouse = reaper.ImGui_Button(ctx, 'Esc', nil, nil )
    if esc == true then reaper.ImGui_PopStyleColor(ctx, 1) end 
    ]]
    
    reaper.ImGui_PopFont(ctx)
  end
  
  --------------
  function loop()
    esc = reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape())
    --enter = reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Enter())
    space = reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Space())
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
      
      local window_flags = reaper.ImGui_WindowFlags_None()--reaper.ImGui_WindowFlags_MenuBar()
      reaper.ImGui_SetNextWindowSize(ctx, W, H, reaper.ImGui_Cond_Once()) -- Set the size of the windows.  Use in the 4th argument reaper.ImGui_Cond_FirstUseEver() to just apply at the first user run, so ImGUI remembers user resize s2
      
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.White) 
      local visible, open = reaper.ImGui_Begin(ctx, 'Simple Project Reconform', true, window_flags)
      reaper.ImGui_PopStyleColor(ctx, 1)
      
      if visible then
          frame() 
          if loopcnt == 0 then reaper.ImGui_SetWindowSize(ctx, 0, 0, nil ) end
          reaper.ImGui_End(ctx)
      end
      
      reaper.ImGui_PopStyleColor(ctx, 13)
      reaper.ImGui_PopFont(ctx)
       
      esc = escMouse or reaper.ImGui_IsKeyReleased(ctx, reaper.ImGui_Key_Escape())
      enter = enterMouse --or reaper.ImGui_IsKeyReleased(ctx, reaper.ImGui_Key_Enter())
      
      if undo then reaper.Main_OnCommandEx(40029,0,0) end
      if redo then reaper.Main_OnCommandEx(40030,0,0) end
      
      if open and esc ~= true and enter ~= true then
          SetExtStates()
          reaper.defer(loop)
      elseif enter == true then
          SetExtStates()
          reaper.Undo_BeginBlock2( 0 )
          reaper.PreventUIRefresh( 1 )
          
          main()
          
          if UndoString then 
            reaper.Main_OnCommandEx(42406,0,0) --Razor edit: Clear all areas
            reaper.Undo_EndBlock2( 0, UndoString, -1 ) 
            reaper.UpdateArrange()
          else reaper.defer(function()end) 
          end
          reaper.defer(loop)
          --reaper.ImGui_DestroyContext(ctx)
      else
          reaper.ImGui_DestroyContext(ctx)
      end
    loopcnt = loopcnt+1
  end
  -----------------
  local fontName
  ctx = reaper.ImGui_CreateContext('Smart Split Options') -- Add VERSION TODO
  if reaper.GetOS():match("^Win") == nil then
    reaper.ImGui_SetConfigVar(ctx, reaper.ImGui_ConfigVar_ViewportsNoDecoration(), 0)
    fontName = 'sans-serif'
  else fontName = 'Calibri'
  end
  font = reaper.ImGui_CreateFont(fontName, fontSize, reaper.ImGui_FontFlags_None()) -- Create the fonts you need
  fontSep = reaper.ImGui_CreateFont(fontName, fontSize-2, reaper.ImGui_FontFlags_Italic())
  fontBig = reaper.ImGui_CreateFont(fontName, fontSize+4, reaper.ImGui_FontFlags_None())
  reaper.ImGui_Attach(ctx, font)
  reaper.ImGui_Attach(ctx, fontSep)
  reaper.ImGui_Attach(ctx, fontBig)
  
  loop(ctx, font)
end
---------------------------
-------------------------

function CreateReportMarkers()
  SetOptGlobals()
  local refItems = CollectSelectedItems()
  local tag = ' - SPReconform'
  
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
  
  table.sort(Gaps, function (a,b) return (a[1] < b[1]) end )
  
  local track = reaper.GetTrack(0, LastRefTrID)
  local fl = reaper.SetMediaTrackInfo_Value(track, 'I_FREEMODE', 2 )
  reaper.UpdateTimeline()
  local splits
  local gaps
  local xfades
  
  local it = reaper.GetTrackMediaItem(track, 0)
  local lanesN = 1 / reaper.GetMediaItemInfo_Value(it, 'F_FREEMODE_H')
  reaper.SetOnlyTrackSelected(track)
  local splitsTake
  local splcnt = 1
  local xfadecnt = 1
  
  for i, item in ipairs(refItems) do
    local itemPos = item[3]
    local itemEnd = itemPos + item[2] - item[1]
    local prev_itemEnd
    if i>1 then prev_itemEnd = refItems[i-1][3] + refItems[i-1][2] - refItems[i-1][1] end
    
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
    
    if i>1 and itemPos < prev_itemEnd then
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
  
  local prevEnd
  local selItNumb = reaper.CountSelectedMediaItems(0)
  for i = 0, selItNumb - 1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    --local itemLocked = reaper.GetMediaItemInfo_Value(item, 'C_LOCK')
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
          if prevEnd < refPos then table.insert(Gaps, {prevEnd, refPos}) end
        end
        
        prevEnd = refPos + refLength
      end
    end
    
  end
  return ItemsTable
end

-----------------------------
function CleanUpRefItems(Items)
  local i = #Items
  while i>1 do
    local areaStart = Items[i][1]
    local areaEnd = Items[i][2]
    local targetPos = Items[i][3]
    
    local prevAstart = Items[i-1][1]
    local prevAend = Items[i-1][2]
    local prevTpos = Items[i-1][3]
    
    if Opt.HealGaps == true then
      if areaStart - (targetPos - prevTpos) == prevAstart then
        Items[i-1][2] = areaEnd
        table.remove(Items,i)
      end
    elseif Opt.HealSplits == true then
      if areaStart == prevAend then
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
  --msg(envcnt)
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
    for e = 0, envcnt -1 do
      local env = reaper.GetTrackEnvelope(track, e)
      local  ret, GUID = reaper.GetSetEnvelopeInfo_String( env, 'GUID', '', false )
      string = string .. ' '.. timeString .. ' "'..GUID..'"'
    end
    local ret, string = reaper.GetSetMediaTrackInfo_String( track, 'P_RAZOREDITS', string, true )
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
  local pointTime = areaEnd
  local PointsTable = {}
  local exact = false
  
  table.insert(PointsTable, {
  Time = areaEnd-areaStart, Measure = -1, Beat = -1, BPM = endTempo,
  Tsign_num = end_num, Tsign_denom = end_denom, islinear = false }) 
  
  while pointTime >= areaStart do
    local p = {}
    local point = reaper.FindTempoTimeSigMarker( 0, pointTime )
    local ret
    ret, p.Time, p.Measure, p.Beat, p.BPM, p.Tsign_num, p.Tsign_denom, p.islinear = reaper.GetTempoTimeSigMarker(0, point )
    pointTime = p.Time - 0.002  --2 ms to avoid infinity cycle
    --msg(p.Tsign_num ..' '.. p.Tsign_denom ..' '.. tostring(p.islinear))
    p.Measure = -1
    p.Beat = -1 
    p.Time = p.Time - areaStart  --relative position

    if p.Time == 0 then exact = true end
    if p.Time >= 0 then table.insert(PointsTable, p) end
  end
  
  
  if exact == false then
    local p = {}
    local point = reaper.FindTempoTimeSigMarker( 0, areaStart )
    local ret
    ret, _, _, _, _, _, _, p.islinear = reaper.GetTempoTimeSigMarker(0, point )
    p.Time = 0 --relative position
    p.Measure = -1
    p.Beat = -1
    p.BPM = startTempo
    p.Tsign_num = start_num
    p.Tsign_denom = start_denom
    table.insert(PointsTable, p)
  end
  
  --for i, v in pairs(PointsTable) do msg(v.Time) end

  local pNumb = #PointsTable
  
  while pNumb > 0 do
    local p = PointsTable[pNumb]
    
    reaper.SetTempoTimeSigMarker
    (0, -1, p.Time + pasteTarget, p.Measure, p.Beat, p.BPM, p.Tsign_num, p.Tsign_denom, p.islinear )
    --msg(p.Time + pasteTarget)
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
  if disable == true then disable = 2 else disable = 1 end
  if not DisLanesTrTable then
    DisLanesTrTable = {}
    local trcnt = reaper.CountTracks(0)
    for i = LastRefTrID +1, trcnt -1 do
      local track = reaper.GetTrack(0,i)
      local lanesState = reaper.GetMediaTrackInfo_Value(track, 'C_LANESCOLLAPSED')
      --msg(lanesState)
      if lanesState >= 2 then
        table.insert(DisLanesTrTable, track)
        reaper.SetMediaTrackInfo_Value(track, 'C_LANESCOLLAPSED', disable)
        
      end
    end
  elseif disable == 2 then
    for i, track in ipairs(DisLanesTrTable) do
      reaper.SetMediaTrackInfo_Value(track, 'C_LANESCOLLAPSED', disable)
    end
  end
end
-----------------------------

function RemoveExtraPoints()
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
      local _, name = reaper.GetEnvelopeName(env)
      if name ~= "Tempo map" then
      
        for k, g in ipairs(Gaps) do
          local leftTime = g[1]
          local rightTime = g[2]
          --msg(leftTime..'  '..rightTime)
          local idx = reaper.GetEnvelopePointByTimeEx( env, -1, rightTime )
          local ret, time, value, shape, tension, selected
          time = rightTime
          while time > leftTime do
            ret, time, value, shape, tension, selected = reaper.GetEnvelopePointEx( env, -1, idx )
            if time > leftTime + 0.0001 and time < rightTime - 0.0001 then -- 0.1 ms to avoid some inaccurace
            --msg(time) 
              reaper.DeleteEnvelopePointEx( env, -1, idx, true )
            end
            idx = idx-1
          end -- points cycle
          reaper.Envelope_SortPointsEx( env, -1 )
        end -- end Gap cycle
        
      end
    end -- end Env cycle
    
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
  
  if Opt.ReconfLockedItems == true then SaveAndUnlockItems() end
  if Opt.ReconfDisabledLanes == true then ToggleDisableLanes(false) end
  reaper.Main_OnCommandEx(reaper.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND'),0,0)  --SWS/BR: Focus arrange
  reaper.Main_OnCommandEx(reaper.NamedCommandLookup('_SWSTL_SHOWALL'),0,0) --SWS: Show all tracks
  reaper.Main_OnCommandEx(41149,0,0) --Envelope: Show all envelopes for all tracks
  SeparateEnv()
  --local Zero = refItems[1][3]
  
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
  
  
  for i, item in ipairs(refItems) do --Start reconform cycle 
    
    local areaStart = item[1]
    local areaEnd = item[2]
    local refPos = item[3]
    
    UndoString = 'Simple Reconform'
    
    if TimeSigCount > 0 then
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
  
  RemoveExtraPoints()
  RestoreEnvVis()
  if Opt.ReconfLockedItems == true then RestoreLockedItems() end
  if Opt.ReconfDisabledLanes == true then ToggleDisableLanes(true) end
  
  if Opt.ReconfRegions == true then
    CreateRegions(refItems)
  end
  
  reaper.SNM_SetIntConfigVar( 'splitautoxfade', splitautoxfade )
  if trimcont == 1 then reaper.Main_OnCommandEx(41117, 0, 0) end
  if trimcontrazor == 1 then reaper.Main_OnCommandEx(42421, 0, 0) end
  reaper.SetEditCurPos2(0, editCurPos, false, false)
  reaper.SelectAllMediaItems(0, false)
end


-----------------------------
-------START-------------------

OptionsWindow()


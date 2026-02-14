-- @noindex

-----------------------------
function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end

--------------------------

function get_script_path()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  --script_path = script_path:gsub('[^/\\]*[/\\]*$','') --one level up
  return script_path
end

------------------------

local script_path = get_script_path()
local commonFile = script_path..'az_Common reconform functions.lua'
dofile(commonFile)

------------------------

function GetOldRefTime(prjTime, refTable)
  if not refTable or #refTable == 0 then return 'No ref track' end
  
  local retval
  local matches = {}
  
  for i, v in ipairs(refTable) do
    local origIn = v[1]
    local origOut = v[2]
    local target = v[3]
    
    if prjTime >= target and prjTime-0.001 <= target + (origOut - origIn) then
      retval = origIn + (prjTime - target) + OldPrjStart
      table.insert(matches, retval)
    end
    
  end
  
  if #matches == 0 then retval = 'GAP' end
  if #matches > 1 then retval = matches[2] end
  
  return retval
end

------------------------

function GetPrevNextRefTime(prjTime, refTable) -- return min, max
  if not refTable or #refTable == 0 then return end
  prjTime = round(prjTime, 4)
  local min, max
  local prevMax
  local flatList={}
  if NewPrjStart then table.insert(flatList, NewPrjStart) end
  
  for i, v in ipairs(refTable) do
    local posIn = v[3]
    local posOut = posIn + (v[2] - v[1])
    FieldMatch(flatList, posIn, true)
    FieldMatch(flatList, round(posOut, 4), true)
  end
  
  table.sort(flatList)
  for i, v in ipairs(flatList) do 
    if prjTime == v then
      min = flatList[i - 1]
      max = flatList[i + 1] 
      return min, max
    elseif prjTime < v and (not flatList[i - 1] or round(prjTime - flatList[i - 1], 4) > 0)then
      min = flatList[i - 1]
      max = v 
      return min, max
    elseif prjTime > v and ( not flatList[i + 1] or round(prjTime - flatList[i + 1], 4) < 0 ) then
      min = v
      max = flatList[i + 1] 
      return min, max
    end
  end
  
end

-----------------------

local function ScriptWindow()
  if not reaper.APIExists('SNM_SetIntConfigVar') then
    reaper.ShowMessageBox('Please, install SWS extension!', 'No SWS extention', 0)
    return
  end
  
  local imgui_path = reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua'
  if not reaper.file_exists(imgui_path) then
    reaper.ShowMessageBox('Please, install ReaImGui from Reapack!', 'No Imgui library', 0)
    return
  end
  dofile(imgui_path) '0.10'
  local fontSize = 16
  local ctx, fontName, OScoeff, font, fontSep, fontBig
  local H = fontSize
  local W = fontSize
  local loopcnt = 0
  local esc
  local settingsOpen = false
  local btnGetRefText
  local refTrack, prevProj
  
  local newEditTimeShow, oldEditTimeShow
  local newEditTime, oldEditTime, oldFixedTime
  
  local refTrackString = ''
  
  local savedFontSize = tonumber(reaper.GetExtState(ExtStateName, 'AssistantFontSize'))
  if type(savedFontSize) == 'number' then fontSize = savedFontSize end
  if not savedFontSize then savedFontSize = fontSize end
  
  local gui_colors = SetGUIcolors()
  local Flags = SetGUIflags()
  
  ctx = reaper.ImGui_CreateContext('ComparisonAssistantForSPR_AZ')
  if reaper.GetOS():match("^Win") == nil then
    reaper.ImGui_SetConfigVar(ctx, reaper.ImGui_ConfigVar_ViewportsNoDecoration(), 0)
    fontName, OScoeff = 'sans-serif', 1.08
  else fontName, OScoeff = 'Calibri', 1
  end
  
  --------------
  
  function frame()
    
    local childALLflags = Flags.childAutoResizeY | Flags.childAutoResizeX
    local ChildALL = reaper.ImGui_BeginChild(ctx, 'ChildALL', 0, 0, childALLflags)
    
    if ChildALL then
      
      reaper.ImGui_PushFont(ctx, font, fontSize)
      
      if type(refTrack) ~= 'table' then
        reaper.ImGui_Text(ctx, 'There is no saved reference track in project!')
        btnGetRefText = 'Get selected items as reference'
      else btnGetRefText = 'Update reference track' --msg(#refTrack)
      end
      
      ---Settings section---
      reaper.ImGui_PushFont(ctx, fontSep, fontSize-2)
      if reaper.ImGui_Button(ctx, 'Settings' ) then
        settingsOpen = not settingsOpen
      end
      reaper.ImGui_PopFont(ctx)
      
      if settingsOpen then 
        reaper.ImGui_SameLine(ctx, nil, fontSize*4)
        if reaper.ImGui_Button(ctx, btnGetRefText ) then
          refTrack = CollectSelectedItems()
          if #refTrack == 0 then refTrack = nil end
        end
        
        local childflags = Flags.childAutoResizeY | Flags.childAutoResizeX | Flags.childBorder
        local ChildSettings = reaper.ImGui_BeginChild(ctx, 'Settings', 0, 0, childflags)
        
        if ChildSettings then 
          --Input box + button
          reaper.ImGui_PushItemWidth(ctx, fontSize * 6 * OScoeff )
          
          local fieldState, retOldPrjOffsetTime =
          reaper.ImGui_InputText(ctx, 'Old project position', reaper.format_timestr_pos( OldPrjStart, '', 5 ), nil, nil) 
          if fieldState == true then
            OldPrjStart = reaper.parse_timestr_pos( retOldPrjOffsetTime, 5 )
            reaper.SetProjExtState(0,ExtStateName, 'OldPrjStart', OldPrjStart )
          end
          reaper.ImGui_SameLine(ctx, fontSize*17, nil)
          reaper.ImGui_PushID(ctx, 1)
          if reaper.ImGui_Button(ctx, 'Get edit cursor', nil, nil ) then
            OldPrjStart = reaper.GetCursorPosition()
            reaper.SetProjExtState(0,ExtStateName, 'OldPrjStart', OldPrjStart )
          end
          reaper.ImGui_PopID(ctx)
          ---------------
          
          --Input box + button 
          local fieldState, retNewPrjOffsetTime =
          reaper.ImGui_InputText(ctx, 'New project position', reaper.format_timestr_pos( NewPrjStart, '', 5 ), nil, nil)
          
          if fieldState == true then
            NewPrjStart = reaper.parse_timestr_pos( retNewPrjOffsetTime, 5 )
          end
          
          reaper.ImGui_SameLine(ctx, fontSize*17, nil)
          reaper.ImGui_PushID(ctx, 2)
          local btnState = reaper.ImGui_Button(ctx, 'Get edit cursor', nil, nil )
          if btnState then
            NewPrjStart = reaper.GetCursorPosition()
          end
          reaper.ImGui_PopID(ctx)
          
          if btnState or fieldState then
            if NewPrjStart and NewPrjStart <= OldPrjStart then
              reaper.ShowMessageBox('Reconformed project must be placed next to the old version.\nLet it be +1 hour after the old verion.','Warning!', 0)
              NewPrjStart = OldPrjStart + 3600
            end
            reaper.SetProjExtState(0, ExtStateName, 'NewPrjStart', NewPrjStart )
          end
          -------------
          
          reaper.ImGui_NewLine(ctx)
          reaper.ImGui_PushItemWidth(ctx, savedFontSize * 5.5 * OScoeff)
          _, savedFontSize = reaper.ImGui_InputInt
          (ctx, 'Font size for the window (default is 16)', savedFontSize)
          
          reaper.ImGui_EndChild(ctx)
        end
      end 
      -----End of Settings section----
      
      if not settingsOpen then reaper.ImGui_SameLine(ctx, fontSize*6 ) end
      reaper.ImGui_Text(ctx, 'Ref navigation')
      
      reaper.ImGui_SameLine(ctx, fontSize*13.5 )
      if reaper.ImGui_Button(ctx, '<', fontSize*2.5) and not Teleported then
        reaper.JS_Window_SetFocus(reaper.GetMainHwnd())
        local min, max = GetPrevNextRefTime(newEditTime + NewPrjStart - PrjTimeOffset, refTrack)
        if min then --msg(min..' '..NewPrjStart..' '..PrjTimeOffset)
          reaper.SetEditCurPos2(0, min, true, false) 
        end
      end
      
      reaper.ImGui_SameLine(ctx, nil, fontSize)
      if reaper.ImGui_Button(ctx, '> ', fontSize*2.5) and not Teleported then
        reaper.JS_Window_SetFocus(reaper.GetMainHwnd())
        local min, max = GetPrevNextRefTime(newEditTime + NewPrjStart - PrjTimeOffset, refTrack)
        if max then --msg(max..' '..NewPrjStart..' '..PrjTimeOffset)
          reaper.SetEditCurPos2(0, max, true, false) 
        end
      end
      
      local childTimeflags = Flags.childAutoResizeY | Flags.childAutoResizeX
      local ChildTime = reaper.ImGui_BeginChild(ctx, 'ChildTime', 0, 0, childTimeflags)
      
      if ChildTime then
        local gotoOldText = 'Go to Old edit position:'
        local gotoNewText = 'New edit position:'
        
        if not Teleported then
          newEditTime = reaper.GetCursorPosition() - NewPrjStart + PrjTimeOffset
          newEditTimeShow = reaper.format_timestr_pos(newEditTime, '', 5)
          
          oldEditTime = GetOldRefTime(newEditTime, refTrack)
          if type(oldEditTime) ~= 'number' then
            oldEditTimeShow = oldEditTime
          else oldEditTimeShow = reaper.format_timestr_pos(oldEditTime, '', 5)
          end 
        else
          gotoOldText = 'Old edit position:'
          gotoNewText = 'Back to New edit position:'
          oldEditTime = reaper.GetCursorPosition() - OldPrjStart + PrjTimeOffset
          oldEditTimeShow = reaper.format_timestr_pos(oldEditTime, '', 5)
        end
        
        reaper.ImGui_Text(ctx, gotoNewText)
         
        reaper.ImGui_SameLine(ctx, fontSize*11.5 )
        reaper.ImGui_PushFont(ctx, fontBig, fontSize+4)
        if Teleported then
          reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.Red)
        else
          reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.Green)
        end
        reaper.ImGui_PushID(ctx, 3)
        if reaper.ImGui_Button(ctx, newEditTimeShow, fontSize*8 ) then
          reaper.JS_Window_SetFocus(reaper.GetMainHwnd())
          if Teleported then
            local _, pos = reaper.GetProjExtState(0,ExtStateName, 'SavedPosition') 
            if pos ~='' then 
              reaper.SetEditCurPos2(0, tonumber(pos), true, false) 
              Teleported = false
            end
          end
        end
        reaper.ImGui_PopID(ctx)
        reaper.ImGui_PopStyleColor(ctx, 1)
        reaper.ImGui_PopFont(ctx)
        ---------
        
        reaper.ImGui_Text(ctx, gotoOldText)
        
        reaper.ImGui_SameLine(ctx, fontSize*11.5 )
        reaper.ImGui_PushFont(ctx, fontBig, fontSize+4)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.White)
        reaper.ImGui_PushID(ctx, 4)
        if reaper.ImGui_Button(ctx, oldEditTimeShow, fontSize*8 ) then
          reaper.JS_Window_SetFocus(reaper.GetMainHwnd())
          if not Teleported and type(oldEditTime) == 'number' then
            oldFixedTime = oldEditTime - OldPrjStart + PrjTimeOffset
            reaper.SetEditCurPos2(0, oldEditTime, true, false) 
            reaper.SetProjExtState(0,ExtStateName, 'SavedPosition', newEditTime) 
            Teleported = true 
          end
        end
        reaper.ImGui_PopID(ctx)
        reaper.ImGui_PopStyleColor(ctx, 1)
        reaper.ImGui_PopFont(ctx)
        
        reaper.ImGui_EndChild(ctx)
      end
      
      ----------------
      reaper.ImGui_SameLine(ctx)
      local childDOPflags = Flags.childAutoResizeY | Flags.childAutoResizeX
      local ChildDOP = reaper.ImGui_BeginChild(ctx, 'ChildDOP', 0, 0, childALLflags)
      
      
      if ChildDOP then 
        reaper.ImGui_PushFont(ctx, font, fontSize)
        
        if reaper.ImGui_Button(ctx, '   Back\nwith drift' ) then
          reaper.JS_Window_SetFocus(reaper.GetMainHwnd())
          if Teleported then
            local _, pos = reaper.GetProjExtState(0,ExtStateName, 'SavedPosition') 
            if pos ~='' then 
              reaper.SetEditCurPos2(0, tonumber(pos) + (oldEditTime-oldFixedTime), true, false) 
              Teleported = false
            end
          end
        end
        
        reaper.ImGui_PopFont(ctx)
        reaper.ImGui_EndChild(ctx)
      end
      
      reaper.ImGui_PopFont(ctx)
      
      reaper.ImGui_EndChild(ctx)
    end
    
  end
  
  --------------
  function loop()
    local curProj, projfn = reaper.EnumProjects( -1 )
    
    if not refTrack or curProj ~= prevProj then
      _, refTrackString = reaper.GetProjExtState(curProj, ExtStateName, 'RefTrack') 
      local f = load(refTrackString)
      refTrack = f()
    end
     
    if loopcnt == 0 and type(refTrack) ~= 'table' then
      settingsOpen = true
    end
    
    --if loopcnt == 0 then msg(refTrackString)end
    if not OldPrjStart or curProj ~= prevProj then
      _, OldPrjStart = reaper.GetProjExtState(0, ExtStateName, 'OldPrjStart')
    end
    if OldPrjStart == '' then OldPrjStart = 0
    else OldPrjStart = tonumber(OldPrjStart)
    end
    
    if not NewPrjStart or curProj ~= prevProj then
      _, NewPrjStart = reaper.GetProjExtState(0, ExtStateName, 'NewPrjStart')
    end
    
    if NewPrjStart == '' then NewPrjStart = 3600
    else NewPrjStart = tonumber(NewPrjStart)
    end
    if not NewPrjStart then NewPrjStart = 3600 end
    
    prevProj = curProj
    
    PrjTimeOffset = -reaper.GetProjectTimeOffset( 0, false )
    
    MIN_luft_ZERO = GetMinLuftZero(PrjTimeOffset)
     
    if not font or savedFontSize ~= fontSize then
      if savedFontSize < 7 then savedFontSize = 7 end
      if savedFontSize > 60 then savedFontSize = 60 end
      reaper.SetExtState(ExtStateName, 'AssistantFontSize', savedFontSize, true)
      fontSize = savedFontSize
      if font then reaper.ImGui_Detach(ctx, font) end
      if fontSep then reaper.ImGui_Detach(ctx, fontSep) end
      font = reaper.ImGui_CreateFont(fontName, reaper.ImGui_FontFlags_None()) -- Create the fonts you need
      fontSep = reaper.ImGui_CreateFont(fontName, reaper.ImGui_FontFlags_Italic())
      fontBig = reaper.ImGui_CreateFont(fontName, reaper.ImGui_FontFlags_None())
      reaper.ImGui_Attach(ctx, font)
      reaper.ImGui_Attach(ctx, fontSep)
      reaper.ImGui_Attach(ctx, fontBig)
    end
    
    esc = reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape())
    
    undo = reaper.ImGui_Shortcut(ctx, reaper.ImGui_Mod_Ctrl() | reaper.ImGui_Key_Z(), reaper.ImGui_InputFlags_RouteGlobal())
    
    redo = reaper.ImGui_Shortcut(ctx, reaper.ImGui_Mod_Ctrl() | reaper.ImGui_Mod_Shift() | reaper.ImGui_Key_Z(), reaper.ImGui_InputFlags_RouteGlobal())
      
      reaper.ImGui_PushFont(ctx, font, fontSize)
      
      local colorCnt, styleCnt = PUSHstyle(ctx, gui_colors, Flags, fontSize)
      
      local window_flags = reaper.ImGui_WindowFlags_None()--reaper.ImGui_WindowFlags_MenuBar()
      reaper.ImGui_SetNextWindowSize(ctx, W, H, reaper.ImGui_Cond_Once()) -- Set the size of the windows.  Use in the 4th argument reaper.ImGui_Cond_FirstUseEver() to just apply at the first user run, so ImGUI remembers user resize s2
      
      local visible, open = reaper.ImGui_Begin(ctx, 'Comparison assistant for reconform', true, window_flags)
      reaper.ImGui_PopStyleColor(ctx, 1)
      
      if visible then
          frame()
          reaper.ImGui_SetWindowSize(ctx, 0, 0, nil )
          reaper.ImGui_End(ctx)
      end
      
      reaper.ImGui_PopStyleColor(ctx, colorCnt)
      reaper.ImGui_PopStyleVar(ctx, styleCnt)
      reaper.ImGui_PopFont(ctx)
       
      esc = reaper.ImGui_IsKeyReleased(ctx, reaper.ImGui_Key_Escape())
      
      if undo then reaper.Main_OnCommandEx(40029,0,0) end
      if redo then reaper.Main_OnCommandEx(40030,0,0) end
      
      if open and not esc then
        if IsOptTgl == true then SetExtStates() end
        if runReconf == true then main() end
        reaper.defer(loop)
      end

    loopcnt = loopcnt+1
  end
  -----------------
  
  loop()
end
---------------------------

ScriptWindow()

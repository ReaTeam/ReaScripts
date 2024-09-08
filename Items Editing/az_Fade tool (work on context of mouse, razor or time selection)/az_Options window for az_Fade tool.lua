-- @noindex

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

function OptionsWindow(OptTable, windowName)
  local imgui_path = reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua'
  if not reaper.file_exists(imgui_path) then
    reaper.ShowMessageBox('Please, install ReaImGui from Reapack!', 'No Imgui library', 0)
    return
  end
  dofile(imgui_path) '0.8.7.6'

  local fontSize = 17
  local ctx, font, fontSep
  local H = fontSize
  local W = fontSize
  local loopcnt = 0
  local _, imgui_version_num, _ = reaper.ImGui_GetVersion()
  
  local tcpActIDstr = reaper.GetExtState(ExtStateName, 'TCPaction')
  local tcpActName = ''
  local section
  
  local savedFontSize = tonumber(reaper.GetExtState(ExtStateName, 'FontSize'))
  if type(savedFontSize) == 'number' then fontSize = savedFontSize end
  if not savedFontSize then savedFontSize = fontSize end
  
  if tcpActIDstr ~= '' and tcpActIDstr:gsub('%d+', '') == '' then
    section =  reaper.SectionFromUniqueID( tonumber(tcpActIDstr) )
    tcpActName = reaper.kbd_getTextFromCmd( tonumber(tcpActIDstr), section )
  elseif tcpActIDstr ~= '' then
    section = reaper.SectionFromUniqueID( tonumber(reaper.NamedCommandLookup(tcpActIDstr)) )
    tcpActName = reaper.kbd_getTextFromCmd
    ( tonumber(reaper.NamedCommandLookup(tcpActIDstr)), section ) 
  end
  
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
    Blue = rgbToHex({10,30,40,100}),
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
    }
  }
  ------
  
  local fontName
  ctx = reaper.ImGui_CreateContext(windowName) -- Add VERSION TODO
  if reaper.GetOS():match("^Win") == nil then
    reaper.ImGui_SetConfigVar(ctx, reaper.ImGui_ConfigVar_ViewportsNoDecoration(), 0)
    fontName = 'sans-serif'
  else
    fontName = 'Calibri'
  end

  --------------
  function frame()
    reaper.ImGui_PushFont(ctx, font) 
    
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
    
    if RunBatch == nil then
      reaper.ImGui_Text(ctx, '' ) --space 
      reaper.ImGui_PushItemWidth(ctx, fontSize*5 )
      _, tcpActIDstr = reaper.ImGui_InputText
      (ctx,'TCP context action (paste command ID):\n'..tcpActName, tcpActIDstr)
    
      _, savedFontSize = reaper.ImGui_InputInt
      (ctx, 'Font size for the window (default is 17)', savedFontSize)
    end
    
    reaper.ImGui_Text(ctx, '' ) --space before buttons
    reaper.ImGui_Text(ctx, '' ) --space before buttons
    
    --Esc button
    reaper.ImGui_SameLine(ctx, fontSize*2, fontSize)
    if esc == true then
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.Button.Active)
    end
    escMouse = reaper.ImGui_Button(ctx, 'Esc', nil, nil )
    if esc == true then reaper.ImGui_PopStyleColor(ctx, 1) end 
    
    --Save button
    reaper.ImGui_SameLine(ctx, nil, fontSize)
    if enter == true then
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.Button.Active)
    end
    local enterName = 'Save & Quit - Enter'
    if RunBatch ~= nil then enterName = 'Run - Enter' end
    enterMouse = reaper.ImGui_Button(ctx, enterName, nil, nil)
    if enter == true then reaper.ImGui_PopStyleColor(ctx, 1) end 
    
    --Apply button
    if ExternalOpen == true then
      reaper.ImGui_SameLine(ctx, nil, fontSize)
      if space == true then
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), gui_colors.Button.Active)
      end
      spaceMouse = reaper.ImGui_Button(ctx, 'Apply - Space', nil, nil)
      if space == true then reaper.ImGui_PopStyleColor(ctx, 1) end
    end
    
    --About button
    reaper.ImGui_SameLine(ctx, fontSize*25, nil)
    if reaper.ImGui_Button(ctx, 'About - forum page', nil, nil) then
      local doc = 'https://forum.cockos.com/showthread.php?t=293335'
      if reaper.CF_ShellExecute then
        reaper.CF_ShellExecute(doc)
      else
        reaper.MB(doc, 'Fade Tool forum page', 0)
      end
    end
    
    reaper.ImGui_PopFont(ctx)
  end
  
  --------------
  function loop()
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
    enter = reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Enter())
    space = reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Space())
    
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
      
      local window_flags = reaper.ImGui_WindowFlags_MenuBar()
      reaper.ImGui_SetNextWindowSize(ctx, W, H, reaper.ImGui_Cond_Once()) -- Set the size of the windows.  Use in the 4th argument reaper.ImGui_Cond_FirstUseEver() to just apply at the first user run, so ImGUI remembers user resize s2
      
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.White) 
      local visible, open = reaper.ImGui_Begin(ctx, windowName, true, window_flags)
      reaper.ImGui_PopStyleColor(ctx, 1)
      
      if visible then
          frame()
          reaper.ImGui_SetWindowSize(ctx, 0, 0, nil )
          --if loopcnt == 0 then reaper.ImGui_SetWindowSize(ctx, 0, 0, nil ) end
          reaper.ImGui_End(ctx)
      end
      
      reaper.ImGui_PopStyleColor(ctx, 13)
      reaper.ImGui_PopFont(ctx)
       
      esc = escMouse or reaper.ImGui_IsKeyReleased(ctx, reaper.ImGui_Key_Escape())
      enter = enterMouse or reaper.ImGui_IsKeyReleased(ctx, reaper.ImGui_Key_Enter())
      
      if ExternalOpen == true then
        space = spaceMouse or reaper.ImGui_IsKeyReleased(ctx, reaper.ImGui_Key_Space()) 
        if space == true then
          SetExtStates(OptTable)
          reaper.SetExtState(ExtStateName, 'TCPaction', tcpActIDstr, true) 
        end
      end
      
      if open and esc ~= true and enter ~= true then
        reaper.defer(loop) 
      elseif enter == true then
          if RunBatch == true then 
            reaper.ImGui_DestroyContext(ctx)
            BatchFades()
          else
            SetExtStates(OptTable)
            reaper.SetExtState(ExtStateName, 'TCPaction', tcpActIDstr, true) 
            reaper.ImGui_DestroyContext(ctx)
          end
      else
          if RunBatch == true then TheRestAfterBatch() end
          reaper.ImGui_DestroyContext(ctx) 
      end
      
    loopcnt = loopcnt+1
  end
  -----------------
  loop(ctx, font)
end


-- @description Smart split items using mouse cursor context (also edit cursor, razor area and time selection)
-- @author AZ
-- @version 3.40
-- @changelog
--   - New option for splitting unselected item under mouse at time selection
--   - Collapsed and resizeable options window
--   - fixed bug for splitting at time selection if there is one selected item in the project
--   - fixed bug when media editing group of selected tracks obeys any unselected track
--   - fixed bug for take envelopes
-- @provides [main] az_Smart split items by mouse cursor/az_Open options for az_Smart split items by mouse cursor.lua
-- @link Forum thread https://forum.cockos.com/showthread.php?t=259751
-- @donation Donate via PayPal https://www.paypal.me/AZsound
-- @about
--   # Smart split items using mouse cursor context
--
--   Forum thread: https://forum.cockos.com/showthread.php?t=259751
--
--   Split items respect grouping, depend on context of mouse cursor, split at razor edit area or time selection if exist, split at mouse or edit cursor otherwise.
--
--   There are a lot of options. To open options window place mouse on the transport panel or mixer panel and press assigned shortcut.
--
--   By design it should be assigned to a keyboard shortcut, not to a mouse modifier.

--[[
TO MODIFY SCRIPT OPTIONS
OPEN THE OPTIONS WINDOW BY RUNNING THE SCRIPT WITH MOUSE ON TRANSPORT PANEL
]]
--Start load file
ExtStateName = "SmartSplit_AZ"

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
  
  text = 'Select item after split by default:'
  table.insert(OptDefaults, {text, 'defSelSide', 'Right', {'Left','Right'} })
  
  text = 'Default crossfade position'
  table.insert(OptDefaults, {text, 'CrossType', 'Left', {
                                                      'Left',
                                                      'Right',
                                                      'Centered'} })
  
  text = 'Time selection options'
  table.insert(OptDefaults, {text, 'Separator', nil})
  
  text = 'Use time selection only if mouse is close enough to TS edge'
  table.insert(OptDefaults, {text, 'UseTSdistance', true})
  
  text = 'Use time selection for split selected items'
  table.insert(OptDefaults, {text, 'UseTSselItems', true})
  
  text = 'Allow split unselected items under mouse at time selection'
  table.insert(OptDefaults, {text, 'AllowTSunsel', false})
  
  text = 'Use time selection at all'
  table.insert(OptDefaults, {text, 'UseTSall', true})
  
  
  text = 'Mouse context options'
  table.insert(OptDefaults, {text, 'Separator', nil})
                                                      
  text = 'Mouse top / bottom placement on item is used for'
  table.insert(OptDefaults, {text, 'MouseT/B', 'fade/crossfade', {
                                                            'fade/crossfade',
                                                            'crossfade/fade',
                                                            'left/right crossfade',
                                                            'select left/right item',
                                                            'none'} })
                                                            
  text = 'Mouse left / right placement around edit cursor is used for'
  table.insert(OptDefaults, {text, 'MouseL/R', 'select left/right item', {
                                                            'left/right crossfade',
                                                            'select left/right item',
                                                            'none'} })
  
  text = 'Respect snap for split at mouse'
  table.insert(OptDefaults, {text, 'SnapMouse', true})
  
  text = 'Snap mouse to edit cursor distance in pixels'
  table.insert(OptDefaults, {text, 'SnapMouseEcur', 0, "%.0f"})
  
  text = 'Prefer edit cursor rather than mouse cursor on selected items'
  table.insert(OptDefaults, {text, 'eCurPriority', false})    -- Edit cursor have piority against mouse on selected item.
  
  
  text = 'Move Edit Cursor with Offset  (useful for immediate listening in context)'
  table.insert(OptDefaults, {text, 'Separator', nil})
  
   text = 'Move cursor after split if mouse is over item and not recording'
  table.insert(OptDefaults, {text, 'MoveEditCursor', true}) -- moves cursor after splitting if mouse is on item and not recording
  
  text = "Don't move edit cursor after split at Edit Cursor\n even mouse is over item"
  table.insert(OptDefaults, {text, 'DontMoveECurSplit', true})
  
  text = 'Offset between first split point and edit cursor in seconds'
  table.insert(OptDefaults, {text, 'eCurOffset', 1, "%.1f"})
  
  text = "Don't move edit cursor if it stays within the limits\n of this value before first split point"
  table.insert(OptDefaults, {text, 'eCurDistance', 4, "%.1f"})
  --^^ If edit cursor placed before the split within the limits of this value it will not moved.
  
  
  text = 'Additional options'
  table.insert(OptDefaults, {text, 'Separator', nil})
  
   text = 'Allow select by razor only one item of group to split them all'
  table.insert(OptDefaults, {text, 'RazRespItemGroup', false})
  
  text = 'Respect locked items'
  table.insert(OptDefaults, {text, 'RespLock', true})
  
  text = 'If no items selected use global split\n according to Preferences -> Editing Behavior'
  table.insert(OptDefaults, {text, 'GlobSplit', true})
  
  text = 'Global split affects hidden tracks'
  table.insert(OptDefaults, {text, 'GSplitHiddenTr', false})
end
-----------------------------

function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end
-----------------------------------

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
  ---------
  
  local fontName
  ctx = reaper.ImGui_CreateContext('Smart Split Options') -- Add VERSION TODO
  if reaper.GetOS():match("^Win") == nil then
    reaper.ImGui_SetConfigVar(ctx, reaper.ImGui_ConfigVar_ViewportsNoDecoration(), 0)
    fontName = 'sans-serif'
  else
    fontName = 'Calibri'
  end
  
  --------------
  function frame()
    reaper.ImGui_PushFont(ctx, font) 
    local Headers = {}
    
    for i, v in ipairs(OptDefaults) do
      local option = v
      
      if type(option[3]) == 'nil' then
        reaper.ImGui_PushFont(ctx, fontSep)
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), gui_colors.White)
        
        reaper.ImGui_Text(ctx, '' )
        --reaper.ImGui_SeparatorText( ctx, option[1] )
        local ret = reaper.ImGui_CollapsingHeader(ctx, option[1])
        table.insert(Headers, ret)
        
        reaper.ImGui_PopStyleColor(ctx, 1)
        reaper.ImGui_PopFont(ctx) 
      end
      
      if Headers[#Headers] == true or #Headers == 0 then
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
      end --if ret
      
      
      OptDefaults[i] = option
    end -- for
    
    reaper.ImGui_Text(ctx, '' ) --space
    
    reaper.ImGui_PushItemWidth(ctx, fontSize*5 )
    _, tcpActIDstr = reaper.ImGui_InputText
    (ctx,'TCP context action (paste command ID):\n'..tcpActName, tcpActIDstr)
    
    _, savedFontSize = reaper.ImGui_InputInt
    (ctx, 'Font size for the window (default is 17)', savedFontSize)
    
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
    enterMouse = reaper.ImGui_Button(ctx, 'Save & Quit - Enter', nil, nil)
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
      local doc = 'https://forum.cockos.com/showthread.php?t=259751'
      if reaper.CF_ShellExecute then
        reaper.CF_ShellExecute(doc)
      else
        reaper.MB(doc, 'Smart Split forum page', 0)
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
      local visible, open = reaper.ImGui_Begin(ctx, 'Smart Split Options', true, window_flags)
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
          SetExtStates()
          reaper.SetExtState(ExtStateName, 'TCPaction', tcpActIDstr, true)
        end
      end
      
      if open and esc ~= true and enter ~= true then
          reaper.defer(loop)
      elseif enter == true then
          SetExtStates()
          reaper.SetExtState(ExtStateName, 'TCPaction', tcpActIDstr, true)
          reaper.ImGui_DestroyContext(ctx)
      else
          reaper.ImGui_DestroyContext(ctx)
      end
    loopcnt = loopcnt+1
  end
  -----------------
  
  loop(ctx, font)
end

-------------------------
--End load file
-------------------------

function SetOptGlobals()
  Opt = {}
  for i = 1, #OptDefaults do
    local name = OptDefaults[i][2]
    Opt[name] = OptDefaults[i][3]
  end
end

-------------------------

function MoveEditCursor(timeTable, EditCurPos)
  if #timeTable > 0 then
    local timepos = math.min(table.unpack(timeTable))
    local playState = reaper.GetPlayStateEx(0)
    
    if Opt.MoveEditCursor == true
    and (timepos - EditCurPos > Opt.eCurDistance or timepos -0.2 <= EditCurPos)
    --^^here small coeff to avoid extra small distance
    and playState ~= 5 then
      reaper.SetEditCurPos2(0, timepos - Opt.eCurOffset, false, false) 
    end
    
  end
end

----------------------------------
----------------------------------

function PixelDistance()
  local distance = 20
  local startTS, endTS = reaper.GetSet_LoopTimeRange2( 0, false, false, 0, 0, 0 )
  
  if startTS ~= endTS then
    local cur_pos = reaper.GetCursorPosition()
    local zoom = reaper.GetHZoomLevel()
    if Mcur_pos ~= nil then
      
      if math.abs(MouseSnapped - startTS)*zoom <= distance
      or math.abs(MouseSnapped - endTS)*zoom <= distance then
         return 'close'
      else return 'far'
      end
      
    end
  else return 'far' end
  
end

----------------------------------
----------------------------------

function RazorEditSelectionExists()

    for i=0, reaper.CountTracks(0)-1 do

        local retval, x = reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0,i), "P_RAZOREDITS", "string", false)

        if x ~= "" then return true end

    end
    
    return false

end

-----------------------

function GetEnvelopePointsInRange(envelopeTrack, areaStart, areaEnd)
    local envelopePoints = {}

    for i = 1, reaper.CountEnvelopePoints(envelopeTrack) do
        local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(envelopeTrack, i - 1)

        if time >= areaStart and time <= areaEnd then --point is in range
            envelopePoints[#envelopePoints + 1] = {
                id = i-1 ,
                time = time,
                value = value,
                shape = shape,
                tension = tension,
                selected = selected
            }
        end
    end

    return envelopePoints
end

-----------------------
function GetItemsInRange(track, areaStart, areaEnd, areaTop, areaBottom)
    local items = {}
    local itemCount = reaper.CountTrackMediaItems(track)
    local itemTop, itemBottom
    
    for k = 0, itemCount - 1 do
        local item = reaper.GetTrackMediaItem(track, k)
        local lock = reaper.GetMediaItemInfo_Value(item, "C_LOCK")
        
        if Opt.RespLock ~= true or lock ~= 1 then
          local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
          local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
          local itemEndPos = pos+length
          
          if areaBottom ~= nil then
            itemTop = reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_Y")
            itemBottom = itemTop + reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_H") 
          end
          
          --check if item is in area bounds
          if itemEndPos > areaStart and pos < areaEnd then
          
            if areaBottom and itemTop then
              if itemTop < areaBottom - 0.001 and itemBottom > areaTop + 0.001 then
                table.insert(items,item)
              end
            else
              table.insert(items,item)
            end
            
          end
        end -- if lock
    end --end for cycle
    
    return items
end

-----------------------
-----------------------

function ParseAreaPerLane(RawTable, itemH) --one level metatable
  local ParsedTable = {}
  local PreParsedTable = {}
  
  local lanesN = math.floor((1/itemH)+0.5)
  local laneW = 1/lanesN
  
  for i=1, lanesN do
    PreParsedTable[i] = {}
  end
  
  ---------------
  for i=1, #RawTable do
      --area data
      local areaStart = tonumber(RawTable[i][1])
      local areaEnd = tonumber(RawTable[i][2])
      local GUID = RawTable[i][3]
      local areaTop = tonumber(RawTable[i][4])
      local areaBottom = tonumber(RawTable[i][5])
      
    if not isEnvelope then
      local areaWidth = math.floor(((areaBottom - areaTop)/itemH)+0.5) -- how many lanes include
      for w=1, areaWidth do
        local areaLane = math.floor((areaBottom/(laneW*w))+0.5)
        --msg(areaLane)
        local smallRect = {
        
              areaStart,
              areaEnd,
              GUID,
              areaBottom - (laneW*w), --areaTop
              areaBottom - (laneW*(w-1)), --areaBottom
              }

        table.insert(PreParsedTable[areaLane], smallRect)
      end
    else
      table.insert(ParsedTable, RawTable[i])
    end
    
  end
  -------------
  
  for i=1, #PreParsedTable do
    local lane = PreParsedTable[i]
    local prevEnd = nil
    for r=1, #lane do
      local smallRect = lane[r]
      
      if prevEnd ~= smallRect[1] then
        table.insert(ParsedTable, smallRect)
      else
        ParsedTable[#ParsedTable][2] = smallRect[2]
      end
      
      prevEnd = smallRect[2]
    end
  end
  
  return ParsedTable
end

-----------------------
-----------------------

function GetRazorEdits()
    local NeedPerLane = true
    local trackCount = reaper.CountTracks(0)
    local areaMap = {}
    for i = 0, trackCount - 1 do
      local track = reaper.GetTrack(0, i)
      local mode = reaper.GetMediaTrackInfo_Value(track,"I_FREEMODE")
      if mode ~= 0 then
        ----NEW WAY----
        
        local ret, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS_EXT', '', false)
          
        if area ~= '' then
        --msg(area)
            --PARSE STRING and CREATE TABLE
            local TRstr = {}
            
            for s in area:gmatch('[^,]+')do
              table.insert(TRstr, s)
            end
            
            for i=1, #TRstr do
            
              local rect = TRstr[i]
              TRstr[i] = {}
              for j in rect:gmatch("%S+") do
                table.insert(TRstr[i], j)
              end
              
            end
            
            local testItemH = reaper.GetMediaItemInfo_Value(reaper.GetTrackMediaItem(track,0), "F_FREEMODE_H")
            
            local TRareaTable
            if NeedPerLane == true then
              --msg(#TRstr)
              local AreaParsed = ParseAreaPerLane(TRstr, testItemH)
              --msg(#AreaParsed)
              TRareaTable = AreaParsed
            else TRareaTable = TRstr end
        
            --FILL AREA DATA
            local i = 1
            
            while i <= #TRareaTable do
                --area data
                local areaStart = tonumber(TRareaTable[i][1])
                local areaEnd = tonumber(TRareaTable[i][2])
                local GUID = TRareaTable[i][3]
                local areaTop = tonumber(TRareaTable[i][4])
                local areaBottom = tonumber(TRareaTable[i][5])
                local isEnvelope = GUID ~= '""'

                --get item/envelope data
                local items = {}
                local envelopeName, envelope
                local envelopePoints
                
                if not isEnvelope then
                --reaper.ShowConsoleMsg(areaTop.." "..areaBottom.."\n\n")
                    items = GetItemsInRange(track, areaStart, areaEnd, areaTop, areaBottom)
                    if not AnythingForSplit and #items > 0 then AnythingForSplit = true end
                else
                    envelope = reaper.GetTrackEnvelopeByChunkName(track, GUID:sub(2, -2))
                    local ret, envName = reaper.GetEnvelopeName(envelope)

                    envelopeName = envName
                    envelopePoints = GetEnvelopePointsInRange(envelope, areaStart, areaEnd)
                end

                if not isEnvelope then
                  local areaData = {
                    areaStart = areaStart,
                    areaEnd = areaEnd,
                    areaTop = areaTop,
                    areaBottom = areaBottom,
                    
                    track = track,
                    items = items,
                    
                    --envelope data
                    isEnvelope = isEnvelope,
                    envelope = envelope,
                    envelopeName = envelopeName,
                    envelopePoints = envelopePoints,
                    GUID = GUID:sub(2, -2)
                  }

                  table.insert(areaMap, areaData)
                end

                i=i+1
            end
          end
        else  --if "I_FREEMODE" == 0
        
        ---OLD WAY for backward compatibility-------
        
          local ret, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
          
          if area ~= '' then
            --PARSE STRING
            local str = {}
            for j in string.gmatch(area, "%S+") do
                table.insert(str, j)
            end
        
            --FILL AREA DATA
            local j = 1
            while j <= #str do
                --area data
                local areaStart = tonumber(str[j])
                local areaEnd = tonumber(str[j+1])
                local GUID = str[j+2]
                local isEnvelope = GUID ~= '""'
        
                --get item/envelope data
                local items = {}
                local envelopeName, envelope
                local envelopePoints
                
                if not isEnvelope then
                    items = GetItemsInRange(track, areaStart, areaEnd)
                    if not AnythingForSplit and #items > 0 then AnythingForSplit = true end
                else
                    envelope = reaper.GetTrackEnvelopeByChunkName(track, GUID:sub(2, -2))
                    local ret, envName = reaper.GetEnvelopeName(envelope)
        
                    envelopeName = envName
                    envelopePoints = GetEnvelopePointsInRange(envelope, areaStart, areaEnd)
                end
        
                if not isEnvelope then
                  local areaData = {
                    areaStart = areaStart,
                    areaEnd = areaEnd,
                    
                    track = track,
                    items = items,
                    
                    --envelope data
                    isEnvelope = isEnvelope,
                    envelope = envelope,
                    envelopeName = envelopeName,
                    envelopePoints = envelopePoints,
                    GUID = GUID:sub(2, -2)
                  }
        
                  table.insert(areaMap, areaData)
                end
        
                j = j + 3
            end
          end
        end  ---OLD WAY END
    end  --trackCount

    return areaMap
end

-----------------------------------

function SplitRazorEdits(razorEdits)
    local areaItems = {} 
    local SplitsT = {}
    local ItemsToRegroup = {}
    
  local togAutoXfade = reaper.GetToggleCommandState(40912) --Options: Toggle auto-crossfade on split
  local togDefFades = reaper.GetToggleCommandState(41194) --Item: Toggle enable/disable default fadein/fadeout
   
  if togAutoXfade == 1 or (TogAutoXfadesEditing == 1 and RespTogAutoXfades == 1) then
    XfadeON = true
  end
  
  --Remove grouped items from grouped tables if they are enclosed by razor
  for r = 1, #razorEdits do
    local areaData = razorEdits[r]
    if not areaData.isEnvelope then
    
      for i = 1, #areaData.items do
        local item = areaData.items[i] 
        for k = 1, #razorEdits do
          if k ~= r then
            local areaData = razorEdits[k]
            _, areaData.grItems = FieldMatch(areaData.grItems, item, false)
            razorEdits[k]=areaData
          end
        end 
      end
      
    end -- if not areaData.isEnvelope
  end
  
  if TogItemGrouping == 1 and Opt.RazRespItemGroup == true then
    TogItemGrouping = 1 else TogItemGrouping = 0
  end
  
  --Split at areas Start
  SelSide = 'Right'
  local i = #razorEdits
  while i > 0 do
    local areaData = razorEdits[i]
    if not areaData.isEnvelope then
      table.move(areaData.items, 1, #areaData.items, #areaData.grItems+1, areaData.grItems)
      --msg('areaData.items') for j,v in pairs(areaData.items) do msg(v) end
      --msg('areaData.grItems') for j,v in pairs(areaData.grItems) do msg(v) end
      local sTime, selItems, itemsToRegroup, newItems =
      Split_Items_At_Time(areaData.items, areaData.grItems, {areaData.areaStart}, areaData.prevEdge) 
      table.move(sTime, 1, #sTime, #SplitsT+1, SplitsT)
      --table.move(newItems, 1, #newItems, #areaData.items+1, areaData.items)
      table.move(newItems, 1, #newItems, #areaData.grItems+1, areaData.grItems)
      razorEdits[i]['itemsToRegroup'] = itemsToRegroup
      --msg(razorEdits[i]['itemsToRegroup']['SplsGrs'])
      --msg(itemsToRegroup.SplGrs)
      --razorEdits[i]['items'] = areaData.items
    end
    i=i-1
  end
  
  --Collect items and regroup using razorEdits.RegroupAreasIDs
  for b = 1, #razorEdits.RegroupAreasIDs do
    local ItemsToRegroup = {}
    --ItemsToRegroup.SplGrs = {}
    local block = razorEdits.RegroupAreasIDs[b]
    for i = 1, #block do
      local id = block[i]
      local items = razorEdits[id]['itemsToRegroup'] 
      table.move(items, 1, #items, #ItemsToRegroup+1, ItemsToRegroup)
      --table.move(items.SplsGrs, 1, #items.SplsGrs, #ItemsToRegroup.SplGrs+1 ,ItemsToRegroup.SplGrs)
    end
    RegroupItems(ItemsToRegroup)
  end
  
  --Split at areas End
  SelSide = 'Left'
  local i = #razorEdits
  while i > 0 do
    local areaData = razorEdits[i]
    if not areaData.isEnvelope then
      --msg('areaData.items') for j,v in pairs(areaData.items) do msg(v) end
      --msg('areaData.grItems') for j,v in pairs(areaData.grItems) do msg(v) end 
      local sTime, selItems, itemsToRegroup = 
      Split_Items_At_Time(areaData.items, areaData.grItems, {areaData.areaEnd}, areaData.areaStart)
      table.move(sTime, 1, #sTime, #SplitsT+1, SplitsT)
      table.move(selItems, 1, #selItems, #areaItems+1, areaItems)
      razorEdits[i]['itemsToRegroup'] = itemsToRegroup
    end
    i=i-1
  end
  
  --Collect items and regroup using razorEdits.RegroupAreasIDs
  for b = 1, #razorEdits.RegroupAreasIDs do
    local ItemsToRegroup = {}
    local block = razorEdits.RegroupAreasIDs[b]
    for i = 1, #block do
      local id = block[i]
      local items = razorEdits[id]['itemsToRegroup']
      table.move(items, 1, #items, #ItemsToRegroup+1, ItemsToRegroup)
    end
    RegroupItems(ItemsToRegroup)
  end

    
  return areaItems, SplitsT
end

-----------------------------------

function CombineTables(A, B)
  local aN = #A
  local bN = #B
  for a = 1, aN do
    local add = true
    for b = 1, bN do
      if A[a] == B[b] then add = false end
    end
    if add == true then table.insert(B,A[a]) end
  end
  return B
end

-----------------------------------

function AddGroupInfo(AreasT)
  local RegroupAreasIDs = {}
  for i = 1, #AreasT do
    local areasIDs = {}
    local areaData = AreasT[i]
    if not areaData.isEnvelope then
        SelectItems(areaData.items,true, true)
        reaper.Main_OnCommandEx(40034, 0,0) -- Item grouping: Select all items in groups
        SelectItems(areaData.items,false, true)
        areaData.grItems = CollectSelectedItems()
        
        local k = i
        repeat
          if k == 1 then areaData.prevEdge = 0
          elseif AreasT[k-1]['track'] == areaData.track
          and  not AreasT[k-1]['isEnvelope'] then
            if AreasT[k-1]['areaEnd'] < areaData.areaStart then
            
              if AreasT[k-1]['areaTop'] and AreasT[k-1]['areaBottom'] then
              
                if areaData.areaTop < AreasT[k-1]['areaBottom']
                and areaData.areaBottom > AreasT[k-1]['areaTop'] then
                  areaData.prevEdge = AreasT[k-1]['areaEnd']
                end
                
              else areaData.prevEdge = AreasT[k-1]['areaEnd']
              end
              
            end
          end
          k=k-1
        until areaData.prevEdge ~= nil
        
        if #areaData.grItems > 0 then
          for c = 1, #AreasT do 
            local compareArea = AreasT[c]
            if compareArea.areaStart < areaData.areaEnd
            and compareArea.areaEnd > areaData.areaStart then
              table.insert(areasIDs, c)
            end
          end

          if #RegroupAreasIDs == 0 then table.insert(RegroupAreasIDs, areasIDs)
          else
            local AddNewGroup = true
            local subtableID
            
            for g = 1, #RegroupAreasIDs do 
              
              for f = 1, #areasIDs do 
                if FieldMatch(RegroupAreasIDs[g], areasIDs[f], nil) == true then
                  AddNewGroup = false
                  subtableID = g
                  break
                end
              end
              
            end 
            
            
            if AddNewGroup == false then
              RegroupAreasIDs[subtableID] = CombineTables(RegroupAreasIDs[subtableID], areasIDs)
              --break
            else table.insert(RegroupAreasIDs, areasIDs)
            end
            
          end --if #RegroupAreasIDs == 0
        end
        
        AreasT[i] = areaData
    end -- if not isEnvelope
  end -- for AreasT
  --[[
  for i = 1, #RegroupAreasIDs do --servise msg
    local block = RegroupAreasIDs[i]
    msg(table.concat(block, ' - '))
  end]]
  
  AreasT.RegroupAreasIDs = RegroupAreasIDs
  return AreasT
end

-----------------------------------

function split_byRE_andSel()
  local selections = GetRazorEdits()
  local items, SplitsT = {}
  if AnythingForSplit == true then
    reaper.Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh(1) 
    selectionsWithGrouping = AddGroupInfo(selections)
    items, SplitsT = SplitRazorEdits(selectionsWithGrouping)
  end
  
  if #items > 0 then
    SelectItems(items, true, true)
    reaper.Main_OnCommandEx(42406, 0, 0) --Razor edit: Clear all areas
    STime = SplitsT 
    UndoString = "Smart split at razor area"
  else
    reaper.defer(function()end)
  end

end


-----------------------------------------
--------------------------------------------


function split_automation_item()
  if TSexist == true then
    reaper.SetEditCurPos(TSstart, false, false)
    reaper.Main_OnCommandEx( 42087, 0, 0 ) -- Envelope: Split automation items
    --
    reaper.SetEditCurPos(TSend, false, false)
    reaper.Main_OnCommandEx( 42087, 0, 0 ) -- Envelope: Split automation items
    
    reaper.SetEditCurPos(Ecur_pos, false, false)
    
    UndoString = "Split automation items by TS"
  else
    reaper.Main_OnCommandEx( 40513, 0, 0 ) -- View: Move edit cursor to mouse cursor
    reaper.Main_OnCommandEx( 42087, 0, 0 ) -- Envelope: Split automation items
    reaper.SetEditCurPos(Ecur_pos, false, false)
    
    UndoString = "Split automation item by mouse"
  end
end


-----------------------------------------
--------------------------------------------


function unsel_automation_Items()
  for t=0, reaper.CountTracks(0)-1 do
    local tr = reaper.GetTrack(0,t)
    for e=0, reaper.CountTrackEnvelopes( tr ) -1 do
      local env = reaper.GetTrackEnvelope( tr, e )
      local aiNumb = reaper.CountAutomationItems( env )
      for AI=0, aiNumb -1 do
        reaper.GetSetAutomationItemInfo( env, AI, "D_UISEL", 0, true )
      end
    end
  end
end


-------------------------------------
------------------------------------

function updateMSG()
  local msg = "It's major update of Smart split script!"..'\n\n'..
  "Now there are options stored in your Reaper config."..'\n'..
  "To open the options window move mouse cursor to the transport or mixer panel and press assigned shortcut."..' '..
  "Or run dedicated script from the package."..'\n\n'..
  "Also there are many new features and variants of behavior."..'\n'..
  "I set some new options ON by default to promote them for new users."..'\n'..
  "Sorry, if that's not what you're waiting for, change that in options."..'\n\n'..
  "Take a look and have fun!"
  reaper.ShowMessageBox(msg, "Smart Split updated", 0)
end

-----------------------------------------
--------------------------------------------

function is_AI_for_split()
  if Window == "arrange" and Segment == "envelope" then
   local envLine, takeEnvelope = reaper.BR_GetMouseCursorContext_Envelope()
   
   if envLine and takeEnvelope == false then
   
     local aiNumber = reaper.CountAutomationItems( envLine ) -1
     
     for i = -1, aiNumber do
       local is_ai_sel = reaper.GetSetAutomationItemInfo( envLine, i, "D_UISEL", 0, false )
       local ai_pos = reaper.GetSetAutomationItemInfo( envLine, i, "D_POSITION", 0, false )
       local ai_end = ai_pos + reaper.GetSetAutomationItemInfo( envLine, i, "D_LENGTH", 0, false )
       if is_ai_sel == 1 and ai_pos < Mcur_pos and ai_end > Mcur_pos then
         return true
       end
     end
   end
   
  end
  return false
end

-----------------------------------
-----------------------------------

function GetTopBottomItemHalf()
local itempart
local x, y = reaper.GetMousePosition()

local item_under_mouse = reaper.GetItemFromPoint(x,y,true)

if item_under_mouse then

  local item_h = reaper.GetMediaItemInfo_Value( item_under_mouse, "I_LASTH" )
  
  local OScoeff = 1
  if reaper.GetOS():match("^Win") == nil then
    OScoeff = -1
  end
  
  local test_point = math.floor( y + (item_h-1) *OScoeff)
  local test_item, take = reaper.GetItemFromPoint( x, test_point, true )
  
  if item_under_mouse == test_item then
    itempart = "header"
  else
    local test_point = math.floor( y + item_h/2 *OScoeff)
    local test_item, take = reaper.GetItemFromPoint( x, test_point, true )
    
    if item_under_mouse ~= test_item then
      itempart = "bottom"
    else
      itempart = "top"
    end
  end

  return item_under_mouse, itempart
else return nil end

end

------------------------------

function GetPrefs(key) -- key need to be a string as in Reaper ini file
  local retval, buf = reaper.get_config_var_string( key )
  if retval == true then return tonumber(buf) end
end

------------------------------

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

------------------------------

function FindBiggestGroupID()
  BiggestGroupID = 0
  local itNumb = reaper.CountMediaItems(0)
  for i = 0, itNumb - 1 do
    local item = reaper.GetMediaItem(0,i)
    local groupID = reaper.GetMediaItemInfo_Value(item, 'I_GROUPID') 
    if groupID > BiggestGroupID then BiggestGroupID = groupID end 
  end
end

------------------------------

function CollectSelectedItems(TableToAdd,areaStart,areaEnd)
  local ItemsTable = {}
  if type(TableToAdd) == 'table' then
    ItemsTable = TableToAdd
  end
  
  local selItNumb = reaper.CountSelectedMediaItems(0)
  for i = 0, selItNumb - 1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    local itemLocked = reaper.GetMediaItemInfo_Value(item, 'C_LOCK')
    
    if areaStart and areaEnd then
      local iPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
      local iEnd = itemPos + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
      if iPos > areaEnd or iEnd < areaStart then item = nil end
    end
    
    if item and (itemLocked ~= 1 or Opt.RespLock == false) then
      table.insert(ItemsTable, item)
    end
    
  end
  return ItemsTable
end

------------------------------

function CollectAllItems()
  local ItemsTable = {}
  local itNumb = reaper.CountMediaItems(0)
  for i = 0, itNumb - 1 do
    local item = reaper.GetMediaItem(0,i)
    local itemPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local itemEnd = itemPos + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    local itemLocked = reaper.GetMediaItemInfo_Value(item, 'C_LOCK')
    local groupID = reaper.GetMediaItemInfo_Value(item, 'I_GROUPID')
    
    if not BiggestGroupID then BiggestGroupID = 0 end
    if groupID > BiggestGroupID then BiggestGroupID = groupID end 
    
    local collect = true
    
    if GlobalSplit == true and TSexist then
      if (itemPos >= TSstart and itemEnd <= TSstart)
      or (itemPos >= TSend or itemEnd <= TSstart) then collect = false end
    else if itemPos >= Ecur_pos or itemEnd <= Ecur_pos then collect = false end
    end
      
    if collect == true and (itemLocked ~= 1 or Opt.RespLock == false) then
      if Opt.GSplitHiddenTr == false then
        local track = reaper.GetMediaItemTrack(item) 
        if reaper.GetMediaTrackInfo_Value(track, 'B_SHOWINTCP') == 1 then
          table.insert(ItemsTable, item)
        end
      else table.insert(ItemsTable, item) end
    end
    
  end
  return ItemsTable
end

------------------------------

function AddGroupedItems(itemsTable, retWithoutInputs) --table, boolean
  local grItems = {}
  local grIDs = {}
  local allCnt = reaper.CountMediaItems(0)
  local inpCnt = #itemsTable
  
  for i = 1, inpCnt do
    local item = itemsTable[i]
    local groupID = reaper.GetMediaItemInfo_Value(item, 'I_GROUPID')
    if groupID ~= 0 and FieldMatch(grIDs, groupID) == false then
      table.insert(grIDs, groupID)
    end
  end
  
  if #grIDs > 0 then
    for i = 0, allCnt-1 do
      local item = reaper.GetMediaItem(0,i)
      local groupID = reaper.GetMediaItemInfo_Value(item, 'I_GROUPID')
      if groupID ~= 0 and FieldMatch(grIDs, groupID) == true then
        table.insert(grItems, item)
      end
    end
  end
  
  if retWithoutInputs == false then
    table.move(itemsTable, 1, #itemsTable, #grItems+1, grItems)
  end
  --msg(#grItems)
  return grItems
end

------------------------------

function isItemsForSplit(Items,time) --Table, number
  for i = 1, #Items do
    local item = Items[i]
    local itemPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local itemEnd = itemPos + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    local itemLocked = reaper.GetMediaItemInfo_Value(item, 'C_LOCK')
    
    if itemPos < time and itemEnd > time then
       return true
    end
  end
  return false
end

------------------------------

function remove_from_table(Table, value)
  local i = #Table
  while i > 0 do
    local field = Table[i]
    if field == value then table.remove(Table,i) end
    i = i-1
  end
end

-------------------------------

function AddTrMediaEditingGroup(Items, timeT)
  local GrSelTrs = reaper.GetToggleCommandState(42581) --Track: Automatically group selected tracks for media/razor editing
  local GrAllTrs = reaper.GetToggleCommandState(42580) --Track: Automatically group all tracks for media/razor editing
  
  for t, time in ipairs(timeT) do
    local Tracks = {}
    local ItemsH = {}
    local GrTracks = {}
    local GrIDsLow = 0
    local GrIDsHigh = 0
    local SelState = 0
    
    for i, item in ipairs(Items) do
      local ipos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
      local iend = ipos + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
      local tr = reaper.GetMediaItemTrack(item)
      if time > ipos and time < iend then
        FieldMatch(Tracks, tr, true)
        local mode = reaper.GetMediaTrackInfo_Value(tr, 'I_FREEMODE')
        local iY = reaper.GetMediaItemInfo_Value(item, 'F_FREEMODE_Y')
        local iH = reaper.GetMediaItemInfo_Value(item, 'F_FREEMODE_H')
        local iL = reaper.GetMediaItemInfo_Value(item, 'I_FIXEDLANE')
        ItemsH[tostring(item)] = {iY, iH, iL, mode}
      end
    end
    
    for i, tr in ipairs(Tracks) do -- collect gr info for tracks with initially captured items
      local intlow = reaper.GetSetTrackGroupMembership( tr, "MEDIA_EDIT_LEAD", 0, 0 )
      local inthigh = reaper.GetSetTrackGroupMembershipHigh( tr, "MEDIA_EDIT_LEAD", 0, 0 )
      local intSel = reaper.GetMediaTrackInfo_Value(tr, 'I_SELECTED')
      GrIDsLow = GrIDsLow | intlow
      GrIDsHigh = GrIDsHigh | inthigh
      SelState = SelState | intSel
    end
    
    
    for i = 1, reaper.CountTracks(0) do -- collect all matching group mappings
      local tr = reaper.GetTrack(0, i-1)
      local intlow = reaper.GetSetTrackGroupMembership( tr, "MEDIA_EDIT_LEAD", 0, 0 )
      local inthigh = reaper.GetSetTrackGroupMembershipHigh( tr, "MEDIA_EDIT_LEAD", 0, 0 )
      local intlowF = reaper.GetSetTrackGroupMembership( tr, "MEDIA_EDIT_FOLLOW", 0, 0 )
      local inthighF = reaper.GetSetTrackGroupMembershipHigh( tr, "MEDIA_EDIT_FOLLOW", 0, 0 )
      
      local intSel = reaper.GetMediaTrackInfo_Value(tr, 'I_SELECTED')
      
      if GrIDsLow & intlow ~= 0 or GrIDsLow & intlowF ~= 0 or SelState & intSel ~= 0 then
        GrIDsLow = GrIDsLow | intlow 
      end
      
      if GrIDsHigh & inthigh ~= 0 or GrIDsHigh & inthighF ~= 0 or SelState & intSel ~= 0 then
        GrIDsHigh = GrIDsHigh | inthigh 
      end
      --[[ 
      if reaper.IsTrackSelected(tr) == true and GrSelTrs == 1 then
      --and FieldMatch(Tracks, tr) == true then
        GrIDsLow = GrIDsLow | intlow
        GrIDsHigh = GrIDsHigh | inthigh
        msg('addSel')
      end
      ]]
    end
    
    for i = 1, reaper.CountTracks(0) do -- add corresponding tracks to the table
      local tr = reaper.GetTrack(0, i-1)
      if GrAllTrs == 1 then
        FieldMatch(GrTracks, tr, true)
      else
        local intlow = reaper.GetSetTrackGroupMembership( tr, "MEDIA_EDIT_LEAD", 0, 0 )
        local inthigh = reaper.GetSetTrackGroupMembershipHigh( tr, "MEDIA_EDIT_LEAD", 0, 0 )
        local intlowF = reaper.GetSetTrackGroupMembership( tr, "MEDIA_EDIT_FOLLOW", 0, 0 )
        local inthighF = reaper.GetSetTrackGroupMembershipHigh( tr, "MEDIA_EDIT_FOLLOW", 0, 0 )
        
        local intSel = reaper.GetMediaTrackInfo_Value(tr, 'I_SELECTED')
        
        if GrIDsLow & intlow ~= 0 or GrIDsLow & intlowF ~= 0 or SelState & intSel ~= 0 then
          table.insert(GrTracks, tr)
        end
        
        if GrIDsHigh & inthigh ~= 0 or GrIDsHigh & inthighF ~= 0 or SelState & intSel ~= 0 then
          FieldMatch(GrTracks, tr, true)
        end
        --[[ 
        if reaper.IsTrackSelected(tr) == true and GrSelTrs == 1 then
        --and FieldMatch(Tracks, tr) == true then
          FieldMatch(GrTracks, tr, true)
        end]]
      end
    end
    
    for i, tr in ipairs(GrTracks) do
      local mode = reaper.GetMediaTrackInfo_Value(tr, 'I_FREEMODE')
      for k = 0, reaper.CountTrackMediaItems(tr) -1 do
        local item = reaper.GetTrackMediaItem(tr, k)
        local ipos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        local iend = ipos + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')

        if time > ipos and time < iend then
          local iY = reaper.GetMediaItemInfo_Value(item, 'F_FREEMODE_Y')
          local iH = reaper.GetMediaItemInfo_Value(item, 'F_FREEMODE_H')
          local iL = reaper.GetMediaItemInfo_Value(item, 'I_FIXEDLANE')
          
          for h, refItem in pairs(ItemsH) do
            if mode == 2 and refItem[4] == mode then
              if refItem[3] == iL then FieldMatch(Items, item, true)
              end
            else 
              if math.abs(refItem[1] - iY) < math.min(refItem[2], iH)/5
              and math.max(refItem[2], iH) / math.min(refItem[2], iH) <= 1.5
              then
                FieldMatch(Items, item, true)
              end
            end
          end 
        end --if time > ipos and time < iend
        
      end --all items on the track cycle
    end --cycle through grouped tracks
    
  end -- timeT cycle
end

-------------------------------

function SelectAllMediaItems(proj, selected) --idx, boolean -- Works on hidden tracks
  local itNumb = reaper.CountMediaItems(proj)
  for i = 0, itNumb - 1 do
    local item = reaper.GetMediaItem(proj,i)
    reaper.SetMediaItemSelected(item, selected)
  end
end

-------------------------------

function SelectItems(Items, SelDesel, exclusiveFlag) -- table, boolean, boolean
  if exclusiveFlag == true and SelDesel == true then
    SelectAllMediaItems(0,false)
  end
  for i=1, #Items do
    local item = Items[i]
    reaper.SetMediaItemSelected(item, SelDesel)
  end
end

-------------------------------

function SetItemEdges(item, startTime, endTime)
  local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
  local isloop = reaper.GetMediaItemInfo_Value(item, 'B_LOOPSRC')
  reaper.SetMediaItemInfo_Value(item, 'D_POSITION', startTime)
  reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', endTime - startTime)
  local takesN = reaper.CountTakes(item)
  for i = 0, takesN-1 do
    local take = reaper.GetTake(item,i)
    if take then
      local offs = reaper.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
      local rate = reaper.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
      offs = offs + (startTime-pos)*rate
      if isloop == 1 then
        local src = reaper.GetMediaItemTake_Source( take )
        local length, isQN = reaper.GetMediaSourceLength( src )
        if offs < 0 then offs = length - math.fmod(-offs, length)
        elseif offs > length then offs = math.fmod(offs, length)
        end
      end
      
      local strmarksnum = reaper.GetTakeNumStretchMarkers( take )
      if strmarksnum > 0 then
        reaper.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', offs)
        for s = 0, strmarksnum -1 do
          local retval, strpos, srcpos = reaper.GetTakeStretchMarker( take, s   )
          reaper.SetTakeStretchMarker( take, s, strpos - (startTime-pos)*rate, srcpos )
        end
      else
        reaper.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', offs)
      end

      local takeenvs = reaper.CountTakeEnvelopes(take)
      for e = 0, takeenvs -1 do
        local env = reaper.GetTakeEnvelope( take, e )
        for p = 0, reaper.CountEnvelopePoints( env ) -1 do
          local ret, time, value, shape, tens, sel = reaper.GetEnvelopePoint( env, p )
          if ret then
            time = time - (startTime-pos)*rate
            reaper.SetEnvelopePoint( env, p, time, value, shape, tens, sel, true )
          end
        end
        reaper.Envelope_SortPoints( env )
      end
      
    end
  end
end

-------------------------------

function RegroupItems(Items)
  local SortedItems = {}
  local i = #Items
  while i > 0 do
    local item = Items[i]
    local itemGroup = reaper.GetMediaItemInfo_Value(item, 'I_GROUPID')
    
    if Items.SplGrs then
      if FieldMatch(Items.SplGrs, itemGroup) == true then
        if SortedItems[itemGroup] == nil then SortedItems[itemGroup] = {} end 
        table.insert(SortedItems[itemGroup],item)
      end
    else
      if SortedItems[itemGroup] == nil then SortedItems[itemGroup] = {} end
      table.insert(SortedItems[itemGroup],item)
    end
    i=i-1
  end
  
  for i, value in pairs(SortedItems) do
    if not BiggestGroupID then FindBiggestGroupID() end
    for v, item in pairs(value) do
       reaper.SetMediaItemInfo_Value( item, 'I_GROUPID', BiggestGroupID+1 )
    end
    BiggestGroupID = BiggestGroupID+1
  end
end

------------------------------
------------------------------

function Split_Items_At_Time(SelItems, ItemsToSplit, TimeTable, RazPrevEdge) --returns SplitsTable, SelItems, (ItemsToRegroup)
  table.sort(TimeTable)
  local newItems = {}
  local SplitsTable = {}
  local ItemsToRegroup = {}
  SelectAllMediaItems(0,false)
  
  local t = #TimeTable
  
  while t > 0 do
    if #TimeTable > 1 then
      if math.fmod(t, 2) ~= 0 then SelSide = 'Right' else SelSide = 'Left' end 
    end
    
    local splitTime = TimeTable[t]
    ItemsToRegroup = {}
    ItemsToRegroup.SplGrs = {}
    
    local i = #ItemsToSplit
    while i > 0 do
      local item = ItemsToSplit[i] 
      local itemPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
      local itemEnd = itemPos + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
      local itemGroup = reaper.GetMediaItemInfo_Value(item, 'I_GROUPID')
      
      if itemPos < splitTime and itemEnd > splitTime
      and (TogItemGrouping == 1 or FieldMatch(SelItems,item,nil) == true ) then
        
        local newItem = reaper.SplitMediaItem(item, splitTime) -- newItem on the right
        if newItem then
          table.insert(newItems, newItem)
          table.insert(SplitsTable, splitTime)
        end
        
        if itemGroup ~= 0 then
          table.insert(ItemsToRegroup, newItem)
          if FieldMatch(ItemsToRegroup.SplGrs, itemGroup) == false then table.insert(ItemsToRegroup.SplGrs, itemGroup) end
        end
        
        if SelSide == 'Right' then
          table.insert(SelItems, newItem)
          remove_from_table(SelItems, item)
        else
          table.insert(SelItems, item)
        end
        
        --Adapt crossfade--
        if newItem then
          local itemTake = reaper.GetActiveTake(item)
          local takeIsMidi
          local newPos
          local newEnd
          local newLfade
          local newRfade
          
          if itemTake then takeIsMidi = reaper.TakeIsMIDI(itemTake) end
          if itemTake and takeIsMidi == false then
            if XfadeON == true then
              local leftAutoFade = itemPos + math.max(0, reaper.GetMediaItemInfo_Value(item,'D_FADEINLEN_AUTO') )
              local rightAutoFade = itemEnd - math.max(0, reaper.GetMediaItemInfo_Value(newItem,'D_FADEOUTLEN_AUTO') )
              
              local leftTime = TimeTable[t-1] or RazPrevEdge or itemPos
              local rightTime = TimeTable[t+1] or itemEnd
              
              leftTime = math.max(leftTime, itemPos, leftAutoFade)
              rightTime = math.min(rightTime, itemEnd, rightAutoFade)
              
              if not PrefCrossfadeSize then PrefCrossfadeSize = GetPrefs('defsplitxfadelen') end
              if not LimitedCrossfade then
                LimitedCrossfade =
                (GetPrefs('splitmaxpix') * ((GetPrefs('splitautoxfade')&256) / 256) ) / reaper.GetHZoomLevel()
              end
              if LimitedCrossfade > 0 then
                PrefCrossfadeSize = math.min(PrefCrossfadeSize, LimitedCrossfade)
              end
              
              if Opt.CrossType == 'Left' then
                newPos = splitTime - PrefCrossfadeSize
                newEnd = splitTime
              elseif Opt.CrossType == 'Right' then
                newPos = splitTime
                newEnd = splitTime + PrefCrossfadeSize
              elseif Opt.CrossType == 'Centered' then
                newPos = splitTime - PrefCrossfadeSize/2
                newEnd = splitTime + PrefCrossfadeSize/2
              end
              
              if newPos < leftTime then
                newPos = leftTime + (splitTime - leftTime)/2
              end
              if newEnd > rightTime then
                newEnd = rightTime - (rightTime - splitTime)/2
              end
              SetItemEdges(newItem, newPos, itemEnd)
              SetItemEdges(item, itemPos, newEnd)
              reaper.SetMediaItemInfo_Value( newItem, "D_FADEINLEN_AUTO", newEnd-newPos )
              reaper.SetMediaItemInfo_Value( item, "D_FADEOUTLEN_AUTO", newEnd-newPos )
            end --if XfadeON == true
          end -- if itemTake and takeIsMidi == false
        end --end of crossfade adapt
        
      elseif itemPos >= splitTime then
        if itemGroup ~= 0 then
          table.insert(ItemsToRegroup, item)
        end
        if SelSide == 'Left'
        or (GlobalSplit == true and t == 2) then remove_from_table(SelItems, item)
        end
      elseif itemEnd <= splitTime then
        if SelSide == 'Right'
        or GlobalSplit == true then remove_from_table(SelItems, item)
        end
      end

      i=i-1
    end -- for ItemsToSplit
    
    if not RazPrevEdge then RegroupItems(ItemsToRegroup) end
    
    t=t-1
  end
  
  if #newItems == 0 then UndoString = nil end
  if RazPrevEdge == nil then
    ItemsToRegroup = nil
    newItems = nil
  end
  return SplitsTable, SelItems, ItemsToRegroup, newItems
end

------------------------------
------------------------------

function Main()
  SetOptGlobals()
  Ecur_pos = reaper.GetCursorPosition()
  Mcur_pos = reaper.BR_PositionAtMouseCursor( true )
  
  TogItemGrouping = reaper.GetToggleCommandState(1156) --Options: Toggle item grouping and track media/razor edit grouping
  TogAutoXfadesEditing = reaper.GetToggleCommandState(40041) --Options: Auto-crossfade media items when editing
  local splautoXConfVar = GetPrefs('splitautoxfade')
  RespTogAutoXfades = (splautoXConfVar&512)/512 --Prefs: Respect toolbar auto-crossfade button
  
  if RazorEditSelectionExists()==true then
    split_byRE_andSel()
  else
    
    Item_mouse, Half = GetTopBottomItemHalf() --what is context item or not
    if Item_mouse and Half ~= 'header' then
      MouseOnItem = true else MouseOnItem = false
    end
    
    if Opt.defSelSide then SelSide = Opt.defSelSide end
    
    TSstart, TSend = reaper.GetSet_LoopTimeRange2( 0, false, false, 0, 0, 0 )
    --calculations for big zoom
    local startArrange, endArrange = reaper.GetSet_ArrangeView2( 0, false, 0, 0, 0, 0 )
    local distance = (endArrange - startArrange)/4
    MouseSnapped = reaper.SnapToGrid(0,Mcur_pos)
    
    if MouseSnapped < startArrange or MouseSnapped > endArrange
    or math.abs(Mcur_pos - MouseSnapped) > distance then
      MouseSnapped = Mcur_pos
    end  --end of calculations for big zoom
    
    if TSstart == TSend or Opt.UseTSall == false then TSexist = false
    else TSexist = true
    end
    if Opt.UseTSdistance == true then
      if PixelDistance() == 'far' then TSexist = false end
    end
    
    if Opt.SnapMouse == false then MouseSnapped = Mcur_pos end
    
    reaper.Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    
    if is_AI_for_split() == true then
      split_automation_item()
    else --If likely there is no intention to split AIs--
      
      local SelectedItems = CollectSelectedItems()
      local inisel= {}
      local allItemsForSplit = {}
      local timeT = {}
      
      
      if #SelectedItems > 0 then
        inisel = SelectedItems 
      elseif MouseOnItem == true then
        inisel = {Item_mouse} 
      else
        if Opt.GlobSplit == true and GetPrefs('relativeedges')&256 == 0 then
          GlobalSplit = true
          SelectedItems = CollectAllItems()
          inisel = SelectedItems
        end
      end
      
      
      if MouseOnItem == true then
        if Opt.RespLock ~= 0
        and reaper.GetMediaItemInfo_Value(Item_mouse, 'C_LOCK') ~= 0 then
          return --no undo
        end --if item under mouse is not locked
        
        if Opt.SnapMouseEcur ~= 0 then
          local zoom = reaper.GetHZoomLevel()
          local distance = Opt.SnapMouseEcur / zoom
          if math.abs(Ecur_pos - Mcur_pos) <= distance then Opt.SnapMouseEcur = true end
        end
        
        timeT = { MouseSnapped }
        UndoString = 'Smart split at mouse cursor'
        
        if Opt['MouseT/B'] == 'left/right crossfade' then
          if Half == 'top' then Opt.CrossType = 'Left'
          elseif Half == 'bottom' then Opt.CrossType = 'Right'
          end
        elseif Opt['MouseT/B'] == 'select left/right item' then
          if Half == 'top' then SelSide = 'Left'
          elseif Half == 'bottom' then SelSide = 'Right'
          end
        end
        
        if reaper.IsMediaItemSelected( Item_mouse ) == false then
          SelectedItems = {}
          if Opt.AllowTSunsel == false then TSexist = false end
          SelectAllMediaItems(0, false)
          inisel = {Item_mouse} 
        elseif Opt.eCurPriority == true then 
          if isItemsForSplit(inisel, Ecur_pos) == true then
            timeT = {Ecur_pos}
            UndoString = nil
            if Opt.DontMoveECurSplit == true then Opt.MoveEditCursor = false end
          end 
        end
        
        if Opt.SnapMouseEcur == true then
          if isItemsForSplit(inisel, Ecur_pos) == true then
            timeT = {Ecur_pos}
            UndoString = nil
            if Opt.DontMoveECurSplit == true then Opt.MoveEditCursor = false end
          end 
        end
        
      else --if mouse is not over item
        timeT = {Ecur_pos} 
      end
      
      
      if TSexist == true
      and (#SelectedItems > 0 or Opt.AllowTSunsel == true) then --TS can't split unselected item under mouse
        if #SelectedItems > 0 and Opt.UseTSselItems == false then
          goto skip
        end
        
        if isItemsForSplit(inisel, TSstart) == true
        or isItemsForSplit(inisel, TSend) == true then 
          timeT = {TSstart, TSend}
          UndoString = 'Smart split at time selection'
        end
        ::skip::
        
      elseif UndoString == nil then
        if isItemsForSplit(inisel, Ecur_pos) == true then
          UndoString = 'Smart split at edit cursor'
          if Opt['MouseL/R'] == 'select left/right item' then
            if Mcur_pos < Ecur_pos then SelSide = 'Left' else SelSide = 'Right' end
          end
          if Opt['MouseL/R'] == 'left/right crossfade' then
            if Mcur_pos < Ecur_pos then Opt.CrossType = 'Left' else Opt.CrossType = 'Right' end
          end
          
          if MouseOnItem ~= true then Opt.MoveEditCursor = false end
        end
      end
      
      if #SelectedItems > 0 and Opt.UseTSselItems == false then TSexist = false end
      
      if UndoString ~= nil then
        if GlobalSplit ~= true then
          if reaper.CountSelectedMediaItems(0) == 0 then SelectItems(inisel, true, true) end
          reaper.Main_OnCommandEx(40034, 0,0) -- Item grouping: Select all items in groups
          --Warning! this ^^ action deselects not grouped items on hidden tracks.
          allItemsForSplit = CollectSelectedItems()
        else
          allItemsForSplit = AddGroupedItems(inisel, false)
        end
        
        if TogItemGrouping == 1 then
          AddTrMediaEditingGroup(allItemsForSplit, timeT)
        end
        
        local togAutoXfade = reaper.GetToggleCommandState(40912) --Options: Toggle auto-crossfade on split
        local togDefFades = reaper.GetToggleCommandState(41194) --Item: Toggle enable/disable default fadein/fadeout
        local defFadesON
        
        if togAutoXfade == 1 or (TogAutoXfadesEditing == 1 and RespTogAutoXfades == 1) then
          XfadeON = true
          if TSexist ~= true then
            if Opt['MouseT/B'] == 'fade/crossfade' and Half == 'top' then
              XfadeON = false
            elseif Opt['MouseT/B'] == 'crossfade/fade' and Half == 'bottom' then
              XfadeON = false
            end
          end
        end
        
        if togDefFades == 1 then 
          defFadesON = true
          if TSexist ~= true then
            if Opt['MouseT/B'] == 'fade/crossfade' and Half == 'bottom' then
              defFadesON = false
            elseif Opt['MouseT/B'] == 'crossfade/fade' and Half == 'top' then
              defFadesON = false
            end
          end
        end
        
        if togAutoXfade == 1 and XfadeON == false then 
          reaper.Main_OnCommandEx(40912,0,0) --Options: Toggle auto-crossfade on split
        end
        
        if TogAutoXfadesEditing == 1 and RespTogAutoXfades == 1 and XfadeON == false then -- turn crossfades off
          reaper.Main_OnCommandEx(40912,0,0) -- ON Options: Toggle auto-crossfade on split
          reaper.Main_OnCommandEx(40912,0,0) -- OFF Options: Toggle auto-crossfade on split
        end
        
        if defFadesON == false and XfadeON ~= true then
          reaper.Main_OnCommandEx(41194,0,0)  --Item: Toggle enable/disable default fadein/fadeout
        end
        
        local SelItems
        STime, SelItems = Split_Items_At_Time(inisel, allItemsForSplit, timeT)
        SelectItems(SelItems, true, true)
        unsel_automation_Items()
        
        if togAutoXfade == 1 and XfadeON == false then
          reaper.Main_OnCommandEx(40912,0,0) --Options: Toggle auto-crossfade on split
        end
        if defFadesON == false and XfadeON ~= true then
          reaper.Main_OnCommandEx(41194,0,0)  --Item: Toggle enable/disable default fadein/fadeout
        end
        
      end -- of if UndoString ~= nil
      
    end -- of if is_AI_for_split()
  
  end -- of if RazorEditSelectionExists()
  
  if TogAutoXfadesEditing == 1 and RespTogAutoXfades == 1 and XfadeON == false then -- turn crossfades off
    reaper.SNM_SetIntConfigVar( 'splitautoxfade', splautoXConfVar )
  end
  
  return UndoString
end

----------------------------

------------------
-------START------
CurVers = 3.4
version = tonumber( reaper.GetExtState(ExtStateName, "version") )
if version ~= CurVers then
  if not version or version < 3 then
    updateMSG()
  else reaper.ShowMessageBox('The script was updated to version '..CurVers ,'Smart split',0)
  end
  reaper.SetExtState(ExtStateName, "version", CurVers, true)
  reaper.defer(function()end)
else
  if reaper.APIExists( 'BR_GetMouseCursorContext' ) ~= true then
    reaper.ShowMessageBox('Please, install SWS extension!', 'No SWS extension', 0)
    return
  end
  
  Window, Segment, Details = reaper.BR_GetMouseCursorContext()
  local tcpActIDstr = reaper.GetExtState(ExtStateName, 'TCPaction')
  local tcpActID
  
  if Window == 'transport' or Window == 'mcp' then
    OptionsWindow()
  elseif Window == 'tcp' and tcpActIDstr ~= '' then 
    if tcpActIDstr:gsub('%d+', '') == '' then 
      tcpActID = tonumber(tcpActIDstr) 
    elseif tcpActIDstr ~= '' then 
      tcpActID = tonumber(reaper.NamedCommandLookup(tcpActIDstr))
    end
    reaper.Main_OnCommandEx(tcpActID,0,0)
  else
    OptionsDefaults()
    GetExtStates()
    local ret = Main()
    if ret ~= nil then --msg(UndoString)
      if STime then MoveEditCursor(STime, Ecur_pos) end
      reaper.Undo_EndBlock2( 0, UndoString, -1 )
      reaper.UpdateArrange()
    else reaper.defer(function()end) end  
  end
end

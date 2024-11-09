-- @description Trim left, right or both item edges via mouse and razor
-- @author AZ
-- @version 1.5
-- @changelog
--   - added option for trimming nearest/farthest edge of item as in the Fade tool script
--   - added TCP user action
--   - added font scaling for options window
-- @provides [main] az_Trim left, right or both item edges via mouse and razor/az_Open options for az_Trim left, right or both item edges via mouse and razor.lua
-- @link Forum thread https://forum.cockos.com/showthread.php?t=288069
-- @donation Donate via PayPal https://www.paypal.me/AZsound
-- @about
--   # Trim left, right or both item edges via mouse and razor
--
--   Use vertical mouse position to trim left or right edge (top/bottom item half) or closest/farthest edge.
--   Use razor to trim items at both sides.
--
--   To open options window place mouse on transport or mixer panel and press assigned shortcut.
--   Or use a dedicated script from the package.

--[[
TO MODIFY SCRIPT OPTIONS
OPEN THE OPTIONS WINDOW BY RUNNING THE SCRIPT WITH MOUSE ON TRANSPORT PANEL
]]
--Start load file
ExtStateName = "TrimItemsLeftRight_AZ"

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
  
  text = 'Respect snap for mouse trim'
  table.insert(OptDefaults, {text, 'RespSnapItems', true })
  
  text = 'Respect item grouping'
  table.insert(OptDefaults, {text, 'RespGrouping', true })
  
  text = 'Respect item grouping when trimming by razor'
  table.insert(OptDefaults, {text, 'razorRespGrouping', false })
  
  text = 'Select items after trimming by razor'
  table.insert(OptDefaults, {text, 'SelectItemsAfterRazorTrim', false })
  
  text = 'Mouse top / bottom placement on item is used for'
  table.insert(OptDefaults, {text, 'LRdefine', 'Left/Right edge trim', {
                                                      'Left/Right edge trim',
                                                      'Closest/Farthest edge trim' } })
  
end

-----------------------
-----------------------

function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end

--------------------------
function rgbToHex(rgba) -- passing a table with percentage value like {100, 50, 20, 90}
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
  dofile(imgui_path) '0.7'
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
  --------------
  function frame()
    reaper.ImGui_PushFont(ctx, font) 
    
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
        if imgui_version_num >= 18910 then
          reaper.ImGui_SeparatorText( ctx, option[1] )
        else
          reaper.ImGui_Text(ctx, option[1] )
        end
        
        reaper.ImGui_PopStyleColor(ctx, 1)
        reaper.ImGui_PopFont(ctx)
      end
      
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
      local doc = 'https://forum.cockos.com/showthread.php?t=288069'
      if reaper.CF_ShellExecute then
        reaper.CF_ShellExecute(doc)
      else
        reaper.MB(doc, 'Forum page for script Trim left or right item edges', 0)
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
      local visible, open = reaper.ImGui_Begin(ctx, 'Options for Trim left or right item edges', true, window_flags)
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
        if space == true then SetExtStates() end
      end
      
      if open and esc ~= true and enter ~= true then
          reaper.defer(loop)
      elseif enter == true then
          SetExtStates()
          reaper.ImGui_DestroyContext(ctx)
      else
          reaper.ImGui_DestroyContext(ctx)
      end
    loopcnt = loopcnt+1
  end
  -----------------
  local fontName
  ctx = reaper.ImGui_CreateContext('Options for Trim left or right item edges') -- Add VERSION TODO
  if reaper.GetOS():match("^Win") == nil then
    reaper.ImGui_SetConfigVar(ctx, reaper.ImGui_ConfigVar_ViewportsNoDecoration(), 0)
    fontName = 'sans-serif'
  else fontName = 'Calibri'
  end
  font = reaper.ImGui_CreateFont(fontName, fontSize, reaper.ImGui_FontFlags_None()) -- Create the fonts you need
  fontSep = reaper.ImGui_CreateFont(fontName, fontSize-2, reaper.ImGui_FontFlags_Italic())
  if imgui_version_num >= 18910 then
    reaper.ImGui_Attach(ctx, font)
    reaper.ImGui_Attach(ctx, fontSep)
  else
    reaper.ImGui_AttachFont(ctx, font)
    reaper.ImGui_AttachFont(ctx, fontSep)
  end
  
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

---------------------------------

function updateMSG()
  local msg = 'The script "az_Trim left, right or both item edges" was updated!'..'\n\n'..
  "Now there are options stored in your Reaper config."..'\n'..
  "To open the options window move mouse cursor to the transport or mixer panel and press assigned shortcut."..' '..
  "Or run dedicated script from the package."..'\n\n'..
  "Take a look and have fun!"
  reaper.ShowMessageBox(msg, "Trim script was updated", 0)
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
          local retval, strpos, srcpos = reaper.GetTakeStretchMarker( take, s )
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

---------------------------------

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
        
        if lock ~= 1 then
          local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
          local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
          local itemEndPos = pos+length
          
          if areaBottom ~= nil then
            itemTop = reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_Y")
            itemBottom = itemTop + reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_H")
            --msg("area: "..tostring(areaTop).." "..tostring(areaBottom).."\n".."item: "..itemTop.." "..itemBottom.."\n\n")
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
      areaWidth = math.floor(((areaBottom - areaTop)/itemH)+0.5) -- how many lanes include
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
        --reaper.ShowConsoleMsg("NEW WAY\n")
        
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
                    if #items > 0 then AnythingForSplit = true end
                else
                    envelope = reaper.GetTrackEnvelopeByChunkName(track, GUID:sub(2, -2))
                    local ret, envName = reaper.GetEnvelopeName(envelope)

                    envelopeName = envName
                    envelopePoints = GetEnvelopePointsInRange(envelope, areaStart, areaEnd)
                end

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

                i=i+1
            end
          end
        else  
        
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
                    if #items > 0 then AnythingForSplit = true end
                else
                    envelope = reaper.GetTrackEnvelopeByChunkName(track, GUID:sub(2, -2))
                    local ret, envName = reaper.GetEnvelopeName(envelope)
        
                    envelopeName = envName
                    envelopePoints = GetEnvelopePointsInRange(envelope, areaStart, areaEnd)
                end
        
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
        
                j = j + 3
            end
          end  ---OLD WAY END
        end
    end

    return areaMap
end

-----------------------

function TrimRazorEdits(razorEdits)
    local areaItems = {}
    local tracks = {}
    local SplitsT = {}
    local GrState = reaper.GetToggleCommandState(1156) --Options: Toggle item grouping override
    
    if AnythingForSplit == true then
      reaper.Undo_BeginBlock2( 0 )
      reaper.PreventUIRefresh(1)
      
      reaper.SelectAllMediaItems(0, false)
      
      for i = 1, #razorEdits do
        local areaData = razorEdits[i]
        if not areaData.isEnvelope then
            local items = areaData.items
            
            for j = 1, #items do
              local item = items[j]
              reaper.SetMediaItemSelected(item, true)
            end
            
            if Opt.razorRespGrouping == true and GrState == 1 then
              reaper.Main_OnCommandEx(40034,0,0) --Item grouping: Select all items in groups
            end
            
            trim_sel_items('right', areaData.areaEnd)
            trim_sel_items('left', areaData.areaStart)
            
            for i=1, reaper.CountSelectedMediaItems(0) do
              table.insert(areaItems, reaper.GetSelectedMediaItem(0, i-1))
            end
            table.insert(SplitsT, areaData.areaStart)
         end
      end
              
    --reaper.SetEditCurPos(cur_pos, false, false)
    reaper.PreventUIRefresh(-1)
  end --if AnythingForSplit
    
    return areaItems, SplitsT
end

-----------------------------------

function trim_byRE_andSel()
  SaveSelItems()
  local selections = GetRazorEdits()
  local items, SplitsT = TrimRazorEdits(selections)
  
  if #items > 0 then
    reaper.PreventUIRefresh( 1 )
    if Opt.SelectItemsAfterRazorTrim == true then
      for i = 1, #items do
        local item = items[i]
        reaper.SetMediaItemSelected(item, true)
        reaper.Main_OnCommandEx(42406, 0, 0) --clear RE area
      end
    else
      reaper.Main_OnCommandEx(42406, 0, 0) --clear RE area
      RestoreSelItems()
    end
    
    reaper.PreventUIRefresh( -1 )
    reaper.Undo_EndBlock2( 0, "Trim at razor area", -1 )
  else
    reaper.defer(function()end)
  end

end


-----------------------------------
-----------------------------------

--------------------------------
---------------------------------

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

function SaveSelItems()
  Sitems = {}
  for i = 0, reaper.CountSelectedMediaItems(0) -1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    table.insert(Sitems, item)
  end
  
end

----------------------------

function RestoreSelItems()
  reaper.SelectAllMediaItems(0, false)
  for i = 1, #Sitems do
    local item = Sitems[i]
    reaper.SetMediaItemSelected(item, true)
  end
end

----------------------------

function GetPrefs(key) -- key need to be a string as in Reaper ini file
  local retval, buf = reaper.get_config_var_string( key )
  if retval == true then return tonumber(buf) end
end

-----------------------------------------
--------------------------------------------


function trim_sel_items(side, trimTime) --side is 'left' or 'right'
local undoDesc
local iCount = reaper.CountSelectedMediaItems(0)

local defFlen = GetPrefs('deffadelen')
local defFshape = GetPrefs('deffadeshape')

for i=0, iCount-1 do
  local item = reaper.GetSelectedMediaItem(0,i)
  
  local iPos = reaper.GetMediaItemInfo_Value(item,'D_POSITION')
  local iEnd = iPos + reaper.GetMediaItemInfo_Value(item,'D_LENGTH')
  local fIn = reaper.GetMediaItemInfo_Value(item,'D_FADEINLEN')
  local fOut = reaper.GetMediaItemInfo_Value(item,'D_FADEOUTLEN')
  local fInA = reaper.GetMediaItemInfo_Value(item,'D_FADEINLEN_AUTO')
  local fOutA = reaper.GetMediaItemInfo_Value(item,'D_FADEOUTLEN_AUTO')
  
  local fInShape = reaper.GetMediaItemInfo_Value(item,'C_FADEINSHAPE')
  local fOutShape = reaper.GetMediaItemInfo_Value(item,'C_FADEOUTSHAPE')
  local fInCurv = reaper.GetMediaItemInfo_Value(item,'D_FADEINDIR')
  local fOutCurv = reaper.GetMediaItemInfo_Value(item,'D_FADEOUTDIR')
  
  if fInA ~= 0 then fIn = fInA end
  if fOutA~= 0 then fOut = fOutA end
  
  if iPos < trimTime and trimTime < iEnd then
  
    if side == 'left' then
      SetItemEdges(item, trimTime, iEnd)
      undoDesc = 'left'
      
      if trimTime < iPos+fIn then
        local param = 'D_FADEINLEN'
        if fInA ~= 0 then param = 'D_FADEINLEN_AUTO' end
        reaper.SetMediaItemInfo_Value(item, param, fIn-(trimTime-iPos))
        reaper.SetMediaItemInfo_Value(item,'C_FADEINSHAPE', fInShape)
        reaper.SetMediaItemInfo_Value(item,'D_FADEINDIR', fInCurv)
      else
        if reaper.GetToggleCommandState(41194) == 1 then fIn = defFlen else fIn = 0 end
        --^^--Item: Toggle enable/disable default fadein/fadeout
        reaper.SetMediaItemInfo_Value(item,'D_FADEINLEN', fIn)
        reaper.SetMediaItemInfo_Value(item,'C_FADEINSHAPE', defFshape)
        --reaper.SetMediaItemInfo_Value(item,'D_FADEINDIR', defFshape)
      end
      
    elseif side == 'right' then
      SetItemEdges(item, iPos, trimTime)
      undoDesc = 'right'
      
      if trimTime > iEnd-fOut then
        local param = 'D_FADEOUTLEN'
        if fOutA~= 0 then param = 'D_FADEOUTLEN_AUTO' end
        reaper.SetMediaItemInfo_Value(item, param, fOut-(iEnd-trimTime))
        reaper.SetMediaItemInfo_Value(item,'C_FADEOUTSHAPE', fOutShape)
        reaper.SetMediaItemInfo_Value(item,'D_FADEOUTDIR', fOutCurv)
      else
        if reaper.GetToggleCommandState(41194) == 1 then fOut = defFlen else fOut = 0 end
        --^^--Item: Toggle enable/disable default fadein/fadeout
        reaper.SetMediaItemInfo_Value(item,'D_FADEOUTLEN', fOut)
        reaper.SetMediaItemInfo_Value(item,'C_FADEOUTSHAPE', defFshape)
        --reaper.SetMediaItemInfo_Value(item,'D_FADEOUTDIR', defFshape)
      end
    end --left/right
    
  end --if cur_pos
end --for

return undoDesc
end


-----------------------------------------
--------------------------------------------

function WhatTrim(half, leftF, rightF, mPos)
  local f_type
  
  if Opt.LRdefine == 'Closest/Farthest edge trim' then --cross define
    if half == "top" then
      if (rightF - mPos) <= (mPos - leftF) then
        f_type = "right"
      else
        f_type = "left"
      end
    elseif half == "bottom" then
      if (rightF - mPos) > (mPos - leftF) then
        f_type = "right"
      else
        f_type = "left"
      end
    end
  elseif Opt.LRdefine == 'Left/Right edge trim' then
    if half == "top" then
      f_type = "left"
    elseif half == "bottom" then
      f_type = "right"
    end
  end
  
  return f_type
end

-----------------------------------------
-----------------------------------------

function MouseTrim()
 
  local item, half = GetTopBottomItemHalf()
  
  if half == "header" or not item then  --if mouse cursor not on the item
    reaper.defer(function() end)
  end
  
  if item and half ~= "header" then
    reaper.Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    
    local mPos = reaper.BR_PositionAtMouseCursor(false) 
    local trimTime
    if Opt.RespSnapItems == true then
      trimTime = reaper.SnapToGrid(0,mPos)
    else trimTime = mPos
    end
    
    GroupEnabled = reaper.GetToggleCommandState(1156) --Options: Toggle item grouping override
    
    SaveSelItems()
    
    if reaper.IsMediaItemSelected(item) == false then
      reaper.SelectAllMediaItems( 0, false )
      reaper.SetMediaItemSelected(item, true)
    end
    
    if Opt.RespGrouping == true and GroupEnabled == 1 then
      reaper.Main_OnCommandEx(40034,0,0) --Item grouping: Select all items in groups
    end
    
    local iPos = reaper.GetMediaItemInfo_Value(item,'D_POSITION')
    local iEnd = iPos + reaper.GetMediaItemInfo_Value(item,'D_LENGTH')
    
    local side = WhatTrim(half, iPos, iEnd, mPos)
    
    undoType = trim_sel_items(side, trimTime)
    
    RestoreSelItems()
    reaper.PreventUIRefresh( -1 )
    if undoType then
      reaper.Undo_EndBlock2( 0, "Trim "..undoType.." edge of items under mouse", -1 )
      reaper.UpdateArrange()
    else reaper.defer(function()end) end
    
    
 
  end
end
--------------------------

-------START------
CurVers = 1.5
version = tonumber( reaper.GetExtState(ExtStateName, "version") )

if version ~= CurVers then
  if not version or version < 1.2 then
    updateMSG()
  else reaper.ShowMessageBox('The script was updated to version '..CurVers ,'Trim items from left or right',0)
  end
  reaper.SetExtState(ExtStateName, "version", CurVers, true)
  reaper.defer(function()end)
else
  if reaper.APIExists( 'BR_GetMouseCursorContext' ) ~= true then
    reaper.ShowMessageBox('Please, install SWS extension!', 'No SWS extension', 0)
    return
  end
  Window, Segment, Details = reaper.BR_GetMouseCursorContext()
  if Window == 'transport' or Window == 'mcp' then
    OptionsWindow()
  else
    OptionsDefaults()
    GetExtStates()
    SetOptGlobals()
    if RazorEditSelectionExists() == true then
      trim_byRE_andSel()
    else
      MouseTrim()
    end
  end
end

-- @noindex


ExtStateName = "SimpleReconform_AZ"

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

----------------------------------

function SetGUIcolors()
  local gui_colors = {
    White = rgbToHex({90,90,90,100}),
    Green = rgbToHex({52,85,52,100}),
    Red = rgbToHex({80,30,30,100}),
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
  
  return gui_colors
end

---------------------

function SetGUIflags()
  local Flags = {}
    Flags.childRounding = reaper.ImGui_StyleVar_ChildRounding()
    Flags.frameRounding = reaper.ImGui_StyleVar_FrameRounding()
    Flags.childBorder = reaper.ImGui_ChildFlags_Borders()
    Flags.menubar = reaper.ImGui_WindowFlags_MenuBar()
    Flags.tableResizeflag = reaper.ImGui_TableFlags_Resizable()
    Flags.childAutoResizeX = reaper.ImGui_ChildFlags_AutoResizeX()
    Flags.childAutoResizeY = reaper.ImGui_ChildFlags_AutoResizeY()
  return Flags
end

--------------------

function PUSHstyle(ctx, gui_colors, Flags, fontSize)
  local colorCnt, styleCnt
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
  
  colorCnt = 13
  --
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(), fontSize/4)
  reaper.ImGui_PushStyleVar(ctx, Flags.frameRounding, fontSize/4)
  reaper.ImGui_PushStyleVar(ctx, Flags.childRounding, fontSize/4)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), fontSize/2, fontSize/4)
  styleCnt = 4
  
  return colorCnt, styleCnt
end

------------------

function serializeTable(tbl)
    return "return " .. tableToString(tbl)
end

--------

function tableToString(tbl, indent)
    indent = indent or 0
    local result = "{\n"
    local prefix = string.rep("  ", indent + 1)

    for k, v in pairs(tbl) do
        local key
        if type(k) == "string" then
            key = string.format("[%q]", k)
        else
            key = string.format("[%s]", tostring(k))
        end

        if type(v) == "table" then
            result = result .. prefix .. key .. " = " .. tableToString(v, indent + 1) .. ",\n"
        elseif type(v) == "string" then
            result = result .. prefix .. key .. " = " .. string.format("%q", v) .. ",\n"
        else
            result = result .. prefix .. key .. " = " .. tostring(v) .. ",\n"
        end
    end

    result = result .. string.rep("  ", indent) .. "}"
    return result
end

-----------------------------

function round(value, digitsAfterDot)
  return tonumber(string.format("%."..digitsAfterDot.."f", tostring(value)))
end

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
        local offset = reaper.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
        table.insert(ItemsTable, {round(offset,4), round(offset + refLength, 4), round(refPos,4)})
        
        local tr = reaper.GetMediaItem_Track(item)
        local trID = reaper.GetMediaTrackInfo_Value( tr, 'IP_TRACKNUMBER' ) -1
        
        if LastRefTrID < trID then LastRefTrID = trID end
        
        if prevEnd then
          if refPos - prevEnd > MIN_luft_ZERO then
            table.insert(Gaps, {round(prevEnd,4), round(refPos,4)})
          end
        end
        
        prevEnd = refPos + refLength
      end
    end
    
  end
  
  reaper.SetProjExtState(0,ExtStateName, 'OldPrjStart', OldPrjStart )
  if #ItemsTable ~= 0 then
    reaper.SetProjExtState(0,ExtStateName, 'RefTrack', serializeTable(ItemsTable) )
  end
  
  return ItemsTable
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

-------------------------

function GetMinLuftZero(PrjTimeOffset)
  return ( reaper.parse_timestr_pos('00:00:00:01', 5) - PrjTimeOffset ) / 4
end
----------------------

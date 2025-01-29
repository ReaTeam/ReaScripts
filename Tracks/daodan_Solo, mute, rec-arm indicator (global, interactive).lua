-- @description Solo, mute, rec-arm indicator (global, interactive)
-- @author daodan
-- @version 1.0
-- @link Forum thread https://forum.cockos.com/showthread.php?t=297880
-- @about
--   #Interactive solo/mute/rec-arm indicator
--
--   Usage: Run script. Solo button lights up when there is soloed track in project. Click button to unsolo all tracks. Click again to restore previous solo states. Same for mute and rec-arm.\
--   Rigth click button for additional actions and settings.

--DEFAULT SETTINGS--


local ButtonON_Action_ID = 1 -- default action when there is muted/soloed tracks (lit button) and m/s bitton clicked
                                --1 - disable solo/mute/rec-arm on all track
                                --2 - disable solo/mute/rec-arm on selected tracks
                                
                                      --note: state saved when you click lit button (when there is any muted/soled track)
local ButtonOFF_Action_ID = 3 -- default action when there is no muted/soloed tracks (not lit button) and m/s bitton clicked
                                --1 - solo/mute/rec-arm selected tracks
                                --2 - exclusive solo/mute/rec-arm selected tracks
                                --3 - restore state all tracks
                                --4 - restore state selected tracks
                                      --note: state saved when you click lit button (when there is any muted/soled track)

buttons = 
{
  order    = { 1       , 2    , 3     },-- 1 rec-arm, 2 mute, 3 solo
  namesFull= {'rec-arm','mute', 'solo'},
  names    = {},
  colors_h = {},
  states   = {}
}

local function SettingsLOAD(reset) -- reset to load default settings)
  local r = reset
  SettingsFILENAME = "daodan_solo, mute, rec-arm indicator [settings].lua"
  dir = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")
  local fh = io.open( dir..SettingsFILENAME, "r" )
  if fh then
    --> File Found. dofile
    io.close(fh)
    dofile(dir..SettingsFILENAME)
  else
    r = true
  end
  
 --load default if not found in SettingsFILENAME file  | defaults         |
      if r or orderString == nil or orderString == '' then orderString = 'rms'
  
  end if r or buttons.names[1] == nil or buttons.names[1]  == '' then  buttons.names[1] = 'R'
  end if r or buttons.names[2] == nil or buttons.names[2] == '' then buttons.names[2] = 'M'
  end if r or buttons.names[3] == nil or buttons.names[3] == '' then buttons.names[3] = 'S'
  
  end if r or frameRounding  == nil then  frameRounding = 0
  
  end if r or sizeX          == nil then          sizeX = 11
  end if r or sizeY          == nil then          sizeY = 3
  end if r or spacingX       == nil then       spacingX = 8
  
  end if r or showToolTips   == nil then   showToolTips = true
  end if r or showBackgroung == nil then showBackgroung = false
  end if r or showOnTop      == nil then      showOnTop = false
  end if r or verticalLayout == nil then verticalLayout = false
  end if r or ignoreMonOnlyR == nil then ignoreMonOnlyR = true
  
  end if r or useCastomFont  == nil then  useCastomFont = false
  end if r or cstFnt == nil or cstFnt == '' then cstFnt = 'Terminator Two'
  end if r or cstFntSize     == nil then     cstFntSize = 20
  
  end if r or buttons.colors_h[1]      == nil then      buttons.colors_h[1] = 0.0
  end if r or buttons.colors_h[2]     == nil then     buttons.colors_h[2] = 0.0
  end if r or buttons.colors_h[3]     == nil then     buttons.colors_h[3] = 1.0
  end if r or colors_sat     == nil then     colors_sat = 0.9
  end if r or colors_vol     == nil then     colors_vol = 1.0
  end if r or colors_alp     == nil then     colors_alp = 1.0
  
  end if r or colors_OFF_hue == nil then colors_OFF_hue = 4.1
  end if r or colors_OFF_sat == nil then colors_OFF_sat = 1.0
  end if r or colors_OFF_vol == nil then colors_OFF_vol = 1.0
  end if r or colors_OFF_alp == nil then colors_OFF_alp = 0.6
  
  end if r or colors_TXT_hue == nil then colors_TXT_hue = 0.0
  end if r or colors_TXT_sat == nil then colors_TXT_sat = 0.0
  end if r or colors_TXT_vol == nil then colors_TXT_vol = 1.0
  end if r or colors_TXT_alp == nil then colors_TXT_alp = 1.0
  end                                                
end
--END OF DEFAULT SETTINGS--

function SettingsWRITEFILE()

  local settingsString = 
          "orderString = '"..tostring(orderString).."'"
          
..'\n'..  "buttons.names[1] = '"..tostring(buttons.names[1]).."'"
..'\n'..  "buttons.names[2] = '"..tostring(buttons.names[2]).."'"
..'\n'..  "buttons.names[3] = '"..tostring(buttons.names[3]).."'"
          
..'\n'..  "frameRounding = "..tostring(frameRounding)

..'\n'..  "sizeX = "..tostring(sizeX)
..'\n'..  "sizeY = "..tostring(sizeY)
..'\n'..  "spacingX = "..tostring(spacingX)

..'\n'..  "showToolTips = "..tostring(showToolTips)
..'\n'..  "showBackgroung = "..tostring(showBackgroung)
..'\n'..  "showOnTop = "..tostring(showOnTop)
..'\n'..  "verticalLayout = "..tostring(verticalLayout)
..'\n'..  "ignoreMonOnlyR = "..tostring(ignoreMonOnlyR)

..'\n'..  "useCastomFont = "..tostring(useCastomFont)
..'\n'..  "cstFnt = '"..tostring(cstFnt).."'"
..'\n'..  "cstFntSize = "..tostring(cstFntSize)

..'\n'..  "buttons.colors_h[1] = "..tostring(buttons.colors_h[1])
..'\n'..  "buttons.colors_h[2] = "..tostring(buttons.colors_h[2])
..'\n'..  "buttons.colors_h[3] = "..tostring(buttons.colors_h[3])
..'\n'..  "colors_sat = "..tostring(colors_sat)
..'\n'..  "colors_vol = "..tostring(colors_vol)
..'\n'..  "colors_alp = "..tostring(colors_alp)

..'\n'..  "colors_OFF_hue = "..tostring(colors_OFF_hue)
..'\n'..  "colors_OFF_sat = "..tostring(colors_OFF_sat)
..'\n'..  "colors_OFF_vol = "..tostring(colors_OFF_vol)
..'\n'..  "colors_OFF_alp = "..tostring(colors_OFF_alp)

..'\n'..  "colors_TXT_hue = "..tostring(colors_TXT_hue)
..'\n'..  "colors_TXT_sat = "..tostring(colors_TXT_sat)
..'\n'..  "colors_TXT_vol = "..tostring(colors_TXT_vol)
..'\n'..  "colors_TXT_alp = "..tostring(colors_TXT_alp)
  
  local file = assert(io.open(dir..SettingsFILENAME, 'w'))
  file:write(settingsString)
  file:close()
  
end

if not reaper.ImGui_GetBuiltinPath then
  return reaper.MB('ReaImGui is not installed or too old.', 'Solo/mute indicator', 0)
end

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9.3'

SettingsLOAD()

local ctx = ImGui.CreateContext('Solo/mute/rec-arm indicator')
font = ImGui.CreateFont(cstFnt, cstFntSize)
ImGui.Attach(ctx, font)

local recArmed
local muted
local soloed
local recarmStates = {}
local muteStates = {}
local soloStates = {}

local ButtonON_Action_text = 
{'disable solo on all tracks'  ,'disable solo on selected tracks','nothing','nothing', --01,02,03,04
 'disable mute on all track'   ,'disable mute on selected tracks','nothing','nothing', --05,06,07,08 (+4)
 'disable rec-arm on all track','disable arm on selected tracks' ,'nothing','nothing'} --09,10,11,12 (+8)

local ButtonOFF_Action_text = 
{'solo selected tracks'   ,'solo selected tracks (exclusive)'   ,'restore solo (all tracks)'   ,'restore solo (selected tracks)'   ,--01,02,03,04
 'mute selected tracks'   ,'mute selected tracks (exclusive)'   ,'restore mute (all tracks)'   ,'restore mute (selected tracks)'   ,--05,06,07,08 (+4)
 'rec-arm selected tracks','rec-arm selected tracks (exclusive)','restore rec-arm (all tracks)','restore rec-arm (selected tracks)'}--09,10,11,12 (+8)

function ToolTip(desc)
  if ImGui.BeginItemTooltip(ctx) then
    ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 35.0)
    ImGui.Text(ctx, desc)
    ImGui.PopTextWrapPos(ctx)
    ImGui.EndTooltip(ctx)
  end
end

function HSV(h, s, v, a)
  local r, g, b = ImGui.ColorConvertHSVtoRGB(h, s, v)
  return ImGui.ColorConvertDouble4ToU32(r, g, b, a or 1.0)
end

function OnClose()
  SettingsWRITEFILE()
end

function StatesCheck()
  local trackCount = reaper.CountTracks(0)
  local gotRecArm, gotMute, gotSolo = false
  
  for trackidx=0, trackCount-1 do
  
    local tr = reaper.GetTrack(0,trackidx)
    
    if not gotMute ~= 1 and reaper.GetMediaTrackInfo_Value(tr,'B_MUTE') > 0 then 
      gotMute = true
      muted = true
    end
    
    if not gotSolo and reaper.GetMediaTrackInfo_Value(tr,'I_SOLO') > 0 then 
      gotSolo = true
      soloed = true
    end
    
    if not gotRecArm and reaper.GetMediaTrackInfo_Value(tr,'I_RECARM') > 0 then
      if reaper.GetMediaTrackInfo_Value(tr,'I_RECMODE')==2 and ignoreMonOnlyR then
       --ignore monitoring only tracks
      else
        gotRecArm = true
        recArmed = true
      end
    end
    
    if gotRecArm == true and gotMute == true and gotSolo == true then return end
    if not gotRecArm then recArmed = false end
    if not gotMute   then muted    = false end
    if not gotSolo   then soloed   = false end
    
  end
  
end

function StatesMuteSave()
  local trackCount = reaper.CountTracks(0)
  for trackidx=0, trackCount-1 do
    local tr = reaper.GetTrack(0, trackidx)
    local mute = reaper.GetMediaTrackInfo_Value( tr, "B_MUTE" )
    muteStates[tr] = mute
  end
end

function StatesMuteRestore(id)
  if id == 3 then --restore all tracks
    local trackCount
    trackCount = reaper.CountTracks(0)
    for trackidx=0, trackCount-1 do
      local tr = reaper.GetTrack(0, trackidx)
      if not muteStates[tr] then return end
      local mute = reaper.GetMediaTrackInfo_Value( tr, "B_MUTE" )
      if mute ~= muteStates[tr] then  reaper.SetMediaTrackInfo_Value( tr, "B_MUTE", muteStates[tr]) end
    end
  elseif id == 4 then--restore selected tracks
    trackCount = reaper.CountSelectedTracks( 0 )
    for trackidx=0, trackCount-1 do
      local tr = reaper.GetSelectedTrack( 0, trackidx )
      if not muteStates[tr] then return end
      local mute = reaper.GetMediaTrackInfo_Value( tr, "B_MUTE" )
      if mute ~= muteStates[tr] then  reaper.SetMediaTrackInfo_Value( tr, "B_MUTE", muteStates[tr]) end
    end
  end
end

function StatesSoloSave()
  local trackCount = reaper.CountTracks(0)
  for trackidx=0, trackCount-1 do
    local tr = reaper.GetTrack(0, trackidx)
    local solo = reaper.GetMediaTrackInfo_Value( tr, "I_SOLO" )
    soloStates[tr] = solo
  end
end

function StatesSoloRestore(id)
  if id == 3 then
    local trackCount
    trackCount = reaper.CountTracks(0)
    for trackidx=0, trackCount-1 do
      local tr = reaper.GetTrack(0, trackidx)
      if not soloStates[tr] then return end
      local solo = reaper.GetMediaTrackInfo_Value( tr, "I_SOLO" )
      if solo ~= soloStates[tr] then  reaper.SetMediaTrackInfo_Value( tr, "I_SOLO", soloStates[tr]) end
    end
  elseif id == 4 then
    trackCount = reaper.CountSelectedTracks( 0 )
    for trackidx=0, trackCount-1 do
      local tr = reaper.GetSelectedTrack( 0, trackidx )
      if not soloStates[tr] then return end
      local solo = reaper.GetMediaTrackInfo_Value( tr, "I_SOLO" )
      if solo ~= soloStates[tr] then  reaper.SetMediaTrackInfo_Value( tr, "I_SOLO", soloStates[tr]) end
    end
  end
end

function StatesRecArmSave()
  local trackCount = reaper.CountTracks(0)
  for trackidx=0, trackCount-1 do
    local tr = reaper.GetTrack(0, trackidx)
    local recarm = reaper.GetMediaTrackInfo_Value( tr, "I_RECARM" )
    recarmStates[tr] = recarm
  end
end

function StatesRecArmRestore(id)
  if id == 3 then
    local trackCount
    trackCount = reaper.CountTracks(0)
    for trackidx=0, trackCount-1 do
      local tr = reaper.GetTrack(0, trackidx)
      if not recarmStates[tr] then return end
      reaper.SetMediaTrackInfo_Value( tr, "I_RECARM", recarmStates[tr])
    end
   
  elseif id == 4 then
    trackCount = reaper.CountSelectedTracks( 0 )
    for trackidx=0, trackCount-1 do
      local tr = reaper.GetSelectedTrack( 0, trackidx )
      if not recarmStates[tr] then return end
      reaper.SetMediaTrackInfo_Value( tr, "I_RECARM", recarmStates[tr])
    end
  end
end

function RecArmDisable(allOrSel) -- 1 for all track
  
  local trackCount
  
  if allOrSel == 1 then trackCount = reaper.CountTracks(0)
                   else trackCount = reaper.CountSelectedTracks(0)end
  
  
  for trackidx=0, trackCount-1 do
    local tr = reaper.GetTrack(0, trackidx)
    if reaper.GetMediaTrackInfo_Value(tr,'I_RECMODE')==2 and ignoreMonOnlyR then
      --ignore monitoring only tracks
    else
      reaper.SetMediaTrackInfo_Value( tr, "I_RECARM", 0)
    end
  end
  
end

function RecArmEnable()

  local trackCount
  trackCount = reaper.CountSelectedTracks(0)
  for trackidx=0, trackCount-1 do
    tr = reaper.GetSelectedTrack(0, trackidx)
    reaper.SetMediaTrackInfo_Value( tr, "I_RECARM", 1)
  end
  
end

function ActionsDisable(RMS,AllOrSel)
  
  if AllOrSel == 1 then
    if RMS == 1 then
      StatesRecArmSave()
      RecArmDisable(AllOrSel)--unrec all
    elseif RMS == 2 then
      StatesMuteSave()
      reaper.Main_OnCommand(40339,0)--unmute all
    elseif RMS == 3 then
      StatesSoloSave()
      reaper.Main_OnCommand(40340,0)--unsolo all
    end
  else
    if reaper.GetSelectedTrack(0,0) then
      if RMS == 1 then
        StatesRecArmSave()
        RecArmDisable(AllOrSel)--unrec sel
      elseif RMS == 2 then
        StatesMuteSave()
        reaper.Main_OnCommand(40731,0)--unmute sel
      elseif RMS == 3 then
        StatesSoloSave()
        reaper.Main_OnCommand(40729,0)--unsolo sel
      end
    end
  end
  
end

function ActionsEnable(RMS,excl)
  
  if reaper.GetSelectedTrack(0,0) then
    if RMS == 1 then
      StatesRecArmSave()
      if excl then 
      RecArmDisable(1) end -- unmrecarm all tracks if exclusive
      RecArmEnable() --rec arm selected tracks
    elseif RMS == 2 then
      StatesMuteSave()
      if excl then reaper.Main_OnCommand(40339,0) end -- unmute all tracks if exclusive
      reaper.Main_OnCommand(40730,0)--mute selected tracks
    elseif RMS == 3 then
      StatesSoloSave()
      if excl then reaper.Main_OnCommand(40340,0) end -- unsolo all tracks
      reaper.Main_OnCommand(40728,0)--solo sel tracks
    end
  end
end

function ButtonON_Action(id, RMS)
  reaper.PreventUIRefresh(1)
  if id == 1 then
    ActionsDisable(RMS,1) --unmute or solo all tracks
  elseif id == 2 then
    ActionsDisable(RMS,0) --unmute or solo sel tracks
  end
  reaper.PreventUIRefresh(-1)
end

function ButtonOFF_Action(id, RMS)
  reaper.PreventUIRefresh(1)
  if id == 1 then
    ActionsEnable(RMS) --mute/solo/rec sel tracks
  elseif id == 2 then
    ActionsEnable(RMS,1) --exclusive
  else
    if RMS == 1 then
      StatesRecArmRestore(id)
    elseif RMS == 2 then
      StatesMuteRestore(id)
    elseif RMS == 3 then
      StatesSoloRestore(id)
    end
  end
  reaper.PreventUIRefresh(-1)
end

function ConvertOrderString(newOrderString)
  
  local newOrder = {}
  local defaultOrderString = 'rms'
  newOrderString = string.lower(newOrderString)
  
  if string.len(newOrderString) > 0 then
    for i=1, string.len(newOrderString) do
      local curent = newOrderString:sub(i, i)
      local curentPos= string.find(defaultOrderString,curent)
      if curentPos then table.insert(newOrder,curentPos) end
    end
  else
    newOrder={1,2,3}
  end
  
  return newOrder
  
end

buttons.order = ConvertOrderString(orderString) --override with order string

local function StyleSet(pushPop,o) --1 to push, 0 to pop; o for order (what button)
    
    if pushPop == 1 then
      
      countStyleVar = 0
      countStyleColor = 0
      
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, frameRounding) countStyleVar=countStyleVar+1
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, sizeX, sizeY) countStyleVar=countStyleVar+1
      
      if buttons.states[o] == true then --push buttons color depending on state
        ImGui.PushStyleColor(ctx, ImGui.Col_Button,        HSV(buttons.colors_h[o] / 7.0, colors_sat    , colors_vol    , colors_alp))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, HSV(buttons.colors_h[o] / 7.0, colors_sat*0.7, colors_vol*0.7, colors_alp))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,  HSV(buttons.colors_h[o] / 7.0, colors_sat*0.8, colors_vol*0.8, colors_alp))
      else
        ImGui.PushStyleColor(ctx, ImGui.Col_Button,        HSV(colors_OFF_hue / 7.0, colors_OFF_sat*0.7, colors_OFF_vol*0.7, colors_OFF_alp))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, HSV(colors_OFF_hue / 7.0, colors_OFF_sat*0.8, colors_OFF_vol*0.8, 1))
        ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,  HSV(colors_OFF_hue / 7.0, colors_OFF_sat    , colors_OFF_vol    , 1))
      end countStyleColor = countStyleColor + 3
      
      ImGui.PushStyleColor(ctx, ImGui.Col_Text,HSV(colors_TXT_hue / 7, colors_TXT_sat, colors_TXT_vol, colors_TXT_alp)) countStyleColor = countStyleColor + 1
      
      if useCastomFont == true then ImGui.PushFont(ctx, font) end
      
    elseif pushPop == 0 then
    
      ImGui.PopStyleVar(ctx, countStyleVar)
      ImGui.PopStyleColor( ctx, countStyleColor)
      if useCastomFont == true then ImGui.PopFont(ctx) end
      
    end
    
end

function Switcher_Action(rms)

  if rms==1 then    --rec arm
    
    if recArmed == true then
      ButtonON_Action(ButtonON_Action_ID,rms)
    else
      ButtonOFF_Action(ButtonOFF_Action_ID,rms)
    end
  
  elseif rms==2 then--mute
    
    if muted == true then
      ButtonON_Action(ButtonON_Action_ID,rms)
    else
      ButtonOFF_Action(ButtonOFF_Action_ID,rms)
    end
    
  elseif rms==3 then--solo
    
    if soloed == true then
      ButtonON_Action(ButtonON_Action_ID,rms)
    else
      ButtonOFF_Action(ButtonOFF_Action_ID,rms)
    end
    
  end
end

function Switcher_ToolTip(rms)
  
  if rms==1 then    --rec arm
    
    if recArmed == true then ToolTip(ButtonON_Action_text[ButtonON_Action_ID+8])
    else ToolTip(ButtonOFF_Action_text[ButtonOFF_Action_ID+8]) end
    
  elseif rms==2 then--mute
    
    --tooltip for mute button----------------------------
    if muted == true then ToolTip(ButtonON_Action_text[ButtonON_Action_ID+4])
    else ToolTip(ButtonOFF_Action_text[ButtonOFF_Action_ID+4]) end
    
  elseif rms==3 then--solo
    
    --tooltip for solo button----------------------------
    if soloed == true then ToolTip(ButtonON_Action_text[ButtonON_Action_ID]) 
    else ToolTip(ButtonOFF_Action_text[ButtonOFF_Action_ID]) end
  
  end
end

function Switcher_ContextMenu(rms)
  if ImGui.BeginPopupContextItem(ctx) then
  
    if rms==1 then    --rec arm
    
        for i=1, 2 do
          if ImGui.MenuItem(ctx, ButtonON_Action_text[i+8]) then
            ButtonON_Action(i,rms)
            ImGui.CloseCurrentPopup(ctx)
          end
        end
        
        for i=1, 4 do
          if ImGui.MenuItem(ctx, ButtonOFF_Action_text[i+8]) then
            ButtonOFF_Action(i,rms)
            ImGui.CloseCurrentPopup(ctx)
          end
        end
        
        
    elseif rms==2 then--mute
    
      for i=1, 2 do
        if ImGui.MenuItem(ctx, ButtonON_Action_text[i+4]) then
          ButtonON_Action(i,rms)
          ImGui.CloseCurrentPopup(ctx)
        end
      end
      
      for i=1, 4 do
        if ImGui.MenuItem(ctx, ButtonOFF_Action_text[i+4]) then
          ButtonOFF_Action(i,rms)
          ImGui.CloseCurrentPopup(ctx)
        end
      end
      
    elseif rms==3 then--solo
    
      for i=1, 2 do
        if ImGui.MenuItem(ctx, ButtonON_Action_text[i]) then
          ButtonON_Action(i,rms)
          ImGui.CloseCurrentPopup(ctx)
        end
      end
      
      for i=1, 4 do
        if ImGui.MenuItem(ctx, ButtonOFF_Action_text[i]) then
          ButtonOFF_Action(i,rms)
          ImGui.CloseCurrentPopup(ctx)
        end
      end
      
  end
    
  ImGui.SeparatorText(ctx,'settings')
  rv,showSettings = ImGui.Checkbox(ctx, 'show settings', showSettings)
  if ImGui.IsItemEdited( ctx ) then ImGui.CloseCurrentPopup(ctx) end
  ImGui.EndPopup(ctx)
  end
end

function myButtons(o)
  
  --BUTTONS--
  StyleSet(1,o)
  if ImGui.Button(ctx, buttons.names[o]) then
    Switcher_Action(o)
  end
  StyleSet(0,o)
  
  --OTHER--
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 4, 4)--reset spacing for tooltips and menus
  --tooltips--
  if showToolTips then Switcher_ToolTip(o) end
  --context menu--
  Switcher_ContextMenu(o)
  ImGui.PopStyleVar(ctx,1)--reset spacing end
end

function ResaveStatesOnProjChange()
  --if project changed update states--
    local current_project = reaper.EnumProjects(-1) -- or 0..inf for a specific tab
    if current_project ~= previous_project then
      -- project was replaced (new or open) or user switched to another tab
      StatesRecArmSave()
      StatesMuteSave()
      StatesSoloSave()
      previous_project = current_project
    end
end

local function myWindow_Settings()

  --ORDER TEXT INPUT--
  ImGui.SeparatorText(ctx, 'buttons visibility and order')
  if not ImGui.ValidatePtr(filterLetters, 'ImGui_Function*') then
    -- Only allow 'r' or 'm' or 's' letters, filter out anything else
    filterLetters = ImGui.CreateFunctionFromEEL([[
    eat = 1; i = strlen(#allowed);
    while(
      i -= 1;
      str_getchar(#allowed, i) == EventChar ? eat = 0;
      eat && i;
    );
    eat ? EventChar = 0;
    ]])
    ImGui.Function_SetValue_String(filterLetters, '#allowed', 'rms')
  end
  rv,orderString = ImGui.InputText(ctx, 'show', orderString, ImGui.InputTextFlags_CallbackCharFilter, filterLetters)
  if ImGui.IsItemEdited( ctx ) then buttons.order = ConvertOrderString(orderString) end
  ToolTip("Set order and visibility of buttons. Default is 'rms' > rec-arm, mute, solo. For example type in 'ms' to hide rec-arm button or sm to swap mute and solo buttons")
  
  --BUTTONS NAMES--
  for i=1, #buttons.order do
    o = buttons.order[i]
    rv,buttons.names[o] = ImGui.InputText(ctx, buttons.namesFull[o], buttons.names[o])
    
    if buttons.names[o]=='' or buttons.names[o]== nil then
    local revetrName
      if o==1 then revetrName='R' elseif o==2 then revetrName='M' elseif o==3 then revetrName='S' end
    buttons.names[o]=revetrName
    end
    
  end
  
  --VISUAL SETTINGS--
  ImGui.SeparatorText(ctx, 'visual')
  
  --roud corners--
  rv,frameRounding = ImGui.SliderDouble(ctx, 'rounding', frameRounding, 0.0, 30.0, '%.0f')
  --size--
  rv,sizeX = ImGui.SliderDouble(ctx, 'size x', sizeX, 0.0, 30.0, '%.0f')
  rv,sizeY = ImGui.SliderDouble(ctx, 'size y', sizeY, 0.0, 30.0, '%.0f')
  --spacing--
  rv,spacingX = ImGui.SliderDouble(ctx, 'spacing', spacingX, 0.0, 12.0, '%.0f')
  
  rv,showToolTips = ImGui.Checkbox(ctx, 'tooltips', showToolTips)
  ImGui.SameLine(ctx)
  rv,showBackgroung = ImGui.Checkbox(ctx, 'background', showBackgroung)
  ImGui.SameLine(ctx)
  rv,showOnTop = ImGui.Checkbox(ctx, 'on top', showOnTop)
  
  rv,verticalLayout = ImGui.Checkbox(ctx, 'vertical', verticalLayout)
  
  rv,ignoreMonOnlyR = ImGui.Checkbox(ctx, 'ignore monitoring only tracks', ignoreMonOnlyR)
  ToolTip('ignore tracks with record mode set to "Record: disable (input monitoring only)" ')
  
  --COLOR SLIDERS--
  ImGui.SeparatorText(ctx, 'colors')
  --buttons color--
  if ImGui.CollapsingHeader(ctx, 'buttons color') then
    --buttons ON color--
    ImGui.SeparatorText(ctx, 'buttons-ON color')
    
    for i=1, #buttons.order do
      o = buttons.order[i]
      ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab,       HSV(buttons.colors_h[o] / 7.0, colors_sat, colors_vol, colors_apl))
      ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive, HSV(buttons.colors_h[o] / 7.0, colors_sat, colors_vol, colors_apl))
      
        rv,buttons.colors_h[o] = ImGui.SliderDouble(ctx,'hue '..buttons.namesFull[o], buttons.colors_h[o], 0.0, 7.0, '%.2f')
      
      ImGui.PopStyleColor(ctx, 2)
    end
    
    rv,colors_sat = ImGui.SliderDouble(ctx, 'saturation', colors_sat, 0.0, 1.0, '%.2f')
    rv,colors_vol = ImGui.SliderDouble(ctx, 'volume',     colors_vol, 0.0, 1.0, '%.2f')
    rv,colors_alp = ImGui.SliderDouble(ctx, 'alpha',     colors_alp, 0.0, 1.0, '%.2f')
    
    --buttons OFF color--
    ImGui.SeparatorText(ctx, 'buttons-OFF color')
    
    ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab,       HSV(colors_OFF_hue / 7, colors_OFF_sat, colors_OFF_vol, colors_OFF_alp))
    ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive, HSV(colors_OFF_hue / 7, colors_OFF_sat, colors_OFF_vol, colors_OFF_alp))
      rv, colors_OFF_hue = ImGui.SliderDouble(ctx, "OFF hue", colors_OFF_hue, 0.0, 7.0, '%.2f')
    ImGui.PopStyleColor(ctx, 2)
    
    rv,colors_OFF_sat = ImGui.SliderDouble(ctx, 'OFF sat', colors_OFF_sat, 0.0, 1.0, '%.2f')
    rv,colors_OFF_vol = ImGui.SliderDouble(ctx, 'OFF vol', colors_OFF_vol, 0.0, 1.0, '%.2f')
    rv,colors_OFF_alp = ImGui.SliderDouble(ctx, 'OFF alp', colors_OFF_alp, 0.0, 1.0, '%.2f')
    
  end
  
  --text color--
  
  if ImGui.CollapsingHeader(ctx, 'text color') then
    rv,colors_TXT_hue = ImGui.SliderDouble(ctx, "txt hue", colors_TXT_hue, 0.0, 7.0, '%.2f')
    rv,colors_TXT_sat = ImGui.SliderDouble(ctx, 'txt sat', colors_TXT_sat, 0.0, 1.0, '%.2f')
    rv,colors_TXT_vol = ImGui.SliderDouble(ctx, 'txt vol', colors_TXT_vol, 0.0, 1.0, '%.2f')
    rv,colors_TXT_alp = ImGui.SliderDouble(ctx, 'txt alp', colors_TXT_alp, 0.0, 1.0, '%.2f')
    
  end
  
  --CUSTOM FONT--
  ImGui.SeparatorText(ctx, 'custom font')
  rv, useCastomFont = ImGui.Checkbox(ctx, 'use custom font', useCastomFont)
  rv, cstFnt = ImGui.InputText(ctx, 'custom font', cstFnt)
  ToolTip('font change is applied on script restart')
  rv, cstFntSize = ImGui.InputText(ctx, 'size', cstFntSize)
  ToolTip('font change is applied on script restart')
  
  --BOTTOM BUTTONS--
  ImGui.SeparatorText(ctx, 'save/close')
  --save and close button--
  if ImGui.Button(ctx, 'save and close') then
    showSettings=false
  end
  
  if ImGui.BeginPopupContextItem(ctx) then
    if ImGui.MenuItem(ctx, "show settings file") then
      reaper.CF_LocateInExplorer( dir..SettingsFILENAME )
      ImGui.CloseCurrentPopup(ctx)
    end
    ImGui.EndPopup(ctx)
  end
  
  --cancel button--
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'cancel') then
    SettingsLOAD()
    buttons.order = ConvertOrderString(orderString)
  end
  
  if ImGui.BeginPopupContextItem(ctx) then
    if ImGui.MenuItem(ctx, "load defaults") then
      r = true
      SettingsLOAD(true)
      ImGui.CloseCurrentPopup(ctx)
    end
    ImGui.EndPopup(ctx)
  end
  
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'close script',-10) then
    SettingsWRITEFILE()
    shouldClose=true
  end
  
  --WRITE SETTINGS AT CLOSE--
  if showSettings==false then
    SettingsWRITEFILE()
  end
  
end

local function myWindow_Indicator()
  
  --INIT--
  local rv
  ResaveStatesOnProjChange()
  StatesCheck()
  buttons.states = {recArmed,muted,soloed}
  
  --BUTTONS--
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, spacingX, spacingX)
  for i=1, #buttons.order do
    o = buttons.order[i]
    myButtons(o)
    if not verticalLayout and i~=#buttons.order then ImGui.SameLine(ctx) end
  end
  ImGui.PopStyleVar(ctx, 1)
  
end

local function loop()
  
  --WINDOW FLAGS--
  local window_flags = ImGui.WindowFlags_None
  
  --user config flags--
  if showBackgroung==false then window_flags = window_flags | ImGui.WindowFlags_NoBackground end
  if showOnTop then window_flags = window_flags | ImGui.WindowFlags_TopMost end
  
  --default flags--
  window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
  window_flags = window_flags | ImGui.WindowFlags_AlwaysAutoResize
  window_flags = window_flags |ImGui.WindowFlags_NoDecoration
  
  --SHOW WINDOW--
  
  --indicator--
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding, frameRounding)--set window (not frame) rounding
  local visible, open = ImGui.Begin(ctx, 'Solo/mute/rec-arm indicator', true, window_flags)
  if visible then
    myWindow_Indicator()
    ImGui.End(ctx)
  end
  ImGui.PopStyleVar(ctx, 1)--set window (not frame) rounding end
  
  --settings--
  if showSettings then
    visible, showSettings = ImGui.Begin(ctx, 'settings', true, ImGui.WindowFlags_TopMost)
    if visible then
      myWindow_Settings()
      ImGui.End(ctx)
    end
  end
  
  --LOOP--
  if open and not shouldClose then
    reaper.defer(loop)
  else
    OnClose()
  end
  
end

reaper.defer(loop)

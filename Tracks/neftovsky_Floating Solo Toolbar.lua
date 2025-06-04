-- @description Floating Solo Toolbar
-- @author Neftovsky
-- @version 1.2
-- @about
--   Floating Solo Toolbar – Advanced Track Control Panel
--
--     This script creates a floating toolbar with customizable buttons to control SOLO and MUTE states of tracks.
--     It includes support for partial name matching, visual customization, and exclusive soloing.
--
--        FEATURES:
--
--   •   Button-to-track mapping:
--       Each button can be assigned to one or multiple tracks (comma-separated).
--
--   •   Solo Toggle:
--       Left-click toggles SOLO on assigned tracks.
--
--   •   Alt + Left-Click → Exclusive Solo:
--       Solos only the clicked button’s tracks and unsolos all others.
--
--   •   Ctrl + Left-Click → Toggle MUTE:
--       Mutes or unmutes assigned tracks (optional; can be disabled in settings).
--
--   •   Partial Name Matching (optional):
--       If enabled in Settings, tracks will match even if only part of the name is typed (e.g., "kick" matches "kick2").
--
--   •   Button-to-track mapping:
--       Each button can be assigned to one or multiple tracks (comma-separated, e.g. "kick, bass").
--       __________________________________________
--    
--       Floating Solo Toolbar – Расширенная панель управления треками
--    
--         Этот скрипт создаёт плавающую панель с настраиваемыми кнопками для управления режимами SOLO и MUTE треков.
--         Поддерживает частичное совпадение имён, настройку внешнего вида и эксклюзивное солирование.
--    
--           ФУНКЦИИ:
--    
--       •   Привязка кнопок к трекам:
--           Каждой кнопке можно назначить один или несколько треков (через запятую, например: "kick, bass").
--    
--       •   Переключение SOLO:
--           Левый клик включает/отключает SOLO у назначенных треков.
--    
--       •   Alt + ЛКМ → Эксклюзивный SOLO:
--           Солирует только треки этой кнопки, убирая SOLO со всех остальных.
--    
--       •   Ctrl + ЛКМ → Переключение MUTE:
--           Включает или выключает MUTE у назначенных треков (можно отключить в настройках).
--    
--       •   Частичное совпадение имён (опционально):
--           При включении в настройках, можно указывать часть имени трека (например, "kick" найдёт "kick2").
--    
--       •   Добавление/удаление кнопок:
--           Управляй кнопками прямо из интерфейса.


if not reaper.ImGui_GetBuiltinPath then return reaper.MB("ReaImGui required", "Error", 0) end
package.path = reaper.ImGui_GetBuiltinPath() .. "/?.lua"
local ImGui = require("imgui")("0.9.3.2")

local ctx
local function EnsureImGuiContext()
  if not ctx or not reaper.ImGui_ValidatePtr(ctx, "ImGui_Context*") then
    ctx = reaper.ImGui_CreateContext("Floating Solo Toolbar")
  end
end

local function encBase64(data)
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  return ((data:gsub('.', function(x)
    local r,b='',x:byte()
    for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
    return r;
  end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if #x < 6 then return '' end
    local c=0
    for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
    return b:sub(c+1,c+1)
  end)..({ '', '==', '=' })[#data%3+1])
end

local function decBase64(data)
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  data = string.gsub(data, '[^'..b..'=]', '')
  return (data:gsub('.', function(x)
    if x == '=' then return '' end
    local r,f='',(b:find(x)-1)
    for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
    return r;
  end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if #x ~= 8 then return '' end
    local c=0
    for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
    return string.char(c)
  end))
end

local function TableToString(tbl)
  local function serialize(o)
    if type(o) == "number" then return tostring(o)
    elseif type(o) == "string" then return string.format("%q", o)
    elseif type(o) == "boolean" then return tostring(o)
    elseif type(o) == "table" then
      local s = "{"
      for k, v in pairs(o) do
        s = s .. "[" .. serialize(k) .. "]=" .. serialize(v) .. ","
      end
      return s .. "}"
    end
    return "nil"
  end
  return serialize(tbl)
end

local function StringToTable(str)
  local f = load("return " .. str)
  local ok, res = pcall(f)
  if ok and type(res) == "table" then return res end
  return nil
end

local settings_key = "FloatingSoloToolbar"
local buttons = {
  ["VOC"] = {track_name = "Vocal Bus", button_label = "VOC", partialNameMatch = true},
}
local button_order = {"VOC"}

local visual = {
  lockPosition = false,
  frameRounding = 4.0,
  sizeX = 2.0,
  sizeY = 1.0,
  spacingX = 4.0,
  alpha_solo = 1.0,
  alpha_mute = 1.0,
  alpha_idle = 0.5,
  text_brightness = 0.9, 
  showBackground = true,
  verticalLayout = false,
  showOnTop = false,
  enableCtrlMute = true,
  solo_hue = 0.08, 
  mute_hue = 0.0, 
}

local function SaveSettings()
  local all = {buttons = buttons, order = button_order, visual = visual}
  reaper.SetExtState(settings_key, "Settings", encBase64(TableToString(all)), true)
end

local function LoadSettings()
  local str = reaper.GetExtState(settings_key, "Settings")
  if str and str ~= "" then
    local decoded = decBase64(str)
    local tbl = StringToTable(decoded)
    if tbl and tbl.buttons and tbl.order then
      buttons = tbl.buttons
      button_order = tbl.order
      if tbl.visual then
        for k, v in pairs(tbl.visual) do
          if type(v) == "number" or type(v) == "boolean" then
            visual[k] = v
          end
        end
      end
    end
  end
end

LoadSettings()

local function SplitTrackNames(str)
  local list = {}
  for name in string.gmatch(str, "[^,%s][^,]*[^,%s]*") do
    table.insert(list, name)
  end
  return list
end

local function HSV(h, s, v, a)
  local r, g, b = reaper.ImGui_ColorConvertHSVtoRGB(h, s, v)
  return reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, a or 1.0)
end

local function GetTracks(track_names, partialMatch)
  local found = {}
  for i = 0, reaper.CountTracks(0)-1 do
    local tr = reaper.GetTrack(0, i)
    local _, name = reaper.GetTrackName(tr)
    for _, t in ipairs(track_names) do
      if (partialMatch and name:lower():find(t:lower(), 1, true))
      or (not partialMatch and name:lower() == t:lower()) then
        table.insert(found, tr)
        break
      end
    end
  end
  return found
end


local function CheckSoloAny(track_names, partialMatch)
  for _, tr in ipairs(GetTracks(track_names, partialMatch)) do
    if reaper.GetMediaTrackInfo_Value(tr, "I_SOLO") > 0 then return true end
  end
  return false
end

local function CheckMuteAny(track_names, partialMatch)
  for _, tr in ipairs(GetTracks(track_names, partialMatch)) do
    if reaper.GetMediaTrackInfo_Value(tr, "B_MUTE") > 0 then return true end
  end
  return false
end

local function SetSolo(track_names, state, partialMatch)
  for _, tr in ipairs(GetTracks(track_names, partialMatch)) do
    reaper.SetMediaTrackInfo_Value(tr, "I_SOLO", state and 2 or 0)
  end
end

local function SetMute(track_names, state, partialMatch)
  for _, tr in ipairs(GetTracks(track_names, partialMatch)) do
    reaper.SetMediaTrackInfo_Value(tr, "B_MUTE", state and 1 or 0)
  end
end

local function ToggleSolo(track_names, partialMatch)
  local is_solo = CheckSoloAny(track_names, partialMatch)
  SetSolo(track_names, not is_solo, partialMatch)
end

local function ToggleMute(track_names, partialMatch)
  local is_mute = CheckMuteAny(track_names, partialMatch)
  SetMute(track_names, not is_mute, partialMatch)
end

local function SoloExclusive(target_key)
  local button = buttons[target_key]
  local solo_to_enable = GetTracks(SplitTrackNames(button.track_name), button.partialNameMatch)
  local all_to_disable = {}

  for _, key in ipairs(button_order) do
    if key ~= target_key then
      local tr_list = GetTracks(SplitTrackNames(buttons[key].track_name), buttons[key].partialNameMatch)
      for _, tr in ipairs(tr_list) do
        all_to_disable[tr] = true
      end
    end
  end

  for _, tr in ipairs(solo_to_enable) do
    all_to_disable[tr] = nil
  end

  for tr in pairs(all_to_disable) do
    reaper.SetMediaTrackInfo_Value(tr, "I_SOLO", 0)
  end
  for _, tr in ipairs(solo_to_enable) do
    reaper.SetMediaTrackInfo_Value(tr, "I_SOLO", 2)
  end
end

local selected_button_key = nil
local button_name_buffer = ""
local track_name_buffer = ""
local show_visual_menu = false

local function RenderVisualSettings()
  local function slider(label, key, step, min, max)
    reaper.ImGui_Text(ctx, label)
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, "-"..key) then visual[key] = math.max(min, visual[key] - step) end
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_Text(ctx, string.format("%.2f", visual[key]))
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, "+"..key) then visual[key] = math.min(max, visual[key] + step) end
  end

  _, visual.sizeX = reaper.ImGui_SliderDouble(ctx, "Width", visual.sizeX, 0.5, 5.0)
  _, visual.sizeY = reaper.ImGui_SliderDouble(ctx, "Height", visual.sizeY, 0.5, 5.0)
  _, visual.spacingX = reaper.ImGui_SliderDouble(ctx, "Spacing", visual.spacingX, 0.0, 30.0)
  _, visual.frameRounding = reaper.ImGui_SliderDouble(ctx, "Frame Rounding", visual.frameRounding, 0.0, 20.0)
  _, visual.text_brightness = reaper.ImGui_SliderDouble(ctx, "Text Brightness", visual.text_brightness, 0.1, 1.0)
  _, visual.alpha_solo = reaper.ImGui_SliderDouble(ctx, "Alpha (Solo)", visual.alpha_solo, 0.0, 1.0)
  _, visual.alpha_idle = reaper.ImGui_SliderDouble(ctx, "Alpha (Idle)", visual.alpha_idle, 0.0, 1.0)
  _, visual.alpha_mute = reaper.ImGui_SliderDouble(ctx, "Alpha (Mute)", visual.alpha_mute, 0.0, 1.0)
  _, visual.solo_hue = reaper.ImGui_SliderDouble(ctx, "SOLO Hue (0.08)", visual.solo_hue, 0.0, 1.0)
  _, visual.mute_hue = reaper.ImGui_SliderDouble(ctx, "MUTE Hue(0.0)", visual.mute_hue, 0.0, 1.0)

  _, visual.showBackground = reaper.ImGui_Checkbox(ctx, "Show Background", visual.showBackground)
  _, visual.verticalLayout = reaper.ImGui_Checkbox(ctx, "Vertical Layout", visual.verticalLayout)
  _, visual.showOnTop = reaper.ImGui_Checkbox(ctx, "Always on Top", visual.showOnTop)
  _, visual.enableCtrlMute = reaper.ImGui_Checkbox(ctx, "Enable Mute (Ctrl+Click)", visual.enableCtrlMute)
  _, visual.lockPosition = reaper.ImGui_Checkbox(ctx, "Lock Position", visual.lockPosition)
end


local function Main()
  EnsureImGuiContext()

  local flags = reaper.ImGui_WindowFlags_NoTitleBar() | reaper.ImGui_WindowFlags_NoCollapse() | reaper.ImGui_WindowFlags_AlwaysAutoResize()
  if not visual.showBackground then flags = flags | reaper.ImGui_WindowFlags_NoBackground() end
  if visual.showOnTop then flags = flags | reaper.ImGui_WindowFlags_TopMost() end

  if not visual.lockPosition then
    reaper.ImGui_SetNextWindowPos(ctx, 100, 100, reaper.ImGui_Cond_FirstUseEver())
  end

  local flags = reaper.ImGui_WindowFlags_NoTitleBar()
              | reaper.ImGui_WindowFlags_NoCollapse()
              | reaper.ImGui_WindowFlags_AlwaysAutoResize()

  if not visual.showBackground then
    flags = flags | reaper.ImGui_WindowFlags_NoBackground()
  end
  if visual.showOnTop then
    flags = flags | reaper.ImGui_WindowFlags_TopMost()
  end
  if visual.lockPosition then
    flags = flags | reaper.ImGui_WindowFlags_NoMove()
  end

  local visible, open = reaper.ImGui_Begin(ctx, "Floating Solo Toolbar", true, flags)

  if visible then
    for _, key in ipairs(button_order) do
      local b = buttons[key]
      local names = SplitTrackNames(b.track_name)
      local is_solo = CheckSoloAny(names, b.partialNameMatch)
      local is_mute = CheckMuteAny(names, b.partialNameMatch)

      local color = is_solo and HSV(visual.solo_hue, 1.0, 0.8, visual.alpha_solo)
                 or is_mute and HSV(visual.mute_hue, 1.0, 0.8, visual.alpha_mute)
                  or reaper.ImGui_ColorConvertDouble4ToU32(0.4, 0.4, 0.4, visual.alpha_idle)
      
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), color)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(),
        reaper.ImGui_ColorConvertDouble4ToU32(
          visual.text_brightness, visual.text_brightness, visual.text_brightness, 1.0))
      reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), visual.frameRounding)
      reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 8 * visual.sizeX, 8 * visual.sizeY)

      if reaper.ImGui_Button(ctx, b.button_label .. "##" .. key) then
        local alt = reaper.ImGui_GetKeyMods(ctx) & reaper.ImGui_Mod_Alt() ~= 0
        local ctrl = reaper.ImGui_GetKeyMods(ctx) & reaper.ImGui_Mod_Ctrl() ~= 0

        if ctrl and visual.enableCtrlMute then ToggleMute(names, b.partialNameMatch)
        elseif alt then SoloExclusive(key)
        else ToggleSolo(names, b.partialNameMatch) end
      end

      if reaper.ImGui_IsItemClicked(ctx, 1) then
        selected_button_key = key
        button_name_buffer = b.button_label
        track_name_buffer = b.track_name
        show_visual_menu = false
        reaper.ImGui_OpenPopup(ctx, "Edit")
      end

      reaper.ImGui_PopStyleVar(ctx, 2)
      reaper.ImGui_PopStyleColor(ctx, 2)

      if not visual.verticalLayout then
        reaper.ImGui_SameLine(ctx, nil, visual.spacingX)
      end
    end

 if reaper.ImGui_BeginPopup(ctx, "Edit") then
     _, button_name_buffer = reaper.ImGui_InputText(ctx, "Label", button_name_buffer, 256)
     _, track_name_buffer = reaper.ImGui_InputText(ctx, "Track", track_name_buffer, 256)
 
     -- Кнопки OK и Cancel с галочкой в одной строке
     if reaper.ImGui_Button(ctx, "OK") then
         if selected_button_key and buttons[selected_button_key] then
             buttons[selected_button_key].button_label = button_name_buffer
             buttons[selected_button_key].track_name = track_name_buffer
             SaveSettings()
         end
         reaper.ImGui_CloseCurrentPopup(ctx)
     end
     reaper.ImGui_SameLine(ctx)
     if reaper.ImGui_Button(ctx, "Cancel") then reaper.ImGui_CloseCurrentPopup(ctx) end
     reaper.ImGui_SameLine(ctx)
     if selected_button_key and buttons[selected_button_key] then
         _, buttons[selected_button_key].partialNameMatch = reaper.ImGui_Checkbox(ctx, "Contains in name", buttons[selected_button_key].partialNameMatch)
     end
 
     reaper.ImGui_Separator(ctx)
     if reaper.ImGui_Button(ctx, "+") then
         local new_key = "Button" .. tostring(#button_order + 1)
         buttons[new_key] = {track_name = "New Track", button_label = "New", partialNameMatch = true}
         table.insert(button_order, new_key)
         SaveSettings()
     end
     reaper.ImGui_SameLine(ctx)
     if reaper.ImGui_Button(ctx, "-") then
         local last = table.remove(button_order)
         if last then buttons[last] = nil end
         SaveSettings()
     end
 
     reaper.ImGui_Separator(ctx)
     if reaper.ImGui_Button(ctx, "Settings") then show_visual_menu = not show_visual_menu end
     if show_visual_menu then
         reaper.ImGui_Separator(ctx)
         RenderVisualSettings()
     end
 
     reaper.ImGui_EndPopup(ctx)
 end

    reaper.ImGui_End(ctx)
  end

  if open then reaper.defer(Main) end
end

Main()

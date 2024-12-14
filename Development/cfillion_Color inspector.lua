-- @description Color inspector
-- @author cfillion
-- @version 1.0
-- @screenshot https://i.imgur.com/GVoBSUs.gif
-- @donation https://reapack.com/donate

local script_name = 'Color inspector'
if not reaper.ImGui_GetBuiltinPath then
  return reaper.MB('ReaImGui is not installed or too old.', script_name, 0)
end

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9.3'
local font = ImGui.CreateFont('sans-serif', 13)
local ctx = ImGui.CreateContext(script_name)
ImGui.Attach(ctx, font)
ImGui.SetColorEditOptions(ctx, ImGui.ColorEditFlags_AlphaBar)

local unsigned_filter = ImGui.CreateFunctionFromEEL(
  "EventChar < '0' || EventChar > '9' ? EventChar = 0;")
ImGui.Attach(ctx, unsigned_filter)

local format, color, color_ref = 0, 0

local function swaprb()
  color = (color >> 16 & 0x000000ff) |
          (color       & 0xff00ff00) |
          (color << 16 & 0x00ff0000)
end

local function flagCheckbox(label, flag)
  if format == 2 then
    ImGui.Checkbox(ctx, label, false)
  else
    color = select(2, ImGui.CheckboxFlags(ctx, label, color, flag << 24))
  end
end

local function selector()
  local rv, value
  ImGui.AlignTextToFramePadding(ctx)
  ImGui.Text(ctx, 'Color format:')
  ImGui.SameLine(ctx)
  local prev_format = format
  rv, format = ImGui.RadioButtonEx(ctx, 'RGB', format, 0)
  if rv and prev_format == 1 then swaprb() end
  ImGui.SameLine(ctx)
  rv, format = ImGui.RadioButtonEx(ctx, 'BGR', format, 1)
  if rv and prev_format ~= 1 then swaprb() end
  ImGui.SameLine(ctx)
  rv, format = ImGui.RadioButtonEx(ctx, 'RGBA', format, 2)
  if rv and prev_format == 1 then swaprb() end

  ImGui.SameLine(ctx, nil, 16)
  ImGui.BeginDisabled(ctx, format == 2)
  if ImGui.Button(ctx, 'Swap R/B') then swaprb() end
  ImGui.EndDisabled(ctx)
  ImGui.Spacing(ctx)

  local btn_size = ImGui.GetFrameHeightWithSpacing(ctx) * 6
  local btn_flags = ImGui.ColorEditFlags_AlphaPreview
  if format ~= 2 then btn_flags = btn_flags | ImGui.ColorEditFlags_NoAlpha end
  if ImGui.ColorButton(ctx, 'Color', color, btn_flags, btn_size, btn_size) then
    color_ref = color
  end
  if ImGui.BeginPopupContextItem(ctx, nil, ImGui.PopupFlags_MouseButtonLeft) then
    local color_picker = format == 2 and ImGui.ColorPicker4 or ImGui.ColorPicker3
    color = select(2, ImGui.ColorPicker4(ctx, 'Color', color,
      btn_flags | ImGui.ColorEditFlags_NoInputs, color_ref))
    ImGui.EndPopup(ctx)
  end

  ImGui.SameLine(ctx)
  ImGui.BeginGroup(ctx)
  local color_flags = ImGui.ColorEditFlags_NoSmallPreview
  local color_edit = format == 2 and ImGui.ColorEdit4 or ImGui.ColorEdit3
  color = select(2, color_edit(ctx, 'RGB', color, color_flags | ImGui.ColorEditFlags_DisplayRGB))
  color = select(2, color_edit(ctx, 'HSV', color, color_flags | ImGui.ColorEditFlags_DisplayHSV))

  if format == 1 then swaprb() end
  color = select(2, ImGui.InputInt(ctx, 'Signed', color, 0, 0, ImGui.InputTextFlags_CharsDecimal))
  local uint = color & 0xFFFFFFFF
  rv, uint = ImGui.InputText(ctx, 'Unsigned', uint,
    ImGui.InputTextFlags_AutoSelectAll | ImGui.InputTextFlags_CallbackCharFilter, unsigned_filter)
  if rv and uint:len() > 0 then color = math.min(0xFFFFFFFF, tonumber(uint) or 0) end
  color = select(2, ImGui.InputInt(ctx, 'Hexadecimal', color, 0, 0, ImGui.InputTextFlags_CharsHexadecimal))
  if format == 1 then swaprb() end

  ImGui.Spacing(ctx)

  ImGui.BeginDisabled(ctx, format == 2)
  ImGui.AlignTextToFramePadding(ctx)
  ImGui.Text(ctx, 'Flags:')
  ImGui.SameLine(ctx)
  flagCheckbox('Enabled', 1)
  ImGui.SetItemTooltip(ctx, 'Used by REAPER')
  ImGui.SameLine(ctx)
  flagCheckbox('SWS portable', 2)
  ImGui.SetItemTooltip(ctx, 'Used by SWS 2.14+ when storing cross-platform colors')
  ImGui.EndDisabled(ctx)

  ImGui.EndGroup(ctx)
end

local function loop()
  ImGui.PushFont(ctx, font)
  local visible, open = ImGui.Begin(ctx, script_name, true, ImGui.WindowFlags_AlwaysAutoResize)
  if visible then
    selector()
    ImGui.End(ctx)
  end
  ImGui.PopFont(ctx)
  if open then
    reaper.defer(loop)
  end
end

reaper.defer(loop)

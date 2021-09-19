-- @description ReaImGui Color Theme Creator
-- @author amagalma
-- @version 1.02
-- @changelog
--   - "Unselect All" button can be used to toggle select all
-- @screenshot https://i.ibb.co/tHDCPrp/Rea-Im-Gui-Color-Theme-Creator.gif
-- @donation https://www.paypal.me/amagalma
-- @about
--   Easily create color themes for ReaImGui development
--
--   - Click on a colored rectangle to set color
--   - Alt-Click text to reset to original color
--   - Click text to select multiple colors
--   - Drag colors to copy from one rectangle to the other
--   - Buttons are self-explanatory
--   - Size of GUI/font can be set inside the script


-- Set preferred size here---
local font_sz = 20
-----------------------------


local btn_h = font_sz*1.75
local ctx = reaper.ImGui_CreateContext('ReaImGui Color Theme Creator', reaper.ImGui_WindowFlags_NoSavedSettings() )
local font = reaper.ImGui_CreateFont( "serif", font_sz )
reaper.ImGui_AttachFont( ctx, font )
local export = { name = "  Export Theme  ", pos = 0 }
reaper.ImGui_PushFont(ctx, font)
local space = reaper.ImGui_CalcTextSize( ctx, "NavWindowingHighlight" ) + 3*font_sz
local window_w = 5*space - (space - reaper.ImGui_CalcTextSize( ctx, "ModalWindowDimBg") - 2*font_sz) + 8
export.pos = window_w - reaper.ImGui_CalcTextSize( ctx, export.name ) - 16
reaper.ImGui_SetNextWindowSize( ctx, window_w, 0 )
local rect_size
local picker_color, previous_picker_color
local palette_button_flags = reaper.ImGui_ColorEditFlags_NoAlpha()  |
                             reaper.ImGui_ColorEditFlags_NoPicker() |
                             reaper.ImGui_ColorEditFlags_NoTooltip()


local palette = {}
for n = 0, 31 do
  local color = reaper.ImGui_ColorConvertHSVtoRGB(n / 31, 0.82, 0.78)
  palette[n+1] = color
end

local colors = {}
local original = {}
local selected = {}
local select_all = false
local stylevar = {}
for i = 1, reaper.ImGui_Col_ModalWindowDimBg()+1 do
  colors[i] = reaper.ImGui_GetColor(ctx, i-1)
  original[i] = colors[i]
  selected[i] = false
  local name = reaper.ImGui_GetStyleColorName(i-1)
  stylevar[i] = { name = name, size = reaper.ImGui_CalcTextSize( ctx, name ) }
end
reaper.ImGui_PopFont( ctx )


local function ImGuiColorNoAlpha( rgba_color ) -- (0-255)
  return reaper.ColorToNative((255 & (rgba_color >> 24)),
         (255 & (rgba_color >> 16)),
         (255 & (rgba_color >> 8)))
end



local function loop()
  for i = 1, 55 do
    reaper.ImGui_PushStyleColor(ctx, i-1, colors[i])
  end
  reaper.ImGui_PushFont(ctx, font)
  local draw_list = reaper.ImGui_GetWindowDrawList( ctx )

  local visible, open = reaper.ImGui_Begin(ctx, 'amagalma ReaImGui Color Theme Creator v1.0###ReaImGui Color Theme Creator', true, reaper.ImGui_WindowFlags_NoResize() | reaper.ImGui_WindowFlags_NoCollapse())
  if visible then
    local rv
    for i = 1, 55 do
      rv, colors[i] = reaper.ImGui_ColorEdit4(ctx, '###' .. stylevar[i].name, colors[i], reaper.ImGui_ColorEditFlags_NoInputs())
      if not rect_size then rect_size = reaper.ImGui_GetItemRectSize( ctx ) end
      reaper.ImGui_SameLine( ctx )
      local x, y = reaper.ImGui_GetCursorScreenPos( ctx )
      reaper.ImGui_Text( ctx, stylevar[i].name )
      if reaper.ImGui_IsItemHovered( ctx ) then
        if reaper.ImGui_IsMouseClicked( ctx, reaper.ImGui_MouseButton_Left() ) then
          if reaper.ImGui_GetKeyMods( ctx ) == reaper.ImGui_KeyModFlags_Alt() then
            colors[i] = original[i]
          else
            selected[i] = not selected[i]
            if selected[i] and not select_all then select_all = true end
          end
        end
      end
      if selected[i] then
        reaper.ImGui_DrawList_AddRect( draw_list, x-3, y, x + stylevar[i].size+3, y + rect_size, colors[1] )
      end
      local m = i % 5
      if m ~= 0 then
        reaper.ImGui_SameLine( ctx, m*space)
      end
    end
    reaper.ImGui_Spacing( ctx ) ; reaper.ImGui_Spacing( ctx )
    reaper.ImGui_Separator( ctx )
    reaper.ImGui_Spacing( ctx ) ; reaper.ImGui_Spacing( ctx )

    if reaper.ImGui_Button( ctx, "  Unselect All  ", nil, btn_h ) then
      select_all = not select_all
      for i = 1, 55 do selected[i] = select_all end
    end

    reaper.ImGui_SameLine( ctx )
    if reaper.ImGui_Button( ctx, "Select Same Color as First Selected", nil, btn_h ) then
      local first
      for i = 1, 55 do
        if selected[i] then first = ImGuiColorNoAlpha( colors[i] ) break end
      end
      if first then
        for i = 1, 55 do
          if ImGuiColorNoAlpha( colors[i] ) == first then selected[i] = true end
        end
      end
    end

    reaper.ImGui_SameLine( ctx )
    if reaper.ImGui_Button( ctx, " Set Color of All Selected ", nil, btn_h ) then
      local first
      for i = 1, 55 do
        if selected[i] then first = colors[i] break end
      end
      if first then
        previous_picker_color = first
        picker_color = first
        reaper.ImGui_OpenPopup( ctx, "Set Color" )
        local x, y = reaper.ImGui_GetWindowPos(ctx)
        reaper.ImGui_SetNextWindowPos( ctx, x + window_w/4, y )
      end
    end

    if reaper.ImGui_BeginPopup( ctx, "Set Color" ) then
      reaper.ImGui_Text( ctx, "RGB Color is applied to all selected items.\nAlpha won't be changed!")
      reaper.ImGui_Separator(ctx)
      rv, picker_color = reaper.ImGui_ColorPicker4(ctx, '##picker', picker_color, reaper.ImGui_ColorEditFlags_NoSidePreview() | reaper.ImGui_ColorEditFlags_NoSmallPreview())
      if rv then
        for i = 1, 55 do
          if selected[i] then
            colors[i] = (reaper.ImGui_ColorConvertNative(ImGuiColorNoAlpha(picker_color)) << 8) | (255 & colors[i])
          end
        end
      end
      reaper.ImGui_SameLine(ctx)

      reaper.ImGui_BeginGroup(ctx) -- Lock X position
      reaper.ImGui_Text(ctx, 'Current')
      reaper.ImGui_ColorButton(ctx, '##current', picker_color, reaper.ImGui_ColorEditFlags_NoPicker(), 70, 40)
      reaper.ImGui_Text(ctx, 'Previous')
      if reaper.ImGui_ColorButton(ctx, '##previous', previous_picker_color,
         reaper.ImGui_ColorEditFlags_NoPicker(), 70, 40)
      then
        picker_color = previous_picker_color
      end
      reaper.ImGui_Separator(ctx)
      reaper.ImGui_Text(ctx, 'Palette')
      for n,c in ipairs(palette) do
        reaper.ImGui_PushID(ctx, n)
        if ((n - 1) % 8) ~= 0 then
          reaper.ImGui_SameLine(ctx, 0.0, ({reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing())})[2])
        end

        if reaper.ImGui_ColorButton(ctx, '##palette', c, palette_button_flags, 20, 20) then
          picker_color = (c << 8) | (picker_color & 0xFF) -- Preserve alpha!
        end

        -- Allow user to drop colors into each palette entry. Note that ColorButton() is already a
        -- drag source by default, unless specifying the ImGuiColorEditFlags_NoDragDrop flag.
        if reaper.ImGui_BeginDragDropTarget(ctx) then
          local drop_color
          rv,drop_color = reaper.ImGui_AcceptDragDropPayloadRGB(ctx)
          if rv then
            palette[n] = drop_color
          end
          rv,drop_color = reaper.ImGui_AcceptDragDropPayloadRGBA(ctx)
          if rv then
            palette[n] = drop_color >> 8
          end
          reaper.ImGui_EndDragDropTarget(ctx)
        end

        reaper.ImGui_PopID(ctx)
      end
      reaper.ImGui_EndGroup(ctx)
      reaper.ImGui_EndPopup(ctx)
    end

    reaper.ImGui_SameLine( ctx )
    if reaper.ImGui_Button( ctx, " Reset Color of All Selected ", nil, btn_h ) then
      for i = 1, 55 do
        if selected[i] then colors[i] = original[i] end
      end
    end

    reaper.ImGui_SameLine( ctx, export.pos )
    if reaper.ImGui_Button( ctx, export.name, nil, btn_h ) then
      local output = string.format("local style_colors = { %s }\nfor i = 1, 55 do\n  reaper.ImGui_PushStyleColor\z
                     (ctx, i-1, style_colors[i])\nend\nreaper.ImGui_PopStyleColor(ctx, 55)", table.concat(colors, ", "))
      reaper.ShowConsoleMsg(output.."\n")
    end

    reaper.ImGui_Spacing( ctx )

    reaper.ImGui_End(ctx)
  end

  reaper.ImGui_PopFont( ctx )
  reaper.ImGui_PopStyleColor(ctx, 55)

  if open then
    reaper.defer(loop)
  else
    reaper.ImGui_DestroyContext(ctx)
  end
end

reaper.defer(loop)

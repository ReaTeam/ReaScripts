-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local ImGui         = require "ext/imgui"
local AppContext    = require "classes/app_context"
local EmojImGui     = require "emojimgui"
local Sticker       = require "classes/sticker"

local PS            = require "modules/project_settings"
local D             = require "modules/defines"

local StickerEditor = {}
StickerEditor.__index = StickerEditor

function StickerEditor:new(sticker, thing, slot)
  local instance = {}
  setmetatable(instance, self)
  instance:_initialize(sticker, thing, slot)
  return instance
end

function StickerEditor:_initialize(sticker, thing, slot)
  self.draw_count  = 0
  self.rand        = math.random()
  self.open        = true
  if not sticker then
    sticker = Sticker:new("1:1::", thing.notes, slot)
    self.new_record       = true
    self.packed_code_was  = nil
  else
    self.new_record       = false
    self.packed_code_was  = sticker:pack()
  end
  self.sticker          = sticker
end

function StickerEditor:setPosition(x,y)
  self.x, self.y = x, y
end

function StickerEditor:setSize(w,h)
  self.w, self.h = w, h
end

function StickerEditor:GrabFocus()
  self.grab_focus = true
end

function StickerEditor:title()
  if self.new_record then
    return "New sticker ..."
  else
    return "Sticker edit"
  end
end

function StickerEditor:stickerSize()
  return PS.RetrieveProjectStickerSize()
end

function StickerEditor:draw(color)
  local app_ctx     = AppContext.instance()
  local ctx         = app_ctx.imgui_ctx

  local x = self.x or 100
  local y = self.y or 100

  ImGui.SetNextWindowPos(ctx,   x, y, ImGui.Cond_Appearing )

  local ret = nil

  -- Don't save the settings
  local b, is_open = ImGui.Begin(ctx, self:title() .. "##edit_sticker_" .. self.rand, true, ImGui.WindowFlags_TopMost | ImGui.WindowFlags_NoSavedSettings | ImGui.WindowFlags_NoDocking | ImGui.WindowFlags_AlwaysAutoResize)
  if b then

    ImGui.PushID(ctx, "sticker_editor_" .. self.rand)

    if ImGui.IsWindowAppearing(ctx) or self.grab_focus then
      ImGui.SetKeyboardFocusHere(ctx)
      ImGui.SetWindowFocus(ctx)
      if self.hwnd then
        reaper.JS_Window_SetFocus(self.hwnd)
        reaper.JS_Window_SetForeground(self.hwnd)
      end
    else
      if not self.hwnd then
        self.hwnd = reaper.JS_Window_Find(self:title(), true)
        if not self.hwnd then
         -- error("CANNOT RETRIEVE HWND FOR STICKER EDITOR")
        end
      end
    end

    if ImGui.IsWindowAppearing(ctx) then
      self.draw_count = 0
    end

    -- Sticker zone

    ImGui.AlignTextToFramePadding(ctx)

    ImGui.BeginGroup(ctx)

    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ChildBorderSize, 1)
    ImGui.PushStyleColor(ctx, ImGui.Col_Border, 0xFFFFFF80)

    if self.sticker.icon then
      ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg, (self.sticker.icon.font_name == 'OpenMoji') and (0x9EB8FFFF) or (0))
    end


---@diagnostic disable-next-line: undefined-field
    if ImGui.BeginChild(ctx, "Smiley prev", 50, 50, ImGui.ChildFlags_Borders, ImGui.WindowFlags_NoScrollbar) then
      if self.sticker and self.sticker.icon then
        local font = EmojImGui.Asset.Font(ctx, self.sticker.icon.font_name)

---@diagnostic disable-next-line: redundant-parameter
        ImGui.PushFont(ctx, font, 28)
        local iw, ih = ImGui.CalcTextSize(ctx, self.sticker.icon.utf8)
        local cw, ch = ImGui.GetContentRegionAvail(ctx)
        ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + (cw - iw) * 0.5)
        ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosY(ctx) + (ch - ih) * 0.5)
        ImGui.Text(ctx, self.sticker.icon.utf8)
        ImGui.PopFont(ctx)
      else
        -- Empty
      end
      ImGui.EndChild(ctx)
      if self.sticker and not self.sticker:hasIcon() then
        local draw_list = ImGui.GetWindowDrawList(ctx)
        local tlx, tly = ImGui.GetItemRectMin(ctx)
        local brx, bry = ImGui.GetItemRectMax(ctx)
        ImGui.DrawList_AddLine(draw_list, tlx, tly, brx, bry, 0xFFFFFF80, 1)
        ImGui.DrawList_AddLine(draw_list, brx, tly, tlx, bry, 0xFFFFFF80, 1)
      end
    end

    if self.sticker.icon then
      ImGui.PopStyleColor(ctx)
    end

    ImGui.PopStyleVar(ctx)
    ImGui.PopStyleColor(ctx)

    if ImGui.IsItemHovered(ctx) then
      ImGui.SetTooltip(ctx, "Click to add/modify icon\n\nRight-Click to remove icon")
    end

    if ImGui.IsItemClicked(ctx) then
      self.icon_picker = EmojImGui.Picker:new()
    end

    if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Right) then
      self.sticker.icon = nil
    end

    ImGui.EndGroup(ctx)

    ImGui.SameLine(ctx)
    ImGui.BeginGroup(ctx)
    local b, t = ImGui.InputText(ctx, "##sticker_text", self.sticker.text )
    if b then
      self.sticker.text = t
    end

    ImGui.Dummy(ctx, 1, 3)
    if self.sticker.icon == nil and self.sticker.text == "" then
      ImGui.Text(ctx, "Sticker is empty")
    else
      ImGui.Text(ctx, "Sticker preview")
      ImGui.SameLine(ctx)
      local metrics = self.sticker:PreRender(ctx, self:stickerSize())
      local xs, ys = ImGui.GetCursorScreenPos(ctx)
      self.sticker:Render(ctx, metrics, xs, ys, color, 0x000000FF)
      ImGui.Dummy(ctx,0,0)
    end
    ImGui.EndGroup(ctx)

    if self.grab_focus then
      self.grab_focus = false
    end

    if self.icon_picker and not self.icon_picker.open then
      self.icon_picker  = nil
      self.grab_focus   = true
    end

    if self.icon_picker then
      local picked = self.icon_picker:draw(ctx)
      if picked then
        self.icon_picker  = nil
        self.grab_focus   = true
        self.sticker.icon = picked
      end
    end

    if ImGui.IsWindowFocused(ctx) and ImGui.IsKeyPressed(ctx, ImGui.Key_Enter, false) then
      is_open   = false
      ret       = self.sticker
    end

    -- Because we're in auto commit, close on shift enter or escape
    if ImGui.IsWindowFocused(ctx) and ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false)  then
      is_open = false
    end

    -- Remember positions
    self.w, self.h = ImGui.GetWindowSize(ctx)
    self.x, self.y = ImGui.GetWindowPos(ctx)

    ImGui.PopID(ctx)
    ImGui.End(ctx)

    self.draw_count = self.draw_count + 1
  end

  self.open = is_open

  return ret
end

return StickerEditor

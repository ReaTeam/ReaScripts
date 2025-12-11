-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local ImGui         = require "ext/imgui"
local AppContext    = require "classes/app_context"
local Sticker       = require "classes/sticker"
local StickerEditor = require "widgets/sticker_editor"
local D             = require "modules/defines"
local PS            = require "modules/project_settings"

local StickerPicker = {}
StickerPicker.__index = StickerPicker

function StickerPicker:new(thing, slot)
  local instance = {}
  setmetatable(instance, self)
  instance:_initialize(thing, slot)
  return instance
end

function StickerPicker:_initialize(thing, slot)
  self.draw_count         = 0
  self.rand               = math.random()
  self.open               = true

  self.thing              = thing
  self.slot               = slot

  self.color              = (D.SlotColor(slot) << 8) | 0xFF

  self:pullLibrary()
end

function StickerPicker:setPosition(x,y)
  self.x, self.y = x, y
end

function StickerPicker:setSize(w,h)
  self.w, self.h = w, h
end

function StickerPicker:GrabFocus()
  self.grab_focus = true
end

function StickerPicker:title()
  return "Sticker Library"
end

function StickerPicker:pullLibrary()
  self.sticker_library = Sticker.Library(self.thing, self.slot)
end

function StickerPicker:commit()
  -- This will also normalize / sort the library
  self.sticker_library = Sticker.StoreLibrary(self.sticker_library)
end

function StickerPicker:stickerSize()
  return PS.RetrieveProjectStickerSize()
end

function StickerPicker:renderStickerZone(ctx, stickers, should_go_to_line)
  local num_on_line     = 0
  local xc, yc          = ImGui.GetCursorScreenPos(ctx)
  local last_vspacing   = nil
  local clicked         = nil
  local sticker_size    = self:stickerSize()

  for _, sticker in ipairs(stickers) do
    local metrics           = sticker:PreRender(ctx, sticker_size)
    local estimated_width   = metrics.width
    local estimated_spacing = metrics.spacing

    xc, yc    = ImGui.GetCursorScreenPos(ctx)

    if num_on_line ~= 0 then
      estimated_width = estimated_spacing + estimated_width
    end

    local rw, _ = ImGui.GetContentRegionAvail(ctx)
    if estimated_width > rw and num_on_line ~= 0 then
      ImGui.NewLine(ctx)
      xc, yc  = ImGui.GetCursorScreenPos(ctx)
      yc      = yc + estimated_spacing
      ImGui.SetCursorScreenPos(ctx, xc, yc)
      num_on_line = 0
    elseif num_on_line ~= 0 then
      -- Add spacing for separation
      xc = xc + estimated_spacing
      ImGui.SetCursorScreenPos(ctx, xc, yc)
    end
    local hov = sticker:Render(ctx, metrics, xc, yc)
    if hov then
      local cl = ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Left)
      local cr = ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Right)
      if cl or (cr and not sticker:isSpecial()) then
        clicked = sticker
      end
      if ImGui.BeginTooltip(ctx) then
        if sticker:isSpecial() then
          if sticker.text == 'checkboxes' then
            ImGui.Text(ctx, "Special sticker that shows the number of checked\nchecbkoxes and the total of checbkoxes in this note")
          end
          if sticker.text == 'progressbar' then
            ImGui.Text(ctx, "Special sticker that shows the proportion of checked\ncheckboxes in this note as a progressbar in %")
          end
          if sticker.text == 'category' then
            ImGui.Text(ctx, "Special sticker that shows the note's category\n(will change if the categories are edited)")
          end
        end
        ImGui.TextColored(ctx, 0xCC96FFFF, "Click"); ImGui.SameLine(ctx,0,5); ImGui.Text(ctx, "to pick")
        if not sticker:isSpecial() then
          ImGui.TextColored(ctx, 0xCC96FFFF, "Right click"); ImGui.SameLine(ctx,0,5); ImGui.Text(ctx, "to edit")
          ImGui.TextColored(ctx, 0xCC96FFFF, "Ctrl+click "); ImGui.SameLine(ctx,0,5); ImGui.Text(ctx, "to remove from library")
        end
        ImGui.EndTooltip(ctx)
      end
    end

    num_on_line = num_on_line + 1
    last_vspacing = estimated_spacing
  end

  if last_vspacing then
    if should_go_to_line then
      local fpx, fpy = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
      ImGui.NewLine(ctx)
      xc, yc  = ImGui.GetCursorScreenPos(ctx)
      yc      = yc + fpy
      ImGui.SetCursorScreenPos(ctx, xc, yc)
      num_on_line = 0
    end
    -- Ensure window extension by calling dummy
    ImGui.Dummy(ctx,0,0)
    if not should_go_to_line then
      ImGui.SameLine(ctx)
    end
  end

  return clicked
end

function StickerPicker:draw()
  local app_ctx     = AppContext.instance()
  local ctx         = app_ctx.imgui_ctx

  ImGui.SetNextWindowSize(ctx, 300, 300, ImGui.Cond_FirstUseEver)

  local x = self.x or 100
  local y = self.y or 100

  ImGui.SetNextWindowPos(ctx,   x, y, ImGui.Cond_Appearing )

  ---ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg, 0x753ffc40)
  -- Don't save the settings
  local b, is_open = ImGui.Begin(ctx, self:title() .. "##sticker_picker", true, ImGui.WindowFlags_TopMost | ImGui.WindowFlags_NoDocking)
  ---ImGui.PopStyleColor(ctx)

  local picked = nil

  if b then
    ImGui.PushID(ctx, "sticker_picker")

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
      end
    end

    if ImGui.IsWindowAppearing(ctx) then
      self.draw_count = 0
    end

    -- Because we're in auto commit, close on shift enter or escape
    if ImGui.IsWindowFocused(ctx) and ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false)  then
      is_open = false
    end

    -- Type 0 : special, 1 : standard (icon+text)
    -- Type:icon:font:icon id:text. If no icon, no font / icon id at all.
    local list = self.sticker_library

    ImGui.SeparatorText(ctx, "Special Stickers")
    picked = picked or self:renderStickerZone(ctx, {
      Sticker:new("0:category",   self.thing.notes, self.slot),
      Sticker:new("0:checkboxes", self.thing.notes, self.slot),
      Sticker:new("0:progressbar", self.thing.notes, self.slot)
    }, true)

---@diagnostic disable-next-line: redundant-parameter
    ImGui.PushFont(ctx, app_ctx.arial_font, 12)
    ImGui.SeparatorText(ctx, "Custom Stickers        ")
    ImGui.SameLine(ctx,0,5)
    ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) - 20)
    ImGui.SetCursorPosY(ctx, ImGui.GetCursorPosY(ctx) + 2)
    local px, py = ImGui.GetCursorScreenPos(ctx)

    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 2)
    if ImGui.Button(ctx, "+##new_sticker") then
      self.sticker_editor = StickerEditor:new(nil, self.thing, self.slot)
      self.sticker_editor:setPosition(px + 20, py)
    end
    ImGui.PopStyleVar(ctx)

    ImGui.PopFont(ctx)

    picked = picked or self:renderStickerZone(ctx, list, false)

    if picked then
      -- A sticker was picked.
      if ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl) then
        -- Ctrl : remove the picked sticker
        local stickers = {}
        for _, s in ipairs(self.sticker_library) do
          if s:pack() ~= picked:pack() then
            stickers[#stickers+1] = s
          end
        end

        self.sticker_library = Sticker.NormalizeLibrary(stickers)
        self:commit()
        picked = nil
      elseif ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Right) then
        self.sticker_editor = StickerEditor:new(picked, self.thing, self.slot)
        self.sticker_editor:setPosition(px + 20, py)
        picked = nil
      end
    end

    ImGui.NewLine(ctx)
    ImGui.Dummy(ctx, 1, 1)

    ImGui.PopID(ctx)
    ImGui.End(ctx)

    if self.grab_focus then
      self.grab_focus = false
    end

    if self.sticker_editor and not self.sticker_editor.open then
      self.sticker_editor = nil
      self.grab_focus     = true
    end

    if self.sticker_editor then
      local res = self.sticker_editor:draw(self.color)
      if res and not res:isEmpty() then
        if self.sticker_editor.new_record then
          self.sticker_library[#self.sticker_library+1] = res
        end
        self:commit()
      end
    end

    if picked then
      is_open = false
    end

    self.draw_count = self.draw_count + 1
  end

  self.open = is_open

  return picked
end

return StickerPicker

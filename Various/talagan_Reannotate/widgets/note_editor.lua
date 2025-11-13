-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local ImGui         = require "ext/imgui"
local AppContext    = require "classes/app_context"
local Notes         = require "classes/notes"
local Color         = require "classes/color"
local StickerPicker = require "widgets/sticker_picker"
local Sticker       = require "classes/sticker"

local NoteEditor = {}
NoteEditor.__index = NoteEditor

function NoteEditor:new()
  local instance = {}
  setmetatable(instance, self)
  instance:_initialize()
  return instance
end

function NoteEditor:_initialize()
  self.draw_count  = 0
  self.rand        = math.random()
  self.open        = true
  self.sticker_base_size = Sticker.DEFAULT_SIZE
end

function NoteEditor:setPosition(x,y)
  self.x, self.y = x, y
end

function NoteEditor:setSize(w,h)
  self.w, self.h = w, h
end

function NoteEditor:setEditedThing(thing)
  self.edited_thing = thing
end

function NoteEditor:setEditedSlot(slot)
  self.edited_slot = slot
end

function NoteEditor:GrabFocus()
  self.grab_focus = true
end

function NoteEditor:title()
  local t = "Editing annotations for "

  if self.edited_thing.type == "track" then
    t = t .. "Track"
  elseif self.edited_thing.type == "env" then
    t = t .. "Envelope"
  elseif self.edited_thing.type == "item" then
    t = t .. "Item"
  elseif self.edited_thing.type == "project" then
    t = t .. "Project"
  else
    error("Unimplemented")
  end

  t = t .. " "
  t = t .. self.edited_thing.name

  return t
end

function NoteEditor:onSlotEditChange()
  if self.slot_edit_change_callback then
    self.slot_edit_change_callback()
  end
end

function NoteEditor:onSlotCommit()
  if self.slot_commit_callback then
    self.slot_commit_callback()
  end
end

function NoteEditor:renderStickerZone(ctx, stickers, should_go_to_line)
  local num_on_line     = 0
  local xc, yc          = ImGui.GetCursorScreenPos(ctx)
  local last_vspacing   = nil
  local clicked         = nil
  local color           = Color:new(Notes.SlotColor(self.edited_slot)):to_irgba()

  for _, sticker in ipairs(stickers) do
    local metrics           = sticker:PreRender(ctx, self.sticker_base_size)
    local estimated_width   = metrics.width
    local estimated_spacing = 4

    xc, yc    = ImGui.GetCursorScreenPos(ctx)

    if num_on_line ~= 0 then
      estimated_width = estimated_spacing + estimated_width
    end

    local rw, _ = ImGui.GetContentRegionAvail(ctx)
    if estimated_width > rw and num_on_line ~= 0 then
      -- Go to line if no more room
      ImGui.NewLine(ctx)
      xc, yc  = ImGui.GetCursorScreenPos(ctx)
      yc      = yc + 5
      ImGui.SetCursorScreenPos(ctx, xc, yc)
      num_on_line = 0
    elseif num_on_line ~= 0 then
      -- Enough room,
      -- Add horizontal spacing for separation and advance
      xc = xc + 2
      ImGui.SetCursorScreenPos(ctx, xc, yc)
    end
    local hov = sticker:Render(ctx, metrics, xc, yc, color, 0x000000FF)
    if hov then
      if ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Left) then
        clicked = sticker
      end
      ImGui.SetTooltip(ctx,"Ctrl+click to remove")
    end
    num_on_line = num_on_line + 1
    last_vspacing = estimated_spacing
  end

  local xc, yc = ImGui.GetCursorScreenPos(ctx)
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
      ImGui.SetCursorScreenPos(ctx, xc, yc)
    end
  end

  return clicked
end

function NoteEditor:draw()
  local app_ctx     = AppContext.instance()
  local ctx         = app_ctx.imgui_ctx
  local cursor_func = app_ctx.cursor_func

  local x = self.x or 100
  local y = self.y or 100
  local w = self.w or 300
  local h = self.h or 200

  local minw = math.max(w, 300)
  local minh = math.max(h, 200)

  ImGui.SetNextWindowSize(ctx, w, h, ImGui.Cond_Appearing)
  ImGui.SetNextWindowPos(ctx, x, y, ImGui.Cond_Appearing )

  -- Don't save the settings
  local b, is_open = ImGui.Begin(ctx, self:title() .. "##edit_notes_" .. self.rand, true, ImGui.WindowFlags_TopMost | ImGui.WindowFlags_NoSavedSettings)
  if b then

    ImGui.PushID(ctx, "note_editor_" .. self.rand)

    local entry   = self.edited_thing.notes:slotText(self.edited_slot)

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
          error("CANNOT RETRIEVE HWND FOR NOTE EDITOR")
        end
      end
    end

    if ImGui.IsWindowAppearing(ctx) then
      self.draw_count = 0
    end

    if self.draw_count == 1 then
      ImGui.Function_SetValue(app_ctx.cursor_func, "WANTED_CURSOR", string.len(entry))
    end

    local sel_col = Color:new(Notes.SlotColor(self.edited_slot))
    ImGui.PushStyleColor(ctx, ImGui.Col_TabSelected, sel_col:to_irgba())

    if ImGui.BeginTabBar(ctx, "Test##note_editor_tab", ImGui.TabBarFlags_NoCloseWithMiddleMouseButton | ImGui.TabBarFlags_NoTabListScrollingButtons) then

      local selection_has_changed = (self.last_selected_tab ~= self.edited_slot)

      for i=0, Notes.MAX_SLOTS-1 do
        local slot    = (i==Notes.MAX_SLOTS - 1) and (0) or (i+1) -- Put SWS/Reaper at the end

        if slot == 0 and self.edited_thing.type == "env" then
        else
          local col     = Color:new(Notes.SlotColor(slot))
          local h, s, v = col:hsv()

          local tab_col = Color:new(0)
          tab_col:setHsv(h,s,v*0.5)

          ImGui.PushStyleColor(ctx, ImGui.Col_Tab, tab_col:to_irgba())
          ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x000000FF)
          ImGui.PushStyleColor(ctx, ImGui.Col_TabHovered, col:to_irgba())
          ImGui.PushStyleColor(ctx, ImGui.Col_TabSelected, col:to_irgba())

          local flags = ImGui.TabItemFlags_NoAssumedClosure| ImGui.TabItemFlags_NoCloseWithMiddleMouseButton | ImGui.TabItemFlags_NoReorder

          if (slot == self.edited_slot) and selection_has_changed then
            flags = flags | ImGui.TabItemFlags_SetSelected
          end

          local e_vis, e_sel = ImGui.BeginTabItem(ctx, Notes.SlotLabel(slot), false, flags)

          if e_vis then
            -- The tab api is awfull and needs to track things to avoid race conditions
            if e_sel and not selection_has_changed then
              if slot ~= self.edited_slot then
                self.edited_slot = slot
                self.grab_focus = true
                self.draw_count = 0
                self.sticker_picker = nil
                self:onSlotEditChange()
              end
            end
            ImGui.EndTabItem(ctx)
          end

          ImGui.PopStyleColor(ctx, 4)
        end
      end

      self.last_selected_tab = self.edited_slot

      ImGui.EndTabBar(ctx)
    end

    ImGui.PopStyleColor(ctx)

    -- Sticker zone

    ImGui.Dummy(ctx,0,2)
    ImGui.Text(ctx, "Stickers")
    ImGui.SameLine(ctx)
    ImGui.SetCursorPosY(ctx, ImGui.GetCursorPosY(ctx) - 2)

    local slot_stickers = self.edited_thing.notes:slotStickers(self.edited_slot)
    if #slot_stickers > 0 then
      slot_stickers = Sticker.UnpackCollection(slot_stickers, self.edited_thing, self.edited_slot)

      local sticker_clicked = self:renderStickerZone(ctx, slot_stickers, false)
      if sticker_clicked and ImGui.IsKeyDown(ctx, ImGui.Mod_Ctrl) then
        -- Remove sticker from the slot
        local stickers        = {}
        for _, s in ipairs(slot_stickers) do
          if s ~= sticker_clicked then
            stickers[#stickers+1] = s
          end
        end
        local stickers_packed = Sticker.PackCollection(Sticker.NormalizeCollection(stickers, false))
        self.edited_thing.notes:setSlotStickers(self.edited_slot, stickers_packed)
        self.edited_thing.notes:commit()
      end
    end

    local xc, yc = ImGui.GetCursorScreenPos(ctx)
    ImGui.SetCursorScreenPos(ctx, xc + 6, yc + 1)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 2)
    local px, py = ImGui.GetCursorScreenPos(ctx)
    if ImGui.Button(ctx, "+") then
      self.sticker_picker = StickerPicker:new(self.edited_thing, self.edited_slot)
      self.sticker_picker:setPosition(px + 20, py)
    end
    ImGui.PopStyleVar(ctx)

    ImGui.Dummy(ctx,0,2)

    local ax, ay  = ImGui.GetContentRegionAvail(ctx)
    if self.grab_focus then
      ImGui.SetKeyboardFocusHere(ctx)
    end

    b, entry = ImGui.InputTextMultiline(ctx, "##reannotate_note_edit_multiline_" .. self.rand, entry,  ax , ay, ImGui.InputTextFlags_CallbackAlways, cursor_func)

    -- Because we're in auto commit, close on shift enter or escape
    if ImGui.IsWindowFocused(ctx) and (ImGui.IsKeyChordPressed(ctx, ImGui.Key_Enter | ImGui.Mod_Shift) or ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false))  then
      is_open = false
    end

    if b and is_open then
      self.edited_thing.notes:setSlotText(self.edited_slot, entry)
      self.edited_thing.notes:commit()

      local alternate_entry = self.edited_thing.mcp_entry or self.edited_thing.tcp_entry
      if alternate_entry then
        alternate_entry.notes:pull()
      end
      self:onSlotCommit()
    end

    if self.grab_focus then
      self.grab_focus = false
    end

    if self.sticker_picker and not self.sticker_picker.open then
      self.sticker_picker = nil
      self.grab_focus = true
    end

    if self.sticker_picker then
      local picked_sticker = self.sticker_picker:draw(ctx)
      if picked_sticker then
        self.sticker_picker.open = false

        -- Get stickers from slot
        local stickers_packed = self.edited_thing.notes:slotStickers(self.edited_slot)
        -- Unpack stickers
        local stickers        = Sticker.UnpackCollection(stickers_packed, self.edited_thing, self.edited_slot)
        -- Add sticker to slot
        stickers[#stickers+1] = picked_sticker
        -- Repack
        stickers_packed = Sticker.PackCollection(Sticker.NormalizeCollection(stickers, false))

        self.edited_thing.notes:setSlotStickers(self.edited_slot, stickers_packed)
        self.edited_thing.notes:commit()
      end
    end

    -- Remember positions
    self.w, self.h = ImGui.GetWindowSize(ctx)
    self.x, self.y = ImGui.GetWindowPos(ctx)

    ImGui.PopID(ctx)
    ImGui.End(ctx)

    self.draw_count = self.draw_count + 1
  end

  self.open = is_open
end

return NoteEditor

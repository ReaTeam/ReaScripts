-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local ImGui         = require "ext/imgui"
local AppContext    = require "classes/app_context"
local Notes         = require "classes/notes"
local Color         = require "classes/color"

local NoteEditor = {}
NoteEditor.__index = NoteEditor

function NoteEditor:new()
  local instance = {}
  setmetatable(instance, self)
  instance:_initialize()
  self.editor_draw_count = 0
  self.show_editor = true
  self.rand = math.random()
  return instance
end

function NoteEditor:_initialize()
end

function NoteEditor:setPosition(x,y)
  self.x, self.y = x, y
end

function NoteEditor:setSize(w,h)
  self.w, self.h = w, h
end

function NoteEditor:setEditContext(edit_context)
  self.edit_context = edit_context
end

function NoteEditor:setEditedSlot(slot)
  self.edited_slot = slot
end

function NoteEditor:GrabFocus()
  self.grab_focus = true
end

function NoteEditor:title()
  local t = "Editing annotations for "

  if self.edit_context.type == "track" then
    t = t .. "Track"
  elseif self.edit_context.type == "env" then
    t = t .. "Envelope"
  elseif self.edit_context.type == "item" then
    t = t .. "Item"
  elseif self.edit_context.type == "project" then
    t = t .. "Project"
  else
    error("Unimplemented")
  end

  t = t .. " "
  t = t .. self.edit_context.name

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

    local entry   = self.edit_context.notes:slot(self.edited_slot)

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
      self.editor_draw_count = 0
    end

    if self.editor_draw_count == 1 then
      ImGui.Function_SetValue(app_ctx.cursor_func, "WANTED_CURSOR", string.len(entry))
    end

    local sel_col = Color:new(Notes.SlotColor(self.edited_slot))
    ImGui.PushStyleColor(ctx, ImGui.Col_TabSelected, sel_col:to_irgba())

    if ImGui.BeginTabBar(ctx, "Test##note_editor_tab", ImGui.TabBarFlags_NoCloseWithMiddleMouseButton | ImGui.TabBarFlags_NoTabListScrollingButtons) then

      local selection_has_changed = (self.last_selected_tab ~= self.edited_slot)

      for i=0, Notes.MAX_SLOTS-1 do
        local slot    = (i==Notes.MAX_SLOTS - 1) and (0) or (i+1) -- Put SWS/Reaper at the end

        if slot == 0 and self.edit_context.type == "env" then
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
                self.editor_draw_count = 0
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

    local ax, ay  = ImGui.GetContentRegionAvail(ctx)
    if self.grab_focus then
      ImGui.SetKeyboardFocusHere(ctx)
    end

    b, entry = ImGui.InputTextMultiline(ctx, "##reannotate_note_edit_multiline_" .. self.rand, entry,  ax , ay, ImGui.InputTextFlags_CallbackAlways, cursor_func)

    -- Because we're in auto commit, close on shift enter or escape
    if ImGui.IsKeyChordPressed(ctx, ImGui.Key_Enter | ImGui.Mod_Shift) or ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false)  then
      is_open = false
    end

    if b and is_open then
      self.edit_context.notes:setSlot(self.edited_slot, entry)
      self.edit_context.notes:commit()

      local alternate_entry = self.edit_context.mcp_entry or self.edit_context.tcp_entry
      if alternate_entry then
        alternate_entry.notes:pull()
      end
      self:onSlotCommit()
    end

    if self.grab_focus then
      self.grab_focus = false
    end

    -- Remember positions
    self.w, self.h = ImGui.GetWindowSize(ctx)
    self.x, self.y = ImGui.GetWindowPos(ctx)

    ImGui.PopID(ctx)
    ImGui.End(ctx)

    self.editor_draw_count = self.editor_draw_count + 1
  end

  if not is_open then
    self.show_editor = false
  end

  return self.show_editor
end

return NoteEditor

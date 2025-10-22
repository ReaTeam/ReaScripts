-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local ImGui         = require "ext/imgui"
local AppContext    = require "classes/app_context"
local Notes         = require "classes/notes"
local S             = require "modules/settings"

local SettingsEditor = {}
SettingsEditor.__index = SettingsEditor

function SettingsEditor:new()
  local instance = {}
  setmetatable(instance, self)
  instance:_initialize()
  self.draw_count = 0
  return instance
end

function SettingsEditor:_initialize()
    self.open = true
end

function SettingsEditor:setPosition(pos_x, pos_y)
    self.pos = { x = pos_x, y = pos_y}
end

function SettingsEditor:draw()
    local app_ctx   = AppContext:instance()
    local ctx       = app_ctx.imgui_ctx


    local b, open = ImGui.Begin(ctx, "Reannotate Settings##reannotate_settings_editor", true,
        ImGui.WindowFlags_AlwaysAutoResize |
        ImGui.WindowFlags_NoDocking |
        ImGui.WindowFlags_NoResize |
        ImGui.WindowFlags_TopMost |
        ImGui.WindowFlags_NoCollapse
    )

    -- Set initiial position
    if ImGui.IsWindowAppearing(ctx) and self.pos then
        ImGui.SetWindowPos(ctx, self.pos.x, self.pos.y)
    end

    -- Close window on escape
    if ImGui.IsWindowFocused(ctx) then
        if ImGui.IsKeyChordPressed(ctx, ImGui.Key_Escape) then
            open = false
        end
    end

    if b then
        ImGui.SeparatorText(ctx, "Category Names")

        if ImGui.BeginTable(ctx, "aaaa##table", 3) then
            ImGui.TableSetupColumn(ctx, "")
            ImGui.TableSetupColumn(ctx, "New Project")
            ImGui.TableSetupColumn(ctx, "Current Project")
            ImGui.TableHeadersRow(ctx)
            for i=0, Notes.MAX_SLOTS-1 do
                local slot = (i==Notes.MAX_SLOTS - 1) and (0) or (i+1)
                ImGui.TableNextRow(ctx)
                ImGui.TableNextColumn(ctx)

                ImGui.PushItemFlag(ctx, ImGui.ItemFlags_NoTabStop, true)
                ImGui.ColorEdit4(ctx, "##col_slot_" .. i, (Notes.SlotColor(slot) << 8) | 0xFF, ImGui.ColorEditFlags_NoPicker | ImGui.ColorEditFlags_NoDragDrop | ImGui.ColorEditFlags_NoInputs | ImGui.ColorEditFlags_NoBorder | ImGui.ColorEditFlags_NoTooltip)
                ImGui.PopItemFlag(ctx)

                --ImGui.Text(ctx,"y1")
                ImGui.TableNextColumn(ctx)
                ImGui.SetNextItemWidth(ctx, 150)
                if slot ~= 0 then
                    local lab   = S.getSetting("SlotLabel_" .. slot)
                    local b, v  = ImGui.InputText(ctx, "##new_proj_edit_slot_" .. i, lab)
                    if b then
                        S.setSetting("SlotLabel_" .. slot, v)
                    end
                else
                    ImGui.Text(ctx, " " .. Notes.SlotLabel(slot))
                end
                ImGui.TableNextColumn(ctx)
                ImGui.SetNextItemWidth(ctx, 150)
                if slot ~= 0 then
                    local b, v = ImGui.InputText(ctx, "##cur_proj_edit_slot_" .. i, Notes.SlotLabel(slot))
                    if b then
                        Notes.SetSlotLabel(slot, v)
                    end
                else
                    ImGui.Text(ctx, " " .. Notes.SlotLabel(slot))
                end
            end
            ImGui.TableNextRow(ctx)
            ImGui.TableNextColumn(ctx)
            ImGui.TableNextColumn(ctx)
            if ImGui.Button(ctx, "Reset to defaults##reset_global_labels_to_defaults_button") then
                for i = 0, Notes.MAX_SLOTS-1 do
                    S.resetSetting("SlotLabel_"..i)
                end
            end
            ImGui.TableNextColumn(ctx)
            if ImGui.Button(ctx, "Reset to defaults##reset_project_labels_to_defaults_button") then
                for i = 0, Notes.MAX_SLOTS-1 do
                    Notes.SetSlotLabel(i, S.getSettingSpec("SlotLabel_"..i).default )
                end
            end

            ImGui.EndTable(ctx)
        end

        ImGui.End(ctx)
    end

    self.open       = open
    self.draw_count = self.draw_count + 1
end

return SettingsEditor

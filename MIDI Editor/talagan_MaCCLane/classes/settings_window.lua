-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local MACCLContext    = require "modules/context"
local S               = require "modules/settings"
local TabParams       = require "modules/tab_params"
local Tab             = require "classes/tab"

local ImGui           = MACCLContext.ImGui

local SettingsWindow = {}
SettingsWindow.__index = SettingsWindow

SettingsWindow.registry = {}

function SettingsWindow:new ()
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize()
    return instance
end

function SettingsWindow:_initialize()
end

function SettingsWindow:newTabDefaultOwnerComboBox()
    local ctx = MACCLContext.ImGuiContext

    local defs = {
        { name = Tab.Types.GLOBAL, human = "Global" },
        { name = Tab.Types.PROJECT, human = "Project" },
        { name = Tab.Types.TRACK,   human = "Track" },
        { name = Tab.Types.ITEM,    human = "Item" }
    }

    local lookup = {}
    for i, v in ipairs(defs) do lookup[v.name] = v end

    local selectableLabel = function (name)
        return '' .. lookup[name].human .. '##sort_strat_' .. name
    end

    local curr = S.getSetting("DefaultOwnerTypeForNewTab")

    ImGui.PushID(ctx, "default_owner_combo_box")
    ImGui.SetNextItemWidth(ctx, 250)
    if ImGui.BeginCombo(ctx, "Default owner", selectableLabel(curr)) then
        for i,v in ipairs(defs) do
            local name          = v.name
            local is_selected   = (name == curr)

            if ImGui.Selectable(ctx, selectableLabel(name), is_selected) then
                S.setSetting("DefaultOwnerTypeForNewTab", name)
            end

            if is_selected then
                ImGui.SetItemDefaultFocus(ctx)
            end
        end
        ImGui.EndCombo(ctx)
    end
    ImGui.PopID(ctx)
end

function SettingsWindow:gfx()
    local ctx = MACCLContext.ImGuiContext

    if not ctx then return end -- Ouch

    if not self.draw_count then
        self.draw_count = 0
    else
        self.draw_count = self.draw_count + 1
    end

    -- Flags : never save the window settings in the ini file. Since the title is dependent of the UUID, this would totally spam it
    ImGui.PushID(ctx, "global_settings_window")

    local visible, open = ImGui.Begin(ctx, "MaCCLane Settings##macclane_settings", true, ImGui.WindowFlags_AlwaysAutoResize | ImGui.WindowFlags_NoDocking)
    if visible then
        ImGui.SeparatorText(ctx, "Appearance")

        ImGui.BeginGroup(ctx)
        if true then
            ImGui.SetNextItemWidth(ctx, 80)
            local b, v = ImGui.SliderInt(ctx, "Tab margin", S.getSetting("TabMargin"), 0, 20, "%d px")
            if b then
                S.setSetting("TabMargin", v)
                MACCLContext.notifySettingsChange()
            end
            if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Right) then
                S.resetSetting("TabMargin")
                MACCLContext.notifySettingsChange()
            end

            ImGui.SetNextItemWidth(ctx, 80)
            local b, v = ImGui.SliderInt(ctx, "Tab spacing", S.getSetting("TabSpacing"), 0, 20, "%d px")
            if b then
                S.setSetting("TabSpacing", v)
                MACCLContext.notifySettingsChange()
            end
            if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Right) then
                S.resetSetting("TabSpacing")
                MACCLContext.notifySettingsChange()
            end
        end
        ImGui.EndGroup(ctx)

        ImGui.SameLine(ctx)

        ImGui.BeginGroup(ctx)
        if true then
            ImGui.SetNextItemWidth(ctx, 80)
            local b, v = ImGui.SliderInt(ctx, "Widget margin", S.getSetting("WidgetMargin"), 0, 20, "%d px")
            if b then
                S.setSetting("WidgetMargin", v)
                MACCLContext.notifySettingsChange()
            end
            if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Right) then
                S.resetSetting("WidgetMargin")
                MACCLContext.notifySettingsChange()
            end
            ImGui.SetNextItemWidth(ctx, 80)
            local b, v = ImGui.SliderInt(ctx, "Font Size", S.getSetting("FontSize"), S.getSettingSpec("FontSize").min, S.getSettingSpec("FontSize").max, "%d px")
            if b then
                S.setSetting("FontSize", v)
                MACCLContext.recreateFont(v)
                MACCLContext.notifySettingsChange()
            end
            if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Right) then
                S.resetSetting("FontSize")
                MACCLContext.recreateFont(S.getSetting("FontSize"))
                MACCLContext.notifySettingsChange()
            end
        end
        ImGui.EndGroup(ctx)

        ImGui.SameLine(ctx)

        ImGui.BeginGroup(ctx)
        if true then
            local b, v = ImGui.ColorEdit3(ctx, 'Global  tabs color', S.getSetting("ColorForGlobalTabs"), ImGui.ColorEditFlags_NoInputs)
            if b then
                S.setSetting("ColorForGlobalTabs", v)
            end
            local b, v = ImGui.ColorEdit3(ctx, 'Project tabs color', S.getSetting("ColorForProjectTabs"), ImGui.ColorEditFlags_NoInputs)
            if b then
                S.setSetting("ColorForProjectTabs", v)
            end
        end
        ImGui.EndGroup(ctx)


        ImGui.SeparatorText(ctx, "Tab order")

        local selectableLabel = function (strat_name)
            return '' .. TabParams.SortStrategy:humanize(strat_name) .. '##sort_strat_' .. strat_name
        end

        local curr_strat = S.getSetting("SortStrategy")
        ImGui.SetNextItemWidth(ctx, 300)
        if ImGui.BeginCombo(ctx, "Sort strategy", selectableLabel(curr_strat)) then
            for i,v in ipairs(TabParams.SortStrategy.defs) do
                local strat_name    = v.name
                local is_selected   = (strat_name == curr_strat)

                if ImGui.Selectable(ctx, selectableLabel(strat_name), is_selected) then
                    S.setSetting("SortStrategy", strat_name)
                    MACCLContext.notifySettingsChange()
                end

                if is_selected then
                    ImGui.SetItemDefaultFocus(ctx)
                end
            end
            ImGui.EndCombo(ctx)
        end

        ImGui.SeparatorText(ctx, "New tab")
        self:newTabDefaultOwnerComboBox()

        ImGui.End(ctx)
    end
    ImGui.PopID(ctx)

    if not open then
        -- Remove from manager
        self.should_be_open = false
    end
end

local _instance = nil
function SettingsWindow.instance()
    if not _instance then _instance = SettingsWindow:new() end
    return _instance
end
function SettingsWindow.process()
    local inst = SettingsWindow.instance()
    if not inst.should_be_open then return end

    inst:gfx()
end
function SettingsWindow.open()
    local inst = SettingsWindow.instance()
    inst.should_be_open = true
end
function SettingsWindow.needsImGuiContext()
    local inst = SettingsWindow.instance()
    return inst.should_be_open
end

return SettingsWindow

-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local MACCLContext    = require "modules/context"
local S               = require "modules/settings"
local TabParams       = require "modules/tab_params"
local Tab             = require "classes/tab"
local TemplateHierarchy      = require "classes/template_hierarchy"

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

local LABEL_COLOR = 0x54c0ffFF

function SettingsWindow:newTabDefaultOwnerComboBox()
    local ctx = MACCLContext.ImGuiContext

    local defs = {
        { name = Tab.Types.GLOBAL,  human = "Global" },
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
    ImGui.SetNextItemWidth(ctx, 100)
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

function SettingsWindow:gfxPlusButton()
    local ctx = MACCLContext.ImGuiContext

    ImGui.AlignTextToFramePadding(ctx)
    ImGui.TextColored(ctx, LABEL_COLOR, "Left click default")
    ImGui.SameLine(ctx)

    if ImGui.Button(ctx, '...') then
        self.template_hierarchy = TemplateHierarchy.buildRootNode()
        ImGui.OpenPopup(ctx, 'plus_button_left_click')
    end

    if ImGui.BeginPopup(ctx, 'plus_button_left_click') then
        TemplateHierarchy.hiearchySubMenu(ctx, self.template_hierarchy, function(file)
            S.setSetting("DefaultTemplateForPlusButton", file.full_path)
        end)
        ImGui.Separator(ctx)
        if ImGui.Selectable(ctx, "Full Bypass", false) then
            S.setSetting("DefaultTemplateForPlusButton", "*full_bypass")
        end
        if ImGui.Selectable(ctx, "Full Recording", false) then
            S.setSetting("DefaultTemplateForPlusButton", "*full_record")
        end

        ImGui.EndPopup(ctx)
    end

    ImGui.SameLine(ctx)

    local p = tostring(S.getSetting("DefaultTemplateForPlusButton"))
    if p == "*full_bypass" then
        p = "Full Bypass"
    elseif p == "*full_record" then
        p = "Full Recording"
    else
        if not (self.last_checked_template == p) then
            -- TODO : Check template existence
            self.last_checked_template = p
        end
        local rp = reaper.GetResourcePath() .. "/Data/MaCCLane"
        local i1, i2 = string.find(p, rp)
        if i2 then p = string.sub(p, i2 + 1, #p) end
    end

    ImGui.Text(ctx, p)
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
            ---@diagnostic disable-next-line: param-type-mismatch
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
            ---@diagnostic disable-next-line: param-type-mismatch
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
            ---@diagnostic disable-next-line: param-type-mismatch
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
            ---@diagnostic disable-next-line: param-type-mismatch
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

        ImGui.Dummy(ctx, 10, 5)

        ImGui.AlignTextToFramePadding(ctx)
        ImGui.TextColored(ctx, LABEL_COLOR, "Tab Colors     ")
        ImGui.SameLine(ctx)
        ---@diagnostic disable-next-line: param-type-mismatch
        local b, v = ImGui.ColorEdit3(ctx, 'Global  ', S.getSetting("ColorForGlobalTabs"), ImGui.ColorEditFlags_NoInputs)
        if b then
            S.setSetting("ColorForGlobalTabs", v)
            MACCLContext.notifySettingsChange()
        end
        ImGui.SameLine(ctx)
        ---@diagnostic disable-next-line: param-type-mismatch
        local b, v = ImGui.ColorEdit3(ctx, 'Project ', S.getSetting("ColorForProjectTabs"), ImGui.ColorEditFlags_NoInputs)
        if b then
            S.setSetting("ColorForProjectTabs", v)
            MACCLContext.notifySettingsChange()
        end

        ImGui.AlignTextToFramePadding(ctx)
        ImGui.TextColored(ctx, LABEL_COLOR, "State Indicator")
        ImGui.SameLine(ctx)
        ---@diagnostic disable-next-line: param-type-mismatch
        local b, v = ImGui.ColorEdit4(ctx, 'Active  ##rec_indicator_active', S.getSetting("ActiveRecTabIndicatorColor"), ImGui.ColorEditFlags_NoInputs)
        if b then
            S.setSetting("ActiveRecTabIndicatorColor", v)
            MACCLContext.notifySettingsChange()
        end
        ImGui.SameLine(ctx)
        ---@diagnostic disable-next-line: param-type-mismatch
        local b, v = ImGui.ColorEdit4(ctx, 'Inactive##rec_indicator_inactive', S.getSetting("InactiveRecTabIndicatorColor"), ImGui.ColorEditFlags_NoInputs)
        if b then
            S.setSetting("InactiveRecTabIndicatorColor", v)
            MACCLContext.notifySettingsChange()
        end
        ImGui.SameLine(ctx)
        ImGui.Dummy(ctx, 5, 1)
        ImGui.SameLine(ctx)

        ImGui.SetNextItemWidth(ctx, 50)
        ---@diagnostic disable-next-line: param-type-mismatch
        local b, v = ImGui.SliderInt(ctx, 'Size##rec_tab_crop_size', S.getSetting("RecTabIndicatorSize"), 2, 6, "%d px")
        if b then
            S.setSetting("RecTabIndicatorSize", v)
            MACCLContext.notifySettingsChange()
        end

        ImGui.SeparatorText(ctx, "Tab edition")
        ImGui.AlignTextToFramePadding(ctx)
        ImGui.TextColored(ctx, 0x54c0ffFF, "Name edit > Enter")
        ImGui.SameLine(ctx)
        ImGui.SetNextItemWidth(ctx, 100)
        ---@diagnostic disable-next-line: param-type-mismatch
        local b, v = ImGui.Combo(ctx, '##name_enter_pressed', S.getSetting("OnNameEditEnterPressed"), "Saves tab\0Navigates\0")
        if b then
            S.setSetting("OnNameEditEnterPressed", v)
        end

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

        ImGui.SeparatorText(ctx, "(+) Button")
        self:gfxPlusButton()

        ImGui.SeparatorText(ctx, "Other")

        ---@diagnostic disable-next-line: param-type-mismatch
        local b, v = ImGui.Checkbox(ctx, "enable debug tools", S.getSetting("DebugTools"))
        if b then
            S.setSetting("DebugTools", v)
        end

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

-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local MACCLContext    = require "modules/context"
local S               = require "modules/settings"
local TabParams       = require "modules/tab_params"
local Tab             = require "classes/tab"

local ImGui           = MACCLContext.ImGui

local MultiExportWindow = {}
MultiExportWindow.__index = MultiExportWindow

MultiExportWindow.registry = {}

function MultiExportWindow:new ()
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize()
    return instance
end

function MultiExportWindow:_initialize()
end

function MultiExportWindow:gfx()
    local ctx = MACCLContext.ImGuiContext

    if not ctx then return end -- Ouch

    if not self.mec:isStillValid() then return end

    if not (self._cached_mec == self.mec) then
        self._cached_settings    = {}
        self._cached_mec         = self.mec
    end

    if not self.draw_count then
        self.draw_count = 0
    else
        self.draw_count = self.draw_count + 1
    end

    ImGui.PushID(ctx, "multi_export_window")

    local visible, open = ImGui.Begin(ctx, "MaCCLane : Export multiple tabs##macclane_multi_tab_export", true, ImGui.WindowFlags_AlwaysAutoResize | ImGui.WindowFlags_NoDocking)
    if visible then
        ImGui.SeparatorText(ctx, "Select tabs to export ...")

        for _, t in ipairs(self.mec:tabs()) do
            if t:exportable() then
                -- Check unknown tabs by default
                if self._cached_settings[t.uuid] == nil then self._cached_settings[t.uuid] = true end

                local b, v = ImGui.Checkbox(ctx, t.params.title .. "##" .. t.uuid, self._cached_settings[t.uuid])
                if b then
                    self._cached_settings[t.uuid] = v
                end
            end
        end

        if ImGui.Button(ctx, "Export")  then
            local spath = reaper.GetResourcePath() .. "/Data/MaCCLane/"
            local res, fname = reaper.JS_Dialog_BrowseForSaveFile("Save as multi template ...", spath, "multi export".. ".mcc", "*.mcc")
            if res == 1 then
                local file, err = io.open(fname, "wb")
                if file then
                    local tabs      = self.mec:tabs()
                    local to_export = {}
                    for _, t in ipairs(tabs) do
                        if self._cached_settings[t.uuid] then
                            to_export[#to_export+1] = t
                        end
                    end
                    local json = Serializing.serializeTabsForTemplate(to_export)
                    file:write(json)
                    io.close(file)
                    open = false
                else
                    reaper.MB("The file could not be opened for saving (" .. err .. ")", "Ouch.", 0)
                end
            end
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
function MultiExportWindow.instance()
    if not _instance then _instance = MultiExportWindow:new() end
    return _instance
end
function MultiExportWindow.process()
    local inst = MultiExportWindow.instance()
    if not inst.should_be_open then return end

    inst:gfx()
end
function MultiExportWindow.open(mec)
    local inst = MultiExportWindow.instance()

    inst.mec            = mec
    inst.should_be_open = true
end
function MultiExportWindow.needsImGuiContext()
    local inst = MultiExportWindow.instance()
    return inst.should_be_open
end

return MultiExportWindow

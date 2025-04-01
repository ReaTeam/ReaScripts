-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local MACCLContext           = require "modules/context"
local FILE                   = require "modules/file"

local Tab                    = require "classes/tab"
local SettingsWindow         = require "classes/settings_window"
local MultiExportWindow      = require "classes/multi_export_window"
local GlobalScopeRepo        = require "classes/global_scope_repo"

local S                      = require "modules/settings"
local LOG                    = require "modules/log"
local INSPECT                = require "lib/inspect"

local ImGui                  = MACCLContext.ImGui

-- Opens a popup menu on a tab
local TabPopupMenu = {}

TabPopupMenu.clear = function()
    TabPopupMenu.current_tab    = nil
    TabPopupMenu.last_open_tab  = nil
end

TabPopupMenu.openOnTab = function(tab)
    if TabPopupMenu.recently_closed_tab == tab or TabPopupMenu.current_tab == tab then
        -- Avoid reopening menu that was recently closed or that is currently open
        TabPopupMenu.clear()
    else
        TabPopupMenu.current_tab    = tab
    end
end

TabPopupMenu.needsImGuiContext = function()
    local has_current_tab                   = not (TabPopupMenu.current_tab == nil)

    return has_current_tab
end

TabPopupMenu.LoadTemplate = function(mec, ref_tab, path)
    local newtabs = Serializing.createTabsFromTemplate(mec, path)
    if not newtabs then
        return
    end
    for _, newtab in ipairs(newtabs) do
        newtab.last_draw_global_x   = ref_tab.last_draw_global_x
        newtab.last_draw_global_y   = ref_tab.last_draw_global_y
        newtab:save()
    end
end

TabPopupMenu.hiearchySubMenu = function(ctx, node)
    local tab = TabPopupMenu.current_tab
    local mec = tab.mec

    for _, sub in pairs(node.subs) do
        if sub.fweight > 0 then
            if ImGui.BeginMenu(ctx, sub.name) then
                TabPopupMenu.hiearchySubMenu(ctx, sub)
                ImGui.EndMenu(ctx)
            end
        end
    end

    for _, file in pairs(node.files) do
        if ImGui.MenuItem(ctx, file.name) then
            TabPopupMenu.LoadTemplate(mec, tab, file.full_path)
        end
    end
end


TabPopupMenu.process = function()

    if TabPopupMenu.recently_closed_tab_date and (reaper.time_precise() - TabPopupMenu.recently_closed_tab_date > 0.1) then
        -- Only remember the recently closed tab for a few ms, then forget
        TabPopupMenu.recently_closed_tab_date   = nil
        TabPopupMenu.recently_closed_tab        = nil
    end

    local ctx = MACCLContext.ImGuiContext
    local tab = TabPopupMenu.current_tab

    -- If no context, cannot show menu
    if not ctx then return end
    if not tab then return end

    local mec = tab.mec
    if not mec then return end

    if not mec:isStillValid() then
        TabPopupMenu.clear()
        return
    end

    local popupid = "###popup_menu_" .. tab:UUID()

    if not (TabPopupMenu.last_open_tab == tab) then
        local imx, imy = ImGui.PointConvertNative(ctx, tab.last_draw_global_x, tab.last_draw_global_y)
        ImGui.SetNextWindowPos(ctx, imx, imy - 5, 0, 0, 1) -- Bottom left corner of the window aligned on top left corner of the tab
        ImGui.OpenPopup(ctx, popupid, ImGui.PopupFlags_NoOpenOverExistingPopup)
        TabPopupMenu.last_open_tab = tab
        if tab.owner_type == Tab.Types.PLUS_TAB then
            local rootdir                   = reaper.GetResourcePath() .. "/Data/MaCCLane"
            TabPopupMenu.template_hierarchy = FILE.crawlForFiles(rootdir,  "mcc")
        end
        ImGui.SetNextWindowFocus(ctx)
    end

    if ImGui.BeginPopup(ctx, popupid) then
        if tab.owner_type == Tab.Types.PLUS_TAB then
            if ImGui.MenuItem(ctx, "Settings ...") then
                SettingsWindow.open()
            end

            ImGui.Separator(ctx)

            if ImGui.MenuItem(ctx, "Import ...") then
                local spath = reaper.GetResourcePath() .. "/Data/MaCCLane/"
                local res, fname = reaper.JS_Dialog_BrowseForOpenFiles("Import ...", spath, "", "*.mcc", false)
                if res == 1 then
                    TabPopupMenu.LoadTemplate(mec, tab, fname)
                end
            end

            if ImGui.MenuItem(ctx, "Export ...") then
                MultiExportWindow.open(mec)
            end

            ImGui.Separator(ctx)

            ImGui.MenuItem(ctx, "Templates", nil, false, false)

            TabPopupMenu.hiearchySubMenu(ctx, TabPopupMenu.template_hierarchy)

            ImGui.Separator(ctx)
            if ImGui.MenuItem(ctx, "Reveal template folder") then
                local spath = reaper.GetResourcePath() .. "/Data/MaCCLane/"
                reaper.CF_ShellExecute(spath)
            end

            ImGui.Separator(ctx)
            if ImGui.MenuItem(ctx, "Paste...", '', false, not (TabPopupMenu.copiedTab == nil)) then
                local srctab = TabPopupMenu.copiedTab

                -- Try to mimic owner from src owner
                local owner = nil
                if srctab.owner_type == Tab.Types.GLOBAL then
                    owner = GlobalScopeRepo.instance()
                elseif srctab.owner_type == Tab.Types.TRACK then
                    owner = mec.track
                elseif srctab.owner_tyep == Tab.Types.ITEM then
                    owner = mec.item
                else
                    owner = nil
                end

                local newtab                = Tab:new(mec, owner, TabPopupMenu.copiedTab.params, TabPopupMenu.copiedTab.state)
                newtab.last_draw_global_x   = tab.last_draw_global_x
                newtab.last_draw_global_y   = tab.last_draw_global_y
                newtab:save()
            end
            ImGui.Separator(ctx)
            if ImGui.MenuItem(ctx, "New Recording Tab ...") then
                mec:openEditorForNewTab(tab, {full_record=true})
            end
            if ImGui.MenuItem(ctx, "New Bypass Tab ...") then
                mec:openEditorForNewTab(tab)
            end
        else
            local meinfo = mec:editorInfo()
            local col, _, _ = tab:colors(mec, true)

            ImGui.ColorButton(ctx, "##col_prev", col, ImGui.ColorEditFlags_NoAlpha | ImGui.ColorEditFlags_NoLabel | ImGui.ColorEditFlags_NoPicker)
            ImGui.SameLine(ctx); ImGui.SetCursorPosY(ctx, ImGui.GetCursorPosY(ctx) + 2)
            ImGui.MenuItem(ctx, tab.params.title, nil, false, false)

            ImGui.Separator(ctx)

            if ImGui.MenuItem(ctx, "Delete") then
                tab:destroy()
            end
            ImGui.Separator(ctx)

            local star = "Move to "
            if tab.owner_type == Tab.Types.GLOBAL then star = "* Set on " end
            if ImGui.MenuItem(ctx, star .. "Global") then
                tab:setOwner(GlobalScopeRepo.instance())
                tab:save()
            end

            local star = "Move to "
            if tab.owner_type == Tab.Types.PROJECT then star = "* Set on " end
            if ImGui.MenuItem(ctx, star .. "Project") then
                tab:setOwner(nil)
                tab:save()
            end

            local star = "Move to "
            if tab.owner_type == Tab.Types.TRACK then star = "* Set on " end
            if meinfo.track and ImGui.MenuItem(ctx, star .. "Track (" .. meinfo.track_name .. ")") then
                tab:setOwner(meinfo.track)
                tab:save()
            end

            local star = "Move to "
            if tab.owner_type == Tab.Types.ITEM then star = "* Set on " end
            if meinfo.item and ImGui.MenuItem(ctx, star .. "current take's item (" .. meinfo.take_name .. ")") then
                tab:setOwner(meinfo.item)
                tab:save()
            end

            ImGui.Separator(ctx)
            if ImGui.MenuItem(ctx, "Save as template ...") then
                local spath = reaper.GetResourcePath() .. "/Data/MaCCLane/"
                local res, fname = reaper.JS_Dialog_BrowseForSaveFile("Save as template ...", spath, tab.params.title .. ".mcc", "*.mcc")
                if res == 1 then
                    local file, err = io.open(fname, "wb")
                    if file then
                        file:write(Serializing.serializeTabForTemplate(tab))
                        io.close(file)
                    else
                        reaper.MB("The file could not be opened for saving (" .. err .. ")", "Ouch.", 0)
                    end
                end
            end

            ImGui.Separator(ctx)
            if ImGui.MenuItem(ctx, "Copy") then
                TabPopupMenu.copiedTab = tab
            end
            if ImGui.MenuItem(ctx, "Cut") then
                TabPopupMenu.copiedTab = tab
                tab:destroy()
            end
            if ImGui.MenuItem(ctx, "Duplicate") then
                tab:duplicate()
            end

            if S.getSetting("DebugTools") then
                ImGui.Separator(ctx)
                if ImGui.MenuItem(ctx, "DEBUG : Print state") then
                    LOG.critical("" .. INSPECT(tab.state) .. "\n")
                end
            end

            ImGui.Separator(ctx)
            if ImGui.MenuItem(ctx, "Edit ...") then
                mec:openTabEditorOn(tab)
            end
        end
        ImGui.EndPopup(ctx)
    else
        TabPopupMenu.clear()
        TabPopupMenu.recently_closed_tab        = tab
        TabPopupMenu.recently_closed_tab_date   = reaper.time_precise()
    end
end

return TabPopupMenu

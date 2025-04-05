-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local FILE                   = require "modules/file"
local MACCLContext           = require "modules/context"
local ImGui                  = MACCLContext.ImGui

local TemplateHierarchy = {}

TemplateHierarchy.buildRootNode = function()
    local rootdir  = reaper.GetResourcePath() .. "/Data/MaCCLane"
    return FILE.crawlForFiles(rootdir,  "mcc")
end

TemplateHierarchy.hiearchySubMenu = function(ctx, node, click_callback)
    for _, sub in pairs(node.subs) do
        if sub.fweight > 0 then
            if ImGui.BeginMenu(ctx, sub.name) then
                TemplateHierarchy.hiearchySubMenu(ctx, sub, click_callback)
                ImGui.EndMenu(ctx)
            end
        end
    end

    for _, file in pairs(node.files) do
        if ImGui.MenuItem(ctx, file.name) and click_callback then
            click_callback(file)
        end
    end
end

return TemplateHierarchy

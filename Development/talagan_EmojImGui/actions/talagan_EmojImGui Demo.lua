-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of EmojImGui

-- Load IconPicker class
local ACTION       = debug.getinfo(1,"S").source
local ACTION_DIR   = (ACTION:match[[^@?(.*[\/])[^\/]-$]]):gsub("talagan_EmojImGui/actions/$","/") -- Works both in dev and prod

package.path = package.path .. ";" .. reaper.ImGui_GetBuiltinPath() .. '/?.lua'
package.path = package.path .. ";" .. ACTION_DIR .. "talagan_EmojImgui/?.lua"

local ImGui         = require "emojimgui/ext/imgui"
local EmojImGui     = require "emojimgui"

local use_profiler  = false

if use_profiler then
    local profiler       = dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Scripts/Development/cfillion_Lua profiler.lua')

    reaper.defer = profiler.defer
    profiler.attachToWorld() -- after all functions have been defined
    profiler.run()
end

-- Set the path to EmojImGui assets. Here it is done because the demo needs to work in dev directly from the git repo
-- But for any dev using the library, the path should already be set internally by the lib and this call is not needed.
EmojImGui.Asset.SetPath(ACTION_DIR .. "talagan_EmojImgui/assets/build")

-- Create ImGui context
local ctx = ImGui.CreateContext("EmojImGui Picker Demo")

-- Demo state
local selected_icon = nil
local picker        = nil

local function loop()
    local picked_icon = nil

    if picker then
        picked_icon = picker:draw(ctx)

        -- If an icon was selected
        if picked_icon then
            selected_icon = picked_icon
            picker = nil
        end
    end

    local visible, open = ImGui.Begin(ctx, "EmojImGui Demo", true, ImGui.WindowFlags_AlwaysAutoResize | ImGui.WindowFlags_NoDocking)
    if visible then
        ImGui.Text(ctx, "Selected icon" .. (selected_icon and " (Click to pick again)" or ""))
        ImGui.Separator(ctx)

        if selected_icon then
            local icon = selected_icon
            ImGui.PushFont(ctx, EmojImGui.Asset.Font(ctx, icon.font_name), 40)
            ImGui.Text(ctx, selected_icon.utf8)
            ImGui.PopFont(ctx)

            ImGui.SameLine(ctx)

            ImGui.Text(ctx, string.format("ID : %s\nLabel: " .. icon.label .. "\nMapped at : U+%X", icon.id, icon.codepoint) )
        else
            ImGui.Text(ctx, "None (click to pick)")
        end

        if not picker and ImGui.IsWindowHovered(ctx) and ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Left) then
            picker = EmojImGui.Picker:new()
        end

        if picker and not picker.open then
            -- Garbage collect the current picker if closed by user
            picker = nil
        end

        ImGui.End(ctx)
    end

    if not open then
        return
    end

    reaper.defer(loop)
end

reaper.defer(loop)

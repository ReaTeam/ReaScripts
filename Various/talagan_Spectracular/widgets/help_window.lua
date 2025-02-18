-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local ImGui = require "ext/imgui"
local S     = require "modules/settings"

-- Use a dedicated ctx for this window
local ctx = nil

local function tableHeaders(header1, header2, header3)
    if not ctx then return end
    ImGui.TableSetupColumn(ctx, header1)
    ImGui.TableSetupColumn(ctx, header2)
    ImGui.TableSetupColumn(ctx, header3)
    ImGui.TableHeadersRow(ctx)
end

local function helpTableLine(component, shortcut, desc)
    if not ctx then return end

    ImGui.TableNextRow(ctx)
    ImGui.TableNextColumn(ctx)
    ImGui.Text(ctx, component)
    ImGui.TableNextColumn(ctx)
    ImGui.Text(ctx, shortcut)
    ImGui.TableNextColumn(ctx)
    ImGui.Text(ctx, desc)
end

local function drawIfOpen()
    if not ctx then return end

    ImGui.SetNextWindowSizeConstraints(ctx, 400, 300, math.huge, math.huge)

    local visible, open = ImGui.Begin(ctx, "Spectracular help##Spectracular_help", true, ImGui.WindowFlags_TopMost | ImGui.WindowFlags_AlwaysAutoResize)
    if visible then
        ImGui.Text(ctx, "Here's a short summary of all possible interactions with Spetracular's UI")
        ImGui.Dummy(ctx,10,10)
        ImGui.SeparatorText(ctx, "Curve Widget")
        if ImGui.BeginTable(ctx, "help_table", 3, ImGui.TableFlags_Borders | ImGui.TableFlags_SizingFixedFit) then
            tableHeaders("Widget", "Interaction", "Effect description")
            helpTableLine("RMS Scale labels (right side)", "Click + Drag",  "Modify RMS curve dB limit (min or max)")
            helpTableLine("RMS Scale labels (right side)", "Right click",   "Reset RMS curve dB limit (min or max)")

            helpTableLine("Note Scale label (left side)", "Click + Drag",  "Modify note profile dB limit. Also affects the spectrograph colors.")
            helpTableLine("Note Scale label (left side)", "Right click", "Reset note profile dB limit. Also affects the spectrograph colors.")

            helpTableLine("Profile button",     "Click",        "Show/Hide profile curve")
            helpTableLine("Profile button",     "Right click",  "Ditch profile curve")
            helpTableLine("RMSE button",        "Click",        "Show/Hide RMSE curve")
            helpTableLine("L/R button",         "Click",        "Cycle through channel display modes (L/R/L+R)")

            ImGui.EndTable(ctx)
        end

        ImGui.Dummy(ctx,10,10)
        ImGui.SeparatorText(ctx, "Time line")
        if ImGui.BeginTable(ctx, "help_table_timeline", 3, ImGui.TableFlags_Borders | ImGui.TableFlags_SizingFixedFit) then
            tableHeaders("Widget", "Interaction", "Effect description")
            helpTableLine("Timeline", "MOD + Drag", "Resize the curve/spectrograph zones : it is used as a splitter between both.")
            ImGui.EndTable(ctx)
        end

        ImGui.Dummy(ctx,10,10)
        ImGui.SeparatorText(ctx, "Spectrograph")
        if ImGui.BeginTable(ctx, "help_table_spec", 3, ImGui.TableFlags_Borders | ImGui.TableFlags_SizingFixedFit) then
            tableHeaders("Widget", "Interaction", "Effect description")
            helpTableLine("Spectrograph", "Mouse wheel", "Zoom horirontally, keeping mouse center invariant")
            helpTableLine("Spectrograph", "MOD + Mouse wheel", "Zoom vertically, keeping mouse cursor invariant")
            helpTableLine("Spectrograph", "Clic + Drag", "Pan")
            helpTableLine("Spectrograph", "Right Click", "Reset zoom (if no profile line is hovered)")
            helpTableLine("Spectrograph", "Click",  "Extract profile for the given note height")
            helpTableLine("Profile Line", "Right click",  "Ditch the highlighted profile")
            helpTableLine("L/R Mix", "Click / Drag",  "Recalculate colors by adjusting the mix of the two channels")
            helpTableLine("Right drawer grip", "MOD + Drag",  "Drag the drawer grip to resize it (the MOD key lights up the grip)")
            ImGui.EndTable(ctx)
        end

        ImGui.End(ctx)
    end

    if not open then
        ctx = nil
    end
end

local function open(cx, cy)
    -- Create a new ctx for the help window (avoid interactions with the current context)
    ctx = ImGui.CreateContext(S.AppName .. "Help")
    ImGui.SetNextWindowPos(ctx, cx+100, cy+100)
end

return {
    open = open,
    drawIfOpen = drawIfOpen
}

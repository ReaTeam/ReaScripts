-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local Version                   = '0.1'

local S                         = require "modules/settings"
local DSP                       = require "modules/dsp"
local SpectrumAnalysisContext   = require "modules/spectrum_analysis_context"
local UTILS                     = require "modules/utils"

local MainWidget                = require "widgets/main"
local T                         = require "widgets/theme"
local HelpWindow                = require "widgets/help_window"

local ImGui                     = require "ext/imgui"
local ctx                       = ImGui.CreateContext(S.AppName)

-- The DSP module needs ImGui compiled EEL function features
DSP.setImGuiContext(ctx)

local spectrum_context              = nil
local processed_spectrum_context    = nil
local main_widget                   = nil

local want_refresh                  = true

local function build_spectrum_context()

    local params = {
        channel_mode          = S.instance_params.channel_mode,
        low_octava            = S.instance_params.low_octava,
        high_octava           = S.instance_params.high_octava,
        time_resolution_ms    = S.instance_params.time_resolution_ms,
        fft_size              = S.instance_params.fft_size
    }

    if S.instance_params.keep_time_selection and spectrum_context then
        -- Reuse precedent context params
        params.ts = spectrum_context.signal.start
        params.te = spectrum_context.signal.stop
    end

    if S.instance_params.keep_track_selection and spectrum_context then
        params.tracks = spectrum_context.tracks
    end

    -- Build the context but don't start the analysis.
    -- We want to draw the UI once first.
    return SpectrumAnalysisContext:new(params)
end

local function SL(ctx)
    ImGui.SameLine(ctx)
    ImGui.Dummy(ctx, 6, 2)
    ImGui.SameLine(ctx)
end

local function drawBottomSettings(ctx)

    ImGui.SetNextItemWidth(ctx, 80)
    local b, v = ImGui.SliderInt(ctx, "Time Res", S.instance_params.time_resolution_ms, 10, 50, "% d ms")
    if b then
        S.setSetting("TimeResolution", v)
        S.instance_params.time_resolution_ms = v
    end

    SL(ctx)

    ImGui.SetNextItemWidth(ctx, 60)
    local combo_items = { '1024', '2048', '4096', '8192', '16384' }
    if ImGui.BeginCombo(ctx, 'FFT', "" .. S.instance_params.fft_size) then
      for i,v in ipairs(combo_items) do
        local is_selected = (v == S.instance_params.fft_size)
        if ImGui.Selectable(ctx, combo_items[i], is_selected) then
            S.instance_params.fft_size = tonumber(v)
            S.setSetting("FFTSize", S.instance_params.fft_size)
        end
        if is_selected then
          ImGui.SetItemDefaultFocus(ctx)
        end
      end
      ImGui.EndCombo(ctx)
    end

    SL(ctx)

    ImGui.SetNextItemWidth(ctx, 60)
    local combo_items = { '512', '1024', '2048', '4096' }
    if ImGui.BeginCombo(ctx, 'RMS', "" .. S.instance_params.rms_window) then
      for i,v in ipairs(combo_items) do
        local is_selected = (v == S.instance_params.rms_window)
        if ImGui.Selectable(ctx, combo_items[i], is_selected) then
            S.instance_params.rms_window = tonumber(v)
            S.setSetting("RMSWindow", S.instance_params.rms_window)
        end
        if is_selected then
          ImGui.SetItemDefaultFocus(ctx)
        end
      end
      ImGui.EndCombo(ctx)
    end

    SL(ctx)

    local v, b = ImGui.Checkbox(ctx, "Keep time sel", S.instance_params.keep_time_selection)
    if v then
        S.instance_params.keep_time_selection = b
        S.setSetting("KeepTimeSelection", b)
    end

    SL(ctx)

    local v, b = ImGui.Checkbox(ctx, "Keep track sel", S.instance_params.keep_track_selection)
    if v then
        S.instance_params.keep_track_selection = b
        S.setSetting("KeepTrackSelection", b)
    end

    SL(ctx)

    if ImGui.Button(ctx, "Refresh") then
        want_refresh = true
    end

    ImGui.SameLine(ctx)
    local htext = "(?)"
    local htw = ImGui.CalcTextSize(ctx, htext)
    local ww  = ImGui.GetWindowWidth(ctx)

    ImGui.SetCursorPosX(ctx, ww - htw - 5)
    ImGui.Text(ctx, htext)

    if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Left) then
        local cx, cy        = ImGui.GetWindowPos(ctx)
        HelpWindow.open(cx,cy)
    end

    if ImGui.IsItemHovered(ctx) and UTILS.isMouseStalled(1.0) then
        ImGui.SetTooltip(ctx, "Click to open help")
    end
end

local function loop()

    -- Ensure main widget exists
    if not main_widget then
        main_widget = MainWidget:new()
        main_widget:setDbBounds(S.instance_params.dbmin, S.instance_params.dbmax)
        main_widget:setRMSDbBounds(S.instance_params.rms_dbmin, S.instance_params.rms_dbmax)
        main_widget:setLRBalance(S.instance_params.lr_balance)
    end

    -- Recalculate spectrum context if asked
    if want_refresh then
        processed_spectrum_context  = build_spectrum_context()
        want_refresh                = false
    end

    -- Process existing unfinished context before
    if processed_spectrum_context then
        if not processed_spectrum_context.analysis_finished then
            -- Continue analysis
            processed_spectrum_context:analyze()
        else
            if processed_spectrum_context.error then
                reaper.MB(processed_spectrum_context.error, "Oops",  0)
                processed_spectrum_context = nil
                if not spectrum_context then
                    return
                end
            else
                -- Hot swap.
                spectrum_context            = processed_spectrum_context
                processed_spectrum_context  = nil
                main_widget:setSpectrumContext(spectrum_context)
            end
        end
    end

    ImGui.SetNextWindowSizeConstraints(ctx, 800, 600, math.huge, math.huge)
    local visible, open = ImGui.Begin(ctx, S.AppName .. ' v' .. Version .. " (" .. S.instance_params.channel_mode .. ")##Spectracular_main", true)
    if visible then
        UTILS.mouseStallUpdate(ctx)

        local canvas_p0_x, canvas_p0_y = ImGui.GetCursorScreenPos(ctx)      -- DrawList API uses screen coordinates!
        local canvas_sz_w, canvas_sz_h = ImGui.GetContentRegionAvail(ctx)   -- Resize canvas to what's available

        --if spectrum_context then

            -- Keep room for bottom widgets (30 pixels)
            canvas_sz_h = canvas_sz_h - 30

            main_widget:setCanvas(canvas_p0_x, canvas_p0_y, canvas_sz_w, canvas_sz_h)

            if spectrum_context then
                main_widget:draw(ctx)
            end

            -- Position ImGui's cursor as the top left corner, and add a fake invisible button in place
            -- Of our whole stuff.
            ImGui.SetCursorScreenPos(ctx, canvas_p0_x, canvas_p0_y)
            if ImGui.InvisibleButton(ctx, 'spct_invisible', canvas_sz_w, canvas_sz_h + 4) then
                -- Add an invisible button to drop all click events.
            end
        --end

        if not processed_spectrum_context then
            drawBottomSettings(ctx)
        else
            -- When processing, we want the progress bar at the top
            local pp, pt = processed_spectrum_context:getProgress()

            local col = UTILS.colLerp(T.SLICE_CURVE_L, T.SLICE_CURVE_R, pp)

            ImGui.PushStyleColor(ctx, ImGui.Col_PlotHistogram, col)
            ImGui.PushStyleColor(ctx, ImGui.Col_PlotHistogramHovered, col)
            ImGui.ProgressBar(ctx, pp, canvas_sz_w, 16, pt)
            ImGui.PopStyleColor(ctx, 2)
        end

        ImGui.End(ctx)
    end

    HelpWindow.drawIfOpen()

    if open then
        reaper.defer(loop)
    end
end

local function run(args)
    local monorx    = "mono.lua$"
    local s, e      = string.find(args.action, monorx)
    if s then
        S.instance_params.channel_mode = "mono"
    end

    reaper.defer(loop)
end

return {
    run = run
}
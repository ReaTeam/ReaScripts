-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local Version                   = '0.3.0'

local S                         = require "modules/settings"
local DSP                       = require "modules/dsp"
local UTILS                     = require "modules/utils"

local SpectrumAnalysisContext   = require "classes/spectrum_analysis_context"
local TakeWatcher               = require "classes/take_watcher"

local MainWidget                = require "widgets/main"
local T                         = require "widgets/theme"
local HelpWindow                = require "widgets/help_window"

local ImGui                     = require "ext/imgui"
local ctx                       = ImGui.CreateContext(S.AppName)
local Arial                     = ImGui.CreateFont("Arial", ImGui.FontFlags_None)

-- The DSP module needs ImGui compiled EEL function features
DSP.setImGuiContext(ctx)

local spectrum_context              = nil
local processed_spectrum_context    = nil
local main_widget                   = nil
local splash                        = nil
local take_watcher                  = nil
local last_changed_at               = nil

local want_refresh                  = true

local function build_spectrum_context()

    local params = {
        channel_mode          = S.instance_params.channel_mode,
        low_octava            = S.instance_params.low_octava,
        high_octava           = S.instance_params.high_octava,
        time_resolution_ms    = S.instance_params.time_resolution_ms,
        fft_size              = S.instance_params.fft_size,
        rms_window            = S.instance_params.rms_window,
        zero_padding_percent  = S.instance_params.zero_padding_percent
    }

    if S.instance_params.keep_time_selection and spectrum_context then
        -- Reuse precedent context params
        params.ts = spectrum_context.signal.start
        params.te = spectrum_context.signal.stop
    end

    if S.instance_params.keep_track_selection and spectrum_context then
        -- Pass last context tracks to new analysis context (else it is deduced from the current selection)
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

local function TT(ctx, text)
    if ImGui.IsItemHovered(ctx) and UTILS.isMouseStalled(0.5) then
        ImGui.SetTooltip(ctx, text)
    end
end

local function loadSplash(ctx, action)
    local folder_path = action:match[[^@?(.*[\/])[^\/]-$]]

    splash = ImGui.CreateImage(folder_path .. "talagan_Spectracular/images/spectracular.png")
    ImGui.Attach(ctx, splash)
end

local function timeResolutionWidget(ctx)
    ImGui.SetNextItemWidth(ctx, 80)
    local b, v = ImGui.SliderInt(ctx, "Time Res", S.instance_params.time_resolution_ms, 10, 50, "%d ms")
    if b then
        S.setSetting("TimeResolution", v)
        S.instance_params.time_resolution_ms = v
    end
    TT(ctx, "Time resolution : interval of time between two FFT analysis (Default : 15ms).\n\z\n\z
             This is the horizontal resolution for the spectograph bitmap, and the extracted time profiles.")

    if ImGui.IsItemHovered(ctx) and ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Right) then
        S.resetSetting("TimeResolution")
        S.instance_params.time_resolution_ms = S.getSetting("TimeResolution")
    end
end

local function FFTWidget(ctx)
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
    TT(ctx, "FFT Window Size (Default : 8192 samples, Right click to reset)\n\z
             \n\z
             Chosing a big window size will allow to perform the analysis on a larger number of samples.\n\z
             This will give a better accuracy in distinguishing involved frequencies, especially in the low range,\n\z
             because FFTs have a linear resolution in frequencies but musical notes belong to a logarithmic frequency scale.\n\z
             But the drawback is that a bigger window 'blurs' the analysis in time\n\z
             (because FFT is a global operation performed on the whole window)\n\z
             A good compromise is 8192 samples.\n\z
             \n\z
             Note : a Hann window is applied to the full sample window to enhance the analysis.")

    if ImGui.IsItemHovered(ctx) and ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Right) then
        S.resetSetting("FFTSize")
        S.instance_params.fft_size = S.getSetting("FFTSize")
    end
end

local function zeroPaddingWidget(ctx)
    ImGui.SetNextItemWidth(ctx, 60)
    local b, v = ImGui.SliderInt(ctx, "ZP", S.instance_params.zero_padding_percent, 0, 90, "%d %%")
    if b then
        S.setSetting("ZeroPaddingPercent", v)
        S.instance_params.zero_padding_percent = v
    end
    TT(ctx, "Zero padding, in percent of the sample window (Default : 0%, Right click to reset).\n\z
             \z\z
             Zero padding is a technique that allows to get more precision in the frequency identification by the FFT.\n\z
             The idea is to use a smaller number of samples to avoid too much signal averaging, while still having a big\n\z
             sample window to get frequency precision.\n\z
             Using zero-padding will generally give you a better time accuracy in the spectrograph, but you will lose precision\n\z
             on the frequency analysis (in other words : what you'll gain horizontally will be lost vertically)")

    if ImGui.IsItemHovered(ctx) and ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Right) then
        S.resetSetting("ZeroPaddingPercent")
        S.instance_params.zero_padding_percent = S.getSetting("ZeroPaddingPercent")
    end
end

local function RMSWidget(ctx)
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
    TT(ctx, "Size of the RMS Window (Default : 1024 samples, Right click to reset)\n\z\n\z
             This is the number of samples of the window used to calculate each point of the energy curve.")

    if ImGui.IsItemHovered(ctx) and ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Right) then
        S.resetSetting("RMSWindow")
        S.instance_params.rms_window = S.getSetting("RMSWindow")
    end
end

local function refreshOptionsWidgets(ctx)
    local v, b = ImGui.Checkbox(ctx, "Keep time sel", S.instance_params.keep_time_selection)
    if v then
        S.instance_params.keep_time_selection = b
        S.setSetting("KeepTimeSelection", b)
    end
    TT(ctx, "When refreshing, keep the original time selection even if it's changed in REAPER")

    SL(ctx)

    local v, b = ImGui.Checkbox(ctx, "Keep track sel", S.instance_params.keep_track_selection)
    if v then
        S.instance_params.keep_track_selection = b
        S.setSetting("KeepTrackSelection", b)
    end
    TT(ctx, "When refreshing, keep the original track selection even if it's changed in REAPER")

    SL(ctx)

    local v, b = ImGui.Checkbox(ctx, "Auto refresh", S.instance_params.auto_refresh)
    if v then
        S.instance_params.auto_refresh = b
        S.setSetting("AutoRefresh", b)
    end
    TT(ctx, "If this option is on, this Spectracular window will watch for changes\n\z
             happening in the currently edited MIDI take and auto-refresh.")
end

local function drawBottomSettings(ctx)

    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 2, 2)
    ImGui.BeginGroup(ctx)

    ImGui.AlignTextToFramePadding(ctx)
    ImGui.TextColored(ctx, 0xCC88FFFF, "Analysis params")
    SL(ctx)
    timeResolutionWidget(ctx)
    SL(ctx)
    FFTWidget(ctx)
    SL(ctx)
    zeroPaddingWidget(ctx)
    SL(ctx)
    RMSWidget(ctx)

    ImGui.AlignTextToFramePadding(ctx)
    ImGui.TextColored(ctx, 0xCC88FFFF, "Refresh params ")
    SL(ctx)
    refreshOptionsWidgets(ctx)
    ImGui.EndGroup(ctx)

    SL(ctx)
    ImGui.Dummy(ctx, 20, 1)
    SL(ctx)

    ImGui.BeginGroup(ctx)
    if ImGui.Button(ctx, "Refresh") then
        want_refresh = true
    end

  --  SL(ctx)

    local htext = "(?)"
--    local htw = ImGui.CalcTextSize(ctx, htext)
--    local ww  = ImGui.GetWindowWidth(ctx)

   -- ImGui.SetCursorPosX(ctx, ww - htw - 5)
    ImGui.AlignTextToFramePadding(ctx)
    ImGui.Text(ctx, htext)

    if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Left) then
        local cx, cy        = ImGui.GetWindowPos(ctx)
        HelpWindow.open(cx,cy)
    end

    if ImGui.IsItemHovered(ctx) and UTILS.isMouseStalled(0.5) then
        ImGui.SetTooltip(ctx, "Click to open help")
    end
    ImGui.EndGroup(ctx)
    ImGui.PopStyleVar(ctx)
end

local BOTTOM_PARAM_HEIGHT = 50

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
        want_refresh                = false
        processed_spectrum_context  = build_spectrum_context()
        last_changed_at             = nil
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

    ImGui.PushFont(ctx, Arial, 12)
    ImGui.SetNextWindowSizeConstraints(ctx, 900, 600, math.huge, math.huge)
    local visible, open = ImGui.Begin(ctx, S.AppName .. ' v' .. Version .. " (" .. S.instance_params.channel_mode .. ")##Spectracular_main", true)
    if visible then
        UTILS.mouseStallUpdate(ctx)

        local canvas_p0_x, canvas_p0_y = ImGui.GetCursorScreenPos(ctx)      -- DrawList API uses screen coordinates!
        local canvas_sz_w, canvas_sz_h = ImGui.GetContentRegionAvail(ctx)   -- Resize canvas to what's available

        -- Hotfixes for windows + DPI scaling which may lead to float values
        canvas_p0_x = math.floor(canvas_p0_x)
        canvas_p0_y = math.floor(canvas_p0_y)
        canvas_sz_w = math.floor(canvas_sz_w)
        canvas_sz_h = math.floor(canvas_sz_h)

        -- Keep room for bottom widgets (30 pixels per row)
        canvas_sz_h = canvas_sz_h - ImGui.GetFrameHeightWithSpacing(ctx) * 2 - 8

        main_widget:setCanvas(canvas_p0_x, canvas_p0_y, canvas_sz_w, canvas_sz_h)

        if spectrum_context then
            main_widget:draw(ctx)
        else
            if splash then
                local iw, ih = ImGui.Image_GetSize(splash)

                local ratio = iw * 1.0/ih

                local fw = canvas_sz_w * 0.8
                local fh = fw / ratio

                if fh > canvas_sz_h then
                    fh = canvas_sz_h
                    fw = fh * ratio
                end

                --local fw = iw
                --local fh = ih

                local cx = canvas_p0_x + math.floor(canvas_sz_w/2 - fw/2)
                local cy = canvas_p0_y + math.floor(canvas_sz_h/2 - fh/2)
                ImGui.SetCursorScreenPos(ctx, cx, cy)
                ImGui.Image(ctx, splash, fw, fh, 0, 0, 1, 1)
            end
        end

        -- Position ImGui's cursor as the top left corner, and add a fake invisible button in place
        -- Of our whole stuff.
        ImGui.SetCursorScreenPos(ctx, canvas_p0_x, canvas_p0_y)
        if ImGui.InvisibleButton(ctx, 'spct_invisible', canvas_sz_w, canvas_sz_h + 4) then
            -- Add an invisible button to drop all click events.
        end

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

    local me = reaper.MIDIEditor_GetActive()
    if me then
        local take          = reaper.MIDIEditor_GetTake(me)
        local watched_take  = take_watcher and take_watcher.take

        if take ~= watched_take then
            take_watcher = nil
            if take then
                take_watcher = TakeWatcher:new(take)
            end
        end
    end

    if S.instance_params.auto_refresh then
        local now = reaper.time_precise()
        if take_watcher and take_watcher:hasChanged() then
            last_changed_at = now
        end

        local mouse_flags = reaper.JS_Mouse_GetState( (1 << 0) | (1 << 1) | (1 << 6) )

        -- Anti bounce
        if (last_changed_at ~= nil) and (now - last_changed_at > 0.7) and (mouse_flags == 0) then
            want_refresh = true
        end
    end

    if open then
        reaper.defer(loop)
    end
    ImGui.PopFont(ctx)
end

local function run(args)
    local monorx    = "mono.lua$"

    local s, e      = string.find(args.action, monorx)
    if s then
        S.instance_params.channel_mode = "mono"
    end

    loadSplash(ctx, args.action)

    reaper.defer(loop)
end

return {
    run = run
}

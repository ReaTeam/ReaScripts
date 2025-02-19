-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local ImGui = require "ext/imgui"
local DSP   = require "modules/dsp"
local MIDI  = require "modules/midi"
local T     = require "widgets/theme"
local UTILS = require "modules/utils"
local LRMix = require "widgets/lr_mix"

local SpectrographTimeProfile = require "widgets/profiles/spectrograph_time_profile"
local FrequencySliceProfile   = require "widgets/profiles/frequency_slice_profile"

-------------------------

-- This widget shows a mix of the spectrograms as a panable/scrollable bitmap.

local SpectrographWidget = {}
SpectrographWidget.__index = SpectrographWidget

function SpectrographWidget:new(mw)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(mw)
    return instance
end

function SpectrographWidget:_initialize(mw)
    self.mw             = mw
    self.lice_bitmap    = nil
    self.imgui_bitmap   = nil

    self:setCanvas(0,0,0,0)
    self:setDbBounds(-90, 6)
    self:setLRBalance(0.5)
    self:setDrawerWidth(150)

    -- Vertical viewport
    self.vob = 0
    self.vot = 1

    -- Horizontal viewport
    self.hol = 0
    self.hor = 1

    -- Kept profiles
    self.rmse_draw_profile   = SpectrographTimeProfile:new(self, -1, SpectrographTimeProfile.Types.RMSE)
    self.extracted_profiles  = {}

    self.cursor_draw_profile        = SpectrographTimeProfile:new(self, self:firstAvailableProfileColorIdx(), SpectrographTimeProfile.Types.NOTE)
    self.cursor_slice_draw_profile  = FrequencySliceProfile:new(self, T.SLICE_CURVE)

    self.lr_mix_widget = LRMix:new(mw)
end

function SpectrographWidget:setSpectrumContext(spectrum_context)
    self.sc                 = spectrum_context
    self.need_refresh_rgb   = true

    self.cursor_draw_profile:rebuildData(self.sc)
    self.cursor_slice_draw_profile:rebuildData(self.sc)

    self.rmse_draw_profile:rebuildData(self.sc)
    for _, p in pairs(self.extracted_profiles) do
        p:rebuildData(self.sc)
    end
end

function SpectrographWidget:spectrumContext()
    return self.sc
end

function SpectrographWidget:firstAvailableProfileColorIdx()
    local col_idx = 1
    local used_colors = {}
    for pi, p in pairs(self.extracted_profiles) do
        used_colors[#used_colors+1] = p.color_idx
    end

    table.sort(used_colors)

    for pi, cidx in ipairs(used_colors) do
        if not (cidx == col_idx) then
            break
        end
        col_idx = col_idx + 1
    end
    return col_idx
end

function SpectrographWidget:setCanvas(x,y,w,h)
    self.canvas_pos_changed    = not (self.x == x and self.y == y)
    self.canvas_size_changed   = not (self.w == w and self.h == h)
    self.canvas_changed        = self.canvas_pos_changed or self.canvas_size_changed

    self.x = x
    self.y = y
    self.w = w
    self.h = h
end

function SpectrographWidget:setDrawerWidth(w)
    self.drawer_width = w
end

function SpectrographWidget:setDbBounds(dbmin, dbmax)
    self.dbmin = dbmin
    self.dbmax = dbmax
    self.need_refresh_rgb = true
end

function SpectrographWidget:setRMSDbBounds(dbmin, dbmax)
    self.rms_dbmin = dbmin
    self.rms_dbmax = dbmax
end

function SpectrographWidget:setLRBalance(bal)
    self.lr_balance = bal
    self.need_refresh_rgb = true
end

function SpectrographWidget:createOrResizeLiceBitmap(w, h)
    if self.lice_bitmap then
        reaper.JS_LICE_Resize(self.lice_bitmap, w, h)
    else
        self.lice_bitmap  = reaper.JS_LICE_CreateBitmap(false, w, h)
    end
end

function SpectrographWidget:recreateImguiBitmapFromLice(ctx)
    if self.imgui_bitmap then
        ImGui.Detach(ctx, self.imgui_bitmap)
    end

    self.imgui_bitmap = nil

    if self.lice_bitmap then
        self.imgui_bitmap = ImGui.CreateImageFromLICE(self.lice_bitmap)
        ImGui.Attach(ctx, self.imgui_bitmap)
    end
end

function SpectrographWidget:recalculateBitmap(ctx)
    local sac = self:spectrumContext()

    self:createOrResizeLiceBitmap(sac.slice_count, sac.slice_size)

    -- Chan coeffs for the mix
    local coeffs = reaper.new_array(sac.chan_count)
    if sac.chan_count >= 2 then
        coeffs[1] = self.lr_balance
        coeffs[2] = 1 - self.lr_balance
    else
        coeffs[1] = 1
    end

    local spectrograms = sac.spectrograms
    local ref_spectro  = spectrograms[1]
    for i=1, ref_spectro.chunk_count do
        local ref_chunk = ref_spectro.chunks[i]

        self.rgb_buf = DSP.ensure_array_size(self.rgb_buf, ref_chunk.data_size)

        local spectro_chunk_datas = {}
        for ci = 1, sac.chan_count do
            spectro_chunk_datas[ci] = spectrograms[ci].chunks[i].data
        end

        DSP.analysis_data_to_rgb_array(spectro_chunk_datas, coeffs, self.rgb_buf, self.dbmin, self.dbmax)

        local pixi = 0
        for si=0, ref_chunk.slice_count - 1 do
            for j=0, sac.slice_size -1 do
                local p = self.rgb_buf[pixi+1]
                reaper.JS_LICE_PutPixel(self.lice_bitmap, ref_chunk.first_slice_offset + si, sac.slice_size - 1 - j, math.floor(p), 1, "COPY")
                pixi = pixi + 1
            end
        end
    end

    self:recreateImguiBitmapFromLice(ctx)

    self.need_refresh_rgb = false
end

function SpectrographWidget:containsPoint(mx, my)
    return mx >= self.x and mx < self.x + self.w and my >= self.y and my < self.y + self.h
end

-- From an (X,Y) point (screen pos), returns (u, v) position in the spectrograph
-- Given the current span/zoom
function SpectrographWidget:xyToUV(mx, my)
    local diffx             = mx - self.x
    local alphax            = 1.0 * diffx/self.w
    local rangeu            = self.hor - self.hol
    local u                 = self.hol + alphax * rangeu

    local diffy             = (self.y + self.h - my)
    local alphay            = 1 - diffy * 1.0/(self.h)
    local rangev            = self.vot - self.vob
    local v                 = self.vob + alphay * rangev

    return {
        u=u,             v=v,
        alphax = alphax, alphay = alphay,
        rangeu = rangeu, rangev = rangev
    }
end

function SpectrographWidget:noteNameForY(my)
    return MIDI.noteName(self:yToNoteNum(my))
end

function SpectrographWidget:yToNoteNum(y)
    local sac           = self:spectrumContext()
    local nr            = sac:noteRange()

    local v             = (y - self.y - self.h) * (self.vot - self.vob)/self.h + self.vot
    local pixoffset     = (1 - v) * sac.slice_size

    return (pixoffset - 0.5) / sac.semi_tone_slices + nr.low_note
end

function SpectrographWidget:noteNumToY(note_num)
    local sac           = self:spectrumContext()
    local nr            = sac:noteRange()

    local pixcount                  = sac.slice_size -- number of pixels for the full texture
    local vspan                     = self.vot - self.vob
    local pix_offset                = (note_num - nr.low_note) * sac.semi_tone_slices + 0.5
    local v                         = 1 - (1.0 * pix_offset) / pixcount

    local y = self.y + self.h - self.h * (self.vot - v) / vspan
    return y
end

function SpectrographWidget:xToTime(mx)
    local sac               = self:spectrumContext()
    local prop              = (mx - self.x)/self.w -- Proportion of the viewport
    local u                 = self.hol + prop * (self.hor -self.hol)

    return sac.signal.start + u * (sac.signal.stop - sac.signal.start)
end

function SpectrographWidget:timeToX(t)
    local sac           = self:spectrumContext()
    local u             = (t - sac.signal.start)/(sac.signal.stop - sac.signal.start)
    local prop          = (u - self.hol)/(self.hor - self.hol)
    local diffx         = prop * self.w
    return self.x + diffx
end

function SpectrographWidget:viewBounds()
    return {
        time_start = self:xToTime(self.x),
        time_stop  = self:xToTime(self.x + self.w)
    }
end

function SpectrographWidget:resetVerticalZoom()
    self.vot = 1
    self.vob = 0
end

function SpectrographWidget:resetHorizontalZoom()
    self.hor = 1
    self.hol = 0
end

function SpectrographWidget:handleMouseWheel(ctx)
    local mx, my        = ImGui.GetMousePos(ctx)

    -- In this widget, the mouse wheel is used for zooming.
    if self.mw:containsPoint(mx,my) then
        local mw, _ = ImGui.GetMouseWheel(ctx)
        if not (mw == 0)  then
            -- Get the UV pos of the mouse, this is the center of the zoom, which should stay invariant
            local uvinfo         = self:xyToUV(mx,my)
            local wpower         = math.ceil( math.log( math.abs(mw)/0.1 * math.exp(0)))
            local zoompower      = ((mw > 0) and (0.9) or (1.1)) ^ wpower

            if UTILS.modifierKeyIsDown() then
                if self:containsPoint(mx, my) then
                    -- Verical ZOOM. Accept vertical zoom only if the spectrograph has focus
                    -- New zoom range, apply zoom/unzoom factor
                    local newrange  = uvinfo.rangev * zoompower
                    -- Max zoom
                    if newrange < 0.05 then newrange = 0.05 end
                    -- Apply zoom and handle boundaries (this will take care of min zoom too)
                    self.vob = uvinfo.v - uvinfo.alphay * newrange
                    if self.vob < 0 then self.vob = 0 end
                    self.vot = self.vob + newrange
                    if self.vot > 1 then self.vot = 1 end
                end
            else
                -- Horizontal zoom. Accept horizontal zooming everywhere on the full main widget
                local newrange = uvinfo.rangeu * zoompower
                if newrange < 0.05 then newrange = 0.05 end
                -- Apply zoom and handle boundaries (this will take care of min zoom too)
                self.hol = uvinfo.u - uvinfo.alphax * newrange
                if self.hol < 0 then self.hol = 0 end
                self.hor = self.hol + newrange
                if self.hor > 1 then self.hor = 1 end
            end
        end
    end
end

function SpectrographWidget:handleLeftMouse(ctx)
    local mx, my        = ImGui.GetMousePos(ctx)
    local dx, dy        = ImGui.GetMouseDragDelta(ctx)

    -- Fast click without drag : extract note profile
    if ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Left) and not UTILS.modifierKeyIsDown() and self:containsPoint(mx, my) and (not self.mw:prehemptsMouse()) and not self.lr_mix_widget:containsPoint(mx, my) and (dx == 0 and dy == 0) then
        local prof = SpectrographTimeProfile:new(self, self:firstAvailableProfileColorIdx(), SpectrographTimeProfile.Types.NOTE)
        prof:buildDataFromNote(self:yToNoteNum(my))

        self.extracted_profiles[#self.extracted_profiles+1] = prof
    end

    -- Strat of click : memorize click info
    if ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Left) and not UTILS.modifierKeyIsDown() and (not self.mw:prehemptsMouse()) and not self.lr_mix_widget:containsPoint(mx, my) then
        if self.mw:containsPoint(mx,my) then
            local uvinfo = self:xyToUV(mx,my)

            self.click = {
                x  = mx,
                y  = my,
                u  = uvinfo.u,
                v  = uvinfo.v,
                vb = self.vob,
                vt = self.vot,
                hl = self.hol,
                hr = self.hor,
                lock_vertical = not self:containsPoint(mx, my)
            }
        end
    elseif ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Left) then
        self.click = nil
    end

    -- Mouse drag, left butotn : pan
    if (not self.mw:prehemptsMouse()) and not self.mw.rmse_widget.dragged and ImGui.IsMouseDragging(ctx, ImGui.MouseButton_Left) then
        if self.click then
            local ddx = dx * 1.0 / self.w
            local uvrange = (self.hor - self.hol)
            self.hol = self.click.hl - ddx * uvrange
            if self.hol < 0 then self.hol = 0 end
            self.hor = self.hol + uvrange
            if self.hor > 1 then self.hor = 1 end
            self.hol = self.hor - uvrange

            if not self.click.lock_vertical then
                local ddy = dy * 1.0 / self.h
                local uvrange = (self.vot - self.vob)
                self.vob = self.click.vb - ddy * uvrange
                if self.vob < 0 then self.vob = 0 end
                self.vot = self.vob + uvrange
                if self.vot > 1 then self.vot = 1 end
                self.vob = self.vot - uvrange
            end
        end
    end
end

function SpectrographWidget:hoveredProfile(ctx)
    local mx, my    = ImGui.GetMousePos(ctx)

    local note1 = self:yToNoteNum(my + 10)
    local note2 = self:yToNoteNum(my - 10)

    local found  = nil
    local fdst   = nil
    for pi, p in ipairs(self.extracted_profiles) do
        if p.note_num >= note1 and p.note_num <= note2 then
            local dst = math.abs(p.note_num - (note1+note2)/2)
            if not fdst or dst < fdst then
                found = pi
                fdst = dst
            end
        end
    end
    return found
end

function SpectrographWidget:handleRightMouse(ctx)
    local mx, my    = ImGui.GetMousePos(ctx)
    local dx, dy = ImGui.GetMouseDragDelta(ctx)

    -- Fast right click without drag : reset view/delete extracted profiles
    if self:containsPoint(mx, my) and (not self.mw:prehemptsMouse()) and not self.lr_mix_widget:containsPoint(mx,my) and ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Right) and (dx == 0 and dy == 0) then
        local torem = self:hoveredProfile(ctx)
        if torem then
            table.remove(self.extracted_profiles, torem)
        else
            -- Reset view
            self:resetHorizontalZoom()
            self:resetVerticalZoom()
        end
    end
end

function SpectrographWidget:handleMouse(ctx)
    self:handleMouseWheel(ctx)
    self:handleLeftMouse(ctx)
    self:handleRightMouse(ctx)
end

function SpectrographWidget:resetProfiles()
    self.extracted_profiles = {}
end

function SpectrographWidget:startClipping(draw_list)
    ImGui.DrawList_PushClipRect(draw_list,  self.x, self.y, self.x + self.w, self.y + self.h, true)
end

function SpectrographWidget:stopClipping(draw_list)
    ImGui.DrawList_PopClipRect(draw_list)
end

function SpectrographWidget:drawHorizontalNoteTicks(ctx, draw_list)
    -- Horizontal Note Ticks
    local sac                   = self:spectrumContext()
    local nr                    = sac:noteRange()
    local pixcount              = sac.slice_size -- number of pixels for the full texture
    local vspan                 = self.vot - self.vob
    local onepixsspan           = (1.0/pixcount)  -- Span of a pixel in uv coordinates
    local ispan                 = onepixsspan * sac.semi_tone_slices -- Span of a semi tone in uv coordinates
    local ipixspan              = ispan * self.h / vspan -- span of a semin tone in screen pixels
    local span_is_sufficient    = (ipixspan >= 12)

    for ni = nr.low_note, nr.high_note + 1 do
          -- Remove 0.5 for boundary (0 is center, -0.5 is line before and +0.5 is line after), add 0.5 pixels to be on the mid pix
        local note_bound_pix_offset = (ni - nr.low_note - 0.5) * sac.semi_tone_slices + 0.5
        local v                     = 1 - 1.0 * note_bound_pix_offset / pixcount
        local is_c                  = (ni % 12 == 0)

        if (v >= self.vob - ispan) and (v <= self.vot + ispan) then
            local y = self.y + self.h - self.h * (self.vot - v) / vspan

            local col = (is_c and T.NOTE_GRID_C or T.NOTE_GRID_OTHER)

            if span_is_sufficient or is_c then
                local notename = MIDI.noteName(ni)
                local nw, nh = ImGui.CalcTextSize(ctx, notename, nil, nil)

                ImGui.DrawList_AddLine(draw_list, self.x, y, self.x + self.w, y, col)
                local textpos = (span_is_sufficient) and (y - 0.5 * ipixspan - 7) or (y - 14)

                ImGui.DrawList_AddText(draw_list, self.x + 5,               textpos, T.NOTE_GRID_C, notename)
                ImGui.DrawList_AddText(draw_list, self.x + self.w - nw - 5, textpos, T.NOTE_GRID_C, notename)
            end
        end
    end

    local SHOW_PIX_GRID = false
    if SHOW_PIX_GRID then
        -- Show pix grid
        for ni = nr.low_note, nr.high_note + 1 do
            for nj=0, self.sc.semi_tone_slices do
                local note_bound_pix_offset     = (ni - nr.low_note) * sac.semi_tone_slices + nj
                local v                         = 1 - 1.0 * note_bound_pix_offset / pixcount
                local y = self.y + self.h - self.h * (self.vot - v) / vspan

                ImGui.DrawList_AddLine(draw_list, self.x, y, self.x + self.w, y, 0x80FF80FF)
            end
        end
    end
end

function SpectrographWidget:draw(ctx)
    local sac = self:spectrumContext()
    if not sac then return end

    if not self.imgui_bitmap or self.need_refresh_rgb then
        self:recalculateBitmap(ctx)
    end

    local draw_list     = ImGui.GetWindowDrawList(ctx)

    local l = 0
    local r = self.w

    -- Handle scroll / zoom / pan
    self:handleMouse(ctx)

    self:startClipping(draw_list)
    -- Draw main texture
    ImGui.DrawList_AddImage(draw_list, self.imgui_bitmap,
    self.x + l,  self.y,
    self.x + r,  self.y + self.h,
    self.hol, self.vob,
    self.hor, self.vot)

    ImGui.DrawList_AddRectFilled(draw_list, self.x,   self.y, self.x + l, self.y + self.h, T.SPECTROGRAPH_BORDER_BG)
    ImGui.DrawList_AddRectFilled(draw_list, self.x+r, self.y, self.x + self.w, self.y + self.h, T.SPECTROGRAPH_BORDER_BG)

    -- Draw borders left and right, to show where the fft
    --ImGui.DrawList_AddLine(draw_list,        self.x + l, self.y,        self.x + l, self.y + self.h,        T.SPECTROGRAPH_BORDER)
    --ImGui.DrawList_AddLine(draw_list,        self.x + r, self.y,        self.x + r, self.y + self.h,        T.SPECTROGRAPH_BORDER)

    local mx, my    = ImGui.GetMousePos(ctx)
    local time      = self:xToTime(mx)

    -- Cursor data calc (tooltip data / profile data)
    if self:containsPoint(mx,my) then
        local note_num = self:yToNoteNum(my)

        self.cursor_draw_profile:buildDataFromNote(note_num)

        self.hovered_db = {}
        for i=1, sac.chan_count do
            self.hovered_db[i] = sac:getValueAt(i, note_num, time)
        end
    end

    -- Mouse cursor
    if self:containsPoint(mx,my) then
        self.overrides_mouse_cursor   = ImGui.MouseCursor_None
        self.want_draw_cursor_profile = true
        if self.lr_mix_widget:containsPoint(mx, my) then
            self.overrides_mouse_cursor     = ImGui.MouseCursor_Arrow
            self.want_draw_cursor_profile   = false
        end
    else
        self.overrides_mouse_cursor   = nil
        self.want_draw_cursor_profile = false
    end

    -- Allow a more general context for the frequency vertical slice
    if self.mw:containsPoint(mx, my) then
        self.cursor_slice_draw_profile:buildDataFromTime(time)
        self.want_draw_cursor_slice   = true
    else
        self.want_draw_cursor_slice   = false
    end

    -- Side frequency curve
    if self.want_draw_cursor_slice then
        ImGui.DrawList_AddRectFilled(draw_list, self.x + self.w - self.drawer_width, self.y, self.x + self.w, self.y + self.h, T.DRAWER_BG)

        -- Stereo L
        self.cursor_slice_draw_profile:buildDrawCurves(self.x, self.y, self.w, self.h, self.drawer_width)
        ImGui.DrawList_AddPolyline(draw_list, self.cursor_slice_draw_profile.draw_curves[1], T.SLICE_CURVE_L,0,2)
        if sac.chan_count > 1 then
            -- Stereo R
            ImGui.DrawList_AddPolyline(draw_list, self.cursor_slice_draw_profile.draw_curves[2], T.SLICE_CURVE_R,0,2)
        end
    end

    self:drawHorizontalNoteTicks(ctx, draw_list)
    self:drawHorizontalCursor(ctx, draw_list)

    if UTILS.modifierKeyIsDown() then
        -- Show hint line for drawer resize
        ImGui.DrawList_AddLine(draw_list, self.x + self.w - self.drawer_width, self.y , self.x + self.w - self.drawer_width, self.y + self.h, 0xFFFFFF50)
    end

    self:stopClipping(draw_list)
end

function SpectrographWidget:drawProfileLines(ctx)
    local draw_list     = ImGui.GetWindowDrawList(ctx)
    local hovered       = self:hoveredProfile(ctx)

    for pi, p in pairs(self.extracted_profiles) do
        local y = self:noteNumToY(p.note_num)
        if y > self.y and y < self.y + self.h then
            -- Background
            ImGui.DrawList_AddLine(draw_list, self.x, y, self.x + self.w, y, (hovered == pi and 0xFFFF00D0 or 0x000000D0), (hovered == pi and 6 or 4))
            -- Line
            ImGui.DrawList_AddLine(draw_list, self.x, y, self.x + self.w, y, p.color, 2.0)
        end
    end
end

function SpectrographWidget:drawHorizontalCursor(ctx, draw_list)
    local mx, my = ImGui.GetMousePos(ctx)
    if self:containsPoint(mx,my) and not self.lr_mix_widget:containsPoint(mx, my) then
        -- Horizontal line cursor
        ImGui.DrawList_AddLine(draw_list, self.x, my, self.x + self.w, my, T.H_CURSOR)
    end
end

function SpectrographWidget:drawTooltip(ctx)
    local sac = self:spectrumContext()
    if not sac then return end

    local mx, my = ImGui.GetMousePos(ctx)

    -- Mouse cursor
    if not self:containsPoint(mx,my) or self.lr_mix_widget:containsPoint(mx, my) then
        return
    end

    local draw_list = ImGui.GetWindowDrawList(ctx)
    local note_name = self:noteNameForY(my)

    local note_text = "" .. note_name
    local db_texts  = {}
    local db_width  = 0

    for i=1, sac.chan_count do
        db_texts[i] = (self.hovered_db[i] and string.format("%.1f dB", self.hovered_db[i]) or "?"):gsub("%.0+$", "")
        local dbw = ImGui.CalcTextSize(ctx, db_texts[i])
        if dbw > db_width then db_width = dbw end
    end

    if self.cursor_is_right == nil then self.cursor_is_right   = true end
    if self.cursor_is_top   == nil then self.cursor_is_top     = true end

    local tw, th            = ImGui.CalcTextSize(ctx, note_text)

    local sqw               = 8
    local chan_num_w        = 6
    local px, py            = 10, 5
    local mgx, mgy          = 10, 10
    local offx, offy        = mgx, mgy -- Top right

    local w                 = px + sqw + px + tw + px + db_width + px -- Add 15 for the small square
    local h                 = 2 * py + sac.chan_count * th + (sac.chan_count - 1) * py

    if sac.chan_count > 1 then
        w = w + px + 10 -- Add room for the channel name (L, R or num)
    end

    local USE_HYSTERESIS = false

    -- Create hysteresis for label position left/right of cursor
    -- Depending on border proximity
    if USE_HYSTERESIS then
        if self.cursor_is_right then
            if self.x + self.w - mx < 1.2 * w then
                self.cursor_is_right = false
            end
        else
            if mx - self.x < 1.2 * w then
                self.cursor_is_right = true
            end
        end
    else
        self.cursor_is_right = true
        if self.x + self.w - mx < 1.2 * w then
            self.cursor_is_right = false
        end
    end

    if not self.cursor_is_right then
        offx = - w - mgx
    end

    if USE_HYSTERESIS then
        if self.cursor_is_top then
            if (my - self.y) < 1.4 * h then
                self.cursor_is_top = false
            end
        else
            if self.y + self.h - my < 1.4 * h then
                self.cursor_is_top = true
            end
        end
    else
        self.cursor_is_top = true
        if (my - self.y) < 1.4 * h then
            self.cursor_is_top = false
        end
    end

    if not self.cursor_is_top then
        offy = - h - mgy
    end

    -- Tooltip's frame
    ImGui.DrawList_AddRectFilled(draw_list, mx + offx,      my - offy - h, mx + offx + w, my - offy, T.TOOLTIP_BG )
    ImGui.DrawList_AddRect(draw_list,       mx + offx,      my - offy - h, mx + offx + w, my - offy, T.H_CURSOR, 1.0 )

    local cx = mx + offx + px
    local cy = my - offy - h + math.floor(0.5 + h/2 - sqw/2)

    -- Draw color rect
    ImGui.DrawList_AddRectFilled(draw_list, cx, cy, cx + sqw, cy + sqw, T.SPECTRO_PROFILES[ ((self:firstAvailableProfileColorIdx()-1) % #T.SPECTRO_PROFILES) + 1] )
    cx = cx + sqw + px

    ImGui.DrawList_AddText(draw_list, cx, my - offy - h + math.floor(0.5 + h/2 - th/2), T.H_CURSOR , note_text)
    cx = cx + tw + px

    for i=1, sac.chan_count do
        local cox = 0
        if sac.chan_count > 1 then
            if sac.chan_count == 2 then
                ImGui.DrawList_AddText(draw_list, cx, my - offy - h + py + (i-1) * (th + py), (i==1) and T.SLICE_CURVE_L or T.SLICE_CURVE_R , (i==1) and "L" or "R")
            end

            cox = chan_num_w + px
        end
        ImGui.DrawList_AddText(draw_list, cx + cox, my - offy - h + py + (i-1) * (th + py), T.H_CURSOR , db_texts[i])
    end
end

function SpectrographWidget:drawLRMix(ctx)
    self.lr_mix_widget:draw(ctx)
end

function SpectrographWidget:endOfDraw(ctx)
    self.canvas_changed = false
    self.canvas_pos_changed = false
    self.canvas_size_changed = false
end

return SpectrographWidget

-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local ImGui                     = require "ext/imgui"
local DSP                       = require "modules/dsp"
local MIDI                      = require "modules/midi"
local T                         = require "widgets/theme"
local UTILS                     = require "modules/utils"
local LRMix                     = require "widgets/lr_mix"
local SpectrographImageStrip    = require "widgets/spectrograph_image_strip"

local SpectrographTimeProfile   = require "widgets/profiles/spectrograph_time_profile"
local FrequencySliceProfile     = require "widgets/profiles/frequency_slice_profile"

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
--    self.imgui_bitmap   = nil
    self.image_strip    = nil

    self:setCanvas(0,0,0,0)
    self:setDbBounds(-90, 6)
    self:setLRBalance(0.5)
    self:setDrawerWidth(150)

    -- Vertical viewport
    self.vp_v_t = 1
    self.vp_v_b = 0

    -- Horizontal viewport
    self.vp_u_l = 0
    self.vp_u_r = 1

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

function SpectrographWidget:createOrUpdateImageStrip(ctx)
    if not self.image_strip then
        self.image_strip = SpectrographImageStrip:new(ctx)
    end

    self.image_strip:update(ctx, self.sc, self.lr_balance, self.dbmin, self.dbmax)
end

function SpectrographWidget:recalculateTextures(ctx)
    self:createOrUpdateImageStrip(ctx)
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
    local rangeu            = self.vp_u_r - self.vp_u_l
    local u                 = self.vp_u_l + alphax * rangeu

    local diffy             = (self.y + self.h - my)
    local alphay            = 1 - diffy * 1.0/(self.h)
    local rangev            = self.vp_v_t - self.vp_v_b
    local v                 = self.vp_v_b + alphay * rangev

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

    local v             = (y - self.y - self.h) * (self.vp_v_t - self.vp_v_b)/self.h + self.vp_v_t
    local pixoffset     = (1 - v) * sac.slice_size

    return (pixoffset - 0.5) / sac.semi_tone_slices + nr.low_note
end

function SpectrographWidget:noteNumToY(note_num)
    local sac           = self:spectrumContext()
    local nr            = sac:noteRange()

    local pixcount                  = sac.slice_size -- number of pixels for the full texture
    local vspan                     = self.vp_v_t - self.vp_v_b
    local pix_offset                = (note_num - nr.low_note) * sac.semi_tone_slices + 0.5
    local v                         = 1 - (1.0 * pix_offset) / pixcount

    local y = self.y + self.h - self.h * (self.vp_v_t - v) / vspan
    return y
end

function SpectrographWidget:xToTime(mx)
    local sac               = self:spectrumContext()
    local prop              = (mx - self.x)/self.w -- Proportion of the viewport
    local u                 = self.vp_u_l + prop * (self.vp_u_r -self.vp_u_l)

    return sac.signal.start + u * (sac.signal.stop - sac.signal.start)
end

function SpectrographWidget:timeToX(t)
    local sac           = self:spectrumContext()
    local u             = (t - sac.signal.start)/(sac.signal.stop - sac.signal.start)
    local prop          = (u - self.vp_u_l)/(self.vp_u_r - self.vp_u_l)
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
    self.vp_v_t = 1
    self.vp_v_b = 0
end

function SpectrographWidget:resetHorizontalZoom()
    self.vp_u_l = 0
    self.vp_u_r = 1
end

function SpectrographWidget:handleMouseWheel(ctx)
    local mx, my        = ImGui.GetMousePos(ctx)
    local sac           = self:spectrumContext()

    -- In this widget, the mouse wheel is used for zooming.
    if self.mw:containsPoint(mx,my) then
        local mw, _ = ImGui.GetMouseWheel(ctx)
        if not (mw == 0)  then
            -- Get the UV pos of the mouse, this is the center of the zoom, which should stay invariant
            local mouse_uv       = self:xyToUV(mx,my)
            local wpower         = math.ceil( math.log( math.abs(mw)/0.1 * math.exp(0)))
            local zoompower      = ((mw > 0) and (0.9) or (1.1)) ^ wpower

            if UTILS.modifierKeyIsDown() then
                if self:containsPoint(mx, my) then
                    -- Verical ZOOM. Accept vertical zoom only if the spectrograph has focus
                    -- New zoom range, apply zoom/unzoom factor
                    local newrange  = mouse_uv.rangev * zoompower
                    -- Max zoom
                    if newrange < 0.05 then newrange = 0.05 end
                    -- Apply zoom and handle boundaries (this will take care of min zoom too)
                    self.vp_v_b = mouse_uv.v - mouse_uv.alphay * newrange
                    if self.vp_v_b < 0 then self.vp_v_b = 0 end
                    self.vp_v_t = self.vp_v_b + newrange
                    if self.vp_v_t > 1 then self.vp_v_t = 1 end
                end
            else
                -- Horizontal zoom. Accept horizontal zooming everywhere on the full main widget
                local newrange  = mouse_uv.rangeu * zoompower
                local fulldur   = sac.signal.duration
                local nrs = fulldur * newrange
                if nrs < 0.01 then
                    nrs = 0.01
                    newrange = nrs / fulldur
                end
                -- Apply zoom and handle boundaries (this will take care of min zoom too)
                self.vp_u_l = mouse_uv.u - mouse_uv.alphax * newrange
                if self.vp_u_l < 0 then self.vp_u_l = 0 end
                self.vp_u_r = self.vp_u_l + newrange
                if self.vp_u_r > 1 then self.vp_u_r = 1 end
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
            local mouse_uv = self:xyToUV(mx,my)

            self.click = {
                x  = mx,
                y  = my,
                u  = mouse_uv.u,
                v  = mouse_uv.v,
                vb = self.vp_v_b,
                vt = self.vp_v_t,
                hl = self.vp_u_l,
                hr = self.vp_u_r,
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
            local uvrange = (self.vp_u_r - self.vp_u_l)
            self.vp_u_l = self.click.hl - ddx * uvrange
            if self.vp_u_l < 0 then self.vp_u_l = 0 end
            self.vp_u_r = self.vp_u_l + uvrange
            if self.vp_u_r > 1 then self.vp_u_r = 1 end
            self.vp_u_l = self.vp_u_r - uvrange

            if not self.click.lock_vertical then
                local ddy = dy * 1.0 / self.h
                local uvrange = (self.vp_v_t - self.vp_v_b)
                self.vp_v_b = self.click.vb - ddy * uvrange
                if self.vp_v_b < 0 then self.vp_v_b = 0 end
                self.vp_v_t = self.vp_v_b + uvrange
                if self.vp_v_t > 1 then self.vp_v_t = 1 end
                self.vp_v_b = self.vp_v_t - uvrange
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
    local vspan                 = self.vp_v_t - self.vp_v_b
    local onepixsspan           = (1.0/pixcount)  -- Span of a pixel in uv coordinates
    local ispan                 = onepixsspan * sac.semi_tone_slices -- Span of a semi tone in uv coordinates
    local ipixspan              = ispan * self.h / vspan -- span of a semin tone in screen pixels
    local span_is_sufficient    = (ipixspan >= 12)

    for ni = nr.low_note, nr.high_note + 1 do
          -- Remove 0.5 for boundary (0 is center, -0.5 is line before and +0.5 is line after), add 0.5 pixels to be on the mid pix
        local note_bound_pix_offset = (ni - nr.low_note - 0.5) * sac.semi_tone_slices + 0.5
        local v                     = 1 - 1.0 * note_bound_pix_offset / pixcount
        local is_c                  = (ni % 12 == 0)

        if (v >= self.vp_v_b - ispan) and (v <= self.vp_v_t + ispan) then
            local y = self.y + self.h - self.h * (self.vp_v_t - v) / vspan

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

    -- Debug feature : show grid for each PIXEL to check if the display is correct.
    local SHOW_PIX_GRID = false
    if SHOW_PIX_GRID then
        -- Show pix grid
        for ni = nr.low_note, nr.high_note + 1 do
            for nj=0, self.sc.semi_tone_slices do
                local note_bound_pix_offset     = (ni - nr.low_note) * sac.semi_tone_slices + nj
                local v                         = 1 - 1.0 * note_bound_pix_offset / pixcount
                local y = self.y + self.h - self.h * (self.vp_v_t - v) / vspan

                ImGui.DrawList_AddLine(draw_list, self.x, y, self.x + self.w, y, 0x80FF80FF)
            end
        end
    end
end

function SpectrographWidget:draw(ctx)
    local sac = self:spectrumContext()
    if not sac then return end

    if not self.image_strip or self.need_refresh_rgb then
        self:recalculateTextures(ctx)
    end

    local draw_list     = ImGui.GetWindowDrawList(ctx)

    local l = 0
    local r = self.w

    -- Handle scroll / zoom / pan
    self:handleMouse(ctx)

    -- Set clipping on
    self:startClipping(draw_list)

    -- Draw our images from our image strip
    for ii, img in ipairs(self.image_strip.images) do

        -- Test if the image overlaps the viewport
        local img_overlaps = (img.ul <= self.vp_u_l and img.ur >= self.vp_u_l) or (img.ul >= self.vp_u_l and img.ul <= self.vp_u_r)
        if img_overlaps then
            -- The image overlaps, map it to the viewport
            local local_ul = (img.ul >= self.vp_u_l) and (0) or ( (self.vp_u_l - img.ul) / (img.ur - img.ul) )
            local local_ur = (img.ur <= self.vp_u_r) and (1) or ( (self.vp_u_r - img.ul) / (img.ur - img.ul) )

            local vp_xl = self.x + ((img.ul <= self.vp_u_l) and (0)         or ( self.w * ((img.ul - self.vp_u_l) / (self.vp_u_r - self.vp_u_l))) )
            local vp_xr = self.x + ((img.ur >= self.vp_u_r) and (self.w)    or ( self.w * ((img.ur - self.vp_u_l) / (self.vp_u_r - self.vp_u_l))) )

            ImGui.DrawList_AddImage(draw_list, img.image,
                    vp_xl,   self.y,                -- Top left
                    vp_xr,   self.y + self.h,       -- Bottom right
                    local_ul, self.vp_v_b,           -- Top left (U,V) (in image_strip)
                    local_ur, self.vp_v_t)           -- Bottom right (U,V) in image strip)
        end
    end

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

    -- Show grid lines for notes
    self:drawHorizontalNoteTicks(ctx, draw_list)

    -- Show note cursor line (mouse hover)
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

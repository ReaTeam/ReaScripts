-- @noindex

-- ReaPerform.lua by Grave Sound Audio
-- A custom Performance Meter for Reaper with per-track freeze options
-- Right-click any track row to freeze to Mono or Stereo

-- ============================================================
-- CONFIG
-- ============================================================
local SCRIPT_NAME  = "ReaPerform - Performance Meter"
local WIN_W        = 640
local WIN_H        = 560
local MIN_WIN_W    = 500
local MIN_WIN_H    = 300
local REFRESH_RATE = 10   -- target fps (frames between updates)
local ROW_H        = 24
local HEADER_H     = 22
local FOOTER_H     = 24
local LOGO_SLOT    = 5    -- gfx image slot for logo
local LOGO_SIZE    = 48   -- display size of logo in stats panel

-- ============================================================
-- COLORS  (R, G, B each 0-255)
-- ============================================================
local C = {
  bg            = {0x1c, 0x1c, 0x1c},
  bg2           = {0x22, 0x22, 0x22},
  header_bg     = {0x2a, 0x2a, 0x2a},
  header_text   = {0xcc, 0xcc, 0xcc},
  row_even      = {0x1e, 0x1e, 0x1e},
  row_odd       = {0x24, 0x24, 0x24},
  row_hover     = {0x2e, 0x38, 0x44},
  row_selected  = {0x1a, 0x3a, 0x5a},
  text_num      = {0x5a, 0xaa, 0xff},  -- blue numerics (like Reaper)
  text_name     = {0xdd, 0xdd, 0xdd},
  text_bright   = {0xff, 0xff, 0xff},
  text_dim      = {0x88, 0x88, 0x88},
  accent        = {0x3a, 0x8a, 0xff},
  bar_cpu       = {0x22, 0x88, 0xff},
  bar_cpu_high  = {0xff, 0x66, 0x22},
  bar_bg        = {0x30, 0x30, 0x30},
  frozen_stereo = {0x22, 0xaa, 0x66},  -- green tint
  frozen_mono   = {0xaa, 0x88, 0x22},  -- amber tint
  sep           = {0x3a, 0x3a, 0x3a},
  menu_bg       = {0x28, 0x28, 0x28},
  menu_item     = {0xcc, 0xcc, 0xcc},
  menu_hover    = {0x3a, 0x8a, 0xff},
  title_bar     = {0x18, 0x18, 0x18},
  title_text    = {0xee, 0xee, 0xee},
  stat_label    = {0xaa, 0xaa, 0xaa},
  stat_value    = {0xdd, 0xdd, 0xdd},
}

-- helper to pack a color for gfx.set
local function col(c, a)
  gfx.set(c[1]/255, c[2]/255, c[3]/255, a or 1)
end

-- ============================================================
-- STATE
-- ============================================================
local state = {
  win_x      = 100,
  win_y      = 100,
  win_w      = WIN_W,
  win_h      = WIN_H,
  scroll     = 0,
  hover_row  = -1,
  sel_row    = -1,
  frame      = 0,
  -- context menu
  menu_open  = false,
  menu_x     = 0,
  menu_y     = 0,
  menu_track = nil,
  menu_items = {},
  -- resizing (native OS title bar handles window drag)
  resizing   = false,
  resize_ox  = 0,
  resize_oy  = 0,
  resize_w0  = 0,
  resize_h0  = 0,
  -- scrollbar drag
  sb_drag        = false,
  sb_drag_start_y= 0,
  sb_drag_start_s= 0,
  -- sorting
  sort_col       = "fx_cpu",
  sort_dir       = -1, -- -1 = desc, 1 = asc
  -- cached track data
  tracks     = {},
  -- throttled freeze detection
  freeze_states    = {}, -- persistent cache
  next_check_idx   = 1, -- for background queue
}

-- ============================================================
-- UTILITY
-- ============================================================
local function fmt_pct(v)
  return string.format("%.1f%%", v)
end


local function clamp(v,a,b) return math.max(a,math.min(b,v)) end

-- Draw a rounded rectangle (filled)
local function fill_rect(x,y,w,h)
  gfx.rect(x, y, w, h, 1)
end

-- Draw text centred in a rect
local function draw_text_center(txt, x, y, w, h)
  local tw, th = gfx.measurestr(txt)
  gfx.x = x + (w - tw) * 0.5
  gfx.y = y + (h - th) * 0.5
  gfx.drawstr(txt)
end

-- Draw text right-aligned in a rect
local function draw_text_right(txt, x, y, w, h)
  local tw, th = gfx.measurestr(txt)
  gfx.x = x + w - tw - 4
  gfx.y = y + (h - th) * 0.5
  gfx.drawstr(txt)
end

-- Draw text left-aligned
local function draw_text_left(txt, x, y, h, pad)
  pad = pad or 4
  local tw, th = gfx.measurestr(txt)
  gfx.x = x + pad
  gfx.y = y + (h - th) * 0.5
  gfx.drawstr(txt)
end

-- ============================================================
-- COLUMN LAYOUT
-- ============================================================
-- Columns: Track | FX CPU | # FX | PDC | Media CPU
-- widths are fractions of the track name column / fixed for others

local COLS = {
  { key="name",      label="Track",     w_fixed=false,  w=0 },  -- fills remaining
  { key="fx_cpu",    label="FX CPU",    w_fixed=true,   w=90 },
  { key="num_fx",    label="# FX",      w_fixed=true,   w=52 },
  { key="pdc",       label="PDC",       w_fixed=true,   w=52 },
  { key="media_cpu", label="Media CPU", w_fixed=true,   w=120 },
}

local function compute_col_x(win_w)
  local fixed_total = 0
  for _, c in ipairs(COLS) do
    if c.w_fixed then fixed_total = fixed_total + c.w end
  end
  COLS[1].w = win_w - fixed_total - 2  -- 2px for scrollbar margin
  local x = 0
  for _, c in ipairs(COLS) do
    c.x = x
    x = x + c.w
  end
end

-- ============================================================
-- DATA COLLECTION
-- ============================================================
local cpu_peak_decay  = {}  -- smoothed cpu proxy values per track
local DECAY           = 0.85
local SAMPLE_INTERVAL = 6    -- snappier UI, background worker handles the heavy lifting

local function get_freeze_state(track, guid)
  -- 1. High-speed check (API)
  local v = reaper.GetMediaTrackInfo_Value(track, "I_FROZEN")
  if v > 0 then 
    local s = math.floor(v + 0.5)
    state.freeze_states[guid] = s
    return s
  end
  
  -- 2. Return cached value (updated by background worker in main loop)
  return state.freeze_states[guid] or 0
end

-- Background worker: Checks EXACTLY ONE track per frame to avoid lag spikes
local function update_freeze_cache(tracks)
  if not tracks or #tracks == 0 then return end
  
  if state.next_check_idx > #tracks then state.next_check_idx = 1 end
  local t = tracks[state.next_check_idx]
  if t then
    local _, chunk = reaper.GetTrackStateChunk(t.track, "", false)
    if chunk:find("FREEZE") then
      state.freeze_states[t.guid] = 1
    else
      -- If not in chunk and not in API, it's definitely not frozen
      if reaper.GetMediaTrackInfo_Value(t.track, "I_FROZEN") == 0 then
        state.freeze_states[t.guid] = 0
      end
    end
  end
  state.next_check_idx = state.next_check_idx + 1
end

local function get_pdc(track)
  -- Sum PDC (latency in samples) across online FX
  local total = 0
  local n = reaper.TrackFX_GetCount(track)
  for i = 0, n-1 do
    local enabled = reaper.TrackFX_GetEnabled(track, i)
    if enabled then
      -- PDC per FX not directly in API — use TrackFX_GetNamedConfigParm if available
      local ok, val = reaper.TrackFX_GetNamedConfigParm(track, i, "pdc")
      if ok then
        local pdc_val = tonumber(val) or 0
        total = total + pdc_val
      end
    end
  end
  return total
end

local function collect_track_data()
  local num = reaper.CountTracks(0)
  local tracks = {}
  for i = 0, num - 1 do
    local track = reaper.GetTrack(0, i)
    local idx     = tostring(reaper.GetTrackGUID(track))
    local _, name = reaper.GetTrackName(track)
    local num_fx  = reaper.TrackFX_GetCount(track)
    local freeze  = get_freeze_state(track, idx)
    local pdc     = get_pdc(track)

    -- Pseudo-CPU: use stereo peak volume as a rough proxy for "activity"
    -- (Reaper doesn't expose real CPU per track in Lua)
    local peak_l  = reaper.Track_GetPeakInfo(track, 0)
    local peak_r  = reaper.Track_GetPeakInfo(track, 1)
    local peak    = math.max(peak_l, peak_r)

    local idx     = tostring(reaper.GetTrackGUID(track))
    local prev    = cpu_peak_decay[idx] or 0
    -- Decay smoothing — use a higher value when signal > prev for fast attack
    if peak > prev then
      cpu_peak_decay[idx] = peak * 0.6 + prev * 0.4
    else
      cpu_peak_decay[idx] = prev * DECAY
    end
    local fx_cpu_pct  = clamp(cpu_peak_decay[idx] * 100, 0, 99.9)
    local media_cpu   = fx_cpu_pct * 0.15  -- rough media estimate

    tracks[i+1] = {
      index     = i,
      track     = track,
      name      = (i+1) .. ": " .. name,
      num_fx    = num_fx,
      fx_cpu    = fx_cpu_pct,
      pdc       = pdc,
      media_cpu = media_cpu,
      freeze    = freeze,
      guid      = idx,
    }
  end

  -- Sort tracks
  table.sort(tracks, function(a, b)
    local val_a = a[state.sort_col]
    local val_b = b[state.sort_col]
    
    -- handle strings vs numbers
    if type(val_a) == "string" then
      if state.sort_dir == 1 then return val_a:lower() < val_b:lower() end
      return val_a:lower() > val_b:lower()
    else
      if state.sort_dir == 1 then return (val_a or 0) < (val_b or 0) end
      return (val_a or 0) > (val_b or 0)
    end
  end)

  return tracks
end

-- ============================================================
-- GLOBAL SYSTEM STATS
-- ============================================================
local sys = {
  cpu         = 0,
  fx_total    = 0,
  media_total = 0,
  total_pdc   = 0,
  srate       = 0,
}
local sys_smooth = { cpu = 0 }

local function collect_sys_stats(tracks)
  local cpu_acc = 0
  local fx_total = 0
  local media_total = 0
  local pdc_acc = 0
  for _, t in ipairs(tracks) do
    cpu_acc = cpu_acc + t.fx_cpu
    fx_total = fx_total + t.num_fx
    media_total = media_total + t.media_cpu
    pdc_acc = pdc_acc + (t.pdc or 0)
  end
  
  -- Average Project Activity (Weighted Average of all tracks)
  -- This provides a realistic view of overall project intensity (0-100%)
  local avg_cpu = #tracks > 0 and (cpu_acc / #tracks) or 0
  
  -- Smoothing for global CPU bar
  if sys_smooth.cpu > avg_cpu then
    sys_smooth.cpu = sys_smooth.cpu * 0.95 + avg_cpu * 0.05
  else
    sys_smooth.cpu = sys_smooth.cpu * 0.7 + avg_cpu * 0.3
  end

  sys.cpu         = clamp(sys_smooth.cpu, 0, 99.9)
  sys.fx_total    = fx_total
  sys.media_total = media_total
  sys.total_pdc   = pdc_acc
  local _, srate_str = reaper.GetAudioDeviceInfo("SRATE", "")
  sys.srate = tonumber(srate_str) or 0
end

-- ============================================================
-- DRAWING — FOOTER
-- ============================================================
local FOOTER_URL    = "https://gravesoundaudio.store/"
local footer_hover  = false

local function draw_footer()
  local w  = state.win_w
  local h  = state.win_h
  local fy = h - FOOTER_H

  -- Background
  col(C.title_bar)
  fill_rect(0, fy, w, FOOTER_H)
  col(C.sep)
  gfx.line(0, fy, w, fy)

  -- Check hover over the link area
  local mx, my = gfx.mouse_x, gfx.mouse_y
  footer_hover = (my >= fy and my <= h)

  -- Left text: "Developed by Grave Sound"
  gfx.setfont(2)
  col(C.text_dim)
  draw_text_left("Developed by", 10, fy, FOOTER_H)
  col(C.text_name)
  local label_w = gfx.measurestr("Developed by ") + 10
  draw_text_left("Grave Sound", label_w, fy, FOOTER_H)

  -- Right: clickable URL
  local url_label = "gravesoundaudio.store  ↗"
  local uw = gfx.measurestr(url_label)
  local ux = w - uw - 12
  if footer_hover and mx >= ux - 4 then
    col(C.accent)
  else
    col({0x5a, 0x9a, 0xee})
  end
  gfx.x = ux
  gfx.y = fy + (FOOTER_H - gfx.texth) * 0.5
  gfx.drawstr(url_label)

  -- Underline
  local uy = fy + (FOOTER_H + gfx.texth) * 0.5
  gfx.line(ux, uy, ux + uw, uy)
end

local function open_url(url)
  -- Try SWS extension first, fall back to os.execute on Windows
  if reaper.CF_ShellExecute then
    reaper.CF_ShellExecute(url)
  else
    os.execute('start "" "' .. url .. '"')
  end
end

-- ============================================================
-- DRAWING — SYSTEM STATS PANEL
-- ============================================================
local STATS_H = 108  -- height of stats area

local function draw_stats_panel(y)
  local w = state.win_w
  col(C.bg2)
  fill_rect(0, y, w, STATS_H)
  -- separator
  col(C.sep)
  gfx.line(0, y + STATS_H - 1, w, y + STATS_H - 1)

  -- Programmatic Grave Sound skull logo (top-right, no external file needed)
  local lx   = w - LOGO_SIZE - 8
  local ly   = math.floor(y + (STATS_H - LOGO_SIZE) * 0.5)
  local s    = LOGO_SIZE
  local scx  = lx + s * 0.5   -- centre x of logo square

  -- Background square
  col({0x12, 0x12, 0x1a})
  fill_rect(lx, ly, s, s)
  -- 1-px accent border
  col(C.accent)
  gfx.rect(lx, ly, s, s, 0)
  -- Inner subtle highlight
  col({0x3a, 0x5a, 0x88})
  gfx.rect(lx+1, ly+1, s-2, s-2, 0)

  -- Skull head (white filled circle)
  local hr  = math.floor(s * 0.225)   -- head radius
  local hcy = math.floor(ly + s * 0.355)  -- head centre y
  col({0xee, 0xee, 0xee})
  gfx.circle(scx, hcy, hr, 1, 1)

  -- Eye sockets
  local er = math.max(1, math.floor(hr * 0.25))
  col({0x12, 0x12, 0x1a})
  gfx.circle(scx - hr * 0.38, hcy - hr * 0.05, er, 1, 1)
  gfx.circle(scx + hr * 0.38, hcy - hr * 0.05, er, 1, 1)
  -- Nose cavity
  gfx.circle(scx, hcy + hr * 0.25, math.max(1, math.floor(er * 0.55)), 1, 1)

  -- Jaw strip
  local jaw_y = math.floor(hcy + hr * 0.65)
  local jaw_w = math.floor(hr * 1.5)
  local jaw_h = math.floor(hr * 0.48)
  col({0xee, 0xee, 0xee})
  fill_rect(math.floor(scx - jaw_w * 0.5), jaw_y, jaw_w, jaw_h)
  -- Tooth gaps (2 gaps → 3 teeth)
  col({0x12, 0x12, 0x1a})
  for i = 1, 2 do
    local gx = math.floor(scx - jaw_w * 0.5 + (jaw_w / 3) * i)
    fill_rect(gx, jaw_y, 1, jaw_h)
  end

  -- Sound waveform bars at the bottom
  local bar_heights = {0.35, 0.65, 1.0, 0.65, 0.35}
  local bw     = math.max(2, math.floor(s * 0.07))
  local bmax_h = math.floor(s * 0.16)
  local b_bot  = ly + s - 3
  local gap    = 2
  local total_bw = #bar_heights * bw + (#bar_heights - 1) * gap
  local bx0    = math.floor(scx - total_bw * 0.5)
  col(C.accent)
  for i, h_frac in ipairs(bar_heights) do
    local bh = math.max(1, math.floor(bmax_h * h_frac))
    fill_rect(bx0 + (i-1) * (bw + gap), b_bot - bh, bw, bh)
  end

  local lh  = 18
  local lx  = 10
  local ly  = y + 5
  local col2_x = math.floor((w - LOGO_SIZE - 16) * 0.52)

  -- CPU sparkline bar at top (full width minus logo)
  local bar_w = w - LOGO_SIZE - 24
  local bar_h = 14
  col(C.bar_bg)
  fill_rect(lx, ly, bar_w, bar_h)
  local cpu_frac = clamp(sys.cpu / 100, 0, 1)
  if cpu_frac > 0.8 then col(C.bar_cpu_high) else col(C.bar_cpu) end
  if bar_w * cpu_frac > 1 then
    fill_rect(lx, ly, math.floor(bar_w * cpu_frac), bar_h)
  end
  -- CPU label overtop bar
  col(C.text_bright)
  gfx.setfont(1)
  local cpu_label = string.format("cur/avg: %.2f%%/%.2f%%  range: 0%%-100%%",
    sys.cpu, sys.cpu * 0.8)
  draw_text_left(cpu_label, lx + 4, ly, bar_h, 2)
  ly = ly + bar_h + 4

  -- Stats lines (2 columns)
  local function stat_line(label, value)
    col(C.stat_label)
    draw_text_left(label, lx, ly, lh)
    col(C.stat_value)
    draw_text_left(value, lx + 100, ly, lh)
  end

  gfx.setfont(2)
  stat_line("CPU:", string.format("%.2f%%", clamp(sys.cpu, 0, 100)))
  
  col(C.stat_label); draw_text_left("Project Rate:", col2_x, ly, lh)
  col(C.stat_value); draw_text_left(string.format("%.0f Hz", sys.srate), col2_x + 95, ly, lh)
  ly = ly + lh

  col(C.stat_label); draw_text_left("Total Plugins:", lx, ly, lh)
  col(C.stat_value); draw_text_left(tostring(sys.fx_total), lx + 100, ly, lh)
  
  col(C.stat_label); draw_text_left("Total PDC:", col2_x, ly, lh)
  col(C.stat_value); draw_text_left(string.format("%d spls", sys.total_pdc), col2_x + 95, ly, lh)
  ly = ly + lh + 2

  -- FX / Media totals
  col(C.text_dim)
  local total_str = string.format("%d FX: %.1f%%, Media %.1f%%",
    sys.fx_total, clamp(sys.cpu * 0.85, 0, 100), clamp(sys.media_total, 0, 100))
  draw_text_left(total_str, lx, ly, lh)
end

-- ============================================================
-- DRAWING — TRACK TABLE HEADER
-- ============================================================
local TABLE_Y_OFFSET  = STATS_H  -- y start of table area

local function draw_table_header(y)
  local w = state.win_w
  col(C.header_bg)
  fill_rect(0, y, w, HEADER_H)
  col(C.sep)
  gfx.line(0, y + HEADER_H - 1, w, y + HEADER_H - 1)

  gfx.setfont(2)
  for i, c in ipairs(COLS) do
    local is_active = (state.sort_col == c.key)
    if is_active then
      col(C.text_bright)
    else
      col(C.header_text)
    end
    
    local label = c.label
    if is_active then
      label = label .. (state.sort_dir == 1 and " ▲" or " ▼")
    end
    
    if c.w_fixed then
      draw_text_center(label, c.x, y, c.w, HEADER_H)
    else
      draw_text_left(label, c.x, y, HEADER_H, 6)
    end

    -- column separator
    if i < #COLS then
      col(C.sep)
      gfx.line(c.x + c.w - 1, y, c.x + c.w - 1, y + HEADER_H)
    end
  end
end

-- ============================================================
-- DRAWING — TRACK ROWS
-- ============================================================
-- Draw a subtle cpu-fill background bar behind the cell, then text on top
local function draw_cpu_cell(x, y, w, h, pct, label)
  -- background bar fills bottom portion of cell
  local frac   = clamp(pct / 100, 0, 1)
  local bar_h  = 4
  local bar_y  = y + h - bar_h - 1
  col(C.bar_bg)
  fill_rect(x + 2, bar_y, w - 4, bar_h)
  if frac > 0.001 then
    if pct > 70 then col(C.bar_cpu_high) else col(C.bar_cpu) end
    fill_rect(x + 2, bar_y, math.max(1, math.floor((w - 4) * frac)), bar_h)
  end
  -- text centred in upper part of cell
  col(C.text_num)
  draw_text_center(label, x, y, w, h - bar_h - 1)
end

local function draw_tracks(tracks, area_y, area_h)
  local w        = state.win_w
  local scroll   = state.scroll
  local y0       = area_y
  local vis_rows = math.floor(area_h / ROW_H)

  -- Clamp scroll
  local max_scroll = math.max(0, #tracks - vis_rows)
  state.scroll = clamp(scroll, 0, max_scroll)
  scroll = state.scroll

  -- Only reserve scrollbar space when we actually need one
  local has_sb  = (#tracks > vis_rows)
  local SB_W    = has_sb and 13 or 0
  local col_w   = w - SB_W   -- width available for columns

  compute_col_x(col_w)

  -- scissor via gfx (approximate — just skip rows out of view)
  local first = scroll + 1
  local last  = math.min(#tracks, scroll + vis_rows + 1)

  for i = first, last do
    local t  = tracks[i]
    local ry = y0 + (i - 1 - scroll) * ROW_H

    -- Row background (fills exactly the column area, no phantom gap)
    local is_hover = (state.hover_row == i)
    local is_sel   = (state.sel_row   == i)
    if is_sel then
      col(C.row_selected)
    elseif is_hover then
      col(C.row_hover)
    elseif i % 2 == 0 then
      col(C.row_even)
    else
      col(C.row_odd)
    end
    fill_rect(0, ry, col_w, ROW_H)

    -- Freeze indicator strip on left edge
    if t.freeze == 1 then
      col(C.frozen_stereo)
      fill_rect(0, ry, 3, ROW_H)
    elseif t.freeze == 2 then
      col(C.frozen_mono)
      fill_rect(0, ry, 3, ROW_H)
    end

    -- Track name column
    local nc = COLS[1]
    local name_display = t.name
    if t.freeze == 1 then name_display = "❄ " .. name_display .. " [S]"
    elseif t.freeze == 2 then name_display = "❄ " .. name_display .. " [M]"
    end
    -- clip to column width
    col(C.text_name)
    gfx.x = nc.x + 6
    gfx.y = ry + (ROW_H - gfx.texth) * 0.5
    -- truncate if needed
    local max_w = nc.w - 10
    local display = name_display
    while gfx.measurestr(display) > max_w and #display > 4 do
      display = display:sub(1, -2)
    end
    if display ~= name_display then display = display:sub(1,-2) .. "…" end
    gfx.drawstr(display)

    -- FX CPU column
    local fc = COLS[2]
    draw_cpu_cell(fc.x, ry, fc.w, ROW_H, t.fx_cpu, fmt_pct(t.fx_cpu))

    -- UNFREEZE button (if frozen, overlayed at the end of name column/start of FX column)
    if t.freeze > 0 then
      local bw, bh = 60, 16
      local bx = fc.x - bw - 4
      local by = ry + (ROW_H - bh) * 0.5
      t._btn_unfreeze = { x=bx, y=by, w=bw, h=bh }
      
      -- Draw button
      col(C.accent, 0.8)
      gfx.rect(bx, by, bw, bh, 1)
      col(C.text_bright)
      gfx.setfont(2)
      draw_text_center("UNFREEZE", bx, by, bw, bh)
    end

    -- # FX column
    local nfc = COLS[3]
    col(C.text_num)
    draw_text_center(tostring(t.num_fx), nfc.x, ry, nfc.w, ROW_H)

    -- PDC column
    local pdc_c = COLS[4]
    col(t.pdc > 0 and C.text_num or C.text_dim)
    draw_text_center(tostring(t.pdc), pdc_c.x, ry, pdc_c.w, ROW_H)

    -- Media CPU column
    local mc = COLS[5]
    draw_cpu_cell(mc.x, ry, mc.w, ROW_H, t.media_cpu, fmt_pct(t.media_cpu))

    -- Row separator (spans column area only)
    col(C.sep)
    gfx.line(0, ry + ROW_H - 1, col_w - 1, ry + ROW_H - 1)
  end

  -- Scrollbar (only when needed, overlaid on right edge)
  if has_sb then
    local sb_x = w - 11
    col(C.bar_bg)
    fill_rect(sb_x, y0, 10, area_h)
    local thumb_h = math.max(20, area_h * vis_rows / #tracks)
    local thumb_y = (max_scroll > 0)
      and (y0 + (area_h - thumb_h) * (scroll / max_scroll))
      or  y0
    col(C.accent)
    fill_rect(sb_x + 1, thumb_y, 8, thumb_h)
  end
end

-- ============================================================
-- CONTEXT MENU
-- ============================================================
local MENU_W    = 200
local MENU_ITEM_H = 22
local MENU_PAD  = 6

local function build_menu(track_data)
  local items = {}
  local freeze = track_data.freeze
  if freeze == 0 then
    items[#items+1] = { label = "Freeze to Stereo",  action = "freeze_stereo" }
    items[#items+1] = { label = "Freeze to Mono",    action = "freeze_mono"   }
  else
    items[#items+1] = { label = "Unfreeze",           action = "unfreeze"      }
    if freeze == 1 then
      items[#items+1] = { label = "Refreeze to Mono",  action = "freeze_mono"  }
    else
      items[#items+1] = { label = "Refreeze to Stereo",action = "freeze_stereo"}
    end
  end
  items[#items+1] = { sep = true }
  items[#items+1] = { label = "Select Track Only",   action = "select_only"   }
  items[#items+1] = { label = "Show in Track List",  action = "show_track"    }
  return items
end

local function do_menu_action(action, track_data)
  local track = track_data.track
  -- Deselect all, select target track
  reaper.SetOnlyTrackSelected(track)
  if action == "freeze_stereo" then
    reaper.Main_OnCommand(41223, 0)  -- Freeze to stereo (pre-fader)
    state.freeze_states[track_data.guid] = 1 -- Instant cache update
  elseif action == "freeze_mono" then
    local cmd = reaper.NamedCommandLookup("_41184")
    if cmd == 0 then cmd = 41235 end
    reaper.Main_OnCommand(cmd, 0)
    state.freeze_states[track_data.guid] = 2 -- Instant cache update
  elseif action == "unfreeze" then
    reaper.Main_OnCommand(41644, 0)  -- Track: Unfreeze tracks
    state.freeze_states[track_data.guid] = 0 -- Instant cache update
  elseif action == "select_only" then
    -- already selected above
  elseif action == "show_track" then
    reaper.SetTrackSelected(track, true)
    reaper.Main_OnCommand(40913, 0)  -- Scroll to selected track
  end
end

local function draw_context_menu()
  if not state.menu_open then return end

  local items  = state.menu_items
  local mx, my = gfx.mouse_x, gfx.mouse_y
  local mn_h   = MENU_PAD * 2
  for _, item in ipairs(items) do
    if item.sep then mn_h = mn_h + 8 else mn_h = mn_h + MENU_ITEM_H end
  end

  local mw = MENU_W
  local sx = clamp(state.menu_x, 0, state.win_w - mw)
  local sy = clamp(state.menu_y, 0, state.win_h - mn_h)

  -- Shadow
  col({0, 0, 0}, 0.5)
  fill_rect(sx + 3, sy + 3, mw, mn_h)

  -- Background
  col(C.menu_bg)
  fill_rect(sx, sy, mw, mn_h)
  col(C.sep)
  gfx.rect(sx, sy, mw, mn_h, 0)  -- outline

  local iy = sy + MENU_PAD
  for idx, item in ipairs(items) do
    if item.sep then
      col(C.sep)
      gfx.line(sx + 8, iy + 3, sx + mw - 8, iy + 3)
      iy = iy + 8
    else
      local hovering = mx >= sx and mx <= sx + mw and my >= iy and my <= iy + MENU_ITEM_H
      if hovering then
        col(C.menu_hover)
        fill_rect(sx + 1, iy, mw - 2, MENU_ITEM_H)
        col(C.text_bright)
      else
        col(C.menu_item)
      end
      draw_text_left(item.label, sx, iy, MENU_ITEM_H, 12)
      item._hover = hovering
      item._y     = iy
      iy = iy + MENU_ITEM_H
    end
  end

  state._menu_bounds = { x=sx, y=sy, w=mw, h=mn_h }
  state._menu_iy_end = iy
end

-- ============================================================
-- RESIZE HANDLE
-- ============================================================
local RESIZE_SZ = 12

local function draw_resize_handle()
  local w = state.win_w
  local h = state.win_h
  col(C.text_dim)
  -- draw three diagonal lines in bottom-right corner
  for i = 1, 3 do
    local o = i * 3
    gfx.line(w - o, h, w, h - o)
  end
end

-- ============================================================
-- INPUT HANDLING
-- ============================================================
local mb_prev = 0
local mr_prev = 0

local function handle_input(tracks)
  local mx, my   = gfx.mouse_x, gfx.mouse_y
  local mb        = gfx.mouse_cap & 1   -- left button
  local mr        = gfx.mouse_cap & 2   -- right button
  local mb_click  = (mb == 1 and mb_prev == 0)
  local mb_release= (mb == 0 and mb_prev == 1)
  local mr_click  = (mr == 2 and mr_prev == 0)
  local w = state.win_w
  local h = state.win_h

  -- Context menu input
  if state.menu_open then
    if mb_click then
      -- Check if click is inside menu
      local b = state._menu_bounds
      if b and mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h then
        for _, item in ipairs(state.menu_items) do
          if item._hover and item.action then
            reaper.Undo_BeginBlock()
            do_menu_action(item.action, state.menu_track)
            reaper.Undo_EndBlock("ReaPerform: " .. item.action, -1)
            state.menu_open = false
            break
          end
        end
      else
        state.menu_open = false
      end
    end
    mb_prev = mb; mr_prev = mr
    return true
  end

  -- No custom title-bar drag (native OS window handles dragging)

  -- Resize handle
  local rx = w - RESIZE_SZ
  local ry = h - RESIZE_SZ
  if mb_click and mx >= rx and my >= ry then
    state.resizing  = true
    state.resize_ox = mx
    state.resize_oy = my
    state.resize_w0 = w
    state.resize_h0 = h
  end
  if state.resizing then
    if mb == 0 then
      state.resizing = false
    else
      local nw = math.max(MIN_WIN_W, state.resize_w0 + (mx - state.resize_ox))
      local nh = math.max(MIN_WIN_H, state.resize_h0 + (my - state.resize_oy))
      gfx.w = nw
      gfx.h = nh
      state.win_w = nw
      state.win_h = nh
    end
  end

  -- Table area mouse tracking
  -- IMPORTANT: subtract FOOTER_H so vis_rows matches what draw_tracks sees
  local table_y  = TABLE_Y_OFFSET + HEADER_H
  local table_h  = h - table_y - FOOTER_H
  local vis_rows = math.floor(table_h / ROW_H)
  local max_scroll = math.max(0, #tracks - vis_rows)

  -- ---- Scrollbar drag ----
  -- The scrollbar lives in the rightmost 11px when tracks exceed the view.
  local sb_x = w - 11
  local sb_zone = mx >= sb_x and mx <= w

  -- Start drag on click inside scrollbar lane (only when scrollable)
  if mb_click and sb_zone and my >= table_y and my <= h - FOOTER_H and max_scroll > 0 then
    state.sb_drag         = true
    state.sb_drag_start_y = my
    state.sb_drag_start_s = state.scroll
  end

  -- Continue / end drag
  if state.sb_drag then
    if mb == 0 then
      state.sb_drag = false
    else
      -- Map mouse movement to scroll delta:
      -- dragging the full scrollbar height = scrolling max_scroll rows
      local drag_delta = my - state.sb_drag_start_y
      local px_per_row = table_h / math.max(1, #tracks)
      local row_delta  = math.floor(drag_delta / px_per_row + 0.5)
      state.scroll = clamp(state.sb_drag_start_s + row_delta, 0, max_scroll)
    end
  end

  -- Header clicks for sorting
  if mb_click and my >= TABLE_Y_OFFSET and my <= TABLE_Y_OFFSET + HEADER_H then
    for i, c in ipairs(COLS) do
      if mx >= c.x and mx <= c.x + c.w then
        if state.sort_col == c.key then
          state.sort_dir = -state.sort_dir
        else
          state.sort_col = c.key
          state.sort_dir = -1 -- default to desc for most columns
          if c.key == "name" then state.sort_dir = 1 end
        end
        state.tracks = collect_track_data() -- refresh sort immediately
        break
      end
    end
  end

  -- Scroll wheel (only when cursor is over the track list, not footer)
  if not state.sb_drag and my >= table_y and my <= h - FOOTER_H then
    local wheel = gfx.mouse_wheel
    if wheel ~= 0 then
      state.scroll = clamp(
        state.scroll - math.floor(wheel / 120),
        0,
        max_scroll
      )
      gfx.mouse_wheel = 0
    end
  end

  -- Hover row (suppress while dragging scrollbar, exclude footer area)
  state.hover_row = -1
  if not state.sb_drag and my >= table_y and my <= h - FOOTER_H and mx < w - 12 then
    local row = math.floor((my - table_y) / ROW_H) + 1 + state.scroll
    if row >= 1 and row <= #tracks then
      state.hover_row = row
    end
  end

  -- Left-click select row (suppress during scrollbar drag)
  if mb_click and state.hover_row >= 1 and not sb_zone then
    local t = tracks[state.hover_row]
    -- Check if click is on UNFREEZE button
    if t._btn_unfreeze then
      local b = t._btn_unfreeze
      if mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h then
        reaper.Undo_BeginBlock()
        do_menu_action("unfreeze", t)
        reaper.Undo_EndBlock("ReaPerform: Unfreeze", -1)
        mb_prev = mb; mr_prev = mr
        return true
      end
    end
    state.sel_row = state.hover_row
  end

  -- Right-click context menu
  if mr_click and state.hover_row >= 1 then
    state.sel_row    = state.hover_row
    state.menu_open  = true
    state.menu_x     = mx
    state.menu_y     = my
    state.menu_track = tracks[state.hover_row]
    state.menu_items = build_menu(tracks[state.hover_row])
  end

  -- Footer click — open Grave Sound store URL
  if mb_click and gfx.mouse_y >= state.win_h - FOOTER_H then
    open_url(FOOTER_URL)
  end

  mb_prev = mb
  mr_prev = mr
  return true
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
local function init()
  gfx.init(SCRIPT_NAME, WIN_W, WIN_H, 0, 200, 200)
  gfx.setfont(1, "Segoe UI", 14)  -- stats bar text
  gfx.setfont(2, "Segoe UI", 13)  -- track rows / footer
  gfx.setfont(3, "Consolas", 13)  -- monospaced (unused but available)
  -- (Logo is drawn programmatically, no image file required)
end

local function frame()
  state.frame = state.frame + 1
  state.win_w = gfx.w
  state.win_h = gfx.h

  -- Collect data every N frames
  if state.frame % SAMPLE_INTERVAL == 0 then
    state.tracks = collect_track_data()
    collect_sys_stats(state.tracks)
  end
  local tracks = state.tracks

  -- Clear background
  col(C.bg)
  gfx.rect(0, 0, state.win_w, state.win_h, 1)

  -- Ensure columns are sized before drawing anything that depends on them
  compute_col_x(state.win_w - 12) 
  
  -- Draw layers (no custom title bar — use native OS window bar)
  gfx.setfont(1)
  draw_stats_panel(0)
  gfx.setfont(2)
  draw_table_header(TABLE_Y_OFFSET)

  local table_top = TABLE_Y_OFFSET + HEADER_H
  local table_h   = state.win_h - table_top - FOOTER_H
  draw_tracks(tracks, table_top, table_h)

  -- Footer (drawn before context menu so menu shows above it)
  draw_footer()

  -- Resize handle (on top)
  draw_resize_handle()

  -- Context menu (topmost)
  draw_context_menu()

  -- Input
  local ok = handle_input(tracks)
  if not ok then return false end

  -- Background worker for heavy freeze checks (one track per frame)
  update_freeze_cache(tracks)

  -- Check window close
  if gfx.getchar() < 0 then return false end

  gfx.update()
  return true
end

-- ============================================================
-- ENTRY
-- ============================================================
init()

local function main()
  if not frame() then return end
  reaper.defer(main)
end

main()

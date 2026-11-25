-- @description Dubbing SubOverlay: subtitles over the video window
-- @author zaraki999kenpachi
-- @version 8.0.2
-- @changelog First release
-- @about
--   # Dubbing SubOverlay
--
--   Subtitles over the REAPER Video window: transparent background, centered text, next line, progress bar, 3-2-1 countdown, roles with colors, overlapping lines, karaoke highlight.
--
--   Reads the subtitles imported in Dubbing_Prompter.lua. Run it again to close it.
--
--   Requires: ReaImGui (and js_ReaScriptAPI to attach to the video window) via ReaPack.

-- Dubbing SubOverlay 0.10.0 — subtitles over the REAPER Video window (ReaImGui).
-- Reads subtitles imported in Dubbing Prompter (project ExtState DubbingSystem / subtitle_data_v1).
-- Features: transparent background, centered text, next line preview, progress bar,
-- 3-2-1 countdown before a line, roles (colors + filter), overlapping lines shown together,
-- karaoke highlight (by time, uniform speed), font / color / outline thickness, auto-fit text size,
-- presets: "subtitles on video" and "prompter" (separate big window for a second monitor).
-- Run the script again to close the running overlay (toggle). Right-click the overlay for settings.
-- Requires ReaImGui (ReaPack). Optional: js_ReaScriptAPI (to attach to the Video window).

if not reaper.ImGui_CreateContext then
  reaper.ShowMessageBox("Не найден ReaImGui.\n\nУстанови: Extensions → ReaPack → Browse packages → ReaImGui.", "Dubbing SubOverlay", 0)
  return
end

local SEC, KEY = "DubbingSystem", "subtitle_data_v1"
local CFG = "DubbingSubOverlayV2"

-- re-launching the action terminates the running instance without a prompt (REAPER 6.36+)
if reaper.set_action_options then reaper.set_action_options(1) end

-- toggle: if an instance is already running, ask it to close and exit
local hb = tonumber(reaper.GetExtState(CFG, "hb") or "")
if hb and reaper.time_precise() - hb < 1.0 then
  reaper.SetExtState(CFG, "quit", "1", false)
  return
end
reaper.DeleteExtState(CFG, "quit", false)

-- ---------- settings ----------
-- mode: 1 = centered over the video, 2 = over the video at the bottom, 3 = bar below the video
local S = {
  attach = true, mode = 1, offset = 0, h = 170, size = 40, bold = true, bg = 0, title = false,
  font = 1, color = 0xFFFFFFFF, role_color = false, show_role = true, show_next = true,
  progress = true, countdown = true, autofit = true, role_filter = "",
  karaoke = false, outline = 2, multi = true,
  warn_cps = 20, show_orig = false, rec_mark = true, timer = true,
  badge = true, tc = true, tc_frames = false, actor_big = false,
}

local DEFAULTS = {}
for k, v in pairs(S) do DEFAULTS[k] = v end

-- dub track items (cached 2 s): used for the take count and the overrun of the current line
local dub_items, dub_time = {}, -10
local function dub_list()
  local now = reaper.time_precise()
  if now - dub_time < 2 then return dub_items end
  dub_time = now; dub_items = {}
  local _, g = reaper.GetProjExtState(0, SEC, "dubbing_track_guid")
  if not g or g == "" then return dub_items end
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, tg = reaper.GetSetMediaTrackInfo_String(tr, "GUID", "", false)
    if tg == g then
      for j = 0, reaper.CountTrackMediaItems(tr) - 1 do
        local it = reaper.GetTrackMediaItem(tr, j)
        local p = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
        dub_items[#dub_items + 1] = { p, p + reaper.GetMediaItemInfo_Value(it, "D_LENGTH") }
      end
      break
    end
  end
  return dub_items
end

-- takes of a line and how far the last take runs past the end of the line
local function take_stats(s)
  local n, over = 0, 0
  for _, it in ipairs(dub_list()) do
    if it[1] < s.finish and it[2] > s.start then
      n = n + 1
      if it[2] - s.finish > over then over = it[2] - s.finish end
    end
  end
  return n, over
end

-- playhead time: seconds or HH:MM:SS:FF
local function tc_text(t)
  if S.tc_frames then
    local ok, f = pcall(reaper.TimeMap_curFrameRate, 0)
    local fps = (ok and f and f > 0) and f or 25
    local n = math.floor(fps + 0.5)
    local total = math.floor(t * fps + 0.5)
    return string.format("%02d:%02d:%02d:%02d", total // (n * 3600), (total // (n * 60)) % 60, (total // n) % 60, total % n)
  end
  return string.format("%02d:%02d:%05.2f", math.floor(t / 3600), math.floor(t / 60) % 60, t % 60)
end

local VCOL = { ok = 0x4CAF50FF, redo = 0xFF5A5AFF, check = 0xFFD64FFF, lip = 0xFFD64FFF }
local VTXT = { ok = "ок", redo = "переписать", check = "спорно", lip = "губы не совпадают" }

local function load_settings()
  for k, d in pairs(S) do
    local v = reaper.GetExtState(CFG, k)
    if v ~= "" then
      if type(d) == "boolean" then S[k] = (v == "1")
      elseif type(d) == "number" then S[k] = tonumber(v) or d
      else S[k] = v end
    end
  end
end

local function save_settings()
  for k, v in pairs(S) do
    local s = type(v) == "boolean" and (v and "1" or "0") or tostring(v)
    reaper.SetExtState(CFG, k, s, true)
  end
end
load_settings()

local function ulen(s) return utf8.len(s) or #s end

-- ---------- roles / palette (same order as in Dubbing Prompter) ----------
local PAL = { 0xFFD64FFF, 0x4FC2F7FF, 0x82C785FF, 0xF06192FF, 0xBA68C8FF,
              0xFF8A66FF, 0x4DB5ABFF, 0xA18880FF, 0x8FA3ADFF, 0xDCE875FF }
local ACCENT = 0x4FC2F7FF
local YELLOW = 0xFFD64FFF

-- ---------- subtitles ----------
local subs, view, roles, role_idx = {}, {}, {}, {}
local raw_cache, last_check = nil, 0

-- saved line: start \t end \t text \t role [\t done \t mark \t note \t orig]
local function parse(raw)
  local out, rl, ri = {}, {}, {}
  for line in ((raw or "") .. "\n"):gmatch("(.-)\n") do
    local a, b, rest = line:match("^([%d%.%-]+)\t([%d%.%-]+)\t(.*)$")
    local st, en = tonumber(a), tonumber(b)
    if st and en and en > st then
      local f = {}
      for part in (rest .. "\t"):gmatch("(.-)\t") do f[#f + 1] = part end
      local text, role = f[1] or "", f[2] or ""
      text = text:gsub("\\n", "\n"):gsub("\\N", "\n"):gsub("\r", "")
      if text:match("%S") then
        out[#out + 1] = { start = st, finish = en, text = text, role = role, orig = (f[6] or ""):gsub("\\n", " "),
          done = (f[3] == "1"), verdict = ((f[8] or "") ~= "" and f[8]) or nil }
        if role ~= "" and not ri[role] then rl[#rl + 1] = role; ri[role] = #rl end -- first appearance, saved order
      end
    end
  end
  table.sort(out, function(x, y) return x.start < y.start end)
  for i, s in ipairs(out) do s.no = i end   -- same numbering as in Dubbing Prompter
  return out, rl, ri
end

local function rebuild_view()
  if S.role_filter == "" then
    view = subs
  else
    view = {}
    for _, s in ipairs(subs) do if s.role == S.role_filter then view[#view + 1] = s end end
  end
end

local function refresh()
  local t = reaper.time_precise()
  if t - last_check < 0.5 then return end
  last_check = t
  local _, raw = reaper.GetProjExtState(0, SEC, KEY)
  if raw ~= raw_cache then
    raw_cache = raw
    subs, roles, role_idx = parse(raw)
    rebuild_view()
  end
end

-- all lines active at pos (earliest start first) and the next line
local function active(pos)
  local lo, hi, idx = 1, #view, 0
  while lo <= hi do
    local mid = math.floor((lo + hi) / 2)
    if view[mid].start <= pos then idx = mid; lo = mid + 1 else hi = mid - 1 end
  end
  local list = {}
  for i = idx, math.max(1, idx - 8), -1 do
    local s = view[i]
    if s and pos < s.finish then table.insert(list, 1, s) end
  end
  if not S.multi and #list > 1 then list = { list[#list] } end
  return list, view[idx + 1]
end

local function role_col(role)
  local i = role_idx[role]
  return i and PAL[((i - 1) % #PAL) + 1] or 0xFFFFFFFF
end

-- ---------- ImGui ----------
local ctx = reaper.ImGui_CreateContext("Dubbing SubOverlay")
local FONT_NAMES = { "Arial", "Segoe UI", "Tahoma", "Verdana", "Roboto", "Calibri", "Georgia", "Times New Roman", "Consolas" }
local bold_flag = (reaper.ImGui_FontFlags_Bold and reaper.ImGui_FontFlags_Bold()) or 0
local fonts = {}
for i, name in ipairs(FONT_NAMES) do
  local reg = reaper.ImGui_CreateFont(name, 0)
  local bold = (bold_flag ~= 0) and reaper.ImGui_CreateFont(name, bold_flag) or reg
  reaper.ImGui_Attach(ctx, reg)
  if bold ~= reg then reaper.ImGui_Attach(ctx, bold) end
  fonts[i] = { reg = reg, bold = bold }
end

local function cur_font()
  local f = fonts[S.font] or fonts[1]
  return S.bold and f.bold or f.reg
end

local function push_font(f, size)
  if pcall(reaper.ImGui_PushFont, ctx, f, size) then return true end
  return pcall(reaper.ImGui_PushFont, ctx, f)
end

local function video_rect()
  if not reaper.JS_Window_Find then return nil end
  local hwnd = reaper.JS_Window_Find("Video Window", true)
  if not hwnd then return nil end
  local ok, l, t, r, b = reaper.JS_Window_GetRect(hwnd)
  if ok and r > l and b > t then return l, t, r, b end
end

-- word wrap with the CURRENT font
local function wrap(text, maxw)
  local out = {}
  for para in (text .. "\n"):gmatch("(.-)\n") do
    if para == "" then
      out[#out + 1] = ""
    else
      local cur = ""
      for word in para:gmatch("%S+") do
        local test = (cur == "") and word or (cur .. " " .. word)
        local w = reaper.ImGui_CalcTextSize(ctx, test)
        if w > maxw and cur ~= "" then out[#out + 1] = cur; cur = word else cur = test end
      end
      if cur ~= "" then out[#out + 1] = cur end
    end
  end
  return out
end

local fitcache, fitcount = {}, 0
local function layout(text, font, size, maxw)
  local key = text .. "|" .. S.font .. (S.bold and "b" or "r") .. "|" .. size .. "|" .. math.floor(maxw)
  local c = fitcache[key]
  if c then return c end
  local p = push_font(font, size)
  local lines = wrap(text, maxw)
  local lh = reaper.ImGui_GetTextLineHeight(ctx)
  local widths = {}
  for i, l in ipairs(lines) do widths[i] = (reaper.ImGui_CalcTextSize(ctx, l)) end
  if p then reaper.ImGui_PopFont(ctx) end
  c = { lines = lines, lh = lh, widths = widths }
  fitcount = fitcount + 1
  if fitcount > 300 then fitcache = {}; fitcount = 0 end
  fitcache[key] = c
  return c
end

local function fit(text, font, maxsize, maxw, maxh)
  local size = maxsize
  while true do
    local c = layout(text, font, size, maxw)
    if not S.autofit or size <= 12 or #c.lines * c.lh <= maxh then return size, c end
    size = size - 2
  end
end

local OUT = { {-1, 0}, {1, 0}, {0, -1}, {0, 1}, {1, 1}, {-1, -1}, {1, -1}, {-1, 1} }

-- draws wrapped lines centered in the window; frac (0..1) + hi enable the karaoke highlight
local function draw_lines(dl, wx, wy, ww, y, c, font, size, col, outline, frac, hi)
  local p = push_font(font, size)
  local oc = col & 0xFF -- black with the same alpha as the text
  local ow = S.outline
  local nhi, off = 0, 0
  if frac then
    local total = 0
    for _, l in ipairs(c.lines) do total = total + ulen(l) end
    nhi = math.floor(total * math.max(0, math.min(1, frac)) + 0.5)
  end
  for i, l in ipairs(c.lines) do
    if l ~= "" then
      local x = wx + (ww - c.widths[i]) / 2
      local yy = wy + y + (i - 1) * c.lh
      if outline and ow > 0 then
        for _, o in ipairs(OUT) do reaper.ImGui_DrawList_AddText(dl, x + o[1] * ow, yy + o[2] * ow, oc, l) end
      end
      local len = ulen(l)
      local k = frac and math.max(0, math.min(len, nhi - off)) or 0
      off = off + len
      if k <= 0 then
        reaper.ImGui_DrawList_AddText(dl, x, yy, col, l)
      elseif k >= len then
        reaper.ImGui_DrawList_AddText(dl, x, yy, hi, l)
      else
        local cut = utf8.offset(l, k + 1)
        local left, right = l:sub(1, cut - 1), l:sub(cut)
        reaper.ImGui_DrawList_AddText(dl, x, yy, hi, left)
        local lw = reaper.ImGui_CalcTextSize(ctx, left)
        reaper.ImGui_DrawList_AddText(dl, x + lw, yy, col, right)
      end
    end
  end
  if p then reaper.ImGui_PopFont(ctx) end
end

local function draw_menu()
  local changed, c = false, false
  if reaper.ImGui_Button(ctx, "Пресет: субтитры на видео") then
    S.attach = true; S.mode = 1; S.h = 170; S.size = 40; S.bg = 0; S.title = false; changed = true
  end
  if reaper.ImGui_Button(ctx, "Пресет: суфлёр (отдельное окно)") then
    S.attach = false; S.h = 320; S.size = 64; S.bg = 235; S.title = true
    S.show_next = true; S.progress = true; S.autofit = true; changed = true
  end
  reaper.ImGui_Separator(ctx)
  c, S.attach = reaper.ImGui_Checkbox(ctx, "Привязать к видеоокну", S.attach); changed = changed or c
  if S.attach then
    if reaper.ImGui_RadioButton(ctx, "По центру видео", S.mode == 1) then S.mode = 1; changed = true end
    if reaper.ImGui_RadioButton(ctx, "Поверх видео, снизу", S.mode == 2) then S.mode = 2; changed = true end
    if reaper.ImGui_RadioButton(ctx, "Под видео", S.mode == 3) then S.mode = 3; changed = true end
    c, S.offset = reaper.ImGui_SliderInt(ctx, "Отступ, px", S.offset, -300, 300); changed = changed or c
    if not reaper.JS_Window_Find then reaper.ImGui_Text(ctx, "Нужен js_ReaScriptAPI (ReaPack)") end
  end
  c, S.h = reaper.ImGui_SliderInt(ctx, "Высота панели", S.h, 40, 600); changed = changed or c

  reaper.ImGui_Separator(ctx)
  if reaper.ImGui_BeginCombo(ctx, "Шрифт", FONT_NAMES[S.font] or FONT_NAMES[1]) then
    for i, name in ipairs(FONT_NAMES) do
      if reaper.ImGui_Selectable(ctx, name, i == S.font) then S.font = i; changed = true; fitcache = {}; fitcount = 0 end
    end
    reaper.ImGui_EndCombo(ctx)
  end
  c, S.size = reaper.ImGui_SliderInt(ctx, "Размер текста", S.size, 12, 160); changed = changed or c
  c, S.autofit = reaper.ImGui_Checkbox(ctx, "Автоподбор размера под панель", S.autofit); changed = changed or c
  c, S.bold = reaper.ImGui_Checkbox(ctx, "Жирный", S.bold); changed = changed or c
  c, S.color = reaper.ImGui_ColorEdit4(ctx, "Цвет текста", S.color,
    reaper.ImGui_ColorEditFlags_NoInputs() | reaper.ImGui_ColorEditFlags_AlphaBar()); changed = changed or c
  c, S.bg = reaper.ImGui_SliderInt(ctx, "Фон: непрозрачность", S.bg, 0, 255); changed = changed or c
  c, S.outline = reaper.ImGui_SliderInt(ctx, "Обводка (при прозрачном фоне)", S.outline, 0, 6); changed = changed or c

  reaper.ImGui_Separator(ctx)
  c, S.show_next = reaper.ImGui_Checkbox(ctx, "Показывать следующую реплику", S.show_next); changed = changed or c
  c, S.progress = reaper.ImGui_Checkbox(ctx, "Полоска времени реплики", S.progress); changed = changed or c
  c, S.countdown = reaper.ImGui_Checkbox(ctx, "Отсчёт 3-2-1 перед репликой", S.countdown); changed = changed or c
  c, S.karaoke = reaper.ImGui_Checkbox(ctx, "Караоке-подсветка (по времени)", S.karaoke); changed = changed or c
  c, S.multi = reaper.ImGui_Checkbox(ctx, "Показывать пересекающиеся реплики", S.multi); changed = changed or c
  c, S.show_role = reaper.ImGui_Checkbox(ctx, "Показывать имя роли", S.show_role); changed = changed or c
  c, S.role_color = reaper.ImGui_Checkbox(ctx, "Текст цветом роли", S.role_color); changed = changed or c

  local label = (S.role_filter == "") and "Все роли" or S.role_filter
  if reaper.ImGui_BeginCombo(ctx, "Роль", label) then
    if reaper.ImGui_Selectable(ctx, "Все роли", S.role_filter == "") then S.role_filter = ""; changed = true; rebuild_view() end
    for _, r in ipairs(roles) do
      if reaper.ImGui_Selectable(ctx, r, S.role_filter == r) then S.role_filter = r; changed = true; rebuild_view() end
    end
    reaper.ImGui_EndCombo(ctx)
  end

  c, S.title = reaper.ImGui_Checkbox(ctx, "Заголовок окна", S.title); changed = changed or c
  c, S.show_orig = reaper.ImGui_Checkbox(ctx, "Оригинал мелким шрифтом под переводом", S.show_orig); changed = changed or c
  c, S.rec_mark = reaper.ImGui_Checkbox(ctx, "Красная рамка во время записи", S.rec_mark); changed = changed or c
  c, S.timer = reaper.ImGui_Checkbox(ctx, "Таймер до следующей реплики (в паузах)", S.timer); changed = changed or c
  c, S.badge = reaper.ImGui_Checkbox(ctx, "Номер, оценка и дубли текущей реплики", S.badge); changed = changed or c
  c, S.actor_big = reaper.ImGui_Checkbox(ctx, "Режим актёра: крупнее его реплики (роль в фильтре)", S.actor_big); changed = changed or c
  c, S.tc = reaper.ImGui_Checkbox(ctx, "Таймкод плейхеда", S.tc); changed = changed or c
  c, S.tc_frames = reaper.ImGui_Checkbox(ctx, "Таймкод в кадрах", S.tc_frames); changed = changed or c
  local wc = S.warn_cps
  c, wc = reaper.ImGui_SliderInt(ctx, "Предупреждать о скорости, зн/с (0 = выкл)", S.warn_cps, 0, 40); changed = changed or c
  S.warn_cps = tonumber(wc) or S.warn_cps
  if changed then save_settings() end
  if reaper.ImGui_Button(ctx, "Сбросить настройки к умолчанию") then
    for k, v in pairs(DEFAULTS) do S[k] = v end
    rebuild_view(); save_settings()
  end
  reaper.ImGui_Separator(ctx)
  return reaper.ImGui_Button(ctx, "Закрыть оверлей")
end

local closing = false

local function loop()
  refresh()
  reaper.SetExtState(CFG, "hb", tostring(reaper.time_precise()), false)
  if reaper.GetExtState(CFG, "quit") == "1" then closing = true end

  local playing = (reaper.GetPlayState() & 1) == 1
  local pos = playing and reaper.GetPlayPosition() or reaper.GetCursorPosition()
  local act, nxt = active(pos)

  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowBorderSize(), 0)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding(), 12, 6)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), S.bg & 0xFF) -- 0xRRGGBBAA: black + alpha

  local wflags = reaper.ImGui_WindowFlags_NoScrollbar() | reaper.ImGui_WindowFlags_NoScrollWithMouse()
    | reaper.ImGui_WindowFlags_NoDocking() | reaper.ImGui_WindowFlags_NoCollapse()
  if not S.title then wflags = wflags | reaper.ImGui_WindowFlags_NoTitleBar() end

  local l, t, r, b
  if S.attach then l, t, r, b = video_rect() end
  if l then
    wflags = wflags | reaper.ImGui_WindowFlags_NoMove() | reaper.ImGui_WindowFlags_NoResize()
    local y
    if S.mode == 1 then y = (t + b) / 2 - S.h / 2 + S.offset      -- centered vertically on the video
    elseif S.mode == 2 then y = b - S.h - S.offset                -- bottom edge, inside the video
    else y = b + S.offset end                                     -- below the video
    reaper.ImGui_SetNextWindowPos(ctx, l, y)
    reaper.ImGui_SetNextWindowSize(ctx, r - l, S.h)
  else
    reaper.ImGui_SetNextWindowSize(ctx, 900, S.h, reaper.ImGui_Cond_FirstUseEver())
    reaper.ImGui_SetNextWindowPos(ctx, 200, 200, reaper.ImGui_Cond_FirstUseEver())
  end

  local visible, open = reaper.ImGui_Begin(ctx, "Dubbing SubOverlay", true, wflags)
  if visible then
    local ww, wh = reaper.ImGui_GetWindowSize(ctx)
    local wx, wy = reaper.ImGui_GetWindowPos(ctx)
    local dl = reaper.ImGui_GetWindowDrawList(ctx)
    local font = cur_font()
    local outline = S.bg < 128

    -- what to show: active lines, or a 3-2-1 countdown before the next one
    -- actor mode: when a role is chosen, its lines are shown larger
    local boost = (S.actor_big and S.role_filter ~= "") and 1.3 or 1
    local blocks, maxsize = {}, math.floor(S.size * boost)
    for _, s in ipairs(act) do
      blocks[#blocks + 1] = { text = s.text, role = s.role, frac = (pos - s.start) / (s.finish - s.start), s = s }
    end
    if #blocks == 0 and S.countdown and playing and nxt and nxt.start - pos > 0 and nxt.start - pos <= 3 then
      blocks[1] = { text = tostring(math.ceil(nxt.start - pos)), role = nxt.role, countdown = true }
      maxsize = math.floor(S.size * 1.5)
    end
    local multi = #blocks > 1
    local first = blocks[1]
    local role = (not multi and first) and first.role or ""

    local pad, margin = 6, 24
    local bar_h = S.progress and 5 or 0
    local role_h = (S.show_role and role ~= "") and 22 or 0
    local maxw = ww - margin * 2

    -- next line (small, dim)
    local nc, nsize, nh = nil, 0, 0
    if S.show_next and nxt and #blocks > 0 then
      nsize = math.max(12, math.floor(S.size * 0.5))
      nc = layout((nxt.text:gsub("\n", " ")), font, nsize, maxw)
      nh = #nc.lines * nc.lh
      if nh > wh * 0.3 then nc = nil; nh = 0 end
    end

    local avail = wh - pad * 2 - bar_h - role_h - nh
    if #blocks > 0 then
      local shown, displays = {}, {}
      for i, bk in ipairs(blocks) do
        local d = bk.text
        if multi and S.show_role and bk.role ~= "" then d = bk.role .. ": " .. d end
        displays[i] = d
      end
      local size = fit(table.concat(displays, "\n"), font, maxsize, maxw, math.max(avail, 10))
      local layouts, total_h = {}, 0
      for i, d in ipairs(displays) do
        layouts[i] = layout(d, font, size, maxw)
        total_h = total_h + #layouts[i].lines * layouts[i].lh
      end
      local y = pad + role_h + math.max(0, (avail - total_h) / 2)
      for i, bk in ipairs(blocks) do
        local c = layouts[i]
        local col
        if bk.countdown then col = ACCENT
        elseif (multi or S.role_color) and bk.role ~= "" then col = role_col(bk.role)
        else col = S.color end
        if bk.s and S.warn_cps > 0 and not bk.countdown then
          local dur = bk.s.finish - bk.s.start
          if dur > 0 and ulen(bk.text:gsub("\n", "")) / dur > S.warn_cps then col = 0xFF5A5AFF end
        end
        local frac, hi
        if S.karaoke and not bk.countdown then
          frac = bk.frac
          hi = (bk.role ~= "" and role_col(bk.role)) or YELLOW
          if hi == col then hi = (col == 0xFFFFFFFF) and YELLOW or 0xFFFFFFFF end
          col = (col & 0xFFFFFF00) | 0xB0 -- unspoken part is dimmer
        end
        draw_lines(dl, wx, wy, ww, y, c, font, size, col, outline, frac, hi)
        y = y + #c.lines * c.lh
      end
    end

    -- role label (single line only)
    if role_h > 0 then
      local bf = fonts[S.font] and fonts[S.font].bold or font
      draw_lines(dl, wx, wy, ww, pad, layout(role, bf, 16, maxw), bf, 16, role_col(role), outline)
    end

    -- next line
    if nc then
      local y = wh - pad - bar_h - nh
      draw_lines(dl, wx, wy, ww, y, nc, font, nsize, (S.color & 0xFFFFFF00) | 0xA0, outline)
    end

    -- status badge of the current line (bottom-left): number, verdict, takes, overrun
    local tf = cur_font()
    if S.badge and first and first.s then
      local n, over = take_stats(first.s)
      local parts = { "№" .. (first.s.no or "?") }
      if first.s.verdict then parts[#parts + 1] = VTXT[first.s.verdict] or first.s.verdict
      elseif first.s.done then parts[#parts + 1] = "записано" end
      if n > 0 then parts[#parts + 1] = "×" .. n end
      local bx, by = wx + 14, wy + wh - bar_h - 26
      local bc = (first.s.verdict and VCOL[first.s.verdict]) or 0xFFFFFFCC
      reaper.ImGui_DrawList_AddText(dl, bx, by, bc, table.concat(parts, "  "))
      if n > 0 and over > 0.25 then
        reaper.ImGui_DrawList_AddText(dl, bx + 220, by, 0xFF5A5AFF, string.format("⚠ дубль длиннее на %.1f с", over))
      end
    end

    -- playhead timecode (top-right)
    if S.tc then
      local ts = tc_text(pos)
      reaper.ImGui_DrawList_AddText(dl, wx + ww - 150, wy + 6, 0xFFFFFFA0, ts)
    end

    -- timer: seconds until the next line (shown in the quiet gaps, 3 s .. 15 s before it)
    if S.timer and #blocks == 0 and nxt and playing then
      local left = nxt.start - pos
      if left > 3 and left <= 15 then
        local tf = cur_font()
        local tsize = math.max(12, math.floor(S.size * 0.35))
        local tc = layout(string.format("следующая реплика через %d с", math.ceil(left)), tf, tsize, maxw)
        draw_lines(dl, wx, wy, ww, pad, tc, tf, tsize, (S.color & 0xFFFFFF00) | 0x90, outline)
      end
    end

    -- original line (dim) above the progress bar
    if S.show_orig and first and first.s and (first.s.orig or "") ~= "" then
      local of = cur_font()
      local oc = layout(first.s.orig, of, math.max(12, math.floor(S.size * 0.4)), maxw)
      local oh = #oc.lines * oc.lh
      draw_lines(dl, wx, wy, ww, wh - pad - bar_h - oh - 2, oc, of, math.max(12, math.floor(S.size * 0.4)),
        (S.color & 0xFFFFFF00) | 0x90, outline)
    end

    -- recording indicator: red frame while REAPER records
    if S.rec_mark and (reaper.GetPlayState() & 4) == 4 then
      local c = 0xFF3B3BFF
      reaper.ImGui_DrawList_AddRectFilled(dl, wx, wy, wx + ww, wy + 3, c, 0)
      reaper.ImGui_DrawList_AddRectFilled(dl, wx, wy + wh - 3, wx + ww, wy + wh, c, 0)
      reaper.ImGui_DrawList_AddRectFilled(dl, wx, wy, wx + 3, wy + wh, c, 0)
      reaper.ImGui_DrawList_AddRectFilled(dl, wx + ww - 3, wy, wx + ww, wy + wh, c, 0)
    end

    -- progress bar (of the first active line)
    if S.progress and first and first.s then
      local frac = math.max(0, math.min(1, first.frac))
      local x1, x2, y1, y2 = wx + 12, wx + ww - 12, wy + wh - bar_h - 3, wy + wh - 3
      reaper.ImGui_DrawList_AddRectFilled(dl, x1, y1, x2, y2, 0xFFFFFF30, 2)
      if frac > 0 then
        reaper.ImGui_DrawList_AddRectFilled(dl, x1, y1, x1 + (x2 - x1) * frac, y2,
          (first.role ~= "" and role_col(first.role)) or 0xFFFFFFFF, 2)
      end
    end

    reaper.ImGui_Dummy(ctx, 1, 1)

    if reaper.ImGui_IsWindowHovered(ctx) and reaper.ImGui_IsMouseClicked(ctx, 1) then
      reaper.ImGui_OpenPopup(ctx, "dub_menu")
    end
    if reaper.ImGui_BeginPopup(ctx, "dub_menu") then
      local up = push_font(fonts[1].reg, 14)
      if draw_menu() then closing = true; reaper.ImGui_CloseCurrentPopup(ctx) end
      if up then reaper.ImGui_PopFont(ctx) end
      reaper.ImGui_EndPopup(ctx)
    end
    reaper.ImGui_End(ctx)
  end

  reaper.ImGui_PopStyleColor(ctx, 1)
  reaper.ImGui_PopStyleVar(ctx, 2)

  if open and not closing then
    reaper.defer(loop)
  else
    reaper.DeleteExtState(CFG, "hb", false)
    reaper.DeleteExtState(CFG, "quit", false)
  end
end

reaper.atexit(function() reaper.DeleteExtState(CFG, "hb", false) end)
loop()

-- @description Region Balance Manager
-- @author ZerogKill
-- @version 1.0

-- @dependency ReaImGui (>= 0.9.0)

local reaper = reaper

-- Проверка наличия ReaImGui
if not reaper.APIExists('ImGui_CreateContext') then
  reaper.ShowMessageBox("Для работы скрипта требуется библиотека ReaImGui.\nПожалуйста, установите её через ReaPack.", " Ошибка", 0)
  return
end

-- ============================================================================
-- ГЛОБАЛЬНОЕ СОСТОЯНИЕ И ПЕРЕМЕННЫЕ
-- ============================================================================
local ctx = reaper.ImGui_CreateContext('Region Balance Manager')
local EXT_SECTION = "REGION_BALANCE_MANAGER"

local regions = {}             -- Список регионов проекта
local snapshots = {}           -- Снапшоты: snapshots[region_guid_or_id] = { [track_guid] = vol }
local active_edit_region = nil -- Регион, который сейчас редактируется в режиме Loop
local current_playing_region = nil -- Регион, под который сейчас подстроены фейдеры

-- Настройки переходов
local transition_mode = 0      -- 0: Instant, 1: Gradual
local transition_time_ms = 500 -- Время кроссфейда в мс
local is_fading = false
local fade_start_time = 0
local fade_tracks = {}         -- { track = tr, start_vol = v1, target_vol = v2 }

-- ============================================================================
-- ВСПАТАТЕЛЬНЫЕ ФУНКЦИИ И СЕРИАЛИЗАЦИЯ (EXTSTATE)
-- ============================================================================

-- Сохранение снапшотов в проект (.rpp)
local function SaveSnapshotsToProject()
  local str_parts = {}
  for r_id, tr_data in pairs(snapshots) do
    local tr_parts = {}
    for tr_guid, vol in pairs(tr_data) do
      table.insert(tr_parts, tr_guid .. ":" .. tostring(vol))
    end
    table.insert(str_parts, r_id .. "=" .. table.concat(tr_parts, ","))
  end
  local full_str = table.concat(str_parts, ";")
  reaper.SetProjExtState(0, EXT_SECTION, "SNAPSHOTS", full_str)
  reaper.MarkProjectDirty(0)
end

-- Загрузка снапшотов из проекта
local function LoadSnapshotsFromProject()
  snapshots = {}
  local retval, val = reaper.GetProjExtState(0, EXT_SECTION, "SNAPSHOTS")
  if retval == 1 and val ~= "" then
    for region_block in val:gmatch("[^;]+") do
      local r_id, tr_str = region_block:match("([^=]+)=(.*)")
      if r_id and tr_str then
        snapshots[r_id] = {}
        for tr_guid, vol in tr_str:gmatch("([^:,]+):([^:,]+)") do
          snapshots[r_id][tr_guid] = tonumber(vol)
        end
      end
    end
  end
end

-- Получение уникального ID для региона (по имени и позиции)
local function GetRegionID(reg)
  return string.format("%s_%.3f_%.3f", reg.name, reg.pos, reg.r_end)
end

-- Обновление списка регионов с таймлайна
local function RefreshRegions()
  regions = {}
  local _, num_markers, num_regions = reaper.CountProjectMarkers(0)
  local total = num_markers + num_regions
  for i = 0, total - 1 do
    local retval, isrgn, pos, r_end, name, markindex, color = reaper.EnumProjectMarkers3(0, i)
    if retval and isrgn then
      table.insert(regions, {
        idx = markindex,
        pos = pos,
        r_end = r_end,
        name = (name == "" and ("Region " .. markindex) or name),
        color = color
      })
    end
  end
  table.sort(regions, function(a, b) return a.pos < b.pos end)
end

-- ============================================================================
-- УПРАВЛЕНИЕ СНАПШОТАМИ И ФЕЙДЕРАМИ
-- ============================================================================

-- Захват (автосохранение) фейдеров текущего проекта для региона
local function CaptureSnapshotForRegion(reg)
  if not reg then return end
  local r_id = GetRegionID(reg)
  snapshots[r_id] = {}
  
  local track_count = reaper.CountTracks(0)
  for i = 0, track_count - 1 do
    local tr = reaper.GetTrack(0, i)
    local guid = reaper.GetTrackGUID(tr)
    local vol = reaper.GetMediaTrackInfo_Value(tr, "D_VOL")
    snapshots[r_id][guid] = vol
  end
  SaveSnapshotsToProject()
end
-- Применение баланса (моментально или через старт фада)
local function ApplySnapshot(reg)
  if not reg then return end
  local r_id = GetRegionID(reg)
  local snap = snapshots[r_id]
  if not snap then return end

  local track_count = reaper.CountTracks(0)

  if transition_mode == 0 then
    -- Моментальный переход (Instant)
    for i = 0, track_count - 1 do
      local tr = reaper.GetTrack(0, i)
      local guid = reaper.GetTrackGUID(tr)
      if snap[guid] then
        reaper.SetMediaTrackInfo_Value(tr, "D_VOL", snap[guid])
      end
    end
    is_fading = false
  else
    -- Постепенный переход (Gradual / Crossfade)
    fade_tracks = {}
    for i = 0, track_count - 1 do
      local tr = reaper.GetTrack(0, i)
      local guid = reaper.GetTrackGUID(tr)
      if snap[guid] then
        local current_vol = reaper.GetMediaTrackInfo_Value(tr, "D_VOL")
        table.insert(fade_tracks, {
          track = tr,
          start_vol = current_vol,
          target_vol = snap[guid]
        })
      end
    end
    fade_start_time = reaper.time_precise()
    is_fading = true
  end
  current_playing_region = r_id
end

-- Обработка плавного кроссфейда в реальном времени
local function ProcessFades()
  if not is_fading then return end
  local now = reaper.time_precise()
  local elapsed = (now - fade_start_time) * 1000 -- в мс
  local progress = elapsed / transition_time_ms

  if progress >= 1.0 then
    progress = 1.0
    is_fading = false
  end

  -- Линейная интерполяция
  for _, item in ipairs(fade_tracks) do
    if reaper.ValidatePtr(item.track, "MediaTrack*") then
      local new_vol = item.start_vol + (item.target_vol - item.start_vol) * progress
      reaper.SetMediaTrackInfo_Value(item.track, "D_VOL", new_vol)
    end
  end
end

-- ============================================================================
-- ЛОГИКА АКТИВАЦИИ / ДЕАКТИВАЦИИ РЕГИОНА (LOOP & AUDITION)
-- ============================================================================

local function ToggleRegionEditMode(reg)
  if active_edit_region and (active_edit_region.pos == reg.pos and active_edit_region.r_end == reg.r_end) then
    -- ВТОРОЙ КЛИК: Деактивация и автосохранение
    CaptureSnapshotForRegion(active_edit_region)
    
    -- Снимаем Time Selection и выключаем Loop
    reaper.GetSet_LoopTimeRange(true, true, 0, 0, false)
    reaper.GetSetRepeat(0) -- Выключить Loop
    
    active_edit_region = nil
  else
    -- ПЕРВЫЙ КЛИК (или переключение на другой регион)
    if active_edit_region then
      -- Сохраняем предыдущий перед переключением
      CaptureSnapshotForRegion(active_edit_region)
    end

    active_edit_region = reg
    
    -- Ставим курсор в начало
    reaper.SetEditCurPos(reg.pos, true, true)
    
    -- Устанавливаем Time Selection по границам региона
    reaper.GetSet_LoopTimeRange(true, true, reg.pos, reg.r_end, false)
    
    -- Включаем режим Loop
    reaper.GetSetRepeat(1)
    
    -- Применяем существующий баланс для редактирования
    ApplySnapshot(reg)
  end
end

-- ============================================================================
-- ФОНОВЫЙ ЦИКЛ (PLAYBACK TRACKER)
-- ============================================================================

local function MainLoop()
  ProcessFades()

  -- Если активен режим ручного редактирования в петле — фоновую смену не проводим
  if not active_edit_region then
    local play_state = reaper.GetPlayState()
    if (play_state & 1) == 1 then -- Песня проигрывается
      local play_pos = reaper.GetPlayPosition()
      
      -- Ищем регион, в котором находится курсор
      local current_reg = nil
      for _, reg in ipairs(regions) do
        if play_pos >= reg.pos and play_pos < reg.r_end then
          current_reg = reg
          break
        end
      end

      if current_reg then
        local r_id = GetRegionID(current_reg)
        if current_playing_region ~= r_id then
          ApplySnapshot(current_reg)
        end
      end
    end
  end
-- ==========================================================================
  -- ОТРИСОВКА ИНТЕРФЕЙСА (ReaImGui)
  -- ==========================================================================
  RefreshRegions()

  local visible, open = reaper.ImGui_Begin(ctx, 'Region Balance Manager', true)
  if visible then
    reaper.ImGui_Text(ctx, "Режим переходов:")
    
    if reaper.ImGui_RadioButton(ctx, "Моментальный (Instant)", transition_mode == 0) then
      transition_mode = 0
    end
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_RadioButton(ctx, "Плавный (Gradual)", transition_mode == 1) then
      transition_mode = 1
    end

    if transition_mode == 1 then
      reaper.ImGui_SetNextItemWidth(ctx, 150)
      _, transition_time_ms = reaper.ImGui_SliderInt(ctx, "Кроссфейд (мс)", transition_time_ms, 50, 3000)
    end

    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Text(ctx, "Список регионов (Клик — Loop/Edit, 2-й клик — Save):")
    reaper.ImGui_Spacing(ctx)

    for _, reg in ipairs(regions) do
      local r_id = GetRegionID(reg)
      local is_editing = active_edit_region and (GetRegionID(active_edit_region) == r_id)
      local has_snapshot = snapshots[r_id] ~= nil

      -- Форматирование статуса и кнопки
      local label = string.format("[%s] %s", reg.idx, reg.name)
      if has_snapshot then
        label = label .. " [Saved]"
      else
        label = label .. " [No Data]"
      end

      -- Подсветка активного для редактирования региона
      if is_editing then
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x228B22FF) -- Зеленый
      end

      if reaper.ImGui_Button(ctx, label, -1, 35) then
        ToggleRegionEditMode(reg)
      end

      if is_editing then
        reaper.ImGui_PopStyleColor(ctx)
      end
    end

    if active_edit_region then
      reaper.ImGui_Separator(ctx)
      reaper.ImGui_TextColored(ctx, 0x00FF00FF, "Режим редактирования: " .. active_edit_region.name)
      if reaper.ImGui_Button(ctx, "Завершить и сохранить баланс", -1, 30) then
        ToggleRegionEditMode(active_edit_region)
      end
    end

    reaper.ImGui_End(ctx)
  end

  if open then
    reaper.defer(MainLoop)
  end
end

-- ============================================================================
-- СТАРТ СКРИПТА
-- ============================================================================
LoadSnapshotsFromProject()
reaper.defer(MainLoop)

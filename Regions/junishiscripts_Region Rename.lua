-- @description Region Rename
-- @author Junishi Scripts
-- @version 1.0
-- @link X https://x.com/1496jun
-- @about
--   - Overview
--   This script provides a GUI to rename all regions within the current time selection in REAPER. It offers flexible naming options, including replacement or prefix/suffix modes, and supports sequential numbering or alphabet labels (upper/lower case).
--
--   - How to Use
--   Select a time range in REAPER that includes the regions you want to rename.
--   Run the script from the Actions List.
--   A GUI window titled "Rename Regions (Time Selection)" will appear.
--
--   - GUI Options
--   Base Name
--   Enter the text that will serve as the base for the new region names.
--
--   --- Mode
--   Replace: Replace existing region names entirely.
--   Add as Prefix: Add the base name and sequence before existing names.
--   Add as Suffix: Add the base name and sequence after existing names.
--
--   --- Sequence Type
--   none: No numbering or lettering.
--   number: Adds a numeric counter (e.g. 01, 02...).
--   alphabet (upper): Adds uppercase letters (e.g. A, B, C...).
--   alphabet (lower): Adds lowercase letters (e.g. a, b, c...).
--
--   --- Digits
--   Number of digits or letters to pad the sequence (e.g. 02, AA).
--
--   --- Applying Changes
--   Click "Apply" to rename all regions within the current time selection using the selected settings.
--
--
--   - Notes
--   The script only affects regions, not markers.
--   Only regions overlapping the current time selection are renamed.
--   Settings persist between script executions.

-- @description Rename Regions with Full GUI (ReaImGui, alphabet case merged)
-- @version 1.0.0
-- @author 1496jun https://x.com/1496jun
-- @requires ReaImGui

local ctx = reaper.ImGui_CreateContext('Region Renamer')
local section = "RenameRegionsTool"

local function get_state(key, default)
  local v = reaper.GetExtState(section, key)
  return v ~= "" and v or default
end

local base_name    = get_state("BaseName", "")
local mode_items   = {"Replace", "Add as Prefix", "Add as Suffix"}
local mode_index   = tonumber(get_state("ModeIndex", "0"))

-- 統合された選択肢
local seq_labels = {"none", "number", "alphabet (upper)", "alphabet (lower)"}
local seq_values = {"none", "num", "alpha_upper", "alpha_lower"}
local seq_index  = tonumber(get_state("SeqTypeIndex", "0"))

local digits     = tonumber(get_state("Digits", "2"))

-- アルファベット連番
local function get_alpha(index, digits, to_upper)
  index = index - 1
  local chars = {}
  local base = to_upper and 65 or 97
  repeat
    local remainder = index % 26
    table.insert(chars, 1, string.char(base + remainder))
    index = math.floor(index / 26) - 1
  until index < 0
  local result = table.concat(chars)
  if #result < digits then
    result = string.rep(string.char(base), digits - #result) .. result
  end
  return result
end

local function rename_regions()
  local start_time, end_time = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  local retval = reaper.CountProjectMarkers(0)
  local regions = {}

  for i = 0, retval - 1 do
    local _, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers(i)
    if isrgn and pos < end_time and rgnend > start_time then
      table.insert(regions, {idx = idx, pos = pos, rgnend = rgnend, name = name})
    end
  end

  reaper.Undo_BeginBlock()
  for i, region in ipairs(regions) do
    local suffix = ""
    local seq_type = seq_values[seq_index + 1]

    if seq_type == "num" then
      suffix = string.format("%0" .. digits .. "d", i)
    elseif seq_type == "alpha_upper" then
      suffix = get_alpha(i, digits, true)
    elseif seq_type == "alpha_lower" then
      suffix = get_alpha(i, digits, false)
    end

    local new_name = ""
    if mode_index == 0 then
      new_name = base_name .. suffix
    elseif mode_index == 1 then
      new_name = base_name .. region.name .. suffix
    elseif mode_index == 2 then
      new_name = region.name .. base_name .. suffix
    end

    reaper.SetProjectMarker(region.idx, true, region.pos, region.rgnend, new_name)
  end

  reaper.Undo_EndBlock("Rename regions (GUI)", -1)
  reaper.UpdateArrange()
end

-- GUIループ
local function loop()
  reaper.ImGui_SetNextWindowSize(ctx, 460, 250, reaper.ImGui_Cond_FirstUseEver())
  local visible, open = reaper.ImGui_Begin(ctx, 'Rename Regions (Time Selection)', true)

  if visible then
    reaper.ImGui_Text(ctx, "Rename regions inside current time selection.")
    _, base_name = reaper.ImGui_InputText(ctx, "Base Name", base_name)

    reaper.ImGui_Separator(ctx)

    _, mode_index = reaper.ImGui_Combo(ctx, "Mode", mode_index, table.concat(mode_items, "\0") .. "\0")
    _, seq_index  = reaper.ImGui_Combo(ctx, "Sequence Type", seq_index, table.concat(seq_labels, "\0") .. "\0")

    _, digits = reaper.ImGui_InputInt(ctx, "Digits", digits)
    if digits < 1 then digits = 1 end

    reaper.ImGui_Separator(ctx)

    if reaper.ImGui_Button(ctx, "Apply") then
      rename_regions()
      reaper.SetExtState(section, "BaseName", base_name, true)
      reaper.SetExtState(section, "ModeIndex", tostring(mode_index), true)
      reaper.SetExtState(section, "SeqTypeIndex", tostring(seq_index), true)
      reaper.SetExtState(section, "Digits", tostring(digits), true)
      open = false -- ウィンドウを閉じる
    end
  end

  reaper.ImGui_End(ctx)

  if open then
    reaper.defer(loop)
  else
    if ctx and reaper.ImGui_DestroyContext then
      pcall(reaper.ImGui_DestroyContext, ctx)
      ctx = nil
    end
  end
end

reaper.defer(loop)


-- @description Clamp velocity of selected MIDI notes
-- @author cfillion
-- @version 1.0.4
-- @changelog Add a "Always on top" option when right-clicking the title bar [p=2782891]
-- @provides [main=main,midi_inlineeditor,midi_editor] .
-- @link Forum thread https://forum.cockos.com/showthread.php?t=281810
-- @screenshot https://i.imgur.com/SPKgPo1.gif
-- @donation https://reapack.com/donate
-- @about
--   # Clamp velocity of selected MIDI notes
--
--   This script opens a window for selecting a minimum and maximum velocity to apply to selected MIDI notes. The selected MIDI notes are taken from the active MIDI editor or selected takes.
--
--   The last few applied velocity ranges are saved and may be recalled via a menu.

if not reaper.ImGui_GetBuiltinPath then
  error('ReaImGui is required')
end
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9'

if not reaper.NF_Base64_Decode then
  error('SWS v2.13.2 or newer is required')
end

local script_name = 'Clamp velocity of selected MIDI notes'
local ctx = ImGui.CreateContext(script_name)
local sans_serif = ImGui.CreateFont('sans-serif', 13)
ImGui.Attach(ctx, sans_serif)

local PRESETS_MAX = 8
local vel_min, vel_max = 0, 127
local topmost = reaper.GetExtState(script_name, 'topmost') == 'true'

function math.clamp(v, min, max)
  return v > max and max or v < min and min or v
end

local function loadPresets()
  local storage = select(2, reaper.NF_Base64_Decode(reaper.GetExtState(script_name, 'presets')))
  local size = math.min(#storage & ~1, PRESETS_MAX)
  local presets = {string.unpack(string.rep('<b', size), storage)}
  table.remove(presets) -- remove index of last read byte
  for i, val in ipairs(presets) do
    presets[i] = math.clamp(val, 0, 0x7f)
  end
  return presets
end

local presets = loadPresets()
local takes, in_me, selected_notes, pscc = {}, false
local had_any_item_active = false

local function forEachNote(callback)
  for take_i, take in ipairs(takes) do
    local take = takes[take_i]
    local note_i = -1
    while true do
      note_i = reaper.MIDI_EnumSelNotes(take, note_i)
      if note_i < 0 then break end
      callback(take, note_i)
    end
  end
end

local function update()
  local current_pscc = reaper.GetProjectStateChangeCount()
  local need_recount = pscc ~= current_pscc
  pscc = current_pscc

  local me_take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive())
  in_me = me_take ~= nil
  if me_take then
    if #takes ~= 1 or takes[1] ~= me_take then
      takes = {me_take}
      need_recount = true
    end
  elseif not need_recount then
    return
  else
    local new_takes = {}
    for i = 0, reaper.CountSelectedMediaItems(nil) - 1 do
      local take = reaper.GetActiveTake(reaper.GetSelectedMediaItem(nil, i))
      if take then
        table.insert(new_takes, take)
      end
    end
    takes = new_takes
  end

  selected_notes = 0
  forEachNote(function(take, note_i)
    if select(2, reaper.MIDI_GetNote(take, note_i)) then
      selected_notes = selected_notes + 1
    end
  end)
end

local function apply()
  local i, max_i = 1, (PRESETS_MAX * 2) - 2
  while i < #presets do
    if i >= max_i or
        presets[i] == vel_min and presets[i + 1] == vel_max then
      table.remove(presets, i)
      table.remove(presets, i)
    else
      i = i + 2
    end
  end

  table.insert(presets, 1, vel_min)
  table.insert(presets, 2, vel_max)

  local format = string.rep('<b', #presets)
  local storage = string.pack(format, table.unpack(presets))
  reaper.SetExtState(script_name, 'presets', reaper.NF_Base64_Encode(storage, true), true)

  reaper.PreventUIRefresh(1)
  forEachNote(function(take, note_i)
    local vel = select(8, reaper.MIDI_GetNote(take, note_i))
    reaper.MIDI_SetNote(take, note_i, nil, nil, nil, nil, nil, nil,
      math.clamp(vel, vel_min, vel_max), true)
  end)
  reaper.Undo_OnStateChange(script_name)
  reaper.PreventUIRefresh(-1)
end

local function shortcuts(...)
  if had_any_item_active then
    return false
  end

  for i = 1, select('#', ...) do
    if ImGui.IsKeyPressed(ctx, select(i, ...), false) then
      return true
    end
  end

  return false
end

local function presetsCombo()
  if #presets < 1 then
    return ImGui.TextDisabled(ctx, 'No saved recent ranges')
  end

  if not ImGui.BeginTable(ctx, '##columns', 2) then
    return
  end

  for i = 1, #presets, 2 do
    local preset_min, preset_max = presets[i], presets[i + 1]
    ImGui.PushID(ctx, i)
    ImGui.TableNextRow(ctx)
    ImGui.TableNextColumn(ctx)
    if ImGui.Selectable(ctx, ('Min: %d'):format(preset_min),
        vel_min == preset_min and vel_max == preset_max,
        ImGui.SelectableFlags_SpanAllColumns) then
      vel_min, vel_max = preset_min, preset_max
    end
    ImGui.TableNextColumn(ctx)
    ImGui.Text(ctx, ('Max: %d'):format(preset_max))
    ImGui.PopID(ctx)
  end

  ImGui.EndTable(ctx)
end

local function window()
  if ImGui.BeginPopupContextItem(ctx) then
    if ImGui.MenuItem(ctx, 'Always on top', nil, topmost) then
      topmost = not topmost
      reaper.SetExtState(script_name, 'topmost', tostring(topmost), true)
    end
    ImGui.EndPopup(ctx)
  end

  ImGui.SetNextItemWidth(ctx, 255)
  vel_min, vel_max = select(2, ImGui.DragIntRange2(ctx, 'Value range', vel_min, vel_max,
    nil, 0, 0x7f, 'Min: %d', 'Max: %d', ImGui.SliderFlags_AlwaysClamp))
  ImGui.SameLine(ctx)
  if ImGui.BeginCombo(ctx, '##preset', '', ImGui.ComboFlags_NoPreview) then
    presetsCombo()
    ImGui.EndCombo(ctx)
  end
  ImGui.SetItemTooltip(ctx, 'Recent values')

  ImGui.Text(ctx, 'Drag or double-click to enter a specific value')
  ImGui.Spacing(ctx)

  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 5, 0)
  local keep_open = true
  if ImGui.Button(ctx, 'OK') or
      shortcuts(ImGui.Key_Enter, ImGui.Key_KeypadEnter) then
    apply()
    keep_open = false
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Apply') then
    apply()
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Cancel') or shortcuts(ImGui.Key_Escape) then
    keep_open = false
  end
  ImGui.SameLine(ctx)
  local target = in_me and 'MIDI editor' or 'selected takes'
  ImGui.TextDisabled(ctx, ('(%d selected notes in %s)'):format(selected_notes, target))
  ImGui.PopStyleVar(ctx)
  return keep_open
end

local function loop()
  local flags = ImGui.WindowFlags_AlwaysAutoResize
  if topmost then flags = flags | ImGui.WindowFlags_TopMost end

  ImGui.PushFont(ctx, sans_serif)
  local visible, open = ImGui.Begin(ctx, script_name, true, flags)
  if visible then
    update()
    if not window() then open = false end
    ImGui.End(ctx)
  end
  ImGui.PopFont(ctx)

  had_any_item_active = ImGui.IsAnyItemActive(ctx)

  if open then
    reaper.defer(loop)
  end
end

reaper.defer(loop)

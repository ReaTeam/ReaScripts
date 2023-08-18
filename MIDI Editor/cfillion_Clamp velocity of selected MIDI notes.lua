-- @description Clamp velocity of selected MIDI notes
-- @author cfillion
-- @version 1.0
-- @provides [main=main,midi_editor,midi_inlineeditor] .
-- @link Forum thread https://forum.cockos.com/showthread.php?t=281810
-- @screenshot https://i.imgur.com/IdK4mL1.gif
-- @donation https://reapack.com/donate
-- @about
--   # Clamp velocity of selected MIDI notes
--
--   This script opens a window for selecting a minimum and maximum velocity to apply to selected MIDI notes. The selected MIDI notes are taken from the active MIDI editor or selected takes.
--
--   The last few applied velocity ranges are saved and may be recalled via a menu.

dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.8')

if not reaper.NF_Base64_Decode then
  error('SWS v2.13.2 or newer is required')
end

local ImGui = {}
for name, func in pairs(reaper) do
  name = name:match('^ImGui_(.+)$')
  if name then ImGui[name] = func end
end

local script_name <const> = 'Clamp velocity of selected MIDI notes'
local ctx = ImGui.CreateContext(script_name)
local sans_serif = ImGui.CreateFont('sans-serif', 13)
ImGui.Attach(ctx, sans_serif)

local PRESETS_MAX <const> = 8
local vel_min, vel_max = 0, 127

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
  local need_recount = pscc ~= reaper.GetProjectStateChangeCount()
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

  if not need_recount then return end

  selected_notes = 0
  forEachNote(function(take, note_i)
    if select(2, reaper.MIDI_GetNote(take, note_i)) then
      selected_notes = selected_notes + 1
    end
  end)
end

local function apply()
  local i = 1
  while i < #presets do
    if i >= (PRESETS_MAX * 2) - 2 or presets[i] == vel_min and presets[i + 1] == vel_max then
      table.remove(presets, i)
      table.remove(presets, i)
    else
      i = i + 2
    end
  end

  table.insert(presets, 1, vel_min)
  table.insert(presets, 2, vel_max)

  local format = string.rep('<b', #presets)
  reaper.SetExtState(script_name, 'presets',
    reaper.NF_Base64_Encode(string.pack(format, table.unpack(presets)), true), true)

  reaper.PreventUIRefresh(1)
  forEachNote(function(take, note_i)
    local vel = select(8, reaper.MIDI_GetNote(take, note_i))
    reaper.MIDI_SetNote(take, note_i, nil, nil, nil, nil, nil, nil,
      math.clamp(vel, vel_min, vel_max), true)
  end)
  reaper.Undo_OnStateChange(script_name)
  reaper.PreventUIRefresh(-1)
end

local function tooltip(text)
  if ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_DelayShort()) and ImGui.BeginTooltip(ctx) then
    ImGui.Text(ctx, text)
    ImGui.EndTooltip(ctx)
  end
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
        ImGui.SelectableFlags_SpanAllColumns()) then
      vel_min, vel_max = preset_min, preset_max
    end
    ImGui.TableNextColumn(ctx)
    ImGui.Text(ctx, ('Max: %d'):format(preset_max))
    ImGui.PopID(ctx)
  end

  ImGui.EndTable(ctx)
end

local function window()
  local rv
  ImGui.SetNextItemWidth(ctx, -115)
  vel_min, vel_max = select(2, ImGui.DragInt2(ctx, 'Velocity range', vel_min, vel_max,
    nil, 0, 0x7f, nil, ImGui.SliderFlags_AlwaysClamp()))
  if ImGui.IsItemDeactivatedAfterEdit(ctx) then
    vel_min, vel_max = math.min(vel_min, vel_max), math.max(vel_min, vel_max)
  end
  ImGui.SameLine(ctx)
  if ImGui.BeginCombo(ctx, '##preset', '', ImGui.ComboFlags_NoPreview()) then
    presetsCombo()
    ImGui.EndCombo(ctx)
  end
  tooltip('Recent values')

  ImGui.Text(ctx, '(Double click to enter a specific value)')
  ImGui.Spacing(ctx)

  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing(), 5, 0)
  local keep_open = true
  if ImGui.Button(ctx, 'OK') then
    apply()
    keep_open = false
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Apply') then
    apply()
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Cancel') then
    keep_open = false
  end
  ImGui.SameLine(ctx)
  local target = in_me and 'MIDI editor' or 'selected takes'
  ImGui.TextDisabled(ctx, ('(%d selected notes in %s)'):format(selected_notes, target))
  ImGui.PopStyleVar(ctx)
  return keep_open
end

local function loop()
  ImGui.PushFont(ctx, sans_serif)
  local visible, open = ImGui.Begin(ctx, script_name, true, ImGui.WindowFlags_AlwaysAutoResize())
  if visible then
    update()
    if not window() then open = false end
    ImGui.End(ctx)
  end
  ImGui.PopFont(ctx)

  if open then
    reaper.defer(loop)
  end
end

reaper.defer(loop)

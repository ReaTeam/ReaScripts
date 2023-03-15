-- @description Joystick inspector
-- @author cfillion
-- @version 1.0
-- @screenshot https://i.imgur.com/WuON2x7.gif
-- @donation https://reapack.com/donate

dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.8.4')

local script_name = 'Joystick inspector'
local joystick, devices = {}, nil
local FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float()
local ctx = reaper.ImGui_CreateContext(script_name, reaper.ImGui_ConfigFlags_DockingEnable())
local font = reaper.ImGui_CreateFont('sans-serif', 13)
reaper.ImGui_Attach(ctx, font)

local c_act    = reaper.ImGui_GetColor(ctx, reaper.ImGui_Col_ButtonActive())
local c_inact  = 0x111111FF
local c_border = reaper.ImGui_GetColor(ctx, reaper.ImGui_Col_Border())
local c_text   = reaper.ImGui_GetColor(ctx, reaper.ImGui_Col_Text())

local function updateDevices()
  devices = {}
  for i = 0, math.huge do
    -- joystick_enum is CPU intensive!
    local guid, name = reaper.joystick_enum(i)
    if not guid then return end
    devices[i + 1] = { guid=guid, name=name }
  end
end

local function setDevice(device)
  if joystick.instance then
    reaper.joystick_destroy(joystick.instance)
  end
  joystick.instance = reaper.joystick_create(device.guid)
  joystick.guid, joystick.name = device.guid, device.name
  joystick.buttons, joystick.axes, joystick.povs =
    reaper.joystick_getinfo(joystick.instance)
end

local function deviceSelect()
  local preview = ''
  if joystick.name then
    preview = ('%s %s'):format(joystick.name, joystick.guid)
  end
  reaper.ImGui_SetNextItemWidth(ctx, -50)
  if not reaper.ImGui_BeginCombo(ctx, 'Device', preview) then
    if devices then devices = nil end
    return
  end
  if not devices then updateDevices() end
  if #devices == 0 then
    reaper.ImGui_TextDisabled(ctx, 'No joysticks are currently available.')
    reaper.ImGui_EndCombo(ctx)
    return
  end
  if reaper.ImGui_BeginTable(ctx, 'devices', 2) then
    local sf = reaper.ImGui_SelectableFlags_SpanAllColumns()
    for i, device in ipairs(devices) do
      reaper.ImGui_TableNextRow(ctx)
      reaper.ImGui_TableNextColumn(ctx)
      reaper.ImGui_PushID(ctx, i)
      if reaper.ImGui_Selectable(ctx, device.name, joystick.guid == device.guid, sf) then
        setDevice(device)
      end
      reaper.ImGui_TableNextColumn(ctx)
      reaper.ImGui_TextDisabled(ctx, device.guid)
      reaper.ImGui_PopID(ctx)
    end
    reaper.ImGui_EndTable(ctx)
  end
  reaper.ImGui_EndCombo(ctx)
end

local function autoWrap(n, sz, func)
  local item_spacing_x =
    reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing())
  local window_visible_x2 =
    reaper.ImGui_GetWindowPos(ctx) + reaper.ImGui_GetWindowContentRegionMax(ctx)
  for i = 0, n do
    func(i)
    local x2 = reaper.ImGui_GetItemRectMax(ctx)
    if i < n and x2 + item_spacing_x + sz < window_visible_x2 then
      reaper.ImGui_SameLine(ctx)
    end
  end
end

local function inspectButtons(dl)
  reaper.ImGui_SeparatorText(ctx, 'Buttons')
  if joystick.buttons < 1 then
    reaper.ImGui_TextDisabled(ctx, 'No buttons available')
    return
  end

  local btn_mask = reaper.joystick_getbuttonmask(joystick.instance)
  local btn_sz = 32
  autoWrap(joystick.buttons - 1, btn_sz, function(i)
    local active = btn_mask & (1<<i) ~= 0
    reaper.ImGui_Dummy(ctx, btn_sz, btn_sz)
    local x1, y1 = reaper.ImGui_GetItemRectMin(ctx)
    local x2, y2 = reaper.ImGui_GetItemRectMax(ctx)
    reaper.ImGui_DrawList_AddRectFilled(dl, x1, y1, x2, y2,
                                        active and c_act or c_inact)
    reaper.ImGui_DrawList_AddRect(dl, x1, y1, x2, y2, c_border)

    local label = i + 1
    local label_w, label_h = reaper.ImGui_CalcTextSize(ctx, label)
    local label_x, label_y = x1 + ((btn_sz - label_w) / 2),
                             y1 + ((btn_sz - label_h) / 2)
    reaper.ImGui_DrawList_AddText(dl, label_x, label_y, c_text, label)
  end)
end

local function inspectAxes(dl)
  reaper.ImGui_SeparatorText(ctx, 'Axes')
  if joystick.axes < 1 then
    reaper.ImGui_TextDisabled(ctx, 'No axes available')
    return
  end

  if not reaper.ImGui_BeginTable(ctx, 'axes', 3) then return end
  reaper.ImGui_TableSetupColumn(ctx, 'ID',      reaper.ImGui_TableColumnFlags_WidthFixed())
  reaper.ImGui_TableSetupColumn(ctx, 'Display', reaper.ImGui_TableColumnFlags_WidthStretch())
  reaper.ImGui_TableSetupColumn(ctx, 'Value',   reaper.ImGui_TableColumnFlags_WidthFixed(), 70)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PlotHistogram(),
    reaper.ImGui_GetStyleColor(ctx, reaper.ImGui_Col_ButtonActive()))
  local height = reaper.ImGui_GetFontSize(ctx)
  for i = 0, joystick.axes - 1 do
    local value = reaper.joystick_getaxis(joystick.instance, i)
    reaper.ImGui_TableNextRow(ctx)
    reaper.ImGui_TableNextColumn(ctx)
    reaper.ImGui_Text(ctx, i + 1)
    reaper.ImGui_TableSetColumnIndex(ctx, 2)
    reaper.ImGui_Text(ctx, ('%+.6f'):format(value))
    reaper.ImGui_TableSetColumnIndex(ctx, 1)
    reaper.ImGui_ProgressBar(ctx, (value + 1) / 2, -FLT_MIN, height, '')

    local x1, y1 = reaper.ImGui_GetItemRectMin(ctx)
    local x2, y2 = reaper.ImGui_GetItemRectMax(ctx)
    local x = x1 + ((x2 - x1) // 2)
    reaper.ImGui_DrawList_AddLine(dl, x, y1-1, x, y2-1, 0xFFFFFF7F)
  end
  reaper.ImGui_PopStyleColor(ctx)
  reaper.ImGui_EndTable(ctx)
end

local function inspectPOVs(dl)
  reaper.ImGui_SeparatorText(ctx, 'POVs')
  if joystick.povs < 1 then
    reaper.ImGui_TextDisabled(ctx, 'No POVs available')
    return
  end

  local pov_sz = 64
  local radius = pov_sz / 2
  autoWrap(joystick.povs - 1, pov_sz, function(i)
    local value = reaper.joystick_getpov(joystick.instance, i)
    reaper.ImGui_BeginGroup(ctx)
    reaper.ImGui_Dummy(ctx, pov_sz, pov_sz)
    local x1, y1 = reaper.ImGui_GetItemRectMin(ctx)
    x1, y1 = x1 + radius, y1 + radius

    local is_dir = value >= 0 and value <= 360
    local active = value ~= 655.35 and not is_dir
    reaper.ImGui_DrawList_AddCircleFilled(dl, x1, y1, radius,
                                          active and c_act or c_inact)
    if is_dir then
      local x2 = x1 + (radius *  math.sin(math.pi * 2 * value / 360))
      local y2 = y1 + (radius * -math.cos(math.pi * 2 * value / 360))
      reaper.ImGui_DrawList_AddLine(dl, x1, y1, x2, y2, c_act, 3)
    end
    reaper.ImGui_DrawList_AddCircle(dl, x1, y1, radius, c_border)

    local label = i + 1
    local label_w, label_h = reaper.ImGui_CalcTextSize(ctx, label)
    local label_x, label_y = x1 + ((pov_sz - label_w) / 2) - radius,
                             y1 + ((pov_sz - label_h) / 2) - radius
    reaper.ImGui_DrawList_AddText(dl, label_x, label_y, c_text, label)

    local value_w = reaper.ImGui_CalcTextSize(ctx, value)
    local cur_x = reaper.ImGui_GetCursorPosX(ctx)
    reaper.ImGui_SetCursorPosX(ctx, cur_x + (pov_sz - value_w) * 0.5)
    reaper.ImGui_Text(ctx, value)
    reaper.ImGui_EndGroup(ctx)
  end)
end

local function inspector()
  if not reaper.joystick_update(joystick.instance) then
    reaper.ImGui_TextColored(ctx, 0xFF2211FF, 'Hardware state update failed')
  end

  local dl = reaper.ImGui_GetWindowDrawList(ctx)
  inspectButtons(dl)
  inspectAxes(dl)
  inspectPOVs(dl)
end

local function loop()
  reaper.ImGui_PushFont(ctx, font)
  reaper.ImGui_SetNextWindowSize(ctx, 500, 320, reaper.ImGui_Cond_FirstUseEver())
  local visible, open = reaper.ImGui_Begin(ctx, script_name, true)
  if visible then
    deviceSelect()
    if joystick.instance then
      inspector()
    else
      reaper.ImGui_Spacing(ctx)
      reaper.ImGui_Text(ctx, 'Select a joystick device to begin.')
    end
    reaper.ImGui_End(ctx)
  end
  if open then
    reaper.defer(loop)
  end
  reaper.ImGui_PopFont(ctx)
end
reaper.defer(loop)

reaper.atexit(function()
  if joystick.instance then
    reaper.joystick_destroy(joystick.instance)
  end
end)

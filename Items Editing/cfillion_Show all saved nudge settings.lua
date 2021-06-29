-- @description Show all saved nudge settings
-- @author cfillion
-- @version 3.0.1
-- @changelog Update the user interface to ReaImGui v0.5
-- @provides
--   .
--   [main] . > cfillion_Nudge left by selected saved nudge dialog settings.lua
--   [main] . > cfillion_Nudge right by selected saved nudge dialog settings.lua
-- @link cfillion.ca https://cfillion.ca
-- @screenshot https://i.imgur.com/5o3OIyf.png
-- @donation https://www.paypal.me/cfillion
-- @about
--   # Show all saved nudge settings
--
--   This script allows viewing, editing and using all nudge setting presets in
--   a single window.
--
--   The edit feature opens the native nudge settings dialog with the current
--   settings filled. The new settings are automatically saved into the selected
--   1-8 slot once the native dialog is closed. Trigger the edit feature a second
--   time to close the native dialog without saving.
--
--   In addition to the GUI script, two additional actions are provided to nudge
--   left or right by the last selected settings in the script interface.
--
--   ## Keyboard Shortcuts
--
--   - Switch to a different nudge setting with the **0-8** keys
--   - Edit the current nudge setting by pressing **n**
--   - Nudge with the **left/right arrow** keys
--   - Close the script with **Escape**
--
--   ## Caveats
--
--   The "Last" tab may be out of sync with the effective last nudge settings.
--   This is because the native "Nudge left/right by saved nudge dialog settings X"
--   actions do not save the nudge settings in reaper.ini when they change the
--   last used settings.
--
--   There is no reliable way for a script to detect whether the last nudge
--   settings are out of sync. A workaround for forcing REAPER to save its
--   settings is to open and close the native nudge dialog.
--
--   Furthermore, REAPER does not store the nudge amout when using the "Set" mode
--   in the native nudge dialog. The script displays "N/A" in this case and the
--   nudge left/right actions are unavailable.

local r = reaper

local WHAT_MAP = {'position', 'left trim', 'left edge', 'right trim', 'contents',
  'duplicate', 'edit cursor', 'end position'}

local UNIT_MAP =  {'milliseconds', 'seconds', 'grid units', 'notes',
  [17]='measures.beats', [18]='samples', [19]='frames', [20]='pixels',
  [21]='item lengths', [22]='item selections'}

local NOTE_MAP = {'1/256', '1/128', '1/64', '1/32T', '1/32', '1/16T', '1/16',
  '1/8T', '1/8', '1/4T', '1/4', '1/2', 'whole'}

local NUDGEDLG_ACTION = 41228
local SAVE_ACTIONS    = {last=0,     bank1=41271, bank2=41283}
local LNUDGE_ACTIONS  = {last=41250, bank1=41279, bank2=41291}
local RNUDGE_ACTIONS  = {last=41249, bank1=41275, bank2=41287}

local KEY_ESCAPE = 0x1b
local KEY_LEFT   = 0x25
local KEY_RIGHT  = 0x27
local KEY_F1     = 0x70

local FLT_MIN, FLT_MAX = r.ImGui_NumericLimits_Float()
local RO        = r.ImGui_InputTextFlags_ReadOnly()
local WND_FLAGS = r.ImGui_WindowFlags_NoScrollbar() |
                  r.ImGui_WindowFlags_NoScrollWithMouse()

local EXT_SECTION, EXT_LAST_SLOT = 'cfillion_show_nudge_settings', 'last_slot'

local isEditing  = false
local saved      = 0
local setting    = {}

local scriptName = ({r.get_action_context()})[2]:match("([^/\\_]+).lua$")
local iniFile    = r.get_ini_file()

function iniRead(key, n)
  if n > 0 then
    key = string.format('%s_%d', key, n)
  end

  return tonumber(({r.BR_Win32_GetPrivateProfileString(
    'REAPER', key, '0', iniFile)})[2])
end

function boolValue(val, off, on)
  if not off then off = 'OFF' end
  if not on then on = 'ON' end
  return val == 0 and off or on
end

function mapValue(val, strings)
  return strings[val] or string.format('%d (Unknown)', val)
end

function isAny(val, ...)
  for _,n in ipairs{...} do
    if val == n then
      return true
    end
  end

  return false
end

function snapTo(unit)
  if isAny(unit, 3, 21, 22) then
    return 'grid'
  elseif unit == 17 then -- measures.beats
    return 'bar'
  end

  return 'unit'
end

function loadSetting(n, reload)
  if setting.n == n and not reload then return end

  setting = {n=n}
  r.SetExtState(EXT_SECTION, EXT_LAST_SLOT, n, true)

  local nudge  = iniRead('nudge', n)
  setting.mode = nudge & 1
  setting.what = (nudge >> 12) + 1
  setting.unit = (nudge >> 4 & 0xFF) + 1
  setting.snap = nudge & 2
  setting.rel  = nudge & 4

  if setting.unit >= 4 and setting.unit <= 16 then
    setting.note = setting.unit - 3
    setting.unit = 4
  end

  if setting.mode == 0 then
    setting.amount = iniRead('nudgeamt', n)
  else
    setting.amount = '(N/A)'
  end

  setting.copies = iniRead('nudgecopies', n)
end

function action(ids)
  local base

  if setting.n == 0 then
    return ids.last
  elseif setting.n < 5 then
    base = ids.bank1
  else
    base = ids.bank2
  end

  return base + ((setting.n - 1) % 4)
end

function nudge(actions)
  if setting.mode ~= 1 then
    r.Main_OnCommand(action(actions), 0)
  end
end

function setAsLast()
  local selection, count = {}, r.CountSelectedMediaItems(0)

  for i=0,count - 1 do
    local item = r.GetSelectedMediaItem(0, 0)
    table.insert(selection, item)
    r.SetMediaItemSelected(item, false)
  end

  nudge(RNUDGE_ACTIONS)

  for _,item in ipairs(selection) do
    r.SetMediaItemSelected(item, true)
  end
end

function editCurrent()
  if isEditing then
    -- prevent saveCurrent() from being called when the nudge dialog is manually closed
    isEditing = false
    r.Main_OnCommand(NUDGEDLG_ACTION, 0)
    loadSetting(setting.n, true)
    return
  elseif setting.n > 0 then
    setAsLast()
  end

  r.Main_OnCommand(NUDGEDLG_ACTION, 0)
end

function saveCurrent()
  if setting.n > 0 then
    r.Main_OnCommand(action(SAVE_ACTIONS), 0)
    saved = os.time()
  end

  loadSetting(setting.n, true)
end

function help()
  if not r.ReaPack_GetOwner then
    r.MB('This feature requires ReaPack v1.2 or newer.', scriptName, 0)
    return
  end

  local owner = r.ReaPack_GetOwner(({r.get_action_context()})[2])

  if not owner then
    r.MB(string.format(
      'This feature is unavailable because "%s" was not installed using ReaPack.',
      scriptName), scriptName, 0)
    return
  end

  r.ReaPack_AboutInstalledPackage(owner)
  r.ReaPack_FreeEntry(owner)
end

function detectEdit()
  local state = r.GetToggleCommandState(NUDGEDLG_ACTION) == 1

  if isEditing and not state then
    saveCurrent()
  end

  isEditing = state
end

function calcItemWidth(text, hasFrame)
  local framePadding = hasFrame and r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_FramePadding()) or 0
  return r.ImGui_CalcTextSize(ctx, text) + (framePadding * 2)
end

function rtlPos(...)
  local args = {...}
  local spacing = r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing())
  local width = 3
  for _, itemWidth in ipairs(args) do
    width = width + itemWidth
  end
  width = width + (spacing * #args)
  return r.ImGui_GetWindowWidth(ctx) - width
end

function button(label, shortcut, active)
  if active then
    local color = 0x96afe1ff
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), color)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), color)
  end
  local rv = r.ImGui_Button(ctx, label) or
    r.ImGui_IsKeyPressed(ctx, shortcut)
  if active then
    r.ImGui_PopStyleColor(ctx, 2)
  end
  return rv
end

function draw()
  for n = 0, 8 do
    if button(n == 0 and 'Last' or n, string.byte(n), setting.n == n) then
      loadSetting(n)
    end
    r.ImGui_SameLine(ctx)
  end

  local editWidth, helpWidth, savedWidth =
    calcItemWidth('Edit', true), calcItemWidth('?', true), calcItemWidth('Saved!')

  if saved > os.time() - 2 then
    r.ImGui_SameLine(ctx, rtlPos(savedWidth, editWidth, helpWidth))
    r.ImGui_Text(ctx, 'Saved!')
    r.ImGui_SameLine(ctx)
  end
  r.ImGui_SameLine(ctx, rtlPos(editWidth, helpWidth))
  if button('Edit', string.byte('N'), isEditing) then editCurrent() end
  r.ImGui_SameLine(ctx, rtlPos(helpWidth))
  if button('?', KEY_F1) then help() end

  r.ImGui_SetNextItemWidth(ctx, 70)
  r.ImGui_InputText(ctx, '##mode', boolValue(setting.mode, 'Nudge', 'Set'), RO)
  r.ImGui_SameLine(ctx)

  r.ImGui_SetNextItemWidth(ctx, 100)
  r.ImGui_InputText(ctx, '##what', mapValue(setting.what, WHAT_MAP), RO)
  r.ImGui_SameLine(ctx)

  r.ImGui_Text(ctx, boolValue(setting.mode, 'by:', 'to:'))
  r.ImGui_SameLine(ctx)

  r.ImGui_SetNextItemWidth(ctx, 70)
  r.ImGui_InputText(ctx, '##amount', setting.amount, RO)
  r.ImGui_SameLine(ctx)

  if setting.note then
    r.ImGui_SetNextItemWidth(ctx, 50)
    r.ImGui_InputText(ctx, '##note', mapValue(setting.note, NOTE_MAP), RO)
    r.ImGui_SameLine(ctx)
  end

  r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
  r.ImGui_InputText(ctx, '##unit', mapValue(setting.unit, UNIT_MAP), RO)

  r.ImGui_AlignTextToFramePadding(ctx)
  r.ImGui_Text(ctx,
    ('Snap to %s: %s'):format(snapTo(setting.unit), boolValue(setting.snap)))
  r.ImGui_SameLine(ctx, nil, 20)

  if setting.mode == 1 and isAny(setting.what, 1, 6, 8) then
    r.ImGui_Text(ctx, ('Relative set: %s'):format(boolValue(setting.rel)))
  elseif setting.what == 6 then
    r.ImGui_Text(ctx, ('Copies: %s'):format(setting.copies))
  end

  if setting.mode == 0 then
    local leftText, rightText = '< Nudge left', 'Nudge right >'
    local leftWidth, rightWidth =
      calcItemWidth(leftText, true), calcItemWidth(rightText, true)
    r.ImGui_SameLine(ctx, rtlPos(leftWidth, rightWidth))
    if button(leftText,  KEY_LEFT)  then nudge(LNUDGE_ACTIONS) end
    r.ImGui_SameLine(ctx, rtlPos(rightWidth))
    if button(rightText, KEY_RIGHT) then nudge(RNUDGE_ACTIONS) end
  else
    local text = '(Nudge unavailable in Set mode)'
    r.ImGui_SameLine(ctx, rtlPos(calcItemWidth(text)))
    r.ImGui_TextDisabled(ctx, text)
  end
end

function contextMenu()
  local dock_id = r.ImGui_GetWindowDockID(ctx)
  if not reaper.ImGui_BeginPopupContextWindow(ctx) then return end
  if r.ImGui_BeginMenu(ctx, 'Dock window') then
    if r.ImGui_MenuItem(ctx, 'Floating', nil, dock_id == 0) then
      set_dock_id = 0
    end
    for i = 0, 15 do
      if r.ImGui_MenuItem(ctx, ('Docker %d'):format(i + 1), nil, dock_id == ~i) then
        set_dock_id = ~i
      end
    end
    r.ImGui_EndMenu(ctx)
  end
  r.ImGui_Separator(ctx)
  if r.ImGui_MenuItem(ctx, 'About/help', 'F1', false, r.ReaPack_GetOwner ~= nil) then
    help()
  end
  if r.ImGui_MenuItem(ctx, 'Close', 'Escape') then
    exit = true
  end
  r.ImGui_EndPopup(ctx)
end

function loop()
  detectEdit()

  r.ImGui_PushFont(ctx, font)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(),  0xffffffff)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(), 0xffffffff)

  r.ImGui_SetNextWindowSize(ctx, 475, 117, r.ImGui_Cond_FirstUseEver())
  r.ImGui_SetNextWindowSizeConstraints(ctx, 400, 112, FLT_MAX, FLT_MAX)
  if set_dock_id then
    r.ImGui_SetNextWindowDockID(ctx, set_dock_id)
    set_dock_id = nil
  end
  local visible, open = r.ImGui_Begin(ctx, scriptName, true, WND_FLAGS)
  if visible then
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Border(),        0x2a2a2aff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),        0xdcdcdcff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),  0x787878ff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), 0xdcdcdcff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(),       0xffffffff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderHovered(), 0x96afe1ff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_PopupBg(),       0xffffffff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),          0x2a2a2aff)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameBorderSize(),  1)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(),     7, 4)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(),      7, 7)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(),   10, 10)

    contextMenu()
    draw()

    r.ImGui_PopStyleVar(ctx, 4)
    r.ImGui_PopStyleColor(ctx, 8)

    r.ImGui_End(ctx)
  end

  r.ImGui_PopStyleColor(ctx, 2)
  r.ImGui_PopFont(ctx)

  if exit or r.ImGui_IsKeyPressed(ctx, KEY_ESCAPE) then
    open = false
  end

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

function previousSlot()
  local slot = tonumber(r.GetExtState(EXT_SECTION, EXT_LAST_SLOT))

  if slot and slot >= 0 and slot <= 8 then
    return slot
  else
    return 0
  end
end

loadSetting(previousSlot())

if scriptName:match('Nudge.+by selected') then
  r.defer(function() end) -- disable automatic undo point
  nudge(scriptName:match('left') and LNUDGE_ACTIONS or RNUDGE_ACTIONS)
  return
end

if not r.ImGui_CreateContext then
  r.MB('This script requires ReaImGui. Install it from ReaPack > Browse packages.', scriptName, 0)
  return
end

ctx = r.ImGui_CreateContext(scriptName, r.ImGui_ConfigFlags_DockingEnable())

local size = r.GetAppVersion():match('OSX') and 12 or 14
font = r.ImGui_CreateFont('sans-serif', size)
r.ImGui_AttachFont(ctx, font)

r.defer(loop)

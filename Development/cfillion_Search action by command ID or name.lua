-- @description Search action by command ID or name
-- @author cfillion
-- @version 2.0.3
-- @changelog Internal code cleanup
-- @link Forum thread https://forum.cockos.com/showthread.php?t=226107
-- @screenshot https://i.imgur.com/yqkvZvf.gif
-- @donation https://reapack.com/donate

local SCRIPT_NAME = select(2, reaper.get_action_context()):match("([^/\\_]+)%.lua$")
local AL_SECTIONS = {
  { id=0,     name='Main'                   },
  { id=100,   name='Main (alt recording)'   },
  { id=32060, name='MIDI Editor'            },
  { id=32061, name='MIDI Event List Editor' },
  { id=32062, name='MIDI Inline Editor'     },
  { id=32063, name='Media Explorer'         },
}

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9'
local font = ImGui.CreateFont('sans-serif', 13)
local ctx = ImGui.CreateContext(SCRIPT_NAME)
ImGui.Attach(ctx, font)

local FLT_MIN, FLT_MAX = ImGui.NumericLimits_Float()
local section, commandId, actionName = AL_SECTIONS[1], '', ''

local function iterateActions()
  local i = 0

  return function()
    local retval, name = reaper.CF_EnumerateActions(section.id, i, '')
    if retval > 0 then
      i = i + 1
      return retval, name
    end
  end
end

local function findById()
  local numericId = reaper.NamedCommandLookup(commandId)
  actionName = reaper.CF_GetCommandText(section.id, numericId)
end

local function findByName()
  for id, name in iterateActions(section) do
    if name == actionName then
      local namedId = id and reaper.ReverseNamedCommandLookup(id)
      commandId = namedId and ('_' .. namedId) or tostring(id)
      return
    end
  end

  commandId = ''
end

local function form()
  local rv

  ImGui.TableSetupColumn(ctx, '', ImGui.TableColumnFlags_WidthFixed)
  ImGui.TableSetupColumn(ctx, '', ImGui.TableColumnFlags_WidthStretch)

  ImGui.TableNextRow(ctx)
  ImGui.TableNextColumn(ctx)
  ImGui.AlignTextToFramePadding(ctx)
  ImGui.Text(ctx, 'Section:')
  ImGui.TableNextColumn(ctx)
  ImGui.SetNextItemWidth(ctx, -FLT_MIN)
  if ImGui.BeginCombo(ctx, '##section', section.name) then
    for _, s in ipairs(AL_SECTIONS) do
      if ImGui.Selectable(ctx, s.name, s.id == section.id) then
        section = s
        local oldName = actionName
        findById()
        if #actionName < 1 then
          actionName = oldName
          findByName()
        end
      end
    end
    ImGui.EndCombo(ctx)
  end

  ImGui.TableNextRow(ctx)
  ImGui.TableNextColumn(ctx)
  ImGui.AlignTextToFramePadding(ctx)
  ImGui.Text(ctx, 'Command ID:')
  ImGui.TableNextColumn(ctx)
  ImGui.SetNextItemWidth(ctx, -FLT_MIN)
  rv, commandId = ImGui.InputText(ctx, '##command_id', commandId)
  if rv then findById() end

  ImGui.TableNextRow(ctx)
  ImGui.TableNextColumn(ctx)
  ImGui.AlignTextToFramePadding(ctx)
  ImGui.Text(ctx, 'Action name:')
  ImGui.TableNextColumn(ctx)
  ImGui.SetNextItemWidth(ctx, -FLT_MIN)
  rv, actionName = ImGui.InputText(ctx, '##action_name', actionName)
  if rv then findByName() end
end

local function buttons()
  local found = #commandId > 0 and #actionName > 0
  ImGui.BeginDisabled(ctx, not found)
  if ImGui.Button(ctx, 'Copy command ID') then
    ImGui.SetClipboardText(ctx, commandId)
  end
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Copy action name') then
    ImGui.SetClipboardText(ctx, actionName)
  end
  if not found and (#commandId > 0 or #actionName > 0) then
    ImGui.SameLine(ctx)
    ImGui.AlignTextToFramePadding(ctx)
    ImGui.Text(ctx, 'Action not found.')
  end
  ImGui.EndDisabled(ctx)
end

local function loop()
  ImGui.PushFont(ctx, font)
  ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg, 0xffffffff)

  ImGui.SetNextWindowSize(ctx, 442, 131, ImGui.Cond_FirstUseEver)
  local visible, open = ImGui.Begin(ctx, SCRIPT_NAME, true)
  if visible then
    ImGui.PushStyleColor(ctx, ImGui.Col_Border,        0x2a2a2aff)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button,        0xdcdcdcff)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,  0x787878ff)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0xdcdcdcff)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,       0xffffffff)
    ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered, 0x96afe1ff)
    ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg,       0xffffffff)
    ImGui.PushStyleColor(ctx, ImGui.Col_Text,          0x2a2a2aff)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize,  1)

    if ImGui.BeginTable(ctx, '##layout', 2) then
      form()
      ImGui.EndTable(ctx)
    end
    ImGui.Spacing(ctx)
    buttons()

    ImGui.PopStyleVar(ctx)
    ImGui.PopStyleColor(ctx, 8)
    ImGui.End(ctx)
  end

  ImGui.PopStyleColor(ctx)
  ImGui.PopFont(ctx)

  if open and not ImGui.IsKeyPressed(ctx, ImGui.Key_Escape) then
    reaper.defer(loop)
  end
end

reaper.defer(loop)

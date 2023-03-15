-- @description Search action by command ID or name
-- @author cfillion
-- @version 2.0.2
-- @changelog Enable ReaImGui's backward compatibility shims
-- @link Forum thread https://forum.cockos.com/showthread.php?t=226107
-- @screenshot https://i.imgur.com/yqkvZvf.gif
-- @donation https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD

dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.7')

local FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float()
local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local AL_SECTIONS = {
  { id=0,     name='Main'                   },
  { id=100,   name='Main (alt recording)'   },
  { id=32060, name='MIDI Editor'            },
  { id=32061, name='MIDI Event List Editor' },
  { id=32062, name='MIDI Inline Editor'     },
  { id=32063, name='Media Explorer'         },
}

local ctx = reaper.ImGui_CreateContext(SCRIPT_NAME)
local font = reaper.ImGui_CreateFont('sans-serif', 13)
reaper.ImGui_AttachFont(ctx, font)

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

  reaper.ImGui_TableSetupColumn(ctx, '', reaper.ImGui_TableColumnFlags_WidthFixed())
  reaper.ImGui_TableSetupColumn(ctx, '', reaper.ImGui_TableColumnFlags_WidthStretch())

  reaper.ImGui_TableNextRow(ctx)
  reaper.ImGui_TableNextColumn(ctx)
  reaper.ImGui_AlignTextToFramePadding(ctx)
  reaper.ImGui_Text(ctx, 'Section:')
  reaper.ImGui_TableNextColumn(ctx)
  reaper.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
  if reaper.ImGui_BeginCombo(ctx, '##section', section.name) then
    for _, s in ipairs(AL_SECTIONS) do
      if reaper.ImGui_Selectable(ctx, s.name, s.id == section.id) then
        section = s
        local oldName = actionName
        findById()
        if #actionName < 1 then
          actionName = oldName
          findByName()
        end
      end
    end
    reaper.ImGui_EndCombo(ctx)
  end

  reaper.ImGui_TableNextRow(ctx)
  reaper.ImGui_TableNextColumn(ctx)
  reaper.ImGui_AlignTextToFramePadding(ctx)
  reaper.ImGui_Text(ctx, 'Command ID:')
  reaper.ImGui_TableNextColumn(ctx)
  reaper.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
  rv, commandId = reaper.ImGui_InputText(ctx, '##command_id', commandId)
  if rv then findById() end

  reaper.ImGui_TableNextRow(ctx)
  reaper.ImGui_TableNextColumn(ctx)
  reaper.ImGui_AlignTextToFramePadding(ctx)
  reaper.ImGui_Text(ctx, 'Action name:')
  reaper.ImGui_TableNextColumn(ctx)
  reaper.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
  rv, actionName = reaper.ImGui_InputText(ctx, '##action_name', actionName)
  if rv then findByName() end
end

local function buttons()
  local found = #commandId > 0 and #actionName > 0
  reaper.ImGui_BeginDisabled(ctx, not found)
  if reaper.ImGui_Button(ctx, 'Copy command ID') then
    reaper.ImGui_SetClipboardText(ctx, commandId)
  end
  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, 'Copy action name') then
    reaper.ImGui_SetClipboardText(ctx, actionName)
  end
  if not found and (#commandId > 0 or #actionName > 0) then
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_AlignTextToFramePadding(ctx)
    reaper.ImGui_Text(ctx, 'Action not found.')
  end
  reaper.ImGui_EndDisabled(ctx)
end

local function loop()
  reaper.ImGui_PushFont(ctx, font)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0xffffffff)

  reaper.ImGui_SetNextWindowSize(ctx, 442, 131, reaper.ImGui_Cond_FirstUseEver())
  local visible, open = reaper.ImGui_Begin(ctx, SCRIPT_NAME, true)
  if visible then
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(),        0x2a2a2aff)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),        0xdcdcdcff)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(),  0x787878ff)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xdcdcdcff)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),       0xffffffff)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(), 0x96afe1ff)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(),       0xffffffff)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(),          0x2a2a2aff)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameBorderSize(),  1)

    if reaper.ImGui_BeginTable(ctx, '##layout', 2) then
      form()
      reaper.ImGui_EndTable(ctx)
    end
    reaper.ImGui_Spacing(ctx)
    buttons()

    reaper.ImGui_PopStyleVar(ctx)
    reaper.ImGui_PopStyleColor(ctx, 8)
    reaper.ImGui_End(ctx)
  end

  reaper.ImGui_PopStyleColor(ctx)
  reaper.ImGui_PopFont(ctx)

  if open and not reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape()) then
    reaper.defer(loop)
  else
    reaper.ImGui_DestroyContext(ctx)
  end
end

loop()

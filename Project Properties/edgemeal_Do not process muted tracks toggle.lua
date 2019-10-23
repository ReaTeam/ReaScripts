-- @description Do not process muted tracks toggle
-- @author Edgemeal
-- @version 1.0
-- @donation Donate https://www.paypal.me/Edgemeal
-- @about This is a toggle only, to persist the setting set in REAPER preferences.

function ToolbarButton(enable)
  local _, _, section_id, command_id = reaper.get_action_context()
  reaper.SetToggleCommandState(section_id, command_id, enable)
  reaper.RefreshToolbar2(section_id, command_id)
end

function Main()
  local val = reaper.SNM_GetIntConfigVar("norunmute", 0)
  if not ((val & 1) == 1) then -- enable
    reaper.SNM_SetIntConfigVar("norunmute", 1)
    ToolbarButton(1)
  else -- disable
    reaper.SNM_SetIntConfigVar("norunmute", 0)
    ToolbarButton(0)
  end
end

if not reaper.APIExists('SNM_GetIntConfigVar') then
  reaper.MB("The SWS extension is required for this script.", "ERROR", 0)
else
  Main()
end
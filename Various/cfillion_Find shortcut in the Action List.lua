-- @description Find shortcut in the Action List
-- @author cfillion
-- @version 1.0
-- @link Forum thread https://forum.cockos.com/showthread.php?t=216102
-- @donation Donate via PayPal https://paypal.me/cfillion
-- @about
--   # Find shortcut in the Action List
--
--   This script opens the "Find Key or MIDI Controller" window in the Action List.
--
--   The js_ReaScriptAPI extension is required and must be installed in order to use this script.

reaper.defer(function() end) -- disable implicit undo point

if not reaper.JS_Window_Find then
  local button = reaper.ShowMessageBox(
    "This script requires the js_ReaScriptAPI extension. Do you want to install it now?",
    "js_ReaScriptAPI not found", 4)

  if button == 6 then
    local repo = {
      name='ReaTeam Extensions',
      url='https://github.com/ReaTeam/Extensions/raw/master/index.xml'
    }

    if not reaper.ReaPack_GetRepositoryInfo(repo.name) then
      -- this won't be needed in ReaPack 1.2.2+
      reaper.ReaPack_AddSetRepository(repo.name, repo.url, true, 2)
      reaper.ReaPack_ProcessQueue(true)
    end

    reaper.ReaPack_BrowsePackages('js_ReaScriptAPI')
  end

  return
end

reaper.ShowActionList()

local title = reaper.JS_Localize('Actions', 'DLG_274')
local actionList = reaper.JS_Window_Find(title, false)
reaper.JS_Window_OnCommand(actionList, 9) -- Find shortcut

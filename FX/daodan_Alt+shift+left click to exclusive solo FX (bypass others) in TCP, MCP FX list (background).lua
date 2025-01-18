-- @description Alt+shift+left click to exclusive solo FX (bypass others) in TCP, MCP FX list (background)
-- @author daodan
-- @version 1.0
-- @link Forum thread https://forum.cockos.com/showthread.php?p=2809719
-- @about
--   # Alt+shift+left click to exclusive solo FX (bypass others) in TCP, MCP FX list (background)
--
--   While script running you can alt+shift+left click FX in TCP, MCP FX list to solo this FX, i.e. bypass other FXs on this track.

function Checks()
  if reaper.APIExists("CF_GetSWSVersion") == false then
    reaper.ShowMessageBox("Please, install SWS/S&M extension","Checks failed",0)
    return
  end
  if reaper.APIExists("JS_ReaScriptAPI_Version") == false then
    reaper.ShowMessageBox("Please, install js_ReaScriptAPI extension","Checks failed",0)
    return
  end
  return 1
end

function SetButtonState(set)
  local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
  reaper.SetToggleCommandState( sec, cmd, set or 0 )
  reaper.RefreshToolbar2( sec, cmd )
end

local mousePressed = 0
local function main()
  local mouse = reaper.JS_Mouse_GetState(-1)
  if mouse & 25 == 25 then --check for alt+shift+left click
    local x, y = reaper.GetMousePosition()
    local trk, info = reaper.GetThingFromPoint(x, y)
    if mousePressed==0 then
      mousePressed = 1
      if info == 'mcp.fxparm' or info == 'mcp.fxlist' or info == 'tcp.fxlist' or info == 'tcp.fxparm' then
        reaper.Main_OnCommand(41110,0) -- Track: Select track under mouse
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_FXBYPALL2"),0) --SWS/S&M: Bypass all FX for selected tracks
      end
    end
  else
    mousePressed = 0
  end
  reaper.defer(main)
end

if not Checks() then return end
SetButtonState(1)
main()
reaper.atexit(SetButtonState)

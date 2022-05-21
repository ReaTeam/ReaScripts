-- @description Select floating FX track, unselect others
-- @author Edgemeal
-- @version 1.00
-- @donation Donate via PayPal https://www.paypal.me/Edgemeal

local prev_fgw = nil

function ToolbarButton(enable)
  local _, _, section_id, command_id = reaper.get_action_context()
  reaper.SetToggleCommandState(section_id, command_id, enable)
  reaper.RefreshToolbar2(section_id, command_id)
end

function Select_floating_fx_track()
  local fgw = reaper.BR_Win32_GetForegroundWindow()
  if prev_fgw ~= fgw then
    prev_fgw = fgw
    for i = 0, reaper.CountTracks(0)-1 do
      local track = reaper.GetTrack(0,i)
      for fx = 0, reaper.TrackFX_GetCount(track)-1 do
        if fgw == reaper.TrackFX_GetFloatingWindow(track,fx) then
          reaper.Main_OnCommand(40297, 0)      -- Track: Unselect (clear selection of) all tracks
          reaper.SetTrackSelected(track, true) -- Select track for floating fx
          return
        end
      end
    end
  end
end

function Main()
  Select_floating_fx_track()
  reaper.defer(Main)
end

function Exit() ToolbarButton(0) end

if not reaper.APIExists('BR_Win32_GetForegroundWindow') then
  reaper.MB('The SWS extension is required for this script.', 'Missing API', 0)
  reaper.defer(function () end)
else
  reaper.atexit(Exit)
  ToolbarButton(1)
  Main()
end

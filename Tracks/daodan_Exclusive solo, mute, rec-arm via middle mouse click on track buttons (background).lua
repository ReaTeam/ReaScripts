-- @description Exclusive solo, mute, rec-arm via middle mouse click on track buttons (background)
-- @author daodan
-- @version 1.1
-- @changelog Added option to keep rec armed but monitoring only tracks armed. Enabled by default.
-- @link Forum thread https://forum.cockos.com/showthread.php?t=297698
-- @about
--   # Exclusive solo, mute, rec-arm via middle mouse click on track buttons (background)
--
--   While script running you can middle mouse click on solo, mute, rec-arm track buttons to perform exclusive solo, mute, rec-arm on this track.\
--   Replicates default behaviour of ctrl+alt+left click on solo, mute buttons and alt+left click on rec-arm button.

--USER SETTINGS--
ignoreMonOnlyR = true -- set true to keep tracks with record mode set to "Record: disable (input monitoring only)" armed
--USER SETTINGS END--

function Checks()
  if reaper.APIExists("JS_ReaScriptAPI_Version") == false then
    reaper.ShowMessageBox("Please, install js_ReaScriptAPI extension","Checks failed",0)
    return
  end
  return 1
end

function SetButtonState(set)
  local is_new_value, filename, sec, cmd, mode, resolution, val = reaper.get_action_context()
  reaper.SetToggleCommandState(sec, cmd, set or 0)
  reaper.RefreshToolbar2(sec, cmd)
end

function disableRecArmAllTracks()
  trackCount = reaper.CountTracks(0)
  for trackidx=0, trackCount-1 do
    local tr = reaper.GetTrack(0, trackidx)
    if reaper.GetMediaTrackInfo_Value(tr,'I_RECMODE')==2 and ignoreMonOnlyR then
      --ignore monitoring only tracks
    else
      reaper.SetMediaTrackInfo_Value( tr, "I_RECARM", 0)
    end
  end
end

local mousePressed = 0
local function main()
  local mouse = reaper.JS_Mouse_GetState(-1)
  local modifMouse = 64 --64 for middle mouse, +8 for shift, +32: Windows (Windows), +16 Alt... See gfx VARIABLES > gfx.mouse_cap
  if mouse & modifMouse == modifMouse then --check for middle click
    local x, y = reaper.GetMousePosition()
    local track, info = reaper.GetThingFromPoint(x, y)
    if mousePressed==0 then
      mousePressed = 1
      --solo--
      if info == 'tcp.solo' or info == 'mcp.solo' then
        reaper.PreventUIRefresh(1)
          reaper.Main_OnCommand(40340,0) -- unsolo all tracks
          if reaper.IsTrackSelected(track) == true then
            selTracksCount = reaper.CountSelectedTracks( 0 )
            for seltrackidx=0, selTracksCount-1 do
              track = reaper.GetSelectedTrack( 0, seltrackidx )
              reaper.SetMediaTrackInfo_Value(track, 'I_SOLO', 2)
            end
          else
            reaper.SetMediaTrackInfo_Value(track, 'I_SOLO', 2)
          end
        reaper.PreventUIRefresh(-1)
      --mute--
      elseif info == 'tcp.mute' or info == 'mcp.mute' then
        reaper.PreventUIRefresh(1)
          reaper.Main_OnCommand(40339,0) -- unmute all tracks
          if reaper.IsTrackSelected(track) == true then
            selTracksCount = reaper.CountSelectedTracks( 0 )
            for seltrackidx=0, selTracksCount-1 do
              track = reaper.GetSelectedTrack( 0, seltrackidx )
              reaper.SetMediaTrackInfo_Value(track, 'B_MUTE', 1)
            end
          else
            reaper.SetMediaTrackInfo_Value(track, 'B_MUTE', 1)
          end
        reaper.PreventUIRefresh(-1)
      --recarm--
      elseif info == 'tcp.recarm' or info == 'mcp.recarm' then
        reaper.PreventUIRefresh(1)
          disableRecArmAllTracks()-- unarm all tracks for recording (except mon only if set)
          if reaper.IsTrackSelected(track) == true then
            selTracksCount = reaper.CountSelectedTracks( 0 )
            for seltrackidx=0, selTracksCount-1 do
              track = reaper.GetSelectedTrack( 0, seltrackidx )
              reaper.SetMediaTrackInfo_Value(track, 'I_RECARM', 1)
            end
          else
            reaper.SetMediaTrackInfo_Value(track, 'I_RECARM', 1)
          end
        reaper.PreventUIRefresh(-1)
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

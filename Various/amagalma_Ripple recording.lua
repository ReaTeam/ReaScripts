-- @description Ripple recording
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showthread.php?t=244437
-- @screenshot https://i.ibb.co/7R037Y1/amagalma-Ripple-Recording.gif
-- @donation https://www.paypal.me/amagalma
-- @about It acts exactly like the normal Record button, but changes behavior according to the ripple mode


-- 0: off
-- 1: 40310 ripple editing per-track
-- 2: 40311 ripple editing all tracks
local ripple_mode = reaper.GetToggleCommandState( 40310 ) == 1 and 1 or
              ( reaper.GetToggleCommandState( 40311 ) == 1 and 2 or 0 )

if ripple_mode > 0 then

  local cur_pos = reaper.GetCursorPositionEx( 0 )

  -- 1: 40252 Set record mode to normal
  -- 2: 40076 Set record mode to time selection auto-punch
  -- 3: 40253 Set record mode to selected item auto-punch
  local rec_mode = reaper.GetToggleCommandState( 40252 ) == 1 and 1 or
             ( reaper.GetToggleCommandState( 40076 ) == 1 and 2 or
               reaper.GetToggleCommandState( 40253 ) == 1 and 3 )

  local function SetTrackAsLastTouched( track )
    if track then
      reaper.SetOnlyTrackSelected( track )
      reaper.Main_OnCommand(40914, 0) -- Set first selected track as last touched track
    end
  end
  local last_touched = false

  local function WhenRecordingStops()
    if reaper.GetPlayState() & 4 ~= 4 then -- Stopped recording
      reaper.Main_OnCommand(40699, 0) -- Cut items
      reaper.SetEditCurPos( cur_pos, true, true )
      SetTrackAsLastTouched(last_touched)
      reaper.Main_OnCommand(42398, 0) -- Paste items/tracks
      return
    else
      reaper.defer(WhenRecordingStops)
    end
  end

  reaper.atexit(function()
    if rec_mode == 1 then
      reaper.Main_OnCommand(40252, 0) -- Set record mode to normal
    elseif rec_mode == 2 then
      reaper.Main_OnCommand(40076, 0) -- Set record mode to time selection auto-punch
    else
      reaper.Main_OnCommand(40253, 0) -- Set record mode to selected item auto-punch
    end
  end)

  local function SplitAllOrRecArmedTracksAtEditCursor()
    local track_cnt = reaper.CountTracks( 0 )
    if track_cnt == 0 then return end
    for tr = 0, track_cnt - 1 do
      local track = reaper.GetTrack( 0 , tr )
      local rec_armed = reaper.GetMediaTrackInfo_Value( track, "I_RECARM" ) == 1
      if (ripple_mode == 1 and rec_armed) or ripple_mode == 2
      then
        if not last_touched and rec_armed then
          last_touched = track
        end
        local pos = cur_pos - 1 -- dummy value
        local i = 0
        local item_cnt = reaper.GetTrackNumMediaItems( track )
        while pos < cur_pos and i < item_cnt do
          local item = reaper.GetTrackMediaItem( track, i )
          local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
          pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
          if pos+length > cur_pos then
            reaper.SplitMediaItem( item, cur_pos )
          end
          i = i + 1
        end
      end
    end
  end

  SplitAllOrRecArmedTracksAtEditCursor()
  reaper.Main_OnCommand(40252, 0) -- Set record mode to normal
  reaper.Main_OnCommand(40043, 0) -- Go to end of project
  reaper.Main_OnCommand(1013, 0) -- Record
  WhenRecordingStops()

else
  reaper.Main_OnCommand(1013, 0) -- Record
end

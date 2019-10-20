-- @description Set audio source of all sends on selected tracks to all channels
-- @author cfillion
-- @version 1.0
-- @donation https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD

local UNDO_STATE_TRACKCFG = 1

local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local category = 0

reaper.Undo_BeginBlock()

for ti = 0, reaper.CountSelectedTracks(0) - 1 do
  local track = reaper.GetSelectedTrack(0, ti)
  local nchan = reaper.GetMediaTrackInfo_Value(track, 'I_NCHAN')

  local src_chan = 0
  if nchan >= 4 then
    src_chan = nchan << 9
  end

  for si = 0, reaper.GetTrackNumSends(track, category) - 1 do
    local dest = reaper.BR_GetMediaTrackSendInfo_Track(track, category, si, 1)
    local dest_nchan = reaper.GetMediaTrackInfo_Value(dest, 'I_NCHAN')

    if dest_nchan < nchan then
      reaper.SetMediaTrackInfo_Value(dest, 'I_NCHAN', nchan)
    end

    reaper.SetTrackSendInfo_Value(track, category, si, 'I_SRCCHAN', src_chan)
  end
end

reaper.Undo_EndBlock(script_name, UNDO_STATE_TRACKCFG)

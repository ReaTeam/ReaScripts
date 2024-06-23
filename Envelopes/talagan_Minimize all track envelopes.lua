--[[
@description Minimize all track envelopes
@version 1.0
@author Ben 'Talagan' Babut
@license MIT
@donation
  https://www.paypal.com/donate/?business=3YEZMY9D6U8NC&no_recurring=1&currency_code=EUR
@changelog
  - Initial release
@about
  This script simply minimizes all track envelopes (it sets their heights to their minimum)
--]]

local function perform()

  -- Modifying the envelope state chunk does not allow to have an undo entry
  -- ... so undo is not possible, it seems. Let's still handle it as we should.
  reaper.Undo_BeginBlock();

  -- Loop on all tracks
  local tn = reaper.CountTracks(0);
  local ti = 0
  for ti = 0, tn-1, 1 do
    local track = reaper.GetTrack(0,ti);
    local en    = reaper.CountTrackEnvelopes(track);

    -- Loop on each envelope for the current track
    for ei = 0, en-1, 1 do
      local evl = reaper.GetTrackEnvelope(track, ei);

      -- ... and patch the height through the state chunk
      _, str = reaper.GetEnvelopeStateChunk(evl, "", false);
      str = str:gsub("\nLANEHEIGHT %d+ %d+\n", "\nLANEHEIGHT 0 0\n");
      reaper.SetEnvelopeStateChunk(evl,str);
    end
  end

  reaper.Undo_EndBlock("Minimized all track envelopes",-1);
end

perform()

-- @description Tempo Envelope - select env point under edit cursor (deselect all others)
-- @author Audiobabble
-- @version 1.0
-- @about Selects the master track tempo envelope point currently under the cursor and deselects all other tempo envelope points, regardless of focus on other envelopes in the project

tr = reaper.GetMasterTrack( 0 )
env = reaper.GetTrackEnvelopeByName( tr, 'Tempo map' )
curpos = reaper.GetCursorPosition()

-- function for rounding to x decimal places
function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end


-- Main Script
for ptidx=1,reaper.CountTempoTimeSigMarkers( 0 ) do
  -- get all envelope points in tempo map
  _, timeIn, valueIn, shapeIn, tensionIn, _ = reaper.GetEnvelopePoint(env, ptidx)
  if round(curpos, 2) == round(timeIn, 2) then
    -- if at cursor then select
    reaper.SetEnvelopePoint(env, ptidx, timeIn, valueIn, shapeIn, tensionIn, true)
  else
    -- if not at cursor, then deselect
    reaper.SetEnvelopePoint(env, ptidx, timeIn, valueIn, shapeIn, tensionIn, false)
  end
end
reaper.UpdateTimeline()


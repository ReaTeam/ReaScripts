-- @description nail the track envelopes heights
-- @author bobobo
-- @version 1.0
-- @about
--   # Nail the track envelope heights
--
--   if you are in urge to fix the trackenvelopes height you can use
--   this lua-script
--
--   Mousewheel with CTRL on TCP in/decreases all including the trackenvelopes
--   running the script before nails the track envelope height so to envelope won’t change in height while mousewheel+CTRL on TCP

--[[
 * ReaScript Name: nail the track envelopes heights
 * About: take all trackenvelopes and fixes the height (adding one pixel and substract afterweards)
 * In TCP when you mousewhell with Ctrl kicked in all tracks will in/decrfease heigt togethrer with all shown traxckenvelopes.
 * If the trackenvelopes got an explicit heigt this heigt is fixed
 * Author: bobobo (standing on the shoulder of giants, say the REAPER forum)
 * Author URI: https://reaper.bobobo.de
 * website: https://bobobo-git.github.io/REAPER/
 * Licence: GPL v3
 * Forum Thread: Script (Lua): Scripts for Layering
 * REAPER: 7.0 pre 36
 
]]


unique_tracks = {}
trackcount = reaper.CountTracks()-1

for i = 0, trackcount do
  track = reaper.GetTrack(0, i) 
  envcount = reaper.CountTrackEnvelopes(track)-1
  for j = 0, envcount do
    --doit(track,j)
    env=reaper.GetTrackEnvelope(track, j)
    hh=reaper.GetEnvelopeInfo_Value(env, "I_TCPH")
    ok, env_chunk = reaper.GetEnvelopeStateChunk(env, "", false)
    hhn=hh+1 
    env_chunk = env_chunk:gsub('LANEHEIGHT %d+ ', 'LANEHEIGHT '..math.tointeger(hhn)..' ')
    reaper.SetEnvelopeStateChunk(env, env_chunk, 0) 
    env_chunk = env_chunk:gsub('LANEHEIGHT %d+ ', 'LANEHEIGHT '..math.tointeger(hh)..' ')
    reaper.SetEnvelopeStateChunk(env, env_chunk, 0) 
  end
end


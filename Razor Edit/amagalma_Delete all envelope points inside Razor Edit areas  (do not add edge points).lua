-- @description Delete all envelope points inside Razor Edit areas (do not add edge points)
-- @author amagalma
-- @version 1.01
-- @changelog Added support for Master Track
-- @link https://forum.cockos.com/showthread.php?t=250759
-- @donation https://www.paypal.me/amagalma
-- @about Differs from the native action because it does not add edge points.


local track_cnt = reaper.CountTracks(0)
local envs, env_cnt = {}, 0
local tracks = {}

for tr = 0, track_cnt - 1 do
  tracks[tr+1] = reaper.GetTrack(0, tr)
end
tracks[track_cnt+1] = reaper.GetMasterTrack( 0 )

for tr = 1, track_cnt + 1 do
  local track = tracks[tr]
  local _, area = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
  if area ~= "" then
    local arSt, arEn
    for str in area:gmatch("(%S+)") do
      if not arSt then arSt = str
      elseif not arEn then arEn = str
      else
        if str ~= '""' then
          env_cnt = env_cnt + 1
          envs[env_cnt] = { reaper.GetTrackEnvelopeByChunkName( track, str:sub(2,-1) ),
                        tonumber(arSt), tonumber(arEn) }
        end
        arSt, arEn = nil, nil
      end
    end
  end
end

if env_cnt == 0 then return reaper.defer(function() end) end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh( 1 )
for e = 1, env_cnt do
  reaper.DeleteEnvelopePointRange( envs[e][1] , envs[e][2] , envs[e][3]  )
end
reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()
reaper.Undo_EndBlock( "Delete envelope points in RE areas", 1 )

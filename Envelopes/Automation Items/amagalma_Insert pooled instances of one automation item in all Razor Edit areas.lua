-- @description Insert pooled instances of one automation item in all Razor Edit areas
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Inserts pooled instances of one automation item in  every Razor Edit area
--   - It does not differentiate between envelopes. It will fill all the envelopes that have a RE area with the same pooled AI.
--   - Option inside the script to keep or remove the RE areas (default: remove)

----------------------------- USER SETTINGS -----------------------------------------------
local removeRE = 1 -- set to 0 to keep Razor Edit areas, or to 1 to remove them
-------------------------------------------------------------------------------------------

local track_cnt = reaper.CountTracks(0)
if track_cnt == 0 then return reaper.defer(function() end) end

local envs, env_cnt = {}, 0
local tracks = {}

for tr = 0, track_cnt - 1 do
  local track = reaper.GetTrack(0, tr)
  local _, area = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
  if area ~= "" then
    local arSt, arEn
    if not tracks[track] then tracks[track] = true end
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
local pool_id
for e = 1, env_cnt do
  local id = reaper.InsertAutomationItem( envs[e][1], pool_id or -1, envs[e][2], envs[e][3]-envs[e][2] )
  if not pool_id then
    pool_id = reaper.GetSetAutomationItemInfo( envs[e][1], id, "D_POOL_ID", 0, false )
  end
end

if removeRE == 1 then
  for track in pairs(tracks) do
    reaper.GetSetMediaTrackInfo_String( track, "P_RAZOREDITS", "", true )
  end
end

reaper.PreventUIRefresh( -1 )
reaper.Undo_EndBlock( "AI: Insert pooled instances in RE areas", 1 )

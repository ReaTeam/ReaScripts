-- @description Insert pooled instances of automation items in all Razor Edit areas for each envelope type (according to envelope name)
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.com/paypalme/amagalma
-- @about
--   # Inserts pooled instances of automation items in  every Razor Edit area. Each envelope type (according to its name) will get the same AI pooled instance. Different types get different pooled instances.
--
--    - Option inside the script to keep or remove the RE areas (default: remove)


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
          local env = reaper.GetTrackEnvelopeByChunkName( track, str:sub(2,-1) )
          local _, fxid = reaper.Envelope_GetParentTrack( env )
          local _, env_name = reaper.GetEnvelopeName( env )
          env_cnt = env_cnt + 1
          if not envs[env_name] then envs[env_name] = {false, {}} end
          envs[env_name][2][#envs[env_name][2]+1] = { env,
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

for _, t in pairs(envs) do
  for e = 1, #t[2] do
    local id = reaper.InsertAutomationItem( t[2][e][1], t[1] or -1, t[2][e][2], t[2][e][3]-t[2][e][2] )
    if not t[1] then
      t[1] = reaper.GetSetAutomationItemInfo( t[2][e][1], id, "D_POOL_ID", 0, false )
    end
  end
end

if removeRE == 1 then
  for track in pairs(tracks) do
    reaper.GetSetMediaTrackInfo_String( track, "P_RAZOREDITS", "", true )
  end
end

reaper.PreventUIRefresh( -1 )
reaper.Undo_EndBlock( "AI: Insert pooled instances in RE areas", 1 )

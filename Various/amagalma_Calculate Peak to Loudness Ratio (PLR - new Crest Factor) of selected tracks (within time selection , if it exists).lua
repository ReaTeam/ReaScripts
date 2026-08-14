-- @description Calculate Peak to Loudness Ratio (PLR - new Crest Factor) of selected tracks (within time selection , if it exists)
-- @author amagalma
-- @version 1.03
-- changelog
--      - If any track receives in higher channels then the calculation is done on 1&2 only
--      - Better handling of unnamed or silent tracks
-- @donation https://www.paypal.me/amagalma


local track_cnt = reaper.CountSelectedTracks( 0 )
if track_cnt == 0 then return end

local track_names, tn_cnt = {}, 0

for i = 0, track_cnt - 1 do
  local track = reaper.GetSelectedTrack( 0, i )
  local _, name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
  if name == "" then
    tn_cnt = tn_cnt + 1
    track_names[tn_cnt] = track
    local id = reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" )
    reaper.GetSetMediaTrackInfo_String( track, "P_NAME", string.format("Track %i",id), true )
  end
end

local ts_start, ts_end = reaper.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
local InTS = false

if ts_start ~= ts_end then
  InTS = gfx.showmenu( "#Calculate PLR of selected tracks||Within Time Selection|Whole Project Length" )
  if InTS == 0 then
    return
  else
    InTS = InTS == 2
  end
end

local renderclosewhendone = reaper.SNM_GetIntConfigVar( "renderclosewhendone", -1 )
local original = renderclosewhendone
if renderclosewhendone ~= -1 then
  local mask = (1<<8)|(1<<9)|(1<<10)
  if renderclosewhendone & mask ~= 256 then -- settings are not correct
    restore = true
    renderclosewhendone = (renderclosewhendone & ~mask)|(1<<8)
    reaper.SNM_SetIntConfigVar( "renderclosewhendone", renderclosewhendone )
  end
end

local floor, ceil = math.floor, math.ceil
local function rnd(num)
  num = tonumber(num)
  if num >= 0 then return string.format("%.2f",floor(num * 100 + 0.5) / 100)
  else return string.format("%.2f",ceil(num * 100 - 0.5) / 100)
  end
end

local function ReceivesOnHigherChannelsExist()
  for i = 0, track_cnt - 1 do
    local track = reaper.GetSelectedTrack(0, i)
    if reaper.GetMediaTrackInfo_Value(track, "I_NCHAN") > 2 then
      for s = 0, reaper.GetTrackNumSends( track, -1 ) - 1 do
        if reaper.GetTrackSendInfo_Value( track, -1, s, "I_DSTCHAN" ) > 0 then
          return true
        end
      end
    end
  end
  return false
end

reaper.atexit(function()
  if restore then
    reaper.SNM_SetIntConfigVar( "renderclosewhendone", original )
  end
  if tn_cnt ~= 0 then
    for i = 1, tn_cnt do
      reaper.GetSetMediaTrackInfo_String( track_names[i], "P_NAME", "", true )
    end
  end
end)

local stereo = not ReceivesOnHigherChannelsExist()

local plr, plr_cnt = {}, 0

local ok, info = reaper.GetSetProjectInfo_String( 0, "RENDER_STATS", 
      InTS and (stereo and "43811" or "42439") or (stereo and "43810" or "42438"), false )
if not ok then return end

for entry in info:gmatch("[^;]+") do
  local e_name, value = entry:match("(.+):(.+)")
  if e_name == "FILE" then
    plr_cnt = plr_cnt + 1
    plr[plr_cnt] = {name = value}
  elseif e_name == "TRUEPEAK" then
    plr[plr_cnt].trpk = rnd(value)
  elseif e_name == "LUFSI" then
    plr[plr_cnt].lufsi = rnd(value)
  end
end

for i = plr_cnt, 1, -1 do
  if plr[i].trpk and plr[i].lufsi then
    plr[i].plr = rnd(tonumber(plr[i].trpk) - tonumber(plr[i].lufsi))
  else
    table.remove( plr, i )
    plr_cnt = plr_cnt - 1
  end
end

if plr_cnt ~= 0 then

  local format = "%-35s | %10s | %10s | %10s |\n"

  reaper.ShowConsoleMsg(string.format("--- Peak to Loudness Ratio of selected tracks%s ---\n", (InTS and ", within time selection" or "")))
  reaper.ShowConsoleMsg(string.rep("-", 76) .. "\n")
  reaper.ShowConsoleMsg(string.format(format, "Track", "PLR", "True Peak", "LUFS-I"))
  reaper.ShowConsoleMsg(string.rep("-", 76) .. "\n")

  for i = 1, plr_cnt do
    local p = plr[i]
    if #p.name > 35 then p.name = string.sub(p.name, 1, 32) .. "..." end
    reaper.ShowConsoleMsg(string.format( format, p.name, p.plr, p.trpk, p.lufsi ))
  end

  reaper.ShowConsoleMsg(string.rep("-", 76) .. "\n\n")
end

reaper.defer(function() end)

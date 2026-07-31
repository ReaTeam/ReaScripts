-- @description Calculate Peak to Loudness Ratio (PLR - new Crest Factor) of selected tracks (within time selection , if it exists)
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma


local track_cnt = reaper.CountSelectedTracks( 0 )
if track_cnt == 0 then return end

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

local plr, plr_cnt = {}, 0

local ok, info = reaper.GetSetProjectInfo_String( 0, "RENDER_STATS", InTS and "42439" or "42438", false )
if not ok then return end

for name, truepeak, lufsi in info:gmatch("FILE:([^%;]+).-TRUEPEAK:([^%;]+).-LUFSI:([^%;]+)") do
  if name then
    plr_cnt = plr_cnt + 1
    plr[plr_cnt] = {
      trpk = rnd(truepeak),
      lufsi = rnd(lufsi),
      plr = rnd(tonumber(truepeak) - tonumber(lufsi)),
      name = name,
    }
  end
end

if restore then
  reaper.SNM_SetIntConfigVar( "renderclosewhendone", original )
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

-- @description Calculate Peak to Loudness Ratio (PLR - new Crest Factor) of selected items, including take and track FX and settings
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma

local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt == 0 then return end

local items, it_cnt = {}, 0
local items_GUID = {}

reaper.PreventUIRefresh( 1 )

for i = 0, item_cnt-1 do
  local item = reaper.GetSelectedMediaItem( 0 , i )
  local take = reaper.GetActiveTake( item )
  if take then
    local name = reaper.GetTakeName( take )
    local _, GUID = reaper.GetSetMediaItemInfo_String( item, "GUID", "", false )
    items_GUID[GUID] = {name = name, track = ({reaper.GetTrackName(reaper.GetMediaItemTrack( item ))})[2]}
    reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", GUID, true )
    it_cnt = it_cnt + 1
    items[it_cnt] = {take = take, name = name}
  end
end

if it_cnt == 0 then
  reaper.PreventUIRefresh( -1 )
  return
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

local ok3, info = reaper.GetSetProjectInfo_String( 0, "RENDER_STATS", "42437", false )
for guid, truepeak, lufsi in info:gmatch("FILE:(%b{}).-TRUEPEAK:([^%;]+).-LUFSI:([^%;]+)") do
  if guid then
    plr_cnt = plr_cnt + 1
    plr[plr_cnt] = {
      trpk = rnd(truepeak),
      lufsi = rnd(lufsi),
      plr = rnd(tonumber(truepeak) - tonumber(lufsi)),
      name = items_GUID[guid].name,
      track = items_GUID[guid].track
    }
  end
end

for i = 1, it_cnt do
  reaper.GetSetMediaItemTakeInfo_String( items[i].take, "P_NAME", items[i].name, true )
end

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()

if restore then
  reaper.SNM_SetIntConfigVar( "renderclosewhendone", original )
end

if plr_cnt ~= 0 then

  local format = "%-35s | %-30s | %10s | %10s | %10s |\n"

  reaper.ShowConsoleMsg("--- Peak to Loudness Ratio of selected items, including take and track FX and settings ---\n")
    reaper.ShowConsoleMsg(string.rep("-", 109) .. "\n")
  reaper.ShowConsoleMsg(string.format(format, "Item Name", "Track", "PLR", "True Peak", "LUFS-I"))
  reaper.ShowConsoleMsg(string.rep("-", 109) .. "\n")

  for i = 1, #plr do
    local p = plr[i]

    local name  = p.name or "Unknown"
    local track = p.track or "Unknown"

    if #name > 35 then name = string.sub(name, 1, 32) .. "..." end
    if #track > 30 then track = string.sub(track, 1, 28) .. "..." end

    reaper.ShowConsoleMsg(string.format( format, name, track, p.plr, p.trpk, p.lufsi ))
  end

  reaper.ShowConsoleMsg(string.rep("-", 109) .. "\n\n")
end

reaper.defer(function() end)

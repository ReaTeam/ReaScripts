-- @description Horizontal Zoom preset bundle
-- @author amagalma
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > amagalma_Load horizontal zoom preset 1.lua
--   [main] . > amagalma_Load horizontal zoom preset 2.lua
--   [main] . > amagalma_Load horizontal zoom preset 3.lua
--   [main] . > amagalma_Load horizontal zoom preset 4.lua
--   [main] . > amagalma_Load horizontal zoom preset 5.lua
-- @donation https://www.paypal.me/amagalma
-- @about Presets for arrange window horizontal zoom. Respects the 'horizontal zoom center' in REAPER Preferences

local zoommode = tonumber(({reaper.get_config_var_string( "zoommode" )})[2])

local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local preset = tonumber(name:match("%d+$"))
local presets = reaper.GetExtState( "amagalma_Horizontal zoom presets", "sizes" )
local pr, p = {121.5,40.5,13.5,4.5,1.5}, 0
if presets ~= "" then
  for n in presets:gmatch("%S+") do
    p = p + 1
    pr[p] = tonumber(n)
  end
end

local cur_start, cur_end = reaper.GetSet_ArrangeView2( 0, false, 0, 0 )
local cur_len, center_pos = cur_end - cur_start

if zoommode == 0 then -- edit or play
  if reaper.GetPlayState() & 1 == 1 then -- playing
    center_pos = reaper.GetPlayPosition()
  else
    center_pos = reaper.GetCursorPosition()
  end
elseif zoommode == 1 then -- edit
  center_pos = reaper.GetCursorPosition()
elseif zoommode == 2 then -- center of view
  center_pos = cur_len/2 + cur_start
else -- if zoommode == 3 -- mouse
  center_pos = reaper.BR_PositionAtMouseCursor( true )
  if center_pos == -1 then
    center_pos = cur_len/2 + cur_start
  end
end

local sz_L = ((center_pos - cur_start) / cur_len) * pr[preset]
local sz_R = ((cur_end - center_pos) / cur_len) * pr[preset]
local adj = center_pos-sz_L < 0 and sz_L-center_pos or 0
reaper.GetSet_ArrangeView2( 0, true, 0, 0, center_pos-sz_L+adj, center_pos+sz_R+adj )

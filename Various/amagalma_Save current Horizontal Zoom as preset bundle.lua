-- @description Save current Horizontal Zoom as preset bundle
-- @author amagalma
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > amagalma_Save current horizontal zoom as preset 1.lua
--   [main] . > amagalma_Save current horizontal zoom as preset 2.lua
--   [main] . > amagalma_Save current horizontal zoom as preset 3.lua
--   [main] . > amagalma_Save current horizontal zoom as preset 4.lua
--   [main] . > amagalma_Save current horizontal zoom as preset 5.lua
-- @donation https://www.paypal.me/amagalma
-- @about To be used with the amagalma_Horizontal Zoom preset bundle


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

local start_time, end_time = reaper.GetSet_ArrangeView2( 0, false, 0, 0 )
pr[preset] = math.floor((end_time - start_time)*100)/100
reaper.SetExtState( "amagalma_Horizontal zoom presets", "sizes", table.concat( pr, " " ), true )

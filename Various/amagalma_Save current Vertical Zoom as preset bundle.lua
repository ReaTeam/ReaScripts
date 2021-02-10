-- @description Save current Vertical Zoom as preset bundle
-- @author amagalma
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > amagalma_Save current vertical zoom as preset 1.lua
--   [main] . > amagalma_Save current vertical zoom as preset 2.lua
--   [main] . > amagalma_Save current vertical zoom as preset 3.lua
--   [main] . > amagalma_Save current vertical zoom as preset 4.lua
--   [main] . > amagalma_Save current vertical zoom as preset 5.lua
-- @donation https://www.paypal.me/amagalma
-- @about To be used with the amagalma_Vertical Zoom preset bundle


local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local preset = tonumber(name:match("%d+$"))
local presets = reaper.GetExtState( "amagalma_Vertical zoom presets", "sizes" )
local pr, p = {0,10,20,30,40}, 0
if presets ~= "" then
  for n in presets:gmatch("%S+") do
    p = p + 1
    pr[p] = tonumber(n)
  end
end

pr[preset] = reaper.SNM_GetIntConfigVar( "vzoom2", -1 )
reaper.SetExtState( "amagalma_Vertical zoom presets", "sizes", table.concat( pr, " " ), true )

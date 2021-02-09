-- @description Vertical Zoom preset bundle
-- @author amagalma
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > amagalma_Load vertical zoom preset 1.lua
--   [main] . > amagalma_Load vertical zoom preset 2.lua
--   [main] . > amagalma_Load vertical zoom preset 3.lua
--   [main] . > amagalma_Load vertical zoom preset 4.lua
--   [main] . > amagalma_Load vertical zoom preset 5.lua
-- @donation https://www.paypal.me/amagalma
-- @about Presets for arrange window vertical zoom. Requires JS_ReaScriptAPI 

 
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

local wanted_size = pr[preset]
local cur_size = reaper.SNM_GetIntConfigVar( "vzoom2", -1 )
if wanted_size == cur_size then return end

local arrangeview = reaper.JS_Window_FindChildByID( reaper.GetMainHwnd(), 1000 )
local ok, position, pageSize, min, max = reaper.JS_Window_GetScrollInfo( arrangeview, "v" )
if not ok then return end
reaper.SNM_SetIntConfigVar( "vzoom2", wanted_size )
reaper.TrackList_AdjustWindows( true )
reaper.JS_Window_SetScrollPos( arrangeview, "v", math.floor((position + pageSize/2)*
(({reaper.JS_Window_GetScrollInfo( arrangeview, "v" )})[5] / max) - pageSize/2 + 0.5) )

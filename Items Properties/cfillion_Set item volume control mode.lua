-- @description Set item volume control mode
-- @author cfillion
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > cfillion_Set item volume control mode to knob.lua
--   [main] . > cfillion_Set item volume control mode to handle (top).lua
--   [main] . > cfillion_Set item volume control mode to handle (center).lua
-- @link
--   cfillion.ca https://cfillion.ca
--   Request thread https://forum.cockos.com/showthread.php?t=229900
-- @screenshot https://i.imgur.com/LKEn1Nx.gif
-- @donation Donate via PayPal https://paypal.me/cfillion
-- @about This script provides actions to set the "Item volume control" option in Preferences > Appearance > Media.

assert(reaper.SNM_GetIntConfigVar, 'The SWS extension must be installed to use this script.')

local knobFlag = 0x4000
local scriptName = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local itemicons = reaper.SNM_GetIntConfigVar('itemicons', 0)
local itemvolmode = scriptName:match('center') and 1 or 0

if scriptName:match('knob') then
  itemicons = itemicons | knobFlag
else
  itemicons = itemicons & ~knobFlag
end

reaper.SNM_SetIntConfigVar('itemicons', itemicons)
reaper.SNM_SetIntConfigVar('itemvolmode', itemvolmode)
reaper.UpdateArrange()

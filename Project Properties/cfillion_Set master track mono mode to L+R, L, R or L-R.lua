-- @description Set master track mono mode to L+R, L, R or L-R
-- @author cfillion
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > cfillion_Set master track mono mode to L+R.lua
--   [main] . > cfillion_Set master track mono mode to L.lua
--   [main] . > cfillion_Set master track mono mode to R.lua
--   [main] . > cfillion_Set master track mono mode to L-R.lua
-- @link
--   cfillion.ca https://cfillion.ca
--   Request thread https://forum.cockos.com/showthread.php?t=216321
-- @donation Donate via PayPal https://paypal.me/cfillion

local L = 1<<3
local R = 1<<4

local modes = {
  ['L+R'] = 0,
  ['L'  ] = L,
  ['R'  ] = R,
  ['L-R'] = L|R,
}

local scriptName = ({reaper.get_action_context()})[2]:match('([^/\\_]+)%.lua$')
local modeName = scriptName:match('mono mode to ([LR+-]+)$')
local mode = assert(modes[modeName],
  string.format("unknown master mono mode '%s'", modeName))

local mastermutesolo = reaper.SNM_GetIntConfigVar('mastermutesolo', 0)
mastermutesolo = mastermutesolo & ~(L|R)
reaper.SNM_SetIntConfigVar('mastermutesolo', mastermutesolo | mode)

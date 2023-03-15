-- @description Change Take Volume (insert 4 points) for selected items (or selected take vol env) in time selection by set amount (Settings)
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about
--   Settings for amagalma_Change Take Volume (insert 4 points) for selected items (or selected take vol env) in time selection by set amount actions.
--
--   Enter change in dB and transition duration in ms (defaults: 3dB, 3ms)

local change = tonumber(reaper.GetExtState( "amagalma_Take_Vol_in_TS", "change" )) or 3
local length = tonumber(reaper.GetExtState( "amagalma_Take_Vol_in_TS", "length" )) or 3
local ok, retvals = reaper.GetUserInputs( "Settings for Take_Vol change actions", 2, "Volume change ( ±dB ),Transition duration ( ms ),separator=\n", change .. "\n" .. length )
if ok then
  change, length = retvals:match("([^\n]+)\n([^\n]+)")
  if tonumber(change) and tonumber(length) then
    reaper.SetExtState( "amagalma_Take_Vol_in_TS", "change", change:gsub("-", ""), true )
    reaper.SetExtState( "amagalma_Take_Vol_in_TS", "length", length:gsub("-", ""), true )
  else
    reaper.MB( "Please, enter numbers", "Invalid input!", 0 )
  end
end

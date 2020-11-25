-- @description Toggle show media item/take or automation item properties, depending on last touched context
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about
--   Runs action "Item properties: Toggle show media item/take properties" or "Envelope: Automation item properties..." depending on last touched cursor context
--
--   Good to replace native F2 key shortcut


local context = reaper.GetCursorContext2( true )
if context == 2 then
  reaper.Main_OnCommand(42090, 0) -- Automation item properties...
else
  reaper.Main_OnCommand(41589, 0) -- Toggle show media item/take properties
end
reaper.defer( function() end )

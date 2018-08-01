--[[
 * @description Smart toggle mute (items, automation items, tracks)
 * @about This script will toggle the mute state of selected items, automation items or tracks, depending on where the mouse clicked last
 * @author EvilDragon
 * @donate https://www.paypal.me/EvilDragon
 * @version 1.0
 * Licence: GPL v3
 * REAPER: 5.0+
 * Extensions: none required
--]]

reaper.Undo_BeginBlock()

last_context = reaper.GetCursorContext2(true)

if last_context < 2 then
  reaper.Main_OnCommand(40183, 0)  -- toggle mute tracks or items depending on context
else
  reaper.Main_OnCommand(42211, 0)  -- toggle mute AIs
end

reaper.Undo_EndBlock("Smart toggle mute (items, automation items, tracks)", 0)

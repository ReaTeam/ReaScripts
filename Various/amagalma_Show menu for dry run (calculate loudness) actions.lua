-- @description Show menu for dry run (calculate loudness) actions
-- @author amagalma
-- @version 1.04
-- @changelog Added new v7.79 stereo actions
-- @link https://forum.cockos.com/showthread.php?t=239556
-- @screenshot https://i.ibb.co/9w5VJwZ/dry-run-menu.gif
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Shows a menu with all the dry run actions at the mouse cursor

local t = {
  { "#Calculate loudness via dry run render|" },
  { "Master Mix", 42440 },
  { "Selected Tracks (multichannel)", 42438 },
  { "Selected Tracks (stereo)", 43810 },
  { "Selected Tracks (mono)", 42447 },
  { "Selected Items", 42468 },
  { "Selected Items (including take/track FX and settings)|", 42437 },
  { ">Within Time Selection" },
  { "Master Mix", 42441 },
  { "Selected Tracks (multichannel)", 42439 },
  { "Selected Tracks (stereo)", 43811 },
  { "<Selected Tracks (mono)", 42448 },
}

local menu = ""
for i = 1, #t do
  menu = menu .. t[i][1] .. "|"
end
local selection = gfx.showmenu(menu)
gfx.quit()

if selection > 0 then
  if selection > 7 then selection = selection + 1 end
  if t[selection][2] then
    reaper.Main_OnCommand(t[selection][2], 0)
  end
end
reaper.defer(function() end)

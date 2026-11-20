-- @description Apply FX to items... (choose from list)
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma

local actions = {
      {"Track/Take FX to items", 40209},
      {"Track/Take FX to items (mono output)", 40361},
      {"Track/Take FX to items (multichannel output)", 41993},
      {"<Track/Take FX to items (MIDI output)", 40436},
      {"First Take FX to items", 42686},
      {"First Take FX to items (mono output)", 42688},
      {"First Track FX to items", 42685},
      {">First Track FX to items (mono output)", 42687},
}

local menu = "#Apply FX to items...||>All FX|"
for i = 1, #actions do
  if i == 5 then menu = menu .. ">First FX only|" end
  menu = menu .. actions[i][1] .. "|"
end

local selection = gfx.showmenu(menu)

if selection ~= 0 then
  selection = selection - 1
  if actions[selection] and actions[selection][2] then
   reaper.Main_OnCommand( actions[selection][2], 0 )
  end
end

reaper.defer(function() end)

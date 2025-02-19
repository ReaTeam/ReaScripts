-- @description Show menu for all Normalize Items actions
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about All Reaper's "Normalize Items" actions in one menu

local t = {
  { "#Normalize Items||" },
  { "Peak/RMS/LUFS...|", "42460" },
  { ">Each Item Separately|" },
  { "to +0dB peak|", "40108" },
  { "<to +0dB peak (reset to unity if already normalized)|", "40936" },
  { ">To Loudest Item|" },
  { "to +0dB peak|", "40254" },
  { "<to +0dB peak (reset to unity if already normalized)|", "40937" },
  { ">Using Most Recent Settings|" },
  { "using most recent settings|", "42461" },
  { "force normalize as if one long item|", "42463" },
  { "force normalize each item separately|", "42464" },
  { "force normalize to loudest item|", "43344" },
  { "<reset to unity if already normalized|", "42462" },
  { "|Reset Item Take Gain to +0dB (Un-Normalize)|", "40938" },
}

local menu = ""
for i = 1, #t do
  menu = menu .. t[i][1]
end
local selection = gfx.showmenu(menu)
if selection > 0 then
  if selection >= 7 then
    selection = selection + 3
  elseif selection >= 5 then
    selection = selection + 2
  elseif selection >= 3 then
    selection = selection + 1
  end
  reaper.Main_OnCommand( t[selection][2], 0 )
end
reaper.defer(function() end)

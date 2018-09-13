--[[
    Description: Enable metronome until playback reaches edit cursor
    Version: 1.0.0
    Author: Lokasenna
    Donation: https://paypal.me/Lokasenna
    Changelog:
        Initial Release
    Links:
        Lokasenna's Website http://forum.cockos.com/member.php?u=10417
    About:
        Turns Reaper's metronome on and automatically turns it off again once
        the playback cursor reaches the edit cursor. When used as part of a
        custom action, this provides a workaround for Reaper's inability to
        monitor input during Count-In.

        Note: This must be used *AFTER* the Record action if Pre-Roll is enabled,
        as Pre-Roll will turn off the metronome.

    Donation: https://www.paypal.me/Lokasenna
]]--

local CLICK_ON  = 41745
local CLICK_OFF = 41746

local editPos

local function loop()

  if (reaper.GetPlayState() & 1 == 1) 
  and reaper.GetPlayPosition2() >= editPos - 0.15 then -- Avoid a click on the 1
    reaper.Main_OnCommand(CLICK_OFF, 0)
  else
    reaper.defer(loop)
  end

end

local function Main()

  editPos = reaper.GetCursorPosition()
  reaper.Main_OnCommand(CLICK_ON, 0)
  reaper.defer(loop)

end

Main()
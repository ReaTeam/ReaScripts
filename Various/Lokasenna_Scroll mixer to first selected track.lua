--[[
Description: Scroll mixer to first selected track
Version: 1.0.1
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Bug fix
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Scrolls the mixer so that the first selected track
	is at the left-hand side, if possible.
Extensions:
--]]

-- Licensed under the GNU GPL v3

if reaper.CountSelectedTracks( 0 ) > 0 then
	reaper.SetMixerScroll( reaper.GetSelectedTrack(0, 0) )
end

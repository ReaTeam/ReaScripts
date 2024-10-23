--[[
Description: Lokasenna_Append selected track names with their first send destination
Version: 1.0.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Initial release
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
  For each selected track, gets the name of its *first* send destination
  and appends it to the track's name. i.e: if "Guitar L" sends to "Guitar Bus",
  it will be renamed to "Guitar L (Guitar Bus)"
]]--

local function Main()
  reaper.Undo_BeginBlock()

  for i = 0, reaper.CountSelectedTracks(0) - 1 do
    local tr = reaper.GetSelectedTrack(0, i)
    local dest = reaper.GetTrackSendInfo_Value(tr, 0, 0, "P_DESTTRACK")

    if dest then
      local _, trName = reaper.GetTrackName(tr, "")
      local _, destName = reaper.GetTrackName(dest, "")
      local newName = trName .. " (" .. destName .. ")"

      reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", newName, true)
    end
  end

  reaper.Undo_EndBlock("Append track names with destination", -1)
end

Main()

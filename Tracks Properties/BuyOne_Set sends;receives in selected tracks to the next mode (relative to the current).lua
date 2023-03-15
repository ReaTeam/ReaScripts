--[[
ReaScript name: Set sends;receives in selected tracks to the next mode (relative to the current)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
About:
	- Whether sends or receives are affected is determined by the user settings
	- The script can be duplicated and each copy dedicated to work either with sends or receives
	- The next mode is relative to the current mode of each given send/receive, therefore if
	several sends/receives are initially set to different modes their resulting modes will differ as well

Licence: WTFPL
REAPER: at least v5.962
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

TYPE = 0 -- sends = 0, receives = 1 or -1

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper

function Msg(param)
r.ShowConsoleMsg(tostring(param)..'\n')
end

local TYPE = (type(TYPE) == 'number' and TYPE >= -1 and TYPE <= 1) and math.floor(TYPE) -- evaluate TYPE value to avoid errors
local TYPE = TYPE and TYPE == 1 and -1 or TYPE -- convert to the number used by API
local tr_cnt = r.GetNumTracks()
local sel_tr_cnt = r.CountSelectedTracks(0)
local snd_rec_cnt = 0

	if TYPE and sel_tr_cnt > 0 then
		for i = 0, sel_tr_cnt-1 do
		local tr = r.GetSelectedTrack(0,i)
		snd_rec_cnt = snd_rec_cnt + r.GetTrackNumSends(tr, TYPE)
		end
	end

local err = not TYPE and 'Invalid type.' or (tr_cnt == 0 and 'There\'re no tracks in the project.') or (sel_tr_cnt == 0 and 'No selected tracks.') or (snd_rec_cnt == 0 and 'There\'re no '..(TYPE == 0 and 'sends' or 'receives')..' in selected tracks.')

	if err then r.MB(err,'ERROR',0) return r.defer(function() end) end

r.Undo_BeginBlock()

	for i = 0, sel_tr_cnt-1 do
	local tr = r.GetSelectedTrack(0,i)
	local snd_rec_cnt = r.GetTrackNumSends(tr, TYPE)
		if snd_rec_cnt > 0 then
			for i = 0, snd_rec_cnt-1 do
			local snd_rec_mode = r.GetTrackSendInfo_Value(tr, TYPE, i, 'I_SENDMODE')
			local snd_rec_mode = snd_rec_mode == 0 and 2 or (snd_rec_mode == 3 and 0) or -1 -- to skip deprecated send/receive type and order according to the send/receive mode list in the routing window
			r.SetTrackSendInfo_Value(tr, TYPE, i, 'I_SENDMODE', snd_rec_mode+1) -- 0=post-fader, 3=post-fx, 1=pre-fx, 2=post-fx (deprecated)
			end
		end
	end


	
local rout_type = TYPE == 0 and 'sends' or 'receives' -- condition an inset for the dialogue	
r.Undo_EndBlock('Set '..rout_type..' in selected tracks to the next mode', 1)



--[[
ReaScript name: Set sends;receives in selected tracks to the same mode and cycle through the modes
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
About: 
	- Sets selected tracks sends or receives to the same mode selected with an interactive dialogue
	- Whether send or receives are affected is determined by the user settings
	- The script can be duplicated and each copy dedicated to work either with sends or receives
	- Or TYPE_DIALOGUE option can be enabled to allow manual selection of the target type (sends or receives)
	- When TYPE_DIALOGUE option is enabled TYPE option value can be whatever, just not empty
	- The script starts out by setting send/receive mode to 'Post-Fader (Post Pan)', the 1st one in the list
	- All sends/receives are being synchronously set to the same mode regardless of their initial mode
	
Licence: WTFPL
REAPER: at least v5.962
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable TYPE_DIALOGUE option place any alphanumeric character between 
-- the quotation marks.

TYPE = 0 -- sends = 0, receives = 1 or -1
TYPE_DIALOGUE = "1" -- enable to select target type (sends or receives) manually

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

local TYPE_DIALOGUE = TYPE_DIALOGUE:gsub('[%s]', '') ~= ''


local err = (not TYPE_DIALOGUE and not TYPE) and 'Invalid type.' or (tr_cnt == 0 and 'There\'re no tracks in the project.') or (sel_tr_cnt == 0 and 'No selected tracks.')

	if err then r.MB(err,'ERROR',0) return r.defer(function() end) end

local resp = TYPE_DIALOGUE and r.MB('"YES" - affect sends    "NO" - affect receives','PROMPT',4)
local TYPE = (resp and resp == 6) and 0 or ((resp and resp == 7) and -1) or TYPE

-- find if there're sends or receives (depending on the TYPE setting) in selected tracks
local snd_rec_cnt = 0
	if TYPE and sel_tr_cnt > 0 then
		for i = 0, sel_tr_cnt-1 do
		local tr = r.GetSelectedTrack(0,i)
		snd_rec_cnt = snd_rec_cnt + r.GetTrackNumSends(tr, TYPE)
		end
	end	
	
local err = snd_rec_cnt == 0 and 'There\'re no '..(TYPE == 0 and 'sends' or 'receives')..' in selected tracks.'	

	if err then r.MB(err,'ERROR',0) return r.defer(function() end) end
	
local snd_rec_mode = 0 -- initial settting for SetTrackSendInfo_Value()
local rout_type = TYPE == 0 and 'sends' or 'receives' -- condition an inset for the dialogue

r.Undo_BeginBlock()

		repeat
		::CONTINUE::
			for i = 0, sel_tr_cnt-1 do
			local tr = r.GetSelectedTrack(0,i)
			local snd_rec_cnt = r.GetTrackNumSends(tr, TYPE)
				if snd_rec_cnt > 0 then
					for i = 0, snd_rec_cnt-1 do	
					r.SetTrackSendInfo_Value(tr, TYPE, i, 'I_SENDMODE', snd_rec_mode)
					snd_rec_mode = r.GetTrackSendInfo_Value(tr, TYPE, i, 'I_SENDMODE')
					end
				end
			end
		readout = snd_rec_mode == 0 and '        Post-Fader (Post Pan)' or (snd_rec_mode == 3 and '          Pre-Fader (Post-FX)' or (snd_rec_mode == 1 and '\t      Pre-FX'))
		local resp = r.MB('The '..rout_type..' mode has been set to:\n\n'..readout..'\n\n      Switch to the next mode?','PROMPT',1)
			if resp == 1 then snd_rec_mode = snd_rec_mode == 0 and 3 or (snd_rec_mode == 3 and 1) or (snd_rec_mode == 1 and 0) -- 0=post-fader, 3=post-fx, 1=pre-fx, 2=post-fx (deprecated)
			goto CONTINUE
			else break end
		until resp == 2

		
r.Undo_EndBlock('Set '..rout_type..' in selected tracks to '..readout:gsub('^%s*(.+)','"%1"')..' mode', 1)
	


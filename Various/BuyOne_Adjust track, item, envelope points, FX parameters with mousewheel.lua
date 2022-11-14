--[[
ReaScript name: Adjust track, item, envelope points, FX parameters with mousewheel
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v6.36
About:	The script is meant to allow using mousewheel on controls with a modifier which
	isn't possible natively. This gives the benefit of avoiding accidental parameter
	change with a mousewheel if allowed in Preferences -> Editing behavior -> Mouse.
	So the script can be used with 'Ignore mousewheel on all faders' and/or 
	'Ignore mousewheel on track panel faders' settings enabled if it's bound to 
	the mousewheel with a modifier in the Action list.	

	▓ SUPPORTED PARAMETERS

	Track TCP - volume, pan (all modes), playback offset
	Item - volume
	Take - volume, pan, pitch
	FX - see TARGETTING FX CONTROLS paragraph below
	Envelope points - track, take and plugin parameter envelope points, 
	including Master track tempo and playrate envelopes

	Track MCP is not supported due to REAPER limitations.


	▓ MOUSE CURSOR PLACEMENTS  
	to target different parameters in tracks, items, envelope points and plugin controls

	▪ Track volume - over the track volume control (knob or slider).  
	▪ Track pan/width - over the track corresponding control.  
	▪ Track playback offset - any other place within the TCP.  
	▪ Item/take volume - around the center of the item/take UI.  
	▪ Take pan - near the item left edge from inside (new cursor type is a good indicator).  
	▪ Take pitch - near the item right edge from inside (new cursor type is a good indicator).  
	(to switch to mainuplating item/take parameters after take envelope was manipulated,
	de-select the envelope.)  
	▪ Envelope point - slightly to the right of the point's vertical axis, not nesessarily 
	near it, can be above or below; IMPORTANT: to be able to affect an envelope it must
	be explicitly selected, or with track and FX parameter envelopes, if it's already selected, 
	then it must be clicked when coming from FX context; selected track and FX parameter 
	envelopes cannot be manipulated while the UI of the last touched FX is open, so its FX chain
	must be either closed or switched to another plugin UI or its floating window must be closed.  
	▪ Plugin controls - this is tricky, touch the control, then click elsewhere, to be safe
	click REAPER program window title bar and run the script. After that regardless of the
	mouse cursor placement and focus of the FX window the plugin control will respond 
	to the mouswheel movements. See 'VERY IMPORTANT:' note in TARGETTING FX CONTROLS paragraph below.

	To change parameters of one object other than an envelope, it doesn't have to be selected. 
	But if several such objects are selected and one of them is under the mouse cursor
	the parameter will be changed in all. The change is relative to the current value
	of the parameter in each one of selected objects. 
	In automation items only selected points within the same item are affected.

	▓ TARGETTING ITEM PARAMETERS	

	Volume (gain) is the only parameter which exists on two levels, for item and for take.

	Item volume is controlled by the knob displayed above the item if enabled in 
	Preferences -> Appearance -> Media -> Media item buttons and/or a handle if enabled under 
	the same section. When item volume changes these change their state. Take volume (gain) 
	is the volume control in the Media Item Properties window (default shortcut is F2) and it 
	changes its state when take volume is changed.	

	If the item under the mouse cursor isn't selected regardless of its number of takes 
	or if it's selected and only has 1 take, item volume it targeted by the script.  
	If selected item has more than 1 take, its active take volume is targeted and not 
	the volume of the take immediately under the mouse cursor.  

	If along with the item under the mouse cursor other items are selected the type of volume
	which will be targeted in all such items depends on the number of takes in the item under
	the mouse cursor. If there's only 1 take in the selected item under the mouse cursor, 
	item volume will be targeted in all other selected items regardless of their own number of takes;
	on the other hand if there're more than 1 take in the selected item under the mouse cursor,
	take volume will be targeted in all other selected items regardless of their own number of takes.
	In selected multi-take items their active take volume will be targeted similarly to the item under 
	the mouse cursor in case it's selected (see above). 

	Pan and pitch can only be adjusted on the take level.


	▓ TARGETTING FX CONTROLS

	Only JSFX are fully supported. REAPER native VST plugins will work but inconsistently
	in terms of the step resolution, for some parameters the step may be too big while
	for others too small. Drop-down lists won't work.  
	3d party plugins may work with the same reservation regarding the step resolution.
	If the controls don't respond to the mousewheel in the plugin UI, switch to the slider 
	interface by clicking the 'UI' button of the plugin wrapper and try there.  
	VERY IMPORTANT: Placement of the mouse cursor depends on the 'Mousewheel targets:' setting
	at Preferences -> Editing behavior -> Mouse. If it's set to 'Window with focus' the mouse
	cursor can be located either within the FX window or outside of it, if it's set to 
	'Window under cursor' it must only be located outside of the FX window otherwise the script
	won't affect plugin parameters (in both cases provided the mouse cursor is not over a TCP 
	or an item, because the track/item parameters will be targeted rather than that of the plugin).  
	Some 3d party plugins may respond to mousewheel regardless of REAPER settings and for
	such plugins this script isn't necessary.  
	Monitoring FX are not supported due to REAPER limitations.	
	The abovesaid regarding scope of support and step resolution applies to FX parameter envelopes 
	as well.  

	As value is changed via the script a tootlip is displayed for values for which there's 
	no readout in the UI, such as take pan and track playback offset. It also displays tooltips 
	for item/take volume (gain) / velocity and take pitch for which readouts on item UI can be enabled 
	in Preferences -> Appearance -> Media - Media item labels.  
	In REAPER item volume (gain) / velocity value in the readout is a sum of item and take volume 
	(gain) / velocity values, therefore if item gain readout is enabled in Preferences and it's not 
	at unity its value may differ from the one displayed in the script tooltip when take volume / 
	velocity  is targeted.  
	If a multi-take item is a mix of media and MIDI takes, the units in the tooltip readout
	depend on the take under the mouse cursor: for media takes it's dB, for MIDI takes it's
	velocity.  
	If several objects are selected the tooltip only displays values for the object under
	the mouse cursor.  
	Display of tooltips by the script for track and item depends on the settings at 
	Preferences -> Appearance - Appearance settings - Tooltips: UI elements and Items/envelopes
	respectively. 

	If track/item/envelope under the mouse cursor is locked nothing happens.

	If 'Ignore mousewheel on all faders' and/or 'Ignore mousewheel on track panel faders' settings
	aren't enabled in Preferences -> Editing behavior -> Mouse, the script won't be applied in the
	relevant context, that is track volume/pan/width and FX parameter controls, and unmodified
	mousewheel events will be used instead.  

	In the USER SETTINGS section you can define resolution for each supported parameter type.
	Mute envelope resolution cannot be custom as there're only two possible values, 1 and 0.
	The resolution for FX papameter envelopes is fixed.  

	The script doesn't create an undo point. Seems pointless for mousewheel actions which inundate
	undo history with points as one mousewheel nudge means 1 discrete point and one movement
	usually consists of several nudges in a row.
		
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- Enable this setting by inserting any QWERTY alphanumeric
-- character between the quotation marks so the script can be used
-- then configure the settings below
ENABLE_SCRIPT = ""

-----------------------------------------------------------------------------

-- IN THE SETTINGS BELOW INSERT NUMBERS BETWEEN THE QUOTATION MARKS


-- Value per one mousewheel nudge, either decimal or integer;
-- While scrolling usually several such nudges are performed in a row which is useful to keep in mind;
-- If the setting is empty or invalid it defaults 0.05dB per mousewheel nudge;
-- The setting is also relevant for all native track envelopes affecting volume/gain;
-- The envelope range depends on the setting at
-- Preferences -> Editing behavior -> Envelope display -> Volume envelope range:
-- The upper range limit is taken from this setting,
-- the lower range limit is set in this script at -60dB for both UI control and envelope point
TRACK_VOL_RESOLUTION = ""

-- One mousewheel nudge equals 1%, while scrolling several such nudges are performed in a row
-- which amount to about 5-6%;
-- Specify the desired value if coarser resolution is needed;
-- Supported values are 1 through 100, 1 equals default;
-- The setting is relevant for the corresponding native track pan envelopes as well
-- If the setting is empty or invalid it defaults to 1%;
-- Only whole numbers (integers) are supported, decimal numbers are rounded down
TRACK_PAN_RESOLUTION = ""

-- Track width knob/envelope resolution;
-- TRACK_PAN_RESOLUTION descripion applies here as well
WIDTH_RESOLUTION = ""

-- Both left and right controls of track dual pan;
-- TRACK_PAN_RESOLUTION descripion applies here as well
DUAL_PAN_RESOLUTION = ""

-- The unit depends on the unit set for the particular track
-- playback offset: either milliseconds or samples;
-- Be aware that if the parameter is being edited for several tracks
-- at once, they may have different playback offset unit enabled;
-- Only whole numbers (integers) are supported;
-- If the setting is empty or invalid it defaults to 1 ms or 1 sample
-- depending on the unit set for the particular track
TRACK_TIME_OFFSET_RESOLUTION = ""

-- Only relevant for the Master track;
-- Whole and decimal numbers are supported, the useful ones are:
-- 1, 0.1, 0.01 and 0.001 BPM and their varieties such as 5.8, 1.02, 0.35 etc.;
-- If the setting is empty or invalid it defaults to 1 BPM
TEMPO_MAP_ENV_RESOLUTION = ""

-- Only relevant for the Master track;
-- Default resolution is 0.01 below 1 and 0.03 above 1;
-- If the setting is empty or invalid the default resolution is used,
-- otherwise any number, whole or decimal, is supported,
-- in which case the resolution will be uniform below and above 1
PLAYRATE_ENV_RESOLUTION = ""

-- Only relevant for media items/takes;
-- Value per one mousewheel nudge, either decimal or integer;
-- While scrolling usually several such nudges are performed in a row which is useful to keep in mind;
-- If the setting is empty or invalid it defaults 0.05dB per mousewheel nudge;
-- The setting is relevant for the native take volume envelope as well;
-- The range upper limit of both item and take volume control is +12dB,
-- dictated by the ReaScript limitations even though upper limit of item
-- volume manual control is +24dB;
-- The take volume envelope range depends on the setting in
-- Preferences -> Editing behavior -> Envelope display -> Volume envelope range:
-- The upper range limit is taken from this setting,
-- the lower range limit is set in this script at -60dB for both UI control and envelope point
ITEM_TAKE_VOL_RESOLUTION = ""

-- Only relevant for MIDI items/takes;
-- If the setting is empty or invalid it defaults 0.05 per mousewheel nudge;
-- The range dictated by REAPER is 0.1 - 16;
ITEM_TAKE_VEL_RESOLUTION = ""

-- Only relevant for audio items;
-- One mousewheel nudge equals 1%, while scrolling several such nudges are performed in a row
-- which amount to about 5-6%;
-- Specify the desired value if coarser resolution is needed;
-- Supported values are 1 through 100, 1 equals default;
-- The setting is relevant for the native take pan envelope as well;
-- If the setting is empty or invalid it defaults to 1%;
-- Only whole numbers (integers) are supported, decimal numbers are rounded down
TAKE_PAN_RESOLUTION = ""

-- For the parameter which is usually adjusted in 'Media Item Properties' window
-- in the 'Pitch adjust (semitones)' field;
-- Only whole numbers (integers) are supported represening semitones;
-- If empty or invalid defaults to 1, i.e. 1 semitone
TAKE_PITCH_RESOLUTION = ""

-- Relevant for take pitch envelope;
-- The resolution unit depends on the setting in
-- Preferences -> Editing behavior -> Envelope display -> Default per take pitch envelope ... snap:
-- which is multiplied by the TAKE_PITCH_ENV_RESOLUTION value,
-- so if the snap is set to 0.05st while the TAKE_PITCH_ENV_RESOLUTION value is 3,
-- the smallest unit will be 0.05 x 3 = 0.15st that is 15 cents for one mousewheel nudge;
-- If the snap in the Preferences is OFF, the applicable unit is 1 cent
-- and the TAKE_PITCH_ENV_RESOLUTION value is multiplied by 1 cent;
-- if the TAKE_PITCH_ENV_RESOLUTION setting is empty or invalid it defaults to 1 unit set in Preferences
-- which is equal to TAKE_PITCH_ENV_RESOLUTION being 1
TAKE_PITCH_ENV_RESOLUTION = ""


-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


local r = reaper


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
r.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function Script_Not_Enabled(ENABLE_SCRIPT)
	if #ENABLE_SCRIPT:gsub(' ','') == 0 then
	local emoji = [[
		_(ツ)_
		\_/|\_/
	]]
	r.MB('  Please enable the script in its USER SETTINGS.\n\nSelect it in the Action list and click "Edit action...".\n\n'..emoji, 'PROMPT', 0)
	return true
	end
end


function round(num, idp) -- idp = number of decimal places
-- http://lua-users.org/wiki/SimpleRound
-- round to N decimal places
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end


local function Tooltip(val)
local x, y = r.GetMousePosition()
r.TrackCtl_SetToolTip(val, x, y-30, true) -- topmost true
end


function Get_TCP_Under_Mouse()
-- r.GetTrackFromPoint() covers the entire track timeline hence isn't suitable for getting the TCP
local curs_pos = r.GetCursorPosition() -- store current edit curs pos
local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0, start_time, end_time) -- isSet false, screen_x_start, screen_x_end are 0 to get full arrange view coordinates // get time of the current Arrange scroll position to use to move the edit cursor away from the mouse cursor
r.PreventUIRefresh(1)
r.SetEditCurPos(end_time+5, false, false) -- moveview, seekplay false // to secure against a vanishing probablility of overlap between edit and mouse cursor positions in which case edit cursor won't move just like it won't if mouse cursor is over the TCP // +5 sec to move edit cursor beyond right edge of the Arrange view to be completely sure that it's far away from the mouse cursor
r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // more sensitive than with snapping
local tcp_under_mouse = r.GetCursorPosition() == end_time+5
-- Restore orig. edit cursor pos
local new_curs_pos = r.GetCursorPosition()
local min_val, subtr_val = table.unpack(new_curs_pos == end_time+5 and {curs_pos, end_time+5} -- TCP found, edit cursor remained at end_time+5
or new_curs_pos ~= end_time+5 and {curs_pos, new_curs_pos} -- TCP not found, edit cursor moved
or {0,0})
--r.MoveEditCursor(min_val - subtr_val, false) -- dosel false = don't create time sel; restore orig. edit curs pos, greater subtracted from the lesser to get negative value meaning to move closer to zero (project start) // MOVES VIEW SO IS UNSUITABLE
-- 	OR SIMPLY
r.SetEditCurPos(curs_pos, false, false) -- moveview, seekplay false // restore orig. edit curs pos
r.PreventUIRefresh(-1)
return tcp_under_mouse and r.GetTrackFromPoint(r.GetMousePosition())
end

function GetMonFXProps() -- get mon fx accounting for floating window, reaper.GetFocusedFX() doesn't detect mon fx in builds prior to 6.20

-- r.TrackFX_GetOpen(master_tr, integer fx)
	local master_tr = r.GetMasterTrack(0)
	local mon_fx_idx = r.TrackFX_GetRecChainVisible(master_tr)
	local is_mon_fx_float = false -- only relevant for pasting stage to reopen the fx in floating window
		if mon_fx_idx < 0 then -- fx chain closed or no focused fx -- if this condition is removed floated fx gets priority
			for i = 0, r.TrackFX_GetRecCount(master_tr) do
				if r.TrackFX_GetFloatingWindow(master_tr, 0x1000000+i) then
				mon_fx_idx = i; is_mon_fx_float = true break end
			end
		end
	return mon_fx_idx, is_mon_fx_float -- expected >= 0, true
end


function GetFocusedFX() -- complemented with GetMonFXProps() to get Mon FX in builds prior to 6.20

local retval, tr_num, itm_num, fx_num = r.GetFocusedFX()
-- Returns 1 if a track FX window has focus or was the last focused and still open, 2 if an item FX window has focus or was the last focused and still open, 0 if no FX window has focus. tracknumber==0 means the master track, 1 means track 1, etc. itemnumber and fxnumber are zero-based. If item FX, fxnumber will have the high word be the take index, the low word the FX index.
-- if take fx, item number is index of the item within the track (not within the project) while track number is the track this item belongs to, if not take fx itm_num is -1, if retval is 0 the rest return values are 0 as well
-- if src_take_num is 0 then track or no object
local mon_fx_num = GetMonFXProps() -- expected >= 0 or > -1
local tr = retval > 0 and (r.GetTrack(0,tr_num-1) or r.GetMasterTrack()) or retval == 0 and mon_fx_num >= 0 and r.GetMasterTrack() -- prior to build 6.20 Master track has to be gotten even when retval is 0
local item = retval == 2 and r.GetTrackMediaItem(tr, itm_num)
-- high word is 16 bits on the left, low word is 16 bits on the right
local take_num, take_fx_num = fx_num>>16, fx_num&0xFFFF -- high word is right shifted by 16 bits (out of 32), low word is masked by 0xFFFF = binary 1111111111111111 (16 bit mask); in base 10 system take fx numbers starting from take 2 are >= 65536
local take = retval == 2 and r.GetMediaItemTake(item, take_num)
local fx_num = retval == 2 and take_fx_num or retval == 1 and fx_num or mon_fx_num >= 0 and 0x1000000+mon_fx_num -- take or track fx index (incl. input/mon fx) // unlike in GetLastTouchedFX() input/Mon fx index is returned directly and need not be calculated // prior to build 6.20 Mon FX have to be gotten when retval is 0 as well // 0x1000000+mon_fx_num is equivalent to 16777216+mon_fx_num

return retval, tr_num-1, tr, itm_num, item, take_num, take, fx_num, mon_fx_num >= 0 -- tr_num = -1 means Master;

end


function GetLastTouchedFX() -- means last even if no longer focused // Mon FX aren't supported by the API function
-- Returns true if the last touched FX parameter is valid, false otherwise.
-- Always returns true as long as FX was touched at least once during a session and that FX is still present, unless the edit cursor is over an item or a TCP
-- To make RS5k last touched its parameter must be changed whereas in plugins with sliders a touch of a slider siffices,
-- could be bacause of a float value change invisible in the UI
-- The low word of tracknumber is the 1-based track index -- 0 means the master track, 1 means track 1, etc. If the high word of tracknumber is nonzero, it refers to the 1-based item index (1 is the first item on the track, etc). For track FX, the low 24 bits of fxnumber refer to the FX index in the chain, and if the next 8 bits are 01, then the FX is record FX. For item FX, the low word defines the FX index in the chain, and the high word defines the take number.
-- https://stackoverflow.com/questions/10493411/what-is-bit-masking
-- hight word is 16 bits on the left, low word is 16 bits on the right
local retval, src_track_num, src_fx_num, src_param_num = r.GetLastTouchedFX() -- doesn't support Mon FX
local track_num = src_track_num&0xFFFF -- low word (16 bits out of 32) masked by 0xFFFF = 1111111111111111 (16 set bits) in binary; 0 master, > 0 regular
local tr = track_num == 0 and r.GetMasterTrack(0) or r.GetTrack(0,track_num-1)
local item_num = src_track_num>>16 -- high word (16 bits out of 32) right shifted; item in track, 1 based
local item = item_num >= 1 and r.GetTrackMediaItem(tr, item_num-1)
local fx_num_tr = src_fx_num&0xFFFFFF -- low 24 bits (out of 32) masked by 0xFFFFFF = 111111111111111111111111 (24 set bits) in binary, fx idx
local is_input_fx = src_fx_num>>24 == 1 -- right shift by 24 bits to only leave 8 high bits intact
local fx_num_take = src_fx_num&0xFFFF -- low word (16 bits out of 32) masked as above // 0 based
local fx_num = item and src_fx_num&0xFFFF or is_input_fx and fx_num_tr+0x1000000 or fx_num_tr -- unlike in GetFocusedFX() input/Mon fx index isn't returned directly and must be calculated
local take_num = item and src_fx_num>>16 -- high word (16 bits out of 32) right shifted as above // 0 based
local take = item and r.GetTake(item, take_num)
return retval, track_num-1, tr, item_num-1, item, take_num, take, fx_num, src_param_num -- indices are 0 based; track_num = -1 means Master; item_num = -1 or take_num or take = false means not take FX
end


function Is_TrackFX_Open(tr, fx_index)
	if tr then
		for fx_idx = 0, r.TrackFX_GetCount(tr)-1 do
			if r.TrackFX_GetOpen(tr, fx_idx) and fx_idx == fx_index then return true end
		end
		for fx_idx = 0, r.TrackFX_GetRecCount(tr)-1 do
			if r.TrackFX_GetOpen(tr, fx_idx+0x1000000) and fx_idx+0x1000000 == fx_index then return true end
		end
	end
end


function Change_FX_Parameter(is_last_touched, fx_track, fx_take, fx_idx, parm_idx, sign)
local obj = fx_track or fx_take
local GetFXParam, GetFXParamEx, GetParamStepSizes, SetFXParam = table.unpack(fx_track and {r.TrackFX_GetParam, r.TrackFX_GetParamEx, r.TrackFX_GetParameterStepSizes, r.TrackFX_SetParam} or fx_take and {r.TakeFX_GetParam, r.TakeFX_GetParamEx, r.TakeFX_GetParameterStepSizes, r.TakeFX_SetParam})
--local cur_val, minval, maxval = GetFXParam(obj, fx_idx, parm_idx)
local cur_val, minval, maxval, midval = GetFXParamEx(fx_track, fx_idx, parm_idx)
local retval, step, smallstep, largestep, istoggle = GetParamStepSizes(obj, fx_idx, parm_idx) -- if no step retval is false
local new_val = cur_val + (retval and step*sign or 0.01*sign)
local new_val = new_val < minval and minval or new_val > maxval and maxval or new_val -- prevent exceeding range limits
end


function Get_FX_Env_Src_Parameter(env) -- get fx parameter the envelope belongs to
local tr = r.GetEnvelopeInfo_Value(env, 'P_TRACK') -- if take env is selected returns 0.0, otherwise pointer
local take = r.GetEnvelopeInfo_Value(env, 'P_TAKE') -- if track env is selected returns 0.0, otherwise pointer
local tr, take = tr ~= 0 and tr, take ~= 0 and take -- validate
local retval, env_name = r.GetEnvelopeName(env)
-- capture fx name displayed in the fx chain, fx env name format is 'parm name / fx name'
local fx_name = env_name:match('.+ / (.+)') -- clean name, without the plugin type prefix
local cur_val, minval, maxval, step
local CountFX, GetFXName, GetNumParams, GetFXEnvelope, GetFXParam, GetParamStepSizes = table.unpack(tr and {r.TrackFX_GetCount, r.TrackFX_GetFXName, r.TrackFX_GetNumParams, r.GetFXEnvelope, r.TrackFX_GetParam, r.TrackFX_GetParameterStepSizes} or take and {r.TakeFX_GetCount, r.TakeFX_GetFXName, r.TakeFX_GetNumParams, r.TakeFX_GetEnvelope, r.TakeFX_GetParam, r.TakeFX_GetParameterStepSizes})
local obj = take or tr
	for fx_idx = 0, CountFX(obj)-1 do
	local retval, name = GetFXName(obj, fx_idx)
		if name:match(': (.+) %(') == fx_name or name == fx_name then -- either default or custom plugin name
			for parm_idx = 0, GetNumParams(obj, fx_idx)-1 do
			local parm_env = GetFXEnvelope(obj, fx_idx, parm_idx, false) -- create false
				if parm_env == env then
				local cur_val, minval, maxval = GetFXParam(obj, fx_idx, parm_idx)
				local retval, step, smallstep, largestep, istoggle = GetParamStepSizes(obj, fx_idx, parm_idx) -- if no step retval is false
				return cur_val, minval, maxval, step ~= 0 and step
				end
			end
		end
	end

end


function Get_Take_Pitch_Env_Snap()
-- Preferences -> Editing behavior -> Envelope display -> Default per take pitch envelope ... snap:
local f = io.open(r.get_ini_file(),'r')
local cont = f:read('*a')
f:close()
local val = cont:match('pitchenvrange=(.-)\n')
local val = #val > 0 and tonumber(val)
local snap
-- Thanks to Mespotine
-- https://mespotin.uber.space/Ultraschall/Reaper_Config_Variables.html
-- 'pitchenvrange' value is the sum of the range integer and then snap integer
-- snap integer is an 8 bit value and is changed by 8 bit increments
-- statring from 0, so if the value is 328 the settings are
-- 72 (range) + 256 (1 st snap)
-- the range cannot be equal to or greater than 256,
-- because when added to the snap value it will cause clash with the next snap value
	if val > 256 and val < 512 then snap = 1
	elseif val > 512 and val < 768 then snap = 0.5
	elseif val > 768 and val < 1024 then snap = 0.25
	elseif val > 1024 and val < 1280 then snap = 0.1
	elseif val > 1280 and val < 1537 then snap = 0.05
	elseif val > 1537 or val < 256 then snap = 0.01 end
-- if snap is OFF (< 256) natively pitch can be set
-- by as little as 1/1000st which isn't practical
-- so in this case the unit is 0.01st i.e. 1 cent
return snap
end


function Get_Vol_Env_Range()
-- Preferences -> Editing behavior -> Envelope display -> Volume envelope range
local f = io.open(r.get_ini_file(),'r')
local cont = f:read('*a')
f:close()
local val = cont:match('volenvrange=(.-)\n')
local val = tonumber(val)
-- Thanks to Mespotine
-- https://mespotin.uber.space/Ultraschall/Reaper_Config_Variables.html
	if val then
	local bit1, bit2 = val&1, val&4
	-- the lower limit is -inf so it doesn't have to be returned
	-- the lower limit is set within the routine to another value
	return bit1 == 1 and bit2 == 0 and 0
	or bit1 == 0 and bit2 == 0 and 6
	or bit1 == 0 and bit2 == 4 and 12
	or bit1 == 1 and bit2 == 4 and 24
	end
end


function Get_Tooltip_Settings()
-- Preferences -> Appearance - Appearance settings - Tooltips:
local f = io.open(r.get_ini_file(),'r')
local cont = f:read('*a')
f:close()
local val = cont:match('tooltips=(.-)\n')
local delay = cont:match('tooltipdelay=(.-)\n') -- likely in ms
local val, delay = tonumber(val), tonumber(delay)
local UI, itm_env, env_hov
-- Thanks to Mespotine
-- https://mespotin.uber.space/Ultraschall/Reaper_Config_Variables.html
	if val then
	UI, itm_env, env_hov = val&2 == 0, val&1 == 0, val&4 == 0 -- UI elements, Items/envelopes, Envs on hover -- enabled
	end
return UI, itm_env, env_hov, delay
end


function Get_Item_Edge_At_Mouse()
local cur_pos = r.GetCursorPosition()
local x, y = r.GetMousePosition()
local item, take = r.GetItemFromPoint(x,y, false) -- allow_locked false
local left_edge, right_edge
	if item then
	r.PreventUIRefresh(1)
	local px_per_sec = r.GetHZoomLevel() -- 100 px per 1 sec = 1 px per 0.01 sec or 10 ms
	local left = r.GetMediaItemInfo_Value(item, 'D_POSITION')
	local right = left + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
	r.Main_OnCommand(40514, 0) -- View: Move edit cursor to mouse cursor (no snapping)
	local new_cur_pos = r.GetCursorPosition()
		if math.abs(left - new_cur_pos) <= 0.01*1000/px_per_sec -- condition the minimal distance by the zoom resolution, the greater the zoom the smaller is the required distance, the base value of 10 ms or 1 px which is valid for zoom at 100 px per 1 sec seems optimal, 1000/px_per_sec is pixels per ms
		then
		left_edge = true
		elseif math.abs(right - new_cur_pos) <= 0.01*1000/px_per_sec then
		right_edge = true
		end
	r.SetEditCurPos(cur_pos, false, false) -- moveview, seekplay false // restore orig edit cursor pos
	r.PreventUIRefresh(-1)
	end
return left_edge, right_edge
end


function Get_Autom_Item_At_Mouse_Cursor(env, pos_at_mouse) -- returns AI index
	for ai_idx = 0, r.CountAutomationItems(env)-1 do
	local start = r.GetSetAutomationItemInfo(env, ai_idx, 'D_POSITION', 0, false) -- is_set false, value 0
	local fin = start + r.GetSetAutomationItemInfo(env, ai_idx, 'D_LENGTH', 0, false) -- is_set false, value 0
		if start <= pos_at_mouse and fin >= pos_at_mouse then return ai_idx end
	end
end


function Track_Controls_Locked(tr)
r.PreventUIRefresh(1)
local mute_state = r.GetMediaTrackInfo_Value(tr, 'B_MUTE')
r.SetMediaTrackInfo_Value(tr, 'B_MUTE', mute_state ~ 1) -- flip the state
local mute_state_new = r.GetMediaTrackInfo_Value(tr, 'B_MUTE')
local locked
	if mute_state == mute_state_new then locked = 1
	else r.SetMediaTrackInfo_Value(tr, 'B_MUTE', mute_state) -- restore
	end
r.PreventUIRefresh(-1)
return locked
end


function validate_vol_resol(setting) -- TO USE WITH API
return #setting:gsub(' ','') > 0 and tonumber(setting) and tonumber(setting) or 0.05
end

function validate_setting(setting)
return #setting:gsub(' ','') > 0 and tonumber(setting)
and math.floor(tonumber(setting)) > 0 and math.floor(tonumber(setting)) or 1
end

function validate_setting2(setting)
return #setting:gsub(' ','') > 0 and tonumber(setting) or 1
end


local build = r.GetAppVersion():match('[%d%.]+') -- or ('(.+)/')
	if tonumber(build) < 6.36 then
	r.MB('     The script is only compatible\n\nwith REAPER builds 6.36 onwards','ERROR', 0)
	return r.defer(function() do return end end)
	end

	if Script_Not_Enabled(ENABLE_SCRIPT) then return r.defer(function() do return end end) end


-- Validate user settings
TRACK_VOL_RESOLUTION = validate_vol_resol(TRACK_VOL_RESOLUTION)
TRACK_PAN_RESOLUTION = validate_setting(TRACK_PAN_RESOLUTION)
WIDTH_RESOLUTION = validate_setting(WIDTH_RESOLUTION)
DUAL_PAN_RESOLUTION = validate_setting(DUAL_PAN_RESOLUTION)
TRACK_TIME_OFFSET_RESOLUTION = validate_setting(TRACK_TIME_OFFSET_RESOLUTION)
TEMPO_MAP_ENV_RESOLUTION = validate_setting2(TEMPO_MAP_ENV_RESOLUTION)
PLAYRATE_ENV_RESOLUTION = #PLAYRATE_ENV_RESOLUTION:gsub(' ','') > 0 and tonumber(PLAYRATE_ENV_RESOLUTION) or 'def'
ITEM_TAKE_VOL_RESOLUTION = validate_vol_resol(ITEM_TAKE_VOL_RESOLUTION)
ITEM_TAKE_VEL_RESOLUTION = validate_vol_resol(ITEM_TAKE_VEL_RESOLUTION)
TAKE_PAN_RESOLUTION = validate_setting(TAKE_PAN_RESOLUTION)
TAKE_PITCH_RESOLUTION = validate_setting(TAKE_PITCH_RESOLUTION)
TAKE_PITCH_ENV_RESOLUTION = validate_setting2(TAKE_PITCH_ENV_RESOLUTION)


local x, y = r.GetMousePosition()
local retval, ui_obj = r.GetThingFromPoint(x,y) -- if track is locked its UI elements aren't returned
local vol, pan, width = ui_obj == 'tcp.volume', ui_obj == 'tcp.pan', ui_obj == 'tcp.width'
local TCP = vol or pan or width -- tr and info_code < 1 -- not envelope and not docked FX window in info_code
local TCP = not TCP and Get_TCP_Under_Mouse() or TCP -- only run if ui elements above weren't found; for the time offset parameter
local env = r.GetCursorContext() == 2 and r.GetSelectedEnvelope(0)
local retval, env_name = table.unpack(env and {r.GetEnvelopeName(env)} or {})
local item, take = r.GetItemFromPoint(x, y, false) -- allow_locked false
local is_last_touched, track_idx, fx_track, item_idx, fx_item, take_idx, fx_take, fx_idx, parm_idx = table.unpack(not TCP and not take and {GetLastTouchedFX()} or {nil})
local is_tr_env = env and r.GetEnvelopeInfo_Value(env, 'P_TRACK') ~= 0 -- if take env is selected returns 0.0, otherwise pointer
local is_take_env = env and r.GetEnvelopeInfo_Value(env, 'P_TAKE') ~= 0 -- if track env is selected returns 0.0, otherwise pointer
local env = not item and is_tr_env and not TCP and env or item and is_take_env and env -- only allow affecting envs when cursor is not over TCP or item while env is selected and cur context is 2

RESOLUTION = (take or fx_take) and ITEM_TAKE_VOL_RESOLUTION or vol and TRACK_VOL_RESOLUTION or pan and TRACK_PAN_RESOLUTION or width and WIDTH_RESOLUTION or (TCP or fx_track) and TRACK_TIME_OFFSET_RESOLUTION or env and TRACK_VOL_RESOLUTION -- the 1st and the last options is meant to satisfy the condition for the routine, the actual RESOLUTION for take, fx_take and envelopes respectively will be selected within the routine itself; fx_track condition covers track FX, the actual FX param resolution will be processed within the routine

	if env or not env and not item and not TCP then
		if ({GetFocusedFX()})[9] then Tooltip(' \n\n'..(' Monitoring FX are not supported '):upper():gsub('.', '%0 ')..'\n\n ')
		return r.defer(function() do return end end) end
	end

--------- MAIN ROUTINE

	if (env or item or TCP or fx_idx) and RESOLUTION then

	function Calc_New_Vol_Value(old_val, add_val, tr, item, take) -- add_val is positive or negative
	-- http://forum.cockos.com/showpost.php?p=1608719&postcount=6
	-- OR https://forum.cockos.com/showthread.php?p=1608719
	-- spotted in 'Thonex_Adjust selected items vol by greatest peak overage'
	-- https://forums.cockos.com/showthread.php?t=210811
	local old_val_dB = 20*math.log(old_val, 10)
	local new_val_dB = old_val_dB + add_val or 0
	--	if tr or take then
	local new_val_dB = new_val_dB > 12 and 12 or new_val_dB < -60 and -60 or new_val_dB -- prevent exceeing track vol control upper limit because there's no cap in the API and limit the lowest value to -60 dB, any lower isn't practical // via API item volume upper limit is 12dB as well even through vol control upper limit is 24dB
	return 10^(new_val_dB/20), new_val_dB -- the 2nd return value is for take vol tooltip
	end

	local _, scr_name, sect_ID, cmd_ID, _, _, val = r.get_action_context()
	local sign = val < 0 and -1 or 1
	local tr, info_code = r.GetTrackFromPoint(x, y)
	-- Last touched fx overrides selected envelope because the former is always valid unless the mouse cursor is over TCP or item
	local env = not Is_TrackFX_Open(fx_track, fx_idx) and env -- only validate selected envelope if the last touched FX isn't visible in the fx chain or its floating window is closed
	local sel_obj_cnt = not fx_idx and (take and r.CountSelectedMediaItems(0) or tr and r.CountSelectedTracks(0) or env and r.CountEnvelopePointsEx(env, -1)) -- autoitem_idx -1 for the envelope points
	local sel_obj_cnt = not fx_idx and (sel_obj_cnt > 0 and (take and not r.IsMediaItemSelected(item) or TCP and not r.IsTrackSelected(tr)) and 0 or sel_obj_cnt) -- if object under mouse isn't selected, ignore other selected objects by preventing loop start below

	-- TRACK/TAKE ENVELOPES
		if env then
			local function Get_Env_Point_At_Time(env, item, take)
			r.PreventUIRefresh(1)
			local cur_pos = r.GetCursorPosition()
			r.Main_OnCommand(40514, 0) -- View: Move edit cursor to mouse cursor (no snapping)
			local pt_time = r.GetCursorPosition()
			local AI_idx = Get_Autom_Item_At_Mouse_Cursor(env, pt_time)
				if item then -- convert cursor project time to time within item
				local item_pos = r.GetMediaItemInfo_Value(r.GetMediaItemTake_Item(take), 'D_POSITION')
				local offset = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
				local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE') -- affects take start offset and take env point pos
				pt_time = (pt_time - item_pos + offset)*playrate
				end
			local pt_idx = r.GetEnvelopePointByTimeEx(env, AI_idx or -1, pt_time) -- autoitem_idx for visible AI points or -1 for the envelope points
			local retval, time, value, shape, tens, is_sel = r.GetEnvelopePointEx(env, AI_idx or -1, pt_idx) -- autoitem_idx for visible AI points or -1 for the envelope points
			r.SetEditCurPos(cur_pos, false, false) -- moveview, seekplay false // restore orig edit cursor pos
			r.PreventUIRefresh(-1)
			return pt_idx, value, is_sel, AI_idx
			end

			local function Count_Sel_Points(env, pt_idx, AI_idx) -- and evaluate is specific point is selected
			local sel_pt_cnt, is_pt_idx_sel = 0
			local pt_cnt = r.CountEnvelopePointsEx(env, AI_idx or -1) -- autoitem_idx for visible AI points or -1 for the envelope points
				for idx = 0, pt_cnt-1 do
				local retval, time, value, shape, tens, is_sel = r.GetEnvelopePointEx(env, AI_idx or -1, idx) -- autoitem_idx for visible AI points or -1 for the envelope points
				sel_pt_cnt = is_sel and sel_pt_cnt+1 or sel_pt_cnt
				is_pt_idx_sel = idx == pt_idx and is_sel or is_pt_idx_sel
				end
			return pt_cnt, sel_pt_cnt
			end

		local pt_idx, pt_val, is_pt_idx_sel, AI_idx = Get_Env_Point_At_Time(env, item, take)
		local pt_cnt, sel_pt_cnt = Count_Sel_Points(env, pt_idx, AI_idx)
		local pt_cnt = is_pt_idx_sel and pt_cnt or 0 -- if point under mouse isn't selected, ignore other selected points by preventing loop start below
		local retval, env_name = r.GetEnvelopeName(env)
		local fx_env_t = env_name:match('^.+ / .+$') and {Get_FX_Env_Src_Parameter(env)} -- fx env name format is 'parm name / fx name' // must precede the next variables declaration to avoid matches of regular envelopes names in the fx envelope name
		local vol, pan, width, pitch, mute, tempo, playrate = table.unpack(not fx_env_t and {n=8, env_name:match('Volume'), env_name:match('Pan'), env_name:match('Width'), env_name:match('Pitch'), env_name:match('Mute'), env_name:match('Tempo'), env_name:match('Playrate'), 1} or {nil}) -- 1 is to allow table.unpack work with nils so it runs until the last valid value // table.unpack(...{} or {}, 1, 7) could be used instead to unpack all 7 fields regardless of nils
		local midi_take = take and r.TakeIsMIDI(take)
		RESOLUTION = vol and is_tr_env and TRACK_VOL_RESOLUTION or vol and is_take_env and (midi_take and ITEM_TAKE_VEL_RESOLUTION or ITEM_TAKE_VOL_RESOLUTION) or pan and is_tr_env and TRACK_PAN_RESOLUTION or pan and is_take_env and TAKE_PAN_RESOLUTION or width and WIDTH_RESOLUTION or pitch and TAKE_PITCH_ENV_RESOLUTION or mute and 1 or tempo and TEMPO_MAP_ENV_RESOLUTION or playrate and PLAYRATE_ENV_RESOLUTION or fx_env_t and fx_env_t[4] -- fx_env_t[4] is step var

			local function Change_Point_Val(env, pt_idx, is_sel, pt_val, RESOLUTION, sign, vol, pan, width, AI_idx) -- env name variables aren't used as arguments to conserve space, due to their being identical inside and outside of the function using them as arguments isn't necessary, which is true for the most other variables as well but which are included for clarity
			local scale_mode = r.GetEnvelopeScalingMode(env)
			local val_scaled = r.ScaleFromEnvelopeMode(scale_mode, pt_val)
			local pt_val_new
				if vol then
				local upper_limit = Get_Vol_Env_Range()
				local pt_val_dB = 20*math.log(val_scaled, 10) + RESOLUTION*sign
				local pt_val_dB = pt_val_dB > upper_limit and upper_limit or pt_val_dB < -60 and -60 or pt_val_dB -- prevent exceeing track/take vol env upper limit because there's no cap in the API and limit the lowest value to -60 dB, any lower isn't practical
				pt_val_new = 10^(pt_val_dB/20)
				elseif pan or width then
				pt_val_new = sign < 0 and val_scaled <= -1 and -1 or sign > 0 and val_scaled >= 1 and 1 or val_scaled+(RESOLUTION/100)*sign -- pan and width extreme value is never equal -1 or 1 even though it's displayed as such in the Console, hence < and > are used to prevent going beyond 100%L or 100%R (pan) and 0% and 100% (width) which happens because there's no cap in the API; RESOLUTION/100 because API range is -1 - +1
				elseif pitch then
				local pitch_env_unit = Get_Take_Pitch_Env_Snap()
				pt_val_new = val_scaled+pitch_env_unit*RESOLUTION*sign
				elseif mute then -- mute
				pt_val_new = (sign < 0 and val_scaled == 0 or sign > 0 and val_scaled == 1) and val_scaled or RESOLUTION*sign -- since like in pan and width there's no cap for mute so values keep being added beyond the limits which then need to be subtracted to get to the valid range, hence prevent exceeding the range by sticking to the current value if mousewheel movement would cause it to exceed the limit
				elseif tempo then
				pt_val_new = val_scaled+RESOLUTION*sign
				pt_val_new = sign < 0 and pt_val_new < 40 and 40 or sign > 0 and pt_val_new > 280 and 280 or pt_val_new -- preventing exceeding the default range limits, can set to lower and higher which will be displayed in the UI, but it's hardly practical
				elseif playrate then -- for this env val_scaled is the same as direct value
				RESOLUTION = RESOLUTION == 'def' and (val_scaled < 1 and 0.01 or val_scaled > 1 and 0.03) or RESOLUTION -- either REAPER default or user resolution
				pt_val_new = val_scaled+RESOLUTION*sign
				pt_val_new = sign < 0 and pt_val_new < 0.1 and 0.1 or sign > 0 and pt_val_new > 4 and 4 or pt_val_new -- preventing exceeding the default range limits, 0.1 - 4
				elseif fx_env_t then
				RESOLUTION = not RESOLUTION and 0.01 or RESOLUTION -- if no step RESOLUTION will be nil, set it to 0.01 the value is arbitrary, won't work well for all parameters of non-JSFX due to differences in their resolution
				pt_val_new = val_scaled+RESOLUTION*sign
				local minval, maxval = fx_env_t[2], fx_env_t[3] -- for clarity
				pt_val_new = sign < 0 and pt_val_new < minval and minval or sign > 0 and pt_val_new > maxval and maxval or pt_val_new -- preventing exceeding the range limits
				end
			local pt_val_new = r.ScaleToEnvelopeMode(scale_mode, pt_val_new)
			r.SetEnvelopePointEx(env, AI_idx or -1, pt_idx, timeIn, pt_val_new, shapeIn, tensionIn, is_sel, noSortIn) -- autoitem_idx for visible AI points or -1 for the envelope points; is_sel is required for autom item points otherwise selected points get deselected
			end

		local change = not is_pt_idx_sel and Change_Point_Val(env, pt_idx, is_pt_idx_sel, pt_val, RESOLUTION, sign, vol, pan, width, AI_idx) -- point directly under mouse cursor if no points are selected
			if is_pt_idx_sel then -- if point under mouse is selected use loop in case some other points are selected as well, uncluding the one under mouse
				for pt_idx = 0, pt_cnt-1 do
				local retval, time, pt_val, shape, tens, is_sel = r.GetEnvelopePointEx(env, AI_idx or -1, pt_idx) -- autoitem_idx for visible AI points or -1 for the envelope points
					if is_sel then
					Change_Point_Val(env, pt_idx, is_sel, pt_val, RESOLUTION, sign, vol, pan, width, AI_idx)
					end
				end
			r.Envelope_SortPointsEx(env, -1) -- autoitem_idx -1 for the envelope points
			end

	-- ITEM/TAKE VOL, TAKE PAN/PITCH
		elseif item and r.GetMediaItemInfo_Value(item, 'C_LOCK')&1 ~= 1 then -- take volume/pan/pitch // not locked
		local left_edge, right_edge = Get_Item_Edge_At_Mouse()
		local mult_takes = r.CountTakes(item) > 1
		RESOLUTION = left_edge and TAKE_PAN_RESOLUTION or right_edge and TAKE_PITCH_RESOLUTION or RESOLUTION -- the last is take vol
		local tooltip = (left_edge or right_edge or mult_takes) and {Get_Tooltip_Settings()} -- get toolip settings for items to display tooltips with take perameters which aren't available on the UI
		local tooltip = tooltip and tooltip[2] -- item/envelope

			local function Change_Item_Take_Vol(item, cur_item, take, cur_take, sel_obj_cnt, mult_takes, RESOLUTION, sign, tooltip) -- item and take args are obj under the mouse cursor
			local cur_item, cur_take = cur_item or item, cur_take or take
			local vol = (sel_obj_cnt == 0 or not mult_takes) and r.GetMediaItemInfo_Value(cur_item, 'D_VOL') or r.GetMediaItemTakeInfo_Value(cur_take, 'D_VOL')
			local is_midi = r.TakeIsMIDI(cur_take)
			local vel_new = is_midi and vol+ITEM_TAKE_VEL_RESOLUTION*sign -- if take is MIDI use direct values for velocity
			local vel_new = vel_new and (sign < 0 and vel_new <= 0.10 and 0.10 or sign > 0 and vel_new >= 16 and 16) or vel_new -- prevent exceeding velocity control range limits
			local vol_new, new_val_dB = table.unpack(is_midi and {vel_new, vel_new} or {Calc_New_Vol_Value(vol, RESOLUTION*sign, tr, cur_item, mult_takes and cur_take)}) -- either direct values for MIDI take velocity or conversion between direct values and decibels // in Calc_New_Vol_Value() function cur_take will be false if item only contains 1 take so that item volume can be manipulated instead of the take volume
			local set = (sel_obj_cnt == 0 or not mult_takes) and r.SetMediaItemInfo_Value(cur_item, 'D_VOL', vol_new) or r.SetMediaItemTakeInfo_Value(cur_take, 'D_VOL', vol_new)
			local obj_under_mouse = cur_item == item or cur_take == take -- only display readout for item under mouse cursor
			local sign = not is_midi and round(new_val_dB, 2) > 0 and '+' or '' -- for readout
			local displ = tooltip and obj_under_mouse and Tooltip(sign..round(new_val_dB, 2)..(is_midi and '' or 'dB')) -- since the value is float rather than exact integer, round it to integer // for MIDI take velocity don't display dB
			end

			local function Change_Item_Take_Parm(item, item1, take, take1, left_edge, right_edge, sel_obj_cnt, mult_takes, RESOLUTION, sign, tooltip) -- sel_obj_cnt is only relevant for volume since ther're two kinds of volume, item and take // item and take args are obj under the mouse cursor
			local displ_val -- to feed to the Tooltip() function
			local cur_item, cur_take = item1 or item, take1 or take
				if left_edge then -- pan
				local pan = r.GetMediaItemTakeInfo_Value(take, 'D_PAN') -- too many decimal places unlike in the track pan return value where there're only 2
				local pan = round(pan, 2) -- round to 2 decimal places
				local pan_new = sign < 0 and pan <= -1 and -1 or sign > 0 and pan >= 1 and 1 or pan+(RESOLUTION/100)*sign -- pan and width extreme value is never equal -1 or 1 even though it's displayed as such in the Console, hence < and > are used to prevent going beyond 100%L or 100%R (pan) and 0% and 100% (width) which happens because there's no cap in the API; RESOLUTION/100 because API range is -1 - +1
				displ_val = tooltip and (pan_new ~= 0 and math.abs(math.floor(pan_new*100+0.1))..(pan_new < 0 and '%L' or pan_new > 0 and '%R') or 'center') -- for some reason math.floor(pan_new*100) without +0.1 makes some negative values be rounded down to the next value instead of the integer part
				r.SetMediaItemTakeInfo_Value(take, 'D_PAN', pan_new)
				elseif right_edge then -- pitch
				local pitch = r.GetMediaItemTakeInfo_Value(take, 'D_PITCH') -- take pitch range is unlimited
				local pitch_new = pitch+RESOLUTION*sign
				displ_val = tooltip and (pitch_new > 0 and '+' or '')..math.floor(pitch_new)..' st'
				r.SetMediaItemTakeInfo_Value(take, 'D_PITCH', pitch_new)
				else -- volume/velocity
				Change_Item_Take_Vol(item, cur_item, take, cur_take, sel_obj_cnt, mult_takes, RESOLUTION, sign, tooltip)
				end
			r.UpdateItemInProject(item)
			local obj_under_mouse = cur_item == item or cur_take == take -- only display readout for item under mouse cursor
			local display = tooltip and displ_val and obj_under_mouse and Tooltip(displ_val) -- tooltip for take vol is generated inside Change_Item_Take_Vol() function // only display tooltip for the object under mouse
			end

		local change = sel_obj_cnt == 0 and Change_Item_Take_Parm(item, cur_item, take, cur_take, left_edge, right_edge, sel_obj_cnt, mult_takes, RESOLUTION, sign, tooltip) -- take directly under mouse cursor if no item is selected // item and take args are obj under the mouse cursor
			for i = 0, sel_obj_cnt-1 do -- all selected items if at least one of them is under mouse cursor, uncluding the one under mouse
			local cur_item = r.GetSelectedMediaItem(0,i)
			local cur_take = r.GetActiveTake(cur_item)
			Change_Item_Take_Parm(item, cur_item, take, cur_take, left_edge, right_edge, sel_obj_cnt, mult_takes, RESOLUTION, sign, tooltip) -- item and take args are obj under the mouse cursor
			end

	-- TRACK PAN/WIDTH
		elseif pan or width then -- track // when track is locked changes via API are blocked as well (good)
		local PARMNAME = pan and (pan_mode == 6 and 'D_DUALPANL' or 'D_PAN') or width and (pan_mode == 6 and 'D_DUALPANR' or 'D_WIDTH')
		local pan_mode = tr and r.GetMediaTrackInfo_Value(tr, 'I_PANMODE')
		RESOLUTION = pan_mode == 6 and DUAL_PAN_RESOLUTION or RESOLUTION
			local function Change_Track_PanWidth(tr)
			local parm_val = r.GetMediaTrackInfo_Value(tr, PARMNAME) -- range -1 - +1
			local parm_val_new = sign < 0 and parm_val <= -1 and -1 or sign > 0 and parm_val >= 1 and 1 or parm_val+(RESOLUTION/100)*sign -- pan and width extreme value is never equal -1 or 1 even though it's displayed as such in the Console, hence < and > are used to prevent going beyond 100%L or 100%R (pan) and 0% and 100% (width) which happens because there's no cap in the API; RESOLUTION/100 because API range is -1 - +1
			r.SetMediaTrackInfo_Value(tr, PARMNAME, parm_val_new)
			end
		local change = sel_obj_cnt == 0 and Change_Track_PanWidth(tr) -- track directly under mouse cursor if no track is selected
			for i = 0, sel_obj_cnt-1 do -- all selected tracks if at least one of them is under mouse cursor, uncluding the one under mouse
			local tr = r.GetSelectedTrack(0,i)
			Change_Track_PanWidth(tr)
			end

	-- TRACK VOL
		elseif vol then -- track // when track is locked changes via API are blocked as well (good)
			local function Change_Track_Vol(tr, RESOLUTION, sign)
			local vol = r.GetMediaTrackInfo_Value(tr, 'D_VOL')
			local vol_new = Calc_New_Vol_Value(vol, RESOLUTION*sign, tr, item, take) -- item, take are irrelevant here
			r.SetMediaTrackInfo_Value(tr, 'D_VOL', vol_new)
			end
		local change = sel_obj_cnt == 0 and Change_Track_Vol(tr, RESOLUTION, sign) -- track directly under mouse cursor if no track is selected
			for i = 0, sel_obj_cnt-1 do -- all selected tracks if at least one of them is under mouse cursor, uncluding the one under mouse
			local tr = r.GetSelectedTrack(0,i)
			Change_Track_Vol(tr, RESOLUTION, sign)
			end

	-- TRACK PLAYBACK OFFSET
		elseif sel_obj_cnt and not Track_Controls_Locked(tr) then -- time offset // track controls aren't locked // sel_obj_cnt condition helps to zero in on the track rather than on the FX window since it's only valid if the target is TCP // tr is the one under the mouse cursor
			local function Change_Track_Time_Offset(tr, cur_tr, RESOLUTION, sign, tooltip)
			local cur_tr = cur_tr or tr
			local flags = r.GetMediaTrackInfo_Value(tr, 'I_PLAY_OFFSET_FLAG')
			local ON = flags&1~= 1
			local ms, samples = ON and flags&2 ~= 2, ON and flags&2 == 2 -- ms range is -500 - +500 represented by decimals with 3 decimal places, e.g. 68 = 0.068; samples range is -8192 - +8192 represented by floats with one decimal place occupied by 0
			local val_new
				if ON then
				local val = r.GetMediaTrackInfo_Value(cur_tr, 'D_PLAY_OFFSET')
				local RESOLUTION = ms and RESOLUTION/1000 or RESOLUTION -- convert RESOLUTION value to agree with ms or samples unit
				val_new = val+RESOLUTION*sign
				val_new = ms and (val_new < -0.5 and -0.5 or val_new > 0.5 and 0.5) or samples and (val_new < -8192 and -8192 or val_new > 8192 and 8192) or val_new -- prevent going over the range limits
				r.SetMediaTrackInfo_Value(cur_tr, 'D_PLAY_OFFSET', val_new)
				end
			local sign = val_new and val_new > 0 and '+' or '' -- for readout
			val_new = not val_new and 'is OFF' or ms and sign..math.floor(val_new*1000+0.5)..' ms' or sign..math.floor(val_new).. ' smpls' -- +0.5 to prevent possible glitch of math.floor to round negave values down to the next value if the only decomal place is occupied by 0
			local tr_under_mouse = cur_tr == tr -- only display readout for track under mouse cursor
			local display = tooltip and tr_under_mouse and Tooltip('Playback offset '..val_new)
			end
		local tooltip = Get_Tooltip_Settings() -- get toolip settings for items to display tooltips with take perameters which aren't available on the UI
		local change = sel_obj_cnt == 0 and Change_Track_Time_Offset(tr, cur_tr, RESOLUTION, sign, tooltip) -- track directly under mouse cursor if no track is selected // tr arg is the one under the mouse cursor
			for i = 0, sel_obj_cnt-1 do -- all selected tracks if at least one of them is under mouse cursor, uncluding the one under mouse
			local cur_tr = r.GetSelectedTrack(0,i)
			Change_Track_Time_Offset(tr, cur_tr, RESOLUTION, sign, tooltip) -- tr is the one under the mouse cursor
			end

	-- TRACK/TAKE FX
		elseif fx_idx and Is_TrackFX_Open(fx_track, fx_idx) then -- only target FX parameters when last touched FX is visible in the FX chain or in a floating window
		Change_FX_Parameter(is_last_touched, fx_track, take, fx_idx, parm_idx, sign)

		end

	return r.defer(function() do return end end)

	end





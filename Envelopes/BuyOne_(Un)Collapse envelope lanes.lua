--[[
ReaScript Name: (Un)Collapse envelope lanes (18 scripts)
Author: BuyOne
Version: 1.2
Changelog: #Added support for theme's default uncollapsed height if starts out from collapsed state
Author URL: https://forum.cockos.com/member.php?u=134058
Licence: WTFPL
Screenshots: https://raw.githubusercontent.com/Buy-One/screenshots/main/(Un)Collapse%20envelope%20lanes.gif
REAPER: at least v5.962  		
Metapackage: true
Provides: 	. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Collapse selected envelope lane in track.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Uncollapse selected envelope lane in track.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Collapse selected envelope lane or all lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Uncollapse selected envelope lane or all lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Collapse selected envelope lane uncollapse others in track.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Uncollapse selected envelope lane collapse others in track.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Alternate collapsing selected envelope lane and other lanes in track.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Collapse track envelope lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Uncollapse track envelope lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Collapse FX envelope lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Uncollapse FX envelope lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Collapse all envelope lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Uncollapse all envelope lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Toggle collapse selected envelope lane in track.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Toggle collapse selected envelope lane or all lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Toggle collapse track envelope lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Toggle collapse FX envelope lanes in selected tracks.lua
		. > BuyOne_(Un)Collapse envelope lanes/BuyOne_Toggle collapse all envelope lanes in selected tracks.lua
About:	In these '(un)collapse envelope lane' scripts 
	'track envelope' means envelope of TCP controls, those 
	which are listed in the 'trim' (envelope) button context 
	menu or under 'Track Envelopes' heading in the track 
	envelope panel, including Send envelopes.  
	'FX envelope' means envelope of a track FX control.  
	With toggle scripts uncollapsed state gets priority, so
	if at least one envelope lane in selected tracks is 
	uncollapsed, it will be collapsed while collapsed lanes 
	will stay as they are.  
	Unidirectional scripts will always work according to their name,
	If there're no lanes to collapse or uncollapse nothing will happen.  
	The scripts don't support creation of undo point due 
	to REAPER internal design.
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- This setting is only relevant for envelope lanes which are fully collapsed
-- before the script is first run and there're no previously stored data
-- of such lanes height. Such data are saved with the project file and is
-- available across project sessions.
-- If empty or malfromed defaults to theme's default uncollapsed height

DEFAULT_UNCOLLAPSED_HEIGHT = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function Get_Envcp_Min_Height(ext_state_sect, env, cond) -- required to condition toggle and storage of current env lane height

local retval, env_chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
local env_chunk_new = env_chunk:gsub('LANEHEIGHT %d+', 'LANEHEIGHT 1.0') -- passing 1 sets envcp to its minimum (collapsed) height
r.SetEnvelopeStateChunk(env, env_chunk_new, false) -- isundo false
local min_height = r.GetEnvelopeInfo_Value(env, 'I_TCPH') -- chunk LANEHEIGHT val corresponds to value of the I_TCPH parameter, NOT of the I_TCPH_USED one
r.SetEnvelopeStateChunk(env, env_chunk, false) -- isundo false // restore chunk
local store = cond and r.SetExtState(ext_state_sect, 'envcp_min_h', min_height, false) -- persist false // store
return min_height

end


function Is_Any_Autom_Lane_UnCollapsed_And_Min_Height(ext_state_sect, scr_mode3, scr_mode4, scr_mode5, scr_mode6, theme_changed, envcp_min_h_stored)
local envcp_min_h
local cond = #envcp_min_h_stored == 0 or theme_changed
local envcp_min_h_stored = tonumber(envcp_min_h_stored)
	for i = 0, r.CountSelectedTracks2(0, true)-1 do -- wantmaster true
	local tr = r.GetSelectedTrack2(0, i, true) -- wantmaster true
		for i = 0, r.CountTrackEnvelopes(tr)-1 do
		local env = r.GetTrackEnvelope(tr, i)
		local is_fx_env = Is_Track_Envelope_FX_Envelope(tr, env)
			if scr_mode3
			or scr_mode4 and not is_fx_env
			or scr_mode5 and is_fx_env
			or scr_mode6 then
			local env_h = r.GetEnvelopeInfo_Value(env, 'I_TCPH')
			envcp_min_h = cond and not envcp_min_h and Get_Envcp_Min_Height(ext_state_sect, env, cond) or envcp_min_h_stored or envcp_min_h -- ensure that Get_Envcp_Min_Height() function only runs once during the loop
				if env_h > envcp_min_h then	return true, envcp_min_h end
			end
		end
	end
return false, envcp_min_h
end


function Un_Collapse_Envelope_Lane(env, envcp_min_h, is_uncollapsed)

local env_h = r.GetEnvelopeInfo_Value(env, 'I_TCPH')
local retval, env_h_data = r.GetSetEnvelopeInfo_String(env, 'P_EXT:height', '', false) -- setNewValue false

local uncollapse_px	= env_h <= envcp_min_h and not is_uncollapsed and env_h_data -- either uncollapse or collapse // 24 is minimum possible in v5 default theme, 27 in v6 // is_uncollapsed is for toggle script instances to make sure that if at least one env lane is uncollapsed only collapse action is possible // if envelope starts out collapsed before any height data is stored env_h_data var is an empty string

local store = (toggle or unidir_collapse) and env_h > envcp_min_h and r.GetSetEnvelopeInfo_String(env, 'P_EXT:height', env_h, true) -- setNewValue true // store current env lane height // do not store when unidir_uncollapse so multiple script runs don't store the new value in the background // the condition is applied here because for some reason the data aren't stored in 'toggle and not uncollapse_px or unidir_collapse' block below without it

local retval, env_chunk = r.GetEnvelopeStateChunk(env, '', false) -- isundo false
local LANEHEIGHT = env_chunk:match('LANEHEIGHT.-\n')

local env_chunk_new
local is_uncollapsed -- for alternating script instances

	if toggle and not uncollapse_px or unidir_collapse then -- collapse
	env_chunk_new = env_chunk:gsub('LANEHEIGHT %d+', 'LANEHEIGHT 1.0') -- 1.0 ensures that envcp gets collapsed fully
	elseif uncollapse_px and (toggle or unidir_uncollapse) -- uncollapse
	then
	local uncollapse_px = #uncollapse_px == 0 and DEFAULT_UNCOLLAPSED_HEIGHT or uncollapse_px -- if no previously stored data, use default/user setting
	env_chunk_new = env_chunk:gsub('LANEHEIGHT %d+', 'LANEHEIGHT '..uncollapse_px)
	is_uncollapsed = 1 -- for alternating script instances
	end

local update = env_chunk_new and r.SetEnvelopeStateChunk(env, env_chunk_new, false) -- isundo false

return is_uncollapsed -- for alternating script instances

end


function Is_Track_Envelope_FX_Envelope(tr, env)
	for fx_idx = 0, r.TrackFX_GetCount(tr)-1 do
		for parm_idx = 0, r.TrackFX_GetNumParams(tr, fx_idx)-1 do
		local fx_env = r.GetFXEnvelope(tr, fx_idx, parm_idx, false) -- create
			if fx_env == env then return true end
		end
	end
end


local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = scr_name:match('([^\\/_]+)%.%w+') -- without scripter name and file ext
local ext_state_sect = '(Un)Collapse envelope lanes' -- extended state will be shared by all script instances

DEFAULT_UNCOLLAPSED_HEIGHT = DEFAULT_UNCOLLAPSED_HEIGHT:gsub(' ','')
DEFAULT_UNCOLLAPSED_HEIGHT = tonumber(DEFAULT_UNCOLLAPSED_HEIGHT) and DEFAULT_UNCOLLAPSED_HEIGHT or 0 -- 0 sets env lane height to theme's default from both collapsed and uncollapsed states, but in the script it's only relevant when the script is first run while the lane is collapsed

local theme_stored = r.GetExtState(ext_state_sect, 'theme_cur')
local theme_cur = r.GetLastColorThemeFile():match('.+[\\/](.+)')
local theme_changed = theme_stored ~= theme_cur
	if theme_changed then
	r.SetExtState(ext_state_sect, 'theme_cur', theme_cur, false) -- persist false
	end


--local scr_name = '' -- TEST NAME

local scr_name = scr_name:lower()
-- conditions to set unidirectional or toggle operation
toggle = scr_name:match('toggle') or scr_name:match('alternate')
unidir_collapse = not toggle and scr_name:match('^collapse')
unidir_uncollapse = not toggle and scr_name:match('^uncollapse')


local scr_mode1 = scr_name:match('selected envelope')
--[[covers:
(Un)Collapse selected envelope lane in track
Toggle collapse selected envelope lane in track
]]
local scr_mode2 = scr_name:match('other') -- 2 complements 1
--[[covers:
(Un)Collapse selected envelope lane (un)collapse others in track
 Alternate collapsing selected envelope lane and other lanes in track
]]
local scr_mode3 = scr_name:match('all lanes') -- 3 bridges between 1 and 4-6
--[[covers:
(Un)Collapse selected envelope lane or all lanes in selected tracks
Toggle collapse selected envelope lane or all lanes in selected tracks
]]
local scr_mode4_6 = scr_name:match('selected tracks') -- 4_6 complements 4-6
-- 4, 5, 6 are mutually exclusive
local scr_mode4 = scr_name:match('track envelope')
--[[covers:
(Un)Collapse track envelope lanes in selected tracks
Toggle collapse track envelope lanes in selected tracks
]]
local scr_mode5 = scr_name:match('fx envelope')
--[[covers:
(Un)Collapse FX envelope lanes in selected tracks
Toggle collapse FX envelope lanes in selected tracks
]]
local scr_mode6 = scr_name:match('all envelope')
--[[covers:
(Un)Collapse all envelope lanes in selected tracks
Toggle collapse all envelope lanes in selected tracks
]]

	-- error if script name was changed beyond recognition
	if not toggle and not unidir_collapse and not unidir_uncollapse
	and not scr_mode1 and not scr_mode2 and not scr_mode2 and not scr_mode4_6
	and not scr_mode4 and not scr_mode5 and not scr_mode6 then
		function rep(n) -- number of repeats, integer
		return (' '):rep(n)
		end
	local br = '\n\n'
	r.MB([[The script name has been changed]]..br..rep(7)..[[which renders it inoperable.]]..br..
	[[   please restore the original name]]..br..[[  referring to the list in the header,]]..br..
	rep(9)..[[or reinstall the package.]], 'ERROR', 0)
	return r.defer(function() do return end end) end


local env = r.GetSelectedEnvelope(0)

	if scr_mode1 and env then

	local par_tr = r.GetEnvelopeInfo_Value(env, 'P_TRACK') -- exclude take envelopes

		if par_tr then
		local envcp_min_h_stored = r.GetExtState(ext_state_sect, 'envcp_min_h')
		local cond = #envcp_min_h_stored == 0 or theme_changed -- not stored or the stored val is outdated due to theme change
		local envcp_min_h = cond and Get_Envcp_Min_Height(ext_state_sect, env, cond) or tonumber(envcp_min_h_stored)
		r.PreventUIRefresh(1) -- must be placed after Get_Envcp_Min_Height() function as it prevents changing envcp height and getting the minimum height value via chunk
		local is_uncollapsed = Un_Collapse_Envelope_Lane(env, envcp_min_h)
			if scr_mode2 then
			-- 1st two conditions are for alternating unidirectional script instances
			if not is_uncollapsed and unidir_collapse then unidir_collapse, unidir_uncollapse = x, 1 -- x is nil
			elseif not toggle then unidir_collapse, unidir_uncollapse = 1, x
			-- condition for alternating toggle script instance to prevent collapse of all when all are uncollapsed
			elseif not is_uncollapsed then toggle, unidir_uncollapse = x, 1
			end
				for i = 0, r.CountTrackEnvelopes(par_tr)-1 do
				local tr_env = r.GetTrackEnvelope(par_tr, i)
				local act = tr_env ~= env and Un_Collapse_Envelope_Lane(tr_env, envcp_min_h, is_uncollapsed)
				end
			end
		r.PreventUIRefresh(-1) -- same
		end
	elseif scr_mode3 and not env or scr_mode4_6	then
	local envcp_min_h_stored = r.GetExtState(ext_state_sect, 'envcp_min_h')
	local is_uncollapsed, envcp_min_h = Is_Any_Autom_Lane_UnCollapsed_And_Min_Height(ext_state_sect, scr_mode3, scr_mode4, scr_mode5, scr_mode6, theme_changed, envcp_min_h_stored) -- condition collapsing all lanes of selected tracks if at least one lane is uncollapsed // not vice versa to ensure that uncollapsed lane height is stored as it's designed to only get stored before collapsing
	local is_uncollapsed = toggle and is_uncollapsed -- make this var only relevant for toggle scripts to allow non-toggle ones work one way regardless of differences between env lanes height (collapsed vs uncollapsed)
	r.PreventUIRefresh(1) -- must be placed after Is_Any_Autom_Lane_UnCollapsed_And_Min_Height() which includes Get_Envcp_Min_Height() function because it prevents changing envcp height and getting the minimum height value via chunk
		for i = 0, r.CountSelectedTracks2(0, true)-1 do -- wantmaster true
		local tr = r.GetSelectedTrack2(0, i, true) -- wantmaster true
			for i = 0, r.CountTrackEnvelopes(tr)-1 do
			local env = r.GetTrackEnvelope(tr, i)
			local is_fx_env = Is_Track_Envelope_FX_Envelope(tr, env)
				if scr_mode3
				or scr_mode4 and not is_fx_env
				or scr_mode5 and is_fx_env
				or scr_mode6 then
				Un_Collapse_Envelope_Lane(env, envcp_min_h, is_uncollapsed)
				end
			end
		end
	r.PreventUIRefresh(-1) -- same
	end

do return r.defer(function() do return end end) end -- TCP/EnvCP height changes cannot be undone even if they're registered in the undo history, native actions affecting TCP height don't even create undo points https://forums.cockos.com/showthread.php?t=262356 // must be placed outside of the block because at its end only the second condition is covered




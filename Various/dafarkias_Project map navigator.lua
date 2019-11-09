@description Project map navigator
@author Dafarkias
@version 0.92
@changelog Added borderless window option back in (shift+Lclick to center window on mouse)
@link Forum thread https://forums.cockos.com/showthread.php?t=226263
@about
  Project Map Navigator:

  Designed to assist in the workflow of REAPER items by visual assistance. 

  Somewhat similar to a map H.U.D. you might see in many popular video games these days, its purpose is to portray the overall view of a project in a scalable window, while providing a quick and efficient way to scroll and zoom throughout your REAPER project!

--[[
NAME: Dfk's Project Map

CATEGORY OF USE: Project Workflow
AUTHOR: Dafarkias
LEGAL RAMIFICATIONS: GPL v.3
COCKOS REAPER THREAD: https://forum.cockos.com/showthread.php?t=222795 
]]local VERSION = "0.91"--[[
REAPER: 5.984 (version used in development)
EXTENSIONS: js_ReaScriptAPI v0.993 (version used in development), SWS/S&M 2.10.0

[v0.5]
		*(script release)
[v0.51]
		*Minor bugs
[v0.52]
		*Added script internal "USER--AREA" customizations
		*Bug: post 6 (Nantho, 1st attempt)
[v0.6]
		*Added "load" screen
		*Added mouse cursor graphic
		*Added new project length detection
		*FEATURE: rmb marquee view
[v0.63]
		*revised rmb marquee
		*various attempted bug-fixes
[v0.64]
		*Attempted fix: Improper display of project markers/regions
		*Attempted fix: Inaccurate placement of track names
		*Added: display project marker/region names at top of window 
[v0.7]
		*Added: play/edit cursor display in project map
		*Added: place edit cursor using project map ( middle mouse button)
		*Added: play/stop playback using project map (spacebar)
		*Added more 'user area' variables
		*Reconfigured algorithm for 'drawing' items (hopefully fixed issue with 'frozen' items, or scaling issues)
[v0.75]
		*Added: mousewheel vertical zoom (mousewheel), modifier options in 'user area'
		*Added: mousewheel horizontal zoom (Shift+mousewheel), modifier options in 'user area'
		*Added: 'escape' key closes window
		*Added: window is pinned by default, option to change in 'user area'
		*Removed: track name collision with project/region markers 
[v0.8]
		*Added MIDI item display (NEW, testing required)
[v0.81]
		*Bug: project marker colors displaying incorrectly (Sumalc, post#64, first attempt)
[v0.85]
		*Added: project map displays the project loop-selection (can be disabled in 'user area')
		*Added: left/right arrows move edit cursor to nearest project/region marker in applicable direction
		*Added: up arrow alternates setting project loop ends to edit cursor position
		*Added: down arrow hard 'plays' from edit cursor position (doesn't cycle between play/stop like spacebar does)
		*Added: '/' toggles project loop on-and-off (project repeat)
[v0.86]
		*Added: 'm' toggles project mixer window visible
		*Added: ctrl+left-click (command for OSX) 'solos' project map track in mixer (toggle)
[v0.87]
		*Added: script refresh after changing track color
		*Added: 'r' refreshes script (force reload, good for updating media items, which don't auto-update)
		*Added: proper hotkey documentation concerning OSX/Windows specifications (Sumalc, post#72 (needs tested))
		*Added: 'Waveform_Definition' into script's 'user area'. Can improve performance. 
		*Added: marker number to beginning of title (Sumalc, post#72)
[v0.9]
		*Fixed: error with assignment of mousewheel modifier(s)
		*Added: 'user area' option for bordless window as default:
		*Added: F12 cycles between borderless window and bordered window 
[v0.91]
		*Removed borderless window due to glitch-error between window positioning and gfx.h
		*Fixed error with project/region marker color display
[v0.92]
		*Added borderless window option back in (shift+Lclick to center window on mouse)
		
--]]

--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA
--
local Pin_window_script                   = true        -- true/false 
local Borderless_Window                   = true        -- true/false
local Script_Load_Speed                   = 10          -- input values of 1 or greater. Use if load screen takes too long. Use with caution!
local Waveform_Definition                 = 5           -- 1-10: Adjusting this can greatly affect the script performance. Use with caution!
local Show_Project_Markers                = true        -- true/false
local Show_Track_Names                    = true        -- true/false
local Show_Project_Looper                 = true        -- true/false
local Show_MIDI_Notes                     = true        -- true/false: turning this off can improve script performance in large projects.
local Marquee_Box_Thickness               = 2           -- 1+
local Edit_Cursor_Width                   = 1           -- 0+: value of '0' will remove edit cursor from map display.
local Edit_Cursor_MarkerSnap              = 3           -- 0+: '0' will turn off snap function. 
local Play_Cursor_Width                   = 1           -- 0+: value of '0' will remove play cursor from map display.
local Invert_Vertical_MouseWheel_Zoom     = false       -- true/false
local Vertical_MouseWheel_Sensitivity     = 2           -- 1+
local Vertical_MouseWheel_Modifier        = "none"      --mousewheel+: "none", "WIN_alt", "WIN_control", "shift", OSX_option", "OSX_command"
local Invert_Horizontal_MouseWheel_Zoom   = false       -- true/false
local Horizontal_MouseWheel_Sensitivity   = 2           -- 1+
local Horizontal_MouseWheel_Modifier      = "shift"     --mousewheel+: "none", "WIN_alt", "WIN_control", "shift", OSX_option", "OSX_command"
--
--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA

function Msg(param) reaper.ShowConsoleMsg(tostring(param).."\n") end function Up() reaper.UpdateTimeline() reaper.UpdateArrange() end

--window vars
local _,_,display_width,display_height = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true )
local window_arrange = reaper.JS_Window_FindChildByID( reaper.GetMainHwnd(), 1000 )
local window_retval, window_position, _, window_min, window_max, _ = reaper.JS_Window_GetScrollInfo( window_arrange, "v" )
local arrange_retval, arrange_width, arrange_height = reaper.JS_Window_GetClientSize( window_arrange )
local window_script = 0 --set in function init()
local window_height = gfx.h  
local window_width  = gfx.w


--project vars 
local arrange_start, arrange_end = reaper.GetSet_ArrangeView2( 0, 0, 0, 0 ) local arrange_length = arrange_end - arrange_start
local loop_start, loop_end = reaper.GetSet_LoopTimeRange2( 0, 0, 1, 0, 0, 0 ) local loop_state = reaper.GetSetRepeatEx( 0, -1 ) 
local track = {} local track_name = {} local track_v_position = {} local track_color = {}
local items = {} local items_position = {} local items_length = {}
local script_name = " [Dfk's Project Map v"..VERSION.."]"
local project_name = reaper.GetProjectName( 0, "" )..script_name
local project_length = reaper.GetProjectLength( 0 )
local peaks = {} local track_buf = 1 local item_buf = 1
local midi_start = {} local midi_end = {} local midi_pitch = {} 
local lClick = 0
local rClick = 0

-- bounding box
local pinPointX = -1 local pinPointY = -1 
local mouseGrab = 3  
local b_x       = gfx.w/(project_length/arrange_start)
local b_y       = gfx.h/(window_max/window_position)
local b_w       = gfx.w/(project_length/arrange_length)
local b_h       = gfx.h/(window_max/arrange_height)
local b_xx      = b_x+b_w
local b_yy      = b_y+b_h

-- other vars
local edit_cursor = reaper.GetCursorPosition()
local gfx_char = {} gfx_char[0], gfx_char[1], gfx_char[2], gfx_char[3], gfx_char[4], gfx_char[5], gfx_char[6], gfx_char[7], gfx_char[8], gfx_char[9], gfx_char[10], gfx_char[11] = .2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
if Vertical_MouseWheel_Modifier == "shift" then Vertical_MouseWheel_Modifier = 8 elseif Vertical_MouseWheel_Modifier == "WIN_alt" then Vertical_MouseWheel_Modifier = 16 elseif Vertical_MouseWheel_Modifier == "WIN_control" then Vertical_MouseWheel_Modifier = 4 elseif Vertical_MouseWheel_Modifier == "OSX_option" then Vertical_MouseWheel_Modifier = 16 elseif Vertical_MouseWheel_Modifier == "OSX_command" then Vertical_MouseWheel_Modifier = 4 else Vertical_MouseWheel_Modifier = 0 end  
if Horizontal_MouseWheel_Modifier == "shift" then Horizontal_MouseWheel_Modifier = 8 elseif Horizontal_MouseWheel_Modifier == "WIN_alt" then Horizontal_MouseWheel_Modifier = 16 elseif Horizontal_MouseWheel_Modifier == "WIN_control" then Horizontal_MouseWheel_Modifier = 4 elseif Horizontal_MouseWheel_Modifier == "OSX_option" then Horizontal_MouseWheel_Modifier = 16 elseif Horizontal_MouseWheel_Modifier == "OSX_command" then Horizontal_MouseWheel_Modifier = 4 else Horizontal_MouseWheel_Modifier = 0 end 

function init()
	local d, w, h, x, y = 0,500,500,display_width/2-250,display_height/2-250 
	if reaper.HasExtState( "Dfk Project Map", "W_D" ) then d = reaper.GetExtState( "Dfk Project Map", "W_D" ) end
	if reaper.HasExtState( "Dfk Project Map", "W_W" ) then w = reaper.GetExtState( "Dfk Project Map", "W_W" ) end
	if reaper.HasExtState( "Dfk Project Map", "W_H" ) then h = reaper.GetExtState( "Dfk Project Map", "W_H" ) end
	if reaper.HasExtState( "Dfk Project Map", "W_X" ) then x = reaper.GetExtState( "Dfk Project Map", "W_X" ) end
	if reaper.HasExtState( "Dfk Project Map", "W_Y" ) then y = reaper.GetExtState( "Dfk Project Map", "W_Y" ) end
	gfx.init(project_name, w, h, d, x, y )
	window_script = reaper.JS_Window_Find( project_name, 1 ) if Pin_window_script == true then reaper.JS_Window_SetZOrder( window_script, "TOPMOST" ) end  
	if Borderless_Window == true then reaper.JS_Window_AttachResizeGrip(window_script) reaper.JS_Window_SetStyle(window_script, "POPUP") end 
	update_project( true ) 
end

function X_YtoDATA( X, Y )
		if X then X = project_length/(gfx.w/X) end
		if Y then Y = window_max/(gfx.h/Y) end
	return X, Y
end

function DATAtoX_Y( T, DY )
		if T then T = gfx.w/(project_length/T) end
		if V then V = gfx.h/(window_max/V) end
	return T, V
end

function COLORtoGFX( color, alpha )
	if alpha == nil then alpha = 1 end
	local r4, g4, b4 = reaper.ColorFromNative( color ) gfx.set(r4/255,g4/255,b4/255,alpha) 
end

function draw_load_screen()
		if track_buf ~= 0
	then local rows = math.floor(gfx.h/10)
			for a = 1, rows
		do
			gfx.x = math.random(0,gfx.w) gfx.y = math.random(0,rows)*10 gfx.set(0,1,0,math.random()) gfx.drawstr( "LOADING" )
		end
	end
end

function draw_items() 

	-- update vars
	window_retval, window_position, _, window_min, window_max, _ = reaper.JS_Window_GetScrollInfo( window_arrange, "v" )
	arrange_retval, arrange_width, arrange_height = reaper.JS_Window_GetClientSize( window_arrange )
	window_width = gfx.w window_height = gfx.h
	arrange_start, arrange_end = reaper.GetSet_ArrangeView2( 0, 0, 0, 0 ) arrange_length = arrange_end - arrange_start
	loop_start, loop_end = reaper.GetSet_LoopTimeRange2( 0, 0, 1, 0, 0, 0 ) loop_state = reaper.GetSetRepeatEx( 0, -1 ) 
	edit_cursor = reaper.GetCursorPosition()
	
	track_v_position = {} track_v_position[1] = 0 

		for a = 1, #track
	do 
		track_v_position[a+1] = track_v_position[a] + reaper.GetMediaTrackInfo_Value( reaper.GetTrack( 0, a-1 ), "I_WNDH" ) 
	end track_v_position[0] = track_v_position[#track_v_position] 

	b_x  = math.floor((gfx.w/(project_length/arrange_start))+.5)
	b_y  = math.floor((gfx.h/(track_v_position[0]/window_position))+.5)
	b_w  = math.floor((gfx.w/(project_length/arrange_length))+.5)
	b_h  = math.floor((gfx.h/(track_v_position[0]/arrange_height))+.5)
	b_xx = b_x+b_w
	b_yy = b_y+b_h

	-- draw items
	gfx.set(0,0,0,1) gfx.rect(0, 0, gfx.w, gfx.h, 1 ) -- clear box
		for a = 1, #track
	do 
			for b = 1, #items_position[a]
		do 
			local take = reaper.GetActiveTake( items[a][b] ) 
				if not take                    -- if NOTHING
			then
			else                             -- if MIDI or AUDIO
				-- Draw item rectangles
				-- internal
				if reaper.TakeIsMIDI(take) then local r4, g4, b4 = reaper.ColorFromNative( track_color[a] ) gfx.set(r4/255,g4/255,b4/255,0.95) else gfx.set(0.25,0.25,0.25,0.8) end
				gfx.rect(gfx.w/(project_length/items_position[a][b]), gfx.h/(track_v_position[0]/track_v_position[a]), gfx.w/(project_length/items_length[a][b]), (gfx.h/(track_v_position[0]/(track_v_position[a+1]-track_v_position[a]))), 1 )
				-- boundary
				gfx.set(0.2,0.5,0.5,0.7) 
				gfx.rect(gfx.w/(project_length/items_position[a][b]), gfx.h/(track_v_position[0]/track_v_position[a]), gfx.w/(project_length/items_length[a][b]), (gfx.h/(track_v_position[0]/(track_v_position[a+1]-track_v_position[a]))), 0 )
				
					if reaper.TakeIsMIDI(take)   -- if MIDI 
				then
						if Show_MIDI_Notes == true
					then
						gfx.set(0,0,0,0.9) local midi_height = math.floor((gfx.h/(track_v_position[a+1]-track_v_position[a]))/12)-4 if midi_height < 1 then midi_height = 1 end
						local midi_track = (gfx.h/(track_v_position[0]/(track_v_position[a+1]-track_v_position[a])))
							for m = 1, #midi_start[a][b]
						do
							local midi_width = math.floor(gfx.w/(project_length/(midi_end[a][b][m]-midi_start[a][b][m]))) if midi_width < 1 then midi_width = 1 end
							gfx.rect(gfx.w/(project_length/midi_start[a][b][m]), 2+math.floor((gfx.h/(track_v_position[0]/track_v_position[a])))+(((midi_pitch[a][b][m]/12)-math.floor(midi_pitch[a][b][m]/12))*(gfx.h/(track_v_position[0]/(track_v_position[a+1]-track_v_position[a])))), midi_width, midi_height, 1 )
						end
					end
				else                           -- if AUDIO
					-- Draw waveform
					-- set color
					local channel_y       = gfx.h/(track_v_position[0]/track_v_position[a])
					local channel_y_width = gfx.h/(track_v_position[0]/(track_v_position[a+1]-track_v_position[a])) channel_y_width = channel_y_width/2
					
						if waveform_color_enabled == false 
					then
						gfx.set(1,1,1,0.95) 
					else
						local r3, g3, b3 = reaper.ColorFromNative( track_color[a] )  
						gfx.set(r3/255,g3/255,b3/255,0.95) 
					end
					-- draw peaks
					for i = 1, #peaks[a][b], 2 do --for i = 1, ((items_length[a][b]/project_length*gfx.w)*2)-1, 2 do
							if peaks[a]
						then 
							if peaks[a][b]
						then
							local max_peak, min_peak = peaks[a][b][i], peaks[a][b][i+1] 
							if max_peak == nil then update_project() return end 
							if math.floor(gfx.w/(project_length/items_position[a][b])+gfx.w/#peaks[a][b]/(project_length/items_length[a][b])*i ) < (gfx.w/(project_length/items_position[a][b]))+(gfx.w/(project_length/items_length[a][b]))-2 then 
							gfx.line( math.floor(gfx.w/(project_length/items_position[a][b])+gfx.w/#peaks[a][b]/(project_length/items_length[a][b])*i ), channel_y+channel_y_width+(channel_y_width*max_peak), 
												math.floor(gfx.w/(project_length/items_position[a][b])+gfx.w/#peaks[a][b]/(project_length/items_length[a][b])*i ), channel_y+channel_y_width-(channel_y_width*max_peak), 1) end
						else end
						else end
					end
				end
			end
		end
	end

	-- project markers
		if Show_Project_Markers == true
	then local projectMarker_alpha = .9 
		local ret_markers, num_markers, num_regions = reaper.CountProjectMarkers( 0 ) gfx.set(1,1,0,projectMarker_alpha) gfx.y = 2 
			for i = 1, num_markers+num_regions
		do 
			local retvaller, isrgn, posser, rgnend, namer, markrgnindexnumber, marker_color = reaper.EnumProjectMarkers3( 0, i-1 ) namer = markrgnindexnumber.."."..namer
			if marker_color == 0 then if isrgn == false then gfx.set(1,.49,.31,projectMarker_alpha) else gfx.set(0,.51,.69) end else COLORtoGFX( marker_color, projectMarker_alpha ) end 
				if i < num_markers+num_regions
			then
				local retvaller2, _, posser2, _, _, _, _ = reaper.EnumProjectMarkers3( 0, i ) 
				while gfx.measurestr( namer )+DATAtoX_Y( posser )+2 > DATAtoX_Y( posser2 ) do namer = string.sub(namer, 0, string.len(namer)-1) if string.len(namer) == 0 then break end end 
			end
			gfx.x = DATAtoX_Y( posser ) gfx.line(DATAtoX_Y( posser ),0,DATAtoX_Y( posser ),gfx.h )
			gfx.x = DATAtoX_Y( posser )+2 gfx.drawstr( namer ) 
		end 
	end 
	-- track names
		if Show_Track_Names == true
	then
			gfx.set( 1,1,1,.95 ) for a = 1, #track
		do 
				if 20+(gfx.h/(track_v_position[0]/track_v_position[a]))<(gfx.h/(track_v_position[0]/track_v_position[a+1])) 
			then if a == 1 then show_PM_titles = true end
				gfx.x = 2 gfx.y = 10+gfx.h/(track_v_position[0]/track_v_position[a]) gfx.drawstr( track_name[a] ) 
			else
				if 10+(gfx.h/(track_v_position[0]/track_v_position[a]))<(gfx.h/(track_v_position[0]/track_v_position[a+1])) then gfx.x = 2 gfx.y = gfx.h/(track_v_position[0]/track_v_position[a]) gfx.drawstr( track_name[a] ) end
			end
		end
	end

	-- edit cursor/play cursor
	gfx.set(1,1,1,0.8) gfx.rect(math.floor( (gfx.w/(project_length/ reaper.GetPlayPosition()))+.5)-math.floor((Play_Cursor_Width/2)), 0,Play_Cursor_Width,gfx.h,1 ) 
	gfx.set(1,0,0,0.8) gfx.rect(math.floor( (gfx.w/(project_length/reaper.GetCursorPosition()))+.5)-math.floor((Edit_Cursor_Width/2)),0,Edit_Cursor_Width,gfx.h,1 )
	--screen bounding box
	gfx.set(0,1,0,0.8) 
	if pinPointY == -1
	then
		for a = 1, Marquee_Box_Thickness do gfx.rect(b_x-(a-1),b_y-(a-1),b_w+((a-1)*2),b_h+((a-1)*2),0 ) end 
	else
		-- green box
		local yy1, yy2 = pinPointY, gfx.mouse_y if pinPointY > gfx.mouse_y then yy2, yy1 = pinPointY, gfx.mouse_y end 
		local xx1, xx2 = pinPointX, gfx.mouse_x if pinPointX > gfx.mouse_x then xx2, xx1 = pinPointX, gfx.mouse_x end 
		for a = 1, Marquee_Box_Thickness do gfx.rect(xx1-(a-1),yy1-(a-1),xx2-xx1+((a-1)*2),yy2-yy1+((a-1)*2),0 ) end
		-- yellow box
		gfx.set(1,1,0,0.8) 
		for a = 1, Marquee_Box_Thickness do gfx.rect(xx1-(a-1),yy1+((yy2-yy1)/2)-(b_h/2)-(a-1),xx2-xx1+((a-1)*2),b_h+((a-1)*2),0 ) end 
	end
	-- display project looper
		if Show_Project_Looper == true 
	then local looper_alpha = .2 if loop_state == 0 then looper_alpha = .1 end
		gfx.set(1,1,1,looper_alpha) gfx.rect(gfx.w/(project_length/loop_start),0,gfx.w/(project_length/(loop_end-loop_start)),gfx.h, 1)
	end

end

function get_peaks( go_to_main ) 

		if items[track_buf]
	then 
		if items[track_buf][item_buf]
	then
		local take = reaper.GetActiveTake( items[track_buf][item_buf] )
			if not take                    -- If NOTHING
		then
		elseif reaper.TakeIsMIDI(take)   -- if MIDI
		then 
			local midi_retval, notecnt, _, _ = reaper.MIDI_CountEvts( take )
				for a = 1, notecnt 
			do
				local midier_retval, _, _, startppqpos, endppqpos, _, pitch, _ = reaper.MIDI_GetNote( take, a-1 )
				midi_start[track_buf][item_buf][a] = reaper.MIDI_GetProjTimeFromPPQPos( take, startppqpos )
				midi_end[track_buf][item_buf][a]   = reaper.MIDI_GetProjTimeFromPPQPos( take, endppqpos )
				midi_pitch[track_buf][item_buf][a] = pitch
			end 
		else                             -- if AUDIO
			------------------
			local n_chans = 1
			local sub_for_it = display_width if gfx.w > sub_for_it then sub_for_it = gfx.w end 
			--local peakrate = (items_length[track_buf][item_buf]/project_length * sub_for_it)/items_length[track_buf][item_buf]
			local peakrate = Waveform_Definition
			local n_spls = math.floor(items_length[track_buf][item_buf]*peakrate + 0.5) if n_spls < 1 then n_spls = 1 end     
			local want_extra_type = 115  -- 's' char 
			local buf = reaper.new_array(n_spls * n_chans * 3)
			buf.clear()
			------------------
			local retval = reaper.GetMediaItemTake_Peaks(take, peakrate, items_position[track_buf][item_buf], n_chans, n_spls, want_extra_type, buf)
			local spl_cnt  = (retval & 0xfffff)        -- sample_count
			local ext_type = (retval & 0x1000000)>>24  -- extra_type was available
			local out_mode = (retval & 0xf00000)>>20   -- output_mode
			------------------
			if spl_cnt > 0 then
				for i = 1, n_spls do
					local p = #peaks[track_buf][item_buf]
					peaks[track_buf][item_buf][p+1] = buf[i]             -- max peak
					peaks[track_buf][item_buf][p+2] = buf[n_spls + i]    -- min peak
				end
			end
		end
		item_buf = item_buf + 1 
	else track_buf = track_buf + 1 item_buf = 1 end
	else track_buf = 0 item_buf = 0 draw_items() end
	if go_to_main == true then main() end 
end

function update_project( go_to_main ) 
	local r = 0 for a = 1, reaper.CountMediaItems( 0 ) do local s = reaper.GetMediaItemInfo_Value( reaper.GetMediaItem( 0, a-1 ), "D_POSITION" )+reaper.GetMediaItemInfo_Value( reaper.GetMediaItem( 0, a-1 ), "D_LENGTH" ) if s > r then r = s end end
	project_length = r
	items = {} items_position = {} items_length = {} track = {} track_name = {} track_color = {} track_buf = 1 item_buf = 1 peaks = {} midi_start = {} midi_end = {} midi_pitch = {} 
		for a = 1,  reaper.CountTracks( 0 )
	do items[a] = {} items_position[a] = {} items_length[a] = {} peaks[a] = {} midi_start[a] = {} midi_end[a] = {} midi_pitch[a] = {} 
		track[a]                     = reaper.GetTrack( 0, a-1 )
		local retval_name, tname_buf = reaper.GetTrackName( track[a] )
		track_name[a]                = tname_buf
		track_color[a]               = reaper.GetTrackColor( track[a] )
			for b = 1, reaper.CountTrackMediaItems( reaper.GetTrack( 0, a-1 ) )
		do peaks[a][b] = {} midi_start[a][b] = {} midi_end[a][b] = {} midi_pitch[a][b] = {} 
			items[a][b]          = reaper.GetTrackMediaItem( track[a], b-1 ) 
			items_position[a][b] = reaper.GetMediaItemInfo_Value( items[a][b], "D_POSITION" ) 
			items_length[a][b]   = reaper.GetMediaItemInfo_Value( items[a][b], "D_LENGTH" ) 
		end
	end 
	get_peaks( go_to_main )
end

--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~
function main() local draw_it = false

	-- project change/update
	local update_pro = false
	local proj_name_buf = reaper.GetProjectName( 0, "" )..script_name if proj_name_buf ~= project_name then project_name = proj_name_buf reaper.JS_Window_SetTitle( window_script, project_name ) update_pro = true end
		if #track == reaper.CountTracks( 0 )
	then
			for a = 1,  reaper.CountTracks( 0 )
		do
			if track_color[a] ~= reaper.GetTrackColor( reaper.GetTrack( 0, a-1 ) ) then track_color[a] = reaper.GetTrackColor( reaper.GetTrack( 0, a-1 ) ) draw_it = true end 
			if track[a] ~= reaper.GetTrack( 0, a-1 ) then update_pro = true end
		end
	else
		update_pro = true
	end
	-- if 'r' 
	if gfx.getchar(114) > 0 and gfx_char[10] < reaper.time_precise() then gfx_char[10] = reaper.time_precise()+1 update_pro = true end 
	if update_pro == true then update_project() end
	------------------------
	
	
	-- if script is in process of loading
		if track_buf > 0
	then 
			for a = 1, Script_Load_Speed
		do
			get_peaks()
		end
	-- if script is not loading
	else
			if reaper.JS_Window_FromPoint( reaper.GetMousePosition() ) == window_script  
		then if lClick ~= 1 then reaper.JS_Window_SetFocus( window_script ) end 
			local c_def = true
			
			-- keyboard input/controls
			-- right: move edit cursor to next marker right
				if gfx.getchar(1919379572 ) > 0 and gfx_char[1] < reaper.time_precise() and Show_Project_Markers == true 
			then gfx_char[1] = reaper.time_precise()+gfx_char[0]
				local ret_markers, num_markers, num_regions = reaper.CountProjectMarkers( 0 ) 
					for i = 1, num_markers+num_regions
				do 
					local retvaller, _, posser, _, _, _, _ = reaper.EnumProjectMarkers3( 0, i-1 ) 
					if posser > reaper.GetCursorPosition() then reaper.SetEditCurPos2( 0, posser, 0, 0 ) break end
				end 
			end 
			-- left: move edit cursor to next marker left
				if gfx.getchar(1818584692) > 0 and gfx_char[2] < reaper.time_precise() and Show_Project_Markers == true
			then gfx_char[2] = reaper.time_precise()+gfx_char[0]
				local ret_markers, num_markers, num_regions = reaper.CountProjectMarkers( 0 ) 
					local i = num_markers+num_regions
				repeat 
					local retvaller, _, posser, _, _, _, _ = reaper.EnumProjectMarkers3( 0, i-1 ) 
					if posser < reaper.GetCursorPosition() then reaper.SetEditCurPos2( 0, posser, 0, 0 ) break end i = i - 1
				until i == 0 
			end 
			-- up: place project loop, alternating placement ends
				if gfx.getchar(30064) > 0 and gfx_char[3] < reaper.time_precise() and Show_Project_Markers == true 
			then gfx_char[3] = reaper.time_precise()+.3 
				if gfx_char[4] == 0 then reaper.GetSet_LoopTimeRange2( 0, 1, 1, reaper.GetCursorPosition(), loop_end, 0 ) gfx_char[4] = reaper.GetCursorPosition() else reaper.GetSet_LoopTimeRange2( 0, 1, 1, gfx_char[4], reaper.GetCursorPosition(), 0 ) gfx_char[4] = 0 end
			end
			
			-- down: 'hard' play from edit cursor, doesn't cycle between play/stop
				if gfx.getchar(1685026670) > 0 and gfx_char[5] < reaper.time_precise() 
			then gfx_char[5] = reaper.time_precise()+.2 
				reaper.OnPlayButton()
			end
			
			-- spacebar: playback toggle
			if gfx.getchar() == 32 then if reaper.GetPlayState() == 1 then reaper.OnStopButton() else reaper.OnPlayButton() end end
			
			-- '/': toggle project looper
			if gfx.getchar(47) > 0 and gfx_char[6] < reaper.time_precise() then gfx_char[6] = reaper.time_precise()+.3 reaper.GetSetRepeatEx( 0, 2 ) reaper.JS_Window_SetFocus( reaper.GetMainHwnd() ) end
			
			-- 'm': toggle project mixer window
			if gfx.getchar(109) > 0 and gfx_char[7] < reaper.time_precise() then gfx_char[7] = reaper.time_precise()+.3 reaper.Main_OnCommand( 40078, 0 ) end
			
			
			-- mouse input/controls
			
			-- position window
				if rClick == 0 and lClick == 0 and gfx.mouse_x > 0 and gfx.mouse_x < gfx.w and gfx.mouse_y > 0 and gfx.mouse_y < gfx.y and gfx.mouse_cap == 9 or lClick == 2
			then lClick = 2
				local _, left, top, right, bottom = reaper.JS_Window_GetRect( window_script )
				local mx, my = reaper.GetMousePosition()
				reaper.JS_Window_SetPosition( window_script, math.floor( mx-((right-left)/2) ), math.floor( my-((bottom-top)/2) ), math.floor( right-left ), math.floor( bottom-top ) )
			end
			
			-- marquee
			-- click
				if rClick == 0 and gfx.mouse_cap == 2 or rClick == 1
			then
				-- initial click
				if rClick == 0 then pinPointX, pinPointY = gfx.mouse_x, gfx.mouse_y end 
				-- hold click
				rClick = 1 gfx.setcursor( 32515 --[[4-point]]) reaper.JS_Mouse_SetCursor( reaper.JS_Mouse_LoadCursor( 32515 ) ) c_def = false draw_it = true
			end
			-- release
				if gfx.mouse_cap == 0 and rClick == 1 
			then  
				-- set horizontal
				local xx1, xx2 = pinPointX, gfx.mouse_x if pinPointX > gfx.mouse_x then xx2, xx1 = pinPointX, gfx.mouse_x end 
				reaper.GetSet_ArrangeView2( 0, 1, 0, 0, X_YtoDATA( xx1 ), X_YtoDATA( xx2 ) )
				-- set vertical limited in function due to API
				local yy1, yy2 = pinPointY, gfx.mouse_y if pinPointY > gfx.mouse_y then yy2, yy1 = pinPointY, gfx.mouse_y end 
				local rater = arrange_height/track_v_position[0]
					if rater ~= 1
				then
					local h_sub = gfx.h-(gfx.h*rater) local m_sub = yy2-((yy2-yy1)/2)-(gfx.h*(rater/2)) 
					reaper.JS_Window_SetScrollPos( window_arrange, "v", math.floor(m_sub*((track_v_position[0]-arrange_height)/h_sub)) ) --Up()
				end
				rClick = 0 pinPointX, pinPointY = -1, -1 gfx.setcursor( 0 ) 
			end
			
			-- center screen
			-- hover
			if rClick == 0 and gfx.mouse_x > b_x+mouseGrab  and gfx.mouse_x < b_xx-mouseGrab and gfx.mouse_y > b_y+mouseGrab and gfx.mouse_y < b_yy-mouseGrab and gfx.mouse_x < gfx.w-2 and gfx.mouse_y < gfx.h-2 and gfx.mouse_y > 2 and gfx.mouse_x > 2 then gfx.setcursor( 32646 --[[4-point]]) reaper.JS_Mouse_SetCursor( reaper.JS_Mouse_LoadCursor( 32646 ) ) c_def = false end -- 4-points
			-- click
				if lClick == 0 and gfx.mouse_cap == 1 and rClick == 0 or lClick == 1
			then lClick = 1 
				local mouse_sub = gfx.mouse_x if mouse_sub > gfx.w then mouse_sub = gfx.w end local arrange_mid = arrange_end-arrange_start local starter = mouse_sub*(project_length/gfx.w)
				reaper.GetSet_ArrangeView2( 0, 1, 0, 0, starter-(arrange_mid/2), starter+(arrange_mid/2) )
				local ratio = arrange_height/window_max 
					if ratio ~= 1
				then
					local h_sub = gfx.h-(gfx.h*ratio) local m_sub = gfx.mouse_y-(gfx.h*(ratio/2)) 
					reaper.JS_Window_SetScrollPos( window_arrange, "v", math.floor(m_sub*((window_max-arrange_height)/h_sub)) ) --Up()
				end
			end
			-- release
			if gfx.mouse_cap ~= 1 then lClick = 0 end
			
			-- ctrl+click: solo track in mixer
				if gfx.mouse_cap == 5 and gfx_char[9] < reaper.time_precise()
			then gfx_char[9] = reaper.time_precise() + .3
					for a = 1, #track 
				do  reaper.SetMediaTrackInfo_Value( track[a], "B_SHOWINMIXER", gfx_char[8] ) 
						if gfx.mouse_y > gfx.h/(track_v_position[0]/track_v_position[a]) and gfx.mouse_y < gfx.h/(track_v_position[0]/track_v_position[a+1]) 
					then
						reaper.SetMediaTrackInfo_Value( track[a], "B_SHOWINMIXER", 1 ) 
					end
				end if gfx_char[8] == 0 then gfx_char[8] = 1 else gfx_char[8] = 0 end reaper.TrackList_AdjustWindows( false ) 
			end
			
			-- mousewheel vertical zoom
				if gfx.mouse_wheel ~= 0 
			then local xdire, ydire = 0, 0 
				if gfx.mouse_cap == Vertical_MouseWheel_Modifier   then ydire = Vertical_MouseWheel_Sensitivity end if gfx.mouse_cap == Horizontal_MouseWheel_Modifier then xdire = Horizontal_MouseWheel_Sensitivity end
				if gfx.mouse_cap == Vertical_MouseWheel_Modifier+2 then ydire = Vertical_MouseWheel_Sensitivity end 
				if Vertical_MouseWheel_Modifier ~= 0 and Horizontal_MouseWheel_Modifier ~= 0 and gfx.mouse_cap == Vertical_MouseWheel_Modifier+Horizontal_MouseWheel_Modifier then xdire = Horizontal_MouseWheel_Sensitivity ydire = Vertical_MouseWheel_Sensitivity end
				if Invert_Vertical_MouseWheel_Zoom == true then ydire = ydire*-1 end if Invert_Horizontal_MouseWheel_Zoom == true then xdire = xdire*-1 end 
				local rpr_ini = io.open(reaper.get_ini_file()) local rpr_ini_string = rpr_ini:read("*a") rpr_ini:close() local _, ini_end = string.find(rpr_ini_string, "zoommode=") local _, ini_end2 = string.find(rpr_ini_string, "vzoommode=") local horizontal_zoomMode = string.sub(rpr_ini_string, ini_end+1, ini_end+1)local vertical_zoomMode = string.sub(rpr_ini_string, ini_end2+1, ini_end2+1) rpr_ini_string = nil
				reaper.Main_OnCommand( reaper.NamedCommandLookup("_WOL_SETHZOOMC_CENTERVIEW"), 0 ) reaper.Main_OnCommand( reaper.NamedCommandLookup("_WOL_SETVZOOMC_TRACKCVIEW"), 0 ) 
					if gfx.mouse_wheel > 0
				then --reaper.Main_OnCommand( 40111, 0)
					reaper.CSurf_OnZoom( xdire, ydire ) 
				end
					if gfx.mouse_wheel < 0
				then --reaper.Main_OnCommand( 40112, 0)
					reaper.CSurf_OnZoom( 0-xdire, 0-ydire ) 
				end 
				if horizontal_zoomMode == 0 then reaper.Main_OnCommand( reaper.NamedCommandLookup("_WOL_SETHZOOMC_EDITPLAYCUR"), 0 ) elseif horizontal_zoomMode == 1 then reaper.Main_OnCommand( reaper.NamedCommandLookup("_WOL_SETHZOOMC_EDITCUR"), 0 ) elseif horizontal_zoomMode == 2 then reaper.Main_OnCommand( reaper.NamedCommandLookup("_WOL_SETHZOOMC_CENTERVIEW"), 0 ) else reaper.Main_OnCommand( reaper.NamedCommandLookup("_WOL_SETHZOOMC_MOUSECUR"), 0 ) end
				if vertical_zoomMode == 0 then reaper.Main_OnCommand( reaper.NamedCommandLookup("_WOL_SETVZOOMC_TRACKCVIEW"), 0 ) elseif vertical_zoomMode == 1 then reaper.Main_OnCommand( reaper.NamedCommandLookup("_WOL_SETVZOOMC_TOPVISTRACK"), 0 ) elseif vertical_zoomMode == 2 then reaper.Main_OnCommand( reaper.NamedCommandLookup("_WOL_SETVZOOMC_LASTSELTRACK"), 0 ) else reaper.Main_OnCommand( reaper.NamedCommandLookup("_WOL_SETVZOOMC_TRACKMOUSECUR"), 0 ) end
				gfx.mouse_wheel = 0
			end
			
			-- place edit cursor
				if gfx.mouse_cap == 64 
			then
				reaper.SetEditCurPos2( 0, project_length/(gfx.w/gfx.mouse_x), 0, 0 ) 
				local ret_markers, num_markers, num_regions = reaper.CountProjectMarkers( 0 ) local no_overlap = {} gfx.set(1,1,0,projectMarker_alpha) gfx.y = 2 
					for i = 1, num_markers+num_regions
				do 
					local retvaller, isrgn, posser, rgnend, namer, markrgnindexnumber, marker_color = reaper.EnumProjectMarkers3( 0, i-1 ) 
						if gfx.mouse_x > DATAtoX_Y( posser )-Edit_Cursor_MarkerSnap and gfx.mouse_x < DATAtoX_Y( posser )+Edit_Cursor_MarkerSnap
					then
						reaper.SetEditCurPos2( 0, posser, 0, 0 ) 
					end
					
				end 
			end
			
			-- return mouse graphic
			if gfx.mouse_cap ~= 1 then lClick = 0 end if c_def == true then gfx.setcursor( 0 ) end 	
	
		end

			if reaper.JS_Window_IsVisible( window_script ) == true
		then
			-- script gfx change/update
			local window_retval2, window_position2, _, window_min2, window_max2, _ = reaper.JS_Window_GetScrollInfo( window_arrange, "v" )
			local loop_start2, loop_end2 = reaper.GetSet_LoopTimeRange2( 0, 0, 1, 0, 0, 0 )
			local arrange_start2, arrange_end2 = reaper.GetSet_ArrangeView2( 0, 0, 0, 0 ) 
				if reaper.GetPlayState() == 1 or arrange_start2 ~= arrange_start or arrange_end2 ~= arrange_end or window_position2 ~= window_position or window_min2 ~= window_min or window_max2 ~= window_max or window_width ~= gfx.w or window_height ~= gfx.h or edit_cursor ~= reaper.GetCursorPosition() or loop_start ~= loop_start2 or loop_end ~= loop_end2 or reaper.GetSetRepeatEx( 0, -1 ) ~= loop_state or draw_it == true
			then
				draw_items() 
			end 
		end
		
	end
	------------------------

	draw_load_screen() 
	if gfx.getchar() ~= -1 and gfx.getchar(27) ~= 1 then reaper.defer(main) end

end
--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~

function delete_ext_states()
	reaper.DeleteExtState( "Dfk Project Map", "W_D", 1 ) 
	reaper.DeleteExtState( "Dfk Project Map", "W_W", 1 ) 
	reaper.DeleteExtState( "Dfk Project Map", "W_H", 1 ) 
	reaper.DeleteExtState( "Dfk Project Map", "W_X", 1 ) 
	reaper.DeleteExtState( "Dfk Project Map", "W_Y", 1 )
	reaper.DeleteExtState( "Dfk Project Map", "W_B", 1 )
end

function exit()
  local wd, wx, wy, ww, wh = gfx.dock( -1, 0, 0, 0, 0 ) 
  reaper.SetExtState( "Dfk Project Map", "W_D",  wd, true )
	reaper.SetExtState( "Dfk Project Map", "W_X",  wx, true )
	reaper.SetExtState( "Dfk Project Map", "W_Y",  wy, true )
	reaper.SetExtState( "Dfk Project Map", "W_W",  ww, true )
	reaper.SetExtState( "Dfk Project Map", "W_H",  wh, true )
end

--delete_ext_states()
reaper.atexit(exit)
init()

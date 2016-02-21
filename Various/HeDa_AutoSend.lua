--[[
   * ReaScript Name: AutoSend MIDI of selected track to a specific track
   * Lua script for Cockos REAPER
   * Author: Hector Corcin (HeDa)
   * Author URI: http://forum.cockos.com/member.php?u=47822
   * Licence: GPL v3
   * Version: 0.2
]]

--[[
Changelog:

v0.2 (2016-02-21)
  + Auto creates the Receiving Track if it doesn't exist avoiding crash. [mccrabney p=1641272&postcount=23]
  + Delay to trigger the send change [mccrabney p=1639100&postcount=15]
  + Remove send if no track is selected (it could be just as an option if wanted)
  # fixes and internal improvements
  
v0.1 (2016-02-18)
  + Initial beta version

]]--


-- OPTIONS -------------------------------------------------------------

-- change the name of the track to receive the MIDI send:
	ho_track_name = "Hardware send"

-- Delay in seconds to trigger the send change.
	seconds_delay = 0.8

-- End of options. Do not modify bellow here unless needed.
------------------------------------------------------------------------	
	

	
	
	
	



last_proj_change_count = reaper.GetProjectStateChangeCount(0)
minimized=1

function FindTrackWithName(trackname)
	local tr
	for i=0, reaper.CountTracks(0)-1 do
		tr=reaper.GetTrack(0,i)
		local retval, TrackName1 = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)	
		if TrackName1 == trackname then 
			return tr, i
		end
	end
end
function FindSendWithName(track, name)
	local numsends=reaper.GetTrackNumSends(track, 0)
	local id
	for f=0, numsends-1 do
		local retval, sendname = reaper.GetTrackSendName(track, f, "")
		if sendname==name then id=f; break; end
	end
	return id
end
function CreateSend(track)
	reaper.CreateTrackSend(track, ho_track)
	local sendidnew=FindSendWithName(track, ho_track_name)
	if sendidnew then 
		reaper.SetTrackSendInfo_Value(track, 0, sendidnew, "I_SRCCHAN", -1)
		reaper.SetTrackSendInfo_Value(track, 0, sendidnew, "I_MIDIFLAGS", 0)
	end
end
function RemoveSend(track)
	local valid_track=reaper.ValidatePtr(track, "MediaTrack*")
	if valid_track then
		local removesendid=FindSendWithName(track, ho_track_name)
		if removesendid then
			reaper.RemoveTrackSend(track, 0, removesendid) 
		end
	end
end
function RemoveOtherSends(track)
	for i=0, reaper.CountTracks(0)-1 do
		local t=reaper.GetTrack(0,i)
		if t ~= track then
			RemoveSend(t)
		end
	end
end

function init()
	is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
	reaper.SetToggleCommandState(sectionID, cmdID, 1)
	reaper.RefreshToolbar2(sectionID, cmdID)
	
	ho_track, ho_track_id = FindTrackWithName(ho_track_name)
	timer=reaper.time_precise()
	if not ho_track then 
		reaper.PreventUIRefresh(1)
		reaper.Undo_BeginBlock2(0)
		local lasttrackid=reaper.CountTracks(0)-1
		local lasttrack=reaper.GetTrack(0,lasttrackid)
		local depthlast = reaper.GetTrackDepth(lasttrack)
		reaper.SetMediaTrackInfo_Value(lasttrack,"I_FOLDERDEPTH",0-depthlast)
		
		reaper.Main_OnCommand("40702",0) -- insert at end of track list
		local ho_track = reaper.GetSelectedTrack(0,0)
		reaper.SetMediaTrackInfo_Value(ho_track,"I_FOLDERDEPTH",0)
		retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String(ho_track, "P_NAME", ho_track_name, true)
		reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_DISMPSEND"),0) -- disable master parent send

		reaper.Undo_EndBlock2(0, "Create Hardware Send track", -1)
		reaper.PreventUIRefresh(-1)

		reaper.ShowMessageBox("Track created at the end of the track list:  " .. ho_track_name .. "\n\nYou can adjust its hardware output and move it or hide it", "Information", 0)
	end
	ho_track, ho_track_id = FindTrackWithName(ho_track_name)
	if ho_track then 
		local selectedtrack=reaper.GetSelectedTrack(0,0)
		if selectedtrack then 
			sendid=FindSendWithName(selectedtrack, ho_track_name)
			if not sendid then
				CreateSend(selectedtrack)
			end
		end
	end	
end

function on_change(action)
	if action == "Change Track Selection" or 
	   action == "Unselect All Tracks" or
	   action == "Remove Tracks" or
	   action == "Remove Track Selection"
	   
		then 
		local selectedtrack=reaper.GetSelectedTrack(0,0)
		if selectedtrack then 
				valid_ho_track=reaper.ValidatePtr(ho_track, "MediaTrack*")
				if not valid_ho_track then
					reaper.ShowMessageBox("Track with hardware output not found. Stopping AutoSend script.", "Error", 0)
					return(-1)
				end
				sendid=FindSendWithName(selectedtrack, ho_track_name)
				if not sendid then
						CreateSend(selectedtrack)
						RemoveOtherSends(selectedtrack)
				end
		else
			RemoveOtherSends("all")
		end
	end
end

function loop()
	if reaper.time_precise() - timer > seconds_delay then 
		local proj_change_count = reaper.GetProjectStateChangeCount(0)
		if proj_change_count > last_proj_change_count then
			local last_action = reaper.Undo_CanUndo2(0) -- get last action
			if last_action ~= nil then
				action = on_change(last_action) -- call main function
			end
			last_proj_change_count = proj_change_count -- store "Project State Change Count" for the next pass
		end	
		timer=reaper.time_precise()
	end
	char = gfx.getchar()
	if char == -1 then
		if minimized==0 or action==-1 then 
			exitnow()
		else
			reaper.runloop(loop)
		end
	end
end

function exitnow()
	is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
	reaper.SetToggleCommandState(sectionID, cmdID, 0)
	reaper.RefreshToolbar2(sectionID, cmdID)
	RemoveOtherSends("all")
end

reaper.atexit(exitnow)   
init()
loop()

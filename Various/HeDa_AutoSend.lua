--[[
   * ReaScript Name: AutoSend MIDI of selected track to a specific track
   * Lua script for Cockos REAPER
   * Author: Hector Corcin (HeDa)
   * Author URI: http://forum.cockos.com/member.php?u=47822
   * Licence: GPL v3
   * Version: 0.1
]]


-- change the name of the track to receive the MIDI send:
ho_track_name = "Hardware send"



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
function CreateSend()
	reaper.CreateTrackSend(selectedtrack, ho_track)
	local sendidnew=FindSendWithName(selectedtrack, ho_track_name)
	if sendidnew then 
		reaper.SetTrackSendInfo_Value(selectedtrack, 0, sendidnew, "I_SRCCHAN", -1)
		reaper.SetTrackSendInfo_Value(selectedtrack, 0, sendidnew, "I_MIDIFLAGS", 0)
	end
end
function RemoveSend()
	local removesendid=FindSendWithName(prevselectedtrack, ho_track_name)
	if removesendid then 
		reaper.RemoveTrackSend(prevselectedtrack, 0, removesendid) 
	end
end		
function on_change(action)
	if action == "Change Track Selection" then 
		selectedtrack=reaper.GetSelectedTrack(0,0)
		if selectedtrack and selectedtrack ~= prevselectedtrack then
			valid_ho_track=reaper.ValidatePtr(ho_track, "MediaTrack*")
			if not valid_ho_track then
				reaper.ShowConsoleMsg("Track with hardware output not found. Exiting.", "Error", 0)
				return
			end
			
			sendid=FindSendWithName(selectedtrack, ho_track_name)
			if not sendid then

					-- add send
					CreateSend()
					--remove previous send
					valid_prevselectedtrack=reaper.ValidatePtr(prevselectedtrack, "MediaTrack*")
					if not valid_prevselectedtrack then
						return
					elseif prevselectedtrack then
						RemoveSend()
					end
			end
			prevselectedtrack=selectedtrack
		end
	end
end

function init()
	is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
	reaper.SetToggleCommandState(sectionID, cmdID, 1)
	reaper.RefreshToolbar2(sectionID, cmdID)
	
	prevselectedtrack=reaper.GetSelectedTrack(0,0)
	selectedtrack=reaper.GetSelectedTrack(0,0)
	ho_track, ho_track_id = FindTrackWithName(ho_track_name)
	if ho_track then ho_track_guid = reaper.GetTrackGUID(ho_track) end

	sendid=FindSendWithName(selectedtrack, ho_track_name)
	if not sendid then
		CreateSend()
	end
end

function loop()
	local proj_change_count = reaper.GetProjectStateChangeCount(0)
	if proj_change_count > last_proj_change_count then
		local last_action = reaper.Undo_CanUndo2(0) -- get last action
		if last_action ~= nil then
			on_change(last_action) -- call main function
		end
		last_proj_change_count = proj_change_count -- store "Project State Change Count" for the next pass
	end	
	char = gfx.getchar()
	if char == -1 then
		if minimized==0 then 
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
	if prevselectedtrack then
		RemoveSend()
	end
end

reaper.atexit(exitnow)   
init()
loop()

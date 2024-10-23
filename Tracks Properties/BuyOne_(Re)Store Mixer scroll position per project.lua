--[[
ReaScript name: (Re)Store Mixer scroll position per project
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS, not mandatory but recommended
About: 	The script allows storing and recalling last project specific 
	Mixer scroll position on project load and when switching between
	project tabs. It can work in manual and in auto modes.

        ▓ M A N U A L  M O D E

        To take advantage of the script functionality 
        you'll need to set up a number of custom actions 
        featuring the script and optionally use SWS extension 
        'Project startup action' utility.

        ► RECALLING

        In order to be able to recall the Mixer scroll position
        on project load do one of the following or both. 
        Create a custom action (note that the two script instances):  

          Custom: Open project and restore Mixer scroll position  
          Script: BuyOne_(Re)Store Mixer scroll position per project.lua <--- (this script) 
          File: Open project  
          Script: BuyOne_(Re)Store Mixer scroll position per project.lua <--- (this script)  

        Use it to load project via Open project dialogue. Set up 'Project startup action':  
        1) Copy this script command ID by right-clicking on its entry in the Action list  
        and selecting 'Copy selected action command ID'.  
        2) From the main REAPER menu select Extensions -> Startup actions -> Set project startup action  
        3) Paste the copied script command ID into the 'Set project startup action' field  
        4) Click OK and save the project so the setting is stored in it.  
        Now the project can be loaded from the 'Recent projects' menu 
        and have Mixer scroll position recalled. SWS Project startup action 
        must be set for each project you wish to be affected by this script on load.

        To be able to recall Mixer scroll position when switching between project tabs
        set up the following custom actions:  

          Custom: Open next proj tab and restore Mixer scroll position  
          Next project tab  
          Script: BuyOne_(Re)Store Mixer scroll position per project.lua <--- (this script)  

          Custom: Open previous proj tab and restore Mixer scroll position  
          Previous project tab  
          Script: BuyOne_(Re)Store Mixer scroll position per project.lua <--- (this script)  

        Use them instead of the stock action to switch project tabs.  
        If you prefer switching tabs manually then after each such switch the script will
        have to be run manually.

        ► STORING

        Once the Mixer scroll position is recalled within a project the script switches 
        to the storage mode. Its consequtive runs will store current Mixer scroll position 
        whatever it is at any given moment. But to be able to store it in the project file 
        the project file must be explicitly saved, for this purpose set up the following 
        custom action:  

          Custom: Save project with Mixer scroll position  
          Script: BuyOne_(Re)Store Mixer scroll position per project.lua <--- (this script)  
          File: Save project  

        and use it instead of the stock Save action.

        So basically once the scroll position has been recalled within a project 
        it can only be recalled again if you don't save the project and switch 
        to another project tab to switch back to the current one using a custom 
        action described above or running the script directly. Once the project 
        has been saved with that custom action a new scroll position has been 
        stored unless it remained the same after recalling.

        After running the above custom action to store a new scroll position you 
        may notice asterisk added to the project name in the project tab as is 
        usually the case when the project has been altered and there's data waiting 
        to be saved. But this doesn't mean the scroll position failed to get stored. 
        Admittedly confusing but couldn't figure out why this happens.

        ▓ A U T O  M O D E 

        In auto mode the script runs in the background and stores and recalls 
        the Mixer scroll position automatically.  
        What you will still need to do is periodically save the project so that 
        the latest scroll position data is saved to the project file and is available 
        on the next project load. But for recalling the scroll position while jumping
        between project tabs saving isn't necessary.  
        This mode must be enabled in the USER SETTINGS.  
        To launch the script automatically on REAPER startup add its command ID to the 
        SWS extension 'Startup actions' as a 'Global startup action'.  
	If the script is linked to a toolbar button in auto mode the button will be lit.

]]
------------------------------------------------------------------
-------------------------- USER SETTINGS -------------------------
------------------------------------------------------------------

-- To enable the settings place any QWERTY character
-- between the quotation marks.

-- Enable this setting so the script can be used
ENABLE_SCRIPT = ""


AUTO_MODE = ""

-------------------------------------------------------------------
----------------------- END OF USER SETTINGS ----------------------
-------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper


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


function Count_Proj_Tabs()
local i = 0
	repeat
	local retval, projfn = r.EnumProjects(i)
	i = retval and i+1 or i
	until not retval
return i
end

function Manage_Scroll_Manual(load, tab_cnt, proj) -- load is boolean
	for i = 0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	local stored, extended_data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:MIXER SCROLL', '', false) -- setNewValue false
		if load and stored then
		r.SetMixerScroll(tr) -- load
		r.SetExtState('MIXER_SCROLL', 'loaded', proj..':'..tab_cnt, false) -- persist false
		return end
		if not load and stored then -- store
		r.GetSetMediaTrackInfo_String(tr, 'P_EXT:MIXER SCROLL', '', true) -- setNewValue true // DELETE CURRENT EXT DATA BECAUSE ANOTHER TRACK IS LIKELY TO MOVE TO THE LEFTMOST POSITION AND BE STORED
		local tr = r.GetMixerScroll()
		r.GetSetMediaTrackInfo_String(tr, 'P_EXT:MIXER SCROLL', 'stored', true) -- setNewValue true // UNCOMMENT
		return end
	end
end


function Manage_Scroll_Auto(load) -- load is boolean
	for i = 0, r.CountTracks(0)-1 do
	local tr = r.GetTrack(0,i)
	local stored, extended_data = r.GetSetMediaTrackInfo_String(tr, 'P_EXT:MIXER SCROLL', '', false) -- setNewValue false
		if load and stored then
		r.SetMixerScroll(tr) -- load
		return end
		if not load and stored and r.GetMixerScroll() ~= tr then -- store, only when Mixer scroll postition changes to avoid unnecessary overwriting
		r.GetSetMediaTrackInfo_String(tr, 'P_EXT:MIXER SCROLL', '', true) -- setNewValue true // DELETE CURRENT EXT DATA BECAUSE ANOTHER TRACK IS LIKELY TO MOVE TO THE LEFTMOST POSITION AND BE STORED		
		r.GetSetMediaTrackInfo_String(r.GetMixerScroll(), 'P_EXT:MIXER SCROLL', 'stored', true) -- setNewValue true
		return end
	end
end


function AUTO()

local tab_cnt = Count_Proj_Tabs()
local proj, projfn = r.EnumProjects(-1)
local LOAD = tab_cnt ~= tab_cnt_init or proj ~= proj_init

	if LOAD then tab_cnt_init, proj_init = tab_cnt, proj end -- update

Manage_Scroll_Auto(LOAD)

r.defer(AUTO)

end

function At_Exit_Wrapper(func, ...)
-- thanks to Lokasenna, https://forums.cockos.com/showthread.php?t=218805 -- defer with args
-- his code didn't work because func(...) produced an error without there being elipsis
-- in function() as well, but gave direction
local t = {...}
return function() func(table.unpack(t)) end
end


function Re_Set_Toggle_State(sect_ID, cmd_ID, toggle_state)
r.SetToggleCommandState(sect_ID, cmd_ID, toggle_state)
r.RefreshToolbar(cmd_ID)
end


	if Script_Not_Enabled(ENABLE_SCRIPT) then return r.defer(function() do return end end) end

	
local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()

AUTO_MODE = #AUTO_MODE:gsub(' ', '') > 0

	if not AUTO_MODE then

	-- Project pointers seem to be consistent within session depending on the project tab ordinal position, a project tab closed and then opened at the same ordinal position will have the same pointer, the pointer only changes if the project tab position has changed, therefore comparison of project pointers to trigger mixer scrtoll position recall on project load doesn't suffice in this scenario and to allow recalling it when loading a project in the same tab which was closed last the custom action 'Open next proj tab and restore Mixer scroll position' has 2 script instances, the 1st one updates the tab count and the 2nd one uses the tab count difference to make LOAD condition true

	local tab_cnt = Count_Proj_Tabs()
	local last_state = r.GetExtState('MIXER_SCROLL', 'loaded')
	local proj_last, tab_cnt_last = last_state:match('(.+):(.+)')
	local proj, projfn = r.EnumProjects(-1) -- -1 current proj
	local proj = tostring(proj)

	local LOAD = #last_state == 0
	or tab_cnt_last+0 ~= tab_cnt -- converting tab_cnt to number
	or proj_last ~= proj

	Manage_Scroll_Manual(LOAD, tab_cnt, proj)

	else
	
	Re_Set_Toggle_State(sect_ID, cmd_ID, 1)

	tab_cnt_init = Count_Proj_Tabs()
	proj_init, projfn = r.EnumProjects(-1) -- -1 current proj
	
	AUTO()

	end

	
	if AUTO_MODE then
	r.atexit(At_Exit_Wrapper(Re_Set_Toggle_State, sect_ID, cmd_ID, 0))
	end

do return r.defer(function() do return end end) end






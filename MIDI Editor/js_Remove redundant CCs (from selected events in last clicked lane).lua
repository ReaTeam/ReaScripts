 --[[
  * ReaScript Name:  Remove redundant CCs
  * Description:  Remove redundant events from 7-bit CC, pitchwheel or channel pressure lanes with a single click.
  * Instructions:  In the USER AREA of the script (below the changelog), the user can customize the following options:
  *                (It may be useful to link different versions of the script to different shortcuts.)
  *                  - lanes_from_which_to_remove:  "all", "last clicked" or "under mouse"
  *                  - ignore_LSB_from_14bit_CCs:  Ignore LSB when comparing pitchwheel events
  *                  - only_analyze_selected:  Limit analysis and removal to selected events?
  *                  - automatically_delete_muted_CCs: Muted CCs are inherently redundant
  *                  - show_error_messages
  *                (* at present, the script does not work with 14-bit CC lanes)
  * Screenshot: 
  * Notes: 
  * Category: 
  * Author: juliansader
  * Licence: GPL v3
  * Forum Thread: Simple but useful MIDI editor tools: warp, stretch, deselect etc
  * Forum Thread URL: forum.cockos.com/showthread.php?t=176878
  * Version: 0.91
  * REAPER: 5.20
  * Extensions: SWS/S&M 2.8.3
 ]]
 
 --[[
  Changelog:
   * v0.9 (2016-05-28)
     + Initial release.
   * v0.91 (2016-06-29)
     + The "Remove Redundant CCs" script has several settings that the user can customize in the script's USER AREA. This is a version of the script with the following settings:
     + CC LANE: CCs will be removed from the last clicked CC lane (not from the lane under the mouse).
     + SELECTION: Only selected CCs will be analyzed. Unselected CCs will be ignored.
     + MUTED: Muted CCs will automatically be removed since they are inherently redundant.
     + 14BIT CC LSB: When analyzing pitchwheel events, the LSB will be ignored.
 ]]
 
 -- USER AREA:
 -- (Settings that the user can customize)
 
 lanes_from_which_to_remove = "last clicked" -- "all", "last clicked" or "under mouse"
 ignore_LSB_from_14bit_CCs  = true -- Ignore LSB when comparing pitchwheel events
 only_analyze_selected = true -- Limit analysis and removal to selected events?
 automatically_delete_muted_CCs = true -- Muted CCs are inherently redundant
 show_error_messages = true
 
 -- ask_confirmation_before_deletion -- not used yet in this version
 
 -- End of USER AREA
 -----------------------------------------------------------------
 
 
 -----------------------------------------------------------------
 -- Function to show error messages if show_error_messages == true
 function showErrorMsg(errorMsg)
     if show_error_messages == true and type(errorMsg) == "string" then
         reaper.ShowConsoleMsg("\n\nERROR:\n" 
                               .. errorMsg 
                               .. "\n\n"
                               .. "(To suppress future non-critical error messages, set 'show_error_messages' to 'false' in the USER AREA near the beginning of the script.)"
                               .. "\n\n")    
     end
 end  
 
 
 -----------------------------
 -- Code execution starts here
 
 -- Various constants
 CCmsg = 176
 PITCHmsg = 224
 CHANPRESSmsg = 208
 
 PITCHlane = 0x201
 CHANPRESSlane = 0x203
 
 local editor, take, targetLane, CCindex
 
 -- Trying a trick to prevent creation of new undo state 
 --     if code does not reach own Undo_BeginBlock
 function noUndo()
 end
 reaper.defer(noUndo)
 
 -- Test whether user customizable parameters are usable
 if lanes_from_which_to_remove ~= "under mouse" 
 and lanes_from_which_to_remove ~= "last clicked" 
 and lanes_from_which_to_remove ~= "all" then
     reaper.ShowConsoleMsg('ERROR:\nThe setting lanes_from_which_to_remove can only take on the values "under mouse", "last clicked" or "all".\n')
     return(false) end
 if type(ignore_LSB_from_14bit_CCs) ~= "boolean" then
     reaper.ShowConsoleMsg("\n\nERROR:\nThe setting 'ignore_LSB_from_14bit_CCs' can only take on the values 'true' or 'false'.\n")
     return(false) end
 if type(only_analyze_selected) ~= "boolean" then
     reaper.ShowConsoleMsg("\n\nERROR:\nThe setting 'only_analyze_selected' can only take on the values 'true' or 'false'.\n")
     return(false) end
 if type(automatically_delete_muted_CCs) ~= "boolean" then
     reaper.ShowConsoleMsg("\n\nERROR:\nThe setting 'automatically_delete_muted_CCs' can only take on the values 'true' or 'false'.\n")
     return(false) end
 if type(show_error_messages) ~= "boolean" then    
     reaper.ShowConsoleMsg("\n\nERROR:\nThe setting 'show_error_messages' can only take on the values 'true' or 'false'.\n")
     return(false) end    
     
 -- Test whether a MIDI editor and an active take are in fact available
 editor = reaper.MIDIEditor_GetActive()
 if editor == nil then 
     showErrorMsg("No active MIDI editor found.")
     return(false)
 end
 take = reaper.MIDIEditor_GetTake(editor)
 if take == nil then 
     showErrorMsg("No active take in MIDI editor.")
     return(false)
 end
 
 -- Try to get lane info
 if lanes_from_which_to_remove == "last clicked" then
 
     targetLane = reaper.MIDIEditor_GetSetting_int(editor, "last_clicked_cc_lane")
     if targetLane == -1 then
         showErrorMsg("No clicked lane found in MIDI editor.\n\n"
                     .."(Hint: To remove CCs from the lane under the mouse instead of the last clicked lane, "
                     .."change the 'lanes_from_which_to_remove' setting in the USER AREA to 'under mouse'.)")
         return(false)
     elseif not ((0 <= targetLane and targetLane <= 127) or targetLane == PITCHlane or targetLane == CHANPRESSlane) then
         showErrorMsg("This script only works in 7-bit CC lanes, pitchwheel or channel pressure lanes.\n\n"
                     .."(Note: The choice of method for removing redundancies from 14-bit CC lanes will depend on the user's intent: "
                     .."For example, LSB information can be removed by simply deleting the CCs in the LSB lane.)")
         return(false)
     end
     
 elseif lanes_from_which_to_remove == "under mouse" then
 
     _, _, currentDetails = reaper.BR_GetMouseCursorContext()
     if not (currentDetails == "cc_lane" or currentDetails == "cc_selector") then 
         showErrorMsg("Mouse is not over a CC lane.\n\n"
                    .."(Hint: To remove CCs from the last clicked lane instead of the lane under the mouse, "
                    .."change the 'lanes_from_which_to_remove' setting in the USER AREA to 'last clicked'.)")
         return(false)
     end
     
     -- SWS version 2.8.3 has a bug in the crucial function "BR_GetMouseCursorContext_MIDI()"
     -- https://github.com/Jeff0S/sws/issues/783
     -- For compatibility with 2.8.3 as well as other versions, the following lines test the SWS version for compatibility
     _, testParam1, _, _, _, testParam2 = reaper.BR_GetMouseCursorContext_MIDI()
     if type(testParam1) == "number" and testParam2 == nil then SWS283 = true else SWS283 = false end
     if type(testParam1) == "boolean" and type(testParam2) == "number" then SWS283again = false else SWS283again = true end 
     if SWS283 ~= SWS283again then
         reaper.ShowConsoleMsg("\n\nERROR:\nCould not determine compatible SWS version.\n")
         return(false)
     end
     
     if SWS283 == true then
         _, _, targetLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
     else 
         _, _, _, targetLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
     end
     
     if targetLane == -1 then
         showErrorMsg("Could not determine lane under mouse.")
         return(false)
     elseif not ((0 <= targetLane and targetLane <= 127) or targetLane == PITCHlane or targetLane == CHANPRESSlane) then
         showErrorMsg("This script only works in 7-bit CC lanes, pitchwheel or channel pressure lanes.\n\n"
                     .."(Note: The choice of method for removing redundancies from 14-bit CC lanes will depend on the user's intent: "
                     .."For example, LSB information can be removed by simply deleting the CCs in the LSB lane.)")
         return(false)
     end    
     
 end
 
 
 -- Tests done and everything seems OK, so script can go ahead.  Start Undo block.
 reaper.Undo_BeginBlock()
 
 
 -- Initialize tables
 -- tableRedundantCCs = {}
 local tableLast = {}
 tableLast.pitch = {}
 for c = 0, 15 do -- initialize channels for MSB and LSB
     tableLast.pitch[c] = {}
 end
 tableLast.chanpress = {}
 tableLast.CC = {}
 for i = 0, 127 do -- initialize lanes for channels
     tableLast.CC[i] = {}
 end
 
 
 -- Iterate through CCs, looking for redundancies 
 reaper.MIDI_Sort(take)
 _, _, ccevtcnt, _ = reaper.MIDI_CountEvts(take)
 local countRedundancies = 0
 
 if only_analyze_selected == true then
     CCindex = reaper.MIDI_EnumSelCC(take, -1)
 else
     CCindex = 0
 end
 
 while (CCindex ~= -1 and CCindex < ccevtcnt) do
 
     doDelete = false
     _, _, muted, _, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, CCindex)
 
     if (lanes_from_which_to_remove == "all" and
        (chanmsg == CCmsg or chanmsg == PITCHmsg or chanmsg == CHANPRESSmsg))
     or (lanes_from_which_to_remove ~= "all" and 
        ( (targetLane == msg2 and chanmsg == CCmsg) 
          or (targetLane == PITCHlane and chanmsg == PITCHmsg)
          or (targetLane == CHANPRESSlane and chanmsg == CHANPRESSmsg)))
     then
         if muted == true and automatically_delete_muted_CCs == true then
             doDelete = true
             
         elseif chanmsg == PITCHmsg then 
             if (ignore_LSB_from_14bit_CCs == true and msg3 == tableLast.pitch[chan].MSB)
             or (ignore_LSB_from_14bit_CCs == false and msg3 == tableLast.pitch[chan].MSB and msg2 == tableLast.pitch[chan].LSB)
             then
                 --table.insert(tableRedundantCCs, CCindex)
                 doDelete = true
             else
                 tableLast.pitch[chan].MSB = msg3 
                 tableLast.pitch[chan].LSB = msg2
             end
             
         elseif chanmsg == CHANPRESSmsg then
             if tableLast.chanpress[chan] == msg2 then
                 --table.insert(tableRedundantCCs, CCindex)
                 doDelete = true
             else
                 tableLast.chanpress[chan] = msg2
             end
             
         elseif chanmsg == CCmsg then
             if tableLast.CC[msg2][chan] == msg3 then
                 --table.insert(tableRedundantCCs, CCindex)
                 doDelete = true
             else
                 tableLast.CC[msg2][chan] = msg3
             end
             
         end
             
     end
     
     if doDelete == true then
         reaper.MIDI_DeleteCC(take, CCindex)
         countRedundancies = countRedundancies + 1
         CCindex = CCindex - 1
         ccevtcnt = ccevtcnt - 1
     end
     
     if only_analyze_selected == true then
         CCindex = reaper.MIDI_EnumSelCC(take, CCindex)
     else
         CCindex = CCindex + 1
     end
     
 end -- while (CCindex ~= -1 and CCindex < ccevtcnt)
 
 --[[ Now delete redundant CCs, if any
 if #tableRedundantCCs == 0 then
     showErrorMsg("No redundant CCs found")
 else
     local doDelete = false
     if ask_confirmation_before_deletion == true then
         retval, answer = reaper.GetUserInputs("Deletion confirmation", 1, "Delete ".. tostring(#tableRedundantCCs) .." CCs?", "y")
         if retval == true and (answer == "y" or answer == "Y") then doDelete = true else doDelete = false end
     else
         doDelete = true
     end
     
     if doDelete == true then
         for i = #tableRedundantCCs, 1, -1 do
             _, _, muted, _, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, tableRedundantCCs[i])
             if chanmsg ~= CCmsg then showErrorMsg("Not CC") end
             reaper.MIDI_DeleteCC(take, tableRedundantCCs[i])
         end
     end
 end
 ]]
 
 if lanes_from_which_to_remove == "all" then
     reaper.Undo_EndBlock("Removed ".. tostring(countRedundancies) .. " redundant events from all lanes", -1)    
 elseif lanes_from_which_to_remove ~= "all" then
     if (0 <= targetLane and targetLane <= 127) then
         reaper.Undo_EndBlock("Removed ".. tostring(countRedundancies) .. " redundant events from 7-bit CC lane " .. tostring(targetLane), -1) 
     elseif targetLane == PITCHlane then
         reaper.Undo_EndBlock("Removed ".. tostring(countRedundancies) .. " redundant events from pitchwheel lane", -1) 
     elseif targetLane == CHANPRESSlane then
         reaper.Undo_EndBlock("Removed ".. tostring(countRedundancies) .. " redundant events from channel pressure lane", -1)  
     end
 end

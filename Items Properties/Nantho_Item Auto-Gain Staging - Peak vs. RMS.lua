--[[
 * Provides: [nomain] spk77_Get max peak val and pos from take_function.lua > Nantho_PeakVsRMS/spk77_Get max peak val and pos from take_function.lua
 * ReaScript Name: Item auto-gain staging (peak vs RMS)
 * About: 
 *  - Normalize selected items to -x dB RMS (x and unit specified by user imput)  
 *  - If those normalized items have peaks over -y dB (y specified by user), trim them down to peak at -y dB max
 * Link: http://forum.cockos.com/showthread.php?t=184368
 * Instructions: Select items. Run.
 * Screenshot: 
 * Author: Nantho
 * Licence: GPL v3
 * Forum Thread: REQ: http://forum.cockos.com/showthread.php?t=182701
 * Forum Thread URI: 
 * REAPER: 5.0
 * Extensions: spk77 Get max peak val and pos from take (function and example).lua
 * Extensions: SWS extension
 * Version: 1.0.0-1
--]]

--[[
 * Changelog:
 * v1.0 (2016-11-29)
	+ Initial Release
--]]


-- Special thanks to X-Raym

-- USER CONFIG AREA -----------------------------------------------------------

threshold = -10 -- number: Default threshold to select items
direction = "+" -- "+"/"-": Select if over or below the threshold

all_items = false

popup = true -- true/false: display a pop up box

console = true -- true/false: display debug messages in the console

------------------------------------------------------- END OF USER CONFIG AREA


-- INCLUDES -----------------------------------------------------------

local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "/Nantho_PeakVsRMS/spk77_Get max peak val and pos from take_function.lua")

-------------------------------------------------------------- INCLUDES


-- UTILITIES -------------------------------------------------------------

-- Display a message in the console for debugging
function Msg(value)
	if console then
		reaper.ShowConsoleMsg(tostring(value) .. "\n")
	end
end


-- Save item selection
function SaveSelectedItems (table)
	for i = 0, reaper.CountSelectedMediaItems(0)-1 do
		table[i+1] = reaper.GetSelectedMediaItem(0, i)
	end
end


--------------------------------------------------------- END OF UTILITIES


-- Main function
function main()

	for i, item in ipairs(init_sel_items) do

		local take = reaper.GetActiveTake(item)

		if take then
			
			local ret, max_peak_val, peak_sample_pos = get_sample_max_val_and_pos(take, true, true, true)

			if ret then

				if direction_string == "+" then
					if max_peak_val < threshold then
						reaper.SetMediaItemSelected(item, false)

					else
						
						peak = max_peak_val						
						item_vol = reaper.GetMediaItemTakeInfo_Value(take,"D_VOL")
						item_vol_DB = 20 * ( math.log( item_vol, 10 ) )
						item_diff_DB = peak - threshold
						new_item_vol_DB = item_vol_DB - item_diff_DB 						
 						new_item_vol = math.exp( new_item_vol_DB * 0.115129254 )

 						reaper.SetMediaItemTakeInfo_Value(take ,"D_VOL" , new_item_vol)				


					end
				
				else
					if max_peak_val > threshold then
						reaper.SetMediaItemSelected(item, false)

					end
				end

			end

		end

	end

end


-- INIT

if all_items then
	reaper.Main_OnCommand(40182, 0) -- Select all items
end

-- See if there is items selected
count_sel_items = reaper.CountSelectedMediaItems(0)

if count_sel_items > 0 then


	if popup then
		threshold_string = tostring(threshold)
		direction_string = tostring(direction)
		retval, retvals_csv = reaper.GetUserInputs("Peak vs. RMS", 2, "Peak Threshold (dB),Under/Over (-/+)?", threshold_string .. "," .. direction_string)

		if retval then
			threshold_string, direction_string = retvals_csv:match("([^,]+),([^,]+)")

			if threshold_string then
				threshold = tonumber(threshold_string)
			end

		end

	end

	if (retval or not popup) and threshold then

		reaper.PreventUIRefresh(1)

		reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

		reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_NORMRMS"), 0)

		init_sel_items =  {}
		SaveSelectedItems(init_sel_items)

		main()

		reaper.Undo_EndBlock("Item Auto-Gain Staging - Peak vs. RMS", -1) -- End of the undo block. Leave it at the bottom of your main function.

		reaper.UpdateArrange()

		reaper.PreventUIRefresh(-1)

	end

end

--[[
   * ReaScript Name: Changes rate of selected items by a multiplication factor and adjusts the lengths
   * Lua script for Cockos REAPER
   * Author: Hector Corcin (HeDa)
   * Author URI: http://forum.cockos.com/member.php?u=47822
   * Licence: GPL v3
   * Version: 0.1
]]

--[[
Changelog:

v0.1 (2016-02-24)
  + Initial version
]]--

-- USER CONFIG AREA -----------------------------------------------------------

------------------------------------------------------- END OF USER CONFIG AREA


-- UTILITIES -------------------------------------------------------------

-- Save item selection
function SaveSelectedItems (table)
	for i = 0, reaper.CountSelectedMediaItems(0)-1 do
		table[i+1] = reaper.GetSelectedMediaItem(0, i)
	end
end

--------------------------------------------------------- END OF UTILITIES


-- Main function
function main()
	function GetVar_Dialog(title, captions_csv, defvals_csv)
      retval, retvals_csv = reaper.GetUserInputs(title, 1, captions_csv,  defvals_csv)
      if retval then
      return retvals_csv
      end  
    end
	rate = GetVar_Dialog("HeDa_Rate Changer", "Multiply rate of selected items by:", 1.0)
	if rate then 
		for i, item in ipairs(init_sel_items) do
			itemstart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
			itemlength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
			itemend = itemstart + itemlength
				
			take = reaper.GetActiveTake(item)
			currentrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
			newrate=currentrate * rate
			reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", newrate)
			newlength = itemlength * currentrate / newrate
			reaper.SetMediaItemInfo_Value(item, "D_LENGTH", newlength)
		end
	end
end


-- INIT
-- See if there is items selected
count_sel_items = reaper.CountSelectedMediaItems(0)

if count_sel_items > 0 then

	reaper.PreventUIRefresh(1)

	reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.
	
	init_sel_items =  {}
	SaveSelectedItems(init_sel_items)

	main()

	reaper.Undo_EndBlock("My action", -1) -- End of the undo block. Leave it at the bottom of your main function.

	reaper.UpdateArrange()

	reaper.PreventUIRefresh(-1)
	
else
	reaper.ShowMessageBox("Select items first", "Please", 0)
end
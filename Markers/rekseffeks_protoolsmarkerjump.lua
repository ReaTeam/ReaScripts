-- @description Pro Tools-like marker jump behavior
-- @author Rek's Effeks
-- @version 1.0.1
-- @changelog created it baybee.
-- @about
--   Pro Tools marker jump behavior. Opens a text box allowing multi-digit input, after which the edit cursor will jump to the entered marker ID. 
--
--   Run the script, enter a numerical input (other characters are sanitized out), press enter.
--
--   Recommended to bind to numpad enter as I couldn't figure out how to treat numpad period as an enter character.


ret, user_input = reaper.GetUserInputs("Pro Tools marker behavior", 1, "Enter marker number:", "")
local number
local res
if ret == true then
	if (user_input ~= "") then
		res, _ = user_input:gsub("%D+", "") --strips out non numbers. i don't know how this works
		number = tonumber(res)
		num_markers = reaper.CountProjectMarkers(0)
		if num_markers < number then
	 		reaper.ShowMessageBox("That numbered marker does not exist.","Error", 0)
		else
			reaper.GoToMarker(0, number, 0)
		end
	end
end

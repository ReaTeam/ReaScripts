-- @description Pro Tools-like marker jump behavior
-- @author Rek's Effeks
-- @version 1.0.2
-- @changelog fixed behavior with manually-numbered markers having higher numbers than the total count. no longer provides error message on failure.
-- @about
--   Pro Tools marker jump behavior. Opens a text box allowing multi-digit input, after which the edit cursor will jump to the entered marker ID. 
--   Run the script, enter a numerical input (other characters are sanitized out), press enter.
--   Recommended to bind to numpad enter as I couldn't figure out how to treat numpad period as an enter character.

ret, user_input = reaper.GetUserInputs("Pro Tools marker behavior", 1, "Enter marker number:", "")
local number
local res
if ret == true then
	if (user_input ~= "") then
		res, _ = user_input:gsub("%D+", "")
		number = tonumber(res)
		reaper.GoToMarker(0, number, 0)
	end
end

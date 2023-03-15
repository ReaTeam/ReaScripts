-- @description Find and Replace in Marker Region Names
-- @author Aaron Cendan
-- @version 1.2
-- @changelog
--   Added field for toggling search case-sensitivity.
--   Fixed replacement with /blank; only affects part of matching name(s).
--   Added replacement with /clear; erases entire name of matching markers/regions.
-- @metapackage
-- @provides
--   [main] . > acendan_Find and Replace in Region Names.lua
--   [main] . > acendan_Find and Replace in Marker Names.lua
-- @link https://aaroncendan.me
-- @about
--   # Find and Replace in Marker/Region Names
--   By Aaron Cendan - May 2020
--
--   ### General Info
--   * Prompts user to replace part of a marker or region's name with new text if that marker/region name contains search criteria.
--   * Uses file name to detect search type.
--
--   ### Search Parameters
--   * Accepts "/blank" as search criteria for finding and replacing blank marker/region names.
--   * Accepts "/clear" as replacement criteria for erasing name of matching markers/regions.
--   * Case-sensitive and case-insensitive searching.

function findReplace()

	reaper.Undo_BeginBlock()

	-- Identify region/marker mode based on script name
	local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
	local region_mode = script_name:match('Region')
	local mode_name = region_mode and 'Region' or 'Marker'
	local retval, num_markers, num_regions = reaper.CountProjectMarkers( 0 )
	local num_total = num_markers + num_regions

	if mode_name == "Region" then
		num_items = num_regions
	elseif mode_name == "Marker" then
		num_items = num_markers
	end

	if num_items > 0 then

		ret, search_string, replace_string, search_field, case_sens = getSearchInfo(mode_name)
		if not ret then return end

		-- Confirm is valid search, search info not blank
		if search_string and replace_string and search_field and case_sens then
			if case_sens == "/c" or case_sens == "/i" then
				if search_field == "/p" then
					searchFullProject(num_total, search_string, replace_string, mode_name, case_sens)

				elseif search_field == "/t" then
					searchTimeSelection(num_total, search_string, replace_string, mode_name, case_sens)

				--Ideally it would be possible to find/replace in render matrix, see function below:
				--elseif search_field == "/m" then
					--searchSelectedMarkersRegions(num_total, search_string, replace_string, mode_name)

				else
					reaper.ShowMessageBox("Search field must be exactly /p or /t","Find/Replace", 0)
					findReplace()
				end
			else
				reaper.ShowMessageBox("Case sensitivity must be exactly /c or /i","Find/Replace", 0)
				findReplace()
			end
		else
			reaper.ShowMessageBox("Search fields cannot be empty!" .. "\n" .. "\n" .. "To Find blank names or Replace part of names with blanks, then use:" .. "\n" .. "/blank".. "\n" .. "\n" .. "To clear the entire name of a matching marker/region, then Replace with:" .. "\n" .. "/clear","Find/Replace", 0)
			findReplace()
		end
	else
		reaper.ShowMessageBox(string.format("Project has no %s" .. "s!", mode_name),"Find/Replace", 0)
	end

	reaper.Undo_EndBlock("Find and Replace", -1)

end

function getSearchInfo(mode_name)
	-- Check for previous search field
	local ret, prev_field =  reaper.GetProjExtState(0, "FindReplaceStorage", "PrevSearchField")
	-- Check for previous search sensitivity
	local ret2, prev_sens =  reaper.GetProjExtState(0, "FindReplaceStorage", "PrevCaseSens")

	if ret == 1 and prev_field == "/p" or prev_field == "/t" then --or prev_field == "/m" then      -- If valid search field used previously, use as default
		if ret2 == 1 and prev_sens == "/c" or prev_sens == "/i" then
			-- Store user input for search and replace strings
			ret,user_input = reaper.GetUserInputs(string.format("Find & Replace in %s Names", mode_name),  4,
							   "Find: Text to Search For,Replace: Text to Replace With,Project /p or Time Selection /t,Case-Sensitive /c or Insensitive /i,extrawidth=100",",,"..prev_field..","..prev_sens)
			search_string, replace_string, search_field, case_sens = user_input:match("([^,]+),([^,]+),([^,]+),([^,]+)")
			-- Save new search field
			if search_field then
				reaper.SetProjExtState(0, "FindReplaceStorage", "PrevSearchField",search_field)
			end
			-- Save new case sensitivity
			if case_sens then
				reaper.SetProjExtState(0, "FindReplaceStorage", "PrevCaseSens",case_sens)
			end
		else
			-- Store user input for search and replace strings
			ret,user_input = reaper.GetUserInputs(string.format("Find & Replace in %s Names", mode_name),  4,
							   "Find: Text to Search For,Replace: Text to Replace With,Project /p or Time Selection /t,Case-Sensitive /c or Insensitive /i,extrawidth=100",",,"..prev_field..",/c")
			search_string, replace_string, search_field, case_sens = user_input:match("([^,]+),([^,]+),([^,]+),([^,]+)")
			-- Save new search field
			if search_field then
				reaper.SetProjExtState(0, "FindReplaceStorage", "PrevSearchField",search_field)
			end
			-- Save new case sensitivity
			if case_sens then
				reaper.SetProjExtState(0, "FindReplaceStorage", "PrevCaseSens",case_sens)
			end
		end
	else                    -- Search not used yet in this project, use Project (/p) field as default
		if ret2 == 1 and prev_sens == "/c" or prev_sens == "/i" then
			-- Store user input for search and replace strings
			ret,user_input = reaper.GetUserInputs(string.format("Find & Replace in %s Names", mode_name),  4,
							   "Find: Text to Search For,Replace: Text to Replace With,Project /p or Time Selection /t,Case-Sensitive /c or Insensitive /i,extrawidth=100",",,/p,"..prev_sens)
			search_string, replace_string, search_field, case_sens = user_input:match("([^,]+),([^,]+),([^,]+),([^,]+)")
			-- Save new search field
			if search_field then
				reaper.SetProjExtState(0, "FindReplaceStorage", "PrevSearchField",search_field)
			end
			-- Save new case sensitivity
			if case_sens then
				reaper.SetProjExtState(0, "FindReplaceStorage", "PrevCaseSens",case_sens)
			end
		else
			-- Store user input for search and replace strings
			ret,user_input = reaper.GetUserInputs(string.format("Find & Replace in %s Names", mode_name),  4,
							   "Find: Text to Search For,Replace: Text to Replace With,Project /p or Time Selection /t,Case-Sensitive /c or Insensitive /i,extrawidth=100",",,/p,/c")
			search_string, replace_string, search_field, case_sens = user_input:match("([^,]+),([^,]+),([^,]+),([^,]+)")
			-- Save new search field
			if search_field then
				reaper.SetProjExtState(0, "FindReplaceStorage", "PrevSearchField",search_field)
			end
			-- Save new case sensitivity
			if case_sens then
				reaper.SetProjExtState(0, "FindReplaceStorage", "PrevCaseSens",case_sens)
			end
		end
	end

	return ret, search_string, replace_string, search_field, case_sens
end

function analyzeMarkerRegion(search_string, replace_string, case_sens, i, isrgn, pos, rgnend, name, markrgnindexnumber, color)
	if search_string ~= "/blank" and search_string ~= "/clear" then
		if case_sens == "/c" then
			if string.find(name, search_string) then
				if replace_string ~= "/blank" and replace_string ~= "/clear" then
					local new_name = string.gsub( name, search_string, replace_string)
					reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
				elseif replace_string == "/blank" then
					local new_name = string.gsub( name, search_string, "")
					reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
				elseif replace_string == "/clear" then
					reaper.DeleteProjectMarker( 0, markrgnindexnumber, isrgn )
					reaper.AddProjectMarker2( 0, isrgn, pos, rgnend, '', markrgnindexnumber, color )
				end
			end
		elseif case_sens == "/i" then
			local lower_name = string.lower(name)
			local lower_search_string = string.lower(search_string)
			local j, k = string.find(lower_name, lower_search_string)
			if j and k then
				if replace_string ~= "/blank" and replace_string ~= "/clear" then
					local new_name = string.sub(name,1,j-1) .. replace_string .. string.sub(name,k+1,string.len(name))
					reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
				elseif replace_string == "/blank" then
					local new_name = string.sub(name,1,j-1) .. string.sub(name,k+1,string.len(name))
					reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
				elseif replace_string == "/clear" then
					reaper.DeleteProjectMarker( 0, markrgnindexnumber, isrgn )
					reaper.AddProjectMarker2( 0, isrgn, pos, rgnend, '', markrgnindexnumber, color )
				end
			end
		end
	else
		if name == "" then
			if replace_string ~= "/blank" and replace_string ~= "/clear" then
				local new_name = replace_string
				reaper.SetProjectMarkerByIndex( 0, i, isrgn, pos, rgnend, markrgnindexnumber, new_name, color )
			end
		end
	end
end

function searchFullProject(num_total, search_string, replace_string, mode_name, case_sens)
	-- Loop through all markers/regions in project
	if mode_name == "Region" then
		local i = 0
		while i < num_total do
			local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
			if isrgn then
				analyzeMarkerRegion(search_string, replace_string, case_sens, i, isrgn, pos, rgnend, name, markrgnindexnumber, color)
			end
			i = i + 1
		end
	elseif mode_name == "Marker" then
		local i = 0
		while i < num_total do
			local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
			if not isrgn then
				analyzeMarkerRegion(search_string, replace_string, case_sens, i, isrgn, pos, rgnend, name, markrgnindexnumber, color)
			end
			i = i + 1
		end
	end
end

function searchTimeSelection(num_total, search_string, replace_string, mode_name, case_sens)
	-- Loop through all markers/regions in time selection
	StartTimeSel, EndTimeSel = reaper.GetSet_LoopTimeRange(0,0,0,0,0);
	-- Confirm valid time selection
	if StartTimeSel ~= EndTimeSel then
		if mode_name == "Region" then
			local i = 0
			while i < num_total do
				local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
				if isrgn then
					if pos >= StartTimeSel and rgnend <= EndTimeSel then
						analyzeMarkerRegion(search_string, replace_string, case_sens, i, isrgn, pos, rgnend, name, markrgnindexnumber, color)
					end
				end
				i = i + 1
			end
		elseif mode_name == "Marker" then
			local i = 0
			while i < num_total do
				local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3( 0, i )
				if not isrgn then
					if pos >= StartTimeSel and pos <= EndTimeSel then
						analyzeMarkerRegion(search_string, replace_string, case_sens, i, isrgn, pos, rgnend, name, markrgnindexnumber, color)
					end
				end
				i = i + 1
			end
		end
	else
		reaper.ShowMessageBox("To Find & Replace within a time selection, you are going to need a time selection!","Find/Replace", 0)
	end
end

function searchSelectedMarkersRegions(num_total, search_string, replace_string, mode_name)
	-- Ideally, it would be possible to run this Find/Replace functionality on regions
	-- that are selected in the Region Render Matrix, but unfortunately, that info is not
	-- exposed via the API as of Reaper v6.10.
end

reaper.PreventUIRefresh(1)

findReplace()

reaper.PreventUIRefresh(-1)

reaper.UpdateArrange()

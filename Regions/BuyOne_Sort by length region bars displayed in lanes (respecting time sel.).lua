--[[
ReaScript name: Sort by length region bars displayed in lanes
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.1
Changelog: #Added error message when there're no regions in project
	   #Added time selection support
	   #Added error message when there're no regions in time selection
	   #Updated script name
	   #Updated About tag text
Licence: WTFPL
REAPER: at least v5.962
Screenshots: https://git.io/JyD8d
About:	Sorts by length region bars with the same start position 
	in either ascending or descending order.
			
	Respects time selection as long as either the regions start 
	position or all their end positions are included in it.
		
	If after sorting some region bars become overlaped, wiggle 
	the Ruler bottom edge having grabbed the topmost track 
	upper edge.
]]

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper

local retval, mrk_cnt, rgn_cnt = r.CountProjectMarkers(0)

	if rgn_cnt == 0 then r.MB('No regions in the project.', 'ERROR', 0) return r.defer(function() do return end end) end


local start, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop - false; start, end - 0, allowautoseek - false
local time_sel = start ~= fin

	if time_sel then
	local within_time_sel_cnt = 0
	local i = 0
		repeat
		local retval, isrgn, pos, rgnend, name, markID, color = r.EnumProjectMarkers3(0, i)
			if time_sel and (pos >= start and pos <= fin or rgnend >= start and rgnend <= fin) then
			within_time_sel_cnt = within_time_sel_cnt + 1 or within_time_sel_cnt
			end
		i = i + 1
		until retval == 0 -- when no next marker/region

		if time_sel and within_time_sel_cnt == 0 then r.MB('No regions within time selection.', 'ERROR', 0) return r.defer(function() do return end end) end
	end


local RESP = r.MB('Longer region bars are at the top — click "YES"\n\nLonger region bars are at the bottom — click "NO"', 'PROMPT', 3)
	if RESP == 2 then return r.defer(function() do return end end) end

-- Enclosed and enclosing regions (different start and end pisitions) displayed in lanes in REAPER are sorted by length automatically such that the longer ones are at the top and this can't be changed
-- Amongst regions which have the same position	the greater the region ID the lower its lane

local t = {}
local same_pos
local i = 0
	repeat
	local retval, isrgn, pos, rgnend, name, markID, color = r.EnumProjectMarkers3(0, i)
		if not time_sel or time_sel and (pos >= start and pos <= fin or rgnend >= start and rgnend <= fin) then
			if isrgn and pos ~= same_pos then
			t[#t+1] = {} -- region group table
			local a = t[#t] -- for brevity
			a[#a+1] = {pos, rgnend, name, color, markID, retval} -- single region table; must be indexed so sorting by pos works below
			same_pos = pos
			elseif isrgn and pos == same_pos then
			local a = t[#t]
			a[#a+1] = {pos, rgnend, name, color, markID, retval}
			end
		end
	i = i + 1
	until retval == 0 -- when no next marker/region


function ID(t,RESP) -- extract IDs and sort
local t2 = {}
	for k,v in ipairs(t) do -- extract
	t2[#t2+1] = v[5] -- markID
	end
	if RESP == 6 then table.sort(t2) -- sort in ascending order
	else table.sort(t2, function(a,b) return a > b end) -- sort in descending order
	end
return t2
end


r.Undo_BeginBlock()

for k1, v1 in ipairs(t) do
  if v1 and next(v1) then
	local indices = ID(v1,RESP)
	table.sort(v1, function(a,b) return a[2] > b[2] end) -- sort by pos in descending order
    for k2, v2 in ipairs(v1) do
	 -- Since region ID should not be arbitrarily changed to avoid collision with existing IDs, reuse IDs within the same region group; to IDs sorted in ascending order apply properties sorted in decsending order and vice versa
	 -- Region/marker color value 0 and empty string name cannot be applied to another region/marker ID which already does have custom color and name set because these are interpreted as 'no change', so original color and name properties stick, that's why a string with a blank space must be applied to get rid of the name and simulate its absence and a value greater than zero must be applied to activate default color; negative values set color white
	 r.SetProjectMarker3(0, indices[k2], true, v2[1], v2[2], #v2[3] > 0 and v2[3] or ' ', (v2[4] > 0 or v2[4] < 0) and v2[4] or 1) -- proj, ID, isrgn true, pos, rgnend, name, color
	 --[[ OR -- to dispense with name and color workarounds employed above and re-insert the region with desired properties to begin with
	 	if #v2[3] == 0 or v2[4] == 0 then
		r.DeleteProjectMarker(0, indices[k2], true) -- 0 project, isrgn true
		r.AddProjectMarker2(0, true, v2[1]-1, v2[2], v2[3], indices[k2], v2[4]) -- 0 project, isrgn true // v2[1]-1 is meant to overcome the limitation which prevents inserting programmatically regions with exactly the same pos and rgnend values as another region, because here we insert one region with properties of another
		end
	r.SetProjectMarker3(0, indices[k2], true, v2[1], v2[2], v2[3], v2[4]) -- here we simply adjust the pos so it matches the original properties which is allowed as long as the region already exists, and reapply the rest of them
	--]]
    end
  end
end


r.Undo_EndBlock(string.format('Sort region bars by length — the longer %s', RESP == 6 and 'at the top' or 'at the bottom'), -1)









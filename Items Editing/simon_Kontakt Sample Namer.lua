-- @description Kontakt Sample Namer
-- @author Simon
-- @version 1.0
-- @screenshot https://user-images.githubusercontent.com/19229302/285487336-2a5678a9-5317-4174-988c-11667fa6da84.png
-- @about
--   # Kontakt Sample Namer
--
--   Names samples for use in Native Instruments Kontakt .Names items in the order:{track}{region}_RR_{rr_num}_{vel_min}_{vel_max}

-- Sample namer for Reaper, created by Simon Dalzell. 5-30-2016. I have no idea how to maintain a git repo.

function Msg(param)
  reaper.ShowConsoleMsg(tostring(param).."\n")
end

function Prompt()
	dyn_amount = 0
	rr_amount = 0
	import_pitch = true
	import_track = true
	set_color = true
	retval, retvals_csv = reaper.GetUserInputs("Sample Export Namer", 5, "Number of Dynamic Levels,Number of Round Robins,Read Pitch from Regions?,Import track name?,Color dynamic levels?",tostring(dyn_amount) .. "," ..tostring(rr_amount) .. "," ..tostring(import_pitch) .. "," ..tostring(import_track) .. "," ..tostring(set_color))

	if retval == true then -- if user clicked ok
		dyn_amount, rr_amount, import_pitch, import_track, set_color = retvals_csv:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
		if dyn_amount then dyn_amount = tonumber(dyn_amount) end
		if dyn_amount == 0 then dyn_amount = 1 end

		if rr_amount then rr_amount = tonumber(rr_amount) end
		if rr_amount == 0 then rr_amount = 1 end

		if import_pitch == "true" then import_pitch = true else import_pitch = false end
		if import_track == "true" then import_track = true else import_track = false end
		if set_color == "true" then set_color = true else set_color = false end
	end
	return retval
end

function AppendRR()
	count_sel_item = reaper.CountSelectedMediaItems(0)
	count_sel_tracks = reaper.CountSelectedTracks(0)
	  
	i = 0 -- goes from 0 to selected number of items
	j = 0 -- goes from 0 to number of tracks
	k = 1 -- goes from 1 to number of RRs (j is the number in "RR1", "RR2", etc)

	for j = 0, count_sel_tracks -1 do -- Runs through selected tracks one by one


		for k = 1, rr_amount do -- runs through rr number one by one

			while i < count_sel_item/count_sel_tracks do -- runs through media items by multiples of rr_amount
				
				item = reaper.GetSelectedMediaItem(0, i)
				item_take = reaper.GetActiveTake(item)

				local _, name = reaper.GetSetMediaItemTakeInfo_String(item_take, "P_NAME", "" .. k, false)
				local _, name = reaper.GetSetMediaItemTakeInfo_String(item_take, "P_NAME", name .. "_RR_" .. k, true)

				
				i = i + rr_amount
			end
			i = k
		end
	end
end

function AppendDyn()
	count_sel_item = reaper.CountSelectedMediaItems(0)
	count_sel_tracks = reaper.CountSelectedTracks(0)
	dyn_size = math.floor(127 / dyn_amount)
	  
	i = 0 -- goes from 0 to selected number of items
	j = 0 -- goes from 0 to number of tracks
	k = 1 -- goes from 1 to number of dynamics (j is the number in "RR1", "RR2", etc)
	l = 0 -- corresponds to dyn number

	for j = 0, count_sel_tracks -1 do -- Runs through selected tracks one by one

		i = 0
		while i < count_sel_item/count_sel_tracks do -- runs through items on one track by multiples of rr_amount

			for l = 1, dyn_amount do -- l corresponds to current dynamic level

				if l == 1 then -- initialize dynamic numbers for each new note group
					dyn_min = 1
					dyn_max = dyn_size
				end

				if l == dyn_amount then
					dyn_max = 127
				end

				for k = 0, rr_amount - 1 do -- k loops through sets of rrs and applies dynamic level text to items
					item = reaper.GetSelectedMediaItem(0, i + k)
					item_take = reaper.GetActiveTake(item)

					if set_color == true then
						reaper.SetMediaItemInfo_Value(item,"I_CUSTOMCOLOR", colors[l]) -- Set color
					end

					local _, name = reaper.GetSetMediaItemTakeInfo_String(item_take, "P_NAME", "RR" .. k, false) -- get previous take name
					local _, name = reaper.GetSetMediaItemTakeInfo_String(item_take, "P_NAME", name .. "_" .. dyn_min .. "_" .. dyn_max, true) -- set new take name
					

				end

				dyn_min = dyn_min + dyn_size
				dyn_max = dyn_max + dyn_size
				i = i + rr_amount

			end
		end
	end
end

function AppendRegion()
	count_sel_item = reaper.CountSelectedMediaItems(0)
	  
	i = 0
	  
	while i < count_sel_item do
	  
		item = reaper.GetSelectedMediaItem(0, i)
		        
		item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
		
		item_take = reaper.GetActiveTake(item)
		
		last_marker, last_region = reaper.GetLastMarkerAndCurRegion(0, item_pos)
		
		retval, region_exists, region_pos, region_end, region_name, marker_index = reaper.EnumProjectMarkers(last_region)
		
		local _, name = reaper.GetSetMediaItemTakeInfo_String(item_take, "P_NAME",region_name, false) -- get name
		local _, name = reaper.GetSetMediaItemTakeInfo_String(item_take, "P_NAME", name .. region_name, true) -- store new name
		
		i = i + 1
	end
end

function ImportTrack()
	count_sel_item = reaper.CountSelectedMediaItems(0)
	  
	i = 0
	  
	for i = 0, count_sel_item -1 do
	  
		item = reaper.GetSelectedMediaItem(0, i)
		item_track = reaper.GetMediaItem_Track(item)

		retval, item_track_name = reaper.GetSetMediaTrackInfo_String(item_track, "P_NAME", "", false)
		
		item_take = reaper.GetActiveTake(item)
		
		local _, name = reaper.GetSetMediaItemTakeInfo_String(item_take, "P_NAME","", false) -- get name
		local _, name = reaper.GetSetMediaItemTakeInfo_String(item_take, "P_NAME", item_track_name, true) -- store new name
	end
end

function Main()
	colors = {}
    for i = 1, 20 do
      colors[i] = 0
    end

    colors[1] = 25296750
    colors[2] = 33489024
    colors[3] = 23167906
    colors[4] = 28149483
    colors[5] = 31505564
    colors[6] = 15853876
    colors[7] = 31300864
    colors[8] = 16844908
    colors[9] = 12952244
    colors[10] = 1902341
    colors[11] = 36810826
    colors[12] = 26194408
    colors[13] = 2309881
    colors[14] = 83212661
    colors[15] = 47235791
    colors[16] = 4145279
    colors[17] = 22940017
    colors[18] = 5309774
    colors[19] = 42831570
    colors[20] = 27106875

	Prompt()
	if retval == true then
		reaper.Undo_BeginBlock()
		if import_track == true then
			ImportTrack()
		end

    if import_pitch == true then
    	AppendRegion()
    end

		if rr_amount > 1 then
			AppendRR()
		end

		if dyn_amount > 1 then
			AppendDyn()
		end
		reaper.Undo_EndBlock("Sample Namer: " .. dyn_amount .. " Dyn, " .. rr_amount .. " RRs", -1)
	end
end

Main()

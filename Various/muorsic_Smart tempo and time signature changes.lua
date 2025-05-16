-- @description Smart tempo and time signature changes
-- @author muorsic
-- @version 1.9
-- @changelog fixed ripple function to preserve next time signature change. (thanks @smandrap)
-- @link Forum thread https://forum.cockos.com/showthread.php?t=300105
-- @about
--   Features
--
--   - Captures original values and sets timebase to "time" before opening Reaper’s dialog (so no beats are added/subtracted when changing signatures).
--   - Compares new values to old ones.
--   - Handles tempo changes before time signatures.
--   - Fixes partial measures by inserting the correct time signature.
--   - Ripples time signatures: if your new signature spans more beats than the existing one and the next measure has a different signature, it adjusts all following signatures.
--   - Supports removal of time signatures as well.
--   - When timebase for markers is "Time" it will bypass the script.

-- muorsic_Smart tempo and time signature changes
-- Version 1.9 May 16th 2025
-- fixed ripple function to preserve next time signature change. (thanks @smandrap)
-- Known Bugs: 
-- Reaper Bug where linear tempo on previous point changes from true to false while next point has only meter change.
-- Some overlapping linear tempo marks can cause misbehaviour.. better adjust by mouse but mostly works


-----TO DO------
-- bug with partial beat, counts beats before current measure? WLO cue + insert beats


flux = 1e8

function Msg(str) -- for debug
    -- reaper.ShowConsoleMsg(str .. "\n")
end

function Round(str)
	roundnumber = string.format("%.2f", str)
	return roundnumber
end

function roundTo(val, step)
  return math.floor(val/step + 0.5) * step
end

function getTempoMarkers()
  local markers = {}
  local proj = 0  -- current project
  local count = reaper.CountTempoTimeSigMarkers(proj)
  
  for i = 0, count-1 do
    local _, timepos, _, _, bpm, ts_num, ts_den, linear= reaper.GetTempoTimeSigMarker(proj, i)
    
    markers[#markers+1] = {
      idx     = i,
      timepos = timepos,
      meter   = string.format("%d/%d", ts_num, ts_den),
      bpm     = bpm,
      tempo   = bpm,
      linear  = linear
    }
  end
  
  return markers
end

-- assume elsewhere you’ve done: point_created = true/false

function find_insert_point(Markers_orig, Markers_new)
  local n_o, n_n = #Markers_orig, #Markers_new

  -- if we've just created a point, return the first misalignment
  if point_created then
    for i = 1, math.min(n_o, n_n) do
      if Markers_orig[i].timepos ~= Markers_new[i].timepos then
        return Markers_new[i].idx
      end
    end
    return false  -- still aligned
  end

  -- otherwise, run the full divergence→realign scan
  local o_i, n_i = 1, 1

  while o_i <= n_o and n_i <= n_n do
    if Markers_orig[o_i].timepos == Markers_new[n_i].timepos then
      o_i = o_i + 1
      n_i = n_i + 1
    else
      -- first mismatch: advance both until (maybe) realigned
      repeat
        o_i = o_i + 1
        n_i = n_i + 1
      until (o_i > n_o or n_i > n_n)
            or (Markers_orig[o_i].timepos == Markers_new[n_i].timepos)

      if o_i <= n_o and n_i <= n_n then
        -- realigned: last extra was at new[n_i-1]
        return Markers_new[n_i - 1].idx
      else
        -- never realigns: return last new.idx
        return Markers_new[n_n].idx
      end
    end
  end

  -- completely aligned from start to finish
  return false
end



function info(point)
	Msg("  Point: " .. tostring(point.point))
	Msg("  Position: " .. Round(point.pos))
	Msg("  measurepos: " .. tostring(point.measurepos))
	Msg("  beatpos: " .. tostring(point.beatpos))
	Msg("  BPM: " .. tostring(point.bpm))
	Msg("  Pos BPM: ".. Round(point.posbpm))
	Msg("  Prev BPM: ".. Round(point.prevbpm))
	Msg("  Time Signature: " .. tostring(point.num) .. "/" .. tostring(point.denom))
	Msg("  Linear Tempo: " .. tostring(point.linear))
	Msg("  Prev Linear Tempo: " .. tostring(point.prevlinear))
	Msg("  idx: " .. tostring(point.idx))
	Msg("  Prev idx: " .. tostring(point.previdx))
	Msg("  idx Count: ".. tostring(point.idxcount))
	Msg("  pattern: ".. tostring(point.pattern))
end

function PartialMeasureDetaction(pos)
	local proj = 0
	-- 1) find the earliest TS change after pos:
	local count = reaper.CountTempoTimeSigMarkers(proj)                     -- 
	local nextTime = math.huge
	local nextMeasureIndex

	for i = 0, count - 1 do

		retval, timepos, measurepos, beatpos, bpm, ts_num, ts_den, linear = reaper.GetTempoTimeSigMarker(proj, i)

		if (ts_num > 0) and (timepos > pos) and (timepos < nextTime) then
			Msg(ts_num)
			nextTime = timepos
			nextMeasureIndex = measurepos
			nextQN = reaper.TimeMap_timeToQN_abs(proj, timepos)
			next_qn_start = reaper.TimeMap_timeToQN_abs(proj, timepos)
			break
		end
	end

	if not nextMeasureIndex then
		Msg("There is no next meter change")
		return false  -- no further meter change ⇒ treat as not partial
	else
		Msg("Found meter change at bar"..nextMeasureIndex.."time location: "..Round(nextTime))
	end

	-- -- 2) get the measure info for the bar *before* that change:
	local prevIndex = nextMeasureIndex - 1
	prev_StartTime, prev_qn_start, prev_qn_end, prev_ts_num, prev_ts_den, prev_tempo = reaper.TimeMap_GetMeasureInfo(proj, prevIndex)
	prev_qn_start = reaper.TimeMap_timeToQN_abs(proj, prev_StartTime)

	-- 4) compute how many beats
	local qt_count = roundTo((next_qn_start - prev_qn_start), 0.0625)
	Msg("beats between "..tostring(qt_count))

	if  prev_StartTime > pos and (qt_count ~= (prev_ts_num*4)/prev_ts_den) then
		adjustedpoint = GetTempoTimeSigAtPos(prev_StartTime)
		if qt_count - math.floor(qt_count) > 0 then
			denom = 4/(qt_count - math.floor(qt_count))
			num = qt_count*(denom/4)
		else
			denom = 4
			num = qt_count
		end
		-- Adjust a different measure
		Msg("\n🔵 adjustedpoint Values:")
		info(adjustedpoint)
		SetTempoTimeSig(prev_StartTime, adjustedpoint.bpm, num, denom, adjustedpoint.linear, false, adjustedpoint.idx, adjustedpoint.point)
	elseif qt_count ~= (prev_ts_num*4)/prev_ts_den then -- Ripple action
		adjustedpoint = GetTempoTimeSigAtPos(nextTime)
		Msg("\n🔵 adjustedpoint Values (Rippled):")
		info(adjustedpoint)

		-- get the measure info for the bar *after* this change:
		local nextIndexAdjusted = nextMeasureIndex+1

		nextAdjusted_StartTime, _, _, _, _, _ = reaper.TimeMap_GetMeasureInfo(proj, nextIndexAdjusted)
		Msg("nextAdjusted_StartTime: "..nextAdjusted_StartTime)
		nextadjustedpoint = GetTempoTimeSigAtPos(nextAdjusted_StartTime)
		Msg("\n🔵 nextadjustedpoint Values:")
		info(nextadjustedpoint)
		-- insert previous timesignature
		if nextadjustedpoint.num == -1 then
			if nextadjustedpoint.point then
				reaper.SetTempoTimeSigMarker(0, nextadjustedpoint.idx, nextAdjusted_StartTime, -1, -1, nextadjustedpoint.bpm, adjustedpoint.num, adjustedpoint.denom, nextadjustedpoint.linear)
			else
				reaper.AddTempoTimeSigMarker(0, nextAdjusted_StartTime, -1, adjustedpoint.num, adjustedpoint.denom, nextadjustedpoint.linear)
			end
			--restore pattern
				if adjustedpoint.pattern then
					reaper.GetSetTempoTimeSigMarkerFlag(0, nextadjustedpoint.previdx+1, 8, true)
					denom, pattern = reaper.TimeMap_GetMetronomePattern(0, nextAdjusted_StartTime, "SET:"..adjustedpoint.pattern)
				end
			--unflag tempo
			if nextadjustedpoint.bpm == -1 then
				Msg("removing bpm flag from nextadjustedpoint "..nextadjustedpoint.previdx+1)
				reaper.GetSetTempoTimeSigMarkerFlag(0, nextadjustedpoint.previdx+1, 2, false)
			end
		end

		if adjustedpoint.bpm == -1 then
			reaper.DeleteTempoTimeSigMarker(0, adjustedpoint.idx)
		else
			SetTempoTimeSig(nextTime, adjustedpoint.bpm, -1, -1, adjustedpoint.linear, false, adjustedpoint.idx, adjustedpoint.point)
		end
		PartialMeasureDetaction(pos)
	else
		Msg("No partial measure detected!")
	end

	return ((prev_ts_num/prev_ts_den)*4) - qt_count > 0
end



-- Get values safely, with robust fallbacks
function GetTempoTimeSigAtPos(pos)
	local idxcount = reaper.CountTempoTimeSigMarkers(0)
  local idx = reaper.FindTempoTimeSigMarker(0, pos+1/flux)
  local previdx = idx-1
  local retval, timepos, measurepos, beatpos, bpm, num, denom, linear = reaper.GetTempoTimeSigMarker(0, idx)
  local _, prevtimepos, _, _, prevbpm, _, _, prevlinear = reaper.GetTempoTimeSigMarker(0, idx-1)
  local retval, _, _, _, nextbpm, _, _, _ = reaper.GetTempoTimeSigMarker(0, idx+1)
  local flags = reaper.GetSetTempoTimeSigMarkerFlag(0, idx, 31, false)

  -- bit 2 = “do not set tempo”; if that bit is 0, then tempo *is* being changed
  local tempoChangeMarked = (flags & 2) == 0

  if not tempoChangeMarked then
    bpm = -1
  end

  -- bit 8 = “apply new metronome pattern”; fetch pattern only if set
  local pattern = false
  if (flags & 8) ~= 0 then
    _, pattern = reaper.TimeMap_GetMetronomePattern(0, pos + 1/flux, "EXTENDED")
  end

  
  if retval then
  	if nextbpm > 0 then
  		nextlinear = true
  	else
  		nextlinear = false
  	end
  else
  	nextlinear = false
  end


  local _, _, posbpm = reaper.TimeMap_GetTimeSigAtTime(0, pos)
  local _, _, prevposbpm = reaper.TimeMap_GetTimeSigAtTime(0, prevtimepos)
  local _, posmeasure, _, posfullbeats, _ = reaper.TimeMap2_timeToBeats(0, pos)
  _, pos_measure_qn_start, _, _, _, _ = reaper.TimeMap_GetMeasureInfo(0, posmeasure)
  posmeasurebeats =  posfullbeats - pos_measure_qn_start

  local raw = pos - timepos
	local floored = math.floor(raw * flux) / flux
	-- clamp at zero:
	local diff = math.max(floored, 0)

  if diff == 0 then
  	point = true
  else 
  	point = false
  	pattern = false
  	prevbpm = bpm
  	num = -1
  	denom = -1
  	if nextlinear and linear then
  		linear = true
  		bpm = posbpm
    else
  		linear = false
  		bpm = -1
    end
  	measurepos = posmeasure
  	beatpos = posmeasurebeats
  	timepos = pos
  	previdx = idx
  	idx = false
  end

  if beatpos < 0 then
  	beatpos = 0
  else
  	beatpos = math.floor(beatpos * 10000 + 0.5) / 10000
  end

  return {
      pos = timepos,
      idx = idx,
      previdx = previdx,
      bpm = bpm,
      num = num,
      denom = denom,
      linear = linear,
      point = point,
      prevlinear = prevlinear,
      prevbpm = prevbpm,
      posbpm = posbpm,
      idxcount = idxcount,
      nextlinear = nextlinear,
      measurepos = measurepos,
      beatpos = beatpos,
      pattern = pattern
  }
end

-- Helper: Set marker values safely
function SetTempoTimeSig(pos, bpm, num, denom, linear, prevlinear, idx, point)

    bpm = bpm or 120
    num = num or 4
    denom = denom or 4
    linear = linear or false
    if point then
	    reaper.SetTempoTimeSigMarker(0, idx, pos, -1, -1, bpm, num, denom, linear)
	    Msg("Point Modified at "..Round(pos))
		else
			reaper.AddTempoTimeSigMarker(0, pos, bpm, num, denom, linear)
			Msg("Point created at "..Round(pos))
		end


end

function script_end()
	Msg("\n🎉 Done!")
	reaper.SNM_SetIntConfigVar("tempoenvtimelock", current_lock)
	reaper.UpdateTimeline()
	reaper.UpdateArrange()
	reaper.PreventUIRefresh(-1)
	reaper.Undo_EndBlock("Smart tempo and time signature changes", -1)
	return
end

reaper.Undo_BeginBlock()


-- Reset Values
point_modified = false
point_created = false
point_removed = false
linear_handling = false


-- Capture original values
cursor_pos = reaper.GetCursorPosition()
-- Msg("\nPartial Measure detection: "..tostring(PartialMeasureDetaction(cursor_pos+1/flux)))
orig = GetTempoTimeSigAtPos(cursor_pos)
Markers_orig = getTempoMarkers()

-- Log original values
reaper.ClearConsole()
Msg("🟢 Original Values:")
info(orig)


-- Open insert tempo/time signature marker dialog
current_lock = reaper.SNM_GetIntConfigVar("tempoenvtimelock", 0)
if current_lock == 0 then 
	Msg("Timebase is set to time, bypassing script")
	reaper.Main_OnCommand(40256, 0)
	script_end()
	return
end

reaper.SNM_SetIntConfigVar("tempoenvtimelock", 0)
reaper.PreventUIRefresh(1)
reaper.Main_OnCommand(40256, 0)

-- Previous linear
linear_handling = orig.prevlinear

-- Capture new values after dialog
new = GetTempoTimeSigAtPos(cursor_pos)
Markers_new = getTempoMarkers()

-- Check change status
if orig.point then
	if orig.idxcount == new.idxcount then
		point_modified = true
	elseif new.idxcount < orig.idxcount then
		point_removed = true
	elseif orig.idxcount == 0 then -- condition where this is the first point in the session
		point_created = true
	end
else
	if orig.idxcount == new.idxcount then
		Msg("\nNo point created or modified, done!")
		Msg("point created: "..tostring(point_created))
		Msg("point modified: "..tostring(point_modified))
		Msg("point removed: "..tostring(point_removed))
		script_end()
		return
	elseif new.idxcount > orig.idxcount then
		point_created = true
	end
end

-- Print values
Msg("point created: "..tostring(point_created))
Msg("point modified: "..tostring(point_modified))
Msg("point removed: "..tostring(point_removed))

-- Capture new values if linear tempo was detected
if linear_handling then
	new_idx_search = find_insert_point(Markers_orig, Markers_new)
	Msg("\nlinear handling: "..tostring(new_idx_search))
	if new_idx_search then
	  Msg("New marker inserted before idx: "..new_idx_search.."\n")
	else
	  Msg("Comparison result: "..(new_idx_search or "no change or misalignment").."\n")
	end

	if point_modified and new_idx_search then
	    retval, timepos, _, _, bpm, num, denom, linear = reaper.GetTempoTimeSigMarker(0, new_idx_search)
		new = GetTempoTimeSigAtPos(timepos) 
	elseif point_created then
	    retval, timepos, _, _, bpm, num, denom, linear = reaper.GetTempoTimeSigMarker(0, orig.previdx+1)
		new = GetTempoTimeSigAtPos(timepos)
	end
end


-- Log new values clearly
Msg("\n🔵 New Values:")
info(new)

-- Check for changes safely
local meter_changed = (orig.num ~= new.num)
local bpm_changed = (orig.bpm ~= new.bpm) and (orig.posbpm ~= new.posbpm)
local linear_changed = (orig.linear ~= new.linear)


if (meter_changed or bpm_changed or linear_changed) then
	Msg("\n⚠️ Action: Changes detected, restoring original point")
	Msg("  Meter changed: " .. tostring(meter_changed))
	Msg("  BPM changed: " .. tostring(bpm_changed))
	Msg("  Linear tempo changed: " .. tostring(linear_changed))
	if point_removed then --restore removed point
		reaper.AddTempoTimeSigMarker(0, orig.pos, orig.bpm, orig.num, orig.denom, orig.linear)
	elseif point_modified then -- restore original values
		reaper.SetTempoTimeSigMarker(0, new.idx, -1, orig.measurepos, orig.beatpos, orig.bpm, orig.num, orig.denom, orig.linear)
	elseif point_created then -- restore previous bpm
		reaper.SetTempoTimeSigMarker(0, new.idx, -1, new.measurepos, new.beatpos, orig.bpm, -1, -1, orig.linear)
	end
else
	Msg("\n✅ Action: No changes detected")
	script_end()
	return
end

if linear_handling and not point_removed then
	new.idx = orig.previdx+1
end


if meter_changed then
	Msg("\n✅ Action: Meter changed")
	reaper.SNM_SetIntConfigVar("tempoenvtimelock", 0)
	if point_created or point_modified then
		reaper.SetTempoTimeSigMarker(0, new.idx, -1, new.measurepos, new.beatpos, orig.bpm, new.num, new.denom, orig.linear)
		new.point = true
		new.idx = reaper.FindTempoTimeSigMarker(0, new.pos)
		if new.pattern then
			reaper.GetSetTempoTimeSigMarkerFlag(0, new.idx, 8, true)
			denom, pattern = reaper.TimeMap_GetMetronomePattern(0, new.pos, "SET:"..new.pattern)
			Msg("denom: "..tostring(denom))
			Msg("pattern: "..tostring(pattern))
		end
	elseif point_removed and not bpm_changed then
		reaper.DeleteTempoTimeSigMarker(0, orig.idx)
		Msg("meter change - no bpm changed, point removed")
	else
		reaper.SetTempoTimeSigMarker(0, orig.idx, -1, new.measurepos, new.beatpos, orig.bpm, new.num, new.denom, orig.linear)
	end
	Msg("\nPartial Measure detection: "..tostring(PartialMeasureDetaction(new.pos+1/flux)))

end



if bpm_changed or linear_changed then
	Msg("\n✅ Action: Bpm changed")
	reaper.SNM_SetIntConfigVar("tempoenvtimelock", 1)
	if point_created or point_modified then
		reaper.SetTempoTimeSigMarker(0, new.idx, -1, new.measurepos, new.beatpos, new.bpm, new.num, new.denom, new.linear)
	elseif point_removed then
		reaper.DeleteTempoTimeSigMarker(0, orig.idx)
		Msg("bpm change - point removed")
	end
end



-- Clean Point

if ((orig.prevbpm == new.bpm) or new.bpm == -1) and new.point and not linear_handling and not new.linear and not point_removed and not new.pattern then
	if new.num == -1 then 
		Msg("\n✅ Action: Deleted Point")
		reaper.DeleteTempoTimeSigMarker(0, new.idx)
	else
		Msg("\n✅ Action: Cleaned Point")
		reaper.SetTempoTimeSigMarker(0, new.idx, -1, new.measurepos, new.beatpos, -1, new.num, new.denom, false)
	end
end


script_end()


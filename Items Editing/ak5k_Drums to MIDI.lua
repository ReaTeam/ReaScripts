-- @description Drums to MIDI
-- @author ak5k
-- @version 0.1.1
-- @changelog bug fix related to items with no transients
-- @link Forum thread https://forum.cockos.com/showthread.php?t=252626
-- @about Creates General MIDI drum notes from transients based on tone in selected items or Razor Edit area. See [website](https://forum.cockos.com/showthread.php?t=252626) for more information.

groove_extraction_mode = false
  --a mode for extracting groove
  --overrides some of the settings below

retrigger_interval = 90
  --in ppqs, 1/4 norm to 960
  --e.g. 1/32 is 120
chan = 10
  --insert channel
vel = 100
  --insert velocity
vel_sensitivity = true
  --detect velocity from transients
  --overrides vel
vel_threshold = -48 --dBFS
  --fixed peak level threshold for MIDI velocity 1
  --set 0 for Transient Detection threshold
multitrack_mode = true
  --discrete output tracks for drum types
tone_per_transient = false
  --detected tone from each transient
average_tones = false
  --use mean average from detected tones

transient = 0.03 -- seconds
kicksnare_crossover = 120 --hz
delete_empty_tracks = true
  --deletes previously created empty destination tracks
clear_transient_guides = true

-------------------------------------------------------------------------------
local reaper = reaper
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)

single_track_mode = not multitrack_mode
local tracks = {}
local items = {}
local razor
local orig, item_deletes = {}, {}
local takes = {}
local chunk_cache = {}
local toms = false
local flip = false
local ext_name = "ak5k_Drums to MIDI"

--get drum "type" from frequency
local function get_drum_type(freq)
  local freq = freq
  if toms == true then
    if freq < 73.9 then return "t1" end --41
    if freq < 93.2 then return "t2" end --43
    if freq < 117.5 then return "t3" end --45
    if freq < 148 then return "t4" end -- 47
    if freq < 186.5 then return "t5" end --48
    return "t6" --50
  end
  if freq < kicksnare_crossover then return "k" end --36
  return "s" --38
end

--get MIDI note for drum type
local function get_drum_note(drum)
  local note
  if drum == "t1" then note = 41 end
  if drum == "t2" then note = 43 end
  if drum == "t3" then note = 45 end
  if drum == "t4" then note = 47 end
  if drum == "t5" then note = 48 end
  if drum == "t6" then note = 50 end
  if drum == "k" then note = 36 end
  if drum == "s" then note = 38 end
  if groove_extraction_mode then
    note = 36
  end
  return note
end

local function GetMediaItemTakeGUID(take)
  local take = take
  if not take then return nil end
  local retval, res = reaper.GetSetMediaItemTakeInfo_String(take, "GUID", "", false)
  if not retval then return nil end
  return reaper.guidToString(res, "")
end

local function list_to_csv(list)
  local res = {}
  local i = 1
  for k, v in pairs(list) do
    res[i] = v -- .. "," .. tostring(v)
    i = i + 1
  end
  return table.concat(res, ",")
end

local function csv_to_list(csv)
  local res = {}
  if csv == "" then return res end
  for k in string.gmatch(csv, '[^,]+') do
    res[k] = true
  end
  return res
end

local function table_len(t)
  if not t then return nil end
  local res = 0
  for _ in pairs(t) do
    res = res + 1
  end
  return res
end

local peak_buf
local function get_peak_level(take, pos)
  local pos = pos
  local abs, ceil, log, max = math.abs, math.ceil, math.log, math.max
  
  --peak_buf.clear()
  local source = reaper.GetMediaItemTake_Source(take)
  local samplerate = reaper.GetMediaSourceSampleRate(source)
  peakrate = 1/transient
  peak_buf = peak_buf or reaper.new_array(2)
  local retval = nil
  local n = 0
  while not retval and n < 8 do
    --retval = reaper.PCM_Source_GetPeaks(source, samplerate*transient*2, pos, 1, 1, 0, peak_buf)
    retval = reaper.GetMediaItemTake_Peaks(take, peakrate, pos, 1, 1, 0, peak_buf)
    n = n + 1
  end
  if not retval then return 0 end
  local peaks = peak_buf.table()
  peaks[2] = -1*peaks[2]
  local peak = max(peaks[1], peaks[2])
  peak = 20*log(peak,10)
  return peak
end

local function HannWindow(size)
  local pi = math.pi
  local cos = math.cos
  local t = {}
  local adj = size % 2 == 0 and 1 or 0
  local mid = math.ceil( size/2 )
  size = size-1
  for i = 0, mid-1 do
    t[i+1] = .5*(1-cos(2*pi*i/size))
  end
  for i = 0, mid do
    t[mid+i+adj] = t[mid-i]
  end
  return t
end

local window
local function analyze(take, pos)
  local reaper = reaper
  local take = take
  local maxv, bin, freq, filter_val, factor
  local pos = pos
  local pi = math.pi
  local ceil, log, max = math.ceil, math.log, math.max
  local cutoff = 300
  local numchannels = 1
  local size = 1024
  if toms then
    size = size*4
  end
  
  local source = reaper.GetMediaItemTake_Source(take)
  local samplerate = reaper.GetMediaSourceSampleRate(source)
  
  local scale = ceil(samplerate/48000)
  size = scale * size
  
  local item = reaper.GetMediaItemTake_Item(take)
  local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  local starttime_sec = pos - offset + transient

  samplebuffer = samplebuffer or reaper.new_array(4*size)
  samplebuffer.clear()
  
  local n = 0
  local retval = nil
  while not retval and n < 8 do
    retval = reaper.PCM_Source_GetPeaks(source, samplerate, pos+transient, 1, 2*size, 0, samplebuffer)
    n = n + 1
  end

  local temp = samplebuffer.table(1, 2*size)
  samplebuffer.clear(0, 2*size+1)
  
  if retval < 1 then return nil end
  
  --"zero crossing"
  
  --[[
  n = 1
  while temp[n] > 0 do
    temp[n] = 0
    n = n + 1
  end
  n = n + 1
  while temp[n] < 0 do
    temp[n] = 0
    n = n + 1
  end
  n = #temp/2
  while temp[n] > 0 do
    temp[n] = 0
    n = n - 1
  end
  n = n - 1
  while temp[n] < 0 do
    temp[n] = 0
    n = n - 1
  end
  ]]--
  local lp_cut = 2 * pi * cutoff
  local lp_n = 1 / (lp_cut + 3*samplerate)
  local lp_b1 = (3*samplerate - lp_cut) * lp_n
  local lp_a0 = lp_cut * lp_n

  local lp_out
  for i, sp in ipairs(temp) do
    lp_out = 2*sp * lp_a0 + (lp_out or 0) * lp_b1
    temp[i] = lp_out
  end
  
  window = window or HannWindow(#temp)
  
  for i = 1, #temp do
    temp[i] = temp[i] * window[i]
  end
  
  samplebuffer.copy(temp)
  samplebuffer.fft_real(size, true)
  
  temp = samplebuffer.table(1, size)
  
  for i = 1, #temp/2 do
    local re = temp[i*2-1]
    local im = temp[i*2]
    temp[i*2], temp[i*2-1] = nil, nil
    temp[i] = re^2+im^2
  end
  
  temp[0] = 0
  
  for i = 1, #temp do
    local v = temp[i]
    bin = bin or 1
    maxv = maxv or v
    if v > maxv then 
      bin = i
      maxv = v
    end
  end
  freq = (bin-1) * samplerate / size
  return freq
  
end

local function get_tm_positions(item, pos, end_pos)
  --local reaper = reaper
  if not item then return nil end
  
  local item = item
  local n = 1
  local res = {}
  local tms = {}
  local temp = nil
  local floor = math.floor
  local sqrt = math.sqrt
  
  local retval, chunk
  if not chunk_cache[item] then
    retval, chunk = reaper.GetItemStateChunk(item, "", false)
    chunk_cache[item] = chunk
  else
    chunk = chunk_cache[item]
  end
  if not chunk then return nil end
  
  local take = reaper.GetActiveTake(item)
  local offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  
  local pos = pos or reaper.GetMediaItemInfo_Value(item, "D_POSITION")

  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local end_pos = len + pos
  local take_num = reaper.GetMediaItemTakeInfo_Value(take, "IP_TAKENUMBER") + 1
  local play_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  
  res = {}
  for section in chunk:gmatch("TMINFO%s(.-)>") do
      res[1] = tonumber(section:match("(%d+)"))
      res[2] = {}
      for line in section:gmatch("TM%s(.-)\n") do
        for substring in line:gmatch("%S+") do
          res[2][#res[2]+1] = tonumber(substring)
        end
      end
  end
  
  
  if not res[1] then return {} end
   
  local samplerate = res[1]
  
  tms = res[2]
  
  n = 1
  for i, tm in ipairs(tms) do
    tms[i] = tm/samplerate + (tms[i-1] or 0)
  end
  
  
  n = 1
  for i, tm in ipairs(tms) do
    tms[i] = nil
    local tm_orig = tm
    tm = tm - offset
    if tm > 0 then
      tms[n] = {}
      tms[n][1] = tm_orig
      tms[n][2] = tm
      n = n + 1
    end
  end
  
  local stm_num = reaper.GetTakeNumStretchMarkers(take)
  if stm_num > 0 then
    stm_hash = stm_hash or {}
    for i, tm in ipairs(tms) do
      tms[i][2] = -1
      tm = tms[i][1]
      for j = 0, stm_num-1 do
        retval1, stm_pos1, src_pos1 = reaper.GetTakeStretchMarker(take, j)
        retval2, stm_pos2, src_pos2 = reaper.GetTakeStretchMarker(take, j+1)
        
        --src_pos1 = src_pos1 -- offset
        --src_pos2 = src_pos2 -- offset
        
        if retval1 == -1 or 
          retval2 == -1 then
         goto next_stm
        end

        if tm >= src_pos1 and tm <= src_pos2 then
          
          --[[
          stretch marker physics
          
          x = source time position
          t = stretched time position
          v = velocity
          v1 = initial velocity
          v2 = final velocity
          v_avg = average velocity (the average/overall stretch for segment)
          a = acceleration, or rate of change in velocity (or 'k')
          
          velocity is the playback speed
          0.5 is half speed, 2 is double speed and so on
          
          common physics equations for
          one dimensional motion with constant acceleration:
          
          find source time position x from stretched time position t
          x = x0 + v1*t+0.5*a*t^2           
            -- (starting point displacement x0 is here considered 0 and left out)
            -- each stretch marker by itself serves as the point zero
          
          find stretched time position t from source time position x
            -- or previous equation solved for t
          t = ((2*a*x+v1^2)^(0.5) - v1) / a -- (negative/double root -t always ruled out)
            -- the amount of 'stretched timeline time' needed to reach point x in source time 
          ]]--
          
          x = tm - src_pos1 -- target position in source
          v_avg = (src_pos2-src_pos1)/(stm_pos2-stm_pos1) 
            -- average velocity over stretched segment (or the overall time stretch/compression ratio)
          
          --assuming slope is the variance of y in visual slope
          slope = reaper.GetTakeStretchMarkerSlope(take, j)
          v1 = v_avg-(v_avg*slope) -- initial velocity
          v2 = v_avg+(v_avg*slope) -- final velocity
          
          a = (v2-v1)/(stm_pos2-stm_pos1) 
            -- k = (y_2 - y_1 / (x_2 - x_1)
            -- constant rate of acceleration over stretched segment (the 'k' of the visual slope)
            
          if a == 0 then -- no acceleration/stretching, scale to average (constant) velocity
            t = x / v_avg 
          else --find 'stretched' time t to 'reach' position x in source (with acceleration)
            t = ((2*a*x+v1^2)^(0.5) - v1) / a -- ^0.5 as in square root
          end
          
          local new_pos = t + stm_pos1
          
          tms[i][2] = new_pos
        end
        ::next_stm::
      end
      ::continue_to_next_tm::
    end
    for i = #tms, 1, -1 do
      if tms[i][2] == -1 then
        table.remove(tms, i)
      end
    end
  end
  
  for i, tm in ipairs(tms) do
    tm = tm[2]
    tm = tm / play_rate
    if tm > len then
      tms[i] = nil
    else
      tms[i][2] = tm + pos
      tms[i][4] = -1 --velocity
    end
  end
  
  if #tms > 0 then
  if average_tones or tone_per_transient then
    for i, tm in ipairs(tms) do
      tms[i][3] = analyze(take, tm[1])
    end
    if average_tones and #tms > 0 then
      local sum, avg
      for i, tm in ipairs(tms) do
        sum = (sum or 0) + tm[3]
      end
      avg = sum / #tms
      for i, tm in ipairs(tms) do
        tms[i][3] = avg
      end
    end
  else
    local freq = analyze(take, tms[#tms][1])
    for i, tm in ipairs(tms) do
      tms[i][3] = freq
    end
  end
  
  if vel_sensitivity then
    for i, tm in ipairs(tms) do
      tms[i][4] = get_peak_level(take, tm[2])
    end
  end
  end
  
  res[2][0] = nil
  
  if #res[2] == 0 then return nil end
  
  return res[2]
end

local function compare_takes(takes)
  local takes = takes
  local res = true
  local retval, prev_takes = reaper.GetProjExtState(0, ext_name, "takes")
  local prev_takes = csv_to_list(prev_takes)
  local razor_temp = {}
  
  if razor then
    local n = 1
    local retval, prev_razor = reaper.GetProjExtState(0, ext_name, "prev_razor")
    for i, razor_edits in ipairs(razor) do
      local tr = razor_edits[1]
      local razor_edits = razor_edits[2]
      local tr_guid = reaper.GetTrackGUID(tr)
      for j, razor_edit in ipairs(razor_edits) do
        local pos = razor_edit[1]
        local end_pos = razor_edit[2]
        local env = razor_edit[3]
        razor_temp[n] = tr_guid .. pos .. end_pos
        n = n + 1
      end
    end
    razor_temp = table.concat(razor_temp) or ""
    if razor_temp ~= prev_razor then
      res = false
    end
  else
    for take, guid in pairs(takes) do
      if not prev_takes[guid] then
        res = false
      end
    end
    if table_len(takes) ~= table_len(prev_takes) then
      res = false
    end
  end
  
  if not res then
    if razor then
      reaper.SetProjExtState(0, ext_name, "prev_razor", razor_temp)
    end
    reaper.SetProjExtState(0, ext_name, "takes", list_to_csv(takes))
    reaper.SetProjExtState(0, ext_name, "flip", "0")
    flip = false
  end
  
  retval, flip = reaper.GetProjExtState(0, ext_name, "flip")
  if res and retval and not toms then
    if flip == "0" then
      toms = true
      reaper.SetProjExtState(0, ext_name, "flip", "1")
    end
    if flip == "1" then
      toms = false
      reaper.SetProjExtState(0, ext_name, "flip", "0")
    end
    flip = true
  end
  
  return res
end

local function get_dest_track(drum)
  local retval, guid = reaper.GetProjExtState(0, ext_name, drum)
  local res = nil
  local name = drum .. "_Drums to MIDI"
  if not multitrack_mode then name = "Drums to MIDI" end
  if groove_extraction_mode then
    name = "Groove Track"
    for i = 0, reaper.CountSelectedTracks(0) -1 do
      local tr = reaper.GetSelectedTrack(0, i)
      if not tracks[tr] then
        return tr
      end
    end
  end
  for i = 0, reaper.GetNumTracks() -1 do
    local tr = reaper.GetTrack(0, i)
    local tr_guid = reaper.GetTrackGUID(tr)
    if tr_guid == guid then
      res = tr
    end
  end
  if not res then
    reaper.InsertTrackAtIndex(reaper.GetNumTracks(), false)
    res = reaper.GetTrack(0, reaper.GetNumTracks() -1)
    reaper.SetProjExtState(0, ext_name, drum, reaper.GetTrackGUID(res))
    reaper.GetSetMediaTrackInfo_String(res, "P_NAME", name, true)
  end
  return res
end

local function second_pass(pos, freq)
  if not pos or not freq then return nil end
  local midi_item
  local abs = math.abs
  toms = not toms
  local drum = get_drum_type(freq)
  if not multitrack_mode then drum = "k" end
  local dest = get_dest_track(drum)

  for i = reaper.GetTrackNumMediaItems(dest) -1, 0, -1 do
    local item = reaper.GetTrackMediaItem(dest, i)
    local midi_take = reaper.GetActiveTake(item)
    local interval = reaper.MIDI_GetProjTimeFromPPQPos(
      midi_take, retrigger_interval) - reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    if abs(reaper.GetMediaItemInfo_Value(item, "D_POSITION") - pos) < interval then
      reaper.DeleteTrackMediaItem(dest, item)
    end
  end

  toms = not toms
end

local function clean_up(tms)
  --delete temp razor items
  if razor then
    for item, _ in pairs(item_deletes) do
     reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(item), item)
    end
  end
  
  --set original items selected
  for item, _ in pairs(orig) do
    reaper.SetMediaItemSelected(item, true)
  end
  
  --clear transient guide markers
  if clear_transient_guides == true then
    reaper.Main_OnCommandEx(42027, 0, 0)
  end
  
  --set item size in single track mode
  --set MIDI item selected
  if not multitrack_mode and #items > 0 and tms and #tms > 0 then
    local tr = get_dest_track("k")
    local item = reaper.GetTrackMediaItem(tr, 0)
    
    if not item then
      goto end_single_clean
    end
    local take = reaper.GetActiveTake(item)
    reaper.MIDI_Sort(take)
    local retval, notecnt = reaper.MIDI_CountEvts(take)
    local retval, _, _, startppqpos, _, _= reaper.MIDI_GetNote(take, 0)
    local retval, _, _, _, endppqpos, _= reaper.MIDI_GetNote(take, notecnt -1)
    local pos = reaper.MIDI_GetProjTimeFromPPQPos(take, startppqpos)
    local end_pos = reaper.MIDI_GetProjTimeFromPPQPos(take, endppqpos)
    local len = end_pos - pos
    local max, min
    for i, item in ipairs(items) do
      min = min or pos
      max = max or end_pos
      if item[2] < min then
        min = item[2]
      end
      if item[3] > max then
        max = item[3]
      end
    end
    pos = min
    len = max - pos
    reaper.SetMediaItemInfo_Value(item, "D_POSITION", pos)
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", len)
    reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", pos)
    reaper.SelectAllMediaItems(0,false)
    reaper.SetMediaItemSelected(item, true)
    reaper.SetOnlyTrackSelected(tr)
    ::end_single_clean::
  end
  
  local drums = {"k", "s", "t1", "t2", "t3", "t4", "t5", "t6"}
  
  --delete empty tracks
  --in multitrack, if item pos difference < 0.01 seconds, delete latter
  --in multitrack, consolidate midi note pitches to corresponding Drums To MIDI tracks
  for i, drum in ipairs(drums) do
    local retval, guid = reaper.GetProjExtState(0, ext_name, drum)
    for i = reaper.GetNumTracks() -1, 0, -1 do
      local tr = reaper.GetTrack(0, i)
      local tr_guid = reaper.GetTrackGUID(tr)
      if tr_guid == guid then
        local note = get_drum_note(drum)
        if multitrack_mode and not tms then
          for j = reaper.CountTrackMediaItems(tr) -1, 0 , -1 do
            local it = reaper.GetTrackMediaItem(tr, j)
            if j ~= 0 then
              local it_prev = reaper.GetTrackMediaItem(tr, j-1)
              local pos = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
              local pos_prev = reaper.GetMediaItemInfo_Value(it_prev, "D_POSITION")
              if pos - pos_prev < transient/3 then
                reaper.DeleteTrackMediaItem(tr, it)
                goto next_item
              end
            end
            local tk = reaper.GetActiveTake(it)
            if reaper.TakeIsMIDI(tk) then
              local retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(tk)
              for k = notecnt -1, 0, -1 do
                local retval, selected, muted, startppqpos, endppqpos, note_chan, pitch, vel = reaper.MIDI_GetNote(tk, k)
                if pitch ~= note then
                  reaper.MIDI_SetNote(tk, k, nil, nil, nil, nil, nil, note)
                end
              end
            end
            ::next_item::
          end
        end
        if reaper.GetTrackNumMediaItems(tr) == 0 and 
          delete_empty_tracks == true then
          reaper.DeleteTrack(tr) 
        end
      end
    end
  end
  
end

local groove_item
local function single_track_midi_item(dest)
  local dest = dest
  local res 
  local num_items = reaper.GetTrackNumMediaItems(dest)
  if groove_extraction_mode then
    groove_item = groove_item or reaper.CreateNewMIDIItemInProj(dest, 0, 0.1, false)
    res = groove_item
    local midi_take = reaper.GetActiveTake(res)
    reaper.SetMediaItemTakeInfo_Value(midi_take, "D_STARTOFFS", 0)
    reaper.SetMediaItemInfo_Value(res, "B_LOOPSRC", 0)
    reaper.SetMediaItemInfo_Value(res, "D_POSITION", 0)
    reaper.SetMediaItemInfo_Value(res, "D_LENGTH", reaper.GetProjectLength(0))
    reaper.MIDI_DisableSort(midi_take)
    return res
  end
  if num_items > 1 then
    reaper.SelectAllMediaItems(0, false)
    for i = num_items -1, 1, -1 do
      local item = reaper.GetTrackMediaItem(dest, i)
      res = reaper.SetMediaItemSelected(item, true)
    end
    reaper.Main_OnCommandEx(42432, 0, 0)
    res = reaper.GetTrackMediaItem(dest, 0)
  end
  if num_items == 1 then
    res = reaper.GetTrackMediaItem(dest, 0)
  end
  if num_items == 0 then
    res = reaper.CreateNewMIDIItemInProj(dest, 0, 0.1, false)
  end
  if res then
    local midi_take = reaper.GetActiveTake(res)
    reaper.SetMediaItemTakeInfo_Value(midi_take, "D_STARTOFFS", 0)
    reaper.SetMediaItemInfo_Value(res, "B_LOOPSRC", 0)
    reaper.SetMediaItemInfo_Value(res, "D_POSITION", 0)
    reaper.SetMediaItemInfo_Value(res, "D_LENGTH", reaper.GetProjectLength(0))
    reaper.MIDI_DisableSort(midi_take)
  end
  return res
end

local _, threshold = reaper.get_config_var_string("transientthreshold")
threshold = tonumber(threshold)
local _, sensitivity = reaper.get_config_var_string("transientsensitivity")
sensitivity = tonumber(sensitivity)
local function get_note_velocity(peak)
  if not peak then return 64 end
  local floor, max, min = math.floor, math.max, math.min
  local vel
  if not (vel_threshold < 0) then
    vel_threshold = threshold
  end
  local k = -127 / vel_threshold--*3/4
  vel = k*peak + 127
  --vel = vel * (sensitivity+0.5)
  vel = max(vel, 1)
  
  vel = min(vel, 127)
  vel = floor(vel)
  return vel
end

local _, ppq = reaper.get_config_var_string("miditicksperbeat")
ppq = tonumber(ppq) or 960
retrigger_interval = retrigger_interval * ppq / 960
local function insert_midi_note(pos, freq, peak)
  if not pos or not freq then return nil end
  local abs = math.abs
  local midi_item
  local midi_take
  local midi_pos = 0
  local midi_end_pos
  local interval = nil
  local peak = peak
  local drum = get_drum_type(freq)
  local note = get_drum_note(drum)
  
  if not multitrack_mode then drum = "k" end
  local dest = get_dest_track(drum)
  
  if not multitrack_mode then
    midi_item = single_track_midi_item(dest)
    midi_take = reaper.GetActiveTake(midi_item)
    midi_pos = reaper.MIDI_GetPPQPosFromProjTime(midi_take, pos)
  end
  
  if not midi_item then
    midi_item = reaper.CreateNewMIDIItemInProj(dest, pos, pos+0.1, false)
    midi_take = reaper.GetActiveTake(midi_item)
    local end_pos = reaper.MIDI_GetProjTimeFromPPQPos(midi_take, 240*ppq/960)
    reaper.SetMediaItemInfo_Value(midi_item, "D_LENGTH", end_pos - pos)
  end
  
  midi_take = reaper.GetActiveTake(midi_item)
  midi_end_pos = reaper.MIDI_GetPPQPosFromProjTime(midi_take, pos)
  midi_end_pos = midi_end_pos + 180*ppq/960
  
  local vel = vel
  if vel_sensitivity then
    vel = get_note_velocity(peak)
  end
  
  reaper.MIDI_InsertNote(
    midi_take, 
    false, 
    false, 
    midi_pos, 
    midi_end_pos, 
    chan, 
    note, 
    vel,
    not multitrack_mode)
    
  --reaper.MIDI_Sort(midi_take)
end

local function parse_razor(buf)
  if not buf then return nil end
  local buf = buf
  local res = {}
  local i, j = 1, 1
  for w in buf:gmatch("%S+") do
    res[i] = res[i] or {}
    res[i][j] = res[i][j] or {}
    res[i][j] = tonumber(w) or w
    j = j + 1
    if j == 4 then 
      res[i][j-1] = w:match('%"(.-)%"') or ""
      j = 1
      i = i + 1
    end
  end
  if i == 1 then return nil end
  return res
end

local function get_razor()
  local res = {}
  local tr
  local buf = ""
  local retval
  local n = 1
  for i = 0, reaper.GetNumTracks() -1 do
    tr = reaper.GetTrack(0, i)
    retval, buf = reaper.GetSetMediaTrackInfo_String(tr, "P_RAZOREDITS", buf, false)
    if retval and buf ~= "" then
      res[n] = {tr, parse_razor(buf)}
      n = n + 1
    end
  end
  if n == 1 then return nil end
  return res
end

local function get_razor_items(tr, parsed_razor)
  if not tr or not parsed_razor then return nil end
  local tr = tr
  local parsed_razor = parsed_razor
  local res = {}
  local n = 1
  for i = 0, reaper.CountTrackMediaItems(tr) -1 do
    local item = reaper.GetTrackMediaItem(tr, i)
    local take = reaper.GetActiveTake(item)
    local source = reaper.GetMediaItemTake_Source(take)
    local typebuf = ""
    local typebuf = reaper.GetMediaSourceType(source, typebuf)
    if typebuf == "MIDI" then
      goto continue_loop
    end
  
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local end_pos = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") + pos
    for i = #parsed_razor, 1, -1 do
      local rz_edit = parsed_razor[i]
      if not (pos <= rz_edit[1] and end_pos <= rz_edit[1] or
        pos >= rz_edit[2] and end_pos >= rz_edit[2]) or 
        pos > rz_edit[1] and pos < rz_edit[2] or 
        end_pos > rz_edit[1] and end_pos < rz_edit[2] then
        res[n] = {}
        res[n] = {item, rz_edit[1], rz_edit[2]}
        orig[item] = true
        n = n + 1
      end
    end
    ::continue_loop::
  end
  if n == 1 then return nil end
  return res
end

local function get_razor_transient_items(razor)
  if not razor then return nil end
  local razor = razor
  local res = {}
  local orig = {}
  local n = 1
  local razor_items = nil
  local item
  local item_count = reaper.CountSelectedMediaItems(0)
  
  for i = item_count -1, 0, -1 do
    item = reaper.GetSelectedMediaItem(0, i)
    reaper.SetMediaItemSelected(item, false)
    orig[item] = true
  end
  
  for _, track_rz in ipairs(razor) do
    local tr = track_rz[1]
    for i = 0, reaper.CountTrackMediaItems(tr) -1 do
      local item = reaper.GetTrackMediaItem(tr, i)
      if reaper.GetMediaItemInfo_Value(item, "B_UISEL") ~= 1 then
        orig[item] = true
      end
    end
    local parsed_razor = track_rz[2]
    local razor_items = get_razor_items(tr, parsed_razor)
    if razor_items then
      for _, razor_item in ipairs(razor_items) do
        local item = razor_item[1]
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local take = reaper.GetActiveTake(item)
        local offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
        local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
        local end_pos = pos + len
        local new_pos = razor_item[2]
        local new_end_pos = razor_item[3]
        
        if pos > new_pos then new_pos = pos end
        
        if pos < new_pos then
          offset = offset + (new_pos - pos)
        end
        
        if end_pos > new_end_pos then
          len = new_end_pos - new_pos
        end
        
        if end_pos - new_pos < new_end_pos - new_pos then
          len = end_pos - new_pos
        end

        local retval, chunk = reaper.GetItemStateChunk(item, "", false)
        if not retval then return nil end
        local new_item = reaper.AddMediaItemToTrack(tr)
        
        retval = reaper.SetItemStateChunk(new_item, chunk, false)
        if not retval then
          reaper.DeleteTrackMediaItem(tr, item)
          return nil
        end
        
        if pos < new_pos then
          local temp_item = new_item
          new_item = reaper.SplitMediaItem(new_item, new_pos)
          reaper.DeleteTrackMediaItem(reaper.GetMediaItem_Track(temp_item), temp_item)
        end
        
        reaper.SetMediaItemInfo_Value(new_item, "D_LENGTH", len)
        take = reaper.GetActiveTake(new_item)
        reaper.SetMediaItemSelected(new_item, true)
        res[n] = {new_item, new_pos, new_end_pos}
        item_deletes[new_item] = true
        n = n + 1
      end
    end
  end
  
  if n == 1 then return nil, nil end
  return res
end

note_cache = {}
local function set_tr_note_cache(tr, tms)
  if not tr or not tms then return nil end
  local note_cache = note_cache or {}
  for i = 0, reaper.CountTrackMediaItems(tr) -1 do
    local it = reaper.GetTrackMediaItem(tr, i)
    local pos = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
    local len = reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
    local end_pos = pos + len
    
    if end_pos < tms[1][2] or
      pos > tms[#tms][2] then
      goto next_item
    end
    
    local tk = reaper.GetActiveTake(it)
    local offset = reaper.GetMediaItemTakeInfo_Value(tk, "D_STARTOFFS")
    local ppq0 = reaper.TimeMap2_timeToQN(0,pos-offset)*ppq
    
    if reaper.TakeIsMIDI(tk) then
      local retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(tk)
      
      for j = 0, notecnt -1 do
        local retval, selected, muted, startppqpos, endppqpos, note_chan, pitch, vel = reaper.MIDI_GetNote(tk, j)
        if note_chan == chan then
          note_cache[tr] = note_cache[tr] or {}
          --local starttime = reaper.MIDI_GetProjTimeFromPPQPos(tk, startppqpos)
          startppqpos = ppq0 + startppqpos
          note_cache[tr][#note_cache[tr]+1] = {startppqpos, pitch, it, tk, j}
        end
      end
    end
    ::next_item::
  end
  return note_cache[tr]
end

local duplicates = {}
local function check_duplicates(tms)
  if not tms then return nil end
  local tms = tms
  local abs, remove = math.abs, table.remove
  local duplicates = duplicates
  
  --set previous matching kick/snare or tom to be deleted
  if flip == true then
    toms = not toms
    
    for i = #tms, 1, -1 do
      local tm = tms[i]
      local pos, freq = tm[2], tm[3]
      local drum = get_drum_type(freq)
      local note = get_drum_note(drum)
      if not multitrack_mode then drum = "k" end
      local dest = get_dest_track(drum)
        
      local tr = dest
      note_cache[tr] = note_cache[tr] or set_tr_note_cache(tr, tms)
      if note_cache[tr] then
        for j = #note_cache[tr], 1, -1 do
          local cache_note = note_cache[tr][j]
          local cache_ppqpos, cache_note, cache_it, cache_tk, cache_idx = 
            cache_note[1], cache_note[2], cache_note[3], cache_note[4], cache_note[5]
            
          --local cache_projpos = reaper.MIDI_GetProjTimeFromPPQPos(cache_tk, cache_pos)
          --local retrigger_projpos = reaper.MIDI_GetProjTimeFromPPQPos(cache_tk, cache_pos + retrigger_interval)
          --local interval = retrigger_projpos - cache_projpos + 0.001
          local ppqpos = reaper.TimeMap2_timeToQN(0, pos)*ppq
          if abs(cache_ppqpos - ppqpos) < retrigger_interval and cache_note == note then
            remove(note_cache[tr], j)
            duplicates[cache_tk] = duplicates[cache_tk] or {}
            duplicates[cache_tk][#duplicates[cache_tk]+1] = cache_idx
          end
        end
      end
    end
    toms = not toms
  end
  
  local retriggers = {}
  
  local n = 2
  while n <= #tms do
    local pos, next_pos = tms[n-1][2], tms[n][2]
    pos = reaper.TimeMap2_timeToQN(0, pos) * ppq
    next_pos = reaper.TimeMap2_timeToQN(0, next_pos) * ppq
    while abs(next_pos - pos) < retrigger_interval and n < #tms do
      retriggers[#retriggers+1] = n
      n = n + 1
      next_pos = tms[n][2]
      next_pos = reaper.TimeMap2_timeToQN(0, next_pos) * ppq
    end
    n = n + 1
  end
  
  for i = #retriggers, 1, -1 do
    remove(tms, retriggers[i])
  end
  
  --if a note already exists, remove it from from 'to do' list
  for i = #tms, 1, -1 do
    local tm = tms[i]
    local pos, freq = tm[2], tm[3]
    local drum = get_drum_type(freq)
    local note = get_drum_note(drum)
    if not multitrack_mode then drum = "k" end
    local dest = get_dest_track(drum)
    
    local tr = dest
    note_cache[tr] = note_cache[tr] or set_tr_note_cache(tr, tms)
    if note_cache[tr] then
      for j = #note_cache[tr], 1, -1 do
        local cache_note = note_cache[tr][j]
        local cache_ppqpos, cache_note, cache_it, cache_tk, cache_idx = 
          cache_note[1], cache_note[2], cache_note[3], cache_note[4], cache_note[5]
        
        --local cache_projpos = reaper.MIDI_GetProjTimeFromPPQPos(cache_tk, cache_pos)
        --local retrigger_projpos = reaper.MIDI_GetProjTimeFromPPQPos(cache_tk, cache_pos + retrigger_interval)
        --local interval = retrigger_projpos - cache_projpos + 0.001
        local ppqpos = reaper.TimeMap2_timeToQN(0, pos)*ppq
        if abs(cache_ppqpos - ppqpos) < retrigger_interval and cache_note == note then
          remove(tms, i)
        end
      end
    end
  end
  
  return tms
end

local function delete_duplicates()
  local sort = table.sort
  for cache_tk, idx_list in pairs(duplicates) do
    sort(idx_list)
    for i = #idx_list, 1, -1 do
      reaper.MIDI_DeleteNote(cache_tk, idx_list[i])
    end
    local retval, notecnt = reaper.MIDI_CountEvts(cache_tk)
    if notecnt == 0 then
      local it = reaper.GetMediaItemTake_Item(cache_tk)
      reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(it), it)
    end
  end
end

-------------------------------------------------------------------------------


local retval, desc = reaper.GetAudioDeviceInfo("MODE", "")

if not retval then return end

if groove_extraction_mode then
  vel_sensitivity = true
  vel_threshold = 0
  multitrack_mode = false
  tone_per_transient = false
  average_tones = false
  retrigger_interval = 30
end

razor = get_razor()
items = get_razor_transient_items(razor)
if not items then
  razor = nil
  items = nil
end

if not items then
  items = {}
  local item_count = reaper.CountSelectedMediaItems(0)
  for i = 1, item_count do
    items[i] = {}
    items[i][1] = reaper.GetSelectedMediaItem(0, i -1)
    items[i][2] = reaper.GetMediaItemInfo_Value(items[i][1], "D_POSITION")
    items[i][3] = reaper.GetMediaItemInfo_Value(items[i][1], "D_LENGTH") + items[i][2]
  end
end

for i = #items, 1, -1 do
  local item = items[i][1]
  local take = reaper.GetActiveTake(item)
  if reaper.TakeIsMIDI(take) then
    table.remove(items, i)
  else
    takes[take] = GetMediaItemTakeGUID(take)
    tracks[reaper.GetMediaItemTrack(item)] = i
  end
end

if table_len(tracks) > 1 then 
  toms = true 
end

if table_len(tracks) == 2 then
  local n = 1
  for tr, _ in pairs(tracks) do
    local _, tr_name = reaper.GetTrackName(tr)
    tr_name = string.sub(tr_name, 1, 1)
    tr_name = string.lower(tr_name)
    if tr_name == "b" or
      tr_name == "k" or
      tr_name == "s" then
      n = n + 1
    end
  end
  if n == 3 then toms = false end
end

local function main()
  
  reaper.Main_OnCommandEx(42029, 0, 0)
  compare_takes(takes)
  local tms = nil
  for i, item in ipairs(items) do
  
    pos = item[2]
    end_pos = item[3]
    item = item[1]
    tms = get_tm_positions(item, pos, end_pos)
    
    if tms then
      tms = check_duplicates(tms)
      for i, tm in ipairs(tms) do
        local pos, freq, peak = tm[2], tm[3], tm[4]
        insert_midi_note(pos, freq, peak)
      end
    end
    
  end

  delete_duplicates()
  clean_up(tms)

end

main()

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock2(0, "Drums to MIDI", -1)
reaper.UpdateArrange()



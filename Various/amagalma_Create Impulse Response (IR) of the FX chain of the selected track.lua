-- @description amagalma_Create Impulse Response (IR) of the FX Chain of the selected Track
-- @author amagalma
-- @version 1.34
-- @about
--  # Creates an impulse response (IR) of the FX Chain of the first selected track.
--  - You can define:
--  - the peak value of the normalization,
--  - the number of channels of the IR (mono or stereo),
--  - the maximum IR length (if sampling reverbs better to set it higher than the reverb tail you expect)
-- @changelog - possible fix for failure in some systems
--  - do not change arrange view

-- Thanks to EUGEN27771, spk77, X-Raym


--------------------------------------------------------------------------------------------


-- locals for better performance
local reaper = reaper
local debug = false
local huge, floor, min, log = math.huge, math.floor, math.min, math.log
local Win = string.find(reaper.GetOS(), "Win" )
local sep = Win and "\\" or "/"

-- Get project samplerate and path
local samplerate = reaper.SNM_GetIntConfigVar( "projsrate", 0 )
local proj_path = reaper.GetProjectPath("") .. sep


--------------------------------------------------------------------------------------------


-- Preliminary tests

-- Test if a track is selected
local track = reaper.GetSelectedTrack( 0, 0 )
local msg = "Please, select one track with enabled TrackFX Chain, for which you want the IR to be created."
if not track then
  reaper.MB( msg, "No track selected!", 0 )
  return
end
local fx_cnt = reaper.TrackFX_GetCount( track )
local fx_enabled = reaper.GetMediaTrackInfo_Value( track, "I_FXEN" )
if fx_cnt < 1 or fx_enabled == 0 then
  reaper.MB( msg, "No FX loaded or FX Chain is bypassed!", 0 )
  return
end

local _, tr_name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
if tr_name ~= "" then tr_name = tr_name .. " IR" end

-- Get values
local ok, retvals = reaper.GetUserInputs( "Impulse Response creation", 5, "IR Name (mandatory): ,Maximum IR Length (sec): ,Mono or Stereo (m or s, 1 or 2): ,Trim silence below (dB, < -60): ,Normalize peak (dBFS, < 0): ,separator=\n", tr_name .. "\n5\ns\n-100\n-0.4" )
local IR_name, IR_len, channels, trim, peak_normalize = string.match(retvals, "(.+)\n(.+)\n(.+)\n(.+)\n(.+)")

local IR_len, peak_normalize, trim = tonumber(IR_len), tonumber(peak_normalize), tonumber(trim)
if channels and channels:lower() == "m" or tonumber(channels) == 1 then
  channels = 1
elseif channels and channels:lower() == "s" or tonumber(channels) == 2 then
  channels = 2
end

-- Test validity of values
if not ok then
  return
end
if not IR_len or IR_len <= 0 or type(IR_len) ~= "number" or (channels ~= 1 and channels ~= 2)
or IR_name == "" or IR_name:match('[%"\\/]') or not peak_normalize or peak_normalize > 0
or type(peak_normalize) ~= "number" or not trim or trim > -60 or type(trim) ~= "number"
then
  reaper.MB( ok and "Invalid values!" or "Action aborted by user...", "Action aborted", 0 )
  return
end
local IR_Path = proj_path .. (IR_name:find("%.wav$") and IR_name or IR_name .. ".wav")

-- If file exists...
if reaper.file_exists( IR_Path ) then
  ok = reaper.MB( "Please, click OK to enter a new name...", "A file with that name already exists!", 1 )
  if ok == 1 then
    ok, IR_Path = reaper.JS_Dialog_BrowseForSaveFile( "Enter a new filename or choose an existing to overwite", proj_path, "", "Wave audio files (.wav)\0*.wav\0\0" )
    IR_Path = IR_Path:find("%.wav$") and IR_Path or IR_Path .. ".wav"
  end
  ok = ok == 1
end
if ok then
  if reaper.file_exists( IR_Path ) then
    local deleted = os.remove(IR_Path)
    if not deleted then
      reaper.MB( "File is in use by an open Reaper Project. Please, run again the script and choose a new filename or one that is not used.", "Aborting...", 0 )
      ok = false
    end
  end
else 
  return 
end
if not ok then return end


--------------------------------------------------------------------------------------------


function Msg(string)
  if debug then
    reaper.ShowConsoleMsg(tostring(string))
  end
end

-- X-Raym conversion functions
function dBFromVal(val) return 20*log(val, 10) end
function ValFromdB(dB_val) return 10^(dB_val/20) end

function Create_Dirac(FilePath, channels, item_len) -- based on EUGEN27771's Wave Generator
  local val_out
  local len = item_len
  local numSamples = floor(samplerate * item_len * channels + 0.5)
  local buf = {}
  buf[1] = 1
  if channels == 1 then
    for i = 2, numSamples do
      buf[i] = 0
    end
  else
    buf[2] = 1
    for i = 3, numSamples do
      buf[i] = 0
    end
  end
  local data_ChunkDataSize = numSamples * channels * 32/8
  -- RIFF_Chunk =  RIFF_ChunkID, RIFF_chunkSize, RIFF_Type
    local RIFF_Chunk, RIFF_ChunkID, RIFF_chunkSize, RIFF_Type 
    RIFF_ChunkID   = "RIFF"
    RIFF_chunkSize = 36 + data_ChunkDataSize
    RIFF_Type      = "WAVE"
    RIFF_Chunk = string.pack("<c4 I4 c4",
                              RIFF_ChunkID,
                              RIFF_chunkSize,
                              RIFF_Type)
  -- fmt_Chunk = fmt_ChunkID, fmt_ChunkDataSize, audioFormat, channels, samplerate, byterate, blockalign, bitspersample
    local fmt_Chunk, fmt_ChunkID, fmt_ChunkDataSize, byterate, blockalign
    fmt_ChunkID       = "fmt "
    fmt_ChunkDataSize = 16 
    byterate          = samplerate * channels * 32/8
    blockalign        = channels * 32/8
    fmt_Chunk  = string.pack("< c4 I4 I2 I2 I4 I4 I2 I2",
                              fmt_ChunkID,
                              fmt_ChunkDataSize,
                              3,
                              channels,
                              samplerate,
                              byterate,
                              blockalign,
                              32)
  -- data_Chunk  =  data_ChunkID, data_ChunkDataSize, Data(bytes)
    local data_Chunk, data_ChunkID
    data_ChunkID = "data"
    data_Chunk = string.pack("< c4 I4",
                              data_ChunkID,
                              data_ChunkDataSize)
  -- Pack data(samples) and Write to File
    local file = io.open(FilePath,"wb")
    if not file then
      reaper.MB("Cannot create wave file!","Action Aborted",0)
      return false  
    end
    local n = 1024
    local rest = numSamples % n
    local Pfmt_str = "<" .. string.rep("f", n)
    local Data_buf = {}
    -- Pack full blocks
    local b = 1
    for i = 1, numSamples-rest, n do
        Data_buf[b] = string.pack(Pfmt_str, table.unpack( buf, i, i+n-1 ) )
        b = b+1
    end
    -- Pack rest
    Pfmt_str = "<" .. string.rep("f", rest)
    Data_buf[b] = string.pack(Pfmt_str, table.unpack( buf, numSamples-rest+1, numSamples ) ) -->>>  Pack samples(Rest)
  -- Write Data to file
  file:write(RIFF_Chunk,fmt_Chunk,data_Chunk, table.concat(Data_buf) )
  file:close()
  for i = 1, huge do
    if reaper.file_exists( FilePath ) then
      reaper.InsertMedia( FilePath, 0 )
      break
    end
  end
  return true
end

-- based on spk77's "get_average_rms" function 
function trim_silence_below_threshold(item, threshold) -- threshold in dB
  if not item then return end
  local take = reaper.GetActiveTake( item )
  local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local item_end = item_pos + item_len
  local position = false
  local threshold = ValFromdB(threshold)
  -- Calculate corrections for take/item volume
  --local adjust_vol = reaper.GetMediaItemTakeInfo_Value(take, "D_VOL") * reaper.GetMediaItemInfo_Value(item, "D_VOL")
  -- Reverse take to get samples from end to start
  reaper.Main_OnCommand(41051, 0) -- Item properties: Toggle take reverse
  -- Get media source of media item take
  local take_pcm_source = reaper.GetMediaItemTake_Source(take)
  -- Create take audio accessor
  local aa = reaper.CreateTakeAudioAccessor(take)
  -- Get the length of the source media
  local take_source_len = reaper.GetMediaSourceLength(take_pcm_source)
  local take_start_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  -- Get the start time of the audio that can be returned from this accessor
  local aa_start = reaper.GetAudioAccessorStartTime(aa)
  -- Get the end time of the audio that can be returned from this accessor
  local aa_end = reaper.GetAudioAccessorEndTime(aa)
  if take_start_offset <= 0 then -- item start position <= source start position 
    aa_start = -take_start_offset
    aa_end = aa_start + take_source_len
  elseif take_start_offset > 0 then -- item start position > source start position 
    aa_start = 0
    aa_end = aa_start + take_source_len- take_start_offset
  end
  if aa_start + take_source_len > item_len then
    aa_end = item_len
  end
  -- Get the number of channels in the source media.
  local take_source_num_channels = reaper.GetMediaSourceNumChannels(take_pcm_source)
  -- Get the sample rate
  local take_source_sample_rate = reaper.GetMediaSourceSampleRate(take_pcm_source)
  local total_samples = floor((aa_end - aa_start) * take_source_sample_rate + 0.5)
  -- How many samples are taken from audio accessor and put in the buffer (window size)
  local samples_per_channel = take_source_sample_rate
  if item_len < 1 then
    samples_per_channel = floor(item_len*take_source_sample_rate)
  end
  -- Samples are collected to this buffer
  local buffer = reaper.new_array(samples_per_channel*take_source_num_channels)
  local audio_end_reached = false
  local offs = aa_start
  function sumsq(a, ...) return a and a^2 + sumsq(...) or 0 end
  function rms(t) return (sumsq(table.unpack(t)) / #t)^.5 end
  local samples_cnt = 0
  -- Loop through samples
  local buff_cnt = 1
  while (not audio_end_reached) do
    if audio_end_reached then
      break
    end
    -- Fix for last buffer
    if total_samples - samples_cnt < samples_per_channel then
      samples_per_channel = total_samples - samples_cnt
      buffer.clear()
      buffer.resize(samples_per_channel*take_source_num_channels)
    end
    -- Get a block of samples. Samples are returned interleaved
    local aa_ret = 
    reaper.GetAudioAccessorSamples(
                      aa,                       -- AudioAccessor accessor
                      take_source_sample_rate,  -- integer samplerate
                      take_source_num_channels, -- integer numchannels
                      offs,                     -- number starttime_sec
                      samples_per_channel,      -- integer numsamplesperchannel
                      buffer                    -- reaper.array samplebuffer
                                  )
    -- Find position --------------------------------------------------------------
    -- Table to store each channel's data
    local chan = {}
    -- Table to store first position above threshold for each channel
    local pos_in_samples = {}
    -- Create channel tables
    for i = 1, take_source_num_channels do
      chan[i] = {}
      local s = 0
      for j = i, #buffer-take_source_num_channels+i, take_source_num_channels do
        s = s + 1
        chan[i][s] = buffer[j]
      end
      local subset = {}
      -- make subset of x samples to calculate rms for them
      local x = 5 --floor(take_source_sample_rate/1000)-1
      s = 0
      for k = 1, #chan[i]-x+1, x+1 do
        s = s + 1
        local f = 1
        subset[s] = {}
        for l = k, k+x do
          subset[s][f] = chan[i][l]
          f = f + 1
        end
        --Msg(string.format("buf %i chan %i sub %i rms %.1f\n", buff_cnt,i,s,dBFromVal(rms(subset[s]))))
        -- if rms of subset is above threshold then stop and store the position in buffer for that channel
        if rms(subset[s]) >= threshold then
          pos_in_samples[#pos_in_samples+1] = floor(k + (x/2)) -- the middle of the subset
          break
        end
      end 
    end
    -- get the first occurrence of rms above threshold if found in this buffer
    if #pos_in_samples ~= 0 then
      local pos_in_samples_val = min(table.unpack(pos_in_samples))
      position = offs + pos_in_samples_val/take_source_sample_rate
    end
    -- if a position was found, then break
    if position then
      --Msg("position found: " .. position .. "\n")
      break
    end
    -- Find position end ----------------------------------------------------------
    -- break loop if last buffer
    if offs + (samples_per_channel/take_source_sample_rate) >= aa_end then
      audio_end_reached = true
      --Msg("audio end reached")
    end
    -- move to next offset
    offs = offs + samples_per_channel / take_source_sample_rate
    samples_cnt = samples_cnt + samples_per_channel
    buff_cnt = buff_cnt + 1
  end
  reaper.DestroyAudioAccessor(aa)
  -- Bring take back to normal
  reaper.Main_OnCommand(41051, 0) -- Item properties: Toggle take reverse
  -- If a suitable position has been found, trim there (ignore if trim is less than 5ms)
  if position and position > 0.005 then
    -- do not let impulse smaller than 20ms
    if item_len-position < 0.02 then
      position = item_len - 0.02
      --Msg("new position : " .. position .. "\n")
    end
    reaper.SetEditCurPos( item_pos, true, false )
    local new_item = reaper.SplitMediaItem( item, item_end - position )
    reaper.DeleteTrackMediaItem( reaper.GetMediaItem_Track( new_item ), new_item )
  end
end


----------------------------------------------------------------------------------------


-- Main Action

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh( 1 )
reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_SAVEVIEW'), 0) -- SWS: Save current arrange view, slot 1


-- Create Dirac
reaper.SelectAllMediaItems( 0, false )
local dirac_path = proj_path .. string.match(reaper.time_precise()*100, "(%d+)%.") .. ".wav"
ok = Create_Dirac(dirac_path, channels, IR_len )
if not ok then return end

-- Apply FX
local item = reaper.GetSelectedMediaItem(0,0)
if channels == 1 then
  reaper.Main_OnCommand(40361, 0) -- Item: Apply track/take FX to items (mono output)
else
  reaper.Main_OnCommand(40209, 0) -- Item: Apply track/take FX to items
end
local take = reaper.GetActiveTake( item )
local PCM_source = reaper.GetMediaItemTake_Source( take )
local render_path = reaper.GetMediaSourceFileName( PCM_source, "" )

-- Normalize to peak
reaper.Main_OnCommand(40108, 0) -- Item properties: Normalize items
reaper.SetMediaItemInfo_Value( item, "D_VOL", ValFromdB(peak_normalize) )

-- Trim silence at the end
trim_silence_below_threshold(item, trim)

-- Glue changes
reaper.Main_OnCommand(40362, 0) -- Item: Glue items, ignoring time selection
item = reaper.GetSelectedMediaItem(0,0)

-- Rename resulting IR
local filename = string.gsub(render_path, ".wav$", "-glued.wav")
for i = 1, huge do
if reaper.file_exists( filename ) then
  reaper.Main_OnCommand(40440, 0) -- Item: Set selected media offline
  os.rename(filename, IR_Path )
  break
end
end
for i = 1, huge do
  if reaper.file_exists( IR_Path ) then
    local take = reaper.GetActiveTake( item )
    reaper.BR_SetTakeSourceFromFile( take, IR_Path, false )
    break
  end
end
reaper.Main_OnCommand(40439, 0) -- Item: Set selected media online
reaper.Main_OnCommand(41858, 0) -- Item: Set item name from active take filename
reaper.Main_OnCommand(40441, 0) -- Peaks: Rebuild peaks for selected items

-- Delete unneeded files
os.remove(dirac_path)
os.remove(render_path)

-- Create Undo
reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_RESTOREVIEW'), 0) -- SWS: Restore arrange view, slot 1
reaper.PreventUIRefresh( -1 )
reaper.Undo_EndBlock( "Create IR of FX Chain of selected track", 4 )
reaper.UpdateArrange()

-- Open in explorer/finder
reaper.CF_LocateInExplorer( IR_Path )

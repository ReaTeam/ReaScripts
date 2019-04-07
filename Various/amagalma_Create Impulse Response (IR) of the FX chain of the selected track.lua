-- @description amagalma_Create Impulse Response (IR) of the FX chain of the selected track
-- @author amagalma
-- @version 1.0
-- @about
--  # Creates an impulse response (IR) of the FX Chain of the first selected track.
--  # You can define:
--  # the peak value of the normalization,
--  # the threshold below which audio in the end of the IR will be discarded,
--  # the channels of the IR (mono or stereo),
--  # the maximum IR length (if sampling reverbs better to set it to a high value like 10)

-- Thanks to EUGEN27771, Adam Lovatt, Lokasenna, Edgemeal, X-Raym

--------------------------------------------------------------------------------------------

-- locals for better performance
local reaper = reaper
local huge, min, floor = math.huge, math.min, math.floor
local GetSamples = reaper.GetAudioAccessorSamples

-- Get project samplerate and path
local samplerate = reaper.SNM_GetIntConfigVar( "projsrate", 0 )
local proj_path = reaper.GetProjectPath("") .. "\\"

-- Needed functions
local function ValFromdB(dB_val) return 10^(dB_val/20) end -- X-Raym
local function dBFromVal(val) return 20*math.log(val, 10) end -- X-Raym

local function rename_item_file(item, newname)
  local take = reaper.GetActiveTake( item )
  if not take or reaper.TakeIsMIDI(take) then return end
  local PCM_source = reaper.GetMediaItemTake_Source( take )
  local filename = reaper.GetMediaSourceFileName( PCM_source, "" )
  reaper.Main_OnCommand(40440, 0) -- Item: Set selected media offline
  for i = 1, huge do
    if reaper.file_exists( filename ) then
      os.rename(filename, newname)
      break
    end
  end
  for i = 1, huge do
    if reaper.file_exists( newname ) then
      reaper.BR_SetTakeSourceFromFile( take, newname, false )
      break
    end
  end
  reaper.Main_OnCommand(40439, 0) -- Item: Set selected media online
  reaper.Main_OnCommand(40441, 0) -- Peaks: Rebuild peaks for selected items
  reaper.Main_OnCommand(41858, 0) -- Item: Set item name from active take filename
end

local function Create_Dirac(FilePath, channels, item_len) -- based on EUGEN27771's Wave Generator
  local numSamples = samplerate * item_len * channels
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
  reaper.InsertMedia( FilePath, 0 )
 return true
end

----------------------------------------------------------------------------------------

-- Test if a track is selected
local track = reaper.GetSelectedTrack( 0, 0 )
local fx_cnt = reaper.TrackFX_GetCount( track )
local fx_enabled = reaper.GetMediaTrackInfo_Value( track, "I_FXEN" )
if not track or fx_cnt < 1 or fx_enabled == 0 then
  reaper.MB( "Please, select a track with enabled TrackFX where you want the IR to be created in", "No track selected or no FX loaded, or FX Chain disabled", 0 )
  return
end

local _, tr_name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
if tr_name ~= "" then tr_name = tr_name .. " IR" end

-- Get values
local ok, retvals = reaper.GetUserInputs( "Impulse Response creation", 5, "IR Name: ,Maximum IR Length (sec): ,Mono or Stereo (m or s): ,Normalize peak (dBFS): ,Trim silence threshold (dB): ,extrawidth=70", tr_name .. ",2,m,-0.3,-120" )
local IR_name, IR_len, channels, peak_normalize, trim = string.match(retvals, "(.+),(.+),(.+),(.+),(.+)")

IR_len, peak_normalize, trim = tonumber(IR_len), tonumber(peak_normalize), tonumber(trim)
if channels == "m" then
  channels = 1
elseif channels == "s" then
  channels = 2
end

-- Test validity of values
if not ok then return end
if not IR_len or IR_len <= 0 or (channels ~= 1 and channels ~= 2) or IR_name == "" or not peak_normalize or peak_normalize > 0 or trim > -60 then 
  reaper.MB( "Invalid values!", "Action aborted", 0 )
return end

reaper.PreventUIRefresh( 1 )
reaper.Undo_BeginBlock()

----------------------------------------------------------------------------------------
-- Create IR
----------------------------------------------------------------------------------------
reaper.SelectAllMediaItems( 0, false )
local dirac_path = proj_path .. IR_name .. ".wav"
ok = Create_Dirac(dirac_path, channels, IR_len)
if not ok then return end
local item = reaper.GetSelectedMediaItem(0,0)
if channels == 1 then
  reaper.Main_OnCommand(40361, 0) -- Item: Apply track/take FX to items (mono output)
else
  reaper.Main_OnCommand(40209, 0) -- Item: Apply track/take FX to items
end
reaper.Main_OnCommand(40131, 0) -- Take: Crop to active take in items
reaper.Main_OnCommand(40612, 0) -- Item: Set item end to source media end
-- Delete original dirac
os.remove (dirac_path)
-- Rename rendered file
rename_item_file(item, dirac_path)

----------------------------------------------------------------------------------------
-- Optimize length of IR (trim trailing silence)
----------------------------------------------------------------------------------------
reaper.Main_OnCommand(40108, 0) -- Item properties: Normalize items
item = reaper.GetSelectedMediaItem(0,0)
local t = {} -- table to store samples
local function iterateSamples(item, reverse) -- Adam Lovatt & Lokasenna
  local item_len = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
  local take = reaper.GetActiveTake( item )
  local take_vol = reaper.GetMediaItemTakeInfo_Value( take, "D_VOL" )
  local range_len_spls = floor(item_len * samplerate)
  -- Break the range into blocks
  local block_size = 65536
  local n_blocks = floor(range_len_spls / block_size)
  local extra_spls = range_len_spls - block_size * n_blocks
  -- 'samplebuffer' will hold all of the audio data for each block
  local samplebuffer = reaper.new_array(block_size * channels)
  local audio = reaper.CreateTakeAudioAccessor(take)
  -- Loop through the audio, one block at a time
  local time_start = reverse and item_len or 0
  local time_offset = ((block_size * channels) / samplerate) * (reverse and -1 or 1)
  local index = 0 
  for cur_block = 0, n_blocks do
    -- The last iteration will almost never be a full block
    local block_size = (cur_block == n_blocks) and extra_spls or block_size
    samplebuffer.clear()
    -- Loads 'samplebuffer' with the next block
    GetSamples(audio, samplerate, channels, (reverse and (time_start - (block_size / samplerate)) or time_start), block_size, samplebuffer)
    local spl_start, spl_end, step
    if reverse then
      spl_start, spl_end = block_size * channels, 1
      step = -1
    else
      spl_start, spl_end = 1, block_size * channels
      step = 1
    end
    for i = spl_start, spl_end, step do
      index = index + 1
      t[index] = samplebuffer[i]*take_vol
    end
    time_start = time_start + time_offset
  end
  reaper.DestroyAudioAccessor(audio)
end

local item_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
iterateSamples(item, true)
for i = 1, #t do
  local sample_dB = dBFromVal(t[i])
  if not (sample_dB ~= sample_dB) and sample_dB ~= -huge and sample_dB >= trim then
    reaper.SetEditCurPos( (#t-i+1)/samplerate + item_pos, false, false )
    reaper.Main_OnCommand(41311, 0) -- Item edit: Trim right edge of item to edit cursor
    reaper.SetMediaItemInfo_Value( item, "D_VOL", ValFromdB(peak_normalize) )
    reaper.Main_OnCommand(40362, 0) -- Item: Glue items, ignoring time selection
    os.remove (dirac_path)
    local item = reaper.GetSelectedMediaItem(0,0)
    rename_item_file(item, dirac_path)
    reaper.Main_OnCommand(40612, 0) -- Item: Set item end to source media end
    -- Edgemeal code for open explorer with file selected
    if string.match( reaper.GetOS(), "Win") then
      reaper.ExecProcess('explorer.exe /e,/select,' .. '"' .. dirac_path .. '"', -1)
    else
      os.execute('open "" "' .. string.match(dirac_path, ".+/"))
    end
    break
  end
end

reaper.Undo_EndBlock( "Create IR of FX in selected track", 4 )
reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()

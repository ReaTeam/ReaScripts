-- @description Create Impulse Response (IR) of the FX Chain of the selected Track
-- @author amagalma
-- @version 2.02
-- @changelog
--   - Ensure no orphan reapeak is left behind
--   - Ensure that track name does not change
-- @link https://forum.cockos.com/showthread.php?t=234517
-- @about
--   # Creates an impulse response (IR) of the FX Chain of the first selected track.
--   - Mono or Stereo IR creation
--   - Browse for path and filename
--   - Normalize to maximum peak value
--   - Trim trailing silence below set threshold
--   - Locate file in Explorer/Finder
--   - Insert file in Project
--   - Load created IR in Reaverb and bypass the other FX in track
--   - Set default values inside the script
--   - Requires JS_ReaScriptAPI extension and Lokasenna GUI v2 libary

-- Thanks to EUGEN27771, spk77, X-Raym, Lokasenna

local version = "2.02"
--------------------------------------------------------------------------------------------


-- ENTER HERE DEFAULT VALUES:
local Max_IR_Lenght = 5 -- Seconds
local Normalize_Peak = -0.4 -- (must be less than 0)
local Normalize_Enable = 1 -- (1 = enabled, 0 = disabled)
local Trim_Silence_Below = -100 -- (must be less than -60)
local Trim_Silence_Enable = 1 -- (1 = enabled, 0 = disabled)
local Mono_Or_Stereo = 2 -- (1: mono, 2: stereo)
local Locate_In_Explorer = 1 -- (1 = yes, 0 = no)
local Insert_In_Project = 0 -- (1 = yes, 0 = no)
local Load_in_Reaverb = 1 -- (1 = yes, 0 = no)


--------------------------------------------------------------------------------------------


-- locals for better performance
local reaper = reaper
local debug = false
local problems = 0
local floor, min, log = math.floor, math.min, math.log
local Win = string.find(reaper.GetOS(), "Win" )
local sep = Win and "\\" or "/"

-- Get project samplerate and path
local samplerate = reaper.SNM_GetIntConfigVar( "projsrate", 0 )
local proj_path = reaper.GetProjectPath("") .. sep
local IR_Path = proj_path

-- Initialize Variables
local IR_name = "IR"
local IR_FullPath = IR_Path .. IR_name
local IR_len, peak_normalize = Max_IR_Lenght, Normalize_Peak
local trim, channels = Trim_Silence_Below, Mono_Or_Stereo


--------------------------------------------------------------------------------------------


-- Preliminary tests


-- Check if JS_ReaScriptAPI is installed
if not reaper.APIExists("JS_Window_Find") then
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "JS_ReaScriptAPI Installation", 0 )
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then
    reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else
    reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
end


-- Check Lokasenna_GUI library availability --
local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" or not reaper.file_exists(lib_path .. "Core.lua") then
  local not_installed = false
  local Core_library = {reaper.GetResourcePath(), "Scripts", "ReaTeam Scripts", "Development", "Lokasenna_GUI v2", "Library", "Core.lua"}
  local sep = reaper.GetOS():find("Win") and "\\" or "/"
  Core_library = table.concat(Core_library, sep)
  if reaper.file_exists(Core_library) then
    local cmdID = reaper.NamedCommandLookup( "_RS1c6ad1164e1d29bb4b1f2c1acf82f5853ce77875" )
    if cmdID > 0 then
          reaper.MB("Lokasenna's GUI path will be set now. Please, re-run the script", "Lokasenna GUI v2 Installation", 0)
      -- Set Lokasenna_GUI v2 library path.lua
      reaper.Main_OnCommand(cmdID, 0)
      return reaper.defer(function() end)
    else
      not_installed = true
    end
  else
    not_installed = true
  end
  if not_installed then
    reaper.MB("Please, right-click and install 'Lokasenna's GUI library v2 for Lua' in the next window. Then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List. After all is set, you can run this script again. Thanks!", "Install Lokasenna GUI v2", 0)
    reaper.ReaPack_BrowsePackages( "Lokasenna GUI library v2 for Lua" )
    return reaper.defer(function() end)
  end
end
loadfile(lib_path .. "Core.lua")()
GUI.req("Classes/Class - Menubox.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Label.lua")()
if missing_lib then 
  reaper.MB("Please re-install 'Lokasenna's GUI library v2 for Lua' from ReaPack and run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Missing libraries!", 0)
  return reaper.defer(function() end)
end


-- Test if a track is selected
local track = reaper.GetSelectedTrack( 0, 0 )
local msg = "Please, select one track with enabled TrackFX Chain, for which you want the IR to be created."
if not track then
  reaper.MB( msg, "No track selected!", 0 )
  return reaper.defer(function() end)
end
local fx_cnt = reaper.TrackFX_GetCount( track )
local fx_enabled = reaper.GetMediaTrackInfo_Value( track, "I_FXEN" )
if fx_cnt < 1 or fx_enabled == 0 then
  reaper.MB( msg, "No FX loaded or FX Chain is bypassed!", 0 )
  return reaper.defer(function() end)
end

local _, tr_name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
local track_name = tr_name
tr_name = tr_name ~= "" and tr_name .. " IR" or "IR"


--------------------------------------------------------------------------------------------


-- FUNCTIONS


local function Msg(string)
  if not string then return end
  if debug then
    reaper.ShowConsoleMsg(tostring(string) .. "\n")
  end
end

-- X-Raym conversion functions
local function dBFromVal(val) return 20*log(val, 10) end
local function ValFromdB(dB_val) return 10^(dB_val/20) end

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
  if reaper.file_exists( FilePath ) then
    reaper.InsertMedia( FilePath, 0 )
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
    --[[ Fix for last buffer
    if total_samples - samples_cnt < samples_per_channel then
      samples_per_channel = total_samples - samples_cnt
      buffer.clear()
      buffer.resize(samples_per_channel*take_source_num_channels)
    end--]]
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
      --Msg("position found: " .. position)
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
      --Msg("new position : " .. position)
    end
    --reaper.SetEditCurPos( item_pos, true, false )
    local new_item = reaper.SplitMediaItem( item, item_end - position )
    reaper.DeleteTrackMediaItem( reaper.GetMediaItem_Track( new_item ), new_item )
    return true
  else
    return false
  end
end

function CreateIR()
  gfx.quit()
  -- Test validity of values
  IR_name = GUI.Val("Name")
  if not IR_name or IR_name == "" then
    Msg("Entered name was not valid. Auto-created from current date and time.")
    IR_name = os.date("IR_%d-%m-%Y_%H-%M-%S")
  end
  IR_name = IR_name:find("%.wav$") and IR_name or IR_name .. ".wav"
  IR_FullPath = IR_Path .. IR_name
  
  IR_len = tonumber(GUI.Val("Length"))
  if not IR_len or IR_len <= 0 then
    Msg("Length value must be above 0. Using default value: " .. Max_IR_Lenght)
    IR_len = Max_IR_Lenght
  end
  
  peak_normalize = tonumber(GUI.Val("Normalize"))
  if not peak_normalize or peak_normalize >= 0 then
    Msg("Peak normalize value must be below 0. Using default value: " .. Normalize_Peak)
    peak_normalize = Normalize_Peak
  end
  
  trim = tonumber(GUI.Val("Trim"))
  if not trim or trim > -60 then
    Msg("Trim silence value must be below -60. Using default value: " .. Trim_Silence_Below)
    trim = Trim_Silence_Below
  end
  
  Normalize_Enable, Trim_Silence_Enable = table.unpack(GUI.Val("NormTrim"))
  channels = GUI.Val("Channels") 
  Locate_In_Explorer, Insert_In_Project, Load_in_Reaverb = table.unpack(GUI.Val("Options"))  
  
  -- Debug messages for validity of values
  Msg("IR full path will be: " .. IR_FullPath)
  Msg("Maximum length of IR will be " .. IR_len)
  if Normalize_Enable then 
    Msg("Normalize Peak to " .. peak_normalize)
  end
  if Trim_Silence_Enable then
    Msg("Trim Silence Below " .. trim)
  end
  Msg("Channels: " .. (channels == 1 and "Mono" or "Stereo"))
  if Locate_In_Explorer then Msg("Locate in Explorer enabled") end
  if Insert_In_Project then Msg("Insert in Project enabled") end
  if Load_in_Reaverb then Msg("Load in Reaverb enabled") end
  Msg("========================\n")
  
  -- Start IR Creation
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh( 1 )
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_SAVEVIEW'), 0) -- SWS: Save current arrange view, slot 1
  
  -- Save current setting for Apply FX/Glue and set to WAV
  local fx_format = reaper.SNM_GetIntConfigVar( "projrecforopencopy", -1 )
  if fx_format ~= 0 then
    reaper.SNM_SetIntConfigVar( "projrecforopencopy", 0 )
  end
  
  -- Disable automatic fades
  local autofade_state = reaper.GetToggleCommandState( 41194 )
  if autofade_state == 1 then
    reaper.Main_OnCommand(41194, 0) -- Item: Toggle enable/disable default fadein/fadeout
  end
  
  -- Create Dirac
  reaper.SelectAllMediaItems( 0, false )
  local dirac_path = IR_Path .. string.match(reaper.time_precise()*100, "(%d+)%.") .. ".wav"
  local ok = Create_Dirac(dirac_path, channels, IR_len )
  if not ok then 
    Msg("Create Dirac failed. Aborted.\n\n")
    return
  end
  
  -- Apply FX
  local item = reaper.GetSelectedMediaItem(0,0)
  if item then
    Msg("Create Dirac succeded. Item is: ".. tostring(item))
  else
    problems = problems+1
    Msg(problems .. ") Could not get the item")
  end
  if channels == 1 then
    reaper.Main_OnCommand(40361, 0) -- Item: Apply track/take FX to items (mono output)
  else
    reaper.Main_OnCommand(40209, 0) -- Item: Apply track/take FX to items
  end
  local take = reaper.GetActiveTake( item )
  local PCM_source = reaper.GetMediaItemTake_Source( take )
  local render_path = reaper.GetMediaSourceFileName( PCM_source, "" )
  if render_path then
    Msg("Applied FX. Render path is: ".. render_path)
  else
    problems = problems+1
    Msg(problems .. ") Could not get the render_path")
  end
  
  -- Normalize to peak
  if Normalize_Enable then
    reaper.Main_OnCommand(40108, 0) -- Item properties: Normalize items
    reaper.SetMediaItemInfo_Value( item, "D_VOL", ValFromdB(peak_normalize) )
    Msg("Normalized to " .. peak_normalize .. " dB")
  end
  
  -- Trim silence at the end
  if Trim_Silence_Enable then
    local ok = trim_silence_below_threshold(item, trim)
    if ok then
      Msg("Trim Silence succeeded")
    else
      problems = problems+1
      Msg(problems .. ") Trim Silence failed")
    end
  end
  
  -- Glue changes
  reaper.Main_OnCommand(40362, 0) -- Item: Glue items, ignoring time selection
  item = reaper.GetSelectedMediaItem(0,0)
  if item then
    Msg("Glued. New item is: ".. tostring(item))
  else
    problems = problems+1
    Msg(problems .. ") Could not get the item")
  end

  -- Rename resulting IR
  local filename = string.gsub(render_path, ".wav$", "-glued.wav")
  if reaper.file_exists( filename ) then
    reaper.Main_OnCommand(40440, 0) -- Item: Set selected media offline
    if reaper.file_exists(IR_FullPath) then
      -- There is already a file with the same filename and path
      local ok = os.remove(IR_FullPath)
      if ok then
        -- File removed to be replaced
        local ok2 = os.rename(filename, IR_FullPath )
        if ok2 then
          Msg("Renamed " .. filename .. "  TO  " .. IR_FullPath)
        else
          problems = problems+1
          Msg(problems .. ") Failed to rename " .. filename .. " TO " .. IR_FullPath)
        end
      else
        -- Didn't manage to remove. Change the name
        IR_FullPath = IR_Path .. os.date("%H-%M-%S ") .. IR_name
        os.rename(filename, IR_FullPath)
        problems = problems+1
        Msg(problems .. ") Specified file is in use by Reaper. Renamed " .. filename .. " TO " .. IR_FullPath)
      end
    else
      -- No same file. Proceed with the renaming
      local ok = os.rename(filename, IR_FullPath )
      if ok then
        Msg("Renamed " .. filename .. "  TO  " .. IR_FullPath)
      else
        problems = problems+1
        Msg(problems .. ") Failed to rename " .. filename .. " TO " .. IR_FullPath)
      end
    end
  else
    problems = problems+1
    Msg(problems .. ") Failed to locate the glued file")
  end
  
  -- Delete unneeded files
  ok = os.remove(dirac_path)
  if ok then
    Msg("Deleted ".. dirac_path)
  else
    problems = problems+1
    Msg(problems .. ") Failed to delete ".. dirac_path)
  end
  local reapeak_file = dirac_path .. ".reapeaks"
  if reaper.file_exists(reapeak_file) then
    ok = os.remove(reapeak_file)
    if ok then
      Msg("Deleted ".. reapeak_file)
    else
      problems = problems+1
      Msg(problems .. ") Failed to delete ".. reapeak_file)
    end
  end
  ok = os.remove(render_path)
  if ok then
    Msg("Deleted ".. render_path)
  else
    problems = problems+1
    Msg(problems .. ") Failed to delete ".. render_path)
  end
  
  -- Re-enable auto-fades if needed
  if autofade_state == 1 then
    reaper.Main_OnCommand(41194, 0) -- Item: Toggle enable/disable default fadein/fadeout
  end
  
  -- Set back format for FX/Glue if changed
  if fx_format ~= 0 then
    reaper.SNM_SetIntConfigVar( "projrecforopencopy", fx_format )
  end  
  
  -- Set back track name
  reaper.GetSetMediaTrackInfo_String( track, "P_NAME", track_name, true )
  
  if Insert_In_Project then
    if reaper.file_exists( IR_FullPath ) then
      local take = reaper.GetActiveTake( item )
      reaper.BR_SetTakeSourceFromFile( take, IR_FullPath, false )
    end
    reaper.Main_OnCommand(40439, 0) -- Item: Set selected media online
    reaper.Main_OnCommand(41858, 0) -- Item: Set item name from active take filename
    reaper.Main_OnCommand(40441, 0) -- Peaks: Rebuild peaks for selected items
    Msg("IR was inserted in Project")
  else
    local ok = reaper.DeleteTrackMediaItem( track, item )
    if not ok then Msg("Failed to remove the item from the Project") end
  end
  
  if Load_in_Reaverb then
    -- Bypass all FX
    track = reaper.GetSelectedTrack(0,0)
    local fx_cnt = reaper.TrackFX_GetCount( track )
    for i = 0, fx_cnt-1 do
      reaper.TrackFX_SetEnabled( track, i, false )
    end
    local pos = reaper.TrackFX_AddByName( track, "ReaVerb", false, -1 )
    reaper.TrackFX_Show( track, pos, 3 )
    local fxhwnd = reaper.JS_Window_Find( "ReaVerb (Cockos)", false )
    local _, list = reaper.JS_Window_ListAllChild( fxhwnd )
    local addbutton
    for address in list:gmatch("[^,]+") do
      local hwnd = reaper.JS_Window_HandleFromAddress( address )
      local title = reaper.JS_Window_GetTitle( hwnd )
      local class = reaper.JS_Window_GetClassName( hwnd )
      if title == "Add" and class == "Button" then
        addbutton = hwnd
      end
    end
    local _, left, top, right, bottom = reaper.BR_Win32_GetWindowRect( addbutton )
    -- click
    reaper.JS_WindowMessage_Post(addbutton, "WM_LBUTTONDOWN", 0x0001, 0, 10, 10)
    reaper.JS_WindowMessage_Post(addbutton, "WM_LBUTTONUP", 0x0000, 0, 10, 10)
    -- two times down arrow
    reaper.JS_WindowMessage_Post(addbutton, "WM_KEYDOWN", 0x28, 0, 0, 0)
    reaper.JS_WindowMessage_Post(addbutton, "WM_KEYDOWN", 0x28, 0, 0, 0)
    -- return
    reaper.JS_WindowMessage_Post(addbutton, "WM_KEYDOWN", 0x0D, 0, 0, 0)
    local start = reaper.time_precise()
    function waitdialog()
      if reaper.time_precise() - start >= 0.5 then
        local openfile = reaper.JS_Window_Find( "Open media file:", true )
        local _, list = reaper.JS_Window_ListAllChild( openfile )
        for address in list:gmatch("[^,]+") do
          local hwnd = reaper.JS_Window_HandleFromAddress( address )
          local class = reaper.JS_Window_GetClassName( hwnd )
          if class == "ComboBox" then
            local editwindow = reaper.JS_Window_FindChildByID( hwnd, 1148 )
            if editwindow then 
              reaper.JS_Window_SetTitle( editwindow, IR_FullPath )
              -- return
              reaper.JS_WindowMessage_Post(editwindow, "WM_KEYDOWN", 0x0D, 0, 0, 0)
              break
            end
          end
        end
        return
      end
      reaper.defer(waitdialog)
    end
    waitdialog()
  end
  
  -- Create Undo
  reaper.Main_OnCommand(reaper.NamedCommandLookup('_SWS_RESTOREVIEW'), 0) -- SWS: Restore arrange view, slot 1
  reaper.PreventUIRefresh( -1 )
  reaper.Undo_EndBlock( "Create IR of FX Chain of selected track", 2|4 )
  reaper.UpdateArrange()
  
  if Locate_In_Explorer then
    reaper.CF_LocateInExplorer( IR_FullPath )
  end
  
  -- Give debug message
  if problems > 0 then
    Msg("Script ended encountering ".. problems .. " problem" .. (problems > 1 and "s" or "") .. 
        "\n==============================\n")
  else
    Msg("\n\nCreated IR:\n-- " .. IR_FullPath .. " --\n\n")
    Msg("Script ended with no problems\n==============================\n")
  end
  
end


--------------------------------------------------------------------------------------------


-- GUI Functions

-- Modified function to display tooltip centered and without flickering
local showtooltip, last_tooltip, showtooltip_time, time_to_read = false, "-"
function GUI.settooltip(str)
  if not str or str == "" then return end
  if not showtooltip then
    local x, y = gfx.clienttoscreen(GUI.mouse.x, GUI.mouse.y )
    reaper.TrackCtl_SetToolTip(str, x, y + 20, true)
    local hwnd = reaper.GetTooltipWindow()
    local ok, width = reaper.JS_Window_GetClientSize( hwnd )
    width = ok and math.floor(width/2) or 146
    if hwnd then reaper.JS_Window_Move( hwnd, x - width, y + 22 ) end
    GUI.tooltip = str
    showtooltip = true
    showtooltip_time = reaper.time_precise()
    last_tooltip = GUI.mouseover_elm.name
    time_to_read = #str * 0.065 + 0.25
  end
end

function BrowseForFile()
  local ok, retval = reaper.JS_Dialog_BrowseForSaveFile( 
  "Save Impulse Response as :", IR_Path, GUI.Val("Name"), "Wave Audio files (*.WAV)\0*.wav\0\0" )
  if ok == 1 then
    IR_Path, IR_name = retval:match("(.+[\\/])(.+)")
    IR_name = IR_name:find("%.wav$") and IR_name or IR_name .. ".wav"
    Msg("Path from function: " .. retval)
    Msg("IR_path: " .. IR_Path )
    Msg("IR_name: " .. IR_name )
    IR_FullPath = IR_Path .. IR_name
    GUI.Val("Name", IR_name )
    Msg("========================\n\n")
  end
end

function MyFunction()
  -- Tooltip code
  if showtooltip then
    if GUI.mouseover_elm and GUI.mouseover_elm.name ~= last_tooltip then
      showtooltip = false
      last_tooltip = "-"
      showtooltip_time = nil
    elseif reaper.time_precise() - showtooltip_time > (time_to_read or 7) then
      reaper.TrackCtl_SetToolTip("", 0, 0, true)
    end
  end
end

function force_size()
  gfx.quit()
  gfx.init(GUI.name, GUI.w, GUI.h, GUI.dock, GUI.x, GUI.y)
  GUI.cur_w, GUI.cur_h = GUI.w, GUI.h
end

GUI.Draw_Version = function ()
  local str = "Script by amagalma   -   using Lokasenna_GUI "..GUI.version
  GUI.font("version")
  GUI.color("white")
  local str_w, str_h = gfx.measurestr(str)
  gfx.x = gfx.w - str_w - 10
  gfx.y = gfx.h - str_h - 4
  gfx.drawstr(str)
end

--------------------------------------------------------------------------------------------


-- GUI

local showdebug = debug and "  -  Debug" or ""
GUI.name = "Easy Impulse Response Creation  -  v" .. version .. showdebug
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 330, 345
GUI.anchor, GUI.corner = "screen", "C"
GUI.colors.white = { 230, 230, 230, 255 }
GUI.tooltip_time = 0.4

-- GUI constants

local left_align = 145
local top_align = 15
local space = 40
local text_w = 240

-- Elements

GUI.New("Name", "Textbox", {
    z = 1,
    x = left_align - 70,
    y = top_align,
    w = text_w,
    h = 20,
    caption = "IR Name",
    cap_pos = "left",
    font_a = 2,
    font_b = "monospace",
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 5,
    undo_limit = 20,
    tooltip = "Enter IR name. The current path is:\n" .. IR_Path .. "\nUse the 'Browse for File' button to change path."
})

GUI.New("Length", "Textbox", {
    z = 1,
    x = left_align,
    y = top_align + space,
    w = text_w *0.45,
    h = 20,
    caption = "Max IR Length",
    cap_pos = "left",
    font_a = 2,
    font_b = "monospace",
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 5,
    undo_limit = 20,
    tooltip = "The maximum length of the IR. When sampling reverbs it is best to specify a length longer than the tail you expect"
})

GUI.New("LengthL", "Label", {
    z = 1,
    x = left_align + text_w * 0.49,
    y = top_align + space,
    caption = "seconds",
    font = 2,
    color = "white",
    bg = "wnd_bg",
    shadow = true
})

GUI.New("Normalize", "Textbox", {
    z = 1,
    x = left_align,
    y = top_align + space*2,
    w = text_w * 0.45,
    h = 20,
    caption = "Normalize Peak to",
    cap_pos = "left",
    font_a = 2,
    font_b = "monospace",
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 5,
    undo_limit = 20,
    tooltip = "Set maximum peak value (number). Must be less than 0dBFS"
})

GUI.New("Trim", "Textbox", {
    z = 1,
    x = left_align,
    y = top_align + space*3,
    w = text_w * 0.45,
    h = 20,
    caption = "Trim Silence Below",
    cap_pos = "left",
    font_a = 2,
    font_b = "monospace",
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 5,
    undo_limit = 20,
    tooltip = "Trim IR length when volume falls under the threshold (number). Enter values below -60dB"
})

GUI.New("NormTrim", "Checklist", {
    z = 1,
    x = left_align + text_w * 0.6,
    y = top_align + space + 11,
    w = 50,
    h = 100,
    caption = "",
    optarray = {"dBFS", "dB   "},
    dir = "v",
    pad = 20,
    font_a = 2,
    font_b = 2,
    col_txt = "white",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = true,
    swap = true,
    opt_size = 20,
    tooltip = "Enable/Disable Normalize and Trim Silence"
})

GUI.New("Channels", "Menubox", {
    z = 1,
    x = left_align,
    y = top_align + space*4,
    w = 127,
    h = 20,
    caption = "Number of Channels",
    optarray = {"Mono", "Stereo"},
    retval = 2,
    font_a = 2,
    font_b = 2,
    col_txt = "white",
    col_cap = "white",
    bg = "wnd_bg",
    pad = 5,
    noarrow = false,
    align = 1,
    tooltip = "Choose to create Mono or Stereo IR"
})

GUI.New("Options", "Checklist", {
    z = 1,
    x = left_align - 59,
    y = top_align + space*4.25,
    w = 100,
    h = 140,
    caption = "",
    optarray = {"Locate in Explorer", "Insert in Project", "Load in Reaverb"},
    dir = "v",
    pad = 20,
    font_a = 2,
    font_b = 2,
    col_txt = "white",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = true,
    swap = true,
    opt_size = 20,
    tooltip = "Choose what to do with the created IR file"
})

GUI.New("Browse", "Button", {
    z = 1,
    x = GUI.w - 120 - 20,
    y = top_align + space*5.5 - 6,
    w = 120,
    h = 25,
    caption = "Browse for File",
    font = 2,
    col_txt = "white",
    col_fill = "elm_frame",
    tooltip = "Click to browse for exact filename and path",
    func = BrowseForFile
})

GUI.New("Create", "Button", {
    z = 1,
    x = GUI.w - 120 - 20,
    y = top_align + space*6.5,
    w = 120,
    h = 25,
    caption = "CREATE IR",
    font = 2,
    col_txt = "white",
    col_fill = "green",
    tooltip = "Click to create IR file",
    func = CreateIR
})

-- Set default values
IR_FullPath = proj_path .. tr_name
IR_Path, IR_name = proj_path, tr_name
GUI.Val("Name", tr_name)
GUI.Val("Length", Max_IR_Lenght)
GUI.Val("Normalize", Normalize_Peak)
GUI.Val("Trim", Trim_Silence_Below)
GUI.Val("NormTrim", {Normalize_Enable == 1, Trim_Silence_Enable == 1} )
GUI.Val("Channels", Mono_Or_Stereo)
GUI.Val("Options", {Locate_In_Explorer == 1, Insert_In_Project == 1, Load_in_Reaverb == 1})
GUI.onresize = force_size
GUI.func = MyFunction

-- Start GUI
if debug then
  reaper.ClearConsole()
  Msg("=== Script is in debug mode ===\n")
end

GUI.Init()
GUI.Main()

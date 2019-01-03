-- @description amagalma_Remove selected items' active takes' source file cue points (WAV only) - NO UNDO!
-- @author amagalma
-- @version 1.1
-- @about
--   # Deletes all cues points from the wav files (removes cue and list chunks)
--   # works only with WAV files

-- @changelog
--   Works correctly with VERY large files (no out of memory messages)
--------------------------------------------------------------------------------------------------

local reaper = reaper

local function remove_cues(item)
  local take = reaper.GetActiveTake(item)
  if take and not reaper.TakeIsMIDI( take ) then
    local source = reaper.GetMediaItemTake_Source( take )
    local samplerate = reaper.GetMediaSourceSampleRate( source )
    local filename = reaper.GetMediaSourceFileName( source , "" )
    local file = io.open(filename, "rb")
    local new_file_exists = false
    file:seek("cur", 4) -- riff_header
    local file_size_buf = file:read(4)
    local cur_pos = file:seek() -- current position in file
    local file_size = string.unpack("I", file_size_buf)
    local wave_header = file:read(4)
    if string.lower(wave_header) == "wave" then
      local tocopy = {} -- odd numbers = "from", even numbers = "to"
      tocopy[1] = 8
      local cue_chunk_found, list_chunk_found = 0, 0
      local cue_chunk_start, cue_chunk_end, list_chunk_start, list_chunk_end
      local data_start, data_end, data_size
      while (cue_chunk_found == 0 or list_chunk_found == 0) and file:seek() < file_size do
        local chunk_start = file:seek()
        local chunk_header = file:read(4)
        local chunk_size_buf = file:read(4)
        local chunk_size = string.unpack("I", chunk_size_buf)
        if chunk_size % 2 ~= 0 then -- odd, add padding
          chunk_size = chunk_size + 1
        end
        if string.lower(chunk_header) == "cue " then
          cue_chunk_start = chunk_start
          cue_chunk_end = cue_chunk_start + 8 + chunk_size
          if #tocopy % 2 ~= 0 then -- odd ("from"), set "to"
            tocopy[#tocopy+1] = cue_chunk_start
          else -- even, set new "to"
            if tocopy[#tocopy] == cue_chunk_start then
              tocopy[#tocopy+1] = cue_chunk_end
            end
          end
          file:seek("set", cue_chunk_end)
          cue_chunk_found = 1
        elseif string.lower(chunk_header) == "list" then
          list_chunk_start = chunk_start
          list_chunk_end = list_chunk_start + 8 + chunk_size
          if #tocopy % 2 ~= 0 then -- odd ("from"), set "to"
            tocopy[#tocopy+1] = list_chunk_start
          else -- even, set new "to"
            if tocopy[#tocopy] == list_chunk_start then
              tocopy[#tocopy+1] = list_chunk_end
            end
          end
          file:seek("set", list_chunk_end)
          list_chunk_found = 1
        elseif string.lower(chunk_header) == "data" then
          data_start = chunk_start
          data_size = chunk_size + 8
          data_end = file:seek("cur", chunk_size)
          if #tocopy % 2 ~= 0 then -- odd ("from"), set "to"
            tocopy[#tocopy+1] = data_end
          else -- even, set new "to"
            tocopy[#tocopy] = data_end
          end
        else -- move on
          local chunk_end = file:seek("cur", chunk_size)
          if #tocopy % 2 ~= 0 then -- odd ("from"), set "to"
            tocopy[#tocopy+1] = chunk_end
          else -- even, set new "to"
            tocopy[#tocopy] = chunk_end
          end
        end
      end
      if tocopy[#tocopy] == tocopy[#tocopy-1] then
        tocopy[#tocopy] = nil
        tocopy[#tocopy] = nil
      end
      if cue_chunk_found == 1 or list_chunk_found == 1 then
        local newfile = io.open(filename .. "cue", "wb")
        newfile:write("RIFF    ")
        for j = 1, #tocopy-1, 2 do
          local START = tocopy[j]
          local END = tocopy[j+1]
          file:seek("set", START)
          if END - START < 2000000 then -- smaller than 2MB
            newfile:write(file:read(END-START))
          else -- bigger than 2MB
            -- read 2MB chunks at a time
            while file:seek() < END do
              if END - file:seek() > 2000000 then
                newfile:write(file:read(2000000))
              else
                newfile:write(file:read(END-file:seek()))
              end
            end
          end
        end
        local new_file_size = newfile:seek("end") - 8
        newfile:seek("set", 4)
        newfile:write(string.pack("I", new_file_size)) -- Chunk Data Size
        newfile:close()
        new_file_exists = true
      end
    end
    io.close(file)
    if new_file_exists then
      -- file substitution
      for i = 1, math.huge do
        if reaper.file_exists( filename .. "cue" ) then
          os.remove(filename) -- delete original file
          os.rename(filename .. "cue", filename) -- rename temporary file as original
          break
        end
      end
    end
  end
end

-------------------------- MAIN FUNCTION ---------------------------------------------------------

local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt > 0 then
  local answer = reaper.MB( "This action cannot be undone! Do you want to remove all cues from the selected items' active takes' source files?", "Warning", 4 )
  if answer ~= 6 then
    return
    reaper.defer(function () end)
  end
  reaper.PreventUIRefresh( 1 )
  reaper.Main_OnCommand(40100, 0) -- Item: Set all media offline
  for i = 0, item_cnt-1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    remove_cues(item)
  end
  reaper.Main_OnCommand(40101, 0) -- Item: Set all media online
  reaper.Main_OnCommand(40441, 0) -- Peaks: Rebuild peaks for selected items
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
  reaper.defer(function () end)
else
 reaper.MB( "Please, select some items first!", "Message", 0 )
  reaper.defer(function () end)
end

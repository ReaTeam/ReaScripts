-- @description amagalma_Remove selected items' active takes' source file cue points (WAV only) - NO UNDO!
-- @author amagalma
-- @version 1.0
-- @about
--   # Deletes all cues points from the wav files (removes cue and list chunks)
--   - works only with WAV files

--------------------------------------------------------------------------------------------------

local reaper = reaper

local function escape_lua_pattern(s)
  local matches =
  {
    ["^"] = "%^";
    ["$"] = "%$";
    ["("] = "%(";
    [")"] = "%)";
    ["%"] = "%%";
    ["."] = "%.";
    ["["] = "%[";
    ["]"] = "%]";
    ["*"] = "%*";
    ["+"] = "%+";
    ["-"] = "%-";
    ["?"] = "%?";
    ["\0"] = "%z";
  }
  return (s:gsub(".", matches))
end

--------------------------------------------------------------------------------------------------

function remove_cues(item)
  local take = reaper.GetActiveTake(item)
  if take and not reaper.TakeIsMIDI( take ) then
    local source = reaper.GetMediaItemTake_Source( take )
    local samplerate = reaper.GetMediaSourceSampleRate( source )
    local filename = reaper.GetMediaSourceFileName( source , "" )
    local file = io.open(filename, "rb")
    file:seek("cur", 4) -- riff_header
    local file_size_buf = file:read(4)
    local cur_pos = file:seek() -- current position in file
    local file_size = string.unpack("I", file_size_buf)
    local wave_header = file:read(4)
    if string.lower(wave_header) == "wave" then
      local cue_chunk_found, list_chunk_found = 0, 0
      local cue_chunk, list_chunk
      while (cue_chunk_found == 0 or list_chunk_found == 0) and file:seek() < file_size do
        local chunk_start = file:seek()
        local chunk_header = file:read(4)
        local chunk_size_buf = file:read(4)
        local chunk_size = string.unpack("I", chunk_size_buf)
        if string.lower(chunk_header) == "cue " then
          cue_chunk = chunk_header .. chunk_size_buf .. file:read(chunk_size)
          cue_chunk_found = 1
        elseif string.lower(chunk_header) == "list" then
          list_chunk = chunk_header .. chunk_size_buf .. file:read(chunk_size)
          list_chunk_found = 1
        else -- move on
          file:seek("cur", chunk_size)
        end      
      end
      if cue_chunk_found == 1 or list_chunk_found == 1 then
        file:seek("set") -- reset to start
        local contents = file:read("*all")
        if cue_chunk_found == 1 then
          contents = string.gsub(contents, escape_lua_pattern(cue_chunk), "") -- remove cue_chunk
        end
        if list_chunk_found == 1 then
          contents = string.gsub(contents, escape_lua_pattern(list_chunk), "") -- remove list_chunk
        end
        -- set correct size chunk size
        local new_file_size = string.len(contents) - 8
        contents = string.gsub(contents, escape_lua_pattern(file_size_buf), string.pack("I", new_file_size))
        -- write to new file
        file = io.open(filename, "wb")
        file:write(contents)
      end
    end
    io.close(file)
  end
end

--------------------------------------------------------------------------------------------------

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

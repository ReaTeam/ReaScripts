-- @description amagalma_Remove selected items' cue points and replace source file (WAV only)
-- @author amagalma
-- @version 1.11
-- @about
--   # Substitutes the source file of each selected item's active take with a duplicate file with the extension " no cues.wav"
--   - works only with WAV files
--   - Smart undo point creation

--[[
@changelog
  # Fix: correct file size written to wav header chunk
--]]

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
        local new_filename = string.match(filename, "(.-)%..+") .. " no cues.wav"
        if not reaper.file_exists( new_filename ) then
          local new_file = io.open(new_filename, "wb")
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
          new_file:write(contents)
          io.close(new_file)
        end
        return new_filename
      end
    end
    io.close(file)
  end
end

--------------------------------------------------------------------------------------------------

local undo = false
local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt > 0 then  
  reaper.PreventUIRefresh( 1 )
  for i = 0, item_cnt-1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    local new_source = remove_cues(item)
    if new_source then
      local take = reaper.GetActiveTake( item )
      reaper.BR_SetTakeSourceFromFile2( take, new_source, false, true )
      local name = string.match(new_source, "\\(.+)$")
      reaper.GetSetMediaItemTakeInfo_String( take, "P_NAME", name, true )
      undo = true
    end
  end
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
  if undo then
    reaper.Undo_OnStateChange( "Remove selected items' cue points (WAV only)" )
  else
    reaper.defer(function () end)
  end
else
  reaper.defer(function () end)
end

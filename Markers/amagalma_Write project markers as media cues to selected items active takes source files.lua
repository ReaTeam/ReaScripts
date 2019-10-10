-- @description amagalma_Write project markers as media cues to selected items' active takes' source files (WAV only)
-- @author amagalma
-- @version 1.02
-- @about
--   # Writes the project markers that cross the selected items as media cues of the selected items' active takes' source files
--   - Overwrites the files
--   - Issues warning if markers are going to appear to other items in the project that share the same source file
--   - To erase an existing media cue, place an unnamed project marker at the position of the cue
-- @changelog
--  # Supports negative project start times

--------------------------------------------------------------------------------------------------

local reaper = reaper
local projsrate
local projoffset = reaper.GetProjectTimeOffset( 0, false )
if reaper.SNM_GetIntConfigVar( "projsrateuse", 0 ) == 1 then 
  projsrate = reaper.SNM_GetIntConfigVar( "projsrate", 0 )
else
  _, projsrate = reaper.GetAudioDeviceInfo( "SRATE", "" )
  projsrate = tonumber(projsrate)
end
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
----------------------------------
local function pairsByKeys (t, f) -- https://www.lua.org/pil/19.3.html
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0 -- iterator variable
  local iter = function () -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end 
----------------------------------
local function pack(number)
  return string.pack("I", number)
end
----------------------------------
local function unpack(number)
  return string.unpack("I", number)
end
----------------------------------
local function len(str)
  return string.len(str)
end
----------------------------------
local function sample_pos(n)
  return tonumber(reaper.format_timestr_pos( n, "", 4 ))
end

--------------------------------------------------------------------------------------------------

local warning = false
local continue = 6
local item_cnt = reaper.CountSelectedMediaItems( 0 )
local _, num_markers = reaper.CountProjectMarkers( 0 )
-- check there are enough selected items
if item_cnt < 1 then
  reaper.MB( "No items selected!", "Action aborted", 0 )
  reaper.defer(function () end)
  return
end
-- check there are enough project markers
if num_markers < 1 then
  reaper.MB( "No project markers present!", "Action aborted", 0 )
  reaper.defer(function () end)
  return
end
-- put apropriate items into a table
local markers_to_write = 0
local items = {}
local sel_item_vis_src = {}
for i = 0, item_cnt-1 do
  local item = reaper.GetSelectedMediaItem(0,i)
  local take = reaper.GetActiveTake(item)
  if take and not reaper.TakeIsMIDI( take ) then
    local source = reaper.GetMediaItemTake_Source( take )
    local samplerate = reaper.GetMediaSourceSampleRate( source )
    local filename = reaper.GetMediaSourceFileName( source , "" )
    local file = io.open(filename, "rb")
    file:seek("cur", 4) -- riff_header
    local file_size_buf = file:read(4)
    local file_size = unpack(file_size_buf)
    local wave_header = file:read(4)
    if string.lower(wave_header) == "wave" then -- Is WAV
      -- find which markers are inside the visible source file portion
      local markers_inside = {}
      local marker_cnt = 0
      local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" ) + projoffset
      local item_end = item_start + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
      local take_offset = reaper.GetMediaItemTakeInfo_Value( take, "D_STARTOFFS" )
      local source_start = item_start - take_offset
      local source_end = source_start + reaper.GetMediaSourceLength( source )
      -- set visible source start & end
      local vis_source_start, vis_source_end
      if source_start < item_start then
        vis_source_start = item_start
      else
        vis_source_start = source_start
      end
      if source_end > item_end then
        vis_source_end = item_end 
      else
        vis_source_end = source_end
      end
      local tocopy = {} -- odd numbers = "from", even numbers = "to"
      tocopy[1] = 8
      -- check if any media cues are present in the source
      local cue_chunk_found, list_chunk_found = 0, 0
      local cue_chunk_start, cue_chunk_end, list_chunk_start, list_chunk_end
      local data_start, data_end, data_size
      local present_markers = {}
      while (cue_chunk_found == 0 or list_chunk_found == 0) and file:seek() < file_size do
        local chunk_start = file:seek()
        local chunk_header = file:read(4)
        local chunk_size_buf = file:read(4)
        local chunk_size = unpack(chunk_size_buf)
        if chunk_size % 2 ~= 0 then -- odd, add padding
          chunk_size = chunk_size + 1
        end
        --[[if string.match(chunk_header, "[\32-\126]") then -- Show chunks found
          reaper.ShowConsoleMsg(chunk_header .. " " .. chunk_start .. " - " ..(chunk_size+8+chunk_start) .. "\n" )
        end--]]
        if string.lower(chunk_header) == "cue " then
          cue_chunk_start = chunk_start
          -- find present markers in item
          local cue_points_cnt = unpack(file:read(4))
          for cp = 1, cue_points_cnt do
            local ID = unpack(file:read(4))
            file:seek("cur", 16)
            local Sample_Offset = unpack(file:read(4))
            present_markers[ID] = {pos = Sample_Offset, name = ""}
            marker_cnt = marker_cnt + 1
          end
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
          file:seek("cur", 4) -- "adtl"
          while file:seek() < chunk_start + chunk_size + 8 do
            local chunk_id = file:read(4)
            if string.lower(chunk_id) == "labl" or string.lower(chunk_id) == "note" then
              local lbl_chunk_data_size = unpack(file:read(4))
              local lbl_cue_point_id = unpack(file:read(4))
              present_markers[lbl_cue_point_id].name = file:read(lbl_chunk_data_size-5)
              if lbl_chunk_data_size % 2 == 0 then -- even, add null termination only
                file:seek("cur", 1)
              else -- odd, add padding and null termination
                file:seek("cur", 2)
              end
            elseif string.lower(chunk_id) == "ltxt" then
              -- not supported
            end
          end
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
        --[[elseif string.match(chunk_header, "[^\32-\126]") then
          -- header is not an ASCII printable character, go back a bit and read again
          file:seek("cur" , -4)--]]
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
      -- add present markers (cues) that are not on the same position as (new) project markers
      for pm = 1, #present_markers do
        markers_inside[present_markers[pm].pos] = present_markers[pm].name
      end
      -- find which markers are inside the visible source start and length
      local max_mrk_pos, min_mrk_pos = 0, false
      local new_item_markers = 0
      for m = 0, num_markers-1 do
        local _, _, marker_pos, _, marker_name = reaper.EnumProjectMarkers( m )
        marker_pos = marker_pos + projoffset
        if marker_pos >= vis_source_start and marker_pos <= vis_source_end then
          local pos = sample_pos((marker_pos-source_start)*(samplerate/projsrate)) - projoffset*projsrate-- position in samples
          -- it's inside, check if it is new
          if not markers_inside[pos] then
            -- new marker, add
            markers_inside[pos] = marker_name
            markers_to_write = markers_to_write + 1
            new_item_markers = new_item_markers + 1
            marker_cnt = marker_cnt + 1
            -- store min & max position of markers
            if not min_mrk_pos then
              min_mrk_pos, max_mrk_pos = pos, pos
            elseif pos > max_mrk_pos then
              max_mrk_pos = pos
            end
          else
            -- exists, check if it brings a new name. If blank then erase
            if marker_name ~= "" then
              if markers_inside[pos] ~= marker_name then
                markers_inside[pos] = marker_name
                markers_to_write = markers_to_write + 1
                new_item_markers = new_item_markers + 1
                -- store min & max position of markers
                if not min_mrk_pos then
                  min_mrk_pos, max_mrk_pos = pos, pos
                elseif pos > max_mrk_pos then
                  max_mrk_pos = pos
                end
              end
            else -- erase marker
              markers_inside[pos] = nil
              markers_to_write = markers_to_write + 1
              new_item_markers = new_item_markers + 1
              marker_cnt = marker_cnt - 1
              -- store min & max position of markers
              if not min_mrk_pos then
                min_mrk_pos, max_mrk_pos = pos, pos
              elseif pos > max_mrk_pos then
                max_mrk_pos = pos
              end
            end
          end
        end
      end
      -- add information to table of items that have changes
      if new_item_markers > 0 then
        items[#items+1] = 
        {
        src = source,
        marker = markers_inside,
        file = filename,
        new_markers = new_item_markers,
        mrk_cnt = marker_cnt,
        --cue_start = cue_chunk_start,
        --cue_end = cue_chunk_end,
        --list_start = list_chunk_start,
        --list_end = list_chunk_end,
        --data_start = data_start,
        --data_end = data_end,
        --data_sz = data_size,
        copy = tocopy
        }
        -- Store the maximum portions of the file sources that are visible for each selected item
        if not warning then
          local guid = reaper.BR_GetMediaItemTakeGUID( take )
          if sel_item_vis_src[filename] then
            if source_start ~= sel_item_vis_src[filename].pos then
              warning = true
            else -- store maximum visible values
              if vis_source_start - source_start < sel_item_vis_src[filename].from then
                sel_item_vis_src[filename].from = vis_source_start - source_start
              end
              if vis_source_end - source_start > sel_item_vis_src[filename].to then
                sel_item_vis_src[filename].to = vis_source_end - source_start
              end
              sel_item_vis_src[filename][guid] = true
              sel_item_vis_src[filename].max = max_mrk_pos
              sel_item_vis_src[filename].min = min_mrk_pos
            end
          else
            sel_item_vis_src[filename] = {from = vis_source_start - source_start , to = vis_source_end - source_start, pos = source_start}
            sel_item_vis_src[filename][guid] = true
            sel_item_vis_src[filename].max = max_mrk_pos
            sel_item_vis_src[filename].min = min_mrk_pos
          end
        end
      end
    end
    file:close()
  end
end
-- check there are enough items to work on
--reaper.ShowConsoleMsg("Markers to write: " .. markers_to_write .. "\n")
if markers_to_write == 0 then
  reaper.MB( "No markers can be embedded to the selected items", "Action aborted", 0 )
  reaper.defer(function () end)
  return
end

-- Find the portions of the file sources that are visible for all items and compare to the selected items

if not warning then
  local all_item_cnt = reaper.CountMediaItems( 0 )
  for i = 0, all_item_cnt-1 do
    local item = reaper.GetMediaItem(0,i)
    local take = reaper.GetActiveTake(item)
    if take and not reaper.TakeIsMIDI( take ) then
      local guid = reaper.BR_GetMediaItemTakeGUID( take )
      local source = reaper.GetMediaItemTake_Source( take )
      local filename = reaper.GetMediaSourceFileName( source , "" )
      if sel_item_vis_src[filename] and not sel_item_vis_src[filename][guid] then
        local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION"  )
        local item_end = item_start + reaper.GetMediaItemInfo_Value( item, "D_LENGTH"  )
        local take_offset = reaper.GetMediaItemTakeInfo_Value( take, "D_STARTOFFS" )
        local source_start = item_start - take_offset
        local source_end = source_start + reaper.GetMediaSourceLength( source )
        -- set visible source start & end
        local vis_source_start, vis_source_end
        if source_start < item_start then
          vis_source_start = item_start
        else
          vis_source_start = source_start
        end
        if source_end > item_end then
          vis_source_end = item_end 
        else
          vis_source_end = source_end
        end
        vis_source_start = sample_pos(vis_source_start - source_start)
        vis_source_end = sample_pos(vis_source_end - source_start)
        -- warn if the markers are going to be visible in this item
        if (sel_item_vis_src[filename].min >= vis_source_start and sel_item_vis_src[filename].min <= vis_source_end)
        or (sel_item_vis_src[filename].max >= vis_source_start and sel_item_vis_src[filename].max <= vis_source_end)
        then
          warning = true
          break        
        end
      end
    end  
  end
end
if warning then
  local msg =
  "The selected items refer to audio files that are used elsewhere in the project, OR the selected items refer to the same audio file. This will result in cues appearing in items elsewhere in the project.\n\nDo you want to continue?\n\n[ In case you continue and don't like the result, you can undo using script\n\"amagalma_Remove selected items' active takes' source file cue points (WAV only) - NO UNDO.lua\" ]"
  continue = reaper.MB( msg, "Warning", 4 )
end
if continue ~= 6 then
  return
end

-- CREATE NEW SOURCE FILES --
reaper.PreventUIRefresh( 1 )
reaper.Main_OnCommand(40100, 0) -- Item: Set all media offline
for i = 1, #items do
  local filename = reaper.GetMediaSourceFileName( items[i].src , "" )
  local file = io.open(filename, "rb")
  local newfile = io.open(filename .. "cue", "wb")
  newfile:write("RIFF    ")
  for j = 1, #items[i].copy-1, 2 do
    local START = items[i].copy[j]
    local END = items[i].copy[j+1]
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
  if items[i].mrk_cnt > 0 then -- cue and list chunks will exist
    local cue_chunk = {}
    local list_chunk = {}
    cue_chunk[1] = "cue " -- Chunk ID
    cue_chunk[2] = pack((items[i].mrk_cnt * 24) + 4) -- Chunk Data Size
    cue_chunk[3] = pack(items[i].mrk_cnt) -- Num Cue Points
    list_chunk[1] = "" -- reserved for later (Chunk ID)
    list_chunk[2] = "" -- reserved for later (Chunk Data Size)
    list_chunk[3] = "adtl" -- Type ID
    local ID = 0
    for pos,name in pairsByKeys(items[i].marker) do
      ID = ID + 1
      -- create cue chunk table
      cue_chunk[#cue_chunk+1] = pack(ID) -- ID
      cue_chunk[#cue_chunk+1] = pack("0") -- Position
      cue_chunk[#cue_chunk+1] = "data" -- Data Chunk ID
      cue_chunk[#cue_chunk+1] = pack("0") -- Chunk Start
      cue_chunk[#cue_chunk+1] = pack("0") -- Block Start
      cue_chunk[#cue_chunk+1] = pack(pos) -- Sample Offset
      -- create list chunk table
      list_chunk[#list_chunk+1] = "labl" -- Chunk ID
      local final_name = name .. "\0"
      list_chunk[#list_chunk+1] = pack(len(final_name) + 4) -- Chunk Data Size
      list_chunk[#list_chunk+1] = pack(ID) -- Cue Point ID
      if len(final_name) % 2 ~= 0 then -- odd, add padding
        final_name = final_name .. "\0"
      end
      list_chunk[#list_chunk+1] = final_name -- Text
    end
    local list_chunk_size = len(table.concat(list_chunk))
    list_chunk[2] = pack(list_chunk_size) -- Chunk Data Size
    list_chunk[1] = "list" -- ID
    local new_cue_chunk = table.concat(cue_chunk)
    local new_list_chunk = table.concat(list_chunk)
    newfile:write(new_cue_chunk)
    newfile:write(new_list_chunk)
  end
  local new_file_size = newfile:seek("end") - 8
  newfile:seek("set", 4)
  newfile:write(pack(new_file_size)) -- Chunk Data Size
  file:close()
  newfile:close()
  -- file substitution
  for i = 1, math.huge do
    if reaper.file_exists( filename .. "cue" ) then
      retvalf, errorf = os.remove(filename) -- delete original file
      os.rename(filename .. "cue", filename) -- rename temporary file as original
      break
    end
  end
end
reaper.Main_OnCommand(40101, 0) -- Item: Set all media online
reaper.Main_OnCommand(40441, 0) -- Peaks: Rebuild peaks for selected items
reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()
reaper.defer(function () end)

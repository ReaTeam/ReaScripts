-- @description amagalma_Add project markers as cue points to selected items and replace source files
-- @author amagalma
-- @version 1.0
-- @about
--   # Opens a temporary project and renders the selected items with project markers as cues. Temp project gets deleted and replaces the active takes of the selected items with the rendered ones.
--   - Project must be saved for action to run
--   - Smart undo point creation

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
local function sleep(s) -- http://lua-users.org/wiki/SleepFunction
  local ntime = os.clock() + s
  repeat until os.clock() > ntime
end

--------------------------------------------------------------------------------------------------

local function cue_points_to_markers(take, offset) -- Only Markers are supported
  if not offset then offset = 0 end
  local marker_indexes = {}
  local source = reaper.GetMediaItemTake_Source( take )
  local samplerate = reaper.GetMediaSourceSampleRate( source )
  local filename = reaper.GetMediaSourceFileName( source , "" )
  local file = io.open(filename, "rb")
  local item = reaper.GetMediaItemTake_Item( take )
  file:seek("cur", 4) -- riff_header
  local file_size_buf = file:read(4)
  local cur_pos = file:seek() -- current position in file
  local file_size = unpack(file_size_buf)
  local wave_header = file:read(4)
  if string.lower(wave_header) == "wave" then
    local cue_chunk_found, list_chunk_found = 0, 0
    local cue_chunk, list_chunk
    local Position_sec = {}
    local Text = {}
    while (cue_chunk_found == 0 or list_chunk_found == 0) and file:seek() < file_size do
      local chunk_start = file:seek()
      local chunk_header = file:read(4)
      local chunk_size_buf = file:read(4)
      local chunk_size = unpack(chunk_size_buf)
      if string.lower(chunk_header) == "cue " then
        local cue_points_cnt = unpack(file:read(4))
        for i = 1, cue_points_cnt do
          local ID = unpack(file:read(4))
          file:seek("cur", 16)          
          Position_sec[ID] = unpack(file:read(4)) / samplerate
        end
        cue_chunk_found = 1
      elseif string.lower(chunk_header) == "list" then
        file:seek("cur", 4) -- "adtl"
        while file:seek() < chunk_start + chunk_size + 8 do
          local chunk_id = file:read(4)
          if string.lower(chunk_id) == "labl" or string.lower(chunk_id) == "note" then
            local lbl_chunk_data_size = unpack(file:read(4))
            local lbl_cue_point_id = unpack(file:read(4))
            Text[lbl_cue_point_id] = file:read(lbl_chunk_data_size-5)
            if lbl_chunk_data_size % 2 == 0 then -- even, add null termination only
              file:seek("cur", 1)
            else -- odd, add padding and null termination
              file:seek("cur", 2)
            end
          elseif string.lower(chunk_id) == "ltxt" then
            -- not supported yet
          end
        end
        list_chunk_found = 1
      else -- move on
        file:seek("cur", chunk_size)
      end      
    end
    if #Position_sec > 0 then
      local item_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local start_in_source = reaper.GetMediaItemTakeInfo_Value( take, "D_STARTOFFS" )
      local source_pos = item_pos - start_in_source
      for i = 1, #Position_sec do
        local index = reaper.AddProjectMarker( 0, false, offset + source_pos + Position_sec[i], 0, Text[i] or "", -1 )
        marker_indexes[#marker_indexes+1] = index
      end
    end
  end
  io.close(file)
  if #marker_indexes > 0 then
    return marker_indexes
  else
    return nil
  end
end

--------------------------------------------------------------------------------------------------

-- INITIAL TESTS

local item_cnt = reaper.CountSelectedMediaItems( 0 )
local _, num_markers = reaper.CountProjectMarkers( 0 )
local _, projfn = reaper.EnumProjects( -1, "" )

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

-- check project is saved
if projfn == "" then
  reaper.MB( "Save project and run action again", "Unsaved project!", 0 )
  reaper.Main_OnCommand(40022, 0) -- File: Save project as...
  reaper.defer(function () end)
  return
else
  reaper.Main_SaveProject( projfn, false )
end

-- check that markers cross selected items
local final_test = false
for i = 0, item_cnt - 1 do
  local item = reaper.GetSelectedMediaItem(0, 0)
  local take = reaper.GetActiveTake( item )
  if take and not reaper.TakeIsMIDI( take ) then
    -- find if project markers are inside selected items
    local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION"  )
    local item_end = item_start + reaper.GetMediaItemInfo_Value( item, "D_LENGTH"  )
    for m = 0, num_markers - 1 do
      local _, _, marker_pos = reaper.EnumProjectMarkers( m )
      if marker_pos >= item_start and marker_pos <= item_end then
        final_test = true
        break
      end
    end
  end
end
if not final_test then
  reaper.MB( "No project markers cross any of the selected items!", "Action aborted", 0 )
  reaper.defer(function () end)
  return 
end

----------------------------------

-- If ALL OK, PROCEED

-- Create duplicate project with no FX and the extension " noFX for Cues.RPP"
local t = {}
local APPLYFX_CFG
local write, masterfx, fxchain, takefx, br = true, false, false, false, 0
local file = io.open(projfn, "r" )
-- Put current file into table, without any FX
for line in file:lines() do
  if string.match(line, "<REAPER_PROJECT") then
    line = '<REAPER_PROJECT 0.1 "' .. reaper.GetAppVersion() .. '" ' .. tostring(os.time() + 1)
  elseif string.match(line, "<APPLYFX_CFG") then
    APPLYFX_CFG = #t+2
  elseif string.match(line, "USE_REC_CFG %d") then
    line = "  USE_REC_CFG 1"
  end
  if string.match(line, "<MASTERFXLIST") then
    masterfx = true
  elseif string.match(line, "<FXCHAIN") then
    fxchain = true
  elseif string.match(line, "<TAKEFX") then
    takefx = true
  end
  if masterfx or fxchain or takefx then
    write = false
    for symbol in string.gmatch(line, "<") do
      br = br + 1
    end
    for symbol in string.gmatch(line, ">") do
      br = br - 1
    end
  else
    write = true
  end
  if br == 0 then
    masterfx = false
    fxchain = false
    takefx = false
  end
  if write then
    t[#t+1] = line
  end
end
io.close(file)
t[APPLYFX_CFG] = "    ZXZhdyBMAA==" -- WAV 32bit FP, Write BWF and Markers only
-- Create new file
local filename = string.gsub(projfn, ".RPP", " noFX for Cues.RPP")
file = io.open(filename, "w")
  file:write(table.concat(t, "\n"))
io.close(file)
-- Open duplicate project
reaper.Main_OnCommand(40859, 0) -- New project tab
reaper.Main_openProject( filename )
sleep(0.5) -- freeze to let the project load

----------------------------------

-- Get items of both projects
local oldproject, oldproject_name = reaper.EnumProjects( 0, "" )
item_cnt = reaper.CountMediaItems( oldproject )
local init_sel_items = {}
local take_index = {}
for i = 0, item_cnt - 1 do
  local item = reaper.GetMediaItem( oldproject, i )
  if reaper.IsMediaItemSelected( item ) then
    init_sel_items[#init_sel_items+1] = item
    take_index[#take_index+1] = reaper.GetMediaItemInfo_Value( item, "I_CURTAKE" )
  end
end

local newproject, newproject_name = reaper.EnumProjects( 1, "" )
item_cnt = reaper.CountMediaItems( newproject )
local sel_items = {}
for i = 0, item_cnt - 1 do
  local item = reaper.GetMediaItem( newproject, i )
  if reaper.IsMediaItemSelected( item ) then
    sel_items[#sel_items+1] = item
  end
end
reaper.SelectAllMediaItems( newproject, false )

-- Render items with markers
local undo = false
reaper.PreventUIRefresh( 1 )
for i = 1, #sel_items do
  local render = false
  local item = sel_items[i]
  local take = reaper.GetActiveTake( item )
  if take and not reaper.TakeIsMIDI( take ) then
    -- find if project markers are inside selected items
    local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION"  )
    local item_end = item_start + reaper.GetMediaItemInfo_Value( item, "D_LENGTH"  )
    for m = 0, num_markers - 1 do
      local _, _, marker_pos = reaper.EnumProjectMarkers( m )
      if marker_pos >= item_start and marker_pos <= item_end then
        render = true
      end
    end
    if render then
      reaper.SetMediaItemSelected( item, true ) -- select only this item
      --local offset = reaper.GetMediaItemTakeInfo_Value( take, "D_STARTOFFS" )
      local indexes = cue_points_to_markers( take ) -- Convert existing cues to markers
      reaper.Main_OnCommand(41999, 0) -- Item: Render items to new take
      sleep(0.5)
      if indexes then
        for index = 1, #indexes do
          reaper.DeleteProjectMarker( 0, indexes[index], false ) -- Delete added project markers
        end
      end
      reaper.Main_OnCommand( 40131, 0 ) -- Take: Crop to active take in items
      take = reaper.GetActiveTake( item )
      undo = true
      reaper.SetMediaItemSelected( item, false ) -- unselect item
      -- set the sources of the initial items to be the same as the sources of new project items
      local source = reaper.GetMediaItemTake_Source( take )
      local filename = reaper.GetMediaSourceFileName( source, "" )
      local olditem = reaper.GetSelectedMediaItem( oldproject, i-1)      
      local oldtake = reaper.GetMediaItemTake( olditem, take_index[i] )
      local _, item_chunk = reaper.GetItemStateChunk( olditem, "", false )
      local chunk_table = {}
      for line in item_chunk:gmatch('[^\n]+') do
        chunk_table[#chunk_table+1] = line
      end
      local _, take_guid = reaper.GetSetMediaItemTakeInfo_String( oldtake, "GUID", "", false )
      local guid_line = 0
      for i = #chunk_table, 1, -1 do
        if string.match(chunk_table[i], escape_lua_pattern(reaper.guidToString( take_guid, "" ))) then
          guid_line = i
          break
        end
      end
      for i = guid_line + 1, #chunk_table do
        if string.match(chunk_table[i], 'FILE "') then
          chunk_table[i] = 'FILE "' .. filename .. '"'
        end
      end
      item_chunk = table.concat(chunk_table, "\n")
      reaper.SetItemStateChunk( olditem, item_chunk, false )
      reaper.SetMediaItemTakeInfo_Value( reaper.GetActiveTake(olditem), "D_STARTOFFS", 0 )
      reaper.Main_OnCommand( 41858, 0 ) -- Item: Set item name from active take filename
    end
  end
end
reaper.Main_SaveProject( newproject, false )
reaper.Main_OnCommand(40860, 0) -- Close current project tab
os.remove(newproject_name)
if reaper.file_exists( newproject_name .. "-bak") then
  os.remove(newproject_name .. "-bak")
end
reaper.PreventUIRefresh( -1 )
reaper.UpdateTimeline()
if undo then
  reaper.Undo_OnStateChange( "Write cue markers to items" )
end

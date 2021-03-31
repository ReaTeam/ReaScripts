-- @description Rename takes and item notes with BWF and iXML metadata
-- @author Rodilab
-- @version 1.2
-- @changelog Update : Read the iXML Track List metadata
-- @about
--   For BWF selected items : Set custom name with $wildcards for rename active take and set new notes.
--   First text-box for Take Name, second text-box for Item Notes (if empty, then don't change).
--   Look "User Config Area" on the top of script to :
--   - Add, remove or edit $wildcards (and metadata fields identifiers)
--   - Enable/Disable popup message box (if disable, set last default)
--
--   $bitdepth, $chnl, $circled, $date, $falsestart, $fileindex, $filename, $filetyp, $nogood, $note, $originator, $originatorref, $project, $reaname, $reaproject, $reatrack, $samplerate, $scene, $speed, $startoffsset, $tag, $take, $taketyp, $tape, $tcstart, $time, $timeref, $totalfiles, $trackcount, $trackname, $ubits, $wildtrack
--
--   by Rodrigo Diaz (aka Rodilab)

--------------------------------------------------------------------------------------
-- User Config Area ------------------------------------------------------------------
--------------------------------------------------------------------------------------
trackname_separator_1 = ":" -- Separator between Track Number and Track Name
trackname_separator_2 = " / " -- Separator between each track
circled_marker = "*"
wildtrack_marker = "WildTrack!"
nogood_marker = "NoGood!"
falsestart_marker = "FalseStart!"
message_box = true -- Popup message box (if not, set default value)
separator = "~" -- This special character is prohibited in the message box
key_char = "$"
list_tags = {
  -- Reaper Infos
  reaproject={"Reaper:Project"},
  reaname={"Reaper:TakeName"},
  reatrack={"Reaper:TrackName"},
  -- BWF
  startoffsset={"Generic:StartOffset"},
  date={"BWF:OriginationDate","IXML:BEXT:BWF_ORIGINATION_DATE"},
  time={"BWF:OriginationTime","IXML:BEXT:BWF_ORIGINATION_TIME"},
  timeref={"BWF:TimeReference","IXML:BEXT:BWF_TIME_REFERENCE_LOW","IXML:SPEED:TIMESTAMP_SAMPLES_SINCE_MIDNIGHT_LO"},
  originatorref={"BWF:OriginatorReference","IXML:BEXT:BWF_ORIGINATOR_REFERENCE"},
  originator={"BWF:Originator","IXML:BEXT:BWF_ORIGINATOR"},
  -- BWF:Description
  scene={"aSCENE","sSCENE","IXML:SCENE"},
  take={"aTAKE","sTAKE","IXML:TAKE"},
  note={"aNOTE","sNOTE","IXML:NOTE"},
  filename={"aFILENAME","sFILENAME","IXML:HISTORY:ORIGINAL_FILENAME","IXML:HISTORY:CURRENT_FILENAME"},
  speed={"aSPEED","sSPEED"},
  filetyp={"aTYP","sTYP"},
  tag={"aTAG","sTAG"},
  ubits={"aUBITS","sUBITS","IXML:UBITS"},
  circled={"aCIRCLED","sCIRCLED","IXML:CIRCLED"},
  wildtrack={"aWILDTRACK","sWILDTRACK","IXML:WILD_TRACK","IXML:TAKE_TYPE"},
  tape={"aTAPE","sTAPE","IXML:TAPE"},
  chnl={"aCHNL"},
  trackname={"aTRK","sTRK"},
  -- only in iXML
  project={"IXML:PROJECT"},
  taketyp={"IXML:TAKE_TYPE"},
  nogood={"IXML:NO_GOOD","IXML:TAKE_TYPE"},
  falsestart={"IXML:FALSE_START","IXML:TAKE_TYPE"},
  totalfiles={"IXML:FILE_SET:TOTAL_FILES"},
  fileindex={"IXML:FILE_SET:FILE_SET_INDEX"},
  bitdepth={"IXML:SPEED:AUDIO_BIT_DEPTH"},
  samplerate={"IXML:SPEED:FILE_SAMPLE_RATE"},
  trackcount={"IXML:TRACK_LIST:TRACK_COUNT"},
  tcstart={"IXML:SPEED:TIMECODE_RATE"}
}

---------------------------------------------------------------------------------
--- Ext State -------------------------------------------------------------------
---------------------------------------------------------------------------------

conf = {}

extstate_id = "RODILAB_Rename_takes_and_item_notes_with_BWF_and_iXML_metadata"
function ExtState_Load()
  local def = {
    default_name = "$scene-$take$circled ($trackname)",
    default_notes = "$note",
    popup_wildcards = "true"
    }
  for key in pairs(def) do
    if reaper.HasExtState(extstate_id,key) then
      conf[key] = reaper.GetExtState(extstate_id,key)
    else
      conf[key] = def[key]
    end
  end
end

function ExtState_Save(default_text)
  conf.default_name = default_text:match("(.+)"..separator) or ""
  conf.default_notes = default_text:match(separator.."(.+)") or ""
  for key in pairs(conf) do reaper.SetExtState(extstate_id, key, conf[key], true) end
end

---------------------------------------------------------------------------------
-- Function : Search tag in a list ----------------------------------------------
---------------------------------------------------------------------------------
local function search(list_chunk,list_metadata)
  for i, tag in ipairs(list_chunk) do
    if not list_metadata[tag] and i == #list_chunk then
      return nil
    elseif list_metadata[tag] then
      return list_metadata[tag]
    end
  end
end

---------------------------------------------------------------------------------
-- Function : Time Code Start ---------------------------------------------------
---------------------------------------------------------------------------------

local function get_tc_start(source,list_metadata)
  local tc_rate = search(list_tags["tcstart"],list_metadata)
  local samplerate =  reaper.GetMediaSourceSampleRate(source)
  local _,ssm = reaper.GetMediaFileMetadata(source,"BWF:TimeReference")
  if tc_rate and samplerate and ssm then
    for k, v in string.gmatch(tc_rate, "(%d+)/(%d+)") do
      tc_rate = k/v
    end
    if tc_rate then
      local calc = (ssm/samplerate)/3600
      local heures = math.floor(calc)
      calc = (calc-heures)*60
      local minutes = math.floor(calc)
      calc = (calc-minutes)*60
      local secondes = math.floor(calc)
      local images = math.floor((calc-secondes)/(1/tc_rate))

      if images < 10 then
        images = "0"..images
      end
      return heures..":"..minutes..":"..secondes..":"..images
    end
  end
end

---------------------------------------------------------------------------------
-- Function : Get all tracks names ----------------------------------------------
---------------------------------------------------------------------------------
local function get_all_track_names(take, key, list_metadata, source)
  -- Set all track names in a list
  local tracks_names_list = {}
  local retval, tracklist_count = reaper.GetMediaFileMetadata(source,"IXML:TRACK_LIST:TRACK_COUNT")
  if retval == 1 then
    for i=1, tracklist_count do
      local tracklist_interleave = ""
      if i > 1 then
        tracklist_interleave = tracklist_interleave..":"..i
      end
      local retval, tracklist_index = reaper.GetMediaFileMetadata(source,"IXML:TRACK_LIST:TRACK:CHANNEL_INDEX"..tracklist_interleave)
      if retval == 1 then
        local retval, tracklist_name = reaper.GetMediaFileMetadata(source,"IXML:TRACK_LIST:TRACK:NAME"..tracklist_interleave)
        if retval ~= 1 then
          tracklist_name = "?"
        end
          table.insert(tracks_names_list,tracklist_index..trackname_separator_1..tracklist_name)
      end
    end
  else
    -- No IXML Track List
    -- Search in BWF Comment
    for i=1, 64 do
      for w, k in ipairs(key) do
        local search_trk = search({k..i},list_metadata)
        if search_trk then
          table.insert(tracks_names_list,i..trackname_separator_1..search_trk)
        end
      end
    end
  end
  -- If any track names exist
  local count_tracks_names = #tracks_names_list
  if count_tracks_names > 0 then
    -- Get real take chanmode
    local take_chanmode = reaper.GetMediaItemTakeInfo_Value(take,"I_CHANMODE")
    local take_channels = 0
    if take_chanmode >= 2 and take_chanmode <= 66 then
      -- Mono
      take_channels = 1
      chanel_offset = take_chanmode - 3
    elseif take_chanmode > 66 then
      -- Stereo
      take_channels = 2
      chanel_offset = take_chanmode - 67
    else
      take_channels = count_tracks_names
      chanel_offset = 0
    end
    -- Set track_name with all tracks names
    local track_name = ""
    for i=1, take_channels do 
      if take_chanmode == 1 and count_tracks_names > 1 and i == 1 then
        -- Invert channel 1 and 2
        if tracks_names_list[2] then
          track_name = track_name..tracks_names_list[2]
        else
          track_name = track_name.."?"
        end
      elseif take_chanmode == 1 and count_tracks_names > 1 and i == 2 then
        -- Invert channel 1 and 2
        if tracks_names_list[1] then
          track_name = track_name..tracks_names_list[1]
        else
          track_name = track_name.."?"
        end
      else
        -- Normal order
        if tracks_names_list[i+chanel_offset] then
          track_name = track_name..tracks_names_list[i+chanel_offset]
        else
          track_name = track_name.."?"
        end
      end
      -- Add separator if isn't last track name
      if take_channels > 1 and i < take_channels then
        track_name = track_name..trackname_separator_2
      end
    end
    return(track_name)
  else
    return(nil)
  end
end

---------------------------------------------------------------------------------
-- Main Function ----------------------------------------------------------------
---------------------------------------------------------------------------------
function main(input)
  reaper.Undo_BeginBlock()

  for i=0, count-1 do
    -- Get item, take and source
    local item = reaper.GetSelectedMediaItem(0,i)
    local take = reaper.GetActiveTake(item)
    if take then
      local source = reaper.GetMediaItemTake_Source(take)
      if reaper.GetMediaSourceType(source,"") == "WAVE" then
        local source_chan = reaper.GetMediaSourceNumChannels(source)
        local text = input

        local list_metadata = {}
        -- Set some Reaper data
        list_metadata["Reaper:Project"] = reaper.GetProjectName(0,"")
        list_metadata["Reaper:TakeName"] = reaper.GetTakeName(take)
        _, list_metadata["Reaper:TrackName"] = reaper.GetTrackName(reaper.GetMediaItemTrack(item))

        -- Get "BWF:Description" metadata list
        local retval, description = reaper.GetMediaFileMetadata(source,"BWF:Description")
        if retval then
          for w in string.gmatch(description, "([^\n\r]+)") do
            for k, v in string.gmatch(w, "(.+)=(.+)") do
              list_metadata[k] = v
            end
          end
        end

        -- Search key in text (invert alphabetically order)
        for i,key in ipairs(sort_keys) do
          i = #sort_keys - i + 1
          key = sort_keys[i]
          for _, tags in pairs(list_tags[key]) do
            if string.find(text,key_char..key) then

              -- Add metadata value (if not already isset)
              for w, k in ipairs(list_tags[key]) do
                if not list_metadata[k] then
                  local retval, value = reaper.GetMediaFileMetadata(source,k)
                  if retval and value ~= "" then
                    list_metadata[k] = value
                  end
                end
              end

              -- Get metadata value
              local value = nil
              if key == "trackname" then
                value = get_all_track_names(take,list_tags[key],list_metadata,source)
              elseif key == "tcstart" then
                value = get_tc_start(source,list_metadata)
              else
                value = search(list_tags[key],list_metadata)
              end

              if value then
                if key == "scene" or key == "take" then
                  value = string.gsub(value,"%s+","")
                elseif key == "wildtrack" then
                  if value == "TRUE" or value == "WILD_TRACK" then
                    value = wildtrack_marker
                  else
                    value = ""
                  end
                elseif key == "nogood" then
                  if value == "TRUE" or value == "NO_GOOD" then
                    value = nogood_marker
                  else
                    value = ""
                  end
                elseif key == "falsestart" then
                  if value == "TRUE" or value == "FALSE_START" then
                    value = falsestart_marker
                  else
                    value = ""
                  end
                elseif key == "circled" then
                  if value == "TRUE" then
                    value = circled_marker
                  else
                    value = ""
                  end
                end
                value = string.gsub(value,"\n\r","")
                value = string.gsub(value,separator,"") --  Prevent double separator
                text = text:gsub(key_char..key,value)
              else
                text = text:gsub(key_char..key,"")
              end -- End if value ~= nil
            end -- End if key is find in text
          end -- End for list_tags
        end -- End for sort_key

        -- Split text in New_name and New_note on separator
        text = text:gsub("\r\n","")
        new_name = text:match("(.+)"..separator)
        new_note = text:match(separator.."(.+)")

        -- Rename take
        if new_name then
          local new_name_spaces = string.gsub(new_name,"%s+","")
          if new_name ~= "" and new_name_spaces ~= "" then
            reaper.GetSetMediaItemTakeInfo_String(take,"P_NAME",new_name,true)
          end
        end
        -- Set item notes
        if new_note and new_note ~= "" then
          local new_note_spaces = string.gsub(new_note,"%s+","")
          if new_note ~= "" and new_note_spaces ~= "" then
            reaper.GetSetMediaItemInfo_String(item,"P_NOTES",new_note,true)
          end
        end
      end -- End source type is "WAVE"
    end -- End active take isset
  end -- End for selected items
  reaper.Undo_EndBlock(script_name, -1)
end

---------------------------------------------------------------------------------
-- DO IT ------------------------------------------------------------------------
---------------------------------------------------------------------------------

count = reaper.CountSelectedMediaItems(0)
if count > 0 then
  script_name = "Rename takes and item notes with BWF and iXML metadata"

  -- Sort keys alphabetically
  sort_keys = {}
  for key,_ in pairs(list_tags) do
    table.insert(sort_keys,key)
  end
  table.sort(sort_keys)

  ExtState_Load()

  if conf.popup_wildcards == "true" then
    local message_keys = ""
    for i,key in ipairs(sort_keys) do
      message_keys = message_keys..key_char..key.."\n"
    end
    message_keys = message_keys.."\nShow this list next time ?"
    local retval = reaper.ShowMessageBox("Available keys :\n\n"..message_keys,script_name,4)
    if retval == 7 then
      conf.popup_wildcards = "false"
    end
  end

  local default_text = conf.default_name..separator..conf.default_notes
  if message_box then
    retval, default_text = reaper.GetUserInputs(
      script_name,2,"Take Name,Item Notes,extrawidth=200,separator="..separator,default_text)
  end
  if retval or not message_box then
    local _, count_separator = string.gsub(default_text,separator,"")
    if count_separator == 1 then
      ExtState_Save(default_text)
      reaper.PreventUIRefresh(1)
      main(default_text)
      reaper.PreventUIRefresh(-1)
      reaper.UpdateArrange()
    else
      reaper.ShowMessageBox("Error: The \""..separator.."\" character is not allowed.",script_name,0)
    end
  end
end

-- @description Rename takes and item notes with BWF and iXML metadata
-- @author Rodilab
-- @version 1.0
-- @about
--   For WAVE selected items : Rename active take and set new notes with BWF and iXML metadatas.
--   Set cutom name with #Wildcards.
--   First text-box for Take Name, second text-box for Item Notes (if empty, then don't change)
--   Look "User Config Area" on the top of script to :
--   - Customize default name, notes, separators, markers etc...
--   - Add, remove or edit #Wildcards keys
--   - Add, remove or edit BWF metadata fields for each #Wildcard
--   - Enable/Disable popup message box (if disable, set default)
--
--   by Rodrigo Diaz (aka Rodilab)

--------------------------------------------------------------------------------------
-- User Config Area ------------------------------------------------------------------
--------------------------------------------------------------------------------------
default_name = "#Scene-#Take#Circled (#TrackName)"
default_notes = "#Note"
trackname_separator_1 = ":" -- Separator between Track Number and Track Name
trackname_separator_2 = " / " -- Separator between each track
cercled_marker = "*"
wildtrack_marker = "WildTrack!"
nogood_marker = "NoGood!"
falsestart_marker = "FalseStart!"
message_box = true -- Popup message box (if not, set default value)
separator = "~" -- This special character is prohibited in the message box
key_char = "#"
list_tags = {
  -- Reaper Infos
  ReaProject={"Reaper:Project"},
  ReaName={"Reaper:TakeName"},
  ReaTrack={"Reaper:TrackName"},
  -- BWF
  StartOffSset={"Generic:StartOffset"},
  Date={"BWF:OriginationDate","IXML:BEXT:BWF_ORIGINATION_DATE"},
  Time={"BWF:OriginationTime","IXML:BEXT:BWF_ORIGINATION_TIME"},
  TimeRef={"BWF:TimeReference","IXML:BEXT:BWF_TIME_REFERENCE_LOW"},
  OriginatorRef={"BWF:OriginatorReference","IXML:BEXT:BWF_ORIGINATOR_REFERENCE"},
  Originator={"BWF:Originator","IXML:BEXT:BWF_ORIGINATOR"},
  -- BWF:Description
  Scene={"aSCENE","sSCENE","IXML:SCENE"},
  Take={"aTAKE","sTAKE","IXML:TAKE"},
  Note={"aNOTE","sNOTE","IXML:NOTE"},
  Filename={"aFILENAME","sFILENAME","IXML:HISTORY:ORIGINAL_FILENAME","IXML:HISTORY:CURRENT_FILENAME"},
  Speed={"aSPEED","sSPEED"},
  FileTyp={"aTYP","sTYP"},
  Tag={"aTAG","sTAG"},
  Ubits={"aUBITS","sUBITS","IXML:UBITS"},
  Circled={"aCIRCLED","sCIRCLED","IXML:CIRCLED"},
  WildTrack={"aWILDTRACK","sWILDTRACK","IXML:WILD_TRACK","IXML:TAKE_TYPE"},
  Tape={"aTAPE","sTAPE","IXML:TAPE"},
  Chnl={"aCHNL"},
  TrackName={"aTRK","sTRK"},
  -- only in iXML
  Project={"IXML:PROJECT"},
  TakeTyp={"IXML:TAKE_TYPE"},
  NoGood={"IXML:NO_GOOD","IXML:TAKE_TYPE"},
  FalseStart={"IXML:FALSE_START","IXML:TAKE_TYPE"},
  TotalFiles={"IXML:FILE_SET:TOTAL_FILES"},
  FileIndex={"IXML:FILE_SET:FILE_SET_INDEX"},
  BitDepth={"IXML:SPEED:AUDIO_BIT_DEPTH"},
  SampleRate={"IXML:SPEED:FILE_SAMPLE_RATE"},
  TrackCount={"IXML:TRACK_LIST:TRACK_COUNT"}
}
--------------------------------------------------------------------------------------
-- End -------------------------------------------------------------------------------
--------------------------------------------------------------------------------------






-------------------------------------
-- Function : Search tag in a list --
-------------------------------------
local function search(list_chunk,list_metadata)
  for i, tag in ipairs(list_chunk) do
    if not list_metadata[tag] and i == #list_chunk then
      return nil
    elseif list_metadata[tag] then
      return list_metadata[tag]
    end
  end
end

-------------------------------------
-- Function : Get all tracks names --
-------------------------------------
local function get_all_track_names(take, key, list_metadata)
  -- Set all track names in a list
  local tracks_names_list = {}
  for i=1, 64 do
    for w, k in ipairs(key) do
      local search_trk = search({k..i},list_metadata)
      if search_trk then
        table.insert(tracks_names_list,i..trackname_separator_1..search_trk)
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
        track_name = track_name..tracks_names_list[2]
      elseif take_chanmode == 1 and count_tracks_names > 1 and i == 2 then
        -- Invert channel 1 and 2
        track_name = track_name..tracks_names_list[1]
      else
        -- Normal order
        track_name = track_name..tracks_names_list[i+chanel_offset]
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

-------------------------------------
-- Main Function --------------------
-------------------------------------
function main(input)
  reaper.Undo_BeginBlock()

  -- Sort keys alphabetically
  sort_keys = {}
  for key,_ in pairs(list_tags) do
    table.insert(sort_keys,key)
  end
  table.sort(sort_keys)

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
              if key == "TrackName" then
                value = get_all_track_names(take,list_tags[key],list_metadata)
              else
                value = search(list_tags[key],list_metadata)
              end

              if value then
                if key == "Scene" or key == "Take" then
                  value = string.gsub(value,"%s+","")
                elseif key == "WildTrack" then
                  if value == "TRUE" or value == "WILD_TRACK" then
                    value = wildtrack_marker
                  else
                    value = ""
                  end
                elseif key == "NoGood" then
                  if value == "TRUE" or value == "NO_GOOD" then
                    value = nogood_marker
                  else
                    value = ""
                  end
                elseif key == "FalseStart" then
                  if value == "TRUE" or value == "FALSE_START" then
                    value = falsestart_marker
                  else
                    value = ""
                  end
                elseif key == "Circled" then
                  if value == "TRUE" then
                    value = cercled_marker
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
  reaper.Undo_EndBlock("Rename takes with BWF and iXML metadata", -1)
end


-------------------------------------
-- DO IT ----------------------------
-------------------------------------

count = reaper.CountSelectedMediaItems(0)
if count > 0 then
  reaper.PreventUIRefresh(1)

  local script_name = "Rename takes and item notes with BWF and iXML metadata"
  if message_box then
    retval, default_text = reaper.GetUserInputs(script_name, 2, "Take Name / Item notes,extrawidth=200,separator="..separator, default_name..separator..default_notes)
  end
  if retval or not message_box then
    if not message_box then
      default_text = default_name..separator..default_notes
    end
    local _, count_separator = string.gsub(default_text,separator,"")
    if count_separator == 1 then
      main(default_text)
    else
      reaper.ShowMessageBox("Error: The \""..separator.."\" character is not allowed.",script_name,0)
    end
  end

  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

-- @description Rename takes and item notes with BWF and iXML metadata
-- @author Rodilab
-- @version 2.1
-- @changelog ReaImGui 0.7 compatibility
-- @link Forum thread https://forum.cockos.com/showthread.php?t=250505
-- @donation Donate via PayPal https://www.paypal.com/donate?hosted_button_id=N5DUAELFWX4DC
-- @about
--   For BWF selected items : Set custom name with $wildcards for rename active take and set new notes.
--   First text-box for Take Name, second text-box for Item Notes (if empty, then don't change).
--
--   $bitdepth, $chnl, $circled, $date, $falsestart, $fileindex, $filename, $filetyp, $nogood, $note, $originator, $originatorref, $project, $reaname, $reaproject, $reatrack, $samplerate, $scene, $speed, $startoffsset, $tag, $take, $taketyp, $tape, $tcstart, $time, $timeref, $totalfiles, $trackcount, $trackname, $ubits, $wildtrack
--
--   by Rodrigo Diaz (aka Rodilab)

r = reaper
script_name = 'Rename takes and item notes with BWF and iXML metadata'

function TestVersion(version,version_min)
  local i = 0
  for num in string.gmatch(tostring(version),'%d+') do
    i = i + 1
    if version_min[i] and tonumber(num) > version_min[i] then
      return true
    elseif version_min[i] and tonumber(num) < version_min[i] then
      return false
    end
  end
  if i < #version_min then return false
  else return true end
end

-- Extensions check
if r.APIExists('ImGui_CreateContext') == true then
  if TestVersion(({r.ImGui_GetVersion()})[2],{0,5,1}) then

dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.6')
message_box = true -- Popup message box (if not, set default value)
separator = "~" -- This special character is prohibited in the message box
wildcard_chars = {"$","#","@"}
list_tags = {
  -- Reaper Infos
  reaproject={"r:Project"},
  reaname={"r:TakeName"},
  reatrack={"r:TrackName"},
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
  def = {
    default_name = "$scene-$take$circled ($trackname)",
    default_notes = "$note",
    trackname_separator_1 = ":",
    trackname_separator_2 = " / ",
    circled_marker = "*",
    wildtrack_marker = "WildTrack!",
    nogood_marker = "NoGood!",
    falsestart_marker = "FalseStart!",
    mouse_pos = false,
    wildcard_char = 1
    }
  for key in pairs(def) do
    if r.HasExtState(extstate_id,key) then
      local es_str = r.GetExtState(extstate_id,key)
      if es_str == 'true' then es_str = true
      elseif es_str == 'false' then es_str = false end
      conf[key] = tonumber(es_str) or es_str
      if (type(conf[key]) ~= 'number' and key=='wildcard_char')
      or (type(conf[key]) ~= 'boolean'and key=='mouse_pos') then
        conf[key] = def[key]
      end
      if  key == "trackname_separator_1" or 
          key == "trackname_separator_2" or 
          key == "circled_marker" or
          key == "wildtrack_marker" or
          key == "nogood_marker" or
          key == "falsestart_marker" then
            local len = string.len(tostring(conf[key]))
            conf[key] = string.sub(tostring(conf[key]),1,len-1)
      end
    else
      conf[key] = def[key]
    end
  end
  -- Erase old keys
  local old_keys = {'x','y','width','heigth'}
  for i, key in ipairs(old_keys) do
    if r.HasExtState(extstate_id, key) then
      r.DeleteExtState(extstate_id, key, true)
    end
  end
end

function ExtState_Save()
  for key in pairs(conf) do
    if  key == "trackname_separator_1" or 
        key == "trackname_separator_2" or 
        key == "circled_marker" or
        key == "wildtrack_marker" or
        key == "nogood_marker" or
        key == "falsestart_marker" then
      r.SetExtState(extstate_id, key, tostring(conf[key]).."/", true)
    else
      r.SetExtState(extstate_id, key, tostring(conf[key]), true)
    end
  end
end

reaper.atexit(function()
  ExtState_Save()
end)

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
  local samplerate =  r.GetMediaSourceSampleRate(source)
  local _,ssm = r.GetMediaFileMetadata(source,"BWF:TimeReference")
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
  local retval, tracklist_count = r.GetMediaFileMetadata(source,"IXML:TRACK_LIST:TRACK_COUNT")
  if retval == 1 then
    for i=1, tracklist_count do
      local tracklist_interleave = ""
      if i > 1 then
        tracklist_interleave = tracklist_interleave..":"..i
      end
      local retval, tracklist_index = r.GetMediaFileMetadata(source,"IXML:TRACK_LIST:TRACK:CHANNEL_INDEX"..tracklist_interleave)
      if retval == 1 then
        local retval, tracklist_name = r.GetMediaFileMetadata(source,"IXML:TRACK_LIST:TRACK:NAME"..tracklist_interleave)
        if retval ~= 1 then
          tracklist_name = "?"
        end
          table.insert(tracks_names_list,tracklist_index..conf.trackname_separator_1..tracklist_name)
      end
    end
  else
    -- No IXML Track List
    -- Search in BWF Comment
    for i=1, 64 do
      for w, k in ipairs(key) do
        local search_trk = search({k..i},list_metadata)
        if search_trk then
          table.insert(tracks_names_list,i..conf.trackname_separator_1..search_trk)
        end
      end
    end
  end
  -- If any track names exist
  local count_tracks_names = #tracks_names_list
  if count_tracks_names > 0 then
    -- Get real take chanmode
    local take_chanmode = r.GetMediaItemTakeInfo_Value(take,"I_CHANMODE")
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
        track_name = track_name..conf.trackname_separator_2
      end
    end
    return(track_name)
  else
    return(nil)
  end
end

---------------------------------------------------------------------------------
--- Main : Rename ---------------------------------------------------------------
---------------------------------------------------------------------------------

function main()
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)

  for i=0, count-1 do
    -- Get item, take and source
    local item = r.GetSelectedMediaItem(0,i)
    local take = r.GetActiveTake(item)
    if take then
      local source = r.GetMediaItemTake_Source(take)
      if r.GetMediaSourceType(source,"") == "WAVE" then
        local source_chan = r.GetMediaSourceNumChannels(source)
        local text = conf.default_name..separator..conf.default_notes

        local list_metadata = {}
        -- Set some r data
        list_metadata["r:Project"] = r.GetProjectName(0,"")
        list_metadata["r:TakeName"] = r.GetTakeName(take)
        _, list_metadata["r:TrackName"] = r.GetTrackName(r.GetMediaItemTrack(item))

        -- Get "BWF:Description" metadata list
        local retval, description = r.GetMediaFileMetadata(source,"BWF:Description")
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
                  local retval, value = r.GetMediaFileMetadata(source,k)
                  if retval and value ~= "" then
                    list_metadata[k] = value
                  end
                end
              end

              -- Get metadata value
              local value
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
                    value = conf.wildtrack_marker
                  else
                    value = ""
                  end
                elseif key == "nogood" then
                  if value == "TRUE" or value == "NO_GOOD" then
                    value = conf.nogood_marker
                  else
                    value = ""
                  end
                elseif key == "falsestart" then
                  if value == "TRUE" or value == "FALSE_START" then
                    value = conf.falsestart_marker
                  else
                    value = ""
                  end
                elseif key == "circled" then
                  if value == "TRUE" then
                    value = conf.circled_marker
                  else
                    value = ""
                  end
                end
                value = string.gsub(value,"\n\r","")
                value = string.gsub(value,separator,"") -- Prevent double separator
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
            r.GetSetMediaItemTakeInfo_String(take,"P_NAME",new_name,true)
          end
        end
        -- Set item notes
        if new_note and new_note ~= "" then
          local new_note_spaces = string.gsub(new_note,"%s+","")
          if new_note ~= "" and new_note_spaces ~= "" then
            r.GetSetMediaItemInfo_String(item,"P_NOTES",new_note,true)
          end
        end
      end -- End source type is "WAVE"
    end -- End active take isset
  end -- End for selected items

  r.PreventUIRefresh(-1)
  r.UpdateArrange()
  r.Undo_EndBlock(script_name,-1)
end

---------------------------------------------------------------------------------
--- ImGui -----------------------------------------------------------------------
---------------------------------------------------------------------------------
FLT_MIN = r.ImGui_NumericLimits_Float()

function CreateContext()
  ctx = r.ImGui_CreateContext(script_name)
  font = r.ImGui_CreateFont('Arial',12)
  r.ImGui_AttachFont(ctx,font)
  if conf.mouse_pos then
    cur_x, cur_y = r.GetMousePosition()
    cur_x, cur_y = r.ImGui_PointConvertNative(ctx, cur_x, cur_y, true)
  end
end

function HelpMarker(desc)
  r.ImGui_TextDisabled(ctx,'(?)')
  if r.ImGui_IsItemHovered(ctx) then
    r.ImGui_BeginTooltip(ctx)
    r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
    r.ImGui_Text(ctx,desc)
    r.ImGui_PopTextWrapPos(ctx)
    r.ImGui_EndTooltip(ctx)
  end
end

function ImGuiBody()
  local rv
  local WindowSize = {r.ImGui_GetWindowSize(ctx)}
  
  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameRounding(),4)

  r.ImGui_BeginTabBar(ctx,'MyTabBar',r.ImGui_TabBarFlags_None())
  if r.ImGui_BeginTabItem(ctx,'Input') then
    -- Take Name Input Box
    r.ImGui_AlignTextToFramePadding(ctx)
    r.ImGui_Text(ctx,'Take name')
    r.ImGui_SameLine(ctx,80)
    r.ImGui_PushItemWidth(ctx,-FLT_MIN)
    retval, conf.default_name = r.ImGui_InputText(ctx,'##Take name',conf.default_name)
    if r.ImGui_BeginDragDropTarget(ctx) then
      local payload
      rv,payload = r.ImGui_AcceptDragDropPayload(ctx,'WILDCARDS')
      if rv then
        conf.default_name = conf.default_name..payload
      end
    end
    conf.default_name =  conf.default_name:gsub(separator,"")

    -- Item Note Input Box
    r.ImGui_AlignTextToFramePadding(ctx)
    r.ImGui_Text(ctx,'Item note')
    r.ImGui_SameLine(ctx,80)
    r.ImGui_PushItemWidth(ctx,-FLT_MIN)
    retval, conf.default_notes = r.ImGui_InputText(ctx,'##Item note',conf.default_notes)
    if r.ImGui_BeginDragDropTarget(ctx) then
      local payload
      rv,payload = r.ImGui_AcceptDragDropPayload(ctx,'WILDCARDS')
      if rv then
        conf.default_notes = conf.default_notes..payload
      end
    end
    conf.default_notes =  conf.default_notes:gsub(separator,"")
    
    if tooltip_copy then
      tooltip_copy = tooltip_copy + 1
      r.ImGui_BeginTooltip(ctx)
      r.ImGui_Text(ctx, 'Copied')
      r.ImGui_EndTooltip(ctx)
      if tooltip_copy > 20 then tooltip_copy = nil end
    end

    -- Wildcars buttons, drag and drop
    HelpMarker('Drag and drop $wildcards in text input')
    local buttonColor = r.ImGui_ColorConvertHSVtoRGB(0,0,0.3,1)
    local hoveredColor = r.ImGui_ColorConvertHSVtoRGB(0,0,0.4,1)
    local textColor = r.ImGui_ColorConvertHSVtoRGB(0,0,0.9,1)
    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Button(),buttonColor)
    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonHovered(),hoveredColor)
    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonActive(),hoveredColor)
    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Text(),textColor)
    r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameRounding(),6.0)
    local width_count = 0
    local width_visible = WindowSize[1]-16
    for n,wildcard in ipairs(sort_keys) do
      local button_width = r.ImGui_CalcTextSize(ctx,key_char..wildcard, 0, 0) + 16
      if width_count + button_width <= width_visible and n ~= 1 then
        r.ImGui_SameLine(ctx)
        width_count = width_count + button_width
      else
        width_count = button_width
      end
      if r.ImGui_SmallButton(ctx,key_char..wildcard) then
        r.ImGui_SetClipboardText(ctx,key_char..wildcard)
        tooltip_copy = 0
      end
      if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_None()) then
        r.ImGui_SetDragDropPayload(ctx,'WILDCARDS',key_char..wildcard)
        r.ImGui_Text(ctx,key_char..wildcard)
        r.ImGui_EndDragDropSource(ctx)
      end
    end
    r.ImGui_PopStyleColor(ctx,4)
    r.ImGui_PopStyleVar(ctx,1)

    -- Separator
    r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_ItemSpacing(),0,r.ImGui_GetTextLineHeight( ctx ))
    r.ImGui_Spacing(ctx)
    r.ImGui_Separator(ctx)
    r.ImGui_PopStyleVar(ctx)
    local button_width = 100

    -- RENAME / CANCEL buttons
    r.ImGui_NewLine(ctx)
    r.ImGui_SameLine(ctx,(WindowSize[1]/2)-button_width-10)
    if r.ImGui_Button(ctx,'Rename', button_width,30) or r.ImGui_IsKeyDown(ctx,36) then
      close = true
      main()
    end
    r.ImGui_SameLine(ctx,(WindowSize[1]/2)+10)
    if r.ImGui_Button(ctx,'Cancel', button_width,30) then
      close = true
    end
    r.ImGui_EndTabItem(ctx)
  end
  -- Settings tab
  if r.ImGui_BeginTabItem(ctx,'Settings') then
    rv,conf.mouse_pos = r.ImGui_Checkbox(ctx,'Open window on mouse position',conf.mouse_pos)
    -- Track Name list
    r.ImGui_AlignTextToFramePadding(ctx)
    r.ImGui_Text(ctx,key_char..'trackname  ')
    r.ImGui_SameLine(ctx, 80)
    r.ImGui_PushItemWidth(ctx,41)
    retval, conf.trackname_separator_1 = r.ImGui_InputText(ctx,'##trackname_separator_1',conf.trackname_separator_1)
    r.ImGui_SameLine(ctx)
    retval, conf.trackname_separator_2 = r.ImGui_InputText(ctx,'##trackname_separator_2',conf.trackname_separator_2)
    r.ImGui_SameLine(ctx)
    r.ImGui_AlignTextToFramePadding(ctx)
    r.ImGui_Text(ctx,'1'..conf.trackname_separator_1..'MixL'..conf.trackname_separator_2..'2'..conf.trackname_separator_1..'MixR'..conf.trackname_separator_2..'3'..conf.trackname_separator_1..'Boom')
    -- Markers
    r.ImGui_PushItemWidth(ctx,90)
    r.ImGui_AlignTextToFramePadding(ctx)
    r.ImGui_Text(ctx,key_char..'circled    ')
    r.ImGui_SameLine(ctx, 80)
    retval, conf.circled_marker = r.ImGui_InputText(ctx,'##Circled',conf.circled_marker)
    r.ImGui_Text(ctx,key_char..'wildtrack  ')
    r.ImGui_SameLine(ctx, 80)
    retval, conf.wildtrack_marker = r.ImGui_InputText(ctx,'##Wildtrack',conf.wildtrack_marker)
    r.ImGui_Text(ctx,key_char..'falsestart ')
    r.ImGui_SameLine(ctx, 80)
    retval, conf.falsestart_marker = r.ImGui_InputText(ctx,'##FalseStart',conf.falsestart_marker)
    r.ImGui_Text(ctx,key_char..'nogood     ')
    r.ImGui_SameLine(ctx, 80)
    retval, conf.nogood_marker = r.ImGui_InputText(ctx,'##NoGood',conf.nogood_marker)
    r.ImGui_Text(ctx,'Wildcard tag')
    r.ImGui_SameLine(ctx, 80)
    local items = ""
    for i,key in ipairs(wildcard_chars) do
      items = items..key.."\31"
    end
    local combo_num = conf.wildcard_char - 1
    retval, combo_num = r.ImGui_Combo(ctx,'##wildcard_char',combo_num,items)
    conf.wildcard_char = combo_num + 1
    key_char = wildcard_chars[conf.wildcard_char]
    if r.ImGui_Button(ctx,'Restore') then
      for key, value in pairs(def) do
        conf[key] = value
      end
    end
    r.ImGui_EndTabItem(ctx)
  end
  r.ImGui_EndTabBar(ctx)
  r.ImGui_PopStyleVar(ctx)
end

function loop()

  r.ImGui_PushFont(ctx,font)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_WindowBg(),0x333333ff)
  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_WindowTitleAlign(),0.5,0.5)
  
  r.ImGui_SetNextWindowSize(ctx, 300, 290, r.ImGui_Cond_FirstUseEver())
  if cur_x then
    r.ImGui_SetNextWindowPos(ctx, cur_x, cur_y, r.ImGui_Cond_Once(), 0.5)
  end
  
  local window_flag = r.ImGui_WindowFlags_NoCollapse()
                    | r.ImGui_WindowFlags_NoDocking()
  local visible, open = r.ImGui_Begin(ctx, script_name, true, window_flag)
  r.ImGui_PopStyleColor(ctx)
  
  if visible then
    ImGuiBody()
    r.ImGui_End(ctx)
  end
  
  r.ImGui_PopStyleVar(ctx)
  r.ImGui_PopFont(ctx)
  
  if not open or r.ImGui_IsKeyDown(ctx,27) or close then
    r.ImGui_DestroyContext(ctx)
  else
    r.defer(loop)
  end
end

---------------------------------------------------------------------------------
-- DO IT ------------------------------------------------------------------------
---------------------------------------------------------------------------------

count = r.CountSelectedMediaItems(0)
if count > 0 then
  -- Sort keys alphabetically
  sort_keys = {}
  for key,_ in pairs(list_tags) do
    table.insert(sort_keys,key)
  end
  table.sort(sort_keys)
  ExtState_Load()
  conf.wildcard_char = tonumber(conf.wildcard_char) or 1
  key_char = wildcard_chars[conf.wildcard_char]
  if message_box then
    CreateContext()
    r.defer(loop)
  else
    main()
  end
end

-- Extentions check end
  else
    r.ShowMessageBox("Please update v0.5.1 or later of  \"ReaImGui: ReaScript binding for Dear ImGui\" with ReaPack and restart Reaper",script_name,0)
    local ReaPack_exist = r.APIExists('ReaPack_BrowsePackages')
    if ReaPack_exist == true then
      r.ReaPack_BrowsePackages('ReaImGui: ReaScript binding for Dear ImGui')
    end
  end
else
  r.ShowMessageBox("Please install \"ReaImGui: ReaScript binding for Dear ImGui\" with ReaPack and restart Reaper",script_name,0)
  local ReaPack_exist = r.APIExists('ReaPack_BrowsePackages')
  if ReaPack_exist == true then
    r.ReaPack_BrowsePackages('ReaImGui: ReaScript binding for Dear ImGui')
  end
end

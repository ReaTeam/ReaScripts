-- @description Match Criteria (match with BWF and iXML metadata)
-- @author Rodilab
-- @version 1.0
-- @screenshot Match Criteria GUI https://www.rodrigodiaz.fr/prive/Match_Criteria.png
-- @about
--   Requires the script "Lokasenna's GUI library v2 for Lua". Please install it first with ReaPack.
--
--   Search for matches to audio files in a folder, according to the matching criteria in the BWF and iXML metadata.
--   Then imports the matching files into new takes or tracks.

-- Script generated by Lokasenna's GUI Builder
local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack, then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Button.lua")()
-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

local script_name = "Match Criteria"
local list_ixml_tags = {
  "IXML:SPEED:TIMESTAMP_SAMPLES_SINCE_MIDNIGHT_LO",
  "IXML:BEXT:BWF_ORIGINATION_DATE",
  "IXML:PROJECT",
  "IXML:TAPE",
  "IXML:SCENE",
  "IXML:TAKE"
  }

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

local function least_one_true(list)
  for i, value in ipairs(list) do
    if value == true then
      return true
    end
  end
  return false
end

local function booltostringnum(boolean)
  if boolean == true then
    return 1
  else
    return 0
  end
end

local function numtobool(num)
  if num == 1 then
    return true
  else
    return false
  end
end

local function save_metadata(source,list_metadata)
  local value_list = {}
  for i, tag in ipairs(list_metadata) do
    local retval,value = reaper.GetMediaFileMetadata(source,tag)
    table.insert(value_list,value)
  end
  return value_list
end

local function new_items()
  local count_new_items =  reaper.CountSelectedMediaItems(0)
  if count_new_items > 0 then
    local list_items = {}
    local list_tracks = {}
    for i=0, count_new_items-1 do
      local item = reaper.GetSelectedMediaItem(0,i)
      table.insert(list_items,item)
      local track = reaper.GetMediaItem_Track(item)
      list_tracks[track] = true
    end
    return list_items, list_tracks
  else
    return nil
  end
end

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

local function close()
  GUI.quit = true
  gfx.quit()
end

function match()
  -- Get User Inputs
  local check_criteria = GUI.Val("check_criteria")
  local radio_import = GUI.Val("radio_import")
  local txtbox_characters = tonumber(GUI.Val("txtbox_characters"))
  if not txtbox_characters then txtbox_characters = 0 end

  if least_one_true(check_criteria) == true or txtbox_characters > 0 then
    -- Close Window
    close()

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    --conf.check_criteria = tostring(check_criteria)
    conf.check_tc = booltostringnum(check_criteria[1])
    conf.check_date = booltostringnum(check_criteria[2])
    conf.check_project = booltostringnum(check_criteria[3])
    conf.check_tape = booltostringnum(check_criteria[4])
    conf.check_scene = booltostringnum(check_criteria[5])
    conf.check_take = booltostringnum(check_criteria[6])
    conf.radio_import = tostring(radio_import)
    conf.txtbox_characters = tostring(txtbox_characters)
    ExtState_Save()

    -- Save all folder .wav files in a list, and metadatas values in other list
    local list_files = {}
    local list_file_metadata = {}
    for file in io.popen('find "'..folder..'" -type f','r'):lines() do -- Loop through all files
      local string_len = string.len(file)
      local file_ext = string.lower(string.sub(file,string_len-3,string_len))
      if file_ext == ".wav" then
        table.insert(list_files,file)
        local tmp_source = reaper.PCM_Source_CreateFromFile(file)
        list_file_metadata[file] = save_metadata(tmp_source,list_ixml_tags)
        reaper.PCM_Source_Destroy(tmp_source)
      end
    end
    table.sort(list_files)

    -- Save all .wav selected items in a list
    local list_items = {}
    for i=0, count_sel_items-1 do
      list_items[i+1] = reaper.GetSelectedMediaItem(0,i)
    end

    local list_match_items = {} -- List of succesfull matching items

    for i, item in ipairs(list_items) do
      -- Get item, take and source
      local take = reaper.GetActiveTake(item)
      if take then
        local source = reaper.GetMediaItemTake_Source(take)
        if reaper.GetMediaSourceType(source,"") == "WAVE" then

          reaper.SelectAllMediaItems(0,false)
          reaper.SetMediaItemSelected(item,true)

          local item_match = false

          local take_info_values = {}
          take_info_values["D_STARTOFFS"] = reaper.GetMediaItemTakeInfo_Value(take,"D_STARTOFFS")
          take_info_values["D_VOL"] = reaper.GetMediaItemTakeInfo_Value(take,"D_VOL")
          take_info_values["D_PAN"] = reaper.GetMediaItemTakeInfo_Value(take,"D_PAN")
          take_info_values["D_PANLAW"] = reaper.GetMediaItemTakeInfo_Value(take,"D_PANLAW")
          take_info_values["D_PITCH"] = reaper.GetMediaItemTakeInfo_Value(take,"D_PITCH")
          take_info_values["I_PITCHMODE"] = reaper.GetMediaItemTakeInfo_Value(take,"I_PITCHMODE")
          take_info_values["I_CUSTOMCOLOR"] = reaper.GetMediaItemTakeInfo_Value(take,"I_CUSTOMCOLOR")

          local take_metadata = save_metadata(source,list_ixml_tags)
          local take_filename = reaper.GetMediaSourceFileName(source,"")
          take_filename = take_filename:match("^.+/(.+)$")
          local take_characters = string.sub(take_filename,1,txtbox_characters)

          for i, file in ipairs(list_files) do
            local file_metadata = list_file_metadata[file]
            local match = true

            for i, value in ipairs(take_metadata) do
              if check_criteria[i] == true then
                if value ~= file_metadata[i] then
                  match = false
                  break
                end
              end
            end

            local filename = file:match("^.+/(.+)$")
            local file_characters = string.sub(filename,1,txtbox_characters)
            if txtbox_characters > 0 and match == true then
              if take_characters ~= file_characters then
                match = false
              end
            end

            if match == true and take_filename ~= filename then
              if item_match == false then
                -- Take: Crop to active take in items
                reaper.Main_OnCommand(40131,0)
              end
              reaper.InsertMedia(file,3)
              local new_take = reaper.GetActiveTake(item)
              local new_source = reaper.GetMediaItemTake_Source(new_take)
              -- Copy/Paste take info values
              for tag, value in pairs(take_info_values) do
                reaper.SetMediaItemTakeInfo_Value(new_take,tag,value)
              end
              item_match = true
            end

          end -- End FOR each file

          if item_match == true then
            table.insert(list_match_items,item)
          end

        end -- End IF source is WAV
      end -- End IF take isset
    end -- End FOR each selected item

    if #list_match_items > 0 then
      -- Select the items that have successfully matched
      reaper.Main_OnCommand(40289,0) -- Unselect all items
      for i, item in ipairs(list_match_items) do
        reaper.SetMediaItemSelected(item,true)
      end

      -- In new tracks
      if radio_import == 2 then
        reaper.Main_OnCommand(40224,0) -- Take: Explode takes of items across tracks
        local list_new_items, list_new_tracks = new_items()

        reaper.Main_OnCommand(40289,0) -- Unselect all items
        -- For each item that have successfully matched
        for i, item in ipairs(list_match_items) do
          -- Select and set first take active
          reaper.SetMediaItemSelected(item,true)
          reaper.SetMediaItemInfo_Value(item,"I_CURTAKE",0)
        end

        for new_track,value in pairs(list_new_tracks) do
          reaper.SetTrackSelected(new_track,true)
        end
        for i, new_item in ipairs(list_new_items) do
          reaper.SetMediaItemSelected(new_item,true)
        end

        -- Take: Crop to active take in items
        reaper.Main_OnCommand(40131,0)
      end

      messagebox = #list_match_items.."/"..#list_items.." items have successfully matched."
    else
      messagebox = "No match"
    end

    reaper.Undo_EndBlock(script_name,0)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.ShowMessageBox(messagebox,script_name,0)
  else
    -- ERROR : No criteria
    reaper.ShowMessageBox("Error : At least one criterion must be checked.",script_name,0)
  end
end

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

GUI.name = script_name
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 320, 290
GUI.anchor, GUI.corner = "mouse", "C"

GUI.New("check_criteria", "Checklist", {
    z = 11,
    x = 16.0,
    y = 32.0,
    w = 150,
    h = 190,
    caption = "Criteria",
    optarray = {"Time Code Start", "Date", "Project Name", "Tape", "Scene", "Take"},
    dir = "v",
    pad = 4,
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = true,
    shadow = true,
    swap = nil,
    opt_size = 20
})

GUI.New("txtbox_characters", "Textbox", {
    z = 10,
    x = 112.0,
    y = 192.0,
    w = 40,
    h = 20,
    caption = "First Characters",
    cap_pos = "left",
    font_a = 3,
    font_b = "monospace",
    color = "txt",
    bg = "wnd_bg",
    shadow = true,
    pad = 4,
    undo_limit = 20
})

GUI.New("radio_import", "Radio", {
    z = 11,
    x = 176.0,
    y = 32.0,
    w = 120,
    h = 70,
    caption = "Import files in",
    optarray = {"New Takes", "New Tracks"},
    dir = "v",
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = true,
    shadow = true,
    swap = nil,
    opt_size = 20
})

GUI.New("btn_match", "Button", {
    z = 11,
    x = 96.0,
    y = 240.0,
    w = 60,
    h = 24,
    caption = "Match",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = match
})

GUI.New("btn_cancel", "Button", {
    z = 11,
    x = 176.0,
    y = 240.0,
    w = 60,
    h = 24,
    caption = "Cancel",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = close
})

---------------------------------------------------------------------------------
--- Ext State -------------------------------------------------------------------
---------------------------------------------------------------------------------

conf = {}

extstate_id = "RODILAB_Match_criteria"
function ExtState_Load()
  local def = {
    txtbox_characters = "0",
    radio_import = 2,
    check_tc = 1,
    check_date = 1,
    check_project = 1,
    check_tape = 1,
    check_scene = 1,
    check_take = 1
    }
  for key in pairs(def) do
    if reaper.HasExtState(extstate_id,key) then
      local es_str = reaper.GetExtState(extstate_id,key)
      conf[key] = tonumber(es_str) or es_str
    else
      conf[key] = def[key]
    end
  end
end

function ExtState_Save()
  for key in pairs(conf) do reaper.SetExtState(extstate_id, key, conf[key], true) end
end

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

count_sel_items = reaper.CountSelectedMediaItems(0)
if count_sel_items > 0 then
  -- Open folder dialog, and set all wave files in a list
  retval, folder = reaper.JS_Dialog_BrowseForFolder("","")
  if retval ~= 0 then
    GUI.Init()
    GUI.Main()
    ExtState_Load()
    GUI.Val("check_criteria",{
      numtobool(conf.check_tc),
      numtobool(conf.check_date),
      numtobool(conf.check_project),
      numtobool(conf.check_tape),
      numtobool(conf.check_scene),
      numtobool(conf.check_take)
      })
    GUI.Val("txtbox_characters",conf.txtbox_characters)
    GUI.Val("radio_import",conf.radio_import)
  end
end

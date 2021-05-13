-- @description Match criteria (match with BWF and iXML metadata)
-- @author Rodilab
-- @version 1.1
-- @changelog Now works with ReaImGui API extension
-- @screenshot Match Criteria GUI https://www.rodrigodiaz.fr/prive/Match_Criteria.png
-- @about
--   Search for matches to audio files in a folder, according to the matching criteria in the BWF and iXML metadata.
--   Then imports the matching files into new takes or tracks.
--
--   Requires "ReaImGui: ReaScript binding for Dear ImGui". Please install it first with ReaPack, and restart Reaper.
--
--   by Rodilab (aka Rodrigo Diaz)

r = reaper
script_name = "Match criteria (match with BWF and iXML metadata)"
OS_Win = string.match(reaper.GetOS(),"Win")
OS_Mac = string.match(reaper.GetOS(),"OSX")
r_version = tonumber(r.GetAppVersion():match[[(%d+.%d+)]])

function TestVersion(version,version_min)
  local i = 0
  for num in string.gmatch(tostring(version),'%d+') do
    i = i + 1
    if version_min[i] and tonumber(num) < version_min[i] then
      return false
    end
  end
  if i < #version_min then return false
  else return true end
end

-- Extensions check
if r.APIExists('ImGui_CreateContext') == true then
  local imgui_version, reaimgui_version = r.ImGui_GetVersion()
  if TestVersion(reaimgui_version,{0,3,1}) then
    if r.APIExists('JS_Dialog_BrowseForOpenFiles') == true then
      if not OS_Mac or not r_version or r_version >= 6.28 then

popup_flags = r.ImGui_WindowFlags_NoResize() | r.ImGui_WindowFlags_NoMove()
window_flag = r.ImGui_WindowFlags_AlwaysAutoResize()
                    | r.ImGui_WindowFlags_NoTitleBar()
window_flags = r.ImGui_WindowFlags_None() | r.ImGui_WindowFlags_NoScrollWithMouse() | r.ImGui_WindowFlags_MenuBar()
background_color = r.ImGui_ColorConvertHSVtoRGB(1,0,0.2,1)
menubar_color = r.ImGui_ColorConvertHSVtoRGB(0.59,0.65,0.5,1)
child_heigth = 200
button_width = 100
width = 430
heigth = 300
separ = package.config:sub(1,1)
list_ixml_tags = {
  "IXML:SPEED:TIMESTAMP_SAMPLES_SINCE_MIDNIGHT_LO",
  "IXML:BEXT:BWF_ORIGINATION_DATE",
  "IXML:PROJECT",
  "IXML:TAPE",
  "IXML:SCENE",
  "IXML:TAKE"
  }

---------------------------------------------------------------------------------
--- Ext State -------------------------------------------------------------------
---------------------------------------------------------------------------------

conf = {}

extstate_id = "RODILAB_Match_criteria_v2"
function ExtState_Load()
  local def = {
    txtbox_characters = 0,
    radio_import = 2,
    check_tc = true,
    check_date = true,
    check_project = true,
    check_tape = true,
    check_scene = true,
    check_take = true,
    mouse_pos = true,
    folder = false,
    width = 430,
    heigth = 300,
    x = -1,
    y = -1
    }
  for key in pairs(def) do
    if r.HasExtState(extstate_id,key) then
      local es_str = r.GetExtState(extstate_id,key)
      if es_str == 'true' then es_str = true
      elseif es_str == 'false' then es_str = false end
      conf[key] = tonumber(es_str) or es_str
      if (type(conf[key]) ~= 'number' and (key=='txtbox_characters'
                                       or key=='radio_import'
                                       or key=='width'
                                       or key=='heigth'
                                       or key=='x'
                                       or key=='y'))
      or (type(conf[key]) ~= 'boolean'and (key=='check_tc'
                                       or key=='check_date'
                                       or key=='check_project'
                                       or key=='check_tape'
                                       or key=='check_scene'
                                       or key=='check_take')) then
        conf[key] = def[key]
      end
    else
      conf[key] = def[key]
    end
  end
end

function ExtState_Save()
  for key in pairs(conf) do
    local value = conf[key]
    if value == true then value = 'true'
    elseif value == false then value = 'false' end
    if key == "folder" then persist = false
    else persist = true end
    r.SetExtState(extstate_id,key,value,persist)
  end
end

function get_window_pos()
  rv, conf.x, conf.y = r.JS_Window_GetClientRect(hwnd)
  if OS_Mac then
    conf.y = conf.y - 10
  end
end

r.atexit(function()
  ExtState_Save()
end)

---------------------------------------------------------------------------------
--- Others functions ------------------------------------------------------------
---------------------------------------------------------------------------------

function save_metadata(source,list_metadata)
  local value_list = {}
  for i, tag in ipairs(list_metadata) do
    local retval,value = reaper.GetMediaFileMetadata(source,tag)
    table.insert(value_list,value)
  end
  return value_list
end

function new_items()
  local count_new_items = reaper.CountSelectedMediaItems(0)
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
--- Main : Match ----------------------------------------------------------------
---------------------------------------------------------------------------------

function main()
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  local check_criteria = {}
  table.insert(check_criteria,conf.check_tc)
  table.insert(check_criteria,conf.check_date)
  table.insert(check_criteria,conf.check_project)
  table.insert(check_criteria,conf.check_tape)
  table.insert(check_criteria,conf.check_take)
  table.insert(check_criteria,conf.check_tc)
  -- Save all folder .wav files in a list, and metadatas values in other list
  local list_files = {}
  local list_file_metadata = {}
  for file in io.popen('find "'..conf.folder..'" -type f','r'):lines() do -- Loop through all files
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
        local take_characters = string.sub(take_filename,1,conf.txtbox_characters)
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
          local file_characters = string.sub(filename,1,conf.txtbox_characters)
          if conf.txtbox_characters > 0 and match == true then
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
    if conf.radio_import == 2 then
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
    popup_message = #list_match_items.."/"..#list_items.." items have successfully matched."
  else
    popup_message = "No match"
  end
  popup_title = "Completed"
  r.Undo_EndBlock(script_name,-1)
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
end

---------------------------------------------------------------------------------
--- ImGui -----------------------------------------------------------------------
---------------------------------------------------------------------------------

function StartContext()
  conf.width = math.max(conf.width,100)
  conf.heigth = math.max(conf.heigth,100)
  if conf.mouse_pos or conf.x < 0 or conf.y < 0 then
    conf.x, conf.y = r.GetMousePosition()
    conf.x = math.floor(conf.x - (width/2))
    conf.y = math.floor(conf.y + (heigth/2))
  end
  if OS_Win then
    conf.y = math.max(conf.y,30)
  else
    conf.y = math.max(conf.y,0)
  end
  conf.x = math.max(conf.x,0)
  if conf.folder == false then
    conf.folder = r.GetProjectPath("")
  end
  ctx = r.ImGui_CreateContext(script_name,conf.width,conf.heigth,conf.x,conf.y)
  hwnd = r.ImGui_GetNativeHwnd(ctx)
  get_window_pos()
end

function loop()
  local rv
  conf.width, conf.heigth = r.ImGui_GetDisplaySize(ctx)
  -- Close Window ?
  if r.ImGui_IsCloseRequested(ctx) or r.ImGui_IsKeyDown(ctx,27) or close then
    get_window_pos()
    r.ImGui_DestroyContext(ctx)
    return
  end

  -- Window
  r.ImGui_SetNextWindowPos(ctx,0,0)
  r.ImGui_SetNextWindowSize(ctx,conf.width,conf.heigth)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_WindowBg(),background_color)
  r.ImGui_Begin(ctx,'wnd',nil,window_flag)
  r.ImGui_PopStyleColor(ctx)

  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameRounding(),4.0)

  if popup_message and popup_title then
    r.ImGui_OpenPopup(ctx,popup_title)
  end

  if r.ImGui_BeginPopupModal(ctx,popup_title,true,popup_flags) then
    r.ImGui_Text(ctx,popup_message)
    r.ImGui_EndPopup(ctx)
  end

  if not r.ImGui_IsPopupOpen(ctx,popup_title) then
    popup_message = nil
    popup_title = nil
  end

  -- Folder button
  if r.ImGui_Button(ctx,'Folder') then
    local rv, browse = r.JS_Dialog_BrowseForFolder('',conf.folder)
    if rv == 1 then
      conf.folder = browse
    end
  end
  r.ImGui_SameLine(ctx)
  r.ImGui_TextWrapped(ctx,conf.folder)
  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_ItemSpacing(),0,r.ImGui_GetTextLineHeight(ctx))
  r.ImGui_Spacing(ctx)
  r.ImGui_PopStyleVar(ctx)

  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ChildRounding(),5.0)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_MenuBarBg(),menubar_color)

  r.ImGui_BeginChild(ctx,'ChildL',r.ImGui_GetWindowContentRegionWidth(ctx)*0.6,child_heigth,true,window_flags)
  if r.ImGui_BeginMenuBar(ctx) then
    r.ImGui_Text(ctx,'Criteria')
  end
  r.ImGui_EndMenuBar(ctx)
  rv,conf.check_tc =      r.ImGui_Checkbox(ctx,'TC Start',conf.check_tc)
  rv,conf.check_date =    r.ImGui_Checkbox(ctx,'Date',conf.check_date)
  rv,conf.check_project = r.ImGui_Checkbox(ctx,'Project Name',conf.check_project)
  rv,conf.check_tape =    r.ImGui_Checkbox(ctx,'Tape',conf.check_tape)
  rv,conf.check_scene =   r.ImGui_Checkbox(ctx,'Scene',conf.check_scene)
  rv,conf.check_take =    r.ImGui_Checkbox(ctx,'Take',conf.check_take)
  r.ImGui_PushItemWidth(ctx,65)
  rv,conf.txtbox_characters = r.ImGui_InputInt(ctx,'First Characters',conf.txtbox_characters,1,1)
  r.ImGui_EndChild(ctx)

  r.ImGui_SameLine(ctx)

  r.ImGui_BeginChild(ctx,'ChildR',0,child_heigth,true,window_flags)
  if r.ImGui_BeginMenuBar(ctx) then
    r.ImGui_Text(ctx,'Import files in')
  end
  r.ImGui_EndMenuBar(ctx)
  rv,conf.radio_import = r.ImGui_RadioButtonEx(ctx, 'New Takes', conf.radio_import,1)
  rv,conf.radio_import = r.ImGui_RadioButtonEx(ctx, 'New Tracks', conf.radio_import,2)
  r.ImGui_EndChild(ctx)
  r.ImGui_PopStyleColor(ctx)
  r.ImGui_PopStyleVar(ctx)

  rv,conf.mouse_pos = r.ImGui_Checkbox(ctx,'Open window on mouse position',conf.mouse_pos)

  -- Separator
  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_ItemSpacing(),0,r.ImGui_GetTextLineHeight(ctx))
  r.ImGui_Spacing(ctx)
  r.ImGui_PopStyleVar(ctx)

  conf.width, conf.heigth = r.ImGui_GetDisplaySize(ctx)
  -- RENAME / CANCEL buttons
  r.ImGui_NewLine(ctx)
  r.ImGui_SameLine(ctx,(conf.width/2)-button_width-10)
  if r.ImGui_Button(ctx,'Match',button_width,30) or r.ImGui_IsKeyDown(ctx,36) then
    if conf.check_tc or conf.check_date or conf.check_project or conf.check_tape or conf.check_scene or conf.check_take or conf.txtbox_characters>0 then
      main()
    else
      -- ERROR : No criteria
      popup_title = "Error"
      popup_message = "At least one criterion must be checked."
    end
  end
  r.ImGui_SameLine(ctx,(conf.width/2)+10)
  if r.ImGui_Button(ctx,'Cancel',button_width,30) then
    close = true
  end

  r.ImGui_PopStyleVar(ctx,1)

  -- End loop
  r.ImGui_End(ctx)
  r.defer(loop)
end

---------------------------------------------------------------------------------
-- DO IT ------------------------------------------------------------------------
---------------------------------------------------------------------------------

count_sel_items = r.CountSelectedMediaItems(0)
if count_sel_items > 0 then
  ExtState_Load()
  StartContext()
  r.defer(loop)
end

-- Extentions check end
      else
        r.ShowMessageBox('Please install Reaper 6.28 or later',script_name,0)
      end
    else
      r.ShowMessageBox("Please install \"js_ReaScriptAPI: API functions for ReaScripts\" with ReaPack and restart Reaper",script_name,0)
      local ReaPack_exist = r.APIExists('ReaPack_BrowsePackages')
      if ReaPack_exist == true then
        r.ReaPack_BrowsePackages('js_ReaScriptAPI: API functions for ReaScripts')
      end
    end
  else
    r.ShowMessageBox("Please update v0.3.1 or later of \"js_ReaScriptAPI: API functions for ReaScripts\" with ReaPack and restart Reaper",script_name,0)
    local ReaPack_exist = r.APIExists('ReaPack_BrowsePackages')
    if ReaPack_exist == true then
      r.ReaPack_BrowsePackages('js_ReaScriptAPI: API functions for ReaScripts')
    end
  end
else
  r.ShowMessageBox("Please install \"ReaImGui: ReaScript binding for Dear ImGui\" with ReaPack and restart Reaper",script_name,0)
  local ReaPack_exist = r.APIExists('ReaPack_BrowsePackages')
  if ReaPack_exist == true then
    r.ReaPack_BrowsePackages('ReaImGui: ReaScript binding for Dear ImGui')
  end
end

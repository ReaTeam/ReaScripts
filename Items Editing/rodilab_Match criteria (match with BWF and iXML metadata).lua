-- @description Match criteria (match with BWF and iXML metadata)
-- @author Rodilab
-- @version 1.5
-- @changelog ReaImGui v0.7 compatibility
-- @link Forum thread https://forum.cockos.com/showthread.php?t=251640
-- @screenshot Screenshot https://www.rodrigodiaz.fr/prive/Match_criteria_v1_4.jpg
-- @donation Donate via PayPay https://www.paypal.com/donate?hosted_button_id=N5DUAELFWX4DC
-- @about
--   Search for matches to audio files in a folder, according to the matching criteria in the BWF and iXML metadata.
--   Then imports the matching files into new takes or tracks.
--
--   Requires "ReaImGui: ReaScript binding for Dear ImGui" extesion. Please install it first with ReaPack, and restart Reaper.

r = reaper
script_name = "Match criteria (match with BWF and iXML metadata)"
OS_Win = string.match(reaper.GetOS(),"Win")
OS_Mac = string.match(reaper.GetOS(),"OSX")

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
  local imgui_version, reaimgui_version = r.ImGui_GetVersion()
  if TestVersion(reaimgui_version,{0,5,0}) then
    if r.APIExists('JS_Dialog_BrowseForOpenFiles') == true then

dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.6')
menubar_color = r.ImGui_ColorConvertHSVtoRGB(0.59,0.65,0.5,1)
child_heigth = 185
button_width = 100
separ = package.config:sub(1,1)
searching = 0
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

extstate_id = "RODILAB_Match_criteria"
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
    folder = false
    }
  for key in pairs(def) do
    if r.HasExtState(extstate_id,key) then
      local es_str = r.GetExtState(extstate_id,key)
      if es_str == 'true' then es_str = true
      elseif es_str == 'false' then es_str = false end
      conf[key] = tonumber(es_str) or es_str
      if (type(conf[key]) ~= 'number' and (key=='txtbox_characters'
                                       or key=='radio_import'))
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
  -- Erase old keys
  local old_keys = {'x','y','width','heigth'}
  for i, key in ipairs(old_keys) do
    if r.HasExtState(extstate_id,key) then
      r.DeleteExtState(extstate_id,key,true)
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

local function GetAllFiles(folderlist,filelist,metadatalist)
  if type(folderlist)   ~= 'table' then return            end
  if type(filelist)     ~= 'table' then filelist     = {} end
  if type(metadatalist) ~= 'table' then metadatalist = {} end 
  local childs = {}
  for i, folder in ipairs(folderlist) do
    reaper.EnumerateFiles(folder,-1) -- Rescan
    local i = 0
    while reaper.EnumerateFiles(folder,i) do
      local filename = reaper.EnumerateFiles(folder,i)
      if string.upper(string.sub(filename,-4,-1)) == '.WAV' then
        local file = folder..separ..filename
        table.insert(filelist,file)
        local tmp_source = reaper.PCM_Source_CreateFromFile(file)
        metadatalist[file] = save_metadata(tmp_source,list_ixml_tags)
        reaper.PCM_Source_Destroy(tmp_source)
      end
      i = i + 1
    end
    reaper.EnumerateSubdirectories(folder,-1) -- Rescan
    local i = 0
    while reaper.EnumerateSubdirectories(folder,i) do
      table.insert(childs,folder..separ..reaper.EnumerateSubdirectories(folder,i))
      i = i + 1
    end
  end
  if #childs == 0 then
    return filelist, metadatalist
  else
    return GetAllFiles(childs,filelist,metadatalist)
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
  list_files, list_file_metadata = GetAllFiles({conf.folder})
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
        take_filename = take_filename:match('^.+'..separ..'(.+)$')
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
          local filename = file:match("^.+"..separ.."(.+)$")
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
  ctx = r.ImGui_CreateContext(script_name)
  font = r.ImGui_CreateFont('Arial',12)
  r.ImGui_AttachFont(ctx,font)
end

function ImGuiBody()
  local rv
  local WindowSize = {r.ImGui_GetWindowSize(ctx)}
  local popup_flags = r.ImGui_WindowFlags_NoResize() | r.ImGui_WindowFlags_NoMove()
  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameRounding(),4.0)

  if r.ImGui_BeginPopupModal(ctx,'Searching',nil,popup_flags) then
    r.ImGui_Text(ctx,'Please wait, this might take some time...')
    r.ImGui_EndPopup(ctx)
  end

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

  if r.ImGui_BeginChild(ctx, 'ChildL', WindowSize[1]*0.6, child_heigth, true, r.ImGui_WindowFlags_MenuBar()) then
    if r.ImGui_BeginMenuBar(ctx) then
      r.ImGui_Text(ctx,'Criteria')
      r.ImGui_EndMenuBar(ctx)
    end

    rv,conf.check_tc =      r.ImGui_Checkbox(ctx,'TC Start',conf.check_tc)
    rv,conf.check_date =    r.ImGui_Checkbox(ctx,'Date',conf.check_date)
    rv,conf.check_project = r.ImGui_Checkbox(ctx,'Project Name',conf.check_project)
    rv,conf.check_tape =    r.ImGui_Checkbox(ctx,'Tape',conf.check_tape)
    rv,conf.check_scene =   r.ImGui_Checkbox(ctx,'Scene',conf.check_scene)
    rv,conf.check_take =    r.ImGui_Checkbox(ctx,'Take',conf.check_take)
    r.ImGui_PushItemWidth(ctx,65)
    rv,conf.txtbox_characters = r.ImGui_InputInt(ctx,'First Characters',conf.txtbox_characters,1,1)
    r.ImGui_EndChild(ctx)
  end

  r.ImGui_SameLine(ctx)

  if r.ImGui_BeginChild(ctx, 'ChildR', 0, child_heigth, true, r.ImGui_WindowFlags_MenuBar()) then
    if r.ImGui_BeginMenuBar(ctx) then
      r.ImGui_Text(ctx,'Import files in')
      r.ImGui_EndMenuBar(ctx)
    end

    rv,conf.radio_import = r.ImGui_RadioButtonEx(ctx, 'New Takes', conf.radio_import,1)
    rv,conf.radio_import = r.ImGui_RadioButtonEx(ctx, 'New Tracks', conf.radio_import,2)
    r.ImGui_EndChild(ctx)
  end
  r.ImGui_PopStyleColor(ctx)
  r.ImGui_PopStyleVar(ctx)

  rv,conf.mouse_pos = r.ImGui_Checkbox(ctx,'Open window on mouse position',conf.mouse_pos)

  -- Separator
  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_ItemSpacing(),0,r.ImGui_GetTextLineHeight(ctx))
  r.ImGui_Spacing(ctx)
  r.ImGui_PopStyleVar(ctx)

  -- Match buttons
  r.ImGui_NewLine(ctx)
  r.ImGui_SameLine(ctx,(WindowSize[1]/2)-button_width-10)
  if match_button then
    if match_button > 1 then
      match_button = false
      main()
    else
      match_button = match_button + 1
    end
  end
  if r.ImGui_Button(ctx,'Match',button_width,30) or r.ImGui_IsKeyDown(ctx,36) then
    if conf.check_tc or conf.check_date or conf.check_project or conf.check_tape or conf.check_scene or conf.check_take or conf.txtbox_characters>0 then
      r.ImGui_OpenPopup(ctx,'Searching')
      match_button = 0
    else
      -- ERROR : No criteria
      popup_title = "Error"
      popup_message = "At least one criterion must be checked."
    end
  end
  r.ImGui_SameLine(ctx,(WindowSize[1]/2)+10)
  if r.ImGui_Button(ctx,'Cancel',button_width,30) then
    close = true
  end

  r.ImGui_PopStyleVar(ctx,1)
end

function loop()
  r.ImGui_PushFont(ctx,font)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_WindowBg(),0x333333ff)
  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_WindowTitleAlign(),0.5,0.5)
  r.ImGui_SetNextWindowSize(ctx, 430, 315, r.ImGui_Cond_FirstUseEver())

  if conf.mouse_pos then
    local cur_x, cur_y = r.GetMousePosition()
    if OS_Mac then
      local primary_monitor_height = ({r.BR_Win32_GetMonitorRectFromRect(false, 0, 0, 0, 0)})[4]
      cur_y = primary_monitor_height - cur_y
    end
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

count_sel_items = r.CountSelectedMediaItems(0)
if count_sel_items > 0 then
  ExtState_Load()
  if conf.folder == false then
    conf.folder = r.GetProjectPath("")
  end
  StartContext()
  r.defer(loop)
end

-- Extentions check end
    else
      r.ShowMessageBox("Please install \"js_ReaScriptAPI: API functions for ReaScripts\" with ReaPack and restart Reaper",script_name,0)
      local ReaPack_exist = r.APIExists('ReaPack_BrowsePackages')
      if ReaPack_exist == true then
        r.ReaPack_BrowsePackages('js_ReaScriptAPI: API functions for ReaScripts')
      end
    end
  else
    r.ShowMessageBox("Please update v0.5.0 or later of  \"ReaImGui: ReaScript binding for Dear ImGui\" with ReaPack and restart Reaper",script_name,0)
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

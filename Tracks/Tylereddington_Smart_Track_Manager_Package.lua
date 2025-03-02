-- @description Smart Track Managers
-- @author Tyler Eddington
-- @version 1.0alpha1
-- @provides [main] Tylereddington_Smart_Track_Manager_Package/New file 4.lua > Tylereddington_Smart_Track_Manager_Package/Smart_Track_Organizer
-- @about
--   # **Comprehensive Template Loader & AI Instrument Integration Script for REAPER**
--
--   ---
--
--   ## **Overview**
--   This script automates track template management and integrates AI-assisted instrument selection. It helps you:
--   1. **Auto-save tracks as templates on startup**, using the **track name** as the filename.
--   2. **Auto-save all tracks as a group template**, named after the **project**.
--   3. **Load, manage, and organize track templates** via a **GUI**.
--   4. **Use AI to recommend instruments** based on your description and desired number.
--   5. **Use AI to tag templates automatically**.
--
--   ---
--
--   ## **Key Features**
--
--   ### **Auto-Saving**
--   - **Saves each track individually** as a `.rtracktemplate` file named after the **track name**.
--   - **Saves a group template** with all project tracks under `TrackTemplateGroups/<ProjectName>.rtracktemplate`.
--
--   ### **Template Management**
--   - **Filter, shuffle, and multi-select templates** for loading.
--   - **Tagging**: Assign and manage tags for templates.
--   - **Delete templates** easily.
--   - **Auto Preview**: Instantly hear a template when selected.
--
--   ### **AI Features**
--   - **AI Instrument Loader**: Automatically selects track templates based on an AI-generated response.
--   - **AI Auto Tagger**: Uses AI to suggest relevant tags for templates.
--
--   ---
--
--   ## **How to Use**
--
--   ### **Loading & Managing Templates**
--   1. Run the script. It automatically saves all current tracks as templates.
--   2. Use the **Template Loader** tab to browse, filter, shuffle, and load templates.
--   3. **Double-click a template** to load it, or **multi-select** and press **Enter**.
--
--   ### **AI Instrument Loader**
--   1. Enter a **description** of the instruments you need and specify how many.
--   2. Click **"Generate Prompt"**—this copies a pre-formatted request to your clipboard.
--   3. **Paste the prompt** into **ChatGPT or any AI chatbot** of your choice.
--   4. Copy the **AI’s response** and **paste it into the response box**.
--   5. Click **"Apply AI Response"**, and the closest matching templates will be loaded.
--
--   ### **AI Auto Tagger**
--   1. Enter a **tag** you want to assign (e.g., "Orchestral").
--   2. Click **"Generate Tagger Prompt"**—this copies a formatted request to your clipboard.
--   3. **Paste the prompt** into **ChatGPT or any AI chatbot**.
--   4. Copy the **AI’s response** and **paste it into the response box**.
--   5. Click **"Apply AI Tagger Response"** to automatically tag relevant templates.
--
--   ---
--
--   ## **Exiting**
--   - Press **Escape** or **File → Close** to exit.
--   - **Any preview track is automatically removed** when closing.
--
--   ---
--
--   ## **Notes & Tips**
--   - Templates are saved using **track names**, so make sure your tracks are named clearly.
--   - The AI tool **does not run inside REAPER**—you must copy/paste the prompts to an external AI chatbot.
--   - **Tags are stored in text files** (`template_tags.txt` and `template_group_tags.txt`) in your REAPER resource folder.

--[[
    Comprehensive Template Loader & AI Instrument Integration Script for REAPER
    with automatic Template Save/Group Save at startup, 
    record-arm fix (removed), and
    temporary message support (Ultraschall).

    Date: December 9, 2024
--]]

---------------------------------------
-- Include Ultraschall API
---------------------------------------
local ultraschall_api_path = reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua"
local ultraschall_api_file = io.open(ultraschall_api_path,"r")
if ultraschall_api_file then 
  ultraschall_api_file:close()
  dofile(ultraschall_api_path)
else
  reaper.ShowMessageBox("Ultraschall API not found.\nPlease install Ultraschall to use this script.", "Error", 0)
  return
end

---------------------------------------
-- Basic Utilities
---------------------------------------
local reaper = reaper
if not reaper.ImGui_CreateContext then
    reaper.ShowMessageBox("ReaImGui extension is required for this script.", "Error", 0)
    return
end

local ctx = reaper.ImGui_CreateContext('Comprehensive Template & AI Instrument Loader')
local unpack = unpack or table.unpack

---------------------------------------
-- Utility: sanitize file names
---------------------------------------
local function sanitize_filename(filename)
    return filename:gsub("[\\/:*?\"<>|]", "_")
end

---------------------------------------
-- Auto-Save Individual Tracks as Templates
---------------------------------------
local function save_all_tracks_as_templates_auto()
    local template_directory = reaper.GetResourcePath().."/TrackTemplates/"
    reaper.RecursiveCreateDirectory(template_directory, 0)

    local track_count = reaper.CountTracks(0)
    if track_count == 0 then
        return
    end

    for i = 0, track_count - 1 do
        -- Deselect everything first
        reaper.Main_OnCommand(40297, 0)

        local track = reaper.GetTrack(0, i)
        reaper.SetTrackSelected(track, true)

        local _, track_name = reaper.GetTrackName(track, "")
        local file_path = template_directory .. sanitize_filename(track_name) .. ".rtracktemplate"

        -- Save selected track as .rtracktemplate
        reaper.Main_SaveProjectEx(0, file_path, 1)
    end

    -- Finally, deselect everything
    reaper.Main_OnCommand(40297, 0)
end

---------------------------------------
-- Auto-Save Template Group (Project Name)
---------------------------------------
local function auto_save_template_group()
    local proj_name = sanitize_filename(reaper.GetProjectName(0, ""))
    local template_group_dir = reaper.GetResourcePath().."/TrackTemplateGroups"
    reaper.RecursiveCreateDirectory(template_group_dir, 0)

    local file_path = template_group_dir .. "/" .. proj_name .. ".rtracktemplate"
    local track_count = reaper.CountTracks(0)
    if track_count == 0 then
 return
    end

    -- Deselect everything first
    reaper.Main_OnCommand(40297, 0)

    -- Select all tracks
    for i = 0, track_count - 1 do
        reaper.SetTrackSelected(reaper.GetTrack(0, i), true)
    end

    reaper.Main_SaveProjectEx(0, file_path, 1)

    -- Deselect again
    reaper.Main_OnCommand(40297, 0)
end

------------------------------------------------------------------------------
-- The rest of the script is the main ImGui-based template manager & AI loader
------------------------------------------------------------------------------

local open = true
local templates = {}
local filtered_templates = {}
local filter_text = ""
local selected_indices = {}
local last_selected_index = nil
local first_frame = true
local tag_input_text = ""
local selected_templates_for_tag_edit = {}
local confirm_delete = false
local delete_templates = {}
local mode = "Track Templates" -- or "Template Groups"

local preview_track = nil
local auto_preview_enabled = false

-- AI Instrument Loader variables
local instructions = ''
local desired_instruments = 1
local ai_response = ''
local generated_prompt = ''

-- AI Auto Tagger variables
local ai_tagger_tag = ""
local ai_tagger_response = ""

-- Paths
local resource_path = reaper.GetResourcePath()
local track_template_dir = resource_path .. "/TrackTemplates"
local template_group_dir = resource_path .. "/TrackTemplateGroups"
local tag_file_path = resource_path .. "/template_tags.txt"
local group_tag_file_path = resource_path .. "/template_group_tags.txt"

reaper.RecursiveCreateDirectory(template_group_dir, 0)

-- Loading state variables
local loading_in_progress = false
local loading_total = 0
local loading_current = 0
local loading_chunks = {}
local loading_done_callback = nil

---------------------------------------
-- Tag Storage / Retrieval
---------------------------------------
local function read_tags(tag_file)
    local tags = {}
    local file = io.open(tag_file, "r")
    if file then
        for line in file:lines() do
            local name, tag_str = line:match("^(.-)%=(.*)$")
            if name and tag_str then
                local tag_list = {}
                for tag in tag_str:gmatch("[^,]+") do
                    table.insert(tag_list, tag)
                end
                tags[name] = tag_list
            end
        end
        file:close()
    end
    return tags
end

local function save_tags(tags, tag_file)
    local file = io.open(tag_file, "w")
    if file then
        for name, tag_list in pairs(tags) do
            file:write(name .. "=" .. table.concat(tag_list, ",") .. "\n")
        end
        file:close()
    end
end

---------------------------------------
-- Read and Filter Templates
---------------------------------------
local function read_templates()
    templates = {}
    local tags = read_tags((mode == "Track Templates") and tag_file_path or group_tag_file_path)
    local dir = (mode == "Track Templates") and track_template_dir or template_group_dir
    local i = 0
    while true do
        local file = reaper.EnumerateFiles(dir, i)
        if not file then break end
        if file:match("%.rtracktemplate$") then
            local template_name = file:sub(1, -16)
            table.insert(templates, {
                name = template_name,
                tags = tags[template_name] or {}
            })
        end
        i = i + 1
    end
end

local function filter_templates()
    filtered_templates = {}
    local filter_lower = filter_text:lower()
    for _, template in ipairs(templates) do
        local name_lower = template.name:lower()
        local tags_lower = table.concat(template.tags, " "):lower()
        local search_space = name_lower .. " " .. tags_lower
        local match = true
        for word in filter_lower:gmatch("%S+") do
            if not search_space:find(word, 1, true) then
                match = false
                break
            end
        end
        if match then
            table.insert(filtered_templates, template)
        end
    end
    for i = #selected_indices, 1, -1 do
        if selected_indices[i] > #filtered_templates then
            table.remove(selected_indices, i)
        end
    end
end

local function shuffle_templates()
    for i = #filtered_templates, 2, -1 do
        local j = math.random(i)
        filtered_templates[i], filtered_templates[j] = filtered_templates[j], filtered_templates[i]
    end
    selected_indices = {}
end

---------------------------------------
-- Loading Mechanism
---------------------------------------
local function load_template_file(template_path)
    local file = io.open(template_path, 'r')
    if not file then return end
    local content = file:read('*a')
    file:close()

    local chunks = {}
    for chunk in content:gmatch('(<TRACK.-\n>)\n') do
        table.insert(chunks, chunk)
    end
    return chunks
end

-- Called whenever we load new templates.
-- 1) Auto-save all current tracks first.
local function prepare_load(templates_to_load, insert_at_end, done_callback)
    save_all_tracks_as_templates_auto()

    local dir = (mode == "Track Templates") and track_template_dir or template_group_dir
    local num_tracks = reaper.CountTracks(0)
    local insert_index
    if insert_at_end then
        insert_index = num_tracks
    else
        local num_selected_tracks = reaper.CountSelectedTracks(0)
        if num_selected_tracks > 0 then
            local last_selected_track = reaper.GetSelectedTrack(0, num_selected_tracks - 1)
            insert_index = math.floor(reaper.GetMediaTrackInfo_Value(last_selected_track, 'IP_TRACKNUMBER'))
        else
            insert_index = num_tracks
        end
    end

    local all_chunks = {}
    for _, template in ipairs(templates_to_load) do
        local template_path = dir .. "/" .. template.name .. ".rtracktemplate"
        if reaper.file_exists(template_path) then
            local track_chunks = load_template_file(template_path)
            if track_chunks then
                for _, chunk in ipairs(track_chunks) do
                    table.insert(all_chunks, {chunk=chunk, insert_index=insert_index})
                    insert_index = insert_index + 1
                end
            end
        end
    end

    if #all_chunks == 0 then
        if done_callback then done_callback() end
        return
    end

    loading_chunks = all_chunks
    loading_total = #all_chunks
    loading_current = 0
    loading_in_progress = true
    loading_done_callback = done_callback
end

local function load_next_chunk()
    if loading_current < loading_total then
        loading_current = loading_current + 1
        local item = loading_chunks[loading_current]

        -- Insert the track
        reaper.InsertTrackAtIndex(item.insert_index, true)
        local new_track = reaper.GetTrack(0, item.insert_index)
        reaper.SetTrackStateChunk(new_track, item.chunk, false)

        -- Deselect everything, then select only the new track
        reaper.Main_OnCommand(40297, 0)
        reaper.SetTrackSelected(new_track, true)

        -- Close any floating FX windows
        local fx_count = reaper.TrackFX_GetCount(new_track)
        for fx = 0, fx_count - 1 do
            reaper.TrackFX_Show(new_track, fx, 0)
        end
    else
        loading_in_progress = false
        loading_chunks = {}
        loading_total = 0
        loading_current = 0
        if loading_done_callback then
            loading_done_callback()
            loading_done_callback = nil
        end
    end
end

local function delete_selected_templates(templates_to_delete)
    local tags_changed = false
    local dir = (mode == "Track Templates") and track_template_dir or template_group_dir
    local tag_file = (mode == "Track Templates") and tag_file_path or group_tag_file_path

    for _, template in ipairs(templates_to_delete) do
        local template_path = dir .. "/" .. template.name .. ".rtracktemplate"
        local result = os.remove(template_path)
        if result then
            for i = #templates, 1, -1 do
                if templates[i].name == template.name then
                    table.remove(templates, i)
                    break
                end
            end
            tags_changed = true
        else
            reaper.ShowMessageBox("Could not delete: " .. template.name, "Error", 0)
        end
    end

    if tags_changed then
        local all_tags = {}
        for _, template in ipairs(templates) do
            all_tags[template.name] = template.tags
        end
        save_tags(all_tags, tag_file)
    end

    filter_templates()
    selected_indices = {}
end

---------------------------------------
-- Auto-Preview Setup
---------------------------------------
local function stop_preview_track()
    if preview_track then
        reaper.DeleteTrack(preview_track)
        preview_track = nil
    end
end

-- Only the preview track is soloed; unselect all and select only this track,
-- then set I_RECMON=1 and I_SOLO=1.
local function setup_preview_track(track)
    reaper.Main_OnCommand(40297, 0) -- unselect all
    reaper.SetTrackSelected(track, true)

    reaper.SetMediaTrackInfo_Value(track, "I_RECMON", 1)
    reaper.SetMediaTrackInfo_Value(track, "I_SOLO", 1)
end

local function auto_preview_template(template)
    if not auto_preview_enabled then
        stop_preview_track()
        return
    end

    stop_preview_track()
    local dir = (mode == "Track Templates") and track_template_dir or template_group_dir
    local template_path = dir .. "/" .. template.name .. ".rtracktemplate"
    if not reaper.file_exists(template_path) then
        return
    end
    local track_chunks = load_template_file(template_path)
    if not track_chunks or #track_chunks == 0 then return end

    reaper.Undo_BeginBlock()

    reaper.InsertTrackAtIndex(reaper.CountTracks(0), true)
    preview_track = reaper.GetTrack(0, reaper.CountTracks(0) - 1)
    reaper.SetTrackStateChunk(preview_track, track_chunks[1], false)

    setup_preview_track(preview_track)

    -- Close any floating FX windows
    local fx_count = reaper.TrackFX_GetCount(preview_track)
    for fx = 0, fx_count - 1 do
        reaper.TrackFX_Show(preview_track, fx, 0)
    end

    reaper.Undo_EndBlock("Auto Preview Template", -1)
end

---------------------------------------
-- Save Current As Template Group (manually if needed)
---------------------------------------
local function save_current_as_template_group()
    local instrument_tracks = {}
    local num_tracks = reaper.CountTracks(0)
    for i = 0, num_tracks - 1 do
        local track = reaper.GetTrack(0, i)
        local fx_count = reaper.TrackFX_GetCount(track)
        if fx_count > 0 then
            table.insert(instrument_tracks, track)
        end
    end

    if #instrument_tracks == 0 then
        reaper.ShowMessageBox("No instrument tracks found to save.", "Error", 0)
        return
    end

    reaper.Main_OnCommand(40297, 0)
    for _, track in ipairs(instrument_tracks) do
        reaper.SetTrackSelected(track, true)
    end

    local group_name = "ManualGroup"
    group_name = sanitize_filename(group_name)

    local file_path = template_group_dir .. "/" .. group_name .. ".rtracktemplate"
    reaper.Main_SaveProjectEx(0, file_path, 1)
    reaper.Main_OnCommand(40297, 0)
    read_templates()
    filter_templates()
    reaper.ShowMessageBox("Saved group '" .. group_name .. "'.", "Success", 0)
end

------------------------------------------------------------------------------
-- AI Instrument Loader / Tagger
------------------------------------------------------------------------------

local function generate_prompt_for_ai()
    if desired_instruments < 1 then
        reaper.ShowMessageBox("Number of instruments must be at least 1.", "Invalid Input", 0)
        return
    end
    if instructions == "" then
        reaper.ShowMessageBox("Please enter instructions for the instruments.", "No Instructions", 0)
        return
    end

    local available_templates = {}
    for _, template in ipairs(templates) do
        table.insert(available_templates, template.name)
    end

    local prompt = "Dear AI,\n"
    prompt = prompt .. instructions .. "\n\n"
    prompt = prompt .. "Number of Instruments: " .. desired_instruments .. "\n\n"
    prompt = prompt .. "Available Instruments:\n"
    for _, name in ipairs(available_templates) do
        prompt = prompt .. "[" .. name .. "]\n"
    end
    prompt = prompt .. "\nPlease provide a response in the following format:\n"
    prompt = prompt .. "[instrument1][instrument2]...[instrumentN]\n\n"
    prompt = prompt .. "Thank you!"

    generated_prompt = prompt
    reaper.CF_SetClipboard(generated_prompt)
    reaper.ShowMessageBox("Prompt generated and copied to clipboard.", "Success", 0)
end

local function parse_ai_response(response_text)
    local instruments = {}
    for instr in response_text:gmatch("%[(.-)%]") do
        if instr ~= "" then
            table.insert(instruments, instr)
        end
    end
    return instruments
end

local function find_closest_template_name(instr)
    local function levenshtein(str1, str2)
        local len1 = #str1
        local len2 = #str2
        local matrix = {}
        for i = 0, len1 do
            matrix[i] = { [0] = i }
        end
        for j = 0, len2 do
            matrix[0][j] = j
        end
        for i = 1, len1 do
            for j = 1, len2 do
                local cost = (str1:sub(i,i) == str2:sub(j,j)) and 0 or 1
                matrix[i][j] = math.min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + cost
                )
            end
        end
        return matrix[len1][len2]
    end

    local best_match = nil
    local best_distance = math.huge
    local instr_lower = instr:lower()
    for _, template in ipairs(templates) do
        local dist = levenshtein(instr_lower, template.name:lower())
        if dist < best_distance then
            best_distance = dist
            best_match = template
        end
    end
    return best_match
end

local function apply_ai_response()
    local instruments = parse_ai_response(ai_response)
    if #instruments == 0 then
        reaper.ShowMessageBox("AI response does not contain any instruments.", "Invalid Response", 0)
        return
    end

    local templates_to_load = {}
    for _, instr in ipairs(instruments) do
        local found_template = nil
        for _, template in ipairs(templates) do
            if template.name:lower() == instr:lower() then
                found_template = template
                break
            end
        end
        if not found_template then
            found_template = find_closest_template_name(instr)
        end
        if found_template then
            table.insert(templates_to_load, found_template)
        end
    end

    if #templates_to_load > 0 then
        prepare_load(templates_to_load, true, function()
            reaper.ShowMessageBox("Instruments loaded successfully.", "Success", 0)
        end)
    else
        reaper.ShowMessageBox("No suitable templates found for the given response.", "Not Found", 0)
    end
end

---------------------------------------
-- AI Auto Tagger
---------------------------------------
local function generate_ai_tagger_prompt()
    if ai_tagger_tag == "" then
        reaper.ShowMessageBox("Enter a tag before generating the prompt.", "No Tag", 0)
        return
    end
    local list_of_templates = {}
    for _, tpl in ipairs(templates) do
        table.insert(list_of_templates, tpl.name)
    end
    local prompt = "Given the following list of template names:\n\n"
    for _, name in ipairs(list_of_templates) do
        prompt = prompt .. "- " .. name .. "\n"
    end
    prompt = prompt .. "\nWhich of these templates should have the tag [" .. ai_tagger_tag .. "]?\n"
    prompt = prompt .. "Respond with a list like: [TemplateName1][TemplateName2]...\n"
    reaper.CF_SetClipboard(prompt)
    reaper.ShowMessageBox("AI Tagger prompt generated and copied to clipboard.", "Success", 0)
end

local function apply_ai_tagger_response()
    local to_tag = {}
    for tpl in ai_tagger_response:gmatch("%[(.-)%]") do
        if tpl ~= "" then
            to_tag[#to_tag+1] = tpl
        end
    end
    if #to_tag == 0 then
        reaper.ShowMessageBox("No templates found in the AI response.", "Error", 0)
        return
    end
    for _, tpl_name in ipairs(to_tag) do
        for _, t in ipairs(templates) do
            if t.name:lower() == tpl_name:lower() then
                local found = false
                for _, tag in ipairs(t.tags) do
                    if tag:lower() == ai_tagger_tag:lower() then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(t.tags, ai_tagger_tag)
                end
            end
        end
    end
    local all_tags = {}
    for _, template in ipairs(templates) do
        all_tags[template.name] = template.tags
    end
    local tag_file = (mode == "Track Templates") and tag_file_path or group_tag_file_path
    save_tags(all_tags, tag_file)
    filter_templates()
    reaper.ShowMessageBox("AI tagger response applied successfully.", "Success", 0)
end

---------------------------------------
-- Main GUI / Main Loop
---------------------------------------
local function main()
    if loading_in_progress then
        load_next_chunk()
    end

    reaper.ImGui_SetNextWindowSize(ctx, 600, 700, reaper.ImGui_Cond_FirstUseEver())
    local visible, open_new = reaper.ImGui_Begin(ctx,
                                                 'Comprehensive Template & AI Instrument Loader',
                                                 open,
                                                 reaper.ImGui_WindowFlags_MenuBar())
    open = open_new

    if visible then
        if reaper.ImGui_BeginMenuBar(ctx) then
            if reaper.ImGui_BeginMenu(ctx, "File") then
                if reaper.ImGui_MenuItem(ctx, "Close") then
                    open = false
                end
                reaper.ImGui_EndMenu(ctx)
            end
            reaper.ImGui_EndMenuBar(ctx)
        end

        if loading_in_progress then
            reaper.ImGui_Text(ctx, "Loading templates...")
            local fraction = 0
            if loading_total > 0 then
                fraction = loading_current / loading_total
            end
            reaper.ImGui_ProgressBar(ctx, fraction, -1, 0,
                                     (string.format("%d/%d", loading_current, loading_total)))
        else
            if reaper.ImGui_BeginTabBar(ctx, "##MainTabs") then
                ---------------------------------------
                -- Template Loader Tab
                ---------------------------------------
                if reaper.ImGui_BeginTabItem(ctx, "Template Loader") then
                    if mode ~= "Track Templates" and mode ~= "Template Groups" then
                        mode = "Track Templates"
                        read_templates()
                        filter_templates()
                    end

                    if reaper.ImGui_BeginTabBar(ctx, "##ModeTabBar") then
                        if reaper.ImGui_BeginTabItem(ctx, "Track Templates") then
                            if mode ~= "Track Templates" then
                                mode = "Track Templates"
                                read_templates()
                                filter_templates()
                            end
                            reaper.ImGui_EndTabItem(ctx)
                        end
                        if reaper.ImGui_BeginTabItem(ctx, "Template Groups") then
                            if mode ~= "Template Groups" then
                                mode = "Template Groups"
                                read_templates()
                                filter_templates()
                            end
                            reaper.ImGui_EndTabItem(ctx)
                        end
                        reaper.ImGui_EndTabBar(ctx)
                    end

                    reaper.ImGui_Separator(ctx)
                    if first_frame then
                        reaper.ImGui_SetKeyboardFocusHere(ctx)
                        first_frame = false
                    end
                    local filter_changed
                    filter_changed, filter_text = reaper.ImGui_InputText(ctx, "Filter", filter_text)
                    if filter_changed then
                        filter_templates()
                    end

                    if reaper.ImGui_Button(ctx, "Shuffle") then
                        shuffle_templates()
                    end
                    reaper.ImGui_SameLine(ctx)
                    if reaper.ImGui_Button(ctx, "Edit Tags") then
                        if #selected_indices > 0 then
                            selected_templates_for_tag_edit = {}
                            local first_tags = {}
                            local first_set = false
                            for _, idx in ipairs(selected_indices) do
                                local t = filtered_templates[idx]
                                table.insert(selected_templates_for_tag_edit, t)
                                if not first_set then
                                    first_tags = {unpack(t.tags)}
                                    first_set = true
                                else
                                    local common = {}
                                    for _, tag in ipairs(t.tags) do
                                        for __, ft in ipairs(first_tags) do
                                            if tag == ft then
                                                table.insert(common, tag)
                                                break
                                            end
                                        end
                                    end
                                    first_tags = common
                                end
                            end
                            tag_input_text = table.concat(first_tags, ", ")
                            reaper.ImGui_OpenPopup(ctx, "Edit Tags")
                        else
                            reaper.ShowMessageBox("Select at least one template.", "No Template Selected", 0)
                        end
                    end
                    reaper.ImGui_SameLine(ctx)
                    if reaper.ImGui_Button(ctx, "Delete") then
                        if #selected_indices > 0 then
                            delete_templates = {}
                            for _, idx in ipairs(selected_indices) do
                                table.insert(delete_templates, filtered_templates[idx])
                            end
                            confirm_delete = true
                            reaper.ImGui_OpenPopup(ctx, "Confirm Delete")
                        else
                            reaper.ShowMessageBox("Select at least one template to delete.", "No Templates Selected", 0)
                        end
                    end

                    reaper.ImGui_Separator(ctx)
                    local changed_auto
                    changed_auto, auto_preview_enabled = reaper.ImGui_Checkbox(ctx, "Auto Preview", auto_preview_enabled)
                    if changed_auto and not auto_preview_enabled then
                        stop_preview_track()
                    end

                    reaper.ImGui_Separator(ctx)
                    if reaper.ImGui_BeginListBox(ctx, "##templates", -1, -1) then
                        for i, template in ipairs(filtered_templates) do
                            local is_selected = false
                            for _, idx in ipairs(selected_indices) do
                                if idx == i then
                                    is_selected = true
                                    break
                                end
                            end
                            reaper.ImGui_PushID(ctx, i)
                            if reaper.ImGui_Selectable(ctx, template.name, is_selected) then
                                local key_mods = reaper.ImGui_GetKeyMods(ctx)
                                if key_mods & reaper.ImGui_Mod_Shift() ~= 0 and last_selected_index then
                                    local start_idx = math.min(last_selected_index, i)
                                    local end_idx = math.max(last_selected_index, i)
                                    selected_indices = {}
                                    for idx2 = start_idx, end_idx do
                                        table.insert(selected_indices, idx2)
                                    end
                                elseif key_mods & reaper.ImGui_Mod_Ctrl() ~= 0 then
                                    if is_selected then
                                        for idx2 = #selected_indices, 1, -1 do
                                            if selected_indices[idx2] == i then
                                                table.remove(selected_indices, idx2)
                                                break
                                            end
                                        end
                                    else
                                        table.insert(selected_indices, i)
                                    end
                                else
                                    selected_indices = {i}
                                end
                                last_selected_index = i

                                if auto_preview_enabled and #selected_indices == 1 then
                                    auto_preview_template(filtered_templates[i])
                                end
                            end
                            if reaper.ImGui_IsItemHovered(ctx) 
                               and reaper.ImGui_IsMouseDoubleClicked(ctx, 0) then
                                prepare_load({template}, false, function()
                                    open = false
                                end)
                            end
                            reaper.ImGui_PopID(ctx)
                        end
                        reaper.ImGui_EndListBox(ctx)
                    end

                    if reaper.ImGui_BeginPopupModal(ctx, "Edit Tags", nil, reaper.ImGui_WindowFlags_AlwaysAutoResize()) then
                        if #selected_templates_for_tag_edit > 0 then
                            reaper.ImGui_Text(ctx, "Editing tags for selected templates:")
                            for _, t in ipairs(selected_templates_for_tag_edit) do
                                reaper.ImGui_Text(ctx, "- " .. t.name)
                            end
                            local tag_changed
                            tag_changed, tag_input_text = reaper.ImGui_InputText(ctx, "Tags (comma-separated)", tag_input_text)
                            if reaper.ImGui_Button(ctx, "Save") then
                                local new_tags = {}
                                for tg in tag_input_text:gmatch("[^,%s]+") do
                                    table.insert(new_tags, tg)
                                end
                                for _, t in ipairs(selected_templates_for_tag_edit) do
                                    t.tags = new_tags
                                    for _, template in ipairs(templates) do
                                        if template.name == t.name then
                                            template.tags = new_tags
                                            break
                                        end
                                    end
                                end
                                local all_tags = {}
                                for _, template in ipairs(templates) do
                                    all_tags[template.name] = template.tags
                                end
                                local tag_file = (mode == "Track Templates") and tag_file_path or group_tag_file_path
                                save_tags(all_tags, tag_file)
                                selected_templates_for_tag_edit = {}
                                tag_input_text = ""
                                reaper.ImGui_CloseCurrentPopup(ctx)
                                filter_templates()
                            end
                            reaper.ImGui_SameLine(ctx)
                            if reaper.ImGui_Button(ctx, "Cancel") then
                                selected_templates_for_tag_edit = {}
                                tag_input_text = ""
                                reaper.ImGui_CloseCurrentPopup(ctx)
                            end
                        else
                            reaper.ImGui_Text(ctx, "No templates selected.")
                            if reaper.ImGui_Button(ctx, "Close") then
                                reaper.ImGui_CloseCurrentPopup(ctx)
                            end
                        end
                        reaper.ImGui_EndPopup(ctx)
                    end

                    if confirm_delete then
                        reaper.ImGui_OpenPopup(ctx, "Confirm Delete")
                        confirm_delete = false
                    end
                    if reaper.ImGui_BeginPopupModal(ctx, "Confirm Delete", nil, reaper.ImGui_WindowFlags_AlwaysAutoResize()) then
                        reaper.ImGui_Text(ctx, "Are you sure you want to delete the selected templates?")
                        if reaper.ImGui_Button(ctx, "Yes") then
                            delete_selected_templates(delete_templates)
                            delete_templates = {}
                            reaper.ImGui_CloseCurrentPopup(ctx)
                        end
                        reaper.ImGui_SameLine(ctx)
                        if reaper.ImGui_Button(ctx, "No") then
                            delete_templates = {}
                            reaper.ImGui_CloseCurrentPopup(ctx)
                        end
                        reaper.ImGui_EndPopup(ctx)
                    end

                    reaper.ImGui_EndTabItem(ctx)
                end

                ---------------------------------------
                -- AI Instrument Loader Tab
                ---------------------------------------
                if reaper.ImGui_BeginTabItem(ctx, "AI Instrument Loader") then
                    reaper.ImGui_Text(ctx, "Instructions for Instruments:")
                    local changed_instr, new_instr = reaper.ImGui_InputTextMultiline(ctx,
                                                                                     '##Instructions',
                                                                                     instructions,
                                                                                     600,
                                                                                     100)
                    if changed_instr then
                        instructions = new_instr
                    end

                    reaper.ImGui_Separator(ctx)
                    reaper.ImGui_Text(ctx, "Number of Instruments:")
                    reaper.ImGui_SameLine(ctx)
                    local changed_num, new_num = reaper.ImGui_InputInt(ctx, '##NumInstruments', desired_instruments, 1, 10)
                    if changed_num then
                        if new_num >= 1 then
                            desired_instruments = new_num
                        end
                    end

                    if reaper.ImGui_Button(ctx, "Generate Prompt") then
                        generate_prompt_for_ai()
                    end

                    reaper.ImGui_Separator(ctx)
                    if generated_prompt ~= "" then
                        reaper.ImGui_Text(ctx, "Generated Prompt (Read-only):")
                        reaper.ImGui_InputTextMultiline(ctx, '##GeneratedPrompt', generated_prompt, 600, 150, reaper.ImGui_InputTextFlags_ReadOnly())
                    end

                    reaper.ImGui_Separator(ctx)
                    reaper.ImGui_Text(ctx, "Paste AI Response:")
                    local response_changed, new_response = reaper.ImGui_InputTextMultiline(ctx, '##AIResponse', ai_response, 600, 100)
                    if response_changed then
                        ai_response = new_response
                    end

                    if reaper.ImGui_Button(ctx, "Apply AI Response") then
                        apply_ai_response()
                    end
                    reaper.ImGui_SameLine(ctx)
                    if reaper.ImGui_Button(ctx, "Clear Response") then
                        ai_response = ""
                    end

                    reaper.ImGui_EndTabItem(ctx)
                end

                ---------------------------------------
                -- AI Auto Tagger Tab
                ---------------------------------------
                if reaper.ImGui_BeginTabItem(ctx, "AI Auto Tagger") then
                    reaper.ImGui_Text(ctx, "Enter a single tag you want to add:")
                    local tagger_changed, tagger_new = reaper.ImGui_InputText(ctx, "##AITaggerTag", ai_tagger_tag)
                    if tagger_changed then
                        ai_tagger_tag = tagger_new
                    end

                    if reaper.ImGui_Button(ctx, "Generate Tagger Prompt") then
                        generate_ai_tagger_prompt()
                    end

                    reaper.ImGui_Separator(ctx)
                    reaper.ImGui_Text(ctx, "Paste AI Tagger Response:")
                    local at_resp_changed, at_resp_new = reaper.ImGui_InputTextMultiline(ctx, "##AITaggerResponse", ai_tagger_response, 600, 100)
                    if at_resp_changed then
                        ai_tagger_response = at_resp_new
                    end

                    if reaper.ImGui_Button(ctx, "Apply AI Tagger Response") then
                        apply_ai_tagger_response()
                    end
                    reaper.ImGui_SameLine(ctx)
                    if reaper.ImGui_Button(ctx, "Clear Tagger Response") then
                        ai_tagger_response = ""
                    end

                    reaper.ImGui_EndTabItem(ctx)
                end

                reaper.ImGui_EndTabBar(ctx)
            end
        end

        if reaper.ImGui_IsWindowFocused(ctx) and not loading_in_progress then
            if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Enter()) 
               or reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_KeypadEnter()) then
                if #selected_indices > 0 then
                    local to_load = {}
                    for _, idx in ipairs(selected_indices) do
                        table.insert(to_load, filtered_templates[idx])
                    end
                    prepare_load(to_load, false, function()
                        open = false
                    end)
                end
            elseif reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape()) then
                if #selected_templates_for_tag_edit > 0 then
                    selected_templates_for_tag_edit = {}
                    tag_input_text = ""
                else
                    open = false
                end
            elseif reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_UpArrow()) then
                if #filtered_templates > 0 then
                    local last_selected = selected_indices[#selected_indices] or 1
                    last_selected = math.max(1, last_selected - 1)
                    selected_indices = {last_selected}
                    last_selected_index = last_selected
                    if auto_preview_enabled and #selected_indices == 1 then
                        auto_preview_template(filtered_templates[last_selected])
                    end
                end
            elseif reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_DownArrow()) then
                if #filtered_templates > 0 then
                    local last_selected = selected_indices[#selected_indices] or 0
                    last_selected = math.min(#filtered_templates, last_selected + 1)
                    selected_indices = {last_selected}
                    last_selected_index = last_selected
                    if auto_preview_enabled and #selected_indices == 1 then
                        auto_preview_template(filtered_templates[last_selected])
                    end
                end
            end
        end

        reaper.ImGui_End(ctx)
    end

    if open then
        reaper.defer(main)
    else
        stop_preview_track()
        if reaper.ImGui_DestroyContext then
            reaper.ImGui_DestroyContext(ctx)
        end
    end
end

--------------------------------------------------
-- SCRIPT START: auto-save tracks + group, then UI
--------------------------------------------------
math.randomseed(os.time())

-- 1) Save all current tracks as templates.
save_all_tracks_as_templates_auto()

-- 2) Also auto-save them as a single "template group" under project name.
auto_save_template_group()

-- 3) Now proceed with reading templates & opening the UI
read_templates()
filter_templates()
main()


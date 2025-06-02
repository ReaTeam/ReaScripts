-- @description Visibility manager
-- @author Julyday
-- @version 1.0.0
-- @about
--   This plugin creates a GUI window that allows you to show/hide groups of tracks in REAPER.
--
--   # Features
--   - Toggle visibility of track groups with simple button clicks
--   - Visual indicators (Green = all visible, Red = some/all hidden)
--   - Add custom groups on the fly
--   - Show/hide all tracks at once
--   - Automatic group creation and management
--   # How to Use
--   1. Run the script to open the track group visibility manager
--   2. Left-click any group button to toggle visibility of all tracks in that group
--   3. Right-click any group button to delete that group
--   4. Use bottom buttons for additional actions (Show All, Hide All Groups, Custom)
--   # How Groups Work
--   A track belongs to a group if:
--   - The track name exactly matches the group name, OR
--   - The track is a child of a track whose name matches the group name
--
--   Groups are stored in "VisibilityManager.ini" file in your project directory.
--   Default groups: Music, Voice, SFX, FX, Trash
--
--   # Donations (crypto):
--   USDT (TRC20) - TTYgm2v1PV6hXYnqNu6hZb9ddu6TSqzZkU
--   USDT (ERC20) - 0x481728FD856603ECaB8b222DFC2428E67Fd92E4E
--   Bitcoin (BTC) - 18viyeLPCSYosz1bVw3aavC189Y2jE3SFm
--   Toncoin (TON) - UQAqtnyzZxDpGB6Os0HbSG1LZdq57MxDXIGoNFyGDvHHZPB8
--   Etherium (ETH) - 00x481728FD856603ECaB8b222DFC2428E67Fd92E4E
--   TRON     (TRX) - TVXuH9mJgDsRkb1CzBSHCdMKC7eRKxcqei


function read_groups()
  local groups = {"Music", "Voice", "SFX", "FX", "Trash"}
  local path = reaper.GetProjectPath() .. "/VisibilityManager.ini"
  local file = io.open(path, "r")

  if file then
    groups = {}
    for line in file:lines() do
      if line ~= "" then
        table.insert(groups, line)
      end
    end
    file:close()
  else
    file = io.open(path, "w")
    if file then
      for _, group in ipairs(groups) do
        file:write(group .. "\n")
      end
      file:close()
    end
  end

  return groups
end

function save_groups(groups)
  local path = reaper.GetProjectPath() .. "/VisibilityManager.ini"
  local file = io.open(path, "w")

  if file then
    for _, group in ipairs(groups) do
      file:write(group .. "\n")
    end
    file:close()
  end
end

function is_track_in_group(track, group_name)
  local _, track_name = reaper.GetTrackName(track)

  if track_name == group_name then
    return true
  end

  local parent = reaper.GetParentTrack(track)
  while parent do
    local _, parent_name = reaper.GetTrackName(parent)
    if parent_name == group_name then
      return true
    end
    parent = reaper.GetParentTrack(parent)
  end

  return false
end

function is_group_visible(group_name)
  local found_tracks = 0
  local visible_tracks = 0

  local track_count = reaper.CountTracks(0)
  for i = 0, track_count - 1 do
    local track = reaper.GetTrack(0, i)
    if is_track_in_group(track, group_name) then
      found_tracks = found_tracks + 1
      if reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP") == 1 then
        visible_tracks = visible_tracks + 1
      end
    end
  end

  if found_tracks == 0 then
    return true
  end

  return visible_tracks == found_tracks
end

function toggle_group_visibility(group_name)
  local any_hidden = false
  local tracks_in_group = {}

  local track_count = reaper.CountTracks(0)
  for i = 0, track_count - 1 do
    local track = reaper.GetTrack(0, i)
    if is_track_in_group(track, group_name) then
      table.insert(tracks_in_group, track)

      if reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP") == 0 then
        any_hidden = true
      end
    end
  end

  if #tracks_in_group == 0 then
    if not track_with_name_exists(group_name) then
      local new_track = create_track_with_name(group_name)
      table.insert(tracks_in_group, new_track)
      any_hidden = false
    end
  end

  local new_visibility = any_hidden and 1 or 0
  for _, track in ipairs(tracks_in_group) do
    reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", new_visibility)
    reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", new_visibility)
  end

  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()
end

function show_all_tracks()
  local track_count = reaper.CountTracks(0)
  for i = 0, track_count - 1 do
    local track = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 1)
    reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 1)
  end

  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()
end

function hide_all_groups(groups)
  local tracks_to_hide = {}
  local track_count = reaper.CountTracks(0)

  for i = 0, track_count - 1 do
    local track = reaper.GetTrack(0, i)

    for _, group in ipairs(groups) do
      if is_track_in_group(track, group) then
        tracks_to_hide[tostring(track)] = track
        break
      end
    end
  end

  for _, track in pairs(tracks_to_hide) do
    reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 0)
    reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 0)
  end

  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()
end

function add_custom_group(groups)
  local retval, name = reaper.GetUserInputs("Add Group", 1, "Group Name:,extrawidth=150", "")

  if retval and name ~= "" then
    table.insert(groups, name)
    save_groups(groups)
    return true
  end

  return false
end

function remove_group(groups, index)
  local group_name = groups[index]
  local confirm = reaper.MB("Are you sure you want to delete the group '" .. group_name .. "'?", "Confirm deletion", 4)

  if confirm == 6 then
    table.remove(groups, index)
    save_groups(groups)
    return true
  end

  return false
end

function track_with_name_exists(name)
  local track_count = reaper.CountTracks(0)
  for i = 0, track_count - 1 do
    local track = reaper.GetTrack(0, i)
    local _, track_name = reaper.GetTrackName(track)
    if track_name == name then
      return true
    end
  end
  return false
end

function create_track_with_name(name)
  local track_count = reaper.CountTracks(0)

  reaper.InsertTrackAtIndex(track_count, true)

  local new_track = reaper.GetTrack(0, track_count)

  reaper.GetSetMediaTrackInfo_String(new_track, "P_NAME", name, true)

  return new_track
end

local groups = read_groups()
local last_clicked = 0
local active_button = nil

function update_ui()
  gfx.set(0.2, 0.2, 0.2, 1.0)
  gfx.rect(0, 0, gfx.w, gfx.h, 1)

  for i, group in ipairs(groups) do
    local btn_x = 20
    local btn_y = 10 + (i-1) * 30
    local btn_w = gfx.w - 40
    local btn_h = 25

    local is_visible = is_group_visible(group)

    local is_pressed = (active_button == i)

    if is_visible then
      gfx.set(0.2, 0.5, 0.2, 1.0)
    else
      gfx.set(0.5, 0.2, 0.2, 1.0)
    end

    local offset_x, offset_y = 0, 0
    if is_pressed then
      offset_x, offset_y = 2, 2
      gfx.set(gfx.r * 0.8, gfx.g * 0.8, gfx.b * 0.8, 1.0)
    end

    gfx.rect(btn_x + offset_x, btn_y + offset_y, btn_w, btn_h, 1)

    if not is_pressed then
      gfx.set(0.1, 0.1, 0.1, 0.5)
      gfx.rect(btn_x + 2, btn_y + 2, btn_w, btn_h, 0)

      gfx.set(1, 1, 1, 0.2)
      gfx.line(btn_x, btn_y, btn_x + btn_w, btn_y)
      gfx.line(btn_x, btn_y, btn_x, btn_y + btn_h)
    end

    gfx.set(0.9, 0.9, 0.9, 1.0)
    gfx.setfont(1, "Arial", 14)
    local text_w, text_h = gfx.measurestr(group)
    gfx.x = btn_x + offset_x + (btn_w - text_w) / 2
    gfx.y = btn_y + offset_y + (btn_h - text_h) / 2
    gfx.drawstr(group)

    if gfx.mouse_cap == 1 and gfx.mouse_x >= btn_x and gfx.mouse_x <= btn_x + btn_w and
       gfx.mouse_y >= btn_y and gfx.mouse_y <= btn_y + btn_h then
      active_button = i

      if last_clicked == 0 then
        toggle_group_visibility(group)
        last_clicked = reaper.time_precise()
      end
    elseif gfx.mouse_cap == 2 and gfx.mouse_x >= btn_x and gfx.mouse_x <= btn_x + btn_w and
           gfx.mouse_y >= btn_y and gfx.mouse_y <= btn_y + btn_h then
      if last_clicked == 0 then
        if remove_group(groups, i) then
          gfx.quit()
          init()
          return
        end
        last_clicked = reaper.time_precise()
      end
    end
  end

  local btn_height = 25
  local btn_margin = 5
  local bottom_panel_y = 10 + #groups * 30
  local btn_width = (gfx.w - (3 * btn_margin) - 40) / 3

  local btn_show_x = 20
  local btn_show_y = bottom_panel_y
  local btn_show_w = btn_width
  local btn_show_h = btn_height

  local is_show_pressed = (active_button == "show_all")
  local offset_x, offset_y = 0, 0

  if is_show_pressed then
    gfx.set(0.2, 0.4, 0.2, 1.0)
    offset_x, offset_y = 2, 2
  else
    gfx.set(0.3, 0.5, 0.3, 1.0)
  end

  gfx.rect(btn_show_x + offset_x, btn_show_y + offset_y, btn_show_w, btn_show_h, 1)

  if not is_show_pressed then
    gfx.set(0.1, 0.1, 0.1, 0.5)
    gfx.rect(btn_show_x + 2, btn_show_y + 2, btn_show_w, btn_show_h, 0)

    gfx.set(1, 1, 1, 0.2)
    gfx.line(btn_show_x, btn_show_y, btn_show_x + btn_show_w, btn_show_y)
    gfx.line(btn_show_x, btn_show_y, btn_show_x, btn_show_y + btn_show_h)
  end

  gfx.set(0.9, 0.9, 0.9, 1.0)
  gfx.setfont(1, "Arial", 14)
  local text_w, text_h = gfx.measurestr("Show All")
  gfx.x = btn_show_x + offset_x + (btn_show_w - text_w) / 2
  gfx.y = btn_show_y + offset_y + (btn_show_h - text_h) / 2
  gfx.drawstr("Show All")

  local btn_hide_x = btn_show_x + btn_show_w + btn_margin
  local btn_hide_y = bottom_panel_y
  local btn_hide_w = btn_width
  local btn_hide_h = btn_height

  local is_hide_pressed = (active_button == "hide_all")
  offset_x, offset_y = 0, 0

  if is_hide_pressed then
    gfx.set(0.4, 0.2, 0.2, 1.0)
    offset_x, offset_y = 2, 2
  else
    gfx.set(0.5, 0.3, 0.3, 1.0)
  end

  gfx.rect(btn_hide_x + offset_x, btn_hide_y + offset_y, btn_hide_w, btn_hide_h, 1)

  if not is_hide_pressed then
    gfx.set(0.1, 0.1, 0.1, 0.5)
    gfx.rect(btn_hide_x + 2, btn_hide_y + 2, btn_hide_w, btn_hide_h, 0)

    gfx.set(1, 1, 1, 0.2)
    gfx.line(btn_hide_x, btn_hide_y, btn_hide_x + btn_hide_w, btn_hide_y)
    gfx.line(btn_hide_x, btn_hide_y, btn_hide_x, btn_hide_y + btn_hide_h)
  end

  gfx.set(0.9, 0.9, 0.9, 1.0)
  local text_w, text_h = gfx.measurestr("Hide All Groups")
  gfx.x = btn_hide_x + offset_x + (btn_hide_w - text_w) / 2
  gfx.y = btn_hide_y + offset_y + (btn_hide_h - text_h) / 2
  gfx.drawstr("Hide All Groups")

  local btn_custom_x = btn_hide_x + btn_hide_w + btn_margin
  local btn_custom_y = bottom_panel_y
  local btn_custom_w = btn_width
  local btn_custom_h = btn_height

  local is_custom_pressed = (active_button == "custom")
  offset_x, offset_y = 0, 0

  if is_custom_pressed then
    gfx.set(0.3, 0.3, 0.5, 1.0)
    offset_x, offset_y = 2, 2
  else
    gfx.set(0.4, 0.4, 0.6, 1.0)
  end

  gfx.rect(btn_custom_x + offset_x, btn_custom_y + offset_y, btn_custom_w, btn_custom_h, 1)

  if not is_custom_pressed then
    gfx.set(0.1, 0.1, 0.1, 0.5)
    gfx.rect(btn_custom_x + 2, btn_custom_y + 2, btn_custom_w, btn_custom_h, 0)

    gfx.set(1, 1, 1, 0.2)
    gfx.line(btn_custom_x, btn_custom_y, btn_custom_x + btn_custom_w, btn_custom_y)
    gfx.line(btn_custom_x, btn_custom_y, btn_custom_x, btn_custom_y + btn_custom_h)
  end

  gfx.set(0.9, 0.9, 0.9, 1.0)
  local text_w, text_h = gfx.measurestr("Custom")
  gfx.x = btn_custom_x + offset_x + (btn_custom_w - text_w) / 2
  gfx.y = btn_custom_y + offset_y + (btn_custom_h - text_h) / 2
  gfx.drawstr("Custom")

  if gfx.mouse_cap == 1 then
    if gfx.mouse_x >= btn_show_x and gfx.mouse_x <= btn_show_x + btn_show_w and
       gfx.mouse_y >= btn_show_y and gfx.mouse_y <= btn_show_y + btn_show_h then
      active_button = "show_all"
      if last_clicked == 0 then
        show_all_tracks()
        last_clicked = reaper.time_precise()
      end
    elseif gfx.mouse_x >= btn_hide_x and gfx.mouse_x <= btn_hide_x + btn_hide_w and
           gfx.mouse_y >= btn_hide_y and gfx.mouse_y <= btn_hide_y + btn_hide_h then
      active_button = "hide_all"
      if last_clicked == 0 then
        hide_all_groups(groups)
        last_clicked = reaper.time_precise()
      end
    elseif gfx.mouse_x >= btn_custom_x and gfx.mouse_x <= btn_custom_x + btn_custom_w and
           gfx.mouse_y >= btn_custom_y and gfx.mouse_y <= btn_custom_y + btn_custom_h then
      active_button = "custom"
      if last_clicked == 0 then
        if add_custom_group(groups) then
          gfx.quit()
          init()
          return
        end
        last_clicked = reaper.time_precise()
      end
    end
  else
    active_button = nil
  end

  if last_clicked ~= 0 and reaper.time_precise() > last_clicked + 0.3 then
    last_clicked = 0
  end

  local char = gfx.getchar()
  if char == 27 or char == -1 then
    gfx.quit()
    return
  end

  gfx.update()
  reaper.defer(update_ui)
end

function init()
  gfx.init("Track Group Visibility Manager", 300, 45 + #groups * 30)
  gfx.setfont(1, "Arial", 14)
  update_ui()
end

reaper.Undo_BeginBlock()
init()
reaper.Undo_EndBlock("Hider Script", -1)

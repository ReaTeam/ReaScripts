-- @description Razor Edit Track Groups
-- @author amagalma
-- @version 1.11
-- @changelog OSX: fixed crash with invalid font size
-- @link https://forum.cockos.com/showthread.php?t=263486
-- @donation https://www.paypal.me/amagalma
-- @about
--   A track selection can be stored as a Razor Edit Track Group. When a group is enabled, creating a razor edit, for any of its members, duplicates the edit to the rest of the group.
--   Razor edits on envelopes will be duplicated on envelopes of tracks that belong to the same group, only if their envelope name and chunk name match.
--
--   For the time being, the script supports one group, but support for more (infinite number of) groups can be added in the future, if required.
--
--   - Requires ReaImGui

-- DISPLAY SETTINGS ---------------
local font_size = 13
local font_type = 'Lucida Console'
-----------------------------------

--------------------------------------------------------------------------------------

local GroupGUIDs = {}
local TracksByGroup = {}
local LastRazorEditsByTrack = {}
local TrackList = {}
local TrackList_text
local Enabled = false

local match, lower = string.match, string.lower

local _, _, section, cmdID = reaper.get_action_context()
reaper.SetToggleCommandState( section, cmdID, 1 ) -- Set ON
reaper.RefreshToolbar2( section, cmdID )

reaper.atexit(function()
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
end)

--------------------------------------------------------------------------------------

local function AddSelectedTracksToGroup( group_guid )
  if not group_guid then group_guid = reaper.genGuid() end
  if not GroupGUIDs[group_guid] then GroupGUIDs[group_guid] = {} end
  for tr = 0, reaper.CountSelectedTracks( 0 )-1 do
    local track = reaper.GetSelectedTrack( 0, tr )
    GroupGUIDs[group_guid][track] = true
    TracksByGroup[track] = group_guid
    local name = ({reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )})[2]
    TrackList[tr+1] = string.format("Track%4i%s", math.tointeger(reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER")),
                      (name ~= "" and "  -  " or "") .. name)
  end
  return group_guid
end

--------------------------------------------------------------------------------------

local function ValidateTracksInGroup( group_guid )
  local tracks, t = {}, 0
  for track in pairs(GroupGUIDs[group_guid]) do
    if reaper.ValidatePtr2( 0, track, "MediaTrack*" ) then
      t = t + 1
      tracks[t] = track
    else
      GroupGUIDs[group_guid][track] = nil
    end
  end
  return tracks
end

--------------------------------------------------------------------------------------

local function GetRazorEditsForTracksInGroups()
  local tracks = {}
  for track in pairs(TracksByGroup) do
    tracks[track] = ({reaper.GetSetMediaTrackInfo_String( track, "P_RAZOREDITS", "", false )})[2]
  end
  return tracks
end

--------------------------------------------------------------------------------------

local function GetTrackEnvelopeInfoFromRazorEdits( track, razor_edit )
  local t, added = {}
  for env_guid in razor_edit:gmatch("{.-}") do
    added = true
    local env = reaper.GetTrackEnvelopeByChunkName( track, env_guid )
    local _, env_name = reaper.GetEnvelopeName( env )
    env_name = env_name .. ({reaper.GetEnvelopeStateChunk( env, "", false )})[2]:match("[^\n]+")
    t[env_guid] = env_name
  end
  return (added and t)
end

--------------------------------------------------------------------------------------

local function GetAllTrackEnvelopesInfo( track )
  local t = {}
  for e = 0, reaper.CountTrackEnvelopes( track )-1 do
    local env = reaper.GetTrackEnvelope( track, e )
    local _, env_name = reaper.GetEnvelopeName( env )
    local _, env_guid = reaper.GetSetEnvelopeInfo_String( env, "GUID", "", false )
    env_name = env_name .. ({reaper.GetEnvelopeStateChunk( env, "", false )})[2]:match("[^\n]+")
    t[env_name] = env_guid
  end
  return t
end

--------------------------------------------------------------------------------------

local function ApplyChangesToGroups()
  local new_razor_edits = GetRazorEditsForTracksInGroups()
  -- Validate Groups
  local validated_groups = {}
  for group_guid in pairs(GroupGUIDs) do
    validated_groups[group_guid] = ValidateTracksInGroup(group_guid)
  end
  reaper.PreventUIRefresh( 1 )
  for group_guid, tracks in pairs(validated_groups) do
    local changed_track, new_razor_edit, envelopes_in_changed_track_RE
    local track_cnt = #tracks
    for i = 1, track_cnt do
      local track = validated_groups[group_guid][i]
      -- if no previous razor edit, or different razor edit then apply changes to group
      if not LastRazorEditsByTrack[track] or
        (new_razor_edits[track] ~= "" and new_razor_edits[track] ~= LastRazorEditsByTrack[track]) then
        new_razor_edit = new_razor_edits[track]
        changed_track = track
        envelopes_in_changed_track_RE = GetTrackEnvelopeInfoFromRazorEdits( changed_track, new_razor_edit )
        break
      end
    end
    if new_razor_edit then
      for i = 1, track_cnt do
        if changed_track ~= tracks[i] then
          if envelopes_in_changed_track_RE then
            -- Create razor edits for envelopes with same name and chunkname
            local env_info = GetAllTrackEnvelopesInfo( tracks[i] )
            local t, t_cnt = {}, 0
            for area_st, area_en, guid in new_razor_edit:gmatch('(%S+ )(%S+ )"(%S-)"') do
              if guid == '' then
                t_cnt = t_cnt + 1
                t[t_cnt] = area_st .. area_en .. '""'
              else
                local env_name = envelopes_in_changed_track_RE[guid]
                --reaper.ShowConsoleMsg(env_name.."\n")
                if env_info[env_name] then
                  t_cnt = t_cnt + 1
                  t[t_cnt] = area_st .. area_en .. '"' .. env_info[env_name] .. '"'
                end
              end
            end
            reaper.GetSetMediaTrackInfo_String( tracks[i], "P_RAZOREDITS", table.concat(t, " "), true )
          else
            reaper.GetSetMediaTrackInfo_String( tracks[i], "P_RAZOREDITS", new_razor_edit, true )
          end
        end
      end
    end
  end
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
  LastRazorEditsByTrack = new_razor_edits -- Replace the table with the last info
end

--------------------------------------------------------------------------------------

local lastProjectChangeCount = reaper.GetProjectStateChangeCount(0)

local function CheckForChanges()
  local projectChangeCount = reaper.GetProjectStateChangeCount(0)
  if lastProjectChangeCount ~= projectChangeCount then
    local action = reaper.Undo_CanUndo2( 0 )
    --reaper.ShowConsoleMsg(projectChangeCount .. " " .. action .. "\n")
    if match( lower(action), "razor" ) then
      ApplyChangesToGroups()
      --reaper.ShowConsoleMsg("apply\n")
    end
    lastProjectChangeCount = projectChangeCount
  end
end

--------------------------------------------------------------------------------------
---------
-- GUI --
---------

local ctx = reaper.ImGui_CreateContext('Apply Razor Edits to Group', reaper.ImGui_ConfigFlags_NoSavedSettings())
local font = reaper.ImGui_CreateFont(font_type, reaper.GetAppVersion():match('OSX') and math.floor(font_size*0.8 + 0.5) or font_size)
reaper.ImGui_AttachFont(ctx, font)

local col_button = reaper.ImGui_Col_Button()
local enabled_color = reaper.ImGui_GetStyleColor( ctx, col_button )
local enabled_button_display = "Disabled###State"
local enabled_button_width, enabled_button_position
local active_col, norm_col = reaper.ImGui_GetStyleColor( ctx, reaper.ImGui_Col_ButtonActive() ), enabled_color

local window_flags = reaper.ImGui_WindowFlags_NoSavedSettings() | reaper.ImGui_WindowFlags_AlwaysAutoResize()

local collapsing_flags = reaper.ImGui_TreeNodeFlags_AllowItemOverlap() | reaper.ImGui_TreeNodeFlags_DefaultOpen()

local group_one = reaper.genGuid()


local function ToggleEnable()
  if Enabled then
    lastProjectChangeCount = reaper.GetProjectStateChangeCount(0)
    enabled_button_display = "Enabled###State"
    enabled_color = active_col
  else
    enabled_button_display = "Disabled###State"
    enabled_color = norm_col
  end
end

local once = 0

local function main()
  if Enabled then
    CheckForChanges()
  end

  reaper.ImGui_PushFont(ctx, font)
  local visible, open = reaper.ImGui_Begin(ctx, "Razor Edit Group", true, window_flags)

  if visible then
    if once ~= 2 then
      local actual_font_size = reaper.ImGui_GetFontSize( ctx )
      local enabled_button_width = math.floor(6 * actual_font_size + 0.5)
      enabled_button_position = reaper.ImGui_GetWindowWidth(ctx) - enabled_button_width - actual_font_size/2
      once = once + 1
    end

    if reaper.ImGui_Button( ctx, "Set Group to Track Selection" ) then
      if reaper.CountSelectedTracks( 0 ) > 1 then
        GroupGUIDs[group_one] = nil
        TracksByGroup = {}
        TrackList = {}
        AddSelectedTracksToGroup(group_one)
        LastRazorEditsByTrack = GetRazorEditsForTracksInGroups()
        TrackList_text = table.concat(TrackList, "\n")
        Enabled = true
        ToggleEnable()
      end
    end
    local open_colapse = reaper.ImGui_CollapsingHeader( ctx, "Current Group:", false, collapsing_flags )
    reaper.ImGui_SameLine( ctx )
    reaper.ImGui_SetCursorPosX( ctx, enabled_button_position )
    reaper.ImGui_PushStyleColor( ctx, col_button, enabled_color )
    if reaper.ImGui_Button( ctx, enabled_button_display, enabled_button_width ) then
      if GroupGUIDs[group_one] then
        Enabled = not Enabled
        ToggleEnable()
      end
    end
    reaper.ImGui_PopStyleColor( ctx )
    if open_colapse and TrackList_text then
      if Enabled then
        reaper.ImGui_Text( ctx, TrackList_text)
      else
        reaper.ImGui_TextColored( ctx, 0xFFFFFF85, TrackList_text)
      end
    end
    reaper.ImGui_End(ctx)
  end
  reaper.ImGui_PopFont(ctx)

  if open then
    reaper.defer(main)
  else
    reaper.ImGui_DestroyContext(ctx)
  end
end

--------------------------------------------------------------------------------------

reaper.defer(main)

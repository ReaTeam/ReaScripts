-- @description Razor Edit Track Groups
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showthread.php?t=263486
-- @donation https://www.paypal.me/amagalma
-- @about
--   A track selection can be stored as a Razor Edit Track Group. When a group is enabled, creating a razor edit, for any of its members, duplicates the edit to the rest of the group.
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

local function ApplyChangesToGroups()
  local new_razor_edits = GetRazorEditsForTracksInGroups()
  -- Validate Groups
  local validated_groups = {}
  for group_guid in pairs(GroupGUIDs) do
    validated_groups[group_guid] = ValidateTracksInGroup(group_guid)
  end
  reaper.PreventUIRefresh( 1 )
  for group_guid, tracks in pairs(validated_groups) do
    local apply = false
    local changed_track
    local track_cnt = #tracks
    for i = 1, track_cnt do
      local track = validated_groups[group_guid][i]
      -- if no previous razor edit, or different razor edit then apply changes to group
      if not LastRazorEditsByTrack[track] or
        (new_razor_edits[track] ~= "" and new_razor_edits[track] ~= LastRazorEditsByTrack[track]) then
        apply = new_razor_edits[track]
        changed_track = track
        --reaper.ShowConsoleMsg(new_razor_edits[track].. "\n")
        break
      end
    end
    if apply then
      for i = 1, track_cnt do
        if changed_track ~= tracks[i] then
          reaper.GetSetMediaTrackInfo_String( tracks[i], "P_RAZOREDITS", apply, true )
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
local font = reaper.ImGui_CreateFont(font_type, reaper.GetAppVersion():match('OSX') and font_size*0.8 or font_size)
reaper.ImGui_AttachFont(ctx, font)

local col_button = reaper.ImGui_Col_Button()
local enabled_color = reaper.ImGui_GetStyleColor( ctx, col_button )
local enabled_button_display = "Disabled###State"
local enabled_button_width
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

-- @description Toggle hide tracks with no items in current time selection
-- @author Rodilab
-- @version 1.0
-- @about
--   - Toggle on : Hide tracks with no items in current time selection
--   - Toggle off : Show all tracks (except for those that were already hidden) 
--
--   Some option on the top of code :
--   - Show/Hide in TCP (default: true)
--   - Show/Hide in MCP (default: false)
--   - Don't show tracks that are already hidden, even if they have items in time selection (default: true)
--   - Show parents tracks too (default: true)
--   - Show/Hide sends destination tracks too (default: true)

--------------------------
-- User variables
--------------------------

TCP = true         -- Show/Hide in TCP
MCP = false        -- Show/Hide in MCP
IgnoreHiden = true -- Don't show tracks that are already hidden, even if they have items in time selection (default: true)
ShowParents = true -- Show parents tracks too
SendTracks = true  -- Show/Hide sends destination tracks too

--------------------------
-- ExtState
--------------------------

extstate_id = 'RODILAB_Hide_tracks_with_no_items_in_time_selection'

function GetMediaTrackByGuid(guid)
  local count = reaper.CountTracks(0)
  if count == 0 then return end
  for i=0, count-1 do
    local track = reaper.GetTrack(0, i)
    local tmp_guid = reaper.GetTrackGUID(track)
    if tmp_guid == guid then
      return track
    end
  end
  return nil
end

function ProjExtStateSave(str)
  reaper.SetProjExtState(0, extstate_id, 'hiden_tracks', str)
end

function ProjExtStateLoad()
  local list = {}
  local rv, str = reaper.GetProjExtState(0, extstate_id, 'hiden_tracks')
  if rv == 1 then
    for guid in string.gmatch(str, '[^;]+') do
      local track = GetMediaTrackByGuid(guid)
      if track then
        list[track] = true
      end
    end
  end
  return list
end

function DeleteExtState()
  reaper.SetProjExtState(0, extstate_id, '', '')
end

--------------------------
-- Code
--------------------------

function ShowAllTracks()
  local count = reaper.CountTracks(0)
  if count > 0 then
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()
    local list_hide = {}
    if IgnoreHiden then
      list_hide = ProjExtStateLoad()
    end
    for t=0, count-1 do
      local track = reaper.GetTrack(0, t)
      if not IgnoreHiden or not list_hide[track] then
        if TCP and reaper.GetMediaTrackInfo_Value(track, 'B_SHOWINTCP') == 0 then
          reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', 1)
        end
        if MCP and reaper.GetMediaTrackInfo_Value(track, 'B_SHOWINMIXER') == 0 then
          reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINMIXER', 1)
        end
      end
    end
    DeleteExtState()
    reaper.TrackList_AdjustWindows(false)
    reaper.Undo_EndBlock("Show all tracks",0)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
  end
end

function HideTracks()
  local sel_start, sel_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
  if sel_start < sel_end then
    local count = reaper.CountTracks(0)
    if count > 0 then
      local list_tracks = {}
      local list_hide = {}
      local list_send = {}
      local rv = false
      for t=0, count-1 do
        local track = reaper.GetTrack(0, t)
        if IgnoreHiden and reaper.GetMediaTrackInfo_Value(track, 'B_SHOWINTCP') == 0 then
          table.insert(list_hide, track)
        else
          local count_items = reaper.CountTrackMediaItems(track)
          if count_items > 0 then
            for i=0, count_items-1 do
              local item = reaper.GetTrackMediaItem(track, i)
              local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
              local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
              local stop = pos + length
              if (pos >= sel_start and pos <= sel_end)
              or (stop >= sel_start and stop <= sel_end)
              or (sel_start >= pos and sel_start <= stop) then
                rv = true
                list_tracks[track] = true
                if ShowParents then
                  local parent = reaper.GetParentTrack(track)
                  while parent do
                    list_tracks[parent] = true
                    parent = reaper.GetParentTrack(parent)
                  end
                end
                if SendTracks then
                  local count_sends = reaper.GetTrackNumSends(track, 0)
                  if count_sends > 0 then
                    for j=0, count_sends-1 do
                      local dest_track = reaper.GetTrackSendInfo_Value(track, 0, i, 'P_DESTTRACK')
                      list_tracks[dest_track] = true
                    end
                  end
                end
                break
              end
            end
          end
        end
      end
      if rv then
        reaper.PreventUIRefresh(1)
        reaper.Undo_BeginBlock()
        for t=0, count-1 do
          local track = reaper.GetTrack(0, t)
          if TCP then reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', list_tracks[track] and 1 or 0) end
          if MCP then reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINMIXER', list_tracks[track] and 1 or 0) end
        end
        DeleteExtState()
        if IgnoreHiden and #list_hide > 0 then
          local str
          for i, track in ipairs(list_hide) do
            local guid = reaper.GetTrackGUID(track)
            if not str then
              str = guid
            else
              str = str..';'..guid
            end
          end
          ProjExtStateSave(str)
        end
        reaper.TrackList_AdjustWindows(false)
        reaper.Undo_EndBlock("Hide tracks with no items in time selection",0)
        reaper.PreventUIRefresh(-1)
        reaper.UpdateArrange()
        return true
      end
    end
  end
  return false
end

function main()
  local is_new_value, filename, section_id, command_id = reaper.get_action_context()
  local state = reaper.GetToggleCommandStateEx(section_id, command_id)
  if state < 1 then
    if HideTracks() then
      state = 1
    end
  else
    state = 0
    ShowAllTracks()
  end
  reaper.SetToggleCommandState(section_id, command_id, state)
  reaper.RefreshToolbar2(section_id, command_id)
end

main()

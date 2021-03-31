-- @description Reorganize vertically all items in selected tracks according to track index metadata
-- @author Rodilab
-- @version 1.1
-- @changelog Update : Read iXML Track List metadata
-- @about
--   Reorganize vertically all items in selected tracks according to track index metadata.
--   To do this, items are moved up or down in the selected tracks.
--   If additional tracks are needed, then they are created (with the parameters of the first selected track).
--   Note: selected tracks must follow each other.
--
--   by Rodrigo Diaz (aka Rodilab)

-- List of track parameter to copy/past for new tracks
script_name = "Reorganize vertically all items in selected tracks according to track index metadata"

local track_parnames = {
  B_MUTE = "",
  B_PHASE = "",
  B_RECMON_IN_EFFECT = "",
  I_SOLO = "",
  I_FXEN = "",
  I_RECARM = "",
  I_RECINPUT = "",
  I_RECMODE = "",
  I_RECMON = "",
  I_RECMONITEMS = "",
  I_AUTOMODE = "",
  I_FOLDERCOMPACT = "",
  I_PERFFLAGS = "",
  I_CUSTOMCOLOR = "",
  I_HEIGHTOVERRIDE = "",
  B_HEIGHTLOCK = "",
  D_VOL = "",
  D_PAN = "",
  D_WIDTH = "",
  D_DUALPANL = "",
  D_DUALPANR = "",
  I_PANMODE = "",
  D_PANLAW = "",
  B_SHOWINMIXER = "",
  B_SHOWINTCP = "",
  B_MAINSEND = "",
  C_MAINSEND_OFFS = "",
  C_BEATATTACHMODE = "",
  F_MCP_FXSEND_SCALE = "",
  F_MCP_FXPARM_SCALE = "",
  F_MCP_SENDRGN_SCALE = "",
  F_TCP_FXPARM_SCALE = "",
  I_PLAY_OFFSET_FLAG = "",
  D_PLAY_OFFSET = ""
}

count_sel_tracks = reaper.CountSelectedTracks(0)
if count_sel_tracks > 0 then
  local track_ip

  -- Tracks follow each other
  local follow = true
  for i=0, count_sel_tracks-1 do
    local track = reaper.GetSelectedTrack(0,i)
    local track_ip = reaper.GetMediaTrackInfo_Value(track,"IP_TRACKNUMBER")
    if i == 0 then first_track_ip = track_ip end
    if i > 0 and track_ip ~= last_track_ip + 1 then
      follow = false
      break
    end
    last_track_ip = track_ip
  end

  local last_track = reaper.GetSelectedTrack(0,count_sel_tracks-1)
  for parname in pairs(track_parnames) do
    track_parnames[parname] = reaper.GetMediaTrackInfo_Value(last_track,parname)
  end

  if follow == true then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    local total_tracks = count_sel_tracks
    local list_move_item = {}
    for i=0, count_sel_tracks-1 do
      local track = reaper.GetSelectedTrack(0,i)
      local track_ip = reaper.GetMediaTrackInfo_Value(track,"IP_TRACKNUMBER")
      local count_items = reaper.CountTrackMediaItems(track)
      for j=0, count_items-1 do
        local item = reaper.GetTrackMediaItem(track,j)
        local take = reaper.GetActiveTake(item)
        if take then
          local source = reaper.GetMediaItemTake_Source(take)
          if reaper.GetMediaSourceType(source,"") == "WAVE" then

            -- Set all track index in a list
            local list_track_index = {}
            -- First search in iXML
            local retval, tracklist_count = reaper.GetMediaFileMetadata(source,"IXML:TRACK_LIST:TRACK_COUNT")
            if retval == 1 then
              for i=1, tracklist_count do
                local tracklist_interleave = ""
                if i > 1 then
                  tracklist_interleave = tracklist_interleave..":"..i
                end
                local retval, tracklist_index = reaper.GetMediaFileMetadata(source,"IXML:TRACK_LIST:TRACK:CHANNEL_INDEX"..tracklist_interleave)
                if retval == 1 then
                  table.insert(list_track_index,tonumber(tracklist_index))
                end
              end
            else
              -- No IXML Track List, search in BWF Description
              for i=1, 64 do
                local retval, description = reaper.GetMediaFileMetadata(source,"BWF:Description")
                if retval then
                  for w in string.gmatch(description, "([^\n\r]+)") do
                    for k, v in string.gmatch(w, "(.+)=(.+)") do
                      local find = string.find(k,"TRK")
                      if find then
                        local id = tonumber(string.sub(k,find+3,string.len(k)))
                        if id then
                          table.insert(list_track_index,id)
                        end
                      end
                    end
                  end
                end
              end
            end

            if #list_track_index > 0 then

              -- Get real first take channel
              local take_chanmode = reaper.GetMediaItemTakeInfo_Value(take,"I_CHANMODE")
              local take_channel = 1
              if take_chanmode >= 2 and take_chanmode <= 66 then
                -- Mono
                take_channel = take_chanmode - 2
              elseif take_chanmode > 66 then
                -- Stereo
                take_channel = take_chanmode - 66
              elseif take_chanmode == 1 then
                -- Invert
                take_channel = 2
              end

              if list_track_index[take_channel] then
                -- If track is not the good one
                if i ~= list_track_index[take_channel]-1 then
                  -- Add Track(s)
                  if list_track_index[take_channel] > total_tracks then
                    -- Get track info values
                    for j=1, list_track_index[take_channel]-total_tracks do
                      reaper.InsertTrackAtIndex(first_track_ip+(total_tracks-1),true)
                      local new_track = reaper.GetTrack(0,first_track_ip+(total_tracks-1))
                      total_tracks = total_tracks + 1
                      reaper.SetTrackSelected(new_track,true)
                      for parname, value in pairs(track_parnames) do
                        reaper.SetMediaTrackInfo_Value(new_track,parname,value)
                        reaper.GetSetMediaTrackInfo_String(new_track,"P_NAME",total_tracks,true)
                      end
                    end
                  end
                  -- Save items to move in list
                  local target_track = reaper.GetTrack(0,first_track_ip+list_track_index[take_channel]-2)
                  list_move_item[item] = target_track
                end -- if wrong track
              end -- If list_track_index[take_channel] is set
            end -- End if list_track_index is set
          end --  End if WAVE
        end -- End if take
      end -- End for item
    end -- End for track

    -- Move items
    for item, target_track in pairs(list_move_item) do
      reaper.MoveMediaItemToTrack(item,target_track)
    end
    reaper.Undo_EndBlock(script_name,0)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
  else
    reaper.ShowMessageBox("Error: Selected tracks must follow each other",script_name,0)
  end -- If follow
end -- If tracks selected

-- @description Explode multichannel items to mono items in new tracks (without render)
-- @author Rodilab
-- @version 1.1
-- @about
--   Explode multichannel selected items to mono items in new tracks (without render new source files).
--   This script changes the channel mode of the takes, and preserve media source file.
--
--   by Rodrigo Diaz (aka Rodilab)

local count = reaper.CountSelectedMediaItems(0)
if count > 0 then
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()
  -- Save selected items in a list
  local item_list={}
  for i=0, count-1 do
    item_list[i+1] = reaper.GetSelectedMediaItem(0,i)
  end

  local new_items_list = {}
  local new_tracks_list = {}
  local pevious_track = ""
  local track_max_chan = 1

  -- Set parnames we want copy/past in new tracks
  local track_parnames = {
    "B_MUTE",
    "B_PHASE",
    "B_RECMON_IN_EFFECT",
    "I_SOLO",
    "I_FXEN",
    "I_RECARM",
    "I_RECINPUT",
    "I_RECMODE",
    "I_RECMON",
    "I_RECMONITEMS",
    "I_AUTOMODE",
    "I_FOLDERCOMPACT",
    "I_PERFFLAGS",
    "I_CUSTOMCOLOR",
    "I_HEIGHTOVERRIDE",
    "B_HEIGHTLOCK",
    "D_VOL",
    "D_PAN",
    "D_WIDTH",
    "D_DUALPANL",
    "D_DUALPANR",
    "I_PANMODE",
    "D_PANLAW",
    "B_SHOWINMIXER",
    "B_SHOWINTCP",
    "B_MAINSEND",
    "C_MAINSEND_OFFS",
    "C_BEATATTACHMODE",
    "F_MCP_FXSEND_SCALE",
    "F_MCP_FXPARM_SCALE",
    "F_MCP_SENDRGN_SCALE",
    "F_TCP_FXPARM_SCALE",
    "I_PLAY_OFFSET_FLAG",
    "D_PLAY_OFFSET"}

  for i, item in ipairs(item_list) do
    local take = reaper.GetActiveTake(item)
    if take then
      local source = reaper.GetMediaItemTake_Source(take)
      if reaper.GetMediaSourceSampleRate(source) > 0 then
        -- Get some track/item/take/source infos
        local track = reaper.GetMediaItem_Track(item)
        local track_id =  reaper.GetMediaTrackInfo_Value(track,"IP_TRACKNUMBER")
        local take = reaper.GetActiveTake(item)
        local take_name = reaper.GetTakeName(take)
        local take_chanmode = reaper.GetMediaItemTakeInfo_Value(take,"I_CHANMODE")
        local source_chan = reaper.GetMediaSourceNumChannels(source)
        local position = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
        local playrate = reaper.GetMediaItemInfo_Value(item,"D_PLAYRATE")

        -- Find the real chan num of take
        if source_chan > 1 and take_chanmode < 2 then
          take_chan = source_chan
        elseif source_chan > 1 and take_chanmode > 66 then
          take_chan = 2
        else
          take_chan = 1
        end

        if take_chan > 1 then

          -- Create new tracks if necessary
          if track == previous_track then
            if track_max_chan < take_chan then
              for j=0, take_chan - track_max_chan - 1 do
                reaper.InsertTrackAtIndex(track_id+track_max_chan+j,true)
                local _,track_name =  reaper.GetSetMediaTrackInfo_String(track,"P_NAME","",false)
                local new_track = reaper.GetTrack(0,track_id+track_max_chan+j)
                table.insert(new_tracks_list,new_track)
                reaper.GetSetMediaTrackInfo_String(new_track,"P_NAME",track_name.." - "..(j+track_max_chan+1),true)
                for p, parname in ipairs(track_parnames) do
                  reaper.SetMediaTrackInfo_Value(new_track,parname,reaper.GetMediaTrackInfo_Value(track,parname))
                end
              end
              track_max_chan = take_chan
            end
          else
            track_max_chan = take_chan
            for j=0, take_chan - 1 do
              reaper.InsertTrackAtIndex(track_id+j,true)
              local _,track_name =  reaper.GetSetMediaTrackInfo_String(track,"P_NAME","",false)
              new_track = reaper.GetTrack(0,track_id+j)
              table.insert(new_tracks_list,new_track)
              reaper.GetSetMediaTrackInfo_String(new_track,"P_NAME",track_name.." - "..(j+1),true)
              for p, parname in ipairs(track_parnames) do
                reaper.SetMediaTrackInfo_Value(new_track,parname,reaper.GetMediaTrackInfo_Value(track,parname))
              end
            end
          end
          previous_track = track
          track_id =  reaper.GetMediaTrackInfo_Value(track,"IP_TRACKNUMBER")

          reaper.Main_OnCommand(40769,0)-- Unselect all
          reaper.SetMediaItemSelected(item,true)-- Select item
          reaper.Main_OnCommand(40698,0)-- Copy item
          --reaper.Main_OnCommand(41173,0)-- Move cursor
          reaper.SetEditCurPos(position,false,false)
          reaper.SetOnlyTrackSelected(track)-- Select one track

          for i=0, take_chan-1 do
            reaper.Main_OnCommand(40285,0)-- Go to next track
            reaper.SetEditCurPos(position,false,false)
            reaper.Main_OnCommand(42398,0)-- Past item

            -- Set take name
            local new_item = reaper.GetSelectedMediaItem(0,0)
            reaper.SetMediaItemInfo_Value(new_item,"D_POSITION",position)
            reaper.SetMediaItemInfo_Value(new_item,"D_LENGTH",length)
            reaper.SetMediaItemInfo_Value(new_item,"D_PLAYRATE",playrate)
            table.insert(new_items_list,new_item)
            local new_take = reaper.GetActiveTake(new_item)
            reaper.GetSetMediaItemTakeInfo_String(new_take,"P_NAME",take_name.." - "..i+1,true)

            -- Change new take chanmode to mono (depend of parent take chanmode)
            if take_chanmode == 0 then
              reaper.SetMediaItemTakeInfo_Value(new_take,"I_CHANMODE",i+3)
            elseif take_chanmode == 1 then
              if i == 0 then
                reaper.SetMediaItemTakeInfo_Value(new_take,"I_CHANMODE",4)
              elseif i == 1 then
                reaper.SetMediaItemTakeInfo_Value(new_take,"I_CHANMODE",3)
              else
                reaper.SetMediaItemTakeInfo_Value(new_take,"I_CHANMODE",i+3)
              end
            elseif take_chanmode > 66 then
              reaper.SetMediaItemTakeInfo_Value(new_take,"I_CHANMODE",(take_chanmode-67)+i+3)
            end
          end
        end
      end
    end
  end

  -- Select only new items
  reaper.SelectAllMediaItems(0,0)
  for i, item in ipairs(new_items_list) do
    reaper.SetMediaItemSelected(item,true)
  end

  -- Select only new tracks
  for i, track in ipairs(new_tracks_list) do
    if i == 1 then
      reaper.SetOnlyTrackSelected(track)
    end
    reaper.SetTrackSelected(track,true)
  end

  reaper.Undo_EndBlock("Explode multichannel items to mono items in new tracks (without render)",0)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

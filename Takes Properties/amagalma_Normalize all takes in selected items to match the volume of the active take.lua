-- @description Normalize all takes in selected items to match the volume of the active take
-- @author amagalma
-- @version 1.02
-- @changelog - Improved working with many items
--   - Track volume and TrackFX are not taken into account
-- @donation https://www.paypal.me/amagalma
-- @about Useful for bringing the rest of the takes to the same volume as the current take, when comping

local start = reaper.time_precise()
local initial_item_cnt = reaper.CountSelectedMediaItems( 0 )
if initial_item_cnt == 0 then return end
local initially_selected_items, init_cnt = {}, 0
local items, cnt = {}, 0
local tracks = {}
local total_take_cnt = 0
local ini = reaper.get_ini_file()
local ok1, itemnormtgt2_old = reaper.BR_Win32_GetPrivateProfileString( "REAPER", "itemnormtgt2", "", ini )
local ok2, itemnormmode_old = reaper.BR_Win32_GetPrivateProfileString( "REAPER", "itemnormmode", "", ini )

if not ok1 or not ok2 then
  reaper.MB("Could not get 'itemnormtgt2' and/or 'itemnormmode' values from reaper.ini!", "Aborting", 0)
  return
end

local function SetLUFSI( val )
  reaper.BR_Win32_WritePrivateProfileString( "REAPER", "itemnormtgt2", tostring(val), ini )
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock2(0)

for i = 0, initial_item_cnt-1 do
  local item = reaper.GetSelectedMediaItem( 0, i )
  init_cnt = init_cnt + 1
  initially_selected_items[init_cnt] = item
  local take_cnt = reaper.CountTakes( item )
  local take = reaper.GetActiveTake( item )
  if take_cnt > 1 and take and not reaper.TakeIsMIDI( take ) then
    local ok, guid = reaper.GetSetMediaItemInfo_String( item, "GUID", "", false )
    if ok then
      cnt = cnt + 1
      local name = reaper.GetTakeName( take )
      tracks[reaper.GetMediaItemTrack(item)] = true
      items[guid] = {ptr = item, val = false, acttake = take, take_cnt = take_cnt, take_name = name }
      total_take_cnt = total_take_cnt + take_cnt - 1
    end
  end
end

if cnt > 0 then

  reaper.SelectAllMediaItems( 0, false )
  for guid, info in pairs(items) do
    reaper.SetMediaItemSelected( info.ptr, true )
    reaper.GetSetMediaItemTakeInfo_String( info.acttake, "P_NAME", guid, true )
  end
  
  for track in pairs(tracks) do
    local fxen = reaper.GetMediaTrackInfo_Value( track, "I_FXEN" ) == 1
    local vol = reaper.GetMediaTrackInfo_Value( track, "D_VOL" )
    tracks[track] = { fxen = fxen, vol = vol }
    reaper.SetMediaTrackInfo_Value( track, "D_VOL", 1 )
    if fxen then
      reaper.SetMediaTrackInfo_Value( track, "I_FXEN", 0 )
    end
  end

  -- Calculate loudness of selected items, including take and track FX and settings, via dry run render
  local ok, stats = reaper.GetSetProjectInfo_String(0, "RENDER_STATS_SUMMARY", "42437", false)
  if stats == "" then
    ok = false
      reaper.MB("RENDER_STATS_SUMMARY is empty!", "Aborting", 0)
  end

  if ok then
    local i = 0
    for entry in stats:gmatch("[^\n\r]+") do
      i = i + 1
      local guid, lufsi = entry:match("(%b{}).-LUFS%-I: (.+)")
      items[guid].val = lufsi
    end
    if i ~= cnt then
      reaper.MB("There was a mismatch between the number of items and the calculated LUFSI values!", "Aborting", 0)
    else
      reaper.BR_Win32_WritePrivateProfileString( "REAPER", "itemnormmode", "16", ini )
      reaper.SelectAllMediaItems( 0, false )
      for guid, info in pairs(items) do
        reaper.SetMediaItemSelected( info.ptr , true )
        for tk = 0, info.take_cnt-1 do
          local take = reaper.GetTake( info.ptr, tk )
          if take ~= info.acttake and info.val then
            reaper.SetActiveTake( take )
            SetLUFSI( info.val )
            reaper.Main_OnCommand(42461, 0) -- Normalize items using most recent settings
          end
        end
        reaper.SetActiveTake( info.acttake )
        reaper.SetMediaItemSelected( info.ptr, false )
      end
      reaper.BR_Win32_WritePrivateProfileString( "REAPER", "itemnormmode", itemnormmode_old, ini )
      SetLUFSI( itemnormtgt2_old )
      job_done = true
    end
  end
  
  for _, info in pairs(items) do
    reaper.GetSetMediaItemTakeInfo_String( info.acttake, "P_NAME", info.take_name, true )
  end

  reaper.SelectAllMediaItems( 0, false )
  for i = 1, init_cnt do
    reaper.SetMediaItemSelected( initially_selected_items[i], true )
  end

  for track, info in pairs(tracks) do
    reaper.SetMediaTrackInfo_Value( track, "D_VOL", info.vol )
    if fxen then
      reaper.SetMediaTrackInfo_Value( track, "I_FXEN", 1 )
    end
  end

end

local process_time = math.floor((reaper.time_precise() - start)*10 + 0.5) / 10

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2( 0, "Normalize all takes to match active take volume", 4 )

if job_done and process_time > 5 then
  reaper.MB( string.format("Normalized %i takes in %.1f seconds.",total_take_cnt,process_time), "Info", 0 )
end

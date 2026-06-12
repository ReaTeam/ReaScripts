-- @description Normalize all takes in selected items to match the volume of the active take
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about Useful for bringing the rest of the takes to the same volume as the current take, when comping

local start = reaper.time_precise()
local initial_item_cnt = reaper.CountSelectedMediaItems( 0 )
if initial_item_cnt == 0 then return end
local initially_selected_items, init_cnt = {}, 0
local items, cnt = {}, 0
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
    cnt = cnt + 1
    items[cnt] = {ptr = item, val = false, acttake = take, take_cnt = take_cnt }
    total_take_cnt = total_take_cnt + take_cnt - 1
  end
end

if cnt > 0 then

  reaper.SelectAllMediaItems( 0, false )
  for i = 1, cnt do
    reaper.SetMediaItemSelected( items[i].ptr, true )
  end

  -- Calculate loudness of selected items, including take and track FX and settings, via dry run render
  local ok, stats = reaper.GetSetProjectInfo_String(0, "RENDER_STATS_SUMMARY", "42437", false)

  if ok then
    local i = 0
    for entry in stats:gmatch("[^\n\r]+") do
      i = i + 1
      items[i].val = entry:match("LUFS%-I: (.+)")
    end
    if i ~= cnt then
      reaper.MB("There was a mismatch between the number of items and the calculated LUFSI values!", "Aborting", 0)
    else
      reaper.BR_Win32_WritePrivateProfileString( "REAPER", "itemnormmode", "16", ini )
      reaper.SelectAllMediaItems( 0, false )
      for i = 1, cnt do
        local item = items[i].ptr
        local acttake = items[i].acttake
        local wanted_lufsi = items[i].val
        local take_cnt = items[i].take_cnt
        reaper.SetMediaItemSelected( item , true )
        for tk = 0, take_cnt-1 do
          local take = reaper.GetTake( item, tk )
          if take ~= acttake and wanted_lufsi then
            reaper.SetActiveTake( take )
            SetLUFSI( wanted_lufsi )
            reaper.Main_OnCommand(42461, 0) -- Normalize items using most recent settings
          end
        end
        reaper.SetActiveTake( acttake )
        reaper.SetMediaItemSelected( item, false )
      end
      reaper.BR_Win32_WritePrivateProfileString( "REAPER", "itemnormmode", itemnormmode_old, ini )
      SetLUFSI( itemnormtgt2_old )
    end
  end

  reaper.SelectAllMediaItems( 0, false )
  for i = 1, init_cnt do
    reaper.SetMediaItemSelected( initially_selected_items[i], true )
  end

end

local process_time = math.floor((reaper.time_precise() - start)*10 + 0.5) / 10

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2( 0, "Normalize all takes to match active take volume", 4 )

if process_time > 5 then
  reaper.MB( string.format("Normalized %i takes in %.1f seconds.",total_take_cnt,process_time), "Info", 0 )
end

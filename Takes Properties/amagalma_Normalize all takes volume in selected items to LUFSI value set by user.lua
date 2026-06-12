-- @description Normalize all takes volume in selected items to LUFSI value set by user
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma

local ok, lufsi = reaper.GetUserInputs("Normalize all takes to LUFS-I", 1, "LUFS-I value (must be negative) :", "-25")
if not ok or not tonumber(lufsi) or tonumber(lufsi) >=0 then return end
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

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock2(0)

for i = 0, initial_item_cnt-1 do
  local item = reaper.GetSelectedMediaItem( 0, i )
  init_cnt = init_cnt + 1
  initially_selected_items[init_cnt] = item
  local take_cnt = reaper.CountTakes( item )
  local take = reaper.GetActiveTake( item )
  if take_cnt > 0 and take and not reaper.TakeIsMIDI( take ) then
    cnt = cnt + 1
    items[cnt] = {ptr = item, take_cnt = take_cnt, acttake = take }
    total_take_cnt = total_take_cnt + take_cnt
  end
end

if cnt > 0 then

  reaper.BR_Win32_WritePrivateProfileString( "REAPER", "itemnormtgt2", lufsi, ini )
  reaper.BR_Win32_WritePrivateProfileString( "REAPER", "itemnormmode", "16", ini )

  reaper.SelectAllMediaItems( 0, false )
  for i = 1, cnt do
    local item = items[i].ptr
    reaper.SetMediaItemSelected( item , true )
    for tk = 0, items[i].take_cnt-1 do
      local take = reaper.GetTake( item, tk )
      reaper.SetActiveTake( take )
      reaper.Main_OnCommand(42461, 0) -- Normalize items using most recent settings
    end
    reaper.SetActiveTake( items[i].acttake )
    reaper.SetMediaItemSelected( item, false )
  end
  reaper.BR_Win32_WritePrivateProfileString( "REAPER", "itemnormmode", itemnormmode_old, ini )
  reaper.BR_Win32_WritePrivateProfileString( "REAPER", "itemnormmode", itemnormtgt2_old, ini )

  reaper.SelectAllMediaItems( 0, false )
  for i = 1, init_cnt do
    reaper.SetMediaItemSelected( initially_selected_items[i], true )
  end

end

local process_time = math.floor((reaper.time_precise() - start)*10 + 0.5) / 10

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2( 0, "Normalize all takes to " .. lufsi .. " dB", 4 )

if process_time > 5 then
  reaper.MB( string.format("Normalized %i takes in %.1f seconds.",total_take_cnt,process_time), "Info", 0 )
end

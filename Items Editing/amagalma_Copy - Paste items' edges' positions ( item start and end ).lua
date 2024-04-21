-- @description Copy - Paste items' edges' positions ( item start and end )
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma


local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt == 0 then
  reaper.MB("Please, select some items and and retry.", "No selected items!", 0)
  return reaper.defer(function() end)
end


local js_api = reaper.APIExists( "JS_Window_Find" )
local title = js_api and "hidden " .. reaper.genGuid() or ""
gfx.init( title, 0, 0, 0, 0, 0 )
if js_api then
  local hwnd = reaper.JS_Window_Find( title, true )
  if hwnd then
    reaper.JS_Window_Show( hwnd, "HIDE" )
  end
end
gfx.x, gfx.y = gfx.mouse_x-52, gfx.mouse_y-70
local selection = gfx.showmenu("amagalma Copy/Paste items' edges' positions||Copy|Paste")
gfx.quit()


if selection == 2 then -- Copy

  local info, j = {}, 0

  for i = 0, item_cnt-1 do
    local item = reaper.GetSelectedMediaItem( 0, i )
    j = j + 1
    info[j] = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    j = j + 1
    info[j] = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
  end

  reaper.SetExtState( "amagalma_copypaste_itemedges", "data", table.concat(info, " "), false )
  reaper.MB("Copied the edge positions of " .. math.tointeger(j/2) .. " items.", "Copy", 0)

elseif selection == 3 then -- Paste

  if not reaper.HasExtState( "amagalma_copypaste_itemedges", "data" ) then
    reaper.MB("No item edges data in memory. Please, copy some first and retry!", "No data!", 0)
    return reaper.defer(function() end)
  end

  local data = reaper.GetExtState( "amagalma_copypaste_itemedges", "data" )
  local info, j = {}, 0

  for position in data:gmatch("%S+") do
    j = j + 1
    info[j] = tonumber(position)
  end

  local total = item_cnt < j/2 and item_cnt or j/2

  reaper.PreventUIRefresh( 1 )

  for i = 0, total-1 do
    local item = reaper.GetSelectedMediaItem( 0, i )
    reaper.SetMediaItemInfo_Value( item, "D_POSITION", info[i*2+1] )
    reaper.SetMediaItemInfo_Value( item, "D_LENGTH", info[i*2+2] )
  end

  reaper.PreventUIRefresh( -1 )
  reaper.Undo_OnStateChangeEx( "Change edge positions of selected items", 4, -1)
  reaper.MB("Modified the edges' positions of " .. math.tointeger(total) .. " items.", "Paste", 0)

else

  return reaper.defer(function() end)

end

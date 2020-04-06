-- @description Toggle show editing guide line on item under mouse cursor
-- @author amagalma
-- @version 1.01
-- @about
--   # Displays a guide line on the item under the mouse cursor for easier editing
--   - Nice for a toolbar action
--   - When prompted by Reaper, choose to "Terminate instance" and to remember your choice
--   - Requires JS_ReaScriptAPI
-- @changelog - Fixed lines sometimes staying behind when changing item

-------------------------------------------------------------------

-- Check if JS_ReaScriptAPI is installed
if not reaper.APIExists("JS_Window_FindChildByID") then
  local answer = reaper.MB( "You have to install JS_ReaScriptAPI for this script to work. Would you like to open the relative web page in your browser?", "JS_ReaScriptAPI not installed", 4 )
  if answer == 6 then
    local url = "https://forum.cockos.com/showthread.php?t=212174"
     reaper.CF_ShellExecute( url )
  end
  return
end

local reaper = reaper
local trackview = reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 1000)
local height, prev_x, prev_top_y, prev_bottom_y, x, y = 0
local pen = reaper.JS_GDI_CreatePen( 1, 16777215 )
-- Refresh toolbar
local _, _, section, cmdID = reaper.get_action_context()
reaper.SetToggleCommandState( section, cmdID, 1 )
reaper.RefreshToolbar2( section, cmdID )

function Exit()
  reaper.JS_GDI_DeleteObject( pen )
  reaper.UpdateArrange()
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
end

function main()
  x, y = reaper.GetMousePosition() -- screen 
  local item = reaper.GetItemFromPoint( x, y, true )
  if item then
    y = reaper.GetMediaTrackInfo_Value( reaper.GetMediaItem_Track( item ), "I_TCPY" ) + 
              reaper.GetMediaItemInfo_Value( item, "I_LASTY" ) -- client
    height = reaper.GetMediaItemInfo_Value( item, "I_LASTH" )
    x = reaper.JS_Window_ScreenToClient( trackview, x, 0 )
    local hdc = reaper.JS_GDI_GetClientDC( trackview )
    reaper.JS_GDI_SelectObject( hdc, pen ) 
    reaper.JS_GDI_Line( hdc, x, y + 1, x, y + height - 2 )
    reaper.JS_GDI_ReleaseDC( trackview, hdc )
  end
  if prev_x and (prev_x ~= x or prev_top_y ~= y + 1) then
    reaper.JS_Window_InvalidateRect(trackview, prev_x, prev_top_y, prev_x + 1, prev_bottom_y, true)
  end
  prev_x, prev_top_y, prev_bottom_y = x, y + 1, y + height - 2
  reaper.defer(main)
end

reaper.atexit(Exit) 
main()

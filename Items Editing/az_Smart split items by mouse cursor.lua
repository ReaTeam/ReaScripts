-- @description Smart split items by mouse cursor
-- @author AZ
-- @version 1.0
-- @about
--   Split items respect grouping, depend on context of mouse cursor, split at time selection if exist, split at mouse or edit cursor otherwise.
--
--   Date: october 2021


--FUNCTIONS--


function is_item_crossTS ()
if itemend < start_pos or itempos > end_pos then
crossTS=0
else
  if itemend == start_pos or itempos == end_pos then
  crossTS=0
  else
    if itempos > start_pos and itemend < end_pos then  --inside TS
    crossTS=0
    else
      if itempos == start_pos and itemend == end_pos then  --inside TS
      crossTS=0
      else
        if itempos == start_pos and itemend < end_pos then  --inside TS
        crossTS=0
        else
          if itempos > start_pos and itemend == end_pos then  --inside TS
          crossTS=0
          else
          crossTS=1
          end
        end
      end
    end
  end
end
end

            
-----------------------------------------
--------------------------------------------


function split_by_edit_cursor_or_TS()
if TSexist==0 then  --if TS doesn't exist
 reaper.Main_OnCommandEx( 40759, 0, 0 ) -- split items under edit cursor (select right)
else

  if itemsNUMB == -1 then --if no one item selected
   reaper.Main_OnCommandEx(  40061, 0, 0 ) -- split at TS
  else
       --if any items selected it need to check croses with TS
    if item then  
     --item under mouse sec position to decide where is item crossed by TS--
    itempos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    itemlen = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" ) 
    itemend = itempos + itemlen
    is_item_crossTS()
    else
    
    item_not_undermouse = reaper.GetSelectedMediaItem( 0, itemsNUMB ) --zero based -- last sel item
    --item sec position to decide where is last sel item crossed by TS--
    itempos = reaper.GetMediaItemInfo_Value( item_not_undermouse, "D_POSITION" )
    itemlen = reaper.GetMediaItemInfo_Value( item_not_undermouse, "D_LENGTH" ) 
    itemend = itempos + itemlen
    
    crossTS = 0 -- need to start while cycle

      while itemsNUMB > -1 and crossTS == 0 do
      is_item_crossTS()
      itemsNUMB = itemsNUMB-1
      item_not_undermouse = reaper.GetSelectedMediaItem( 0, itemsNUMB ) --zero based
      
        if item_not_undermouse then --to avoid error if no more items founded
        --item sec position to decide where is another item regards TS--
        itempos = reaper.GetMediaItemInfo_Value( item_not_undermouse, "D_POSITION" )
        itemlen = reaper.GetMediaItemInfo_Value( item_not_undermouse, "D_LENGTH" ) 
        itemend = itempos + itemlen
        end
      end
    end  
  
    if crossTS==0 then
      reaper.Main_OnCommandEx( 40759, 0, 0 ) -- split items under edit cursor (select right)
    else
     reaper.Undo_BeginBlock2( 0 )
     reaper.PreventUIRefresh( 1 )
     reaper.Main_OnCommandEx(  40061, 0, 0 ) -- split at TS
     reaper.Main_OnCommandEx( 40635, 0, 0 )  -- Time selection: Remove time selection
     reaper.PreventUIRefresh( -1 )
     reaper.Undo_EndBlock2( 0, "Split items at time selection", -1 )
    end 
  end
end
end


-----------------------------------------
--------------------------------------------


function split_not_sel_item()

reaper.Main_OnCommandEx( 40289, 0, 0 ) -- unselect all items
reaper.SetMediaItemSelected( item, 1 ) -- select founded item under mouse
reaper.Main_OnCommandEx( 40513, 0, 0 ) -- View: Move edit cursor to mouse cursor

reaper.Main_OnCommandEx(  40759, 0, 0 ) -- CENTRAL FUNCTION split items under edit cursor (select right)

reaper.SetEditCurPos(cur_pos, false, false)

end



-----------------------------------------
--------------------------------------------



function split_sel_item()

reaper.Main_OnCommandEx( 40513, 0, 0 ) -- View: Move edit cursor to mouse cursor
split_by_edit_cursor_or_TS() --CENTRAL FUNCTION
reaper.SetEditCurPos(cur_pos, false, false)

end



-----------------------------------------
--------------------------------------------


function split_automation_item()

reaper.Main_OnCommandEx( 40513, 0, 0 ) -- View: Move edit cursor to mouse cursor
reaper.Main_OnCommandEx( 42087, 0, 0 ) -- Envelope: Split automation items
reaper.SetEditCurPos(cur_pos, false, false)

Env_line =  reaper.GetSelectedEnvelope( 0 )
  if Env_line then
    AI_number = reaper.CountAutomationItems( Env_line ) -1

    while AI_number > -1 do
    reaper.GetSetAutomationItemInfo( Env_line, AI_number, "D_UISEL", 0, true )
    AI_number = AI_number - 1
    end
  end

end



-----------------------------------------
--------------------------------------------



--CONTEXT DEFINING CODE--

x, y = reaper.GetMousePosition()
item = reaper.GetItemFromPoint( x, y, false ) --what is context item or not
itemsNUMB =  reaper.CountSelectedMediaItems( 0 ) -1 -- -1 to accordance Get Sel Item
start_pos, end_pos = reaper.GetSet_LoopTimeRange2( 0, false, false, 0, 0, 0 )

if start_pos==0 and end_pos==0 then TSexist=0
else
TSexist=1
end

cur_pos=reaper.GetCursorPosition()

window, segment, details = reaper.BR_GetMouseCursorContext()
--mouse_pos = reaper.BR_GetMouseCursorContext_Position()

--[[
if window == "arrange" and segment == "envelope" then
reaper.SetCursorContext( 2, 0 )
context = reaper.GetCursorContext2( false )  --what is context global
--reaper.ShowConsoleMsg( tostring(context) )
end


context = reaper.GetCursorContext2( false )  --what is context global
]]

--if context == 2 then
if window == "arrange" and segment == "envelope" then
reaper.Undo_BeginBlock2( 0 )
reaper.PreventUIRefresh( 1 )
split_automation_item()
reaper.PreventUIRefresh( -1 )
reaper.Undo_EndBlock2( 0, "Split automation item by mouse", -1 )
else
  
  if not item then  --if mouse cursor not on the item
  split_by_edit_cursor_or_TS()
  end
  
  if item then
  
    selstate = reaper.IsMediaItemSelected( item )
    
    if selstate==false then
    reaper.Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    split_not_sel_item()
    reaper.PreventUIRefresh( -1 )
    reaper.Undo_EndBlock2( 0, "Split items under mouse", -1 )
    else
    reaper.Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    split_sel_item()
    reaper.PreventUIRefresh( -1 )
    reaper.Undo_EndBlock2( 0, "Split items under mouse or time selection", -1 )
    end
     
  end
  
end

-- @description amagalma_Implode enclosed items as takes of longer items on the same track
-- @author amagalma
-- @version 1.1
-- @about
--   # Implodes enclosed items as takes of longer or equal length items, preserving item size and item/take colors
--   - Can be used with as many tracks and items as you like
--   - You can set in the script if you want newly created items to be selected after operation finishes
--   - Works with items with more than one takes too

--[[
 * Changelog:
 * v1.1 (2017-09-17)
  + action now works with items with more than one takes too
--]]

-----------------------------------------------------------------------------------

local reaper = reaper
local Selected_items = {}
local newitems = {}

-----------------------------------------------------------------------------------


----------------------------  USER SETTINGS  ----------------------------------------
                                                                                   --
local selnew = 1 -- enter 1 to select newly created items after operation finishes --
                                                                                   --
-------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------

function Store_Properties()
  local sel_item_cnt = reaper.CountSelectedMediaItems( 0 )
  if sel_item_cnt > 0 then
    -- Store selected items
    for i = 0, sel_item_cnt-1 do
      local selitem = reaper.GetSelectedMediaItem( 0, i )
      Selected_items[i+1] = selitem
    end
    local Track = {}
    local track_cnt = reaper.CountTracks( 0 )
    -- iterate project tracks
    for i = 0, track_cnt-1 do
      local track =  reaper.GetTrack( 0, i)
      local item_cnt = reaper.CountTrackMediaItems( track )
      local store = false
      local Item = {}
      -- get track's items' properties
      if item_cnt > 0 then
        for j = 0, item_cnt-1 do
          local item = reaper.GetTrackMediaItem( track, j)
          if reaper.IsMediaItemSelected( item ) then
            local Start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
            local End = Start + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
            local takes = reaper.CountTakes( item )
            Item[#Item+1] = {Item = item, Start = Start, End = End, Takes = takes}
            store = true
          end
        end
      end
      -- Store a Track only if it has selected items in it
      if store then Track[#Track+1] = {track = track, item = Item} end
    end
    return Track
  end
end

-----------------------------------------------------------------------------------

local Tr = Store_Properties()
if Tr and #Selected_items > 1 then
  reaper.PreventUIRefresh( 1 )
  reaper.Undo_BeginBlock()
  -- Unselect all items - Needed in order to use "implode items" Main Command
  for i = 1, #Selected_items do
    reaper.SetMediaItemSelected( Selected_items[i], false )
  end
  for tr = 1, #Tr do
    for it = 2, #Tr[tr].item do
      local Colors = {}
      local item = Tr[tr].item[it].Item -- enclosed item
      local shortstart = Tr[tr].item[it].Start
      local shortend = Tr[tr].item[it].End
      local shorttakes = Tr[tr].item[it].Takes
      for tk = 0, shorttakes-1 do
        local source = reaper.GetMediaItemTake_Source(reaper.GetMediaItemTake( item, tk ))
        local color
        -- store take colors relative to their source
        if shorttakes < 2 then
          color = reaper.GetDisplayedMediaItemColor( item )
        else
          color = reaper.GetMediaItemTakeInfo_Value(reaper.GetMediaItemTake(item, tk), "I_CUSTOMCOLOR")
        end
        Colors[#Colors+1] = {Source = source, Color = color}
      end
      local longest, longstart, longend, longtakes
      local found = false
      -- find enclosing item
      for lg = 1, #Tr[tr].item-1 do
        longest = Tr[tr].item[lg].Item
        if longest ~= item then -- do not compare item to itself
          longstart = Tr[tr].item[lg].Start
          longend = Tr[tr].item[lg].End
          longtakes = Tr[tr].item[lg].Takes
          if shortstart >= longstart and shortend <= longend then
            found = true
            -- store take colors relative to their source (add to Colors table)
            for tk = 0, longtakes-1 do
              local source = reaper.GetMediaItemTake_Source(reaper.GetMediaItemTake( longest, tk ))
              local color
              if longtakes < 2 then
                color = reaper.GetDisplayedMediaItemColor( item )
              else
                color = reaper.GetMediaItemTakeInfo_Value(reaper.GetMediaItemTake(longest, tk), "I_CUSTOMCOLOR")
              end
              Colors[#Colors+1] = {Source = source, Color = color}
            end
            break
          elseif longstart > shortstart then
            break -- item is after "enclosed item", so it cannot be an enclosing one!
          end
        end
      end
      if found then -- there is an enclosing item
        if shortstart ~= longstart then
          longest = reaper.SplitMediaItem( longest, shortstart )
        end
        if shortend ~= longend then
          reaper.SplitMediaItem( longest, shortend )
        end
        reaper.SetMediaItemSelected(item, true )
        local itemsource = reaper.GetMediaItemTake_Source(reaper.GetActiveTake( item ))
        local longestsource = reaper.GetMediaItemTake_Source(reaper.GetActiveTake( longest ))
        reaper.SetMediaItemSelected(longest, true )
        reaper.Main_OnCommand(40543,0) -- Take: Implode items on same track into takes
        local newitem = reaper.GetSelectedMediaItem( 0, 0 )
        if reaper.GetMediaItemTake_Source(reaper.GetMediaItemTake( newitem, 0 )) ~= longestsource then
          reaper.Main_OnCommand(41354,0) -- Item: Rotate take lanes backward
        end
        local take_cnt = reaper.CountTakes( newitem )
        -- color the takes according to their source (connection stores in Colors table)
        for tk = 0, take_cnt-1 do
          local source = reaper.GetMediaItemTake_Source(reaper.GetMediaItemTake(newitem,tk ))
          for cl = 1, #Colors do
            if Colors[cl].Source == source then
              reaper.SetMediaItemTakeInfo_Value(reaper.GetMediaItemTake(newitem,tk), "I_CUSTOMCOLOR", Colors[cl].Color)
            end
          end
        end
        reaper.SetActiveTake(reaper.GetMediaItemTake( newitem, take_cnt-1 ))
        reaper.SetMediaItemSelected(newitem, false )
        newitems[#newitems+1] = newitem
      end
    end
  end
  if selnew == 1 then
    -- Select new created items
    for i = 1, #newitems do
      reaper.SetMediaItemSelected( newitems[i], true )
    end
  end
  reaper.Undo_EndBlock( "Implode items on same track into takes (embed shorter into longer)", 4 )
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
end

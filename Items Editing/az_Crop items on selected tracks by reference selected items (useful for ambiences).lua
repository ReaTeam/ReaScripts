-- @description Crop items on selected tracks by reference selected items (useful for ambiences)
-- @author AZ
-- @version 1.0
-- @link Forum thread https://forum.cockos.com/showthread.php?t=288069
-- @donation Donate via PayPal https://www.paypal.me/AZsound
-- @about
--   #Crop items on selected tracks by reference selected items
--
--   This script is dedicated for editing ambiences for a movie.
--   It's convenient to use scene cut  (or picture cut) track with empty items and to crop all placed ambience batches in one click.
--
--   Crossfades will be created looking for reference items overlapping.


--FUNCTIONS--

function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end

---------------
function MessageNoTrSel()
  local title = 'Crop items on sel tracks by reference items'
  local text = 'There is no track to perform. Select target tracks.'
  reaper.ShowMessageBox(text, title, 0) 
end

---------------
function MessageOneTrSel()
  local title = 'Crop items on sel tracks by reference items'
  local text = 'There is only one track selected.'..'\n'
  ..'Select reference items on another track or select other target tracks.'
  reaper.ShowMessageBox(text, title, 0) 
end

---------------
function MessageNoRefItems()
  local title = 'Crop items on sel tracks by reference items'
  local text = 'There are no reference items selected'..'\n'
  ..'or there are no items on 1st selected track.'
  reaper.ShowMessageBox(text, title, 0) 
end

---------------
function CollectRefItems()

  if Ref1stTrack == true then
  
    local track = reaper.GetSelectedTrack(0,0)
    local iNumb = reaper.CountTrackMediaItems(track)
    
    if iNumb > 0 then
      for i = 1, iNumb do
        local item = reaper.GetTrackMediaItem(track, i-1)
        table.insert(RefItems, item)
      end
    end
    
  else
  
    if SelItNumb > 0 then
      for i = 1, SelItNumb do
        local item = reaper.GetSelectedMediaItem(0, i-1)
        local iTrack = reaper.GetMediaItem_Track(item)
        if reaper.IsTrackSelected(iTrack) ~= true then
          table.insert(RefItems, item)
        end
      end --for
    end
    
  end --else
  
end

---------------

function GetItemGroupsByOverlap()
  local ItemGroups = {}

  if Ref1stTrack == true then lowidx = 2 else lowidx = 1 end

  for t = lowidx, SelTrNumb do
    local track = reaper.GetSelectedTrack2(0, t-1, false)
    local itemCount = reaper.CountTrackMediaItems(track)

    if itemCount > 0 then
      local items = {}
      for i = 0, itemCount - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local endPos = pos + len
        table.insert(items, { item=item, pos=pos, ["end"]=endPos })
      end

      -- Sort by start position
      table.sort(items, function(a,b) return a.pos < b.pos end)

      local trackGroups = {}
      local currentGroup = { items[1] }
      local groupEnd = items[1]["end"]  -- track current group's end

      for i = 2, #items do
        local curr = items[i]
        if curr.pos <= groupEnd then
          table.insert(currentGroup, curr)
          -- expand group end if needed
          if curr["end"] > groupEnd then
            groupEnd = curr["end"]
          end
        else
          table.insert(trackGroups, currentGroup)
          currentGroup = { curr }
          groupEnd = curr["end"]
        end
      end
      table.insert(trackGroups, currentGroup)

      ItemGroups[t+1] = trackGroups
    end
  end

  return ItemGroups
end

---------------------

function AssignRegionsToItemGroups(Regions, ItemGroups)
  -- Iterate over all tracks
  for tIndex, trackGroups in pairs(ItemGroups) do
    -- Iterate over all groups within the track
    for gIndex, group in ipairs(trackGroups) do
      
      -- Calculate group's overall start and end positions
      local groupStart = math.huge
      local groupEnd = -math.huge
      for _, itemData in ipairs(group) do
        if itemData.pos <= groupStart then groupStart = itemData.pos end
        if itemData["end"] >= groupEnd then groupEnd = itemData["end"] end
      end

      local bestRegionID = nil
      local bestOverlap = 0

      -- Find region with the largest overlap
      for regionID, reg in pairs(Regions) do
        local regStart = reg.regStart
        local regEnd = reg.regEnd

        -- Calculate overlap
        local overlapStart = math.max(groupStart, regStart)
        local overlapEnd = math.min(groupEnd, regEnd)
        local overlap = overlapEnd - overlapStart

        if overlap > bestOverlap then
          bestOverlap = overlap
          bestRegionID = regionID
        end
      end

      -- Assign region data if overlap exists
      if bestRegionID and bestOverlap > 0 then
        local reg = Regions[bestRegionID]
        group.regStart = reg.regStart
        group.regEnd = reg.regEnd
        group.fIn = reg.fIn
        group.fOut = reg.fOut
        group.regionID = bestRegionID
      else
        group.regStart = nil
        group.regEnd = nil
        group.fIn = nil
        group.fOut = nil
        group.regionID = nil
      end
    end
  end

  return ItemGroups
end

---------------
function CollectRefRegions()
  local regions = {}
  for i = 1, #RefItems do
    local item = RefItems[i]
    local reg = {}
    local itemPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local itemLen = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    local itemEnd = itemPos + itemLen
    reg.regStart = itemPos
    reg.regEnd = itemEnd
    table.insert(regions, reg)
  end
  
  for i, reg in ipairs(regions) do
    local fIn, fOut
    if i > 1 then fIn = regions[i-1]['regEnd'] - reg.regStart end
    if not fIn or fIn <= 0 then fIn = 0 end
    
    if i < #regions then fOut = reg.regEnd - regions[i+1]['regStart']  end
    if not fOut or fOut <= 0 then fOut = 0 end
    
    reg.fIn = fIn
    reg.fOut = fOut
  end
  
  if #regions > 0 then return regions end
end

---------------
function CropGroups(ItemGroups)
if not Fade then Fade, RespLocked = GetSceneCrossfade() end

if Fade then
  for t, trGr in pairs(ItemGroups) do
    for g, gr in ipairs(trGr) do
      if gr.regStart and gr.regEnd then
        local inItem = gr[1]
        local outItem = gr[#gr]
        local isTrimStart
        
        local inLock = reaper.GetMediaItemInfo_Value(inItem.item, 'C_LOCK')
        local outLock = reaper.GetMediaItemInfo_Value(outItem.item, 'C_LOCK')
        
        if inLock == 0 and inItem.pos < gr.regStart and inItem['end'] > gr.regStart then
          reaper.BR_SetItemEdges(inItem.item, gr.regStart, inItem['end'])
          local fadeIn = gr.fIn
          if fadeIn == 0 then fadeIn = Fade end
          reaper.SetMediaItemInfo_Value(inItem.item, 'D_FADEINLEN', fadeIn)
          isTrimStart = true
          UndoString = 'Crop items by reference'
        end
        if outLock == 0 and outItem.pos < gr.regEnd and outItem['end'] > gr.regEnd then
          local pos = outItem.pos
          if inItem == outItem and isTrimStart then pos = gr.regStart end
          reaper.BR_SetItemEdges(outItem.item, pos, gr.regEnd)
          local fadeOut = gr.fOut
          if fadeOut == 0 then fadeOut = Fade end
          reaper.SetMediaItemInfo_Value(outItem.item, 'D_FADEOUTLEN', fadeOut)
          UndoString = 'Crop items by reference'
        end
      end
    end
  end
  
end

end

---------------
function GetSceneCrossfade()
  local defCrossfade = '240'
  local defCrossfadeUnits = 'ms' -- or 'frames'
  --local defRespLocked = 'yes'
  local crossfade
  
  local section = 'CropItemsByReference_AZ'
  local extAmount = reaper.GetExtState(section, 'amount')
  if extAmount ~= '' then defCrossfade = extAmount end
  
  local extUnits = reaper.GetExtState(section, 'units')
  if extUnits ~= '' then defCrossfadeUnits = extUnits end
  
  --local respLocked = reaper.GetExtState(section, 'respLocked')
  --if respLocked ~= '' then defRespLocked = respLocked end
  
  
  local title = 'Crop items by reference - Set crossfade between scenes'
  local captions_csv = 'Fade size (if no crossfade), ms or frames'
  local retvals_csv = defCrossfade..','..defCrossfadeUnits --..','..defRespLocked
  
  local  retval, retvals_csv = reaper.GetUserInputs
  ( title, 2, captions_csv, retvals_csv )
  
  if retval == true then
    local values = {}
    for s in retvals_csv:gmatch('[^,]+')do
      table.insert(values, s)
    end
    
    reaper.SetExtState(section, 'amount', values[1], true)
    reaper.SetExtState(section, 'units', values[2], true)
    --reaper.SetExtState(section, 'respLocked', values[3], true)
    
    if values[2] == 'ms' then
      crossfade = tonumber(values[1])/1000
    elseif string.match(values[2],'f') then
      local timestr = '00:00:00:'..values[1]
      crossfade = reaper.parse_timestr_pos( timestr, 5 )
    end
    
    --defRespLocked = string.match(values[3],'y')
    
    return crossfade, defRespLocked
  end
end

---------------
function Main()
  SelItNumb = reaper.CountSelectedMediaItems()
  SelTrNumb = reaper.CountSelectedTracks2(0, false)
  if SelTrNumb == 0 then MessageNoTrSel() return end
  if SelItNumb == 0 then
    Ref1stTrack = true
    if SelTrNumb == 1 then MessageOneTrSel() return end
  end
  
  CollectRefItems()
  if #RefItems == 0 then
    Ref1stTrack = true
    if SelTrNumb == 1 then MessageOneTrSel() return end
    CollectRefItems()
    if #RefItems == 0 then MessageNoRefItems() return end
  end
  
  Regions = CollectRefRegions()
  ItemGroups = GetItemGroupsByOverlap()
  AssignRegionsToItemGroups(Regions, ItemGroups)
  
  
  reaper.Undo_BeginBlock2(0)
  reaper.PreventUIRefresh(1)
  CropGroups(ItemGroups)
end


-------------------------
-------Start-------------
RefItems = {}
SceneStarts = {}
SceneEnds = {}
ItemsLeft = {}
ItemsRight = {}

Main()

if UndoString ~= nil then
  reaper.Undo_EndBlock2( 0, UndoString, -1 )
  reaper.UpdateArrange()
else reaper.defer(function()end) end  

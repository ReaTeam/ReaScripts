-- @description Fade tool (work on context of mouse, razor or time selection)
-- @author AZ
-- @version 1.2
-- @changelog
--   - Added options window
--   - global locking and locked items are respected now.
--   - batch fades/crossfades work for many tracks at ones.
--   - last batch values can be saved in project (by default)
-- @about
--   # Fade tool
--
--   Options window can be opened by pressing the shortcut assigned the script when mouse placed on transport or mixer panel.
--   ----------------------------------------
--   - Use top/bottom mouse placement on the item to define what fade you need, in or out.
--
--     There is two ways that you can change in the options.
--
--           Default is: top / bottom - fadein / fadeout
--
--           Another is: top / bottom - close edge fade / far edge fade
--
--   - Use razor edit area for fades and crossfades a pair of items.
--
--   - Use time selection with item selection. Such way you can crossfade items on different tracks.
--
--   - Also you can set both fades for item by selection it's middle part.
--
--   - Create batch fades / crossfades if there is at least one whole item in the area .
--
--   --------------------------
--   - There is an option (ON by default) to move edit cursor with offset before first fade. That allows you to listen changes immediately.
--
--   - Locking respected by default.
--
--   - Script warns if non-midi items have too short source for creating crossfade and offer to loop source.
--
--   - Last batch values can be saved in project (by default)
--
--
--   P.S. There is experimental support for fixed media lanes being in pre-release versions.

---------------------
Options = {
--TO MODIFY THESE OPTIONS CALL THE OPTIONS WINDOW.
--JUST PLACE MOUSE ON TRANSPORT OR MIXER PANEL AND PRESS SHORTCUT FOR THIS SCRIPT.

RespectLocking = "yes", --Global locking and locked items (yes/no)

moveEditCursor = "yes", -- moves cursor after fade set
curOffset = 1, -- offset between fade and edit cursor in sec
LRdefine = 2, -- 1 = cross define, based on close and far edge,
             -- 2 = top item half: fadein, bottom: fadeout 
DefaultFadeIn = 30, -- Fade-in in ms
DefaultFadeOut = 30, -- Fade-out in ms
DefaultCrossFade = 30, -- Default crossfade in ms
DefCrossType = 1, -- 1 = pre-crossfade, 2 = centered crossfade
RespectExistingFades = "yes", --For default batch fades/crossfades
RespectLockingBatch = "yes", --For default batch fades/crossfades

SaveLastBatchPrj = "yes", --Use and save last batch settings in project
}
--------------------
--------------------


function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end

---------------------------------
--------Options functions--------
ScriptName = 'AZ_FadeTool'

function GetExtStates()
  local respLock = reaper.GetExtState(ScriptName, 'respLock')
  if respLock:match('y') == 'y' or respLock == 'true' then
    Options.RespectLocking = 'yes'
  elseif respLock:match('n') == 'n' or respLock == 'false' then
    Options.RespectLocking = 'no'
  end

  local moveEcur = reaper.GetExtState(ScriptName, 'moveEcur')
  if moveEcur:match('y') == 'y' or moveEcur == 'true' then
    Options.moveEditCursor = 'yes'
  elseif moveEcur:match('n') == 'n' or moveEcur == 'false' then
    Options.moveEditCursor = 'no'
  end
  
  local curOffs = reaper.GetExtState(ScriptName, 'curOffs')
  if curOffs:match('%d+')~= nil then
    Options.curOffset = tonumber(curOffs)
  end
  
  local lrDef = reaper.GetExtState(ScriptName, 'lrDef')
  if tonumber(lrDef)==1 or tonumber(lrDef)==2 then
    Options.LRdefine = tonumber(lrDef)
  end
  
  -----------
  
  local defFin = reaper.GetExtState(ScriptName, 'defFin')
  if defFin:match('%d+')~= nil then
    Options.DefaultFadeIn = tonumber(defFin)
  end
  
  local defFout = reaper.GetExtState(ScriptName, 'defFout')
  if defFout:match('%d+')~= nil then
    Options.DefaultFadeOut = tonumber(defFout)
  end
  
  local defCrossF = reaper.GetExtState(ScriptName, 'defCrossF')
  if defCrossF:match('%d+')~= nil then
    Options.DefaultCrossFade = tonumber(defCrossF)
  end
  
  local defCrossT = reaper.GetExtState(ScriptName, 'defCrossType')
  if tonumber(defCrossT)==1 or tonumber(defCrossT)==2 then
    Options.DefCrossType = tonumber(defCrossT)
  end
  
  local respExistF = reaper.GetExtState(ScriptName, 'RespectExistingFades')
  if respExistF:match('y') == 'y' or respExistF == 'true' then
    Options.RespectExistingFades = 'yes'
  elseif respExistF:match('n') == 'n' or respExistF == 'false' then
    Options.RespectExistingFades = 'no'
  end
  
  local respLockB = reaper.GetExtState(ScriptName, 'RespectLockingBatch')
  if respLockB == 'y' or respLockB == 'yes' or respLockB == 'true' then
    Options.RespectLockingBatch = 'yes'
  elseif respLockB:match('n') == 'n' or respLockB == 'false' then
    Options.RespectLockingBatch = 'no'
  end
  
  local saveBatchPrj = reaper.GetExtState(ScriptName, 'SaveLastBatchPrj')
  if saveBatchPrj == 'y' or saveBatchPrj == 'yes' or saveBatchPrj == 'true' then
    Options.SaveLastBatchPrj = 'yes'
  elseif saveBatchPrj:match('n') == 'n' or saveBatchPrj == 'false' then
    Options.SaveLastBatchPrj = 'no'
  end
  
  SetGlobVariables()
end
------------------

function SetGlobVariables()
  
  if Options.RespectLocking:match('y') == 'y' or Options.RespectLocking == 'true' then
    RespectLocking = true
  elseif Options.RespectLocking:match('n') == 'n' or Options.RespectLocking == 'false' then
    RespectLocking = false
  end
  
  if Options.moveEditCursor:match('y') == 'y' or Options.moveEditCursor == 'true' then
    moveEditCursor = true
  elseif Options.moveEditCursor:match('n') == 'n' or Options.moveEditCursor == 'false' then
    moveEditCursor = false
  end
  
  curOffset = Options.curOffset
  LRdefine = Options.LRdefine
  
  -----------

  DefaultFadeIn = Options.DefaultFadeIn
  DefaultFadeOut = Options.DefaultFadeOut
  DefaultCrossFade = Options.DefaultCrossFade
  DefCrossType = Options.DefCrossType

  if Options.RespectExistingFades:match('y') == 'y' or Options.RespectExistingFades == 'true' then
    RespectExistingFades = 'yes'
  elseif Options.RespectExistingFades:match('n') == 'n' or Options.RespectExistingFades == 'false' then
    RespectExistingFades = 'no'
  end

  if Options.RespectLockingBatch:match('y') == 'y' or Options.RespectLockingBatch == 'true' then
    RespectLockingBatch = 'yes'
  elseif Options.RespectLockingBatch:match('n') == 'n' or Options.RespectLockingBatch == 'false' then
    RespectLockingBatch = 'no'
  end
  
  if Options.SaveLastBatchPrj:match('y') == 'y' or Options.SaveLastBatchPrj == 'true' then
    SaveLastBatchPrj = 'yes'
  elseif Options.SaveLastBatchPrj:match('n') == 'n' or Options.SaveLastBatchPrj == 'false' then
    SaveLastBatchPrj = 'no'
  end
end

-----------------
function SetExtStates(str)
  local retval = {}
  for s in str:gmatch('[^,]+')do
    table.insert(retval, s)
  end
  
  reaper.SetExtState(ScriptName, 'respLock',retval[1], true)
  reaper.SetExtState(ScriptName, 'moveEcur',retval[2], true)
  reaper.SetExtState(ScriptName, 'curOffs',retval[3], true)
  reaper.SetExtState(ScriptName, 'lrDef',retval[4], true)
  
  reaper.SetExtState(ScriptName, 'defFin',retval[5], true)
  reaper.SetExtState(ScriptName, 'defFout',retval[6], true)
  reaper.SetExtState(ScriptName, 'defCrossF',retval[7], true)
  reaper.SetExtState(ScriptName, 'defCrossType',retval[8], true)
  
  reaper.SetExtState(ScriptName, 'RespectExistingFades',retval[9], true)
  reaper.SetExtState(ScriptName, 'RespectLockingBatch',retval[10], true)
  
  reaper.SetExtState(ScriptName, 'SaveLastBatchPrj',retval[11], true)
end

function OptionsWindow()

  GetExtStates()
  
  local title = 'Fade tool - global options'
  local describe = 
  'Respect locking (y/n)'..','..
  
  'Move E-cursor after fade set (y/n)'..','..
  'Distance from cursor to fade in sec'..','..
  'L/R define type for mouse (1/2)'..','..
  
  'Batch: Fade-in in ms'..','..
  'Batch: Fade-out in ms'..','..
  'Batch: Crossfade in ms'..','..
  'Crossfade type 1=pre 2=centered'..','..
  'Batch: Respect existing fades(y/n)'..','..
  'Batch: Respect locking (y/n)'..','..
  'Save last batch settings in project'
  local values =
  tostring(Options.RespectLocking)..','..
  tostring(Options.moveEditCursor)..','..
  tostring(Options.curOffset)..','..
  tostring(Options.LRdefine)..','..
  tostring(Options.DefaultFadeIn)..','..
  tostring(Options.DefaultFadeOut)..','..
  tostring(Options.DefaultCrossFade)..','..
  tostring(Options.DefCrossType)..','..
  tostring(Options.RespectExistingFades)..','..
  tostring(Options.RespectLockingBatch)..','..
  tostring(Options.SaveLastBatchPrj)
  local done, str = reaper.GetUserInputs(title, 11, describe, values)
  
  if done then SetExtStates(str) end
end


function HelloMessage()
  local text = 'Hello friend! It seems you updated script "az_Fade tool".'
  ..'\n'..'Note that now you have easy access to the options.'
  ..'\n'..'Just press assigned hotkey when mouse placed on transport or mixer area.'
  ..'\n\n'..'Also there are improves now for batch fades and locking related behavior.'
  ..'\n'..'Have fun!)'
  reaper.ShowMessageBox(text,'Fade tool - Hello!',0)
end

---------------------------------
--------Work functions-----------
---------------------------------

function RazorEditSelectionExists()

    for i=0, reaper.CountTracks(0)-1 do

        local retval, x = reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0,i), "P_RAZOREDITS", "string", false)

        if x ~= "" then return true end

    end
    
    return false

end

-----------------------

function GetEnvelopePointsInRange(envelopeTrack, areaStart, areaEnd)
    local envelopePoints = {}

    for i = 1, reaper.CountEnvelopePoints(envelopeTrack) do
        local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(envelopeTrack, i - 1)

        if time >= areaStart and time <= areaEnd then --point is in range
            envelopePoints[#envelopePoints + 1] = {
                id = i-1 ,
                time = time,
                value = value,
                shape = shape,
                tension = tension,
                selected = selected
            }
        end
    end

    return envelopePoints
end


-----------------------

function GetItemsInRange(track, areaStart, areaEnd, areaTop, areaBottom) --returns items, needBatch
    local items = {}
    local itemCount = reaper.CountTrackMediaItems(track)
    local needBatch
    
    for k = 0, itemCount - 1 do 
        local item = reaper.GetTrackMediaItem(track, k)
        local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local itemEndPos = pos+length
        local iLock = reaper.GetMediaItemInfo_Value( item, "C_LOCK" )
        
        if areaBottom ~= nil then
          itemTop = reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_Y")
          itemBottom = itemTop + reaper.GetMediaItemInfo_Value(item, "F_FREEMODE_H")
          --msg("area: "..tostring(areaTop).." "..tostring(areaBottom).."\n".."item: "..itemTop.." "..itemBottom.."\n\n")
        end

        --check if item is in area bounds
        if itemEndPos > areaStart and pos < areaEnd and (iLock==0 or RespectLocking == false) then
        
          if areaBottom and itemTop then
            if itemTop < areaBottom - 0.001 and itemBottom > areaTop + 0.001 then
              table.insert(items,item)
              if pos >= areaStart and itemEndPos <= areaEnd then needBatch = true end
            end
          else
            table.insert(items,item)
            if pos >= areaStart and itemEndPos <= areaEnd then needBatch = true end
          end
          
        end

    end --end for cycle

    return items, needBatch
end

-----------------------
-----------------------

function ParseAreaPerLane(RawTable, itemH) --one level metatable
  local ParsedTable = {}
  local PreParsedTable = {}
  
  local lanesN = math.floor((1/itemH)+0.5)
  local laneW = 1/lanesN
  
  for i=1, lanesN do
    PreParsedTable[i] = {}
  end
  
  ---------------
  for i=1, #RawTable do
      --area data
      local areaStart = tonumber(RawTable[i][1])
      local areaEnd = tonumber(RawTable[i][2])
      local GUID = RawTable[i][3]
      local areaTop = tonumber(RawTable[i][4])
      local areaBottom = tonumber(RawTable[i][5])
      
    if not isEnvelope then
      areaWidth = math.floor(((areaBottom - areaTop)/itemH)+0.5) -- how many lanes include
      for w=1, areaWidth do
        local areaLane = math.floor((areaBottom/(laneW*w))+0.5)
        --msg(areaLane)
        local smallRect = {
        
              areaStart,
              areaEnd,
              GUID,
              areaBottom - (laneW*w), --areaTop
              areaBottom - (laneW*(w-1)), --areaBottom
              }

        table.insert(PreParsedTable[areaLane], smallRect)
      end
    else
      table.insert(ParsedTable, RawTable[i])
    end
    
  end
  -------------
  
  for i=1, #PreParsedTable do
    local lane = PreParsedTable[i]
    local prevEnd = nil
    for r=1, #lane do
      local smallRect = lane[r]
      
      if prevEnd ~= smallRect[1] then
        table.insert(ParsedTable, smallRect)
      else
        ParsedTable[#ParsedTable][2] = smallRect[2]
      end
      
      prevEnd = smallRect[2]
    end
  end
  
  return ParsedTable
end

-----------------------
-----------------------

function GetRazorEdits() --returns areaMap, needBatch
    local NeedPerLane = true
    local trackCount = reaper.CountTracks(0)
    local areaMap = {}
    local needBatch
    
    for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
        local mode = reaper.GetMediaTrackInfo_Value(track,"I_FREEMODE")
        if mode ~= 0 then
        ----NEW WAY----
        --reaper.ShowConsoleMsg("NEW WAY\n")
        
          local ret, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS_EXT', '', false)
          
        if area ~= '' then
        --msg(area)
            --PARSE STRING and CREATE TABLE
            local TRstr = {}
            
            for s in area:gmatch('[^,]+')do
              table.insert(TRstr, s)
            end
            
            for i=1, #TRstr do
            
              local rect = TRstr[i]
              TRstr[i] = {}
              for j in rect:gmatch("%S+") do
                table.insert(TRstr[i], j)
              end
              
            end
            
            local testItemH = reaper.GetMediaItemInfo_Value(reaper.GetTrackMediaItem(track,0), "F_FREEMODE_H")
            
            local AreaParsed = ParseAreaPerLane(TRstr, testItemH)
            
            local TRareaTable
            if NeedPerLane == true then TRareaTable = AreaParsed else TRareaTable = TRstr end
        
            --FILL AREA DATA
            local i = 1
            
            while i <= #TRareaTable do
                --area data
                local areaStart = tonumber(TRareaTable[i][1])
                local areaEnd = tonumber(TRareaTable[i][2])
                local GUID = TRareaTable[i][3]
                local areaTop = tonumber(TRareaTable[i][4])
                local areaBottom = tonumber(TRareaTable[i][5])
                local isEnvelope = GUID ~= '""'
                

                --get item/envelope data
                local items = {}
                local envelopeName, envelope
                local envelopePoints
                
                if not isEnvelope then
                --reaper.ShowConsoleMsg(areaTop.." "..areaBottom.."\n\n")
                  local TOneedBatch
                    items, TOneedBatch = GetItemsInRange(track, areaStart, areaEnd, areaTop, areaBottom)
                    if needBatch ~= true then needBatch = TOneedBatch end
                else
                    envelope = reaper.GetTrackEnvelopeByChunkName(track, GUID:sub(2, -2))
                    local ret, envName = reaper.GetEnvelopeName(envelope)

                    envelopeName = envName
                    envelopePoints = GetEnvelopePointsInRange(envelope, areaStart, areaEnd)
                end

                local areaData = {
                    areaStart = areaStart,
                    areaEnd = areaEnd,
                    areaTop = areaTop,
                    areaBottom = areaBottom,
                    
                    track = track,
                    items = items,
                    
                    --envelope data
                    isEnvelope = isEnvelope,
                    envelope = envelope,
                    envelopeName = envelopeName,
                    envelopePoints = envelopePoints,
                    GUID = GUID:sub(2, -2)
                }

                table.insert(areaMap, areaData)

                i=i+1
            end
          end
        else  
        
        ---OLD WAY for backward compatibility-------
        
          local ret, area = reaper.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
          
          if area ~= '' then
            --PARSE STRING
            local str = {}
            for j in string.gmatch(area, "%S+") do
                table.insert(str, j)
            end
        
            --FILL AREA DATA
            local j = 1
            while j <= #str do
                --area data
                local areaStart = tonumber(str[j])
                local areaEnd = tonumber(str[j+1])
                local GUID = str[j+2]
                local isEnvelope = GUID ~= '""'
        
                --get item/envelope data
                local items = {}
                local envelopeName, envelope
                local envelopePoints
                
                if not isEnvelope then
                  local TOneedBatch
                    items, TOneedBatch = GetItemsInRange(track, areaStart, areaEnd)
                    if needBatch ~= true then needBatch = TOneedBatch end
                else
                    envelope = reaper.GetTrackEnvelopeByChunkName(track, GUID:sub(2, -2))
                    local ret, envName = reaper.GetEnvelopeName(envelope)
        
                    envelopeName = envName
                    envelopePoints = GetEnvelopePointsInRange(envelope, areaStart, areaEnd)
                end
        
                local areaData = {
                    areaStart = areaStart,
                    areaEnd = areaEnd,
                    
                    track = track,
                    items = items,
                    
                    --envelope data
                    isEnvelope = isEnvelope,
                    envelope = envelope,
                    envelopeName = envelopeName,
                    envelopePoints = envelopePoints,
                    GUID = GUID:sub(2, -2)
                }
        
                table.insert(areaMap, areaData)
        
                j = j + 3
            end
          end  ---OLD WAY END
        end
    end

    return areaMap, needBatch
end

--------------------------------

function SetCrossfade(Litem,Ritem,areaData)
  local Ltake = reaper.GetActiveTake(Litem)
  local Rtake = reaper.GetActiveTake(Ritem)
  local LiNewEnd
  local RiNewStart
  
  local leftISmidi
  local rightISmidi
  
  -----------Left item edges---------------
  local LiPos = reaper.GetMediaItemInfo_Value( Litem, "D_POSITION" )
  local LiLock = reaper.GetMediaItemInfo_Value( Litem, "C_LOCK" )
  
  if LiLock == 1 and RespectLocking == false then
    table.insert(LOCKEDitems, Litem)
    reaper.SetMediaItemInfo_Value( Litem, "C_LOCK", 0 )
  end
  
  if reaper.GetMediaItemInfo_Value( Litem, "B_LOOPSRC" ) == 0 then
    local tOffs =  reaper.GetMediaItemTakeInfo_Value( Ltake, "D_STARTOFFS" )
    local source =  reaper.GetMediaItemTake_Source( Ltake )
    local srcLength, lengthIsQN = reaper.GetMediaSourceLength( source )
    local srcEnd = LiPos - tOffs + srcLength
    if lengthIsQN == true then --if take is midi
      srcEnd = areaData.areaEnd
      leftISmidi = true
    end
    LiNewEnd = math.min(srcEnd,areaData.areaEnd)
    reaper.BR_SetItemEdges(Litem, LiPos, LiNewEnd)
  else
    LiNewEnd = areaData.areaEnd
    reaper.BR_SetItemEdges(Litem, LiPos, LiNewEnd)
  end
  
  -----------Right item edges------------
  local RiPos = reaper.GetMediaItemInfo_Value( Ritem, "D_POSITION" )
  local RiEnd = RiPos + reaper.GetMediaItemInfo_Value( Ritem, "D_LENGTH" )
  local RiLock = reaper.GetMediaItemInfo_Value( Ritem, "C_LOCK" )
  
  if RiLock == 1 and RespectLocking == false then
    table.insert(LOCKEDitems, Ritem)
    reaper.SetMediaItemInfo_Value( Ritem, "C_LOCK", 0 )
  end
  
  if reaper.GetMediaItemInfo_Value( Ritem, "B_LOOPSRC" ) == 0 then
    local tOffs =  reaper.GetMediaItemTakeInfo_Value( Rtake, "D_STARTOFFS" )
    local source =  reaper.GetMediaItemTake_Source( Rtake )
    local srcLength, lengthIsQN = reaper.GetMediaSourceLength( source )
    local srcStart = RiPos - tOffs
    if lengthIsQN == true then --if take is midi
      srcStart = areaData.areaStart
      rightISmidi = true
    end
    RiNewStart = math.max(srcStart, areaData.areaStart)
    reaper.BR_SetItemEdges(Ritem, RiNewStart, RiEnd)
  else
    RiNewStart = areaData.areaStart
    reaper.BR_SetItemEdges(Ritem, RiNewStart, RiEnd)
  end
  ---------------------------------------
  
  
  -----------Chech is a gap between items--------
  if LiNewEnd and RiNewStart and LiNewEnd <= RiNewStart then
    local SourceMsg =
    "There is items pair with don't crossing sources.\n\nDo you want to loop their sources?"
    .."\nIf no there will be just longest fades if possible."
    if reaper.ShowMessageBox(SourceMsg,"Fade tool",4) == 7 then
      SetFade(Litem, "out", LiNewEnd - areaData.areaStart )
      SetFade(Ritem, "in", areaData.areaEnd - RiNewStart)
    else
      reaper.SetMediaItemInfo_Value( Litem, "B_LOOPSRC", 1 )
      reaper.SetMediaItemInfo_Value( Ritem, "B_LOOPSRC", 1 )
      reaper.BR_SetItemEdges(Litem, LiPos, areaData.areaEnd)
      reaper.BR_SetItemEdges(Ritem, areaData.areaStart, RiEnd)
    end
  end
  
  
  ---------Is new fade------- check for Midi items
  if LiNewEnd and RiNewStart and LiNewEnd > RiNewStart then
    
    if reaper.GetMediaItemInfo_Value( Litem, "D_FADEOUTLEN_AUTO") == 0 and leftISmidi == true then
      reaper.SetMediaItemInfo_Value( Litem, "D_FADEOUTLEN", LiNewEnd - RiNewStart )
    end
    
    if reaper.GetMediaItemInfo_Value( Ritem, "D_FADEINLEN_AUTO") == 0 and rightISmidi == true then
      reaper.SetMediaItemInfo_Value( Ritem, "D_FADEINLEN", LiNewEnd - RiNewStart )
    end

  end
end

-----------------------
-----------------------

function GetSetPrjBatchDefaults(get_set)
  local Mtrack = reaper.GetMasterTrack(0)
  if get_set == "set" then
    local parname
    
    parname = "P_EXT:"..'AZ_Ftool_Batch '..'DefaultFadeIn'
    local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String
    ( Mtrack, parname, tostring(DefaultFadeIn), true )
    
    parname = "P_EXT:"..'AZ_Ftool_Batch '..'DefaultFadeOut'
    local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String
    ( Mtrack, parname, tostring(DefaultFadeOut), true )
    
    parname = "P_EXT:"..'AZ_Ftool_Batch '..'DefaultCrossFade'
    local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String
    ( Mtrack, parname, tostring(DefaultCrossFade), true )
    
    parname = "P_EXT:"..'AZ_Ftool_Batch '..'DefCrossType'
    local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String
    ( Mtrack, parname, tostring(DefCrossType), true )
    
    parname = "P_EXT:"..'AZ_Ftool_Batch '..'RespectExistingFades'
    local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String
    ( Mtrack, parname, tostring(RespectExistingFades), true )
    
    parname = "P_EXT:"..'AZ_Ftool_Batch '..'RespectLockingBatch'
    local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String
    ( Mtrack, parname, tostring(RespectLockingBatch), true )

  elseif get_set == "get" then
  
    local parname
    parname = "P_EXT:"..'AZ_Ftool_Batch '..'DefaultFadeIn'
    local retval, string = reaper.GetSetMediaTrackInfo_String( Mtrack, parname, '', false )
    if string ~= "" and retval ~= false then DefaultFadeIn = tonumber(string) end
    
    parname = "P_EXT:"..'AZ_Ftool_Batch '..'DefaultFadeOut'
    local retval, string = reaper.GetSetMediaTrackInfo_String( Mtrack, parname, '', false )
    if string ~= "" and retval ~= false then DefaultFadeOut = tonumber(string) end
    
    parname = "P_EXT:"..'AZ_Ftool_Batch '..'DefaultCrossFade'
    local retval, string = reaper.GetSetMediaTrackInfo_String( Mtrack, parname, '', false )
    if string ~= "" and retval ~= false then DefaultCrossFade = tonumber(string) end
    
    parname = "P_EXT:"..'AZ_Ftool_Batch '..'DefCrossType'
    local retval, string = reaper.GetSetMediaTrackInfo_String( Mtrack, parname, '', false )
    if string ~= "" and retval ~= false then DefCrossType = tonumber(string) end
    
    parname = "P_EXT:"..'AZ_Ftool_Batch '..'RespectExistingFades'
    local retval, string = reaper.GetSetMediaTrackInfo_String( Mtrack, parname, '', false )
    if string ~= "" and retval ~= false then RespectExistingFades = string end
    
    parname = "P_EXT:"..'AZ_Ftool_Batch '..'RespectLockingBatch'
    local retval, string = reaper.GetSetMediaTrackInfo_String( Mtrack, parname, '', false )
    if string ~= "" and retval ~= false then RespectLockingBatch = string end
  end

end

-----------------------
-----------------------
function BatchFades(razorEdits)
  
  if SaveLastBatchPrj == "yes" then GetSetPrjBatchDefaults("get") end
  
  local done, str = reaper.GetUserInputs
  ( "Batch fades/crossfades", 6, "Fade-in ms,Fade-out ms,Crossfade ms,Pre-crossfade or centered,Respect existing fades y/n,RespectLocking y/n",
  tostring(DefaultFadeIn)..','..tostring(DefaultFadeOut)..','..tostring(DefaultCrossFade)..','..tostring(DefCrossType)..
  ','..tostring(RespectExistingFades)..','..tostring(RespectLockingBatch))
    if done == true then
      
      local ret = {}
      for s in str:gmatch('[^,]+')do
        table.insert(ret, s)
      end
      DefaultFadeIn = tonumber(ret[1])
      DefaultFadeOut = tonumber(ret[2])
      DefaultCrossFade = tonumber(ret[3])
      DefCrossType = tonumber(ret[4])
      RespectExistingFades = ret[5]
      RespectLockingBatch = ret[6]
      
      if SaveLastBatchPrj == "yes" then GetSetPrjBatchDefaults("set") end
      
      if RespectLockingBatch:match('n') == 'n' then
        RespectLocking = false
        reaper.Main_OnCommandEx(40596,0,0) --Locking: Clear item edges locking mode
        if start_TS ~= end_TS then
          razorEdits = GetTSandItems(start_TS, end_TS)
        else
          razorEdits = GetRazorEdits()
        end
      else RespectLocking = true
      end
      
      for i = 1, #razorEdits do
        local areaData = razorEdits[i]
        if not areaData.isEnvelope then
          local items = areaData.items
          
          local PrevEnd
          local PrevFout
          local AnyEdit
          
          for i, item in pairs(items) do
            local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
            local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
            local iFin = reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN" )
            local iFout = reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN" )
            
            if RespectExistingFades:match('n') == 'n' then iFin = 0 iFout = 0 end
            
            if iPos >= areaData.areaStart then
              if iPos == PrevEnd then
                local crossStart, crossEnd
                if DefCrossType == 1 then
                  crossStart = iPos - DefaultCrossFade/1000
                  crossEnd = iPos
                else
                  crossStart = iPos - DefaultCrossFade/2000
                  crossEnd = iPos + DefaultCrossFade/2000
                end
                
                local crossData = {
                  areaStart = crossStart,
                  areaEnd = crossEnd,
                }
                
                if PrevFout == 0 and iFin == 0 then
                  SetCrossfade(items[i-1],item, crossData)
                  AnyEdit = 1
                elseif PrevFout == 0 then
                  SetFade(items[i-1], "out", DefaultFadeOut/1000)
                  AnyEdit = 1
                elseif iFin == 0 then
                  SetFade(item, "in", DefaultFadeIn/1000)
                  AnyEdit = 1
                end
                
              elseif not PrevEnd or iPos > PrevEnd then
                if iFin == 0 then
                  SetFade(item, "in", DefaultFadeIn/1000)
                  AnyEdit = 1
                end
                if PrevFout == 0 then
                  SetFade(items[i-1], "out", DefaultFadeOut/1000)
                  AnyEdit = 1
                end
              end
              
              if i == #items and iFout == 0 and iEnd <= areaData.areaEnd then --fadeout for the last item
                SetFade(item, "out", DefaultFadeOut/1000)
                AnyEdit = 1
              end
            end
            
            PrevEnd = iEnd
            PrevFout = iFout
          end -- for in pairs(items)
          
          if AnyEdit == nil then
            reaper.defer(function()end)
          else
            reaper.Main_OnCommandEx(42406, 0, 0)  --Clear RE area
            if start_TS ~= end_TS then
              reaper.Main_OnCommandEx(40020, 0, 0)
              --Time selection: Remove (unselect) time selection and loop points
            end
          end
        end --if not area is Envelope
      end -- end for cycle #razorEdits
    end --if done
end

-----------------------
-----------------------

function FadeRazorEdits(razorEdits, needBatch) --get areaMap table and batch flag
    local areaItems = {}
    local fadeStartT = {}
    local fadeStartEdge
    reaper.PreventUIRefresh(1)
    
    local state = reaper.GetToggleCommandState(40041) --Options: Toggle auto-crossfade on/off
    if state == 0 then
      reaper.Main_OnCommandEx(40041,0,0)
    end
    
    if needBatch == true then
      UndoString = 'Batch fades/crossfades'
      BatchFades(razorEdits)
    else
    
      for i = 1, #razorEdits do
        local areaData = razorEdits[i]
        if not areaData.isEnvelope then
            local items = areaData.items
            local Litem
            local Ritem
            

            if #items == 0 or #items > 2 then
              reaper.defer(function()end)
            end

            ---------Define L/R items--------
            if #items == 2 then
              local item_1 = items[1]
              local item_2 = items[2]
              local iPos_1 = reaper.GetMediaItemInfo_Value(item_1, "D_POSITION")
              local itemEndPos_1 = iPos_1+reaper.GetMediaItemInfo_Value(item_1, "D_LENGTH")
              local iPos_2 = reaper.GetMediaItemInfo_Value(item_2, "D_POSITION")
              local itemEndPos_2 = iPos_2+reaper.GetMediaItemInfo_Value(item_2, "D_LENGTH")
              
              if iPos_1 <= areaData.areaStart and itemEndPos_1 > areaData.areaStart and iPos_1 <= iPos_2 and
              iPos_2 < areaData.areaEnd and itemEndPos_2 >= areaData.areaEnd and itemEndPos_1 <= itemEndPos_2 then
                Litem = item_1
                Ritem = item_2
              end
              
            elseif #items == 1 then
            
              item_1 = items[1]
              local iPos_1 = reaper.GetMediaItemInfo_Value(item_1, "D_POSITION")
              local itemEndPos_1 = iPos_1+reaper.GetMediaItemInfo_Value(item_1, "D_LENGTH")
              if (iPos_1 <= areaData.areaStart and itemEndPos_1 < areaData.areaEnd) or
              (iPos_1 < areaData.areaStart and itemEndPos_1 <= areaData.areaEnd)then
                Litem = item_1
              elseif (iPos_1 >= areaData.areaStart and itemEndPos_1 > areaData.areaEnd) or
              (iPos_1 > areaData.areaStart and itemEndPos_1 >= areaData.areaEnd)then
                Ritem = item_1
              end
            end

            -------------1st case-------------
            if #items == 2 and Litem and Ritem and (edgesLock == 0 or RespectLocking == false) then
              UndoString = "Set crossfade in RE area"
                --create crossfade
                table.insert(fadeStartT, areaData.areaStart)
                SetCrossfade(Litem,Ritem,areaData)
                
            end
            -------End of the 1st case-----------
            
            -------Other 3 cases-----------
            if #items == 1 then
              UndoString = "Set fade by RE area"
              if Ritem and Litem == nil then  --fade IN
                local item = items[1]
                local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
                fadeStartEdge = SetFade(item, "in", areaData.areaEnd - iPos)
                if fadeStartEdge ~= nil then table.insert(fadeStartT, fadeStartEdge) end
                
              elseif Litem and Ritem == nil then -- fade OUT
                local item = items[1]
                local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
                local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
                fadeStartEdge = SetFade(item, "out", iEnd - areaData.areaStart)
                if fadeStartEdge ~= nil then table.insert(fadeStartT, fadeStartEdge) end
                
              elseif Litem == nil and Ritem == nil then -- fades on the rests
                local item = items[1]
                local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
                local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
                fadeStartEdge = SetFade(item, "in", areaData.areaStart - iPos)
                                SetFade(item, "out", iEnd - areaData.areaEnd)
                if fadeStartEdge ~= nil then table.insert(fadeStartT, fadeStartEdge) end
                
              end
            end --other 3 cases
            
        end -- if not area is envelope
      end -- end for cycle
      
      if #fadeStartT == 0 and UndoString ~= 'Batch fades/crossfades' then UndoString = nil
      else
        reaper.Main_OnCommandEx(42406, 0, 0)  --Clear RE area
        if start_TS ~= end_TS then
          reaper.Main_OnCommandEx(40020, 0, 0)
          --Time selection: Remove (unselect) time selection and loop points
        end
      end
      
    end --else (if no Batch)
    
    if state == 0 then
      reaper.Main_OnCommandEx(40041,0,0)  --Options: Toggle auto-crossfade on/off
    end
    reaper.PreventUIRefresh(-1)
    
    return fadeStartT
end

-----------------------------------

function SaveSelItemsByTracks(startTime, endTime) --- time optional
  local SI = {}
  local oldTrack
  local needBatch
  
  for i=0, reaper.CountSelectedMediaItems(0) -1 do
    local TData = {Tname, Titems={} }
    local item = reaper.GetSelectedMediaItem(0,i)
    local iTrack = reaper.GetMediaItemTrack(item)
    
    if startTime and endTime then --is item in range
      local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
      local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
      local iLock = reaper.GetMediaItemInfo_Value(item, "C_LOCK")
      
      if iPos < endTime and iEnd > startTime and (iLock==0 or RespectLocking == false) then
        if iPos >= startTime and iEnd <= endTime then needBatch = true end
      else
        item = nil
      end
    end
    
    if item then
      if iTrack ~= oldTrack then
        oldTrack = iTrack
        TData.Tname = iTrack
        table.insert(TData.Titems, item)
        table.insert(SI, TData)
      else
        table.insert(SI[#SI].Titems, item )
      end
    end
  end

  return SI, needBatch
end

--------------------------------

function GetTSandItems(start_TS, end_TS) --returns areaMap and needBatch
  local areaMap = {}
  local items = {}
  local SI = {}
  local needBatch
  
  if reaper.CountSelectedMediaItems(0) == 2 then
    local item_1 = reaper.GetSelectedMediaItem(0,0)
    local item_2 = reaper.GetSelectedMediaItem(0,1)

    local iPos_1 = reaper.GetMediaItemInfo_Value(item_1, "D_POSITION")
    local itemEndPos_1 = iPos_1+reaper.GetMediaItemInfo_Value(item_1, "D_LENGTH")
    local iLock_1 = reaper.GetMediaItemInfo_Value(item_1, "C_LOCK")
    
    local iPos_2 = reaper.GetMediaItemInfo_Value(item_2, "D_POSITION")
    local itemEndPos_2 = iPos_2+reaper.GetMediaItemInfo_Value(item_2, "D_LENGTH")
    local iLock_2 = reaper.GetMediaItemInfo_Value(item_2, "C_LOCK")
    
    if iLock_1 == 0 and iLock_2 == 0 then
      if iPos_1 <= start_TS and itemEndPos_1 > start_TS and iPos_1 < iPos_2 and
      iPos_2 < end_TS and itemEndPos_2 >= end_TS and itemEndPos_1 < itemEndPos_2 then
        items[1] = item_1
        items[2] = item_2
      elseif iPos_2 <= start_TS and itemEndPos_2 >start_TS and iPos_2 < iPos_1 and
      iPos_1 < end_TS and itemEndPos_1 >= end_TS and itemEndPos_2 < itemEndPos_1 then
        items[1] = item_2
        items[2] = item_1
      end
    end
    
    if #items == 2 then -- if there are finded left and right items
      local areaData = {
          areaStart = start_TS,
          areaEnd = end_TS,
          
          items = items,
      }
      
      table.insert(areaMap, areaData)
    else
      SI, needBatch = SaveSelItemsByTracks(start_TS, end_TS)
      for t=1, #SI do
        local TData = SI[t]

        local areaData = {
            areaStart = start_TS,
            areaEnd = end_TS,
            
            track = TData.Tname,
            items = TData.Titems,
        }
        
        table.insert(areaMap, areaData)
      end
      
      if #SI == 0 then
        local areaData = {
            areaStart = start_TS,
            areaEnd = end_TS,
            
            track,
            items = {},
        }
        
        table.insert(areaMap, areaData)
      end
    end
  else --if not 2 items selected
    SI, needBatch = SaveSelItemsByTracks(start_TS, end_TS)
    
    for t=1, #SI do
      local TData = SI[t]
    
      local areaData = {
          areaStart = start_TS,
          areaEnd = end_TS,
          
          track = TData.Tname,
          items = TData.Titems,
      }
      
      table.insert(areaMap, areaData)
    end
    
    if #SI == 0 then
      local areaData = {
          areaStart = start_TS,
          areaEnd = end_TS,
          
          track,
          items = {},
      }
      
      table.insert(areaMap, areaData)
    end
  end
  
  return areaMap, needBatch
end


-----------------------------------
-----------------------------------

function GetTopBottomItemHalf()
local window, segment, details = reaper.BR_GetMouseCursorContext()
local x, y = reaper.GetMousePosition()
--reaper.ShowConsoleMsg("y position "..y.."\n")

local item_under_mouse = reaper.BR_GetMouseCursorContext_Item()

if item_under_mouse then
  local item_h = reaper.GetMediaItemInfo_Value( item_under_mouse, "I_LASTH" )
  local OScoeff = 1
  if reaper.GetOS():match("^Win") == nil then
    OScoeff = -1
  end
  --reaper.ShowConsoleMsg("item_h = "..item_h.."\n")
  
  local test_point = math.floor( y + item_h/2 *OScoeff)
  
  local test_item, take = reaper.GetItemFromPoint( x, test_point, true )
  
  if item_under_mouse ~= test_item then
    return "bottom"
  else
    return "top"
  end
else return "no item" end

end

------------------------------

function SetFade(item, f_type, f_size, shape ) -- returns fadeStartEdge
  if not item then return end

  if f_type == "in" then
    
    local InitOutFade = reaper.GetMediaItemInfo_Value( item, "D_FADEOUTLEN" )
    local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    local iLock = reaper.GetMediaItemInfo_Value( item, "C_LOCK" )
    
    if (iLock == 0 and fadesLock == 0) or RespectLocking == false then
      if InitOutFade ~= 0 then
       local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
       local fEdge = iPos + f_size
        if fEdge > iEnd - InitOutFade then
        reaper.SetMediaItemInfo_Value( item, "D_FADEOUTLEN", iEnd - fEdge )
        end
      end
      
      reaper.SetMediaItemInfo_Value( item, "D_FADEINLEN", f_size )
      return iPos
    end
    
  elseif f_type == "out" then
  
    local InitInFade = reaper.GetMediaItemInfo_Value( item, "D_FADEINLEN" )
    local iPos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    local iEnd = iPos + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
    local fEdge = iEnd - f_size
    local iLock = reaper.GetMediaItemInfo_Value( item, "C_LOCK" )
    
    if (iLock == 0 and fadesLock == 0) or RespectLocking == false then
      if InitInFade ~= 0 then
        if fEdge < iPos + InitInFade then
          reaper.SetMediaItemInfo_Value( item, "D_FADEINLEN", fEdge - iPos )
        end
      end
      
      reaper.SetMediaItemInfo_Value( item, "D_FADEOUTLEN", f_size )
      return fEdge
    end
  end
  
end

----------------------------

function SaveSelItems()
  Sitems = {}
  for i = 0, reaper.CountSelectedMediaItems(0) -1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    table.insert(Sitems, item)
  end
  
end

----------------------------

function RestoreSelItems()
  reaper.SelectAllMediaItems(0, false)
  for i = 1, #Sitems do
    local item = Sitems[i]
    reaper.SetMediaItemSelected(item, true)
  end
end

----------------------------

function WhatFade(half, i_pos, i_end, mPos)
  local f_type, f_size
  
  if LRdefine == 1 then --cross define
    if half == "top" then
      if (i_end - mPos) <= (mPos - i_pos) then
        f_type = "out"
        f_size = i_end - mPos
      else
        f_type = "in"
        f_size = mPos - i_pos
      end
    elseif half == "bottom" then
      if (i_end - mPos) > (mPos - i_pos) then
        f_type = "out"
        f_size = i_end - mPos
      else
        f_type = "in"
        f_size = mPos - i_pos
      end
    end
  elseif LRdefine == 2 then
    if half == "top" then
      f_type = "in"
      f_size = mPos - i_pos
    elseif half == "bottom" then
      f_type = "out"
      f_size = i_end - mPos
    end
  end
  return f_type, f_size
end

----------------------------

function FadeToMouse()
  local mPos = reaper.SnapToGrid(0,reaper.BR_GetMouseCursorContext_Position())
  local fadeStartT = {}
  local fadeStartEdge
  
  local i_pos = reaper.GetMediaItemInfo_Value(item_mouse, "D_POSITION")
  local i_end = i_pos + reaper.GetMediaItemInfo_Value(item_mouse, "D_LENGTH")
  local f_type = "in"
  local half = GetTopBottomItemHalf()
  f_type, f_size = WhatFade(half, i_pos, i_end, mPos)
 
  if reaper.IsMediaItemSelected(item_mouse) == false then
    fadeStartEdge = SetFade(item_mouse, f_type, f_size) -- item, "in"/"out" f_type, f_size, (shape)
  else
    for i=0, reaper.CountSelectedMediaItems(0) - 1 do
      local item = reaper.GetSelectedMediaItem(0,i)
      fadeStartEdge = SetFade(item, f_type, f_size) -- item, "in"/"out" f_type, f_size, (shape)
    end
  end
  
  if fadeStartEdge ~= nil then 
    table.insert(fadeStartT, fadeStartEdge)
    UndoString = 'Set fade to mouse'
  end
  
  return fadeStartT
end

------------------------------------------

function MoveEditCursor(timeTable)
  if #timeTable > 0 then
    local fadeStartEdge = math.min(table.unpack(timeTable))
    if moveEditCursor == true then
      reaper.SetEditCurPos2(0, fadeStartEdge - curOffset, false, false)
    end
  end
end

-----------------------------------------

function RestoreLockedItems()
  if RespectLocking == false and #LOCKEDitems > 0 then
    for i=1, #LOCKEDitems do
    local item = LOCKEDitems[i]
    reaper.SetMediaItemInfo_Value( item, "C_LOCK", 1 )
    end
  end
end
----------------------------------------
----------------------------------------
function Main()

GetExtStates()
LOCKEDitems = {}
edgesLock = reaper.GetToggleCommandState(40597) --Locking: Toggle item edges locking mode
fadesLock = reaper.GetToggleCommandState(40600) --Locking: Toggle item fade/volume handles locking mode

if RespectLocking ~= true and (edgesLock == 1 or fadesLock == 1) then
  reaper.Main_OnCommandEx(40596,0,0) --Locking: Clear item edges locking mode
  reaper.Main_OnCommandEx(40599,0,0) --Locking: Clear item fade/volume handles locking mode
end

if RazorEditSelectionExists() == true then
  reaper.Undo_BeginBlock2( 0 )
  reaper.PreventUIRefresh( 1 )
  sTime = FadeRazorEdits(GetRazorEdits())
  MoveEditCursor(sTime)
  RestoreLockedItems()
  if UndoString then
    reaper.Undo_EndBlock2( 0, UndoString, -1 )
    reaper.UpdateArrange()
  else reaper.defer(function()end) end
else
  start_TS, end_TS = reaper.GetSet_LoopTimeRange2( 0, false, false, 0, 0, 0 )
  if start_TS ~= end_TS and reaper.CountSelectedMediaItems(0)> 0 then
    reaper.Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    sTime = FadeRazorEdits(GetTSandItems(start_TS, end_TS))
    MoveEditCursor(sTime)
    RestoreLockedItems()
    if UndoString == 'Batch fades/crossfades' then
      reaper.Undo_EndBlock2( 0, UndoString, -1 )
    else
      reaper.Undo_EndBlock2( 0, "Fades in Time selection", -1 )
    end
    reaper.UpdateArrange()
  else
  
    item_mouse = reaper.BR_GetMouseCursorContext_Item()
    
    if item_mouse and ((RespectLocking == true and fadesLock == 0) or RespectLocking ~= true) then
      reaper.Undo_BeginBlock2( 0 )
      reaper.PreventUIRefresh( 1 )
      sTime = FadeToMouse()
      MoveEditCursor(sTime)
      if UndoString then
        reaper.Undo_EndBlock2( 0, UndoString, -1 )
        reaper.UpdateArrange()
      else reaper.defer(function()end) end
    else
      reaper.defer(function()end)
    end
  end
end


if edgesLock == 1 then
  reaper.Main_OnCommandEx(40595,0,0) --Locking: Set item edges locking mode
end
if fadesLock == 1 then
  reaper.Main_OnCommandEx(40598,0,0) --Locking: Set item fade/volume handles locking mode
end

end --end of Main()

---------------------------

-----------START-----------
if reaper.GetExtState(ScriptName,'version') ~= '1.2' then
  reaper.SetExtState(ScriptName,'version', '1.2', true)
  HelloMessage()
end
window, segment, details = reaper.BR_GetMouseCursorContext()
if window == 'transport' or window == 'mcp' then
  OptionsWindow()
else Main() end

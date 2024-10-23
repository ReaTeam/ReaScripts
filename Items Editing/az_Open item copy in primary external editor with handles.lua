-- @description Open item copy in primary external editor with handles
-- @author AZ
-- @version 1.0
-- @about
--   #Open item copy in primary external editor with handles
--
--   Like native action, but has 0,5 sec handles by default and preserves fx and envelopes.
--
--   Also, like native action, it can't adress stretch markers the right way, stretch markers will ignored.


handles = 0.5 --in sec

--FUNCTIONS--

function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end
-------------------------
--[[
function CopyMetadata(oldtake,newtake)
  local src =  reaper.GetMediaItemTake_Source( oldtake )
  --local retval, str = reaper.GetMediaFileMetadata( src, "" )
  local name = reaper.GetMediaSourceFileName( src )
  local retval, str = reaper.CF_GetMediaSourceMetadata( src, name, '' )
  msg(str)
end
-------------------------]]

-------------------------
function CopyFXandEnvelopes(oldtake,newtake)
  local fxCount =  reaper.TakeFX_GetCount(oldtake)
  local envCount = reaper.CountTakeEnvelopes(oldtake)
  
  for f=0, fxCount-1 do
    reaper.TakeFX_CopyToTake( oldtake, f, newtake, f, false )
  end
  
  --reaper.Main_OnCommandEx(reaper.NamedCommandLookup('_S&M_TAKEENVSHOW1'),0,0)
  --^^SWS/S&M: Show take volume envelope
  for e=0, envCount-1 do
    local env = reaper.GetTakeEnvelope(oldtake, e)
    local retval, envName = reaper.GetEnvelopeName( env )
    local result, envchunk = reaper.GetEnvelopeStateChunk(env,'',true)
    local basicEnv
    
    if envName == 'Volume' then --SWS/S&M: Show take volume envelope
      reaper.Main_OnCommandEx(reaper.NamedCommandLookup('_S&M_TAKEENVSHOW1'),0,0)
      basicEnv = true
    elseif envName == 'Pan' then --SWS/S&M: Show take pan envelope
      reaper.Main_OnCommandEx(reaper.NamedCommandLookup('_S&M_TAKEENVSHOW2'),0,0)
      basicEnv = true
    elseif envName == 'Mute' then --SWS/S&M: Show take mute envelope
      reaper.Main_OnCommandEx(reaper.NamedCommandLookup('_S&M_TAKEENVSHOW3'),0,0)
      basicEnv = true
    elseif envName == 'Pitch' then --SWS/S&M: Show take pitch envelope
      reaper.Main_OnCommandEx(reaper.NamedCommandLookup('_S&M_TAKEENVSHOW7'),0,0)
      basicEnv = true
    end
    
    if basicEnv == true then
      local newenv = reaper.GetTakeEnvelope(newtake, e)
      reaper.SetEnvelopeStateChunk( newenv, envchunk, 1 )
    end
  end
  
  for f=0, fxCount-1 do
    local paramsCount = reaper.TakeFX_GetNumParams( oldtake, f )
    for p=0, paramsCount-1 do
      local env = reaper.TakeFX_GetEnvelope( oldtake, f, p, false )
      if env then
        local result, envchunk = reaper.GetEnvelopeStateChunk(env,'',true)
        local newenv = reaper.TakeFX_GetEnvelope(newtake, f, p, true)
        reaper.SetEnvelopeStateChunk( newenv, envchunk, 1 )
      end
    end
  end
end
-------------------------

------------------------
function main()
  local iCount = reaper.CountSelectedMediaItems(0)
  
  --handles = AskUserHandles()
  
  Items={}
  
  for i=1, iCount do
    local item = reaper.GetSelectedMediaItem(0,i-1)
    local ipos = reaper.GetMediaItemInfo_Value(item,'D_POSITION')
    local ilen = reaper.GetMediaItemInfo_Value(item,'D_LENGTH')
    local iEnd = ipos + ilen
    Items[i] = {item,ipos,iEnd}
  end
  
  reaper.SelectAllMediaItems(0,false)
  
  for i=1, #Items do
    local item = Items[i][1]
    reaper.SetMediaItemSelected(item,true)
    local take = reaper.GetActiveTake(item)
    
    if reaper.TakeIsMIDI(take) == false then
      if not Done then Done = 1 end -- doesn't matter
      local widePos
      local wideEnd
      local offset
      
      local ipos = Items[i][2]
      local iEnd = Items[i][3]
      
      local strNum = reaper.GetTakeNumStretchMarkers( take )
      
      if strNum > 0 then
        --widePos, wideEnd = AdoptEdgesStretch()
        local title = 'Take copy with handles'
        local msg = 'Cauton! Stretch markers can not be adressed\n the right way for a while.\n Do you want to process such items?'
        if not ItemsStretchProcess then
          ItemsStretchProcess = reaper.ShowMessageBox(msg, title, 4)
        end
        if ItemsStretchProcess  == 7 then break else
          widePos = ipos - handles
          wideEnd = iEnd + handles
        end
      else
        widePos = ipos - handles
        wideEnd = iEnd + handles
      end
      
      if widePos < 0 then
        wideEnd = wideEnd - widePos
        offset = reaper.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
        reaper.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', offset + widePos)
      end
      reaper.BR_SetItemEdges(item, widePos, wideEnd)
      reaper.Main_OnCommandEx(40132,0,0) --Item: Open item copies in primary external editor
      reaper.BR_SetItemEdges(item, ipos,iEnd)
      --CreateNewSrc(take,src)
      
      local newtake = reaper.GetActiveTake(item)
      
      if widePos < 0 then
        reaper.SetMediaItemTakeInfo_Value(take, 'D_STARTOFFS', offset)
        --return offset for source take
        reaper.SetMediaItemTakeInfo_Value(newtake, 'D_STARTOFFS', widePos*-1)
        --create offset for new take
      end
      CopyFXandEnvelopes(take,newtake)
      --CopyMetadata(take,newtake)
      reaper.SetMediaItemSelected(item,false)
    end --if take isn't midi
    
  end --#Items
  
  
  
  for i=1, #Items do
    reaper.SetMediaItemSelected(Items[i][1],true)
  end
end
-------------------------
--------START------------

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

AutoCross = reaper.GetToggleCommandState(40041)
--Options: Auto-crossfade media items when editing
if AutoCross == 0 then reaper.Main_OnCommandEx(40041,0,0) end

main()
if Done then
  UndoString = 'Open item copy in ext editor with handles'
end

if AutoCross == 0 then reaper.Main_OnCommandEx(40041,0,0) end
if UndoString then
  reaper.Undo_EndBlock2(0, UndoString, -1)
  reaper.UpdateArrange()
else reaper.defer(function()end) end

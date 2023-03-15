-- @description Propagate project Pitch Shift mode to all takes with default mode
-- @author AZ
-- @version 1.0
-- @about
--   #Propagate project Pitch Shift mode to all takes with default mode
--
--   Useful for copying content to other projects.
--
--   Just select items and run the script.
--
--   NOTE: Project has to be saved in file to let the script access to its actual settings.


--FUNCTIONS--

function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end

-------------------------

function SetMode(item)
  if not PrjMode then
    local prj, projfn = reaper.EnumProjects( -1 )
    --msg(projfn)

    if (PrjSaved==nil)and (reaper.IsProjectDirty(0)==1 or projfn == '') then
      PrjSaved = reaper.ShowMessageBox
      ("The project has to be saved before action.\nDo you want to save the project?","Set pitch shift mode",4)
      if PrjSaved == 6 then
        reaper.Main_SaveProject(0, false)
        prj, projfn = reaper.EnumProjects( -1 )
      else return false end
    end
    
    if projfn ~= '' then
    
      for line in io.lines(projfn) do 
        if line:match('DEFPITCHMODE') then 
          PrjMode = {}
          for s in line:gmatch("%S+") do
            table.insert(PrjMode, s)
          end
          PrjMode.pitch = PrjMode[2]
          PrjMode.stretch = PrjMode[3]
          --msg(PrjMode.pitch)
          --msg(PrjMode.stretch)
        end
      end
     --msg(PrjMode) 
    end
    
  end --if PrjMode doesn't exist
  
  if PrjMode then
    local retval, iChunkOld = reaper.GetItemStateChunk( item, '', false )
    --msg(iChunkOld)
    
    for line in string.gmatch(iChunkOld, "([^\n]*)\n?") do
      --msg(line)
      if line:match('PLAYRATE') then
        local PLAYRATE={}
        for s in line:gmatch("%S+") do
          table.insert(PLAYRATE, s)
        end
        if tonumber(PLAYRATE[5]) == -1 or tonumber(PLAYRATE[6]) == 0 then
          EditsCount = EditsCount+1 --just for statistics
        end
        if tonumber(PLAYRATE[5]) == -1 then PLAYRATE[5] = PrjMode.pitch end
        if tonumber(PLAYRATE[6]) == 0 then PLAYRATE[6] = PrjMode.stretch end
        
        line = table.concat(PLAYRATE,' ')
      end
      
      if not iChunkNew then iChunkNew = line
      else iChunkNew = iChunkNew..'\n'..line end
      
    end 
    
    if iChunkNew then  reaper.SetItemStateChunk( item, iChunkNew, true ) end
    --msg(iChunkNew)
    
    return true
  end --if PrjMode
  
  
end

------------------------

function main()
  EditsCount = 0
  local selI = reaper.CountSelectedMediaItems(0)
  for i=0, selI-1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    local takeCount = reaper.CountTakes(item)
    
    for i=0, takeCount-1 do
      local take = reaper.GetTake(item,i)
      local mode = reaper.GetMediaItemTakeInfo_Value(take,'I_PITCHMODE')
      if mode == -1 then
        if SetMode(item) == true then break
        else goto exit end
      end
    end --takes cycle
    
  end --items cycle
  ::exit::
end

--------Start------------

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

main()
if EditsCount>0 then
  UndoString = 'Propagate project pitch mode to takes'
  reaper.ShowMessageBox('Takes were adopted: '..EditsCount,"Done",0)
end
if UndoString then
  reaper.Undo_EndBlock2(0, UndoString, -1)
  reaper.UpdateArrange()
else reaper.defer(function()end) end

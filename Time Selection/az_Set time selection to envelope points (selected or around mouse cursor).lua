-- @description Set time selection to envelope points (selected or around mouse cursor)
-- @author AZ
-- @version 1.0
-- @link Forum thread https://forum.cockos.com/showthread.php?t=288069
-- @about
--   # Set time selection to envelope points (selected or around mouse cursor)
--
--   It works for regular envelopes, automation items and take envelopes.
--   Selected points outside of visible arrange area will be ignored.
--
--   But if there are  several automation items at the same time, the most right of them will be used.
--   It's a limitation of Reaper, it's impossible to find exact automation item under mouse.

function msg(value)
  reaper.ShowConsoleMsg(tostring(value)..'\n')
end

---------

function main(env)
 
 local envItem = reaper.GetEnvelopeInfo_Value(env, 'P_ITEM')
 local startTS, endTS
 local PointsTime = {}
 local AiEdges = {}
 local aiMouse
 local prevP
 local nextP
 local itemPos = 0
 local itemLen = 0
 local takeRate = 1
 
 if envItem ~= 0 then
   itemPos = reaper.GetMediaItemInfo_Value(envItem, 'D_POSITION')
   itemEnd = itemPos + reaper.GetMediaItemInfo_Value(envItem, 'D_LENGTH')
   
   if mPos < itemPos or mPos > itemEnd then return end
   
   local envTake = reaper.GetActiveTake(envItem)
   takeRate = reaper.GetMediaItemTakeInfo_Value(envTake, 'D_PLAYRATE')
 end
 
 local aicnt = reaper.CountAutomationItems(env)
 for i=0, aicnt -1 do
 
   local aiPos = reaper.GetSetAutomationItemInfo( env, i, 'D_POSITION', 0, false )
   local aiLen = reaper.GetSetAutomationItemInfo( env, i, 'D_LENGTH', 0, false )
   table.insert(AiEdges, aiPos)
   table.insert(AiEdges, aiPos+aiLen)
   
   if aiPos < mPos and aiPos + aiLen > mPos then
     aiMouse = i
   end
   
   local pcnt = reaper.CountEnvelopePointsEx(env, i)
   for k=0, pcnt -1 do
     local ret, ptime, _, _, _, selected = reaper.GetEnvelopePointEx( env, i, k )
     if ret and ptime >= arStart and ptime <= arEnd and selected == true then
       table.insert(PointsTime, ptime)
     end
   end
   
 end
 
 
 local pcnt = reaper.CountEnvelopePoints(env)
 for i=0, pcnt -1 do
   local ret, ptime, _, _, _, selected = reaper.GetEnvelopePoint( env, i )
   
   if envItem ~= 0 then ptime = ptime / takeRate + itemPos end
   
   if ret and ptime >= arStart and ptime <= arEnd and selected == true then
     if itemPos ~= itemLen then
       if ptime >= itemPos and ptime <= itemEnd then
         table.insert(PointsTime, ptime)
       end
     else table.insert(PointsTime, ptime)
     end
   end
   
   if ptime < mPos then prevP = ptime end 
   if ptime > mPos and not nextP then nextP = ptime end
   
 end
 
 if envItem ~= 0 then
   if not prevP then prevP = itemPos end
   if not nextP then nextP = itemEnd end
   
   if itemPos > prevP then prevP = itemPos end
   if itemEnd < nextP then nextP = itemEnd end
 end
 
 if not aiMouse then
   table.sort(AiEdges)
   for i, v in ipairs(AiEdges) do
     if v < mPos and v > prevP then prevP = v end
     if v > mPos and ( not nextP or v < nextP ) then nextP = v end
   end
 end
 
 
 if #PointsTime <= 1 then
   if aiMouse then
   
     local aiPos = reaper.GetSetAutomationItemInfo( env, aiMouse, 'D_POSITION', 0, false )
     local aiLen = reaper.GetSetAutomationItemInfo( env, aiMouse, 'D_LENGTH', 0, false )
     prevP = aiPos
     nextP = nil
     
     local pcnt = reaper.CountEnvelopePointsEx(env, aiMouse)
     for i=0, pcnt -1 do
       local ret, ptime, _, _, _, selected = reaper.GetEnvelopePointEx( env, aiMouse, i )
       
       if ptime < mPos then prevP = ptime end
       if ptime > mPos and not nextP then nextP = ptime end 
     end
     
     if not nextP then nextP = aiPos + aiLen end
   end
   
   if not prevP then prevP = mPos end
   if not nextP then nextP = mPos end
   
   startTS = prevP
   endTS = nextP
   UndoString = "Set TS to a pair of envelope points around mouse"
 else
   
   table.sort(PointsTime)
   startTS = PointsTime[1]
   endTS = PointsTime[#PointsTime]
   
   UndoString = "Set TS to selected envelope points"
 end
 
 if UndoString then
   _,_ = reaper.GetSet_LoopTimeRange2(0, true, false, startTS, endTS, false)
 end
 
end

------------
------------

mPos = reaper.BR_PositionAtMouseCursor(false)
arStart, arEnd = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
local selenv

local x,y = reaper.GetMousePosition()
local track, info = reaper.GetThingFromPoint(x, y)
  
if info:match('envelope') == 'envelope' then
  selenv = reaper.GetTrackEnvelope(track, info:match('%d+'))
end

if not selenv then
  selenv = reaper.GetSelectedEnvelope(0)
end

if selenv then
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock2(0)
  main(selenv)
end

if UndoString then
  reaper.Undo_EndBlock2( 0, UndoString, -1 )
  reaper.UpdateArrange()
else reaper.defer(function()end)
end

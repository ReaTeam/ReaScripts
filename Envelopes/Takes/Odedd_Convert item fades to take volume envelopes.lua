-- @description Convert item fades to take volume envelopes
-- @author Oded D
-- @version 1.4
-- @changelog Fix envelope point appearing at -inf in some cases
-- @screenshot https://s8.gifyu.com/images/CleanShot-2022-05-30-at-09.54.51.gif
-- @about
--   Convert selected items' fades to their respective active takes' volume envelope, interpolating the existing envelope inside the fade region.
--
--   Includes code by cohler, and greatly assisted by this thread:
--     https://forum.cockos.com/showthread.php?t=262260

local minPoints = 15
local _c = {}
_c.fade = function(ftype,t,s,e,c,inout)
  --
  -- Returns 0 to 1
  --
  -- ftype is the REAPER fade type 1-7 (Note: not 0-6 here)
  -- t - time code where fade is calculated
  -- s - time code of fade start
  -- e - time code of fade end
  -- c - REAPER curvature parameter (D_FADEINDIR, D_FADEOUTDIR)
  -- inout - true for fade in, false for fade out
  --
  if e<=s then return 1 end
  t = t<s and s or t>e and e or t
  
  local x = (t-s)/(e-s)
  local ret = _c.fadein[ftype](table.unpack(inout and {x,c} or {1-x,-c}))
  return ret
end

_c.fade1 = function(x,c) return c<0 and (1+c)*x*(2-x)-c*(1-(1-x)^8)^.5 or (1-c)*x*(2-x)+c*x^4 end
_c.fade2 = function(x,c) return c<0 and (1+c)*x-c*(1-(1-x)^2) or (1-c)*x+c*x^2 end
_c.fade3 = function(x,c) return c<0 and (1+c)*x-c*(1-(1-x)^4) or (1-c)*x+c*x^4 end
_c.fade4a = function(x,c) return (c*x^4)+(1-c)*(1-(1-x)^2*(2-math.pi/4-(1-math.pi/4)*(1-x)^2)) end
_c.fade4b = function(x,c) return (c+1)*(1-x^2*(2-math.pi/4-(1-math.pi/4)*(x^2)))-c*((1-x)^4) end
_c.fade4 = function(x,c) return c<0 and (1-_c.fade4b(x,c)^2)^.5 or _c.fade4a(x,c) end
_c.fadeg = function(x,t) return t==.5 and x or ((x*(1-2*t)+t^2)^.5-t)/(1-2*t) end
_c.fadeh = function(x,t) local g = _c.fadeg(x,t); return (2*t-1)*g^2+(2-2*t)*g end

_c.fadein = {
  function(x,c) c=c or 0; return _c.fade3(x,c) end,
  function(x,c) c=c or 0; return _c.fade1(x,c) end,
  function(x,c) c=c or 1; return _c.fade2(x,c) end,
  function(x,c) c=c or -1; return _c.fade3(x,c) end,
  function(x,c) c=c or 1; return _c.fade3(x,c) end,
  function(x,c) c=c or 0; local x1 = _c.fadeh(x,.25*(c+2)); return (3-2*x1)*x1^2 end,
  function(x,c) c=c or 0; local x2 = _c.fadeh(x,(5*c+8)/16); return x2<=.5 and 8*x2^4 or 1-8*(1-x2)^4 end,
  function(x,c) c=c or 0; return _c.fade4(x,c) end,
}

function stepsByLength(length)
  if ((length * 10) < minPoints) then
    return minPoints 
  else
    return length * 10
  end
end

function generateInterpolatedFade(env, start_time, end_time, shape, direction, inout, sort)

  local take = reaper.Envelope_GetParentTake(env,0,-1)
  local takePlaybackRate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE") 
  start_time = start_time * takePlaybackRate
  end_time = end_time * takePlaybackRate
  if shape>8 then shape=1 end
  local points = {}
  local length = end_time - start_time
  local steps = stepsByLength(length / takePlaybackRate)
  local isScale = reaper.GetEnvelopeScalingMode(env)
  local safety_margin=0.0000001 * takePlaybackRate
  
  --length = length * takePlaybackRate
  -- interpolate fade curve with existing points
  if end_time > start_time then
    for t=start_time, end_time, (length/steps) do
      pointVal = _c.fade(shape, t,start_time,end_time,direction, inout) 
      retval, multiplier = reaper.Envelope_Evaluate(env,t, 44100,128)
      multiplier = reaper.ScaleFromEnvelopeMode(isScale,multiplier)
      val = reaper.ScaleToEnvelopeMode(isScale, pointVal * multiplier)
      table.insert(points, {time=t,value=val})
    end
  
    -- interpolate existing points with fade curve
    for pi=0, reaper.CountEnvelopePoints(env,-1)-1 do
    retval, t, pointVal = reaper.GetEnvelopePoint(env, pi)
      if (t >= start_time) and (t <= end_time) then
        normalizedPointVal = reaper.ScaleFromEnvelopeMode(isScale,pointVal)
        multiplier = _c.fade(shape, t, start_time,end_time,direction, inout) 
        val = reaper.ScaleToEnvelopeMode(isScale, normalizedPointVal * multiplier)
        table.insert(points, {time=t,value=val})
      elseif (t > end_time) then
        foundPoint=true
      end
    end
    reaper.DeleteEnvelopePointRange(env,start_time,end_time+safety_margin)
   
    -- insert actual points
    for tk, val in pairs(points) do
      reaper.InsertEnvelopePoint(env,val.time,val.value,0,0,false,false)
    end
    
    -- determine and insert last point
    endVal = 0
    if inout then
      retval, endVal = reaper.Envelope_Evaluate(env,end_time, 44100,128)
      endVal = reaper.ScaleFromEnvelopeMode(isScale,endVal)
    end
    val = reaper.ScaleToEnvelopeMode(isScale, endVal)
    reaper.InsertEnvelopePoint(env,end_time,val,0,0,false,false)
    if sort then reaper.Envelope_SortPoints(env) end
  end
end

function convertItemFadesToEnvelope(item)
  local itemLength = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
  local fadeinLength = not (reaper.GetMediaItemInfo_Value(item,"D_FADEINLEN_AUTO") == 0) and reaper.GetMediaItemInfo_Value(item,"D_FADEINLEN_AUTO") or reaper.GetMediaItemInfo_Value(item,"D_FADEINLEN")
  local fadeoutLength = not (reaper.GetMediaItemInfo_Value(item,"D_FADEOUTLEN_AUTO") == 0) and reaper.GetMediaItemInfo_Value(item,"D_FADEOUTLEN_AUTO") or reaper.GetMediaItemInfo_Value(item,"D_FADEOUTLEN")
  local fadeinDir = reaper.GetMediaItemInfo_Value(item,"D_FADEINDIR")
  local fadeoutDir = reaper.GetMediaItemInfo_Value(item,"D_FADEOUTDIR")
  local fadeinShape = reaper.GetMediaItemInfo_Value(item,"C_FADEINSHAPE")+1
  local fadeoutShape = reaper.GetMediaItemInfo_Value(item,"C_FADEOUTSHAPE")+1
  local take = reaper.GetActiveTake(item)
  local env = reaper.GetTakeEnvelopeByName(take,"Volume")
  local fadeinStartTime = 0 
  local fadeoutStartTime = itemLength-fadeoutLength
  
  
  if fadeinLength > 0 or fadeoutLength > 0 then
  
    -- create fade in
    generateInterpolatedFade(env,fadeinStartTime,fadeinLength,fadeinShape,fadeinDir,true,false)
    generateInterpolatedFade(env,fadeoutStartTime,itemLength,fadeoutShape,fadeoutDir,false,false)
    
    reaper.Envelope_SortPoints(env)
    --reaper.Envelope_SortPoints(env,-1)
    reaper.SetMediaItemInfo_Value(item,"D_FADEINLEN",0)
    reaper.SetMediaItemInfo_Value(item,"D_FADEINLEN_AUTO",0)
    reaper.SetMediaItemInfo_Value(item,"D_FADEOUTLEN",0)
    reaper.SetMediaItemInfo_Value(item,"D_FADEOUTLEN_AUTO",0)
  end
end


function main()
  local numSelectedMediaItems = reaper.CountSelectedMediaItems(0)
  
  -- show take envelopes for selected items
  local cmdId = reaper.NamedCommandLookup("_S&M_TAKEENVSHOW1")
  reaper.Main_OnCommand(cmdId,0)
  
  for ic = 0, numSelectedMediaItems-1 do
    local item = reaper.GetSelectedMediaItem(0,ic)
    convertItemFadesToEnvelope(item)
  end
end

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock("Convert item fades to take volume envelopes",0)

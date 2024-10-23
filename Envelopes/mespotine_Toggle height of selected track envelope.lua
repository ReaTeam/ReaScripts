-- @description Toggle height of selected track envelope
-- @author Meo-Ada Mespotine
-- @version 1.0
-- @changelog First version
-- @donation Donation options https://mespotin.uber.space/Mespotine/mespotine-unterstuetzen/
-- @about
--   # Toggle height of selected envelope.
--
--   Meo-Ada Mespotine - 8. February 2022 - licensed under MIT-license
--
--   Toggles between minimum height and the default-compactible-height of Reaper.
--   Has no effect, if there's no envelope in the project.

--- Default Values

-- Set these values according to your wishes:
  
  -- set this to the minimum height in pixels
  defheight=24

  -- set this to the maximum height in pixels
  defmaxheight=70
  

Env=reaper.GetSelectedEnvelope(0)

if Env==nil then return end

reaper.Undo_BeginBlock()

Aretval, ToggleState = reaper.GetSetEnvelopeInfo_String(Env, "P_EXT:EnvelopeToggleState", "", false)

if ToggleState=="" or ToggleState=="true" then 
  ToggleState="true" 
  Aretval, ToggleState = reaper.GetSetEnvelopeInfo_String(Env, "P_EXT:EnvelopeToggleState", "false", true)
else
  Aretval, ToggleState = reaper.GetSetEnvelopeInfo_String(Env, "P_EXT:EnvelopeToggleState", "true", true)
end
if ToggleState=="true" then 
  ToggleHeight=reaper.GetExtState("ultraschall_envelope", "EnvelopeMinHeight")
  if ToggleHeight=="" then ToggleHeight=defheight end
else
  ToggleHeight=reaper.GetExtState("ultraschall_envelope", "EnvelopeMaxHeight")
  if ToggleHeight=="" then ToggleHeight=defmaxheight end
end



retval, str = reaper.GetEnvelopeStateChunk(Env, "", false) -- get envelopestatechunk

-- get settings, we don't want to change
part1=str:match("(.-)LANE")
part2=str:match("LANEHEIGHT.-%c(.*)")

-- set height
if defheight==nil then height=str:match("LANEHEIGHT (.-) .-%c")
else height=defheight
end

newstr=part1.."LANEHEIGHT "..ToggleHeight.." 0\n"..part2 -- insert new height and compacted-state
retval, str2 = reaper.SetEnvelopeStateChunk(Env, newstr, false) -- set envelope to new settings

retval, Name=reaper.GetEnvelopeName(Env)

if ToggleState=="false" then Heightsize="max" else Heightsize="min" end
reaper.Undo_EndBlock("Toggle EnvH: "..Name.."-"..Heightsize, -1)

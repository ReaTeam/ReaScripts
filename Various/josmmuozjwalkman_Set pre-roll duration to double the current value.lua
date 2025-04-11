-- @description Set pre-roll duration to double the current value
-- @author José M Muñoz (J-WalkMan)
-- @version 1.0
-- @provides . > JWM_Set pre-roll duration to double the current value.lua
-- @about
--   Minimum value is 1 measure
--   Maximum value is 16 measures

--Script by Mnz
-- -1 is just to highlight the odd case where reaper can't find a preroll measure value
-- the script makes sure the preroll can't be set to more than 16 bars

prerollmeas = reaper.SNM_GetDoubleConfigVar("prerollmeas", -1)
if prerollmeas == 0 then
  reaper.SNM_SetDoubleConfigVar("prerollmeas", 1)
elseif prerollmeas >= 16 then
  reaper.SNM_SetDoubleConfigVar("prerollmeas", 16)
else
  reaper.SNM_SetDoubleConfigVar("prerollmeas", prerollmeas*2)
end

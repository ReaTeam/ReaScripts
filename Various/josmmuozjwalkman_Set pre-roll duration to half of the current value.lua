-- @description Set pre-roll duration to half of the current value
-- @author José M Muñoz (J-WalkMan)
-- @version 1.0
-- @provides . > JWM_Set pre-roll duration to half of the current value.lua
-- @about
--   Minimum value is 1 measure
--   Maximum value is 16 measures

--Script by Mnz
-- -1 is just to highlight the odd case where reaper can't find a preroll measure value
-- the script makes sure the preroll can't be set to less than 0

prerollmeas = reaper.SNM_GetDoubleConfigVar("prerollmeas", -1)
if prerollmeas <= 1 then
  reaper.SNM_SetDoubleConfigVar("prerollmeas", 0)
else
  reaper.SNM_SetDoubleConfigVar("prerollmeas", prerollmeas/2)
end

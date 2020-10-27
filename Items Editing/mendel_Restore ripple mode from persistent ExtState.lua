-- @description Restore ripple mode from persistent ExtState
-- @author mendel
-- @version 1.0
-- @about
--   # Restore ripple mode from persistent ExtState
--
--   This script works in conjunction with "Save ripple mode to persistent ExtState". These two scripts are intended to be used as bookends for custom actions which change the ripple mode programatically. This allows a custom action to proceed as expected, leaving the user experience of the ripple mode unchanged.

function Restore_Ripple_State()
RippleState = reaper.GetExtState("Ripple","RippleState")
  if RippleState=="A"
    then
      reaper.Main_OnCommand(40311,0,1)
      -- reaper.ShowMessageBox("Ripple Mode Restored: All Tracks", "Ripple Mode", 0)
  end
  if RippleState=="P"
    then
      reaper.Main_OnCommand(40310,0,1)
      -- reaper.ShowMessageBox("Ripple Mode Restored: Per Track", "Ripple Mode", 0)
  end
  if RippleState=="N"
    then
      reaper.Main_OnCommand(40309,0,1)
      -- reaper.ShowMessageBox("Ripple Mode Restored: Off", "Ripple Mode", 0)
  end
end

Restore_Ripple_State()

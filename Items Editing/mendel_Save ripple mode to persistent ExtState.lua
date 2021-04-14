-- @description Save ripple mode to persistent ExtState
-- @author mendel
-- @version 1.0
-- @about
--   # Save ripple mode to persistent ExtState
--
--   A most basic script that simply gets the current ripple mode, and saves it as a persistent ExtState. This state may be recalled by another script, and the ripple mode restored.
--
--   These two scripts are intended to be used in conjunction: as bookends to custom actions that require a programmatic change of the ripple mode.

Ra = reaper.GetToggleCommandState(41991)
R1 = reaper.GetToggleCommandState(41990)

function Save_Ripple_State()
  if Ra==1 then
    reaper.SetExtState("Ripple","RippleState","A",1)
    -- reaper.ShowMessageBox("Ripple Mode Saved: All Tracks", "Ripple Mode", 0)
  end
  if R1==1 then
    reaper.SetExtState("Ripple","RippleState","P",1)
    -- reaper.ShowMessageBox("Ripple Mode Saved: Per Track", "Ripple Mode", 0)
  end
  if Ra+R1==0 then
    reaper.SetExtState("Ripple","RippleState","N",1)
    -- reaper.ShowMessageBox("Ripple Mode Saved: Off", "Ripple Mode", 0)
  end
end

Save_Ripple_State()

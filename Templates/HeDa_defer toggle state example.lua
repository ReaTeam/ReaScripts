function run ()

  -- do some action
  
  reaper.defer(run)
end

function exitnow()
  _, _, sectionID, cmdID = reaper.get_action_context()
  reaper.SetToggleCommandState(sectionID, cmdID, 0)
  reaper.RefreshToolbar2(sectionID, cmdID)
  gfx.quit()
end

_, _, ,sectionID,cmdID = reaper.get_action_context()
reaper.SetToggleCommandState(sectionID, cmdID, 1)
reaper.RefreshToolbar2(sectionID, cmdID)

reaper.atexit(exitnow)
run()

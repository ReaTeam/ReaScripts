-- @noindex


function OpenSelectedProject()
  -- autosave current project
  local autosaveName = reaper.GetProjectName(0):gsub(".RPP","")
  if autosaveName ~= "" then
    reaper.Main_SaveProject(0, false)
  else
    if reaper.CountMediaItems(0) ~= 0 then
      reaper.SetExtState("Fanciest","ProjectSave","autosave_"..os.date(),false)
      local scriptFolder = ({ reaper.get_action_context() })[2]:match('^.+[\\//]')
      dofile(scriptFolder.."rxfx_Turing-complete - Save project as.lua")
    end
  end

  -- open selected project
  local folder = reaper.GetExtState("Fanciest", "ProjectFolder")
  local projectFile = reaper.GetExtState("Fanciest", "ProjectLoad")
  reaper.Main_openProject("noprompt:" .. folder .. projectFile)

end

OpenSelectedProject()

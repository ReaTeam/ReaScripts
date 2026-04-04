-- @noindex


function GetProjectFolder()
  reaper.SetExtState("Fanciest","ProjectFolder","/home/flynn/Music/",true)
end
  
-- GetProjectFolder()

function SendProjectList()
  local folder = reaper.GetExtState("Fanciest","ProjectFolder")
  local ext = "rpp"
  local files = {}
  project_list = {}
  
  local i = 0
  repeat
      local file = reaper.EnumerateFiles(folder, i)
      if file and file:lower():match("%." .. ext .. "$") then
          table.insert(files, file)
      end
      i = i + 1
  until not file
  
  -- files now contains all .rpp filenames in that folder
  for _, f in ipairs(files) do
      --reaper.ShowConsoleMsg(f .. "\n")
      table.insert(project_list,f)
  end
  checking=reaper.GetProjectName(0)
  reaper.SetExtState("Fanciest", "ProjectList", table.concat(project_list, '\n'), false)
  --reaper.ShowConsoleMsg(reaper.GetExtState("Fanciest","ProjectList"))
end

SendProjectList()


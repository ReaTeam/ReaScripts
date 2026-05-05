-- @noindex


function SaveProjectAs()
  local folder = reaper.GetExtState("Fanciest", "ProjectFolder")

  --local oldProject = reaper.GetProjectName(0):gsub(".RPP","")
  --local projectFile = reaper.GetExtState("Fanciest", "ProjectSave")
  local autosaveName = reaper.GetProjectName(0):gsub(".RPP","")
  if autosaveName ~= "" then
    reaper.Main_SaveProject(0, false)
  else
    projectFile = "autosave_"..os.date()
    reaper.Main_SaveProjectEx(0, folder .. projectFile .. ".RPP", 8)
    local projectStorage = reaper.GetProjectName(0):gsub(".RPP","")

    reaper.GetSetProjectInfo_String(0, "RECORD_PATH", projectStorage, 1)
    --reaper.ShowConsoleMsg('\n\n'..oldProject..'vs'..projectStorage..'\n')
    os.execute('mkdir "'..folder..projectStorage..'"')

    -- move all recordings
    local numItems = reaper.CountMediaItems(0)
    for i=0,numItems-1 do
      local currentItem = reaper.GetMediaItem(0, i)
      local numTakes = reaper.GetMediaItemNumTakes(currentItem)
      for n=0,numTakes-1 do
        local currentTake = reaper.GetMediaItemTake(currentItem,n)
        --if currentTake == nil then
        if currentTake ~= nil then
          local currentSource = reaper.GetMediaItemTake_Source(currentTake)
          local currentFilename = reaper.GetMediaSourceFileName(currentSource):gsub(folder,'')
          if currentFilename ~= '' then
            local t = {}
            for str in string.gmatch(currentFilename, "([^/]+)") do
              table.insert(t,str)
            end
            local finalFilename = folder..projectStorage..'/'..t[#t]
            --reaper.ShowConsoleMsg(folder..currentFilename..'\n to '..finalFilename..'\n')
            os.rename(folder..currentFilename, finalFilename)
            local finalSource = reaper.PCM_Source_CreateFromFile(finalFilename)
            reaper.SetMediaItemTake_Source(currentTake,finalSource)
          end
        end
        --
        -- GetMediaSourceFilename
        --reaper.ShowConsoleMsg(currentShort .. '\n')
      end
    end
    reaper.Main_SaveProject(0, false)
  end

  --reaper.ShowConsoleMsg(reaper.GetProjectPath())
end

SaveProjectAs()
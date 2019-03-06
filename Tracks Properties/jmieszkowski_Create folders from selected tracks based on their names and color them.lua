-- @description Create folders from selected tracks based on their names and color them
-- @author jmieszkowski
-- @version 1.0
-- @link Documentation https://github.com/jmieszkowski/ReaScripts/blob/master/README.md
-- @about
--   # Create folders from selected tracks based on their names and color them
--   This script creates folders from selected tracks accordingly to their names and color them.
--   For example if track name is"kick" it will add it to "DRUMS" folder and color it to red.
--   You can customize this script, read documentation on github for more.
--   ## How to use
--   SWS extension is required!
--   Select tracks -> run the script

function Main()

  -- this tables contain words that script uses to filter, feel free to add your own words!
  -- BUT BE CAREFUL, script doesn`t use full-match, it`s more like "does the track name contains this word?"
  -- e.g. if track name is kick12345-abcdefg-159846 it will match with "kick" from namesOfDrumTracks
  -- so if you add for example "T" as a word in same table, it wouldn`t work correctly!
  -- size of letters doesn`t matter
  namesOfDrumTracks = {"kick","snare", "tom","hi hat", "perc", "crash", "OH", "SN", "ride", "hat", "SD", "BD", "HH"}
  namesOfVocalTracks = {"voc", "vox", "choir", "vc"}
  namesOfGuitarTracks = {"GTR", "guitar", "GIT", "GT"}
  namesOfStringTracks = {"violin", "cello", "viola"}
  namesOfBassTracks = {"bass","808", "bas"}
  namesOfLoopsTracks = {"loop"}
  namesOfSynthTracks = {"synth", "synthesizer"}
  namesOfPianoTracks = {"keys", "piano"}

  -- this variables contain names of parent(folder) tracks
  -- edit them if you want, by putting a word between quotation marks ""
  -- e.g. default: drumsParentTrackName = "DRUMS"
  --      edited:  drumsParentTrackName = "MY DRUMS"
  guitarsParentTrackName = "GUITARS"
  stringsParentTrackName = "STRINGS"
  loopsParentTrackName = "LOOPS"
  synthsParentTrackName = "SYNTHS"
  pianosParentTrackName = "PIANOS"
  bassParentTrackName = "BASSES"
  drumsParentTrackName = "DRUMS"
  vocalsParentTrackName = "VOCALS"

  -- this variables contain colors of folders in RGB
  -- edit this to set your own color
  guitarsColor = reaper.ColorToNative(222,255,11)
  stringsColor = reaper.ColorToNative(255,184,16)
  loopsColor   = reaper.ColorToNative(192,16,255)
  synthsColor  = reaper.ColorToNative(16,255,255)
  pianosColor  = reaper.ColorToNative(255,192,16)
  bassesColor  = reaper.ColorToNative(16,16,255)
  drumsColor   = reaper.ColorToNative(253,0,0)
  vocalsColor  = reaper.ColorToNative(11,255,36)



  -- whoever you are, better DON`T change it!
  commandID = reaper.NamedCommandLookup("_SWS_MAKEFOLDER")-- this variable holds the sws command ID

  -- whoever you are, better DON`T change it!
  tracksIndexesThatUserSelected = {} -- that table holds indexes of tracks that user selected + parent tracks that are created
                                     -- by the script


  -- THIS SECTION FROM HERE ----------------------------------------------------------------
  -- is used to insert indexes of all tracks that user selected, to table(tracksToSelect)    

  numberOfTracks = reaper.CountSelectedTracks(0)

  for i = 0,numberOfTracks-1,1 do
    track = reaper.GetTrack(0,i)
    index = reaper.GetMediaTrackInfo_Value(track,"IP_TRACKNUMBER")
    table.insert(tracksIndexesThatUserSelected,index)
    reaper.SetMediaTrackInfo_Value(track,"I_SELECTED",0)
  end
  -- TO HERE --------------------------------------------------------------------------------

  -- this is actual call of function that creates folder

  createFolder(tracksIndexesThatUserSelected, namesOfStringTracks, stringsParentTrackName, stringsColor)
  createFolder(tracksIndexesThatUserSelected, namesOfLoopsTracks, loopsParentTrackName, loopsColor)
  createFolder(tracksIndexesThatUserSelected, namesOfSynthTracks, synthsParentTrackName, synthsColor)
  createFolder(tracksIndexesThatUserSelected, namesOfPianoTracks, pianosParentTrackName, pianosColor)
  createFolder(tracksIndexesThatUserSelected, namesOfGuitarTracks, guitarsParentTrackName, guitarsColor)
  createFolder(tracksIndexesThatUserSelected, namesOfBassTracks, bassParentTrackName, bassesColor)
  createFolder(tracksIndexesThatUserSelected, namesOfDrumTracks, drumsParentTrackName, drumsColor)
  createFolder(tracksIndexesThatUserSelected, namesOfVocalTracks, vocalsParentTrackName, vocalsColor)

  colorTracksToParentTrackColor(tracksIndexesThatUserSelected)
end

-- function colors tracks in folder to their parents track color
function colorTracksToParentTrackColor(tracksToColor)

  for i=0, tableLength(tracksToColor)-1, 1 do
       track = reaper.GetTrack(0,i)
       folder_info =  reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH')
       parent_track = reaper.GetParentTrack(track)

       if parent_track ~= nil then -- check if track has a parent track, otherwise it would throw an error
         color = reaper.GetTrackColor(parent_track)

         if color ~= 0 then
             reaper.SetTrackColor(track,color)
         end
       end
  end
end

-- function creates folder from tracks which names suits to specific table (e.g. namesOfDrumTracks)
function createFolder(tracksToSelect,tableWithTrackNames, nameOfParentTrack, folderColor)
  local numberOfTracksAddedToTheFolder = 0

  for i = 0, tableLength(tracksToSelect)-1, 1 do
    local track = reaper.GetTrack(0, i)
    local _, track_name = reaper.GetTrackName(track, "")

    if contains(tableWithTrackNames, track_name) then
      reaper.SetMediaTrackInfo_Value(track, "I_SELECTED",1)
      numberOfTracksAddedToTheFolder = numberOfTracksAddedToTheFolder + 1
    end
  end

  if numberOfTracksAddedToTheFolder > 1 then -- validate if there is more than 1 track in the group, dont want to create folder with 1 track
    reaper.InsertTrackAtIndex(0,0) -- insert track at the begining of the project, it will be parent track
    table.insert(tracksToSelect,tableLength(tracksToSelect)) -- insert one more element to this table, it holds indexes of 
                                                           -- all tracks that are currently in this project

    local parent_track = reaper.GetTrack(0,0) -- take this track which i just inserted

    reaper.SetTrackColor(parent_track, folderColor)
    reaper.GetSetMediaTrackInfo_String(parent_track, "P_NAME" ,nameOfParentTrack, true)
    reaper.SetMediaTrackInfo_Value(parent_track, "I_SELECTED", 1)
    reaper.ReorderSelectedTracks(1,1) -- reorder all selected tracks, i need this, because sws - make folder from selected tracks
                                    -- works only for tracks that are directly in touch with each other
    reaper.SetMediaTrackInfo_Value(parent_track, "I_FOLDERCOMPACT", 2)

    reaper.Main_OnCommandEx(commandID, 0, 0) -- it executes sws make folder from selected tracks
  end
  clearSelect(tracksToSelect) -- clear selects, this function have already made a folder for selected tracks, so there is no need
                              -- to hold them selected
end

-- function unselects all tracks that are currently selected
-- without this script doesn`t work, because it creates folder from selected tracks, so they have to be unselected
-- after script creates a folder from them
function clearSelect(tracksToSelect)
  for i = 0, tableLength(tracksToSelect)-1, 1 do
    track = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, "I_SELECTED",0)
  end
end

-- function gets table and returns its length
-- i used it to program loops
function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
    return count
end

-- function checks if table contains specific string
-- i used it to check if table contains track name
-- for example if namesOfDrumsTracks contains "kick"(track name)
function contains(tab,name)
  for i=1, tableLength(tab),1 do
   if string.match(string.upper(name), string.upper(tab[i])) then -- i convert strings to uppercase letters because
    return true                                                   -- it eliminates the problem with comparison strings
   end                                                            -- with lowercase and uppercase letters :)
  end
  return false
end




Main()


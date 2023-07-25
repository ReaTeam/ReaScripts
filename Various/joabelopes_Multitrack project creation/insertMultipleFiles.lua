-- @noindex

--[[
# DESCRIPTION

Add multiple instruments from multiple musics on multiple tracks at once.

It will read all the folders inside the project folder, all the files inside then, and add the correct audio files into the correct tracks, based on the name of the file, the name of the track folder, and the search table.
 
The audio file name will be compared with the elements of the "searchTable", using regex pattern, so if something match, the audio will be added.

The searchTable is a matrix of arrays. 
Each array has the following elements: {"pattern of the name", trackFolderNumber , haveProjectMarker}.

* The first element (string) is required; 
* The second element (number) is only needed if you don't have a track folder (with UPPERCASE name) that matches the pattern searched;
* The third element (true or false) is only recommended for the audios on the first track of the project, because it will add a marker with the name of the folder that the audio belong, helping to organize the project (example: the metronome track, suposing that you have one metronome audio file for each music).


For example, you want to add all the guitar files (from all folders inside the project folder) on the project:
* add inside the searchTable: ..., {"guitar"}, ...
* add on the project:

GUITARS (track folder)
guitar_base_1 (track)
guitar_base_2 (track)
guitar_solo_1 (track)
guitar_solo_2 (track)


* Author: Joabe Lopes
* Github repo: https://github.com/joabeslopes/Reaper-scripts-multitrack-creation/
* Licence: GPL v3
* Extensions required: None
]]


-- adjust this table according to your needs
searchTable = { {"cli",0,true},{"regencia",2},{"guia"},{"bass"},{"baixo"},{"guita"},{"vio"},{"perc"},{"sanf"},{"acordeon"},{"key"},{"tecla"},{"piano"},{"org"},{"fx"},{"sax"},{"trompete"} }


-- split a big string into an array of strings, separated by the line breaks ( \n )
function splitString(bigString)
    stringArray = {}
    for str in string.gmatch(bigString, "[^\n]+") do
        table.insert(stringArray, str)
    end
    return stringArray
end

-- discover the kind of running OS, based on the project path
function findOS(projectPath)
    if string.find(projectPath, "^/.*") then -- probably Unix OS (Linux or MacOS)
        return "unix"
    elseif string.find(projectPath, "^%u:.*") then -- probably Windows OS
        return "windows"
    end
end

-- search for the file and it's corresponding track
function regexFullSearch(musicPath, fileName, regex, trackFolder)
    if string.find(fileName, string.upper(regex)) then
        if string.find(fileName, ".*SOLO.*") then
            temp = string.sub(fileName, string.find(fileName, ".*SOLO.*"))
            if string.find(temp, ".*_R.*") then
                audioPath = musicPath..string.sub(temp, string.find(temp, ".*_R.*"))
                correctTrackNumber = trackFolder + 4
            elseif string.find(temp, ".*_2.*") then
                audioPath = musicPath..string.sub(temp, string.find(temp, ".*_2.*"))
                correctTrackNumber = trackFolder + 4
            elseif string.find(temp, ".*%pR.*") then
                audioPath = musicPath..string.sub(temp, string.find(temp, ".*%pR.*"))
                correctTrackNumber = trackFolder + 4
            else
                audioPath = musicPath..temp
                correctTrackNumber = trackFolder + 3
            end
        elseif string.find(fileName, ".*BASE.*") then
            temp = string.sub(fileName, string.find(fileName, ".*BASE.*"))
            if string.find(temp, ".*_R.*") then
                audioPath = musicPath..string.sub(temp, string.find(temp, ".*_R.*"))
                correctTrackNumber = trackFolder + 2
            elseif string.find(temp, ".*%pR.*") then
                audioPath = musicPath..string.sub(temp, string.find(temp, ".*%pR.*"))
                correctTrackNumber = trackFolder + 2
            elseif string.find(temp, ".*_2.*") then
                audioPath = musicPath..string.sub(temp, string.find(temp, ".*_2.*"))
                correctTrackNumber = trackFolder + 2
            else
                audioPath = musicPath..temp
                correctTrackNumber = trackFolder + 1
            end
        elseif string.find(fileName, ".*_L.*") then
            audioPath = musicPath .. string.sub(fileName, string.find(fileName, ".*_L.*"))
            correctTrackNumber = trackFolder + 1
        elseif string.find(fileName, ".*%pL.*") then
            audioPath = musicPath..string.sub(fileName, string.find(fileName, ".*%pL.*"))
            correctTrackNumber = trackFolder + 1
        elseif string.find(fileName, ".*_R.*") then
            audioPath = musicPath..string.sub(fileName, string.find(fileName, ".*_R.*"))
            correctTrackNumber = trackFolder + 2
        elseif string.find(fileName, ".*%pR.*") then
            audioPath = musicPath..string.sub(fileName, string.find(fileName, ".*%pR.*"))
            correctTrackNumber = trackFolder + 2

        else
            audioPath = musicPath..string.sub(fileName, string.find(fileName, string.upper(regex)))
            correctTrackNumber = trackFolder
        end
    
    elseif string.find(fileName, regex) then

        if string.find(fileName, ".*solo.*") then
            temp = string.sub(fileName, string.find(fileName, ".*solo.*"))
            if string.find(temp, ".*_R.*") then
                audioPath = musicPath..string.sub(temp, string.find(temp, ".*_R.*"))
                correctTrackNumber = trackFolder + 4
            elseif string.find(temp, ".*_r.*") then
                audioPath = musicPath..string.sub(temp, string.find(temp, ".*_r.*"))
                correctTrackNumber = trackFolder + 4
            elseif string.find(temp, ".*%pR.*") then
                audioPath = musicPath..string.sub(temp, string.find(temp, ".*%pR.*"))
                correctTrackNumber = trackFolder + 4
            elseif string.find(temp, ".*%pr.*") then
                audioPath = musicPath..string.sub(temp, string.find(temp, ".*%pr.*"))
                correctTrackNumber = trackFolder + 4
            elseif string.find(temp, ".*_2.*") then
                audioPath = musicPath..string.sub(temp, string.find(temp, ".*_2.*"))
                correctTrackNumber = trackFolder + 4
            else
                audioPath = musicPath..temp
                correctTrackNumber = trackFolder + 3
            end
        elseif string.find(fileName, ".*base.*") then
            temp = string.sub(fileName, string.find(fileName, ".*base.*"))
            if string.find(temp, ".*_R.*") then
                audioPath = musicPath..string.sub(temp, string.find(temp, ".*_R.*"))
                correctTrackNumber = trackFolder + 2
            elseif string.find(temp, ".*_r.*") then
                audioPath = musicPath..string.sub(temp, string.find(temp, ".*_r.*"))
                correctTrackNumber = trackFolder + 2
            elseif string.find(temp, ".*%pR.*") then
                audioPath = musicPath..string.sub(temp, string.find(temp, ".*%pR.*"))
                correctTrackNumber = trackFolder + 2
            elseif string.find(temp, ".*%pr.*") then
                audioPath = musicPath..string.sub(temp, string.find(temp, ".*%pr.*"))
                correctTrackNumber = trackFolder + 2
            elseif string.find(temp, ".*_2.*") then
                audioPath = musicPath..string.sub(temp, string.find(temp, ".*_2.*"))
                correctTrackNumber = trackFolder + 2
            else
                audioPath = musicPath..temp
                correctTrackNumber = trackFolder + 1
            end
        elseif string.find(fileName, ".*_L.*") then
            audioPath = musicPath .. string.sub(fileName, string.find(fileName, ".*_L.*"))
            correctTrackNumber = trackFolder + 1
        elseif string.find(fileName, ".*_l.*") then
            audioPath = musicPath..string.sub(fileName, string.find(fileName, ".*_l.*"))
            correctTrackNumber = trackFolder + 1
        elseif string.find(fileName, ".*%pL.*") then
            audioPath = musicPath..string.sub(fileName, string.find(fileName, ".*%pL.*"))
            correctTrackNumber = trackFolder + 1
        elseif string.find(fileName, ".*%pl.*") then
            audioPath = musicPath..string.sub(fileName, string.find(fileName, ".*%pl.*"))
            correctTrackNumber = trackFolder + 1
        elseif string.find(fileName, ".*_R.*") then
            audioPath = musicPath..string.sub(fileName, string.find(fileName, ".*_R.*"))
            correctTrackNumber = trackFolder + 2
        elseif string.find(fileName, ".*_r.*") then
            audioPath = musicPath..string.sub(fileName, string.find(fileName, ".*_r.*"))
            correctTrackNumber = trackFolder + 2
        elseif string.find(fileName, ".*%pR.*") then
            audioPath = musicPath..string.sub(fileName, string.find(fileName, ".*%pR.*"))
            correctTrackNumber = trackFolder + 2
        elseif string.find(fileName, ".*%pr.*") then
            audioPath = musicPath..string.sub(fileName, string.find(fileName, ".*%pr.*"))
            correctTrackNumber = trackFolder + 2
        else
            audioPath = musicPath..string.sub(fileName, string.find(fileName, regex))
            correctTrackNumber = trackFolder
        end
    end

    return audioPath, correctTrackNumber
end


-- insert the audio files in the project
function insertAudioTake(audioPath, trackNumber, folderName)
    if folderName then
        reaper.AddProjectMarker(0, false, reaper.GetCursorPosition(), 0, folderName, -1)
    end
    track = reaper.GetTrack(0, trackNumber)
    reaper.SetOnlyTrackSelected(track)
    reaper.InsertMedia(audioPath, 0)

end

-- search the corresponding folder of the track and adjust it in the search table
function fillSearchTable(searchTable)
    for i = 1, reaper.CountTracks(0) do
        track = reaper.GetTrack(0,i-1)
        nothing, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        for j =1, #searchTable do
            nameSearch = string.upper(searchTable[j][1])
            if string.find(trackName, ".*"..nameSearch..".*") then
                searchTable[j][2] = i
            end
        end
    end
end


---------------------- Main function ----------------------

-- correct the search table
fillSearchTable(searchTable)


-- discover the running OS and insert the medias in the project
projectPath = reaper.GetProjectPath()
os = findOS(projectPath)

if os == "unix" then

    projectFolders = io.popen('ls "'..projectPath..'"', 'r')
    readFolders = projectFolders:read('*all')
    if readFolders then
        foldersNames = splitString(readFolders)
        projectFolders:close()

        for folder = 1, #foldersNames do
            if (not string.find(foldersNames[folder], ".*%prpp.*")) and (not string.find(foldersNames[folder], "%ptxt$")) then -- ignore the project file and text files

                musicPath = projectPath.. '/' ..foldersNames[folder].. '/'
                allFiles = io.popen('ls "' .. musicPath .. '"', 'r'):read('*all')
                filesNames = splitString(allFiles)
                io.popen('ls "' ..musicPath.. '"', 'r'):close()

                for file = 1, #filesNames do
                    if string.find(filesNames[file], ".*%pwav$") or string.find(filesNames[file], ".*%pmp3$") then --select only audio files (.wav or .mp3)

                        for s=1, #searchTable do
                            regex = ".*"..searchTable[s][1]..".*"
                            trackFolder = searchTable[s][2]
                            haveProjMarker = searchTable[s][3]
                            if string.find(filesNames[file]:upper(),regex:upper()) then
                                audioPath, trackNumber = regexFullSearch(musicPath, filesNames[file], regex, trackFolder)

                                if haveProjMarker then
                                    insertAudioTake(audioPath, trackNumber, foldersNames[folder])
                                else
                                    insertAudioTake(audioPath, trackNumber)
                                end

                            end
                        end

                    end
                end
            end
        end
    else
        reaper.ShowConsoleMsg("Folder read error")
    end

elseif os == "windows" then

    projectFolders = io.popen('dir /b "'..projectPath..'"', 'r')
    readFolders = projectFolders:read('*all')
    if readFolders then
        foldersNames = splitString(readFolders)
        projectFolders:close()

        for folder = 1, #foldersNames do
            if (not string.find(foldersNames[folder], ".*%prpp.*")) and (not string.find(foldersNames[folder], "%ptxt$")) then -- ignore the project file and text files

                musicPath = projectPath.. '\\' ..foldersNames[folder].. '\\'
                allFiles = io.popen('dir /b "' .. musicPath .. '"', 'r'):read('*all')
                filesNames = splitString(allFiles)
                io.popen('dir /b "' ..musicPath.. '"', 'r'):close()

                for file = 1, #filesNames do
                    if string.find(filesNames[file], ".*%pwav$") or string.find(filesNames[file], ".*%pmp3$") then --select only audio files (.wav or .mp3)

                        for s=1, #searchTable do
                            regex = ".*"..searchTable[s][1]..".*"
                            trackFolder = searchTable[s][2]
                            haveProjMarker = searchTable[s][3]
                            if string.find(filesNames[file]:upper(), regex:upper()) then
                                audioPath, trackNumber = regexFullSearch(musicPath, filesNames[file]:upper(), regex:upper(), trackFolder)

                                if haveProjMarker then
                                    insertAudioTake(audioPath, trackNumber, foldersNames[folder])
                                else
                                    insertAudioTake(audioPath, trackNumber)
                                end

                            end
                        end

                    end
                end
            end
        end
    else
        reaper.ShowConsoleMsg("Folder read error")
    end
end

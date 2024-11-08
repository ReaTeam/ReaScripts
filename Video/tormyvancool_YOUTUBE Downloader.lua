-- @description YOUTUBE Downloader
-- @author Tormy Van Cool
-- @version 2.9
-- @Changelog:
-- 1.0 2024-26-10
--     # First Release
-- 1.1 2024-26-10
--     + Processes Notifications
--     - /Video/
--     + /Videos/
-- 1.2 2024-26-10
--     - --merge-output-format mp4
--     + -S vcodec:h264,res,acodec:aac
-- 1.3 2024-26-10
--     - 10
--     + 2
-- 1.4 2024-26-10
--     - 2
--     + 5
-- 1.5 2024-26-10
--     - 5
--     + 1
--     # Unified Update
-- 1.6 2024-26-10 - 1
--     + 2
--     + Version
-- 1.7 2024-27-10
--     - 'start "" "' from all O.S.s
--     + 'start "UPDATE & DOWNLOAD" "' Win
-- 1.8 2024-27-10
--     - GGGGG = ''
--     - 1
--     + Start = '"'
--     + 2
-- 1.9 2024-27-10
--     + Check saved project
--     - 1
--     + 2
-- 2.0 2024-27-10
--     - "chmod +x " ..  MainPath
--     + 'chmod +x "' ..  MainPath .. '"'
--     # Ordered Variables
--     - 2
--     + 1
--     + Apple Trial
-- 2.3 2024-27-10
--     # Linux execution correction
--     + Credits
--     # 2.1 and 2.2 just trials due issues with Linux and Apple
-- 2.31 2024-28-10
--     # Binaries directly form the source
-- 2.32 2024-28-10
--     - yt-dlp
--     + yt-dlp_linux
-- 2.4 2024-29-10
--     # Adjusted header style for production
-- 2.5 2024-11-04
--     - Various 
--     + VideoPath = 'Video'
-- 2.6 2024-11-05
--     + check for temrination of temporary file upfrotn import the video
-- 2.7 2024-11-05
--     - Check Routine
-- 2.8 2024-11-06
--     + Detects Nework Interruptions during download
--     + Removes leftovers
--     + URLs as filename: forbidden
--     + Limitation to only alphanumerical characters
-- 2.9 2024-11-06
--     + Check IfFileExists: Overwrite, Newname, Exit
--     + check if the subdir for yt-dlp exists. if not it warns the user and stops the script
-- @about:
-- # Import VIDEOs directly in TimeLine from YouTUBE, VIMEO, PATREONS and thousand other ones.
--  
--    Key Features:
-- 
--    - 4 click operation: Start the script, enter the URL, give a title, click on OK
--    - Import any Video in TimeLine by giving just the URL
--    - Videos are saved into the project folder under the dedicated /Videos/ folder
--    - Videos are imported into a new track, having the given name, and at the cursor position
--    - Auto-update of the binaries "yt-dlp" each time the script is invoked, to ensure top quality at each use
--    - Compatible with about thousand platforms included:
--    - YouTUBE
--    - Vimeo
--    - Patreons
--    and several other ones ...
-- 
--   [Full list here](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)
-- @Credits:
--    Stefano marcantoni and Ben Talagan - to have helped for MAC implementation
--    Paolo Saggese PMS67 - to have helped for Linux implementation
--    cfillion - for his support during general debug
--    smandrap - for his key suggestoin to that helped to improve the reliability. Topic https://forum.cockos.com/showthread.php?t=96087
-- @provides
--   [win64] yt-dlp/yt-dlp.exe https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe
--   [linux] yt-dlp/yt-dlp_linux https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp
--   [darwin64] yt-dlp/yt-dlp_macos https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos
--   [darwin-arm64] yt-dlp/yt-dlp_macos https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos
--   [win64]        .
--   [linux]        .
--   [darwin64]     .
--   [darwin-arm64] .

reaper.ClearConsole()

---------------------------------------------
-- MAIN VARIABLES
---------------------------------------------
local LF = "\n"
local pipe = "|"
local colon = ":"
local quote = '"'
local slash = '\\'
local backslash = '/'
local clock = os.clock
local debug = false
local ver = 2.9
local InputVariable = ""
local dlpWin = 'yt-dlp.exe'
local dlpMac = 'yt-dlp_macos'
local dlpLnx = 'yt-dlp_linux'
local version = reaper.GetAppVersion()
local pj_name_ = reaper.GetProjectName(0, "")
local ProjDir = reaper.GetProjectPathEx(0)
local ResourcePATH = reaper.GetResourcePath()
local VideoPath = 'Video'
_,ScriptName = reaper.get_action_context()
local ScriptPath = ScriptName:match('^.+[\\/]') -- Script Path
local CallPath = ScriptPath .. 'yt-dlp/' -- Get FullPath to yt-dlp

      -- CHECK IF YT-DLP FOLDER IS CREATED BY REAPACK AS EXPECTED
      a=0
      CheckForDir = ""
      repeat
        if CheckForDir == "yt-dlp" then
          returnedDir = CheckForDir
        end
        CheckForDir = reaper.EnumerateSubdirectories( ScriptPath, a)
        a = a + 1
      until(CheckForDir == nil)
      if returnedDir == nil then
        local retQuery = reaper.MB("This script must be isntalled from a Reapack Repository.\n\nClick \"OK\", remove it and install it as it should!\n", "INSTALLATION ERROR", 0)
        if retQuery == 1 then
          goto done 
        end
      end
      
---------------------------------------------
-- FUNCTIONS
---------------------------------------------
      
      -- SLEEP(SECONDS)
      function sleep(n)
        local t0 = clock()
        while clock() - t0 <= n do end
      end
      
      -- IDENTIFIES THE O.S.
      function getOS()
        local OS = reaper.GetOS()
        local a = {}
        local MainPath = ''
        if OS == "Win32" or OS == "Win64" then
          MainPath = '"' .. ResourcePATH .. '/Scripts/Tormy Van Cool ReaPack Scripts/' .. VideoPath .. '/yt-dlp/' .. dlpWin .. '"'
          Start = 'start /b /wait "UPDATE & DOWNLOAD" '
          OpSys = 1
        end
        if OS == "OSX64" or OS == "macOS-arm64" then
          MainPath  = './yt-dlp_macos'
          Start = 'cd "' .. CallPath .. '" && chmod +x ' .. dlpMac .. ' && '
          os.execute('chmod +x "' ..  MainPath .. '"')
          OpSys = 2
        end
        if OS == "Other" then
         -- MainPath = ResourcePATH .. '/Scripts/Tormy Van Cool ReaPack Scripts/Various/yt-dlp/' .. dlpLnx .. '"'
         -- Start = '"'
         -- os.execute('chmod +x "' ..  MainPath .. '"')
          MainPath = '"' .. ResourcePATH .. '/Scripts/Tormy Van Cool ReaPack Scripts/' .. VideoPath .. '/yt-dlp/' .. dlpLnx .. '"'
          Start = ''
          os.execute('chmod +x ' ..  MainPath)
          OpSys = 3
        end
        return MainPath
      end
      
      -- GET FILE SIZE
      function get_file_size(filename)
          local file = io.open(filename, "rb")
          if not file then return 0 end
          local size = file:seek("end")
          file:close()
          return size
      end
      
      local MainPath = getOS()

      -- FILTER OUT PROHIITED CHARACTERS
      function GetRid(chappy, seed, subs) -- Get rid of not-admitted characters to prevent any error by user
        local ridchap
        if subs == nil then subs = "" end
        if chappy == nil then return end
        local ridchap = string.gsub (chappy, seed,  subs)
        return ridchap
      end

      -- CHECK FOR URL VALIDITY
      function is_valid_url(url)
        -- Pattern to match a basic URL structure
        local pattern = "^https?://[%w-_%.%?%.:/%+=&]+$"
        return url:match(pattern) ~= nil
      end

      local minVersion = '7.27'
      if minVersion > version then
        reaper.MB('your Reaper verions is '..version..'\nPlease update REAPER to the last version!', 'ERROR: REAPER '..version..' OUTDATED', 0)
        goto done
      end
---------------------------------------------
-- INTERACTIONS
---------------------------------------------

      -- CHECK WHETHER PROJECT IS SAVED
      if pj_name_ == "" then 
        reaper.MB("YOU MUST SAVE THE PROJECT FIRST! Then relaunch this script!",'WARNING',0)
        return
      end

      -- GET URL
      repeat
      retval, url=reaper.GetUserInputs("DOWNLOAD VIDEO", 1, "Paste URL,extrawidth=400", InputVariable)
      if retval==false then return end
      if retval then
        t = {}
        i = 0
        for line in url:gmatch("[^" .. LF .. "]*") do
            i = i + 1
            t[i] = line
        end
      end
      if t[1]== "" then
        reaper.MB("VIDEO URL is MANDATORY","ERROR",0,0)
      end
      if is_valid_url(t[1]) == false then
        reaper.MB("URL NOT VALID","ERROR",0,0)
      end
      until( t[1] ~= "" and is_valid_url(t[1]) == true)
      
      
      -- GET FILENAME
      ::getfilename::
      repeat
      retval_1, FileName=reaper.GetUserInputs("DOWNLOAD VIDEO", 1, "Insert FILE NAME,extrawidth=400", InputVariable)
      FileName = GetRid(GetRid(GetRid(GetRid(GetRid(FileName, pipe), colon), quote), slash), backslash) -- No reserved characters can be written
      FileName = FileName:gsub("http", "")

      if retval_1==false then return end
      if retval_1 then
        t = {}
        i = 0
        for line in FileName:gmatch("[^" .. LF .. "]*") do
            i = i + 1
            t[i] = line
        end
      end
      
      -- NO EMPTY TITLE ADMITTED
      if t[1]== "" then
        reaper.MB("VIDEO TITLE is MANDATORY","ERROR",0,0)
      end
      
      -- NO URLS AND NOT ALPHANUMERICAL CHARACTERS ADMITTED
      if t[1]:match("[^%w%s]") then
        reaper.MB("ONLY ALPHANUMERIC CHARACTERS ADMITTED","ERROR",0,0)
        t[1]=""
      end
      until( t[1] ~= "")

---------------------------------------------
-- ARGS & TRIGGERS
---------------------------------------------

      if FileName ~= "" 
        then
          if string.find(FileName, ".mp4") == nil then
            FileTemp = FileName .. '.f137.mp4.part'
            FileName = FileName .. ".mp4"
          end
          argument = ' -o "'  .. FileName .. '"'
          FileTemp = FileName:sub(1, -5) .. '.f137.mp4.part'
      end
      
      -- ARGS
      args = " --update-to master -S vcodec:h264,res,acodec:aac " .. url .. ' -P "' .. ProjDir .. '/Videos/"' .. argument .. " --force-overwrite"
      upArgs = " --update-to master"

      -- TRIGGERS
      Update = Start .. MainPath .. upArgs
      Video = Start .. MainPath .. args
      Destination =  ProjDir ..'/Videos/' .. FileName
      Destination = Destination:gsub('\\','/')
      

---------------------------------------------
-- UPDATE AND IMPORT VIDEO
---------------------------------------------

      if url  ~= "" then

          if debug == true then 
            reaper.ShowConsoleMsg("FileName: " .. FileTemp .. "\n")
            reaper.ShowConsoleMsg("Destination: " .. Destination .. "\n")
          end
          
          -- CHECK IF FILE EXISTS
          local checkfile = reaper.file_exists(Destination)
          local answer = nil
          if checkfile == true then
            answer = reaper.MB("A file with the same filename exists\nWould you want to overwrite it?\n\nYES => Go on\nNO => Rewrite the filname\nCANCEL => Exit",'WARNING: FILENAME EXISTS',3)
          end
          if answer == 7 then 
            goto getfilename 
          elseif answer == 2 then
            goto done
          end
          
          reaper.MB("STARTED THE FOLLOWING PROCESSES v" .. ver .. ":\n\n1. Update YT-DLP\n2. Downlaod the video: " ..url .. "\n3. Naming the video: " .. FileName .. ".mp4 \n4. Saving the video into " .. ProjDir .. "/Videos/\n5. Import the video into the project\n\nHEY it will take a little while. DON'T PANIC!\n\nCLICK ON \"OK\" TO CONTINUE", "PROCESS STARTED. PROCESSES LISTED HERE BELOW",0)
          
          -- DIFFERENTIATE EXECUTION BASED ON O.S.
          if OpSys == 2 then
            os.execute(Update)
            os.execute(Video)
          elseif OpSys == 1 or OpSys == 3 then
            os.execute(Start .. MainPath .. upArgs .. args)
          end
          
          
          ---------------------------------------------
          -- NETWORK DISRUPTION
          ---------------------------------------------
          
          -- GET RESIDUAL FILES AND REMOVE THEM
          local ResFiles ="" 
          a=0
          test = ""
          repeat
            if test:find(".mp4.part") then
              returned = test
            end
            test = reaper.EnumerateFiles( ProjDir .. "/Videos", a)
            a = a + 1
          until(test == nil)
          if returned ~= nil then
            local retQuery = reaper.MB("Due a Network Error, the video was not properly downloaded.\nBY CLICKING OK THESE LEFTOVERS WILL BE REMOVED\n\nLeftovers:\n\n" .. returned, "NETWORK ERROR", 0)
            if retQuery == 1 then
            os.remove(ProjDir .. "/Videos/" .. returned)
            end
          else
            reaper.InsertMedia(Destination, 1)
          end

          if debug == true then 
            local stable = false
            local last_size = get_file_size(Destination)
            while not stable or io.open(FileTemp, "rb")  do
                
                local new_size = get_file_size(Destination)
                
                if new_size > 0 and new_size == last_size then
                    stable = true
                else
                    last_size = new_size
                end
            end
          end


      end

::done::

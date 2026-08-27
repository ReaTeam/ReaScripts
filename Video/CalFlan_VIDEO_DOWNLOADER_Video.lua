-- @description Reaper Web-Video Downloader
-- @author CalFlan
-- @version 1.0
-- @changelog First Commit
-- @provides
--   [windows] .
--   [windows main] CalFlan_VIDEO_DOWNLOADER_Video/CalFlan_VIDEO_DOWNLOADER_Audio.lua
-- @about
--   # Reaper Web-Video Downloader:
--
--   ## Set up
--   In order to use this script, you'll need to install yt-dlp and place the .exe into the "yt-dlp" folder as seen below
--
--   <img width="224" height="122" alt="image" src="https://github.com/user-attachments/assets/f39c0dfd-074d-44f6-9528-80ecd9591fbe" />
--
--
--   The yt-dlp git hub page can be found [here](https://github.com/yt-dlp/yt-dlp#installation)
--
--   Or the .exe can be downloaded directly from [This Link](https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe)
--
--   For more information on yt-dlp, and why it is being used in this project, see the about yt-dlp section
--
--   ## User Guide
--   ### What's Included
--   Two scripts are included in this repo: 
--   * One script downloads video + audio. 
--   * The other downloads only the extracted audio.
--  
--   The scripts are near identical, except for the arguments being passed to yt-dlp
--
--   ### Step by Step
--   * Upon using the script you'll be prompted for a video URL
--   * Once you've pasted the URL, hit enter and the script will then open a command line and run yt-dlp with the appropriate arguments and begin downloading
--   * The video will be downloaded to your projects media folder, If the project is unsaved the default recording path will be used instead
--   * Download progress will be displayed in the command line
--   * Once the video is download is complete, the video will be imported into Reaper.  
--
--   ## About yt-dlp
--   This script works by using yt-dlp, a public domain, open source and feature rich command-line based video downloader. 
--
--   [More information and the download for on yt-dlp can be found here](https://github.com/yt-dlp/yt-dlp)
--
--   yt-dlp and this script supports downloading form a wide range of websites, not just YouTube, including Vimeo, Twitch and many more:
--
--   [A full list of supported websites can be found here](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md) 
--
--   ## Mac or Linux users
--   Currently this version of the script only works on PC, primarily because it is the only platform I have access to test on.
--
--   If you are a Mac or Linux user looking to use this script, I'd encourage you to fiddle around and try and get it working with this as a framework.
--
--   I imagine you'll simply need to replace the .exe and the cmd line functions with something appropriate for your machine

-- Get the script's directory to make paths relative to the script location
local script_path = debug.getinfo(1).source:match("@(.*)") or ""
local script_dir = script_path:match("(.+)\\") or ""

-- CHANGE ME
-- local ytdlp_path = script_dir .. "\\yt-dlp" -- Relative path to yt-dlp folder
local ytdlp_exe = script_dir .. "\\yt-dlp.exe"

-- Settings
local Download_format = '-f "bv[ext=webm]+ba[ext=m4a]" --restrict-filenames' -- Replace with your desired format options

-- Get Directory
local url = ""
local download_Path = reaper.GetProjectPath("")-- Gets set to ReaProject Path, or Default recording path if project is not saved
--
local function Checkforytdlp()
    local file = io.open(ytdlp_exe, "r")
    if file then
        io.close(file)
        return(true)
    else
        reaper.ShowMessageBox("yt-dlp.exe not found at: \n\n" .. ytdlp_exe .. "\n\nPlease install yt-dlp, See README.md For instructions", "Error, yt-dlp.exe missing", 0)
        return(false)
    end
end

local function promptURL()
    local retval, user_input = reaper.GetUserInputs("Video Downloader", 1, "Enter Video URL:, extrawidth=200",url)
    if retval then
        url = user_input
    else
        url = nil
    end
end

local function get_last_file_name(download_Path)
    local command = 'dir /a-d /o-d /tc /b "'..download_Path..'" 2>nul:' -- /tw for last modified file, /tc for last created file
    local pipe = io.popen(command)
    local file_name = pipe:read()
    pipe:close()
    return file_name
 end
 
 local function importVideo()
    local file_name = get_last_file_name(download_Path)
    if file_name then
        reaper.InsertMedia(download_Path.."\\"..file_name,1)
    else
        reaper.ShowConsoleMsg("Directory is empty")
    end
 end

local function DownloadVideo()
    if not url then -- Check if URL is provided
        reaper.ShowMessageBox("No URL provided", "Error", 0)
        return
    end
    
    -- Check if exe exists
    local file = io.open(ytdlp_exe, "r")
    if file then
        io.close(file)
    else
        reaper.ShowMessageBox("yt-dlp.exe not found at: " .. ytdlp_exe, "Error", 0)
        return
    end
    local command = "cmd /c \"\"" .. ytdlp_exe .. "\" " .. Download_format .. " -P  \"" .. download_Path .. "\" \"" .. url .. "\" 2>&1\"" -- Build the command to run yt-dlp with the specified options
    -- reaper.ShowConsoleMsg("Running command: " .. command .. "\n")
    os.execute(command) -- Run the command 
    importVideo()
end

if Checkforytdlp() then
    promptURL()
    DownloadVideo()
end

-- @noindex

-- Get the script's directory to make paths relative to the script location
local script_path = debug.getinfo(1).source:match("@(.*)") or ""
local script_dir = script_path:match("(.+)\\") or ""

-- CHANGE ME
-- local ytdlp_path = script_dir .. "\\yt-dlp" -- Relative path to yt-dlp folder
local ytdlp_exe = script_dir .. "\\yt-dlp.exe"

-- Settings
local Download_format = '-x --force-overwrites --audio-format wav --restrict-filename' -- Replace with your desired format options

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
    local retval, user_input = reaper.GetUserInputs("Audio Downloader", 1, "Enter Video URL:, extrawidth=200",url)
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

-- Body
if Checkforytdlp() then
    promptURL()
    DownloadVideo()
end

-- @description Save project plugin info to text file
-- @author Edgemeal
-- @version 1.06-1
-- @provides [main] edgemeal_Save project plugin info to text file/edgemeal_Save project plugin info to text file (Don't open notepad on Windows).lua
-- @link Forum https://forum.cockos.com/showthread.php?t=225219
-- @donation Donate https://www.paypal.me/Edgemeal

function Add_TakeFX(fx_names, name)
  for i = 1, #fx_names do -- do not add duplicates
    if fx_names[i] == name then return end
  end
  fx_names[#fx_names+1] = name
end

local function RemoveFileExt(file)
  local index = (file:reverse()):find("%.")
  if index > 0 then
    return string.sub(file, 1, #file-index)
  else
    return file
  end
end

function Status(fx_name, preset_name, enabled, offline)
  local s = (enabled and "" or "*") .. (offline and "#" or "") -- combine indicators w/o spaces.
  s = s .. ((s ~= "") and " " .. fx_name or fx_name) -- fx name, prefix with space if indicators present.
  t[#t+1] = s .. ((preset_name ~= "") and " <> Preset: " .. preset_name or "") -- add preset name if present.
end

function AddFX(track,fx_count)
  for fx = 0, fx_count-1 do
    local _, fx_name = reaper.TrackFX_GetFXName(track, fx, "")
    local _, preset_name = reaper.TrackFX_GetPreset(track, fx, "")
    local enabled = reaper.TrackFX_GetEnabled(track, fx) -- bypass
    local offline = reaper.TrackFX_GetOffline(track, fx) -- offline
    Status(fx_name,preset_name,enabled,offline) -- add fx info
  end
  -- Track Sends
  local send_cnt = reaper.GetTrackNumSends(track, 0)
  if send_cnt > 0 then
    local s = 'Track Sends('..tostring(send_cnt)..'): '
    for send_index = 0, send_cnt - 1 do
      local retval, send_name = reaper.GetTrackSendName(track, send_index, '')
      s = s .. send_name .. ((send_index < send_cnt - 1) and ', ' or '')
    end
   t[#t+1] = s
  end
end

function AddItemFX(track,track_name)
  local itemcount = reaper.CountTrackMediaItems(track)
  if itemcount > 0 then
    local fx_used = {}
    for j = 0, itemcount-1 do
      local item = reaper.GetTrackMediaItem(track, j)
      local take = reaper.GetActiveTake(item)
      if take then
        local fx_count = reaper.TakeFX_GetCount(take)
        for fx = 0, fx_count-1 do
          local _, fx_name = reaper.TakeFX_GetFXName(take, fx, "")
          Add_TakeFX(fx_used,fx_name)
        end
      end
    end
    if #fx_used > 0 then
      local tn = track_name .. ' - Media Items FX\n'
      t[#t+1]=tn..string.rep('-', #tn-1)
      t[#t+1]= table.concat(fx_used, "\n")
      t[#t+1]= "" -- empty line
    end
  end
end
 
function AddFxMonitor()
  local track = reaper.GetMasterTrack()
  local cnt = reaper.TrackFX_GetRecCount(track) -- get fx count in 'fx monitoring' chain.
  if cnt > 0 then
    local tn ="FX Monitoring\n"
    t[#t+1]=tn..string.rep('-', #tn-1)
    for i = 0, cnt-1 do
      local fx = (0x1000000 + i) -- convert for fx monitoring
      local retval, fx_name = reaper.TrackFX_GetFXName(track, fx, "")
      local _, preset_name = reaper.TrackFX_GetPreset(track, fx, "")
      local enabled = reaper.TrackFX_GetEnabled(track, fx) -- bypass
      local offline = reaper.TrackFX_GetOffline(track, fx) -- offline
      Status(fx_name,preset_name,enabled,offline) -- add fx info
    end
    t[#t+1]= "" -- add empty line
  end
end

function Get_Line1(filename)
  local file = io.open(filename, "r")
  local line = file:read("*line")
  file:close()
  return line
end

function Main()
  local date, proj, projfn = '', reaper.EnumProjects(-1, "")
  if projfn ~= "" then
    t[#t+1]="Project: "..reaper.GetProjectName(proj, "")
    t[#t+1]="Path: "..reaper.GetProjectPath("")
    local line = Get_Line1(projfn)-- get project time stamp, last word in 1st line of project file.
    if line then   -- convert last word in string to date, "Month(word) #Day, #Year  #Time"
      date = 'Date: '..os.date("%B %d, %Y  %X", tonumber(line:match(".* (.*)")))
      t[#t+1] = date
    end
    t[#t+1]='Length: '..reaper.format_timestr(reaper.GetProjectLength(proj), "")
  else
    t[#t+1]="Unknown project (not saved)"
  end
  if #date > 0 then t[#t+1] = string.rep('-', #date+1) end ---- seperator line.
  t[#t+1]= '* = Plugin disabled\n# = Plugin offline'
  if #date > 0 then t[#t+1] = string.rep('-', #date+1) end ---- seperator line.
  t[#t+1]= ""  -- empty line
  
  -- FX Monitor
  AddFxMonitor()

  -- Master Track
  local track = reaper.GetMasterTrack(0)
  local fx_count = reaper.TrackFX_GetCount(track)
  if fx_count > 0 then
    local tn ="Master Track\n"  -- add track name
    t[#t+1]=tn..string.rep('-', #tn-1)
    AddFX(track,fx_count)
    t[#t+1]= ""  -- empty line
  end
  
  -- Regular Tracks
  local track_count = reaper.CountTracks(0)
  for i = 0, track_count-1  do
    local track = reaper.GetTrack(0, i)
    local _, track_name = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME' , '', false)
    local tn ='Track '..tostring(i+1)..': '..track_name..'\n'  -- add track name
    t[#t+1]=tn..string.rep('-', #tn-1)
    AddFX(track,reaper.TrackFX_GetCount(track))
    t[#t+1]= ""  -- empty line
    AddItemFX(track, string.sub(tn,1,#tn-1)) -- show fx names used in items on this track.
  end
  
  -- save project info to text file in project folder
  if projfn ~= "" then
    local fn = RemoveFileExt(projfn).." - Project Plugins.txt"
    local file = io.open(fn, "w")
    file:write(table.concat(t,"\n"))
    file:close()

    -- Close instances with exact same title open via Windows notepad.
    local os = reaper.GetOS()-- get OS
    if (os == 'Win32') or (os == 'Win64') then
      if reaper.APIExists('JS_Window_FindTop') then -- check if JS_API extension is installed
        local np_title = RemoveFileExt(reaper.GetProjectName(proj, ""))..' - Project Plugins.txt - Notepad'
        local hwnd = reaper.JS_Window_FindTop(np_title, true)
        while hwnd do
          reaper.JS_WindowMessage_Send(hwnd, "WM_CLOSE", 0,0,0,0)
          hwnd = reaper.JS_Window_FindTop(np_title, true)
        end
      end
    end
    if reaper.APIExists('CF_ShellExecute') then -- check if SWS extension is installed
      reaper.CF_ShellExecute(fn) -- open text file in OS default application
    end
  else
    reaper.ClearConsole()
    reaper.ShowConsoleMsg(table.concat(t,"\n"))
  end
end

t = {} -- store proj info
Main()

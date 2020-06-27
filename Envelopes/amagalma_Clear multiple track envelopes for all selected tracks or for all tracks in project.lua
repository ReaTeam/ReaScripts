-- @description Clear multiple track envelopes for all selected tracks or for all tracks in project
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showthread.php?p=2311051#post2311051
-- @screenshot https://i.ibb.co/pX7rsyg/amagalma-Clear-multiple-track-envelopes-for-all-selected-tracks-or-for-all-tracks-in-project.gif
-- @donation https://www.paypal.me/amagalma
-- @about
--   #Clear multiple track envelopes for all selected tracks or for all tracks in project
--
--   - Displays a window where you can select multiple track envelopes to be cleared/removed. It works for all the selected tracks or for all the tracks in the project.
--   - Due to a Reaper bug, currently UNDO is not possible
--   - Requires Lokasenna GUI v2. If not installed/set-up, user is prompted with automatic installation/set-up.


-- Check Lokasenna_GUI library availability --
local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" or not reaper.file_exists(lib_path .. "Core.lua") then
  local not_installed = false
  local Core_library = {reaper.GetResourcePath(), "Scripts", "ReaTeam Scripts", "Development", "Lokasenna_GUI v2", "Library", "Core.lua"}
  local sep = reaper.GetOS():find("Win") and "\\" or "/"
  Core_library = table.concat(Core_library, sep)
  if reaper.file_exists(Core_library) then
    local cmdID = reaper.NamedCommandLookup( "_RS1c6ad1164e1d29bb4b1f2c1acf82f5853ce77875" )
    if cmdID > 0 then
          reaper.MB("Lokasenna's GUI path will be set now. Please, re-run the script", "Lokasenna GUI v2 Installation", 0)
      -- Set Lokasenna_GUI v2 library path.lua
      reaper.Main_OnCommand(cmdID, 0)
      return reaper.defer(function() end)
    else
      not_installed = true
    end
  else
    not_installed = true
  end
  if not_installed then
    reaper.MB("Please, right-click and install 'Lokasenna's GUI library v2 for Lua' in the next window. Then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List. After all is set, you can run this script again. Thanks!", "Install Lokasenna GUI v2", 0)
    reaper.ReaPack_BrowsePackages( "Lokasenna GUI library v2 for Lua" )
    return reaper.defer(function() end)
  end
end
loadfile(lib_path .. "Core.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Options.lua")()
if missing_lib then 
  reaper.MB("Please re-install 'Lokasenna's GUI library v2 for Lua'", "Missing library!", 0)
  return reaper.defer(function() end)
end
local GUI = GUI

--------------------------------------------------------------

local function Cancel()
  gfx.quit()
end

local selected_tracks_cnt = reaper.CountSelectedTracks( 0 )

local function Clear_Envelopes(tracks_table, envelope_table)
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  local env_cleared_count = 0
  local tr_s = #tracks_table == 1 and "" or "s"
  for tr = 1, #tracks_table do
    local t = {}
    local open = false
    local track = tracks_table[tr]
    local _, chunk = reaper.GetTrackStateChunk( track, "", false )
    for line in chunk:gmatch("[^\n]+") do
      local save_line = true
      if ( envelope_table[4] and line == ("<VOLENV") ) or
        ( envelope_table[5] and line == ("<PANENV") ) or
        ( envelope_table[1] and line == ("<VOLENV2") ) or
        ( envelope_table[2] and line == ("<PANENV2") ) or
        ( envelope_table[6] and line == ("<WIDTHENV") )or
        ( envelope_table[3] and line == ("<WIDTHENV2") ) or
        ( envelope_table[7] and line == ("<VOLENV3") ) or
        ( envelope_table[8] and line == ("<MUTEENV") )
      then
        open = true
        env_cleared_count = env_cleared_count + 1
      end
      if open and line:find(">") then 
        open = false
        save_line = false
      end
      if save_line and not open then
        t[#t+1] = line
      end
    end
    reaper.SetTrackStateChunk( track, table.concat(t, "\n"), false )
  end
  reaper.PreventUIRefresh(-1)
  local env_s = env_cleared_count == 1 and "" or "s"
  reaper.MB("Cleared a total of: " .. env_cleared_count .. " envelope" .. env_s .. " of " .. #tracks_table ..
            " track" .. tr_s, "Done!", 0)
  local numtr = #tracks_table == selected_tracks_cnt and "selected" or "all"
  reaper.Undo_EndBlock( "Remove Selected Envelopes for " .. numtr .. " track" .. tr_s, 1 )
end


local function OK()
  local envelope_count, envelope_table = GetEnvelopeSelection()
  local env_s = envelope_count == 1 and "" or "s"
  if envelope_count == 0 then
    reaper.MB("Please, select some envelopes first.", "No Track Envelopes selected", 0)
    return
  end
  local msg = "Due to a Reaper bug, UNDO is not possible! Are you sure you want to clear the selected envelope" .. env_s
  if GUI.Val("All") then
    local all_track_cnt = reaper.CountTracks( 0 )
    local ok = reaper.MB(msg .. " of ALL tracks?", "Clear selected envelope" .. env_s .. " of ALL tracks ( " ..
        all_track_cnt .. " track" .. (all_track_cnt == 1 and "" or "s") .." )", 1)
    if ok == 1 then
      local t = {}
      for tr = 0, all_track_cnt-1 do
        t[tr+1] = reaper.GetTrack(0, tr)
      end
      Clear_Envelopes(t, envelope_table)
      ClearEnvelopeSelection()
    else
      return
    end
  else
    local tr_s = selected_tracks_cnt == 1 and "" or "s"
    local ok = reaper.MB(msg .. " of the SELECTED tracks?", "Clear selected envelope" .. env_s .. 
        " of SELECTED tracks ( " .. selected_tracks_cnt .. " track" .. tr_s .. " )", 1)
    if ok == 1 then
       t = {}
      for tr = 0, selected_tracks_cnt-1 do
        t[tr+1] = reaper.GetSelectedTrack(0, tr)
      end
      Clear_Envelopes(t, envelope_table)
      ClearEnvelopeSelection()
    else
      return
    end
  end
end

GUI.name = "Clear Track Envelopes"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 200, 360
GUI.anchor, GUI.corner = "screen", "C"


GUI.New("Envelopes", "Checklist", {
    z = 1,
    x = 20,
    y = 13,
    w = 160,
    h = 220,
    caption = "Track Envelopes",
    optarray = {"Volume", "Pan", "Width", "Volume (Pre-FX)", "Pan (Pre-FX)", "Width (Pre-FX)", "Trim Volume", "Mute"},
    dir = "v",
    pad = 5,
    font_a = 2,
    font_b = 2,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = true,
    shadow = false,
    swap = false,
    opt_size = 20
})


GUI.New("All", "Checklist", {
    z = 1,
    x = 6,
    y = 233,
    w = 180,
    h = 25,
    caption = "",
    optarray = {"All tracks in project!"},
    dir = "v",
    pad = 5,
    font_a = 2,
    font_b = 2,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = false,
    swap = true,
    opt_size = 20
})

GUI.New("Selected", "Checklist", {
    z = 1,
    x = 6,
    y = 263,
    w = 180,
    h = 25,
    caption = "",
    optarray = {"Selected tracks only"},
    dir = "v",
    pad = 5,
    font_a = 2,
    font_b = 2,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = false,
    swap = true,
    opt_size = 20
})


GUI.New("OK", "Button", {
    z = 1,
    x = 21,
    y = 305,
    w = 70,
    h = 25,
    caption = "OK",
    font = 2,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = OK
})

GUI.New("Cancel", "Button", {
    z = 1,
    x = 109,
    y = 305,
    w = 70,
    h = 25,
    caption = "Cancel",
    font = 2,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = Cancel
})


function GetEnvelopeSelection()
  local count = 0
  local t = {}
  for i = 1, 8 do
    if GUI.elms.Envelopes.optsel[i] then
      count = count + 1
      t[i] = true
    else
      t[i] = false
    end
  end
  return count, t
end

function ClearEnvelopeSelection()
  for i = 1, 8 do
    GUI.elms.Envelopes.optsel[i] = false
  end
end

function GUI.elms.Selected:onmouseup()
  if not self.focus then
    self:redraw()
    return
  end
  local mouseopt = self:getmouseopt()
  if not mouseopt then return end
  if selected_tracks_cnt > 0 then
    self.optsel[mouseopt] = not self.optsel[mouseopt]
    self.focus = false
    self:redraw()
    GUI.Val("All", not self.optsel[mouseopt])
  end
end

function GUI.elms.All:onmouseup()
  if not self.focus then
    self:redraw()
    return
  end
  local mouseopt = self:getmouseopt()
  if not mouseopt then return end
  if selected_tracks_cnt > 0 then
    self.optsel[mouseopt] = not self.optsel[mouseopt]
    self.focus = false
    self:redraw()
    GUI.Val("Selected", not self.optsel[mouseopt])
  end
end


GUI.colors.txt = {225, 225, 225, 255}
GUI.Draw_Version = function ()
  local str = "Script by amagalma using Lokasenna_GUI v2"
  GUI.font("version")
  GUI.color("txt")
  local str_w, str_h = gfx.measurestr(str)
  gfx.x = gfx.w/2 - str_w/2
  gfx.y = gfx.h - str_h - 4
  gfx.drawstr(str)
end

local function Check()
  selected_tracks_cnt = reaper.CountSelectedTracks( 0 ) 
  if selected_tracks_cnt < 1 then
    if GUI.elms.Selected.col_txt == "txt" then
      GUI.elms.Selected.col_txt = "gray"
      GUI.Val("Selected", false)
      GUI.Val("All", true)
      GUI.elms.Selected:redraw()
    end
  else
    if GUI.elms.Selected.col_txt == "gray" then
      GUI.elms.Selected.col_txt = "txt"
      GUI.elms.Selected:redraw()
    end
  end
end

if selected_tracks_cnt > 0 then
  GUI.Val("Selected", true)
else
  GUI.Val("All", true)
end
GUI.func = Check
GUI.freq = 0.4

GUI.Init()
GUI.Main()

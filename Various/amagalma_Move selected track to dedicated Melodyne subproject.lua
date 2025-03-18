-- @description Move selected track to dedicated Melodyne subproject
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about
--   Moves the selected track to a dedicated subproject that has only the track and Melodyne.
--   Suitable only for Melodyne ARA

local i = 0
MelodyneInstalled = false
while true do
  local retval, name, ident = reaper.EnumInstalledFX( i )
  if not retval then break end
  if name:match("Melodyne") then
    MelodyneInstalled = true ; break
  end
  i=i+1
end
if not MelodyneInstalled then
  return reaper.MB("Melodyne does not seem to be reachable by Reaper.\nThere is no point in running this script.", "Aborting..", 0 )
end
i = nil

local track_cnt = reaper.CountSelectedTracks( 0 )
local err = "Please select a track to move into a Melodyne subproject."
if track_cnt ~= 1 then
  return reaper.MB( err, "Exactly one track must be selected.", 0 )
end

local sel_track = reaper.GetSelectedTrack( 0, 0 )

local sel_track_items = reaper.CountTrackMediaItems( sel_track )
local unsuitable_items = 0
for i = 0, sel_track_items-1 do
  local item = reaper.GetTrackMediaItem( sel_track, i )
  local take = reaper.GetActiveTake( item )
  if (not take) or reaper.TakeIsMIDI(take) then
    unsuitable_items = unsuitable_items + 1
  end
end
if unsuitable_items == sel_track_items then
  return reaper.MB("The selected track has no suitable audio files.", "Aborting..", 0 )
end

local orig_project = reaper.EnumProjects( -1 )
local orig_track_id = reaper.GetMediaTrackInfo_Value( sel_track, "IP_TRACKNUMBER" )

------------------------------------------------------------------------------------

track_has_Melodyne_already = reaper.TrackFX_AddByName( sel_track, "Melodyne", false, 0 ) ~= -1

local fx_chunk
local _, chunk = reaper.GetTrackStateChunk( sel_track, "", false )
local fx_chunk_cnt = 0
local captured_fx, c = {}, 0
local div, fx_chain
local start_fx = track_has_Melodyne_already and 1 or 0
for line in chunk:gmatch("[^\n\r]+") do
  if (not fx_chain) and line == "<FXCHAIN" then fx_chain = true ; div = 0 end
  if fx_chain then
    if line:match("BYPASS %d+ %d+ %d+") then
      fx_chunk_cnt = fx_chunk_cnt + 1
    elseif line:match("^<") then div = div + 1
    elseif line:match("^>") then div = div - 1
    end
    if div == 0 then fx_chain = false end
    if fx_chunk_cnt > start_fx then
      c = c + 1
      captured_fx[c] = line
    end
  end
end
reaper.Undo_BeginBlock2( orig_project )
for i = reaper.TrackFX_GetCount( sel_track )-1, start_fx, -1 do
  reaper.TrackFX_Delete( sel_track, i )
end
fx_chunk = table.concat(captured_fx,"\n")

local cur_pos = reaper.GetCursorPosition()

local open_projects = {}
local idx = 0
while true do
  local reaproj = reaper.EnumProjects( idx )
  if not reaproj then break end
  open_projects[reaproj] = true
  idx = idx + 1
end

reaper.Main_OnCommand(41997, 0) -- Move tracks to subproject

local subproject
idx = 0
while true do
  local reaproj = reaper.EnumProjects( idx )
  if not reaproj then break end
  if not open_projects[reaproj] then
    subproject = reaproj
    break
  end
  idx = idx + 1
end

if not subproject then
  reaper.Undo_EndBlock2( orig_project, "Removed trackFX", 2 )
  return reaper.MB( "No sub-project was found", "Oops, something went wrong!", 0 )
end

if fx_chunk ~= "" then
  local orig_track = reaper.GetTrack( orig_project, orig_track_id-1 )
  local _, chunk = reaper.GetTrackStateChunk( orig_track, "", false )
  local new_chunk = chunk:sub( 1, -3 ) .. "<FXCHAIN\n" .. fx_chunk
  reaper.SetTrackStateChunk( orig_track, new_chunk, true )
end
reaper.Undo_EndBlock2( orig_project, "Moved track to Melodyne subproject", -1 )

local sub_track = reaper.GetTrack( subproject, 0 )
if not track_has_Melodyne_already then
  idx = reaper.TrackFX_AddByName( sub_track, "Melodyne", false, -1 )
end

reaper.SelectProjectInstance( subproject )
reaper.TrackFX_Show( sub_track, idx or 0, 3 )
reaper.SetEditCurPos2( subproject, cur_pos, true, false )

-- @description Cycle layout for track under mouse cursor (applies to other selected tracks if track selected)
-- @author amagalma
-- @version 1.0
-- @about
--   # Cycles between available layouts for the track under the mouse cursor (TCP or MCP)
--     If the track under the mouse cursor is selected, then the action applies to all selected tracks, else only to the track under the mouse cursor
--     Tooltip with the loaded layout name

----------------------------------------------------

local reaper = reaper

local track, context = reaper.BR_TrackAtMouseCursor()
-- check context (tcp or mcp wanted)
if context ~= 0 and context ~= 1 then
  return reaper.defer(function() end)
end

-- make tracks table
local tracks = {}
if reaper.IsTrackSelected( track ) then
  local sel_cnt = reaper.CountSelectedTracks( 0 )
  for i = 0, sel_cnt-1 do
    tracks[#tracks+1] = reaper.GetSelectedTrack( 0, i )
  end
else
  tracks[1] = track
end

-- Get all layouts into tables
local tcp, index_tcp = {}, {}
local i = 1
repeat
  local retval, name = reaper.ThemeLayout_GetLayout( "tcp", i )
  if name ~= "" then
    tcp[#tcp+1] = name
    index_tcp[name] = #tcp
  end
  i = i + 1
until not retval
local mcp, index_mcp = {}, {}
i = 1
repeat
  local retval, name = reaper.ThemeLayout_GetLayout( "mcp", i )
  if name ~= "" then
    mcp[#mcp+1] = name
    index_mcp[name] = #mcp
  end
  i = i + 1
until not retval

-- Cycle track layout
local layout, what
if context == 0 then -- tcp
  layout = ({reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", "", false )})[2]
  if layout == "" then
    layout = tcp[1]
  elseif layout == tcp[#tcp] then
    layout = ""
  else
    layout = tcp[index_tcp[layout]+1]
  end
  for i = 1, #tracks do
    reaper.GetSetMediaTrackInfo_String( tracks[i], "P_TCP_LAYOUT", layout, true )
  end
  what = "TCP layout"
elseif context == 1 then -- mcp
  layout = ({reaper.GetSetMediaTrackInfo_String( track, "P_MCP_LAYOUT", "", false )})[2]
  if layout == "" then
    layout = mcp[1]
  elseif layout == mcp[#mcp] then
    layout = ""
  else
    layout = mcp[index_mcp[layout]+1]
  end
  for i = 1, #tracks do
    reaper.GetSetMediaTrackInfo_String( tracks[i], "P_MCP_LAYOUT", layout, true )
  end
  what = "MCP layout"
end

-- Display tooltip
local x, y = reaper.GetMousePosition()
if layout == "" then layout = "Default" end
reaper.TrackCtl_SetToolTip( layout, x, y+20, true )

--Create undo
reaper.Undo_OnStateChangeEx( "Change " .. what , 1, -1 )

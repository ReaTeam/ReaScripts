-- @description Create tempo-map from markers (and remove markers)
-- @version 1.1
-- @author Mordi
-- @about
--  This script will take all of your markers and
--  create a tempo-map by detecting the tempo between
--  each one. It also removes the markers.
--
--  Made by Mordi, Nov 2017
--  Thanks to X-Raym for some snippets

reaper.PreventUIRefresh(1)

-- Begin undo-block
reaper.Undo_BeginBlock()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

-- Save current time-selection
init_start_timesel, init_end_timesel = reaper.GetSet_LoopTimeRange(0, 0, 0, 0, 0)
init_start_loop, init_end_loop = reaper.GetSet_LoopTimeRange(0, 1, 0, 0, 0)

-- Init
markerNum = reaper.CountProjectMarkers(0)
m_pos_prev = 0.0

-- Tempo-map
for i = 0, markerNum - 1, 1 do

  local m_retval, m_isrgn, m_pos, m_rgnend, m_name, m_indexnum = reaper.EnumProjectMarkers(i)
  
  if m_retval == 0 then
    break
  end
  
  if not m_isrgn then
  
    if i > 0 then
      reaper.GetSet_LoopTimeRange(1, 0, m_pos_prev, m_pos, 0)
      reaper.Main_OnCommand(40338, 0)
    end
  
    m_pos_prev = m_pos
  
  end
end

-- Remove markers
for i = markerNum, 1, -1 do
  local m_retval, m_isrgn, m_pos, m_rgnend, m_name, m_indexnum = reaper.EnumProjectMarkers(i)
  
  if not m_isrgn then
    reaper.DeleteProjectMarkerByIndex(0, m_indexnum)
  end
end

-- Restore time-selection
reaper.GetSet_LoopTimeRange(1, 0, init_start_timesel, init_end_timesel, 0)
reaper.GetSet_LoopTimeRange(1, 1, init_start_loop, init_end_loop, 0)

-- End undo-block
reaper.Undo_EndBlock("Create tempo-map from markers", 0)

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)

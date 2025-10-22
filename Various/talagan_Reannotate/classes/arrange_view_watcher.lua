-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

-- This class watches for changes in the arrange view.
local ArrangeViewWatcher = {}
ArrangeViewWatcher.__index = ArrangeViewWatcher

function ArrangeViewWatcher:new(cb)
  local instance = {}
  setmetatable(instance, self)
  instance:_initialize(cb)
  return instance
end

function ArrangeViewWatcher:_initialize(cb)
  self.pcount = nil
  self.astart = nil
  self.aend   = nil
  self.last_track_y = nil
  self.last_track_h = nil
  self.cb = cb
end

function ArrangeViewWatcher:tick()
  local npcount         = reaper.GetProjectStateChangeCount()
  local nastart, naend  = reaper.GetSet_ArrangeView2(0, false, 0, 0)

  local lt = reaper.GetTrack(0,reaper.CountTracks()-1)
  local ly = nil
  local lh = nil
  local lx = nil
  local lw = nil

  if lt then ly = reaper.GetMediaTrackInfo_Value(lt, "I_TCPY") end
  if lt then lh = reaper.GetMediaTrackInfo_Value(lt, "I_TCPH") end

  -- Also detect MCP changes.
  if lt then lx = reaper.GetMediaTrackInfo_Value(lt, "I_MCPX") end
  if lt then lw = reaper.GetMediaTrackInfo_Value(lt, "I_MCPW") end

  if  not (npcount == self.pcount) or
      not (nastart == self.astart) or
      not (naend == self.aend) or
      not (lh == self.last_track_h) or
      not (ly == self.last_track_y) or
      not (lx == self.last_track_x) or
      not (lw == self.last_track_w)  then
    if self.cb then self.cb() end
    self.pcount = npcount
    self.astart = nastart
    self.aend   = naend
    self.last_track_y  = ly
    self.last_track_h  = lh
    self.last_track_x  = lx
    self.last_track_w  = lw
    return true
  end

  return false
end

return ArrangeViewWatcher



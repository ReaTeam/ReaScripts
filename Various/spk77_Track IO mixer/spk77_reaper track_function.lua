--[[
   * Lua script for Cockos REAPER
   * Author: spk77
   * Author URI: http://forum.cockos.com/member.php?u=49553
   * Forum Thread URI: http://forum.cockos.com/showthread.php?t=168777
   * Licence: GPL v3
   * Version: 0.2015.12.18
	 * NoIndex: true
  ]]
	
--require "class"

--//////////////////
--// Track  class //
--//////////////////

local Reaper_track = class(
              function(tr, track_id, ...)
                tr.id = track_id
              end
              )
            

-- METHODS --

-- Get track name
function Reaper_track:get_name()
  if self.id == reaper.GetMasterTrack(0) then 
    self.name = "MASTER"
  else
    local retval, name = reaper.GetSetMediaTrackInfo_String(self.id, "P_NAME", "", false)
    if name == "" then 
      name = "Track " .. string.format("%d", reaper.GetMediaTrackInfo_Value(self.id, "IP_TRACKNUMBER"))
    end
    self.name = name
  end
  return self.name
end


-- Set track name
function Reaper_track:set_name(new_name)
  reaper.GetSetMediaTrackInfo_String(self.id, "P_NAME", new_name, true)
  self.name = new_name
end


-- Get track number
function Reaper_track:get_number()
  if self.id ~= reaper.GetMasterTrack(0) then
    self.number = reaper.GetMediaTrackInfo_Value(self.id, "IP_TRACKNUMBER")
  else
    self.number = 0
  end
  return self.number
end


-- Get track volume
function Reaper_track:get_vol()
  self.vol = ({reaper.GetTrackUIVolPan(self.id)})[2]
  return self.number
end
  


-- Get receives
function Reaper_track:get_receives()
  local tr_num_receives = reaper.GetTrackNumSends(self.id, -1)
  self.receives = {}
  -- populate "receives" table
  for i=1, tr_num_receives do
    local ret, vol, pan = reaper.GetTrackReceiveUIVolPan(self.id, i-1)
    local name = ({reaper.GetTrackReceiveName(self.id, i-1, "")})[2]
    local mute = ({reaper.GetTrackReceiveUIMute(self.id, i-1)})[2]
    self.receives[i] = {index = -i, vol = vol, pan = pan, mute = mute, name = name}
  end
  return self.receives
end


-- Get hardware outs
function Reaper_track:get_hw_outs()
  local tr_num_hw_outs = reaper.GetTrackNumSends(self.id, 1)
  self.hw_outs = {}
  -- populate "hw_outs" table
  for i=1, tr_num_hw_outs do
    local ret, vol, pan = reaper.GetTrackSendUIVolPan(self.id, i-1)
    local name = ({reaper.GetTrackSendName(self.id, i-1, "")})[2]
    local mute = ({reaper.GetTrackSendUIMute(self.id, i-1)})[2]
    self.hw_outs[i] = {index = i-1, vol = vol, pan = pan, mute = mute, name = name}
  end
  return self.hw_outs
end


-- Get sends
function Reaper_track:get_sends()
  local tr_num_hw_outs = reaper.GetTrackNumSends(self.id, 1)
  local tr_num_sends = reaper.GetTrackNumSends(self.id, 0)
  self.sends = {}
   -- populate "sends" table
  for i=1, tr_num_sends do
    local ret, vol, pan = reaper.GetTrackSendUIVolPan(self.id, tr_num_hw_outs + i - 1)
    local name = ({reaper.GetTrackSendName(self.id, tr_num_hw_outs + i - 1, "")})[2]
    local mute = ({reaper.GetTrackSendUIMute(self.id, tr_num_hw_outs + i - 1)})[2]
    self.sends[i] = {index = tr_num_hw_outs + i - 1, vol = vol, pan = pan, mute = mute, name = name}
  end
  return self.sends
end


-- Get routing (receives, sends, hardware outs)
function Reaper_track:get_routing()
  local t = {}
  
  local tr_num_receives = reaper.GetTrackNumSends(self.id, -1)
  if tr_num_receives > 0 then 
    for i=1, tr_num_receives do
      local ret, vol, pan = reaper.GetTrackReceiveUIVolPan(self.id, i-1)
      local name = ({reaper.GetTrackReceiveName(self.id, i-1, "")})[2]
      local mute = ({reaper.GetTrackReceiveUIMute(self.id, i-1)})[2]
      t[i] = {index = -i, vol = vol, pan = pan, mute = mute, name = name}
    end
  end
  
  local tr_num_hw_outs = reaper.GetTrackNumSends(self.id, 1)
  for i=1, tr_num_hw_outs do
    local ret, vol, pan = reaper.GetTrackSendUIVolPan(self.id, i-1)
    local name = ({reaper.GetTrackSendName(self.id, i-1, "")})[2]
    local mute = ({reaper.GetTrackSendUIMute(self.id, i-1)})[2]
    t[i+tr_num_receives] = {index = i-1, vol = vol, pan = pan, mute = mute, name = name}
  end

  local tr_num_sends = reaper.GetTrackNumSends(self.id, 0)
  for i=1, tr_num_sends do
    local ret, vol, pan = reaper.GetTrackSendUIVolPan(self.id, tr_num_hw_outs + i - 1)
    local name = ({reaper.GetTrackSendName(self.id, tr_num_hw_outs + i - 1, "")})[2]
    local mute = ({reaper.GetTrackSendUIMute(self.id, tr_num_hw_outs + i - 1)})[2]
    t[i+tr_num_receives+tr_num_hw_outs] = {index = tr_num_hw_outs + i - 1, vol = vol, pan = pan, mute = mute, name = name}
  end
    
  return t
end


-- Count receives
function Reaper_track:get_num_receives()
  return reaper.GetTrackNumSends(self.id, -1)
end


-- Count hardware outs
function Reaper_track:get_num_hw_outs()
  return reaper.GetTrackNumSends(self.id, 1)
end


-- Count sends
function Reaper_track:get_num_sends()
  return reaper.GetTrackNumSends(self.id, 0)
end


-- Count receives, sends and hardware outs
function Reaper_track:get_num_input_outputs()
  return self:get_num_receives() + self:get_num_hw_outs() + self:get_num_sends()
end



function Reaper_track:make_track_table()
  local t = {}
 
  if self.id ~= reaper.GetMasterTrack(0) then
    t.name = ({reaper.GetSetMediaTrackInfo_String(self.id, "P_NAME", "", 0)})[2] -- get second value from return values
    --_, t.name = reaper.GetSetMediaTrackInfo_String(track_id, "P_NAME", "", 0)
    t.number = reaper.GetMediaTrackInfo_Value(self.id, "IP_TRACKNUMBER")
  else
    t.name = "MASTER"
    t.number = 0
  end
 
  t.receives, t.sends, t.hw_outs = get_track_routing(project, track_id)
  t.num_ins_outs = (#t.receives + #t.hw_outs + #t.sends) -- count all inputs and outputs
  return t
end


return Reaper_track


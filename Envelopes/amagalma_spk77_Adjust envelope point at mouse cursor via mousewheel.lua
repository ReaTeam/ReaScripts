--[[
ReaScript name: amagalma_spk77_Adjust envelope point at mouse cursor via mousewheel.lua
Version: 1.01
Author: amagalma & spk77
About:
  # Adjusts any envelope point under mouse cursor via the mousewheel (action must be assigned to modifier key(s) + mousewheel)
    + Based on "spk77_Adjust volume envelope point at mouse cursor via mousewheel.lua"
    + Step size can be set inside the script
    + Can work with any envelope under the mouse or with selected envelope only (preference set inside the script)
    + Tooltip that shows current value even if mouse is not over point
    + Smart Undo point creation (only one undo point is created when the modifier key is released)
    + Undo points are created per envelope (in case more than one envelopes are changed while modifier key is pressed)
    + Requires JS_ReaScriptAPI and SWS (if not installed, user is prompted to have a browser opened to the relevant web pages)

Changelog:
 * v1.01(29-01-2020)
  + improved naming of undo points
  + worked around ECP not updating the values
--]]


-------------------
-- User settings --
-------------------


-- Adjustment behavior
local adj_sel_env = false   -- true:  envelope has to be selected

-- Volume envelope step size
-- (User configurable "dB_steps": see "set_envelope_point" -function)

-- Pan envelope step size
local pan_env_step = 0.01 -- 200 steps (-1 to 1)

-- Width envelope step size
local width_env_step = 0.01 -- 200 steps (-1 to 1)

-- Mute envelope step size
local mute_env_step = 1 -- 2 steps (0 to 1)

-- Playrate envelope step size
local playrate_env_step = 0.05 -- = 5% difference in speed

-- Step count for all other envelopes
local all_steps = 200


----------------------------------------------------------------------


local reaper = reaper

local dbg = false -- Get Debug messages


----------------------------------------------------------------------


local os_open = 'start "" "'
if string.match(reaper.GetOS(), "OSX" ) == "OSX" then
  os_open = 'open "" "'
end

-- Check if JS_ReaScriptAPI is installed
if not reaper.APIExists("JS_ReaScriptAPI_Version") then
  local answer = reaper.MB( "You have to install JS_ReaScriptAPI for this script to work. Would you like to open the relative web page in your browser?", "JS_ReaScriptAPI not installed", 4 )
  if answer == 6 then
    local url = "https://forum.cockos.com/showthread.php?t=212174"
    os.execute(os_open .. url .. '"')
  end
  return
end

-- Check if SWS is installed
if not reaper.APIExists("CF_GetSWSVersion") then
  local answer = reaper.MB( "You have to install SWS extension for this script to work. Would you like to open the relative web page in your browser?", "SWS extension not installed", 4 )
  if answer == 6 then
    local url = "https://www.sws-extension.org/index.php#download_featured"
    os.execute(os_open .. url .. '"')
  end
  return
end


----------------------------------------------------------------------


local dB_step = 0.2

local max = math.max
local abs = math.abs
local exp = math.exp
local log = math.log
local floor = math.floor
local ceil = math.ceil

function msg(m)
  if dbg then
    reaper.ShowConsoleMsg(tostring(m) .. "\n")
  end
end

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    if num >= 0 then return floor(num * mult + 0.5) / mult
    else return ceil(num * mult - 0.5) / mult end
end


-- Justin's functions ------------------------------------------------


function VAL2DB(x)
  if x < 0.0000000298023223876953125 then 
    x = -150
  else
    x = max(-150, log(x)* 8.6858896380650365530225783783321)
  end
  return x
end

function DB2VAL(x)
  return exp(x*0.11512925464970228420089957273422)
end


----------------------------------------------------------------------


-- Set new value for an envelope point

function set_envelope_point(env_prop_table, m_wheel_delta)
  local e = env_prop_table
  local env = e.pointer
  local min_val = e.min_val
  local max_val = e.max_val
  local br_env = reaper.BR_EnvAlloc(env, true)
  local pos = reaper.BR_PositionAtMouseCursor(false)
  local p_index = reaper.BR_EnvFind(br_env, pos, 10)
  local get_point_ret, position, value, shape, selected, bezier = reaper.BR_EnvGetPoint(br_env, p_index)
  reaper.BR_EnvFree(br_env, false)
  
  local x, y = reaper.GetMousePosition() -- needed for tooltips
  local ToolTip = "Envelope not visible"
  
  function Range(value) -- keep value inside maximum and minumum value
    if value < e.min_val then
      value = e.min_val
    elseif value > e.max_val then
      value = e.max_val
    end
    return value
  end
  
  -- Volume envelopes
  if e.name == "Volume" or e.name == "Volume (Pre-FX)" or e.name == "Trim Volume" then
    local dB_val = VAL2DB(abs(value))
    -- Change the "dB_step" here
    if     dB_val < -90 then dB_step = 5     -- < -90 dB
    elseif dB_val < -60 then dB_step = 3     -- from -90 to -60 dB
    elseif dB_val < -45 then dB_step = 2     -- from -60 to -45 dB
    elseif dB_val < -30 then dB_step = 1.5   -- from -45 to -30 dB
    elseif dB_val < -18 then dB_step = 1     -- from -30 to -18 dB
    elseif dB_val < 24  then dB_step = 0.2   -- from -18 to 24 dB
    end  
    if m_wheel_delta < 0 then 
      dB_step = -dB_step
    end
    value = DB2VAL(dB_val + dB_step)
    ToolTip = tostring(round(VAL2DB(value), 1) .. "dB")
    
  -- Pan envelopes
  elseif e.name == "Pan" or e.name == "Pan (Pre-FX)" then
    value = Range(round(value + (m_wheel_delta > 0 and pan_env_step or -pan_env_step), 2))
    local vl = string.match(value*100, "%d%d?%d?")
    ToolTip = value > 0 and vl .. "%L" or ((value > -0.009 and value < 0.009 ) and "center" or vl .. "%R")
    
  -- Width envelopes 
  elseif e.name == "Width" or e.name == "Width (Pre-FX)" then
    value = Range(round(value + (m_wheel_delta > 0 and width_env_step or -width_env_step), 3))
    local vl = string.match(value*100, "-?%d%d?%d?")
    ToolTip = value > 0 and vl .. "%" or ((value > -0.009 and value < 0.009 ) and "mono" or vl .. "%")
  
  -- Mute envelope
  elseif e.name == "Mute" then
    value = Range(value + (m_wheel_delta > 0 and mute_env_step or -mute_env_step))
    ToolTip = value > 0 and "unmuted" or "muted"
  
  -- Tempo Map envelope
  elseif e.name == "Tempo map" then
    local sign = 1
    if m_wheel_delta < 0 then 
      sign = -1
    end
    if value < 65 then
      value = Range(value + 0.5*sign)
    elseif value >= 65 and value < 140 then
      value = Range(value + 1*sign)
    else
      value = Range(value + 2*sign)
    end
    ToolTip = value .. "bpm"
  
  -- Playrate envelope
  elseif e.name == "Playrate" then
    value = Range(value + (m_wheel_delta > 0 and playrate_env_step or -playrate_env_step))
    --snap near 100%
    if value < 1.01 and value > 0.99 then value = 1 end
    local pl = (value*100)
    if pl == 100 then pl = "100% (normal speed)"
    elseif pl <100 then pl = string.match(pl, "%d%d%d?") .. "% (slower)"
    else pl = string.match(pl, "%d%d%d?") .. "% (faster)"
    end
    ToolTip = pl
    
  -- All other envelopes
  else
    local step = (e.max_val - e.min_val)/all_steps
    if m_wheel_delta < 0 then 
     step = -step
    end
    value = Range(value + step)
    ToolTip = value
  end
  
  if e.is_fader_scaling then
    value = reaper.ScaleToEnvelopeMode(1, value)
  end
  
  -- Adjust a point only if its envelope is visible (mainly for Tempo Map)
  if e.visible then 
    reaper.SetEnvelopePoint(env, p_index, nil, value, nil, nil, nil, true)
    reaper.UpdateTimeline()
    reaper.TrackCtl_SetToolTip( ToolTip, x, y - 60, true )
    msg("m_wheel_delta: " .. m_wheel_delta)
    msg("set point to value: " .. value)
    -- Unfortunately, this is needed in order to update the ECP
    local _, chunk = reaper.GetEnvelopeStateChunk( env, "", true )
    reaper.SetEnvelopeStateChunk( env, chunk, true )
    return true
  else
    return false
  end
end


----------------------------------------------------------------------


-- Get "envelope properties" table 

function get_env_properties(env)
  local envelope = {}
  if env ~= nil then
    local br_env = reaper.BR_EnvAlloc(env, true)
    local active, visible, armed, in_lane, lane_height, default_shape, 
          min_val, max_val, center_val, env_type, is_fader_scaling
          = reaper.BR_EnvGetProperties(br_env, false, false, false, false, 0, 0, 0, 0, 0, 0, false)
    reaper.BR_EnvFree(br_env, false)
    
    local env_name = ({reaper.GetEnvelopeName(env, "")})[2]
    if env_name == "Volume" or env_name == "Volume (Pre-FX)" then
      max_val = reaper.SNM_GetIntConfigVar("volenvrange", -1)
      if max_val ~= -1 then
        if max_val == 1 then 
          max_val = 1.0
        elseif max_val == 0 then 
          max_val = 2.0
        elseif max_val == 4 then 
          max_val = 4.0
        else 
          max_val = 16.0
        end
      end 
    end
    
    -- Store values to "envelope" table
    envelope.pointer = env
    envelope.active = active
    envelope.visible = visible
    envelope.armed = armed
    envelope.in_lane = in_lane
    envelope.lane_height = lane_height
    envelope.default_shape = default_shape
    envelope.min_val = min_val
    envelope.max_val = max_val
    envelope.center_val = center_val
    envelope.is_fader_scaling = is_fader_scaling
    envelope.type = env_type
    envelope.name = env_name
  end
  return envelope
end


----------------------------------------------------------------------
-- Main --
----------------------------------------------------------------------


-- check which modifiers triggered the script, so that it can be checked if they are still being pressed
-- Looks for Cntrl, Shift, Alt and Win keys
local modifiers
for i = 60, 0, -4  do
  modifiers = reaper.JS_Mouse_GetState(i)
  if init ~= 0 then break end
end

-- check for first envelope
local master = reaper.GetMasterTrack( 0 )
local window, segment, details = reaper.BR_GetMouseCursorContext()
msg("window: " .. window .. "  segment" .. segment .. "  details: " .. details)
local first_env -- This is needed for undo points to be created if you move from one envelope to other while having keys pressed
if adj_sel_env then
  first_env = reaper.GetSelectedEnvelope(0)
else
  first_env = reaper.BR_GetMouseCursorContext_Envelope()
end
if first_env == nil then -- no envelope found or this can happen if the mouse is not directly over a tempo envelope point
  local track, context = reaper.BR_TrackAtMouseCursor()
  if context == 2 and track == master then
    first_env = reaper.GetTrackEnvelopeByName( master, "Tempo map" )
    -- check if Tempo Map is visible / do not mess with hidden envelope!!
    local first_br_env = reaper.BR_EnvAlloc(first_env, true)
    local first_visible = ({reaper.BR_EnvGetProperties(first_br_env, false, false, false, false, 0, 0, 0, 0, 0, 0, false)})[2]
    reaper.BR_EnvFree(first_br_env, false)
    if not first_visible then
      first_env = nil
    end
  end
end

if not first_env then
  msg("no envelope could be found1 - no undo point")
  return
  reaper.defer(function() end)
end

-- Do the stuff
local tr_Name
local Name = ({reaper.GetEnvelopeName(first_env, "")})[2]
local UNDO = false
function Main()
  local windowOut, segment, details = reaper.BR_GetMouseCursorContext()
  local Track = reaper.BR_GetMouseCursorContext_Track()
  tr_Name = Track and ({reaper.GetTrackName( Track )})[2] or "-"
  local env
  if adj_sel_env then
    env = reaper.GetSelectedEnvelope(0)
  else
    env = reaper.BR_GetMouseCursorContext_Envelope()
  end
  if env == nil then -- this can happen if the mouse is not directly over a tempo envelope point
    local track, context = reaper.BR_TrackAtMouseCursor()
    if context == 2 and track == master then
      env = reaper.GetTrackEnvelopeByName( master, "Tempo map" )
    else -- no envelope could be found
      if UNDO == false then
        msg("no envelope could be found2 - no undo point")
        return
        reaper.defer(function() end)
      else -- create undo point
        if UNDO then
          reaper.Undo_OnStateChangeEx(tr_Name .. ": " .. Name .. " adjust via mousewheel", 1, -1)
          msg("Undo created for " .. tr_Name .. ": " .. Name .. " envelope (1)" )
          return
        end
      end
    end
  end
  
  -- check if modifier key(s) is/are being pressed down
  if reaper.JS_Mouse_GetState(modifiers) == modifiers then
    -- check if we are still on the same env. If not create Undo point
    if env ~= first_env then
      reaper.Undo_OnStateChangeEx(tr_Name .. ": " .. Name .. " adjust via mousewheel", 1, -1)
      msg("Undo created for " .. tr_Name .. ": " .. Name .. " envelope (2)")
      first_env = env
    end
    local m_wheel_delta = ({reaper.get_action_context()})[7]
    if m_wheel_delta ~= 0 then
      env_properties = get_env_properties(env)
      Name = env_properties.name
      UNDO = set_envelope_point(env_properties, m_wheel_delta)
    end
    reaper.defer(Main)
  else -- key has been released
    if UNDO then
      reaper.Undo_OnStateChangeEx(tr_Name .. ": " .. Name .. " adjust via mousewheel", 1, -1)
      msg("Undo created for " .. tr_Name .. ": " .. Name .. " envelope (3)")
      return
    else
      msg("no changes - no undo point")
      return reaper.defer(function() end)
    end
  end
end


Main()

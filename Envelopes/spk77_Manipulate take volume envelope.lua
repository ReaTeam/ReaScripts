/*
   * ReaScript Name: Adjust volume envelope point at mouse cursor via mousewheel
   * EEL script for Cockos REAPER
   * Author: spk77
   * Author URI: http://forum.cockos.com/member.php?u=49553
   * Licence: GPL v3
   * Version: 1.0
   */




local detect_by_rms = true -- (false = detect by max peak in current RMS window)
local env_point_value_is_rms = true
dbg = true

 
-- Mouse table --------------------------------------------
 mouse = {  
                    -- Constants
                    LB = 1,
                    RB = 2,
                    CTRL = 4,
                    SHIFT = 8,
                    ALT = 16,
                    
                    -- "cap" function
                    cap = function (mask)
                            if mask == nil then
                              return gfx.mouse_cap end
                            return gfx.mouse_cap&mask == mask
                          end,
                            
                    --lb_down = false,
                    --lb_up = true,
                    uptime = 0,
                    moving = false,
                    last_state = 0,
                    
                    last_x = -1, last_y = -1,
                   
                    dx = 0,
                    dy = 0,
                    
                    ox_l = 0, oy_l = 0,    -- left click positions
                    ox_r = 0, oy_r = 0,    -- right click positions
                    capcnt = 0,
                    last_LMB_state = false
                 }
last_RMB_state = false             
-- ///////////////////////////////////////////////////////////////////////

-- source_rms_t = {pos = {}, rms = {}}
rms_window_size = 0.010

local open_threshold_dB = {}
--last_open_threshold_dB_val = open_threshold_dB.val
local close_threshold_dB = {}
local hold_sl = {}
local ng_gain_sl = {}
local gain_db = {}

local take_source_sample_rate
local samples_per_channel
local channel_data = {}

local floor = math.floor
local abs = math.abs
local log = math.log
local log10 = function(x) return log(x,10) end
local amp_to_dB = function(x) return 20*log10(x) end
local dB_to_amp = function(x) return 10^(x/20) end


local info_text = ""
local info_text_x
local info_text_y
local info_text_a = 1

current_env_points = {}

gfx.init("Create/manipulate take volume envelope", 440, 280)
gfx.setfont(1,"Arial", 15)
gfx.clear = 3355443

 gui = {}
gui.error_msg_x = 10
gui.error_msg_y = 10
gui.help_text_x = 10
gui.help_text_y = gui.error_msg_y + gfx.texth
--gui.last_touched_slider = nil

--gui.last_touched_slider = {}

local text_h = gfx.texth
local info_text_x = 10
local info_text_y = 10+text_h


function get_script_path()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  return script_path
end

function msg(m)
  if dbg then
    reaper.ShowConsoleMsg(tostring(m) .. "\n")
  end
end

-- Initialize variables ---
local array_created = false
--local comp_sl = {}
local mx, my = -1, -1
local e_i = {}
local e_v = {}
envelope = {}
local add_undo_point = false

local last_comp_sl_val = -1
local last_open_threshold_dB_val = -1000
local last_points_per_second_val = -1

local sel_points = 0
--local sum = 0
local average = 0
local c = 1
---------------------------
-- get "script path"
local script_path = get_script_path()
--msg(script_path)

-- modify "package.path"
package.path = package.path .. ";" .. script_path .. "?.lua"
--msg(package.path)

-- Import files ("classes", functions etc.)-----------------
require "class" -- import "base class"
-- mouse = require "mouse"

local Slider = require "slider class" -- import "slider class"
-- Set slider drag sensitivity
Slider.drag_sensitivity = 0.5 -- slider moves 50 pixels if mouse moves 100 pixels

local Menu = require "spk77_menu class_function"

--//////////////////
--// Button class //
--//////////////////

local Button = class(
                      function(btn,x1,y1,w,h,state_count,state,visual_state,lbl,help_text)
                        btn.x1 = x1
                        btn.y1 = y1
                        btn.w = w
                        btn.h = h
                        btn.x2 = x1+w
                        btn.y2 = y1+h
                        btn.state = state
                        btn.state_count = state_count - 1
                        btn.vis_state = visual_state
                        btn.label = lbl
                        btn.help_text = help_text
                        btn.__mouse_state = 0
                        btn.label_w, btn.label_h = gfx.measurestr(btn.label)
                        btn.__state_changing = false
                        btn.r = 0
                        btn.g = 1
                        btn.b = 0
                        btn.a = 0.2
                        btn.lbl_r = 0
                        btn.lbl_g = 1
                        btn.lbl_b = 1
                        btn.lbl_a = 1
                      end
                    )

-- get current state
function Button:get_state()
   return self.state
end

-- cycle through states
function Button:set_next_state()
  if self.state <= self.state_count - 1 then
    self.state = self.state + 1
  else self.state = 0 
  end
end

-- get "button label text" w and h
function Button:measure_lbl()
  self.label_w, self.label_h = gfx.measurestr(self.label)
end

-- returns true if "mouse on element"
function Button:__is_mouse_on()
  return(gfx.mouse_x > self.x1 and gfx.mouse_x < self.x2 and gfx.mouse_y > self.y1 and gfx.mouse_y < self.y2)
end

function Button:__lmb_down()
  return(mouse.last_LMB_state == false and gfx.mouse_cap & 1 == 1 and self.__mouse_state == 0)
  --return(last_mouse_state == 0 and self.mouse_state == 1)
end

function Button:set_help_text()
  if self.help_text == "" then return false end
    gfx.set(1,1,1,1)
    gfx.x = 10
    gfx.y = 10
    gfx.printf(self.help_text)
end

function Button:set_color(r,g,b,a)
  self.r = r
  self.g = g
  self.b = b
  self.a = a
end

function Button:set_label_color(r,g,b,a)
  self.lbl_r = r
  self.lbl_g = g
  self.lbl_b = b
  self.lbl_a = a
end


function Button:draw_label()
  -- Draw button label
  if self.label ~= "" then
    --if self.__mouse_state == 1 then gfx.setfont(1,"Arial", 10) end
    gfx.x = self.x1 + math.floor(0.5*self.w - 0.5 * self.label_w) -- center the label
    gfx.y = self.y1 + 0.5*self.h - 0.5*gfx.texth
    
    --gfx.a = self.lbl_a
    gfx.set(self.lbl_r, self.lbl_g, self.lbl_b, self.lbl_a)
    if self.__mouse_state == 1 then
      --gfx.x = gfx.x + 1
      ----gfx.y = gfx.y + 1
      gfx.a = self.lbl_a*0.8
    elseif self.__mouse_state == 0 then
      --gfx.a = self.lbl_a
    end
  
    --gfx.set(self.lbl_r,self.lbl_g,self.lbl_b,self.lbl_a)
    gfx.printf(self.label)
    if self.__mouse_state == 1 then 
     ---- gfx.y = gfx.y - 1
    end
  end
end


-- Draw element (+ mouse handling)
function Button:draw()
  gfx.set(self.r,self.g,self.b, self.a)
  gfx.rect(self.x1, self.y1, self.w, self.h,0)
  
  
  -- lmb released (and was clicked on element)
  if mouse.last_LMB_state == false and self.__mouse_state == 1 then self.__mouse_state = 0 end
  --if mouse.last_LMB_state == false and self.__state_changing == true then self.__state_changing = false end
   
  -- Mouse is on element -----------------------
  if self:__is_mouse_on() then
    if self.__mouse_state == 1 or mouse.last_LMB_state == false then
      self:set_help_text() -- Draw info/help text (if self.help_text is not "")
    end
    if mouse.last_LMB_state == false then
      self.a=self.a+0.08
      if self.a > 0.9 then self.a = 0.9 end
    end
    if self.__mouse_state == 0 or self.__state_changing then
    
      
    end
    -- Left mouse btn is pressed on button
    if self:__lmb_down() then 
      self.__mouse_state = 1
      last_clicked = self
      if self.__state_changing == false then
        self.__state_changing = true
      end
    end
    
    
    
    if mouse.last_LMB_state == false and gfx.mouse_cap & 1 == 0 and self.__state_changing == true then
      if self.onClick ~= nil then self:onClick()
        self.__state_changing = false
      end
    end
  
  -- Mouse is not on element -----------------------
  else
    if self.__mouse_state == 0 then
      self.a=self.a-0.08
      if self.a < 0.5 then self.a = 0.5 end
    end
    if mouse.last_LMB_state == false and self.__state_changing == true then
      self.__state_changing = false
    end
  end
  
  --self.a = 0.2
  
  if self.__mouse_state == 1 or self.vis_state == 1 or self.__state_changing then
    gfx.set(self.r,self.g,self.b, self.a)
    gfx.rect(self.x1+1, self.y1+1, self.w-2, self.h-2,0)
    

  -- Button is not pressed
  elseif not self.__state_changing or self.vis_state == 0 or self.__mouse_state == 0 then
  end
  --aas=gfx.a
  self:draw_label()
end


--//////////
--// Init //
--//////////

function init()
  
  array_created = false
  
  -- Button function args: x1,y1,w,h,state_count,state,visual_state,lbl,help_text
  --[[
  --create_btn = Button(10,text_h*4,80,20,2,0,0,"Create", "Analyze take and create 'take volume envelope' points")
  create_btn.onClick = function ()
                       --reaper.Main_OnCommand(40333, 0)
                       --update = false
                      --if update == false then 
                       get_source_properties() --end
                     end
  --]]
  
  analyze_btn = Button(10,text_h*4,80,20,2,0,0,"Analyze", "Analyze selected take")
  analyze_btn.onClick = function ()
                          analyze_take_source()
                        end
                        
  inv_btn = Button(10,text_h*5+15,80,20,2,0,0,"Invert", "Invert selected points")
  inv_btn.onClick = function ()
                      reaper.Main_OnCommand(40334, 0) -- Invert envelope points
                    end
                    
  toggle_env_btn = Button(10,text_h*6+30,80,20,2,0,0,"Toggle env", "Toggle take volume envelope")
  toggle_env_btn.onClick = function ()
                             reaper.Main_OnCommand(40693, 0) -- Toggle take volume envelope
                           end
  

  analyze_btn:set_color(0.8,1,1,0.5)
  analyze_btn:set_label_color(1,1,1,1)
  --create_btn:set_color(1,0,1,0.5)
  inv_btn:set_color(1,0,1,0.5)
  toggle_env_btn:set_color(1,0,1,0.5)
  
  --create_btn:set_label_color(1,1,1,1)
  inv_btn:set_label_color(1,1,1,1)
  toggle_env_btn:set_label_color(1,1,1,1)
  
  
  --update = true
  
  ------------------------
  -- Initialize sliders --
  -- (see slider class.lua)
  -- Slider function args: x1, y1, w, h, val, default_val, min_val, max_val, lbl, help_text, id)
  ----------------------------------------------------------------------------------------------
  
  
  
  open_threshold_dB = Slider(120, text_h*4, 300, 15, -40, -40, -100, 0, "Noise gate open threshold (dB)", "Noise gate opens when above this threshold (dB)", "open_threshold_dB")
  open_threshold_dB:set_hit_zone()
  last_open_threshold_dB_val = open_threshold_dB.val
  
  close_threshold_dB = Slider(120, open_threshold_dB.y2+5, 300, 15, -50, -50, -100, 0, "Noise gate close threshold (dB)", "Noise gate closes when below this threshold (dB)", "close_threshold_dB")
  close_threshold_dB:set_hit_zone()
  
  hold_sl = Slider(120, close_threshold_dB.y2+5, 300, 15, 200, 200, 0, 2000, "Hold (ms)", "Minimum gate open time", "hold")
  hold_sl:set_hit_zone()
  
  ng_floor_sl = Slider(120, hold_sl.y2+5, 300, 15, 0, 0, 0, 1, "Noise gate floor", "", "ng_floor_sl")
  ng_floor_sl:set_hit_zone()
  
-- Compressor -- 
  points_per_second = Slider(120, ng_floor_sl.y2 + 2*gfx.texth, 300, 15, 0, 40, 0, 100, "Points per second", "Points per second (0 = noise gate only)", "points_per_second")
  points_per_second:set_hit_zone() -- (if no arguments are passed: slider hitzone = slider area)
  points_per_second:set_fg_color(0.2,1,0.2,1) 
  last_points_per_second_val = points_per_second.val
  --points_per_second:show_background(false)
  --points_per_second:show_hitzone(true)
   

  comp_sl = Slider(120, points_per_second.y2+5, 300, 15, 1.2, 1.2, 1, 5, "Ratio", "Ratio", "comp_sl")                            
  comp_sl:set_hit_zone()
  comp_sl:set_fg_color(0.2,1,0.2,1)                    
  last_comp_sl_val = comp_sl.val
  
  comp_threshold_sl = Slider(120, comp_sl.y2+5, 300, 15, -10, -100, -100, 0, "Threshold", "", "comp_threshold_sl")                            
  comp_threshold_sl:set_hit_zone()
  comp_threshold_sl:set_fg_color(0.2,1,0.2,1)                    
  last_comp_threshold_sl = comp_threshold_sl.val
  
  
  gain_dB_sl = Slider(120, comp_threshold_sl.y2+20, 300, 15, 0.0, 0.0, -6, 12, "Gain (dB)", "'Makeup gain' for envelope points above threshold", "gain_dB_sl")
  gain_dB_sl:set_hit_zone()
  gain_dB_sl:set_fg_color(0.8,0,0.7,0.8)
end




function get_and_show_take_envelope(take, envelope_name)
  local env = reaper.GetTakeEnvelopeByName(take, envelope_name)
  if env == nil then 
    if     envelope_name == "Volume" then reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_TAKEENV1"), 0)     -- show take volume envelope
    elseif envelope_name == "Pan" then reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_TAKEENV2"), 0)    -- show take pan envelope
    elseif envelope_name == "Mute" then reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_TAKEENV3"), 0)   -- show take mute envelope
    elseif envelope_name == "Pitch" then reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_TAKEENV10"), 0) -- show take pitch envelope
    end  
    env = reaper.GetTakeEnvelopeByName(take, envelope_name)
  end
  return env
end


function get_source_properties()
  local t = {}
  local time_sel_start, time_sel_end = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  if time_sel_start == time_sel_end then
    --**info_text = "No time selection set"
    --**return
  end
  
  item = reaper.GetSelectedMediaItem(0, 0)
  if item == nil then
    info_text = "Please select one item"
    return
  end
  take = reaper.GetActiveTake(item)
  if take == nil then
    info_text = "Empty item selected?"
    return
  end
  
  --[[
  --playrate =reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE") 
  if reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE") ~= 1.0 then
    info_text = "Take playrate has to be '1.0'"
    return
  end
  ]]
  
  if reaper.TakeIsMIDI(take) then
    info_text = "Please select an audio take"
    return
  end
    
  take_pcm_source = reaper.GetMediaItemTake_Source(take)

  num_channels = reaper.GetMediaSourceNumChannels(take_pcm_source)
  if num_channels > 1 then
    info_text = "Please select a mono take (multichannel take sources are not supported)"
    return
  end
  
  sample_rate = reaper.GetMediaSourceSampleRate(take_pcm_source)
  
  item_pos =reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  item_end = item_pos+item_length
  
  -- Time selection outside selected item
  if time_sel_start > item_end or time_sel_end < item_pos then
    --**info_text = "Time selection is not over selected item"
    --**return
  end
  
  -- Time selection is partially over selected item
  --**if time_sel_start < item_pos then time_sel_start = item_pos end
  --**if time_sel_end > item_end then time_sel_end = item_end end

  t.time_sel = {}
  t.time_sel.start = time_sel_start
  t.time_sel.end_pos = time_sel_end
  
  t.item = {}
  t.item.id = item
  t.item.pos = item_pos
  t.item.len = item_length
  t.item.end_pos = item_end
  
  t.take = {}
  t.take.id = take
  t.take.start_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  t.take.pcm = reaper.GetMediaItemTake_Source(take)
  t.take.sample_rate = reaper.GetMediaSourceSampleRate(take_pcm_source)
  t.take.num_channels = reaper.GetMediaSourceNumChannels(take_pcm_source)
  
  t.take.aa = {}
  t.take.aa.o = reaper.CreateTakeAudioAccessor(take)
  t.take.aa.start = reaper.GetAudioAccessorStartTime(t.take.aa.o)
  t.take.aa.end_pos = reaper.GetAudioAccessorEndTime(t.take.aa.o)
  t.take.aa.hash = reaper.GetAudioAccessorHash(t.take.aa.o, "")
  
  return t
--**get_samples_create_points(take, t)

end





function adjust_params(slider_id)
  if #channel_data == 0 then
    info_text = "Select item and press 'Analyze' button"
    return
  end
  if slider_id == "points_per_second" and last_points_per_second_val == points_per_second.val then
   --msg(points_per_second.val)
   -- return
  elseif slider_id == "open_threshold_dB" and last_open_threshold_dB_val == open_threshold_dB.val then
   --msg(open_threshold_dB.val)
    return
  
  elseif slider_id == "close_threshold_dB" and last_close_threshold_dB_val == close_threshold_dB.val then
   --msg(close_threshold_dB.val)
    return
  
  elseif slider_id == "hold" and last_hold_val == hold_sl.val then
   --msg(hold_sl.val)
    return

  elseif slider_id == "ng_floor_sl" and last_ng_floor_sl_val == ng_floor_sl.val then
   --msg(ng_gain_sl.val)
    return
  elseif slider_id == "gain_dB_sl" and last_gain_dB_sl_val == gain_dB_sl.val then
   --msg(ng_gain_sl.val)
    return
  elseif slider_id == "comp_sl" and last_comp_sl_val == comp_sl.val then
    return
  elseif slider_id == "comp_threshold_sl" and last_comp_threshold_sl == comp_threshold_sl.val then
    return 
  end
  
  sp = get_source_properties()
  if sp == nil then
    return
  end
  
  env = get_and_show_take_envelope(take, "Volume")
  reaper.SetCursorContext(2, env)
  
  local item = reaper.GetSelectedMediaItem(0, 0)
  if item == nil then
    info_text = "Please select one item"
    return
  end
  local take = reaper.GetActiveTake(item)
    if take == nil then
    info_text = "Empty item selected?"
    return
  end
  item_pos =reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  item_length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  item_end = item_pos+item_length
  
  local time_sel_start, time_sel_end = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  if time_sel_start == time_sel_end then
    --**info_text = "No time selection set"
    --**return
  end
  
  
  --reaper.DeleteEnvelopePointRange(env, sp.time_sel.start-sp.item.pos, sp.time_sel.end_pos-sp.item.pos)
  reaper.DeleteEnvelopePointRange(env, 0, item_length)
  --**reaper.DeleteEnvelopePointRange(env, sp.take.start_offset, item_length)
  
  sample_rate = sp.take.sample_rate
  hold_start = 0
  last_gate_close_pos = -1
  last_gate_open_pos = -1
  hold = hold_sl.val/1000
  gate_open = false
  last_env_point_pos = 0
  last_env_point_pos2 = 0
  local offs = 0
  --local ng_floor
  ng_floor = 20*log10(ng_floor_sl.val) -- ng_floor_sl.val range: 0 to 1
  ng_floor = 10^(ng_floor / 20)
  open_threshold = 10^(open_threshold_dB.val / 20)
  
  local close_threshold = 10^(close_threshold_dB.val / 20)
  gain_dB = 10^(gain_dB_sl.val / 20)
  attack = 0.005
  release = 0.005
  --reaper.PreventUIRefresh(1)
  --**reaper.Main_OnCommand(41844,0)
  --**for i=1, #source_rms_t.rms do
  current_env_points = {}
  --local compressor_gain = 0
  local env_point_val = 1
  
  
  local min_dist_for_comp_points = points_per_second.max_val/points_per_second.val*rms_window_size
  --comp_point_dist=100/points_per_second.val*samples_per_channel / sample_rate
  for i=1, #channel_data[1].rms do
    peak_val = channel_data[1].peak_val[i]
    rms_val = channel_data[1].rms[i]
    
    if detect_by_rms then
      rms = rms_val
    else
      rms = peak_val
    end
    
    if env_point_value_is_rms then
      env_point_val = rms_val
      --c_e = 1-rms_val
    else
      env_point_val = peak_val
      --c_e = 1-peak_val
    end
--**
        
    --pos_at_time_sel = floor(time_sel_start-item_pos)--*1000/10+1
    --end_pos_at_time_sel = pos_at_time_sel + floor(time_sel_end-time_sel_start)--*1000/10+1
    
    --**peak_pos = channel_data[1].peak_pos[i]--**source_rms_t.pos[i]
    peak_pos = channel_data[1].peak_pos[i]
    --peak_pos = (i-1)*0.01 -- start of current RMS window
    --msg(peak_pos)
    if rms > open_threshold then
    --if rms > open_threshold then --and peak_pos > points_per_second.val/1000/10 then 
      if not gate_open then
        if peak_pos > last_env_point_pos and peak_pos > last_gate_close_pos then
          --**reaper.InsertEnvelopePoint(env, peak_pos-0.07, 0.0, 5, -0.5, false, true)
          --**reaper.InsertEnvelopePoint(env, peak_pos-0.02, 1.0, 0, 0, false, true)
          --if peak_pos < last_gate_close_pos then
            --**reaper.SetTakeStretchMarker(take, -1, peak_pos, nil)
            reaper.InsertEnvelopePoint(env, peak_pos, ng_floor, 5, -0.5, false, true)
            --if points_per_second.val > 0 then
            --  reaper.InsertEnvelopePoint(env, peak_pos, (1-c_e)*compressor_gain*gain_dB, 5, 0.5, true, true)
            --else
            if points_per_second.val > 0 then
              reaper.InsertEnvelopePoint(env, peak_pos+attack, 1.0, 0, 0, true, true)
            else
              reaper.InsertEnvelopePoint(env, peak_pos+attack, 1.0*gain_dB, 0, 0, true, true)
            end
            --end
            
            --**reaper.InsertEnvelopePoint(env, peak_pos+attack, c_e*gain_dB, 0, 0, true, true)
            
            last_gate_open_pos = peak_pos+attack --peak_pos
          --else
          --  reaper.DeleteEnvelopePointRange(env, last_gate_close_pos, last_gate_close_pos+release)
          --end
        --else
          --**reaper.InsertEnvelopePoint(env, last_env_point_pos+0.00001, ng_gain, 5, -0.5, false, true)
          --**reaper.InsertEnvelopePoint(env, last_env_point_pos+0.05, 1.0, 0, 0, false, true)
        end
        last_env_point_pos = last_gate_open_pos
        gate_open = true
      else
        if points_per_second.val > 0 then --and vol_riding then
        
          --**if peak_pos >= last_env_point_pos2+ 100/points_per_second.val*samples_per_channel / sample_rate then
          if peak_pos > last_env_point_pos and peak_pos > last_env_point_pos2 + min_dist_for_comp_points then
          --counter = counter + 1
            ----***c_e = c_e^comp_sl.val*gain_dB
            --peak_pos = offs
            --slope = 1-1/comp_sl.val
            slope = 1-1/comp_sl.val
            
            --compressor_gain = c_e
            env_point_val_dB = 20*log10(env_point_val)
            peak_val_dB = 20*log10(peak_val)
            if env_point_val_dB >= comp_threshold_sl.val then
              compressor_gain = slope*(comp_threshold_sl.val - env_point_val_dB)
              --msg(compressor_gain)
              compressor_gain = 10^(compressor_gain/20)
              --msg(comp_threshold_sl.val - peak_val_dB)
             
              
             
            else
              --c_e = last_c_e-c_e
              compressor_gain = 1
              
              --compressor_gain = 10^(compressor_gain/20)
            end
            --**env_point_val = (1-env_point_val)*compressor_gain*gain_dB
            env_point_val = compressor_gain*gain_dB
            -- env_point_val = math.min((1-env_point_val)*compressor_gain*gain_dB, 1.0) -- max point val to 0 dB
            --**env_point_val = math.min(env_point_val, 1)
            reaper.InsertEnvelopePoint(env, peak_pos, env_point_val, 0, 0, true, true)
            --msg((1-c_e)*compressor_gain*gain_dB)
            --reaper.InsertEnvelopePoint(env, peak_pos, 1-(c_e*compressor_gain*gain_dB), 0, 0, true, true)
            --current_env_points[#current_env_points+1] = peak_pos
            --**reaper.InsertEnvelopePoint(env, peak_pos, 0.5+(c_e)^4, 0, 0, true, true)
            --**reaper.InsertEnvelopePoint(env, peak_pos, 0.5+(c_e)^1.1, 0, 0, true, true)
            last_env_point_pos = peak_pos
            last_env_point_pos2 = offs
            --end
            --**reaper.SetTakeStretchMarker(take, -1, peak_pos, nil)
          end
        end
      end
            
            
    else
      -- GATE IS CLOSING
      if gate_open and rms < close_threshold then --and peak_pos - last_env_point_pos > 0.5
      --peak_pos = offs + samples_per_channel / sample_rate
        --**if peak_pos-0.07 > last_gate_open_pos + hold  then
        if peak_pos > last_gate_open_pos + hold  then
          --**reaper.SetTakeStretchMarker(take, -1, peak_pos, nil)
          --if points_per_second.val > 0 then
           -- reaper.InsertEnvelopePoint(env, peak_pos, (1-c_e)*compressor_gain*gain_dB, 5, 0.5, true, true)
          --else
            if points_per_second.val > 0 then
              reaper.InsertEnvelopePoint(env, peak_pos, 1.0, 5, 0.5, true, true)
            else
              reaper.InsertEnvelopePoint(env, peak_pos, 1.0*gain_dB, 5, 0.5, true, true)
            end
          --end
          
          reaper.InsertEnvelopePoint(env, peak_pos+release, ng_floor, 0, 0, false, true)
          gate_open = false
          last_env_point_pos = peak_pos+release--peak_pos-0.02
          last_gate_close_pos = peak_pos+release--peak_pos-0.02
        end
      end
    end
    offs = i*0.01
          --last_peak_pos = peak_pos
  end
  reaper.Envelope_SortPoints(env)
  --reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  if add_undo_point == false then 
    add_undo_point = true
  end
  ---[[
  last_open_threshold_dB_val = open_threshold_dB.val
  last_close_threshold_dB_val = close_threshold_dB_val
  last_points_per_second_val = points_per_second.val
  last_hold_sl_val = hold_sl.val
  last_ng_floor_sl_val = ng_floor_sl.val
  last_gain_dB_sl_val = gain_dB_sl.val
  last_comp_sl_val = comp_sl.val
  last_comp_threshold_sl = comp_threshold_sl.val
  --]]
end







function get_set_envelope_points()
  if last_comp_sl_val == comp_sl.val then
    return
  end
  local item = reaper.GetSelectedMediaItem(0, 0)
  if item == nil then
    info_text = "Please select one item"
    return
  end
  local take = reaper.GetActiveTake(item)
    if take == nil then
    info_text = "Empty item selected?"
    return
  end
  
  if reaper.TakeIsMIDI(take) then
    info_text = "Please select an audio take"
    return
  end
  
 
  --local env = envelope.pointer
  local env = get_and_show_take_envelope(take, "Volume")
  local envelope = get_env_properties(env)
  local get_env_point = reaper.GetEnvelopePoint
  if env == nil then
    gfx.x = gui.error_msg_x ; gfx.y = gui.error_msg_y
    gfx.set(1,0,0,1)
    gfx.printf("Please select a track/take envelope")
  else
    local min_val = envelope.min_val
    local max_val = envelope.max_val
    local name = envelope.name
    local points = current_env_points
    for i=1, #current_env_points do
       point_index = reaper.GetEnvelopePointByTime(env, points[i])
      --value = ({get_env_point(env, point_index)})[3]
      --value = math.min(math.max(min_val, value), max_val)
      reaper.SetEnvelopePoint(env,
                              point_index,
                              points[i],
                              comp_sl.val*2,
                              nil,
                              nil,
                              nil,
                              true)
 --end
  --[[
    local env_point_count = reaper.CountEnvelopePoints(env)
    
    -- COLLECT POINTS --
    
    if array_created == false then
      sel_points = 0
      sum = 0
      c = 1
      e_i = {}
      e_v = {}
      local value = 0
      local selected = false
      for i=1,env_point_count do
        value = ({get_env_point(env, i-1)})[3]
        selected = ({get_env_point(env, i-1)})[6]
        if selected then
          e_i[c] = i-1
          e_v[c] = value
          c = c+1
          sel_points = sel_points + 1
          sum = sum + value
        end
      end
      average = sum/sel_points
      array_created = true
      last_comp_sl_val = comp_sl.val
    end
    
    
    -- APPLY CHANGES TO SELECTED ENVELOPE --
    --[[
    if array_created == true and last_comp_sl_val ~= comp_sl.val then
      --if comp_sl.val < last_comp_sl_val then
      --  gfx.printf("Expanding... ".. name) else gfx.printf("Compressing... ".. name)
      --end
    if envelope.is_tempo then
      for i=1, sel_points do
        local _, timeOut, measure, beat, value, num, den, linear = reaper.GetTempoTimeSigMarker(0, e_i[i])
        local v = e_v[i]
        value = v + (average-v) * comp_sl.val
        value = math.min(math.max(min_val, value), max_val)

        if den ~= 0 then -- make sure partial tempo markers have their positions preserved
          local positionQN = reaper.TimeMap_timeToQN_abs(0, timeOut);
          reaper.SetTempoTimeSigMarker(0, e_i[i], timeOut, -1, -1, value, num, den, linear)
          reaper.SetTempoTimeSigMarker(0, e_i[i], reaper.TimeMap_QNToTime_abs(0, positionQN), -1, -1, value, num, den, linear)
        else
          reaper.SetTempoTimeSigMarker(0, e_i[i], -1, measure, beat, value, num, den, linear)
        end
      end
    else
      for i=1, sel_points do
        local _, timeOut, value, _, _, _ = reaper.GetEnvelopePoint(env, e_i[i])
        local v = e_v[i]
        --l = 20*math.log(math.abs(v),10)
        value = v + (average-v) * comp_sl.val
        --value = v + l * comp_sl.val
        value = math.min(math.max(min_val, value), max_val)        
        reaper.SetEnvelopePoint(env, e_i[i], timeOut, value)
      end
    
    end 
    --]]      
      -- a flag for "reaper.Undo_OnStateChange"
      if add_undo_point == false then 
        add_undo_point = true
      end
      last_comp_sl_val = comp_sl.val
    end
    reaper.Envelope_SortPoints(env)
    reaper.UpdateArrange()
    if envelope.is_tempo then
      reaper.UpdateTimeline()
    end
  end
end





-- Returns "envelope properties" table 
function get_env_properties(env)
  local envelope = {}
  if env ~= nil then
    local br_env = reaper.BR_EnvAlloc(env, true)
    local active, visible, armed, in_lane, lane_height, default_shape, 
          min_val, max_val, center_val, env_type, is_fader_scaling
          = reaper.BR_EnvGetProperties(br_env, false, false, false, false, 0, 0, 0, 0, 0, 0, false)        
    reaper.BR_EnvFree(br_env, false)
    
    env_name = ({reaper.GetEnvelopeName(env, "")})[2]
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
    if is_fader_scaling then
      max_val    = reaper.ScaleToEnvelopeMode(1, max_val)
      center_val = reaper.ScaleToEnvelopeMode(1, center_val)
      min_val    = reaper.ScaleToEnvelopeMode(1, min_val)
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
    envelope.is_tempo = env_type == 9
  end
  return envelope
end 




--------**************************

function analyze_take_source()
  
  local time_sel_start, time_sel_end = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  if time_sel_start == time_sel_end then
    --**info_text = "No time selection set"
    --**return
  end
--**  
  --local RMS_t = {}
  local item = reaper.GetSelectedMediaItem(0, 0)
  if item == nil then
    info_text = "Please select one item"
    return
  end
  
  local take = reaper.GetActiveTake(item)
  if take == nil then
    info_text = "Empty item selected?"
    return
  end
  
  env = get_and_show_take_envelope(take, "Volume")
  reaper.SetCursorContext(2, env)
  --env = reaper.GetSelectedTrackEnvelope(0)
  
  if reaper.GetEnvelopeScalingMode(env) == 1 then
    info_text = "'Volume envelope: Fader scaling' -mode is not supported"
    return
  end
  
  env_prop = get_env_properties(env)
  if env_prop.pointer == nil then
    info_text = "Couldn't get envelope properties"
    return
  end
--  local item = reaper.GetMediaItemTake_Item(take) -- Get parent item
  
   
  local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local item_end = item_pos+item_len
  local item_loop_source = reaper.GetMediaItemInfo_Value(item, "B_LOOPSRC") == 1.0 -- is "Loop source" ticked?
  
  -- Get media source of media item take
  local take_pcm_source = reaper.GetMediaItemTake_Source(take)
  if take_pcm_source == nil then
    return
  end
  
  -- Create take audio accessor
  local aa = reaper.CreateTakeAudioAccessor(take)
  if aa == nil then
    return
  end
  
  -- Get the length of the source media. If the media source is beat-based,
  -- the length will be in quarter notes, otherwise it will be in seconds.
  local take_source_len, length_is_QN = reaper.GetMediaSourceLength(take_pcm_source)
  if length_is_QN then
    return
  end
  
  local take_start_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  
  
  -- (I'm not sure how this should be handled)
  
  -- Item source is looped --
  -- Get the start time of the audio that can be returned from this accessor
  local aa_start = reaper.GetAudioAccessorStartTime(aa)
  -- Get the end time of the audio that can be returned from this accessor
  local aa_end = reaper.GetAudioAccessorEndTime(aa)
  
   
  --[[
  -- Item source is not looped --
  if not item_loop_source then
    if take_start_offset <= 0 then -- item start position <= source start position 
      aa_start = -take_start_offset
      aa_end = aa_start + take_source_len
    elseif take_start_offset > 0 then -- item start position > source start position 
      aa_start = 0
      aa_end = aa_start + take_source_len- take_start_offset
    end
    if aa_start + take_source_len > item_len then
      --msg(aa_start + take_source_len > item_len)
      aa_end = item_len
    end
  end
  --aa_len = aa_end-aa_start
  --]]
  
  
  -- Get the number of channels in the source media.
  local take_source_num_channels = reaper.GetMediaSourceNumChannels(take_pcm_source)
  
  channel_data = {} -- channel data is collected to this table
  -- Initialize channel_data table
  for i=1, take_source_num_channels do
    channel_data[i] = {
                        rms = {},       -- RMS value in current RMS window
                        sum = 0,        -- (for calculating RMS per channel)
                        peak_val = {},  -- peak value in current RMS window
                        peak_pos = {}   -- peak value in current RMS window
                      }
  end
    
  -- Get the sample rate. MIDI source media will return zero.
  local take_source_sample_rate = reaper.GetMediaSourceSampleRate(take_pcm_source)
  if take_source_sample_rate == 0 then
    return
  end
  
  -- How many samples are taken from audio accessor and put in the buffer
   samples_per_channel = take_source_sample_rate/1000*10 -- 10 ms
  
  ----samples_per_channel = math.floor(take_source_sample_rate / 1000 * 10) -- (old)
  ----samples_per_channel = 18 -- (old)
  
  -- Samples are collected to this buffer
   buffer = reaper.new_array(samples_per_channel * take_source_num_channels)
  
  --local take_playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  
  -- total_samples = math.ceil((aa_end - aa_start) * take_source_sample_rate)
  local total_samples = math.floor((aa_end - aa_start) * take_source_sample_rate + 0.5)
  --total_samples = (aa_end - aa_start) * take_source_sample_rate
  
  -- take source is not within item -> return
  if total_samples < 1 then
    return
  end

  
  --[[
  local open_threshold = 10^(open_threshold_dB.val / 20)
  local close_threshold = 10^(close_threshold_dB.val / 20)
  --local gain = 10^(gain_db.val / 20)
  
  local ng_floor
  if ng_floor_sl.val == -150 then 
    ng_floor = 0.0
  else
     ng_floor = 10^(ng_floor_sl.val / 20)
  end
  --]]
  
  local block = 0
  local sample_count = 0
  local audio_end_reached = false
  local offs = aa_start
  
  --local log10 = function(x) return math.log(x, 10) end
  local abs = math.abs
  --local floor = math.floor
  local peak_val = 0.0
  local peak_sample_index = -1
  --reaper.DeleteEnvelopePointRange(env, item_pos, item_end)
  --reaper.DeleteEnvelopePointRange(env, 0, item_len)
  --**reaper.DeleteEnvelopePointRange(env, time_sel_start-item_pos, time_sel_end-item_pos)
  ----total_samples = math.floor((item_end - item_pos) * sample_rate)
  ------total_samples = math.floor((time_sel_end - time_sel_start) * sample_rate)
  --**total_samples = math.ceil((time_sel_end - time_sel_start) * sample_rate)
  
  local s_c = 0
  local last_peak_pos = 0
  local last_peak_val = 0
  local block = 0
  peak_sample_index = -1
   peak_val = -1
  sample_count = 0
  g = true
  points_added = false
  --msg(offs)
  
  local abs = math.abs
  local floor = math.floor
  local peak_count = 0
  --**points = {}
   sum = 0
  local sqr = math.sqrt
  gate_open = false 
  hold_start = offs
  last_env_point_pos = offs
  last_env_point_pos2 = offs
  last_gate_close_pos = -1
  last_gate_open_pos = -1
  hold = hold_sl.val/1000
  --counter = 0
  
  source_rms_t = {pos = {}, rms = {}}
  local spl
   current_channel = 1
  
  
  -- Loop through samples
  while sample_count < total_samples do
    if audio_end_reached then
      break
    end
  
    -- Get a block of samples from the audio accessor.
    -- Samples are extracted immediately pre-FX,
    -- and returned interleaved (first sample of first channel, 
    -- first sample of second channel...). Returns 0 if no audio, 1 if audio, -1 on error.
    local aa_ret = 
            reaper.GetAudioAccessorSamples(
                                            aa,                       -- AudioAccessor accessor
                                            take_source_sample_rate,  -- integer samplerate
                                            take_source_num_channels, -- integer numchannels
                                            offs,                     -- number starttime_sec
                                            samples_per_channel,      -- integer numsamplesperchannel
                                            buffer                    -- reaper.array samplebuffer
                                          )
      
    if aa_ret == 1 then
      --sum = 0
      peak_val = 0.0
      peak_sample_index = -1
      peak_pos = -1
      for i=1, #buffer, take_source_num_channels do
        if sample_count == total_samples then
          audio_end_reached = true
          break
        end
        sample_index = i
        for j=1, take_source_num_channels do
          local buf_pos = i+j-1
          spl = abs(buffer[buf_pos])
          --spl = buffer[buf_pos]
          channel_data[j].sum = channel_data[j].sum + spl
          if spl > peak_val then
            peak_val = spl
            --source_rms_t.pos[#source_rms_t.pos+1] = spl
            peak_sample_index = sample_index
            --**peak_sample_index = block * samples_per_channel + sample_index
            --peak_sample_index = offs + sample_index/take_source_sample_rate
            
            
            
          end
          
          --channel_data[j].sum_squares = channel_data[j].sum_squares + spl*spl
        end
        
        --channel_data[j].rms = channel_data[j].sum_squares/samples_per_channel
        --sum = sum + spl*spl
        --source_rms_t.pos[#source_rms_t.pos+1] = peak_pos --
        --source_rms_t.rms[#source_rms_t.rms+1] = peak_val--rms --20*math.log(math.abs(rms),10)
        sample_count = sample_count + 1
      end
      
      local peak_pos = offs + (peak_sample_index-1)/take_source_sample_rate -- "peak_sample_index-1" means "start of peak sample")
      for j=1, take_source_num_channels do
        channel_data[j].peak_val[#channel_data[j].peak_val+1] = peak_val  -- absolute spl val
        channel_data[j].peak_pos[#channel_data[j].peak_pos+1] = peak_pos  -- peak position in current RMS window
        -- calculate RMS for current samples
        channel_data[j].rms[block+1] = channel_data[j].sum/samples_per_channel
        channel_data[j].sum = 0
      end
      --local peak_pos = time_sel_start+peak_sample_index / take_source_sample_rate-item_pos -- peak position in current channel
      --channel_data[current_channel].peaks[#channel_data[current_channel].peaks+1] = peak_pos
    elseif aa_ret == 0 then -- no audio in current buffer
      sample_count = sample_count + samples_per_channel
    else
      info_text = "Couldn't get samples"
      return
    end
    
    block = block + 1
    offs = offs + samples_per_channel / take_source_sample_rate -- new offset in take source (seconds)
    gfx.x = 10
    gfx.y = 10
    gfx.printf("Analyzing..." .. floor(100*block*samples_per_channel/total_samples + 0.5) .. "%%")
    gfx.update()
  end -- end of while loop
  
  reaper.DestroyAudioAccessor(aa)
  reaper.UpdateArrange()
  
  --msg(#channel_data[1].peak_val)
  --[[ OLD CODE 
  item = reaper.GetSelectedMediaItem(0, 0)
  if item == nil then
    info_text = "Please select one item"
    return
  end
  take = reaper.GetActiveTake(item)
  if take == nil then
    info_text = "Empty item selected?"
    return
  end
  
  sp = get_source_properties()--source_properties_table
  
    
  item_t = sp.item            
  take_t = sp.take
  time_sel_t = sp.time_sel
  aa_t = sp.take.aa
  
  
  env = get_and_show_take_envelope(take, "Volume")
  reaper.SetCursorContext(2, env)
  --env = reaper.GetSelectedTrackEnvelope(0)
  
  if reaper.GetEnvelopeScalingMode(env) == 1 then
    info_text = "'Volume envelope: Fader scaling' -mode is not supported"
    return
  end
  
  env_prop = get_env_properties(env)
  if env_prop.pointer == nil then
    info_text = "Couldn't get envelope properties"
    return
  end
  
  --[[ OLD CODE
  if take_t.aa.o ~= nil then
    reaper.DestroyAudioAccessor(take_t.aa.o)
    take_t.aa.o = reaper.CreateTakeAudioAccessor(take_t.id)
  end
  last_accessor = take_t.aa.o
  aa_start = take_t.start
  aa_end = take_t.end_pos
  
  --env_prop = get_env_properties(env)
  --noise_gate_threshold = math.pow(10, noise_gate_threshold_dB / 20)
  
  
  
  local open_threshold = 10^(open_threshold_dB.val / 20)
  local close_threshold = 10^(close_threshold_dB.val / 20)
  gain = 10^(gain_db.val / 20)

  local ng_gain
  if ng_gain_sl.val == -150 then 
    ng_gain = 0.0
  else
     ng_gain = 10^(ng_gain_sl.val / 20)
  end
  --]]
  --local gain = 1
  --//local noise_gate_threshold = 10^(noise_gate_threshold_dB.val / 20)
  --//local ng_dB_val = noise_gate_gain_dB.val
  
  --if noise_gate_gain_dB.x1 == 120 then ng_dB_val = -10000000 end
  --//local noise_gate_gain = 10^(ng_dB_val / 20)

  --//local gain = 10^(gain_dB.val / 20)
  --ratio ={}
 -- ratio.val = 1
  
   
  --local take_pcm = take_t.pcm
  --local sample_rate = take_t.sample_rate
  --local num_channels = take_t.num_channels
  
  ----points_per_second < 10 ? points_per_second = 10;
  ----if points_per_second.val > 100 then points_per_second.val = 100 end
  
  --samples_per_channel = math.floor(sample_rate / 1000 * points_per_second.val)
  --**samples_per_channel = math.floor(sample_rate / 1000 * 10)
  --samples_per_channel = 441


 -- buffer = reaper.new_array(samples_per_channel)
  
  --//if time_sel_start < item_pos+ take_offset then time_sel_start = item_pos+ take_offset end
  --//if time_sel_end > item_end then time_sel_end = item_end end
  
  
  
  
  --time_sel_start = time_sel_start
  --time_sel_end = time_sel_end
  
  --time_sel_start = item_pos
  --time_sel_end = item_end
  
  
  --start_offs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  ----offs = math.max(0, time_sel_start-item_pos)
  --offs = math.max(0, time_sel_start)- item_pos
  --offs = 0
  --take_pos = item_pos-start_offs
  
  
  --[[
  while g == true do
    if offs + samples_per_channel / sample_rate > time_sel_end-item_pos then
      g = false 
      points_added = true
    end
    
                                          
    if reaper.GetAudioAccessorSamples(last_accessor,sample_rate,num_channels,offs,samples_per_channel,buffer) > 0 then
      sum = 0
      for i=1, samples_per_channel do
        local curr_sample = buffer[i]
        if abs(peak_val) < abs(curr_sample) then
          peak_val = curr_sample
          peak_sample_index = block * samples_per_channel + i
        end
        sample_count = sample_count + 1
        sum = sum + curr_sample*curr_sample
      end
      peak_val_abs = abs(peak_val)
      
  
      if peak_sample_index > -1 then
        sum = sum/samples_per_channel
        rms = sqr(sum)
        
        --points_per_second.val
        --msg(rms)
        local peak_pos = time_sel_start+peak_sample_index / sample_rate-item_pos
        source_rms_t.pos[#source_rms_t.pos+1] = peak_pos --
        source_rms_t.rms[#source_rms_t.rms+1] = peak_val_abs--rms --20*math.log(math.abs(rms),10)
        --**source_rms_t.rms[#source_rms_t.rms+1] = rms --20*math.log(math.abs(rms),10)
        --**points[#points+1] = peak_pos
        --c_e =  gain-1*peak_val_abs--^0.5--exp_factor.val
        c_e = 1-peak_val_abs*0.5--^0.5--exp_factor.val
--**--
        --if peak_val_abs > open_threshold then
        if not detect_by_rms then
          rms = peak_val_abs
        end
        if rms > open_threshold then
          sel = true
        else
          sel = false
        end
        
        if c_e > env_prop.max_val then c_e = env_prop.max_val end
        
        if g then
          if rms > open_threshold then --and peak_pos > points_per_second.val/1000/10 then 
            if not gate_open then
              if peak_pos-0.07 > last_env_point_pos then
                --**reaper.InsertEnvelopePoint(env, peak_pos-0.07, 0.0, 5, -0.5, false, true)
                --**reaper.InsertEnvelopePoint(env, peak_pos-0.02, 1.0, 0, 0, false, true)
                reaper.InsertEnvelopePoint(env, offs-0.05, ng_gain, 5, -0.5, false, true)
                reaper.InsertEnvelopePoint(env, offs, 1.0, 0, 0, false, true)
                last_gate_open_pos = offs--peak_pos
              else
                reaper.InsertEnvelopePoint(env, last_env_point_pos+0.00001, ng_gain, 5, -0.5, false, true)
                reaper.InsertEnvelopePoint(env, last_env_point_pos+0.05, 1.0, 0, 0, false, true)
              end
              --last_gate_open_pos = peak_pos-0.02
              last_env_point_pos = last_gate_open_pos
              gate_open = true
            else
              if points_per_second.val > 0 and vol_riding then
                if peak_pos >= last_env_point_pos2+ 100/points_per_second.val*samples_per_channel / sample_rate then
                  --counter = counter + 1
                  reaper.InsertEnvelopePoint(env, peak_pos, c_e, 0, 0, true, true)
                  --reaper.InsertEnvelopePoint(env, peak_pos, 0.5+(c_e)^4, 0, 0, true, true)
                  --reaper.InsertEnvelopePoint(env, peak_pos, 0.5+(c_e)^1.1, 0, 0, true, true)
                  last_env_point_pos = peak_pos
                  last_env_point_pos2 = offs
                end
              end
            end
            --last_sel = sel
            
            
          --//elseif not sel and (last_sel or time_sel_start+peak_sample_index / sample_rate-item_pos - last_peak_pos > .2) then
          else--not sel then --and peak_pos - last_peak_pos > points_per_second.val/1000 then
            ----reaper.InsertEnvelopePoint(env, time_sel_start+(peak_sample_index / sample_rate-item_pos), c_e, 0, 0, false, true)
            -- GATE IS CLOSING
            if gate_open and rms < close_threshold then --and peak_pos - last_env_point_pos > 0.5
            --peak_pos = offs + samples_per_channel / sample_rate
              if peak_pos-0.07 > last_gate_open_pos + hold  then
                if last_env_point_pos > peak_pos-0.07 then
                 -- peak_pos = last_env_point_pos+0.08
                end
                reaper.InsertEnvelopePoint(env, peak_pos-0.07, 1.0, 5, 0.5, false, true)
                reaper.InsertEnvelopePoint(env, peak_pos-0.02, ng_gain, 0, 0, false, true)
                gate_open = false
                last_env_point_pos = peak_pos-0.02
                last_gate_close_pos = peak_pos-0.02
              end
              
            --if gate_open then
                --gate_open = false
              --last_env_point_pos = peak_pos-0.02
              
              --end
            --end
            end
            --last_gate_close_pos = peak_pos-0.07
            --reaper.InsertEnvelopePoint(env, peak_pos-0.01, 0.0, 5, -0.9, sel, true)
           --reaper.InsertEnvelopePoint(env, time_sel_start+peak_sample_index / sample_rate-item_pos, 0.0, 0, 0, sel, true)
            --last_sel = sel
          end
          
          --last_peak_pos = peak_pos
        end
          --last_peak_pos = time_sel_start+(peak_sample_index / sample_rate-item_pos)
          --msg(time_sel_start+peak_sample_index / sample_rate-item_pos)
          -- msg(last_peak_pos)
       -- end
        last_peak_pos = peak_pos
        last_peak_val = peak_val_abs
        
        --if sample_count > total_samples then return end
        --if offs > time_sel_end - 1 then return end
      end
      block = block + 1
      offs = offs + samples_per_channel / sample_rate
      peak_val = 0.0
      peak_sample_index = -1
    else
      info_text="Couldn't get samples"
      offs = offs + samples_per_channel / sample_rate
      --return
      
     -- msg(samples_per_channel)
    end
    --if points_added then
      --reaper.InsertEnvelopePoint(env, time_sel_start-item_pos, 1, 0, 0, false, true)
      --reaper.InsertEnvelopePoint(env, time_sel_end-item_pos, 1, 0, 0, false, true)
    --end
    --s_c = s_c + 1
    gfx.x = 10
    gfx.y = 10
    gfx.printf("Analyzing..." .. floor(100*block*samples_per_channel/total_samples + 0.5) .. "%%")
    gfx.update()
    --msg(#points)
  end
  
  --if points_added then
    local point_index = reaper.GetEnvelopePointByTime(env, time_sel_start-item_pos)
    local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(env, point_index)
    --reaper.InsertEnvelopePoint(env, time_sel_start-item_pos, value, 0, 0, false, true) 
    --reaper.InsertEnvelopePoint(env, time_sel_start-item_pos, 0, 0, 0, false, true)
    
    
    --reaper.InsertEnvelopePoint(env, time_sel_end-item_pos, 1, 0, 0, false, true)
  --end
  update = true
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_ENV_UNSEL_OUT_TIME_SEL"), 0)
  --env_state=reaper.GetToggleCommandState(40693) -- get "toggle take vol env" state
  
  reaper.Envelope_SortPoints(env)
  reaper.UpdateArrange()
  reaper.Undo_OnStateChange_Item(0, "Create envelope points", item)
  info_text = ""
 
 --]]
  info_text = ""
  adjust_params()
  --return channel_data
end

--------**************************

--[[
function get_samples_create_points(take, source_properties_table)
  sp = source_properties_table
  
  
  item_t = sp.item            
  take_t = sp.take
  time_sel_t = sp.time_sel
  aa_t = sp.take.aa
  
  env = get_and_show_take_envelope(take, "Volume")
  reaper.SetCursorContext(2, env)
  --env = reaper.GetSelectedTrackEnvelope(0)
  
  if reaper.GetEnvelopeScalingMode(env) == 1 then
    info_text = "'Volume envelope: Fader scaling' -mode is not supported"
    return
  end
  
  env_prop = get_env_properties(env)
  if env_prop.pointer == nil then
    info_text = "Couldn't get envelope properties"
    return
  end
  
  if take_t.aa.o ~= nil then
    reaper.DestroyAudioAccessor(take_t.aa.o)
    take_t.aa.o = reaper.CreateTakeAudioAccessor(take_t.id)
  end
  last_accessor = take_t.aa.o
  aa_start = take_t.start
  aa_end = take_t.end_pos
  
  --env_prop = get_env_properties(env)
  --noise_gate_threshold = math.pow(10, noise_gate_threshold_dB / 20)
  local open_threshold = 10^(open_threshold_dB.val / 20)
  local close_threshold = 10^(close_threshold_dB.val / 20)
  local ng_gain
  if ng_gain_sl.val == 150 then 
    ng_gain = 0.0
  else
     ng_gain = 10^(ng_gain_sl.val / 20)
  end
  
  
  
  gain = 10^(gain_db.val / 20)
  --local gain = 1
  --//local noise_gate_threshold = 10^(noise_gate_threshold_dB.val / 20)
  --//local ng_dB_val = noise_gate_gain_dB.val
  
  --if noise_gate_gain_dB.x1 == 120 then ng_dB_val = -10000000 end
  --//local noise_gate_gain = 10^(ng_dB_val / 20)

  --//local gain = 10^(gain_dB.val / 20)
  --ratio ={}
 -- ratio.val = 1
  
   
  local take_pcm = take_t.pcm
  local sample_rate = take_t.sample_rate
  local num_channels = take_t.num_channels
  
  ----points_per_second < 10 ? points_per_second = 10;
  ----if points_per_second.val > 100 then points_per_second.val = 100 end
  
  --samples_per_channel = math.floor(sample_rate / 1000 * points_per_second.val)
  samples_per_channel = math.floor(sample_rate / 1000 * 10)
  --samples_per_channel = 441


  buffer = reaper.new_array(samples_per_channel)
  
  
  item_pos = item_t.pos
  item_len = item_t.len
  item_end = item_pos + item_len
  
  take_start_offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  take_playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  
  time_sel_start = time_sel_t.start
  time_sel_end = time_sel_t.end_pos
  
  --//if time_sel_start < item_pos+ take_offset then time_sel_start = item_pos+ take_offset end
  --//if time_sel_end > item_end then time_sel_end = item_end end
  
  
  
  
  time_sel_start = time_sel_start
  time_sel_end = time_sel_end
  
  --time_sel_start = item_pos
  --time_sel_end = item_end
  
  
  --start_offs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
  ----offs = math.max(0, time_sel_start-item_pos)
  offs = math.max(0, time_sel_start)- item_pos
  --offs = 0
  --take_pos = item_pos-start_offs
  reaper.DeleteEnvelopePointRange(env, time_sel_start-item_pos, time_sel_end-item_pos)
  ----total_samples = math.floor((item_end - item_pos) * sample_rate)
  ------total_samples = math.floor((time_sel_end - time_sel_start) * sample_rate)
  total_samples = math.ceil((time_sel_end - time_sel_start) * sample_rate)

  local s_c = 0
  last_peak_pos = 0
  last_peak_val = 0
  block = 0
  peak_sample_index = -1
  local peak_val = -1
  sample_count = 0
  g = true
  points_added = false
  --msg(offs)
  
  local abs = math.abs
  local floor = math.floor
  local peak_count = 0
  --**points = {}
  local sum = 0
  local sqr = math.sqrt
  gate_open = false 
  hold_start = offs
  last_env_point_pos = offs
  last_env_point_pos2 = offs
  last_gate_close_pos = -1
  last_gate_open_pos = -1
  hold = hold_sl.val/1000
  counter = 0
  
  while g == true do
    if offs + samples_per_channel / sample_rate > time_sel_end-item_pos then
      g = false 
      points_added = true
    end
    
    if reaper.GetAudioAccessorSamples(last_accessor,sample_rate,num_channels,offs,samples_per_channel,buffer) > 0 then
      sum = 0
      for i=1, samples_per_channel do
        local curr_sample = buffer[i]
        if abs(peak_val) < abs(curr_sample) then
          peak_val = curr_sample
          peak_sample_index = block * samples_per_channel + i
        end
        sample_count = sample_count + 1
        sum = sum + curr_sample*curr_sample
      end
      peak_val_abs = abs(peak_val)
      
  
      if peak_sample_index > -1 then
        sum = sum/samples_per_channel
        rms = sqr(sum)
        --points_per_second.val
        --msg(rms)
        --[[
        if peak_val_abs < noise_gate_threshold then
          c_e = 0--noise_gate_gain
          sel = false
        else
        
        local peak_pos = time_sel_start+peak_sample_index / sample_rate-item_pos
        --**points[#points+1] = peak_pos
        --c_e =  gain-1*peak_val_abs--^0.5--exp_factor.val
        c_e = 1-peak_val_abs--^0.5--exp_factor.val
--**--
        --if peak_val_abs > open_threshold then
        if not detect_by_rms then
          rms = peak_val_abs
        end
        if rms > open_threshold then
          sel = true
        else
          sel = false
        end
        
        if c_e > env_prop.max_val then c_e = env_prop.max_val end
        
        if g then
          if rms > open_threshold then --and peak_pos > points_per_second.val/1000/10 then 
            if not gate_open then
              reaper.InsertEnvelopePoint(env, peak_pos-0.07, ng_gain, 5, -0.5, false, true)
              reaper.InsertEnvelopePoint(env, peak_pos-0.02, 1.0, 0, 0, false, true)
              last_gate_open_pos = peak_pos-0.02
              last_env_point_pos = last_gate_open_pos
              gate_open = true
            else
              if vol_riding then
                if peak_pos >= last_env_point_pos2+ 100/points_per_second.val*samples_per_channel / sample_rate then
                  counter = counter + 1
                  
                  reaper.InsertEnvelopePoint(env, peak_pos, c_e, 0, 0, true, true)
                  --reaper.InsertEnvelopePoint(env, peak_pos, 0.5+(c_e)^4, 0, 0, true, true)
                  --reaper.InsertEnvelopePoint(env, peak_pos, 0.5+(c_e)^1.1, 0, 0, true, true)
                  last_env_point_pos = peak_pos
                  last_env_point_pos2 = offs
                end
              end
            end
            --last_sel = sel
            
            
          --//elseif not sel and (last_sel or time_sel_start+peak_sample_index / sample_rate-item_pos - last_peak_pos > .2) then
          else--not sel then --and peak_pos - last_peak_pos > points_per_second.val/1000 then
            ----reaper.InsertEnvelopePoint(env, time_sel_start+(peak_sample_index / sample_rate-item_pos), c_e, 0, 0, false, true)
            -- GATE IS CLOSING
            if gate_open and rms < close_threshold then --and peak_pos - last_env_point_pos > 0.5
            --peak_pos = offs + samples_per_channel / sample_rate
              if peak_pos-0.07 > last_gate_open_pos + hold  then
                if last_env_point_pos > peak_pos-0.07 then
                  peak_pos = last_env_point_pos+0.08
                end
                reaper.InsertEnvelopePoint(env, peak_pos-0.07, 1.0, 5, 0.5, false, true)
                reaper.InsertEnvelopePoint(env, peak_pos-0.02, ng_gain, 0, 0, false, true)
                gate_open = false
              end
            --if gate_open then
                --gate_open = false
              --last_env_point_pos = peak_pos-0.02
                last_gate_close_pos = peak_pos-0.02
              --end
            --end
            end
            --last_gate_close_pos = peak_pos-0.07
            --reaper.InsertEnvelopePoint(env, peak_pos-0.01, 0.0, 5, -0.9, sel, true)
           --reaper.InsertEnvelopePoint(env, time_sel_start+peak_sample_index / sample_rate-item_pos, 0.0, 0, 0, sel, true)
            --last_sel = sel
          end
          
          --last_peak_pos = peak_pos
        end
          --last_peak_pos = time_sel_start+(peak_sample_index / sample_rate-item_pos)
          --msg(time_sel_start+peak_sample_index / sample_rate-item_pos)
          -- msg(last_peak_pos)
       -- end
        last_peak_pos = peak_pos
        last_peak_val = peak_val_abs
        
        --if sample_count > total_samples then return end
        --if offs > time_sel_end - 1 then return end
      end
      block = block + 1
      offs = offs + samples_per_channel / sample_rate
      peak_val = 0.0
      peak_sample_index = -1
    else
      info_text="Couldn't get samples"
      return
      
     -- msg(samples_per_channel)
    end
    --if points_added then
      --reaper.InsertEnvelopePoint(env, time_sel_start-item_pos, 1, 0, 0, false, true)
      --reaper.InsertEnvelopePoint(env, time_sel_end-item_pos, 1, 0, 0, false, true)
    --end
    --s_c = s_c + 1
    gfx.x = 10
    gfx.y = 10
    gfx.printf("Analyzing..." .. floor(100*block*samples_per_channel/total_samples + 0.5) .. "%%")
    gfx.update()
    --msg(#points)
  
  end
  
  --if points_added then
    local point_index = reaper.GetEnvelopePointByTime(env, time_sel_start-item_pos)
    local retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(env, point_index)
    --reaper.InsertEnvelopePoint(env, time_sel_start-item_pos, value, 0, 0, false, true) 
    --reaper.InsertEnvelopePoint(env, time_sel_start-item_pos, 0, 0, 0, false, true)
    
    
    --reaper.InsertEnvelopePoint(env, time_sel_end-item_pos, 1, 0, 0, false, true)
  --end
  update = true
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_ENV_UNSEL_OUT_TIME_SEL"), 0)
  --env_state=reaper.GetToggleCommandState(40693) -- get "toggle take vol env" state
  
  reaper.Envelope_SortPoints(env)
  reaper.UpdateArrange()
  reaper.Undo_OnStateChange_Item(0, "Create envelope points", item)
  info_text = ""
 
end
--]]
    
    


function draw_info_text()
  if info_text ~= nil and info_text ~= "" then
    gfx.set(1,1,0,info_text_a)
    gfx.x = info_text_x
    gfx.y = info_text_y
    gfx.drawstr(tostring(info_text))
    if info_text_a < 0.7 then info_text_a = 1 end
    info_text_a = info_text_a - 0.01
  end
end




function OnMouseDown(x, y)
  mouse.capcnt = 0
  mouse.ox_l, mouse.oy_l = x, y
  if comp_sl._mouse_on_hitzone then -- mouse is pressed on compress slider
    get_set_envelope_points() -- update envelope table
  elseif open_threshold_dB._mouse_on_hitzone then
    --adjust_threshold(true)
  elseif close_threshold_dB._mouse_on_hitzone then
    --adjust_threshold(false)
  end
end


function OnMouseRmbDown(x, y)
  right_click_menu = Menu.create_menu("right_click_menu")
  
  local menu_item_detect_by_rms = 
                    right_click_menu:add_item(
                       { 
                         label = "Detect by RMS",
                         toggleable = true,
                         selected = detect_by_rms
        
                       }
                     )

  menu_item_detect_by_rms.command = function()
                                     detect_by_rms = not detect_by_rms
                                     adjust_params()
                                   end
  
  local menu_item_env_point_val_is_rms = 
                    right_click_menu:add_item(
                       { 
                         label = "Envelope follower uses RMS values",
                         toggleable = true,
                         selected = env_point_value_is_rms
        
                       }
                     )
  
  menu_item_env_point_val_is_rms.command = function()
                                     env_point_value_is_rms = not env_point_value_is_rms
                                     adjust_params()
                                   end
  
  
  
  
  right_click_menu:show(x, y)
end


function OnMouseMove(x, y)
  -- handle mouse move here, use mouse.down and mouse.capcnt
  mouse.last_x, mouse.last_y = x, y
  mouse.dx = gfx.mouse_x - mouse.ox_l
  --mouse.dy = gfx.mouse_y - mouse.oy_l
  --mouse.capcnt = mouse.capcnt + 1
  if comp_sl._dragging then -- user is dragging the compress slider
    adjust_params("comp_sl")--get_set_envelope_points() -- apply changes to selected take volume envelope
  elseif points_per_second._dragging then
    adjust_params("points_per_second")
  elseif open_threshold_dB._dragging then
    adjust_params("open_threshold_dB")
  elseif close_threshold_dB._dragging then
    adjust_params("close_threshold_dB")
  elseif hold_sl._dragging then
    adjust_params("hold_sl")
  elseif ng_floor_sl._dragging then
    adjust_params("ng_floor_sl")
  elseif gain_dB_sl._dragging then
    adjust_params("gain_dB_sl")
  elseif comp_threshold_sl._dragging then
    adjust_params("comp_threshold_sl")
  end
end


function OnMouseUp(x, y)
  mouse.uptime = os.clock()
  mouse.dx = 0
  mouse.dy = 0
  mouse.last_LMB_state = false
  --comp_sl:set_to_default_value()
  --[[
  last_open_threshold_dB_val = open_threshold_dB.val
  last_close_threshold_dB_val = close_threshold_dB_val
  last_points_per_second_val = points_per_second.val
  last_hold_sl_val = hold_sl.val
  last_ng_floor_sl_val = ng_floor_sl.val
  --]]
  array_created = false
  if gui.add_undo_point == true then
    reaper.Undo_OnStateChangeEx("Adjust track send volume", -1, -1)
    gui.add_undo_point = false
  end
end

function OnMouseRmbUp(x, y)
  if right_click_menu ~= last_right_click_menu then
    if detect_by_rms then
      first_item = "!Detect by RMS|"
    else  
      first_item = "Detssect by RMS|"
    end
  end
  --last_right_click_menu = right_click_menu
end


--//////////
--// Main //
--//////////

function main()
  gfx.x = 10
  gfx.y = 10
  RMB_state = gfx.mouse_cap&2 == 2
  -- This is from Schwa's GUI example
  mx, my = gfx.mouse_x, gfx.mouse_y
  if mouse.cap(mouse.LB) then              -- LMB pressed down?
    if mouse.last_LMB_state == false then  -- prevent "polling"...
      OnMouseDown(mx, my)                  --   ...run this once per LMB click
      --if mouse.uptime and os.clock() - mouse.uptime < 0.20 then
        --OnMouseDoubleClick(mx, my)
      --end
    elseif mx ~= mouse.last_x or my ~= mouse.last_y then
      OnMouseMove(mx, my)
    end
  elseif RMB_state and not last_RMB_state then
    OnMouseRmbDown(mx, my) 
  elseif mouse.last_LMB_state then
    OnMouseUp(mx, my)
  elseif last_RMB_state then
    OnMouseRmbUp(mx, my)
  end
  
  draw_info_text()
  -- Draw buttons
  --create_btn:draw()
  analyze_btn:draw()
  --inv_btn:draw()
  toggle_env_btn:draw()
  
  gfx.x = open_threshold_dB.x1
  gfx.y = open_threshold_dB.y1 - gfx.texth-2
  gfx.printf("Noise gate:")
  
  open_threshold_dB:update()
  open_threshold_dB:draw_label()
  open_threshold_dB:draw_value()
  
  close_threshold_dB:update()
  close_threshold_dB:draw_label()
  close_threshold_dB:draw_value()
  
  hold_sl:update()
  hold_sl:draw_label()
  hold_sl:draw_value()
  
  ng_floor_sl:update()
  ng_floor_sl:draw_label()
  local ng_floor_sl_dB = 20*log10(ng_floor_sl.val)
  --[[
  if ng_floor_sl_dB < -150 then
    ng_floor_sl_dB = -1000
  end
  --]]
  ng_floor_sl:draw_value(nil,nil,3, ng_floor_sl_dB)
  
  
  gfx.x = points_per_second.x1
  gfx.y = points_per_second.y1 - gfx.texth-2
  gfx.printf("Compressor:")
  
  points_per_second:update()
  points_per_second:draw_label()
  points_per_second.val = floor(points_per_second.val + 0.5)
  points_per_second:draw_value(nil,nil,0)
  ---[[
  gain_dB_sl:update()
  gain_dB_sl:draw_label()
  gain_dB_sl:draw_value()
  
  
  comp_threshold_sl:update()
  comp_threshold_sl:draw_label()
  comp_threshold_sl:draw_value()
  
  
  --[[
  exp_factor:update()
  exp_factor:draw_label()
  exp_factor:draw_value()  
  
  multiplier:update()
  multiplier:draw_label()
  multiplier:draw_value()
  --]]
  comp_sl:update()
  comp_sl:draw_label()
  comp_sl:draw_value()
  
  gfx.x = 120
  gfx.y = gfx.texth*3

  if mouse.cap(mouse.LB) and mouse.last_LMB_state == false then
    mouse.last_LMB_state = true
    if array_created == true then
      array_created = false
      --last_comp_sl_val = comp_sl.val
    end
  end
  
  -- add undo point if slider value has changed
  if add_undo_point == true and mouse.cap() == 0 then
    reaper.Undo_OnStateChangeEx("Compress or expand envelope points", -1, -1)
    add_undo_point = false
  end 
  
  last_RMB_state = RMB_state
  
  --if update then gfx.update() end
  gfx.update()
  if gfx.getchar() >= 0 then reaper.defer(main) end
end



init()
main()

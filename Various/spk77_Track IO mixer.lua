--[[
 * Lua script for Cockos REAPER
 * ReaScript Name: Track IO mixer
 * Author: spk77
 * Author URI: http://forum.cockos.com/member.php?u=49553
 * Forum Thread URI: http://forum.cockos.com/showthread.php?t=168777
 * Licence: GPL v3
 * Version: 0.2016.06.25
 * Provides: spk77_Track IO mixer/*.{lua,png}
--]]

-- Initialize some variables
local tr = {} -- track data table
local rt = {} -- routing data table
local rc_menu = {} -- right click menu table
local slider_context_menu = {} --slider context menu (right click)
--local track_id = nil
local last_track = nil
local num_ios = 0
local last_num_ios = 0

local last_gfx_w = 0
local last_gfx_h = 0

local last_mouse_cap = -1

------------------------------------------------------------------------------
-- GUI table (+user settings) --
------------------------------------------------------------------------------
local gui = {}
gui.settings = {}
gui.settings.image_index = 1
gui.last_w = 0
gui.last_h = 0

gui.scale = 1

gui.last_touched_slider = {}
gui.add_undo_point = false
gui.over_ride_undo = false
        
--gui.w_changed = function () return gfx.w ~= last_gfx_w end
--gui.h_changed = function () return gfx.h ~= last_gfx_h end

-------------------
-- USER SETTINGS --
-------------------

-- Font colors (use values from 0.0 to 1.0):
-- Track name
gui.track_name_r = 0.8 
gui.track_name_g = 0.8
gui.track_name_b = 0.2
gui.track_name_a = 0.8

-- receives
gui.receive_name_r = 1
gui.receive_name_g = 0.5
gui.receive_name_b = 0
gui.receive_name_a = 0.8

-- hardware outs
gui.hw_out_name_r = 0
gui.hw_out_name_g = 1
gui.hw_out_name_b = 0.5
gui.hw_out_name_a = 0.8

-- sends
gui.send_name_r = 0
gui.send_name_g = 1
gui.send_name_b = 1
gui.send_name_a = 0.8

-- Initial GUI width/height
gui.width = 250
gui.height = 400
               
gui.settings.docker_id = 0          -- try 0, 1, 257, 513, 769, 1027, 1281, 1537 etc.
--gui.settings.knob_draw_x = 10     -- draw start x-pos for knobs/sliders
--gui.settings.knob_draw_y = 10     -- draw start y-pos for knobs/sliders

gui.settings.font_size = 15         -- font size for names
gui.settings.spacing = 0           -- spacing between knobs/sliders
gui.settings.io_type_spacing = 10   -- additional spacing between receives/sends/hw outs
gui.settings.lock_to_track = false  -- false = IO mixer follows track selection
gui.show_receives = true            -- show "receive" knobs/sliders
gui.show_hw_outs = true             -- show "hardware out" knobs/sliders
gui.show_sends = true               -- show "send" knobs/sliders

gui.show_MIDI_receives = true       
gui.show_MIDI_sends = true          

-- Mouse drag settings --
-- "gui.slider_drag_sensitivity" changes linearly if...
--  ...GUI width > "gui.slider_drag_sensitivity_min_w and GUI width <= gui.slider_drag_sensitivity_max_w"
gui.slider_drag_sensitivity_max_val = 1    -- mouse is moved by 1 pixel -> slider thumb is moved by 1 pixel
gui.slider_drag_sensitivity_min_val = 0.2  -- mouse is moved by 1 pixel -> slider thumb is moved by 0.2 pixel
gui.slider_drag_sensitivity_max_w = 600    -- 
gui.slider_drag_sensitivity_min_w = 124    -- min size of a script gfx window seems to be 124
gui.slider_drag_sensitivity = gui.slider_drag_sensitivity_max_val

--------------------------
-- END OF USER SETTINGS --
--------------------------




------------------------------------------------------------------------------
-- "msg" function
------------------------------------------------------------------------------
function msg(m)
  return reaper.ShowConsoleMsg(tostring(m) .. "\n")
end


------------------------------------------------------------------------------
-- "Get script path" function
------------------------------------------------------------------------------
function get_script_path()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  return script_path
end

------------------------------------------------------------------------------
-- "Get file separator" function
------------------------------------------------------------------------------
function get_file_separator()
  local OS = reaper.GetOS()
  if OS ~= "Win32" and OS ~= "Win64" then
    return "/"
  end
  return "\\"
end


------------------------------------------------------------------------------
-- Import modules and initialize tables --
------------------------------------------------------------------------------
-- get "script path"
local script_path = get_script_path() .. "spk77_Track IO mixer" .. get_file_separator()
--msg(script_path)

-- modify "package.path"
package.path = package.path .. ";" .. script_path .. "?.lua"
--msg(package.path)

-- Import files ("classes", functions etc.)-----------------
require "spk77_class_function" -- import "base class"
local mouse = require "spk77_mouse_function"
mouse.last_x, mouse.last_y = gfx.mouse_x, gfx.mouse_x
--]=]

-- Import functions from "Slider class"  
local slider_class = require "spk77_slider class_function" -- import "slider class"
local slider_table = slider_class.sliders
local clear_slider_table = slider_class.clear_slider_table -- (function from "slider class")
local get_last_touched = slider_class.get_last_touched -- (function from "slider class")
local create_slider = slider_class.Slider -- this function creates a slider instance


-- Import menu class
local menu_class = require "spk77_menu class_function"


------------------------------------------------------------------------------
-- "Init" function
------------------------------------------------------------------------------
function init()
  -- Start the mainloop
  mainloop()
end


                     
-- /////////////////////////////////////////////////////////


-- Image_table (add more knobs here)
local image_file_table = {
            --{image_path = script_path .. "SPK77 test knob 01 64x64.png", fr_count = 128},
            {image_path = script_path .. "spk77_volthumb_47x21.png", fr_count = 1}
            --{image_path = script_path .. "mcp_volthumb_96x43.png", fr_count = 1}
            --{image_path = script_path .. "mcp_volthumb_yellow.png", fr_count = 1}
            
            --[[ Knobs are disabled at the moment
            {image_path = script_path .. "Hopi sweep knob 01 32x32.png", fr_count = 108},     -- 3456 x 32 pixels (108 frames)
            {image_path = script_path .. "Hopi sweep knob 01 64x64.png", fr_count = 128},     -- 8192 x 64 pixels
            {image_path = script_path .. "Hopi sweep knob 02 64x64.png", fr_count = 128},     -- 8192 x 64 pixels
            {image_path = script_path .. "Hopi sweep knob 03 64x64.png", fr_count = 128},     -- 8192 x 64 pixels
            {image_path = script_path .. "Hopi sweep knob 05 32x32.png", fr_count = 128},
            {image_path = script_path .. "Hopi sweep knob 03 (modded by SPK77) 32x32.png", fr_count = 128},
            {image_path = script_path .. "Hopi sweep knob 03b 32x32.png", fr_count = 128}
            --]]
          }


------------------------------------------------------------------------------
-- Load images and get dimensions func
------------------------------------------------------------------------------
-- This function creates a table from valid filenames/files --
--   and "stores" the images to REAPER's image slots
function get_image_dimensions(image_file_table)
  local t = {}
  local h = 0 -- counter for valid handles
  for i=1, #image_file_table do
    -- load image from filename (REAPER has 128 "slots" for images (0..127)
    local handle = gfx.loadimg(h, image_file_table[i].image_path)
    local fr_count = image_file_table[i].fr_count
    if handle > -1 then 
      h = h + 1
      t[h] = {}
      t[h].handle = handle
      t[h].full_w, t[h].full_h = gfx.getimgdim(t[h].handle)
      t[h].frame_w = t[h].full_w / fr_count
      t[h].frame_h = t[h].full_h -- works for now (horizontal orientation)
      t[h].fr_count = fr_count
    end
  end
  return t
end


------------------------------------------------------------------------------
-- Initialize GUI --
------------------------------------------------------------------------------
gfx.init("", gui.width, gui.height, gui.settings.docker_id)
gfx.setfont(1,"Arial", gui.settings.font_size)
gfx.clear = 3355443  -- matches with "FUSION: Pro&Clean Theme :: BETA 01" http://forum.cockos.com/showthread.php?t=155329
                     -- (Double click in ReaScript IDE to open the link)

-- Slider drawing positions 
gui.slider_start_x = 10
gui.slider_start_y = 5*gfx.texth

-- (These are for vertical scrolling):
--gui.sliders_x = 10
--gui.sliders_y = 10
--gui.sliders_w = gfx.w
--gui.sliders_h = gfx.h

gui.x, gui.last_x = gui.slider_start_x, gui.slider_start_x
gui.y, gui.last_y  = gui.slider_start_y, gui.slider_start_y
--gui.dx, gui.dy = 0, 0

local get_sel_track = function () return reaper.GetSelectedTrack(0,0) end

-- "Smoothing/scaling" functions
local vol_to_slider = function (vol) return (vol*4)^(1/4) end
local slider_to_vol = function (slider_val) return slider_val^4/4 end
------------------------------------------------------------------------------


local image_table = get_image_dimensions(image_file_table)
--local Pr = require "Reaper project" -- import "Project class"
local Track = require "spk77_reaper track_function" -- import "Track class"

local log10 = function(val) return math.log(val,10) end
local vol_max = 4--3.9810717055349727


---[[----------------------------------------------------------------------------
-- "Reset last touched slider to default value" function
------------------------------------------------------------------------------
-- reset last touched slider
function reset_slider()
  local lt = gui.last_touched_slider
  if next(gui.last_touched_slider) ~= nil then 
    reaper.SetTrackSendUIVol(tr.id, lt.id, 1, 0)
  end
end 
--]]


function create_menu()
  -- Create right click menu
  rc_menu = {}
  rc_menu = menu_class.create_menu("rc_menu")
  
  -- "Lock to track" + separator ("|" at the end of label adds a separator)   
  local lock = rc_menu:add_item(
                 { 
                   label = "Lock to selected track|",
                   toggleable = true,
                   selected = gui.settings.lock_to_track
  
                 }
               )
  -- This function is called when "Lock to track" -menuitem is clicked
  lock.command = function()
                   gui.settings.lock_to_track = not gui.settings.lock_to_track
                   ----slider_table = create_slider_pos_table(10, 5*gfx.texth, tr)
                   if not gui.settings.lock_to_track then
                     --tr = Track(track_id)
                     --tr:get_name()
                   end
                 end
  
  -- "Show receives"             
  local show_receives = 
           rc_menu:add_item(
             {label = "Show receives", toggleable = true, selected = gui.show_receives}
           )
                           
  show_receives.command = 
                 function()
                   gui.show_receives = not gui.show_receives
                   gui.slider_start_y = 5*gfx.texth
                 end 
  
  -- "Show hardware outs"               
  local show_hw_outs = 
           rc_menu:add_item({label = "Show hardware outs", toggleable = true, selected = gui.show_hw_outs})
                           
  show_hw_outs.command = 
                 function()
                   gui.show_hw_outs = not gui.show_hw_outs
                   gui.slider_start_y = 5*gfx.texth
                 end
                 
  -- "Show sends" + separator ("|" at the end of label adds a separator)    
  local show_sends = 
           rc_menu:add_item({label = "Show sends|", toggleable = true, selected = gui.show_sends})
                           
  show_sends.command = 
                 function()
                   gui.show_sends = not gui.show_sends
                   gui.slider_start_y = 5*gfx.texth
                 end
  -- Add submenu               
  rc_menu:add_item({label = ">Track list"})
  
  -- Add first submenu item ("open master track in mixer")
  local master = rc_menu:add_item({label = "MASTER"})
  master.track = reaper.GetMasterTrack(0)
  master.active = reaper.GetMasterTrack(0) ~= tr.id
  if not master.active then
    master.selected = true
  end
  master.command = 
      function()
        OnTrackSelectionChange(reaper.GetMasterTrack(0))
      end
      
  -- Add all track names to the submenu 
  for i=1, reaper.CountTracks(0) do
    --if i==1 then
    local track = reaper.GetTrack(0, i-1)
    local tr_name = ""
    if reaper.GetTrackNumSends(track, -1) + reaper.GetTrackNumSends(track, 0) + reaper.GetTrackNumSends(track, 1) ~= 0 then
      
      local retval, tr_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
      if not retval or tr_name == "" then tr_name = "Track " .. tostring(i) end
      
      local curr_item = rc_menu:add_item({label = tr_name})
      curr_item.active = track ~= tr.id
      if not curr_item.active then
        curr_item.selected = true
      end
      
      --curr_item.label = tr_name
      curr_item.track = track
      
      curr_item.command = 
          function()
            local track = rc_menu:get_item_from_id(rc_menu.val).track
            OnTrackSelectionChange(track)
          end
    end
    
    
    if i == reaper.CountTracks(0) then
      rc_menu.items[#rc_menu.items].label = "<" .. rc_menu.items[#rc_menu.items].label
    end
  end
  
  --rc_menu.items[#rc_menu.items].label = "|"-- .. rc_menu[#rc_menu].label
  -- Add submenu               
  rc_menu:add_item({label = ">Options"})
  -- Add submenu 
  --rc_menu:add_item({label = ">Track list"})
  local show_MIDI_receives = rc_menu:add_item({label = "Show MIDI receives", toggleable = true, selected = gui.show_MIDI_receives})
  
  show_MIDI_receives.command = 
                 function()
                   gui.show_MIDI_receives = not gui.show_MIDI_receives
                   gui.slider_start_y = 5*gfx.texth
                 end
  show_MIDI_sends = rc_menu:add_item({label = "Show MIDI sends", toggleable = true, selected = gui.show_MIDI_sends})
  
  show_MIDI_sends.command = 
                 function()
                   gui.show_MIDI_sends = not gui.show_MIDI_sends
                   gui.slider_start_y = 5*gfx.texth
                 end
  --reaper.BR_GetSetTrackSendInfo(MediaTrack track, integer category, integer sendidx, string parmname, boolean setNewValue, number newValue)
  --reaper.BR_GetSetTrackSendInfo(MediaTrack track, integer category, integer sendidx, string parmname, boolean setNewValue, number newValue)
  --end
end



function create_slider_context_menu()
  -- Create right click menu
  slider_context_menu = {}
  slider_context_menu = menu_class.create_menu("slider_context_menu")
  
  -- "Open track in mixer" + separator ("|" at the end of label adds a separator)   
  local go_to = slider_context_menu:add_item(
                 { 
                   label = "Open in mixer"
                 }
               )
               
 
  -- This function is called when "go_to" -menuitem is clicked
  go_to.command = 
    function()
      local lt = gui.last_touched_slider
      local category = 0 -- category is <0 for receives, 0=sends
      -- trackType determines which track is returned (0=source track, 1=destination track)
      local index = lt.id - reaper.GetTrackNumSends(tr.id, 1) -- note to self: "lt.id - num hardware outs"
      local track_type = 1
      if lt.id < 0 then
        category = -1
        track_type = 0
        index = math.abs(lt.id) - 1 -- sendidx is zero-based
      end
      local track = reaper.BR_GetMediaTrackSendInfo_Track(tr.id, category, index, track_type)
      OnTrackSelectionChange(track) -- update track object
    end
    
    
    
  
end
------------------------------------------------------------------------------
-- "OnMouseDown" function
------------------------------------------------------------------------------
function OnMouseDown(x, y, mouse_cap)
  gui.last_touched_slider = get_last_touched()
  --mouse.capcnt = 0
  --gui.last_touched_slider = slider_class.last_touched
  
  -- Left mouse button clicked
  if mouse.LMB_state and next(gui.last_touched_slider) ~= nil then
    --msg("LMB down")
    mouse.ox_l, mouse.oy_l = x, y
    if gfx.mouse_cap == 5 then -- ctrl + lmb
      slider_class.last_touched:set_to_default_value()
    elseif gfx.mouse_cap == 9 then -- shift + lmb
      reaper.ToggleTrackSendUIMute(tr.id, gui.last_touched_slider.id)
      gui.over_ride_undo = true
    elseif gfx.mouse_cap == 17 then
    --end
    
    --[[
    elseif gfx.mouse_cap == xx then  
      local last_touched_sl_type = gui.last_touched_slider.send_type
      for i=1, #slider_table do
        local curr_sl = slider_table[i]
        if last_touched_sl_type == curr_sl.send_type then
          curr_sl._mouse_LMB_state = true
        end
      end
      --]]
    end
  
  -- Right mouse button clicked (not on slider)
  elseif mouse.RMB_state then
    mouse.ox_r, mouse.oy_r = x, y
    gui.last_x = gui.x
    gui.last_y = gui.y
    -- store right click y pos of first slider
    --gui.slider_start_y = slider_table[1].y1
    -- store right click y pos (this is needed when the "vertical scroll position" is calculated)
    gui.sliders_y = mouse.oy_r
    
    
    --msg("RMB down")
    if next(gui.last_touched_slider) == nil then
      create_menu()
      rc_menu:show(x, y)
      --msg(rc_menu.items_str)
    elseif gui.last_touched_slider.send_type ~= 0 then --(if slider is not hw out)
      create_slider_context_menu()
      slider_context_menu:show(x, y)
    end
    
  end
end


------------------------------------------------------------------------------
-- "OnMouseDoubleClick" function
------------------------------------------------------------------------------
function OnMouseDoubleClick(x, y, mouse_cap)
end


------------------------------------------------------------------------------
-- "OnMouseMove" function
------------------------------------------------------------------------------
function OnMouseMove(x, y, mouse_cap, track_id)
  
  -- handle mouse move here, use mouse.down and mouse.capcnt
  if gfx.mouse_cap&1 == 1 and next(gui.last_touched_slider) ~= nil then
 
      --msg("LMB down+move")
    local last_touched_sl_type = gui.last_touched_slider.send_type
    mouse.dx = gfx.mouse_x - mouse.ox_l
    mouse.dy = gfx.mouse_y - mouse.oy_l
    local sl = gui.last_touched_slider
    reaper.SetTrackSendUIVol(tr.id, sl.id, slider_to_vol(0.5*sl.val), 0)
    
  --[[  
  elseif gfx.mouse_cap&2 == 2 then 
    --msg("RMB down+move")
    local dy = gfx.mouse_y - gui.sliders_y -- for vertical scroll
    mouse.dx = gfx.mouse_x - mouse.ox_r
    mouse.dy = gfx.mouse_y - mouse.oy_r
    if slider_table[1].y2 + dy > gfx.h then 
      dy = 0
    elseif slider_table[#slider_table].y2 + dy < gui.slider_start_y then 
      dy = 0
    end
    for i=1, #slider_table do
      local sl = slider_table[i]
      local sl_dy = gui.slider_start_y - slider_table[i].y1
      sl.y1 = sl.y1 + dy
      sl.y2 = sl.y1 + sl.h
      sl.hit_zone_y1 = sl.hit_zone_y1 + dy
    end
    gui.sliders_y = gfx.mouse_y
  --]]
  end
  
  mouse.last_x, mouse.last_y = x, y
  --mouse.capcnt = mouse.capcnt + 1
  if next(gui.last_touched_slider) ~= nil then -- is table empty?
    if gui.add_undo_point == false then 
      gui.add_undo_point = true 
    end
  end
end

------------------------------------------------------------------------------
-- OnMouseUp func
------------------------------------------------------------------------------
function OnMouseUp(x, y)
  --msg("mouse up")
  -- Last mouse cap is alt+LMB
  if last_mouse_cap == 17 and next(gui.last_touched_slider) ~= nil then
    local sl = gui.last_touched_slider
    sl.pos = sl.last_pos
    sl.val = sl.last_val
    reaper.SetTrackSendUIVol(tr.id, sl.id, slider_to_vol(0.5*sl.last_val), 0)
    gui.over_ride_undo = true
  end
  
  slider_class.last_touched = {}
  mouse.uptime = os.clock()
  mouse.dx = 0
  mouse.dy = 0
  --mouse.lb_down = false
  --mouse.lb_up = true
  mouse.last_LMB_state = false
  mouse.last_RMB_state = false
  --sl:update()
  gui.last_touched_slider = {}
  --msg("LMB up")
 
  if gui.add_undo_point == true then
    if not gui.over_ride_undo then
      reaper.Undo_OnStateChangeEx("Adjust track send volume", -1, -1)
    else
      gui.over_ride_undo = false
    end
    gui.add_undo_point = false
  end
end


------------------------------------------------------------------------------
-- "Vertical scroll" function
------------------------------------------------------------------------------
function vertical_scroll(dy, is_mouse_wheel)
  if #slider_table == 0 then
    return
  end
  if slider_table[1].y2 + dy > gfx.h - 5 then-- first slider is at end of gfx window
    dy = 0
  elseif slider_table[#slider_table].y1 + dy < 0 + 50 then -- last slider is at start of gfx window
    dy = 0
  end

  local gui_start_y = 0
  local gui_end_y = gfx.h
  for i=1, #slider_table do
    local sl = slider_table[i]
    local sl_dy = gui.slider_start_y - slider_table[i].y1
 
    sl.y1 = sl.y1 + dy
    sl.y2 = sl.y1 + sl.h
    sl.hit_zone_y1 = sl.hit_zone_y1 + dy
    if sl.y1 > gui_end_y or sl.y1 < 50 then
      sl.show = false
    else
      sl.show = true
    end
  end
  dy = 0
  gui.slider_start_y = slider_table[1].y1
  gui.sliders_y = gfx.mouse_y
end


------------------------------------------------------------------------------
-- "OnGuiResize" function
------------------------------------------------------------------------------
function OnGuiResize()
  -- GUI has been resized
  if #slider_table > 0 then
    create_slider_pos_table(gui.slider_start_x, slider_table[1].y1)
  end
  gui.last_gfx_w = gfx.w
  gui.last_gfx_w = gfx.h
end


------------------------------------------------------------------------------
-- "Draw text" function
------------------------------------------------------------------------------
function draw_text(x, y, text, r, g, b, a)
  gfx.x = x
  gfx.y = y
  gfx.r = r or gfx.r
  gfx.g = g or gfx.g
  gfx.b = b or gfx.b
  gfx.a = a or gfx.a --alpha or 1
  gfx.printf(text)
end


------------------------------------------------------------------------------
-- "Create slider position table" function
------------------------------------------------------------------------------
function create_slider_pos_table(start_x, start_y)
  clear_slider_table()
  local image_index = gui.settings.image_index
  local i_t = image_table
  
  local h = i_t[image_index].handle
  local fr_count = i_t[image_index].fr_count
  local fr_w = i_t[image_index].frame_w * gui.scale
  local fr_h = i_t[image_index].frame_h * gui.scale
  local x = start_x
  local y = start_y
  
  local sens_max_w = gui.slider_drag_sensitivity_max_w
  local sens_min_w = gui.slider_drag_sensitivity_min_w
  local sens_max_val = gui.slider_drag_sensitivity_max_val
  local sens_min_val = gui.slider_drag_sensitivity_min_val
  local w = gfx.w
  local last_send_type 
  for i=1, #rt do
    local sl = create_slider()--Slider()
    --local vol_max = 3.9810717055349727
    
    -- Change "drag_sensitivity" dynamically depending on GUI width
    if gfx.w <= sens_max_w then 
      sl.drag_sensitivity = sens_min_val + (sens_max_val-sens_min_val)*(gfx.w-sens_min_w)/(sens_max_w-sens_min_w)
      ----sl.drag_sensitivity = gfx.w/sens_max_w
    else
      sl.drag_sensitivity = gui.slider_drag_sensitivity  -- (configured in "user settings")
    end
    if w < 124 then
      w = 124
    end
    sl:set_area(x, y, w - 58 - fr_w, fr_h)
    --sl:set_hit_zone(x, y, fr_w, fr_h)
    sl:set_hit_zone(x, y, w -20, fr_h)
    sl:show_foreground(false)
    sl:show_background(false)
    sl:show_hitzone(true)
    sl:set_hz_color(0.1,0.1,0.1,0.15)
    
    sl.show_value = false
    sl.show_label = false
    
    
    --sl.last_val = sl.val
    sl.default_val = 2.8284271247462
    sl.min_val = 0
    sl.max_val = vol_max--0.5*vol_max
    sl.lbl = rt[i].name
    sl.help_text = ""
    sl.id = rt[i].index
    
    
    sl.send_type = rt[i].type
    
    if i < #rt and sl.send_type ~= rt[i+1].type then
      y = y + gui.settings.io_type_spacing
      --gfx.line(gui.x, curr_sl.y2+2, gfx.w-10, curr_sl.y2+2)
    end
    y = y + fr_h + gfx.texth + gui.settings.spacing
    last_send_type = sl.send_type
  end
end


------------------------------------------------------------------------------
-- "Draw sliders" func
------------------------------------------------------------------------------
function draw_knobs()
  local image_index = gui.settings.image_index
  local i_t = image_table
  local h = i_t[image_index].handle
  local fr_count = i_t[image_index].fr_count
  local fr_w = i_t[image_index].frame_w -- * gui.scale
  local fr_h = i_t[image_index].frame_h -- * gui.scale
  local text_h = gfx.texth
  --gfx.set(0,0.7,0.7,0.9)
  --gfx.a = 0.2
  --gfx.set(0.8,0.8,0.8,1)
  --gfx.roundrect(6,gui.slider_start_y - gfx.texth-2,gfx.w-14,100+2,5,1)
  gfx.a = 0.8
  for i=1, #slider_table do
    --gfx.set(0.8,0.8,0.8,0.8)
    local curr_sl = slider_table[i]
    local srcx = curr_sl.pos
    curr_sl.y1 = curr_sl.y1-- + gui.dy --gui.slider_start_y
    --gfx.y = curr_sl.y1+gui.y -- * gui.scale
    
    
    if curr_sl.y1-gfx.texth >= 30 then
      curr_sl:show_hitzone(true)
      curr_sl.show = true
      if curr_sl.send_type == -1 then
        gfx.set(gui.receive_name_r, gui.receive_name_g, gui.receive_name_b, gui.receive_name_a)
      elseif curr_sl.send_type == 0 then
        gfx.set(gui.hw_out_name_r, gui.hw_out_name_g, gui.hw_out_name_b, gui.hw_out_name_a)
      else
        gfx.set(gui.send_name_r, gui.send_name_g, gui.send_name_b, gui.send_name_a)
      end
      
      draw_text(curr_sl.x1, curr_sl.y1-gfx.texth, curr_sl.lbl) -- draw send/receive name
      gfx.x = curr_sl.pos--curr_sl.x1
      gfx.y = curr_sl.y1--* gui.scale
      if rt[i].mute then
        gfx.a = 0.5
      else
        gfx.a = 1
      end
      
      gfx.blit(  h,                 -- source
                 gui.scale,                 -- scale
                 0--1.5*3.14,                 -- rotation
                 --0.5*(-srcx+10),              -- srcx
                 --0,                 -- srcy
                 --gfx.w,--fr_w               -- srcw
                 --gfx.h--fr_w               -- srcw
      )
      
     
      local dB_val
      if rt[i].vol < 0.0000000001 then 
        dB_val = "-inf"
      else
        dB_val = 20*log10(rt[i].vol)
        if dB_val > 0 then
          dB_val = string.format("+%.1f", tostring(dB_val))
        else
          dB_val = string.format("%.1f", tostring(dB_val))
        end
      end
      local w = gfx.w
      if w < 124 then
        w = 124
      end
      draw_text(curr_sl.hit_zone_x2-37, curr_sl.y1 + 0.5*(curr_sl.h-text_h), dB_val, 1, 1, 0, 0.9) -- draw dB value
      --draw_text(gfx.w - 40, curr_sl.y1, dB_val) -- draw dB value
      --curr_sl:draw_label(curr_sl.x1, curr_sl.y1)
    else
      curr_sl.show = false
      curr_sl:show_hitzone(false)
    end
    --elseif curr_sl.y1 < 30 then
      
    --  gfx.a = 0 end
    
    --gfx.set(1,1,1,1)
    
    
  end
end
------------------------------------------------------------------------------


function create_track_object(track_id)
  return Track(track_id) -- create a new "Track" instance (see "Reaper track.lua")
end  

function OnTrackSelectionChange(track_id)
  tr = create_track_object(track_id)
  tr:get_name()
  get_track_routing(tr) -- updates the "rt" table
  gui.slider_start_y = 5*gfx.texth
  create_slider_pos_table(gui.slider_start_x, gui.slider_start_y)
  return tr
end


------------------------------------------------------------------------------
-- Draw GUI func
------------------------------------------------------------------------------
function draw_gui()
  -- Draw track label
  draw_text(gui.x, gui.settings.font_size, tr.name, gui.track_name_r, gui.track_name_g, 
              gui.track_name_b, gui.track_name_a)
  
  -- If locked to a track - draw "Locked" text
  gfx.a = 0.4
  local io_label_y = gfx.y+3*gfx.texth 
  ----gfx.line(gui.x,gfx.y+gfx.texth,gfx.w-10,gfx.y+gfx.texth)
  if gui.settings.lock_to_track then
    --gfx.setfont(1,"Arial", 0.8*gui.settings.font_size)
    draw_text(10, 0, "(Locked to track)")
    --gfx.setfont(1,"Arial", gui.settings.font_size)
  end
  
  -- Update/(draw) sliders
  for i=1, #slider_table do
    local sl = slider_table[i]
    
    if sl.use_images and sl.show then
    
      --blit(sl)
    end
    
    --sl:update()
  end
  gfx.a = 1
  
  -- Draw knob images (get dimensions/positions from "slider_table")
  draw_knobs()

end

--[[-----------------------------------------------------------------------------
-- "blit" function (Draw sliders)
------------------------------------------------------------------------------
function blit(sl)
  local image_index = gui.settings.image_index
  local i_t = image_table
  local h = i_t[image_index].handle
  local fr_count = i_t[image_index].fr_count
  local fr_w = i_t[image_index].frame_w -- * gui.scale
  local fr_h = i_t[image_index].frame_h -- * gui.scale
  
  --gfx.set(0,0.7,0.7,0.9) 
  --for i=1, #slider_table do
    local curr_sl = sl
    local srcx = curr_sl.pos
    curr_sl.y1 = curr_sl.y1+gui.dy--gui.slider_start_y
    
    
     -- if curr_sl.use_images then
       -- draw_text(curr_sl.x1, curr_sl.y1-gfx.texth, curr_sl.lbl) -- draw send/receive name
      --end
      gfx.x = curr_sl.pos--curr_sl.x1
      gfx.y = curr_sl.y1--* gui.scale
      gfx.a = 1
      
      gfx.blit(  h,                 -- source
                 gui.scale,                 -- scale
                 0--1.5*3.14,                 -- rotation
                 --0.5*(-srcx+10),              -- srcx
                 --0,                 -- srcy
                 --gfx.w,--fr_w               -- srcw
                 --gfx.h--fr_w               -- srcw
      )
      local val_str = string.format("%.3f", curr_sl.val)
      curr_sl.val_w = gfx.measurestr(val_str)
      gfx.set(curr_sl.val_r, curr_sl.val_g, curr_sl.val_b, curr_sl.val_a)
      gfx.x = gfx.w - 60
      gfx.y = curr_sl.y1 + 0.5*curr_sl.h - 0.5*gfx.texth
      gfx.printf(val_str)
    
    --end
  --end
end
--]]


------------------------------------------------------------------------------
-- "Get track routing" function
------------------------------------------------------------------------------
function get_track_routing(tr) -- "tr" is a track object (see "Reaper track.lua")
  -- Collect track routing data
  rt = {}
  
  local num_ios = 0
  if gui.show_receives then
    tr:get_receives() --see "Reaper track.lua"
    for i=1, #tr.receives do
      tr.receives[i].type = -1
      rt[#rt+1] = tr.receives[i]
    end
    num_ios = num_ios + #tr.receives
  end
  
  if gui.show_hw_outs then
    tr:get_hw_outs() --see "Reaper track.lua"
    for i=1, #tr.hw_outs do
      tr.hw_outs[i].type = 0
      rt[#rt+1] = tr.hw_outs[i]
    end
    num_ios = num_ios + #tr.hw_outs
  end
  if gui.show_sends then
    tr:get_sends() --see "Reaper track.lua"
    for i=1, #tr.sends do
      tr.sends[i].type = 1
      rt[#rt+1] = tr.sends[i]
    end
    num_ios = num_ios + #tr.sends
  end
  return num_ios
end  


------------------------------------------------------------------------------
-- "Mainloop" function
------------------------------------------------------------------------------
function mainloop()
  --dock_state = gfx.dock(-1)
  local mouse_cap = gfx.mouse_cap
  mouse.LMB_state = mouse_cap&1 == 1
  mouse.RMB_state = mouse_cap&2 == 2
  
  local gfx_w = gfx.w
  local gfx_h = gfx.h
  
  local track_id = get_sel_track()
  if track_id == nil then
    track_id = reaper.GetMasterTrack(0)
  end

  if not gui.settings.lock_to_track and track_id ~= last_track then -- selected track has changed
    OnTrackSelectionChange(track_id)
    last_track = track_id
  elseif gfx_w ~= last_gfx_w or gfx_h ~= last_gfx_h then
    OnGuiResize()
  end
  
  -- Get track routing and update "rt" table (=routing table)
  num_ios = get_track_routing(tr)
  
  if num_ios ~= last_num_ios then
    create_slider_pos_table(gui.slider_start_x, gui.slider_start_y)
    last_num_ios = num_ios
  end
  
  if gfx.mouse_wheel ~= 0 then
    -- func desc: vertical_scroll(dy, is_mouse_wheel)
    vertical_scroll(gfx.mouse_wheel/4, true)
    gfx.mouse_wheel = 0
  end

  if not mouse.LMB_state then
    if #rt > 0 then
      for i=1, #rt do
        -- set slider value from REAPER if slider is not currently dragged by user
        if not slider_table[i]._mouse_LMB_state then
          if last_mouse_cap ~= 17 then
            slider_table[i].val = 2*(rt[i].vol*4)^(1/4)
          end
        end
      end
    end
  end
  
  for i=1, #slider_table do
    slider_table[i]:update()
  end
  
  -- This is from Schwa's GUI example
  local mx, my = gfx.mouse_x, gfx.mouse_y
  if mouse.LMB_state or mouse.RMB_state then
    if mouse.LMB_state and not mouse.last_LMB_state or mouse.RMB_state and not mouse.last_RMB_state then
      OnMouseDown(mx, my, mouse_cap)
    --end
      --[[
      if mouse.uptime and os.clock() - mouse.uptime < 0.15 then
        OnMouseDoubleClick(mx, my)
      end
      --]]
    elseif mx ~= mouse.last_x or my ~= mouse.last_y then
      OnMouseMove(mx, my, mouse_cap, track_id)
    end
  elseif mouse.last_LMB_state or mouse.last_RMB_state then
    OnMouseUp(mx, my, mouse_cap)
  end

  draw_gui()
  
  last_gfx_w = gfx.w
  last_gfx_h = gfx.h
  mouse.last_LMB_state = mouse.LMB_state
  mouse.last_RMB_state = mouse.RMB_state
  last_mouse_cap = mouse_cap
  
  gfx.update()
  if gfx.getchar() >= 0 then 
    reaper.defer(mainloop)
  end
end

init()



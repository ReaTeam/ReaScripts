-- @description Perfect Timing! - Audio Quantizer
-- @author 80icio
-- @version 0.27
-- @changelog
--   - Fixed graphic issue between mouse position indication vertical line and arrange window trigger lines
--   - Fixed arrange window trigger lines behaviour when tracks disappear in folder
-- @link Forum thread https://forum.cockos.com/showthread.php?t=288964
-- @about
--   # PERFECT TIMING! 
--   is a script for audio quantizing with advanced features.
--
--   * Fast transient analysis with 2 visualization options.
--   * Timesaving Grid Based detection.
--   * Multitrack and Multichannel analysis and editing.
--   * Hipass Lowpass filters and transient attack.
--   * Super fast quantizing + crossfading .
--   * Sensitivity and threshold Histogram.
--   * Low CPU consumption
--   * Multisized GUI
--   * Works with fixed lanes

--- This script is a re adaptation and re writing of  @Cool Mk Slicer 2 (80icio Mod)
--- Thanks to Cool for Mk Slicer, I mainly learnt coding LUA from his script
--- Thanks to amagalma 'Toggle show editing guide line on item under mouse cursor in Main Window' for letting me seee how to draw lines on the screen
--- Thanks to Nickstomp for export track group names
--- Thanks to _Stevie_ for testing at very early stages
--- Thanks to drummerboy, mtierney, MykRobinson for testing

-----------------------------vars vars vars!-----------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local r = reaper
local scriptname = 'Perfect Timing! - Audio Quantizer'

function msg (message, clear)
  if clear then r.ClearConsole() end
  r.ShowConsoleMsg(tostring(message)..'\n')
end
--[[
  local profiler = dofile(reaper.GetResourcePath() ..
    '/Scripts/ReaTeam Scripts/Development/cfillion_Lua profiler.lua')
  reaper.defer = profiler.defer
]]--

------------------------------check estensions---------------------------------
--[[
function Reaperversioncheck(str)
    local digit = str:match("%d")
    return tonumber(digit)
end

local reaperversion = Reaperversioncheck(r.GetAppVersion())
]]--

if not r.ImGui_GetBuiltinPath then
  r.ShowMessageBox("Please, install or update IMGUI extension from REAPACK.\nThanks!", "Ooops!", 0)
  r.ReaPack_BrowsePackages('ReaImGui: ReaScript binding for Dear ImGui')
  return -- ReaImGui is not present or pre-0.9
end

package.path = r.ImGui_GetBuiltinPath() .. '/?.lua'

local ImGui = require 'imgui' '0.9'

if r.APIExists( "JS_ReaScriptAPI_Version") then ------checkin JS ---------
  local version = r.JS_ReaScriptAPI_Version()
  if version < 1.002 then
    r.ShowMessageBox( "Installed JS_ReaScriptAPI version is v" .. version .. " and needs to be updated via REAPACK.\n\nPlease, update, restart Reaper and run the script again. Thanks!", "Ooops!", 0 )
    r.ReaPack_BrowsePackages('JS_ReaScriptAPI')
    return false
  end
else  
  r.ShowMessageBox( "Please, install JS_ReaScriptAPI via REAPACK.\nThanks!", "Ooops!", 0 )
  r.ReaPack_BrowsePackages('JS_ReaScriptAPI')
  return false
end

if  not r.APIExists("ULT_SetMediaItemNote") then ------------SWS check---------------
  r.ShowMessageBox("SWS/S&M extension required.\nPlease download The SWS/S&M extension from www.sws-extension.org.", "Ooops!", 0)
  return false 
end 

-----------------------------vars vars vars!-----------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local ctx = ImGui.CreateContext(scriptname)
local font_type = 'Arial'

local cyclecount = 0
local block_size = 1024
local time_limit = 5*60  
local thresh_min = 0.001
local sens_def = 100
local Wave = {}
local Gate_Gl = {}
local store_wavesum = {}
local items_to_analyze = {}
local sel_tracks_table = {}
local Histogram_tbl = {}
local keeptrue = {}
local thresh_table = {}
local thresh_histogram_table = {}
local visualizer_bounds = {}
local thresh_moving = 0

local edittrack = {}
local editgroup = {}
local sens_x, sens_y = 0, 0
local sens_w, sens_h = 0, 0

local sin = math.sin
local cos = math.cos
local abs  = math.abs
local min  = math.min
local max  = math.max
local sqrt = math.sqrt
local ceil  = math.ceil
local floor = math.floor   
local exp = math.exp
local logx = math.log
local huge = math.huge
local tan = math.tan
local pi = math.pi
local fmod = math.fmod

local filter_preset = 0
local page_select = 1
local radio_w_size = 1 
local m_window_width
local m_window_height
local visualizer_h = 0
local zoom_bounds_L, zoom_bounds_Total = 0,0
local dockid
local Highsens = 0
local waveform_zoom_gain = 1
local min_visualzer_rangeview = 1
local Visualizer_mode = 0
local waveform_zoom_h = 1
local h_zoom_center = 0
local samplesdifference = 0
local h_zoom_absolute_center = 0
local new_zoom_pos_range = 1
local new_zoom_pos_start = 0
local moving_h = 0
local a_bttn_state = 1

local Change_grid = false
local analyzing = false
local initfont = false
local h_zoom_dragging = false

local gain_v = 0
local sens_v = 5
local Thresh_v

local lowcut = 20
local hicut = 20000
local Rtrig_v
local LeadP_v
local Xfade_v 
local Sensitivity_v
local Qstrength_v 
local Qstrength_label = ""
local newpresetname = ''
local Offset_v
local Gtolerance_v
local Detect = 1
local attack_trans = 0

local Help_state = false
local AutoColor = true
local GridScan = true
local visualizer = false
local filter_on = false
local normalize_sens_scale = true
local Store_Par_Window = {}
local init_filter = '20,20000,0,0.0'
r.SetExtState(scriptname, 'Filter Preset' .. 0, init_filter,true)
local sel_tracks = 0
local mode = 1
---local min_rms_tbl = {0.15, 0.00}
local min_rms_tbl = {0.00, 0.00}
local min_rms = min_rms_tbl[1]

local filter_preset_list

local Grid_help = "Control your project Grid settings via the script.\nGrid settings are limited to 1/4 to 1/64."
local GridScan_help = "Grid Scan refines results by selecting only 1 transient per grid division, narrowing the research time window around it."
local EditTrk_help = "Select single tracks or track groups you want to edit the same as the analyzed audio."
local LeadingPad_help = "Leading Pad will anticipate the edit cut but leave every grid snap point on the correct position, to prevent editing artifacts and keep your transients far from x fades.\nSPLIT mode only"
local Xfade_help = "Set automatic Xfade length for smoothing out after split and quantize.\nSPLIT mode only."
local mode_help = "Split mode is for phase coherent multitrack quantizing like Drum quantizing. Warp is for stretch markers quantizing."
local Retrig_help = "Re-trigger Time prevents double triggering and re-triggering,\nrepresenting the minimum time where only a single transient can occur."
local Qstrength_help = "Quantize Strength determines the percentage of quantization applied to your audio. 100% aligns with the grid, lower values apply partial quantization."
local linecolor_help = "Change the color of detection lines in the main window. Lines can also be automatically colored for better visibility (see MENU)"
local Visualizer_help = "Visualizer displays the analyzed audio waveform in a new window, particularly useful when applying filters to observe waveform changes."
local lowcut_help = "Apply a Lowcut/High-pass filter to remove unwanted frequencies from the analyzed audio"
local hicut_help = "Apply a Hicut/Low-pass filter to remove unwanted frequencies from the analyzed audio"
local gain_help = "Adjust filter output gain"
local attack_help = "This setting makes your transients get louder/faster, use it when transients are soft and hard to detect."
local filter_help = "Engage the filter. Note: This may significantly slow down audio analysis."
local Crest_help = "Lower values to catch soft dynamics / slow transients.\nHigher values to catch only high dynamics / fast transients."
local Offset_help = "Adjust the time offset to shift transient detection forward or backward."
local Threshold_help = "Set threshold to your preference in order to avoid catching to many transients"
local Sensitivity_help = "Sensitivity Scale is based on loudness data of the detected transients. Higher values means to include softer transients."
local Visual_Navigation_help = "leftClick and Drag to zoom and navigate\nRight Click and Drag for horizontal scroll\nMousewheel down = zoom in\nMousewheel up = zoom out .\nUpArrow/DownArrow = zoom peaks in/out\nLeftArrow/RightArrow = Navigate Left and Right"

  

function str_to_bool(str)
    if str == nil then
        return false
    end
    return string.lower(str) == 'true'
end


function getsettings()
  Visualizer_mode = tonumber(r.GetExtState(scriptname,'Visualizer_mode') ) or 0 
  AutoColor = str_to_bool(r.GetExtState(scriptname,'AutoColor') )
  visualizer = str_to_bool(r.GetExtState(scriptname,'visualizer') )
  Help_state = str_to_bool(r.GetExtState(scriptname,'Help_state') )
  linecolor_v = tonumber(r.GetExtState(scriptname,'linecolor_v') ) or 0.5
  font_size = tonumber(r.GetExtState(scriptname,'font_size') ) or 16
  EditTrk_mode = tonumber(r.GetExtState(scriptname,'EditTrk_mode') ) or 0
  m_window_width = tonumber(r.GetExtState(scriptname,'m_window_width') ) or 1000
  m_window_height = tonumber(r.GetExtState(scriptname,'m_window_height') ) or 220
  dockid = tonumber(r.GetExtState(scriptname,'dockid') ) or 0
  Thresh_v = tonumber(r.GetExtState(scriptname,'Thresh_v') ) or -60
  Rtrig_v = tonumber(r.GetExtState(scriptname,'Rtrig_v') ) or 20
  LeadP_v = tonumber(r.GetExtState(scriptname,'LeadP_v') ) or 10
  Xfade_v = tonumber(r.GetExtState(scriptname,'Xfade_v') ) or 10
  Sensitivity_v = tonumber(r.GetExtState(scriptname,'Sensitivity_v') ) or 100
  sens_v = tonumber(r.GetExtState(scriptname,'sens_v') ) or 5
  mode = tonumber(r.GetExtState(scriptname,'mode') ) or 1
  Qstrength_v = tonumber(r.GetExtState(scriptname,'Qstrength_v') ) or 100
  Offset_v = tonumber(r.GetExtState(scriptname,'Offset_v') ) or -0.1
  Gtolerance_v = tonumber(r.GetExtState(scriptname,'Gtolerance_v') ) or 100
  
  if r.GetExtState(scriptname,'filter_preset_list') == '' then
    filter_preset_list = 'Init Filter,+Add Preset,'
  else
    filter_preset_list = tostring(r.GetExtState(scriptname,'filter_preset_list'))
  end
  local replacedString = filter_preset_list:gsub(",", "\0")
  filter_preset_list = replacedString
end

function initsettings() -----------initialize settings
  filter_preset = 0
  gain_v = 0
  Visualizer_mode = 0; r.SetExtState(scriptname,'Visualizer_mode', 0 ,true)
  AutoColor = true;  r.SetExtState(scriptname,'AutoColor', tostring(true) ,true)
  Rtrig_v = 20;  r.SetExtState(scriptname,'Rtrig_v', 20 ,true)
  linecolor_v = 0.5;  r.SetExtState(scriptname,'linecolor_v', 0.5 ,true)
  font_size = 16;  r.SetExtState(scriptname,'font_size', 16 ,true)
  EditTrk_mode = 0;  r.SetExtState(scriptname,'EditTrk_mode', 0 ,true)
  m_window_width = 1000;  r.SetExtState(scriptname,'m_window_width', 1000 ,true)
  m_window_height = 220;  r.SetExtState(scriptname,'m_window_height', 220 ,true)
  dockid = 0;  r.SetExtState(scriptname,'dockid', 0 ,true)
  Thresh_v = -60;  r.SetExtState(scriptname,'Thresh_v', -60 ,true)
  LeadP_v = 10;  r.SetExtState(scriptname,'LeadP_v', 10 ,true)
  Xfade_v = 10;  r.SetExtState(scriptname,'Xfade_v', 10 ,true)
  Sensitivity_v = 100;  r.SetExtState(scriptname,'Sensitivity_v', 100 ,true)
  sens_v = 5; r.SetExtState(scriptname,'sens_v', 5 ,true)
  mode = 1;  r.SetExtState(scriptname,'mode', 1 ,true)
  Qstrength_v = 100;  r.SetExtState(scriptname,'Qstrength_v', 100 ,true)
  Offset_v = -0.1;  r.SetExtState(scriptname,'Offset_v', -0.1 ,true)
  Gtolerance_v = 100;  r.SetExtState(scriptname,'Gtolerance_v', 100 ,true)
end

function AlwaysStoreatexit()
  r.SetExtState(scriptname,'AutoColor',tostring(AutoColor),true)
  r.SetExtState(scriptname,'visualizer',tostring(visualizer),true)
  r.SetExtState(scriptname,'Visualizer_mode',Visualizer_mode,true)
  r.SetExtState(scriptname,'font_size',font_size,true)
  r.SetExtState(scriptname,'EditTrk_mode',EditTrk_mode,true)
  r.SetExtState(scriptname,'m_window_width',m_window_width,true)
  r.SetExtState(scriptname,'m_window_height',m_window_height,true)
  r.SetExtState(scriptname,'mode', mode,true)
  r.SetExtState(scriptname,'dockid', dockid,true)
  r.SetExtState(scriptname,'Help_state',tostring(Help_state),true)
end

getsettings()---------get settings or initialize them

function RGBlinecolor(linecolor_v)
  local red, green, blue = ImGui.ColorConvertHSVtoRGB(linecolor_v, 1, 1 )
  linecolor = RGB(floor(red*255),floor(green*255) ,floor(blue*255) )
  return linecolor
end

local my_font = ImGui.CreateFont(font_type, font_size)
ImGui.Attach(ctx, my_font)

local my_font2 = ImGui.CreateFont(font_type, font_size -2)
ImGui.Attach(ctx, my_font2)

local Grid_mode
local grid_dist
local Swing, Swing_toggle
local Triplets
local Dotted

local color_button 
local Sensitivity_slider
local analyze_bttn
local analyze_bttn_state = {'Analyze Audio' , 'Analyzing...', 'Processing...'}
local SplitA_bttn
local Q_bttn
local Thresh_slider
local sensitivity_slider
local Gtolerance_slider
local Rtrig_slider
local check_itm = false
local Time_vs_Peak_mode = 0 

local lines = {}
local QN_lineTHICK = {}

function reset_param()
  check_itm = false
  reset_Histogram()
  movescreen = {}
  movescreen_prev = {}
  items_to_analyze = {}
  sel_tracks_table = {}
end

local NoIP = ImGui.SliderFlags_NoInput

local Grid_string = {'1 bar\0 1/2\0 1/4\0 1/8\0 1/16\0 1/32\0 1/64\0', '2/3 bar\0 1/3\0 1/6\0 1/12\0 1/24\0 1/48\0' }
local Visualizer_mode_table = 'MW & Visualizer\0MW or Visualizer\0'
local Grid_table = Grid_string[1]
local EditTrk_table = 'Edit Tracks \0Edit TrackGroups\0'
local mode_table = {'Split', 'Warp'}
--local Time_vs_Peak_mode_table = 'GS Peak Priority\0GS Time Priority\0'
-----------------------------ERRORS--------------------------------------------
local error_msg = 0
local error_msg_table = {'Please unselect midi items', 'Please unmute audio', 'Items Position / Length mismatch', 'Sample rate mismatch','Please select 1 Item per track'}
local first_sel_item_start, first_sel_item_end, first_sel_item_length

-----------------------------all 'bout GRID------------------------------------
local _, divis, Swing_on, Swing_Slider = r.GetSetProjectGrid(0, 0)
local store_divis, store_Swing_on, store_Swing_Slider = divis, Swing_on, Swing_Slider
local Swing_Slider_adapt = floor(Swing_Slider*100)
-------------------------------------------------------------------------------

-----------------------------FUNCTIONS-----------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


function givemetime()
  check_itm = false
  local timenow = r.time_precise()
  if timenow < time_gap then
    r.defer(givemetime)
    analyzing = true
  else
    return
    getitem()
  end
end

function givemetime2()
  local timenow = r.time_precise()
  if timenow < time_gap then
    r.defer(givemetime2)
    processing = true
  else
    return
    processing_audio()
  end
end
      
function OpenURL(url)
  r.CF_ShellExecute(url)
end

function IsEven(num)
  return num % 2 == 0
end

function getLowest(tbl)
  local low = huge
  local index
  for i, v in pairs(tbl) do
    if v < low then
    low = v
    index = i
    end
  end
  return index
end

function getHighest(tbl)
  local Hi = 0
  local index
  for i, v in pairs(tbl) do
    if v > Hi then
    Hi = v
    index = i
    end
  end
  return index
end

function count_string_pattern(inputString,pattern)
  local patternToFind = "\0"
  local count = 0
  inputString:gsub(patternToFind, function()
      count = count + 1
  end)
  return count
end

local ADDpreset = count_string_pattern(filter_preset_list,'\0')
--------------------color converters-----------------------

function HSV(h, s, v, a)
  local red, green, blue = ImGui.ColorConvertHSVtoRGB(h, s, v)
  return ImGui.ColorConvertDouble4ToU32(red, green, blue, a or 1.0)
end

function RGB(red,green,blue)
  return (((blue)&0xFF)|(((green)&0xFF)<<8)|(((red)&0xFF)<<16)|(0xFF<<24))
end

local linecolor = RGBlinecolor(linecolor_v)

---------------------reset to 0 functions-----------------------

function reset_edittracks()
  for i = 1, #edittrack do
    edittrack[i] = false 
    if not check_itm then keeptrue[i] = false end
  end
end

function reset_trkgroups()
  for i = 1, #editgroup do
    editgroup[i] = false 
  end
end

function reset_Histogram()
  for i=1, sens_def do
    Histogram_tbl[i] = 0
  end
end

---------------------------Get track group names functions------------------------------------

function GetGroupNameString(idx)
    return string.format('TRACK_GROUP_NAME:%d', idx)
end

function GetGroupName(idx)
    local retval, group_name_str = r.GetSetProjectInfo_String(0, GetGroupNameString(idx), '', false);
    assert(retval)
    return group_name_str
end

function GetGroupNames(table)
    local group_names = {}
    for i = 1, 64 do
        group_names[i] = GetGroupName(i)
    end
    return group_names
end

----------------------------Get Set Grid Functions--------------------------------------

function get_grid_from_proj()
   Dotted = (r.GetToggleCommandState(reaper.NamedCommandLookup('_SWS_AWTOGGLEDOTTED')))
   --if divis == 4 then Grid_mode = 0; r.GetSetProjectGrid(0, true, 1/4, Swing_on, Swing_Slider) ; Triplets = false  end 
   --if divis == 2 then Grid_mode = 0; r.GetSetProjectGrid(0, true, 1/4, Swing_on, Swing_Slider) ; Triplets = false  end
   --if divis == 1 then Grid_mode = 0; r.GetSetProjectGrid(0, true, 1/4, Swing_on, Swing_Slider) ; Triplets = false  end
   --if divis == 1/2 then Grid_mode = 0 ; r.GetSetProjectGrid(0, true, 1/4, Swing_on, Swing_Slider) ; Triplets = false  end
   if divis > 1 then Grid_mode = 0 ; r.GetSetProjectGrid(0, true, 1, Swing_on, Swing_Slider) ; Triplets = false  end
   if divis == 1 then Grid_mode = 0 ; Triplets = false end
   if divis == 2/3 then Grid_mode = 0 ; Triplets = true end
   if divis == 1/2 then Grid_mode = 1 ; Triplets = false end
   if divis == 1/3 then Grid_mode = 1 ; Triplets = true end
   if divis == 1/4 then Grid_mode = 2 ; Triplets = false end
   if divis == 1/6 then Grid_mode = 2 ; Triplets = true end
   if divis == 1/8 then Grid_mode = 3 ; Triplets = false end
   if divis == 1/12 then Grid_mode = 3 ; Triplets = true end
   if divis == 1/16 then Grid_mode = 4 ; Triplets = false end
   if divis == 1/24 then Grid_mode = 4 ; Triplets = true end
   if divis == 1/32 then Grid_mode = 5 ; Triplets = false end
   if divis == 1/48 then Grid_mode = 5 ; Triplets = true end
   if divis == 1/64 then Grid_mode = 6 ; Triplets = false end
   if divis < 1/64 then Grid_mode = 6 ; r.GetSetProjectGrid(0, true, 1/64, Swing_on, Swing_Slider) ; Triplets = false end
   if Triplets == true then Grid_table = Grid_string[2] else Grid_table = Grid_string[1] end
   _, divis, Swing_on, Swing_Slider = r.GetSetProjectGrid(0, 0)
   store_divis, store_Swing_on, store_Swing_Slider = divis, Swing_on, Swing_Slider
   Swing_Slider_adapt = floor(Swing_Slider*100)
end

function set_grid_from_script()

    Swing_Slider = Swing_Slider_adapt/100
    if Grid_mode == 0 and Triplets == false then r.GetSetProjectGrid(0, true, 1, Swing_on, Swing_Slider) end
    if Grid_mode == 0 and Triplets == true then r.GetSetProjectGrid(0, true, 2/3, Swing_on, Swing_Slider) end
    if Grid_mode == 1 and Triplets == false then r.GetSetProjectGrid(0, true, 1/2, Swing_on, Swing_Slider) end
    if Grid_mode == 1 and Triplets == true then r.GetSetProjectGrid(0, true, 1/3, Swing_on, Swing_Slider) end
    if Grid_mode == 2 and Triplets == false then r.GetSetProjectGrid(0, true, 1/4, Swing_on, Swing_Slider) end
    if Grid_mode == 2 and Triplets == true then r.GetSetProjectGrid(0, true, 1/6, Swing_on, Swing_Slider) end
    if Grid_mode == 3 and Triplets == false then r.GetSetProjectGrid(0, true, 1/8, Swing_on, Swing_Slider) end
    if Grid_mode == 3 and Triplets == true then r.GetSetProjectGrid(0, true, 1/12, Swing_on, Swing_Slider) end
    if Grid_mode == 4 and Triplets == false then r.GetSetProjectGrid(0, true, 1/16, Swing_on, Swing_Slider) end
    if Grid_mode == 4 and Triplets == true then r.GetSetProjectGrid(0, true, 1/24, Swing_on, Swing_Slider) end
    if Grid_mode == 5 and Triplets == false then r.GetSetProjectGrid(0, true, 1/32, Swing_on, Swing_Slider) end
    if Grid_mode == 5 and Triplets == true then r.GetSetProjectGrid(0, true, 1/48, Swing_on, Swing_Slider) end
    if Grid_mode == 6 and Triplets == false then r.GetSetProjectGrid(0, true, 1/64, Swing_on, Swing_Slider) end
    if Grid_mode == 6 and Triplets == true then r.GetSetProjectGrid(0, true, 1/64, Swing_on, Swing_Slider) ; Triplets = false end
    if Triplets == true then Grid_table = Grid_string[2] else Grid_table = Grid_string[1] end
    _, divis, Swing_on, Swing_Slider = r.GetSetProjectGrid(0, 0)
    store_divis, store_Swing_on, store_Swing_Slider = divis, Swing_on, Swing_Slider
end

--------------------------------------------------------------------------------------------


function sel_mediaitems_tracks() --Select only tracks of selected items
  item_n =  r.CountSelectedMediaItems(0)
  for i=1, item_n do
    local sel_item = r.GetSelectedMediaItem(0, i-1)
    local track = r.GetMediaItemTrack(sel_item)
    local track_idx =  r.CSurf_TrackToID( track, false )
    edittrack[track_idx] = true
    keeptrue[track_idx] = true
    r.SetTrackSelected(track, true)
    sel_tracks_table[i] = track
  end
end

function getselitemedges(item) ------gets item start & end position + length
  if item then
    startT = r.GetMediaItemInfo_Value(item, "D_POSITION")
    iteml = r.GetMediaItemInfo_Value(item, "D_LENGTH")
    endT = startT + iteml
  end
  return startT, endT, iteml
end 

function collect_param()
  item_n =  r.CountSelectedMediaItems(0)
  if item_n == 0 then return end
   for i = 1, item_n do
     items_to_analyze[i] = r.GetSelectedMediaItem( 0, i-1 )
   end
  first_sel_item = r.GetSelectedMediaItem(0, 0) 
  first_sel_item_fade_in = r.GetMediaItemInfo_Value( first_sel_item, 'D_FADEINLEN' )
  first_sel_item_fade_out = r.GetMediaItemInfo_Value( first_sel_item, 'D_FADEOUTLEN' )
  first_sel_item_lane = r.GetMediaItemInfo_Value( first_sel_item, 'I_FIXEDLANE' )
  first_sel_track = r.GetMediaItemTrack( first_sel_item )
  selected_tracks_count = r.CountSelectedTracks(0)
  first_active_take = r.GetActiveTake(first_sel_item)
  first_src = r.GetMediaItemTake_Source(first_active_take)
  first_srate =  r.GetMediaSourceSampleRate(first_src) -- take samplerate (simple wave/MIDI detection)
  first_sel_item_start, first_sel_item_end, first_sel_item_length = getselitemedges(first_sel_item)
  --[[
  if first_sel_item_length < 20 then
    waveform_zoom_h = 1
    min_visualzer_rangeview = waveform_zoom_h
  else 
    waveform_zoom_h = first_sel_item_length / 20
    min_visualzer_rangeview = waveform_zoom_h
  end
  ]]--
  if AutoColor then
    item_color = r.GetMediaItemInfo_Value( first_sel_item, "I_CUSTOMCOLOR" )
    if item_color == 0 then 
       item_color = r.GetTrackColor( first_sel_track ) 
    end
   item_color_r, item_color_g, item_color_b = r.ColorFromNative(item_color)
   local red, green, blue = (255 - item_color_r), (255 - item_color_g), (255 - item_color_b )
   linecolor =  RGB(red, green, blue)
   linecolor_v,_,_ = ImGui.ColorConvertRGBtoHSV(red/255, green/255, blue/255 )
   red, green, blue = ImGui.ColorConvertHSVtoRGB(linecolor_v, 1, 1 )
   linecolor = RGB(floor(red*255),floor(green*255) ,floor(blue*255) )
   linecolor_v,_,_ = ImGui.ColorConvertRGBtoHSV(red, green, blue)
  end
end


function check_items()
  check_itm = false
  item_n =  r.CountSelectedMediaItems(0)
  local itemtrack_store = 0
  for i=0, item_n-1 do
    local sel_item = r.GetSelectedMediaItem(0, i)
    local item_track = r.GetMediaItemTrack(sel_item)
    local active_take = r.GetActiveTake(first_sel_item)
    local src = r.GetMediaItemTake_Source(active_take)
    local srate =  r.GetMediaSourceSampleRate(src)
    local mute_check = r.GetMediaItemInfo_Value(sel_item, "B_MUTE")
    local sel_item_start, _, sel_item_length = getselitemedges(sel_item)
    if srate == 0 then error_msg=1 ------ check for midi items
      elseif item_track == itemtrack_store then error_msg=5 ------ check for multiple items on same track
       elseif mute_check == 1 then error_msg=2 ------ check for muted items 
         elseif tostring(sel_item_start) ~= tostring(first_sel_item_start) then error_msg=3  ------ check for same length (to string because of 3.5527136788005e-15)
          elseif tostring(sel_item_length) ~= tostring(first_sel_item_length) then error_msg=3
           elseif srate ~= first_srate then error_msg=4------ check for same sample rate
                    
    end
    itemtrack_store = item_track
  end
  if error_msg == 0 then
    srate = first_srate
    check_itm = true
  end
end 

--------------------------------------------------------------------------------
---  Accessor  -----------------------------------------------------------------
--------------------------------------------------------------------------------

function Wave:Create_Track_Accessor(itemn) 
  local item = r.GetSelectedMediaItem(0,itemn)
  if item then
     local tk = r.GetActiveTake(item)
     self.n_channels = r.GetMediaSourceNumChannels( r.GetMediaItemTake_Source(tk) )
     if tk then
        self.AA = r.CreateTakeAudioAccessor( tk )
        self.buffer   = r.new_array(block_size*self.n_channels)-- main block-buffer
        self.buffer.clear()
     end
  end
end

function Wave:Destroy_Track_Accessor()
  if getitem == 0 then
      if self.AA then r.DestroyAudioAccessor(self.AA) 
         self.buffer.clear()
      end
  end
end

function Wave:table_plus(size, tmp_buf)
  local buf=self.out_buf
  local j = 1
  for i = size+1, size + #tmp_buf, 1 do  
      buf[i] = tmp_buf[j]
      j=j+1 
  end
end

function Wave:table_plus2(size, tmp_buf)
  local buf=self.out_buf 
  local j = 1
  for i = size+1, size + #tmp_buf, 1 do  
      buf[i] = self.out_buf[i]+tmp_buf[j]
      j=j+1 
  end
end

--------------------------------------------------------------------------------
-- Wave:Set_Values() - set main values, cordinates etc -------------------------
--------------------------------------------------------------------------------
function Wave:Set_Values()
  self.selSamplestable = {}
  self.sel_len    = min(first_sel_item_length,time_limit)    
  self.selSamples = floor(self.sel_len*srate)        
  self.Xblock = block_size
  local max_size = 2^22 - 1    
  local div_fact = self.Xblock 
  self.blockstep = self.Xblock/srate
  self.full_buf_sz  =(max_size//div_fact)*div_fact     
  self.n_Full_Bufs  = self.selSamples//self.full_buf_sz
  --[[
  self.n_Full_Bufs2 = self.selSamples//max_size
  
  if self.n_Full_Bufs2>=1 then
    for i = 1,  self.n_Full_Bufs2+1 do
      if i == self.n_Full_Bufs2+1 then
        self.selSamplestable[i] = self.selSamples - max_size*(i-1)
      else
        self.selSamplestable[i] = max_size
      end
    end
  else
    self.selSamplestable[1] = self.selSamples
  end
  ]]--
  
  self.n_XBlocks_FB = self.full_buf_sz/div_fact           
  local rest_smpls  = self.selSamples - self.n_Full_Bufs*self.full_buf_sz
  self.rest_buf_sz  = ceil(rest_smpls/div_fact) * div_fact 
  self.n_XBlocks_RB = self.rest_buf_sz/div_fact             
  self.total_XBlocks = (self.selSamples//self.Xblock)+1
  return true
end


--------------------------------------------------------------------------------
---  FILTERS  ------------------------------------------------------------------
--------------------------------------------------------------------------------


function eugeen_lp_filter(freq)

  
  local sqr2 = 1.414213562
  local c = 1 / tan((pi/first_srate) * freq )
  local c2 = c * c
  local csqr2 = sqr2 * c
  local d = (c2 + csqr2 + 1)
  local ampIn0 = 1 / d;
  local ampIn1 = ampIn0 + ampIn0
  local ampIn2 = ampIn0
  local ampOut1 = (2 * (1 - c2)) / d
  local ampOut2 = (c2 - csqr2 + 1) / d  
  
  if freq>=300 then fraction = 8
  else
    fraction = 8 * (300/freq)^0.3
  end
  
  
  local group_delay_samples = floor(((1 / freq) * first_srate) / fraction + 0.5) ----- ICIO filter delay compensation

  local dlyIn1, dlyIn2, dlyOut1, dlyOut2 = 0,0,0,0
  for i = 1, #Wave.out_buf - group_delay_samples do
    
    local input = Wave.out_buf[i + group_delay_samples]
    local output = (ampIn0 * input) + (ampIn1 * dlyIn1) + (ampIn2 * dlyIn2) - (ampOut1 * dlyOut1) - (ampOut2 * dlyOut2)
    dlyOut2 = dlyOut1
    dlyOut1 = output
    dlyIn2 = dlyIn1
    dlyIn1 = input

    Wave.out_buf[i] = output
  end

end

function simple_hp_filter(freq) -----Simple 1-Pole Filter modded to 5 poles
  
  
  local lp_cut = 2*pi*freq
  local lp_n = 1/(lp_cut+ 3*first_srate)
  local lp_b1 = (3*first_srate - lp_cut)*lp_n
  local lp_a0 = lp_cut*lp_n
  local lp_outl = 0
  local lp_out2 = 0
  local lp_out3 = 0
  local lp_out4 = 0
  local lp_out5 = 0
  
  for i = 1, #Wave.out_buf do
  
    local input = Wave.out_buf[i]
    
    lp_outl = 2*input*lp_a0 + lp_outl*lp_b1
    input = input-lp_outl
    lp_out2 = 2*input*lp_a0 + lp_out2*lp_b1
    input = input-lp_out2
    lp_out3 = 2*input*lp_a0 + lp_out3*lp_b1
    input = input-lp_out3
    lp_out4 = 2*input*lp_a0 + lp_out4*lp_b1
    input = input-lp_out4
    lp_out5 = 2*input*lp_a0 + lp_out5*lp_b1
    Wave.out_buf[i] = input-lp_out5
  end
end



function Wave:apply_filters_gain()
  if filter_on then
    if  hicut < 20000 then eugeen_lp_filter(hicut) end -- simple_lp_filter(hicut) end
    if  lowcut > 20 then simple_hp_filter(lowcut) end

    
    if attack_trans>0 then Enhanced_transient(attack_trans) end
    if gain_v ~= 0 then
      for i = 1, #self.out_buf do 
        self.out_buf[i] = self.out_buf[i] * (10^((gain_v)/20))
        if self.out_buf[i]>1 then self.out_buf[i] = 1 end
        if self.out_buf[i]<-1 then self.out_buf[i] = -1 end
      end
    end
  end
end

function Enhanced_transient(attack)
  local b1Env1 = -exp(-30 / first_srate )
  local a0Env1 = 1.0 + b1Env1
  local b1Env2 = -exp(-1250 / first_srate )
  local a0Env2 = 1.0 + b1Env2
  local b1Env3 = -exp(-3 / first_srate )
  local a0Env3 = 1.0 + b1Env3
  local sustain= -1
  local tmpEnv1 = 0
  local tmpEnv2 = 0
  local tmpEnv3 = 0

  for i = 1, #Wave.out_buf do 
    local maxSpls = abs(Wave.out_buf[i])
    tmpEnv1 = a0Env1*maxSpls - b1Env1*tmpEnv1
    tmpEnv2 = a0Env2*maxSpls - b1Env2*tmpEnv2
    tmpEnv3 = a0Env3*maxSpls - b1Env3*tmpEnv3
    local env1 = sqrt(tmpEnv1)
    local env2 = sqrt(tmpEnv2)
    local env3 = sqrt(tmpEnv3)
    local gain = exp(logx(max(env2/env1,1))*attack)*exp( logx( max(env3/env1,1))*sustain)
    Wave.out_buf[i] = Wave.out_buf[i] * gain
  end
end

function Wave:create_threshold_histogram()
  local temp_abs_table = {}
  local step_res = #self.out_buf//(first_srate//2)
  if step_res == 0 then step_res = 1 end
  for i = 1, #self.out_buf, step_res do 
  local peakdata = 0
    if self.out_buf[i]<0 then peakdata = self.out_buf[i]*-1 else peakdata = self.out_buf[i] end
      if peakdata >= thresh_min  then ---- thresh_min = -60db
        temp_abs_table[#temp_abs_table+1] = abs(20 * logx(peakdata,10))*10
      end
  end
  table.sort(temp_abs_table)
  local store_n = 0
  local thresh_table_max = 0
  for i = 1, 600 do
    thresh_table[i] = 0
    local n=1+store_n
    while temp_abs_table[n]~=nil and temp_abs_table[n]<i do
      if temp_abs_table[n]>=i-1 then thresh_table[i] = thresh_table[i] + 1 end
      n=n+1
    end
    store_n = n
    if thresh_table[i]>thresh_table_max then thresh_table_max = thresh_table[i] end
  end
  
  -----------------Normalize threshold table graph --------------------------------
  for i = 1, #thresh_table do
    thresh_table[i] = (thresh_table[i]/thresh_table_max)
  end
end

--------------------------------------------------------------------------------
---  Multi Item Accessor  ------------------------------------------------------
--------------------------------------------------------------------------------

function transfer_table(from)
  local to = {}
    for i=1, #from do
      to[i]=from[i]
    end
  return to
end

function Wave:Multi_Item_Sample_Sum()
  if not self.State then
       if not self:Set_Values() then return end -- set main values  
  end
  
  for c = 1, item_n do
  
  Wave:Create_Track_Accessor(c-1)
 
    if self.AA  then
          -------------------------------------------------------------------------
          -- Filtering >> samples to out_buf >> to table >> create peaks ----------
          -------------------------------------------------------------------------
          local size, n_XBlocks
          local block_start = 0 -- first block in current buf start
          
          for i=1, self.n_Full_Bufs+1 do

                 if i>self.n_Full_Bufs then size, n_XBlocks = self.rest_buf_sz, self.n_XBlocks_RB 
                                       else size, n_XBlocks = self.full_buf_sz, self.n_XBlocks_FB  
                 end

              tmp_buf = r.new_array(size)
              tmp_buf.clear()
              
                    for block=1, n_XBlocks do 

                        if block<n_XBlocks then
                        r.GetAudioAccessorSamples(self.AA, srate, self.n_channels, block_start, self.Xblock, self.buffer)

                        else
                              if i <= self.n_Full_Bufs then
                              
                                r.GetAudioAccessorSamples(self.AA, srate, self.n_channels, block_start, self.Xblock, self.buffer)

                              else
                              
                                r.GetAudioAccessorSamples(self.AA, srate, self.n_channels, block_start, self.Xblock, self.buffer)
  
                                local emptysamples = (self.Xblock - ((self.Xblock*self.total_XBlocks)-self.selSamples))*self.n_channels
                                 
                                self.buffer.clear(0, emptysamples+1, (self.Xblock*self.n_channels)-emptysamples)
                              end
                          
                        end

                    
                        if self.n_channels>1 then
                        local temp_buffer_multichannel ={}
                          for f = 1, #self.buffer, self.n_channels do
                          local temp_sum = 0
                            for multichannel = 1, self.n_channels do
                              temp_sum = temp_sum + self.buffer[(f-1)+multichannel]
                            end
                          temp_buffer_multichannel[#temp_buffer_multichannel+1]=temp_sum/self.n_channels
                          end
                        
                        local bufpos = ((block-1)* self.Xblock)
                        tmp_buf.copy(temp_buffer_multichannel, 1, self.Xblock, bufpos+1 ) -- copy block to out_buf with offset
                         
                        else
                        
                        local bufpos = ((block-1)* self.Xblock)
                        tmp_buf.copy(self.buffer, 1, self.Xblock, bufpos+1 ) -- copy block to out_buf with offset
     
                        end
                        
                        --------------------
                        
                        block_start = block_start + self.blockstep   -- next block start_time
                        
                         
                           
                    end
              
             -------------------------------------------------------------------------------
             
             -------------------------------------------------------------------------------
             

              if c==1 then 
                if i==1 then 
                self.out_buf = tmp_buf.table() 
                else 
                self:table_plus((i-1)*self.full_buf_sz, tmp_buf.table() ) 
                end
        
              else
                if i == 1 then

                  for g=1, #tmp_buf do
                  self.out_buf[g] = self.out_buf[g] + tmp_buf[g]
                  end
                  self:table_plus2((i-1)*self.full_buf_sz, tmp_buf.table())
                else
                self:table_plus2((i-1)*self.full_buf_sz, tmp_buf.table())
                end
              
             
              end
             tmp_buf.clear()
          end ---------
        
      end 
  
  
  Wave:Destroy_Track_Accessor()
  end
  
  ------------------store the data on a  table -------------
  store_wavesum = transfer_table(self.out_buf)

  self:apply_filters_gain()
  
  self:create_threshold_histogram()

  self.State = true -- Change State
end

function checkedittracks()----------check if any tracks are true in the edit group, if not it stops the process
  local checktracks = false
    for i = 1, #edittrack do
      checktracks = edittrack[i]
      if checktracks then break end
    end
    return checktracks
end

function MoveEdges(item, new_start,new_end)
  local take = r.GetActiveTake(item)
  local pos = r.GetMediaItemInfo_Value(item,'D_POSITION')
  --local length = r.GetMediaItemInfo_Value( item,'D_LENGTH')
  local SnOffs = r.GetMediaItemInfo_Value( item,'D_SNAPOFFSET')
  --local rateIt = r.GetMediaItemTakeInfo_Value(take,'D_PLAYRATE')
  local ofSetIt = r.GetMediaItemTakeInfo_Value(take,'D_STARTOFFS')
  r.SetMediaItemInfo_Value(item,'D_POSITION',new_start)
  r.SetMediaItemInfo_Value(item,'D_LENGTH', new_end - new_start)
  r.SetMediaItemTakeInfo_Value(take,'D_STARTOFFS', ofSetIt +  new_start-pos)
  r.SetMediaItemInfo_Value(item,'D_SNAPOFFSET',SnOffs + pos - new_start)
end


function Arc_GetClosestGridDivision(time_pos)
    r.PreventUIRefresh(4573);
    local st_tm, en_tm = r.GetSet_ArrangeView2(0,0,0,0)
    r.GetSet_ArrangeView2(0,1,0,0,st_tm,st_tm+.1)
    local Grid = r.SnapToGrid(0,time_pos)
    r.GetSet_ArrangeView2(0,1,0,0,st_tm,en_tm)
    r.PreventUIRefresh(-4573)
    return Grid
end

----------------------------------------------------------------------------------- 


function Split_Quantize_items()

if checkedittracks()==false then 
  return 
end
r.PreventUIRefresh(1)
r.Undo_BeginBlock(1)

local xfadeonsplits = 0
local xfadeonedits = 0
if r.GetToggleCommandState(40912)==1 then  ---- disable autocrossfade on splits
  r.Main_OnCommand(40912,0,0)
  xfadeonsplits = 1
end

if r.GetToggleCommandState(40041)==1 then  ---- disable autocrossfade media items when editing
  r.Main_OnCommand(40041,0,0)
  xfadeonedits = 1
end

local storegroupediting

time = ImGui.GetTime(ctx)

sel_tracks = 0

local store_curs_pos = r.GetCursorPosition(0)

------check if any items in looprange-------
local tracksN = r.CountTracks(0)
local items_store_tbl = {}

for i = 1, tracksN do
  if edittrack[i] == true then
    r.Main_OnCommand(40297,0,0)-----unselect all tracks
    r.Main_OnCommand(40289,0,0)-----unselect all items
    r.SetTrackSelected(r.GetTrack( 0, i-1 ), true)
    --r.GetSet_LoopTimeRange( true, false, first_sel_item_start+first_sel_item_fade_in+10/first_srate, first_sel_item_end-first_sel_item_fade_out-10/first_srate, false )
    --r.GetSet_LoopTimeRange( true, false, first_sel_item_start, first_sel_item_end, false )
    
    --r.Main_OnCommand(40718,0,0) ----select items in selected tracks in time selection
    local edit_cursor_middle_pos = first_sel_item_start + first_sel_item_length/2
    r.SetEditCurPos( edit_cursor_middle_pos, false, false )
    
    r.Main_OnCommand(r.NamedCommandLookup('_XENAKIOS_SELITEMSUNDEDCURSELTX'),0,0)--Xenakios/SWS: Select items under edit cursor on selected tracks
    local count_sel_items = r.CountSelectedMediaItems()
    if count_sel_items == 0 then
      edittrack[i] = false
    elseif count_sel_items > 0 then
    
       for  c = 0, count_sel_items-1 do
       
       local mediaitem = r.GetSelectedMediaItem( 0, c )
       
        -- if reaperversion>=7 then 
           if  r.GetMediaItemInfo_Value( mediaitem, 'I_FIXEDLANE' ) == first_sel_item_lane then
            items_store_tbl[#items_store_tbl + 1] = mediaitem
           end
        -- else
        --  items_store_tbl[#items_store_tbl + 1] = mediaitem
        -- end
       end
    end
    
    
  end
end

r.SetEditCurPos( store_curs_pos, false, false )

r.Main_OnCommand(40289,0,0)-----unselect all items
r.Main_OnCommand(40635,0,0) ---- remove time selection 

for i=1, #items_store_tbl do
  r.SetMediaItemInfo_Value( items_store_tbl[i], 'B_UISEL', 1)
end
---r.Main_OnCommand(r.NamedCommandLookup('_FNG_CLEAN_OVERLAP'),0,0)
check_items()

if check_itm then
  --[[
  for i = 1, tracksN do -------------select edit tracks 
    if edittrack[i] then
      sel_tracks = sel_tracks+1
      r.SetTrackSelected(r.GetTrack( 0, i-1 ), true)
    end
  end
  ]]--
  sel_tracks = #items_store_tbl
  
  
    
    
    if r.GetToggleCommandState(1156)==1 then
      storegroupediting = true
      r.Main_OnCommandEx(1156,0,0) ----- Options: Toggle item grouping and track media/razor edit grouping
    end
    
    local firstgrid = Arc_GetClosestGridDivision(first_sel_item_start) 
    local firstcut = Arc_GetClosestGridDivision(first_sel_item_start+((Gate_Gl.State_Points[1]/first_srate) + ((Offset_v)/1000)))
    
    firstQcheck = (firstcut == firstgrid)
  
    local function split_items()
      local split_n = 1
      for i = 1, #items_store_tbl do
      local item = items_store_tbl[i]
      local take = r.GetActiveTake(items_store_tbl[i])
      local rateIt = r.GetMediaItemTakeInfo_Value(take,'D_PLAYRATE')
      if firstQcheck then split_n = 3 end
        for c=split_n, #Gate_Gl.State_Points, 2 do
          local Cuttime = first_sel_item_start+((Gate_Gl.State_Points[c]/first_srate) + ((Offset_v)/1000)) 
            item = r.SplitMediaItem( item, Cuttime)
        end
      end
    end
    
    local function add_stretch_markers()
      for i = 1, #items_store_tbl do
      local take = r.GetActiveTake(items_store_tbl[i])
      local rateIt = r.GetMediaItemTakeInfo_Value(take,'D_PLAYRATE')
      r.SetTakeStretchMarker( take, -1, 0 ) ---------------put fixed stretch markers on the items edges
      r.SetTakeStretchMarker( take, -1, (first_sel_item_end - first_sel_item_start)*rateIt) ---------------put fixed stretch markers on the items edges
        for c=1, #Gate_Gl.State_Points, 2 do
          local pos = ((Gate_Gl.State_Points[c]/first_srate) + ((Offset_v)/1000))
          r.SetTakeStretchMarker( take, -1, pos*rateIt )
        end
      end
    
    end

    --------------------------------------------------------------------------------
    
    
    if mode == 1 then -------if SPLIT mode
    split_items()
        local sel_item_n = r.CountSelectedMediaItems(0)
      
        itempertrack = sel_item_n/#items_store_tbl
        
       -----------------------Leading Pad ----------------------------------------------
       
       
          if LeadP_v ~= 0 then
      
                for i = 1, itempertrack do
                  
                    local item = r.GetSelectedMediaItem(0,i-1)
                    
                    local itemstart = r.GetMediaItemInfo_Value(item, 'D_POSITION')- (LeadP_v/1000)
                    
                    for tr=1, #items_store_tbl do
                    
                      local item2 = r.GetSelectedMediaItem(0,(i-1)+(itempertrack*(tr-1)))
                      
                      if i == 1 then
                        if firstQcheck then
                          r.SetMediaItemInfo_Value(item2, 'D_SNAPOFFSET',( Gate_Gl.State_Points[1]/first_srate)+ ((Offset_v)/1000)) -- - LeadP_v/1000) )
                        end
                      else
                         -- r.BR_SetItemEdges( item2, itemstart, itemstart + r.GetMediaItemInfo_Value(item, 'D_LENGTH'))
                          MoveEdges(item2,itemstart, itemstart + r.GetMediaItemInfo_Value(item, 'D_LENGTH'))
                          r.SetMediaItemInfo_Value(item2, 'D_SNAPOFFSET', LeadP_v/1000 )
                      end
                      
                  end
                end
                
          end
      
        
       ------------------------------------------------------------------------------
        for i = 1, tracksN do
          if edittrack[i] then
            r.SetTrackSelected(  r.GetTrack( 0, i-1 ), true )
          end
        end
      
        if  storegroupediting == true then r.Main_OnCommandEx(1156,0,0) end
    
        Gate_Gl.State_Points = {}
        r.PreventUIRefresh(-1)
        
  
        if Qstrength_v ~= 0 then
          Quantize_Items()
        end
        
        if Xfade_v ~= 0 then 
          Overlap(Xfade_v)
        end

        r.Undo_EndBlock('Perfect Timing! Split & Quantize', -1)
        
      ---------------------------------------------------
    else -------END SPLIT mode ----- begin WARP mode--
        
      --------------------------quantize stretch markers------------------------------
    add_stretch_markers()
          local i = 0
            while(true) do
              i=i+1
              local item = r.GetSelectedMediaItem(0,i-1)
              if item then
            
                local q_force = Qstrength_v or 100
              
                if item then
                    local posIt = r.GetMediaItemInfo_Value(item,"D_POSITION")
                    local take = r.GetActiveTake(item); 
                    local rateIt = r.GetMediaItemTakeInfo_Value(take,'D_PLAYRATE')
                  
                    local countStrMar = r.GetTakeNumStretchMarkers(take);
                    for i = 2,countStrMar-1 do;
                        local pos = ({r.GetTakeStretchMarker(take,i-1)})[2]/rateIt+posIt
                        local posGrid = Arc_GetClosestGridDivision(pos)
                        if q_force < 0 then q_force = 0 elseif q_force > 100 then q_force = 100 end
                        local new_pos = (((posGrid-pos)/100*q_force)+pos)-posIt;
                        r.SetTakeStretchMarker(take,i-1,new_pos*rateIt)
                    end;
                    r.UpdateItemInProject(item);
                end
              else
                break
              end
            end
            
    
      r.UpdateArrange()
      
        r.Undo_EndBlock('Perfect Timing! Warp Items', -1)
    end -------end WARP mode
  
    
    ---------------------------------------------------------------
  
    if xfadeonsplits == 1 then  ---- re enable disable autocrossfade on splits if disabled
      r.Main_OnCommand(40912,0,0)
    end
    
    if xfadeonedits == 1 then  ----  re enable autocrossfade media items when editing if disabled
      r.Main_OnCommand(40041,0,0)
    end
  --r.Main_OnCommand(40289,0,0)-----unselect all items
  
  end ----- checkitm IF

end 

-----------------------------fill gaps --------------------------------------------------------
function fillgaps()

    for i = 2, itempertrack do
       local prev_item = r.GetSelectedMediaItem(0,i-2)
       local prev_startTime = r.GetMediaItemInfo_Value( prev_item, 'D_POSITION' )
       local prev_endTime = prev_startTime + r.GetMediaItemInfo_Value( prev_item, 'D_LENGTH' )
       
       local sel_item = r.GetSelectedMediaItem(0,i-1)
       local startTime = r.GetMediaItemInfo_Value( sel_item, 'D_POSITION' )
       local endTime = startTime + r.GetMediaItemInfo_Value( sel_item, 'D_LENGTH' )

       if prev_endTime >= startTime then
         for tr=1, sel_tracks do
          local prev_item2 = r.GetSelectedMediaItem(0,(i-2)+(itempertrack*(tr-1)))
          --r.BR_SetItemEdges( prev_item2, prev_startTime, startTime )
          MoveEdges( prev_item2, prev_startTime, startTime )
         end
       else
         for tr=1, sel_tracks do
          local sel_item2 = r.GetSelectedMediaItem(0,(i-1)+(itempertrack*(tr-1)))
          --r.BR_SetItemEdges( sel_item2, prev_endTime, endTime )
          MoveEdges( sel_item2, prev_endTime, endTime )
         end
       end
    end
end
----------------------------------------------------------------------------------------------

function Quantize_Items()

r.Main_OnCommandEx(r.NamedCommandLookup('_FNG_CLEAN_OVERLAP'),0,0) --- clean overlapping items

  if r.GetToggleCommandState(1157) == 0 then
      r.Main_OnCommand(1157, 0)
  end
  
  if r.GetToggleCommandState(40145) == 0 then
      r.Main_OnCommand(40145, 0)
  end

 ----------------------------------------------QUANTIZE-----------------------------------
        
    for i = 1, itempertrack do
      
       local sel_item = r.GetSelectedMediaItem(0,i-1)
       local pos = r.GetMediaItemInfo_Value(sel_item, "D_POSITION")
       local Q_pos = Arc_GetClosestGridDivision(pos)
       local snapoff = r.GetMediaItemInfo_Value(sel_item, "D_SNAPOFFSET")
       local Q_diff = (Q_pos - pos + snapoff )*(Qstrength_v/100)
       local New_pos =  pos - (snapoff*(Qstrength_v/100)*2) + Q_diff
       
       for tr=1, sel_tracks do
        local sel_item2 = r.GetSelectedMediaItem(0,(i-1)+(itempertrack*(tr-1)))
        r.SetMediaItemInfo_Value(sel_item2, "D_POSITION", New_pos)
       end
    end
    
    r.Main_OnCommandEx(r.NamedCommandLookup('_FNG_CLEAN_OVERLAP'),0,0) --- clean overlapping items

  ----------------------------------------------END QUANTIZE-----------------------------------
  
fillgaps()

  ---------------------------END fill gaps --------------------------------------------------------
  local sel_item_n = r.CountSelectedMediaItems(0)

  local itempertrack = sel_item_n/sel_tracks
  
   --r.Main_OnCommandEx(r.NamedCommandLookup('_FNG_CLEAN_OVERLAP'),0,0)
    for tr=1, sel_tracks do
    
      local item_1 = r.GetSelectedMediaItem(0,(itempertrack*(tr-1)))
      local item_2 = r.GetSelectedMediaItem(0,(itempertrack*(tr))-1)
      
      local item1_end = r.GetMediaItemInfo_Value(item_1,'D_POSITION')+r.GetMediaItemInfo_Value(item_1,'D_LENGTH')
      local item2_start = r.GetMediaItemInfo_Value(item_2,'D_POSITION')
      --r.BR_SetItemEdges( item_1, first_sel_item_start, -1 ) 
      MoveEdges( item_1, first_sel_item_start, item1_end ) 
      --r.BR_SetItemEdges( item_2, -1, first_sel_item_end ) 
      MoveEdges( item_2, item2_start, first_sel_item_end ) 
      
    end  

end


function Overlap(CrossfadeT)
  local t,ret = {}
  local items_count = r.CountSelectedMediaItems(0)
  local crossfade_time = (CrossfadeT or 0)/1000
  if items_count == 0 then return 0 end
  for i = 1 ,items_count do
      local item = r.GetSelectedMediaItem(0,i-1)
      local trackIt = r.GetMediaItem_Track(item)
      if t[tostring(trackIt)] then
          ret = 1
          local take = r.GetActiveTake(item)
          local pos = r.GetMediaItemInfo_Value(item,'D_POSITION')
          local length = r.GetMediaItemInfo_Value( item,'D_LENGTH')
          local SnOffs = r.GetMediaItemInfo_Value( item,'D_SNAPOFFSET')
          local rateIt = r.GetMediaItemTakeInfo_Value(take,'D_PLAYRATE')
          local ofSetIt = r.GetMediaItemTakeInfo_Value(take,'D_STARTOFFS')
          if pos < crossfade_time then crossfade_time = pos end
          r.SetMediaItemInfo_Value(item,'D_POSITION',pos-crossfade_time)
          r.SetMediaItemInfo_Value(item,'D_LENGTH',length+crossfade_time)
          r.SetMediaItemTakeInfo_Value(take,'D_STARTOFFS',ofSetIt-(crossfade_time*rateIt))
          r.SetMediaItemInfo_Value(item,'D_SNAPOFFSET',SnOffs+crossfade_time)
      else
          t[tostring(trackIt)] = trackIt
      end
  end
  if ret == 1 then 
    r.Main_OnCommand(41059,0) --crossfade overlapping items
  else
    return ret or 0
  end
end

----------------------------------------------------------------------
---  Gate - Normalize points table  ----------------------------------
----------------------------------------------------------------------

function Gate_Gl:normalizeState_TB2(input)
local output = {}
local temp_points ={}

    local scaleRMS  = 0.79/(self.maxRMS-self.minRMS) ----- rms scale is been scaled by 10 points on left and right side  to look nicer and narrower on the histogram
    local scalePeak = 0.79/(self.maxPeak-self.minPeak) 
    local c = 2
    ---------------------------------
    for i=2, #input, 2 do 
    
        input[i][1] = ((input[i][1] - self.minRMS)*scaleRMS)+0.10 --- rms scale is been scaled by 10 points on left and right side  to look nicer and narrower on the histogram

        input[i][2] = ((input[i][2] - self.minPeak)*scalePeak)+0.10

        if input[i][1] > min_rms then
          
          output[c-1]=input[i-1]
          output[c] = {rms, peak}
          output[c][1]= input[i][1]
          output[c][2]= input[i][2]
          c = c + 2
          
        end
    end
    ---------------------------------
    self.minRMS, self.minPeak = 0, 0
    self.maxRMS, self.maxPeak = 0.79, 0.79 
    self.store_Normalized_State_Points = transfer_table(output)
    
  return output
    
end

----------------------------------------------------------------------
---  Gate - Reduce trig points  --------------------------------------
----------------------------------------------------------------------

function Gate_Gl:Reduce_Points_by_Power2(input)
  local output = {}
  local Reduce_P_v = ((100-Sensitivity_v)/sens_def)
  
  local c=0
      for i=2, #input, 2 do
  
        if input[i][Detect+1] >= Reduce_P_v then
          c = c+1
          output[c] = input[i-1]
          c = c+1
          output[c] = {input[i][1], input[i][2]}
        end
      end
  
  self.store_State_Points2 = output
  return output
end

function Gate_Gl:Points_skimmer(input,h)
local output ={}

    for i=1, h do
    self.grid_diff_temp ={}
    self.rms_battle = {}
    local idtotal ={}
      if IsEven(i)==false then
          for c = 1, #input, 2 do
            if input[c] < Grid_blocks_Ruler[i] and input[c] > (Grid_blocks_Ruler[i-2] or 0) then
               local diff = abs(input[c] - Grid_blocks_Ruler[i-1])
               
               if diff <= grid_dist then
                 self.grid_diff_temp[#self.grid_diff_temp+1] = diff
                 self.rms_battle[#self.rms_battle+1] = input[c+1][1]
                 idtotal[#idtotal+1] = c
               end
            end
          end
          
            id = getHighest(self.rms_battle)
   
          if idtotal[id] then
            output[#output+1] = input[idtotal[id]]
            output[#output+1] = input[(idtotal[id])+1]
          end
      end
    end
return output
end
    
---------------------------------reduce by grid ----------------------

function Create_Grid_table()
    grid_dist = (srate*(Gtolerance_v/1000))
    
    local blockline =first_sel_item_start
    _, storediv, storeswing, storeswingamt = r.GetSetProjectGrid(0, 0)
    local sr_sw_shift = storeswingamt*(1-abs(storediv-1))*(srate/2)
    
    Grid_blocks_Ruler = {}
    Grid_blocks_Ruler_thickness = {}
    
    local h = 0
    local checkgridstart = r.TimeMap2_timeToQN( 0, first_sel_item_start )
    
    
    if checkgridstart - floor(checkgridstart) == 0 then
      blockline = first_sel_item_start 
    else 
      blockline =  r.TimeMap_QNToTime(floor(checkgridstart))
    end
    
       while (blockline <= first_sel_item_end) do
    
            function beatc(beatpos)
               local retval, measures, cml, fullbeats, cdenom = r.TimeMap2_timeToBeats(0, beatpos)
               local _, division, _, _ = r.GetSetProjectGrid(0,false)
               beatpos = r.TimeMap2_beatsToTime(0, fullbeats +(division*2*(cdenom/4)))
               return beatpos
            end
            
            blockline = beatc(blockline)
            
            h = h + 1
            
            Grid_blocks_Ruler[h] = floor(((blockline - first_sel_item_start)*srate))
            ---msg(blockline)
            if fmod(blockline,0.5) == 0 then
            Grid_blocks_Ruler_thickness[h] = 2
            else
            Grid_blocks_Ruler_thickness[h] = 1
            end
            
       end
    
    Grid_blocks_Ruler[0] = 0
    
            if storeswing == 1 then
            
                for i=2,h, 4 do
                  Grid_blocks_Ruler[i] = floor(Grid_blocks_Ruler[i] + sr_sw_shift)
                end
            end
   return h
end

function Gate_Gl:sens_histogram(input)
    reset_Histogram()
    local tmp_Histogram = {}
    Histogram_height = {}
    local Histogram_height_max = 0
    
    for i=2, #input, 2 do
      table.insert(tmp_Histogram, floor(((input[i][Detect+1])*sens_def)+1.5))
    end

    local sens_h_highligth = abs((Sensitivity_v*(sens_def/100))-sens_def-1)
    
    for i=1, #tmp_Histogram do

      local hist_pos = sens_def+1-(tmp_Histogram[i])
      
      if tmp_Histogram[i] >= sens_h_highligth then
        Histogram_tbl[hist_pos] = 2 
      else  
        Histogram_tbl[hist_pos] = 1
      end
      
      if Histogram_height[hist_pos] ~= nil then
        Histogram_height[hist_pos] = (Histogram_height[hist_pos] + 1)^0.75
      else
        Histogram_height[hist_pos]=1
      end
      if Histogram_height[hist_pos] > Histogram_height_max then Histogram_height_max = Histogram_height[hist_pos] end
      
    end
    
    for c = 1, #Histogram_tbl do
      if Histogram_height[c]~= nil then
         Histogram_height[c] = ((Histogram_height[c] / Histogram_height_max))
      end
    end

    Histogram = Histogram_tbl
end

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
function Trig_line_thickness(input)
QN_lineTHICK = {}

      for i=1, #input, 2 do
        local gridcheck =  fmod(r.TimeMap2_timeToQN(0,(input[i]/first_srate)+ first_sel_item_start),1)
        if gridcheck <= (divis*2) then
          QN_lineTHICK[i] = 2
        else
          QN_lineTHICK[i] = 1
        end
      end
end


function Gate_Gl:Reduce_Points_by_Grid2(input)
local output = {}

  if GridScan then
    h = Create_Grid_table()
    output = Gate_Gl:Points_skimmer(input,h)
  else ----------------------------------------------------------no gridscan
    output = self.store_Normalized_State_Points
  end
return output
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Gate  --------------------------------------------------------------------
--------------------------------------------------------------------------------


function Gate_Gl:Transient_Detective()

      -------------------------------------------------
      self.State_Points = {}  -- State_Points table 
      self.grid_Points = {} -- Grid_Points table
      
      -------------------------------------------------
      -- GetSet parameters ----------------------------
      -------------------------------------------------
      -- Threshold, Sensitivity ----------
      -- Gain from Fltr_Gain slider(need for scaling gate Thresh!) 1=0db
      
      
      local Thresh     = 10^((Thresh_v)/20) -- Threshold
  
      local Sensitivity  = 10^(sens_v/20) -- Gate "Sensitivity", diff between - fast and slow envelopes(in dB)
      -- Attack, Release Time -----------
      local attTime1  = 0.001                          -- Env1 attack(sec)
      local attTime2  = 0.007                            -- Env2 attack(sec)
      local relTime1  = 0.010                            -- Env1 release(sec)
      local relTime2  = 0.015                            -- Env2 release(sec)
      -----------------------------------
      -- Init counters etc --------------
      ----------------------------------- 
      local retrig_smpls   = floor((Rtrig_v/1000)*srate)  -- Retrig slider to samples
      
      local retrig         = retrig_smpls+1                          -- Retrig counter start value!
           
      local det_velo_smpls = floor(15/1000*srate) -- DetVelo slider to samples
      -----------------------------------
      local rms_sum, peak_smpl  = 0, 0       -- init rms_sum,   maxRMS
      local maxRMS,  maxPeak    = 0, 0                 -- init max-s
      local minRMS,  minPeak    = huge, huge -- init min-s
      -------------------
      local smpl_cnt  = 0                   -- Gate sample(for get velo) counter
      local st_cnt    = 1                   -- Gate State counter for State tables
      -----------------------------------
      local envOut1 = Wave.out_buf[1]    -- Peak envelope1 follower start value
      local envOut2 = envOut1            -- Peak envelope2 follower start value
      local Trig = false                 -- Trigger, Trig init state 
      ------------------------------------------------------------------
      -- Compute sample frequency related coeffs ----------------------- 
      local ga1 = exp(-1/(srate*attTime1))   -- attack1 coeff
      local gr1 = exp(-1/(srate*relTime1))   -- release1 coeff
      local ga2 = exp(-1/(srate*attTime2))   -- attack2 coeff
      local gr2 = exp(-1/(srate*relTime2))   -- release2 coeff
      
       -----------------------------------------------------------------
       -- Gate main for ------------------------------------------------
       -----------------------------------------------------------------
       
       
       for i = 1, Wave.selSamples do
       
         local input = Wave.out_buf[i]
         if input < 0 then input = input*-1 end
           --------------------------------------------
           -- Envelope1(fast) -------------------------
           if envOut1 < input then envOut1 = input + ga1 * (envOut1 - input)
              else envOut1 = input + gr1 * (envOut1 - input)
           end
           
           
           --------------------------------------------
           -- Envelope2(slow) -------------------------
           if envOut2 < input then envOut2 = input + ga2 * (envOut2 - input)
              else envOut2 = input + gr2 * (envOut2 - input)
           end
           
           --------------------------------------------
           -- Trigger ---------------------------------  
           if retrig>retrig_smpls then
              if envOut1>Thresh and (envOut1/envOut2) > Sensitivity then
              
                 Trig = true; smpl_cnt = 0; retrig = 0; rms_sum, peak_smpl = 0, 0 -- set start-values(for capture velo)
              end
           else envOut2 = envOut1; retrig = retrig+1 
           end
           -------------------------------------------------------------
           -- Get samples(for velocity) --------------------------------
           -------------------------------------------------------------

           if Trig then
              if smpl_cnt<=det_velo_smpls then
                 rms_sum   = rms_sum + input*input  -- get  rms_sum   for note-velo
                 
                 peak_smpl = max(peak_smpl, input)  -- find peak_smpl for note-velo
                 
                 if peak_smpl > 1 then peak_smpl = 1 end
                 smpl_cnt  = smpl_cnt+1 
                 ----------------------------    
                 
              else 
                 
                  Trig = false -- reset Trig state !!!
                  -----------------------
                  local RMS  = sqrt(rms_sum/det_velo_smpls)  -- calculate RMS
                  if RMS >1 then RMS = 1 end
                  
                  --- Trigg point -------
                  self.State_Points[st_cnt]   = i - det_velo_smpls  -- Time point(in Samples!) 
                  self.State_Points[st_cnt+1] = {RMS, peak_smpl}    -- RMS, Peak values
                
                  ----------------------------------------gridblocks selection icio

                  minRMS  = min(minRMS, RMS)         -- save minRMS for scaling
                  minPeak = min(minPeak, peak_smpl)  -- save minPeak for scaling 
                  maxRMS  = max(maxRMS, RMS)         -- save maxRMS for scaling
                  maxPeak = max(maxPeak, peak_smpl)  -- save maxPeak for scaling 
                  
                  --------
                  st_cnt = st_cnt+2
          
                  -----------------------
              end
           end       
           ----------------------------------   

       end
    
    -----------------------------
    if minRMS == maxRMS then minRMS = 0 end 
    if minPeak == maxPeak then minPeak = 0 end 
    
    
    if normalize_sens_scale then
      self.maxRMS, self.maxPeak = maxRMS, maxPeak   -- maxRMS, maxPeak for scaling MIDI velo
      self.minRMS, self.minPeak = minRMS, minPeak   -- minRMS, minPeak for scaling MIDI velo
    else
      self.maxRMS, self.maxPeak = 1, 1
      self.minRMS, self.minPeak = 0, 0 
    end
    -----------------------------

    self.State_Points = Gate_Gl:normalizeState_TB2(self.State_Points)
    self.grid_Points = Gate_Gl:Reduce_Points_by_Grid2(self.State_Points)
    Gate_Gl:sens_histogram(self.grid_Points)
    Trig_line_thickness(self.grid_Points)
    self.State_Points = Gate_Gl:Reduce_Points_by_Power2(self.grid_Points)
    processing = false
    -----------------------------
    collectgarbage() -- collectgarbage
    
  -------------------------------
end

-----------------------------------MAIN WINDOW TRIG LINES!!!!---------------------------------------------------
----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

local MainHwnd = r.GetMainHwnd()
local trackview = r.JS_Window_FindChildByID(MainHwnd, 0x3E8)

function CreateBitmap()
  local c = 1
  
  for i = 1, (#Gate_Gl.grid_Points * item_n), 2 do 
    lines[c] = r.JS_LICE_CreateBitmap(true, 1, 1)
    r.JS_LICE_Clear(lines[c], linecolor)
    c = c + 1
  end
  
  if visualizer then
    for i = 1, item_n*4 do 
      visualizer_bounds[i] = r.JS_LICE_CreateBitmap(true, 1, 1)
      r.JS_LICE_Clear(visualizer_bounds[i], 0x8FFFFFFF)
    end
  end
  
end

function DestroyBitmap()
  if #lines > 0 then
    for i = 1, #lines do
      if lines[i] then r.JS_LICE_DestroyBitmap(lines[i]) end
    end
  end
  if #visualizer_bounds > 0 then
    for i = 1, #visualizer_bounds do
      if visualizer_bounds[i] then r.JS_LICE_DestroyBitmap(visualizer_bounds[i]) end
    end
  end
  
end


function MW_drawlines()
  local mouse_vert_line_on_arrange_window = false

  if check_itm == true and open and quantize_state == false  then

     local itemsn = r.CountSelectedMediaItems(0)
     if itemsn >= #items_to_analyze  then
      for trck = 1, #items_to_analyze  do

        local item = items_to_analyze[trck]
        local media_Hidden = r.GetMediaItemInfo_Value(item, "B_FIXEDLANE_HIDDEN")
        
        if r.IsMediaItemSelected(item) == false or media_Hidden == 1 then
          DestroyBitmap()
          reset_param()
          reset_edittracks()
          return
        end

        local sel_tr = sel_tracks_table[trck]

        local media_move_check =   r.GetMediaItemInfo_Value(item, "D_LENGTH" ) - r.GetMediaItemInfo_Value(item, "D_POSITION") 
        local track_H = r.GetMediaTrackInfo_Value(sel_tr, "I_TCPH")
        
        if media_move_check == first_sel_item_length - first_sel_item_start and sel_tr == r.GetMediaItemTrack(item) then
            
            local MWzoom = r.GetHZoomLevel()
            local _, scrollpos, pageSize, min, max, trackPos  = r.JS_Window_GetScrollInfo( trackview, "h" )
            local _, scrollpos_v = r.JS_Window_GetScrollInfo( trackview, "v" )
            local  _, width = r.JS_Window_GetClientSize( trackview )
            local track_y = r.GetMediaTrackInfo_Value(sel_tr, "I_TCPY") 
            local track_H = r.GetMediaTrackInfo_Value(sel_tr, "I_TCPH")
      
            --local track_FL_n = r.GetMediaTrackInfo_Value(sel_tr, "I_NUMFIXEDLANES")
            
            if r.GetToggleCommandState(43194) then
             local window, _, _ = r.BR_GetMouseCursorContext() 
             if window == "arrange" then
              mouse_vert_line_on_arrange_window = true
             else
              mouse_vert_line_on_arrange_window = false
             end
            end
            
            local media_H = 0
            
            if track_H ~= 0 then
               media_H = r.GetMediaItemInfo_Value(item, "I_LASTH" )
            end
            
            local media_Y = r.GetMediaItemInfo_Value(item, "I_LASTY" )
         
            --local media_FL_y = r.GetMediaItemInfo_Value(item, "F_FREEMODE_Y")
           -- local media_FL_h = r.GetMediaItemInfo_Value(item, "F_FREEMODE_H")

            movescreen[trck] =h_zoom_center + zoom_bounds_L + zoom_bounds_Total + r.CSurf_TrackToID( sel_tr, false ) + MWzoom + scrollpos + track_H + media_H + scrollpos_v + itemsn + track_y*2
            
            if MW_lines_ON and (Gtolerance_slider or r.GetPlayState() ~= 0 or mouse_vert_line_on_arrange_window or visualizer_rv or Offset or Detect_rv2 or Detect_rv or Visualizer_mode_rv or
            color_button or Sensitivity_slider or Change_grid or movescreen[trck] ~= movescreen_prev[trck]) then --or set_grid_from_script or get_grid_from_proj
  
              if visualizer then
                ---------------------------------------------- visualizer ZOOM AREA reference on MW
                local bounds_start_pos = floor((startT+(zoom_bounds_L/first_srate)) * MWzoom)
                local bounds_width = floor((zoom_bounds_Total/first_srate) * MWzoom)
                --local composite_Y_start = track_y + (track_H*media_FL_y+0.5)//1
                --local composite_Y_end = media_Y - (track_H*media_FL_y+0.5)//1
                local thickness = 3 -- media_H//8
                r.JS_Composite(trackview, bounds_start_pos - scrollpos, track_y + media_Y , bounds_width, thickness ,visualizer_bounds[trck], 0, 0, 1, 1, true)
                r.JS_Composite(trackview, bounds_start_pos - scrollpos, track_y + media_Y + media_H - thickness , bounds_width, thickness ,visualizer_bounds[trck+#items_to_analyze], 0, 0, 1, 1, true)
                r.JS_Composite(trackview, bounds_start_pos - scrollpos, track_y + media_Y + thickness , thickness,  media_H - thickness*2,visualizer_bounds[trck+#items_to_analyze*2], 0, 0, 1, 1, true)
                r.JS_Composite(trackview, bounds_start_pos - scrollpos + bounds_width - thickness, track_y + media_Y + thickness , thickness , media_H - thickness*2 ,visualizer_bounds[trck+#items_to_analyze*3], 0, 0, 1, 1, true)
                
                ----------------------------------------------
              end
            
              movescreen_prev[trck] = movescreen[trck]
              local pagesizecheck = (floor(width/pageSize))
              scrollpos = scrollpos*pagesizecheck
              local Reduce_P_v = ((100-Sensitivity_v)/sens_def)
              local c = 1
              
              for i = 1, #Gate_Gl.grid_Points, 2 do
                local trig_line_pos = (Gate_Gl.grid_Points[i]/first_srate) + (Offset_v/1000)
                local item_screen_pos = floor((startT+trig_line_pos) * MWzoom)
                  if pagesizecheck <=4 and  Gate_Gl.grid_Points[i+1][Detect+1] >= Reduce_P_v then --track_y + tr_label_h
                    r.JS_Composite(trackview, item_screen_pos - scrollpos, track_y + media_Y, QN_lineTHICK[i], media_H, lines[c+((#Gate_Gl.grid_Points/2)*(trck-1))], 0, 0, 1, 1, true)
                  else 
                    r.JS_Composite(trackview, item_screen_pos - scrollpos, track_y + media_Y,  0, media_H, lines[c+((#Gate_Gl.grid_Points/2)*(trck-1))], 0, 0, 1, 1, true)
                  end
                c = c + 1
              end
              
            end
 
        else
          DestroyBitmap()
          reset_param()
          reset_edittracks()
          return
        end
 
      end 
      
    r.defer(MW_drawlines)
    else 
      DestroyBitmap()
      reset_param()
      reset_edittracks()
    end
    
  end

end


function Triglinesdraw()
  DestroyBitmap()
  CreateBitmap()
  MW_drawlines()
end
-----------------------store automatically some parameters at exit--------
function exit()
  DestroyBitmap()
  AlwaysStoreatexit()
  r.defer(function() end)
end
-----------------------------------INIT-------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

get_grid_from_proj()
reset_Histogram()
Histogram = Histogram_tbl

-----------------------------ANALYZE AUDIO-------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function getitem()
  --profiler.start()
  cyclecount = 0
  quantize_state = false
  time = ImGui.GetTime(ctx)
  DestroyBitmap()
  reset_param()

    error_msg = 0
    
    collect_param()
    if item_n ~= 0 then
      check_items()
      
      if check_itm and error_msg == 0 then
        reset_Histogram()
        Histogram = {} 
        sel_mediaitems_tracks()
        Wave:Set_Values()
        Wave:Multi_Item_Sample_Sum()
        Gate_Gl:Transient_Detective()
        Triglinesdraw()
       
      end

    end
    analyzing = false
--profiler.stop()
end

function processing_audio()
  thresh_moving =0
  w_check =0
  DestroyBitmap()
  reset_Histogram()
  movescreen = {}
  movescreen_prev = {}
  processing = true
  Wave.out_buf = transfer_table(store_wavesum)
  Wave:apply_filters_gain()
  Wave:create_threshold_histogram()
  Gate_Gl:Transient_Detective()
  Triglinesdraw()
end

--profiler.attachToWorld()

--profiler.run()

-----------------------------LAYOUT--------------------------------------------
-------------------------------------------------------------------------------
-----------------------------LAYOUT--------------------------------------------
-------------------------------------------------------------------------------
-----------------------------LAYOUT--------------------------------------------
-------------------------------------------------------------------------------
-----------------------------LAYOUT--------------------------------------------
-------------------------------------------------------------------------------

-----------------------------imgui functions-----------------------------------

function filter_add_preset()
  ImGui.OpenPopup(ctx, 'FilterAddPreset')
  ImGui.SetNextWindowPos( ctx, main_x+(main_w/2)-100, main_y+(main_h/2)-50 )
  ImGui.SetNextWindowSize( ctx, 200, 100 )
  
  if ImGui.BeginPopupModal(ctx, 'FilterAddPreset', _,  ImGui.WindowFlags_NoMove | ImGui.WindowFlags_NoDecoration ) then
   ImGui.SeparatorText(ctx, 'Store Preset')
   ImGui.PushItemWidth(ctx, -1)

   if not ImGui.IsAnyItemActive(ctx) then ImGui.SetKeyboardFocusHere( ctx ) end
   _, newpresetname = ImGui.InputTextWithHint( ctx, '##newpresetname_input', '--Preset-Name--', newpresetname, ImGui.InputTextFlags_AutoSelectAll )
   -- _, newpresetname =ImGui.InputText(ctx,'##newpresetname_input', newpresetname,  ImGui.InputTextFlags_AutoSelectAll)
   ImGui.PushItemWidth(ctx, -1)
  
   if  ImGui.Button(ctx, 'Add', 87) then 
   local rv, pos = findValue(filter_preset_list,newpresetname)
    if rv then
      r.SetExtState(scriptname, 'Filter Preset' .. pos, tostring(lowcut..','.. hicut ..','.. gain_v ..','.. attack_trans),true)
      filter_preset = pos
      ADDpreset = 0
    else
      filter_preset_list = filter_add_preset_string(filter_preset_list, newpresetname)
      ADDpreset = count_string_pattern(filter_preset_list,'\0')
      filter_preset = ADDpreset -2
      ADDpreset = 0
      local replacedString = filter_preset_list:gsub("\0", ",")
      r.SetExtState(scriptname,'filter_preset_list',replacedString,true)
      r.SetExtState(scriptname, 'Filter Preset' .. filter_preset, tostring(lowcut..','.. hicut ..','.. gain_v ..','.. attack_trans),true)
    end
   end
   ImGui.SameLine(ctx)
   if  ImGui.Button(ctx, 'Cancel', 87) then filter_preset = store_filter_preset or 0; ADDpreset = 0 end
   ImGui.EndPopup(ctx)
  end
end


function findValue(inputString, searchValue)
    local replacedString = inputString:gsub("\0", ",")
    local valuesTable = {}
    local position = -1  
    local found = false
    
    for value in replacedString:gmatch("([^,]+)") do
        table.insert(valuesTable, value)
    end
    
    for i, value in ipairs(valuesTable) do
        if value == searchValue then
            found = true
            position = i - 1 
            break
        end
    end
    
    return found, position
end

function filter_add_preset_string(inputString, newpreset)
local replacedString = inputString:gsub("\0", ",")
local modifiedString
  local lastCommaPos = replacedString:find(",[^,]*$")
    local count = 0
    for i = #replacedString, 1, -1 do
        if replacedString:sub(i, i) == "," then
            count = count + 1
            if count == 2 then
                local newValue = "new value"
                modifiedString = replacedString:sub(1, i) .. newpreset .. ',' .. replacedString:sub(i + 1)
                break
            end
        end
    end
  outputstring = modifiedString:gsub(",", "\0" )
  return outputstring
end

function filter_get_preset(filter_preset)
  local inputString = r.GetExtState(scriptname,'Filter Preset' .. filter_preset)
  local valuesTable = {}
  
  for value in inputString:gmatch("[^,%s]+") do
      table.insert(valuesTable, value)
  end
  lowcut = valuesTable[1]
  hicut = valuesTable[2]
  gain_v = valuesTable[3]
  attack_trans = valuesTable[4]
end

function help_widget(string, zero_parameter, storequery)
  if Help_state == true and ImGui.BeginItemTooltip(ctx) then
    
    ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 25.0)
  
    ImGui.Text(ctx, string )
    
    if zero_parameter~=nil then 
      if not storequery then
      ImGui.Text(ctx, 'ALT Click => Set to '..zero_parameter )
      ImGui.Text(ctx, 'Right Click => Store as Default Query ' )
     -- ImGui.Text(ctx, 'Alt - Double Click => Set to ' .. zero_parameter)
      else
      ImGui.Text(ctx, 'ALT Click => Set to '..zero_parameter )
      end
    end
    ImGui.PopTextWrapPos(ctx)
    ImGui.EndTooltip(ctx)
  end
end


function store_single_settings(parameter, par_name, unit)

  local x, y
  local w

    if Store_Par_Window[par_name] == nil then Store_Par_Window[par_name] = false end
    
    if ImGui.IsMouseClicked( ctx, 1 ) and Store_Par_Window[par_name] == true then
      Store_Par_Window[par_name] = false
    end
    if ImGui.IsItemClicked(ctx, 1) then
      Store_Par_Window[par_name] = true
    end
    
    

    if Store_Par_Window[par_name]  then
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding, 10)
          
    Button_Style(0.6)
    
      ImGui.OpenPopup(ctx, 'StoreDefault'..par_name )
      x, y = ImGui.GetMouseClickedPos( ctx, 1 )
      ImGui.SetNextWindowPos( ctx, x-20 , y-15)
      
      if ImGui.BeginPopup( ctx, 'StoreDefault'..par_name, ImGui.WindowFlags_NoScrollbar | ImGui.WindowFlags_NoMove) then
      
        ImGui.Text(ctx, 'Store')
        ImGui.SameLine(ctx)
        ImGui.TextColored( ctx, 0xFFFF00FF, parameter .. unit )
        ImGui.SameLine(ctx)
        ImGui.Text(ctx, 'as Default?')
        
        if ImGui.BeginTable(ctx, 'store', 2,   ImGui.TableFlags_SizingStretchSame ) then
        ImGui.TableNextColumn(ctx)
        if ImGui.Button( ctx, 'Yes', -1) then
          r.SetExtState(scriptname,par_name,parameter,true)
          Store_Par_Window[par_name] = false
        end

        ImGui.TableNextColumn(ctx)

        if ImGui.Button( ctx, 'No', -1) then
          Store_Par_Window[par_name] = false
        end
        
        ImGui.EndTable(ctx)
        end
        ImGui.EndPopup(ctx)
      end
    ImGui.PopStyleColor(ctx, 3)
    ImGui.PopStyleVar(ctx)
    end

end


function errormessage(number)
local w,h = ImGui.GetWindowSize(ctx)
local x,y = ImGui.GetWindowPos(ctx)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_PopupRounding, 10)
    ImGui.PushStyleVar(ctx,  ImGui.StyleVar_SeparatorTextAlign, 0.5, 0.5)     

      ImGui.OpenPopup(ctx, 'Error Message:' )
      ImGui.SetNextWindowSize(ctx, 300, 80)
      ImGui.SetNextWindowPos(ctx, x+(w/2) -150, y+(h/2)-40)
      if ImGui.BeginPopupModal( ctx, 'Error Message:', false,  ImGui.WindowFlags_NoScrollbar | ImGui.WindowFlags_NoMove | ImGui.WindowFlags_NoResize) then
        if ImGui.BeginTable(ctx, 'Error', 1 ) then
          ImGui.TableNextColumn(ctx)
          ImGui.SeparatorText(ctx, error_msg_table[error_msg])
          ImGui.EndTable(ctx)
        end
        ImGui.EndPopup(ctx)
      end
    ImGui.PopStyleVar(ctx, 2)

end

function Mouse_Init_parameter(parameter, value)
  if ImGui.IsItemHovered(ctx) and (ImGui.IsKeyDown( ctx, ImGui.Key_RightAlt ) or ImGui.IsKeyDown( ctx, ImGui.Key_LeftAlt )) and ImGui.IsMouseReleased(ctx, 0)  then
      parameter = value
  end
  --[[
  if ImGui.IsItemHovered(ctx) and ImGui.IsKeyDown( ctx, 16384 ) and ImGui.IsMouseDoubleClicked(ctx, 0) then
      parameter = value2 or 0
  end
  ]]--
  return parameter
end

function Slider_Style(hue)
     local s = 0.8
     local v = 0.9
     ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, HSV(hue, s, v, 0.40))
     ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, HSV(hue, s, v, 0.6))
     ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive, HSV(hue, s, v, 0.6))
     ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrab, HSV(hue+0.07, s, v, 0.8))
     ImGui.PushStyleColor(ctx, ImGui.Col_SliderGrabActive, HSV(hue+0.07, s, v, 0.8))
end

function Button_Style(hue)
    local s = 0.8
    local v = 0.9

    ImGui.PushStyleColor(ctx, ImGui.Col_Button, HSV(hue, s, v, 0.5))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, HSV(hue, s, v, 1))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, HSV(hue, s, v, 0.8))
end

function Menu_Button_Style(hue)
    local s = 0.5
    local v = 0.2

    ImGui.PushStyleColor(ctx, ImGui.Col_Button, HSV(hue, s, v, 0.5))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, HSV(hue, s, v, 1))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, HSV(hue, s, v, 1))
end

function Waveform_Button_Style(hue)
    local s = 0.5
    local v = 0.2

    ImGui.PushStyleColor(ctx, ImGui.Col_Button, HSV(hue, s, v, 0.5))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, HSV(hue, s, v, 1))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, HSV(hue, s, v, 1))
end

function mode_center_align (text, size, mode)
blanks = ''
    emply_text_w , _ = ImGui.CalcTextSize( ctx, ' ' , emply_text_w , emply_text_h)
    totalblanks = floor(size/emply_text_w)
    text_len = string.len(text)
    
  
    emptys = floor((totalblanks /4 )*2)
    
    for i=1, emptys do
      blanks = (blanks..' ')
    end
  return blanks
end

function thresh_histogram() ---------- draw Threshold PEAK Histogram
  local th_max_x, th_max_y =  ImGui.GetItemRectMax(ctx)
    if  quantize_state == false then
    local th_w, th_h = ImGui.GetItemRectSize(ctx)

     if thresh_moving ~= th_max_x+th_max_y or cyclecount== 1 then

     thresh_histogram_table = {}
     
        for i = 1, 600 do
          local line_step = (((th_w)/600)*i)--+((th_w)/600)/2

          if thresh_table[i]~= 0 and thresh_table[i]~= nil then
             thresh_histogram_table[i] = {th_max_x-line_step, th_max_y-(thresh_table[i]*th_h)}
          else
            thresh_histogram_table[i] = 0
          end
          
        end
     
     end

      for i = 1, #thresh_histogram_table do

        if thresh_histogram_table[i]~= 0 then
        
          ImGui.DrawList_AddLine( draw_list, thresh_histogram_table[i][1], th_max_y, thresh_histogram_table[i][1] , thresh_histogram_table[i][2], 0xFFFF0030,1 )
        end
      end 
    thresh_moving = th_max_x+th_max_y
    end

end
local LRarrow = 0
function waveform_visualizer()
      
         local w = m_window_width - ImGui.StyleVar_CellPadding-2
         local y_pos = 0
         local y_neg = 0
         local max_zoom_h = floor(#Wave.out_buf/(m_window_width*2))

         local i_array = 1
         
         if  ImGui.IsKeyPressed( ctx,  ImGui.Key_DownArrow ) then -------- down arrow for waveform zooming 
          waveform_zoom_gain = waveform_zoom_gain-1
         end
         
         if  ImGui.IsKeyPressed( ctx,  ImGui.Key_UpArrow ) then -------- up arrow for waveform zooming
          waveform_zoom_gain = waveform_zoom_gain+1
         end
         if waveform_zoom_gain<1 then waveform_zoom_gain=1 end -----------min waveform zoom is 1
         if waveform_zoom_gain>14 then waveform_zoom_gain=14 end -----------max waveform zoom is 14
         
         
         if  ImGui.IsKeyPressed( ctx,   ImGui.Key_LeftArrow ) or ImGui.IsKeyPressed( ctx,   ImGui.Key_RightArrow ) then -------- left arrow for navigating
          
          if  ImGui.IsKeyPressed( ctx,   ImGui.Key_LeftArrow ) then 
            h_zoom_center = h_zoom_center + -0.1/waveform_zoom_h
            LRarrow = 1
          end
          if  ImGui.IsKeyPressed( ctx,   ImGui.Key_RightArrow ) then  
            h_zoom_center = h_zoom_center + 0.1/waveform_zoom_h
            LRarrow = 1
          end
         else
          LRarrow = 0
         end
         
         if ImGui.IsItemHovered(ctx) then ------- if hovered change mouse cursor
         ImGui.SetMouseCursor( ctx, ImGui.MouseCursor_ResizeAll )
         
         local mouse_wheel_v, mouse_wheel_h = ImGui.GetMouseWheel( ctx )
         
           if ImGui.IsMouseClicked( ctx, 0 ) or mouse_wheel_v~=0 or mouse_wheel_h~=0 then -------- zoom when click left
           new_zoom_pos_range = (1/waveform_zoom_h)
           new_zoom_pos_start = (startsample/#Wave.out_buf)
             local x_mouse, _ = r.GetMousePosition(ctx)
             x_mouse = x_mouse-histo_x
             x_mouse = x_mouse/histo_w
             if x_mouse>1 then x_mouse=1 end
             if x_mouse<0 then x_mouse=0 end
             local x_mouse_rel = (x_mouse * new_zoom_pos_range) + new_zoom_pos_start 
             h_zoom_center = x_mouse_rel
             h_zoom_absolute_center = x_mouse
             samplesdifference = h_zoom_center-h_zoom_absolute_center
           end
           
           
           if ImGui.IsMouseDragging( ctx, 1 ) then ------right click dragging 
           -- ImGui.SetMouseCursor( ctx, ImGui.MouseCursor_Hand )
            local x_delta_rc, _ = ImGui.GetMouseDelta( ctx )
            h_zoom_center = h_zoom_center - x_delta_rc/w/waveform_zoom_h
            
            right_click_dragging = true
           else
            right_click_dragging = false
           end
           
           if h_zoom_center>1 then h_zoom_center = 1 end
           if h_zoom_center<0 then h_zoom_center = 0 end
           
           
           if ImGui.IsMouseDragging( ctx, 0 ) or mouse_wheel_v~=0 or mouse_wheel_h~=0 then -------------------get horizontal zoom value
             h_zoom_dragging = true
             local x_delta, y_delta = ImGui.GetMouseDelta( ctx )
             mouse_wheel_h = (mouse_wheel_h^3)*-1
             mouse_wheel_h=min(mouse_wheel_h,600)
             mouse_wheel_h=max(mouse_wheel_h,-600)
             
             local zoom_factor_y = (y_delta/10) / histo_h
             local zoom_factor_wheel = mouse_wheel_v / histo_h
             waveform_zoom_h = waveform_zoom_h + (zoom_factor_y + zoom_factor_wheel) * (max_zoom_h / 2)
             --waveform_zoom_h = waveform_zoom_h^2/2
             --waveform_zoom_h = waveform_zoom_h + (y_delta/histo_h)*(max_zoom_h/2) + (mouse_wheel_v/histo_h)*(max_zoom_h/2) 
             moving_h = floor(((x_delta^3)/waveform_zoom_h) + (mouse_wheel_h*100/waveform_zoom_h)) + moving_h
             
               if waveform_zoom_h>max_zoom_h then waveform_zoom_h=max_zoom_h end
               if waveform_zoom_h<min_visualzer_rangeview then waveform_zoom_h=min_visualzer_rangeview end
           else
             h_zoom_dragging = false
             moving_h = 0
           end
           
           
         else
           ImGui.SetMouseCursor( ctx, ImGui.MouseCursor_Arrow )
         end

           if w_check ~= w or cyclecount==1 or h_zoom_dragging or LRarrow~=0 or right_click_dragging then ---or v_zoom_dragging then
             line_array_pos = {}
             line_array_neg = {}
             
             zoomedsamples = floor(#Wave.out_buf/waveform_zoom_h)
             
             startsample = floor(#Wave.out_buf*((1-(1/waveform_zoom_h))*h_zoom_center+(samplesdifference/waveform_zoom_h)))
             startsample = startsample+moving_h
             
             if startsample<0 then startsample = 0 end
              
             local endsample = zoomedsamples+startsample
             
             if endsample>#Wave.out_buf then 
              endsample=#Wave.out_buf ; startsample = #Wave.out_buf-zoomedsamples
             end

             local w_zoom = (w)/(zoomedsamples)
             
             for i = 1+startsample, endsample do 
               local x_poly = floor(i*w_zoom)
               local x_poly_next = floor((i+1)*w_zoom)
               
               if x_poly == x_poly_next then

                  if Wave.out_buf[i]>=(y_pos) then
                   y_pos = Wave.out_buf[i]
                  end 
                  if Wave.out_buf[i]<=(y_neg) then
                   y_neg = Wave.out_buf[i]
                  end 
                  
               else
               
                 line_array_pos[i_array] = y_pos

                 line_array_neg[i_array] = y_neg

                 y_pos = 0
                 y_neg = 0
                 i_array = i_array+1
                 
               end
             end
           end
        
    w_check = w 
  return startsample, zoomedsamples 
end ---------------------- end Visualizer 

-----------------------------main loooooooop-----------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function Main_loop()

if cyclecount < 2 then
  cyclecount = cyclecount+1
end

  if font_size_slider or initfont then
    my_font = ImGui.CreateFont(font_type, font_size)
    ImGui.Attach(ctx, my_font)
    my_font2 = ImGui.CreateFont(font_type, font_size -2)
    ImGui.Attach(ctx, my_font2)
    
    --ImGui.Attach(ctx, my_font3)
    initfont = false
  end
  
  main_win_h_adapt = floor((m_window_height/16)*(font_size)*((16/font_size)^0.45))+visualizer_h
  
  ImGui.PushFont(ctx, my_font)
  
  ImGui.SetNextWindowSize( ctx, m_window_width, main_win_h_adapt )
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowTitleAlign, 0.5, 0.5)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowRounding, 10)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowBorderSize, 0)
  
  ImGui.PushStyleColor( ctx, ImGui.Col_WindowBg, HSV(0, 0, 0.15, 1) )
  
  if dockid~=0 and cyclecount == 1 then
    ImGui.SetNextWindowDockID( ctx, dockid)
  end
  
    visible, open = ImGui.Begin(ctx, scriptname, true,  ImGui.WindowFlags_NoResize | ImGui.WindowFlags_NoScrollbar)

  
docked = ImGui.IsWindowDocked( ctx )
dockid = ImGui.GetWindowDockID( ctx )

if visible then
  
  draw_list = ImGui.GetWindowDrawList(ctx)
  
  MW_lines_ON = ((Visualizer_mode == 1 and not visualizer) or Visualizer_mode == 0) 
  main_x ,main_y = ImGui.GetWindowPos( ctx )
  main_w, main_h = ImGui.GetWindowSize( ctx )
   
  if m_window_width == 720 then 
  radio_w_size = 0 
  else 
    if m_window_width == 1000 then
    radio_w_size = 1 
    end
  end

  if docked then 
  m_window_width = main_w 
  if main_w <720 then m_window_width =720 end
  else
    if docked == false and main_w ~= 720 and main_w ~= 1000 then
      if radio_w_size == 1 then
        m_window_width = 1000 
      else
        m_window_width = 720 
      end
    end
  end
  
  
  ImGui.PopStyleColor(ctx, 1)
  
  if error_msg~=0 and ImGui.GetTime(ctx) < time +3 then
      errormessage(error_msg)
  end
  
-----------------------------------MENU-----------------------------------------------------
    
    Menu_Button_Style(0.5)
    if ImGui.BeginTable(ctx, 'menubar', 4, ImGui.TableFlags_NoPadOuterX| ImGui.TableFlags_NoPadInnerX 
    | ImGui.TableFlags_PreciseWidths, m_window_width-ImGui.StyleVar_CellPadding, 20) then
    
      ImGui.TableNextColumn(ctx)
      ImGui.PushStyleColor( ctx, ImGui.Col_PopupBg, HSV(0, 0, 0.15, 1) )
      
      
      if ImGui.Button(ctx, 'Menu', (m_window_width/13)+(m_window_width-720)/6, 0) then
         _, ymenu = ImGui.GetItemRectMin( ctx )
         ImGui.OpenPopup(ctx, '##menulist')
  
         ImGui.SetNextWindowPos( ctx, main_x + ImGui.StyleVar_FramePadding - ImGui.StyleVar_WindowPadding, ymenu)
         ImGui.SetNextWindowSize( ctx, floor(m_window_width/4) - ImGui.StyleVar_FramePadding, main_h - ymenu + main_y - ImGui.StyleVar_WindowPadding )
      end 
      
      ImGui.SameLine(ctx)
      visualizer_rv, visualizer = ImGui.Checkbox( ctx, 'Visualizer', visualizer )
      
      ImGui.PushFont(ctx, my_font2)
      
      if ImGui.BeginPopupModal(ctx, '##menulist', _,  ImGui.WindowFlags_NoMove | ImGui.WindowFlags_NoDecoration ) then
        
         ImGui.SetWindowSize( ctx, floor(m_window_width/2) - ImGui.StyleVar_FramePadding, -1 )
         
         ImGui.MenuItem( ctx, '<<< Back')
         ImGui.Separator(ctx)
         
         if ImGui.BeginTable(ctx, 'menusettings', 2,  ImGui.TableFlags_BordersInnerV  |   ImGui.TableFlags_PreciseWidths, -1, -1)
         then
         
         ImGui.TableNextColumn(ctx)
         
         if ImGui.MenuItem( ctx, 'Init Settings') then 
           initsettings() 
           initfont = true
         end
         
         ImGui.Separator(ctx)
         
         _, Help_state = ImGui.Checkbox(ctx,  'Help Widgets', Help_state)
         
        if docked == false then
        
        ImGui.AlignTextToFramePadding( ctx )
        ImGui.Text( ctx, 'GUI size' )
        ImGui.SameLine(ctx)
        
          w_size_rvS, radio_w_size = ImGui.RadioButtonEx(ctx, 'S', radio_w_size, 0)
          ImGui.SameLine(ctx)
          w_size_rvL, radio_w_size = ImGui.RadioButtonEx(ctx, 'L', radio_w_size, 1)
          
          if w_size_rvS then m_window_width = 720 end
          if w_size_rvL then m_window_width = 1000 end
          
        end
         
        ImGui.PushItemWidth(ctx, -1)
        font_size_slider, font_size = ImGui.SliderInt(ctx, '##font_size', font_size, 16, 19, "FontSize: %d", NoIP)
  
         ImGui.Separator(ctx)  
         if ImGui.MenuItem( ctx, 'Forum Page') then OpenURL('https://forum.cockos.com/showthread.php?p=2764162#post2764162') end
         if ImGui.MenuItem( ctx, 'Tip Me!') then OpenURL('https://paypal.me/80icio') end
         
         ImGui.TableNextColumn(ctx)----------------------second menu column
         
         ImGui.SeparatorText(ctx,'TRGLine Options')
         ImGui.PushItemWidth(ctx, -1)
         
         Visualizer_mode_rv, Visualizer_mode = ImGui.Combo(ctx, '##Visualizer_mode', Visualizer_mode, Visualizer_mode_table)
  
         ImGui.PushItemWidth(ctx, -1)
         --[[
         _, AutoThresh = ImGui.Checkbox( ctx, 'Auto Threshold', AutoThresh )
         _, AutoSens = ImGui.Checkbox( ctx, 'Auto Sensitivity', AutoSens )
         ]]--
         _, AutoColor = ImGui.Checkbox( ctx, 'AutoColor', AutoColor )
         
         
         ImGui.EndTable(ctx) -------- end 'menusettings'
         end
         
      ImGui.EndPopup(ctx) ---------------------- end MENU pop up
         
    end

    ImGui.PopStyleColor(ctx, 1)
    ImGui.PopFont(ctx)
    ImGui.TableNextColumn(ctx)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 10)
    
    if page_select == 1 then
      ImGui.PushStyleVar( ctx,  ImGui.StyleVar_FrameBorderSize, 2 )
      ImGui.Button(ctx, '/// Main Settings',-1)
      ImGui.PopStyleVar(ctx,1)
    else
      if ImGui.Button(ctx, '/// Main Settings',-1) then page_select = 1 end
    end
    
    ImGui.TableNextColumn(ctx)
    
    if filter_on then
      ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFFFF00FF)
  
      if page_select == 2 then
        
        ImGui.PushStyleVar( ctx,  ImGui.StyleVar_FrameBorderSize, 2 )
        ImGui.Button(ctx, '/// Filters', -1) 
        ImGui.PopStyleVar(ctx,1)
      else
        if ImGui.Button(ctx, '/// Filters', -1) then page_select = 2 end
      end
    
      ImGui.PopStyleColor(ctx, 1)
      
      else
      
      if page_select == 2 then
        
        ImGui.PushStyleVar( ctx,  ImGui.StyleVar_FrameBorderSize, 2 )
        ImGui.Button(ctx, '/// Filters', -1) 
        ImGui.PopStyleVar(ctx,1)
      else
        if ImGui.Button(ctx, '/// Filters', -1) then page_select = 2 end
      end
    end
    ImGui.TableNextColumn(ctx)
    
    
    if page_select == 3 then
      ImGui.PushStyleVar( ctx,  ImGui.StyleVar_FrameBorderSize, 2 )
      ImGui.Button(ctx, '/// Advanced Settings',-1)
      ImGui.PopStyleVar(ctx,1)
    else
      if ImGui.Button(ctx, '/// Advanced Settings',-1) then page_select = 3 end
    end

      ImGui.PopStyleVar(ctx,1)
      ImGui.PopStyleColor(ctx, 3)
      ImGui.EndTable(ctx)
    end
   
---------------------------------TOTAL TABLE-----------------------------------------------------
  if ImGui.BeginTable(ctx, 'total', 2, ImGui.TableFlags_SizingFixedFit) then
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 3)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize, 5)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabRounding, 3)  
  
  
  ImGui.TableNextColumn(ctx)---------------------------Edit Tracks--total table left-----------------------
  
  
 
  local edittracks_w = floor(m_window_width/4) - ImGui.StyleVar_FramePadding
    if ImGui.BeginTable(ctx, 'leftcolumn', 1,ImGui.WindowFlags_NoResize,edittracks_w, -1) then
    
    ImGui.TableNextColumn(ctx)
    ImGui.PushItemWidth(ctx,edittracks_w)
  EditTrk, EditTrk_mode = ImGui.Combo(ctx, '##Edit', EditTrk_mode, EditTrk_table)
  _, y_EditTrk = ImGui.GetItemRectMax(ctx)
  help_widget(EditTrk_help)
  
  
  
  ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarBg, HSV(0, 0, 0.15, 1) )
  ImGui.PushFont(ctx, my_font2)

  if ImGui.BeginTable(ctx, 'tracklist', 1,  ImGui.TableFlags_ScrollY 
  | ImGui.TableFlags_Borders, edittracks_w, 129*(font_size/19)+(19-font_size)*3) then
  
    ImGui.TableNextColumn(ctx)
 
    if not check_itm or EditTrk then reset_edittracks() end --;reset_trkgroups() end

    if EditTrk_mode == 0 then------------------------------- Sel Tracks Edit--------------------------------------
      for i = 0, r.CountTracks(0)-1 do
      
        ImGui.TableNextRow( ctx )
        ImGui.TableSetColumnIndex(ctx, 0)
        local trk = r.GetTrack( 0, i )
        _, Trackname = r.GetTrackName( trk )
        local Tdepth = ""
        for i = 1,r.GetTrackDepth( trk ) do
          Tdepth = tostring(Tdepth.."  ")
        end
         
        if r.CountTrackMediaItems( trk )>=1 then

          if keeptrue[i+1] then
            ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFFFF00FF)
            _, edittrack[i+1] = ImGui.Selectable( ctx, Tdepth..tostring(i+1 ..' ' .. Trackname),true )
            ImGui.PopStyleColor(ctx)

          else

          _, edittrack[i+1] = ImGui.Selectable( ctx, Tdepth .. tostring(i+1 ..' ' .. Trackname), edittrack[i+1] )

          end
        else
        ImGui.TextDisabled( ctx, Tdepth .. tostring(i+1 ..' ' .. Trackname) )
        edittrack[i+1] = false
        end
      
      end
    
    end
    
    if EditTrk_mode ~= 1 and check_itm and cyclecount == 1 then -------autoscroll edittrack mode table
      local scrollMAX = ImGui.GetScrollMaxY( ctx )
      ImGui.SetScrollY( ctx, (scrollMAX/r.CountTracks(0))*(r.CSurf_TrackToID(first_sel_track, false)) )
    end
    
    if EditTrk and EditTrk_mode == 1 then
      ImGui.SetScrollY( ctx, 0 )
    end
    
    
    
    if  EditTrk_mode == 1 then -------------------- trackgroup Edit
    
      local group_names_lst = GetGroupNames()
      local selgrp
      
      for i = 1, #group_names_lst do
        ImGui.TableNextRow( ctx )
        ImGui.TableSetColumnIndex(ctx, 0)
        editcheck, editgroup[i] = ImGui.Selectable( ctx, tostring('Grp '.. i ..' ' .. group_names_lst[i]), editgroup[i] )
        
        if editcheck then
        r.Main_OnCommandEx( 40297, 0, 0 )-- Track: Unselect (clear selection of) all tracks
        end
        
        if  editgroup[i] and editcheck then
          selgrp = i
          for c = 1, #group_names_lst do
            if c~=selgrp then editgroup[c] = false end
          end
        end
        
        if editgroup[i] and check_itm then
          r.Main_OnCommandEx( 40803+i, 0, 0 ) --Group: Select all tracks in group 'i'
        end

      end
      
      for i = 0, r.CountTracks(0)-1 do
        local trk = r.GetTrack( 0, i )
        if keeptrue[i+1] or (r.IsTrackSelected(trk) and r.CountTrackMediaItems( trk )>=1)  then
          edittrack[i+1] = true
        else
          edittrack[i+1] = false
        end
      end
      
    end --------------------end trackgroups
    
    ImGui.EndTable(ctx) -------- end tracklist
    
  end
  ImGui.PopStyleColor(ctx, 1)
  ImGui.PopFont(ctx)
  ImGui.EndTable(ctx) -------- end leftcolumn
  end
  
  ImGui.TableNextColumn(ctx)--------------------------total table right
  
  -------------------------------------------------------All Parameters-------------------------
  -------------------------------------------------------All Parameters-------------------------
  -------------------------------------------------------All Parameters-------------------------
  
   if ImGui.BeginTable(ctx, 'Settings', 3, ImGui.TableFlags_SizingStretchSame |   ImGui.TableFlags_PreciseWidths
   , floor((m_window_width/4)*3)-ImGui.StyleVar_CellPadding, 0)
  then
  --------------------------------------------------------------------------------------------
  -----------------------------------COLUMN 1-------------------------------------------------
  --------------------------------------------------------------------------------------------
  
   ImGui.TableNextColumn(ctx)
   
   if page_select == 1 then ----------------------------Grid settings
   
     Slider_Style(0)
     ImGui.PushItemWidth(ctx, m_window_width/4-100)
     Grid, Grid_mode = ImGui.Combo(ctx, '##Grid', Grid_mode, Grid_table)
     
     help_widget(Grid_help)
 
     ImGui.SameLine(ctx)
     
      
     if Triplets == true then 
       Button_Style(0)
       Triplets_rv, _ = ImGui.Button(ctx, '3', 30, 0)
       ImGui.PopStyleColor(ctx, 3)
     else
        ImGui.PushStyleVar( ctx,  ImGui.StyleVar_FrameBorderSize, 2 )
        Menu_Button_Style(0.5)
        Triplets_rv, _ = ImGui.Button(ctx, '3', 30, 0 )
        ImGui.PopStyleColor(ctx, 3)
        ImGui.PopStyleVar(ctx)
     end
     
     if Triplets_rv then
      if Triplets or not Triplets then Triplets = not Triplets end
     end
     
     ImGui.SameLine(ctx)
     if Dotted == 1 then 
       Button_Style(0)
       Dotted_rv, _ = ImGui.Button(ctx, 'Dot', 42, 0)
       ImGui.PopStyleColor(ctx, 3)
     else
        ImGui.PushStyleVar( ctx,  ImGui.StyleVar_FrameBorderSize, 2 )
        Menu_Button_Style(0.5)
        Dotted_rv, _ = ImGui.Button(ctx, 'Dot', 42, 0 )
        ImGui.PopStyleColor(ctx, 3)
        ImGui.PopStyleVar(ctx)
     end
     
     if Dotted_rv then
        r.Main_OnCommandEx(reaper.NamedCommandLookup('_SWS_AWTOGGLEDOTTED'),0,0)
     end
     
     
     ImGui.PushItemWidth(ctx,-1)
     Swing_toggle, Swing_on = ImGui.Checkbox(ctx, '##swingtoggle', Swing_on)
     
     
     if Swing_on == true then
       ImGui.SameLine(ctx) 
       Swing, Swing_Slider_adapt = ImGui.SliderInt(ctx, '##Swing', Swing_Slider_adapt, -100, 100, "Swing ON: %d %%", NoIP)
     else
       ImGui.SameLine(ctx)
       ImGui.PushStyleColor(ctx,  ImGui.Col_Text, 0xFFFFFF50)
       ImGui.Text(ctx, 'Swing OFF')
       ImGui.PopStyleColor(ctx, 1)
     end
     
     if Swing_on == true then Swing_on = 1 else Swing_on = 0 end
     
     GridScan_rv, GridScan = ImGui.Checkbox( ctx, '##GridScan', GridScan )
     ImGui.SameLine(ctx)
     
     if GridScan then
      Gtolerance_slider, Gtolerance_v = ImGui.SliderInt(ctx, '##Gtolerance_v', Gtolerance_v, 10, 200, "GrdScan: %d ms", NoIP)
     else
      ImGui.PushStyleColor(ctx,  ImGui.Col_Text, 0xFFFFFF30)
      Gtolerance_slider, Gtolerance_v = ImGui.SliderInt(ctx, '##Gtolerance_v', Gtolerance_v, 50, 200, "Grid Scan: %d ms", NoIP)
      ImGui.PopStyleColor(ctx, 1)
     end
     store_single_settings(Gtolerance_v, 'Gtolerance_v', ' ms' )
     
     Gtolerance_v = Mouse_Init_parameter(Gtolerance_v, tonumber(r.GetExtState(scriptname,'Gtolerance_v') ) or 100)

     help_widget(GridScan_help, 'Default')
   
   ImGui.PopStyleColor(ctx, 5)
   
   elseif page_select == 2 then ---------------------------- Filters
   
   Slider_Style(0.4)
     ImGui.PushItemWidth(ctx,-1)
     
     lowcut_rv, lowcut = ImGui.SliderInt( ctx, '##LowCut', lowcut, 20, 20000, "LowCut: %d Hz", NoIP |  ImGui.SliderFlags_Logarithmic)

     lowcut = Mouse_Init_parameter(lowcut, 20 )
     lowcut_edit = ImGui.IsItemDeactivatedAfterEdit( ctx )
     
     help_widget(lowcut_help, '20 Hz', true)
     
     
     ImGui.PushItemWidth(ctx,-1)
     hicut_rv, hicut = ImGui.SliderInt( ctx, '##hiCut', hicut, 20, 20000, "HiCut: %d Hz", NoIP |  ImGui.SliderFlags_Logarithmic)
     hicut = Mouse_Init_parameter(hicut, 20000 )
     hicut_edit = ImGui.IsItemDeactivatedAfterEdit( ctx )
     help_widget(hicut_help, '20000 Hz', true)
     
     if hicut_rv and hicut < lowcut then lowcut = hicut end
     if lowcut_rv and lowcut > hicut then hicut = lowcut end
     
     
     ImGui.PushItemWidth(ctx, -1)
     _, gain_v = ImGui.SliderInt(ctx, '##gain', gain_v, -30, 30, "Gain: %d db", NoIP)
     
     gain_edit = ImGui.IsItemDeactivatedAfterEdit( ctx )
     help_widget(gain_help, '0 db', true)
     
     gain_v = Mouse_Init_parameter(gain_v, 0 )
     ImGui.PopStyleColor(ctx, 5)
   else ----------------------------------------------------advanced settings
   ImGui.SeparatorText(ctx, 'Global Presets')
   
    
   end
   --------------------------------------------------------------------------------------------
   -----------------------------------COLUMN 2-------------------------------------------------
   --------------------------------------------------------------------------------------------
   
   ImGui.TableNextColumn(ctx)
   
   if page_select == 1 then---------------------------- Lpad Xfade mode
   
   Slider_Style(0.1)
   ImGui.PushItemWidth(ctx,-1)
 

     if mode == 1 and LeadP_v >0 then --------deactivated slider if warp mode
      LeadingPad, LeadP_v = ImGui.SliderInt(ctx, '##2', LeadP_v, 0, 50, "Leading Pad: %d ms", NoIP)
     else
      ImGui.PushStyleColor(ctx,  ImGui.Col_Text, 0xFFFFFF30)
      LeadingPad, LeadP_v = ImGui.SliderInt(ctx, '##2', LeadP_v, 0, 50, "Leading Pad: OFF", NoIP)
      ImGui.PopStyleColor(ctx, 1)
     end
     store_single_settings(LeadP_v, 'LeadP_v', ' ms' )
     LeadP_v = Mouse_Init_parameter(LeadP_v, tonumber(r.GetExtState(scriptname,'LeadP_v') ) or 10)
     
     help_widget(LeadingPad_help, 'Default')
     
     if mode == 1 and Xfade_v>0 then --------deactivated slider if warp mode
      Xfade, Xfade_v = ImGui.SliderInt(ctx, '##3', Xfade_v, 0, 50, "X Fade: %d ms", NoIP)
     else
      ImGui.PushStyleColor(ctx,  ImGui.Col_Text, 0xFFFFFF30)
      Xfade, Xfade_v = ImGui.SliderInt(ctx, '##3', Xfade_v, 0, 50, "X Fade: OFF", NoIP)
      ImGui.PopStyleColor(ctx, 1)
     end
     store_single_settings(Xfade_v, 'Xfade_v', ' ms')
     Xfade_v = Mouse_Init_parameter(Xfade_v, tonumber(r.GetExtState(scriptname,'Xfade_v') ) or 10)
     help_widget(Xfade_help, 'Default')
     
     ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x000000FF)
     
     mode_switch, mode = ImGui.SliderInt(ctx, '##mode', mode, 1, 2, mode_string, NoIP)
     
       mode_w, _ = ImGui.GetItemRectSize(ctx)
       
       mode_center = mode_center_align(mode_table[mode], mode_w)
  
       if mode == 1 then  
        mode_string = tostring(mode_table[mode]..mode_center) 
       else 
        mode_string = tostring(mode_center..mode_table[mode])
       end
     

     
     ImGui.PopStyleColor(ctx)    
     help_widget(mode_help)

  ImGui.PopStyleColor(ctx, 5)
  
  elseif page_select == 2 then ------------------------------------transient design

  Slider_Style(0.65)
    
    ImGui.PushItemWidth(ctx,-1)
    _, attack_trans = ImGui.SliderDouble( ctx, '##attack', attack_trans, 0, 6, "Attack: %.1f", NoIP)
    transient_rv = ImGui.IsItemDeactivatedAfterEdit(ctx)
    attack_trans = Mouse_Init_parameter(attack_trans, 0.0)
    help_widget(attack_help, '0.0', true)

    if  filter_on then 
      filter_on_str = 'Filter ON' 
    else
      filter_on_str = 'Filter OFF' 
    end
    
    filter_button = ImGui.Button(ctx,filter_on_str,-1)
    
    if filter_button then filter_on = not filter_on end
    ImGui.PopStyleColor(ctx, 5)
  else -----------------------------------------------------------advanced settings
  ImGui.SeparatorText(ctx, 'Time Offset')
  --ImGui.SeparatorText(ctx, 'Sensitivity Slope')
  --ImGui.PushItemWidth(ctx, -1)
  
  --Time_vs_Peak_mode_edit, Time_vs_Peak_mode = ImGui.Combo(ctx, '##TvsP', Time_vs_Peak_mode, Time_vs_Peak_mode_table)

  ImGui.PushItemWidth(ctx,-1)
  
  Offset, Offset_v = ImGui.SliderDouble(ctx, '##Oset', Offset_v, -20, 20, "%.1f ms", NoIP)
  store_single_settings(Offset_v, 'Offset_v', ' ms' )
  Offset_v = Mouse_Init_parameter(Offset_v, tonumber(r.GetExtState(scriptname,'Offset_v') ) or -0.1)
  
  help_widget(Offset_help, 'o ms')
  
    
  end
  
  --------------------------------------------------------------------------------------------
  -----------------------------------COLUMN 3-------------------------------------------------
  --------------------------------------------------------------------------------------------
       
  ImGui.TableNextColumn(ctx) 
  
  if page_select == 1 then---------------------------- Retrig Qstrength LineColor
  
  Slider_Style(0.7)
  
  ImGui.PushItemWidth(ctx,-1)
  _, Rtrig_v = ImGui.SliderInt( ctx, '##Retrig Time', Rtrig_v,1, 200, "Retrig: %d ms", NoIP )
  Rtrig_edit = ImGui.IsItemDeactivatedAfterEdit( ctx )
  store_single_settings(Rtrig_v, 'Rtrig_v', ' ms' )
  Rtrig_v = Mouse_Init_parameter(Rtrig_v, tonumber(r.GetExtState(scriptname,'Rtrig_v') ) or 20)
  help_widget(Retrig_help, 'Default')
  

    Qstrength, Qstrength_v = ImGui.SliderInt(ctx, '##4', Qstrength_v, 0, 100, Qstrength_label, NoIP)
    if Qstrength_v > 0 then
      Qstrength_label = "Q Strength: %d %%"
    else
      Qstrength_label = "Quantize OFF"
    end
    store_single_settings(Qstrength_v, 'Qstrength_v', ' %' )
    Qstrength_v = Mouse_Init_parameter(Qstrength_v, tonumber(r.GetExtState(scriptname,'Qstrength_v') ) or 100)
    help_widget(Qstrength_help, 'Split Only')
    
    color_button, linecolor_v = ImGui.SliderDouble(ctx, '##linecolor', linecolor_v, 0, 1, "Line Color: %.1f", NoIP)
    store_single_settings(linecolor_v, 'linecolor_v', '' )
    linecolor_v = Mouse_Init_parameter(linecolor_v, tonumber(r.GetExtState(scriptname,'linecolor_v') ) or 0.5)
    help_widget(linecolor_help, '0,5')
    
    ImGui.PopStyleColor(ctx, 5)
  
  elseif page_select == 2 then
  ImGui.SeparatorText(ctx, 'Filter Presets')
  ImGui.PushItemWidth(ctx,-1)
  filter_preset_rv, filter_preset = ImGui.Combo(ctx,'Filter Presets',filter_preset, filter_preset_list)
  if filter_preset_rv then 
    ADDpreset = count_string_pattern(filter_preset_list,'\0')
    if filter_preset ~= ADDpreset-1 then 
      store_filter_preset = filter_preset
      filter_get_preset(filter_preset)
    end
  end
  
  if filter_preset == ADDpreset-1 then 
    filter_add_preset()
  end
  ---------------------------
  else  ------------------------------------------------------advanced settings 3
    ImGui.SeparatorText(ctx, 'Sensitivity Scale')
    ImGui.AlignTextToFramePadding( ctx )
    Detect_rv2, Detect = ImGui.RadioButtonEx(ctx, 'Peak', Detect, 1)
    ImGui.SameLine(ctx)
    Detect_rv, Detect = ImGui.RadioButtonEx(ctx, 'RMS', Detect, 0)
    normalize_sens_scale_rv, normalize_sens_scale = ImGui.Checkbox(ctx, 'Scale Normalize', normalize_sens_scale)
  end
  
  ImGui.EndTable(ctx) ------- end Settings
  end
  --------------------------------------------------------------------------------------------
  -----------------------------------Settings Table END---------------------------------------
  --------------------------------------------------------------------------------------------
  
  -----------------------------------sens slider
  
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 0, 8)
  if ImGui.BeginTable(ctx, 'sensitivityandthreshold', 3 , ImGui.TableFlags_SizingStretchSame |   ImGui.TableFlags_PreciseWidths
  , floor((m_window_width/4)*3)-ImGui.StyleVar_CellPadding, 0)
  then
  
  --ImGui.TableSetupColumn( ctx, 'senscolumn',  ImGui.TableColumnFlags_None, 1 )
  ImGui.TableNextColumn(ctx)
  ImGui.PushItemWidth(ctx,-1)
  Sensitivity_slider, Sensitivity_v = ImGui.SliderInt(ctx, '##Sensitivity', Sensitivity_v, 0, 100, "Sensitivity: %d %%", NoIP)
  
  store_single_settings(Sensitivity_v, 'Sensitivity_v', ' %' )
  Sensitivity_v = Mouse_Init_parameter(Sensitivity_v, tonumber(r.GetExtState(scriptname,'Sensitivity_v') ) or 100)
  help_widget(Sensitivity_help)
  
  if  quantize_state == false then
  
  local sens_x, sens_y = ImGui.GetItemRectMin( ctx )
  local sens_w, sens_h = ImGui.GetItemRectSize( ctx )

    for i=1, #Histogram do ------------------------sens histogram---------------------------------------
      
       line_step = (((sens_w)/sens_def)*(i-1))+((sens_w)/sens_def)/2
       if Histogram[i]~= 0 and Histogram[i]~= nil then
         local height = (sens_h-9)*(Histogram_height[i])
         if  Histogram[i] == 2 then
           ImGui.DrawList_AddLine( draw_list, sens_x+line_step, sens_y+sens_h-3 , sens_x+line_step , sens_y+sens_h-3 - height , -855703399 ,2 )
         else
           ImGui.DrawList_AddLine( draw_list, sens_x+line_step, sens_y+sens_h-3 , sens_x+line_step , sens_y+sens_h-3 - height , -855703501 ,2 )
         end
       end
    end

  end
  ImGui.TableNextColumn(ctx)
  ImGui.PushItemWidth(ctx, -1)
  
  _, sens_v = ImGui.SliderDouble(ctx, '##sens_v', sens_v, 1, 10, "Crest: %.1f dB", NoIP)
    sens_v_rv = ImGui.IsItemDeactivatedAfterEdit(ctx)
    help_widget(Crest_help, 'Default')
    
  store_single_settings(sens_v, 'sens_v', ' dB' )
  sens_v = Mouse_Init_parameter(sens_v, tonumber(r.GetExtState(scriptname,'sens_v') ) or 5)
  
  ImGui.TableNextColumn(ctx)
  ImGui.PushItemWidth(ctx, -1)
  
  Thresh_rv, Thresh_v = ImGui.SliderInt(ctx, '##Threshold', Thresh_v, -60, 0, "Threshold: %d db", NoIP)
  
  if check_itm then
    thresh_histogram()
  end
  
  help_widget(Threshold_help, '0 db')
  
  Thresh_v = Mouse_Init_parameter(Thresh_v, tonumber(r.GetExtState(scriptname,'Thresh_v') ) or -60)
  
  store_single_settings(Thresh_v, 'Thresh_v', ' db' )
  
  Thresh_edit = ImGui.IsItemDeactivatedAfterEdit( ctx )
  
  if Thresh_rv or cyclecount == 1 then 
    display_Thresh = 10^((Thresh_v)/20) 
  end
  
  
  ImGui.EndTable(ctx)  ------- end sensitivityandthreshold
  end 
  ImGui.PopStyleVar( ctx, 1)
  
  --------------------------------------------Analyze and Quantize buttons

  Button_Style(0.6)
  if processing then
    a_bttn_state = 3
  else
    if analyzing == false   then
       a_bttn_state = 1
    else
       a_bttn_state = 2
    end
  end
  
  if  check_itm == false or quantize_state == true or processing  then
  if ImGui.BeginTable(ctx, 'buttons', 1, ImGui.TableFlags_SizingStretchSame | ImGui.TableFlags_PreciseWidths
  | ImGui.TableFlags_NoPadInnerX | ImGui.TableFlags_NoPadOuterX, ((m_window_width/4)*3)-ImGui.StyleVar_CellPadding+1)
  then
    ImGui.TableNextColumn(ctx)
    
        --if error_msg~=0 and ImGui.GetTime(ctx) < time +3 then
         -- analyze_bttn = ImGui.Button( ctx, error_msg_table[error_msg],-1, 0)
       -- else
          analyze_bttn = ImGui.Button( ctx, analyze_bttn_state[a_bttn_state],-1, 0)
        --end
     
    ImGui.EndTable(ctx)
  end
  end
  
  
  
  if  check_itm and quantize_state == false and not processing then
  
    if ImGui.BeginTable(ctx, 'buttons', 2, ImGui.TableFlags_SizingStretchSame | ImGui.TableFlags_PreciseWidths, ((m_window_width/4)*3)-ImGui.StyleVar_CellPadding+1)
    then
  
      ImGui.TableNextColumn(ctx)
  
        analyze_bttn = ImGui.Button( ctx, analyze_bttn_state[a_bttn_state],-1, 0.0)
      
      ImGui.TableNextColumn(ctx)
        if Qstrength_v > 0 then
         Q_bttn = ImGui.Button( ctx, 'Quantize', -1, 0.0) 
        else
         if mode == 1 then
          Q_bttn = ImGui.Button( ctx, 'Split', -1, 0.0) 
         else
          Q_bttn = ImGui.Button( ctx, 'Add Stretch Markers', -1, 0.0) 
         end
        end
  
    ImGui.EndTable(ctx) ------- end buttons
    end
  end  
  ImGui.PopStyleColor(ctx, 2)
    
  ImGui.EndTable(ctx)----------------------------------------------end total table
  end
  -------------------------------------------------------------------------------------------------------------
  ---------------------------------------visualizer------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------------

    if check_itm and not quantize_state and visualizer  then ----------------------------------START VISUALIZER IF CYCLE
      visualizer_h = 80
      if ImGui.BeginTable(ctx, 'Visualizertable', 1,  ImGui.TableFlags_SizingStretchProp, m_window_width-ImGui.StyleVar_CellPadding-2)
      then
      
      ImGui.TableNextColumn(ctx)
      --[[
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 8, 6)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 4, 0)
      ImGui.PushStyleVar(ctx, ImGui.StyleVar_GrabMinSize, ( m_window_width-ImGui.StyleVar_CellPadding-2)*new_zoom_pos_range)
      ImGui.PushItemWidth(ctx, -1)
      _, vis_scroll_v_pos =ImGui.SliderDouble(ctx, '##h_scrollbar',vis_scroll_v_pos,new_zoom_pos_range,1)
      ImGui.PopStyleVar(ctx, 3)
      ]]--
      ----------waveform background---------------------------------
      Waveform_Button_Style(0.5)
      ImGui.Button( ctx, '##Visualizerbutton',-1, -1-2)
      help_widget(Visual_Navigation_help)
      ImGui.PopStyleColor(ctx, 3)
      ----------waveform background---------------------------------

      histo_w, histo_h = ImGui.GetItemRectSize(ctx)
      histo_x, _ = ImGui.GetItemRectMin(ctx)
      _, histo_y = ImGui.GetItemRectMax(ctx)
    
      zoom_bounds_L, zoom_bounds_Total = waveform_visualizer()

      ImGui.EndTable(ctx) ---------- Visualizertable
      end 
      
      local y_center = histo_y - (histo_h/2)
      
  
      for i = 1, #line_array_pos do -------------------------Draw waveform
        local array_pos = line_array_pos[i]*waveform_zoom_gain
        local array_neg = line_array_neg[i]*waveform_zoom_gain
        if array_pos>1 then array_pos = 1 end
        if array_neg<-1 then array_neg = -1 end
        local ypos = (y_center - array_pos*((histo_h/2)-3))
        local yneg = (y_center - array_neg*((histo_h/2)-3))
        local x = histo_x + i -1
        ImGui.DrawList_AddLine(draw_list, x, yneg, x, ypos, 0xFF0000FF, 1 ) ---0xFFFF00FF
      end
      
      local Reduce_P_v = ((100-Sensitivity_v)/sens_def)
      
      for i = 1, #Gate_Gl.grid_Points, 2 do   ----------------------Draw trig points lines on Visualizer
        local vis_trig_line_pos = Gate_Gl.grid_Points[i] + (Offset_v/1000)*first_srate
        if vis_trig_line_pos>=zoom_bounds_L and vis_trig_line_pos<=zoom_bounds_L+zoom_bounds_Total and Gate_Gl.grid_Points[i+1][Detect+1] >= Reduce_P_v then
          local x = ((histo_w)*((vis_trig_line_pos-zoom_bounds_L)/zoom_bounds_Total))+histo_x
          --if r.GetMousePosition(ctx) < x+5 and r.GetMousePosition(ctx) > x-5 then
          --  ImGui.SetMouseCursor( ctx, ImGui.MouseCursor_Hand )
          --end
          local h = histo_h*Gate_Gl.grid_Points[i+1][Detect+1]
          local h2 = (histo_h-h)/2
          ImGui.DrawList_AddLine(draw_list, x, histo_y-h2, x, histo_y-h-h2, 0xFFFF00FF, QN_lineTHICK[i] )
        end
      end

      for i=2, #Grid_blocks_Ruler-1, 2 do ----- Draw grid on Visualizer
        if Grid_blocks_Ruler[i] ~= nil and Grid_blocks_Ruler[i]>=zoom_bounds_L and Grid_blocks_Ruler[i]<=zoom_bounds_L+zoom_bounds_Total then
          local x = ((histo_w)*((Grid_blocks_Ruler[i]-zoom_bounds_L)/zoom_bounds_Total))+histo_x
          ImGui.DrawList_AddLine(draw_list, x, histo_y, x, histo_y-histo_h, 0xFFFFFF00+Grid_blocks_Ruler_thickness[i]*10, Grid_blocks_Ruler_thickness[i] )
        end
      end
      
      -------------------------Draw threshold
      
      local Thresh_ypos = (y_center - display_Thresh*waveform_zoom_gain*((histo_h/2)-3))
      local Thresh_yneg = (y_center + display_Thresh*waveform_zoom_gain*((histo_h/2)-3))
      if display_Thresh*waveform_zoom_gain<=1 then
        ImGui.DrawList_AddLine(draw_list, histo_x, Thresh_ypos, histo_x+histo_w, Thresh_ypos, 0xFFFFFF60, 1 )
        ImGui.DrawList_AddLine(draw_list, histo_x, Thresh_yneg, histo_x+histo_w, Thresh_yneg, 0xFFFFFF60, 1 )
      end
      
      -------------------------Draw Playback and edit Cursor
      local cursorpos
      if r.GetPlayState() == 1 or r.GetPlayState() == 4 then
        cursorpos = first_srate*(r.GetPlayPositionEx(0)-first_sel_item_start)
      else
        cursorpos = (first_srate*(r.GetCursorPositionEx(0)-first_sel_item_start))//1
      end
      if cursorpos >= zoom_bounds_L and cursorpos <= zoom_bounds_L+zoom_bounds_Total then
        local relative_pos = (cursorpos-zoom_bounds_L)/zoom_bounds_Total
        local x_histo_pos = histo_x + histo_w*relative_pos
        ImGui.DrawList_AddLine(draw_list, x_histo_pos, histo_y, x_histo_pos, histo_y-histo_h, 0x00FFFFFF, 1 )
      end
    else
        visualizer_h = 0
  end -----------------------------------END VISUALIZER IF CYCLE
  
  -------------------------------------------------------------------------------------------------------------
  ---------------------------------------visualizer------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------------

   if  check_itm == true and Q_bttn and quantize_state == false then
     store_wavesum = {}
     DestroyBitmap()
     Gate_Gl.State_Points = Gate_Gl:Reduce_Points_by_Power2(Gate_Gl.grid_Points) 
     Split_Quantize_items()
     quantize_state = true
     reset_Histogram()
     check_itm = false
   end
   
    

  
    ImGui.PopStyleVar( ctx, 3)
    
ImGui.End(ctx)
end ----------------end if visible
ImGui.PopStyleColor(ctx,1)
ImGui.PopStyleVar( ctx, 3)
ImGui.PopFont(ctx)
-----------------------------END LAYOUT----------------------------------------
-------------------------------------------------------------------------------

if analyze_bttn then --or check_itm and ( sensitivity_slider or Thresh_slider) then 
  waveform_zoom_h = 1
  h_zoom_center = 0
  store_wavesum = {}
  time_gap = r.time_precise()+0.1
  givemetime()

end
if (((hicut_edit or lowcut_edit or transient_rv or gain_edit) and filter_on) or filter_button or Rtrig_edit or
Thresh_edit or GridScan_rv  or sens_v_rv or normalize_sens_scale_rv ) and check_itm then
  time_gap = r.time_precise()+0.1
  givemetime2()
end

if Visualizer_mode == 0 then
  if check_itm and (visualizer_rv or Visualizer_mode_rv) then
    movescreen_prev = {}
    Triglinesdraw()
  end
else
  if check_itm and (visualizer_rv or Visualizer_mode_rv) then
    if MW_lines_ON then
      DestroyBitmap()
    else
      movescreen_prev = {}
      Triglinesdraw()
    end
  end
end

if check_itm and Gtolerance_slider then
    Gate_Gl.grid_Points  = Gate_Gl:Reduce_Points_by_Grid2(Gate_Gl.store_Normalized_State_Points)
    Gate_Gl:sens_histogram(Gate_Gl.grid_Points)
    Trig_line_thickness(Gate_Gl.grid_Points)
    Triglinesdraw()
end

if  check_itm and color_button then
    local red, green, blue = ImGui.ColorConvertHSVtoRGB(linecolor_v, 1, 1 )
    linecolor = RGB(floor(red*255),floor(green*255) ,floor(blue*255) )
    Triglinesdraw()
end

if  (Sensitivity_slider or Detect_rv2 or Detect_rv) and check_itm then
     Gate_Gl:sens_histogram(Gate_Gl.grid_Points)
end

if Grid or Swing_toggle or Swing or Triplets_rv  then 
  set_grid_from_script()
  if check_itm then
  Change_grid = true
    Gate_Gl.grid_Points  = Gate_Gl:Reduce_Points_by_Grid2(Gate_Gl.store_Normalized_State_Points)
    Gate_Gl:sens_histogram(Gate_Gl.grid_Points)
    Trig_line_thickness(Gate_Gl.grid_Points)
    Triglinesdraw()
  end
  Change_grid = false
end 

_, divis, Swing_on, Swing_Slider = r.GetSetProjectGrid(0, 0) ----- check if grid being changed in main window
if divis ~= store_divis or Swing_on ~= store_Swing_on or Swing_Slider ~= store_Swing_Slider then 
  get_grid_from_proj() 
  if check_itm == true then
  Change_grid = true
    Gate_Gl.grid_Points  = Gate_Gl:Reduce_Points_by_Grid2(Gate_Gl.store_Normalized_State_Points)
    Gate_Gl:sens_histogram(Gate_Gl.grid_Points)
    Trig_line_thickness(Gate_Gl.grid_Points)
    Triglinesdraw()
  end
  Change_grid = false
end

if ImGui.IsKeyPressed(ctx, ImGui.Key_Space) then -----keep transport playstop even when focusing the script
  r.Main_OnCommandEx(40044, 0, 0)
end

if open and not ImGui.IsKeyPressed(ctx, ImGui.Key_Escape) then -------------------exit script with ESC
  r.defer(Main_loop)
else
  exit()
end

end -------------end main loop

r.defer(Main_loop)

-----------------------------FINE-----------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

r.atexit(exit)


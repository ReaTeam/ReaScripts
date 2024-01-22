-- @description MK Shaper/Stutter
-- @author cool
-- @version 1.20
-- @changelog
--   + Added Razor Edit.
--   + Now the script can manage any selected envelopes. If the envelope is not selected before running the script, the script will create a volume envelope by default.
--   + The name of the active Envelope is now displayed in the script interface.
--   + Added envelope selector for Items (Volume, Pan, Pitch).
--   + Rise and Fall for the Pan envelope have been adjusted. The Gain control changes the range.
--   + The range has been increased and the principle of operation of the Gain regulator has been changed.
--   + Added "Soft Attack" option.
--   + Significantly improved script performance when processing Selected Area.
--   + Reset now correctly removes multitrack envelopes and selected areas.
--   + True Stutter mode: When the Shape control is at maximum, the envelope takes on a rectangular shape.
--   + Fixed a bug: sometimes in item envelope mode the points were not placed correctly if the item had a changed ratio.
--   + Fixed a bug: now changing the Shift option does not cause the script to crash if this is done before pressing the Shape button.
--   + Fixed a bug: flickering and incorrect position of item envelope points in Rise and Fall modes.
--   + Fixed a bug: points were not placed correctly if the item was placed at the start of the project.
--   + Fixed a bug: now the script does not crash when trying to process Empty Items.
--   + Fixed a bug: now the point of the first transient is drawn correctly if it is not at the start of the item.
--   + Fixed a bug that slowed down the update of the script window when Loop was running.
--   + Fixed a bug: now the DestroyAudioAccessor function works correctly.
--   + Now loop selection is captured by the script only when controlled from the script interface.
--   + The minimum grid and ruler resolution has been limited: now long items and small grid resolutions do not overload the processor.
--   + Optimization in general: now the script starts instantly. CPU load reduced by 50% when idle.
--   + Controls have been streamlined for more intuitive operation.
--   + Work without items: if there are no items in the selected area, the script will run in Grid and Track Envelope mode.
--   + Now, when working with midi items and without items, the script runs almost instantly, without wasting resources on processing.
--   + Added the option to manage all envelopes at once. When disabled, the script controls only the selected one.
--   + Now, when zooming horizontally using the keyboard keys, the waveform is centered on the edit cursor.
--   + The minimum HPF value turns off the filter, completely removing filtering artifacts.
--   + Increased the maximum waveform window width and main window size limits for better display on large screens.
--   + Theme: Added the option "Large Font Size" (Options - User Settings (Advanced)), which increases the font size when the window size is large.
--   + Undo Points are now created during envelope generation.
--   + Donate service has been changed to valid.
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=254081
-- @screenshot Main View https://i.imgur.com/DAe0EY7.jpg
-- @donation Donate via BuyMeACoffee https://www.buymeacoffee.com/MaximKokarev
-- @about
--   MK Shaper/Stutter is a script for quick envelope operations based on transients or rhythm grid.
--
--   -The script is based on the time-tested MK Slicer.
--   -Completely non-destructive audio processing based on envelopes manipulations. Realtime envelope operations.
--   -Basic operations: Transient or Grid shaping (Ableton Sampler like), emphasizing or suppressing attacks, shortening the tails of sounds, gating percussion, steady rhythmic pulsation (stutter), sidechain pulsation based on transients or grid. Working with the grid also includes triplets and swing.
--   -Ability to work with multitracks. Ability to work with many items. Ability to work with MIDI items (only in Grid mode).
--   -The Attack parameter depends on the Velocity of the transients. Several modes are available.
--
--   Instructions for use:
--
--   1. Select one track and select the area with the item. Or: just select the item(s) on the same track without selecting an area. The script will not start, several tracks are selected.
--   2. Run the script.
--   3. Done! You can work. To form envelopes click "Shape".
--   To cancel an actions, use "Reset" button. Reset sliders to default: Ctrl + Click. Fine tune: Shift + Drag(or MouseWheel). Exit the script: Esc, Space - Play. 
--   Also, after running the script, you can select the track on which you want to form an envelope and click "Shape".

--[[
MK Shaper/Stutter v1.20 by Maxim Kokarev 
https://forum.cockos.com/member.php?u=121750

Thanks to Anton (MyDaw)
https://www.facebook.com/MyDawEdition/

"Grid switch" (snippet)
code by Archie
https://forum.cockos.com/member.php?u=120700

"Delete selected items active take envelopes"
script by IXix
https://forum.cockos.com/member.php?u=2949

Based on "Drums to MIDI(beta version)" script by eugen2777
http://forum.cockos.com/member.php?u=50462  

Razor Edit functions by Juliansander
https://forum.cockos.com/showthread.php?t=241604
]]

----------------------------------------------------------------------------
-- Some functions(local functions work faster in big cicles(~30%)) ------------
-- R.Ierusalimschy - "lua Performance Tips" ----------------------------------
----------------------------------------------------------------------------
local r = reaper
local abs  = math.abs
local min  = math.min
local max  = math.max
local sqrt = math.sqrt
local ceil  = math.ceil
local floor = math.floor   
local exp = math.exp
local logx = math.log
local huge = math.huge      
local random = math.random

Slice_Status = 1
SliceQ_Status = 0
MarkersQ_Status = 0
Slice_Init_Status = 0
SliceQ_Init_Status = 0
Markers_Init_Status = 0
Markers_Status = 0
MIDISmplr_Status = 0
Trigg_Status = 0
Take_Check = 0
Reset_Status = 0
MouseUpX = 0
MIDISampler = 0
Midi_sampler_offs_stat = 0
Reset_to_def = 0
RE_Status = 0
Swing_on = 0
Grid1_on = 0
Grid2_on = 0
Grid4_on = 0
Grid8_on = 0
Grid16_on = 0
Grid32_on = 0
Grid64_on = 0
GridT_on = 0
Gate_on = 0
Gate_on2 = 0
Midi_Check = 0
WaveCheck = 0
Undo_Permit = 0
Show_process_wait_is_active = 0
----------------------------Advanced Settings-------------------------------------------

RememberLast = 1            -- (Remember some sliders positions from last session. 1 - On, 0 - Off)
SnapToStart = 1 --(Snap Play Cursor to Waveform Start. 1 - On, 0 - Off)
WFiltering = 0 -- (Waveform Visual Filtering while Window Scaling. 1 - On, 0 - Off)
ShowRuler = 1 -- (Show Project Grid Green Markers. 1 - On, 0 - Off)
ShowInfoLine = 0 -- (Show Project Info Line. 1 - On, 0 - Off)
Markers_Btns = 0  -- (Show MK_Slicer's Markers Operation Controls. 1 - On, 0 - Off)
ForceSync = 0 -- (force Sync On on the script starts: 1 - On (Always On), 0 - Off (Default, Save Previous State))
Pitch_Range = 24 -- (Pitch Envelope Range, Half Tones: default 24)

------------------------End of Advanced Settings----------------------------------------

-----------------------------------States and UA  protection-----------------------------

Docked = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','Docked'))or 0;
EscToExit = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','EscToExit'))or 1;
InvOnByDefault = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','InvOnByDefault'))or 2;
EnvItemOnClose = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','EnvItemOnClose'))or 0;
MIDI_Mode = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','Midi_Sampler.norm_val'))or 1;
Sampler_preset_state = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','Sampler_preset.norm_val'))or 1;
AutoScroll = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','AutoScroll'))or 0;
PlayMode = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','PlayMode'))or 0;
Loop_on = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','Loop_on'))or 1;

   if ForceSync == 1 then
       Sync_on = 1
         else
       Sync_on = tonumber(r.GetExtState('cool_MK Slicer.lua','Sync_on'))or 0;
   end

Sync_on = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','Sync_on'))or 0;
TrackEnv = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','TrackEnv'))or 1;
VolPreFX = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','VolPreFX'))or 1;
SelectedEnvOnly = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','SelectedEnvOnly'))or 0;
ObeyingItemSelection = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','ObeyingItemSelection'))or 0;
MaxFontSizeSt = tonumber(r.GetExtState('MK_Slicer_3','MaxFontSizeSt'))or 0;
if MaxFontSizeSt == 1 then MaxFontSize = 24 else MaxFontSize = 18 end
XFadeOff = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','XFadeOff'))or 0;
Guides_mode = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','Guides.norm_val'))or 1;
OutNote_State = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','OutNote.norm_val'))or 1;
HiPrecision_On = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','HiPrecision_On'))or 0;
VeloRng = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','Gate_VeloScale.norm_val'))or 0.231;
VeloRng2 = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','Gate_VeloScale.norm_val2'))or 1;

if RememberLast == nil then RememberLast = 1 end 
if RememberLast <= 0 then RememberLast = 0 elseif RememberLast >= 1 then RememberLast = 1 end 
if WFiltering == nil then WFiltering = 1 end 
if WFiltering <= 0 then WFiltering = 0 elseif WFiltering >= 1 then WFiltering = 1 end 

    r.Undo_BeginBlock() 
r.PreventUIRefresh(1)


left, right = huge, -huge
for t = 0, reaper.CountTracks(0)-1 do
    local track = reaper.GetTrack(0, t)
    local tR = {}
    local razorOK, razorStr = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    if razorOK and #razorStr ~= 0 then
        for razorLeft, razorRight, envGuid in razorStr:gmatch([[([%d%.]+) ([%d%.]+) "([^"]*)"]]) do
            if envGuid == "" then
                local razorLeft, razorRight = tonumber(razorLeft), tonumber(razorRight)
            if razorLeft  < left  then left  = razorLeft end
            if razorRight > right then right = razorRight end
                table.insert(tR, {left = razorLeft, right = razorRight})
            end
        end

       if razorOK and #razorStr ~= 0 then
           reaper.Main_OnCommand(40297,0)
           reaper.SetTrackSelected(track, true)
       else
           reaper.SetTrackSelected(track, false)
       end

    end
    for i = 0, reaper.CountTrackMediaItems(track)-1 do
        local item = reaper.GetTrackMediaItem(track, i)
  --      reaper.SetMediaItemSelected(item, false)
        local left = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local right = left + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        for _, r in ipairs(tR) do
            if left < r.right and right > r.left then
                reaper.SetMediaItemSelected(item, true)
            end
        end
    end
end
if left <= right then
    reaper.GetSet_LoopTimeRange2(0, true, false, left, right, false)
end
reaper.UpdateArrange()


 loopcheck = 0
local cursorpos = r.GetCursorPosition()
----loopcheck------
local loopcheckstart, loopcheckending = r.GetSet_LoopTimeRange( 0, false, 0, 0, 0 )

if loopcheckstart == loopcheckending then
     r.Main_OnCommand(41039, 0) -- Loop points: Set loop points to items
     r.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items
else
     r.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
end

NoItems = 0
if r.CountSelectedMediaItems(0) == 0 and r.CountSelectedTracks(0) == 1 then -- if no items, create new-----

     Table = {}
     Table2 = {}

     track = r.GetSelectedTrack(0, 0)
     if loopcheckstart ~= loopcheckending then
       midiItem = r.CreateNewMIDIItemInProj(track, loopcheckstart, loopcheckending, false) -- loopcheckstart+0.0001
       new_tk = r.GetActiveTake(midiItem)
       r.SetMediaItemInfo_Value(midiItem, "B_UISEL", 1) -- select item
       r.SetMediaItemInfo_Value(midiItem, "I_CUSTOMCOLOR",r.ColorToNative(25,25,25)|0x1000000)
       r.GetSetMediaItemTakeInfo_String(new_tk, 'P_NAME', 'Temporary item. Will be deleted automatically after closing the script.', 1)
       Table[track] = track
       Table2[midiItem] = midiItem
       NoItems = 1
     end

end ----------------------------------------------------------------

if loopcheckstart == loopcheckending and loopcheckstart and loopcheckending then 
     loopcheck = 0
       else
     loopcheck = 1
end
r.SetEditCurPos(cursorpos,0,0) 

function GetLoopTimeRange()
start, ending = r.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
end

------------------------------Detect MIDI takes-------------------------------------------

function midi_check()

local i=0;
while(true) do;
  i=i+1;
  local item = r.GetSelectedMediaItem(0,i-1);
  if item then;
  active_take = r.GetActiveTake(item)  -- active take in item
    if active_take then 
       take_pcm_source2 = r.GetMediaItemTake_Source(active_take)
       take_source_sample_rate = r.GetMediaSourceSampleRate(take_pcm_source2)

            if take_source_sample_rate ~= 0 then 
                 WaveCheck = 1 
            end

            if r.TakeIsMIDI(active_take) then
                 Midi_Check = 1 
            end

     end

  else;
    break;
  end;
end;

end
midi_check()


r.PreventUIRefresh(-1)
    r.Undo_EndBlock("Init", -1) 

------------------------------Prepare Item(s) and Foolproof---------------------------------

 

function collect_itemtake_param()    -- collect parameter on sel item and active take for SM tables and displacement calcs...
   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item 
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   mute_check = r.GetMediaItemInfo_Value(sel_item, "B_MUTE")
 end

   collect_itemtake_param()              -- get bunch of parameters about this item

if selected_tracks_count > 1 then 
--gfx.quit() 
--r.ShowConsoleMsg("Only single track items, please. User manual: https://forum.cockos.com/showthread.php?t=232672")
--return 
end -- не запускать, если айтемы находятся на разных треках.

----------------------------------Get States from last session-----------------------------

if RememberLast == 1 then
CrossfadeTime = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','CrossfadeTime'))or 15;
QuantizeStrength = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','QuantizeStrength'))or 100;
Offs_Slider = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','Offs_Slider'))or 0.5;
HF_Slider = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','HF_Slider'))or 0.3312;
LF_Slider = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','LF_Slider'))or 1;
Sens_Slider = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','Sens_Slider'))or 0.375;
else
CrossfadeTime = DefaultXFadeTime or 15;
QuantizeStrength = DefaultQStrength or 100;
Offs_Slider = DefaultOffset or 0.5;
HF_Slider = DefaultHP or 0.3312;
LF_Slider = DefaultLP or 1;
Sens_Slider = DefaultSens or 0.375;
end


--------------------------------------------------------------------------------------------

function getsomerms()

r.Undo_BeginBlock(); r.PreventUIRefresh(1)

local itemproc = r.GetSelectedMediaItem(0,0)

 if itemproc  then
   local tk = r.GetActiveTake(itemproc)

 function get_average_rms(take, adj_for_take_vol, adj_for_item_vol)
   local RMS_t = {}
   if take == nil then return end
   local item = r.GetMediaItemTake_Item(take) -- Get parent item
   if item == nil then return end

   local aa = r.CreateTakeAudioAccessor(take)
   if aa == nil then return end
   
   local aa_start = r.GetAudioAccessorStartTime(aa)
   local aa_end = r.GetAudioAccessorEndTime(aa)
   local a_length = (aa_end - aa_start)/5

   local take_pcm_source = r.GetMediaItemTake_Source(take)
   if take_pcm_source == nil then 
      take_source_num_channels = 2
      take_source_sample_rate = 44100
       else
      take_source_num_channels =  r.GetMediaSourceNumChannels(take_pcm_source)
      take_source_sample_rate = r.GetMediaSourceSampleRate(take_pcm_source)
    end
 
if take_source_sample_rate == 0 then take_source_sample_rate = 44100 end -- if MIDI item, create fake samplerate           

   if take_source_num_channels > 2 then take_source_num_channels = 2 end
   local channel_data = {} -- channel data is collected to this table

   for i=1, take_source_num_channels do
    channel_data[i] = {
                         rms = 0,
                         sum_squares = 0 -- (for calculating RMS per channel)
                       }
   end

   local samples_per_channel = take_source_sample_rate/10
   
   local buffer = r.new_array(samples_per_channel * take_source_num_channels)
   buffer.clear()
   local total_samples = (aa_end - aa_start) * (take_source_sample_rate/a_length)
   
   if total_samples < 1 then return end

   local sample_count = 0
   local offs = aa_start
   local log10 = function(x) return logx(x, 10) end

   while sample_count < total_samples do

     local aa_ret =  r.GetAudioAccessorSamples(
                                             aa,                       -- AudioAccessor accessor
                                             take_source_sample_rate,  -- integer samplerate
                                             take_source_num_channels, -- integer numchannels
                                             offs,                     -- number starttime_sec
                                             samples_per_channel,      -- integer numsamplesperchannel
                                             buffer                    -- r.array samplebuffer
                                           )
       
     if aa_ret == 1 then
      local buffer_l = #buffer
       for i=1, buffer_l, take_source_num_channels do
         if sample_count == total_samples then
           break
         end
         for j=1, take_source_num_channels do
           local buf_pos = i+j-1
           local spl = buffer[buf_pos]
           channel_data[j].sum_squares = channel_data[j].sum_squares + spl*spl
         end
         sample_count = sample_count + 1
       end
     elseif aa_ret == 0 then -- no audio in current buffer
       sample_count = sample_count + samples_per_channel
     else
       return
     end
     
     offs = offs + samples_per_channel / take_source_sample_rate -- new offset in take source (seconds)
   end -- end of while loop
   
   r.DestroyAudioAccessor(aa)
    
   adjust_vol = 1
   
   if adj_for_take_vol then
     adjust_vol = adjust_vol * r.GetMediaItemTakeInfo_Value(take, "D_VOL")
     if adjust_vol < 0 then adjust_vol = (adjust_vol * -1) end -- if phase is inverted
   end
   
   if adj_for_item_vol then
     adjust_vol = adjust_vol * r.GetMediaItemInfo_Value(item, "D_VOL")
   end
   
   for i=1, take_source_num_channels do
     local curr_ch = channel_data[i]
     curr_ch.rms = sqrt(curr_ch.sum_squares/total_samples) * adjust_vol
       RMS_t[i] = 20*log10(curr_ch.rms)
   end
   return RMS_t
 end

local getrms
       if tk ~= nil and Take_Check == 0 then  
           getrms = get_average_rms( tk, 0, 0)
             else
           getrms = {-20}
       end
 ----------------------------------------------------------------------------------
 
local inf = 1/0

 for i=1, #getrms do
 rms = ceil(getrms[i])
 end

if rms <= -30 then rms = -30 end
if rms == -inf then rms = -20 end

local rmsresult = string.sub(rms,1,string.find(rms,'.')+5)

readrms = 1-(rmsresult*-0.015)
out_gain = (rmsresult+12)*-0.03

if readrms > 1 then readrms = 1 elseif readrms < 0 then readrms = 0 end
if out_gain > 1 then out_gain = 1 elseif out_gain < 0 then out_gain = 0 end

else

readrms = 0.65
out_gain = 0.15

end

orig_gain = out_gain*1200

end

if tk == nil then 
   readrms = 0.65
   out_gain = 0.15
end

getsomerms()     
     
function ClearExState()

r.DeleteExtState('_Slicer_', 'ItemToSlice', 0)
r.DeleteExtState('_Slicer_', 'TrackForSlice', 0)
r.SetExtState('_Slicer_', 'GetItemState', 'ItemNotLoaded', 0)

end

ClearExState()

-- Is SWS installed?
if not r.APIExists("ULT_SetMediaItemNote") then
    r.ShowMessageBox("This script requires the SWS/S&M extension.\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org.", "ERROR", 0)
    return false 
end  

getitem = 1

function GetTempo()
    tempo = r.Master_GetTempo()
    tempo_corr = 1/(r.Master_GetTempo()/120)
    retoffset = (60000/tempo)/16 - 20
    retrigms = retoffset*0.00493 or 0.0555
end
GetTempo()
---------------------Initial Swing Set---------------------------------------------
    _, _, swng_on, swngdefamt = r.GetSetProjectGrid(0,false)
   if swngdefamt then
       swngdefamt = (swngdefamt+1)/2   
   end
    if swng_on == 1 then 
       Swing_on = 1 
     end
r.PreventUIRefresh(-1); r.Undo_EndBlock('Shaper/Stutter Start', -1)

--------------------------------------------------------------------------------
---------------------Retina Check-----------------------------------------------
--------------------------------------------------------------------------------
local retval, dpi = r.ThemeLayout_GetLayout("mcp", -3) -- get the current dpi
--Now we need to tell the gfx-functions, that Retina/HiDPI is available(512)
if dpi == "512" then -- if dpi==retina, set the gfx.ext_retina to 1, else to 0
  gfx.ext_retina=1 -- Retina
else
  gfx.ext_retina=0 -- no Retina
end
---------------------------------------------------------------
----------------------Rounding-------------------------------
---------------------------------------------------------------
math_round = function(num, idp) -- rounding
  local mult = 10^(idp or 0)
  return floor(num * mult + 0.5) / mult
end
---------------------------------------------------------------
----------------------Find Even/Odd---------------------------
---------------------------------------------------------------
function IsEven(num)
  return num % 2 == 0
end
--------------------------------------------------------------------------------
---   Simple Element Class   ---------------------------------------------------
--------------------------------------------------------------------------------
local Element = {}
function Element:new(x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, norm_val,norm_val2, fnt_rgba)
    local elm = {}
    elm.def_xywh = {x,y,w,h,fnt_sz} -- its default coord,used for Zoom etc
    elm.x, elm.y, elm.w, elm.h = x, y, w, h
    elm.r, elm.g, elm.b, elm.a = r, g, b, a
    elm.lbl, elm.fnt, elm.fnt_sz = lbl, fnt, fnt_sz
    elm.fnt_rgba = fnt_rgba or {0.8, 0.8, 0.8, 0.9} --цвет текста кнопок, фреймов и слайдеров
    elm.norm_val = norm_val
    elm.norm_val2 = norm_val2
    ------
    setmetatable(elm, self)
    self.__index = self 
    return elm
end

--------------------------------------------------------------
--- Function for Child Classes(args = Child,Parent Class) ----
--------------------------------------------------------------
function extended(Child, Parent)
  setmetatable(Child,{__index = Parent}) 
end
--------------------------------------------------------------
---   Element Class Methods(Main Methods)   ------------------
--------------------------------------------------------------
function Element:update_xywh()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  local zoom_coeff =   (gfx_width/1200)+1
  if zoom_coeff <= 2.044 then zoom_coeff = 2.044 end 
  self.x, self.w = (self.def_xywh[1]* Z_w/zoom_coeff)*2.045, (self.def_xywh[3]* Z_w/zoom_coeff)*2.045-- upd x,w
  self.x = self.x+(zoom_coeff-2.044)*380 -- auto slide to right when zoom
  self.x = math_round(self.x,2)
  self.w = math_round(self.w,2)
  self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* Z_h) -- upd y,h
  if self.fnt_sz then --fix it!--
     local  Z_w2 = Z_w
     local  Z_h2 = Z_h
           if gfx.ext_retina == 1 then
                self.fnt_sz = max(14,self.def_xywh[5]* 1.2)
                self.fnt_sz = min(15,self.fnt_sz* Z_h2)
           else
                self.fnt_sz = max(15,self.def_xywh[5]* 1.2)
                self.fnt_sz = min(16,self.fnt_sz* Z_h2)
           end
  end  
end

------------------------
function Element:pointIN(p_x, p_y)
  return p_x >= self.x and p_x <= self.x + self.w and p_y >= self.y and p_y <= self.y + self.h
end
--------
function Element:mouseIN()
  return gfx.mouse_cap&1==0 and self:pointIN(gfx.mouse_x,gfx.mouse_y)
end
------------------------
function Element:mouseDown()
  return gfx.mouse_cap&1==1 and self:pointIN(mouse_ox,mouse_oy)
end
--------
function Element:mouseUp() -- its actual for sliders and knobs only!
  return gfx.mouse_cap&1==0 and self:pointIN(mouse_ox,mouse_oy)
end
--------
function Element:mouseClick()
  return gfx.mouse_cap&1==0 and last_mouse_cap&1==1 and
  self:pointIN(gfx.mouse_x,gfx.mouse_y) and self:pointIN(mouse_ox,mouse_oy)         
end
------------------------
function Element:mouseR_Down()
  return gfx.mouse_cap&2==2 and self:pointIN(mouse_ox,mouse_oy)
end
--------
function Element:mouseM_Down()
  return gfx.mouse_cap&64==64 and self:pointIN(mouse_ox,mouse_oy)
end
------------------------
function Element:draw_frame()
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local an = 1.02
    if self:mouseIN() then an=an+0.25 end
    if self:mouseDown() then an=an+0.35 end
  gfx.set(0.259,0.357,0.592,an) -- sliders and checkboxes borders
  gfx.rect(x, y, w, h, false)            -- frame1      
end

function Element:draw_frame_g()
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local an = 1.02
    if self:mouseIN() then an=an+0.25 end
    if self:mouseDown() then an=an+0.35 end
  gfx.set(0.2,0.47,0.39,an) -- sliders and checkboxes borders
  gfx.rect(x, y, w, h, false)            -- frame1      
end

function Element:draw_frame_r()
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local an = 1.02
    if self:mouseIN() then an=an+0.25 end
    if self:mouseDown() then an=an+0.35 end
  gfx.set(0.484,0.244,0.214,an) -- sliders and checkboxes borders
  gfx.rect(x, y, w, h, false)            -- frame1      
end

function Element:draw_frame_v()
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local an = 1.02
    if self:mouseIN() then an=an+0.25 end
    if self:mouseDown() then an=an+0.35 end
  gfx.set(0.37,0.26,0.6,an) -- sliders and checkboxes borders
  gfx.rect(x, y, w, h, false)            -- frame1      
end

function Element:draw_frame_rng()
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local an = 1.02
    local rn = 0.259
    local gn = 0.357
    local bn = 0.592
    if self:mouseIN() then 
an=an+0.25 
rn = 0.29
gn = 0.29
bn = 0.34
end
    if self:mouseDown() then 
an=an+0.35 
rn = 0.30
gn = 0.30
bn = 0.35
end
  gfx.set(rn,gn,bn,an) -- sliders and checkboxes borders
  gfx.rect(x, y, w, h, false)            -- frame1      
end

function Element:draw_frame_loop()
  local x,y,w,h  = self.x,self.y,self.w,self.h*24
    local r,g,b,a  = self.r,self.g,self.b,self.a
  gfx.set(0.3,0.3,0.35,0.2) -- sliders and checkboxes borders
  gfx.rect(x, y, w, h, true)            -- frame1      
end

function Element:draw_frame2()
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
  gfx.set(0.3,0.3,0.3,1) -- main frames
  gfx.rect(x, y, w, h, false)            -- frame1      
end

function Element:draw_frame3()
  local x,y,w,h  = self.x,self.y,self.w,self.h
 --   local r,g,b,a  = self.r,self.g,self.b,self.a
--  gfx.set(0.25,0.25,0.25,1) -- waveform window and buttons frames
  gfx.rect(x, y, w, h, false)            -- frame1      
end

function Element:draw_frame4()
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
  gfx.set(0.22,0.22,0.22,1) -- main frames
  gfx.rect(x, y, w, h, false)            -- frame1     
end

function Element:draw_frame_filled()
  local x,y,w,h  = self.x,self.y,self.w,self.h
  gfx.rect(x, y, w, h, true)            -- filled areas      
end

function Element:draw_rect()
  local x,y,w,h  = self.x,self.y,self.w,self.h
  gfx.set(0,0,0,0.3) -- цвет фона окна waveform
  gfx.rect(x, y, w, h, true)            -- frame1      
end

----------------------------------------------------------------------------------------------------
---   Create Element Child Classes(Button,Slider,Knob)   -------------------------------------------
----------------------------------------------------------------------------------------------------
  local Button, Button_small, Button_top, Button_Settings, Slider, Slider_small, Slider_simple, Slider_simple_r, Slider_simple_g, Slider_simple_g_bias, Slider_simple_v, Slider_complex, Slider_Fine, Slider_Swing, Slider_fgain, Rng_Slider, Knob, CheckBox, CheckBox_simple, CheckBox_Show, CheckBox_Red, CheckBox_Green, Frame, Colored_Rect, Colored_Rect_top, Frame_filled, ErrMsg, Txt, Txt2, Line, Line_colored, Line2 = {},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}
  extended(Button,     Element)
  extended(Button_small,     Element)
  extended(Button_top,     Element)
  extended(Button_Settings,     Element)
  extended(Knob,       Element)
  extended(Slider,     Element)
  extended(Slider_small,     Element)
  extended(Slider_simple,     Element)
  extended(Slider_simple_r,     Element)
  extended(Slider_simple_g,     Element)
  extended(Slider_simple_g_bias,     Element)
  extended(Slider_simple_v,     Element)
  extended(Slider_complex,     Element)
  extended(Slider_Fine,     Element)
  extended(Slider_Swing,     Element)
  extended(Slider_fgain,     Element)
  extended(ErrMsg,     Element)
  extended(Txt,     Element)
  extended(Txt2,     Element)
  extended(Line,     Element)
  extended(Line_colored,     Element)
  extended(Line2,     Element)
    -- Create Slider Child Classes --
  local H_Slider, V_Slider, T_Slider, HP_Slider, LP_Slider, G_Slider, S_Slider, Rtg_Slider, Loop_Slider, Rdc_Slider, O_Slider, Sw_Slider, Q_Slider, Q_Slider_Red, Q_Slider_Green, Q_Slider_Green_Bias, Q_Slider_Violet, X_Slider, X_SliderOff = {},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}
    extended(H_Slider, Slider_small)
    extended(V_Slider, Slider)
    extended(T_Slider, Slider)
    extended(HP_Slider, Slider_complex)
    extended(LP_Slider, Slider_complex)
    extended(G_Slider, Slider_fgain)
    extended(S_Slider, Slider)
    extended(Rtg_Slider, Slider)
    extended(Rtg_Slider, Slider)
    extended(Rdc_Slider, Slider)
    extended(O_Slider, Slider_Fine)
    extended(Sw_Slider, Slider_Swing)
    extended(Q_Slider, Slider_simple)
    extended(Q_Slider_Red, Slider_simple_r)
    extended(Q_Slider_Green, Slider_simple_g)
    extended(Q_Slider_Green_Bias, Slider_simple_g_bias)
    extended(Q_Slider_Violet, Slider_simple_v)
    extended(X_Slider, Slider_simple)
    extended(X_SliderOff, Slider)
    ---------------------------------
  extended(Rng_Slider, Element)
  extended(Loop_Slider, Element)
  extended(Frame,      Element)
  extended(Colored_Rect,      Element)
  extended(Colored_Rect_top,      Element)
  extended(Frame_filled,      Element)
  extended(CheckBox,   Element)
  extended(CheckBox_simple,   Element)
  extended(CheckBox_Show,   Element)
  extended(CheckBox_Red,   Element)
  extended(CheckBox_Green,   Element)
--------------------------------------------------------------------------------
---   Buttons Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function Button_small:draw_body()
    gfx.rect(self.x+1,self.y+1,self.w-2,self.h-2,true) -- draw btn body
end
--------
function Button_small:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+(h-lbl_h)/2
    gfx.drawstr(self.lbl)
end
------------------------
function Button_small:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h/1.2)
    if fnt_sz <= 9 then fnt_sz = 9 end
    if fnt_sz >= MaxFontSize-1 then fnt_sz = MaxFontSize-1 end
    -- Get mouse state ---------
          -- in element --------
          if self:mouseIN() then a=a+0.3 end
          -- in elm L_down -----
          if self:mouseDown() then a=a-0.5 end
          -- in elm L_up(released and was previously pressed) --
          if self:mouseClick() and self.onClick then self.onClick() end
    -- Draw btn body, frame ----
    gfx.set(r,g,b,a)    -- set body color
    self:draw_body()    -- body
    self:draw_frame3()   -- frame
    -- Draw label --------------
    gfx.set(table.unpack(self.fnt_rgba))   -- set label color
    gfx.setfont(1, fnt, fnt_sz) -- set label fnt
    self:draw_lbl()             -- draw lbl
end

--------------------------------------------------------------------------------
function Button:draw_body()
    gfx.rect(self.x+1,self.y+1,self.w-2,self.h-2,true) -- draw btn body
end
--------
function Button:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+(h-lbl_h)/2+1
    gfx.drawstr(self.lbl)
end
------------------------
function Button:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element --------
          if self:mouseIN() then a=a+0.3 end
          -- in elm L_down -----
          if self:mouseDown() then a=a-0.5 end
          -- in elm L_up(released and was previously pressed) --
          if self:mouseClick() and self.onClick then self.onClick() end
    -- Draw btn body, frame ----
    gfx.set(r,g,b,a)    -- set body color
    self:draw_body()    -- body
    self:draw_frame3()   -- frame
    -- Draw label --------------
    gfx.set(table.unpack(self.fnt_rgba))   -- set label color
    gfx.setfont(1, fnt, fnt_sz) -- set label fnt
    self:draw_lbl()             -- draw lbl
end

--------------------------------------------------------------------------------

function Button_top:draw_body()
    gfx.rect(self.x+1,self.y+1,self.w-2,self.h-2,true) -- draw btn body
end
--------
function Button_top:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+(h-lbl_h)/2
    gfx.drawstr(self.lbl)
end
------------------------
function Button_top:draw()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = (self.def_xywh[1]* Z_w) , (self.def_xywh[3]* Z_w) -- upd x,w
  self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* Z_h) -- upd y,h
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 10 then fnt_sz = 10 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element --------
          if self:mouseIN() then a=a+0.3 end
          -- in elm L_down -----
          if self:mouseDown() then a=a-0.5 end
          -- in elm L_up(released and was previously pressed) --
          if self:mouseClick() and self.onClick then self.onClick() end
    -- Draw btn body, frame ----
    gfx.set(r,g,b,a)    -- set body color
    self:draw_body()    -- body
    self:draw_frame3()   -- frame
    -- Draw label --------------
    gfx.set(table.unpack(self.fnt_rgba))   -- set label color
    gfx.setfont(1, fnt, fnt_sz) -- set label fnt
    self:draw_lbl()             -- draw lbl
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Button_Settings:draw_body()
    gfx.rect(self.x,self.y,self.w,self.h, true) -- draw btn body
end
--------
function Button_Settings:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+(h-lbl_h)/2+1
    gfx.drawstr(self.lbl)
end
------------------------
function Button_Settings:draw()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = (self.def_xywh[1]* (Z_w/2)) , (self.def_xywh[3]* (Z_w/2)) -- upd x,w
  self.y, self.h = (self.def_xywh[2]* (Z_h/2)) , (self.def_xywh[4]* (Z_h/2)) -- upd y,h
  if self.fnt_sz then --fix it!--
     self.fnt_sz = max(16,self.def_xywh[5]* (Z_w+Z_h)/2)
     self.fnt_sz = min(26,self.fnt_sz* Z_h)
  end    
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    if fnt_sz <= 12 then fnt_sz = 12 end

    -- Get mouse state ---------
          -- in element --------
          SButton = 0
          MenuCall = 0
          if self:mouseIN() then 
          a=a+0.4 
          SButton = 1
          end
          -- in elm L_down -----
          if self:mouseDown() then 
          a=a-0.2 
          SButton = 1
          MenuCall = 1
          end
          -- in elm L_up(released and was previously pressed) --
          if self:mouseClick() and self.onClick then self.onClick() end

    -- Draw btn body, frame ----
    gfx.set(r,g,b,a)    -- set body color
    self:draw_body()    -- body
--    self:draw_frame3()   -- frame
    -- Draw label --------------
    gfx.set(table.unpack(self.fnt_rgba))   -- set label color
    gfx.setfont(1, fnt, fnt_sz) -- set label fnt
    self:draw_lbl()             -- draw lbl
end

--------------------------------------------------------------------------------
---   Txt Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function Txt:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+(h-lbl_h)/2
    gfx.set(1,1,1,0.4)    -- set body color
    gfx.drawstr(self.lbl)
end

function Txt2:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= 17 then fnt_sz = 17 end
    fnt_sz = fnt_sz-1

    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+(h-lbl_h)/2
    gfx.set(r,g,b,a)  -- set body,frame color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    gfx.drawstr(self.lbl)
end

function Line:draw()
   self:update_xywh() -- Update xywh(if wind changed)
   local r,g,b,a  = self.r,self.g,self.b,self.a
   self:draw_frame2()  -- draw frame
end

function Line_colored:draw()
   self:update_xywh() -- Update xywh(if wind changed)
   local r,g,b,a  = self.r,self.g,self.b,self.a
   gfx.set(r,g,b,a)   -- set frame color -- цвет рамок
   self:draw_frame3()  -- draw frame
end

function Line2:draw()
   self:update_xywh() -- Update xywh(if wind changed)
   local r,g,b,a  = self.r,self.g,self.b,self.a
   gfx.set(r,g,b,a)   -- set frame color -- цвет рамок
   self:draw_frame_filled()  -- draw frame
end

--------------------------------------------------------------------------------
---   ErrMsg Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function ErrMsg:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+(h-lbl_h)/2
    gfx.set(0.8, 0.3, 0.3, 1)   -- set label color
    gfx.drawstr(self.lbl)
end

--------------------------------------------------------------------------------
---   Slider Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function Slider_small:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.005 -- Set step
    else
    Mult_S = 0.05 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1) end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0) end
    return true
end

function Slider:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.005 -- Set step
    else
    Mult_S = 0.05 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1); Gate_on2 = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0); Gate_on2 = 1 end
    return true
end

function Slider_simple:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.005 -- Set step
    else
    Mult_S = 0.05 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1); Gate_on2 = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0); Gate_on2 = 1 end
    return true
end

function Slider_simple_r:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.01 -- Set step
    else
    Mult_S = 0.1 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1); Gate_on2 = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0); Gate_on2 = 1 end
    return true
end

function Slider_simple_g:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.01 -- Set step
    else
    Mult_S = 0.1 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1); Gate_on2 = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0); Gate_on2 = 1 end
    return true
end

function Slider_simple_g_bias:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.007 -- Set step
    else
    Mult_S = 0.07 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1); Gate_on2 = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0); Gate_on2 = 1 end
    return true
end

function Slider_simple_v:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.01 -- Set step
    else
    Mult_S = 0.1 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1); Gate_on2 = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0); Gate_on2 = 1 end
    return true
end

function Slider_complex:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.005 -- Set step
    else
    Mult_S = 0.05 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1); Gate_on2 = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0); Gate_on2 = 1 end
    return true
end

function Slider_Fine:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.0025 -- Set step
    else
    Mult_S = 0.025 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1); Gate_on2 = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0); Gate_on2 = 1 end
    return true
end

function Slider_Swing:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.005 -- Set step
    else
    Mult_S = 0.05 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step+0.00001, 1); Gate_on2 = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step+0.00001, 0); Gate_on2 = 1 end
    return true
end

function Slider_fgain:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.005 -- Set step
    else
    Mult_S = 0.05 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1); Gate_on2 = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0); Gate_on2 = 1 end
    return true
end
-------------------------------------------------------------------------------------
function H_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    if MCtrl then VAL = 0.5 end --set default value by Ctrl+LMB
    self.norm_val=VAL
end
function V_Slider:set_norm_val()
    local y, h  = self.y, self.h
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((last_y-gfx.mouse_y)/(h*K))
       else VAL = (h-(gfx.mouse_y-y))/h end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    self.norm_val=VAL
end
function T_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    if MCtrl then VAL = readrms end --set default value by Ctrl+LMB
    self.norm_val=VAL

end
function HP_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    DefaultHP = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultHP'))or 0.3312;
    if MCtrl then VAL = DefaultHP end --set default value by Ctrl+LMB
    self.norm_val=VAL

if RememberLast == 0 then 
HF_Slider = DefaultHP
end
end
function LP_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    DefaultLP = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultLP'))or 1;
    if MCtrl then VAL = DefaultLP end --set default value by Ctrl+LMB
    self.norm_val=VAL

if RememberLast == 0 then 
LF_Slider = DefaultLP
end
end
function G_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    if MCtrl then VAL = out_gain end --set default value by Ctrl+LMB
    self.norm_val=VAL
end
function S_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    DefaultSens = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultSens'))or 0.375;
    if MCtrl then VAL = DefaultSens end --set default value by Ctrl+LMB
    self.norm_val=VAL

if RememberLast == 0 then 
Sens_Slider = DefaultSens
end

end
function Rtg_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    if MCtrl then VAL = retrigms end --set default value by Ctrl+LMB
    self.norm_val=VAL
end
function Rdc_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    if MCtrl then VAL = 1 end --set default value by Ctrl+LMB
    self.norm_val=VAL
end
function O_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    DefaultOffset = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultOffset'))or 0.5;
    if MCtrl then VAL = DefaultOffset end --set default value by Ctrl+LMB
    self.norm_val=VAL

if RememberLast == 0 then 
Offs_Slider = DefaultOffset
end
end
function Sw_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    if MCtrl then VAL = swngdefamt end --set default value by Ctrl+LMB
    self.norm_val=VAL

end
function Q_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    DefaultQStrength = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultQStrength'))or 100;
    if MCtrl then VAL = DefaultQStrength*0.01 end --set default value by Ctrl+LMB
    self.norm_val=VAL

if RememberLast == 0 then 
QuantizeStrength = DefaultQStrength
end
end
function Q_Slider_Red:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    DefaultQStrength = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultQStrength'))or 0;
    if MCtrl then VAL = 0 end --set default value by Ctrl+LMB
    self.norm_val=VAL

if RememberLast == 0 then 
QuantizeStrength = DefaultQStrength
end
end
function Q_Slider_Green:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    DefaultQStrength = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultQStrength'))or 50;
    if MCtrl then VAL = 0.5 end --set default value by Ctrl+LMB
    self.norm_val=VAL

if RememberLast == 0 then 
QuantizeStrength = DefaultQStrength
end
end
function Q_Slider_Green_Bias:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    DefaultQStrength = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultQStrength'))or 50;
    if MCtrl then VAL = 0.5 end --set default value by Ctrl+LMB
    self.norm_val=VAL

if RememberLast == 0 then 
QuantizeStrength = DefaultQStrength
end
end
function Q_Slider_Violet:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    DefaultQStrength = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultQStrength'))or 30;
    if MCtrl then VAL = 0.3 end --set default value by Ctrl+LMB
    self.norm_val=VAL

if RememberLast == 0 then 
QuantizeStrength = DefaultQStrength
end
end
function X_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    DefaultXFadeTime = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultXFadeTime'))or 15;
    if MCtrl then VAL = 0.5 end --set default value by Ctrl+LMB
    self.norm_val=VAL
    
if RememberLast == 0 then 
CrossfadeTime = DefaultXFadeTime
end
end

function X_SliderOff:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    VAL = 0
    self.norm_val=VAL
end
-----------------------------------------------------------------------------
function H_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw H_Slider body
end
function V_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = h * self.norm_val
    gfx.rect(x,y+h-val, w, val, true) -- draw V_Slider body
end
function T_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw T_Slider body
end
function HP_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw HP_Slider body
end
function LP_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw LP_Slider body
end
function G_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw G_Slider body
end
function S_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw S_Slider body
end
function Rtg_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw Rtg_Slider body
end
function Rdc_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw Rdc_Slider body
end
function O_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw O_Slider body
end
function Sw_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw O_Slider body
end
function Q_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw Q_Slider body
end
function Q_Slider_Red:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw Q_Slider body
end
function Q_Slider_Green:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw Q_Slider body
end
function Q_Slider_Green_Bias:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw Q_Slider body
end
function Q_Slider_Violet:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw Q_Slider body
end
function X_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw X_Slider body
end
function X_SliderOff:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = 0
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw X_Slider body
end
--------------------------------------------------------------
function H_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw H_Slider label
end

function V_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+h-lbl_h-5;
    gfx.drawstr(self.lbl) -- draw V_Slider label
end

function T_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw T_Slider label
end
function HP_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw HP_Slider label
end
function LP_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw LP_Slider label
end
function G_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw G_Slider label
end
function S_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw S_Slider label
end
function Rtg_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw Rtg_Slider label
end
function Rdc_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw Rdc_Slider label
end
function O_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw O_Slider label
end
function Sw_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw O_Slider label
end
function Q_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw Q_Slider label
end
function Q_Slider_Red:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw Q_Slider label
end
function Q_Slider_Green:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw Q_Slider label
end
function Q_Slider_Green_Bias:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw Q_Slider label
end
function Q_Slider_Violet:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw Q_Slider label
end
function X_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw X_Slider label
end
function X_SliderOff:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.set(1,1,1,0.2)  -- set body,frame color
self:draw_frame2() -- frame
    gfx.drawstr(self.lbl) -- draw X_Slider label
end
---------------------------------------------------------------
function H_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw H_Slider Value
end

function V_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+(w-val_w)/2; gfx.y = y+5;
    gfx.drawstr(val) -- draw V_Slider Value
end

function T_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw T_Slider Value
end
function HP_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw HP_Slider Value
end
function LP_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw LP_Slider Value
end
function G_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw G_Slider Value
end
function S_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw S_Slider Value
end
function Rtg_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw Rtg_Slider Value
end
function Rdc_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw Rdc_Slider Value
end
function O_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw O_Slider Value
end
function Sw_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw O_Slider Value
end
function Q_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw Q_Slider Value
end
function Q_Slider_Red:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw Q_Slider Value
end
function Q_Slider_Green:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw Q_Slider Value
end
function Q_Slider_Green_Bias:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw Q_Slider Value
end
function Q_Slider_Violet:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw Q_Slider Value
end
function X_Slider:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw X_Slider Value
end
function X_SliderOff:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw X_Slider Value
end
----------------------------------------------------------------

function Slider_small:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize-1 then fnt_sz = MaxFontSize-1 end
fnt_sz = fnt_sz-1
    -- Get mouse state ---------
          -- in element(and get mouswheel) --
          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then 
                 if gfx.mouse_wheel == 0 then 
                    if self.onMove then self.onMove() end 
                 end 
             end  
          end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 
             self:set_norm_val()
             if self.onMove then self.onMove() end 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             MouseUpX = 1
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end    
    -- Draw sldr body, frame ---
    gfx.set(r,g,b,a)  -- set body,frame color
    self:draw_body()  -- body
    self:draw_frame() -- frame
    -- Draw label,value --------
    gfx.set(table.unpack(self.fnt_rgba))   -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    self:draw_lbl()   -- draw lbl
    self:draw_val()   -- draw value
end
---------------------------------------------------------------------------------------

function Slider:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element(and get mouswheel) --

          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then 
             if gfx.mouse_wheel == 0 then 
                if self.onMove then self.onMove() end 
             end
----------------------------------------------------------
        local time_start = reaper.time_precise() 
      if item_length2 == nil then item_length2 = 0 end  
        local timer2 = exp(item_length2/300)/8   
            if timer2 < 0.15 then timer2 = timer2/1.4 end
            if timer2 < 0.10 then timer2 = timer2/8 end
        local function Main_Timer() -- timer prevents slider lag
           if elapsed ~= 1 then
                  elapsed = reaper.time_precise() - time_start
                 if elapsed >= timer2 then   
                     runcheck = 0
                     if gfx.mouse_wheel == 0 then 
                        MW_doit_slider() --------- main function
                     end
                     return
                 else
                 runcheck = 1 
                     reaper.defer(Main_Timer)
                 end
            end
         end
             
       if runcheck ~= 1 then
           Main_Timer()
       end
 ---------------------------------------------------------               
             end  
          end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 
             self:set_norm_val()
             if self.onMove then self.onMove() end 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             MouseUpX = 1
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end    
    -- Draw sldr body, frame ---
    gfx.set(r,g,b,a)  -- set body,frame color
    self:draw_body()  -- body
    self:draw_frame() -- frame
    -- Draw label,value --------
    gfx.set(table.unpack(self.fnt_rgba))   -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    self:draw_lbl()   -- draw lbl
    self:draw_val()   -- draw value
end
---------------------------------------------------------------------------------------

function Slider_simple:draw() -- slider without waveform and markers redraw
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element(and get mouswheel) --
          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then 
                 if gfx.mouse_wheel == 0 then 
                    if self.onMove then self.onMove() end 
                 end 
             end  
          end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 
             self:set_norm_val()
             if self.onMove then self.onMove() end 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             MouseUpX = 1
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end    
    -- Draw sldr body, frame ---
    gfx.set(r,g,b,a)  -- set body,frame color
    self:draw_body()  -- body
    self:draw_frame() -- frame
    -- Draw label,value --------
    gfx.set(table.unpack(self.fnt_rgba))   -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    self:draw_lbl()   -- draw lbl
    self:draw_val()   -- draw value
end
--------------------------------------------------------------------------------

function Slider_simple_r:draw() -- slider without waveform and markers redraw
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element(and get mouswheel) --
          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then 
                 if gfx.mouse_wheel == 0 then 
                    if self.onMove then self.onMove() end 
                 end 
             end  
          end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 
             self:set_norm_val()
             if self.onMove then self.onMove() end 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             MouseUpX = 1
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end    
    -- Draw sldr body, frame ---
    gfx.set(r,g,b,a)  -- set body,frame color
    self:draw_body()  -- body
    self:draw_frame_r() -- frame
    -- Draw label,value --------
    gfx.set(table.unpack(self.fnt_rgba))   -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    self:draw_lbl()   -- draw lbl
    self:draw_val()   -- draw value
end
--------------------------------------------------------------------------------
function Slider_simple_g:draw() -- slider without waveform and markers redraw
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element(and get mouswheel) --
          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then 
                 if gfx.mouse_wheel == 0 then 
                    if self.onMove then self.onMove() end 
                 end 
             end  
          end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 
             self:set_norm_val()
             if self.onMove then self.onMove() end 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             MouseUpX = 1
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end    
    -- Draw sldr body, frame ---
    gfx.set(r,g,b,a)  -- set body,frame color
    self:draw_body()  -- body
    self:draw_frame_g() -- frame
    -- Draw label,value --------
    gfx.set(table.unpack(self.fnt_rgba))   -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    self:draw_lbl()   -- draw lbl
    self:draw_val()   -- draw value
end
--------------------------------------------------------------------------------
function Slider_simple_g_bias:draw() -- slider without waveform and markers redraw
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element(and get mouswheel) --
          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then 
                 if gfx.mouse_wheel == 0 then 
                    if self.onMove then self.onMove() end 
                 end 
             end  
          end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 
             self:set_norm_val()
             if self.onMove then self.onMove() end 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             MouseUpX = 1
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end    
    -- Draw sldr body, frame ---
    gfx.set(r,g,b,a)  -- set body,frame color
    self:draw_body()  -- body
    self:draw_frame_g() -- frame
    -- Draw label,value --------
    gfx.set(table.unpack(self.fnt_rgba))   -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    self:draw_lbl()   -- draw lbl
    self:draw_val()   -- draw value
end
--------------------------------------------------------------------------------
function Slider_simple_v:draw() -- slider without waveform and markers redraw
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element(and get mouswheel) --
          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then 
                 if gfx.mouse_wheel == 0 then 
                    if self.onMove then self.onMove() end 
                 end 
             end  
          end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 
             self:set_norm_val()
             if self.onMove then self.onMove() end 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             MouseUpX = 1
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end    
    -- Draw sldr body, frame ---
    gfx.set(r,g,b,a)  -- set body,frame color
    self:draw_body()  -- body
    self:draw_frame_v() -- frame
    -- Draw label,value --------
    gfx.set(table.unpack(self.fnt_rgba))   -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    self:draw_lbl()   -- draw lbl
    self:draw_val()   -- draw value
end
--------------------------------------------------------------------------------

function Slider_Fine:draw() -- Offset slider with fine tuning and additional line redrawing
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element(and get mouswheel) --
          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then 
             if gfx.mouse_wheel == 0 then 
                if self.onMove then self.onMove() end 
     end
----------------------------------------------------------
        local time_start = reaper.time_precise() 
      if item_length2 == nil then item_length2 = 0 end  
        local timer2 = exp(item_length2/300)/8   
            if timer2 < 0.15 then timer2 = timer2/1.4 end
            if timer2 < 0.10 then timer2 = timer2/8 end
        local function Main_Timer() -- timer prevents slider lag
           if elapsed ~= 1 then
                  elapsed = reaper.time_precise() - time_start
                 if elapsed >= timer2 then   
                     runcheck = 0
                     if gfx.mouse_wheel == 0 then 
                        MW_doit_slider_Fine()  --------- main function
                     end
                     return
                 else
                 runcheck = 1 
                     reaper.defer(Main_Timer)
                 end
            end
         end
             
       if runcheck ~= 1 then
           Main_Timer()
       end
 ---------------------------------------------------------
             end  
          end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 
             self:set_norm_val()
             if self.onMove then self.onMove() end 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             MouseUpX = 1
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end    
    -- Draw sldr body, frame ---
    gfx.set(r,g,b,a)  -- set body,frame color
    self:draw_body()  -- body
    self:draw_frame() -- frame
    -- Draw label,value --------
    gfx.set(table.unpack(self.fnt_rgba))   -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    self:draw_lbl()   -- draw lbl
    self:draw_val()   -- draw value
end
------------------------------------------------------------------------------
function Slider_Swing:draw() -- Offset slider with fine tuning and additional line redrawing
  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = (self.def_xywh[1]* Z_w) , (self.def_xywh[3]* Z_w) -- upd x,w
  self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* Z_h) -- upd y,h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element(and get mouswheel) --
          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then 
             if gfx.mouse_wheel == 0 then 
                if self.onMove then self.onMove() end 
     end
----------------------------------------------------------                  

                        MW_doit_slider_Swing()  --------- main function
  
 ---------------------------------------------------------
             end  
          end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 
             self:set_norm_val()
             if self.onMove then self.onMove() end 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             MouseUpX = 1
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end    
    -- Draw sldr body, frame ---
    gfx.set(r,g,b,a)  -- set body,frame color
    self:draw_body()  -- body
    self:draw_frame() -- frame
    -- Draw label,value --------
    gfx.set(table.unpack(self.fnt_rgba))   -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    self:draw_lbl()   -- draw lbl
    self:draw_val()   -- draw value
end
--------------------------------------------------------------------------------

function Slider_complex:draw() -- slider with full waveform and markers redraw
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element(and get mouswheel) --
          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then 
             if gfx.mouse_wheel == 0 then 
                if self.onMove then self.onMove() end 
     end
----------------------------------------------------------
        local time_start = reaper.time_precise() 
      if item_length2 == nil then item_length2 = 0 end  
        local timer2 = exp(item_length2/300)/8   
            if timer2 < 0.15 then timer2 = timer2/1.2 end
            if timer2 < 0.10 then timer2 = timer2/4 end
        local function Main_Timer() -- timer prevents slider lag
           if elapsed ~= 1 then
                  elapsed = reaper.time_precise() - time_start
                 if elapsed >= timer2 then   
                     runcheck = 0
                     if gfx.mouse_wheel == 0 then 
                          MW_doit_slider_comlpex()  --------- main function
                     end
                     return
                 else
                 runcheck = 1 
                     reaper.defer(Main_Timer)
                 end
            end
         end
             
       if runcheck ~= 1 then
           Main_Timer()
       end
 ---------------------------------------------------------
             end  
          end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 
             self:set_norm_val()
             if self.onMove then self.onMove() end 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             MouseUpX = 1
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end    
    -- Draw sldr body, frame ---
    gfx.set(r,g,b,a)  -- set body,frame color
    self:draw_body()  -- body
    self:draw_frame() -- frame
    -- Draw label,value --------
    gfx.set(table.unpack(self.fnt_rgba))   -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    self:draw_lbl()   -- draw lbl
    self:draw_val()   -- draw value
end
--------------------------------------------------------------------------------
function Slider_fgain:draw() -- filter slider without waveform processing
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element(and get mouswheel) --
          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then 
             if gfx.mouse_wheel == 0 then 
                if self.onMove then self.onMove() end 
     end
----------------------------------------------------------
        local time_start = reaper.time_precise() 
      if item_length2 == nil then item_length2 = 0 end  
        local timer2 = exp(item_length2/300)/8   
            if timer2 < 0.15 then timer2 = timer2/1.4 end
            if timer2 < 0.10 then timer2 = timer2/8 end
        local function Main_Timer() -- timer prevents slider lag
           if elapsed ~= 1 then
                  elapsed = reaper.time_precise() - time_start
                 if elapsed >= timer2 then   
                     runcheck = 0
                     if gfx.mouse_wheel == 0 then 
                           MW_doit_slider_fgain()   --------- main function
                     end
                     return
                 else
                 runcheck = 1 
                     reaper.defer(Main_Timer)
                 end
            end
         end
             
       if runcheck ~= 1 then
           Main_Timer()
       end
 ---------------------------------------------------------
             end  
          end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 
             self:set_norm_val()
             if self.onMove then self.onMove() end 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             MouseUpX = 1
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end    
    -- Draw sldr body, frame ---
    gfx.set(r,g,b,a)  -- set body,frame color
    self:draw_body()  -- body
    self:draw_frame() -- frame
    -- Draw label,value --------
    gfx.set(table.unpack(self.fnt_rgba))   -- set lbl,val color
    gfx.setfont(1, fnt, fnt_sz) -- set lbl,val fnt
    self:draw_lbl()   -- draw lbl
    self:draw_val()   -- draw value
end

--------------------------------------------------------------------------------
---   Rng_Slider Class Methods   -----------------------------------------------
--------------------------------------------------------------------------------
function Rng_Slider:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.005 -- Set step
    else
    Mult_S = 0.05 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1);    Gate_on2 = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0);    Gate_on2 = 1 end
    if self.norm_val >= self.norm_val2 then self.norm_val = self.norm_val2 end
    return true
end

function Rng_Slider:pointIN_Ls(p_x, p_y)
  local x, w, sb_w = self.rng_x, self.rng_w, self.sb_w
  local val = w * self.norm_val
  x = (x+val-sb_w)+4 -- left sbtn x; x-10 extend mouse zone to the left(more comfortable) 
  return p_x >= x-5 and p_x <= x + sb_w and p_y >= self.y and p_y <= self.y + self.h
end
--------
function Rng_Slider:pointIN_Rs(p_x, p_y)
  local x, w, sb_w = self.rng_x, self.rng_w, self.sb_w
  local val = w * self.norm_val2
  x = (x+val)-4 -- right sbtn x; x+10 extend mouse zone to the right(more comfortable)
  return p_x >= x and p_x <= x+5 + sb_w and p_y >= self.y and p_y <= self.y + self.h
end
--------
function Rng_Slider:pointIN_rng(p_x, p_y)
  local x  = self.rng_x + self.rng_w * self.norm_val  -- start rng
  local x2 = self.rng_x + self.rng_w * self.norm_val2 -- end rng
  return p_x >= x+5 and p_x <= x2-5 and p_y >= self.y and p_y <= self.y + self.h
end
------------------------
function Rng_Slider:mouseIN_Ls()
  return gfx.mouse_cap&1==0 and self:pointIN_Ls(gfx.mouse_x,gfx.mouse_y)
end
--------
function Rng_Slider:mouseIN_Rs()
  return gfx.mouse_cap&1==0 and self:pointIN_Rs(gfx.mouse_x,gfx.mouse_y)
end
--------
function Rng_Slider:mouseIN_rng()
  return gfx.mouse_cap&1==0 and self:pointIN_rng(gfx.mouse_x,gfx.mouse_y)
end
------------------------
function Rng_Slider:mouseDown_Ls()
  return gfx.mouse_cap&1==1 and last_mouse_cap&1==0 and self:pointIN_Ls(mouse_ox,mouse_oy)
end
--------
function Rng_Slider:mouseDown_Rs()
  return gfx.mouse_cap&1==1 and last_mouse_cap&1==0 and self:pointIN_Rs(mouse_ox,mouse_oy)
end
--------
function Rng_Slider:mouseDown_rng()
  return gfx.mouse_cap&1==1 and last_mouse_cap&1==0 and self:pointIN_rng(mouse_ox,mouse_oy)
end
--------------------------------
function Rng_Slider:set_norm_val()
    local x, w = self.rng_x, self.rng_w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    -- valid val --
    if VAL<0 then VAL=0 elseif VAL>self.norm_val2 then VAL=self.norm_val2 end
    if MCtrl then VAL = 0.231 end --set default value by Ctrl+LMB
    self.norm_val=VAL
end
--------
function Rng_Slider:set_norm_val2()
    local x, w = self.rng_x, self.rng_w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val2 + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    -- valid val2 --
    if VAL<self.norm_val then VAL=self.norm_val elseif VAL>1 then VAL=1 end
    if MCtrl then VAL = 1 end --set default value by Ctrl+LMB
    self.norm_val2=VAL
end
--------
function Rng_Slider:set_norm_val_both()
    local x, w = self.x, self.w
    local diff = self.norm_val2 - self.norm_val -- values difference
    local K = 1           -- K = coefficient
    if Shift then K=10 end -- when Ctrl pressed
    local VAL  = self.norm_val  + (gfx.mouse_x-last_x)/(w*K)
    -- valid values --
    if VAL<0 then VAL = 0 elseif VAL>1-diff then VAL = 1-diff end
    self.norm_val  = VAL
    self.norm_val2 = VAL + diff
end
--------------------------------
function Rng_Slider:draw_body()
    local x,y,w,h  = self.rng_x+1,self.y+1,self.rng_w-2,self.h-2
    local sb_w = self.sb_w 
    local val  = w * self.norm_val
    local val2 = w * self.norm_val2
    gfx.rect(x+val-sb_w, y, val2-val+sb_w*2, h, true) -- draw body
end
--------
function Rng_Slider:draw_sbtns()
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local x,y,w,h  = self.rng_x+1,self.y+1,self.rng_w-1,self.h-2
    local sb_w = self.sb_w
    local val  = w * self.norm_val
    local val2 = w * self.norm_val2-1
    gfx.set(1,1,1,0.15)  -- sbtns body color
    gfx.rect(x+val-sb_w, y, sb_w+1, h, true)   -- sbtn1 body
    gfx.rect(x+val2-1,     y, sb_w+1, h, true) -- sbtn2 body
    
end
--------------------------------
function Rng_Slider:draw_val() -- variant 2
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val  = string.format("%.2f", self.norm_val)
    local val2 = string.format("%.2f", self.norm_val2)
    local val_w,  val_h  = gfx.measurestr(val)
    local val2_w, val2_h = gfx.measurestr(val2)
      local T = 0 -- set T = 0 or T = h (var1, var2 text position) 
      gfx.x = x+5
      gfx.y = y+(h-val_h)/2 + T
      gfx.drawstr(val)  -- draw value 1
      gfx.x = x+w-val2_w-5
      gfx.y = y+(h-val2_h)/2 + T
      gfx.drawstr(val2) -- draw value 2
end
--------
function Rng_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
      local T = 0 -- set T = 0 or T = h (var1, var2 text position)
      gfx.x = x+(w-lbl_w)/2
      gfx.y = y+(h-lbl_h)/2 + T
      gfx.drawstr(self.lbl)
end
--------------------------------
function Rng_Slider:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- set additional coordinates --
 --   self.sb_w  = h-5
 --   self.sb_w  = floor(self.w/17) -- sidebuttons width(change it if need)
    self.sb_w  = floor(self.w/10) -- sidebuttons width(change it if need)
    self.rng_x = self.x + self.sb_w    -- range streak min x
    self.rng_w = self.w - self.sb_w*2  -- range streak max w
    -- Get mouse state -------------
          -- Reset Ls,Rs states --
          if gfx.mouse_cap&1==0 then self.Ls_state, self.Rs_state, self.rng_state = false,false,false end
          -- in element --
          if self:mouseIN_Ls() then g=g+0.15; b=b-0.1 end
          if  self:mouseIN_Rs() then r=r+0.3 end
          if  self:mouseIN_rng() then a=a+0.2 end
          if  self:mouseIN() then 
             if self:set_norm_val_m_wheel() then 
                 if gfx.mouse_wheel == 0 then 
                    if self.onMove then self.onMove() end 
                 end 
             end  
          end
          -- in elm L_down --
          if self:mouseDown_Ls()  then self.Ls_state = true end
          if self:mouseDown_Rs()  then self.Rs_state = true end
          if self:mouseDown_rng() then self.rng_state = true end

          if MCtrl and self:mouseDown()  then       -- Ctrl+Click on empty rng area set defaults
          self.norm_val = 0.234   
          self.norm_val2 = 1   
          end
          --------------
          if self.Ls_state  == true then g=g+0.2; b=b-0.1; self:set_norm_val()      end
          if self.Rs_state  == true then r=r+0.35; self:set_norm_val2()     end
          if self.rng_state == true then a=a+0.3; self:set_norm_val_both() end
          if (self.Ls_state or self.Rs_state or self.rng_state) and self.onMove then self.onMove() end
          -- in elm L_up(released and was previously pressed) --
           if self:mouseClick() and self.onClick then self.onClick() end
          if self:mouseUp() and self.onUp then self.onUp()
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end
    -- Draw sldr body, frame, sidebuttons --
    gfx.set(r,g,b,a)  -- set color
    self:draw_body()  -- body
    self:draw_frame_rng() -- frame
    self:draw_sbtns() -- draw L,R sidebuttons
    -- Draw label,values --
    gfx.set(table.unpack(self.fnt_rgba)) -- set label color
    gfx.setfont(1, fnt, fnt_sz)          -- set lbl,val fnt
    self:draw_lbl() -- draw lbl
    self:draw_val() -- draw value
end

--------------------------------------------------------------------------------
---   Loop_Slider Class Methods   -----------------------------------------------
--------------------------------------------------------------------------------

function Loop_Slider:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.005 -- Set step
    else
    Mult_S = 0.05 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val2 = min(self.norm_val2+Step, 1) end
    if gfx.mouse_wheel < 0 then self.norm_val2 = max(self.norm_val2-Step, 0) end
    if self.norm_val2 <= self.norm_val then self.norm_val2 = self.norm_val+0.05 end
    return true
end

function Loop_Slider:pointIN_Ls(p_x, p_y)
  local x, w, sb_w = self.rng_x, self.rng_w, self.sb_w
  local val = w * self.norm_val
  x = (x+val-sb_w)+4 -- left sbtn x; x-10 extend mouse zone to the left(more comfortable) 
  return p_x >= x-10 and p_x <= x + sb_w+10 and p_y >= self.y and p_y <= self.y*1.4 + self.h
end
--------
function Loop_Slider:pointIN_Rs(p_x, p_y)
  local x, w, sb_w = self.rng_x, self.rng_w, self.sb_w
  local val = w * self.norm_val2
  x = (x+val)-4 -- right sbtn x; x+10 extend mouse zone to the right(more comfortable)
  return p_x >= x-10 and p_x <= x + sb_w+10 and p_y >= self.y and p_y <= self.y*1.4 + self.h
end
--------
function Loop_Slider:pointIN_rng(p_x, p_y)
  local rng_shift = 5
  local x  = (self.rng_x + self.rng_w * self.norm_val) + rng_shift -- start rng
  local x2 = (self.rng_x + self.rng_w * self.norm_val2) - rng_shift -- end rng
  return p_x >= x+10 and p_x <= x2-10 and p_y >= self.y and p_y <= self.y*1.4 + self.h
end
------------------------
function Loop_Slider:mouseIN_Ls()
  return gfx.mouse_cap&1==0 and self:pointIN_Ls(gfx.mouse_x,gfx.mouse_y)
end
--------
function Loop_Slider:mouseIN_Rs()
  return gfx.mouse_cap&1==0 and self:pointIN_Rs(gfx.mouse_x,gfx.mouse_y)
end
--------
function Loop_Slider:mouseIN_rng()
  return gfx.mouse_cap&1==0 and self:pointIN_rng(gfx.mouse_x,gfx.mouse_y)
end
------------------------
function Loop_Slider:mouseDown_Ls()
  return gfx.mouse_cap&1==1 and last_mouse_cap&1==0 and self:pointIN_Ls(mouse_ox,mouse_oy)
end
--------
function Loop_Slider:mouseDown_Rs()
  return gfx.mouse_cap&1==1 and last_mouse_cap&1==0 and self:pointIN_Rs(mouse_ox,mouse_oy)
end
--------
function Loop_Slider:mouseDown_rng()
  return gfx.mouse_cap&1==1 and last_mouse_cap&1==0 and self:pointIN_rng(mouse_ox,mouse_oy)
end
--------------------------------
function Loop_Slider:set_norm_val()
    local x, w = self.rng_x, self.rng_w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    -- valid val --
    if VAL<=0 then VAL=0 elseif VAL>=self.norm_val2-0.05 then VAL=self.norm_val2-0.05 end
    if MCtrl then VAL = 0 end --set default value by Ctrl+LMB
    self.norm_val=VAL
end

--------
function Loop_Slider:set_norm_val2()
    local x, w = self.rng_x, self.rng_w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val2 + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    -- valid val2 --
    if VAL<=self.norm_val+0.05 then VAL=self.norm_val+0.05 elseif VAL>=1 then VAL=1 end
    if MCtrl then VAL = 1 end --set default value by Ctrl+LMB
    self.norm_val2=VAL
end
--------
function Loop_Slider:set_norm_val_both()
    local x, w = self.x, self.w
    local diff = self.norm_val2 - self.norm_val -- values difference
    local K = 1           -- K = coefficient
    if Shift then K=10 end -- when Ctrl pressed
    local VAL  = self.norm_val  + (gfx.mouse_x-last_x)/(w*K)
    -- valid values --
    if VAL<=0 then VAL = 0 elseif VAL>=1-diff then VAL = 1-diff end

    self.norm_val  = VAL
    self.norm_val2 = VAL + diff
end
--------------------------------
function Loop_Slider:draw_body()
    local x,y,w,h  = self.rng_x,self.y,self.rng_w,self.h*24
    local sb_w = self.sb_w
    local val  = w * self.norm_val
    local val2 = w * self.norm_val2
    gfx.rect(x+val-sb_w, y, val2-val+sb_w*2, h, true) -- draw body
end
--------
function Loop_Slider:draw_sbtns()
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local x,y,w,h  = self.rng_x,self.y,self.rng_w,self.h
    local sb_w = self.sb_w
    local val  = w * self.norm_val
    local val2 = w * self.norm_val2+1
    gfx.set(0,0.7,0,1)  -- sbtns body color
    gfx.triangle(x+val-sb_w, y, x+val-sb_w, y*1.5, x+val-sb_w+15, y)
    gfx.triangle(x+val2+sb_w-1, y, x+val2+sb_w-1, y*1.5, x+val2+sb_w-1-15, y)  
end
--------------------------------
function Loop_Slider:draw_val() -- variant 2
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val  = string.format("%.2f", self.norm_val)
    local val2 = string.format("%.2f", self.norm_val2)
    local val_w,  val_h  = gfx.measurestr(val)
    local val2_w, val2_h = gfx.measurestr(val2)
      gfx.x = x+5
      gfx.y = y+(h-val_h)/2
      gfx.drawstr(val)  -- draw value 1
      gfx.x = x+w-val2_w-5
      gfx.y = y+(h-val2_h)/2
      gfx.drawstr(val2) -- draw value 2
end
--------
function Loop_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
      gfx.x = x+(w-lbl_w)/2
      gfx.y = (y+(h-lbl_h)/2)*1.25
      gfx.drawstr(self.lbl)
end
--------------------------------
function Loop_Slider:draw()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = (self.def_xywh[1]* Z_w) , (self.def_xywh[3]* Z_w) -- upd x,w
  self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* (Z_h/32)) -- upd y,h
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 10 then fnt_sz = 10 end
    if fnt_sz >= 17 then fnt_sz = 17 end
    -- set additional coordinates --
    self.sb_w  = h
--    self.sb_w  = floor(self.w/120) -- sidebuttons width(change it if need)
    self.rng_x = self.x + self.sb_w    -- range streak min x
    self.rng_w = self.w - self.sb_w*2  -- range streak max w
    -- Get mouse state -------------
          -- Reset Ls,Rs states --
          if gfx.mouse_cap&1==0 then self.Ls_state, self.Rs_state, self.rng_state = false,false,false end
          -- in element --
          if self:mouseIN_Ls() then g=g+0.15; b=b-0.1 end
          if  self:mouseIN_Rs() then r=r+0.3 end
          if  self:mouseIN_rng() then a=a+0.2 end
    self.h = (self.def_xywh[4]* (Z_h/1.2)) -- upd y,h -- mw caption area height correction
    local h  = self.h
          if  self:mouseIN() then 
             if self:set_norm_val_m_wheel() then 
                 if gfx.mouse_wheel == 0 then 
                    if self.onMove then self.onMove() end 
                 end 
             end  
          end
          if MCtrl and self:mouseDown()  then       -- Ctrl+Click on empty loop area set defaults
          self.norm_val = 0   
          self.norm_val2 = 1   
          end
    self.h = (self.def_xywh[4]* (Z_h/32)) -- upd y,h -- revert height
    local h  = self.h
          -- in elm L_down --
          if self:mouseDown_Ls()  then self.Ls_state = true end
          if self:mouseDown_Rs()  then self.Rs_state = true end
          if self:mouseDown_rng() then self.rng_state = true end
          --------------
          if self.Ls_state  == true then g=g+0.2; b=b-0.1; self:set_norm_val()      end
          if self.Rs_state  == true then r=r+0.35; self:set_norm_val2()     end
          if self.rng_state == true then a=a+0.3; self:set_norm_val_both() end
          if (self.Ls_state or self.Rs_state or self.rng_state) and self.onMove then self.onMove() end
          -- in elm L_up(released and was previously pressed) --
           if self:mouseClick() and self.onClick then self.onClick() end
          if self:mouseUp() and self.onUp then self.onUp()
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end

    -- Draw sldr body, frame, sidebuttons --
    gfx.set(r,g,b,a)  -- set color
    self:draw_body()  -- body
    self:draw_frame_loop() -- frame
    self:draw_sbtns() -- draw L,R sidebuttons
    -- Draw label,values --
    gfx.set(table.unpack(self.fnt_rgba)) -- set label color
    gfx.setfont(1, fnt, fnt_sz)          -- set lbl,val fnt
    gfx.set(1,1,1,0.5)  -- set color
    self:draw_lbl() -- draw lbl
    self:draw_val() -- draw value
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   CheckBox Class Methods   -------------------------------------------------
--------------------------------------------------------------------------------
function CheckBox:set_norm_val_m_wheel()
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = self.norm_val-1 end
    if gfx.mouse_wheel < 0 then self.norm_val = self.norm_val+1 end
    -- note! check = self.norm_val, checkbox table = self.norm_val2 --
    if self.norm_val> #self.norm_val2 then self.norm_val=1
    elseif self.norm_val<1 then self.norm_val= #self.norm_val2
    end
    return true
end
--------
function CheckBox:set_norm_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val      -- current value,check
    local menu_tb = self.norm_val2 -- checkbox table
    local menu_str = ""
       for i=1, #menu_tb,1 do
         if i~=val then menu_str = menu_str..menu_tb[i].."|"
                   else menu_str = menu_str.."!"..menu_tb[i].."|" -- add check
         end
       end
    gfx.x = self.x; gfx.y = self.y + self.h
    local new_val = gfx.showmenu(menu_str)        -- show checkbox menu
    if new_val>0 then self.norm_val = new_val end -- change check(!)
end
--------
function CheckBox:draw_body()
    gfx.rect(self.x+1,self.y+1,self.w-2,self.h-2, true) -- draw checkbox body
end
--------    gfx.rect(x+1,y+1, val-2, h-2, true) 
function CheckBox:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x-lbl_w-5; gfx.y = y+(h-lbl_h)/2
    gfx.drawstr(self.lbl) -- draw checkbox label
end
--------
function CheckBox:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val2[self.norm_val]
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+3; gfx.y = y+(h-val_h)/2
    gfx.drawstr(val) -- draw checkbox val
end
------------------------
function CheckBox:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element --------
          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then -- use if need
                if self.onMove then self.onMove() end   
                      MW_doit_checkbox()

            end  
          end          
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 end
          -- in elm L_up(released and was previously pressed) --
          if self:mouseClick() then self:set_norm_val()
             if self:mouseClick() and self.onClick then self.onClick() end
          end
    -- Draw ch_box body, frame -
    gfx.set(r,g,b,a)    -- set body color
    self:draw_body()    -- body
    self:draw_frame()   -- frame
    -- Draw label --------------
    gfx.set(table.unpack(self.fnt_rgba))   -- set label,val color
    gfx.setfont(1, fnt, fnt_sz) -- set label,val fnt
    self:draw_lbl()             -- draw lbl
    self:draw_val()             -- draw val
end
--------------------------------------------------------------------------------
function CheckBox_simple:set_norm_val_m_wheel()
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = self.norm_val-1;     Gate_on2 = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = self.norm_val+1;     Gate_on2 = 1 end
    -- note! check = self.norm_val, checkbox table = self.norm_val2 --
    if self.norm_val> #self.norm_val2 then self.norm_val=1
    elseif self.norm_val<1 then self.norm_val= #self.norm_val2
    end
    return true
end
--------
function CheckBox_simple:set_norm_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val      -- current value,check
    local menu_tb = self.norm_val2 -- checkbox table
    local menu_str = ""
       for i=1, #menu_tb,1 do
         if i~=val then menu_str = menu_str..menu_tb[i].."|"
                   else menu_str = menu_str.."!"..menu_tb[i].."|" -- add check
         end
       end
    gfx.x = self.x; gfx.y = self.y + self.h
    local new_val = gfx.showmenu(menu_str)        -- show checkbox menu
    if new_val>0 then self.norm_val = new_val end -- change check(!)
end
--------
function CheckBox_simple:draw_body()
    gfx.rect(self.x+1,self.y+1,self.w-2,self.h-2, true) -- draw checkbox body
end
--------
function CheckBox_simple:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x-lbl_w-5; gfx.y = y+(h-lbl_h)/2
    gfx.drawstr(self.lbl) -- draw checkbox label
end
--------
function CheckBox_simple:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val2[self.norm_val]
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+3; gfx.y = y+(h-val_h)/2
    gfx.drawstr(val) -- draw checkbox val
end
------------------------
function CheckBox_simple:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element --------
          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then -- use if need
                if self.onMove then self.onMove() end   
            end  
          end          
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 end
          -- in elm L_up(released and was previously pressed) --
          if self:mouseClick() then self:set_norm_val()
             if self:mouseClick() and self.onClick then self.onClick() end
          end
    -- Draw ch_box body, frame -
    gfx.set(r,g,b,a)    -- set body color
    self:draw_body()    -- body
    self:draw_frame_v()   -- frame
    -- Draw label --------------
    gfx.set(table.unpack(self.fnt_rgba))   -- set label,val color
    gfx.setfont(1, fnt, fnt_sz) -- set label,val fnt
    self:draw_lbl()             -- draw lbl
    self:draw_val()             -- draw val
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function CheckBox_Red:set_norm_val_m_wheel()
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = self.norm_val-1;     Gate_on2 = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = self.norm_val+1;     Gate_on2 = 1 end
    -- note! check = self.norm_val, checkbox table = self.norm_val2 --
    if self.norm_val> #self.norm_val2 then self.norm_val=1
    elseif self.norm_val<1 then self.norm_val= #self.norm_val2
    end
    return true
end
--------
function CheckBox_Red:set_norm_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val      -- current value,check
    local menu_tb = self.norm_val2 -- checkbox table
    local menu_str = ""
       for i=1, #menu_tb,1 do
         if i~=val then menu_str = menu_str..menu_tb[i].."|"
                   else menu_str = menu_str.."!"..menu_tb[i].."|" -- add check
         end
       end
    gfx.x = self.x; gfx.y = self.y + self.h
    local new_val = gfx.showmenu(menu_str)        -- show checkbox menu
    if new_val>0 then self.norm_val = new_val end -- change check(!)
end
--------
function CheckBox_Red:draw_body()
    gfx.rect(self.x+1,self.y+1,self.w-2,self.h-2, true) -- draw checkbox body
end
--------
function CheckBox_Red:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x-lbl_w-5; gfx.y = y+(h-lbl_h)/2
    gfx.drawstr(self.lbl) -- draw checkbox label
end
--------
function CheckBox_Red:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val2[self.norm_val]
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+3; gfx.y = y+(h-val_h)/2
    gfx.drawstr(val) -- draw checkbox val
end
------------------------
function CheckBox_Red:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element --------
          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then -- use if need
                if self.onMove then self.onMove() end   
            end  
          end          
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 end
          -- in elm L_up(released and was previously pressed) --
          if self:mouseClick() then self:set_norm_val()
             if self:mouseClick() and self.onClick then self.onClick() end
          end
    -- Draw ch_box body, frame -
    gfx.set(r,g,b,a)    -- set body color
    self:draw_body()    -- body
    self:draw_frame_r()   -- frame
    -- Draw label --------------
    gfx.set(table.unpack(self.fnt_rgba))   -- set label,val color
    gfx.setfont(1, fnt, fnt_sz) -- set label,val fnt
    self:draw_lbl()             -- draw lbl
    self:draw_val()             -- draw val
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function CheckBox_Green:set_norm_val_m_wheel()
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = self.norm_val-1;     Gate_on2 = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = self.norm_val+1;     Gate_on2 = 1 end
    -- note! check = self.norm_val, checkbox table = self.norm_val2 --
    if self.norm_val> #self.norm_val2 then self.norm_val=1
    elseif self.norm_val<1 then self.norm_val= #self.norm_val2
    end
    return true
end
--------
function CheckBox_Green:set_norm_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val      -- current value,check
    local menu_tb = self.norm_val2 -- checkbox table
    local menu_str = ""
       for i=1, #menu_tb,1 do
         if i~=val then menu_str = menu_str..menu_tb[i].."|"
                   else menu_str = menu_str.."!"..menu_tb[i].."|" -- add check
         end
       end
    gfx.x = self.x; gfx.y = self.y + self.h
    local new_val = gfx.showmenu(menu_str)        -- show checkbox menu
    if new_val>0 then self.norm_val = new_val end -- change check(!)
end
--------
function CheckBox_Green:draw_body()
    gfx.rect(self.x+1,self.y+1,self.w-2,self.h-2, true) -- draw checkbox body
end
--------
function CheckBox_Green:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x-lbl_w-5; gfx.y = y+(h-lbl_h)/2
    gfx.drawstr(self.lbl) -- draw checkbox label
end
--------
function CheckBox_Green:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val2[self.norm_val]
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+3; gfx.y = y+(h-val_h)/2
    gfx.drawstr(val) -- draw checkbox val
end
------------------------
function CheckBox_Green:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element --------
          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then -- use if need
                if self.onMove then self.onMove() end   
            end  
          end          
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 end
          -- in elm L_up(released and was previously pressed) --
          if self:mouseClick() then self:set_norm_val()
             if self:mouseClick() and self.onClick then self.onClick() end
          end
    -- Draw ch_box body, frame -
    gfx.set(r,g,b,a)    -- set body color
    self:draw_body()    -- body
    self:draw_frame_g()   -- frame
    -- Draw label --------------
    gfx.set(table.unpack(self.fnt_rgba))   -- set label,val color
    gfx.setfont(1, fnt, fnt_sz) -- set label,val fnt
    self:draw_lbl()             -- draw lbl
    self:draw_val()             -- draw val
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function CheckBox_Show:set_norm_val_m_wheel()
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = self.norm_val-1 end
    if gfx.mouse_wheel < 0 then self.norm_val = self.norm_val+1 end
    -- note! check = self.norm_val, checkbox table = self.norm_val2 --
    if self.norm_val> #self.norm_val2 then self.norm_val=1
    elseif self.norm_val<1 then self.norm_val= #self.norm_val2
    end
    return true
end
--------
function CheckBox_Show:set_norm_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val      -- current value,check
    local menu_tb = self.norm_val2 -- checkbox table
    local menu_str = ""
       for i=1, #menu_tb,1 do
         if i~=val then menu_str = menu_str..menu_tb[i].."|"
                   else menu_str = menu_str.."!"..menu_tb[i].."|" -- add check
         end
       end
    gfx.x = self.x; gfx.y = self.y + self.h
    local new_val = gfx.showmenu(menu_str)        -- show checkbox menu
    if new_val>0 then self.norm_val = new_val end -- change check(!)
end
--------
function CheckBox_Show:draw_body()
    gfx.rect(self.x+1,self.y+1,self.w-2,self.h-2, true) -- draw checkbox body
end
--------
function CheckBox_Show:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x-lbl_w-5; gfx.y = y+(h-lbl_h)/2
    gfx.drawstr(self.lbl) -- draw checkbox label
end
--------
function CheckBox_Show:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val2[self.norm_val]
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+3; gfx.y = y+(h-val_h)/2
    gfx.drawstr(val) -- draw checkbox val
end
------------------------
function CheckBox_Show:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Get mouse state ---------
          -- in element --------
          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then -- use if need
                if self.onMove then self.onMove() end   
                      MW_doit_checkbox_show()
                      DrawGridGuides()
            end  
          end          
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 end
          -- in elm L_up(released and was previously pressed) --
          if self:mouseClick() then self:set_norm_val()
             if self:mouseClick() and self.onClick then self.onClick() end
          end
    -- Draw ch_box body, frame -
    gfx.set(r,g,b,a)    -- set body color
    self:draw_body()    -- body
    self:draw_frame()   -- frame
    -- Draw label --------------
    gfx.set(table.unpack(self.fnt_rgba))   -- set label,val color
    gfx.setfont(1, fnt, fnt_sz) -- set label,val fnt
    self:draw_lbl()             -- draw lbl
    self:draw_val()             -- draw val
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Frame Class Methods  -----------------------------------------------------
--------------------------------------------------------------------------------
function Frame:draw()
   self:update_xywh() -- Update xywh(if wind changed)
   local r,g,b,a  = self.r,self.g,self.b,self.a
   gfx.set(r,g,b,a)   -- set frame color -- цвет рамок
   self:draw_frame4()  -- draw frame
end

--------------------------------------------------------------------------------
---   Frame Class Methods  -----------------------------------------------------
--------------------------------------------------------------------------------
function Colored_Rect:draw()
   self:update_xywh() -- Update xywh(if wind changed)
   local r,g,b,a  = self.r,self.g,self.b,self.a
   gfx.set(r, g, b, a)   -- set frame color -- цвет рамок
   self:draw_frame_filled()  -- draw frame
end

function Colored_Rect_top:draw()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = (self.def_xywh[1]* Z_w) , (self.def_xywh[3]* Z_w) -- upd x,w
  self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* Z_h) -- upd y,h
    local x,y,w,h  = self.x,self.y,self.w,self.h
   local r,g,b,a  = self.r,self.g,self.b,self.a
   gfx.set(r, g, b, a)   -- set frame color -- цвет рамок
   self:draw_frame_filled()  -- draw frame
end

--------------------------------------------------------------------------------
---   Frame_filled Class Methods  -----------------------------------------------------
--------------------------------------------------------------------------------
function Frame_filled:draw()
   self:update_xywh() -- Update xywh(if wind changed)
   local r,g,b,a  = self.r,self.g,self.b,self.a
   gfx.set(r,g,b,a)   -- set frame color -- цвет рамок
   self:draw_frame_filled()  -- draw frame
end

----------------------------------------------------------------------------------------------------
--   Some Default Values   -------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function Init_Srate()

local init_item = r.GetSelectedMediaItem(0,0)

 if init_item  then
       local init_take = r.GetActiveTake(init_item)
   if init_take == nil then return end
       local item = r.GetMediaItemTake_Item(init_take) -- Get parent item
   if item == nil then return end

   -- Get media source of media item take
   local take_pcm_source = r.GetMediaItemTake_Source(init_take)
   if take_pcm_source == nil then 
      local srate = 44100
   else
      local srate = r.GetMediaSourceSampleRate(take_pcm_source)
   end
end

   if srate then
      if srate < 44100 then srate = 44100 end
      if srate > 48000 then srate = 48000 end
    else
      srate = 44100
   end
end

Init_Srate() -- Project Samplerate


if HiPrecision_On == 1 then
   bsdiv = 2; bsdiv2 = 4
    else
   bsdiv = 16; bsdiv2 = 16
end
if NoItems == 0 and WaveCheck == 1 then mlt2 = 1 else mlt2 = 4 end
local block_size = 1024*bsdiv -- размер блока(для фильтра и тп) , don't change it!
local time_limit = 5*60*mlt2    -- limit maximum time, change, if need.
----------------------------------------------------------------------------------------------------
---  Create main objects(Wave,Gate) ----------------------------------------------------------------
----------------------------------------------------------------------------------------------------
local Wave = Element:new(10,45,1024,335)
local Gate_Gl  = {}

corrX = 0
corrY = 10
corrY2 = 3 -- Random_Setup menu correction
  
---------------------------------------------------------------
---  Create Frames   ------------------------------------------
---------------------------------------------------------------
------local tables to reduce locals (avoid 200 locals limits)-------
local elm_table = {Fltr_Frame, Gate_Frame, Mode_Frame, Mode_Frame_filled, Gate_Frame_filled, Random_Setup_Frame_filled, Random_Setup_Frame, Grid1_Led, Grid2_Led, Grid4_Led, Grid8_Led, Grid16_Led, Grid32_Led, Grid64_Led, GridT_Led, Swing_Led, Offbeat_Frame_filled, BiasThr_Frame_filled}

elm_table[1] = Frame:new(10, 375+corrY,180,100) --Fltr_Frame
elm_table[2] = Frame:new(200,375+corrY,180,100) --Gate_Frame
elm_table[3] = Frame:new(390,375+corrY,645,100) --Mode_Frame
elm_table[4] = Frame_filled:new(673,409+corrY,91,40,  0.18,0.18,0.18,0.7 ) --Mode_Frame_filled
elm_table[5] = Frame_filled:new(210,380+corrY,160,89,  0.18,0.18,0.18,0.7 ) --Gate_Frame_filled

elm_table[6] = Frame_filled:new(670,373+corrY2,147,112,  0.15,0.15,0.15,1 ) --Random_Setup_Frame_filled
elm_table[7] = Frame:new(670,373+corrY2,147,112,  0.15,0.15,0.15,1 ) --Random_Setup_Frame

elm_table[8] = Colored_Rect_top:new(50,24,40,2,  0.0,0.7,0.0,1 ) -- Grid1_Led
elm_table[9] = Colored_Rect_top:new(92,24,40,2,  0.0,0.7,0.0,1 ) -- Grid2_Led
elm_table[10] = Colored_Rect_top:new(134,24,40,2,  0.0,0.7,0.0,1 ) -- Grid4_Led
elm_table[11] = Colored_Rect_top:new(176,24,40,2,  0.0,0.7,0.0,1 ) -- Grid8_Led
elm_table[12] = Colored_Rect_top:new(218,24,40,2,  0.0,0.7,0.0,1 ) -- Grid16_Led
elm_table[13] = Colored_Rect_top:new(260,24,40,2,  0.0,0.7,0.0,1 ) -- Grid32_Led
elm_table[14] = Colored_Rect_top:new(302,24,40,2,  0.0,0.7,0.0,1 ) -- Grid64_Led
elm_table[15] = Colored_Rect_top:new(344,24,40,2,  0.0,0.7,0.0,1 ) -- GridT_Led
elm_table[16] = Colored_Rect_top:new(391,24,50,2,  0.0,0.7,0.0,1 ) -- Swing_Led

elm_table[17] = Frame_filled:new(767,430+corrY,71,19,  0.18,0.18,0.18,0.7 ) --Offbeat_Frame_filled
elm_table[18] = Frame_filled:new(498,450+corrY,171,19,  0.18,0.18,0.18,0.7 ) --BiasThr_Frame_filled

local leds_table = {Frame_byGrid, Frame_byGrid2, Light_Loop_on, Light_Loop_off, Light_Sync_on, Light_Sync_off, Rand_Mode_Color1, Rand_Mode_Color2, Rand_Mode_Color3, Rand_Mode_Color4, Rand_Mode_Color5, Rand_Mode_Color6, Rand_Mode_Color7, Rand_Button_Color1, Rand_Button_Color2, Rand_Button_Color3, Rand_Button_Color4, Rand_Button_Color5, Rand_Button_Color6, Rand_Button_Color7, InverseEnv_On, InverseEnv_Off}

leds_table[1] = Colored_Rect:new(492,410+corrY,2,18,  0.1,0.7,0.6,1 ) -- Frame_byGrid (Blue indicator)
leds_table[2] = Colored_Rect:new(492,410+corrY,2,18,  0.7,0.7,0.0,1 ) -- Frame_byGrid2 (Yellow indicator)

leds_table[3] = Colored_Rect_top:new(981,5,2,20,  0.0,0.7,0.0,1 ) -- Light_Loop_on
leds_table[4] = Colored_Rect_top:new(981,5,2,20,  0.5,0.5,0.5,0.5 ) -- Light_Loop_off

leds_table[5] = Colored_Rect_top:new(921,5,2,20,  0.0,0.7,0.0,1 ) -- Light_Sync_on
leds_table[6] = Colored_Rect_top:new(921,5,2,20,  0.5,0.5,0.5,0.5 ) -- Light_Sync_off

leds_table[21] = Colored_Rect:new(571,410+corrY,2,18,  0.0,0.7,0.0,1 ) -- InverseEnv_On (Green indicator)
leds_table[22] = Colored_Rect:new(571,410+corrY,2,18,  0.5,0.5,0.5,0.5 ) -- InverseEnv_Off (Grey indicator)

local others_table = {Triangle, RandText, Q_Rnd_Linked, Q_Rnd_Linked2, Line, Line2, Loop_Dis, Volume, VolumeFill, Attack, AttackFill, Release, ReleaseFill}

others_table[1] = Txt2:new(642,415+corrY2,55,18, 0.4,0.4,0.4,1, ">","Arial",20) --Triangle
others_table[2] = Txt2:new(749,374+corrY2,55,18, 0.4,0.4,0.4,1, "Intensity","Arial",10) --RandText

others_table[3] = Line_colored:new(482,375+corrY,152,18,  0.7,0.5,0.1,1) --| Q_Rnd_Linked (Bracket)
others_table[4] = Line2:new(480,380+corrY,156,18,  0.177,0.177,0.177,1)--| Q_Rnd_Linked2 (Bracket fill)

others_table[5] = Line:new(677,404+corrY,82,6) --Line (Preset/Velocity Bracket)
others_table[6] = Line2:new(677,407+corrY,82,4,  0.177,0.177,0.177,1)--Line2 (Preset/Velocity Bracket fill)
others_table[7] = Colored_Rect_top:new(10,28,1024,15,  0.23,0.23,0.23,0.5)--Loop_Dis (Loop Disable fill)
others_table[8] = Line:new(771,404+corrY,61,6) --Line (Mode Bracket)
others_table[9] = Line2:new(771,407+corrY,61,4,  0.177,0.177,0.177,1)--Line2 (Mode Bracket fill)

others_table[10] = Line:new(846,404+corrY,61,6) --Line (Volume Bracket)
others_table[11] = Line2:new(846,407+corrY,61,4,  0.177,0.177,0.177,1)--Line2 (Volume Bracket fill)

others_table[12] = Line:new(503,404+corrY,82,6) --Line (Attack Bracket)
others_table[13] = Line2:new(503,407+corrY,82,4,  0.177,0.177,0.177,1)--Line2 (Attack Bracket fill)

others_table[14] = Line:new(601,404+corrY,61,6) --Line (Release Bracket)
others_table[15] = Line2:new(601,407+corrY,61,4,  0.177,0.177,0.177,1)--Line2 (Release Bracket fill)

local Frame_Sync_TB = {leds_table[5]}
local Frame_Sync_TB2 = {leds_table[6]}
local Frame_Loop_TB = {leds_table[3]}
local Frame_Loop_TB2 = {leds_table[4], others_table[7]}
local Frame_TB = {elm_table[1], elm_table[2], elm_table[3]} 
local FrameR_TB = {others_table[5], others_table[6], others_table[8], others_table[9], others_table[10], others_table[11], others_table[12], others_table[13], others_table[14], others_table[15]}
local FrameQR_Link_TB = {others_table[3],others_table[4]}
local Frame_TB1 = {leds_table[2]}
local Frame_TB2 = {elm_table[5], leds_table[1]} -- Grid mode
local Frame_TB2_Trigg = {elm_table[4]}

local Grid1_Led_TB = {elm_table[8]}
local Grid2_Led_TB = {elm_table[9]}
local Grid4_Led_TB = {elm_table[10]}
local Grid8_Led_TB = {elm_table[11]}
local Grid16_Led_TB = {elm_table[12]}
local Grid32_Led_TB = {elm_table[13]}
local Grid64_Led_TB = {elm_table[14]}
local GridT_Led_TB = {elm_table[15]}
local Swing_Led_TB = {elm_table[16]}

local Triangle_TB = {others_table[1]}
local RandText_TB = {others_table[2]}

local InvertEnvOn_TB = {} --leds_table[21]
local InvertEnvOff_TB = {} --leds_table[22]

local Transient_Fill_TB = {elm_table[17]}
local Grid_Fill_TB = {elm_table[18]}

---------------------------------------------------------------
---  Create Menu Settings   ------------------------------------
---------------------------------------------------------------
---------------
-- Menu class --
---------------

------------- "class.lua" is copied from http://lua-users.org/wiki/SimpleLuaClasses -----------
-- class.lua
-- Compatible with Lua 5.1 (not 5.0).
function class(base, init)
  local c = {}    -- a new class instance
  if not init and type(base) == 'function' then
     init = base
     base = nil
  elseif type(base) == 'table' then
   -- our new class is a shallow copy of the base class!
     for i,v in pairs(base) do
        c[i] = v
     end
     c._base = base
  end
  -- the class will be the metatable for all its objects,
  -- and they will look up their methods in it.
  c.__index = c

  -- expose a constructor which can be called by <classname>(<args>)
  local mt = {}
  mt.__call = function(class_tbl, ...)
  local obj = {}
  setmetatable(obj,c)
  if init then
     init(obj,...)
  else 
     -- make sure that any stuff from the base class is initialized!
     if base and base.init then
     base.init(obj, ...)
     end
  end
  return obj
  end
  c.init = init
  c.is_a = function(self, klass)
     local m = getmetatable(self)
     while m do 
        if m == klass then return true end
        m = m._base
     end
     return false
  end
  setmetatable(c, mt)
  return c
end

----------------
-- Menu class --
----------------
-- To create a new menu instance, call this function like this:
--   menu_name = Menu("menu_name")
local Menu = 
 class(
   function(menu, id)
     menu.id = id    
     menu.items = {}       -- Menu items are collected to this table
     menu.items_str = ""
     menu.curr_item_pos = 1
   end
 )

------------------
-- Menu methods --
------------------
-- Returns "menu item table" (or false if "id" not found)
function Menu:get_item_from_id(id)
 for i=1, #self.items do
   if self.items[i].id == id then
     return self.items[i]
   end
 end
 return false
end

-- Updates "menu item type" variables (_has_submenu, _last_item_in_submenu etc.)
function Menu:update_item(item_table)
 local t = item_table
 t._has_submenu = false
 t._last_item_in_submenu = false
 t.id = self.curr_item_pos
 
 if string.sub(t.label, 1, 1) == ">" or
    string.sub(t.label, 1, 2) == "<>" or
    string.sub(t.label, 1, 2) == "><" then
   t._has_submenu = true
   t.id = -1
   self.curr_item_pos = self.curr_item_pos - 1

 elseif string.sub(t.label, 1, 1) == "<" then
   t._has_submenu = false
   t._last_item_in_submenu = true
 end
 --t.id = self.curr_item_pos
 self.curr_item_pos = self.curr_item_pos + 1
end

-- Returns the created table and table index in "menu_obj.items"
function Menu:add_item(...)
 local t = ... or {}
 self.items[#self.items+1] = t -- add new menu item at the end of menu
 
 -- Parse arguments
 for i,v in pairs(t) do
   --msg(i .. " = " .. tostring(v))
   if i == "label" then
     t.label = v
   elseif i == "selected" then
     t.selected = v
   elseif i == "active" then
     t.active = v
   elseif i == "toggleable" then
     t.toggleable = v
   elseif i == "command" then
     t.command = v
   end
 end
 
 -- Default values for menu items
 -- (Edit these)
 if t.label == nil or t.label == "" then
   t.label = tostring(#self.items) -- if label is nil or "" -> label is set to "table index in menu_obj.items"
 end
 
 if t.selected == nil then
   t.selected = false   -- edit
 end
 
 if t.active == nil then
   t.active = true      -- edit
 end
 
 if t.toggleable == nil then
   t.toggleable = false -- edit
 end

 return t, #self.items
end

-- Get menu item table at index
function Menu:get_item(index)
 if self.items[index] == nil then
   return false
 end
 return self.items[index]
end

-- Show menu at mx, my
function Menu:show(mx, my)
 gfx.x = mx
 gfx.y = my
 
 -- Check which items has a function to call when a menu is about to be shown
 for i=1, #self.items do
   if self.items[i].on_menu_show ~= nil then
     self.items[i].on_menu_show()
   end
   -- Update item
   self:update_item(self.items[i])
 end
 
 -- Convert menu item tables to string
 self.items_str = self:table_to_string() or ""
 self.val = gfx.showmenu(self.items_str)
 if self.val > 0 then
   self:update(self.val)
 end
 self.curr_item_pos = 1 -- set "menu item position counter" back to the initial value
end

function Menu:update(menu_item_index)
 -- check which "menu item id" matches with "menu_item_index"
 for i=1, #self.items do
   if self.items[i].id == menu_item_index then
     menu_item_index = i
     break
   end
 end
 local i = menu_item_index 
 -- if menu item is "toggleable" then toggle "selected" state
 if self.items[i].toggleable then
   self.items[i].selected = not self.items[i].selected
 end
 -- if menu item has a "command" (function), then call that function
 if self.items[i].command ~= nil then
   self.items[i].command()
 end
end

-- Convert "Menu_obj.items" to string
function Menu:table_to_string()
 if self.items == nil then
   return
 end
 self.items_str = ""
 
 for i=1, #self.items do
   local temp_str = ""
   local menu_item = self.items[i]
   if menu_item.selected then
     temp_str = "!"
   end
   
   if not menu_item.active then
     temp_str = temp_str .. "#"
   end
   
   if menu_item.label ~= "" then
     temp_str = temp_str .. menu_item.label .. "|"
   end

   self.items_str = self.items_str .. temp_str
 end
 
 return self.items_str
end

--END of Menu class----------------------------------------------------


----------------------------------------------------------------------------------------------------
---  Create controls objects(btns,sliders etc) and override some methods   -------------------------
----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--- Filter Sliders ------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Filter HP_Freq --------------------------------
local HP_Freq = HP_Slider:new(20,410+corrY,160,18, 0.28,0.4,0.7,0.8, "Low Cut","Arial",16, HF_Slider )
-- Filter LP_Freq --------------------------------
local LP_Freq = LP_Slider:new(20,430+corrY,160,18, 0.28,0.4,0.7,0.8, "High Cut","Arial",16, LF_Slider )
--------------------------------------------------
-- Filter Freq Sliders draw_val function ---------
--------------------------------------------------
function HP_Freq:draw_val()
if LP_Freq.norm_val <= HP_Freq.norm_val+0.05 then LP_Freq.norm_val = HP_Freq.norm_val+0.05 end --auto "bell"
if HP_Freq.norm_val <= 0 then HP_Freq.norm_val = 0 end
if HP_Freq.norm_val >= 1 then HP_Freq.norm_val = 1 end
if LP_Freq.norm_val >= 1 then LP_Freq.norm_val = 1 end
if LP_Freq.norm_val <= 0 then LP_Freq.norm_val = 0 end
  local sx = 16+(self.norm_val*100)*1.20103
  self.form_val = floor(exp(sx*logx(1.059))*8.17742) -- form val

if self.form_val > 20000 then self.form_val = 20000 end
  -------------
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%d", self.form_val) .." Hz"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val) -- draw Slider Value
  if self.form_val == 20 then self.form_val = 0 end -- filter off
end
-------------------------
function LP_Freq:draw_val()
if HP_Freq.norm_val >= LP_Freq.norm_val-0.05 then HP_Freq.norm_val = LP_Freq.norm_val-0.05 end --auto "bell"
  local sx = 16+(self.norm_val*100)*1.20103
  self.form_val = floor(exp(sx*logx(1.059))*8.17742) -- form val
  -------------
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%d", self.form_val) .." Hz"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val) -- draw Slider Value
end


-- Filter Gain -----------------------------------
local Fltr_Gain = G_Slider:new(20,450+corrY,160,18,  0.28,0.4,0.7,0.8, "Filtered Gain","Arial",16, out_gain )
function Fltr_Gain:draw_val()
  self.form_val = self.norm_val*30  -- form value
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." dB"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
end

--------------------------------------------------
-- onUp function for Filter Freq sliders ---------
--------------------------------------------------
function Fltr_Sldrs_onUp()
   if Wave.AA then Wave:Processing()
      if Wave.State then
         Wave:Redraw() 
         Gate_Gl:Apply_toFiltered()
Gate_on2 = 1
      end
   end
end
----------------
HP_Freq.onUp   = Fltr_Sldrs_onUp
LP_Freq.onUp   = Fltr_Sldrs_onUp
--------------------------------------------------
-- onUp function for Filter Gain slider  ---------
--------------------------------------------------
Fltr_Gain.onUp =
function() 
   if Wave.State then 
      Wave:Redraw()
      Gate_Gl:Apply_toFiltered() 
Gate_on2 = 1
   end 
end



-------------------------------------------------------------------------------------
--- Gate Sliders --------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Threshold -------------------------------------
-------------------------------------------------
local Gate_Thresh = T_Slider:new(210,380+corrY,160,18, 0.28,0.4,0.7,0.8, "Threshold","Arial",16, readrms )
function Gate_Thresh:draw_val()
  self.form_val = (self.norm_val-1)*57-3
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." dB"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val) -- draw Slider Value
  Gate_Thresh:draw_val_line() -- Draw GATE Threshold lines !!!
end
     
--------------------------------------------------
-- Gate Threshold-lines function -----------------
-------------------------------------------------- 
function Gate_Thresh:draw_val_line()
  if Wave.State then gfx.set(0.7,0.7,0.7,0.3) --цвет линий treshold
    local val = (10^(self.form_val/20)) * Wave.Y_scale * Wave.vertZoom * Z_h -- value in gfx
    if val>Wave.h/2 then return end            -- don't draw lines if value out of range
    local val_line1 = Wave.y + Wave.h/2 - val  -- line1 y coord
    local val_line2 = Wave.y + Wave.h/2 + val  -- line2 y coord
    gfx.line(Wave.x, val_line1, Wave.x+Wave.w-1, val_line1 )
    gfx.line(Wave.x, val_line2, Wave.x+Wave.w-1, val_line2 )
  end
end

-- Sensitivity -------------------------------------
local Gate_Sensitivity = S_Slider:new(210,400+corrY,160,18, 0.28,0.4,0.7,0.8, "Sensitivity","Arial",16, Sens_Slider )
function Gate_Sensitivity:draw_val()
  self.form_val = 2+(self.norm_val)*8       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." dB"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
end
-- Retrig ----------------------------------------
local Gate_Retrig = Rtg_Slider:new(210,420+corrY,160,18, 0.28,0.4,0.7,0.8, "Retrig","Arial",16, retrigms )
function Gate_Retrig:draw_val()
  self.form_val  = 20+ self.norm_val * 180   -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
end
-- Reduce points slider -------------------------- 
local Gate_ReducePoints = Rdc_Slider:new(210,450+corrY,160,18, 0.28,0.4,0.7,0.8, "Reduce","Arial",16, 1 )
function Gate_ReducePoints:draw_val()
  self.cur_max   = self.cur_max or 0 -- current points max
  self.form_val  = ceil(self.norm_val * self.cur_max) -- form_val
  if self.form_val==0 and self.cur_max>0 then self.form_val=1 end -- надо переделать,это принудительно 
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%d", self.form_val)
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
end
----------------
Gate_ReducePoints.onUp = 
function()
  if Wave.State then Gate_Gl:Reduce_Points() end
end
--------------------------------------------------
-- onUp function for Gate sliders(except reduce) -
--------------------------------------------------
function Floor_Sldrs_onUp() 
   if Wave.State then Gate_Gl:Apply_toFiltered() end 
Gate_on2 = 1
end
----------------
Gate_Thresh.onUp    = Floor_Sldrs_onUp
Gate_Sensitivity.onUp = Floor_Sldrs_onUp
Gate_Retrig.onUp    = Floor_Sldrs_onUp

-----------------Offset Slider------------------------ 
local Offset_Sld = O_Slider:new(400,430+corrY,94,18, 0.28,0.4,0.7,0.8, "Offset","Arial",16, Offs_Slider )
function Offset_Sld:draw_val()

  self.form_val  = (50- self.norm_val * 100)*( -1)     -- form_val

  function fixzero()
  FixMunus = self.form_val
  if (FixMunus== 0.0)then FixMunus = 0
  end

  end
  fixzero()  
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", FixMunus).."ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
  Offset_Sld.form_val = Offset_Sld.form_val-0.5 -- correction
  end
Offset_Sld.onUp =
function() 
   if Wave.State then
     Offset_Sld_DoIt()
      fixzero() 
Gate_on2 = 1
   end 
end

-----------------HBiasSlider Slider------------------------ 
local HBiasSlider = Q_Slider_Green:new(596,410+corrY,73,18, 0.218,0.542,0.45,0.8, "Rel","Arial",16, 0.5 )
function HBiasSlider:draw_val()

  self.form_val  = (self.norm_val * 200)-100     -- form_val

  function fixzero()
  self_form_val = self.form_val
    if (self_form_val == 0.0) then self_form_val = 0 end
  end
  fixzero()  
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self_form_val)..""
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
  HBiasSlider = self_form_val/100
  HBS_rev = ((self_form_val-100)+100)*-1
   HBiasSlider2 = ((exp(HBS_rev/50))+1)*-1 --reverse slider
  HBS_rev2 = (self.norm_val-1)*-1
  HBS_corr = (HBS_rev2*10) +1
  HBS = self.norm_val


if HBS <= 0.5  then 
    HBS = HBS*(self.norm_val*1.5) 
      else
    HBS = HBS
end


  end
HBiasSlider.onUp =
function() 
   if Wave.State then
    fixzero() 

Gate_on2 = 1
   end 
end

-- QStrength slider ------------------------------ 
local QStrength_Sld = Q_Slider:new(596,387+corrY,73,18, 0.28,0.4,0.7,0.8, "QStr","Arial",16, QuantizeStrength*0.01 )
function QStrength_Sld:draw_val()
  self.form_val = (self.norm_val)*100       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val)..""
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
  q_strength =  floor(QStrength_Sld.form_val)
end
QStrength_Sld.onUp =
function() 

end

-- Gain slider ------------------------------ 
local XFade_Sld = X_Slider:new(841,410+corrY,73,18, 0.28,0.4,0.7,0.8, "Gain","Arial",16, 0.5 )
function XFade_Sld:draw_val()
  self.form_val = (self.norm_val*200) - 100       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val)..""
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
  self.form_val =   self.form_val +100
  EnvGainSld = ((XFade_Sld.form_val*(XFade_Sld.form_val*40))/50000)/8 --  exp(XFade_Sld.form_val/8.686)
  EnvGainSld_p = (self.norm_val)*4
  EnvGainSld2 =  (((XFade_Sld.form_val*(XFade_Sld.form_val*40))/50000)/8 )
  PanWidth =  (((XFade_Sld.form_val)-112)/12*-1)
  PanWidth2 =  (((XFade_Sld.form_val)-100)/100*-1)+1
  PanWidth3 =  (exp((XFade_Sld.form_val*-1)/24.04491734815))*64
      if PanWidth3 <= 1 then PanWidth3 = 1 end
      if PanWidth2 < 0.01 then PanWidth2 = 0.01 end
      if PanWidth < 1 then PanWidth = PanWidth2 end
end
XFade_Sld.onUp =
function() 
Gate_on2 = 1
end


-- Floor slider ------------------------------ 
local Floor_Sld = Q_Slider_Red:new(841,430+corrY,73,18, 0.564,0.261,0.221,0.8, "Floor","Arial",16, 0 )
function Floor_Sld:draw_val()
  self.form_val = (self.norm_val)*100       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val)..""
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
Floor_Sld.form_val = Floor_Sld.form_val/2
FloorVal = ((Floor_Sld.form_val*(Floor_Sld.form_val*40))/50000)/8
FloorVal_p = ((self.norm_val-1)*-1)/4
FloorVal_inv = (exp(((Floor_Sld.form_val)-100)/100*-1)-1)/1.75
end
Floor_Sld.onUp =
function() 
Gate_on2 = 1
end

-- Attack slider ------------------------------ 
local Attack_Sld = Q_Slider_Violet:new(498,410+corrY,94,18, 0.419,0.281,0.716,0.8, "Att","Arial",16, 0.3  )
function Attack_Sld:draw_val()
  self.form_val = (self.norm_val)*100       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val)..""
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
  AttVal2 =  (floor(Attack_Sld.form_val))/2000 -- grid mode attval
  AttVal =   (exp((floor((Attack_Sld.form_val-100)*-1))/30)) -- transient mode attval
end
Attack_Sld.onUp =
function() 
Gate_on2 = 1
end

-- Shape slider ------------------------------ 
local Shape_Sld = Q_Slider_Green:new(596,430+corrY,73,18, 0.218,0.542,0.45,0.8, "Shape","Arial",16, 0.5 )
function Shape_Sld:draw_val()
  self.form_val = (self.norm_val)*100       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val)..""
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
  CurveVal =  (Shape_Sld.norm_val*2)-1 --  ((Shape_Sld.form_val*(Shape_Sld.form_val*40))/50000)/8
end
Shape_Sld.onUp =
function() 
Gate_on2 = 1
end

-- BiasThr slider ------------------------------ 
local BiasThr_Sld = Q_Slider_Green_Bias:new(596,450+corrY,73,18, 0.218,0.542,0.45,0.8, "Rel.Thr","Arial",16, 1 )
function BiasThr_Sld:draw_val()
   self_norm_val = self.norm_val*1.4

      if self_norm_val == 0 then self.form_val = 0.5
      elseif self_norm_val <= 0.1 then self.form_val = 1
      elseif self_norm_val <= 0.2 then self.form_val = 1.5
      elseif self_norm_val <= 0.3 then self.form_val = 2
      elseif self_norm_val <= 0.4 then self.form_val = 3
      elseif self_norm_val <= 0.5 then self.form_val = 4
      elseif self_norm_val <= 0.6 then self.form_val = 6
      elseif self_norm_val <= 0.7 then self.form_val = 8
      elseif self_norm_val <= 0.8 then self.form_val = 12
      elseif self_norm_val <= 0.9 then self.form_val = 16
      elseif self_norm_val <= 1.0 then self.form_val = 24
      elseif self_norm_val <= 1.1 then self.form_val = 32
      elseif self_norm_val <= 1.2 then self.form_val = 48
      elseif self_norm_val <= 1.3 then self.form_val = 64
      elseif self_norm_val <= 1.4 then self.form_val = 0
      end

  local x,y,w,h  = self.x,self.y,self.w,self.h

    if self.form_val == 0 then 
      strng = string.format("%s", "All")..""
      HlvLngth = 0
        else
      strng = string.format("%.0f", self.form_val*2)..""
      HlvLngth = 1/self.form_val
    end

  local val = strng
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
  HlvLngth = HlvLngth
end
BiasThr_Sld.onUp =
function() 
Gate_on2 = 1
end
-------------------------------------------------------------------------------------
--- Range Slider --------------------------------------------------------------------
-------------------------------------------------------------------------------------
local Gate_VeloScale = Rng_Slider:new(673,430+corrY,90,18, 0.28,0.4,0.7,0.8, "Range","Arial",16, VeloRng, VeloRng2 )---velodaw 
function Gate_VeloScale:draw_val()

  self.form_val  = floor(1+ self.norm_val * 126)  -- form_val
  self.form_val2 = floor(1+ self.norm_val2 * 126) -- form_val2
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val  = string.format("%d", self.form_val)
  local val2 = string.format("%d", self.form_val2)
  local val_w,  val_h  = gfx.measurestr(val)
  local val2_w, val2_h = gfx.measurestr(val2)
  local T = 0 -- set T = 0 or T = h (var1, var2 text position) 
  gfx.x = x+3
  gfx.y = y+(h-val_h)/2 + T
  gfx.drawstr(val)  -- draw value 1
  gfx.x = x+w-val2_w-3
  gfx.y = y+(h-val2_h)/2 + T
  gfx.drawstr(val2) -- draw value 2
end
Gate_VeloScale.onUp =
function() 
   if Wave.State then
        Gate_on2 = 1
   end 
end

-------------------------------------------------------------------------------------
--- Loop Slider --------------------------------------------------------------------
-------------------------------------------------------------------------------------
local LoopScale = Loop_Slider:new(10,29,1024,18, 0.28,0.4,0.7,0.8, "","Arial",16, 0,1 ) -- Play Loop Range

function LoopScale:draw_val()

           if loop_start then
              if self_Zoom == nil then self_Zoom = 1 end
              if shift_Pos == nil then shift_Pos = 0 end
              rng1 = math_round(loop_start+(self.norm_val/self_Zoom+(shift_Pos/1024))*loop_length,3)
              rng2 = math_round(loop_start+(self.norm_val2/self_Zoom+(shift_Pos/1024))*loop_length,3)
           end
end

              if rng1 == nil then rng1 = 0 end
              if rng2 == nil then rng2 = 1 end

-- Swing Button ----------------------------
local Swing_Btn = Button_top:new(391,5,50,19, 0.3,0.3,0.3,1, "Swing",    "Arial",16 )
Swing_Btn.onClick = 
function()
   if Wave.State then 
Gate_on2 = 1
    local _, division, _, swingamt = r.GetSetProjectGrid(0,false)
        if Swing_on == 0 then 
             Swing_on = 1
    r.GetSetProjectGrid(0, true, division, 1, swing_slider_amont)
               else
             Swing_on = 0
    r.GetSetProjectGrid(0, true, division, 0)
        end
DrawGridGuides()
   end 
end 

triplets = 2

-- Grid Button T----------------------------
local GridT_Btn = Button_top:new(344,5,40,19, 0.3,0.3,0.3,1, "T",    "Arial",16 )
GridT_Btn.onClick = 
function()
   if Wave.State then 
Gate_on2 = 1
        if GridT_on == 0 then 
             GridT_on = 1
             triplets = 3
    local _, division, _, _ = r.GetSetProjectGrid(0,false)
    r.GetSetProjectGrid(0, true, (division+division/3)/2, swing_mode, swingamt)
               else
             GridT_on = 0
             triplets = 2
    local _, division, _, _ = r.GetSetProjectGrid(0,false)
    r.GetSetProjectGrid(0, true, division+division/2, swing_mode, swingamt)
        end
DrawGridGuides()
   end 
end 

-- Grid Button 1----------------------------
local Grid1_Btn = Button_top:new(50,5,40,19, 0.3,0.3,0.3,1, "1",    "Arial",16 )
Grid1_Btn.onClick = 
function()
   if Wave.State then 
Gate_on2 = 1
    local _, division, _, _ = r.GetSetProjectGrid(0,false)
        if Grid1_on == 0 then 
             Grid1_on = 1
             Grid2_on = 0
             Grid4_on = 0
             Grid8_on = 0
             Grid16_on = 0
             Grid32_on = 0
             Grid64_on = 0
    r.GetSetProjectGrid(0, true, 2/triplets, swing_mode, swingamt)
               else
             Grid1_on = 0
        end
DrawGridGuides()
   end 
end 

-- Grid Button 1/2----------------------------
local Grid2_Btn = Button_top:new(92,5,40,19, 0.3,0.3,0.3,1, "1/2",    "Arial",16 )
Grid2_Btn.onClick = 
function()
   if Wave.State then 
Gate_on2 = 1
    local _, division, _, _ = r.GetSetProjectGrid(0,false)
        if Grid2_on == 0 then 
             Grid1_on = 0
             Grid2_on = 1
             Grid4_on = 0
             Grid8_on = 0
             Grid16_on = 0
             Grid32_on = 0
             Grid64_on = 0
    r.GetSetProjectGrid(0, true, 1/triplets, swing_mode, swingamt)
               else
             Grid2_on = 0
        end
DrawGridGuides()
   end 
end 

-- Grid Button 1/4----------------------------
local Grid4_Btn = Button_top:new(134,5,40,19, 0.3,0.3,0.3,1, "1/4",    "Arial",16 )
Grid4_Btn.onClick = 
function()
   if Wave.State then 
Gate_on2 = 1
    local _, division, _, _ = r.GetSetProjectGrid(0,false)
        if Grid4_on == 0 then 
             Grid1_on = 0
             Grid2_on = 0
             Grid4_on = 1
             Grid8_on = 0
             Grid16_on = 0
             Grid32_on = 0
             Grid64_on = 0
    r.GetSetProjectGrid(0, true, 0.5/triplets, swing_mode, swingamt)
               else
             Grid4_on = 0
        end
DrawGridGuides()
   end 
end 

-- Grid Button 1/8----------------------------
local Grid8_Btn = Button_top:new(176,5,40,19, 0.3,0.3,0.3,1, "1/8",    "Arial",16 )
Grid8_Btn.onClick = 
function()
   if Wave.State then 
Gate_on2 = 1
    local _, division, _, _ = r.GetSetProjectGrid(0,false)
        if Grid8_on == 0 then 
             Grid1_on = 0
             Grid2_on = 0
             Grid4_on = 0
             Grid8_on = 1
             Grid16_on = 0
             Grid32_on = 0
             Grid64_on = 0
    r.GetSetProjectGrid(0, true, 0.25/triplets, swing_mode, swingamt)
               else
             Grid8_on = 0
        end
DrawGridGuides()
   end 
end 

-- Grid Button 1/16----------------------------
local Grid16_Btn = Button_top:new(218,5,40,19, 0.3,0.3,0.3,1, "1/16",    "Arial",16 )
Grid16_Btn.onClick = 
function()
   if Wave.State then 
Gate_on2 = 1
    local _, division, _, _ = r.GetSetProjectGrid(0,false)
        if Grid16_on == 0 then 
             Grid1_on = 0
             Grid2_on = 0
             Grid4_on = 0
             Grid8_on = 0
             Grid16_on = 1
             Grid32_on = 0
             Grid64_on = 0
    r.GetSetProjectGrid(0, true, 0.125/triplets, swing_mode, swingamt)
               else
             Grid16_on = 0
        end
DrawGridGuides()
   end 
end 

-- Grid Button 1/32----------------------------
local Grid32_Btn = Button_top:new(260,5,40,19, 0.3,0.3,0.3,1, "1/32",    "Arial",16 )
Grid32_Btn.onClick = 
function()
   if Wave.State then 
Gate_on2 = 1
    local _, division, _, _ = r.GetSetProjectGrid(0,false)
        if Grid32_on == 0 then 
             Grid1_on = 0
             Grid2_on = 0
             Grid4_on = 0
             Grid8_on = 0
             Grid16_on = 0
             Grid32_on = 1
             Grid64_on = 0
    r.GetSetProjectGrid(0, true, 0.0625/triplets, swing_mode, swingamt)
               else
             Grid32_on = 0
        end
DrawGridGuides()
   end 
end 

-- Grid Button 1/64----------------------------
local Grid64_Btn = Button_top:new(302,5,40,19, 0.3,0.3,0.3,1, "1/64",    "Arial",16 )
Grid64_Btn.onClick = 
function()
   if Wave.State then 
Gate_on2 = 1
    local _, division, _, _ = r.GetSetProjectGrid(0,false)
        if Grid64_on == 0 then 
             Grid1_on = 0
             Grid2_on = 0
             Grid4_on = 0
             Grid8_on = 0
             Grid16_on = 0
             Grid32_on = 0
             Grid64_on = 1
    r.GetSetProjectGrid(0, true, 0.03125/triplets, swing_mode, swingamt)
               else
             Grid64_on = 0
        end
DrawGridGuides()
   end 
end 

-------------------------------------------------------------------------------------
-----------------Swing Slider-----------------------------------------------------
-------------------------------------------------------------------------------------

local Swing_Sld = Sw_Slider:new(443,5,100,20, 0.28,0.4,0.7,0.8, " ","Arial",16, swngdefamt )
function Swing_Sld:draw_val()

  self.form_val  = ((100- self.norm_val * 200)*( -1))     -- form_val

  function fixzero()
  self_form_val = self.form_val
    if (self_form_val == 0.0) then self_form_val = 0 end
  end
  fixzero()  
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self_form_val).." %"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
  swing_slider_amont = self_form_val/100
  end
Swing_Sld.onUp =
function() 
   if Wave.State then
    local _, division, _, _ = r.GetSetProjectGrid(0,false)
    r.GetSetProjectGrid(0, true, division, swing_mode, swing_slider_amont)
    fixzero() 
Gate_on2 = 1
   end 
end

-------------------------------------------------------------------------------------
--- Buttons -------------------------------------------------------------------------
-------------------------------------------------------------------------------------

-- Create Loop  Button ----------------------------
local Loop_Btn = Button_top:new(984,5,50,20, 0.3,0.3,0.3,1, "Loop",    "Arial",16 )
Loop_Btn.onClick = 
function()
   if Wave.State then 
        if Loop_on == 0 then 
             Loop_on = 1
               else
             Loop_on = 0
        end
   end 
end 

-- Create Sync Button ----------------------------
local Sync_Btn = Button_top:new(924,5,50,20, 0.3,0.3,0.3,1, "Sync",    "Arial",16 )
Sync_Btn.onClick = 
function()
   if Wave.State then 
        if Sync_on == 0 then 
             Sync_on = 1
               else
             Sync_on = 0
        end
   end 
end 

-- Get Selection button --------------------------
local Get_Sel_Button = Button:new(20,380+corrY,160,25, 0.3,0.3,0.3,1, "Get Selection",    "Arial",16 )
Get_Sel_Button.onClick = 

function()

Slice_Status = 1
SliceQ_Status = 0
MarkersQ_Status = 0
Slice_Init_Status = 0
SliceQ_Init_Status = 0
Markers_Status = 0
MIDISmplr_Status = 0
Take_Check = 0
Trigg_Status = 0
Reset_Status = 0
Midi_sampler_offs_stat = 0
Midi_Check = 0
WaveCheck = 0

    r.Undo_BeginBlock() 
r.PreventUIRefresh(1)


left, right = huge, -huge
for t = 0, reaper.CountTracks(0)-1 do
    local track = reaper.GetTrack(0, t)
    local tR = {}
    local razorOK, razorStr = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    if razorOK and #razorStr ~= 0 then
        for razorLeft, razorRight, envGuid in razorStr:gmatch([[([%d%.]+) ([%d%.]+) "([^"]*)"]]) do
            if envGuid == "" then
                local razorLeft, razorRight = tonumber(razorLeft), tonumber(razorRight)
            if razorLeft  < left  then left  = razorLeft end
            if razorRight > right then right = razorRight end
                table.insert(tR, {left = razorLeft, right = razorRight})
            end
        end

    if razorOK and #razorStr ~= 0 then
        reaper.Main_OnCommand(40297,0)
        reaper.SetTrackSelected(track, true)
    else
        reaper.SetTrackSelected(track, false)
    end

    end
    for i = 0, reaper.CountTrackMediaItems(track)-1 do
        local item = reaper.GetTrackMediaItem(track, i)
  --      reaper.SetMediaItemSelected(item, false)
        local left = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local right = left + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        for _, r in ipairs(tR) do
            if left < r.right and right > r.left then
                reaper.SetMediaItemSelected(item, true)
            end
        end
    end
end
if left <= right then
    reaper.GetSet_LoopTimeRange2(0, true, false, left, right, false)
end
reaper.UpdateArrange()


 loopcheck = 0
local cursorpos = r.GetCursorPosition()
----loopcheck------
local loopcheckstart, loopcheckending = r.GetSet_LoopTimeRange( 0, false, 0, 0, 0 )

if loopcheckstart == loopcheckending then
     r.Main_OnCommand(41039, 0) -- Loop points: Set loop points to items
     r.Main_OnCommand(40290, 0) -- Time selection: Set time selection to items
else
     r.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
end

----------- Delete Created Item --------------
if NoItems == 1 then
    for tr, trck in pairs(Table) do
        if trck then 
             for it, del_it in pairs(Table2) do
                if del_it then 
                   reaper.DeleteTrackMediaItem(tr, it)
                   reaper.UpdateArrange()
                   NoItems = 0
                end
             end    
        end
    end
end
------------------------------------

NoItems = 0
if r.CountSelectedMediaItems(0) == 0 and r.CountSelectedTracks(0) == 1 then -- if no items, create -----

     Table = {}
     Table2 = {}

     track = r.GetSelectedTrack(0, 0)
     if loopcheckstart ~= loopcheckending then
       midiItem = r.CreateNewMIDIItemInProj(track, loopcheckstart, loopcheckending, false) -- 0.0001
       reaper.SetMediaItemInfo_Value(midiItem, "B_UISEL", 1)
       reaper.SetMediaItemInfo_Value( midiItem, "I_CUSTOMCOLOR",reaper.ColorToNative(25,25,25)|0x1000000 )
       Table[track] = track
       Table2[midiItem] = midiItem
       NoItems = 1
     end

end ----------------------------------------------------------------

if loopcheckstart == loopcheckending and loopcheckstart and loopcheckending then 
     loopcheck = 0
       else
     loopcheck = 1
end
r.SetEditCurPos(cursorpos,0,0) 

midi_check()

r.PreventUIRefresh(-1)
    r.Undo_EndBlock("Init", -1) 

--------------------------A Bit More Foolproof----------------------------



function collect_itemtake_param()    -- collect parameter on sel item and active take for SM tables and displacement calcs...
   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   mute_check = r.GetMediaItemInfo_Value(sel_item, "B_MUTE")
 end
 
   collect_itemtake_param()              -- get bunch of parameters about this item


if selected_tracks_count > 1 then

------------------------------------------Error Message-----------------------------------------

local timer = 2 -- Time in seconds
local time = reaper.time_precise()
local function Msg()
   local char = gfx.getchar()
     if char == 27 or char == -1 or (reaper.time_precise() - time) > timer then ErrMsg_Ststus = 0 return end
local Get_Sel_ErrMsg = ErrMsg:new(680,450+corrY,260,25, 1, 1, 1, 1, "Only single track items, please",    "Arial", 22)
local ErrMsg_TB = {Get_Sel_ErrMsg}
ErrMsg_Ststus = 1
     for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
   gfx.update()
  r.defer(Msg)
end
end
Msg()

--------------------------------------End of Error Message--------------------------------------------

Init()

 goto zzz 
end -- не запускать, если айтемы находятся на разных треках.

--------------------------------------------------------------------------------
    r.Undo_BeginBlock() 
r.PreventUIRefresh(1)
Muted = 0
if number_of_takes == 1 and mute_check == 1 then 
r.Main_OnCommand(40175, 0) 
Muted = 1
end

getsomerms()

if Muted == 1 then
r.Main_OnCommand(40175, 0) 
end
r.PreventUIRefresh(-1)
    r.Undo_EndBlock("Toggle Item Mute", -1) 

Init_Srate()
Init()
getitem()

if Wave.State then
--      Wave:Reset_All() --Reset item to Init before the "Get Selection"
      DrawGridGuides()
end

::zzz::

end


-- Create Settings Button ----------------------------
local Settings = Button_Settings:new(9,10,40,40, 0.3, 0.3, 0.3, 1, ">",    "Arial",20 )
Settings.onClick = 
function()
   Wave:Settings()
end 

-- Create Add Markers Button ----------------------------
local Add_Markers = Button:new(498,380+corrY,67,25, 0.3,0.3,0.3,1, "Markers",    "Arial",16 )
Add_Markers.onClick = 
function()
   if Wave.State then Wave:Add_Markers() end 
end 

-- Create Quantize Markers Button ----------------------------
local Quantize_Markers = Button:new(567,380+corrY,25,25, 0.3,0.3,0.3,1, "Q",    "Arial",16 )
Quantize_Markers.onClick = 
function()
   if Wave.State then Wave:Quantize_Markers() end 
end 


-- Reset All Button ----------------------------
local Reset_All = Button:new(970,445+corrY,55,25, 0.3,0.3,0.3,1, "Reset",    "Arial",16 )
Reset_All.onClick = 
function()
r.PreventUIRefresh(1)

   if Wave.State then 
    --        r.Main_OnCommand(40635, 0)     -- Remove Selection
       Wave:Reset_All() 
              if TrackEnv == 1 then 
                Gate_on2 = 0
                else
                Gate_on2 = 1
             end

       Gate_on = 0

            time_start = reaper.time_precise()     
               local function Main()        
                   local elapsed = reaper.time_precise() - time_start       
                   if elapsed >= 0.2 then
                       Gate_on2 = 0
                       return
                       else
                       reaper.defer(Main)
                   end        
               end       
            Main()
   end 



       if TrackEnv == 1 then

               r.PreventUIRefresh(1)
               r.Undo_BeginBlock()
               
               tracks = r.CountSelectedTracks(0)

               for i=0, tracks-1 do
               local track = r.GetSelectedTrack(0, i)
               local envs = r.CountTrackEnvelopes(track)
                      if track then
                            for j = 0, envs-1 do
                                 envelope = r.GetTrackEnvelope( track, j )
                 
                                  if SelectedEnvOnly == 1 then
                                         envelope = r.GetSelectedEnvelope( 0 )
                                   end
                 
                                   if envelope then
                                        _, EnvName = r.GetEnvelopeName(envelope)
                                        env = r.GetTrackEnvelopeByName(track, EnvName)
                                        if env then
      --       r.SetCursorContext(2, env)
                                            loop_n_points = r.CountEnvelopePoints(env)
                                            GetLoopTimeRange()
                     
                                            for i = 1, loop_n_points do
                                              r.DeleteEnvelopePointRange( env, (start), (ending+1/srate) )
                                            end
                                        end
                                   end
                             end
                        end
               end

              if tracks == 0 or (tracks ~= 0 and (loop_n_points == 1 or loop_n_points == nil)) then
                       envelope2 = r.GetSelectedEnvelope( 0 )
                       if envelope2 then
                           loop_n_points2 = r.CountEnvelopePoints(envelope2)
                           start2, ending2 = r.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
                           for i = 1, loop_n_points2 do
                              r.DeleteEnvelopePointRange( envelope2, (start2), (ending2+1/srate) )
                           end
                       end
               end
               
               r.Undo_EndBlock('Delete Points (Track)', 0)
               r.PreventUIRefresh(-1)
               r.UpdateArrange()

       else
              DelTakeEnv()
       end

        if Markers_Status == 1 then
            r.Main_OnCommand(41844, 0)  ---Delete All Markers    
            Markers_Status = 0
        end


end --  for i = 0, tracks-1 do
r.PreventUIRefresh(-1)


local ItemEnvMode = CheckBox_Show:new(970,400+corrY,55,18,  0.28,0.4,0.7,0.8, "Env: ","Arial",16,  1,
                              { "Volume", "Pan", "Pitch" } )
ItemEnvMode.onClick = 
function() 
end


-- Gate Button ----------------------------
local Gate_Btn = Button:new(400,390,94,25, 0.3,0.3,0.3,1, "Shape",    "Arial",16 )
Gate_Btn.onClick = 
function()
   if Wave.State then 
midi_check()
           if TrackEnv == 0 and Midi_Check == 0 then 
                 if ItemEnvMode.norm_val == 1 then
                     r.Main_OnCommand(r.NamedCommandLookup("_S&M_TAKEENVSHOW1"),0) -- show Vol
                 elseif ItemEnvMode.norm_val == 2 then
                     r.Main_OnCommand(r.NamedCommandLookup("_S&M_TAKEENVSHOW2"),0) -- show Pan
                  elseif ItemEnvMode.norm_val == 3 then
                     r.Main_OnCommand(r.NamedCommandLookup("_S&M_TAKEENVSHOW7"),0) -- show Pitch
                 end
           end

         Gate_on2 = 1
   
         Undo_Permit = 1
   
         if Gate_on == 0 then 
              Gate_on = 1
         end

   end 
end 


----------------------------------------
--- Button_TB --------------------------
----------------------------------------
local Loop_TB = {LoopScale}
local LoopBtn_TB = {Loop_Btn, Sync_Btn, Swing_Btn}

local Button_TB = {Get_Sel_Button, Settings, Reset_All}
local Markers_TB = {Add_Markers, Quantize_Markers, QStrength_Sld}
local Button_TB2 = {Gate_Btn} --Create_MIDI, Midi_Sampler, 
 
-------------------------------------------------------------------------------------
--- CheckBoxes ---------------------------------------------------------------------
-------------------------------------------------------------------------------------

-------------------------
local VeloMode = CheckBox:new(673,410+corrY,90,18, 0.28,0.4,0.7,0.8, "","Arial",16,  2, -------velodaw
                              {"Use RMS","Use Peak"} )

VeloMode.onClick = 
function()
    Gate_on2 = 1
end

if NoItems == 0 and WaveCheck == 1 then Guides_mode = Guides_mode else Guides_mode = 2 end --if no items, script starts in Grid mode
local Guides  = CheckBox:new(400,410+corrY,91,18, 0.28,0.4,0.7,0.8, "","Arial",16,  Guides_mode,
                              {"Transients","Grid"} )

Guides.onClick = 
function() 
   if Wave.State then
      Wave:Reset_All()
      DrawGridGuides()
   end 
end

--------------------------------------------------
-- View Checkboxes -------------------------------
-------------------------

local Floor_State = CheckBox_Red:new(917,430+corrY,45,18, 0.564,0.261,0.221,0.8, "","Arial",16,  1,
                              {"Flat","Rise","Fall"} )
Floor_State.onClick = 
function() 
MW_doit_slider_Swing()
end

local AttackTxt = Txt:new(522,384+corrY,55,18, 0.8,0.8,0.8,0.8, "Attack","Arial",22)

local ReleaseTxt = Txt:new(605,384+corrY,55,18, 0.8,0.8,0.8,0.8, "Release","Arial",22)

local VelocityTxt = Txt:new(691,384+corrY,55,18, 0.8,0.8,0.8,0.8, "Velocity","Arial",22)

local ModeTxt = Txt:new(775,384+corrY,55,18, 0.8,0.8,0.8,0.8, "Mode","Arial",22)

local LevelsTxt = Txt:new(850,384+corrY,55,18, 0.8,0.8,0.8,0.8, "Levels","Arial",22)

local ViewMode = CheckBox_Show:new(970,380+corrY,55,18,  0.28,0.4,0.7,0.8, "","Arial",16,  1,
                              { "View All", "Original", "Filtered" } )
ViewMode.onClick = 
function() 
   if Wave.State then Wave:Redraw() end 
end



local EnvMode = CheckBox:new(767,410+corrY,70,18,  0.28,0.4,0.7,0.8, "","Arial",16,  InvOnByDefault,
                              { "Invert on", "Invert off" } )
EnvMode.onClick = 
function() 
end

local OffBeatP = CheckBox:new(767,430+corrY,70,18,  0.28,0.4,0.7,0.8, "","Arial",16,  2,
                              { "Shift on", "Shift off" } )
OffBeatP.onClick = 
function() 
DrawGridGuides()
Gate_on2 = 1
end

local AttMode = CheckBox_simple:new(498,450+corrY,94,18, 0.419,0.281,0.716,0.8, "","Arial",16,  1,
                              { "Fixed", "By Velocity", "By Vel Inv."} )
AttMode.onClick = 
function() 
end

local AttSoft = CheckBox_simple:new(498,430+corrY,94,18, 0.419,0.281,0.716,0.8, "","Arial",16,  1,
                              { "Normal", "Soft"} )
AttSoft.onClick = 
function() 
end

-----------------------------------
--- CheckBox_TB -------------------
-----------------------------------
local CheckBox_TB = {ViewMode, Guides, EnvMode, OffBeatP, AttMode, AttSoft}
local CheckBoxItem_TB = {ItemEnvMode}
local Slider_TB_Trigger = {Gate_VeloScale, VeloMode, AttackTxt, ReleaseTxt, VelocityTxt, ModeTxt, LevelsTxt}

----------------------------------------

local Slider_TB = {HP_Freq,LP_Freq,Fltr_Gain, Gate_Thresh,Gate_Sensitivity,Gate_Retrig,Gate_ReducePoints,Offset_Sld,Project, HBiasSlider, Floor_State}

local Sliders_Grid_TB = {Grid1_Btn, Grid2_Btn, Grid4_Btn, Grid8_Btn, Grid16_Btn, Grid32_Btn, Grid64_Btn, GridT_Btn}

local Slider_Swing_TB = {Swing_Sld}

local XFade_TB = {XFade_Sld}
local XFade_TB_Off = {XFade_Sld_Off}

local SliderGate_TB = {Floor_Sld, Shape_Sld, Attack_Sld, BiasThr_Sld}
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Gate  --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Gate_Gl:Apply_toFiltered()
      -------------------------------------------------
      self.State_Points = {}  -- State_Points table 
      -------------------------------------------------
      -- GetSet parameters ----------------------------
      -------------------------------------------------
      -- Threshold, Sensitivity ----------
      local gain_fltr  = 10^(Fltr_Gain.form_val/20)      -- Gain from Fltr_Gain slider(need for scaling gate Thresh!)
      local Thresh     = 10^(Gate_Thresh.form_val/20)/gain_fltr -- Threshold regard gain_fltr
              Thresh     = Thresh / (0.5/ block_size)      -- Threshold regard fft_real scale and gain_fltr
      local Sensitivity  = 10^(Gate_Sensitivity.form_val/20) -- Gate "Sensitivity", diff between - fast and slow envelopes(in dB)
      -- Attack, Release Time -----------
      -- Эти параметры нужно либо выносить в доп. настройки, либо подбирать тщательнее...
      local attTime1  = 0.001                            -- Env1 attack(sec)
      local attTime2  = 0.007                            -- Env2 attack(sec)
      local relTime1  = 0.010                            -- Env1 release(sec)
      local relTime2  = 0.015                            -- Env2 release(sec)
      -----------------------------------
      -- Init counters etc --------------
      ----------------------------------- 
      local retrig_smpls   = floor(Gate_Retrig.form_val/1000*srate)  -- Retrig slider to samples
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
       for i = 1, Wave.selSamples, 1 do
           local input = abs(Wave.out_buf[i]) -- abs sample value(abs envelope)
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
            else envOut2 = envOut1; retrig = retrig+1 -- урав. огибающие,пока триггер неактивен
           end
           -------------------------------------------------------------
           -- Get samples(for velocity) --------------------------------
           -------------------------------------------------------------
           if Trig then
              if smpl_cnt<=det_velo_smpls then
                 rms_sum   = rms_sum + input*input  -- get  rms_sum   for note-velo
                 peak_smpl = max(peak_smpl, input)  -- find peak_smpl for note-velo
                 smpl_cnt  = smpl_cnt+1 
                 ----------------------------     
                 else 
                      Trig = false -- reset Trig state !!!
                      -----------------------
                      local RMS  = sqrt(rms_sum/det_velo_smpls)  -- calculate RMS
                      --- Trigg point -------
                      self.State_Points[st_cnt]   = i - det_velo_smpls  -- Time point(in Samples!) 
                      self.State_Points[st_cnt+1] = {RMS, peak_smpl}    -- RMS, Peak values
                      --------
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
    if minRMS == maxRMS then minRMS = 0 end -- если только одна точка
    self.minRMS, self.minPeak = minRMS, minPeak   -- minRMS, minPeak for scaling MIDI velo
    self.maxRMS, self.maxPeak = maxRMS, maxPeak   -- maxRMS, maxPeak for scaling MIDI velo
    -----------------------------
    Gate_ReducePoints.cur_max = #self.State_Points/2 -- set Gate_ReducePoints slider m factor
    Gate_Gl:normalizeState_TB() -- нормализация таблицы(0...1)
    Gate_Gl:Reduce_Points()     -- Reduce Points
    -----------------------------
    collectgarbage() -- collectgarbage(подметает память) 
  -------------------------------
end

----------------------------------------------------------------------
---  Gate - Normalize points table  ----------------------------------
----------------------------------------------------------------------
function Gate_Gl:normalizeState_TB()
    local scaleRMS  = 1/(self.maxRMS-self.minRMS) 
    local scalePeak = 1/(self.maxPeak-self.minPeak) 
    ---------------------------------
    for i=2, #self.State_Points, 2 do -- Отсчет с 2(чтобы не писать везде table[i+1])!!!
        self.State_Points[i][1] = (self.State_Points[i][1] - self.minRMS)*scaleRMS
        self.State_Points[i][2] = (self.State_Points[i][2] - self.minPeak)*scalePeak
    end
    ---------------------------------
    self.minRMS, self.minPeak = 0, 0 -- норм мин
    self.maxRMS, self.maxPeak = 1, 1 -- норм макс
end


----------------------------------------------------------------------
---  Gate - Reduce trig points  --------------------------------------
----------------------------------------------------------------------
function Gate_Gl:Reduce_Points() -- Надо допилить!!!
    local mode = VeloMode.norm_val
    local tmp_tb = {} -- временная таблица для сортировки и поиска нужного значения
    ---------------------------------
    for i=2, #self.State_Points, 2 do -- Отсчет с 2(чтобы не писать везде table[i+1])!!!
        tmp_tb[i/2] = self.State_Points[i][mode] -- mode - учитываются текущие настройки
    end
    ---------------------------------
    table.sort(tmp_tb) -- сортировка, default, от меньшего к большему
    ---------------------------------
    local pointN = ceil((1-Gate_ReducePoints.norm_val) * #tmp_tb)  -- здесь form_val еще не определено, поэтому так!
    local reduce_val = 0
    if #tmp_tb>0 and pointN>0 then reduce_val = tmp_tb[pointN] end -- искомое значение(либо 0)
    ---------------------------------
    
 self.Res_Points = {}

-----------------------Last point of last Item------------------------------------
  local s_start, s_end = r.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
  local items = reaper.CountSelectedMediaItems(0)
   local itemz = reaper.GetSelectedMediaItem(0, 0)
    p0sition_first    = reaper.GetMediaItemInfo_Value(itemz, "D_POSITION")
  for i=items-1, items-1 do
   local item = reaper.GetSelectedMediaItem(0, i)
    take        = reaper.GetActiveTake(item)
    p0sition    = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    l3ngth = (reaper.GetMediaItemInfo_Value(item, "D_LENGTH")+p0sition-p0sition_first)*srate
      if l3ngth< s_end*srate then l3ngth = (s_end-s_start)*srate end
      if take then
          rateIt = r.GetMediaItemTakeInfo_Value(take,'D_PLAYRATE');
      end  
          table.insert(self.State_Points, l3ngth) 
          table.insert(self.State_Points, {0, 0})
  end
--------------------------------------------------------------------------------------

    for i=1, #self.State_Points, 2 do
       -- В результирующую таблицу копируются значения, входящие в диапазон --
       if self.State_Points[i+1][mode]>= reduce_val then
         local p = #self.Res_Points+1
         self.Res_Points[p]   = self.State_Points[i]+(Offset_Sld.form_val/1000*srate)
         self.Res_Points[p+1] = {self.State_Points[i+1][1], self.State_Points[i+1][2]}
       
        end
    end 
 end     
-------------------------------------------------------------------------------
------------------------------View "Grid by" Lines------------------------------
-------------------------------------------------------------------------------

local Grid_Points_r

function DrawGridGuides()

local lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')
     
     local item =  r.BR_GetMediaItemByGUID( 0, lastitem )
                if item then 

---------------------------SET NEWGRID-------------------------------------

 Grid_Points_r ={}
 Grid_Points = {}
local p = 0
local b = 0

if loop_start == nil then loop_start = 0 end
if loop_end == nil then loop_end = 0 end
if srate == nil then return end

if OffBeatP.norm_val == 1 then
   local _, offbeat_division, _, _ = r.GetSetProjectGrid(0,false)
  if tempo_corr == nil then tempo_corr = 1 end
  offbeat = offbeat_division*tempo_corr
    else
  offbeat = 0
end

local blueline = loop_start-offbeat 
   while (blueline <= loop_end) do

function beatc(beatpos)
   local retval, measures, cml, fullbeats, cdenom = r.TimeMap2_timeToBeats(0, beatpos)
   local _, division, _, _ = r.GetSetProjectGrid(0,false)
   beatpos = r.TimeMap2_beatsToTime(0, fullbeats +(division*4))
   return beatpos
end
blueline = beatc(blueline)
    
    p = p + 1
    Grid_Points[p] = floor(blueline*srate)+(Offset_Sld.form_val/1000*srate)
            table.insert(Grid_Points, (loop_start*srate)+(Offset_Sld.form_val/1000*srate))           -- First Grid Point
    
        b = b + 1
        Grid_Points_r[b] = floor((blueline - loop_start)*srate)+(Offset_Sld.form_val/1000*srate)
      --      table.insert(Grid_Points_r, ((loop_start-p0sition)*srate)+(Offset_Sld.form_val/1000*srate))           -- First Grid Point Blue Marker
   end 

table.sort(Grid_Points)
table.sort(Grid_Points_r)

 end 

end

-----------------------------------------------------------------------
---  Gate - Draw Gate Lines  -------------------------------------------
-----------------------------------------------------------------------
function Gate_Gl:draw_Lines()
  --if not self.Res_Points or #self.Res_Points==0 then return end -- return if no lines
  if not self.Res_Points then return end -- return if no lines
    --------------------------------------------------------
    -- Set values ------------------------------------------
    --------------------------------------------------------
    local mode = VeloMode.norm_val
    local offset = Wave.h * Gate_VeloScale.norm_val
    self.scale = Gate_VeloScale.norm_val2 - Gate_VeloScale.norm_val
    -- Pos, X, Y scale in gfx  ---------
    self.start_smpl = Wave.Pos/Wave.X_scale    -- Стартовая позиция отрисовки в семплах!
    self.Xsc = Wave.X_scale * Wave.Zoom * Z_w  -- x scale(regard zoom) for trigg lines
    self.Yop = Wave.y + Wave.h - offset        -- y start wave coord for velo points
    self.Ysc = Wave.h * self.scale             -- y scale for velo points 
    --------------------------------------------------------
 
 if (Guides.norm_val == 1) then 
   
    -- Draw, capture trig lines ----------------------------
    --------------------------------------------------------
    gfx.set(0.9, 0.9, 0, 0.7) -- gate line, point color -- цвет маркеров транзиентов
    ----------------------------
   
    for i=1, #self.Res_Points, 2 do
        local line_x = Wave.x + (self.Res_Points[i] - self.start_smpl) * self.Xsc  -- line x coord
        local velo_y = self.Yop -  self.Res_Points[i+1][mode] * self.Ysc           -- velo y coord    
   
    ------------------------
        -- draw line, velo -----
        ------------------------
        if line_x>=Wave.x and line_x<=Wave.x+Wave.w and i<#self.Res_Points-1 then -- Verify line range
           gfx.line(line_x, Wave.y, line_x, Wave.y+Wave.h-1)  -- Draw Trig Line
           

           gfx.circle(line_x, velo_y, 3,1,1)             -- Draw Velocity point

        end
        
            ------------------------
            -- Get mouse -----------
            ------------------------
            if not self.cap_ln and abs(line_x-gfx.mouse_x)< (10*Z_w) then -- здесь 10*Z_w - величина окна захвата маркера.
               if Wave:mouseDown() or Wave:mouseR_Down() then self.cap_ln = i end
            end
        end
------------------------------------------------------------------------------------------------------------

 else       

gfx.set(0, 0.7, 0.7, 0.7) -- gate line, point color -- цвет маркеров при отображении сетки

local Grid_Points_r = Grid_Points_r or {};     
local _, division, swingmode, swingamt = r.GetSetProjectGrid(0, 0)
local lnt_corr = (loop_length/tempo_corr)/8
   for i=1, #Grid_Points_r  do

         sw_shift = swingamt*(1-abs(division-1))
         if IsEven(i) == false and swingmode == 1 then 
         sw_shift = (sw_shift*128*Wave.Zoom*Z_w)/lnt_corr
         else
         sw_shift = 0
         end

         if 0.00007 > self.Xsc*division then self.Xsc = 0.00007/division end
         OffsSldCorrG = 0.5/1000*srate
         local line_x  = Wave.x+sw_shift + (Grid_Points_r[i] - self.start_smpl+OffsSldCorrG) * self.Xsc  -- line x coord

         --------------------
         -- draw line 8 -----
         ----------------------
       
         if line_x>=Wave.x and line_x<=Wave.x+Wave.w then -- Verify line range
            gfx.line(line_x, Wave.y, line_x, Wave.y+Wave.h-1)  -- Draw Trig Line
         end

          ------------------------
          -- Get mouse -----------
          ------------------------
          if not self.cap_ln and abs(line_x-gfx.mouse_x)<10 then 
             if Wave:mouseDown() or Wave:mouseR_Down() then self.cap_ln = i end
          end
      end  
end   
    --------------------------------------------------------
    -- Operations with captured lines(if exist) ------------
    --------------------------------------------------------
    Gate_Gl:manual_Correction()
    -- Update captured state if mouse released -------------
    if self.cap_ln and Wave:mouseUp() then self.cap_ln = false  
    end     
end
----------------------------------------------------------------------------------------------------------------------

function Gate_Gl:draw_Ruler()
  --if not self.Res_Points or #self.Res_Points==0 then return end -- return if no lines
  if not self.Res_Points then return end -- return if no lines
    --------------------------------------------------------
    -- Set values ------------------------------------------
    --------------------------------------------------------
    -- Pos, X, Y scale in gfx  ---------
    self.start_smpl = Wave.Pos/Wave.X_scale    -- Стартовая позиция отрисовки в семплах!
    self.Xsc = Wave.X_scale * Wave.Zoom * Z_w  -- x scale(regard zoom) for trigg lines
    --------------------------------------------------------
  
    -- Draw Project Grid lines ("Ruler") ----------------------------
-------------------------------------------------------------------------------------------------------------

local Grid_Points_Ruler = Grid_Points_r or {};     
local _, division, swingmode, swingamt = r.GetSetProjectGrid(0, 0)
local lnt_corr = (loop_length/tempo_corr)/8
local ruler_recolor, p_corr = 0, 1

 for i=1, #Grid_Points_Ruler  do

         sw_shift = swingamt*(1-abs(division-1))
         if IsEven(i) == false and swingmode == 1 then 
            sw_shift = (sw_shift*128*Wave.Zoom*Z_w)/lnt_corr
              else
            sw_shift = 0
         end

         if 0.00007 > self.Xsc*division then self.Xsc = 0.00007/division; ruler_recolor = 1 end
         if OffsSldCorr == nil then OffsSldCorr = Offset_Sld.form_val/1000*srate end
         local line_x  = Wave.x+sw_shift + (Grid_Points_Ruler[i] - self.start_smpl-OffsSldCorr) * self.Xsc  -- line x coord

         --------------------
         -- draw line -----
         ----------------------      
         if line_x>=Wave.x and line_x<=Wave.x+Wave.w then -- Verify line range

             if ruler_recolor == 0 then
                 gfx.set(0, 0, 0, 0.8) -- ruler black background
                 p_corr = 1
               else
                 gfx.set(0.1, 1, 0.1, 0.4) -- ruler green background ("grid too small")
                 p_corr = 2
             end

            gfx.line(line_x-p_corr, (Wave.y*1.17), line_x-p_corr, Wave.y-2+(Wave.h/300))  -- Draw Trig Line Left
            gfx.line(line_x, (Wave.y*1.18), line_x, Wave.y-2+(Wave.h/300))  -- Draw Trig Line Center
            gfx.line(line_x+p_corr, (Wave.y*1.17), line_x+p_corr, Wave.y-2+(Wave.h/300))  -- Draw Trig Line Right

            gfx.set(0.1, 1, 0.1, 1) -- ruler green short line, point color -- цвет линий сетки проекта
            gfx.line(line_x, (Wave.y*1.17), line_x, Wave.y-1+(Wave.h/300))  -- Draw Trig Line

        end

   end  
end

--------------------------------------------------------------------------------
-- Gate -  manual_Correction ---------------------------------------------------
--------------------------------------------------------------------------------
function Gate_Gl:manual_Correction()
    -- Change Velo, Move, Del Line ---------------
    if self.cap_ln and (Guides.norm_val == 1) then
        -- Change Velo ---------------------------
        if Ctrl then
            local curs_x = Wave.x + (self.Res_Points[self.cap_ln] - self.start_smpl) * self.Xsc  -- x coord
            local curs_y = min(max(gfx.mouse_y, Wave.y), Wave.y+Wave.h)                            -- y coord
            gfx.set(1, 1, 1, 0.8) -- cursor color -- цвет курсора
            gfx.line(curs_x-12, curs_y, curs_x+12, curs_y) -- cursor line
            gfx.line(curs_x, curs_y-12, curs_x, curs_y+12) -- cursor line
            gfx.circle(curs_x, curs_y, 3, 0, 1)            -- cursor point
            --------------------
            local newVelo = (self.Yop - curs_y)/(Wave.h*self.scale) -- velo from mouse y pos
            newVelo   = min(max(newVelo,0),1)
            --------------------
            self.Res_Points[self.cap_ln+1] = {newVelo, newVelo}   -- veloRMS, veloPeak from mouse y
            Gate_on2 = 1
        end
        -- Move Line -----------------------------
        if Shift then 
            local curs_x = min(max(gfx.mouse_x, Wave.x), Wave.x + Wave.w) -- x coord
            local curs_y = min(max(gfx.mouse_y, Wave.y), self.Yop)        -- y coord
            gfx.set(1, 1, 1, 0.8) -- cursor color -- цвет курсора
            gfx.line(curs_x-12, curs_y, curs_x+12, curs_y) -- cursor line
            gfx.line(curs_x, curs_y-12, curs_x, curs_y+12) -- cursor line
            gfx.circle(curs_x, curs_y, 3, 0, 1)            -- cursor point
            --------------------
            self.Res_Points[self.cap_ln] = self.start_smpl + (curs_x-Wave.x) / self.Xsc -- Set New Position
            Gate_on2 = 1
        end

        -- Delete Line ---------------------------
        if SButton == 0 and Wave:mouseR_Down() then gfx.x, gfx.y  = mouse_ox, mouse_oy
            if mouseR_Up_status == 1 and not Wave:mouseDown() then
               table.remove(self.Res_Points,self.cap_ln) -- Del self.cap_ln - Элементы смещаются влево!
               table.remove(self.Res_Points,self.cap_ln) -- Поэтому, опять тот же индекс(а не self.cap_ln+1)
                    mouseR_Up_status = 0
                    MouseUpX = 1
                    Gate_on2 = 1
            end
        end       
    end
    
    -- Insert Line(on mouseR_Down) -------------------------
    if SButton == 0 and Guides.norm_val == 1 and not self.cap_ln and Wave:mouseR_Down() then gfx.x, gfx.y  = mouse_ox, mouse_oy
        if mouseR_Up_status == 1 and not Wave:mouseDown() then
            local line_pos = self.start_smpl + (mouse_ox-Wave.x)/self.Xsc  -- Time point(in Samples!) from mouse_ox pos
            --------------------
            local newVelo = (self.Yop - mouse_oy)/(Wave.h*self.scale) -- velo from mouse y pos
            newVelo = min(max(newVelo,0),1)
            --------------------             disabled ---- not working w/o sorting------------
  --          table.insert(self.Res_Points, line_pos)           -- В конец таблицы
    --        table.insert(self.Res_Points, {newVelo, newVelo}) -- В конец таблицы
            --------------------
            self.cap_ln = #self.Res_Points
                    mouseR_Up_status = 0
                    MouseUpX = 1
                    Gate_on2 = 1
        end
    end 
end

------------------------------------------------------------------------------------------------------------------------
---   WAVE   -----------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

function Wave:Settings()
end


-------------------------------------------------------------------------------------------------------------

function Wave:Quantize_Slices()

end

---------------------------------------------------------------------------------------------------------

function Wave:Add_Markers()
MarkersQ_Status = 1
SliceQ_Init_Status = 0
Reset_Status = 1
Markers_Status = 1

if Markers_Status == 1 then  
--Wave:Reset_All()
end

 r.Undo_BeginBlock() 
r.PreventUIRefresh(1)


local cursorpos = r.GetCursorPosition()

 r.Undo_BeginBlock() 
r.PreventUIRefresh(1)
   -------------------------------------------
    lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')
   
    item =  r.BR_GetMediaItemByGUID( 0, lastitem )
               if item then
    
   r.SetMediaItemSelected(item, 1)
               
            r.Main_OnCommand(41844, 0)  ---Delete All Markers         
               
    if (Guides.norm_val == 1) then  --Add Markers by Transients 
    
      
         local next_startppqpos
         ----------------------------
         local points_cnt = #Gate_Gl.Res_Points
         for i= 1, points_cnt, 2 do
                                
           if i<points_cnt then next_startppqpos = (self.sel_start + Gate_Gl.Res_Points[i]/srate )
               
            end
            stmarkpos = next_startppqpos
            
            r.SetEditCurPos(stmarkpos,0,0)

            r.Main_OnCommand(41842, 0)  ---Add Marker


         ----------------------------
     end        

      --      r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVETIME1"),0)
     --       r.Main_OnCommand(40290, 0) -- Set time selection to item
            r.Main_OnCommand(41843, 0)  ---Add Marker
      --      r.Main_OnCommand(40635, 0)     -- Remove Selection
      --      r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME1"),0)

     else -- Add Markers by Grid

    local _, division, swingmode, swingamt = r.GetSetProjectGrid(0, 0)
      for i=1, #Grid_Points do

         sw_shift = swingamt*(1-abs(division-1))
         if IsEven(i) == false and swingmode == 1 then 
         sw_shift = sw_shift*tempo_corr                    
         else
         sw_shift = 0
         end
       
            r.SetEditCurPos((Grid_Points[i]/srate)+sw_shift,0,0)
        
            r.Main_OnCommand(41842, 0)  ---Add Marker
       
         ----------------------------
     end   
    end
   end 

r.SetEditCurPos(cursorpos,0,0)
 r.PreventUIRefresh(-1)
 
 Slice_Status = 1

    -------------------------------------------
    r.Undo_EndBlock("Add Markers", -1)    

end

-------------------------------------------------------------------------------------------------------------

function Wave:Quantize_Markers()

     if MarkersQ_Status == 0 then --instant Q
        Wave:Add_Markers()
        MarkersQ_Status = 1
     end

     if MarkersQ_Status == 1 then

 r.Undo_BeginBlock() 
r.PreventUIRefresh(1)
   -------------------------------------------

       _, save_project_grid, save_swing, save_swing_amt = r.GetSetProjectGrid(proj, false) -- backup current grid settings

    if save_project_grid > 0.5 then
               r.Main_OnCommand(40780, 0)  -- Set minimal Grid size (1/2)
    end

   local function Arc_GetClosestGridDivision(time_pos);
        r.PreventUIRefresh(4573);
        local st_tm, en_tm = r.GetSet_ArrangeView2(0,0,0,0);
        r.GetSet_ArrangeView2(0,1,0,0,st_tm,st_tm+.1);
        local Grid = r.SnapToGrid(0,time_pos);
        r.GetSet_ArrangeView2(0,1,0,0,st_tm,en_tm);
        r.PreventUIRefresh(-4573);
        return Grid;
    end;

--------------------Snap Markers to Grid----------------------

local i=0;

    r.Undo_BeginBlock();

if r.GetToggleCommandState(r.NamedCommandLookup('_BR_OPTIONS_SNAP_FOLLOW_GRID_VIS'), 0) == 1 then
      grid_opt = 1
  else
      grid_opt = 0
      r.Main_OnCommand(r.NamedCommandLookup('_BR_OPTIONS_SNAP_FOLLOW_GRID_VIS'), 0)
end

if r.GetToggleCommandState(1157) == 1 then
      snap = 1
  else
      snap = 0
      r.Main_OnCommand(1157, 0)
end

if r.GetToggleCommandState(40145) == 1 then
      grid = 1
  else
      grid = 0
      r.Main_OnCommand(40145, 0)
end


while(true) do;
  i=i+1;
  local item = r.GetSelectedMediaItem(0,i-1);
  if item then;

    local q_force = q_strength or 100;
  
    if item then;
        local posIt = r.GetMediaItemInfo_Value(item,"D_POSITION");
        local take = r.GetActiveTake(item); 
        if take then
            local rateIt = r.GetMediaItemTakeInfo_Value(take,'D_PLAYRATE');
            ---
            local countStrMar = r.GetTakeNumStretchMarkers(take);
            for i = 1,countStrMar do;
                local pos = ({r.GetTakeStretchMarker(take,i-1)})[2]/rateIt+posIt;
                local posGrid = Arc_GetClosestGridDivision(pos);
                if q_force < 0 then q_force = 0 elseif q_force > 100 then q_force = 100 end;
                local new_pos = (((posGrid-pos)/100*q_force)+pos)-posIt; 
                r.SetTakeStretchMarker(take,i-1,new_pos*rateIt);
            end;
        end
        r.UpdateItemInProject(item);
    end;
  else;
    break;
  end;
end;

 if  grid_opt == 0 then r.Main_OnCommand(r.NamedCommandLookup('_BR_OPTIONS_SNAP_FOLLOW_GRID_VIS'), 0) end
 if  snap == 0 then r.Main_OnCommand(1157, 0) end
 if  grid == 0 then r.Main_OnCommand(40145, 0) end

    r.Undo_EndBlock("MarkersQ",-1);

       r.GetSetProjectGrid(proj, true, save_project_grid, save_swing, save_swing_amt) -- restore saved grid settings
    
 r.PreventUIRefresh(-1)
Slice_Status = 1
MarkersQ_Status = 0
Reset_Status = 1
Markers_Init_Status = 1
    -------------------------------------------
    r.Undo_EndBlock("Quantize Markers", -1)    
 end
end

------------------------------------------------------------------------------------------------

function Wave:Reset_All()

end


--------------------------------------------------------------------------------
---  Accessor  -----------------------------------------------------------------
--------------------------------------------------------------------------------
function Wave:Create_Track_Accessor() 
    
 local item = r.GetSelectedMediaItem(0,0)
    if item then
    item_to_slice = r.BR_GetMediaItemGUID(item)
   
       r.DeleteExtState('_Slicer_', 'ItemToSlice', 0)
       r.SetExtState('_Slicer_', 'ItemToSlice', item_to_slice, 0)
       r.SetExtState('_Slicer_', 'GetItemState', 'ItemLoaded', 0)
      local tk = r.GetActiveTake(item)
      if tk then

    self.track = r.GetMediaItemTake_Track(tk)
    if self.track then self.AA = r.CreateTrackAudioAccessor(self.track)

         self.buffer   = r.new_array(block_size)-- main block-buffer
         self.buffer.clear()
         return true
    end
end
end
end

--------

function Wave:Destroy_Track_Accessor()
   
--if getitem == 0 then
    if self.AA then r.DestroyAudioAccessor(self.AA) 
       self.buffer.clear()
    end
 --end
end

--------
function Wave:Get_TimeSelection()
     r.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection

      local sel_start, sel_end = r.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
      if sel_start ~= sel_end then
          time_sel_length = sel_end - sel_start
          else
          time_sel_length = 1
      end

item_length2 = sel_end - sel_start -- check for sliders mw adaptive delay

loop_start = sel_start
loop_end = sel_end
loop_length = sel_end - sel_start
sel_len = sel_end - sel_start

-----------------------------------------------------------------------------------------------------
    -------------- 
    self.sel_start, self.sel_end, self.sel_len = sel_start,sel_end,sel_len  -- selection start, end, lenght
    return true

end



function DelTakeEnv()

       
if sel_area == 1 then

       r.PreventUIRefresh(1)
       r.Undo_BeginBlock()
       
       items = r.CountSelectedMediaItems(0)
       
       for i=0, items-1 do
       local item = r.GetSelectedMediaItem(0, i)
              if item then
                     take = r.GetActiveTake( item )
                     p0sition    = r.GetMediaItemInfo_Value(item, "D_POSITION")
                     l3ngth = r.GetMediaItemInfo_Value(item, "D_LENGTH")
                     rateIt = r.GetMediaItemTakeInfo_Value(take,'D_PLAYRATE');
                     env = r.GetTakeEnvelope( take, 0 )
                         if env then
                              loop_n_points = r.CountEnvelopePoints(env)
                              GetLoopTimeRange()
                               if start == ending then
                                 start = p0sition
                                 ending = p0sition+l3ngth
                               end
                          
                               for i = 1, loop_n_points do
                                 r.DeleteEnvelopePointRange( env, (start-p0sition)*rateIt, (ending-p0sition)*rateIt )
                               end
                         end
                end
       end
       
       r.Undo_EndBlock('Delete Points (Item)', 0)
       r.PreventUIRefresh(-1)
       r.UpdateArrange()

else

       r.PreventUIRefresh(1)
       
       r.Undo_BeginBlock()

       selItemCount = r.CountSelectedMediaItems(pProj)
       i = 0
       while i < selItemCount do
           pItem = r.GetSelectedMediaItem(pProj, i)
           pTake = r.GetMediaItemTake(pItem, 0)
         if pTake then
           itemchunk = "";
           envchunk = ""
           result, itemchunk = r.GetItemStateChunk(pItem, itemchunk, 1)
               
           envCount = r.CountTakeEnvelopes(pTake)
           e = 0
           while e < envCount do
               pEnv = r.GetTakeEnvelope(pTake, e)          
       
               result, envchunk = r.GetEnvelopeStateChunk(pEnv, envchunk, 1)
               
               x, y = string.find(itemchunk, envchunk, 0, 0)
               
               if x and y then
                   itemchunk = string.sub(itemchunk, 0, x - 1) .. string.sub(itemchunk, y , 0)
               end
               
               --r.ShowConsoleMsg(itemchunk)
                   
               e = e + 1
           end
           
           r.SetItemStateChunk(pItem, itemchunk, 1);
               
           r.UpdateItemInProject(pItem)
           
           i = i + 1
           else 
             break
         end
       end
       
       r.Undo_EndBlock("Delete selected items active take envelopes", -1)    
       r.UpdateArrange()
       r.PreventUIRefresh(-1)
end

end


-- SelectedEnvOnly = 0 -- On - process only selected envelope, Off - process all envelopes on a selected tracks.

------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
------------------------  Create Envelope ------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------
envs_status2 = 0
envs_status3 = 0
function Wave:Create_Envelope()

midi_check()
if Midi_Check == 1 then  -- If MIDI item, then PostFX Track Vol 
   TrackEnv = 1
         if NoItems == 0 then
             VolPreFX = 0
               else
             VolPreFX = VolPreFX
         end
     else 
   TrackEnv = TrackEnv
   VolPreFX = VolPreFX
end

local items = r.CountSelectedMediaItems(0)
for i=0, items-1 do
 local item = r.GetSelectedMediaItem(0, i)
  take        = r.GetActiveTake(item)
  p0sition    = r.GetMediaItemInfo_Value(item, "D_POSITION")
  p0sition2    = r.GetMediaItemInfo_Value(item, "D_POSITION")
  l3ngth = r.GetMediaItemInfo_Value(item, "D_LENGTH")

  if take then 
      rateIt = r.GetMediaItemTakeInfo_Value(take,'D_PLAYRATE');
         else
      return
  end

      if i<1 then p0sition_b = p0sition2 end -- takes into account multiple items
      ending_b = p0sition2+l3ngth
 
      if self.sel_start ~= p0sition_b or self.sel_end ~= ending_b then --if selected part of item
         sel_area = 1
          else
         sel_area = 0
      end
 
      if self.sel_start == p0sition_b then --if selection equal start of item
         sel_equal_pos = 1
          else
         sel_equal_pos = 0
      end

           if ItemEnvMode.norm_val == 1 then
               envelope    = r.GetTakeEnvelopeByName(take, "Volume") -- take envelope
                    elseif ItemEnvMode.norm_val == 2 then
               envelope    = r.GetTakeEnvelopeByName(take, "Pan") -- take envelope
                    elseif ItemEnvMode.norm_val == 3 then
               envelope    = r.GetTakeEnvelopeByName(take, "Pitch") -- take envelope
           end

       local tracks = r.CountSelectedTracks()
       for i = 0, tracks-1 do
        local  track = r.GetSelectedTrack(0, i)
        local envs = r.CountTrackEnvelopes(track)

        if envs == 0 and TrackEnv == 1 then -- if no track envelopes, adds it 
              r.TrackList_AdjustWindows(true)

              if envs_status2 == 0 then
                  if VolPreFX == 1 then
                    r.Main_OnCommand(40050, 0) -- Active Pre-FX Vol Env --
                    envelope = r.GetTrackEnvelopeByName(track,"Volume (Pre-FX)")
                    envs_status2 = 1
                      else
                    r.Main_OnCommand(40052, 0) -- Active Vol Env --
                    envelope = r.GetTrackEnvelopeByName(track,"Volume")
                    envs_status2 = 1
                  end
              end
         else
              if TrackEnv ~= 1 then
                  envs = 1
              else
            end
        end



              if envs ~= 0  and TrackEnv == 1 then -- if envs exist
                    -----------------------------------------------------
                    if envs_status3 == 0 then
                      i_envelope_pre = r.GetTrackEnvelopeByName(track,"Volume (Pre-FX)") -- check
                      i_envelope_vol = r.GetTrackEnvelopeByName(track,"Volume")
                          if i_envelope_pre == nil and i_envelope_vol == nil then -- if no eny vol envs, skip it
                            envs_status3 = 1
                          else

                                if VolPreFX == 1 then 
                                  i_envelope = r.GetTrackEnvelopeByName(track,"Volume (Pre-FX)") -- check
                                      if i_envelope == nil then -- if nil - create and focus
                                          r.Main_OnCommand(40050, 0) -- Active Pre-FX Vol Env --
                                          envelope = r.GetTrackEnvelopeByName(track,"Volume (Pre-FX)")
                                          else -- if exist - focus
                                          envelope = r.GetTrackEnvelopeByName(track,"Volume (Pre-FX)")      
                                      end
                                  envs_status3 = 1
                                    else
                                  i_envelope = r.GetTrackEnvelopeByName(track,"Volume")
                                      if i_envelope == nil then 
                                          r.Main_OnCommand(40052, 0) -- Active Vol Env --
                                          envelope = r.GetTrackEnvelopeByName(track,"Volume")
                                          else
                                          envelope = r.GetTrackEnvelopeByName(track,"Volume")
                                      end
                                  envs_status3 = 1
                                end

                          end      
                    end
                  -----------------------------------------------------
               end



  local envs_status = 1

  if not r.GetSelectedEnvelope(0) then --if no selected envelopes, change status for select first one
      envs_status = 0
  end


for j = 0, envs-1 do

if TrackEnv == 1 then -- track envelope

if envs_status == 0 then
     TrackEnvelope = r.GetTrackEnvelope( track, j ) -- all envelopes
--     envs_status = 1
else
     TrackEnvelope = r.GetTrackEnvelope( track, j ) -- all envelopes
     if SelectedEnvOnly == 1 then
         TrackEnvelope = r.GetSelectedEnvelope(0) -- only selected envelopes
     end
end

      if   TrackEnvelope then    
               _, EnvName = r.GetEnvelopeName(TrackEnvelope)
               envelope = r.GetTrackEnvelopeByName(track, EnvName)
                  if envs_status == 0 then
                        r.SetCursorContext(2, envelope) -- select the envelope 
                       envs_status = 1
                  end
      end



     p0sition = 0
     rateIt = 1

end

    local _, division, swingmode, swingamt = r.GetSetProjectGrid(0, 0)
    tempo_corr2 = (r.Master_GetTempo()/120)
    aatempo_corr2 = (math.log(r.Master_GetTempo()/120))*1.45

    if r.Master_GetTempo() >= 120 then
       tempo_corr3 = tempo_corr2
         else
       tempo_corr3 = tempo_corr
    end

      local shape, tens, sel, nosort = 5, CurveVal, 1, 1
      if CurveVal == 1 then tens = 0 else tens = CurveVal end -- resets CurveVal when rectangle
      local PreAttack = 0.004
      OneSpl = 1/srate

  --- Del old points in sel range --
if envelope then
   r.DeleteEnvelopePointRange( envelope, (self.sel_start-p0sition)*rateIt, (self.sel_start + self.sel_len+OneSpl)*rateIt)
end

if envelope and self.sel_start then

if ItemEnvMode.norm_val == 3 then EnvGainSld = EnvGainSld_p end -- pitch mode 
if ItemEnvMode.norm_val == 3 then FloorVal = FloorVal_p end -- pitch mode
if (EnvName == "Pan" or EnvName == "Pan (Pre-FX)" or ItemEnvMode.norm_val == 2) then EnvGainSld = 1 else EnvGainSld = EnvGainSld end
if not (EnvName == "Pan" or EnvName == "Pan (Pre-FX)" or ItemEnvMode.norm_val == 2) then PanWidth3 = 1 else PanWidth3 = PanWidth3 end

    Gain =  (FloorVal) -- Env_Gain.scal_val
   if ((EnvName == "Pan" or EnvName == "Pan (Pre-FX)") or ItemEnvMode.norm_val == 2) then Gain = (Gain*0.96)-0.24 else Gain = Gain end  -- gain correction on the pan envelope
          if ItemEnvMode.norm_val == 3 then -- gain correction on the pitch envelope
                 Gain = ((Gain*0.96)-0.24)*(Pitch_Range)
                 EnvGainSld = EnvGainSld*(Pitch_Range/4)
                 EnvGainSld2 = EnvGainSld2*(Pitch_Range/4)
              else
                 Gain = Gain
                 EnvGainSld = EnvGainSld           
                 EnvGainSld2 = EnvGainSld2
           end

          EnvGcorr =  (EnvGainSld2/0.8)*((exp(Gain)-1)*(EnvGainSld+1.11)) -- gain boost correction
    ----------------------------------------------------
    local mode = r.GetEnvelopeScalingMode(envelope)
    if  EnvName == "Volume (Pre-FX)" or EnvName == "Volume" or (ItemEnvMode.norm_val == 1 and TrackEnv == 0) then EnvGcorr = EnvGcorr else EnvGcorr = Gain*3.2 end -- boost correction off if no vol envelope
          Gain = r.ScaleToEnvelopeMode(mode,  Gain+EnvGcorr)
          if EnvGainSld < 1 and Floor_State.norm_val ~= 1 then EnvGainSld = 1 end -- limit gain slider when rise or fall
          G_1 = max(Gain, r.ScaleToEnvelopeMode(mode, EnvGainSld))     -- 1 - gain
          ZeroGain = r.ScaleToEnvelopeMode(mode, 1)
          _, ZeroGain2, _, _, _ = r.Envelope_Evaluate(envelope, self.sel_end+(2/srate), 0, 0) -- initial envelope gain (selection start)
          _, ZeroGain, _, _, _ = r.Envelope_Evaluate(envelope, self.sel_start-OneSpl, 0, 0) -- initial envelope gain (selection end)
          FlCmp = ZeroGain-G_1 -- rise/fall floor compensation when gain sld

         if EnvMode.norm_val == 1 then  --inverted
            Gx1 = G_1
            Gx2 = Gain
         elseif EnvMode.norm_val == 2 then
            Gx1 = Gain
            Gx2 = G_1
         end

 if ItemEnvMode.norm_val == 3 then Gx1 = math_round(Gx1,0) end -- if Pitch, rounding to half tone
 if ItemEnvMode.norm_val == 3 then Gx2 = math_round(Gx2,0) end

    ppqp0s_Status = 0

if (Guides.norm_val == 1) then  ----------------- Add Markers by Transients -----------------------------------

    local mode = VeloMode.norm_val
    local velo_scale  = Gate_VeloScale.form_val2 - Gate_VeloScale.form_val
    local velo_offset = Gate_VeloScale.form_val

    local points_cnt = #Gate_Gl.Res_Points
      for i=1, points_cnt, 2 do

              if Gate_Gl.Res_Points[i] then 
                 if startppqp0s then next_startppqp0s3 = startppqp0s end
                 if i<points_cnt then startppqp0s = (self.sel_start + Gate_Gl.Res_Points[i]/srate )*rateIt end
                 if i<points_cnt-2 then next_startppqp0s = (self.sel_start + Gate_Gl.Res_Points[i+2]/srate )*rateIt end
                 vel = floor(velo_offset + Gate_Gl.Res_Points[i+1][mode] * velo_scale)

-----------------------Limiters for Selected Area
if startppqp0s <= (self.sel_start+(1/srate))*rateIt then startppqp0s = (self.sel_start+(1/srate))*rateIt end

if startppqp0s >= (self.sel_end-(1/srate))*rateIt then startppqp0s = (self.sel_end-(1/srate))*rateIt end
-----------------------------------------------

       if Floor_State.norm_val == 1 or ItemEnvMode.norm_val == 3 then --Flat if flat or pitch
               move2 = Gx1/PanWidth3
               move = Gx1/PanWidth3
               move3 = Gx2/PanWidth3
               move2_last = move2
            elseif Floor_State.norm_val == 2 then --Rise
                if EnvMode.norm_val == 1 then -- inverse
                  if  ItemEnvMode.norm_val == 2 or (EnvName == "Pan" or EnvName == "Pan (Pre-FX)") then -- Pan
                      move2 = (i/points_cnt)/PanWidth
                      move = ((i+1)/points_cnt)/PanWidth
                      move3 = (1-((i+1)/points_cnt)-1)/PanWidth
                   else
                      move2 = Gx1
                      move = Gx1
                      move3 = min(((i/points_cnt)*(ZeroGain)), Gx1)-FlCmp -- -- move up inv
                      move2_last = move2
                   end

                        else

                  if  ItemEnvMode.norm_val == 2 or (EnvName == "Pan" or EnvName == "Pan (Pre-FX)") then -- Pan 
                      move3 = (i/points_cnt)/PanWidth
                      move2 = (1-(i/points_cnt)-1)/PanWidth
                      move = (1-((i+1)/points_cnt)-1)/PanWidth
                  else
                      move3 = Gx2
                      move2 = min((((i-2)/points_cnt)*(ZeroGain)),Gx2)-FlCmp  -- move up
                      move = min(((i/points_cnt)*(ZeroGain)),Gx2)-FlCmp  -- move up
                      move2_last = ZeroGain-FlCmp
                  end
               end
            elseif Floor_State.norm_val == 3 then -- Fall
                if EnvMode.norm_val == 1 then -- inverse
                  if  ItemEnvMode.norm_val == 2 or (EnvName == "Pan" or EnvName == "Pan (Pre-FX)") then -- Pan 
                      move2 = (1-(i/points_cnt))/PanWidth
                      move =  (1-((i+1)/points_cnt))/PanWidth
                      move3 = (((i+1)/points_cnt)-1)/PanWidth
                   else
                      move2 = Gx1
                      move = Gx1
                      move3 = min((Gx1)-((i/points_cnt)*(ZeroGain)), Gx1)  -- move down inv
                      move2_last = move2
                   end
                         else
                  if  ItemEnvMode.norm_val == 2 or (EnvName == "Pan" or EnvName == "Pan (Pre-FX)") then -- Pan          
                      move3 = (1-(i/points_cnt))/PanWidth
                      move2 = ((i/points_cnt)-1)/PanWidth
                      move = (((i+1)/points_cnt)-1)/PanWidth
                   else
                      move3 = Gx2
                      move2 = min((Gx2)-(((i-2)/points_cnt)*(ZeroGain)),Gx2) -- move down
                      move = min((Gx2)-((i/points_cnt)*(ZeroGain)),Gx2) -- move down
                      move2_last = 0-FlCmp
                   end
               end
        end


          if TrackEnv == 1 then
               posz = self.sel_end
               posn = self.sel_start
               pos_n = self.sel_start
               else
               posz = ((p0sition+l3ngth)*rateIt)*tempo_corr2 -- (p0sition+l3ngth)*rateIt
               posn = 0
                  if sel_area == 1 then
                     pos_n = (p0sition+(self.sel_start-p0sition))*rateIt
                       else
                     pos_n = p0sition
                  end
          end


        if i ==1 and startppqp0s > pos_n+0.004 then -- adaptive first point (gone if too close to start)
           ppqp0s_Status = 1
        end

if  next_startppqp0s3 then -- 

     if TrackEnv == 1 then

             if i<=3 and ppqp0s_Status == 1 then -- first point -- and i > points_cnt-1 and startppqp0s3-PreAttack > (self.sel_start)-0.001*rateIt
                              r.InsertEnvelopePoint(envelope, max(min((next_startppqp0s3)-(p0sition*rateIt)-PreAttack, posz), posn-OneSpl),  move2, shape, tens, sel, nosort) --pre-attack
             elseif i>3 and startppqp0s-PreAttack > (self.sel_start)-0.001*rateIt then -- other points
                              r.InsertEnvelopePoint(envelope, max(min((next_startppqp0s3)-(p0sition*rateIt)-PreAttack, posz), posn-OneSpl),  move2, shape, tens, sel, nosort) --pre-attack
             end

       else -- item env

             if i<=3 and ppqp0s_Status == 1 then -- first point -- and i > points_cnt-1 and startppqp0s3-PreAttack > (self.sel_start)-0.001*rateIt
                       --       r.InsertEnvelopePoint(envelope, max(min((next_startppqp0s3)-(p0sition*rateIt)-PreAttack, posz), posn-OneSpl),  move2, shape, tens, sel, nosort) --pre-attack last point
             elseif i>3 then 
                              r.InsertEnvelopePoint(envelope, max(min((next_startppqp0s3)-(p0sition*rateIt)-PreAttack, posz), posn-OneSpl),  move2, shape, tens, sel, nosort) --pre-attack
                      end

      end


                         if AttMode.norm_val == 1 then
                            aa = 0.01
                         elseif AttMode.norm_val == 2 then
                            aa = vel/2000*tempo_corr
                         elseif AttMode.norm_val == 3 then
                            vel = (vel-127)*-1 --inverse vel
                            aa = vel/2000*tempo_corr
                         end
aaa = HBiasSlider

                         if  i > 1 then 
                             ax = (startppqp0s/HBiasSlider2)-(next_startppqp0s3/HBiasSlider2)

                                   if startppqp0s-next_startppqp0s3 >= HlvLngth and (HBiasSlider ~= 1.0 or CurveVal == 1.0 ) then
                                             if startppqp0s-next_startppqp0s3 >= 7 and startppqp0s-next_startppqp0s3 < 15 then ax = ax/2 --release too long? divide him!
                                                 elseif startppqp0s-next_startppqp0s3 >= 15 and startppqp0s-next_startppqp0s3 < 31 then ax = ax/4 
                                                 elseif startppqp0s-next_startppqp0s3 >= 31 then ax = ax/8 
                                                 else ax = ax 
                                             end
                                         r.InsertEnvelopePoint(envelope, max(min((next_startppqp0s3)-(p0sition*rateIt)-(ax), posz), posn-OneSpl),  move, 0, tens, sel, nosort) -- adaptive shift -- linear shape (0)
                                   end
                         end


        if aa and (AttVal <= 29 or AttSoft.norm_val ~= 1) then
                                AttValz = AttVal*HBS_corr -- BiasSlider reduces the AttVal
                                AttValx = AttVal*(HBS_corr/2) -- BiasSlider reduces the AttVal

                      if AttMode.norm_val == 1 then

                                ab = (0.1/AttValz)*tempo_corr
                             elseif AttMode.norm_val == 2 then
                                ab = (aa/AttValx)*tempo_corr
                             elseif AttMode.norm_val == 3 then
                                ab = (aa/AttValx)*tempo_corr
                      end


                    if CurveVal ~= 1.0 then 
                       skip_point_tr = 1
                         else
                       skip_point_tr = 0
                    end


     if TrackEnv == 1 then

                  if i<=2 and startppqp0s > (self.sel_start)-ab*rateIt  and ax then -- 
                               if CurveVal ~= 1.0 then -- when attack max, attack = halved - pre-attack (rectangle shaped)
                                    r.InsertEnvelopePoint(envelope, max(min((startppqp0s)-(p0sition*rateIt)+(ab), posz), posn-OneSpl), move3, shape, tens, sel, nosort) --attack
                                  else
                                    r.InsertEnvelopePoint(envelope, max(min((next_startppqp0s3)-(p0sition*rateIt)-(ax)-PreAttack, posz), posn-OneSpl), move3, shape, tens, sel, nosort) --attack
                               end
                  elseif i>2 and i < points_cnt-skip_point_tr then -- other points
                               if CurveVal ~= 1.0 then -- when attack max, attack = halved - pre-attack (rectangle shaped)
                                   r.InsertEnvelopePoint(envelope, max(min((startppqp0s)-(p0sition*rateIt)+(ab), posz), posn-OneSpl), move3, shape, tens, sel, nosort) --attack
                                  else
                                    r.InsertEnvelopePoint(envelope, max(min((next_startppqp0s3)-(p0sition*rateIt)-(ax)-PreAttack, posz), posn-OneSpl), move3, shape, tens, sel, nosort) --attack
                               end
                  end

      else -- item env


                               if CurveVal ~= 1.0 then -- when attack max, attack = halved - pre-attack (rectangle shaped)
                                        if i < points_cnt-1 then -- if not last point
                                              r.InsertEnvelopePoint(envelope, max(min((startppqp0s)-(p0sition*rateIt)+(ab), posz), posn-OneSpl), move3, shape, tens, sel, nosort) --attack
                                        end
                                   else
                                        if i > 2 then -- if not last point
                                              r.InsertEnvelopePoint(envelope, max(min((next_startppqp0s3)-(p0sition*rateIt)-(ax)-PreAttack, posz), posn-OneSpl), move3, shape, tens, sel, nosort) --attack
                                        end
                               end
      end

     end

    if AttSoft.norm_val == 1 or CurveVal == 1.0 then

         if TrackEnv == 1 then
    
                        if i<=2 and startppqp0s > (self.sel_start)-0.001*rateIt  then -- 
                                     r.InsertEnvelopePoint(envelope, max(min((startppqp0s)-(p0sition*rateIt), posz), posn-OneSpl), move3, shape, tens, sel, nosort) -- main, transients
                        elseif i>2 and i < points_cnt-1  then -- other points
                                     r.InsertEnvelopePoint(envelope, max(min((startppqp0s)-(p0sition*rateIt), posz), posn-OneSpl), move3, shape, tens, sel, nosort)
                        end

          else -- item env
    
                      if i < points_cnt-1 then -- if not last point
                                    r.InsertEnvelopePoint(envelope, max(min((startppqp0s)-(p0sition*rateIt), posz), posn-OneSpl), move3, shape, tens, sel, nosort) -- main, transients
                      end
    
          end --TrackEnv
    
    end -- AttSoft

end

              end
      end

    else   -------------------------------- Add Markers by Grid ----------------------------------------------------------------------------

  aex = ((1/division)*1.3125)/tempo_corr
  tempo_to_binary = (math.log(r.Master_GetTempo()/120))*1.45
  HBiasSliderx = (HBiasSlider-(tempo_to_binary))/(aex)
  AddCorr = (min(HBiasSlider, 0)*-1)+0.4
            ACorr = (min(division*64, 8))/1.3
            AttVal3 = (((AttVal2)*(division*ACorr))/AddCorr)*tempo_corr 

if envelope then
  r.DeleteEnvelopePointRange( envelope, (self.sel_start), (self.sel_start + self.sel_len))
end

          if TrackEnv == 1 then
               posy = (self.sel_start-OneSpl)+self.sel_len
               posx = self.sel_start-OneSpl
               posn = self.sel_start+OneSpl
               else
                 if sel_area == 1 then
                    local rateIt2
                    if rateIt <= 1 then  rateIt2 = 1 else rateIt2 = rateIt end
                    posy = (p0sition+(self.sel_end-p0sition))*rateIt2
                    posx = p0sition*rateIt
                    posn = 0+OneSpl
                 else
                    local rateIt2
                    if rateIt <= 1 then  rateIt2 = 1 else rateIt2 = rateIt end
                    posy = ((p0sition+(self.sel_end-p0sition))*rateIt2)-OneSpl
                    posx = p0sition*rateIt
                    posn = 0+OneSpl
                 end
          end


---------Temp testing Del-------------
local rateIt2
if rateIt <= 1 then  rateIt2 = 1 else rateIt2 = rateIt end
                    
aa1 = (p0sition+(self.sel_end-p0sition))*rateIt2
aa2 = (p0sition+(l3ngth+self.sel_len))*rateIt2

---------------------------------------------


    local points_cnt2  = #Grid_Points
      for i=1, points_cnt2 do

         sw_shift2 = swingamt*division
         sw_shift = swingamt*division
             if IsEven(i) == true and swingmode == 1 then 
             sw_shift = sw_shift*tempo_corr         
             sw_shift2 = sw_shift2*tempo_corr         
               else
             sw_shift = 0
         end

         HB = ((sw_shift2)*(HBS*tempo_corr))

              if Grid_Points then 
                 if i<points_cnt2 then startppqp0s = ((posn+Grid_Points[i]/srate)+sw_shift)*rateIt end
                 if i<points_cnt2 then startppqp0s_halved = ((posn+(Grid_Points[i]+(division*srate))/srate)+sw_shift)*rateIt end

-----------------------Limiters for Selected Area
if startppqp0s <= self.sel_start*rateIt then startppqp0s = self.sel_start*rateIt end
if startppqp0s_halved <= self.sel_start*rateIt then startppqp0s_halved = self.sel_start*rateIt end

aag = (posn+self.sel_end+PreAttack)*tempo_corr3 -- Track Env End
aaf = (((p0sition+(self.sel_end-p0sition))*rateIt)*tempo_corr3)-OneSpl -- Item Env End

       if TrackEnv == 1 then --if track env
           if startppqp0s >= aag then startppqp0s = aag end
           if startppqp0s_halved >= aag then startppqp0s_halved = aag end
           else
           if startppqp0s >= aaf then startppqp0s = aaf end
           if startppqp0s_halved >= aaf then startppqp0s_halved = aaf end
       end

if i==points_cnt2 then aa3 = startppqp0s-OneSpl end
if i==points_cnt2 then aa4 = startppqp0s_halved-OneSpl end
-----------------------------------------------

        if Floor_State.norm_val == 1 or ItemEnvMode.norm_val == 3 then -- Flat if flat or pitch
               move2 = Gx1/PanWidth3
               move = Gx1/PanWidth3
               move3 = Gx2/PanWidth3
            elseif Floor_State.norm_val == 2 then --Rise
                if EnvMode.norm_val == 1 then -- inverse
                  if  ItemEnvMode.norm_val == 2 or (EnvName == "Pan" or EnvName == "Pan (Pre-FX)") then -- Pan
                      move2 = (i/points_cnt2)/PanWidth
                      move = ((i+1)/points_cnt2)/PanWidth
                      move3 = (1-((i+1)/points_cnt2)-1)/PanWidth
                   else -- Vol
                      move2 = Gx1
                      move = Gx1
                      move3 = min(((i/points_cnt2)*(ZeroGain)),Gx1)-FlCmp -- move up inv
                   end

                          else    -- non inverse Rise
  
                  if  ItemEnvMode.norm_val == 2 or (EnvName == "Pan" or EnvName == "Pan (Pre-FX)") then -- Pan 
                      move3 = (i/points_cnt2)/PanWidth
                      move2 = (1-(i/points_cnt2)-1)/PanWidth
                      move = (1-((i+1)/points_cnt2)-1)/PanWidth
                  else --Vol
                      move3 = Gx2
                      move2 = min(((i/points_cnt2)*(ZeroGain)),Gx2)-FlCmp-- move up 
                      move = min((((i+1)/points_cnt2)*(ZeroGain)),Gx2)-FlCmp -- move up -
                  end
                end
            elseif Floor_State.norm_val == 3 then --Fall
                if EnvMode.norm_val == 1 then  -- inverse
                  if  ItemEnvMode.norm_val == 2 or (EnvName == "Pan" or EnvName == "Pan (Pre-FX)") then -- Pan 
                      move2 = (1-(i/points_cnt2))/PanWidth
                      move =  (1-((i+1)/points_cnt2))/PanWidth
                      move3 = (((i+1)/points_cnt2)-1)/PanWidth
                   else -- Vol
                      move2 = Gx1
                      move = Gx1
                      move3 = min((Gx1)-((i/points_cnt2)*(ZeroGain)),Gx1) -- move down inv
                   end

                          else    -- non inverse 

                  if  ItemEnvMode.norm_val == 2 or (EnvName == "Pan" or EnvName == "Pan (Pre-FX)") then -- Pan          
                      move3 = (1-(i/points_cnt2))/PanWidth
                      move2 = ((i/points_cnt2)-1)/PanWidth
                      move = (((i+1)/points_cnt2)-1)/PanWidth
                   else -- Vol
                      move3 = Gx2 
                      move2 = min(Gx2-((i/points_cnt2)*(ZeroGain)),Gx2) --+EnvGcorr -- move down
                      move = min(Gx2-(((i+1)/points_cnt2)*(ZeroGain)),Gx2) --+EnvGcorr -- move down
                   end
                end
        end


 if TrackEnv == 1 then
       if Offset_Sld.form_val >= 0 then -- end point correction
           bnd_corr = (posn+self.sel_end)+(Offset_Sld.form_val/1000*srate)*tempo_corr3 
           else
           bnd_corr = (posn+self.sel_end)*tempo_corr3 
       end

       ad_tr = self.sel_start*2
       ad_ts = ((posn+self.sel_end)*tempo_corr3)+OneSpl 
       ad_corr = OneSpl
    else
       bnd_corr = (self.sel_end*rateIt)-(HBiasSliderx*tempo_corr3)
       ad_corr = AttVal3
       if sel_area == 1 then
          ad_tr = (p0sition+(self.sel_start-p0sition))*rateIt
          ad_ts = ((p0sition+(self.sel_end-p0sition))*rateIt)
          else
          ad_tr = p0sition*rateIt
          ad_ts = (p0sition+l3ngth)*rateIt*tempo_corr2
       end
end

      if  startppqp0s+ad_corr <= ad_ts-OneSpl then -- TrackEnv == 1 or
        skip_point_last = 0
          else
        skip_point_last = 0 -- 1
     end
     
              if i<=1 and startppqp0s-PreAttack > ad_tr  then -- first point
            --        if OffBeatP.norm_val == 2 or Guides.norm_val == 1 then 
                            r.InsertEnvelopePoint(envelope, max(min((startppqp0s)-(posx)-(PreAttack/4), (posy)*rateIt), posn),  move2, shape, 0, sel, nosort) --pre attack
              --      end
              elseif i>1 and i < points_cnt2-skip_point_last then -- other points
                    r.InsertEnvelopePoint(envelope, max(min((startppqp0s)-(posx)-PreAttack, (posy)*rateIt), posn),  move2, shape, 0, sel, nosort) --pre attack
              end


                    if OffBeatP.norm_val == 1 then 
                       skip_point = 1 -- 1
                         else
                       skip_point = 0
                    end
a0 = 0
                    if sel_area == 1 or (Floor_State.norm_val == 2 or Floor_State.norm_val == 3) then
a0 = 1
                        skip_point2 = 0 -- 1
                          else
                        skip_point2 = 0

                    end



 if bnd_corr and startppqp0s_halved-OneSpl < bnd_corr and (HBiasSlider ~= 1 or CurveVal == 1.0) then

          if i > skip_point and i < points_cnt2 then -- skip first -- and HBiasSlider ~= 1
                        if IsEven(i) == true then
                              r.InsertEnvelopePoint(envelope, max(min((startppqp0s_halved+HBiasSliderx*rateIt-(HB*tempo_corr2))-(posx), (posy)), posn),  move, shape, tens, sel, nosort) -- adaptive shift -- linear shape (0)
                                     else
                              r.InsertEnvelopePoint(envelope, max(min((startppqp0s_halved+HBiasSliderx*rateIt+(HB))-(posx), (posy)), posn),  move, shape, tens, sel, nosort) -- adaptive shift -- linear shape (0)
                        end
           end
 end
 

        if TrackEnv == 1 then
 
                             if i<=1  then -- first point  --  and startppqp0s-PreAttack > (self.sel_start*2)-AttVal3
                                    if OffBeatP.norm_val == 2 or Guides.norm_val == 1 then 
                                    if CurveVal ~= 1.0 then -- when attack max, attack = halved - pre-attack (rectangle shaped)
                                         r.InsertEnvelopePoint(envelope, max(min((startppqp0s)-(posx)+(AttVal3), posy), posn), move3, shape, tens, sel, nosort) -- attack
                                        else
                                           if IsEven(i) == true then
                                                      r.InsertEnvelopePoint(envelope, max(min((startppqp0s_halved+HBiasSliderx-(HB*tempo_corr2))-(posx)-(PreAttack), (posy)*rateIt), posn), move3, shape, tens, sel, nosort) -- attack max
                                                         else
                                                      r.InsertEnvelopePoint(envelope, max(min((startppqp0s_halved+HBiasSliderx+(HB))-(posx)-(PreAttack), (posy)*rateIt), posn), move3, shape, tens, sel, nosort) -- attack max
                                            end
                                    end
 
                                    end
                             elseif i>1 and i < points_cnt2 then -- other points
                                    if CurveVal ~= 1.0 then -- when attack max, attack = halved - pre-attack ()
                                         r.InsertEnvelopePoint(envelope, max(min((startppqp0s)-(posx)+(AttVal3), posy), posn), move3, shape, tens, sel, nosort) -- attack
                                        else
                                           if IsEven(i) == true then
                                                      r.InsertEnvelopePoint(envelope, max(min((startppqp0s_halved+HBiasSliderx-(HB*tempo_corr2))-(posx)-(PreAttack), (posy)*rateIt), posn), move3, shape, tens, sel, nosort) -- attack max
                                                         else
                                                      r.InsertEnvelopePoint(envelope, max(min((startppqp0s_halved+HBiasSliderx+(HB))-(posx)-(PreAttack), (posy)*rateIt), posn), move3, shape, tens, sel, nosort) -- attack max
                                            end
                                    end
                           end
  
                    if i < points_cnt2 and (AttSoft.norm_val == 1 or CurveVal == 1.0) then              
                
                             if i<=1 and startppqp0s-PreAttack > (self.sel_start*2)-PreAttack  then -- first point
                                    if OffBeatP.norm_val == 2 or Guides.norm_val == 1 then 
                                         r.InsertEnvelopePoint(envelope, max(min((startppqp0s)-(posx), posy), posn), move3, shape, tens, sel, nosort)
                                    end
                             elseif i>1  then -- other points
                                         r.InsertEnvelopePoint(envelope, max(min((startppqp0s)-(posx), posy), posn), move3, shape, tens, sel, nosort)
                           end
 
                     end  -- AttSoft.norm_val 
 
             else
 
                          if OffBeatP.norm_val == 1  then
                                  if i>1 and  i < points_cnt2-skip_point_last then --skip first
                                     if CurveVal ~= 1.0 then -- when attack max, attack = halved - pre-attack ()
                                         r.InsertEnvelopePoint(envelope, max(min((startppqp0s)-(posx)+(AttVal3), (posy)*rateIt), posn), move3, shape, tens, sel, nosort) -- attack
                                         else
                                            if IsEven(i) == true then
                                                       r.InsertEnvelopePoint(envelope, max(min((startppqp0s_halved+HBiasSliderx*rateIt-(HB*tempo_corr2))-(posx)-(PreAttack), (posy)*rateIt), posn), move3, shape, tens, sel, nosort) -- attack max
                                                          else
                                                       r.InsertEnvelopePoint(envelope, max(min((startppqp0s_halved+HBiasSliderx*rateIt+(HB))-(posx)-(PreAttack), (posy)*rateIt), posn), move3, shape, tens, sel, nosort) -- attack max
                                             end
                                     end
                                         if AttSoft.norm_val == 1 or CurveVal == 1.0 then  
                                                              r.InsertEnvelopePoint(envelope, max(min((startppqp0s)-(posx), (posy)*rateIt), posn), move3, shape, tens, sel, nosort)
                                         end  -- AttSoft.norm_val 
                                  end
                         else

                                  if i < points_cnt2-skip_point2-skip_point_last then
                                             if CurveVal ~= 1.0 then -- when attack max, attack = halved - pre-attack ()
                                                 r.InsertEnvelopePoint(envelope, max(min((startppqp0s+OneSpl)-(posx)+(AttVal3), (posy)*rateIt), posn), move3, shape, tens, sel, nosort) -- attack
                                                 else
                                                    if IsEven(i) == true then
                                                               r.InsertEnvelopePoint(envelope, max(min((startppqp0s_halved+HBiasSliderx*rateIt-(HB*tempo_corr2))-(posx)-(PreAttack), (posy)*rateIt), posn), move3, shape, tens, sel, nosort) -- attack max
                                                                  else
                                                               r.InsertEnvelopePoint(envelope, max(min((startppqp0s_halved+HBiasSliderx*rateIt+(HB))-(posx)-(PreAttack), (posy)*rateIt), posn), move3, shape, tens, sel, nosort) -- attack max
                                                     end
                                             end
         
                                         if i < points_cnt2-skip_point2-skip_point_last and (AttSoft.norm_val == 1 or CurveVal == 1.0) then  
                                                     r.InsertEnvelopePoint(envelope, max(min((startppqp0s+OneSpl)-(posx), (posy)*rateIt), posn), move3, shape, tens, sel, nosort)
                                         end  -- AttSoft.norm_val  
                                   end
                      end
        end



              end
      end
       
end   

-------------------------------------------------Start and end points ---------------------------------------------------

StartEndPointsIsOn = 1 -- all additional points on/off. 0 - Debug/testing purpose only.

ab1 = 0
ab2 = 0
ab3 = 0

if StartEndPointsIsOn == 1 then

          if TrackEnv == 1 then
               posl = (self.sel_end)
               posf = (self.sel_start)+OneSpl 
                 else
                   if sel_area == 0 then
                       posl = ((l3ngth)*rateIt)-(OneSpl*4)
                       posf = (0)+OneSpl
                        else
                       posl = ((l3ngth)*rateIt)-(OneSpl*4)
                       posf = ((self.sel_start-p0sition)*rateIt)+(OneSpl*2)
                   end
          end

         if EnvMode.norm_val == 1 then --inverted
                 Gx3 = Gx1
                 Gx4 = Gx1
         elseif EnvMode.norm_val == 2 then 
ab1 = 1
            if OffBeatP.norm_val == 2 or Guides.norm_val == 1 then
ab2 = 1
                 Gx3 = Gx2
                     else
ab3 = 1
                 Gx3 = Gx1
            end
                 Gx4 = Gx1
         end
ab4 = EnvMode.norm_val
ab5 = OffBeatP.norm_val

if EnvMode.norm_val == 1 and OffBeatP.norm_val == 2 and EnvName == "Pan" then Gx3 = Gx2 end
--if EnvMode.norm_val == 1 and OffBeatP.norm_val == 1 then Gx3 = Gx1 end
if EnvMode.norm_val == 1 and OffBeatP.norm_val ~= 1 and TrackEnv == 1 then Gx3 = Gx2 end
if EnvMode.norm_val == 2 and OffBeatP.norm_val == 2 and TrackEnv == 0 then Gx3 = Gx2 end
if TrackEnv == 0 and OffBeatP.norm_val == 1 and Floor_State.norm_val == 3 then Gx3 = Gx2 end

if ItemEnvMode.norm_val == 1 or OffBeatP.norm_val ~= 2 then
   PanWidth2 = 1
     else
   PanWidth2 = PanWidth
end

a1 = 0
a2 = 0
a3 = 0
a4 = 0
a5 = 0
a6 = 0
a7 = 0
a8 = 0
a9 = 0
a10 = 0
a11 = 0
a12 = 0
a13 = 0
a13a = 0
a14 = 0
a14a = 0
a14b = 0
a15 = 0
a16 = 0
a17 = 0
a18 = 0
a19 = 0

    if TrackEnv == 1 then
a1 = 1
        r.InsertEnvelopePoint(envelope, (self.sel_start-(0))*rateIt, ZeroGain, shape, tens, 0, nosort) -- sel_start
        r.InsertEnvelopePoint(envelope, (self.sel_end+(0))*rateIt, ZeroGain2, shape, tens, 0, nosort) -- sel_end
         else
         if sel_area == 1 then --if selected part of item
a2 = 1
                 r.InsertEnvelopePoint(envelope, ((self.sel_start-p0sition)*rateIt)+OneSpl, ZeroGain2, shape, tens, 0, nosort) -- sel_start
    --          if EnvMode.norm_val ~= 1 then
a3 = 1
                 r.InsertEnvelopePoint(envelope, ((self.sel_end-p0sition)*rateIt)-OneSpl, Gx1, shape, tens, 0, nosort) -- sel_end_pre att
                 r.InsertEnvelopePoint(envelope, ((self.sel_end-p0sition)*rateIt)-OneSpl, ZeroGain2, shape, tens, 0, nosort) -- sel_end
  --            end
         end
     end

---------------------------------------------------Additional Firstest and Lastest points--------------------------------------------------------------------------

             if sel_area == 1 and (EnvMode.norm_val == 2 and OffBeatP.norm_val == 1) then
                  if Floor_State.norm_val ~= 3 then
a4 = 1
                      r.InsertEnvelopePoint(envelope, posf+OneSpl, Gx3/PanWidth2, 0, tens, sel, true) --first point
                  end
             end

             if sel_area == 0 and (OffBeatP.norm_val ~= 2 and EnvMode.norm_val ~=1) then
                  if not (Floor_State.norm_val == 2 and (EnvName == "Pan" or EnvName == "Pan (Pre-FX)" or ItemEnvMode.norm_val == 2)) then
a5 = 1
                     r.InsertEnvelopePoint(envelope, posf+OneSpl+OneSpl, Gx3/PanWidth2, 0, tens, sel, true) --first point -- Gx1/PanWidth2
                  end
             end

             if sel_area == 1 and (ItemEnvMode.norm_val ~= 2 and OffBeatP.norm_val ~= 2) then
                  if not (Floor_State.norm_val == 2 and (EnvName == "Pan" or EnvName == "Pan (Pre-FX)" or ItemEnvMode.norm_val == 2)) then
a6 = 1
                     r.InsertEnvelopePoint(envelope, posf+OneSpl, Gx3/PanWidth2, 0, tens, sel, true) --first point sel, inv and shift --Gx1/PanWidth2
                  end
             end
      
             if Floor_State.norm_val == 3 and (ItemEnvMode.norm_val == 2 and OffBeatP.norm_val ~= 2) then  --Fall and Pan
a7 = 1
                     r.InsertEnvelopePoint(envelope, posf+OneSpl, Gx1/PanWidth, shape, tens, sel, true) --first point
             end
      
             if Floor_State.norm_val == 2 and (ItemEnvMode.norm_val == 2 and OffBeatP.norm_val ~= 2) then --Rise and Pan
a8 = 1
                     r.InsertEnvelopePoint(envelope, posf+OneSpl, 0, shape, tens, sel, true) --first point
             end
      
      
             if Guides.norm_val == 1 then -- adaptive first transient (Transients)

                          if Floor_State.norm_val ~= 3 and ItemEnvMode.norm_val ~= 2 and not (EnvName == "Pan" or EnvName == "Pan (Pre-FX)") then  -- if not Fall and not Pan
                                         if ( ppqp0s_Status == 1) and EnvMode.norm_val == 2 then
             a9 = 1
                                                      r.InsertEnvelopePoint(envelope, posf+OneSpl, Gain, shape, tens, sel, true) --firstest point pre att
                                         elseif  EnvMode.norm_val == 1 then
                                                  if OffBeatP.norm_val == 2 and ItemEnvMode.norm_val ~= 1 then
             a10 = 1
                                                       r.InsertEnvelopePoint(envelope, posf+OneSpl, Gx1/PanWidth2, shape, tens, sel, true) --firstest point pre att
                                                  end
                                         end
                          end

               else -- adaptive first transient (Grid)

                          if sel_equal_pos == 0 and Floor_State.norm_val ~= 3 and ItemEnvMode.norm_val ~= 2 and not (EnvName == "Pan" or EnvName == "Pan (Pre-FX)") then
                                         if Offset_Sld.form_val > 0.0 and EnvMode.norm_val == 2 then
             a11 = 1
                                                      r.InsertEnvelopePoint(envelope, posf+OneSpl, Gain, shape, tens, sel, true) --firstest point pre att
                                         elseif Offset_Sld.form_val <= 0.0 and EnvMode.norm_val == 1 then
                                                  if OffBeatP.norm_val == 2 then
             a12 = 1
                                                       r.InsertEnvelopePoint(envelope, posf+OneSpl, Gain, shape, tens, sel, true) --firstest point pre att
                                                  end
                                         end
                          end

               end ------------------------------

 --     if TrackEnv == 1 then

               if (Offset_Sld.form_val > 0.0 and EnvMode.norm_val ~= 2) or Offset_Sld.form_val > 0.0 then -- Offset slider + and invert, first point
 a13 = 1
                                    r.InsertEnvelopePoint(envelope, posf+OneSpl+OneSpl, Gx1/PanWidth2, shape, tens, sel, true) --first point -- Gx1/PanWidth2
              end

               if (Offset_Sld.form_val <= 0.0 and EnvMode.norm_val ~= 1) or Offset_Sld.form_val <= 0.0 then -- Offset slider - and not invert, first point
 a13a = 1
                                    if Guides.norm_val == 1  then 

                                              if EnvMode.norm_val == 1 then
 a14 = 1   
                                                 r.InsertEnvelopePoint(envelope, posf+OneSpl+OneSpl, Gx1/PanWidth2, shape, tens, sel, true) --first point -- Gx1/PanWidth2
                                              end
                                            else
 a14a = 1
                                         if (ItemEnvMode.norm_val ~= 2 and OffBeatP.norm_val == 2) then
 a14b = 1
                                             r.InsertEnvelopePoint(envelope, posf+OneSpl+OneSpl, Gx3/PanWidth2, shape, tens, sel, true) --first point -- Gx1/PanWidth2
                                         end
                                    end
               end
    --  end

               if Floor_State.norm_val == 3 or Floor_State.norm_val == 1 then -- Fall or Flat
                  FlCmp2 = 0
                   else
                  FlCmp2 = FlCmp
               end
              
                if Floor_State.norm_val == 1 then -- Flat
                  FlCmp3 = 0
                   else
                  FlCmp3 = FlCmp
                  Gx4 = 0
               end
      
               if Floor_State.norm_val == 3 then --inverted and Fall
                    if  EnvMode.norm_val == 1  then
                       FlCmp3 = FlCmp
                       Gx4 = ZeroGain2
                       else
                       FlCmp3 = 0
                    end
               end
      

                if TrackEnv == 1 then
                   if sel_area == 1 then 
                          if EnvMode.norm_val ~= 1 and (Floor_State.norm_val == 1 and OffBeatP.norm_val ~= 2) or (Floor_State.norm_val == 3 and OffBeatP.norm_val ~= 2) then --not inverted
                             if  (EnvMode.norm_val ~= 1 and Floor_State.norm_val ~= 3)    then
a15 = 1
                                 r.InsertEnvelopePoint(envelope, posl-OneSpl, 0, shape, tens, sel, true) --lastest point (Gx3)
                             end
                          end
                     else 
a16 = 1
                --     r.InsertEnvelopePoint(envelope, posl, ZeroGain2-FlCmp2, shape, tens, sel, true) --lastest point (Gx3)
                   end
                end
      
              if TrackEnv == 1 and (Floor_State.norm_val == 1 or Floor_State.norm_val == 3) and ItemEnvMode.norm_val ~= 2 and not (EnvName == "Pan" or EnvName == "Pan (Pre-FX)") then
a17 = 1
                             r.InsertEnvelopePoint(envelope, posl-OneSpl, Gx1-FlCmp3, shape, tens, sel, true) --last point pre att +0.0007 -- Gx4-FlCmp3
              end


       if Guides.norm_val == 1 and sel_area == 1 then -- Transients and sel area
a18 = 1
                     if sel_equal_pos == 1 then
a19 = 1
                           r.InsertEnvelopePoint(envelope, posf+OneSpl+OneSpl, Gx3/PanWidth2, 0, tens, sel, true) --first point -- Gx1/PanWidth2
                     end

                --     r.InsertEnvelopePoint(envelope, posl-OneSpl, Gx1-FlCmp2, shape, tens, sel, true) --lastest point (Gx3)

                     if (EnvName == "Pan" or EnvName == "Pan (Pre-FX)") then
                             --             r.InsertEnvelopePoint(envelope, posl-OneSpl, Gx1/PanWidth2, shape, tens, sel, true) --lastest point (Gx3)
                     end

       end

end -- StartEndPointsIsOn

------------------------------------------------------------------------------------------------------------------------------------------------------------------
    r.Envelope_SortPoints(envelope)

end --for i=0, items-1 do



end
end
end --  for i = 0, tracks-1 do
    r.UpdateArrange()
end



---------------------------------------------------------------------------------------------------
---  Wave(Processing, drawing etc)  ------------------------------------------------------
---------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
--- DRAW --------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--- Draw Original,Filtered ------------------------------------------------
--------------------------------------------------------------------------------
function Wave:Redraw()
 
    local x,y,w,h = self.def_xywh[1],self.def_xywh[2],self.def_xywh[3],self.def_xywh[4]
    ---------------
    gfx.dest = 1           -- set dest gfx buffer1
    gfx.a    = 1           -- gfx.a - for buf    
    gfx.setimgdim(1,-1,-1) -- clear buf1(Wave)
    gfx.setimgdim(1,w,h)   -- set gfx buffer w,h
    ---------------
      if ViewMode.norm_val == 1 then self:draw_waveform(1,  0.12,0.32,0.57,0.95) -- Draw Original(1, r,g,b,a) -- цвет оригинальной и фильтрованной waveform
                                                  self:draw_waveform(2,  0.75,0.2,0.25,1) -- Draw Filtered(2, r,g,b,a)
        elseif ViewMode.norm_val == 2 then self:draw_waveform(1,  0.14,0.34,0.59,1) -- Only original 
        elseif ViewMode.norm_val == 3 then self:draw_waveform(2,  0.7,0.2,0.25,1) -- Only filtered 
      end
    ---------------
    gfx.dest = -1          -- set main gfx dest buffer
    ---------------
end

--------------------------------------------------------------
--------------------------------------------------------------
function Wave:draw_waveform(mode, r,g,b,a)
    local Peak_TB, Ysc
    local Y = self.Y
    ----------------------------
    if mode==1 then Peak_TB = self.in_peaks;  Ysc = self.Y_scale+orig_gain * self.vertZoom end  
    if mode==2 then Peak_TB = self.out_peaks;
       -- Its not real Gain - но это обязательно учитывать в дальнейшем, экономит время...
       local fltr_gain = 10^(Fltr_Gain.form_val/20)               -- from Fltr_Gain Sldr!
       Ysc = self.Y_scale*(0.5/block_size) * fltr_gain * self.vertZoom  -- Y_scale for filtered waveform drawing 
    end   
    ----------------------------
    ----------------------------
    local w = self.def_xywh[3] -- 1024 = def width
    local Zfact = self.max_Zoom/self.Zoom  -- zoom factor
    local Ppos = self.Pos*self.max_Zoom    -- старт. позиция в "мелкой"-Peak_TB для начала прорисовки  
    local curr = ceil(Ppos+1)              -- округление
    local n_Peaks = w*self.max_Zoom       -- Макс. доступное кол-во пиков
    gfx.set(r,g,b,a)                       -- set color
    -- уточнить, нужно сделать исправление для неориг. размера окна --
    -- next выходит за w*max_Zoom, а должен - макс. w*max_Zoom(51200) при max_Zoom=50 --
    for i=1, w do            
       local next = min(i*Zfact + Ppos, n_Peaks ) -- грубоватое исправление...
       local min_peak, max_peak, peak = 0, 0, 0 
          for p=curr, next do
              peak = Peak_TB[p][1]
              min_peak = min(min_peak, peak)
              peak = Peak_TB[p][2]
              max_peak = max(max_peak, peak)
          end
        curr = ceil(next)
        local y, y2 = Y - min_peak *Ysc, Y - max_peak *Ysc 
        gfx.line(i,y, i,y2) -- здесь всегда x=i
    end  
    ----------------------------
end

--------------------------------------------------------------
--------------------------------------------------------------
function Wave:Create_Peaks(mode) -- mode = 1 for original, mode = 2 for filtered
    local buf
    if mode==1 then buf = self.in_buf    -- for input(original)    
               else buf = self.out_buf   -- for output(filtered)
    end
    ----------------------------
    ----------------------------
    local Peak_TB = {}
    local w = self.def_xywh[3] -- 1024 = def width 
    local pix_dens = self.pix_dens
    local smpl_inpix = (self.selSamples/w) /self.max_Zoom  -- кол-во семплов на один пик(при макс. зуме!)
    local a = 0
    -- норм --------------------
    local curr = 1
    for i=1, w * self.max_Zoom do
        local next = i*smpl_inpix
        local min_smpl, max_smpl, smpl = 0, 0, 0 
        for s=curr, next, pix_dens do  
            smpl = buf[s]
              min_smpl = min(min_smpl, smpl)
              max_smpl = max(max_smpl, smpl)
        end
        a = a +1
        Peak_TB[a] = {min_smpl, max_smpl} -- min, max val to table
        curr = ceil(next) 
    end
    ----------------------------
    if mode==1 then self.in_peaks = Peak_TB else self.out_peaks = Peak_TB end    
    ----------------------------
end


------------------------------------------------------------------------------------------------------------------------
-- WAVE - (Get samples(in_buf) > filtering > to out-buf > Create in, out peaks ) ---------------------------------------
------------------------------------------------------------------------------------------------------------------------
-------
function Wave:table_plus(mode, size, tmp_buf)
  local buf
  if mode==1 then buf=self.in_buf else buf=self.out_buf end
  local j = 1
  for i = size+1, size + #tmp_buf, 1 do  
      buf[i] = tmp_buf[j]
      j=j+1 
  end
end
--------------------------------------------------------------------------------
-- Wave:Set_Values() - set main values, cordinates etc -------------------------
--------------------------------------------------------------------------------
function Wave:Set_Values()
  -- gfx buffer always used default Wave coordinates! --
  local x,y,w,h = self.def_xywh[1],self.def_xywh[2],self.def_xywh[3],self.def_xywh[4] 
    -- Get Selection ----------------
    if not self:Get_TimeSelection() then return end    -- Get time sel start,end,lenght
    ---------------------------------
if NoItems == 0 and WaveCheck == 1 then mlt = 1 else mlt = 16 end
    -- Calculate some values --------
    self.sel_len    = min(self.sel_len,time_limit)     -- limit lenght(deliberate restriction) 
    self.selSamples = floor(self.sel_len*srate)/mlt        -- time selection lenght to samples
    -- init Horizontal --------------

    local MaxZoom = 5*self.sel_len
    if MaxZoom > 150 then MaxZoom = 150 end
    self.max_Zoom = MaxZoom -- maximum zoom level(желательно ок.150-200,но зав. от длины выдел.(нужно поправить в созд. пиков!))

    self.Zoom = self.Zoom or 1  -- init Zoom 
    self.Pos  = self.Pos  or 0  -- init src position
    -- init Vertical ---------------- 
    self.max_vertZoom = 12       -- maximum vertical zoom level(need optim value)
    self.vertZoom = self.vertZoom or 1  -- init vertical Zoom 
    ---------------------------------
    -- pix_dens - нужно выбрать оптимум или оптимальную зависимость от sel_len!!!
    self.pix_dens = 4            -- 2^(4-1) 4-default. 1-учесть все семплы для прорисовки(max кач-во),2-через один и тд.
    self.X, self.Y  = x, h/2                           -- waveform position(X,Y axis)
    self.X_scale    = (w/self.selSamples)/mlt                -- X_scale = w/lenght in samples
    self.Y_scale    = h/2.5                            -- Y_scale for waveform drawing
    ---------------------------------
    -- Some other values ------------
    self.crsx   = block_size/bsdiv2   -- one side "crossX"  -- use for discard some FFT artefacts(its non-nat, but in this case normally)
    self.Xblock = block_size-self.crsx*2               -- active part of full block(use mid-part of each block)
    -----------
    local max_size = 2^22 - 1    -- Макс. доступно(при создании из таблицы можно больше, но...)
    local div_fact = self.Xblock -- Размеры полн. и ост. буфера здесь всегда должны быть кратны Xblock --
    self.full_buf_sz  = (max_size//div_fact)*div_fact     -- размер полного буфера с учетом кратности div_fact
    self.n_Full_Bufs  = self.selSamples//self.full_buf_sz -- кол-во полных буферов в выделении
    self.n_XBlocks_FB = self.full_buf_sz/div_fact         -- кол-во X-блоков в полном буфере
    -----------
    local rest_smpls  = self.selSamples - self.n_Full_Bufs*self.full_buf_sz -- остаток семплов
    self.rest_buf_sz  = ceil(rest_smpls/div_fact) * div_fact  -- размер остаточного(окр. вверх для захв. полн. участка)
    self.n_XBlocks_RB = self.rest_buf_sz/div_fact             -- кол-во X-блоков в остаточном буфере 
  -------------
  return true
end

-----------------------------------
function Wave:Processing()
    -------------------------------
    -- Filter values --------------
    -------------------------------
    -- LP = HiFreq, HP = LowFreq --
    local Low_Freq, Hi_Freq =  HP_Freq.form_val, LP_Freq.form_val
    local bin_freq = srate/(block_size*2)          -- freq step 
    local lowband  = Low_Freq/bin_freq             -- low bin
    local hiband   = Hi_Freq/bin_freq              -- hi bin
    -- lowband, hiband to valid values(need even int) ------------
    lowband = floor(lowband/2)*2
    hiband  = ceil(hiband/2)*2  
    -------------------------------------------------------------------------
    -- Get Original(input) samples to in_buf >> to table >> create peaks ----
    -------------------------------------------------------------------------
    if not self.State then
        if not self:Set_Values() then return end -- set main values, coordinates etc   
        ------------------------------------------------------ 
        local size = self.full_buf_sz
        local buf_start = self.sel_start
				local max = self.n_Full_Bufs+1
				local tmp_buf = r.new_array(size)
				local len = self.full_buf_sz/srate
        for i=1, max do 
            if i == max then size = self.rest_buf_sz end  
						tmp_buf.clear()
            r.GetAudioAccessorSamples(self.AA, srate, 1, buf_start, size, tmp_buf) -- orig samples to in_buf for drawing
            --------
            if i==1 then self.in_buf = tmp_buf.table(1,size) else self:table_plus(1, (i-1)*self.full_buf_sz, tmp_buf.table(1,size) ) end
            --------
            buf_start = buf_start + len -- to next
            ------------------------
        end
        self:Create_Peaks(1)  -- Create_Peaks input(Original) wave peaks
        self.in_buf  = nil    -- входной больше не нужен
    end
    
    -------------------------------------------------------------------------
    -- Filtering >> samples to out_buf >> to table >> create peaks ----------
    -------------------------------------------------------------------------
    local size, n_XBlocks = self.full_buf_sz, self.n_XBlocks_FB
    local buf_start = self.sel_start
    local max = self.n_Full_Bufs+1
		local tmp_buf = r.new_array(size)
		local len = self.full_buf_sz/srate
		for i=1, max do
       if i == max then size, n_XBlocks = self.rest_buf_sz, self.n_XBlocks_RB end
       ------
       ---------------------------------------------------------
       local block_start = buf_start - (self.crsx/srate)   -- first block in current buf start(regard crsx)   
       for block=1, n_XBlocks do r.GetAudioAccessorSamples(self.AA, srate, 1, block_start, block_size, self.buffer)
               -----------------------------------------------------------
               -- Filter_FFT ----(note: don't use out of range freq!)
               -----------------------------------------------------------           
                      local buf = self.buffer
                        ----------------------------------------
                        -- Filter(use fft_real) --------------
                        ----------------------------------------
                        buf.fft_real(block_size,true)       -- FFT
                          -----------------------------
                          -- Clear lowband bins --
                          buf.clear(0, 1, lowband)                  -- clear low bins
                          -- Clear hiband bins  --
                          buf.clear(0, hiband+1, block_size-hiband) -- clear hi bins
                          -----------------------------  
                        buf.ifft_real(block_size,true)      -- iFFT
               -----------------------------------------------------------
               -----------------------------------------------------------   
           tmp_buf.copy(self.buffer, self.crsx+1, self.Xblock, (block-1)* self.Xblock + 1 ) -- copy block to out_buf with offset
           --------------------
           block_start = block_start + self.Xblock/srate   -- next block start_time
       end
       ---------------------------------------------------------
       if i==1 then self.out_buf = tmp_buf.table(1,size) else self:table_plus(2, (i-1)*self.full_buf_sz, tmp_buf.table(1,size) ) end
       --------
       buf_start = buf_start + len -- to next
       ------------------------
    end
    -------------------------------------------------------------------------
    self:Create_Peaks(2)  -- Create_Peaks output(Filtered) wave peaks
    -------------------------------------------------------------------------
    self.State = true -- Change State
    -------------------------
   collectgarbage() -- collectgarbage(подметает память) 
end 


----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
---  Wave - Get - Set Cursors  ---------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Wave:Get_Cursor() 
  local E_Curs = r.GetCursorPosition()
  --- edit cursor ---
  local insrc_Ecx = (E_Curs - self.sel_start) * srate * self.X_scale    -- cursor in source!
     insrc_Ecx_k = insrc_Ecx
     self.Ecx = (insrc_Ecx - self.Pos) * self.Zoom*Z_w                  -- Edit cursor
     if self.Ecx >= 0 and self.Ecx <= self.w then gfx.set(0.7,0.8,0.9,1) -- main edit cursor color
        gfx.line(self.x + self.Ecx, self.y, self.x + self.Ecx, self.y+self.h -1 )
     end
     if self.Ecx >= 0 and self.Ecx <= self.w then gfx.set(1,1,1,1) -- loop edit cursor color 
        gfx.line(self.x + self.Ecx, self.y/1.5, self.x + self.Ecx, (self.y+self.h)/9.3 )
     end
  --- play cursor ---
  if r.GetPlayState()&1 == 1 then local P_Curs = r.GetPlayPosition()
     local insrc_Pcx = (P_Curs - self.sel_start) * srate * self.X_scale -- cursor in source!
     self.Pcx = (insrc_Pcx - self.Pos) * self.Zoom*Z_w                  -- Play cursor
     if self.Pcx >= 0 and self.Pcx <= self.w then gfx.set(0.5,0.5,1,1) -- play cursor color  -- цвет плэй курсора
        gfx.line(self.x + self.Pcx, self.y, self.x + self.Pcx, self.y+self.h -1 )
     end

--------------------Auto-Scroll------------------------------------------------

if AutoScroll == 1 or PlayMode == 1 then
         if PlayMode == 0 then -- disable correction when Spacebar to Pause
               if self.Pcx < 0 then mouseAutScrl_status = 1 end
               
               if char==32 and mouseAutScrl_status == 1 then -- cursor focus behavior
               mouseAutScrl_status = 0
               local corr = r.GetCursorPosition() - self.sel_start-0.02 --pos_cor
                     if corr < 0 then corr = 0 end
                     self.Pos =  (corr) * srate * self.X_scale
                     self.Pos = max(self.Pos, 0)
                     self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
                     --------------------
                     Wave:Redraw() -- redraw after move view
               end
         end
   if self.Pcx > self.w then 
      mouseAutScrl_status = 1
      self.Pos = self.Pos + self.w/(self.Zoom*Z_w)
      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
      Wave:Redraw()
   end 
end
------------------------------------------------------------------------------
  end
end 

--------------------------
function Wave:Set_Cursor()
  if SButton == 0 and self:mouseDown() and not(Ctrl or Shift) then  
    if self.insrc_mx then local New_Pos = self.sel_start + (self.insrc_mx/self.X_scale )/srate
       r.SetEditCurPos(New_Pos, false, true)    -- true-seekplay(false-no seekplay) 
    end
  end
end 

----------------------------------------------------------------------------------------------------
---  Wave - Get Mouse  -----------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Wave:Get_Mouse()
    -----------------------------
local true_position = (gfx.mouse_x-self.x)/Z_w  --  waveform borders correction
local pos_margin = gfx.mouse_x-self.x
if true_position < 24 then pos_margin = 0 end
if true_position > 1000 then pos_margin = gfx.mouse_x end
self.insrc_mx_zoom = self.Pos + (pos_margin)/(self.Zoom*Z_w) -- its current mouse position in source!

if SnapToStart == 1 then
local true_position = (gfx.mouse_x-self.x)/Z_w  --  cursor snap correction
local pos_margin = gfx.mouse_x-self.x
   if true_position < 12 then pos_margin = 0 end
    self.insrc_mx = self.Pos + (pos_margin)/(self.Zoom*Z_w) 
else
    self.insrc_mx = self.Pos + (gfx.mouse_x-self.x)/(self.Zoom*Z_w) -- old behavior
end

    ----------------------------- 
    --- Wave get-set Cursors ----
    self:Get_Cursor()
    self:Set_Cursor()   

self.insrc_mx_zoom_k = self.Pos + (insrc_Ecx_k-self.x)/(self.Zoom*Z_w) -- its current cursor position in source!
    -----------------------------------------
    --- Wave Zoom(horizontal) ---------------
    if self:mouseIN() and gfx.mouse_wheel~=0 and not(Ctrl or Shift) then 
DrawGridGuides()
    local M_Wheel = gfx.mouse_wheel
      -------------------
      if     M_Wheel>0 then self.Zoom = min(self.Zoom*1.25, self.max_Zoom)   
      elseif M_Wheel<0 then self.Zoom = max(self.Zoom*0.75, 1)
      end                 
      -- correction Wave Position from src --
      self.Pos = self.insrc_mx_zoom - (gfx.mouse_x-self.x)/(self.Zoom*Z_w)
      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
self_Zoom = self.Zoom --refresh loop by mw
      -------------------
      Wave:Redraw() -- redraw after horizontal zoom
    end
    -----------------------------------------
    --- Wave Zoom(Vertical) -----------------
    if self:mouseIN() and gfx.mouse_wheel~=0 and (Ctrl or Shift) then 
    local  M_Wheel = gfx.mouse_wheel

------------------------------------------------------------------------------------------------------
     if     M_Wheel>0 then self.vertZoom = min(self.vertZoom*1.2, self.max_vertZoom)   
     elseif M_Wheel<0 then self.vertZoom = max(self.vertZoom*0.8, 1)
     end                 
     -------------------
     Wave:Redraw() -- redraw after vertical zoom
    end
    -----------------------------------------
      Cursor_Status = 0
    --- Wave Move ---------------------------
    if (self:mouseDown() or self:mouseM_Down()) and not Shift and not Ctrl then 
      Cursor_Status = 1
      self.Pos = self.Pos + (last_x - gfx.mouse_x)/(self.Zoom*Z_w)
      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
      --------------------
self_Zoom = self.Zoom --refresh loop by mw middle click
      self_Pos = self.Pos
      Wave:Redraw() -- redraw after move view
    end


if Cursor_Status == 1 and (last_x - gfx.mouse_x) ~= 0.0 then -- set and delay new cursor

        time_start = reaper.time_precise()       
        local function Main()     
            local elapsed = reaper.time_precise() - time_start       
            if elapsed >= 0.1 then
              gfx.setcursor(32512)  --set "arrow" cursor
              runcheck = 0
                return
            else
              gfx.setcursor(429, 1) --set "hand" cursor
              runcheck = 1
                reaper.defer(Main)
            end           
        end
        
        if runcheck ~= 1 then
           Main()
        end

end

MouseAct = 0
if ((last_x - gfx.mouse_x) ~= 0.0) and (self:mouseDown() or self:mouseM_Down()) then MouseAct = 1 end

if Sync_on == 1 and ((self:mouseIN() and gfx.mouse_wheel ~= 0) or MouseAct == 1) then -- sync_on by mousewheel only

        time_startx = reaper.time_precise()       
 local  function Mainx()     
            local elapsedx = reaper.time_precise() - time_startx      
            if elapsedx >= 0.2 then
              Sync_on2 = 0
              runcheckx = 0
                return
            else
             Sync_on2 = 1
              runcheckx = 1
                reaper.defer(Mainx)
            end           
        end
        
        if runcheckx ~= 1 then
           Mainx()
        end
end

    --------------------------------------------
    --- Reset Zoom by Middle Mouse Button------
    if Ctrl and self:mouseM_Down() then 
      self.Pos = 0
      self.Zoom = 1   
      Wave:Redraw() -- redraw after zoom reset
      --------------------
    end

              -- loop correction for rng1 and rng2--
      self.Pos3 = self.Pos + (last_x - gfx.mouse_x)/(self.Zoom*Z_w)
      self.Pos3 = max(self.Pos, 0)
      self.Pos3 = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
      shift_Pos = self.Pos3

     --------------------------------------------------------------------------------
     -- Zoom by Arrow Keys
     --------------------------------------------------------------------------------
local KeyUP, KeyDWN, KeyL, KeyR

    if char==30064 then KeyUP = 1 else KeyUP = 0 end -- up
    if char==1685026670 then KeyDWN = 1 else KeyDWN = 0 end -- down
    if char==1818584692 then KeyL = 1 else KeyL = 0 end -- left
    if char==1919379572 then KeyR = 1 else KeyR = 0 end -- right

-------------------------------horizontal----------------------------------------
     if  KeyR == 1 then self.Zoom = min(self.Zoom*1.2, self.max_vertZoom+138)   

      self.Pos = self.insrc_mx_zoom_k - (insrc_Ecx_k-(self.x*1.2))/(self.Zoom*Z_w)
      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )

     Wave:Redraw() -- redraw after horizontal zoom
        
     elseif  KeyL == 1 then self.Zoom = max(self.Zoom*0.8, 1)

      self.Pos = self.insrc_mx_zoom_k - (insrc_Ecx_k-(self.x*0.8))/(self.Zoom*Z_w)
      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )

     Wave:Redraw() -- redraw after horizontal zoom
     end   

-------------------------------vertical-------------------------------------------
     if  KeyUP == 1 then self.vertZoom = min(self.vertZoom*1.2, self.max_vertZoom)   
     Wave:Redraw() -- redraw after vertical zoom

     elseif  KeyDWN == 1 then self.vertZoom = max(self.vertZoom*0.8, 1)
     Wave:Redraw() -- redraw after vertical zoom
     end   

end

--------------------------------------------------------------------------------
---  Insert from buffer(inc. Get_Mouse) ----------------------------------------
--------------------------------------------------------------------------------
function Wave:from_gfxBuffer()

  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = (self.def_xywh[1]* Z_w) , (self.def_xywh[3]* Z_w) -- upd x,w
  self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* Z_h) -- upd y,h
--[[
  if self.fnt_sz then --fix it!--
     self.fnt_sz = max(16,self.def_xywh[5]* (Z_w+Z_h)/1.9)
     self.fnt_sz = min(22,self.fnt_sz* Z_h)
  end 
]]--
  -- draw Wave frame, axis -------------
  self:draw_rect()

   -- Insert Wave from gfx buffer1 ------
  gfx.a = 1 -- gfx.a for blit
  local srcw, srch = Wave.def_xywh[3], Wave.def_xywh[4] -- its always def values 
    if WFiltering == 0 then gfx.mode = 4 end
  gfx.blit(1, 1, 0, 0, 0, srcw, srch,  self.x, self.y, self.w, self.h)

  -- Get Mouse -------------------------
  self:Get_Mouse()     -- get mouse(for zoom, move etc) 
end  

--------------------------------------------------------------------------------
---  Wave - show_help, info ----------------------------------------------------
--------------------------------------------------------------------------------
function Wave:show_help()
 local fnt_sz = 15
if gfx.ext_retina == 1 then
 fnt_sz = max(14,  fnt_sz* (Z_h)/2)
 fnt_sz = min(20, fnt_sz* Z_h)
else
 fnt_sz = max(17,  fnt_sz* (Z_h)/2)
 fnt_sz = min(24, fnt_sz* Z_h)
end

 gfx.setfont(1, "Arial", fnt_sz)
 gfx.set(0.6, 0.6, 0.6, 1) -- цвет текста инфо
 local ZH_correction = Z_h*40
 gfx.x, gfx.y = self.x+23 * (Z_w+Z_h)-ZH_correction, (self.y+1*(Z_h*3))-15
 gfx.drawstr(
  [[
    Select an item (max 300s).
    It is better not to use items longer than 60s.
    Press "Get Selection" button.
    Use sliders to change detection setting.
    Shift+Drag/Mousewheel - fine tune,
    Ctrl+Left Click - reset value to default,
    Space - Play. 
    Esc - Close Shaper/Stutter
    ----------------
    On Waveform Area:
    Mouswheel or Left/Right keys - Horizontal Zoom,
    Ctrl(Shift)+Mouswheel or Up/Down keys - Vertical Zoom, 
    Middle Drag - Move View (Scroll),
    Left Click - Set Edit Cursor,
    Shift+Left Drag - Move Marker,
    Ctrl+Left Drag - Change Velocity,
    Shift+Ctrl+Left Drag - Move Marker and Change Velocity,
    Right Click on Marker - Delete Marker,
    Right Click on Empty Space - Insert Marker.
  ]]) 
end


function Wave:show_env_name()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = (self.def_xywh[1]* Z_w) , (self.def_xywh[3]* Z_w) -- upd x,w
  self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* Z_h) -- upd y,h
local fnt_sz
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local x,y,w,h  = self.x,self.y/6,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/3.5
    gfx.y = y+(h-lbl_h)/500

    if fnt_sz then
           fnt_sz = fnt_sz*(Z_h*1.05)
        if fnt_sz <= 12 then fnt_sz = 12 end
        if fnt_sz >= MaxFontSize-1 then fnt_sz = MaxFontSize-1 end
        fnt_sz = fnt_sz-1
        gfx.setfont(1, "Arial", fnt_sz)
    end
    gfx.set(0.6, 0.6, 0.6, 1) -- цвет текста 

 local Selected_tracks  = reaper.CountSelectedTracks(0)

  if Selected_tracks == 0 then
      gfx.set(0.8, 0.4, 0.4, 1) -- цвет текста ошибки
  end

     TEnv = reaper.GetSelectedEnvelope(0)
        if TEnv then
               _, EnvNameText = reaper.GetEnvelopeName(TEnv)
        end

    if TrackEnv == 1 then --if track env

          if EnvNameText then
               if SelectedEnvOnly == 1 then
                     if Selected_tracks == 0 then
                         gfx.drawstr("No Track(s) Selected", 1, gfx.w, gfx.h)
                         else
                         gfx.drawstr(EnvNameText, 1, gfx.w, gfx.h)
                     end
                  else
                     if Selected_tracks == 0 then
                         gfx.drawstr("No Track(s) Selected", 1, gfx.w, gfx.h)
                         else
                         gfx.drawstr("All Envelopes On "..Selected_tracks.." Selected Tracks", 1, gfx.w, gfx.h)
                     end
               end
          end

        else -- if item envelope

           if ItemEnvMode.norm_val == 1 then
               ItEnvNm = "Volume"
           elseif ItemEnvMode.norm_val == 2 then
               ItEnvNm = "Pan"
            elseif ItemEnvMode.norm_val == 3 then
               ItEnvNm = "Pitch"
           end

           if ItEnvNm then
                gfx.drawstr("Item Envelope: "..ItEnvNm, 1, gfx.w, gfx.h)
           end
    end
end


function Wave:show_process_wait()
    if not Z_w or not Z_h then return end -- return if zoom not defined
    self.x, self.w = (self.def_xywh[1]* Z_w) , (self.def_xywh[3]* Z_w) -- upd x,w
    self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* Z_h) -- upd y,h
    local fnt_sz
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local x,y,w,h  = self.x,self.y/6,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/10
    gfx.y = y+(h-lbl_h)/2.2
    
     if Wave.State then -- if the wave is loaded, place small text upside down
         gfx.x = x+(w-lbl_w)/3.5
         gfx.y = y+(h-lbl_h)/500
         fnt_sz = fnt_sz
         sz_mult = 1
            else
         fnt_sz = 50
         sz_mult = 3
     end

    if fnt_sz then
        if fnt_sz <= 12 then fnt_sz = 12 end
        if fnt_sz >= MaxFontSize+1 then fnt_sz = MaxFontSize+1 end
        fnt_sz = fnt_sz*(Z_h)*sz_mult
        gfx.setfont(1, "Arial", fnt_sz)
    end
    gfx.set(0.6, 0.6, 0.6, 1) -- цвет текста 

    if reaper.CountSelectedMediaItems(0) > 0 then
       gfx.drawstr("Processing, wait...", 1, gfx.w, gfx.h)
    end
end

----------------------------------------------------------------------------------------------------
---   MAIN   ---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function MAIN()

if Gate_on == 1 and Gate_on2 == 1 then 
        time_startf = reaper.time_precise()       
        local function Mainf()     
            local elapsedf = reaper.time_precise() - time_startf       
            if elapsedf >= 0.1 then
              Gate_on3 = 0
              runcheckf = 0
                return
            else         
             Gate_on3 = 1
             runcheckf = 1
             Gate_on2 = 0
                reaper.defer(Mainf)
            end           
        end
        
   if runcheckf ~= 1 then
      Mainf()
   end
end


if Gate_on3 == 1 then

    if Undo_Permit == 1 then
        r.Undo_BeginBlock() 
    end

    Wave:Create_Envelope()

    if Undo_Permit == 1 then
        r.Undo_EndBlock("Slicer/Shaper: Create Envelope", -1) 
        Undo_Permit = 0
    end

end



  -- Draw Wave, lines etc ------
    if Wave.State then      
          Wave:from_gfxBuffer() -- Wave from gfx buffer
          Gate_Gl:draw_Lines()  -- Draw Gate trig-lines
         if ShowRuler == 1 then
               Gate_Gl:draw_Ruler() -- Draw Ruler lines
         end


        local _, division, swing, _ = r.GetSetProjectGrid(0,false)
-----------------------------Grid Buttons Leds-------------------------------------------------------
        if division == 1 or division == 2/3 then
                 for key,frame  in pairs(Grid1_Led_TB)    do frame:draw()  end  
        Grid1_on = 0
        end
        if division == 0.5 or division == 1/3 then
                 for key,frame  in pairs(Grid2_Led_TB)    do frame:draw()  end  
        Grid2_on = 0
        end
        if division == 0.25 or division == 0.5/3 then
                 for key,frame  in pairs(Grid4_Led_TB)    do frame:draw()  end  
        Grid4_on = 0
        end
        if division == 0.125 or division == 0.25/3 then
                 for key,frame  in pairs(Grid8_Led_TB)    do frame:draw()  end  
        Grid8_on = 0
        end
        if division == 0.0625 or division == 0.125/3 then
                 for key,frame  in pairs(Grid16_Led_TB)    do frame:draw()  end  
        Grid16_on = 0
        end
        if division == 0.03125 or division == 0.0625/3 then
                 for key,frame  in pairs(Grid32_Led_TB)    do frame:draw()  end 
        Grid32_on = 0 
        end
        if division == 0.015625 or division == 0.03125/3 then
                 for key,frame  in pairs(Grid64_Led_TB)    do frame:draw()  end  
        Grid64_on = 0
        end
           if ((floor(1/division+.5)) % 3) == 0 then Trplts = true else Trplts = false end;
        if GridT_on == 1 or Trplts == true then
                 for key,frame  in pairs(GridT_Led_TB)    do frame:draw()  end  
        end
        if Swing_on == 1 then
                 for key,frame  in pairs(Swing_Led_TB)    do frame:draw()  end  
        end

-----------------------------Top Buttons-------------------------------------------------------

              for key,btn    in pairs(Sliders_Grid_TB)   do btn:draw()    end 

           if swing == 1  then
              for key,btn    in pairs(Slider_Swing_TB)   do btn:draw()    end 
          end

           if Sync_on == 1 then
              for key,btn    in pairs(Frame_Sync_TB)   do btn:draw()    end 
              else
              for key,btn    in pairs(Frame_Sync_TB2)   do btn:draw()    end 
          end

          if Loop_on == 1 then
              for key,btn    in pairs(Frame_Loop_TB)   do btn:draw()    end 
              for key,btn    in pairs(Loop_TB)   do btn:draw()    end 
              for key,btn    in pairs(LoopBtn_TB)   do btn:draw()    end 
              else
              for key,btn    in pairs(Frame_Loop_TB2)   do btn:draw()    end 
              for key,btn    in pairs(LoopBtn_TB)   do btn:draw()    end 
          end
           if Show_process_wait_is_active == 0 then Wave:show_env_name() end
      else 
          Wave:show_help()      -- else show help
    end


  -- Draw sldrs, btns etc ------
    for key,btn    in pairs(Frame_TB)   do btn:draw()    end 

    if Markers_Btns == 1 then
           for key,btn    in pairs(Markers_TB)   do btn:draw()    end 
    end

       for key,btn    in pairs(Button_TB2)   do btn:draw()    end 
       for key,btn    in pairs(FrameR_TB)   do btn:draw()    end 

       for key,btn    in pairs(Button_TB)   do btn:draw()    end 
       for key,sldr   in pairs(Slider_TB)   do sldr:draw()   end
       for key,ch_box in pairs(CheckBox_TB) do ch_box:draw() end

       for key,sldr   in pairs(Slider_TB_Trigger)   do sldr:draw()   end


     if TrackEnv == 0 then
       for key,ch_box in pairs(CheckBoxItem_TB) do ch_box:draw() end
     end


     if EnvMode.norm_val == 1  then
        for key,frame  in pairs(InvertEnvOn_TB)    do frame:draw()  end   
        else 
        for key,frame  in pairs(InvertEnvOff_TB)    do frame:draw()  end    
     end


     if Guides.norm_val == 1  then
        for key,frame  in pairs(Frame_TB1)    do frame:draw()  end   
        else 
        for key,frame  in pairs(Frame_TB2)    do frame:draw()  end    
     end

     if XFadeOff == 1 then
        for key,sldr   in pairs(XFade_TB_Off)   do sldr:draw()   end
        else
        for key,sldr   in pairs(XFade_TB)   do sldr:draw()   end
     end

                 for key,sldr   in pairs(SliderGate_TB)   do sldr:draw()   end

    if ShowInfoLine == 1 and Random_Setup ~= 1 then
        Info_Line()
    end

         if Guides.norm_val == 2 then
               for key,frame  in pairs(Frame_TB2_Trigg)    do frame:draw()  end 
               for key,frame  in pairs(Grid_Fill_TB)    do frame:draw()  end 
                   else
               for key,frame  in pairs(Transient_Fill_TB)    do frame:draw()  end 
         end

end

------------------------------------
-- MouseWheel Related Functions ---
------------------------------------

function MW_doit_slider()
      if Wave.State then
            Gate_Gl:Apply_toFiltered() -- redraw transient markers
            Slice_Status = 1
Gate_on2 = 1
      end
end

function MW_doit_slider_Fine()
      if Wave.State then
     OffsSldCorr = (Offset_Sld.form_val/1000*srate)
             Gate_Gl:Apply_toFiltered()
             DrawGridGuides()
            Slice_Status = 1
      end
end

function MW_doit_slider_Swing()
        time_start = reaper.time_precise()       
        local function Mainz()     
            local elapsed = reaper.time_precise() - time_start       
            if elapsed >= 0.1 then
                --
              runcheck = 0
                return
            else         
        r.GetSetProjectGrid(0, true, division, swing_mode, swing_slider_amont) --
              runcheck = 1
                reaper.defer(Mainz)
            end           
        end
        
   if runcheck ~= 1 then
      Mainz()
   end
Gate_on2 = 1
end

function MW_doit_slider_fgain()
      if Wave.State then
            Gate_Gl:Apply_toFiltered() -- redraw transient markers
            Wave:Redraw() --redraw filtered gain and filters
            Slice_Status = 1
Gate_on2 = 1
      end
end

function MW_doit_slider_comlpex()
      if Wave.State then
            Wave:Processing() -- redraw lowcut and highcut
            Gate_Gl:Apply_toFiltered() -- redraw transient markers
            Wave:Redraw() --redraw filtered gain and filters
            Slice_Status = 1
Gate_on2 = 1
      end
end

function MW_doit_checkbox()
      if Wave.State then
         Wave.Reset_All()
         DrawGridGuides()
Gate_on2 = 1
      end
end

function MW_doit_checkbox_show()
      if Wave.State then
         Wave:Redraw()
      end
end

function Heal_protection() -- не клеит, если Guides активны
   if Guides.norm_val == 1 then
--r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то клей, попытка не деструктивно склеить).
end 
end

function Glue_protection() -- не клеит, если Guides активны
   if Guides.norm_val == 1 then
-- r.Main_OnCommand(41588, 0) -- glue (если изменены rate, pitch, больше одного айтема и не миди айтем, то клей. Требуется для корректной работы кнопки MIDI).
end 
end

function Offset_Sld_DoIt()
    if Wave.State then
       OffsSldCorr = (Offset_Sld.form_val/1000*srate)
       Gate_Gl:Apply_toFiltered()
       DrawGridGuides()
    end
end

------------------------------------------------------------------------------------

function store_settings() --store dock position
   r.SetExtState("cool_MK_Shaper/Stutter.lua", "dock", gfx.dock(-1), true)
end

function store_settings2() --store sliders/checkboxes
     if RememberLast == 1 then 
        r.SetExtState('cool_MK_Shaper/Stutter.lua','Guides.norm_val',Guides.norm_val,true);
   --     if HiPrecision_On == 1 then OutNote.norm_val = OutNote2.norm_val end
  --      r.SetExtState('cool_MK_Shaper/Stutter.lua','OutNote.norm_val',OutNote.norm_val,true);
 --       r.SetExtState('cool_MK_Shaper/Stutter.lua','Midi_Sampler.norm_val',Midi_Sampler.norm_val,true);
  --      r.SetExtState('cool_MK_Shaper/Stutter.lua','Sampler_preset.norm_val',Sampler_preset.norm_val,true);
  --      r.SetExtState('cool_MK_Shaper/Stutter.lua','QuantizeStrength',QStrength_Sld.form_val,true);
        r.SetExtState('cool_MK_Shaper/Stutter.lua','HF_Slider',HP_Freq.norm_val,true);
        r.SetExtState('cool_MK_Shaper/Stutter.lua','LF_Slider',LP_Freq.norm_val,true);
        r.SetExtState('cool_MK_Shaper/Stutter.lua','Sens_Slider',Gate_Sensitivity.norm_val,true);
        r.SetExtState('cool_MK_Shaper/Stutter.lua','Offs_Slider',Offset_Sld.norm_val,true);
        if XFadeOff == 0 then
           r.SetExtState('cool_MK_Shaper/Stutter.lua','CrossfadeTime',XFade_Sld.form_val,true);
        end
        r.SetExtState('cool_MK_Shaper/Stutter.lua','Gate_VeloScale.norm_val',Gate_VeloScale.norm_val,true);
        r.SetExtState('cool_MK_Shaper/Stutter.lua','Gate_VeloScale.norm_val2',Gate_VeloScale.norm_val2,true);

          r.SetExtState('cool_MK_Shaper/Stutter.lua','Sync_on',Sync_on,true);
     end
end

-------------------------------------------------------------------------------
--   INIT   --------------------------------------------------------------------
-------------------------------------------------------------------------------
function Init()
   dock_pos = r.GetExtState("cool_MK_Shaper/Stutter.lua", "dock")
       if Docked == 1 then
         if dock_pos == "0.0" then dock_pos = 1025 end
           dock_pos = dock_pos or 1025
           xpos = 400
           ypos = 320
           else
           dock_pos = 0
           xpos = r.GetExtState("cool_MK_Shaper/Stutter.lua", "window_x") or 400
           ypos = r.GetExtState("cool_MK_Shaper/Stutter.lua", "window_y") or 320
        end

    -- Some gfx Wnd Default Values ---------------
    local R,G,B = 45,45,45              -- 0...255 format -- цвет основного окна
    local Wnd_bgd = R + G*256 + B*65536 -- red+green*256+blue*65536  
    local Wnd_Title = "MK Shaper/Stutter v1.20"
    local Wnd_Dock, Wnd_X,Wnd_Y = dock_pos, xpos, ypos
 --   Wnd_W,Wnd_H = 1044,490 -- global values(used for define zoom level)

       Wnd_W = r.GetExtState("cool_MK_Shaper/Stutter.lua", "zoomW") or 1044
       Wnd_H = r.GetExtState("cool_MK_Shaper/Stutter.lua", "zoomH") or 490
       if Wnd_W == (nil or "") then Wnd_W = 1044 end
       if Wnd_H == (nil or "") then Wnd_H = 490 end
    -- Init window ------
    gfx.clear = Wnd_bgd         
    gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )


    -- Init mouse last --
    last_mouse_cap = 0
    last_x, last_y = 0, 0
    mouse_ox, mouse_oy = -1, -1
end


function Info_Line()
       -- Draw out_gain value
   if ErrMsg_Ststus == 1 or not Z_w or not Z_h then return end -- return if zoom not defined
       gfx.set(1,1,1,0.4)    -- set body color
       gfx.x = gfx.x+(Z_w*64)
       gfx.y = gfx.y+3
   local _, division, swing, swingamt = r.GetSetProjectGrid(0,false)
   if swingamt then
       swngamt = math_round((swingamt*100),0)
       swngamt = string.format("%d", swngamt)

---------------------Grid---------------------------------
        division = tonumber(division);
        if not tonumber(division) then return false end;
        local i,T,str1,str2,str3,str4;
    if  division >= 0.6 and division <= 0.7 then divisi = division/2
    else divisi = division end
        fraction = floor(1/divisi+.5)
        str1 = (string.format("%.0f",1).."/"..string.format("%.0f",fraction)):gsub("/%s-1$","");
        if division >= 1 then str2 = string.format("%.3f",division):gsub("[0.]-$","") else str2 = str1 end;
        if (fraction % 3) == 0 then T = true else T = false end;
        if T == true then tripl = "T" else tripl = "" end
        if T then str3=string.format("%.0f",1).."/"..string.format("%.0f",fraction-(fraction/3)).."T"else str3=str1 end;
        if T then;
            if division>=0.6666 then str4=string.format("%.3f",(division/2)+division):gsub("[0.]-$","").."T"else str4=str3;end;
            elseif division >= 1 then str4=str2 else str4=str1;
        end;

       gfx.printf("Project: Grid " .. tostring(str4) .. "  ")

   if swing == 0 then 
   swngamt = "Off" 
          gfx.printf("Swing " .. tostring(swngamt) .. "")
   else 
   swngamt = swngamt 
          gfx.printf("Swing " .. tostring(swngamt) .. "%%")
   end
  end

end
---------------------------------------
--   Mainloop   ------------------------
---------------------------------------

function mainloop()

local rng1x = rng1
local rng2x = rng2

local Loop_onx = Loop_on

    -- zoom level -- 
    Wnd_WZ = r.GetExtState("cool_MK_Shaper/Stutter.lua", "zoomWZ") or 1044
    Wnd_HZ = r.GetExtState("cool_MK_Shaper/Stutter.lua", "zoomHZ") or 490
    if Wnd_WZ == (nil or "") then Wnd_WZ = 1044 end
    if Wnd_HZ == (nil or "") then Wnd_HZ = 490 end

    Z_w, Z_h = gfx.w/Wnd_WZ, gfx.h/Wnd_HZ
    gfx_width = gfx.w
    if Z_w<0.63 then Z_w = 0.63 elseif Z_w>4 then Z_w = 4 end --2.2
    if Z_h<0.63 then Z_h = 0.63 elseif Z_h>4 then Z_h = 4 end  --2.2

    -- mouse and modkeys --
    if gfx.mouse_cap&2==0 then mouseR_Up_status = 1 end
    if gfx.mouse_cap&1==1   and last_mouse_cap&1==0  or   -- L mouse
       gfx.mouse_cap&2==2   and last_mouse_cap&2==0  or   -- R mouse
       gfx.mouse_cap&64==64 and last_mouse_cap&64==0 then -- M mouse
       mouse_ox, mouse_oy = gfx.mouse_x, gfx.mouse_y 
    end
    Ctrl  = gfx.mouse_cap&4==4   -- Ctrl  state
    Shift = gfx.mouse_cap&8==8   -- Shift state
    MCtrl = gfx.mouse_cap&5==5   -- Ctrl+LMB state
    Alt   = gfx.mouse_cap&16==16 -- Alt state

    if gfx.mouse_cap&1==1 then 
       mouse_oxz = gfx.mouse_x/Z_w
       mouse_oyz = gfx.mouse_y/Z_h
          if mouse_oxz <= 1034 and mouse_oyz <= 360 then
             mouseAutScrl_status = 0
          end
    end

    -------------------------
    MAIN() -- main function
    -------------------------

    if Loop_on == 1 then
       isloop = true
         else
       isloop = false
    end


if Loop_onx ~= Loop_on then
                r.GetSet_LoopTimeRange(true, true, 0, 0, false) -- loop off when Loop_on == 0
end


    if loop_start and Wave.State and (rng1x ~= rng1 or rng2x ~= rng2) or Loop_onx ~= Loop_on then
        r.GetSet_LoopTimeRange(isloop, true, rng1, rng2, false)
    end


    if Sync_on2 == 1 then
           if loop_start then
              if self_Zoom == nil then self_Zoom = 1 end
              if shift_Pos == nil then shift_Pos = 0 end
              rng3 = math_round(loop_start-((loop_length/self_Zoom)/20)+(0/self_Zoom+(shift_Pos/1024))*( loop_length ),3)
              rng4 = math_round(loop_start+((loop_length/self_Zoom)/16)+(1/self_Zoom+(shift_Pos/1024))*( loop_length ),3)
           end

              if rng3 == nil then rng3 = 0 end
              if rng4 == nil then rng4 = 1 end

         r.GetSet_ArrangeView2( 0,1,0,0,rng3, rng4 )

    end

if gfx.mouse_wheel ~= 0 then
wheel_check = 1
else
wheel_check = 0
end

    last_mouse_cap = gfx.mouse_cap
    last_x, last_y = gfx.mouse_x, gfx.mouse_y
    gfx.mouse_wheel = 0 -- reset mouse_wheel


    char = gfx.getchar()

    if char==32 then 
         if PlayMode == 0 then
         r.Main_OnCommand(40044, 0) 
         else
         r.Main_OnCommand(40073, 0) 
         end
    end -- play
  
     if char==26 then 
         r.Main_OnCommand(40029, 0)  
         SliceQ_Init_Status = 0
         Slice_Status = 1
         MarkersQ_Status = 1
     end ---undo
   
     if char==19 then 
         r.Main_OnCommand(40026, 0)  
     end ---save (ctrl+s)

     if EscToExit == 1 then
           if char == 27 then gfx.quit() end   -- escape 
     end

     if char~=-1 then 
        r.defer(mainloop)  
         else 
        Wave:Destroy_Track_Accessor()
     end     -- defer  

    -----------  
    gfx.update()
    -----------

end

function store_window() -- store window dock state/position/size
  local _, xpos, ypos, Wnd_W, Wnd_H = gfx.dock(-1, 0, 0, 0, 0)
    r.SetExtState("cool_MK_Shaper/Stutter.lua", "window_x", xpos, true)
    r.SetExtState("cool_MK_Shaper/Stutter.lua", "window_y", ypos, true)
    r.SetExtState("cool_MK_Shaper/Stutter.lua", "zoomW", Wnd_W, true)
    r.SetExtState("cool_MK_Shaper/Stutter.lua", "zoomH", Wnd_H, true)
    r.SetExtState("cool_MK_Shaper/Stutter.lua", "zoomWZ", Wnd_WZ, true)
    r.SetExtState("cool_MK_Shaper/Stutter.lua", "zoomHZ", Wnd_HZ, true)
end

function getitem()


     time_start = reaper.time_precise()       
        local function Main()     
            local elapsed = reaper.time_precise() - time_start       
            if elapsed >= 0.01 then
               Show_process_wait_is_active = 0
            ----------------------------------------------------------------
                 r.Undo_BeginBlock() 
                 r.PreventUIRefresh(1)
                 Muted = 0
                 if number_of_takes == 1 and mute_check == 1 then 
                 r.Main_OnCommand(40175, 0) 
                 Muted = 1
                 end

                 ----------------------------------------------------------------
                    Wave:Destroy_Track_Accessor() -- Destroy previos AA(освобождает память etc)
                    Wave.State = false -- reset Wave.State
                    if Wave:Create_Track_Accessor() then Wave:Processing()
                       if Wave.State then
                          Wave:Redraw()
                          Gate_Gl:Apply_toFiltered() 
                          DrawGridGuides()
                         -- DrawGridGuides2()
                       end
                    end
                 -----------------------------------------------------------------
                 
                 if Muted == 1 then
                 r.Main_OnCommand(40175, 0) 
                 end
                 r.PreventUIRefresh(-1)
                 r.Undo_EndBlock("Toggle Item Mute", -1) 
             ------------------------------------------------------------------
              runcheck = 0
                return
            else
            Wave:show_process_wait()
            Show_process_wait_is_active = 1
              runcheck = 1
                reaper.defer(Main)
            end           
        end
        
        if runcheck ~= 1 then
           Main()
        end

end

-----------------------------------------------------------------------------------
-- Set ToolBar Button ON
function SetButtonON()
  local is_new_value, filename, sec, cmd, mode, resolution, val = r.get_action_context()
  r.SetToggleCommandState( sec, cmd, 1 ) -- Set ON
  r.RefreshToolbar2( sec, cmd )
end

-- Set ToolBar Button OFF
function SetButtonOFF()
  local is_new_value, filename, sec, cmd, mode, resolution, val = r.get_action_context()
  r.SetToggleCommandState( sec, cmd, 0 ) -- Set OFF
  r.RefreshToolbar2( sec, cmd )
end
-----------------------------------------------------------------------------------
SetButtonON()

Init()
mainloop()
getitem()

----------------------------Menu GFX and Items------------------------------------

 mouse = {  
                  -- Constants
                  LB = 1,
                  RB = 2,
                  -- "cap" function
                  cap = function (mask)
                          if mask == nil then
                            return gfx.mouse_cap end
                          return gfx.mouse_cap&mask == mask
                        end,                        
                  last_LMB_state = false,
                  last_RMB_state = false
               }

function mainloop_settings()
  LMB_state = mouse.cap(mouse.LB)
if not mouse.last_LMB_state and MenuCall == 1 then 
  context_menu:show(last_x, last_y)
end
  mouse.last_LMB_state = LMB_state
  gfx.update()
  if gfx.getchar() >= 0 then r.defer(mainloop_settings) end
end


---------------------------
-- Create "context" menu --
---------------------------
context_menu = Menu("context_menu")

item1 = context_menu:add_item({label = "Links|", active = false})

item2 = context_menu:add_item({label = "Donate (ByMeACoffee)", toggleable = false})
item2.command = function()
                     r.CF_ShellExecute('https://www.buymeacoffee.com/MaximKokarev')
end

item3 = context_menu:add_item({label = "User Manual and Support (Forum Thread)|", toggleable = false})
item3.command = function()
                     r.CF_ShellExecute('https://forum.cockos.com/showthread.php?t=254081')
end

item4 = context_menu:add_item({label = "Options|", active = false})


if Docked == 1 then
item5 = context_menu:add_item({label = "Script Starts Docked", toggleable = true, selected = true})
else
item5 = context_menu:add_item({label = "Script Starts Docked", toggleable = true, selected = false})
end
item5.command = function()
                     if item5.selected == true then 
  local _, xpos, ypos, Wnd_W, Wnd_H = gfx.dock(-1, 0, 0, 0, 0)
    r.SetExtState("cool_MK_Shaper/Stutter.lua", "window_x", xpos, true)
    r.SetExtState("cool_MK_Shaper/Stutter.lua", "window_y", ypos, true)
    r.SetExtState("cool_MK_Shaper/Stutter.lua", "zoomW", Wnd_W, true)
    r.SetExtState("cool_MK_Shaper/Stutter.lua", "zoomH", Wnd_H, true)
    r.SetExtState("cool_MK_Shaper/Stutter.lua", "zoomWZ", Wnd_WZ, true)
    r.SetExtState("cool_MK_Shaper/Stutter.lua", "zoomHZ", Wnd_HZ, true)

gfx.quit()
     Docked = 1
     dock_pos = r.GetExtState("cool_MK_Shaper/Stutter.lua", "dock")
     if dock_pos == "0.0" then dock_pos = 1025 end
     dock_pos = dock_pos or 1025
     xpos = 400
     ypos = 320
     local Wnd_Title = "MK Shaper/Stutter v1.20"
     local Wnd_Dock, Wnd_X,Wnd_Y = dock_pos, xpos, ypos
     gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )

                     else

    r.SetExtState("cool_MK_Shaper/Stutter.lua", "dock", gfx.dock(-1), true)
gfx.quit()
    Docked = 0
    dock_pos = 0
    xpos = r.GetExtState("cool_MK_Shaper/Stutter.lua", "window_x") or 400
    ypos = r.GetExtState("cool_MK_Shaper/Stutter.lua", "window_y") or 320
    local Wnd_Title = "MK Shaper/Stutter v1.20"
    local Wnd_Dock, Wnd_X,Wnd_Y = dock_pos, xpos, ypos
    gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )
 
    Wnd_WZ = r.GetExtState("cool_MK_Shaper/Stutter.lua", "zoomWZ") or 1044
    Wnd_HZ = r.GetExtState("cool_MK_Shaper/Stutter.lua", "zoomHZ") or 490
    if Wnd_WZ == (nil or "") then Wnd_WZ = 1044 end
    if Wnd_HZ == (nil or "") then Wnd_HZ = 490 end
 
    Z_w, Z_h = gfx.w/Wnd_WZ, gfx.h/Wnd_HZ
 
    if Z_w<0.63 then Z_w = 0.63 elseif Z_w>4 then Z_w = 4 end --2.2
    if Z_h<0.63 then Z_h = 0.63 elseif Z_h>4 then Z_h = 4 end  --2.2
                     end
          r.SetExtState('cool_MK_Shaper/Stutter.lua','Docked',Docked,true);
end


if EscToExit == 1 then
item6 = context_menu:add_item({label = "Use ESC to Close Script", toggleable = true, selected = true})
else
item6 = context_menu:add_item({label = "Use ESC to Close Script", toggleable = true, selected = false})
end
item6.command = function()
                     if item6.selected == true then 
                     EscToExit = 1
                     else
                     EscToExit = 0
                     end
          r.SetExtState('cool_MK_Shaper/Stutter.lua','EscToExit',EscToExit,true);
end


if AutoScroll == 1 then
item7 = context_menu:add_item({label = "Auto Scroll View", toggleable = true, selected = true})
else
item7 = context_menu:add_item({label = "Auto Scroll View", toggleable = true, selected = false})
end
item7.command = function()
                     if item7.selected == true then 
                     AutoScroll = 1
                     else
                     AutoScroll = 0
                     end
          r.SetExtState('cool_MK_Shaper/Stutter.lua','AutoScroll',AutoScroll,true);
end


if PlayMode == 1 then
item8 = context_menu:add_item({label = "Spacebar to Pause", toggleable = true, selected = true})
else
item8 = context_menu:add_item({label = "Spacebar to Pause", toggleable = true, selected = false})
end
item8.command = function()
                     if item8.selected == true then 
                     PlayMode = 1
                     else
                     PlayMode = 0
                     end
          r.SetExtState('cool_MK_Shaper/Stutter.lua','PlayMode',PlayMode,true);
end


if Loop_on == 1 then
item9 = context_menu:add_item({label = "Loop is Enabled when the Script Starts|", toggleable = true, selected = true})
else
item9 = context_menu:add_item({label = "Loop is Enabled when the Script Starts|", toggleable = true, selected = false})
end
item9.command = function()
                     if item9.selected == true then 
                     Loop_on = 1
                     else
                     Loop_on = 0
                     end
          r.SetExtState('cool_MK_Shaper/Stutter.lua','Loop_on',Loop_on,true);
end


if TrackEnv == 1 then
item10 = context_menu:add_item({label = "Track Envelope", toggleable = true, selected = true})
else
item10 = context_menu:add_item({label = "Track Envelope", toggleable = true, selected = false})
end
item10.command = function()
                     if item10.selected == true then 
                     TrackEnv = 1
                     else
                     TrackEnv = 0
                     end
          r.SetExtState('cool_MK_Shaper/Stutter.lua','TrackEnv',TrackEnv,true);
end


if VolPreFX == 0 then
item11 = context_menu:add_item({label = "Pre-FX Track Volume", toggleable = true, selected = false})
else
item11 = context_menu:add_item({label = "Pre-FX Track Volume", toggleable = true, selected = true})
end
item11.command = function()
                     if item11.selected == false then 
                     VolPreFX = 0
                     else
                     VolPreFX = 1
                     end
          r.SetExtState('cool_MK_Shaper/Stutter.lua','VolPreFX',VolPreFX,true);
end


if InvOnByDefault == 1 then
item12 = context_menu:add_item({label = "Invert On by Default", toggleable = true, selected = true})
else
item12 = context_menu:add_item({label = "Invert On by Default", toggleable = true, selected = false})
end
item12.command = function()
                     if item12.selected == true then 
                     InvOnByDefault = 1
                     else
                     InvOnByDefault = 2
                     end
          r.SetExtState('cool_MK_Shaper/Stutter.lua','InvOnByDefault',InvOnByDefault,true);
end 


if EnvItemOnClose == 1 then
item13 = context_menu:add_item({label = "Create Envelope Item On Script Close", toggleable = true, selected = true})
else
item13 = context_menu:add_item({label = "Create Envelope Item On Script Close", toggleable = true, selected = false})
end
item13.command = function()
                     if item13.selected == true then 
                     EnvItemOnClose = 1
                     else
                     EnvItemOnClose = 0
                     end
          r.SetExtState('cool_MK_Shaper/Stutter.lua','EnvItemOnClose',EnvItemOnClose,true);
end


if HiPrecision_On == 1 then
item14 = context_menu:add_item({label = "High Precision (Slow, Restart required)|", toggleable = true, selected = true})
else
item14 = context_menu:add_item({label = "High Precision (Slow, Restart required)|", toggleable = true, selected = false})
end
item14.command = function()
                     if item14.selected == true then 
                     HiPrecision_On = 1
                     else
                     HiPrecision_On = 0
                     end
          r.SetExtState('cool_MK_Shaper/Stutter.lua','HiPrecision_On',HiPrecision_On,true);
end 


if SelectedEnvOnly == 1 then
item15 = context_menu:add_item({label = "Process Only Selected Envelope", toggleable = true, selected = true})
else
item15 = context_menu:add_item({label = "Process Only Selected Envelope", toggleable = true, selected = false})
end
item15.command = function()
                     if item15.selected == true then 
                     SelectedEnvOnly = 1
                     else
                     SelectedEnvOnly = 0
                     end
          r.SetExtState('cool_MK_Shaper/Stutter.lua','SelectedEnvOnly',SelectedEnvOnly,true);
end


if ObeyingItemSelection == 1 then
           item16 = context_menu:add_item({label = "--Reserved--|", toggleable = true, selected = true, active = true})
           else
           item16 = context_menu:add_item({label = "--Reserved--|", toggleable = true, selected = false, active = true})
end
item16.command = function()
                     if item16.selected == true then 
                     ObeyingItemSelection = 1
                     else
                     ObeyingItemSelection = 0
                     end
          r.SetExtState('cool_MK_Shaper/Stutter.lua','ObeyingItemSelection',ObeyingItemSelection,true);

end


item17 = context_menu:add_item({label = ">User Settings (Advanced)"})
item17.command = function()

end


item18 = context_menu:add_item({label = "Set User Defaults", toggleable = false})
item18.command = function()
user_defaults()
end


item19 = context_menu:add_item({label = "Reset All Setted User Defaults|", toggleable = false})
item18.command = function()

      r.SetExtState('cool_MK_Shaper/Stutter.lua','DefaultXFadeTime',15,true);
      r.SetExtState('cool_MK_Shaper/Stutter.lua','DefaultQStrength',100,true);
      r.SetExtState('cool_MK_Shaper/Stutter.lua','DefaultLP',1,true);
      r.SetExtState('cool_MK_Shaper/Stutter.lua','DefaultHP',0.3312,true);
      r.SetExtState('cool_MK_Shaper/Stutter.lua','DefaultSens',0.375,true);
      r.SetExtState('cool_MK_Shaper/Stutter.lua','DefaultOffset',0.5,true);
      r.SetExtState('cool_MK_Shaper/Stutter.lua','MIDI_Base_Oct',2,true);
 --     r.SetExtState('cool_MK_Shaper/Stutter.lua','Trigger_Oct_Shift',0,true);

end


if MaxFontSizeSt == 1 then
  item38 = context_menu:add_item({label = "Large Font Size (Restart required)", toggleable = true, selected = true, active = true})
  else
  item38 = context_menu:add_item({label = "Large Font Size (Restart required)", toggleable = true, selected = false, active = true})
end
item38.command = function()
            if item38.selected == true then 
            MaxFontSizeSt = 1
            else
            MaxFontSizeSt = 0
            end
 r.SetExtState('MK_Slicer_3','MaxFontSizeSt',MaxFontSizeSt,true);
end


item21 = context_menu:add_item({label = "|Reset Controls to User Defaults (Restart required)|<", toggleable = false})
item21.command = function()
Reset_to_def = 1
  --sliders--
      DefaultXFadeTime = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultXFadeTime'))or 15;
      DefaultQStrength = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultQStrength'))or 100;
      DefaultHP = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultHP'))or 0.3312;
      DefaultLP = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultLP'))or 1;
      DefaultSens = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultSens'))or 0.375;
      DefaultOffset = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultOffset'))or 0.5;
  --sheckboxes--
     DefMIDI_Mode =  1;
     DefSampler_preset_state =  1;
     DefGuides_mode =  1;
     DefOutNote_State =  1;
     DefGate_VeloScale =  1;
     DefGate_VeloScale2 =  1;
     DefXFadeOff = 0

  --sliders--
      r.SetExtState('cool_MK_Shaper/Stutter.lua','CrossfadeTime',DefaultXFadeTime,true);
      r.SetExtState('cool_MK_Shaper/Stutter.lua','QuantizeStrength',DefaultQStrength,true);
      r.SetExtState('cool_MK_Shaper/Stutter.lua','Offs_Slider',DefaultOffset,true);
      r.SetExtState('cool_MK_Shaper/Stutter.lua','HF_Slider',DefaultHP,true);
      r.SetExtState('cool_MK_Shaper/Stutter.lua','LF_Slider',DefaultLP,true);
      r.SetExtState('cool_MK_Shaper/Stutter.lua','Sens_Slider',DefaultSens,true);
  --sheckboxes--
      r.SetExtState('cool_MK_Shaper/Stutter.lua','Guides.norm_val',DefGuides_mode,true);
--      if HiPrecision_On == 1 then OutNote.norm_val = OutNote2.norm_val end
 --     r.SetExtState('cool_MK_Shaper/Stutter.lua','OutNote.norm_val',DefOutNote_State,true);
      r.SetExtState('cool_MK_Shaper/Stutter.lua','Midi_Sampler.norm_val',DefMIDI_Mode,true);
      r.SetExtState('cool_MK_Shaper/Stutter.lua','Sampler_preset.norm_val',DefSampler_preset_state,true);
      r.SetExtState('cool_MK_Shaper/Stutter.lua','XFadeOff',DefXFadeOff,true);
      r.SetExtState('cool_MK_Shaper/Stutter.lua','Gate_VeloScale.norm_val',DefGate_VeloScale,true);
      r.SetExtState('cool_MK_Shaper/Stutter.lua','Gate_VeloScale.norm_val2',DefGate_VeloScale2,true);

end


item22 = context_menu:add_item({label = "|Reset Window Size", toggleable = false})
item22.command = function()
store_window()
           xpos = r.GetExtState("cool_MK_Shaper/Stutter.lua", "window_x") or 400
           ypos = r.GetExtState("cool_MK_Shaper/Stutter.lua", "window_y") or 320
    local Wnd_Dock, Wnd_X,Wnd_Y = dock_pos, xpos, ypos
    Wnd_W,Wnd_H = 1044,490 -- global values(used for define zoom level)
    -- Re-Init window ------
    gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )
    gfx.update()

end

----------------------------end of context menu--------------------------------

 mainloop_settings()

------------------------------User Defaults form--------------------------------
function user_defaults()
::first_string::
DefaultXFadeTime = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultXFadeTime'))or 15;
DefaultQStrength = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultQStrength'))or 100;
DefaultHP = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultHP'))or 0.3312;
DefaultLP = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultLP'))or 1;
DefaultSens = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultSens'))or 0.375;
DefaultOffset = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','DefaultOffset'))or 0.5;
MIDI_Base_Oct = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','MIDI_Base_Oct'))or 2;
Trigger_Oct_Shift  = tonumber(r.GetExtState('cool_MK_Shaper/Stutter.lua','Trigger_Oct_Shift'))or 0;

function toHertz(val) --  val to hz
  local sxx = 16+(val*100)*1.20103
  return floor(exp(sxx*logx(1.059))*8.17742) 
end;

  DefaultLP = toHertz(DefaultLP)
  DefaultHP = toHertz(DefaultHP)

  DefaultSens = 2+(DefaultSens)*8
  DefaultOffset = (100- DefaultOffset * 200)*( -1)

math_round = function(num, idp) -- rounding
  local mult = 10^(idp or 0)
  return floor(num * mult + 0.5) / mult
end

  DefaultSens = math_round(DefaultSens, 1)
  DefaultOffset = math_round(DefaultOffset, 1)
  DefaultXFadeTime = ceil(DefaultXFadeTime)
  DefaultQStrength = ceil(DefaultQStrength)
  MIDI_Base_Oct = floor(MIDI_Base_Oct)
  Trigger_Oct_Shift = floor(Trigger_Oct_Shift)

local values = tostring(DefaultXFadeTime)
..","..tostring(DefaultQStrength)
..","..tostring(DefaultHP)
..","..tostring(DefaultLP)
..","..tostring(DefaultSens)
..","..tostring(DefaultOffset)
..","..tostring(MIDI_Base_Oct)
..","..tostring(Trigger_Oct_Shift)

local retval, value = r.GetUserInputs("User Defaults", 8, "--Reserved-- ,Quantize Strength (0 - 100) % ,LowCut Slider (20 - 20000) Hz ,High Cut Slider (20 - 20000) Hz ,Sensitivity (2 - 10) dB ,Offset Slider (-100 - +100) ,--Reserved-- ,--Reserved-- ", values)
   if retval then
     local val1, val2, val3, val4, val5, val6, val7, val8 = value:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")

      DefaultXFadeTime2 = tonumber(val1)
      DefaultQStrength2 = tonumber(val2)
      DefaultHP2 = tonumber(val3)
      DefaultLP2 = tonumber(val4)
      DefaultSens2 = tonumber(val5)
      DefaultOffset2 = tonumber(val6)
      MIDI_Base_Oct2 = tonumber(val7)
      Trigger_Oct_Shift2 = tonumber(val8)

     if not DefaultXFadeTime2 or not DefaultQStrength2 or not DefaultOffset2 or not DefaultHP2 or not DefaultLP2 or not MIDI_Base_Oct2 or not DefaultSens2 or not Trigger_Oct_Shift2 then 
     r.MB('Please enter a number', 'Error', 0) goto first_string end

if DefaultXFadeTime2 < 0 then DefaultXFadeTime2 = 0 elseif DefaultXFadeTime2 > 50 then DefaultXFadeTime2 = 50 end
if DefaultQStrength2 < 0 then DefaultQStrength2 = 0 elseif DefaultQStrength2 > 100 then DefaultQStrength2 = 100 end
if DefaultHP2 < 20 then DefaultHP2 = 20 elseif DefaultHP2 > 20000 then DefaultHP2 = 20000 end
if DefaultLP2 < 20 then DefaultLP2 = 20 elseif DefaultLP2 > 20000 then DefaultLP2 = 20000 end
if DefaultSens2 < 2 then DefaultSens2 = 2 elseif DefaultSens2 > 10 then DefaultSens2 = 10 end
if DefaultOffset2 < -100 then DefaultOffset2 = -100 elseif DefaultOffset2 > 100 then DefaultOffset2 = 100 end
if MIDI_Base_Oct2 < 0 then MIDI_Base_Oct2 = 0 elseif MIDI_Base_Oct2 > 9 then MIDI_Base_Oct2 = 9 end
if Trigger_Oct_Shift2 < -2 then Trigger_Oct_Shift2 = -2 elseif Trigger_Oct_Shift2 > 7 then Trigger_Oct_Shift2 = 7 end

local function fromHertz(val); -- hz to val
    local a,b,c = 20,639.3,20000;
    local d = ((c-b)/(b-a))^2;
    return logx(1-((1-d)/(c-a))*(val-a),d);
end;

DefaultLP2 = fromHertz(DefaultLP2)
DefaultHP2 = fromHertz(DefaultHP2)
DefaultSens2 = (DefaultSens2-2)/8
DefaultOffset2 = ((DefaultOffset2/100)+1)/2

          r.SetExtState('cool_MK_Shaper/Stutter.lua','DefaultXFadeTime',DefaultXFadeTime2,true);
          r.SetExtState('cool_MK_Shaper/Stutter.lua','DefaultQStrength',DefaultQStrength2,true);
          r.SetExtState('cool_MK_Shaper/Stutter.lua','DefaultLP',DefaultLP2,true);
          r.SetExtState('cool_MK_Shaper/Stutter.lua','DefaultHP',DefaultHP2,true);
          r.SetExtState('cool_MK_Shaper/Stutter.lua','DefaultSens',DefaultSens2,true);
          r.SetExtState('cool_MK_Shaper/Stutter.lua','DefaultOffset',DefaultOffset2,true);
          r.SetExtState('cool_MK_Shaper/Stutter.lua','MIDI_Base_Oct',MIDI_Base_Oct2,true);
  --        r.SetExtState('cool_MK_Shaper/Stutter.lua','Trigger_Oct_Shift',Trigger_Oct_Shift2,true);

end
end
-----------------------end of User Defaults form--------------------------------

function ClearExState() 
----------- Delete Created Item --------------
if NoItems == 1 then
    for tr, trck in pairs(Table) do
        if trck then 
             for it, del_it in pairs(Table2) do
                if del_it then 
                   reaper.DeleteTrackMediaItem(tr, it)
                   reaper.UpdateArrange()
                   NoItems = 0
                end
             end    
        end
    end
end
------------------------------------
r.DeleteExtState('_Slicer_', 'ItemToSlice', 0)
r.DeleteExtState('_Slicer_', 'TrackForSlice', 0)
r.SetExtState('_Slicer_', 'GetItemState', 'ItemNotLoaded', 0)
store_settings()
  if loopcheck == 0 then
      r.GetSet_LoopTimeRange(true, true, 0, 0, false)
  end
  if Reset_to_def == 0 then
     store_settings2()
  end
store_window()
SetButtonOFF()
  if EnvItemOnClose == 1 and TrackEnv == 1 then
              if VolPreFX == 1 then
                  r.Main_OnCommand(41865,0)--Envelope: select Vol Pre-FX
                   else
                  r.Main_OnCommand(41866,0)--Envelope: select Vol
              end
         r.Main_OnCommand(42082, 0) --create env item
  end
end

r.atexit(ClearExState)

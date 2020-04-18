-- @description MK Slicer
-- @author cool
-- @version 1.4.4
-- @changelog
--   + Bugfix: now the step of the quantization grid is independent of zoom.
--   + Added experimental option to disable XFades and Fill Gaps
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=232672
-- @screenshot MK Slicer Main View https://i.imgur.com/5jkmMRL.png
-- @donation
--   Donate via PayPal https://www.paypal.me/MKokarev
--   Donate via Yandex https://money.yandex.ru/to/41001256406969
-- @about
--   # MK Slicer
--
--   This is a lua script for quick slicing, quantizing by grid, re-quantizing, triggering or sampling audio.
--
--   Key features:
--
--    - Advanced detector. Thanks to filters and good visualization, you can precisely cut even material in which transients are not initially visualized.
--    - Quick Slicing or placing Markers (by Transients or by Grid).
--    - One click Quantize by Grid. Without gaps, clicks and artificial duplication of items.
--    - Ability to work with multitracks. Slices and quantizes your multitrack drums phase-accurate, quickly and without pain. Items in the multitrack will be automatically grouped.
--    - Re-Quantizing. When quantizing with a grid larger than the step of the transients, you can re-quantize your loops to get unique material. 
--    - One click sampling and exporting into RS5k.
--    - Good old Trigger. Easy conversion of rhythmic parts to midi patterns with accurate velocity reproduction.
--    - Advanced interface. Intuitive controls. Resetting values to defaults by Ctrl+Click. Change operations on-the-fly without the need of Undo.
--    - Adaptive initial settings. Upon initialization, the script sets the View Gain, Threshold, and Retrig settings depending on the material and tempo of the project.
--
--   Instructions for use:
--
--   1. Select an item or several items on the same track. The script will not run if items are placed on different tracks.
--   2. Run the script.
--   3. Do your work.
--   4. To cancel an actions, use Reset or just Ctrl + Z. Reset sliders to default: Ctrl + Click. Fine tune: Shift + Drag. Exit the script: Esc, Space - Play. 
--
--     On Waveform Area:
--     Mouswheel or Left/Right keys - Horizontal Zoom,
--     Ctrl(Shift)+Mouswheel or Up/Down keys - Vertical Zoom,
--     Middle Drag - Move View (Scroll),
--     Left Click - Set Edit Cursor,
--     Shift+Left Drag - Move Marker,
--     Ctrl+Left Drag - Change Velocity,
--     Shift+Ctrl+Left Drag - Move Marker and Change Velocity,
--     Right Click on Marker - Delete Marker,
--     Right Click on Empty Space - Insert Marker.
--
--   Working with multitrack:
--
--   0. Before starting the work, I recommend you to create a guide track - usually a mixdown kick, snare and toms tracks together in one track. This track will be used as a “lead” for the detector to operate more accurately After the work is completed, you can delete it.
--   1. Select one (guide) item. The script will not run if items are placed on different tracks.
--   2. Run the script.
--   3. Select the rest items in the multitrack - you can do it with the help of Marque Selection or even Ctrl+A - it will make no difference. Your workspace will be set equal to the length of an item selected at the moment you start the script. 
--   4. Do your work. When a slicing or placing markers occurs on a multitrack, items will be automatically added to Groups.
--
--
--   Important.
--
--   For the machanism Reset to operate correctly and for the operations on-the-fly to follow each other smoothly, it is OBLIGATORY for the items to start from the beginning of the bar. It's the condition which ensures comfortable work without surprises like a sudden move of the items after the following quantization. Additionaly, I don't recommend to change selection manually or do anything with the items while the script is working. Also, do not forget to save your project regularly. Just in case.
--
--   Sometimes a script applies glue to items. For example, when several items are selected and when a MIDI is created in a sampler mode.

--[[
MK Slicer v1.4.4 by Maxim Kokarev 
https://forum.cockos.com/member.php?u=121750

Co-Author of the compilation - MyDaw
https://www.facebook.com/MyDawEdition/

"Remove selected overlapped items (by tracks)" 
"Remove final selected item in tracks"
"Unselect all items except first selected in track"
scripts by Archie
https://forum.cockos.com/member.php?u=120700

Based on "Drums to MIDI(beta version)" script by eugen2777   
http://forum.cockos.com/member.php?u=50462  

Export to ReaSamplOmatic5000 function from RS5k manager by MPL 
https://forum.cockos.com/showthread.php?t=207971  
]]

-------------------------------------------------------------------------------
-- Some functions(local functions work faster in big cicles(~30%)) ------------
-- R.Ierusalimschy - "lua Performance Tips" -----------------------------------
-------------------------------------------------------------------------------
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

----------------------------Advanced Settings-------------------------------------------

RememberLast = 1            -- (Remember some sliders positions from last session. 1 - On, 0 - Off)
AutoXFadesOnSplitOverride = 1 -- (Override "Options: Toggle auto-crossfade on split" option. 0 - Don't Override, 1 - Override)
ItemFadesOverride = 1 -- (Override "Item: Toggle enable/disable default fadein/fadeout" option. 0 - Don't Override, 1 - Override)

------------------------End of Advanced Settings----------------------------------------

-----------------------------------States and UA  protection-----------------------------

Docked = tonumber(r.GetExtState('cool_MK Slicer.lua','Docked'))or 0;
EscToExit = tonumber(r.GetExtState('cool_MK Slicer.lua','EscToExit'))or 1;
MIDISamplerCopyFX = tonumber(r.GetExtState('cool_MK Slicer.lua','MIDISamplerCopyFX'))or 1;
MIDISamplerCopyRouting = tonumber(r.GetExtState('cool_MK Slicer.lua','MIDISamplerCopyRouting'))or 1;
MIDI_Mode = tonumber(r.GetExtState('cool_MK Slicer.lua','MIDI_Mode'))or 0;
AutoScroll = tonumber(r.GetExtState('cool_MK Slicer.lua','AutoScroll'))or 0;
SnapToStart = tonumber(r.GetExtState('cool_MK Slicer.lua','SnapToStart'))or 1;
ObeyingTheSelection = tonumber(r.GetExtState('cool_MK Slicer.lua','ObeyingTheSelection'))or 1;
ObeyingItemSelection = tonumber(r.GetExtState('cool_MK Slicer.lua','ObeyingItemSelection'))or 1;
XFadeOff = tonumber(r.GetExtState('cool_MK Slicer.lua','XFadeOff'))or 0;

if AutoXFadesOnSplitOverride == nil then AutoXFadesOnSplitOverride = 1 end 
if AutoXFadesOnSplitOverride < 0 then AutoXFadesOnSplitOverride = 0 elseif AutoXFadesOnSplitOverride > 1 then AutoXFadesOnSplitOverride = 1 end 
if ItemFadesOverride == nil then ItemFadesOverride = 1 end 
if ItemFadesOverride < 0 then ItemFadesOverride = 0 elseif ItemFadesOverride > 1 then ItemFadesOverride = 1 end 
if RememberLast == nil then RememberLast = 1 end 
if RememberLast < 0 then RememberLast = 0 elseif RememberLast > 1 then RememberLast = 1 end 

-------------------------------Check time range and unselect-----------------------------

function unselect_if_out_of_time_range()

local j=0; -- unselect if out of time range 
while(true) do;
  j=j+1;
  local track = r.GetSelectedTrack(0,j-1);
  if track then;
      start, ending = r.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
      local i=0; 
      while(true) do;
        i=i+1;
        local item = r.GetSelectedMediaItem(0,i-1);
        if item then;
               item_pos =  r.GetMediaItemInfo_Value( item, 'D_POSITION' )
               item_length = r.GetMediaItemInfo_Value( item, 'D_LENGTH' )
               item_end = item_pos + item_length
        if item_pos ~= start and item_end ~= ending then
              r.SetMediaItemSelected(item, false)
        end
        if item_pos > start and item_end < ending then
               r.SetMediaItemSelected(item, true)
        end
      else;
        break;
    end;
  end;
 else;
   break;
 end;
end;

end
------------------------------Detect MIDI takes-------------------------------------------

function take_check()
local i=0;
while(true) do;
  i=i+1;
  local item = r.GetSelectedMediaItem(0,i-1);
  if item then;
  active_take = r.GetActiveTake(item)  -- active take in item
    if r.TakeIsMIDI(active_take) then Take_Check = 1 end
  else;
    break;
  end;
end;

end
-------------------------------------------------------------------------------------------
function sel_tracks_items() --Select only tracks of selected items

	UnselectAllTracks()
	selected_items_count = r.CountSelectedMediaItems(0)

	for i = 0, selected_items_count - 1  do
		item = r.GetSelectedMediaItem(0, i) -- Get selected item i
		track = r.GetMediaItem_Track(item)
		r.SetTrackSelected(track, true)				
	end 
end

function UnselectAllTracks()
	first_track = r.GetTrack(0, 0)
          if first_track then
	      r.SetOnlyTrackSelected(first_track)
	      r.SetTrackSelected(first_track, false)
          end
end

    r.Undo_BeginBlock() 
r.PreventUIRefresh(1)

if ObeyingItemSelection == 1 then
sel_tracks_items()
end
-------------------------------------------------------------------------------------------
r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVESEL'), 0)  -- Save track selection
-----------------------------------ObeyingTheSelection------------------------------------



function collect_param()    -- collect parameters
   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item 
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   src = r.GetMediaItemTake_Source(active_take)
   srate =  r.GetMediaSourceSampleRate(src) -- take samplerate (simple wave/MIDI detection)
 end

collect_param()
start, ending = r.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
time_sel_length = ending - start
if ObeyingTheSelection == 1 and ObeyingItemSelection == 0 and start ~= ending then
    r.Main_OnCommand(40289, 0) -- Item: Unselect all items
          if time_sel_length > 0.25 and selected_tracks_count == 1 then
              r.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
          end
end

count_itms =  r.CountSelectedMediaItems(0)
if ObeyingTheSelection == 1 and count_itms ~= 0 and start ~= ending and time_sel_length > 0.25 then
   take_check()
   if Take_Check ~= 1 and selected_tracks_count == 1 then

    --------------------------------------------------------
    local function no_undo() r.defer(function()end)end;
    --------------------------------------------------------
    
    local startTSel,endTSel = r.GetSet_LoopTimeRange(0,0,0,0,0);
    if startTSel == endTSel then no_undo() return end;
    
    local CountSelItem = r.CountSelectedMediaItems(0);
    if CountSelItem == 0 then no_undo() return end;
    
    local TMSL,UNDO;
    for t = CountSelItem-1,0,-1 do;
        local item = r.GetSelectedMediaItem(0,t);
        local posIt = r.GetMediaItemInfo_Value(item,"D_POSITION");
        local lenIt = r.GetMediaItemInfo_Value(item, "D_LENGTH");
        if posIt < endTSel and posIt+lenIt > startTSel then;
            TMSL = true;
            if not UNDO then;
                r.Undo_BeginBlock();
                r.PreventUIRefresh(1);
                UNDO = true;
            end;
        end;
        if posIt < endTSel and posIt+lenIt > endTSel then;
            r.SplitMediaItem(item,endTSel);
        end;
        if posIt < startTSel and posIt+lenIt > startTSel then;
            r.SplitMediaItem(item,startTSel);
        end;
    end;
    
    if TMSL then;
        for t = r.CountSelectedMediaItems(0)-1,0,-1 do;
            local item = r.GetSelectedMediaItem(0,t);
            local posIt = r.GetMediaItemInfo_Value(item,"D_POSITION");
            local lenIt = r.GetMediaItemInfo_Value(item, "D_LENGTH");
            if posIt >= endTSel or posIt+lenIt <= startTSel then;
                r.SetMediaItemInfo_Value(item,'B_UISEL',0);
            end;
        end;
    end;
    
    if UNDO then;
         r.PreventUIRefresh(-1);
         r.Undo_EndBlock("Split items by time selection,unselect with items outside of time selection if there is selection inside",-1);
    else;
        no_undo();
    end;    
    r.UpdateArrange();

        collect_param()  
        if number_of_takes ~= 1 and srate ~= nil then
           r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то клей, попытка не деструктивно склеить).
        end
       collect_param()    
       if number_of_takes ~= 1 and srate ~= nil then -- проверяем ещё раз. Если не удалось, клеим деструктивно.
           r.Main_OnCommand(41588, 0) -- glue (если больше одного айтема и не миди айтем, то клей).
       end
   end
end

-----------------------------------------------------------------------------------------------------

local cursorpos = r.GetCursorPosition()

            r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVETIME1"),0)
            r.Main_OnCommand(40290, 0) -- Set time selection to item
            r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVETIME2"),0)
            r.Main_OnCommand(40635, 0)     -- Remove Selection
            r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME1"),0)

r.SetEditCurPos(cursorpos,0,0) 
r.PreventUIRefresh(-1)
    r.Undo_EndBlock("Init", -1) 

------------------------------Prepare Item(s) and Foolproof---------------------------------



sel_tracks_items() 

function collect_itemtake_param()    -- collect parameter on sel item and active take for SM tables and displacement calcs...
   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item 
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   src = r.GetMediaItemTake_Source(active_take)
   srate =  r.GetMediaSourceSampleRate(src) -- take samplerate (simple wave/MIDI detection)
   mute_check = r.GetMediaItemInfo_Value(sel_item, "B_MUTE")
 end
 

   collect_itemtake_param()              -- get bunch of parameters about this item

if selected_tracks_count > 1 then 
gfx.quit() 
r.ShowConsoleMsg("Only single track items, please. User manual: https://forum.cockos.com/showthread.php?t=232672")
return 
end -- не запускать, если айтемы находятся на разных треках.

local i=0;
while(true) do;
  i=i+1;
  local item = r.GetSelectedMediaItem(0,i-1);
  if item then;
  active_take = r.GetActiveTake(item)  -- active take in item
    if r.TakeIsMIDI(active_take) then 
       gfx.quit() 
       r.ShowConsoleMsg("Only Wave items, please. Additional help: https://forum.cockos.com/showthread.php?t=232672") 
       return 
    end
  else;
    break;
  end;
end;

 if number_of_takes ~= 1 and srate ~= nil then
 
r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то клей, попытка не деструктивно склеить).

end

   collect_itemtake_param()    

 if number_of_takes ~= 1 and srate ~= nil then -- проверяем ещё раз. Если не удалось, клеим деструктивно.
 
 r.Main_OnCommand(41588, 0) -- glue (если больше одного айтема и не миди айтем, то клей).
  
  end
------------------------------------------------------------------------------------------
r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTORESEL'), 0)  -- Restore track selection
----------------------------------Get States from last session-----------------------------

if RememberLast == 1 then
CrossfadeTime = tonumber(r.GetExtState('cool_MK Slicer.lua','CrossfadeTime'))or 15;
QuantizeStrength = tonumber(r.GetExtState('cool_MK Slicer.lua','QuantizeStrength'))or 100;
Offs_Slider = tonumber(r.GetExtState('cool_MK Slicer.lua','Offs_Slider'))or 0.5;
HF_Slider = tonumber(r.GetExtState('cool_MK Slicer.lua','HF_Slider'))or 0.3312;
LF_Slider = tonumber(r.GetExtState('cool_MK Slicer.lua','LF_Slider'))or 1;
Sens_Slider = tonumber(r.GetExtState('cool_MK Slicer.lua','Sens_Slider'))or 0.375;
else
CrossfadeTime = DefaultXFadeTime or 15;
QuantizeStrength = DefaultQStrength or 100;
Offs_Slider = DefaultOffset or 0.5;
HF_Slider = DefaultHP or 0.3312;
LF_Slider = DefaultLP or 1;
Sens_Slider = DefaultSens or 0.375;
end

------------------Item;  Remove selected overlapped items (by tracks)----------------------

function cleanup_slices() 

     -------------------------------------------------------
    local function no_undo()r.defer(function()end)end;
    -------------------------------------------------------
    
    local CountSelItem = r.CountSelectedMediaItems(0);
    if CountSelItem == 0 then return end;
    
    local t = {};
    local tblTrack = {};
    local UNDO;
    
    for i = 1, CountSelItem do;
        local item = r.GetSelectedMediaItem(0,i-1);
        local track = r.GetMediaItem_Track(item);
        if not t[tostring(track)]then;
            t[tostring(track)] = track;
            tblTrack[#tblTrack+1] = track;
        end;
    end;
       
    for iTr = 1, #tblTrack do;
        
        local t = {};
        local rem = {};
        
        local CountTrItem = r.CountTrackMediaItems(tblTrack[iTr]);
        for iIt = 1, CountTrItem do;
            local itemTr = r.GetTrackMediaItem(tblTrack[iTr],iIt-1);
            local sel = r.IsMediaItemSelected(itemTr);
            if sel then;
                
                local posIt = r.GetMediaItemInfo_Value(itemTr,'D_POSITION');
                posIt = floor(posIt*1000)/1000;
                
                if not t[posIt] then;
                    t[posIt] = posIt;
                else;
                    rem[#rem+1] = {};
                    rem[#rem].track = tblTrack[iTr];
                    rem[#rem].item = itemTr;
                end;
            end;
        end;
        
        for iDel = 1, #rem do;
            local Del = r.DeleteTrackMediaItem(rem[iDel].track,rem[iDel].item);
            if not UNDO and Del then;
                r.Undo_BeginBlock();
                r.PreventUIRefresh(1);
                UNDO = true;
            end;
        end;
    end;

    if UNDO then;
        r.PreventUIRefresh(-1);
        r.Undo_EndBlock("Remove selected overlapped items",-1);
    else;
        no_undo();
    end;

end

-------------------------Copy/Paste Sends/Returns---------------------------------------
---------------------------------------------------
    local function copyReceiveTrack(track,desttrIn,i);
        if i>r.GetTrackNumSends(track,-1)-1 then return end;
        local t={'P_SRCTRACK','I_MIDIFLAGS','I_DSTCHAN','I_SRCCHAN','I_AUTOMODE',
              'I_SENDMODE','D_PANLAW','D_PAN','D_VOL','B_MONO','B_PHASE','B_MUTE'};
        local t2 = {};
        for j = 1,#t do;
            t2[j] = r.GetTrackSendInfo_Value(track,-1,i,t[j]);
        end;
        local SendNew = r.CreateTrackSend(t2[1],desttrIn);
        for j = 2,#t do;
            r.SetTrackSendInfo_Value(t2[1],0,SendNew,t[j],t2[j]);
        end;
    end;
    ---------------------------------------------------
    local function copySendTrack(track,desttrIn,i);
        if i>r.GetTrackNumSends(track,0)-1 then return end;
        local t={'P_DESTTRACK','I_MIDIFLAGS','I_DSTCHAN','I_SRCCHAN','I_AUTOMODE',
              'I_SENDMODE','D_PANLAW','D_PAN','D_VOL','B_MONO','B_PHASE','B_MUTE'};
        local t2 = {};
        for j = 1,#t do;
            t2[j] = r.GetTrackSendInfo_Value(track,0,i,t[j]);
        end;
        local SendNew = r.CreateTrackSend(desttrIn,t2[1]);
        for j = 2,#t do;
            r.SetTrackSendInfo_Value(desttrIn,0,SendNew,t[j],t2[j]);
        end;
    end;
    ---------------------------------------------------
--------------------------------------------------------------------------------------------

function getsomerms()

r.Undo_BeginBlock(); r.PreventUIRefresh(1)
 
local itemproc = r.GetSelectedMediaItem(0,0)

 if itemproc  then

       local tk = r.GetActiveTake(itemproc)

 function get_average_rms(take, adj_for_take_vol, adj_for_item_vol)
   local RMS_t = {}
   if take == nil then
     return
   end
   
   local item = r.GetMediaItemTake_Item(take) -- Get parent item
   if item == nil then
     return
   end

   -- Get media source of media item take
   local take_pcm_source = r.GetMediaItemTake_Source(take)
   if take_pcm_source == nil then
     return
   end
   
   -- Create take audio accessor
   local aa = r.CreateTakeAudioAccessor(take)
   if aa == nil then
     return
   end
   
   -- Get the start time of the audio that can be returned from this accessor
   local aa_start = r.GetAudioAccessorStartTime(aa)
   -- Get the end time of the audio that can be returned from this accessor
   local aa_end = r.GetAudioAccessorEndTime(aa)
    a_length = (aa_end - aa_start)/25
      if a_length <= 1 then a_length = 1 elseif a_length > 20 then a_length = 20
end
            
   -- Get the number of channels in the source media.
   local take_source_num_channels =  r.GetMediaSourceNumChannels(take_pcm_source)
          if take_source_num_channels > 2 then take_source_num_channels = 2 end
   local channel_data = {} -- channel data is collected to this table
   -- Initialize channel_data table
   for i=1, take_source_num_channels do
     channel_data[i] = {
                         rms = 0,
                         sum_squares = 0 -- (for calculating RMS per channel)
                       }
   end
     
   -- Get the sample rate. MIDI source media will return zero.
   local take_source_sample_rate = r.GetMediaSourceSampleRate(take_pcm_source)
   if take_source_sample_rate == 0 then
     return
   end
 
   -- How many samples are taken from audio accessor and put in the buffer
   local samples_per_channel = take_source_sample_rate/10
   
   -- Samples are collected to this buffer
   local buffer = r.new_array(samples_per_channel * take_source_num_channels)
   
   total_samples = (aa_end - aa_start) * (take_source_sample_rate/a_length)
   
   if total_samples < 1 then
     return
   end

   local block = 0
   local sample_count = 0
   local offs = aa_start
   
   local log10 = function(x) return logx(x, 10) end

   -- Loop through samples
   while sample_count < total_samples do
 
     -- Get a block of samples from the audio accessor.
     -- Samples are extracted immediately pre-FX,
     -- and returned interleaved (first sample of first channel, 
     -- first sample of second channel...). Returns 0 if no audio, 1 if audio, -1 on error.
     local aa_ret = 
             r.GetAudioAccessorSamples(
                                             aa,                       -- AudioAccessor accessor
                                             take_source_sample_rate,  -- integer samplerate
                                             take_source_num_channels, -- integer numchannels
                                             offs,                     -- number starttime_sec
                                             samples_per_channel,      -- integer numsamplesperchannel
                                             buffer                    -- r.array samplebuffer
                                           )
       
     if aa_ret == 1 then
       for i=1, #buffer, take_source_num_channels do
         if sample_count == total_samples then
           audio_end_reached = true
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
     
     block = block + 1
     offs = offs + samples_per_channel / take_source_sample_rate -- new offset in take source (seconds)
   end -- end of while loop
   
   r.DestroyAudioAccessor(aa)
    
   -- Calculate corrections for take/item volume
   local adjust_vol = 1
   
   if adj_for_take_vol then
     adjust_vol = adjust_vol * r.GetMediaItemTakeInfo_Value(take, "D_VOL")
   end
   
   if adj_for_item_vol then
     adjust_vol = adjust_vol * r.GetMediaItemInfo_Value(item, "D_VOL")
   end
   
   -- Calculate RMS for each channel
   for i=1, take_source_num_channels do
     local curr_ch = channel_data[i]
     curr_ch.rms = sqrt(curr_ch.sum_squares/total_samples) * adjust_vol
       RMS_t[i] = 20*log10(curr_ch.rms)
   end
   return RMS_t
 end
 
 getrms = get_average_rms( tk, 0, 0, 0, 0)

 ----------------------------------------------------------------------------------
 
 for i=1, #getrms do
 rms = ceil(getrms[i])
 end

if rms == "-1.#INF" then return end
if srate == nil then rms = -17 end

rmsresult = string.sub(rms,1,string.find(rms,'.')+5)

if rmsresult == "-1.#IN" then 
rmsresult  = -30
gfx.quit()
 end

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
exept = 1

function GetTempo()
tempo = r.Master_GetTempo()
retoffset = (60000/tempo)/16 - 20
retrigms = retoffset*0.00493 or 0.0555
end
GetTempo()

r.PreventUIRefresh(-1); r.Undo_EndBlock('Slicer', -1)

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
    elm.fnt_rgba = fnt_rgba or {0.8, 0.8, 0.8, 1} --цвет текста кнопок, фреймов и слайдеров
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
  self.x, self.w = ceil(self.def_xywh[1]* Z_w) , ceil(self.def_xywh[3]* Z_w) -- upd x,w
  self.y, self.h = ceil(self.def_xywh[2]* Z_h) , ceil(self.def_xywh[4]* Z_h) -- upd y,h
  if self.fnt_sz then --fix it!--
     self.fnt_sz = max(16,self.def_xywh[5]* (Z_w+Z_h)/1.9)
     self.fnt_sz = min(22,self.fnt_sz* Z_h)
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
  gfx.rect(x, y, w, h, false)            -- frame1
  gfx.roundrect(x, y, w-1, h-1, 3, true) -- frame2         
end

function Element:draw_rect()
  local x,y,w,h  = self.x,self.y,self.w,self.h
  gfx.set(0.1,0.1,0.1,1) -- цвет фона окна waveform
  gfx.rect(x, y, w, h, true)            -- frame1
  gfx.roundrect(x, y, w-1, h-1, 3, true) -- frame2         
end

----------------------------------------------------------------------------------------------------
---   Create Element Child Classes(Button,Slider,Knob)   -------------------------------------------
----------------------------------------------------------------------------------------------------
local XButton,ZButton, Button, Button_Settings, Slider, Rng_Slider, Knob, CheckBox, Frame, ErrMsg, Txt = {},{},{},{},{},{},{},{},{},{},{}
  extended(Button,     Element)
  extended(Button_Settings,     Element)
  extended(Knob,       Element)
  extended(Slider,     Element)
  extended(ZButton,     Element)
  extended(XButton,     Element)
  extended(ErrMsg,     Element)
  extended(Txt,     Element)
    -- Create Slider Child Classes --
    local H_Slider, V_Slider, T_Slider, HP_Slider, LP_Slider, G_Slider, S_Slider, Rtg_Slider, Rdc_Slider, O_Slider, Q_Slider, X_Slider, X_SliderOff = {},{},{},{},{},{},{},{},{},{},{},{},{}
    extended(H_Slider, Slider)
    extended(V_Slider, Slider)
    extended(T_Slider, Slider)
    extended(HP_Slider, Slider)
    extended(LP_Slider, Slider)
    extended(G_Slider, Slider)
    extended(S_Slider, Slider)
    extended(Rtg_Slider, Slider)
    extended(Rdc_Slider, Slider)
    extended(O_Slider, Slider)
    extended(Q_Slider, Slider)
    extended(X_Slider, Slider)
    extended(X_SliderOff, Slider)
    ---------------------------------
  extended(Rng_Slider, Element)
  extended(Frame,      Element)
  extended(CheckBox,   Element)

--------------------------------------------------------------------------------  
--------------------------------------------------------------------------------
---   Buttons Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function Button:draw_body()
    gfx.rect(self.x,self.y,self.w,self.h, true) -- draw btn body
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
    local fnt,fnt_sz = self.fnt, self.fnt_sz
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
    self:draw_frame()   -- frame
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
  self.x, self.w = ceil(self.def_xywh[1]* (Z_w/2)) , ceil(self.def_xywh[3]* (Z_w/2)) -- upd x,w
  self.y, self.h = ceil(self.def_xywh[2]* (Z_h/2)) , ceil(self.def_xywh[4]* (Z_h/2)) -- upd y,h
  if self.fnt_sz then --fix it!--
     self.fnt_sz = max(16,self.def_xywh[5]* (Z_w+Z_h)/2)
     self.fnt_sz = min(26,self.fnt_sz* Z_h)
  end    
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
          -- in element --------
          SButton = 0
          MenuCall = 0
          if self:mouseIN() then 
          a=a+0.1 
          SButton = 1
          end
          -- in elm L_down -----
          if self:mouseDown() then 
          a=a-0.1 
          SButton = 1
          MenuCall = 1
          end
          -- in elm L_up(released and was previously pressed) --
          if self:mouseClick() and self.onClick then self.onClick() end

    -- Draw btn body, frame ----
    gfx.set(r,g,b,a)    -- set body color
    self:draw_body()    -- body
    self:draw_frame()   -- frame
    -- Draw label --------------
    gfx.set(table.unpack(self.fnt_rgba))   -- set label color
    gfx.setfont(1, fnt, fnt_sz) -- set label fnt
    self:draw_lbl()             -- draw lbl
end

-------------------------------------------------------------------------------- 
--------------------------------------------------------------------------------
---   Txt Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
------------------------
function Txt:draw()

    self:update_xywh() -- Update xywh(if wind changed)
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+(h-lbl_h)/2
    gfx.set(0.8, 0.8, 0.8, 1)   -- set label color
    gfx.drawstr(self.lbl)

end

--------------------------------------------------------------------------------  
--------------------------------------------------------------------------------
---   ErrMsg Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
------------------------
function ErrMsg:draw()

    self:update_xywh() -- Update xywh(if wind changed)
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+(h-lbl_h)/2
    gfx.set(0.8, 0.3, 0.3, 1)   -- set label color
    gfx.drawstr(self.lbl)

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Slider Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function Slider:set_norm_val_m_wheel()
    local Step = 0.05 -- Set step
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1) end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0) end
    return true
end
-------------------------------------------------------------------------------------
function H_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
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
    DefaultHP = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultHP'))or 0.3312;
    if MCtrl then VAL = DefaultHP end --set default value by Ctrl+LMB
    self.norm_val=VAL

if RememberLast == 1 then 
    local SAVE_VAL = VAL;
    if tonumber(r.GetExtState('cool_MK Slicer.lua','HF_Slider'))or 0 ~= SAVE_VAL then;
        r.SetExtState('cool_MK Slicer.lua','HF_Slider',SAVE_VAL,true);
    end;
else
HF_Slider = DefaultHP
end
end
function LP_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    DefaultLP = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultLP'))or 1;
    if MCtrl then VAL = DefaultLP end --set default value by Ctrl+LMB
    self.norm_val=VAL

if RememberLast == 1 then 
    local SAVE_VAL = VAL;
    if tonumber(r.GetExtState('cool_MK Slicer.lua','LF_Slider'))or 0 ~= SAVE_VAL then;
        r.SetExtState('cool_MK Slicer.lua','LF_Slider',SAVE_VAL,true);
    end;
else
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
    DefaultSens = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultSens'))or 0.375;
    if MCtrl then VAL = DefaultSens end --set default value by Ctrl+LMB
    self.norm_val=VAL

if RememberLast == 1 then 
    local SAVE_VAL = VAL;
    if tonumber(r.GetExtState('cool_MK Slicer.lua','Sens_Slider'))or 0 ~= SAVE_VAL then;
        r.SetExtState('cool_MK Slicer.lua','Sens_Slider',SAVE_VAL,true);
    end;
else
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
    DefaultOffset = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultOffset'))or 0.5;
    if MCtrl then VAL = DefaultOffset end --set default value by Ctrl+LMB
    self.norm_val=VAL

if RememberLast == 1 then 
    local SAVE_VAL = VAL;
    if tonumber(r.GetExtState('cool_MK Slicer.lua','Offs_Slider'))or 0 ~= SAVE_VAL then;
        r.SetExtState('cool_MK Slicer.lua','Offs_Slider',SAVE_VAL,true);
    end;
else
Offs_Slider = DefaultOffset
end
end
function Q_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    DefaultQStrength = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultQStrength'))or 100;
    if MCtrl then VAL = DefaultQStrength*0.01 end --set default value by Ctrl+LMB
    self.norm_val=VAL

if RememberLast == 1 then 
    local SAVE_VAL = VAL*100;
    if tonumber(r.GetExtState('cool_MK Slicer.lua','QuantizeStrength'))or 0 ~= SAVE_VAL then;
        r.SetExtState('cool_MK Slicer.lua','QuantizeStrength',SAVE_VAL,true);
    end;
else
QuantizeStrength = DefaultQStrength
end
end
function X_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    DefaultXFadeTime = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultXFadeTime'))or 15;
    if MCtrl then VAL = DefaultXFadeTime*0.02 end --set default value by Ctrl+LMB
    self.norm_val=VAL
    
if RememberLast == 1 then 
    local SAVE_VAL = VAL*50;
    if tonumber(r.GetExtState('cool_MK Slicer.lua','CrossfadeTime'))or 0 ~= SAVE_VAL then;
        r.SetExtState('cool_MK Slicer.lua','CrossfadeTime',SAVE_VAL,true);
    end;
else
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
    gfx.rect(x,y, val, h, true) -- draw H_Slider body
end

function V_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = h * self.norm_val
    gfx.rect(x,y+h-val, w, val, true) -- draw V_Slider body
end

function T_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x,y, val, h, true) -- draw T_Slider body
end
function HP_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x,y, val, h, true) -- draw HP_Slider body
end
function LP_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x,y, val, h, true) -- draw LP_Slider body
end
function G_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x,y, val, h, true) -- draw G_Slider body
end
function S_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x,y, val, h, true) -- draw S_Slider body
end
function Rtg_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x,y, val, h, true) -- draw Rtg_Slider body
end
function Rdc_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x,y, val, h, true) -- draw Rdc_Slider body
end
function O_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x,y, val, h, true) -- draw O_Slider body
end
function Q_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x,y, val, h, true) -- draw Q_Slider body
end
function X_Slider:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x,y, val, h, true) -- draw X_Slider body
end
function X_SliderOff:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = 0
    gfx.rect(x,y, val, h, true) -- draw X_Slider body
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
function Q_Slider:draw_lbl()
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
    gfx.set(1,1,1,0.45)  -- set body,frame color
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
function Q_Slider:draw_val()
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
function Slider:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
          -- in element(and get mouswheel) --
          if self:mouseIN() then a=a+0.2
             --if self:set_norm_val_m_wheel() then 
                --if self.onMove then self.onMove() end 
             --end  
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
--------------------------------------------------------------------------------
---   Rng_Slider Class Methods   -----------------------------------------------
--------------------------------------------------------------------------------
function Rng_Slider:pointIN_Ls(p_x, p_y)
  local x, w, sb_w = self.rng_x, self.rng_w, self.sb_w
  local val = w * self.norm_val
  x = x+val-sb_w -- left sbtn x; x-10 extend mouse zone to the left(more comfortable) 
  return p_x >= x-10 and p_x <= x + sb_w and p_y >= self.y and p_y <= self.y + self.h
end
--------
function Rng_Slider:pointIN_Rs(p_x, p_y)
  local x, w, sb_w = self.rng_x, self.rng_w, self.sb_w
  local val = w * self.norm_val2
  x = x+val -- right sbtn x; x+10 extend mouse zone to the right(more comfortable)
  return p_x >= x and p_x <= x+10 + sb_w and p_y >= self.y and p_y <= self.y + self.h
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
    if MCtrl then VAL = 0.234 end --set default value by Ctrl+LMB
    if VAL<0 then VAL = 0 elseif VAL>1-diff then VAL = 1-diff end

    self.norm_val  = VAL
    self.norm_val2 = VAL + diff
end
--------------------------------
function Rng_Slider:draw_body()
    local x,y,w,h  = self.rng_x,self.y,self.rng_w,self.h
    local sb_w = self.sb_w 
    local val  = w * self.norm_val
    local val2 = w * self.norm_val2
    gfx.rect(x+val-sb_w, y, val2-val+sb_w*2, h, true) -- draw body
end
--------
function Rng_Slider:draw_sbtns()
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local x,y,w,h  = self.rng_x,self.y,self.rng_w,self.h
    local sb_w = self.sb_w
    local val  = w * self.norm_val
    local val2 = w * self.norm_val2
    gfx.set(r,g,b,0.06)  -- sbtns body color
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
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    -- set additional coordinates --
    self.sb_w  = h-5
    --self.sb_w  = floor(self.w/17) -- sidebuttons width(change it if need)
    --self.sb_w  = floor(self.w/40) -- sidebuttons width(change it if need)
    self.rng_x = self.x + self.sb_w    -- range streak min x
    self.rng_w = self.w - self.sb_w*2  -- range streak max w
    -- Get mouse state -------------
          -- Reset Ls,Rs states --
          if gfx.mouse_cap&1==0 then self.Ls_state, self.Rs_state, self.rng_state = false,false,false end
          -- in element --
          if self:mouseIN_Ls() or self:mouseIN_Rs() then a=a+0.1 end
          -- in elm L_down --
          if self:mouseDown_Ls()  then self.Ls_state = true end
          if self:mouseDown_Rs()  then self.Rs_state = true end
          if self:mouseDown_rng() then self.rng_state = true end
          --------------
          if self.Ls_state  == true then a=a+0.2; self:set_norm_val()      end
          if self.Rs_state  == true then a=a+0.2; self:set_norm_val2()     end
          if self.rng_state == true then a=a+0.2; self:set_norm_val_both() end
          if (self.Ls_state or self.Rs_state or self.rng_state) and self.onMove then self.onMove() end
          -- in elm L_up(released and was previously pressed) --
          -- if self:mouseClick() and self.onClick then self.onClick() end
          if self:mouseUp() and self.onUp then self.onUp()
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end
    -- Draw sldr body, frame, sidebuttons --
    gfx.set(r,g,b,a)  -- set color
    self:draw_body()  -- body
    self:draw_frame() -- frame
    self:draw_sbtns() -- draw L,R sidebuttons
    -- Draw label,values --
    gfx.set(table.unpack(self.fnt_rgba)) -- set label color
    gfx.setfont(1, fnt, fnt_sz)          -- set lbl,val fnt
    self:draw_lbl() -- draw lbl
    self:draw_val() -- draw value
end


---   Button Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function ZButton:draw_body()
    gfx.rect(self.x,self.y,self.w,self.h, true) -- draw btn body
end
--------
function ZButton:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+(h-lbl_h)/2
    gfx.drawstr(self.lbl)
end
------------------------
function ZButton:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
          -- in element --------
          if self:mouseIN() then a=a+0.1 end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.2 end
          -- in elm L_up(released and was previously pressed) --
          if self:mouseClick() and self.onClick then self.onClick() end
    -- Draw btn body, frame ----
    gfx.set(r,g,b,a)    -- set body color
    self:draw_body()    -- body
    self:draw_frame()   -- frame
    
    
     -- Draw label --------------
    
    gfx.set(table.unpack(self.fnt_rgba))   -- set label color
    gfx.setfont(1, fnt, fnt_sz) -- set label fnt
  
   gfx.line(self.x+self.w/1.89,self.y+self.h-self.h/4,self.x+self.w/2,self.y+self.h/3,1 )
   
  gfx.line(self.x+self.w/2.11,self.y+self.h-self.h/4,self.x+self.w/2,self.y+self.h/3,1 )
  
   gfx.line(self.x+self.w/1.899,self.y+self.h-self.h/4.09,self.x+self.w/2.01,self.y+self.h/3,1 )
   
  gfx.line(self.x+self.w/2.119,self.y+self.h-self.h/4.09,self.x+self.w/2.01,self.y+self.h/3,1 )

end


---   Button Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function XButton:draw_body()
    gfx.rect(self.x,self.y,self.w,self.h, true) -- draw btn body
end
--------
function XButton:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+(h-lbl_h)/2
    gfx.drawstr(self.lbl)
end
------------------------
function XButton:draw()
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
          -- in element --------
          if self:mouseIN() then a=a+0.3 end
          -- in elm L_down -----
          if self:mouseDown() then a=a-0.3 end
          -- in elm L_up(released and was previously pressed) --
          if self:mouseClick() and self.onClick then self.onClick() end
    -- Draw btn body, frame ----
    gfx.set(r,g,b,a)    -- set body color
    self:draw_body()    -- body
    self:draw_frame()   -- frame
    
    
     -- Draw label --------------
    
    gfx.set(table.unpack(self.fnt_rgba))   -- set label color
    gfx.setfont(1, fnt, fnt_sz) -- set label fnt

   gfx.line(self.x+self.w/2,self.y+self.h-self.h/4,self.x+self.w/1.89,self.y+self.h/3,1 )   
   
  gfx.line(self.x+self.w/2 ,self.y+self.h-self.h/4,self.x+self.w/2.11,self.y+self.h/3,1 )  
  
   gfx.line(self.x+self.w/2.01,self.y+self.h-self.h/4.09,self.x+self.w/1.899,self.y+self.h/3,1 )    
   
  gfx.line(self.x+self.w/2.01,self.y+self.h-self.h/4.09,self.x+self.w/2.119,self.y+self.h/3,1 )  

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
    gfx.rect(self.x,self.y,self.w,self.h, true) -- draw checkbox body
end
--------
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
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    -- Get mouse state ---------
          -- in element --------
          if self:mouseIN() then a=a+0.2
             --if self:set_norm_val_m_wheel() then -- use if need
                --if self.onMove then self.onMove() end 
             --end  
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
   if self:mouseIN() then a=a+0.0 end --изменение яркости рамки при наведении мыши
   gfx.set(0.5,0.5,0.5,a)   -- set frame color -- цвет рамок
   self:draw_frame()  -- draw frame
end

----------------------------------------------------------------------------------------------------
--   Some Default Values   -------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
local srate   = 44100 -- дефолтный семплрейт(не реальный, но здесь не имеет значения)
local block_size = 1024*16 -- размер блока(для фильтра и тп) , don't change it!
local time_limit = 5*60    -- limit maximum time, change, if need.
local defPPQ = 960         -- change, if need.
----------------------------------------------------------------------------------------------------
---  Create main objects(Wave,Gate) ----------------------------------------------------------------
----------------------------------------------------------------------------------------------------
local Wave = Element:new(10,10,1024,350)
local Gate_Gl  = {}

---------------------------------------------------------------
---  Create Frames   ------------------------------------------
---------------------------------------------------------------
local Fltr_Frame = Frame:new(10, 370,180,110,  0,0.5,0,0.2 )
local Gate_Frame = Frame:new(200,370,180,110,  0,0.5,0,0.2 )
local Mode_Frame = Frame:new(390,370,645,110,  0,0.5,0,0.2 )
local Frame_TB = {Fltr_Frame, Gate_Frame, Mode_Frame}


local Midi_Sampler = CheckBox:new(610,410,68,18, 0.3,0.4,0.7,0.7, "","Arial",16,  MIDI_Mode+1,
                              {"Sampler","Trigger"} )


---------------------------------------------------------------
---  Create Menu Settings   ------------------------------------
---------------------------------------------------------------

function OpenURL(url)
  local OS = r.GetOS()
  if OS == "OSX32" or OS == "OSX64" then
    os.execute('open "" "' .. url .. '"')
  else
    os.execute('start "" "' .. url .. '"')
  end
end

---------------
-- class.lua --
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
----------------------------------------------------------------------------------------

----------------
-- Menu class --
----------------

-- To create a new menu instance, call this function like this:
--   menu_name = Menu("menu_name")
local Menu = 
  class(
    function(menu, id)
      menu.id = id    
      menu.items = {} -- Menu items are collected to this table
    end
  )


------------------
-- Menu methods --
------------------

-- Returns the created table and table index in "menu_obj.items"
function Menu:add_item(...)
  t = ... or {}
  self.items[#self.items+1] = t -- add new menu item at the end of menu
  -- Parse arguments
  for i,v in pairs(t) do
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
  -- Edit these
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
  
  if t.command == nil then
    t.command = function() return end
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
  self.items_str = self:table_to_string() or ""
  self.val = gfx.showmenu(self.items_str)
  if self.val > 0 then
    self:update(self.val)
  end
end


function Menu:update(menu_item_index)
  local i = menu_item_index 
  if self.items[i].toggleable then
    self.items[i].selected = not self.items[i].selected
  end
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
    s = ""
    local menu_item = self.items[i]
    if menu_item.selected then
      s = "!"
    end
    
    if not menu_item.active then
      s = s .. "#"
    end
    
    if #menu_item > 0 then
      --self.items[i]
      s = s .. ">"
    end
    
    if menu_item.label ~= "" then
      s = s .. menu_item.label .. "|"
    end
    
    if i < #self.items then
    --  s = s .. "|"
    end
    --aas = self
    self.items_str = self.items_str .. s
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
local HP_Freq = HP_Slider:new(20,410,160,18, 0.3,0.4,0.7,0.7, "Low Cut","Arial",16, HF_Slider )
-- Filter LP_Freq --------------------------------
local LP_Freq = LP_Slider:new(20,430,160,18, 0.3,0.4,0.7,0.7, "High Cut","Arial",16, LF_Slider )

--------------------------------------------------
-- Filter Freq Sliders draw_val function ---------
--------------------------------------------------
function HP_Freq:draw_val()
  local sx = 16+(self.norm_val*100)*1.20103
  self.form_val = floor(exp(sx*logx(1.059))*8.17742) -- form val
  -------------
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%d", self.form_val) .." Hz"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val) -- draw Slider Value
end
-------------------------
 LP_Freq.draw_val = HP_Freq.draw_val -- Same as the previous(HP_Freq:draw_val())
-------------------------


-- Filter Gain -----------------------------------
local Fltr_Gain = G_Slider:new(20,450,160,18,  0.3,0.4,0.7,0.7, "Filtered Gain","Arial",16, out_gain )
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
   end 
end

local CreateMIDIMode = CheckBox:new(0,0,0,0, 0.3,0.4,0.7,0.7, "","Arial",16,  1,
                              {"", "", ""} )

-------------------------
local VeloMode = CheckBox:new(680,410,90,18, 0.3,0.4,0.7,0.7, "","Arial",16,  1, -------velodaw
                              {"Use RMS","Use Peak"} )

VeloMode.onClick = 
function()

end

-------------------------------------------------------------------------------------
--- Gate Sliders --------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Threshold -------------------------------------
-------------------------------------------------
local Gate_Thresh = T_Slider:new(210,380,160,18, 0.3,0.4,0.7,0.7, "Threshold","Arial",16, readrms )
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
local Gate_Sensitivity = S_Slider:new(210,400,160,18, 0.3,0.4,0.7,0.7, "Sensitivity","Arial",16, Sens_Slider )
function Gate_Sensitivity:draw_val()
  self.form_val = 2+(self.norm_val)*8       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." dB"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
end
-- Retrig ----------------------------------------
local Gate_Retrig = Rtg_Slider:new(210,420,160,18, 0.3,0.4,0.7,0.7, "Retrig","Arial",16, retrigms )
function Gate_Retrig:draw_val()
  self.form_val  = 20+ self.norm_val * 180   -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
end
-- Detect Velo time ------------------------------ 
local Gate_DetVelo = H_Slider:new(0,0,0,0, 0,0,0,0, "","Arial",16, 0.50 )
function Gate_DetVelo:draw_val()
  self.form_val  = 5+ self.norm_val * 20     -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
end
-- Reduce points slider -------------------------- 
local Gate_ReducePoints = Rdc_Slider:new(210,450,160,18, 0.3,0.4,0.7,0.7, "Reduce","Arial",16, 1 )
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
function Gate_Sldrs_onUp() 
   if Wave.State then Gate_Gl:Apply_toFiltered() end 
end
----------------
Gate_Thresh.onUp    = Gate_Sldrs_onUp
Gate_Sensitivity.onUp = Gate_Sldrs_onUp
Gate_Retrig.onUp    = Gate_Sldrs_onUp
Gate_DetVelo.onUp   = Gate_Sldrs_onUp

-- Detect Velo time ------------------------------ 
local Offset_Sld = O_Slider:new(400,430,205,18, 0.3,0.4,0.7,0.7, "Offset","Arial",16, Offs_Slider )
function Offset_Sld:draw_val()

  self.form_val  = (100- self.norm_val * 200)*( -1)     -- form_val
  function fixzero()
  FixMunus = self.form_val
  if (FixMunus== 0.0)then FixMunus = 0
  end
  end
  fixzero()  
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", FixMunus).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
  
  end
Offset_Sld.onUp =
function() 
   if Wave.State then
      Gate_Gl:Apply_toFiltered()
      DrawGridGuides()
      fixzero() 
   end 
end

-- QStrength slider ------------------------------ 
local QStrength_Sld = Q_Slider:new(400,450,101,18, 0.3,0.4,0.7,0.7, "QStrength","Arial",16, QuantizeStrength*0.01 )
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

-- XFade slider ------------------------------ 
local XFade_Sld = X_Slider:new(503,450,102,18, 0.3,0.4,0.7,0.7, "XFades","Arial",16, CrossfadeTime*0.02 )
function XFade_Sld:draw_val()
  self.form_val = (self.norm_val)*50       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
  x_fade =  floor(XFade_Sld.form_val)
end
XFade_Sld.onUp =
function() 

end

-- XFade sliderOff ------------------------------ 
local XFade_Sld_Off = X_SliderOff:new(503,450,102,18, 0.4,0.4,0.4,0.8, "XFades","Arial",16, 0 )
function XFade_Sld_Off:draw_val()
  self.form_val = (self.norm_val)*50       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w+8
  gfx.set(1,1,1,0.4)  -- set body,frame color
  gfx.drawstr('Off')--draw Slider Value
end
XFade_Sld_Off.onUp =
function() 

end

-------------------------------------------------------------------------------------
--- Range Slider --------------------------------------------------------------------
-------------------------------------------------------------------------------------
local Gate_VeloScale = Rng_Slider:new(680,430,90,18, 0.3,0.4,0.7,0.7, "Range","Arial",16, 0.231, 1 )---velodaw 
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

-------------------------
local OutNote  = CheckBox:new(610,430,68,18, 0.3,0.4,0.7,0.7, "","Arial",16,  1,
                              --{36,37,38,39,40,41,42,43,44,45,46,47},
                              {'C1: 36', 'C#1: 37', 'D1: 38', 'D#1: 39', 'E1: 40',
                               'F1: 41', 'F#1: 42', 'G1: 43', 'G#1: 44',
                               'A1: 45', 'A#1: 46', 'B1: 47'} 
                              )
-------------------------

local Velocity = Txt:new(698,384,55,18, 0.8,0.8,0.8,0.8, "Velocity:","Arial",22)

----------------------------------------

local Slider_TB = { HP_Freq,LP_Freq,Fltr_Gain, 
                   Gate_Thresh,Gate_Sensitivity,Gate_Retrig,Gate_ReducePoints,Offset_Sld,QStrength_Sld,XFade_Sld}

local Slider_TB_XFadeOff = { HP_Freq,LP_Freq,Fltr_Gain, 
                   Gate_Thresh,Gate_Sensitivity,Gate_Retrig,Gate_ReducePoints,Offset_Sld,QStrength_Sld,XFade_Sld_Off}
                   
local Exception = {Gate_DetVelo}                   



local Slider_TB_Trigger = { HP_Freq,LP_Freq,Fltr_Gain, 
                   Gate_Thresh,Gate_Sensitivity,Gate_Retrig,Gate_DetVelo,Gate_ReducePoints, 
                   Gate_VeloScale, VeloMode,OutNote, Velocity,Offset_Sld,QStrength_Sld,XFade_Sld}

-------------------------------------------------------------------------------------
--- Buttons -------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Get Selection button --------------------------
local Get_Sel_Button = Button:new(20,380,160,25, 0.3,0.3,0.3,1, "Get Item",    "Arial",16 )
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
------------------------------------------------------------------------------------------------
function sel_tracks_items() --Select only tracks of selected items

	UnselectAllTracks()
	selected_items_count = r.CountSelectedMediaItems(0)

	for i = 0, selected_items_count - 1  do
		item = r.GetSelectedMediaItem(0, i) -- Get selected item i
		track = r.GetMediaItem_Track(item)
		r.SetTrackSelected(track, true)				
	end 
end

function UnselectAllTracks()
	first_track = r.GetTrack(0, 0)
          if first_track then
	      r.SetOnlyTrackSelected(first_track)
	      r.SetTrackSelected(first_track, false)
          end
end


    r.Undo_BeginBlock() 
r.PreventUIRefresh(1)

if ObeyingItemSelection == 1 then
sel_tracks_items()
end

-----------------------------------ObeyingTheSelection------------------------------------

function collect_param()    -- collect parameters
   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item 
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   src = r.GetMediaItemTake_Source(active_take)
   srate =  r.GetMediaSourceSampleRate(src) -- take samplerate (simple wave/MIDI detection)
 end

collect_param()
start, ending = r.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
time_sel_length = ending - start
if ObeyingTheSelection == 1 and ObeyingItemSelection == 0 and start ~= ending then
    r.Main_OnCommand(40289, 0) -- Item: Unselect all items
          if time_sel_length > 0.25 and selected_tracks_count == 1 then
              r.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
          end
end

count_itms =  r.CountSelectedMediaItems(0)
if ObeyingTheSelection == 1 and count_itms ~= 0 and start ~= ending and time_sel_length > 0.25 then
   take_check()
   if Take_Check ~= 1 and selected_tracks_count == 1 then

    --------------------------------------------------------
    local function no_undo() r.defer(function()end)end;
    --------------------------------------------------------
    
    local startTSel,endTSel = r.GetSet_LoopTimeRange(0,0,0,0,0);
    if startTSel == endTSel then no_undo() return end;
    
    local CountSelItem = r.CountSelectedMediaItems(0);
    if CountSelItem == 0 then no_undo() return end;
    
    local TMSL,UNDO;
    for t = CountSelItem-1,0,-1 do;
        local item = r.GetSelectedMediaItem(0,t);
        local posIt = r.GetMediaItemInfo_Value(item,"D_POSITION");
        local lenIt = r.GetMediaItemInfo_Value(item, "D_LENGTH");
        if posIt < endTSel and posIt+lenIt > startTSel then;
            TMSL = true;
            if not UNDO then;
                r.Undo_BeginBlock();
                r.PreventUIRefresh(1);
                UNDO = true;
            end;
        end;
        if posIt < endTSel and posIt+lenIt > endTSel then;
            r.SplitMediaItem(item,endTSel);
        end;
        if posIt < startTSel and posIt+lenIt > startTSel then;
            r.SplitMediaItem(item,startTSel);
        end;
    end;
    
    if TMSL then;
        for t = r.CountSelectedMediaItems(0)-1,0,-1 do;
            local item = r.GetSelectedMediaItem(0,t);
            local posIt = r.GetMediaItemInfo_Value(item,"D_POSITION");
            local lenIt = r.GetMediaItemInfo_Value(item, "D_LENGTH");
            if posIt >= endTSel or posIt+lenIt <= startTSel then;
                r.SetMediaItemInfo_Value(item,'B_UISEL',0);
            end;
        end;
    end;
    
    if UNDO then;
         r.PreventUIRefresh(-1);
         r.Undo_EndBlock("Split items by time selection,unselect with items outside of time selection if there is selection inside",-1);
    else;
        no_undo();
    end;    
    r.UpdateArrange();

        collect_param()  
        if number_of_takes ~= 1 and srate ~= nil then
           r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то клей, попытка не деструктивно склеить).
        end
       collect_param()    
       if number_of_takes ~= 1 and srate ~= nil then -- проверяем ещё раз. Если не удалось, клеим деструктивно.
           r.Main_OnCommand(41588, 0) -- glue (если больше одного айтема и не миди айтем, то клей).
       end
   end
end

local cursorpos = r.GetCursorPosition()

            r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVETIME1"),0)
            r.Main_OnCommand(40290, 0) -- Set time selection to item
            r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVETIME2"),0)
            r.Main_OnCommand(40635, 0)     -- Remove Selection
            r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME1"),0)

r.SetEditCurPos(cursorpos,0,0) 
r.PreventUIRefresh(-1)
    r.Undo_EndBlock("Init", -1) 

--------------------------A Bit More Foolproof----------------------------

sel_tracks_items() 

function collect_itemtake_param()    -- collect parameter on sel item and active take for SM tables and displacement calcs...
   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   mute_check = r.GetMediaItemInfo_Value(sel_item, "B_MUTE")
 end
 
   collect_itemtake_param()              -- get bunch of parameters about this item

take_check()

 if number_of_takes ~= 1 and Take_Check == 0 then
 
r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то клей, попытка не деструктивно склеить).

end

   collect_itemtake_param()

if selected_tracks_count == 1 and number_of_takes > 1 and Take_Check == 0 then 

 r.Main_OnCommand(41588, 0) -- glue (если больше одного айтема, то клей).
  
  end

if selected_tracks_count > 1 then

------------------------------------------Error Message-----------------------------------------

local timer = 2 -- Time in seconds
local time = os.time()
local function Msg()
   local char = gfx.getchar()
     if char == 27 or char == -1 or (os.time() - time) > timer then return end
local Get_Sel_ErrMsg = ErrMsg:new(660,450,260,25, 1, 1, 1, 1, "Only single track items, please",    "Arial", 22)
local ErrMsg_TB = {Get_Sel_ErrMsg}
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

if  Take_Check == 1 then  

------------------------------------Error Message----------------------------------------------

local timer = 2 -- Time in seconds
local time = os.time()
local function Msg()
   local char = gfx.getchar()
     if char == 27 or char == -1 or (os.time() - time) > timer then return end
local Get_Sel_ErrMsg = ErrMsg:new(660,450,260,25, 1, 1, 1, 1, "Only Wave items, please",    "Arial", 22)
local ErrMsg_TB = {Get_Sel_ErrMsg}
     for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
   gfx.update()
  r.defer(Msg)
end
end
Msg()

-------------------------------------End of Error Message----------------------------------------

Init()

 goto zzz 
end -- не запускать, если MIDI айтем.

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

getitem()

::zzz::

end

-- Create Settings Button ----------------------------
local Settings = Button_Settings:new(10,10,40,40, 0.3, 0.3, 0.3, 0.9, ">",    "Arial",20 )
Settings.onClick = 
function()
   Wave:Settings()
end 

-- Create Just Slice  Button ----------------------------
local Just_Slice = Button:new(400,380,67,25, 0.3,0.3,0.3,1, "Slice",    "Arial",16 )
Just_Slice.onClick = 
function()
   if Wave.State then Wave:Just_Slice() end 
end 

-- Create Quantize Slices Button ----------------------------
local Quantize_Slices = Button:new(469,380,31,25, 0.3,0.3,0.3,1, "Q",    "Arial",16 )
Quantize_Slices.onClick = 
function()
   if Wave.State then Wave:Quantize_Slices() end 
end 


-- Create Add Markers Button ----------------------------
local Add_Markers = Button:new(505,380,67,25, 0.3,0.3,0.3,1, "Markers",    "Arial",16 )
Add_Markers.onClick = 
function()
   if Wave.State then Wave:Add_Markers() end 
end 

-- Create Quantize Markers Button ----------------------------
local Quantize_Markers = Button:new(574,380,31,25, 0.3,0.3,0.3,1, "Q",    "Arial",16 )
Quantize_Markers.onClick = 
function()
   if Wave.State then Wave:Quantize_Markers() end 
end 

-- Reset All Button ----------------------------
local Reset_All = Button:new(970,445,55,25, 0.3,0.3,0.3,1, "Reset",    "Arial",16 )
Reset_All.onClick = 
function()
   if Wave.State then Wave:Reset_All() end 
end

-- Create Midi Button ----------------------------
local Create_MIDI = Button:new(610,380,68,25, 0.3,0.3,0.3,1, "MIDI",    "Arial",16 )
Create_MIDI.onClick = 

function()

if Wave.State and MIDISmplr_Status == 0 and Trigg_Status == 0 then
  Slice_Status = 1
  M_Check = 0
  MIDISampler = 1

sel_tracks_items() 
selected_tracks_count = r.CountSelectedTracks(0)

  if selected_tracks_count > 1 then

-----------------------------------------Error Message1---------------------------------------------------

  local timer = 2 -- Time in seconds
  local time = os.time()
  local function Msg()
     local char = gfx.getchar()
       if char == 27 or char == -1 or (os.time() - time) > timer then return end
  local Get_Sel_ErrMsg = ErrMsg:new(660,450,260,25, 1, 1, 1, 1, "Only single track items, please",    "Arial", 22)
  local ErrMsg_TB = {Get_Sel_ErrMsg}
       for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
     gfx.update()
    r.defer(Msg)
  end
  end
  Msg()

--------------------------------------End of Error Message1-------------------------------------------
Init()

  M_Check = 1

  return

  end -- не запускать, если мультитрек.

take_check()

if  Take_Check == 1 then  

------------------------------------Error Message2----------------------------------------------

local timer = 2 -- Time in seconds
local time = os.time()
local function Msg()
   local char = gfx.getchar()
     if char == 27 or char == -1 or (os.time() - time) > timer then return end
local Get_Sel_ErrMsg = ErrMsg:new(660,450,260,25, 1, 1, 1, 1, "Only Wave items, please",    "Arial", 22)
local ErrMsg_TB = {Get_Sel_ErrMsg}
     for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
   gfx.update()
  r.defer(Msg)
end
end
Msg()

-------------------------------------End of Error Message2----------------------------------------

Take_Check = 0

Init()

  return

end -- не запускать, если MIDI айтем.

  if M_Check == 0 then

      r.Undo_BeginBlock() 

   r.Main_OnCommand(41844, 0)  ---Delete All Markers  

  sel_tracks_items() 

function pitch_and_rate_check()
     selected_tracks_count = r.CountSelectedTracks(0)
     number_of_takes =  r.CountSelectedMediaItems(0)
     if number_of_takes == 0 then return end
     sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item 
     active_take = r.GetActiveTake(sel_item)  -- active take in item
     take_pitch = r.GetMediaItemTakeInfo_Value(active_take, "D_PITCH")  -- take pitch
     take_playrate = r.GetMediaItemTakeInfo_Value(active_take, "D_PLAYRATE") -- take playrate 
     src = r.GetMediaItemTake_Source(active_take)
     srate =  r.GetMediaSourceSampleRate(src) -- take samplerate (simple wave/MIDI detection)
end
pitch_and_rate_check()
  if selected_tracks_count > 1 then return end -- не запускать, если айтемы находятся на разных треках.

local i=0;
while(true) do;
  i=i+1;
  local item = r.GetSelectedMediaItem(0,i-1);
  if item then;
  active_take = r.GetActiveTake(item)  -- active take in item
    if r.TakeIsMIDI(active_take) then return end
  else;
    break;
  end;
end;

 if number_of_takes ~= 1 and srate ~= nil then
 
r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то клей, попытка не деструктивно склеить).

end

pitch_and_rate_check()

   if take_pitch ~= 0 or take_playrate ~= 1.0 or number_of_takes ~= 1 and srate > 0 then
 
    r.Main_OnCommand(41588, 0) -- glue (если изменены rate, pitch, больше одного айтема и не миди айтем, то клей. Требуется для корректной работы кнопки MIDI).

  end

  getitem()

  if (Midi_Sampler.norm_val == 1) then  

  Wave:Just_Slice()   
  Wave:Load_To_Sampler() 

  Wave.State = false -- reset Wave.State

      r.Undo_EndBlock("Create MIDI", -1) 

  else

     if Wave.State then Wave:Create_MIDI() end 

     Wave.State = false -- reset Wave.State

  end
  end 
  end
end
----------------------------------------
--- Button_TB --------------------------
----------------------------------------
local Button_TB = {Get_Sel_Button, Settings, Just_Slice, Quantize_Slices, Add_Markers, Quantize_Markers, Reset_All, Create_MIDI, Midi_Sampler}
 

-------------------------------------------------------------------------------------
--- CheckBoxes ----------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, norm_val = check, norm_val2 = checkbox table ---
-------------------------------------------------------------------------------------
--------------------------------------------------
-- MIDI Checkboxes ---------------(600,380,288,18, 0.3,0.5,0.3,0.3 -- green
local NoteChannel  = CheckBox:new(600,380,288,18, 0.3,0.4,0.7,0.7, "","Arial",16,  1,
                              --{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},
                              {'Channel: 1', 'Channel: 2', 'Channel: 3', 'Channel: 4',
                               'Channel: 5', 'Channel: 6', 'Channel: 7', 'Channel: 8',
                               'Channel: 9', 'Channel: 10','Channel: 11','Channel: 12',
                               'Channel: 13','Channel: 14','Channel: 15','Channel: 16'} 
                              )
-------------------------
local NoteLenghth  = CheckBox:new(750,430,90,18, 0.3,0.4,0.7,0.7, "","Arial",16,  5,

                              {"Lenght: 1/4","Lenght: 1/8","Lenght: 1/16","Lenght: 1/32","Lenght: 1/64"} )
-------------------------


local Guides  = CheckBox:new(400,410,205,18, 0.3,0.4,0.7,0.7, "","Arial",16,  1,
                              {"Guides By Transients","Guides By 1/2","Guides By 1/4","Guides By 1/8","Guides By 1/16","Guides By 1/32","Guides By 1/64"} )

Guides.onClick = 
function() 

   if Wave.State then
      DrawGridGuides()
   end 

end

--------------------------------------------------
-- View Checkboxes -------------------------------
local DrawMode = CheckBox:new(0,0,0,0, 0.3,0.4,0.7,0.7, "","Arial",16,  4,  --(970,380,55,18, 0.3,0.4,0.7,0.7, "Draw: ","Arial",16,  1,
                              { "", "", "", "" } )

-------------------------
local ViewMode = CheckBox:new(970,380,55,18,  0.3,0.4,0.7,0.7, "Show: ","Arial",16,  1,
                              { "All", "Original", "Filtered" } )
ViewMode.onClick = 
function() 
   if Wave.State then Wave:Redraw() end 
end


-----------------------------------
--- CheckBox_TB -------------------
-----------------------------------
local CheckBox_TB = {DrawMode, ViewMode,Guides}

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
           
      local det_velo_smpls = floor(Gate_DetVelo.form_val/1000*srate) -- DetVelo slider to samples
              
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
    collectgarbage("collect") -- collectgarbage(подметает память) 
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
    for i=1, #self.State_Points, 2 do
       -- В результирующую таблицу копируются значения, входящие в диапазон --
       if self.State_Points[i+1][mode]>= reduce_val then
         local p = #self.Res_Points+1
         self.Res_Points[p]   = self.State_Points[i]+(Offset_Sld.form_val/1000*srate)
         self.Res_Points[p+1] = {self.State_Points[i+1][1], self.State_Points[i+1][2]}
       
        end
    end 
      
function DrawGridGuides()
 
lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')
     
     item =  r.BR_GetMediaItemByGUID( 0, lastitem )
                if item then 
                              
                local sel_start_g = r.GetMediaItemInfo_Value( item, 'D_POSITION' )
                local len_g = r.GetMediaItemInfo_Value( item, 'D_LENGTH' )
                sel_end_g = sel_start_g+len_g

------------------------------------------------------------------------------
-------------------------------SAVE GRID-----------------------------

local _, division, swingmode, swingamt = r.GetSetProjectGrid(0, 0)

local ext_sec, ext_key = 'savegrid', 'grid'
r.SetExtState(ext_sec, ext_key, division..','..swingmode..','..swingamt, 0)
 
---------------------------SET NEWGRID--------------------------------------------------------------------
--------------------------------------------------------------------------------------- 
 
if  Guides.norm_val == 2 then  r.Main_OnCommand(40780, 0)
elseif Guides.norm_val == 3 then r.Main_OnCommand(40779, 0)
elseif Guides.norm_val == 4 then r.Main_OnCommand(40778, 0)  
elseif Guides.norm_val == 5 then r.Main_OnCommand(40776, 0)
elseif Guides.norm_val == 6 then r.Main_OnCommand(40775, 0)
elseif Guides.norm_val == 7 then r.Main_OnCommand(40774, 0)
end
  Grid_Points_r ={}
 Grid_Points = {}
 grinline = sel_start_g 
   while (grinline <= sel_end_g) do
    grinline = r.BR_GetNextGridDivision(grinline)
    
    local pop = #Grid_Points+1
    Grid_Points[pop] = floor(grinline*srate)+(Offset_Sld.form_val/1000*srate)
    
    local rock = #Grid_Points_r+1
        offset_pop = (grinline - sel_start_g)
        Grid_Points_r[rock] = floor(offset_pop*srate)+(Offset_Sld.form_val/1000*srate)
   end 
 end 
  
------------------------------------RESTORE GRID-----------------------------------------------
-----------------------------------------------------------------------------
 
 local ext_sec, ext_key = 'savegrid', 'grid'
 local str = r.GetExtState(ext_sec, ext_key)
 if not str or str == '' then return end
 
 local division, swingmode, swingamt = str:match'(.*),(.*),(.*)'
 if not (division and swingmode and swingamt) then return end
 
 r.GetSetProjectGrid(0, 1, division, swingmode, swingamt)
 
  end
end

------------------------------------------------------------------
---  Gate - Draw Gate Lines  -----------------------------------------
----------------------------------------------------------------------
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
        local line_x   = Wave.x + (self.Res_Points[i] - self.start_smpl) * self.Xsc  -- line x coord
        local velo_y   = self.Yop -  self.Res_Points[i+1][mode] * self.Ysc           -- velo y coord    
   
    ------------------------
        -- draw line, velo -----
        ------------------------
        if line_x>=Wave.x and line_x<=Wave.x+Wave.w then -- Verify line range
           gfx.line(line_x, Wave.y, line_x, Wave.y+Wave.h-1)  -- Draw Trig Line
           
           if (Midi_Sampler.norm_val == 2) then
           gfx.circle(line_x, velo_y, 3,1,1)             -- Draw Velocity point
        end
        end
        
            ------------------------
            -- Get mouse -----------
            ------------------------
            if not self.cap_ln and abs(line_x-gfx.mouse_x)< (10*Z_w) then -- здесь 10*Z_w - величина окна захвата маркера.
               if Wave:mouseDown() or Wave:mouseR_Down() then self.cap_ln = i end
            end
        end
      
 else       

gfx.set(0, 0.7, 0.7, 0.7) -- gate line, point color -- цвет маркеров при отображении сетки

 Grid_Points_r = Grid_Points_r or {};     

 for i=1, #Grid_Points_r  do
         local line_x  = Wave.x + (Grid_Points_r[i] - self.start_smpl) * self.Xsc  -- line x coord

  
     ------------------------
         -- draw line 8 -----
         ------------------------
       
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

--------------------------------------------------------------------------------
-- Gate -  manual_Correction ---------------------------------------------------
--------------------------------------------------------------------------------
function Gate_Gl:manual_Correction()
    -- Change Velo, Move, Del Line ---------------
    if self.cap_ln then
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
        end

        -- Delete Line ---------------------------
        if SButton == 0 and Wave:mouseR_Down() then gfx.x, gfx.y  = mouse_ox, mouse_oy
            if mouseR_Up_status == 1 then
               table.remove(self.Res_Points,self.cap_ln) -- Del self.cap_ln - Элементы смещаются влево!
               table.remove(self.Res_Points,self.cap_ln) -- Поэтому, опять тот же индекс(а не self.cap_ln+1)
                    mouseR_Up_status = 0
                    MouseUpX = 1
            end
        end       
    end
    
    -- Insert Line(on mouseR_Down) -------------------------
    if SButton == 0 and not self.cap_ln and Wave:mouseR_Down() then gfx.x, gfx.y  = mouse_ox, mouse_oy
        if mouseR_Up_status == 1 then
            local line_pos = self.start_smpl + (mouse_ox-Wave.x)/self.Xsc  -- Time point(in Samples!) from mouse_ox pos
            --------------------
            local newVelo = (self.Yop - mouse_oy)/(Wave.h*self.scale) -- velo from mouse y pos
            newVelo = min(max(newVelo,0),1)
            --------------------             
            table.insert(self.Res_Points, line_pos)           -- В конец таблицы
            table.insert(self.Res_Points, {newVelo, newVelo}) -- В конец таблицы
            --------------------
            self.cap_ln = #self.Res_Points
                    mouseR_Up_status = 0
                    MouseUpX = 1
        end
    end 
end


------------------------------------------------------------------------------------------------------------------------
---   WAVE   -----------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

function Wave:Settings()


end

--------------------------------------------------------------------------------
---  GetSet_MIDITake  ----------------------------------------------------------
--------------------------------------------------------------------------------
-- Создает новый айтем для фичи Trigger, либо удаляет выбранную ноту в выделленном.
function Wave:GetSet_MIDITake()
    local tracknum, midi_track, item, take
    -- New item on new track(mode 1) ------------
    if CreateMIDIMode.norm_val == 1 then       
        tracknum = r.GetMediaTrackInfo_Value(self.track, "IP_TRACKNUMBER")
        r.InsertTrackAtIndex(tracknum, false)
        midi_track = r.GetTrack(0, tracknum)
        r.TrackList_AdjustWindows(0)
        item = r.CreateNewMIDIItemInProj(midi_track, self.sel_start, self.sel_end, false)
        take = r.GetActiveTake(item)
        return item, take
    -- New item on sel track(mode 2) ------------
    elseif CreateMIDIMode.norm_val == 2 then
        midi_track = r.GetSelectedTrack(0, 0)
        if not midi_track or midi_track==self.track then return end -- if no sel track or sel track==self.track
        item = r.CreateNewMIDIItemInProj(midi_track, self.sel_start, self.sel_end, false)
        take = r.GetActiveTake(item)
        return item, take
    -- Use selected item(mode 3) ----------------
    elseif CreateMIDIMode.norm_val == 3 then
        item = r.GetSelectedMediaItem(0, 0)
        if item then take = r.GetActiveTake(item) end
            if take and r.TakeIsMIDI(take) then
               local ret, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)
               local findpitch = 35 + OutNote.norm_val -- from checkbox
               local note = 0
                -- Del old notes with same pith --
                for i=1, notecnt do
                    local ret, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(take, note)
                    if pitch==findpitch then 
                       r.MIDI_DeleteNote(take, note); note = note-1 -- del note witch findpitch and update counter
                    end  
                    note = note+1
                end
            r.MIDI_Sort(take)
            r.UpdateItemInProject(item)
            return item, take
        end   
    end  
end

--------------------------------------------------------------------------------------------------------------

function Wave:Just_Slice()

if Slice_Status == 1 or MouseUpX == 1 then

MouseUpX = 0
Slice_Status = 0
Reset_Status = 1

r.PreventUIRefresh(1)

r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVESEL'), 0)  -- Save track selection

sel_tracks_items() -- select for a multitrack check
selected_tracks_count = r.CountSelectedTracks(0)
count_itms =  r.CountSelectedMediaItems(0)

if SliceQ_Status == 1 and count_itms > selected_tracks_count  then
 r.Main_OnCommand(40029, 0)  -- Undo
 r.Main_OnCommand(40548, 0)  -- Heal Splits
end

SliceQ_Status = 0

sel_tracks_items() -- select for a multitrack check
selected_tracks_count = r.CountSelectedTracks(0)
count_itms =  r.CountSelectedMediaItems(0)

 r.Undo_BeginBlock() 

   -------------------------------------------

if AutoXFadesOnSplitOverride == 1 then
local crossfades_on_split_option
  if r.GetToggleCommandState(40912) == 1 then
    r.Main_OnCommand(40912,0)--Options: Toggle auto-crossfades on split
    crossfades_on_split_option = 1
  end
end

if ItemFadesOverride == 1 then
local itemfades_option
  if r.GetToggleCommandState(41194) == 1 then
    r.Main_OnCommand(41194,0)--Options: Toggle item crossfades
    itemfades_option = 1
  end
end

if count_itms == selected_tracks_count and selected_tracks_count >1 then  -- multitrack
               r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVETIME1"),0)
               r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME2"),0);  -- Restore Selection
              r.Main_OnCommand(40061, 0) -- Item: Split items at time selection
sel_tracks_items() 

unselect_if_out_of_time_range()

               r.Main_OnCommand(40635, 0)     -- Remove Selection
               r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME1"),0)
               r.Main_OnCommand(40032, 0) -- Group Items

elseif count_itms > selected_tracks_count and selected_tracks_count >1 then  -- sliced multitrack

               r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVETIME1"),0)
               r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME2"),0);  -- Restore Selection
               r.Main_OnCommand(40061, 0) -- Item: Split items at time selection
sel_tracks_items() 

unselect_if_out_of_time_range()

               r.Main_OnCommand(40635, 0)     -- Remove Selection
               r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME1"),0)
               r.Main_OnCommand(40032, 0) -- Group Items

end

 r.Main_OnCommand(40548, 0)     -- Heal Slices

sel_tracks_items() -- select for a multitrack check
selected_tracks_count = r.CountSelectedTracks(0)
count_itms =  r.CountSelectedMediaItems(0)

if count_itms > selected_tracks_count and selected_tracks_count > 1 then  -- sliced multitrack

 if Slice_Init_Status == 0 then---------------------------------glue------------------------------

          r.Main_OnCommand(41588, 0) -- glue 

   Wave:Destroy_Track_Accessor() -- Destroy previos AA
   if Wave:Create_Track_Accessor() then Wave:Processing() end

end

end

  r.Main_OnCommand(40033, 0) -- UnGroup
  r.Main_OnCommand(41844, 0) -- Remove Markers

sel_tracks_items() -- select for a multitrack check
selected_tracks_count = r.CountSelectedTracks(0)
count_itms =  r.CountSelectedMediaItems(0)

 r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTORESEL'), 0)  -- Restore track selection

if count_itms > selected_tracks_count and selected_tracks_count >1 or count_itms > selected_tracks_count and selected_tracks_count == 1 then  -- sliced single/multitrack

      r.Main_OnCommand(40029, 0)  -- Undo 

 goto yyy 

end -- вторая проверка. Если айтемы не склеились, значит слайсы квантованы и применяем undo.

if count_itms > 1 and selected_tracks_count >1 then  -- multitrack

       r.Main_OnCommand(40032, 0) -- Group Items

end

if count_itms == selected_tracks_count  then  -- single track

local cursorpos = r.GetCursorPosition()
                   

  lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')


    item =  r.BR_GetMediaItemByGUID( 0, lastitem )
               if item then
               
   r.SetMediaItemSelected(item, 1)  
            
    r.Main_OnCommand(40548, 0)     -- Heal Slices
               
    if (Guides.norm_val == 1) then      
           
         local startppqpos, next_startppqpos
         ----------------------------
         local points_cnt = #Gate_Gl.Res_Points
         for i = 1, points_cnt, 2 do
                                
           if i<points_cnt then next_startppqpos = (self.sel_start + Gate_Gl.Res_Points[i]/srate )         
            end

            cutpos = (next_startppqpos - 0.001)
if MIDISampler == 1 then
          if  cutpos - self.sel_start >= 0.03 and self.sel_end - cutpos >= 0.05 then -- if transient too close near item start, do nothing
             r.SetEditCurPos(cutpos,0,0)          
             r.Main_OnCommand(40757, 0)  ---split
          end
else
          if  cutpos - self.sel_start >= 0 and self.sel_end - cutpos >= 0.02 then -- if transient too close near item end, do nothing
             r.SetEditCurPos(cutpos,0,0)          
             r.Main_OnCommand(40757, 0)  ---split
          end
end
        ----------------------------
     end        
         
   else

 Grid_Points = Grid_Points or {}

  for i=1, #Grid_Points or 0 do --split by grid                   
            r.SetEditCurPos(Grid_Points[i]/srate,0,0)           
            r.Main_OnCommand(40757, 0)  ---split     
         ----------------------------
     end        
   end
 end 

Slice_Init_Status = 1 

SliceQ_Init_Status = 1

r.SetEditCurPos(cursorpos,0,0) 

r.Main_OnCommand(40034, 0)  ---select all items in groups

if AutoXFadesOnSplitOverride == 1 then
  if crossfade_on_split_option then r.Main_OnCommand(40912,0) end--Options: Toggle auto-crossfade on split
end

if ItemFadesOverride == 1 then
  if itemfades_option then r.Main_OnCommand(41194,0) end--Options: Toggle item crossfades
end

 r.PreventUIRefresh(-1)
    -------------------------------------------
    r.Undo_EndBlock("Slice", -1) 
 
end
::yyy::

end
end

-------------------------------------------------------------------------------------------------------------

function Wave:Quantize_Slices()

if SliceQ_Init_Status == 1 then
              
 r.Undo_BeginBlock() 
 r.PreventUIRefresh(1)
   -------------------------------------------

 count_itms =  r.CountSelectedMediaItems(0)

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

function quantize()

local i=0;

while(true) do
  i=i+1
  local item = r.GetSelectedMediaItem(0,i-1)
  if item then
        pos = r.GetMediaItemInfo_Value(item, "D_POSITION") + r.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")

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

        r.SetMediaItemInfo_Value(item, "D_POSITION", pos - q_strength / 100 * (pos - ( Arc_GetClosestGridDivision(pos))) - r.GetMediaItemInfo_Value(item, "D_SNAPOFFSET"))
  else
    break
  end

 if  grid_opt == 0 then r.Main_OnCommand(r.NamedCommandLookup('_BR_OPTIONS_SNAP_FOLLOW_GRID_VIS'), 0) end
 if  snap == 0 then r.Main_OnCommand(1157, 0) end
 if  grid == 0 then r.Main_OnCommand(40145, 0) end

end
r.UpdateArrange();
end

quantize()

cleanup_slices()

if XFadeOff == 0 then

  r.Main_OnCommand(r.NamedCommandLookup("_SWS_AWFILLGAPSQUICK"),0) -- fill gaps 

        CrossfadeT = x_fade

    local function Overlap(CrossfadeT);
        local t,ret = {};
        local items_count = r.CountSelectedMediaItems(0);
        if items_count == 0 then return 0 end;
        for i = 1 ,items_count do;
            local item = r.GetSelectedMediaItem(0,i-1);
            local trackIt = r.GetMediaItem_Track(item);
            if t[tostring(trackIt)] then;
                ----
                ret = 1;
                local crossfade_time = (CrossfadeT or 0)/1000;
                local take = r.GetActiveTake(item); 
                local pos = r.GetMediaItemInfo_Value(item,'D_POSITION');
                local length = r.GetMediaItemInfo_Value( item,'D_LENGTH');
                local SnOffs = r.GetMediaItemInfo_Value( item,'D_SNAPOFFSET');
                local rateIt = r.GetMediaItemTakeInfo_Value(take,'D_PLAYRATE');
                local ofSetIt = r.GetMediaItemTakeInfo_Value(take,'D_STARTOFFS');

                if pos < crossfade_time then crossfade_time = pos end;
                ----
                r.SetMediaItemInfo_Value(item,'D_POSITION',pos-crossfade_time);
                r.SetMediaItemInfo_Value(item,'D_LENGTH',length+crossfade_time);
                r.SetMediaItemTakeInfo_Value(take,'D_STARTOFFS',ofSetIt-(crossfade_time*rateIt));
                r.SetMediaItemInfo_Value(item,'D_SNAPOFFSET',SnOffs+crossfade_time);
            else;
                t[tostring(trackIt)] = trackIt;
            end;
        end;
        if ret == 1 then r.Main_OnCommand(41059,0) end;
        return ret or 0;
    end;
    
    r.Undo_BeginBlock();
    local Over = Overlap(CrossfadeT);
    r.Undo_EndBlock("Overlap",Over-Over*2);
    r.UpdateArrange();
end
       r.GetSetProjectGrid(proj, true, save_project_grid, save_swing, save_swing_amt) -- restore saved grid settings

 r.PreventUIRefresh(-1)
    -------------------------------------------
    r.Undo_EndBlock("Quantize Slices", -1)    

Slice_Status = 1
SliceQ_Status = 1
SliceQ_Init_Status = 0
Reset_Status = 1

end

end

---------------------------------------------------------------------------------------------------------

function Wave:Add_Markers()
MarkersQ_Status = 1
SliceQ_Init_Status = 0
Reset_Status = 1
 r.Undo_BeginBlock() 
r.PreventUIRefresh(1)

r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVESEL'), 0)  -- Save track selection

sel_tracks_items() -- select for a multitrack check
selected_tracks_count = r.CountSelectedTracks(0)
count_itms =  r.CountSelectedMediaItems(0)

if count_itms > selected_tracks_count  then
     if Slice_Status == 0 then 
             r.Main_OnCommand(40548, 0)  -- Heal Splits
     end
end

sel_tracks_items() -- select for a multitrack check
selected_tracks_count = r.CountSelectedTracks(0)
count_itms =  r.CountSelectedMediaItems(0)

if SliceQ_Status == 1 and count_itms > selected_tracks_count  then
 r.Main_OnCommand(40029, 0)  -- Undo
 r.Main_OnCommand(40029, 0)
end

if count_itms == selected_tracks_count and selected_tracks_count >1 then  -- multitrack

               r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVETIME1"),0)
               r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME2"),0);  -- Restore Selection
               r.Main_OnCommand(40061, 0) -- Item: Split items at time selection
sel_tracks_items() 

unselect_if_out_of_time_range()

               r.Main_OnCommand(40635, 0)     -- Remove Selection
               r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME1"),0)
               r.Main_OnCommand(40032, 0) -- Group Items

elseif count_itms > selected_tracks_count and selected_tracks_count >1 then  -- multitrack

               r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVETIME1"),0)
               r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME2"),0);  -- Restore Selection
               r.Main_OnCommand(40061, 0) -- Item: Split items at time selection
sel_tracks_items() 

unselect_if_out_of_time_range()

               r.Main_OnCommand(40635, 0)     -- Remove Selection
               r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME1"),0)
               r.Main_OnCommand(40032, 0) -- Group Items

end
 r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTORESEL'), 0)  -- Restore track selection

local cursorpos = r.GetCursorPosition()

if selected_tracks_count > 1 and count_itms == selected_tracks_count then --------------------RESET MULTITRACK (Markers)---------------------------

  r.Main_OnCommand(41844, 0) -- Remove Markers

else

if selected_tracks_count > 1 and count_itms > selected_tracks_count then --------------------RESET SLICED MULTITRACK (Markers)---------------------------

  r.Main_OnCommand(41844, 0) -- Remove Markers
             r.Main_OnCommand(40548, 0)  -- Heal Splits

 if Markers_Init_Status == 0 and Slice_Init_Status == 0 then---------------------------------glue------------------------------

sel_tracks_items() -- select for a multitrack check
selected_tracks_count = r.CountSelectedTracks(0)
count_itms =  r.CountSelectedMediaItems(0)

if selected_tracks_count > 1 and count_itms > selected_tracks_count then --------------------RESET SLICED MULTITRACK (Markers)---------------------------

          r.Main_OnCommand(41588, 0) -- glue 

   Wave:Destroy_Track_Accessor() -- Destroy previos AA
   if Wave:Create_Track_Accessor() then Wave:Processing() end

end
end
end
end 

sel_tracks_items() 
     if count_itms > selected_tracks_count and selected_tracks_count > 1 then
             r.Main_OnCommand(40548, 0)  -- Heal Splits
     end
 count_itms =  r.CountSelectedMediaItems(0)

function collect_itemtake_param()    -- collect parameter on sel item and active take for SM tables and displacement calcs...
   selected_tracks_count = r.CountSelectedTracks(0)
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item 
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   active_take = r.GetActiveTake(sel_item)  -- active take in item
 end
 
   collect_itemtake_param()              -- get bunch of parameters about this item (inc take playrate, I lifted this from another PL9 script)


if selected_tracks_count > 1 and count_itms == selected_tracks_count then
  r.Main_OnCommand(41844, 0) -- Remove Markers
end

Markers_Status = 1

r.SetEditCurPos(cursorpos,0,0) 
 r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTORESEL'), 0)  -- Restore track selection
r.PreventUIRefresh(-1)
   r.Undo_EndBlock("Reset (add markers)", -1)    


if count_itms == selected_tracks_count  then  -- sliced single track

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

            r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVETIME1"),0)
            r.Main_OnCommand(40290, 0) -- Set time selection to item
            r.Main_OnCommand(41843, 0)  ---Add Marker
            r.Main_OnCommand(40635, 0)     -- Remove Selection
            r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME1"),0)

     else -- Add Markers by Grid

      for i=1, #Grid_Points do
       
            r.SetEditCurPos(Grid_Points[i]/srate,0,0)
        
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
end

-------------------------------------------------------------------------------------------------------------

function Wave:Quantize_Markers()

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
while(true) do;
  i=i+1;
  local item = r.GetSelectedMediaItem(0,i-1);
  if item then;

    local q_force = q_strength or 100;
  
    if item then;
        local posIt = r.GetMediaItemInfo_Value(item,"D_POSITION");
        local take = r.GetActiveTake(item); 
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
        r.UpdateItemInProject(item);
    end;
  else;
    break;
  end;
end;

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

SliceQ_Init_Status = 1

Slice_Status = 1

if Reset_Status == 1 then

if Markers_Status ~= 0 or Slice_Init_Status ~= 0 then

 r.Undo_BeginBlock() 
r.PreventUIRefresh(1)
------------------------------------------------------------------------------------------
r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVESEL'), 0)  -- Save track selection

sel_tracks_items() -- select for a multitrack check
selected_tracks_count2 = r.CountSelectedTracks(0)
count_itms2 =  r.CountSelectedMediaItems(0)

if SliceQ_Status == 1 and count_itms2 > selected_tracks_count2  then
 r.Main_OnCommand(40029, 0)  -- Undo
  elseif  SliceQ_Status == 0 and count_itms2 > selected_tracks_count2  then
 r.Main_OnCommand(40548, 0)     -- Heal Slices
end

sel_tracks_items() 
count_itms =  r.CountSelectedMediaItems(0)

function collect_itemtake_param()    -- collect parameter on sel item and active take for SM tables and displacement calcs...
   selected_tracks_count = r.CountSelectedTracks(0)
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item 
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   active_take = r.GetActiveTake(sel_item)  -- active take in item
 end
 
   collect_itemtake_param()              -- get bunch of parameters about this item (inc take playrate, I lifted this from another PL9 script)

take_check()

if selected_tracks_count > 1 and count_itms == selected_tracks_count then

  r.Main_OnCommand(41844, 0) -- Remove Markers

else --------------------RESET MULTITRACK---------------------------
 r.Main_OnCommand(40548, 0)     -- Heal Slices
end 

if  Take_Check == 1 then

-----------------------------------Error Message------------------------------------------------

local timer = 2 -- Time in seconds
local time = os.time()
local function Msg()
   local char = gfx.getchar()
     if char == 27 or char == -1 or (os.time() - time) > timer then return end
local Get_Sel_ErrMsg = ErrMsg:new(660,450,260,25, 1, 1, 1, 1, "Something went wrong. Use Undo (Ctrl+Z)",    "Arial", 22)
local ErrMsg_TB = {Get_Sel_ErrMsg}
     for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
   gfx.update()
  r.defer(Msg)
end
end
Msg()

---------------------------------End of Error Message----------------------------------------------
Init()
 return 
end -- не запускать, если MIDI айтемы.

  end 
end

   -------------------------------------------

  r.Main_OnCommand(40033, 0) -- UnGroup
  r.Main_OnCommand(41844, 0) -- Remove Markers

sel_tracks_items() -- select for a multitrack check
selected_tracks_count = r.CountSelectedTracks(0)
count_itms =  r.CountSelectedMediaItems(0)

if count_itms > 1 and selected_tracks_count == count_itms then  -- multitrack
  r.Main_OnCommand(41844, 0) -- Remove Markers
end

r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTORESEL'), 0)  -- Restore track selection

 r.PreventUIRefresh(-1)
    -------------------------------------------
    r.Undo_EndBlock("Reset_All", -1)   
 
Reset_Status = 0
SliceQ_Status = 0
SliceQ_Init_Status = 0

end

-------------------------------------------------------------------------------------------------------

function Wave:Load_To_Sampler(sel_start, sel_end, track)

              r.Undo_BeginBlock()
             r.PreventUIRefresh(1) 

local trim_content_option
  if r.GetToggleCommandState(41117) == 1 then
    r.Main_OnCommand(41117,0)--Options: Toggle trim behind items when editing
    trim_content_option = 1
  end
MIDISampler = 1
r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVETIME1"),0)

ItemState = r.GetExtState('_Slicer_', 'GetItemState')

if  (ItemState=="ItemLoaded") then 

r.Main_OnCommand(40297,0) ----unselect all tracks

lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')   
item =  r.BR_GetMediaItemByGUID( 0, lastitem )
track = r.GetMediaItem_Track(item)

r.GetSet_LoopTimeRange2( 0, 1, 0, self.sel_start, self.sel_end, 0 )

r.SetTrackSelected( track, 1 )

             volume_ = r.GetMediaTrackInfo_Value(track,"D_VOL") -- Copy Vol
             solo_ = r.GetMediaTrackInfo_Value(track,"I_SOLO") -- Copy Solo
             mute_ = r.GetMediaTrackInfo_Value(track,"B_MUTE") -- Copy Mute
             pan_ = r.GetMediaTrackInfo_Value(track,"D_PAN") -- Copy Pan
             width_ = r.GetMediaTrackInfo_Value(track,"D_WIDTH") -- Copy Width

if MIDISamplerCopyFX == 1 then
             r.Main_OnCommand(r.NamedCommandLookup("_S&M_COPYFXCHAIN5"),0) -- Copy FX
end
             r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME1"),0)

elseif not (ItemState=="ItemLoaded") then 

self.sel_start = sel_start
self.sel_end = sel_end 

end

data ={}

obeynoteoff_default = 1

      if not track then return end
      nmb = r.GetMediaTrackInfo_Value(track,"IP_TRACKNUMBER");
      track = r.GetTrack(nmb-1,0);

function ExportItemToRS5K_defaults(data,conf,refresh,note,filepath, start_offs, end_offs, track)
    local rs5k_pos = r.TrackFX_AddByName( track, 'ReaSamplomatic5000', false, -1 )
    r.TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'FILE0', filepath)
    r.TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'DONE', '')      
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 2, 0) -- gain for min vel
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 3, note/127 ) -- note range start
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 4, note/127 ) -- note range end
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 5, 0.5 ) -- pitch for start
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 6, 0.5 ) -- pitch for end
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 8, 0 ) -- max voices = 0
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 9, 0 ) -- attack
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 11, obeynoteoff_default ) -- obey note offs
    if start_offs and end_offs then
      r.TrackFX_SetParamNormalized( track, rs5k_pos, 13, start_offs ) -- attack
      r.TrackFX_SetParamNormalized( track, rs5k_pos, 14, end_offs )   
    end  
  end


function ExportItemToRS5K(data,conf,refresh,note,filepath, start_offs, end_offs)
 
    if not note or not filepath then return end

     if note > 127 then return end
       ExportItemToRS5K_defaults(data,conf,refresh,note,filepath, start_offs, end_offs, track)
       return 1

  end

 function ExportSelItemsToRs5k_FormMIDItake_data()
    local MIDI = {}
    -- check for same track/get items info
      local item = r.GetSelectedMediaItem(0,0)
      if not item then return end
      MIDI.it_pos = r.GetMediaItemInfo_Value( item, 'D_POSITION' )
      MIDI.it_end_pos = MIDI.it_pos + 0.1
      local proceed_MIDI = true
      local it_tr0 = r.GetMediaItemTrack( item )
      for i = 1, r.CountSelectedMediaItems(0) do
        local item = r.GetSelectedMediaItem(0,i-1)
        local it_pos = r.GetMediaItemInfo_Value( item, 'D_POSITION' )
        local it_len = r.GetMediaItemInfo_Value( item, 'D_LENGTH' )
        MIDI[#MIDI+1] = {pos=it_pos, end_pos = it_pos+it_len}
        MIDI.it_end_pos = it_pos + it_len
        local it_tr = r.GetMediaItemTrack( item )
        if it_tr ~= it_tr0 then proceed_MIDI = false break end
      end
      
    return proceed_MIDI, MIDI
  end
  -------------------------------------------------------------------------------    
  function ExportSelItemsToRs5k_AddMIDI(track, MIDI, base_pitch)    
    if not MIDI then return end
      local new_it = r.CreateNewMIDIItemInProj( track, MIDI.it_pos, self.sel_end --[[MIDI.it_end_pos]] )
new_tk = r.GetActiveTake( new_it )
      for i = 1, #MIDI do
        local startppqpos =  r.MIDI_GetPPQPosFromProjTime( new_tk, MIDI[i].pos )
        local endppqpos =  r.MIDI_GetPPQPosFromProjTime( new_tk, MIDI[i].end_pos )
        local ret = r.MIDI_InsertNote( new_tk, 
            false, --selected, 
            false, --muted, 
            startppqpos, 
            endppqpos, 
            0, 
            base_pitch+i-1, 
            100, 
            true)--noSortInOptional )
        if base_pitch+i-1 == 127 then return end
      end
      r.MIDI_Sort( new_tk )
      r.GetSetMediaItemTakeInfo_String( new_tk, 'P_NAME', 'Sliced item', 1 )
      
      newmidiitem = r.GetMediaItemTake_Item(new_tk)
 
      r.SetMediaItemSelected( newmidiitem, 1 )

  if trim_content_option then r.Main_OnCommand(41117,0) end--Options: Toggle trim behind items when editing
      
      r.UpdateArrange()    
  end



function Load() 
               r.InsertTrackAtIndex(0,false);
               track = r.GetTrack(0,0);
                if not track then return end        
              -- item check
                local item = r.GetSelectedMediaItem(0,0)
                if not item then return true end  
              -- get base pitch
                MIDI_Base_Oct = tonumber(r.GetExtState('cool_MK Slicer.lua','MIDI_Base_Oct'))or 2;
                base_pitch = MIDI_Base_Oct*12 
              -- get info for new midi take
                local proceed_MIDI, MIDI = ExportSelItemsToRs5k_FormMIDItake_data()        
              -- export to RS5k
                for i = 1, r.CountSelectedMediaItems(0) do
                  local item = r.GetSelectedMediaItem(0,i-1)
                  
                  local take = r.GetActiveTake(item)                         

                  local it_len = r.GetMediaItemInfo_Value( item, 'D_LENGTH' )                 
          
                  if not take or r.TakeIsMIDI(take) then goto skip_to_next_item end
                  local tk_src =  r.GetMediaItemTake_Source( take )
                  local s_offs = r.GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
                  local src_len =r.GetMediaSourceLength( tk_src )
                  local filepath = r.GetMediaSourceFileName( tk_src, '' )
                  --msg(s_offs/src_len)
                  ExportItemToRS5K(data,conf,refresh,base_pitch + i-1,filepath, s_offs/src_len, (s_offs+it_len)/src_len)
                  r.SetTrackMIDINoteNameEx( 0, track, base_pitch-1 + i, 0, "Slice " .. 0+i) -- renaming notes in ME
                  ::skip_to_next_item::
                end
                   
                   r.Main_OnCommand(40548,0)--Item: Heal Splits   
                   r.Main_OnCommand(40719,0)--Item: Mute items     
              -- add MIDI
                if proceed_MIDI then ExportSelItemsToRs5k_AddMIDI(track, MIDI,base_pitch) end  
      
        track = r.GetSelectedTrack(0, 0)
        r.Main_OnCommand(40297,0) -- Unselect All Tracks
	first_track = r.GetTrack(0, 0)
          if first_track then
	      r.SetTrackSelected(first_track, true)

        end
        r.ReorderSelectedTracks(nmb+1, 0)

   function scroll_mcp()
      local i=0;
      while(true) do;
        i=i+1;
        local trk = r.GetSelectedTrack(0, i-1);
        if trk then;  
           if r.IsTrackVisible(trk, 1) then 
             r.SetMixerScroll(trk);
           end
        else;
          break;
        end;
      end;
    end
      
    r.defer(scroll_mcp)

        r.GetSetMediaTrackInfo_String(track, "P_NAME", "Sliced item", true)

            r.SetMediaTrackInfo_Value(track, "D_VOL", volume_) -- Paste Vol
            r.SetMediaTrackInfo_Value(track, "I_SOLO", solo_) -- Paste Solo
            r.SetMediaTrackInfo_Value(track, "B_MUTE", mute_) -- Paste Mute
            r.SetMediaTrackInfo_Value(track, "D_PAN", pan_) -- Paste Pan
            r.SetMediaTrackInfo_Value(track, "D_WIDTH", width_) -- Paste Width
            r.SetMediaTrackInfo_Value(track, "I_RECMON", 1) -- Set Monitoring

if MIDISamplerCopyRouting == 1 then
    desttrIn = r.GetSelectedTrack(0,0)
    local CountSend = r.GetTrackNumSends(track,0);
    for i = 1,CountSend do;
        copySendTrack(track,desttrIn,i-1);
    end;

    local CountReceives = r.GetTrackNumSends(track,-1);
    for i = 1,CountReceives do;
       copyReceiveTrack(track,desttrIn,i-1);
    end;
end

if MIDISamplerCopyFX == 1 then
             r.Main_OnCommand(r.NamedCommandLookup("_S&M_COPYFXCHAIN10"),0) -- Paste FX
end

             r.Main_OnCommand(r.NamedCommandLookup("_XENAKIOS_SELPREVTRACK"),0) -- Select previous track
    MIDISampler = 0
    MIDISmplr_Status = 1       
    Reset_Status = 0     
    r.PreventUIRefresh(-1)

        r.Main_OnCommand(40913,0) -- Track: Vertical scroll selected tracks into view
       -------------------------------------------
       r.Undo_EndBlock("Export To Sampler", -1)        
              
            end

take_check()
if  Take_Check == 0 then Load() end --

end

--------------------------------------------------------------------------------
---  Create MIDI  --------------------------------------------------------------
--------------------------------------------------------------------------------
-- Создает миди-ноты в соответствии с настройками и полученными из аудио данными
function Wave:Create_MIDI()
  r.Undo_BeginBlock() 
  -------------------------------------------
    local item, take = Wave:GetSet_MIDITake()
    if not take then return end 
    -- Velocity scale ----------
    local mode = VeloMode.norm_val
    local velo_scale  = Gate_VeloScale.form_val2 - Gate_VeloScale.form_val
    local velo_offset = Gate_VeloScale.form_val
    -- Note parameters ---------
    local pitch = 35 + OutNote.norm_val        -- pitch from checkbox
    local chan  = NoteChannel.norm_val - 1     -- midi channel from checkbox
    local len   = defPPQ/NoteLenghth.norm_val  -- note lenght(its always use def ppq(960)!)
    local sel, mute = 1, 0
    local startppqpos, endppqpos, vel, next_startppqpos
    ----------------------------
    local points_cnt = #Gate_Gl.Res_Points
    for i=1, points_cnt, 2 do
        startppqpos = r.MIDI_GetPPQPosFromProjTime(take, self.sel_start + Gate_Gl.Res_Points[i]/srate )
        endppqpos   =  startppqpos + len
        -- По идее,нет смысла по два раза считать,можно просто ставить предыдущую - переделать! --
        if i<points_cnt-2 then next_startppqpos = r.MIDI_GetPPQPosFromProjTime(take, self.sel_start + Gate_Gl.Res_Points[i+2]/srate )
           -- С учетом точек добавленных вручную(но, по хорошему, их надо было добавлять не в конец таблицы, а между текущими) --
           if next_startppqpos>startppqpos then  endppqpos = min(endppqpos, next_startppqpos) end -- del overlaps 
        end
        -- Insert Note ---------
        vel = floor(velo_offset + Gate_Gl.Res_Points[i+1][mode] * velo_scale)
     
        r.MIDI_InsertNote(take, sel, mute, startppqpos-1, endppqpos-2, chan, pitch, vel, true)
    end
    ----------------------------
    r.MIDI_Sort(take)           -- sort notes
    r.UpdateItemInProject(item) -- update item
    Trigg_Status = 1
    Reset_Status = 0
  -------------------------------------------
  r.Undo_EndBlock("Create Trigger MIDI", -1) 
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

      r.GetMediaItemTake_Track(tk)  
    
    self.track = r.GetMediaItemTake_Track(tk)
    if self.track then self.AA = r.CreateTrackAudioAccessor(self.track)

         self.AA_Hash  = r.GetAudioAccessorHash(self.AA, "")
         self.AA_start = r.GetAudioAccessorStartTime(self.AA)
         self.AA_end   = r.GetAudioAccessorEndTime(self.AA)
         self.buffer   = r.new_array(block_size)-- main block-buffer
         self.buffer.clear()
         return true
    end
end
end
end

--------
function Wave:Validate_Accessor()
    if self.AA then 
       if not r.AudioAccessorValidateState(self.AA) then return true end 
    end
end
--------
function Wave:Destroy_Track_Accessor()
   
if (getitem == 0) then
    if self.AA then r.DestroyAudioAccessor(self.AA) 
       self.buffer.clear()
    end
 end
end

--------
function Wave:Get_TimeSelection()

 local item = r.GetSelectedMediaItem(0,0)
    if item then
      local start, ending = r.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
      if start ~= ending then
          time_sel_length = ending - start
          else
          time_sel_length = 1
      end

 local sel_start = r.GetMediaItemInfo_Value(item, "D_POSITION")
         local sel_end = sel_start + r.GetMediaItemInfo_Value(item, "D_LENGTH")

    local sel_len = sel_end - sel_start
    if sel_len<0.25 or time_sel_length < 0.25 then return end -- 0.25 minimum
    -------------- 
    self.sel_start, self.sel_end, self.sel_len = sel_start,sel_end,sel_len  -- selection start, end, lenght
    return true
end
end

----------------------------------------------------------------------------------------------------
---  Wave(Processing, drawing etc)  ----------------------------------------------------------------
----------------------------------------------------------------------------------------------------
------------------------------------------------------------
-- Filter_FFT ----------------------------------------------
------------------------------------------------------------  
function Wave:Filter_FFT(lowband, hiband)
  local buf = self.buffer
    ----------------------------------------
    -- Filter(use fft_real) ----------------
    ----------------------------------------
    buf.fft_real(block_size,true)       -- FFT
      -----------------------------
      -- Clear lowband bins --
      buf.clear(0, 1, lowband)                  -- clear low bins
      -- Clear hiband bins  --
      buf.clear(0, hiband+1, block_size-hiband) -- clear hi bins
      -----------------------------  
    buf.ifft_real(block_size,true)      -- iFFT
    ----------------------------------------
end  

--------------------------------------------------------------------------------------------
--- DRAW -----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--- Draw Original,Filtered -----------------------------------------------------
--------------------------------------------------------------------------------
function Wave:Redraw()
  
    local x,y,w,h = self.def_xywh[1],self.def_xywh[2],self.def_xywh[3],self.def_xywh[4] 
    ---------------
    gfx.dest = 1           -- set dest gfx buffer1
    gfx.a    = 1           -- gfx.a - for buf    
    gfx.setimgdim(1,-1,-1) -- clear buf1(Wave)
    gfx.setimgdim(1,w,h)   -- set gfx buffer w,h
    ---------------
      if ViewMode.norm_val == 1 then self:draw_waveform(1,  0.12,0.32,0.57,1) -- Draw Original(1, r,g,b,a) -- цвет оригинальной и фильтрованной waveform
                                     self:draw_waveform(2,  0.75,0.2,0.25,1) -- Draw Filtered(2, r,g,b,a)
        elseif ViewMode.norm_val == 2 then self:draw_waveform(1,  0.17,0.37,0.67,1) -- Only original 0.3,0.4,0.7
        elseif ViewMode.norm_val == 3 then self:draw_waveform(2,  0.7,0.2,0.25,1) -- Only filtered 0.7,0.1,0.3
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
    local n_Peaks = w*self.max_Zoom        -- Макс. доступное кол-во пиков
    gfx.set(r,g,b,a)                       -- set color
    -- уточнить, нужно сделать исправление для неориг. размера окна --
    -- next выходит за w*max_Zoom, а должен - макс. w*max_Zoom(51200) при max_Zoom=50 --
    for i=1, w do            
       local next = min( i*Zfact + Ppos, n_Peaks ) -- грубоватое исправление...
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
        Peak_TB[#Peak_TB+1] = {min_smpl, max_smpl} -- min, max val to table
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
    -- Calculate some values --------
    self.sel_len    = min(self.sel_len,time_limit)     -- limit lenght(deliberate restriction) 
    self.selSamples = floor(self.sel_len*srate)        -- time selection lenght to samples
    -- init Horizontal --------------
    self.max_Zoom = 150 -- maximum zoom level(желательно ок.150-200,но зав. от длины выдел.(нужно поправить в созд. пиков!))
    self.Zoom = self.Zoom or 1  -- init Zoom 
    self.Pos  = self.Pos  or 0  -- init src position
    -- init Vertical ---------------- 
    self.max_vertZoom = 12       -- maximum vertical zoom level(need optim value)
    self.vertZoom = self.vertZoom or 1  -- init vertical Zoom 
    ---------------------------------
    -- pix_dens - нужно выбрать оптимум или оптимальную зависимость от sel_len!!!
    self.pix_dens = 2^(DrawMode.norm_val-1)            -- 1-учесть все семплы для прорисовки(max кач-во),2-через один и тд.
    self.X, self.Y  = x, h/2                           -- waveform position(X,Y axis)
    self.X_scale    = w/self.selSamples                -- X_scale = w/lenght in samples
    self.Y_scale    = h/2                              -- Y_scale for waveform drawing
    ---------------------------------
    -- Some other values ------------
    self.crsx   = block_size/16   -- one side "crossX"  -- use for discard some FFT artefacts(its non-nat, but in this case normally)
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
    local info_str = "Processing ."
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
        ------------------------------------------------------
        local size
        local buf_start = self.sel_start
        for i=1,  self.n_Full_Bufs+1 do 
            if i>self.n_Full_Bufs then size = self.rest_buf_sz else size = self.full_buf_sz end  

	            local GGG=size;
	            if size == 0 then goto TTT end;

            local tmp_buf = r.new_array(size)
            r.GetAudioAccessorSamples(self.AA, srate, 1, buf_start, size, tmp_buf) -- orig samples to in_buf for drawing
            --------
            if i==1 then self.in_buf = tmp_buf.table() else self:table_plus(1, (i-1)*self.full_buf_sz, tmp_buf.table() ) end
            --------
            buf_start = buf_start + self.full_buf_sz/srate -- to next
            ------------------------
            info_str = info_str.."."; self:show_info(info_str..".")  -- show info_str
        end
        self:Create_Peaks(1)  -- Create_Peaks input(Original) wave peaks
        self.in_buf  = nil    -- входной больше не нужен
	        ::TTT::
    end
    
    -------------------------------------------------------------------------
    -- Filtering >> samples to out_buf >> to table >> create peaks ----------
    -------------------------------------------------------------------------
    local size, n_XBlocks
    local buf_start = self.sel_start
    for i=1, self.n_Full_Bufs+1 do
       if i>self.n_Full_Bufs then size, n_XBlocks = self.rest_buf_sz, self.n_XBlocks_RB 
                             else size, n_XBlocks = self.full_buf_sz, self.n_XBlocks_FB
       end
       ------
	       if size == 0 then goto TTT2 end
       local tmp_buf = r.new_array(size)
       ---------------------------------------------------------
       local block_start = buf_start - (self.crsx/srate)   -- first block in current buf start(regard crsx)   
       for block=1, n_XBlocks do r.GetAudioAccessorSamples(self.AA, srate, 1, block_start, block_size, self.buffer)
           --------------------
           self:Filter_FFT(lowband, hiband)                -- Filter(note: don't use out of range freq!)
           tmp_buf.copy(self.buffer, self.crsx+1, self.Xblock, (block-1)* self.Xblock + 1 ) -- copy block to out_buf with offset
           --------------------
           block_start = block_start + self.Xblock/srate   -- next block start_time
       end
       ---------------------------------------------------------
       if i==1 then self.out_buf = tmp_buf.table() else self:table_plus(2, (i-1)*self.full_buf_sz, tmp_buf.table() ) end
       --------
       buf_start = buf_start + (self.full_buf_sz/srate) -- to next
       ------------------------
       info_str = info_str.."."; self:show_info(info_str..".")  -- show info_str
    end
    -------------------------------------------------------------------------
    self:Create_Peaks(2)  -- Create_Peaks output(Filtered) wave peaks
    -------------------------------------------------------------------------
    -------------------------------------------------------------------------
    self.State = true -- Change State
    -------------------------

	  ::TTT2::  
end 


----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
---  Wave - Get - Set Cursors  ---------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Wave:Get_Cursor() 
  local E_Curs = r.GetCursorPosition()
  --- edit cursor ---
  local insrc_Ecx = (E_Curs - self.sel_start) * srate * self.X_scale    -- cursor in source!
     self.Ecx = (insrc_Ecx - self.Pos) * self.Zoom*Z_w                  -- Edit cursor
     if self.Ecx >= 0 and self.Ecx <= self.w then gfx.set(0.7,0.8,0.9,1) -- edit cursor color -- цвет едит курсора
        gfx.line(self.x + self.Ecx, self.y, self.x + self.Ecx, self.y+self.h -1 )
     end
  --- play cursor ---
  if r.GetPlayState()&1 == 1 then local P_Curs = r.GetPlayPosition()
     local insrc_Pcx = (P_Curs - self.sel_start) * srate * self.X_scale -- cursor in source!
     self.Pcx = (insrc_Pcx - self.Pos) * self.Zoom*Z_w                  -- Play cursor
     if self.Pcx >= 0 and self.Pcx <= self.w then gfx.set(0.5,0.5,1,1) -- play cursor color  -- цвет плэй курсора
        gfx.line(self.x + self.Pcx, self.y, self.x + self.Pcx, self.y+self.h -1 )
     end

--------------------Auto-Scroll------------------------------------------------

if AutoScroll == 1 then

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
true_position = (gfx.mouse_x-self.x)/Z_w  -- корректировка для захвата краёв waveform
pos_margin = gfx.mouse_x-self.x
if true_position < 24 then pos_margin = 0 end
if true_position > 1000 then pos_margin = gfx.mouse_x end
self.insrc_mx_zoom = self.Pos + (pos_margin)/(self.Zoom*Z_w) -- its current mouse position in source!

if SnapToStart == 1 then
   true_position = (gfx.mouse_x-self.x)/Z_w  -- корректировка для cursor snap
   pos_margin = gfx.mouse_x-self.x
   if true_position < 12 then pos_margin = 0 end
    self.insrc_mx = self.Pos + (pos_margin)/(self.Zoom*Z_w) 
else
    self.insrc_mx = self.Pos + (gfx.mouse_x-self.x)/(self.Zoom*Z_w) -- old behavior
end

    ----------------------------- 
    --- Wave get-set Cursors ----
    self:Get_Cursor()
    self:Set_Cursor()   
    -----------------------------------------
    --- Wave Zoom(horizontal) ---------------
    if self:mouseIN() and gfx.mouse_wheel~=0 and not(Ctrl or Shift) then 
      M_Wheel = gfx.mouse_wheel
      -------------------
      if     M_Wheel>0 then self.Zoom = min(self.Zoom*1.25, self.max_Zoom)   
      elseif M_Wheel<0 then self.Zoom = max(self.Zoom*0.75, 1)
      end                 
      -- correction Wave Position from src --
      self.Pos = self.insrc_mx_zoom - (gfx.mouse_x-self.x)/(self.Zoom*Z_w)
      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
      -------------------
      Wave:Redraw() -- redraw after horizontal zoom
    end

    -----------------------------------------
    --- Wave Zoom(Vertical) -----------------
    if self:mouseIN() and Ctrl or Shift and gfx.mouse_wheel~=0 then 
     M_Wheel = gfx.mouse_wheel

------------------------------------------------------------------------------------------------------
     if     M_Wheel>0 then self.vertZoom = min(self.vertZoom*1.2, self.max_vertZoom)   
     elseif M_Wheel<0 then self.vertZoom = max(self.vertZoom*0.8, 1)
     end                 
     -------------------
     Wave:Redraw() -- redraw after vertical zoom
    end
    -----------------------------------------
    --- Wave Move ---------------------------
    if self:mouseM_Down() then 
      self.Pos = self.Pos + (last_x - gfx.mouse_x)/(self.Zoom*Z_w)
      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
      --------------------
      Wave:Redraw() -- redraw after move view
    end

     --------------------------------------------------------------------------------
     -- Zoom by Arrow Keys
     --------------------------------------------------------------------------------

    if char==30064 then KeyUP = 1 else KeyUP = 0 end -- up
    if char==1685026670 then KeyDWN = 1 else KeyDWN = 0 end -- down
    if char==1818584692 then KeyL = 1 else KeyL = 0 end -- left
    if char==1919379572 then KeyR = 1 else KeyR = 0 end -- right

-------------------------------horizontal----------------------------------------
     if  KeyR == 1 then self.Zoom = min(self.Zoom*1.2, self.max_vertZoom+138)   

      self.Pos = self.insrc_mx_zoom - (gfx.mouse_x-self.x)/(self.Zoom*Z_w)
      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )

     Wave:Redraw() -- redraw after horizontal zoom
     else
     end   

     if  KeyL == 1 then self.Zoom = max(self.Zoom*0.8, 1)

      self.Pos = self.insrc_mx_zoom - (gfx.mouse_x-self.x)/(self.Zoom*Z_w)
      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )

     Wave:Redraw() -- redraw after horizontal zoom
     else
     end   

-------------------------------vertical-------------------------------------------
     if  KeyUP == 1 then self.vertZoom = min(self.vertZoom*1.2, self.max_vertZoom)   
     Wave:Redraw() -- redraw after vertical zoom
     else
     end   

     if  KeyDWN == 1 then self.vertZoom = max(self.vertZoom*0.8, 1)
     Wave:Redraw() -- redraw after vertical zoom
     else
     end   

end

--------------------------------------------------------------------------------
---  Insert from buffer(inc. Get_Mouse) ----------------------------------------
--------------------------------------------------------------------------------
function Wave:from_gfxBuffer()
  self:update_xywh()   -- update coord
  -- draw Wave frame, axis -------------
  self:draw_rect()
  gfx.set(0,0,0,0.2) -- set color -- цвет рамки вокруг wave окна
  gfx.line(self.x, self.y+self.h/2, self.x+self.w-1, self.y+self.h/2 )
  self:draw_frame() 
   -- Insert Wave from gfx buffer1 ------
  gfx.a = 1 -- gfx.a for blit
  local srcw, srch = Wave.def_xywh[3], Wave.def_xywh[4] -- its always def values 
  gfx.blit(1, 1, 0, 0, 0, srcw, srch,  self.x, self.y, self.w, self.h)
  -- Get Mouse -------------------------
  self:Get_Mouse()     -- get mouse(for zoom, move etc) 
end  

--------------------------------------------------------------------------------
---  Wave - show_help, info ----------------------------------------------------
--------------------------------------------------------------------------------
function Wave:show_help()
 local fnt_sz = 15
 fnt_sz = max(17,  fnt_sz* (Z_h)/2)
 fnt_sz = min(24, fnt_sz* Z_h)
 gfx.setfont(1, "Arial", fnt_sz)
 gfx.set(0.7, 0.7, 0.7, 1) -- цвет текста инфо
ZH_correction = Z_h*40
 gfx.x, gfx.y = (self.x+23 * (Z_w+Z_h)-ZH_correction), self.y+5*(Z_h*3)
 gfx.drawstr(
  [[
    Select an item (max 300s).
    It is better not to use items longer than 60s.
    Press "Get Item" button.
    Use sliders to change detection setting.
    Shift+Drag - fine tune,
    Ctrl+Left Click - reset value to default,
    Space - Play. 
    Esc - Close Slicer.
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

--------------------------------
function Wave:show_info(info_str)
  if self.State or self.sel_len<15 then return end
  gfx.update()
  gfx.setfont(1, "Arial", 40)
  gfx.set(0.7, 0.7, 0.4, 1)
  gfx.x = self.x+self.w/2-200; gfx.y = self.y+(self.h)/2
  gfx.drawstr(info_str)
  gfx.update()
end

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
---   MAIN   ---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function MAIN()
  if Project_Change() then
   
     if not Wave:Verify_Project_State() then 
     
     Wave.State = false end  
  end
  -- Draw Wave, lines etc ------
  if Wave.State then 
      
       Wave:from_gfxBuffer() -- Wave from gfx buffer
       Gate_Gl:draw_Lines()  -- Draw Gate trig-lines
  
  else Wave:show_help()      -- else show help
  end
  -- Draw sldrs, btns etc ------
 draw_controls()
 
end


--------------------------------
-- Get Project Change ----------
--------------------------------
function Project_Change()
    local cur_cnt = r.GetProjectStateChangeCount(0)
    if cur_cnt ~= proj_change_cnt then proj_change_cnt = cur_cnt
       return true  
    end
end
--------------------------------
-- Verify Project State --------
--------------------------------
function Wave:Verify_Project_State() -- 
    if self.AA and r.ValidatePtr2(0, self.track, "MediaTrack*") then
          return true 
   end
end 

--------------------------------------------------------------------------------
--   Draw controls(buttons,sliders,knobs etc)  ---------------------------------
--------------------------------------------------------------------------------
function draw_controls()
    for key,btn    in pairs(Button_TB)   do btn:draw()    end 

   if (Midi_Sampler.norm_val == 2) then
   
    for key,sldr   in pairs(Slider_TB_Trigger)   do sldr:draw()   end

  else
  
  if (exept == 1) then
  for key,sldr   in pairs(Exception)   do sldr:draw()   end
  exept = 0
  end
       if XFadeOff == 1 then
         for key,sldr   in pairs(Slider_TB_XFadeOff)   do sldr:draw()   end
       else
         for key,sldr   in pairs(Slider_TB)   do sldr:draw()   end
       end
  end
   
    for key,ch_box in pairs(CheckBox_TB) do ch_box:draw() end
    for key,frame  in pairs(Frame_TB)    do frame:draw()  end       
end

function store_settings() --store dock position
    r.SetExtState("cool_MK Slicer.lua", "dock", gfx.dock(-1), true)
end

--------------------------------------------------------------------------------
--   INIT   --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Init()
   dock_pos = r.GetExtState("cool_MK Slicer.lua", "dock")
       if Docked == 1 then
         if dock_pos == "0.0" then dock_pos = 1025 end
           dock_pos = dock_pos or 1025
           xpos = 400
           ypos = 320
           else
           dock_pos = 0
           xpos = r.GetExtState("cool_MK Slicer.lua", "window_x") or 400
           ypos = r.GetExtState("cool_MK Slicer.lua", "window_y") or 320

        end

    -- Some gfx Wnd Default Values ---------------
    local R,G,B = 45,45,45              -- 0...255 format -- цвет основного окна
    local Wnd_bgd = R + G*256 + B*65536 -- red+green*256+blue*65536  
    local Wnd_Title = "MK Slicer v1.4.4"
    local Wnd_Dock, Wnd_X,Wnd_Y = dock_pos, xpos, ypos
 --   Wnd_W,Wnd_H = 1044,490 -- global values(used for define zoom level)

       Wnd_W = r.GetExtState("cool_MK Slicer.lua", "zoomW") or 1044
       Wnd_H = r.GetExtState("cool_MK Slicer.lua", "zoomH") or 490
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
---------------------------------------
--   Mainloop   ------------------------
---------------------------------------
function mainloop()
    -- zoom level -- 
    Wnd_WZ = r.GetExtState("cool_MK Slicer.lua", "zoomWZ") or 1044
    Wnd_HZ = r.GetExtState("cool_MK Slicer.lua", "zoomHZ") or 490
    if Wnd_WZ == (nil or "") then Wnd_WZ = 1044 end
    if Wnd_HZ == (nil or "") then Wnd_HZ = 490 end

    Z_w, Z_h = gfx.w/Wnd_WZ, gfx.h/Wnd_HZ

    if Z_w<0.63 then Z_w = 0.63 elseif Z_w>1.9 then Z_w = 1.9 end 
    if Z_h<0.63 then Z_h = 0.63 elseif Z_h>1.9 then Z_h = 1.9 end 

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
    -- MAIN function --------
    -------------------------
    MAIN() -- main function
    -------------------------
    -------------------------
    last_mouse_cap = gfx.mouse_cap
    last_x, last_y = gfx.mouse_x, gfx.mouse_y
    gfx.mouse_wheel = 0 -- reset mouse_wheel
    char = gfx.getchar()

    if char==32 then r.Main_OnCommand(40044, 0) end -- play
    
     if char==26 then 

r.Main_OnCommand(40029, 0)  

SliceQ_Init_Status = 0
Slice_Status = 1
MarkersQ_Status = 1
--SliceQ_Status = 0

end ---undo
   
if EscToExit == 1 then
      if char == 27 then gfx.quit() end   -- escape 
end

     if char~=-1 then r.defer(mainloop)              -- defer
       
       else 

    end       
   
    -----------  
    gfx.update()
    -----------

function store_window() -- store window dock state/position/size
  local _, xpos, ypos, Wnd_W, Wnd_H = gfx.dock(-1, 0, 0, 0, 0)
    r.SetExtState("cool_MK Slicer.lua", "window_x", xpos, true)
    r.SetExtState("cool_MK Slicer.lua", "window_y", ypos, true)
    r.SetExtState("cool_MK Slicer.lua", "zoomW", Wnd_W, true)
    r.SetExtState("cool_MK Slicer.lua", "zoomH", Wnd_H, true)
    r.SetExtState("cool_MK Slicer.lua", "zoomWZ", Wnd_WZ, true)
    r.SetExtState("cool_MK Slicer.lua", "zoomHZ", Wnd_HZ, true)
end

end

function getitem()

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
      end
   end
-----------------------------------------------------------------

if Muted == 1 then
r.Main_OnCommand(40175, 0) 
end
r.PreventUIRefresh(-1)
    r.Undo_EndBlock("Toggle Item Mute", -1) 

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

item2 = context_menu:add_item({label = "Donate", toggleable = false})
item2.command = function()
                     OpenURL('https://paypal.me/MKokarev')
end

item3 = context_menu:add_item({label = "Forum Thread|", toggleable = false})
item3.command = function()
                     OpenURL('https://forum.cockos.com/showthread.php?p=2255547')
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
    r.SetExtState("cool_MK Slicer.lua", "window_x", xpos, true)
    r.SetExtState("cool_MK Slicer.lua", "window_y", ypos, true)
    r.SetExtState("cool_MK Slicer.lua", "zoomW", Wnd_W, true)
    r.SetExtState("cool_MK Slicer.lua", "zoomH", Wnd_H, true)
    r.SetExtState("cool_MK Slicer.lua", "zoomWZ", Wnd_WZ, true)
    r.SetExtState("cool_MK Slicer.lua", "zoomHZ", Wnd_HZ, true)

gfx.quit()
     Docked = 1
     dock_pos = r.GetExtState("cool_MK Slicer.lua", "dock")
     if dock_pos == "0.0" then dock_pos = 1025 end
     dock_pos = dock_pos or 1025
     xpos = 400
     ypos = 320
     local Wnd_Title = "MK Slicer v1.4.4"
     local Wnd_Dock, Wnd_X,Wnd_Y = dock_pos, xpos, ypos
     gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )

                     else

    r.SetExtState("cool_MK Slicer.lua", "dock", gfx.dock(-1), true)
gfx.quit()
    Docked = 0
    dock_pos = 0
    xpos = r.GetExtState("cool_MK Slicer.lua", "window_x") or 400
    ypos = r.GetExtState("cool_MK Slicer.lua", "window_y") or 320
    local Wnd_Title = "MK Slicer v1.4.4"
    local Wnd_Dock, Wnd_X,Wnd_Y = dock_pos, xpos, ypos
    gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )
 
    Wnd_WZ = r.GetExtState("cool_MK Slicer.lua", "zoomWZ") or 1044
    Wnd_HZ = r.GetExtState("cool_MK Slicer.lua", "zoomHZ") or 490
    if Wnd_WZ == (nil or "") then Wnd_WZ = 1044 end
    if Wnd_HZ == (nil or "") then Wnd_HZ = 490 end
 
    Z_w, Z_h = gfx.w/Wnd_WZ, gfx.h/Wnd_HZ
 
    if Z_w<0.63 then Z_w = 0.63 elseif Z_w>1.9 then Z_w = 1.9 end 
    if Z_h<0.63 then Z_h = 0.63 elseif Z_h>1.9 then Z_h = 1.9 end 
                     end
          r.SetExtState('cool_MK Slicer.lua','Docked',Docked,true);
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
          r.SetExtState('cool_MK Slicer.lua','EscToExit',EscToExit,true);
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
          r.SetExtState('cool_MK Slicer.lua','AutoScroll',AutoScroll,true);
end


if SnapToStart == 1 then
item8 = context_menu:add_item({label = "Snap Play Cursor to Waveform Start|", toggleable = true, selected = true})
else
item8 = context_menu:add_item({label = "Snap Play Cursor to Waveform Start|", toggleable = true, selected = false})
end
item8.command = function()
                     if item8.selected == true then 
                     SnapToStart = 1
                     else
                     SnapToStart = 0
                     end
          r.SetExtState('cool_MK Slicer.lua','SnapToStart',SnapToStart,true);
end


if MIDISamplerCopyFX == 1 then
item9 = context_menu:add_item({label = "Sampler: Copies FX from the Original Track to a New one", toggleable = true, selected = true})
else
item9 = context_menu:add_item({label = "Sampler: Copies FX from the Original Track to a New one", toggleable = true, selected = false})
end
item9.command = function()
                     if item9.selected == true then 
                     MIDISamplerCopyFX = 1
                     else
                     MIDISamplerCopyFX = 0
                     end
          r.SetExtState('cool_MK Slicer.lua','MIDISamplerCopyFX',MIDISamplerCopyFX,true);
end 


if MIDISamplerCopyRouting == 1 then
item10 = context_menu:add_item({label = "Sampler: Copies Routing from the Original Track to a New one", toggleable = true, selected = true})
else
item10 = context_menu:add_item({label = "Sampler: Copies Routing from the Original Track to a New one", toggleable = true, selected = false})
end
item10.command = function()
                     if item10.selected == true then 
                     MIDISamplerCopyRouting = 1
                     else
                     MIDISamplerCopyRouting = 0
                     end
          r.SetExtState('cool_MK Slicer.lua','MIDISamplerCopyRouting',MIDISamplerCopyRouting,true);
end


if MIDI_Mode == 1 then
item11 = context_menu:add_item({label = "Trigger Mode by Default (Restart required)|", toggleable = true, selected = true})
else
item11 = context_menu:add_item({label = "Trigger Mode by Default (Restart required)|", toggleable = true, selected = false})
end
item11.command = function()
                     if item11.selected == true then 
                     MIDI_Mode = 1
                     else
                     MIDI_Mode = 0
                     end
          r.SetExtState('cool_MK Slicer.lua','MIDI_Mode',MIDI_Mode,true);
end 


if ObeyingTheSelection == 1 then
item12 = context_menu:add_item({label = "Start the Script or 'Get Item' Obeying Time Selection, if any", toggleable = true, selected = true})
else
item12 = context_menu:add_item({label = "Start the Script or 'Get Item' Obeying Time Selection, if any", toggleable = true, selected = false})
end
item12.command = function()
                     if item12.selected == true then 
                     ObeyingTheSelection = 1
                     else
                     ObeyingTheSelection = 0
                     end
          r.SetExtState('cool_MK Slicer.lua','ObeyingTheSelection',ObeyingTheSelection,true);
end


if ObeyingItemSelection == 1 then
           item13 = context_menu:add_item({label = "Time Selection Require Item(s) Selection|", toggleable = true, selected = true, active = true})
           else
           item13 = context_menu:add_item({label = "Time Selection Require Item(s) Selection|", toggleable = true, selected = false, active = true})
end
item13.command = function()
                     if item13.selected == true then 
                     ObeyingItemSelection = 1
                     else
                     ObeyingItemSelection = 0
                     end
          r.SetExtState('cool_MK Slicer.lua','ObeyingItemSelection',ObeyingItemSelection,true);

end


item14 = context_menu:add_item({label = ">User Settings (Advanced)"})
item14.command = function()

end


item15 = context_menu:add_item({label = "Set User Defaults", toggleable = false})
item14.command = function()
user_defaults()
end


item16 = context_menu:add_item({label = "Reset All Setted User Defaults", toggleable = false})
item15.command = function()

      r.SetExtState('cool_MK Slicer.lua','DefaultXFadeTime',15,true);
      r.SetExtState('cool_MK Slicer.lua','DefaultQStrength',100,true);
      r.SetExtState('cool_MK Slicer.lua','DefaultLP',1,true);
      r.SetExtState('cool_MK Slicer.lua','DefaultHP',0.3312,true);
      r.SetExtState('cool_MK Slicer.lua','DefaultSens',0.375,true);
      r.SetExtState('cool_MK Slicer.lua','DefaultOffset',0.5,true);
      r.SetExtState('cool_MK Slicer.lua','MIDI_Base_Oct',2,true);

end


item17 = context_menu:add_item({label = "|XFades and Fill Gaps On/Off (Experimental)", toggleable = false})
item16.command = function()
 if XFadeOff == 1 then XFadeOff = 0
elseif XFadeOff == 0 then XFadeOff = 1
end
      r.SetExtState('cool_MK Slicer.lua','XFadeOff',XFadeOff,true);
end


item18 = context_menu:add_item({label = "|Reset Sliders to User Defaults (Restart required)|<", toggleable = false})
item17.command = function()

      DefaultXFadeTime = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultXFadeTime'))or 15;
      DefaultQStrength = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultQStrength'))or 100;
      DefaultHP = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultHP'))or 0.3312;
      DefaultLP = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultLP'))or 1;
      DefaultSens = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultSens'))or 0.375;
      DefaultOffset = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultOffset'))or 0.5;

      r.SetExtState('cool_MK Slicer.lua','CrossfadeTime',DefaultXFadeTime,true);
      r.SetExtState('cool_MK Slicer.lua','QuantizeStrength',DefaultQStrength,true);
      r.SetExtState('cool_MK Slicer.lua','Offs_Slider',DefaultOffset,true);
      r.SetExtState('cool_MK Slicer.lua','HF_Slider',DefaultHP,true);
      r.SetExtState('cool_MK Slicer.lua','LF_Slider',DefaultLP,true);
      r.SetExtState('cool_MK Slicer.lua','Sens_Slider',DefaultSens,true);

end


item19 = context_menu:add_item({label = "|Reset Window Size", toggleable = false})
item18.command = function()
store_window()
           xpos = r.GetExtState("cool_MK Slicer.lua", "window_x") or 400
           ypos = r.GetExtState("cool_MK Slicer.lua", "window_y") or 320
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
DefaultXFadeTime = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultXFadeTime'))or 15;
DefaultQStrength = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultQStrength'))or 100;
DefaultHP = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultHP'))or 0.3312;
DefaultLP = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultLP'))or 1;
DefaultSens = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultSens'))or 0.375;
DefaultOffset = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultOffset'))or 0.5;
MIDI_Base_Oct = tonumber(r.GetExtState('cool_MK Slicer.lua','MIDI_Base_Oct'))or 2;

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

local values = tostring(DefaultXFadeTime)
..","..tostring(DefaultQStrength)
..","..tostring(DefaultHP)
..","..tostring(DefaultLP)
..","..tostring(DefaultSens)
..","..tostring(DefaultOffset)
..","..tostring(MIDI_Base_Oct)

local retval, value = r.GetUserInputs("User Defaults", 7, "Crossfade Time (0 - 50) ms ,Quantize Strength (0 - 100) % ,LowCut Slider (20 - 20000) Hz ,High Cut Slider (20 - 20000) Hz ,Sensitivity (2 - 10) dB ,Offset Slider (-100 - +100) ,Sampler Base Octave (0 - 9) ", values)
   if retval then
     local val1, val2, val3, val4, val5, val6, val7 = value:match("([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")

      DefaultXFadeTime2 = tonumber(val1)
      DefaultQStrength2 = tonumber(val2)
      DefaultHP2 = tonumber(val3)
      DefaultLP2 = tonumber(val4)
      DefaultSens2 = tonumber(val5)
      DefaultOffset2 = tonumber(val6)
      MIDI_Base_Oct2 = tonumber(val7)

     if not DefaultXFadeTime2 or not DefaultQStrength2 or not DefaultOffset2 or not DefaultHP2 or not DefaultLP2 or not MIDI_Base_Oct2 or not DefaultSens2 then 
     r.MB('Please enter a number', 'Error', 0) goto first_string end

if DefaultXFadeTime2 < 0 then DefaultXFadeTime2 = 0 elseif DefaultXFadeTime2 > 50 then DefaultXFadeTime2 = 50 end
if DefaultQStrength2 < 0 then DefaultQStrength2 = 0 elseif DefaultQStrength2 > 100 then DefaultQStrength2 = 100 end
if DefaultHP2 < 20 then DefaultHP2 = 20 elseif DefaultHP2 > 20000 then DefaultHP2 = 20000 end
if DefaultLP2 < 20 then DefaultLP2 = 20 elseif DefaultLP2 > 20000 then DefaultLP2 = 20000 end
if DefaultSens2 < 2 then DefaultSens2 = 2 elseif DefaultSens2 > 10 then DefaultSens2 = 10 end
if DefaultOffset2 < -100 then DefaultOffset2 = -100 elseif DefaultOffset2 > 100 then DefaultOffset2 = 100 end
if MIDI_Base_Oct2 < 0 then MIDI_Base_Oct2 = 0 elseif MIDI_Base_Oct2 > 9 then MIDI_Base_Oct2 = 9 end

local function fromHertz(val); -- hz to val
    local a,b,c = 20,639.3,20000;
    local d = ((c-b)/(b-a))^2;
    return logx(1-((1-d)/(c-a))*(val-a),d);
end;

DefaultLP2 = fromHertz(DefaultLP2)
DefaultHP2 = fromHertz(DefaultHP2)
DefaultSens2 = (DefaultSens2-2)/8
DefaultOffset2 = ((DefaultOffset2/100)+1)/2

          r.SetExtState('cool_MK Slicer.lua','DefaultXFadeTime',DefaultXFadeTime2,true);
          r.SetExtState('cool_MK Slicer.lua','DefaultQStrength',DefaultQStrength2,true);
          r.SetExtState('cool_MK Slicer.lua','DefaultLP',DefaultLP2,true);
          r.SetExtState('cool_MK Slicer.lua','DefaultHP',DefaultHP2,true);
          r.SetExtState('cool_MK Slicer.lua','DefaultSens',DefaultSens2,true);
          r.SetExtState('cool_MK Slicer.lua','DefaultOffset',DefaultOffset2,true);
          r.SetExtState('cool_MK Slicer.lua','MIDI_Base_Oct',MIDI_Base_Oct2,true);

end
end
-----------------------end of User Defaults form--------------------------------

function ClearExState()

r.DeleteExtState('_Slicer_', 'ItemToSlice', 0)
r.DeleteExtState('_Slicer_', 'TrackForSlice', 0)
r.SetExtState('_Slicer_', 'GetItemState', 'ItemNotLoaded', 0)
store_settings ()
store_window()
SetButtonOFF()
end

r.atexit(ClearExState)

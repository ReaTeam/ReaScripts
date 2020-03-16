-- @description MK Slicer
-- @author cool
-- @version 1.3
-- @changelog
--   ! MK Slicer (Non-Destructive) renamed to MK Slicer. Old MK Slicer has been removed.
--   + Improved Slicer accuracy
--   + Improved MIDI Trigger accuracy
--   + New slider Quantizing Strength 
--   + New slider Crossfades Length
--   + New Slice Quantizing algorithm. Quantizing items to swing grid now able!
--   + Addition Ctrl+Wheel for vertical zoom. May be handle for mac users.
--   + Zoom by Arrow Keys available. May be handle for notebook users.
--   + New internal crossfades algorithm. No more SWS setups.
--   + View Gain renamed to Filtered Gain, to avoid misunderstanding.
--   + Some minor changes/improvements
--   + User Area (set defaults inside the script):
--   Docked/Windowed Start
--   Esc to Exit (on/off)
--   MIDI_Base_Oct - Define Start octave for Export to MIDI Sampler
--   Default Crossfade Time in ms. (0 = Crossfades Off)
--   Default Quantize Strength in %. (0 = Quantize Off)
--   Default MIDI Mode (Sampler or Trigger)
--   Override Reaper option "Toggle auto-crossfade on split" (on/off)
--   Override Reaper option "Toggle enable/disable default fadein/fadeout" (on/off)
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

-- @description MK Slicer
-- @author cool
-- @version 1.3
-- @provides [main] cool_MK Slicer/cool_MK Slicer.lua
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=232672
-- @donation Donate via PayPal https://www.paypal.me/MKokarev
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
--    - Ability to work with mul--[[
MK Slicer v1.3 by Maxim Kokarev 
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
--|
--|
--|
--|
--|
--|
-------------------------------User Area-------------------------------------------

Docked = 0              -- (1 - Script starts docked, 0 - Windowed) 
EscToExit = 1           -- (Use ESC to close script? 1 - Yes, 0 - No.)
MIDI_Base_Oct = 2         -- (Start note for Export to MIDI Sampler. 0 = C-1, 1 = C0, 2 = C1, etc)
CrossfadeTime = 15   -- (Default Crossfades Length in ms. 0 = Crossfades Off, max. 50)
QuantizeStrength = 100 -- (Default Quantize Strength in %. 0 = Quantize Off, max. 100)
MIDI_Mode = 1             --  (Default MIDI Mode. 1 = Sampler, 2 = Trigger)

-------------------------------Advanced-------------------------------------------

AutoXFadesOnSplitOverride = 1 -- (Override "Options: Toggle auto-crossfade on split" option. 0 - Don't Override, 1 - Override)
ItemFadesOverride = 1 -- (Override "Item: Toggle enable/disable default fadein/fadeout" option. 0 - Don't Override, 1 - Override)

---------------------------End of User Area----------------------------------------
--|
--|
--|
--|
--|
--|
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

Slice_Status = 0
SliceQ_Status = 0
Markers_Status = 0

    r.Undo_BeginBlock() 
r.PreventUIRefresh(1)
local cursorpos = r.GetCursorPosition()

            r.Main_OnCommand(40290, 0) -- Set time selection to item
            r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVETIME1'), 0) 
            r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVEALLSELITEMS1'), 0)
            r.Main_OnCommand(40635, 0)     -- Remove Selection

r.SetEditCurPos(cursorpos,0,0) 
r.PreventUIRefresh(-1)
    r.Undo_EndBlock("Init", -1) 
---------------------------------Prepare Item(s) and Foolproof----------------------------------------------

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
	r.SetOnlyTrackSelected(first_track)
	r.SetTrackSelected(first_track, false)
end

sel_tracks_items() 

function collect_itemtake_param()    -- collect parameter on sel item and active take for SM tables and displacement calcs...
   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   take_start_offset = r.GetMediaItemTakeInfo_Value(active_take, "D_STARTOFFS") -- take offset
   src = r.GetMediaItemTake_Source(active_take)
   srate =  r.GetMediaSourceSampleRate(src) -- take samplerate (simple wave/MIDI detection)
 end
 
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item 
   collect_itemtake_param()              -- get bunch of parameters about this item

if selected_tracks_count > 1 then gfx.quit() return end -- не запускать, если айтемы находятся на разных треках.

if  srate == 0 then gfx.quit() return end -- не запускать, если MIDI айтем.

 if number_of_takes ~= 1 and srate ~= nil then
 
r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то клей, попытка не деструктивно склеить).

end

   collect_itemtake_param()    

 if number_of_takes ~= 1 and srate ~= nil then -- проверяем ещё раз. Если не удалось, клеим деструктивно.
 
 r.Main_OnCommand(41588, 0) -- glue (если больше одного айтема и не миди айтем, то клей).
  
  end
--------------------------------------UA  protection--------------------------------------------------

if Docked == nil then Docked = 0 end 
if Docked > 1 then Docked = 1 end 
if Docked < 0 then Docked = 0 end 
if EscToExit == nil then EscToExit = 1 end 
if EscToExit > 1 then EscToExit = 1 end 
if EscToExit < 0 then EscToExit = 0 end 
if MIDI_Base_Oct == nil then MIDI_Base_Oct = 2 end 
if MIDI_Base_Oct > 7 then MIDI_Base_Oct = 7 end 
if MIDI_Base_Oct < 0 then MIDI_Base_Oct = 0 end 
if CrossfadeTime == nil then CrossfadeTime = 50 end 
if CrossfadeTime > 50 then CrossfadeTime = 50 end 
if CrossfadeTime < 0 then CrossfadeTime = 0 end 
if QuantizeStrength == nil then QuantizeStrength = 100 end 
if QuantizeStrength > 100 then QuantizeStrength = 100 end 
if QuantizeStrength < 0 then QuantizeStrength = 0 end 
if MIDI_Mode == nil then MIDI_Mode = 1 end 
if MIDI_Mode > 2 then MIDI_Mode = 2 end 
if MIDI_Mode < 1 then MIDI_Mode = 1 end 
if AutoXFadesOnSplitOverride == nil then AutoXFadesOnSplitOverride = 1 end 
if AutoXFadesOnSplitOverride > 1 then AutoXFadesOnSplitOverride = 1 end 
if AutoXFadesOnSplitOverride < 0 then AutoXFadesOnSplitOverride = 0 end 
if ItemFadesOverride == nil then ItemFadesOverride = 1 end 
if ItemFadesOverride > 1 then ItemFadesOverride = 1 end 
if ItemFadesOverride < 0 then ItemFadesOverride = 0 end 

--------------------------------Save Item Position and Fade-out length-------------------------------

PosTable = {}
PosTable2 = {}
function savepos()
firstItem = r.GetSelectedMediaItem(0, 0)
if firstItem == nil then return end
firstItemPosition = r.GetMediaItemInfo_Value(firstItem, "D_POSITION")
fadeoutlength = r.GetMediaItemInfo_Value(firstItem, "D_FADEOUTLEN")
PosTable[firstItem] = firstItemPosition
PosTable2[firstItem] = fadeoutlength
end
savepos()

function restorepos()
firstItem2 = r.GetSelectedMediaItem(0, 0)
if firstItem2 == nil then return end
if PosTable[firstItem] == nil then return end
firstItemPosition2 = r.SetMediaItemInfo_Value(firstItem2, "D_POSITION", PosTable[firstItem])
fadeoutlength2 = r.SetMediaItemInfo_Value(firstItem2, "D_FADEOUTLEN", PosTable2[firstItem])
end
-------------------------------------------------------------------------------------------------------


---------------------Item;  Remove selected overlapped items (by tracks)------------------------------

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
--------------------------------------------------------------------------------------------------

--------------------Remove Last Item (obeying Time Selection)-------------------------------------

local function remove_last();

    -------------------------------------------------------
    local function no_undo()r.defer(function()end)end;
    -------------------------------------------------------
 
    
    local CountSelItem = r.CountSelectedMediaItems(0);
    if CountSelItem == 0 then no_undo() return end;
    
    local t = {};
    local tblTrack = {};
    for i = 1, CountSelItem do; -- Get tracks from items

        local item = r.GetSelectedMediaItem(0,i-1);
        local track = r.GetMediaItem_Track(item);
        if not t[tostring(track)]then;
            t[tostring(track)] = track;
            tblTrack[#tblTrack+1] = track;
        end;
    end;
    
    local UNDO;
    local timeSelStart,timeSelEnd = r.GetSet_LoopTimeRange(0,0,0,0,0);


        for i = 1, #tblTrack do;
            local X = 0;
            local cntIt = 0;
            local CountTrItem = r.CountTrackMediaItems(tblTrack[i]);
            for it = CountTrItem-1,0,-1 do;         
                local itemTr = r.GetTrackMediaItem(tblTrack[i],it);
                local posIt = r.GetMediaItemInfo_Value(itemTr,'D_POSITION');
                local lenIt = r.GetMediaItemInfo_Value(itemTr,'D_LENGTH');
                
                if posIt < timeSelEnd and posIt+lenIt > timeSelStart then;
                    
                    local sel = r.IsMediaItemSelected(itemTr);
                    if sel then;
                        
                        cntIt = cntIt + 1;
                        if lenIt+posIt > X then;
                            X = lenIt+posIt;
                            ItX = itemTr;
                            TrX = tblTrack[i];
                        end;
                    end;
                end;
            end;
            
            if cntIt > 1 then;
                if ItX and TrX then;
                    local Del = r.DeleteTrackMediaItem(TrX,ItX);
                    if not UNDO and Del then;
                        r.Undo_BeginBlock();
                        r.PreventUIRefresh(1);
                        UNDO = true;
                    end;
                end;
            end;
        end;

    
    
    if UNDO then;
        r.PreventUIRefresh(-1);
        r.Undo_EndBlock("Remove final selected item in tracks",-1);
    else;
        no_undo();
    end;
 
    
end

-----------------------------------------------------------------------------------------------

-------------------------Select First Item (obeying Time Selection)------------------------------------

function select_first_item()

    -------------------------------------------------------
    local function no_undo()r.defer(function()end)end;
    -------------------------------------------------------
    
    local CountSelItem = r.CountSelectedMediaItems(0);
    if CountSelItem == 0 then no_undo() return end;
    

    local t = {};
    local tblTrack = {};
    for i = 1, CountSelItem do;
        local item = r.GetSelectedMediaItem(0,i-1);
        local track = r.GetMediaItem_Track(item);
        if not t[tostring(track)]then;
            t[tostring(track)] = track;
            tblTrack[#tblTrack+1] = track;
        end;
    end;
    
    local UNDO;
    local timeSelStart,timeSelEnd = r.GetSet_LoopTimeRange(0,0,0,0,0); 

        for i = 1, #tblTrack do;
            
            local unsel,sel;
            
            local CountTrItem = r.CountTrackMediaItems(tblTrack[i]);
            for it = 1, CountTrItem do;
                
                local itemTr = r.GetTrackMediaItem(tblTrack[i],it-1);
                local posIt = r.GetMediaItemInfo_Value(itemTr,'D_POSITION');
                local lenIt = r.GetMediaItemInfo_Value(itemTr,'D_LENGTH');
                
                if posIt < timeSelEnd and posIt+lenIt > timeSelStart then;
                    if unsel then;
                        r.SetMediaItemInfo_Value(itemTr,'B_UISEL',0);
                        if not UNDO then;
                            r.Undo_BeginBlock();
                            r.PreventUIRefresh(1);
                            UNDO = true;
                        end;
                    else;
                        sel = r.IsMediaItemSelected(itemTr);
                    end;
                    
                    if sel then;
                        unsel = true;
                    end;
                end;
                
                if posIt >= timeSelEnd then break end; 
            end;
        end;

    
    
    if UNDO then;
        r.PreventUIRefresh(-1);
        r.Undo_EndBlock("Unselect all items except first selected in track",-1);
    else;
        no_undo();
    end;

end

---------------------------------------------------------------------------------------------------


function getsomerms()

r.Undo_BeginBlock(); r.PreventUIRefresh(1)
 
local itemproc = r.GetSelectedMediaItem(0,0)

 if itemproc  then

       local tk = r.GetActiveTake(itemproc)

 function get_average_rms(take, adj_for_take_vol, adj_for_item_vol, adj_for_take_pan, val_is_dB)
   local RMS_t = {}
   if take == nil then
     return
   end
   
   local item = r.GetMediaItemTake_Item(take) -- Get parent item
   
   if item == nil then
     return
   end
   
   local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
   local item_len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
   local item_end = item_pos+item_len
   local item_loop_source = r.GetMediaItemInfo_Value(item, "B_LOOPSRC") == 1.0 -- is "Loop source" ticked?
   
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
   
   -- Get the length of the source media. If the media source is beat-based,
   -- the length will be in quarter notes, otherwise it will be in seconds.
   local take_source_len, length_is_QN = r.GetMediaSourceLength(take_pcm_source)
   if length_is_QN then
     return
   end
 
   local take_start_offset = r.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
   
   
   -- (I'm not sure how this should be handled)
   
   -- Item source is looped --
   -- Get the start time of the audio that can be returned from this accessor
   local aa_start = r.GetAudioAccessorStartTime(aa)
   -- Get the end time of the audio that can be returned from this accessor
   local aa_end = r.GetAudioAccessorEndTime(aa)
    
 
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
   
   -- Get the number of channels in the source media.
   local take_source_num_channels = r.GetMediaSourceNumChannels(take_pcm_source)
 
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
   
   --local take_playrate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
   
   -- total_samples = ceil((aa_end - aa_start) * take_source_sample_rate)
   local total_samples = floor((aa_end - aa_start) * take_source_sample_rate + 0.5)
   --total_samples = (aa_end - aa_start) * take_source_sample_rate
   
   -- take source is not within item -> return
   if total_samples < 1 then
     return
   end
   
   local block = 0
   local sample_count = 0
   local audio_end_reached = false
   local offs = aa_start
   
   local log10 = function(x) return logx(x, 10) end
   local abs = abs
   --local floor = floor
   
   
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
   
  
   local adjust_pan = 1
   
   -- Calculate RMS for each channel
   for i=1, take_source_num_channels do
     -- Adjust for take pan
     if adj_for_take_pan then
       local take_pan = r.GetMediaItemTakeInfo_Value(take, "D_PAN")
       if take_pan > 0 and i % 2 == 1 then
         adjust_pan = adjust_pan * (1 - take_pan)
       elseif take_pan < 0 and i % 2 == 0 then
         adjust_pan = adjust_pan * (1 + take_pan)
       end
     end
     
     local curr_ch = channel_data[i]
     curr_ch.rms = sqrt(curr_ch.sum_squares/total_samples) * adjust_vol * adjust_pan
     adjust_pan = 1
     RMS_t[i] = curr_ch.rms
     if val_is_dB then -- if function param "val_is_dB" is true -> convert values to dB
       RMS_t[i] = 20*log10(RMS_t[i])
     end
   end
 
   return RMS_t
 end
 

 getrms = get_average_rms( tk, 0, 0, 0, 0)

 ----------------------------------------------------------------------------------
 

 for i=1, #getrms do
 rms = (getrms[i])
 end


if rms == "-1.#INF" then return end

if srate == nil then rms = -17 end

rmsresult = string.sub(rms,1,string.find(rms,'.')+5)


foroutgain = rmsresult  

if foroutgain == "-1.#IN" then 

foroutgain = -30
rmsresult  = -30
gfx.quit()
 end

rmsoffset = (rmsresult+3)

  
boost =rmsoffset-8
  
readrmspro =(boost*-0.0177)
 
readrms =(1-readrmspro)+0.1

out_gain_boost = (foroutgain+12)

out_gain = (out_gain_boost*0.03)*-1

if (out_gain >= 1) then out_gain = 1 end

else

readrms = 0.65

out_gain = 0.15



end

orig_gain = (out_gain*1300)

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


MinimumItem = 0.3


exept = 1

function GetTempo()
retrigms = 0.0555

tempo = r.Master_GetTempo()

Quarter = (60000/tempo)

Sixty_Fourth = (Quarter/16)

retoffset =(Sixty_Fourth - 20)

retrigms = (retoffset*0.00493) 

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
     self.fnt_sz = max(9,self.def_xywh[5]* (Z_w+Z_h)/2)
     self.fnt_sz = min(22,self.fnt_sz)
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
local XButton,ZButton, Button, Slider, Rng_Slider, Knob, CheckBox, Frame, ErrMsg, Txt = {},{},{},{},{},{},{},{},{},{}
  extended(Button,     Element)
  extended(Knob,       Element)
  extended(Slider,     Element)
  extended(ZButton,     Element)
  extended(XButton,     Element)
  extended(ErrMsg,     Element)
  extended(Txt,     Element)
    -- Create Slider Child Classes --
    local H_Slider, V_Slider, T_Slider, HP_Slider, LP_Slider, G_Slider, S_Slider, Rtg_Slider, Rdc_Slider, O_Slider, Q_Slider, X_Slider = {},{},{},{},{},{},{},{},{},{},{},{}
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
    ---------------------------------
  extended(Rng_Slider, Element)
  extended(Frame,      Element)
  extended(CheckBox,   Element)

--------------------------------------------------------------------------------  
--------------------------------------------------------------------------------
---   Button Class Methods   ---------------------------------------------------
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
--    gfx.setfont(1, fnt, fnt_sz) -- set label fnt

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
--    gfx.setfont(1, fnt, fnt_sz) -- set label fnt

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
    if MCtrl then VAL = 0.3312 end --set default value by Ctrl+LMB
    self.norm_val=VAL
end
function LP_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    if MCtrl then VAL = 1 end --set default value by Ctrl+LMB
    self.norm_val=VAL
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
    if MCtrl then VAL = 0.31 end --set default value by Ctrl+LMB
    self.norm_val=VAL
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
    if MCtrl then VAL = 0.5 end --set default value by Ctrl+LMB
    self.norm_val=VAL
end
function Q_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    if MCtrl then VAL = QuantizeStrength*0.01 end --set default value by Ctrl+LMB
    self.norm_val=VAL
end
function X_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    if MCtrl then VAL = CrossfadeTime*0.02 end --set default value by Ctrl+LMB
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
--------------------------------------------------------------
function H_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
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
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw T_Slider label
end
function HP_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw HP_Slider label
end
function LP_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw LP_Slider label
end
function G_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw G_Slider label
end
function S_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw S_Slider label
end
function Rtg_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw Rtg_Slider label
end
function Rdc_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw Rdc_Slider label
end
function O_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw O_Slider label
end
function Q_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw Q_Slider label
end
function X_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
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
    --self:draw_lbl()             -- draw lbl
    
   --gfx.set(1,0,0,a)  
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
    --self:draw_lbl()             -- draw lbl
    
   --gfx.set(1,0,0,a)  
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
    gfx.x = x+5; gfx.y = y+(h-val_h)/2
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
--local n_chans = 1     -- кол-во каналов(трековых), don't change it!
local block_size = 1024*16 -- размер блока(для фильтра и тп) , don't change it!
local time_limit = 3*60    -- limit maximum time, change, if need.
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


local Midi_Sampler = CheckBox:new(610,410,68,18, 0.3,0.4,0.7,0.7, "","Arial",16,  MIDI_Mode,
                              {"Sampler","Trigger"} )


----------------------------------------------------------------------------------------------------
---  Create controls objects(btns,sliders etc) and override some methods   -------------------------
----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--- Filter Sliders ------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Filter HP_Freq --------------------------------
local HP_Freq = HP_Slider:new(20,410,160,18, 0.3,0.4,0.7,0.7, "Low Cut","Arial",16, 0.3312 )
-- Filter LP_Freq --------------------------------
local LP_Freq = LP_Slider:new(20,430,160,18, 0.3,0.4,0.7,0.7, "High Cut","Arial",16, 1 )

--------------------------------------------------
-- Filter Freq Sliders draw_val function ---------
--------------------------------------------------
function HP_Freq:draw_val()
  local sx = 16+(self.norm_val*100)*1.20103
  self.form_val = floor(exp(sx*logx(1.059))*8.17742) -- form val
  -------------
  local x,y,w,h  = self.x,self.y,self.w,self.h
  --local val = string.format("%.1f", self.form_val)
  local val = string.format("%d", self.form_val) .." Hz"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
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
  gfx.x = x+w-val_w-5
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
  gfx.x = x+w-val_w-5
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
local Gate_Sensitivity = S_Slider:new(210,400,160,18, 0.3,0.4,0.7,0.7, "Sensitivity","Arial",16, 0.31 )
function Gate_Sensitivity:draw_val()
  self.form_val = 2+(self.norm_val)*8       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." dB"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
end
-- Retrig ----------------------------------------
local Gate_Retrig = Rtg_Slider:new(210,420,160,18, 0.3,0.4,0.7,0.7, "Retrig","Arial",16, retrigms )
function Gate_Retrig:draw_val()
  self.form_val  = 20+ self.norm_val * 180   -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
end
-- Detect Velo time ------------------------------ 
local Gate_DetVelo = H_Slider:new(0,0,0,0, 0,0,0,0, "","Arial",16, 0.50 )------velodaw (680,450,90,18, 0.3,0.4,0.7,0.7, "Look","Arial",16, 0.50 )
function Gate_DetVelo:draw_val()
  self.form_val  = 5+ self.norm_val * 20     -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value



end
-- Reduce points slider -------------------------- 
local Gate_ReducePoints = Rdc_Slider:new(210,450,160,18, 0.3,0.4,0.7,0.7, "Reduce","Arial",16, 1 )
function Gate_ReducePoints:draw_val()
  self.cur_max   = self.cur_max or 0 -- current points max
  self.form_val  = ceil(self.norm_val * self.cur_max) -- form_val
  if self.form_val==0 and  self.cur_max>0 then self.form_val=1 end -- надо переделать,это принудительно 
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%d", self.form_val)
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
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
local Offset_Sld = O_Slider:new(400,430,205,18, 0.3,0.4,0.7,0.7, "Offset","Arial",16, 0.5 )------velodaw
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
  gfx.x = x+w-val_w-5
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
local QStrength_Sld = Q_Slider:new(400,450,101,18, 0.3,0.4,0.7,0.7, "Q Strength","Arial",16, QuantizeStrength*0.01 ) --205 (400,450,136,18
function QStrength_Sld:draw_val()
  self.form_val = (self.norm_val)*100       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val)..""
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
  q_strength =  floor(QStrength_Sld.form_val)
end
QStrength_Sld.onUp =
function() 

end

-- XFade slider ------------------------------ 
local XFade_Sld = X_Slider:new(503,450,102,18, 0.3,0.4,0.7,0.7, "XFades","Arial",16, CrossfadeTime*0.02 ) --205
function XFade_Sld:draw_val()
  self.form_val = (self.norm_val)*50       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
  x_fade =  floor(XFade_Sld.form_val)
end
XFade_Sld.onUp =
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
  gfx.x = x+5
  gfx.y = y+(h-val_h)/2 + T
  gfx.drawstr(val)  -- draw value 1
  gfx.x = x+w-val2_w-5
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

Slice_Status = 0
SliceQ_Status = 0
Markers_Status = 0

    r.Undo_BeginBlock() 
r.PreventUIRefresh(1)
local cursorpos = r.GetCursorPosition()

            r.Main_OnCommand(40290, 0) -- Set time selection to item
            r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVETIME1'), 0) 
            r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVEALLSELITEMS1'), 0)
            r.Main_OnCommand(40635, 0)     -- Remove Selection

r.SetEditCurPos(cursorpos,0,0) 
r.PreventUIRefresh(-1)
    r.Undo_EndBlock("Init", -1) 

--------------------------A Bit More Foolproof----------------------------

savepos()

sel_tracks_items() 

function collect_itemtake_param()    -- collect parameter on sel item and active take for SM tables and displacement calcs...
   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   src = r.GetMediaItemTake_Source(active_take)
   srate =  r.GetMediaSourceSampleRate(src) -- take samplerate (simple wave/MIDI detection)
 end
 
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item
   collect_itemtake_param()              -- get bunch of parameters about this item

if selected_tracks_count == 1 and number_of_takes > 1 and srate ~= 0 then 

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

if  srate == 0 then  

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

getsomerms()

getitem()

::zzz::

end


-- Create Just Slice  Button ----------------------------
local Just_Slice = Button:new(400,380,67,25, 0.3,0.3,0.3,1, "Slice",    "Arial",16 )
Just_Slice.onClick = 
function()
   if Wave.State then Wave:Just_Slice() end 
end 

-- Create Quantize Slices Button ----------------------------
local Quantize_Slices = Button:new(468,380,32,25, 0.3,0.3,0.3,1, "Q",    "Arial",16 )
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
local Quantize_Markers = Button:new(573,380,32,25, 0.3,0.3,0.3,1, "Q",    "Arial",16 )
Quantize_Markers.onClick = 
function()
   if Wave.State then Wave:Quantize_Markers() end 
end 

-- Reset All Button ----------------------------
local Reset_All = Button:new(970,445,55,25, 0.3,0.3,0.3,1, "Reset",    "Arial",16 )
Reset_All.onClick = 
function()

if Markers_Status ~= 0 or Slice_Status ~= 0 then

--------------------------A Bit More Foolproof----------------------------
 r.Undo_BeginBlock() 
r.PreventUIRefresh(1)
   
local cursorpos = r.GetCursorPosition()

sel_tracks_items() 
               r.Main_OnCommand(40548, 0)  -- Heal Splits

 count_itms =  r.CountSelectedMediaItems(0)

function collect_itemtake_param()    -- collect parameter on sel item and active take for SM tables and displacement calcs...
   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   src = r.GetMediaItemTake_Source(active_take)
   srate =  r.GetMediaSourceSampleRate(src) -- take samplerate (simple wave/MIDI detection)
 end
 
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item (well first one, anyway)
   collect_itemtake_param()              -- get bunch of parameters about this item (inc take playrate, I lifted this from another PL9 script)


if selected_tracks_count > 1 and count_itms == selected_tracks_count then

  r.Main_OnCommand(41844, 0) -- Remove Markers


else --------------------RESET MULTITRACK---------------------------
               r.Main_OnCommand(40029, 0)  -- Undo Heal Splits

end 



if  srate == 0 then

-----------------------------------Error Message2------------------------------------------------

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

---------------------------------End of Error Message2----------------------------------------------

 return 
end -- не запускать, если MIDI айтемы.

r.SetEditCurPos(cursorpos,0,0) 

r.PreventUIRefresh(-1)
   r.Undo_EndBlock("Reset_All", -1)    

   if Wave.State then Wave:Reset_All() end 
end 

-------------------------
end

-- Create Midi Button ----------------------------
local Create_MIDI = Button:new(610,380,68,25, 0.3,0.3,0.3,1, "MIDI",    "Arial",16 )
Create_MIDI.onClick = 


function()

M_Check = 0

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


M_Check = 1

return

end -- не запускать, если мультитрек.

if M_Check == 0 then

    r.Undo_BeginBlock() 

 r.Main_OnCommand(41844, 0)  ---Delete All Markers  


sel_tracks_items() 


function pitch_and_rate_check()

   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item (well first one, anyway)
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   take_pitch = r.GetMediaItemTakeInfo_Value(active_take, "D_PITCH")  -- take pitch
   take_playrate = r.GetMediaItemTakeInfo_Value(active_take, "D_PLAYRATE") -- take playrate 
   src = r.GetMediaItemTake_Source(active_take)
   srate =  r.GetMediaSourceSampleRate(src) -- take samplerate (simple wave/MIDI detection)

if selected_tracks_count > 1 then  return end -- не запускать, если айтемы находятся на разных треках.

if  srate == 0 then return end -- не запускать, если MIDI айтем.

 if take_pitch ~= 0 or take_playrate ~= 1.0 or number_of_takes ~= 1 and srate > 0 then
 
  r.Main_OnCommand(41588, 0) -- glue (если изменены rate, pitch, больше одного айтема и не миди айтем, то клей. Требуется для корректной работы кнопки MIDI).

end
end

pitch_and_rate_check()

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

----------------------------------------
--- Button_TB --------------------------
----------------------------------------
local Button_TB = {Get_Sel_Button, Just_Slice, Quantize_Slices, Add_Markers, Quantize_Markers, Reset_All, Create_MIDI, Midi_Sampler}
 


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
local DrawMode = CheckBox:new(0,0,0,0, 0.3,0.4,0.7,0.7, "","Arial",16,  1,  --(970,380,55,18, 0.3,0.4,0.7,0.7, "Draw: ","Arial",16,  1,
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
  local start_time = r.time_precise()--time test
  -----------------------------------------------------
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
  --r.ShowConsoleMsg("Gate time = " .. r.time_precise()-start_time .. '\n')--time test
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
            if not self.cap_ln and abs(line_x-gfx.mouse_x)<10 then 
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
        if Wave:mouseR_Down() then gfx.x, gfx.y  = mouse_ox, mouse_oy
            if gfx.showmenu("Delete")==1 then
               table.remove(self.Res_Points,self.cap_ln) -- Del self.cap_ln - Элементы смещаются влево!
               table.remove(self.Res_Points,self.cap_ln) -- Поэтому, опять тот же индекс(а не self.cap_ln+1)
            end
        end       
    end
    
    -- Insert Line(on mouseR_Down) -------------------------
    if not self.cap_ln and Wave:mouseR_Down() then gfx.x, gfx.y  = mouse_ox, mouse_oy
        if gfx.showmenu("Insert")==1 then
            local line_pos = self.start_smpl + (mouse_ox-Wave.x)/self.Xsc  -- Time point(in Samples!) from mouse_ox pos
            --------------------
            local newVelo = (self.Yop - mouse_oy)/(Wave.h*self.scale) -- velo from mouse y pos
            newVelo = min(max(newVelo,0),1)
            --------------------             
            table.insert(self.Res_Points, line_pos)           -- В конец таблицы
            table.insert(self.Res_Points, {newVelo, newVelo}) -- В конец таблицы
            --------------------
            self.cap_ln = #self.Res_Points
        end
    end 
end


------------------------------------------------------------------------------------------------------------------------
---   WAVE   -----------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------


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

sel_tracks_items() -- select for a multitrack check

   selected_tracks_count = r.CountSelectedTracks(0)

 count_itms =  r.CountSelectedMediaItems(0)

 r.Undo_BeginBlock() 
r.PreventUIRefresh(1)
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
            r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTTIME1'), 0)  -- Restore Selection
               r.Main_OnCommand(40061, 0)     -- Item: Split items at time selection
               r.Main_OnCommand(40718, 0)  -- Select all items on selected tracks in current time selection
               r.Main_OnCommand(40635, 0)     -- Remove Selection


               r.Main_OnCommand(40032, 0) -- Group Items

elseif count_itms > selected_tracks_count and selected_tracks_count >1 then  -- multitrack

            r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTTIME1'), 0)  -- Restore Selection
               r.Main_OnCommand(40061, 0)     -- Item: Split items at time selection
               r.Main_OnCommand(40718, 0)  -- Select all items on selected tracks in current time selection
               r.Main_OnCommand(40635, 0)     -- Remove Selection


               r.Main_OnCommand(40032, 0) -- Group Items

end

sel_tracks_items() -- select for a multitrack check

   selected_tracks_count = r.CountSelectedTracks(0)

 count_itms =  r.CountSelectedMediaItems(0)

         r.Main_OnCommand(40548, 0)  -- Heal Splits

if count_itms > selected_tracks_count and selected_tracks_count >1 then  -- sliced multitrack

 if Slice_Status == 0 then---------------------------------glue------------------------------

         r.Main_OnCommand(40548, 0)  -- Heal Splits

   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end

local i=0;

while(true) do;
  i=i+1;
  local item = reaper.GetSelectedMediaItem(0,i-1);
  if item then;

   active_take = r.GetActiveTake(item)  -- active take in item
   take_start_offset = r.GetMediaItemTakeInfo_Value(active_take, "D_STARTOFFS") -- take offset

          r.Main_OnCommand(41588, 0) -- glue (если кусок айтема и не со стартовой точки, то клей).

  else;
    break;
  end;
end;

end

end

savepos()

Wave:Reset_All()

sel_tracks_items() -- select for a multitrack check

   selected_tracks_count = r.CountSelectedTracks(0)

 count_itms =  r.CountSelectedMediaItems(0)

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

  if  cutpos - self.sel_start >= 0.04 and self.sel_end - cutpos >= 0.07 then -- if transient too close near item start, do nothing
            r.SetEditCurPos(cutpos,0,0)          
            r.Main_OnCommand(40757, 0)  ---split
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

Slice_Status = 1 

SliceQ_Status = 1

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


function Wave:Quantize_Slices()

if SliceQ_Status ~= 0 then
              
 r.Undo_BeginBlock() 
 r.PreventUIRefresh(1)
   -------------------------------------------

 count_itms =  r.CountSelectedMediaItems(0)

       _, save_project_grid, save_swing, save_swing_amt = r.GetSetProjectGrid(proj, false) -- backup current grid settings

    if save_project_grid > 0.5 then
               r.Main_OnCommand(40780, 0)  -- Set minimal Grid size (1/2)
    end

function quantize()

local i=0;

while(true) do
  i=i+1
  local item = r.GetSelectedMediaItem(0,i-1)
  if item then
        pos = r.GetMediaItemInfo_Value(item, "D_POSITION") + r.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")

if r.GetToggleCommandState(reaper.NamedCommandLookup('_BR_OPTIONS_SNAP_FOLLOW_GRID_VIS'), 0) == 1 then
      grid_opt = 1
  else
      grid_opt = 0
      r.Main_OnCommand(reaper.NamedCommandLookup('_BR_OPTIONS_SNAP_FOLLOW_GRID_VIS'), 0)
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

        r.SetMediaItemInfo_Value(item, "D_POSITION", pos - q_strength / 100 * (pos - ( r.SnapToGrid(0, pos))) - r.GetMediaItemInfo_Value(item, "D_SNAPOFFSET"))
  else
    break
  end

 if  grid_opt == 0 then r.Main_OnCommand(reaper.NamedCommandLookup('_BR_OPTIONS_SNAP_FOLLOW_GRID_VIS'), 0) end
 if  snap == 0 then r.Main_OnCommand(1157, 0) end
 if  grid == 0 then r.Main_OnCommand(40145, 0) end

end
r.UpdateArrange();
end

quantize()

cleanup_slices()


r.Main_OnCommand(r.NamedCommandLookup("_SWS_AWFILLGAPSQUICK"),0) -- fill gaps 

        CrossfadeT = x_fade

    local function Overlap(CrossfadeT);
        local t,ret = {};
        local items_count = reaper.CountSelectedMediaItems(0);
        if items_count == 0 then return 0 end;
        for i = 1 ,items_count do;
            local item = reaper.GetSelectedMediaItem(0,i-1);
            local trackIt = reaper.GetMediaItem_Track(item);
            if t[tostring(trackIt)] then;
                ----
                ret = 1;
                local crossfade_time = (CrossfadeT or 0)/1000;
                local take = reaper.GetActiveTake(item); 
                local pos = reaper.GetMediaItemInfo_Value(item,'D_POSITION');
                local length = reaper.GetMediaItemInfo_Value( item,'D_LENGTH');
                local rateIt = reaper.GetMediaItemTakeInfo_Value(take,'D_PLAYRATE');
                local ofSetIt = reaper.GetMediaItemTakeInfo_Value(take,'D_STARTOFFS');
                if pos < crossfade_time then crossfade_time = pos end;
                ----
                reaper.SetMediaItemInfo_Value(item,'D_POSITION',pos-crossfade_time);
                reaper.SetMediaItemInfo_Value(item,'D_LENGTH',length+crossfade_time);
                reaper.SetMediaItemTakeInfo_Value(take,'D_STARTOFFS',ofSetIt-(crossfade_time*rateIt));
            else;
                t[tostring(trackIt)] = trackIt;
            end;
        end;
        if ret == 1 then reaper.Main_OnCommand(41059,0) end;
        return ret or 0;
    end;
    
    
    reaper.Undo_BeginBlock();
    local Over = Overlap(CrossfadeT);
    reaper.Undo_EndBlock("Overlap",Over-Over*2);
    reaper.UpdateArrange();

       r.GetSetProjectGrid(proj, true, save_project_grid, save_swing, save_swing_amt) -- restore saved grid settings

 r.PreventUIRefresh(-1)

    -------------------------------------------
    r.Undo_EndBlock("Quantize Slices", -1)    

end

SliceQ_Status = 0

end


function Wave:Add_Markers()

SliceQ_Status = 1

sel_tracks_items() -- select for a multitrack check

   selected_tracks_count = r.CountSelectedTracks(0)

 count_itms =  r.CountSelectedMediaItems(0)

 r.Undo_BeginBlock() 
r.PreventUIRefresh(1)

if count_itms == selected_tracks_count and selected_tracks_count >1 then  -- multitrack
            r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTTIME1'), 0)  -- Restore Selection
               r.Main_OnCommand(40061, 0)     -- Item: Split items at time selection
               r.Main_OnCommand(40718, 0)  -- Select all items on selected tracks in current time selection
               r.Main_OnCommand(40635, 0)     -- Remove Selection


               r.Main_OnCommand(40032, 0) -- Group Items

elseif count_itms > selected_tracks_count and selected_tracks_count >1 then  -- multitrack

            r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTTIME1'), 0)  -- Restore Selection
               r.Main_OnCommand(40061, 0)     -- Item: Split items at time selection
               r.Main_OnCommand(40718, 0)  -- Select all items on selected tracks in current time selection
               r.Main_OnCommand(40635, 0)     -- Remove Selection


               r.Main_OnCommand(40032, 0) -- Group Items

end

local cursorpos = r.GetCursorPosition()

if selected_tracks_count > 1 and count_itms == selected_tracks_count then --------------------RESET MULTITRACK (Markers)---------------------------

  r.Main_OnCommand(41844, 0) -- Remove Markers

else

if selected_tracks_count > 1 and count_itms > selected_tracks_count then --------------------RESET SLICED MULTITRACK (Markers)---------------------------

  r.Main_OnCommand(41844, 0) -- Remove Markers
               r.Main_OnCommand(40548, 0)  -- Heal Splits

end

end 


sel_tracks_items() 

               r.Main_OnCommand(40548, 0)  -- Heal Splits

 count_itms =  r.CountSelectedMediaItems(0)

function collect_itemtake_param()    -- collect parameter on sel item and active take for SM tables and displacement calcs...
   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   src = r.GetMediaItemTake_Source(active_take)
   srate =  r.GetMediaSourceSampleRate(src) -- take samplerate (simple wave/MIDI detection)
 end
 
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item (well first one, anyway)
   collect_itemtake_param()              -- get bunch of parameters about this item (inc take playrate, I lifted this from another PL9 script)


if selected_tracks_count > 1 and count_itms == selected_tracks_count then

  r.Main_OnCommand(41844, 0) -- Remove Markers


else --------------------RESET MULTITRACK---------------------------

               r.Main_OnCommand(40029, 0)  -- Undo Heal Splits
end


Markers_Status = 1

r.SetEditCurPos(cursorpos,0,0) 

r.PreventUIRefresh(-1)
   r.Undo_EndBlock("Reset (add markers)", -1)    

Wave:Reset_All() -- single track reset

if count_itms > 1 and selected_tracks_count >1 then  -- multitrack
               r.Main_OnCommand(40032, 0) -- Group Items
end

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

            r.Main_OnCommand(40290, 0) -- Set time selection to item
            r.Main_OnCommand(41843, 0)  ---Add Marker
            r.Main_OnCommand(40635, 0)     -- Remove Selection

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
 
 
 
    -------------------------------------------
    r.Undo_EndBlock("Add Markers", -1)    

end
end



function Wave:Quantize_Markers()

     
 r.Undo_BeginBlock() 
r.PreventUIRefresh(1)
   -------------------------------------------

       _, save_project_grid, save_swing, save_swing_amt = r.GetSetProjectGrid(proj, false) -- backup current grid settings

    if save_project_grid > 0.5 then
               r.Main_OnCommand(40780, 0)  -- Set minimal Grid size (1/2)
    end

--------------------Snap Markers to Grid----------------------

local i=0;

    r.Undo_BeginBlock();
while(true) do;
  i=i+1;
  local item = reaper.GetSelectedMediaItem(0,i-1);
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
            local posGrid = r.SnapToGrid(0,pos);
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

    -------------------------------------------
    r.Undo_EndBlock("Quantize Markers", -1)    
 
end

--------------------------------------------------------------------------------------


function Wave:Reset_All()

SliceQ_Status = 1

local cursorpos = r.GetCursorPosition()
   
 r.Undo_BeginBlock() 
r.PreventUIRefresh(1)
   -------------------------------------------
               r.Main_OnCommand(40033, 0) -- UnGroup
  r.Main_OnCommand(41844, 0) -- Remove Markers
               r.Main_OnCommand(40548, 0)  -- Heal Splits

 count_itms =  r.CountSelectedMediaItems(0)

   r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVESEL'), 0)  -- Save track selection

sel_tracks_items() -- select for a multitrack check

   selected_tracks_count = r.CountSelectedTracks(0)

 restorepos()


if count_itms > 1 and selected_tracks_count == 1 then -- single item/sliced item


elseif count_itms > 1 and selected_tracks_count == count_itms then  -- multitrack


  r.Main_OnCommand(41844, 0) -- Remove Markers

elseif count_itms > selected_tracks_count and selected_tracks_count >1 then  -- sliced multitrack

                 r.Main_OnCommand(40548, 0)  -- Heal Splits

end

r.SetEditCurPos(cursorpos,0,0) 

 r.PreventUIRefresh(-1)

    -------------------------------------------
    r.Undo_EndBlock("Reset_All", -1)    

end


function Wave:Load_To_Sampler(sel_start, sel_end, track)

              r.Undo_BeginBlock()
             r.PreventUIRefresh(1) 

ItemState = r.GetExtState('_Slicer_', 'GetItemState')

if  (ItemState=="ItemLoaded") then 

r.SelectAllMediaItems(0, 0 )

r.Main_OnCommand(40297,0) ----unselect all tracks

lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')   
item =  r.BR_GetMediaItemByGUID( 0, lastitem )
track = r.GetMediaItem_Track(item)
               
r.GetSet_LoopTimeRange2( 0, 1, 0, self.sel_start, self.sel_end, 0 )

r.SetTrackSelected( track, 1 )

r.Main_OnCommand(40718,0)----Select all items on selected tracks in currient time selection
r.Main_OnCommand(40635,0) ---Remove Time selection

elseif not (ItemState=="ItemLoaded") then 

self.sel_start = sel_start
self.sel_end = sel_end 


end

data ={}

data.parent_track =  track

obeynoteoff_default = 1

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
 
    
    if not data.parent_track or not note or not filepath then return end

    local track =  r.GetSelectedTrack( 0, 0 )
    if data[note] and data[note][1] then 
      track = data[note][1].src_track
      if conf.allow_multiple_spls_per_pad == 0 then
        r.TrackFX_SetNamedConfigParm(  track, data[note][1].rs5k_pos, 'FILE0', filepath)
        r.TrackFX_SetNamedConfigParm(  track, data[note][1].rs5k_pos, 'DONE', '')
        return 1  
       else
        ExportItemToRS5K_defaults(data,conf,refresh,note,filepath, start_offs, end_offs, track)  
        return #data[note]+1        
      end
     else
       ExportItemToRS5K_defaults(data,conf,refresh,note,filepath, start_offs, end_offs, track)
       return 1
    end
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
          --if ret then r.ShowConsoleMsg('done') end
      end
      r.MIDI_Sort( new_tk )
      r.GetSetMediaItemTakeInfo_String( new_tk, 'P_NAME', 'sliced loop', 1 )
      
      newmidiitem = r.GetMediaItemTake_Item(new_tk)
 
      r.SetMediaItemSelected( newmidiitem, 1 )
      
      r.UpdateArrange()    
  end



function Load() 

              -- track check
                local track = track
                if not track then return end        
              -- item check
                local item = r.GetSelectedMediaItem(0,0)
                if not item then return true end  
              -- get base pitch
               
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
                  ::skip_to_next_item::
                end
                   
                   r.Main_OnCommand(40548,0)--Item: Heal Splits   
                   r.Main_OnCommand(40719,0)--Item: Mute items     
              -- add MIDI
                if proceed_MIDI then ExportSelItemsToRs5k_AddMIDI(track, MIDI,base_pitch) end        
                     
    r.PreventUIRefresh(-1)
 
       -------------------------------------------
       r.Undo_EndBlock("Export To Sampler", -1)        
              
            end

function doublecheck()

   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item (well first one, anyway)
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   src = r.GetMediaItemTake_Source(active_take)
   srate =  r.GetMediaSourceSampleRate(src) -- take samplerate (simple wave/MIDI detection)

if  srate ~= 0 then Load() end --

end

doublecheck()

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
   
if (getitem ==0) then
    if self.AA then r.DestroyAudioAccessor(self.AA) 
       self.buffer.clear()
    end
 end
end

--------
function Wave:Get_TimeSelection()

 local item = r.GetSelectedMediaItem(0,0)
    if item then
    
 local sel_start = r.GetMediaItemInfo_Value(item, "D_POSITION")
         local sel_end = sel_start + r.GetMediaItemInfo_Value(item, "D_LENGTH")
  
   
    local sel_len = sel_end - sel_start
    if sel_len<0.25 then return end -- 0.25 minimum
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
    self.crsx   = block_size/8   -- one side "crossX"  -- use for discard some FFT artefacts(its non-nat, but in this case normally)
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
  local start_time = r.time_precise()--time test
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
  end
end 
--------------------------
function Wave:Set_Cursor()
  if self:mouseDown() and not(Ctrl or Shift) then  
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
    self.insrc_mx = self.Pos + (gfx.mouse_x-self.x)/(self.Zoom*Z_w) -- its current mouse position in source!
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
      self.Pos = self.insrc_mx - (gfx.mouse_x-self.x)/(self.Zoom*Z_w)
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
     if  KeyR == 1 then self.Zoom = min(self.Zoom*1.2, self.max_vertZoom)   

      self.Pos = self.insrc_mx - (gfx.mouse_x-self.x)/(self.Zoom*Z_w)
      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )

     Wave:Redraw() -- redraw after vertical zoom
     else
     end   

     if  KeyL == 1 then self.Zoom = max(self.Zoom*0.8, 1)

      self.Pos = self.insrc_mx - (gfx.mouse_x-self.x)/(self.Zoom*Z_w)
      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )

     Wave:Redraw() -- redraw after vertical zoom
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
 local fnt_sz = 16
 fnt_sz = max(9,  fnt_sz* (Z_w+Z_h)/2)
 fnt_sz = min(20, fnt_sz)
 gfx.setfont(1, "Arial", fnt_sz)
 gfx.set(0.7, 0.7, 0.7, 1) -- цвет текста инфо
 gfx.x, gfx.y = self.x+10, self.y+10
 gfx.drawstr(
  [[
  Select an item (max 180s).
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
  for key,sldr   in pairs(Slider_TB)   do sldr:draw()   end
  end
   
    for key,ch_box in pairs(CheckBox_TB) do ch_box:draw() end
    for key,frame  in pairs(Frame_TB)    do frame:draw()  end       
end

--------------------------------------------------------------------------------
--   INIT   --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Init()
    -- Some gfx Wnd Default Values ---------------
    local R,G,B = 45,45,45              -- 0...255 format -- цвет основного окна
    local Wnd_bgd = R + G*256 + B*65536 -- red+green*256+blue*65536  
    local Wnd_Title = "MK Slicer v1.3"
    local Wnd_Dock, Wnd_X,Wnd_Y = Docked,400,320 
    Wnd_W,Wnd_H = 1044,490 -- global values(used for define zoom level)
    -- Init window ------
    gfx.clear = Wnd_bgd         
    gfx.init( Wnd_Title, Wnd_W,Wnd_H,Wnd_Dock, Wnd_X,Wnd_Y )
    -- Init mouse last --
    last_mouse_cap = 0
    last_x, last_y = 0, 0
    mouse_ox, mouse_oy = -1, -1
end
----------------------------------------
--   Mainloop   ------------------------
----------------------------------------
function mainloop()

    -- zoom level -- 
    Z_w, Z_h = gfx.w/Wnd_W, gfx.h/Wnd_H
    if Z_w<0.65 then Z_w = 0.65 elseif Z_w>1.8 then Z_w = 1.8 end 
    if Z_h<0.65 then Z_h = 0.65 elseif Z_h>1.8 then Z_h = 1.8 end 
    -- mouse and modkeys --
    if gfx.mouse_cap&1==1   and last_mouse_cap&1==0  or   -- L mouse
       gfx.mouse_cap&2==2   and last_mouse_cap&2==0  or   -- R mouse
       gfx.mouse_cap&64==64 and last_mouse_cap&64==0 then -- M mouse
       mouse_ox, mouse_oy = gfx.mouse_x, gfx.mouse_y 
    end
    Ctrl  = gfx.mouse_cap&4==4   -- Ctrl  state
    Shift = gfx.mouse_cap&8==8   -- Shift state
    MCtrl = gfx.mouse_cap&5==5   -- Ctrl+LMB state
    Alt   = gfx.mouse_cap&16==16 -- Alt state
    
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

SliceQ_Status = 1

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

end

function getitem()

local start_time = r.time_precise()
   ---------------------
   Wave:Destroy_Track_Accessor() -- Destroy previos AA(освобождает память etc)
   Wave.State = false -- reset Wave.State
   if Wave:Create_Track_Accessor() then Wave:Processing()
      if Wave.State then
         Wave:Redraw()
         Gate_Gl:Apply_toFiltered() 
      end
   end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Init()
mainloop()

getitem()


function ClearExState()

r.DeleteExtState('_Slicer_', 'ItemToSlice', 0)
r.DeleteExtState('_Slicer_', 'TrackForSlice', 0)
r.SetExtState('_Slicer_', 'GetItemState', 'ItemNotLoaded', 0)
end

r.atexit(ClearExState)
titracks. Slices and quantizes your multitrack drums phase-accurate, quickly and without pain. Items in the multitrack will be automatically grouped.
--    - Re-Quantizing. When quantizing with a grid larger than the step of the transients, you can re-quantize your loops to get unique material. 
--    - One click sampling and exporting into RS5k.
--    - Good old Trigger. Easy conversion of rhythmic parts to midi patterns with accurate velocity reproduction.
--    - Advanced interface. Intuitive controls. Resetting values to defaults by Ctrl+Click. Change operations on-the-fly without the need of Undo.
--    - Adaptive initial settings. Upon initialization, the script sets the View Gain, Threshold, and Retrig settings depending on the material and tempo of the project.

--[[
MK Slicer v1.3 by Maxim Kokarev 
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
--|
--|
--|
--|
--|
--|
-------------------------------User Area-------------------------------------------

Docked = 0              -- (1 - Script starts docked, 0 - Windowed) 
EscToExit = 1           -- (Use ESC to close script? 1 - Yes, 0 - No.)
MIDI_Base_Oct = 2         -- (Start note for Export to MIDI Sampler. 0 = C-1, 1 = C0, 2 = C1, etc)
CrossfadeTime = 15   -- (Default Crossfades Length in ms. 0 = Crossfades Off, max. 50)
QuantizeStrength = 100 -- (Default Quantize Strength in %. 0 = Quantize Off, max. 100)
MIDI_Mode = 1             --  (Default MIDI Mode. 1 = Sampler, 2 = Trigger)

-------------------------------Advanced-------------------------------------------

AutoXFadesOnSplitOverride = 1 -- (Override "Options: Toggle auto-crossfade on split" option. 0 - Don't Override, 1 - Override)
ItemFadesOverride = 1 -- (Override "Item: Toggle enable/disable default fadein/fadeout" option. 0 - Don't Override, 1 - Override)

---------------------------End of User Area----------------------------------------
--|
--|
--|
--|
--|
--|
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

Slice_Status = 0
SliceQ_Status = 0
Markers_Status = 0

    r.Undo_BeginBlock() 
r.PreventUIRefresh(1)
local cursorpos = r.GetCursorPosition()

            r.Main_OnCommand(40290, 0) -- Set time selection to item
            r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVETIME1'), 0) 
            r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVEALLSELITEMS1'), 0)
            r.Main_OnCommand(40635, 0)     -- Remove Selection

r.SetEditCurPos(cursorpos,0,0) 
r.PreventUIRefresh(-1)
    r.Undo_EndBlock("Init", -1) 
---------------------------------Prepare Item(s) and Foolproof----------------------------------------------

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
	r.SetOnlyTrackSelected(first_track)
	r.SetTrackSelected(first_track, false)
end

sel_tracks_items() 

function collect_itemtake_param()    -- collect parameter on sel item and active take for SM tables and displacement calcs...
   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   take_start_offset = r.GetMediaItemTakeInfo_Value(active_take, "D_STARTOFFS") -- take offset
   src = r.GetMediaItemTake_Source(active_take)
   srate =  r.GetMediaSourceSampleRate(src) -- take samplerate (simple wave/MIDI detection)
 end
 
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item 
   collect_itemtake_param()              -- get bunch of parameters about this item

if selected_tracks_count > 1 then gfx.quit() return end -- не запускать, если айтемы находятся на разных треках.

if  srate == 0 then gfx.quit() return end -- не запускать, если MIDI айтем.

 if number_of_takes ~= 1 and srate ~= nil then
 
r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то клей, попытка не деструктивно склеить).

end

   collect_itemtake_param()    

 if number_of_takes ~= 1 and srate ~= nil then -- проверяем ещё раз. Если не удалось, клеим деструктивно.
 
 r.Main_OnCommand(41588, 0) -- glue (если больше одного айтема и не миди айтем, то клей).
  
  end
--------------------------------------UA  protection--------------------------------------------------

if Docked == nil then Docked = 0 end 
if Docked > 1 then Docked = 1 end 
if Docked < 0 then Docked = 0 end 
if EscToExit == nil then EscToExit = 1 end 
if EscToExit > 1 then EscToExit = 1 end 
if EscToExit < 0 then EscToExit = 0 end 
if MIDI_Base_Oct == nil then MIDI_Base_Oct = 2 end 
if MIDI_Base_Oct > 7 then MIDI_Base_Oct = 7 end 
if MIDI_Base_Oct < 0 then MIDI_Base_Oct = 0 end 
if CrossfadeTime == nil then CrossfadeTime = 50 end 
if CrossfadeTime > 50 then CrossfadeTime = 50 end 
if CrossfadeTime < 0 then CrossfadeTime = 0 end 
if QuantizeStrength == nil then QuantizeStrength = 100 end 
if QuantizeStrength > 100 then QuantizeStrength = 100 end 
if QuantizeStrength < 0 then QuantizeStrength = 0 end 
if MIDI_Mode == nil then MIDI_Mode = 1 end 
if MIDI_Mode > 2 then MIDI_Mode = 2 end 
if MIDI_Mode < 1 then MIDI_Mode = 1 end 
if AutoXFadesOnSplitOverride == nil then AutoXFadesOnSplitOverride = 1 end 
if AutoXFadesOnSplitOverride > 1 then AutoXFadesOnSplitOverride = 1 end 
if AutoXFadesOnSplitOverride < 0 then AutoXFadesOnSplitOverride = 0 end 
if ItemFadesOverride == nil then ItemFadesOverride = 1 end 
if ItemFadesOverride > 1 then ItemFadesOverride = 1 end 
if ItemFadesOverride < 0 then ItemFadesOverride = 0 end 

--------------------------------Save Item Position and Fade-out length-------------------------------

PosTable = {}
PosTable2 = {}
function savepos()
firstItem = r.GetSelectedMediaItem(0, 0)
if firstItem == nil then return end
firstItemPosition = r.GetMediaItemInfo_Value(firstItem, "D_POSITION")
fadeoutlength = r.GetMediaItemInfo_Value(firstItem, "D_FADEOUTLEN")
PosTable[firstItem] = firstItemPosition
PosTable2[firstItem] = fadeoutlength
end
savepos()

function restorepos()
firstItem2 = r.GetSelectedMediaItem(0, 0)
if firstItem2 == nil then return end
if PosTable[firstItem] == nil then return end
firstItemPosition2 = r.SetMediaItemInfo_Value(firstItem2, "D_POSITION", PosTable[firstItem])
fadeoutlength2 = r.SetMediaItemInfo_Value(firstItem2, "D_FADEOUTLEN", PosTable2[firstItem])
end
-------------------------------------------------------------------------------------------------------


---------------------Item;  Remove selected overlapped items (by tracks)------------------------------

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
--------------------------------------------------------------------------------------------------

--------------------Remove Last Item (obeying Time Selection)-------------------------------------

local function remove_last();

    -------------------------------------------------------
    local function no_undo()r.defer(function()end)end;
    -------------------------------------------------------
 
    
    local CountSelItem = r.CountSelectedMediaItems(0);
    if CountSelItem == 0 then no_undo() return end;
    
    local t = {};
    local tblTrack = {};
    for i = 1, CountSelItem do; -- Get tracks from items

        local item = r.GetSelectedMediaItem(0,i-1);
        local track = r.GetMediaItem_Track(item);
        if not t[tostring(track)]then;
            t[tostring(track)] = track;
            tblTrack[#tblTrack+1] = track;
        end;
    end;
    
    local UNDO;
    local timeSelStart,timeSelEnd = r.GetSet_LoopTimeRange(0,0,0,0,0);


        for i = 1, #tblTrack do;
            local X = 0;
            local cntIt = 0;
            local CountTrItem = r.CountTrackMediaItems(tblTrack[i]);
            for it = CountTrItem-1,0,-1 do;         
                local itemTr = r.GetTrackMediaItem(tblTrack[i],it);
                local posIt = r.GetMediaItemInfo_Value(itemTr,'D_POSITION');
                local lenIt = r.GetMediaItemInfo_Value(itemTr,'D_LENGTH');
                
                if posIt < timeSelEnd and posIt+lenIt > timeSelStart then;
                    
                    local sel = r.IsMediaItemSelected(itemTr);
                    if sel then;
                        
                        cntIt = cntIt + 1;
                        if lenIt+posIt > X then;
                            X = lenIt+posIt;
                            ItX = itemTr;
                            TrX = tblTrack[i];
                        end;
                    end;
                end;
            end;
            
            if cntIt > 1 then;
                if ItX and TrX then;
                    local Del = r.DeleteTrackMediaItem(TrX,ItX);
                    if not UNDO and Del then;
                        r.Undo_BeginBlock();
                        r.PreventUIRefresh(1);
                        UNDO = true;
                    end;
                end;
            end;
        end;

    
    
    if UNDO then;
        r.PreventUIRefresh(-1);
        r.Undo_EndBlock("Remove final selected item in tracks",-1);
    else;
        no_undo();
    end;
 
    
end

-----------------------------------------------------------------------------------------------

-------------------------Select First Item (obeying Time Selection)------------------------------------

function select_first_item()

    -------------------------------------------------------
    local function no_undo()r.defer(function()end)end;
    -------------------------------------------------------
    
    local CountSelItem = r.CountSelectedMediaItems(0);
    if CountSelItem == 0 then no_undo() return end;
    

    local t = {};
    local tblTrack = {};
    for i = 1, CountSelItem do;
        local item = r.GetSelectedMediaItem(0,i-1);
        local track = r.GetMediaItem_Track(item);
        if not t[tostring(track)]then;
            t[tostring(track)] = track;
            tblTrack[#tblTrack+1] = track;
        end;
    end;
    
    local UNDO;
    local timeSelStart,timeSelEnd = r.GetSet_LoopTimeRange(0,0,0,0,0); 

        for i = 1, #tblTrack do;
            
            local unsel,sel;
            
            local CountTrItem = r.CountTrackMediaItems(tblTrack[i]);
            for it = 1, CountTrItem do;
                
                local itemTr = r.GetTrackMediaItem(tblTrack[i],it-1);
                local posIt = r.GetMediaItemInfo_Value(itemTr,'D_POSITION');
                local lenIt = r.GetMediaItemInfo_Value(itemTr,'D_LENGTH');
                
                if posIt < timeSelEnd and posIt+lenIt > timeSelStart then;
                    if unsel then;
                        r.SetMediaItemInfo_Value(itemTr,'B_UISEL',0);
                        if not UNDO then;
                            r.Undo_BeginBlock();
                            r.PreventUIRefresh(1);
                            UNDO = true;
                        end;
                    else;
                        sel = r.IsMediaItemSelected(itemTr);
                    end;
                    
                    if sel then;
                        unsel = true;
                    end;
                end;
                
                if posIt >= timeSelEnd then break end; 
            end;
        end;

    
    
    if UNDO then;
        r.PreventUIRefresh(-1);
        r.Undo_EndBlock("Unselect all items except first selected in track",-1);
    else;
        no_undo();
    end;

end

---------------------------------------------------------------------------------------------------


function getsomerms()

r.Undo_BeginBlock(); r.PreventUIRefresh(1)
 
local itemproc = r.GetSelectedMediaItem(0,0)

 if itemproc  then

       local tk = r.GetActiveTake(itemproc)

 function get_average_rms(take, adj_for_take_vol, adj_for_item_vol, adj_for_take_pan, val_is_dB)
   local RMS_t = {}
   if take == nil then
     return
   end
   
   local item = r.GetMediaItemTake_Item(take) -- Get parent item
   
   if item == nil then
     return
   end
   
   local item_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
   local item_len = r.GetMediaItemInfo_Value(item, "D_LENGTH")
   local item_end = item_pos+item_len
   local item_loop_source = r.GetMediaItemInfo_Value(item, "B_LOOPSRC") == 1.0 -- is "Loop source" ticked?
   
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
   
   -- Get the length of the source media. If the media source is beat-based,
   -- the length will be in quarter notes, otherwise it will be in seconds.
   local take_source_len, length_is_QN = r.GetMediaSourceLength(take_pcm_source)
   if length_is_QN then
     return
   end
 
   local take_start_offset = r.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
   
   
   -- (I'm not sure how this should be handled)
   
   -- Item source is looped --
   -- Get the start time of the audio that can be returned from this accessor
   local aa_start = r.GetAudioAccessorStartTime(aa)
   -- Get the end time of the audio that can be returned from this accessor
   local aa_end = r.GetAudioAccessorEndTime(aa)
    
 
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
   
   -- Get the number of channels in the source media.
   local take_source_num_channels = r.GetMediaSourceNumChannels(take_pcm_source)
 
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
   
   --local take_playrate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
   
   -- total_samples = ceil((aa_end - aa_start) * take_source_sample_rate)
   local total_samples = floor((aa_end - aa_start) * take_source_sample_rate + 0.5)
   --total_samples = (aa_end - aa_start) * take_source_sample_rate
   
   -- take source is not within item -> return
   if total_samples < 1 then
     return
   end
   
   local block = 0
   local sample_count = 0
   local audio_end_reached = false
   local offs = aa_start
   
   local log10 = function(x) return logx(x, 10) end
   local abs = abs
   --local floor = floor
   
   
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
   
  
   local adjust_pan = 1
   
   -- Calculate RMS for each channel
   for i=1, take_source_num_channels do
     -- Adjust for take pan
     if adj_for_take_pan then
       local take_pan = r.GetMediaItemTakeInfo_Value(take, "D_PAN")
       if take_pan > 0 and i % 2 == 1 then
         adjust_pan = adjust_pan * (1 - take_pan)
       elseif take_pan < 0 and i % 2 == 0 then
         adjust_pan = adjust_pan * (1 + take_pan)
       end
     end
     
     local curr_ch = channel_data[i]
     curr_ch.rms = sqrt(curr_ch.sum_squares/total_samples) * adjust_vol * adjust_pan
     adjust_pan = 1
     RMS_t[i] = curr_ch.rms
     if val_is_dB then -- if function param "val_is_dB" is true -> convert values to dB
       RMS_t[i] = 20*log10(RMS_t[i])
     end
   end
 
   return RMS_t
 end
 

 getrms = get_average_rms( tk, 0, 0, 0, 0)

 ----------------------------------------------------------------------------------
 

 for i=1, #getrms do
 rms = (getrms[i])
 end


if rms == "-1.#INF" then return end

if srate == nil then rms = -17 end

rmsresult = string.sub(rms,1,string.find(rms,'.')+5)


foroutgain = rmsresult  

if foroutgain == "-1.#IN" then 

foroutgain = -30
rmsresult  = -30
gfx.quit()
 end

rmsoffset = (rmsresult+3)

  
boost =rmsoffset-8
  
readrmspro =(boost*-0.0177)
 
readrms =(1-readrmspro)+0.1

out_gain_boost = (foroutgain+12)

out_gain = (out_gain_boost*0.03)*-1

if (out_gain >= 1) then out_gain = 1 end

else

readrms = 0.65

out_gain = 0.15



end

orig_gain = (out_gain*1300)

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


MinimumItem = 0.3


exept = 1

function GetTempo()
retrigms = 0.0555

tempo = r.Master_GetTempo()

Quarter = (60000/tempo)

Sixty_Fourth = (Quarter/16)

retoffset =(Sixty_Fourth - 20)

retrigms = (retoffset*0.00493) 

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
     self.fnt_sz = max(9,self.def_xywh[5]* (Z_w+Z_h)/2)
     self.fnt_sz = min(22,self.fnt_sz)
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
local XButton,ZButton, Button, Slider, Rng_Slider, Knob, CheckBox, Frame, ErrMsg, Txt = {},{},{},{},{},{},{},{},{},{}
  extended(Button,     Element)
  extended(Knob,       Element)
  extended(Slider,     Element)
  extended(ZButton,     Element)
  extended(XButton,     Element)
  extended(ErrMsg,     Element)
  extended(Txt,     Element)
    -- Create Slider Child Classes --
    local H_Slider, V_Slider, T_Slider, HP_Slider, LP_Slider, G_Slider, S_Slider, Rtg_Slider, Rdc_Slider, O_Slider, Q_Slider, X_Slider = {},{},{},{},{},{},{},{},{},{},{},{}
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
    ---------------------------------
  extended(Rng_Slider, Element)
  extended(Frame,      Element)
  extended(CheckBox,   Element)

--------------------------------------------------------------------------------  
--------------------------------------------------------------------------------
---   Button Class Methods   ---------------------------------------------------
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
--    gfx.setfont(1, fnt, fnt_sz) -- set label fnt

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
--    gfx.setfont(1, fnt, fnt_sz) -- set label fnt

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
    if MCtrl then VAL = 0.3312 end --set default value by Ctrl+LMB
    self.norm_val=VAL
end
function LP_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    if MCtrl then VAL = 1 end --set default value by Ctrl+LMB
    self.norm_val=VAL
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
    if MCtrl then VAL = 0.31 end --set default value by Ctrl+LMB
    self.norm_val=VAL
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
    if MCtrl then VAL = 0.5 end --set default value by Ctrl+LMB
    self.norm_val=VAL
end
function Q_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    if MCtrl then VAL = QuantizeStrength*0.01 end --set default value by Ctrl+LMB
    self.norm_val=VAL
end
function X_Slider:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    if MCtrl then VAL = CrossfadeTime*0.02 end --set default value by Ctrl+LMB
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
--------------------------------------------------------------
function H_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
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
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw T_Slider label
end
function HP_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw HP_Slider label
end
function LP_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw LP_Slider label
end
function G_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw G_Slider label
end
function S_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw S_Slider label
end
function Rtg_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw Rtg_Slider label
end
function Rdc_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw Rdc_Slider label
end
function O_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw O_Slider label
end
function Q_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw Q_Slider label
end
function X_Slider:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+5; gfx.y = y+(h-lbl_h)/2;
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
    --self:draw_lbl()             -- draw lbl
    
   --gfx.set(1,0,0,a)  
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
    --self:draw_lbl()             -- draw lbl
    
   --gfx.set(1,0,0,a)  
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
    gfx.x = x+5; gfx.y = y+(h-val_h)/2
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
--local n_chans = 1     -- кол-во каналов(трековых), don't change it!
local block_size = 1024*16 -- размер блока(для фильтра и тп) , don't change it!
local time_limit = 3*60    -- limit maximum time, change, if need.
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


local Midi_Sampler = CheckBox:new(610,410,68,18, 0.3,0.4,0.7,0.7, "","Arial",16,  MIDI_Mode,
                              {"Sampler","Trigger"} )


----------------------------------------------------------------------------------------------------
---  Create controls objects(btns,sliders etc) and override some methods   -------------------------
----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--- Filter Sliders ------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Filter HP_Freq --------------------------------
local HP_Freq = HP_Slider:new(20,410,160,18, 0.3,0.4,0.7,0.7, "Low Cut","Arial",16, 0.3312 )
-- Filter LP_Freq --------------------------------
local LP_Freq = LP_Slider:new(20,430,160,18, 0.3,0.4,0.7,0.7, "High Cut","Arial",16, 1 )

--------------------------------------------------
-- Filter Freq Sliders draw_val function ---------
--------------------------------------------------
function HP_Freq:draw_val()
  local sx = 16+(self.norm_val*100)*1.20103
  self.form_val = floor(exp(sx*logx(1.059))*8.17742) -- form val
  -------------
  local x,y,w,h  = self.x,self.y,self.w,self.h
  --local val = string.format("%.1f", self.form_val)
  local val = string.format("%d", self.form_val) .." Hz"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
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
  gfx.x = x+w-val_w-5
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
  gfx.x = x+w-val_w-5
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
local Gate_Sensitivity = S_Slider:new(210,400,160,18, 0.3,0.4,0.7,0.7, "Sensitivity","Arial",16, 0.31 )
function Gate_Sensitivity:draw_val()
  self.form_val = 2+(self.norm_val)*8       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." dB"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
end
-- Retrig ----------------------------------------
local Gate_Retrig = Rtg_Slider:new(210,420,160,18, 0.3,0.4,0.7,0.7, "Retrig","Arial",16, retrigms )
function Gate_Retrig:draw_val()
  self.form_val  = 20+ self.norm_val * 180   -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
end
-- Detect Velo time ------------------------------ 
local Gate_DetVelo = H_Slider:new(0,0,0,0, 0,0,0,0, "","Arial",16, 0.50 )------velodaw (680,450,90,18, 0.3,0.4,0.7,0.7, "Look","Arial",16, 0.50 )
function Gate_DetVelo:draw_val()
  self.form_val  = 5+ self.norm_val * 20     -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value



end
-- Reduce points slider -------------------------- 
local Gate_ReducePoints = Rdc_Slider:new(210,450,160,18, 0.3,0.4,0.7,0.7, "Reduce","Arial",16, 1 )
function Gate_ReducePoints:draw_val()
  self.cur_max   = self.cur_max or 0 -- current points max
  self.form_val  = ceil(self.norm_val * self.cur_max) -- form_val
  if self.form_val==0 and  self.cur_max>0 then self.form_val=1 end -- надо переделать,это принудительно 
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%d", self.form_val)
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
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
local Offset_Sld = O_Slider:new(400,430,205,18, 0.3,0.4,0.7,0.7, "Offset","Arial",16, 0.5 )------velodaw
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
  gfx.x = x+w-val_w-5
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
local QStrength_Sld = Q_Slider:new(400,450,101,18, 0.3,0.4,0.7,0.7, "Q Strength","Arial",16, QuantizeStrength*0.01 ) --205 (400,450,136,18
function QStrength_Sld:draw_val()
  self.form_val = (self.norm_val)*100       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val)..""
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
  q_strength =  floor(QStrength_Sld.form_val)
end
QStrength_Sld.onUp =
function() 

end

-- XFade slider ------------------------------ 
local XFade_Sld = X_Slider:new(503,450,102,18, 0.3,0.4,0.7,0.7, "XFades","Arial",16, CrossfadeTime*0.02 ) --205
function XFade_Sld:draw_val()
  self.form_val = (self.norm_val)*50       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5
  gfx.drawstr(val)--draw Slider Value
  x_fade =  floor(XFade_Sld.form_val)
end
XFade_Sld.onUp =
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
  gfx.x = x+5
  gfx.y = y+(h-val_h)/2 + T
  gfx.drawstr(val)  -- draw value 1
  gfx.x = x+w-val2_w-5
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

Slice_Status = 0
SliceQ_Status = 0
Markers_Status = 0

    r.Undo_BeginBlock() 
r.PreventUIRefresh(1)
local cursorpos = r.GetCursorPosition()

            r.Main_OnCommand(40290, 0) -- Set time selection to item
            r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVETIME1'), 0) 
            r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVEALLSELITEMS1'), 0)
            r.Main_OnCommand(40635, 0)     -- Remove Selection

r.SetEditCurPos(cursorpos,0,0) 
r.PreventUIRefresh(-1)
    r.Undo_EndBlock("Init", -1) 

--------------------------A Bit More Foolproof----------------------------

savepos()

sel_tracks_items() 

function collect_itemtake_param()    -- collect parameter on sel item and active take for SM tables and displacement calcs...
   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   src = r.GetMediaItemTake_Source(active_take)
   srate =  r.GetMediaSourceSampleRate(src) -- take samplerate (simple wave/MIDI detection)
 end
 
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item
   collect_itemtake_param()              -- get bunch of parameters about this item

if selected_tracks_count == 1 and number_of_takes > 1 and srate ~= 0 then 

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

if  srate == 0 then  

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

getsomerms()

getitem()

::zzz::

end


-- Create Just Slice  Button ----------------------------
local Just_Slice = Button:new(400,380,67,25, 0.3,0.3,0.3,1, "Slice",    "Arial",16 )
Just_Slice.onClick = 
function()
   if Wave.State then Wave:Just_Slice() end 
end 

-- Create Quantize Slices Button ----------------------------
local Quantize_Slices = Button:new(468,380,32,25, 0.3,0.3,0.3,1, "Q",    "Arial",16 )
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
local Quantize_Markers = Button:new(573,380,32,25, 0.3,0.3,0.3,1, "Q",    "Arial",16 )
Quantize_Markers.onClick = 
function()
   if Wave.State then Wave:Quantize_Markers() end 
end 

-- Reset All Button ----------------------------
local Reset_All = Button:new(970,445,55,25, 0.3,0.3,0.3,1, "Reset",    "Arial",16 )
Reset_All.onClick = 
function()

if Markers_Status ~= 0 or Slice_Status ~= 0 then

--------------------------A Bit More Foolproof----------------------------
 r.Undo_BeginBlock() 
r.PreventUIRefresh(1)
   
local cursorpos = r.GetCursorPosition()

sel_tracks_items() 
               r.Main_OnCommand(40548, 0)  -- Heal Splits

 count_itms =  r.CountSelectedMediaItems(0)

function collect_itemtake_param()    -- collect parameter on sel item and active take for SM tables and displacement calcs...
   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   src = r.GetMediaItemTake_Source(active_take)
   srate =  r.GetMediaSourceSampleRate(src) -- take samplerate (simple wave/MIDI detection)
 end
 
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item (well first one, anyway)
   collect_itemtake_param()              -- get bunch of parameters about this item (inc take playrate, I lifted this from another PL9 script)


if selected_tracks_count > 1 and count_itms == selected_tracks_count then

  r.Main_OnCommand(41844, 0) -- Remove Markers


else --------------------RESET MULTITRACK---------------------------
               r.Main_OnCommand(40029, 0)  -- Undo Heal Splits

end 



if  srate == 0 then

-----------------------------------Error Message2------------------------------------------------

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

---------------------------------End of Error Message2----------------------------------------------

 return 
end -- не запускать, если MIDI айтемы.

r.SetEditCurPos(cursorpos,0,0) 

r.PreventUIRefresh(-1)
   r.Undo_EndBlock("Reset_All", -1)    

   if Wave.State then Wave:Reset_All() end 
end 

-------------------------
end

-- Create Midi Button ----------------------------
local Create_MIDI = Button:new(610,380,68,25, 0.3,0.3,0.3,1, "MIDI",    "Arial",16 )
Create_MIDI.onClick = 


function()

M_Check = 0

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


M_Check = 1

return

end -- не запускать, если мультитрек.

if M_Check == 0 then

    r.Undo_BeginBlock() 

 r.Main_OnCommand(41844, 0)  ---Delete All Markers  


sel_tracks_items() 


function pitch_and_rate_check()

   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item (well first one, anyway)
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   take_pitch = r.GetMediaItemTakeInfo_Value(active_take, "D_PITCH")  -- take pitch
   take_playrate = r.GetMediaItemTakeInfo_Value(active_take, "D_PLAYRATE") -- take playrate 
   src = r.GetMediaItemTake_Source(active_take)
   srate =  r.GetMediaSourceSampleRate(src) -- take samplerate (simple wave/MIDI detection)

if selected_tracks_count > 1 then  return end -- не запускать, если айтемы находятся на разных треках.

if  srate == 0 then return end -- не запускать, если MIDI айтем.

 if take_pitch ~= 0 or take_playrate ~= 1.0 or number_of_takes ~= 1 and srate > 0 then
 
  r.Main_OnCommand(41588, 0) -- glue (если изменены rate, pitch, больше одного айтема и не миди айтем, то клей. Требуется для корректной работы кнопки MIDI).

end
end

pitch_and_rate_check()

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

----------------------------------------
--- Button_TB --------------------------
----------------------------------------
local Button_TB = {Get_Sel_Button, Just_Slice, Quantize_Slices, Add_Markers, Quantize_Markers, Reset_All, Create_MIDI, Midi_Sampler}
 


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
local DrawMode = CheckBox:new(0,0,0,0, 0.3,0.4,0.7,0.7, "","Arial",16,  1,  --(970,380,55,18, 0.3,0.4,0.7,0.7, "Draw: ","Arial",16,  1,
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
  local start_time = r.time_precise()--time test
  -----------------------------------------------------
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
  --r.ShowConsoleMsg("Gate time = " .. r.time_precise()-start_time .. '\n')--time test
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
            if not self.cap_ln and abs(line_x-gfx.mouse_x)<10 then 
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
        if Wave:mouseR_Down() then gfx.x, gfx.y  = mouse_ox, mouse_oy
            if gfx.showmenu("Delete")==1 then
               table.remove(self.Res_Points,self.cap_ln) -- Del self.cap_ln - Элементы смещаются влево!
               table.remove(self.Res_Points,self.cap_ln) -- Поэтому, опять тот же индекс(а не self.cap_ln+1)
            end
        end       
    end
    
    -- Insert Line(on mouseR_Down) -------------------------
    if not self.cap_ln and Wave:mouseR_Down() then gfx.x, gfx.y  = mouse_ox, mouse_oy
        if gfx.showmenu("Insert")==1 then
            local line_pos = self.start_smpl + (mouse_ox-Wave.x)/self.Xsc  -- Time point(in Samples!) from mouse_ox pos
            --------------------
            local newVelo = (self.Yop - mouse_oy)/(Wave.h*self.scale) -- velo from mouse y pos
            newVelo = min(max(newVelo,0),1)
            --------------------             
            table.insert(self.Res_Points, line_pos)           -- В конец таблицы
            table.insert(self.Res_Points, {newVelo, newVelo}) -- В конец таблицы
            --------------------
            self.cap_ln = #self.Res_Points
        end
    end 
end


------------------------------------------------------------------------------------------------------------------------
---   WAVE   -----------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------


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

sel_tracks_items() -- select for a multitrack check

   selected_tracks_count = r.CountSelectedTracks(0)

 count_itms =  r.CountSelectedMediaItems(0)

 r.Undo_BeginBlock() 
r.PreventUIRefresh(1)
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
            r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTTIME1'), 0)  -- Restore Selection
               r.Main_OnCommand(40061, 0)     -- Item: Split items at time selection
               r.Main_OnCommand(40718, 0)  -- Select all items on selected tracks in current time selection
               r.Main_OnCommand(40635, 0)     -- Remove Selection


               r.Main_OnCommand(40032, 0) -- Group Items

elseif count_itms > selected_tracks_count and selected_tracks_count >1 then  -- multitrack

            r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTTIME1'), 0)  -- Restore Selection
               r.Main_OnCommand(40061, 0)     -- Item: Split items at time selection
               r.Main_OnCommand(40718, 0)  -- Select all items on selected tracks in current time selection
               r.Main_OnCommand(40635, 0)     -- Remove Selection


               r.Main_OnCommand(40032, 0) -- Group Items

end

sel_tracks_items() -- select for a multitrack check

   selected_tracks_count = r.CountSelectedTracks(0)

 count_itms =  r.CountSelectedMediaItems(0)

         r.Main_OnCommand(40548, 0)  -- Heal Splits

if count_itms > selected_tracks_count and selected_tracks_count >1 then  -- sliced multitrack

 if Slice_Status == 0 then---------------------------------glue------------------------------

         r.Main_OnCommand(40548, 0)  -- Heal Splits

   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end

local i=0;

while(true) do;
  i=i+1;
  local item = reaper.GetSelectedMediaItem(0,i-1);
  if item then;

   active_take = r.GetActiveTake(item)  -- active take in item
   take_start_offset = r.GetMediaItemTakeInfo_Value(active_take, "D_STARTOFFS") -- take offset

          r.Main_OnCommand(41588, 0) -- glue (если кусок айтема и не со стартовой точки, то клей).

  else;
    break;
  end;
end;

end

end

savepos()

Wave:Reset_All()

sel_tracks_items() -- select for a multitrack check

   selected_tracks_count = r.CountSelectedTracks(0)

 count_itms =  r.CountSelectedMediaItems(0)

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

  if  cutpos - self.sel_start >= 0.04 and self.sel_end - cutpos >= 0.07 then -- if transient too close near item start, do nothing
            r.SetEditCurPos(cutpos,0,0)          
            r.Main_OnCommand(40757, 0)  ---split
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

Slice_Status = 1 

SliceQ_Status = 1

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


function Wave:Quantize_Slices()

if SliceQ_Status ~= 0 then
              
 r.Undo_BeginBlock() 
 r.PreventUIRefresh(1)
   -------------------------------------------

 count_itms =  r.CountSelectedMediaItems(0)

       _, save_project_grid, save_swing, save_swing_amt = r.GetSetProjectGrid(proj, false) -- backup current grid settings

    if save_project_grid > 0.5 then
               r.Main_OnCommand(40780, 0)  -- Set minimal Grid size (1/2)
    end

function quantize()

local i=0;

while(true) do
  i=i+1
  local item = r.GetSelectedMediaItem(0,i-1)
  if item then
        pos = r.GetMediaItemInfo_Value(item, "D_POSITION") + r.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")

if r.GetToggleCommandState(reaper.NamedCommandLookup('_BR_OPTIONS_SNAP_FOLLOW_GRID_VIS'), 0) == 1 then
      grid_opt = 1
  else
      grid_opt = 0
      r.Main_OnCommand(reaper.NamedCommandLookup('_BR_OPTIONS_SNAP_FOLLOW_GRID_VIS'), 0)
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

        r.SetMediaItemInfo_Value(item, "D_POSITION", pos - q_strength / 100 * (pos - ( r.SnapToGrid(0, pos))) - r.GetMediaItemInfo_Value(item, "D_SNAPOFFSET"))
  else
    break
  end

 if  grid_opt == 0 then r.Main_OnCommand(reaper.NamedCommandLookup('_BR_OPTIONS_SNAP_FOLLOW_GRID_VIS'), 0) end
 if  snap == 0 then r.Main_OnCommand(1157, 0) end
 if  grid == 0 then r.Main_OnCommand(40145, 0) end

end
r.UpdateArrange();
end

quantize()

cleanup_slices()


r.Main_OnCommand(r.NamedCommandLookup("_SWS_AWFILLGAPSQUICK"),0) -- fill gaps 

        CrossfadeT = x_fade

    local function Overlap(CrossfadeT);
        local t,ret = {};
        local items_count = reaper.CountSelectedMediaItems(0);
        if items_count == 0 then return 0 end;
        for i = 1 ,items_count do;
            local item = reaper.GetSelectedMediaItem(0,i-1);
            local trackIt = reaper.GetMediaItem_Track(item);
            if t[tostring(trackIt)] then;
                ----
                ret = 1;
                local crossfade_time = (CrossfadeT or 0)/1000;
                local take = reaper.GetActiveTake(item); 
                local pos = reaper.GetMediaItemInfo_Value(item,'D_POSITION');
                local length = reaper.GetMediaItemInfo_Value( item,'D_LENGTH');
                local rateIt = reaper.GetMediaItemTakeInfo_Value(take,'D_PLAYRATE');
                local ofSetIt = reaper.GetMediaItemTakeInfo_Value(take,'D_STARTOFFS');
                if pos < crossfade_time then crossfade_time = pos end;
                ----
                reaper.SetMediaItemInfo_Value(item,'D_POSITION',pos-crossfade_time);
                reaper.SetMediaItemInfo_Value(item,'D_LENGTH',length+crossfade_time);
                reaper.SetMediaItemTakeInfo_Value(take,'D_STARTOFFS',ofSetIt-(crossfade_time*rateIt));
            else;
                t[tostring(trackIt)] = trackIt;
            end;
        end;
        if ret == 1 then reaper.Main_OnCommand(41059,0) end;
        return ret or 0;
    end;
    
    
    reaper.Undo_BeginBlock();
    local Over = Overlap(CrossfadeT);
    reaper.Undo_EndBlock("Overlap",Over-Over*2);
    reaper.UpdateArrange();

       r.GetSetProjectGrid(proj, true, save_project_grid, save_swing, save_swing_amt) -- restore saved grid settings

 r.PreventUIRefresh(-1)

    -------------------------------------------
    r.Undo_EndBlock("Quantize Slices", -1)    

end

SliceQ_Status = 0

end


function Wave:Add_Markers()

SliceQ_Status = 1

sel_tracks_items() -- select for a multitrack check

   selected_tracks_count = r.CountSelectedTracks(0)

 count_itms =  r.CountSelectedMediaItems(0)

 r.Undo_BeginBlock() 
r.PreventUIRefresh(1)

if count_itms == selected_tracks_count and selected_tracks_count >1 then  -- multitrack
            r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTTIME1'), 0)  -- Restore Selection
               r.Main_OnCommand(40061, 0)     -- Item: Split items at time selection
               r.Main_OnCommand(40718, 0)  -- Select all items on selected tracks in current time selection
               r.Main_OnCommand(40635, 0)     -- Remove Selection


               r.Main_OnCommand(40032, 0) -- Group Items

elseif count_itms > selected_tracks_count and selected_tracks_count >1 then  -- multitrack

            r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTTIME1'), 0)  -- Restore Selection
               r.Main_OnCommand(40061, 0)     -- Item: Split items at time selection
               r.Main_OnCommand(40718, 0)  -- Select all items on selected tracks in current time selection
               r.Main_OnCommand(40635, 0)     -- Remove Selection


               r.Main_OnCommand(40032, 0) -- Group Items

end

local cursorpos = r.GetCursorPosition()

if selected_tracks_count > 1 and count_itms == selected_tracks_count then --------------------RESET MULTITRACK (Markers)---------------------------

  r.Main_OnCommand(41844, 0) -- Remove Markers

else

if selected_tracks_count > 1 and count_itms > selected_tracks_count then --------------------RESET SLICED MULTITRACK (Markers)---------------------------

  r.Main_OnCommand(41844, 0) -- Remove Markers
               r.Main_OnCommand(40548, 0)  -- Heal Splits

end

end 


sel_tracks_items() 

               r.Main_OnCommand(40548, 0)  -- Heal Splits

 count_itms =  r.CountSelectedMediaItems(0)

function collect_itemtake_param()    -- collect parameter on sel item and active take for SM tables and displacement calcs...
   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   src = r.GetMediaItemTake_Source(active_take)
   srate =  r.GetMediaSourceSampleRate(src) -- take samplerate (simple wave/MIDI detection)
 end
 
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item (well first one, anyway)
   collect_itemtake_param()              -- get bunch of parameters about this item (inc take playrate, I lifted this from another PL9 script)


if selected_tracks_count > 1 and count_itms == selected_tracks_count then

  r.Main_OnCommand(41844, 0) -- Remove Markers


else --------------------RESET MULTITRACK---------------------------

               r.Main_OnCommand(40029, 0)  -- Undo Heal Splits
end


Markers_Status = 1

r.SetEditCurPos(cursorpos,0,0) 

r.PreventUIRefresh(-1)
   r.Undo_EndBlock("Reset (add markers)", -1)    

Wave:Reset_All() -- single track reset

if count_itms > 1 and selected_tracks_count >1 then  -- multitrack
               r.Main_OnCommand(40032, 0) -- Group Items
end

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

            r.Main_OnCommand(40290, 0) -- Set time selection to item
            r.Main_OnCommand(41843, 0)  ---Add Marker
            r.Main_OnCommand(40635, 0)     -- Remove Selection

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
 
 
 
    -------------------------------------------
    r.Undo_EndBlock("Add Markers", -1)    

end
end



function Wave:Quantize_Markers()

     
 r.Undo_BeginBlock() 
r.PreventUIRefresh(1)
   -------------------------------------------

       _, save_project_grid, save_swing, save_swing_amt = r.GetSetProjectGrid(proj, false) -- backup current grid settings

    if save_project_grid > 0.5 then
               r.Main_OnCommand(40780, 0)  -- Set minimal Grid size (1/2)
    end

--------------------Snap Markers to Grid----------------------

local i=0;

    r.Undo_BeginBlock();
while(true) do;
  i=i+1;
  local item = reaper.GetSelectedMediaItem(0,i-1);
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
            local posGrid = r.SnapToGrid(0,pos);
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

    -------------------------------------------
    r.Undo_EndBlock("Quantize Markers", -1)    
 
end

--------------------------------------------------------------------------------------


function Wave:Reset_All()

SliceQ_Status = 1

local cursorpos = r.GetCursorPosition()
   
 r.Undo_BeginBlock() 
r.PreventUIRefresh(1)
   -------------------------------------------
               r.Main_OnCommand(40033, 0) -- UnGroup
  r.Main_OnCommand(41844, 0) -- Remove Markers
               r.Main_OnCommand(40548, 0)  -- Heal Splits

 count_itms =  r.CountSelectedMediaItems(0)

   r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVESEL'), 0)  -- Save track selection

sel_tracks_items() -- select for a multitrack check

   selected_tracks_count = r.CountSelectedTracks(0)

 restorepos()


if count_itms > 1 and selected_tracks_count == 1 then -- single item/sliced item


elseif count_itms > 1 and selected_tracks_count == count_itms then  -- multitrack


  r.Main_OnCommand(41844, 0) -- Remove Markers

elseif count_itms > selected_tracks_count and selected_tracks_count >1 then  -- sliced multitrack

                 r.Main_OnCommand(40548, 0)  -- Heal Splits

end

r.SetEditCurPos(cursorpos,0,0) 

 r.PreventUIRefresh(-1)

    -------------------------------------------
    r.Undo_EndBlock("Reset_All", -1)    

end


function Wave:Load_To_Sampler(sel_start, sel_end, track)

              r.Undo_BeginBlock()
             r.PreventUIRefresh(1) 

ItemState = r.GetExtState('_Slicer_', 'GetItemState')

if  (ItemState=="ItemLoaded") then 

r.SelectAllMediaItems(0, 0 )

r.Main_OnCommand(40297,0) ----unselect all tracks

lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')   
item =  r.BR_GetMediaItemByGUID( 0, lastitem )
track = r.GetMediaItem_Track(item)
               
r.GetSet_LoopTimeRange2( 0, 1, 0, self.sel_start, self.sel_end, 0 )

r.SetTrackSelected( track, 1 )

r.Main_OnCommand(40718,0)----Select all items on selected tracks in currient time selection
r.Main_OnCommand(40635,0) ---Remove Time selection

elseif not (ItemState=="ItemLoaded") then 

self.sel_start = sel_start
self.sel_end = sel_end 


end

data ={}

data.parent_track =  track

obeynoteoff_default = 1

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
 
    
    if not data.parent_track or not note or not filepath then return end

    local track =  r.GetSelectedTrack( 0, 0 )
    if data[note] and data[note][1] then 
      track = data[note][1].src_track
      if conf.allow_multiple_spls_per_pad == 0 then
        r.TrackFX_SetNamedConfigParm(  track, data[note][1].rs5k_pos, 'FILE0', filepath)
        r.TrackFX_SetNamedConfigParm(  track, data[note][1].rs5k_pos, 'DONE', '')
        return 1  
       else
        ExportItemToRS5K_defaults(data,conf,refresh,note,filepath, start_offs, end_offs, track)  
        return #data[note]+1        
      end
     else
       ExportItemToRS5K_defaults(data,conf,refresh,note,filepath, start_offs, end_offs, track)
       return 1
    end
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
          --if ret then r.ShowConsoleMsg('done') end
      end
      r.MIDI_Sort( new_tk )
      r.GetSetMediaItemTakeInfo_String( new_tk, 'P_NAME', 'sliced loop', 1 )
      
      newmidiitem = r.GetMediaItemTake_Item(new_tk)
 
      r.SetMediaItemSelected( newmidiitem, 1 )
      
      r.UpdateArrange()    
  end



function Load() 

              -- track check
                local track = track
                if not track then return end        
              -- item check
                local item = r.GetSelectedMediaItem(0,0)
                if not item then return true end  
              -- get base pitch
               
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
                  ::skip_to_next_item::
                end
                   
                   r.Main_OnCommand(40548,0)--Item: Heal Splits   
                   r.Main_OnCommand(40719,0)--Item: Mute items     
              -- add MIDI
                if proceed_MIDI then ExportSelItemsToRs5k_AddMIDI(track, MIDI,base_pitch) end        
                     
    r.PreventUIRefresh(-1)
 
       -------------------------------------------
       r.Undo_EndBlock("Export To Sampler", -1)        
              
            end

function doublecheck()

   selected_tracks_count = r.CountSelectedTracks(0)
   number_of_takes =  r.CountSelectedMediaItems(0)
   if number_of_takes == 0 then return end
   sel_item = r.GetSelectedMediaItem(0, 0)    -- get selected item (well first one, anyway)
   active_take = r.GetActiveTake(sel_item)  -- active take in item
   src = r.GetMediaItemTake_Source(active_take)
   srate =  r.GetMediaSourceSampleRate(src) -- take samplerate (simple wave/MIDI detection)

if  srate ~= 0 then Load() end --

end

doublecheck()

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
   
if (getitem ==0) then
    if self.AA then r.DestroyAudioAccessor(self.AA) 
       self.buffer.clear()
    end
 end
end

--------
function Wave:Get_TimeSelection()

 local item = r.GetSelectedMediaItem(0,0)
    if item then
    
 local sel_start = r.GetMediaItemInfo_Value(item, "D_POSITION")
         local sel_end = sel_start + r.GetMediaItemInfo_Value(item, "D_LENGTH")
  
   
    local sel_len = sel_end - sel_start
    if sel_len<0.25 then return end -- 0.25 minimum
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
    self.crsx   = block_size/8   -- one side "crossX"  -- use for discard some FFT artefacts(its non-nat, but in this case normally)
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
  local start_time = r.time_precise()--time test
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
  end
end 
--------------------------
function Wave:Set_Cursor()
  if self:mouseDown() and not(Ctrl or Shift) then  
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
    self.insrc_mx = self.Pos + (gfx.mouse_x-self.x)/(self.Zoom*Z_w) -- its current mouse position in source!
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
      self.Pos = self.insrc_mx - (gfx.mouse_x-self.x)/(self.Zoom*Z_w)
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
     if  KeyR == 1 then self.Zoom = min(self.Zoom*1.2, self.max_vertZoom)   

      self.Pos = self.insrc_mx - (gfx.mouse_x-self.x)/(self.Zoom*Z_w)
      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )

     Wave:Redraw() -- redraw after vertical zoom
     else
     end   

     if  KeyL == 1 then self.Zoom = max(self.Zoom*0.8, 1)

      self.Pos = self.insrc_mx - (gfx.mouse_x-self.x)/(self.Zoom*Z_w)
      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )

     Wave:Redraw() -- redraw after vertical zoom
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
 local fnt_sz = 16
 fnt_sz = max(9,  fnt_sz* (Z_w+Z_h)/2)
 fnt_sz = min(20, fnt_sz)
 gfx.setfont(1, "Arial", fnt_sz)
 gfx.set(0.7, 0.7, 0.7, 1) -- цвет текста инфо
 gfx.x, gfx.y = self.x+10, self.y+10
 gfx.drawstr(
  [[
  Select an item (max 180s).
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
  for key,sldr   in pairs(Slider_TB)   do sldr:draw()   end
  end
   
    for key,ch_box in pairs(CheckBox_TB) do ch_box:draw() end
    for key,frame  in pairs(Frame_TB)    do frame:draw()  end       
end

--------------------------------------------------------------------------------
--   INIT   --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Init()
    -- Some gfx Wnd Default Values ---------------
    local R,G,B = 45,45,45              -- 0...255 format -- цвет основного окна
    local Wnd_bgd = R + G*256 + B*65536 -- red+green*256+blue*65536  
    local Wnd_Title = "MK Slicer v1.3"
    local Wnd_Dock, Wnd_X,Wnd_Y = Docked,400,320 
    Wnd_W,Wnd_H = 1044,490 -- global values(used for define zoom level)
    -- Init window ------
    gfx.clear = Wnd_bgd         
    gfx.init( Wnd_Title, Wnd_W,Wnd_H,Wnd_Dock, Wnd_X,Wnd_Y )
    -- Init mouse last --
    last_mouse_cap = 0
    last_x, last_y = 0, 0
    mouse_ox, mouse_oy = -1, -1
end
----------------------------------------
--   Mainloop   ------------------------
----------------------------------------
function mainloop()

    -- zoom level -- 
    Z_w, Z_h = gfx.w/Wnd_W, gfx.h/Wnd_H
    if Z_w<0.65 then Z_w = 0.65 elseif Z_w>1.8 then Z_w = 1.8 end 
    if Z_h<0.65 then Z_h = 0.65 elseif Z_h>1.8 then Z_h = 1.8 end 
    -- mouse and modkeys --
    if gfx.mouse_cap&1==1   and last_mouse_cap&1==0  or   -- L mouse
       gfx.mouse_cap&2==2   and last_mouse_cap&2==0  or   -- R mouse
       gfx.mouse_cap&64==64 and last_mouse_cap&64==0 then -- M mouse
       mouse_ox, mouse_oy = gfx.mouse_x, gfx.mouse_y 
    end
    Ctrl  = gfx.mouse_cap&4==4   -- Ctrl  state
    Shift = gfx.mouse_cap&8==8   -- Shift state
    MCtrl = gfx.mouse_cap&5==5   -- Ctrl+LMB state
    Alt   = gfx.mouse_cap&16==16 -- Alt state
    
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

SliceQ_Status = 1

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

end

function getitem()

local start_time = r.time_precise()
   ---------------------
   Wave:Destroy_Track_Accessor() -- Destroy previos AA(освобождает память etc)
   Wave.State = false -- reset Wave.State
   if Wave:Create_Track_Accessor() then Wave:Processing()
      if Wave.State then
         Wave:Redraw()
         Gate_Gl:Apply_toFiltered() 
      end
   end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

Init()
mainloop()

getitem()


function ClearExState()

r.DeleteExtState('_Slicer_', 'ItemToSlice', 0)
r.DeleteExtState('_Slicer_', 'TrackForSlice', 0)
r.SetExtState('_Slicer_', 'GetItemState', 'ItemNotLoaded', 0)
end

r.atexit(ClearExState)

-- @description MK Slicer
-- @author cool
-- @version 2.15
-- @changelog
--   + Now the combination Ctrl+S works when the script window is active.
--   + os.execute replaced with CF_ShellExecute for better performance and Linux compatibility.
--   + Added a hidden option to force Sync to be enabled every time the script is run.
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=232672
-- @screenshot MKSlicer2.0 https://i.imgur.com/QFWHt9a.png
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
--    - Trigger. Easy conversion of rhythmic parts to midi patterns with accurate velocity reproduction.
--    - Random - a function for randomizing slices and some of their parameters. Ideal for uniqualization, humanization and creation of new parts.
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
MK Slicer v2.15 by Maxim Kokarev 
https://forum.cockos.com/member.php?u=121750

Co-Author of the compilation - MyDaw
https://www.facebook.com/MyDawEdition/

"Remove selected overlapped items (by tracks)" 
"Remove final selected item in tracks"
"Unselect all items except first selected in track"
"Grid switch" (snippet)
scripts by Archie
https://forum.cockos.com/member.php?u=120700

Based on "Drums to MIDI(beta version)" script by eugen2777
http://forum.cockos.com/member.php?u=50462  

Export to ReaSamplOmatic5000 function from RS5k manager by MPL 
https://forum.cockos.com/showthread.php?t=207971  

Razor Edit functions by BirdBird and Juliansander
https://forum.cockos.com/showthread.php?t=241604

Randomise Reverse Based on "me2beats_Toggle random active takes reverse"
script by me2beats
https://forum.cockos.com/member.php?u=100851
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
Random_Status = 0
MouseUpX = 0
MIDISampler = 0
Midi_sampler_offs_stat = 0
Reset_to_def = 0
RE_Status = 0
SliceQ_Status_Rand = 0
Swing_on = 0
Grid1_on = 0
Grid2_on = 0
Grid4_on = 0
Grid8_on = 0
Grid16_on = 0
Grid32_on = 0
Grid64_on = 0
GridT_on = 0

----------------------------Advanced Settings-------------------------------------------

RememberLast = 1            -- (Remember some sliders positions from last session. 1 - On, 0 - Off)
AutoXFadesOnSplitOverride = 1 -- (Override "Options: Toggle auto-crossfade on split" option. 0 - Don't Override, 1 - Override)
Compensate_Oct_Offset = 0 -- (Trigger: octave shift of note names to compensate "MIDI octave name display offset". -4 - Min, 4 - Max)
WFiltering = 0 -- (Waveform Visual Filtering while Window Scaling. 1 - On, 0 - Off)
ShowRuler = 1 -- (Show Project Grid Green Markers. 1 - On, 0 - Off)
ShowInfoLine = 0 -- (Show Project Info Line. 1 - On, 0 - Off)
SnapToStart = 1 --(Snap Play Cursor to Waveform Start. 1 - On, 0 - Off)
ZeroCrossingType = 1 -- (1 - Snap to Nearest (working fine), 0 - Snap to previous (not recommend, for testing only!))
SnapToSemi = 1 -- (Random pitch steps by semitones 2 - On(Intervals), 1 - On(chromatic), 0 - Off(cents))
ForceSync = 0 -- (force Sync On on the script starts: 1 - On (Force On), 0 - Off (Save Previous State))

------------------------End of Advanced Settings----------------------------------------

-----------------------------------States and UA  protection-----------------------------

Docked = tonumber(r.GetExtState('cool_MK Slicer.lua','Docked'))or 0;
EscToExit = tonumber(r.GetExtState('cool_MK Slicer.lua','EscToExit'))or 1;
MIDISamplerCopyFX = tonumber(r.GetExtState('cool_MK Slicer.lua','MIDISamplerCopyFX'))or 1;
MIDISamplerCopyRouting = tonumber(r.GetExtState('cool_MK Slicer.lua','MIDISamplerCopyRouting'))or 1;
MIDI_Mode = tonumber(r.GetExtState('cool_MK Slicer.lua','Midi_Sampler.norm_val'))or 1;
Sampler_preset_state = tonumber(r.GetExtState('cool_MK Slicer.lua','Sampler_preset.norm_val'))or 1;
AutoScroll = tonumber(r.GetExtState('cool_MK Slicer.lua','AutoScroll'))or 0;
PlayMode = tonumber(r.GetExtState('cool_MK Slicer.lua','PlayMode'))or 0;
Loop_on = tonumber(r.GetExtState('cool_MK Slicer.lua','Loop_on'))or 1;

   if ForceSync == 1 then
       Sync_on = 1
         else
       Sync_on = tonumber(r.GetExtState('cool_MK Slicer.lua','Sync_on'))or 0;
   end

ZeroCrossings = tonumber(r.GetExtState('cool_MK Slicer.lua','ZeroCrossings'))or 0;
ItemFadesOverride = tonumber(r.GetExtState('cool_MK Slicer.lua','ItemFadesOverride'))or 1;
ObeyingTheSelection = tonumber(r.GetExtState('cool_MK Slicer.lua','ObeyingTheSelection'))or 1;
ObeyingItemSelection = tonumber(r.GetExtState('cool_MK Slicer.lua','ObeyingItemSelection'))or 1;
XFadeOff = tonumber(r.GetExtState('cool_MK Slicer.lua','XFadeOff'))or 0;
Guides_mode = tonumber(r.GetExtState('cool_MK Slicer.lua','Guides.norm_val'))or 1;
OutNote_State = tonumber(r.GetExtState('cool_MK Slicer.lua','OutNote.norm_val'))or 1;
Notes_On = tonumber(r.GetExtState('cool_MK Slicer.lua','Notes_On'))or 1;
VeloRng = tonumber(r.GetExtState('cool_MK Slicer.lua','Gate_VeloScale.norm_val'))or 0.231;
VeloRng2 = tonumber(r.GetExtState('cool_MK Slicer.lua','Gate_VeloScale.norm_val2'))or 1;
Random_Order = tonumber(r.GetExtState('cool_MK Slicer.lua','Random_Order'))or 1;
Random_Vol = tonumber(r.GetExtState('cool_MK Slicer.lua','Random_Vol'))or 0;
Random_Pan = tonumber(r.GetExtState('cool_MK Slicer.lua','Random_Pan'))or 0;
Random_Pitch = tonumber(r.GetExtState('cool_MK Slicer.lua','Random_Pitch'))or 0;
Random_Mute = tonumber(r.GetExtState('cool_MK Slicer.lua','Random_Mute'))or 0;
Random_Position = tonumber(r.GetExtState('cool_MK Slicer.lua','Random_Position'))or 0;
Random_Reverse = tonumber(r.GetExtState('cool_MK Slicer.lua','Random_Reverse'))or 0;
RandV = tonumber(r.GetExtState('cool_MK Slicer.lua','RandV_Sld.norm_val'))or 0.5;
RandPan = tonumber(r.GetExtState('cool_MK Slicer.lua','RandPan_Sld.norm_val'))or 1;
RandPtch = tonumber(r.GetExtState('cool_MK Slicer.lua','RandPtch_Sld.norm_val'))or 0.5;
RandPos = tonumber(r.GetExtState('cool_MK Slicer.lua','RandPos_Sld.norm_val'))or 0.2;
RandMute = tonumber(r.GetExtState('cool_MK Slicer.lua','RandRev_Sld.norm_val'))or 0.5;

if AutoXFadesOnSplitOverride == nil then AutoXFadesOnSplitOverride = 1 end 
if AutoXFadesOnSplitOverride <= 0 then AutoXFadesOnSplitOverride = 0 elseif AutoXFadesOnSplitOverride >= 1 then AutoXFadesOnSplitOverride = 1 end 
if RememberLast == nil then RememberLast = 1 end 
if RememberLast <= 0 then RememberLast = 0 elseif RememberLast >= 1 then RememberLast = 1 end 
if Compensate_Oct_Offset == nil then Compensate_Oct_Offset = 0 end 
if Compensate_Oct_Offset <= -4 then Compensate_Oct_Offset = -4 elseif Compensate_Oct_Offset >= 4 then Compensate_Oct_Offset = 4 end 
if WFiltering == nil then WFiltering = 1 end 
if WFiltering <= 0 then WFiltering = 0 elseif WFiltering >= 1 then WFiltering = 1 end 

 loopcheck = 0
----loopcheck------
local loopcheckstart, loopcheckending = r.GetSet_LoopTimeRange( 0, true, 0, 0, 0 )
if loopcheckstart == loopcheckending and loopcheckstart and loopcheckending then 
     loopcheck = 0
       else
     loopcheck = 1
end

    r.Undo_BeginBlock() 
r.PreventUIRefresh(1)

-------------------------------Check time range and unselect-----------------------------

function unselect_if_out_of_time_range()

local j=0; -- unselect if out of time range 
while(true) do;
  j=j+1;
  local track = r.GetSelectedTrack(0,j-1);
  if track then;
  local start, ending = r.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
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
    if r.TakeIsMIDI(active_take) then 
    Take_Check = 1 end
  else;
    break;
  end;
end;

end

-------------------------------Check Razor Edits-----------------------------
function GetItemsInRange(track, areaStart, areaEnd)
    local items = {}
    local itemCount = r.CountTrackMediaItems(track)
    for k = 0, itemCount - 1 do 
        local item = r.GetTrackMediaItem(track, k)
        local pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = r.GetMediaItemInfo_Value(item, "D_LENGTH")
        local itemEndPos = pos+length
        if (itemEndPos > areaStart and itemEndPos <= areaEnd) or          --check if item is in area bounds
            (pos >= areaStart and pos < areaEnd) or
            (pos <= areaStart and itemEndPos >= areaEnd) then
                table.insert(items,item)
        end
    end
    return items
end

function SetTrackRazorEdit(track, areaStart, areaEnd, clearSelection)
    if clearSelection == nil then clearSelection = false end   
    if clearSelection then
        local ret, area = r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)   
        local str = {}  --parse string, all this string stuff could probably be written better
        for j in string.gmatch(area, "%S+") do table.insert(str, j) end       
        local j = 1   --strip existing selections across the track
        while j <= #str do
            local GUID = str[j+2]
            if GUID == '""' then 
                str[j] = ''
                str[j+1] = ''
                str[j+2] = ''
            end
            j = j + 3
        end
        --insert razor edit 
        local REstr = tostring(areaStart) .. ' ' .. tostring(areaEnd) .. ' ""'
        table.insert(str, REstr)
        local finalStr = ''
        for i = 1, #str do
            local space = i == 1 and '' or ' '
            finalStr = finalStr .. space .. str[i]
        end
        local ret, area = r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', finalStr, true)
        return ret
    else         
        local ret, area = r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
        local str = area ~= nil and area .. ' ' or ''
        str = str .. tostring(areaStart) .. ' ' .. tostring(areaEnd) .. '  ""'       
        local ret, area = r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', str, true)
        return ret
    end
end

function GetRazorEdits()
    local trackCount = r.CountTracks(0)
    local areaMap = {}
    for i = 0, trackCount - 1 do
        local track = r.GetTrack(0, i)
        local ret, area = r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
        if area ~= '' then
            --PARSE STRING
            local str = {}
            for j in string.gmatch(area, "%S+") do
                table.insert(str, j)
            end       
            --FILL AREA DATA
            local j = 1
            while j <= #str do
                local areaStart = tonumber(str[j])        --area data
                local areaEnd = tonumber(str[j+1]) 
                local items = {}  --get item data
                items = GetItemsInRange(track, areaStart, areaEnd)
                  r.SetTrackSelected(track, true) -- Set Track Selected
                local areaData = {
                    areaStart = areaStart,
                    areaEnd = areaEnd,                
                    track = track,
                    items = items,                   
                }
                table.insert(areaMap, areaData)
                j = j + 3
            end
        end
    end
    return areaMap
end

function SplitRazorEdits(razorEdits)
left, right = huge, -huge
    local areaItems = {}
    local tracks = {}
    for i = 1, #razorEdits do
        local areaData = razorEdits[i]
        if not areaData.isEnvelope then
            local items = areaData.items           
            if tracks[areaData.track] ~= nil then  --recalculate item data for tracks with previous splits
                items = GetItemsInRange(areaData.track, areaData.areaStart, areaData.areaEnd)
            end            
            for j = 1, #items do 
                local item = items[j]        
                 if areaData.areaStart  < left  then left  = areaData.areaStart end  --combine areas and set time selection
                 if areaData.areaEnd > right then right = areaData.areaEnd end
                 if left <= right then
                      r.GetSet_LoopTimeRange2(0, true, false, left, right, false)
                      table.insert(areaItems, item)
                 end
            end
            tracks[areaData.track] = 1
        end
    end
    return areaItems
end

 -- Unselect All Tracks if RE exist --
    for i = 0, r.CountTracks(0) - 1 do
        local _, check_area = r.GetSetMediaTrackInfo_String(r.GetTrack(0, i), 'P_RAZOREDITS', '', false)
        if check_area ~= '' then
                r.Main_OnCommand(40297, 0) -- Unselect all tracks
                RE_Status = 1
        end
    end

 -- Select Items by RE --
local selections = GetRazorEdits()
local items = SplitRazorEdits(selections)
for i = 1, #items do
    local item = items[i]
    r.SetMediaItemSelected(item, true)
end

take_check()
sel_tr_count = r.CountSelectedTracks(0)
  if sel_tr_count == 1 then
        r.Main_OnCommand(42406, 0) -- Clear RE Areas
     local   start, ending = r.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
           if start ~= ending and Take_Check ~= 1 then
               r.Main_OnCommand(40061, 0) -- Split at Time Selection
               r.Main_OnCommand(40635, 0) -- Remove Time Selection
           end
    elseif sel_tr_count > 1 then
    gfx.quit() 
    r.ShowConsoleMsg("Only single track items, please. User manual: https://forum.cockos.com/showthread.php?t=232672")
    return
    elseif sel_tr_count ==0 then
  end

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

function re_createRE()
    local itemCount = r.CountSelectedMediaItems(0) -- re-create deleted RE
    for i = 0, itemCount - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        local track = r.GetMediaItem_Track(item)      
        local itemStartPosition = r.GetMediaItemInfo_Value(item, 'D_POSITION')
        local itemLength = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
        local itemEndPosition = itemStartPosition + itemLength
        SetTrackRazorEdit(track, itemStartPosition, itemEndPosition, false)
    end
end


function deferinit() -- continuous selection items in RE
for t = 0, reaper.CountTracks(0)-1 do
    local track = reaper.GetTrack(0, t)
    local tR = {}
    local razorOK, razorStr = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    if razorOK and #razorStr ~= 0 then
        for razorLeft, razorRight, envGuid in razorStr:gmatch([[([%d%.]+) ([%d%.]+) "([^"]*)"]]) do
            if envGuid == "" then
                local razorLeft, razorRight = tonumber(razorLeft), tonumber(razorRight)
                table.insert(tR, {left = razorLeft, right = razorRight})
            end
        end
    end
    for i = 0, reaper.CountTrackMediaItems(track)-1 do
        local item = reaper.GetTrackMediaItem(track, i)
        reaper.SetMediaItemSelected(item, false)
        local left = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local right = left + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        for _, r in ipairs(tR) do
            if left < r.right and right > r.left then
                reaper.SetMediaItemSelected(item, true)
            end
        end
    end
end
reaper.UpdateArrange()
      if char~=-1 then r.defer(deferinit)  else end     -- defer     r.defer(deferinit)
end


        if RE_Status == 1 then
             re_createRE()
             deferinit()
        end

---------------------------------------End of RE_Splits----------------------------------------

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
 end

collect_param()
local start, ending = r.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
time_sel_length = ending - start
if ObeyingTheSelection == 1 and ObeyingItemSelection == 0 and start ~= ending then
    r.Main_OnCommand(40289, 0) -- Item: Unselect all items
          if time_sel_length >= 0.25 and selected_tracks_count == 1 then
              r.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
          end
end

count_itms =  r.CountSelectedMediaItems(0)
if ObeyingTheSelection == 1 and count_itms ~= 0 and start ~= ending and time_sel_length >= 0.25 then
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

   for i = 0, number_of_takes-1 do -- take fx check
     local item = r.GetSelectedMediaItem(0, i)
     local take_count = r.CountTakes(item)
     for j = 0, take_count-1 do
       local take = r.GetMediaItemTake(item, j) 
       if r.TakeFX_GetCount(take) > 0 then 
        tkfx = 1
       end
     end
   end

        if number_of_takes ~= 1 and tkfx ~= 1 then
           r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то попытка не деструктивно склеить).
        end
       collect_param()    
       if number_of_takes ~= 1 then -- проверяем ещё раз. Если не удалось, клеим деструктивно.
           r.Main_OnCommand(41588, 0) -- glue (если больше одного айтема и не миди айтем, то клей).
           tkfx = 0
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

   for i = 0, number_of_takes-1 do -- take fx check
     local item = r.GetSelectedMediaItem(0, i)
     local take_count = r.CountTakes(item)
     for j = 0, take_count-1 do
       local take = r.GetMediaItemTake(item, j) 
       if r.TakeFX_GetCount(take) > 0 then 
        tkfx = 1
       end
     end
   end

 if number_of_takes ~= 1 and srate ~= nil and tkfx ~= 1 then
     r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то клей, попытка не деструктивно склеить).
end

   collect_itemtake_param()    

 if number_of_takes ~= 1 and srate ~= nil then -- проверяем ещё раз. Если не удалось, клеим деструктивно.
     r.Main_OnCommand(41588, 0) -- glue (если больше одного айтема и не миди айтем, то клей).
     tkfx = 0
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
    local b = 0
    for i = 1, CountSelItem do;
        local item = r.GetSelectedMediaItem(0,i-1);
        local track = r.GetMediaItem_Track(item);
        if not t[tostring(track)]then;
            t[tostring(track)] = track;
            b = b + 1
            tblTrack[b] = track;
        end;
    end;
       
    for iTr = 1, #tblTrack do;
        
        local t = {};
        local rem = {};
        local c = 0
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
                    c = c +1
                    rem[c] = {};
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
   if take == nil then return end
   
   local item = r.GetMediaItemTake_Item(take) -- Get parent item
   if item == nil then return end

   -- Get media source of media item take
   local take_pcm_source = r.GetMediaItemTake_Source(take)
   if take_pcm_source == nil then return end
   
   -- Create take audio accessor
   local aa = r.CreateTakeAudioAccessor(take)
   if aa == nil then return end
   
   -- Get the start time of the audio that can be returned from this accessor
   local aa_start = r.GetAudioAccessorStartTime(aa)
   -- Get the end time of the audio that can be returned from this accessor
   local aa_end = r.GetAudioAccessorEndTime(aa)
   local a_length = (aa_end - aa_start)/25
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
 
   -- How many samples are taken from audio accessor and put in the buffer
   local samples_per_channel = take_source_sample_rate/10
   
   -- Samples are collected to this buffer
   local buffer = r.new_array(samples_per_channel * take_source_num_channels)
   
   local total_samples = (aa_end - aa_start) * (take_source_sample_rate/a_length)
   
   if total_samples < 1 then return end

   local sample_count = 0
   local offs = aa_start
   
   local log10 = function(x) return logx(x, 10) end

   -- Loop through samples
   while sample_count < total_samples do
 
     -- Get a block of samples from the audio accessor.
     -- Samples are extracted immediately pre-FX,
     -- and returned interleaved (first sample of first channel, 
     -- first sample of second channel...). Returns 0 if no audio, 1 if audio, -1 on error.
     local aa_ret =  r.GetAudioAccessorSamples(
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
     
     offs = offs + samples_per_channel / take_source_sample_rate -- new offset in take source (seconds)
   end -- end of while loop
   
   r.DestroyAudioAccessor(aa)
    
   -- Calculate corrections for take/item volume
   adjust_vol = 1
   
   if adj_for_take_vol then
     adjust_vol = adjust_vol * r.GetMediaItemTakeInfo_Value(take, "D_VOL")
     if adjust_vol < 0 then adjust_vol = (adjust_vol * -1) end -- if phase is inverted
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
 
 local getrms = get_average_rms( tk, 0, 0, 0, 0)

 ----------------------------------------------------------------------------------
 
local inf = 1/0

 for i=1, #getrms do
 rms = ceil(getrms[i])
 end

if rms == -inf then rms = -17 end

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
r.PreventUIRefresh(-1); r.Undo_EndBlock('Slicer', -1)

--------------------------------------------------------------------------------
---------------------Retina Check-----------------------------------------------
--------------------------------------------------------------------------------
local retval, dpi = reaper.ThemeLayout_GetLayout("mcp", -3) -- get the current dpi
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
  local zoom_coeff =   (gfx_width/1000)+1
  if zoom_coeff <= 2.044 then zoom_coeff = 2.044 end 
  self.x, self.w = (self.def_xywh[1]* Z_w/zoom_coeff)*2.045, (self.def_xywh[3]* Z_w/zoom_coeff)*2.045-- upd x,w
  self.x = self.x+(zoom_coeff-2.044)*270 -- auto slide to right whem woom
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

function Element:draw_rect_ruler()
  local x,y,w,h  = self.x,self.y,self.w,self.h
  gfx.set(0.122,0.122,0.122,0.3) -- цвет фона окна waveform
  gfx.rect(x, y, w, h, true)            -- frame1      
end

----------------------------------------------------------------------------------------------------
---   Create Element Child Classes(Button,Slider,Knob)   -------------------------------------------
----------------------------------------------------------------------------------------------------
  local Button, Button_small, Button_top, Button_Settings, Slider, Slider_small, Slider_simple, Slider_complex, Slider_Fine, Slider_Swing, Slider_fgain, Rng_Slider, Knob, CheckBox, CheckBox_simple, CheckBox_Show, Frame, Colored_Rect, Colored_Rect_top, Frame_filled, ErrMsg, Txt, Txt2, Line, Line_colored, Line2, Ruler = {},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}
  extended(Button,     Element)
  extended(Button_small,     Element)
  extended(Button_top,     Element)
  extended(Button_Settings,     Element)
  extended(Knob,       Element)
  extended(Slider,     Element)
  extended(Slider_small,     Element)
  extended(Slider_simple,     Element)
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
  extended(Ruler,     Element)
    -- Create Slider Child Classes --
  local H_Slider, V_Slider, T_Slider, HP_Slider, LP_Slider, G_Slider, S_Slider, Rtg_Slider, Loop_Slider, Rdc_Slider, O_Slider, Sw_Slider, Q_Slider, X_Slider, X_SliderOff = {},{},{},{},{},{},{},{},{},{},{},{},{},{},{}
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
if fnt_sz >= 17 then fnt_sz = 17 end
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
if fnt_sz >= 18 then fnt_sz = 18 end
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
    if fnt_sz >= 18 then fnt_sz = 18 end
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

function Ruler:draw()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = (self.def_xywh[1]* Z_w) , (self.def_xywh[3]* Z_w) -- upd x,w
  self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* Z_h) -- upd y,h
  self:draw_rect_ruler()
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
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1) end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0) end
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
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1) end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0) end
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
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1) end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0) end
    return true
end

function Slider_Fine:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.0005 -- Set step
    else
    Mult_S = 0.005 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1) end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0) end
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
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step+0.00001, 1) end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step+0.00001, 0) end
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
    DefaultHP = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultHP'))or 0.3312;
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
    DefaultLP = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultLP'))or 1;
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
    DefaultSens = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultSens'))or 0.375;
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
    DefaultOffset = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultOffset'))or 0.5;
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
    DefaultQStrength = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultQStrength'))or 100;
    if MCtrl then VAL = DefaultQStrength*0.01 end --set default value by Ctrl+LMB
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
    DefaultXFadeTime = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultXFadeTime'))or 15;
    if MCtrl then VAL = DefaultXFadeTime*0.02 end --set default value by Ctrl+LMB
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
if fnt_sz >= 17 then fnt_sz = 17 end
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
if fnt_sz >= 18 then fnt_sz = 18 end
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
if fnt_sz >= 18 then fnt_sz = 18 end
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

function Slider_Fine:draw() -- Offset slider with fine tuning and additional line redrawing
    self:update_xywh() -- Update xywh(if wind changed)
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 12 then fnt_sz = 12 end
if fnt_sz >= 18 then fnt_sz = 18 end
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
if fnt_sz >= 18 then fnt_sz = 18 end
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
if fnt_sz >= 18 then fnt_sz = 18 end
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
if fnt_sz >= 18 then fnt_sz = 18 end
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
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1) end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0) end
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
if fnt_sz >= 18 then fnt_sz = 18 end
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
if fnt_sz >= 18 then fnt_sz = 18 end
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
    if gfx.mouse_wheel > 0 then self.norm_val = self.norm_val-1 end
    if gfx.mouse_wheel < 0 then self.norm_val = self.norm_val+1 end
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
if fnt_sz >= 18 then fnt_sz = 18 end
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
    self:draw_frame()   -- frame
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
if fnt_sz >= 18 then fnt_sz = 18 end
    -- Get mouse state ---------
          -- in element --------
          if self:mouseIN() then a=a+0.2
             if self:set_norm_val_m_wheel() then -- use if need
                if self.onMove then self.onMove() end   
                      MW_doit_checkbox_show()
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
       local item = r.GetMediaItemTake_Item(init_take) -- Get parent item
   if item == nil then
     return
   end

   -- Get media source of media item take
   local take_pcm_source = r.GetMediaItemTake_Source(init_take)
   if take_pcm_source == nil then
     return
   end
   local srate = r.GetMediaSourceSampleRate(take_pcm_source)
end

   if srate then
      if srate < 44100 then srate = 44100 end
      if srate > 48000 then srate = 48000 end
    else
      srate = 44100
   end
end

Init_Srate() -- Project Samplerate

local block_size = 1024*16 -- размер блока(для фильтра и тп) , don't change it!
local time_limit = 5*60    -- limit maximum time, change, if need.
local defPPQ = 960         -- change, if need.
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
local elm_table = {Fltr_Frame, Gate_Frame, Mode_Frame, Mode_Frame_filled, Gate_Frame_filled, Random_Setup_Frame_filled, Random_Setup_Frame, Grid1_Led, Grid2_Led, Grid4_Led, Grid8_Led, Grid16_Led, Grid32_Led, Grid64_Led, GridT_Led, Swing_Led}

elm_table[1] = Frame:new(10, 375+corrY,180,100) --Fltr_Frame
elm_table[2] = Frame:new(200,375+corrY,180,100) --Gate_Frame
elm_table[3] = Frame:new(390,375+corrY,645,100) --Mode_Frame
elm_table[4] = Frame_filled:new(670,380+corrY,191,69,  0.2,0.2,0.2,0.5 ) --Mode_Frame_filled
elm_table[5] = Frame_filled:new(210,380+corrY,160,89,  0.2,0.2,0.2,0.5 ) --Gate_Frame_filled

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

local leds_table = {Frame_byGrid, Frame_byGrid2, Light_Loop_on, Light_Loop_off, Light_Sync_on, Light_Sync_off, Rand_Mode_Color1, Rand_Mode_Color2, Rand_Mode_Color3, Rand_Mode_Color4, Rand_Mode_Color5, Rand_Mode_Color6, Rand_Mode_Color7, Rand_Button_Color1, Rand_Button_Color2, Rand_Button_Color3, Rand_Button_Color4, Rand_Button_Color5, Rand_Button_Color6, Rand_Button_Color7}

leds_table[1] = Colored_Rect:new(591,410+corrY,2,18,  0.1,0.7,0.6,1 ) -- Frame_byGrid (Blue indicator)
leds_table[2] = Colored_Rect:new(591,410+corrY,2,18,  0.7,0.7,0.0,1 ) -- Frame_byGrid2 (Yellow indicator)

leds_table[3] = Colored_Rect_top:new(981,5,2,20,  0.0,0.7,0.0,1 ) -- Light_Loop_on
leds_table[4] = Colored_Rect_top:new(981,5,2,20,  0.5,0.5,0.5,0.5 ) -- Light_Loop_off

leds_table[5] = Colored_Rect_top:new(921,5,2,20,  0.0,0.7,0.0,1 ) -- Light_Sync_on
leds_table[6] = Colored_Rect_top:new(921,5,2,20,  0.5,0.5,0.5,0.5 ) -- Light_Sync_off

leds_table[7] = Colored_Rect:new(675,377+corrY2,2,14,  0.1,0.8,0.2,1 ) --  Rand_Mode_Color1
leds_table[8] = Colored_Rect:new(675,392+corrY2,2,14,  0.7,0.7,0.0,1 ) --  Rand_Mode_Color2
leds_table[9] = Colored_Rect:new(675,407+corrY2,2,14,  0.8,0.4,0.1,1 ) --  Rand_Mode_Color3
leds_table[10] = Colored_Rect:new(675,422+corrY2,2,14,  0.7,0.0,0.0,1 ) --  Rand_Mode_Color4
leds_table[11] = Colored_Rect:new(675,452+corrY2,2,14,  0.2,0.5,1,1 ) --  Rand_Mode_Color5
leds_table[12] = Colored_Rect:new(675,437+corrY2,2,14,  0.8,0.1,0.8,1 ) --  Rand_Mode_Color6
leds_table[13] = Colored_Rect:new(675,467+corrY2,2,14,  0.1,0.7,0.6,1 ) --  Rand_Mode_Color7

leds_table[14] = Colored_Rect:new(598,436,8,2,  0.1,0.8,0.2,1 ) --  Rand_Button_Color1
leds_table[15] = Colored_Rect:new(607,436,9,2,  0.7,0.7,0.0,1 ) --  Rand_Button_Color2
leds_table[16] = Colored_Rect:new(617,436,9,2,  0.8,0.4,0.1,1 ) --  Rand_Button_Color3
leds_table[17] = Colored_Rect:new(627,436,9,2,  0.7,0.0,0.0,1 ) --  Rand_Button_Color4
leds_table[18] = Colored_Rect:new(647,436,9,2,  0.2,0.5,1,1 ) --  Rand_Button_Color5
leds_table[19] = Colored_Rect:new(637,436,9,2,  0.8,0.1,0.8,1 ) --  Rand_Button_Color6
leds_table[20] = Colored_Rect:new(657,436,8,2,  0.1,0.7,0.6,1 ) --  Rand_Button_Color7

local others_table = {Triangle, RandText, Q_Rnd_Linked, Q_Rnd_Linked2, Line, Line2, Loop_Dis, Ruler}

others_table[1] = Txt2:new(642,415+corrY2,55,18, 0.4,0.4,0.4,1, ">","Arial",20) --Triangle
others_table[2] = Txt2:new(749,374+corrY2,55,18, 0.4,0.4,0.4,1, "Intensity","Arial",10) --RandText

others_table[3] = Line_colored:new(482,375+corrY,152,18,  0.7,0.5,0.1,1) --| Q_Rnd_Linked (Bracket)
others_table[4] = Line2:new(480,380+corrY,156,18,  0.177,0.177,0.177,1)--| Q_Rnd_Linked2 (Bracket fill)

others_table[5] = Line:new(774,404+corrY,82,6) --Line (Preset/Velocity Bracket)
others_table[6] = Line2:new(774,407+corrY,82,4,  0.177,0.177,0.177,1)--Line2 (Preset/Velocity Bracket fill)
others_table[7] = Colored_Rect_top:new(10,28,1024,15,  0.23,0.23,0.23,0.5)--Loop_Dis (Loop Disable fill)
others_table[8] = Ruler:new(10,42,1024,13,  0,0,0,0)--Loop_Dis (Loop Disable fill)


local Frame_Sync_TB = {leds_table[5]}
local Frame_Sync_TB2 = {leds_table[6]}
local Frame_Loop_TB = {leds_table[3]}
local Frame_Loop_TB2 = {leds_table[4], others_table[7]}
local Frame_TB = {elm_table[1], elm_table[2], elm_table[3]} 
local FrameR_TB = {others_table[5], others_table[6]}
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

local Rand_Mode_Color1_TB = {leds_table[7]}
local Rand_Mode_Color2_TB = {leds_table[8]}
local Rand_Mode_Color3_TB = {leds_table[9]}
local Rand_Mode_Color4_TB = {leds_table[10]}
local Rand_Mode_Color5_TB = {leds_table[11]}
local Rand_Mode_Color6_TB = {leds_table[12]}
local Rand_Mode_Color7_TB = {leds_table[13]}

local Rand_Button_Color1_TB = {leds_table[14]}
local Rand_Button_Color2_TB = {leds_table[15]}
local Rand_Button_Color3_TB = {leds_table[16]}
local Rand_Button_Color4_TB = {leds_table[17]}
local Rand_Button_Color5_TB = {leds_table[18]}
local Rand_Button_Color6_TB = {leds_table[19]}
local Rand_Button_Color7_TB = {leds_table[20]}

local Triangle_TB = {others_table[1]}
local RandText_TB = {others_table[2]}
local Ruler_TB = {others_table[8]}

local Midi_Sampler = CheckBox_simple:new(670,410+corrY,98,18, 0.28,0.4,0.7,0.8, "","Arial",16,  MIDI_Mode,
                              {"Sampler","Trigger"} )

local Sampler_preset = CheckBox_simple:new(770,410+corrY,90,18, 0.28,0.4,0.7,0.8, "","Arial",16,  Sampler_preset_state,
                              {"Percussive","Melodic"} )

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
  
  if t.selected == nil then t.selected = false end 
  if t.active == nil then t.active = true  end 
  if t.toggleable == nil then t.toggleable = false end
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
  -------------
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%d", self.form_val) .." Hz"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val) -- draw Slider Value
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

-------------------------
local VeloMode = CheckBox_simple:new(770,410+corrY,90,18, 0.28,0.4,0.7,0.8, "","Arial",16,  1, -------velodaw
                              {"Use RMS","Use Peak"} )

VeloMode.onClick = 
function()
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
function Gate_Sldrs_onUp() 
   if Wave.State then Gate_Gl:Apply_toFiltered() end 
end
----------------
Gate_Thresh.onUp    = Gate_Sldrs_onUp
Gate_Sensitivity.onUp = Gate_Sldrs_onUp
Gate_Retrig.onUp    = Gate_Sldrs_onUp

-----------------Offset Slider------------------------ 
local Offset_Sld = O_Slider:new(400,430+corrY,265,18, 0.28,0.4,0.7,0.8, "Offset","Arial",16, Offs_Slider )
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
local QStrength_Sld = Q_Slider:new(400,450+corrY,130,18, 0.28,0.4,0.7,0.8, "QStrength","Arial",16, QuantizeStrength*0.01 )
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
local XFade_Sld = X_Slider:new(532,450+corrY,133,18, 0.28,0.4,0.7,0.8, "XFades","Arial",16, CrossfadeTime*0.02 )
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
local XFade_Sld_Off = X_SliderOff:new(532,450+corrY,133,18, 0.4,0.4,0.4,0.4, "XFades","Arial",16, 0 )
function XFade_Sld_Off:draw_val()
  self.form_val = (self.norm_val)*50       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w+8
  gfx.set(1,1,1,0.2)  -- set body,frame color
  gfx.drawstr('Off')--draw Slider Value
end
XFade_Sld_Off.onUp =
function() 

end


-- RandV_Sld ------------------------------ 
local RandV_Sld = H_Slider:new(737,392+corrY2,75,14, 0.28,0.4,0.7,0.8, "","Arial",16, RandV )
function RandV_Sld:draw_val()
  self.form_val = (self.norm_val)*100       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val).."%"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.y = y+(h-val_h)/2
  gfx.drawstr(val)--draw Slider Value
  RandVval =  floor(RandV_Sld.form_val)
end
RandV_Sld.onUp =
function() 

end
if RandVval == nil then RandVval = RandV*100 end

-- RandPan_Sld ------------------------------ 
local RandPan_Sld = H_Slider:new(737,407+corrY2,75,14, 0.28,0.4,0.7,0.8, "","Arial",16, RandPan )
function RandPan_Sld:draw_val()
  self.form_val = (self.norm_val)*100       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val).."%"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.y = y+(h-val_h)/2
  gfx.drawstr(val)--draw Slider Value
  RandPanval =  floor(RandPan_Sld.form_val)
end
RandPan_Sld.onUp =
function() 

end
if RandPanval == nil then RandPanval = RandPan*100 end

-- RandPtch_Sld ------------------------------ 
local RandPtch_Sld = H_Slider:new(737,422+corrY2,75,14, 0.28,0.4,0.7,0.8, "","Arial",16, RandPtch )
function RandPtch_Sld:draw_val()
  self.form_val = (self.norm_val)*100       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val).."%"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.y = y+(h-val_h)/2
  gfx.drawstr(val)--draw Slider Value
  RandPtchval =  (RandPtch_Sld.form_val/100)*12
end
RandPtch_Sld.onUp =
function() 

end
if RandPtchval == nil then RandPtchval = RandPtch*12 end

-- RandPos_Sld ------------------------------ 
local RandPos_Sld = H_Slider:new(737,437+corrY2,75,14, 0.28,0.4,0.7,0.8, "","Arial",16, RandPos )
function RandPos_Sld:draw_val()
  self.form_val = (self.norm_val)*100       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val).."%"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.y = y+(h-val_h)/2
  gfx.drawstr(val)--draw Slider Value
  RandPosval =  (RandPos_Sld.form_val)
end
RandPos_Sld.onUp =
function() 

end

if RandPosval == nil then RandPosval = RandPos*100 end

-- RandRev_Sld ------------------------------ 
local RandRev_Sld = H_Slider:new(737,452+corrY2,75,14, 0.28,0.4,0.7,0.8, "","Arial",16, RandMute )
function RandRev_Sld:draw_val()
  self.form_val = (self.norm_val)*100       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val).."%"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.y = y+(h-val_h)/2
  gfx.drawstr(val)--draw Slider Value

  revsld =       (logx(RandRev_Sld.form_val+1))*21.63          --(RandRev_Sld.form_val/1.75)+40
  RandRevVal =  ceil(revsld*-1)+100
end
RandRev_Sld.onUp =
function() 

end
if RandRevVal == nil then RandRevVal = RandMute*100 end

-------------------------------------------------------------------------------------
--- Range Slider --------------------------------------------------------------------
-------------------------------------------------------------------------------------
local Gate_VeloScale = Rng_Slider:new(770,430+corrY,90,18, 0.28,0.4,0.7,0.8, "Range","Arial",16, VeloRng, VeloRng2 )---velodaw 
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
       if GridT_on == 1 then
          Guides = 0
          else
          Guides = 1
       end
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
       if GridT_on == 1 then
          Guides = 2
          else
          Guides = 3
       end
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
       if GridT_on == 1 then
          Guides = 4
          else
          Guides = 5
       end
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
       if GridT_on == 1 then
          Guides = 6
          else
          Guides = 7
       end
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
       if GridT_on == 1 then
          Guides = 8
          else
          Guides = 9
       end
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
       if GridT_on == 1 then
          Guides = 10
          else
          Guides = 11
       end
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
       if GridT_on == 1 then
          Guides = 12
          else
          Guides = 12
       end
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
   end 
end

----------------------------------------------------------------------------------
----------------------Notes CheckBox---------------------------------------------
----------------------------------------------------------------------------------
Trigger_Oct_Shift = tonumber(r.GetExtState('cool_MK Slicer.lua','Trigger_Oct_Shift'))or 0;
octa = Trigger_Oct_Shift+1
note = 23+(octa*12)

local OutNote  = CheckBox_simple:new(670,430+corrY,98,18, 0.28,0.4,0.7,0.8, "","Arial",16,  OutNote_State,
                              {
                                   "B" .. Compensate_Oct_Offset+octa .. ": " .. note, 
                                   "C" .. Compensate_Oct_Offset+octa+1 .. ": " .. note+1, 
                                   "C#" .. Compensate_Oct_Offset+octa+1 .. ": " .. note+2, 
                                   "D" .. Compensate_Oct_Offset+octa+1 .. ": " .. note+3, 
                                   "D#" .. Compensate_Oct_Offset+octa+1 .. ": " .. note+4, 
                                   "E" .. Compensate_Oct_Offset+octa+1 .. ": " .. note+5,
                                   "F" .. Compensate_Oct_Offset+octa+1 .. ": " .. note+6, 
                                   "F#" .. Compensate_Oct_Offset+octa+1 .. ": " .. note+7, 
                                   "G" .. Compensate_Oct_Offset+octa+1 .. ": " .. note+8, 
                                   "G#" .. Compensate_Oct_Offset+octa+1 .. ": " .. note+9,
                                   "A" .. Compensate_Oct_Offset+octa+1 .. ": " .. note+10, 
                                   "A#" .. Compensate_Oct_Offset+octa+1 .. ": " .. note+11, 
                                   "B" .. Compensate_Oct_Offset+octa+1 .. ": " .. note+12, 
                                   "C" .. Compensate_Oct_Offset+octa+2 .. ": " .. note+13, 
                                   "C#" .. Compensate_Oct_Offset+octa+2 .. ": " .. note+14, 
                                   "D" .. Compensate_Oct_Offset+octa+2 .. ": " .. note+15} 
                              )

local OutNote2  = CheckBox_simple:new(670,430+corrY,98,18, 0.28,0.4,0.7,0.8, "","Arial",16,  OutNote_State, -- named notes
                              {
                                   "B" .. Compensate_Oct_Offset+octa .. ":Kick1", 
                                   "C" .. Compensate_Oct_Offset+octa+1 .. ":Kick2", 
                                   "C#" .. Compensate_Oct_Offset+octa+1 .. ":SStick", 
                                   "D" .. Compensate_Oct_Offset+octa+1 .. ":Snare1", 
                                   "D#" .. Compensate_Oct_Offset+octa+1 .. ":Clap", 
                                   "E" .. Compensate_Oct_Offset+octa+1 .. ":Snare2",
                                   "F" .. Compensate_Oct_Offset+octa+1 .. ":FloorTom1", 
                                   "F#" .. Compensate_Oct_Offset+octa+1 .. ":HClosed", 
                                   "G" .. Compensate_Oct_Offset+octa+1 .. ":FloorTom2", 
                                   "G#" .. Compensate_Oct_Offset+octa+1 .. ":HPedal",
                                   "A" .. Compensate_Oct_Offset+octa+1 .. ":LowTom", 
                                   "A#" .. Compensate_Oct_Offset+octa+1 .. ":HOpen", 
                                   "B" .. Compensate_Oct_Offset+octa+1 .. ":MidTom", 
                                   "C" .. Compensate_Oct_Offset+octa+2 .. ":HighTom1", 
                                   "C#" .. Compensate_Oct_Offset+octa+2 .. ":Crash", 
                                   "D" .. Compensate_Oct_Offset+octa+2 .. ":HighTom2"} 
                              )

-------------------------

local Velocity = Txt:new(788,384+corrY,55,18, 0.8,0.8,0.8,0.8, "Velocity","Arial",22)
----------------------------------------

local Slider_TB = {HP_Freq,LP_Freq,Fltr_Gain, 
                   Gate_Thresh,Gate_Sensitivity,Gate_Retrig,Gate_ReducePoints,Offset_Sld,QStrength_Sld,Project}

local Sliders_Grid_TB = {Grid1_Btn, Grid2_Btn, Grid4_Btn, Grid8_Btn, Grid16_Btn, Grid32_Btn, Grid64_Btn, GridT_Btn}

local Slider_Swing_TB = {Swing_Sld}

local Slider_TB_Trigger = {Gate_VeloScale, VeloMode,OutNote, Velocity}

local Slider_TB_Trigger_notes = {Gate_VeloScale, VeloMode,OutNote2, Velocity}

local XFade_TB = {XFade_Sld}
local XFade_TB_Off = {XFade_Sld_Off}

local SliderRandV_TB = {RandV_Sld}
local SliderRandPan_TB = {RandPan_Sld}
local SliderRandPtch_TB = {RandPtch_Sld}
local SliderRand_TBPos = {RandPos_Sld}
local SliderRand_TBM = {RandRev_Sld}

local Preset = Txt:new(788,384+corrY,55,18, 0.8,0.8,0.8,0.8, "Preset","Arial",22)

local Preset_TB = {Preset} 

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
local Get_Sel_Button = Button:new(20,380+corrY,160,25, 0.3,0.3,0.3,1, "Get Item",    "Arial",16 )
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
Random_Status = 0
SliceQ_Status_Rand = 0

 loopcheck = 0
----loopcheck------
local loopcheckstart, loopcheckending = r.GetSet_LoopTimeRange( 0, true, 0, 0, 0 )
if loopcheckstart == loopcheckending and loopcheckstart and loopcheckending then 
     loopcheck = 0
       else
     loopcheck = 1
end

    r.Undo_BeginBlock() 
r.PreventUIRefresh(1)

-------------------------------Check Razor Edits-----------------------------
function GetItemsInRange(track, areaStart, areaEnd)
    local items = {}
    local itemCount = r.CountTrackMediaItems(track)
    for k = 0, itemCount - 1 do 
        local item = r.GetTrackMediaItem(track, k)
        local pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = r.GetMediaItemInfo_Value(item, "D_LENGTH")
        local itemEndPos = pos+length
        if (itemEndPos > areaStart and itemEndPos <= areaEnd) or          --check if item is in area bounds
            (pos >= areaStart and pos < areaEnd) or
            (pos <= areaStart and itemEndPos >= areaEnd) then
                table.insert(items,item)
        end
    end
    return items
end

function SetTrackRazorEdit(track, areaStart, areaEnd, clearSelection)
    if clearSelection == nil then clearSelection = false end   
    if clearSelection then
        local ret, area = r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)   
        local str = {}  --parse string, all this string stuff could probably be written better
        for j in string.gmatch(area, "%S+") do table.insert(str, j) end       
        local j = 1   --strip existing selections across the track
        while j <= #str do
            local GUID = str[j+2]
            if GUID == '""' then 
                str[j] = ''
                str[j+1] = ''
                str[j+2] = ''
            end
            j = j + 3
        end
        --insert razor edit 
        local REstr = tostring(areaStart) .. ' ' .. tostring(areaEnd) .. ' ""'
        table.insert(str, REstr)
        local finalStr = ''
        for i = 1, #str do
            local space = i == 1 and '' or ' '
            finalStr = finalStr .. space .. str[i]
        end
        local ret, area = r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', finalStr, true)
        return ret
    else         
        local ret, area = r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
        local str = area ~= nil and area .. ' ' or ''
        str = str .. tostring(areaStart) .. ' ' .. tostring(areaEnd) .. '  ""'       
        local ret, area = r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', str, true)
        return ret
    end
end

function GetRazorEdits()
    local trackCount = r.CountTracks(0)
    local areaMap = {}
    for i = 0, trackCount - 1 do
        local track = r.GetTrack(0, i)
        local ret, area = r.GetSetMediaTrackInfo_String(track, 'P_RAZOREDITS', '', false)
        if area ~= '' then
            --PARSE STRING
            local str = {}
            for j in string.gmatch(area, "%S+") do
                table.insert(str, j)
            end       
            --FILL AREA DATA
            local j = 1
            while j <= #str do
                local areaStart = tonumber(str[j])        --area data
                local areaEnd = tonumber(str[j+1]) 
                local items = {}  --get item data
                items = GetItemsInRange(track, areaStart, areaEnd)
                  r.SetTrackSelected(track, true) -- Set Track Selected
                local areaData = {
                    areaStart = areaStart,
                    areaEnd = areaEnd,                
                    track = track,
                    items = items,                   
                }
                table.insert(areaMap, areaData)
                j = j + 3
            end
        end
    end
    return areaMap
end

function SplitRazorEdits(razorEdits)
left, right = huge, -huge
    local areaItems = {}
    local tracks = {}
    for i = 1, #razorEdits do
        local areaData = razorEdits[i]
        if not areaData.isEnvelope then
            local items = areaData.items           
            if tracks[areaData.track] ~= nil then  --recalculate item data for tracks with previous splits
                items = GetItemsInRange(areaData.track, areaData.areaStart, areaData.areaEnd)
            end            
            for j = 1, #items do 
                local item = items[j]        
                 if areaData.areaStart  < left  then left  = areaData.areaStart end  --combine areas and set time selection
                 if areaData.areaEnd > right then right = areaData.areaEnd end
                 if left <= right then
                      r.GetSet_LoopTimeRange2(0, true, false, left, right, false)
                      table.insert(areaItems, item)
                 end
            end
            tracks[areaData.track] = 1
        end
    end
    return areaItems
end

 -- Unselect All Tracks if RE exist --
    for i = 0, r.CountTracks(0) - 1 do
        local _, check_area = r.GetSetMediaTrackInfo_String(r.GetTrack(0, i), 'P_RAZOREDITS', '', false)
        if check_area ~= '' then
                r.Main_OnCommand(40297, 0) -- Unselect all tracks
                RE_Status = 1
        end
    end

 -- Select Items by RE --
local selections = GetRazorEdits()
local items = SplitRazorEdits(selections)
for i = 1, #items do
    local item = items[i]
    r.SetMediaItemSelected(item, true)
end

take_check()
sel_tr_count = r.CountSelectedTracks(0)
  if sel_tr_count == 1 then
        r.Main_OnCommand(42406, 0) -- Clear RE Areas
     local    start, ending = r.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
           if start ~= ending and Take_Check ~= 1 then
               r.Main_OnCommand(40061, 0) -- Split at Time Selection
               r.Main_OnCommand(40635, 0) -- Remove Time Selection
           end
    elseif sel_tr_count > 1 then
 goto next_step
    elseif sel_tr_count ==0 then
  end

function re_createRE()
    local itemCount = r.CountSelectedMediaItems(0) -- re-create deleted RE
    for i = 0, itemCount - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        local track = r.GetMediaItem_Track(item)      
        local itemStartPosition = r.GetMediaItemInfo_Value(item, 'D_POSITION')
        local itemLength = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
        local itemEndPosition = itemStartPosition + itemLength
        SetTrackRazorEdit(track, itemStartPosition, itemEndPosition, false)
    end
end


function deferinit() -- continuous selection items in RE
for t = 0, reaper.CountTracks(0)-1 do
    local track = reaper.GetTrack(0, t)
    local tR = {}
    local razorOK, razorStr = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    if razorOK and #razorStr ~= 0 then
        for razorLeft, razorRight, envGuid in razorStr:gmatch([[([%d%.]+) ([%d%.]+) "([^"]*)"]]) do
            if envGuid == "" then
                local razorLeft, razorRight = tonumber(razorLeft), tonumber(razorRight)
                table.insert(tR, {left = razorLeft, right = razorRight})
            end
        end
    end
    for i = 0, reaper.CountTrackMediaItems(track)-1 do
        local item = reaper.GetTrackMediaItem(track, i)
        reaper.SetMediaItemSelected(item, false)
        local left = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local right = left + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        for _, r in ipairs(tR) do
            if left < r.right and right > r.left then
                reaper.SetMediaItemSelected(item, true)
            end
        end
    end
end
reaper.UpdateArrange()
      if char~=-1 then r.defer(deferinit)  else end     -- defer     r.defer(deferinit)
end


        if RE_Status == 1 then
             re_createRE()
             deferinit()
        end
::next_step::
---------------------------------------End of RE_Splits----------------------------------------

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
local start, ending = r.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
time_sel_length = ending - start
if ObeyingTheSelection == 1 and ObeyingItemSelection == 0 and start ~= ending then
    r.Main_OnCommand(40289, 0) -- Item: Unselect all items
          if time_sel_length >= 0.25 and selected_tracks_count == 1 then
              r.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
          end
end

count_itms =  r.CountSelectedMediaItems(0)
if ObeyingTheSelection == 1 and count_itms ~= 0 and start ~= ending and time_sel_length >= 0.25 then
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

   for i = 0, number_of_takes-1 do -- take fx check
     local item = r.GetSelectedMediaItem(0, i)
     local take_count = r.CountTakes(item)
     for j = 0, take_count-1 do
       local take = r.GetMediaItemTake(item, j) 
       if r.TakeFX_GetCount(take) > 0 then 
        tkfx = 1
       end
     end
   end

       if number_of_takes ~= 1 and srate ~= nil and tkfx ~= 1 and Random_Status ~= 1 then
           r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то клей, попытка не деструктивно склеить).
        end
       collect_param()    
       if number_of_takes ~= 1 and srate ~= nil then -- проверяем ещё раз. Если не удалось, клеим деструктивно.
           r.Main_OnCommand(41588, 0) -- glue (если больше одного айтема и не миди айтем, то клей).
       tkfx = 0
       end
   end
end
-----------------------------------------------------------------------------------------------------
if ObeyingTheSelection == 1 and time_sel_length < 0.25 and ending ~= start then
------------------------------------------Error Message-----------------------------------------
local timer = 2 -- Time in seconds
local time = reaper.time_precise()
local function Msg()
   local char = gfx.getchar()
     if char == 27 or char == -1 or (reaper.time_precise() - time) > timer then ErrMsg_Ststus = 0 return end
local Get_Sel_ErrMsg = ErrMsg:new(680,450+corrY,260,25, 1, 1, 1, 1, "Time Selection is Too Short (<0.25s)",    "Arial", 22)
local ErrMsg_TB = {Get_Sel_ErrMsg}
ErrMsg_Ststus = 1
     for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
   gfx.update()
  r.defer(Msg)
end
end
Msg()
--------------------------------------End of Error Message-------------------------------------
Init()
 goto zzz
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

if  Take_Check == 1 then  

------------------------------------Error Message----------------------------------------------

local timer = 2 -- Time in seconds
local time = reaper.time_precise()
local function Msg()
   local char = gfx.getchar()
     if char == 27 or char == -1 or (reaper.time_precise() - time) > timer then ErrMsg_Ststus = 0 return end
local Get_Sel_ErrMsg = ErrMsg:new(680,450+corrY,260,25, 1, 1, 1, 1, "Only Wave items, please",    "Arial", 22)
local ErrMsg_TB = {Get_Sel_ErrMsg}
ErrMsg_Ststus = 1
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

   for i = 0, number_of_takes-1 do -- take fx check
     local item = r.GetSelectedMediaItem(0, i)
     local take_count = r.CountTakes(item)
     for j = 0, take_count-1 do
       local take = r.GetMediaItemTake(item, j) 
       if r.TakeFX_GetCount(take) > 0 then 
        tkfx = 1
       end
     end
   end

 if number_of_takes ~= 1 and Take_Check == 0 and tkfx ~= 1 and Random_Status ~= 1 then
     r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то клей, попытка не деструктивно склеить).
 end

   collect_itemtake_param()

  if selected_tracks_count == 1 and number_of_takes > 1 and Take_Check == 0 then 
     r.Main_OnCommand(41588, 0) -- glue (если больше одного айтема, то клей).
     tkfx = 0
  end

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
--      Wave:Reset_All() --Reset item to Init before the "Get Item"
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

-- Create Just Slice  Button ----------------------------
local Just_Slice = Button:new(400,380+corrY,67,25, 0.3,0.3,0.3,1, "Slice",    "Arial",16 )
Just_Slice.onClick = 
function()
   if Wave.State then Wave:Just_Slice() end 
end 

-- Create Quantize Slices Button ----------------------------
local Quantize_Slices = Button:new(469,380+corrY,25,25, 0.3,0.3,0.3,1, "Q",    "Arial",16 )
Quantize_Slices.onClick = 
function()
   if Wave.State then Wave:Quantize_Slices() end 
end 

-- Create Add Markers Button ----------------------------
local Add_Markers = Button:new(499,380+corrY,67,25, 0.3,0.3,0.3,1, "Markers",    "Arial",16 )
Add_Markers.onClick = 
function()
   if Wave.State then Wave:Add_Markers() end 
end 

-- Create Quantize Markers Button ----------------------------
local Quantize_Markers = Button:new(568,380+corrY,25,25, 0.3,0.3,0.3,1, "Q",    "Arial",16 )
Quantize_Markers.onClick = 
function()
   if Wave.State then Wave:Quantize_Markers() end 
end 

----------------------------------------------------
--------------RANDOMIZE-----------------------
----------------------------------------------------
function Randomizer()

    if Random_Order == 1 then
        r.Main_OnCommand(41638, 0)  -- Random Order  
    end

math.randomseed(r.time_precise()*os.time()/1e3)
local t = {}
local sel_items = {}
local function SaveSelItems()
  for i = 0, r.CountSelectedMediaItems(0)-1 do
    sel_items[i+1] = r.GetSelectedMediaItem(0, i)
  end
end

local function RestoreSelItems()
  r.SelectAllMediaItems(0, 0) -- unselect all items
  for _, item in ipairs(sel_items) do
    if item then r.SetMediaItemSelected(item, 1) end
  end
end

function swap(array, index1, index2)
  array[index1], array[index2] = array[index2], array[index1]
end

function shuffle(array)
  local counter = #array
  while counter > 1 do
    local index = random(counter)
    swap(array, index, counter)
    counter = counter - 1
  end
end

function random_numbers_less_than(x)
  local t, t_res = {},{}
  local e = 0
  local d = 0
  for i = 1, x do 
     e = e + 1
     t[e] = i 
  end
  shuffle(t)
  local max = floor(x/((RandRevVal/10)+1))
  for i = 1, max do 
    d = d + 1
    t_res[d] = t[i] 
  end
  return t_res
end

local items = r.CountSelectedMediaItems()
if items == 0 then return end

for i = 0, items - 1 do --RANDOMIZE PAN AND PITCH and other
    item = r.GetSelectedMediaItem(0, i)

       if item then
                  item_take = r.GetActiveTake(item)
        
                  if Random_Pan == 1 then
                      local random_pan = random()*(RandPanval/50) - (RandPanval/100)
                      r.SetMediaItemTakeInfo_Value(item_take, 'D_PAN', random_pan)
                  end
        
                  if Random_Vol == 1 then
                   local random_vol = (random()*(RandVval/100))+(1/(RandVval/2)) -- +0.1
                    if RandVval <= 2 then random_vol = 1 end
                    if RandVval >= 3 and RandVval <= 10 then random_vol = (random_vol+0.45) end
                    if RandVval >= 11 and RandVval <= 45 then random_vol = (random_vol+0.55) end
                    if RandVval >= 46 and RandVval <= 70 then random_vol = (random_vol+0.4) end
                    if RandVval >= 71 and RandVval <= 80 then random_vol = (random_vol+0.2) end
                    if RandVval >= 81 and RandVval <= 100 then random_vol = (random_vol+0.1) end
                   r.SetMediaItemTakeInfo_Value(item_take, 'D_VOL', random_vol)
                  end

                  if Random_Pitch == 1 then
                     local random_polarity = random()*2 - 1
                     local random_pitch
                     local random_pitch2                   
                                 if RandPtchval <= 1.3 then --slider = 10
                                    random_pitch = random() * (RandPtchval*random_polarity) -- by cents
                                    else
                                    random_pitch = ceil(random() * (RandPtchval*random_polarity)) -- by semitones
                                 end

                              if RandPtchval >= 10.7 then  ----- by intervals,  slider = 90
                                    if random_pitch == 0  then random_pitch2 = 0 end
                                
                                    if random_pitch >= 1 and random_pitch <= 2  then random_pitch2 = 3 end
                                    if random_pitch >= 3 and random_pitch <= 4 then random_pitch2 = 5 end
                                    if random_pitch >= 5 and random_pitch <= 7 then random_pitch2 = 7 end
                                    if random_pitch >= 8 and random_pitch <= 12 then random_pitch2 = 12 end
                                    
                                    if random_pitch <= -1 and random_pitch >= -2  then random_pitch2 = -3 end
                                    if random_pitch <= -3 and random_pitch >= -4 then random_pitch2 = -5 end
                                    if random_pitch <= -5 and random_pitch >= -7 then random_pitch2 = -7 end
                                    if random_pitch <= -8 and random_pitch >= -12 then random_pitch2 = -12 end
                                 else
                                    random_pitch2 = random_pitch
                              end

                     r.SetMediaItemTakeInfo_Value(item_take, 'D_PITCH', random_pitch2)
                 end

     end
end

for i = 1, items - 1 do --RANDOMIZE Position instead first item
    item = r.GetSelectedMediaItem(0, i)
       if item then
                  item_take = r.GetActiveTake(item)   
                  if Random_Position == 1 then
                      local random_position = random(ceil((RandPosval/10)+1))-1
                      local random_polarity2 = random()*2 - 1
                      local it_start = r.GetMediaItemInfo_Value(item, "D_POSITION")
                      local tempo_corr = 1/(r.Master_GetTempo()/120)
                      local random_pos = it_start+((random_position/300)*random_polarity2)*tempo_corr
                      r.SetMediaItemInfo_Value(item, "D_POSITION", random_pos)
                 end
     end
end

SaveSelItems()
local f = 0
for i = 0, items-1 do
  local it = r.GetSelectedMediaItem(0,i)
  f = f + 1
  t[f] = it
end

local t_nums = random_numbers_less_than(items)

r.Undo_BeginBlock(); r.PreventUIRefresh(1)

r.SelectAllMediaItems(0, 0) -- unselect all items
for i = 1, #t_nums-1 do
  local it = t[t_nums[i]]
  if it and IsEven(i) == true then
     r.SetMediaItemSelected(it,1)
  end
end
        if Random_Reverse == 1 then
             r.Main_OnCommand(41051,0) --Item properties: Toggle take reverse
        end

RestoreSelItems()

----------------------------------------------------------------------------------------
local t = {}
local sel_items = {}
local function SaveSelItems()
  for i = 0, r.CountSelectedMediaItems(0)-1 do
    sel_items[i+1] = r.GetSelectedMediaItem(0, i)
  end
end

local function RestoreSelItems()
  r.SelectAllMediaItems(0, 0) -- unselect all items
  for _, item in ipairs(sel_items) do
    if item then r.SetMediaItemSelected(item, 1) end
  end
end

function swap(array, index1, index2)
  array[index1], array[index2] = array[index2], array[index1]
end

function shuffle(array)
  local counter = #array
  while counter > 1 do
    local index = random(counter)
    swap(array, index, counter)
    counter = counter - 1
  end
end

function random_numbers_less_than(x)
  local t, t_res = {},{}
  local e = 0
  local d = 0
  for i = 1, x do 
     e = e + 1
     t[e] = i 
  end
  shuffle(t)
  local max = (x)
  for i = 1, max do 
    d = d + 1
    t_res[d] = t[i] 
  end
  return t_res
end

local items = r.CountSelectedMediaItems()
if items == 0 then return end

SaveSelItems()
local f = 0
for i = 0, items-1 do
  local it = r.GetSelectedMediaItem(0,i)
  f = f + 1
  t[f] = it
end

local t_nums = random_numbers_less_than(items)


r.SelectAllMediaItems(0, 0) -- unselect all items
for i = 1, #t_nums-1 do
  local it = t[t_nums[i]]
  if it and IsEven(i) == true then
     r.SetMediaItemSelected(it,1)
  end
end
        if Random_Mute == 1 then
            r.Main_OnCommand(40719,0) -- Item properties: Mute
        end

RestoreSelItems()
----------------------------------------------------------------------------------------------

        if Random_Position == 1 then
            r.Main_OnCommand(r.NamedCommandLookup("_SWS_AWFILLGAPSQUICK"),0) -- fill gaps 
        end

r.PreventUIRefresh(-1); r.Undo_EndBlock('Random', -1)

end


-- Random_Setup Button ----------------------------
local Random_SetupB = Button_small:new(598,410+corrY,67,15, 0.3,0.3,0.3,1, "Rnd.Set",    "Arial",16 )
Random_SetupB.onClick = 
function()
     if Random_Setup ~= 1 then
            Random_Setup = 1 
        else
            Random_Setup = 0 
     end
end

-- Random_Clear Button ----------------------------
local Random_SetupClearB = Button_small:new(772,467+corrY2,40,14, 0.3,0.3,0.3,1, "Clear",    "Arial",16 )
Random_SetupClearB.onClick = 
function()
Random_Order = 1 
Random_Vol = 0 
Random_Pan = 0 
Random_Pitch = 0
Random_Position = 0
Random_Mute = 0 
Random_Reverse = 0
r.SetExtState('cool_MK Slicer.lua','Random_Order',Random_Order,true);
r.SetExtState('cool_MK Slicer.lua','Random_Vol',Random_Vol,true);
r.SetExtState('cool_MK Slicer.lua','Random_Pan',Random_Pan,true);
r.SetExtState('cool_MK Slicer.lua','Random_Pitch',Random_Pitch,true);
r.SetExtState('cool_MK Slicer.lua','Random_Position',Random_Position,true);
r.SetExtState('cool_MK Slicer.lua','Random_Position',Random_Position,true);
r.SetExtState('cool_MK Slicer.lua','Random_Mute',Random_Mute,true);
r.SetExtState('cool_MK Slicer.lua','Random_Reverse',Random_Reverse,true);
end

-- Random_Order Button ----------------------------
local Random_OrderB = Button_small:new(675,377+corrY2,60,14, 0.3,0.3,0.3,1, "Order",    "Arial",5 )
Random_OrderB.onClick = 
function()
     if Random_Order ~= 1 then
            Random_Order = 1 
        else
            Random_Order = 0 
     end
          r.SetExtState('cool_MK Slicer.lua','Random_Order',Random_Order,true);
end

-- Random_Vol Button ----------------------------
local Random_VolB = Button_small:new(675,392+corrY2,60,14, 0.3,0.3,0.3,1, "Volume",    "Arial",5 )
Random_VolB.onClick = 
function()
     if Random_Vol ~= 1 then
            Random_Vol = 1 
        else
            Random_Vol = 0 
     end
          r.SetExtState('cool_MK Slicer.lua','Random_Vol',Random_Vol,true);
end

-- Random_Pan Button ----------------------------
local Random_PanB = Button_small:new(675,407+corrY2,60,14, 0.3,0.3,0.3,1, "Pan",    "Arial",5 )
Random_PanB.onClick = 
function()
     if Random_Pan ~= 1 then
            Random_Pan = 1 
        else
            Random_Pan = 0 
     end
          r.SetExtState('cool_MK Slicer.lua','Random_Pan',Random_Pan,true);
end

-- Random_Pitch Button ----------------------------
local Random_PitchB = Button_small:new(675,422+corrY2,60,14, 0.3,0.3,0.3,1, "Pitch",    "Arial",5 )
Random_PitchB.onClick = 
function()
     if Random_Pitch ~= 1 then
            Random_Pitch = 1 
        else
            Random_Pitch = 0 
     end
          r.SetExtState('cool_MK Slicer.lua','Random_Pitch',Random_Pitch,true);
end

-- Random_Position Button ----------------------------
local Random_PositionB = Button_small:new(675,437+corrY2,60,14, 0.3,0.3,0.3,1, "Position",    "Arial",5 )
Random_PositionB.onClick = 
function()
     if Random_Position ~= 1 then
            Random_Position = 1 
        else
            Random_Position = 0 
     end
          r.SetExtState('cool_MK Slicer.lua','Random_Position',Random_Position,true);
end

-- Random_Reverse Button ----------------------------
local Random_ReverseB = Button_small:new(675,452+corrY2,60,14, 0.3,0.3,0.3,1, "Reverse",    "Arial",5 )
Random_ReverseB.onClick = 
function()
     if Random_Reverse ~= 1 then
            Random_Reverse = 1 
        else
            Random_Reverse = 0 
     end
          r.SetExtState('cool_MK Slicer.lua','Random_Reverse',Random_Reverse,true);
end

-- Random_Mute Button ----------------------------
local Random_MuteB = Button_small:new(675,467+corrY2,60,14, 0.3,0.3,0.3,1, "Mute",    "Arial",5 )
Random_MuteB.onClick = 
function()
     if Random_Mute ~= 1 then
            Random_Mute = 1 
        else
            Random_Mute = 0 
     end
          r.SetExtState('cool_MK Slicer.lua','Random_Mute',Random_Mute,true);
end

-- Random Button ----------------------------

local Random = Button:new(598,380+corrY,67,25, 0.3,0.3,0.3,1, "Random",    "Arial",16 ) 
Random.onClick = 
function()
if Wave.State then 
    if Random_Order ~= 1 and Random_Reverse ~= 1 and Random_Mute ~= 1 and Random_Position ~= 1 and Random_Pitch ~= 1 and Random_Pan ~= 1 and Random_Vol ~= 1 then 
      
        ------------------------------------------Error Message-----------------------------------------        
         local timer = 2 -- Time in seconds
         local time = reaper.time_precise()
         local function Msg()
            local char = gfx.getchar()
              if char == 27 or char == -1 or (reaper.time_precise() - time) > timer then ErrMsg_Ststus = 0 return end
         local Get_Sel_ErrMsg = ErrMsg:new(680,450+corrY,260,25, 1, 1, 1, 1, "Select at least one option in Rnd.Set",    "Arial", 22)
         local ErrMsg_TB = {Get_Sel_ErrMsg}
         ErrMsg_Ststus = 1
              for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
            gfx.update()
           r.defer(Msg)
         end
         end
         Msg()
         --------------------------------------End of Error Message------------------------------------  
         Init()

         return 
    end
Wave:Random() end 
end

function Wave:Random()
     r.PreventUIRefresh(1)
if Random_Status == 1 then  Wave:Reset_All()  end

     Wave:Just_Slice()

  r.Undo_BeginBlock() 

if Random_Status == 0 then 
      Randomizer()
      Random_Status = 1
   else
      r.Main_OnCommand(40029, 0)  -- Undo
      Randomizer()
end

if XFadeOff == 0 then

--  r.Main_OnCommand(r.NamedCommandLookup("_SWS_AWFILLGAPSQUICK"),0) -- fill gaps 

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

  r.Undo_EndBlock("Random", -1) 
r.PreventUIRefresh(-1)
    if SliceQ_Status_Rand == 1 then
       Wave:Quantize_Slices()
    end
end

-- Reset All Button ----------------------------
local Reset_All = Button:new(970,445+corrY,55,25, 0.3,0.3,0.3,1, "Reset",    "Arial",16 )
Reset_All.onClick = 
function()
   if Wave.State then 
       Wave:Reset_All() 
       SliceQ_Status_Rand = 0
   end 
end

-- Create Midi Button ----------------------------
local Create_MIDI = Button:new(670,380+corrY,98,25, 0.3,0.3,0.3,1, "MIDI",    "Arial",16 )
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

--------------------------------------End of Error Message1-------------------------------------------
Init()

  M_Check = 1

  return

  end -- не запускать, если мультитрек.

take_check()

if  Take_Check == 1 then  

------------------------------------Error Message2----------------------------------------------

local timer = 2 -- Time in seconds
local time = reaper.time_precise()
local function Msg()
   local char = gfx.getchar()
     if char == 27 or char == -1 or (reaper.time_precise() - time) > timer then ErrMsg_Ststus = 0 return end
local Get_Sel_ErrMsg = ErrMsg:new(680,450+corrY,260,25, 1, 1, 1, 1, "Only Wave items, please",    "Arial", 22)
local ErrMsg_TB = {Get_Sel_ErrMsg}
ErrMsg_Ststus = 1
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

   for i = 0, number_of_takes-1 do -- take fx check
     local item = r.GetSelectedMediaItem(0, i)
     local take_count = r.CountTakes(item)
     for j = 0, take_count-1 do
       local take = r.GetMediaItemTake(item, j) 
       if r.TakeFX_GetCount(take) > 0 then 
        tkfx = 1
       end
     end
   end

    if number_of_takes ~= 1 and tkfx ~= 1 then
         Heal_protection()
   end

pitch_and_rate_check()

   if take_pitch ~= 0 or take_playrate ~= 1.0 or number_of_takes ~= 1 then
         Glue_protection()
         tkfx = 0
  end


  if (Midi_Sampler.norm_val == 1) then  

  Midi_sampler_offs_stat = 1
  Wave:Create_Track_Accessor() 
  Wave:Just_Slice()   
  Wave:Load_To_Sampler() 

  Wave.State = false -- reset Wave.State

      r.Undo_EndBlock("Create MIDI", -1) 

  else
              MIDITrigger()

  end

  end 
  end
end
----------------------------------------
--- Button_TB --------------------------
----------------------------------------
local Loop_TB = {LoopScale}
local LoopBtn_TB = {Loop_Btn, Sync_Btn, Swing_Btn}

local Checkbox_TB_preset = {Sampler_preset}

local Button_TB = {Get_Sel_Button, Settings, Just_Slice, Quantize_Slices, Add_Markers, Quantize_Markers, Random, Reset_All, Random_SetupB}
local Button_TB2 = {Create_MIDI, Midi_Sampler}
local Random_Setup_TB2 = {elm_table[6], elm_table[7], Random_OrderB, Random_VolB, Random_PitchB, Random_PanB, Random_MuteB, Random_PositionB, Random_ReverseB, Random_SetupClearB}
 
-------------------------------------------------------------------------------------
--- CheckBoxes ---------------------------------------------------------------------
-------------------------------------------------------------------------------------

local Guides  = CheckBox:new(400,410+corrY,193,18, 0.28,0.4,0.7,0.8, "","Arial",16,  Guides_mode,
                              {"Guides By Transients","Guides By Grid"} )

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
local ViewMode = CheckBox_Show:new(970,380+corrY,55,18,  0.28,0.4,0.7,0.8, "Show: ","Arial",16,  1,
                              { "All", "Original", "Filtered" } )
ViewMode.onClick = 
function() 
   if Wave.State then Wave:Redraw() end 
end

-----------------------------------
--- CheckBox_TB -------------------
-----------------------------------
local CheckBox_TB = {ViewMode, Guides}

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
function DrawGridGuides()
 
local lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')
     
     local item =  r.BR_GetMediaItemByGUID( 0, lastitem )
                if item then 
-------------------------------SAVE GRID-----------------------------
--local _, division, swingmode, swingamt = r.GetSetProjectGrid(0, 0)

--local ext_sec, ext_key = 'savegrid', 'grid'
--r.SetExtState(ext_sec, ext_key, division..','..swingmode..','..swingamt, 0)
---------------------------SET NEWGRID-------------------------------------
if  Guides.norm_val == 2 then  
--[[
     if Guides == 0 then r.Main_OnCommand(40781, 0) --1
          elseif Guides == 1 then r.Main_OnCommand(42007, 0)
          elseif Guides == 2 then r.Main_OnCommand(40780, 0) --2
          elseif Guides == 3 then r.Main_OnCommand(42000, 0)
          elseif Guides == 4 then r.Main_OnCommand(40779, 0) -- 4
          elseif Guides == 5 then r.Main_OnCommand(41214, 0)  
          elseif Guides == 6 then r.Main_OnCommand(40778, 0) --8 
          elseif Guides == 7 then r.Main_OnCommand(40777, 0)
          elseif Guides == 8 then r.Main_OnCommand(40776, 0) --16
          elseif Guides == 9 then r.Main_OnCommand(41213, 0)
          elseif Guides == 10 then r.Main_OnCommand(40775, 0)-- 32
          elseif Guides == 11 then r.Main_OnCommand(41212, 0)
          elseif Guides == 12 then r.Main_OnCommand(40774, 0) -- 64
     end
]]--
end
 Grid_Points_r ={}
 Grid_Points = {}
local p = 0
local b = 0
local blueline = loop_start 
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
    
        b = b + 1
        Grid_Points_r[b] = floor((blueline - loop_start)*srate)+(Offset_Sld.form_val/1000*srate)
   end 
 end 
------------------------------------RESTORE GRID----------------------------
-- local ext_sec, ext_key = 'savegrid', 'grid'
 --local str = r.GetExtState(ext_sec, ext_key)
 --if not str or str == '' then return end
 
 --local division, swingmode, swingamt = str:match'(.*),(.*),(.*)'
 --if not (division and swingmode and swingamt) then return end
 
 --r.GetSetProjectGrid(0, 1, division, swingmode, swingamt)
end

-------------------------------------------------------------------------------
------------------------View Main (Project) Grid--------------------------------
-------------------------------------------------------------------------------
function DrawGridGuides2() 
local lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')    
    local  item =  r.BR_GetMediaItemByGUID( 0, lastitem )
                if item then                               
-------------------------------SAVE GRID-----------------------------
 local _, division, swingmode, swingamt = r.GetSetProjectGrid(0, 0)
---------------------------SET NEWGRID-------------------------------
Grid_Points_Ruler ={}
local d = 0
local grinline2 = loop_start 
   while (grinline2 <= loop_end) do

function beatc(beatpos)
   local retval, measures, cml, fullbeats, cdenom = r.TimeMap2_timeToBeats(0, beatpos)
   local _, division, _, _ = r.GetSetProjectGrid(0,false)
   beatpos = r.TimeMap2_beatsToTime(0, fullbeats +(division*4))
   return beatpos
end
grinline2 = beatc(grinline2)

        d = d + 1
        Grid_Points_Ruler[d] = floor((grinline2 - loop_start)*srate)
   end 
 end 
--------------------------------RESTORE GRID-------------------------
 r.GetSetProjectGrid(0, 1, division, swingmode, swingamt)
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
------------------------------------------------------------------------------------------------------------

 else       

gfx.set(0, 0.7, 0.7, 0.7) -- gate line, point color -- цвет маркеров при отображении сетки

local Grid_Points_r = Grid_Points_r or {};     
local _, division, swingmode, swingamt = r.GetSetProjectGrid(0, 0)
local tempo_corr = 1/(r.Master_GetTempo()/120)
local lnt_corr = (loop_length/tempo_corr)/8
   for i=1, #Grid_Points_r  do

         sw_shift = swingamt*(1-abs(division-1))
         if IsEven(i) == false and swingmode == 1 then 
         sw_shift = (sw_shift*128*Wave.Zoom*Z_w)/lnt_corr
         else
         sw_shift = 0
         end

         local line_x  = Wave.x+sw_shift + (Grid_Points_r[i] - self.start_smpl) * self.Xsc  -- line x coord

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

local Grid_Points_Ruler = Grid_Points_Ruler or {};     
local _, division, swingmode, swingamt = r.GetSetProjectGrid(0, 0)
local tempo_corr = 1/(r.Master_GetTempo()/120)
local lnt_corr = (loop_length/tempo_corr)/8

gfx.set(0, 0, 0, 0.8) -- gate line, point color background

 for i=1, #Grid_Points_Ruler  do

         sw_shift = swingamt*(1-abs(division-1))
         if IsEven(i) == false and swingmode == 1 then 
           sw_shift = (sw_shift*128*Wave.Zoom*Z_w)/lnt_corr
             else
           sw_shift = 0
         end

         local line_x  = Wave.x+sw_shift + (Grid_Points_Ruler[i] - self.start_smpl) * self.Xsc  -- line x coord
         --------------------
         -- draw line -----
         ----------------------      
         if line_x>=Wave.x and line_x<=Wave.x+Wave.w then -- Verify line range
          gfx.line(line_x-1, (Wave.y*1.17), line_x-1, Wave.y-2+(Wave.h/300))  -- Draw Trig Line Left
          gfx.line(line_x, (Wave.y*1.18), line_x, Wave.y-2+(Wave.h/300))  -- Draw Trig Line Center
          gfx.line(line_x+1, (Wave.y*1.17), line_x+1, Wave.y-2+(Wave.h/300))  -- Draw Trig Line Right
         end
end  

gfx.set(0.1, 1, 0.1, 1) -- gate line, point color -- цвет линий сетки проекта

 for i=1, #Grid_Points_Ruler  do

         sw_shift = swingamt*(1-abs(division-1))
         if IsEven(i) == false and swingmode == 1 then 
            sw_shift = (sw_shift*128*Wave.Zoom*Z_w)/lnt_corr
              else
            sw_shift = 0
         end

         local line_x  = Wave.x+sw_shift + (Grid_Points_Ruler[i] - self.start_smpl) * self.Xsc  -- line x coord
         --------------------
         -- draw line -----
         ----------------------      
         if line_x>=Wave.x and line_x<=Wave.x+Wave.w then -- Verify line range
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
            if mouseR_Up_status == 1 and not Wave:mouseDown() then
               table.remove(self.Res_Points,self.cap_ln) -- Del self.cap_ln - Элементы смещаются влево!
               table.remove(self.Res_Points,self.cap_ln) -- Поэтому, опять тот же индекс(а не self.cap_ln+1)
                    mouseR_Up_status = 0
                    MouseUpX = 1
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
-- Создает новый айтем для фичи Trigger
function Wave:GetSet_MIDITake()
    local tracknum, midi_track, item, take      
        tracknum = r.GetMediaTrackInfo_Value(self.track, "IP_TRACKNUMBER")
        r.InsertTrackAtIndex(tracknum, false)
        midi_track = r.GetTrack(0, tracknum)
        r.TrackList_AdjustWindows(0)
        item = r.CreateNewMIDIItemInProj(midi_track, self.sel_start, self.sel_end, false)
        take = r.GetActiveTake(item)
        return item, take
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

   if count_itms == 0 then return end -- take reverse check
   for i = 0, count_itms-1 do -- take fx check
   local item = r.GetSelectedMediaItem(0, i)
   local take_count = r.CountTakes(item)
     for j = 0, take_count-1 do
     local take = r.GetMediaItemTake(item, j) 
     local   _, _, _, _, _, reverse = r.BR_GetMediaSourceProperties(take)
       if reverse == true then 
         tkrev = 1
          else
         tkrev = 0
       end
     end
   end

if SliceQ_Status == 1 and count_itms > selected_tracks_count  then
 r.Main_OnCommand(40029, 0)  -- Undo
    if tkrev == 0 then  -- if reversed item, then glue
       r.Main_OnCommand(40548, 0)  -- Heal Splits
    elseif tkrev == 1 then
      r.Main_OnCommand(41588, 0)  -- Glue
      getitem()
    end
end

SliceQ_Status = 0

sel_tracks_items() -- select for a multitrack check
selected_tracks_count = r.CountSelectedTracks(0)
count_itms =  r.CountSelectedMediaItems(0)

 r.Undo_BeginBlock() 

   -------------------------------------------

if AutoXFadesOnSplitOverride == 1 then
crossfades_on_split_option = 0
  if r.GetToggleCommandState(40912) == 1 then
    r.Main_OnCommand(40912,0)--Options: Toggle auto-crossfades on split
    crossfades_on_split_option = 1
  end
end

if ItemFadesOverride == 1 then
    itemfades_option = 0
  if r.GetToggleCommandState(41194) == 1 then
    r.Main_OnCommand(41194,0)--Options: Toggle item crossfades
    itemfades_option = 1
  end
else
itemfades_option2 = 0
  if r.GetToggleCommandState(41194) == 0 then
    r.Main_OnCommand(41194,0)--Options: Toggle item crossfades
    itemfades_option2 = 1
  end
end

if count_itms == selected_tracks_count and selected_tracks_count >1 then  -- multitrack
               r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVETIME1"),0)
               r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME2"),0);  -- Restore Selection
               r.Main_OnCommand(40061, 0) -- Item: Split items at time selection

        if RE_Status == 1 then
         re_createRE()
         end

sel_tracks_items() 

unselect_if_out_of_time_range()

               r.Main_OnCommand(40635, 0)     -- Remove Selection
               r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME1"),0)
               r.Main_OnCommand(40032, 0) -- Group Items

elseif count_itms > selected_tracks_count and selected_tracks_count >1 then  -- sliced multitrack

               r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVETIME1"),0)
               r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME2"),0);  -- Restore Selection
               r.Main_OnCommand(40061, 0) -- Item: Split items at time selection

        if RE_Status == 1 then
         re_createRE()
         end

sel_tracks_items() 

unselect_if_out_of_time_range()

               r.Main_OnCommand(40635, 0)     -- Remove Selection
               r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME1"),0)
               r.Main_OnCommand(40032, 0) -- Group Items

end

    if tkrev == 0 then -- if reversed item, then glue
       r.Main_OnCommand(40548, 0)  -- Heal Splits
    elseif tkrev == 1 then
      r.Main_OnCommand(41588, 0)  -- Glue
      getitem()
    end

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

         if Midi_sampler_offs_stat == 1 then
            cutpos = next_startppqpos - 0.002
            else
            cutpos = next_startppqpos
         end

if MIDISampler == 1 then
          if  cutpos - self.sel_start >= 0.03 and self.sel_end - cutpos >= 0.05 then -- if transient too close near item start, do nothing
             r.SetEditCurPos(cutpos,0,0)   
                if ZeroCrossings == 1 then
                    if ZeroCrossingType == 1 then
                         r.Main_OnCommand(41995, 0)   -- move to nearest zero crossing
                           else
                         r.Main_OnCommand(40790, 0)   -- move to previous zero crossing
                    end
                end
             r.Main_OnCommand(40757, 0)  ---split
          end
else

       if Random_Position == 1 or Random_Mute == 1  or Random_Vol == 1  or Random_Pitch == 1  or Random_Order == 1 or Random_Pan == 1 or Random_Reverse == 1 then 
                 if  cutpos - self.sel_start >= 0.03 and self.sel_end - cutpos >= 0.02 then -- if transient too close near item start and end, do nothing
                    r.SetEditCurPos(cutpos,0,0)   
                       if ZeroCrossings == 1 then
                           if ZeroCrossingType == 1 then
                                r.Main_OnCommand(41995, 0)   -- move to nearest zero crossing
                                  else
                                r.Main_OnCommand(40790, 0)   -- move to previous zero crossing
                           end
                       end
                    r.Main_OnCommand(40757, 0)  ---split
                 end
       else
                 if  cutpos - self.sel_start >= 0 and self.sel_end - cutpos >= 0.02 then -- if transient too close near item end, do nothing
                    r.SetEditCurPos(cutpos,0,0)   
                       if ZeroCrossings == 1 then
                           if ZeroCrossingType == 1 then
                                r.Main_OnCommand(41995, 0)   -- move to nearest zero crossing
                                  else
                                r.Main_OnCommand(40790, 0)   -- move to previous zero crossing
                           end
                       end
                    r.Main_OnCommand(40757, 0)  ---split
                 end
       end
end

        ----------------------------
     end        
         
   else

   Grid_Points = Grid_Points or {}
     local _, division, swingmode, swingamt = r.GetSetProjectGrid(0, 0)
     local tempo_corr = 1/(r.Master_GetTempo()/120)
    for i=1, #Grid_Points or 0 do --split by grid 

         sw_shift = swingamt*(1-abs(division-1))
         if IsEven(i) == false and swingmode == 1 then 
         sw_shift = sw_shift*tempo_corr                    
         else
         sw_shift = 0
         end
               
            r.SetEditCurPos((Grid_Points[i]/srate)+sw_shift,0,0)  
                if ZeroCrossings == 1 then
                    if ZeroCrossingType == 1 then
                         r.Main_OnCommand(41995, 0)   -- move to nearest zero crossing
                           else
                         r.Main_OnCommand(40790, 0)   -- move to previous zero crossing
                    end
                end
            r.Main_OnCommand(40757, 0)  ---split     
         ----------------------------
     end        
   end
 end 

Slice_Init_Status = 1 

SliceQ_Init_Status = 1

r.SetEditCurPos(cursorpos,0,0) 

r.Main_OnCommand(40034, 0)  ---select all items in groups

 r.PreventUIRefresh(-1)
    -------------------------------------------
    r.Undo_EndBlock("Slice", -1) 
 
end
::yyy::

    if AutoXFadesOnSplitOverride == 1 then
      if crossfades_on_split_option == 1 then r.Main_OnCommand(40912,0) end--Options: Toggle auto-crossfade on split
      crossfades_on_split_option = 0
    end
    
    if ItemFadesOverride == 1 then
         if itemfades_option == 1 then r.Main_OnCommand(41194,0) end--Options: Toggle item crossfades
         itemfades_option = 0
       else
         if itemfades_option2 == 1  then r.Main_OnCommand(41194,0) end--Options: Toggle item crossfades
         itemfades_option2 = 0
    end

end
end

-------------------------------------------------------------------------------------------------------------

function Wave:Quantize_Slices()


     if Slice_Status == 1 then --instant Q
        Wave:Just_Slice()
        Slice_Status = 0
     end


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
SliceQ_Status_Rand = 1
end

end

---------------------------------------------------------------------------------------------------------

function Wave:Add_Markers()
MarkersQ_Status = 1
SliceQ_Init_Status = 0
Reset_Status = 1

if Random_Status == 1 or Markers_Status == 1 then  
Wave:Reset_All()
end

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

        if RE_Status == 1 then
         re_createRE()
         end

sel_tracks_items() 

unselect_if_out_of_time_range()

               r.Main_OnCommand(40635, 0)     -- Remove Selection
               r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME1"),0)
               r.Main_OnCommand(40032, 0) -- Group Items

elseif count_itms > selected_tracks_count and selected_tracks_count >1 then  -- multitrack

               r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVETIME1"),0)
               r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME2"),0);  -- Restore Selection
               r.Main_OnCommand(40061, 0) -- Item: Split items at time selection

        if RE_Status == 1 then
         re_createRE()
         end

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

    local _, division, swingmode, swingamt = r.GetSetProjectGrid(0, 0)
    local tempo_corr = 1/(r.Master_GetTempo()/120)
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

if Random_Status == 1 then
   if  Slice_Status == 1 then
     r.Main_OnCommand(40029, 0)  -- Undo
   else
     r.Main_OnCommand(40029, 0)  -- Undo
     r.Main_OnCommand(40548, 0)     -- Heal Slices
   end
Random_Status = 0
end

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
local time = reaper.time_precise()
local function Msg()
   local char = gfx.getchar()
     if char == 27 or char == -1 or (reaper.time_precise() - time) > timer then ErrMsg_Ststus = 0 return end
local Get_Sel_ErrMsg = ErrMsg:new(680,450+corrY,260,25, 1, 1, 1, 1, "Something went wrong. Use Undo (Ctrl+Z)",    "Arial", 22)
local ErrMsg_TB = {Get_Sel_ErrMsg}
ErrMsg_Ststus = 1
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
MarkersQ_Status = 0
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

local RS_Att
local RS_Rel

 if Sampler_preset.norm_val == 1 then
RS_Att = 2 -- ms
RS_Rel = 10 -- ms
else
RS_Att = 0.1 -- ms
RS_Rel = 1 -- ms
end

RS_Att = RS_Att/2000
RS_Rel = RS_Rel/2000

function ExportItemToRS5K_defaults(data,conf,refresh,note,filepath, start_offs, end_offs, track)
    local rs5k_pos = r.TrackFX_AddByName( track, 'ReaSamplomatic5000', false, -1 )
                               r.TrackFX_Show( track, rs5k_pos, 2) -- Hide Plugins Windows
    r.TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'FILE0', filepath)
    r.TrackFX_SetNamedConfigParm(  track, rs5k_pos, 'DONE', '')      
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 0, 0.63) -- gain for min vel
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 2, 0) -- gain for min vel
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 3, note/127 ) -- note range start
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 4, note/127 ) -- note range end
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 5, 0.5 ) -- pitch for start
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 6, 0.5 ) -- pitch for end
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 8, 0 ) -- max voices = 0
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 9, RS_Att ) -- attack
    r.TrackFX_SetParamNormalized( track, rs5k_pos, 10, RS_Rel ) -- Release
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
      local c = 0
      for i = 1, r.CountSelectedMediaItems(0) do
        local item = r.GetSelectedMediaItem(0,i-1)
        local it_pos = r.GetMediaItemInfo_Value( item, 'D_POSITION' )
        local it_len = r.GetMediaItemInfo_Value( item, 'D_LENGTH' )
        c = c +1
        MIDI[c] = {pos=it_pos, end_pos = it_pos+it_len}
        MIDI.it_end_pos = it_pos + it_len
        local it_tr = r.GetMediaItemTrack( item )
        if it_tr ~= it_tr0 then proceed_MIDI = false break end
      end
      
    return proceed_MIDI, MIDI
  end
  -------------------------------------------------------------------------------    
  function ExportSelItemsToRs5k_AddMIDI(track, MIDI, base_pitch)    
    if not MIDI then return end
      local new_it = r.CreateNewMIDIItemInProj( track, MIDI.it_pos, self.sel_end )
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


            r.GetSetMediaTrackInfo_String(track, "P_NAME", "Sliced item", true) -- New Track Name

            r.SetMediaTrackInfo_Value(track, "D_VOL", volume_) -- Paste Vol
            r.SetMediaTrackInfo_Value(track, "I_SOLO", solo_) -- Paste Solo
            r.SetMediaTrackInfo_Value(track, "B_MUTE", mute_) -- Paste Mute
            r.SetMediaTrackInfo_Value(track, "D_PAN", pan_) -- Paste Pan
            r.SetMediaTrackInfo_Value(track, "D_WIDTH", width_) -- Paste Width
            r.SetMediaTrackInfo_Value(track, "I_RECMON", 1) -- Set Monitoring


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
    Midi_sampler_offs_stat = 0
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
    Trigger_Oct_Shift = tonumber(r.GetExtState('cool_MK Slicer.lua','Trigger_Oct_Shift'))or 0;
    local base_shift = Trigger_Oct_Shift*12 
    if Notes_On == 1 then OutNote.norm_val = OutNote2.norm_val end
    local pitch = (34+base_shift) + OutNote.norm_val        -- pitch from checkbox
    local chan  = 0     -- midi channel: 0 = ch1, 1 = ch2, etc
    local len   = defPPQ/5  --note lenght(its always use def ppq 960!). 5 = Lenght: 1/64
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
     
        r.MIDI_InsertNote(take, sel, mute, startppqpos, endppqpos-1, chan, pitch, vel, true)
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

function Wave:Destroy_Track_Accessor()
   
if getitem == 0 then
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

item_length2 = sel_end - sel_start -- check for sliders mw adaptive delay


loop_start = sel_start
loop_end = sel_end
loop_length = sel_end - sel_start

-----------------------------------------------------------------------------------------------------
if sel_len < 0.25 then
------------------------------------------Error Message-----------------------------------------
local timer = 2 -- Time in seconds
local time = reaper.time_precise()
local function Msg()
   local char = gfx.getchar()
     if char == 27 or char == -1 or (reaper.time_precise() - time) > timer then ErrMsg_Ststus = 0 return end
local Get_Sel_ErrMsg = ErrMsg:new(680,450+corrY,260,25, 1, 1, 1, 1, "Item is Too Short (<0.25s)",    "Arial", 22)
local ErrMsg_TB = {Get_Sel_ErrMsg}
ErrMsg_Ststus = 1
     for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
   gfx.update()
  r.defer(Msg)
end
end
Msg()
--------------------------------------End of Error Message-------------------------------------
Init()
end

if ObeyingTheSelection == 1 then
    if sel_len<0.25 or time_sel_length < 0.25 then return end -- 0.25 minimum
else
    if sel_len<0.25 then return end -- 0.25 minimum
end
    -------------- 
    self.sel_start, self.sel_end, self.sel_len = sel_start,sel_end,sel_len  -- selection start, end, lenght
    return true
end
end

---------------------------------------------------------------------------------------------------
---  Wave(Processing, drawing etc)  ----------------------------------------------------------------
---------------------------------------------------------------------------------------------------

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
    self.pix_dens = 8            -- 2^(4-1) 4-default. 1-учесть все семплы для прорисовки(max кач-во),2-через один и тд.
    self.X, self.Y  = x, h/2                           -- waveform position(X,Y axis)
    self.X_scale    = w/self.selSamples                -- X_scale = w/lenght in samples
    self.Y_scale    = h/2.5                            -- Y_scale for waveform drawing
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
     if self.Ecx >= 0 and self.Ecx <= self.w then gfx.set(0.7,0.8,0.9,1) -- main edit cursor color
        gfx.line(self.x + self.Ecx, self.y, self.x + self.Ecx, self.y+self.h -1 )
     end
     if self.Ecx >= 0 and self.Ecx <= self.w then gfx.set(0.9,0.9,0.9,1) -- loop edit cursor color 
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
    -----------------------------------------
    --- Wave Zoom(horizontal) ---------------
    if self:mouseIN() and gfx.mouse_wheel~=0 and not(Ctrl or Shift) then 
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
DrawGridGuides()
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
local KeyUP
local KeyDWN
local KeyL
local KeyR

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

  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = (self.def_xywh[1]* Z_w) , (self.def_xywh[3]* Z_w) -- upd x,w
  self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* Z_h) -- upd y,h
  if self.fnt_sz then --fix it!--
     self.fnt_sz = max(16,self.def_xywh[5]* (Z_w+Z_h)/1.9)
     self.fnt_sz = min(22,self.fnt_sz* Z_h)
  end 
  -- draw Wave frame, axis -------------
  self:draw_rect()


   -- Insert Wave from gfx buffer1 ------
  gfx.a = 1 -- gfx.a for blit
  local srcw, srch = Wave.def_xywh[3], Wave.def_xywh[4] -- its always def values 
    if WFiltering == 0 then
        gfx.mode = 4
    end
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
    Press "Get Item" button.
    Use sliders to change detection setting.
    Shift+Drag/Mousewheel - fine tune,
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

----------------------------------------------------------------------------------------------------
---   MAIN   ---------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function MAIN()

  -- Draw Wave, lines etc ------
    if Wave.State then      
          Wave:from_gfxBuffer() -- Wave from gfx buffer
          Gate_Gl:draw_Lines()  -- Draw Gate trig-lines
      --       for key,btn    in pairs(Ruler_TB)   do btn:draw()    end   -- Draw Ruler Background
          Gate_Gl:draw_Ruler() -- Draw Ruler lines



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
      else 
          Wave:show_help()      -- else show help
    end

  -- Draw sldrs, btns etc ------
    for key,btn    in pairs(Frame_TB)   do btn:draw()    end 

    if SliceQ_Status_Rand == 1 and Random_Status == 1 then
        for key,btn    in pairs(FrameQR_Link_TB)   do btn:draw()    end 
    end

    if  Random_Setup ~= 1 then
       for key,btn    in pairs(Button_TB2)   do btn:draw()    end 
       for key,btn    in pairs(FrameR_TB)   do btn:draw()    end 
    end
    for key,btn    in pairs(Button_TB)   do btn:draw()    end 
    for key,sldr   in pairs(Slider_TB)   do sldr:draw()   end
    for key,ch_box in pairs(CheckBox_TB) do ch_box:draw() end


      if Random_Order == 1 then
         for key,frame  in pairs(Rand_Button_Color1_TB)    do frame:draw()  end 
     end
      if Random_Vol == 1 then
         for key,frame  in pairs(Rand_Button_Color2_TB)    do frame:draw()  end 
     end
      if Random_Pan == 1 then
         for key,frame  in pairs(Rand_Button_Color3_TB)    do frame:draw()  end 
     end
      if Random_Pitch == 1 then
         for key,frame  in pairs(Rand_Button_Color4_TB)    do frame:draw()  end 
     end
      if Random_Mute == 1 then
         for key,frame  in pairs(Rand_Button_Color7_TB)    do frame:draw()  end 
     end
      if Random_Position == 1 then
         for key,frame  in pairs(Rand_Button_Color6_TB)    do frame:draw()  end 
     end
      if Random_Reverse == 1 then
         for key,frame  in pairs(Rand_Button_Color5_TB)    do frame:draw()  end 
     end

if  Random_Setup ~= 1 then
      if (Midi_Sampler.norm_val == 1)  then
         for key,ch_box    in pairs(Checkbox_TB_preset)   do ch_box:draw()    end 
      end
end
      if (Midi_Sampler.norm_val == 2)then 
           if  Random_Setup ~= 1 then

              if Notes_On == 1 then
                 for key,sldr   in pairs(Slider_TB_Trigger_notes)   do sldr:draw()   end
                 else
                 for key,sldr   in pairs(Slider_TB_Trigger)   do sldr:draw()   end
              end
           end
         if Guides.norm_val ~= 1 then
               for key,frame  in pairs(Frame_TB2_Trigg)    do frame:draw()  end 
         end
     else
         if  Random_Setup ~= 1 then
               for key,frame  in pairs(Preset_TB)    do frame:draw()  end  
         end
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

    if Random_Setup == 1 then

        for key,btn    in pairs(Random_Setup_TB2)   do btn:draw()    end 

        for key,frame  in pairs(Triangle_TB)    do frame:draw()  end 

      if Random_Order == 1 then
         for key,frame  in pairs(Rand_Mode_Color1_TB)    do frame:draw()  end 
     end
      if Random_Vol == 1 then
         for key,frame  in pairs(Rand_Mode_Color2_TB)    do frame:draw()  end 
         for key,sldr   in pairs(SliderRandV_TB)   do sldr:draw()   end
     end
      if Random_Pan == 1 then
         for key,frame  in pairs(Rand_Mode_Color3_TB)    do frame:draw()  end 
         for key,sldr   in pairs(SliderRandPan_TB)   do sldr:draw()   end
     end
      if Random_Pitch == 1 then
         for key,frame  in pairs(Rand_Mode_Color4_TB)    do frame:draw()  end 
         for key,sldr   in pairs(SliderRandPtch_TB)   do sldr:draw()   end
     end
      if Random_Mute == 1 then
         for key,frame  in pairs(Rand_Mode_Color7_TB)    do frame:draw()  end 
     end
      if Random_Position == 1 then
         for key,frame  in pairs(Rand_Mode_Color6_TB)    do frame:draw()  end 
         for key,sldr   in pairs(SliderRand_TBPos)   do sldr:draw()   end
     end
      if Random_Reverse == 1 then
         for key,frame  in pairs(Rand_Mode_Color5_TB)    do frame:draw()  end 
         for key,sldr   in pairs(SliderRand_TBM)   do sldr:draw()   end
     end

         for key,frame  in pairs(RandText_TB)    do frame:draw()  end 
   end

    if ShowInfoLine == 1 and Random_Setup ~= 1 then
        Info_Line()
    end

end

------------------------------------
-- MouseWheel Related Functions ---
------------------------------------

function MW_doit_slider()
      if Wave.State then
            Gate_Gl:Apply_toFiltered() -- redraw transient markers
            Slice_Status = 1
      end
end

function MW_doit_slider_Fine()
      if Wave.State then
            Gate_Gl:Apply_toFiltered() -- redraw transient markers
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
end

function MW_doit_slider_fgain()
      if Wave.State then
            Gate_Gl:Apply_toFiltered() -- redraw transient markers
            Wave:Redraw() --redraw filtered gain and filters
            Slice_Status = 1
      end
end

function MW_doit_slider_comlpex()
      if Wave.State then
            Wave:Processing() -- redraw lowcut and highcut
            Gate_Gl:Apply_toFiltered() -- redraw transient markers
            Wave:Redraw() --redraw filtered gain and filters
            Slice_Status = 1
      end
end

function MW_doit_checkbox()
      if Wave.State then
         Wave.Reset_All()
         DrawGridGuides()
      end
end

function MW_doit_checkbox_show()
      if Wave.State then
         Wave:Redraw()
      end
end

function Heal_protection() -- не клеит, если Guides активны
   if Guides.norm_val == 1 then
r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то клей, попытка не деструктивно склеить).
end 
end

function Glue_protection() -- не клеит, если Guides активны
   if Guides.norm_val == 1 then
r.Main_OnCommand(41588, 0) -- glue (если изменены rate, pitch, больше одного айтема и не миди айтем, то клей. Требуется для корректной работы кнопки MIDI).
end 
end

function MIDITrigger()
   if Guides.norm_val == 1 then
     if Wave.State then Wave:Create_MIDI() end
     Wave.State = false -- reset Wave.State
   end 
end
------------------------------------------------------------------------------------

function store_settings() --store dock position
   r.SetExtState("cool_MK Slicer.lua", "dock", gfx.dock(-1), true)
end

function store_settings2() --store sliders/checkboxes
     if RememberLast == 1 then 
        r.SetExtState('cool_MK Slicer.lua','Guides.norm_val',Guides.norm_val,true);
        if Notes_On == 1 then OutNote.norm_val = OutNote2.norm_val end
        r.SetExtState('cool_MK Slicer.lua','OutNote.norm_val',OutNote.norm_val,true);
        r.SetExtState('cool_MK Slicer.lua','Midi_Sampler.norm_val',Midi_Sampler.norm_val,true);
        r.SetExtState('cool_MK Slicer.lua','Sampler_preset.norm_val',Sampler_preset.norm_val,true);
        r.SetExtState('cool_MK Slicer.lua','QuantizeStrength',QStrength_Sld.form_val,true);
        r.SetExtState('cool_MK Slicer.lua','HF_Slider',HP_Freq.norm_val,true);
        r.SetExtState('cool_MK Slicer.lua','LF_Slider',LP_Freq.norm_val,true);
        r.SetExtState('cool_MK Slicer.lua','Sens_Slider',Gate_Sensitivity.norm_val,true);
        r.SetExtState('cool_MK Slicer.lua','Offs_Slider',Offset_Sld.norm_val,true);
        if XFadeOff == 0 then
           r.SetExtState('cool_MK Slicer.lua','CrossfadeTime',XFade_Sld.form_val,true);
        end
        r.SetExtState('cool_MK Slicer.lua','Gate_VeloScale.norm_val',Gate_VeloScale.norm_val,true);
        r.SetExtState('cool_MK Slicer.lua','Gate_VeloScale.norm_val2',Gate_VeloScale.norm_val2,true);

        r.SetExtState('cool_MK Slicer.lua','RandV_Sld.norm_val',RandV_Sld.norm_val,true);
        r.SetExtState('cool_MK Slicer.lua','RandPan_Sld.norm_val',RandPan_Sld.norm_val,true);
        r.SetExtState('cool_MK Slicer.lua','RandPtch_Sld.norm_val',RandPtch_Sld.norm_val,true);
        r.SetExtState('cool_MK Slicer.lua','RandPos_Sld.norm_val',RandPos_Sld.norm_val,true);
        r.SetExtState('cool_MK Slicer.lua','RandRev_Sld.norm_val',RandRev_Sld.norm_val,true);

          r.SetExtState('cool_MK Slicer.lua','Sync_on',Sync_on,true);
     end
end

-------------------------------------------------------------------------------
--   INIT   --------------------------------------------------------------------
-------------------------------------------------------------------------------
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
    local Wnd_Title = "MK Slicer v2.15"
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

    -- zoom level -- 
    Wnd_WZ = r.GetExtState("cool_MK Slicer.lua", "zoomWZ") or 1044
    Wnd_HZ = r.GetExtState("cool_MK Slicer.lua", "zoomHZ") or 490
    if Wnd_WZ == (nil or "") then Wnd_WZ = 1044 end
    if Wnd_HZ == (nil or "") then Wnd_HZ = 490 end

    Z_w, Z_h = gfx.w/Wnd_WZ, gfx.h/Wnd_HZ
    gfx_width = gfx.w
    if Z_w<0.63 then Z_w = 0.63 elseif Z_w>2.2 then Z_w = 2.2 end 
    if Z_h<0.63 then Z_h = 0.63 elseif Z_h>2.2 then Z_h = 2.2 end 

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
    if ShowRuler == 1 then
        DrawGridGuides2()
    end

    if Loop_on == 1 then
       isloop = true
         else
       isloop = false
     --       if loopcheck == 0 then
                r.GetSet_LoopTimeRange(true, true, 0, 0, false)
      --      end
    end

    if loop_start then
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

         reaper.GetSet_ArrangeView2( 0,1,0,0,rng3, rng4 )

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
    r.SetExtState("cool_MK Slicer.lua", "window_x", xpos, true)
    r.SetExtState("cool_MK Slicer.lua", "window_y", ypos, true)
    r.SetExtState("cool_MK Slicer.lua", "zoomW", Wnd_W, true)
    r.SetExtState("cool_MK Slicer.lua", "zoomH", Wnd_H, true)
    r.SetExtState("cool_MK Slicer.lua", "zoomWZ", Wnd_WZ, true)
    r.SetExtState("cool_MK Slicer.lua", "zoomHZ", Wnd_HZ, true)
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

item2 = context_menu:add_item({label = "Donate (PayPal)", toggleable = false})
item2.command = function()
                     r.CF_ShellExecute('https://paypal.me/MKokarev')
end

item3 = context_menu:add_item({label = "User Manual and Support (Forum Thread)|", toggleable = false})
item3.command = function()
                     r.CF_ShellExecute('https://forum.cockos.com/showthread.php?p=2255547')
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
     local Wnd_Title = "MK Slicer v2.15"
     local Wnd_Dock, Wnd_X,Wnd_Y = dock_pos, xpos, ypos
     gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )

                     else

    r.SetExtState("cool_MK Slicer.lua", "dock", gfx.dock(-1), true)
gfx.quit()
    Docked = 0
    dock_pos = 0
    xpos = r.GetExtState("cool_MK Slicer.lua", "window_x") or 400
    ypos = r.GetExtState("cool_MK Slicer.lua", "window_y") or 320
    local Wnd_Title = "MK Slicer v2.15"
    local Wnd_Dock, Wnd_X,Wnd_Y = dock_pos, xpos, ypos
    gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )
 
    Wnd_WZ = r.GetExtState("cool_MK Slicer.lua", "zoomWZ") or 1044
    Wnd_HZ = r.GetExtState("cool_MK Slicer.lua", "zoomHZ") or 490
    if Wnd_WZ == (nil or "") then Wnd_WZ = 1044 end
    if Wnd_HZ == (nil or "") then Wnd_HZ = 490 end
 
    Z_w, Z_h = gfx.w/Wnd_WZ, gfx.h/Wnd_HZ
 
    if Z_w<0.63 then Z_w = 0.63 elseif Z_w>2.2 then Z_w = 2.2 end 
    if Z_h<0.63 then Z_h = 0.63 elseif Z_h>2.2 then Z_h = 2.2 end 
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
          r.SetExtState('cool_MK Slicer.lua','PlayMode',PlayMode,true);
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
          r.SetExtState('cool_MK Slicer.lua','Loop_on',Loop_on,true);
end


if ZeroCrossings == 1 then
item10 = context_menu:add_item({label = "Split at Zero Crossings (Attension: Imprecise Cuts!)", toggleable = true, selected = true})
else
item10 = context_menu:add_item({label = "Split at Zero Crossings (Attension: Imprecise Cuts!)", toggleable = true, selected = false})
end
item10.command = function()
                     if item10.selected == true then 
                     ZeroCrossings = 1
                     else
                     ZeroCrossings = 0
                     end
          r.SetExtState('cool_MK Slicer.lua','ZeroCrossings',ZeroCrossings,true);
end


if ItemFadesOverride == 1 then
item11 = context_menu:add_item({label = "Set Item Fades On Splits (Prevent Clicks)", toggleable = true, selected = false})
else
item11 = context_menu:add_item({label = "Set Item Fades On Splits (Prevent Clicks)", toggleable = true, selected = true})
end
item11.command = function()
                     if item11.selected == false then 
                     ItemFadesOverride = 1
                     else
                     ItemFadesOverride = 0
                     end
          r.SetExtState('cool_MK Slicer.lua','ItemFadesOverride',ItemFadesOverride,true);
end


if MIDISamplerCopyFX == 1 then
item12 = context_menu:add_item({label = "Sampler: Copies FX from the Original Track to a New one", toggleable = true, selected = true})
else
item12 = context_menu:add_item({label = "Sampler: Copies FX from the Original Track to a New one", toggleable = true, selected = false})
end
item12.command = function()
                     if item12.selected == true then 
                     MIDISamplerCopyFX = 1
                     else
                     MIDISamplerCopyFX = 0
                     end
          r.SetExtState('cool_MK Slicer.lua','MIDISamplerCopyFX',MIDISamplerCopyFX,true);
end 


if MIDISamplerCopyRouting == 1 then
item13 = context_menu:add_item({label = "Sampler: Copies Routing from the Original Track to a New one", toggleable = true, selected = true})
else
item13 = context_menu:add_item({label = "Sampler: Copies Routing from the Original Track to a New one", toggleable = true, selected = false})
end
item13.command = function()
                     if item13.selected == true then 
                     MIDISamplerCopyRouting = 1
                     else
                     MIDISamplerCopyRouting = 0
                     end
          r.SetExtState('cool_MK Slicer.lua','MIDISamplerCopyRouting',MIDISamplerCopyRouting,true);
end


if Notes_On == 1 then
item14 = context_menu:add_item({label = "Trigger: Show Note Names|", toggleable = true, selected = true})
else
item14 = context_menu:add_item({label = "Trigger: Show Notes Names|", toggleable = true, selected = false})
end
item14.command = function()
                     if item14.selected == true then 
                     Notes_On = 1
                     else
                     Notes_On = 0
                     end
          r.SetExtState('cool_MK Slicer.lua','Notes_On',Notes_On,true);
end 


if ObeyingTheSelection == 1 then
item15 = context_menu:add_item({label = "Start the Script or 'Get Item' Obeying Time Selection, if any", toggleable = true, selected = true})
else
item15 = context_menu:add_item({label = "Start the Script or 'Get Item' Obeying Time Selection, if any", toggleable = true, selected = false})
end
item15.command = function()
                     if item15.selected == true then 
                     ObeyingTheSelection = 1
                     else
                     ObeyingTheSelection = 0
                     end
          r.SetExtState('cool_MK Slicer.lua','ObeyingTheSelection',ObeyingTheSelection,true);
end


if ObeyingItemSelection == 1 then
           item16 = context_menu:add_item({label = "Time Selection Require Item(s) Selection|", toggleable = true, selected = true, active = true})
           else
           item16 = context_menu:add_item({label = "Time Selection Require Item(s) Selection|", toggleable = true, selected = false, active = true})
end
item16.command = function()
                     if item16.selected == true then 
                     ObeyingItemSelection = 1
                     else
                     ObeyingItemSelection = 0
                     end
          r.SetExtState('cool_MK Slicer.lua','ObeyingItemSelection',ObeyingItemSelection,true);

end


item17 = context_menu:add_item({label = ">User Settings (Advanced)"})
item17.command = function()

end


item18 = context_menu:add_item({label = "Set User Defaults", toggleable = false})
item17.command = function()
user_defaults()
end


item19 = context_menu:add_item({label = "Reset All Setted User Defaults", toggleable = false})
item18.command = function()

      r.SetExtState('cool_MK Slicer.lua','DefaultXFadeTime',15,true);
      r.SetExtState('cool_MK Slicer.lua','DefaultQStrength',100,true);
      r.SetExtState('cool_MK Slicer.lua','DefaultLP',1,true);
      r.SetExtState('cool_MK Slicer.lua','DefaultHP',0.3312,true);
      r.SetExtState('cool_MK Slicer.lua','DefaultSens',0.375,true);
      r.SetExtState('cool_MK Slicer.lua','DefaultOffset',0.5,true);
      r.SetExtState('cool_MK Slicer.lua','MIDI_Base_Oct',2,true);
      r.SetExtState('cool_MK Slicer.lua','Trigger_Oct_Shift',0,true);

end


item20 = context_menu:add_item({label = "|XFades and Fill Gaps On/Off (Experimental)", toggleable = false})
item19.command = function()
 if XFadeOff == 1 then XFadeOff = 0
elseif XFadeOff == 0 then XFadeOff = 1
end
      r.SetExtState('cool_MK Slicer.lua','XFadeOff',XFadeOff,true);
end


item21 = context_menu:add_item({label = "|Reset Controls to User Defaults (Restart required)|<", toggleable = false})
item20.command = function()
Reset_to_def = 1
  --sliders--
      DefaultXFadeTime = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultXFadeTime'))or 15;
      DefaultQStrength = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultQStrength'))or 100;
      DefaultHP = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultHP'))or 0.3312;
      DefaultLP = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultLP'))or 1;
      DefaultSens = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultSens'))or 0.375;
      DefaultOffset = tonumber(r.GetExtState('cool_MK Slicer.lua','DefaultOffset'))or 0.5;
  --sheckboxes--
     DefMIDI_Mode =  1;
     DefSampler_preset_state =  1;
     DefGuides_mode =  1;
     DefOutNote_State =  1;
     DefGate_VeloScale =  1;
     DefGate_VeloScale2 =  1;
     DefXFadeOff = 0

  --sliders--
      r.SetExtState('cool_MK Slicer.lua','CrossfadeTime',DefaultXFadeTime,true);
      r.SetExtState('cool_MK Slicer.lua','QuantizeStrength',DefaultQStrength,true);
      r.SetExtState('cool_MK Slicer.lua','Offs_Slider',DefaultOffset,true);
      r.SetExtState('cool_MK Slicer.lua','HF_Slider',DefaultHP,true);
      r.SetExtState('cool_MK Slicer.lua','LF_Slider',DefaultLP,true);
      r.SetExtState('cool_MK Slicer.lua','Sens_Slider',DefaultSens,true);
  --sheckboxes--
      r.SetExtState('cool_MK Slicer.lua','Guides.norm_val',DefGuides_mode,true);
      if Notes_On == 1 then OutNote.norm_val = OutNote2.norm_val end
      r.SetExtState('cool_MK Slicer.lua','OutNote.norm_val',DefOutNote_State,true);
      r.SetExtState('cool_MK Slicer.lua','Midi_Sampler.norm_val',DefMIDI_Mode,true);
      r.SetExtState('cool_MK Slicer.lua','Sampler_preset.norm_val',DefSampler_preset_state,true);
      r.SetExtState('cool_MK Slicer.lua','XFadeOff',DefXFadeOff,true);
      r.SetExtState('cool_MK Slicer.lua','Gate_VeloScale.norm_val',DefGate_VeloScale,true);
      r.SetExtState('cool_MK Slicer.lua','Gate_VeloScale.norm_val2',DefGate_VeloScale2,true);

end


item22 = context_menu:add_item({label = "|Reset Window Size", toggleable = false})
item21.command = function()
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
Trigger_Oct_Shift  = tonumber(r.GetExtState('cool_MK Slicer.lua','Trigger_Oct_Shift'))or 0;

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

local retval, value = r.GetUserInputs("User Defaults", 8, "Crossfade Time (0 - 50) ms ,Quantize Strength (0 - 100) % ,LowCut Slider (20 - 20000) Hz ,High Cut Slider (20 - 20000) Hz ,Sensitivity (2 - 10) dB ,Offset Slider (-100 - +100) ,Sampler Base Octave (0 - 9) ,Trigger Octave Shift (-2 - 7) ", values)
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

          r.SetExtState('cool_MK Slicer.lua','DefaultXFadeTime',DefaultXFadeTime2,true);
          r.SetExtState('cool_MK Slicer.lua','DefaultQStrength',DefaultQStrength2,true);
          r.SetExtState('cool_MK Slicer.lua','DefaultLP',DefaultLP2,true);
          r.SetExtState('cool_MK Slicer.lua','DefaultHP',DefaultHP2,true);
          r.SetExtState('cool_MK Slicer.lua','DefaultSens',DefaultSens2,true);
          r.SetExtState('cool_MK Slicer.lua','DefaultOffset',DefaultOffset2,true);
          r.SetExtState('cool_MK Slicer.lua','MIDI_Base_Oct',MIDI_Base_Oct2,true);
          r.SetExtState('cool_MK Slicer.lua','Trigger_Oct_Shift',Trigger_Oct_Shift2,true);

end
end
-----------------------end of User Defaults form--------------------------------

function ClearExState()
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
end

r.atexit(ClearExState)

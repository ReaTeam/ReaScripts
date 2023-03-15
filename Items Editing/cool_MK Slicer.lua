-- @description MK Slicer
-- @author cool
-- @version 3.03
-- @changelog
--   +Added experimental font smoothing option (requires RealmGUI to be installed).
--   +When scrolling horizontally, hand cursor changed to double arrow cursor (required for RealmGUI compatibility)
--   +Fixed a bug: now the script does not close with an error if used with 0 transient markers.
--   +Fixed a bug: now when the "Script Starts Docked" option is enabled, the script is immediately sent to the dock.
--   +Fixed a bug: now multiple button presses do not cause multiple drawing of the error text.
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=232672
-- @screenshot MK_Slicer 3 https://i.imgur.com/L7WnvoO.jpg
-- @donation
--   Donate by BuyMeACoffee https://www.buymeacoffee.com/MaximKokarev
--   Donate by YooMoney https://yoomoney.ru/to/41001256406969
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
--   - Pitch detection: the ability to convert simple single-voiced parts and drums to midi.
--   - Tempo detection, item rate change to adapt to project tempo. Ability to create a tempo map from an item.
--    - Adaptive initial settings. Upon initialization, the script sets the View Gain, Threshold, and Retrig settings depending on the material and tempo of the project.
--
--   Instructions for use:
--
--   1. Select an item or several items. If items on multiple tracks are selected, only the top one will be analyzed. If several items are selected on the same track, they will be glued together.
--   2. Run the script.
--   3. Do your work.
--   4. To cancel an actions, use Reset or just Ctrl + Z. Reset sliders to default: Ctrl + Click. Fine tune: Shift + Drag. Exit the script: Esc, Space - Play. 
--
--   On Waveform Area:
--   Mouswheel or Left/Right keys - Horizontal Zoom,
--   Ctrl(Shift)+Mouswheel or Up/Down keys - Vertical Zoom, 
--   Left or Middle Drag - Move View (Horizontal Scroll),
--   Left Click - Set Edit Cursor,
--   Left Drag Small Flag - Move Marker,
--   Ctrl+Left Drag - Change Velocity,
--   Right Click on Marker - Delete Marker,
--   Right Click on Empty Space - Insert Marker.
--
--   Working with multitrack:
--
--   0. Before starting the work, I recommend you to create a guide track - usually a mixdown kick, snare and toms tracks together in one track. This track will be used as a “lead” for the detector to operate more accurately After the work is completed, you can delete it.
--   1. Select items. If items on multiple tracks are selected, only the top one will be analyzed.
--   2. Run the script.
--   3. Do your work. When a slicing or placing markers occurs on a multitrack, items will be automatically added to Groups.
--
--
--   Important.
--
--   For the machanism Reset to operate correctly and for the operations on-the-fly to follow each other smoothly, it is OBLIGATORY for the items to start from the beginning of the bar. It's the condition which ensures comfortable work without surprises like a sudden move of the items after the following quantization. Additionaly, I don't recommend to change selection manually or do anything with the items while the script is working. Also, do not forget to save your project regularly. Just in case.
--
--   Sometimes a script applies glue to items. For example, when several items are selected and when a MIDI is created in a sampler mode.

--[[
MK Slicer v3.03 by Maxim Kokarev 
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

Razor Edit functions by BirdBird, Juliansander and Embass:
https://forum.cockos.com/showthread.php?t=241604

Randomise Reverse based on "me2beats_Toggle random active takes reverse"
script by me2beats
https://forum.cockos.com/member.php?u=100851

Pitch to Notes table based on FeedTheCat code:
https://forum.cockos.com/showthread.php?t=259698

Pitch Detection based on Justin Frankel code:
http://forum.cockos.com/showpost.php?p=1777001&postcount=2

"Unselect an item if there is only one on the track" code by Edgemeal:
https://forum.cockos.com/showpost.php?p=2575889&postcount=231
]]

----------------------------Advanced User Settings--(Modify with care!)----------------------------------

RememberLast = 1  -- (Remember some sliders positions from last session. 1 - On, 0 - Off)
AutoXFadesOnSplitOverride = 1 -- (Override "Options: Toggle auto-crossfade on split" option. 0 - Don't Override, 1 - Override)
Compensate_Oct_Offset = 0 -- (Trigger: octave shift of note names to compensate "MIDI octave name display offset". -4 - Min, 4 - Max)
WFiltering = 0 -- (Waveform Visual Filtering while Window Scaling. 1 - On, 0 - Off)
ShowRuler = 1 -- (Show Project Grid Green Markers. 1 - On, 0 - Off)
ShowTrackAndItemInfo = 1 -- (Show processed item and related track number. 1 - On, 0 - Off)
SnapToStart = 1 --(Snap Play Cursor to Waveform Start. 1 - On, 0 - Off)
ZeroCrossingType = 1 -- (1 - Snap to Nearest (working fine), 0 - Snap to previous (not recommend, for testing only!))
SnapToSemi = 1 -- (Random pitch steps by semitones 2 - On(Intervals), 1 - On(chromatic), 0 - Off(cents))
ForceSync = 0 -- (force Sync On on the script starts: 1 - On (Force On), 0 - Off (Save Previous State))
No_Heal_On_Init = 1 --(Don't try healing multiple items on the script starts: 1 - On (Glue only), 0 - Off (Trying to undestructive Heal items, if not successful, then Glue))
No_Glue_On_Init = 0 --(Don't try gluing multiple items on the script starts: 1 - On ( No Glue, not recommend), 0 - Off (Glue, Recommended))
GroupingWhenSlicing = 1 -- (Grouping Multitrack When Slicing: 1 - On, 0 - Off. Disabling greatly increases the speed of Slicing multitrack. )
SetTkMarker = 0 -- (Place Tempo Marker When Set BPM (Item Rate): 1 - On, 0 - Off.)

RebuildPeaksOnStart = 0 -- (Rebuilding waveform peaks when the script starts. Required for Pitch Detection to work correctly on slow PC. 1 - On (Recommended), 0 - Off)
TimeForPeaksRebuild = 0.6 -- (Additional delay required to rebuild peaks in Pitch Detection mode. If you get an empty MIDI file, you need to increase the value. I recommend values between: 0.3 (fast modern PC) and 1 (slowest PC). Default: 0.3, Recommended: 0.6 ).

ForcePitchBend = 1 -- Forces a Pitch Bend value for each ReaSamplomatic5000 instance (1 - On, 0 - Off)
PitchBend = 12 -- if ForcePitchBend if on, set max pitch bend, semitones (0 - Min, 12 - Max)

KickNote = 35 -- Pitch Detector Notes ("Drums" preset)
SnareNote = 38
HatNote = 42

--------------------------------Themes----------------------------------------------
local TH = {}
function Theming(Theme)

      if Theme == nil then Theme = 1 end 
      if Theme < 0 then Theme = 1 elseif Theme >= 10 then Theme = 10 end 


      if Theme == 1 then 
      -------------------------Prime------------------------------
      theme_name = "Prime"
      -------Backgrounds and Frames-----------------
      TH[1] = {0.172, 0.20, 0.215,1} -- Waveform, Background Box
      TH[2] = {0.172, 0.20, 0.215,1} -- Waveform, Frame
      TH[3] = { 0.208, 0.243, 0.251} -- Main Background
      TH[4] = { 0.32, 0.34, 0.34, 1 } -- Controls Body
      TH[5] = { 0.22, 0.24, 0.24, 0 } -- Controls Frame

      -----------Waveforms---------------
      TH[6] = { 0.078, 0.58, 0.725,1 } -- Waveform, Filtered 
      TH[7] = {0.16, 0.14, 0.14,1} -- Waveform, Original 
      TH[8] = { 0.12, 0.10, 0.10,1 } -- Waveform, Draw original Only

      --------Waveform Lines--------------
      TH[9] = { 0.1, 0.8, 0.4, 1 } -- Ruler 
      TH[10] = 4 -- Ruler Gradient Width (0 = off)
      TH[11] = 0.05 --Ruler Gradient Transparency

      TH[12] = { 1, 1, 1, 0.1 } -- Threshold Lines
      TH[13] = { 0.906, 0.463, 0.0, 0.9 } -- Transient Markers
      TH[14] = 5 -- Transient Markers Gradient Width (if Selected)
      TH[15] = 0.3 --Transient Markers Gradient Transparency (if Selected)
      TH[16] = 0 -- Transient Markers Gradient Width (0 - off)
      TH[17] = 0 --Transient Markers Gradient Transparency

      TH[18] = { 0.906, 0.463, 0.0, 0.1 } -- Sample Area if enabled

      TH[19] = { 0.82, 0.294, 0.0, 0.7 } -- Grid Markers

      TH[20] = { 0.8, 0.8, 0.8, 1 } -- Edit Cursor
      TH[21] = 5 -- Edit Cursor Gradient Width
      TH[22] = 0.2 --Edit Cursor Gradient Transparency

      TH[23] = { 0.031, 0.604, 0.765, 1 } -- Play Cursor
      TH[24] = 5 -- Play Cursor Gradient Width
      TH[25] = 0.2 --Play Cursor Gradient Transparency

      TH[26] = { 0.2, 1, 0.5, 0.5 } -- Aim Assist Cursor

      -------Buttons and Sliders ---------
      TH[27] = {0.2, 0.2 ,0.2 ,1} -- Button Body
      TH[28] = {0.2, 0.2 ,0.2 ,1} -- Button Frames
      
      TH[29] = {0.23, 0.25, 0.25,1} -- Slider Frames
      TH[30] = {0.23, 0.25, 0.25,1} -- Slider Body
      
      TH[31] = {0.32, 0.34, 0.34, 1} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.32, 0.34, 0.34, 1} -- Slider Body (Top, Loop and Swing)
      
      --------------Text--------------------
      TH[33] = { 0.61, 0.61, 0.61, 1 } -- Text Main
      TH[34] = { 1, 0.5, 0.3, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.45, 0.45, 0.45, 1 } -- Txt Greyed (BPM)
      TH[36] = { 0.55, 0.55, 0.55, 1 } -- Txt Greyed (Presets, Mode)      
      TH[37] = -0.1 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.9 -- BPM digits transparency

      -----------Elements------------------
      TH[39] =  { 0.1, 0.8, 0.4, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.60, 0.60, 0.60, 0.4 } -- Txt Brackets
      TH[41] = { 0.60, 0.60, 0.60, 0.4 } -- Main Separators
      TH[42] = 0.7 -- Leds Transparency (Controls Body)
      TH[43] = 0.1 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      --------------------------------------------------------------


      elseif Theme == 2 then 
     ------------------------------Neon---------------------------
      theme_name = "Neon"
      -------Backgrounds and Frames-----------------
      TH[1] = {0.12157, 0.14118, 0.16471,1} -- Waveform, Background Box
      TH[2] = {0.172, 0.20, 0.215,1} -- Waveform, Frame
      TH[3] = { 0.20922, 0.22882, 0.26804} -- Main Background
      TH[4] = { 0.18, 0.19, 0.22, 1 } -- Controls Body
      TH[5] = { 0.22, 0.22, 0.22, 0 } -- Controls Frame

      -----------Waveforms---------------
      TH[6] = {0.875, 0.525, 0.098,1} -- Waveform, Filtered 
      TH[7] = {0.24,0.23,0.21,1} -- Waveform, Original 
      TH[8] = { 0.37, 0.33, 0.28 ,1 } -- Waveform, Draw original Only

      --------Waveform Lines--------------
      TH[9] = { 0.0, 0.97647, 0.49804, 1 } -- Ruler
      TH[10] = 4 -- Ruler Gradient Width (0 = off)
      TH[11] = 0.12 --Ruler Gradient Transparency

      TH[12] = { 0.027, 0.624, 0.749, 0.3 } -- Threshold Lines
      TH[13] = { 0.035, 0.604, 0.718, 0.9 } -- Transient Markers
      TH[14] = 7 -- Transient Markers Gradient Width (if Selected)
      TH[15] = 0.3 --Transient Markers Gradient Transparency (if Selected)
      TH[16] = 7 -- Transient Markers Gradient Width (0 - off)
      TH[17] = 0.1 --Transient Markers Gradient Transparency

      TH[18] = { 0.035, 0.604, 0.718, 0.12 } -- Sample Area if enabled

      TH[19] = { 0, 0.7, 0.7, 0.7 } -- Grid Markers
      
      TH[20] = { 0.98, 0.114, 0.984, 1 } -- Edit Cursor
      TH[21] = 5 -- Edit Cursor Gradient Width
      TH[22] = 0.2 --Edit Cursor Gradient Transparency

      TH[23] = { 0.141, 0.98, 0.69, 1 } -- Play Cursor
      TH[24] = 5 -- Play Cursor Gradient Width
      TH[25] = 0.2 --Play Cursor Gradient Transparency

      TH[26] = { 0.0, 1, 0.5, 0.5 } -- Aim Assist Cursor
      
      -------Buttons and Sliders ---------
      TH[27] = {0.3, 0.31 ,0.32 ,1} -- Button Body
      TH[28] = {0.3, 0.31 ,0.32 ,1} -- Button Frames
      
      TH[29] = {0.28235, 0.32941, 0.34118,1} -- Slider Frames
      TH[30] = {0.28235, 0.32941, 0.34118,1} -- Slider Body
      
      TH[31] = {0.33235, 0.37941, 0.39118,1} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.33235, 0.37941, 0.39118,1} -- Slider Body (Top, Loop and Swing)
      
      --------------Text--------------------     
      TH[33] = { 0.7, 0.7, 0.7, 1 } -- Text Main
      TH[34] = { 1, 0.5, 0.3, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.4, 0.4, 0.4, 0.5 } -- Txt Greyed (BPM)
      TH[36] = { 0.5, 0.5, 0.5, 0.5 } -- Txt Greyed (Presets, Mode)
      TH[37] = 0 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.9 -- BPM digits transparency
    
      -----------Elements------------------
      TH[39] =  { 0.0, 0.81176, 0.41176, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.4, 0.4, 0.4, 0.5 } -- Txt Brackets
      TH[41] = { 0.4, 0.4, 0.4, 0.5 } -- Main Separators
      TH[42] = 0.9 -- Leds Transparency (Controls Body)
      TH[43] = 0.15 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      --------------------------------------------------------------


      elseif Theme == 3 then 
       -------------------------Black------------------------------
      theme_name = "Black"
      -------Backgrounds and Frames-----------------
      TH[1] = {0.188, 0.196, 0.2,1} -- Waveform, Background Box
      TH[2] = {0.172, 0.20, 0.215,1} -- Waveform, Frame
      TH[3] = { 0.166, 0.174, 0.177} -- Main Background
      TH[4] = { 0.157, 0.157, 0.157, 1 } -- Controls Body
      TH[5] = { 0.22, 0.22, 0.22, 0 } -- Controls Frame

      -----------Waveforms---------------
      TH[6] = { 0.078, 0.725, 0.725,1 } -- Waveform, Filtered 
      TH[7] = {0.16, 0.14, 0.14,1} -- Waveform, Original 
      TH[8] = { 0.12, 0.10, 0.10,1 } -- Waveform, Draw original Only

      --------Waveform Lines--------------
      TH[9] = { 0.9, 0.9, 0.9, 1 } -- Ruler 
      TH[10] = 4 -- Ruler Gradient Width (0 = off)
      TH[11] = 0.05 --Ruler Gradient Transparency

      TH[12] = { 0.9, 0.9, 0.9, 0.2 } -- Threshold Lines
      TH[13] = { 0.906, 0.463, 0.0, 0.9 } -- Transient Markers
      TH[14] = 5 -- Transient Markers Gradient Width (if Selected)
      TH[15] = 0.3 --Transient Markers Gradient Transparency (if Selected)
      TH[16] = 0 -- Transient Markers Gradient Width (0 - off)
      TH[17] = 0 --Transient Markers Gradient Transparency

      TH[18] = { 0.906, 0.463, 0.0, 0.1 } -- Sample Area if enabled

      TH[19] = { 0.906, 0.463, 0.0, 0.9 } -- Grid Markers

      TH[20] = { 0.8, 0.8, 0.8, 1 } -- Edit Cursor
      TH[21] = 4 -- Edit Cursor Gradient Width
      TH[22] = 0.1 --Edit Cursor Gradient Transparency

      TH[23] = { 0.031, 0.604, 0.765, 1 } -- Play Cursor
      TH[24] = 4 -- Play Cursor Gradient Width
      TH[25] = 0.1 --Play Cursor Gradient Transparency

      TH[26] = { 0.97, 0.97, 0, 0.5 } -- Aim Assist Cursor

      -------Buttons and Sliders ---------
      TH[27] = {0.3, 0.305, 0.31 ,1} -- Button Body
      TH[28] = {0.3, 0.305, 0.31 ,1} -- Button Frames
      
      TH[29] = {0.24, 0.25, 0.25,1} -- Slider Frames
      TH[30] = {0.24, 0.25, 0.25,1} -- Slider Body
      
      TH[31] = {0.32, 0.33, 0.33, 1} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.32, 0.33, 0.33, 1} -- Slider Body (Top, Loop and Swing)
      
      --------------Text--------------------
      TH[33] = { 0.9, 0.9, 0.9, 0.7 } -- Text Main
      TH[34] = { 1, 0.5, 0.3, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.45, 0.45, 0.45, 1 } -- Txt Greyed (BPM)
      TH[36] = { 0.55, 0.55, 0.55, 1 } -- Txt Greyed (Presets, Mode)      
      TH[37] = -0.1 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.9 -- BPM digits transparency

      -----------Elements------------------
      TH[39] =  { 0.808, 0.525, 0.098, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.22, 0.23, 0.23, 0.7 } -- Txt Brackets
      TH[41] = { 0.22, 0.23, 0.23, 0.7 } -- Main Separators
      TH[42] = 0.9 -- Leds Transparency (Controls Body)
      TH[43] = 0 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      --------------------------------------------------------------


      elseif Theme == 4 then 
      -------------------------Blue Lake------------------------------
      theme_name = "Blue Lake"
      -------Backgrounds and Frames-----------------
      TH[1] = {0.071, 0.227, 0.369,1} -- Waveform, Background Box
      TH[2] = {0.071, 0.227, 0.369,1} -- Waveform, Frame
      TH[3] = { 0.035, 0.137, 0.231} -- Main Background
      TH[4] = { 0.153, 0.216, 0.267, 1 } -- Controls Body
      TH[5] = { 0.22, 0.22, 0.22, 0 } -- Controls Frame

      -----------Waveforms---------------
      TH[6] = { 0.231, 0.62, 0.992,1 } -- Waveform, Filtered 
      TH[7] = {0.008, 0.188, 0.349,1} -- Waveform, Original 
      TH[8] = { 0.008, 0.188, 0.349,1 } -- Waveform, Draw original Only

      --------Waveform Lines--------------
      TH[9] = { 0.104, 0.731, 1.0, 1 } -- Ruler
      TH[10] = 4 -- Ruler Gradient Width (0 = off)
      TH[11] = 0.1 --Ruler Gradient Transparency

      TH[12] = { 0.98, 0.788, 0.008, 0.5 } -- Threshold Lines
      TH[13] = { 0.98, 0.788, 0.008, 0.9 } -- Transient Markers
      TH[14] = 5 -- Transient Markers Gradient Width (if Selected)
      TH[15] = 0.3 --Transient Markers Gradient Transparency (if Selected)
      TH[16] = 5 -- Transient Markers Gradient Width (0 - off)
      TH[17] = 0.05 --Transient Markers Gradient Transparency

      TH[18] = { 0.98, 0.788, 0.008, 0.12 } -- Sample Area if enabled

      TH[19] = { 0.98, 0.788, 0.008, 0.7 } -- Grid Markers
      
      TH[20] = { 0.8, 0.2, 0.2, 1 } -- Edit Cursor
      TH[21] = 5 -- Edit Cursor Gradient Width
      TH[22] = 0.4 --Edit Cursor Gradient Transparency

      TH[23] = { 0.5, 0.89608, 0.82941, 1 } -- Play Cursor
      TH[24] = 5 -- Play Cursor Gradient Width
      TH[25] = 0.2 --Play Cursor Gradient Transparency

      TH[26] = { 1, 1, 1, 0.5 } -- Aim Assist Cursor
      
      -------Buttons and Sliders ---------      
      TH[27] = {0.234, 0.32, 0.339 ,1} -- Button Body
      TH[28] = {0.234, 0.32, 0.339 ,1} -- Button Frames
      
      TH[29] = {0.224, 0.29, 0.329,1} -- Slider Frames
      TH[30] = {0.224, 0.29, 0.329,1} -- Slider Body
      
      TH[31] = {0.204, 0.27, 0.329, 1} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.204, 0.27, 0.329, 1} -- Slider Body (Top, Loop and Swing)
      
      --------------Text--------------------      
      TH[33] = { 0.65, 0.65, 0.65, 1 } -- Text Main
      TH[34] = { 0.894, 0.737, 0.235, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.45, 0.45, 0.45, 1 } -- Txt Greyed (BPM)
      TH[36] = { 0.45, 0.45, 0.45, 1 } -- Txt Greyed (Presets, Mode)
      TH[37] = 0 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.9 -- BPM digits transparency
     
      -----------Elements------------------
      TH[39] =  { 0.98, 0.788, 0.008, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.45, 0.45, 0.45, 0.5 } -- Txt Brackets
      TH[41] = { 0.45, 0.45, 0.45, 0.5 } -- Main Separators
      TH[42] = 0.9 -- Leds Transparency (Controls Body)
      TH[43] = 0.1 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      --------------------------------------------------------------


      elseif Theme == 5 then 
      -------------------------Fall------------------------------
      theme_name = "Fall"
      -------Backgrounds and Frames-----------------
      TH[1] = {0.169, 0.169, 0.169,1} -- Waveform, Background Box
      TH[2] = {0.172, 0.20, 0.215,1} -- Waveform, Frame
      TH[3] = { 0.533, 0.537, 0.537} -- Main Background
      TH[4] = { 0.651, 0.651, 0.651, 1 } -- Controls Body
      TH[5] = { 0.22, 0.22, 0.22, 0 } -- Controls Frame

      -----------Waveforms---------------
      TH[6] = {0.224, 0.62, 0.808,1} -- Waveform, Filtered 
      TH[7] = {0.19, 0.19, 0.19,1} -- Waveform, Original 
      TH[8] = { 0.294, 0.239, 0.192 ,1 } -- Waveform, Draw original Only

      --------Waveform Lines--------------
      TH[9] = { 0.7, 0.7, 0.8, 1 } -- Ruler
      TH[10] = 4 -- Ruler Gradient Width (0 = off)
      TH[11] = 0.05 --Ruler Gradient Transparency

      TH[12] = { 0.7, 0.7, 0.7, 0.4 } -- Threshold Lines
      TH[13] = { 0.9, 0.4, 0.1, 0.9 } -- Transient Markers
      TH[14] = 5 -- Transient Markers Gradient Width (if Selected)
      TH[15] = 0.3 --Transient Markers Gradient Transparency (if Selected)
      TH[16] = 0 -- Transient Markers Gradient Width (0 - off)
      TH[17] = 0 --Transient Markers Gradient Transparency

      TH[18] = { 0.9, 0.4, 0.1, 0.12 } -- Sample Area if enabled

      TH[19] = { 0.7, 0.7, 0.8, 0.7 } -- Grid Markers
      
      TH[20] = { 1.0, 0.9, 0.9, 1 } -- Edit Cursor
      TH[21] = 5 -- Edit Cursor Gradient Width
      TH[22] = 0.2 --Edit Cursor Gradient Transparency

      TH[23] = { 0.7, 0.7, 0.7, 1 } -- Play Cursor
      TH[24] = 5 -- Play Cursor Gradient Width
      TH[25] = 0.2 --Play Cursor Gradient Transparency

      TH[26] = { 0.9, 0.9, 1, 0.5 } -- Aim Assist Cursor
      
      -------Buttons and Sliders ---------      
      TH[27] = {0.3, 0.31 ,0.32 ,0} -- Button Body
      TH[28] = {0.15, 0.15, 0.15 ,1} -- Button Frames
      
      TH[29] = {0.28235, 0.32941, 0.34118,1} -- Slider Frames
      TH[30] = {0.859, 0.494, 0.161,1} -- Slider Body
      
      TH[31] = {0.32, 0.32, 0.32,1} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.32, 0.32, 0.32,1} -- Slider Body (Top, Loop and Swing)
      
      --------------Text--------------------      
      TH[33] = { 0.078, 0.078, 0.078, 1 } -- Text Main
      TH[34] = { 0.906, 0.524, 0.229, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.4, 0.4, 0.4, 0.7 } -- Txt Greyed (BPM)
      TH[36] = { 0.2, 0.2, 0.2, 0.7 } -- Txt Greyed (Presets, Mode)
      TH[37] = -0.32 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.8 -- BPM digits transparency

      -----------Elements------------------      
      TH[39] =  {0.9, 0.4, 0.1, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.3, 0.3, 0.3, 1 } -- Txt Brackets
      TH[41] = { 0.3, 0.3, 0.3, 1 } -- Main Separators
      TH[42] = 0.7 -- Leds Transparency (Controls Body)
      TH[43] = 0 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      --------------------------------------------------------------


      elseif Theme == 6 then 
      -------------------------Soft Dark--------------------------
      theme_name = "Soft Dark"
      -------Backgrounds and Frames-----------------
      TH[1] = {0.267, 0.267, 0.267,1} -- Waveform, Background Box
      TH[2] = {0.267, 0.267, 0.267,1} -- Waveform, Frame
      TH[3] = { 0.227, 0.227, 0.227} -- Main Background
      TH[4] = { 0.267, 0.267, 0.267, 1 } -- Controls Body
      TH[5] = { 0.28, 0.28, 0.28, 1 } -- Controls Frame

      -----------Waveforms---------------
      TH[6] = { 0.894, 0.447, 0.6,1 } -- Waveform, Filtered 
      TH[7] = {0.217, 0.217, 0.217,1} -- Waveform, Original 
      TH[8] = { 0.17, 0.17, 0.17,1 } -- Waveform, Draw original Only

      --------Waveform Lines--------------
      TH[9] = { 0.551, 0.696, 1, 1 } -- Ruler
      TH[10] = 4 -- Ruler Gradient Width (0 = off)
      TH[11] = 0.07 --Ruler Gradient Transparency

      TH[12] = { 0.882, 0.89, 0.447, 0.3 } -- Threshold Lines
      TH[13] = { 0.882, 0.89, 0.447, 0.8 } -- Transient Markers
      TH[14] = 5 -- Transient Markers Gradient Width (if Selected)
      TH[15] = 0.3 --Transient Markers Gradient Transparency (if Selected)
      TH[16] = 0 -- Transient Markers Gradient Width (0 - off)
      TH[17] = 0 --Transient Markers Gradient Transparency

      TH[18] = { 0.882, 0.89, 0.447, 0.12 } -- Sample Area if enabled

      TH[19] = { 0.2, 1, 0.5, 0.5 } -- Grid Markers

      TH[20] = { 0.8, 0.8, 0.8, 1 } -- Edit Cursor
      TH[21] = 5 -- Edit Cursor Gradient Width
      TH[22] = 0.2 --Edit Cursor Gradient Transparency

      TH[23] = { 0.451, 0.596, 0.906, 1 } -- Play Cursor
      TH[24] = 5 -- Play Cursor Gradient Width
      TH[25] = 0.2 --Play Cursor Gradient Transparency

      TH[26] = { 0.2, 1, 0.5, 0.5 } -- Aim Assist Cursor

      -------Buttons and Sliders ---------
      TH[27] = {0.2, 0.2 ,0.2 ,1} -- Button Body
      TH[28] = {0.2, 0.2 ,0.2 ,1} -- Button Frames
      
      TH[29] = {0.22, 0.22, 0.22,1} -- Slider Frames
      TH[30] = {0.22, 0.22, 0.22,1} -- Slider Body
      
      TH[31] = {0.32, 0.34, 0.34, 1} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.32, 0.34, 0.34, 1} -- Slider Body (Top, Loop and Swing)
      
      --------------Text--------------------
      TH[33] = { 0.55, 0.55, 0.55, 1 } -- Text Main
      TH[34] = { 0.551, 0.696, 1, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.45, 0.45, 0.45, 1 } -- Txt Greyed (BPM)
      TH[36] = { 0.45, 0.45, 0.45, 1 } -- Txt Greyed (Presets, Mode)
      TH[37] = -0.1 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.7 -- BPM digits transparency

      -----------Elements------------------
      TH[39] =  { 0.451, 0.596, 0.906, 0.7 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.9, 0.9, 0.9, 0.12 } -- Txt Brackets
      TH[41] = { 0.2, 0.2, 0.2, 0.7 } -- Main Separators
      TH[42] = 0.7 -- Leds Transparency (Controls Body)
      TH[43] = 0 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      --------------------------------------------------------------


elseif Theme == 7 then 
      --------------------------Graphite-------------------------------
      theme_name = "Graphite"
      -------Backgrounds and Frames-----------------
      TH[1] = {0.73, 0.75, 0.75,1} -- Waveform, Background Box
      TH[2] = {0.63, 0.65, 0.65,1} -- Waveform, Frame
      TH[3] = { 0.73, 0.75, 0.75} -- Main Background
      TH[4] = { 0.73, 0.75, 0.75, 1 } -- Controls Body
      TH[5] = { 0.22, 0.22, 0.22, 0 } -- Controls Frame

      -----------Waveforms---------------
      TH[6] = { 0.4, 0.306, 0.675 ,1 } -- Waveform, Filtered 
      TH[7] = {0.62,0.64,0.64,1} -- Waveform, Original 
      TH[8] = { 0.55, 0.57, 0.57 ,1 } -- Waveform, Draw original Only

      --------Waveform Lines--------------
      TH[9] = { 0.357, 0.267, 0.624, 1 } -- Ruler
      TH[10] = 4 -- Ruler Gradient Width (0 = off)
      TH[11] = 0.1 --Ruler Gradient Transparency

      TH[12] = { 0.1, 0.1, 0.1, 0.3 } -- Threshold Lines
      TH[13] = { 0.094, 0.094, 0.094, 0.7 } -- Transient Markers
      TH[14] = 5 -- Transient Markers Gradient Width (if Selected)
      TH[15] = 0.2 --Transient Markers Gradient Transparency (if Selected)
      TH[16] = 5 -- Transient Markers Gradient Width (0 - off)
      TH[17] = 0.05 --Transient Markers Gradient Transparency

      TH[18] = { 0.094, 0.094, 0.094, 0.12 } -- Sample Area if enabled

      TH[19] = { 0.1, 0.1, 0.1, 0.7 } -- Grid Markers
      
      TH[20] = { 0.82, 0.1, 0.0, 1 } -- Edit Cursor
      TH[21] = 4 -- Edit Cursor Gradient Width
      TH[22] = 0.1 --Edit Cursor Gradient Transparency

      TH[23] = { 0.82, 0.294, 0.0, 1 } -- Play Cursor
      TH[24] = 4 -- Play Cursor Gradient Width
      TH[25] = 0.1 --Play Cursor Gradient Transparency

      TH[26] = { 1, 1, 1, 0.75 } -- Aim Assist Cursor
      
      -------Buttons and Sliders ---------      
      TH[27] = {0.3, 0.31 ,0.32 ,0} -- Button Body
      TH[28] = {0.15, 0.15, 0.15 ,0.7} -- Button Frames
      
      TH[29] = {0.48, 0.49, 0.5, 0.7} -- Slider Frames
      TH[30] = {0.50, 0.52, 0.53,1} -- Slider Body
      
      TH[31] = {0.48, 0.49, 0.5, 0.7} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.45, 0.47, 0.48,1} -- Slider Body (Top, Loop and Swing)
      
      --------------Text--------------------      
      TH[33] = { 0.16, 0.16, 0.19, 1 } -- Text Main
      TH[34] = { 0.3, 0.2, 0.3, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.45, 0.45, 0.45, 1 } -- Txt Greyed (BPM)
      TH[36] = { 0.45, 0.45, 0.45, 1 } -- Txt Greyed (Presets, Mode)
      TH[37] = -0.3 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.8 -- BPM digits transparency
     
      -----------Elements------------------
      TH[39] =  {0.257, 0.167, 0.524 ,1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.15, 0.15, 0.15 ,0.7 } -- Txt Brackets
      TH[41] = { 0.15, 0.15, 0.15 ,0.7 } -- Main Separators
      TH[42] = 0.7 -- Leds Transparency (Controls Body)
      TH[43] = 1 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      --------------------------------------------------------------


elseif Theme == 8 then 
      -------------------------Clean------------------------------
      theme_name = "Clean"
      -------Backgrounds and Frames-----------------
      TH[1] = {0.95, 0.95, 0.95,1} -- Waveform, Background Box
      TH[2] = {0.071, 0.227, 0.369,0} -- Waveform, Frame
      TH[3] = { 0.835, 0.843, 0.839} -- Main Background
      TH[4] = { 0.941, 0.941, 0.941, 1 } -- Controls Body
      TH[5] = { 0.922, 0.91, 0.404, 0 } -- Controls Frame

      -----------Waveforms---------------
      TH[6] = { 0.349, 0.745, 0.302,1 } -- Waveform, Filtered 
      TH[7] = {0.90, 0.90, 0.90,0.07} -- Waveform, Original 
      TH[8] = { 0.843, 0.851, 0.961,1 } -- Waveform, Draw original Only

      --------Waveform Lines--------------
      TH[9] = { 0.1, 0.1, 0.1, 1 } -- Ruler
      TH[10] = 0 -- Ruler Gradient Width (0 = off)
      TH[11] = 0 --Ruler Gradient Transparency

      TH[12] = { 0.1, 0.1, 0.1, 0.15 } -- Threshold Lines
      TH[13] = { 0.1, 0.1, 0.1, 0.6 } -- Transient Markers
      TH[14] = 6 -- Transient Markers Gradient Width (if Selected)
      TH[15] = 0.12 --Transient Markers Gradient Transparency (if Selected)
      TH[16] = 0 -- Transient Markers Gradient Width (0 - off)
      TH[17] = 0 --Transient Markers Gradient Transparency

      TH[18] = { 0.1, 0.1, 0.1, 0.1 } -- Sample Area if enabled

      TH[19] = { 0.071, 0.451, 0.635, 0.7 } -- Grid Markers
      
      TH[20] = { 0.765, 0.384, 0.78, 0.7 } -- Edit Cursor
      TH[21] = 5 -- Edit Cursor Gradient Width
      TH[22] = 0.1 --Edit Cursor Gradient Transparency

      TH[23] = { 0.3, 0.78, 0.7, 0.7 } -- Play Cursor
      TH[24] = 5 -- Play Cursor Gradient Width
      TH[25] = 0.1 --Play Cursor Gradient Transparency

      TH[26] = {  0.337, 0.643, 0.792 ,1 } -- Aim Assist Cursor
      
      -------Buttons and Sliders ---------      
      TH[27] = {0.337, 0.643, 0.792 ,0.8} -- Button Body
      TH[28] = {0.337, 0.643, 0.792 ,0.8} -- Button Frames
      
      TH[29] = {0.953, 0.533, 0.267,0.8} -- Slider Frames
      TH[30] = {0.953, 0.533, 0.267,0.8} -- Slider Body
      
      TH[31] = {0.923, 0.503, 0.237, 0.8} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.923, 0.503, 0.237, 0.8} -- Slider Body (Top, Loop and Swing)
      
      --------------Text--------------------      
      TH[33] = { 0.2, 0.2, 0.2, 1 } -- Text Main
      TH[34] = { 0.922, 0.502, 0.235, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.45, 0.45, 0.45, 0.6 } -- Txt Greyed (BPM)
      TH[36] = { 0.40, 0.40, 0.40, 0.6 } -- Txt Greyed (Presets, Mode)
      TH[37] = -0.2 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.7 -- BPM digits transparency
     
      -----------Elements------------------
      TH[39] =  { 0.337, 0.451, 0.671, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.2, 0.2, 0.2, 0.2 } -- Txt Brackets
      TH[41] = { 0.2, 0.2, 0.2, 0.2 } -- Main Separators
      TH[42] = 0.7 -- Leds Transparency (Controls Body)
      TH[43] = 0 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      --------------------------------------------------------------

elseif Theme == 9 then 
      -------------------------Ink------------------------------
      theme_name = "Ink"
      -------Backgrounds and Frames-----------------
      TH[1] = {0.95, 0.95, 0.95,1} -- Waveform, Background Box
      TH[2] = {0.071, 0.227, 0.369,0} -- Waveform, Frame
      TH[3] = { 0.835, 0.843, 0.839} -- Main Background
      TH[4] = { 0.941, 0.941, 0.941, 1 } -- Controls Body
      TH[5] = { 0.922, 0.91, 0.404, 0 } -- Controls Frame

      -----------Waveforms---------------
      TH[6] = { 0.1, 0.1, 0.4,1 } -- Waveform, Filtered 
      TH[7] = {0.90, 0.90, 0.90,0.08} -- Waveform, Original 
      TH[8] = { 0.843, 0.851, 0.961,1 } -- Waveform, Draw original Only

      --------Waveform Lines--------------
      TH[9] = { 0.149, 0.145, 0.624, 1 } -- Ruler
      TH[10] = 0 -- Ruler Gradient Width (0 = off)
      TH[11] = 0 --Ruler Gradient Transparency

      TH[12] = { 0.1, 0.1, 0.1, 0.5 } -- Threshold Lines
      TH[13] = { 0.5, 0.5, 0.5, 1.5 } -- Transient Markers
      TH[14] = 5 -- Transient Markers Gradient Width (if Selected)
      TH[15] = 0.2 --Transient Markers Gradient Transparency (if Selected)
      TH[16] = 0 -- Transient Markers Gradient Width (0 - off)
      TH[17] = 0 --Transient Markers Gradient Transparency

      TH[18] = { 0.1, 0.1, 0.1, 1.35 } -- Sample Area if enabled

      TH[19] = { 0.965, 0.1, 0.1, 0.7 } -- Grid Markers
      
      TH[20] = { 0.965, 0.384, 0.98, 1 } -- Edit Cursor
      TH[21] = 5 -- Edit Cursor Gradient Width
      TH[22] = 0.1 --Edit Cursor Gradient Transparency

      TH[23] = { 0.3, 0.38, 0.3, 1 } -- Play Cursor
      TH[24] = 5 -- Play Cursor Gradient Width
      TH[25] = 0.1 --Play Cursor Gradient Transparency

      TH[26] = {  0.4, 0.4, 0.9, 1.5 } -- Aim Assist Cursor
      
      -------Buttons and Sliders ---------      
      TH[27] = {0.835, 0.843, 0.839 ,1} -- Button Body
      TH[28] = {0.565, 0.565, 0.565 ,1} -- Button Frames
      
      TH[29] = {0.565, 0.565, 0.565,1} -- Slider Frames
      TH[30] = {0.835, 0.843, 0.839,1} -- Slider Body
      
      TH[31] = {0.565, 0.565, 0.565, 1} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.735, 0.743, 0.739, 1} -- Slider Body (Top, Loop and Swing)
      
      --------------Text--------------------      
      TH[33] = { 0.142, 0.111, 0.566, 0.9 } -- Text Main
      TH[34] = { 0.604, 0.184, 0.545, 0.9 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.45, 0.45, 0.45, 0.7 } -- Txt Greyed (BPM)
      TH[36] = { 0.45, 0.45, 0.45, 0.7 } -- Txt Greyed (Presets, Mode)
      TH[37] = -0.32 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.7 -- BPM digits transparency
     
      -----------Elements------------------
      TH[39] =  { 0.149, 0.145, 0.624, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.2, 0.2, 0.2, 0.5 } -- Txt Brackets
      TH[41] = { 0.2, 0.2, 0.2, 0.5 } -- Main Separators
      TH[42] = 0.7 -- Leds Transparency (Controls Body)
      TH[43] = 0 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      --------------------------------------------------------------

      elseif Theme == 10 then 
      ------------------Slicer Classic---------------------------------
      theme_name = "Classic"
      -------Backgrounds and Frames-----------------
      TH[1] = { 0.122, 0.122, 0.122, 1 } -- Waveform, Background
      TH[2] = { 0, 0, 0, 0 } -- Waveform, Frame
      TH[3] = { 0.17647, 0.17647, 0.17647} -- Main Background
      TH[4] = { 0.17647, 0.17647, 0.17647, 1 } -- Controls Body
      TH[5] = { 0.22, 0.22, 0.22, 1 } -- Controls Frame

      -----------Waveforms---------------
      TH[6] = { 0.7, 0.2, 0.25, 1 } -- Waveform, Only filtered 
      TH[7] = { 0.14, 0.34, 0.59, 1 } -- Waveform, Only original 
      TH[8] = { 0.14, 0.34, 0.59, 1 } -- Waveform, Draw original Only

      --------Waveform Lines--------------
      TH[9] = { 0.1, 1, 0.1, 1 } -- Ruler 
      TH[10] = 0 -- Ruler Gradient Width (0 = off)
      TH[11] = 0 --Ruler Gradient Transparency

      TH[12] = { 0.7, 0.7, 0.7, 0.3 } -- Threshold Lines
      TH[13] = { 0.8, 0.8, 0, 0.95 } -- Transient Markers
      TH[14] = 5 -- Transient Markers Gradient Width (if Selected)
      TH[15] = 0.2 --Transient Markers Gradient Transparency (if Selected)
      TH[16] = 0 -- Transient Markers Gradient Width (0 - off)
      TH[17] = 0 --Transient Markers Gradient Transparency

      TH[18] = { 0.8, 0.8, 0, 0.1 } -- Sample Area if enabled

      TH[19] = { 0, 0.7, 0.7, 0.7 } -- Grid Markers

      TH[20] = { 0.7, 0.8, 0.9, 1 } -- Edit Cursor
      TH[21] = 5 -- Edit Cursor Gradient Width
      TH[22] = 0.2 --Edit Cursor Gradient Transparency

      TH[23] = { 0.5, 0.5, 1, 1 } -- Play Cursor
      TH[24] = 5 -- Play Cursor Gradient Width
      TH[25] = 0.2 --Play Cursor Gradient Transparency

      TH[26] = { 0.2, 1, 0.2, 0.7 } -- Aim Assist Cursor
      
      -------Buttons and Sliders ---------      
      TH[27] = { 0.3, 0.3 ,0.3 ,1 } -- Button Body
      TH[28] = { 0.3, 0.3, 0.3 ,1 } -- Button Frames
      
      TH[29] = {0.28,0.4,0.7,0.8} -- Slider Frames
      TH[30] = {0.28,0.4,0.7,0.8} -- Slider Body
      
      TH[31] = {0.28,0.4,0.7,0.8} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.28,0.4,0.7,0.8} -- Slider Body (Top, Loop and Swing)
      
      --------------Text--------------------      
      TH[33] = { 0.8, 0.8, 0.8, 0.9 } -- Text Color
      TH[34] = { 1, 0.5, 0.3, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 1, 1, 1, 0.2 } -- Txt Greyed (BPM)
      TH[36] = { 1, 1, 1, 0.25 } -- Txt Greyed (Presets, Mode)
      TH[37] = 0 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.9 -- BPM digits transparency
    
      -----------Elements------------------
      TH[39] =  { 0.0, 0.7, 0.0, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.4, 0.4, 0.4, 0.5 } -- Txt Brackets
      TH[41] = { 0.4, 0.4, 0.4, 0.5 } -- Main Separators
      TH[42] = 1 -- Leds Transparency (Controls Body)
      TH[43] = 0 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      --------------------------------------------------------------
      end
end

ThemeSel = tonumber(reaper.GetExtState('MK_Slicer_3','ThemeSel'))or 1;
Theming(ThemeSel)

--------------------------------End of Advanced User Settings------------------------------------------

----------------------------------------------------------------------------
-- Some functions(local functions work faster in big cicles(~30%)) -----
-- R.Ierusalimschy - "lua Performance Tips" ------------------------------
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
local fmod = math.fmod
-----------------------------------------------------------------------------
Slice_Status = 1
SliceQ_Status = 0
MarkersQ_Status = 0
Slice_Init_Status = 0
SliceQ_Init_Status = 0
Markers_Init_Status = 0
Markers_Status = 0
MIDISmplr_Status = 0
MIDIPitch_Status = 0
Trigg_Status = 0
Pitch_Det_Status = 0
Take_Check = 0
Reset_Status = 0
Random_Status = 0
MouseUpX = 0
MIDISampler = 0
Midi_sampler_offs_stat = 0
Pitch_Det_offs_stat = 0
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
ErrMsg_Status = 0
SetBPMButtonStatus = 0
SetBPMStatus_Reset = 0
SetBPMStatus_ResetRate = 0
TMInit_Status = 0
BPMButtonStatus2 = 0
Markers_BPM_Reset_Status = 0
Slice_BPM_Reset_Status = 0
Drag = 0
-----------------------------------States and UA  protection-----------------------------
Docked = tonumber(r.GetExtState('MK_Slicer_3','Docked'))or 0;
EscToExit = tonumber(r.GetExtState('MK_Slicer_3','EscToExit'))or 1;
MIDISamplerCopyFX = tonumber(r.GetExtState('MK_Slicer_3','MIDISamplerCopyFX'))or 1;
MIDISamplerCopyRouting = tonumber(r.GetExtState('MK_Slicer_3','MIDISamplerCopyRouting'))or 1;
MIDI_Mode = tonumber(r.GetExtState('MK_Slicer_3','Midi_Sampler.norm_val'))or 1;
Sampler_preset_state = tonumber(r.GetExtState('MK_Slicer_3','Sampler_preset.norm_val'))or 1; 
Create_Replace_state = tonumber(r.GetExtState('MK_Slicer_3','Create_Replace.norm_val'))or 1; 
Create_Replace_state2 = tonumber(r.GetExtState('MK_Slicer_3','Create_Replace2.norm_val'))or 1; 
Set_Rate_Feel_state = tonumber(r.GetExtState('MK_Slicer_3','Set_Rate_Feel.norm_val'))or 1; 
Set_Rate_Mode_state = tonumber(r.GetExtState('MK_Slicer_3','Set_Rate_Mode.norm_val'))or 1; 
Pitch_Det_Options_state = tonumber(r.GetExtState('MK_Slicer_3','Pitch_Det_Options.norm_val'))or 1;
Pitch_Det_Options_state2 = tonumber(r.GetExtState('MK_Slicer_3','Pitch_Det_Options2.norm_val'))or 1;
AutoScroll = tonumber(r.GetExtState('MK_Slicer_3','AutoScroll'))or 0;
PlayMode = tonumber(r.GetExtState('MK_Slicer_3','PlayMode'))or 0;
Snap_AutoPlay = tonumber(r.GetExtState('MK_Slicer_3','Snap_AutoPlay'))or 0;
Loop_on = tonumber(r.GetExtState('MK_Slicer_3','Loop_on'))or 1;
Snap_on = tonumber(r.GetExtState('MK_Slicer_3','Snap_on'))or 0;
Aim_on = tonumber(r.GetExtState('MK_Slicer_3','Aim_on'))or 0;

   if ForceSync == 1 then
       Sync_on = 1
         else
       Sync_on = tonumber(r.GetExtState('MK_Slicer_3','Sync_on'))or 0;
   end

ZeroCrossings = tonumber(r.GetExtState('MK_Slicer_3','ZeroCrossings'))or 0;
ItemFadesOverride = tonumber(r.GetExtState('MK_Slicer_3','ItemFadesOverride'))or 1;
ObeyingTheSelection = tonumber(r.GetExtState('MK_Slicer_3','ObeyingTheSelection'))or 1;
ObeyingItemSelection = tonumber(r.GetExtState('MK_Slicer_3','ObeyingItemSelection'))or 1;
XFadeOff = tonumber(r.GetExtState('MK_Slicer_3','XFadeOff'))or 0;
FontAntiAliasing = tonumber(r.GetExtState('MK_Slicer_3','FontAntiAliasing'))or 0;
Guides_mode = tonumber(r.GetExtState('MK_Slicer_3','Guides.norm_val'))or 1;

OutNote_State = tonumber(r.GetExtState('MK_Slicer_3','OutNote.norm_val'))or 1;
Notes_On = tonumber(r.GetExtState('MK_Slicer_3','Notes_On'))or 1;
VeloRng = tonumber(r.GetExtState('MK_Slicer_3','Gate_VeloScale.norm_val'))or 0.231;
VeloRng2 = tonumber(r.GetExtState('MK_Slicer_3','Gate_VeloScale.norm_val2'))or 1;
Random_Order = tonumber(r.GetExtState('MK_Slicer_3','Random_Order'))or 1;
Random_Vol = tonumber(r.GetExtState('MK_Slicer_3','Random_Vol'))or 0;
Random_Pan = tonumber(r.GetExtState('MK_Slicer_3','Random_Pan'))or 0;
Random_Pitch = tonumber(r.GetExtState('MK_Slicer_3','Random_Pitch'))or 0;
Random_Mute = tonumber(r.GetExtState('MK_Slicer_3','Random_Mute'))or 0;
Random_Position = tonumber(r.GetExtState('MK_Slicer_3','Random_Position'))or 0;
Random_Reverse = tonumber(r.GetExtState('MK_Slicer_3','Random_Reverse'))or 0;
RandV = tonumber(r.GetExtState('MK_Slicer_3','RandV_Sld.norm_val'))or 0.5;
RandPan = tonumber(r.GetExtState('MK_Slicer_3','RandPan_Sld.norm_val'))or 1;
RandPtch = tonumber(r.GetExtState('MK_Slicer_3','RandPtch_Sld.norm_val'))or 0.5;
RandPos = tonumber(r.GetExtState('MK_Slicer_3','RandPos_Sld.norm_val'))or 0.2;
RandRev = tonumber(r.GetExtState('MK_Slicer_3','RandRev_Sld.norm_val'))or 0.5;

if AutoXFadesOnSplitOverride == nil then AutoXFadesOnSplitOverride = 1 end 
if AutoXFadesOnSplitOverride <= 0 then AutoXFadesOnSplitOverride = 0 elseif AutoXFadesOnSplitOverride >= 1 then AutoXFadesOnSplitOverride = 1 end 
if RememberLast == nil then RememberLast = 1 end 
if RememberLast <= 0 then RememberLast = 0 elseif RememberLast >= 1 then RememberLast = 1 end 
if Compensate_Oct_Offset == nil then Compensate_Oct_Offset = 0 end 
if Compensate_Oct_Offset <= -4 then Compensate_Oct_Offset = -4 elseif Compensate_Oct_Offset >= 4 then Compensate_Oct_Offset = 4 end 
if WFiltering == nil then WFiltering = 1 end 
if WFiltering <= 0 then WFiltering = 0 elseif WFiltering >= 1 then WFiltering = 1 end 

---------------------------------------Check and Store Inits----------------------------------------------------------
function TransportStateInit()
local state
local transport = {}
state = r.GetToggleCommandStateEx( 0, 41834) -- get Option: "Toggle stop playback at end of loop if repeat is disabled"
   transport[1] = {state = state}
   transportstate_init = transport[1].state
end
TransportStateInit()

 repeatstate = r.GetToggleCommandStateEx( 0, 41834) -- get Option: "Toggle stop playback at end of loop if repeat is disabled"
 if repeatstate == 0 then
    r.Main_OnCommand(41834, 0) -- Option: "Toggle stop playback at end of loop if repeat is disabled"
 end

function TransportRepeatInit()
local state
local loop = {}
state = r.GetToggleCommandStateEx( 0, 1068) -- get Option: ""Transport: Toggle repeat"
   loop[1] = {state = state}
   repeatstate_init = loop[1].state
end
TransportRepeatInit()

 loopcheck = 0
----loopcheck------
local loopcheckstart, loopcheckending = r.GetSet_LoopTimeRange( 0, true, 0, 0, 0 )
if loopcheckstart == loopcheckending and loopcheckstart and loopcheckending then 
     loopcheck = 0
       else
     loopcheck = 1
end

function GetLoopTimeRangeInit()
   local st, en
   local selection = {st, en}
   st, en = r.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
   selection[1] = {st = st}
   selection[2] = {en = en}
   start_init = selection[1].st
   ending_init = selection[2].en
end
GetLoopTimeRangeInit()

if FontAntiAliasing == 1 then
    GFX2IMGUI_NO_LOG = true
    GFX2IMGUI_MAX_DRAW_CALLS = 1<<16
    local gfx2imgui_path = reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/gfx2imgui.lua'
    local os_sep = package.config:sub(1,1)
    gfx2imgui_path = gfx2imgui_path:gsub( "/", os_sep )
    if reaper.file_exists( gfx2imgui_path ) then
       gfx = dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/gfx2imgui.lua')
       RG_status = "(RealmGUI)"
       else
       RG_status = "(RealmGUI not installed)"
    end
else
RG_status = ""
end

----------------------------function GetLoopTimeRange-----------------------------
function GetLoopTimeRange()
  start, ending = r.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
end


-------------------------------Save and Restore Initial Rate and Length--------------------------------------------

function SaveInitRate() -- save rate/length
RateTable = {rate, init_length}
   local lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')
   local item =  r.BR_GetMediaItemByGUID( 0, lastitem )
       if item ~= nil then
               local take = r.GetActiveTake(item)
               local rate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
               local init_length    = r.GetMediaItemInfo_Value(item, "D_LENGTH")
               if rate == nil then rate = 1 end
               RateTable[1] = {rate = rate}
               RateTable[2] = {init_length = init_length}
        end             
end
-----------------
function RestoreInitRate()-- restore rate/length
   local lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')
   local item =  r.BR_GetMediaItemByGUID( 0, lastitem )
       if item ~= nil then
           local take = r.GetActiveTake(item)
           if RateTable ~= nil then
                 local it_rate = RateTable[1].rate -- first item start      
                 local init_length = RateTable[2].init_length -- first item start           
                 r.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", it_rate)
                 r.SetMediaItemInfo_Value(item, 'D_LENGTH', init_length)
                 if SetTkMarker == 1 then
                 r.DeleteTakeMarker(take, 0)
                 end
           end
       end
end

------------------------------------------------------------------------------------------

    r.Undo_BeginBlock() 
r.PreventUIRefresh(1)

-------------------------------Check time range and unselect-----------------------------
function unselect_if_out_of_time_range()

GetLoopTimeRange()

    if start == ending then return end;

    local CountSelItem = reaper.CountSelectedMediaItems(0)
    if CountSelItem == 0 then return end;

    for i = reaper.CountSelectedMediaItems(0)-1,0,-1 do;
        local SelItem = reaper.GetSelectedMediaItem(0,i);
        local PosIt = reaper.GetMediaItemInfo_Value(SelItem,"D_POSITION");
                     EndIt = PosIt + r.GetMediaItemInfo_Value(SelItem, "D_LENGTH")
        if (PosIt ~= start and EndIt ~= ending) and (PosIt < start or EndIt > ending) then;
            reaper.SetMediaItemInfo_Value(SelItem,"B_UISEL",0);
        end;
    end;

end
 
------------------------------Detect MIDI takes/Empty Items--------------------------------
function take_check()
local i=0;
while(true) do;
  i=i+1;
  local item = r.GetSelectedMediaItem(0,i-1);
  if item then;
  active_take = r.GetActiveTake(item)  -- active take in item
       if active_take  then
             if r.TakeIsMIDI(active_take) then 
              Take_Check = 1 -- MIDI Item
            end
       else
  --     Take_Check = 1 -- Empty Item
       end
  else;
    break;
  end;
end;

end

----------------------Select only tracks of selected items-----------------------------
function sel_tracks_items() --

  selected_items_count = r.CountSelectedMediaItems(0)

          UnselectAllTracks()
        
            for i = 0, selected_items_count - 1  do
                 item = r.GetSelectedMediaItem(0, i) -- Get selected item i
                 if item then 
                     track = r.GetMediaItem_Track(item)
                     r.SetTrackSelected(track, true)        
                 end  
           end
end

function UnselectAllTracks()
  first_track = r.GetTrack(0, 0)
          if first_track then
            r.SetOnlyTrackSelected(first_track)
            r.SetTrackSelected(first_track, false)
          end
end

------------------------Time Selection To Selected Items (First Track Only)------------------------
function TimeSelToFirstTrackItems()
::start::
local SelItems = {p0sition_b, ending_b}
local table_pos = 1 
local item, sel, track, p0sition, l3ngth, it_start, it_end, items_count, it_table
GetLoopTimeRange()
track = r.GetSelectedTrack(0,0,0) -- first selected track
    if track then
      items_count = r.CountTrackMediaItems(track)     
          for i=0, items_count-1 do
                  item = r.GetTrackMediaItem(track,i)
                  sel =  r.IsMediaItemSelected(item)
                  if item and sel == true then
   
                        p0sition    = r.GetMediaItemInfo_Value(item, "D_POSITION")
                        l3ngth = r.GetMediaItemInfo_Value(item, "D_LENGTH")
         
                         SelItems[table_pos] = {
                                     p0sition_b = p0sition,
                                     ending_b = p0sition+l3ngth
                                                }
                          table_pos = table_pos + 1
                   end
           end
   
      it_table = #SelItems
      for i = 1, it_table do
         it_start = SelItems[1].p0sition_b -- first item start
         it_end = SelItems[it_table].ending_b -- last item end
      end
   
         if it_start or it_end then
                r.GetSet_LoopTimeRange( 1, 0, it_start, it_end, 0 ) -- set loop/selection area
r.Main_OnCommand(40061, 0) -- Split at Time Selection
   
                if sel and ((it_start >= start and it_start < ending) or (it_end <= ending and it_end > start) or (it_start < start and it_end > ending)) and start ~= ending then -- if selection exist and outside the item
                    r.Main_OnCommand(40635, 0) -- Remove Time Selection
                    goto start
                end
         end
     end
end

------------Split items by time selection,unselect with items outside of time selection if there is selection inside-------
function SplitByTimeAndDeselect()
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
end


---------------------------------UnSelect MIDI And EmptyItems-----------------------------------------
function UnSelectMIDIAndEmptyItems()

r.Undo_BeginBlock();
r.PreventUIRefresh(1);
local cursorpos = r.GetCursorPosition()

local Empty_Item = 0
local MIDI_Item = 0
for i = 0, r.CountSelectedTracks(0)-1  do
local track = r.GetSelectedTrack(0, i)
     for k = 0, r.CountTrackMediaItems(track)-1 do
            local itm = r.GetTrackMediaItem(track, k)
            if itm then  
                 local take = r.GetActiveTake(itm)
   
                  if r.IsMediaItemSelected(itm) then
                          if take == nil then Empty_Item = 1 end
                          if take and r.TakeIsMIDI(take) == true then MIDI_Item = 1 end
                  
                          if (Empty_Item == 1 or MIDI_Item == 1) then
                             r.SetMediaItemSelected(itm, false) 
                             Empty_Item = 0
                             MIDI_Item = 0
                          end
                   end
            end
      end
end

r.SetEditCurPos(cursorpos,0,0)

r.PreventUIRefresh(-1);
r.Undo_EndBlock("UnSelect MIDI And EmptyItems",-1);
r.UpdateArrange()

end  
UnSelectMIDIAndEmptyItems()

---------------------------------Selective Glue Multitrack-----------------------------------------
function GlueMultitrack()
r.Undo_BeginBlock();
r.PreventUIRefresh(1);
local cursorpos = r.GetCursorPosition()

 -- r.Main_OnCommand(40290, 0) -- selection by items
  unselect_if_out_of_time_range()
  GetLoopTimeRange()
  
  function IsOneSelectedMediaItem(track)
    local sel_count, index, TakeFX = 0,0,0
    for i = 0, r.CountTrackMediaItems(track)-1 do
    local itm = r.GetTrackMediaItem(track, i)
    local item_pos =  r.GetMediaItemInfo_Value( itm, 'D_POSITION' )
    local item_end = item_pos + r.GetMediaItemInfo_Value( itm, 'D_LENGTH' )
    local take = r.GetActiveTake(itm)
 
       if take and r.IsMediaItemSelected(itm) then
           if r.TakeFX_GetCount(take) > 0 then TakeFX = 1 end
       end

            if r.IsMediaItemSelected(itm) and TakeFX ~= 1 then  -- if selected and no take fx
                if ((item_pos >= start and item_pos < ending) or (item_end <= ending and item_end > start) or (item_pos < start and item_end > ending)) or start == ending then
                    sel_count = sel_count + 1
                    if sel_count > 1 then return end
                    index = i
                end
            end 

    end
       if sel_count == 1 then return r.GetTrackMediaItem(track, index) end
  end
  
  for i = 0, r.CountSelectedTracks(0)-1  do
      local track = r.GetSelectedTrack(0, i)
      local item = IsOneSelectedMediaItem(track)
         if item then  
               r.SetMediaItemSelected(item, false) 
          end
  end

  UnSelectMIDIAndEmptyItems()
  if item or ObeyingItemSelection == 0 then 
     r.Main_OnCommand(40362, 0) -- glue
     r.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
     unselect_if_out_of_time_range()
     UnSelectMIDIAndEmptyItems()
  end

r.SetEditCurPos(cursorpos,0,0)

r.PreventUIRefresh(-1);
r.Undo_EndBlock("Glue Multitrack (skip single items)",-1);
r.UpdateArrange()

end  

---------------------------Get Track Number and Item Name to table----------------------------
local function InitTrackItemName()

     local track, track_num, item, take
     
     TableTI = {}
     
      track = r.GetSelectedTrack(0, 0)

      if not track then 
        track = r.GetTrack(0, 0)
            if track == nil then return end
            r.SetTrackSelected(track, true)
      end
 
      track_num = r.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
      TableTI.track  = ('%d'):format(track_num) -- convert 3.0 to 3

      item = r.GetSelectedMediaItem(0, 0)
      if item then
         take = r.GetActiveTake(item)
         if take then
                if Take_Check ~= 1 then -- if midi take, then return end
               TableTI.item = r.GetTakeName(take)
               else
     --          TableTI.item = 'MIDI'  
                  return
               end
         else
            TableTI.item = 'Empty Item'  
         end
      end

end

-------------------------------------Check Razor Edits------------------------------------
function RazorEditSelectionExists()
    for i=0, r.CountTracks(0)-1 do
        local retval, x = r.GetSetMediaTrackInfo_String(r.GetTrack(0,i), "P_RAZOREDITS", "string", false)
        if x ~= "" then return true end
    end--for   
    return false
end --RazorEditSelectionExists()

RE_exist = RazorEditSelectionExists()

if RE_exist == true then
r.PreventUIRefresh(1)
-------------------Razor edit - Set time selection to razor areas----------------------------------
left, right = math.huge, -math.huge
for t = 0, r.CountTracks(0)-1 do
    local track = r.GetTrack(0, t)
    local razorOK, razorStr = r.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    if razorOK and #razorStr ~= 0 then
        for razorLeft, razorRight, envGuid in razorStr:gmatch([[([%d%.]+) ([%d%.]+) "([^"]*)"]]) do
            local razorLeft, razorRight = tonumber(razorLeft), tonumber(razorRight)
            if razorLeft  < left  then left  = razorLeft end
            if razorRight > right then right = razorRight end
        end
    end
end
if left <= right then
    r.GetSet_LoopTimeRange2(0, true, false, left, right, false)
end

---------------------Select media items that overlap razor areas--------------------------------
for t = 0, r.CountTracks(0)-1 do
    local track = r.GetTrack(0, t)
    local tR = {}
    local razorOK, razorStr = r.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    if razorOK and #razorStr ~= 0 then
        for razorLeft, razorRight, envGuid in razorStr:gmatch([[([%d%.]+) ([%d%.]+) "([^"]*)"]]) do
            if envGuid == "" then
                local razorLeft, razorRight = tonumber(razorLeft), tonumber(razorRight)
                table.insert(tR, {left = razorLeft, right = razorRight})
            end
        end
    end
    for i = 0, r.CountTrackMediaItems(track)-1 do
        local item = r.GetTrackMediaItem(track, i)
        r.SetMediaItemSelected(item, false)
        local left = r.GetMediaItemInfo_Value(item, "D_POSITION")
        local right = left + r.GetMediaItemInfo_Value(item, "D_LENGTH")
        for _, rr in ipairs(tR) do
            if left < rr.right and right > rr.left then
                r.SetMediaItemSelected(item, true)
            end
        end
    end
end
--------------------------------------------------------------------------------------------------------------
            GetLoopTimeRange()
                  if start ~= ending then
                        r.Main_OnCommand(40061, 0) -- Split at Time Selection
                  --   r.Main_OnCommand(40635, 0) -- Remove Time Selection
                  unselect_if_out_of_time_range()
                  end
         
         sel_tracks_items()
         UnSelectMIDIAndEmptyItems()
         sel_tracks_items()

-----------------------------------------Set RE by Selected Items------------------------------------------         

         	r.Main_OnCommand(42406, 0) -- clear area sel
         	GetLoopTimeRange()
         	if start ~= ending then
         		local str_track_razor_edits = string.format([[%s %s '']], start, ending)	
         		for i = 0, r.CountSelectedTracks(0) - 1 do
         			local track = r.GetSelectedTrack(0, i)
         			r.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", str_track_razor_edits, true) -- set
         		end
         	end

         r.PreventUIRefresh(-1)
         r.UpdateArrange()
         
  else -- if not RE

            r.PreventUIRefresh(1)
            sel_tracks_items()

            GetLoopTimeRange()
                  if start ~= ending then -- if selection exist
                    --    TimeSelToFirstTrackItems()
                        r.Main_OnCommand(40061, 0) -- Split at Time Selection
                        TimeSelToFirstTrackItems()
                        UnSelectMIDIAndEmptyItems()
                  else -- if selection not exist
                        TimeSelToFirstTrackItems()
                        UnSelectMIDIAndEmptyItems()
                        GetLoopTimeRange() -- check again
                          if start ~= ending then -- if selection exist
                             r.Main_OnCommand(40061, 0) -- Split at Time Selection
                          end
                  end
                 unselect_if_out_of_time_range()
                 r.PreventUIRefresh(-1)
                 r.UpdateArrange()

end -- if RE_exist
---------------------------------------End of RE_Splits----------------------------------------

if ObeyingItemSelection == 1 then
sel_tracks_items()
end

InitTrackItemName() 

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
GetLoopTimeRange()
time_sel_length = ending - start
if ObeyingTheSelection == 1 and ObeyingItemSelection == 0 and start ~= ending then
    r.Main_OnCommand(40289, 0) -- Item: Unselect all items
          if time_sel_length >= 0.25 then
              r.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
              UnSelectMIDIAndEmptyItems()
          end
end

count_itms =  r.CountSelectedMediaItems(0)
if ObeyingTheSelection == 1 and count_itms ~= 0 and start ~= ending and time_sel_length >= 0.25 then
   take_check()
   if Take_Check ~= 1 then

    SplitByTimeAndDeselect()

    collect_param()  

        if number_of_takes ~= 1 and No_Heal_On_Init == 0 then
           r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то попытка не деструктивно склеить).
        end
  
       if number_of_takes ~= 1 and No_Glue_On_Init == 0 then -- проверяем ещё раз. Если не удалось, клеим деструктивно.
             GlueMultitrack()
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

    r.Undo_EndBlock("Init", -1) 

------------------------------Prepare Item(s) and Foolproof---------------------------------

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

if number_of_takes ~= 1 and No_Heal_On_Init == 0 then
     r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то клей, попытка не деструктивно склеить).
end

 if number_of_takes ~= 1 and No_Glue_On_Init == 0  then -- проверяем ещё раз. Если не удалось, клеим деструктивно.
             GlueMultitrack()
 end

r.Main_OnCommand(40635, 0) -- Remove Time Selection
r.PreventUIRefresh(-1)

r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTORESEL'), 0)  -- Restore track selection
----------------------------------Get States from last session-----------------------------

if RememberLast == 1 then
CrossfadeTime = tonumber(r.GetExtState('MK_Slicer_3','CrossfadeTime'))or 15;
PitchDetect = tonumber(r.GetExtState('MK_Slicer_3','PitchDetect'))or 5;
QuantizeStrength = tonumber(r.GetExtState('MK_Slicer_3','QuantizeStrength'))or 100;
Offs_Slider = tonumber(r.GetExtState('MK_Slicer_3','Offs_Slider'))or 0.5;
HF_Slider = tonumber(r.GetExtState('MK_Slicer_3','HF_Slider'))or 0.3312;
LF_Slider = tonumber(r.GetExtState('MK_Slicer_3','LF_Slider'))or 1;
Sens_Slider = tonumber(r.GetExtState('MK_Slicer_3','Sens_Slider'))or 0.63;
else
CrossfadeTime = DefaultXFadeTime or 15;
PitchDetect = DefaultP_Slider or 5;
QuantizeStrength = DefaultQStrength or 100;
Offs_Slider = DefaultOffset or 0.5;
HF_Slider = DefaultHP or 0.3312;
LF_Slider = DefaultLP or 1;
Sens_Slider = DefaultSens or 0.63;
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
----------------------------------FillGaps----------------------------------------------------------------------------
function FillGaps()
   local sel_item = {}
   local offs_table = {item_id, p0sition_id}
   local item_cnt = r.CountSelectedMediaItems(0)
   
     r.PreventUIRefresh(1)
     local trimstate = r.GetToggleCommandStateEx( 0, 41117) -- get Options: Toggle trim behind items state
     if trimstate == 1 then
       r.Main_OnCommand(41121, 0) -- Options: Disable trim behind items when editing
     end

     -----------------Collect Offset Data-----------------------------------------
     local num_items = reaper.CountSelectedMediaItems(0)
         for j = 1, num_items-1 do
                   item_id = r.GetSelectedMediaItem(0, j); 
                   p0sition_id = r.GetMediaItemInfo_Value(item_id, "D_POSITION")
         
            offs_table[j] = {
                   item_id = item_id,
                   p0sition_id = p0sition_id
                   }
         end
     --------------------------------------------------

     for i = 1, item_cnt do
       local item = r.GetSelectedMediaItem(0, 0)
       sel_item[i] = item
       r.SetMediaItemSelected(item, false)
     end
   
   local it_table = #sel_item
   
     for i = 2, it_table do
       local item = sel_item[i]
       local previousitem = sel_item[i-1]
   
      if r.GetMediaItem_Track(item) == r.GetMediaItem_Track(previousitem) then
         local secondstart = r.GetMediaItemInfo_Value(item, "D_POSITION")
         local firstend = r.GetMediaItemInfo_Value(previousitem, "D_POSITION") + r.GetMediaItemInfo_Value(previousitem, "D_LENGTH")
         if secondstart >= firstend then
   
                    r.SetMediaItemSelected(item, true)
                    r.ApplyNudge(0, 1, 1, 1, firstend, 0, 0)
                    r.SetMediaItemSelected(item, false)
   
           elseif firstend > secondstart then -- items are overlapping
             local overlap = firstend - secondstart
             if overlap > 0 then
   
                     r.SetMediaItemSelected(previousitem, true)
                     r.ApplyNudge(0, 1, 3, 1, secondstart, 0, 0)
                     r.SetMediaItemSelected(previousitem, false)

             end
         end
       end
     end
   
     if trimstate == 1 then
       r.Main_OnCommand(41120,0) -- Re-enable trim behind items (if it was enabled)
     end
   
   local it_table2 = #sel_item
       for i = 1, it_table2 do
         r.SetMediaItemSelected(sel_item[i], true)
       end

      ----------------------Set Offset Through Tracks---------------------
      items2 = #offs_table 
                for k=1, items2 do
                     if item_id ~= nil then 
       
                        item_offs2 = offs_table[k].item_id                   
                        p0sition_offs2 = offs_table[k].p0sition_id 
              
                            if item_offs2 ~= nil and p0sition_offs2 ~= nil then
                                local newstart = r.GetMediaItemInfo_Value(item_offs2, "D_POSITION")
                                set_offs = p0sition_offs2-newstart
                                r.SetMediaItemInfo_Value(item_offs2, "D_SNAPOFFSET", set_offs)
                            end
                      end
                end
     -------------------------------------------------------------------------

     r.PreventUIRefresh(-1)
     r.UpdateArrange()
end


----------------------------------Crossfades-------------------------------------------
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
                if take then
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
                end
            else;
                t[tostring(trackIt)] = trackIt;
            end;
        end;
        if ret == 1 then r.Main_OnCommand(41059,0) end;
        return ret or 0;
    end;
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
function beatc(beatpos)
   local retval, measures, cml, fullbeats, cdenom = r.TimeMap2_timeToBeats(0, beatpos)
   local _, division, _, _ = r.GetSetProjectGrid(0,false)
   if division < 0.0078125 then division = 0.0078125 end
   beatpos = r.TimeMap2_beatsToTime(0, fullbeats +(division*4))
   return beatpos
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
    retrigms = 0.1703 -- 30ms retrig
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



----------------------- Global Elem Position and Width-------------------

----------Get Item Block-------------------
a_pos = 16 
a_width = 145

----------Sliders Block----------------------
b_pos = 171
b_width = 150

----------Divider Line1---------------------
dl1_pos = 330

----------Slice/Q/Random  Block----------
c_pos = -60 -- global shift only

----------Divider Line2---------------------
dl2_pos = 600

----------MIDI Block------------------------
d_pos = -60 -- global shift only

----------Divider Line3---------------------
dl3_pos = 882

----------BPM Block------------------------
e_pos = -60 -- global shift only

----------Global Vertical Correction-------
corrY = 10 -- global shift only

--------------------------------------------------------------------------------
---------------------Retina Check---------------------------------------------
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
  return ((num * mult + 0.5)//1) / mult
end
---------------------------------------------------------------
----------------------Find Even/Odd--------------------------
---------------------------------------------------------------
function IsEven(num)
  return num % 2 == 0
end
---------------------------------------------------------------
----------------------Text Shortener-------------------------
---------------------------------------------------------------
function TextShort(stext, limit) -- stext - text input, limit - number of characters
    local symbols_count = #stext
    if symbols_count >= limit then
        stext = stext:sub(1, symbols_count-(symbols_count-limit))
        else
        stext = stext
    end
        return stext
end
--------------------------------------------------------------------------------
---   Simple Element Class   --------------------------------------------------
--------------------------------------------------------------------------------
local Element = {}
function Element:new(x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, norm_val,norm_val2, fnt_rgba)
    local elm = {}
    elm.def_xywh = {x,y,w,h,fnt_sz} -- its default coord,used for Zoom etc
    elm.x, elm.y, elm.w, elm.h = x, y, w, h
    elm.r, elm.g, elm.b, elm.a = r, g, b, a
    elm.lbl, elm.fnt, elm.fnt_sz = lbl, fnt, fnt_sz
    elm.fnt_rgba = fnt_rgba or { TH[33][1], TH[33][2], TH[33][3], TH[33][4] } --цвет текста кнопок, фреймов и слайдеров
    elm.norm_val = norm_val
    elm.norm_val2 = norm_val2
    ------
    setmetatable(elm, self)
    self.__index = self 
    return elm
end

---------------------------------------------------------------
--- Function for Child Classes(args = Child,Parent Class) ---
---------------------------------------------------------------
function extended(Child, Parent)
  setmetatable(Child,{__index = Parent}) 
end
--------------------------------------------------------------
---   Element Class Methods(Main Methods)   -------------
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
--------
function Element:mouseRClick()
  return gfx.mouse_cap&2==0 and last_mouse_cap&2==2 and
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
    local an = TH[29][4]
    if self:mouseIN() then an=an+0.1 end
    if self:mouseDown() then an=an+0.1 end
  gfx.set(TH[29][1],TH[29][2],TH[29][3],an) -- sliders and checkboxes borders
  gfx.rect(x, y, w, h, false)            -- frame1      
end

function Element:draw_frame_sw()
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local an = TH[29][4]
    if self:mouseIN() then an=an+0.1 end
    if self:mouseDown() then an=an+0.1 end
  gfx.set(TH[31][1],TH[31][2],TH[31][3],an) -- swing slider borders
  gfx.rect(x, y, w, h, false)            -- frame1      
end

function Element:draw_frame_rng() -- range slider
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local an = TH[30][4]
    local rn = TH[30][1]
    local gn = TH[30][2]
    local bn = TH[30][3]
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
  gfx.set(0.3,0.3,0.35,0.2) -- loop slider background
  gfx.rect(x, y, w, h, true)            -- frame1      
end

function Element:draw_frame2()
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
  gfx.set(TH[40][1],TH[40][2],TH[40][3],TH[40][4]) -- brackets
  gfx.rect(x, y, w, h, false)            -- frame1      
end

function Element:draw_frame3()
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
  gfx.set(TH[28][1],TH[28][2],TH[28][3],TH[28][4]) -- waveform window and buttons frames
  gfx.rect(x, y, w, h, false)            -- frame1      
end

function Element:draw_frame4()
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
  gfx.set(TH[4][1],TH[4][2],TH[4][3],TH[4][4]) -- main frame body
  gfx.rect(x, y, w, h, true)            -- frame1   
end

function Element:draw_frame5()
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
  gfx.set(TH[5][1],TH[5][2],TH[5][3],TH[5][4]) -- main frame
  gfx.rect(x, y, w, h, false)            -- frame1     
end

function Element:draw_frame_waveform()
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
  gfx.set(TH[2][1],TH[2][2],TH[2][3],TH[2][4]) -- main frame
  gfx.rect(x, y, w, h, false)            -- frame1     
end

function Element:draw_frame_filled()
  local x,y,w,h  = self.x,self.y,self.w,self.h
  gfx.rect(x, y, w, h, true)            -- filled areas      
end

function Element:draw_rect()
  local x,y,w,h  = self.x,self.y,self.w,self.h
  gfx.set(TH[1][1],TH[1][2],TH[1][3],TH[1][4]) -- цвет фона окна waveform
  gfx.rect(x, y, w, h, true)            -- frame1      
end

function Element:draw_rect_ruler()
  local x,y,w,h  = self.x,self.y,self.w,self.h
  gfx.set(0.122,0.122,0.122,0.3) -- 
  gfx.rect(x, y, w, h, true)            -- frame1      
end

----------------------------------------------------------------------------------------------------
---   Create Element Child Classes(Button,Slider,Knob)   ----------------------------------------
----------------------------------------------------------------------------------------------------
  local Button, Button_small, Button_top, Button_Settings, Slider, Slider_small, Slider_simple, Slider_complex, Slider_Fine, Slider_Swing, Slider_fgain, Rng_Slider, Knob, CheckBox, CheckBox_simple, CheckBox_Show, Frame_body, Frame, Colored_Rect, Colored_Rect_top, Frame_filled, ErrMsg, SysMsg, Txt, Txt2, Line, Line_colored, Line2, Ruler = {},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}
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
  extended(SysMsg,     Element)
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
  extended(Frame_body,      Element)
  extended(Frame,      Element)
  extended(Colored_Rect,      Element)
  extended(Colored_Rect_top,      Element)
  extended(Frame_filled,      Element)
  extended(CheckBox,   Element)
  extended(CheckBox_simple,   Element)
  extended(CheckBox_Show,   Element)
 
--------------------------------------------------------------------------------
---   Buttons Class Methods   ------------------------------------------------
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
    gfx.set(TH[36][1],TH[36][2],TH[36][3],TH[36][4])    -- set body color
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
  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = (self.def_xywh[1]* Z_w) , (self.def_xywh[3]* Z_w) -- upd x,w
  self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* Z_h) -- upd y,h

    local r,g,b,a  = self.r,self.g,self.b,self.a
    local x,y,w,h  = self.x,self.y/6,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
         gfx.x = x+(w-lbl_w)/3.5
         gfx.y = (y+(h-lbl_h)/50)-5

  local  fnt_sz = 0

        if fnt_sz < 16 then fnt_sz = 16 end
        if fnt_sz > 22 then fnt_sz = 22 end

        fnt_sz = fnt_sz*(Z_h*1.05)
        gfx.setfont(1, "Arial", fnt_sz)

    gfx.set(TH[34][1], TH[34][2], TH[34][3], TH[34][4]) -- цвет текста 
        gfx.drawstr(self.lbl, 0|4, 900*Z_w, (50/(Z_h*8))+(22*Z_h))

end
----------------------SysMsg-----------------------------------------------------

function SysMsg:draw()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = (self.def_xywh[1]* Z_w) , (self.def_xywh[3]* Z_w) -- upd x,w
  self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* Z_h) -- upd y,h

    local r,g,b,a  = self.r,self.g,self.b,self.a
    local x,y,w,h  = self.x,self.y/6,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
         gfx.x = x+(w-lbl_w)/3.5
         gfx.y = (y+(h-lbl_h)/50)-2

     local xc = 0
     local  fnt_sz = 0
     local symbols_count = #TableTI.item
     if symbols_count >= 50 then -- sc limit
         symbols_count = symbols_count-(symbols_count-50)
     end

      if  Swing_on == 1 then 
         xc = 100*Z_w  
          else
         xc = 0 
      end

      if fnt_sz < 16 then fnt_sz = 16 end
      if fnt_sz > 22 then fnt_sz = 22 end

      fnt_sz = fnt_sz*(Z_h*1.05)
      gfx.setfont(1, "Arial", fnt_sz)

      gfx.x = gfx.x-(fnt_sz*4)

      if symbols_count > 20 then
          if gfx.x < (35-(symbols_count/4))*(fnt_sz*2) then 
          gfx.x = xc+450*Z_w 
          else
            if fnt_sz > 20 and Swing_on == 0 then
              gfx.x = gfx.x-(fnt_sz*4)
            end
          end
      end

    gfx.set(TH[33][1], TH[33][2], TH[33][3], TH[33][4]) -- цвет текста 
        gfx.drawstr(self.lbl, 0|4, 900*Z_w, (50/(Z_h*8))+(22*Z_h))
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
    if gfx.mouse_wheel == 0 then Slider_Status = 0; return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1); Slider_Status = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0); Slider_Status = 1 end
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
    if gfx.mouse_wheel == 0 then Slider_Status = 0; return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1); Slider_Status = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0); Slider_Status = 1 end
    return true
end

function Slider_Fine:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.0005 -- Set step
    else
    Mult_S = 0.005 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then Slider_Status = 0; return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1); Slider_Status = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0); Slider_Status = 1 end
    return true
end

function Slider_Swing:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.005 -- Set step
    else
    Mult_S = 0.05 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then Slider_Status = 0; return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step+0.00001, 1); Slider_Status = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step+0.00001, 0); Slider_Status = 1 end
    return true
end

function Slider_fgain:set_norm_val_m_wheel()
    if Shift == true then
    Mult_S = 0.005 -- Set step
    else
    Mult_S = 0.05 -- Set step
    end
    local Step = Mult_S
    if gfx.mouse_wheel == 0 then Slider_Status = 0; return false end  -- return if m_wheel = 0
    if gfx.mouse_wheel > 0 then self.norm_val = min(self.norm_val+Step, 1); Slider_Status = 1 end
    if gfx.mouse_wheel < 0 then self.norm_val = max(self.norm_val-Step, 0); Slider_Status = 1 end
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
    DefaultHP = tonumber(r.GetExtState('MK_Slicer_3','DefaultHP'))or 0.3312;
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
    DefaultLP = tonumber(r.GetExtState('MK_Slicer_3','DefaultLP'))or 1;
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
    DefaultSens = tonumber(r.GetExtState('MK_Slicer_3','DefaultSens'))or 0.63;
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
    DefaultOffset = tonumber(r.GetExtState('MK_Slicer_3','DefaultOffset'))or 0.5;
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
    DefaultQStrength = tonumber(r.GetExtState('MK_Slicer_3','DefaultQStrength'))or 100;
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
    DefaultXFadeTime = tonumber(r.GetExtState('MK_Slicer_3','DefaultXFadeTime'))or 15;
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
           if elapsed ~= timer2 then
                  elapsed = reaper.time_precise() - time_start
                 if elapsed >= timer2 then   
                     runcheck = 0
                     if gfx.mouse_wheel == 0 then 
                        MW_doit_slider(1) --------- main function
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
             Slider_Status = 1 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             MouseUpX = 1
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
             Slider_Status = 0 
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
           if elapsed ~= timer2 then
                  elapsed = reaper.time_precise() - time_start
                 if elapsed >= timer2 then   
                     runcheck = 0
                     if gfx.mouse_wheel == 0 then 
                        MW_doit_slider_Fine(1)  --------- main function
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
             Slider_Status = 1 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             MouseUpX = 1
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
             Slider_Status = 0 
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
function Slider_Swing:draw() -- Swing slider
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
             Slider_Status = 1 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             MouseUpX = 1
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
             Slider_Status = 0 
          end    
    -- Draw sldr body, frame ---
    gfx.set(r,g,b,a)  -- set body,frame color
    self:draw_body()  -- body
    self:draw_frame_sw() -- frame
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
           if elapsed ~= timer2 then
                  elapsed = reaper.time_precise() - time_start
                 if elapsed >= timer2 then   
                     runcheck_c = 0
                     if gfx.mouse_wheel == 0 then 
                          MW_doit_slider_comlpex(1)  --------- main function
                     end
                     return
                 else
                 runcheck_c = 1 
                     reaper.defer(Main_Timer)
                 end
            end
         end
             
       if runcheck_c ~= 1 then
           Main_Timer()
       end
 ---------------------------------------------------------
             end  
          end
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.3 
             self:set_norm_val()
             if self.onMove then self.onMove() end 
             Slider_Status = 1 
          end
          --in elm L_up(released and was previously pressed)--
          --if self:mouseClick() then --[[self.onClick()]] end
          -- L_up released(and was previously pressed in elm)--
          if self:mouseUp() and self.onUp then self.onUp()
             MouseUpX = 1
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
             Slider_Status = 0
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
           if elapsed ~= timer2 then
                  elapsed = reaper.time_precise() - time_start
                 if elapsed >= timer2 then   
                     runcheck = 0
                     if gfx.mouse_wheel == 0 then 
                           MW_doit_slider_fgain(1)   --------- main function
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
---   Rng_Slider Class Methods   ---------------------------------------------
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
    gfx.set(TH[30][1]/1.2,TH[30][2]/1.2,TH[30][3]/1.2,TH[30][4])  -- sbtns body color
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
    self.sb_w  = self.w//10 -- sidebuttons width(change it if need)
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
---   Loop_Slider Class Methods   --------------------------------------------
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
    gfx.set(TH[39][1],TH[39][2],TH[39][3],TH[39][4])  -- sbtns body color
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
---   CheckBox Class Methods   ----------------------------------------------
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
 --   gfx.drawstr(val) -- draw checkbox val
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
          a=a-0.6
          if self:mouseIN() then a=a+0.3
             if self:set_norm_val_m_wheel() then -- use if need
                if self.onMove then self.onMove() end   
                      MW_doit_checkbox_show()
            end  
          end          
          -- in elm L_down -----
          if self:mouseDown() then a=a+0.4 end
          -- in elm L_up(released and was previously pressed) --
          if self:mouseClick() then self:set_norm_val()
             if self:mouseClick() and self.onClick then self.onClick() end
          end
    -- Draw ch_box body, frame -
    gfx.set(r,g,b,a)    -- set body color
    self:draw_body()    -- body
 --   self:draw_frame()   -- frame
    -- Draw label --------------
    gfx.set(table.unpack(self.fnt_rgba))   -- set label,val color
    gfx.setfont(1, fnt, fnt_sz) -- set label,val fnt
    self:draw_lbl()             -- draw lbl
    self:draw_val()             -- draw val
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Frame Class Methods  --------------------------------------------------
--------------------------------------------------------------------------------
function Frame_body:draw()
   self:update_xywh() -- Update xywh(if wind changed)
   local r,g,b,a  = self.r,self.g,self.b,self.a
   gfx.set(r,g,b,a)   -- set frame color -- цвет рамок
   self:draw_frame4()  -- draw frame body
end

function Frame:draw()
   self:update_xywh() -- Update xywh(if wind changed)
   local r,g,b,a  = self.r,self.g,self.b,self.a
   gfx.set(r,g,b,a)   -- set frame color -- цвет рамок
   self:draw_frame5()  -- draw frame
end

--------------------------------------------------------------------------------
---   Frame Class Methods  --------------------------------------------------
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
---   Frame_filled Class Methods  --------------------------------------------
--------------------------------------------------------------------------------
function Frame_filled:draw()
   self:update_xywh() -- Update xywh(if wind changed)
   local r,g,b,a  = self.r,self.g,self.b,self.a
   gfx.set(r,g,b,a)   -- set frame color -- цвет рамок
   self:draw_frame_filled()  -- draw frame
end

----------------------------------------------------------------------------------------------------
--   Some Default Values   -----------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

function Init_Srate()

local init_item = r.GetSelectedMediaItem(0,0)

      if init_item  then
            local init_take = r.GetActiveTake(init_item)
               if init_take ~= nil then 
              
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
end

Init_Srate() -- Project Samplerate


local block_size = 1024*16 -- размер блока(для фильтра и тп) , don't change it!
local time_limit = 5*60    -- limit maximum time, change, if need.
local defPPQ = 960         -- change, if need.
----------------------------------------------------------------------------------------------------
---  Create main objects(Wave,Gate) -----------------------------------------------------------
----------------------------------------------------------------------------------------------------
local Wave = Element:new(10,45,1024,335)
local Gate_Gl  = {}

---------------------------------------------------------------
---  Create Frames ------------------------------------------
---------------------------------------------------------------
------local tables to reduce locals (avoid 200 locals limits)-------
local elm_table = {Fltr_Frame, Gate_Frame, Mode_Frame, Mode_Frame_filled, Gate_Frame_filled, Random_Setup_Frame_filled, Random_Setup_Frame, Grid1_Led, Grid2_Led, Grid4_Led, Grid8_Led, Grid16_Led, Grid32_Led, Grid64_Led, GridT_Led, Swing_Led, MIDI_Divider_Line, MIDI_Divider_Line2, BPM_Divider_Line, BPM_Divider_Line2, Frame}

elm_table[1] = Frame_body:new(10, 385,1024,100) --Main_Frame_body

elm_table[2] = Line2:new(dl1_pos,380+corrY,4,88, TH[41][1],TH[41][2],TH[41][3],TH[41][4]) -- Vertical Line
elm_table[3] = Line2:new(dl1_pos+1,380+corrY,4,88, TH[4][1],TH[4][2],TH[4][3],TH[4][4])--| fill

elm_table[4] = Frame_filled:new(669+d_pos,380+corrY,279,69,  TH[4][1],TH[4][2],TH[4][3],TH[4][4]-0.4 ) --Mode_Frame_filled
elm_table[5] = Frame_filled:new(b_pos,380+corrY,160,89,  TH[4][1],TH[4][2],TH[4][3],TH[4][4]-0.4 ) --Gate_Frame_filled

elm_table[6] = Frame_filled:new(656+c_pos,376,147,112,  TH[4][1],TH[4][2],TH[4][3],TH[4][4] ) --Random_Setup_Frame_filled
elm_table[7] = Line:new(656+c_pos,376,147,112,  TH[5][1],TH[5][2],TH[5][3],TH[5][4] ) --Random_Setup_Frame

elm_table[8] = Colored_Rect_top:new(50,24,40,2,  TH[39][1],TH[39][2],TH[39][3],TH[39][4] ) -- Grid1_Led
elm_table[9] = Colored_Rect_top:new(92,24,40,2,  TH[39][1],TH[39][2],TH[39][3],TH[39][4] ) -- Grid2_Led
elm_table[10] = Colored_Rect_top:new(134,24,40,2,  TH[39][1],TH[39][2],TH[39][3],TH[39][4] ) -- Grid4_Led
elm_table[11] = Colored_Rect_top:new(176,24,40,2,  TH[39][1],TH[39][2],TH[39][3],TH[39][4] ) -- Grid8_Led
elm_table[12] = Colored_Rect_top:new(218,24,40,2,  TH[39][1],TH[39][2],TH[39][3],TH[39][4] ) -- Grid16_Led
elm_table[13] = Colored_Rect_top:new(260,24,40,2,  TH[39][1],TH[39][2],TH[39][3],TH[39][4] ) -- Grid32_Led
elm_table[14] = Colored_Rect_top:new(302,24,40,2,  TH[39][1],TH[39][2],TH[39][3],TH[39][4] ) -- Grid64_Led
elm_table[15] = Colored_Rect_top:new(344,24,40,2,  TH[39][1],TH[39][2],TH[39][3],TH[39][4] ) -- GridT_Led
elm_table[16] = Colored_Rect_top:new(391,24,50,2,  TH[39][1],TH[39][2],TH[39][3],TH[39][4] ) -- Swing_Led

elm_table[17] = Line2:new(dl2_pos,380+corrY,4,88, TH[41][1],TH[41][2],TH[41][3],TH[41][4]) -- Vertical Line2 
elm_table[18] = Line2:new(dl2_pos+1,380+corrY,4,88, TH[4][1],TH[4][2],TH[4][3],TH[4][4])--| fill

elm_table[19] = Line2:new(dl3_pos,380+corrY,4,88, TH[41][1],TH[41][2],TH[41][3],TH[41][4]) -- Vertical Line3 
elm_table[20] = Line2:new(dl3_pos+1,380+corrY,4,88, TH[4][1],TH[4][2],TH[4][3],TH[4][4])--| fill

elm_table[21] = Frame:new(10, 385,1024,100) --Main_Frame

local leds_table = {Frame_byGrid, Frame_byGrid2, Light_Loop_on, Light_Loop_off, Light_Snap_on, Light_Snap_off, Rand_Mode_Color1, Rand_Mode_Color2, Rand_Mode_Color3, Rand_Mode_Color4, Rand_Mode_Color5, Rand_Mode_Color6, Rand_Mode_Color7, Rand_Button_Color1, Rand_Button_Color2, Rand_Button_Color3, Rand_Button_Color4, Rand_Button_Color5, Rand_Button_Color6, Rand_Button_Color7, MIDIMode1, MIDIMode2, MIDIMode3, Light_Aim_on, Light_Aim_off}

leds_table[1] = Colored_Rect:new(577+c_pos,410+corrY,2,18,  0.1,0.7,0.6,TH[42] ) -- Frame_byGrid (Blue indicator)
leds_table[2] = Colored_Rect:new(577+c_pos,410+corrY,2,18,  0.7,0.7,0.0,TH[42] ) -- Frame_byGrid2 (Yellow indicator)

leds_table[3] = Colored_Rect_top:new(983,5,2,20,  TH[39][1],TH[39][2],TH[39][3],TH[39][4] ) -- Light_Loop_on
leds_table[4] = Colored_Rect_top:new(983,5,2,20,  0.5,0.5,0.5,0.5 ) -- Light_Loop_off

leds_table[5] = Colored_Rect_top:new(950,5,2,20,  TH[39][1],TH[39][2],TH[39][3],TH[39][4] ) -- Light_Snap_on
leds_table[6] = Colored_Rect_top:new(950,5,2,20,  0.5,0.5,0.5,0.5 ) -- Light_Snap_off

leds_table[7] = Colored_Rect:new(661+c_pos,380,2,14,  0.1,0.8,0.2,TH[42] ) --  Rand_Mode_Color1
leds_table[8] = Colored_Rect:new(661+c_pos,395,2,14,  0.7,0.7,0.0,TH[42] ) --  Rand_Mode_Color2
leds_table[9] = Colored_Rect:new(661+c_pos,410,2,14,  0.8,0.4,0.1,TH[42] ) --  Rand_Mode_Color3
leds_table[10] = Colored_Rect:new(661+c_pos,425,2,14,  0.7,0.0,0.0,TH[42] ) --  Rand_Mode_Color4
leds_table[11] = Colored_Rect:new(661+c_pos,455,2,14,  0.2,0.5,1,TH[42] ) --  Rand_Mode_Color5
leds_table[12] = Colored_Rect:new(661+c_pos,440,2,14,  0.8,0.1,0.8,TH[42] ) --  Rand_Mode_Color6
leds_table[13] = Colored_Rect:new(661+c_pos,470,2,14,  0.1,0.7,0.6,TH[42] ) --  Rand_Mode_Color7

leds_table[14] = Colored_Rect:new(584+c_pos,426+corrY,8,2,  0.1,0.8,0.2,TH[42] ) --  Rand_Button_Color1
leds_table[15] = Colored_Rect:new(593+c_pos,426+corrY,9,2,  0.7,0.7,0.0,TH[42] ) --  Rand_Button_Color2
leds_table[16] = Colored_Rect:new(603+c_pos,426+corrY,9,2,  0.8,0.4,0.1,TH[42] ) --  Rand_Button_Color3
leds_table[17] = Colored_Rect:new(613+c_pos,426+corrY,9,2,  0.7,0.0,0.0,TH[42] ) --  Rand_Button_Color4
leds_table[18] = Colored_Rect:new(633+c_pos,426+corrY,9,2,  0.2,0.5,1,TH[42] ) --  Rand_Button_Color5
leds_table[19] = Colored_Rect:new(623+c_pos,426+corrY,9,2,  0.8,0.1,0.8,TH[42] ) --  Rand_Button_Color6
leds_table[20] = Colored_Rect:new(643+c_pos,426+corrY,8,2,  0.1,0.7,0.6,TH[42] ) --  Rand_Button_Color7

leds_table[21] = Colored_Rect:new(761+d_pos,410+corrY,2,18,  0.69,0.17,0.17,TH[42] ) -- MIDIMode1
leds_table[22] = Colored_Rect:new(761+d_pos,410+corrY,2,18,  0.69,0.32,0.05,TH[42] ) -- MIDIMode2
leds_table[23] = Colored_Rect:new(761+d_pos,410+corrY,2,18,  0.54,0.14,1,TH[42] ) -- MIDIMode3

leds_table[25] = Colored_Rect_top:new(917,5,2,20,  TH[39][1],TH[39][2],TH[39][3],TH[39][4] ) -- Light_Aim_on
leds_table[26] = Colored_Rect_top:new(917,5,2,20,  0.5,0.5,0.5,0.5 ) -- Light_Aim_off

local others_table = {Triangle, RandText, Q_Rnd_Linked, Q_Rnd_Linked2, Line, Line2, Loop_Dis, Ruler, Preset, Velocity, Mode, Mode2, ModeText}

others_table[1] = Txt2:new(628+c_pos,408+corrY,55,18, TH[36][1],TH[36][2],TH[36][3],TH[36][4], ">","Arial",20) --Triangle
others_table[2] = Txt2:new(735+c_pos,377,55,18, TH[36][1],TH[36][2],TH[36][3],TH[36][4], "Intensity","Arial",10) --RandText

others_table[3] = Line_colored:new(474+c_pos,375+corrY,145,18,  0.7,0.5,0.1,1) --| Q_Rnd_Linked (Bracket)
others_table[4] = Line2:new(472+c_pos,380+corrY,149,18,  TH[4][1],TH[4][2],TH[4][3],TH[4][4])--| Q_Rnd_Linked2 (Bracket fill)

others_table[5] = Line:new(769+d_pos,404+corrY,77,6) --Line (Preset/Velocity Bracket)
others_table[6] = Line2:new(769+d_pos,407+corrY,77,4,  TH[4][1],TH[4][2],TH[4][3],TH[4][4])--Line2 (Preset/Velocity Bracket fill)
others_table[7] = Colored_Rect_top:new(10,28,1024,15,  0.23,0.23,0.23,0.5)--Loop_Dis (Loop Disable fill)
others_table[8] = Ruler:new(10,42,1024,13,  0,0,0,0)--Loop_Dis (Loop Disable fill)

others_table[9] = Txt:new(781+d_pos,384+corrY,55,18, TH[36][1],TH[36][2],TH[36][3],TH[36][4], "Preset","Arial",22)
others_table[10] = Txt:new(780+d_pos,384+corrY,55,18, TH[36][1],TH[36][2],TH[36][3],TH[36][4], "Velocity","Arial",22)

others_table[11] = Line:new(856+d_pos,404+corrY,73,6) --Line (Mode Bracket)
others_table[12] = Line2:new(856+d_pos,407+corrY,73,4,  TH[4][1],TH[4][2],TH[4][3],TH[4][4])--Line2 (Mode Bracket fill)
others_table[13] = Txt:new(868+d_pos,384+corrY,52,18, TH[36][1],TH[36][2],TH[36][3],TH[36][4], "Mode","Arial",22) -- Mode Text

local Frame_Snap_TB = {leds_table[5]}
local Frame_Snap_TB2 = {leds_table[6]}
local Frame_Aim_TB = {leds_table[25]}
local Frame_Aim_TB2 = {leds_table[26]}
local Frame_Loop_TB = {leds_table[3]}
local Frame_Loop_TB2 = {leds_table[4], others_table[7]}
local Frame_TB = {elm_table[1], elm_table[2], elm_table[3], elm_table[17], elm_table[18], elm_table[19], elm_table[20], elm_table[21]} 
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
local Preset_TB = {others_table[9]}  

local MIDI_Mode_Color1_TB = {leds_table[21]}
local MIDI_Mode_Color2_TB = {leds_table[22]}
local MIDI_Mode_Color3_TB = {leds_table[23]}



local Midi_Sampler = CheckBox_simple:new(670+d_pos,410+corrY,91,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  MIDI_Mode,
                              {"Sampler","Trigger","Pitch Detect"} )

                              if Midi_Sampler.norm_val == 3 and RebuildPeaksOnStart == 1 then
                                  r.Main_OnCommand(40441,0) --rebuild peaks when the script starts
                              end

local Sampler_preset = CheckBox_simple:new(765+d_pos,410+corrY,85,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  Sampler_preset_state,
                              {"Percussive","Melodic"} )

local Pitch_Preset = CheckBox_simple:new(765+d_pos,410+corrY,85,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  PitchDetect,
                              {"Drums","Drums 2", "Percussion", "Bass","Default","Melodic","Complex"} )

local Pitch_Det_Options = CheckBox_simple:new(670+d_pos,430+corrY,93,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  Pitch_Det_Options_state,
                              {"Velocity On","Velocity Off"} )

local Pitch_Det_Options2 = CheckBox_simple:new(670+d_pos,450+corrY,93,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  Pitch_Det_Options_state2,
                              {"Note Lgth.","Staccato","Legato"} )

local Create_Replace = CheckBox_simple:new(852+d_pos,410+corrY,81,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  Create_Replace_state,
                              {"Create","Replace"} )

local Create_Replace2 = CheckBox_simple:new(852+d_pos,410+corrY,81,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  Create_Replace_state2, -- Pitch Detection mode
                              {"Create","Replace","No MIDI","No MIDI C"} )

local Set_Rate_Feel = CheckBox_simple:new(952+e_pos,430+corrY,72,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  Set_Rate_Feel_state, -- Pitch Detection mode
                              {"Straight","Triplets"} )

local Set_Rate_Mode = CheckBox_simple:new(952+e_pos,450+corrY,72,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  Set_Rate_Mode_state, -- Pitch Detection mode
                              {"Item Rate","Tempo","Mapping"} )

local VeloMode = CheckBox_simple:new(765+d_pos,410+corrY,85,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  1, -------velodaw
                              {"Use RMS","Use Peak"} )


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
---  Create controls objects(btns,sliders etc) and override some methods   ------------------------
----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
--- Filter Sliders ------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- Filter HP_Freq --------------------------------
local HP_Freq = HP_Slider:new(a_pos,410+corrY,a_width,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "Low Cut","Arial",16, HF_Slider )
-- Filter LP_Freq --------------------------------
local LP_Freq = LP_Slider:new(a_pos,430+corrY,a_width,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "High Cut","Arial",16, LF_Slider )
------------------------------------------------
-- Filter Freq Sliders draw_val function ---------
------------------------------------------------
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
local Fltr_Gain = G_Slider:new(a_pos,450+corrY,a_width,18,  TH[30][1],TH[30][2],TH[30][3],TH[30][4], "Filt. Gain","Arial",16, out_gain )
function Fltr_Gain:draw_val()
  self.form_val = self.norm_val*30  -- form value
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." dB"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
end

------------------------------------------------
-- onUp function for Filter Freq sliders ---------
------------------------------------------------
function Fltr_Sldrs_onUp()
   if Wave.AA then 
      if Wave.State then
         MW_doit_slider_comlpex()
      end
   end
end
----------------
HP_Freq.onUp   = Fltr_Sldrs_onUp
LP_Freq.onUp   = Fltr_Sldrs_onUp
------------------------------------------------
-- onUp function for Filter Gain slider  ---------
------------------------------------------------
Fltr_Gain.onUp =
function() 
   if Wave.State then 
      MW_doit_slider_fgain()
   end 
end

-------------------------------------------------------------------------------------
--- Gate Sliders --------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Threshold -----------------------------------
------------------------------------------------
local Gate_Thresh = T_Slider:new(b_pos,380+corrY,b_width,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "Threshold","Arial",16, readrms )
function Gate_Thresh:draw_val()
  self.form_val = (self.norm_val-1)*57-3
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." dB"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val) -- draw Slider Value
  Gate_Thresh:draw_val_line() -- Draw GATE Threshold lines !!!
end
     
-- Sensitivity -------------------------------------
local Gate_Sensitivity = S_Slider:new(b_pos,400+corrY,b_width,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "Sensitivity","Arial",16, Sens_Slider )
function Gate_Sensitivity:draw_val()
  sens_val = ((self.norm_val+0.125)*9)-0.125
  self.form_val = 2+(abs(self.norm_val-1))*8       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", sens_val)..""
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
end
-- Retrig ----------------------------------------
local Gate_Retrig = Rtg_Slider:new(b_pos,420+corrY,b_width,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "Retrig","Arial",16, retrigms )
function Gate_Retrig:draw_val()
  custom_log = (self.norm_val*(self.norm_val/2))*2
  self.form_val  = 10 + custom_log * 690   -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
end
-- Reduce points slider -------------------------- 
local Gate_ReducePoints = Rdc_Slider:new(b_pos,450+corrY,b_width,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "Reduce","Arial",16, 1 )
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
   if Wave.State then MW_doit_slider() end 
end
----------------
Gate_Thresh.onUp    = Gate_Sldrs_onUp
Gate_Sensitivity.onUp = Gate_Sldrs_onUp
Gate_Retrig.onUp    = Gate_Sldrs_onUp

-----------------Offset Slider------------------------ 
local Offset_Sld = O_Slider:new(400+c_pos,430+corrY,251,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "Offset","Arial",16, Offs_Slider )
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
  Offset_Sld.form_val = Offset_Sld.form_val-0.5 -- correction
  end
Offset_Sld.onUp =
function() 
   if Wave.State then

      MW_doit_slider_Fine()

      fixzero() 
   end 
end

-- QStrength slider ------------------------------ 
local QStrength_Sld = Q_Slider:new(400+c_pos,450+corrY,123,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "QStrength","Arial",16, QuantizeStrength*0.01 )
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
local XFade_Sld = X_Slider:new(525+c_pos,450+corrY,126,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "XFades","Arial",16, CrossfadeTime*0.02 )
function XFade_Sld:draw_val()
  self.form_val = (self.norm_val)*50       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val).." ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value
  CrossfadeT =  floor(XFade_Sld.form_val)
end
XFade_Sld.onUp =
function() 

end

-- XFade sliderOff ------------------------------ 
local XFade_Sld_Off = X_SliderOff:new(525+c_pos,450+corrY,126,18, 0.4,0.4,0.4,0.4, "XFades","Arial",16, 0 )
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
local RandV_Sld = H_Slider:new(723+c_pos,395,75,14, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16, RandV )
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
local RandPan_Sld = H_Slider:new(723+c_pos,410,75,14, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16, RandPan )
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
local RandPtch_Sld = H_Slider:new(723+c_pos,425,75,14, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16, RandPtch )
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
local RandPos_Sld = H_Slider:new(723+c_pos,440,75,14, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16, RandPos )
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
local RandRev_Sld = H_Slider:new(723+c_pos,455,75,14, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16, RandRev )
function RandRev_Sld:draw_val()
  self.form_val = (self.norm_val)*100       -- form_val
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val).."%"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.y = y+(h-val_h)/2
  gfx.drawstr(val)--draw Slider Value

  revsld =       (logx(RandRev_Sld.form_val+1))*21.63     
  RandRevVal =  ceil(revsld*-1)+100
end
RandRev_Sld.onUp =
function() 

end
if RandRevVal == nil then RandRevVal = ceil((((logx((RandRev*100)+1))*21.63)*-1)+100) end

-------------------------------------------------------------------------------------
--- Range Slider --------------------------------------------------------------------
-------------------------------------------------------------------------------------
local Gate_VeloScale = Rng_Slider:new(765+d_pos,430+corrY,85,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "Range","Arial",16, VeloRng, VeloRng2 )---velodaw 
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
local LoopScale = Loop_Slider:new(10,29,1024,18, TH[32][1],TH[32][2],TH[32][3],TH[32][4], "","Arial",16, 0,1 ) -- Play Loop Range

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
local Swing_Btn = Button_top:new(391,5,50,19, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Swing",    "Arial",16 )
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
Wave:DrawGridGuides()
   end 
end 

triplets = 2

-- Grid Button T----------------------------
local GridT_Btn = Button_top:new(344,5,40,19, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "T",    "Arial",16 )
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
Wave:DrawGridGuides()
   end 
end 

-- Grid Button 1----------------------------
local Grid1_Btn = Button_top:new(50,5,40,19, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "1",    "Arial",16 )
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
Wave:DrawGridGuides()
   end 
end 

-- Grid Button 1/2----------------------------
local Grid2_Btn = Button_top:new(92,5,40,19, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "1/2",    "Arial",16 )
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
Wave:DrawGridGuides()
   end 
end 

-- Grid Button 1/4----------------------------
local Grid4_Btn = Button_top:new(134,5,40,19, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "1/4",    "Arial",16 )
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
Wave:DrawGridGuides()
   end 
end 

-- Grid Button 1/8----------------------------
local Grid8_Btn = Button_top:new(176,5,40,19, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "1/8",    "Arial",16 )
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
Wave:DrawGridGuides()
   end 
end 

-- Grid Button 1/16----------------------------
local Grid16_Btn = Button_top:new(218,5,40,19, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "1/16",    "Arial",16 )
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
Wave:DrawGridGuides()
   end 
end 

-- Grid Button 1/32----------------------------
local Grid32_Btn = Button_top:new(260,5,40,19, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "1/32",    "Arial",16 )
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
Wave:DrawGridGuides()
   end 
end 

-- Grid Button 1/64----------------------------
local Grid64_Btn = Button_top:new(302,5,40,19, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "1/64",    "Arial",16 )
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
Wave:DrawGridGuides()
   end 
end 

-------------------------------------------------------------------------------------
-----------------Swing Slider-----------------------------------------------------
-------------------------------------------------------------------------------------

local Swing_Sld = Sw_Slider:new(443,5,100,20, TH[32][1],TH[32][2],TH[32][3],TH[32][4], " ","Arial",16, swngdefamt )
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
  swing_slider_amont = math_round(self_form_val/100, 2)
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
Trigger_Oct_Shift = tonumber(r.GetExtState('MK_Slicer_3','Trigger_Oct_Shift'))or 0;
octa = Trigger_Oct_Shift+1
note = 23+(octa*12)

local OutNote  = CheckBox_simple:new(670+d_pos,430+corrY,93,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  OutNote_State,
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

local OutNote2  = CheckBox_simple:new(670+d_pos,430+corrY,93,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  OutNote_State, -- named notes
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


----------------------------------------

local Slider_TB = {HP_Freq,LP_Freq,Fltr_Gain,Gate_Thresh,Gate_Sensitivity,Gate_Retrig,Gate_ReducePoints,Offset_Sld,QStrength_Sld,Project,Set_Rate_Mode, Set_Rate_Feel}

local Sliders_Grid_TB = {Grid1_Btn, Grid2_Btn, Grid4_Btn, Grid8_Btn, Grid16_Btn, Grid32_Btn, Grid64_Btn, GridT_Btn}

local Slider_Swing_TB = {Swing_Sld}

local Slider_TB_Trigger = {Gate_VeloScale, VeloMode,OutNote, others_table[10]}

local Slider_TB_Trigger_notes = {Gate_VeloScale, VeloMode,OutNote2, others_table[10]}

local XFade_TB = {XFade_Sld}
local XFade_TB_Off = {XFade_Sld_Off}

local SliderRandV_TB = {RandV_Sld}
local SliderRandPan_TB = {RandPan_Sld}
local SliderRandPtch_TB = {RandPtch_Sld}
local SliderRand_TBPos = {RandPos_Sld}
local SliderRand_TBM = {RandRev_Sld}

-------------------------------------------------------------------------------------
--- Buttons -------------------------------------------------------------------------
-------------------------------------------------------------------------------------

-- Create Loop  Button ----------------------------
local Loop_Btn = Button_top:new(986,5,48,20, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Loop",    "Arial",16 )
Loop_Btn.onClick = 
function()
   if Wave.State then 
        SetLoop = 0
        if Loop_on == 0 then 
                  Loop_on = 1
               else
                  Loop_on = 0
        end
   end 
end 

-- Aim Button ----------------------------
local Aim_Btn = Button_top:new(920,5,27,20, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "I",    "Arial",16 )
Aim_Btn.onClick = 
function()
   if Wave.State then 
        if Aim_on == 0 then 
             Aim_on = 1
               else
             Aim_on = 0
        end
   end 
end 

-- Create Snap Button ----------------------------
local Snap_Btn = Button_top:new(953,5,27,20, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Ll",    "Arial",16 )
Snap_Btn.onClick = 
function()
   if Wave.State then 
         repeatstate_status = 0
         if Snap_on == 0 then
                Snap_on = 1
             else
              SetSnap = 0
              Snap_on = 0
         end
   end 
end 

-- Get Selection button --------------------------
local Get_Sel_Button = Button:new(a_pos,380+corrY,a_width,25, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Get Item",    "Arial",16 )
Get_Sel_Button.onClick = 

function()

Slice_Status = 1
SliceQ_Status = 0
MarkersQ_Status = 0
Slice_Init_Status = 0
SliceQ_Init_Status = 0
Markers_Status = 0
MIDISmplr_Status = 0
MIDIPitch_Status = 0
Take_Check = 0
Trigg_Status = 0
Pitch_Det_Status = 0
Reset_Status = 0
Midi_sampler_offs_stat = 0
Pitch_Det_offs_stat = 0
Random_Status = 0
SliceQ_Status_Rand = 0
ErrMsg_Status = 0
SetBPMButtonStatus = 0
SetBPMStatus_Reset = 0
SetBPMStatus_ResetRate = 0
TMInit_Status = 0
Markers_BPM_Reset_Status = 0
Slice_BPM_Reset_Status = 0

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

UnSelectMIDIAndEmptyItems()
-------------------------------------Check Razor Edits------------------------------------
function RazorEditSelectionExists()
    for i=0, r.CountTracks(0)-1 do
        local retval, x = r.GetSetMediaTrackInfo_String(r.GetTrack(0,i), "P_RAZOREDITS", "string", false)
        if x ~= "" then return true end
    end--for
    return false
end --RazorEditSelectionExists()

RE_exist = RazorEditSelectionExists()

if RE_exist == true then
r.PreventUIRefresh(1)
-------------------Razor edit - Set time selection to razor areas----------------------------------
left, right = math.huge, -math.huge
for t = 0, r.CountTracks(0)-1 do
    local track = r.GetTrack(0, t)
    local razorOK, razorStr = r.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    if razorOK and #razorStr ~= 0 then
        for razorLeft, razorRight, envGuid in razorStr:gmatch([[([%d%.]+) ([%d%.]+) "([^"]*)"]]) do
            local razorLeft, razorRight = tonumber(razorLeft), tonumber(razorRight)
            if razorLeft  < left  then left  = razorLeft end
            if razorRight > right then right = razorRight end
        end
    end
end
if left <= right then
    r.GetSet_LoopTimeRange2(0, true, false, left, right, false)
end

---------------------Select media items that overlap razor areas--------------------------------
for t = 0, r.CountTracks(0)-1 do
    local track = r.GetTrack(0, t)
    local tR = {}
    local razorOK, razorStr = r.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
    if razorOK and #razorStr ~= 0 then
        for razorLeft, razorRight, envGuid in razorStr:gmatch([[([%d%.]+) ([%d%.]+) "([^"]*)"]]) do
            if envGuid == "" then
                local razorLeft, razorRight = tonumber(razorLeft), tonumber(razorRight)
                table.insert(tR, {left = razorLeft, right = razorRight})
            end
        end
    end
    for i = 0, r.CountTrackMediaItems(track)-1 do
        local item = r.GetTrackMediaItem(track, i)
        r.SetMediaItemSelected(item, false)
        local left = r.GetMediaItemInfo_Value(item, "D_POSITION")
        local right = left + r.GetMediaItemInfo_Value(item, "D_LENGTH")
        for _, rr in ipairs(tR) do
            if left < rr.right and right > rr.left then
                r.SetMediaItemSelected(item, true)
            end
        end
    end
end
--------------------------------------------------------------------------------------------------------------
            GetLoopTimeRange()
                  if start ~= ending then
                        r.Main_OnCommand(40061, 0) -- Split at Time Selection
                  --   r.Main_OnCommand(40635, 0) -- Remove Time Selection
                  unselect_if_out_of_time_range()
                  end
         
         sel_tracks_items()
         UnSelectMIDIAndEmptyItems()
         sel_tracks_items()

-----------------------------------------Set RE by Selected Items------------------------------------------         

         	r.Main_OnCommand(42406, 0) -- clear area sel
         	GetLoopTimeRange()
         	if start ~= ending then
         		local str_track_razor_edits = string.format([[%s %s '']], start, ending)	
         		for i = 0, r.CountSelectedTracks(0) - 1 do
         			local track = r.GetSelectedTrack(0, i)
         			r.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", str_track_razor_edits, true) -- set
         		end
         	end

         r.PreventUIRefresh(-1)
         r.UpdateArrange()
         
  else -- if not RE

            r.PreventUIRefresh(1)
            sel_tracks_items()

            GetLoopTimeRange()
                  if start ~= ending then -- if selection exist
                        r.Main_OnCommand(40061, 0) -- Split at Time Selection
                        TimeSelToFirstTrackItems()
                        UnSelectMIDIAndEmptyItems()
                  else
                        TimeSelToFirstTrackItems()
                        UnSelectMIDIAndEmptyItems()
                        GetLoopTimeRange() -- check again
                          if start ~= ending then -- if selection exist
                             r.Main_OnCommand(40061, 0) -- Split at Time Selection
                          end
                  end
                 unselect_if_out_of_time_range()
                 r.PreventUIRefresh(-1)
                 r.UpdateArrange()

end -- if RE_exist
---------------------------------------End of RE_Splits----------------------------------------

if ObeyingItemSelection == 1 then
sel_tracks_items()
end

InitTrackItemName()

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
GetLoopTimeRange()
time_sel_length = ending - start
if ObeyingTheSelection == 1 and ObeyingItemSelection == 0 and start ~= ending then
    r.Main_OnCommand(40289, 0) -- Item: Unselect all items
          if time_sel_length >= 0.25 then
              r.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
              UnSelectMIDIAndEmptyItems()
          end
end

count_itms =  r.CountSelectedMediaItems(0)
if ObeyingTheSelection == 1 and count_itms ~= 0 and start ~= ending and time_sel_length >= 0.25 then
   take_check()
   if Take_Check ~= 1 then

    SplitByTimeAndDeselect()

    collect_param()  

        if number_of_takes ~= 1 and No_Heal_On_Init == 0 then
           r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то попытка не деструктивно склеить).
        end
  
       if No_Glue_On_Init == 0 then -- проверяем ещё раз. Если не удалось, клеим деструктивно.
             GlueMultitrack()
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
     if char == 27 or char == -1 or (reaper.time_precise() - time) > timer then ErrM_St_s = 0 return else ErrM_St_s = 1 end
     local Get_Sel_ErrMsg = ErrMsg:new(580,35,260,45, 1, 1, 1, 1, "Time Selection is Too Short (<0.25s)")
     local ErrMsg_TB = {Get_Sel_ErrMsg}
     ErrMsg_Status = 1
     for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
   gfx.update()
  r.defer(Msg)
end
end
 if ErrM_St_s ~= 1 then
 Msg()
 end
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

    r.Undo_EndBlock("Init", -1) 

--------------------------A Bit More Foolproof----------------------------


     number_of_items_m =  r.CountSelectedMediaItems(0)
  if number_of_items_m < 1 then

-----------------------------------------Error Message1---------------------------------------------------

  local timer = 2 -- Time in seconds
  local time = reaper.time_precise()
  local function Msg()
     local char = gfx.getchar()
     if char == 27 or char == -1 or (reaper.time_precise() - time) > timer then ErrM_St = 0 return else ErrM_St = 1 end
     local Get_Sel_ErrMsg = ErrMsg:new(580,35,260,45, 1, 1, 1, 1, "No items selected")
     local ErrMsg_TB = {Get_Sel_ErrMsg}
     ErrMsg_Status = 1
     for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
       gfx.update()
       r.defer(Msg)
     end
  end
if ErrM_St ~= 1 then
Msg()
end

--------------------------------------End of Error Message1-------------------------------------------
Init()

  return

  end -- не запускать, если нет айтемов.


sel_tracks_items() 

collect_itemtake_param()              -- get bunch of parameters about this item

take_check()

if  Take_Check == 1 and number_of_takes == 1 then  

------------------------------------Error Message3----------------------------------------------

local timer = 2 -- Time in seconds
local time = reaper.time_precise()
local function Msg()
   local char = gfx.getchar()
     if char == 27 or char == -1 or (reaper.time_precise() - time) > timer then ErrM_St_w = 0 return else ErrM_St_w = 1 end
     local Get_Sel_ErrMsg = ErrMsg:new(580,35,260,45, 1, 1, 1, 1, "Only Wave items, please")
     local ErrMsg_TB = {Get_Sel_ErrMsg}
     ErrMsg_Status = 1
     for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
   gfx.update()
  r.defer(Msg)
end
end
if ErrM_St_w ~= 1 then
Msg()
end
-------------------------------------End of Error Message3----------------------------------------

Init()

 goto zzz 
end -- не запускать, если MIDI айтем.


 if number_of_takes ~= 1 and Take_Check == 0 and Random_Status ~= 1 and No_Heal_On_Init == 0 then
     r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то клей, попытка не деструктивно склеить).
 end

  if No_Glue_On_Init == 0 then 

             GlueMultitrack()

  end
SaveInitRate()
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
--Init()
getitem()

if Wave.State then
      Wave:DrawGridGuides()
end

if Midi_Sampler.norm_val == 3 and RebuildPeaksOnStart == 1 then
    r.Main_OnCommand(40441,0) --rebuild peaks when the script starts
end

r.Main_OnCommand(40635, 0) -- Remove Time Selection
r.PreventUIRefresh(-1)
::zzz::

end


-- Create Settings Button ----------------------------
local Settings = Button_Settings:new(9,10,40,40, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "=",    "Arial",20 )
Settings.onClick = 
function()
   Wave:Settings()
end 

-- Create Just Slice  Button ----------------------------
local Just_Slice = Button:new(400+c_pos,380+corrY,60,25, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Slice",    "Arial",16 )
Just_Slice.onClick = 
function()
   if Wave.State then 
ErrMsg_Status = 0

sel_tracks_items()

collect_param()

if selected_tracks_count > 1 and number_of_takes > 1 then -- multitrack

     time_start = reaper.time_precise()       
        local function Main()     
            local elapsed = reaper.time_precise() - time_start       
            if elapsed >= 0.02 then
                 ErrMsg_Status = 0
            ----------------------------------------------------------------
                 Wave:Just_Slice() 
             ------------------------------------------------------------------

              runcheck = 0
                return
            else
             ErrMsg_Status = 1

               Wave:show_process_wait()

              runcheck = 1
                reaper.defer(Main)
            end           
        end
        
        if runcheck ~= 1 then
           Main()
        end

else -- if single track
  Wave:Just_Slice() 
end

end 
end 

-- Create Quantize Slices Button ----------------------------
local Quantize_Slices = Button:new(462+c_pos,380+corrY,25,25, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Q",    "Arial",16 )
Quantize_Slices.onClick = 
function()
   if Wave.State then 

ErrMsg_Status = 0

sel_tracks_items()

collect_param()

if selected_tracks_count > 1 and number_of_takes > 1 then -- multitrack

     time_start = reaper.time_precise()       
        local function Main()     
            local elapsed = reaper.time_precise() - time_start       
            if elapsed >= 0.02 then
                 ErrMsg_Status = 0
            ----------------------------------------------------------------
                 Wave:Quantize_Slices()
             ------------------------------------------------------------------

              runcheck = 0
                return
            else
             ErrMsg_Status = 1

               Wave:show_process_wait()

              runcheck = 1
                reaper.defer(Main)
            end           
        end
        
        if runcheck ~= 1 then
           Main()
        end

else -- if single track
Wave:Quantize_Slices()
end
 
end 
end 

-- Create Add Markers Button ----------------------------
local Add_Markers = Button:new(492+c_pos,380+corrY,60,25, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Markers",    "Arial",16 )
Add_Markers.onClick = 
function()
   if Wave.State then Wave:Add_Markers() end 
end 

-- Create Quantize Markers Button ----------------------------
local Quantize_Markers = Button:new(554+c_pos,380+corrY,25,25, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Q",    "Arial",16 )
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
     
     math.randomseed(reaper.time_precise()*os.time()/1e3)
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
       local max = x//((RandRevVal/10)+1)
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
             --    r.Main_OnCommand(r.NamedCommandLookup("_SWS_AWFILLGAPSQUICK"),0) -- fill gaps 
                   FillGaps()
             end
     
     r.PreventUIRefresh(-1); r.Undo_EndBlock('Random', -1)

end


-- Random_Setup Button ----------------------------
local Random_SetupB = Button_small:new(584+c_pos,410+corrY,67,15, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Rnd.Set",    "Arial",16 )
Random_SetupB.onClick = 
function()
     if Random_Setup ~= 1 then
            Random_Setup = 1 
        else
            Random_Setup = 0 
     end
end

local sbtbl = {Random_OrderB, Random_VolB, Random_PanB, Random_PitchB, Random_PositionB, Random_ReverseB, Random_MuteB, Random_SetupClearB}

-- Random_Clear Button ----------------------------
sbtbl[8] = Button_small:new(758+c_pos,470,40,14, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Clear",    "Arial",16 )
sbtbl[8].onClick = 
function()
Random_Order = 1 
Random_Vol = 0 
Random_Pan = 0 
Random_Pitch = 0
Random_Position = 0
Random_Mute = 0 
Random_Reverse = 0
r.SetExtState('MK_Slicer_3','Random_Order',Random_Order,true);
r.SetExtState('MK_Slicer_3','Random_Vol',Random_Vol,true);
r.SetExtState('MK_Slicer_3','Random_Pan',Random_Pan,true);
r.SetExtState('MK_Slicer_3','Random_Pitch',Random_Pitch,true);
r.SetExtState('MK_Slicer_3','Random_Position',Random_Position,true);
r.SetExtState('MK_Slicer_3','Random_Position',Random_Position,true);
r.SetExtState('MK_Slicer_3','Random_Mute',Random_Mute,true);
r.SetExtState('MK_Slicer_3','Random_Reverse',Random_Reverse,true);
end

-- Random_Order Button ----------------------------
sbtbl[1] = Button_small:new(661+c_pos,380,60,14, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Order",    "Arial",5 )
sbtbl[1].onClick = 
function()
     if Random_Order ~= 1 then
            Random_Order = 1 
        else
            Random_Order = 0 
     end
          r.SetExtState('MK_Slicer_3','Random_Order',Random_Order,true);
end

-- Random_Vol Button ----------------------------
sbtbl[2] = Button_small:new(661+c_pos,395,60,14, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Volume",    "Arial",5 )
sbtbl[2].onClick = 
function()
     if Random_Vol ~= 1 then
            Random_Vol = 1 
        else
            Random_Vol = 0 
     end
          r.SetExtState('MK_Slicer_3','Random_Vol',Random_Vol,true);
end

-- Random_Pan Button ----------------------------
sbtbl[3] = Button_small:new(661+c_pos,410,60,14, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Pan",    "Arial",5 )
sbtbl[3].onClick = 
function()
     if Random_Pan ~= 1 then
            Random_Pan = 1 
        else
            Random_Pan = 0 
     end
          r.SetExtState('MK_Slicer_3','Random_Pan',Random_Pan,true);
end

-- Random_Pitch Button ----------------------------
sbtbl[4] = Button_small:new(661+c_pos,425,60,14, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Pitch",    "Arial",5 )
sbtbl[4].onClick = 
function()
     if Random_Pitch ~= 1 then
            Random_Pitch = 1 
        else
            Random_Pitch = 0 
     end
          r.SetExtState('MK_Slicer_3','Random_Pitch',Random_Pitch,true);
end

-- Random_Position Button ----------------------------
sbtbl[5] = Button_small:new(661+c_pos,440,60,14, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Position",    "Arial",5 )
sbtbl[5].onClick = 
function()
     if Random_Position ~= 1 then
            Random_Position = 1 
        else
            Random_Position = 0 
     end
          r.SetExtState('MK_Slicer_3','Random_Position',Random_Position,true);
end

-- Random_Reverse Button ----------------------------
sbtbl[6] = Button_small:new(661+c_pos,455,60,14, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Reverse",    "Arial",5 )
sbtbl[6].onClick = 
function()
     if Random_Reverse ~= 1 then
            Random_Reverse = 1 
        else
            Random_Reverse = 0 
     end
          r.SetExtState('MK_Slicer_3','Random_Reverse',Random_Reverse,true);
end

-- Random_Mute Button ----------------------------
sbtbl[7] = Button_small:new(661+c_pos,470,60,14, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Mute",    "Arial",5 )
sbtbl[7].onClick = 
function()
     if Random_Mute ~= 1 then
            Random_Mute = 1 
        else
            Random_Mute = 0 
     end
          r.SetExtState('MK_Slicer_3','Random_Mute',Random_Mute,true);
end

-- Random Button ----------------------------

local Random = Button:new(584+c_pos,380+corrY,67,25, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Random",    "Arial",16 ) 
Random.onClick = 
function()
if Wave.State then 
    if Random_Order ~= 1 and Random_Reverse ~= 1 and Random_Mute ~= 1 and Random_Position ~= 1 and Random_Pitch ~= 1 and Random_Pan ~= 1 and Random_Vol ~= 1 then 
      
        ------------------------------------------Error Message-----------------------------------------        
         local timer = 2 -- Time in seconds
         local time = reaper.time_precise()
         local function Msg()
            local char = gfx.getchar()
     if char == 27 or char == -1 or (reaper.time_precise() - time) > timer then ErrM_St_r = 0 return else ErrM_St_r = 1 end
         local Get_Sel_ErrMsg = ErrMsg:new(580,35,260,45, 1, 1, 1, 1, "Select at least one option in Rnd.Set")
         local ErrMsg_TB = {Get_Sel_ErrMsg}
         ErrMsg_Status = 1
              for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
            gfx.update()
           r.defer(Msg)
         end
         end
         if ErrM_St_r ~= 1 then
         Msg()
         end
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

----  r.Main_OnCommand(r.NamedCommandLookup("_SWS_AWFILLGAPSQUICK"),0) -- fill gaps 

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
local Reset_All = Button:new(973,448+corrY,55,22, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Reset",    "Arial",16 )
Reset_All.onClick = 
function()
   if Wave.State then 
       Wave:Reset_All() 
       SliceQ_Status_Rand = 0
   end 
end


-- Set Rate Button ----------------------------
local Set_Rate = Button:new(952+e_pos,380+corrY,72,25, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Set BPM",    "Arial",16 )
Set_Rate.onClick = 
function()
   if Wave.State then 
       Wave:Reset_All()
       SetBPMButtonStatus = 1
       if Set_Rate_Mode.norm_val == 1 then
             SetRate()
             SetBPMStatus_ResetRate = 1
             elseif Set_Rate_Mode.norm_val == 2 then
             DelTempo()
             SetTempo(bpm4c)
             SetBPMStatus_Reset = 1
             elseif Set_Rate_Mode.norm_val == 3 then
             DelTempo()
             TMInit_Status = 1
             SetBPMStatus_Reset = 1
       end
   end 
end


-- Create Midi Button ----------------------------
local Create_MIDI = Button:new(670+d_pos,380+corrY,93,25, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "MIDI",    "Arial",16 )
Create_MIDI.onClick = 

function()

if Wave.State and MIDISmplr_Status == 0 and MIDIPitch_Status == 0 then -- and Trigg_Status == 0
  Slice_Status = 1
  M_Check = 0
  MIDISampler = 1

number_of_items_m =  r.CountSelectedMediaItems(0)
if Wave.State and number_of_items_m < 1 then
     local lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')
     local item =  r.BR_GetMediaItemByGUID( 0, lastitem )
     if item ~= nil then
         r.SetMediaItemSelected(item, true)
     end
end


selected_tracks_count = r.CountSelectedTracks(0)

  if selected_tracks_count > 1 then

-----------------------------------------Error Message2---------------------------------------------------

  local timer = 2 -- Time in seconds
  local time = reaper.time_precise()
  local function Msg()
     local char = gfx.getchar()
     if char == 27 or char == -1 or (reaper.time_precise() - time) > timer then ErrM_St_m = 0 return else ErrM_St_m = 1 end
  local Get_Sel_ErrMsg = ErrMsg:new(580,35,260,45, 1, 1, 1, 1, "Only single track items, please")
  local ErrMsg_TB = {Get_Sel_ErrMsg}
ErrMsg_Status = 1
       for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
     gfx.update()
    r.defer(Msg)
  end
  end
if ErrM_St_m ~= 1 then
Msg()
end

--------------------------------------End of Error Message2-------------------------------------------
Init()

  M_Check = 1

  return

  end -- не запускать, если мультитрек.

take_check()

if  Take_Check == 1 then  

------------------------------------Error Message3----------------------------------------------

local timer = 2 -- Time in seconds
local time = reaper.time_precise()
local function Msg()
   local char = gfx.getchar()
     if char == 27 or char == -1 or (reaper.time_precise() - time) > timer then ErrM_St_m2 = 0 return else ErrM_St_m2 = 1 end
local Get_Sel_ErrMsg = ErrMsg:new(580,35,260,45, 1, 1, 1, 1, "Only Wave items, please")
local ErrMsg_TB = {Get_Sel_ErrMsg}
ErrMsg_Status = 1
     for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
   gfx.update()
  r.defer(Msg)
end
end
if ErrM_St_m2 ~= 1 then
Msg()
end

-------------------------------------End of Error Message3----------------------------------------

Take_Check = 0

Init()

  return

end -- не запускать, если MIDI айтем.

  if M_Check == 0 then

      r.Undo_BeginBlock() 

   r.Main_OnCommand(41844, 0)  ---Delete All Markers  

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

   if take_pitch ~= 0 or (take_playrate ~= 1.0 and Midi_Sampler.norm_val == 1) or number_of_takes ~= 1 then
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
     
          elseif Midi_Sampler.norm_val == 2 then
                 cursorpos = r.GetCursorPosition()
                       MIDITrigger()
        
          elseif (Midi_Sampler.norm_val == 3) then  
                 cursorpos = r.GetCursorPosition()
                       MIDIPitch_Status = 1
                       Pitch_Det_offs_stat = 1
                       Wave:Just_Slice() 
                       MIDITrigger_pitched()

                       r.Undo_EndBlock("Audio to MIDI", -1) 
          end  
  end 
  end
end
----------------------------------------
--- Button_TB --------------------------
----------------------------------------
local Loop_TB = {LoopScale}
local LoopBtn_TB = {Loop_Btn, Aim_Btn, Snap_Btn, Swing_Btn}

local Checkbox_TB_preset = {Sampler_preset}

local Button_TB = {Get_Sel_Button, Settings, Just_Slice, Quantize_Slices, Add_Markers, Quantize_Markers, Random, Reset_All, Random_SetupB, Set_Rate, Set_Rate_Incr, Set_Rate_Decr}
local Button_TB2 = {Create_MIDI, Midi_Sampler}
local Pitch_Det_Options_TB = {Pitch_Det_Options, Pitch_Det_Options2, Pitch_Preset}
local  Create_Replace_TB = {others_table[11], others_table[12], others_table[13]}
local  Create_Replace_TB2 = {Create_Replace} --trigger
local  Create_Replace_TB3 = {Create_Replace2} --pitch detection
local Random_Setup_TB2 = {elm_table[6], elm_table[7], sbtbl[1], sbtbl[2], sbtbl[3], sbtbl[4], sbtbl[5], sbtbl[6], sbtbl[7], sbtbl[8]}
 
-------------------------------------------------------------------------------------
--- CheckBoxes ---------------------------------------------------------------------
-------------------------------------------------------------------------------------

local Guides  = CheckBox:new(400+c_pos,410+corrY,177,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  Guides_mode,
                              {"Guides By Transients","Guides By Grid"} )

Guides.onClick = 
function() 
   if Wave.State then
      Wave:Reset_All()
      Wave:DrawGridGuides()
   end 
end

--------------------------------------------------
-- View Checkboxes -------------------------------
-------------------------
local ViewMode = CheckBox_Show:new(1019,375+corrY,15,15,  0.4,0.4,0.4,0.7, "","Arial",16,  1,
                              { "Show All", "Original", "Filtered" } )
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
           local input = Wave.out_buf[i] -- abs sample value(abs envelope)
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

function Wave:DrawGridGuides()

local lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')
     
     local item =  r.BR_GetMediaItemByGUID( 0, lastitem )

        if item then 

           Grid_Points ={}
           self.Grid_Points_S ={}
           
           local b = 0
           
           if loop_start == nil then loop_start = 0 end
           if loop_end == nil then loop_end = 0 end
           if srate == nil then return end
           
           local blueline = loop_start 
                while (blueline <= loop_end) do
             
                     blueline = beatc(blueline)
             
                     b = b + 1
                     Grid_Points[b] = (((blueline - loop_start)*srate)//1)+(Offset_Sld.form_val/1000*srate)
                     self.Grid_Points_S[b] = ((blueline*srate)//1)+(Offset_Sld.form_val/1000*srate)
             
                end 
         end 

end

-----------------------------------------------------------------------
---  Gate - Draw Gate Lines  -------------------------------------------
-----------------------------------------------------------------------
function Gate_Gl:draw_Lines()
  if not self.Res_Points then return end -- return if no lines
    --------------------------------------------------------
    -- Set values ------------------------------------------
    --------------------------------------------------------
    TrMrkrHover = 0
    local sw_shift = 0
    local velo_y, line_x_mouse_x, line_x
    local mode = VeloMode.norm_val
    local offset = Wave.h * Gate_VeloScale.norm_val
    self.scale = Gate_VeloScale.norm_val2 - Gate_VeloScale.norm_val
    -- Pos, X, Y scale in gfx  ---------
    self.start_smpl = Wave.Pos/Wave.X_scale    -- Стартовая позиция отрисовки в семплах!
    self.Xsc = Wave.X_scale * Wave.Zoom * Z_w  -- x scale(regard zoom) for trigg lines
    self.Yop = Wave.y + Wave.h - offset        -- y start wave coord for velo points
    self.Ysc = Wave.h * self.scale             -- y scale for velo points 
    vel_point_lowest = 30 -- vel point bottom line
    const = 1.132 -- triangle, vertical position

    triangle_size = 40*((Z_w/10)+(Wave.Zoom/20))
    if triangle_size > 14 then triangle_size = 14 end
    --------------------------------------------------------
    mouse_pos_height =  gfx.mouse_y/Z_h 
    mouse_pos_width =  gfx.mouse_x/Z_w

 if (Guides.norm_val == 1) then 

    -- Draw, capture trig lines ----------------------------
    --------------------------------------------------------
    gfx.set(TH[13][1],TH[13][2],TH[13][3],TH[13][4]) -- gate line, point color -- цвет маркеров транзиентов
    ----------------------------
   
    for i=1, #self.Res_Points, 2 do
           line_x = Wave.x + (self.Res_Points[i] - self.start_smpl) * self.Xsc  -- line x coord

           if (Midi_Sampler.norm_val == 2) then
                 velo_y = (self.Yop-vel_point_lowest) -  self.Res_Points[i+1][mode] * (self.Ysc-vel_point_lowest)  -- velo y coord       
           end
        ------------------------
        -- draw line, velo -----
        ------------------------
        if line_x>=Wave.x and line_x<=Wave.x+Wave.w then -- Verify line range
           gfx.line(line_x, Wave.y+2, line_x, Wave.y+Wave.h-1)  -- Draw Trig Line
           if TH[16] > 0 then
               grad_w2 = TH[16]*(0.7+Z_w/2)
               gfx.gradrect((line_x+1)-grad_w2, Wave.y, grad_w2, Wave.h,        TH[13][1],TH[13][2],TH[13][3], 0.0,    0, 0, 0, TH[17] / grad_w2) -- grad back
               gfx.gradrect(line_x-1, Wave.y, grad_w2, Wave.h,        TH[13][1],TH[13][2],TH[13][3], TH[17],    0, 0, 0, -TH[17] / grad_w2) -- grad ahead
           end
           gfx.triangle(line_x+1, Wave.h*const, line_x+1, (Wave.h*const)-triangle_size, line_x+triangle_size+1, Wave.h*const) -- Triangle (Transient Small Flag)

           if (Midi_Sampler.norm_val == 2) then
              gfx.circle(line_x, velo_y, 3,1,1)             -- Draw Velocity point
           end
         end
        
            ------------------------
            -- Get mouse -----------
            ------------------------
            line_x_mouse_x = line_x-gfx.mouse_x
            if line_x_mouse_x < 0 then line_x_mouse_x = line_x_mouse_x*-1 end

            grab_corr = 50*((Z_w/10)+(Wave.Zoom/20)) --14*(Z_w/4)
            if grab_corr >= 15  then grab_corr = 15 end
            if not self.cap_ln and line_x_mouse_x < (grab_corr) then -- здесь grab_corr - величина окна захвата маркера.
                if Wave:mouseDown() or Wave:mouseR_Down() then self.cap_ln = i end
                   TrMrkrHover = 1
                   if not Ctrl and mouse_pos_height >= 355 and mouse_pos_height <= 380 then  
                       if TH[14] > 0 then
                          grad_w = TH[14]*(0.7+Z_w/2) -- selected marker gradient
                          gfx.gradrect((line_x+1)-grad_w, Wave.y, grad_w, Wave.h,        TH[13][1],TH[13][2],TH[13][3], 0.0,    0, 0, 0, TH[15] / grad_w) -- grad back
                          gfx.gradrect(line_x-1, Wave.y, grad_w, Wave.h,        TH[13][1],TH[13][2],TH[13][3], TH[15],    0, 0, 0, -TH[15] / grad_w) -- grad ahead
                        end
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

 else  ------------------------------------------------------------------------------------------------------------     

gfx.set(TH[19][1],TH[19][2],TH[19][3],TH[19][4]) -- grid line, point color -- цвет маркеров при отображении сетки

local Grid_Points = Grid_Points or {};     
local _, division, swingmode, swingamt = r.GetSetProjectGrid(0, 0)
if division < 0.0078125 then division = 0.0078125 end
local lnt_corr = (loop_length/tempo_corr)/8
if 0.00007 > self.Xsc*division then self.Xsc = 0.00007/division end

   for i=1, #Grid_Points  do

   if Swing_on == 1 and swing_slider_amont ~= 0 then
         sw_shift = swingamt*(1-abs(division-1))
         if IsEven(i) == false and swingmode == 1 then 
            sw_shift = (sw_shift*128*Wave.Zoom*Z_w)/lnt_corr
              else
            sw_shift = 0
         end
    end
         OffsSldCorrG = 0.5/1000*srate
         line_x  = Wave.x+sw_shift + (Grid_Points[i] - self.start_smpl+OffsSldCorrG) * self.Xsc  -- line x coord

         if line_x>=Wave.x and line_x<=Wave.x+Wave.w then -- Verify line range
            gfx.line(line_x, Wave.y, line_x, Wave.y+Wave.h-2)  -- Draw Trig Line
         end

      end  

end   

---------------------------------Snap and Loop Toggles----------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------
     if Snap_on == 1 then
     
             repeatstate = r.GetToggleCommandStateEx( 0, 1068) -- get Option: ""Transport: Toggle repeat"
             if repeatstate == 0 then
                r.Main_OnCommand(1068, 0) -- Option: "Transport: Toggle repeat"
             end
            
         elseif Snap_on == 0 then
     
            if repeatstate_status == 0 then
                 repeatstate = r.GetToggleCommandStateEx( 0, 1068) -- get Option: ""Transport: Toggle repeat"
                 if repeatstate == 1 then
                    r.Main_OnCommand(1068, 0) -- Option: "Transport: Toggle repeat"
                    repeatstate_status = 1
                 end
            end
     
            if SetSnap == 0 then 
                  if Loop_on == 1 then 
                     r.GetSet_LoopTimeRange(1, 1, item_pos, item_end, 0) -- reset loop  
                     else
                     r.GetSet_LoopTimeRange(1, 1, 0, 0, 0) -- reset loop  
                  end
               SetSnap = 1
            end
     
     end
---------------------------------------------------------------------------------------------------------------------

     if Loop_on == 1 then
     
             repeatstate = r.GetToggleCommandStateEx( 0, 1068) -- get Option: ""Transport: Toggle repeat"
             if repeatstate == 0 then
                r.Main_OnCommand(1068, 0) -- Option: "Transport: Toggle repeat"
             end
             
          elseif Loop_on == 0 then
     
            repeatstate = r.GetToggleCommandStateEx( 0, 1068) -- get Option: ""Transport: Toggle repeat"
            if repeatstate == 1 then
               r.Main_OnCommand(1068, 0) -- Option: "Transport: Toggle repeat"
            end
            
            if SetLoop == 0 then 
                if Snap_on == 0 then 
                    if Loop_on == 1 then
                       r.GetSet_LoopTimeRange(1, 1, item_pos, item_end, 0) -- reset loop  
                       else
                       r.GetSet_LoopTimeRange(1, 1, 0, 0, 0) -- reset loop  
                    end
                end
                SetLoop = 1
            end

     end
---------------------------------------------------------------------------------------------------------------------

end -- function Gate_Gl:draw_Lines()
----------------------------------------------------------------------------------------------------------------------
function Gate_Gl:draw_Ruler()
    --------------------------------------------------------
    -- Set values ------------------------------------------
    --------------------------------------------------------
    -- Pos, X, Y scale in gfx  ---------
    self.start_smpl = Wave.Pos/Wave.X_scale    -- Стартовая позиция отрисовки в семплах!
    self.Xsc = Wave.X_scale * Wave.Zoom * Z_w  -- x scale(regard zoom) for trigg lines
    --------------------------------------------------------

    -- Draw Project Grid lines ("Ruler") ----------------------------
-------------------------------------------------------------------------------------------------------------
local Grid_Points_Ruler = Grid_Points or {};     
local _, division, swingmode, swingamt = r.GetSetProjectGrid(0, 0)
if division < 0.0078125 then division = 0.0078125 end
local lnt_corr = (loop_length/tempo_corr)/8
local ruler_recolor, p_corr, sw_shift = 0, 1, 0
if 0.00007 > self.Xsc*division then self.Xsc = 0.00007/division; ruler_recolor = 1 end
local grad_w3, grad_a3

 for i=1, #Grid_Points_Ruler  do

   if Swing_on == 1 and swing_slider_amont ~= 0 then
         sw_shift = swingamt*(1-abs(division-1))
         if IsEven(i) == false and swingmode == 1 then 
            sw_shift = (sw_shift*128*Wave.Zoom*Z_w)/lnt_corr
              else
            sw_shift = 0
         end
    end

         if OffsSldCorr == nil then OffsSldCorr = Offset_Sld.form_val/1000*srate end
         local line_x  = Wave.x+sw_shift + (Grid_Points_Ruler[i] - self.start_smpl-OffsSldCorr) * self.Xsc  -- line x coord

         --------------------
         -- draw line -----
         ----------------------      
         if line_x>=Wave.x and line_x<=Wave.x+Wave.w then -- Verify line range


             if ruler_recolor == 0 then
                 gfx.set(TH[1][1],TH[1][2],TH[1][3],TH[1][4]) -- ruler black background
                 gfx.rect(line_x-1,(Wave.y*1.02), 3, 3+(Wave.h/50), true) -- draw body
                 grad_w3 = TH[10]*(0.7+Z_w/2)
                 grad_a3 = TH[11]
               else
                   grad_w3 = 5*(0.7+Z_w/2)
                   grad_a3 = 0.4
             end

            gfx.set(TH[9][1], TH[9][2], TH[9][3], TH[9][4]) -- ruler green short line, point color -- цвет линий сетки проекта
            gfx.line(line_x, (Wave.y*1.17), line_x, Wave.y-1+(Wave.h/300))  -- Draw Trig Line
              if TH[10] ~= 0 then -- ruler gradient. 0 = off
                 gfx.gradrect((line_x+1)-grad_w3, (Wave.y*1.01), grad_w3, (Wave.h/38),        TH[9][1], TH[9][2], TH[9][3], 0.0,    0, 0, 0, grad_a3 / grad_w3) -- grad back
                 gfx.gradrect(line_x-1, (Wave.y*1.01), grad_w3, (Wave.h/38),        TH[9][1], TH[9][2], TH[9][3], grad_a3,    0, 0, 0, -grad_a3 / grad_w3) -- grad ahead
              end
        end
   end  

end

--------------------------------------------------
-- Gate Threshold-lines function -----------------
-------------------------------------------------- 
function Gate_Thresh:draw_val_line()
  if Wave.State and (Guides.norm_val == 1) then gfx.set(TH[12][1],TH[12][2],TH[12][3],TH[12][4]) --цвет линий treshold
    local val = (10^(self.form_val/20)) * Wave.Y_scale * Wave.vertZoom * Z_h -- value in gfx
    if val>Wave.h/2 then return end            -- don't draw lines if value out of range
    local val_line1 = Wave.y + Wave.h/2 - val  -- line1 y coord
    local val_line2 = Wave.y + Wave.h/2 + val  -- line2 y coord
    gfx.line(Wave.x, val_line1, Wave.x+Wave.w-1, val_line1 )
    gfx.line(Wave.x, val_line2, Wave.x+Wave.w-1, val_line2 )
  end
end


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------BPM--------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

function InitRate(i_rate)
     local lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')
     local item =  r.BR_GetMediaItemByGUID( 0, lastitem )
         if item ~= nil then
                  take = r.GetActiveTake(item)
      
            local i_rate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
                if i_rate == nil then i_rate = 1 end

                 return i_rate
            else
               i_rate = 1
        end
end

--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------

function FixLength()
     local lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')
     local item =  r.BR_GetMediaItemByGUID( 0, lastitem )
            take = r.GetActiveTake(item)

        i_rate = InitRate()

        local item_src = reaper.GetMediaItemTake_Source(take)
        local item_src_l = reaper.GetMediaSourceLength(item_src)
    
        local _, _, init_start, init_length, _, _ = r.BR_GetMediaSourceProperties( take )
    
        local a_condition = ((init_length*i_rate)+init_start)-item_src_l
    
    if a_condition > 0 then
       r.SetMediaItemInfo_Value(item, "D_LENGTH", (item_src_l-init_start)/i_rate)
    end
    
      r.UpdateArrange()  

end

------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------DelTempo------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

function DelTempo()

   local lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')
   local item =  r.BR_GetMediaItemByGUID( 0, lastitem )
       if item ~= nil then
               local take = r.GetActiveTake(item)

             local init_pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
             local init_rate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
             local init_length    = r.GetMediaItemInfo_Value(item, "D_LENGTH")
             item_end = init_pos+init_length
        
            local t_start_i = r.FindTempoTimeSigMarker(0, init_pos)
            
            if not t_start_i or t_start_i == -1 then return end
            local _, t_start = r.GetTempoTimeSigMarker(0, t_start_i)
            if t_start < init_pos then
               _, t_start = r.GetTempoTimeSigMarker(0, t_start_i+1)
               if t_start == 0 or t_start > item_end then
                  return
               else t_start_i = t_start_i+1  end
            end
            
            local t_end_i = r.FindTempoTimeSigMarker(0, item_end)
           
            for i = t_end_i,t_start_i,-1 do
              r.DeleteTempoTimeSigMarker(0, i)
            end
        
          r.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", init_rate)
          r.SetMediaItemInfo_Value(item, 'D_LENGTH', init_length)
      end

end

------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------SetTempoMap----------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

function Gate_Gl:SetTempoMap()

     if TMInit_Status == 1 then
     
      local PntsMap= {} -- collect transients only
      local Pos_BPM_Table = {}

      local sPR_count = #self.Res_Points
           for j=3, sPR_count, 2 do -- starts from 2 because...
           local k = #PntsMap+1
              PntsMap[k] = self.Res_Points[j]
           end
          table.insert(PntsMap, 0) -- ...this is first. 
          table.sort(PntsMap)
          
      local PM_count = #PntsMap         
          for i = 2, PM_count do
            local prev_val = PntsMap[i - 1]
            local val = PntsMap[i]
            table.insert(Pos_BPM_Table, prev_val)
            new_val = 60/((val - prev_val)/srate)
            table.insert(Pos_BPM_Table, new_val)
          end
          
     local lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')
     local item =  r.BR_GetMediaItemByGUID( 0, lastitem )
           if item ~= nil then
                         take = r.GetActiveTake(item)
             
                  local init_rate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
                  local init_pos    = r.GetMediaItemInfo_Value(item, "D_POSITION")
                  local init_length    = r.GetMediaItemInfo_Value(item, "D_LENGTH")

             local PBPMT_count = #Pos_BPM_Table 
                   for i = 1, PBPMT_count, 2 do
                     local time = Pos_BPM_Table[i]
                     local bpm = Pos_BPM_Table[i+1]
                             time = (time)/srate
                             time_init = (Pos_BPM_Table[1])/srate
 
                        time = r.BR_GetClosestGridDivision(time+init_pos)
         
                        if bpm and time then
         
                                 if bpm < 40 then 
                                     bpm_div = 0.125
                                     elseif bpm >= 40 and bpm < 60 then 
                                     bpm_div = 0.25
                                     elseif bpm >= 60 and bpm < 160 then 
                                     bpm_div = 0.5
                                     elseif bpm >= 160 and bpm < 240 then 
                                     bpm_div = 1
                                     elseif bpm >= 240 and bpm < 320 then 
                                     bpm_div = 1
                                     elseif bpm >= 320 and bpm < 720 then 
                                     bpm_div = 2
                                     elseif bpm >= 720 and bpm < 1440 then
                                     bpm_div = 4
                                     elseif bpm >= 1440 then
                                     bpm_div = 8    
                                     else
                                     bpm_div = 0.5    
                                 end
                       
                                 if Set_Rate_Feel.norm_val == 1 then 
                                     bpm = bpm -- straight feel
                                     else
                                     bpm = bpm*0.666666666 -- triplet feel
                                 end
            
                                 bpm = math_round((bpm/(2*bpm_div)),1)
                                  r.SetTempoTimeSigMarker( 0, -1, time, -1, -1, bpm, -1, -1, 0 )
                        end
                   end

              r.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", init_rate)
              r.SetMediaItemInfo_Value(item, 'D_LENGTH', init_length)
              --FixLength() -- fix item end tail
         
               r.Main_OnCommand(40635, 0) -- Remove Time Selection
         
               r.UpdateArrange()  
               r.UpdateTimeline()
         
               Wave:DrawGridGuides()
             -- getitem()
         
              TMInit_Status = 0
           end
     end

end

------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------SetTempo--------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

function SetTempo(bpm_in)
    r.Undo_BeginBlock();
    r.PreventUIRefresh(1);
    
     local lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')
     local item =  r.BR_GetMediaItemByGUID( 0, lastitem )
      if item ~= nil and bpm_in ~= nil then
                     take = r.GetActiveTake(item)
         
              local init_rate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
              local init_pos    = r.GetMediaItemInfo_Value(item, "D_POSITION")
              local init_length    = r.GetMediaItemInfo_Value(item, "D_LENGTH")
         
              local _, _, bpm1 = reaper.TimeMap_GetTimeSigAtTime(0, init_pos)
         
                      a1 = bpm_in
                      
                      r.AddTempoTimeSigMarker(0, init_pos, bpm_in, 0, 0, 0)
     
              local init_rate2 = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
              local init_length2    = r.GetMediaItemInfo_Value(item, "D_LENGTH")
              local init_pos2    = r.GetMediaItemInfo_Value(item, "D_POSITION")
                      
                      item_pos_end = init_pos2+(init_length2*init_rate2)/init_rate
                      
                      r.AddTempoTimeSigMarker(0, item_pos_end, bpm1, 0, 0, 0)
     
          r.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", init_rate)
          r.SetMediaItemInfo_Value(item, 'D_LENGTH', init_length)
          FixLength() -- fix item end tail
     
           r.Main_OnCommand(40635, 0) -- Remove Time Selection
     
           r.UpdateArrange()  
           r.UpdateTimeline()
     
           Wave:DrawGridGuides()
         --  getitem()
     end
    r.PreventUIRefresh(-1);
    r.Undo_EndBlock("Change Tempo",-1);
end

------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------SetRate()--------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

function SetRate() 
-----------------------------------------------------------------------
     local lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')
     local item =  r.BR_GetMediaItemByGUID( 0, lastitem )
        if item ~= nil and bpm4 ~= nil then
               take = r.GetActiveTake(item)
        
               local item_source = reaper.GetMediaItemTake_Source(take)
               local item_source_length = reaper.GetMediaSourceLength(item_source)
        
               local init_rate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
               local init_length = r.GetMediaItemInfo_Value(item, "D_LENGTH")
               local init_offs = r.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
        
               new_offs = init_offs*init_rate
               new_length = init_length*init_rate
        
              GetTempo()
              new_rate = (tempo/bpm4)*init_rate
        
                 r.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", new_rate)
                 r.SetMediaItemInfo_Value(item, "D_LENGTH", new_length/new_rate)
                 r.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", new_offs/new_rate)
          
              if SetTkMarker == 1 then
                  SetItemMarker( math_round(bpm4/init_rate,1) ) -- set take marker
              end  

    --          FixLength() -- fix item end tail
        
              r.Main_OnCommand(40635, 0) -- Remove Time Selection

              getitem_fast()
        
              r.UpdateArrange()
       end
-----------------------------------------------------------------------
end

------------------------------------------------------------------------------------------------------------------
----------------------------------------Set Item Marker-------------------------------------------------------

function SetItemMarker(input)
     local lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')
     local item =  r.BR_GetMediaItemByGUID( 0, lastitem )
            take = r.GetActiveTake(item)
            local rate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
            local st_offs = r.GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS' )
      r.DeleteTakeMarker(take, 0)
      r.SetTakeMarker(take, 0, ("" .. tostring(input) .. " bpm"), st_offs, 1)
   r.UpdateArrange()  
end

------------------------------------------------------------------------------------------------------------------------
----------------------------------------------Median------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

function Gate_Gl:SplsToMedian()
        
          local Pnts_m = {} -- collect transients only
          local Output_Table = {}

      local sPR_count_m = #self.Res_Points
                 for j=1, sPR_count_m, 2 do
                 local k = #Pnts_m+1
                    Pnts_m[k] = self.Res_Points[j]
                 end
                 table.sort(Pnts_m)
     
       local Pts_m_count = #Pnts_m
             for i = 2, Pts_m_count do -- collect time (spls) between transients to new table
                local prev_val = Pnts_m[i - 1]
                local val = Pnts_m[i]
                table.insert(Output_Table, val - prev_val)
             end
              
             -----http://lua-users.org/wiki/SimpleStats----------           
            -- calculation mean (median) script
             function median(t) 
               local temp={}
               for k,v in pairs(t) do
                 if type(v) == 'number' then
                   table.insert( temp, v )
                 end
               end
               table.sort( temp )
               local tmp = #temp
               if fmod(tmp,2) == 0 then
                  if tmp > 1 then
                      return ( temp[tmp/2] + temp[(tmp/2)+1] ) / 2
                  end
               else
                 return temp[ceil(tmp/2)]
               end
             end
            
             -- calculation deviation between transients
             function standardDeviation(t) 
               local m
               local vm
               local sum = 0
               local count = 0
               local result
               m = median(t)
               for k,v in pairs(t) do
                 if type(v) == 'number' then
                   vm = v - m
                   sum = sum + (vm * vm)
                   count = count + 1
                 end
               end
               result = sqrt(sum/(count-1))
               return result
             end
             ---------------------------------------------------

             median_spls = median(Output_Table)
                          
             if median_spls then
                 bpm_m = (60/(median_spls/srate)) -- calc bpm from samples

                 if Set_Rate_Feel.norm_val == 1 then 
                     bpm_m = bpm_m -- straight feel
                     else
                     bpm_m = bpm_m*0.666666666 -- triplet feel
                 end
     
     
                 if bpm_m < 40 then 
                     bpm_div = 0.125
                     elseif bpm_m >= 40 and bpm_m < 80 then 
                     bpm_div = 0.25
                     elseif bpm_m >= 80 and bpm_m < 160 then 
                     bpm_div = 0.5
                     elseif bpm_m >= 160 and bpm_m < 240 then 
                     bpm_div = 1
                     elseif bpm_m >= 240 and bpm_m < 320 then 
                     bpm_div = 1
                     elseif bpm_m >= 320 and bpm_m < 720 then 
                     bpm_div = 2
                     elseif bpm_m >= 720 and bpm_m < 1440 then
                     bpm_div = 4
                     elseif bpm_m >= 1440 then
                     bpm_div = 8    
                     else
                     bpm_div = 0.5    
                 end
     
                      bpm2 = bpm_m/(1*bpm_div)
                      bpm4 = bpm_m/(2*bpm_div)
                      bpm8 = bpm_m/(4*bpm_div)
     
                 if #Output_Table >=2 then
                        dev_simple = ((standardDeviation(Output_Table))*bpm_div)/1000 -- deviation 0 - 10
                        else
                        dev_simple = 3 
                  end
        
             end

end

------------------------------------------------------------------------------------------------------------------------
---------------------------------------Wave:BPM_Numbers()-------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

function Wave:BPM_Numbers()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  local zoom_coeff =   (gfx_width/1200)+1
  if zoom_coeff <= 2.044 then zoom_coeff = 2.044 end 
  self.x, self.w = (self.def_xywh[1]* Z_w/zoom_coeff)*2.045, (self.def_xywh[3]* Z_w/zoom_coeff)*2.045-- upd x,w
  self.x = self.x+(zoom_coeff-2.044)*380 -- auto slide to right when zoom
  self.x = math_round(self.x,2)
  self.w = math_round(self.w,2)
  self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* Z_h) -- upd y,h
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    local fnt_sz = 15
    fnt_sz = fnt_sz*(Z_h*1.25)
    local fnt = self.fnt

    if fnt_sz then
       if gfx.ext_retina == 1 then
          if fnt_sz <= 15 then fnt_sz = 15 end
          if fnt_sz >= 36 then fnt_sz = 36 end
          else
          if fnt_sz <= 12 then fnt_sz = 12 end
          if fnt_sz >= 30 then fnt_sz = 30 end
       end
    end 

     if dev_simple then
   
          if Set_Rate_Mode.norm_val == 1 then
              i_rate = InitRate()
              else
              i_rate = 1
           end

           if i_rate then
              bpm2c = (bpm2/i_rate) -- init_rate
              bpm4c = (bpm4/i_rate) -- init_rate
              bpm8c = (bpm8/i_rate) -- init_rate
           else
              bpm2c = bpm2
              bpm4c = bpm4
              bpm8c = bpm8
           end

           bpm2c = math_round(bpm2c,1)
           bpm4c = math_round(bpm4c,1)
           bpm8c = math_round(bpm8c,1)
    
           col_r = dev_simple/10 -- R
           col_g = abs((dev_simple/10)-1) -- G
           col_b = 0.2 -- B

         
            if (col_r <= 1 and col_r >= 0.2) and (col_g < 1 and col_g >= 0.2) then col_r = 1 end
            if (col_g <= 1 and col_g >= 0.2) and (col_r < 1 and col_r >= 0.2)  then col_g = 1 end
            
            if col_r < 0.2 then col_r = 0.2 end
            if col_g < 0.2 then col_g = 0.2 end
            
             col_r = col_r+TH[37]
             col_g = col_g+TH[37]
             col_b = col_b+TH[37]

            if col_r < 0 then col_r = 0 elseif col_r > 1 then col_r = 1 end -- limiters after btb theme correction
            if col_g < 0 then col_g = 0 elseif col_g > 1 then col_g = 1 end
            if col_b < 0 then col_b = 0 elseif col_b > 1 then col_b = 1 end

             gfx.set(col_r, col_g, col_b, TH[38]) -- bpm text color
     
      end

      bpm4c2 = bpm4c
      if bpm4c2 == nil then bpm4c2 = "BPM" end
      if bpm2c == nil then bpm2c = "" end
      if bpm8c == nil then bpm8c = "" end

      gfx.x = x+((w/1.030)-lbl_h)-(fnt_sz/2)
      gfx.y = y+(h*1.125)
      gfx.y = gfx.y/1.018
      gfx.setfont(1, "Arial", fnt_sz+1, 98) -- 98 - Bold flag
     
      gfx.drawstr("" .. tostring(bpm4c2) .. "") -- big bpm x1

      gfx.setfont(1, "Arial", fnt_sz)
      gfx.set(TH[35][1], TH[35][2], TH[35][3], TH[35][4]-0.05)

      gfx.x = x+((w/1.030)-lbl_h)-(fnt_sz/2)
      gfx.y = y+fnt_sz-3+(h*1.125)
      gfx.y = gfx.y/1.020
      gfx.drawstr("" .. tostring(bpm8c) .. "") -- bpm below (x0.5)

      gfx.x = x+((w/1.030)-lbl_h)-(fnt_sz/2)
      gfx.y = y-fnt_sz+4+(h*1.125)
      gfx.y = gfx.y/1.020
      gfx.drawstr("" .. tostring(bpm2c) .. "") -- bpm above (x2)

end

--------------------------------------------------------------------------------
-- Gate -  manual_Correction ---------------------------------------------------
--------------------------------------------------------------------------------
function Gate_Gl:manual_Correction()
    -- Change Velo, Move, Del Line ---------------
    if self.cap_ln and (Guides.norm_val == 1) then
        -- Change Velo ---------------------------
        if Ctrl and Midi_Sampler.norm_val == 2 and mouse_pos_height < 355 then
            local curs_x = Wave.x + (self.Res_Points[self.cap_ln] - self.start_smpl) * self.Xsc  -- x coord
            local curs_y = min(max(gfx.mouse_y, Wave.y), Wave.y+Wave.h)                            -- y coord
            gfx.set(1, 1, 1, 0.8) -- cursor color -- цвет курсора
            gfx.line(curs_x-12, curs_y, curs_x+12, curs_y) -- cursor line
            gfx.line(curs_x, curs_y-12, curs_x, curs_y+12) -- cursor line
            gfx.circle(curs_x, curs_y, 3, 0, 1)            -- cursor point
            --------------------
            local newVelo = (self.Yop-vel_point_lowest - curs_y)/((Wave.h*self.scale)-vel_point_lowest) -- velo from mouse y pos
            newVelo   = min(max(newVelo,0),1)
            --------------Edit Velocity Text---------------
            true_velocity = ceil(127*(Gate_VeloScale.norm_val+newVelo*self.scale))
            if true_velocity <= 0 then true_velocity = 1 end

             local fnt_sz = 60
             if gfx.ext_retina == 1 then
              fnt_sz = max(10,  fnt_sz* (Z_h)/2)
              fnt_sz = min(60, fnt_sz* Z_h)
             else
              fnt_sz = max(12,  fnt_sz* (Z_h)/2)
              fnt_sz = min(72, fnt_sz* Z_h)
             end
             
              gfx.setfont(1, "Arial", fnt_sz)
              gfx.set(TH[1][1],TH[1][2],TH[1][3],TH[1][4]) -- background color
              gfx.x = curs_x+10
              gfx.y = Wave.y*1.2
              gfx.rect(gfx.x,gfx.y,  0.14*gfx.h, 0.07* gfx.h, true)
              gfx.set(TH[13][1],TH[13][2],TH[13][3],TH[13][4]) -- velocity text color 
              gfx.drawstr("" .. true_velocity .. "", 1|4, (curs_x+(0.005*gfx.w))+(0.14*gfx.h), (0.19*gfx.h)-10)
            --------------------
            self.Res_Points[self.cap_ln+1] = {newVelo, newVelo}   -- veloRMS, veloPeak from mouse y
        end

        -- Move Line -----------------------------
        if not Ctrl and (mouse_pos_height >= 355 and mouse_pos_height <= 390)then 
            local curs_x = min(max(gfx.mouse_x, Wave.x), Wave.x + Wave.w) -- x coord
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

        -- Assist Lines and Arrows---------------------------
        if Aim_on == 1 and not Ctrl and not Wave:mouseDown() and not self.cap_ln and TrMrkrHover == 0 and ((mouse_pos_height >= 45 and mouse_pos_height <= 380 and mouse_pos_width >= 10 and mouse_pos_width <= 1034) or (mouse_pos_height >= 5 and mouse_pos_height <= 30 and mouse_pos_width >= 910 and mouse_pos_width <= 950))  then -- waveform box and aim button
            local curs_x = min(max(gfx.mouse_x, Wave.x), Wave.x + Wave.w) -- x coord
            local curs_y = min(max(gfx.mouse_y, Wave.y), self.Yop)        -- y coord
            gfx.set(TH[26][1],TH[26][2],TH[26][3],TH[26][4]) -- aim cursor color -- цвет курсора
            if (Guides.norm_val == 1) and Midi_Sampler.norm_val == 2 then
               gfx.line(curs_x-10, (curs_y), curs_x+10, (curs_y)) -- cursor line horizontal
            end
            gfx.line(curs_x,Wave.y+2, curs_x, (Wave.y*8.4)+1) -- cursor line

            triangle_size_as = 3*(0.7+Z_h/2)
            arrow_height = 12*(0.7+Z_h/2)
            const2 = 7.27
            gfx.triangle(curs_x-triangle_size_as, Wave.h*const, curs_x, (Wave.h*const)-arrow_height, curs_x+triangle_size_as+1, Wave.h*const) -- Triangle Arrow Bottom
            gfx.triangle(curs_x-triangle_size_as+1, (Wave.h/const2), curs_x, (Wave.h/const2)+(arrow_height-arrow_height/5), curs_x+triangle_size_as-1, (Wave.h/const2)) -- Triangle Arrow Top
            --------------------
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

    if not Wave:mouseR_Down() then -- stop BPM calculation while trig line inserting
        Gate_Gl:SplsToMedian()
        Gate_Gl:SetTempoMap()
    end

    if Snap_on == 1 then
        Gate_Gl:SnapAreaTables()
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

    local tracknum, midi_track, item, take, track_check, startppq_time, endppq_time, count_items_on_track, item2   
    local waveitem = 0

        r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVESEL'), 0)  -- Save track selection

        tracknum = r.GetMediaTrackInfo_Value(self.track, "IP_TRACKNUMBER")

        if Create_Replace.norm_val == 1 or Create_Replace2.norm_val == 1 then r.InsertTrackAtIndex(tracknum, false) end

        midi_track = r.GetTrack(0, tracknum)
        r.TrackList_AdjustWindows(0)


        r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVEALLSELITEMS1"),0) -- SWS: Save selected item(s)

-------------------------check item below and select--------------------------------------------------------

        r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME2"),0) -- Restore time selection

       if midi_track then

               r.Main_OnCommand(40289, 0) -- unselect all items
               GetLoopTimeRange()

               r.SetOnlyTrackSelected(midi_track)
                       
                count_items_on_track = reaper.CountTrackMediaItems(midi_track)
       
                for i=0, count_items_on_track-1 do -- try to select item below
                   item2 = reaper.GetTrackMediaItem(midi_track, i)          
                       if item2 then;
                               item_pos =  r.GetMediaItemInfo_Value( item2, 'D_POSITION' )
                               item_length = r.GetMediaItemInfo_Value( item2, 'D_LENGTH' )
                               item_end = item_pos + item_length
                              if (item_pos >= self.sel_start and item_pos < self.sel_end) or (item_end <= self.sel_end and item_end > self.sel_start) or (item_pos < self.sel_start and item_end > self.sel_end) then
                                     r.SetMediaItemSelected(item2, true)
                                     take = r.GetActiveTake(item2)
                                     if take then
                                           if not r.TakeIsMIDI(take) then waveitem = 1  end --set status if wave item below
                                     end
                              end
                        end
                end
              ---------------------------------------------------------------------------
               if not r.GetSelectedMediaItem(0, 0) then -- create new item if none
                  local track2, newitem
                  track2 = r.GetSelectedTrack(0, 0)
                  newitem = r.CreateNewMIDIItemInProj(track2, self.sel_start, self.sel_end, false) 
                  r.SetMediaItemInfo_Value(newitem, "B_UISEL", 1)
               end
       end

----------------------------------------------------------------------------------------------------------------

     track_check = r.GetMediaTrackInfo_Value(r.GetSelectedTrack(0, 0), "IP_TRACKNUMBER") -- if no track or wave item below

          if tracknum == track_check or waveitem == 1 then 
                      if Midi_Sampler.norm_val == 2 or Midi_Sampler.norm_val == 3 then
                         r.InsertTrackAtIndex(tracknum, false) -- create new track
                      end
                  midi_track = r.GetTrack(0, track_check)
                  r.Main_OnCommand(40419, 0) -- select item below
                  r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTTIME2"),0) -- Restore time selection
                  r.Main_OnCommand(40718, 0) -- select item in time selection
          end 


          if waveitem == 1 then -- create new item on new track if wave item below
                  trackx = reaper.GetSelectedTrack(0, 0)
                  tracknum2 = r.GetMediaTrackInfo_Value(trackx, "IP_TRACKNUMBER")
                  midi_track2 = r.GetTrack(0, tracknum2-2)
                  midiItem =   r.CreateNewMIDIItemInProj(midi_track2, self.sel_start, self.sel_end, false)
                  r.SetMediaItemInfo_Value(midiItem, "B_UISEL", 1)
          end

------------------------------------------------- Del old notes ---------------------------------------------

        item = r.GetSelectedMediaItem(0, 0)

        if item then 
             if tracknum == track_check then 
                 item = r.CreateNewMIDIItemInProj(midi_track, self.sel_start, self.sel_end, false)
             end
           take = r.GetActiveTake(item) 
             else
           item = r.CreateNewMIDIItemInProj(midi_track, self.sel_start, self.sel_end, false)
           take = r.GetActiveTake(item)
        end

            if take and r.TakeIsMIDI(take) then
               local ret, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)
               local note = 0
                -- Del old notes --
                for i=1, notecnt do
                    local ret, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(take, note)

                    startppq_time = reaper.MIDI_GetProjTimeFromPPQPos(take, startppq)
                    endppq_time = reaper.MIDI_GetProjTimeFromPPQPos(take, endppq)

                        if Midi_Sampler.norm_val == 3 then
                                  if pitch and (startppq_time >= self.sel_start and startppq_time <= self.sel_end) or (endppq_time <= self.sel_end and endppq_time >= self.sel_start) then -- check selection area
                                     r.MIDI_DeleteNote(take, note); note = note-1 -- del note and update counter
                                  end  
                        elseif Midi_Sampler.norm_val == 2 then
                                  local findpitch
                                if Notes_On == 1 then
                                    findpitch = 34 + OutNote2.norm_val  -- from checkbox
                                    else
                                    findpitch = 34 + OutNote2.norm_val  -- from checkbox
                                end
                             if (startppq_time >= self.sel_start and startppq_time <= self.sel_end) or (endppq_time <= self.sel_end and endppq_time >= self.sel_start) then
                                  if pitch==findpitch then 
                                     reaper.MIDI_DeleteNote(take, note); note = note-1 -- del note witch findpitch and update counter
                                  end  
                             end
                        end
                    note = note+1
                end
             end
---------------------------------------------------------------------------------------------------------
        return item, take
end

--------------------------------------------------------------------------------------------------------------

function Wave:Just_Slice()

if Slice_Status == 1 or MouseUpX == 1 then

MouseUpX = 0
Slice_Status = 0
Reset_Status = 1
Slice_BPM_Reset_Status = 1

r.PreventUIRefresh(1)

r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVESEL'), 0)  -- Save track selection

sel_tracks_items() -- select for a multitrack check
UnSelectMIDIAndEmptyItems()
selected_tracks_count = r.CountSelectedTracks(0)
count_itms =  r.CountSelectedMediaItems(0)

if count_itms ~= 0 then  
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
end -- take reverse check

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

    if tkrev == 0 then -- if reversed item, then glue
       r.Main_OnCommand(40548, 0)  -- Heal Splits
    elseif tkrev == 1 then
      r.Main_OnCommand(41588, 0)  -- Glue
      getitem_fast()
    end

sel_tracks_items() -- select for a multitrack check
selected_tracks_count = r.CountSelectedTracks(0)
count_itms =  r.CountSelectedMediaItems(0)

if count_itms > selected_tracks_count and selected_tracks_count > 1 then  -- sliced multitrack

 if Slice_Init_Status == 0 then---------------------------------glue------------------------------

          GlueMultitrack() -- glue 

   Wave:Destroy_Track_Accessor() -- Destroy previos AA
   if Wave:Create_Track_Accessor() then Wave:Processing() end
   
   InitTrackItemName()

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

if (count_itms > 1 and selected_tracks_count > 1) and GroupingWhenSlicing == 1 then  -- multitrack

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
             
           if i<points_cnt then next_startppqpos = (self.sel_start + Gate_Gl.Res_Points[i]/srate)         
            end

         if Midi_sampler_offs_stat == 1 then
            cutpos = next_startppqpos - 0.002 -- -2ms
            elseif Pitch_Det_offs_stat == 1 then
            cutpos = next_startppqpos + 0.001 -- +1ms
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

 self.Grid_Points_S = self.Grid_Points_S or {}
 local sw_shift = 0
 local _, division, swingmode, swingamt = r.GetSetProjectGrid(0, 0)

    for i=1, #self.Grid_Points_S or 0 do --split by grid 

   if Swing_on == 1 and swing_slider_amont ~= 0 then
         sw_shift = swingamt*(1-abs(division-1))
         if IsEven(i) == false and swingmode == 1 then 
             sw_shift = sw_shift*tempo_corr                    
             else
             sw_shift = 0
         end
    end
               
            r.SetEditCurPos((self.Grid_Points_S[i]/srate)+(0.5/1000)+sw_shift,0,0)
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

--  r.Main_OnCommand(r.NamedCommandLookup("_SWS_AWFILLGAPSQUICK"),0) -- fill gaps 

    FillGaps()


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
Markers_BPM_Reset_Status = 1
if Random_Status == 1 or Markers_Status == 1 then  
Wave:Reset_All()
end

Markers_BPM_Reset_Status = 1

 r.Undo_BeginBlock() 
r.PreventUIRefresh(1)


r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVESEL'), 0)  -- Save track selection

sel_tracks_items() -- select for a multitrack check
UnSelectMIDIAndEmptyItems()
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
 local sw_shift = 0
 local _, division, swingmode, swingamt = r.GetSetProjectGrid(0, 0)
      for i=1, #self.Grid_Points_S do

   if Swing_on == 1 and swing_slider_amont ~= 0 then
         sw_shift = swingamt*(1-abs(division-1))
         if IsEven(i) == false and swingmode == 1 then 
             sw_shift = sw_shift*tempo_corr                    
             else
             sw_shift = 0
         end
    end
       
            r.SetEditCurPos((self.Grid_Points_S[i]/srate)+sw_shift,0,0)
        
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
r.PreventUIRefresh(1)
if Random_Status == 1 or Trigg_Status == 1 then
   if  Slice_Status == 1 then
     r.Main_OnCommand(40029, 0)  -- Undo
   else
     r.Main_OnCommand(40029, 0)  -- Undo
       if Pitch_Det_Status == 1 then
           r.Main_OnCommand(40029, 0)  -- Undo
           else
           r.Main_OnCommand(40548, 0)     -- Heal Slices
       end
   end
Random_Status = 0
Trigg_Status = 0
Pitch_Det_Status = 0
end

SliceQ_Init_Status = 1

Slice_Status = 1

if Reset_Status == 1 then

if Markers_Status ~= 0 or Slice_Init_Status ~= 0 then

 r.Undo_BeginBlock() 

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
     if char == 27 or char == -1 or (reaper.time_precise() - time) > timer then ErrM_St_rs = 0 return else ErrM_St_rs = 1 end
local Get_Sel_ErrMsg = ErrMsg:new(580,35,260,45, 1, 1, 1, 1, "Something went wrong. Use Undo (Ctrl+Z)")
local ErrMsg_TB = {Get_Sel_ErrMsg}
ErrMsg_Status = 1
     for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
   gfx.update()
  r.defer(Msg)
end
end
if ErrM_St_rs ~= 1 then
Msg()
end

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

if Markers_BPM_Reset_Status == 0 and Slice_BPM_Reset_Status == 0 then

    if SetBPMStatus_ResetRate == 1 then
       RestoreInitRate()
       getitem_fast()
       SetBPMStatus_ResetRate = 0
    end
    
    if SetBPMStatus_Reset == 1 then
       DelTempo()
       SetBPMStatus_Reset = 0
    end

end

 r.PreventUIRefresh(-1)
    -------------------------------------------
    r.Undo_EndBlock("Reset_All", -1)   
 
Markers_BPM_Reset_Status = 0
Slice_BPM_Reset_Status = 0
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
    if item ~= nil then
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
     end

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
        if ForcePitchBend == 1 then
              r.TrackFX_SetParamNormalized( track, rs5k_pos, 16, (1/12)*PitchBend ) -- pitch bend
        end
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
                MIDI_Base_Oct = tonumber(r.GetExtState('MK_Slicer_3','MIDI_Base_Oct'))or 2;
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


-------------------------------------------------------------------
function TransposeNotesToKickSnareHat()

local collect_pitch = {}
local retval, ret, sel, muted, startppq, endppq, chan, pitch, vel
 local item = r.GetSelectedMediaItem(0, 0)
       if item then take = r.GetActiveTake(item) 

                               item_pos =  r.GetMediaItemInfo_Value( item, 'D_POSITION' )
                               item_length = r.GetMediaItemInfo_Value( item, 'D_LENGTH' )
                               item_end = item_pos + item_length

            if take and r.TakeIsMIDI(take) then
                 r.MIDI_DisableSort(take)
                 local _, notecnt = r.MIDI_CountEvts(take)
                 local note = 0
                 -----------------collect loudest notes to table-----------------------------
                  for i=1, notecnt do
                      ret, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(take, note)
                      if pitch and vel > HatThreshold then 
                           collect_pitch[i] = pitch
                      end  
                      note = note+1
                  end


 ----------------------------------- find lowest note---------------------------------
           local key, min = 1, collect_pitch[1]
           for k, v in ipairs(collect_pitch) do
               if collect_pitch[k] < min then
                   min = v
               end
           end

              GetLoopTimeRange()
            
                  if (item_pos >= start and item_pos <= ending) or (item_end <= ending and item_end >= start) or (item_pos < start and item_end > ending) then
                  --------------------------------------set new pitch-----------------------------------
                            local _, notes = r.MIDI_CountEvts(take)
                            for i = 0, notes-1 do
                              retval, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(take, i)
                              if min then
                                   r.MIDI_SetNote(take, i, sel, muted, startppq, endppq, chan, pitch+(KickNote-min), vel) -- kick and overal transpose
                               end
                               if vel <= HatThreshold then
                                   r.MIDI_SetNote(take, i, sel, muted, startppq, endppq, chan, HatNote, vel) -- hat
                               end
                            end
                  
                  --------------------------------------set new pitch 2nd pass------------------------
                            local _, notes = r.MIDI_CountEvts(take)
                            for i = 0, notes-1 do
                              retval, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(take, i)
                                    if pitch < 37 then
                                       r.MIDI_SetNote(take, i, sel, muted, startppq, endppq, chan, KickNote, vel) -- any lowest to kick
                                    end
                               if vel > HatThreshold then
                                    if pitch >= 37 then
                                       r.MIDI_SetNote(take, i, sel, muted, startppq, endppq, chan, SnareNote, vel) -- snare
                                    end
                                end
                            end
                  
                  --------------------------------------set vel 100 if Velocity Off------------------------
                           if Pitch_Det_Options.norm_val ~= 1 and (Pitch_Preset.norm_val == 1 or Pitch_Preset.norm_val == 2) then 
                                 local _, notes = r.MIDI_CountEvts(take)
                                 for i = 0, notes-1 do
                                   retval, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(take, i)
                                   r.MIDI_SetNote(take, i, sel, muted, startppq, endppq, chan, pitch, 100) -- set vel 100
                                 end
                           end
                  end
            
  
      r.MIDI_Sort(take)  
      r.UpdateItemInProject(item)
   end
r.UpdateArrange()
end

end


--------------------------------------------------------------------------------
---  Create MIDI  --------------------------------------------------------------
--------------------------------------------------------------------------------
-- Создает миди-ноты в соответствии с настройками и полученными из аудио данными
function Wave:Create_MIDI()
  r.Undo_BeginBlock() 
  r.PreventUIRefresh(1) 
  -------------------------------------------
    local item, take = Wave:GetSet_MIDITake()
    if not take then return end 
    -- Velocity scale ----------
    local mode = VeloMode.norm_val
    local velo_scale  = Gate_VeloScale.form_val2 - Gate_VeloScale.form_val
    local velo_offset = Gate_VeloScale.form_val
    -- Note parameters ---------
    Trigger_Oct_Shift = tonumber(r.GetExtState('MK_Slicer_3','Trigger_Oct_Shift'))or 0;
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
        startppqpos = r.MIDI_GetPPQPosFromProjTime(take, self.sel_start + (Gate_Gl.Res_Points[i]/srate)+0.0005 )
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
  r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTALLSELITEMS1'), 0) -- SWS: Restore saved selected item(s)
  r.Main_OnCommand(40635, 0) -- Time selection: Remove (unselect) time selection
  r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTORESEL'), 0)  -- Restore track selection

  r.SetEditCurPos(cursorpos,0,0) 

  r.PreventUIRefresh(-1)
  r.Undo_EndBlock("Create Trigger MIDI", -1) 
end
------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---  Create Pitched MIDI  --------------------------------------------------------------
--------------------------------------------------------------------------------

function Wave:Detect_pitch()

     r.Undo_BeginBlock() 

         local peakrate
         local peakrate2 = 200
         local item_table = {p0sition_id, note_id, duration_id, vel_id, a_end, power}

         local attThresh_dB = -6  -- curve level above which the script turns on 
         local relThresh_dB = -12  -- curve level below which the script turns off

         if Pitch_Preset.norm_val == 1 then
             pitch_preset = 0.025 -- Drums
             peakrate = 1000
             HatThreshold = 70 -- velocity. Lowest vel becomes to hat, highest becomes to snare.
             elseif Pitch_Preset.norm_val == 2 then
             pitch_preset = 0.005 -- Drums 2
             peakrate = 1000
             HatThreshold = 85 -- velocity. Lowest vel becomes to hat, highest becomes to snare.
             attThresh_dB = -6
             relThresh_dB = -14
             elseif Pitch_Preset.norm_val == 3 then
             pitch_preset = 0.005 -- Percussion
             peakrate = 1000
             attThresh_dB = -6
             relThresh_dB = -16
             elseif Pitch_Preset.norm_val == 4 then
             pitch_preset = 0.0626 -- Bass
             peakrate = 100 
             elseif Pitch_Preset.norm_val == 5 then
             pitch_preset = 0.0626 -- Default
             peakrate = 1000
             elseif Pitch_Preset.norm_val == 6 then
             pitch_preset = 0.04 -- Melodic
             peakrate = 1000
             elseif Pitch_Preset.norm_val == 7 then
             pitch_preset = 0.1 -- Complex
             peakrate = 100
             else
             pitch_preset = 0.0626
             peakrate = 1000
         end

                    local nn = pitch_preset*tempo_corr 
                    local buffsize = srate/50 

                    relThresh  = 10^(relThresh_dB/20)
                    attThresh  = 10^(attThresh_dB/20)
                    
          local n_spls, want_extra_type, buf2, retval2

          function FrequencyToName_Drums(f)
              local n = {'1', '1', '1', '1', '1', '1', '1', '2', '2', '2', '3', '3',
                              '3', '4', '4', '4', '5', '5', '5', '6', '6', '6', '7', '7',
                             '7', '8', '8', '8', '9', '9', '9', '10', '10', '10', '11', '11',
                             '11', '12', '12', '12', '13', '13', '13', '14', '14', '14', '15', '15',
                             '15', '16', '16', '16', '17', '17', '17', '18', '18', '18', '19', '19',
                             '19', '20', '20', '20', '21', '21', '21', '22', '22', '22', '23', '23',
                             '23', '24', '24', '24', '25', '25', '25', '26', '26', '26', '27', '27',
                             '27', '28', '28', '28', '29', '29', '29', '30', '30', '30', '31', '31',
                             '31', '32', '32', '32', '33', '33', '33', '34', '34', '34', '35', '35',
                             '35', '36', '36', '36', '37', '37', '37', '38', '38', '38', '39', '39',
                             '39', '40', '40', '40', '41', '41', '41', '42', '42', '42', '42', '42'}
              local dist = (132 * logx(f / 6.875) / logx(2048) % 132)
              local dist_rnd = floor(dist + 0.5) % 132
              return n[dist_rnd + 1]+18
          end

          function FrequencyToName(f)
              local n = {'-3', '-2', '-1', '0', '1', '2', '3', '4', '5', '6', '7', '8',
                              '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
                             '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31', '32',
                             '33', '34', '35', '36', '37', '38', '39', '40', '41', '42', '43', '44',
                             '45', '46', '47', '48', '49', '50', '51', '52', '53', '54', '55', '56',
                             '57', '58', '59', '60', '61', '62', '63', '64', '65', '66', '67', '68',
                             '69', '70', '71', '72', '73', '74', '75', '76', '77', '78', '79', '80',
                             '81', '82', '83', '84', '85', '86', '87', '88', '89', '90', '91', '92',
                             '93', '94', '95', '96', '97', '98', '99', '100', '101', '102', '103', '104',
                             '105', '106', '107', '108', '109', '110', '111', '112', '113', '114', '115', '116',
                             '117', '118', '119', '120', '121', '122', '123', '124', '125', '126', '127', '128'}
              local dist = (132 * logx(f / 6.875) / logx(2048) % 132)
              local dist_rnd = floor(dist + 0.5) % 132
              return n[dist_rnd + 1]
          end

---------------------------------------------
  local items = r.CountSelectedMediaItems(0)

     for i=0, items-1 do
     
        item = r.GetSelectedMediaItem(0,i);
          
           if item then

                    take = r.GetActiveTake( item )
     
                    p0sition = r.GetMediaItemInfo_Value(item, "D_POSITION")
                    l3ngth = r.GetMediaItemInfo_Value(item, "D_LENGTH")
                    note_duration = p0sition+l3ngth
                    note_duration_halved = p0sition+(l3ngth/2)

               if take then

       -------------------------------------------Vel detection -------------------------------------------------------------
            if Pitch_Det_Options.norm_val == 1 or Pitch_Preset.norm_val == 1 or Pitch_Preset.norm_val == 2 then
                     local source = r.GetMediaItemTake_Source(take)    
                     local accessor = r.CreateTakeAudioAccessor(take)
                     local channels = 1 -- r.GetMediaSourceNumChannels(source)
                     local buffer = r.new_array(srate*channels)
                     r.GetAudioAccessorSamples(accessor, srate, channels, 0.005, 1000, buffer)

                     local sampleMax = 0
                
                     for j = 1, buffsize do                               
                        local spls = abs(buffer[j])                 
                        sampleMax = max(spls, sampleMax)
                     end
                     
                     note_velocity = min(floor(logx(sampleMax+0.2)*50)+110, 127)
       
                     r.DestroyAudioAccessor(accessor)
               else
                     note_velocity = 100       
             end

       ------------------------------------------Pitch detection------------------------------------------------------------
                    local buf = r.new_array(3);
                    buf.clear()

                    local rv = r.GetMediaItemTake_Peaks(take, peakrate, p0sition+nn, 1, 1, 115, buf);
                    if rv & (1<<24) and (rv&0xfffff) > 0 then
                      local spl = buf[3];
                      note_tonal = spl&0x7fff
                      power = (spl>>15)/16384.0;
                    end

                 --   if power < 0.01 then note_tonal = nil end

                    if note_tonal ~= nil and note_tonal > 5 then -- and note_tonal > 5
                         if Pitch_Preset.norm_val == 1 or Pitch_Preset.norm_val == 2 then
                             note_name = FrequencyToName_Drums(note_tonal) --create note from frequency
                             else
                             note_name = FrequencyToName(note_tonal) --create note from frequency
                         end
                    end

      ----------------------------------------Length detection------------------------------------------------------------
                    if Pitch_Det_Options2.norm_val == 1 then
                                n_spls = ceil(l3ngth*peakrate2) -- Note: its Peak Samples!
                              
                                buf2 = r.new_array(n_spls * 2) -- max, min, only for 1 channel
                                buf2.clear()         -- Clear buffer
                                retval2 = r.GetMediaItemTake_Peaks(take, peakrate2, p0sition, 1, n_spls, 0, buf2)
                                ------------------
                              
                                local last_trig = false
                                for m = 1, n_spls do
                                    max_peak = max(abs(buf2[m]), abs(buf2[m+n_spls]))
                              
                                        if not last_trig and max_peak >= attThresh then
                                          last_trig = true
                                        elseif last_trig and max_peak < relThresh then
                                          a_ending = p0sition + (m-1)/peakrate2; last_trig = false
          
                                        end
                                end
                     end
                      ------------------      
                 end 
          end

        if a_ending == nil then a_ending = note_duration_halved end
        if a_ending <= p0sition then a_ending = note_duration_halved end
     
        item_table[i] = {
               p0sition_id = p0sition,
               note_id = note_name,
               duration_id = note_duration,   
               vel_id = note_velocity,  
               a_end = a_ending,
               pow = power      
               }

     end

-----------------
local items = r.CountSelectedMediaItems(0) --reset takes vol
for i=0, items-1 do 
 local item = r.GetSelectedMediaItem(0, i)
     local take = r.GetActiveTake(item)
         r.SetMediaItemTakeInfo_Value(take, 'D_VOL', 1)
end
------------------

No_Midi = 0  -- initial states
Item_Coloring = 0
 
if Create_Replace2.norm_val == 3 then No_Midi = 1 
elseif Create_Replace2.norm_val == 4 then No_Midi = 1; Item_Coloring = 1 
end 

----------------------------------Create MIDI-------------------------------------------------------------------------

        local next_startppqpos, p0sition2, note2, duration2, velocity2, a_end2, fix_length, detect_ppqpos2, pow2
        local items_t = #item_table 

   if No_Midi == 0 then --create midi
   
      local item_midi, take_midi = Wave:GetSet_MIDITake()
   
            if not take_midi then return end 
   
            r.MIDI_DisableSort(take_midi)
   
              if (Guides.norm_val == 1) then -- staccato note length in Transient mode
                     fix_length = 240
                        else  -- staccato note length in Grid mode (half grid)
                     local _, division, _, _ = r.GetSetProjectGrid(0,false)
                     fix_length = division*1920 
              end
   
             if items_t ~= 0 then
                      for k=0, items_t do  
                                            p0sition2 = item_table[k].p0sition_id       
                                            note2 = item_table[k].note_id  
                                            duration2 =  item_table[k].duration_id
                                            velocity2 =  item_table[k].vel_id
                                            a_end2 =  item_table[k].a_end
                                            pow2 =  item_table[k].pow
       
                           start_ppqpos = r.MIDI_GetPPQPosFromProjTime(take_midi, p0sition2 )
                           end_ppqpos = r.MIDI_GetPPQPosFromProjTime(take_midi, duration2 )
                           detect_ppqpos = r.MIDI_GetPPQPosFromProjTime(take_midi, a_end2 )
       
                           if (Guides.norm_val == 1) then -- 
                                 detect_ppqpos2 = detect_ppqpos
                                   else -- fix note length in Grid mode 
                                 detect_ppqpos2 = start_ppqpos+fix_length
                           end
       
                           if Pitch_Det_Options2.norm_val == 1 then -- length, detected
                                  note_length = detect_ppqpos
       
                                              ----------------del overlaps -----------
                                                  if k<items-1 then next_startppqpos = r.MIDI_GetPPQPosFromProjTime(take_midi, item_table[k+1].p0sition_id ) -- next note position
                                                        if next_startppqpos<detect_ppqpos then    -- del overlaps 
                                                            note_length = min(detect_ppqpos2, next_startppqpos) 
                                                        end
                                                  end
                                             -----------------------------------------
       
                           elseif Pitch_Det_Options2.norm_val == 2 then  -- staccato, fixed
       
                                 note_length = start_ppqpos+fix_length
                                              ----------------del overlaps -----------
                                                  if k<items-1 then next_startppqpos = r.MIDI_GetPPQPosFromProjTime(take_midi, item_table[k+1].p0sition_id ) -- next note position
                                                        if next_startppqpos<start_ppqpos+fix_length then    -- del overlaps 
                                                            note_length = min(end_ppqpos, next_startppqpos)-10
                                                        end
                                                  end
                                              if note_length > start_ppqpos+240 then note_length = start_ppqpos+240 end -- length limiter
                                             -----------------------------------------
                               elseif Pitch_Det_Options2.norm_val == 3 then  -- legato
                                  note_length = end_ppqpos-2
                           end
       
                            if k == 0 and velocity2 < 35 then note2 = nil end
       
                               if note2 then
                                   r.MIDI_InsertNote(take_midi, 1, 0, start_ppqpos, note_length, 0, note2, velocity2, true)
                               end
       
                       end -- end of Create MIDI
            end
            
                           r.MIDI_Sort(take_midi)           -- sort notes
                           r.UpdateItemInProject(item_midi) -- update item
   
       if Pitch_Preset.norm_val == 1 or Pitch_Preset.norm_val == 2 then TransposeNotesToKickSnareHat() end
    
           else -- or wave items renaming
   
      r.Undo_BeginBlock()
      r.PreventUIRefresh(1)
   
   -----------------------Rainbow Color Palette------------------------------------
   color1 = (194 << 16) | (70 << 8) | 70 -- rgb to native: (R << 16) | (G << 8) | B
   color2 = (193 << 16) | (109 << 8) | 85
   color3 = (193 << 16) | (142 << 8) | 73
   color4 = (197 << 16) | (178 << 8) | 90
   color5 = (125 << 16) | (183 << 8) | 74
   color6 = (83 << 16) | (183 << 8) | 111
   color7 = (85 << 16) | (189 << 8) | 189
   color8 = (77 << 16) | (160 << 8) | 177
   color9 = (98 << 16) | (135 << 8) | 183
   color10 = (109 << 16) | (98 << 8) | 187
   color11 = (156 << 16) | (80 << 8) | 189
   color12 = (198 << 16) | (88 << 8) | 133
   ----------------------------------------------------------------------------------
    
               local collect_pitch_x = {}
               local table_p = 0

     if Pitch_Preset.norm_val == 1 or Pitch_Preset.norm_val == 2 then -- if Drums or Drums2 presets
     
                   local track = r.GetSelectedTrack(0,0,0) -- first selected track
                   local items_count = r.CountSelectedMediaItems(0)   
                       for ii=0, items_count-1 do
                               local item = r.GetSelectedMediaItem(0,ii)
                               it_pitch = item_table[ii].note_id  
                               it_vel =  item_table[ii].vel_id
            
                               if it_pitch then
                                      it_pitch = tonumber(it_pitch) -- convert string "x" to number x
                
                                      if it_vel and it_vel > HatThreshold then 
                                           collect_pitch_x[table_p] = it_pitch
                                      end  
                              end
                        table_p = table_p+1
                        end
            
                ----------------------------------- find lowest note---------------------------------
                  local key_x, min_x = 1, collect_pitch_x[1]
                       for k, v in ipairs(collect_pitch_x) do
                           if collect_pitch_x[k] < min_x then
                               min_x = v
                           end
                       end
              
     end


   local    track = r.GetSelectedTrack(0,0,0) -- first selected track
   local    items_count = r.CountSelectedMediaItems(0)   
           for i=0, items_count-1 do
                   item = r.GetSelectedMediaItem(0,i)
                   take = r.GetActiveTake(item)
                   itm_name = item_table[i].note_id  
                   itm_vel =  item_table[i].vel_id
   
                     if itm_name then
   
                        itm_name = tonumber(itm_name) -- convert string "x" to number x


    if Pitch_Preset.norm_val == 1 or Pitch_Preset.norm_val == 2 then  -- drums

                       if min_x then
                             itm_name = itm_name+(KickNote-min_x) -- kick and overal pitch
                       end

                       if itm_vel <= HatThreshold then
                              itm_note = 'Hat' -- hats
                              color_x = color7
                         else
                           if itm_vel > HatThreshold then
                                if itm_name >= 37 then
                                    itm_note = 'Snare' -- snare
                                    color_x = color4
                                end
                            end
                       end

                       if itm_name < 37 and itm_vel > HatThreshold then
                          itm_note = 'Kick' -- any lowest to kick
                          color_x = color12
                       end

             itm_name_oct = ("" .. itm_note .. "") -- create note + octave number string

    else -- melodic

                        if itm_name % 12 == 0 or itm_name == 0 then itm_note = 'C' color_x = color1; -- convert note numbers to notes
                             elseif (itm_name+11) % 12 == 0 then itm_note = 'C#' color_x = color2;
                             elseif (itm_name+10) % 12 == 0 then itm_note = 'D' color_x = color3;
                             elseif (itm_name+9) % 12 == 0 then itm_note = 'D#' color_x = color4;
                             elseif (itm_name+8) % 12 == 0 then itm_note = 'E' color_x = color5;
                             elseif (itm_name+7) % 12 == 0 then itm_note = 'F' color_x = color6;
                             elseif (itm_name+6) % 12 == 0 then itm_note = 'F#' color_x = color7;
                             elseif (itm_name+5) % 12 == 0 then itm_note = 'G' color_x = color8;
                             elseif (itm_name+4) % 12 == 0 then itm_note = 'G#' color_x = color9;
                             elseif (itm_name+3) % 12 == 0 then itm_note = 'A' color_x = color10;
                             elseif (itm_name+2) % 12 == 0 then itm_note = 'A#' color_x = color11;
                             elseif (itm_name+1) % 12 == 0 then itm_note = 'B' color_x = color12;
                        end
   
        
                       if itm_name < 12 then add_oct = '-1' -- get octave numbers
                           elseif itm_name >= 12 and itm_name < 24 then add_oct = '0' 
                           elseif itm_name >= 24 and itm_name < 36 then add_oct = '1' 
                           elseif itm_name >= 36 and itm_name < 48 then add_oct = '2' 
                           elseif itm_name >= 48 and itm_name < 60 then add_oct = '3' 
                           elseif itm_name >= 60 and itm_name < 72 then add_oct = '4' 
                           elseif itm_name >= 72 and itm_name < 84 then add_oct = '5' 
                           elseif itm_name >= 84 and itm_name < 96 then add_oct = '6' 
                           elseif itm_name >= 96 and itm_name < 108 then add_oct = '7' 
                           elseif itm_name >= 108 and itm_name < 120 then add_oct = '8' 
                           elseif itm_name >= 120 then add_oct = '9' 
                       end
        
                       itm_name_oct = ("" .. itm_note .. add_oct .. "") -- create note + octave number string

      end

                       r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', itm_name_oct, 1) -- set name
                       if Item_Coloring == 1 then 
                           Cr, Cg, Cb = r.ColorFromNative(color_x)
                           r.SetMediaItemInfo_Value( item, "I_CUSTOMCOLOR", reaper.ColorToNative(Cr, Cg, Cb)|0x1000000 ) -- set color
                       end
                 end
            end
   
            r.PreventUIRefresh(-1)
            r.Undo_EndBlock('Renaming Item(s)', -1)
   
   end


end -- end of function Wave:Detect_pitch()

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
      if start_init ~= ending_init then
          time_sel_length = ending_init - start_init
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
     if char == 27 or char == -1 or (reaper.time_precise() - time) > timer then ErrM_St_s2 = 0 return else ErrM_St_s2 = 1 end
local Get_Sel_ErrMsg = ErrMsg:new(580,35,260,45, 1, 1, 1, 1, "Item is Too Short (<0.25s)")
local ErrMsg_TB = {Get_Sel_ErrMsg}
ErrMsg_Status = 1
     for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
   gfx.update()
  r.defer(Msg)
end
end
if ErrM_St_s2 ~= 1 then
Msg()
end
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

--------------------------------------------------------------------------------------------
---  Wave(Processing, drawing etc)  ---------------------------------------------------
--------------------------------------------------------------------------------------------
--- DRAW --------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--- Draw Original,Filtered --------------------------------------------------
--------------------------------------------------------------------------------
function Wave:Redraw()
    local x,y,w,h = self.def_xywh[1],self.def_xywh[2],self.def_xywh[3],self.def_xywh[4]
    ---------------
    gfx.dest = 1           -- set dest gfx buffer1
    gfx.a    = 1           -- gfx.a - for buf    
    gfx.setimgdim(1,-1,-1) -- clear buf1(Wave)
    gfx.setimgdim(1,w,h)   -- set gfx buffer w,h
    ---------------
      if ViewMode.norm_val == 1 then self:draw_waveform(1,  TH[7][1],TH[7][2],TH[7][3],TH[7][4]) -- Draw Original(1, r,g,b,a) -- цвет оригинальной и фильтрованной waveform
                                                  self:draw_waveform(2,  TH[6][1],TH[6][2],TH[6][3],TH[6][4]) -- Draw Filtered(2, r,g,b,a)
        elseif ViewMode.norm_val == 2 then self:draw_waveform(1, TH[8][1],TH[8][2],TH[8][3],TH[8][4]) -- Only original 
        elseif ViewMode.norm_val == 3 then self:draw_waveform(2,  TH[6][1],TH[6][2],TH[6][3],TH[6][4]) -- Only filtered 
      end
    ---------------
    gfx.dest = -1          -- set main gfx dest buffer
    ---------------
end

--------------------------------------------------------------
--------------------------------------------------------------
function Wave:draw_waveform(mode, r,g,b,a)
--local start_time = reaper.time_precise()
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
    -- уточнить, нужно сделать исправление для неориг. размера окна --
    -- next выходит за w*max_Zoom, а должен - макс. w*max_Zoom(51200) при max_Zoom=50 --
    for i=1, w do            
       local next = min(i*Zfact + Ppos, n_Peaks ) -- грубоватое исправление...
       local min_peak, max_peak, peak = 0, 0, 0 
        local i_next = i+1
          for p=curr, next do
              peak = Peak_TB[p][1]
              min_peak = min(min_peak, peak)
              peak = Peak_TB[p][2]
              max_peak = max(max_peak, peak)
          end
        curr = ceil(next)
        local y, y2 = Y - min_peak *Ysc, Y - max_peak *Ysc 
        gfx.set(r,g,b,a)   
        gfx.line(i,y, i,y2) -- peaks

        if TH[43] > 0 then
           gfx.set(r,g,b,TH[43]) 
           gfx.line(i+1,y-1, i+1,y2+1) -- additional peaks (blur/thickness)
           gfx.line(i-1,y-1, i-1,y2+1) -- 
        end

    end  
    ----------------------------
--reaper.ShowConsoleMsg("Full Process time = " .. reaper.time_precise()-start_time .. '\n') -- time test 
end

--------------------------------------------------------------
--------------------------------------------------------------
function Wave:Create_Peaks(mode) -- mode = 1 for original, mode = 2 for filtered
--local start_time = reaper.time_precise()
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
--reaper.ShowConsoleMsg("Full Process time = " .. reaper.time_precise()-start_time .. '\n') -- time test 
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
    self.X_scale    = w/self.selSamples                -- X_scale = w/lenght in samples
    self.Y_scale    = h/2.5                            -- Y_scale for waveform drawing
    ---------------------------------
    -- Some other values ------------
    self.crsx   = ceil(block_size/16)   -- one side "crossX"  -- use for discard some FFT artefacts(its non-nat, but in this case normally)
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
    -----------------------------
    -- Filter values --------------
    -----------------------------
    -- LP = HiFreq, HP = LowFreq --
    local Low_Freq, Hi_Freq =  HP_Freq.form_val, LP_Freq.form_val
    local bin_freq = srate/(block_size*2)          -- freq step 
    local lowband  = Low_Freq/bin_freq             -- low bin
    local hiband   = Hi_Freq/bin_freq              -- hi bin
    -- lowband, hiband to valid values(need even int) ------------
    lowband = floor(lowband/2)*2
    hiband  = ceil(hiband/2)*2  
    -------------------------------------------------------------------------
    -- Get Original(input) samples to in_buf >> to table >> create peaks ---
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
    -- Filtering >> samples to out_buf >> to table >> create peaks --------
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
                        -----------------------------------
                        -- Filter(use fft_real) -------------
                        -----------------------------------
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
---  Wave - Get - Set Cursors  --------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Wave:Get_Cursor() 
  local E_Curs = r.GetCursorPosition()
  --- edit cursor ---
  local insrc_Ecx = (E_Curs - self.sel_start) * srate * self.X_scale    -- cursor in source!
     insrc_Ecx_k = insrc_Ecx
     self.Ecx = (insrc_Ecx - self.Pos) * self.Zoom*Z_w                  -- Edit cursor
     if (self.Ecx >= 0 and self.Ecx <= self.w) then gfx.set(TH[20][1],TH[20][2],TH[20][3],TH[20][4]) -- main edit cursor color
        gfx.line(self.x + self.Ecx, self.y+2, self.x + self.Ecx, self.y+self.h -2 )
     end
     if self.Ecx >= 0 and self.Ecx <= self.w then gfx.set(1,1,1,1)
             grad_w1 = TH[21]*(0.7+Z_w/2)
             gfx.gradrect(((self.x+1) + self.Ecx)-grad_w1, self.y, grad_w1, self.h,        TH[20][1],TH[20][2],TH[20][3], 0.0,    0, 0, 0, TH[22] / grad_w1) -- grad back
             gfx.gradrect((self.x-1) + self.Ecx, self.y, grad_w1, self.h,        TH[20][1],TH[20][2],TH[20][3], TH[22],    0, 0, 0, -TH[22] / grad_w1) -- grad ahead
             Reaper_Cursor_Grab = 1
     end

  --- play cursor ---
  if r.GetPlayState()&1 == 1 then local P_Curs = r.GetPlayPosition()
     local insrc_Pcx = (P_Curs - self.sel_start) * srate * self.X_scale -- cursor in source!
     self.Pcx = (insrc_Pcx - self.Pos) * self.Zoom*Z_w                  -- Play cursor
     if self.Pcx >= 0 and self.Pcx <= self.w then gfx.set(TH[23][1],TH[23][2],TH[23][3],TH[23][4]) -- play cursor color  -- цвет плэй курсора
        gfx.line(self.x + self.Pcx, self.y, self.x + self.Pcx, self.y+self.h -1 )
          if not self:mouseDown() then
             grad_w2 = TH[24]*(0.7+Z_w/2)
             gfx.gradrect(((self.x+1) + self.Pcx)-grad_w2, self.y, grad_w2, self.h,        TH[23][1],TH[23][2],TH[23][3], 0.0,    0, 0, 0, TH[25] / grad_w2) -- grad back
             gfx.gradrect((self.x-1) + self.Pcx, self.y, grad_w2, self.h,        TH[23][1],TH[23][2],TH[23][3], TH[25],    0, 0, 0, -TH[25] / grad_w2) -- grad ahead
          end
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
       if Reaper_Cursor_Grab == 1 and (Snap_on == 0 or Guides.norm_val == 2) and mouse_pos_height <=355 then 
          r.SetEditCurPos(New_Pos, false, false)    -- true-seekplay(false-no seekplay) 
          Reaper_Cursor_Grab = 0
       end
    end
  end
end 

--------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------SnapArea------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
function GetItemParams()
     local lastitem = r.GetExtState('_Slicer_', 'ItemToSlice')
     local item =  r.BR_GetMediaItemByGUID( 0, lastitem )
           if item ~= nil then
                item_pos =  r.GetMediaItemInfo_Value( item, 'D_POSITION' )
                item_length = r.GetMediaItemInfo_Value( item, 'D_LENGTH' )
                item_end = item_pos + item_length
            end
end

SelAreaTable = {play_start_id, play_length_id}

function Gate_Gl:SnapAreaTables()

   local MousePnts= {} -- collect transients only
   local TrTable = {}

             local sPcount = #self.Res_Points
                 for j=1, sPcount, 2 do
                 local k = #MousePnts+1
                    MousePnts[k] = self.Res_Points[j]
                 end

              GetItemParams()

                 table.insert(MousePnts, 0)
                 table.insert(MousePnts, item_end*srate)
                 table.insert(MousePnts, (item_end*srate)-1/srate)
                 table.sort(MousePnts)

         local mpts = #MousePnts
             for i = 2, mpts do -- collect time (spls) between transients to new table
                local prev_val = MousePnts[i - 1]
                local val = MousePnts[i]
                table.insert(TrTable, prev_val)
                table.insert(TrTable, val - prev_val)
             end

St = 0
if TrTable ~= nil and Snap_on == 1 then

   local TrTbl = #TrTable
   for i = 1, TrTbl, 2 do
           local l_start_posx = TrTable[i]
           local l_lengthx = TrTable[i+1]
           local l_next_posx = TrTable[i+2]

         GetItemParams()

         if item ~= nil then

              if l_next_posx ~= nil and item_end ~= nil and item_pos ~= nil then
   
                   l_start_pos = ((l_start_posx)/srate)+item_pos
                   l_end_pos = ((l_start_posx)/srate)+((l_lengthx)/srate)+item_pos
                   l_length = ((l_lengthx)/srate)+item_pos
                   l_next = ((l_next_posx)/srate)+item_pos
   
                   local edit_cur_pos = r.GetCursorPosition()

                   play_start = (l_start_pos - item_pos) * srate * Wave.X_scale    -- l_start_pos
                   play_length = ((l_length) - item_pos) * srate * Wave.X_scale    -- l_length
   
                   l_next = (l_next - item_pos) * srate * Wave.X_scale    -- l_next
                   
                   mouse_pos = Wave.Pos + (gfx.mouse_x-Wave.x)/(Wave.Zoom*Z_w) -- its current mouse position in source!
                   if mouse_pos < 0 then mouse_pos = 0 elseif mouse_pos > 1024 then mouse_pos = 1024 end 

                   if Wave:mouseDown() or Wave:mouseRClick() then                   
                         local Edit_cur = (r.GetCursorPosition() - Wave.sel_start) * srate * Wave.X_scale    -- cursor in source!            
                         if (Edit_cur-4 <= mouse_pos and Edit_cur+4 >= mouse_pos)  then
                             mouse_pos1 = mouse_pos+0.05 -- "+" = left transient,
                             mouse_pos2 = mouse_pos+0.05 -- 
                             else
                             mouse_pos1 = mouse_pos-0.05 --  "-" = right transient
                             mouse_pos2 = mouse_pos-0.05 -- 
                         end               
                    end

                   if  ( Wave:mouseClick() or Wave:mouseRClick() or Slider_Status == 1 ) and St == 0 then  --   or self:mouseRClick() -- self:mouseUp() -- self:mouseClick()

                        if play_start_id ~= nil and play_length_id ~= nil and (mouse_pos_height > 380) then -- mouse hover imitation: if mouse on controls and controls changed, snap area stay in focus
                           mouse_pos1 = SelAreaTable.play_start_id+(SelAreaTable.play_length_id/8) -- or /2
                           mouse_pos2 = mouse_pos1
                        end

                        if mouse_pos1 == nil or mouse_pos2 == nil then mouse_pos1 = mouse_pos; mouse_pos2 = mouse_pos end

                        if play_start <= mouse_pos1 and l_next >= mouse_pos2 then -- if mouse between two transients
   
                                if r.GetPlayState()&1 == 1 and Wave:mouseClick() then -- autoplay by click while playback
                                   r.SetEditCurPos(l_start_pos, false, true)
                                end
  
                                r.SetEditCurPos((l_start_pos), false, false)    -- true-seekplay(false-no seekplay) 
  
                                if Snap_AutoPlay == 1 and (mouse_pos_height < 355 and mouse_pos_height > 45) and not Wave:mouseRClick() and Drag == 0 then
                                    if r.GetPlayState()&1 == 0 then
                                       r.OnPlayButton()
                                       else
                                          if edit_cur_pos == l_start_pos then
                                              r.OnStopButton()
                                              else
                                              r.OnPlayButton()
                                          end
                                    end
                                end   

                                if l_end_pos >= item_end then l_end_pos = item_end end
                                if l_start_pos == item_pos and (l_start_pos+0.05 >= l_end_pos) then l_start_pos = l_end_pos  end
                                r.GetSet_LoopTimeRange(1, true, (l_start_pos), l_end_pos, false) -- if loop
                                   
                               play_start_id = play_start  
                               play_length_id = play_length   
                                SelAreaTable = {
                                      play_start_id = play_start_id,
                                      play_length_id = play_length_id
                                      }
                               St = 1

                        end

                   end
   
              end
        end -- if item
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
Wave:DrawGridGuides()
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
    if (self:mouseDown() or self:mouseM_Down()) and not Shift and not Ctrl and (mouse_pos_height <= 355) then 
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
            if elapsed >= 0.17 then
              gfx.setcursor(32512)  --set "arrow" cursor
              Drag = 0 -- snap area condition
              runcheck = 0
                return
            else
              gfx.setcursor(32644, 1) --set "hand" cursor
              Drag = 1 -- snap area condition
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

     if SetBPMButtonStatus == 1 then
             time_startt = reaper.time_precise()       
      local  function Maint()     
                 local elapsedt = reaper.time_precise() - time_startt      
                 if elapsedt >= 0.2 then
                BPMButtonStatus2 = 0
                   runcheckt = 0
                     return
                 else
               BPMButtonStatus2 = 1
                   runcheckt = 1
                     reaper.defer(Maint)
                 end           
             end
             
             if runcheckt ~= 1 then
                Maint()
             SetBPMButtonStatus = 0
             end
     end

end

--------------------------------------------------------------------------------
---  Insert from buffer(inc. Get_Mouse) ----------------------------------------
--------------------------------------------------------------------------------
function Wave:from_gfxBuffer()

    if not Z_w or not Z_h then return end -- return if zoom not defined
    self.x, self.w = (self.def_xywh[1]* Z_w) , (self.def_xywh[3]* Z_w) -- upd x,w
    self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* Z_h) -- upd y,h
  
    -- draw Wave frame, axis -------------
    self:draw_rect()
    self:draw_frame_waveform()
     -- Insert Wave from gfx buffer1 ------
    gfx.a = 1 -- gfx.a for blit
    local srcw, srch = Wave.def_xywh[3], Wave.def_xywh[4] -- its always def values 
    if WFiltering == 0 then gfx.mode = 4 end
    gfx.blit(1, 1, 0, 0, 0, srcw, srch,  self.x, self.y, self.w, self.h)

     -- draw Yellow Selection Box  -------------
         if play_length_id ~= nil and Snap_on == 1 and Guides.norm_val == 1 then 
            
                      sel_width = SelAreaTable.play_length_id     
                      sel_start_s = SelAreaTable.play_start_id     
                      
                      if sel_width ~= nil and sel_start_s ~= nil then 
                          gfx.set(TH[18][1],TH[18][2],TH[18][3], gfx.imgui and TH[18][4]%1 or TH[18][4]) -- snap area color                         
                          sel_width  = (sel_width)*self.Zoom*Z_w  -- zoom and width correction        
                          sel_start_s  = (sel_start_s - self.Pos)*self.Zoom*Z_w  -- zoom and width correction        
                          gfx.rect(sel_start_s+self.x, self.y, sel_width, self.h,true) -- draw btn body
                      end
         else
         SelAreaTable = {} -- reset table
       end

       -- Get Mouse -------------------------
       self:Get_Mouse()     -- get mouse(for zoom, move etc) 

end  

function Wave:CursorTop()

     if self.sel_start ~= nil  then
         local insrc_Ecx3 = (r.GetCursorPosition() - self.sel_start) * srate * self.X_scale    -- cursor in source!
         self.Ecx3 = (insrc_Ecx3 - self.Pos) * self.Zoom*Z_w                  -- Edit cursor
         if self.Ecx3 >= 0 and self.Ecx3 <= self.w then gfx.set(0.9,0.9,0.9,0.7) -- loop edit cursor color 
            gfx.line(self.x + self.Ecx3, self.y/1.5, self.x + self.Ecx3, (self.y+self.h)/9.3 )
         end
     
         if r.GetPlayState()&1 == 1 then
              local insrc_Pcx2 = (r.GetPlayPosition() - self.sel_start) * srate * self.X_scale -- cursor in source!
              self.Pcx2 = (insrc_Pcx2 - self.Pos) * self.Zoom*Z_w                  -- Play cursor
              if self.Pcx2 >= 0 and self.Pcx2 <= self.w then gfx.set(0.9,0.9,0.9,0.4) -- play cursor color  -- цвет плэй курсора
                     gfx.line(self.x + self.Pcx2, self.y/1.5, self.x + self.Pcx2, (self.y+self.h)/9.3 )
              end
         end
     end
end

function Wave:ForegroundBorders()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = (self.def_xywh[1]* Z_w) , (self.def_xywh[3]* Z_w) -- upd x,w
  self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* Z_h) -- upd y,h
--------------left and right borders-----------------------------------
    gfx.set(TH[3][1],TH[3][2],TH[3][3],1)
    gfx.rect(0, self.y,self.x, self.h,true) -- left

    gfx.set(TH[3][1],TH[3][2],TH[3][3],1)
    gfx.rect(self.x+1024*Z_w, self.y,self.x+2, self.h+2,true) -- right
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
 gfx.set(TH[33][1], TH[33][2], TH[33][3], TH[33][4]) -- цвет текста инфо
 local ZH_correction = Z_h*40
 gfx.x, gfx.y = self.x+23 * (Z_w+Z_h)-ZH_correction, (self.y+1*(Z_h*3))-15
 gfx.drawstr(
  [[
    Select an item (max 300sec).
    It is better to use items shorter than 60sec.
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
    Left or Middle Drag - Move View (Horizontal Scroll),
    Left Click - Set Edit Cursor,
    Left Drag Small Flag - Move Marker,
    Ctrl+Left Drag - Change Velocity,
    Right Click on Marker - Delete Marker,
    Right Click on Empty Space - Insert Marker.
  ]]) 
end

function Wave:show_process_wait()

      if Wave.State then     
             local Get_Sel_ErrMsg = ErrMsg:new(580,35,260,45, 1, 1, 1, 1, "Processing, wait...")
             local ErrMsg_TB = {Get_Sel_ErrMsg}
             ErrMsg_Status = 1
                  for key,btn    in pairs(ErrMsg_TB)   do btn:draw()    
             end           
       else           
             local fnt_sz = 100
             if gfx.ext_retina == 1 then
              fnt_sz = max(14,  fnt_sz* (Z_h)/2)
              fnt_sz = min(80, fnt_sz* Z_h)
             else
              fnt_sz = max(17,  fnt_sz* (Z_h)/2)
              fnt_sz = min(96, fnt_sz* Z_h)
             end

              gfx.setfont(1, "Arial", fnt_sz)
              gfx.set(TH[33][1], TH[33][2], TH[33][3], TH[33][4]) -- цвет текста инфо
              local ZH_correction = Z_h*40
              gfx.x, gfx.y = self.x+23 * (Z_w+Z_h)-ZH_correction, (self.y+1*(Z_h*3))+120
             
              gfx.drawstr("Processing, wait...", 1, gfx.w, gfx.h)
       end
end


function Wave:show_init_track_item_name()

if TableTI.item == '' then TableTI.item = 'NoName' end

      if TableTI.track and TableTI.item then    
             local text_sys = TextShort(TableTI.item, 50)
             local Get_Sel_SysMsg = SysMsg:new(550,15,470,20, 1, 1, 1, 1, "Track ".. TableTI.track ..",  Item: ".. text_sys .."")
             local SysMsg_TB = {Get_Sel_SysMsg}
             if ShowTrackAndItemInfo == 1 then
                  for key,btn    in pairs(SysMsg_TB)   do btn:draw()   end      
             end
       end
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
         if ShowRuler == 1 then Gate_Gl:draw_Ruler() end -- Draw Ruler lines


        local _, division, swing, _ = r.GetSetProjectGrid(0,false)

------------------------------------MouseWheelOverTheButtons---------------------------------------
       if gfx.mouse_wheel ~= 0 and (mouse_pos_height >= 5 and mouse_pos_height <= 25 and mouse_pos_width >= 50 and  mouse_pos_width <= 342) then  
           if gfx.mouse_wheel < 0 then 
                 _, division, swing, _ = r.GetSetProjectGrid(0,false)
                division = division*2 
               if division >= 1 then division = 1 end
                r.GetSetProjectGrid(0,true,division, swing)
           end
           if gfx.mouse_wheel > 0then 
                _, division, swing, _ = r.GetSetProjectGrid(0,false)
               division = division/2 
               if division <= 0.015625 then division = 0.015625 end
               r.GetSetProjectGrid(0,true,division, swing)
           end
       Wave:DrawGridGuides()
       end
--------------------------------------------------------------------------------------------------------

        if division < 0.0078125 then division = 0.0078125 end --128th
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
           if (1//division) % 3 == 0 then Trplts = true else Trplts = false end;
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

           if Aim_on == 1 then
              for key,btn    in pairs(Frame_Aim_TB)   do btn:draw()    end 
              else
              for key,btn    in pairs(Frame_Aim_TB2)   do btn:draw()    end 
          end

           if Snap_on == 1 then
              for key,btn    in pairs(Frame_Snap_TB)   do btn:draw()    end 
              else
              for key,btn    in pairs(Frame_Snap_TB2)   do btn:draw()    end 
          end

          if Loop_on == 1 then
              for key,btn    in pairs(Frame_Loop_TB)   do btn:draw()    end 
              for key,btn    in pairs(Loop_TB)   do btn:draw()    end 
              for key,btn    in pairs(LoopBtn_TB)   do btn:draw()    end 
              else
              for key,btn    in pairs(Frame_Loop_TB2)   do btn:draw()    end 
              for key,btn    in pairs(LoopBtn_TB)   do btn:draw()    end 
          end

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

     if Midi_Sampler.norm_val == 1 then
         for key,frame  in pairs(MIDI_Mode_Color1_TB)    do frame:draw()  end 
     elseif Midi_Sampler.norm_val == 2 then
         for key,frame  in pairs(MIDI_Mode_Color2_TB)    do frame:draw()  end 
     elseif Midi_Sampler.norm_val == 3 then
         for key,frame  in pairs(MIDI_Mode_Color3_TB)    do frame:draw()  end 
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
     else
         if  Random_Setup ~= 1 then
              for key,frame  in pairs(Preset_TB)    do frame:draw()  end 
                   if Midi_Sampler.norm_val == 3 then
                        for key,frame  in pairs(Pitch_Det_Options_TB)    do frame:draw()  end  
                   end  
         end
     end

                   if (Midi_Sampler.norm_val == 2) and Random_Setup ~= 1 then        
                        for key,frame  in pairs(Create_Replace_TB)    do frame:draw()  end 
                        for key,frame  in pairs(Create_Replace_TB2)    do frame:draw()  end 
                  end

                   if (Midi_Sampler.norm_val == 3) and Random_Setup ~= 1 then        
                        for key,frame  in pairs(Create_Replace_TB)    do frame:draw()  end 
                        for key,frame  in pairs(Create_Replace_TB3)    do frame:draw()  end 
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

     if Guides.norm_val ~= 1 and Midi_Sampler.norm_val == 2 and Random_Setup ~= 1 then
           for key,frame  in pairs(Frame_TB2_Trigg)    do frame:draw()  end -- mode fill
     end

        Wave:BPM_Numbers()

     if ErrMsg_Status == 0 and Random_Setup ~= 1 then
          Wave:show_init_track_item_name()
     end

Wave:ForegroundBorders()
Wave:CursorTop()

    if not Wave.State then  
          Wave:show_help()      -- else show help
    end

end

------------------------------------
-- MouseWheel Related Functions ---
------------------------------------

function MW_doit_slider(mwsl)

      local div
      if mwsl == 1 then
        div = 400
        elseif  mwsl == 0 or mwsl == nil then
        div = 5000
      end

      if Wave.State then

           if (ending and start) and ending - start > 45 then

               time_c = (ending - start)/div
               if time_c > 1.0 then time_c = 1.0 end

                   time_start = reaper.time_precise()   
                   local function Main_d()    
                       local elapsed = reaper.time_precise() - time_start       
                       if elapsed >= time_c then
                            ErrMsg_Status = 0
                       ----------------------------------------------------------------
                       Gate_Gl:Apply_toFiltered() -- redraw transient markers
                       Slice_Status = 1
                        ---------------------------------------------------------------
                         runcheckd = 0
                           return
                       else
                          ------------------------------
                          ErrMsg_Status = 1
                          Wave:show_process_wait()
                          ------------------------------
                         runcheckd = 1
                           reaper.defer(Main_d)
                       end           
                   end
                   if runcheckd ~= 1 then
                      Main_d()
                   end----------------------------------
           else
                       Gate_Gl:Apply_toFiltered() -- redraw transient markers
                       Slice_Status = 1
           end

      end
end

function MW_doit_slider_Fine(mwsf)

      local div
      if mwsf == 1 then
        div = 400
        elseif  mwsf == 0 or mwsf == nil then
        div = 5000
      end

      if Wave.State then

           if (ending and start) and ending - start > 45 then

               time_c = (ending - start)/div
               if time_c > 1.0 then time_c = 1.0 end
                   time_start = reaper.time_precise()   
                   local function Main_d()    
                       local elapsed = reaper.time_precise() - time_start       
                       if elapsed >= time_c then
                            ErrMsg_Status = 0
                       ----------------------------------------------------------------
                        OffsSldCorr = (Offset_Sld.form_val/1000*srate)
                        Gate_Gl:Apply_toFiltered()
                        Wave:DrawGridGuides()
                        Slice_Status = 1
                        ---------------------------------------------------------------
                         runcheckd = 0
                           return
                       else
                          ------------------------------
                          ErrMsg_Status = 1
                          Wave:show_process_wait()
                          ------------------------------
                         runcheckd = 1
                           reaper.defer(Main_d)
                       end           
                   end
                   if runcheckd ~= 1 then
                      Main_d()
                   end----------------------------------
           else
                  OffsSldCorr = (Offset_Sld.form_val/1000*srate)
                  Gate_Gl:Apply_toFiltered()
                  Wave:DrawGridGuides()
                  Slice_Status = 1
           end

      end
end

function MW_doit_slider_Swing()
   if Wave.State then
           time_start = reaper.time_precise()       
           local function Mainz()     
               local elapsed = reaper.time_precise() - time_start       
               if elapsed >= 0.2 then
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
end

function MW_doit_slider_fgain(mwfg)

      local div
      if mwfg == 1 then
        div = 400
        elseif  mwfg == 0 or mwfg == nil then
        div = 4000
      end

      if Wave.State then

            if (ending and start) and ending - start > 30 then

               time_c = (ending - start)/div
               if time_c > 1.0 then time_c = 1.0 end

                    time_start = reaper.time_precise()   
                    local function Main_f()    
                        local elapsed = reaper.time_precise() - time_start       
                        if elapsed >= time_c then
                             ErrMsg_Status = 0
                        ----------------------------------------------------------------
                        Gate_Gl:Apply_toFiltered() -- redraw transient markers
                        Wave:Redraw() --redraw filtered gain and filters
                        Slice_Status = 1
                         ---------------------------------------------------------------
                          runcheckf = 0
                            return
                        else
                           ------------------------------
                           ErrMsg_Status = 1
                           Wave:show_process_wait()
                           ------------------------------
                          runcheckf = 1
                            reaper.defer(Main_f)
                        end           
                    end
                    if runcheckf ~= 1 then
                       Main_f()
                    end----------------------------------
            else
                    Gate_Gl:Apply_toFiltered() -- redraw transient markers
                    Wave:Redraw() --redraw filtered gain and filters
                    Slice_Status = 1
            end

      end
end

function MW_doit_slider_comlpex(mw)  -- redraw lowcut and highcut

      local div
      if mw == 1 then
        div = 200
        elseif  mw == 0 or mw == nil then
        div = 2000
      end

      if Wave.State then
 if (ending and start) then time_c = (ending - start)/div end
     if time_c > 1.0 then time_c = 1.0 end
        time_start = reaper.time_precise()   
        local function Main_i()    
            local elapsed = reaper.time_precise() - time_start  
            if  elapsed >= time_c then

                 ErrMsg_Status = 0
            ----------------------------------------------------------------
            Wave:Processing()
            Gate_Gl:Apply_toFiltered() -- redraw transient markers
            Wave:Redraw() --redraw filtered gain and filters
            Slice_Status = 1
             ---------------------------------------------------------------
              runchecki = 0
                return
            else
               ------------------------------
               ErrMsg_Status = 1
               Wave:show_process_wait()
               ------------------------------
              runchecki = 1
                reaper.defer(Main_i)
            end           
        end
        if runchecki ~= 1 then
           Main_i()
        end----------------------------------

      end
end

function MW_doit_checkbox()
      if Wave.State then
         Wave.Reset_All()
         Wave:DrawGridGuides()
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
   if Guides.norm_val == 1 and Midi_Sampler.norm_val ~= 3 then
r.Main_OnCommand(41588, 0) -- glue (если изменены rate, pitch, больше одного айтема и не миди айтем, то клей. Требуется для корректной работы кнопки MIDI).
end 
end

function MIDITrigger()
   if Guides.norm_val == 1 then
     if Wave.State then Wave:Create_MIDI() end
     --Wave.State = false -- reset Wave.State
   end 
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function MIDITrigger_pitched()

 tggl_state = r.GetToggleCommandState(42294)
 
 if tggl_state == 0 then r.Main_OnCommand(42303,0) end
 
 r.Main_OnCommand(40178, 0) -- Set take channel mode to mono (downmix)
 r.Main_OnCommand(40108, 0) -- Normalize
 
 ----------------add_time getting and calculation-------------------
 lastitemq = r.GetExtState('_Slicer_', 'ItemToSlice')   
 itemq =  r.BR_GetMediaItemByGUID( 0, lastitemq )
 
 sel_tracks_items()
 local track = r.GetSelectedTrack(0,0)
 trackID = track and r.CSurf_TrackToID( track, false )
 local count_tracks = r.CountTracks(0)
   if itemq ~= nil then
        takeq = r.GetActiveTake( itemq )
        local source = r.GetMediaItemTake_Source(takeq) 
        local true_length, lengthIsQN = reaper.GetMediaSourceLength(source);

        at_const = TimeForPeaksRebuild
        add_time =  at_const+(true_length)/(50/at_const) or 4 -- content processing time depends on the duration of the wav file
      ---------------------------------------------------------------------
       ----------------------timer-------------------------
        local time_start = reaper.time_precise()       
        local function Main()     
            local elapsed = reaper.time_precise() - time_start       
            if elapsed >= add_time then

                 r.PreventUIRefresh(1)
                 -----------------------------------------------
                 if Wave.State then Wave:Detect_pitch() end
                 -----------------------------------------------

                 ---------------we finish what we started in GetSet_MIDITake()-----------------

            if Create_Replace2.norm_val ~= 3 and Create_Replace2.norm_val ~= 4 then
                 r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTALLSELITEMS1'), 0) -- SWS: Restore saved selected item(s)
            end

                 r.Main_OnCommand(40635, 0) -- Time selection: Remove (unselect) time selection

                 if tggl_state == 0 then r.Main_OnCommand(42303,0) end -- 42294

                 r.Main_OnCommand(40176, 0)  -- Set take channel mode to normal

            if Create_Replace2.norm_val ~= 3 and Create_Replace2.norm_val ~= 4 then
                 r.Main_OnCommand(40548, 0)  -- Heal Splits
            end

                 r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTORESEL'), 0)  -- Restore track selection
                 Pitch_Det_offs_stat = 0
                 Trigg_Status = 1
                 Pitch_Det_Status = 1
                 MIDIPitch_Status = 0
                 r.SetEditCurPos(cursorpos,0,0)

                ------------------------------------
                 if count_tracks == trackID then
                 r.Main_OnCommand(40913,0)  -- Track: Vertical scroll selected tracks into view
                 end
                 ------------------------------------

                 r.PreventUIRefresh(-1);
                 r.UpdateArrange()
                 ---------------------------------------------------------------

              runcheck = 0
                return
            else
             ---------
              runcheck = 1
                reaper.defer(Main)
            end           
        end
        
        if runcheck ~= 1 then
           Main()
        end
        ------------------------------------------------------
   end

end

------------------------------------------------------------------------------------

function store_settings() --store dock position
   r.SetExtState("MK_Slicer_3", "dock", gfx.dock(-1), true)
end

function store_settings2() --store sliders/checkboxes
     if RememberLast == 1 then 
        r.SetExtState('MK_Slicer_3','Guides.norm_val',Guides.norm_val,true);
        if Notes_On == 1 then OutNote.norm_val = OutNote2.norm_val end
        r.SetExtState('MK_Slicer_3','OutNote.norm_val',OutNote.norm_val,true);
        r.SetExtState('MK_Slicer_3','Midi_Sampler.norm_val',Midi_Sampler.norm_val,true);
        r.SetExtState('MK_Slicer_3','Sampler_preset.norm_val',Sampler_preset.norm_val,true);
        r.SetExtState('MK_Slicer_3','Create_Replace.norm_val',Create_Replace.norm_val,true);
        r.SetExtState('MK_Slicer_3','Create_Replace2.norm_val',Create_Replace2.norm_val,true);
        r.SetExtState('MK_Slicer_3','Set_Rate_Feel.norm_val',Set_Rate_Feel.norm_val,true);
        r.SetExtState('MK_Slicer_3','Set_Rate_Mode.norm_val',Set_Rate_Mode.norm_val,true);
        r.SetExtState('MK_Slicer_3','Pitch_Det_Options.norm_val',Pitch_Det_Options.norm_val,true);
        r.SetExtState('MK_Slicer_3','Pitch_Det_Options2.norm_val',Pitch_Det_Options2.norm_val,true);
        r.SetExtState('MK_Slicer_3','QuantizeStrength',QStrength_Sld.form_val,true);
        r.SetExtState('MK_Slicer_3','HF_Slider',HP_Freq.norm_val,true);
        r.SetExtState('MK_Slicer_3','LF_Slider',LP_Freq.norm_val,true);
        r.SetExtState('MK_Slicer_3','Sens_Slider',Gate_Sensitivity.norm_val,true);
        r.SetExtState('MK_Slicer_3','Offs_Slider',Offset_Sld.norm_val,true);
        if XFadeOff == 0 then
           r.SetExtState('MK_Slicer_3','CrossfadeTime',XFade_Sld.form_val,true);
        end
        r.SetExtState('MK_Slicer_3','PitchDetect',Pitch_Preset.norm_val,true);
        r.SetExtState('MK_Slicer_3','Gate_VeloScale.norm_val',Gate_VeloScale.norm_val,true);
        r.SetExtState('MK_Slicer_3','Gate_VeloScale.norm_val2',Gate_VeloScale.norm_val2,true);

        r.SetExtState('MK_Slicer_3','RandV_Sld.norm_val',RandV_Sld.norm_val,true);
        r.SetExtState('MK_Slicer_3','RandPan_Sld.norm_val',RandPan_Sld.norm_val,true);
        r.SetExtState('MK_Slicer_3','RandPtch_Sld.norm_val',RandPtch_Sld.norm_val,true);
        r.SetExtState('MK_Slicer_3','RandPos_Sld.norm_val',RandPos_Sld.norm_val,true);
        r.SetExtState('MK_Slicer_3','RandRev_Sld.norm_val',RandRev_Sld.norm_val,true);

          r.SetExtState('MK_Slicer_3','Snap_on',Snap_on,true);
          r.SetExtState('MK_Slicer_3','Aim_on',Aim_on,true);
     end
end

-------------------------------------------------------------------------------
--   INIT   --------------------------------------------------------------------
-------------------------------------------------------------------------------
function Init()

  --Dock ------
   dock_pos = tonumber(r.GetExtState("MK_Slicer_3", "dock"))
       if Docked == 1 then
         if not dock_pos or dock_pos == 0 then dock_pos = 1025 end
           dock_pos = dock_pos | 1
           gfx.dock(dock_pos)
           xpos = 400
           ypos = 320
           else
           dock_pos = 0
           xpos = tonumber(r.GetExtState("MK_Slicer_3", "window_x")) or 400
           ypos = tonumber(r.GetExtState("MK_Slicer_3", "window_y")) or 320
        end

    -- Some gfx Wnd Default Values ---------------
    local R,G,B = ceil(TH[3][1]*255),ceil(TH[3][2]*255),ceil(TH[3][3]*255)             -- 0...255 format -- цвет основного окна
    local Wnd_bgd = R + G*256 + B*65536 -- red+green*256+blue*65536  
    local Wnd_Title = "MK Slicer v3.03" .. " " .. theme_name .. " " .. RG_status .. ""
    local Wnd_Dock, Wnd_X,Wnd_Y = dock_pos, xpos, ypos

     -- set init fonts/size
     gfx.setfont(1, "Arial", 12)
     gfx.setfont(2, "Arial", 14)
     gfx.setfont(3, "Arial", 16)
     gfx.setfont(4, "Arial", 18)
     gfx.setfont(5, "Arial", 20)
     gfx.setfont(6, "Arial", 22)
     gfx.setfont(7, "Arial", 36)
     gfx.setfont(8, "Arial", 40)
     gfx.setfont(9, "Arial", 72)
     gfx.setfont(10, "Arial", 80)

 --   Wnd_W,Wnd_H = 1044,490 -- global values(used for define zoom level)

       Wnd_W = tonumber(r.GetExtState("MK_Slicer_3", "zoomW")) or 1044
       Wnd_H = tonumber(r.GetExtState("MK_Slicer_3", "zoomH")) or 490
       if Wnd_W == (nil or 0) then Wnd_W = 1044 end
       if Wnd_H == (nil or 0) then Wnd_H = 490 end
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

local rng1x = rng1
local rng2x = rng2

local Loop_onx = Loop_on
local Guides_norm_val = Guides.norm_val

    -- zoom level -- 
    Wnd_WZ = tonumber(r.GetExtState("MK_Slicer_3", "zoomWZ")) or 1044
    Wnd_HZ = tonumber(r.GetExtState("MK_Slicer_3", "zoomHZ")) or 490
    if Wnd_WZ == (nil or 0) then Wnd_WZ = 1044 end
    if Wnd_HZ == (nil or 0) then Wnd_HZ = 490 end

    Z_w, Z_h = gfx.w/Wnd_WZ, gfx.h/Wnd_HZ
    gfx_width = gfx.w
    if Z_w<0.63 then Z_w = 0.63 elseif Z_w>4 then Z_w = 4 end --2.2
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

    if Loop_on == 1 then
       isloop = true
         else
       isloop = false
    end


      if Loop_onx ~= Loop_on and Snap_on == 0 then
          r.GetSet_LoopTimeRange(true, true, 0, 0, false) -- loop off when Loop_on == 0
      end


    if loop_start and Wave.State and (rng1x ~= rng1 or rng2x ~= rng2) or Loop_onx ~= Loop_on or BPMButtonStatus2 == 1 or Guides_norm_val ~= Guides.norm_val then
        if Snap_on == 1 and Loop_on == 1 then
             if Guides.norm_val == 2 then
                r.GetSet_LoopTimeRange(isloop, true, rng1, rng2, false)
             end
           elseif (Snap_on == 0 and Loop_on == 0) then
             r.GetSet_LoopTimeRange(1, true, 0, 0, false)
           elseif (Snap_on == 1 and Loop_on == 0) then
             if Guides.norm_val == 2 then
                r.GetSet_LoopTimeRange(1, true, 0, 0, false)
             end
           elseif Snap_on == 0 and Loop_on == 1 then
             r.GetSet_LoopTimeRange(isloop, true, rng1, rng2, false)
        end
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
 
         if CursorFollowsLoop == 1 and Loop_on == 1 then
             cursorstart, _ = r.GetSet_LoopTimeRange( 0, 1, 0, 0, 0 )
             r.SetEditCurPos(cursorstart, false, false)
         end

         if PlayMode == 1 and Snap_on == 0 then
            r.Main_OnCommand(40073, 0) -- play/pause
            else
            r.Main_OnCommand(40044, 0) -- play/stop
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
    r.SetExtState("MK_Slicer_3", "window_x", xpos, true)
    r.SetExtState("MK_Slicer_3", "window_y", ypos, true)
    r.SetExtState("MK_Slicer_3", "zoomW", Wnd_W, true)
    r.SetExtState("MK_Slicer_3", "zoomH", Wnd_H, true)
    r.SetExtState("MK_Slicer_3", "zoomWZ", Wnd_WZ, true)
    r.SetExtState("MK_Slicer_3", "zoomHZ", Wnd_HZ, true)
end

function getitem()

     time_start = reaper.time_precise()       
        local function Main()     
            local elapsed = reaper.time_precise() - time_start       
            if elapsed >= 0.01 then
                 ErrMsg_Status = 0
            ----------------------------------------------------------------
                        r.Undo_BeginBlock() 
                        r.PreventUIRefresh(1)
                        Muted = 0
                        if number_of_takes == 1 and mute_check == 1 then 
                        r.Main_OnCommand(40175, 0) 
                        Muted = 1
                        end
                        
                        ----------------------------
                           Wave:Destroy_Track_Accessor() -- Destroy previos AA(освобождает память etc)
                           Wave.State = false -- reset Wave.State
                           if Wave:Create_Track_Accessor() then Wave:Processing()
                              if Wave.State then
                                 Wave:Redraw()
                                 Gate_Gl:Apply_toFiltered() 
                                 Wave:DrawGridGuides()
                              end
                           end
                        ----------------------------------
                        
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
             ErrMsg_Status = 1
              runcheck = 1
                reaper.defer(Main)
            end           
        end
        
        if runcheck ~= 1 then
           Main()
        end

end


function getitem_fast()

        r.Undo_BeginBlock() 
        r.PreventUIRefresh(1)
        Muted = 0
        if number_of_takes == 1 and mute_check == 1 then 
        r.Main_OnCommand(40175, 0) 
        Muted = 1
        end
        
        ----------------------------
           Wave:Destroy_Track_Accessor() -- Destroy previos AA(освобождает память etc)
           Wave.State = false -- reset Wave.State
           if Wave:Create_Track_Accessor() then Wave:Processing()
              if Wave.State then
                 Wave:Redraw()
                 Gate_Gl:Apply_toFiltered() 
                 Wave:DrawGridGuides()
              end
           end
        ----------------------------------
        
        if Muted == 1 then
        r.Main_OnCommand(40175, 0) 
        end
        r.PreventUIRefresh(-1)
        r.Undo_EndBlock("Toggle Item Mute", -1) 

end

function SaveRateDelay()

     time_start_srd = reaper.time_precise()       
        local function Main()     
            local elapsed = reaper.time_precise() - time_start_srd       
            if elapsed >= 0.2 then
            ---------------------------------------------------------
                              if Wave.State then
                                 SaveInitRate()
                              end
                        ----------------------------------
              runcheck_srd = 0
                return
            else
              runcheck_srd = 1
                reaper.defer(Main)
            end           
        end
        
        if runcheck_srd ~= 1 then
           Main()
        end

end
SaveRateDelay()
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
                         r.SetExtState("MK_Slicer_3", "window_x", xpos, true)
                         r.SetExtState("MK_Slicer_3", "window_y", ypos, true)
                         r.SetExtState("MK_Slicer_3", "zoomW", Wnd_W, true)
                         r.SetExtState("MK_Slicer_3", "zoomH", Wnd_H, true)
                         r.SetExtState("MK_Slicer_3", "zoomWZ", Wnd_WZ, true)
                         r.SetExtState("MK_Slicer_3", "zoomHZ", Wnd_HZ, true)
                     
                          gfx.quit()
                          Docked = 1
                          dock_pos = tonumber(r.GetExtState("MK_Slicer_3", "dock"))
                          if not dock_pos or dock_pos == 0 then dock_pos = 1025 end
                          dock_pos = dock_pos | 1
                          gfx.dock(dock_pos)
                          xpos = 400
                          ypos = 320
                          local Wnd_Title = "MK Slicer v3.03"
                          local Wnd_Dock, Wnd_X,Wnd_Y = dock_pos, xpos, ypos
                          gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )

                     else

                         r.SetExtState("MK_Slicer_3", "dock", gfx.dock(-1), true)
                         gfx.quit()
                         Docked = 0
                         dock_pos = 0
                         xpos = tonumber(r.GetExtState("MK_Slicer_3", "window_x")) or 400
                         ypos = tonumber(r.GetExtState("MK_Slicer_3", "window_y")) or 320
                         local Wnd_Title = "MK Slicer v3.03"
                         local Wnd_Dock, Wnd_X,Wnd_Y = dock_pos, xpos, ypos
                         if Wnd_Y == (nil or 0) then Wnd_Y = Wnd_Y+25 end -- correction for window header visibility
                         gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )
                      
                         Wnd_WZ = tonumber(r.GetExtState("MK_Slicer_3", "zoomWZ")) or 1044
                         Wnd_HZ = tonumber(r.GetExtState("MK_Slicer_3", "zoomHZ")) or 490
                         if Wnd_WZ == (nil or 0) then Wnd_WZ = 1044 end
                         if Wnd_HZ == (nil or 0) then Wnd_HZ = 490 end
                      
                         Z_w, Z_h = gfx.w/Wnd_WZ, gfx.h/Wnd_HZ
                      
                         if Z_w<0.63 then Z_w = 0.63 elseif Z_w>2.2 then Z_w = 2.2 end 
                         if Z_h<0.63 then Z_h = 0.63 elseif Z_h>2.2 then Z_h = 2.2 end 
                     end
          r.SetExtState('MK_Slicer_3','Docked',Docked,true);
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
          r.SetExtState('MK_Slicer_3','EscToExit',EscToExit,true);
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
          r.SetExtState('MK_Slicer_3','AutoScroll',AutoScroll,true);
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
          r.SetExtState('MK_Slicer_3','PlayMode',PlayMode,true);
end


if Snap_AutoPlay == 1 then
item35 = context_menu:add_item({label = "Snap Area: Auto Play by Click", toggleable = true, selected = true})
else
item35 = context_menu:add_item({label = "Snap Area: Auto Play by Click", toggleable = true, selected = false})
end
item35.command = function()
                     if item35.selected == true then 
                     Snap_AutoPlay = 1
                     else
                     Snap_AutoPlay = 0
                     end
          r.SetExtState('MK_Slicer_3','Snap_AutoPlay',Snap_AutoPlay,true);
end


if Loop_on == 1 then
item9 = context_menu:add_item({label = "Loop is Enabled when the Script Starts", toggleable = true, selected = true})
else
item9 = context_menu:add_item({label = "Loop is Enabled when the Script Starts", toggleable = true, selected = false})
end
item9.command = function()
                     if item9.selected == true then 
                     Loop_on = 1
                     else
                     Loop_on = 0
                     end
          r.SetExtState('MK_Slicer_3','Loop_on',Loop_on,true);
end

if Sync_on == 1 then
item33 = context_menu:add_item({label = "Sync Waveform and Arrange View|", toggleable = true, selected = true})
else
item33 = context_menu:add_item({label = "Sync Waveform and Arrange View|", toggleable = true, selected = false})
end
item33.command = function()
                     if item33.selected == true then 
                     Sync_on = 1
                     else
                     Sync_on = 0
                     end
          r.SetExtState('MK_Slicer_3','Sync_on',Sync_on,true);
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
          r.SetExtState('MK_Slicer_3','ZeroCrossings',ZeroCrossings,true);
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
          r.SetExtState('MK_Slicer_3','ItemFadesOverride',ItemFadesOverride,true);
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
          r.SetExtState('MK_Slicer_3','MIDISamplerCopyFX',MIDISamplerCopyFX,true);
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
          r.SetExtState('MK_Slicer_3','MIDISamplerCopyRouting',MIDISamplerCopyRouting,true);
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
          r.SetExtState('MK_Slicer_3','Notes_On',Notes_On,true);
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
          r.SetExtState('MK_Slicer_3','ObeyingTheSelection',ObeyingTheSelection,true);
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
          r.SetExtState('MK_Slicer_3','ObeyingItemSelection',ObeyingItemSelection,true);

end


item17 = context_menu:add_item({label = ">User Settings (Advanced)"})
item17.command = function()

end


item18 = context_menu:add_item({label = "Set User Defaults", toggleable = false})
item18.command = function()
user_defaults()
end


item19 = context_menu:add_item({label = "Reset All Setted User Defaults|", toggleable = false})
item19.command = function()

      r.SetExtState('MK_Slicer_3','DefaultXFadeTime',15,true);
      r.SetExtState('MK_Slicer_3','DefaultP_Slider',5,true);
      r.SetExtState('MK_Slicer_3','DefaultQStrength',100,true);
      r.SetExtState('MK_Slicer_3','DefaultLP',1,true);
      r.SetExtState('MK_Slicer_3','DefaultHP',0.3312,true);
      r.SetExtState('MK_Slicer_3','DefaultSens',0.63,true);
      r.SetExtState('MK_Slicer_3','DefaultOffset',0.5,true);
      r.SetExtState('MK_Slicer_3','MIDI_Base_Oct',2,true);
      r.SetExtState('MK_Slicer_3','Trigger_Oct_Shift',0,true);

end

item37 = context_menu:add_item({label = "Experimental Options", active = false})

item20 = context_menu:add_item({label = "|XFades and Fill Gaps On/Off", toggleable = false})
item20.command = function()
 if XFadeOff == 1 then XFadeOff = 0
elseif XFadeOff == 0 then XFadeOff = 1
end
      r.SetExtState('MK_Slicer_3','XFadeOff',XFadeOff,true);
end


if FontAntiAliasing == 1 then
           item36 = context_menu:add_item({label = "Font AntiAliasing (Need RealmGUI, Restart required)", toggleable = true, selected = true, active = true})
           else
           item36 = context_menu:add_item({label = "Font AntiAliasing (Need RealmGUI, Restart required)", toggleable = true, selected = false, active = true})
end
item36.command = function()
                     if item36.selected == true then 
                     FontAntiAliasing = 1
                     else
                     FontAntiAliasing = 0
                     end
          r.SetExtState('MK_Slicer_3','FontAntiAliasing',FontAntiAliasing,true);
end


item21 = context_menu:add_item({label = "|Reset Controls to User Defaults (Restart required)|<", toggleable = false})
item21.command = function()
Reset_to_def = 1
  --sliders--
      DefaultXFadeTime = tonumber(r.GetExtState('MK_Slicer_3','DefaultXFadeTime'))or 15;
      DefaultP_Slider = tonumber(r.GetExtState('MK_Slicer_3','DefaultP_Slider'))or 5;
      DefaultQStrength = tonumber(r.GetExtState('MK_Slicer_3','DefaultQStrength'))or 100;
      DefaultHP = tonumber(r.GetExtState('MK_Slicer_3','DefaultHP'))or 0.3312;
      DefaultLP = tonumber(r.GetExtState('MK_Slicer_3','DefaultLP'))or 1;
      DefaultSens = tonumber(r.GetExtState('MK_Slicer_3','DefaultSens'))or 0.63;
      DefaultOffset = tonumber(r.GetExtState('MK_Slicer_3','DefaultOffset'))or 0.5;
  --sheckboxes--
     DefMIDI_Mode =  1;
     DefSampler_preset_state =  1;
     DefCreate_Replace_state =  1
     DefCreate_Replace_state2 =  1
     DefPitch_Det_Options_state =  1;
     DefPitch_Det_Options_state2 =  1;
     DefGuides_mode =  1;
     DefOutNote_State =  1;
     DefGate_VeloScale =  1;
     DefGate_VeloScale2 =  1;
     DefXFadeOff = 0

  --sliders--
      r.SetExtState('MK_Slicer_3','CrossfadeTime',DefaultXFadeTime,true);
      r.SetExtState('MK_Slicer_3','PitchDetect',DefaultP_Slider,true);
      r.SetExtState('MK_Slicer_3','QuantizeStrength',DefaultQStrength,true);
      r.SetExtState('MK_Slicer_3','Offs_Slider',DefaultOffset,true);
      r.SetExtState('MK_Slicer_3','HF_Slider',DefaultHP,true);
      r.SetExtState('MK_Slicer_3','LF_Slider',DefaultLP,true);
      r.SetExtState('MK_Slicer_3','Sens_Slider',DefaultSens,true);
  --sheckboxes--
      r.SetExtState('MK_Slicer_3','Guides.norm_val',DefGuides_mode,true);
      if Notes_On == 1 then OutNote.norm_val = OutNote2.norm_val end
      r.SetExtState('MK_Slicer_3','OutNote.norm_val',DefOutNote_State,true);
      r.SetExtState('MK_Slicer_3','Midi_Sampler.norm_val',DefMIDI_Mode,true);
      r.SetExtState('MK_Slicer_3','Sampler_preset.norm_val',DefSampler_preset_state,true);
      r.SetExtState('MK_Slicer_3','Create_Replace.norm_val',DefCreate_Replace_state,true);
      r.SetExtState('MK_Slicer_3','Create_Replace.norm_val',DefCreate_Replace_state2,true);
      r.SetExtState('MK_Slicer_3','Pitch_Det_Options.norm_val',DefPitch_Det_Options_state,true);
      r.SetExtState('MK_Slicer_3','Pitch_Det_Options2.norm_val',DefPitch_Det_Options_state2,true);
      r.SetExtState('MK_Slicer_3','XFadeOff',DefXFadeOff,true);
      r.SetExtState('MK_Slicer_3','Gate_VeloScale.norm_val',DefGate_VeloScale,true);
      r.SetExtState('MK_Slicer_3','Gate_VeloScale.norm_val2',DefGate_VeloScale2,true);

end

--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
item22 = context_menu:add_item({label = ">Select Theme (Script will close. Re-open required)"})
item22.command = function()
end


if ThemeSel == 1 then
item23 = context_menu:add_item({label = "Prime", toggleable = true, selected = true})
else
item23 = context_menu:add_item({label = "Prime", toggleable = true, selected = false})
end
item23.command = function()
                   ThemeSel = 1
                   r.SetExtState('MK_Slicer_3','ThemeSel',ThemeSel,true);
                   gfx.quit()
end


if ThemeSel == 2 then
item24 = context_menu:add_item({label = "Neon", toggleable = true, selected = true})
else
item24 = context_menu:add_item({label = "Neon", toggleable = true, selected = false})
end
item24.command = function()
                   ThemeSel = 2
                   r.SetExtState('MK_Slicer_3','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 3 then
item25 = context_menu:add_item({label = "Black", toggleable = true, selected = true})
else
item25 = context_menu:add_item({label = "Black", toggleable = true, selected = false})
end
item25.command = function()
                   ThemeSel = 3
                   r.SetExtState('MK_Slicer_3','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 4 then
item24 = context_menu:add_item({label = "Blue Lake", toggleable = true, selected = true})
else
item24 = context_menu:add_item({label = "Blue Lake", toggleable = true, selected = false})
end
item24.command = function()
                   ThemeSel = 4
                   r.SetExtState('MK_Slicer_3','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 5 then
item27 = context_menu:add_item({label = "Fall", toggleable = true, selected = true})
else
item27 = context_menu:add_item({label = "Fall", toggleable = true, selected = false})
end
item27.command = function()
                   ThemeSel = 5
                   r.SetExtState('MK_Slicer_3','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 6 then
item28 = context_menu:add_item({label = "Soft Dark", toggleable = true, selected = true})
else
item28 = context_menu:add_item({label = "Soft Dark", toggleable = true, selected = false})
end
item28.command = function()
                   ThemeSel = 6
                   r.SetExtState('MK_Slicer_3','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 7 then
item29 = context_menu:add_item({label = "Graphite", toggleable = true, selected = true})
else
item29 = context_menu:add_item({label = "Graphite", toggleable = true, selected = false})
end
item29.command = function()
                   ThemeSel = 7
                   r.SetExtState('MK_Slicer_3','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 8 then
item30 = context_menu:add_item({label = "Clean", toggleable = true, selected = true})
else
item30 = context_menu:add_item({label = "Clean", toggleable = true, selected = false})
end
item30.command = function()
                   ThemeSel = 8
                   r.SetExtState('MK_Slicer_3','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 9 then
item31 = context_menu:add_item({label = "Ink", toggleable = true, selected = true})
else
item31 = context_menu:add_item({label = "Ink", toggleable = true, selected = false})
end
item31.command = function()
                   ThemeSel = 9
                   r.SetExtState('MK_Slicer_3','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 10 then
item32 = context_menu:add_item({label = "Classic|<", toggleable = true, selected = true})
else
item32 = context_menu:add_item({label = "Classic|<", toggleable = true, selected = false})
end
item32.command = function()
                   ThemeSel = 10
                   r.SetExtState('MK_Slicer_3','ThemeSel',ThemeSel,true);
                   gfx.quit()
end


item34 = context_menu:add_item({label = "|Reset Window Size", toggleable = false})
item34.command = function()
store_window()
           xpos = tonumber(r.GetExtState("MK_Slicer_3", "window_x")) or 400
           ypos = tonumber(r.GetExtState("MK_Slicer_3", "window_y")) or 320
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
DefaultXFadeTime = tonumber(r.GetExtState('MK_Slicer_3','DefaultXFadeTime'))or 15;
DefaultP_Slider = tonumber(r.GetExtState('MK_Slicer_3','DefaultP_Slider'))or 5;
DefaultQStrength = tonumber(r.GetExtState('MK_Slicer_3','DefaultQStrength'))or 100;
DefaultHP = tonumber(r.GetExtState('MK_Slicer_3','DefaultHP'))or 0.3312;
DefaultLP = tonumber(r.GetExtState('MK_Slicer_3','DefaultLP'))or 1;
DefaultSens = tonumber(r.GetExtState('MK_Slicer_3','DefaultSens'))or 0.63;
DefaultOffset = tonumber(r.GetExtState('MK_Slicer_3','DefaultOffset'))or 0.5;
MIDI_Base_Oct = tonumber(r.GetExtState('MK_Slicer_3','MIDI_Base_Oct'))or 2;
Trigger_Oct_Shift  = tonumber(r.GetExtState('MK_Slicer_3','Trigger_Oct_Shift'))or 0;

function toHertz(val) --  val to hz
  local sxx = 16+(val*100)*1.20103
  return floor(exp(sxx*logx(1.059))*8.17742) 
end;

  DefaultLP = toHertz(DefaultLP)
  DefaultHP = toHertz(DefaultHP)

  DefaultSens = ((DefaultSens+0.125)*9)-0.125
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

local retval, value = r.GetUserInputs("User Defaults", 8, "Crossfade Time (0 - 50) ms ,Quantize Strength (0 - 100) % ,LowCut Slider (20 - 20000) Hz ,High Cut Slider (20 - 20000) Hz ,Sensitivity (1 - 10) ,Offset Slider (-100 - +100) ,Sampler Base Octave (0 - 9) ,Trigger Octave Shift (-2 - 7) ", values)
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
if DefaultSens2 < 1 then DefaultSens2 = 1 elseif DefaultSens2 > 10 then DefaultSens2 = 10 end
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
DefaultSens2 = ((DefaultSens2+0.125)/9)-0.125
DefaultOffset2 = ((DefaultOffset2/100)+1)/2

          r.SetExtState('MK_Slicer_3','DefaultXFadeTime',DefaultXFadeTime2,true);
          r.SetExtState('MK_Slicer_3','DefaultQStrength',DefaultQStrength2,true);
          r.SetExtState('MK_Slicer_3','DefaultLP',DefaultLP2,true);
          r.SetExtState('MK_Slicer_3','DefaultHP',DefaultHP2,true);
          r.SetExtState('MK_Slicer_3','DefaultSens',DefaultSens2,true);
          r.SetExtState('MK_Slicer_3','DefaultOffset',DefaultOffset2,true);
          r.SetExtState('MK_Slicer_3','MIDI_Base_Oct',MIDI_Base_Oct2,true);
          r.SetExtState('MK_Slicer_3','Trigger_Oct_Shift',Trigger_Oct_Shift2,true);

end
end
-----------------------end of User Defaults form--------------------------------

function ClearExState()

transportstate = r.GetToggleCommandStateEx(0, 41834) -- get Option: "Toggle stop playback at end of loop if repeat is disabled"
if transportstate_init ~= transportstate then
   r.Main_OnCommand(41834,0) -- Re-enable "Toggle stop playback at end of loop if repeat is disabled" (if it was enabled)
end


repeatstate = r.GetToggleCommandStateEx(0, 1068) -- get Option: ""Transport: Toggle repeat"
if repeatstate_init ~= repeatstate then
   r.Main_OnCommand(1068, 0) -- Re-enable "Transport: Toggle repeat" (if it was enabled on init)
end

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

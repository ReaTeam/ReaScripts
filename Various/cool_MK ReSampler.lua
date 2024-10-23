-- @description MK ReSampler
-- @author cool
-- @version 0.9.1
-- @changelog
--   + Added Fine slider for fine-tuning the frequency in cents.
--   + Added Reverse function: play files backwards.
--   + The waveform now displays Reverse if the function is active.
--   + Now the script can receive MIDI from any channel, not just the first.
--   + Fixed a bug: now play cursor correctly changes position if the zoom of the waveform is changed.
--   + Fixed a bug: now the script does not give an error when working with Reversed items (but also does not work with them).
--   + Fixed a bug: now the script does not crash with an error if the recording was activated from daw, but was stopped by the script button.
--   + Fixed a bug: now the script does not crash with an error when pressing the keyboard arrows.
--   + Now zoom, when you press the keyboard arrows, focuses approximately around the area of the start and end markers.
--   + Added a condition for correct work with Muted items.
--   + Improved display of the initial screen when launching on long items.
--   + Now clicking on a sample in the Media Explorer resets the selection of items, shifting the focus of the script to the Media Explorer.
--   + All menus that have only two items have been replaced with switch buttons with indication.
--   + Increased the maximum deviation of Random Pitch to +-50 cents.
--   + Changed the position of some controls.
--   + Fixed typo: RealmGUI -> ReaimGUI.
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=287293
-- @screenshot Main View and VMK https://i.ibb.co/gRr8RvF/MK-Re-Sampler.jpg
-- @donation Donate via BuyMeACoffee https://www.buymeacoffee.com/MaximKokarev
-- @about
--   MK ReSampler
--   A simple tool for quick pre-listening, sampling and sound design.
--
--   To work, you need js_ReaScriptAPI from ReaPak and the latest version of SWS from this page: https://www.sws-extension.org/download/pre-release/
--   Important: this is not a plugin. The script does not have audio/MIDI inputs and outputs, does not process sound, does not store samples in its memory and is not saved in projects. It only manages existing Reaper functions and third party APIs.
--
--   Highlights:
--   -Instant playback of a selected item or file from Media Explorer.
--   -Several pitch and playback speed algorithms: from non-destructive stretching to changing the sound beyond recognition.
--   -Automatic pitch adjustment to always stay in tune.
--   -No settings for inputs and outputs: the script accepts MIDI data from any sources, including Virtual MIDI Keyboard.
--   -Sound playback occurs through any selected track.
--   -Possibility of recording.
--
--   How it works?
--   Just select any Item in the project or File in the Media Explorer and play it using a MIDI keyboard or VMK.

--[[
MK ReSampler v0.9.1 by Maxim Kokarev 
https://forum.cockos.com/member.php?u=121750

Based on CF_Preview_Play API by cfillion
https://forum.cockos.com/member.php?u=98780

Based on "Drums to MIDI(beta version)" script by eugen2777
http://forum.cockos.com/member.php?u=50462  

Razor Edit functions by BirdBird, Juliansander and Embass:
https://forum.cockos.com/showthread.php?t=241604

"Display Path of selected files in Media Explorer" code by Edgemeal:
https://forums.cockos.com/showpost.php?p=2748255&postcount=12
]]

----------------------------Advanced User Settings--(Modify with care!)----------------------------------

RememberLast = 1  -- (Remember some sliders positions from last session. 1 - On, 0 - Off)
WFiltering = 0 -- (Waveform Visual Filtering while Window Scaling. 1 - On, 0 - Off)
ShowTrackAndItemInfo = 1 -- (Show processed item and related track number. 1 - On, 0 - Off)

MinSelLength = 0.005 -- Minimal Item Length


--------------------------------Themes----------------------------------------------
local TH = {}
function Theming(Theme)

      if Theme == nil then Theme = 1 end 
      if Theme < 0 then Theme = 1 elseif Theme >= 12 then Theme = 12 end 

---------------TH[described element] = {red, green, blue, alpha}----------------

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
      ThickBFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      Tint_d = 1   -- Active Button Tint Coloring Mode: 1 - darker than Green tops elements, 0 - lighter than Green tops elements (best for light themes).
      Tint_a = 0.1 -- Active Button Tint Transparency
      
      TH[29] = {0.23, 0.25, 0.25,0} -- Slider Frames
      TH[30] = {0.23, 0.25, 0.25,1} -- Slider Body
      ThickFrames = 0 -- Thickness - 0 = normal, 1 - thick frames
      
      TH[31] = {0.32, 0.34, 0.34, 1} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.32, 0.34, 0.34, 1} -- Slider Body (Top, Loop and Swing)
      ThickSwFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      TH[45] = { 0.23, 0.25, 0.25, 0.4 } -- Slider Background

      TH[46] = { 0.205, 0.225, 0.225, 1 } -- CheckBox Body
      TH[47] = 0.05 -- CheckBox Tint Transparency
      
      --------------Text--------------------
      TH[33] = { 0.61, 0.61, 0.61, 1 } -- Text Main
      TH[34] = { 1, 0.5, 0.3, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.45, 0.45, 0.45, 1 } -- Txt Greyed (BPM)
      TH[36] = { 0.6, 0.6, 0.6, 1 } -- Txt Greyed (Presets, Mode)      
      TH[37] = -0.1 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.9 -- BPM digits transparency
      TH[48] = {0.23, 0.25, 0.25,0.25} -- BPM Background
      TH[49] = {1, 1, 1, 0.03} -- Status Bar Background

      -----------Elements------------------
      TH[39] =  { 0.8, 0.2, 0.1, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.60, 0.60, 0.60, 0.4 } -- Txt Brackets
      TH[41] = { 0.60, 0.60, 0.60, 0.4 } -- Main Separators
      TH[42] = 0.8 -- Leds Transparency (Controls Body)
      TH[43] = 0.1 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      TH[44] = { 0.1, 0.8, 0.4, 0.75 } -- Random+Q Bracket Color
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
      ThickBFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      Tint_d = 1   -- Active Button Tint Coloring Mode: 1 - darker than Green tops elements, 0 - lighter than Green tops elements (best for light themes).
      Tint_a = 0.12 -- Active Button Tint Transparency
      
      TH[29] = {0.28235, 0.32941, 0.34118,0} -- Slider Frames
      TH[30] = {0.28235, 0.32941, 0.34118,1} -- Slider Body
      ThickFrames = 0 -- Thickness - 0 = normal, 1 - thick frames
      
      TH[31] = {0.33235, 0.37941, 0.39118,0} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.33235, 0.37941, 0.39118,1} -- Slider Body (Top, Loop and Swing)
      ThickSwFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      TH[45] = { 0.28235, 0.32941, 0.34118, 0.3 } -- Slider Background

      TH[46] = { 0.31235, 0.33941, 0.35118, 1 } -- CheckBox Body
      TH[47] = 0.05 -- CheckBox Tint Transparency      

      --------------Text--------------------     
      TH[33] = { 0.7, 0.7, 0.7, 1 } -- Text Main
      TH[34] = { 1, 0.5, 0.3, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.4, 0.4, 0.4, 0.5 } -- Txt Greyed (BPM)
      TH[36] = { 0.5, 0.5, 0.5, 0.5 } -- Txt Greyed (Presets, Mode)
      TH[37] = 0 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.9 -- BPM digits transparency
      TH[48] = {0.23, 0.25, 0.25,0} -- BPM Background
      TH[49] = {0, 0, 0, 0.05} -- Status Bar Background
    
      -----------Elements------------------
      TH[39] =  { 0.8, 0.2, 0.1, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.4, 0.4, 0.4, 0.5 } -- Txt Brackets
      TH[41] = { 0.4, 0.4, 0.4, 0.3 } -- Main Separators
      TH[42] = 0.9 -- Leds Transparency (Controls Body)
      TH[43] = 0.15 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      TH[44] = { 0.906, 0.463, 0.0, 0.9 } -- Random+Q Bracket Color
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
      ThickBFrames = 1 -- Thickness - 0 = normal, 1 - thick frames

      Tint_d = 1   -- Active Button Tint Coloring Mode: 1 - darker than Green tops elements, 0 - lighter than Green tops elements (best for light themes).
      Tint_a = 0.14 -- Active Button Tint Transparency
      
      TH[29] = {0.24, 0.25, 0.25,1} -- Slider Frames
      TH[30] = {0.24, 0.25, 0.25,1} -- Slider Body
      ThickFrames = 1 -- Thickness - 0 = normal, 1 - thick frames
      
      TH[31] = {0.32, 0.33, 0.33, 1} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.32, 0.33, 0.33, 1} -- Slider Body (Top, Loop and Swing)
      ThickSwFrames = 1 -- Thickness - 0 = normal, 1 - thick frames

      TH[45] = { 0.24, 0.25, 0.25, 0.15 } -- Slider Background

      TH[46] = { 0.26, 0.28, 0.28, 1 } -- CheckBox Body
      TH[47] = 0.05 -- CheckBox Tint Transparency
      
      --------------Text--------------------
      TH[33] = { 0.9, 0.9, 0.9, 0.7 } -- Text Main
      TH[34] = { 1, 0.5, 0.3, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.45, 0.45, 0.45, 1 } -- Txt Greyed (BPM)
      TH[36] = { 0.55, 0.55, 0.55, 1 } -- Txt Greyed (Presets, Mode)      
      TH[37] = -0.1 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.9 -- BPM digits transparency
      TH[48] = {0, 0, 0,0.05} -- BPM Background
      TH[49] = {0, 0, 0, 0.05} -- Status Bar Background

      -----------Elements------------------
      TH[39] =  { 0.8, 0.2, 0.1, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.22, 0.23, 0.23, 0.7 } -- Txt Brackets
      TH[41] = { 0.22, 0.23, 0.23, 0.7 } -- Main Separators
      TH[42] = 0.9 -- Leds Transparency (Controls Body)
      TH[43] = 0 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      TH[44] = { 0.60, 0.60, 0.60, 0.6 } -- Random+Q Bracket Color
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
      ThickBFrames = 1 -- Thickness - 0 = normal, 1 - thick frames

      Tint_d = 1   -- Active Button Tint Coloring Mode: 1 - darker than Green tops elements, 0 - lighter than Green tops elements (best for light themes).
      Tint_a = 0.1 -- Active Button Tint Transparency
      
      TH[29] = {0.224, 0.29, 0.329,1} -- Slider Frames
      TH[30] = {0.224, 0.29, 0.329,1} -- Slider Body
      ThickFrames = 1 -- Thickness - 0 = normal, 1 - thick frames
      
      TH[31] = {0.204, 0.27, 0.329, 1} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.204, 0.27, 0.329, 1} -- Slider Body (Top, Loop and Swing)
      ThickSwFrames = 1 -- Thickness - 0 = normal, 1 - thick frames

      TH[45] = { 0.165, 0.165, 0.165, 0.3 } -- Slider Background

      TH[46] = { 0.229, 0.305, 0.335, 1 } -- CheckBox Body
      TH[47] = 0.05 -- CheckBox Tint Transparency
      
      --------------Text--------------------      
      TH[33] = { 0.65, 0.65, 0.65, 1 } -- Text Main
      TH[34] = { 0.894, 0.737, 0.235, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.45, 0.45, 0.45, 1 } -- Txt Greyed (BPM)
      TH[36] = { 0.45, 0.45, 0.45, 1 } -- Txt Greyed (Presets, Mode)
      TH[37] = 0 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.9 -- BPM digits transparency
      TH[48] = {0, 0.1, 0.1,0.15} -- BPM Background
      TH[49] = {0, 0, 0, 0} -- Status Bar Background
     
      -----------Elements------------------
      TH[39] =  { 0.8, 0.2, 0.1, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.45, 0.45, 0.45, 0.5 } -- Txt Brackets
      TH[41] = { 0.45, 0.45, 0.45, 0.5 } -- Main Separators
      TH[42] = 0.9 -- Leds Transparency (Controls Body)
      TH[43] = 0.1 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      TH[44] = { 0.906, 0.463, 0.0, 0.9 } -- Random+Q Bracket Color
      --------------------------------------------------------------

      elseif Theme == 5 then 
      -------------------------Fall (Dark)------------------------------
      theme_name = "Fall (Dark)"
      -------Backgrounds and Frames-----------------
      TH[1] = {0.063, 0.063, 0.067,1} -- Waveform, Background Box
      TH[2] = {0.063, 0.063, 0.067,1} -- Waveform, Frame
      TH[3] = {0.171, 0.171, 0.171} -- Main Background
      TH[4] = { 0.241, 0.241, 0.241, 1 } -- Controls Body
      TH[5] = { 0.778, 0.778, 0.778, 0 } -- Controls Frame

      -----------Waveforms---------------
      TH[6] = {0.945, 0.565, 0.0,1} -- Waveform, Filtered 
      TH[7] = {0.1, 0.1, 0.1,1} -- Waveform, Original 
      TH[8] = { 0.294, 0.239, 0.192 ,1 } -- Waveform, Draw original Only

      --------Waveform Lines--------------
      TH[9] = { 0.7, 0.7, 0.8, 1 } -- Ruler
      TH[10] = 0 -- Ruler Gradient Width (0 = off)
      TH[11] = 0.05 --Ruler Gradient Transparency

      TH[12] = { 0.11, 0.78, 0.863, 0.4 } -- Threshold Lines
      TH[13] = { 0.11, 0.78, 0.863, 0.9 } -- Transient Markers
      TH[14] = 5 -- Transient Markers Gradient Width (if Selected)
      TH[15] = 0.3 --Transient Markers Gradient Transparency (if Selected)
      TH[16] = 0 -- Transient Markers Gradient Width (0 - off)
      TH[17] = 0 --Transient Markers Gradient Transparency

      TH[18] = { 0.11, 0.78, 0.863, 0.12 } -- Sample Area if enabled

      TH[19] = { 0.278, 0.604, 0.435, 1 } -- Grid Markers
      
      TH[20] = { 1.0, 0.9, 0.9, 1 } -- Edit Cursor
      TH[21] = 5 -- Edit Cursor Gradient Width
      TH[22] = 0.2 --Edit Cursor Gradient Transparency

      TH[23] = { 0.7, 0.7, 0.7, 1 } -- Play Cursor
      TH[24] = 5 -- Play Cursor Gradient Width
      TH[25] = 0.2 --Play Cursor Gradient Transparency

      TH[26] = { 0.9, 0.9, 1, 0.5 } -- Aim Assist Cursor
      
      -------Buttons and Sliders ---------      
      TH[27] = {0.11, 0.11, 0.11 ,1} -- Button Body
      TH[28] = {0.11, 0.11, 0.11 ,1} -- Button Frames
      ThickBFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      Tint_d = 1   -- Active Button Tint Coloring Mode: 1 - darker than Green tops elements, 0 - lighter than Green tops elements (best for light themes).
      Tint_a = 0.1 -- Active Button Tint Transparency
      
      TH[29] = {0.078, 0.078, 0.078,1} -- Slider Frames
      TH[30] = {0.1, 0.424, 0.455,1} -- Slider Body
      ThickFrames = 1 -- Thickness - 0 = normal, 1 - thick frames
      
      TH[31] = {0.1, 0.424, 0.455,1} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.1, 0.424, 0.455,1} -- Slider Body (Top, Loop and Swing)
      ThickSwFrames = 1 -- Thickness - 0 = normal, 1 - thick frames
      
      TH[45] = { 0.165, 0.165, 0.165, 1 } -- Slider Background

      TH[46] = { 0.1, 0.424, 0.455,1 } -- CheckBox Body
      TH[47] = 0 -- CheckBox Tint Transparency

      --------------Text--------------------      
      TH[33] = { 0.85, 0.85, 0.85, 1 } -- Text Main
      TH[34] = { 0.906, 0.524, 0.229, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.4, 0.4, 0.4, 0.7 } -- Txt Greyed (BPM)
      TH[36] = { 0.8, 0.8, 0.8, 0.5 } -- Txt Greyed (Presets, Mode)
      TH[37] = 0 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.9 -- BPM digits transparency
      TH[48] = {0, 0, 0,0.2} -- BPM Background
      TH[49] = {1, 1, 1, 0.05} -- Status Bar Background

      -----------Elements------------------      
      TH[39] =  { 0.8, 0.2, 0.1, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.778, 0.778, 0.778, 0.3 } -- Txt Brackets
      TH[41] = { 0.078, 0.078, 0.078, 0.4 } -- Main Separators
      TH[42] = 0.7 -- Leds Transparency (Controls Body)
      TH[43] = 0 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      TH[44] = { 0.778, 0.778, 0.778, 0.5 } -- Random+Q Bracket Color
      --------------------------------------------------------------

      elseif Theme == 6 then 
      -------------------------Fall------------------------------
      theme_name = "Fall"
      -------Backgrounds and Frames-----------------
      TH[1] = {0.16, 0.16, 0.16,1} -- Waveform, Background Box
      TH[2] = {0.16, 0.16, 0.16,1} -- Waveform, Frame
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
      ThickBFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      Tint_d = 1   -- Active Button Tint Coloring Mode: 1 - darker than Green tops elements, 0 - lighter than Green tops elements (best for light themes).
      Tint_a = 0.15 -- Active Button Tint Transparency
      
      TH[29] = {0.28235, 0.32941, 0.34118,1} -- Slider Frames
      TH[30] = {0.859, 0.494, 0.161,1} -- Slider Body
      ThickFrames = 0 -- Thickness - 0 = normal, 1 - thick frames
      
      TH[31] = {0.32, 0.32, 0.32,1} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.32, 0.32, 0.32,1} -- Slider Body (Top, Loop and Swing)
      ThickSwFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      TH[45] = { 0.165, 0.165, 0.165, 0.07 } -- Slider Background

      TH[46] = { 0.879, 0.454, 0.141, 1 } -- CheckBox Body
      TH[47] = 0 -- CheckBox Tint Transparency
      
      --------------Text--------------------      
      TH[33] = { 0.078, 0.078, 0.078, 1 } -- Text Main
      TH[34] = { 0.906, 0.524, 0.229, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.4, 0.4, 0.4, 0.7 } -- Txt Greyed (BPM)
      TH[36] = { 0.2, 0.2, 0.2, 0.85 } -- Txt Greyed (Presets, Mode)
      TH[37] = -0.32 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.8 -- BPM digits transparency
      TH[48] = {1, 1, 1,0.1} -- BPM Background
      TH[49] = {1, 1, 1, 0.05} -- Status Bar Background

      -----------Elements------------------      
      TH[39] =  { 0.8, 0.2, 0.1, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.3, 0.3, 0.3, 1 } -- Txt Brackets
      TH[41] = { 0.3, 0.3, 0.3, 1 } -- Main Separators
      TH[42] = 0.9 -- Leds Transparency (Controls Body)
      TH[43] = 0 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      TH[44] = { 0.20, 0.20, 0.20, 1 } -- Random+Q Bracket Color
      --------------------------------------------------------------


      elseif Theme == 7 then 
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
      ThickBFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      Tint_d = 1   -- Active Button Tint Coloring Mode: 1 - darker than Green tops elements, 0 - lighter than Green tops elements (best for light themes).
      Tint_a = 0.15 -- Active Button Tint Transparency
      
      TH[29] = {0.22, 0.22, 0.22,1} -- Slider Frames
      TH[30] = {0.22, 0.22, 0.22,1} -- Slider Body
      ThickFrames = 0 -- Thickness - 0 = normal, 1 - thick frames
      
      TH[31] = {0.32, 0.34, 0.34, 1} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.32, 0.34, 0.34, 1} -- Slider Body (Top, Loop and Swing)
      ThickSwFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      TH[45] = { 0.165, 0.165, 0.165, 0 } -- Slider Background

      TH[46] = { 0.21, 0.21, 0.21, 1 } -- CheckBox Body
      TH[47] = 0.05 -- CheckBox Tint Transparency
      
      --------------Text--------------------
      TH[33] = { 0.55, 0.55, 0.55, 1 } -- Text Main
      TH[34] = { 0.551, 0.696, 1, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.45, 0.45, 0.45, 1 } -- Txt Greyed (BPM)
      TH[36] = { 0.45, 0.45, 0.45, 1 } -- Txt Greyed (Presets, Mode)
      TH[37] = -0.1 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.7 -- BPM digits transparency
      TH[48] = {0.23, 0.25, 0.25,0.25} -- BPM Background
      TH[49] = {1, 1, 1, 0.02} -- Status Bar Background

      -----------Elements------------------
      TH[39] =  { 0.8, 0.2, 0.1, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.9, 0.9, 0.9, 0.12 } -- Txt Brackets
      TH[41] = { 0.2, 0.2, 0.2, 0.7 } -- Main Separators
      TH[42] = 0.7 -- Leds Transparency (Controls Body)
      TH[43] = 0 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      TH[44] = { 0.551, 0.696, 1, 0.6 } -- Random+Q Bracket Color
      --------------------------------------------------------------


elseif Theme == 8 then 
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
      ThickBFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      Tint_d = 0   -- Active Button Tint Coloring Mode: 1 - darker than Green tops elements, 0 - lighter than Green tops elements (best for light themes).
      Tint_a = 0.1 -- Active Button Tint Transparency
      
      TH[29] = {0.48, 0.49, 0.5, 0.7} -- Slider Frames
      TH[30] = {0.50, 0.52, 0.53,1} -- Slider Body
      ThickFrames = 0 -- Thickness - 0 = normal, 1 - thick frames
      
      TH[31] = {0.48, 0.49, 0.5, 0.7} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.45, 0.47, 0.48,1} -- Slider Body (Top, Loop and Swing)
      ThickSwFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      TH[45] = { 0.50, 0.52, 0.53, 0.15 } -- Slider Background

      TH[46] = { 0.60, 0.62, 0.63, 1 } -- CheckBox Body
      TH[47] = 0.1 -- CheckBox Tint Transparency
      
      --------------Text--------------------      
      TH[33] = { 0.16, 0.16, 0.19, 1 } -- Text Main
      TH[34] = { 0.3, 0.2, 0.3, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.45, 0.45, 0.45, 1 } -- Txt Greyed (BPM)
      TH[36] = { 0.45, 0.45, 0.45, 1 } -- Txt Greyed (Presets, Mode)
      TH[37] = -0.3 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.8 -- BPM digits transparency
      TH[48] = {1, 1, 1,0} -- BPM Background
      TH[49] = {1, 1, 1, 0} -- Status Bar Background
     
      -----------Elements------------------
      TH[39] =  { 0.8, 0.2, 0.1, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.15, 0.15, 0.15 ,0.7 } -- Txt Brackets
      TH[41] = { 0.15, 0.15, 0.15 ,0.7 } -- Main Separators
      TH[42] = 0.7 -- Leds Transparency (Controls Body)
      TH[43] = 1 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      TH[44] = { 0.20, 0.20, 0.20, 1 } -- Random+Q Bracket Color
      --------------------------------------------------------------

      elseif Theme == 9 then 
     ------------------------------Spring---------------------------
      theme_name = "Spring"
      -------Backgrounds and Frames-----------------
      TH[1] = {0.812, 0.816, 0.804,1} -- Waveform, Background Box
      TH[2] = {0.812, 0.816, 0.804,1} -- Waveform, Frame
      TH[3] = { 0.827, 0.831, 0.82} -- Main Background
      TH[4] = { 0.843, 0.851, 0.847, 1 } -- Controls Body
      TH[5] = { 0.843, 0.851, 0.847, 0 } -- Controls Frame

      -----------Waveforms---------------
      TH[6] = {0.847, 0.451, 0.349,1} -- Waveform, Filtered 
      TH[7] = {0.747, 0.767, 0.775,1} -- Waveform, Original 
      TH[8] = { 0.847, 0.867, 0.875 ,1 } -- Waveform, Draw original Only

      --------Waveform Lines--------------
      TH[9] = { 0.094, 0.09, 0.082, 1 } -- Ruler
      TH[10] = 0 -- Ruler Gradient Width (0 = off)
      TH[11] = 0.12 --Ruler Gradient Transparency

      TH[12] = { 0.161, 0.478, 0.922, 0.3 } -- Threshold Lines
      TH[13] = { 0.161, 0.478, 0.922, 0.9 } -- Transient Markers
      TH[14] = 7 -- Transient Markers Gradient Width (if Selected)
      TH[15] = 0.15 --Transient Markers Gradient Transparency (if Selected)
      TH[16] = 0 -- Transient Markers Gradient Width (0 - off)
      TH[17] = 0.1 --Transient Markers Gradient Transparency

      TH[18] = { 0.161, 0.478, 0.922, 0.12 } -- Sample Area if enabled

      TH[19] = { 0.0, 0.5, 0.2, 0.5 } -- Grid Markers
      
      TH[20] = { 0.28, 0.114, 0.284, 1 } -- Edit Cursor
      TH[21] = 5 -- Edit Cursor Gradient Width
      TH[22] = 0.1 --Edit Cursor Gradient Transparency

      TH[23] = { 0.141, 0.68, 0.69, 1 } -- Play Cursor
      TH[24] = 5 -- Play Cursor Gradient Width
      TH[25] = 0.1 --Play Cursor Gradient Transparency

      TH[26] = { 0.0, 0.5, 0.2, 0.5 } -- Aim Assist Cursor
      
      -------Buttons and Sliders ---------
      TH[27] = {0.706, 0.706, 0.702 ,1} -- Button Body
      TH[28] = {0.706, 0.706, 0.702 ,1} -- Button Frames
      ThickBFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      Tint_d = 0   -- Active Button Tint Coloring Mode: 1 - darker than Green tops elements, 0 - lighter than Green tops elements (best for light themes).
      Tint_a = 0.1 -- Active Button Tint Transparency
      
      TH[29] = {0.765, 0.765, 0.765,1} -- Slider Frames
      TH[30] = {0.765, 0.765, 0.765,1} -- Slider Body
      ThickFrames = 0 -- Thickness - 0 = normal, 1 - thick frames
      
      TH[31] = {0.706, 0.706, 0.702,1} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.706, 0.706, 0.702,1} -- Slider Body (Top, Loop and Swing)
      ThickSwFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      TH[45] = { 0.165, 0.165, 0.165, 0 } -- Slider Background

      TH[46] = { 0.735, 0.735, 0.735, 1 } -- CheckBox Body
      TH[47] = 0.1 -- CheckBox Tint Transparency
      
      --------------Text--------------------     
      TH[33] = { 0.298, 0.29, 0.282, 1 } -- Text Main
      TH[34] = { 0.8, 0.3, 0.1, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.4, 0.4, 0.4, 0.5 } -- Txt Greyed (BPM)
      TH[36] = { 0.298, 0.29, 0.282, 0.5 } -- Txt Greyed (Presets, Mode)
      TH[37] = -0.5 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.9 -- BPM digits transparency
      TH[48] = {1, 1, 1,0.1} -- BPM Background
      TH[49] = {1, 1, 1, 0.05} -- Status Bar Background
    
      -----------Elements------------------
      TH[39] =  { 0.8, 0.2, 0.1, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.298, 0.29, 0.282, 0.4 } -- Txt Brackets
      TH[41] = { 0.718, 0.714, 0.694, 1 } -- Main Separators
      TH[42] = 1 -- Leds Transparency (Controls Body)
      TH[43] = 0 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      TH[44] = { 0.906, 0.463, 0.0, 0.9 } -- Random+Q Bracket Color
      --------------------------------------------------------------

elseif Theme == 10 then 
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
      TH[28] = {0.337, 0.643, 0.792 ,0.75} -- Button Frames
      ThickBFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      Tint_d = 0   -- Active Button Tint Coloring Mode: 1 - darker than Green tops elements, 0 - lighter than Green tops elements (best for light themes).
      Tint_a = 0.4 -- Active Button Tint Transparency
      
      TH[29] = {0.953, 0.533, 0.267,0} -- Slider Frames
      TH[30] = {0.953, 0.533, 0.267,0.8} -- Slider Body
      ThickFrames = 0 -- Thickness - 0 = normal, 1 - thick frames
      
      TH[31] = {0.923, 0.503, 0.237, 0} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.923, 0.503, 0.237, 0.8} -- Slider Body (Top, Loop and Swing)
      ThickSwFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      TH[45] = { 0.953, 0.533, 0.267, 0.2 } -- Slider Background

      TH[46] = { 0.923, 0.503, 0.237, 0.9 } -- CheckBox Body
      TH[47] = 0 -- CheckBox Tint Transparency
      
      --------------Text--------------------      
      TH[33] = { 0.2, 0.2, 0.2, 1 } -- Text Main
      TH[34] = { 0.922, 0.502, 0.235, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.45, 0.45, 0.45, 0.6 } -- Txt Greyed (BPM)
      TH[36] = { 0.40, 0.40, 0.40, 0.6 } -- Txt Greyed (Presets, Mode)
      TH[37] = -0.2 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.7 -- BPM digits transparency
      TH[48] = {1, 1, 1,0.1} -- BPM Background
      TH[49] = {1, 1, 1, 0.05} -- Status Bar Background
     
      -----------Elements------------------
      TH[39] =  { 0.8, 0.2, 0.1, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.2, 0.2, 0.2, 0.2 } -- Txt Brackets
      TH[41] = { 0.2, 0.2, 0.2, 0.2 } -- Main Separators
      TH[42] = 0.7 -- Leds Transparency (Controls Body)
      TH[43] = 0 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      TH[44] = { 0.20, 0.20, 0.20, 1 } -- Random+Q Bracket Color
      --------------------------------------------------------------

elseif Theme == 11 then 
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
      ThickBFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      Tint_d = 0   -- Active Button Tint Coloring Mode: 1 - darker than Green tops elements, 0 - lighter than Green tops elements (best for light themes).
      Tint_a = 0.15 -- Active Button Tint Transparency
      
      TH[29] = {0.565, 0.565, 0.565,1} -- Slider Frames
      TH[30] = {0.835, 0.843, 0.839,1} -- Slider Body
      ThickFrames = 0 -- Thickness - 0 = normal, 1 - thick frames
      
      TH[31] = {0.565, 0.565, 0.565, 1} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.735, 0.743, 0.739, 1} -- Slider Body (Top, Loop and Swing)
      ThickSwFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      TH[45] = { 0.835, 0.843, 0.839, 0.15 } -- Slider Background

      TH[46] = { 0.023, 0.103, 0.437, 0.1 } -- CheckBox Body
      TH[47] = 0.15 -- CheckBox Tint Transparency
      
      --------------Text--------------------      
      TH[33] = { 0.142, 0.111, 0.566, 0.9 } -- Text Main
      TH[34] = { 0.604, 0.184, 0.545, 0.9 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 0.45, 0.45, 0.45, 0.7 } -- Txt Greyed (BPM)
      TH[36] = { 0.45, 0.45, 0.45, 0.7 } -- Txt Greyed (Presets, Mode)
      TH[37] = -0.32 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.7 -- BPM digits transparency
      TH[48] = {1, 1, 1,0.1} -- BPM Background
      TH[49] = {1, 1, 1, 0.1} -- Status Bar Background
     
      -----------Elements------------------
      TH[39] =  { 0.8, 0.2, 0.1, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.2, 0.2, 0.2, 0.5 } -- Txt Brackets
      TH[41] = { 0.2, 0.2, 0.2, 0.5 } -- Main Separators
      TH[42] = 0.7 -- Leds Transparency (Controls Body)
      TH[43] = 0 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      TH[44] = { 0.20, 0.20, 0.20, 0.7 } -- Random+Q Bracket Color
      --------------------------------------------------------------

      elseif Theme == 12 then 
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
      ThickBFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      Tint_d = 1   -- Active Button Tint Coloring Mode: 1 - darker than Green tops elements, 0 - lighter than Green tops elements (best for light themes).
      Tint_a = 0.1 -- Active Button Tint Transparency
      
      TH[29] = {0.28,0.4,0.7,0.8} -- Slider Frames
      TH[30] = {0.28,0.4,0.7,0.8} -- Slider Body
      ThickFrames = 0 -- Thickness - 0 = normal, 1 - thick frames
      
      TH[31] = {0.28,0.4,0.7,0.8} -- Slider Frames (Top, Loop and Swing)
      TH[32] = {0.28,0.4,0.7,0.8} -- Slider Body (Top, Loop and Swing)
      ThickSwFrames = 0 -- Thickness - 0 = normal, 1 - thick frames

      TH[45] = { 0.28,0.4,0.7, 0.07 } -- Slider Background

      TH[46] = { 0.28,0.4,0.7,0.8 } -- CheckBox Body
      TH[47] = 0 -- CheckBox Tint Transparency
      
      --------------Text--------------------      
      TH[33] = { 0.8, 0.8, 0.8, 0.9 } -- Text Color
      TH[34] = { 1, 0.5, 0.3, 1 } -- Text Warn (Small "Processing, wait...")
      TH[35] = { 1, 1, 1, 0.2 } -- Txt Greyed (BPM)
      TH[36] = { 1, 1, 1, 0.25 } -- Txt Greyed (Presets, Mode)
      TH[37] = 0 -- an additional value is added to the brightness of the BPM digits. Can be negative.
      TH[38] = 0.9 -- BPM digits transparency
      TH[48] = {0.23, 0.25, 0.25, 0} -- BPM Background
      TH[49] = {0, 0, 0, 0} -- Status Bar Background
    
      -----------Elements------------------
      TH[39] =  { 0.8, 0.2, 0.1, 1 } -- Green tops elements (Loop triangles, Buttons Leds)
      TH[40] = { 0.4, 0.4, 0.4, 0.5 } -- Txt Brackets
      TH[41] = { 0.4, 0.4, 0.4, 0.5 } -- Main Separators
      TH[42] = 1 -- Leds Transparency (Controls Body)
      TH[43] = 0 -- Waveform Peaks Thickness (Transparency) - 0 = normal peaks, 1 - thick peaks, 0.5 or something = like a blur/antialiasing
      TH[44] = { 0.906, 0.463, 0.0, 0.9 } -- Random+Q Bracket Color
      --------------------------------------------------------------
      end
end

ThemeSel = tonumber(reaper.GetExtState('MK_ReSampler','ThemeSel'))or 2;
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
local rad = math.rad
-----------------------------------------------------------------------------

Take_Check = 0
Reset_to_def = 0
ErrMsg_Status = 0
Drag = 0
item_name = 'MK_ReSamplerTempItem48g3f' -- unique name here
track_name = 'MK_ReSamplerTempTrack1e30d' -- unique name here
ResetZoom = 0
-----------------------------------States and UA  protection-----------------------------
Docked = tonumber(r.GetExtState('MK_ReSampler','Docked'))or 0;
EscToExit = tonumber(r.GetExtState('MK_ReSampler','EscToExit'))or 1;
RS_SamplerMode_state = tonumber(r.GetExtState('MK_ReSampler','RS_SamplerMode.norm_val'))or 2; 
Vel_Det_Options_state = tonumber(r.GetExtState('MK_ReSampler','Vel_Det_Options.norm_val'))or 1;
ReverseBtn_on = tonumber(r.GetExtState('MK_ReSampler','ReverseBtn_on'))or 0; 
NoteOffBtn_on = tonumber(r.GetExtState('MK_ReSampler','NoteOffBtn_on'))or 1; 
MonoBtn_on = tonumber(r.GetExtState('MK_ReSampler','MonoBtn_on'))or 0; 
LoopBtn_on = tonumber(r.GetExtState('MK_ReSampler','LoopBtn_on'))or 0; 

FontAntiAliasing = tonumber(r.GetExtState('MK_ReSampler','FontAntiAliasing'))or 0;
MaxFontSizeSt = tonumber(r.GetExtState('MK_ReSampler','MaxFontSizeSt'))or 0;
if MaxFontSizeSt == 1 then MaxFontSize = 24 else MaxFontSize = 18 end

RS_Att_Sld_state = tonumber(r.GetExtState('MK_ReSampler','RS_Att_Sld.norm_val'))or 0;     
RS_Rel_Sld_state = tonumber(r.GetExtState('MK_ReSampler','RS_Rel_Sld.norm_val'))or 0;     
RandomPitch_Sld_state = tonumber(r.GetExtState('MK_ReSampler','RandomPitch_Sld.norm_val'))or 0;  
BaseOctave_state = tonumber(r.GetExtState('MK_ReSampler','BaseOctave.norm_val'))or 4;
--SingleVoice_state = tonumber(r.GetExtState('MK_ReSampler','SingleVoice.norm_val'))or 2;
Speed_state = tonumber(r.GetExtState('MK_ReSampler','Speed.norm_val'))or 4;
Notes_On = tonumber(r.GetExtState('MK_ReSampler','Notes_On'))or 1;

if RememberLast == nil then RememberLast = 1 end 
if RememberLast <= 0 then RememberLast = 0 elseif RememberLast >= 1 then RememberLast = 1 end  
if WFiltering == nil then WFiltering = 1 end 
if WFiltering <= 0 then WFiltering = 0 elseif WFiltering >= 1 then WFiltering = 1 end 


------------------------------------GetItemByType-----------------------------------------------------
function GetItemByType() -- Selected or on Specific Named Track
local Table = {}
local tracks, trk, retval, TName, items, item

item = r.GetSelectedMediaItem(0,0) --
    if item then
      Table = {item = item}
         else
            tracks = r.CountTracks();
            for i = tracks, 0, -1 do
               trk = r.GetTrack(0, i)
                  if trk then
                     retval, TName = r.GetSetMediaTrackInfo_String(trk, "P_NAME", "", false) -- 
                     if TName == track_name then 
                            items   =   r.CountTrackMediaItems(trk)
                            for i = 0, items do
                                item = r.GetTrackMediaItem(trk, i)
                                 if item then
                                 Table = {item = item}
                                 end
                           end
                     end
                end
           end
   end

return Table.item

end


---------------------------------------Check and Store Inits----------------------------------------------------------

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
    local gfx2imgui_path = r.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/gfx2imgui.lua'
    local os_sep = package.config:sub(1,1)
    gfx2imgui_path = gfx2imgui_path:gsub( "/", os_sep )
    if r.file_exists( gfx2imgui_path ) then
       gfx = dofile(r.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/gfx2imgui.lua')
       RG_status = "(ReaimGUI)"
       else
       RG_status = "(ReaimGUI not installed)"
    end
else
RG_status = ""
end

----------------------------function GetLoopTimeRange-----------------------------
function GetLoopTimeRange()
  start, ending = r.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
end



    r.Undo_BeginBlock() 
r.PreventUIRefresh(1)

-------------------------------Check time range and unselect-----------------------------
function unselect_if_out_of_time_range()

GetLoopTimeRange()

    if start == ending then return end;

    local CountSelItem = r.CountSelectedMediaItems(0)
    if CountSelItem == 0 then return end;

    for i = r.CountSelectedMediaItems(0)-1,0,-1 do;
        local SelItem = r.GetSelectedMediaItem(0,i);
        local PosIt = r.GetMediaItemInfo_Value(SelItem,"D_POSITION");
                     EndIt = PosIt + r.GetMediaItemInfo_Value(SelItem, "D_LENGTH")
        if (PosIt ~= start and EndIt ~= ending) and (PosIt < start or EndIt > ending) then;
            r.SetMediaItemInfo_Value(SelItem,"B_UISEL",0);
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
          if time_sel_length >= MinSelLength then
              r.Main_OnCommand(40718, 0) -- Item: Select all items on selected tracks in current time selection
              UnSelectMIDIAndEmptyItems()
          end
end

count_itms =  r.CountSelectedMediaItems(0)
if ObeyingTheSelection == 1 and count_itms ~= 0 and start ~= ending and time_sel_length >= MinSelLength then
   take_check()
   if Take_Check ~= 1 then

    SplitByTimeAndDeselect()

    collect_param()  

        if number_of_takes ~= 1 and No_Heal_On_Init == 0 then
           r.Main_OnCommand(40548, 0)  -- Heal Splits -- (если больше одного айтема и не миди айтем, то попытка не деструктивно склеить).
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


r.Main_OnCommand(40635, 0) -- Remove Time Selection
r.PreventUIRefresh(-1)

r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTORESEL'), 0)  -- Restore track selection
-----------------------------------------------------------------------------------------------------------------------------

readrms = 0.65
out_gain = 0.15
orig_gain = 10


function ClearExState()
    r.DeleteExtState('MK_ReSampler_', 'ItemToSample', 0)
    r.DeleteExtState('MK_ReSampler_', 'TrackForSlice', 0)
    r.SetExtState('MK_ReSampler_', 'GetItemState', 'ItemNotLoaded', 0)
end

ClearExState()

-- Is SWS installed?
if not r.APIExists("ULT_SetMediaItemNote") then
    r.ShowMessageBox("This script requires the SWS/S&M extension.\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org.", "ERROR", 0)
    return false 
end  

getitem = 1


r.PreventUIRefresh(-1); r.Undo_EndBlock('Slicer', -1)



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
corrY = -90 -- global shift only;

----------Random Setup Vertical Correction-------
f_pos = 20

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
 if ThickFrames == 1 then gfx.rect(x+1, y+1, w-2, h-2, false)  end          -- frame1 
end

function Element:draw_frame_sld()
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
  gfx.set(TH[45][1],TH[45][2],TH[45][3],TH[45][4]) -- sliders backgrounds
  gfx.rect(x, y, w, h, true)            -- frame1      
end

function Element:draw_frame_sw()
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local an = TH[31][4]
    if self:mouseIN() then an=an+0.1 end
    if self:mouseDown() then an=an+0.1 end
  gfx.set(TH[31][1],TH[31][2],TH[31][3],an) -- swing slider borders
  gfx.rect(x, y, w, h, false)            -- frame1    
 if ThickSwFrames == 1 then gfx.rect(x+1, y+1, w-2, h-2, false)  end          -- frame1  
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
 if ThickBFrames == 1 then gfx.rect(x+1, y+1, w-2, h-2, false)  end          -- frame1   
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

function Element:draw_frame_rnd_q()
  local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
  gfx.set(TH[44][1],TH[44][2],TH[44][3],TH[44][4]) -- brackets
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
  local Button, Button_top, Button_top_txt, Button_top_rec_symb, Button_Settings, Slider_simple, Slider_Fine, Knob, CheckBox_simple, CheckBox_simple_tntd, Frame_body, Frame, Colored_Rect, Colored_Rect_top, Frame_filled, ErrMsg, SysMsg, Txt, Txt2, Line, Line_colored, Line2, Line3, Ruler = {},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}
  extended(Button,     Element)
  extended(Button_top,     Element)
  extended(Button_top_txt,     Element)
  extended(Button_top_rec_symb,     Element)
  extended(Button_Settings,     Element)
  extended(Knob,       Element)
  extended(Slider_simple,     Element)
  extended(Slider_Fine,     Element)
  extended(ErrMsg,     Element)
  extended(SysMsg,     Element)
  extended(Txt,     Element)
  extended(Txt2,     Element)
  extended(Line,     Element)
  extended(Line_colored,     Element)
  extended(Line2,     Element)
  extended(Line3,     Element)
  extended(Ruler,     Element)
    -- Create Slider Child Classes --
  local Slider_Att, Slider_Rel, F_Slider = {},{},{}
    extended(Slider_Att, Slider_simple)
    extended(Slider_Rel, Slider_simple)
    extended(F_Slider, Slider_Fine)
    ---------------------------------
  extended(Frame_body,      Element)
  extended(Frame,      Element)
  extended(Colored_Rect,      Element)
  extended(Colored_Rect_top,      Element)
  extended(Frame_filled,      Element)
  extended(CheckBox_simple,   Element)
  extended(CheckBox_simple_tntd,   Element)
 
--------------------------------------------------------------------------------
---   Buttons Class Methods   ------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
function Button:draw_body()
    gfx.rect(self.x+1,self.y+1,self.w-2,self.h-2,true) -- draw btn body
end
--------
function Button:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+(w-lbl_w)/2; gfx.y = y+(h-lbl_h)/2
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
if self:mouseDown() and self.onDown then self.onDown() end
if self:mouseUp() and self.onUp then self.onUp() end
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

function Button_top_rec_symb:draw_rec_circle()
local c_rad = 3*Z_h
if c_rad < 2.0 then c_rad = 2.0 end
gfx.circle(self.x*1.05, self.y*1.08, c_rad, true, true)
end

function Button_top_rec_symb:draw_rec_frame()
--    gfx.rect(self.x+1,self.y+1,(self.w-2)/8,(self.h-2)/8,false) -- draw btn body
end
--------
function Button_top_txt:draw_lbl()
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
    if TH[27][4] ~= 0 then
        self:draw_frame3()   -- frame
    end

end

function Button_top_txt:draw()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = (self.def_xywh[1]* Z_w) , (self.def_xywh[3]* Z_w) -- upd x,w
  self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* Z_h) -- upd y,h
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    local fnt,fnt_sz = self.fnt, self.fnt_sz*(Z_h*1.05)
    if fnt_sz <= 10 then fnt_sz = 10 end
    if fnt_sz >= MaxFontSize then fnt_sz = MaxFontSize end
    -- Draw label --------------
    gfx.set(table.unpack(self.fnt_rgba))   -- set label color
    gfx.setfont(1, fnt, fnt_sz) -- set label fnt
   self:draw_lbl()             -- draw lbl

    gfx.set(r,g,b,a)    -- set body color

    if TH[27][4] == 0 then
        self:draw_frame3()   -- frame
    end
end

function Button_top_rec_symb:draw()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  self.x, self.w = (self.def_xywh[1]* Z_w) , (self.def_xywh[3]* Z_w) -- upd x,w
  self.y, self.h = (self.def_xywh[2]* Z_h) , (self.def_xywh[4]* Z_h) -- upd y,h
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a

    gfx.set(r,g,b,a)
  --  self:draw_rec_frame()

    if Rec_on == 1 then
        gfx.set(TH[39][1],TH[39][2],TH[39][3],0.8)
    end
    self:draw_rec_circle()   -- 

end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Button_Settings:draw_body()
    gfx.rect(self.x,self.y,self.w,self.h, true) -- draw btn body
end

function Button_Settings:draw_symb()
    gfx.rect(5+self.x*1.35,(self.y*2)/1.049,self.w/2,self.h/10, true) -- draw btn body
    gfx.rect(5+self.x*1.35,(self.y*3)/1.049,self.w/2,self.h/10, true) -- draw btn body
    gfx.rect(5+self.x*1.35,(self.y*4)/1.049,self.w/2,self.h/10, true) -- draw btn body
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
  self.x, self.w = (self.def_xywh[1]* (Z_w/2)) , (self.def_xywh[3]* (Z_w/8)+22) -- upd x,w
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
 --   self:draw_lbl()             -- draw lbl
self:draw_symb()
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
    if fnt_sz >= MaxFontSize-1 then fnt_sz = MaxFontSize-1 end
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

function Line3:draw() -- rnd q bracket
   self:update_xywh() -- Update xywh(if wind changed)
   local r,g,b,a  = self.r,self.g,self.b,self.a
   gfx.set(r,g,b,a)   -- set frame color -- цвет рамок
   self:draw_frame_rnd_q()  -- draw frame
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

     if h >= 20 then
        Zh2 = -2
        else
        Zh2 = 4
     end

     gfx.y = (y+(h-lbl_h)/50)-(Zh2/Z_h)

     local  fnt_sz = 10
     fnt_sz = fnt_sz*(Z_h*2)
      if fnt_sz < 10 then fnt_sz = 10 end
      if fnt_sz > 60 then fnt_sz = 60 end

  
      gfx.setfont(1, "Arial", fnt_sz)

      gfx.x = 50*Z_w

    gfx.set(TH[33][1], TH[33][2], TH[33][3], TH[33][4]) -- цвет текста 
        gfx.drawstr(self.lbl, 0|4, 980*Z_w, (50/(Z_h*8))+(22*Z_h))
end

--------------------------------------------------------------------------------
---   Slider Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
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
-------------------------------------------------------------------------------------

function Slider_Att:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    DefaultAttTime = tonumber(r.GetExtState('MK_ReSampler','DefaultAttTime'))or 0;
    if MCtrl then VAL = 0 end --set default value by Ctrl+LMB
    self.norm_val=VAL
end

function Slider_Rel:set_norm_val()
    local x, w = self.x, self.w
    local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
    if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
       else VAL = (gfx.mouse_x-x)/w end
    if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
    DefaultRelTime = tonumber(r.GetExtState('MK_ReSampler','DefaultRelTime'))or 0;
    if MCtrl then VAL = 0 end --set default value by Ctrl+LMB
    self.norm_val=VAL
end

function F_Slider:set_norm_val()
  local x, w = self.x, self.w
  local VAL,K = 0,10 -- VAL=temp value;K=coefficient(when Ctrl pressed)
  if Shift then VAL = self.norm_val + ((gfx.mouse_x-last_x)/(w*K))
     else VAL = (gfx.mouse_x-x)/w end
  if VAL<0 then VAL=0 elseif VAL>1 then VAL=1 end
  DefaultOffset = 0.5
  if MCtrl then VAL = DefaultOffset end --set default value by Ctrl+LMB
  self.norm_val=VAL
end
-----------------------------------------------------------------------------
function Slider_Att:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw Slider_Att body
end
function Slider_Rel:draw_body()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = w * self.norm_val
    gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw Slider_Rel body
end
function F_Slider:draw_body()
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = w * self.norm_val
  gfx.rect(x+1,y+1, val-2, h-2, true)  -- draw F_Slider body
end
--------------------------------------------------------------
function Slider_Att:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw Slider_Att label
end
function Slider_Rel:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
    gfx.drawstr(self.lbl) -- draw Slider_Rel label
end
function F_Slider:draw_lbl()
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local lbl_w, lbl_h = gfx.measurestr(self.lbl)
  gfx.x = x+3; gfx.y = y+(h-lbl_h)/2;
  gfx.drawstr(self.lbl) -- draw F_Slider label
end
---------------------------------------------------------------
function Slider_Att:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw Slider_Att Value
end
function Slider_Rel:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = string.format("%.2f", self.norm_val)
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
    gfx.drawstr(val) -- draw Slider_Rel Value
end
function F_Slider:draw_val()
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.2f", self.norm_val)
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-5; gfx.y = y+(h-val_h)/2;
  gfx.drawstr(val) -- draw F_Slider Value
end
----------------------------------------------------------------
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
             mouse_ox, mouse_oy = -1, -1 -- reset after self.onUp()
          end    
    -- Draw sldr body, frame ---
    self:draw_frame_sld() -- frame background
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
  self:draw_frame_sld() -- frame background
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
---   CheckBox Class Methods   ----------------------------------------------
--------------------------------------------------------------------------------
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
    gfx.set(TH[46][1],TH[46][2],TH[46][3],TH[46][4])    -- set body color
    self:draw_body()    -- body
    self:draw_frame()   -- frame
    -- Draw label --------------
    gfx.set(table.unpack(self.fnt_rgba))   -- set label,val color
    gfx.setfont(1, fnt, fnt_sz) -- set label,val fnt
    self:draw_lbl()             -- draw lbl
    self:draw_val()             -- draw val
end
--------------------------------------------------------------------------------
function CheckBox_simple_tntd:set_norm_val_m_wheel()
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
function CheckBox_simple_tntd:set_norm_val()
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
function CheckBox_simple_tntd:draw_body()
    gfx.rect(self.x+1,self.y+1,self.w-2,self.h-2, true) -- draw checkbox body
end
--------
function CheckBox_simple_tntd:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local lbl_w, lbl_h = gfx.measurestr(self.lbl)
    gfx.x = x-lbl_w-5; gfx.y = y+(h-lbl_h)/2
    gfx.drawstr(self.lbl) -- draw checkbox label
end
--------
function CheckBox_simple_tntd:draw_val()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local val = self.norm_val2[self.norm_val]
    local val_w, val_h = gfx.measurestr(val)
    gfx.x = x+3; gfx.y = y+(h-val_h)/2
    gfx.drawstr(val) -- draw checkbox val
end
------------------------
function CheckBox_simple_tntd:draw()
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
    gfx.set(TH[46][1],TH[46][2],TH[46][3],TH[46][4])    -- set body color
    self:draw_body()    -- body
    self:draw_frame()   -- frame
    self:draw_tint()
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

--local init_item = r.GetSelectedMediaItem(0,0)
local init_item = GetItemByType()

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
----------------------------------------------------------------------------------------------------
---  Create main objects(Wave,Gate) -----------------------------------------------------------
----------------------------------------------------------------------------------------------------
local Wave = Element:new(10,28,1024,252)
local Gate_Gl  = {}

---------------------------------------------------------------
---  Create Frames ------------------------------------------
---------------------------------------------------------------
------local tables to reduce locals (avoid 200 locals limits)-------
local elm_table = {}

elm_table[1] = Frame_body:new(10, 375+corrY,1024,100) --Main_Frame_body

elm_table[2] = Line2:new(dl1_pos,380+corrY,4,88, TH[41][1],TH[41][2],TH[41][3],TH[41][4]) -- Vertical Line
elm_table[3] = Line2:new(dl1_pos+1,380+corrY,4,88, TH[4][1],TH[4][2],TH[4][3],TH[4][4])--| fill

elm_table[17] = Line2:new(dl2_pos,380+corrY,4,88, TH[41][1],TH[41][2],TH[41][3],TH[41][4]) -- Vertical Line2 
elm_table[18] = Line2:new(dl2_pos+1,380+corrY,4,88, TH[4][1],TH[4][2],TH[4][3],TH[4][4])--| fill

elm_table[19] = Line2:new(dl3_pos,380+corrY,4,88, TH[41][1],TH[41][2],TH[41][3],TH[41][4]) -- Vertical Line3 
elm_table[20] = Line2:new(dl3_pos+1,380+corrY,4,88, TH[4][1],TH[4][2],TH[4][3],TH[4][4])--| fill

elm_table[21] = Frame:new(10, 375+corrY,1024,100) --Main_Frame


local leds_table = {}

if Tint_d == 1 then
  TH39_1 = TH[39][1]/2
  TH39_2 = TH[39][2]/2
  TH39_3 = TH[39][3]/2
  else
  TH39_1 = TH[39][1]*2
  TH39_2 = TH[39][2]*2
  TH39_3 = TH[39][3]*2
end
if TH39_1 < 0 then TH39_1 = 0 elseif TH39_1 > 1 then TH39_1 = 1 end
if TH39_2 < 0 then TH39_2 = 0 elseif TH39_2 > 1 then TH39_2 = 1 end
if TH39_3 < 0 then TH39_3 = 0 elseif TH39_3 > 1 then TH39_3 = 1 end

if TH[28][4] == 0 then fr_marg = 1; fr_marg2 = 2 else fr_marg = 0; fr_marg2 = 0 end -- if no frames, then add led size correction

leds_table[1] = Colored_Rect:new(927,380+corrY+fr_marg,3,22-fr_marg2,  0.1,0.7,0.2,TH[42] ) -- (Kybd on)
leds_table[2] = Colored_Rect:new(927,380+corrY+fr_marg,3,22-fr_marg2,  0.3,0.3,0.3,TH[42] ) -- (Kybd off)

leds_table[3] = Colored_Rect:new(908+d_pos,410+corrY,3,18,  0.1,0.7,0.2,TH[42] ) -- Light_Reverse_on
leds_table[4] = Colored_Rect:new(908+d_pos,410+corrY,3,18,  0.3,0.3,0.3,TH[42] ) -- Light_Reverse_off

leds_table[5] = Colored_Rect_top:new(997,5,3,20,  TH[39][1],TH[39][2],TH[39][3],TH[39][4] ) -- Light_Rec_on
leds_table[6] = Colored_Rect_top:new(997,5,3,20,  0.5,0.5,0.5,0.5 ) -- Light_Rec_off

leds_table[7] = Colored_Rect_top:new(1000,5,35,20,  TH39_1,TH39_2,TH39_3, Tint_a ) -- Tint_Light_Rec_on

elm_table[8] = Colored_Rect_top:new(0,0,1045,28,  TH[49][1],TH[49][2],TH[49][3],TH[49][4] ) --Status Bar_Frame_filled

leds_table[9] = Colored_Rect:new(737+d_pos,410+corrY,3,18,  0.1,0.7,0.2,TH[42] ) -- Light_NoteOff_on
leds_table[10] = Colored_Rect:new(737+d_pos,410+corrY,3,18,  0.3,0.3,0.3,TH[42] ) -- Light_NoteOff_off

leds_table[11] = Colored_Rect:new(737+d_pos,430+corrY,3,18,  0.1,0.7,0.2,TH[42] ) -- Light_Mono_on
leds_table[12] = Colored_Rect:new(737+d_pos,430+corrY,3,18,  0.3,0.3,0.3,TH[42] ) -- Light_Mono_off

leds_table[13] = Colored_Rect:new(737+d_pos,450+corrY,3,18,  0.1,0.7,0.2,TH[42] ) -- Light_Loop_on
leds_table[14] = Colored_Rect:new(737+d_pos,450+corrY,3,18,  0.3,0.3,0.3,TH[42] ) -- Light_Loop_off

local others_table = {}

others_table[1] = Txt:new(130+d_pos,384+corrY,55,18, TH[36][1],TH[36][2],TH[36][3],TH[36][4], "Amp","Arial",22)
others_table[2] = Txt:new(300+d_pos,384+corrY,55,18, TH[36][1],TH[36][2],TH[36][3],TH[36][4], "Pitch","Arial",22)

others_table[3] = Txt:new(470+d_pos,384+corrY,55,18, TH[36][1],TH[36][2],TH[36][3],TH[36][4], "Transpose","Arial",22)
others_table[4] = Txt:new(640+d_pos,384+corrY,55,18, TH[36][1],TH[36][2],TH[36][3],TH[36][4], "Play Options","Arial",22)

others_table[5] = Line:new(100+d_pos,404+corrY,110,6) --Line (Amp Bracket)
others_table[6] = Line2:new(100+d_pos,407+corrY,110,4,  TH[4][1],TH[4][2],TH[4][3],TH[4][4])--Line2 (Amp Bracket fill)

others_table[7] = Line:new(270+d_pos,404+corrY,110,6) --Line (Play Bracket)
others_table[8] = Line2:new(270+d_pos,407+corrY,110,4,  TH[4][1],TH[4][2],TH[4][3],TH[4][4])--Line2 (Play Bracket fill)

others_table[9] = Line:new(440+d_pos,404+corrY,110,6) --Line (Pitch Bracket)
others_table[10] = Line2:new(440+d_pos,407+corrY,110,4,  TH[4][1],TH[4][2],TH[4][3],TH[4][4])--Line2 (Pitch Bracket fill)

others_table[11] = Line:new(610+d_pos,404+corrY,110,6) --Line (Transpose Bracket)
others_table[12] = Line2:new(610+d_pos,407+corrY,110,4,  TH[4][1],TH[4][2],TH[4][3],TH[4][4])--Line2 (Transpose Bracket fill)



local Vel_Det_Options = CheckBox_simple:new(80+d_pos,450+corrY,150,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  Vel_Det_Options_state,
                              {"Velocity On","Velocity 50%", "Velocity Off"} )

local RS_SamplerMode = CheckBox_simple:new(250+d_pos,410+corrY,150,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  RS_SamplerMode_state,
                              {"Off", "HQ: Stretch", "HQ: Attack", "HQ: Sustain", "LQ: Crispy", "LQ: Smooth", "Rrreeeaaa"} )

local Speed = CheckBox_simple:new(250+d_pos,450+corrY,150,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  Speed_state,
                              {"Speed: x8", "Speed: x4", "Speed: x2", "Speed: x1", "Speed: x0.5", "Speed: x0.25", "Speed: x0.125"} )

local BaseOctave  = CheckBox_simple:new(420+d_pos,410+corrY,150,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  BaseOctave_state,
                                           {"Octave: +3","Octave: +2","Octave: +1","Octave: 0","Octave: -1","Octave: -2","Octave: -3"} )

local BasePitch  = CheckBox_simple:new(420+d_pos,430+corrY,150,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "","Arial",16,  13,
                                           {"Pitch: +12","Pitch: +11","Pitch: +10","Pitch: +9","Pitch: +8","Pitch: +7","Pitch: +6","Pitch: +5","Pitch: +4","Pitch: +3","Pitch: +2","Pitch: +1","Pitch: 0","Pitch: -1","Pitch: -2","Pitch: -3","Pitch: -4","Pitch: -5","Pitch: -6","Pitch: -7","Pitch: -8","Pitch: -9","Pitch: -10","Pitch: -11","Pitch: -12"} )


-- Create Settings Button ----------------------------
local Settings = Button_Settings:new(9,10,40,40, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "",    "Arial",20 )
Settings.onClick = 
function()
 --  Wave:Settings()
end 

function Wave:Settings()
end



function GetTrackRecordingMode(RecMode, RecArm)
local tr, RecMode, RecArm
local mode = {val, val2}
    tr = r.GetSelectedTrack(0, 0)
    if not tr then return end
    val = r.GetMediaTrackInfo_Value( tr, "I_RECMODE" )
    val2 = r.GetMediaTrackInfo_Value( tr, "I_RECARM" )
    mode[1] = {val = val}
    RecMode = mode[1].val
    mode[2] = {val2 = val2}
    RecArm = mode[2].val2
  return RecMode, RecArm
end

function SetTrackRecordingMode(RecMode, RecArm)
  local tr
   tr = r.GetSelectedTrack(0, 0)
   if not tr or not RecMode or not RecArm then return end
   r.SetMediaTrackInfo_Value( tr, "I_RECMODE", RecMode )
   r.SetMediaTrackInfo_Value( tr, "I_RECARM", RecArm )
end

function OnRecordStop()
  SetTrackRecordingMode(RecMode, RecArm)
  r.Main_OnCommand(1016, 0) -- Transport: Stop   
  r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTALLSELITEMS1"),0) -- SWS: Restore saved selected item(s)
  r.CF_Preview_StopAll()
end  

Rec_on = r.GetToggleCommandStateEx(0, 1013) -- get Transport: Record status

-- Rec Button ----------------------------
local Rec_Btn = Button_top:new(1000,5,35,20, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "",    "Arial",16 )
local Rec_Btn_Txt = Button_top_txt:new(1000,5,35,20, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "",    "Arial",16 )
local Rec_Btn_Tnt = Button_top_rec_symb:new(968,14,42,84, TH[33][1],TH[33][2],TH[33][3],TH[33][4]-0.1, "",    "Arial",16 )
Rec_Btn.onClick = 
function()
   if Wave.State then 
         if Rec_on == 0 then
              Rec_on = 1
              RecMode, RecArm = GetTrackRecordingMode()
              SetTrackRecordingMode(1, 1)
              r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVEALLSELITEMS1"),0) -- SWS: Save selected item(s)
              r.Main_OnCommand(1013, 0) -- Transport: Record
             else
              Rec_on = 0
              OnRecordStop()
         end
   end 
end 




-- NoteOffBtn Button ----------------------------
local NoteOffBtn = Button:new(590+d_pos,410+corrY,150,18, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "NoteOff",    "Arial",16 )
NoteOffBtn.onClick = 
function()
    if Wave.State then 
        if NoteOffBtn_on == 0 then 
           NoteOffBtn_on = 1
            else
           NoteOffBtn_on = 0
        end
    end 
end

-- MonoBtn Button ----------------------------
local MonoBtn = Button:new(590+d_pos,430+corrY,150,18, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Mono",    "Arial",16 )
MonoBtn.onClick = 
function()
    if Wave.State then 
        if MonoBtn_on == 0 then 
           MonoBtn_on = 1
            else
           MonoBtn_on = 0
        end
    end 
end

-- LoopBtn Button ----------------------------
local LoopBtn = Button:new(590+d_pos,450+corrY,150,18, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Loop",    "Arial",16 )
LoopBtn.onClick = 
function()
    if Wave.State then 
        if LoopBtn_on == 0 then 
           LoopBtn_on = 1
            else
           LoopBtn_on = 0
        end
    end 
end


ReverseBtn_ResetZoom = 0
-- ReverseBtn Button ----------------------------
local ReverseBtn = Button:new(760+d_pos,410+corrY,150,18, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Reverse",    "Arial",16 )
ReverseBtn.onClick = 
function()
    if Wave.State then 
      ReverseBtn_ResetZoom = 1 -- reset zoom and markers position on click only
        if ReverseBtn_on == 0 then 
           ReverseBtn_on = 1
            else
           ReverseBtn_on = 0
        end
    end 
end


-- Open_Kybd Button ----------------------------
local Open_Kybd = Button:new(928,380+corrY,100,22, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "VMK",    "Arial",16 )
Open_Kybd.onClick = 
function()
       r.Main_OnCommand(40377, 0) -- 
end


-- Stop! Button ----------------------------
local Reset_All = Button:new(928,448+corrY,100,22, TH[27][1],TH[27][2],TH[27][3],TH[27][4], "Stop!",    "Arial",16 )
Reset_All.onClick = 
function()
       LoopOn = 0
       r.CF_Preview_StopAll()
end

--[[
PadStat = 0
-- Pad Button ----------------------------
local Pad = Button:new(820,380+corrY,100,90, TH[27][1],TH[27][2],TH[27][3],0.7, "PAD",    "Arial",16 )
Pad.onDown = 
function()
PadStat = 1
Buf_1p = 144
NoteToNote2 = 0
end

Pad.onUp =
function()
  if PadStat == 1 and RS_ObeyNoteOff.norm_val == 1 then
    Buf_1p = 128
    Buf_1p = nil
    PadStat = 0
    NoteToNote2 = nil
  end
--if PadStat == 0 then Buf_1p = nil end
end
]]--




-- Att_Sld ------------------------------ 
local RS_Att_Sld = Slider_Att:new(80+d_pos,410+corrY,150,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "Attack","Arial",16, RS_Att_Sld_state ) -- DefaultAttTime
function RS_Att_Sld:draw_val()

  self.form_val = logx((self.norm_val-1)*-1)*20*-1   -- form_val
  if (self.form_val == -0.0) then self.form_val = 0 end
  if (self.form_val >= 100) then self.form_val = 100 end
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.1f", self.form_val).."ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.y = y+(h-val_h)/2
  gfx.drawstr(val)--draw Slider Value

RS_Att = self.form_val/1000

end
RS_Att_Sld.onUp =
function() 

end


-- Rel_Sld ------------------------------ 
local RS_Rel_Sld = Slider_Rel:new(80+d_pos,430+corrY,150,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "Release","Arial",16, RS_Rel_Sld_state ) --DefaultRelTime
function RS_Rel_Sld:draw_val()
  self.form_val = logx((self.norm_val-1)*-1)*200*-1   -- form_val
  if (self.form_val == -0.0) then self.form_val = 0 end
  if (self.form_val >= 1000) then self.form_val = 1000 end
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val).."ms"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.y = y+(h-val_h)/2
  gfx.drawstr(val)--draw Slider Value

RS_Rel = self.form_val/1000

end
RS_Rel_Sld.onUp =
function() 

end


-- RandomPitch_Sld ------------------------------ 
local RandomPitch_Sld = Slider_Rel:new(250+d_pos,430+corrY,150,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "Rnd. Pitch","Arial",16, RandomPitch_Sld_state ) --DefaultRelTime
function RandomPitch_Sld:draw_val()
 -- self.form_val = logx((self.norm_val-1)*-1)*25*-1   -- form_val
  self.form_val = (self.norm_val)*100   -- form_val
  if (self.form_val == -0.0) then self.form_val = 0 end
  if (self.form_val >= 100) then self.form_val = 100 end
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", self.form_val).."%"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.y = y+(h-val_h)/2
  gfx.drawstr(val)--draw Slider Value

RandomPitch = (19+(self.form_val-1)*-1)+100
end
RandomPitch_Sld.onUp =
function() 

end


-- PitchOffset_Sld ------------------------------ 
local PitchOffset_Sld = F_Slider:new(420+d_pos,450+corrY,150,18, TH[30][1],TH[30][2],TH[30][3],TH[30][4], "Fine","Arial",16, 0.5 )
function PitchOffset_Sld:draw_val()

  self.form_val  = floor(100-self.norm_val * 200)*( -1)     -- form_val

  function fixzero()
  FixMunus = self.form_val
  if (FixMunus== 0.0)then FixMunus = 0
  end

  end
  fixzero()  
  local x,y,w,h  = self.x,self.y,self.w,self.h
  local val = string.format("%.0f", FixMunus).."c"
  local val_w, val_h = gfx.measurestr(val)
  gfx.x = x+w-val_w-3
  gfx.drawstr(val)--draw Slider Value

RS_PitchOffset = self.form_val/100

  end
PitchOffset_Sld.onUp =
function() 

      fixzero() 

end



------------------------------------------------------------------------------------------------------------------------
---   WAVE   Sampler --------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

----------Get FilePath from Media Explorer----------https://forums.cockos.com/showpost.php?p=2687361&postcount=7
function RunAction(hwnd, id)
  r.JS_WindowMessage_Send(hwnd, 'WM_COMMAND', id, 0, 0, 0)
end

function GetSelectedFiles()
  if not r.ValidatePtr(mx, "HWND") then
    mx = r.OpenMediaExplorer("", false)
    path_hwnd = r.JS_Window_FindChildByID(mx, 1002)
  end
  if not mx then return end

  -- Parts based on code by Daodan (Thanks!), https://forum.cockos.com/showpost.php?p=2474322&postcount=12
  local show_full_path = r.GetToggleCommandStateEx(32063, 42026) == 1
  local show_leading_path = r.GetToggleCommandStateEx(32063, 42134) == 1
  local forced_full_path = false
  local path = r.JS_Window_GetTitle(path_hwnd)
  local mx_list_view = r.JS_Window_FindChildByID(mx, 1001)
  local _, sel_indexes = r.JS_ListView_ListAllSelItems(mx_list_view)
  local sep = package.config:sub(1, 1) 
  local sel_files = {}
  -- get selected files
  for index in string.gmatch(sel_indexes, '[^,]+') do
    index = tonumber(index)
    local file_name = r.JS_ListView_GetItem(mx_list_view, index, 0)
    -- Get selected/focused item in explorer file list
    local file_name = r.JS_ListView_GetItem(mx_list_view, index, 0)
    -- Check if file_name is valid path itself (for searches and DBs)
    if not r.file_exists(file_name) then file_name = path .. sep .. file_name end
    -- If file does not exist, try enabling option that shows full path
    if not show_full_path and not r.file_exists(file_name) then
      show_full_path = true
      forced_full_path = true
      RunAction(mx, 42026) -- Browser: Show full path in databases and searches
      file_name = r.JS_ListView_GetItem(mx_list_view, index, 0) 
    end 
    -- Check if file_name is valid path itself (for searches and DBs)
    if r.file_exists(file_name) then 
      sel_files[#sel_files + 1] = file_name
    else 
      file_name = path .. sep .. file_name 
      if r.file_exists(file_name) then sel_files[#sel_files + 1] = file_name end
      -- if file still not found its likely from DB with invalid paths, DB needs to be rescanned/updated!
    end
  end 
  -- Restore previous settings
  if forced_full_path then
    RunAction(mx, 42026) -- Browser: Show full path in databases and searches
    if show_leading_path then RunAction(mx, 42134) end  -- Browser: Show leading path in databases and searches
  end
  -- return results
  return sel_files
end



function GetPitchFromFileName(file)
    -- Parse note name from file name
    local pattern_pre = '([%p%s_[(-.])'
    local pattern_note = '([CDEFGABcdefgab][#b]?)'
    local pattern_add = '(%d?m?[MmSs]?[IiAaUu]?[NnJjSs]?o?r?%d*)' --
    local pattern_post = '([%p%s_[(-.])'
    local pattern = pattern_pre .. pattern_note .. pattern_add .. pattern_post -- 

    file = file or ''
    local file_name = file:match('([^\\/]+)$')
    local file_note
    file_name = file_name or ''
    for pre, note, add, post in file_name:gmatch(pattern) do
        if not file_note then file_note = string.upper(note) end
    end

    local note = {'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#'}

    if name == 'Db' then name = 'C#' end
    if name == 'Eb' then name = 'D#' end
    if name == 'Gb' then name = 'F#' end
    if name == 'Ab' then name = 'G#' end
    if name == 'Bb' then name = 'A#' end

    for i = 1, #note do
        if file_note == note[i] then
            return 12-(i+3)
        end
    end

end


------------------------------------CheckTrackName--------------------------------------------------
function CheckTrackName()
local tracks, trk, retval, TrName, TrackNameValid
   tracks = r.CountTracks();
   for i = tracks, 0, -1 do
      trk = r.GetTrack(0, i)
         if trk then
            retval, TrName = r.GetSetMediaTrackInfo_String(trk, "P_NAME", "", false) -- 
            if TrName == track_name then 
                  TrackNameValid = 1  
                  return TrackNameValid
                  else          
                  TrackNameValid = 0  
            end
         end
   end
end


------------------------------------DeleteTrackByName--------------------------------------------------
function DeleteTrackByName()
local tracks, trk, retval, NameToDel
   tracks = r.CountTracks();
   for i = tracks, 0, -1 do
      trk = r.GetTrack(0, i)
         if trk then
            retval, NameToDel = r.GetSetMediaTrackInfo_String(trk, "P_NAME", "", false) -- 
            if NameToDel == track_name then 
               r.DeleteTrack(trk) 
            end
         end
   end
end
DeleteTrackByName() -- delete on exit and init


------------------------------------DeleteItemByName--------------------------------------------------
function DeleteItemByName()
local tracks, trk, retval, NameToDel, items, item, tk, retval2, NameToDelIt
   tracks = r.CountTracks();
   for i = tracks, 0, -1 do
      trk = r.GetTrack(0, i)
         if trk then
            retval, NameToDel = r.GetSetMediaTrackInfo_String(trk, "P_NAME", "", false) -- 
            if NameToDel == track_name then 
                   items   =   r.CountTrackMediaItems(trk)
                   for i = 0, items do
                       item = r.GetTrackMediaItem(trk, i)
                         if item then
                            tk = r.GetActiveTake(item)
                               if tk then
                                   retval2, NameToDelIt = r.GetSetMediaItemTakeInfo_String(tk , "P_NAME", "", false)
                                   if NameToDelIt == item_name then 
                                      r.DeleteTrackMediaItem(trk, item)
                                   end
                               end   
                          end
                    end
              end
         end
   end
end

------------------------------------InsertNamedTrack---------------------------------------------------
function InsertNamedTrack()
       r.PreventUIRefresh(1)
local index, trck, track, item, tk
    index = r.CountTracks();
    r.InsertTrackAtIndex(index, 0)
    trck = r.GetTrack(0, index)
    
    r.GetSetMediaTrackInfo_String(trck, "P_NAME", "" .. track_name .. "", true) -- 
    -----HideTrack--------
    r.SetMediaTrackInfo_Value(trck, "B_SHOWINTCP", 0, false) -- 
    r.SetMediaTrackInfo_Value(trck, "B_SHOWINMIXER", 0, false) -- 
       r.PreventUIRefresh(-1)
end     

--------------------------------InsertNamedItemIntoNamedTrack---------------------------------------
function InsertNamedItemIntoNamedTrack()
local track, item, tk
local tracks, trk, retval, NameToDel
   tracks = r.CountTracks();
   for i = tracks, 0, -1 do
      trk = r.GetTrack(0, i)
         if trk then
            retval, NameToDel = r.GetSetMediaTrackInfo_String(trk, "P_NAME", "", false) -- 
            if NameToDel == track_name then 
                     track = r.GetTrack(0, i)
                     item = r.CreateNewMIDIItemInProj(track, 0, len, false) -- 
                     tk = r.GetActiveTake(item)
                     r.GetSetMediaItemTakeInfo_String(tk , "P_NAME", "" .. item_name .. "", true)
             end
         end
     end
end

------------------------------------InsertFileInToItem-----------------------------------------------------
function InsertFileInToItem()

local tracks, trk, retval, NameToDel, items, item, tk, retval2, NameToDelIt
   tracks = r.CountTracks();
   for i = tracks, 0, -1 do
      trk = r.GetTrack(0, i)
         if trk then
            retval, NameToDel = r.GetSetMediaTrackInfo_String(trk, "P_NAME", "", false) -- 
            if NameToDel == track_name then 
                   items   =   r.CountTrackMediaItems(trk)
                   for i = 0, items do
                       item = r.GetTrackMediaItem(trk, i)
                         if item then
                            tk = r.GetActiveTake(item)
                               if tk then
                                       retval2, NameToDelIt = r.GetSetMediaItemTakeInfo_String(tk , "P_NAME", "", false)
                                       if NameToDelIt == item_name then                
                                           r.BR_SetTakeSourceFromFile( tk, '' .. filepath .. '', 0 )
                                       end
                                 end
                           end
                     end
               end
          end
     end
end



--[[
function getFiles()
fileTable = {}
 local  retval, fileDr = gfx.getdropfile(0)
    if retval ~= 0 then
       fileTable = {fileDr = fileDr}
       gfx.drawstr(fileDr)
    end

  gfx.getdropfile(-1)
   
  reaper.defer(DropFile)
end

function DropFile()

  if gfx.getdropfile() ~= 0 then
--local droppedfilex = droppedfile
    getFiles()
    droppedfile = fileTable.fileDr
    return droppedfile
  else
    reaper.defer(DropFile)
  end
end


          droppedfile = DropFile()
]]--


function UnselectItemsIfMEFocused()
 local mouse = r.JS_Mouse_GetState (1) -- 1 - lmb, 2 - rmb
    if mouse == nil then return end
    if mouse == 1 or mouse == 2 then
        -- Get Control ID under mouse
       local x,y = r.GetMousePosition()
       local  hwnd = r.JS_Window_FromPoint(x,y)
       if reaper.JS_Window_GetTitle(reaper.JS_Window_GetParent(hwnd)) == "Media Explorer" then
          local pth = reaper.JS_Window_GetTitle(hwnd)
          if pth == 'List1' then
            reaper.Main_OnCommand(40289, 0) -- Item: Unselect (clear selection of) all items
          end
      end
   end
end


TableLength = {}

function Wave:Sampler()

local length, length_it, offset, mrkr_lngth, mrkr_offset, mode, submode
  PlayStat = 0
  Buf_0 = 0
  Buf_4 = 0
  local Buf_1x = Buf_1
  local Buf_2x = Buf_2 
  local filepathx = filepath
  local droppedfilex =  droppedfile 
  local filex = file 

     local retval,  buf,  ts,  devIdx = r.MIDI_GetRecentInputEvent(0)

     Buf1 =  string.byte(buf,1) or 128
     Buf_1 = Buf1+(Buf1&0x0/2) or 128
     Buf_2 =  string.byte(buf,2) or 0
     Buf_3 =  string.byte(buf,3) or 0
     NtOn = 144+(Buf1&0x0F) or 128

    -- Ch = Buf1&0x0F -- MIDI Channel-1

if Vel_Det_Options.norm_val == 1 then
    VelToVol = ((Buf_3/127)*Buf_3)/130
    elseif Vel_Det_Options.norm_val == 2 then
    VelToVol = (1/127)*Buf_3
else
   VelToVol = 1
end

if (Buf_1 ~= Buf_1x) then  Buf_0 = 1 end -- if note triggered

if Buf_2 ~= Buf_2x and Buf_1 == NtOn then  Buf_4 = 1 end -- if note pressed and changed

if ((Buf_1 ~= Buf_1x and Buf_1 == NtOn) or Buf_4 == 1) then 
   PlayStat = 1; 
   if MonoBtn_on == 1 then 
      if  Buf_1 == Buf_1x then
        RS_Rel = 0; 
      end
       r.CF_Preview_StopAll()  
   end
end



local track = r.GetSelectedTrack(0, 0)
local item = r.GetSelectedMediaItem(0, 0)

if item then

   if (Buf_1 ~= Buf_1x) then
      take = r.GetActiveTake(item)
      src1 = r.GetMediaItemTake_Source(take)
      filepath = r.GetMediaSourceFileName(src1, "")
    
      pos = r.GetMediaItemInfo_Value(item, "D_POSITION")
      rate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
      length_it    = r.GetMediaItemInfo_Value(item, "D_LENGTH")
      len    =  length_it*rate
      offset_it = r.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS", pos-len)
      TableLength = {len = len}
    end

 else

    if (Buf_1 ~= Buf_1x) then
      
        --Display selected files in Media Explorer
      if r.GetToggleCommandStateEx(0, 50124) == 1 then -- if not check, GetSelectedFiles() always open explorer 
          flpth = GetSelectedFiles()
          for i = 1, #flpth do 
              filepath =  flpth[i]
          end
      end

  --  if (droppedfile) then filepath = droppedfile end
  
      if filepath == nil then return end
      filepath = filepath:gsub("\\", "/")
    
        local source  = r.PCM_Source_CreateFromFile('' .. filepath .. '')
        retval2, offs, len, rev = r.PCM_Source_GetSectionInfo(source)

    -----------------DummyTempTrackAndItem--------------------------------
      if filepathx ~= filepath then
          TableLength = {len = len}
          r.PreventUIRefresh(1)
            if CheckTrackName() == 1 then
                DeleteItemByName() -- delete ItemName from existing track
                else
                InsertNamedTrack() -- insert TrackName 
            end
            
            InsertNamedItemIntoNamedTrack()
            InsertFileInToItem()
        r.PreventUIRefresh(-1)
    end
    --------------------------------------------------------------------------------
    rate = 1
  end
end

length = TableLength.len

if filepath == nil then return end

if BaseOctave.norm_val == 1 then Oct = 0
   elseif BaseOctave.norm_val == 2 then Oct = 12
   elseif BaseOctave.norm_val == 3 then Oct = 24
   elseif BaseOctave.norm_val == 4 then Oct = 36
   elseif BaseOctave.norm_val == 5 then Oct = 48
   elseif BaseOctave.norm_val == 6 then Oct = 60
   elseif BaseOctave.norm_val == 7 then Oct = 72
end

if BasePitch.norm_val == 1 then BPitch = 12
   elseif BasePitch.norm_val == 2 then BPitch = 11
   elseif BasePitch.norm_val == 3 then BPitch = 10
   elseif BasePitch.norm_val == 4 then BPitch = 9
   elseif BasePitch.norm_val == 5 then BPitch = 8
   elseif BasePitch.norm_val == 6 then BPitch = 7
   elseif BasePitch.norm_val == 7 then BPitch = 6
   elseif BasePitch.norm_val == 8 then BPitch = 5
   elseif BasePitch.norm_val == 9 then BPitch = 4
   elseif BasePitch.norm_val == 10 then BPitch = 3
   elseif BasePitch.norm_val == 11 then BPitch = 2
   elseif BasePitch.norm_val == 12 then BPitch = 1
   elseif BasePitch.norm_val == 13 then BPitch = 0
   elseif BasePitch.norm_val == 14 then BPitch = -1
   elseif BasePitch.norm_val == 15 then BPitch = -2
   elseif BasePitch.norm_val == 16 then BPitch = -3
   elseif BasePitch.norm_val == 17 then BPitch = -4
   elseif BasePitch.norm_val == 18 then BPitch = -5
   elseif BasePitch.norm_val == 19 then BPitch = -6
   elseif BasePitch.norm_val == 20 then BPitch = -7
   elseif BasePitch.norm_val == 21 then BPitch = -8
   elseif BasePitch.norm_val == 22 then BPitch = -9
   elseif BasePitch.norm_val == 23 then BPitch = -10
   elseif BasePitch.norm_val == 24 then BPitch = -11
   elseif BasePitch.norm_val == 25 then BPitch = -12
end

Oct = Oct or 36
NoteToNote = (Buf_2-Oct)+(GetPitchFromFileName(filepath) or 0)+BPitch+(RS_PitchOffset or 0)

if RS_SamplerMode.norm_val == 1 then NoteToNote = 0 end

if length == nil then return end

rate = rate or 1
offset = offset or 0
offset_it = offset_it or 0
RS_Rel = RS_Rel or 0
StartOffsPos2 = StartOffsPos2 or 0
EndOffsPos2 = EndOffsPos2 or 0
RandomPitch = RandomPitch or 120

mrkr_lngth = (length/1024)*(1024-EndOffsPos2)
if item == nil then 
   offset = (length/1024)*StartOffsPos2 or 0
   length = (length-offset)-mrkr_lngth
   else
   offset = offset_it + (length/1024)*StartOffsPos2 or 0 
   length = (length - ((length/1024)*StartOffsPos2))-mrkr_lngth
end

if ReverseBtn_on == 1 then rvrs = 1; offset =  mrkr_lngth else rvrs = 0 end

local source  = r.PCM_Source_CreateFromFile(filepath)
if not source then return end
local section = r.PCM_Source_CreateFromType('SECTION')
r.CF_PCM_Source_SetSectionInfo(section, source, offset, length+RS_Rel, rvrs)
r.PCM_Source_Destroy(source)
local preview = r.CF_CreatePreview(section)
r.PCM_Source_Destroy(section)

            r.CF_Preview_SetValue(preview, "D_VOLUME", VelToVol)
            r.CF_Preview_SetValue(preview, "D_FADEINLEN", RS_Att or 0)
            r.CF_Preview_SetValue(preview, "D_FADEOUTLEN", RS_Rel or 0)

          if (Buf_1 ~= Buf_1x) and RandomPitch ~= 120 then
              random_pitch = (random(28)-14)/RandomPitch
              random_pitch2 = random_pitch/6
              else
              random_pitch = 0
              random_pitch2 = 0
          end

       if RS_SamplerMode.norm_val == 1 or RS_SamplerMode.norm_val == 2 then -- stretch
            r.CF_Preview_SetValue(preview, "B_PPITCH", 0)
            r.CF_Preview_SetValue(preview, "D_PLAYRATE", (random_pitch2+(2^(NoteToNote/12))) + 0.001)

           else -- pitch 

               --mode = -- 10- élastique 3.3.3 Efficient, 0 - SoundTouch, 2 - Simple Windowed, 144 - Rubber Band, 14 - Reeeeaaaa, 15 - ReaReaRea
               --submode = -- 0 - Default
               --pitch_add = 0.001 -- algorithm trigger (temporary?)
               if RS_SamplerMode.norm_val == 3 then mode = 10; submode = 0; pitch_add = 0.001
                  elseif RS_SamplerMode.norm_val == 4 then mode = 144; submode = 0; pitch_add = 0.001
                  elseif RS_SamplerMode.norm_val == 5 then mode = 15; submode = 0; pitch_add = 0.001
                  elseif RS_SamplerMode.norm_val == 6 then mode = 2; submode = 0; pitch_add = 0.001
                  elseif RS_SamplerMode.norm_val == 7 then mode = 14; submode = 0; pitch_add = 0.001
               end

              if Speed.norm_val == 1 then Speed_Rate = 8
                 elseif Speed.norm_val == 2 then Speed_Rate = 4
                 elseif Speed.norm_val == 3 then Speed_Rate = 2
                 elseif Speed.norm_val == 4 then Speed_Rate = 0
                 elseif Speed.norm_val == 5 then Speed_Rate = 0.5
                 elseif Speed.norm_val == 6 then Speed_Rate = 0.25
                 elseif Speed.norm_val == 7 then Speed_Rate = 0.125
              end

            r.CF_Preview_SetValue(preview, "D_PLAYRATE", Speed_Rate)
            r.CF_Preview_SetValue(preview, "I_PITCHMODE", mode<<16|submode)
            r.CF_Preview_SetValue(preview, "D_PITCH", NoteToNote+pitch_add+random_pitch)
        end

            if LoopBtn_on == 1 then -- 
                r.CF_Preview_SetValue(preview, "B_LOOP", 1)
            end

           r.CF_Preview_SetOutputTrack( preview, 0, track ) -- output

           if PlayStat == 1  then    
               r.CF_Preview_Play(preview) 
               if filepathx ~= filepath then
                 getitem_fast()
               end
           end -- after configuring the preview

 --if  Buf_3 == 0   then  r.CF_Preview_Stop(preview);  end -- 

    if NoteOffBtn_on == 1 then
      if (Buf_1 ~= NtOn and Buf_1 ~= Buf_1x) then PlayStat = 0; r.CF_Preview_StopAll() end -- 
    end

end



--------------------------------------------------------------------------------
---  Accessor  -----------------------------------------------------------------
--------------------------------------------------------------------------------
function Wave:Create_Track_Accessor() 
       local item = GetItemByType()
    --local item = r.GetSelectedMediaItem(0,0) -- 
        if item then
        item_to_sample = r.BR_GetMediaItemGUID(item)
       
           r.DeleteExtState('MK_ReSampler_', 'ItemToSample', 0)
           r.SetExtState('MK_ReSampler_', 'ItemToSample', item_to_sample, 0)
           r.SetExtState('MK_ReSampler_', 'GetItemState', 'ItemLoaded', 0)
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
   
 --  if getitem == 0 then
       if self.AA then r.DestroyAudioAccessor(self.AA) 
          self.buffer.clear()
       end
 --   end

end


--------
function Wave:Get_TimeSelection()
-- local item = r.GetSelectedMediaItem(0,0)
   local item = GetItemByType()
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
if sel_len < MinSelLength then
------------------------------------------Error Message-----------------------------------------
local timer = 2 -- Time in seconds
local time = reaper.time_precise()
local function Msg()
   local char = gfx.getchar()
     if char == 27 or char == -1 or (reaper.time_precise() - time) > timer then ErrM_St_s2 = 0 return else ErrM_St_s2 = 1 end
local Get_Sel_ErrMsg = ErrMsg:new(580,35,260,45, 1, 1, 1, 1, "Item is Too Short (< " .. MinSelLength .." s)")
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
    if sel_len<MinSelLength or time_sel_length < MinSelLength then return end -- 0.25 minimum
else
    if sel_len<MinSelLength then return end -- 0.25 minimum
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
    self:draw_waveform(TH[6][1],TH[6][2],TH[6][3],TH[6][4]) -- Only original 
    ---------------
    gfx.dest = -1          -- set main gfx dest buffer
    ---------------
end

--------------------------------------------------------------
--------------------------------------------------------------
function Wave:draw_waveform(r,g,b,a)
--local start_time = reaper.time_precise()
    local Peak_TB, Ysc
    local Y = self.Y
    ----------------------------
    Peak_TB = self.in_peaks;  
    Ysc = self.Y_scale+orig_gain * self.vertZoom
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
function Wave:Create_Peaks() -- mode = 1 for original, mode = 2 for filtered
--local start_time = reaper.time_precise()
    local buf
    buf = self.in_buf    -- for input(original)    
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
              min_smpl = smpl
              max_smpl = smpl
        end
        a = a +1
        Peak_TB[a] = {min_smpl, max_smpl} -- min, max val to table
        curr = ceil(next) 
    end
    ----------------------------
    self.in_peaks = Peak_TB   
    ----------------------------
--reaper.ShowConsoleMsg("Full Process time = " .. reaper.time_precise()-start_time .. '\n') -- time test 
end


------------------------------------------------------------------------------------------------------------------------
-- WAVE - (Get samples(in_buf) > filtering > to out-buf > Create in, out peaks ) ---------------------------------------
------------------------------------------------------------------------------------------------------------------------
-------
function Wave:table_plus(size, tmp_buf)
  local buf=self.in_buf
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
    srate = srate or 44100
    -- Calculate some values --------
    self.sel_len    = min(self.sel_len,time_limit)     -- limit lenght(deliberate restriction) 
    self.selSamples = floor(self.sel_len*srate)        -- time selection lenght to samples
    -- init Horizontal --------------

    local MaxZoom = logx(200*self.sel_len)*20
    if MaxZoom > 150 then MaxZoom = 150 end
    self.max_Zoom = MaxZoom -- maximum zoom level(желательно ок.150-200,но зав. от длины выдел.(нужно поправить в созд. пиков!))
    self.Zoom = self.Zoom or 1  -- init Zoom 
    self.Pos  = self.Pos  or 0  -- init src position
    -- init Vertical ---------------- 
    self.max_vertZoom = 200       -- maximum vertical zoom level(need optim value)
    self.vertZoom = self.vertZoom or 1  -- init vertical Zoom 
    ---------------------------------
    -- pix_dens - нужно выбрать оптимум или оптимальную зависимость от sel_len!!!
    self.pix_dens = 16           -- 2^(4-1) 4-default. 1-учесть все семплы для прорисовки(max кач-во),2-через один и тд. 16 - max, 1 - min
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
    -----------
    local rest_smpls  = self.selSamples - self.n_Full_Bufs*self.full_buf_sz -- остаток семплов
    self.rest_buf_sz  = ceil(rest_smpls/div_fact) * div_fact  -- размер остаточного(окр. вверх для захв. полн. участка)
  -------------
  return true
end

-----------------------------------
function Wave:Processing()
--local start_time = reaper.time_precise()
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
            if i==1 then self.in_buf = tmp_buf.table(1, size) else self:table_plus((i-1)*self.full_buf_sz, tmp_buf.table(1, size) ) end
            --------
            buf_start = buf_start + len -- to next
            ------------------------
        end
        self:Create_Peaks()  -- Create_Peaks input(Original) wave peaks
        self.in_buf  = nil    -- входной больше не нужен
    end
    
    self.State = true -- Change State
    -------------------------
    collectgarbage() -- collectgarbage(подметает память) 
--reaper.ShowConsoleMsg("Full Process time = " .. reaper.time_precise()-start_time .. '\n') -- time test 
end 


LoopOn = 0
----------------------------------------------------------------------------------------------------
---  Wave - Get - Set Cursors  ------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Wave:Get_Cursor() 

     local NtN
     rate = rate or 1
     StartOffsPos = StartOffsPos or 0
     EndOffsPos = EndOffsPos or 0
     Speed_Rate = Speed_Rate or 1
     if Speed_Rate == 0 or RS_SamplerMode.norm_val == 1 then Speed_Rate = 1 end
  ---play cursor ---

  if NoteOffBtn_on == 1 then -- stop audio when note off = on
    if RS_ObeyNoteOff_state2 == 0 then
    r.CF_Preview_StopAll();
    RS_ObeyNoteOff_state2 = 1
    end
  else
    RS_ObeyNoteOff_state2 = 0
  end

  if ((LoopBtn_on == 1 and NoteOffBtn_on == 0) or NoteOffBtn_on == 0) then
        if (Buf_0 == 1 and Buf_1 == NtOn) then
          counter = 0
          LoopOn = 1
        end
      else
        LoopOn = 0
   end


    if (Buf_1 == NtOn and Buf_4 ~= 1) or (LoopOn == 1) then 
      counter = (counter + 1) 
      else
      counter = 0
    end

        if RS_SamplerMode.norm_val == 2 then -- pitch
           NtN = 2^(NoteToNote/12)/rate -- note pitch depended speed
           else
           NtN = (1*Speed_Rate)/rate -- constant speed
        end

   count = (counter-1)/(32/NtN)

     local insrc_Pcx = (count) * srate * self.X_scale -- cursor in source!
     self.Pcx = (insrc_Pcx) * self.Zoom*Z_w                  -- Play cursor -- 
     self.Pcx = self.Pcx + (StartOffsPos) -- + start marker correction
   --  self.PcxEnd = self.Pcx + (EndOffsPos) -- + end marker correction
     StartOffsPos2 = ((StartOffsPos/Z_w)+(self.Pos*self.Zoom))/self.Zoom -- start marker gui-independent value for offset
     EndOffsPos2 = ((EndOffsPos/Z_w)+(self.Pos*self.Zoom))/self.Zoom -- end marker gui-independent value for length
     if LoopBtn_on == 1 and (self.Pcx >= self.w*self.Zoom or self.Pcx >= EndOffsPos ) then counter = 0 end
     if counter ~= 0 and (self.Pcx >= 0 and self.Pcx <= self.w and self.Pcx <= EndOffsPos) then gfx.set(TH[23][1],TH[23][2],TH[23][3],TH[23][4]) -- play cursor color  -- цвет плэй курсора
        gfx.line(self.x + self.Pcx, self.y, self.x + self.Pcx, self.y+self.h -1 )
          if not self:mouseDown() then
             grad_w2 = TH[24]*(0.7+Z_w/2)
             gfx.gradrect(((self.x+1) + self.Pcx)-grad_w2, self.y, grad_w2, self.h,        TH[23][1],TH[23][2],TH[23][3], 0.0,    0, 0, 0, TH[25] / grad_w2) -- grad back
             gfx.gradrect((self.x-1) + self.Pcx, self.y, grad_w2, self.h,        TH[23][1],TH[23][2],TH[23][3], TH[25],    0, 0, 0, -TH[25] / grad_w2) -- grad ahead
          end
      end
end 

counter = 0

----------------------------------------------------------------------------------------------------
---  Wave - Get Mouse  -------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Wave:Get_Mouse()
    -----------------------------
insrc_Ecx_k = insrc_Ecx_k or 512
local gfx_mouse_x
if ReverseBtn_on == 1 then
  gfx_mouse_x = (self.w-gfx.mouse_x)+(20*Z_w)
  --gfx_mouse_x = gfx.mouse_x
  else
  gfx_mouse_x = gfx.mouse_x
end

local true_position = (gfx_mouse_x-self.x)/Z_w  --  waveform borders correction
local pos_margin = gfx_mouse_x-self.x
if true_position < 24 then pos_margin = 0 end
if true_position > 1000 then pos_margin = gfx_mouse_x end
self.insrc_mx_zoom = self.Pos + (pos_margin)/(self.Zoom*Z_w) -- its current mouse position in source!
selfinsrc_mx_zoom = self.insrc_mx_zoom
self.insrc_mx = self.x-(self.Pos - (gfx.mouse_x-self.x))/(Z_w) -- zoom focus to mouse position

    --- Wave get-set Cursors ----
    self:Get_Cursor()

self.insrc_mx_zoom_k = self.Pos + (insrc_Ecx_k-self.x)/(self.Zoom*Z_w) -- for keyboard arrows
    -----------------------------------------
    --- Wave Zoom(horizontal) ---------------
    if self:mouseIN() and gfx.mouse_wheel~=0 and not(Ctrl or Shift) then 
    local M_Wheel = gfx.mouse_wheel
      -------------------
      if ReverseBtn_on == 0 then
          if     M_Wheel>0 then self.Zoom = min(self.Zoom*1.25, self.max_Zoom)   
          elseif M_Wheel<0 then self.Zoom = max(self.Zoom*0.75, 1)
          end      
      end
      -- correction Wave Position from src --
      self.Pos = self.insrc_mx_zoom - (gfx_mouse_x-self.x)/(self.Zoom*Z_w) 

      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )  
   
      self.Pos2 = self.Pos2 or 0
      self.Pos2 = self.insrc_mx_zoom - (gfx_mouse_x-self.x)/(self.Zoom*Z_w)
      self.Pos2 = max(self.Pos2, 0)
      self.Pos2 = min(self.Pos2, (self.w - self.w/self.Zoom)/Z_w )
      -------------------
      Wave:Redraw() -- redraw after horizontal zoom
    end
    -----------------------------------------
    --- Wave Zoom(Vertical) -----------------
    if self:mouseIN() and gfx.mouse_wheel~=0 and (Ctrl or Shift) then 
    local  M_Wheel = gfx.mouse_wheel

------------------------------------------------------------------------------------------------------
     if     M_Wheel>0 then self.vertZoom = min(self.vertZoom*1.5, self.max_vertZoom)   
     elseif M_Wheel<0 then self.vertZoom = max(self.vertZoom*0.5, 1)
     end                 
     -------------------
     Wave:Redraw() -- redraw after vertical zoom
    end
    -----------------------------------------
      Cursor_Status = 0
    --- Wave Move ---------------------------
    if (self:mouseDown() or self:mouseM_Down()) and not Shift and not Ctrl and (mouse_pos_height <= mphMin) then 
      Cursor_Status = 1
      if ReverseBtn_on == 1 then
        self.Pos = self.Pos - (last_x - gfx.mouse_x)/(self.Zoom*Z_w)
        else
        self.Pos = self.Pos + (last_x - gfx.mouse_x)/(self.Zoom*Z_w)
      end

      self.Pos = max(self.Pos, 0)
      self.Pos = min(self.Pos, (self.w - self.w/self.Zoom)/Z_w )
      
      self.Pos2 = self.Pos2 or 0
      self.Pos2 = self.Pos2 + (last_x - gfx.mouse_x)/(self.Zoom*Z_w)
      self.Pos2 = max(self.Pos2, 0)
      self.Pos2 = min(self.Pos2, (self.w - self.w/self.Zoom)/Z_w )
      
      --------------------
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

    --------------------------------------------
    --- Reset Zoom by Middle Mouse Button------
    if Ctrl and self:mouseM_Down() or ResetZoom == 1 then 
      self.Pos = 0
      self.Zoom = 1   
      Wave:Redraw() -- redraw after zoom reset
      ResetZoom = 0
      --------------------
    end

     --------------------------------------------------------------------------------
     -- Zoom by Arrow Keys
     --------------------------------------------------------------------------------
local KeyUP, KeyDWN, KeyL, KeyR

    if char==30064 and (Shift or Ctrl) then KeyUP = 1 else KeyUP = 0 end -- up
    if char==1685026670 and (Shift or Ctrl) then KeyDWN = 1 else KeyDWN = 0 end -- down
    if char==1818584692 and (Shift or Ctrl) then KeyL = 1 else KeyL = 0 end -- left
    if char==1919379572 and (Shift or Ctrl) then KeyR = 1 else KeyR = 0 end -- right

-------------------------------horizontal----------------------------------------
if ReverseBtn_on == 0 then
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
 end
-------------------------------vertical-------------------------------------------
     if  KeyUP == 1 then self.vertZoom = min(self.vertZoom*1.5, self.max_vertZoom)   
     Wave:Redraw() -- redraw after vertical zoom

     elseif  KeyDWN == 1 then self.vertZoom = max(self.vertZoom*0.5, 1)
     Wave:Redraw() -- redraw after vertical zoom
     end   

     if ReverseBtn_on == 1 then -- reset and lock zoom if reversed.
      self.Pos = 0
      self.Pos2 = 0
      self.Zoom = 1  
    else
      self.Pos = self.Pos
      self.Pos2 = self.Pos2
      self.Zoom = self.Zoom  
    end

    a_Pos = self.Pos
    a_Pos2 = self.Pos2
    a_Zoom = self.Zoom  

end


--------------------------------------------------------------------------------
---   Gate  --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Gate_Gl:Apply_toFiltered()
 Res_Points = {0}
 Res_Points2 = {1024}
end

--------------------------------------------------------------------------------
-- Gate -  manual_Correction ---------------------------------------------------
--------------------------------------------------------------------------------
-----------------------------------------------------------------------
---  Gate - Draw Gate Lines  -------------------------------------------
-----------------------------------------------------------------------
function Gate_Gl:draw_Lines()

  if not Res_Points then return end -- return if no lines
    --------------------------------------------------------
    -- Set values ------------------------------------------
    --------------------------------------------------------
    local line_x_mouse_x, line_x  --, line_x_mouse_x2, line_x2
    local DragStart = 0
    local DragEnd = 0
    -- Pos, X, Y scale in gfx  ---------

if ReverseBtn_on == 1 then
  WavePos = Wave.Pos2 or 0
  else
  WavePos = Wave.Pos or 0
end

    self.start_smpl = WavePos/Wave.X_scale    -- Стартовая позиция отрисовки в семплах!
    self.Xsc = Wave.X_scale * Wave.Zoom * Z_w  -- x scale(regard zoom) for trigg lines
    const = 1.11 -- triangle, vertical position
    triangle_size = 50*((Z_w/10)+(Wave.Zoom/20))
    if triangle_size > 14 then triangle_size = 14 end
    --------------------------------------------------------
    mouse_pos_height =  gfx.mouse_y/Z_h 
    mouse_pos_width =  gfx.mouse_x/Z_w

    mphMin = 200
    mphMax = 380

    local  fnt_sz = 16
    fnt_sz = fnt_sz*(Z_h)
    if fnt_sz < 12 then fnt_sz = 12 end
    if fnt_sz > 32 then fnt_sz = 32 end
    gfx.setfont(1, "Arial", fnt_sz)

--------------------- Draw, capture trig lines ----------------------------
-----------------------------------------------------------------------------------------------------------------------------
------------------------------------- Start Marker--------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
    for i=1, #Res_Points, 2 do 
           line_x = Wave.x + (Res_Points[i]-WavePos)*Wave.Zoom*Z_w  -- line x coord
--if line_x2 and line_x>=line_x2-(10-Wave.Pos*Wave.Zoom*Z_w) and DragEnd == 0 then line_x = line_x2-(10-Wave.Pos*Wave.Zoom*Z_w); self.cap_ln = false end
        ------------------------
        -- draw line-----
        ------------------------
           gfx.set(TH[1][1],TH[1][2],TH[1][3],0.7) -- brackets
           gfx.rect(Wave.x, Wave.y, line_x-(9*Z_w), Wave.h, true)            -- pre-start shading

        if line_x>=Wave.x and line_x<=Wave.x+Wave.w then -- Verify line range

           gfx.set(TH[13][1],TH[13][2],TH[13][3],TH[13][4]) -- gate line, point color -- цвет маркеров транзиентов
           gfx.line(line_x, Wave.y, line_x, Wave.y+Wave.h-1)  -- Draw Marker Line
           if TH[16] > 0 then
               grad_w2 = TH[16]*(0.7+Z_w/2)
               gfx.gradrect((line_x+1)-grad_w2, Wave.y, grad_w2, Wave.h,        TH[13][1],TH[13][2],TH[13][3], 0.0,    0, 0, 0, TH[17] / grad_w2) -- grad back
               gfx.gradrect(line_x-1, Wave.y, grad_w2, Wave.h,        TH[13][1],TH[13][2],TH[13][3], TH[17],    0, 0, 0, -TH[17] / grad_w2) -- grad ahead
           end
           gfx.triangle(line_x+1, Wave.h*const, line_x+1, (Wave.h*const)-triangle_size, line_x+triangle_size+1, Wave.h*const) -- Triangle (Start Marker Small Flag)
           gfx.set(TH[13][1],TH[13][2],TH[13][3],0.75) -- gate line, point color -- цвет маркеров транзиентов
           gfx.x = line_x+7
           gfx.y = ((Wave.h*const)-10)/1.07
           if line_x2 and line_x2>=line_x+80 then
              gfx.drawstr("start", 4|4, Wave.w, Wave.h*const) -- (Start Marker text)
           end
         end
        
            ------------------------
            -- Get mouse -----------
            ------------------------
            line_x_mouse_x = line_x-gfx.mouse_x
            if line_x_mouse_x < 0 then line_x_mouse_x = line_x_mouse_x*-1 end

            grab_corr = 17
            if not self.cap_ln and line_x_mouse_x < (grab_corr) and gfx.mouse_x > (10*Z_w) then -- здесь grab_corr - величина окна захвата маркера.
                if Wave:mouseDown() or Wave:mouseR_Down() then self.cap_ln = i end
                   if not Ctrl and mouse_pos_height >= mphMin and mouse_pos_height <= mphMax-100 then  
                       if TH[14] > 0 then
                          grad_w = TH[14]*(0.7+Z_w/2) -- selected marker gradient
                          gfx.gradrect((line_x+1)-grad_w, Wave.y, grad_w, Wave.h,        TH[13][1],TH[13][2],TH[13][3], 0.0,    0, 0, 0, TH[15] / grad_w) -- grad back
                          gfx.gradrect(line_x-1, Wave.y, grad_w, Wave.h,        TH[13][1],TH[13][2],TH[13][3], TH[15],    0, 0, 0, -TH[15] / grad_w) -- grad ahead
                        end
                   end
            end
       end

       StartOffsPos = line_x -(10*Z_w)
       --------------------------------------------------------
       -- Operations with captured lines(if exist) ------------
       --------------------------------------------------------
              if self.cap_ln  then -- and line_x< line_x2+100
                r.CF_Preview_StopAll(); counter = 0; LoopOn = 0
                  -- Move Line -----------------------------
                  if not Ctrl and DragEnd == 0 and (mouse_pos_height >= mphMin and mouse_pos_height <= mphMax) then 
                      DragStart = 1
                      local curs_x = min(max(gfx.mouse_x, Wave.x), Wave.x + Wave.w) -- x coord
                      --------------------
                      Res_Points[self.cap_ln] = ((curs_x-Wave.x)/Wave.Zoom/Z_w)+WavePos -- Set New Position
                  end
              end
       -- Update captured state if mouse released -------------
       if self.cap_ln and Wave:mouseUp() then self.cap_ln = false end   

  -----------------------------------------------------------------------------------------------------------------------------
  ------------------------------------- End Marker--------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------------------
  if not Res_Points2 then return end -- return if no lines
     for i=1, #Res_Points2, 2 do 
           line_x2 = Wave.x + (Res_Points2[i]-WavePos)*Wave.Zoom*Z_w  -- line x coord
--if line_x2<=line_x+(10-Wave.Pos*Wave.Zoom*Z_w) and DragEnd == 0 then line_x2 = line_x+(10-Wave.Pos*Wave.Zoom*Z_w); self.cap_ln2 = false end
        ------------------------
        -- draw line -----
        ------------------------
           gfx.set(TH[1][1],TH[1][2],TH[1][3],0.7) -- brackets
           gfx.rect(line_x2, Wave.y, (Wave.w-line_x2)+(11*Z_w), Wave.h, true)            -- post-end shading

        if line_x2>=Wave.x and line_x2<=Wave.x+Wave.w then -- Verify line range

           gfx.set(TH[13][1],TH[13][2],TH[13][3],TH[13][4]) -- gate line, point color -- цвет маркеров транзиентов
           gfx.line(line_x2, Wave.y, line_x2, Wave.y+Wave.h-1)  -- Draw Marker Line
           if TH[16] > 0 then
               grad_w2 = TH[16]*(0.7+Z_w/2)
               gfx.gradrect((line_x2+1)-grad_w2, Wave.y, grad_w2, Wave.h,        TH[13][1],TH[13][2],TH[13][3], 0.0,    0, 0, 0, TH[17] / grad_w2) -- grad back
               gfx.gradrect(line_x2-1, Wave.y, grad_w2, Wave.h,        TH[13][1],TH[13][2],TH[13][3], TH[17],    0, 0, 0, -TH[17] / grad_w2) -- grad ahead
           end
           gfx.triangle(line_x2+1-1, Wave.h*const, line_x2-1, (Wave.h*const)-triangle_size, line_x2-triangle_size-1, Wave.h*const) -- Triangle (End Marker Small Flag)
           gfx.set(TH[13][1],TH[13][2],TH[13][3],0.75) -- gate line, point color -- цвет маркеров транзиентов
           gfx.x = line_x2-80
           gfx.y = ((Wave.h*const)-10)/1.07
           if line_x2>=line_x+80 then
              gfx.drawstr("end", 2|4, line_x2-5, (Wave.h*const)) -- (End Marker text)
           end
         end
        
            ------------------------
            -- Get mouse -----------
            ------------------------
            line_x_mouse_x2 = line_x2-gfx.mouse_x
            if line_x_mouse_x2 < 0 then line_x_mouse_x2 = line_x_mouse_x2*-1 end

            grab_corr = 17
            if not self.cap_ln2 and line_x_mouse_x2 < (grab_corr) and gfx.mouse_x < (1034*Z_w) then -- здесь grab_corr - величина окна захвата маркера.
                if Wave:mouseDown() or Wave:mouseR_Down() then self.cap_ln2 = i end
                   if not Ctrl and mouse_pos_height >= mphMin and mouse_pos_height <= mphMax-100 then  
                       if TH[14] > 0 then
                          grad_w = TH[14]*(0.7+Z_w/2) -- selected marker gradient
                          gfx.gradrect((line_x2+1)-grad_w, Wave.y, grad_w, Wave.h,        TH[13][1],TH[13][2],TH[13][3], 0.0,    0, 0, 0, TH[15] / grad_w) -- grad back
                          gfx.gradrect(line_x2-1, Wave.y, grad_w, Wave.h,        TH[13][1],TH[13][2],TH[13][3], TH[15],    0, 0, 0, -TH[15] / grad_w) -- grad ahead
                        end
                   end
            end
       end

       EndOffsPos = line_x2-(10*Z_w)
       --------------------------------------------------------
       -- Operations with captured lines(if exist) ------------
       --------------------------------------------------------
              if self.cap_ln2  then --and line_x+100 < line_x2
                r.CF_Preview_StopAll(); counter = 0; LoopOn = 0
                  -- Move Line -----------------------------
                  if not Ctrl and DragStart == 0  and (mouse_pos_height >= mphMin and mouse_pos_height <= mphMax) then 
                      DragEnd = 1
                      local curs_x2 = min(max(gfx.mouse_x, Wave.x), Wave.x + Wave.w) -- x coord
                      --------------------
                      Res_Points2[self.cap_ln2] = ((curs_x2-Wave.x)/Wave.Zoom/Z_w)+WavePos -- Set New Position
          
                  end
              end
       -- Update captured state if mouse released -------------
       if self.cap_ln2 and Wave:mouseUp() then self.cap_ln2 = false end     

       insrc_Ecx_k = StartOffsPos+(EndOffsPos - StartOffsPos)/2

     --------------------------------------------------------
     ------Reset Markers X Button------------
     --------------------------------------------------------
      if (mouse_pos_height >= Wave.y/Z_h and mouse_pos_height <= (Wave.y+(37*Z_h))/Z_h and mouse_pos_width >= (Wave.w-(30*Z_w))/Z_w and  mouse_pos_width <= (Wave.w+(10*Z_w))/Z_w) then
             gfx.set(1-TH[1][1],1-TH[1][2],1-TH[1][3],0.05) -- shading
             gfx.rect(Wave.w-(30*Z_w), Wave.y, (40*Z_w), Wave.y+(10*Z_h), true) -- shading area
         
             gfx.set(TH[13][1],TH[13][2],TH[13][3],TH[13][4])  -- hover color
         
               if Wave:mouseDown() and Drag == 0 then
                  Gate_Gl:Apply_toFiltered()
                  ResetZoom = 1
               end    
          else       
             gfx.set(1-TH[1][1],1-TH[1][2],1-TH[1][3], 0.1) -- default color
     end

    gfx.x = Wave.w-(14*Z_w)
    gfx.y = Wave.y+(14*Z_h)
    gfx.drawstr("X", Wave.w, Wave.h) -- (End Marker text)



end -- function Gate_Gl:draw_Lines()


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

    ---------------------------Waveform Reverse Animation------------------------------
    angleR = Wave.w 

    if ReverseBtn_on == 1 then 
      if angle_counter ~= angleR then
          angle_counter = angle_counter+200*Z_w 
          if angle_counter >= angleR then angle_counter = angleR end
      end
     else 
      angle = 0 
      if angle_counter ~= angle then
          angle_counter = angle_counter-200*Z_w 
          if angle_counter <= angle then angle_counter = angle end
      end
    end

    if angle_counter > angleR*2  then
      angle2 = rad(180)
      else
      angle2 = rad(0)
    end
    ------------------------------------------------------------------------------------------

    if WFiltering == 0 then gfx.mode = 4 end
    gfx.blit(1, 1, angle2, 0, 0, srcw, srch,  self.x+angle_counter, self.y, self.w-(angle_counter*2), self.h)

       self:Get_Mouse()     -- get mouse(for zoom, move etc) 

       Gate_Gl:draw_Lines()  -- Draw Start and End lines
end  
angle_counter = 0


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
 gfx.x, gfx.y = self.x+40 * ((Z_w/4)+Z_h)-ZH_correction, (self.y+1*(Z_h*3))
 gfx.drawstr(
  [[
    Select an Item or File in the Media Browser.
    Use MIDI Keyboard to make a noise.

    Sliders:
    Shift+Drag/Mousewheel - fine tune,
    Ctrl+Left Click - reset value to default,

    Waveform Area:
    Mouswheel or Left/Right keys - Horizontal Zoom,
    Ctrl(Shift)+Mouswheel or Up/Down keys - Vertical Zoom, 
    Left or Middle Drag - Move View (Horizontal Scroll),
    Left Drag Small Flag - Move Marker

    Esc - Close ReSampler.
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
        ErrMsg_Status = 1  
             local fnt_sz = 100
             if gfx.ext_retina == 1 then
              fnt_sz = max(24,  fnt_sz* (Z_h)/2)
              fnt_sz = min(80, fnt_sz* Z_h)
             else
              fnt_sz = max(32,  fnt_sz* (Z_h)/2)
              fnt_sz = min(96, fnt_sz* Z_h)
             end

              gfx.setfont(1, "Arial", fnt_sz)
              gfx.set(TH[33][1], TH[33][2], TH[33][3], TH[33][4]) -- цвет текста инфо
              local ZH_correction = Z_h*40
              gfx.x, gfx.y = self.x+23 * (Z_w+Z_h)-ZH_correction, (self.y+1*(Z_h*3))+(100*Z_h)
             
              gfx.drawstr("Processing, wait...", 1, gfx.w, gfx.h)
       end
end


---------------------------Get Track Number and Item Name to table----------------------------
function InitTrackItemName()

     local track, track_num, item, take, source, src_parent
     
     TableTI = {}
     
      track = r.GetSelectedTrack(0, 0)

      if not track then 
      TableTI.track  = 'N/A'
      else
      track_num = r.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
      TableTI.track  = ('%d'):format(track_num) -- convert 3.0 to 3
      end

      if filepath == nil then return end
      local  filepath = filepath:gsub("\\", "/")
   
      item = reaper.GetSelectedMediaItem(0, 0)

      if item then
        take = reaper.GetActiveTake(item)
        if take then
        source = reaper.GetMediaItemTake_Source(take)
        src_parent = r.GetMediaSourceParent(source)
        if src_parent ~= nil then TableTI_item = 'Reversed (not supported)'; goto item_rev end
        end
        else
        source  = r.PCM_Source_CreateFromFile('' .. filepath .. '')
      end

        TableTI_item = r.GetMediaSourceFileName(source or src_parent, "")
        ::item_rev::
        TableTI.item = TableTI_item:gsub("\\", "/")
      local _, _, TableTI_length, _ = r.PCM_Source_GetSectionInfo(source or src_parent)
  TableTI.length = TableTI_length
  return TableTI.track, TableTI.item, TableTI.length

end



function Wave:show_init_track_item_name()
text_track, text_sys, text_length = InitTrackItemName()
--if TableTI.item == '' then TableTI.item = 'NoName' end
local SysSource
      if  text_sys then    
             text_sys = TextShort(text_sys, 150)
             text_sys = text_sys:gsub(".*/", "")
             text_length = math_round(text_length,2)
              if r.GetSelectedMediaItem(0,0) == nil then             
                  SysSource = 'File: '
                  else
                  SysSource = 'Item: '
              end
             local Get_Sel_SysMsg = SysMsg:new(550,15,470,20, 1, 1, 1, 1, "Track: ".. text_track .."  |  "  ..  SysSource .. "".. text_sys .."  |  Length: ".. text_length .."s")
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

UnselectItemsIfMEFocused()

Wave:Sampler()

if Rec_on == 1 and r.GetPlayState()&1 == 0 then -- if Rec stopped from DAW transport
     Rec_on = 0
     OnRecordStop()
 end

local Frame_NoteOff_TB = {leds_table[9]}
local Frame_NoteOff_TB2 = {leds_table[10]}
local Frame_Mono_TB = {leds_table[11]}
local Frame_Mono_TB2 = {leds_table[12]}
local Frame_Loop_TB = {leds_table[13]}
local Frame_Loop_TB2 = {leds_table[14]}

local Frame_Reverse_TB = {leds_table[3]}
local Frame_Reverse_TB2 = {leds_table[4]}
local Frame_Rec_TB = {leds_table[5]}
local Frame_Rec_TB2 = {leds_table[6]}
local Frame_Tint_Rec_TB = {leds_table[7]}
local Frame_TB = {elm_table[1], elm_table[3], elm_table[18], elm_table[20], elm_table[21]} 
local StatusBar_Bck_TB = {elm_table[8]}
local Text_TB = {others_table[1], others_table[2], others_table[3], others_table[4],others_table[5], others_table[6],others_table[7], others_table[8], others_table[9], others_table[10],others_table[11], others_table[12]}    

----------------------------------------
--- Button_TB --------------------------
----------------------------------------
local Btn_TB = {Rec_Btn } -- top swing button: GrBtnT[9]
local Btn_Txt_TB2 = {Rec_Btn_Txt, Rec_Btn_Tnt}

local Checkbox_TB_preset = {RS_Att_Sld, RS_Rel_Sld, PitchOffset_Sld, RS_PitchBend_Sld, RS_ObeyNoteOff, RS_SamplerMode, Vel_Det_Options, SingleVoice, BaseOctave,BasePitch,RandomPitch_Sld, Reverse, Reset_All, ReverseBtn,NoteOffBtn,MonoBtn,LoopBtn}
local Checkbox_TB_speed = {Speed}
local Frame_TB1 = {leds_table[2]}
local Frame_TB2 = {leds_table[1]} -- 

local SysMsg_TB = {Get_Sel_SysMsg}
local Button_TB = {Settings, Open_Kybd, Pad}
local  Loop_ReSampler_TB2 = {Loop_Sampler} --trigger

-----------------------------------
--- CheckBox_TB -------------------
-----------------------------------
for key,btn    in pairs(Frame_TB)   do btn:draw()    end 
  -- Draw Wave, lines etc ------
    if Wave.State then   
   
        Wave:from_gfxBuffer() -- Wave from gfx buffer



        for key,btn    in pairs(StatusBar_Bck_TB)   do btn:draw()    end -- Status Bar Background

          -----------------------------Top Buttons-------------------------------
           if Rec_on == 1 then
              for key,btn    in pairs(Frame_Rec_TB)   do btn:draw()    end 
              else
              for key,btn    in pairs(Frame_Rec_TB2)   do btn:draw()    end 
          end

        for key,btn    in pairs(Btn_TB)   do btn:draw()    end 

          -- Draw sldrs, btns etc ------



        for key,ch_box in pairs(Btn_Txt_TB2) do ch_box:draw() end -- aim, snap, loop text layer

        for key,btn    in pairs(Text_TB)   do btn:draw()    end -- Status Bar Background

        for key,ch_box    in pairs(Checkbox_TB_preset)   do ch_box:draw()    end 
        for key,btn    in pairs(Loop_ReSampler_TB2)   do btn:draw()    end -- Loop_Sampler

        if  RS_SamplerMode.norm_val > 2 then --show if algo
                  for key,ch_box    in pairs(Checkbox_TB_speed)   do ch_box:draw()    end       
        end

           if ErrMsg_Status == 0  then
                Wave:show_init_track_item_name()
           end

           if Rec_on == 1 then
            for key,btn    in pairs(Frame_Tint_Rec_TB)   do btn:draw()    end 
        end

          if NoteOffBtn_on == 1 then
            for key,btn    in pairs(Frame_NoteOff_TB)   do btn:draw()    end 
            else
            for key,btn    in pairs(Frame_NoteOff_TB2)   do btn:draw()    end 
        end

          if MonoBtn_on == 1 then
            for key,btn    in pairs(Frame_Mono_TB)   do btn:draw()    end 
            else
            for key,btn    in pairs(Frame_Mono_TB2)   do btn:draw()    end 
        end

          if LoopBtn_on == 1 then
            for key,btn    in pairs(Frame_Loop_TB)   do btn:draw()    end 
            else
            for key,btn    in pairs(Frame_Loop_TB2)   do btn:draw()    end 
        end

         if ReverseBtn_on == 1 then
              for key,btn    in pairs(Frame_Reverse_TB)   do btn:draw()    end 
              else
              for key,btn    in pairs(Frame_Reverse_TB2)   do btn:draw()    end 
          end

      end

      for key,btn    in pairs(Button_TB)   do btn:draw()    end -- open kybd, settings and pad buttons

        if r.GetToggleCommandStateEx(0, 40377) == 1 then -- View: Show virtual MIDI keyboard
          for key,btn    in pairs(Frame_TB2)   do btn:draw()    end -- 
          else
          for key,btn    in pairs(Frame_TB1)   do btn:draw()    end -- 
         end

          if not Wave.State and ErrMsg_Status == 0 then  
              Wave:show_help()      -- else show help
          end
 
end

------------------------------------------------------------------------------------

function store_settings() --store dock position
   r.SetExtState("MK_ReSampler", "dock", gfx.dock(-1), true)
end

function store_settings2() --store sliders/checkboxes
     if RememberLast == 1 then 
        r.SetExtState('MK_ReSampler','BaseOctave.norm_val',BaseOctave.norm_val,true);
        r.SetExtState('MK_ReSampler','Speed.norm_val',Speed.norm_val,true);
        r.SetExtState('MK_ReSampler','ReverseBtn_on',ReverseBtn_on,true);
        r.SetExtState('MK_ReSampler','NoteOffBtn_on',NoteOffBtn_on,true);
        r.SetExtState('MK_ReSampler','MonoBtn_on',MonoBtn_on,true);
        r.SetExtState('MK_ReSampler','LoopBtn_on',LoopBtn_on,true);
        r.SetExtState('MK_ReSampler','RS_SamplerMode.norm_val',RS_SamplerMode.norm_val,true);
        r.SetExtState('MK_ReSampler','Vel_Det_Options.norm_val',Vel_Det_Options.norm_val,true);
        r.SetExtState('MK_ReSampler','RS_Att_Sld.norm_val',RS_Att_Sld.norm_val,true);
        r.SetExtState('MK_ReSampler','RS_Rel_Sld.norm_val',RS_Rel_Sld.norm_val,true);
        r.SetExtState('MK_ReSampler','RandomPitch_Sld.norm_val',RandomPitch_Sld.norm_val,true);

     end
end

-------------------------------------------------------------------------------
--   INIT   --------------------------------------------------------------------
-------------------------------------------------------------------------------
function Init()

  --Dock ------
   dock_pos = tonumber(r.GetExtState("MK_ReSampler", "dock"))
       if Docked == 1 then
         if not dock_pos or dock_pos == 0 then dock_pos = 1025 end
           dock_pos = dock_pos | 1
           gfx.dock(dock_pos)
           xpos = 400
           ypos = 320
           else
           dock_pos = 0
           xpos = tonumber(r.GetExtState("MK_ReSampler", "window_x")) or 400
           ypos = tonumber(r.GetExtState("MK_ReSampler", "window_y")) or 320
        end

    -- Some gfx Wnd Default Values ---------------
    local R,G,B = ceil(TH[3][1]*255),ceil(TH[3][2]*255),ceil(TH[3][3]*255)             -- 0...255 format -- цвет основного окна
    local Wnd_bgd = R + G*256 + B*65536 -- red+green*256+blue*65536  
    local Wnd_Title = "MK ReSampler v0.9.1" .. " " .. theme_name .. " " .. RG_status .. ""
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



       Wnd_W = tonumber(r.GetExtState("MK_ReSampler", "zoomW")) or 1044
       Wnd_H = tonumber(r.GetExtState("MK_ReSampler", "zoomH")) or 390
       if Wnd_W == (nil or 0) then Wnd_W = 1044 end
       if Wnd_H == (nil or 0) then Wnd_H = 390 end
    -- Init window ------
 --   Wnd_W,Wnd_H = 1044,490 -- global values(used for define zoom level)
    gfx.clear = Wnd_bgd         
    gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )

    -- Init mouse last --
    last_mouse_cap = 0
    last_x, last_y = 0, 0
    mouse_ox, mouse_oy = -1, -1


    Gate_Gl:Apply_toFiltered()


end

---------------------------------------
--   Mainloop   ------------------------
---------------------------------------
function mainloop()

  if ReverseBtn_ResetZoom == 1 then -- reset and lock zoom if reversed.
    ResetZoom = 1 
    Gate_Gl:Apply_toFiltered()
    ReverseBtn_ResetZoom = 0
  end


    -- zoom level -- 
    Wnd_WZ = tonumber(r.GetExtState("MK_ReSampler", "zoomWZ")) or 1044
    Wnd_HZ = tonumber(r.GetExtState("MK_ReSampler", "zoomHZ")) or 390
    if Wnd_WZ == (nil or 0) then Wnd_WZ = 1044 end
    if Wnd_HZ == (nil or 0) then Wnd_HZ = 390 end

    Z_w, Z_h = gfx.w/Wnd_WZ, gfx.h/Wnd_HZ
    gfx_width = gfx.w
    if Z_w<0.5 then Z_w = 0.5 elseif Z_w>4 then Z_w = 4 end --2.2
    if Z_h<0.5 then Z_h = 0.5 elseif Z_h>4 then Z_h = 4 end  --2.2

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
 

         if PlayMode == 1 then
            r.Main_OnCommand(40073, 0) -- play/pause
            else
            r.Main_OnCommand(40044, 0) -- play/stop
         end

    end -- play
  
     if char==26 then 
         r.Main_OnCommand(40029, 0)  
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
    r.SetExtState("MK_ReSampler", "window_x", xpos, true)
    r.SetExtState("MK_ReSampler", "window_y", ypos, true)
    r.SetExtState("MK_ReSampler", "zoomW", Wnd_W, true)
    r.SetExtState("MK_ReSampler", "zoomH", Wnd_H, true)
    r.SetExtState("MK_ReSampler", "zoomWZ", Wnd_WZ, true)
    r.SetExtState("MK_ReSampler", "zoomHZ", Wnd_HZ, true)
end

function getitem()

     time_start = reaper.time_precise()       
        local function Main()     
            local elapsed = reaper.time_precise() - time_start       
            if elapsed >= 0.05 then
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
                           Init_Srate() -- Project Samplerate
                           Wave:Destroy_Track_Accessor() -- Destroy previos AA(освобождает память etc)
                           Wave.State = false -- reset Wave.State
                           if Wave:Create_Track_Accessor() then Wave:Processing()
                              if Wave.State then
                                 Wave:Redraw()
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
-------------------------
  collect_itemtake_param()
  Muted = 0
  if number_of_takes == 1 and mute_check == 1 then 
    r.Undo_BeginBlock() 
    r.PreventUIRefresh(1)
    r.Main_OnCommand(40175, 0) 
    Muted = 1
  end
        ----------------------------
           Init_Srate() -- Project Samplerate
           Wave:Destroy_Track_Accessor() -- Destroy previos AA(освобождает память etc)
           Wave.State = false -- reset Wave.State
           if Wave:Create_Track_Accessor() then Wave:Processing()
              if Wave.State then
                 Wave:Redraw()
              end
           end
        ----------------------------------
  if Muted == 1 then
    r.Main_OnCommand(40175, 0) 
    r.PreventUIRefresh(-1)
    r.Undo_EndBlock("Toggle Item Mute", -1) 
  end
---------------------------
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
                     r.CF_ShellExecute('https://forum.cockos.com/showthread.php?t=287293')
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
                         r.SetExtState("MK_ReSampler", "window_x", xpos, true)
                         r.SetExtState("MK_ReSampler", "window_y", ypos, true)
                         r.SetExtState("MK_ReSampler", "zoomW", Wnd_W, true)
                         r.SetExtState("MK_ReSampler", "zoomH", Wnd_H, true)
                         r.SetExtState("MK_ReSampler", "zoomWZ", Wnd_WZ, true)
                         r.SetExtState("MK_ReSampler", "zoomHZ", Wnd_HZ, true)
                     
                          gfx.quit()
                          Docked = 1
                          dock_pos = tonumber(r.GetExtState("MK_ReSampler", "dock"))
                          if not dock_pos or dock_pos == 0 then dock_pos = 1025 end
                          dock_pos = dock_pos | 1
                          gfx.dock(dock_pos)
                          xpos = 400
                          ypos = 320
                          local Wnd_Title = "MK ReSampler v0.9.1"
                          local Wnd_Dock, Wnd_X,Wnd_Y = dock_pos, xpos, ypos
                          gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )

                     else

                         r.SetExtState("MK_ReSampler", "dock", gfx.dock(-1), true)
                         gfx.quit()
                         Docked = 0
                         dock_pos = 0
                         xpos = tonumber(r.GetExtState("MK_ReSampler", "window_x")) or 400
                         ypos = tonumber(r.GetExtState("MK_ReSampler", "window_y")) or 320
                         local Wnd_Title = "MK ReSampler v0.9.1"
                         local Wnd_Dock, Wnd_X,Wnd_Y = dock_pos, xpos, ypos
                         if Wnd_Y == (nil or 0) then Wnd_Y = Wnd_Y+25 end -- correction for window header visibility
                         gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )
                      
                         Wnd_WZ = tonumber(r.GetExtState("MK_ReSampler", "zoomWZ")) or 1044
                         Wnd_HZ = tonumber(r.GetExtState("MK_ReSampler", "zoomHZ")) or 390
                         if Wnd_WZ == (nil or 0) then Wnd_WZ = 1044 end
                         if Wnd_HZ == (nil or 0) then Wnd_HZ = 390 end
                      
                         Z_w, Z_h = gfx.w/Wnd_WZ, gfx.h/Wnd_HZ
                      
                         if Z_w<0.63 then Z_w = 0.63 elseif Z_w>4 then Z_w = 4 end --2.2
                         if Z_h<0.63 then Z_h = 0.63 elseif Z_h>4 then Z_h = 4 end 
                     end
          r.SetExtState('MK_ReSampler','Docked',Docked,true);
end


if EscToExit == 1 then
item6 = context_menu:add_item({label = "Use ESC to Close Script|", toggleable = true, selected = true})
else
item6 = context_menu:add_item({label = "Use ESC to Close Script|", toggleable = true, selected = false})
end
item6.command = function()
                     if item6.selected == true then 
                     EscToExit = 1
                     else
                     EscToExit = 0
                     end
          r.SetExtState('MK_ReSampler','EscToExit',EscToExit,true);
end




item17 = context_menu:add_item({label = ">User Settings (Advanced)"})
item17.command = function()

end



if FontAntiAliasing == 1 then
           item36 = context_menu:add_item({label = "Font AntiAliasing (Need ReaimGUI, Restart required)", toggleable = true, selected = true, active = true})
           else
           item36 = context_menu:add_item({label = "Font AntiAliasing (Need ReaimGUI, Restart required)", toggleable = true, selected = false, active = true})
end
item36.command = function()
                     if item36.selected == true then 
                     FontAntiAliasing = 1
                     else
                     FontAntiAliasing = 0
                     end
          r.SetExtState('MK_ReSampler','FontAntiAliasing',FontAntiAliasing,true);
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
          r.SetExtState('MK_ReSampler','MaxFontSizeSt',MaxFontSizeSt,true);
end


item21 = context_menu:add_item({label = "|Reset Controls to User Defaults (Restart required)|<", toggleable = false})
item21.command = function()
Reset_to_def = 1

  --sheckboxes--
     DefSampler_preset_state =  1;
     DefSampler_mode_state =  2;
     DefLoop_ReSampler_state =  1;
     DefVel_Det_Options_state =  1;
     DefBaseOctave_State =  4;
     DefSpeed_state = 4;
     DefDefaultAttTime = 0
     DefDefaultRelTime = 0
     DefReverseBtn_on = 0
     DefNoteOffBtn_on = 1
     DefMonoBtn_on = 0
     DefLoopBtn_on = 0
  --sliders--
      r.SetExtState('MK_ReSampler','DefaultAttTime',DefDefaultAttTime,true);
      r.SetExtState('MK_ReSampler','DefaultRelTime',DefDefaultRelTime,true);

  --sheckboxes--
      r.SetExtState('MK_ReSampler','Speed.norm_val',DefSpeed_state,true);
      r.SetExtState('MK_ReSampler','BaseOctave.norm_val',DefBaseOctave_State,true);
      r.SetExtState('MK_ReSampler','ReverseBtn_on',DefReverseBtn_on,true);
      r.SetExtState('MK_ReSampler','NoteOffBtn_on',DefNoteOffBtn_on,true);
      r.SetExtState('MK_ReSampler','MonoBtn_on',DefMonoBtn_on,true);
      r.SetExtState('MK_ReSampler','LoopBtn_on',DefLoopBtn_on,true);
      r.SetExtState('MK_ReSampler','RS_SamplerMode.norm_val',DefSampler_mode_state,true);
      r.SetExtState('MK_ReSampler','Vel_Det_Options.norm_val',DefVel_Det_Options_state,true);

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
                   r.SetExtState('MK_ReSampler','ThemeSel',ThemeSel,true);
                   gfx.quit()
end


if ThemeSel == 2 then
item24 = context_menu:add_item({label = "Neon", toggleable = true, selected = true})
else
item24 = context_menu:add_item({label = "Neon", toggleable = true, selected = false})
end
item24.command = function()
                   ThemeSel = 2
                   r.SetExtState('MK_ReSampler','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 3 then
item25 = context_menu:add_item({label = "Black", toggleable = true, selected = true})
else
item25 = context_menu:add_item({label = "Black", toggleable = true, selected = false})
end
item25.command = function()
                   ThemeSel = 3
                   r.SetExtState('MK_ReSampler','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 4 then
item24 = context_menu:add_item({label = "Blue Lake", toggleable = true, selected = true})
else
item24 = context_menu:add_item({label = "Blue Lake", toggleable = true, selected = false})
end
item24.command = function()
                   ThemeSel = 4
                   r.SetExtState('MK_ReSampler','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 5 then
item41 = context_menu:add_item({label = "Fall (Dark)", toggleable = true, selected = true})
else
item41 = context_menu:add_item({label = "Fall (Dark)", toggleable = true, selected = false})
end
item41.command = function()
                   ThemeSel = 5
                   r.SetExtState('MK_ReSampler','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 6 then
item27 = context_menu:add_item({label = "Fall", toggleable = true, selected = true})
else
item27 = context_menu:add_item({label = "Fall", toggleable = true, selected = false})
end
item27.command = function()
                   ThemeSel = 6
                   r.SetExtState('MK_ReSampler','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 7 then
item28 = context_menu:add_item({label = "Soft Dark", toggleable = true, selected = true})
else
item28 = context_menu:add_item({label = "Soft Dark", toggleable = true, selected = false})
end
item28.command = function()
                   ThemeSel = 7
                   r.SetExtState('MK_ReSampler','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 8 then
item29 = context_menu:add_item({label = "Graphite", toggleable = true, selected = true})
else
item29 = context_menu:add_item({label = "Graphite", toggleable = true, selected = false})
end
item29.command = function()
                   ThemeSel = 8
                   r.SetExtState('MK_ReSampler','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 9 then
item40 = context_menu:add_item({label = "Spring", toggleable = true, selected = true})
else
item40 = context_menu:add_item({label = "Spring", toggleable = true, selected = false})
end
item40.command = function()
                   ThemeSel = 9
                   r.SetExtState('MK_ReSampler','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 10 then
item30 = context_menu:add_item({label = "Clean", toggleable = true, selected = true})
else
item30 = context_menu:add_item({label = "Clean", toggleable = true, selected = false})
end
item30.command = function()
                   ThemeSel = 10
                   r.SetExtState('MK_ReSampler','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 11 then
item31 = context_menu:add_item({label = "Ink", toggleable = true, selected = true})
else
item31 = context_menu:add_item({label = "Ink", toggleable = true, selected = false})
end
item31.command = function()
                   ThemeSel = 11
                   r.SetExtState('MK_ReSampler','ThemeSel',ThemeSel,true);
                   gfx.quit()
end

if ThemeSel == 12 then
item32 = context_menu:add_item({label = "Classic|<", toggleable = true, selected = true})
else
item32 = context_menu:add_item({label = "Classic|<", toggleable = true, selected = false})
end
item32.command = function()
                   ThemeSel = 12
                   r.SetExtState('MK_ReSampler','ThemeSel',ThemeSel,true);
                   gfx.quit()
end


item34 = context_menu:add_item({label = "|Reset Window Size", toggleable = false})
item34.command = function()
store_window()
           xpos = tonumber(r.GetExtState("MK_ReSampler", "window_x")) or 400
           ypos = tonumber(r.GetExtState("MK_ReSampler", "window_y")) or 320
    local Wnd_Dock, Wnd_X,Wnd_Y = dock_pos, xpos, ypos
    Wnd_W, Wnd_H = 1044, 390 -- global values(used for define zoom level)
    -- Re-Init window ------
    gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )
    gfx.update()

end


----------------------------end of context menu--------------------------------

 mainloop_settings()


function ClearExState()
              if Rec_on == 1 then -- when exit while recording
                OnRecordStop()
              end
   DeleteTrackByName()
   r.CF_Preview_StopAll()
   r.DeleteExtState('MK_ReSampler_', 'ItemToSample', 0)
   r.DeleteExtState('MK_ReSampler_', 'TrackForSlice', 0)
   r.SetExtState('MK_ReSampler_', 'GetItemState', 'ItemNotLoaded', 0)
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

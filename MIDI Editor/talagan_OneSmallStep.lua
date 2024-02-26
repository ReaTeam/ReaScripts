--[[
@description One Small Step : Alternative Step Input
@version 0.9.4
@author Ben 'Talagan' Babut
@license MIT
@metapackage
@provides
  [main=main,midi_editor] .
  [main=main,midi_editor] talagan_OneSmallStep Change input mode.lua > talagan_OneSmallStep Change input mode - KeyboardPress.lua
  [main=main,midi_editor] talagan_OneSmallStep Change input mode.lua > talagan_OneSmallStep Change input mode - KeyboardRelease.lua
  [main=main,midi_editor] talagan_OneSmallStep Change input mode.lua > talagan_OneSmallStep Change input mode - Punch.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len param source.lua > talagan_OneSmallStep Change note len param source - OSS.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len param source.lua > talagan_OneSmallStep Change note len param source - ItemConf.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len param source.lua > talagan_OneSmallStep Change note len param source - ProjectGrid.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len modifier.lua > talagan_OneSmallStep Change note len modifier - Straight.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len modifier.lua > talagan_OneSmallStep Change note len modifier - Triplet.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len modifier.lua > talagan_OneSmallStep Change note len modifier - Dotted.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len modifier.lua > talagan_OneSmallStep Change note len modifier - Modified.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len modifier.lua > talagan_OneSmallStep Change note len modifier - Tuplet.lua
  [main=main,midi_editor] talagan_OneSmallStep Increase note len.lua
  [main=main,midi_editor] talagan_OneSmallStep Decrease note len.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len.lua > talagan_OneSmallStep Change note len - 1_64.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len.lua > talagan_OneSmallStep Change note len - 1_32.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len.lua > talagan_OneSmallStep Change note len - 1_16.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len.lua > talagan_OneSmallStep Change note len - 1_8.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len.lua > talagan_OneSmallStep Change note len - 1_4.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len.lua > talagan_OneSmallStep Change note len - 1_2.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len.lua > talagan_OneSmallStep Change note len - 1.lua
  [main=main,midi_editor] talagan_OneSmallStep Cleanup helper JSFXs.lua
  [main=main,midi_editor] talagan_OneSmallStep Commit back.lua
  [main=main,midi_editor] talagan_OneSmallStep Commit.lua
  [main=main,midi_editor] talagan_OneSmallStep Set or remove playback marker.lua
  [main=main,midi_editor] talagan_OneSmallStep Playback.lua
  [nomain] talagan_OneSmallStep/classes/*.lua
  [nomain] talagan_OneSmallStep/images/*.lua
  [nomain] talagan_OneSmallStep/talagan_OneSmallStep Engine lib.lua
  [nomain] talagan_OneSmallStep/talagan_OneSmallStep Helper lib.lua
  [effect] talagan_OneSmallStep/One Small Step Helper.jsfx
  [data] talagan_OneSmallStep/toolbar_icons/toolbar_one_small_step.png > toolbar_icons/toolbar_one_small_step.png
  [data] talagan_OneSmallStep/toolbar_icons/toolbar_one_small_step_cleanup.png > toolbar_icons/toolbar_one_small_step_cleanup.png
@screenshot
  https://stash.reaper.fm/48269/oss_094.png
@changelog
  - [Feature] Added option to allow erasing note endings that do not match cursor when steping back
  - [Feature] Keypress Mode : Added Sustain Inertia to detect held keys when pressing other keys
  - [Feature] Added options to tweak Key Release / Key Press reaction times
  - [Feature] Added option to choose if input notes are selected or not
  - [Feature] Added option to automatically cleanup JSFXs on closing (thanks @stevie !)
  - [Feature] Added an option to prevent notes from being inserted if the sustain pedal modifier key is pressed (this blocks insertion, useful in KP mode when starting an erase operation)
  - [Bug Fix] Project boundaries were not updated if the edited item was the last one and was extended (thanks @daodan !)
  - [Bug Fix] Reduced intensive CPU usage when OSS is runing due to unuseful calls to Undo_Begin/End
@about
  # Purpose

    One Small Step is a tool for performing MIDI note step input in REAPER. It is an alternative to the standard step input, and it tries to address some issues with certain workflows, as well as to propose different input modes, like validating held notes with the sustain pedal or a REAPER action (obviously linked to a custom keyboard shortcut). It will also work outside of the MIDI editor (in the arrange view), as long as you've selected a MIDI item and set the cursor at the right position ; this offers additional comfort and can speed up your workflow.

  # On MIDI issues with Reaper's standard step input flow

    REAPER's step input tool uses the MIDI control path. While it has some advantages, one of the main issue you may have encountered is that when step inputing, MIDI events will not go through the input FX chain of the track you're working on. If you are performing MIDI processing there (like channel routing, note transposition, note dropping, velocity processing, etc), everything will be ignored because REAPER does not use the result of the FX input chain, but the raw MIDI note events. This leads to strange behaviours, e.g. the MIDI editor piano roll not being in coherency with the input notes (so what you see on the piano roll is not what you'll get), but worse, you will not get the same result as if you were recording.

    To address this, One Small Step installs a JSFX at the end of the track input chain to watch for note events AFTER they've been processed by the FX input chain, and performs the patching of the MIDI item by itself.

  # Reaper forum thread

    The official discussion thread is located here : https://forum.cockos.com/showthread.php?t=288076

  # Install Notes

    This script also needs the JS_ReaScriptAPI api by Julian Sader and the ReaImGui library by Christian Fillion to work. Please install them alongside (OSS will remind you to do so anyway). A restart of Reaper is needed after install.

  # How to use

    Launch the action called 'OneSmallStep' (other actions are provided but we'll get on this later). You should now see OSS's main dialog - One Small Step is active (it is active as long as this dialog is visible). At the top of it, the name of the target MIDI track / item / take will be displayed if there's one eligible that matches your current selection / cursor position.

    It is important to note that the track should be armed for record (OSS will give you an indication if you forgot to arm the recording) and the MIDI source should be chosen (exactly like you would when recording). If everyhing's ready, a red circle will glow, meaning that in this configuration, OneSmallStep is able to do its job (listen to MIDI events, and step input/patch the current MIDI item).

  ## Input modes

    You can then select your input mode between **Keyboard Press** Mode, **Punch** Mode, and **Keyboard Release** Mode.

    For each Input Mode, two triggers may be used to validate notes and rests : the Commit action, and the Commit Back action, to which you may consider giving shortcuts. The effect of each action will be different if the notes were already held or not (creation, extension, shortening, removal ...). Those two actions may also be triggered by the Sustain Pedal (for the Commit) or a modifier key (shift, ctrl, etc) + Sustain Pedal (for the Commit Back action).

  ### Keyboard Press Mode (Fast Mode)

    Notes are added on keyboard key press events.

    Suitable for inputing notes at a high pace. It is not error tolerant (you get what you play), but will only aggregate chords if keys are pressed simultaneously.

  ### Punch Mode

    Notes are NOT added on keyboard key press/release events. Only the sustain pedal or commit action add notes.

    Suitable for validating everything by ear before input. Useful when testing chords or melodic ideas.

  ### Keyboard Release Mode (Grope Mode)

    Notes are added on keyboard key release events.

    Suitable for inputing notes at a low pace, correcting things by ear, especially for chords. This mode is error tolerant, but tends to aggregate and skip notes easily when playing fast.

    This is pretty much the same as Reaper's default step input mode.

  ### Effect of the sustain pedal / actions

    For all modes, the sustain pedal and the commit action :

    - Insert held notes
    - Extend already committed and still held notes
    - Insert rests if no notes are held

    The modifier key + the sustain pedal and the commit back action :

    - Erase back held notes if they match the cursor
    - Step back if no notes are held

  ## Note length parameter source

    Three sources for determining the input note length are proposed.

  ### One Small Step

    Note length parameters are global and configured in OSS, with the buttons aside.

  ### Project Grid

    One Small Step will use the grid parameters of the project to determine the length of the notes to insert

  ### MIDI Item's conf

    One Small Step will use the note parameters specific to the edited MIDI item to determine the length of the notes to insert. Those parameters are located at the bottom of the MIDI Editor (the combo boxes right of the 'Notes' label).

  ## Step input playback

    One Small Step provides a convenient playback widget, which is a way to ear what you've just written, without losing the position of the edit cursor, so that you can work faster. The playback button will replay the last N measures (N is settable, and the result is rounded to the start of the matching measure). You can chose Mk instead of a number of measures, and instead, the start point will be the 'OSS Playback' marker (if it is set, else, only the current measure will be played as when N=0). You can set/remove it using the marker button on the right.

    Both the "set/move/remove marker" and "playback" actions are available independently so you can also use them without the UI if you need them in other workflows.

  ## Other Reaper actions

    To speed up your flow, multiple actions are provided to quickly change OSS parameters, so that you can assign shortcuts to them. Those are :

    - **Change input mode**
    - **Change note len**
    - **Decrease/Increase note len**
    - **Change note len modifier**
    - **Change note len param source**
    - **Cleanup helper JSFXs**

    actions, whose names should be self explanatory. The **Cleanup helper JSFXs** is here for cleaniness, to remove the Helper JSFXs that are installed automatically on the input FX chain of your tracks when OSS is running (it could have been done automatically when closing the tool, but it adds an entry in the undo stack, which is annoying, and I don't have a solution for this yet).

  # Calling One Small Step from a Reaper toolbar button

    The most logical way to summon OSS is to create a togglable toolbar button in Reaper by assigning it the 'talagan_OneSmallStep.lua' action. You should be good to go : OSS will handle the color of the button dependending on its state, and you can close OSS either by clicking on the cross in the top right corner of the window, or by re-clicking the toolbar button.

  # Toolbar icons

    Two toolbar icons are provided with OSS, one icon for launching OSS ('toolbar_one_small_step'), and one for launching the cleanup script ('toolbar_one_small_step_cleanup').

  # Credits

    This tool takes a lot of inspiration in tenfour's "tenfour-step" scripts. Epic hail to tenfour for opening the way !

    Thanks to @cfillion for the precious pieces of advice when reviewing this source !

    A lot of thanks to all donators, and forum members that help this tool to get better ! @stevie, @hipox, @MartinTL, @henu, @Thonex, @smandrap, @SoaSchas, @daodan, @inthevoid, @dahya, @User41, @Spookye, @R.Cato

--]]

--------------------------------

--[[
# Ruby script to convert from png > lua to load binary img for ReaImGui

def png_to_lua(fname)
  buf = File.open(fname,"rb").read.unpack("C*").map{ |c| "\\x%02X" % c }.each_slice(40).map{ |s| s.join }.join("\\z\n")
  buf = "return \"\\z\n" + buf + "\"\n;\n"
  outname = File.basename(fname,".png") + ".lua"
  File.open(outname, "wb") { |f| f << buf }
end

png_to_lua("triplet.png")

--]]

-- Tell the script to be terminated if relaunched.
-- Check the existence of the function for sanity (added in v 7.03)
if reaper.set_action_options ~= nil then
  reaper.set_action_options(1);
end

-------------------------------
-- Path and modules

package.path      = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path
local engine_lib  = require "talagan_OneSmallStep/talagan_OneSmallStep Engine lib";

-------------------------------
-- Check dependencies

if not reaper.APIExists("JS_ReaScriptAPI_Version") then
  local answer = reaper.MB( "You have to install JS_ReaScriptAPI for this script to work. Right-click the entry in the next window and choose to install.", "JS_ReaScriptAPI not installed", 0 )
  reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  return
end

if not reaper.APIExists("ImGui_CreateContext") then
  local answer = reaper.MB( "You have to install ReaImGui for this script to work. Right-click the entry in the next window and choose to install.", "ReaImGUI not installed", 0 )
  reaper.ReaPack_BrowsePackages( "ReaImGui:" )
  return
end

-------------------------------
-- ImGui Backward compatibility

dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.8.7')

-------------------------------

local images = {};

function getImage(image_name)
  if not reaper.ImGui_ValidatePtr(images[image_name], 'ImGui_Image*') then
    local bin = require("./talagan_OneSmallStep/images/" .. image_name);
    images[image_name] = reaper.ImGui_CreateImageFromMem(bin);
  end
  return images[image_name];
end

-------------------------------

local ctx                   = reaper.ImGui_CreateContext('One Small Step');

-------------------------------
-- Other global variables

local focustimer        = nil;
local showsettings      = nil;

------------------------------

function SL()
  reaper.ImGui_SameLine(ctx);
end

function TT(str)
  if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal()) then
    reaper.ImGui_SetTooltip(ctx, str)
  end
end

function to_frac(num)
   local W = math.floor(num)
   local F = num - W
   local pn, n, N = 0, 1
   local pd, d, D = 1, 0
   local x, err, q, Q
   repeat
      x = x and 1 / (x - q) or F
      q, Q = math.floor(x), math.floor(x + 0.5)
      pn, n, N = n, q*n + pn, Q*n + pn
      pd, d, D = d, q*d + pd, Q*d + pd
      err = F - N/D
   until math.abs(err) < 1e-15
   return N + D*W, D, err
end

-- Since reaper gives us the note length as a float
-- Use a lookup after back conversion to fraction
-- To display the current sig
local KnownNoteLengthSignatures = {
  ['4/1']   = { icon = "note_1",    triplet = false, modif_label = "x 4" },
  ['8/3']   = { icon = "note_1",    triplet = true,  modif_label = "x 4" },
  ['6/1']   = { icon = "note_1",    triplet = false, modif_label = ". x 4" },
  ['2/1']   = { icon = "note_1",    triplet = false, modif_label = "x 2" },
  ['4/3']   = { icon = "note_1",    triplet = true,  modif_label = "x 2" },
  ['3/1']   = { icon = "note_1",    triplet = false, modif_label = ". x 2" },
  ['1/1']   = { icon = "note_1",    triplet = false, modif_label = "" },
  ['2/3']   = { icon = "note_1",    triplet = true,  modif_label = "" },
  ['3/2']   = { icon = "note_1",    triplet = false, modif_label = ". " },
  ['1/2']   = { icon = "note_1_2",  triplet = false, modif_label = "" },
  ['1/3']   = { icon = "note_1_2",  triplet = true,  modif_label = "" },
  ['3/4']   = { icon = "note_1_2",  triplet = false, modif_label = "." },
  ['1/4']   = { icon = "note_1_4",  triplet = false, modif_label = "" },
  ['1/6']   = { icon = "note_1_4",  triplet = true,  modif_label = "" },
  ['3/8']   = { icon = "note_1_4",  triplet = false, modif_label = "." },
  ['1/8']   = { icon = "note_1_8",  triplet = false, modif_label = "" },
  ['1/12']  = { icon = "note_1_8",  triplet = true,  modif_label = "" },
  ['3/16']  = { icon = "note_1_8",  triplet = false, modif_label = "." },
  ['1/16']  = { icon = "note_1_16", triplet = false, modif_label = "" },
  ['1/24']  = { icon = "note_1_16", triplet = true,  modif_label = "" },
  ['3/32']  = { icon = "note_1_16", triplet = false, modif_label = "." },
  ['1/32']  = { icon = "note_1_32", triplet = false, modif_label = "" },
  ['1/48']  = { icon = "note_1_32", triplet = true,  modif_label = "" },
  ['3/64']  = { icon = "note_1_32", triplet = false, modif_label = "." },
  ['1/64']  = { icon = "note_1_64", triplet = false, modif_label = "" },
  ['1/96']  = { icon = "note_1_64", triplet = true,  modif_label = "" },
  ['3/128'] = { icon = "note_1_64", triplet = false, modif_label = "." },
  ['1/128'] = { icon = "note_1",    triplet = false, modif_label = "x 1/128" },
  ['1/192'] = { icon = "note_1",    triplet = true,  modif_label = "x 1/128" },
  ['3/256'] = { icon = "note_1",    triplet = false, modif_label = ". x 1/128" },
}

function ImGui_QNToLabel(ctx, qn)

  local n,d,e = to_frac(qn);

  -- Do a reverse conversion to fraction
  -- And then lookup for what we know

  local sig = n .. "/" .. d;
  local det = KnownNoteLengthSignatures[sig];
  if det then
    ImGui_NoteLenImg(ctx, det.icon, det.triplet, det.modif_label);
  else
    ImGui_NoteLenImg(ctx, "note_1", false, "x "..sig);
  end
end


-- Indicator for the current project grid note len
function ImGui_ProjectGridLabel(ctx)
  local _, qn, swing, _ = reaper.GetSetProjectGrid(0, false);

  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),0, 0);
  if swing == 3 then
    reaper.ImGui_TextColored(ctx, 0xC0C0C0FF, "Measure");
  else
    ImGui_QNToLabel(ctx, qn);
  end
  reaper.ImGui_PopStyleVar(ctx,1);
end

-- Indicator for the current MIDI item note len
function ImGui_ItemGridLabel(ctx,take)
  if not take then
    return
  end

  local grid_len, swing, note_len = reaper.MIDI_GetGrid(take);

  if note_len == 0 then
    note_len = grid_len;
  end

  local qn = note_len/4;

  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),0, 0);
  ImGui_QNToLabel(ctx, qn);
  reaper.ImGui_PopStyleVar(ctx,1);
end

function ButtonGroupImageButton(image_name, is_on, callback, corner, is_green)

  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 0, 0);

  if is_green then
    PushGreenButtonColors(is_on);
  else
    PushBlueButtonColors(is_on);
  end

  if corner == nil then
    corner = 0.1
  end

  if reaper.ImGui_ImageButton(ctx, image_name, getImage(image_name), 20, 20, corner, corner, 1 - corner, 1 - corner, 0, 0xFFFFFFFF) then
    callback();
  end

  if is_green then
    PopGreenButtonColors();
  else
    PopBlueButtonColors();
  end

  reaper.ImGui_PopStyleVar(ctx,1);
end

function PushBlueButtonColors(is_on)
  local on_col  = 0x5080FFFF;
  local off_col = 0x203040FF;
  local hov_col = 0x60A0FFFF;
  local act_col = 0x60A0FFFF;

  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), is_on and on_col or off_col);
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),hov_col );
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), act_col );
end

function PopBlueButtonColors()
  reaper.ImGui_PopStyleColor(ctx,3);
end

function PushGreenButtonColors(is_on)

  local on_col  = 0x008000FF;
  local off_col = 0x006000FF;
  local hov_col = 0x00C000FF;
  local act_col = 0x00C000FF;

  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), is_on and on_col or off_col);
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),hov_col );
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), act_col );
end

function PopGreenButtonColors()
  reaper.ImGui_PopStyleColor(ctx,3);
end

function ButtonGroupTextButton(text, is_on, callback)

  if reaper.ImGui_Button(ctx, text) then
    callback();
  end;

end

function ImGui_NoteLenImg(context, image_name, triplet, divider)
  reaper.ImGui_SetCursorPosY(ctx,reaper.ImGui_GetCursorPosY(ctx));
  reaper.ImGui_Image(ctx, getImage(image_name), 20, 20, 0.1, 0.1, 0.9, 0.9);

  if triplet then
    SL();
    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) - 20);
    reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) - 10);
    ImGui_NoteLenImg(ctx, "note_triplet");
  end

  if divider then
    SL();
    reaper.ImGui_SetCursorPosY(ctx,reaper.ImGui_GetCursorPosY(ctx) + 3);
    reaper.ImGui_TextColored(ctx, 0xC0C0C0FF, divider);
  end
end

function ImGui_VerticalSpacer(context, height)
  reaper.ImGui_PushStyleVar(context, reaper.ImGui_StyleVar_ItemSpacing(),0,0)
  reaper.ImGui_Dummy(context, 10, height);
  reaper.ImGui_PopStyleVar(context,1);
end

function MiniBarSeparator(dst)
  dst = ((dst == nil) and 6 or dst);

  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),0,0);
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),0,0);
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemInnerSpacing(),0,0)
  reaper.ImGui_Dummy(ctx, dst, 0);
  reaper.ImGui_PopStyleVar(ctx,3);

end

function RecordBadge(track)
  local recarmed      = reaper.GetMediaTrackInfo_Value(track, "I_RECARM");
  local playState     = reaper.GetPlayState();

  reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx)+1);

  if (recarmed == 1) and not (engine_lib.getInputMode() == engine_lib.InputMode.None) and playState == 0 then
    local alpha = math.sin(reaper.time_precise()*4);
    local r1    = 200+math.floor(55 * alpha);
    local r2    = 120+math.floor(55 * alpha);

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),      (r1 << 24) | 0x000000FF);
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),        (r2 << 24) | 0x000000FF);
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(),  (r2 << 24) | 0x000000FF);
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), (r2 << 24) | 0x000000FF);
  else
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(),      0xCCCCCCFF);
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),        0x808080FF);
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(),  0x808080FF);
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), 0x808080FF);
  end

  reaper.ImGui_RadioButton(ctx, '##', true);
  reaper.ImGui_PopStyleColor(ctx, 4);
end

function RecordIssues(track)
  local recarmed      = reaper.GetMediaTrackInfo_Value(track, "I_RECARM");
  local playState     = reaper.GetPlayState();

  reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx));
  if not (recarmed == 1) then
    reaper.ImGui_TextColored(ctx, 0x808080FF, '[Track not armed]');
  elseif engine_lib.getInputMode() == engine_lib.InputMode.None then
    reaper.ImGui_TextColored(ctx, 0x808080FF, '[Input Mode is OFF]');
  elseif not (playState == 0) then
    reaper.ImGui_TextColored(ctx, 0x808080FF, '[Reaper not ready]');
  else
    reaper.ImGui_TextColored(ctx, 0x808080FF, '');
  end
end

-- Current take info label and indicators
function TakeInfo(take)
  local track         = reaper.GetMediaItemTake_Track(take);
  local _, track_name = reaper.GetTrackName(track);
  local take_name     = reaper.GetTakeName(take);

  reaper.ImGui_TextColored(ctx, 0xA0A0FFFF, track_name .. " / " .. take_name);

  -- Glowing indicator
  SL();
  RecordBadge(track);
  SL();
  RecordIssues(track);
end

-- Current track info label and indicators (if no take)
function TrackInfo(track)
  local _, track_name = reaper.GetTrackName(track);

  reaper.ImGui_TextColored(ctx, 0xA0A0FFFF, track_name .. " /");
  SL();
  reaper.ImGui_TextColored(ctx, 0xFFA0A0FF, "No Item");

  SL();
  RecordBadge(track);
  SL();
  RecordIssues(track);
end



-- MINIBAR : Input Mode
function InputModeMiniBar()
  local mode      = engine_lib.getInputMode();
  local modifkey  = engine_lib.getSustainPedalModifierKey().name or "";

  local pedalmanual = "\z
    The sustain pedal and the commit action :\n\n\z
    \32 - Insert held notes\n\z
    \32 - Extend already committed and still held notes\n\z
    \32 - Insert rests if no notes are held\n\z
    \n\z
    " .. modifkey .. " + the sustain pedal and the commit back action :\n\n\z
    \32 - Erase back held notes if they match the cursor\n\z
    \32 - Step back if no notes are held";

  ButtonGroupImageButton('input_mode_keyboard_press', mode == engine_lib.InputMode.KeyboardPress, function()
      engine_lib.setInputMode(engine_lib.InputMode.KeyboardPress);
    end, 0);

  TT("Input Mode : Keyboard Press (Fast mode)\n\z
      \n\z
      Notes are added on keyboard key press events.\n\z
      \n\z
      Suitable for inputing notes at a high pace. It is not error\n\z
      tolerant (you get what you play), but will only aggregate \n\z
      chords if keys are pressed simultaneously.\n\z
      \n\z" .. pedalmanual);
  SL();

  ButtonGroupImageButton('input_mode_pedal', mode == engine_lib.InputMode.Punch, function()
      engine_lib.setInputMode(engine_lib.InputMode.Punch);
    end,0);

  TT("Input Mode : Punch (Check mode)\n\z
      \n\z
      Notes are NOT added on keyboard key press/release events.\n\z
      Only the sustain pedal or commit action add notes.\n\z
      \n\z
      Suitable for validating everything by ear before input.\n\z
      Useful when testing chords or melodic ideas.\n\z
      \n\z" .. pedalmanual);
  SL();

  ButtonGroupImageButton('input_mode_keyboard_release', mode == engine_lib.InputMode.KeyboardRelease, function()
      engine_lib.setInputMode(engine_lib.InputMode.KeyboardRelease);
    end, 0);

  TT("Input Mode : Keyboard Release (Grope mode)\n\z
      \n\z
      Notes are added on keyboard key release events.\n\z
      \n\z
      Suitable for inputing notes at a low pace, correcting\n\z
      things by ear, especially for chords. This mode is error\n\z
      tolerant, but tends to aggregate and skip notes easily\n\z
      when playing fast.\n\z
      \n\z" .. pedalmanual);
  SL();

end

-- MINIBAR : Conf source
function ConfSourceMiniBar()
  local nlm = engine_lib.getNoteLenParamSource();

  ButtonGroupImageButton('note_len_mode_oss', nlm == engine_lib.NoteLenParamSource.OSS, function() engine_lib.setNoteLenParamSource(engine_lib.NoteLenParamSource.OSS) end, 0);
  TT('Note Length conf : One Small Step\n\nUse the params aside.');
  SL();
  ButtonGroupImageButton('note_len_mode_pgrid', nlm == engine_lib.NoteLenParamSource.ProjectGrid, function() engine_lib.setNoteLenParamSource(engine_lib.NoteLenParamSource.ProjectGrid) end);
  TT( "Note Length conf : Project\n\nUse the project's grid conf.");
  SL();
  ButtonGroupImageButton('note_len_mode_igrid', nlm == engine_lib.NoteLenParamSource.ItemConf, function() engine_lib.setNoteLenParamSource(engine_lib.NoteLenParamSource.ItemConf) end);
  TT( "Note Length conf : MIDI Item\n\nUse the MIDI item's own conf.\n\n('Notes' at the bottom of the MIDI editor)");

end

-- MINIBAR : Note length
function NoteLenMiniBar()
  local nl = engine_lib.getNoteLen();
  for i,v in ipairs(engine_lib.NoteLenDefs) do
    SL();
    ButtonGroupImageButton('note_'.. v.id , nl == v.id,
      function()
        engine_lib.setNoteLen(v.id)
      end
    );
  end
end

-- MINIBAR : Note length modifier
function NoteLenModifierMiniBar()

  local nmod = engine_lib.getNoteLenModifier();

  ButtonGroupImageButton('note_dotted', nmod == engine_lib.NoteLenModifier.Dotted, function()
      if nmod == engine_lib.NoteLenModifier.Dotted then
        engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Straight);
      else
        engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Dotted);
      end
    end
  );
  TT("Dotted");
  SL();
  ButtonGroupImageButton('note_triplet', nmod == engine_lib.NoteLenModifier.Triplet, function()
      if nmod == engine_lib.NoteLenModifier.Triplet then
        engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Straight);
      else
        engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Triplet);
      end
    end
  );
  TT("Triplet");
  SL();
  ButtonGroupImageButton('note_modified', nmod == engine_lib.NoteLenModifier.Modified, function()
      if nmod == engine_lib.NoteLenModifier.Modified then
        engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Straight);
      else
        engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Modified);
      end
    end
  );
  TT("Modified length");
  SL();
  ButtonGroupImageButton('note_tuplet', nmod == engine_lib.NoteLenModifier.Tuplet, function()
      if nmod == engine_lib.NoteLenModifier.Tuplet then
        engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Straight);
      else
        engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Tuplet);
      end
    end
  );
  TT("N-tuplet");
end

-- Sub-params : N-tuplet
function NTupletComboBox()
  local combo_items = { '4', '5', '6', '7', '8', '9', '10', '11', '12' }

  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 5, 4);
  reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx));
  reaper.ImGui_PushID(ctx, "nlet_combo");

  local tuplet = ''..engine_lib.getTupletDivision();

  reaper.ImGui_SetNextItemWidth(ctx,50);
  if reaper.ImGui_BeginCombo(ctx, '', tuplet) then
    for i,v in ipairs(combo_items) do
      local is_selected = (tuplet == v);
      if reaper.ImGui_Selectable(ctx, combo_items[i], is_selected) then
        engine_lib.setTupletDivision(tonumber(v));
      end
      if is_selected then
        reaper.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    reaper.ImGui_EndCombo(ctx)
  end
  reaper.ImGui_PopStyleVar(ctx,1);
  reaper.ImGui_PopID(ctx);
end

-- Sub-params : Augmented/Diminished Sign/Factor
function NoteADSignComboBox()

  local val         = engine_lib.getNoteADSign();
  local combo_items = { '+', '-' };

  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 5, 4);
  reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx));
  reaper.ImGui_PushID(ctx, "augmented_diminshed_sign");

  reaper.ImGui_SetNextItemWidth(ctx, 40);
  if reaper.ImGui_BeginCombo(ctx, '', val) then
    for i, label in ipairs(combo_items) do

      local is_selected = (val == label);
      if reaper.ImGui_Selectable(ctx, label, is_selected) then
        engine_lib.setNoteADSign(label);
      end
      if is_selected then
        reaper.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    reaper.ImGui_EndCombo(ctx)
  end
  reaper.ImGui_PopID(ctx);
  reaper.ImGui_PopStyleVar(ctx,1);
end

function NoteADFactorComboBox()

  local val = engine_lib.getNoteADFactor();

  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 5, 4);
  reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx));
  reaper.ImGui_PushID(ctx, "augmented_diminished_combo");

  reaper.ImGui_SetNextItemWidth(ctx, 55);
  if reaper.ImGui_BeginCombo(ctx, '', val) then
    for i, v in ipairs(engine_lib.AugmentedDiminishedDefs) do

      if reaper.ImGui_Selectable(ctx, v.id, (val == v.id)) then
        engine_lib.setNoteADFactor(v.id);
      end
      if is_selected then
        reaper.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    reaper.ImGui_EndCombo(ctx)
  end
  reaper.ImGui_PopID(ctx);
  reaper.ImGui_PopStyleVar(ctx,1);
end


-- Note AD
function AugmentedDiminishedMiniBars()
  NoteADSignComboBox();
  SL();
  MiniBarSeparator();
  SL();
  NoteADFactorComboBox();
end

function PlayBackMeasureCountComboBox()

  reaper.ImGui_PushID(ctx, "playback_measure_count");
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),        0x006000FF);
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), 0x00A000FF);
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(),  0x00C000FF);
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(),         0x008000FF);
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(),  0x008000FF);
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(),        0x006000FF);
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(),         0x00C000FF);
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(),  0x00C000FF);

  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 5, 4);
  local curm = engine_lib.getPlaybackMeasureCount();

  local function label(mnum)
    return ((mnum == -1) and "Mk" or mnum);
  end

  reaper.ImGui_SetNextItemWidth(ctx,45);
  if reaper.ImGui_BeginCombo(ctx, '', label(curm)) then
    for i=-1,16,1 do
      local is_selected = (curm == i);

      if reaper.ImGui_Selectable(ctx, label(i), is_selected) then
        engine_lib.setPlaybackMeasureCount(i);
      end
      if is_selected then
        reaper.ImGui_SetItemDefaultFocus(ctx)
      end
      if i == -1 then
        TT("Use OSS marker as start point for playback");
      end
    end
    reaper.ImGui_EndCombo(ctx)
  end
  reaper.ImGui_PopStyleVar(ctx,1);
  reaper.ImGui_PopStyleColor(ctx,8);
  reaper.ImGui_PopID(ctx);

  TT("Number of measures to rewind, rounded at measure start.\n\n\z
      'Mk' stands for Marker mode, the playback will start at the\n\z
      'OSS Playback' marker instead. you can set/move/remove it\n\z
      it with the button on the right.\z
    ");

end

function PlaybackButton()
  reaper.ImGui_PushID(ctx, "playback");
  ButtonGroupImageButton("playback", false, function()
      local id = reaper.NamedCommandLookup("_RSb38bb99e06254b3b6e60fc7755e7af02d54341b4");
      reaper.Main_OnCommand(id, 0);
    end, 0, true
  );
  reaper.ImGui_PopID(ctx);
  TT("Playback");
end

function PlaybackSetMarkerButton()
  reaper.ImGui_PushID(ctx, "playback_marker");
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 8, 4);
  ButtonGroupImageButton("marker", false, function()
      engine_lib.setPlaybackMarkerAtCurrentPos();
    end, 0, true, false
  );
  reaper.ImGui_PopStyleVar(ctx,1);
  reaper.ImGui_PopID(ctx);
  TT("Sets/Moves/Removes the playback marker");
end

function PlaybackWidget()

  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),       2, 4);
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemInnerSpacing(),  0, 0);

  PlaybackButton();
  SL();
  PlayBackMeasureCountComboBox();
  SL();
  PlaybackSetMarkerButton();

  reaper.ImGui_PopStyleVar(ctx,2);
end

function TargetLine(take)
  PlaybackWidget();
  SL();
  MiniBarSeparator(0);
  SL();

  if not take then
    if engine_lib.getSetting("AllowCreateItem") then
      local track = engine_lib.TrackForEditionIfNoItemFound();
      if track then
        TrackInfo(track);
      else
        reaper.ImGui_TextColored(ctx, 0xA0A0A0FF, "No target item or track.");
      end
    else
      reaper.ImGui_TextColored(ctx, 0xA0A0A0FF, "No target item. Please select one.");
    end
    ImGui_VerticalSpacer(ctx,0);
  else
    TakeInfo(take);
  end
end

-- MINIBAR : Settings
function SettingsMiniBar()
  ButtonGroupImageButton('settings', false,
    function()
      showsettings = not showsettings;
    end,
  0);
end

function PlaybackMarkerSettingComboBox()

  local combo_items = { 'Hide/Restore', 'Keep visible', 'Remove' }
  local curval      = engine_lib.getSetting("PlaybackMarkerPolicyWhenClosed");

  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 5, 4);
  reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx));
  reaper.ImGui_PushID(ctx, "playback_marker_policy");

  reaper.ImGui_SetNextItemWidth(ctx, 120);
  if reaper.ImGui_BeginCombo(ctx, '', curval) then
    for i,v in ipairs(combo_items) do
      local is_selected = (curval == v);
      if reaper.ImGui_Selectable(ctx, combo_items[i], is_selected) then
        engine_lib.setSetting("PlaybackMarkerPolicyWhenClosed", v);
      end
      if is_selected then
        reaper.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    reaper.ImGui_EndCombo(ctx)
  end
  reaper.ImGui_PopStyleVar(ctx,1);
  reaper.ImGui_PopID(ctx);

  SL();

  reaper.ImGui_Text(ctx, "playback marker when closing");
end

function StepBackSustainPedalModifierKeyComboBox()
  local combo_items = engine_lib.ModifierKeys;
  local setting     = "StepBackSustainPedalModifierKey";
  local modkey      = engine_lib.getSustainPedalModifierKey() or {};
  local label       = modkey.name or "";
  local curval      = modkey.vkey or 0;

  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 5, 4);
  reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx));
  reaper.ImGui_PushID(ctx, setting);

  reaper.ImGui_SetNextItemWidth(ctx, 70);
  if reaper.ImGui_BeginCombo(ctx, '', label) then
    for i,v in ipairs(combo_items) do
      local is_selected = (curval == v.vkey);
      if reaper.ImGui_Selectable(ctx, v.name, is_selected) then
        engine_lib.setSetting("StepBackSustainPedalModifierKey", v.vkey);
      end
      if is_selected then
        reaper.ImGui_SetItemDefaultFocus(ctx)
      end
    end
    reaper.ImGui_EndCombo(ctx)
  end
  reaper.ImGui_PopStyleVar(ctx,1);
  reaper.ImGui_PopID(ctx);

  SL();

  reaper.ImGui_Text(ctx, "+ sustain pedal : performs step back action");
end

function SettingsPanel()
  if reaper.ImGui_BeginTabBar(ctx, 'settings_tab_bar', reaper.ImGui_TabBarFlags_None()) then
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Tab(),        0x00000000);
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TabHovered(), 0x00000000);
    if reaper.ImGui_TabItemButton(ctx, 'Settings', reaper.ImGui_TabItemFlags_Leading() | reaper.ImGui_TabItemFlags_NoTooltip()) then
    end
    reaper.ImGui_PopStyleColor(ctx, 2);

    if reaper.ImGui_BeginTabItem(ctx, 'General') then

      ImGui_VerticalSpacer(ctx,5);

      local curval = nil;

      curval = engine_lib.getSetting("AllowTargetingFocusedMidiEditors");
      if reaper.ImGui_Checkbox(ctx, "Allow targeting items open in focused MIDI Editors", curval) then
        engine_lib.setSetting("AllowTargetingFocusedMidiEditors", not curval);
      end

      curval = engine_lib.getSetting("AllowTargetingNonSelectedItemsUnderCursor");
      if reaper.ImGui_Checkbox(ctx, "Allow targeting items on selected tracks if no item is selected", curval) then
        engine_lib.setSetting("AllowTargetingNonSelectedItemsUnderCursor", not curval);
      end

      curval = engine_lib.getSetting("AllowCreateItem");
      if reaper.ImGui_Checkbox(ctx, "Allow creating new items if needed", curval) then
        engine_lib.setSetting("AllowCreateItem", not curval);
      end

      curval = engine_lib.getSetting("SelectInputNotes");
      if reaper.ImGui_Checkbox(ctx, "Select input notes", curval) then
        engine_lib.setSetting("SelectInputNotes", not curval);
      end

      curval = engine_lib.getSetting("CleanupJsfxAtClosing");
      if reaper.ImGui_Checkbox(ctx, "Cleanup helper JSFXs when closing OSS", curval) then
        engine_lib.setSetting("CleanupJsfxAtClosing", not curval);
      end

      reaper.ImGui_EndTabItem(ctx)
    end

    if reaper.ImGui_BeginTabItem(ctx, 'Step Back') then
      ImGui_VerticalSpacer(ctx,5);
      StepBackSustainPedalModifierKeyComboBox();

      curval = engine_lib.getSetting("PreventAddingNotesIfModifierKeyIsPressed");
      if reaper.ImGui_Checkbox(ctx, "Do not add notes if the step back modifier key is pressed", curval) then
        engine_lib.setSetting("PreventAddingNotesIfModifierKeyIsPressed", not curval);
      end

      curval = engine_lib.getSetting("AllowErasingWhenNoteEndDoesNotMatchCursor");
      if reaper.ImGui_Checkbox(ctx, "Erase note ends even if they do not align on cursor", curval) then
        engine_lib.setSetting("AllowErasingWhenNoteEndDoesNotMatchCursor", not curval);
      end

      reaper.ImGui_EndTabItem(ctx)
    end

    if reaper.ImGui_BeginTabItem(ctx, 'KP Mode') then
      ImGui_VerticalSpacer(ctx,5);

      ------------
      reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 2, 0);
      if reaper.ImGui_Button(ctx,"rst##KPM_CA_rst") then
        engine_lib.resetSetting("KeyPressModeAggregationTime")
      end
      SL();
      reaper.ImGui_PopStyleVar(ctx);

      local change, v1 = reaper.ImGui_SliderDouble(ctx, "Chord Aggregation##keypress", engine_lib.getSetting("KeyPressModeAggregationTime"), 0, 0.1, "%.3f seconds", reaper.ImGui_SliderFlags_NoInput())
      if change then
        engine_lib.setSetting("KeyPressModeAggregationTime", v1);
      end
      SL();
      reaper.ImGui_TextColored(ctx, 0xB0B0B0FF, "(?)");
      TT("Key press events happening within this time\nwindow are aggregated as a chord")

      ------------
      reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 2, 0);
      if reaper.ImGui_Button(ctx,"rst##KPM_HI_rst") then
         engine_lib.resetSetting("KeyPressModeInertiaTime")
      end
      SL();
      reaper.ImGui_PopStyleVar(ctx);

      ------------
      change, v1 = reaper.ImGui_SliderDouble(ctx, "Sustain inertia##keypress", engine_lib.getSetting("KeyPressModeInertiaTime"), 0.2, 1.0, "%.3f seconds", reaper.ImGui_SliderFlags_NoInput())
      if change then
         engine_lib.setSetting("KeyPressModeInertiaTime", v1)
      end
      SL();
      reaper.ImGui_TextColored(ctx, 0xB0B0B0FF, "(?)");
      TT("If key A is pressed, and then key B is pressed but\nkey A was still held for more than this time,\nthen A is considered sustained and not released.\n\n\z
        This setting allows to enter new notes overlapping sustained notes.")
      SL();

      curval = engine_lib.getSetting("KeyPressModeInertiaEnabled");
      if reaper.ImGui_Checkbox(ctx, "Enabled##kp_inertia", curval) then
        engine_lib.setSetting("KeyPressModeInertiaEnabled", not curval);
      end

      ------------
      reaper.ImGui_EndTabItem(ctx)
    end

    if reaper.ImGui_BeginTabItem(ctx, 'KR Mode') then
      ImGui_VerticalSpacer(ctx,5);

      reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(), 2, 0);
      if reaper.ImGui_Button(ctx,"rst##KRM_CA_rst") then
        engine_lib.resetSetting("KeyReleaseModeForgetTime")
      end
      SL();
      reaper.ImGui_PopStyleVar(ctx);
      local change, v1 = reaper.ImGui_SliderDouble(ctx, "Forget time",  engine_lib.getSetting("KeyReleaseModeForgetTime"), 0.05, 0.4, "%.3f s", reaper.ImGui_SliderFlags_NoInput())
      if change then
        engine_lib.setSetting("KeyReleaseModeForgetTime", v1);
      end
      SL();
      reaper.ImGui_TextColored(ctx, 0xB0B0B0FF, "(?)");
      TT("How long a key should be remembered after release,\n\z
          if other keys are still pressed.\n\n\z
          This is used to know if a note should be forgotten/trashed\n\z
          or used as part of the input chord.")
      SL();

      reaper.ImGui_EndTabItem(ctx)
    end

    if reaper.ImGui_BeginTabItem(ctx, 'Playback') then

      ImGui_VerticalSpacer(ctx,5);
      PlaybackMarkerSettingComboBox();
      reaper.ImGui_EndTabItem(ctx)
    end

    reaper.ImGui_EndTabBar(ctx)
  end
end

function ui_loop()

  engine_lib.TrackFocus();

  reaper.ImGui_PushStyleVar(ctx,reaper.ImGui_StyleVar_WindowPadding(),10,10);

  local flags   = reaper.ImGui_WindowFlags_NoDocking() |
    reaper.ImGui_WindowFlags_NoCollapse() |
    reaper.ImGui_WindowFlags_AlwaysAutoResize() |
    reaper.ImGui_WindowFlags_TopMost();

  -- Since we use a trick to give back the focus to reaper, we don't want the window to glitch.
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), 0x0A0A0AFF);
  local visible, open = reaper.ImGui_Begin(ctx, 'One Small Step v0.9.4', true, flags);
  reaper.ImGui_PopStyleColor(ctx,1);

  if visible then
    reaper.ImGui_SetConfigVar(ctx,reaper.ImGui_ConfigVar_HoverDelayNormal(), 1.0);

    -- Target display line
    local take = engine_lib.TakeForEdition();

    TargetLine(take);

    -- Separator
    ImGui_VerticalSpacer(ctx,10);

    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),      0, 0);
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),       2, 4);
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemInnerSpacing(),  0, 0);

    local nlm   = engine_lib.getNoteLenParamSource();
    local nlmod = engine_lib.getNoteLenModifier();

    SettingsMiniBar();
    SL();
    MiniBarSeparator();
    SL();
    InputModeMiniBar();
    SL();
    MiniBarSeparator();
    SL();
    ConfSourceMiniBar();
    SL();
    MiniBarSeparator();

    if nlm == engine_lib.NoteLenParamSource.OSS then

      NoteLenMiniBar();
      SL();
      MiniBarSeparator();
      SL();
      NoteLenModifierMiniBar();

      if nlmod == engine_lib.NoteLenModifier.Tuplet then
        SL();
        MiniBarSeparator();
        SL();
        NTupletComboBox();
      elseif nlmod == engine_lib.NoteLenModifier.Modified then
        SL();
        MiniBarSeparator();
        SL();
        AugmentedDiminishedMiniBars();
      end

    elseif nlm == engine_lib.NoteLenParamSource.ProjectGrid then
      SL();
      ImGui_ProjectGridLabel(ctx);
    elseif nlm == engine_lib.NoteLenParamSource.ItemConf then
      SL();
      ImGui_ItemGridLabel(ctx,take);
    end

    reaper.ImGui_PopStyleVar(ctx,3);

    if showsettings then
      ImGui_VerticalSpacer(ctx,10);
      SettingsPanel();
    end

    if reaper.ImGui_IsWindowFocused(ctx) then
      if not focustimer or reaper.ImGui_IsAnyMouseDown(ctx) then
        -- create or reset the timer when there's activity in the window
        focustimer = reaper.time_precise();
      end

      if (reaper.time_precise() - focustimer > 0.5) then
        engine_lib.RestoreFocus();
      end
    else
      focustimer = nil;
    end

    -- End
    reaper.ImGui_End(ctx);
  end

  reaper.ImGui_PopStyleVar(ctx);

  if open then
    reaper.defer(main_loop)
  else
    stop();
  end
end

function updateToolbarButtonState(v)
  local _,_,sectionID,cmdID,_,_,_ = reaper.get_action_context();
  reaper.SetToggleCommandState(sectionID,cmdID,v);
  reaper.RefreshToolbar2(sectionID, cmdID);
end

function main_loop()

  local engine_ret = engine_lib.atLoop();

  if engine_ret == -42 then
    reaper.ShowMessageBox("Could not install One Small Step's helper FX on the track.\n\nIf you've just installed One Small Step, please try to restart REAPER to let it refresh its JFSX repository.", "Oops !", 0);
    return;
  end

  ui_loop();
end

function onReaperExit()
  updateToolbarButtonState(0);
  engine_lib.atExit();
end

function stop()
  reaper.ImGui_DestroyContext(ctx);
end

function start()
  focustimer    = 0; -- Will force a focus restore
  updateToolbarButtonState(1);
  engine_lib.atStart();
  reaper.atexit(onReaperExit);
  reaper.defer(main_loop);
end

start();

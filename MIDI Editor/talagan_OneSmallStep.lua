--[[
@description One Small Step : Alternative Step Input
@version 0.9
@author Ben 'Talagan' Babut
@license MIT
@metapackage
@provides
  [main=main,midi_editor] .
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
  [main=main,midi_editor] talagan_OneSmallStep Commit.lua
  [nomain] talagan_OneSmallStep/images/*.lua
  [nomain] talagan_OneSmallStep/talagan_OneSmallStep Engine lib.lua
  [nomain] talagan_OneSmallStep/talagan_OneSmallStep Helper lib.lua
  [effect] talagan_OneSmallStep/One Small Step Helper.jsfx
  [data] talagan_OneSmallStep/toolbar_icons/toolbar_one_small_step.png > toolbar_icons/toolbar_one_small_step.png
  [data] talagan_OneSmallStep/toolbar_icons/toolbar_one_small_step_cleanup.png > toolbar_icons/toolbar_one_small_step_cleanup.png
@screenshot
  https://stash.reaper.fm/48161/One%20Small%20Step%200.1.png
@changelog
  - Added support for complex note length modification (+/- fractions between 0 and 1)
  - More compact UI (save space)
  - Removed OFF mode : Redundant with closing OSS
  - Bug Fix : "change note len param source" actions where called "change note len modifier" instead
  - Big code refactoring
@about
  # Purpose

    One Small Step is a tool for performing MIDI note step input in REAPER. It is an alternative to the standard step input, and it tries to address some issues with certain workflows, as well as to propose different input modes, like validating held notes with the sustain pedal or a REAPER action (obviously linked to a custom keyboard shortcut). It will also work outside of the MIDI editor (in the arrange view), as long as you've selected a MIDI item and set the cursor at the right position ; this offers additional comfort and can speed up your workflow.

  # More detail

    REAPER's step input tool uses the MIDI control path. While it has some advantages, one of the main issue you may have encountered is that when step inputing, MIDI events will not go through the input FX chain of the track you're working on. If you are performing MIDI processing there (like channel routing, note transposition, note dropping, velocity processing, etc), everything will be ignored because REAPER does not use the result of the FX input chain, but the raw MIDI note events. This leads to strange behaviours, e.g. the MIDI editor piano roll not being in coherency with the input notes (so what you see on the piano roll is not what you'll get), but worse, you will not get the same result as if you were recording.

    To address this, One Small Step installs a JSFX at the end of the track input chain to watch for note events AFTER they've been processed by the FX input chain, and performs the patching of the MIDI item by itself.

  # Install Notes

    This script also needs the JS_ReaScriptAPI api by Julian Sander and the ReaImGui library by Christian Fillion to work. Please install them alongside (OSS will remind you to do so anyway). A restart of Reaper is needed after install.

  # Reaper forum thread

    The official discussion thread is located here : https://forum.cockos.com/showthread.php?t=288076

  # How to use

    Launch the action called 'OneSmallStep' (other actions are provided but we'll get on this later). You should now see OSS's main dialog - One Small Step is active (it is active as long as this dialog is visible). At the top of it, the name of the target MIDI track / item / take will be displayed if there's one eligible that matches your current selection. It is important to note that the track should be armed for record (OSS will give you an indication if you forgot to arm the recording) and the MIDI source should be chosen (exactly like you would when recording). If everyhing's ready, a red circle will glow, meaning that in this configuration, OneSmallStep is able to do its job (listen to MIDI events, and step input/patch the current MIDI item).

  ## Input modes

    You can then select your input mode between Keyboard / Sustain Pedal / Action. For each Input Mode, two triggers may be used to validate notes and rests : the sustain pedal and the 'OneSmallStep Commit' Action, to which you may consider giving a shortcut. Inserting held notes and/or rests depends on the chosen mode. You can use the tooltip by hovering over each mode's button as a reminder of their role.

  ### Keyboard

    Notes are added to the MIDI item at the current position, when the keys are released.
    Rests can also be inserted in this mode, by calling the 'OneSmallStep Commit' action or pressing the sustain pedal.

  ### Sustain Pedal

    Hold keys on your MIDI controller, then press the sustain pedal to validate them. This is convenient when playing with chords for example.
    In this mode, the 'OneSmallStep Commit' action will behave like the sustain pedal.

  ### Action

    It's the same thing as with the sustain pedal, except that held notes are validated with the REAPER action. In this mode, the sustain pedal will only insert rests.

  ## Note length

    Three sources for determining the input note length are proposed.

  ### One Small Step

    Note length parameters are global and configured in OSS, with the buttons aside.

  ### Project Grid

    One Small Step will use the grid parameters of the project to determine the length of the notes to insert

  ### MIDI Item's conf

    One Small Step will use the note parameters specific to the edited MIDI item to determine the length of the notes to insert. Those parameters are located at the bottom of the MIDI Editor (the combo boxes right of the 'Notes' label).

  ## Other actions

    To speed up your flow, multiple actions are provided to quickly change OSS parameters, so that you can assign shortcuts to them. Those are the "Change note len", "Decrease/Increase note len", "Change note len modifier", "Change note len param source" actions, whose names should be self explanatory. The "Cleanup helper JSFXs" is here for cleaniness, to remove the Helper JSFXs that are installed automatically on the input FX chain of your tracks when OSS is running (it could have been done automatically when closing the tool, but it adds an entry in the undo stack, which is annoying, and I don't have a solution for this yet).

  # Calling One Small Step from a Reaper toolbar button

    The most logical way to summon OSS is to create a togglable toolbar button in Reaper by assigning it the 'talagan_OneSmallStep.lua' action. OSS handles the color of the button dependending on its state. However, the first time you try to close OSS by re-clicking the toolbar button, Reaper will ask if you want to open another instance of OSS or terminate the current one. Tick 'remember my answer for this script' and click 'Terminate Instances'. Now, the button should be fully togglable.

  # Toolbar icons

    Two toolbar icons are provided with OSS, one icon for launching OSS ('toolbar_one_small_step'), and one for launching the cleanup script ('toolbar_one_small_step_cleanup').

  # Credits

    This tool takes a lot of inspiration in tenfour's "tenfour-step" scripts. Epic hail to tenfour for opening the way !

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

function ButtonGroupImageButton(image_name, is_on, callback, corner)
  reaper.ImGui_SetCursorPosY(ctx,  reaper.ImGui_GetCursorPosY(ctx));
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), is_on and 0x5080FFFF or 0x203040FF);

  if corner == nil then
    corner = 0.1
  end

  if reaper.ImGui_ImageButton(ctx, image_name, getImage(image_name), 20, 20, corner, corner, 1 - corner, 1 - corner, 0, 0xFFFFFFFF) then
    callback();
  end

  reaper.ImGui_PopStyleColor(ctx);
  reaper.ImGui_SameLine(ctx);
end

function ImGui_NoteLenImg(context, image_name, triplet, divider)
  reaper.ImGui_SetCursorPosY(ctx,reaper.ImGui_GetCursorPosY(ctx));
  reaper.ImGui_Image(ctx, getImage(image_name), 20, 20, 0.1, 0.1, 0.9, 0.9);

  if triplet then
    reaper.ImGui_SameLine(ctx);
    reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetCursorPosX(ctx) - 20);
    reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) - 10);
    ImGui_NoteLenImg(ctx, "note_triplet");
  end

  if divider then
    reaper.ImGui_SameLine(ctx);
    reaper.ImGui_SetCursorPosY(ctx,reaper.ImGui_GetCursorPosY(ctx) + 3);
    reaper.ImGui_TextColored(ctx, 0xC0C0C0FF, divider);
  end
end

local function to_frac(num)
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

function ImGui_VerticalSpacer(context, height)
  reaper.ImGui_PushStyleVar(context, reaper.ImGui_StyleVar_ItemSpacing(),0,0)
  reaper.ImGui_Dummy(context, 10, height);
  reaper.ImGui_PopStyleVar(context,1);
end

function MiniBarSeparator()
  reaper.ImGui_SameLine(ctx);
  reaper.ImGui_Dummy(ctx,10,0);
  reaper.ImGui_SameLine(ctx);
end

-- Current take info label and indicators
function TakeInfo(take)
  local track         = reaper.GetMediaItemTake_Track(take);
  local _, track_name = reaper.GetTrackName(track);
  local take_name     = reaper.GetTakeName(take);
  local recarmed      = reaper.GetMediaTrackInfo_Value(track, "I_RECARM");
  local playState     = reaper.GetPlayState();

  reaper.ImGui_TextColored(ctx, 0xA0A0FFFF, track_name .. " / " .. take_name)

  -- Glowing indicator
  reaper.ImGui_SameLine(ctx);
  reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) - 3);

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

  -- Target issues debug text
  reaper.ImGui_SameLine(ctx);
  reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) - 3);
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

-- MINIBAR : Input Mode
function InputModeMiniBar()
  local mode      = engine_lib.getInputMode();

  ButtonGroupImageButton('input_mode_keyboard', mode == engine_lib.InputMode.Keyboard, function()engine_lib.setInputMode(engine_lib.InputMode.Keyboard); end);
  if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal()) then
    reaper.ImGui_SetTooltip(ctx, 'Input Mode : Keyboard\n\nNotes are added on keyboard key\nrelease events.\n\nThis is pretty much the same as\nReaper\'s default step input mode.\n\n- The sustain pedal inserts rests\n- The Commit action inserts rests')
  end

  ButtonGroupImageButton('input_mode_pedal', mode == engine_lib.InputMode.Pedal, function()engine_lib.setInputMode(engine_lib.InputMode.Pedal); end,0);
  if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal()) then
    reaper.ImGui_SetTooltip(ctx, 'Input Mode : Pedal\n\nHold some keyboard keys, and\nthen press the sustain pedal\nto validate and add notes.\n\nUseful when testing chords.\n\n- The sustain pedal commits held notes\n- The Commit action commits held notes')
  end

  ButtonGroupImageButton('input_mode_action', mode == engine_lib.InputMode.Action, function()engine_lib.setInputMode(engine_lib.InputMode.Action); end);
  if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal()) then
    reaper.ImGui_SetTooltip(ctx, 'Input Mode : Action\n\nHold some keyboard keys, and then\ncall the \'OneSmallStep Commit\'\naction from Reaper to validate\nand add notes.\n\n- The sustain pedal inserts rests\n- The Commit action commits held notes')
  end
end

-- MINIBAR : Conf source
function ConfSourceMiniBar()
  local nlm = engine_lib.getNoteLenMode();

  ButtonGroupImageButton('note_len_mode_oss', nlm == engine_lib.NoteLenMode.OSS, function() engine_lib.setNoteLenMode(engine_lib.NoteLenMode.OSS) end, 0);
  if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal()) then
    reaper.ImGui_SetTooltip(ctx, 'Note Length conf : One Small Step\n\nUse the params aside.')
  end

  ButtonGroupImageButton('note_len_mode_pgrid', nlm == engine_lib.NoteLenMode.ProjectGrid, function() engine_lib.setNoteLenMode(engine_lib.NoteLenMode.ProjectGrid) end);
  if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal()) then
    reaper.ImGui_SetTooltip(ctx, "Note Length conf : Project\n\nUse the project's grid conf.")
  end

  ButtonGroupImageButton('note_len_mode_igrid', nlm == engine_lib.NoteLenMode.ItemConf, function() engine_lib.setNoteLenMode(engine_lib.NoteLenMode.ItemConf) end);
  if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal()) then
    reaper.ImGui_SetTooltip(ctx, "Note Length conf : MIDI Item\n\nUse the MIDI item's own conf.\n\n('Notes' at the bottom of the MIDI editor)")
  end
end

-- MINIBAR : Note length
function NoteLenMiniBar()
  local nl = engine_lib.getNoteLen();
  for i,v in ipairs(engine_lib.NoteLenDefs) do
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
  if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal()) then
    reaper.ImGui_SetTooltip(ctx, "Dotted")
  end

  ButtonGroupImageButton('note_triplet', nmod == engine_lib.NoteLenModifier.Triplet, function()
      if nmod == engine_lib.NoteLenModifier.Triplet then
        engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Straight);
      else
        engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Triplet);
      end
    end
  );
  if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal()) then
    reaper.ImGui_SetTooltip(ctx, "Triplet")
  end

  ButtonGroupImageButton('note_modified', nmod == engine_lib.NoteLenModifier.Modified, function()
      if nmod == engine_lib.NoteLenModifier.Modified then
        engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Straight);
      else
        engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Modified);
      end
    end
  );
  if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal()) then
    reaper.ImGui_SetTooltip(ctx, "Modified length")
  end

  ButtonGroupImageButton('note_tuplet', nmod == engine_lib.NoteLenModifier.Tuplet, function()
      if nmod == engine_lib.NoteLenModifier.Tuplet then
        engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Straight);
      else
        engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Tuplet);
      end
    end
  );
  if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal()) then
    reaper.ImGui_SetTooltip(ctx, "N-tuplet")
  end
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
  MiniBarSeparator();
  NoteADFactorComboBox();
end


function ui_loop()

  reaper.ImGui_PushStyleVar(ctx,reaper.ImGui_StyleVar_WindowPadding(),10,10);
  --
  local flags   = reaper.ImGui_WindowFlags_NoDocking() |
    reaper.ImGui_WindowFlags_NoCollapse() |
    reaper.ImGui_WindowFlags_AlwaysAutoResize() |
    reaper.ImGui_WindowFlags_TopMost();

  -- Since we use a trick to give back the focus to reaper, we don't want the window to glitch.
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), 0x0A0A0AFF);
  local visible, open = reaper.ImGui_Begin(ctx, 'One Small Step v0.9', true, flags);
  reaper.ImGui_PopStyleColor(ctx,1);

  if visible then
    reaper.ImGui_SetConfigVar(ctx,reaper.ImGui_ConfigVar_HoverDelayNormal(), 1.0);

    -- Target display line
    local take = engine_lib.TakeForEdition();
    if not take then
      reaper.ImGui_TextColored(ctx, 0xA0A0A0FF, "No target item. Please select one.");
      ImGui_VerticalSpacer(ctx,3);
    else
      TakeInfo(take);
    end

    -- Separator
    ImGui_VerticalSpacer(ctx,10);

    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),      0, 0);
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),       2, 4);
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemInnerSpacing(),  0, 0);

    local nlm   = engine_lib.getNoteLenMode();
    local nlmod = engine_lib.getNoteLenModifier();

    InputModeMiniBar();
    MiniBarSeparator();
    ConfSourceMiniBar();
    MiniBarSeparator();

    if nlm == engine_lib.NoteLenMode.OSS then

      NoteLenMiniBar();
      MiniBarSeparator();
      NoteLenModifierMiniBar();

      if nlmod == engine_lib.NoteLenModifier.Tuplet then
        MiniBarSeparator();
        NTupletComboBox();
      elseif nlmod == engine_lib.NoteLenModifier.Modified then
        MiniBarSeparator();
        AugmentedDiminishedMiniBars();
      end

    elseif nlm == engine_lib.NoteLenMode.ProjectGrid then
      ImGui_ProjectGridLabel(ctx);
    elseif nlm == engine_lib.NoteLenMode.ItemConf then
      ImGui_ItemGridLabel(ctx,take);
    end

    reaper.ImGui_PopStyleVar(ctx,3);

    if reaper.ImGui_IsWindowFocused(ctx) then
      if not focustimer or reaper.ImGui_IsAnyMouseDown(ctx) then
        -- create or reset the timer when there's activity in the window
        focustimer = reaper.time_precise();
      end

      if reaper.time_precise() - focustimer > 0.5 then
        local hwnd = reaper.GetMainHwnd();
        reaper.JS_Window_SetFocus(hwnd)
      end
    else
      focustimer = nil;
    end

    -- End
    reaper.ImGui_End(ctx);

  end

  reaper.ImGui_PopStyleVar(ctx);

  if open then
    reaper.defer(loop)
  else
    stop();
  end
end


function updateToolbarButtonState(v)
  local _,_,sectionID,cmdID,_,_,_ = reaper.get_action_context();
  reaper.SetToggleCommandState(sectionID,cmdID,v);
  reaper.RefreshToolbar2(sectionID, cmdID);
end

function loop()

  local engine_ret = engine_lib.atLoop();

  if engine_ret == -42 then
    reaper.ShowMessageBox("Could not install One Small Step's helper FX on the track.\n\nIf you've just installed One Small Step, please try to restart REAPER to let it refresh its JFSX repository.", "Oops !", 0);
    return;
  end

  ui_loop();
end

function onReaperExit()
  updateToolbarButtonState(0);
end

function stop()
  reaper.ImGui_DestroyContext(ctx);
  engine_lib.atExit();
end

function start()
  updateToolbarButtonState(1);
  engine_lib.atStart();
  reaper.atexit(onReaperExit);
  reaper.defer(loop);
end

start();

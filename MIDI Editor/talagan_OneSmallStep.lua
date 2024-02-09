--[[
@description One Small Step : Alternative Step Input
@version 0.8
@author Ben 'Talagan' Babut
@license MIT
@metapackage
@provides
  [main=main,midi_editor] .
  [main=main,midi_editor] talagan_OneSmallStep Change note len mode.lua > talagan_OneSmallStep Change note len modifier - OSS.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len mode.lua > talagan_OneSmallStep Change note len modifier - ItemConf.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len mode.lua > talagan_OneSmallStep Change note len modifier - ProjectGrid.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len modifier.lua > talagan_OneSmallStep Change note len modifier - Triplet.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len modifier.lua > talagan_OneSmallStep Change note len modifier - Straight.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len modifier.lua > talagan_OneSmallStep Change note len modifier - Dotted.lua
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
  - MIDI Items are now extended if the input notes overflow
  - Allow the use of the commit action in keyboard mode to insert rests
  - Allow the use of the commit action in pedal mode to act as the sustain pedal
  - Added Project Grid and MIDI Item conf modes to change the source for the note length
  - Added support for n-tuplets
  - Bug Fix : When launched from a toolbar button, update the button to OFF state when crashing or being terminated by REAPER
@about
  # Purpose

    One Small Step is a tool for performing MIDI note step input in REAPER. It is an alternative to the standard step input, and it tries to address some issues with certain workflows, as well as to propose different input modes, like validating held notes with the sustain pedal or a REAPER action (obviously linked to a custom keyboard shortcut). It will also work outside of the MIDI editor (in the arrange view), as long as you've selected a MIDI item and set the cursor at the right position ; this offers additional comfort and can speed up your workflow.

  # More detail

    REAPER's step input tool uses the MIDI control path. While it has some advantages, one of the main issue you may have encountered is that when step inputing, MIDI events will not go through the input FX chain of the track you're working on. If you are performing MIDI processing there (like channel routing, note transposition, note dropping, velocity processing, etc), everything will be ignored because REAPER does not use the result of the FX input chain, but the raw MIDI note events. This leads to strange behaviours, e.g. the MIDI editor piano roll not being in coherency with the input notes (so what you see on the piano roll is not what you'll get), but worse, you will not get the same result as if you were recording.

    To address this, One Small Step installs a JSFX at the end of the track input chain to watch for note events AFTER they've been processed by the FX input chain, and performs the patching of the MIDI item by itself.

  # Install Notes

    This script also needs the JS_ReaScriptAPI api by Julian Sander and the ReaImGui library by Christian Fillion to work. Please install them alongside (OSS will remind you to do so anyway).

  # Reaper forum thread

    The official discussion thread is located here : https://forum.cockos.com/showthread.php?t=288076

  # How to use

    Launch the action called 'OneSmallStep' (other actions are provided but we'll get on this later). You should now see OSS's main dialog - One Small Step is active (it is active as long as this dialog is visible). At the top of it, the name of the target MIDI track / item / take will be displayed if there's one eligible that matches your current selection. It is important to note that the track should be armed for record (OSS will give you an indication if you forgot to arm the recording). If everyhing's ready, a red circle will glow, meaning that in this configuration, OneSmallStep is able to do its job (listen to MIDI events, and step input/patch the current MIDI item).

  ## Input modes

    You can then select your input mode between Off / Keyboard / Sustain Pedal / Action.

  ### Off mode

    Does nothing. It just allows to keep the window open and play with the params without the risk to edit something.

  ### Keyboard

    Notes are added to the MIDI item at the current position, when the keys are released.
    Rests can also be inserted in this mode, by calling the 'OneSmallStep Commit' action.

  ### Sustain Pedal

    Hold keys on your MIDI controller, then press the sustain pedal to validate them. This is convenient when playing with chords for example.
    In this mode, the 'OneSmallStep Commit' action will behave like the sustain pedal.

  ### Action

    It's the same thing as with the sustain pedal, except that held notes are validated with a REAPER action. This action is the one called 'OneSmallStep Commit'. You can assign a shortcut to it, and your shortcut will take the role of the sustain pedal for validation.

  ## Note length

    Three sources for determining the input note length are proposed.

  ### One Small Step

    Note length parameters are global and configured in OSS, with the buttons aside.

  ### Project Grid

    One Small Step will use the grid parameters of the project to determine the length of the notes to insert

  ### MIDI Item's conf

    One Small Step will use the note parameters specific to the edited MIDI item to determine the length of the notes to insert. Those parameters are located at the bottom of the MIDI Editor (the combo boxes right of the 'Notes' label).

  ## Other actions

    To speed up your flow, multiple actions are provided to quickly change OSS parameters, so that you can assign shortcuts to them. Those are the "Change note len", "Decrease/Increase note len", "Change note len modifier", "Change note len mode" actions, whose names should be self explanatory. The "Cleanup helper JSFXs" is here for cleaniness, to remove the Helper JSFXs that are installed automatically on the input FX chain of your tracks when OSS is running (it could have been done automatically when closing the tool, but it adds an entry in the undo stack, which is annoying, and I don't have a solution for this yet).

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
local bigfont               = reaper.ImGui_CreateFont("sans-serif", 16);
local bigfontbold           = reaper.ImGui_CreateFont("sans-serif", 16, reaper.ImGui_FontFlags_Bold());

reaper.ImGui_Attach(ctx,bigfont);
reaper.ImGui_Attach(ctx,bigfontbold);

------------------------------

_DEBUG=true
function DBG(txt)
  if _DEBUG then
    reaper.ShowConsoleMsg(txt);
  end
end

-------

function ButtonGroupTextButton(text, is_on, callback)
  reaper.ImGui_SetCursorPosY(ctx,reaper.ImGui_GetCursorPosY(ctx) - 2);
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), is_on and 0x5080FFFF or 0x203040FF);
  if reaper.ImGui_Button(ctx, text) then
    callback();
  end

  reaper.ImGui_PopStyleColor(ctx);
  reaper.ImGui_SameLine(ctx);
end

function ButtonGroupImageButton(image_name, is_on, callback, corner)
  reaper.ImGui_SetCursorPosY(ctx,reaper.ImGui_GetCursorPosY(ctx) - 3);
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
  reaper.ImGui_SetCursorPosY(ctx,reaper.ImGui_GetCursorPosY(ctx) - 3);
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

function ImGui_QNToLabel(ctx, qn)

  -- We have to do a reverse translation from the info given by GetProjectGrid...
  -- And it's TEDIOUS


  -- I don't have enough icons, cheat
  if qn == 4 then
    ImGui_NoteLenImg(ctx, "note_1", false, "x 4");
  elseif qn == 4 * (3/2.0) then
    ImGui_NoteLenImg(ctx, "note_1", false, ". x 4");
  elseif qn == 4 * (2/3.0) then
    ImGui_NoteLenImg(ctx, "note_1", true,  "x 4");

  -- I don't have enough icons, cheat
  elseif qn == 2 then
    ImGui_NoteLenImg(ctx, "note_1", false, "x 2");
  elseif qn == 2 * (3/2.0) then
    ImGui_NoteLenImg(ctx, "note_1", false, ". x 2");
  elseif qn == 2 * (2/3.0) then
    ImGui_NoteLenImg(ctx, "note_1", true,  "x 2");

  elseif qn == 1 then
    ImGui_NoteLenImg(ctx, "note_1");
  elseif qn == 1 * (3/2.0) then
    ImGui_NoteLenImg(ctx, "note_1", false, ".");
  elseif qn == 1 * (2/3.0) then
    ImGui_NoteLenImg(ctx, "note_1", true);

  elseif qn == 0.5 then
    ImGui_NoteLenImg(ctx, "note_1_2");
  elseif qn == 0.5 * (3/2.0) then
    ImGui_NoteLenImg(ctx, "note_1_2", false, ".");
  elseif qn == 0.5 * (2/3.0) then
    ImGui_NoteLenImg(ctx, "note_1_2", true);

  elseif qn == 0.25 then
    ImGui_NoteLenImg(ctx, "note_1_4");
  elseif qn == 0.25 * (3/2.0) then
    ImGui_NoteLenImg(ctx, "note_1_4", false, ".");
  elseif qn == 0.25 * (2/3.0) then
    ImGui_NoteLenImg(ctx, "note_1_4", true);

  elseif qn == 0.125 then
    ImGui_NoteLenImg(ctx, "note_1_8");
  elseif qn == 0.125 * (3/2.0) then
    ImGui_NoteLenImg(ctx, "note_1_8", false, ".");
  elseif qn == 0.125 * (2/3.0) then
    ImGui_NoteLenImg(ctx, "note_1_8", true);

  elseif qn == 0.0625 then
    ImGui_NoteLenImg(ctx, "note_1_16");
  elseif qn == 0.0625 * (3/2.0) then
    ImGui_NoteLenImg(ctx, "note_1_16", false, ".");
  elseif qn == 0.0625 * (2/3.0) then
    ImGui_NoteLenImg(ctx, "note_1_16", true);

  elseif qn == 0.03125 then
    ImGui_NoteLenImg(ctx, "note_1_32");
  elseif qn == 0.03125 * (3/2.0) then
    ImGui_NoteLenImg(ctx, "note_1_32", false, ".");
  elseif qn == 0.03125 * (2/3.0) then
    ImGui_NoteLenImg(ctx, "note_1_32", true);

  elseif qn == 0.015625 then
    ImGui_NoteLenImg(ctx, "note_1_64");
  elseif qn == 0.015625 * (3/2.0) then
    ImGui_NoteLenImg(ctx, "note_1_64", false, ".");
  elseif qn == 0.015625 * (2/3.0) then
    ImGui_NoteLenImg(ctx, "note_1_64", true);

  -- I don't have enough icons, cheat
  elseif qn == 0.0078125 then
    ImGui_NoteLenImg(ctx, "note_1", false, "/ 128");
  elseif qn == 0.0078125 * (3/2.0) then
    ImGui_NoteLenImg(ctx, "note_1", false, ". / 128");
  elseif qn == 0.0078125 * (2/3.0) then
    ImGui_NoteLenImg(ctx, "note_1", true,  "/ 128");
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

function ui_loop()

  reaper.ImGui_PushStyleVar(ctx,reaper.ImGui_StyleVar_WindowPadding(),10,10);
  --
  local flags   = reaper.ImGui_WindowFlags_NoDocking() |
    reaper.ImGui_WindowFlags_NoCollapse() |
    reaper.ImGui_WindowFlags_AlwaysAutoResize() |
    reaper.ImGui_WindowFlags_TopMost();

  -- Since we use a trick to give back the focus to reaper, we don't want the window to glitch.
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), 0x0A0A0AFF);
  local visible, open = reaper.ImGui_Begin(ctx, 'One Small Step v0.8', true, flags);
  reaper.ImGui_PopStyleColor(ctx,1);

  if visible then
    reaper.ImGui_SetConfigVar(ctx,reaper.ImGui_ConfigVar_HoverDelayNormal(), 1.0);

    -- Target display line
    local take = engine_lib.TakeForEdition();
    if not take then
      reaper.ImGui_TextColored(ctx, 0xA0A0A0FF, "No target item. Please select one.");

      ImGui_VerticalSpacer(ctx,3);
    else
      local track         = reaper.GetMediaItemTake_Track(take);
      local _, track_name = reaper.GetTrackName(track);
      local take_name     = reaper.GetTakeName(take);
      local recarmed      = reaper.GetMediaTrackInfo_Value(track, "I_RECARM");
      local playState     = reaper.GetPlayState();

      reaper.ImGui_TextColored(ctx, 0xA0A0FFFF, track_name .. " / " .. take_name)

      -- Glowing indicator
      reaper.ImGui_SameLine(ctx);
      reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) - 3);

      if (recarmed == 1) and not (engine_lib.getMode() == 0) and playState == 0 then
        local alpha = math.sin(reaper.time_precise()*4);
        local r1    = 200+math.floor(55 * alpha);
        local r2    = 120+math.floor(55 * alpha);

        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(), (r1 << 24) | 0x000000FF);
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),   (r2 << 24) | 0x000000FF);
      else
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(), 0xCCCCCCFF);
        reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(),   0x808080FF);
      end

      reaper.ImGui_RadioButton(ctx, '##', true);
      reaper.ImGui_PopStyleColor(ctx, 2);

      -- Target issues debug text
      reaper.ImGui_SameLine(ctx);
      reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) - 3);
      if not (recarmed == 1) then
        reaper.ImGui_TextColored(ctx, 0x808080FF, '[Track not armed]');
      elseif engine_lib.getMode() == 0 then
        reaper.ImGui_TextColored(ctx, 0x808080FF, '[Input Mode is OFF]');
      elseif not (playState == 0) then
        reaper.ImGui_TextColored(ctx, 0x808080FF, '[Reaper not ready]');
      else
        reaper.ImGui_TextColored(ctx, 0x808080FF, '');
      end

    end

    -- Separator
    ImGui_VerticalSpacer(ctx,10);

    -- Input mode line
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),10,3);
    reaper.ImGui_Text(ctx, "Input Mode");
    reaper.ImGui_SameLine(ctx);
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),2,3);

    local mode      = engine_lib.getMode();

    ButtonGroupTextButton("Off",      mode == engine_lib.InputMode.None,      function() engine_lib.setMode(engine_lib.InputMode.None); end);
    if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal() ) then
      reaper.ImGui_SetTooltip(ctx, 'One Small Step input is disabled.\n\nThat mode allows you to keep\nthis window open, but that\'s all.')
    end

    ButtonGroupTextButton("Keyboard", mode == engine_lib.InputMode.Keyboard,  function() engine_lib.setMode(engine_lib.InputMode.Keyboard); end);
    if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal() ) then
      reaper.ImGui_SetTooltip(ctx, 'Notes are added on keyboard key\nrelease events.\n\nThis is pretty much the same as\nReaper\'s default step input mode.')
    end

    ButtonGroupTextButton("Pedal",    mode == engine_lib.InputMode.Pedal,     function() engine_lib.setMode(engine_lib.InputMode.Pedal); end);
    if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal()) then
      reaper.ImGui_SetTooltip(ctx, 'Hold some keyboard keys, and\nthen press the sustain pedal\nto validate and add notes.\n\nUseful when testing chords.')
    end

    ButtonGroupTextButton("Action",    mode == engine_lib.InputMode.Action,     function() engine_lib.setMode(engine_lib.InputMode.Action); end);
    if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal()) then
      reaper.ImGui_SetTooltip(ctx, 'Hold some keyboard keys, and then\ncall the \'OneSmallStep Commit\'\naction from Reaper to validate\nand add notes.\n\nThis is pretty much the same as\nthe sustain pedal mode, except\nthat it uses a Reaper action\nto validate input notes.')
    end

    reaper.ImGui_PopStyleVar(ctx,2);

    -- Separator
    reaper.ImGui_NewLine(ctx);
    ImGui_VerticalSpacer(ctx,7);

    -- Note length line
    reaper.ImGui_Text(ctx, "Note Length");
    reaper.ImGui_SameLine(ctx);

    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),      0, 0);
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),       2, 4);
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemInnerSpacing(),  0, 0);

    local nlm = engine_lib.getNoteLenMode();

    ButtonGroupImageButton('note_len_mode_oss', nlm == engine_lib.NoteLenMode.OSS, function() engine_lib.setNoteLenMode(engine_lib.NoteLenMode.OSS) end, 0);
    if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal()) then
      reaper.ImGui_SetTooltip(ctx, 'Use One Small Step conf (aside)')
    end

    ButtonGroupImageButton('note_len_mode_pgrid', nlm == engine_lib.NoteLenMode.ProjectGrid, function() engine_lib.setNoteLenMode(engine_lib.NoteLenMode.ProjectGrid) end);
    if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal()) then
      reaper.ImGui_SetTooltip(ctx, "Use the project's grid conf")
    end

    ButtonGroupImageButton('note_len_mode_igrid', nlm == engine_lib.NoteLenMode.ItemConf, function() engine_lib.setNoteLenMode(engine_lib.NoteLenMode.ItemConf) end);
    if reaper.ImGui_IsItemHovered(ctx, reaper.ImGui_HoveredFlags_DelayNormal()) then
      reaper.ImGui_SetTooltip(ctx, "Use the MIDI item's own conf\n\n('Notes' at the bottom of the MIDI editor)")
    end

    reaper.ImGui_SameLine(ctx);
    reaper.ImGui_Dummy(ctx,10,0);
    reaper.ImGui_SameLine(ctx);

    if nlm == engine_lib.NoteLenMode.OSS then

      local nl = engine_lib.getNoteLen();
      for s,k in ipairs({ "1", "1_2", "1_4", "1_8", "1_16", "1_32", "1_64" }) do
        ButtonGroupImageButton('note_'.. k, nl==k,
          function()
            engine_lib.setNoteLen(k)
          end
        );
      end

      reaper.ImGui_SameLine(ctx);
      reaper.ImGui_Dummy(ctx,10,0);
      reaper.ImGui_SameLine(ctx);

      local nmod = engine_lib.getNoteLenModifier();

      ButtonGroupImageButton('note_dotted', nmod == engine_lib.NoteLenModifier.Dotted, function()
          if nmod == engine_lib.NoteLenModifier.Dotted then
            engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Straight);
          else
            engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Dotted);
          end
        end
      );
      ButtonGroupImageButton('note_triplet', nmod == engine_lib.NoteLenModifier.Triplet, function()
          if nmod == engine_lib.NoteLenModifier.Triplet then
            engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Straight);
          else
            engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Triplet);
          end
        end
      );
      ButtonGroupImageButton('note_tuplet', nmod == engine_lib.NoteLenModifier.Tuplet, function()
          if nmod == engine_lib.NoteLenModifier.Tuplet then
            engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Straight);
          else
            engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Tuplet);
          end
        end
      );

      if nmod == engine_lib.NoteLenModifier.Tuplet then

        reaper.ImGui_SameLine(ctx);
        reaper.ImGui_Dummy(ctx,10,0);
        reaper.ImGui_SameLine(ctx);

        local combo_items = { '4', '5', '6', '7', '8', '9', '10', '11', '12' }

        reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 5, 4);
        reaper.ImGui_SetCursorPosY(ctx, reaper.ImGui_GetCursorPosY(ctx) - 3);
        reaper.ImGui_PushID(ctx, "nlet_combo");

        local tuplet = engine_lib.getTupletDivision();

        reaper.ImGui_SetNextItemWidth(ctx,50);
        if reaper.ImGui_BeginCombo(ctx, '', tuplet) then
          for i,v in ipairs(combo_items) do
            local is_selected = (combo_preview_value == v);
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

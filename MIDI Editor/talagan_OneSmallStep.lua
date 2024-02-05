--[[
@description One Small Step : Alternative Step Input
@version 0.1
@author Ben 'Talagan' Babut
@license MIT
@metapackage
@provides
  [main=main,midi_editor] .
  [main=main,midi_editor] talagan_OneSmallStep Toggle note len modifier - Triplet.lua
  [main=main,midi_editor] talagan_OneSmallStep Toggle note len modifier - Straight.lua
  [main=main,midi_editor] talagan_OneSmallStep Toggle note len modifier - Dotted.lua
  [main=main,midi_editor] talagan_OneSmallStep Increase note len.lua
  [main=main,midi_editor] talagan_OneSmallStep Decrease note len.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len - 1_64.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len - 1_32.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len - 1_16.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len - 1_8.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len - 1_4.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len - 1_2.lua
  [main=main,midi_editor] talagan_OneSmallStep Change note len - 1.lua
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
  Initial version.
@about
  # Purpose

    One Small Step is a tool for performing MIDI note step input in REAPER. It is an alternative to the standard step input, and it tries to address some issues with certain workflows, as well as to propose different input modes, like validating held notes with the sustain pedal or a REAPER action (obviously linked to a custom keyboard shortcut). It will also work outside of the MIDI editor (in the arrange view), as long as you've selected a MIDI item and set the cursor at the right position ; this offers additional comfort and can speed up your workflow.

  # More detail

    REAPER's step input tool uses the MIDI control path. While it has some advantages, one of the main issue you may have encountered is that when step inputing, MIDI events will not go through the input FX chain of the track you're working on. If you are performing MIDI processing there (like channel routing, note transposition, note dropping, velocity processing, etc), everything will be ignored because REAPER does not use the result of the FX input chain, but the raw MIDI note events. This leads to strange behaviours, e.g. the MIDI editor piano roll not being in coherency with the input notes (so what you see on the piano roll is not what you'll get), but worse, you will not get the same result as if you were recording.

    To address this, One Small Step installs a JSFX at the end of the track input chain to watch for note events AFTER they've been processed by the FX input chain, and performs the patching of the MIDI item by itself.

  # Install Notes

    This script also needs the JS_ReaScriptAPI api by Julian Sander and the ReaImGui library by Christian Fillion to work. Please install them alongside (OSS will remind you to do so anyway).

  # Reaper forum thread

    The forum thread does not exist yet (at release time). Please search "One Small Step" on reaper forums for now (until a new version is released and the doc is updated).

  # How to use

    Launch the action called 'OneSmallStep' (other actions are provided but we'll get on this later). You should now see OSS's main dialog - One Small Step is active (it is active as long as this dialog is visible). At the top of it, the name of the target MIDI track / item / take will be displayed if there's one eligible that matches your current selection. It is important to note that the track should be armed for record (OSS will give you an indication if you forgot to arm the recording). If everyhing's ready, a red circle will glow, meaning that in this configuration, OneSmallStep is able to do its job (listen to MIDI events, and step input/patch the current MIDI item).

  ## Input modes

    You can then select your input mode between Off / Keyboard / Sustain Pedal / Action.

  ### Off mode

    Does nothing. It just allows to keep the window open and play with the params without the risk to edit something.

  ### Keyboard

    Notes are added to the MIDI item at the current position, when the keys are released.

  ### Sustain Pedal

    Hold keys on your MIDI controller, then press the sustain pedal to validate them. This is convenient when playing with chords for example.

  ### Action

    It's the same thing as with the sustain pedal, except that held notes are validated with a REAPER action. This action is the one called 'OneSmallStep Commit'. You can assign a shortcut to it, and your shortcut will take the role of the sustain pedal for validation.

  ## Note length

    You can adjust the length of the input notes here.

  ## Other actions

    To speed up your flow, multiple actions are provided to quickly change OSS parameters, so that you can assign shortcuts to them. Those are the "Change note len", "Decrease/Increase note len", "Toggle note len modifier" actions, whose names should be safe explanatory. The "Cleanup helper JSFXs" is here for cleaniness, to remove the Helper JSFXs that are installed automatically on the input FX chain of your tracks when OSS is running (it could have been done automatically when closing the tool, but it adds an entry in the undo stack, which is annoying, and I don't have a solution for this yet).

  # Toolbar icons

    Two toolbar icons are provided with OSS, one icon for launching OSS ('toolbar_one_small_step'), and one for launching the cleanup script ('toolbar_one_small_step_cleanup').

  # Credits

    This tool takes a lot of inspiration in tenfour's "tenfour-step" scripts. Epic hail to tenfour for opening the way !

--]]

-------------------------

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

-------------------------
-- Path and modules

package.path      = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path
local engine_lib = require "talagan_OneSmallStep/talagan_OneSmallStep Engine lib";

--------------------------
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

--------------------

local images = {};

function getImage(image_name)
  if not reaper.ImGui_ValidatePtr(images[image_name], 'ImGui_Image*') then
    local bin = require("./talagan_OneSmallStep/images/" .. image_name);
    images[image_name] = reaper.ImGui_CreateImageFromMem(bin);
  end
  return images[image_name];
end

-------

local ctx                   = reaper.ImGui_CreateContext('One Small Step');
local bigfont               = reaper.ImGui_CreateFont("sans-serif", 16);
local bigfontbold           = reaper.ImGui_CreateFont("sans-serif", 16, reaper.ImGui_FontFlags_Bold());

reaper.ImGui_Attach(ctx,bigfont);
reaper.ImGui_Attach(ctx,bigfontbold);

-------

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

function ButtonGroupImageButton(image_name, is_on, callback)
  reaper.ImGui_SetCursorPosY(ctx,reaper.ImGui_GetCursorPosY(ctx) - 3);
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), is_on and 0x5080FFFF or 0x203040FF);

  if reaper.ImGui_ImageButton(ctx, image_name, getImage(image_name), 20, 20, 0.1, 0.1, 0.9, 0.9, 0, 0xFFFFFFFF) then
    callback();
  end

  reaper.ImGui_PopStyleColor(ctx);
  reaper.ImGui_SameLine(ctx);
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
  local visible, open = reaper.ImGui_Begin(ctx, 'One Small Step v0.1', true, flags);
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
    ImGui_VerticalSpacer(ctx,5);

    -- Note length line
    reaper.ImGui_Text(ctx, "Note Length");
    reaper.ImGui_SameLine(ctx);
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(),      0, 0);
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemSpacing(),       2, 4);
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ItemInnerSpacing(),  0, 0);

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
          engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Streight);
        else
          engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Dotted);
        end
      end
    );
    ButtonGroupImageButton('note_triplet', nmod == engine_lib.NoteLenModifier.Triplet, function()
        if nmod == engine_lib.NoteLenModifier.Triplet then
          engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Streight);
        else
          engine_lib.setNoteLenModifier(engine_lib.NoteLenModifier.Triplet);
        end
      end
    );

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
    reaper.ShowMessageBox("Could not install One Small Step's helper FX on the track.\n\nIf you just installed One Small Step, please try to restart REAPER to let it refresh its JFSX repository.", "Oops !", 0);
    return;
  end

  ui_loop();
end

function stop()
  updateToolbarButtonState(0);
  reaper.ImGui_DestroyContext(ctx);
  engine_lib.atExit();
end

function start()
  updateToolbarButtonState(1);
  engine_lib.atStart();
  reaper.defer(loop);
end

start();

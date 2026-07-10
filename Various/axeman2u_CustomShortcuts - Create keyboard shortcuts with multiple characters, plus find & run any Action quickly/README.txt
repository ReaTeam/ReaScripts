@noindex

CustomShortcuts -- install & first run
=======================================

WHAT'S HERE
  CustomShortcuts_core.lua       shared library (don't run directly)
  CustomShortcuts_capture.lua    shared library (don't run directly)
  CustomShortcuts_Activate.lua   the only entry point you'll bind a shortcut to
  CustomShortcuts_Create.lua     shortcut editor -- reached FROM Activate, no shortcut needed

These four files must stay together in the same folder. The data file
(CustomShortcuts_data.lua) is created automatically next to them the
first time you click Save in Create mode -- don't create it by hand.

WHAT THIS DOES
  Activate mode opens a small always-on-top window bound to a REAPER
  shortcut of your choice -- the only shortcut you need to set up for
  this whole tool. While it's focused, it bypasses REAPER's own
  shortcuts: tap a modifier key (press and release, don't hold it while
  typing) to search by your own custom shortcut phrase, or just start
  typing to search by action name (like REAPER's Action List, including
  multi-word matching -- "track show" matches "Track: Show FX chain").
  Enter runs the top result and closes the window; double-clicking any
  row runs that one; Escape closes without running anything; pressing
  the same launch shortcut again closes the window. The first 10 results
  are always numbered 0-9 -- press Tab, then type that digit to run the
  corresponding row, no mouse needed. Click "Clear" to reset the search
  box with one click.

  Create mode is the shortcut editor: a table listing every action in a
  section you choose, showing REAPER's own native shortcut for reference
  and an editable custom shortcut column. You get to it by clicking
  "Edit Shortcuts..." inside Activate mode -- there's no separate REAPER
  shortcut to bind for it. Click a cell, tap one or more modifiers, then
  type a word, then press Enter to commit -- it'll automatically move on
  to the next row so you can work down the list quickly. Press Enter
  with nothing typed to clear a shortcut. If the phrase you typed is
  already used elsewhere in that section, a popup lets you steal it
  (with a follow-up offer to reassign the action that lost it) or go
  back and pick something else. Nothing is written to disk until you
  click Save. However you close this window (Save, Discard, or just
  closing it), Activate mode reopens automatically right after, so
  you're immediately ready to search for and run whatever you just
  assigned.

1. INSTALL THE DEPENDENCIES
   This tool needs two REAPER extensions, both installed the same way:

   a) Get ReaPack (REAPER's package manager), if you don't have it
      already:
        - Go to https://reapack.com and download the installer for your
          platform.
        - Quit REAPER first.
        - Run the installer (it drops a file into REAPER's resource
          folder) and follow its instructions.
        - Relaunch REAPER.

   b) With ReaPack installed, in REAPER's menu go to:
        Extensions > ReaPack > Browse packages...
      Then:
        - Search for "ReaImGui", select it, right-click > Install, OK.
        - Search for "js_ReaScriptAPI", select it, right-click > Install,
          OK.
        - Click "Apply" / OK to commit the installs.
        - Restart REAPER (required for extensions to load -- this step
          doesn't apply to ordinary scripts, but these are compiled
          extensions).

2. COPY THE FILES INTO PLACE
   - In REAPER: Options > Show REAPER resource path in explorer/finder.
   - Open the "Scripts" subfolder.
   - Copy this whole folder in there, e.g.:
       .../Scripts/CustomShortcuts/

3. LOAD ACTIVATE AS AN ACTION
   - In REAPER: Actions > Show action list.
   - Click "New action..." > "Load ReaScript...".
   - Select CustomShortcuts_Activate.lua.
   - It now appears in the action list (search "CustomShortcuts" to find
     it quickly). Do NOT try to load core.lua or capture.lua as actions
     -- they're shared libraries, not standalone scripts. You also don't
     need to manually load Create.lua -- clicking "Edit Shortcuts..."
     inside Activate registers it automatically the first time.

4. BIND ONE SHORTCUT
   - With the Activate action selected in the action list, click "Add"
     under Keyboard Shortcuts, press whatever key combo you want, OK.
   - That's the only shortcut this whole tool ever needs through
     REAPER's own system -- everything else lives inside it.

5. FIRST RUN
   - Trigger your new shortcut to open Activate.
   - Click "Edit Shortcuts..." to open the editor. It opens with the
     "Main" section tab selected and a (probably long) list of actions.
   - Click into an action's "Custom shortcut" cell, tap a modifier key
     (Cmd/Ctrl/Shift/Alt) and release it, then type a word, then press
     Enter to commit. Enter with nothing typed clears that row's
     shortcut instead.
   - Click Save when you're done -- nothing is written to disk before
     that. Closing this window (however you do it) reopens Activate.
   - Try it out: tap a modifier to search by shortcut, or just start
     typing to search by action name, then Enter or double-click to run.

IF SOMETHING DOESN'T WORK
  - Nothing happens at all when you run Activate: open REAPER's
    ReaScript console (View > ReaScript console output, or it opens
    automatically on an error) for error output -- most likely
    ReaImGui or js_ReaScriptAPI isn't actually installed, or REAPER
    hasn't been restarted since installing them. Re-check step 1.
  - Typing does nothing in the window: check the ReaScript console for
    JS_VKeys errors -- js_ReaScriptAPI may not have loaded (needs the
    REAPER restart from step 1b).
  - A Create-mode row shows "(none)" in Custom shortcut even though
    REAPER has a native shortcut for that action: auto-seed only fills
    in simple modifier(s)+single-character shortcuts (like Cmd+M). More
    complex native shortcuts (function keys, multi-character sequences,
    etc.) aren't auto-seeded -- just enter one yourself the normal way.
  - Keys stop responding system-wide, in other apps too: restart REAPER.
    Both scripts release their keyboard hook the instant they close,
    including on an unexpected error, so this shouldn't happen -- but
    restarting REAPER is the only way to clear it if it ever does.

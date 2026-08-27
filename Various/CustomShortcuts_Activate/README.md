# CustomShortcuts

A fast, searchable custom-shortcut system for REAPER that lives outside REAPER's
own keyboard shortcut list. Only one REAPER shortcut is ever needed, bound to
`CustomShortcuts_Activate.lua`.

## Requirements

- **ReaImGui** and **js_ReaScriptAPI**, both installable via ReaPack
  (Extensions > ReaPack > Browse packages).
- REAPER on Windows or macOS. (Linux uses the same SWELL-based keyboard layer
  as macOS internally, so it should behave like macOS below, but hasn't been
  tested.)

## Files

| File | Purpose |
|---|---|
| `CustomShortcuts_Activate.lua` | The everyday entry point. Bind your one REAPER shortcut to this. |
| `CustomShortcuts_Create.lua` | The shortcut editor. Opened via the "Edit Shortcuts..." button in Activate -- never needs its own bound shortcut. |
| `CustomShortcuts_core.lua` | Shared data/logic (sections, persistence, auto-seeding, action dispatch). |
| `CustomShortcuts_capture.lua` | Shared keyboard-capture engine (modifier-tap detection, text entry, platform-specific key handling). |
| `CustomShortcuts_data.lua` | Auto-generated. Holds your saved custom-shortcut phrases. Created/updated automatically -- see below. |

## Setup

1. Install ReaImGui and js_ReaScriptAPI via ReaPack if you haven't already.
2. Actions List > find "Script: CustomShortcuts_Activate.lua" > assign it a
   keyboard shortcut. This is the only REAPER shortcut you need.
3. Run it. A small search window opens.

## Using Activate mode

- **Tap a modifier** (Cmd/Ctrl/Shift/Opt, or a combination -- tap each one and
  release before typing) to search by your own custom shortcut phrase.
- **Type a letter first** to search action names instead, the same
  multi-word matching REAPER's own Action List uses.
- **Enter** runs the top result and closes the window. **Double-click** runs
  whichever row you clicked. **Escape** closes without running anything.
- The first 10 results are numbered -- **Tab** then a digit runs one without
  touching the mouse.
- Pressing your bound shortcut again while the window is open closes it
  (toggle).

## Using Create mode

Opened via "Edit Shortcuts..." in Activate. Lists every action in a section;
click a row's custom-shortcut cell and type a phrase the same way you would
in Activate (tap modifiers, then type a word). Press Enter to confirm a row
and move to the next, Escape to cancel editing that row.

**Auto-seeding:** if an action already has a simple native REAPER shortcut
(one or more modifiers plus a single character, e.g. `Cmd+M`) and no custom
phrase yet, Create (and Activate -- see below) fills it in automatically using
that same combination, translated into this system's phrase format.

**Saving:** typed edits are explicit -- nothing is written to disk until you
click Save (or close the window, which prompts if there are unsaved changes).
Auto-seeded values are the exception: since you never typed or confirmed
those yourself, they're written to disk immediately at the moment they're
seeded, with nothing for you to save.

## The data file

`CustomShortcuts_data.lua`, saved next to the scripts, is plain Lua (not
JSON) so it's readable/editable by hand in a pinch -- back it up first if you
do. Activate loads it fresh every launch; Create loads it once per session
and writes back explicit edits plus any auto-seeding it does itself.

**Activate creates and updates this file too, not just Create.** Every time
Activate runs, it auto-seeds and saves any missing custom shortcuts for the
current section (Main, plus whatever context is active, e.g. an open MIDI
editor) from REAPER's own native bindings -- so newly added REAPER shortcuts
become available here without ever needing to open Create. Two sections
(Media Explorer, MIDI Event List Editor) are only ever reachable by browsing
to them in Create, since Activate has no way to detect that context on its
own -- those two are seeded/saved by Create instead.

## Known REAPER interaction: Enter/Return sometimes needs two presses

If pressing Enter in Activate doesn't run the top result the first time, but
does on a second press, this is very likely **not a bug in this script** --
it's a collision with a native REAPER keyboard shortcut.

**What's happening:** REAPER's Main section, out of the box, often has
something bound to the bare Enter/Return key, and depending on how that
binding is scoped, REAPER can dispatch it as a **Global** shortcut -- meaning
it fires system-wide, regardless of which window has OS focus, through a
higher-priority path than normal keyboard input. js_ReaScriptAPI's key
interception (`JS_VKeys_Intercept`), which this script relies on to capture
keystrokes while its window is focused, cannot block a Global shortcut --
confirmed directly by the extension's author:

> "Global keystrokes override all other plugins, and AFAIK cannot temporarily
> be deactivated... Global keystrokes can be intercepted without getting
> passed through as long as they are not Global+text fields."

In practice this means the first Enter press gets consumed by REAPER's native
binding -- invisibly, since it happens before this script (or even ReaImGui
itself) ever sees the keystroke -- and only the second press reaches this
script normally.

**How to check/fix it:**

1. Open REAPER's Actions List, make sure the section is set to **Main**.
2. Look through the Key Shortcuts for whatever is bound to plain Enter/Return
   (no modifiers). Sorting or searching the shortcut column may help find it.
3. Check whether that binding is scoped as **Global**.
4. Either remove/rebind that native shortcut, or change its scope, depending
   on which behavior you'd rather keep. This is a REAPER keymap setting, not
   something this script can override or work around from ReaScript -- by
   design, Global shortcuts are meant to be unblockable.

## REAPER Preferences that affect ReaImGui window behavior

A couple of settings under **Options > Preferences > General > Advanced
UI/system tweaks** are worth knowing about if this script's window ever
behaves oddly:

- **Allow keyboard commands when mouse-editing** -- ReaImGui's own changelog
  documents a fix for "Alt key input while holding down a mouse button when
  'Allow keyboard commands when mouse-editing' is disabled" (Windows). If
  Alt/Opt-tap detection in this script ever seems to misbehave specifically
  while a mouse button is also held, check this setting.
- **HiDPI mode** -- affects how ReaImGui (and REAPER generally) scales on
  high-resolution displays. Shouldn't affect keyboard behavior, but can affect
  whether the window's size/position looks right.
- **Modal window positioning** -- affects where floating/utility windows like
  this one open on screen.

More generally: any REAPER preference that changes how keyboard shortcuts are
scoped or dispatched (Main vs. Global, per the Enter issue above) is the more
likely culprit for keyboard-specific oddities than anything under Advanced
UI/system tweaks, since those are mostly rendering/positioning related.

## Platform notes

- **Modifier labels** differ by OS to match what's actually printed on the
  key: Option shows as "Opt" on Mac, "Alt" on Windows. Phrases are stored
  using these labels, so a shortcut saved on one OS won't automatically match
  on the other if it uses this key -- re-save it on each machine you use.
- **Punctuation** in typed phrases/searches is handled differently per
  platform under the hood (Windows uses real hardware VK codes; Mac uses
  SWELL's ASCII-fallback behavior for punctuation keys) but should produce
  the same visible characters either way.

-- @noindex

--[[
 * @noindex

  CustomShortcuts_capture.lua

  Shared capture logic used by both Activate and Create:
    - VKeys-based bypass of REAPER's native shortcuts (via js_ReaScriptAPI),
      engaged/released based on window focus rather than open/close.
    - The "tap one or more modifiers, then type" shortcut-vs-search-mode
      detector.

  VK codes are read directly by code (state:byte(vk)), confirmed via live
  testing on macOS. Also confirmed empirically on macOS: physical Cmd
  reports through the slot Windows calls VK_CONTROL, and physical Ctrl
  reports through the slot Windows calls VK_LWIN (the Windows/Super key
  slot) -- Option/Alt and Shift match their standard Windows slots
  normally. Labels below reflect that, with a GetOS() check so this
  doesn't mislabel things on Windows.

  Modifier accumulation: each individual clean tap (a modifier, or several
  held together, then all released with nothing else pressed in between)
  ADDS to the running set of selected modifiers, rather than replacing it.
  That means "Ctrl+Shift+word" can be entered either by holding both at
  once and releasing them together, OR by tapping Ctrl, then separately
  tapping Shift -- both build the same combined set. The set locks in
  (stops accepting more taps) the moment you type the first letter.

  PrimeKeyState(): call it once, synchronously, before a script's main
  defer loop begins. Without it, the very first PollKeys() call has no
  baseline (prevState starts as nil), so any key still physically held
  down at that instant -- typically part of the very shortcut chord
  REAPER just used to launch the script -- reads as a brand new keypress.
  That's how e.g. a Cmd+Shift+A launch shortcut could leak a stray "A"
  into the search box the instant the window opened.
--]]

local M = {}

-- Standard virtual-key codes for these slots (values are stable across
-- platforms -- what varies is which *physical* key lands in which slot).
local VK_SHIFT   = 0x10
local VK_CONTROL = 0x11
local VK_MENU    = 0x12 -- Alt/Option
local VK_LWIN    = 0x5B
local VK_RWIN    = 0x5C

M.MODIFIER_VKEYS = { VK_SHIFT, VK_CONTROL, VK_MENU, VK_LWIN, VK_RWIN }

local isMac = reaper.GetOS():match("OSX") or reaper.GetOS():match("macOS")

if isMac then
  M.MODIFIER_LABELS = {
    [VK_SHIFT]   = "Shift",
    [VK_CONTROL] = "Cmd",  -- confirmed: physical Cmd reports here on macOS
    [VK_MENU]    = "Alt",  -- Option
    [VK_LWIN]    = "Ctrl", -- confirmed: physical Ctrl reports here on macOS
    [VK_RWIN]    = "Ctrl",
  }
else
  M.MODIFIER_LABELS = {
    [VK_SHIFT]   = "Shift",
    [VK_CONTROL] = "Ctrl",
    [VK_MENU]    = "Alt",
    [VK_LWIN]    = "Win",
    [VK_RWIN]    = "Win",
  }
end

-- Control keys we need to poll manually. IMPORTANT: while JS_VKeys_Intercept
-- is engaged, the key events never reach any window at all -- not even our
-- own ReaImGui window -- because the intercept happens at the OS hook
-- level, upstream of window messages entirely. That means ReaImGui's own
-- IsKeyPressed()/InputText() widgets see NOTHING while we're intercepting:
-- Enter, Escape, and Backspace all have to be polled here too, the same way
-- as the letter/digit keys, rather than relying on ImGui to notice them.
M.VK_BACK   = 0x08
M.VK_TAB    = 0x09
M.VK_RETURN = 0x0D
M.VK_ESCAPE = 0x1B
M.VK_DELETE = 0x2E
M.CONTROL_VKEYS = { M.VK_BACK, M.VK_TAB, M.VK_RETURN, M.VK_ESCAPE, M.VK_DELETE }

-- Printable character vkeys we care about capturing into the text buffer:
-- letters, digits, space. (Punctuation deliberately excluded to keep
-- shortcuts to clean words -- add more here if you want it.)
local function buildTextVkeys()
  local t = {}
  for vk = 0x41, 0x5A do t[#t + 1] = vk end -- A-Z
  for vk = 0x30, 0x39 do t[#t + 1] = vk end -- 0-9
  t[#t + 1] = 0x20 -- space
  return t
end
M.TEXT_VKEYS = buildTextVkeys()

local function vkeyToChar(vk)
  if vk == 0x20 then return " " end
  if vk >= 0x41 and vk <= 0x5A then return string.char(vk) end -- 'A'-'Z' -> upper; caller lowercases if desired
  if vk >= 0x30 and vk <= 0x39 then return string.char(vk) end
  return nil
end
M.VkeyToChar = vkeyToChar

-- ---------------------------------------------------------------------
-- VKeys bypass (js_ReaScriptAPI)
-- ---------------------------------------------------------------------

local intercepting = false

function M.SetFocused(isFocused)
  if isFocused and not intercepting then
    reaper.JS_VKeys_Intercept(-1, 1)
    intercepting = true
  elseif not isFocused and intercepting then
    reaper.JS_VKeys_Intercept(-1, -1)
    intercepting = false
  end
end

-- MUST be called from the script's reaper.atexit handler, as the very
-- first thing it does, before any other cleanup. If this doesn't run,
-- the intercepted keys stay blocked system-wide (every app, not just
-- REAPER) until REAPER is restarted.
function M.ReleaseAll()
  if intercepting then
    reaper.JS_VKeys_Intercept(-1, -1)
    intercepting = false
  end
end

-- ---------------------------------------------------------------------
-- Key-state polling with edge detection
-- ---------------------------------------------------------------------

local prevState = nil

-- vk's that were already down the moment PrimeKeyState() ran -- normally
-- the modifier(s) from the very shortcut that just launched this script
-- (e.g. Cmd+Shift in a Cmd+Shift+A binding). Each is removed from this
-- set the FIRST time it's subsequently observed being released, and that
-- one "grace release" is NOT allowed to complete a tap -- it's just the
-- natural release of the launch chord, not a deliberate search gesture.
-- After that one grace release, the key behaves completely normally.
local residualModifiers = {}

local function isDown(state, vk)
  if not state then return false end
  if vk < 1 then return false end
  -- Confirmed via live testing: byte N (1-indexed, Lua string convention)
  -- holds the state for VK code N directly -- no +1 needed.
  local b = state:byte(vk)
  return b ~= nil and b ~= 0
end

-- Call ONCE, synchronously, right when the script starts -- before the
-- main defer loop begins (and before the window is shown). Primes the
-- edge-detection baseline with whatever keys are ALREADY down at that
-- instant, which typically still includes the modifier+letter combo the
-- user just used to invoke this very script via its REAPER shortcut
-- binding. Without this, the first real PollKeys() call has nothing to
-- compare against (prevState is nil), so an already-held key reads as a
-- brand new press. Also records which modifiers are part of that residue
-- (see residualModifiers above).
function M.PrimeKeyState()
  prevState = reaper.JS_VKeys_GetState(0)
  residualModifiers = {}
  for _, vk in ipairs(M.MODIFIER_VKEYS) do
    if isDown(prevState, vk) then
      residualModifiers[vk] = true
    end
  end
end

-- Call once per frame. Returns a table: { down = {[vk]=true,...}, pressed
-- = {[vk]=true,...} (down this frame, up last frame), released = {...} }
function M.PollKeys()
  local state = reaper.JS_VKeys_GetState(0)
  local down, pressed, released = {}, {}, {}

  local function check(vk)
    local nowDown = isDown(state, vk)
    local wasDown = isDown(prevState, vk)
    if nowDown then down[vk] = true end
    if nowDown and not wasDown then pressed[vk] = true end
    if wasDown and not nowDown then released[vk] = true end
  end

  for _, vk in ipairs(M.MODIFIER_VKEYS) do check(vk) end
  for _, vk in ipairs(M.TEXT_VKEYS) do check(vk) end
  for _, vk in ipairs(M.CONTROL_VKEYS) do check(vk) end

  prevState = state
  return { down = down, pressed = pressed, released = released }
end

-- ---------------------------------------------------------------------
-- Capture state machine
--
-- Usage: call NewCaptureState() once, then Update(state, keys) every
-- frame UNCONDITIONALLY -- don't skip frames where nothing is down; the
-- release that completes a modifier tap happens on exactly that kind of
-- frame. Inspect state.mode / state.text / state.heldModifierAtTap.
--
-- mode: "idle"     -- nothing entered yet this "session" (since last Reset)
--       "shortcut" -- at least one modifier has been tapped; still
--                     collecting more modifier taps, or building the word
--                     once text starts
--       "search"   -- a text key came first; building an action-name search
-- ---------------------------------------------------------------------

local MAX_SHORTCUT_LEN = 18

function M.NewCaptureState()
  return {
    mode = "idle",
    text = "",
    heldModifierAtTap = nil,  -- combined label string, e.g. "Ctrl+Shift"
    selectedModifiers = {},   -- persistent accumulated set of modifier vkeys
    tappedModifiers = {},     -- vkeys currently down since THIS tap sequence started
    anyOtherKeyDuringHold = false,
  }
end

function M.Reset(state)
  state.mode = "idle"
  state.text = ""
  state.heldModifierAtTap = nil
  state.selectedModifiers = {}
  state.tappedModifiers = {}
  state.anyOtherKeyDuringHold = false
end

local function recomputeLabel(state)
  local labels = {}
  for vk in pairs(state.selectedModifiers) do
    labels[#labels + 1] = M.MODIFIER_LABELS[vk] or "?"
  end
  table.sort(labels)
  state.heldModifierAtTap = table.concat(labels, "+")
end

-- Returns true if the text buffer changed (caller can use this to know
-- when to re-run the search filter).
function M.Update(state, keys)
  local changed = false

  -- Still allowed to add more modifier taps as long as nothing's been
  -- typed yet -- true whether this is the very first tap (mode "idle")
  -- or a later one (mode already "shortcut" from an earlier tap).
  local canStillCollectModifiers = (state.mode == "idle") or (state.mode == "shortcut" and state.text == "")

  -- Track by keys.down (currently held), not keys.pressed (fresh edge
  -- this frame), so a modifier already held on the very first polled
  -- frame (e.g. still physically down from the Cmd+Shift+A chord that
  -- just launched this script) still counts toward a tap -- its press
  -- edge was "consumed" by PrimeKeyState() so it wouldn't leak a stray
  -- letter into search, but that shouldn't also stop it from completing
  -- a tap. EXCEPT: skip residual modifiers entirely here -- see below,
  -- their first release is a no-op grace period, not a real tap.
  for _, vk in ipairs(M.MODIFIER_VKEYS) do
    if keys.down[vk] and not residualModifiers[vk] then
      state.tappedModifiers[vk] = true
    end
  end

  -- A residual modifier (still down from the launch shortcut itself)
  -- gets exactly one "grace release" that does NOT count as a completed
  -- tap -- it's just the natural release of the keys used to open this
  -- window, not a deliberate search gesture. After this, it's cleared
  -- and behaves like any other modifier from here on.
  for _, vk in ipairs(M.MODIFIER_VKEYS) do
    if residualModifiers[vk] and keys.released[vk] then
      residualModifiers[vk] = nil
    end
  end

  local anyModifierHeld = false
  for _, vk in ipairs(M.MODIFIER_VKEYS) do
    if keys.down[vk] then anyModifierHeld = true end
  end
  if anyModifierHeld then
    for _, vk in ipairs(M.TEXT_VKEYS) do
      if keys.pressed[vk] then state.anyOtherKeyDuringHold = true end
    end
    -- a second (or third) distinct modifier held together counts as part
    -- of the same chord tap, not a disqualifier.
  end

  local stillAnyModifierHeld = false
  for _, vk in ipairs(M.MODIFIER_VKEYS) do
    if keys.down[vk] then stillAnyModifierHeld = true end
  end
  local releasedAModifier = false
  for _, vk in ipairs(M.MODIFIER_VKEYS) do
    if keys.released[vk] then releasedAModifier = true end
  end

  if releasedAModifier and not stillAnyModifierHeld then
    if canStillCollectModifiers and not state.anyOtherKeyDuringHold and next(state.tappedModifiers) ~= nil then
      -- Merge this tap's modifiers into the running set (doesn't replace
      -- what was already collected from an earlier, separate tap).
      for vk in pairs(state.tappedModifiers) do
        state.selectedModifiers[vk] = true
      end
      state.mode = "shortcut"
      recomputeLabel(state)
    end
    state.tappedModifiers = {}
    state.anyOtherKeyDuringHold = false
  end

  -- Text keys: append to buffer (only meaningful once we're not idle,
  -- or to kick off "search" mode if idle and this is the first input).
  for _, vk in ipairs(M.TEXT_VKEYS) do
    if keys.pressed[vk] then
      if state.mode == "idle" then
        state.mode = "search"
      end
      if #state.text < MAX_SHORTCUT_LEN or state.mode == "search" then
        local ch = vkeyToChar(vk)
        if ch then
          local isShift = keys.down[VK_SHIFT]
          if not isShift then ch = ch:lower() end
          state.text = state.text .. ch
          changed = true
        end
      end
    end
  end

  -- Backspace: trims the buffer. If that empties it back to nothing while
  -- in "shortcut" mode, the modifier set stays intact (you can keep
  -- adding more modifier taps or just retype the word) -- only a full
  -- Reset() clears the modifier set itself.
  if keys.pressed[M.VK_BACK] and #state.text > 0 then
    state.text = state.text:sub(1, -2)
    changed = true
  end

  return changed
end

-- Render state.text yourself as a plain Text widget (not an ImGui
-- InputText) -- see the note above about why ImGui widgets don't receive
-- keystrokes while the intercept is active. Enter/Escape should be read
-- by the caller directly off keys.pressed[capture.VK_RETURN] /
-- keys.pressed[capture.VK_ESCAPE] each frame, same reasoning.

return M

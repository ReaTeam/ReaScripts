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

-- Exposed so callers outside this module (e.g. Create.lua's own direct
-- key-to-text loop) can check shift state the same way capture.Update()
-- does internally, without duplicating the raw VK code.
M.VK_SHIFT = VK_SHIFT
-- Exposed so callers can look up this key's correct platform label (e.g.
-- "Opt" on Mac, "Alt" on Windows) via M.MODIFIER_LABELS[M.VK_MENU]
-- instead of hardcoding either name themselves.
M.VK_MENU = VK_MENU

local osStr = reaper.GetOS()
local isMac = osStr:match("OSX") or osStr:match("macOS")
-- Deliberately "is it Windows" rather than "is it Mac", so an
-- unanticipated third platform (Linux) defaults to the SWELL/ASCII-
-- fallback behavior below, which is the SWELL-based one of the two.
local isWindows = osStr:match("Win") ~= nil

-- ---------------------------------------------------------------------
-- Punctuation vkeys -- genuinely platform-different, not a layout guess.
--
-- On WINDOWS, JS_VKeys_GetState reads real hardware VK codes directly,
-- and Windows has proper named constants for punctuation (the VK_OEM_*
-- range, 0xBA-0xDE) -- documented by Microsoft, confirmed correct. One
-- physical key = one fixed code regardless of Shift, same model as
-- letters/digits; Shift is tracked separately and picks which of the
-- two characters that key means.
--
-- On MAC (and presumably Linux), js_ReaScriptAPI rides on SWELL, whose
-- own header documents SWELL_MacKeyToWindowsKey() as returning "a
-- windows VK_ keycode (OR ASCII)" -- i.e. for punctuation keys SWELL
-- hasn't given a dedicated VK_OEM_* slot to, it just reports the literal
-- ASCII code of whatever character the OS says that keystroke produced,
-- ALREADY reflecting Shift. That's not a per-key guess, it's the
-- documented fallback mechanism, and it explains the period/Delete bug
-- directly: ASCII "." is 46 (0x2E) -- the exact number this file had
-- already claimed for VK_DELETE. So on Mac, punctuation vkeys are read
-- as themselves (no separate shift lookup needed -- the OS already did
-- that part), and VK_DELETE is retired there entirely rather than risk
-- it colliding with whatever else lands on 0x2E (Backspace already
-- covers "delete text," and the on-screen Clear button still works).
-- ---------------------------------------------------------------------

-- Windows-only: real VK_OEM_* constants, { unshifted, shifted } per key.
local OEM_CHARS = {
  [0xBA] = { ";",  ":" },  -- VK_OEM_1
  [0xBB] = { "=",  "+" },  -- VK_OEM_PLUS
  [0xBC] = { ",",  "<" },  -- VK_OEM_COMMA
  [0xBD] = { "-",  "_" },  -- VK_OEM_MINUS
  [0xBE] = { ".",  ">" },  -- VK_OEM_PERIOD
  [0xBF] = { "/",  "?" },  -- VK_OEM_2
  [0xC0] = { "`",  "~" },  -- VK_OEM_3
  [0xDB] = { "[",  "{" },  -- VK_OEM_4
  [0xDC] = { "\\", "|" },  -- VK_OEM_5
  [0xDD] = { "]",  "}" },  -- VK_OEM_6
  [0xDE] = { "'",  "\"" }, -- VK_OEM_7
}
local OEM_VKEYS = {}
for vk in pairs(OEM_CHARS) do OEM_VKEYS[#OEM_VKEYS + 1] = vk end

-- Mac/Linux-only: every printable-ASCII punctuation code (everything in
-- 0x21-0x7E that isn't a letter, digit, or modifier -- which are handled
-- separately). Built programmatically rather than hand-listed since
-- these ARE just their own ASCII values here -- e.g. vk 44 IS "," already.
-- IMPORTANT: the modifier exclusion is not optional -- VK_LWIN (0x5B)
-- and VK_RWIN (0x5C), which is where physical Ctrl reports on Mac (see
-- MODIFIER_LABELS above), fall inside this same numeric range as ASCII
-- "[" and "\". Without excluding them, tapping Ctrl also got read as
-- typing "[", which kicked capture straight into "search" mode instead
-- of registering as a modifier tap -- exactly what broke shortcut entry.
local MODIFIER_VKEY_SET = {}
for _, vk in ipairs(M.MODIFIER_VKEYS) do MODIFIER_VKEY_SET[vk] = true end

local MAC_ASCII_PUNCT_VKEYS = {}
for vk = 0x21, 0x7E do
  local isLetter = vk >= 0x41 and vk <= 0x5A
  local isDigit = vk >= 0x30 and vk <= 0x39
  if not isLetter and not isDigit and not MODIFIER_VKEY_SET[vk] then
    MAC_ASCII_PUNCT_VKEYS[#MAC_ASCII_PUNCT_VKEYS + 1] = vk
  end
end

-- Shifted symbols on the digit row (US layout), e.g. Shift+1 -> "!").
-- WINDOWS ONLY -- on Mac, shifted digit-row symbols come through the
-- ASCII-fallback path above instead (their own distinct ASCII codes),
-- same reasoning as the rest of punctuation.
local SHIFT_DIGIT_CHARS = {
  [0x30] = ")", [0x31] = "!", [0x32] = "@", [0x33] = "#", [0x34] = "$",
  [0x35] = "%", [0x36] = "^", [0x37] = "&", [0x38] = "*", [0x39] = "(",
}

if isMac then
  M.MODIFIER_LABELS = {
    [VK_SHIFT]   = "Shift",
    [VK_CONTROL] = "Cmd",  -- confirmed: physical Cmd reports here on macOS
    [VK_MENU]    = "Opt",  -- Option key -- "Alt" is the Windows name for this slot
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
-- Real, reliable Forward-Delete code on Windows. On Mac, this same
-- number (0x2E) is where ASCII "." also lands (see above) -- rather
-- than have period silently clear the search field, Delete-as-Clear is
-- retired on Mac. -1 is a safe "never matches" sentinel: isDown() below
-- explicitly treats any vk < 1 as always-up.
M.VK_DELETE = isWindows and 0x2E or -1
M.CONTROL_VKEYS = { M.VK_BACK, M.VK_TAB, M.VK_RETURN, M.VK_ESCAPE, M.VK_DELETE }

-- Printable character vkeys we care about capturing into the text
-- buffer: letters, digits, space, plus punctuation via whichever of the
-- two platform-specific lists above actually applies.
local function buildTextVkeys()
  local t = {}
  for vk = 0x41, 0x5A do t[#t + 1] = vk end -- A-Z
  for vk = 0x30, 0x39 do t[#t + 1] = vk end -- 0-9
  t[#t + 1] = 0x20 -- space
  local punctSource = isWindows and OEM_VKEYS or MAC_ASCII_PUNCT_VKEYS
  for _, vk in ipairs(punctSource) do t[#t + 1] = vk end
  return t
end
M.TEXT_VKEYS = buildTextVkeys()

-- isShift picks the shifted variant where the key produces a different
-- symbol under Shift. For letters and (on Windows) digits/punctuation,
-- one physical key reports one fixed code and Shift is read fresh off
-- keys.down every time, REGARDLESS of capture mode or how much text is
-- already typed -- unlike the other modifiers (which only matter for
-- the tap-to-build-a-shortcut-prefix system and stop mattering once
-- text has started), Shift's normal keyboard job never turns off. On
-- Mac, punctuation is the exception: the vk itself already reflects
-- Shift (see MAC_ASCII_PUNCT_VKEYS above), so isShift is simply ignored
-- for that branch -- passing it again would double-apply it.
local function vkeyToChar(vk, isShift)
  if vk == 0x20 then return " " end
  if vk >= 0x41 and vk <= 0x5A then -- A-Z
    return isShift and string.char(vk) or string.char(vk + 32)
  end
  if vk >= 0x30 and vk <= 0x39 then -- 0-9
    if isWindows and isShift then return SHIFT_DIGIT_CHARS[vk] end
    return string.char(vk)
  end
  if isWindows then
    local oem = OEM_CHARS[vk]
    if oem then return isShift and oem[2] or oem[1] end
    return nil
  else
    if vk >= 0x21 and vk <= 0x7E then return string.char(vk) end
    return nil
  end
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
        local isShift = keys.down[VK_SHIFT]
        local ch = vkeyToChar(vk, isShift)
        if ch then
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

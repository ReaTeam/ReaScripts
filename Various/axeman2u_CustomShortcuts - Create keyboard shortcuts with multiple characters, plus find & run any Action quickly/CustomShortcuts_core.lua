-- @noindex

--[[
 * @noindex

  CustomShortcuts_core.lua

  Shared library for the custom shortcut system. Both entry-point scripts
  (Activate and Create) require() this file. Nothing in here opens a window
  or runs a UI loop -- it's pure data/logic so both scripts stay in sync.

  Depends on: ReaImGui, js_ReaScriptAPI (checked by the entry-point scripts,
  not here).
--]]

local M = {}

-- ---------------------------------------------------------------------
-- Sections
-- ---------------------------------------------------------------------
-- NOTE: "MIDI Inline Editor" (section 32062) is intentionally left out.
-- There is no known API call that can dispatch an action into that specific
-- context, so custom shortcuts for it would be unrunnable. If that turns
-- out to be wrong, it can be added back in.
M.SECTIONS = {
  { id = 0,     name = "Main" },
  { id = 100,   name = "Main (alt recording)" },
  { id = 32060, name = "MIDI Editor" },
  { id = 32061, name = "MIDI Event List Editor" },
  { id = 32063, name = "Media Explorer" },
}

M.SECTION_MAIN = 0
M.SECTION_MAIN_ALT = 100
M.SECTION_MIDI_EDITOR = 32060
M.SECTION_MIDI_EVENTLIST = 32061
M.SECTION_MEDIA_EXPLORER = 32063

function M.SectionName(id)
  for _, s in ipairs(M.SECTIONS) do
    if s.id == id then return s.name end
  end
  return "Unknown (" .. tostring(id) .. ")"
end

-- ---------------------------------------------------------------------
-- Paths
-- ---------------------------------------------------------------------
-- Use this file's OWN location (not reaper.get_action_context(), which
-- describes whichever script is running as an action, not necessarily
-- reliable to call from inside a required module) -- core.lua always
-- lives in the same folder as both entry-point scripts.
local selfInfo = debug.getinfo(1, "S")
M.SCRIPT_DIR = selfInfo.source:match("^@(.*[/\\])") or (reaper.GetResourcePath() .. "/Scripts/CustomShortcuts/")
M.DATA_FILE = M.SCRIPT_DIR .. "CustomShortcuts_data.lua"
M.ACTIVATE_SCRIPT = M.SCRIPT_DIR .. "CustomShortcuts_Activate.lua"
M.CREATE_SCRIPT = M.SCRIPT_DIR .. "CustomShortcuts_Create.lua"

-- ---------------------------------------------------------------------
-- Persistent command-ID resolution
--
-- kbd_enumerateActions gives back a numeric command ID that is only valid
-- for the current REAPER session -- ReaScript/custom-action numeric IDs are
-- reassigned on every restart. To store something in a file that's still
-- correct next week, native (built-in) actions can use their raw numeric ID
-- directly (those ARE stable across restarts), but scripts/custom actions
-- need their string identifier instead, reconstructed via
-- ReverseNamedCommandLookup.
-- ---------------------------------------------------------------------

-- Returns (persistentIdString, isNative)
function M.GetPersistentId(cmdId)
  local lookup = reaper.ReverseNamedCommandLookup(cmdId)
  if lookup == nil then
    return tostring(cmdId), true
  else
    return "_" .. lookup, false
  end
end

-- Turns a persistent ID string back into a session-valid numeric command ID.
-- Returns nil if it can no longer be resolved (e.g. the script/extension
-- that provided it was removed).
function M.ResolveRuntimeId(persistentId)
  if not persistentId or persistentId == "" then return nil end
  if persistentId:sub(1, 1) == "_" then
    local id = reaper.NamedCommandLookup(persistentId)
    if id == 0 then return nil end
    return id
  else
    return tonumber(persistentId)
  end
end

-- ---------------------------------------------------------------------
-- Action enumeration
-- ---------------------------------------------------------------------

-- Returns an array of { cmdId = <session-valid numeric id>, name = <string> }
-- for every action registered in the given section.
function M.EnumerateSectionActions(sectionId)
  local actions = {}
  local idx = 0
  while true do
    local cmdId, name = reaper.kbd_enumerateActions(sectionId, idx)
    if not cmdId or cmdId == 0 then break end
    actions[#actions + 1] = { cmdId = cmdId, name = name }
    idx = idx + 1
  end
  return actions
end

-- ---------------------------------------------------------------------
-- Native REAPER shortcuts (read-only reference / seed source)
-- ---------------------------------------------------------------------

-- Returns an array of shortcut description strings REAPER already has
-- bound to this command in this section (usually 0 or 1 entries, but an
-- action can have more than one).
function M.GetNativeShortcuts(sectionId, cmdId)
  local out = {}
  local ok, count = pcall(reaper.CountActionShortcuts, sectionId, cmdId)
  if not ok or not count then return out end
  for i = 0, count - 1 do
    local ok2, retval, desc = pcall(reaper.GetActionShortcutDesc, sectionId, cmdId, i)
    if ok2 and retval and desc and desc ~= "" then
      out[#out + 1] = desc
    end
  end
  return out
end

-- ---------------------------------------------------------------------
-- Action dispatch (varies by section)
-- ---------------------------------------------------------------------

-- Returns true if a MIDI editor is currently open (regardless of whether
-- it's frontmost).
function M.GetActiveMidiEditor()
  return reaper.MIDIEditor_GetActive()
end

-- Attempts to find the Media Explorer window via js_ReaScriptAPI.
-- Returns nil if it's not open or js_ReaScriptAPI isn't available.
function M.GetMediaExplorerWindow()
  if not reaper.JS_Window_Find then return nil end
  return reaper.JS_Window_Find("Media Explorer", true)
end

-- Runs the given action. sectionId + cmdId must both be session-valid
-- (i.e. already resolved via ResolveRuntimeId if they came from disk).
-- Returns true/false for whether it was actually able to dispatch it.
function M.RunAction(sectionId, cmdId)
  if not cmdId then return false end

  if sectionId == M.SECTION_MAIN or sectionId == M.SECTION_MAIN_ALT then
    reaper.Main_OnCommand(cmdId, 0)
    return true

  elseif sectionId == M.SECTION_MIDI_EDITOR or sectionId == M.SECTION_MIDI_EVENTLIST then
    local editor = M.GetActiveMidiEditor()
    if not editor then return false end
    reaper.MIDIEditor_OnCommand(editor, cmdId)
    return true

  elseif sectionId == M.SECTION_MEDIA_EXPLORER then
    local wnd = M.GetMediaExplorerWindow()
    if not wnd or not reaper.JS_Window_OnCommand then return false end
    reaper.JS_Window_OnCommand(wnd, cmdId)
    return true
  end

  return false
end

-- Is the given section currently "reachable" -- i.e. is there actually a
-- window open right now that an action in this section could run against?
-- Main is always reachable. Used to filter search results so we never show
-- something the user can't currently execute.
function M.IsSectionActive(sectionId)
  if sectionId == M.SECTION_MAIN or sectionId == M.SECTION_MAIN_ALT then
    return true
  elseif sectionId == M.SECTION_MIDI_EDITOR or sectionId == M.SECTION_MIDI_EVENTLIST then
    return M.GetActiveMidiEditor() ~= nil
  elseif sectionId == M.SECTION_MEDIA_EXPLORER then
    return M.GetMediaExplorerWindow() ~= nil
  end
  return false
end

-- Snapshot "what context is REAPER in right now" -- must be called BEFORE
-- your ReaImGui window is created/focused, since after that point the
-- foreground window is your script, not REAPER's, and this signal is lost.
-- Returns the specific section id if one is active, else Main.
--
-- SIMPLIFICATION: this treats "a MIDI editor is open at all" as the
-- signal, rather than confirming it's specifically the frontmost/focused
-- window at this instant. If you have a MIDI editor open in the
-- background while working in the arrange view, this will still prefer
-- the MIDI editor section.
function M.SnapshotActiveSection()
  local editor = M.GetActiveMidiEditor()
  if editor then
    return M.SECTION_MIDI_EDITOR
  end
  return M.SECTION_MAIN
end

-- ---------------------------------------------------------------------
-- Data file (plain Lua table, not JSON -- no parser needed, and it's
-- human-readable/editable in a pinch)
--
-- Shape:
-- {
--   [sectionId] = {
--     shortcuts = {
--       ["punch out"] = { id = "_RS1a2b3c...", name = "Transport: ..." },
--       ...
--     }
--   },
--   ...
-- }
-- ---------------------------------------------------------------------

local function serialize(val, indent)
  indent = indent or ""
  local t = type(val)
  if t == "string" then
    return string.format("%q", val)
  elseif t == "number" or t == "boolean" then
    return tostring(val)
  elseif t == "table" then
    local child_indent = indent .. "  "
    local parts = {}
    for k, v in pairs(val) do
      local key_str
      if type(k) == "number" then
        key_str = "[" .. k .. "]"
      else
        key_str = "[" .. string.format("%q", tostring(k)) .. "]"
      end
      parts[#parts + 1] = child_indent .. key_str .. " = " .. serialize(v, child_indent)
    end
    if #parts == 0 then return "{}" end
    return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
  else
    return "nil"
  end
end

function M.SaveData(data)
  local f, err = io.open(M.DATA_FILE, "w")
  if not f then return false, err end
  f:write("-- Auto-generated by CustomShortcuts. Editable by hand if needed,\n")
  f:write("-- but back it up before doing so.\n")
  f:write("return " .. serialize(data) .. "\n")
  f:close()
  return true
end

function M.LoadData()
  local f = io.open(M.DATA_FILE, "r")
  if not f then
    return { }
  end
  f:close()
  local chunk, err = loadfile(M.DATA_FILE)
  if not chunk then
    reaper.ShowConsoleMsg("CustomShortcuts: failed to parse data file: " .. tostring(err) .. "\n")
    return { }
  end
  local ok, result = pcall(chunk)
  if not ok or type(result) ~= "table" then
    reaper.ShowConsoleMsg("CustomShortcuts: data file did not evaluate to a table\n")
    return { }
  end
  return result
end

-- Ensures data.sections style access always works even for a brand new file.
function M.EnsureSection(data, sectionId)
  if not data[sectionId] then
    data[sectionId] = { shortcuts = {} }
  end
  if not data[sectionId].shortcuts then
    data[sectionId].shortcuts = {}
  end
  return data[sectionId]
end

-- ---------------------------------------------------------------------
-- Search matching
-- ---------------------------------------------------------------------

-- Combines a capture state's tapped-modifier label and typed word into
-- the single phrase format used for storage/lookup (e.g. "Cmd+punch").
-- Works for either Activate's live captureState or Create's per-row
-- editCapture -- both share the same { heldModifierAtTap, text } shape.
function M.CombinedPhrase(captureState)
  if not captureState or captureState.text == "" then return "" end
  if captureState.heldModifierAtTap and captureState.heldModifierAtTap ~= "" then
    return captureState.heldModifierAtTap .. "+" .. captureState.text
  end
  return captureState.text
end

-- REAPER Action List style matching: splits `needle` on whitespace into
-- separate words and requires EVERY word to appear somewhere in
-- `haystack` (case-insensitive, any order) -- so typing "track show"
-- matches "Track: Show FX chain", same as typing the same words into
-- REAPER's own Action List would. Returns a score for ranking (0 = no
-- match, higher = a "better" match) rather than just a boolean, so
-- callers that want a sensible "top result" (e.g. Enter-to-run) can sort
-- by it; callers that just want a filter can simply check `> 0`.
-- `needle` should already be lowercase; `haystack` doesn't need to be.
function M.ScoreNameMatch(haystack, needle)
  if needle == "" then return 0 end
  local h = haystack:lower()
  local words = {}
  for w in needle:gmatch("%S+") do words[#words + 1] = w end
  if #words == 0 then return 0 end

  for _, w in ipairs(words) do
    if not h:find(w, 1, true) then return 0 end
  end

  if h == needle then return 4 end
  if h:find(needle, 1, true) == 1 then return 3 end
  if h:find(words[1], 1, true) == 1 then return 2 end
  return 1
end

-- ---------------------------------------------------------------------
-- Cross-script coordination (mutual shutdown)
-- ---------------------------------------------------------------------

-- Resolves a sibling script's command ID (registers it if it isn't
-- registered yet -- idempotent, safe to call every time).
function M.GetSiblingCommandId(scriptPath, sectionId)
  return reaper.AddRemoveReaScript(true, sectionId or 0, scriptPath, true)
end

-- If the sibling script is currently running (as a toggle action via
-- set_action_options(1)), invoke it once to make REAPER terminate it.
-- Does nothing if it's not running, so this is always safe to call.
function M.ShutDownSiblingIfRunning(scriptPath, sectionId)
  sectionId = sectionId or 0
  local cmdId = M.GetSiblingCommandId(scriptPath, sectionId)
  if not cmdId or cmdId == 0 then return end
  local state = reaper.GetToggleCommandStateEx(sectionId, cmdId)
  if state == 1 then
    reaper.Main_OnCommand(cmdId, 0)
  end
end

return M

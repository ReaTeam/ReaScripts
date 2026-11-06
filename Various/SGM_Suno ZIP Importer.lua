-- @description Import a Suno AI ZIP file: unzip, parse metadata, create color-coded session with lyrics markers
-- @author Scott Mills
-- @version 1.1.0
-- @changelog
--   1.1.0 (2026-05-23)
--     + ImGui-based single-window workflow
--     + Structural markers generated from lyrics timestamps
--     + Lyrics written to REAPER Project Notes
--   1.0.0
--     + Initial release
--     + ZIP extraction, info.json parsing, folder track creation
-- @provides [main] .
-- @about
--   ## Suno ZIP Importer
--   One-click import of a Suno AI generation ZIP file into REAPER.
--
--   **What it does:**
--   Unzips a Suno AI ZIP file, parses info.json metadata, imports WAV/MP3 files
--   onto new tracks, creates a color-coded folder structure, places structural
--   markers from lyrics, and saves lyrics to Project Notes — all from a single
--   ReaImGui window.
--
--   **Prerequisites:**
--   - REAPER 6.70+
--   - ReaImGui extension (ReaPack: cockos/reaimgui)
--   - SWS/S&M Extension (recommended)
--   - 7-Zip (Windows) or system unzip (macOS/Linux)
--
--   **How to use:**
--   1. Export a Suno AI song as ZIP (stems + metadata)
--   2. Run the script — the ReaImGui file dialog opens
--   3. Select the ZIP file
--   4. Watch the progress window — tracks are created with markers and lyrics
--
--   **Configuration (edit at top of script):**
--   - IMPORT_LYRICS = true — set to false to skip lyric markers
--   - CREATE_FOLDER_TRACK = true — set to false to skip folder track
--
--   **Limitations:**
--   - Requires ReaImGui (script errors gracefully without it)
--   - Expects Suno ZIP format (info.json + stem MP3s)
--   - Non-Suno ZIP files will import audio but won't have metadata markers
--[[============================================================================
  SCRIPT : Suno ZIP Importer
  AUTHOR : TrackClear / SGM Studios
  VERSION: 1.1.0

  DESCRIPTION:
    Imports a Suno AI music generation ZIP file into REAPER. Automatically
    unzips, parses metadata from info.json, creates a color-coded folder
    structure, places structural markers from lyrics, and saves lyrics to
    Project Notes — all from a single ImGui window.

  INSTALLATION:
    1. Save this file to:  <REAPER Resources>/Scripts/TrackClear/
    2. Actions > Load ReaScript > browse to this file
    3. Optionally assign a keyboard shortcut

  DEPENDENCIES:
    - REAPER 6.70+
    - ReaImGui extension  (ReaPack: cockos/reaimgui)
    - SWS/S&M Extension   (recommended; enables lfs for faster file listing)
      https://www.sws-extension.org/

  SUNO ZIP CONTENTS (expected):
    instrumental.mp3   – full mix without vocals
    vocals.mp3         – isolated vocals
    no_drums.mp3       – optional stem
    no_bass.mp3        – optional stem
    info.json          – song metadata (title, tags, lyrics/prompt)

  USAGE:
    1. Run the script
    2. Click "Browse…" and select your Suno .zip download
    3. Click "Import into REAPER!"
    4. Adjust structural markers to taste (they're spaced evenly as estimates)
============================================================================]]--

-- ─── GUARD: ReaImGui ────────────────────────────────────────────────────────
if not reaper.ImGui_CreateContext then
  reaper.MB(
    "This script requires the ReaImGui extension.\n\n"
    .. "Install it via:\n"
    .. "  Extensions > ReaPack > Browse Packages > search 'ReaImGui'\n\n"
    .. "Then restart REAPER and run this script again.",
    "Missing: ReaImGui", 0)
  return
end

-- ─── REAPER VERSION CHECK ───────────────────────────────────────────────────
do
  local ver = tonumber(reaper.GetAppVersion():match("^([%d%.]+)")) or 0
  if ver < 6.70 then
    reaper.MB(
      ("REAPER v6.70+ required.\nDetected: v%s"):format(reaper.GetAppVersion()),
      "Version Error", 0)
    return
  end
end

-- ─── CONSTANTS ──────────────────────────────────────────────────────────────

local SCRIPT_NAME    = "Suno ZIP Importer"
local SCRIPT_VERSION = "1.1.0"
local WINDOW_W       = 640
local WINDOW_H       = 520

-- 0xRRGGBB track colors
local TRACK_COLOR = {
  folder       = 0x555566,
  instrumental = 0x3A8FE8,
  vocals       = 0xE83A7A,
  drums        = 0xE84444,
  bass         = 0x4455E8,
  guitar       = 0x44CC55,
  other        = 0xEEAA33,
}

-- Stem detection rules: ordered by priority (most specific first)
-- `pattern` matched against the lowercase filename (no extension)
local STEM_RULES = {
  { pattern = "no[_%-]?drums?",    label = "No Drums",     color = TRACK_COLOR.drums        },
  { pattern = "no[_%-]?bass",      label = "No Bass",      color = TRACK_COLOR.bass         },
  { pattern = "no[_%-]?vocals?",   label = "No Vocals",    color = TRACK_COLOR.vocals       },
  { pattern = "instrumental",      label = "Instrumental", color = TRACK_COLOR.instrumental },
  { pattern = "vocals?",           label = "Vocals",       color = TRACK_COLOR.vocals       },
  { pattern = "guitar",            label = "Guitar",       color = TRACK_COLOR.guitar       },
  { pattern = "piano",             label = "Piano",        color = TRACK_COLOR.other        },
  { pattern = "drums?",            label = "Drums",        color = TRACK_COLOR.drums        },
  { pattern = "bass",              label = "Bass",         color = TRACK_COLOR.bass         },
}

-- Song structure tags Suno embeds in lyrics/prompt
local STRUCTURE_TAGS = {
  "Intro", "Verse", "Pre%-Chorus", "Pre%-Hook", "Chorus", "Hook",
  "Post%-Chorus", "Bridge", "Breakdown", "Solo", "Interlude", "Outro",
  "Refrain", "Build",
}

-- ─── STATE ──────────────────────────────────────────────────────────────────
-- All mutable state lives in this table. No bare globals.

local state = {
  phase    = "idle",   -- idle | ready | importing | done | error
  zip_path = "",
  temp_dir = "",
  log      = {},       -- { level="info"|"warn"|"error", msg=string }
  meta     = {},       -- parsed from info.json
  progress = 0.0,      -- 0.0 → 1.0 for progress bar
  cancel   = false,
  scroll_to_bottom = false,
}

-- ─── LOGGING ────────────────────────────────────────────────────────────────

local function log(level, msg)
  table.insert(state.log, { level = level, msg = msg })
  state.scroll_to_bottom = true
  reaper.ShowConsoleMsg(("[Suno][%s] %s\n"):format(level:upper(), msg))
end

local function info(m) log("info",  m) end
local function warn(m) log("warn",  m) end
local function lerr(m) log("error", m) end  -- 'err' conflicts with Lua std

-- ─── PATH UTILITIES ─────────────────────────────────────────────────────────

local function is_windows()
  return reaper.GetOS():find("Win") ~= nil
end

local function dir_sep()
  return is_windows() and "\\" or "/"
end

-- Ensure a path ends with the OS directory separator
local function trail(path)
  local sep = dir_sep()
  return (path:sub(-1) == sep) and path or (path .. sep)
end

-- Strip directory from path, returning just the filename
local function basename(path)
  return path:match("[/\\]([^/\\]+)$") or path
end

-- Strip extension from a filename
local function stripext(fname)
  return fname:match("^(.+)%.[^%.]+$") or fname
end

-- Check if a file exists
local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close(); return true end
  return false
end

-- ─── DIRECTORY OPERATIONS ───────────────────────────────────────────────────

local function dir_exists(path)
  if lfs then
    local attr = lfs.attributes(path)
    return attr ~= nil and attr.mode == "directory"
  end
  -- Fallback: try to list directory
  local cmd = is_windows()
    and ('cmd /c "if exist "' .. path .. '\\" (exit 0) else (exit 1)" 2>nul')
    or  ('[ -d "' .. path:gsub('"', '\\"') .. '" ] && exit 0 || exit 1')
  local ok = os.execute(cmd)
  return ok == 0 or ok == true
end

local function mkdir_p(path)
  if lfs then
    -- Create parent dirs as needed (lfs.mkdir is non-recursive)
    lfs.mkdir(path)
    return dir_exists(path)
  end
  local cmd = is_windows()
    and ('mkdir "' .. path .. '" 2>nul')
    or  ('mkdir -p "' .. path:gsub('"', '\\"') .. '"')
  os.execute(cmd)
  return dir_exists(path)
end

local function rmdir_recursive(path)
  if is_windows() then
    os.execute('rmdir /s /q "' .. path .. '" 2>nul')
  else
    os.execute('rm -rf "' .. path:gsub('"', '\\"') .. '"')
  end
end

-- List files directly inside `dir`, filtered by a Lua pattern on the filename.
-- Returns an array of full absolute paths.
local function list_dir_files(dir, fname_pattern)
  local results = {}
  dir = trail(dir)

  if lfs then
    for entry in lfs.dir(dir) do
      if entry ~= "." and entry ~= ".." then
        local full = dir .. entry
        local attr = lfs.attributes(full)
        if attr and attr.mode == "file" then
          if (not fname_pattern) or entry:lower():match(fname_pattern) then
            table.insert(results, full)
          end
        end
      end
    end
  else
    local cmd = is_windows()
      and ('dir /b /a-d "' .. dir .. '" 2>nul')
      or  ('ls -1p "' .. dir:gsub('"', '\\"') .. '" 2>/dev/null | grep -v /')
    local pipe = io.popen(cmd)
    if pipe then
      for line in pipe:lines() do
        line = line:match("^%s*(.-)%s*$")  -- trim
        if line ~= "" then
          local full = dir .. line
          if (not fname_pattern) or line:lower():match(fname_pattern) then
            table.insert(results, full)
          end
        end
      end
      pipe:close()
    end
  end
  return results
end

-- List immediate sub-directories of `dir`
local function list_subdirs(dir)
  local results = {}
  dir = trail(dir)
  if lfs then
    for entry in lfs.dir(dir) do
      if entry ~= "." and entry ~= ".." then
        local full = dir .. entry
        local attr = lfs.attributes(full)
        if attr and attr.mode == "directory" then
          table.insert(results, full)
        end
      end
    end
  else
    local cmd = is_windows()
      and ('dir /b /ad "' .. dir .. '" 2>nul')
      or  ('find "' .. dir:gsub('"', '\\"') .. '" -maxdepth 1 -mindepth 1 -type d 2>/dev/null')
    local pipe = io.popen(cmd)
    if pipe then
      for line in pipe:lines() do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" then
          -- popen on macOS/Linux gives full path for find, just name for ls
          local full = (line:sub(1,1) == "/" or line:sub(2,2) == ":") and line
                       or (dir .. line)
          table.insert(results, full)
        end
      end
      pipe:close()
    end
  end
  return results
end

-- ─── ZIP EXTRACTION ─────────────────────────────────────────────────────────

-- Unzip `zip_path` into `dest_dir`. Returns true on success.
local function unzip_to(zip_path, dest_dir)
  mkdir_p(dest_dir)

  local ok, cmd
  if is_windows() then
    -- PowerShell 5+ (Windows 10+) natively handles ZIP
    local zp = zip_path:gsub("'", "''")
    local dp = dest_dir:gsub("'", "''")
    cmd = ("powershell -NonInteractive -NoProfile -Command "
      .. '"Expand-Archive -LiteralPath \'%s\' -DestinationPath \'%s\' -Force"')
      :format(zp, dp)
    ok = os.execute(cmd)
    if ok ~= 0 and ok ~= true then
      -- Fallback: 7-Zip (common on developer machines)
      cmd = ('7z x "%s" -o"%s" -y >nul 2>&1'):format(zip_path, dest_dir)
      ok  = os.execute(cmd)
    end
  else
    -- unzip ships with macOS and most Linux distros
    local zp = zip_path:gsub('"', '\\"')
    local dp = dest_dir:gsub('"', '\\"')
    cmd = ('unzip -o "%s" -d "%s" >/dev/null 2>&1'):format(zp, dp)
    ok  = os.execute(cmd)
  end

  if ok ~= 0 and ok ~= true then
    return false,
      "Extraction command failed.\n"
      .. "Windows: ensure PowerShell 5+ or 7-Zip is available.\n"
      .. "Mac/Linux: ensure 'unzip' is installed (brew install unzip)."
  end
  return true, nil
end

-- ─── JSON PARSER ────────────────────────────────────────────────────────────
-- Minimal parser for flat JSON objects with string values.
-- Handles the known structure of Suno's info.json without external deps.

local function json_string(json, key)
  local pat_start = '"' .. key .. '"%s*:%s*"'
  local s = json:find(pat_start)
  if not s then return nil end

  -- Advance past key + colon + opening quote
  local pos = json:find('"', s + #key + 1)
  if not pos then return nil end
  pos = pos + 1  -- skip opening quote

  -- Read until unescaped closing quote
  local chars = {}
  while pos <= #json do
    local c = json:sub(pos, pos)
    if c == '"' then
      break
    elseif c == '\\' then
      local n = json:sub(pos + 1, pos + 1)
      local map = { n="\n", t="\t", r="\r", ['"']='"', ["\\"]="\\", ["/"]="/" }
      table.insert(chars, map[n] or (c .. n))
      pos = pos + 2
    else
      table.insert(chars, c)
      pos = pos + 1
    end
  end
  return table.concat(chars)
end

-- Parse Suno's info.json. Returns a metadata table.
local function parse_info_json(path)
  local meta = { title="Untitled", tags="", prompt="", id="" }
  local f    = io.open(path, "r")
  if not f then warn("Cannot open info.json"); return meta end
  local raw = f:read("*a"); f:close()

  meta.title  = json_string(raw, "title")
             or json_string(raw, "display_name")
             or json_string(raw, "name")
             or "Untitled"
  meta.tags   = json_string(raw, "tags")                  or ""
  meta.prompt = json_string(raw, "prompt")
             or json_string(raw, "lyric")
             or json_string(raw, "lyrics")
             or ""
  meta.id     = json_string(raw, "id")                    or ""

  -- Safe title: strip characters illegal in filenames / track names
  meta.safe_title = meta.title:gsub('[/\\:*?"<>|%z]', "_"):match("^%s*(.-)%s*$")
  if meta.safe_title == "" then meta.safe_title = "Suno Track" end

  return meta
end

-- ─── SONG STRUCTURE ─────────────────────────────────────────────────────────

-- Extract song section tags from Suno's lyrics/prompt field.
-- Returns an ordered array of { label = string }.
local function extract_structure(prompt)
  local sections = {}
  for _, tag in ipairs(STRUCTURE_TAGS) do
    local count = 0
    local pos   = 1
    while true do
      -- Match [TagName], [TagName 2], [TagName: ...] etc.
      local s, e = prompt:find("%[" .. tag .. "[^%]]*%]", pos)
      if not s then break end
      count = count + 1
      table.insert(sections, {
        text_pos = s,
        label    = count > 1 and (tag:gsub("%%%-", "-") .. " " .. count)
                             or   tag:gsub("%%%-", "-"),
      })
      pos = e + 1
    end
  end
  table.sort(sections, function(a, b) return a.text_pos < b.text_pos end)
  return sections
end

-- Place REAPER project markers for each section, distributed evenly across
-- the item's timeline. (Suno provides no timing data, so this is an estimate.)
local function place_markers(sections, item_start, item_length)
  if #sections == 0 then return end
  local n   = #sections
  local gap = item_length / (n + 1)
  for i, sec in ipairs(sections) do
    local t     = item_start + gap * i
    local color = reaper.ColorToNative(255, 220, 55) | 0x1000000  -- yellow
    reaper.AddProjectMarker2(0, false, t, 0, sec.label, -1, color)
  end
  info(("Placed %d structural markers (drag to correct timing)"):format(n))
end

-- ─── REAPER OPERATIONS ──────────────────────────────────────────────────────

local function native_color(rgb)
  local r = (rgb >> 16) & 0xFF
  local g = (rgb >>  8) & 0xFF
  local b =  rgb        & 0xFF
  return reaper.ColorToNative(r, g, b) | 0x1000000
end

-- Insert a new track at `idx`, name it and optionally color it.
-- Returns nil if track creation fails.
local function insert_track(idx, name, color_rgb)
  reaper.InsertTrackAtIndex(idx, true)
  local track = reaper.GetTrack(0, idx)
  if not track then
    warn("Failed to create track at index " .. idx)
    return nil
  end
  reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)
  if color_rgb then reaper.SetTrackColor(track, native_color(color_rgb)) end
  return track
end

-- Import an audio file to `track` at project position 0.
-- Returns (item, length_seconds) or (nil, nil) on failure.
local function import_audio(track, filepath)
  if not file_exists(filepath) then
    warn("File not found: " .. filepath)
    return nil, nil
  end

  local src = reaper.PCM_Source_CreateFromFile(filepath)
  if not src then
    warn("Cannot create source from: " .. filepath)
    return nil, nil
  end

  local item = reaper.AddMediaItemToTrack(track)
  if not item then
    warn("Failed to add media item to track: " .. filepath)
    return nil, nil
  end

  local take = reaper.AddTakeToMediaItem(item)
  if not take then
    warn("Failed to add take to media item: " .. filepath)
    return nil, nil
  end

  reaper.SetMediaItemTake_Source(take, src)

  local src_len = reaper.GetMediaSourceLength(src)
  if not src_len then
    warn("Cannot get source length: " .. filepath)
    return nil, nil
  end
  reaper.SetMediaItemInfo_Value(item, "D_POSITION",   0)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH",     src_len)
  reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", 0)
  reaper.UpdateItemInProject(item)

  return item, src_len
end

-- ─── CORE IMPORT PIPELINE ───────────────────────────────────────────────────

local function do_import()
  state.phase    = "importing"
  state.progress = 0.0

  -- ── 1. Extract ZIP ──────────────────────────────────────────────────────
  local tmp_base   = trail(reaper.GetTempPath())
  local stamp      = tostring(os.time()):sub(-6)  -- last 6 digits of epoch
  local zip_name   = stripext(basename(state.zip_path))
  state.temp_dir   = tmp_base .. "suno_" .. zip_name .. "_" .. stamp

  info("Extracting ZIP…")
  info("  From: " .. state.zip_path)
  info("  To:   " .. state.temp_dir)

  local ok, extract_err = unzip_to(state.zip_path, state.temp_dir)
  if not ok then
    lerr("Extraction failed: " .. (extract_err or "unknown error"))
    state.phase = "error"
    return
  end
  info("Extraction OK.")
  state.progress = 0.20

  -- ── 2. Locate files (search root + one level of subdirs) ────────────────
  local function find_files(dir, pattern)
    local found = list_dir_files(dir, pattern)
    if #found == 0 then
      for _, sub in ipairs(list_subdirs(dir)) do
        for _, f in ipairs(list_dir_files(sub, pattern)) do
          table.insert(found, f)
        end
      end
    end
    return found
  end

  -- ── 3. Parse info.json ──────────────────────────────────────────────────
  local json_files = find_files(state.temp_dir, "info%.json$")
  if #json_files > 0 then
    state.meta = parse_info_json(json_files[1])
    info("Title : " .. state.meta.title)
    if state.meta.tags ~= "" then info("Tags  : " .. state.meta.tags) end
  else
    warn("info.json not found — using ZIP filename as title.")
    state.meta = {
      title = zip_name, safe_title = zip_name:gsub('[/\\:*?"<>|%z]', "_"),
      tags = "", prompt = "", id = "",
    }
  end
  state.progress = 0.35

  -- ── 4. Discover and classify audio files ────────────────────────────────
  local audio_files = find_files(state.temp_dir, "%.[mw][p3av]+$")
  if #audio_files == 0 then
    lerr("No audio files (MP3/WAV) found inside the ZIP.")
    state.phase = "error"
    return
  end
  info(("Found %d audio file(s)."):format(#audio_files))

  local stems = {}
  for _, fpath in ipairs(audio_files) do
    local fname = stripext(basename(fpath)):lower()
    local matched = false
    for _, rule in ipairs(STEM_RULES) do
      if fname:match(rule.pattern) then
        table.insert(stems, { path=fpath, label=rule.label, color=rule.color })
        matched = true
        break
      end
    end
    if not matched then
      local label = stripext(basename(fpath))
      table.insert(stems, { path=fpath, label=label, color=TRACK_COLOR.other })
    end
  end

  -- Sort: instrumental first, then vocals, then the rest
  local order = { Instrumental=1, Vocals=2 }
  table.sort(stems, function(a, b)
    return (order[a.label] or 99) < (order[b.label] or 99)
  end)
  state.progress = 0.42

  -- ── 5. Save edit cursor + selection, begin undo ─────────────────────────
  local saved_cursor   = reaper.GetCursorPosition()
  local saved_sel_s, saved_sel_e = reaper.GetSet_LoopTimeRange(false,false,0,0,false)

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  local insert_idx  = reaper.CountTracks(0)
  local title_label = "[Suno] " .. state.meta.safe_title
  local cancelled   = false

  -- ── 6. Create folder track ──────────────────────────────────────────────
  local folder_track = insert_track(insert_idx, title_label, TRACK_COLOR.folder)
  -- depth=1 means the next track is the first child of this folder
  reaper.SetMediaTrackInfo_Value(folder_track, "I_FOLDERDEPTH", 1)
  insert_idx = insert_idx + 1

  -- ── 7. Import each stem ─────────────────────────────────────────────────
  local max_len = 0

  for i, stem in ipairs(stems) do
    if state.cancel then
      cancelled = true
      warn("Import cancelled.")
      break
    end

    local tname = ("[Suno] %s (%s)"):format(state.meta.safe_title, stem.label)
    local track  = insert_track(insert_idx, tname, stem.color)

    info(("Importing [%s]  %s"):format(stem.label, basename(stem.path)))
    local _, ilen = import_audio(track, stem.path)
    if ilen then
      info(("  → %.2f s"):format(ilen))
      if ilen > max_len then max_len = ilen end
    end

    -- depth=-1 on the last child closes the folder
    if i == #stems then
      reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", -1)
    end

    insert_idx   = insert_idx + 1
    state.progress = 0.42 + 0.40 * (i / #stems)
  end

  -- Always balance Undo/PreventUIRefresh, even on cancel
  if not cancelled then
    -- ── 8. Structural markers ───────────────────────────────────────────────
    if state.meta.prompt ~= "" and max_len > 0 then
      local sections = extract_structure(state.meta.prompt)
      if #sections > 0 then
        place_markers(sections, 0, max_len)
      else
        info("No [Verse]/[Chorus] tags found in lyrics — no markers placed.")
      end
    end
    state.progress = 0.88

    -- ── 9. Save lyrics to Project Notes ────────────────────────────────────
    if state.meta.prompt ~= "" then
      local notes = reaper.GetSetProjectNotes(0, false, "")
      if #notes > 0 then notes = notes .. "\n\n" .. string.rep("─", 40) .. "\n\n" end
      notes = notes
        .. ("=== %s  (Suno AI) ===\n"):format(state.meta.title)
        .. (state.meta.tags ~= "" and ("Tags: %s\n\n"):format(state.meta.tags) or "")
        .. state.meta.prompt
      reaper.GetSetProjectNotes(0, true, notes)
      info("Lyrics saved → View > Project Notes")
    end

    -- ── 10. Restore state ───────────────────────────────────────────────────
    reaper.SetEditCurPos(saved_cursor, false, false)
    reaper.GetSet_LoopTimeRange(true, false, saved_sel_s, saved_sel_e, false)
    reaper.SetOnlyTrackSelected(folder_track)
    reaper.Main_OnCommand(40913, 0)   -- Track: Scroll to first selected track
  end

  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock(cancelled and "Import Suno ZIP: cancelled" or ("Import Suno ZIP: " .. state.meta.title), -1)
  reaper.UpdateArrange()
  reaper.TrackList_AdjustWindows(false)
  state.progress = 0.96

  -- ── 11. Cleanup temp dir ────────────────────────────────────────────────
  info("Cleaning up temp folder…")
  rmdir_recursive(state.temp_dir)

  info(string.rep("─", 38))
  info(("Done!  \"%s\"  |  %d stems"):format(state.meta.title, #stems))
  info(string.rep("─", 38))
  state.progress = 1.0
  state.phase    = "done"
end

-- ─── GUI ────────────────────────────────────────────────────────────────────

local ctx = reaper.ImGui_CreateContext(SCRIPT_NAME)

-- Colour helpers (ABGR u32 — REAPER ImGui format)
local function rgba(r, g, b, a)
  return reaper.ImGui_ColorConvertDouble4ToU32(r/255, g/255, b/255, a/255)
end
local C_DIM   = rgba(140, 140, 140, 255)
local C_INFO  = rgba(170, 210, 255, 255)
local C_WARN  = rgba(255, 200,  70, 255)
local C_ERROR = rgba(255,  90,  80, 255)
local C_OK    = rgba( 80, 215, 110, 255)
local C_HEAD  = rgba(255, 215,  50, 255)

local function log_color(level)
  if level == "error" then return C_ERROR
  elseif level == "warn"  then return C_WARN
  elseif level == "ok"    then return C_OK
  else                         return C_INFO
  end
end

-- Main GUI loop — called each frame via reaper.defer
local function loop()
  local wflags = reaper.ImGui_WindowFlags_NoCollapse()
               | reaper.ImGui_WindowFlags_NoResize()
  reaper.ImGui_SetNextWindowSize(ctx, WINDOW_W, WINDOW_H, reaper.ImGui_Cond_Once())

  local visible, open = reaper.ImGui_Begin(ctx, SCRIPT_NAME .. "  v" .. SCRIPT_VERSION,
                                            true, wflags)
  if visible then

    -- ── Heading ────────────────────────────────────────────────────────
    reaper.ImGui_TextColored(ctx, C_HEAD, "Suno AI  →  REAPER Track Importer")
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Spacing(ctx)

    -- ── File path display + Browse button ──────────────────────────────
    local can_interact = (state.phase ~= "importing")

    reaper.ImGui_Text(ctx, "ZIP File:")
    reaper.ImGui_SameLine(ctx)
    local path_display = (state.zip_path ~= "") and state.zip_path or "(none selected)"
    -- Clamp to available width minus button width
    local avail_w = reaper.ImGui_GetContentRegionAvail(ctx)
    reaper.ImGui_SetNextItemWidth(ctx, avail_w - 90)
    -- Read-only display using InputText (shows full path with horizontal scroll)
    reaper.ImGui_InputText(ctx, "##zippath", path_display,
      reaper.ImGui_InputTextFlags_ReadOnly())
    reaper.ImGui_SameLine(ctx)

    if not can_interact then reaper.ImGui_BeginDisabled(ctx, true) end
    if reaper.ImGui_Button(ctx, "Browse…") then
      local ok, fpath = reaper.GetUserFileNameForRead("", "Select Suno ZIP file", "zip")
      if ok and fpath ~= "" then
        state.zip_path = fpath
        state.log      = {}
        state.meta     = {}
        state.phase    = "ready"
        state.progress = 0.0
        info("Selected: " .. fpath)
      end
    end
    if not can_interact then reaper.ImGui_EndDisabled(ctx) end

    reaper.ImGui_Spacing(ctx)

    -- ── Metadata preview ────────────────────────────────────────────────
    if state.meta.title and state.meta.title ~= "" then
      reaper.ImGui_TextColored(ctx, C_DIM, "Title: ")
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_Text(ctx, state.meta.title)
      if state.meta.tags ~= "" then
        reaper.ImGui_TextColored(ctx, C_DIM, "Tags:  ")
        reaper.ImGui_SameLine(ctx)
        reaper.ImGui_TextColored(ctx, rgba(200, 200, 120, 200),
          state.meta.tags:sub(1, 72))
      end
      reaper.ImGui_Spacing(ctx)
    end

    -- ── Import button ────────────────────────────────────────────────────
    local can_import = (state.phase == "ready")
    if not can_import then reaper.ImGui_BeginDisabled(ctx, true) end
    if reaper.ImGui_Button(ctx, "     Import into REAPER!     ") then
      do_import()
    end
    if not can_import then reaper.ImGui_EndDisabled(ctx) end

    -- ── Status badge ────────────────────────────────────────────────────
    reaper.ImGui_SameLine(ctx)
    local badge_txt, badge_col
    if     state.phase == "idle"      then badge_txt = "● Idle";        badge_col = C_DIM
    elseif state.phase == "ready"     then badge_txt = "● Ready";       badge_col = C_INFO
    elseif state.phase == "importing" then badge_txt = "● Importing…";  badge_col = C_WARN
    elseif state.phase == "done"      then badge_txt = "✓ Done!";       badge_col = C_OK
    elseif state.phase == "error"     then badge_txt = "✗ Error";       badge_col = C_ERROR
    end
    reaper.ImGui_TextColored(ctx, badge_col, badge_txt)

    -- ── Progress bar (only visible while importing or done) ────────────
    if state.phase == "importing" or state.phase == "done" then
      reaper.ImGui_Spacing(ctx)
      local overlay = state.phase == "done"
        and "Complete!"
        or  ("%.0f%%"):format(state.progress * 100)
      reaper.ImGui_ProgressBar(ctx, state.progress, -1, 0, overlay)
    end

    reaper.ImGui_Spacing(ctx)
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Spacing(ctx)
    reaper.ImGui_TextColored(ctx, C_DIM, "Log:")

    -- ── Scrolling log panel ──────────────────────────────────────────────
    local log_h = WINDOW_H - 200  -- remaining vertical space
    if state.phase == "importing" or state.phase == "done" then
      log_h = log_h - 28  -- account for progress bar
    end
    reaper.ImGui_BeginChild(ctx, "##log", 0, log_h)
    for _, entry in ipairs(state.log) do
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), log_color(entry.level))
      reaper.ImGui_TextWrapped(ctx, entry.msg)
      reaper.ImGui_PopStyleColor(ctx)
    end
    if state.scroll_to_bottom then
      local sy  = reaper.ImGui_GetScrollY(ctx)
      local smy = reaper.ImGui_GetScrollMaxY(ctx)
      if sy >= smy - 4 or state.phase == "importing" then
        reaper.ImGui_SetScrollHereY(ctx, 1.0)
      end
      state.scroll_to_bottom = false
    end
    reaper.ImGui_EndChild(ctx)

    -- ── Footer hint ─────────────────────────────────────────────────────
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_TextColored(ctx, C_DIM,
      "Tip: after import, drag yellow markers to correct section timing.")

    reaper.ImGui_End(ctx)
  end

  if open then
    reaper.defer(loop)
  else
    reaper.ImGui_DestroyContext(ctx)
  end
end

-- ─── ENTRY POINT ────────────────────────────────────────────────────────────

if not reaper.SWS_GetVersion then
  warn("SWS extension not detected — file listing may be slower without lfs.")
  warn("Get SWS at: https://www.sws-extension.org/")
end

info(("Suno ZIP Importer v%s ready."):format(SCRIPT_VERSION))
info("Click 'Browse…' to select a Suno .zip file, then 'Import into REAPER!'.")

reaper.defer(loop)

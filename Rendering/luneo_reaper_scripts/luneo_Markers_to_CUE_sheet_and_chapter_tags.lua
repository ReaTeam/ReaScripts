-- @noindex

-- @description Markers to CUE sheet and chapter tags
-- @version 2.0
-- @author Luneo
-- @link https://codeberg.org/luneo/reaper_scripts
-- @about
--   # Markers to CUE sheet and chapter tags
--
--   Reads markers and regions straight from the open REAPER project and writes
--   a CUE sheet and/or a Vorbis comment file containing CHAPTERxxx tags,
--   and can embed both into a FLAC (metaflac) or an Opus file (opustags).
--   Optionally it also writes FFMETADATA, ffmpeg's own chapter and metadata
--   format, which carries an end time per chapter.
--   Positions arrive at full precision instead of being quantised to the frame
--   grid of the marker export.
--
--   The first region defines the offset, so times can be made relative to the
--   rendered audio file. Optionally calls `metaflac` afterwards to embed both
--   the chapter tags and the cue sheet into a FLAC file.
--
--   Settings live in the CONFIG block at the top of the script.
-- @changelog
--   v2.0:
--     Add album, artist, genre, date and title tags to FFMETADATA output
--   v1.9:
--     Add support for FFMETADATA format
--   v1.8:
--     Add support for opus files (via opustags)
--   v1.7:
--     Update changelog
--   v1.6:
--     Add dialog field for metaflac path
--     Add none option for output to only embed chapter data into flac file
--   v1.5:
--     Album defaults to the project title, artist to the project author
--   v1.4:
--      Add changelog info
--   v1.3: 
--      Settings dialog now also asks for Album, Artist, Date and Genre
--      Album defaults to the project title, artist to the project author
--      Added y/n switches for embedding tags and for the native CUESHEET block
--   v1.2:
--     Embedding writes ALBUM, ARTIST, ALBUMARTIST, TITLE, DATE and GENRE
--     Output location can be picked as a file or as a folder
--     Added CONFIG.METAFLAC for an absolute path when REAPER cannot find it
--   v1.1:
--     metaflac errors are shown in the console instead of a bare exit code
--     Chapter tags are read back after embedding to confirm they were written
--     Warn that the native CUESHEET block hides chapter titles in mpv and VLC
--     Fixed cancelling the save dialog falling through to the default path
--   v1.0:
--     Initial release


--[[
  Markers -> CUE sheet + CHAPTER tags  (ReaScript, Lua)

  Reads markers and regions straight from the open REAPER project and writes a
  CUE sheet and/or a Vorbis comment file containing CHAPTERxxx tags.
  No CSV export needed, and positions arrive at full precision instead of being
  quantised to the frame grid of the marker export.

  Install:
    Actions -> Show action list -> New action -> Load ReaScript...
    Put this file in REAPER/Scripts/, then assign a shortcut if you like.

  Everything worth changing lives in the CONFIG block below. With ASK = true a
  dialog lets you adjust the base name, audio file and offset at run time; with
  PICK_PATH you get a file or folder browser for the output location first.
]]

------------------------------------------------------------------ CONFIG

local CONFIG = {
  ASK        = true,        -- show the settings dialog on start
  PICK_PATH  = "file",      -- "file" = save dialog for folder + base name
                            -- "dir"  = folder dialog only, name from OUT_NAME
                            -- false  = no dialog, use OUT_DIR / OUT_NAME
  ONLY       = "both",      -- "both" | "cue" | "chapters" | "none"
                            -- "none" writes no files and only embeds
  FFMETA     = false,       -- additionally write PREFIX.ffmeta, ffmpeg's
                            -- FFMETADATA format: chapters with a start and an
                            -- end, plus arbitrary key=value metadata
  AUDIO_FILE = "",          -- name for the FILE line; empty = <project name>.flac
  FILE_TYPE  = "FLAC",      -- WAVE | MP3 | FLAC | AIFF
  OFFSET     = "auto",      -- "auto" = subtract the start of the first region
                            -- "none" = subtract nothing
                            -- number = fixed value in seconds, e.g. 1.4 or -0.25
  PERFORMER  = "",          -- CUE header; empty = line is omitted
  TITLE      = "",          -- CUE header; empty = project name
  OUT_DIR    = "",          -- target folder; empty = folder of the project file
  OUT_NAME   = "",          -- base name without extension; empty = project name
  EMBED      = true,        -- true: call metaflac afterwards
  OPUSTAGS   = "opustags",  -- same, used when the target file ends in .opus
  METAFLAC   = "metaflac",  -- default for the dialog field; an absolute path
                            -- entered there is remembered and wins over this.
                            -- Use an absolute path if REAPER cannot find it,
                            -- e.g. "/opt/homebrew/bin/metaflac" on macOS or
                            -- "C:\\Program Files\\flac\\metaflac.exe" on Windows
  EMBED_FILE = "",          -- FLAC file to embed into; empty = OUT_DIR/AUDIO_FILE
  WRITE_TAGS = true,        -- also write ALBUM/ARTIST/TITLE when embedding
  ALBUM      = "",          -- empty = CONFIG.TITLE, or the project name
  ALBUMARTIST= "",          -- empty = CONFIG.PERFORMER, or the project author
                            -- from Project Settings -> Notes
  DATE       = "",          -- e.g. "2026-09"; empty = current year and month
  GENRE      = "Pop",       -- empty = tag omitted
  NATIVE_CUE = false,       -- also write FLAC's own CUESHEET block. Careful:
                            -- ffmpeg then uses that block for chapters and
                            -- ignores the CHAPTER tags, so mpv/VLC lose the
                            -- chapter titles. Leave this off for player use.
}

------------------------------------------------------------------ Helpers

local is_windows = package.config:sub(1, 1) == "\\"
local SEP = is_windows and "\\" or "/"

local function msg(s)
  reaper.ShowConsoleMsg(tostring(s) .. "\n")
end

local function fail(s)
  reaper.MB(tostring(s), "Markers -> CUE + Chapters", 0)
  return nil
end

-- integer division, so the script also runs on Lua 5.1/5.2 hosts
local function idiv(a, b) return math.floor(a / b) end

local function trim(s) return (tostring(s):gsub("^%s+", ""):gsub("%s+$", "")) end

local function fmt_cue(sec)                  -- MM:SS:FF, 75 CD frames per second
  local fr = math.floor(sec * 75 + 0.5)
  local total = idiv(fr, 75)
  return string.format("%02d:%02d:%02d", idiv(total, 60), total % 60, fr % 75)
end

local function fmt_chapter(sec)              -- HH:MM:SS.mmm
  local ms = math.floor(sec * 1000 + 0.5)
  local total = idiv(ms, 1000)
  return string.format("%02d:%02d:%02d.%03d",
    idiv(total, 3600), idiv(total, 60) % 60, total % 60, ms % 1000)
end

local function q(s) return '"' .. tostring(s):gsub('"', "'") .. '"' end

local function split_name(name, n)
  name = trim(name)
  if name == "" then return nil, string.format("Track %02d", n) end
  local performer, title = name:match("^(.-)%s+%-%s+(.+)$")
  if performer then return performer, title end
  return nil, name
end

-- quote an argument for the shell (only needed for EMBED)
local function shq(s)
  s = tostring(s)
  if is_windows then return '"' .. s:gsub('"', '""') .. '"' end
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function split_path(path)
  local dir = path:match("^(.*)[/\\][^/\\]*$") or ""
  local name = path:match("([^/\\]+)$") or ""
  return dir, name
end

local function api(name)
  local ok, exists = pcall(reaper.APIExists, name)
  return ok and exists == true
end

------------------------------------------------------- Locate project file

-- Bindings differ between REAPER versions: older ones expect the string output
-- parameter, newer ones do not. Try both.
local function project_file()
  local ok, _, fn = pcall(reaper.EnumProjects, -1, "")
  if not ok or type(fn) ~= "string" then
    ok, _, fn = pcall(reaper.EnumProjects, -1)
  end
  if ok and type(fn) == "string" and fn ~= "" then return fn end
  return ""
end

-- Ask GetSetProjectInfo_String for the first key that yields something.
-- Key names differ between REAPER versions and some return an empty string
-- or fail outright, so probe a list instead of trusting a single name.
local function project_meta(keys)
  for _, k in ipairs(keys) do
    local ok, _, val = pcall(reaper.GetSetProjectInfo_String, 0, k, "", false)
    if ok and type(val) == "string" and trim(val) ~= "" then return trim(val), k end
  end
  return "", nil
end

local function strip_ext(s) return (tostring(s):gsub("%.[%a%d]+$", "")) end

-- Project Settings -> Notes -> Author. Not every REAPER build exposes this
-- key, so fall back to an empty string instead of erroring out.
local function project_author()
  return (project_meta({ "PROJECT_AUTHOR", "AUTHOR" }))
end

local projfn = project_file()
local proj_dir, proj_file = split_path(projfn)
local proj_name = proj_file:gsub("%.[Rr][Pp][Pp]$", "")
if proj_name == "" then proj_name = "Untitled" end

------------------------------------------------------------ Collect markers

local marks, first_region, first_region_end, n_regions = {}, nil, nil, 0
do
  local total = reaper.CountProjectMarkers(0)
  for i = 0, total - 1 do
    local retval, isrgn, pos, rgnend, name, idx = reaper.EnumProjectMarkers(i)
    if retval ~= 0 then
      if isrgn then
        n_regions = n_regions + 1
        if not first_region or pos < first_region then
          first_region = pos
          first_region_end = rgnend        -- the render region defines the length
        end
      else
        marks[#marks + 1] = { sec = pos, name = name or "", ord = idx or #marks }
      end
    end
  end
end

if #marks == 0 then
  return fail("This project has no markers (regions do not count as tracks).")
end

table.sort(marks, function(a, b)
  if a.sec ~= b.sec then return a.sec < b.sec end
  return a.ord < b.ord
end)

--------------------------------------------------------- Output path picker

local audio_file = CONFIG.AUDIO_FILE
if audio_file == "" then audio_file = proj_name .. "." .. CONFIG.FILE_TYPE:lower() end
local out_name = CONFIG.OUT_NAME ~= "" and CONFIG.OUT_NAME or proj_name
local out_dir = CONFIG.OUT_DIR ~= "" and CONFIG.OUT_DIR or proj_dir
local offset_str = tostring(CONFIG.OFFSET)
local only = CONFIG.ONLY

-- Ways to ask for a path, best first:
--   1. GetUserFileName        -- native, no extension needed.
--      mode 0 = new file (save), 1 = existing file, 2 = multiple, 3 = directory.
--      Returns false when the user cancels. extension_list is pipe separated
--      and ignored in directory mode.
--   2. JS_Dialog_BrowseForSaveFile / JS_Dialog_BrowseForFolder -- js_ReaScriptAPI
--      (ReaPack, REAPER 6.24+), for installs whose REAPER predates GetUserFileName.
--   3. GetUserFileNameForRead -- always present, but an OPEN dialog: the user
--      picks the existing audio file and we derive folder + base name from it.
local function pick_output(want_dir)
  local suggestion = (out_dir ~= "" and (out_dir .. SEP) or "") .. out_name .. ".cue"
  local EXT = "CUE sheets|*.cue|All files|*.*"

  if api("GetUserFileName") then
    local ok, retval, fn = pcall(reaper.GetUserFileName,
      want_dir and 3 or 0,
      want_dir and "Choose the output folder" or "Save CUE sheet / chapter tags as",
      want_dir and out_dir or suggestion,
      want_dir and "" or EXT)
    if ok then
      if retval and fn and fn ~= "" then return fn end
      return nil, "cancelled"          -- documented: false means cancelled
    end
  end

  if want_dir then
    if api("JS_Dialog_BrowseForFolder") then
      local ok, retval, folder = pcall(reaper.JS_Dialog_BrowseForFolder,
        "Choose the output folder", out_dir)
      if ok then
        if retval == 1 and folder and folder ~= "" then return folder end
        if retval == 0 then return nil, "cancelled" end
      end
    end
  elseif api("JS_Dialog_BrowseForSaveFile") then
    local ok, retval, fn = pcall(reaper.JS_Dialog_BrowseForSaveFile,
      "Save CUE sheet / chapter tags as", out_dir, out_name .. ".cue", "")
    if ok then
      if retval == 1 and fn and fn ~= "" then return fn end
      if retval == 0 then return nil, "cancelled" end
    end
  end

  local ok, retval, fn = pcall(reaper.GetUserFileNameForRead, suggestion,
    "Pick the audio file (its folder and name are used for the output)", "flac")
  if ok and retval and fn and fn ~= "" then return fn end
  return nil, "cancelled"
end

if CONFIG.PICK_PATH == "dir" then
  local picked, why = pick_output(true)
  if not picked then if why == "cancelled" then return end
  else
    -- directory mode may still return a file if we fell through to the
    -- read dialog, so strip a trailing file name if there is one
    if picked:match("[/\\][^/\\]*%.[%a%d]+$") then picked = (split_path(picked)) end
    out_dir = picked:gsub("[/\\]$", "")
  end
elseif CONFIG.PICK_PATH == "file" or CONFIG.PICK_PATH == true then
  local picked, why = pick_output(false)
  if not picked and why == "cancelled" then return end
  if picked then
    local d, f = split_path(picked)
    if d ~= "" then out_dir = d end
    local base = f:gsub("%.[%a%d]+$", "")
    if base ~= "" then out_name = base end
    -- if an audio file was picked, use it for the FILE line as well
    if f:lower():match("%.flac$") or f:lower():match("%.opus$")
      or f:lower():match("%.wav$") or f:lower():match("%.aiff?$")
      or f:lower():match("%.mp3$") then
      audio_file = f
      if CONFIG.EMBED_FILE == "" and
        (f:lower():match("%.flac$") or f:lower():match("%.opus$")) then
        CONFIG.EMBED_FILE = picked
      end
    end
  end
end

------------------------------------------------------------ Settings dialog

-- values shared by the cue header and the FLAC tags
local v_album  = CONFIG.ALBUM ~= "" and CONFIG.ALBUM
  or (CONFIG.TITLE ~= "" and CONFIG.TITLE or "")
if v_album == "" then
  -- the project title beats the file name, but some keys hand back the file
  -- name itself -- treat that as "no title" and fall back to the cleaned name
  local t = project_meta({ "PROJECT_TITLE" })   -- Project Settings -> Notes
  if t ~= "" and (t:lower() == proj_file:lower() or t:lower() == proj_name:lower()) then
    t = ""
  end
  v_album = t ~= "" and strip_ext(t) or proj_name
end
local v_artist = CONFIG.ALBUMARTIST ~= "" and CONFIG.ALBUMARTIST
  or (CONFIG.PERFORMER ~= "" and CONFIG.PERFORMER or project_author())
-- Neither plain Lua nor the REAPER API can read a file's modification time,
-- so fall back to the current year and month -- for a project you are
-- rendering right now that is the same thing.
local v_date   = CONFIG.DATE ~= "" and CONFIG.DATE or os.date("%Y-%m")
local v_genre  = CONFIG.GENRE
local v_embed  = CONFIG.EMBED
local v_ffmeta = CONFIG.FFMETA
-- The metaflac path is remembered between runs, so an absolute path only has
-- to be typed once. A value stored here wins over the CONFIG default.
local v_metaflac = CONFIG.METAFLAC
local v_opustags = CONFIG.OPUSTAGS
do
  local ok, saved = pcall(reaper.GetExtState, "cue_chapters", "metaflac")
  if ok and type(saved) == "string" and saved ~= "" then v_metaflac = saved end
  local ok2, saved2 = pcall(reaper.GetExtState, "cue_chapters", "opustags")
  if ok2 and type(saved2) == "string" and saved2 ~= "" then v_opustags = saved2 end
end
local v_native = CONFIG.NATIVE_CUE

local function yn(b) return b and "y" or "n" end
local function is_yes(s)
  s = tostring(s):lower()
  return s == "y" or s == "yes" or s == "j" or s == "ja" or s == "1" or s == "true"
end

if CONFIG.ASK then
  -- A custom separator avoids the comma trap: artist names like
  -- "Kilate Tesla, Jayn, PURI" would otherwise be split into three fields.
  -- Captions themselves stay comma separated, so they must not contain commas.
  local SP = "|"
  local defaults = table.concat({ out_name, audio_file, offset_str, only,
    v_album, v_artist, v_date, v_genre, yn(v_ffmeta), yn(v_embed), yn(v_native),
    v_metaflac, v_opustags }, SP)
  local ok, csv = reaper.GetUserInputs("Markers -> CUE + Chapters", 13,
    "Base name,Audio file (FILE line),Offset (auto/none/sec)," ..
    "Output (both/cue/chapters/none),Album,Artist,Date,Genre," ..
    "Also write FFMETADATA (y/n)," ..
    "Embed tags into FLAC (y/n),CUESHEET block (y/n - hides chapter titles!)," ..
    "metaflac (name or absolute path),opustags (for .opus targets)," ..
    "extrawidth=240,separator=" .. SP,
    defaults)
  if not ok then return end
  local f = {}
  for part in (csv .. SP):gmatch("(.-)" .. SP) do f[#f + 1] = trim(part) end
  if f[1] and f[1] ~= "" then out_name = f[1] end
  if f[2] and f[2] ~= "" then audio_file = f[2] end
  if f[3] and f[3] ~= "" then offset_str = f[3] end
  if f[4] and f[4] ~= "" then only = f[4]:lower() end
  -- tag fields may be cleared on purpose, so take them as they are
  v_album, v_artist, v_date, v_genre = f[5] or "", f[6] or "", f[7] or "", f[8] or ""
  v_ffmeta = is_yes(f[9])
  v_embed  = is_yes(f[10])
  v_native = is_yes(f[11])
  if f[12] and f[12] ~= "" then v_metaflac = f[12] end
  if f[13] and f[13] ~= "" then v_opustags = f[13] end
  pcall(reaper.SetExtState, "cue_chapters", "metaflac", v_metaflac, true)
  pcall(reaper.SetExtState, "cue_chapters", "opustags", v_opustags, true)
end

if only ~= "both" and only ~= "cue" and only ~= "chapters" and only ~= "none" then
  return fail("Output must be both, cue, chapters or none (got: " .. tostring(only) .. ")")
end
if only == "none" and not v_embed and not v_ffmeta then
  return fail("Output \"none\" only makes sense together with embedding or\n" ..
    "FFMETADATA, otherwise the script would produce nothing at all.")
end
-- "none" still builds both, it just does not keep the files around
local keep_files = (only ~= "none")
local want_cue = (only == "both" or only == "cue" or only == "none")
local want_chapters = (only == "both" or only == "chapters" or only == "none")

------------------------------------------------------------------- Offset

local offset = 0
if offset_str == "auto" then
  offset = first_region or 0
elseif offset_str ~= "none" then
  offset = tonumber(offset_str)
  if not offset then
    return fail("Cannot read offset: " .. tostring(offset_str) ..
      "\nUse auto, none or a number of seconds.")
  end
end

local clamped = 0
for _, mk in ipairs(marks) do
  mk.sec = mk.sec - offset
  if mk.sec < 0 then mk.sec = 0; clamped = clamped + 1 end
end

-------------------------------------------------------------- Build output

local cue, chap = {}, {}

if want_cue then
  cue[#cue + 1] = "REM COMMENT " .. q("Generated from " ..
    (proj_name ~= "" and proj_name or "REAPER project"))
  cue[#cue + 1] = "REM COMMENT " .. q(string.format("Offset %.3f s", offset))
  if v_artist ~= "" then cue[#cue + 1] = "PERFORMER " .. q(v_artist) end
  cue[#cue + 1] = "TITLE " .. q(v_album ~= "" and v_album or proj_name)
  cue[#cue + 1] = "FILE " .. q(audio_file) .. " " .. CONFIG.FILE_TYPE:upper()
end

for n, mk in ipairs(marks) do
  local performer, title = split_name(mk.name, n)
  if want_cue then
    cue[#cue + 1] = string.format("  TRACK %02d AUDIO", n)
    cue[#cue + 1] = "    TITLE " .. q(title)
    if performer then cue[#cue + 1] = "    PERFORMER " .. q(performer) end
    cue[#cue + 1] = "    INDEX 01 " .. fmt_cue(mk.sec)
  end
  if want_chapters then
    local label = trim(mk.name)
    if label == "" then label = title end
    chap[#chap + 1] = string.format("CHAPTER%03d=%s", n, fmt_chapter(mk.sec))
    chap[#chap + 1] = string.format("CHAPTER%03dNAME=%s", n, label)
  end
end

if out_dir == "" then
  msg("Warning: project not saved, writing to REAPER's working directory.")
  msg("Save the project or set OUT_DIR so paths are absolute.")
end

-- FFMETADATA needs an interval per chapter, so the last one needs a length.
-- The render region gives it exactly; otherwise fall back to the project length.
local ffmeta = {}
if v_ffmeta then
  local dur
  if first_region_end and first_region_end > 0 then
    dur = first_region_end - offset
  else
    local ok, len = pcall(reaper.GetProjectLength, 0)
    if ok and type(len) == "number" and len > 0 then dur = len - offset end
  end
  local last_ms = math.floor(marks[#marks].sec * 1000 + 0.5)
  local end_ms
  if dur and math.floor(dur * 1000 + 0.5) > last_ms then
    end_ms = math.floor(dur * 1000 + 0.5)
  else
    end_ms = last_ms + 1000
  end

  local function esc(v)
    return (tostring(v):gsub("([=;#\\\n])", "\\%1"))
  end
  ffmeta[#ffmeta + 1] = ";FFMETADATA1"
  -- global section: everything before the first [CHAPTER] is file metadata
  local function gtag(field, value)
    if value == nil or value == "" then return end
    ffmeta[#ffmeta + 1] = field .. "=" .. esc(value)
  end
  gtag("title", v_album)
  gtag("album", v_album)
  gtag("artist", v_artist)
  gtag("album_artist", v_artist)
  gtag("date", v_date)
  gtag("genre", v_genre)
  for n, mk in ipairs(marks) do
    local start_ms = math.floor(mk.sec * 1000 + 0.5)
    local stop_ms = (n < #marks) and (math.floor(marks[n + 1].sec * 1000 + 0.5) - 1)
      or end_ms
    ffmeta[#ffmeta + 1] = "[CHAPTER]"
    ffmeta[#ffmeta + 1] = "TIMEBASE=1/1000"
    ffmeta[#ffmeta + 1] = "START=" .. start_ms
    ffmeta[#ffmeta + 1] = "END=" .. stop_ms
    ffmeta[#ffmeta + 1] = "title=" .. esc(trim(mk.name))
  end
end

local prefix = (out_dir ~= "" and (out_dir .. SEP) or "") .. out_name
local cue_path, chap_path = prefix .. ".cue", prefix .. "_chapters.txt"
local ffmeta_path = prefix .. ".ffmeta"
if not keep_files then
  -- metaflac reads from files, so build them in REAPER's resource folder
  -- (always writable) and delete them again once the tags are in the FLAC
  local ok, res = pcall(reaper.GetResourcePath)
  local tmp = (ok and type(res) == "string" and res ~= "") and res or out_dir
  local stem = tmp .. SEP .. "cue_chapters_tmp_" .. tostring(os.time())
  cue_path, chap_path = stem .. ".cue", stem .. "_chapters.txt"
end

local function cleanup()
  if not keep_files then
    os.remove(cue_path)
    os.remove(chap_path)
  end
end

local function write(path, lines)
  local f = io.open(path, "wb")
  if not f then return false, path end
  f:write(table.concat(lines, "\n"), "\n")
  f:close()
  return true
end

reaper.ClearConsole()
if want_cue then
  local ok, p = write(cue_path, cue)
  if not ok then return fail("Cannot write: " .. p) end
  if keep_files then msg("written: " .. cue_path) end
end
if want_chapters then
  local ok, p = write(chap_path, chap)
  if not ok then cleanup(); return fail("Cannot write: " .. p) end
  if keep_files then msg("written: " .. chap_path) end
end
if v_ffmeta then
  -- always a real file: nothing inside this script consumes it
  local ok, p = write(ffmeta_path, ffmeta)
  if not ok then return fail("Cannot write: " .. p) end
  msg("written: " .. ffmeta_path)
  msg("  use it with: ffmpeg -i <audio> -i " .. ffmeta_path ..
    " -map_metadata 1 -map_chapters 1 -c copy <out>")
end
if not keep_files then msg("no cue/chapter files kept, embedding only") end
msg(string.format("%d markers, %d regions, offset %.3f s", #marks, n_regions, offset))
if clamped > 0 then
  msg(string.format("Warning: %d markers were before the offset and got clamped to 0", clamped))
end
if want_cue and #marks > 99 then
  msg(string.format("Warning: %d tracks -- CUE sheets are designed for 99", #marks))
end

--------------------------------------------- optional: embed via tagger

if v_embed then
  -- run a command and capture its output, so failures land in the console
  local function run(cmd)
    local pipe = io.popen(cmd .. " 2>&1", "r")
    if not pipe then return false, -1, "io.popen failed" end
    local out = pipe:read("*a") or ""
    local ok, how, code = pipe:close()
    if ok == nil or ok == false then
      return false, (how == "exit" and code) or code or 1, out
    end
    if code and code ~= 0 then return false, code, out end
    if out:match("[Nn]ot found") or out:match("^ERROR") or out:match("\nERROR") then
      return false, 1, out
    end
    return true, 0, out
  end

  local flac = CONFIG.EMBED_FILE
  if flac == "" then
    flac = (out_dir ~= "" and (out_dir .. SEP) or "") .. audio_file
  end

  local function size_of(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local n = f:seek("end")
    f:close()
    return n
  end

  -- pick the tagger from the extension of the target file
  local target_ext = (flac:match("%.([%a%d]+)$") or ""):lower()
  local backend
  if target_ext == "flac" then backend = "flac"
  elseif target_ext == "opus" then backend = "opus" end

  local abort = nil
  if not backend then
    abort = "cannot tag " .. target_ext .. " files -- only .flac and .opus"
  elseif not size_of(flac) then
    abort = "audio file not found: " .. flac
  elseif want_chapters and (size_of(chap_path) or 0) == 0 then
    abort = "chapter file missing or empty: " .. chap_path
  elseif want_cue and (size_of(cue_path) or 0) == 0 then
    abort = "cue file missing or empty: " .. cue_path
  end

  if abort then
    msg("embed skipped -- " .. abort)
    cleanup()
  else
    local is_flac = (backend == "flac")
    local tool_name = is_flac and "metaflac" or "opustags"

    -- opustags converts tags against the locale charset and fails on non-ASCII
    -- titles in a C locale, so force UTF-8. On Windows an environment prefix
    -- does not work in cmd.exe, so use --raw there, which skips conversion.
    local TOOL = shq(is_flac and v_metaflac or v_opustags)
    local RAW = (not is_flac and is_windows) and " --raw" or ""
    local ENVPREFIX = (not is_flac and not is_windows) and "LC_ALL=C.UTF-8 " or ""
    local function tool(rest) return ENVPREFIX .. TOOL .. RAW .. " " .. rest end

    -- is the tagger reachable? exit code 127 means not found
    local ok, code, out = run(tool(is_flac and "--version" or "--help"))
    if not ok then
      msg(tool_name .. " could not be run (exit " .. tostring(code) .. ")")
      msg(trim(out))
      msg("Put the absolute path in the dialog's " .. tool_name .. " field,")
      msg("e.g. /opt/homebrew/bin/" .. tool_name .. " -- it is remembered.")
      msg("Find it in a terminal with: which " .. tool_name)
      cleanup()
      return
    end
    msg("using " .. (trim(out):match("^[^\r\n]*") or tool_name))

    -- collect existing CHAPTER tags so a second run does not duplicate them
    local stale, seen = {}, {}
    local read_cmd = is_flac and tool("--export-tags-to=- " .. shq(flac))
      or tool(shq(flac))
    local _, _, tags = run(read_cmd)
    for line in tostring(tags):gmatch("[^\r\n]+") do
      local field = line:match("^([%a%d_]+)=")
      if field and field:upper():match("^CHAPTER%d+") and not seen[field:upper()] then
        seen[field:upper()] = true
        stale[#stale + 1] = field
      end
    end

    -- the two taggers spell the same operations differently
    local args = {}
    local function del(field)
      args[#args + 1] = is_flac and ("--remove-tag=" .. shq(field))
        or ("--delete " .. shq(field))
    end
    local function set(field, value)
      if is_flac then
        args[#args + 1] = "--remove-tag=" .. shq(field)
        args[#args + 1] = "--set-tag=" .. shq(field .. "=" .. value)
      else
        args[#args + 1] = "--set " .. shq(field .. "=" .. value)
      end
    end

    for _, field in ipairs(stale) do del(field) end

    if want_chapters then
      if is_flac then
        args[#args + 1] = "--import-tags-from=" .. shq(chap_path)
      else
        -- opustags has no import, but the lines are still in memory
        for _, line in ipairs(chap) do
          local k, v = line:match("^([^=]+)=(.*)$")
          if k then args[#args + 1] = "--add " .. shq(k .. "=" .. v) end
        end
      end
    end
    if want_cue then
      if is_flac then
        args[#args + 1] = "--remove-tag=CUESHEET"
        args[#args + 1] = "--set-tag-from-file=" .. shq("CUESHEET=" .. cue_path)
      else
        set("CUESHEET", table.concat(cue, "\n"))
      end
    end

    if CONFIG.WRITE_TAGS then
      local function tag(field, value)
        if value == nil or value == "" then return end
        set(field, value)
      end
      tag("ALBUM", v_album)
      tag("TITLE", v_album)
      tag("ARTIST", v_artist)
      tag("ALBUMARTIST", v_artist)
      tag("DATE", v_date)
      tag("GENRE", v_genre)
    end

    if not is_flac then args[#args + 1] = "--in-place" end
    args[#args + 1] = shq(flac)

    local cmd = tool(table.concat(args, " "))
    local ok2, code2, out2 = run(cmd)
    if not ok2 then
      msg(tool_name .. " failed with exit code " .. tostring(code2))
      if trim(out2) ~= "" then msg(trim(out2)) end
      msg("command was: " .. cmd)
      if keep_files then
        msg("The text files are ready, you can run that command manually.")
      else
        msg("Set Output to both to keep the files and retry manually.")
      end
      cleanup()
      return
    end
    if trim(out2) ~= "" then msg(trim(out2)) end

    -- verify: read the tags back instead of trusting the exit code
    local _, _, check = run(read_cmd)
    local n = 0
    for _ in tostring(check):gmatch("CHAPTER%d+=") do n = n + 1 end
    msg(("embedded into %s (%d stale tags removed, %d chapters now in the file)")
      :format(flac, #stale, n))
    if want_chapters and n == 0 then
      msg("Warning: " .. tool_name .. " reported success but no CHAPTER tags " ..
        "are in the file.")
    end

    -- FLAC's own CUESHEET block is optional and may fail without
    -- invalidating the rest of the work.
    if v_native then
      if not is_flac then
        msg("Note: the native CUESHEET block is FLAC only, skipped for " .. target_ext)
      elseif not want_cue then
        msg("Note: CUESHEET block needs cue output, skipped")
      else
        local ok3, code3, out3 = run(tool("--import-cuesheet-from=" ..
          shq(cue_path) .. " " .. shq(flac)))
        if ok3 then
          msg("CUESHEET block written -- note: ffmpeg based players (mpv, VLC)")
          msg("will now take chapters from this block and show NO chapter titles.")
          msg("Undo with: metaflac --remove --block-type=CUESHEET " .. flac)
        else
          msg("Warning: CUESHEET block not written (exit " .. tostring(code3) .. ")")
          if trim(out3) ~= "" then msg(trim(out3)) end
        end
      end
    end
    cleanup()
  end
else
  cleanup()
end

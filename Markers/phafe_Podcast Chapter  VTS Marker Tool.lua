-- @description Podcast Chapter / VTS Marker Tool
-- @author Phafe
-- @version 1.0.0
-- @about
--   This tool is will add Podcasting2.0 chapters and "Value Time Split" (VTS) regions with lookups from podcastindex.org. Once created, the export option generates two files - Chapter json file and VTS txt file. The VTS should be added to the RSS feed within the episode "<podcast:value>" tag.
--
--   --   # Podcast Chapter / VTS Marker Tool
--   --
--   --   Insert Podcasting 2.0 chapter markers and Value4Value time-split
--   --   regions directly on the Reaper timeline, search PodcastIndex for
--   --   feed/episode GUIDs, and export a chapters.json file plus a VTS
--   --   remote-item XML snippet from your project's markers/regions.
--   --
--   --   Requires python3 (or python on Windows) on PATH, and a free
--   --   PodcastIndex API key/secret (https://api.podcastindex.org/) which
--   --   the script will prompt you for on first use of "VTS Insert".
--
--   ================================================================================
--    PodcastIndex Search -> Value4Value Remote-Item Region Stamper (Reaper)
--    + Podcasting 2.0 Chapters (JSON) & VTS RSS XML (TXT) Exporter
--   ================================================================================

-- @description Podcast Chapter / VTS Marker Tool
-- @version 1.0.0
-- @author Phafe
-- @about
--   # Podcast Chapter / VTS Marker Tool
--
--   Adds Podcasting 2.0 chapters and Value Time Split (VTS) regions to
--   your Reaper project timeline, with feed/episode lookups from
--   podcastindex.org.
--
--   Once created, the Export option generates two files: a chapters
--   JSON file, and a VTS text file. The VTS file's contents should be
--   pasted into your episode's RSS feed entry, inside the episode's
--   `<podcast:value>` tag.
--
--   Requires python3 (or python on Windows) on PATH, and a free
--   PodcastIndex API key/secret (https://api.podcastindex.org/) which
--   the script will prompt you for on first use of "VTS Insert".
-- @changelog
--   Initial public release

--[[
================================================================================
 PodcastIndex Search -> Value4Value Remote-Item Region Stamper (Reaper)
 + Podcasting 2.0 Chapters (JSON) & VTS RSS XML (TXT) Exporter
================================================================================

 This tool adds Podcasting 2.0 chapters and Value Time Split (VTS) regions
 to your Reaper project, with feed/episode lookups from podcastindex.org.

 Once created, the Export option generates two files:
   - a Chapters JSON file, and
   - a VTS text file.
 The VTS file's contents should be pasted into your episode's RSS feed
 entry, inside the episode's <podcast:value> tag.

 REQUIREMENTS (for the VTS / PodcastIndex search flow)
   - python3 (or "python" on Windows) available on PATH.
   - A free PodcastIndex API key/secret: https://api.podcastindex.org/
     The first time you use "VTS Insert", the script will prompt you for
     these via a Reaper input box and remember them for next time (stored
     in Reaper's ExtState, per-machine). You can re-enter them at any time
     by clearing them in the prompt.
   - Reaper's ReaScript io/os access enabled. The first time a script in a
     session uses io.open/io.popen, Reaper may show a one-time permission
     prompt -- allow it, or this script can't write its temp files.

 Three-option menu:
   Chapter Insert - insert a plain CHAP= marker at the cursor/playhead.
   VTS Insert     - search PodcastIndex, pick a podcast + episode, and
                    insert a region (VTS=...) plus matching CHAP= markers.
   Export files   - scan the project's CHAP= markers and VTS= regions and
                    write out "<project>_chapters.json" and
                    "<project>_vts.txt" next to the project file.

================================================================================
--]]

------------------------------------------------------------------------------
-- small OS/file helpers
------------------------------------------------------------------------------

local function is_windows()
    return reaper.GetOS():match("Win") ~= nil
end

local function path_join(dir, name)
    return dir .. (is_windows() and "\\" or "/") .. name
end

local function safe_execute(cmd)
    local handle = io.popen(cmd)
    if not handle then return "" end
    local result = handle:read("*a") or ""
    handle:close()
    return result
end

local function read_file(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local c = f:read("*a")
    f:close()
    return c
end

local function write_file(path, content)
    local f = io.open(path, "w")
    if not f then return false end
    f:write(content)
    f:close()
    return true
end

-- Which command to try: "python" on Windows, "python3" everywhere else.
local function get_python_command()
    return is_windows() and "python" or "python3"
end

-- Cached across calls within a single script run so we don't re-shell-out
-- to check python's presence before every single API request.
local python_availability_cache = nil

-- Runs `python3 --version` (or `python --version` on Windows) and checks the
-- output actually looks like Python, since io.popen silently "succeeds" even
-- when the command doesn't exist -- it just produces no useful output.
local function check_python_available()
    if python_availability_cache ~= nil then
        return python_availability_cache
    end
    local python = get_python_command()
    local output = safe_execute(python .. " --version 2>&1")
    python_availability_cache = output ~= "" and output:match("[Pp]ython%s+%d") ~= nil
    return python_availability_cache
end

-- Clear, OS-specific instructions shown when python can't be found.
local function python_missing_message()
    local python = get_python_command()
    if is_windows() then
        return "Python was not found on your system PATH.\n\n" ..
            "This script needs Python 3 installed to talk to the PodcastIndex API.\n\n" ..
            "To fix this:\n" ..
            "1. Download Python 3 from https://www.python.org/downloads/\n" ..
            "2. During install, check the box that says \"Add python.exe to PATH\".\n" ..
            "3. Restart REAPER and try again.\n\n" ..
            "(The script looks for a command named \"" .. python .. "\".)"
    else
        return "Python 3 was not found on your system PATH.\n\n" ..
            "This script needs Python 3 installed to talk to the PodcastIndex API.\n\n" ..
            "To fix this:\n" ..
            "- macOS: install from https://www.python.org/downloads/ or run\n" ..
            "  \"brew install python3\" in Terminal if you use Homebrew.\n" ..
            "- Linux: install via your package manager, e.g.\n" ..
            "  \"sudo apt install python3\" (Debian/Ubuntu).\n\n" ..
            "Restart REAPER after installing and try again.\n\n" ..
            "(The script looks for a command named \"" .. python .. "\".)"
    end
end

-- Escape a Lua string into a valid, safe Python double-quoted string literal.
local function py_quote(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\")
    s = s:gsub('"', '\\"')
    s = s:gsub("\n", "\\n")
    s = s:gsub("\r", "\\r")
    s = s:gsub("\t", "\\t")
    return '"' .. s .. '"'
end

-- Turn a flat Lua table of {key=value,...} into a Python dict literal string.
local function py_dict_literal(params)
    local parts = {}
    for k, v in pairs(params) do
        parts[#parts + 1] = py_quote(k) .. ": " .. py_quote(v)
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end

------------------------------------------------------------------------------
-- minimal pure-Lua JSON decoder (objects, arrays, strings, numbers, bool/null)
------------------------------------------------------------------------------

local json = {}

function json.decode(str)
    local pos = 1

    local function skip_ws()
        local _, e = str:find("^[ \t\r\n]*", pos)
        if e then pos = e + 1 end
    end

    local parse_value

    local function parse_string()
        pos = pos + 1 -- opening quote
        local out = {}
        while true do
            local c = str:sub(pos, pos)
            if c == "" then error("unterminated string in JSON") end
            if c == '"' then
                pos = pos + 1
                return table.concat(out)
            elseif c == "\\" then
                local nc = str:sub(pos + 1, pos + 1)
                local simple = { ['"'] = '"', ['\\'] = '\\', ['/'] = '/',
                                  b = '\b', f = '\f', n = '\n', r = '\r', t = '\t' }
                if simple[nc] then
                    out[#out + 1] = simple[nc]
                    pos = pos + 2
                elseif nc == "u" then
                    local hex = str:sub(pos + 2, pos + 5)
                    local cp = tonumber(hex, 16) or 63
                    if cp < 128 then
                        out[#out + 1] = string.char(cp)
                    elseif cp < 0x800 then
                        out[#out + 1] = string.char(0xC0 + math.floor(cp / 64), 0x80 + (cp % 64))
                    else
                        out[#out + 1] = string.char(
                            0xE0 + math.floor(cp / 4096),
                            0x80 + (math.floor(cp / 64) % 64),
                            0x80 + (cp % 64))
                    end
                    pos = pos + 6
                else
                    out[#out + 1] = nc
                    pos = pos + 2
                end
            else
                out[#out + 1] = c
                pos = pos + 1
            end
        end
    end

    local function parse_number()
        local s, e = str:find("^-?%d+%.?%d*[eE]?[%+%-]?%d*", pos)
        local numstr = str:sub(s, e)
        pos = e + 1
        return tonumber(numstr)
    end

    local function parse_object()
        pos = pos + 1
        local obj = {}
        skip_ws()
        if str:sub(pos, pos) == "}" then pos = pos + 1; return obj end
        while true do
            skip_ws()
            local key = parse_string()
            skip_ws()
            pos = pos + 1 -- ':'
            skip_ws()
            obj[key] = parse_value()
            skip_ws()
            local c = str:sub(pos, pos)
            if c == "," then pos = pos + 1
            elseif c == "}" then pos = pos + 1; break
            else error("bad JSON object at pos " .. pos) end
        end
        return obj
    end

    local function parse_array()
        pos = pos + 1
        local arr = {}
        skip_ws()
        if str:sub(pos, pos) == "]" then pos = pos + 1; return arr end
        while true do
            skip_ws()
            arr[#arr + 1] = parse_value()
            skip_ws()
            local c = str:sub(pos, pos)
            if c == "," then pos = pos + 1
            elseif c == "]" then pos = pos + 1; break
            else error("bad JSON array at pos " .. pos) end
        end
        return arr
    end

    parse_value = function()
        skip_ws()
        local c = str:sub(pos, pos)
        if c == '"' then return parse_string()
        elseif c == "{" then return parse_object()
        elseif c == "[" then return parse_array()
        elseif c == "t" then pos = pos + 4; return true
        elseif c == "f" then pos = pos + 5; return false
        elseif c == "n" then pos = pos + 4; return nil
        else return parse_number()
        end
    end

    local ok, result = pcall(function()
        skip_ws()
        return parse_value()
    end)
    if not ok then return nil, result end
    return result
end

------------------------------------------------------------------------------
-- PodcastIndex API credentials -- stored per-machine in Reaper's ExtState so
-- the user is only asked once. Get your own free key/secret at:
--   https://api.podcastindex.org/
------------------------------------------------------------------------------

local EXTSTATE_SECTION = "PodcastChapterVTS"

local function get_api_credentials()
    local _, saved_key    = reaper.GetExtState(EXTSTATE_SECTION, "api_key")
    local _, saved_secret = reaper.GetExtState(EXTSTATE_SECTION, "api_secret")

    if saved_key and saved_key ~= "" and saved_secret and saved_secret ~= "" then
        return saved_key, saved_secret
    end

    local retval, csv = reaper.GetUserInputs(
        "PodcastIndex API Credentials",
        2,
        "API Key,API Secret",
        (saved_key or "") .. "," .. (saved_secret or "")
    )

    if not retval then
        return nil, nil, "PodcastIndex API key/secret are required. Get a free pair at https://api.podcastindex.org/"
    end

    local key, secret = csv:match("^([^,]*),(.*)$")
    key = (key or ""):gsub("^%s*(.-)%s*$", "%1")
    secret = (secret or ""):gsub("^%s*(.-)%s*$", "%1")

    if key == "" or secret == "" then
        return nil, nil, "PodcastIndex API key/secret are required. Get a free pair at https://api.podcastindex.org/"
    end

    reaper.SetExtState(EXTSTATE_SECTION, "api_key", key, true)
    reaper.SetExtState(EXTSTATE_SECTION, "api_secret", secret, true)

    return key, secret
end

------------------------------------------------------------------------------
-- PodcastIndex API call (auth + HTTP handled by a throwaway python helper --
-- far less error-prone than reimplementing SHA1 and urlencoding in Lua)
------------------------------------------------------------------------------

local function podcastindex_get(endpoint, params)
    local api_key, api_secret, cred_err = get_api_credentials()
    if not api_key then
        return nil, cred_err
    end

    if not check_python_available() then
        return nil, python_missing_message()
    end

    local resource_dir = reaper.GetResourcePath()
    local py_path  = path_join(resource_dir, "pi_runner_tmp.py")
    local out_path = path_join(resource_dir, "pi_runner_tmp_out.json")

    local py_source = string.format([[
import time, hashlib
import urllib.request, urllib.error, urllib.parse

api_key    = %s
api_secret = %s
endpoint   = %s
params     = %s
out_path   = %s

epoch = str(int(time.time()))
auth_hash = hashlib.sha1((api_key + api_secret + epoch).encode("utf-8")).hexdigest()

qs = urllib.parse.urlencode(params)
url = "https://api.podcastindex.org/api/1.0" + endpoint
if qs:
    url += "?" + qs

req = urllib.request.Request(url, method="GET")
req.add_header("X-Auth-Date", epoch)
req.add_header("X-Auth-Key", api_key)
req.add_header("Authorization", auth_hash)
req.add_header("User-Agent", "Reaper-PodcastIndex-Script/1.0")

try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        body = resp.read().decode("utf-8", errors="replace")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(body)
except urllib.error.HTTPError as e:
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("ERROR: HTTP " + str(e.code) + " " + e.read().decode("utf-8", errors="replace"))
except Exception as e:
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("ERROR: " + str(e))
]], py_quote(api_key), py_quote(api_secret), py_quote(endpoint), py_dict_literal(params), py_quote(out_path))

    if not write_file(py_path, py_source) then
        return nil, "Could not write temporary python helper file to " .. resource_dir
    end

    local python = get_python_command()
    safe_execute(string.format('%s "%s"', python, py_path))

    local response = read_file(out_path)

    os.remove(py_path)
    if out_path then os.remove(out_path) end

    if not response or response:match("^%s*$") then
        return nil, "No response from PodcastIndex.\n\n" ..
            "Python was found on PATH, but the request produced no output. " ..
            "This usually means network access is blocked (check your firewall " ..
            "or Reaper's network permissions) or the PodcastIndex API is unreachable."
    end
    if response:sub(1, 6) == "ERROR:" then
        return nil, response
    end

    local decoded, err = json.decode(response)
    if not decoded then
        return nil, "Could not parse PodcastIndex response as JSON: " .. tostring(err)
    end
    return decoded
end

------------------------------------------------------------------------------
-- Stage 1: search podcasts by term
------------------------------------------------------------------------------

local function search_podcasts(term)
    local data, err = podcastindex_get("/search/byterm", { q = term })
    if not data then return nil, err end

    local results = {}
    for _, f in ipairs(data.feeds or {}) do
        if f.podcastGuid and f.podcastGuid ~= "" then
            results[#results + 1] = {
                id       = f.id,
                title    = f.title or "Untitled",
                author   = f.author or f.ownerName or "Unknown",
                feedGuid = f.podcastGuid,
                art_url  = f.artwork or f.image or "",
                website  = f.link or "",
            }
        end
    end
    return results
end

------------------------------------------------------------------------------
-- Stage 2: list episodes of a chosen podcast (by feed id)
------------------------------------------------------------------------------

local function list_episodes(feed_id)
    local data, err = podcastindex_get("/episodes/byfeedid", { id = feed_id, max = "30" })
    if not data then return nil, err end

    local results = {}
    for _, it in ipairs(data.items or {}) do
        if it.guid and it.guid ~= "" then
            results[#results + 1] = {
                title         = it.title or "Untitled episode",
                itemGuid      = it.guid,
                datePublished = it.datePublishedPretty or "",
                art_url       = it.image or it.feedImage or "",
                website       = it.link or "",
                duration      = tonumber(it.duration) or 0, -- episode length in seconds, per PodcastIndex
            }
        end
    end
    return results
end

------------------------------------------------------------------------------
-- list chooser -- a real popup menu via gfx.showmenu, so results are
-- actually visible and clickable instead of crammed into a text caption.
------------------------------------------------------------------------------

local function build_menu_string(list, label_fn)
    local parts = {}
    for i, item in ipairs(list) do
        local label = label_fn(item)
        -- gfx.showmenu treats & as an accelerator marker and | as the item
        -- separator, and a leading '<' or '>' as submenu syntax -- escape
        -- all of that so titles/authors can't corrupt the menu.
        label = label:gsub("&", "&&")
        label = label:gsub("|", "/")
        label = label:gsub("^[<>]+", "")
        if #label > 90 then label = label:sub(1, 87) .. "..." end
        parts[#parts + 1] = string.format("%d. %s", i, label)
    end
    return table.concat(parts, "|")
end

local function choose_from_list(dlg_title, list, label_fn)
    if #list == 0 then return nil end
    local menu_str = build_menu_string(list, label_fn)

    local mx, my = reaper.GetMousePosition()
    gfx.init(dlg_title, 0, 0, 0, mx, my)
    gfx.x, gfx.y = 0, 0
    local sel = gfx.showmenu(menu_str)
    gfx.quit()

    if sel == 0 then return nil end -- user dismissed the menu
    return list[sel]
end

------------------------------------------------------------------------------
-- region insertion
------------------------------------------------------------------------------

local function sanitize(s)
    return (s or ""):gsub("[|\r\n]", " ")
end

-- Chapter-marker text can't safely contain a literal quote or newline since
-- it would break the CHAP="Title" by Artist format.
local function sanitize_chap(s)
    return (s or ""):gsub('["\r\n]', " ")
end

-- Playback position takes priority over the edit cursor if transport is
-- rolling, so markers land where you're actually listening.
local function current_position()
    if reaper.GetPlayState() ~= 0 then
        return reaper.GetPlayPosition()
    end
    return reaper.GetCursorPosition()
end

local function insert_region(feedGuid, itemGuid, title, artist, image_url, website_url, duration_hint)
    local start_pos = current_position()

    local region_start, region_end
    local sel_start, sel_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

    if sel_end and sel_end > sel_start then
        region_start, region_end = sel_start, sel_end
    else
        -- Default the length prompt to the song's actual duration (from PodcastIndex),
        -- falling back to 30s if no duration was reported.
        local default_len = "30"
        if duration_hint and duration_hint > 0 then
            default_len = tostring(duration_hint)
        end
        local ok, len_str = reaper.GetUserInputs("Region Length", 1, "Region length in seconds:", default_len)
        local len = (ok and tonumber(len_str)) or tonumber(default_len) or 30
        if not len or len <= 0 then len = 30 end
        region_start = start_pos
        region_end = start_pos + len
    end

    local region_name = string.format(
        "VTS=title=%s|feedGuid=%s|itemGuid=%s|image=%s|website=%s",
        sanitize(title), sanitize(feedGuid), sanitize(itemGuid), sanitize(image_url), sanitize(website_url)
    )

    local chap_name = string.format('CHAP="%s" by %s', sanitize_chap(title), sanitize_chap(artist))

    reaper.Undo_BeginBlock()
    reaper.AddProjectMarker2(0, true, region_start, region_end, region_name, -1, 0)
    reaper.AddProjectMarker2(0, false, region_start, 0, chap_name, -1, 0)
    reaper.AddProjectMarker2(0, false, region_end, 0, chap_name, -1, 0)
    reaper.UpdateTimeline()
    reaper.Undo_EndBlock("Insert PodcastIndex remote-item region", -1)

    return region_start, region_end
end

------------------------------------------------------------------------------
-- plain chapter marker (no PodcastIndex lookup -- just a name and a point)
------------------------------------------------------------------------------

local function insert_chapter_marker()
    local ok, name = reaper.GetUserInputs("Insert Chapter Marker", 1, "Chapter name:", "")
    if not ok or name == "" then return end

    local pos = current_position()
    local marker_name = "CHAP=" .. sanitize(name)

    reaper.Undo_BeginBlock()
    reaper.AddProjectMarker2(0, false, pos, 0, marker_name, -1, 0)
    reaper.UpdateTimeline()
    reaper.Undo_EndBlock("Insert chapter marker", -1)

    reaper.ShowMessageBox(string.format("Chapter marker added at %.2fs\n\n%s", pos, marker_name),
        "Chapter Marker Added", 0)
end

------------------------------------------------------------------------------
-- PodcastIndex search -> VTS region + CHAP markers flow
------------------------------------------------------------------------------

local function run_vts_flow()
    local ok, term = reaper.GetUserInputs("Search PodcastIndex", 1, "Album / Artist / Podcast title:", "")
    if not ok or term == "" then return end

    local podcasts, err = search_podcasts(term)
    if not podcasts then
        reaper.ShowMessageBox("PodcastIndex search failed:\n\n" .. tostring(err), "Search Error", 0)
        return
    end
    if #podcasts == 0 then
        reaper.ShowMessageBox("No podcasts found for '" .. term .. "'.", "No Results", 0)
        return
    end

    local podcast = choose_from_list("Select Podcast", podcasts,
        function(p) return string.format("[%s] %s", p.author, p.title) end)
    if not podcast then return end

    local episodes, eerr = list_episodes(podcast.id)
    if not episodes then
        reaper.ShowMessageBox("Could not fetch episodes:\n\n" .. tostring(eerr), "Episode Lookup Error", 0)
        return
    end
    if #episodes == 0 then
        reaper.ShowMessageBox("No episodes with a usable GUID were found for that podcast.", "No Episodes", 0)
        return
    end

    local episode = choose_from_list("Select Episode", episodes,
        function(e) return string.format("%s  (%s)", e.title, e.datePublished) end)
    if not episode then return end

    local image_url = episode.art_url
    if not image_url or image_url == "" then image_url = podcast.art_url end

    -- Prefer the episode's own page link; fall back to the podcast's website.
    local website_url = episode.website
    if not website_url or website_url == "" then website_url = podcast.website end

    local region_start, region_end = insert_region(podcast.feedGuid, episode.itemGuid, episode.title, podcast.author, image_url, website_url, episode.duration)

    reaper.ShowMessageBox(string.format(
        "Region + CHAP markers added at %.2fs - %.2fs\n\ntitle: %s\nartist: %s\nfeedGuid: %s\nitemGuid: %s\nimage: %s\nwebsite: %s",
        region_start, region_end, episode.title, podcast.author, podcast.feedGuid, episode.itemGuid, tostring(image_url), tostring(website_url)
    ), "Region Stamped", 0)
end

------------------------------------------------------------------------------
-- Export files: CHAP= markers -> chapters.json, VTS= regions -> vts.txt
------------------------------------------------------------------------------

-- Tolerance for comparing rounded (6-decimal) timestamps for equality
local EXPORT_TIME_EPSILON = 0.0000005

local function get_project_save_details()
    local _, project_path = reaper.EnumProjects(-1, "")
    if project_path and project_path ~= "" then
        local project_dir = project_path:match("(.*[/\\])")
        local filename = project_path:match("[^/\\]+$")
        local base_name = filename:gsub("%.[Rr][Pp][Pp]$", "")
        return project_dir, base_name
    else
        return nil, "untitled_project"
    end
end

local function get_start_marker_offset()
    local _, num_markers, num_regions = reaper.CountProjectMarkers(0)
    local total_elements = num_markers + num_regions
    for i = 0, total_elements - 1 do
        local _, is_region, position_seconds, _, name, _ = reaper.EnumProjectMarkers3(0, i)
        if not is_region and name and name == "=START" then
            return position_seconds
        end
    end
    return 0.0
end

-- Parses a pipe-delimited key=value string, e.g.:
--   title=Save Me Tonight|feedGuid=abc-123|itemGuid=01x|image=https://...
-- Returns a table: { title = "...", feedGuid = "...", itemGuid = "...", image = "..." }
local function parse_kv_payload(payload)
    local fields = {}
    for pair in payload:gmatch("([^|]+)") do
        -- key = everything up to the first "=", value = the rest (trimmed)
        local key, value = pair:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
        if key then
            fields[key] = value
        end
    end
    return fields
end

local function process_timeline_elements(offset)
    local chapters = {}
    local vts_splits = {}
    local _, num_markers, num_regions = reaper.CountProjectMarkers(0)
    local total_elements = num_markers + num_regions

    for i = 0, total_elements - 1 do
        local _, is_region, pos_start, pos_end, name, _ = reaper.EnumProjectMarkers3(0, i)

        if name and name ~= "" then
            -- 1. PROCESS CHAPTER MARKERS
            if not is_region and name:sub(1, 5) == "CHAP=" then
                local clean_title = name:sub(6):gsub("^%s*(.-)%s*$", "%1")
                local adjusted_time = math.max(0.0, pos_start - offset)
                table.insert(chapters, {
                    startTime = math.floor(adjusted_time * 1000000 + 0.5) / 1000000, -- 6 decimals
                    title = clean_title,
                    img = "", -- may be filled in later from a co-located VTS region
                    url = ""  -- may be filled in later from a co-located VTS region
                })

            -- 2. PROCESS VTS REGIONS (pipe-delimited key=value format)
            elseif is_region and name:sub(1, 4) == "VTS=" then
                local raw_payload = name:sub(5):gsub("^%s*(.-)%s*$", "%1")
                local adjusted_start = math.max(0.0, pos_start - offset)
                local adjusted_end = math.max(0.0, pos_end - offset)
                local duration = adjusted_end - adjusted_start

                local fields = parse_kv_payload(raw_payload)
                local feed_guid = fields.feedGuid or "MISSING_FEED_GUID"
                local item_guid = fields.itemGuid or "MISSING_ITEM_GUID"
                local vts_title = fields.title or ""
                local vts_image = fields.image or ""
                local vts_website = fields.website or ""

                if duration > 0 then
                    table.insert(vts_splits, {
                        startTime = math.floor(adjusted_start * 1000000 + 0.5) / 1000000, -- 6 decimals
                        duration = math.floor(duration * 1000000 + 0.5) / 1000000,
                        feedGuid = feed_guid,
                        itemGuid = item_guid,
                        title = vts_title,
                        image = vts_image,
                        website = vts_website
                    })
                end
            end
        end
    end

    -- Sort arrays sequentially
    table.sort(chapters, function(a, b) return a.startTime < b.startTime end)
    table.sort(vts_splits, function(a, b) return a.startTime < b.startTime end)

    return chapters, vts_splits
end

-- Matches VTS regions to chapters by exact (offset-adjusted, rounded) start time,
-- and copies the VTS 'image'/'website' fields into the chapter's "img"/"url"
-- fields when found.
local function match_media_to_chapters(chapters, vts_splits)
    for _, chap in ipairs(chapters) do
        for _, split in ipairs(vts_splits) do
            if math.abs(chap.startTime - split.startTime) < EXPORT_TIME_EPSILON then
                if split.image and split.image ~= "" then
                    chap.img = split.image
                end
                if split.website and split.website ~= "" then
                    chap.url = split.website
                end
                break
            end
        end
    end
end

local function export_files()
    local start_offset = get_start_marker_offset()
    local chapters, vts_splits = process_timeline_elements(start_offset)

    if #chapters == 0 and #vts_splits == 0 then
        reaper.ShowMessageBox("No elements starting with 'CHAP=' or 'VTS=' were found.", "No Data Found", 0)
        return
    end

    match_media_to_chapters(chapters, vts_splits)

    local project_dir, project_name = get_project_save_details()
    local base_filepath = ""

    if project_dir and project_name then
        -- Replace spaces with underscores in the filename only, not the directory path.
        local safe_name = project_name:gsub(" ", "_")
        base_filepath = project_dir .. safe_name
    else
        reaper.ShowMessageBox("Could not automatically resolve project folder. Please choose a file path location.", "Path Resolution", 0)
        local retval, chosen_path = reaper.GetUserFileNameForRead("untitled_project_chapters.json", "Save Files Base Path", "json")
        if not retval or chosen_path == "" then return end
        local chosen_dir = chosen_path:match("(.*[/\\])") or ""
        local chosen_base = chosen_path:match("[^/\\]+$") or chosen_path
        chosen_base = chosen_base:gsub("%.[Jj][Ss][Oo][Nn]$", ""):gsub(" ", "_")
        base_filepath = chosen_dir .. chosen_base
    end

    local json_filepath = base_filepath .. "_chapters.json"
    local txt_filepath = base_filepath .. "_vts.txt"

    -- 1. WRITE CHAPTERS TO JSON FILE
    if #chapters > 0 then
        local json_file = io.open(json_filepath, "w")
        if json_file then
            json_file:write("{\n  \"version\": \"1.2.0\",\n  \"chapters\": [\n")
            for i, chap in ipairs(chapters) do
                json_file:write("    {\n")
                local start_time_line = string.format("      \"startTime\": %f,\n", chap.startTime):gsub("0+$", ""):gsub("%.$", ".0")
                json_file:write(start_time_line)
                json_file:write(string.format("      \"title\": %q,\n", chap.title))
                json_file:write(string.format("      \"img\": %q,\n", chap.img or ""))
                json_file:write(string.format("      \"url\": %q\n", chap.url or ""))
                json_file:write(i < #chapters and "    },\n" or "    }\n")
            end
            json_file:write("  ]\n}")
            json_file:close()
        end
    end

    -- 2. WRITE VALUE TIME SPLITS TO TXT FILE (INDENTED REMOTE ITEM XML FORMAT)
    if #vts_splits > 0 then
        local txt_file = io.open(txt_filepath, "w")
        if txt_file then
            for _, split in ipairs(vts_splits) do
                -- Format output numbers cleanly up to 6 decimal precision
                local s_time = string.format("%f", split.startTime):gsub("0+$", ""):gsub("%.$", ".0")
                local d_time = string.format("%f", split.duration):gsub("0+$", ""):gsub("%.$", ".0")

                -- Applied 8-space and 12-space indentation to the nested tag block
                txt_file:write(string.format("        <podcast:valueTimeSplit startTime=%q remotePercentage=\"99\" duration=%q>\n", s_time, d_time))
                txt_file:write(string.format("            <podcast:remoteItem feedGuid=%q itemGuid=%q/>\n", split.feedGuid, split.itemGuid))
                txt_file:write("        </podcast:valueTimeSplit>\n\n")
            end
            txt_file:close()
        end
    end

    local feedback = string.format("Successfully exported files!\n\nChapters JSON: %d items\nVTS RSS XML (.txt): %d items", #chapters, #vts_splits)
    if #vts_splits > 0 then
        feedback = feedback .. "\n\nPaste the contents of the VTS .txt file into your episode's " ..
            "RSS feed entry, inside the episode's <podcast:value> tag."
    end
    reaper.ShowMessageBox(feedback, "Export Complete", 0)
end

------------------------------------------------------------------------------
-- main -- Chapter / VTS / Export files chooser via gfx.showmenu
------------------------------------------------------------------------------

local function choose_mode()
    local mx, my = reaper.GetMousePosition()
    gfx.init("Add Marker Type", 0, 0, 0, mx, my)
    gfx.x, gfx.y = 0, 0
    local sel = gfx.showmenu("Chapter Insert|VTS Insert|Export files")
    gfx.quit()

    if sel == 1 then return "chapter"
    elseif sel == 2 then return "vts"
    elseif sel == 3 then return "export"
    else return nil end
end

local function main()
    local mode = choose_mode()
    if mode == "chapter" then
        insert_chapter_marker()
    elseif mode == "vts" then
        run_vts_flow()
    elseif mode == "export" then
        export_files()
    end
    -- else: menu dismissed with no selection, do nothing
end

main()

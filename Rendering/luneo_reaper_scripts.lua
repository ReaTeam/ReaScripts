-- @description luneo Markers to CUE sheet and chapter tags
-- @author Luneo
-- @version 2.0
-- @changelog
--   --   v2.0:
--   --     Add album, artist, genre, date and title tags to FFMETADATA output
--   --   v1.9:
--   --     Add support for FFMETADATA format
--   --   v1.8:
--   --     Add support for opus files (via opustags)
--   --   v1.7:
--   --     Update changelog
--   --   v1.6:
--   --     Add dialog field for metaflac path
--   --     Add none option for output to only embed chapter data into flac file
--   --   v1.5:
--   --     Album defaults to the project title, artist to the project author
--   --   v1.4:
--   --      Add changelog info
--   --   v1.3: 
--   --      Settings dialog now also asks for Album, Artist, Date and Genre
--   --      Album defaults to the project title, artist to the project author
--   --      Added y/n switches for embedding tags and for the native CUESHEET block
--   --   v1.2:
--   --     Embedding writes ALBUM, ARTIST, ALBUMARTIST, TITLE, DATE and GENRE
--   --     Output location can be picked as a file or as a folder
--   --     Added CONFIG.METAFLAC for an absolute path when REAPER cannot find it
--   --   v1.1:
--   --     metaflac errors are shown in the console instead of a bare exit code
--   --     Chapter tags are read back after embedding to confirm they were written
--   --     Warn that the native CUESHEET block hides chapter titles in mpv and VLC
--   --     Fixed cancelling the save dialog falling through to the default path
--   --   v1.0:
--   --     Initial release
-- @provides [main] luneo_reaper_scripts/luneo_Markers_to_CUE_sheet_and_chapter_tags.lua
-- @about
--   # Luneo reaper_scripts
--
--   ## Markers to CUE sheet and chapter tags
--
--   Turns the markers of the open project into the two metadata formats a rendered
--   mix needs: a **CUE sheet** for CD-oriented tools and rippers, and **chapter
--   tags** for players. Optionally writes both into the rendered FLAC in one step.
--   Another optional target output format is the FFMETADATA format for ffmpeg.
--   This format allows the data to be embedded in several other formats that support
--   chapters (like aac/mp4).
--
--   The point is to skip the detour through REAPER's marker export and instead directly
--   export them to the desired format or even embed them right into the exported file
--   (embedding supported for flac and opus files)
--
--   ### Input
--
--   The markers of the currently open project. Marker names are split at `" - "`
--   into performer and title, so a marker called `Anna Joyce - Eu Esperei` becomes:
--
--   ```
--   TITLE "Eu Esperei"
--   PERFORMER "Anna Joyce"
--   ```
--
--   Names without that separator become the title alone. **Regions are not tracks** —
--   the earliest region defines the offset, so times can be made relative to the
--   start of the rendered audio rather than to the project timeline.
--
--   ### Output
--
--   Three files next to the project (or wherever you point the dialog):
--
--   | File | Contents |
--   | --- | --- |
--   | `<name>.cue` | Standard CUE sheet, `MM:SS:FF` at 75 frames per second |
--   | `<name>_chapters.txt` | `CHAPTER001=00:00:00.400` / `CHAPTER001NAME=…` pairs, millisecond precision |
--   | `<name>.ffmeta` | optional, ffmpeg FFMETADATA: chapters with start and end, plus key/value metadata |
--
--   With embedding enabled, the tagger writes into the audio file -- `metaflac` for
--   `.flac`, `opustags` for `.opus`:
--
--   - the chapter tags, so players show a titled chapter list
--   - the cue sheet as a `CUESHEET` vorbis comment, which keeps track titles and
--     performers readable by foobar2000 and similar tools
--   - `ALBUM`, `ARTIST`, `ALBUMARTIST`, `TITLE`, `DATE` and `GENRE`
--
--   Existing `CHAPTER*` tags are removed first, so running the script twice does not
--   duplicate them.
--
--   FFMETADATA is ffmpeg's own metadata format. Unlike the tag based formats it
--   stores an end time per chapter, which is what containers without Vorbis
--   comments need, and it can carry arbitrary key/value metadata alongside. Feed it
--   to any ffmpeg invocation:
--
--   ```
--   ffmpeg -i audio.ext -i name.ffmeta -map_metadata 1 -map_chapters 1 -c copy out.ext
--   ```
--
--   The end of the last chapter comes from the render region, so nothing has to be
--   measured afterwards.
--
--   Output mode `none` skips the cue and chapter files entirely: both are still built, but in a
--   temporary location, and are deleted again once the tags are in the FLAC.
--
--   ### Usage
--
--   Run the action. A file browser asks where to save, then one dialog collects
--   everything else — base name, audio file name, offset, which files to write, the
--   album tags, and two `y/n` switches for embedding. Album and artist are
--   pre-filled from **Project Settings → Notes**, the date from the current month.
--
--   Defaults that do not need a dialog live in the `CONFIG` block at the top of the
--   script; set `ASK = false` to skip the dialog entirely.
--
--   ### Requirements
--
--   REAPER with Lua ReaScript support. Embedding additionally needs `metaflac` from
--   the [FLAC tools](https://xiph.org/flac/) on the `PATH` — if REAPER cannot find
--   it (common on macOS, where a GUI app does not inherit the shell environment),
--   put the absolute path into `CONFIG.METAFLAC`. Same with opustags.
--
--   ### A note on the native CUESHEET block
--
--   The dialog offers writing FLAC's own `CUESHEET` metadata block. Leave it off
--   unless you specifically need it. That block mirrors a CD table of contents and
--   has no title fields, and ffmpeg-based players (mpv, VLC) prefer it over the
--   chapter tags — so enabling it makes chapter titles disappear. To undo:
--
--   ```
--   metaflac --remove --block-type=CUESHEET yourfile.flac
--   ```

<?xml version="1.0" encoding="utf-8"?>
<index version="1" name="reaper_scripts" commit="d5a3e73d2c19026bfa76555ca0c096937d4deaf8">
  <category name="Rendering">
    <reapack name="luneo_Markers_to_CUE_sheet_and_chapter_tags.lua" type="script" desc="Markers to CUE sheet and chapter tags">
      <metadata>
        <description><![CDATA[{\rtf1\ansi\deff0{\fonttbl{\f0 \fswiss Helvetica;}{\f1 \fmodern Courier;}}
{\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
\widowctrl\hyphauto

{\pard \ql \f0 \sa180 \li0 \fi0 \outlinelevel0 \b \fs36 Markers to CUE sheet and chapter tags\par}
{\pard \ql \f0 \sa180 \li0 \fi0 Reads markers and regions straight from the open REAPER project and writes a CUE sheet and/or a Vorbis comment file containing CHAPTERxxx tags, and can embed both into a FLAC (metaflac) or an Opus file (opustags). Optionally it also writes FFMETADATA, ffmpeg's own chapter and metadata format, which carries an end time per chapter. Positions arrive at full precision instead of being quantised to the frame grid of the marker export.\par}
{\pard \ql \f0 \sa180 \li0 \fi0 The first region defines the offset, so times can be made relative to the rendered audio file. Optionally calls {\f1 metaflac} afterwards to embed both the chapter tags and the cue sheet into a FLAC file.\par}
{\pard \ql \f0 \sa180 \li0 \fi0 Settings live in the CONFIG block at the top of the script.\par}
}
]]></description>
        <link rel="website">https://codeberg.org/luneo/reaper_scripts</link>
      </metadata>
      <version name="1.6" author="Luneo" time="2026-09-01T22:53:36Z">
        <changelog><![CDATA[Settings dialog now also asks for Album, Artist, Date and Genre
Added y/n switches for embedding tags and for the native CUESHEET block
Embedding writes ALBUM, ARTIST, ALBUMARTIST, TITLE, DATE and GENRE
Output location can be picked as a file or as a folder
Added output mode "none" which embeds without leaving files behind
metaflac errors are shown in the console instead of a bare exit code
Chapter tags are read back after embedding to confirm they were written
Warn that the native CUESHEET block hides chapter titles in mpv and VLC
Album defaults to the project title, artist to the project author
metaflac path is a dialog field now and is remembered between runs
Fixed cancelling the save dialog falling through to the default path]]></changelog>
        <source main="main">https://codeberg.org/luneo/reaper_scripts/raw/b32c93f44d7f3818ca26d1b70595145f88150b7a/Rendering/luneo_Markers_to_CUE_sheet_and_chapter_tags.lua</source>
      </version>
      <version name="1.7" author="Luneo" time="2026-09-01T23:06:28Z">
        <changelog><![CDATA[v1.6:
  Add dialog field for metaflac path
  Add none option for output to only embed chapter data into flac file
v1.5:
  Album defaults to the project title, artist to the project author
v1.4:
   Add changelog info
v1.3: 
   Settings dialog now also asks for Album, Artist, Date and Genre
   Album defaults to the project title, artist to the project author
   Added y/n switches for embedding tags and for the native CUESHEET block
v1.2:
  Embedding writes ALBUM, ARTIST, ALBUMARTIST, TITLE, DATE and GENRE
  Output location can be picked as a file or as a folder
  Added CONFIG.METAFLAC for an absolute path when REAPER cannot find it
v1.1:
  metaflac errors are shown in the console instead of a bare exit code
  Chapter tags are read back after embedding to confirm they were written
  Warn that the native CUESHEET block hides chapter titles in mpv and VLC
  Fixed cancelling the save dialog falling through to the default path
v1.0:
  Initial release]]></changelog>
        <source main="main">https://codeberg.org/luneo/reaper_scripts/raw/cbf3145293f5da725bd1fb45087d999a73fd856f/Rendering/luneo_Markers_to_CUE_sheet_and_chapter_tags.lua</source>
      </version>
      <version name="1.1" author="YOUR NAME" time="2026-09-02T00:45:31Z">
        <changelog><![CDATA[v1.8:
  Add support for opus files (via opustags)
v1.7:
  Update changelog
v1.6:
  Add dialog field for metaflac path
  Add none option for output to only embed chapter data into flac file
v1.5:
  Album defaults to the project title, artist to the project author
v1.4:
   Add changelog info
v1.3: 
   Settings dialog now also asks for Album, Artist, Date and Genre
   Album defaults to the project title, artist to the project author
   Added y/n switches for embedding tags and for the native CUESHEET block
v1.2:
  Embedding writes ALBUM, ARTIST, ALBUMARTIST, TITLE, DATE and GENRE
  Output location can be picked as a file or as a folder
  Added CONFIG.METAFLAC for an absolute path when REAPER cannot find it
v1.1:
  metaflac errors are shown in the console instead of a bare exit code
  Chapter tags are read back after embedding to confirm they were written
  Warn that the native CUESHEET block hides chapter titles in mpv and VLC
  Fixed cancelling the save dialog falling through to the default path
v1.0:
  Initial release]]></changelog>
        <source main="main">https://codeberg.org/luneo/reaper_scripts/raw/4b8961bc45543d850af740bdf843a5381fe0f063/Rendering/luneo_Markers_to_CUE_sheet_and_chapter_tags.lua</source>
      </version>
      <version name="1.8" author="Luneo" time="2026-09-02T00:50:30Z">
        <changelog><![CDATA[v1.8:
  Add support for opus files (via opustags)
v1.7:
  Update changelog
v1.6:
  Add dialog field for metaflac path
  Add none option for output to only embed chapter data into flac file
v1.5:
  Album defaults to the project title, artist to the project author
v1.4:
   Add changelog info
v1.3: 
   Settings dialog now also asks for Album, Artist, Date and Genre
   Album defaults to the project title, artist to the project author
   Added y/n switches for embedding tags and for the native CUESHEET block
v1.2:
  Embedding writes ALBUM, ARTIST, ALBUMARTIST, TITLE, DATE and GENRE
  Output location can be picked as a file or as a folder
  Added CONFIG.METAFLAC for an absolute path when REAPER cannot find it
v1.1:
  metaflac errors are shown in the console instead of a bare exit code
  Chapter tags are read back after embedding to confirm they were written
  Warn that the native CUESHEET block hides chapter titles in mpv and VLC
  Fixed cancelling the save dialog falling through to the default path
v1.0:
  Initial release]]></changelog>
        <source main="main">https://codeberg.org/luneo/reaper_scripts/raw/692a497e477ca1dd0d55af760334f6e1203b41fa/Rendering/luneo_Markers_to_CUE_sheet_and_chapter_tags.lua</source>
      </version>
      <version name="1.9" author="Luneo" time="2026-09-02T01:36:44Z">
        <changelog><![CDATA[v1.9:
  Add support for FFMETADATA format
v1.8:
  Add support for opus files (via opustags)
v1.7:
  Update changelog
v1.6:
  Add dialog field for metaflac path
  Add none option for output to only embed chapter data into flac file
v1.5:
  Album defaults to the project title, artist to the project author
v1.4:
   Add changelog info
v1.3: 
   Settings dialog now also asks for Album, Artist, Date and Genre
   Album defaults to the project title, artist to the project author
   Added y/n switches for embedding tags and for the native CUESHEET block
v1.2:
  Embedding writes ALBUM, ARTIST, ALBUMARTIST, TITLE, DATE and GENRE
  Output location can be picked as a file or as a folder
  Added CONFIG.METAFLAC for an absolute path when REAPER cannot find it
v1.1:
  metaflac errors are shown in the console instead of a bare exit code
  Chapter tags are read back after embedding to confirm they were written
  Warn that the native CUESHEET block hides chapter titles in mpv and VLC
  Fixed cancelling the save dialog falling through to the default path
v1.0:
  Initial release]]></changelog>
        <source main="main">https://codeberg.org/luneo/reaper_scripts/raw/ee78183127ee7172a1e01ccd3dcc0a69d717414f/Rendering/luneo_Markers_to_CUE_sheet_and_chapter_tags.lua</source>
      </version>
      <version name="2.0" author="Luneo" time="2026-09-02T01:47:44Z">
        <changelog><![CDATA[v2.0:
  Add album, artist, genre, date and title tags to FFMETADATA output
v1.9:
  Add support for FFMETADATA format
v1.8:
  Add support for opus files (via opustags)
v1.7:
  Update changelog
v1.6:
  Add dialog field for metaflac path
  Add none option for output to only embed chapter data into flac file
v1.5:
  Album defaults to the project title, artist to the project author
v1.4:
   Add changelog info
v1.3: 
   Settings dialog now also asks for Album, Artist, Date and Genre
   Album defaults to the project title, artist to the project author
   Added y/n switches for embedding tags and for the native CUESHEET block
v1.2:
  Embedding writes ALBUM, ARTIST, ALBUMARTIST, TITLE, DATE and GENRE
  Output location can be picked as a file or as a folder
  Added CONFIG.METAFLAC for an absolute path when REAPER cannot find it
v1.1:
  metaflac errors are shown in the console instead of a bare exit code
  Chapter tags are read back after embedding to confirm they were written
  Warn that the native CUESHEET block hides chapter titles in mpv and VLC
  Fixed cancelling the save dialog falling through to the default path
v1.0:
  Initial release]]></changelog>
        <source main="main">https://codeberg.org/luneo/reaper_scripts/raw/d5a3e73d2c19026bfa76555ca0c096937d4deaf8/Rendering/luneo_Markers_to_CUE_sheet_and_chapter_tags.lua</source>
      </version>
    </reapack>
  </category>
</index>

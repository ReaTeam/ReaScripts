--[[
@description One Small Step : Alternative Step Input
@version 0.9.21
@author Ben 'Talagan' Babut
@license MIT
@metapackage
@changelog
  - [Cosmetics] Adapted to ImGui 0.10
@provides
  [main=main,midi_editor] .
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change input mode - (MIDI).lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change input mode.lua             > talagan_OneSmallStep/actions/talagan_OneSmallStep Change input mode - KeyboardPress.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change input mode.lua             > talagan_OneSmallStep/actions/talagan_OneSmallStep Change input mode - KeyboardRelease.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change input mode.lua             > talagan_OneSmallStep/actions/talagan_OneSmallStep Change input mode - Punch.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change edit mode - (MIDI).lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change edit mode.lua              > talagan_OneSmallStep/actions/talagan_OneSmallStep Change edit mode - Write.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change edit mode.lua              > talagan_OneSmallStep/actions/talagan_OneSmallStep Change edit mode - Navigate.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change edit mode.lua              > talagan_OneSmallStep/actions/talagan_OneSmallStep Change edit mode - Replace.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change edit mode.lua              > talagan_OneSmallStep/actions/talagan_OneSmallStep Change edit mode - Insert.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change edit mode.lua              > talagan_OneSmallStep/actions/talagan_OneSmallStep Change edit mode - Repitch.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len param source - (MIDI).lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len param source.lua  > talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len param source - OSS.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len param source.lua  > talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len param source - ItemConf.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len param source.lua  > talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len param source - ProjectGrid.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len modifier - (MIDI).lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len modifier.lua      > talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len modifier - Straight.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len modifier.lua      > talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len modifier - Triplet.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len modifier.lua      > talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len modifier - Dotted.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len modifier.lua      > talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len modifier - Modified.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len modifier.lua      > talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len modifier - Tuplet.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len - (MIDI).lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len.lua               > talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len - 1_64.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len.lua               > talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len - 1_32.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len.lua               > talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len - 1_16.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len.lua               > talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len - 1_8.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len.lua               > talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len - 1_4.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len.lua               > talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len - 1_2.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len.lua               > talagan_OneSmallStep/actions/talagan_OneSmallStep Change note len - 1.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action.lua                   > talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action - Commit.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action.lua                   > talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action - CommitBack.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action.lua                   > talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action - Insert.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action.lua                   > talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action - InsertBack.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action.lua                   > talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action - Write.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action.lua                   > talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action - WriteBack.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action.lua                   > talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action - Replace.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action.lua                   > talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action - ReplaceBack.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action.lua                   > talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action - Navigate.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action.lua                   > talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action - NavigateBack.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action.lua                   > talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action - Repitch.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action.lua                   > talagan_OneSmallStep/actions/talagan_OneSmallStep Edit Action - RepitchBack.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Increase note len.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Decrease note len.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Cleanup helper JSFXs.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Set or remove operation marker.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Set or remove playback marker.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Playback.lua
  [main=main,midi_editor] talagan_OneSmallStep/actions/talagan_OneSmallStep Toggle armed.lua
  [nomain] talagan_OneSmallStep/actions/talagan_OneSmallStep Toggle Debugger.lua
  [nomain] talagan_OneSmallStep/classes/**/*.lua
  [nomain] talagan_OneSmallStep/images/*.lua
  [effect] talagan_OneSmallStep/One Small Step Helper.jsfx
  [data] talagan_OneSmallStep/toolbar_icons/toolbar_one_small_step.png > toolbar_icons/toolbar_one_small_step.png
  [data] talagan_OneSmallStep/toolbar_icons/toolbar_one_small_step_cleanup.png > toolbar_icons/toolbar_one_small_step_cleanup.png
@screenshot
  https://stash.reaper.fm/48269/oss_094.png
@about
  # Purpose

    One Small Step is a tool for performing MIDI note step input in REAPER. It is an alternative to the standard step input, offering more control and tools, and making allowing the use of the sustain pedal (+ keyboard modifier keys) for validating things. It offers multiple input modes, based on keyboard press/release events, or with strict pedal/action validation. It allows inputing, inserting, erasing, translating notes with minimal use of the mouse. . It will work outside of the MIDI editor (directly in the arrange view), as long as you've selected a MIDI item and set the cursor at the right position ; this offers additional comfort and can speed up your workflow. It also addresses some issues with workflows that use the input FX chain for routing/transposing MIDI (because Reaper's standard input bypasses the fx input chain).

  # Install Notes

    This script also needs the JS_ReaScriptAPI api by Julian Sader and the ReaImGui library by Christian Fillion to work. Please install them alongside (OSS will remind you to do so anyway). A restart of Reaper is needed after install.

  # Reaper forum thread

    The official discussion thread is located here : https://forum.cockos.com/showthread.php?t=288076

  # Documentation

    The documentation for all versions is located here : https://bentalagan.github.io/onesmallstep-doc/

  # Credits

    One Small Step uses Jeremy Bernstein (sockmonkey72)'s MIDIUtils library. Thanks for the precious work !

    This tool takes a lot of inspiration in tenfour's "tenfour-step" scripts. Epic hail to tenfour for opening the way !

    Thanks to @cfillion for the precious pieces of advice when reviewing this source !

    A lot of thanks to all donators, and forum members that help this tool to get better !
    @stevie, @hipox, @MartinTL, @henu, @Thonex, @smandrap, @SoaSchas, @daodan, @inthevoid, @dahya, @User41, @Spookye, @R.Cato, @samlletas
--]]

VERSION = "0.9.21"
DOC_URL = "https://bentalagan.github.io/onesmallstep-doc/index.html?ver=" .. VERSION

PATH    = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]]

-------------------------------
-- Path and modules

package.path      =  PATH .. "talagan_OneSmallStep/"         .. "?.lua" .. ";" .. package.path
package.path      =  PATH .. "talagan_OneSmallStep/classes/" .. "?.lua" .. ";" .. package.path

--------------------------------

-- Tell the script to be terminated if relaunched.
-- Check the existence of the function for sanity (added in v 7.03)
if reaper.set_action_options ~= nil then
  reaper.set_action_options(1)
end

-------------------------------
-- Check dependencies

local function CheckReapack(func_name, api_name, search_string)
  if not reaper.APIExists(func_name) then
    local answer = reaper.MB( api_name .. " is required and you need to install it.\z
      Right-click the entry in the next window and choose to install.",
      api_name .. " not installed", 0 )
    reaper.ReaPack_BrowsePackages( search_string )
    return false
  end
  return true
end

if not CheckReapack("JS_ReaScriptAPI_Version",   "JS_ReaScriptAPI",  "js_ReaScriptAPI")     then return end
if not CheckReapack("ImGui_CreateContext",       "ReaImGUI",         "ReaImGui:")           then return end
if not CheckReapack("CF_ShellExecute",           "SWS",              "SWS/S&M Extension")  then return end

--------------------------------
-- Inner requirements

local E   = require "engine_lib"
local H   = require "helper_lib"
local DBG = require "modules/debugger"

local S   = E.S
local D   = E.D
local MK  = E.MK
local TGT = E.TGT
local F   = E.F
local ED  = E.ED
local ART = E.ART
local MOD = E.MOD

-- Get the debugger setting at launch
local DEBUGGER_IS_ON = S.getSetting("UseDebugger")

-------------------------------
-- ImGui Backward compatibility

package.path  = reaper.ImGui_GetBuiltinPath() .. '/?.lua' .. ";" .. package.path
local ImGui   = require 'imgui' '0.10.0'

-------------------------------

local ctx                   = ImGui.CreateContext('One Small Step')
local arial                 = ImGui.CreateFont("Arial", ImGui.FontFlags_None)

-------------------------------

local images = {}

local function getImage(image_name)
  if (not images[image_name]) or (not ImGui.ValidatePtr(images[image_name], 'ImGui_Image*')) then
    local bin = require("images/" .. image_name)
    images[image_name] = ImGui.CreateImageFromMem(bin)
    -- Prevent the GC from freeing this image
    ImGui.Attach(ctx, images[image_name])
  end
  return images[image_name]
end
-------------------------------
-- Other global variables

local focustimer                      = nil
local showsettings                    = nil

------------------------------

function SL()
  ImGui.SameLine(ctx)
end

function SEP(txt)
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xA0A0A0FF)
  ImGui.SeparatorText(ctx, txt)
  ImGui.PopStyleColor(ctx)
end

function XSeparator()
  ImGui.SetCursorPosY(ctx, ImGui.GetCursorPosY(ctx) + 2) ; ImGui.Text(ctx, "x ")
end

function TT(str)
  if ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_DelayNormal) then
    ImGui.SetTooltip(ctx, str)
  end
end

function ToFrac(num)
   local W = math.floor(num)
   local F = num - W
   local pn, n, N = 0, 1, 0
   local pd, d, D = 1, 0, 0
   local x, err, q, Q
   repeat
      x = x and 1 / (x - q) or F
      q, Q = math.floor(x), math.floor(x + 0.5)
      pn, n, N = n, q*n + pn, Q*n + pn
      pd, d, D = d, q*d + pd, Q*d + pd
      err = F - N/D
   until math.abs(err) < 1e-15
   return N + D*W, D, err
end

-- Since reaper gives us the note length as a float
-- Use a lookup after back conversion to fraction
-- To display the current sig
local KnownNoteLengthSignatures = {
  ['4/1']   = { icon = "note_1",    triplet = false, modif_label = "x 4" },
  ['8/3']   = { icon = "note_1",    triplet = true,  modif_label = "x 4" },
  ['6/1']   = { icon = "note_1",    triplet = false, modif_label = ". x 4" },
  ['2/1']   = { icon = "note_1",    triplet = false, modif_label = "x 2" },
  ['4/3']   = { icon = "note_1",    triplet = true,  modif_label = "x 2" },
  ['3/1']   = { icon = "note_1",    triplet = false, modif_label = ". x 2" },
  ['1/1']   = { icon = "note_1",    triplet = false, modif_label = "" },
  ['2/3']   = { icon = "note_1",    triplet = true,  modif_label = "" },
  ['3/2']   = { icon = "note_1",    triplet = false, modif_label = ". " },
  ['1/2']   = { icon = "note_1_2",  triplet = false, modif_label = "" },
  ['1/3']   = { icon = "note_1_2",  triplet = true,  modif_label = "" },
  ['3/4']   = { icon = "note_1_2",  triplet = false, modif_label = "." },
  ['1/4']   = { icon = "note_1_4",  triplet = false, modif_label = "" },
  ['1/6']   = { icon = "note_1_4",  triplet = true,  modif_label = "" },
  ['3/8']   = { icon = "note_1_4",  triplet = false, modif_label = "." },
  ['1/8']   = { icon = "note_1_8",  triplet = false, modif_label = "" },
  ['1/12']  = { icon = "note_1_8",  triplet = true,  modif_label = "" },
  ['3/16']  = { icon = "note_1_8",  triplet = false, modif_label = "." },
  ['1/16']  = { icon = "note_1_16", triplet = false, modif_label = "" },
  ['1/24']  = { icon = "note_1_16", triplet = true,  modif_label = "" },
  ['3/32']  = { icon = "note_1_16", triplet = false, modif_label = "." },
  ['1/32']  = { icon = "note_1_32", triplet = false, modif_label = "" },
  ['1/48']  = { icon = "note_1_32", triplet = true,  modif_label = "" },
  ['3/64']  = { icon = "note_1_32", triplet = false, modif_label = "." },
  ['1/64']  = { icon = "note_1_64", triplet = false, modif_label = "" },
  ['1/96']  = { icon = "note_1_64", triplet = true,  modif_label = "" },
  ['3/128'] = { icon = "note_1_64", triplet = false, modif_label = "." },
  ['1/128'] = { icon = "note_1",    triplet = false, modif_label = "x 1/128" },
  ['1/192'] = { icon = "note_1",    triplet = true,  modif_label = "x 1/128" },
  ['3/256'] = { icon = "note_1",    triplet = false, modif_label = ". x 1/128" },
}

local function QNToLabel(ctx, qn, swing)

  local n,d,e = ToFrac(qn)

  -- Do a reverse conversion to fraction
  -- And then lookup for what we know

  local sig = n .. "/" .. d
  local det = KnownNoteLengthSignatures[sig]
  if det then
    ImGui_NoteLenImg(ctx, det.icon, det.triplet, det.modif_label)
  else
    ImGui_NoteLenImg(ctx, "note_1", false, "x "..sig)
  end

  if swing ~= 0 then
    SL()
    ImGui.SetCursorPosY(ctx, ImGui.GetCursorPosY(ctx) + 2)
    ImGui.Text(ctx, "(sw) ")
  end
end


-- Indicator for the current project grid note len
local function ProjectGridLabel(ctx)
  local _, qn, swingmode, swing = reaper.GetSetProjectGrid(0, false)
  if swingmode ~= 1 then
    swing = 0
  end

  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)
  if swing == 3 then
    ImGui.TextColored(ctx, 0xC0C0C0FF, "Measure")
  else
    QNToLabel(ctx, qn, swing)
  end
  ImGui.PopStyleVar(ctx,1)
end

-- Indicator for the current MIDI item note len
local function ItemGridLabel(ctx,take)
  if not take then
    return
  end

  local grid_len, swing, note_len = reaper.MIDI_GetGrid(take)

  if note_len == 0 then
    note_len = grid_len
  end

  local qn = note_len/4

  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,0, 0)
  QNToLabel(ctx, qn, swing)
  ImGui.PopStyleVar(ctx,1)
end


local ColorSets = {
  Blue = {
    on      = 0x5080FFFF,
    off     = 0x203040FF,
    hover   = 0x3070BBFF,
    active  = 0x60A0FFFF,
    onover  = 0xFFFFFFFF,
    offover = 0xFFFFFFFF
  },
  Green = {
    on      = 0x008000FF,
    off     = 0x006000FF,
    hover   = 0x00C000FF,
    active  = 0x00C000FF,
    onover  = 0xFFFFFFFF,
    offover = 0xFFFFFFFF
  },
  Snap = {
    on      = 0x00000000,
    off     = 0x00000000,
    hover   = 0x203040FF,
    active  = 0xFFE03cFF,
    onover  = 0xFFE03cFF,
    offover = 0x808080FF
  }
}

function PushButtonColors(colorset, is_on)
  local cs = ColorSets[colorset]

  ImGui.PushStyleColor(ctx, ImGui.Col_Button, is_on and cs.on or cs.off)
  ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, cs.hover )
  ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, cs.active )
end

function PopButtonColors()
  ImGui.PopStyleColor(ctx, 3)
end

function ButtonGroupImageButton(image_name, is_on, options)

  options = options or {}

  local colorset = options['colorset'] or "Blue"
  local corner = options['corner'] or 0
  local cs = ColorSets[colorset]

  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 0, 0)

  PushButtonColors(colorset, is_on)

  ImGui.IsItemHovered(ctx)

  local ret = ImGui.ImageButton(ctx, image_name, getImage(image_name),
    20, 20,
    corner, corner,
    1 - corner, 1 - corner,
    0, (is_on) and (cs.onover) or (cs.offover))

  PopButtonColors()

  ImGui.PopStyleVar(ctx,1)

  return ret
end


function ButtonGroupTextButton(text, is_on, callback)
  if ImGui.Button(ctx, text) then
    callback()
  end
end

function ImGui_NoteLenImg(context, image_name, triplet, divider)
  ImGui.SetCursorPosY(ctx,ImGui.GetCursorPosY(ctx))
  ImGui.Image(ctx, getImage(image_name), 20, 20, 0.1, 0.1, 0.9, 0.9)

  if triplet then
    SL()
    ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) - 20)
    ImGui.SetCursorPosY(ctx, ImGui.GetCursorPosY(ctx) - 10)
    ImGui_NoteLenImg(ctx, "note_triplet")
  end

  if divider and divider ~= "" then
    SL()
    if divider:match("^.") then
      ImGui.SetCursorPosX(ctx,ImGui.GetCursorPosX(ctx) - 2)
    end
    ImGui.SetCursorPosY(ctx,ImGui.GetCursorPosY(ctx) + 3)
    ImGui.TextColored(ctx, 0xC0C0C0FF, divider .. " ")
  end
end

function ImGui_VerticalSpacer(context, height)
  ImGui.PushStyleVar(context, ImGui.StyleVar_ItemSpacing,0,0)
  ImGui.Dummy(context, 10, height)
  ImGui.PopStyleVar(context,1)
end

function MiniBarSeparator(dst)
  dst = ((dst == nil) and 6 or dst)

  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,0,0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,0,0)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing,0,0)
  ImGui.Dummy(ctx, dst, 0)
  ImGui.PopStyleVar(ctx,3)

end

function RecordBadge(track)
  local recarmed      = reaper.GetMediaTrackInfo_Value(track, "I_RECARM")
  local playState     = reaper.GetPlayState()

  ImGui.SetCursorPosY(ctx, ImGui.GetCursorPosY(ctx))

  local tt = ""
  if (recarmed == 1) and not (S.getSetting("Disarmed")) and not (S.getInputMode() == D.InputMode.None) and playState == 0 then
    local alpha = math.sin(reaper.time_precise()*4)
    local r1    = 200+math.floor(55 * alpha)
    local r2    = 120+math.floor(55 * alpha)

    -- Glowing red
    ImGui.PushStyleColor(ctx, ImGui.Col_CheckMark,      (r1 << 24) | 0x000000FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,        (r2 << 24) | 0x000000FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive,  (r2 << 24) | 0x000000FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, (r2 << 24) | 0x000000FF)

    tt = "OSS is active. Click to disarm."
  else
    -- Grey icon
    ImGui.PushStyleColor(ctx, ImGui.Col_CheckMark,      0xCCCCCCFF)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,        0x808080FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive,  0x808080FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, 0x808080FF)
    tt = "OSS is inactive."
    if  S.getSetting("Disarmed") then
      tt = tt .. " Click to rearm."
    end
  end

  ImGui.RadioButton(ctx, '##', true)
  if recarmed == 1 and playState == 0 and ImGui.IsItemClicked(ctx) then
    S.setSetting("Disarmed", not S.getSetting("Disarmed"))
  end
  TT(tt)
  ImGui.PopStyleColor(ctx, 4)
end

function RecordIssues(track)
  local recarmed      = reaper.GetMediaTrackInfo_Value(track, "I_RECARM")
  local playState     = reaper.GetPlayState()

  ImGui.AlignTextToFramePadding(ctx)
  if not (recarmed == 1) then
    ImGui.TextColored(ctx, 0x808080FF, '[Track not armed]')
  elseif S.getSetting("Disarmed") then
    ImGui.TextColored(ctx, 0x808080FF, '[OSS is disarmed]')
  elseif S.getInputMode() == D.InputMode.None then
    ImGui.TextColored(ctx, 0x808080FF, '[Input Mode is OFF]')
  elseif not (playState == 0) then
    ImGui.TextColored(ctx, 0x808080FF, '[Reaper not ready]')
  else
    ImGui.TextColored(ctx, 0x808080FF, '')
  end
end

-- Current take info label and indicators
function TakeInfo(take)
  local track         = reaper.GetMediaItemTake_Track(take)
  local _, track_name = reaper.GetTrackName(track)
  local take_name     = reaper.GetTakeName(take)

  -- Glowing indicator
  RecordBadge(track)
  SL()
  ImGui.TextColored(ctx, 0xA0A0FFFF, track_name .. " / " .. take_name)
  SL()
  RecordIssues(track)
end

-- Current track info label and indicators (if no take)
function TrackInfo(track)
  local _, track_name = reaper.GetTrackName(track)

  RecordBadge(track)
  SL()
  ImGui.TextColored(ctx, 0xA0A0FFFF, track_name .. " /")
  SL()
  ImGui.TextColored(ctx, 0xFFA0A0FF, "No Item")
  SL()
  RecordIssues(track)
end

-- MINIBAR : Input Mode
function InputModeMiniBar()
  local mode      = S.getInputMode()
  local modifkey  = S.getSetting("StepBackModifierKey")
  local mkinfo    = D.ModifierKeyLookup[modifkey]

  local pedalmanual = "\z
    The sustain pedal and the commit action :\n\n\z
    \32 - Insert held notes\n\z
    \32 - Extend already committed and still held notes\n\z
    \32 - Insert rests if no notes are held\n\z
    \n\z
    " .. mkinfo.name .. " + the sustain pedal and the commit back action :\n\n\z
    \32 - Erase back held notes if they match the cursor\n\z
    \32 - Step back if no notes are held"

  if ButtonGroupImageButton('input_mode_keyboard_press', mode == D.InputMode.KeyboardPress) then
    S.setInputMode(D.InputMode.KeyboardPress)
  end

  TT("Input Mode : Keyboard Press (Fast mode)\n\z
      \n\z
      Notes are added on keyboard key press events.\n\z
      \n\z
      Suitable for inputing notes at a high pace. It is not error\n\z
      tolerant (you get what you play), but will only aggregate \n\z
      chords if keys are pressed simultaneously.\n\z
      \n\z" .. pedalmanual)
  SL()

  if ButtonGroupImageButton('input_mode_pedal', mode == D.InputMode.Punch) then
    S.setInputMode(D.InputMode.Punch)
  end

  TT("Input Mode : Punch (Check mode)\n\z
      \n\z
      Notes are NOT added on keyboard key press/release events.\n\z
      Only the sustain pedal or commit action add notes.\n\z
      \n\z
      Suitable for validating everything by ear before input.\n\z
      Useful when testing chords or melodic ideas.\n\z
      \n\z" .. pedalmanual)
  SL()

  if ButtonGroupImageButton('input_mode_keyboard_release', mode == D.InputMode.KeyboardRelease) then
    S.setInputMode(D.InputMode.KeyboardRelease)
  end

  TT("Input Mode : Keyboard Release (Grope mode)\n\z
      \n\z
      Notes are added on keyboard key release events.\n\z
      \n\z
      Suitable for inputing notes at a low pace, correcting\n\z
      things by ear, especially for chords. This mode is error\n\z
      tolerant, but tends to aggregate and skip notes easily\n\z
      when playing fast.\n\z
      \n\z" .. pedalmanual)
  SL()

end

-- MINIBAR : Conf source
function ConfSourceMiniBar()
  local nlm = S.getNoteLenParamSource()

  if ButtonGroupImageButton('note_len_mode_oss', nlm == D.NoteLenParamSource.OSS) then
    S.setNoteLenParamSource(D.NoteLenParamSource.OSS)
  end
  TT('Note Length conf : One Small Step\n\nUse the params aside.')
  SL()

  if ButtonGroupImageButton('note_len_mode_pgrid', nlm == D.NoteLenParamSource.ProjectGrid) then
    S.setNoteLenParamSource(D.NoteLenParamSource.ProjectGrid)
  end
  TT( "Note Length conf : Project\n\nUse the project's grid conf.")
  SL()

  if ButtonGroupImageButton('note_len_mode_inote', nlm == D.NoteLenParamSource.ItemConf) then
    S.setNoteLenParamSource(D.NoteLenParamSource.ItemConf)
  end
  TT( "Note Length conf : MIDI Item\n\nUse the MIDI item's own conf.\n\n('Notes' at the bottom of the MIDI editor)")
end

-- MINIBAR : Note length
function NoteLenMiniBar(with_fracs)
  local nl = S.getNoteLen()
  for i,v in ipairs(D.NoteLenDefs) do
    if i > 1 then
      SL()
    end
    local icon = (with_fracs) and ('frac_' .. v.frac) or ('note_' .. v.id)
    if ButtonGroupImageButton(icon, nl == v.id, {corner = (with_fracs and 0 or 0.1)} ) then
        S.setNoteLen(v.id)
    end
  end
end

-- MINIBAR : Note length modifier
function NoteLenModifierMiniBar(with_fracs)

  local nmod = S.getNoteLenModifier()

  if ButtonGroupImageButton(with_fracs and 'frac_3_2' or 'note_dotted', nmod == D.NoteLenModifier.Dotted, {corner = with_fracs and 0 or 0.1}) then
    if nmod == D.NoteLenModifier.Dotted then
      S.setNoteLenModifier(D.NoteLenModifier.Straight)
    else
      S.setNoteLenModifier(D.NoteLenModifier.Dotted)
    end
  end
  TT(with_fracs and "3/2" or "Dotted")
  SL()

  if ButtonGroupImageButton(with_fracs and 'frac_2_3' or 'note_triplet', nmod == D.NoteLenModifier.Triplet, {corner = with_fracs and 0 or  0.1}) then
    if nmod == D.NoteLenModifier.Triplet then
      S.setNoteLenModifier(D.NoteLenModifier.Straight)
    else
      S.setNoteLenModifier(D.NoteLenModifier.Triplet)
    end
  end
  TT(with_fracs and "2/3" or "Triplet")
  SL()

  if ButtonGroupImageButton(with_fracs and 'frac_1_n' or 'note_tuplet', nmod == D.NoteLenModifier.Tuplet, {corner = with_fracs and 0 or  0.1}) then
    if nmod == D.NoteLenModifier.Tuplet then
      S.setNoteLenModifier(D.NoteLenModifier.Straight)
    else
      S.setNoteLenModifier(D.NoteLenModifier.Tuplet)
    end
  end
  TT(with_fracs and "1/n" or "N-tuplet")
  SL()

  if ButtonGroupImageButton('note_modified', nmod == D.NoteLenModifier.Modified ) then
    if nmod == D.NoteLenModifier.Modified then
      S.setNoteLenModifier(D.NoteLenModifier.Straight)
    else
      S.setNoteLenModifier(D.NoteLenModifier.Modified)
    end
  end
  TT(with_fracs and "n/m" or "Modified length")
end

-- Sub-params : N-tuplet
function NTupletComboBox()
  local combo_items = { '2', '3','4', '5', '6', '7', '8', '9', '10', '11', '12' }

  ImGui.AlignTextToFramePadding(ctx)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 5, 3)
  ImGui.PushID(ctx, "nlet_combo")

  local tuplet = '' .. S.getTupletDivision()

  ImGui.SetNextItemWidth(ctx,50)
  if ImGui.BeginCombo(ctx, '', tuplet) then
    for i,v in ipairs(combo_items) do
      local is_selected = (tuplet == v)
      if ImGui.Selectable(ctx, combo_items[i], is_selected) then
        S.setTupletDivision(tonumber(v))
      end
      if is_selected then
        ImGui.SetItemDefaultFocus(ctx)
      end
    end
    ImGui.EndCombo(ctx)
  end
  ImGui.PopStyleVar(ctx,1)
  ImGui.PopID(ctx)
end

-- Sub-params : Augmented/Diminished Sign/Factor
function NoteLenFactorComboBox(role) -- Numerator/Denominator

  local setting     = "NoteLenFactor" .. role
  local curval      = S.getSetting(setting)
  local combo_items = { }

  for i = 1, 32 do
    combo_items[#combo_items+1] = i
  end

  ImGui.AlignTextToFramePadding(ctx)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 5, 3)
  ImGui.PushID(ctx, "NoteLenFactor" .. role)

  ImGui.SetNextItemWidth(ctx, 45)

---@diagnostic disable-next-line: param-type-mismatch
  if ImGui.BeginCombo(ctx, '', curval) then
    for i, val in ipairs(combo_items) do

      local is_selected = (val == curval)
      if ImGui.Selectable(ctx, "" .. val, is_selected) then
        S.setSetting(setting, val)
      end
      if is_selected then
        ImGui.SetItemDefaultFocus(ctx)
      end
    end
    ImGui.EndCombo(ctx)
  end
  ImGui.PopID(ctx)
  ImGui.PopStyleVar(ctx,1)
end


-- Note AD
function AugmentedDiminishedMiniBars(with_x)
  if with_x then
    XSeparator()
    SL()
  end
  NoteLenFactorComboBox("Numerator")
  SL()
  ImGui.Text(ctx, " / ")
  SL()
  NoteLenFactorComboBox("Denominator")
end

function PlayBackMeasureCountComboBox()

  ImGui.PushID(ctx, "playback_measure_count")
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,        0x006000FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, 0x00A000FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive,  0x00C000FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_Button,         0x008000FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,  0x008000FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg,        0x006000FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_Header,         0x00C000FF)
  ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered,  0x00C000FF)

  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 5, 3)
  local curm = S.getPlaybackMeasureCount()

  local label = function(mnum)
    return ((mnum == -1) and "Mk" or mnum)
  end

  ImGui.SetNextItemWidth(ctx,46)
  if ImGui.BeginCombo(ctx, '', label(curm)) then
    for i=-1,16,1 do
      local is_selected = (curm == i)

      if ImGui.Selectable(ctx, label(i), is_selected) then
        S.setPlaybackMeasureCount(i)
      end
      if is_selected then
        ImGui.SetItemDefaultFocus(ctx)
      end
      if i == -1 then
        TT("Use OSS marker as start point for playback")
      end
    end
    ImGui.EndCombo(ctx)
  end
  ImGui.PopStyleVar(ctx,1)
  ImGui.PopStyleColor(ctx,8)
  ImGui.PopID(ctx)

  TT("Number of measures to rewind, rounded at measure start.\n\n\z
      'Mk' stands for Marker mode, the playback will start at the\n\z
      'OSS Playback' marker instead. you can set/move/remove it\n\z
      it with the button on the right.")

end

local function PlaybackButton()
  ImGui.PushID(ctx, "playback")
  if ButtonGroupImageButton("playback", false, { colorset = "Green" } ) then
    local id = reaper.NamedCommandLookup("_RS0bbcbcb0cb7174a2406403352d006c0573c4c8b4")
    reaper.Main_OnCommand(id, 0)
  end

  ImGui.PopID(ctx)
  TT("Playback")
end

local function PlaybackSetMarkerButton()
  ImGui.PushID(ctx, "playback_marker")
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 8, 4)
  if ButtonGroupImageButton("marker", false, { colorset = "Green" } ) then
    MK.setPlaybackMarkerAtCurrentPos()
  end

  ImGui.PopStyleVar(ctx,1)
  ImGui.PopID(ctx)
  TT("Sets/Moves/Removes the playback marker")
end

local function NoteHighlightingMiniBar()

  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,       2, 4)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing,  0, 0)

  ImGui.PushID(ctx, "note_highlightingbutton")
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 8, 4)

  local setting = "NoteHiglightingDuringPlay"
  local hon = S.getSetting(setting)
  if ButtonGroupImageButton("note_highlighting", hon, {colorset="Snap"}) then
    S.setSetting(setting, not hon)
  end

  TT("Highlight notes in MIDI editor during play")
  ImGui.PopStyleVar(ctx,1)
  ImGui.PopID(ctx)

  SL()
  ImGui.PopStyleVar(ctx, 2)
end

local function MagnetMiniBar()

  local snapElements = {
    { setting = "SnapNotes",        tt = "Note bounds"   , image = "note",    width = 7 },
    { setting = "SnapProjectGrid",  tt = "Project grid"  , image = "pgrid",   width = 7 },
    { setting = "SnapItemGrid",     tt = "Item grid"     , image = "igrid",   width = 5 },
    { setting = "SnapItemBounds",   tt = "Item bounds"   , image = "ibounds", width = 8 }
  }

  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,       2, 4)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing,  0, 0)

  for k,v in ipairs(snapElements) do
    ImGui.PushID(ctx, "snap_btn_" .. v.setting)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 8, 4)
    local navon = S.getSetting(v.setting)
    if ButtonGroupImageButton("snap_btn_" .. v.image, navon, {colorset="Snap"}) then
      S.setSetting(v.setting, not navon)
    end
    TT("Navigation snap to " .. v.tt)
    ImGui.PopStyleVar(ctx,1)
    ImGui.PopID(ctx)
    if k < #snapElements then
      SL()
    end
  end

  ImGui.PopStyleVar(ctx, 2)
end

function EditModeMiniBar()

  local mode  = S.getSetting("EditMode")
  local amode = ED.ResolveOperationMode().mode

  local modes = {
    { name = D.EditMode.Write, tt = "Forward  : Add notes\nBackward : Selective delete (remove notes if pressed)" },
    { name = D.EditMode.Insert, tt = "Forward  : Add notes and shift later ones\nBackward : Delete or shorten notes and shift later ones back", alt = "Stretch/Compress"},
    { name = D.EditMode.Replace, tt = "Forward  : Delete (partially or fully) existing notes, and add new ones instead\nBackward : Delete (partially or fully) existing notes", alt = "Stuff/Unstuff"},
    { name = D.EditMode.Repitch, tt = "Forward  : Change the pitch of notes (number of pressed keys should match)\nBackward : Jump back to precedent note start" },
    { name = D.EditMode.Navigate, tt = "Forward  : Navigate forward (using snap options)\nBackward : Navigate backward (using snap options)" },
  }

  for k,v in pairs(modes) do
    local icon      = 'edit_mode_' .. v.name:lower()
    local ison      = (mode == v.name)
    local isactive  = (amode == v.name)

    local colorset  = "Blue"

    if ison then
      if not isactive then
        ison = false
      end
    else
      if isactive then
        ison = true
        colorset = "Blue"
      end
    end

    if ButtonGroupImageButton(icon, ison, {colorset = colorset}) then
      S.setSetting("EditMode", v.name)
    end
    local tt = v.name .. " Mode\n\n" .. v.tt

    if v.alt then
      tt = tt .. "\n\nClicking on the light indicator sets the operation marker\nand switches to " .. v.alt .. " mode"
    end

    TT(tt)

    if k < #modes then
      SL()
    end
  end
end

function PlaybackWidget()

  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,       2, 4)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing,  0, 0)

  PlaybackButton()
  SL()
  PlayBackMeasureCountComboBox()
  SL()
  PlaybackSetMarkerButton()

  ImGui.PopStyleVar(ctx,2)
end

function SliderReset(setting)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 2, 0)
  SL()
  if ImGui.Button(ctx,"R##" .. setting) then
    S.resetSetting(setting)
  end
  TT("Reset")
  ImGui.PopStyleVar(ctx)
end

function SettingSlider(setting, in_label, out_label, tooltip, use_help_interrogation_for_tooltip, options)

  options = options or {}

  local width = options.width
  local spec  = S.getSettingSpec(setting)
  local min   = options.min or spec.min
  local max   = options.max or spec.max

  if width then
    ImGui.SetNextItemWidth(ctx, width)
  end

  local slider_func = nil
  if spec.type == 'int' then
    slider_func = ImGui.SliderInt
  elseif spec.type == 'double' then
    slider_func = ImGui.SliderDouble
  else
    error("Contact developer, forgot to handle type " .. spec.type)
  end

---@diagnostic disable-next-line: param-type-mismatch
  local change, v1 = slider_func(ctx, "##slider_" .. setting , S.getSetting(setting), min, max, in_label, ImGui.SliderFlags_NoInput)
  if change then
    S.setSetting(setting, v1)
  end

  if tooltip and not use_help_interrogation_for_tooltip then
    TT(tooltip)
  end

  SL()
  SliderReset(setting)

  if out_label and out_label ~= "" then
    SL()
    ImGui.Text(ctx, out_label)
  end

  if use_help_interrogation_for_tooltip and tooltip then
    SL()
    ImGui.TextColored(ctx, 0xB0B0B0FF, "(?)")
    TT(tooltip)
  end
end

function SettingComboBox(setting, pre_label, tooltip, width)

  local combo_items = S.getSettingSpec(setting).inclusion
  local curval      = S.getSetting(setting)

  ImGui.AlignTextToFramePadding(ctx)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 5, 3)

  if pre_label ~= "" then
    ImGui.Text(ctx, pre_label)
    SL()
    ImGui.SetNextItemWidth(ctx, 180)
  end

  ImGui.SetNextItemWidth(ctx, width)
  ImGui.PushID(ctx, setting .. "_combo")
---@diagnostic disable-next-line: param-type-mismatch
  if ImGui.BeginCombo(ctx, '', curval) then
    for i,v in ipairs(combo_items) do
      local is_selected = (curval == v)
      if ImGui.Selectable(ctx, combo_items[i], is_selected) then
        S.setSetting(setting, v)
      end
      if is_selected then
        ImGui.SetItemDefaultFocus(ctx)
      end
    end
    ImGui.EndCombo(ctx)
  end
  ImGui.PopID(ctx)
  ImGui.PopStyleVar(ctx,1)

  TT(tooltip)
end

local function ResolveStepBackPedalState()
  local ccnum   = S.getSetting("StepBackModifierPedal")

  if ccnum == -1 then return end

  local track   = nil
  local take    = TGT.TakeForEdition()

  if take then track = reaper.GetMediaItemTake_Track(take)
  else         track = TGT.TrackForEditionIfNoItemFound()
  end

  if not track then return false end

  local oss_state = H.oneSmallStepState(track)
  return H.isModifierPedalDown(oss_state, ccnum)
end

function TargetModeInfo()
  local back_pedal = ResolveStepBackPedalState()

  local currentop     = ED.ResolveOperationMode()
  local back_modifier = back_pedal or MOD.IsStepBackModifierKeyPressed()

  local _TT = function(msg, is_alt, alternative)
    msg = msg .. "\n\n" .. "Click to set/move/remove operation marker\n\n"
    if is_alt then
      msg = msg .. "Switches back to " .. alternative .. " Mode"
    else
      msg = msg .. "Switches to " .. alternative .. " Mode"
    end
    return TT(msg)
  end

  if currentop.mode == "Insert" then
    if currentop.use_alt then
      if back_modifier  then
        ImGui.Image(ctx, getImage("indicator_compress"),20,20); _TT("Compress notes between marker and edit cursor", true, "Insert"); SL()
      else
        ImGui.Image(ctx, getImage("indicator_stretch"),20,20); _TT("Stretch notes between marker and edit cursor", true, "Insert"); SL()
      end
    else
      if back_modifier  then
        ImGui.Image(ctx, getImage("indicator_insert_back"),20,20); _TT("Insert back (delete and shift)", false, "Compress"); SL()
      else
        ImGui.Image(ctx, getImage("indicator_insert_forward"),20,20); ; _TT("Insert (add notes and shift)", false, "Stretch"); SL()
      end
    end
  elseif currentop.mode == "Replace" then
    if currentop.use_alt then
      if back_modifier  then
        ImGui.Image(ctx, getImage("indicator_unstuff"),20,20); _TT("Stuff notes at the end of the zone between marker and edit cursor", true, "Replace"); SL()
      else
        ImGui.Image(ctx, getImage("indicator_stuff"),20,20);   _TT("Unstuff notes at the end of the zone between marker and edit cursor", true, "Replace"); SL()
      end
    else
      if back_modifier then
        ImGui.Image(ctx, getImage("indicator_replace_back"),20,20); SL();  _TT("Replace back (delete)", false, "Untuff"); SL()
      else
        ImGui.Image(ctx, getImage("indicator_replace_forward"),20,20); SL();  _TT("Replace (add notes and remove/patch existing)", false, "Stuff"); SL()
      end
    end
  elseif currentop.mode == "Navigate" then
    if back_modifier then
      ImGui.Image(ctx, getImage("indicator_navigate_back"),20,20); SL();  TT("Navigate backward") SL()
    else
      ImGui.Image(ctx, getImage("indicator_navigate_forward"),20,20); SL(); TT("Navigate forward") SL()
    end
  elseif currentop.mode == "Repitch" then
    if back_modifier then
      ImGui.Image(ctx, getImage("indicator_repitch_back"),20,20); SL();  TT("Write back (selective delete") SL()
    else
      ImGui.Image(ctx, getImage("indicator_repitch_forward"),20,20); SL();  TT("Write (add notes)") SL()
    end
  else
    if back_modifier then
      ImGui.Image(ctx, getImage("indicator_write_back"),20,20); SL();  TT("Write back (selective delete") SL()
    else
      ImGui.Image(ctx, getImage("indicator_write_forward"),20,20); SL();  TT("Write (add notes)") SL()
    end
  end

  if ImGui.IsItemClicked(ctx) then
    MK.setOperationMarkerAtCurrentPos()
  end

end


function TargetLine(take)

  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,       2, 4)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing,  0, 0)

  PlaybackWidget();   SL()
  MiniBarSeparator(); SL()

  ImGui.PopStyleVar(ctx,2)

  SL()

  if not take then
    if S.getSetting("AllowCreateItem") then
      local track = TGT.TrackForEditionIfNoItemFound()
      if track then
        TargetModeInfo()
        TrackInfo(track)
      else
        ImGui.TextColored(ctx, 0xA0A0A0FF, "No target item or track.")
      end
    else
      ImGui.TextColored(ctx, 0xA0A0A0FF, "No target item. Please select one.")
    end
  else
    TargetModeInfo()
    TakeInfo(take)
  end

  if DEBUGGER_IS_ON then
    SL(); ImGui.TextColored(ctx, 0xFF7070FF, "[DBG ON]")
  end
end

-- MINIBAR : Settings
function SettingsMiniBar()
  if ButtonGroupImageButton('settings', false) then
    showsettings = not showsettings
  end
end

function MarkerPolicySettingComboBox(marker_name, policy_setting_name)

  local combo_items = { 'Hide/Restore', 'Keep visible', 'Remove' }
  local curval      = S.getSetting(policy_setting_name)

  ImGui.AlignTextToFramePadding(ctx)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 5, 3)
  ImGui.PushID(ctx, "playback_marker_policy_" .. policy_setting_name)

  ImGui.SetNextItemWidth(ctx, 120)
---@diagnostic disable-next-line: param-type-mismatch
  if ImGui.BeginCombo(ctx, '', curval) then
    for i,v in ipairs(combo_items) do
      local is_selected = (curval == v)
      if ImGui.Selectable(ctx, combo_items[i], is_selected) then
        S.setSetting(policy_setting_name, v)
      end
      if is_selected then
        ImGui.SetItemDefaultFocus(ctx)
      end
    end
    ImGui.EndCombo(ctx)
  end
  ImGui.PopStyleVar(ctx,1)
  ImGui.PopID(ctx)

  SL()

  ImGui.Text(ctx, marker_name .. " when closing")
end

function AllowedModifierKeyCombinationsForEditMode()
  -- All combinations but remove ctrl pedal
  local modkey      = D.ModifierKeyLookup[S.getSetting("StepBackModifierKey")]

  local filtered = {}
  for k, v in ipairs(D.ModifierKeyCombinations) do
    if modkey.vkey ~= v.vkeys[1] and modkey.vkey ~= v.vkeys[2] then
      filtered[#filtered+1] = v
    end
  end

  return filtered
end

function ClearConflictingModifierKeys()
  local sbmk        = S.getSetting("StepBackModifierKey")
  local editmodes   = { "Navigate", "Replace", "Insert", "Repitch" }

  for k,v in ipairs(editmodes) do
    local setting = v.."ModifierKeyCombination"
    local modk    = S.getSetting(setting)
    local combi   = D.ModifierKeyCombinationLookup[modk]

    for _, vk in ipairs(combi.vkeys) do
      if sbmk == vk then
        S.setSetting(setting, "none")
      end
    end
  end
end

function StepBackModifierKeyComboBox(callback)
  local setting     = "StepBackModifierKey"
  local modkey      = D.ModifierKeyLookup[S.getSetting(setting)] or {}
  local combo_items = D.ModifierKeys
  local label       = modkey.name
  local curval      = modkey.vkey

  ImGui.AlignTextToFramePadding(ctx)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 5, 3)
  ImGui.PushID(ctx, setting)

  ImGui.SetNextItemWidth(ctx, 100)
  if ImGui.BeginCombo(ctx, '', label) then
    for i,v in ipairs(combo_items) do
      local is_selected = (curval == v.vkey)

      if is_selected then
        ImGui.SetItemDefaultFocus(ctx)
      end

      if ImGui.Selectable(ctx, v.name, is_selected) then
        S.setSetting(setting, v.vkey)
        ClearConflictingModifierKeys()
      end
    end
    ImGui.EndCombo(ctx)
  end
  ImGui.PopStyleVar(ctx,1)
  ImGui.PopID(ctx)

  SL()
  ImGui.TextColored(ctx, 0x9090FFFF, "+ sustain pedal")
  SL()
  ImGui.Text(ctx, "performs")
  SL()
  ImGui.TextColored(ctx, 0xFFA0F0FF, "Back Operation")
end

function StepBackModifierPedalComboBox()
  local setting     = "StepBackModifierPedal"
  local modifier    = D.ModifierPedalLookup[S.getSetting(setting)] or {}
  local combo_items = D.ModifierPedals
  local label       = modifier.name
  local curval      = modifier.ccnum

  ImGui.AlignTextToFramePadding(ctx)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 5, 3)
  ImGui.PushID(ctx, setting)

  ImGui.SetNextItemWidth(ctx, 160)
  if ImGui.BeginCombo(ctx, '', label) then
    for i,v in ipairs(combo_items) do
      local is_selected = (curval == v.ccnum)

      if is_selected then
        ImGui.SetItemDefaultFocus(ctx)
      end

      if ImGui.Selectable(ctx, v.name, is_selected) then
        S.setSetting(setting, v.ccnum)
        ClearConflictingModifierKeys()
      end
    end
    ImGui.EndCombo(ctx)
  end
  ImGui.PopStyleVar(ctx,1)
  ImGui.PopID(ctx)

  if S.getSetting(setting) == -1 then
    SL()
    ImGui.Text(ctx, "defined as pedal modifier for")
  else
    SL()
    ImGui.TextColored(ctx, 0x9090FFFF, "+ sustain pedal")
    SL()
    ImGui.Text(ctx, "performs")
  end

  SL()
  ImGui.TextColored(ctx, 0xFFA0F0FF, "Back Operation")
end


function EditModeComboBox(editModeName, callback)

  local combo_items   = AllowedModifierKeyCombinationsForEditMode()
  local setting       = editModeName .. "ModifierKeyCombination"
  local current_id    = S.getSetting(setting)
  local current_combi = D.ModifierKeyCombinationLookup[current_id]

  ImGui.AlignTextToFramePadding(ctx)
  ImGui.PushStyleVar(ctx,  ImGui.StyleVar_FramePadding, 5, 3)
  ImGui.PushID(ctx,        setting)

  ImGui.SetNextItemWidth(ctx, 100)
  if ImGui.BeginCombo(ctx, '', current_combi.label) then
    for i,v in ipairs(combo_items) do
      local is_selected = (current_combi.id == v.id)

      if is_selected then
        ImGui.SetItemDefaultFocus(ctx)
      end

      if ImGui.Selectable(ctx, v.label, is_selected) then
        S.setSetting(setting, v.id)
        -- TODO : Reset all collisions
      end
    end
    ImGui.EndCombo(ctx)
  end
  ImGui.PopStyleVar(ctx,1)
  ImGui.PopID(ctx)

  SL()
  ImGui.Text(ctx, "activates")
  SL()
  ImGui.TextColored(ctx, 0xFFA0F0FF, ""..editModeName)
  SL()
  ImGui.Text(ctx, "edit mode")
end

function RepitchModeComboBox()
  local setting     = "RepitchModeAffects"
  local combo_items = S.getSettingSpec("RepitchModeAffects").inclusion
  local curval      = S.getSetting("RepitchModeAffects")

  ImGui.AlignTextToFramePadding(ctx)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 5, 3)

  ImGui.Text(ctx, "Repitch mode affects")
  SL()
  ImGui.SetNextItemWidth(ctx, 180)

  ImGui.PushID(ctx, setting .. "_combo")
---@diagnostic disable-next-line: param-type-mismatch
  if ImGui.BeginCombo(ctx, '', curval) then
    for i,v in ipairs(combo_items) do
      local is_selected = (curval == v)
      if ImGui.Selectable(ctx, combo_items[i], is_selected) then
        S.setSetting(setting, v)
      end
      if is_selected then
        ImGui.SetItemDefaultFocus(ctx)
      end
    end
    ImGui.EndCombo(ctx)
  end
  ImGui.PopID(ctx)
  ImGui.PopStyleVar(ctx,1)
end

function SettingsPanel()
  if ImGui.BeginTabBar(ctx, 'settings_tab_bar', ImGui.TabBarFlags_None) then
    ImGui.PushStyleColor(ctx, ImGui.Col_Tab,        0x00000000)
    ImGui.PushStyleColor(ctx, ImGui.Col_TabHovered, 0x00000000)
    if ImGui.TabItemButton(ctx, 'Settings##settings_tab', ImGui.TabItemFlags_Leading | ImGui.TabItemFlags_NoTooltip) then
    end
    ImGui.PopStyleColor(ctx, 2)

    if ImGui.BeginTabItem(ctx, 'General') then

      ImGui_VerticalSpacer(ctx,5)

      local curval = nil

      curval = S.getSetting("AllowTargetingFocusedMidiEditors")
---@diagnostic disable-next-line: param-type-mismatch
      if ImGui.Checkbox(ctx, "Allow targeting items open in focused MIDI Editors", curval) then
        S.setSetting("AllowTargetingFocusedMidiEditors", not curval)
      end

      curval = S.getSetting("AllowTargetingNonSelectedItemsUnderCursor")
---@diagnostic disable-next-line: param-type-mismatch
      if ImGui.Checkbox(ctx, "Allow targeting items on selected tracks if no item is selected", curval) then
        S.setSetting("AllowTargetingNonSelectedItemsUnderCursor", not curval)
      end

      curval = S.getSetting("AllowCreateItem")
---@diagnostic disable-next-line: param-type-mismatch
      if ImGui.Checkbox(ctx, "Allow creating new items if needed", curval) then
        S.setSetting("AllowCreateItem", not curval)
      end

      curval = S.getSetting("SelectInputNotes")
---@diagnostic disable-next-line: param-type-mismatch
      if ImGui.Checkbox(ctx, "Select input notes", curval) then
        S.setSetting("SelectInputNotes", not curval)
      end

      curval = S.getSetting("AlwaysFocusMEOnLaunch")
---@diagnostic disable-next-line: param-type-mismatch
      if ImGui.Checkbox(ctx, "Always focus the MIDI Editor on launch", curval) then
        S.setSetting("AlwaysFocusMEOnLaunch", not curval)
      end

      curval = S.getSetting("CleanupJsfxAtClosing")
---@diagnostic disable-next-line: param-type-mismatch
      if ImGui.Checkbox(ctx, "Cleanup helper JSFXs when closing OSS", curval) then
        S.setSetting("CleanupJsfxAtClosing", not curval)
      end

      ImGui.EndTabItem(ctx)
    end

    if ImGui.BeginTabItem(ctx, 'Input') then
      ImGui_VerticalSpacer(ctx,5)
      SEP("Key Press input mode")

      SettingSlider("KeyPressModeAggregationTime",
        "%.3f seconds",
        "Chord Aggregation",
        "Key press events happening within this time\nwindow are aggregated as a chord",
        true)

      SettingSlider("KeyPressModeInertiaTime",
        "%.3f seconds",
        "Sustain Inertia",
        "If key A is pressed, and then key B is pressed but\n\z
        key A was still held for more than this time,\n\z
        then A is considered sustained and not released.\n\n\z
        This setting allows to enter new notes overlapping sustained notes.",
        true)
      SL()
      local curval = S.getSetting("KeyPressModeInertiaEnabled")
---@diagnostic disable-next-line: param-type-mismatch
      if ImGui.Checkbox(ctx, "Enabled##kp_inertia", curval) then
        S.setSetting("KeyPressModeInertiaEnabled", not curval)
      end

      ImGui_VerticalSpacer(ctx,5)
      SEP("Key Release input mode")

      SettingSlider("KeyReleaseModeForgetTime",
        "%.3f seconds",
        "Forget time",
        "How long a key should be remembered after release,\n\z
        if other keys are still pressed.\n\n\z
        This is used to know if a note should be forgotten/trashed\n\z
        or used as part of the input chord.",
        true)

      ImGui_VerticalSpacer(ctx,5)
      SEP("Sustain Pedal")

      curval = S.getSetting("PedalRepeatEnabled")
---@diagnostic disable-next-line: param-type-mismatch
      if ImGui.Checkbox(ctx, "Pedal repeat every", curval) then
        S.setSetting("PedalRepeatEnabled", not curval)
      end
      SL()
      SettingSlider("PedalRepeatTime",
        "%.3f seconds", "and", "Repeat time for the pedal event when pressed",
        false,
        { width = 120 } )
      SL()
      SettingSlider("PedalRepeatFirstHitMultiplier",
        "x %.d",
        "on first hit",
        "Multiplication factor for first hit",
        false,
        { width = 50 } )

      ImGui_VerticalSpacer(ctx,5)
      SEP("Velocity")

      curval = S.getSetting("VelocityLimiterEnabled")
---@diagnostic disable-next-line: param-type-mismatch
      if ImGui.Checkbox(ctx, "Limit velocity between", curval) then
        S.setSetting("VelocityLimiterEnabled", not curval)
      end
      SL()
      SettingSlider("VelocityLimiterMin",
        "%d",
        "and",
        "Minimum value",
        false,
        { width = 127, min = S.getSettingSpec("VelocityLimiterMin").min, max = S.getSetting("VelocityLimiterMax") } )
      SL()
      SettingSlider("VelocityLimiterMax",
        "%d",
        "",
        "Maximum value",
        false,
        { width = 127, min = S.getSetting("VelocityLimiterMin"), max = S.getSettingSpec("VelocityLimiterMax").max } )
      SL()
      SettingComboBox("VelocityLimiterMode", "mode", "Velocity limiting label", 100)

      ImGui.EndTabItem(ctx)
    end

    if ImGui.BeginTabItem(ctx, 'Controls') then
      ImGui_VerticalSpacer(ctx,5)

      ImGui.SeparatorText(ctx, "Key modifiers")
      StepBackModifierKeyComboBox()
      EditModeComboBox("Write")
      EditModeComboBox("Navigate")
      EditModeComboBox("Insert")
      EditModeComboBox("Replace")
      EditModeComboBox("Repitch")

      ImGui.SeparatorText(ctx, "Pedal Modifiers")
      StepBackModifierPedalComboBox()

      ImGui.SeparatorText(ctx, "UI options")
      local curval = S.getSetting("HideEditModeMiniBar")
---@diagnostic disable-next-line: param-type-mismatch
      if ImGui.Checkbox(ctx, "Hide edit mode mini bar", curval) then
        S.setSetting("HideEditModeMiniBar", not curval)
      end
      SL()
      ImGui.TextColored(ctx, 0xB0B0B0FF, "(?)")
      TT("If you have configured a modifier for all modes,\n\z
          and you have set a default mode, you may want to\n\z
          get rid of the edit mode mini bar (still, you could\n\z
          also want to keep the ability to toggle a mode with a\n\z
          mouse click). Up to you!")

      ImGui.EndTabItem(ctx)
    end

    if ImGui.BeginTabItem(ctx, 'Editing') then
      ImGui_VerticalSpacer(ctx,5)
      SEP("All edit modes")

      local curval = S.getSetting("AutoScrollArrangeView")
---@diagnostic disable-next-line: param-type-mismatch
      if ImGui.Checkbox(ctx, "Auto-scroll arrange view after editing/navigating", curval) then
        S.setSetting("AutoScrollArrangeView", not curval)
      end

      curval = S.getSetting("AllowKeyEventNavigation")
---@diagnostic disable-next-line: param-type-mismatch
      if ImGui.Checkbox(ctx, "Allow navigating on controller key press/release", curval) then
        S.setSetting("AllowKeyEventNavigation", not curval)
      end

      MarkerPolicySettingComboBox("operation marker", "OperationMarkerPolicyWhenClosed")

      ImGui_VerticalSpacer(ctx,5)
      SEP("Write mode")

      curval = S.getSetting("DoNotRewindOnStepBackIfNothingErased")
---@diagnostic disable-next-line: param-type-mismatch
      if ImGui.Checkbox(ctx, "Do not rewind on controller key press/release and nothing is erased", curval) then
        S.setSetting("DoNotRewindOnStepBackIfNothingErased", not curval)
      end

      ImGui_VerticalSpacer(ctx,5)
      SEP("Insert mode")

      ImGui.Text(ctx, "When inserting in the middle of an existing note...")
      ImGui_VerticalSpacer(ctx,5)

      SettingComboBox("InsertModeInMiddleOfMatchingNotesBehaviour",
        "  · if a pressed note matches, then",
        "This option defines OSS's behavior when you try to insert some notes\n\z
        in the middle of existing notes, if one of the key you are pressing/holding\n\z
        matches (same pitch) one of the existing notes",
        220)

      SettingComboBox("InsertModeInMiddleOfNonMatchingNotesBehaviour",
        "  · if no pressed note matches, then",
        "This option defines OSS's behavior when you try to insert some notes\n\z
        in the middle of existing notes, if any of the key you are pressing/holding\n\z
        does NOT match (same pitch) any existing note",
        220)

      ImGui_VerticalSpacer(ctx,5)
      SEP("Repitch mode")

      RepitchModeComboBox()
      SettingSlider("RepitchModeAggregationTime",
        "%.3f seconds",
        "Repitch chord aggregation",
        "Notes that fit in that time window are aggregated as a chord",
        true)

      ImGui.EndTabItem(ctx)
    end

    if ImGui.BeginTabItem(ctx, 'Playback') then
      ImGui_VerticalSpacer(ctx,5)
      MarkerPolicySettingComboBox("playback marker", "PlaybackMarkerPolicyWhenClosed")
      ImGui.EndTabItem(ctx)
    end

    if ImGui.BeginTabItem(ctx, 'Articulations') then
      ImGui_VerticalSpacer(ctx,5)

      local track   = nil
      local take    = TGT.TakeForEdition()

      if take then
        track = reaper.GetMediaItemTake_Track(take)
      else
        track = TGT.TrackForEditionIfNoItemFound()
      end

      local help = "The articulation markup manager is an experimental feature that will create text events\n\z
      in the \"Text Events\" CC Lane automatically to match notes that are KeySwitches.\n\z
      Basically, it aims to translate KeySwitches from a note representation to a more\n\z
      compact/friendly/readable horizontal representation.\n\z
      \n\z
      Those events will be created/synced after each note input, but also when OSS is running and\n\z
      and you're mouse editing the notes in the MIDI Editor (a background task is watching those changes\n\z
      and automatically converts them to the \"Text Events\" CC Lane).\n\z
      \n\z
      Inversely, notes that are suppressed will see their corresponding text events disappear.\n\z
      \n\z
      The condition for creating such a text event is that a note name is attached to the note/key\n\z
      that was pressed/modified. For this to work, you need to load a Note Name map file on your track's\n\z
      piano roll (note that this can be done per channel).\n\z"

      if track then
        local curval = S.getTrackSetting(track, "OSSArticulationManagerEnabled")

---@diagnostic disable-next-line: param-type-mismatch
        if ImGui.Checkbox(ctx, "Use articulation markup manager", curval) then
          S.setTrackSetting(track, "OSSArticulationManagerEnabled", not curval)
        end

        SL()
        ImGui.TextColored(ctx, 0xB0B0B0FF, "(?)")
        TT(help)
        SL()
        ImGui.TextColored(ctx, 0x00EEFFFF, "[Per track setting]")
      else
        ImGui.TextColored(ctx, 0x00EEFFFF, "Please select a track to access the articulation manager")
        SL()
        ImGui.TextColored(ctx, 0xB0B0B0FF, "(?)")
        TT(help)
      end

      ImGui.EndTabItem(ctx)
    end

    if ImGui.TabItemButton(ctx, "?##go_to_help") then
      reaper.CF_ShellExecute(DOC_URL)
    end

    ImGui.EndTabBar(ctx)
  end
end

function NoteLenOptions(grid_mode)
  local nlmod = S.getNoteLenModifier()

  NoteLenMiniBar(grid_mode); SL()
  MiniBarSeparator(); SL()

  if grid_mode then
    XSeparator(); SL()
  end

  NoteLenModifierMiniBar(grid_mode)

  if nlmod == D.NoteLenModifier.Tuplet then
    SL(); MiniBarSeparator(); SL()
    NTupletComboBox()
  elseif nlmod == D.NoteLenModifier.Modified then
    SL(); MiniBarSeparator(); SL()
    AugmentedDiminishedMiniBars(not grid_mode)
  end
end

local function Stop()
end

local draw_count = 0

local function UiLoop()

  ImGui.PushFont(ctx, arial, 12)
  ImGui.PushStyleVar(ctx,ImGui.StyleVar_WindowPadding,10,10)

  local flags   = ImGui.WindowFlags_NoDocking |
    ImGui.WindowFlags_NoCollapse |
    ImGui.WindowFlags_AlwaysAutoResize |
    ImGui.WindowFlags_TopMost


  -- Since we use a trick to give back the focus to reaper, we don't want the window to glitch.
  ImGui.PushStyleColor(ctx, ImGui.Col_TitleBgActive, (DEBUGGER_IS_ON) and (0xFF0000FF) or (0x0A0A0AFF))
  local visible, open = ImGui.Begin(ctx, 'One Small Step v' .. VERSION, true, flags)
  ImGui.PopStyleColor(ctx,1)

  if visible then
    F.TrackFocus()

    if draw_count == 1 then
      if S.getSetting("AlwaysFocusMEOnLaunch") then
        F.ForceLastFocusTo('MIDIEditor')
      end
    end

    ImGui.SetConfigVar(ctx,ImGui.ConfigVar_HoverDelayNormal, 1.0)

    -- Target display line
    local take = TGT.TakeForEdition()

    TargetLine(take)

    -- Separator
    ImGui_VerticalSpacer(ctx,10)

    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,      0, 0)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,       2, 4)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemInnerSpacing,  0, 0)

    local nlm     = S.getNoteLenParamSource()
    local amode   = S.getSetting("EditMode")
    local opmode  = ED.ResolveOperationMode()
    local emode   = opmode.mode

    SettingsMiniBar(); SL()
    MiniBarSeparator(); SL()

    NoteHighlightingMiniBar(); SL()
    MiniBarSeparator(); SL()

    InputModeMiniBar(); SL()
    MiniBarSeparator(); SL()

    if not S.getSetting("HideEditModeMiniBar") then
      EditModeMiniBar(); SL()
      MiniBarSeparator(); SL()
    end

    MagnetMiniBar();    SL()
    MiniBarSeparator(); SL()

    ConfSourceMiniBar(); SL()
    MiniBarSeparator(); SL()

    if nlm == D.NoteLenParamSource.OSS then
      NoteLenOptions(emode == "Replace" and opmode.use_alt)
    elseif nlm == D.NoteLenParamSource.ProjectGrid then
      ProjectGridLabel(ctx); SL()
      XSeparator(); SL()
      NoteLenOptions(true)
    elseif nlm == D.NoteLenParamSource.ItemConf then
      ItemGridLabel(ctx,take); SL()
      XSeparator(); SL()
      NoteLenOptions(true)
    end

    ImGui.PopStyleVar(ctx,3)

    if showsettings then
      ImGui_VerticalSpacer(ctx,10)
      SettingsPanel()
    end

    if ImGui.IsWindowFocused(ctx) then
      if not focustimer or ImGui.IsAnyMouseDown(ctx) then
        -- create or reset the timer when there's activity in the window
        focustimer = reaper.time_precise()
      end

      if (reaper.time_precise() - focustimer > 0.5) then
        F.RestoreFocus()
      end
    else
      focustimer = nil
    end
    draw_count = draw_count + 1
    -- End
    ImGui.End(ctx)
  end

  ImGui.PopStyleVar(ctx)
  ImGui.PopFont(ctx)

  return open
end

local function UpdateToolbarButtonState(v)
  local _,_,sectionID,cmdID,_,_,_ = reaper.get_action_context()
  reaper.SetToggleCommandState(sectionID,cmdID,v)
  reaper.RefreshToolbar2(sectionID, cmdID)
end


local lastArtUpdateProjState  = nil
local lastArtUpdateTake       = nil
local lastArtUpdateWatch      = nil

local function WatchForArticulationsToUpdate()
  if not lastArtUpdateWatch or reaper.time_precise() - lastArtUpdateWatch > 0.1 then
    lastArtUpdateWatch = reaper.time_precise()

    local take  = TGT.TakeForEdition()

    if not take then
      return
    end

    local track = reaper.GetMediaItemTake_Track(take)

    if not S.getTrackSetting(track, "OSSArticulationManagerEnabled") then
      -- Nothing to do, but reset stuff
      lastArtUpdateTake = nil
      return
    end

    local pscc  = reaper.GetProjectStateChangeCount()

    if take ~= lastArtUpdateTake or pscc ~= lastArtUpdateProjState then
      lastArtUpdateTake       = take
      lastArtUpdateProjState  = pscc

      ART.UpdateArticulationTextEventsIfNeeded(track, take)
    end

  end
end

function MainLoop()

  WatchForArticulationsToUpdate()

  local engine_ret = E.atLoop()

  if engine_ret == -42 then
    reaper.ShowMessageBox("Could not install One Small Step's helper FX on the track.\n\nIf you've just installed One Small Step, please try to restart REAPER to let it refresh its JFSX repository.", "Oops !", 0)
    return
  end

  if UiLoop() then
    reaper.defer(MainLoop)
  else
    Stop()
  end
end

local function onReaperExit()
  UpdateToolbarButtonState(0)
  E.atExit()
end

local function _start()
  focustimer    = 0;  -- Will force a focus restore

  F.TrackFocus()      -- Track focus at start so that we can restore exactly to what was focused before OSS's window opens

  UpdateToolbarButtonState(1)
  E.atStart()
  reaper.atexit(onReaperExit)
  reaper.defer(MainLoop)
end

local function start()
  -- Defer everything so that we can benefit of the debugger
  reaper.defer(_start)
end

S.setSetting("UseProfiler", false)

DBG.LaunchDebugStubIfNeeded()
DBG.LaunchProfilerIfNeeded()

start()

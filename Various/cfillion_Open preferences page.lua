-- @description Open preferences page
-- @author cfillion
-- @version 1.0.3
-- @changelog Fix opening the Device page on Windows and Linux [p=2547777]
-- @metapackage
-- @provides
--   [main] . > cfillion_Open preferences page - General.lua
--   [main] . > cfillion_Open preferences page - General - Paths.lua
--   [main] . > cfillion_Open preferences page - General - Keyboard, Multitouch.lua
--   [main] . > cfillion_Open preferences page - Project.lua
--   [main] . > cfillion_Open preferences page - Project - Track, Send Defaults.lua
--   [main] . > cfillion_Open preferences page - Project - Media Item Defaults.lua
--   [main] . > cfillion_Open preferences page - Audio.lua
--   [main] . > cfillion_Open preferences page - Audio - Device.lua
--   [main] . > cfillion_Open preferences page - Audio - MIDI Devices.lua
--   [main] . > cfillion_Open preferences page - Audio - Buffering.lua
--   [main] . > cfillion_Open preferences page - Audio - Mute, Solo.lua
--   [main] . > cfillion_Open preferences page - Audio - Playback.lua
--   [main] . > cfillion_Open preferences page - Audio - Seeking.lua
--   [main] . > cfillion_Open preferences page - Audio - Recording.lua
--   [main] . > cfillion_Open preferences page - Audio - Loop Recording.lua
--   [main] . > cfillion_Open preferences page - Audio - Rendering.lua
--   [main] . > cfillion_Open preferences page - Appearance.lua
--   [main] . > cfillion_Open preferences page - Appearance - Media.lua
--   [main] . > cfillion_Open preferences page - Appearance - Peaks, Waveforms.lua
--   [main] . > cfillion_Open preferences page - Appearance - Fades, Crossfades.lua
--   [main] . > cfillion_Open preferences page - Appearance - Track Control Panels.lua
--   [main] . > cfillion_Open preferences page - Editing Behavior.lua
--   [main] . > cfillion_Open preferences page - Editing Behavior - Envelope Display.lua
--   [main] . > cfillion_Open preferences page - Editing Behavior - Automation.lua
--   [main] . > cfillion_Open preferences page - Editing Behavior - Mouse.lua
--   [main] . > cfillion_Open preferences page - Editing Behavior - Mouse Modifiers.lua
--   [main] . > cfillion_Open preferences page - Editing Behavior - MIDI Editor.lua
--   [main] . > cfillion_Open preferences page - Media.lua
--   [main] . > cfillion_Open preferences page - Media - MIDI.lua
--   [main] . > cfillion_Open preferences page - Media - Video, REX, Misc.lua
--   [main] . > cfillion_Open preferences page - Plug-ins.lua
--   [main] . > cfillion_Open preferences page - Plug-ins - Compatibility.lua
--   [main] . > cfillion_Open preferences page - Plug-ins - VST.lua
--   [main] . > cfillion_Open preferences page - Plug-ins - ReWire.lua
--   [main] . > cfillion_Open preferences page - Plug-ins - ReaScript.lua
--   [main] . > cfillion_Open preferences page - Plug-ins - ReaMote.lua
--   [main] . > cfillion_Open preferences page - Control, OSC, web.lua
--   [main] . > cfillion_Open preferences page - External Editors.lua
--   [main] . > cfillion_Open preferences page - Plug-ins - LV2.lua
-- @donation Donate via PayPal https://paypal.me/cfillion
-- @about
--   # Open preferences page
--
--   This script adds one action for every pages in the Preferences window.
--
--   Running the script opens the Preferences window with the corresponding page
--   selected.

local macos, windows = reaper.GetOS():match('^OSX'), reaper.GetOS():match('^Win')

local pages = { -- prefpage_lastpage
  ['General'                 ] = { 0x08b  ,
  [  'Paths'                 ] =   0x1da  ,
  [  'Keyboard, Multitouch'  ] =   0x0db },
  ['Project'                 ] = { 0x0d4  ,
  [  'Track, Send Defaults'  ] =   0x0b2  ,
  [  'Media Item Defaults'   ] =   0x1dd },
  ['Audio'                   ] = { 0x09c  ,
  [  'Device'                ] =   (macos   and 0x1d9) or
                                   (windows and 0x076) or
                                                0x242,
  [  'MIDI Devices'          ] =   0x099  ,
  [  'Buffering'             ] =   0x0cb  ,
  [  'Mute, Solo'            ] =   0x248  ,
  [  'Playback'              ] =   0x088  ,
  [  'Seeking'               ] =   0x205  ,
  [  'Recording'             ] =   0x089  ,
  [  'Loop Recording'        ] =   0x206  ,
  [  'Rendering'             ] =   0x1de },
  ['Appearance'              ] = { 0x0d5  ,
  [  'Media'                 ] =   0x0ec  ,
  [  'Peaks, Waveforms'      ] =   0x1cb  ,
  [  'Fades, Crossfades'     ] =   0x20c  ,
  [  'Track Control Panels'  ] =   0x1ca },
  ['Editing Behavior'        ] = { 0x0ac  ,
  [  'Envelope Display'      ] =   0x1bf  ,
  [  'Automation'            ] =   0x207  ,
  [  'Mouse'                 ] =   0x0d7  ,
  [  'Mouse Modifiers'       ] =   0x1d2  ,
  [  'MIDI Editor'           ] =   0x1ea },
  ['Media'                   ] = { 0x08a  ,
  [  'MIDI'                  ] =   0x101  ,
  [  'Video, REX, Misc'      ] =   0x1c1 },
  ['Plug-ins'                ] = { 0x09a  ,
  [  'Compatibility'         ] =   0x1f9  ,
  [  'VST'                   ] =   0x0d2  ,
  [  'LV2'                   ] =   0x251  ,
  [  'ReWire'                ] =   0x0d1  ,
  [  'ReaScript'             ] =   0x203  ,
  [  'ReaMote'               ] =   0x0e3 },
  ['Control, OSC, web'       ] =   0x09d  ,
  ['External Editors'        ] =   0x0a0  ,
}

local function split(haystack, needle, plain)
  local results = {}
  local offsetPos = 1

  local startPos, endPos = nil, 0

  while endPos do
    offsetPos = endPos + 1

    startPos, endPos = haystack:find(needle, offsetPos, plain)
    if startPos then startPos = startPos - 1 end

    table.insert(results, haystack:sub(offsetPos, startPos))
  end

  return results
end

local function findNestedPage(pagePath, rootPage)
  for i, pageName in ipairs(pagePath) do
    rootPage = rootPage[pageName]
    assert(rootPage, string.format('Unknown page: %s', pageName))
  end

  return type(rootPage) == 'table' and rootPage[1] or rootPage
end

local scriptName = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local pagePath = split(scriptName, ' - ', true)
table.remove(pagePath, 1)
assert(#pagePath > 0, 'Invalid script file name')

local pageId = findNestedPage(pagePath, pages)
reaper.ViewPrefs(pageId, '')
reaper.defer(function() end)

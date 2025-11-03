--[[
@description EmojImGui : An Emoji / Icon library for ReaImGui
@version 0.3.0
@author Ben 'Talagan' Babut
@license MIT
@donation https://www.paypal.com/donate/?business=3YEZMY9D6U8NC&no_recurring=1&currency_code=EUR
@links
  Forum Thread https://forum.cockos.com/showthread.php?t=TODO
@changelog
  - Initial version
@metapackage
@provides
  [nomain] talagan_EmojImGui/assets/build/OpenMoji-color-glyf_colr_0-patched.ttf
  [nomain] talagan_EmojImGui/assets/build/openmoji-spec.json
  [nomain] talagan_EmojImGui/assets/build/TweMoji-color-glyf_colr_0-patched.ttf
  [nomain] talagan_EmojImGui/assets/build/twemoji-spec.json
  [nomain] talagan_EmojImGui/emojimgui/**/*.lua
  [nomain] talagan_EmojImGui/emojimgui.lua
  [main]   talagan_EmojImGui/actions/talagan_EmojImGui Demo.lua > .
@about
  # Purpose

    This library targets developers who want to add emoji/icon support to their Reaper applications in lua.

    It offers two emoji fonts (OpenMoji and TweMoji) that have been patched to work with ReaImGui / Freetype, as well specification files describing their structure.

    The library comes as an API that allows to load these fonts, as well as a ready-to-use icon picker.

    OpenMoji is an open source font released under the CC BY-SA 4.0 license, and written by many teachers and students from the HfG Schwäbisch Gmünd university (https://openmoji.org). Thanks to their hard work !

    TweMoji is an open source font released under the CC-BY 4.0 license, originally written by twitter and maintained here (https://github.com/jdecked/twemoji).

--]]

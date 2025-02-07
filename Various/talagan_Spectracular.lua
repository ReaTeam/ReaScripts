--[[
@description Spectracular ! Spectrogram binocular for REAPER
@version 0.1
@author Ben 'Talagan' Babut
@donation https://www.paypal.com/donate/?business=3YEZMY9D6U8NC&no_recurring=1&currency_code=EUR
@license MIT
@screenshot
  https://stash.reaper.fm/49923/spectracular%200.1.png
@links
  Forum Thread (does not exist yet TODO) http://forum.cockos.com/
@metapackage
@changelog
  - Initial version
@provides
  [nomain] talagan_Spectracular/ext/**/*
  [nomain] talagan_Spectracular/modules/**/*
  [nomain] talagan_Spectracular/unit_tests/**/*
  [nomain] talagan_Spectracular/widgets/**/*
  [nomain] talagan_Spectracular/app.lua

  [main=main] talagan_Spectracular/actions/talagan_Spectracular generic action.lua > talagan_Spectracular mono.lua
  [main=main] talagan_Spectracular/actions/talagan_Spectracular generic action.lua > talagan_Spectracular stereo.lua
@about
  Spectracular is a Spectrogram for Reaper. It allows to quiclky render a mix of tracks to mono or stereo and explore the result with a time / frequency graph, where frequencies are represented on a logarithmic scale as notes.

  Just create a time selection, a track selection, and launch Spectracular's mono or stereo action.

  It is possible to span / scroll, adapt the color scales, and also extract per-note profiles to visualize the time evolution of a specific frequency, and compare them together.

  All mouse interactions are given in the help window that can be launched from the bottom right (?) button.

  Please note that this tool is very young and may contain bugs.
--]]

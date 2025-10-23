--[[
@description Reannotate - Annotation tool for REAPER
@version 0.3.1
@author Ben 'Talagan' Babut
@donation https://www.paypal.com/donate/?business=3YEZMY9D6U8NC&no_recurring=1&currency_code=EUR
@license MIT
@screenshot
  https://stash.reaper.fm/50870/reannotate_screenshot_reapack.png
@links
  Forum Thread https://forum.cockos.com/showthread.php?t=304147
@metapackage
@changelog
  - [DOC] Updated forum thread link
  - [Bug Fix] Envelope notes vertical position was wrong (forgot to add track's position)
@provides
  [nomain] talagan_Reannotate/ext/**/*
  [nomain] talagan_Reannotate/classes/**/*
  [nomain] talagan_Reannotate/images/**/*
  [nomain] talagan_Reannotate/modules/**/*
  [nomain] talagan_Reannotate/widgets/**/*

  [main=main] talagan_Reannotate/actions/talagan_Reannotate Quick Preview.lua > talagan_Reannotate Quick Preview.lua
@about
  Reannotate is a visual annotation tool for Reaper.

  It comes as a modal overlay over Reaper, allowing to quickly consult and add some kind of colored "Post-It" notes over objects (tracks, envelopes, items, and project). These notes can be previewed as tooltips by hovering the mouse over objects and can use markdown syntax.

  Basic filtering by category and search is available (pretty basic for now but may evolve).

  SWS and Reaper notes may be edited with Reannotate. They will appear in a dedicated category, allowing retro-compatibility for older projects or projects written by users not using Reannotate.

  You can consult the forum thread for more info.

  Please note that this tool is very young and may contain bugs.
--]]

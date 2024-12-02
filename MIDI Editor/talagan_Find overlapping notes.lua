--[[
@description Find overlapping notes in project / active take
@version 0.5
@author Ben 'Talagan' Babut
@donation https://www.paypal.com/donate/?business=3YEZMY9D6U8NC&no_recurring=1&currency_code=EUR
@license MIT
@changelog
  - Initial Release
@metapackage
@provides
  [main=main,midi_editor] talagan_Find overlapping notes/actions/talagan_Find overlapping notes in active take and select them.lua > .
  [main=main,midi_editor] talagan_Find overlapping notes/actions/talagan_Find overlapping notes in project and report items.lua > .
  [nomain]                talagan_Find overlapping notes/overlapping_lib.lua
@about
  Simple scripts to detect overlapping notes. Currently comes in two actions :
    - One to search in the whole project, that will give you a report per track+item if some overlapping notes were found
    - One to launch with a MIDI Editor open, it will select problematic notes if found
--]]

--[[
@description Docking tools : actions to resize docks
@version 0.1
@author Ben 'Talagan' Babut
@donation https://www.paypal.com/donate/?business=3YEZMY9D6U8NC&no_recurring=1&currency_code=EUR
@license MIT
@metapackage
@provides
  [main=main]             talagan_Docking tools/actions/talagan_Maximize bottommost dock.lua                              > talagan_Maximize bottommost dock.lua
  [main=main]             talagan_Docking tools/actions/talagan_Minimize bottommost dock.lua                              > talagan_Minimize bottommost dock.lua
  [main=main]             talagan_Docking tools/actions/talagan_Set bottommost dock height (500).lua                      > talagan_Set bottommost dock height (500).lua
  [main=main,midi_editor] talagan_Docking tools/actions/talagan_Maximize dock containing active MIDI Editor.lua           > talagan_Maximize dock containing active MIDI Editor.lua
  [main=main,midi_editor] talagan_Docking tools/actions/talagan_Minimize dock containing active MIDI Editor.lua           > talagan_Minimize dock containing active MIDI Editor.lua
  [main=main,midi_editor] talagan_Docking tools/actions/talagan_Set dock containing active MIDI Editor height (500).lua   > talagan_Set dock containing active MIDI Editor height (500).lua
  [nomain] talagan_Docking tools/docking_lib.lua
@changelog
  - Initial Release
@about
  This package provide actions to quickly resize the MIDI dock and the bottommost dock (maximize, minimize, or set to custom height).

  These actions are meant to be small bricks of bigger custom actions where you perform a reorganisation of the UI (e.g. use FTC's scrolling scripts for the MIDI editor).

  You can copy / paste the "... (500).lua" action files and modify their name to put a custom height instead of 500.
--]]

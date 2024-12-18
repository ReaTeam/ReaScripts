--[[
@description Docking tools : actions to resize docks
@version 0.2
@author Ben 'Talagan' Babut
@donation https://www.paypal.com/donate/?business=3YEZMY9D6U8NC&no_recurring=1&currency_code=EUR
@license MIT
@links
  Forum Thread https://forum.cockos.com/showthread.php?t=296531
@metapackage
@changelog
  - Added support for all dock positions (left/top/bottom/right)
  - New syntax for duplicated action names allow to define conditional heights depending on the dock position
  - New syntax for duplicated action names allow to target other widgets than the active MIDI Editor
@provides

  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Set bottommost dock height (500).lua
  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Set dock containing active MIDI Editor height (500).lua

  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Maximize dock containing project bay.lua
  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Minimize dock containing project bay.lua
  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Set dock containing project bay size (500,700,500,700).lua

  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Maximize bottommost dock.lua
  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Minimize bottommost dock.lua
  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Set bottommost dock size (500).lua

  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Maximize topmost dock.lua
  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Minimize topmost dock.lua
  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Set topmost dock size (500).lua

  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Maximize rightmost dock.lua
  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Minimize rightmost dock.lua
  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Set rightmost dock size (500).lua

  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Maximize leftmost dock.lua
  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Minimize leftmost dock.lua
  [main=main] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Set leftmost dock size (500).lua

  [main=main,midi_editor] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Maximize dock containing active MIDI Editor.lua
  [main=main,midi_editor] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Minimize dock containing active MIDI Editor.lua
  [main=main,midi_editor] talagan_Docking tools/actions/talagan_Generic dock resize action.lua > talagan_Set dock containing active MIDI Editor size (500).lua

  [nomain] talagan_Docking tools/docking_lib.lua
@about
  This package provide actions to quickly resize the docks in REAPER.

  These actions are meant to be small bricks of bigger custom actions where you perform a reorganisation of the UI (e.g. use FTC's scrolling scripts for the MIDI editor).

  All actions in this package are duplicates of the same one, with a different name that will decide of it's behaviour. The syntax of the name should be one of the following :

  - Maximize A_DOCK.lua
  - Minimize A_DOCK.lua
  - Set A_DOCK size (SIZES).lua

  A_DOCK can be either :

  - DIRMOST dock
  - dock containing A_WIDGET

  DIRMOST can be one of the following :

  - leftmost
  - rightmost
  - bottommost
  - topmost

  A_WIDGET can be one of the following :

  - active MIDI Editor
  - Mixer
  - Project Bay
  - Media Explorer
  - Track Manager
  - Track Group Manager
  - Take Properties
  - Undo History
  - Envelope Manager
  - Routing Matrix
  - Track Grouping Matrix
  - Track Wiring Diagram
  - Region Render Matrix
  - FX Browser
  - Navigator
  - Big Clock
  - Performance Meter

  Finally SIZES syntax is one of the following

  - T,R,B,L
  - DIM

  T,R,B,L and DIM are either pixel sizes, or "min" or "max"

  If using the first syntax, each value T,R,B or L applies conditionally to the dock depending on its position (top, right, bottom or left). That way you may write, for example, your own "set to big" function that will use custom sizes for you desired "biggest" dock config, wherever the dock is.

  Various actions using this syntax are installed with this package and may be used as an example.

  If you want to add your own custom behaviours, just duplicate one (copy-paste the corresponding file **in the same directory**) and rename it to your will.


  Thanks to @Edgemeal for the technical advice / windows support and @X-raym for the code review!
--]]

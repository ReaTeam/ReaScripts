--[[
@description Track color layouts
@version 1.0.0
@author Ben 'Talagan' Babut
@donation https://www.paypal.com/donate/?business=3YEZMY9D6U8NC&no_recurring=1&currency_code=EUR
@license MIT
@changelog
  Initial Version
@metapackage
@provides
  [nomain] talagan_Track color layouts/talagan_Track color layouts lib.lua
  [main=main,midi_editor] . > talagan_Track color layout 1.lua
  [main=main,midi_editor] . > talagan_Track color layout 2.lua
  [main=main,midi_editor] . > talagan_Track color layout 3.lua
  [main=main,midi_editor] . > talagan_Track color layout 4.lua
  [data] talagan_Track color layouts/toolbar_talagan_track_color_layout_1.png > toolbar_icons/toolbar_talagan_track_color_layout_1.png
  [data] talagan_Track color layouts/toolbar_talagan_track_color_layout_2.png > toolbar_icons/toolbar_talagan_track_color_layout_2.png
  [data] talagan_Track color layouts/toolbar_talagan_track_color_layout_3.png > toolbar_icons/toolbar_talagan_track_color_layout_3.png
  [data] talagan_Track color layouts/toolbar_talagan_track_color_layout_4.png > toolbar_icons/toolbar_talagan_track_color_layout_4.png
@screenshot
  Standard use case https://i.imgur.com/KlOdiwy.gif
  The tool in action https://i.imgur.com/LD8x61n.gif
@about
  # Purpose

  REAPER is by default limited to one color per track. What if we were able to define multiple colors for each track, each color tied to a configuration (or layout), and switch between those layouts in an instant to recolorize the whole project set of tracks ?

  For example you could have one track color layout for composing, one for mixing, etc. Depending on the workflow, you could quickly switch from a color scheme to another.

  This is what this small extension tries to achieve.

  # How to use

  Simply call the action "talagan_Track Color Layout N" to switch to Layout number N. That's all ! Now, the current Track Color Layout is N, and all track color modifications will be done in the current layout. Then call "talagan_Track Color Layout M" to switch to Layout number M. And so on.

  The default, active layout is Layout 1 (for new projects or projects that have not used layouts yet).

  # Saving features

  All color pieces of information are stored directly on each track. Saving your project will thus also save your color layouts. They are also saved inside track templates too !

  # More layouts

  The install is limited to 4 layouts, but you can duplicate the script and change the number at the end to use another layout. You can  virtually have as many layouts as you desire.

  # Known bugs / limitations

  When importing a track template, the new tracks will have the color they had at export time, and the corresponding layout at that time may not match the current project layout (ex : they were saved while being on layout 1, and your current project is currently using layout 2, so they will thus appear with the colors of layout 1 whereas they should appear with the colors of layout 2). There's a security in the script that prevents those new tracks colors from being squashed due to this incoherency and lose their layout configs. To resynchronize these new tracks with the rest of the project, just switch the layout once after import.

--]]

--[[

  This file is a generic action for the Track Color Layout library.
  You can duplicate it and change the number at the end of its file name
  to modify the Track Color Layout to switch to.

]]--

package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path
require "talagan_Track color layouts/talagan_Track color layouts lib"
switchToTrackColorLayout(extractTrackLayoutNumFromActionName())

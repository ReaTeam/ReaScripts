--[[
Description: ChordGun
Author: pandabot
License: MIT
Version: 1.4
Screenshot: https://github.com/benjohnson2001/ChordGun/raw/release/ChordGun/src/images/chordGunInterface.png
Donate: https://paypal.me/benjohnson2001
Links:
  pandabot (Cockos forum) https://forum.cockos.com/member.php?u=127396
  Source repository (GitHub) https://github.com/benjohnson2001/ChordGun/tree/release
Metapackage: true
Provides:
    [main=main,midi_editor] pandabot_ChordGun/*.lua
About:

    ### Chord Gun
    
    #### What is it?
    Reaper tool that fires scale chords and notes into a composition, either by sequencing through the MIDI Editor or recording directly into Media Items
    

    #### How do I use it?
    There is an instructional video [here](www.youtube.com/watch?v=1CqVYcN3VAw)
		

    #### keyboard shortcuts (when GUI has focus)
    0 - stop all notes from playing

    1 - play scale chord 1

    2 - play scale chord 2

    3 - play scale chord 3

    4 - play scale chord 4

    5 - play scale chord 5

    6 - play scale chord 6

    7 - play scale chord 7

    q - higher scale note 1

    w - higher scale note 2

    e - higher scale note 3

    r - higher scale note 4

    t - higher scale note 5

    y - higher scale note 6

    u - higher scale note 7

    a - scale note 1

    s - scale note 2

    d - scale note 3

    f - scale note 4

    g - scale note 5

    h - scale note 6

    j - scale note 7

    z - lower scale note 1

    x - lower scale note 2

    c - lower scale note 3

    v - lower scale note 4

    b - lower scale note 5

    n - lower scale note 6

    m - lower scale note 7

    ctrl+, - decrement scale tonic note

    ctrl+. - increment scale tonic note

    ctrl+shift+, - decrement scale type

    ctrl+shift+. - increment scale type

    option+, - halve grid size

    option+. - double grid size

    option+shift+, - decrement octave

    option+shift+. - increment octave

    command+, - decrement chord type

    command+. - increment chord type

    command+shift+, - decrement chord inversion

    command+shift+. - increment chord inversion
--]]

--[[
Changelog:

v1.4 (2019-10-25)
  + fixed UI flaw with dropdown icon

v1.3 (2019-10-14)
  + added shift-click insertion for keyboard shortcuts

v1.2 (2019-10-13)
  + added click for preview, shift-click to insert (https://forum.cockos.com/showthread.php?t=225717)

v1.1 (2019-10-13)
  + added guard clause for scale numbers greater than 5 on pentatonic scales
  + added fix for tempo change markers

v1.0 (2018-11-07)
  + initial version
]]--

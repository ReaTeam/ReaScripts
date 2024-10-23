--[[
@description Distribute MIDI notes evenly
@version 1.0.0
@author Talagan
@license MIT
@metapackage
@provides
  [nomain] talagan_Distribute MIDI notes evenly lib.lua
  [main=main,midi_editor] . > talagan_Distribute MIDI notes evenly (grid size).lua
  [main=main,midi_editor] . > talagan_Distribute MIDI notes evenly (grid size+).lua
  [main=main,midi_editor] . > talagan_Distribute MIDI notes evenly (dialog).lua
  [main=main,midi_editor] . > talagan_Distribute MIDI notes evenly (dialog+).lua
  [main=main,midi_editor] . > talagan_Distribute MIDI notes evenly (last param).lua
@about
  # Purpose

  Redistribute the selected MIDI notes evenly in time, based on notes start, starting from the first note, and given a spacing value. Note lengths are preserved.

  # How to use
  
  Just select some MIDI notes in the editor and use one of the derived actions.

  The library has a saved state for the last used spacing value. 
  Each action has the ability to save/squash or leave that last value intact.

  Actions with a '+' at the end of their argument name will save the used value as the 'last used value' for later use through the 'last param' action.
  Actions without a '+' at the end of their argument name will leave that value intact.
  It is a convenient option to enhance your workflow.
    
  The argument syntax for an action argument is thus the following.
  
  Special values:
    - (dialog) : asks the spacing value to the user with a dialog. 
                 That field is interpreted by reaper as a time string, 
                 REAPER handles various formats such as 
                'hh:mm:ss.ms' for time or 'm.b.f' (measure / beats / fraction of beat).
    - (grid size) : use the current selected grid size of the MIDI editor directly
    - (last param) : use the last saved spacing parameter value

  Normal values:
    Use the same format as in the dialog box (ex : (0.1.0) for 1 beat, (0:0:0.250) for 250 ms).
  
  Making an action save/squash the last spacing parameter:
    Use a '+' at the end of the parameter. Ex: (grid size+), (0.1.0+), (dialog+), etc...
--]]

--[[

  This file is a generic action for the Distribute MIDI notes evenly library.
  You can duplicate it and change the argument within parenthesis contained in its file name 
  to modify the spacing/behaviour of the action.

]]--

package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path
require "talagan_Distribute MIDI notes evenly lib"
performMidiDistributionDependingOnActionFileName()

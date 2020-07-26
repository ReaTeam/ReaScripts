--[[
@noindex
@author Talagan
@license MIT
@about
  See the companion lib file for details.
--]]

package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path
require "talagan_Distribute MIDI notes evenly lib"

function main()
  if DEBUG then
    reaper.ClearConsole();
  end
  
  local retval, spacing = reaper.GetUserInputs("Enter a spacing value (No value = grid size)",1,"Spacing (use project time format), extrawidth=100",reaper.GetExtState("talagan_Distribute MIDI notes evenly", "spacing"));
  
  if retval == true then
    performMidiDistribution(spacing);
  end
end

main()




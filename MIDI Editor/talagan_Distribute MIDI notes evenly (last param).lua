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
  performMidiDistribution(reaper.GetExtState("talagan_Distribute MIDI notes evenly", "spacing"));
end

main()




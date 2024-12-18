-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of Talagan Docking Tools

package.path      = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path

local ok, docking_lib = pcall(require, "talagan_Docking tools/docking_lib")
if not ok then
  reaper.MB("This script is not well installed. Please install 'Docking tools' with Reapack.","Ouch!",0)
  return
end

if not docking_lib.CheckDependencies() then return end

docking_lib.resizeDockFromActionName(debug.getinfo(1,"S").source)


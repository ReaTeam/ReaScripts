-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description Secondary action for the "Find overlapping notes" package

package.path       = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]] .. "?.lua;" .. package.path

local ok, overlib = pcall(require, "talagan_Find overlapping notes/overlapping_lib")
if not ok then
  reaper.MB("This script is not well installed. Please reinstall it through Reapack", "Ouch!", 0);
  return
end

overlib.findOverlappingNotesInCurrentMETake()

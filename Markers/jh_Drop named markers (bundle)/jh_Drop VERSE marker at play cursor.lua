-- @noindex

package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path
require 'jh_Drop named marker function'

--
-- CUSTOM MARKER NAME HERE
--
local name = "Verse"
--

Insert_Marker_Custom_Name(name)

-- @noindex

-- fixing script path for correct require calls
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"

local IntelliFreeze = require("timtam_IntelliFreeze")

local tracks = IntelliFreeze.getSelectedTracks(nil, true)

IntelliFreeze.filterArrayInplace(tracks, IntelliFreeze.getTrackRequiresFreezing)

IntelliFreeze.freezeTracks(tracks, 2)

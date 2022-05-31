-- @description Toggle bypass non-instrument FX on selected track
-- @author Tagirijus
-- @version 1.1
-- @about
--   # Description
--
--   This little script will toggle the bypass state for each FX plugin on the selected track. So it's not affecting instrument plugins, which is great for a quick "before / after" check after you applied some effect plugins on a track, which also have an instrument plugin inserted.


local INSTRUMENT_NAMES = {'VSTi', 'VST3i'}


function debugMsg(msg)
	reaper.ShowMessageBox(tostring(msg), 'DEBUG MSG', 0)
end


function toggleBypassFXOnSelectedTrack()
	-- selected track
	local TRACK = reaper.GetSelectedTrack(0, 0)
	if TRACK == nil then
		return nil
	end

	-- FX counts
	local FXCount = reaper.TrackFX_GetCount(TRACK)
	if FXCount == 0 then
		return nil
	end

	-- iter through this FX list by their counts
	for i = 0, FXCount - 1 do
		toggleBypassOnlyForFX(TRACK, i)
	end
end


function toggleBypassOnlyForFX(track, fxid)
	-- ignore instrument plugin
	local retval, FXName = reaper.TrackFX_GetFXName(track, fxid, '')
	for i = 1, #(INSTRUMENT_NAMES) do
		tmp = INSTRUMENT_NAMES[i]
		if string.find(FXName, tmp) ~= nil then
			return nil
		end
	end

	-- toggle the bypass state for the plugin
	local bypass_state = reaper.TrackFX_GetEnabled(track, fxid)
	reaper.TrackFX_SetEnabled(track, fxid, not bypass_state)
end


function main()
	reaper.Undo_BeginBlock()

	-- Do the magic here
	toggleBypassFXOnSelectedTrack();

	reaper.Undo_EndBlock("Tagirijus: Toggle bypass FX on selected track", -1)
end

main()

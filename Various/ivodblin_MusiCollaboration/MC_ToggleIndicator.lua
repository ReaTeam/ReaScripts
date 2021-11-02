-- @noindex


function main()

--=================================================
--Creates a temporary track at the bottom of the 
--project. Its name is used by the CollabControl-
--script as a parameter.
--This trick is used, as I couldn't figure out,
--how lua scripts handle arguments.
--=================================================

	local S_TmpTrName = "MC_TI"
	local N_IdLastTr
	local N_RetVal
	local S_RetStr
	local S_ScriptPath
	local S_MC_Script = "MC_CollabControl.lua"
	local	CS_WinOS = "Win"
	local CS_MacOS = "OSX"

	N_IdLastTr = reaper.CountTracks(0)
	reaper.InsertTrackAtIndex(N_IdLastTr, false)
	
	N_RetVal, S_RetStr = reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0, N_IdLastTr), "P_NAME", S_TmpTrName, true)

	if string.find(reaper.GetOS(), CS_WinOS) ~= nil then
		S_ScriptPath = reaper.GetResourcePath() .. "\\Scripts\\MuCol\\"
	elseif string.find(reaper.GetOS(), CS_MacOS) ~= nil then
		S_ScriptPath = reaper.GetResourcePath() .. "/Scripts/MuCol/"
	end
	
	dofile(S_ScriptPath .. S_MC_Script)
end

main()

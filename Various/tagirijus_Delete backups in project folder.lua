-- @description Delete backups in project folder
-- @author Tagirijus
-- @version 2.0
-- @changelog - Since v2.0 a "Backups" folder in the project folder now will also be cleared
-- @about
--   # Description
--
--   This little script will delete all the \*.rpp-bak files in the active project folder. In v2.0 it now also looks into the Backups-folder and removes the files in there as well.


function debugMsg(msg)
	reaper.ShowMessageBox(tostring(msg), 'DEBUG MSG', 0)
end


function EnumerateFiles( folder )
	local files = {}
	local i = 0
	repeat
		local retval = reaper.EnumerateFiles( folder, i )
		table.insert(files, retval)
		i = i + 1
	until not retval
	return files
end


function SplitFileName( strfilename )
	-- Returns the Path, Filename, and Extension as 3 values
	local path, file_name, extension = string.match( strfilename, "(.-)([^\\|/]-([^\\|/%.]+))$" )
	file_name = string.match( file_name, ('(.+)%.(.+)') )
	return path, file_name, extension
end


function DeleteBackupsInProjectFolder()

	-- DELETE BACKUPS
	retval, proj_path = reaper.EnumProjects( -1 )
	if proj_path == "" then
		return false
	end
	folder, proj_name, proj_ext = SplitFileName(proj_path)

	local success = true
	local files = EnumerateFiles( folder )
	for i, file in ipairs( files ) do
		if file:find( '%.rpp%-bak' ) then
			success = os.remove(folder .. file)
			if success == false then
				debugMsg('Something went wrong during backup moving. "tagirijus_Delete backups in project folder.lua" in line 54.')
				return false
			end
		end
	end

end


function DeleteBackupsInBackupFolder()

	-- DELETE BACKUPS
	retval, proj_path = reaper.EnumProjects( -1 )
	if proj_path == "" then
		return false
	end
	folder, proj_name, proj_ext = SplitFileName(proj_path)
	folder = folder .. 'Backups\\'

	local success = true
	local files = EnumerateFiles( folder )
	for i, file in ipairs( files ) do
		if file:find( '%.rpp%-bak' ) then
			success = os.remove(folder .. file)
			if success == false then
				debugMsg('Something went wrong during backup moving. "tagirijus_Delete backups in project folder.lua" in line 54.')
				return false
			end
		end
	end

end


function main()
	DeleteBackupsInProjectFolder()
	DeleteBackupsInBackupFolder()
end

main()

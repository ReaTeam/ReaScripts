-- @description Save project and move backups
-- @author Tagirijus
-- @version 1.0
-- @about This little script will just move all the \*.rpp-bak files in the opened project folder to another location given in the script variable.

function debugMsg(msg)
	reaper.ShowMessageBox(tostring(msg), 'DEBUG MSG', 0)
end


local function GetAdditionalDir()
	-- function by amagalma; thank you!!
	local _, fullpath = reaper.EnumProjects( -1 )
	local projpath, proj_filename = fullpath:match("(.+)[\\/](.+)%.[rR][pP]+")
	local autosavedir
	local sep = package.config:sub(1,1)
	local file = io.open(reaper.get_ini_file())
	io.input(file)
	for line in io.lines() do
		autosavedir = line:match("autosavedir=([^\n\r]+)")
		if autosavedir then break end
	end
	file:close()
	if autosavedir then
		local absolute
		if string.match(reaper.GetOS(), "Win") then
			if autosavedir:match("^%a:\\") or autosavedir:match("^\\\\") then
				absolute = true
			end
		else -- unix
			absolute = autosavedir:match("^/")
		end
		if not absolute then
			if projpath then
				autosavedir = projpath .. sep .. autosavedir
			else
				autosavedir = reaper.GetProjectPath("") .. sep .. autosavedir
			end
		end
		return autosavedir
	end
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


function SaveProjectAndMoveBackups()

	-- SAVE PROJECT
	reaper.Main_SaveProject( 0, false )

	-- MOVE BACKUPS
	retval, proj_path = reaper.EnumProjects( -1 )
	if proj_path == "" then
		return false
	end
	folder, proj_name, proj_ext = SplitFileName(proj_path)

	local success = true
	local files = EnumerateFiles( folder )
	for i, file in ipairs( files ) do
		if file:find( '%.rpp%-bak' ) then
			success = os.rename(folder .. file, GetAdditionalDir() .. '\\' .. file)
			if success == false then
				debugMsg('Something went wrong during backup moving. "tagirijus_Save project and move backups.lua" in line 54.')
				return false
			end
		end
	end

end


function main()
	SaveProjectAndMoveBackups()
end

main()

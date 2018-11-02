-- @noindex
local workingDirectory = reaper.GetResourcePath() .. "/Scripts/ChordGun/src"
require(workingDirectory .. "/interface/Interface")
require(workingDirectory .. "/preferences")
require(workingDirectory .. "/scaleData")
require(workingDirectory .. "/interface/handleInput")


--clearConsoleWindow()
updateScaleData()

local interface = Interface:init("ChordGun")
interface:startGui()

local function windowHasNotBeenClosed()
	return inputCharacter ~= -1
end

local function main()

	handleInput()

	if windowHasNotBeenClosed() then
		reaper.runloop(main)
	end
	
	interface:update()
end

main()

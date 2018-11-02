-- @noindex
local function hex2rgb(arg) 

	local r, g, b = arg:match('(..)(..)(..)')
	r = tonumber(r, 16)/255
	g = tonumber(g, 16)/255
	b = tonumber(b, 16)/255
	return r, g, b
end

local function setColor(hexColor)

	local r, g, b = hex2rgb(hexColor)
	gfx.set(r, g, b, 1)
end

--[[ window ]]--

function setDrawColorToBackground()
	setColor("242424")
end

--[[ buttons ]]--

function setDrawColorToNormalButton()
	setColor("2D2D2D")
end

function setDrawColorToHighlightedButton()
	setColor("474747")
end

--

function setDrawColorToSelectedChordTypeButton()
	setColor("474747")
end

function setDrawColorToHighlightedSelectedChordTypeButton()
	setColor("717171")
end

--

function setDrawColorToSelectedChordTypeAndScaleNoteButton()
	setColor("DCDCDC")
end

function setDrawColorToHighlightedSelectedChordTypeAndScaleNoteButton()
	setColor("FFFFFF")
end

--

function setDrawColorToOutOfScaleButton()
	setColor("121212")
end

function setDrawColorToHighlightedOutOfScaleButton()
	setColor("474747")
end

--

function setDrawColorToButtonOutline()
	setColor("1D1D1D")
end

--[[ button text ]]--

function setDrawColorToNormalButtonText()
	setColor("D7D7D7")
end

function setDrawColorToHighlightedButtonText()
	setColor("EEEEEE")
end

--

function setDrawColorToSelectedChordTypeButtonText()
	setColor("F1F1F1")
end

function setDrawColorToHighlightedSelectedChordTypeButtonText()
	setColor("FDFDFD")
end

--

function setDrawColorToSelectedChordTypeAndScaleNoteButtonText()
	setColor("121212")
end

function setDrawColorToHighlightedSelectedChordTypeAndScaleNoteButtonText()
	setColor("000000")
end

--[[ buttons ]]--

function setDrawColorToHeaderOutline()
	setColor("151515")
end

function setDrawColorToHeaderBackground()
	setColor("242424")
end

function setDrawColorToHeaderText()
	setColor("818181")
end


--[[ frame ]]--
function setDrawColorToFrameOutline()
	setColor("0D0D0D")
end

function setDrawColorToFrameBackground()
	setColor("181818")
end


--[[ dropdown ]]--
function setDrawColorToDropdownOutline()
	setColor("090909")
end

function setDrawColorToDropdownBackground()
	setColor("1D1D1D")
end

function setDrawColorToDropdownText()
	setColor("D7D7D7")
end

--[[ valuebox ]]--
function setDrawColorToValueBoxOutline()
	setColor("090909")
end

function setDrawColorToValueBoxBackground()
	setColor("161616")
end

function setDrawColorToValueBoxText()
	setColor("9F9F9F")
end


--[[ text ]]--
function setDrawColorToText()
	setColor("878787")
end


--[[ debug ]]--

function setDrawColorToRed()
	setColor("FF0000")
end





--[[
function setDrawColorToBackground()

	local r, g, b
	local backgroundColor = {36, 36, 36, 1}		-- #242424
	gfx.set(table.unpack(backgroundColor))
end

function setDrawColorToNormalButton()

	local backgroundColor = {45, 45, 45, 1}		-- #2D2D2D
	gfx.set(table.unpack(backgroundColor))
end

function setDrawColorToHighlightedButton()

	local backgroundColor = {71, 71, 71, 1}		-- #474747
	gfx.set(table.unpack(backgroundColor))
end

function setDrawColorToSelectedButton()

	local backgroundColor = {220, 220, 220, 1}	-- #DCDCDC
	gfx.set(table.unpack(backgroundColor))
end
]]--
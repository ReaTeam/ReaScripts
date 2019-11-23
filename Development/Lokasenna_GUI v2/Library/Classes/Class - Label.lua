-- NoIndex: true

--[[	Lokasenna_GUI - Label class.

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Label

    Creation parameters:
	name, z, x, y, caption[, shadow, font, color, bg]

]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end


-- Label - New
GUI.Label = GUI.Element:new()
function GUI.Label:new(name, z, x, y, caption, shadow, font, color, bg)

	local label = (not x and type(z) == "table") and z or {}

	label.name = name
	label.type = "Label"

	label.z = label.z or z
	label.x = label.x or x
    label.y = label.y or y

    -- Placeholders; we'll get these at runtime
	label.w, label.h = 0, 0

	label.caption = label.caption   or caption
	label.shadow =  label.shadow    or shadow   or false
	label.font =    label.font      or font     or 2
	label.color =   label.color     or color    or "txt"
	label.bg =      label.bg        or bg       or "wnd_bg"


	GUI.redraw_z[label.z] = true

	setmetatable(label, self)
    self.__index = self
    return label

end


function GUI.Label:init(open)

    -- We can't do font measurements without an open window
    if gfx.w == 0 then return end

    self.buffs = self.buffs or GUI.GetBuffer(2)

    GUI.font(self.font)
    self.w, self.h = gfx.measurestr(self.caption)

    local w, h = self.w + 4, self.h + 4

    -- Because we might be doing this in mid-draw-loop,
    -- make sure we put this back the way we found it
    local dest = gfx.dest


    -- Keeping the background separate from the text to avoid graphical
    -- issues when the text is faded.
    gfx.dest = self.buffs[1]
    gfx.setimgdim(self.buffs[1], -1, -1)
    gfx.setimgdim(self.buffs[1], w, h)

    GUI.color(self.bg)
    gfx.rect(0, 0, w, h)

    -- Text + shadow
    gfx.dest = self.buffs[2]
    gfx.setimgdim(self.buffs[2], -1, -1)
    gfx.setimgdim(self.buffs[2], w, h)

    -- Text needs a background or the antialiasing will look like shit
    GUI.color(self.bg)
    gfx.rect(0, 0, w, h)

    gfx.x, gfx.y = 2, 2

    GUI.color(self.color)

	if self.shadow then
        GUI.shadow(self.caption, self.color, "shadow")
    else
        gfx.drawstr(self.caption)
    end

    gfx.dest = dest

end


function GUI.Label:ondelete()

	GUI.FreeBuffer(self.buffs)

end


function GUI.Label:fade(len, z_new, z_end, curve)

	self.z = z_new
	self.fade_arr = { len, z_end, reaper.time_precise(), curve or 3 }
	self:redraw()

end


function GUI.Label:draw()

    -- Font stuff doesn't work until we definitely have a gfx window
	if self.w == 0 then self:init() end

    local a = self.fade_arr and self:getalpha() or 1
    if a == 0 then return end

    gfx.x, gfx.y = self.x - 2, self.y - 2

    -- Background
    gfx.blit(self.buffs[1], 1, 0)

    gfx.a = a

    -- Text
    gfx.blit(self.buffs[2], 1, 0)

    gfx.a = 1

end


function GUI.Label:val(newval)

	if newval then
		self.caption = newval
		self:init()
		self:redraw()
	else
		return self.caption
	end

end


function GUI.Label:getalpha()

    local sign = self.fade_arr[4] > 0 and 1 or -1

    local diff = (reaper.time_precise() - self.fade_arr[3]) / self.fade_arr[1]
    diff = math.floor(diff * 100) / 100
    diff = diff^(math.abs(self.fade_arr[4]))

    local a = sign > 0 and (1 - (gfx.a * diff)) or (gfx.a * diff)

    self:redraw()

    -- Terminate the fade loop at some point
    if sign == 1 and a < 0.02 then
        self.z = self.fade_arr[2]
        self.fade_arr = nil
        return 0
    elseif sign == -1 and a > 0.98 then
        self.fade_arr = nil
    end

    return a

end

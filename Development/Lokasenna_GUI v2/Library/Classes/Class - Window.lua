-- NoIndex: true

--[[	Lokasenna_GUI - Window class

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Window

    Creation parameters:
	name, z, x, y, w, h, caption, z_set[, center]

]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end


GUI.Window = GUI.Element:new()
function GUI.Window:new(name, z, x, y, w, h, caption, z_set, center) -- Add your own params here

	local wnd = (not x and type(z) == "table") and z or {}

	wnd.name = name
	wnd.type = "Window"

	wnd.z = wnd.z or z

	wnd.x = wnd.x or x
    wnd.y = wnd.y or y
    wnd.w = wnd.w or w
    wnd.h = wnd.h or h

    wnd.caption = wnd.caption or caption

    wnd.title_height = wnd.title_height or 20
    wnd.close_size = wnd.title_height - 8

    if wnd.center == nil then
        wnd.center = not center and true or center
    end

    wnd.noclose = wnd.noclose or false

    wnd.z_set = wnd.z_set or z_set
    wnd.noadjust = {}

	GUI.redraw_z[wnd.z] = true

	setmetatable(wnd, self)
	self.__index = self
	return wnd

end


function GUI.Window:init()

	local x, y, w, h = self.x, self.y, self.w, self.h

    -- buffs[3] will be filled at :open
	self.buffs = self.buffs or GUI.GetBuffer(3)

    local th, cs = self.title_height, self.close_size


    -- Window frame/background
	gfx.dest = self.buffs[1]
	gfx.setimgdim(self.buffs[1], -1, -1)
	gfx.setimgdim(self.buffs[1], w, h)

	GUI.color("elm_frame")
    --gfx.rect(0, 0, w, h, true)
    GUI.roundrect(0, 0, w - 2, h - 2, 4, true, true)

	GUI.color("wnd_bg")
	gfx.rect(4, th + 4, w - 10, h - (th + 10), true)



    -- [Close] button

    gfx.dest = self.buffs[2]
    gfx.setimgdim(self.buffs[2], -1, -1)
    gfx.setimgdim(self.buffs[2], 2*cs, cs)

    GUI.font(2)
    local str_w, str_h = gfx.measurestr("x")

    local function draw_x(x, y, w)

        gfx.line(x,     y,          x + w - 1,  y + w - 1,  false)
        gfx.line(x,     y + 1,      x + w - 2,  y + w - 1,  false)
        gfx.line(x + 1, y,          x + w - 1,  y + w - 2,  false)

        gfx.line(x,     y + w - 1,  x + w - 1,  y,      false)
        gfx.line(x,     y + w - 2,  x + w - 2,  y,      false)
        gfx.line(x + 1, y + w - 1,  x + w - 1,  y + 1,  false)

    end

    -- Background
    GUI.color("elm_frame")
    gfx.rect(0, 0, 2*cs, cs, true)

    GUI.color("txt")
    draw_x(2, 2, cs - 4)


    -- Mouseover circle
    GUI.color("elm_fill")
    GUI.roundrect(cs, 0, cs - 1, cs - 1, 4, true, true)

    GUI.color("wnd_bg")
    draw_x(cs + 2, 2, cs - 4)

end


function GUI.Window:ondelete()

    GUI.FreeBuffer(self.buffs)

end


function GUI.Window:onupdate()

    if GUI.escape_bypass == "close" then
        self:close()
        return
    end

    if self.hoverclose and not self:mouseoverclose() then
        self.hoverclose = nil
        self:redraw()
        return true
    end

end



function GUI.Window:draw()

    self:drawbackground()
    self:drawwindow()
    if self.caption and self.caption ~= "" then self:drawcaption() end


end




------------------------------------
-------- Input methods -------------
------------------------------------


function GUI.Window:onmouseup()

    if not self.noclose and self:mouseoverclose() then
        self:close()
        self:redraw()
    end

end


function GUI.Window:onmouseover()

    if self.noclose then return end

    local old = self.hoverclose
    self.hoverclose = self:mouseoverclose()

    if self.hoverclose ~= old then self:redraw() end

end




------------------------------------
-------- Drawing helpers -----------
------------------------------------


function GUI.Window:drawbackground()

    gfx.blit(self.buffs[3], 1, 0, 0, 0, GUI.cur_w, GUI.cur_h, 0, 0, GUI.cur_w, GUI.cur_h)

    GUI.color("shadow")
    gfx.a = 0.4
    gfx.rect(0, 0, GUI.cur_w, GUI.cur_h)
    gfx.a = 1

end


function GUI.Window:drawwindow()

	local x, y, w, h = self.x, self.y, self.w, self.h
    local cs = self.close_size
    local off = (self.title_height - cs) / 2 + 2

    -- Copy the pre-drawn bits
	gfx.blit(self.buffs[1], 1, 0, 0, 0, w, h, x, y)
    if not self.noclose then
        gfx.blit(self.buffs[2], 1, 0, self.hoverclose and cs or 0, 0, cs, cs, x + w - cs - off, y + off)
    end

end


function GUI.Window:drawcaption()

    GUI.font(2)
    GUI.color("txt")
    local str_w, str_h = gfx.measurestr(self.caption)
    gfx.x = self.x + (self.w - str_w) / 2
    gfx.y = self.y + (self.title_height - str_h) / 2 + 1 -- extra px looks better
    gfx.drawstr(self.caption)

end




------------------------------------
-------- Script methods ------------
------------------------------------


function GUI.Window:open(...)

    if self.center then self.x, self.y = GUI.center(self) end

    self:hidelayers()

    -- Flag for Core.lua so pressing Esc will close this window
    -- and not the script window
    GUI.escape_bypass = true

    -- Run user hook
    if self.onopen then self:onopen({...}) end

    self:blitwindow()

    self:redraw()

end


function GUI.Window:close(...)

    -- Run user hook
    if self.onclose then self:onclose({...}) end

    self:showlayers()

    GUI.escape_bypass = false

end


function GUI.Window:adjustelm(elm, force)

    if elm.ox and not force then return end

    elm.ox, elm.oy = elm.x, elm.y
    elm.x, elm.y = self.x + elm.x, self.y + self.title_height + elm.y

end


function GUI.Window:adjustchildelms(force)

    for k in pairs( self:getchildelms() ) do

        if not self.noadjust[k] then

            self:adjustelm(GUI.elms[k], force)

        end

    end

end


------------------------------------
-------- Helpers -------------------
------------------------------------


function GUI.Window:mouseoverclose()

    if GUI.IsInside(   {x = self.x + self.w - self.title_height - 4,
                        y = self.y,
                        w = self.title_height + 4,
                        h = self.title_height + 4},
                        GUI.mouse.x, GUI.mouse.y) then
        return true
    end
end


function GUI.Window:blitwindow()

    -- Copy the graphics buffer to use as a background for the window
    -- since everything is hidden
    gfx.dest = self.buffs[3]
    gfx.setimgdim(self.buffs[3], -1, -1)
    gfx.setimgdim(self.buffs[3], GUI.cur_w, GUI.cur_h)

    --gfx.blit(source, scale, rotation[, srcx, srcy, srself.close_width, srch, destx, desty, destw, desth, rotxoffs, rotyoffs] )
    gfx.blit(0, 1, 0, 0, 0, GUI.cur_w, GUI.cur_h, 0, 0, GUI.cur_w, GUI.cur_h)
    gfx.x, gfx.y = 0, 0
    gfx.blurto(GUI.cur_w, GUI.cur_h)

end


function GUI.Window:hidelayers()

    -- Store the actual hidden layers, and then hide everything...
    local elms_hide = {}
    for i = 1, GUI.z_max do
        if GUI.elms_hide[i] then elms_hide[i] = true end
        GUI.elms_hide[i] = true
    end
    self.elms_hide = elms_hide

    -- ...except the window and its child layers
    GUI.elms_hide[self.z] = false
    for k, v in pairs(self.z_set) do
        GUI.elms_hide[v] = false
    end

end


function GUI.Window:showlayers()

    -- Set the layer visibility back to where it was
    for i = 1, GUI.z_max do
        GUI.elms_hide[i] = self.elms_hide[i]
    end

    -- Hide the window and its child layers
    GUI.elms_hide[self.z] = true
    for k, v in pairs(self.z_set) do
        GUI.elms_hide[v] = true
    end

end


function GUI.Window:getchildelms()

    local elms = {}
    for _, n in pairs(self.z_set) do

        if GUI.elms_list[n] then
            for k, v in pairs(GUI.elms_list[n]) do
                if v ~= self.name then elms[v] = true end
            end
        end
    end

    return elms

end
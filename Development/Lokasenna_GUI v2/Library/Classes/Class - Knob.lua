-- NoIndex: true

--[[	Lokasenna_GUI - Knob class

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Knob

    Creation parameters:
	name, z, x, y, w, caption, min, max, default,[ inc, vals]

]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end

-- Knob - New.
GUI.Knob = GUI.Element:new()
function GUI.Knob:new(name, z, x, y, w, caption, min, max, default, inc, vals)

	local Knob = (not x and type(z) == "table") and z or {}

	Knob.name = name
	Knob.type = "Knob"

	Knob.z = Knob.z or z

	Knob.x = Knob.x or x
    Knob.y = Knob.y or y
    Knob.w = Knob.w or w
    Knob.h = Knob.w

	Knob.caption = Knob.caption or caption
	Knob.bg = Knob.bg or "wnd_bg"

    Knob.cap_x = Knob.cap_x or 0
    Knob.cap_y = Knob.cap_y or 0

	Knob.font_a = Knob.font_a or 3
	Knob.font_b = Knob.font_b or 4

	Knob.col_txt = Knob.col_txt or "txt"
	Knob.col_head = Knob.col_head or "elm_fill"
	Knob.col_body = Knob.col_body or "elm_frame"

	Knob.min = Knob.min or min
    Knob.max = Knob.max or max
    Knob.inc = Knob.inc or inc or 1


    Knob.steps = math.abs(Knob.max - Knob.min) / Knob.inc

    function Knob:formatretval(val)

        local decimal = tonumber(string.match(val, "%.(.*)") or 0)
        local places = decimal ~= 0 and string.len( decimal) or 0
        return string.format("%." .. places .. "f", val)

    end

	Knob.vals = Knob.vals or vals

	-- Determine the step angle
	Knob.stepangle = (3 / 2) / Knob.steps

	Knob.default = Knob.default or default
    Knob.curstep = Knob.default

	Knob.curval = Knob.curstep / Knob.steps

    Knob.retval = Knob:formatretval(
                ((Knob.max - Knob.min) / Knob.steps) * Knob.curstep + Knob.min
                                    )


	GUI.redraw_z[Knob.z] = true

	setmetatable(Knob, self)
	self.__index = self
	return Knob

end


function GUI.Knob:init()

	self.buff = self.buff or GUI.GetBuffer()

	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)

	-- Figure out the points of the triangle

	local r = self.w / 2
	local rp = r * 1.5
	local curangle = 0
	local o = rp + 1

	local w = 2 * rp + 2

	gfx.setimgdim(self.buff, 2*w, w)

	local side_angle = (math.acos(0.666667) / GUI.pi) * 0.9

	local Ax, Ay = GUI.polar2cart(curangle, rp, o, o)
    local Bx, By = GUI.polar2cart(curangle + side_angle, r - 1, o, o)
	local Cx, Cy = GUI.polar2cart(curangle - side_angle, r - 1, o, o)

	-- Head
	GUI.color(self.col_head)
	GUI.triangle(true, Ax, Ay, Bx, By, Cx, Cy)
	GUI.color("elm_outline")
	GUI.triangle(false, Ax, Ay, Bx, By, Cx, Cy)

	-- Body
	GUI.color(self.col_body)
	gfx.circle(o, o, r, 1)
	GUI.color("elm_outline")
	gfx.circle(o, o, r, 0)

	--gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs] )
	gfx.blit(self.buff, 1, 0, 0, 0, w, w, w + 1, 0)
	gfx.muladdrect(w + 1, 0, w, w, 0, 0, 0, GUI.colors["shadow"][4])

end


function GUI.Knob:ondelete()

	GUI.FreeBuffer(self.buff)

end


-- Knob - Draw
function GUI.Knob:draw()

	local x, y = self.x, self.y

	local r = self.w / 2
	local o = {x = x + r, y = y + r}


	-- Value labels
	if self.vals then self:drawvals(o, r) end

    if self.caption and self.caption ~= "" then self:drawcaption(o, r) end


	-- Figure out where the knob is pointing
	local curangle = (-5 / 4) + (self.curstep * self.stepangle)

	local blit_w = 3 * r + 2
	local blit_x = 1.5 * r

	-- Shadow
	for i = 1, GUI.shadow_dist do

		gfx.blit(   self.buff, 1, curangle * GUI.pi,
                    blit_w + 1, 0, blit_w, blit_w,
                    o.x - blit_x + i - 1, o.y - blit_x + i - 1)

	end

	-- Body
	gfx.blit(   self.buff, 1, curangle * GUI.pi,
                0, 0, blit_w, blit_w,
                o.x - blit_x - 1, o.y - blit_x - 1)

end


-- Knob - Get/set value
function GUI.Knob:val(newval)

	if newval then

        self:setcurstep(newval)

		self:redraw()

	else
		return self.retval
	end

end


-- Knob - Dragging.
function GUI.Knob:ondrag()

	local y = GUI.mouse.y
	local ly = GUI.mouse.ly

	-- Ctrl?
	local ctrl = GUI.mouse.cap&4==4

	-- Multiplier for how fast the knob turns. Higher = slower
	--					Ctrl	Normal
	local adj = ctrl and 1200 or 150

    self:setcurval( GUI.clamp(self.curval + ((ly - y) / adj), 0, 1) )

    --[[
	self.curval = self.curval + ((ly - y) / adj)
	if self.curval > 1 then self.curval = 1 end
	if self.curval < 0 then self.curval = 0 end



	self.curstep = GUI.round(self.curval * self.steps)

	self.retval = GUI.round(((self.max - self.min) / self.steps) * self.curstep + self.min)
    ]]--
	self:redraw()

end


-- Knob - Doubleclick
function GUI.Knob:ondoubleclick()
	--[[
	self.curstep = self.default
	self.curval = self.curstep / self.steps
	self.retval = GUI.round(((self.max - self.min) / self.steps) * self.curstep + self.min)
	]]--

    self:setcurstep(self.default)

	self:redraw()

end


-- Knob - Mousewheel
function GUI.Knob:onwheel()

	local ctrl = GUI.mouse.cap&4==4

	-- How many steps per wheel-step
	local fine = 1
	local coarse = math.max( GUI.round(self.steps / 30), 1)

	local adj = ctrl and fine or coarse

    self:setcurval( GUI.clamp( self.curval + (GUI.mouse.inc * adj / self.steps), 0, 1))

	self:redraw()

end



------------------------------------
-------- Drawing methods -----------
------------------------------------

function GUI.Knob:drawcaption(o, r)

    local str = self.caption

	GUI.font(self.font_a)
	local cx, cy = GUI.polar2cart(1/2, r * 2, o.x, o.y)
	local str_w, str_h = gfx.measurestr(str)
	gfx.x, gfx.y = cx - str_w / 2 + self.cap_x, cy - str_h / 2  + 8 + self.cap_y
	GUI.text_bg(str, self.bg)
	GUI.shadow(str, self.col_txt, "shadow")

end


function GUI.Knob:drawvals(o, r)

    for i = 0, self.steps do

        local angle = (-5 / 4 ) + (i * self.stepangle)

        -- Highlight the current value
        if i == self.curstep then
            GUI.color(self.col_head)
            GUI.font({GUI.fonts[self.font_b][1], GUI.fonts[self.font_b][2] * 1.2, "b"})
        else
            GUI.color(self.col_txt)
            GUI.font(self.font_b)
        end

        --local output = (i * self.inc) + self.min
        local output = self:formatretval( i * self.inc + self.min )

        if self.output then
            local t = type(self.output)

            if t == "string" or t == "number" then
                output = self.output
            elseif t == "table" then
                output = self.output[output]
            elseif t == "function" then
                output = self.output(output)
            end
        end

        -- Avoid any crashes from weird user data
        output = tostring(output)

        if output ~= "" then

            local str_w, str_h = gfx.measurestr(output)
            local cx, cy = GUI.polar2cart(angle, r * 2, o.x, o.y)
            gfx.x, gfx.y = cx - str_w / 2, cy - str_h / 2
            GUI.text_bg(output, self.bg)
            gfx.drawstr(output)
        end

    end

end




------------------------------------
-------- Value helpers -------------
------------------------------------

function GUI.Knob:setcurstep(step)

    self.curstep = step
    self.curval = self.curstep / self.steps
    self:setretval()

end


function GUI.Knob:setcurval(val)

    self.curval = val
    self.curstep = GUI.round(val * self.steps)
    self:setretval()

end


function GUI.Knob:setretval()

    self.retval = self:formatretval(self.inc * self.curstep + self.min)

end

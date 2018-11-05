-- NoIndex: true

--[[	Lokasenna_GUI - Listbox class

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Listbox

    Creation parameters:
	name, z, x, y, w, h[, list, multi, caption, pad]

]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end

-- Listbox - New
GUI.Listbox = GUI.Element:new()
function GUI.Listbox:new(name, z, x, y, w, h, list, multi, caption, pad)

	local lst = (not x and type(z) == "table") and z or {}

	lst.name = name
	lst.type = "Listbox"

	lst.z = lst.z or z

	lst.x = lst.x or x
    lst.y = lst.y or y
    lst.w = lst.w or w
    lst.h = lst.h or h

	lst.list = lst.list or list or {}
	lst.retval = lst.retval or {}

    if lst.multi == nil then
        lst.multi = multi or false
    end

	lst.caption = lst.caption or caption or ""
	lst.pad = lst.pad or pad or 4

    if lst.shadow == nil then
        lst.shadow = true
    end
	lst.bg = lst.bg or "elm_bg"
    lst.cap_bg = lst.cap_bg or "wnd_bg"
	lst.color = lst.color or "txt"

	-- Scrollbar fill
	lst.col_fill = lst.col_fill or "elm_fill"

	lst.font_a = lst.font_a or 3

	lst.font_b = lst.font_b or 4

	lst.wnd_y = 1

	lst.wnd_h, lst.wnd_w, lst.char_w = nil, nil, nil

	GUI.redraw_z[lst.z] = true

	setmetatable(lst, self)
	self.__index = self
	return lst

end


function GUI.Listbox:init()

	-- If we were given a CSV, process it into a table
	if type(self.list) == "string" then self.list = self:CSVtotable(self.list) end

	local x, y, w, h = self.x, self.y, self.w, self.h

	self.buff = GUI.GetBuffer()

	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)
	gfx.setimgdim(self.buff, w, h)

	GUI.color(self.bg)
	gfx.rect(0, 0, w, h, 1)

	GUI.color("elm_frame")
	gfx.rect(0, 0, w, h, 0)


end


function GUI.Listbox:ondelete()

	GUI.FreeBuffer(self.buff)

end


function GUI.Listbox:draw()


	local x, y, w, h = self.x, self.y, self.w, self.h

	local caption = self.caption
	local pad = self.pad

	-- Some values can't be set in :init() because the window isn't
	-- open yet - measurements won't work.
	if not self.wnd_h then self:wnd_recalc() end

	-- Draw the caption
	if caption and caption ~= "" then self:drawcaption() end

	-- Draw the background and frame
	gfx.blit(self.buff, 1, 0, 0, 0, w, h, x, y)

	-- Draw the text
	self:drawtext()

	-- Highlight any selected items
	self:drawselection()

	-- Vertical scrollbar
	if #self.list > self.wnd_h then self:drawscrollbar() end

end


function GUI.Listbox:val(newval)

	if newval then
		--self.list = type(newval) == "string" and self:CSVtotable(newval) or newval
        if type(newval) == "table" then

            for i = 1, #self.list do
                self.retval[i] = newval[i] or nil
            end

        elseif type(newval) == "number" then

            newval = math.floor(newval)
            for i = 1, #self.list do
                self.retval[i] = (i == newval)
            end

        end

		self:redraw()

	else

		if self.multi then
			return self.retval
		else
			for k, v in pairs(self.retval) do
				return k
			end
		end

	end

end


---------------------------------
------ Input methods ------------
---------------------------------


function GUI.Listbox:onmouseup()

	if not self:overscrollbar() then

		local item = self:getitem(GUI.mouse.y)

		if self.multi then

			-- Ctrl
			if GUI.mouse.cap & 4 == 4 then

				self.retval[item] = not self.retval[item]

			-- Shift
			elseif GUI.mouse.cap & 8 == 8 then

				self:selectrange(item)

			else

				self.retval = {[item] = true}

			end

		else

			self.retval = {[item] = true}

		end

	end

	self:redraw()

end


function GUI.Listbox:onmousedown(scroll)

	-- If over the scrollbar, or we came from :ondrag with an origin point
	-- that was over the scrollbar...
	if scroll or self:overscrollbar() then

        local wnd_c = GUI.round( ((GUI.mouse.y - self.y) / self.h) * #self.list  )
		self.wnd_y = math.floor( GUI.clamp(1, wnd_c - (self.wnd_h / 2), #self.list - self.wnd_h + 1) )

		self:redraw()

	end

end


function GUI.Listbox:ondrag()

	if self:overscrollbar(GUI.mouse.ox) then

		self:onmousedown(true)

	-- Drag selection?
	else


	end

	self:redraw()

end


function GUI.Listbox:onwheel(inc)

	local dir = inc > 0 and -1 or 1

	-- Scroll up/down one line
	self.wnd_y = GUI.clamp(1, self.wnd_y + dir, math.max(#self.list - self.wnd_h + 1, 1))

	self:redraw()

end


---------------------------------
-------- Drawing methods---------
---------------------------------


function GUI.Listbox:drawcaption()

	local str = self.caption

	GUI.font(self.font_a)
	local str_w, str_h = gfx.measurestr(str)
	gfx.x = self.x - str_w - self.pad
	gfx.y = self.y + self.pad
	GUI.text_bg(str, self.cap_bg)

	if self.shadow then
		GUI.shadow(str, self.color, "shadow")
	else
		GUI.color(self.color)
		gfx.drawstr(str)
	end

end


function GUI.Listbox:drawtext()

	GUI.color(self.color)
	GUI.font(self.font_b)

	local tmp = {}
	for i = self.wnd_y, math.min(self:wnd_bottom() - 1, #self.list) do

		local str = tostring(self.list[i]) or ""
        tmp[#tmp + 1] = str

	end

	gfx.x, gfx.y = self.x + self.pad, self.y + self.pad
    local r = gfx.x + self.w - 2*self.pad
    local b = gfx.y + self.h - 2*self.pad
	gfx.drawstr( table.concat(tmp, "\n"), 0, r, b)

end


function GUI.Listbox:drawselection()

	local off_x, off_y = self.x + self.pad, self.y + self.pad
	local x, y, w, h

	w = self.w - 2 * self.pad

	GUI.color("elm_fill")
	gfx.a = 0.5
	gfx.mode = 1
	-- for wnd_y, wnd_y + wnd_h do

	for i = 1, #self.list do

		if self.retval[i] and i >= self.wnd_y and i < self:wnd_bottom() then

			y = off_y + (i - self.wnd_y) * self.char_h
			gfx.rect(off_x, y, w, self.char_h, true)

		end

	end

	gfx.mode = 0
	gfx.a = 1

end


function GUI.Listbox:drawscrollbar()

	local x, y, w, h = self.x, self.y, self.w, self.h
	local sx, sy, sw, sh = x + w - 8 - 4, y + 4, 8, h - 12


	-- Draw a gradient to fade out the last ~16px of text
	GUI.color("elm_bg")
	for i = 0, 15 do
		gfx.a = i/15
		gfx.line(sx + i - 15, y + 2, sx + i - 15, y + h - 4)
	end

	gfx.rect(sx, y + 2, sw + 2, h - 4, true)

	-- Draw slider track
	GUI.color("tab_bg")
	GUI.roundrect(sx, sy, sw, sh, 4, 1, 1)
	GUI.color("elm_outline")
	GUI.roundrect(sx, sy, sw, sh, 4, 1, 0)

	-- Draw slider fill
	local fh = (self.wnd_h / #self.list) * sh - 4
	if fh < 4 then fh = 4 end
	local fy = sy + ((self.wnd_y - 1) / #self.list) * sh + 2

	GUI.color(self.col_fill)
	GUI.roundrect(sx + 2, fy, sw - 4, fh, 2, 1, 1)

end


---------------------------------
-------- Helpers ----------------
---------------------------------


-- Updates internal values for the window size
function GUI.Listbox:wnd_recalc()

	GUI.font(self.font_b)

    self.char_w, self.char_h = gfx.measurestr("_")
	self.wnd_h = math.floor((self.h - 2*self.pad) / self.char_h)
	self.wnd_w = math.floor(self.w / self.char_w)

end


-- Get the bottom edge of the window (in rows)
function GUI.Listbox:wnd_bottom()

	return self.wnd_y + self.wnd_h

end


-- Determine which item the user clicked
function GUI.Listbox:getitem(y)

	--local item = math.floor( ( (y - self.y) / self.h ) * self.wnd_h) + self.wnd_y

	GUI.font(self.font_b)

	local item = math.floor(	(y - (self.y + self.pad))
								/	self.char_h)
				+ self.wnd_y

	item = GUI.clamp(1, item, #self.list)

	return item

end


-- Split a CSV into a table
function GUI.Listbox:CSVtotable(str)

	local tmp = {}
	for line in string.gmatch(str, "([^,]+)") do
		table.insert(tmp, line)
	end

	return tmp

end


-- Is the mouse over the scrollbar (true) or the text area (false)?
function GUI.Listbox:overscrollbar(x)

	return (#self.list > self.wnd_h and (x or GUI.mouse.x) >= (self.x + self.w - 12))

end


-- Selects from the first selected item to the current mouse position
function GUI.Listbox:selectrange(mouse)

	-- Find the first selected item
	local first
	for k, v in pairs(self.retval) do
		first = first and math.min(k, first) or k
	end

	if not first then first = 1 end

	self.retval = {}

	-- Select everything between the first selected item and the mouse
	for i = mouse, first, (first > mouse and 1 or -1) do
		self.retval[i] = true
	end

end
-- NoIndex: true

--[[	Lokasenna_GUI - Frame class

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Frame

    Creation parameters:
	name, z, x, y, w, h[, shadow, fill, color, round]

]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end



GUI.Frame = GUI.Element:new()
function GUI.Frame:new(name, z, x, y, w, h, shadow, fill, color, round)

	local Frame = (not x and type(z) == "table") and z or {}
	Frame.name = name
	Frame.type = "Frame"

	Frame.z = Frame.z or z

	Frame.x = Frame.x or x
    Frame.y = Frame.y or y
    Frame.w = Frame.w or w
    Frame.h = Frame.h or h

    if Frame.shadow == nil then
        Frame.shadow = shadow or false
    end
    if Frame.fill == nil then
        Frame.fill = fill or false
    end
	Frame.color = Frame.color or color or "elm_frame"
	Frame.round = Frame.round or round or 0

	Frame.text, Frame.last_text = Frame.text or "", ""
	Frame.txt_indent = Frame.txt_indent or 0
	Frame.txt_pad = Frame.txt_pad or 0

	Frame.bg = Frame.bg or "wnd_bg"

	Frame.font = Frame.font or 4
	Frame.col_txt = Frame.col_txt or "txt"
	Frame.pad = Frame.pad or 4

	GUI.redraw_z[Frame.z] = true

	setmetatable(Frame, self)
	self.__index = self
	return Frame

end


function GUI.Frame:init()

    self.buff = self.buff or GUI.GetBuffer()

    gfx.dest = self.buff
    gfx.setimgdim(self.buff, -1, -1)
    gfx.setimgdim(self.buff, 2 * self.w + 4, self.h + 2)

    self:drawframe()

    self:drawtext()

end


function GUI.Frame:ondelete()

	GUI.FreeBuffer(self.buff)

end


function GUI.Frame:draw()

    local x, y, w, h = self.x, self.y, self.w, self.h

    if self.shadow then

        for i = 1, GUI.shadow_dist do

            gfx.blit(self.buff, 1, 0, w + 2, 0, w + 2, h + 2, x + i - 1, y + i - 1)

        end

    end

    gfx.blit(self.buff, 1, 0, 0, 0, w + 2, h + 2, x - 1, y - 1)

end


function GUI.Frame:val(new)

	if new ~= nil then
		self.text = new
        self:init()
		self:redraw()
	else
		return string.gsub(self.text, "\n", "")
	end

end




------------------------------------
-------- Drawing methods -----------
------------------------------------


function GUI.Frame:drawframe()

    local w, h = self.w, self.h
	local fill = self.fill
	local round = self.round

    -- Frame background
    if self.bg then
        GUI.color(self.bg)
        if round > 0 then
            GUI.roundrect(1, 1, w, h, round, 1, true)
        else
            gfx.rect(1, 1, w, h, true)
        end
    end

    -- Shadow
    local r, g, b, a = table.unpack(GUI.colors["shadow"])
	gfx.set(r, g, b, 1)
	GUI.roundrect(self.w + 2, 1, self.w, self.h, round, 1, 1)
	gfx.muladdrect(self.w + 2, 1, self.w + 2, self.h + 2, 1, 1, 1, a, 0, 0, 0, 0 )


    -- Frame
	GUI.color(self.color)
	if round > 0 then
		GUI.roundrect(1, 1, w, h, round, 1, fill)
	else
		gfx.rect(1, 1, w, h, fill)
	end

end


function GUI.Frame:drawtext()

	if self.text and self.text:len() > 0 then

        if self.text ~= self.last_text then
            self.text = self:wrap_text(self.text)
            self.last_text = self.text
        end

		GUI.font(self.font)
		GUI.color(self.col_txt)

		gfx.x, gfx.y = self.pad + 1, self.pad + 1
		if not fill then GUI.text_bg(self.text, self.bg) end
		gfx.drawstr(self.text)

	end

end




------------------------------------
-------- Helpers -------------------
------------------------------------


function GUI.Frame:wrap_text(text)

    return GUI.word_wrap(   text, self.font, self.w - 2*self.pad,
                            self.txt_indent, self.txt_pad)

end

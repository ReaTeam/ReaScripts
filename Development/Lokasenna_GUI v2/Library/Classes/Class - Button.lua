-- NoIndex: true

--[[	Lokasenna_GUI - Button class 

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/TextEditor
    
    Creation parameters:
	name, z, x, y, w, h, caption, func[, ...]

]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end


-- Button - New
GUI.Button = GUI.Element:new()
function GUI.Button:new(name, z, x, y, w, h, caption, func, ...)

	local Button = (not x and type(z) == "table") and z or {}
	
	Button.name = name
	Button.type = "Button"
	
	Button.z = Button.z or z
	
	Button.x = Button.x or x
    Button.y = Button.y or y
    Button.w = Button.w or w
    Button.h = Button.h or h

	Button.caption = Button.caption or caption
	
	Button.font = Button.font or 3
	Button.col_txt = Button.col_txt or "txt"
	Button.col_fill = Button.col_fill or "elm_frame"
	
	Button.func = Button.func or func or function () end
	Button.params = Button.params or {...}
	
	Button.state = 0
    
	GUI.redraw_z[Button.z] = true    

	setmetatable(Button, self)
	self.__index = self
	return Button

end


function GUI.Button:init()
	
	self.buff = self.buff or GUI.GetBuffer()
	
	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)
	gfx.setimgdim(self.buff, 2*self.w + 4, self.h + 2)
	
	GUI.color(self.col_fill)
	GUI.roundrect(1, 1, self.w, self.h, 4, 1, 1)
	GUI.color("elm_outline")
	GUI.roundrect(1, 1, self.w, self.h, 4, 1, 0)
	
	
	local r, g, b, a = table.unpack(GUI.colors["shadow"])
	gfx.set(r, g, b, 1)
	GUI.roundrect(self.w + 2, 1, self.w, self.h, 4, 1, 1)
	gfx.muladdrect(self.w + 2, 1, self.w + 2, self.h + 2, 1, 1, 1, a, 0, 0, 0, 0 )
	
	
end


function GUI.Button:ondelete()
	
	GUI.FreeBuffer(self.buff)
	
end



-- Button - Draw.
function GUI.Button:draw()
	
	local x, y, w, h = self.x, self.y, self.w, self.h
	local state = self.state

	-- Draw the shadow if not pressed
	if state == 0 then
		
		for i = 1, GUI.shadow_dist do
			
			gfx.blit(self.buff, 1, 0, w + 2, 0, w + 2, h + 2, x + i - 1, y + i - 1)
			
		end

	end
	
	gfx.blit(self.buff, 1, 0, 0, 0, w + 2, h + 2, x + 2 * state - 1, y + 2 * state - 1) 	
	
	-- Draw the caption
	GUI.color(self.col_txt)
	GUI.font(self.font)
    
    local str = self.caption
    str = str:gsub([[\n]],"\n")
	
	local str_w, str_h = gfx.measurestr(str)
	gfx.x = x + 2 * state + ((w - str_w) / 2)
	gfx.y = y + 2 * state + ((h - str_h) / 2)
	gfx.drawstr(str)
	
end


-- Button - Mouse down.
function GUI.Button:onmousedown()
	
	self.state = 1
	self:redraw()

end


-- Button - Mouse up.
function GUI.Button:onmouseup() 
	
	self.state = 0
	
	-- If the mouse was released on the button, run func
	if GUI.IsInside(self, GUI.mouse.x, GUI.mouse.y) then
		
		self.func(table.unpack(self.params))
		
	end
	self:redraw()

end

function GUI.Button:ondoubleclick()
	
	self.state = 0
	
	end


-- Button - Right mouse up
function GUI.Button:onmouser_up()

	if GUI.IsInside(self, GUI.mouse.x, GUI.mouse.y) and self.r_func then
	
		self.r_func(table.unpack(self.r_params))

	end
end


-- Button - Execute (extra method)
-- Used for allowing hotkeys to press a button
function GUI.Button:exec(r)
	
	if r then
		self.r_func(table.unpack(self.r_params))
	else
		self.func(table.unpack(self.params))
	end
	
end


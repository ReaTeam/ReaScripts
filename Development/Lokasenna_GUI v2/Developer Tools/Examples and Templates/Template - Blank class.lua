-- NoIndex: true

--[[	Lokasenna_GUI - Template class
	
	---- User parameters ----

	(name, z, x, y, w, h[, caption, pad])
    
Required:
z				Element depth, used for hiding and disabling layers. 1 is the highest.
x, y			Coordinates of top-left corner
w, h			Width and height of the template

Optional:
                
                Any extra parameters accessible via GUI.New() should be listed here.


Additional:

                Any extra parameters NOT accessible via GUI.New() should be listed here.


Extra methods:


GUI.Val()		
GUI.Val(new)	


]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end


GUI.Template = GUI.Element:new()
function GUI.Template:new(name, z, x, y, w, h, param1, param2) -- Add your own params here
	
    -- This provides support for creating elms with a keyed table
	local tmp = (not x and type(z) == "table") and z or {}
	
	tmp.name = name
	tmp.type = "Template"
	
	tmp.z = tmp.z or z

	
	tmp.x = tmp.x or x
    tmp.y = tmp.y or y
    tmp.w = tmp.w or w
    tmp.h = tmp.h or h

    -- Optional parameters should be given default values to avoid errors/crashes:
    tmp.param1 = tmp.param1 or param1 or 12
    
    -- Because Lua makes no distinction between nil, false, and simply omitting a parameter, we have
    -- to be a little more creative when specifically passing false values:
    if tmp.param2 == nil then
        tmp.param2 = param2 or false
    end
    
	GUI.redraw_z[z] = true	    
	
	setmetatable(tmp, self)
	self.__index = self
	return tmp

end


function GUI.Template:init()
	
	local x, y, w, h = self.x, self.y, self.w, self.h
	
    -- Pretty much any class will benefit from doing as much drawing as possible
    -- to a buffer, so the GUI can just copy/paste it when the screen updates rather
    -- than getting each element to redraw itself every single time.
    
    -- Seriously, redrawing can eat up a TON of CPU.
    
	self.buff = GUI.GetBuffer()
	
	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)
	gfx.setimgdim(self.buff, w, h)
	
	GUI.color("elm_bg")
	gfx.rect(0, 0, w, h, 1)
	
	GUI.color("elm_frame")
	gfx.rect(0, 0, w, h, 0)
	
end


function GUI.Template:draw()
	
	local x, y, w, h = self.x, self.y, self.w, self.h
	
    -- Copy the pre-drawn bits
	gfx.blit(self.buff, 1, 0, 0, 0, w, h, x, y)

    -- Draw text, or whatever you want, here
    
end


function GUI.Template:val(newval)
	
	if newval then
		self.retval = newval
		self:redraw()		
	else
		return self.retval
	end
    
end


function GUI.Template:onmousedown()
	
    
    -- Odds are, any input method will want to make the element redraw itself so
    -- whatever the user did is actually shown on the screen.
	self:redraw()	
end


function GUI.Template:ondoubleclick()

	self:redraw()
end


function GUI.Template:ondrag()

    -- GUI.mouse.ox and .oy are available to compare where the drag started from
    -- with the current position

	self:redraw()
end


function GUI.Template:onwheel(inc)
    
    -- Use 'inc' to figure out which way the wheel was turned and by how much
    
    self:redraw()
end


function GUI.Template:ontype()
    
    -- See the TextEditor class for a good example of handling keyboard input

	self:redraw()	
end


--------------------------------------------------
-------- See Core.lua -> GUI.Element -------------
-------- for all of the available methods --------
--------------------------------------------------



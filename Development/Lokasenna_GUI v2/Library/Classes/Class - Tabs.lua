-- NoIndex: true

--[[	Lokasenna_GUI - Tabs class

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Tabs
    
    Creation parameters:
    name, z, x, y, tab_w, tab_h, opts[, pad]

]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end

GUI.Tabs = GUI.Element:new()
function GUI.Tabs:new(name, z, x, y, tab_w, tab_h, opts, pad)
	
	local Tab = (not x and type(z) == "table") and z or {}
	
	Tab.name = name
	Tab.type = "Tabs"
	
	Tab.z = Tab.z or z
	
	Tab.x = Tab.x or x
    Tab.y = Tab.y or y
	Tab.tab_w = Tab.tab_w or tab_w or 48
    Tab.tab_h = Tab.tab_h or tab_h or 20

	Tab.font_a = Tab.font_a or 3
    Tab.font_b = Tab.font_b or 4
	
	Tab.bg = Tab.bg or "elm_bg"
	Tab.col_txt = Tab.col_txt or "txt"
	Tab.col_tab_a = Tab.col_tab_a or "wnd_bg"
	Tab.col_tab_b = Tab.col_tab_b or "tab_bg"
	
    -- Placeholder for if I ever figure out downward tabs
	Tab.dir = Tab.dir or "u"
	
	Tab.pad = Tab.pad or pad or 8
	
	-- Parse the string of options into a table
    if not Tab.optarray then
        local opts = Tab.opts or opts
        
        Tab.optarray = {}
        if type(opts) == "string" then
            for word in string.gmatch(opts, '([^,]+)') do
                Tab.optarray[#Tab.optarray + 1] = word
            end
        elseif type(opts) == "table" then
            Tab.optarray = opts
        end
    end
	
	Tab.z_sets = {}
	for i = 1, #Tab.optarray do
		Tab.z_sets[i] = {}
	end
    
	-- Figure out the total size of the Tab frame now that we know the 
    -- number of buttons, so we can do the math for clicking on it
	Tab.w, Tab.h = (Tab.tab_w + Tab.pad) * #Tab.optarray + 2*Tab.pad + 12, Tab.tab_h
    
    if Tab.fullwidth == nil then
        Tab.fullwidth = true
    end
    
	-- Currently-selected option
	Tab.retval = Tab.retval or 1
    Tab.state = Tab.retval or 1

	GUI.redraw_z[Tab.z] = true	

	setmetatable(Tab, self)
	self.__index = self
	return Tab

end


function GUI.Tabs:init()
    
    self:update_sets()    
    
end


function GUI.Tabs:draw()
	
	local x, y = self.x + 16, self.y
    local tab_w, tab_h = self.tab_w, self.tab_h
	local pad = self.pad
	local font = self.font_b
	local dir = self.dir
	local state = self.state
    
    -- Make sure w is at least the size of the tabs. 
    -- (GUI builder will let you try to set it lower)
    self.w = self.fullwidth and (GUI.cur_w - self.x) or math.max(self.w, (tab_w + pad) * #self.optarray + 2*pad + 12)  

	GUI.color(self.bg)
	gfx.rect(x - 16, y, self.w, self.h, true)
			
	local x_adj = tab_w + pad
	
	-- Draw the inactive tabs first
	for i = #self.optarray, 1, -1 do

		if i ~= state then
			--											 
			local tab_x, tab_y = x + GUI.shadow_dist + (i - 1) * x_adj, 
								 y + GUI.shadow_dist * (dir == "u" and 1 or -1)

			self:draw_tab(tab_x, tab_y, tab_w, tab_h, dir, font, self.col_txt, self.col_tab_b, self.optarray[i])

		end
	
	end

	self:draw_tab(x + (state - 1) * x_adj, y, tab_w, tab_h, dir, self.font_a, self.col_txt, self.col_tab_a, self.optarray[state])
	
    -- Keep the active tab's top separate from the window background
	GUI.color(self.bg)
    gfx.line(x + (state - 1) * x_adj, y, x + state * x_adj, y, 1)

	-- Cover up some ugliness at the bottom of the tabs
	GUI.color("wnd_bg")		
	gfx.rect(self.x, self.y + (dir == "u" and tab_h or -6), self.w, 6, true)

	
end


function GUI.Tabs:val(newval)
	
	if newval then
		self.state = newval
		self.retval = self.state

		self:update_sets()
		self:redraw()
	else
		return self.state
	end
	
end


function GUI.Tabs:onresize()
    
    if self.fullwidth then self:redraw() end
    
end


------------------------------------
-------- Input methods -------------
------------------------------------


function GUI.Tabs:onmousedown()

    -- Offset for the first tab
	local adj = 0.75*self.h

	local mouseopt = (GUI.mouse.x - (self.x + adj)) / (#self.optarray * (self.tab_w + self.pad))
		
	mouseopt = GUI.clamp((math.floor(mouseopt * #self.optarray) + 1), 1, #self.optarray)

	self.state = mouseopt

	self:redraw()
	
end


function GUI.Tabs:onmouseup()
		
	-- Set the new option, or revert to the original if the cursor isn't inside the list anymore
	if GUI.IsInside(self, GUI.mouse.x, GUI.mouse.y) then
        
		self.retval = self.state		
		self:update_sets()
		
	else
		self.state = self.retval	
	end
    
	self:redraw()	
    
end


function GUI.Tabs:ondrag() 

	self:onmousedown()
	self:redraw()
    
end


function GUI.Tabs:onwheel()

	self.state = GUI.round(self.state + GUI.mouse.inc)
	
	if self.state < 1 then self.state = 1 end
	if self.state > #self.optarray then self.state = #self.optarray end
	
	self.retval = self.state
	self:update_sets()
	self:redraw()
    
end




------------------------------------
-------- Drawing helpers -----------
------------------------------------


function GUI.Tabs:draw_tab(x, y, w, h, dir, font, col_txt, col_bg, lbl)

	local dist = GUI.shadow_dist
    local y1, y2 = table.unpack(dir == "u" and  {y, y + h}
                                           or   {y + h, y})

	GUI.color("shadow")

    -- Tab shadow
    for i = 1, dist do
        
        gfx.rect(x + i, y, w, h, true)
        
        gfx.triangle(   x + i, y1, 
                        x + i, y2, 
                        x + i - (h / 2), y2)
        
        gfx.triangle(   x + i + w, y1,
                        x + i + w, y2,
                        x + i + w + (h / 2), y2)

    end

    -- Hide those gross, pixellated edges
    gfx.line(x + dist, y1, x + dist - (h / 2), y2, 1)
    gfx.line(x + dist + w, y1, x + dist + w + (h / 2), y2, 1)

    GUI.color(col_bg)

    gfx.rect(x, y, w, h, true)

    gfx.triangle(   x, y1,
                    x, y2,
                    x - (h / 2), y2)
                    
    gfx.triangle(   x + w, y1,
                    x + w, y2,
                    x + w + (h / 2), y + h)

    gfx.line(x, y1, x - (h / 2), y2, 1)
    gfx.line(x + w, y1, x + w + (h / 2), y2, 1)    
    
    
	-- Draw the tab's label
	GUI.color(col_txt)
	GUI.font(font)
	
	local str_w, str_h = gfx.measurestr(lbl)
	gfx.x = x + ((w - str_w) / 2)
	gfx.y = y + ((h - str_h) / 2)
	gfx.drawstr(lbl)	

end




------------------------------------
-------- Tab helpers ---------------
------------------------------------


-- Updates visibility for any layers assigned to the tabs
function GUI.Tabs:update_sets(init)
    
	local state = self.state
	
	if init then
		self.z_sets = init
	end

	local z_sets = self.z_sets

	if not z_sets or #z_sets[1] < 1 then
		--reaper.ShowMessageBox("GUI element '"..self.name.."':\nNo z sets found.", "Library error", 0)
		--GUI.quit = true
		return 0
	end

	for i = 1, #z_sets do
        
        if i ~= state then
            for _, z in pairs(z_sets[i]) do
                
                GUI.elms_hide[z] = true
                
            end
        end
        
	end
    
    for _, z in pairs(z_sets[state]) do
        
        GUI.elms_hide[z] = false
        
    end

end

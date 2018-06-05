--[[
Description: Copy values from selected MIDI notes
Version: 1.33
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
    Install the script in Main, MIDI Editor, and Inline Editor action lists.
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
    Copies a set of selected MIDI notes, and applies individual values
    from them to other MIDI notes.
Provides:
    [main=main,midi_editor,midi_inlineeditor] .
--]]

-- Licensed under the GNU GPL v3
local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

local function req(file)
	
	if missing_lib then return function () end end
	
    local ret, err = loadfile(( file:sub(2, 2) == ":" and "" or script_path) .. file)
	if not ret then
		reaper.ShowMessageBox("Couldn't load "..file.."\n\nError: "..tostring(err), "Library error", 0)
		missing_lib = true		
		return function () end

	else 
		return ret
	end	

end

---- Libraries added with Lokasenna's Script Compiler ----



---- Beginning of file: F:/Github Repositories/Lokasenna_GUI/Core.lua ----

--[[
	
	Lokasenna_GUI 2.0
	
	Core functionality
	
]]--

local function GUI_table ()

local GUI = {}

GUI.version = "2.0"




------------------------------------
-------- Error handling ------------
------------------------------------


-- A basic crash handler, just to add some helpful detail
-- to the Reaper error message.
GUI.crash = function (errObject)
                             
    local by_line = "([^\r\n]*)\r?\n?"
    local trim_path = "[\\/]([^\\/]-:%d+:.+)$"
    local err = string.match(errObject, trim_path) or "Couldn't get error message."

    local trace = debug.traceback()
    local tmp = {}
    for line in string.gmatch(trace, by_line) do
        
        local str = string.match(line, trim_path) or line
        
        tmp[#tmp + 1] = str

    end
    
    local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)$")
    
    local ret = reaper.ShowMessageBox(name.." has crashed!\n\n"..
                                      "Would you like to have a crash report printed "..
                                      "to the Reaper console?", 
                                      "Oops", 4)
    
    if ret == 6 then 
        reaper.ShowConsoleMsg("Error: "..err.."\n\n"..
                              "Stack traceback:\n\t"..table.concat(tmp, "\n\t", 2).."\n\n")
    end
    
    gfx.quit()
end



------------------------------------
-------- Main functions ------------
------------------------------------


-- All elements are stored here. Don't put them anywhere else, or
-- Main will never find them.
GUI.elms = {}

-- On each draw loop, only layers that are set to true in this table
-- will be redrawn; if false, it will just copy them from the buffer
-- Set [0] = true to redraw everything.
GUI.redraw_z = {}

-- Maintain a list of all GUI elements, sorted by their z order	
-- Also removes any elements with z = -1, for automatically
-- cleaning things up.
GUI.elms_list = {}
GUI.z_max = 0
GUI.update_elms_list = function (init)
	
	local z_table = {}
	GUI.z_max = 0

	for key, __ in pairs(GUI.elms) do

		local z = GUI.elms[key].z or 5

		-- Delete elements if the script asked to
		if z == -1 then
			
			GUI.elms[key]:ondelete()
			GUI.elms[key] = nil
			
		else

			if z_table[z] then
				table.insert(z_table[z], key)

			else
				z_table[z] = {key}

			end
		
		end
		
		if init then 
			
			GUI.elms[key]:init()

		end

		GUI.z_max = math.max(z, GUI.z_max)

	end

	GUI.elms_list = z_table
	
end

GUI.elms_hide = {}
GUI.elms_freeze = {}




GUI.Init = function ()
    xpcall( function()
        
        
        -- Create the window
        gfx.clear = reaper.ColorToNative(table.unpack(GUI.colors.wnd_bg))
        
        if not GUI.x then GUI.x = 0 end
        if not GUI.y then GUI.y = 0 end
        if not GUI.w then GUI.w = 640 end
        if not GUI.h then GUI.h = 480 end

        if GUI.anchor and GUI.corner then
            GUI.x, GUI.y = GUI.get_window_pos(  GUI.x, GUI.y, GUI.w, GUI.h, 
                                                GUI.anchor, GUI.corner)
        end
            
        gfx.init(GUI.name, GUI.w, GUI.h, GUI.dock or 0, GUI.x, GUI.y)
        
        
        GUI.cur_w, GUI.cur_h = gfx.w, gfx.h

        -- Measure the window's title bar, in case we need it
        local __, __, wnd_y, __, __ = gfx.dock(-1, 0, 0, 0, 0)
        local __, gui_y = gfx.clienttoscreen(0, 0)
        GUI.title_height = gui_y - wnd_y


        -- Initialize a few values
        GUI.last_time = 0
        GUI.mouse = {
        
            x = 0,
            y = 0,
            cap = 0,
            down = false,
            wheel = 0,
            lwheel = 0
            
        }
      
        -- Store which element the mouse was clicked on.
        -- This is essential for allowing drag behaviour where dragging affects 
        -- the element position.
        GUI.mouse_down_elm = nil
        GUI.rmouse_down_elm = nil
        GUI.mmouse_down_elm = nil
            
        -- Convert color presets from 0..255 to 0..1
        for i, col in pairs(GUI.colors) do
            col[1], col[2], col[3], col[4] =    col[1] / 255, col[2] / 255, 
                                                col[3] / 255, col[4] / 255
        end
        
        -- Initialize the tables for our z-order functions
        GUI.update_elms_list(true)	
        
        if GUI.exit then reaper.atexit(GUI.exit) end
        
        GUI.gfx_open = true

    end, GUI.crash)
end

GUI.Main = function ()
    xpcall( function ()    

        GUI.Main_Update_State()

        GUI.Main_Update_Elms()

        -- If the user gave us a function to run, check to see if it needs to be 
        -- run again, and do so. 
        if GUI.func then
            
            local new_time = os.time()
            if new_time - GUI.last_time >= (GUI.freq or 1) then
                GUI.func()
                GUI.last_time = new_time
            
            end
        end
        
        
        -- Maintain a list of elms and zs in case any have been moved or deleted
        GUI.update_elms_list()    
        
        
        GUI.Main_Draw()

    end, GUI.crash)
end


GUI.Main_Update_State = function()
    
	-- Update mouse and keyboard state, window dimensions
    if GUI.mouse.x ~= gfx.mouse_x or GUI.mouse.y ~= gfx.mouse_y then
        
        GUI.mouse.lx, GUI.mouse.ly = GUI.mouse.x, GUI.mouse.y
        GUI.mouse.x, GUI.mouse.y = gfx.mouse_x, gfx.mouse_y
        
        -- Hook for user code
        if GUI.onmousemove then GUI.onmousemove() end
       
    else
    
        GUI.mouse.lx, GUI.mouse.ly = GUI.mouse.x, GUI.mouse.y
       
    end
	GUI.mouse.wheel = gfx.mouse_wheel
	GUI.mouse.cap = gfx.mouse_cap
	GUI.char = gfx.getchar() 
	
	if GUI.cur_w ~= gfx.w or GUI.cur_h ~= gfx.h then
		GUI.cur_w, GUI.cur_h = gfx.w, gfx.h
        
        -- Deprecated
		GUI.resized = true
        
        -- Hook for user code
        if GUI.onresize then GUI.onresize() end
        
	else
		GUI.resized = false
	end
	
	--	(Escape key)	(Window closed)		(User function says to close)
	--if GUI.char == 27 or GUI.char == -1 or GUI.quit == true then
	if (GUI.char == 27 and not (	GUI.mouse.cap & 4 == 4 
								or 	GUI.mouse.cap & 8 == 8 
								or 	GUI.mouse.cap & 16 == 16
                                or  GUI.escape_bypass))
			or GUI.char == -1 
			or GUI.quit == true then
		
		return 0
	else
        if GUI.char == 27 and GUI.escape_bypass then GUI.escape_bypass = "close" end
		reaper.defer(GUI.Main)
	end
    
end


--[[
	Update each element's state, starting from the top down.
	
	This is very important, so that lower elements don't
	"steal" the mouse.
	
	
	This function will also delete any elements that have their z set to -1

	Handy for something like Label:fade if you just want to remove
	the faded element entirely
	
	***Don't try to remove elements in the middle of the Update
	loop; use this instead to have them automatically cleaned up***	
	
]]--
GUI.Main_Update_Elms = function ()
    
    -- Disabled May 2/2018 to see if it was actually necessary
	-- GUI.update_elms_list()
	
	-- We'll use this to shorten each elm's update loop if the user did something
	-- Slightly more efficient, and averts any bugs from false positives
	GUI.elm_updated = false

	-- Check for the dev mode toggle before we get too excited about updating elms
	if  GUI.char == 282         and GUI.mouse.cap & 4 ~= 0 
    and GUI.mouse.cap & 8 ~= 0  and GUI.mouse.cap & 16 ~= 0 then
		
		GUI.dev_mode = not GUI.dev_mode
		GUI.elm_updated = true
		GUI.redraw_z[0] = true
		
	end	


	for i = 0, GUI.z_max do
		if  GUI.elms_list[i] and #GUI.elms_list[i] > 0 
        and not (GUI.elms_hide[i] or GUI.elms_freeze[i]) then
			for __, elm in pairs(GUI.elms_list[i]) do

				if elm and GUI.elms[elm] then GUI.Update(GUI.elms[elm]) end
				
			end
		end
		
	end

	-- Just in case any user functions want to know...
	GUI.mouse.last_down = GUI.mouse.down
	GUI.mouse.last_r_down = GUI.mouse.r_down

end

    
GUI.Main_Draw = function ()    
    
	-- Redraw all of the elements, starting from the bottom up.
	local w, h = GUI.cur_w, GUI.cur_h

	local need_redraw, global_redraw
	if GUI.redraw_z[0] then
		global_redraw = true
        GUI.redraw_z[0] = false
	else
		for z, b in pairs(GUI.redraw_z) do
			if b == true then 
				need_redraw = true 
				break
			end
		end
	end

	if need_redraw or global_redraw then
		
		-- All of the layers will be drawn to their own buffer (dest = z), then
		-- composited in buffer 0. This allows buffer 0 to be blitted as a whole
		-- when none of the layers need to be redrawn.
		
		gfx.dest = 0
		gfx.setimgdim(0, -1, -1)
		gfx.setimgdim(0, w, h)

		GUI.color("wnd_bg")
		gfx.rect(0, 0, w, h, 1)

		for i = GUI.z_max, 0, -1 do
			if  GUI.elms_list[i] and #GUI.elms_list[i] > 0 
            and not GUI.elms_hide[i] then

				if global_redraw or GUI.redraw_z[i] then
					
					-- Set this before we redraw, so that elms can call a redraw 
                    -- from their own :draw method. e.g. Labels fading out
					GUI.redraw_z[i] = false

					gfx.setimgdim(i, -1, -1)
					gfx.setimgdim(i, w, h)
					gfx.dest = i
					
					for __, elm in pairs(GUI.elms_list[i]) do
						if not GUI.elms[elm] then GUI.Msg(elm.." doesn't exist?") end
                        
                        -- Reset these just in case an element or some user code forgot to,
                        -- otherwise we get things like the whole buffer being blitted with a=0.2
                        gfx.mode = 0
                        gfx.set(0, 0, 0, 1)
                        
						GUI.elms[elm]:draw()
					end

					gfx.dest = 0
				end
							
				gfx.blit(i, 1, 0, 0, 0, w, h, 0, 0, w, h, 0, 0)
			end
		end

        -- Draw developer hints if necessary
        if GUI.dev_mode then
            GUI.Draw_Dev()
        else		
            GUI.Draw_Version()		
        end
		
	end
   
		
    -- Reset them again, to be extra sure
	gfx.mode = 0
	gfx.set(0, 0, 0, 1)
	
	gfx.dest = -1
	gfx.blit(0, 1, 0, 0, 0, w, h, 0, 0, w, h, 0, 0)
	
	gfx.update()

end




------------------------------------
-------- Buffer functions ----------
------------------------------------


--[[
	We'll use this to let elements have their own graphics buffers
	to do whatever they want in. 
	
	num	=	How many buffers you want, or 1 if not specified.
	
	Returns a table of buffers, or just a buffer number if num = 1
	
	i.e.
	
	-- Assign this element's buffer
	function GUI.my_element:new(.......)
	
	   ...new stuff...
	   
	   my_element.buffers = GUI.GetBuffer(4)
	   -- or
	   my_element.buffer = GUI.GetBuffer()
		
	end
	
	-- Draw to the buffer
	function GUI.my_element:init()
		
		gfx.dest = self.buffers[1]
		-- or
		gfx.dest = self.buffer
		...draw stuff...
	
	end
	
	-- Copy from the buffer
	function GUI.my_element:draw()
		gfx.blit(self.buffers[1], 1, 0)
		-- or
		gfx.blit(self.buffer, 1, 0)
	end
	
]]--

-- Any used buffers will be marked as True here
GUI.buffers = {}

-- When deleting elements, their buffer numbers
-- will be added here for easy access.
GUI.freed_buffers = {}

GUI.GetBuffer = function (num)
	
	local ret = {}
	local prev
	
	for i = 1, (num or 1) do
		
		if #GUI.freed_buffers > 0 then
			
			ret[i] = table.remove(GUI.freed_buffers)
			
		else
		
			for j = (not prev and 1023 or prev - 1), 0, -1 do
			
				if not GUI.buffers[j] then
					ret[i] = j
					GUI.buffers[j] = true
					break
				end
				
			end
			
		end
		
	end

	return (#ret == 1) and ret[1] or ret

end

-- Elements should pass their buffer (or buffer table) to this
-- when being deleted
GUI.FreeBuffer = function (num)
	
	if type(num) == "number" then
		table.insert(GUI.freed_buffers, num)
	else
		for k, v in pairs(num) do
			table.insert(GUI.freed_buffers, v)
		end
	end	
	
end




------------------------------------
-------- Element functions ---------
------------------------------------


-- Wrapper for creating new elements, allows them to know their own name
-- If called after the script window has opened, will also run their :init
-- method.
-- Can be given a user class directly by passing the class itself as 'elm',
-- or if 'elm' is a string will look for a class in GUI[elm]
GUI.New = function (name, elm, ...)

    local elm = type(elm) == "string"   and GUI[elm]
                                        or  elm

    if not elm or type(elm) ~= "table" then
		reaper.ShowMessageBox(  "Unable to create element '"..tostring(name)..
                                "'.\nClass '"..tostring(elm).."' isn't available.", 
                                "GUI Error", 0)
		GUI.quit = true
		return nil
	end
    
    if GUI.elms[name] then GUI.elms[name]:delete() end
	
	GUI.elms[name] = elm:new(name, ...)
    
	if GUI.gfx_open then GUI.elms[name]:init() end
    
    -- Return this so (I think) a bunch of new elements could be created
    -- within a table that would end up holding their names for easy bulk
    -- processing.

    return name
	
end


--	See if the any of the given element's methods need to be called
GUI.Update = function (elm)
	
	local x, y = GUI.mouse.x, GUI.mouse.y
	local x_delta, y_delta = x-GUI.mouse.lx, y-GUI.mouse.ly
	local wheel = GUI.mouse.wheel
	local inside = GUI.IsInside(elm, x, y)
	
	local skip = elm:onupdate() or false
		
	
	if GUI.elm_updated then
		if elm.focus then
			elm.focus = false
			elm:lostfocus()
		end
		skip = true
	end


	if skip then return end
    
    -- Left button
    if GUI.mouse.cap&1==1 then
        
        -- If it wasn't down already...
        if not GUI.mouse.last_down then


            -- Was a different element clicked?
            if not inside then 
                if GUI.mouse_down_elm == elm then
                    -- Should already have been reset by the mouse-up, but safeguard...
                    GUI.mouse_down_elm = nil
                end
                if elm.focus then
                    elm.focus = false
                    elm:lostfocus()
                end
                return 0
            else
                if GUI.mouse_down_elm == nil then -- Prevent click-through

                    GUI.mouse_down_elm = elm

                    -- Double clicked?
                    if GUI.mouse.downtime 
                    and reaper.time_precise() - GUI.mouse.downtime < 0.10 
                    then

                        GUI.mouse.downtime = nil
                        GUI.mouse.dbl_clicked = true
                        elm:ondoubleclick()

                    elseif not GUI.mouse.dbl_clicked then

                        elm.focus = true
                        elm:onmousedown()

                    end

                    GUI.elm_updated = true
                end
                
                GUI.mouse.down = true
                GUI.mouse.ox, GUI.mouse.oy = x, y
                
                -- Where in the elm the mouse was clicked. For dragging stuff
                -- and keeping it in the place relative to the cursor.
                GUI.mouse.off_x, GUI.mouse.off_y = x - elm.x, y - elm.y
                
            end
                        
        -- 		Dragging? Did the mouse start out in this element?
        elseif (x_delta ~= 0 or y_delta ~= 0) 
        and     GUI.mouse_down_elm == elm then
        
            if elm.focus ~= false then 

                GUI.elm_updated = true
                elm:ondrag(x_delta, y_delta)
                
            end
        end

    -- If it was originally clicked in this element and has been released
    elseif GUI.mouse.down and GUI.mouse_down_elm == elm then

            GUI.mouse_down_elm = nil

            if not GUI.mouse.dbl_clicked then elm:onmouseup() end

            GUI.elm_updated = true
            GUI.mouse.down = false
            GUI.mouse.dbl_clicked = false
            GUI.mouse.ox, GUI.mouse.oy = -1, -1
            GUI.mouse.off_x, GUI.mouse.off_y = -1, -1
            GUI.mouse.lx, GUI.mouse.ly = -1, -1
            GUI.mouse.downtime = reaper.time_precise()


    end
    
    
    -- Right button
    if GUI.mouse.cap&2==2 then
        
        -- If it wasn't down already...
        if not GUI.mouse.last_r_down then

            -- Was a different element clicked?
            if not inside then 
                if GUI.rmouse_down_elm == elm then
                    -- Should have been reset by the mouse-up, but in case...
                    GUI.rmouse_down_elm = nil
                end
                --elm.focus = false
            else
            
                -- Prevent click-through
                if GUI.rmouse_down_elm == nil then 

                    GUI.rmouse_down_elm = elm

                        -- Double clicked?
                    if GUI.mouse.r_downtime 
                    and reaper.time_precise() - GUI.mouse.r_downtime < 0.20 
                    then

                        GUI.mouse.r_downtime = nil
                        GUI.mouse.r_dbl_clicked = true
                        elm:onr_doubleclick()

                    elseif not GUI.mouse.r_dbl_clicked then

                        elm:onmouser_down()

                    end

                    GUI.elm_updated = true

                end
                
                GUI.mouse.r_down = true
                GUI.mouse.r_ox, GUI.mouse.r_oy = x, y
                -- Where in the elm the mouse was clicked. For dragging stuff
                -- and keeping it in the place relative to the cursor.
                GUI.mouse.r_off_x, GUI.mouse.r_off_y = x - elm.x, y - elm.y                    

            end
            
    
        -- 		Dragging? Did the mouse start out in this element?
        elseif (x_delta ~= 0 or y_delta ~= 0) 
        and     GUI.rmouse_down_elm == elm then
        
            if elm.focus ~= false then 

                elm:onr_drag(x_delta, y_delta)
                GUI.elm_updated = true

            end

        end

    -- If it was originally clicked in this element and has been released
    elseif GUI.mouse.r_down and GUI.rmouse_down_elm == elm then 
    
        GUI.rmouse_down_elm = nil
    
        if not GUI.mouse.r_dbl_clicked then elm:onmouser_up() end

        GUI.elm_updated = true
        GUI.mouse.r_down = false
        GUI.mouse.r_dbl_clicked = false
        GUI.mouse.r_ox, GUI.mouse.r_oy = -1, -1
        GUI.mouse.r_off_x, GUI.mouse.r_off_y = -1, -1
        GUI.mouse.r_lx, GUI.mouse.r_ly = -1, -1
        GUI.mouse.r_downtime = reaper.time_precise()

    end



    -- Middle button
    if GUI.mouse.cap&64==64 then
        
        
        -- If it wasn't down already...
        if not GUI.mouse.last_m_down then


            -- Was a different element clicked?
            if not inside then 
                if GUI.mmouse_down_elm == elm then
                    -- Should have been reset by the mouse-up, but in case...
                    GUI.mmouse_down_elm = nil
                end
            else
                -- Prevent click-through
                if GUI.mmouse_down_elm == nil then 

                    GUI.mmouse_down_elm = elm

                    -- Double clicked?
                    if GUI.mouse.m_downtime 
                    and reaper.time_precise() - GUI.mouse.m_downtime < 0.20 
                    then

                        GUI.mouse.m_downtime = nil
                        GUI.mouse.m_dbl_clicked = true
                        elm:onm_doubleclick()

                    else

                        elm:onmousem_down()

                    end

                    GUI.elm_updated = true

              end

                GUI.mouse.m_down = true
                GUI.mouse.m_ox, GUI.mouse.m_oy = x, y
                GUI.mouse.m_off_x, GUI.mouse.m_off_y = x - elm.x, y - elm.y

            end
            

        
        -- 		Dragging? Did the mouse start out in this element?
        elseif (x_delta ~= 0 or y_delta ~= 0) 
        and     GUI.mmouse_down_elm == elm then
        
            if elm.focus ~= false then 
                
                elm:onm_drag(x_delta, y_delta)
                GUI.elm_updated = true
                
            end

        end

    -- If it was originally clicked in this element and has been released
    elseif GUI.mouse.m_down and GUI.mmouse_down_elm == elm then
    
        GUI.mmouse_down_elm = nil
    
        if not GUI.mouse.m_dbl_clicked then elm:onmousem_up() end
        
        GUI.elm_updated = true
        GUI.mouse.m_down = false
        GUI.mouse.m_dbl_clicked = false
        GUI.mouse.m_ox, GUI.mouse.m_oy = -1, -1
        GUI.mouse.m_off_x, GUI.mouse.m_off_y = -1, -1
        GUI.mouse.m_lx, GUI.mouse.m_ly = -1, -1
        GUI.mouse.m_downtime = reaper.time_precise()

    end

		
	
	-- If the mouse is hovering over the element
	if inside and not GUI.mouse.down and not GUI.mouse.r_down then
		elm:onmouseover()
		elm.mouseover = true
	else
		elm.mouseover = false
		--elm.hovering = false
	end
	
	
	-- If the mousewheel's state has changed
	if inside and GUI.mouse.wheel ~= GUI.mouse.lwheel then
		
		GUI.mouse.inc = (GUI.mouse.wheel - GUI.mouse.lwheel) / 120
		
		elm:onwheel(GUI.mouse.inc)
		GUI.elm_updated = true
		GUI.mouse.lwheel = GUI.mouse.wheel
	
	end
	
	-- If the element is in focus and the user typed something
	if elm.focus and GUI.char ~= 0 then
		elm:ontype() 
		GUI.elm_updated = true
	end
	
end


--[[	Return or change an element's value
	
	For use with external user functions. Returns the given element's current 
	value or, if specified, sets a new one.	Changing values with this is often 
	preferable to setting them directly, as most :val methods will also update 
	some internal parameters and redraw the element when called.
]]--
GUI.Val = function (elm, newval)

	if not GUI.elms[elm] then return nil end
	
	if newval then
		GUI.elms[elm]:val(newval)
	else
		return GUI.elms[elm]:val()
	end

end


-- Are these coordinates inside the given element?
-- If no coords are given, will use the mouse cursor
GUI.IsInside = function (elm, x, y)

	if not elm then return false end

	local x, y = x or GUI.mouse.x, y or GUI.mouse.y

	return	(	x >= (elm.x or 0) and x < ((elm.x or 0) + (elm.w or 0)) and 
				y >= (elm.y or 0) and y < ((elm.y or 0) + (elm.h or 0))	)
	
end


-- Returns the x,y that would center elm2 within elm1. 
-- Axis can be "x", "y", or "xy".
GUI.center = function (elm1, elm2)
    
    if not (    elm1.x and elm1.y and elm1.w and elm1.h
            and elm2.x and elm2.y and elm2.w and elm2.h) then return end
            
    return (elm1.x + (elm1.w - elm2.w) / 2), (elm1.y + (elm1.h - elm2.h) / 2)
    
    
end




------------------------------------
-------- Prototype element ---------
----- + all default methods --------
------------------------------------


--[[
	All classes will use this as their template, so that
	elements are initialized with every method available.
]]--
GUI.Element = {}
function GUI.Element:new(name)
	
	local elm = {}
	if name then elm.name = name end
    self.z = 1
	
	setmetatable(elm, self)
	self.__index = self
	return elm
	
end

-- Called a) when the script window is first opened
-- 		  b) when any element is created via GUI.New after that
-- i.e. Elements can draw themselves to a buffer once on :init()
-- and then just blit/rotate/etc as needed afterward
function GUI.Element:init() end

-- Called whenever the element's z layer is told to redraw
function GUI.Element:draw() end

-- Ask for a redraw on the next update
function GUI.Element:redraw()
    GUI.redraw_z[self.z] = true
end

-- Called on every update loop, unless the element is hidden or frozen
function GUI.Element:onupdate() end

function GUI.Element:delete()
    
    self.ondelete(self)
    GUI.elms[self.name] = nil
    
end

-- Called when the element is deleted by GUI.update_elms_list() or :delete.
-- Use it for freeing up buffers and anything else memorywise that this
-- element was doing
function GUI.Element:ondelete() end


-- Set or return the element's value
-- Can be useful for something like a Slider that doesn't have the same
-- value internally as what it's displaying
function GUI.Element:val() end

-- Called on every update loop if the mouse is over this element.
function GUI.Element:onmouseover() end

-- Only called once; won't repeat if the button is held
function GUI.Element:onmousedown() end

function GUI.Element:onmouseup() end
function GUI.Element:ondoubleclick() end

-- Will continue being called even if you drag outside the element
function GUI.Element:ondrag() end

-- Right-click
function GUI.Element:onmouser_down() end
function GUI.Element:onmouser_up() end
function GUI.Element:onr_doubleclick() end
function GUI.Element:onr_drag() end

-- Middle-click
function GUI.Element:onmousem_down() end
function GUI.Element:onmousem_up() end
function GUI.Element:onm_doubleclick() end
function GUI.Element:onm_drag() end

function GUI.Element:onwheel() end
function GUI.Element:ontype() end


-- Elements like a Textbox that need to keep track of their focus
-- state will use this to e.g. update the text somewhere else 
-- when the user clicks out of the box.
function GUI.Element:lostfocus() end




------------------------------------
-------- Developer stuff -----------
------------------------------------


-- Print a string to the Reaper console.
GUI.Msg = function (str)
	reaper.ShowConsoleMsg(tostring(str).."\n")
end

-- Print the specified parameters for a given element to the Reaper console.
-- If nothing is specified, prints all of the element's properties.
function GUI.Element:Msg(...)
    
    local arg = {...}
    
    if #arg == 0 then
        arg = {}
        for k in GUI.kpairs(self, "full") do
            arg[#arg+1] = k
        end
    end    
    
    if not self or not self.type then return end
    local pre = tostring(self.name) .. "."
    local strs = {}
    
    for i = 1, #arg do
        
        strs[#strs + 1] = pre .. tostring(arg[i]) .. " = "
        
        if type(self[arg[i]]) == "table" then 
            strs[#strs] = strs[#strs] .. "table:"
            strs[#strs + 1] = GUI.table_list(self[arg[i]], nil, 1)
        else
            strs[#strs] = strs[#strs] .. tostring(self[arg[i]])
        end
        
    end
    
    reaper.ShowConsoleMsg( "\n" .. table.concat(strs, "\n") .. "\n")
    
end


-- Developer mode settings
GUI.dev = {
	
	-- grid_a must be a multiple of grid_b, or it will
	-- probably never be drawn
	grid_a = 128,
	grid_b = 16
	
}


-- Draws a grid overlay and some developer hints
-- Toggled via Ctrl+Shift+Alt+Z, or by setting GUI.dev_mode = true
GUI.Draw_Dev = function ()
	    
	-- Draw a grid for placing elements
	GUI.color("magenta")
	gfx.setfont("Courier New", 10)
	
	for i = 0, GUI.w, GUI.dev.grid_b do
		
		local a = (i == 0) or (i % GUI.dev.grid_a == 0)
		gfx.a = a and 1 or 0.3
		gfx.line(i, 0, i, GUI.h)
		gfx.line(0, i, GUI.w, i)
		if a then
			gfx.x, gfx.y = i + 4, 4
			gfx.drawstr(i)
			gfx.x, gfx.y = 4, i + 4
			gfx.drawstr(i)
		end	
	
	end
    
    local str = "Mouse: "..math.modf(GUI.mouse.x)..", "..math.modf(GUI.mouse.y).." "
    local str_w, str_h = gfx.measurestr(str)
    gfx.x, gfx.y = GUI.w - str_w - 2, GUI.h - 2*str_h - 2
    
    GUI.color("black")
    gfx.rect(gfx.x - 2, gfx.y - 2, str_w + 4, 2*str_h + 4, true)
    
    GUI.color("white")
    gfx.drawstr(str)
   
    local snap_x, snap_y = GUI.nearestmultiple(GUI.mouse.x, GUI.dev.grid_b),
                           GUI.nearestmultiple(GUI.mouse.y, GUI.dev.grid_b)
    
    gfx.x, gfx.y = GUI.w - str_w - 2, GUI.h - str_h - 2
	gfx.drawstr(" Snap: "..snap_x..", "..snap_y)
    
	gfx.a = 1
    
    GUI.redraw_z[0] = true
	
end




------------------------------------
-------- Constants/presets ---------
------------------------------------
	
    
GUI.chars = {
	
	ESCAPE		= 27,
	SPACE		= 32,
	BACKSPACE	= 8,
	TAB			= 9,
	HOME		= 1752132965,
	END			= 6647396,
	INSERT		= 6909555,
	DELETE		= 6579564,
	PGUP		= 1885828464,
	PGDN		= 1885824110,
	RETURN		= 13,
	UP			= 30064,
	DOWN		= 1685026670,
	LEFT		= 1818584692,
	RIGHT		= 1919379572,
	
	F1			= 26161,
	F2			= 26162,
	F3			= 26163,
	F4			= 26164,
	F5			= 26165,
	F6			= 26166,
	F7			= 26167,
	F8			= 26168,
	F9			= 26169,
	F10			= 6697264,
	F11			= 6697265,
	F12			= 6697266

}


--[[	Font and color presets
	
	Can be set using the accompanying functions GUI.font
	and GUI.color. i.e.
	
	GUI.font(2)				applies the Header preset
	GUI.color("elm_fill")	applies the Element Fill color preset
	
	Colors are converted from 0-255 to 0-1 when GUI.Init() runs,
	so if you need to access the values directly at any point be
	aware of which format you're getting in return.
		
]]--
GUI.fonts = {
	
				-- Font, size, bold/italics/underline
				-- 				^ One string: "b", "iu", etc.
				{"Calibri", 32},	-- 1. Title
				{"Calibri", 20},	-- 2. Header
				{"Calibri", 16},	-- 3. Label
				{"Calibri", 16},	-- 4. Value
	version = 	{"Calibri", 12, "i"},
	
}


GUI.colors = {
	
	-- Element colors
	wnd_bg = {64, 64, 64, 255},			-- Window BG
	tab_bg = {56, 56, 56, 255},			-- Tabs BG
	elm_bg = {48, 48, 48, 255},			-- Element BG
	elm_frame = {96, 96, 96, 255},		-- Element Frame
	elm_fill = {64, 192, 64, 255},		-- Element Fill
	elm_outline = {32, 32, 32, 255},	-- Element Outline
	txt = {192, 192, 192, 255},			-- Text
	
	shadow = {0, 0, 0, 48},				-- Element Shadows
	faded = {0, 0, 0, 64},
	
	-- Standard 16 colors
	black = {0, 0, 0, 255},
	white = {255, 255, 255, 255},
	red = {255, 0, 0, 255},
	lime = {0, 255, 0, 255},
	blue =  {0, 0, 255, 255},
	yellow = {255, 255, 0, 255},
	cyan = {0, 255, 255, 255},
	magenta = {255, 0, 255, 255},
	silver = {192, 192, 192, 255},
	gray = {128, 128, 128, 255},
	maroon = {128, 0, 0, 255},
	olive = {128, 128, 0, 255},
	green = {0, 128, 0, 255},
	purple = {128, 0, 128, 255},
	teal = {0, 128, 128, 255},
	navy = {0, 0, 128, 255},
	
	none = {0, 0, 0, 0},
	

}


-- Global shadow size, in pixels
GUI.shadow_dist = 2


--[[
	How fast the caret in textboxes should blink, measured in GUI update loops.
	
	'16' looks like a fairly typical textbox caret.
	
	Because each On and Off redraws the textbox's Z layer, this can cause CPU 
    issues in scripts with lots of drawing to do. In that case, raising it to 
    24 or 32 will still look alright but require less redrawing.
]]--
GUI.txt_blink_rate = 16


-- Odds are you don't need too much precision here
-- If you do, just specify GUI.pi = math.pi() in your code
GUI.pi = 3.14159




------------------------------------
-------- Table functions -----------
------------------------------------


--[[	Copy the contents of one table to another, since Lua can't do it natively
	
	Provide a second table as 'base' to use it as the basis for copying, only
	bringing over keys from the source table that don't exist in the base
	
	'depth' only exists to provide indenting for my debug messages, it can
	be left out when calling the function.
]]--
GUI.table_copy = function (source, base, depth)
	
	-- 'Depth' is only for indenting debug messages
	depth = ((not not depth) and (depth + 1)) or 0
	
	
	
	if type(source) ~= "table" then return source end
	
	local meta = getmetatable(source)
	local new = base or {}
	for k, v in pairs(source) do
		

		
		if type(v) == "table" then
			
			if base then
				new[k] = GUI.table_copy(v, base[k], depth)
			else
				new[k] = GUI.table_copy(v, nil, depth)
			end
			
		else
			if not base or (base and new[k] == nil) then 

				new[k] = v
			end
		end
		
	end
	setmetatable(new, meta)
	
	return new
	
end


-- (For debugging)
-- Returns a string of the table's contents, indented to show nested tables
-- If 't' contains classes, or a lot of nested tables, etc, be wary of using larger
-- values for max_depth - this function will happily freeze Reaper for ten minutes.
GUI.table_list = function (t, max_depth, cur_depth)
    
    local ret = {}
    local n,v
    cur_depth = cur_depth or 0
    
    for n,v in pairs(t) do
                        
                ret[#ret+1] = string.rep("\t", cur_depth) .. n .. " = "
                
                if type(v) == "table" then
                    
                    ret[#ret] = ret[#ret] .. "table:"
                    if not max_depth or cur_depth <= max_depth then
                        ret[#ret+1] = GUI.table_list(v, max_depth, cur_depth + 1)
                    end
                
                else
                
                    ret[#ret] = ret[#ret] .. tostring(v)
                end

    end
    
    return table.concat(ret, "\n")
    
end


-- Compare the contents of one table to another, since Lua can't do it natively
-- Returns true if all of t_a's keys + and values match all of t_b's.
GUI.table_compare = function (t_a, t_b)
	
	if type(t_a) ~= "table" or type(t_b) ~= "table" then return false end
	
	local key_exists = {}
	for k1, v1 in pairs(t_a) do
		local v2 = t_b[k1]
		if v2 == nil or not GUI.table_compare(v1, v2) then return false end
		key_exists[k1] = true
	end
	for k2, v2 in pairs(t_b) do
		if not key_exists[k2] then return false end
	end
	
    return true
    
end


-- 	Sorting function adapted from: http://lua-users.org/wiki/SortedIteration
GUI.full_sort = function (op1, op2)

	-- Sort strings that begin with a number as if they were numbers,
	-- i.e. so that 12 > "6 apples"
	if type(op1) == "string" and string.match(op1, "^(%-?%d+)") then
		op1 = tonumber( string.match(op1, "^(%-?%d+)") )
	end
	if type(op2) == "string" and string.match(op2, "^(%-?%d+)") then
		op2 = tonumber( string.match(op2, "^(%-?%d+)") )
	end

	--if op1 == "0" then op1 = 0 end
	--if op2 == "0" then op2 = 0 end
	local type1, type2 = type(op1), type(op2)
	if type1 ~= type2 then --cmp by type
		return type1 < type2
	elseif type1 == "number" and type2 == "number"
		or type1 == "string" and type2 == "string" then
		return op1 < op2 --comp by default
	elseif type1 == "boolean" and type2 == "boolean" then
		return op1 == true
	else
		return tostring(op1) < tostring(op2) --cmp by address
	end
	
end


--[[	Allows "for x, y in pairs(z) do" in alphabetical/numerical order
    
	Copied from Programming In Lua, 19.3
	
	Call with f = "full" to use the full sorting function above, or
	use f to provide your own sorting function as per pairs() and ipairs()
	
]]--
GUI.kpairs = function (t, f)


	if f == "full" then
		f = GUI.full_sort
	end

	local a = {}
	for n in pairs(t) do table.insert(a, n) end

	table.sort(a, f)
	
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
	
		i = i + 1
		
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
		
	end
	
	
	return iter
end


-- Accepts a table, and returns a table with the keys and values swapped, i.e.
-- {a = 1, b = 2, c = 3} --> {1 = "a", 2 = "b", 3 = "c"}
GUI.table_invert = function(t)
    
    local tmp = {}
    
    for k, v in pairs(t) do
        tmp[v] = k
    end
    
    return tmp

end


-- Looks through a table using ipairs (specify a different function with 'f') and returns
-- the first key whose value matches 'find'. 'find' is checked using string.match, so patterns
-- should be allowable. No (captures) though.

-- If you need to find multiple values in the same table, and each of them only occurs once, 
-- it will be more efficient to just copy the table with GUI.table_invert and check by key.
GUI.table_find = function(t, find, f)      
    local iter = f or ipairs
    
    for k, v in iter(t) do
        if string.match(tostring(v), find) then return k end
    end
    
end

------------------------------------
-------- Text functions ------------
------------------------------------


--[[	Apply a font preset
	
	fnt			Font preset number
				or
				A preset table -> GUI.font({"Arial", 10, "i"})
	
]]--
GUI.font = function (fnt)
	
	local font, size, str = table.unpack( type(fnt) == "table" 
                                            and fnt 
                                            or  GUI.fonts[fnt])
	
	-- Different OSes use different font sizes, for some reason
	-- This should give a roughly equal size on Mac
	if string.find(reaper.GetOS(), "OSX") then
		size = math.floor(size * 0.7)
	end
	
	-- Cheers to Justin and Schwa for this
	local flags = 0
	if str then
		for i = 1, str:len() do 
			flags = flags * 256 + string.byte(str, i) 
		end 	
	end
	
	gfx.setfont(1, font, size, flags)

end


--[[	Prepares a table of character widths
	
	Iterates through all of the GUI.fonts[] presets, storing the widths
	of every printable ASCII character in a table. 
	
	Accessable via:		GUI.txt_width[font_num][char_num]
	
	- Requires a window to have been opened in Reaper
	
	- 'get_txt_width' and 'word_wrap' will automatically run this
	  if it hasn't been run already; it may be rather clunky to use
	  on demand depending on what your script is doing, so it's
	  probably better to run this immediately after initiliazing
	  the window and then have the width table ready to use.
]]--

GUI.init_txt_width = function ()

	GUI.txt_width = {}
	local arr
	for k in pairs(GUI.fonts) do
			
		GUI.font(k)
		GUI.txt_width[k] = {}
		arr = {}
		
		for i = 1, 255 do
			
			arr[i] = gfx.measurechar(i)
			
		end	
		
		GUI.txt_width[k] = arr
		
	end
	
end


-- Returns the total width (in pixels) for a given string and font
-- (as a GUI.fonts[] preset number or name)
-- Most of the time it's simpler to use gfx.measurestr(), but scripts 
-- with a lot of text should use this instead - it's 10-12x faster.
GUI.get_txt_width = function (str, font)
	
	if not GUI.txt_width then GUI.init_txt_width() end 

	local widths = GUI.txt_width[font]
	local w = 0
	for i = 1, string.len(str) do

		w = w + widths[		string.byte(	string.sub(str, i, i)	) ]

	end

	return w

end


-- Measures a string to see how much of it will it in the given width,
-- then returns both the trimmed string and the excess
GUI.fit_txt_width = function (str, font, w)
    
    local len = string.len(str)
    
    -- Assuming 'i' is the narrowest character, get an upper limit
    local max_end = math.floor( w / GUI.txt_width[font][string.byte("i")] )

    for i = max_end, 1, -1 do
       
        if GUI.get_txt_width( string.sub(str, 1, i), font ) < w then
           
           return string.sub(str, 1, i), string.sub(str, i + 1)
           
        end
        
    end
    
    -- Worst case: not even one character will fit
    -- If this actually happens you should probably rethink your choices in life.
    return "", str

end


--[[	Returns 'str' wrapped to fit a given pixel width
	
	str		String. Can include line breaks/paragraphs; they should be preserved.
	font	Font preset number
	w		Pixel width
	indent	Number of spaces to indent the first line of each paragraph
			(The algorithm skips tab characters and leading spaces, so
			use this parameter instead)
	
	i.e.	Blah blah blah blah		-> indent = 2 ->	  Blah blah blah blah
			blah blah blah blah							blah blah blah blah

	
	pad		Indent wrapped lines by the first __ characters of the paragraph
			(For use with bullet points, etc)
			
	i.e.	- Blah blah blah blah	-> pad = 2 ->	- Blah blah blah blah
			blah blah blah blah				  	 	  blah blah blah blah
	
				
	This function expands on the "greedy" algorithm found here:
	https://en.wikipedia.org/wiki/Line_wrap_and_word_wrap#Algorithm
				
]]--
GUI.word_wrap = function (str, font, w, indent, pad)
	
	if not GUI.txt_width then GUI.init_txt_width() end
	
	local ret_str = {}

	local w_left, w_word
	local space = GUI.txt_width[font][string.byte(" ")]
	
	local new_para = indent and string.rep(" ", indent) or 0
	
	local w_pad = pad   and GUI.get_txt_width( string.sub(str, 1, pad), font ) 
                        or 0
	local new_line = "\n"..string.rep(" ", math.floor(w_pad / space)	)
	
	
	for line in string.gmatch(str, "([^\n\r]*)[\n\r]*") do
		
		table.insert(ret_str, new_para)
		
		-- Check for leading spaces and tabs
		local leading, line = string.match(line, "^([%s\t]*)(.*)$")	
		if leading then table.insert(ret_str, leading) end
		
		w_left = w
		for word in string.gmatch(line,  "([^%s]+)") do
	
			w_word = GUI.get_txt_width(word, font)
			if (w_word + space) > w_left then
				
				table.insert(ret_str, new_line)
				w_left = w - w_word
				
			else
			
				w_left = w_left - (w_word + space)
				
			end
			
			table.insert(ret_str, word)
			table.insert(ret_str, " ")
			
		end
		
		table.insert(ret_str, "\n")
		
	end
	
	table.remove(ret_str, #ret_str)
	ret_str = table.concat(ret_str)
	
	return ret_str
			
end


-- Draw the given string of the first color with a shadow 
-- of the second color (at 45' to the bottom-right)
GUI.shadow = function (str, col1, col2)
	
	local x, y = gfx.x, gfx.y
	
	GUI.color(col2)
	for i = 1, GUI.shadow_dist do
		gfx.x, gfx.y = x + i, y + i
		gfx.drawstr(str)
	end
	
	GUI.color(col1)
	gfx.x, gfx.y = x, y
	gfx.drawstr(str)
	
end


-- Draws a string using the given text and outline color presets
GUI.outline = function (str, col1, col2)

	local x, y = gfx.x, gfx.y
	
	GUI.color(col2)
	
	gfx.x, gfx.y = x + 1, y + 1
	gfx.drawstr(str)
	gfx.x, gfx.y = x - 1, y + 1
	gfx.drawstr(str)
	gfx.x, gfx.y = x - 1, y - 1
	gfx.drawstr(str)
	gfx.x, gfx.y = x + 1, y - 1
	gfx.drawstr(str)
	
	GUI.color(col1)
	gfx.x, gfx.y = x, y
	gfx.drawstr(str)
	
end


--[[	Draw a background rectangle for the given string
	
	A solid background is necessary for blitting z layers
	on their own; antialiased text with a transparent background
	looks like complete shit. This function draws a rectangle 2px
	larger than your text on all sides.
	
	Call with your position, font, and color already set:
	
	gfx.x, gfx.y = self.x, self.y
	GUI.font(self.font)
	GUI.color(self.col)
	
	GUI.text_bg(self.text)
	
	gfx.drawstr(self.text)
	
	Also accepts an optional background color:
	GUI.text_bg(self.text, "elm_bg")
	
]]--
GUI.text_bg = function (str, col)
	
	local x, y = gfx.x, gfx.y
	local r, g, b, a = gfx.r, gfx.g, gfx.b, gfx.a
	
	col = col or "wnd_bg"
	
	GUI.color(col)
	
	local w, h = gfx.measurestr(str)
	w, h = w + 4, h + 4
		
	gfx.rect(gfx.x - 2, gfx.y - 2, w, h, true)
	
	gfx.x, gfx.y = x, y
	
	gfx.set(r, g, b, a)	
	
end




------------------------------------
-------- Color functions -----------
------------------------------------


--[[	Apply a color preset
	
	col			Color preset string -> "elm_fill"
				or
				Color table -> {1, 0.5, 0.5[, 1]}
								R  G    B  [  A]
]]--			
GUI.color = function (col)

	-- If we're given a table of color values, just pass it right along
	if type(col) == "table" then

		gfx.set(col[1], col[2], col[3], col[4] or 1)
	else
		gfx.set(table.unpack(GUI.colors[col]))
	end	

end


-- Convert a hex color RRGGBB to 8-bit values R, G, B
GUI.hex2rgb = function (num)
	
	if string.sub(num, 1, 2) == "0x" then
		num = string.sub(num, 3)
	end

	local red = string.sub(num, 1, 2)
	local green = string.sub(num, 3, 4)
	local blue = string.sub(num, 5, 6)

	
	red = tonumber(red, 16) or 0
	green = tonumber(green, 16) or 0
	blue = tonumber(blue, 16) or 0

	return red, green, blue
	
end


-- Convert rgb[a] to hsv[a]; useful for gradients
-- Arguments/returns are given as 0-1
GUI.rgb2hsv = function (r, g, b, a)
	
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local chroma = max - min
	
	-- Dividing by zero is never a good idea
	if chroma == 0 then
		return 0, 0, max, (a or 1)
	end
	
	local hue
	if max == r then
		hue = ((g - b) / chroma) % 6
	elseif max == g then
		hue = ((b - r) / chroma) + 2
	elseif max == b then
		hue = ((r - g) / chroma) + 4
	else
		hue = -1
	end
	
	if hue ~= -1 then hue = hue / 6 end
	
	local sat = (max ~= 0) 	and	((max - min) / max)
							or	0
							
	return hue, sat, max, (a or 1)
	
	
end


-- ...and back the other way
GUI.hsv2rgb = function (h, s, v, a)
	
	local chroma = v * s
	
	local hp = h * 6
	local x = chroma * (1 - math.abs(hp % 2 - 1))
	
	local r, g, b
	if hp <= 1 then
		r, g, b = chroma, x, 0
	elseif hp <= 2 then
		r, g, b = x, chroma, 0
	elseif hp <= 3 then
		r, g, b = 0, chroma, x
	elseif hp <= 4 then
		r, g, b = 0, x, chroma
	elseif hp <= 5 then
		r, g, b = x, 0, chroma
	elseif hp <= 6 then
		r, g, b = chroma, 0, x
	else
		r, g, b = 0, 0, 0
	end
	
	local min = v - chroma	
	
	return r + min, g + min, b + min, (a or 1)
	
end


--[[
	Returns the color for a given position on an HSV gradient 
	between two color presets

	col_a		Tables of {R, G, B[, A]}, values from 0-1
	col_b
	
	pos			Position along the gradient, 0 = col_a, 1 = col_b
	
	returns		r, g, b, a

]]--
GUI.gradient = function (col_a, col_b, pos)
	
	local col_a = {GUI.rgb2hsv( table.unpack( type(col_a) == "table" 
                                                and col_a 
                                                or  GUI.colors(col_a) )) }
	local col_b = {GUI.rgb2hsv( table.unpack( type(col_b) == "table" 
                                                and col_b 
                                                or  GUI.colors(col_b) )) }
	
	local h = math.abs(col_a[1] + (pos * (col_b[1] - col_a[1])))
	local s = math.abs(col_a[2] + (pos * (col_b[2] - col_a[2])))
	local v = math.abs(col_a[3] + (pos * (col_b[3] - col_a[3])))
    
	local a = (#col_a == 4) 
        and  (math.abs(col_a[4] + (pos * (col_b[4] - col_a[4])))) 
        or  1
	
	return GUI.hsv2rgb(h, s, v, a)
	
end




------------------------------------
-------- Math/trig functions -------
------------------------------------


-- Round a number to the nearest integer (or optional decimal places)
GUI.round = function (num, places)

	if not places then
		return num > 0 and math.floor(num + 0.5) or math.ceil(num - 0.5)
	else
		places = 10^places
		return num > 0 and math.floor(num * places + 0.5) 
                        or math.ceil(num * places - 0.5) / places
	end
	
end


-- Returns 'val', rounded to the nearest multiple of 'snap'
GUI.nearestmultiple = function (val, snap)
    
    local int, frac = math.modf(val / snap)
    return (math.floor( frac + 0.5 ) == 1 and int + 1 or int) * snap
    
end



-- Make sure num is between min and max
-- I think it will return the correct value regardless of what
-- order you provide the values in.
GUI.clamp = function (num, min, max)
        
	if min > max then min, max = max, min end
	return math.min(math.max(num, min), max)
    
end


-- Returns an ordinal string (i.e. 30 --> 30th)
GUI.ordinal = function (num)
	
	rem = num % 10
	num = GUI.round(num)
	if num == 1 then
		str = num.."st"
	elseif rem == 2 then
		str = num.."nd"
	elseif num == 13 then
		str = num.."th"
	elseif rem == 3 then
		str = num.."rd"
	else
		str = num.."th"
	end
	
	return str
	
end


--[[ 
	Takes an angle in radians (omit Pi) and a radius, returns x, y
	Will return coordinates relative to an origin of (0,0), or absolute
	coordinates if an origin point is specified
]]--
GUI.polar2cart = function (angle, radius, ox, oy)
	
	local angle = angle * GUI.pi
	local x = radius * math.cos(angle)
	local y = radius * math.sin(angle)

	
	if ox and oy then x, y = x + ox, y + oy end

	return x, y
	
end


--[[
	Takes cartesian coords, with optional origin coords, and returns
	an angle (in radians) and radius. The angle is given without reference
	to Pi; that is, pi/4 rads would return as simply 0.25
]]--
GUI.cart2polar = function (x, y, ox, oy)
	
	local dx, dy = x - (ox or 0), y - (oy or 0)
	
	local angle = math.atan(dy, dx) / GUI.pi
	local r = math.sqrt(dx * dx + dy * dy)

	return angle, r
	
end




------------------------------------
-------- Drawing functions ---------
------------------------------------


-- Improved roundrect() function with fill, adapted from mwe's EEL example.
GUI.roundrect = function (x, y, w, h, r, antialias, fill)
	
	local aa = antialias or 1
	fill = fill or 0
	
	if fill == 0 or false then
		gfx.roundrect(x, y, w, h, r, aa)
	else
	
		if h >= 2 * r then
			
			-- Corners
			gfx.circle(x + r, y + r, r, 1, aa)			-- top-left
			gfx.circle(x + w - r, y + r, r, 1, aa)		-- top-right
			gfx.circle(x + w - r, y + h - r, r , 1, aa)	-- bottom-right
			gfx.circle(x + r, y + h - r, r, 1, aa)		-- bottom-left
			
			-- Ends
			gfx.rect(x, y + r, r, h - r * 2)
			gfx.rect(x + w - r, y + r, r + 1, h - r * 2)
				
			-- Body + sides
			gfx.rect(x + r, y, w - r * 2, h + 1)
			
		else
		
			r = (h / 2 - 1)
		
			-- Ends
			gfx.circle(x + r, y + r, r, 1, aa)
			gfx.circle(x + w - r, y + r, r, 1, aa)
			
			-- Body
			gfx.rect(x + r, y, w - (r * 2), h)
			
		end	
		
	end
	
end


-- Improved triangle() function with optional non-fill
GUI.triangle = function (fill, ...)
	
	-- Pass any calls for a filled triangle on to the original function
	if fill then
		
		gfx.triangle(...)
		
	else
	
		-- Store all of the provided coordinates into an array
		local coords = {...}
		
		-- Duplicate the first pair at the end, so the last line will
		-- be drawn back to the starting point.
		table.insert(coords, coords[1])
		table.insert(coords, coords[2])
	
		-- Draw a line from each pair of coords to the next pair.
		for i = 1, #coords - 2, 2 do			
				
			gfx.line(coords[i], coords[i+1], coords[i+2], coords[i+3])
		
		end		
	
	end
	
end




------------------------------------
-------- Misc. functions -----------
------------------------------------


--[[	Use when working with file paths if you need to add your own /s
		(Borrowed from X-Raym)
        
        Apr. 22/18 - Further reading leads me to believe that simply using
        '/' as a separator should work just fine on Windows, Mac, and Linux.
]]--
GUI.file_sep = string.match(reaper.GetOS(), "Win") and "\\" or "/"


-- To open files in their default app, or URLs in a browser
-- Copied from Heda; cheers!
GUI.open_file = function (path)

	local OS = reaper.GetOS()
    
    if OS == "OSX32" or OS == "OSX64" then
		os.execute('open "" "' .. path .. '"')
	else
		os.execute('start "" "' .. path .. '"')
	end
  
end


-- Also might need to know this
GUI.SWS_exists = reaper.APIExists("CF_GetClipboardBig")


-- Why does Lua not have an operator for this?
GUI.xor = function(a, b)
   
   return (a or b) and not (a and b)
    
end


--[[
Returns x,y coordinates for a window with the specified anchor position

If no anchor is specified, it will default to the top-left corner of the screen.
	x,y		offset coordinates from the anchor position
	w,h		window dimensions
	anchor	"screen" or "mouse"
	corner	"TL"
			"T"
			"TR"
			"R"
			"BR"
			"B"
			"BL"
			"L"
			"C"
]]--
GUI.get_window_pos = function (x, y, w, h, anchor, corner)

	local ax, ay, aw, ah = 0, 0, 0 ,0
		
	local __, __, scr_w, scr_h = reaper.my_getViewport(x, y, x + w, y + h, 
                                                       x, y, x + w, y + h, 1)
	
	if anchor == "screen" then
		aw, ah = scr_w, scr_h
	elseif anchor =="mouse" then
		ax, ay = reaper.GetMousePosition()
	end
	
	local cx, cy = 0, 0
	if corner then
		local corners = {
			TL = 	{0, 				0},
			T =		{(aw - w) / 2, 		0},
			TR = 	{(aw - w) - 16,		0},
			R =		{(aw - w) - 16,		(ah - h) / 2},
			BR = 	{(aw - w) - 16,		(ah - h) - 40},
			B =		{(aw - w) / 2, 		(ah - h) - 40},
			BL = 	{0, 				(ah - h) - 40},
			L =	 	{0, 				(ah - h) / 2},
			C =	 	{(aw - w) / 2,		(ah - h) / 2},
		}
		
		cx, cy = table.unpack(corners[corner])
	end	
	
	x = x + ax + cx
	y = y + ay + cy
	
--[[
	
	Disabled until I can figure out the multi-monitor issue
	
	-- Make sure the window is entirely on-screen
	local l, t, r, b = x, y, x + w, y + h
	
	if l < 0 then x = 0 end
	if r > scr_w then x = (scr_w - w - 16) end
	if t < 0 then y = 0 end
	if b > scr_h then y = (scr_h - h - 40) end
]]--	
	
	return x, y	
	
end


-- Display the GUI version number
-- Set GUI.version = 0 to hide this
GUI.Draw_Version = function ()
	
	if not GUI.version then return 0 end

	local str = "Lokasenna_GUI "..GUI.version
	
	GUI.font("version")
	GUI.color("txt")
	
	local str_w, str_h = gfx.measurestr(str)
	
	--gfx.x = GUI.w - str_w - 4
	--gfx.y = GUI.h - str_h - 4
	gfx.x = gfx.w - str_w - 6
	gfx.y = gfx.h - str_h - 4
	
	gfx.drawstr(str)	
	
end




------------------------------------
-------- The End -------------------
------------------------------------


-- Make our table full of functions available to the parent script
return GUI

end
GUI = GUI_table()

----------------------------------------------------------------
----------------------------To here-----------------------------
----------------------------------------------------------------

---- End of file: F:/Github Repositories/Lokasenna_GUI/Core.lua ----



---- Beginning of file: F:/Github Repositories/Lokasenna_GUI/Classes/Class - Button.lua ----

--[[	Lokasenna_GUI - Button class 
	
	(Adapted from eugen2777's simple GUI template.)
	
	---- User parameters ----

	(name, z, x, y, w, h, caption, func[, ...])

Required:
z				Element depth, used for hiding and disabling layers. 1 is the highest.
x, y			Coordinates of top-left corner
w, h			Button size
caption			Label
func			Function to perform when clicked

                Note that you only need give a reference to the function:

                GUI.New("my_button", "Button", 1, 32, 32, 64, 32, "Button", my_func)

                Unless the function is returning a function (hey, Lua is weird), you don't 
                want to actually run it:

                GUI.New("my_button", "Button", 1, 32, 32, 64, 32, "Button", my_func())

Optional:
...				Any parameters to pass to that function, separated by commas as they
				would be if calling the function directly.


Additional:
r_func			Function to perform when right-clicked
r_params		If provided, any parameters to pass to that function
font			Button label's font
col_txt			Button label's color

col_fill		Button color. 
				*** If you change this, call :init() afterward ***


Extra methods:
exec			Force a button-click, i.e. for allowing buttons to have a hotkey:
					[Y]es	[N]o	[C]ancel
					
				Params:
				r			Boolean, optional. r = true will run the button's
							right-click action instead

]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end


-- Button - New
GUI.Button = GUI.Element:new()
function GUI.Button:new(name, z, x, y, w, h, caption, func, ...)

	local Button = {}
	
	Button.name = name
	Button.type = "Button"
	
	Button.z = z
	GUI.redraw_z[z] = true	
	
	Button.x, Button.y, Button.w, Button.h = x, y, w, h

	Button.caption = caption
	
	Button.font = 3
	Button.col_txt = "txt"
	Button.col_fill = "elm_frame"
	
	Button.func = func or function () end
	Button.params = {...}
	
	Button.state = 0

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


---- End of file: F:/Github Repositories/Lokasenna_GUI/Classes/Class - Button.lua ----



---- Beginning of file: F:/Github Repositories/Lokasenna_GUI/Classes/Class - Options.lua ----

--[[	Lokasenna_GUI - Options class
	
    This file provides two separate element classes:
    
    Radio       A list of options from which the user can only choose one at a time.
    Checklist   A list of options from which the user can choose any, all or none.
    
    Both classes take the same parameters on creation, and offer the same parameters
    afterward - their usage only differs when it comes to their respective :val methods.
    
    



	Adapted from eugen2777's simple GUI template.
	
	---- User parameters ----
	
	(name, z, x, y, w, h, caption, opts[, dir, pad])
	
Required:
z				Element depth, used for hiding and disabling layers. 1 is the highest.
x, y			Coordinates of top-left corner
caption			Element title. Feel free to just use a blank string: ""
opts			Accepts either a table* or a comma-separated string of options.

				Options can be separated by a gap in the list by using "_":
				
				opts = "Alice,Bob,Charlie,_,Edward,Francine"
				->
				Alice       1
				Bob         2
				Charlie     3
				
				Edward      5
				Francine    6

                * Must be indexed contiguously, starting from 1.

Optional:
dir				"h"		Options will extend to the right, with labels above them
				"v"		Options will extend downward, with labels to their right
pad				Separation in px between options. Defaults to 4.


Additional:
bg				Color to be drawn underneath the text. Defaults to "wnd_bg"
frame			Boolean. Draw a frame around the options.
size			Width of the unfilled options in px. Defaults to 20.
				* Changing this might mess up the spacing *
col_txt			Text color
col_fill		Filled option color
font_a			List title font
font_b			List option font
shadow			Boolean. Draw a shadow under the text? Defaults to true.
swap			If dir = "h", draws the option labels below them rather than above
						 "v", shifts the options over and draws the option labels 
                              to the left rather than the right.


Extra methods:


    Radio

GUI.Val()		Returns the current option, numbered from 1.
GUI.Val(new)	Sets the current option, numbered from 1.


    Checklist
    
GUI.Val()		Returns a table of boolean values for each option. Indexed from 1.
GUI.Val(new)	Accepts a table of boolean values for each option. Indexed from 1.

]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end


local Option = GUI.Element:new()

function Option:new(name, z, x, y, w, h, caption, opts, dir, pad)
    
	local option = {}
	
	option.name = name
	option.type = "Option"
	
	option.z = z
	GUI.redraw_z[z] = true	
	
	option.x, option.y, option.w, option.h = x, y, w, h

	option.caption = caption

	option.frame = true
	option.bg = "wnd_bg"
    
	option.dir = dir or "v"
	option.pad = pad or 4
        
	option.col_txt = "txt"
	option.col_fill = "elm_fill"

	option.font_a = 2
	option.font_b = 3
	
	option.shadow = true
	
    option.swap = false
    
	-- Size of the option bubbles
	option.opt_size = 20
	
	-- Parse the string of options into a table
	option.optarray = {}
    
    if type(opts) == "table" then
        
        for i = 1, #opts do
            option.optarray[i] = opts[i]
        end
        
    else
    
        local tempidx = 1
        for word in string.gmatch(opts, '([^,]*)') do
            option.optarray[tempidx] = word
            tempidx = tempidx + 1
        end
        
    end

	setmetatable(option, self)
    self.__index = self 
    return option
    
end


function Option:init()
	
    -- Make sure we're not trying to use the base class.
    if self.type == "Option" then
        reaper.ShowMessageBox(  "'"..self.name.."' was initialized as an Option element,"..
                                "but Option doesn't do anything on its own!",
                                "GUI Error", 0)
        
        GUI.quit = true
        return
        
    end
        
	self.buff = self.buff or GUI.GetBuffer()
		
	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)
	gfx.setimgdim(self.buff, 2*self.opt_size + 4, 2*self.opt_size + 2)
	
    
    self:initoptions()
	
    
	if self.caption and self.caption ~= "" then
		GUI.font(self.font_a)		
		local str_w, str_h = gfx.measurestr(self.caption)
		self.cap_h = 0.5*str_h
		self.cap_x = self.x + (self.w - str_w) / 2	
	else
		self.cap_h = 0
		self.cap_x = 0
	end
	
end


function Option:draw()
	
	if self.frame then
		GUI.color("elm_frame")
		gfx.rect(self.x, self.y, self.w, self.h, 0)
	end

    if self.caption and self.caption ~= "" then self:drawcaption() end

    self:drawoptions()

end




------------------------------------
-------- Input helpers -------------
------------------------------------




function Option:getmouseopt()
    
    local len = #self.optarray
    
	-- See which option it's on
	local mouseopt = self.dir == "h" 	
                    and (GUI.mouse.x - (self.x + self.pad))
					or	(GUI.mouse.y - (self.y + self.cap_h + 1.5*self.pad) )
                    
	mouseopt = mouseopt / ((self.opt_size + self.pad) * len)
	mouseopt = GUI.clamp( math.floor(mouseopt * len) + 1 , 1, len )

    return self.optarray[mouseopt] ~= "_" and mouseopt or false
    
end


------------------------------------
-------- Drawing methods -----------
------------------------------------


function Option:drawcaption()
    
    GUI.font(self.font_a)
    
    gfx.x = self.cap_x
    gfx.y = self.y - self.cap_h
    
    GUI.text_bg(self.caption, self.bg)
    
    GUI.shadow(self.caption, self.col_txt, "shadow")
    
end


function Option:drawoptions()

    local x, y, w, h = self.x, self.y, self.w, self.h
    
    local horz = self.dir == "h"
	local pad = self.pad
    
    -- Bump everything down for the caption
    y = y + ((self.caption and self.caption ~= "") and self.cap_h or 0) + 1.5 * pad 

    -- Bump the options down more for horizontal options
    -- with the text on top
	if horz and self.caption ~= "" and not self.swap then
        y = y + self.cap_h + 2*pad 
    end

	local opt_size = self.opt_size
    
    local adj = opt_size + pad

    local str, opt_x, opt_y

	for i = 1, #self.optarray do
	
		str = self.optarray[i]
		if str ~= "_" then
		        
            opt_x = x + (horz   and (i - 1) * adj + pad
                                or  (self.swap  and (w - adj - 1) 
                                                or   pad))
                                                
            opt_y = y + (i - 1) * (horz and 0 or adj)
                
			-- Draw the option bubble
            self:drawoption(opt_x, opt_y, opt_size, self:isoptselected(i))

            self:drawvalue(opt_x,opt_y, opt_size, str)
            
		end
		
	end
	
end


function Option:drawoption(opt_x, opt_y, size, selected)
    
    gfx.blit(   self.buff, 1,  0,  
                selected and (size + 3) or 1, 1, 
                size + 1, size + 1, 
                opt_x, opt_y)

end


function Option:drawvalue(opt_x, opt_y, size, str)

    if not str or str == "" then return end
    
	GUI.font(self.font_b) 
    
    local str_w, str_h = gfx.measurestr(str)
    
    if self.dir == "h" then
        
        gfx.x = opt_x + (size - str_w) / 2
        gfx.y = opt_y + (self.swap and (size + 4) or -size)

    else
    
        gfx.x = opt_x + (self.swap and -(str_w + 8) or 1.5*size)
        gfx.y = opt_y + (size - str_h) / 2
        
    end

    GUI.text_bg(str, self.bg)
    if #self.optarray == 1 or self.shadow then
        GUI.shadow(str, self.col_txt, "shadow")
    else
        GUI.color(self.col_txt)
        gfx.drawstr(str)
    end

end




------------------------------------
-------- Radio methods -------------
------------------------------------


GUI.Radio = {}
setmetatable(GUI.Radio, {__index = Option})

function GUI.Radio:new(name, z, x, y, w, h, caption, opts, dir, pad)

    local radio = Option:new(name, z, x, y, w, h, caption, opts, dir, pad)
    
    radio.type = "Radio"
    
    radio.retval, radio.state = 1, 1
    
    setmetatable(radio, self)
    self.__index = self
    return radio
    
end


function GUI.Radio:initoptions()

	local r = self.opt_size / 2

	-- Option bubble
	GUI.color(self.bg)
	gfx.circle(r + 1, r + 1, r + 2, 1, 0)
	gfx.circle(3*r + 3, r + 1, r + 2, 1, 0)
	GUI.color("elm_frame")
	gfx.circle(r + 1, r + 1, r, 0)
	gfx.circle(3*r + 3, r + 1, r, 0)
	GUI.color(self.col_fill)
	gfx.circle(3*r + 3, r + 1, 0.5*r, 1)


end


function GUI.Radio:val(newval)
	
	if newval then
		self.retval = newval
		self.state = newval
		self:redraw()		
	else
		return self.retval
	end	
	
end


function GUI.Radio:onmousedown()
	
	self.state = self:getmouseopt() or self.state

	self:redraw()

end


function GUI.Radio:onmouseup()
	
    -- Bypass option for GUI Builder
    if not self.focus then
        self:redraw()
        return
    end
	
	-- Set the new option, or revert to the original if the cursor 
    -- isn't inside the list anymore
	if GUI.IsInside(self, GUI.mouse.x, GUI.mouse.y) then
		self.retval = self.state
	else
		self.state = self.retval	
	end

    self.focus = false
	self:redraw()

end


function GUI.Radio:ondrag() 

	self:onmousedown()

	self:redraw()

end


function GUI.Radio:onwheel()
--[[
	state = GUI.round(self.state +     (self.dir == "h" and 1 or -1) 
                                    *   GUI.mouse.inc)
]]--                             

    self.state = self:getnextoption(    GUI.xor( GUI.mouse.inc > 0, self.dir == "h" ) 
                                        and -1 
                                        or 1 )

	--if self.state < 1 then self.state = 1 end
	--if self.state > #self.optarray then self.state = #self.optarray end

	self.retval = self.state

	self:redraw()

end


function GUI.Radio:isoptselected(opt)
    
   return opt == self.state 
    
end


function GUI.Radio:getnextoption(dir)
   
    local j = dir > 0 and #self.optarray or 1
   
    for i = self.state + dir, j, dir do
       
        if self.optarray[i] ~= "_" then
            return i
        end
       
    end
    
    return self.state
    
end




------------------------------------
-------- Checklist methods ---------
------------------------------------


GUI.Checklist = {}
setmetatable(GUI.Checklist, {__index = Option})

function GUI.Checklist:new(name, z, x, y, w, h, caption, opts, dir, pad)

    local checklist = Option:new(name, z, x, y, w, h, caption, opts, dir, pad)
    
    checklist.type = "Checklist"
    
    checklist.optsel = {}
    
    setmetatable(checklist, self)
    self.__index = self
    return checklist
    
end


function GUI.Checklist:initoptions()

	local size = self.opt_size

	-- Option bubble
	GUI.color("elm_frame")
	gfx.rect(1, 1, size, size, 0)
    gfx.rect(size + 3, 1, size, size, 0)
	
	GUI.color(self.col_fill)
	gfx.rect(size + 3 + 0.25*size, 1 + 0.25*size, 0.5*size, 0.5*size, 1)

end


function GUI.Checklist:val(newval)
      
	if newval then
		if type(newval) == "table" then
			for k, v in pairs(newval) do
				self.optsel[tonumber(k)] = v
			end
			self:redraw()
        elseif type(newval) == "boolean" and #self.optarray == 1 then
        
            self.optsel[1] = newval
            self:redraw()
		end
	else
        if #self.optarray == 1 then
            return self.optsel[1]
        else
            local tmp = {}
            for i = 1, #self.optarray do
                tmp[i] = not not self.optsel[i]
            end
            return tmp            
        end
		--return #self.optarray > 1 and self.optsel or self.optsel[1]
	end
	
end


function GUI.Checklist:onmouseup()
    
    -- Bypass option for GUI Builder
    if not self.focus then
        self:redraw()
        return
    end

    local mouseopt = self:getmouseopt()
	
    if not mouseopt then return end
    
	self.optsel[mouseopt] = not self.optsel[mouseopt] 

    self.focus = false
	self:redraw()

end


function GUI.Checklist:isoptselected(opt)
   
   return self.optsel[opt]
    
end

---- End of file: F:/Github Repositories/Lokasenna_GUI/Classes/Class - Options.lua ----



---- Beginning of file: F:/Github Repositories/Lokasenna_GUI/Classes/Class - Label.lua ----

--[[	Lokasenna_GUI - Label class.

	---- User parameters ----
	
	(name, z, x, y, caption[, shadow, font, color, bg])
	
Required:
z				Element depth, used for hiding and disabling layers. 1 is the highest.
x, y			Coordinates of top-left corner
caption			Label text

Optional:
shadow			Boolean. Draw a shadow?
font			Which of the GUI's font values to use
color			Use one of the GUI.colors keys to override the standard text color
bg				Color to be drawn underneath the label. Defaults to "wnd_bg"

Additional:
w, h			These are set when the Label is initially drawn, and updated any
				time the label's text is changed via GUI.Val().

Extra methods:
fade			Allows a label to fade out and disappear. Nice for briefly displaying
				a status message like "Saved to disk..."

				Params:
				len			Length of the fade, in seconds
				z_new		z layer to move the label to when called
							i.e. popping up a tooltip
				z_end		z layer to move the label to when finished
							i.e. putting the tooltip label back in a
							frozen layer until you need it again
							
							Set to -1 to have the label deleted instead
				
				curve		Optional. Sets the "shape" of the fade.
							
							1 	will produce a linear fade
							>1	will keep the text at full-strength longer,
								but with a sharper fade at the end
							<1	will drop off very steeply
                            
							Defaults to 3 if not specified                            
                            
                            Use negative values to fade in on z_new, rather
                            than fading out. In this case, the value of
                            z_end doesn't matter.
							

							
				Note: While fading, the label's z layer will be redrawn on every
				update loop, which may affect CPU usage for scripts with many elements.
                
                If this is the case, try to put the label on a layer with as few
                other elements as possible.
							  
]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end


-- Label - New
GUI.Label = GUI.Element:new()
function GUI.Label:new(name, z, x, y, caption, shadow, font, color, bg)
	
	local label = {}	
	
	label.name = name
	
	label.type = "Label"
	
	label.z = z
	GUI.redraw_z[z] = true

	label.x, label.y = x, y
	
    -- Placeholders; we'll get these at runtime
	label.w, label.h = 0, 0
	
	label.caption = caption
	
	label.shadow = shadow or false
	label.font = font or 2
    
    label.flags = nil
    label.right, label.bottom = nil, nil
	
	label.color = color or "txt"
	label.bg = bg or "wnd_bg"
	
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

---- End of file: F:/Github Repositories/Lokasenna_GUI/Classes/Class - Label.lua ----



---- Beginning of file: F:/Github Repositories/Lokasenna_GUI/Classes/Class - Frame.lua ----

--[[	Lokasenna_GUI - Frame class
	
	---- User parameters ----

	(name, z, x, y, w, h[, shadow, fill, color, round])

Required:
z				Element depth, used for hiding and disabling layers. 1 is the highest.
x, y			Coordinates of top-left corner
w, h			Frame size

Optional:
shadow			Boolean. Draw a shadow beneath the frame?	Defaults to False.
fill			Boolean. Fill in the frame?	Defaults to False.
color			Frame (and fill) color.	Defaults to "elm_frame".
round			Radius of the frame's corners. Defaults to 0.

Additional:
text			Text to be written inside the frame. Will automatically be wrapped
				to fit self.w - 2*self.pad.
txt_indent		Number of spaces to indent the first line of each paragraph
txt_pad			Number of spaces to indent wrapped lines (to match up with bullet
				points, etc)
pad				Padding between the frame's edges and text. Defaults to 0.				
bg				Color to be drawn underneath the text. Defaults to "wnd_bg",
				but will use the frame's fill color instead if Fill = True
font			Text font. Defaults to preset 4.
col_txt			Text color. Defaults to "txt".


Extra methods:


GUI.Val()		Returns the frame's text.
GUI.Val(new)	Sets the frame's text and formats it to fit within the frame, as above.

	
	
]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end



GUI.Frame = GUI.Element:new()
function GUI.Frame:new(name, z, x, y, w, h, shadow, fill, color, round)
	
	local Frame = {}
	Frame.name = name
	Frame.type = "Frame"
	
	Frame.z = z
	GUI.redraw_z[z] = true	
	
	Frame.x, Frame.y, Frame.w, Frame.h = x, y, w, h
	
	Frame.shadow = shadow or false
	Frame.fill = fill or false
	Frame.color = color or "elm_frame"
	Frame.round = round or 0
	
	Frame.text, Frame.last_text = "", ""
	Frame.txt_indent = 0
	Frame.txt_pad = 0
    
	Frame.bg = "wnd_bg"
    
	Frame.font = 4
	Frame.col_txt = "txt"
	Frame.pad = 4
	
	
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

	if new then
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

---- End of file: F:/Github Repositories/Lokasenna_GUI/Classes/Class - Frame.lua ----



---- Beginning of file: F:/Github Repositories/Lokasenna_GUI/Classes/Class - Knob.lua ----

--[[	Lokasenna_GUI - Knob class.

	---- User parameters ----
	
	(name, z, x, y, w, caption, min, max, default,[ inc, vals])
	
Required:	
z				Element depth, used for hiding and disabling layers. 1 is the highest.	
x, y, w			Coordinates of top-left corner, width. Height is fixed.
caption			Label / question
min, max		Minimum and maximum values
default			Default step for the knob. Steps are counted from min to max starting at 0.


Optional:
inc             Amount to increment the value per step. Defaults to 1.

vals			Boolean, defaults to True. Display value labels?
				For knobs with a lot of steps, i.e. Pan from -100 to +100, set this
				to false and use a label to read the value, update the Knob's caption


                Example:
                
                    A knob from 0 to 11, defaulting to 11, with a step size of 0.25:
                    
                        min     = 0
                        max     = 11
                        default = 44
                        inc     = 0.25



Additional:
bg				Color to be drawn underneath the label. Defaults to "wnd_bg"
font_a          Caption font
font_b          Value font
col_txt         Text color
col_head        Knob head color
col_body        Knob body color
cap_x, cap_y    Offset values for the knob's caption.
output			Allows the value labels to be modified; accepts several different var types:
				
				string		Replaces all of the value labels
				number
				table		Replaces each value label with output[step], with the steps
							being numbered as above
				functions	Replaces each value with the returned value from
							output(step), numbered as above
							
				Output will always count steps starting from 0, so you'll have to account for minimum
				values in the final string yourself.
	
	
Extra methods:

GUI.Val()		Returns the current display value of the knob. i.e. 
				
					For a Pan knob, -100 to +100, with 201 steps,
					GUI.Val("my_knob") will return an integer from -100 to +100
					
GUI.Val(new)	Sets the display value of the knob, as above.				
	
]]--

if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end

-- Knob - New.
GUI.Knob = GUI.Element:new()
function GUI.Knob:new(name, z, x, y, w, caption, min, max, default, inc, vals)
	
	local Knob = {}
	
	Knob.name = name
	Knob.type = "Knob"
	
	Knob.z = z
	GUI.redraw_z[z] = true	
	
	Knob.x, Knob.y, Knob.w, Knob.h = x, y, w, w

	Knob.caption = caption
	Knob.bg = "wnd_bg"
    
    Knob.cap_x, Knob.cap_y = 0, 0
	
	Knob.font_a = 3
	Knob.font_b = 4
	
	Knob.col_txt = "txt"
	Knob.col_head = "elm_fill"
	Knob.col_body = "elm_frame"
    
	Knob.min, Knob.max = min, max
    Knob.inc = inc or 1
    Knob.steps = math.abs(max - min) / Knob.inc
    
    function Knob:formatretval(val)
        
        local decimal = tonumber(string.match(val, "%.(.*)") or 0)
        local places = decimal ~= 0 and string.len( decimal) or 0
        return string.format("%." .. places .. "f", val)
        
    end    
	
	Knob.vals = vals
	
	-- Determine the step angle
	Knob.stepangle = (3 / 2) / Knob.steps
	
	Knob.default, Knob.curstep = default, default
    
	Knob.curval = Knob.curstep / Knob.steps    
	
    Knob.retval = Knob:formatretval(
                ((max - min) / Knob.steps) * Knob.curstep + min
                                    )


	
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

---- End of file: F:/Github Repositories/Lokasenna_GUI/Classes/Class - Knob.lua ----

---- End of libraries ----


if missing_lib then return 0 end


local script_name = "Lokasenna_Copy values from selected MIDI notes"
local copied_notes = {}




------------------------------------
-------- Misc. functions -----------
------------------------------------


local function show_warning(show)
    
    GUI.elms.frm_nope.z = show and 2 or 5
    GUI.elms.lbl_nope.z = show and 1 or 5
    GUI.redraw_z[1] = true    
    
end




------------------------------------
-------- Ext States ----------------
------------------------------------


local function get_ext_vals()
    
    local vals = {}
    local str = reaper.GetExtState(script_name, "Options")
    for k in string.gmatch(str, "%d+") do
        vals[tonumber(k)] = true
    end
    GUI.Val("chk_vals", vals)
    
    str = reaper.GetExtState(script_name, "Strengths")
    local pos, vel = string.match(str, "(.+),(.+)")
    if pos then GUI.Val("knb_pos_strength", pos) end
    if vel then GUI.Val("knb_vel_strength", vel) end
        
    
    local wnd = reaper.GetExtState(script_name, "Window")
    local x, y = string.match(wnd, "(.+),(.+)")
    if x and y then
        GUI.x, GUI.y = tonumber(x), tonumber(y)
        GUI.anchor, GUI.corner = "screen", nil
    end
    
end


local function set_ext_vals()
    
    local vals = {}
    for k, v in pairs(GUI.elms.chk_vals.optsel) do
        if v then vals[#vals+1] = k end
    end
    --reaper.SetExtState( section, key, value, persist )
    reaper.SetExtState(script_name, "Options", table.concat(vals, ","), true)
    reaper.SetExtState(script_name, "Strengths", 
                        GUI.elms.knb_pos_strength.retval .. "," .. GUI.elms.knb_vel_strength.retval,
                        true)
    
    local __,x,y,w,h = gfx.dock(-1,0,0,0,0)
    reaper.SetExtState(script_name, "Window", x .. "," .. y, true)
    
end




------------------------------------
-------- Get + Set code ------------
------------------------------------


local function btn_get()
       
    local take = get_MIDI_take()
    if not take then return end

    copied_notes = {}

    local idx = -2
    while idx ~= -1 do
        
        idx = reaper.MIDI_EnumSelNotes(take, idx)

        if idx == -1 then break end		

        copied_notes[#copied_notes+1] = {reaper.MIDI_GetNote(take, idx)}

    end
    
    if #copied_notes == 0 then
        if not startup then reaper.MB("No selected notes found.", "Whoops!", 0) end
        show_warning(true)
        return
    end
    
    local track = reaper.GetMediaItemTake_Track(take)
    local _, track_name = reaper.GetTrackName(track, "")
    local item_name = reaper.GetTakeName(take)
    GUI.Val("lbl_got", "Got " .. #copied_notes .. " notes from " .. tostring(track_name) .. ", " .. tostring(item_name))

    show_warning(false)
    
end


local function btn_set()

    local take = get_MIDI_take()
    if not take then return end

    reaper.Undo_BeginBlock()

    local i = 0
    local idx = -2
    while idx ~= -1 do
        
        idx = reaper.MIDI_EnumSelNotes(take, idx)
        
        if idx == -1 or i == #copied_notes then break end
        i = i + 1

        local note = {reaper.MIDI_GetNote(take, idx)}
        local copy = copied_notes[i]
        
        note = apply_values(note, copy)
        
        reaper.MIDI_SetNote( take, idx, note[2], note[3], note[4], note[5], note[6], note[7], note[8], true)

        ::next::

    end
    
    if i == 0 then
        reaper.MB("No selected notes found.", "Whoops!", 0)
        return
    elseif i < #copied_notes then
        --reaper.MB("Could only copy " .. count .. " notes out of " .. #copied_notes ..".", "", 0)
    end
    
    reaper.MIDI_Sort( take )    
   
    reaper.Undo_EndBlock("Copy values from selected MIDI notes", 0)
    
end


-- Global --> btn_set, btn_get
function get_MIDI_take()
    
    -- Get editor, pop up MB if no editor, etc, etc
    local hwnd = reaper.MIDIEditor_GetActive()
    if hwnd then
        
        return reaper.MIDIEditor_GetTake( hwnd )        
    
    else
    
        local item = reaper.GetSelectedMediaItem(0, 0)
        if item then
            local take = reaper.GetActiveTake(item)
            if reaper.BR_IsMidiOpenInInlineEditor(take) then 
                return take 
            else
                
            end            
        end

    end
   
    if not startup then 
        reaper.MB("This script needs an open MIDI editor, or a selected item with the inline MIDI editor open.", "Whoops!", 0)
    end
    show_warning(true)   
    return nil
    
end


-- Global --> btn_set
function apply_values(note, copy)
      
    --[[
        note[1] = retval        boolean
        [2] = selected      boolean
        [3] = muted         boolean
        [4] = startppqpos   number
        [5] = endppqpos     number 
        [6] = chan          number 
        [7] = pitch         number 
        [8] = velocity      number 
    ]]--
    
    -- Read the values out with the indices offset to match GetNote/SetNote
    local opts = {}
    for k, v in pairs( GUI.Val("chk_vals") ) do
        opts[k + 2] = v
    end
        
    local pos_strength = GUI.Val("knb_pos_strength") / 100
    local vel_strength = GUI.Val("knb_vel_strength") / 100    
    
    
    note[3] = opts[3] and copy[3] or note[3]

    -- Just Start
    if opts[4] and not opts[5] then
        
        local len = note[5] - note[4]
        note[4] = note[4] + (copy[4] - note[4]) * pos_strength
        note[5] = note[4] + len

    -- Just Length
    elseif opts[5] and not opts[4] then

        local len_note = note[5] - note[4]
        local len_copy = copy[5] - copy[4]
        local len = len_note + (len_copy - len_note) * pos_strength
        note[5] = note[4] + len
        
    -- Start and Length
    elseif opts[4] and opts[5] then
    
        local len_note = note[5] - note[4]
        local len_copy = copy[5] - copy[4]
        local len = len_note + (len_copy - len_note) * pos_strength
     
        note[4] = note[4] + (copy[4] - note[4]) * pos_strength
        note[5] = note[4] + len
    
    end
    
    note[6] = opts[6] and copy[6] or note[6]
    note[7] = opts[7] and copy[7] or note[7]
    note[8] = opts[8] and GUI.round((note[8] + (copy[8] - note[8]) * vel_strength))
                      or  note[8]
    
    return note
    
end



------------------------------------
-------- GUI Stuff -----------------
------------------------------------


GUI.name = "Copy values from selected MIDI notes"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 320, 340
GUI.anchor, GUI.corner = "mouse", "C"


GUI.New("btn_get", "Button", 3, 120, 16, 80, 24, "Copy values", btn_get)
GUI.New("btn_set", "Button", 3, 120, 288, 80, 24, "Apply values", btn_set)

GUI.New("lbl_got", "Label", 3, 16, 52, "", true, 4)

GUI.New("chk_vals", "Checklist", 4, 48, 88, 224, 184, 
        "Values to apply:", "Mute,Position,Length,Channel,Pitch,Velocity", "v")

GUI.New("knb_pos_strength", "Knob", 3, 208, 136, 24, "Strength", 0, 100, 100, 1, false)
GUI.New("knb_vel_strength", "Knob", 3, 208, 192, 24, "Strength", 0, 100, 100, 1, false)

GUI.New("frm_nope", "Frame", 2, 0, 48, 400, 308, true, true, "wnd_bg", 0)
GUI.New("lbl_nope", "Label", 1, 88, 96, "No notes copied", true, 2)

GUI.elms_hide[5] = true


local pos_x1, pos_x2, pos_x3, pos_y1, pos_y2, pos_y3
local vel_y1
function GUI.elms.chk_vals:init()
    
    GUI.Checklist.init(self)
    
    pos_x1 = self.x + self.pad + self.opt_size
    pos_x2 = pos_x1 + 80
    pos_x3 = GUI.elms.knb_pos_strength.x + 8
    pos_y1 = self.y + self.cap_h + 2.5*self.pad + 1.5*self.opt_size 
    pos_y2 = pos_y1 + self.opt_size + self.pad
    pos_y3 = pos_y1 + (pos_y2 - pos_y1) / 2
    
    vel_y1 = self.y + self.cap_h + 6.5*self.pad + 5.5*self.opt_size
    
    GUI.elms.knb_pos_strength.y = pos_y3 - (GUI.elms.knb_pos_strength.h / 2)
    GUI.elms.knb_vel_strength.y = vel_y1 - (GUI.elms.knb_vel_strength.h / 2)
    
end


function GUI.elms.chk_vals:draw()
       
    GUI.color("elm_frame")
    gfx.line(pos_x1, pos_y1, pos_x2, pos_y1)
    gfx.line(pos_x1, pos_y2, pos_x2, pos_y2)
    gfx.line(pos_x2, pos_y1, pos_x2, pos_y2)
    gfx.line(pos_x2, pos_y3, pos_x3, pos_y3)
    
    gfx.line(pos_x1, vel_y1, pos_x3, vel_y1)

    GUI.Checklist.draw(self)
    
end


GUI.elms.knb_pos_strength.cap_y = -8
function GUI.elms.knb_pos_strength:draw()
    
    self.caption = "Strength: " .. self.retval .. "%"
    GUI.Knob.draw(self)

end

GUI.elms.knb_vel_strength.cap_y = -8
function GUI.elms.knb_vel_strength:draw()
    
    self.caption = "Strength: " .. self.retval .. "%"
    GUI.Knob.draw(self)
    
end


function GUI.elms.lbl_nope:init()

    GUI.font(self.font)
    local str_w, str_h = gfx.measurestr(self.caption)
    self.x = (GUI.w - str_w) / 2

    GUI.Label.init(self)

end


function GUI.elms.lbl_got:init()

    GUI.font(self.font)
    local str_w, str_h = gfx.measurestr(self.caption)
    self.x = (GUI.w - str_w) / 2

    GUI.Label.init(self)

end




------------------------------------
-------- Startup stuff -------------
------------------------------------


startup = true

-- Look for selected notes on startup.
btn_get()

startup = false

get_ext_vals()

GUI.exit = set_ext_vals

local function check_undo()
    
    -- Ctrl
    if GUI.mouse.cap & 4 == 4 and GUI.char == 26 then
        
        reaper.Undo_DoUndo2(-1)
        
    end  
    
end
GUI.func = check_undo
GUI.freq = 0

GUI.Init()
GUI.Main()

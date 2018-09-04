-- NoIndex: true
--[[	Lokasenna_GUI - GetUserInputs window
	
    This module emulates the native reaper.GetUserInputs() dialog, offering a dialog that matches
    the GUI theme, input and output values in tables rather than CSVs, and a function hook for
    getting the returned values into your script.

    Note: The Window, Textbox, and Button classes must be loaded before loading this module.
    
    Parameters:
    GUI.GetUserInputs(title, captions, defaults, ret_func, extra_width)

    title           String. Window title.
    captions        Indexed table. Captions for the textboxes.
    defaults        Indexed table. Default values for the textboxes.
    ret_func        Function to run when the window is closed. Values returned from the module are
                    passed to it as an indexed table - see the example below and the example script.

    extra_width     Number. Additional width for the textboxes.

    Example:

        local function return_values(vals)
            
            if not vals then vals = {"cancelled"} end
            reaper.MB("Returned values:\n\n" .. table.concat(vals, "\n"), "Returned:", 0)
            
        end

        GUI.GetUserInputs("title", {1,2,3}, {"a","b","c"}, return_values)

]]--

if not (GUI and GUI.Window and GUI.Textbox and GUI.Button) then
	reaper.ShowMessageBox(  "Couldn't access some functions.\n\nUserInputs requires the Lokasenna_GUI "..
                            "Core script and the Window, Textbox, and Button classes.", 
                            "Library Error", 0)
	missing_lib = true
	return 0
end


local ref_txt = {x = 128, y = 16, w = 128, h = 20, off = 24}


local function check_window_size(w, h)
    
		-- If the window's size has been changed, reopen it
		-- at the current position with the size we specified
		local dock,wnd_x,wnd_y,wnd_w,wnd_h = gfx.dock(-1,0,0,0,0)
        
        if wnd_w < w or wnd_h < h then
            return {dock, wnd_x, wnd_y, wnd_w, wnd_h}
        end
        
end


local function resize_window(dock, x, y, w, h)

    gfx.quit()
    gfx.init(GUI.name, w + 32, h + 32, dock, x, y)
    GUI.redraw_z[0] = true
    GUI.cur_w, GUI.cur_h = w, h
    
end


local function return_values(apply, func)
    
    if apply then
        
        local vals = {}
        for i = 1, GUI.elms.UserInputs_wnd.num_inputs do
            vals[i] = GUI.Val("UserInputs_txt_" .. i)
        end
        func(vals)
        
    else
    
        func(nil)
        
    end    
    
end


local function clear_UserInputs()
    
    -- Return the buffers we borrowed for our z_set
    GUI.FreeBuffer(GUI.elms.UserInputs_wnd.z_set)
    
    -- Delete any elms with "UserInput" in their name
    for k in pairs(GUI.elms) do
        if string.match(k, "UserInput") then
            GUI.elms[k]:delete()
        end
    end
    
end


local function wnd_open(self)

    self:adjustchildelms()
    
    -- Place the OK/Cancel buttons appropriately
    GUI.elms.UserInputs_ok.x = self.x + (self.w / 2) - 72
    GUI.elms.UserInputs_cancel.x = self.x + (self.w / 2) + 8
    
end
    
local function wnd_close(self, apply)
    
    self:showlayers()
    
    return_values(apply, self.ret_func)
    
    GUI.escape_bypass = false

    if self.resize then
        
        -- Reopen window with initial size
        resize_window( table.unpack(self.resize) )       
        
    end

    clear_UserInputs()
    
end


local function txt_enter(self)

    self.focus = false
    self:lostfocus()
    self:redraw()
    
    GUI.elms.UserInputs_ok:exec()

end


-- Opens a Window element with text fields for getting user input
function GUI.GetUserInputs(title, captions, defaults, ret_func, extra_width)
    
    if not captions or type(captions) ~= "table" or #captions == 0 
    or not defaults or type(defaults) ~= "table" or #defaults == 0 then
        return
    end
    
    local caps, defs = captions, defaults
    
    --[[
    -- Preliminary support for passing CSVs
    local caps = {}
    if type(captions) == "string" then
        for str in string.gmatch(captions, "[^,]+") do
            caps[#caps+1] = str
        end
    elseif type(captions) == "table" then
        caps = captions
    end    
    
    local defs = {}
    if type(defaults) == "string" then
        for str in string.gmatch(defaults, "[^,]+") do
            defs[#defs+1] = str
        end
    elseif type(defaults) == "table" then
        defs = defaults
    end
    ]]--
    
    
    -- Figure out the window dimensions
    local w = ref_txt.x + ref_txt.w + (extra_width or 0) + 16
    local h = 16 + #caps * (ref_txt.off) + 80


    -- Resize the script window if the GUI window is larger (it'll be reset after)
    local resize = check_window_size(w, h)
    
    if resize then
        
        -- Reopen the window
        resize_window(resize[1], resize[2], resize[3], w + 32, h + 32)
        
    end


    local z_set = GUI.GetBuffer(2)
    table.sort(z_set)

    -- Set up the window
    --	name, z, x, y, w, h, caption, z_set[, center]
    local elms = {}
    elms.UserInputs_wnd = {
        type = "Window",
        z = z_set[2],
        x = 0,
        y = 0,
        w = w,
        h = h,
        caption = title or "",
        z_set = z_set,
        num_inputs = #caps,
        ret_func = ret_func,
        resize = resize
    }
    
    -- Set up the textboxes
    for i = 1, #caps do
        
        elms["UserInputs_txt_" .. i] = {
            type = "Textbox",
            z = z_set[1],
            x = ref_txt.x,
            y = ref_txt.y + (i - 1)*ref_txt.off,
            w = ref_txt.w + (extra_width or 0),
            h = ref_txt.h,
            caption = caps[i] or "",
            retval = defs[i] or "",
            tab_idx = i,
        }

    end
   
    -- Set up the OK/Cancel buttons
    elms.UserInputs_ok = {
        type = "Button",
        z = z_set[1],
        x = 0,
        y = h - 64,
        w = 64,
        h = 24,
        caption = "OK",
    }
    elms.UserInputs_cancel = {
        type = "Button",
        z = z_set[1],
        x = 0,
        y = h - 64,
        w = 64,
        h = 24,
        caption = "Cancel"
        
    }
    
    -- Create the window and elements
    GUI.CreateElms(elms)
    
    -- Our elms need to be in the master list for the Window's adjustment function to see them
    GUI.update_elms_list()

    -- Method overrides so we can return values and whatnot
    GUI.elms.UserInputs_wnd.onopen = wnd_open
    
    GUI.elms.UserInputs_wnd.close = wnd_close
    
    GUI.newfocus = GUI.elms.UserInputs_txt_1

    -- Return should also press the OK button
    -- The metatable stuff is necessary because an individual textbox doesn't
    -- technically its own .keys table, so adding an entry to it ends up going
    -- in GUI.Textbox.keys when it looks for its own .keys and can't find it.
    for name in pairs( GUI.elms.UserInputs_wnd:getchildelms() ) do
        if string.match(name, "txt") then
            GUI.elms[name].keys = {[GUI.chars.RETURN] = txt_enter}
            setmetatable(GUI.elms[name].keys, {__index=GUI.Textbox.keys})
        end
    end

    GUI.elms.UserInputs_ok.func = function() GUI.elms.UserInputs_wnd:close(true) end
    GUI.elms.UserInputs_cancel.func = function() GUI.elms.UserInputs_wnd:close() end


    GUI.elms.UserInputs_wnd:open()
    
end
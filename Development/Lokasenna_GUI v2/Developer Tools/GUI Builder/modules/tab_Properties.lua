-- NoIndex: true
--local Sidebar = require("wnd_Sidebar")

local Property = GUI.req(GUI.script_path .. "modules/class_Properties.lua")()
--local Element = require("func_Elements")
--local Property = require("class_Properties")

local Properties = {}

local ref_properties = {x = 104, y = 56, w = 144, h = 20, off = 22}

function Properties.adjust_elms(x, w)
    
    Properties.ref_x, Properties.ref_w = x, w
    -- Make sure we move all of the property elements
    for k in pairs(GUI.elms) do

        if string.match(k, "GB_prop_") then
           GUI.elms[k].x = x + ref_properties.x
        end

    end
    
end




------------------------------------
-------- Getting elements ----------
------------------------------------



-- Global --> Properties.lua
-- Make a copy of the target element with a new name,
-- and delete the old one
function Properties.rename_elm(self, new)

    Properties.recreate_elm(GUI.elms[self.elm], new, true)

    --Element.select_elm(GUI.elms[new])

end



-- Global --> Properties.lua
-- Delete an element and make it again; for changing properties that need
-- more than just a call to :init
-- Specify 'name' to rename the element, since it requires recreating the
-- element anyway.
function Properties.recreate_elm(elm, name, selected, dup_x, dup_y)

    -- Compensate y for the menu bar offset added by get_creation_params
    --if not dup_x then elm.y = elm.y + Menu.h end

    local old = elm.name


    -- If changing the name, change the old elm's name so the exported param strings use it...
    if name then
        elm.name = name
    end

    -- Get creation strings w/ our updated vars
    local params = Element.get_elm_params(elm)

    -- ...and then change the name back so the elm can be deleted
    if name then
        elm.name = old

        -- If the element's caption is still the default, change it too
        if elm.caption == old then
            params.caption = Element.format_property_to_code(name)
        end
    end

    -- If duplicating, update the elm's x and y before creating it
    if dup_x then
        
        params.x = Element.format_property_to_code(dup_x)
        params.y = Element.format_property_to_code(dup_y)
        
    -- If not duplicating, delete the old one
    else
        elm:delete() 
    end
    
    -- Concat the table since Lua won't do it with keys
    -- get_elm_params should probably do this itself somehow?
    local str = "GUI.New({\n\t"
    local param_strs = {}
    for k, v in pairs(params) do
        param_strs[#param_strs + 1] = k .. " = " .. v
    end
    str = str .. table.concat(param_strs, ",\n\t") .. "\n})"
    
    --GUI.Msg("creating element with string:\n" .. tostring(str) )
    
    -- Create a new element with the same name
    load(str)()
    
    Element.store_elm_defaults(GUI.elms[name or old])
    
    Element.add_GB_methods(GUI.elms[name or old])

    if selected then
        
        local page = GUI.elms.GB_mnu_pages and GUI.elms.GB_mnu_pages.retval
        Properties.init_properties(GUI.elms[name or old], page)
        
        GUI.elms.GB_frm_sel_elm.elm = name or old

    end

end





-- DEPENDS: GUI STATE
-- Clear all property elements
function Properties.clear_properties()

    GUI.elms.GB_side_no_elm.z = 2

    for k in pairs(GUI.elms) do

        if string.match(k, "GB_prop_") or string.match(k, "GB_mnu_pages") then 
            GUI.elms[k]:delete() 
        end
        
    end
    
    GUI.redraw_z[5] = true
    
end


-- DEPENDS: CLASS_PROPERTIES, GUI STATE
function Properties.new_property(property, elm, pos)

    local prop = property.prop
    local name = "GB_prop_" .. prop
    local class = property.class

    GUI.New(name, Property[class], 5, 
            ref_properties.x + Sidebar_ref_x(), 
            ref_properties.y + ref_properties.off * pos, 
            ref_properties.w, ref_properties.h, 
            property.caption, table.unpack(Property[class].extra_params or {}) )
    
    local self = GUI.elms[name]
    self.class = class
    self.prop = prop
    self.elm = elm.name
    self.recreate = property.recreate
    GUI.Val(name, elm[prop]) 

end


-- DEPENDS: CLASS_PROPERTIES, GUI STATE
function Properties.init_mnu_pages(page, numpages)
    
    local pages = {}
    for i = 1, numpages do
        pages[i] = i .. " of " .. numpages
    end
    pages = table.concat(pages,",")           
    
    local mnu_w = 64
    
    GUI.New("GB_mnu_pages", "Menubox", 5, 
            Sidebar_ref_x() + (Sidebar_w - mnu_w) / 2, 
            48, 
            80, 20, nil, pages, nil, true)
    GUI.elms.GB_mnu_pages.align = 1

    -- Append the menubox's onmouseup(?) and onwheel methods
    function GUI.elms.GB_mnu_pages:onmouseup()
       
        GUI.Menubox.onmouseup(self)
        
        Properties.init_properties(GUI.elms[GUI.elms.GB_frm_sel_elm.elm], self.retval)
        
    end
    
    function GUI.elms.GB_mnu_pages:onwheel()
        
        GUI.Menubox.onwheel(self)
        
        Properties.init_properties(GUI.elms[GUI.elms.GB_frm_sel_elm.elm], self.retval)
        
    end

    GUI.Val("GB_mnu_pages", page)

end


-- Create property elements for the current element
function Properties.init_properties(elm, curpage)
    
    Properties.clear_properties()
    
    --GUI.Val("GB_lbl_cur_elm", "Current element:")
    GUI.elms.GB_side_no_elm.z = -2

    -- Create the new property elements and load them from the elm
    -- Why are these being stored on the elm again? Remembering defaults?
    local properties = GUI[elm.type].GB.properties
    
    -- For tag entries
    local skip = 0
    local numpages, page = 0
    local done_elms
    
    for i = 1, #properties do
    
        -- Spacer entries; do nothing
        if properties[i] == "" then
        
        -- Page numbers
        elseif type(properties[i]) == "string" then
            
            numpages = numpages + 1
            
            -- End of current page
            if page and not done_elms then
                
                done_elms = true
                
            -- Haven't seen a page header yet, requested page is this one, or not given
            else

                if not page
                and (not curpage or numpages == math.floor(curpage)) then
                
                    page = numpages
                    skip = i
                
                end
                
            end
            
        -- Only create elements if they're on the active page, or p1 if not given            
        elseif not done_elms and (page or (not page and not curpage)) then
            Properties.new_property(properties[i], elm, i - skip)
        end

    end


    if page then
        
        Properties.init_mnu_pages(page, numpages)

    end

end


return Properties
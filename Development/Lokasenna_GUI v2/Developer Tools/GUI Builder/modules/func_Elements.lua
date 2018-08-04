-- NoIndex: true

local Element = {}


-- Add all of the element data to the element classes
--Element.classes = GUI.req(GUI.script_path .. "modules/data_Elements.lua")()
Element.classes = require("data_Elements")



function Element.select_elm(elm)

    GUI.elms.GB_frm_sel_elm.elm = elm.name
    GUI.elms.GB_frm_sel_elm.z = 10
    GUI.redraw_z[10] = true

    Properties.init_properties(elm)

end


function Element.deselect_elm()

    GUI.elms.GB_frm_sel_elm.elm = nil
    GUI.elms.GB_frm_sel_elm.z = -2
    GUI.redraw_z[10] = true

    Properties.clear_properties()

end


function Element.duplicate_elm(elm)
    
    local new_name = Element.get_new_elm_name(elm.type)
    
    local x, y = Element.get_new_elm_coords(GUI.mouse.x, GUI.mouse.y)
    
    Properties.recreate_elm(elm, new_name, false, x, y)

end


function Element.delete_elm(elm)

    if GUI.elms.GB_frm_sel_elm.elm == elm.name then Element.deselect_elm() end

    elm:redraw()
    elm:delete()

    -- Giving GUI.Update a new element to perform the subsequent :onmouseup(),
    -- otherwise it will get stuck and not allow any new LMB input.
    --GUI.mouse_down_elm = GUI.elms.GB_frm_bg
    --GUI.forcemouseup()
    
end


-- Shift+drag to move elements
function Element.drag_elm(elm)

    elm.x, elm.y = Element.get_new_elm_coords(  GUI.mouse.x - GUI.mouse.off_x, 
                                                GUI.mouse.y - GUI.mouse.off_y)

    GUI.elms.GB_frm_sel_elm.x, GUI.elms.GB_frm_sel_elm.y = elm.x, elm.y
    GUI.elms.GB_frm_sel_elm:redraw()

    elm:init()
    elm:redraw()

    GUI.Val("GB_prop_x", elm.x)
    GUI.Val("GB_prop_y", elm.y)
    
end


-- CAN STAY HERE
function Element.get_new_elm_name(type)

    local i = 1
    while true do

        if not GUI.elms[type..i] then
            return type..i
        else
            i = i + 1
        end

    end
end



-- Global --> Recreate element
function Element.add_GB_methods(elm)

    function elm:onmouseup()

        -- Just a placeholder to keep elms from doing anything on Shift and
        -- messing up the other methods
        if GUI.mouse.cap & 8 == 8 then

        
        -- Alt+click to delete
        elseif GUI.mouse.cap & 16 == 16 then

            Element.delete_elm(self)

        else

            GUI[self.type].onmouseup(self)

        end

    end

    function elm:onmousedown()

        -- Shift+click to select
        if GUI.mouse.cap & 8 == 8 then

            if GUI.elms.GB_frm_sel_elm.elm ~= self.name then Element.select_elm(self) end
            --self.focus = false

        else

            GUI[self.type].onmousedown(self)

        end

    end

    function elm:ondrag()

        -- Shift+click to move elm
        if GUI.mouse.cap & 8 == 8 then

            Element.drag_elm(self)

        else

            GUI[self.type].ondrag(self)

        end

    end

end


-- Global --> Recreate element
function Element.store_elm_defaults(elm)

    local defaults = {}
    local creation = elm.GB.creation
    local extra = GUI.table_find(creation, "^$") + 1
    local extra_props = {table.unpack(creation, extra)}

    for i = 1, #extra_props do

        defaults[extra_props[i]] = elm[extra_props[i]]

    end

    elm.prop_defaults = defaults

end


-- NEEDS PREFS (move prefs to global GB state?)
function Element.get_new_elm_coords(x, y)
    
    local off = Menu.h
    
    if Prefs.preferences.grid_snap then
        x = GUI.nearestmultiple(x, Prefs.preferences.grid_size)
        y = GUI.nearestmultiple(y - off, Prefs.preferences.grid_size)
          + off
    end
    
    return x, y
    
end

function Element.create_new_elm(class)

    if not class then return end

    local name = Element.get_new_elm_name(class)

    local x, y = Element.get_new_elm_coords(GUI.mouse.x, GUI.mouse.y)

    GUI.New(name, class, 11, x, y, table.unpack(GUI[class].GB.defaults) )
    GUI.elms[name].caption = name
    GUI.elms[name]:init()

    Element.add_GB_methods(GUI.elms[name])

    Element.store_elm_defaults(GUI.elms[name])

end


-- Returns two tables
-- 'props' can be placed in a GUI.New call with table.concat(props, ", ")
function Element.get_elm_params(elm)
    
    local params = elm.GB.properties
--[[
    -- Values common to all elms
    local props = {
        name = '"'..elm.name..'"',
        type = '"'..elm.type..'"', 
        z = elm.z,
        x = Element.format_property_to_code(elm.x), 
        y = Element.format_property_to_code(elm.y - Menu.h)
        }
]]--

    -- 'type' isn't part of the editable properties, so we need to add it here
    local props = {type = Element.format_property_to_code(elm.type)}
    
    -- Grab any extra creation parameters
    for i = 1, #params do
        
        local prop = params[i].prop
        if prop then

            -- Exception for Menubar menus because they're special
            local val
            if elm.type == "Menubar" and prop == "menus" then
                local menus, tmp = elm[prop], {}
                for i = 1, #menus do
                tmp[#tmp + 1] = '{title = "' .. menus[i].title .. '", options = {}}'
                end
                val = "{" .. table.concat(tmp,", ") .. "}"
                
            -- Exception for sliders changing direction
            elseif elm.type == "Slider" and prop == "w" then
                val = Element.format_property_to_code( math.max(elm.w, elm.h) )
            else
            
                val = Element.format_property_to_code( elm[prop] )
                
            end

            props[prop] = val
        end

    end

    return  props

end

-- NO DEPENDENCIES
-- Format values as proper code
function Element.format_property_to_code(val)
    
    if      type(val) == "string" then
        return '"' .. val .. '"'
    elseif  type(val) == "number" then
        -- Was fucking up Slider.inc with decimal values.
        -- Will this break anything else?
        --val = math.floor(val)
    elseif  type(val) == "boolean" then
        return tostring(val)
    elseif  type(val) == "table" then
        
        local strs = {}
        for i = 1, #val do
            if type(val[i]) == "string" then
                strs[#strs+1] = '"' .. val[i] .. '"'
            else
                strs[#strs+1] = tostring(val[i])
            end
        end
        return "{" .. table.concat(strs, ", ") .. "}"

    end

    return val
    
end


local right_click_menu = {

    strs = {

        "#Insert element:",
        "",        
        "Duplicate selected element",   

    },

    opts = {

        "",
        "",
        "duplicate",        

    }

}

function Element.get_new_elm_menu()

    local strs, opts = {right_click_menu.strs[1]}, {right_click_menu.opts[1]}

    local idx = 2
    for class in GUI.kpairs(Element.classes) do

        if not GUI[class].GB.hidden then
            
            strs[idx] = class
            opts[idx] = class
            idx = idx + 1
            
        end

    end

    strs[idx], opts[idx] = "", ""
    strs[idx + 1], opts[idx + 1] = right_click_menu.strs[3], right_click_menu.opts[3]

    return strs, opts

end


function Element.new_elm_menu()

    gfx.x, gfx.y = GUI.mouse.x, GUI.mouse.y

    local strs, opts = Element.get_new_elm_menu()

    local ret = gfx.showmenu(table.concat(strs, "|"))
    if ret == 0 then return end

    local seps = 0
    for i = 1, ret do
        if strs[i] == "" then seps = seps + 1 end
    end

    ret = ret + seps

    local opt = opts[ret]

    if opt == "duplicate" then
        if GUI.elms.GB_frm_sel_elm.elm then
            Element.duplicate_elm(GUI.elms[GUI.elms.GB_frm_sel_elm.elm])
        end
    else
        Element.create_new_elm(opt)
    end


end





return Element
-- NoIndex: true
------------------------------------
-------- Property classes ----------
------------------------------------

local Element = require("func_Elements")

local Property = {}

Property.Name       = GUI.table_copy(GUI.Textbox)
Property.String     = GUI.table_copy(GUI.Textbox)
Property.Cap_Pos    = GUI.table_copy(GUI.Textbox)
Property.Menu_Titles= GUI.table_copy(GUI.Textbox)
Property.Number     = GUI.table_copy(GUI.Textbox)
Property.Boolean    = GUI.table_copy(GUI.Checklist)
Property.Font       = GUI.table_copy(GUI.Textbox)
Property.MonoFont   = GUI.table_copy(GUI.Textbox)
Property.Color      = GUI.table_copy(GUI.Textbox)
Property.Coord_Y    = GUI.table_copy(GUI.Textbox)
Property.Coord_Z    = GUI.table_copy(GUI.Textbox)
Property.Direction  = GUI.table_copy(GUI.Textbox)
Property.Table      = GUI.table_copy(GUI.Textbox)



------------------------------------
-------- Shared methods/params -----
------------------------------------


-- Pass the property's new value to its target element
local function apply_value(self)

    -- Make sure the value is valid, otherwise revert
    local val = self:validate()
    
    if val or (self.class == "Boolean" and val == false) then
        
        GUI.elms[self.elm][self.prop] = val
        GUI.elms[self.elm]:init()
        GUI.elms[self.elm]:redraw()

        GUI.elms.GB_frm_sel_elm:redraw()

    else
        
        self:val(GUI.elms[self.elm][self.prop])
    end

end


-- All property elements should apply their value when focus is lost
local function lostfocus(self)
        
    GUI[self.type].lostfocus(self)
    
    self:apply_value()
    
    if self.recreate then Properties.recreate_elm(GUI.elms[self.elm], nil, true) end
    
end


local function revert_value(self)

    gfx.x, gfx.y = GUI.mouse.x, GUI.mouse.y
    local can_revert = not self.recreate
    local val = gfx.showmenu(can_revert and "Revert to default value" or "#This property cannot be reverted")
    
    if val and val > 0 then

        local new = GUI.elms[self.elm].prop_defaults[self.prop]
        self:val(new)
        self:lostfocus()
        self:redraw()
      
    end
    
end

-- Any common methods
for class in pairs(Property) do
    
    Property[class].apply_value = apply_value  
    Property[class].lostfocus = lostfocus
    Property[class].onmouser_up = revert_value
    
end




------------------------------------
-------- Class-specific ------------
-------- methods and params --------
------------------------------------


-- Creation params for each type of property
-- (Not including name,type,z,x,y,w,h,caption, since they're determined at runtime.
Property.Boolean.extra_params = {""}
    

-- Don't allow duplicate names
function Property.Name:validate()
    
    local val = self:val()
    if val and val ~= "" and not GUI.elms[val] and not string.match(val, "^GB_") then
        return tostring(self:val())
    end
    
end
    
function Property.String:validate()
    return tostring(self:val())
end

function Property.Cap_Pos:validate()
    local val = self:val()
    return (val == "left" 
        or  val == "top" 
        or  val == "bottom"
        or  val == "right") and val
end

function Property.Menu_Titles:validate()
    
    local val = self:val()
    return type(val) == "table" and val
    
end

function Property.Number:validate()
    return tonumber(self:val())
end

function Property.Coord_Y:validate()
    return tonumber(self:val())
end

function Property.Coord_Z:validate()
    return tonumber(self:val())
end

function Property.Font:validate()
    local val = self:val()
    if GUI.fonts[tonumber(val)] then
        return tonumber(val)
    elseif GUI.fonts[val] then
        return val
    end
end

function Property.MonoFont:validate()
    local val = self:val()
    if GUI.fonts[tonumber(val)] then
        val = tonumber(val)
    elseif not GUI.fonts[val] then
        val = nil
    end
    
    -- Check for monospace
    if val then
        GUI.font(val)
        local w1 = gfx.measurechar(string.byte("i"))
        local w2 = gfx.measurechar(string.byte("m"))
        
        if w1 == w2 then return val end
    end
        
end

function Property.Color:validate()
    local val = self:val()
    if GUI.colors[val] then
        return val
    elseif GUI.colors[tonumber(val)] then
        return tonumber(val)
    end
end

function Property.Boolean:validate()
    return not not self:val()
end

function Property.Direction:validate()
    local val = self:val()
    if val == "h" or val == "v" then return val end
end

function Property.Table:validate()
    local val = self:val()

    if type(val) == "table"
    -- Don't accept anything other than digits for slider handles
    and not (       GUI.elms[self.elm].type == "Slider"
                and string.match(table.concat(val), "[^%d^%s]") )
    then 
    
        return self:val() 
        
    end
end



-- Offset for the menu bar
function Property.Coord_Y:val(newval)

    if newval then
        self.retval = tonumber(newval) - Menu.h
        self:redraw()		
    else
        return tonumber(self.retval) + Menu.h
    end   

end


-- Offset so 1-10 can be reserved for GB stuff
function Property.Coord_Z:val(newval)
    
    if newval then
        self.retval = tonumber(newval) - 10
        self:redraw()
    else
        return self.retval + 10
    end
    
end


function Property.Boolean:init()
    
    self.optarray = {self.caption}
    
    self.caption = ""
    self.frame = false
    self.pad = 0     
    
    GUI[self.type].init(self)
    
end

function Property.Boolean:val(newval)

    if newval ~= nil then
        self.optsel[1] = not not newval
    else
        return self.optsel[1]
    end   

end    

function Property.Boolean:onmouseup()
    
    GUI[self.type].onmouseup(self)
    
    GUI.elms[self.elm][self.prop] = self.optsel[1]
    GUI.elms[self.elm]:init()
    GUI.redraw_z[GUI.elms[self.elm].z] = true
            
end


function Property.Name:lostfocus()
    
    GUI[self.type].lostfocus(self)
    
    -- Make sure the value is valid, otherwise revert
    local val = self:validate()
    
    if val then
        
        Properties.rename_elm(self, val)
        
    else
        self:val(GUI.elms[self.elm][self.prop])
    end    
        
end


function Property.Coord_Z:lostfocus()
    
    GUI[self.type].lostfocus(self)
    
    local val = self:validate()
    
    if val then
        
        local legal = GUI.clamp(11, val, 111)
        if val ~= legal then
            
            self:val(legal)
    
        end
        
        GUI.elms[self.elm][self.prop] = self:val()
        GUI.elms[self.elm]:init()
        GUI.elms[self.elm]:redraw()

        GUI.elms.GB_frm_sel_elm:redraw()
        
    else
    
        self:val(GUI.elms[self.elm][self.prop])
        
    end
    
end

--[[ function Property.Menu_Titles:apply_value()
    
    GUI[self.type].lostfocus(self)
   
    -- 
    local val = self:validate()
    
    if val then
        
        -- Make the titles accessible for get_creation_params
        GUI.elms[self.elm].titles = val
        
    else
    
        self:val(GUI.elms[self.elm][self.prop])
        
    end
    
end
]]--

function Property.Direction:apply_value()
  
    -- Make sure the value is valid, otherwise revert
    local val = self:val()
    if val and val ~= "" then val = self:validate(val) end
    
    if val and val ~= GUI.elms[self.elm][self.prop] then

        -- Make the change
        GUI.elms[self.elm][self.prop] = val
        
        -- Swap w to where it should be for the new direction
        local horz = (val == "h")
        
        -- This is gross. I hate it.
        if GUI.elms[self.elm].type == "Checklist" or GUI.elms[self.elm].type == "Radio" then
            
            GUI.elms[self.elm][horz and "w" or "h"], GUI.elms[self.elm][horz and "h" or "w"] 
          = GUI.elms[self.elm][horz and "h" or "w"], GUI.elms[self.elm][horz and "w" or "h"]
          
        else
            -- Slider
            GUI.elms[self.elm][horz and "w" or "h"] = GUI.elms[self.elm][horz and "h" or "w"]
            
        end

        -- Delete the elm and make it again
        Properties.recreate_elm(GUI.elms[self.elm], nil, true)
        
        GUI.elms.GB_frm_sel_elm:redraw()        

    else
        self:val(GUI.elms[self.elm][self.prop])
    end  
    
end

function Property.Menu_Titles:val(newval)
    
    if newval then
        
        local titles = {}
        for i = 1, #GUI.elms[self.elm].menus do
            titles[i] = GUI.elms[self.elm].menus[i].title
        end
        self.retval = table.concat(titles, ",")
        
    else
    
        -- Applying to the menubar
        local menus = {}
        for v in string.gmatch(self.retval, "[^,]*") do
            table.insert(menus, {title = v, options = {}})
        end
                
        return menus
        
    end
    
end

function Property.Table:val(newval)

    if newval then

        if type(newval) == "table" then

            local vals = {}
            for i = 1, #newval do
                
                vals[i] = newval[i]

            end
            
            self.retval = table.concat(vals, ",")
        
        end

    else
    
        local vals = {}
        for v in string.gmatch(self.retval, "[^,]*") do
            table.insert(vals, v)
        end
        --if GUI.elms[self.elm].type == "Slider" then
        --table.sort(vals)
        return vals
        
    end

end



return Property
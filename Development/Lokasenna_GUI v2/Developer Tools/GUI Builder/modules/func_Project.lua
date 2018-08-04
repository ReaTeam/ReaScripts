-- NoIndex: true
--local Sidebar = require("wnd_Sidebar")

local Project = {}

-- Default project window properties
Project.proj_settings = {
    
    name = "New script GUI",
    w = 640,
    h = 480,
    x = 0,
    y = 0,
    anchor = "mouse",
    corner = "C"
    
    }



Project.validate_proj_setting = {

    name = function(val)
        if val ~= "" then return tostring(val) end
    end,

    w = function(val)
        if tonumber(val) and tonumber(val) > 0 then return math.floor(val) end
    end,

    h = function(val)
        if tonumber(val) and tonumber(val) > 0 then return math.floor(val) end
    end,

    x = function(val)
        if tonumber(val) then return math.floor(val) end
    end,

    y = function(val)
        if tonumber(val) then return math.floor(val) end
    end,

    anchor = function(val)
        if val == "screen" or val == "mouse" then return tostring(val) end
    end,

    corner = function(val)
        if string.match("TL,T,TR,R,BR,B,BL,L,C", "%,"..val.."%,") then return val end
    end,

}


function Project.populate_settings()
    
    for k, v in pairs(Project.proj_settings) do
    
        GUI.Val("GB_wnd_proj_" .. k, v)        
        
    end
    
end


function Project.update_wnd_size()
    
    local dock, x, y, w, h = gfx.dock(-1, 0, 0, 0, 0)
    w = Project.proj_settings.w + Sidebar_w
    h = Project.proj_settings.h + Menu.h
    
    gfx.quit()
    --gfx.init("name"[,width,height,dockstate,xpos,ypos] )
    gfx.init(GUI.name, w, h, dock, x, y)
    
end


function Project.save_settings()
    
    local resized
    
    for k in pairs(Project.proj_settings) do
        
        local new = GUI.Val("GB_wnd_proj_" .. k)
        local old = Project.proj_settings[k]
        
        --GUI.Msg(k .. ", new: " .. new .. ", old: " .. old)
        
        if new ~= old and (k == "w" or k == "h") then
            --GUI.Msg("resizing")
            resized = true
        end
        
        Project.proj_settings[k] = new
        
    end
    
    if resized then Project.update_wnd_size() end
    
end


function Project.add_method_overrides(elms)
        
    for name in pairs(elms) do
        
        if not string.match(name, "_OK") then
            
            GUI.elms[name].prop = string.match(name, "GB_wnd_proj_(.+)")
            
            GUI.elms[name].lostfocus = function(self)
                
                GUI.Textbox.lostfocus(self)
                
                local val = Project.validate_proj_setting[ self.prop ](self.retval)
                
                if val then
                    
                    Project.proj_settings[self.prop] = self.retval
                    
                else
                
                    self.retval = Project.proj_settings[self.prop]
                    
                end               

            end
            
        end
        
        
    end    
    
end




return Project
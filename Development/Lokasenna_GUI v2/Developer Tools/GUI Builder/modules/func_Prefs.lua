-- NoIndex: true
local Prefs = {}

Prefs.preferences = {
    
    grid_snap = true,
    grid_show = true,
    grid_size = 16,
    
}

Prefs.validate_preference = {
    
    grid_snap = function(val) 
        return not not val 
    end,
    grid_show = function(val)
        return not not val 
    end,
    grid_size = function(val) 
        if tonumber(val) and tonumber(val) > 0 then return math.floor(val) end
    end,
        
    }

function Prefs.populate_settings()
    
    for k, v in pairs(Prefs.preferences) do
        
        GUI.Val("GB_wnd_prefs_" .. k, v)
        
    end
    
end


function Prefs.save_settings()
    
    for k in pairs(Prefs.preferences) do
        
        Prefs.preferences[k] = GUI.Val("GB_wnd_prefs_" .. k)
        
    end
    
end


function Prefs.add_method_overrides(elms)
        
    for name in pairs(elms) do
        
        if not string.match(name, "_OK") then
            
            GUI.elms[name].prop = string.match(name, "GB_wnd_prefs_(.+)")
            
            GUI.elms[name].lostfocus = function(self)
                
                GUI.Textbox.lostfocus(self)
                
                local val = Prefs.validate_preference[ self.prop ](self.retval)
                
                if val then
                    
                    Prefs.preferences[self.prop] = self.retval
                    
                else
                
                    self.retval = Prefs.preferences[self.prop]
                    
                end               

            end
            
        end
        
        
    end    
    
end


function Prefs.draw_grid(self)
   
      
    GUI.color("wnd_bg")
    gfx.rect(0, 0, self.w, self.h, true)
   
    GUI.color("gray")
    GUI.font(4)
    
    local grid = Prefs.preferences.grid_size
    
    for i = grid, math.max(self.h, self.w), grid do
        
        local a = (i == 0) or (i % (grid * 4) == 0)
        gfx.a = a and 1 or 0.3
        gfx.line(i, 0, i, self.h)
        gfx.line(0, i, self.w, i)
        if a then
            gfx.x, gfx.y = i + 4, 4
            gfx.drawstr( math.floor(i) )
            gfx.x, gfx.y = 4, i + 4
            gfx.drawstr( math.floor(i) )
        end	
	
	end
    
    
    
end

return Prefs
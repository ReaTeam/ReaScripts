-- NoIndex: true
local Prefs = GUI.req(GUI.script_path .. "modules/func_Prefs.lua")()

-- Global preferencse
GUI.New("GB_wnd_prefs", "Window", 497, 0, 0, 320, 240, "Preferences", {495, 496, 497})

GUI.New("GB_wnd_prefs_grid_show", "Checklist", 496, 16, 12, 192, 28, "", "Show grid")
GUI.New("GB_wnd_prefs_grid_snap", "Checklist", 496, 16, 36, 192, 28, "", "Snap to grid")
GUI.New("GB_wnd_prefs_grid_size", "Textbox", 496, 80, 72, 64, 20, "Grid size:")

GUI.New("GB_wnd_prefs_OK", "Button",           496, 0, 0, 64, 24, "OK", GUI.elms.GB_wnd_prefs.close, GUI.elms.GB_wnd_prefs, true)


GUI.elms.GB_wnd_prefs.noadjust = {GB_wnd_prefs_OK = true}

GUI.elms_hide[495] = true
GUI.elms_hide[496] = true
GUI.elms_hide[497] = true

GUI.elms.GB_wnd_prefs_grid_show.frame = false
GUI.elms.GB_wnd_prefs_grid_snap.frame = false



function GUI.elms.GB_wnd_prefs:onopen()
    
    self:adjustchildelms()

    GUI.elms.GB_wnd_prefs_OK.x = GUI.center(GUI.elms.GB_wnd_prefs_OK, self)
    GUI.elms.GB_wnd_prefs_OK.y = self.y + self.h - 40

    Prefs.populate_settings()

end

function GUI.elms.GB_wnd_prefs:onclose(ok)
    
    if ok then 
        
        Prefs.save_settings()
        
        -- Update the grid size
        GUI.elms.GB_frm_bg:init()
        GUI.elms.GB_frm_bg:redraw()
        
    end

    
end


return Prefs
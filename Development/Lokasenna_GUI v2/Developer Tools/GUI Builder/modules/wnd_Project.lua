-- NoIndex: true
local Project = GUI.req(GUI.script_path .. "modules/func_Project.lua")()

-- Project settings
GUI.New("GB_wnd_proj", "Window", 499, 0, 0, 320, 240, "Project Settings", {498, 499})

local ref_wnd_proj = {x = 64, y = 16, x_off = 128, y_off = 22}
GUI.New("GB_wnd_proj_name", "Textbox",  498, ref_wnd_proj.x, ref_wnd_proj.y, 192, 20, "Name:")

GUI.New("GB_wnd_proj_x", "Textbox",     498, ref_wnd_proj.x, ref_wnd_proj.y + 2*ref_wnd_proj.y_off, 64, 20, "X:")
GUI.New("GB_wnd_proj_y", "Textbox",     498, ref_wnd_proj.x + ref_wnd_proj.x_off, ref_wnd_proj.y + 2*ref_wnd_proj.y_off, 64, 20, "Y:")

GUI.New("GB_wnd_proj_w", "Textbox",     498, ref_wnd_proj.x, ref_wnd_proj.y + 3*ref_wnd_proj.y_off, 64, 20, "Width:")
GUI.New("GB_wnd_proj_h", "Textbox",     498, ref_wnd_proj.x + ref_wnd_proj.x_off, ref_wnd_proj.y + 3*ref_wnd_proj.y_off, 64, 20, "Height:")

GUI.New("GB_wnd_proj_anchor", "Textbox",498, ref_wnd_proj.x, ref_wnd_proj.y + 5*ref_wnd_proj.y_off, 64, 20, "Anchor:")
GUI.New("GB_wnd_proj_corner", "Textbox",498, ref_wnd_proj.x + ref_wnd_proj.x_off, ref_wnd_proj.y + 5*ref_wnd_proj.y_off, 64, 20, "Corner:")

GUI.New("GB_wnd_proj_OK", "Button",           498, 0, 0, 64, 24, "OK", GUI.elms.GB_wnd_proj.close, GUI.elms.GB_wnd_proj, true)


GUI.elms.GB_wnd_proj.noadjust = {GB_wnd_proj_OK = true}

GUI.elms_hide[498] = true
GUI.elms_hide[499] = true


function GUI.elms.GB_wnd_proj:onopen()
    
    self:adjustchildelms()

    GUI.elms.GB_wnd_proj_OK.x = GUI.center(GUI.elms.GB_wnd_proj_OK, self)
    GUI.elms.GB_wnd_proj_OK.y = self.y + self.h - 40

    Project.populate_settings()

    Project.resize_window = nil
end

function GUI.elms.GB_wnd_proj:onclose(ok)
    if ok then 
        
        Project.save_settings() 
        GUI.elms.GB_frm_bg:redraw()
    
    end
    
end


return Project
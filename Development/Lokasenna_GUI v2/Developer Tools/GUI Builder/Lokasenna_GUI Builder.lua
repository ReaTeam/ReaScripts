-- NoIndex: true
--[[
    GUI Builder for Lokasenna_GUI v2.9

]]--


local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack, then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Frame.lua")()
GUI.req("Classes/Class - Knob.lua")()
GUI.req("Classes/Class - Label.lua")()
GUI.req("Classes/Class - Listbox.lua")()
GUI.req("Classes/Class - Menubar.lua")()
GUI.req("Classes/Class - Menubox.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Tabs.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - TextEditor.lua")()
GUI.req("Classes/Class - Window.lua")()




------------------------------------
-------- Random globals ------------
------------------------------------

Sidebar_w = 272
function Sidebar_ref_x() return (GUI.cur_w or GUI.w or gfx.w) - Sidebar_w end





------------------------------------
-------- GB Modules ----------------
------------------------------------



package.path = package.path .. ";" .. GUI.script_path .. "modules/?.lua"

Element     = GUI.req(GUI.script_path .. "modules/func_Elements.lua")()
Export      = GUI.req(GUI.script_path .. "modules/func_Export.lua")()
Sidebar     = GUI.req(GUI.script_path .. "modules/wnd_Sidebar.lua")()
Properties  = GUI.req(GUI.script_path .. "modules/tab_Properties.lua")()
Project     = GUI.req(GUI.script_path .. "modules/wnd_Project.lua")()
Prefs       = GUI.req(GUI.script_path .. "modules/wnd_Prefs.lua")()
Menu        = GUI.req(GUI.script_path .. "modules/func_Menu.lua")()
Help        = GUI.req(GUI.script_path .. "modules/wnd_Help.lua")()

--local Element = require("func_Elements")
--local Export = require("func_Export")
--local Sidebar = require("wnd_Sidebar")
--local Properties = require("tab_Properties")

-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end





------------------------------------
-------- GUI Stuff -----------------
------------------------------------


GUI.name = "GUI Builder"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 640 + Sidebar_w, 480 + Menu.h
GUI.anchor, GUI.corner = "mouse", "C"




------------------------------------
-------- Basic frames --------------
------------------------------------

GUI.New("GB_frm_bg", "Frame",    112, 0, 0, 800, 768, false, false, "wnd_bg")


-- For highlighting the current element
GUI.New("GB_frm_sel_elm", "Frame", 1, 1, 1, 1, 1)



------------------------------------
-------- Basic frames --------------
-------- Properties + methods ------
------------------------------------

function GUI.elms.GB_frm_bg:init()

    self.buff = GUI.GetBuffer()

    self.w, self.h = Sidebar_ref_x(), (GUI.cur_h or GUI.h or gfx.h)
    local w, h = self.w, self.h

    gfx.dest = self.buff
    gfx.setimgdim(self.buff, -1, -1)
    gfx.setimgdim(self.buff, w, h)

    Prefs.draw_grid(self)

end


-- Doesn't need to be visible.
function GUI.elms.GB_frm_bg:draw()

    if Prefs.preferences.grid_show then
--gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs] )
        gfx.blit(self.buff, 1, 0, 0, 0, self.w, self.h, 0, Menu.h)

    end

    GUI.color("white")

    gfx.rect(   -1,
                0,
                Project.proj_settings.w + 2,
                Project.proj_settings.h + Menu.h + 1,
                false)

end

function GUI.elms.GB_frm_bg:onmouseup()

    if GUI.mouse.cap & 8 == 8 then

        Element.deselect_elm()

    end

end

function GUI.elms.GB_frm_bg:onmouser_up()

    Element.new_elm_menu()

end


GUI.elms.GB_frm_sel_elm.bg = nil

-- We don't want the frame to pick up any user input
function GUI.elms.GB_frm_sel_elm:onupdate()
    return true
end

function GUI.elms.GB_frm_sel_elm:draw()

    GUI.color("magenta")

    if self.elm then
        gfx.rect(   GUI.elms[self.elm].x - 4,
                    GUI.elms[self.elm].y - 4,
                    GUI.elms[self.elm].w + 8,
                    GUI.elms[self.elm].h + 8,
                    false)
    end

end



GUI.Init()




------------------------------------
-------- Things we can't do --------
-------- until Init has run --------
------------------------------------


GUI.onresize = Sidebar.adjust_sidebar
Sidebar.adjust_sidebar()

Project.add_method_overrides( GUI.elms.GB_wnd_proj:getchildelms() )
Prefs.add_method_overrides( GUI.elms.GB_wnd_prefs:getchildelms() )



GUI.Main()

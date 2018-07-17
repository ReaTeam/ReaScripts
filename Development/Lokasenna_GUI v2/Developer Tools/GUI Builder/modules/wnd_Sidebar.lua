-- NoIndex: true
--local Properties = require("tab_Properties")

local Sidebar = {}

-- Moved to main script so they can be global; avoids a circular dependency
-- Sidebar_w = 272
-- function Sidebar_ref_x() return (GUI.cur_w or GUI.w or gfx.w) - Sidebar_w end


-- Adjust the sidebar and its contents when the window is resized
function Sidebar.adjust_sidebar()

    local ref = Sidebar_ref_x()

    GUI.elms.GB_side_frm.x = ref
    GUI.elms.GB_side_frm.h = GUI.cur_h - GUI.elms.GB_side_frm.y
    GUI.elms.GB_side_frm:init()
    
    GUI.elms.GB_side_bg.x = ref
    GUI.elms.GB_side_bg.h = GUI.cur_h
    GUI.elms.GB_side_bg:init()

    GUI.elms.GB_frm_bg.w = ref
    GUI.elms.GB_frm_bg.h = GUI.cur_h - GUI.elms.GB_frm_bg.y
    GUI.elms.GB_frm_bg:init()

    GUI.elms.GB_side_no_elm.x = ref + (Sidebar_w - GUI.elms.GB_side_no_elm.w) / 2
    if GUI.elms.GB_mnu_pages then
        GUI.elms.GB_mnu_pages.x = ref + (Sidebar_w - GUI.elms.GB_mnu_pages.w) / 2
    end

    GUI.elms.GB_mnu_bar.w = GUI.cur_w
    GUI.elms.GB_mnu_bar:init()

    GUI.elms.GB_side_tab.x = ref
    GUI.elms.GB_side_tab.w = GUI.cur_w - ref
    GUI.elms.GB_side_tab:init()

    Properties.adjust_elms(ref, Sidebar_w)

    GUI.redraw_z[0] = true

end

GUI.New("GB_side_frm", "Frame",  3, 800, 0, 4, 768, true, true)
GUI.New("GB_side_bg", "Frame", 9, Sidebar_ref_x(), 0, Sidebar_w, 768, false, false, "wnd_bg")

GUI.New("GB_side_tab", "Tabs", 4, Sidebar_ref_x(), 20, 56, 20, "Element")
GUI.New("GB_side_no_elm", "Label", 5, 816, 48, "No element selected", true, 2, "txt")

GUI.elms.GB_side_tab:update_sets(

    {

    [1] = {5},
    [2] = {6},

    }
)


return Sidebar
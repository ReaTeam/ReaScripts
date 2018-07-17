-- NoIndex: true
-- Adds creation and property data to the GUI element classes,
-- as well as GB-specific methods for selecting, deleting, duplicating, dragging, etc
--[[

        {prop = "", caption = "", class = ""},

    prop        Target element's property
    caption     Displayed property name
    class       Property type
    
    recreate = true
    
                Will :delete and GUI.New(...) the target element after applying a
                value. Necessary for some classes (Slider) that do a lot of internal
                work with the created values and can't be easily updated.
    
]]--

local classes = {}

-- Frequently-used properties so I only have to type them out once
local props = {

    name        = {prop = "name",         caption = "Name",           class = "Name"},
    z           = {prop = "z",            caption = "Z",              class = "Coord_Z"},
    x           = {prop = "x",            caption = "X",              class = "Number"},
    y           = {prop = "y",            caption = "Y",              class = "Coord_Y"},
    w           = {prop = "w",            caption = "W",              class = "Number"},
    h           = {prop = "h",            caption = "H",              class = "Number"},
    caption     = {prop = "caption",      caption = "Caption",        class = "String"},
    font        = {prop = "font",         caption = "Font",           class = "Font"},
    font_a      = {prop = "font_a",       caption = "Cap. Font",      class = "Font"},
    font_b      = {prop = "font_b",       caption = "Text Font",      class = "Font"},
    col_txt     = {prop = "col_txt",      caption = "Text Color",     class = "Color"},
    col_fill    = {prop = "col_fill",     caption = "Fill Color",     class = "Color"},
    pad         = {prop = "pad",          caption = "Padding",        class = "Number"},
    shadow      = {prop = "shadow",       caption = "Shadow",         class = "Boolean"},
}

classes.Button = {
    defaults = {48, 24, "Button"},
    creation = {"w", "h", "caption", "", "font", "col_txt", "col_fill"},        
    properties = {
        props.name,
        "",
        props.z,
        props.x,
        props.y,
        props.w,
        props.h,
        "",
        props.caption,
        props.font,
        props.col_txt,
        props.col_fill,            
    }
}

classes.Checklist = {
    defaults = {96, 192, "Checklist", "Option 1,Option 2,Option 3,Option 4"},
    creation = {"w", "h", "caption", "optarray", "dir", "pad", "", "font_a", "font_b", "col_txt", "col_fill", "bg", "frame", "shadow", "opt_size", "swap"},
    properties = {
        "1",
        props.name,
        "",
        props.z,
        props.x,
        props.y,
        props.w,
        props.h,
        "",
        props.caption,
        "",
        {prop = "optarray",     caption = "Options",        class = "Table"},
        {prop = "dir",          caption = "Direction",      class = "Direction"},
        props.pad,
        "2",
        props.font_a,
        props.font_b,
        props.col_txt,
        props.col_fill,        
        {prop = "bg",           caption = "Text BG",        class = "Color"},
        "",
        {prop = "frame",        caption = "Frame",          class = "Boolean"},
        props.shadow,
        {prop = "swap",         caption = "Swap",           class = "Boolean"},
        "",
        {prop = "opt_size",     caption = "Opt. Size",      class = "Number"},
    }
}

classes.Frame = {
    defaults = {256, 128},
    creation = {"w", "h", "shadow", "fill", "color", "round", "", "text", "txt_indent", "txt_pad", "pad", "bg", "font", "col_txt"},
    properties = {
        "1",
        props.name,
        "",
        props.z,
        props.x,
        props.y,
        props.w,
        props.h,
        "",
        props.shadow,
        {prop = "fill",         caption = "Fill",           class = "Boolean"},
        {prop = "color",        caption = "Frame Color",    class = "Color"},
        {prop = "bg",           caption = "BG Color",       class = "Color"},
        {prop = "round",        caption = "Round",          class = "Number"},
        "2",
        {prop = "text",         caption = "Text",           class = "String"},
        {prop = "txt_indent",   caption = "Para. Indent",   class = "Number"},
        {prop = "txt_pad",      caption = "Wrap Indent",    class = "Number"},
        props.pad,
        props.font,
        props.col_txt,
    }
}

classes.Knob = {
    defaults = {40, "Knob", 0, 10, 5, 1, true},
    creation = {"w", "caption", "min", "max", "default", "inc", "vals", "", "bg", "font_a", "font_b", "col_txt", "col_head", "col_body", "cap_x", "cap_y"},
    properties = {
        "1",
        props.name,
        "",
        props.z,
        props.x,
        props.y,
        props.w,
        "",
        props.caption,
        "",
        {prop = "min",          caption = "Min.",           class = "Number",       recreate = true},
        {prop = "max",          caption = "Max.",           class = "Number",       recreate = true},
        {prop = "default",      caption = "Default",        class = "Number",       recreate = true},
        {prop = "inc",          caption = "Increment",      class = "Number",       recreate = true},
        {prop = "vals",         caption = "Show Values",    class = "Boolean"},
        "2",
        props.font_a,
        props.font_b,
        props.col_txt,
        {prop = "col_head",     caption = "Head",           class = "Color"},
        {prop = "col_body",     caption = "Body",           class = "Color"},
        "",
        {prop = "cap_x",        caption = "Cap. Offset X",  class = "Number"},
        {prop = "cap_y",        caption = "Cap. Offset Y",  class = "Number"},
    }
}

classes.Label = {
    defaults = {"Label"},
    creation = {"caption", "", "shadow", "font", "color", "bg"},        
    properties = {
        props.name,
        "",
        props.z,
        props.x,
        props.y,
        "",
        "",
        "",
        props.caption,        
        props.font,
        {prop = "color",        caption = "Text Color",     class = "Color"},
        {prop = "bg",           caption = "BG Color",       class = "Color"},  
        props.shadow, 

    }
}

classes.Listbox = {
    defaults = {192, 96, "Item 1,Item 2,Item 3,Item 4"},
    creation = {"w", "h", "list", "multi", "caption", "pad", "", "cap_bg", "bg", "shadow", "color", "col_fill", "font_a", "font_b"},
    properties = {
        "1",
        props.name,
        "",
        props.z,
        props.x,
        props.y,
        props.w,
        props.h,
        "",
        {prop = "list",         caption = "List Items",     class = "Table"},
        {prop = "multi",        caption = "Multi-select",   class = "Boolean"},
        "",
        props.caption,
        "2",
        props.font_a,
        {prop = "font_b",       caption = "Text Font",      class = "Font",         recreate = true},
        {prop = "color",        caption = "Text Color",     class = "Color"},
        props.col_fill,
        {prop = "bg",           caption = "List BG",        class = "Color"},
        {prop = "cap_bg",       caption = "Caption BG",     class = "Color"},
        props.shadow,
        props.pad,       
        
    }
}

classes.Menubar = {
    defaults = {    {
                    {title = "Menu 1", options = {}},
                    {title = "Menu 2", options = {}},
                    {title = "Menu 3", options = {}},
                    },
                },
    creation = {"menus", "w", "h", "pad", "", "font", "col_txt", "col_bg", "col_over"},
    properties = {
        props.name,
        "",
        props.z,
        props.x,
        props.y,
        props.w,
        props.h,
        "",
        {prop = "menus",        caption = "Menu Titles",    class = "Menu_Titles",  recreate = true},
        "",
        {prop = "font",         caption = "Text Font",      class = "Font"},
        props.col_txt,
        {prop = "col_bg",       caption = "BG Color",       class = "Color"},
        {prop = "col_over",     caption = "Hover Color",    class = "Color"},
        {prop = "fullwidth",    caption = "Full Width",     class = "Boolean",      recreate = true},
    }
}

classes.Menubox = {
    defaults = {128, 20, "Menubox", "!Option 1,#Option 2,>Folder,Option 3,Option 4,<Option 5,,Option 6"},
    creation = {"w", "h", "caption", "optarray", "pad", "noarrow", "", "col_txt", "col_cap", "bg", "font_a", "font_b", "align", "retval"},
    properties = {
        "1",
        props.name,
        "",
        props.z,
        props.x,
        props.y,
        props.w,
        props.h,
        "",
        props.caption,
        {prop = "optarray",     caption = "Options",        class = "Table"},
        {prop = "retval",       caption = "Default",        class = "Number",       recreate = true},
        "2",
        props.font_a,
        props.font_b,
        {prop = "col_txt",      caption = "Cap. Color",     class = "Color"},
        {prop = "col_cap",      caption = "Text Color",     class = "Color"},
        {prop = "bg",           caption = "BG Color",       class = "Color"},
        "",
        props.pad,
        {prop = "noarrow",      caption = "Hide Arrow",     class = "Boolean"},
        {prop = "align",        caption = "Align",          class = "Number"},
    }
}

classes.Radio = {
    defaults = {96, 192, "Checklist", "Option 1,Option 2,Option 3,Option 4"},
    creation = {"w", "h", "caption", "optarray", "dir", "pad", "", "font_a", "font_b", "col_txt", "col_fill", "bg", "frame", "shadow", "opt_size", "swap"},
    properties = {
        "1",
        props.name,
        "",
        props.z,
        props.x,
        props.y,
        props.w,
        props.h,
        "",
        props.caption,
        "",
        {prop = "optarray",     caption = "Options",        class = "Table"},
        {prop = "dir",          caption = "Direction",      class = "Direction"},
        "2",
        props.font_a,
        props.font_b,
        props.col_txt,
        props.col_fill,        
        {prop = "bg",           caption = "Text BG",        class = "Color"},
        "",
        {prop = "frame",        caption = "Frame",          class = "Boolean"},
        props.shadow,
        {prop = "swap",         caption = "Swap",           class = "Boolean"},
        "",
        {prop = "opt_size",     caption = "Opt. Size",      class = "Number"},
    }
}

classes.Slider = {
    defaults = {96, "Slider", 0, 10, {5}},
    creation = {"w", "caption", "min", "max", "defaults", "inc", "dir", "", "font_a", "font_b", "col_txt", "col_fill", "bg", "show_handles", "show_values", "cap_x", "cap_y"},
    properties = {
        "1",
        props.name,
        "",
        props.z,
        props.x,
        props.y,
        props.w,
        "",
        "",
        props.caption,
        "",
        {prop = "min",          caption = "Min.",           class = "Number",       recreate = true},
        {prop = "max",          caption = "Max.",           class = "Number",       recreate = true},
        {prop = "defaults",     caption = "Defaults",       class = "Table",        recreate = true},
        {prop = "inc",          caption = "Increment",      class = "Number",       recreate = true},
        {prop = "dir",          caption = "Direction",      class = "Direction",    recreate = true},
        "2",
        props.font_a,
        {prop = "font_b",       caption = "Val. Font",      class = "Font"},
        props.col_txt,
        props.col_fill,
        {prop = "bg",           caption = "BG Color",       class = "Color"},
        "",
        {prop = "show_handles", caption = "Show Handles",   class = "Boolean"},
        {prop = "show_values",  caption = "Show Values",    class = "Boolean"},
        "",
        {prop = "cap_x",        caption = "Cap. Offset X",  class = "Number"},
        {prop = "cap_y",        caption = "Cap. Offset Y",  class = "Number"},
    }
}

classes.Tabs = {
    defaults = {48, 20, "Tab 1,Tab 2,Tab 3"},
    creation = {"tab_w", "tab_h", "optarray", "pad", "", "w", "bg", "col_txt", "col_tab_a", "col_tab_b", "font_a", "font_b"},
    properties = {
        "1",
        props.name,
        "",
        props.z,
        props.x,
        props.y,
        {prop = "w",            caption = "W",              class = "Number",       recreate = true},
        "",
        props.caption,
        {prop = "optarray",     caption = "Options",        class = "Table",        recreate = true},  
        {prop = "tab_w",        caption = "Tab Width",      class = "Number",},
        {prop = "tab_h",        caption = "Tab Height",     class = "Number",       recreate = true},
        {prop = "pad",          caption = "Tab Pad",        class = "Number"},
        "2",
        {prop = "font_a",       caption = "Active Font",    class = "Font"},
        {prop = "font_b",       caption = "Inact. Font",    class = "Font"},
        props.col_txt,
        {prop = "col_tab_a",    caption = "Active Color",   class = "Color"},
        {prop = "col_tab_b",    caption = "Inact. Color",   class = "Color"},
        {prop = "bg",           caption = "BG Color",       class = "Color"},
        {prop = "fullwidth",    caption = "Full Width",     class = "Boolean",      recreate = true},
    }
}

classes.Textbox = {
    defaults = {96, 20, "Textbox"},
    creation = {"w", "h", "caption", "pad", "", "font_a", "font_b", "cap_pos", "color", "bg", "shadow", "undo_limit"},
    properties = {
        "1",
        props.name,
        "",
        props.z,
        props.x,
        props.y,
        props.w,
        props.h,
        "",
        props.caption,
        {prop = "cap_pos",      caption = "Cap. Pos.",      class = "Cap_Pos"},
        "2",
        props.font_a,
        {prop = "font_b",       caption = "Text Font",      class = "MonoFont"},
        {prop = "color",        caption = "Text Color",     class = "Color"},
        {prop = "bg",           caption = "Cap. BG",        class = "Color"},
        props.shadow,        
        props.pad,
        "",
        {prop = "undo_limit",   caption = "Undo States",    class = "Number"},

    }
}

classes.TextEditor = {
    defaults = {256, 192},
    creation = {"w", "h", "text", "caption", "pad", "", "bg", "shadow", "color", "col_fill", "font_a", "font_b", "undo_limit"},
    properties = {
        "1",
        props.name,
        "",
        props.z,
        props.x,
        props.y,
        {prop = "w",            caption = "W",              class = "Number",       recreate = true},
        {prop = "h",            caption = "H",              class = "Number",       recreate = true},  
        "",
        props.caption,        
        "2",
        props.font_a,
        {prop = "font_b",       caption = "Text Font",      class = "MonoFont"},
        {prop = "color",        caption = "Text Color",     class = "Color"},
        props.col_fill,
        {prop = "cap_bg",       caption = "Cap. BG",        class = "Color"},
        {prop = "bg",           caption = "Background",     class = "Color"},
        "",
        props.shadow,        
        props.pad, 
        "",
        {prop = "undo_limit",   caption = "Undo States",    class = "Number"},
    }
}

-- Store the element data with the element classes, keep a list of classes we can return
local ret_classes = {}

for class, data in pairs(classes) do

    GUI[class].GB = data
    ret_classes[class] = true

end

return classes



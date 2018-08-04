-- NoIndex: true

--[[
	Lokasenna_GUI example

	- Demonstration of the Listbox, Menubar, and TextEditor classes

]]--

-- The Core library must be loaded prior to anything else

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please run 'Script: Set Lokasenna_GUI v2 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

GUI.req("Classes/Class - Menubar.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Listbox.lua")()
GUI.req("Classes/Class - TextEditor.lua")()

-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end



------------------------------------
-------- Menu functions ------------
------------------------------------


local mnu_file = {
    
    new = function()
        GUI.Val("txted_text", "file: new")
    end,
    
    open = function()
        GUI.Val("txted_text", "file: open")
    end,

    recent_blah = function()
        GUI.Val("txted_text", "file:\trecent files: blah.txt")
    end,
    
    recent_stuff = function()
        GUI.Val("txted_text", "file:\trecent files: stuff.txt")
    end,
    
    recent_readme = function()
        GUI.Val("txted_text", "file:\trecent files: readme.md")
    end,

    save = function()
        GUI.Val("txted_text", "file: save")
    end,
    
    save_as = function()
        GUI.Val("txted_text", "file: save as")
    end,
    
    print = function()
        GUI.Val("txted_text", "file: print")
    end,
    
    print_preview = function()
        GUI.Val("txted_text", "file: print preview")
    end,
    
    exit = function()
        GUI.quit = true
    end
    
}

local mnu_edit = {
    
    cut = function()
        GUI.Val("txted_text", "edit: cut")
    end,
    
    copy = function()
        GUI.Val("txted_text", "edit: copy")
    end,
    
    copy_path = function()
        GUI.Val("txted_text", "edit:\tcopy current path")
    end,
        
    copy_file = function()
        GUI.Val("txted_text", "edit:\tcopy current filename")    
    end,
    
    copy_dir = function()
        GUI.Val("txted_text", "edit:\tcopy current directory path")
    end,
    
    paste = function()
        GUI.Val("txted_text", "edit: paste")
    end,
    
    delete = function()
        GUI.Val("txted_text", "edit: delete")
    end,
    
    select_all = function()
        GUI.Val("txted_text", "edit: select all")
    end
    
}

local mnu_view = { 
    
    always_on_top = function()
        GUI.Val("txted_text", "view: always on top")
    end,    
    
    toggle_full_screen = function()
        GUI.Val("txted_text", "view: toggle full-screen")
    end,    
    
    hide_menu = function()
        GUI.Val("txted_text", "view: hide menu")
    end 
    
}

local mnu_help = {

    help = function()
        GUI.Val("txted_text", "help: help")
    end,    
    
    open_website = function()
        GUI.Val("txted_text", "help: open website")
    end,    
    
    check_for_updates = function()
        GUI.Val("txted_text", "help: check for updates")
    end,    
    
    about = function()
        GUI.Val("txted_text", "help: about")
    end
    
}




------------------------------------
-------- Menu contents -------------
------------------------------------


-- This table is passed to the Menubar
-- Must be structured like this (.title, .options, etc)
local menus = {
    
    {title = "File", options = {
        {"New",                 mnu_file.new},
        {""},
        {"Open",                mnu_file.open},
        {">Recent Files"},
            {"blah.txt",        mnu_file.recent_blah},
            {"stuff.txt",       mnu_file.recent_stuff},
            {"<readme.md",      mnu_file.recent_readme},
        {"Save",                mnu_file.save},
        {"Save As",             mnu_file.save_as},
        {""},
        {"#Print",               mnu_file.print},
        {"#Print Preview",       mnu_file.print_preview},
        {""},
        {"Exit",                mnu_file.exit}
    }},
 
    {title = "Edit", options = {
        {"Cut",                 mnu_edit.cut},
        {"Copy",                mnu_edit.copy},
        {">Copy to Clipboard"},
            {"Current full file path",  mnu_edit.copy_path},
            {"Current filename",        mnu_edit.copy_file},
            {"<Current directory path",  mnu_edit.copy_dir},
        {"Paste",               mnu_edit.paste},
        {"Delete",              mnu_edit.delete},
        {""},
        {"Select All",          mnu_edit.select_all}
    }},
    
    {title = "View", options = {
        {"!Always On Top",       mnu_view.always_on_top},
        {"Toggle Full-Screen",  mnu_view.toggle_full_screen},
        {"Hide Menu",           mnu_view.hide_menu}
    }},
    
    {title = "Help", options = {
        {"Help",                mnu_help.help},
        {"#Open Website",        mnu_help.open_website},
        {""},
        {"#Check For Updates",   mnu_help.check_for_updates},
        {"About",               mnu_help.about},
    }},
}




------------------------------------
-------- Listbox contents ----------
------------------------------------


local items = {
	
	{"Pride and Prejudice", 
[[It is a truth universally acknowledged, that a single man in possession of a good fortune
must be in want of a wife.]]},

	{"100 Years of Solitude", 
[[Many years later, as he faced the firing squad, Colonel Aureliano Buendía was to remember
that distant afternoon when his father took him to discover ice.]]},

	{"Lolita", 
[[Lolita, light of my life, fire of my loins.]]},

	{"1984", 
[[It was a bright cold day in April, and the clocks were striking thirteen.]]},
	
	{"A Tale of Two Cities", 
[[It was the best of times, it was the worst of times, it was the age of wisdom, it was the
age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the
season of Light, it was the season of Darkness, it was the spring of hope, it was the winter
of despair.]]},
	
	{"The Catcher in the Rye", 
[[If you really want to hear about it, the first thing you’ll probably want to know is where
I was born, and what my lousy childhood was like, and how my parents were occupied and all
before they had me, and all that David Copperfield kind of crap, but I don’t feel like going
into it, if you want to know the truth.]]},
	
	{"City of Glass", 
[[It was a wrong number that started it, the telephone ringing three times in the dead of
night, and the voice on the other end asking for someone he was not.]]},
	
	{"The Stranger", 
[[Mother died today.]]},
	
	{"Waiting", 
[[Every summer Lin Kong returned to Goose Village to divorce his wife, Shuyu.]]},
	
	{"Notes from Underground", 
[[I am a sick man . . . I am a spiteful man.]]},
	
	{"Paradise", 
[[They shoot the white girl first.]]},
	
	{"The Old Man and the Sea", 
[[He was an old man who fished alone in a skiff in the Gulf Stream and he had gone
eighty-four days now without taking a fish.]]},
	
	{"The Crow Road", 
[[It was the day my grandmother exploded.]]},
	
	{"Catch-22", 
[[It was love at first sight.]]},
	
	{"Imaginative Qualities of Actual Things",
[[What if this young woman, who writes such bad poems, in competition with her husband,
whose poems are equally bad, should stretch her remarkably long and well-made legs out
before you, so that her skirt slips up to the tops of her stockings?]]}

}

local titles = {}
for i = 1, #items do
	titles[i] = items[i][1]
end


local function add_text()
	
	-- Get the list box's selected item(s)
	local selected = GUI.Val("lst_titles")
	
	-- Make sure it's a table, just to be consistent with the multi-select logic
	if type(selected) == "number" then selected = {[selected] = true} end
	
	-- Get and sort the selected item numbers
	local vals = {}
	for k, v in pairs(selected) do
		table.insert(vals, k)
	end
	
	table.sort(vals)
	
	-- Replace the numbers with the appropriate text
	for i = 1, #vals do
		vals[i] = items[vals[i]][2]
	end
	
	local str = table.concat(vals, "\n\n")

	GUI.Val("txted_text", str)
	
end




------------------------------------
-------- Window settings -----------
------------------------------------

GUI.name = "Example - Menubar, Listbox, and TextEditor"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 800, 272
GUI.anchor, GUI.corner = "mouse", "C"




------------------------------------
-------- GUI Elements --------------
------------------------------------


--[[
    
    Menubar     z,  x,  y,  menus[, w, h, pad])
	Button		z, 	x, 	y, 	w, 	h, caption, func[, ...]
	Listbox		z, 	x, 	y, 	w, 	h[, list, multi, caption, pad])
	TextEditor	z,	x,	y,	w,	h[, text, caption, pad])
	
]]--


GUI.New("mnu_menu", "Menubar",      1,  0,   0,   menus, GUI.w)
GUI.New("lst_titles", "Listbox",	1,	16,  40,  300, 208, "", true)
GUI.New("btn_go", "Button",			1,	324, 104, 32,  24, "-->", add_text) 
GUI.New("txted_text", "TextEditor",	1,	364, 40,  420, 208, "Select an item\nor two\nor three\nor everything\n\nin the list and click the button!")


GUI.elms.lst_titles.list = titles


function GUI.elms.lst_titles:ondoubleclick()

	add_text()
	
end


GUI.Init()
GUI.Main()
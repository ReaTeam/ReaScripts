-- NoIndex: true

--[[
	Lokasenna_GUI example

	- Getting user input before running an action; i.e. replacing GetUserInputs

]]--

-- The Core library must be loaded prior to anything else

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please run 'Script: Set Lokasenna_GUI v2 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Menubox.lua")()
GUI.req("Classes/Class - Options.lua")()

-- If any of the requested libraries weren't found, abort the script nicely.
if missing_lib then return 0 end




------------------------------------
-------- Functions  ----------------
------------------------------------


local function btn_click()
	
	-- Grab all of the user's settings into local variables,
	-- just to make it less awkward to work with
	local mode, thresh = GUI.Val("mnu_mode"), GUI.Val("sldr_thresh")
	local opts = GUI.Val("chk_opts")
	local time_sel, sel_track, glue = opts[1], opts[2], opts[3]
	
	-- Be nice, give the user an Undo point
	reaper.Undo_BeginBlock()
	
	reaper.ShowMessageBox(
		"This is where we pretend to perform some sort of fancy operation with the user's settings.\n\n"
		.."Working in "..tostring(GUI.elms.mnu_mode.optarray[mode])
		.." mode with a threshold of "..tostring(thresh).."db.\n\n"
		.."Apply only to time selection: "..tostring(time_sel).."\n"
		.."Apply only to selected track: "..tostring(sel_track).."\n"
		.."Glue the processed items together afterward: "..tostring(glue)
	, "Yay!", 0)
	
	
	reaper.Undo_EndBlock("Typical script options", 0)	
	
	-- Exit the script on the next update
	GUI.quit = true
	
end




------------------------------------
-------- Window settings -----------
------------------------------------


GUI.name = "Example - Typical script options"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 400, 200
GUI.anchor, GUI.corner = "mouse", "C"




------------------------------------
-------- GUI Elements --------------
------------------------------------


--[[	

	Button		z, 	x, 	y, 	w, 	h, caption, func[, ...]
	Checklist	z, 	x, 	y, 	w, 	h, caption, opts[, dir, pad]
	Menubox		z, 	x, 	y, 	w, 	h, caption, opts, pad, noarrow]
	Slider		z, 	x, 	y, 	w, 	caption, min, max, defaults[, inc, dir]
	
]]--

GUI.New("mnu_mode",	"Menubox",		1, 64,	32,  72, 20, "Mode:", "Auto,Punch,Step")
GUI.New("chk_opts",	"Checklist",	1, 192,	32,  192, 96, "Options", "Only in time selection,Only on selected track,Glue items when finished", "v", 4)
GUI.New("sldr_thresh", "Slider",	1, 32,  96, 128, "Threshold", -60, 0, 48, nil, "h")
GUI.New("btn_go",	"Button",		1, 168, 152, 64, 24, "Go!", btn_click)


GUI.Init()
GUI.Main()
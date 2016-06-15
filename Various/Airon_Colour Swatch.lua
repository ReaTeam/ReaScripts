-- @version 1.61
-- @author Airon
-- @changelog
--    + spk77: fixed colour swatch reset (forum.cockos.com/showpost.php?p=1694646&postcount=282)

--[[
* ReaScript Name: Colour Swatch Window
* Author: Airon
* Licence: GPL v3
* REAPER: 5.0
* Extensions: None
* Description: Colour Swatch window for context sensitive colouring of tracks or items
* Instructions:
*   FULL AUTHOR LIST:
*   Airon, SPK77, Heda, Evil Dragon and many more in the JS/Reascript forum
*
*   Will remember the state it was left in the next time the window is opened again.
*   Can be reset to defaults by clicking on the text in the upper middle "Reset"
*   Detects the selection focus and indicates this in the top row with a TRACK or ITEM text highlighted in red
*   CONFIG options:
*     one_off_colour_change - if set to true, will close the colour swatch window after the first colour change
*     move_window_to_mouse  - if set to true, will reposition the window where the mouse is after opening the window and RESET
*     SHIFT + Right-Click + drag = Upper Saturation
*      CTRL + Right-Click + drag = Lower Saturation
*
*       ALT + Right-Click + drag = Upper Luminosity
*             Right-Click + drag = Lower Luminosity
*
*     Colour Gradient for selected tracks or items
*     CLICK on first colour, then CTRL(Cmd on OSX)+CLICK on second colour
--]]

--[[
 Changelog:
 * v1.61 (2016-06-15)
    + spk77: fixed colour swatch reset
 * v1.60 (2016-06-11)
    + fixed colour swatch reset
]]

-- /////////Basic Config Start////////////////////////////////
dbug_flag = 0 -- set to 0 for no debugging messages, 1 to get them
function dbug (dbug_msg)
  if dbug_flag==1 then ; reaper.ShowConsoleMsg(tostring(dbug_msg)) ; end;
end
--// Setup variables //
save_settings_on_exit = 1      -- 1->save settings via saving to external state when exiting, 0->do not
r_ini_strsection = "colswatch" -- string section name under which last used settings are
                               -- saved to the external state file by Reaper
one_off_colour_change = false  -- change to true if you want the script to bug out after ONE colour change
move_window_to_mouse = false   -- change to true if you want the script to move to your mouse cursor position when opened or when being RESET
auto_apply = 1                 -- 1 -> detect last selection type, item or track , 0 -> manual , click on TRACK or ITEM to change
                            
font_main           = "Verdana"
font_main_h         = 18
font_helptext_h     = 12 -- or use math.floor(font_main_h*0.66666)
window_title        = "Colour Swatch"
swatch_name_last_tooltip = ""
-- if a colour list is used, this area will display the colour name
-- see function settings_derivative and find_longest_swatch_name
text_preset         = "Reset"
text_preset_list    = "Placeholder Preset 1|Preset2|Preset3|Preset4|" --unused as of yet
text_help           = "Help"
text_help_menu      = "Control saturation and luminosity boundaries|by Right-Click and Dragging||Upper Saturation SHIFT+rightdrag|Lower Saturation CTRL+rightdrag|Upper Luminosity rightdrag|Lower Luminosity ALT+rightdrag||Colour gradient with CLICK on first colour|CTRL(CMD)+click on second colour"
text_trackindicator = "TRACK"
text_itemindicator  = "ITEM"
text_autoindicator  = "AUTO"
text_seperation     = 10 -- pixels

track_apply = 1  -- default apply until we can tell what is currently selected.
item_apply = 0

sw_r = 1     --initialize swatch colours WHITE
sw_g = 1
sw_b = 1     
sw_a = 1     -- alpha. rather important or everything will show up black
   
mouse  = { ox=0, oy=0, down=false, up=false, uptime=0 } -- mouse pointer coordinates and stuff
swatch = { n=Black, r=0, g=0, b=0 }                     -- extracted data clicked on swatch
zone   = { ox=0, oy=0 }                                 -- coordinates inside the swatch zone

-- TITLE NEUTRAL colour
tn_r   = 0.75  -- red
tn_g   = 0.75  -- green
tn_b   = 0.75  -- blue
tn_a   = 1     -- alpha
-- TITLE ACTIVATED colour
tact_r = 1     -- red 
tact_g = 0.8   -- green
tact_b = 0.8   -- blue
tact_a = 1     -- alpha


-- ###############################################
-- ### IF YOU CHANGE THIS, to see your changes ###
-- ### close the script window,                ###
-- ### relaunch the script and hit Reset       ###
-- ###############################################
preset_default = { generate_colour = 1 , -- 1-> generated colours, 0->colour list included in preset
                   saturation_max = 0.520 ,
                   saturation_min = 1.000 ,
                   luminance_max = 0.98 ,
                   luminance_min = 0.11 ,
                   sw_max_x = 160 ,   -- # of swatches horizontally
                   sw_max_y = 60  ,   -- # of swatches vertically
                   sw_w = 4     ,     -- swatch width
                   sw_h = 4    ,      -- swatch height
                   sw_border = 0,     -- area around the swatches in pixels
                   bg_r=0.1 ,         -- background behind the swatches
                   bg_g=0.1 ,
                   bg_b=0.1,
                   csv_colour_list = 0 -- no colour list here
                   }

function settings_from_preset (e)
    -- set variables with preset data
    -- set all global variables that can be changed by a preset
    -- function expects the preset data to be passed as an array
    
    generate_colour  =  e.generate_colour
    saturation_max   =  e.saturation_max
    saturation_min   =  e.saturation_min
    luminance_max    =  e.luminance_max
    luminance_min    =  e.luminance_min
    sw_max_x         =  e.sw_max_x
    sw_max_y         =  e.sw_max_y
    sw_w             =  e.sw_w
    sw_h             =  e.sw_h
    sw_border        =  e.sw_border
    bg_r             =  e.bg_r
    bg_g             =  e.bg_g
    bg_b             =  e.bg_b
    if generate_colour == 0 then
        csv_colour_list =  e.csv_colour_list
    end
end

-- The functions I use for saving and recovering settings from the reaper external state file.
--     string reaper.GetExtState(string section, string key)
--            reaper.SetExtState(string section, string key, string value, boolean persist)
--   
--    boolean reaper.HasExtState(string section, string key)
--            reaper.DeleteExtState(string section, string key, boolean persist)


function retrieve_and_set_last_used_setting() -- set variables with preset data
-- set all variables that can be changed by a preset
-- function expects the preset data to be passed as an array

  generate_colour  =  tonumber(reaper.GetExtState(r_ini_strsection, "generate_colour"))
  saturation_max   =  tonumber(reaper.GetExtState(r_ini_strsection, "saturation_max"))
  saturation_min   =  tonumber(reaper.GetExtState(r_ini_strsection, "saturation_min"))
  luminance_max    =  tonumber(reaper.GetExtState(r_ini_strsection, "luminance_max"))
  luminance_min    =  tonumber(reaper.GetExtState(r_ini_strsection, "luminance_min"))
  sw_max_x         =  tonumber(reaper.GetExtState(r_ini_strsection, "sw_max_x"))
  sw_max_y         =  tonumber(reaper.GetExtState(r_ini_strsection, "sw_max_y"))
  sw_w             =  tonumber(reaper.GetExtState(r_ini_strsection, "sw_w"))
  sw_h             =  tonumber(reaper.GetExtState(r_ini_strsection, "sw_h"))
  sw_border        =  tonumber(reaper.GetExtState(r_ini_strsection, "sw_border"))
  bg_r             =  tonumber(reaper.GetExtState(r_ini_strsection, "bg_r"))
  bg_g             =  tonumber(reaper.GetExtState(r_ini_strsection, "bg_g"))
  bg_b             =  tonumber(reaper.GetExtState(r_ini_strsection, "bg_b"))
  -- csv colour list not yet included
  --  if e.csv_colour_list then
  --   csv_colour_list =  e.csv_colour_list
  --  end
end


function save_current_settings() -- set variables with preset data
  -- save away current settings to Reaper external state INI
  reaper.SetExtState(r_ini_strsection,"generate_colour",tostring(generate_colour),true)
  reaper.SetExtState(r_ini_strsection,"saturation_max", tostring(saturation_max),true)
  reaper.SetExtState(r_ini_strsection,"saturation_min", tostring(saturation_min),true)
  reaper.SetExtState(r_ini_strsection,"luminance_max",  tostring(luminance_max),true)
  reaper.SetExtState(r_ini_strsection,"luminance_min",  tostring(luminance_min),true)
  reaper.SetExtState(r_ini_strsection,"sw_max_x",       tostring(sw_max_x),true)
  reaper.SetExtState(r_ini_strsection,"sw_max_y",       tostring(sw_max_y),true)
  reaper.SetExtState(r_ini_strsection,"sw_w",           tostring(sw_w),true)
  reaper.SetExtState(r_ini_strsection,"sw_h",           tostring(sw_h),true)
  reaper.SetExtState(r_ini_strsection,"sw_border",      tostring(sw_border),true)
  reaper.SetExtState(r_ini_strsection,"bg_r",           tostring(bg_r),true)
  reaper.SetExtState(r_ini_strsection,"bg_g",           tostring(bg_g),true)
  reaper.SetExtState(r_ini_strsection,"bg_b",           tostring(bg_b),true)
  -- csv colour list not yet included
  --if e.csv_colour_list then
  -- csv_colour_list =  e.csv_colour_list
  --end
end


function return_preset_from_current_settings ()
    -- dump current settings in to an array and return it
    local e = {}  -- clear local array
    e.generate_colour =  generate_colour 
    e.saturation_max  =  saturation_max  
    e.saturation_min  =  saturation_min  
    e.luminance_max   =  luminance_max   
    e.luminance_min   =  luminance_min   
    e.sw_max_x        =  sw_max_x        
    e.sw_max_y        =  sw_max_y        
    e.sw_w            =  sw_w            
    e.sw_h            =  sw_h            
    e.sw_border       =  sw_border       
    e.bg_r            =  bg_r
    e.bg_g            =  bg_g
    e.bg_b            =  bg_b
    return e -- return the preset data for doing clever stuff.
end


function find_longest_swatch_name(e)
    gfx.setfont(1,font_main, font_helptext_h) -- for string length calculations
    
    local str_longest = e[1] -- first swatch name string
    --local count = math.min(#e*0.25) -- how many name/r/g/b sets ?
    
    if #e < 5 then -- just one colour entry?
        return str_longest
    end
    
    local k , strlength = 0 , 0
    local strlength_max = gfx.measurestr(tostring(e[1]))
    
    for k=5, #e, 4 do
        strlength = gfx.measurestr(tostring(e[k]))
        if strlength     > strlength_max then
            strlength_max = strlength
            str_longest   = e[k]
        end
    end
    return str_longest
end


function create_window ()
    -- DESTROYS(!!!!) and creates the window
    -- ////// Necessary gfx system init to get string measurements
    gfx.quit() -- close any existing window
    gfx.clear = -1
    gfx.dest = -1  -- set default if not yet done
    gfx.init(window_title, sw_win_w, sw_win_h) -- in case we need debug info
    
    --draw background across entire window contents
    gfx.set  (bg_r, bg_g, bg_b, 1) 
    gfx.rect (0, 0, sw_win_w, sw_win_h,  1) 
    
    --calculate initial width of zone for parameter display
    gfx.setfont(1,font_main, font_helptext_h)         --set font
    parameter_string_measure = 'Sat 0.000 Lum 0.000'  --example text
    start_draw_parameters_x  = sw_win_w - gfx.measurestr(parameter_string_measure) --width of resulting text
    
    gfx.setfont(1,font_main, font_main_h) -- set font for string measurements
    --calculate text positioning and click zones
    -- track indicator
    indicator_tx       = text_seperation + 0
    indicator_ty       = 1
    indicator_tw       = gfx.measurestr(text_trackindicator)
    indicator_th       = indicator_ty+font_main_h
    -- item indicator
    indicator_ix       = text_seperation + indicator_tx + gfx.measurestr(text_trackindicator)
    indicator_iy       = 1
    indicator_iw       = gfx.measurestr(text_itemindicator)
    indicator_ih       = indicator_iy+font_main_h
    -- automatic context switching indicator
    indicator_ax       = text_seperation + indicator_ix + gfx.measurestr(text_autoindicator)
    indicator_ay       = 1
    indicator_aw       = gfx.measurestr(text_autoindicator)
    indicator_ah       = indicator_ay+font_main_h
    --help and preset zones
    gfx.setfont(1,font_main, font_helptext_h)    -- set font for string measurements
    ui_helpx           = text_seperation * 4 + indicator_ax + gfx.measurestr(text_autoindicator)
    ui_helpy           = 4
    ui_helpw, ui_helph = gfx.measurestr(text_help)
    ui_presetx         = text_seperation * 4 + ui_helpx     + gfx.measurestr(text_help)
    ui_presety         = 4
    ui_presetw,ui_preseth = gfx.measurestr(text_preset)
    
    -- zone above the swatches
    -- 0/0 to the right of the window and above sw_origin_y
    zone_control =  {            0 ,           0 , sw_win_w , (sw_origin_y-0) }  -- area above the colour swatches
    
    zone_swatch  =  { sw_origin_x  , sw_origin_y , sw_win_w                  , sw_win_h } -- zone where the swatches live
    zone_preset  =  { ui_presetx   , ui_presety  , ui_presetx + ui_presetw   , ui_presety + ui_preseth   } -- resets swatches to the default preset
    zone_help    =  { ui_helpx     , ui_helpy    , ui_helpx   + ui_helpw     , ui_helpy   + ui_helph     } -- help text
    zone_track   =  { indicator_tx , indicator_ty, indicator_tx+indicator_tw , indicator_ty+indicator_th }
    zone_item    =  { indicator_ix , indicator_iy, indicator_ix+indicator_iw , indicator_iy+indicator_ih }
    zone_auto    =  { indicator_ax , indicator_ay, indicator_ax+indicator_aw , indicator_ay+indicator_ah }
end


function generate_colourlist_from_csvlist(e) -- receive the colour list string
    --Grab the data
    sw_table_csv = NIL
    sw_table_csv = {} -- reset sw_table_csv
    local n,r,g,b
    for n, r, g, b in string.gmatch(e, "(.-);(.-);(.-);(.-)\n") do
        table.insert (sw_table_csv, n) -- dump the values in to the sw_table_csv array
        table.insert (sw_table_csv, r)
        table.insert (sw_table_csv, g)
        table.insert (sw_table_csv, b)
    end
end



---/// Generate colour list from Hue range, saturation range and luminosity range ////
--///////////////////////////////////////////////////////////////////////////////////
function generate_colourlist_from_hsl(sat_max,sat_min,lum_max,lum_min)
    -- Hue is spread horizontally, luminosity vertically
    -- saturation is constant, and passed to this function.
    -- colour table is stored in sw_table
    -- sw_max_x and sw_max_y define the horizontal and vertical number if swatches
    -- dbug ("Generating colour table "..sat_max.."  "..sat_min.."  "..lum_max.."  "..lum_min.."\n")
    local hue, lum, horiz, vert = 0,0,1,1
    local r, g, b = 0,0,0
    --[[
    if (lum_max-lum_min < 0  and lum_max<0 and lum_max>1 and lum_min<0 and lum_min>1) then
        dbug("Luminosity parameters illegal. Please choose proper values. ( 0-1 lum_max bigger than lum_min)")
    return ;end -- jump away
    --]]
    sw_table = {} -- reset the swatch table
    for horiz=1 , sw_max_x, 1 do
        hue = horiz / sw_max_x
    
        for vert=1, sw_max_y, 1 do
            lum = lum_max - (((lum_max - lum_min)/sw_max_y) * vert)
            sat = sat_max - (((sat_max - sat_min)/sw_max_y) * vert)
            -- With Hue and Luminosity values calculated we call the conversion function
            r,g,b = hslToRgb(hue,sat,lum)                      -- saturation can very
            -- not necessary r = r/255 ; g = g/255 ; b = b/255           -- convert to normalized values
            
            -- Colour values range from 0 to 255
            table.insert (sw_table, (r.." "..g.." "..b))  -- A string consisting of the RGB numbers
            table.insert (sw_table, r)                  -- red colour value
            table.insert (sw_table, g)                  -- green colour value
            table.insert (sw_table, b)                  -- blue colour value
        end
    end

end

-- //// Convert Hue, Saturation, Luminosity to Red Gree Blue values ////

---[[ Let's bypass this version to test Integer colour values.
function hslToRgb(h,s,l)
    local r, g, b
    if s == 0 then
      r, g, b = l, l, l -- achromatic
    else
        function hue2rgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1/6 then return p + (q - p) * 6 * t end
            if t < 1/2 then return q end
            if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
            return p
        end
        local q
        
        if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
        
        local p = 2 * l - q
        r = hue2rgb(p, q, h + 1/3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1/3)
    end
    -- return r * 255, g * 255, b * 255 -- (rgb values)
    return r, g , b    -- normalized rgb values
end  

function rgbToHsv(r, g, b)
    --r, g, b = r / 255, g / 255, b / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local d = max - min
    local h, s, v
    v = max

    if max == 0 then s = 0 else s = d / max end

    if max == min then
        h = 0 -- achromatic
    else
        if max == r then
            h = (g - b) / d
            if g < b then h = h + 6 end
        elseif max == g then h = (b - r) / d + 2
        elseif max == b then h = (r - g) / d + 4
        end

        h = h / 6
    end

    return h, s, v
end

function hsvToRgb(h, s, v)
    local r, g, b

    local i = math.floor(h * 6);
    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);

    i = i % 6

    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end

    return r, g, b
end

function intToRgb(color_int) -- expects a 24-bit number
    local r = color_int & 255          -- modulo 255
    local g = (color_int >> 8) & 255   -- shift 8 bits to the right and modulo 255
    local b = (color_int >> 16) & 255  -- shift 16 bits to the right and modulo 255
    -- r,g and b now contain integer numbers ranging from 0 to 255, representing integer versions of red, green and blue values
    r = r/255
    g = g/255
    b = b/255
    return r, g, b -- r,g,b now contain numbers ranging from 0 to 1, i.e. normalized, floating point colour values
end

-- //// Convert decimal number to hex in our case
function rgbToHex(rgb)
    local hexadecimal = '0x00'

    for key, value in pairs(rgb) do
        local hex = ''
        while (value > 0) do
            local index = math.fmod(value, 16) + 1
            value = math.floor(value / 16)
            hex = string.sub('0123456789ABCDEF', index, index) .. hex
        end
        if (string.len(hex) == 0) then
            hex = '00'
        elseif (string.len(hex) == 1) then
            hex = '0' .. hex
        end
        hexadecimal = hexadecimal .. hex
    end

    return hexadecimal
end




-- //// SET TRACK COLOUR in Reaper ////
-- assumes colour integers are in variables 
--   swatch.r , swatch_g , swatch_b

function set_track_colour()

    local int_r, int_g, int_b = 0 , 0 , 0 -- requires assignment due to use in debug output
    local set_colour
  
    -- create integers from 0-255 from normalized 0..1 colour values
    if swatch.r > 0 then ; int_r = math.floor(255*swatch.r+0.5) ; end
    if swatch.g > 0 then ; int_g = math.floor(255*swatch.g+0.5) ; end
    if swatch.b > 0 then ; int_b = math.floor(255*swatch.b+0.5) ; end
  
    set_colour = reaper.ColorToNative(int_r, int_g, int_b)
    -- ######################  
    -- ## Colour TRACKS ?? ##
    -- ######################
    if track_apply == 1 then
        count = reaper.CountSelectedTracks(0)
        reaper.Undo_BeginBlock()
        
        local h1     , s1     , v1
        local h_step , s_step , v_step
        
        for selindex = 0 , count-1 do
            sel_track = reaper.GetSelectedTrack(0,selindex)
            -- Colour transition mod by Spk77
            -- LMB: Set one color for selected tracks
            if gfx.mouse_cap == 1 then -- one color
                reaper.SetTrackColor(sel_track, set_colour)
            
            -- CTRL+LMB: Set color gradient for selected tracks
            elseif gfx.mouse_cap == 5 then
                if selindex == 0 then
                    local first_sel_tr_color = reaper.GetTrackColor(sel_track)
                    local r1,g1,b1 = intToRgb(first_sel_tr_color)
                    h1,s1,v1 = rgbToHsv(r1, g1, b1) -- First selected track's color (HSV)
                    local h2,s2,v2 = rgbToHsv(int_r/255, int_g/255, int_b/255) -- Last pressed swatch color (HSV)
                    -- Calculate steps for H,S and V
                    h_step = (h2-h1)/(count-1)
                    s_step = (s2-s1)/(count-1)
                    v_step = (v2-v1)/(count-1)
                else
                    local r,g,b = hsvToRgb(h1+h_step*(selindex), s1+s_step*(selindex), v1+v_step*(selindex))
                    r = math.floor(r*255+0.5)
                    g = math.floor(g*255+0.5)
                    b = math.floor(b*255+0.5)
                    set_colour = reaper.ColorToNative(r, g, b)
                    reaper.SetTrackColor(sel_track, set_colour)
                end
            end
  
        end
        reaper.Undo_EndBlock("Track(s) coloured", -1)
    end
    -- ##################### 
    -- ## Colour ITEMS ?? ##
    -- #####################
    if item_apply == 1 then
        count = reaper.CountSelectedMediaItems(0)
        reaper.Undo_BeginBlock()
      
        for selindex = 0 , count-1 do
            -- MediaItem reaper.GetSelectedMediaItem(ReaProject proj, integer selitem)
            sel_item = reaper.GetSelectedMediaItem(0,selindex)
            -- boolean reaper.SetMediaItemTakeInfo_Value(MediaItem_Take take, string parmname, number newvalue)
            
            -- Colour transition mod by Spk77
            -- LMB: Set one color for selected tracks
            if gfx.mouse_cap == 1 then -- one color
                item_colour = reaper.ColorToNative(int_r, int_g, int_b)
                reaper.SetMediaItemInfo_Value(sel_item, "I_CUSTOMCOLOR", item_colour|16777216)
            
            -- CTRL+LMB: Set color gradient for selected tracks
            elseif gfx.mouse_cap == 5 then
                if selindex == 0 then
                    local first_sel_item_color = reaper.GetMediaItemInfo_Value(sel_item, "I_CUSTOMCOLOR")--reaper.GetTrackColor(sel_track)
                    local r1,g1,b1 = intToRgb(first_sel_item_color)
                    h1,s1,v1 = rgbToHsv(r1, g1, b1) -- First selected track's color (HSV)
                    local h2,s2,v2 = rgbToHsv(int_r/255, int_g/255, int_b/255) -- Last pressed swatch color (HSV)
                    -- Calculate steps for H,S and V
                    h_step = (h2-h1)/(count-1)
                    s_step = (s2-s1)/(count-1)
                    v_step = (v2-v1)/(count-1)
                else
                    local r,g,b = hsvToRgb(h1+h_step*(selindex), s1+s_step*(selindex), v1+v_step*(selindex))
                    r = math.floor(r*255+0.5)
                    g = math.floor(g*255+0.5)
                    b = math.floor(b*255+0.5)
                    item_colour = reaper.ColorToNative(r, g, b)
                    reaper.SetMediaItemInfo_Value(sel_item, "I_CUSTOMCOLOR", item_colour|16777216)
                end
            end
            -- reaper.SetMediaItemTakeInfo_Value (sel_item, I_CUSTOMCOLOR, item_take_colour) 
            reaper.UpdateItemInProject(sel_item) 
        end
        reaper.Undo_EndBlock("Item(s) coloured", -1)
    end
    reaper.TrackList_AdjustWindows(false)
end


-- //// Get Index number in sw_table of the clicked on swatch ////
function get_colour_swatch()
    -- zone.ox and zone.oy are presumed to be set to where the user left-clicked on a colour swatch
    local n,r,g,b,  swatch_x, swatch_y, i, j = "Black",0,0,0, 0,0 ,0,0 -- preset and clear some local stuff
      
    swatch_x = 1+ math.floor((zone.ox+1)/(sw_w+sw_border))   -- round up to swatch number on x-axis
    swatch_y = 1+ math.floor((zone.oy+1)/(sw_h+sw_border))   -- round up to swatch number on y-axis
  
    j = (swatch_x-1)*sw_max_y + swatch_y  -- calculate which name/colour set we need to get
    i = 4 * j  - 3                        -- set index counter to first value of that set
    if i > (#sw_table - 3) then
        i = #sw_table - 3
    end
    
    n,r,g,b = sw_table[i], sw_table[i+1], sw_table[i+2], sw_table[i+3]              -- grab the data from the table
    swatch.n=n ; swatch.r=tonumber(r) ; swatch.g=tonumber(g) ; swatch.b=tonumber(b) -- place data in swatch array, making sure numbers are numbers
  
    -- dbug ("") -- clear the console
    --dbug ("Mouse  Zone x/y : "..mouse.ox.."  "..mouse.oy.."\n")
    --dbug ("Swatch Zone x/y : "..zone.ox.."  "..zone.oy.."\n")
    --dbug ("Swatch count    X = "..swatch_x.."  Y = "..swatch_y.."\n")
    --dbug ("Swatch table index = "..i.."\n")
    --dbug ("Swatch data : "..n.."   "..r.."   "..g.."   "..b.."\n")
end


-- Mouse button goes down and we're off to check where  
function OnMouseDown()
    mouse.down=true                           -- set mouse.down flag, the button is now pressed down
    mouse.ox, mouse.oy = gfx.mouse_x, gfx.mouse_y -- grab current mouse cursor coordinates
  
    -- check boundaries
    -- Control zone first
    if     ( mouse.ox >= zone_control[1]  and mouse.oy >= zone_control[2]
         and mouse.ox <= zone_control[3]  and mouse.oy <= zone_control[4] ) then
           --dbug ("") -- clear console
           dbug ("Control zone selected\n")
            --do stuff about the area above the swatches
      
        if generate_colour == 1 then -- only do allow reset stuff if we're generating colours
            use_default = 0
            if    ( mouse.ox >= zone_preset[1] and mouse.oy >= zone_preset[2]
                and mouse.ox <= zone_preset[3] and mouse.oy <= zone_preset[4] ) then
                use_default = 1                      -- colour_swatch_init will use the default preset !!!
                colour_swatch_init()                 -- closes window, reopens it fresh from saved settings
            end
           
            
        elseif ( mouse.ox >= zone_track[1]  and mouse.oy >= zone_track[2]
             and mouse.ox <= zone_track[3]  and mouse.oy <= zone_track[4] ) then
              dbug("    Track apply\n")
            if auto_apply == 0 then ; track_apply = 1; item_apply = 0 ; draw_indicate_controls() ; end

        elseif ( mouse.ox >= zone_item[1]   and mouse.oy >= zone_item[2]
             and mouse.ox <= zone_item[3]   and mouse.oy <= zone_item[4]  ) then
            dbug("    Item apply\n")
            if auto_apply == 0 then ; track_apply = 0; item_apply = 1 ; draw_indicate_controls() ; end

        elseif ( mouse.ox >= zone_auto[1]   and mouse.oy >= zone_auto[2]
             and mouse.ox <= zone_auto[3]   and mouse.oy <= zone_auto[4]  ) then
            dbug("    Automatic context detection\n")
            if auto_apply == 0 then ; auto_apply = 1 ; draw_indicate_controls() ; end
            if auto_apply == 1 then ; auto_apply = 0 ; draw_indicate_controls() ; end

        elseif ( mouse.ox >= zone_help[1]   and mouse.oy >= zone_help[2]
             and mouse.ox <= zone_help[3]   and mouse.oy <= zone_help[4] ) then
            -- show the menu
            if generate_color == 1 then
                dbug("    Help menu\n")
                gfx.showmenu(text_help_menu)
            end
        end

    -- SWATCH zone ??
    elseif (   mouse.ox >= zone_swatch[1]  and mouse.oy >= zone_swatch[2]
           and mouse.ox <= zone_swatch[3]  and mouse.oy <= zone_swatch[4]  ) then
        --dbug ("") -- clear console
        dbug ("Swatch zone selected\n")
        -- do the swatch stuff
        zone.ox = mouse.ox-sw_origin_x  -- grab the mouse position for swatch zone calc
        zone.oy = mouse.oy-sw_origin_y
        get_colour_swatch()         -- get the four values
        set_track_colour()          -- use the values to colour the tracks or items... check which
        if one_off_colour_change then
            doexit=true -- leave after one colour change
        end
    else -- no zone, no action but a dbug report
    --dbug ("Clicked outside any usable zone\n")
    end
end


function OnMouseUp()
    mouse.down=false
    --mouse.uptime=os.clock()
end


-- //// Draw the colour swatches in to the window     ////
--   // Takes data from sw_table{} and draws swatches //
--   // as specified in sw_max_x and sw_max_y         //
function draw_swatches()
    local k,i = 1,1
    local j = sw_max_x*sw_max_y
    sw_count_x , sw_count_y = 0,0

    for k = 1, j, 1 do -- name+ 3*colour numbers per swatch

        i = 1 + (k-1)*4 -- sw_table index to access the data
        --while sw_table[i] do -- this would draw all swatches, even off screen
        -- grab the data from the table
        
        sw_name,sw_r,sw_g,sw_b = sw_table[i], sw_table[i+1], sw_table[i+2], sw_table[i+3]
        
        sw_x = sw_origin_x + sw_count_x * (sw_w + sw_border) -- calculate drawing
        sw_y = sw_origin_y + sw_count_y * (sw_h + sw_border) -- coordinates
        
        gfx.set  (sw_r, sw_g, sw_b, sw_a)      -- set colour from data. Alpha is preset in beginning
        gfx.rect (sw_x, sw_y, sw_w, sw_h,  1)  -- draw the swatch
        
        -- check if we can draw another swatch
        if  sw_count_y < sw_max_y then      -- more to draw in this column ?
            sw_count_y = sw_count_y + 1     -- draw another swatch to colum in next pass
        end
        if  sw_count_y == sw_max_y then
            sw_count_x = sw_count_x + 1     -- increase column count
            sw_count_y = 0                  -- start at the top
        end
        
    --  i = i + 4 -- jump to next set of name & 3 colour numbers
    end
end



--//// Draws the information text at the top ///
function draw_indicate_controls()
    --clear the area with "buttons" so that text doesn't overlap previous states (thanks EvilDragon)
    gfx.set(0, 0, 0, 1)
    gfx.rect(indicator_tx,indicator_ty,indicator_ax+indicator_aw,indicator_ay+indicator_ah-1) -- that -1 at the end fixs the little black overhang

     -- Draws both the track and item indicator, in either the active or neutral color
    -- Set color for track indicator
    gfx.setfont(1,font_main, font_main_h)
    if track_apply == 1 then ; gfx.set (tact_r, tact_g, tact_b, tact_a) -- set active color
                        else ; gfx.set (tn_r,   tn_g,   tn_b,   tn_a)   -- set neutral color
    end
    --// draw TRACK indicator //
    gfx.x = indicator_tx; gfx.y = indicator_ty
    gfx.drawstr(text_trackindicator)

    -- Set color for item indicator
    if item_apply  == 1 then ; gfx.set (tact_r, tact_g, tact_b, tact_a) -- set active color
                        else ; gfx.set (tn_r,   tn_g,   tn_b,   tn_a)   -- set neutral color
    end
    --draw ITEM indicator //
    gfx.x = indicator_ix; gfx.y = indicator_iy
    gfx.drawstr(text_itemindicator)

    -- Set color for auto indicator
    if auto_apply  == 1 then ; gfx.set (tact_r, tact_g, tact_b, tact_a) -- set active color
                        else ; gfx.set (tn_r,   tn_g,   tn_b,   tn_a)   -- set neutral color
    end
    --draw AUTO indicator //
    gfx.x = indicator_ax; gfx.y = indicator_ay
    gfx.drawstr(text_autoindicator)

    dbug("Draw X "..gfx.x.."  Draw Y "..gfx.y.."  measure "..gfx.measurestr(text_trackindicator).."  measure2 ".. gfx.measurestr(text_itemindicator).."   trackind :  "..indicator_tx.."  itemind :  "..indicator_ix.."   Help Text :  "..ui_helpx.."\n")

    -- help indicator
    gfx.setfont(1,font_main, font_helptext_h)    -- set font
    gfx.set(tn_r, tn_g, tn_b, tn_a)                -- set color and alpha
    gfx.x = ui_helpx ; gfx.y = ui_helpy            -- set drawing coordinates
    gfx.drawstr(text_help)                        -- draw the text

    -- as the preset area can change a lot, we use the function below
    draw_preset_area(text_preset)
end

function draw_preset_area(text_temp)
    -- clear area
    gfx.set  (bg_r, bg_g, bg_b, 1)
    gfx.rect (ui_presetx, ui_presety, ui_presetw, ui_preseth,  1) 
    -- set colour, coordinates and draw text
    gfx.setfont(1,font_main, font_helptext_h)
    gfx.set (tn_r, tn_g, tn_b, tn_a)
    gfx.x = ui_presetx ; gfx.y = ui_presety
    gfx.drawstr (text_temp)
    dbug ("Preset area drawn with - "..text_temp.."\n")
end

function clear_parameters()
    gfx.set (bg_r, bg_g, bg_b, 1)
    gfx.rect (start_draw_parameters_x, 0, sw_win_w-start_draw_parameters_x, sw_origin_y-1,  1)    
end


function draw_parameters()
    ---[[
    clear_parameters()
    -- this is all taylored to Verdana size 12
    gfx.setfont(1,font_main, font_helptext_h)
    gfx.set (tn_r, tn_g, tn_b, tn_a)
    gfx.x = start_draw_parameters_x     ; gfx.y=0 ; gfx.printf ("Sat")
    gfx.x = start_draw_parameters_x +20 ; gfx.y=0 ; gfx.printf ("%.3f",saturation_max)
    gfx.x = start_draw_parameters_x +20 ; gfx.y=10; gfx.printf ("%.3f",saturation_min)
    gfx.x = start_draw_parameters_x +55 ; gfx.y=0 ; gfx.printf ("Lum")
    gfx.x = start_draw_parameters_x +77 ; gfx.y=0 ; gfx.printf ("%.3f",luminance_max)
    gfx.x = start_draw_parameters_x +77 ; gfx.y=10; gfx.printf ("%.3f",luminance_min)
    --]]
end



-- Start fresh
function colour_swatch_init()
    --dbug ("") -- clear console
    gfx.clear = -1
    gfx.dest  = -1  -- set default if not yet done
  
    -- this version has this set to 0
    -- Do we retrieve settings from the saved external state
    -- or from the default preset
    if use_default == 1 then
        settings_from_preset(preset_default)
        save_current_settings() -- and save them
    
    elseif save_settings_on_exit == 1 then
        if reaper.HasExtState(r_ini_strsection,"generate_colour") then
            generate_colour  =  tonumber(reaper.GetExtState(r_ini_strsection, "generate_colour"))
        else
          settings_from_preset(preset_default)
        end
        if generate_colour == 1 then
            --dbug ("Saved state exists\n")
            retrieve_and_set_last_used_setting()
              -- should the generate_colour be set differently in the default preset
              -- use the default preset instead of the saved values.
              -- this is done so we can test scripts with different presets using
              -- the same Reaper external state saves.
              if generate_colour ~= preset_default.generate_colour then
                settings_from_preset(preset_default)
              end
        end
    end  
  
    sw_table = NIL
    sw_table = {} -- our current name and colour information ends up in this table
    if generate_colour == 1 then
        generate_colourlist_from_hsl(saturation_max, saturation_min, luminance_max, luminance_min) -- saturation at 1 -> full saturation
    elseif generate_colour == 0 then
        generate_colourlist_from_csvlist(csv_colour_list)
        sw_table = sw_table_csv -- copy the CSV table over. this is our work copy
    end
  
    settings_derivative()                -- set variables generated from preset data  
    --dbug (" Window size : "..sw_win_w.."   "..sw_win_h.."\n")
  
    
    create_window()    -- window is drawn for the first time with preset settings
  
    sw_x = sw_origin_x -- initialize drawing coordinates
    sw_y = sw_origin_y
    sw_count_x = 0     -- initialize colum and row counter
    sw_count_y = 0
  
    if generate_colour == 0 then
        preset_text = "Info"
    end
  
    draw_swatches()
    draw_indicate_controls() -- draw bit above colour swatches
  
  
    if generate_colour == 1 then
        draw_parameters()  -- feedback numbers on generated swatch edge parameters
    elseif generate_colour == 0 then
        clear_parameters() -- static colour selection, so just clear that area
    end
    --dbug ("Generated colours. We are rolling\n")

    -- thanks Daxlienre and Heda
    if move_window_to_mouse then ; reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_MOVE_WINDOW_TO_MOUSE_H_M_V_T"),0) ; end
end

function settings_derivative()
    -- setup variables from preset data:
    sw_origin_x  =  sw_border -- start drawing swatches here
    sw_origin_y  =  font_main_h + sw_border + 2
    sw_win_w     =  sw_origin_x + sw_max_x * (sw_w + sw_border)  -- swatch area offset + swatches including border
    sw_win_h     =  sw_origin_y + sw_max_y * (sw_h + sw_border)
    
    if sw_win_w  <  340 then ; sw_win_w = 340; end -- minimum window size to accomodate UI elements
    
    if generate_colour == 0 then
        -- we're using a preset colour table ?
        -- find longest colour description string and store it in text_preset
        -- sw_table 1, 5, 9, etc. contains all the names
        --
        -- shove sw_table[1] in to collection variables and count length
        -- step through sw_table[(i+1)*4] to math.min(#sw_table*0.25)
        -- 
        text_preset =  find_longest_swatch_name(sw_table)
    end
end

  -- this function hooks in to the saved data and retrieves it
  -- check retrieved values
--[[  local e = {}
  e = last_used_settings[0] -- copy in to local array "e"
  local flag = 1 -- we'll assume everything is alright
  if type(e.generate_colour) ~= number then dbug ("Generate colour not a number"); flag=0; end
  if type(e.saturation_max)  ~= number then dbug ("Saturation_max is not a number"); flag=0; end
  if type(e.saturation_min)  ~= number then dbug ("Saturation_min not a number"); flag=0; end
  if type(e.luminance_max)   ~= number then dbug ("Luminance Max not a number"); flag=0; end
  if type(e.luminance_min)   ~= number then dbug ("Luminance min not a number"); flag=0; end
  if type(e.sw_max_x)        ~= number then dbug ("swatch max x not a number"); flag=0; end
  if type(e.sw_max_y)        ~= number then dbug ("swatch max y not a number"); flag=0; end
  if type(e.sw_w)            ~= number then dbug ("swatch width not a number"); flag=0; end
  if type(e.sw_h)            ~= number then dbug ("swatch width not a number"); flag=0; end
  if type(e.sw_border)       ~= number then dbug ("swatch border not a number"); flag=0; end
  if type(e.bg_r)            ~= number then dbug ("background red not a number"); flag=0; end
  if type(e.bg_g)            ~= number then dbug ("background green not a number"); flag=0; end
  if type(e.bg_b)            ~= number then dbug ("background blue not a number"); flag=0; end

  settings_from_preset (e)
end
--]]

-- ==============================
-- //// Main background loop ////
-- ==============================
function runloop()
    -- MOUSE CURSOR POSITION - print colour name in preset area
    -- if we're using a preset colour list
    if generate_colour == 0 then
        mouse.ox,mouse.oy=gfx.mouse_x,gfx.mouse_y
        if (       mouse.ox >= zone_swatch[1]  and mouse.oy >= zone_swatch[2]
            and mouse.ox <= zone_swatch[3]  and mouse.oy <= zone_swatch[4]  ) then
            zone.ox = mouse.ox-sw_origin_x  -- grab the mouse position for swatch zone calc
            zone.oy = mouse.oy-sw_origin_y
            get_colour_swatch()
        -- swatch data in swatch.n .r .g .b
        if swatch.n == swatch_name_last_tooltip then
            -- do nothing
            else
            -- swatch.n contains the relevant name
            draw_preset_area(tostring(swatch.n))
            swatch_name_last_tooltip = swatch.n
        end
        end
    end
    
    -- LEFT MOUSE BUTTON click
    if gfx.mouse_cap&1 == 1 then
        if not mouse.down then
            -- The Reaper action is here
            OnMouseDown()
        end
    elseif mouse.down then 
        OnMouseUp() 
    end

    -- TRACK or ITEM selection? decide the default context only when instantiating the script
    if auto_apply == 1 then
    ---[[
        if reaper.GetCursorContext2(true) == 0 then
            item_apply = 0 ; track_apply = 1
        elseif reaper.GetCursorContext2(true) == 1 then
            item_apply = 1 ; track_apply = 0
        end --]]
    --[[
        if reaper.GetCursorContext() == 0 then
            item_apply = 0 ; track_apply = 1
        elseif reaper.GetCursorContext() == 1 then
            item_apply = 1 ; track_apply = 0
        end --]]

    end

    -- 3 states possible :
    -- (-1) item=1 track=0, 0 item=1 track=1, 1 item=0 track=1, 
    selection_context = (-1) * item_apply + track_apply 
    if last_selection_context ~= selection_context then -- compare to previous state
      --something's changed, let's redraw
      draw_indicate_controls()
    end
    last_selection_context = selection_context
    --]]  
    
    
    -- Swatch zone checks
    -- Mouse + modifiers to change the three parameters
    -- saturnation, maximum luminosity and minimum luminosity
    if generate_colour == 1 then -- only allow this for generated colour lists
        if (gfx.mouse_cap&2 == 2) then-- right-mouse button clicked down
        
            -- SHIFT+Right drag
            if     (gfx.mouse_cap&8 == 8)   then
                --UPPER SATURATION
                saturation_max = math.min(math.max(0, last_saturation_max - mouse.ox_r/gfx.w+gfx.mouse_x/gfx.w), 1);
               
                generate_colourlist_from_hsl(saturation_max, saturation_min, luminance_max, luminance_min)
                draw_swatches()
                draw_parameters()
        
            -- CTRL+Right drag
            elseif (gfx.mouse_cap&4 == 4) then
                --LOWER SATURATION
                saturation_min = math.min(math.max(0, last_saturation_min - mouse.ox_r/gfx.w+gfx.mouse_x/gfx.w), 1);
                
                generate_colourlist_from_hsl(saturation_max, saturation_min, luminance_max, luminance_min)
                draw_swatches()
                draw_parameters()
                
            -- ALT+Right drag
            elseif (gfx.mouse_cap&16 == 16) then
                --LOWER LUMINOSITY
                luminance_min = math.min(math.max(0, last_luminance_min - mouse.ox_r/gfx.w+gfx.mouse_x/gfx.w), 1);
                
                generate_colourlist_from_hsl(saturation_max, saturation_min, luminance_max, luminance_min)
                draw_swatches()
                draw_parameters()
          
            -- no modifier Right click + drag
            else
                --UPPER LUMINOSITY
                luminance_max = math.min(math.max(0, last_luminance_max - mouse.ox_r/gfx.w+gfx.mouse_x/gfx.w), 1);
                
                generate_colourlist_from_hsl(saturation_max, saturation_min, luminance_max, luminance_min)
                draw_swatches()
                draw_parameters()
            
            end
        
        else
            -- setup variables for next pass
            -- last_saturation = saturation
            last_luminance_max = luminance_max
            last_luminance_min = luminance_min
            last_saturation_max = saturation_max
            last_saturation_min = saturation_min
            mouse.ox_r =gfx.mouse_x
            mouse.ox_l =gfx.mouse_y -- in case we want to do up/down stuff
        end  
        if last_gfx_w ~= gfx.w then
            draw_indicate_controls()
            draw_swatches()
            last_gfx_w = gfx.w
        end
        if last_gfx_h ~= gfx.h then -- redraw if we mucked about up and down
            draw_indicate_controls()
            draw_swatches()
            last_gfx_h = gfx.h
        end
    
    elseif generate_colour == 0 then
        -- preset list of colours... so do nothing
        -- draw_preset_area()
    end
    
    gfx.update()
    
    -- checks to keep it running
    local c=gfx.getchar()
    if c >= 0 and c ~= 27 and not doexit then reaper.defer(runloop) -- ESC key pressed or doexit=true, we exit
    elseif c == 27 then
        gfx.quit()
    end
end
-- End of runloop


function colour_swatch_exit ()
    if save_settings_on_exit==1 then
        save_current_settings()
        --dbug ("Settings saved to reaper ini\nQuitting\n")
    end
    gfx.quit()
end


-- ===================
-- == Program Start ==
-- ===================
---[[
gfx.init(window_title, 200, 200) -- this appears to be necessary
colour_swatch_init()
reaper.atexit(colour_swatch_exit)
reaper.defer(runloop)
--]]

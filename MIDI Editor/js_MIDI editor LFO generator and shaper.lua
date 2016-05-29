--[[
 * ReaScript Name:  Xenakios's LFO generator and shaper (Julian mod) - MIDI editor version
 * Description:  LFO generator and shaper - MIDI editor version
 *               Draw fancy LFO curves in REAPER's piano roll.
 * Instructions:  
 *         DRAWING ENVELOPES:
 *         Click in open space to add an envelope point.
 *         Alt-click (or -drag) to remove points
 *         Cntl-click (or -drag) to set all points to the same value.
 *         Right-click to save/load/delete curves.
 *         A curve saved as "default" will be loaded by default at startup.
 *                   
 *         CUSTOMIZATION:
 *         The user can easily add custom shapes to the script - see the instructions in the script.
 *         In addition, the interface colors can be customized in the USER AREA in the script.
 * 
 * Screenshot: 
 * Notes: 
 * Category: 
 * Author: Xenakios (modded by juliansader)
 * Licence: GPL v3
 * Forum Thread:
 * Forum Thread URL: http://forum.cockos.com/showthread.php?t=153348&page=5
 * Version: 0.991
 * REAPER: 5.20
 * Extensions: SWS/S&M 2.8.3
]]

--[[
 Changelog:
 * v0.1
    + Xenakios' Initial Release
 * v0.2
    + Julian's mod
 * v0.3 (2016-05-20)
    + Time selection now works properly with take envelopes when take position is not at start of project.
    + LFO now uses full range of envelopes with different min and max values (such as pitch).
 * v0.4 (2016-05-20)
    + Cntl-click (or -drag) in envelope now sets all points to the same value.
    + Added help text and "?" button.
 * v0.5 (2016-05-21)
    + Prevent slow mouse clicks from activating buttons multiple times.
    + Interface colors now easily customizable.
    + Replaced 'Delay' with 'Phase step', which steps through nodes in shape definition.
    + The LFO generator now inserts an interpolated envelope point at end of time selection.
 * v0.9 (2016-05-22)
    + Saving and loading of curves.
    + New interface look.
 * v0.91 (2016-05-25)
    + Fixed "attempt to get length of a nil value (global 'savedNames')" bug
 * v0.99 (2016-05-27)
    + The MIDI editor version!  
    + Bézier curves are not yet implemented in this v0.99. All REAPER envelope shapes are implemented.
    + Envelope area now resizeable (allowing finer resolution).
    + Alt-drag for quick delete of multiple nodes.
    + Slow start/end shape replaced by Sine in MIDI editor version.
    + Accurate interpolation of Fast start, Fast end and Sine shapes.
    + Curve named "default" will be loaded on startup.
 * v0.991 (2016-05-29(
    + Script does not fail when "Zoom dependent" CC density is selected in Preferences
]]

--  USER AREA:
    --[[ 
    Colors are defined as {red, green, blue, alpha}
    (Values are between 0 and 1)
    
    Default colors are:
    backgroundColor = {0.15, 0.15, 0.15, 1}
    foregroundColor = {0.75, 0.29, 0, 0.8}
    textColor       = {1, 1, 1, 0.7}  
    buttonColor     = {1, 0, 0, 1} 
    hotbuttonColor  = {0, 1, 0, 1}
    shadows         = true
    ]]
    backgroundColor = {0.1, 0.1, 0.15, 1}
    foregroundColor = {0.3, 0.3, 0.8, 0.7}
    textColor       = {1, 1, 1, 0.7}  
    buttonColor     = {1, 0, 1, 1} 
    hotbuttonColor  = {0, 1, 0, 1}
    shadows         = true  
      
    -- If set to false, CCs in channels other than the LFO's channel will not be deleted
    deleteOnlyDrawChannel = true
    
    --[[
    The user can easily add new shapes:
    Simply add the new items to 1) shapeMenu, 2) shapeTable, 4) the list of values
        and 3) the shape_function table, and give the new shape the next number in the 'List of shapes'.
    The functions in the table specify the shapes in terms of a sequence of node points:
        totalSteps = total number of steps in the shape
        amplitude  = Relative amplitude of point (min=-1, max=1).  "false" means that the point 
                     will be skipped (thereby expanding the shape).
        shape      = 0=Linear, 1=Square, 2=Slow start/end (aka sine), 3=Fast start, 4=Fast end (aka parabolic), 5=Bézier
        tension    = Tension of Bézier curve (only relevant if shape == 5.
        linearJump = specifies whether the shape has a discontinuous jump to the other side of the 'center'.
    ]]
                                
shapeMenu = "Bézier (N/A)|Saw down|Saw up|Square|Triangle|Sine|Fast end triangle|Fast start triangle|MwMwMw"
shapeTable = {"Bezier (N/A)", "Saw down", "Saw up", "Square", "Triangle", "Sine", "Fast end triangle", "Fast start triangle", "MwMwMw"}
-- List of shapes:
Bezier = 1
SawDown = 2
SawUp = 3
Square = 4
Triangle = 5
Sine = 6
FastEndTri = 7
FastStartTri = 8
MwMwMw = 9

shape_function = {}

shape_function[Bezier] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % 4 == 0 then return 4, 1, 5, 1, false end
  if cnt % 4 == 1 then return 4, 0, 5, -1, false end
  if cnt % 4 == 2 then return 4, -1, 5, 1, false end
  return 4, 0, 5, -1, false
end

shape_function[SawUp] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  -- The skipped point ("false") are inserted to make period more similar to Bézier shape  
  if cnt % 4 == 0 then return 4, 1, 0, 1, true end
  return 4, false, 0, 1, false
end

shape_function[SawDown] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  -- The skipped points ("false") are inserted to make period more similar to Bézier shape
  if cnt % 4 == 0 then return 4, -1, 0, 1, true end
  return 4, false, 0, 1, false
end

shape_function[Square] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  -- The skipped points ("false") are inserted to make period more equal to Bézier shape
  if cnt % 4 == 0 then return 4, false, 1, 1, false end
  if cnt % 4 == 1 then return 4, -1, 1, 1, false end  
  if cnt % 4 == 2 then return 4, false, 1, 1, false end
  return 4, 1, 1, 1, false
end

shape_function[Triangle] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  -- The skipped point ("false") are inserted to make period equal to Bézier shape
  if cnt % 4 == 0 then return 4, 1, 0, 1, false end
  if cnt % 4 == 1 then return 4, false, 0, 1, false end  
  if cnt % 4 == 2 then return 4, -1, 0, 1, false end
  return 4, false, 0, 1, false
end

shape_function[Sine] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % 4 == 0 then return 4, 1, 2, 1, false end
  if cnt % 4 == 1 then return 4, false, 2, 1, false end
  if cnt % 4 == 2 then return 4, -1, 2, 1, false end
  return 4, false, 2, 1, false
end

shape_function[FastEndTri] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  -- The skipped point ("false") are inserted to make period equal to Bézier shape
  if cnt % 4 == 0 then return 4, 1, 4, 1, false end
  if cnt % 4 == 1 then return 4, false, 4, 1, false end  
  if cnt % 4 == 2 then return 4, -1, 4, 1, false end
  return 4, false, 4, 1, false
end

shape_function[FastStartTri] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  -- The skipped point ("false") are inserted to make period equal to Bézier shape
  if cnt % 4 == 0 then return 4, 1, 3, 1, false end
  if cnt % 4 == 1 then return 4, false, 3, 1, false end  
  if cnt % 4 == 2 then return 4, -1, 3, 1, false end
  return 4, false, 3, 1, false
end

shape_function[MwMwMw] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % 8 == 0 then return 8, 0.5, 0, 1, false end
  if cnt % 8 == 1 then return 8, false, 0, 1, false end
  if cnt % 8 == 2 then return 8, 1, 0, 1, true end
  if cnt % 8 == 3 then return 8, false, 0, 1, false end
  if cnt % 8 == 4 then return 8, -0.5, 0, 1, false end
  if cnt % 8 == 5 then return 8, false, 0, 1, false end
  if cnt % 8 == 6 then return 8, -1, 0, 1, true end
  if cnt % 8 == 7 then return 8, false, 0, 1, false end
end


---------------------------------------------
-- Some global constants used in Julian's mod
shapeSelected = 6 -- Starting shape
commandID = reaper.NamedCommandLookup("_BR_ME_ENV_CURVE_TO_CC_CLEAR")
sliderHeight = 28
borderWidth = 10
envHeight = 190
initXsize = 209 --300 -- Initial sizes for the GUI
initYsize = borderWidth + sliderHeight*10 + envHeight + 35
envYpos = borderWidth+sliderHeight*10+5
-- The Clip slider and value in the original code
--     do not appear to have any effect, 
--     so the slider was replaced by the "Real-time copy to CC?" 'slider',
--     and the value was replaced by this constant
clip = 1

helpText = "\n\nDRAWING ENVELOPES:"
         .."\n\nClick in open space to add an envelope point."
         .."\n\nAlt-click (or -drag) to remove points."
         .."\n\nCntl-click (or -drag) to set all points to the same value."
         .."\n\nRight-click to save/load/delete curves."
         .."\n\nA curve saved as 'default' will be loaded by default."
         .."\n\nCUSTOMIZATION:"
         .."\n\nThe user can easily add custom shapes to the script - see the instructions in the script."
         .."\n\nIn addition, the interface colors can be customized in the USER AREA in the script."

-- laneTypes         
CC7BIT = 0
CHANPRESSURE = 1
PITCH = 2
CC14BIT = 3

-- For 7-bit lanes, will later be divided by 128
minv = 0
maxv = 16383
---------------------------------------------

egsliders={}

notevalues={{1,8,"32nd"},
            {1,5,"16th quintuplet"},
            {1,4,"16th"},
            {1,3,"8th triplet"},
            {1,2,"8th"},
            {6,8,"8th dotted"},
            {4,5,"4th quintuplet"},
            {1,1,"4th"},
            {6,4,"4th dotted"},
            {4,2,"Half"},
            {4,1,"Whole"}}
            
use_note_rates=false            

function make_slider(x,y,w,h,val,name,valcb)
  slider={}
  slider.x=function() return x end
  slider.y=function() return y end
  -- gfx.w-60 was replaced by gfx.w-20 since the column of buttons was removed
  slider.w=function() return gfx.w-20 end
  slider.h=function() return 20 end
  slider.value=val
  slider.valcb=valcb
  slider.name=name
  slider.type="Slider"
  slider.env_enabled=false
  slider.envelope= {{ 0.0, val }, 
                    --{ 0.25, val } , -- Two of the starting nodes were
                    --{ 0.75 ,val } , --   removed to simple ramp simpler.
                    { 1.0,val }}
  slider.OnMouse=function(theslider, whichevent, x, y, extra) 
      --reaper.ShowConsoleMsg(tostring(theslider).." "..x.." "..y.."\n") 
  end
  return slider
end

---------------------------------------------------------------
-- Julian's mod: these new "make_" functions are basically just 
--    copies of the original "make_slider" function, but with
--    new "type".  Irrelevant stuff such as slider.envelope were left
--    untouched in case there is a reference to these stuff in the
--    rest of the code. 
function make_radiobutton(x,y,w,h,val,name,valcb)
  slider={}
  slider.x=function() return x end
  slider.y=function() return y end
  slider.w=function() return gfx.w-20 end
  slider.h=function() return 20 end
  slider.value=val
  slider.valcb=valcb
  slider.name=name
  slider.type="Button"
  slider.env_enabled=false
  slider.envelope= {{ 0.0, val },
                    --{ 0.25, val } , 
                    --{ 0.75 ,val } , 
                    { 1.0,val }}
  slider.OnMouse=function(theslider, whichevent, x, y, extra) 
      --reaper.ShowConsoleMsg(tostring(theslider).." "..x.." "..y.."\n") 
    end
  return slider
end -- function make_radiobutton

function make_menubutton(x,y,w,h,val,name,valcb)
  slider={}
  slider.x=function() return x end
  slider.y=function() return y end
  slider.w=function() return gfx.w-20 end
  slider.h=function() return 20 end
  slider.value=val
  slider.valcb=valcb
  slider.name=name
  slider.type="Menu"
  slider.env_enabled=false
  slider.envelope= {{ 0.0, val }, 
                    --{ 0.25, val } , 
                    --{ 0.75 ,val } , 
                    { 1.0,val }}
  slider.OnMouse=function(theslider, whichevent, x, y, extra) 
      --reaper.ShowConsoleMsg(tostring(theslider).." "..x.." "..y.."\n") 
    end
  return slider
end -- function make_menubutton

function make_question(x,y,w,h,val,name,valcb)
  slider={}
  slider.x=function() return x end
  slider.y=function() return y end
  slider.w=function() return gfx.w-20 end
  slider.h=function() return 20 end
  slider.value=val
  slider.valcb=valcb
  slider.name=name
  slider.enabled = false
  slider.type="Question"
  slider.env_enabled=false
  slider.envelope= {{ 0.0, val }, 
                    --{ 0.25, val } , 
                    --{ 0.75 ,val } , 
                    { 1.0,val }}
  slider.OnMouse=function(theslider, whichevent, x, y, extra) 
      --reaper.ShowConsoleMsg(tostring(theslider).." "..x.." "..y.."\n") 
    end
  return slider
end -- function make_question

-- End new functions -------------------------------------
----------------------------------------------------------

function make_envelope(x,y,w,h,assocslider)
  result={}
  result.x=function() return x end
  result.y=function() return y end
  result.w=function() return gfx.w-20 end
  result.h=function() return h+gfx.h-initYsize end
  
  result.type="Envelope"
  result.hotpoint=0
  result.envelope=assocslider.envelope
  result.name=assocslider.name
  return result
end

-- The column of buttons in original release was removed,
--     so this function is not necessary any more
--[[
function make_button(x,y,w,h,click_cb)
  result={}
  result.x=function() return x end
  result.y=function() return y end
  result.w=function() return w end
  result.h=function() return h end
  result.type="Button"
  result.name="MyButton"
  result.OnClick=click_cb
  result.checked=true
  return result
end
]]
function bound_value(minval, val, maxval)
    if val<minval then return minval end
    if val>maxval then return maxval end
    return val
end

function quantize_value(val, numsteps)
    stepSize = math.floor(0.5 + (maxv-minv)/numsteps)
    return(stepSize * math.floor(0.5 + val/stepSize))
    --return 1.0/numsteps*math.floor(val*numsteps)
end

-- This function has been removed since BR_EnvGetProperties is more accurate
--[[
envelope_ranges={["Volume"] = {0.0,2.0}, ["Volume (Pre-FX)"] = {0.0,2.0},
                 ["Pan"] = {-1.0,1.0}, ["Pan (Pre-FX)"] = {-1.0,1.0}, ["Playrate"]={0.1,4.0} }

function get_envelope_range(env)
  rv, name=reaper.GetEnvelopeName(env, "")
  if rv==true then
    if envelope_ranges[name]~=nil then 
      return envelope_ranges[name][1],envelope_ranges[name][2] end
    --if name=="Volume" or name=="Volume (Pre-FX)" then return 0.0,2.0 end
    --if name=="Pan" or name=="Pan (Pre-FX)" then return -1.0,1.0 end
  end
  return 0.0,1.0
end
]]

function setColor(colorTable)
    gfx.r = colorTable[1]
    gfx.g = colorTable[2]
    gfx.b = colorTable[3]
    gfx.a = colorTable[4]
end

function is_in_rect(xcora,ycora,xa,ya,wa,ha)
if (xcora>=xa and xcora<xa+wa and ycora>=ya and ycora<ya+ha) then
  return true
end
return false
end

function slider_to_value(slid)
  
end

function slider_to_string(slid)
    if slid.name=="Quant steps" then 
        if slid.value == 1 then return("None")
        else return(math.ceil(3+slid.value*125))
        end
    elseif slid.name=="Phase step" then 
        local totalSteps, _, _, _, _ = shape_function[shapeSelected](0)
        local phaseStep = math.floor(slid.value * totalSteps)
        return tostring(phaseStep) .."/".. tostring(totalSteps)
    else
       return tostring((math.floor(0.5 + slid.value*100))/100)
    end
end

function draw_slider(slid)
    if slid.type == "Slider" then
        local imgw = 32
        local imgh = 25
        setColor(textColor)
        gfx.x=slid.x()+3
        gfx.y=slid.y() --+2
        gfx.drawstr(slid.name .. ": " .. slider_to_string(slid))
        gfx.a=gfx.a - 0.6;
        --gfx.rect(slid.x(),slid.y()+15,slid.w(),2,true)
        local thumbx=slid.x()+(slid.w()-(imgw/1))*slid.value
        if shadows == true then
            setColor({0,0,0,1})
            gfx.rect(slid.x()+1,slid.y()+16,slid.w()*slid.value,7,true)  
        end
        setColor(foregroundColor)
        gfx.rect(slid.x(),slid.y()+15,slid.w()*slid.value,7,true)
        --gfx.rect(thumbx,slid.y(),imgw,imgh,true)  
    
    elseif slid.type == "Button" then
        function fillRoundRect(x,y,w,h,r)
            if r>w/2 or r>h/2 then r=math.floor(min(w/2, h/2)) end
            for i = 0, r-1 do
                gfx.line(x+r-i, y+i, x+w-1-r+i, y+i, 0)
                gfx.line(x+r-i, y+h-1-i, x+w-1-r+i, y+h-1-i, 0)
            end
            for i = y+r, y+h-1-r do
                gfx.line(x, i, x+w-1, i, 0)
            end
        end
        stringw,stringh = gfx.measurestr(slid.name)
        ampw,amph = gfx.measurestr("Amplitude")
        if slid.name == egsliders[100].name then
            --local stringw,stringh = gfx.measurestr("Amplitude")
            if shadows == true then
                setColor({0,0,0,1})
                --gfx.rect(gfx.w/2-ampw/2-5, slid.y()-1, ampw+12, stringh+7, true)
                fillRoundRect(gfx.w/2-ampw/2-5, slid.y()-1, ampw+12, stringh+7, 1)
            end
            setColor(foregroundColor)
            gfx.a = gfx.a*0.9
            --gfx.a = gfx.a+0.1
            --gfx.rect(gfx.w/2-ampw/2-6, slid.y()-2, ampw+12, stringh+7, true) --(slid.x(),slid.y()-2,stringw+6,stringh+8,true)
            fillRoundRect(gfx.w/2-ampw/2-6, slid.y()-2, ampw+12, stringh+7, 1)
            setColor(textColor)
            gfx.x=gfx.w/2-stringw/2 --slid.x()+3
            gfx.y=slid.y()+2
            gfx.drawstr(slid.name)
        else
            setColor(textColor)
            gfx.x=gfx.w/2-stringw/2 --slid.x()+3
            gfx.y=slid.y()+2
            gfx.drawstr(slid.name)
        end
    
    elseif slid.type == "Menu" then
        setColor(textColor)
        gfx.x=slid.x()+3
        gfx.y=slid.y()+2
        gfx.drawstr(slid.name)
        if shadows == true then
            setColor({0,0,0,1})
            gfx.x=slid.x()+4+gfx.measurestr(slid.name)+gfx.measurestr("w")
            gfx.y=slid.y()+3
            gfx.drawstr(shapeTable[shapeSelected])
        end
        setColor(foregroundColor)
        gfx.x=slid.x()+3+gfx.measurestr(slid.name)+gfx.measurestr("w")
        gfx.y=slid.y()+2
        gfx.a = gfx.a + 0.3
        gfx.drawstr(shapeTable[shapeSelected])
    
    elseif slid.type == "Question" then
        setColor(textColor)
        gfx.x=slid.x()+3
        gfx.y=slid.y()+2
        gfx.drawstr(slid.name)
        if shadows == true then
            gfx.x=slid.x()+4+gfx.measurestr(slid.name)+gfx.measurestr("w")
            gfx.y=slid.y()+3
            setColor({0,0,0,1})
            if slid.enabled == true then
                gfx.drawstr("Enabled")
            else
                gfx.drawstr("Disabled")      
            end
        end
        gfx.x=slid.x()+3+gfx.measurestr(slid.name)+gfx.measurestr("w")
        gfx.y=slid.y()+2
        setColor(foregroundColor)
        gfx.a = gfx.a + 0.3  
        if slid.enabled == true then
            gfx.drawstr("Enabled")
        else
            gfx.drawstr("Disabled")      
        end    
    end    
        
end

-- The column of buttons in original release was removed,
--     so this function is not necessary any more
--[[
function draw_button(but)
  if but.type~="Button" then return end
  gfx.r=1.0; gfx.g=1.0; gfx.b=1.0; gfx.a=1.0;
  gfx.rect(but.x(),but.y(),but.w(),but.h(),false)
  if but.checked==true then
    gfx.line(but.x(),but.y(),but.x()+but.w(), but.y()+but.h())
    gfx.line(but.x(),but.y()+but.h(),but.x()+but.w(),but.y())
  end
end
]]

function draw_envelope(env,enabled)

    -- Draw Envelope title
    if env.type~="Envelope" then return end
    local title=env.name
    setColor(textColor)
    title = "Envelope: " .. title
    gfx.x = gfx.w/2 - gfx.measurestr(title)/2
    gfx.y = gfx.h - 23
    gfx.drawstr(title)
    
    -- draw "?"
    if shadows == true then
        gfx.x = gfx.w - 19
        gfx.y = gfx.h - 22
        setColor({0,0,0,1})
        gfx.drawstr("?")
    end
    setColor(foregroundColor)
    gfx.a = 1
    gfx.y = gfx.h - 23
    gfx.x = gfx.w - 20 --gfx.measurestr("?")
    gfx.drawstr("?")
    
    setColor(backgroundColor)
    gfx.r = gfx.r/3; gfx.g = gfx.g/3; gfx.b = gfx.b/3
    gfx.rect(env.x(), env.y(), env.w(), env.h())

        
    --env.h = function() return(envHeight+gfx.h-initYsize) end
    
    local xcor0=0.0
    local ycor0=0.0
    local i=1
    for key,envpoint in pairs(env.envelope) do
        local xcor = env.x()+envpoint[1]*env.w()
        local ycor = env.y()+(1.0-envpoint[2])*env.h()
        
        if i>1 then
            --reaper.ShowConsoleMsg(i.." ")
            setColor(textColor)
            gfx.line(xcor0,ycor0,xcor,ycor,true)
        end
        xcor0=xcor
        ycor0=ycor
        
        if env.hotpoint==i then
            setColor(hotbuttonColor)
        else
            setColor(buttonColor)
        end
        i=i+1
        gfx.circle(xcor,ycor,5.0,true,true)
    end
end

function get_hot_env_point(env,mx,my)
  for key,envpoint in pairs(env.envelope) do
    local xcor = env.x()+envpoint[1]*env.w()
    local ycor = env.y()+(1.0-envpoint[2])*env.h()
    if is_in_rect(mx,my,xcor-5,ycor-5,10,10) then return key end
  end
 
  return 0
end

function get_env_interpolated_value(env,x)
  if #env==0 then return 0.0 end
  if x<env[1][1] then return env[1][2] end
  if x>env[#env][1] then return env[#env][2] end
  local i=1
  for key,envpoint in pairs(env) do
    if x>=envpoint[1] then
      nextpt=env[key+1]
      if nextpt==nil then nextpt=envpoint end
      if x<nextpt[1] then
        local timedelta=nextpt[1]-envpoint[1]
        if timedelta<0.0001 then timedelta=0.0001 end
        local valuedelta=nextpt[2]-envpoint[2]
        local interpos=(x-envpoint[1])
        return envpoint[2]+valuedelta*((1.0/timedelta)*interpos)
      end
    end
    i=i+1
  end
  return 0.0
end

function sort_envelope(env)
  table.sort(env,function(a,b) return a[1]<b[1] end)
end


---------------------------------------------------------------------------------------------------
-- The important function that generates the nodes
function generate(freq,amp,center,phase,randomness,quansteps,tilt,fadindur,fadoutdur,ratemode,clip)

    math.randomseed(1)
       
    tableVals = nil
    tableVals = {}        
  
    time=time_start
  
    --local freqhz=1.0+7.0*freq^2.0
    local nvindex=math.floor(1+(#notevalues-1)*freq)
    local dividend=notevalues[nvindex][1]
    local divisor=notevalues[nvindex][2]
    --reaper.ShowConsoleMsg(dividend .. " " .. divisor .. "\n")
    local freqhz=1.0
    if ratemode>0.5 then
        freqhz=(reaper.Master_GetTempo()/60.0)*1.0/(dividend/divisor)
    else
        freqhz=0.1+(31.9*freq^2.0)
    end    
    
    local timeseldur=time_end-time_start
    local fadoutstart_time = time_end-time_start-timeseldur*fadoutdur
    
    local totalSteps, _, _, _, _ = shape_function[shapeSelected](0)
    local phaseStep = math.floor(phase * totalSteps)
  
    local segshape=-1.0+2.0*tilt
    local ptcount=0
        
    tableNodes = nil
    tableNodes = {}
    ---------------------------------------------------------------------------------------------------
    -- The main loop that inserts points.
    -- In order to interpolate the closing envelope point that will be inserted at end_time,
    --    this loop must actually progress one step beyond the end time.  The point beyond end_time 
    --    of course not be inserted, but will only be used to calculate the interpolated closing point.
    -- while isBeyondEnd == false do
    repeat
        time_to_interp = 1.0/timeseldur*(time-time_start)
        freq_norm_to_use=get_env_interpolated_value(egsliders[1].envelope,time_to_interp)
        freqhz=0.2+(15.8*freq_norm_to_use^2.0)
        
        -- fade goes to infinity when trying to calculate point beyond end_time, 
        --    so use fadeHackTime when calculating the point efter end_time.
        fade_gain = 1.0
        fadeHackTime = math.min(time, time_end) 
        if fadeHackTime - time_start < timeseldur*fadindur then
            fade_gain=1.0/(timeseldur*fadindur)*(fadeHackTime - time_start)
        end
        if fadeHackTime - time_start > fadoutstart_time then
            fade_gain=1.0-(1.0/(timeseldur*fadoutdur)*(fadeHackTime - fadoutstart_time - time_start))
        end
              
        ---------------------     
        -- Get info for point
        totalSteps, val, pointShape, pointTension, linearJump = shape_function[shapeSelected](ptcount-phaseStep)
        
        -- Bézier curves are not yet implemented, so replace Bézier with Linear
        if pointShape == 5 then pointShape = 0 end
        
        -- Usually "false" values are skipped, but not if it is the very first point
        --   Try to interpolate
        if ptcount == 0 and val == false then
            for i = 1, totalSteps-1 do
                _, nextVal, nextShape, nextTension, nextJump = shape_function[shapeSelected](ptcount-phaseStep+i)
                if nextVal ~= false then n=i break end
            end
            for i = 1, totalSteps-1 do
                _, prevVal, prevShape, prevTension, prevJump = shape_function[shapeSelected](ptcount-phaseStep-i)
                if prevVal ~= false then p=i break end
            end
            if nextVal ~= false and prevVal ~= false then -- if entire shape is "false", then don't bother
                if prevJump then prevVal=-prevVal end
                linearJump = false
                if prevShape == 1 then -- square
                    val = prevVal
                elseif prevShape == 2 then -- sine
                    val = prevVal + (nextVal-prevVal)*(1-math.cos(math.pi * p/(p+n)))/2
                    pointShape = 2 + p/(p+n)
                elseif prevShape == 3 then -- Fast start (aka inverse parabolic)
                    val = nextVal + (prevVal-nextVal)*((n/(p+n))^3)
                    pointShape = 3 + p/(p+n)
                elseif prevShape == 4 then -- Fast end (aka parabolic)
                    val = prevVal + (nextVal-prevVal)*((p/(p+n))^3)
                    pointShape = 4 + p/(p+n)                
                else -- Linear or Bézier: This interpolation will only be accurate for linear shapes
                    val = prevVal + (nextVal-prevVal) * p / (p+n)
                end
            else
                return(0) -- entire shape is false
            end
        
        end  
               
        if val == false then -- Skip point
            time=time+(1.0/freqhz/4.0)
            ptcount=ptcount+1   
        else -- Point will be inserted. Must first calculate value
            -- If linearJump, then oppositeVal must also be calculated               
            if linearJump == true then oppositeVal = -val end
          
            --if time_to_interp<0.0 or time_to_interp>1.0 then
            --  reaper.ShowConsoleMsg(time_to_interp.." ") end
            amp_to_use = get_env_interpolated_value(egsliders[2].envelope,time_to_interp)
            --if amp_to_use<0.0 or amp_to_use>1.0 then reaper.ShowConsoleMsg(amp_to_use.." ") end
            val=0.5+(0.5*amp_to_use*fade_gain)*val
            local center_to_use=get_env_interpolated_value(egsliders[3].envelope,time_to_interp)
            local rangea=maxv-minv
            val=minv+((rangea*center_to_use)+(-rangea/2.0)+(rangea/1.0)*val)
            z=(2*math.random()-1)*randomness*(maxv-minv)/2
            val=val+z
            local tilt_ramp = 1.0/(time_end-time_start) * (time-time_start)
            local tilt_amount = -1.0+2.0*tilt
            local tilt_delta = -tilt_amount+(2.0*tilt_amount)*tilt_ramp
            --[[val=val+tilt_delta
            local num_quansteps=3+quansteps*61
            if num_quansteps<64 then
                val=quantize_value(val,num_quansteps)
            end]]
            --[[if quansteps ~= 1 then
                val=quantize_value(val,3 + math.ceil(quansteps*125))
            end]]
            
            instime=time
            
            val=bound_value(minv,val,maxv)
            --val = reaper.ScaleToEnvelopeMode(envscalingmode, val)
            local tension = segshape*pointTension  
            
            local insPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, instime)
            if linearJump == true then
                oppositeVal=0.5+(0.5*amp_to_use*fade_gain)*oppositeVal
                oppositeVal=minv+((rangea*center_to_use)+(-rangea/2.0)+(rangea/1.0)*oppositeVal)
                oppositeVal=oppositeVal-z
                --[[if quansteps ~= 1 then
                    val=quantize_value(val,3 + math.ceil(quansteps*125))
                end]]
                oppositeVal=bound_value(minv,oppositeVal,maxv)
                local tension = segshape*pointTension
                table.insert(tableNodes, {PPQ = insPPQ, 
                                   value = val, 
                                   shape = 0, 
                                   tension = 0})
                table.insert(tableNodes, {PPQ = insPPQ,
                                   value = oppositeVal, 
                                   shape = pointShape, 
                                   tension = tension})
            else
                table.insert(tableNodes, {PPQ = insPPQ, 
                                   value = val, 
                                   shape = pointShape, 
                                   tension = tension})       
            end

            time=time+(1.0/freqhz/4.0)
            ptcount=ptcount+1
        end -- if val ~= false
       
    until instime > time_end
    --end -- while time<=gen_end_time
    
    --if last_used_parms==nil then last_used_params={"}
    --last_used_params[env]={freq,amp,center,phase,randomness,quansteps,tilt,fadindur,fadoutdur,ratemode,clip}
    
    --reaper.Envelope_SortPoints(env)
    --tableNodes:sort(sortPPQ)
    
end

function exit()
    gfx.quit()
    
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
        reaper.SetToggleCommandState(sectionID, cmdID, 0)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
    
    --[[    
    if laneType == CC7BIT then
        reaper.Undo_OnStateChange("LFO tool: 7-bit CC lane ".. clickedLane, -1)
    elseif laneType == CHANPRESSURE then
        reaper.Undo_OnStateChange("LFO tool: channel pressure", -1)
    elseif laneType == CC14BIT then
        reaper.Undo_OnStateChange("LFO tool: 14 bit CC lanes ".. 
                                  tostring(clickedLane-256) .. "/" .. tostring(clickedLane-224))
    elseif laneType == PITCH then
        reaper.Undo_OnStateChange("LFO tool: pitchwheel", -1)
    end
    ]]
    reaper.Undo_OnStateChange("LFO tool: ".. clickedLaneString, -1)
end -- function exit() 


-------------------------------------------------------------------------
-- The function that gets user inputs from the GUI and then draws the CCs
captured_control=nil
was_changed=false
already_added_pt=false
already_removed_pt=false
last_mouse_cap=0

function update()
    local char = gfx.getchar()
    if char<0 or char==27 then return end -- Tests whether GUI has been closed, or Esc has been pressed
    time_start_new, time_end_new = reaper.GetSet_LoopTimeRange(false, false, 0.0, 0.0, false)  
    if time_start_new ~= time_start or time_end_new ~= time_end then 
        return(0) 
    end
    --if reaper.GetExtState("LFO Generator", "isRunning") == "quit" then return(0) end
    
    
    setColor(backgroundColor)
    gfx.rect(0,0,gfx.w,gfx.h,true)
    
    --[[curenv=reaper.GetSelectedEnvelope(0)
    --if curenv==nil and last_envelope~=nil then curenv=last_envelope end
    if curenv~=last_envelope then 
      last_envelope=curenv
      if last_used_params[curenv]~=nil then
        for i=1, #egsliders do 
          if egsliders[i].type=="Slider" then
            --egsliders[i].value=last_used_params[curenv][i]
          end
        end
      end
    end]]

    if gfx.mouse_cap==0 then 
        captured_control=nil
        already_added_pt=false 
        already_removed_pt=false
        firstClick = true
        --[[if was_changed==true then
          reaper.Undo_OnStateChangeEx("Generate envelope points",1,-1) 
        end]]
        was_changed=false
    end
    
  
    if (gfx.mouse_cap == 1 
    and gfx.mouse_x > gfx.w-22 and gfx.mouse_y > gfx.h-22) 
    and firstClick == true then
        firstClick = false
        reaper.ShowConsoleMsg(helpText)
    end  
  
  
    local dogenerate=false
    for key,tempcontrol in pairs(egsliders) do
      --if key>=200 and tempcontrol.type=="Button" then reaper.ShowConsoleMsg(tostring(tempcontrol).." ") end
      if is_in_rect(gfx.mouse_x,gfx.mouse_y,tempcontrol.x(),tempcontrol.y(),tempcontrol.w(),tempcontrol.h()) then
        if gfx.mouse_cap&1==1 and captured_control==nil then
          captured_control=tempcontrol
        
        end
        --[[
        if tempcontrol.type=="Slider" and gfx.mouse_cap==2 
          and (tempcontrol.name=="Rate" or tempcontrol.name=="Amplitude") then
          gfx.x=gfx.mouse_x
          gfx.y=gfx.mouse_y
          local menuresult=gfx.showmenu("Toggle envelope active|Show envelope")
          if menuresult==1 then
            if tempcontrol.env_enabled==false then
              tempcontrol.env_enabled=true else
              tempcontrol.env_enabled=false
            end
          end
          if menuresult==2 then
            egsliders[100].envelope=tempcontrol.envelope
            egsliders[100].name=tempcontrol.name
          end
        end
        ]]
      
      
        if gfx.mouse_cap==1 and (tempcontrol.name=="Rate" or tempcontrol.name=="Amplitude" or tempcontrol.name=="Center") then
          egsliders[100].envelope=tempcontrol.envelope
          egsliders[100].name=tempcontrol.name
        end  
        
        if gfx.mouse_cap==1 and (tempcontrol.name=="Real-time copy to CC?") 
        and firstClick == true
        then
          tempcontrol.enabled = not tempcontrol.enabled
          firstClick = false
          dogenerate = true
        end 
        
        if gfx.mouse_cap == 1 and tempcontrol.name == "LFO shape?" then
            gfx.x = gfx.mouse_x
            gfx.y = gfx.mouse_y
            retval = gfx.showmenu(shapeMenu)
            if retval ~= 0 then shapeSelected = retval end
            dogenerate = true
        end
      
        if gfx.mouse_cap == 5 and tempcontrol.type == "Envelope" then
            pt_y = 1.0/tempcontrol.h()*(gfx.mouse_y-tempcontrol.y())
            for i = 1, #tempcontrol.envelope do
                tempcontrol.envelope[i][2] = 1 - pt_y
            end
            dogenerate = true
        end
        
        if tempcontrol.type=="Envelope" then
          if gfx.mouse_cap==0 or gfx.mouse_cap==17 then
            tempcontrol.hotpoint=get_hot_env_point(tempcontrol,gfx.mouse_x,gfx.mouse_y)
          end
          if gfx.mouse_cap&1 == 1 or gfx.mouse_cap&2 == 2 then
              firstClick = false
          end
          if tempcontrol.hotpoint==0 and gfx.mouse_cap==1 and already_added_pt==false then
            --reaper.ShowConsoleMsg("gonna add point ")
            local pt_x = 1.0/tempcontrol.w()*(gfx.mouse_x-tempcontrol.x())
            local pt_y = 1.0/tempcontrol.h()*(gfx.mouse_y-tempcontrol.y())
            tempcontrol.envelope[#tempcontrol.envelope+1]={ pt_x,1.0-pt_y }
            dogenerate=true
            already_added_pt=true
            sort_envelope(tempcontrol.envelope)
          end
          --if already_removed_pt==false and tempcontrol.hotpoint>0 and gfx.mouse_cap == 17  then
          if tempcontrol.hotpoint>0 and gfx.mouse_cap == 17 then
            table.remove(tempcontrol.envelope,tempcontrol.hotpoint)
            dogenerate=true
            --already_removed_pt=true
            --reaper.ShowConsoleMsg("remove pt "..tempcontrol.hotpoint)
          end       
          if tempcontrol==captured_control and tempcontrol.hotpoint>0 and gfx.mouse_cap==1 then
            local pt_x = 1.0/tempcontrol.w()*(gfx.mouse_x-captured_control.x())
            local pt_y = 1.0/captured_control.h()*(gfx.mouse_y-captured_control.y())
            ept = captured_control.envelope[captured_control.hotpoint]
            ept[1]=pt_x
            ept[2]=1.0-pt_y
            dogenerate=true
            --reaper.ShowConsoleMsg("would drag pt "..tempcontrol.hotpoint.."\n")
          end
        end
      end
      local env_enabled=false
      if captured_control~=nil then
          if captured_control.OnMouse~=nil then 
              --captured_control.OnMouse(captured_control, "drag", gfx.mouse_x,gfx.mouse_y, nil)
          end
          if captured_control.type=="Slider" then
              if captured_control.envelope==egsliders[100].envelope then 
                   env_enabled=captured_control.env_enabled
              end
              local new_value=1.0/captured_control.w()*(gfx.mouse_x-captured_control.x())
              new_value=bound_value(0.0,new_value,1.0)
              --reaper.ShowConsoleMsg(captured_control.type .. " ")
              if captured_control.value~=new_value then
                  dogenerate=true
                  captured_control.value=new_value
              end
          end
      end
      draw_slider(tempcontrol)
      draw_envelope(tempcontrol,env_enabled)
    end  
  
    ---------------------------------------------
    -- If right-click, show save/load/delete menu
    if gfx.mouse_cap == 2 then
    
        --reaper.DeleteExtState("LFO generator", "savedCurves", true) -- delete the ExtState
    
        -------------------------------
        -- First, try to load all saved curves
        getSavedCurvesAndNames()
        
        loadStr = ""
        if savedNames ~= nil and #savedNames > 0 then
  
            loadStr = "||>Load curve"
            for i = 1, #savedNames do
                loadStr = loadStr .. "|" .. savedNames[i]
            end
            
            loadStr = loadStr .. "|<||>Delete curve"
            for i = 1, #savedNames do
                loadStr = loadStr .. "|" .. savedNames[i] 
            end
            loadStr = loadStr .. "|<||"           
        end
        
        saveLoadString = "Save curve" .. loadStr      
        
        
        ----------------------------------------
        -- Show save/load/delete menu
        gfx.x = gfx.mouse_x; gfx.y = gfx.mouse_y
        menuSel = gfx.showmenu(saveLoadString)
        
        if menuSel == 0 then  
            -- do nothing
            
        ------------------------
        -- Save curve
        elseif menuSel == 1 then
            repeat
                retval, curveName = reaper.GetUserInputs("Save curve", 1, "Curve name (no | or ,)", "")
            until retval == false or (curveName:find("|") == nil and curveName:find(",") == nil and curveName:len()>0)
            
            if retval ~= false then
                saveString = curveName
                for i = 0, 10 do
                    if egsliders[i] == nil then -- skip
                    elseif egsliders[i].name == "LFO shape?" then saveString = saveString .. ",LFO shape?," .. tostring(shapeSelected)
                    elseif egsliders[i].name == "Real-time copy to CC?" then saveString = saveString .. ",Real-time copy to CC?," .. tostring(egsliders[i].enabled) 
                    elseif egsliders[i].name == "Phase step" then saveString = saveString .. ",Phase step," .. tostring(egsliders[i].value)
                    elseif egsliders[i].name == "Randomness" then saveString = saveString .. ",Randomness," .. tostring(egsliders[i].value)
                    elseif egsliders[i].name == "Quant steps" then saveString = saveString .. ",Quant steps," .. tostring(egsliders[i].value)
                    elseif egsliders[i].name == "Bezier shape" then saveString = saveString .. ",Bezier shape," .. tostring(egsliders[i].value)
                    elseif egsliders[i].name == "Fade in duration" then saveString = saveString .. ",Fade in duration," .. tostring(egsliders[i].value)
                    elseif egsliders[i].name == "Fade out duration" then saveString = saveString .. ",Fade out duration," .. tostring(egsliders[i].value)
                    elseif egsliders[i].name == "Rate mode" then saveString = saveString .. ",Rate mode," .. tostring(egsliders[i].value)
                    elseif egsliders[i].name == "Rate" then 
                        saveString = saveString .. ",Rate,"  .. tostring(#egsliders[i].envelope)
                        for p = 1, #egsliders[i].envelope do
                            saveString = saveString .. "," .. tostring(egsliders[i].envelope[p][1]) .. "," 
                                                           .. tostring(egsliders[i].envelope[p][2])
                        end
                    elseif egsliders[i].name == "Center" then 
                        saveString = saveString .. ",Center,"  .. tostring(#egsliders[i].envelope)
                        for p = 1, #egsliders[i].envelope do
                            saveString = saveString .. "," .. tostring(egsliders[i].envelope[p][1]) .. "," 
                                                           .. tostring(egsliders[i].envelope[p][2])
                        end
                    elseif egsliders[i].name == "Amplitude" then 
                        saveString = saveString .. ",Amplitude,"  .. tostring(#egsliders[i].envelope)
                        for p = 1, #egsliders[i].envelope do
                            saveString = saveString .. "," .. tostring(egsliders[i].envelope[p][1]) .. "," 
                                                           .. tostring(egsliders[i].envelope[p][2])
                        end
                    end
                end -- for i = 0, 11
                
                if reaper.HasExtState("LFO generator", "savedCurves") then
                    reaper.SetExtState("LFO generator", "savedCurves", saveString .. "|" .. reaper.GetExtState("LFO generator", "savedCurves"), true)
                else
                    reaper.SetExtState("LFO generator", "savedCurves", saveString .. "|", true)
                end
                
                
            end -- if retval ~= false
    
        elseif savedNames ~= nil and type(savedNames) == "table" and #savedNames > 0 then
            -----------------------------------
            -- delete curve
            if 1+#savedNames < menuSel then 
            
                --retval, curveName = reaper.GetUserInputs("Delete curve", 1, "Curve name", "")
                extStateString = ""
                for i = 1, #savedCurves do
                    if i ~= menuSel - (#savedNames+1) then
                        extStateString = savedCurves[i] .. "|" .. extStateString
                    end
                end
                if extStateString == "" then 
                    reaper.DeleteExtState("LFO generator", "savedCurves", true)
                else
                    reaper.SetExtState("LFO generator", "savedCurves", extStateString, true)
                end
                
            ---------------------------------------------------
            -- load curve 
            elseif 1 < menuSel and menuSel <= 1+#savedNames then 
            
                if savedNames ~= nil and type(savedNames) == "table" and #savedNames > 0 then
                    loadCurve(menuSel-1)
                    dogenerate = true
                end
            end    
            
        end -- if menuSel == ...  
    
    end -- if gfx.mouse_cap == 2
    
    
    if dogenerate==true then
        generateAndDisplay()      
    end -- if dogenerate==true
    
    last_mouse_cap=gfx.mouse_cap
    gfx.update()
    reaper.defer(update)
end

--------------------------------

function generateAndDisplay()
    generate(egsliders[1].value,
        egsliders[2].value,
        egsliders[3].value,
        egsliders[4].value,
        egsliders[5].value,
        egsliders[6].value,
        egsliders[7].value,
        egsliders[8].value,
        egsliders[9].value,
        0, --egsliders[10].value,
        clip)
    was_changed=true
    
    -- Draw the envelope in CC lane
    drawCCsBetweenNodes()
end

------------------------------
function drawCCsBetweenNodes()
    i = 1
    for n = 1, #tableNodes-1 do
        while i <= #tableCC and tableCC[i].PPQ < tableNodes[n+1].PPQ do
            -- Interpolate value of CC between nodes
            if tableNodes[n].shape == 0 then -- Linear
                CCvalue = tableNodes[n].value + ((tableCC[i].PPQ - tableNodes[n].PPQ)/(tableNodes[n+1].PPQ - tableNodes[n].PPQ))*(tableNodes[n+1].value - tableNodes[n].value)
            elseif tableNodes[n].shape == 1 then -- Square
                CCvalue = tableNodes[n].value
            elseif tableNodes[n].shape >= 2 and tableNodes[n].shape < 3 then -- Sine
                local piMin = (tableNodes[n].shape - 2)*math.pi
                local piRefVal = math.cos(piMin)+1
                local piFrac  = piMin + (tableCC[i].PPQ-tableNodes[n].PPQ)/(tableNodes[n+1].PPQ-tableNodes[n].PPQ)*(math.pi - piMin)
                local cosFrac = 1-(math.cos(piFrac)+1)/piRefVal
                CCvalue = tableNodes[n].value + cosFrac*(tableNodes[n+1].value-tableNodes[n].value)
            elseif tableNodes[n].shape >= 3 and tableNodes[n].shape < 4 then -- Inverse parabolic
                local minVal = 1 - (tableNodes[n].shape - 4)
                local fracVal = minVal*(tableCC[i].PPQ-tableNodes[n+1].PPQ)/(tableNodes[n].PPQ-tableNodes[n+1].PPQ)
                local refVal = minVal^3
                local normFrac = (fracVal^3)/refVal
                CCvalue = tableNodes[n+1].value + normFrac*(tableNodes[n].value - tableNodes[n+1].value)            
            elseif tableNodes[n].shape >= 4 and tableNodes[n].shape < 5 then -- Parabolic
                local minVal = tableNodes[n].shape - 4
                local fracVal = minVal + (tableCC[i].PPQ-tableNodes[n].PPQ)/(tableNodes[n+1].PPQ-tableNodes[n].PPQ)*(1 - minVal)
                local refVal = 1 - minVal^3
                local normFrac = 1 - (1-fracVal^3)/refVal
                CCvalue = tableNodes[n].value + normFrac*(tableNodes[n+1].value - tableNodes[n].value)
            else -- if tableNodes[n].shape == 5 then -- Bézier
                CCvalue = tableNodes[n].value
            end
            
            if egsliders[slidNum_quant].value ~= 1 then
                CCvalue=quantize_value(CCvalue, 3 + math.ceil(125*egsliders[slidNum_quant].value))
            end
            CCvalue = math.max(minv, math.min(maxv, math.floor(CCvalue+0.5)))
            
            -- SetCC to the new value
            if laneType == CC7BIT then
                reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, CCvalue>>7, true)
            elseif laneType == CC14BIT then
                reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, CCvalue>>7, true)
                reaper.MIDI_SetCC(take, tableCCLSB[i].index, nil, nil, tableCC[i].PPQ, nil, nil, nil, CCvalue&127, true)
            elseif laneType == PITCH then
                reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, CCvalue&127, CCvalue>>7, true)
            else -- if laneType == CHANPRESSURE then
                reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, CCvalue>>7, nil, true)
            end
            
            i = i + 1
            
        end -- while tableCC[i].PPQ < tableNodes[n].PPQ and i <= #tableCC
    
    end -- for n = 1, #tableNodes-1 

end -- function drawCCsBetweenNodes()

--------------------------
function getSavedCurvesAndNames()
    savedCurves = nil
    savedCurves = {}
    savedNames = nil
    savedNames = {}
        
    if reaper.HasExtState("LFO generator", "savedCurves") then
        extStateString = reaper.GetExtState("LFO generator", "savedCurves")
        savedCurves = nil
        savedCurves = {}
        prevSeparator = 0
        repeat
            nextSeparator = extStateString:find("|", prevSeparator+1)
            if nextSeparator ~= nil then
                table.insert(savedCurves, extStateString:sub(prevSeparator+1, nextSeparator-1))
                --reaper.ShowConsoleMsg(savedCurves[#savedCurves] .. "\n\n")
            end
            prevSeparator = nextSeparator
        until nextSeparator == nil
        
        for i = 1, #savedCurves do
            firstComma = savedCurves[i]:find(",")
            if firstComma ~= nil then
                table.insert(savedNames, savedCurves[i]:sub(1, firstComma-1))
            end
        end
        
        if #savedNames == 0 or #savedNames ~= #savedCurves then
            reaper.ShowConsoleMsg("\n\nThe saved curves appear to have been corrupted."
                                  .. "\n\nThe saved curves can be edited (and perhaps recovered) manually, or they can all be deleted by running the following command in a script:"
                                  .. "\nreaper.DeleteExtState(\"LFO generator\", \"savedCurves\", true)")
            savedCurves = nil
            savedNames = nil
            return(false)
        end
    else
        return(false)
    end
                
end -- function getSavedCurvesAndNames()

-----------------------------------

function loadCurve(curveNum)

    if savedCurves ~= nil and #savedCurves ~= nil and #savedCurves >= curveNum and curveNum >= 0 then
    
        savedString = savedCurves[curveNum]
                
        prevComma = 0
        function nextStr()
            nextComma = savedString:find(",", prevComma+1)
            if nextComma == nil then substring = savedString:sub(prevComma+1)
            else substring = savedString:sub(prevComma+1,nextComma-1)
                prevComma = nextComma
            end
            --reaper.ShowConsoleMsg(substring .. "\n")
            return(substring)
        end
        
        curveName = nextStr()
        for i = 0, 11 do
            --reaper.ShowConsoleMsg("\nsliderName = ")
            sliderName = nextStr()
            if sliderName  == "LFO shape?" then shapeSelected = tonumber(nextStr())
            --[[elseif sliderName == "Real-time copy to CC?" then 
                if nextStr() == "true" then
                    egsliders[slidNum_copyCC].enabled = true
                else
                    egsliders[slidNum_copyCC].enabled = false
                end]]
            elseif sliderName == "Phase step" then egsliders[slidNum_phase].value = tonumber(nextStr())
            elseif sliderName == "Randomness" then egsliders[slidNum_random].value = tonumber(nextStr())
            elseif sliderName == "Quant steps" then egsliders[slidNum_quant].value = tonumber(nextStr())
            elseif sliderName == "Bezier shape" then egsliders[slidNum_Bezier].value = tonumber(nextStr())
            elseif sliderName == "Fade in duration" then egsliders[slidNum_fadein].value = tonumber(nextStr())
            elseif sliderName == "Fade out duration" then egsliders[slidNum_fadeout].value = tonumber(nextStr())
            elseif sliderName == "Rate mode" then egsliders[slidNum_mode].value = tonumber(nextStr())
            elseif sliderName == "Rate" then 
                egsliders[slidNum_rate].envelope = nil
                egsliders[slidNum_rate].envelope = {}
                for p = 1, tonumber(nextStr()) do
                    egsliders[slidNum_rate].envelope[p] = {tonumber(nextStr()), tonumber(nextStr())}
                end
            elseif sliderName == "Center" then 
                egsliders[slidNum_center].envelope = nil
                egsliders[slidNum_center].envelope = {}
                for p = 1, tonumber(nextStr()) do
                    egsliders[slidNum_center].envelope[p] = {tonumber(nextStr()), tonumber(nextStr())}
                end
            elseif sliderName == "Amplitude" then 
                egsliders[slidNum_amp].envelope = nil
                egsliders[slidNum_amp].envelope = {}
                for p = 1, tonumber(nextStr()) do
                    egsliders[slidNum_amp].envelope[p] = {tonumber(nextStr()), tonumber(nextStr())}
                end
            end
        end -- for i = 0, 11 
        
        -------------------------------------------------------
        -- Draw the newly loaded envelope
        if egsliders[100].name == egsliders[1].name then -- "Rate"
            egsliders[100]=make_envelope(borderWidth, envYpos, 0, envHeight, egsliders[1])
        elseif egsliders[100].name == egsliders[2].name then -- "Amplitude"
            egsliders[100]=make_envelope(borderWidth, envYpos, 0, envHeight, egsliders[2])
        else -- "Center"
            egsliders[100]=make_envelope(borderWidth, envYpos, 0, envHeight, egsliders[3])
        end
        
        generate(egsliders[1].value,
               egsliders[2].value,
               egsliders[3].value,
               egsliders[4].value,
               egsliders[5].value,
               egsliders[6].value,
               egsliders[7].value,
               egsliders[8].value,
               egsliders[9].value,
               0, --egsliders[10].value,
               clip)
               was_changed=true
               
       -- Draw the envelope in CC lane
       drawCCsBetweenNodes()
        
    end -- savedCurves ~= nil and #savedCurves ~= nil and

end -- loadCurve()

  
---------------------------------------------
function constructNewGUI()

    --[[
    if laneType == CC7BIT then
        titleString = "LFO: CC ".. tostring(clickedLane)
    elseif laneType == CHANPRESSURE then
        titleString = "LFO: Chan pressure"
    elseif laneType == CC14BIT then
        titleString = "LFO: CC ".. tostring(clickedLane-256) .. "/" .. tostring(clickedLane-224)
    elseif laneType == PITCH then
        titleString = "LFO: Pitch"
    end
    ]]
    gfx.quit()
    gfx.init("LFO: ".. clickedLaneString, initXsize, initYsize,0)
    gfx.setfont(1,"Ariel", 15)
    
    egsliders[1]=make_radiobutton(borderWidth,borderWidth,0,0,0.5,"Rate", function(nx) end)
    slidNum_rate = 1
    egsliders[2]=make_radiobutton(borderWidth,borderWidth+sliderHeight*1,0,0,0.5,"Amplitude",function(nx) end)
    slidNum_amp = 2
    egsliders[3]=make_radiobutton(borderWidth,borderWidth+sliderHeight*2,0,0,0.5,"Center",function(nx) end)
    slidNum_center = 3
    egsliders[0]=make_menubutton(borderWidth,borderWidth+sliderHeight*3,0,0,0.0,"LFO shape?",function(nx) end)
    slidNum_shape = 0
    --[[egsliders[11]=make_question(borderWidth,borderWidth+sliderHeight*4,0,0,0.0,"Real-time copy to CC?",function(nx) end)
    slidNum_copyCC = 11]]
    -- The following slider was originally named "Phase"
    egsliders[4]=make_slider(borderWidth,borderWidth+sliderHeight*4,0,0,0.0,"Phase step",function(nx) end)
    slidNum_phase = 4
    egsliders[5]=make_slider(borderWidth,borderWidth+sliderHeight*5,0,0,0.0,"Randomness",function(nx) end)
    slidNum_random = 5
    egsliders[6]=make_slider(borderWidth,borderWidth+sliderHeight*6,0,0,1.0,"Quant steps",function(nx) end)
    slidNum_quant = 6
    egsliders[7]=make_slider(borderWidth,borderWidth+sliderHeight*7,0,0,0.7,"Bezier shape",function(nx) end)
    slidNum_Bezier = 7
    egsliders[8]=make_slider(borderWidth,borderWidth+sliderHeight*8,0,0,0.0,"Fade in duration",function(nx) end)
    slidNum_fadein = 8
    egsliders[9]=make_slider(borderWidth,borderWidth+sliderHeight*9,0,0,0.0,"Fade out duration",function(nx) end)
    slidNum_fadeout = 9
    --egsliders[10]=make_slider(borderWidth,borderWidth+sliderHeight*11,0,0,0.0,"Rate mode",function(nx) end)
    --slidNum_mode = 10
    egsliders[100]=make_envelope(borderWidth, envYpos, 0, envHeight,egsliders[1]) --315-30
    
    --[[for key,tempcontrol in pairs(egsliders) do
      reaper.ShowConsoleMsg(key.." "..tempcontrol.type.." "..tempcontrol.name.."\n")
    end]]
    
end -- constructNewGUI()

---------------------------------------------
-- Main 

function newTimeAndCCs()
   
    editor = reaper.MIDIEditor_GetActive()
    if editor == nil then return(false) end
    take = reaper.MIDIEditor_GetTake(editor)
    if take == nil then return(false) end
    clickedLane = reaper.MIDIEditor_GetSetting_int(editor, "last_clicked_cc_lane")
    _, clickedLaneString = reaper.MIDIEditor_GetSetting_str(editor, "last_clicked_cc_lane", "")

    if 256 <= clickedLane and clickedLane <= 287 then
        clickedLaneString = "CC ".. tostring(clickedLane-256) .. "/" .. tostring(clickedLane-224) .. " 14-bit"
    elseif clickedLaneString == "" then
        clickedLaneString = "CC ".. tostring(clickedLane)
    end
    defaultChannel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
    
    time_start, time_end = reaper.GetSet_LoopTimeRange(false, false, 0.0, 0.0, false)  
    if time_end<=time_start then return(false) end
    PPQstart = reaper.MIDI_GetPPQPosFromProjTime(take, time_start)
    PPQend   = reaper.MIDI_GetPPQPosFromProjTime(take, time_end)
    
    --[[ If an LFO tool is already running, remove
    if reaper.HasExtState("LFO Generator", "isRunning") then
        reaper.SetExtState("LFO Generator", "isRunning", "quit", true)
        while reaper.HasExtState("LFO Generator", "isRunning") do end
    end
    
    reaper.SetExtState("LFO Generator", "isRunning", "running", true)
    ]]
    
    -- OK, script can start, so activate menu button, if relevant, and define atexit
    _, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
        reaper.SetToggleCommandState(sectionID, cmdID, 1)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end    
    reaper.atexit(exit)
    
    -- Since 7bit CC, 14bit CC, channel pressure, and pitch all 
    --     require somewhat different tweaks, these must often be 
    --     distinguished.   
    if 0 <= clickedLane and clickedLane <= 127 then -- CC, 7 bit (single lane)
        laneType = CC7BIT
    elseif clickedLane == 0x203 then -- Channel pressure
        laneType = CHANPRESSURE
    elseif 256 <= clickedLane and clickedLane <= 287 then -- CC, 14 bit (double lane)
        laneType = CC14BIT
    elseif clickedLane == 0x201 then
        laneType = PITCH
    else -- not a lane type in which a ramp can be drawn (sysex, velocity etc).
        return(false)
    end
        
    ------------------------------------------------------------------------
    -- Deselect all events in one shot.  Much faster than doing this via Lua
    reaper.MIDI_SelectAll(take, false)
    
    -- Delete all CCs in time selection (in last clicked lane and in channel)
    -- Use binary search to find event close to rightmost edge of ramp
    reaper.MIDI_Sort(take)
    _, _, ccevtcnt, _ = reaper.MIDI_CountEvts(take)        
    rightIndex = ccevtcnt-1
    leftIndex = 0
    while (rightIndex-leftIndex)>1 do
        middleIndex = math.ceil((rightIndex+leftIndex)/2)
        _, _, _, middlePPQpos, _, _, _, _ = reaper.MIDI_GetCC(take, middleIndex)
        if middlePPQpos > PPQend then
            rightIndex = middleIndex
        else -- middlePPQpos <= startingPPQpos
            leftIndex = middleIndex
        end     
    end -- while (rightIndex-leftIndex)>1
    
    -- Now delete events original events between the two endpoints.
    for i = rightIndex, 0, -1 do   
        _, selected, _, ppqpos, chanmsg, chan, msg2, _ = reaper.MIDI_GetCC(take, i)
        if ppqpos < PPQstart then
            break -- Once below range of selected events, no need to search further
        elseif ppqpos <= PPQend
        and (deleteOnlyDrawChannel == false or (deleteOnlyDrawChannel == true and chan == defaultChannel)) -- same channel
        and (   (laneType == CC7BIT and chanmsg == 176 and msg2 == clickedLane) 
             or (laneType == PITCH and chanmsg == 224)
             or (laneType == CHANPRESSURE and chanmsg == 208)
             or (laneType == CC14BIT and chanmsg == 176 and msg2 == clickedLane-256)
             or (laneType == CC14BIT and chanmsg == 176 and msg2 == clickedLane-224)
            )
        then
            reaper.MIDI_DeleteCC(take, i)
        end -- elseif
    end -- for i = rightIndex, 0, -1
    
    -----------------------------------------------------------------
    -- Insert new (selected) CCs at CC density grid in time selection
    -- Insert endpoints at time_start and time_end
    
    insertValue = 8000
    
    if laneType == CC7BIT then
        reaper.MIDI_InsertCC(take, true, false, PPQstart, 176, defaultChannel, clickedLane, insertValue>>7)
    elseif laneType == PITCH then
        reaper.MIDI_InsertCC(take, true, false, PPQstart, 224, defaultChannel, insertValue&127, insertValue>>7)
    elseif laneType == CHANPRESSURE then
        reaper.MIDI_InsertCC(take, true, false, PPQstart, 208, defaultChannel, insertValue>>7, 0)
    else -- laneType == CC14BIT
        reaper.MIDI_InsertCC(take, true, false, PPQstart, 176, defaultChannel, clickedLane-256, insertValue>>7)
        reaper.MIDI_InsertCC(take, true, false, PPQstart, 176, defaultChannel, clickedLane-224, insertValue&127)
    end
    
    if laneType == CC7BIT then
        reaper.MIDI_InsertCC(take, true, false, PPQend, 176, defaultChannel, clickedLane, insertValue>>7)
    elseif laneType == PITCH then
        reaper.MIDI_InsertCC(take, true, false, PPQend, 224, defaultChannel, insertValue&127, insertValue>>7)
    elseif laneType == CHANPRESSURE then
        reaper.MIDI_InsertCC(take, true, false, PPQend, 208, defaultChannel, insertValue>>7, 0)
    else -- laneType == CC14BIT
        reaper.MIDI_InsertCC(take, true, false, PPQend, 176, defaultChannel, clickedLane-256, insertValue>>7)
        reaper.MIDI_InsertCC(take, true, false, PPQend, 176, defaultChannel, clickedLane-224, insertValue&127)
    end          
    
    -- Get first insert position at CC density 'grid'
    -- First, Get the default grid resolution as set in Preferences -> 
    --    MIDI editor -> "Events per quarter note when drawing in CC lanes"
    takeStartQN = reaper.MIDI_GetProjQNFromPPQPos(take, 0)
    PPQ = reaper.MIDI_GetPPQPosFromProjQN(take, takeStartQN+1)
    density = math.floor(reaper.SNM_GetIntConfigVar("midiCCdensity", 32))
    density = math.floor(math.min(128, math.max(4, math.abs(density)))) -- If user selected "Zoom dependent", density < 0
    PPperCC = PPQ/density
    local QNperCC = 1/density
    local QNstart = reaper.MIDI_GetProjQNFromPPQPos(take, PPQstart)
    firstCCinsertPPQpos = reaper.MIDI_GetPPQPosFromProjQN(take, QNperCC*(math.ceil(QNstart/QNperCC)))
    --if firstCCinsertPPQpos = PPQstart then firstCCinsertPPQpos = firstCCinsertPPQpos + PPperCC end
    
    for p = firstCCinsertPPQpos, PPQend, PPperCC do
        insertPPQpos = math.floor(p + 0.5)      
        if insertPPQpos ~= PPQstart and insertPPQpos ~= PPQend then
            if laneType == CC7BIT then
                reaper.MIDI_InsertCC(take, true, false, insertPPQpos, 176, defaultChannel, clickedLane, insertValue>>7)
            elseif laneType == PITCH then
                reaper.MIDI_InsertCC(take, true, false, insertPPQpos, 224, defaultChannel, insertValue&127, insertValue>>7)
            elseif laneType == CHANPRESSURE then
                reaper.MIDI_InsertCC(take, true, false, insertPPQpos, 208, defaultChannel, insertValue>>7, 0)
            else -- laneType == CC14BIT
                reaper.MIDI_InsertCC(take, true, false, insertPPQpos, 176, defaultChannel, clickedLane-256, insertValue>>7)
                reaper.MIDI_InsertCC(take, true, false, insertPPQpos, 176, defaultChannel, clickedLane-224, insertValue&127)
            end
        end
    end
    
    -----------------------------------------------------------
    -- Get indices of the newly inserted CCs and store in table
    tableCC = nil
    tableCCLSB = nil
    tableCC = {}
    tableCCLSB = {}
    
    if laneType ~= CC14BIT then -- Since the events in the ramp are the only selected ones in take, no need to check event types
        selCCindex = reaper.MIDI_EnumSelCC(take, -1)
        while (selCCindex ~= -1) do
            _, _, _, ppqpos, _, _, _, _ = reaper.MIDI_GetCC(take, selCCindex)
            --if (laneType == CC7BIT and chanmsg == 176 and msg2 == clickedLane)
            --or (laneType == PITCH and chanmsg == 224)
            --or (laneType == CHANPRESSURE and chanmsg == 208) then
                table.insert(tableCC, {index = selCCindex,
                                      PPQ = ppqpos})
            --end
            selCCindex = reaper.MIDI_EnumSelCC(take, selCCindex)
        end
    else -- When 14-bit CC, must distinguish between MSB and LSB events
        selCCindex = reaper.MIDI_EnumSelCC(take, -1)
        while (selCCindex ~= -1) do
            _, _, _, ppqpos, _, _, msg2, _ = reaper.MIDI_GetCC(take, selCCindex)
            if msg2 == clickedLane-256 then
                table.insert(tableCC, {index = selCCindex,
                                       PPQ = ppqpos})
            else
                table.insert(tableCCLSB, {index = selCCindex,
                                          PPQ = ppqpos})
            end
            selCCindex = reaper.MIDI_EnumSelCC(take, selCCindex)
        end
        if #tableCC ~= #tableCCLSB then
            reaper.ShowConsoleMsg("Something went wrong while writing CCs")
            return(false)
        end
    end
    
    ----------------------------------
    -- Make sure the tables are sorted
    function sortPPQ(a,b)
        if a.PPQ < b.PPQ then return(true) else return(false) end
    end
    table.sort(tableCC,sortPPQ)
    if laneType == CC14BIT then
        table.sort(tableCCLSB, sortPPQ)
    end
    
        
end -- newTimeAndCCs()

-------------------------
-- Get the script started

if newTimeAndCCs() == false then return(0) end

constructNewGUI()

-- Load default curve, if any
if getSavedCurvesAndNames() ~= false then
    if savedNames ~= nil and type(savedNames) == "table" and #savedNames > 0 then
        for i = 1, #savedNames do
            if savedNames[i] == "default" then
                loadCurve(i)
            end
        end
    end
end

-- Generate the first version of the envelope nodes and draw the CCs between
generateAndDisplay()
update()

--[[
ReaScript name: js_Envelope LFO generator and shaper.lua
Version: 1.41
Author: juliansader / Xenakios
Website: http://forum.cockos.com/showthread.php?t=177437
Screenshot: http://stash.reaper.fm/27661/LFO%20shaper.gif
Donation: https://www.paypal.me/juliansader
About:
  # Description
  
  LFO generator and shaper - Automation envelope version.
  
  Draw fancy LFO curves in REAPER's automation envelopes.
  
    
  # Instructions
  
  SELECTION OF TARGET ENVELOPE
  
  The script can insert LFOs into either 1) a selected automation item, or 2) the time selection of the underlying envelope.
  
  To insert an LFO into the time selection, select an envelope and deselect all automation items.
  
  To insert an LFO into an automation item, select a single automation item. If the time selection falls within the bounds 
      of the selected automation item, the LFO will be inserted into only the selected part of the automation item.
  
  (The time selection and the target envelope or automation item can be changed while the script is running.)
  
  
  DRAWING CURVES
  
  Leftclick in open space in the envelope drawing area to add an envelope node.
  
  Shift + Leftdrag to add multiple envelope nodes.
  
  Alt + Leftclick (or -drag) to delete nodes.
  
  Rightclick on an envelope node to open a dialog box in which a precise custom value can be entered.
  
  Move mousewheel while mouse hovers above node for fine adjustment.
  
  Use a Ctrl modifier to edit all nodes simultaneously:
  
  Ctrl + Leftclick (or -drag) to set all nodes to the mouse Y position.
  
  Ctrl + Rightclick to enter a precise custom value for all nodes.
  
  Ctrl + Mousewheel for fine adjustment of all nodes simultaneously.
  
  The keyboard shortcuts "a", "c" and "r" can be used to switch the envelope view between Amplitude, Center and Rate.
  

  VALUE AND TIME DISPLAY
  
  The precise Rate, Amplitude or Center of the hot node, as well as the precise time position, can be displayed above the node.
  
  Rightclick in open space in the envelope area to open a menu in which the Rate and time display formats can be selected.
  

  LOADING AND SAVING CURVES
  
  Right-click (outside envelope area) to open the Save/Load/Delete curve menu.
  
  One of the saved curves can be loaded automatically at startup. By default, this curve must be named "default".
  
                    
  FURTHER CUSTOMIZATION
  
  Further customization is possible - see the instructions in the script's USER AREA.
  
  This include:
  - Easily adding custom LFO shapes.
  - Specifying the resolution of LFO shapes' phase steps.
  - Specifying the resolution of the mousewheel fine adjustment.
  - Changing interface colors.
  - Changing the default curve name.
  - etc...      
]]
--[[
  Changelog:
  * v1.04 (2016-06-23)
    + User can specify the number of phase steps in standard LFO shapes, which allows nearly continuous phase changes.
  * v1.10 (2017-01-18)    
    + Header info updated to ReaPack 1.1 format.
    + Keyboard shortcuts "a", "c" and "r" for quick switching between GUI views.
  * v1.11 (2017-03-02)
    + Fixed bug in loading default curves with customized names (different from "default").
  * v1.20 (2017-08-06)
    + GUI window will open at last-used screen position.
  * v1.30 (2017-08-09)
    + Compatible with automation items.
    + Requires REAPER v5.50 or higher.
  * v1.40 (2017-08-09)
    + LFO can be limited to time selection within automation item.
    + Undo points more informative.
  * v1.41 (2017-08-16)
    + Checks REAPER version and SWS installed.
]]
-- The archive of the full changelog is at the end of the script.

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
    backgroundColor = {0.15, 0.15, 0.15, 1}
    foregroundColor = {0.3, 0.8, 0.3, 0.7}
    textColor       = {1, 1, 1, 0.7}  
    buttonColor     = {1, 0, 0, 1} 
    hotbuttonColor  = {0, 1, 0, 1}
    shadows         = true  
      
    -- Name of curve to load as default.
    --    By changing this name and saving as new script, different default curves can be 
    --    linked to different shortcut keys.
    defaultCurveName = "default" 
        
    -- How fine should the mousewheel adjustment be? (Between 0 and 1.)
    -- 0 would result in no fine adjustment, while 1 would result in immediate jumps to
    --    minimum or maximum values.
    fineAdjust = 0.0003
    
    -- Should the LFO Tool try to preserve the shape and values of the pre-existing envelope 
    --    outside the time selection?  
    -- To do so, the script will preserve the outermost pre-existing envelope points at the 
    --    edges of the selection.  If it cannot find such points, it will insert new points 
    --    at the edges with values of the existing envelope.
    -- NOTE: Certain envelope shapes, particularly the non-linear shapes, will not 
    --    be perfectly preserved by inserting new edge points.
    preserveExistingEnvelope = true -- "true" or "false"
    
    -- Number of phase steps in standard LFO shapes.  (Must be a positive multiple of 4.)
    -- The higher the number, the more nearly continuous the phase steps will be.  However, it may also
    --    slow the responsiveness of the scripts down.
    phaseStepsDefault = 100
    
    --[[
    The user can easily add new shapes:
    Simply add the new items to 1) shapeMenu, 2) shapeTable, 4) the list of values
        and 3) the shape_function table, and give the new shape the next number in the 'List of shapes'.
    The functions in the table specify the shapes in terms of a sequence of node points:
        totalSteps = total number of steps in the shape
        amplitude  = Relative amplitude of point (min=-1, max=1).  "false" means that the point 
                     will be skipped (thereby expanding the shape).
        shape      = 0=Linear, 1=Square, 2=Slow start/end, 3=Fast start, 4=Fast end, 5=Bézier
        tension    = Tension of Bézier curve (only relevant if shape == 5.
        linearJump = specifies whether the shape has a discontinuous jump to the other side of the 'center'.
    ]]
                                
shapeMenu = "Bézier|Saw down|Saw up|Square|Triangle|Sineish|Fast end triangle|Fast start triangle|MwMwMw"
shapeTable = {"Bezier", "Saw down", "Saw up", "Square", "Triangle", "Sineish", "Fast end triangle", "Fast start triangle", "MwMwMw"}
-- List of shapes:
Bezier = 1
SawDown = 2
SawUp = 3
Square = 4
Triangle = 5
Sineish = 6
FastEndTri = 7
FastStartTri = 8
MwMwMw = 9

shape_function = {}

shape_function[Bezier] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % phaseStepsDefault == 0 then return phaseStepsDefault, 1, 5, 1, false end
  if cnt % phaseStepsDefault == phaseStepsDefault/4 then return phaseStepsDefault, 0, 5, -1, false end
  if cnt % phaseStepsDefault == phaseStepsDefault/2 then return phaseStepsDefault, -1, 5, 1, false end
  if cnt % phaseStepsDefault == phaseStepsDefault*3/4 then return phaseStepsDefault, 0, 5, -1, false end
  return phaseStepsDefault, false, 5, -1, false
end

shape_function[SawUp] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump 
  if cnt % phaseStepsDefault == 0 then return phaseStepsDefault, 1, 0, 1, true end
  return phaseStepsDefault, false, 0, 1, false
end

shape_function[SawDown] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % phaseStepsDefault == 0 then return phaseStepsDefault, -1, 0, 1, true end
  return phaseStepsDefault, false, 0, 1, false
end

shape_function[Square] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % phaseStepsDefault == phaseStepsDefault/4 then return phaseStepsDefault, -1, 1, 1, false end  
  if cnt % phaseStepsDefault == phaseStepsDefault*3/4 then return phaseStepsDefault, 1, 1, 1, false end
  return phaseStepsDefault, false, 1, 1, false
end

shape_function[Triangle] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % phaseStepsDefault == 0 then return phaseStepsDefault, 1, 0, 1, false end
  if cnt % phaseStepsDefault == phaseStepsDefault/2 then return phaseStepsDefault, -1, 0, 1, false end
  return phaseStepsDefault, false, 0, 1, false
end

shape_function[Sineish] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % phaseStepsDefault == 0 then return phaseStepsDefault, 1, 2, 1, false end
  if cnt % phaseStepsDefault == phaseStepsDefault/2 then return phaseStepsDefault, -1, 2, 1, false end
  return phaseStepsDefault, false, 2, 1, false
end

shape_function[FastEndTri] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % phaseStepsDefault == 0 then return phaseStepsDefault, 1, 4, 1, false end
  if cnt % phaseStepsDefault == phaseStepsDefault/2 then return phaseStepsDefault, -1, 4, 1, false end
  return phaseStepsDefault, false, 4, 1, false
end

shape_function[FastStartTri] = function(cnt)
  -- returns totalSteps, amplitude, shape, tension, linearJump
  if cnt % phaseStepsDefault == 0 then return phaseStepsDefault, 1, 3, 1, false end
  if cnt % phaseStepsDefault == phaseStepsDefault/2 then return phaseStepsDefault, -1, 3, 1, false end
  return phaseStepsDefault, false, 3, 1, false
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
initYsize = borderWidth + sliderHeight*12 + envHeight + 45
envYpos = initYsize - envHeight - 30

hotpointRateDisplayType = "period note length" -- "frequency" or "period note length"
hotpointTimeDisplayType = -1
rateInterpolationType = "parabolic" -- "linear" or "parabolic"

-- By default, these curve will align if the tempo is a constant 120bpm
-- The range is between 2 whole notes and 1/32 notes, or 0.25Hz and 16Hz.
timeBaseMax = 16 -- 16 oscillations per second
timeBaseMin = 0.25
beatBaseMax = 32 -- 32 divisions per whole note
beatBaseMin = 0.5

-- The Clip slider and value in the original code
--     do not appear to have any effect, 
--     so the slider was replaced by the "Real-time copy to CC?" 'slider',
--     and the value was replaced by this constant
clip = 1
                  
helpText = "SELECTION OF TARGET ENVELOPE:"
          .."\n\nThe script can insert an LFO into either:"
          .."\n\n  * a selected automation item, or"
          .."\n\n  * the time selection of the underlying envelope."
          .."\n\nTo insert an LFO into the time selection, select an envelope and deselect all automation items."
          .."\n\nTo insert an LFO into an automation item, select a single automation item. If the time selection falls within the bounds of the selected automation item, "
          .."the LFO will be inserted into only the selected part of the automation item."
          .."\n\n(The time selection and the target envelope or automation item can be changed while the script is running.)"
          
          .."\n\n\nDRAWING CURVES:"
          .."\n\n  * Leftclick in open space in the envelope drawing area to add an envelope node."
          .."\n\n  * Shift + Leftdrag to add multiple envelope nodes."
          .."\n\n  * Alt + Leftclick (or -drag) to delete nodes."
          .."\n\n  * Rightclick on an envelope node to open a dialog box in which a precise custom value can be entered."
          .."\n\n  * Move mousewheel while mouse hovers above node for fine adjustment."
          
          .."\n\nUse a Ctrl modifier to edit all nodes simultaneously:"
          .."\n\n  * Ctrl + Leftclick (or -drag) to set all nodes to the mouse Y position."
          .."\n\n  * Ctrl + Rightclick to enter a precise custom value for all nodes."
          .."\n\n  * Ctrl + Mousewheel for fine adjustment of all nodes simultaneously."
          
          .."\n\n\nVALUE AND TIME DISPLAY:"
          .."\n\nThe precise Rate, Amplitude or Center of the hot node, as well as the precise time position, can be displayed above the node." 
          .."\n\nRightclick in open space in the envelope area to open a menu in which the Rate and time display formats can be selected."
          
          .."\n\n\nLOADING AND SAVING CURVES:"
          .."\n\nRight-click (outside envelope area) to open the Save/Load/Delete curve menu."
          .."\n\nOne of the saved curves can be loaded automatically at startup. By default, this curve must be named 'default'."
          
          .."\n\n\nCOPYING TO CC:"
          .."\n\n'Real-time copy to CC' does not write directly to the CC lane. Instead, it copies from the active envelope to the last clicked CC lane. An envelope must therefore still be open and active."
          
          .."\n\n\nFURTHER CUSTOMIZATION:"
          .."\n\nFurther customization is possible - refer to the instructions in the script's USER AREA.\nThis includes:"
          .."\n  * Easily adding custom LFO shapes."
          .."\n  * Specifying the resolution of LFO shapes' phase steps."
          .."\n  * Specifying the resolution of the mousewheel fine adjustment."
          .."\n  * Changing interface colors."
          .."\n  * Changing the default curve name."
          .."\netc..."

-- mouse_cap values
NOTHING = 0
LEFTBUTTON = 1
RIGHTBUTTON = 2
CTRLKEY = 4
SHIFTKEY = 8
ALTKEY = 16
WINKEY = 32
MIDDLEBUTTON = 64

------------------------------------------------------------------------
-- Reader beware: there is lots of cruft remaining in this script
--    since it is an unfinished script that was later hacked and modded.

fader_img=0

egenvelopes={}

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

function make_question(x,y,w,h,val,name,valcb, trueanswer, falseanswer)
  slider={}
  slider.x=function() return x end
  slider.y=function() return y end
  slider.w=function() return gfx.w-20 end
  slider.h=function() return 20 end
  slider.value=val
  slider.valcb=valcb
  slider.name=name
  slider.enabled = false
  slider.trueanswer = trueanswer
  slider.falseanswer = falseanswer
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

function quantize_value(val, numSteps, rangeMin, rangeMax)
  local stepSize = (1.0/numSteps) * (rangeMax-rangeMin)
  return math.max(rangeMin, math.min(rangeMax, rangeMin + stepSize * math.floor((val-rangeMin)/stepSize + 0.5)))
  --return (1.0/numsteps) * math.floor(val*numsteps + 0.5)
end
--[[function quantize_value(val, numsteps)
    stepSize = math.floor(0.5 + (maxv-minv)/numsteps)
    return(stepSize * math.floor(0.5 + val/stepSize))
    --return 1.0/numsteps*math.floor(val*numsteps)
end]]

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
        --local imgw,imgh=gfx.getimgdim(fader_img)
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
        --gfx.blit(fader_img,1.0,0.0,0,0,imgw,imgh-1,thumbx,slid.y,imgw,imgh-1)
    
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
            if slid.value == 1 then
                gfx.drawstr(slid.trueanswer)
            else
                gfx.drawstr(slid.falseanswer)      
            end
        end
        gfx.x=slid.x()+3+gfx.measurestr(slid.name)+gfx.measurestr("w")
        gfx.y=slid.y()+2
        setColor(foregroundColor)
        gfx.a = gfx.a + 0.3  
        if slid.value == 1 then
            gfx.drawstr(slid.trueanswer)
        else
            gfx.drawstr(slid.falseanswer)      
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
            
            -- Must calculate the hotpoint time and rate displays
            local timeAtNode
            if type(time_end) == "number" and type(time_start) == "number" and time_start<=time_end then
                if egsliders[slidNum_timebase].value == 1 then -- Timebase == Beats
                    local timeStartQN = reaper.TimeMap_timeToQN(time_start)
                    local timeEndQN = reaper.TimeMap_timeToQN(time_end)
                    timeAtNode = reaper.TimeMap_QNToTime(timeStartQN + envpoint[1]*(timeEndQN-timeStartQN))
                else
                    timeAtNode = time_start + envpoint[1]*(time_end - time_start)
                end
            else -- Just in case no envelope selected, or update() has not yet been run, or something.
                timeAtNode = 0
            end
            
            -- If Rate envelope, display either period or frequency above hotpoint
            if env.name == "Rate" then
                
                if egsliders[slidNum_timebase].value == 1 and hotpointRateDisplayType == "period note length" then
                    local pointRate = beatBaseMin + (beatBaseMax - beatBaseMin)*(envpoint[2]^2)
                    local pointRateInverse = 1.0/pointRate
                    if pointRateInverse == math.floor(pointRateInverse) then hotString = string.format("%i", tostring(pointRateInverse))
                    elseif pointRate == math.floor(pointRate) then hotString = "1/" .. string.format("%i", tostring(pointRate))
                    elseif pointRate > 1 then hotString = "1/" .. string.format("%.3f", tostring(pointRate))
                    else hotString = string.format("%.3f", tostring(pointRateInverse))
                    end
                elseif egsliders[slidNum_timebase].value == 1 and hotpointRateDisplayType == "frequency" then
                    local bpm = getBPM(timeAtNode)
                    local pointRate = beatBaseMin + (beatBaseMax - beatBaseMin)*(envpoint[2]^2)
                    local pointFreq = (1.0/240) * pointRate * bpm
                    hotString = string.format("%.3f", tostring(pointFreq)) .. "Hz"
                elseif egsliders[slidNum_timebase].value == 0 and hotpointRateDisplayType == "period note length" then
                    local bpm = getBPM(timeAtNode)
                    local pointFreq = timeBaseMin + (timeBaseMax-timeBaseMin)*(envpoint[2]^2)
                    local pointRate = (1.0/bpm) * pointFreq * 240 -- oscillations/sec * sec/min * min/beat * beats/wholenote
                    local pointRateInverse = 1.0/pointRate
                    if pointRateInverse == math.floor(pointRateInverse) then hotString = string.format("%i", tostring(pointRateInverse))
                    elseif pointRate == math.floor(pointRate) then hotString = "1/" .. string.format("%i", tostring(pointRate))
                    elseif pointRate > 1 then hotString = "1/" .. string.format("%.3f", tostring(pointRate))
                    else hotString = string.format("%.3f", tostring(pointRateInverse))
                    end
                elseif egsliders[slidNum_timebase].value == 0 and hotpointRateDisplayType == "frequency" then -- hotpointRateDisplayType == "frequency"
                    local pointFreq = timeBaseMin+((timeBaseMax-timeBaseMin)*(envpoint[2])^2.0)
                    hotString = string.format("%.3f", tostring(pointFreq)) .. "Hz"
                end
                hotString = "R =" .. hotString
                
            -- If Amplitude or Center, display value scaled to actual envelope range.
            -- (The BRenvMaxValue and BRenvMinValue variables are calculated in the update() function.)
            elseif env.name == "Amplitude" then
                if type(BRenvMinValue) == "number" and type(BRenvMaxValue) == "number" then
                    hotString = "A =" .. string.format("%.3f", tostring(envpoint[2]*0.5*(BRenvMaxValue-BRenvMinValue)))
                else
                    hotString = "A = ?"
                end
            else -- env.name == "Center"
                if type(BRenvMinValue) == "number" and type(BRenvMaxValue) == "number" then
                    hotString = "C =" .. string.format("%.3f", tostring(BRenvMinValue + envpoint[2]*(BRenvMaxValue-BRenvMinValue)))
                else
                    hotString = "C = ?"
                end
            end
            
            if hotpointTimeDisplayType >= -1 and hotpointTimeDisplayType <=5 then
                hotString = hotString .. ", " .. "t =" .. reaper.format_timestr_pos(timeAtNode, "", hotpointTimeDisplayType)
            elseif hotpointTimeDisplayType == 6 then
                hotString = hotString .. ", " .. "t =" .. string.format("%.3f", tostring(envpoint[1]))
            -- if hotpointTimeDisplayType == 7 then do nothing
            end
            
            -- The following lines shift the x-position of the string            
            stringWidth, stringHeight = gfx.measurestr(hotString)
            gfx.x = (xcor+3) - (stringWidth+5)*(xcor-env.x())/env.w()
            gfx.y = ycor - 5 - stringHeight
            gfx.drawstr(hotString)
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

function get_env_interpolated_value(env,x,curveType)
  if #env==0 then return 0.0 end
  if x<=env[1][1] then return env[1][2] end
  if x>=env[#env][1] then return env[#env][2] end
  local i=1
  for key,envpoint in pairs(env) do
      if x>=envpoint[1] then
          nextpt=env[key+1]
          if nextpt==nil then nextpt=envpoint end
          if x<nextpt[1] then
              local timedelta=nextpt[1]-envpoint[1]
              if timedelta<0.0001 then timedelta=0.0001 end
              -- Remember that the envelope area is a mapping of [0,1] to actual frequency or period using a power curve:
              -- freqhz = MIN + (MAX-MIN)*(pointValue^2.0)
              -- Therefore this function was changed from a linear interpolation to a similar power curve.
              if curveType == "parabolic" then
                  local valuedelta=nextpt[2]^2 - envpoint[2]^2
                  local interpos=(x-envpoint[1])
                  return ((envpoint[2]^2 + valuedelta*(interpos/timedelta))^0.5)
              else
                  local valuedelta=nextpt[2] - envpoint[2]
                  local interpos=(x-envpoint[1])
                  return (envpoint[2] + valuedelta*(interpos/timedelta))
              end
          end
      end
      i=i+1
  end
  return 0.0
end


function convert_tempo_env_to_TempoTimeSigMarkers()
    local tableTempoPoints = {}
    local totalNumberOfPoints = reaper.CountEnvelopePoints(env)
    
    local closestPointBeforeOrAtStart = reaper.GetEnvelopePointByTime(env, time_start - timeOffset)
    for i = closestPointBeforeOrAtStart, totalNumberOfPoints do
        local pointOK, timeOut, valueOut, _, _, _ = reaper.GetEnvelopePoint(env, i)
        if pointOK == true and timeOut > time_end - timeOffset then
            break 
        elseif pointOK == true and timeOut <= time_end - timeOffset then
            table.insert(tableTempoPoints, {time=timeOut, value=valueOut})
            --reaper.ShowConsoleMsg(valueOut .. "\n")
        end
    end
    
    for i = 1, #tableTempoPoints do
        reaper.SetTempoTimeSigMarker(0, -1, tableTempoPoints[i].time, -1, -1, tableTempoPoints[i].value, 0, 0, true)
    end
    
    reaper.UpdateTimeline()
end -- function convert_tempo_env_to_TempoTimeSigMarkers


function sort_envelope(env)
  table.sort(env,function(a,b) return a[1]<b[1] end)
end

last_used_params={}

last_envelope=nil

---------------------------------------------------------------------------------------------------
-- The important function that calculates the positions and values of the envelope points, and 
--    inserts the points into whatever envelope is active.
function generate(freq,amp,center,phase,randomness,quansteps,tilt,fadindur,fadoutdur,ratemode,clip)

    math.randomseed(1)
       
    tableVals = nil
    tableVals = {}
    
    --------------------------------------------------------------------------------------------
    -- This script creates an Undo point whenever the target envelope or time selection changes.
    -- Except if it is the first envelope: An undo point should only be created AFTER the first 
    --    envelope has been shaped.
    -- Another undo point will be created when the script exits.
    newSelection = false -- temporary
    
    env  = reaper.GetSelectedEnvelope(0)
    if env == nil then return end
    envNameOK, envName = reaper.GetEnvelopeName(env, "")    
    
    selectedAutoItemPrev = selectedAutoItem
    selectedAutoItem = -1
    for a = 0, reaper.CountAutomationItems(env)-1 do
        local selected = reaper.GetSetAutomationItemInfo(env, a, "D_UISEL", 0, false)
        if selected ~= 0 then 
            if selectedAutoItem ~= -1 then return -- If more than one auto item selected, do nothing
            else selectedAutoItem = a 
            end
        end
    end    
    
    time_start, time_end = reaper.GetSet_LoopTimeRange(false, false, 0.0, 0.0, false)
    local autoItemStart, autoItemEnd, noNeedToPreserveStartValue, noNeedToPreserveEndValue, timeWithinAutoItem
    if selectedAutoItem ~= -1 then
        autoItemStart = reaper.GetSetAutomationItemInfo(env, selectedAutoItem, "D_POSITION", 0, false)
        autoItemEnd   = autoItemStart + reaper.GetSetAutomationItemInfo(env, selectedAutoItem, "D_LENGTH", 0, false)
        if time_start > autoItemStart-0.00000001 and time_start < autoItemStart+0.00000001 then 
            time_start = autoItemStart
            noNeedToPreserveStartValue = true    
        end
        if time_end > autoItemEnd-0.00000001 and time_end < autoItemEnd+0.00000001 then 
            time_end = autoItemEnd-0.00000001
            noNeedToPreservceEndValue = true
        end
        if (time_start >= autoItemStart and time_end <= autoItemEnd-0.00000001) then
            timeWithinAutoItem = true
        else
            timeWithinAutoItem = false
            time_start, time_end = autoItemStart, autoItemEnd-0.00000001
        end
        --[[
        or (time_start > autoItemStart and time_end <= autoItemEnd-0.00000001)
        then -- time selection is within automation item, but not 
            preserveExistingEnvelopeInAutoItem = true
        else
            time_start = autoItemStart
            time_end   = autoItemEnd - 0.00000001 -- Inserting points precisely at end of automation items does not seem to work
            preserveExistingEnvelopeInAutoItem = false 
        end]]
    end
    
    if time_end <= time_start then return end -- If no time is selected, time_start = time_end = 0
    
    if env ~= envPrev or selectedAutoItem ~= selectedAutoItemPrev or time_start ~= timeStartPrev or time_end ~= timeEndPrev then
        newSelection = true
        startEnvPointFound = false
        endEnvPointFound = false
        
        if not firstNewSelection then
            if envPrevName then
                undoStr = "LFO Tool: " .. envPrevName
            else
                undoStr = "LFO Tool"
            end  
            reaper.Undo_OnStateChange2(0, undoStr)
            firstNewSelection = false
        end
        envPrevName = envName
        
        timeStartPrev = time_start
        timeEndPrev = time_end
        envPrev = env
        selectedAutoItemPrev = selectedAutoItem
    end
            
        
    -------------------------------------------------------------------------------
    -- The reaper.InsertEnvelopePoint function uses time position relative to 
    --    start of *take*, whereas the reaper.GetSet_LoopTimeRange function returns 
    --    time relative to *project* start.
    -- The following code therefore adjusts time_start and time_end
    --    relative to take position.
    -- The project's own time offset in seconds (Project settings -> 
    --    Project start time) does not appear to have an effect - but must still
    --    make sure about this...
    local BRenv = reaper.BR_EnvAlloc(env, true)
    local envTake = reaper.BR_EnvGetParentTake(BRenv)
    _, _, _, _, _, _, BRenvMinValue, BRenvMaxValue, _, _, _ = reaper.BR_EnvGetProperties(BRenv)
    reaper.BR_EnvFree(BRenv, false)
    
    if envTake ~= nil then -- Envelope is take envelope
        envItem = reaper.GetMediaItemTake_Item(envTake)
        envItemOffset = reaper.GetMediaItemInfo_Value(envItem, "D_POSITION")
        --envItemLength = reaper.GetMediaItemInfo_Value(envItem, "D_LENGTH")
        --Does the "start offset in take of item" return value of the following function add any info?
        --envTakeOffsetInItem = reaper.GetMediaItemTakeInfo_Value(envTake, "D_STARTOFFS")
        timeOffset = envItemOffset --envTakeOffsetInItem + envItemOffset
        -- The following lines would further restrict time selection to within
        --    the position and length of the take (or item).  However, by leaving 
        --    the time selection unrestricted allows the take to be expanded into
        --    time selection without having to re-draw the envelope.
        -- I am not sure how to get the length of an item, so time_end will be
        --    restricted to item end, not take end.
        --time_start = math.max(0, time_start - envTakeOffsetInItem - envItemOffset)
        --time_end = math.min(envItemLength - envTakeOffsetInItem, time_end - envTakeOffsetInItem - envItemOffset)
    else
        timeOffset = 0
    end
    
    ---------------------------------------------------------------------------------
    -- The LFO tries to preserve existing envelope values outside the time selection.
    -- To do so, it will preserve the outermost pre-existing envelope points at the 
    --    edges of the selection.
    -- If it cannot find such points, it will insert new points with values of the 
    --    existing envelope.
    -- NOTE: Certain envelope shapes, particularly the non-linear shapes, will not 
    --    be perfectly preserved by inserting new edge points.
    if newSelection and preserveExistingEnvelope and (selectedAutoItem == -1 or timeWithinAutoItem) then
        startEnvPoint = nil
        endEnvPoint = nil      
        startEnvPoint = {}
        endEnvPoint = {}
        startEnvPointFound = false
        endEnvPointFound = false
        
        reaper.Envelope_SortPoints(env)
        local totalNumberOfPoints = reaper.CountEnvelopePointsEx(env, selectedAutoItem)
        
        if not noNeedToPreserveStartValue then
            startEnvPoint = {shape = nil}
            local closestPointBeforeStart = reaper.GetEnvelopePointByTimeEx(env, selectedAutoItem, time_start - timeOffset - 0.0000001)
            --if i ~= -1 then
            --_, _, _, startEnvPoint.shape, _, _ = reaper.GetEnvelopePoint(env, i)
            for i = closestPointBeforeStart, totalNumberOfPoints do
                local retval, timeOut, valueOut, shapeOut, _, _ = reaper.GetEnvelopePointEx(env, selectedAutoItem, i)
                if retval then
                    if not startEnvPoint.shape then startEnvPoint.shape = shapeOut end 
                    if timeOut >= time_start - timeOffset - 0.00000001 and timeOut <= time_start - timeOffset + 0.00000001 then
                        startEnvPointFound = true
                        startEnvPoint.value = valueOut
                        break
                    elseif retval == true and timeOut > time_start - timeOffset + 0.00000001 then
                        break
                    end
                end
            end
            -- If no point found at time start, interpolate envelope value to insert new point
            if not startEnvPointFound then
                local retval, valueOut, _, _, _ = reaper.Envelope_Evaluate(env, time_start-timeOffset, 0, 0)
                --if retval ~= 1 --!! What is the return value is REAPER cannot determine the envelope value?
                    startEnvPointFound = true
                    startEnvPoint.value = valueOut
                --end
            end 
        end
        
        if not noNeedToPreserveEndValue then
            local closestPointBeforeOrAtEnd = reaper.GetEnvelopePointByTimeEx(env, selectedAutoItem, time_end - timeOffset)
            for i = closestPointBeforeOrAtEnd, totalNumberOfPoints do
                local retval, timeOut, valueOut, shapeOut, tensionOut, _ = reaper.GetEnvelopePointEx(env, selectedAutoItem, i)
                -- Store the parameters of points < time_end, in case they nood to be used to interpolate a 
                --    edge point to preserve existing envelope outside time selection
                if retval then
                    if timeOut < time_end - timeOffset - 0.00000001 then
                        endEnvPoint = {value = valueOut, shape = shapeOut, tension = tensionOut}
                    elseif timeOut < time_end - timeOffset + 0.00000001 then
                        endEnvPointFound = true
                        endEnvPoint = {value = valueOut, shape = shapeOut, tension = tensionOut}
                    elseif timeOut >= time_end - timeOffset + 0.00000001 then
                        break
                    end
                end
            end
            
            -- If no point found, interpolate envelope value to insert new point
            if endEnvPointFound == false then
                local retval, valueOut, _, _, _ = reaper.Envelope_Evaluate(env, time_end-timeOffset, 0, 0)
                --if retval ~= 1 --!! What is the return value is REAPER cannot determine the envelope value?
                    endEnvPointFound = true
                    endEnvPoint.value = valueOut
                    if type(endEnvPoint.shape) ~= "number" then endEnvPoint.shape = 1 end -- If no shape was found earlier
                    if type(endEnvPoint.tension) ~= "number" then endEnvPoint.tension = 0.5 end
                --end
            end 
        end
        
    end -- if newSelection == true
    
    -- Remember that take envelopes require a time offset
    reaper.DeleteEnvelopePointRangeEx(env, selectedAutoItem, time_start - timeOffset - 0.00000001, time_end - timeOffset + 0.00000001) -- time_start - phase?
    
    -- startEnvPoint (to preservce existing envelope values) must be inserted before 
    --    the LFO's own points
    if preserveExistingEnvelope and startEnvPointFound and not (startEnvPoint.shape == 1) then -- If square shape, not need to insert point
        reaper.InsertEnvelopePointEx(env, selectedAutoItem, time_start - timeOffset, startEnvPoint.value, 0, 0, true, false)
    end
    
    
    ------------------------------------------------------------------------------
    -- OK, preservation is done, now can start calculating LFO's own point values.
    envscalingmode=reaper.GetEnvelopeScalingMode(env)
  
    minv = BRenvMinValue
    maxv = BRenvMaxValue
    
    -- Keep time_start and time_end in timebase, gen_time_start and gen_time_end is in time or beats.
    local time, gen_time_start, gen_time_end
    if ratemode>0.5 then
      time=reaper.TimeMap_timeToQN(time_start)
      gen_time_start = time
      gen_time_end=reaper.TimeMap_timeToQN(time_end)
    else
      time=time_start
      gen_time_start = time
      gen_time_end=time_end
    end 
    
    local timeseldur = gen_time_end - gen_time_start
      
    local totalSteps, _, _, _, _ = shape_function[shapeSelected](0)
    local phaseStep = math.floor(phase * totalSteps)
  
    local segshape=-1.0+2.0*tilt
    local ptcount=0
    
    if time <= gen_time_end then
        isBeyondEnd = false else isBeyondEnd = true
    end
    
    ---------------------------------------------------------------------------------------------------
    -- The main loop that inserts points.
    -- In order to interpolate the closing envelope point that will be inserted at end_time,
    --    this loop must actually progress one step beyond the end time.  The point beyond end_time 
    --    of course not be inserted, but will only be used to calculate the interpolated closing point.
    while isBeyondEnd == false do
  
        -- Calculate the step size to next envelope node
        -- The script's internal envelope value is between [0,1] and must be mapped to 
        --    a period between [timeBaseMin, timeBaseMax] or [beatBaseMin,beatBaseMax].
        -- This is done using a power curve: 
        --    nextNodeStepSize = (1/(MINFREQ + (MAXFREQ-MINFREQ)*(freq_norm_to_use^FREQPOWER)) / totalSteps
        time_to_interp = (1.0/timeseldur)*(time-gen_time_start) --!!time_start
        
        freq_norm_to_use=get_env_interpolated_value(egsliders[1].envelope,time_to_interp, rateInterpolationType)
        if ratemode < 0.5 then
            -- Timebase is time, so step size in seconds
            nextNodeStepSize = (1.0/(timeBaseMin + (timeBaseMax-timeBaseMin)*(freq_norm_to_use^2.0))) / totalSteps
        else
            -- Timebase == beats, so step size in Quarter Notes
            nextNodeStepSize = (4.0/(beatBaseMin + (beatBaseMax-beatBaseMin)*(freq_norm_to_use^2.0))) / totalSteps
        end
  
        ---------------------         
        -- Get info for point
        totalSteps, val, pointShape, pointTension, linearJump = shape_function[shapeSelected](ptcount-phaseStep)
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
                elseif prevShape == 3 then -- Fast start (aka inverse cubic)
                    val = nextVal + (prevVal-nextVal)*((n/(p+n))^3)
                elseif prevShape == 4 then -- Fast end (aka cubic)
                    val = prevVal + (nextVal-prevVal)*((p/(p+n))^3)               
                else -- Linear or Bézier: This interpolation will only be accurate for linear shapes
                    val = prevVal + (nextVal-prevVal) * p / (p+n)
                    pointTension = prevTension
                end         
            else
                return(0) -- entire shape is false
            end
        
        end  
                
        if val == false then -- Skip point
            time=time+nextNodeStepSize
            ptcount=ptcount+1   
        else -- Point will be inserted. Must first calculate value
        -- If linearJump, then oppositeVal must also be calculated               
            if linearJump == true then oppositeVal = -val end
          
            -- fade goes to infinity when trying to calculate point beyond gen_time_end, 
            --    so use timeFadeHack when calculating the point efter end_time.
            fade_gain = 1.0
            timeFadeHack = math.min(time, gen_time_end) 
            if timeFadeHack - gen_time_start < timeseldur*fadindur then
               fade_gain = 1.0/(timeseldur*fadindur)*(timeFadeHack - gen_time_start)
            end
            if timeFadeHack - gen_time_start > timeseldur - timeseldur*fadoutdur then
               --!!fade_gain = 1.0-(1.0/(timeseldur*fadoutdur)*(timeFadeHack - fadoutstart_time - gen_time_start))
               fade_gain = fade_gain * (1.0/(timeseldur*fadoutdur))*(gen_time_end - timeFadeHack)
            end
            
            
            --if time_to_interp<0.0 or time_to_interp>1.0 then
            --  reaper.ShowConsoleMsg(time_to_interp.." ") end
            amp_to_use = get_env_interpolated_value(egsliders[2].envelope,time_to_interp, "linear")
            --if amp_to_use<0.0 or amp_to_use>1.0 then reaper.ShowConsoleMsg(amp_to_use.." ") end
            val=0.5+(0.5*amp_to_use*fade_gain)*val
            local center_to_use=get_env_interpolated_value(egsliders[3].envelope,time_to_interp, "linear")
            local rangea=maxv-minv
            val=minv+((rangea*center_to_use)+(-rangea/2.0)+(rangea/1.0)*val)
            local z=math.random()*randomness
            val=val+(-randomness/2.0)+z
            local tilt_ramp = (time - gen_time_start) / (timeseldur) --!!1.0/(gen_time_end-time_start) * (time-time_start)
            local tilt_amount = -1.0+2.0*tilt
            local tilt_delta = -tilt_amount+(2.0*tilt_amount)*time_to_interp --!!tilt_ramp
            --val=val+tilt_delta
            --[[local num_quansteps=3+quansteps*61
            if num_quansteps<64 then
              val=quantize_value(val,num_quansteps)
            end]]
            if quansteps ~= 1 then
                val=quantize_value(val, 3 + math.ceil(quansteps*125), minv, maxv)
            end          
            
            val=bound_value(minv,val,maxv)
            val = reaper.ScaleToEnvelopeMode(envscalingmode, val)
            tension = segshape*pointTension  
            
            if linearJump == true then
                oppositeVal=0.5+(0.5*amp_to_use*fade_gain)*oppositeVal
                oppositeVal=minv+((rangea*center_to_use)+(-rangea/2.0)+(rangea/1.0)*oppositeVal)
                oppositeVal=oppositeVal+(-randomness/2.0)+z
                if quansteps ~= 1 then
                     oppositeVal=quantize_value(oppositeVal,3 + math.ceil(quansteps*125), minv, maxv)
                end
                oppositeVal=bound_value(minv,oppositeVal,maxv)
                oppositeVal = reaper.ScaleToEnvelopeMode(envscalingmode, oppositeVal)
                --tension = segshape*pointTension -- override val's tension
            end
    
            -- To insert envelope nodes, timebase==beat must be mapped back to timebase==time
            --!!local instime=time
            if ratemode>0.5 then
                instime=reaper.TimeMap2_QNToTime(0, time)
            else
                instime = time
            end
    
            -- Insert point in envelope        
            -- And remember that takes envelopes require a time offset
            if time < gen_time_end then
                if linearJump == true then
                    reaper.InsertEnvelopePointEx(env, selectedAutoItem, instime-timeOffset, val, 0, 0, true, true)
                    reaper.InsertEnvelopePointEx(env, selectedAutoItem, instime-timeOffset, oppositeVal, pointShape, tension, true, true)
                    prevVal = oppositeVal
                else             
                    reaper.InsertEnvelopePointEx(env, selectedAutoItem, instime-timeOffset, val, pointShape, tension, true, true)
                    prevVal = val
                end
                prevTime = instime
                prevShape = pointShape
                prevTension = tension
            else -- interpolate the last envelope point
                isBeyondEnd = true
                --[[if ratemode>0.5 then
                  endTime=reaper.TimeMap2_QNToTime(0, gen_time_end)  
                else
                  endTime=gen_time_end
                end]]
                if prevShape == 0 then -- linear
                    endVal = prevVal + (val-prevVal)*(time_end - prevTime)/(instime-prevTime)
                elseif prevShape == 1 then -- square
                    endVal = prevVal
                elseif prevShape == 2 then -- slow start/end (seems to be sine?)
                    local pifrac    = (math.pi)*(time_end - prevTime)/(instime-prevTime)
                    local cosfrac = (1-math.cos(pifrac))/2
                    endVal = prevVal + cosfrac*(val-prevVal)
                else
                    endVal = prevVal + (val-prevVal)*(time_end-prevTime)/(instime-prevTime)
                end
                -- What shape should the final point have, if endEnvPointFound == false?  
                -- The script uses "square", which keeps the envelope flat till the next point.
                reaper.InsertEnvelopePointEx(env, selectedAutoItem, time_end-timeOffset, endVal, 1, tension, true, false) -- endTime-timeOffset
                
                -- And lastly, insert the endEnvPoint to preserve existing envelope value to right of time selection
                if preserveExistingEnvelope and endEnvPointFound then
                    reaper.InsertEnvelopePointEx(env, selectedAutoItem, time_end - timeOffset, endEnvPoint.value, endEnvPoint.shape, endEnvPoint.tension, true, false)
                end
            end
                
                
            
            --oscphase=oscphase+1.0/((2*3.141592653)/(freqhz))
            time=time+nextNodeStepSize
            --time=time+(1.0/(freqhz*32))
            ptcount=ptcount+1
        end -- if val ~= false
       
    end -- while time<=gen_time_end
     
    --if last_used_parms==nil then last_used_params={"}
    last_used_params[env]={freq,amp,center,phase,randomness,quansteps,tilt,fadindur,fadoutdur,ratemode,clip}
    reaper.Envelope_SortPointsEx(env, selectedAutoItem)
    if envNameOK and envName == "Tempo map" then 
        local firstOK, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker(0, 0)
        if firstOK then
            reaper.SetTempoTimeSigMarker(0, 0, timepos, -1, -1, bpm, timesig_num, timesig_denom, lineartempo)
        end
        reaper.GetSet_LoopTimeRange(true, false, time_start, time_end, false)
        --convert_tempo_env_to_TempoTimeSigMarkers() end
    end
    reaper.UpdateTimeline()
      
    --
end

----------------------------------------------------------

function exit()

    -- Find and store the last-used coordinates of the GUI window, so that it can be re-opened at the same position
    local docked, xPos, yPos, xWidth, yHeight = gfx.dock(-1, 0, 0, 0, 0)
    if docked == 0 and type(xPos) == "number" and type(yPos) == "number" then
        -- xPos and yPos should already be integers, but use math.floor just to make absolutely sure
        reaper.SetExtState("LFO generator", "Last coordinates (env version)", string.format("%i", math.floor(xPos+0.5)) .. "," .. string.format("%i", math.floor(yPos+0.5)), true)
    end
     
    gfx.quit()

    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
        reaper.SetToggleCommandState(sectionID, cmdID, 0)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
    
    --reaper.Undo_OnStateChange("LFO Tool: Envelope",-1)
    if envName then
        undoStr = "LFO Tool: " .. envName
    else
        undoStr = "LFO Tool: Automation"
    end
    reaper.Undo_OnStateChange2(0, undoStr)
end -- function exit()


function getBPM(projtime)
    return(reaper.TimeMap_GetDividedBpmAtTime(projtime))
    --[[
    local currentQN = reaper.TimeMap2_timeToQN(0, projtime)
    local nextQNtime = reaper.TimeMap2_QNToTime(0, currentQN + 1)
    return(60/(nextQNtime-projtime))
    ]]
end

-------------------------------------------------------------------------
-- The function that gets user inputs from the GUI and then draws the CCs
captured_control=nil
was_changed=false
already_added_pt=false
already_removed_pt=false
last_mouse_cap=0

function update()
    
    gfx.update()

    ---------------------------------------------------------------------------
    -- First, test whether the script should exit
    -- Quit script if GUI has been closed, or Esc has been pressed
    local char = gfx.getchar()
    if char<0 or char==27 then return end -- Tests whether GUI has been closed, or Esc has been pressed
    setColor(backgroundColor)
    gfx.rect(0,0,gfx.w,gfx.h,true)
    curenv=reaper.GetSelectedEnvelope(0)
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
    end

    ------------------------------------------------------------------------
    -- Reset several parameters
    -- Including firstClick to prevent long mousebutton press from activating buttons multiple times
    if gfx.mouse_cap==NOTHING then 
        captured_control=nil
        already_added_pt=false 
        already_removed_pt=false
        firstClick = true
        was_changed=false
    end
    
    -----------------------------------------------------------------------
    -- Now, check all the possible combinations of mousebuttons, mousewheel
    --    and mouse position to see what to do
    
    -- Show help menu  
    if (gfx.mouse_cap == LEFTBUTTON
    and gfx.mouse_x > gfx.w-22 and gfx.mouse_y > gfx.h-22) 
    and firstClick == true then
        firstClick = false
        reaper.ClearConsole()
        reaper.ShowConsoleMsg(helpText)
    end  
    
    -- Iterate through all the buttons and sliders in the GUI  
    local dogenerate=false
    for key,tempcontrol in pairs(egsliders) do
    
      --if key>=200 and tempcontrol.type=="Button" then reaper.ShowConsoleMsg(tostring(tempcontrol).." ") end
      if is_in_rect(gfx.mouse_x,gfx.mouse_y,tempcontrol.x(),tempcontrol.y(),tempcontrol.w(),tempcontrol.h()) 
      or (key == slidNum_env and is_in_rect(gfx.mouse_x,gfx.mouse_y,0,tempcontrol.y()-15,gfx.w,tempcontrol.h()+22))
      --get_hot_env_point(tempcontrol,gfx.mouse_x,gfx.mouse_y)>0) -- Envelope gets captured if on hotbutton, even if outside rectangle
      then
          if gfx.mouse_cap==LEFTBUTTON and captured_control==nil then
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
        
            -- Click on Rate/Center/Amplitude buttons to change envelope type
            --[[if gfx.mouse_cap==LEFTBUTTON and (tempcontrol.name=="Rate" or tempcontrol.name=="Amplitude" or tempcontrol.name=="Center") then
                egsliders[100].envelope=tempcontrol.envelope
                egsliders[100].name=tempcontrol.name
                firstClick = false
                dogenerate = true
            end   ]]
            if char == string.byte("r") or (gfx.mouse_cap==LEFTBUTTON and tempcontrol.name=="Rate") then
                egsliders[100].envelope=egsliders[slidNum_rate].envelope
                egsliders[100].name=egsliders[slidNum_rate].name -- = tempcontrol.name
                firstClick = false
                dogenerate = true
            elseif char == string.byte("c") or (gfx.mouse_cap==LEFTBUTTON and tempcontrol.name=="Center") then
                egsliders[100].envelope=egsliders[slidNum_center].envelope
                egsliders[100].name=egsliders[slidNum_center].name -- = tempcontrol.name
                firstClick = false
                dogenerate = true
            elseif char == string.byte("a") or (gfx.mouse_cap==LEFTBUTTON and tempcontrol.name=="Amplitude") then
                egsliders[100].envelope=egsliders[slidNum_amp].envelope
                egsliders[100].name=egsliders[slidNum_amp].name -- tempcontrol.name
                firstClick = false
                dogenerate = true
            end
        
            -- Enable or disable Real-time copy-to-CC
            if gfx.mouse_cap==LEFTBUTTON and tempcontrol.type == "Question" --name=="Real-time copy to CC?") 
            and firstClick == true
            then
              if tempcontrol.value == 0 then
                  tempcontrol.value = 1
              else
                  tempcontrol.value = 0
              end
              firstClick = false
              dogenerate = true
            end 
        
            -- Choose envelope shape
            if gfx.mouse_cap == LEFTBUTTON and tempcontrol.name == "LFO shape?" then
                gfx.x = gfx.mouse_x
                gfx.y = gfx.mouse_y
                retval = gfx.showmenu(shapeMenu)
                if retval ~= 0 then shapeSelected = retval end
                dogenerate = true
                firstClick = false
            end       
        
            --------------------------------------------------------------------------------------------------
            -- Several options when drawing in envelope
            if tempcontrol.type=="Envelope" then
            
              -- Detect hotpoint if hovering over or drag-deleting
              -- The value of the tempcontrol.hotpoint variable is the number of the 'hot'
              --       node of the envelope.  0 if no hotpoint.
              if gfx.mouse_cap==NOTHING or gfx.mouse_cap==(LEFTBUTTON+ALTKEY) then
                tempcontrol.hotpoint=get_hot_env_point(tempcontrol,gfx.mouse_x,gfx.mouse_y)
              end
              
              -- Ctrl+left click in envelope area to set all nodes to same value
              if gfx.mouse_cap == (LEFTBUTTON + CTRLKEY) then
                  pt_y = 1.0/tempcontrol.h()*(gfx.mouse_y-tempcontrol.y())
                  for i = 1, #tempcontrol.envelope do
                      tempcontrol.envelope[i][2] = math.min(1, math.max(0, 1 - pt_y))
                  end
                  dogenerate = true
                  firstClick = false
              end 
              
      
              -- Leftclick to add an envelope node at mouse position
              -- Since the 'capture' area of the envelope area has been expanded, must make sure here that mouse is really inside area
              if tempcontrol.hotpoint==0 and gfx.mouse_cap==LEFTBUTTON and already_added_pt==false 
              and is_in_rect(gfx.mouse_x,gfx.mouse_y,tempcontrol.x(),tempcontrol.y(),tempcontrol.w(),tempcontrol.h()) 
              and tempcontrol == captured_control -- To prevent adding nodes while moving Fade out slider
              then
                  --reaper.ShowConsoleMsg("gonna add point ")
                  local pt_x = 1.0/tempcontrol.w()*(gfx.mouse_x-tempcontrol.x())
                  local pt_y = 1.0/tempcontrol.h()*(gfx.mouse_y-tempcontrol.y())
                  tempcontrol.envelope[#tempcontrol.envelope+1]={math.min(1, math.max(0, pt_x)),
                                                                 math.min(1, math.max(0, 1.0-pt_y)) }
                  dogenerate=true
                  already_added_pt=true
                  sort_envelope(tempcontrol.envelope)
                  firstClick = false
              end
              
              -- Shift+left-drag to add multiple envelope nodes
              -- Ignore already_added_pt to allow left-drag
              -- Since the 'capture' area of the envelope area has been expanded, must make sure here that mouse is really inside area
              if tempcontrol.hotpoint==0 and gfx.mouse_cap==(LEFTBUTTON+SHIFTKEY) 
              and is_in_rect(gfx.mouse_x,gfx.mouse_y,tempcontrol.x(),tempcontrol.y(),tempcontrol.w(),tempcontrol.h()) 
              then --and already_added_pt==false then
                  --reaper.ShowConsoleMsg("gonna add point ")
                  local pt_x = 1.0/tempcontrol.w()*(gfx.mouse_x-tempcontrol.x())
                  local pt_y = 1.0/tempcontrol.h()*(gfx.mouse_y-tempcontrol.y())
                  tempcontrol.envelope[#tempcontrol.envelope+1]={math.min(1, math.max(0, pt_x)),
                                                                 math.min(1, math.max(0, 1.0-pt_y)) }
                  dogenerate=true
                  already_added_pt=true
                  sort_envelope(tempcontrol.envelope)
                  firstClick = false
              end
              
              --Remove envelope point under mouse
              --Prevent removal of endpoint nodes
              --if already_removed_pt==false and tempcontrol.hotpoint>0 and gfx.mouse_cap == 17  then
              if tempcontrol.hotpoint > 0 and gfx.mouse_cap == (LEFTBUTTON+ALTKEY)
                  and not (tempcontrol.hotpoint == 1 or tempcontrol.hotpoint == #tempcontrol.envelope)
                  then
                  table.remove(tempcontrol.envelope,tempcontrol.hotpoint)
                  dogenerate=true
                  firstClick = false
                  --already_removed_pt=true
                  --reaper.ShowConsoleMsg("remove pt "..tempcontrol.hotpoint)
              end  
                           
              -- Move existing envelope node
              if tempcontrol==captured_control and tempcontrol.hotpoint>0 and gfx.mouse_cap==LEFTBUTTON then
                  local pt_x = (1.0/captured_control.w())*(gfx.mouse_x-captured_control.x())
                  local pt_y = (1.0/captured_control.h())*(gfx.mouse_y-captured_control.y())
                  ept = captured_control.envelope[captured_control.hotpoint]
                  if tempcontrol.hotpoint == 1 then 
                      ept[1]=0
                  elseif tempcontrol.hotpoint == #tempcontrol.envelope then
                      ept[1]=1
                  else
                      ept[1]=math.min(1, math.max(0, pt_x))
                  end
                  ept[2]=math.min(1, math.max(0, 1.0-pt_y))
                  dogenerate=true
                  firstClick = false
                  --reaper.ShowConsoleMsg("would drag pt "..tempcontrol.hotpoint.."\n")
              end
      
              -- Fine adjust hotpoint using mousewheel
              if tempcontrol.hotpoint>0 and gfx.mouse_cap==NOTHING and gfx.mouse_wheel ~= 0 then
                  if gfx.mouse_wheel < 0 then fineAdjust = -math.abs(fineAdjust) else fineAdjust = math.abs(fineAdjust) end
                  gfx.mouse_wheel = 0
                  tempcontrol.envelope[tempcontrol.hotpoint][2] = math.min(1, math.max(0, tempcontrol.envelope[tempcontrol.hotpoint][2] + fineAdjust))
                  dogenerate=true
                  --reaper.ShowConsoleMsg("would drag pt "..tempcontrol.hotpoint.."\n")
              end
              
                              
              -- Ctrl+mousewheel for fine adjustment of all points simultaneously
              if gfx.mouse_cap == CTRLKEY and gfx.mouse_wheel ~= 0 then
                  if gfx.mouse_wheel < 0 then fineAdjust = -math.abs(fineAdjust) else fineAdjust = math.abs(fineAdjust) end
                  gfx.mouse_wheel = 0
                  for i = 1, #tempcontrol.envelope do
                      tempcontrol.envelope[i][2] = math.min(1, math.max(0, tempcontrol.envelope[i][2] + fineAdjust))
                  end
                  dogenerate = true
              end 
        
              -- Rightclick away from nodes: select rate and time display
              if type(tempcontrol.hotpoint)=="number" and tempcontrol.hotpoint<=0
                  and gfx.mouse_cap==RIGHTBUTTON 
                  then
                  gfx.x = gfx.mouse_x; gfx.y = gfx.mouse_y
                  if hotpointRateDisplayType == "frequency" then
                      rateMenuString = "#Display hotpoint rate as|!Time (Frequency)|Beats (Period note length)"
                  else
                      rateMenuString = "#Display hotpoint rate as|Time (Frequency)|!Beats (Period note length)"
                  end 
                  
                  if hotpointTimeDisplayType == -1 then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|!Project default|Time|Measures.beats+time|Measures.beats|Seconds|Samples|h:m:s:f|Normalized|Do not display time"
                  elseif hotpointTimeDisplayType == 0 then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|Project default|!Time|Measures.beats+time|Measures.beats|Seconds|Samples|h:m:s:f|Normalized|Do not display time"
                  elseif hotpointTimeDisplayType == 1 then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|Project default|Time|!Measures.beats+time|Measures.beats|Seconds|Samples|h:m:s:f|Normalized|Do not display time"
                  elseif hotpointTimeDisplayType == 2 then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|Project default|Time|Measures.beats+time|!Measures.beats|Seconds|Samples|h:m:s:f|Normalized|Do not display time"
                  elseif hotpointTimeDisplayType == 3 then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|Project default|Time|Measures.beats+time|Measures.beats|!Seconds|Samples|h:m:s:f|Normalized|Do not display time"
                  elseif hotpointTimeDisplayType == 4 then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|Project default|Time|Measures.beats+time|Measures.beats|Seconds|!Samples|h:m:s:f|Normalized|Do not display time"
                  elseif hotpointTimeDisplayType == 5 then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|Project default|Time|Measures.beats+time|Measures.beats|Seconds|Samples|!h:m:s:f|Normalized|Do not display time"
                  elseif hotpointTimeDisplayType == 6 then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|Project default|Time|Measures.beats+time|Measures.beats|Seconds|Samples|h:m:s:f|!Normalized|Do not display time"
                  else --if hotpointTimeDisplayType == false then
                      rateMenuString = rateMenuString .. 
                      "||#Display hotpoint position as|Project default|Time|Measures.beats+time|Measures.beats|Seconds|Samples|h:m:s:f|Normalized|!Do not display time"
                  end
                  
                  retval = gfx.showmenu(rateMenuString)
                  if retval == 2 then hotpointRateDisplayType = "frequency" 
                  elseif retval == 3 then hotpointRateDisplayType = "period note length" 
                  elseif type(retval) == "number" and retval > 3 then hotpointTimeDisplayType = retval-6
                  end
                  
                  dogenerate = true       
              end
        
              -- If Rate: Ctrl-RightClick to quantize period of ALL nodes
              if tempcontrol.name == "Rate" and gfx.mouse_cap==CTRLKEY+RIGHTBUTTON then
                  gfx.x = gfx.mouse_x; gfx.y = gfx.mouse_y
                  local tableNoteRates = {nil, 32.0, 16.0*3.0/2.0, 16.0, 8.0*3.0/2.0, 8.0, 4.0*3.0/2.0, 4.0, 2.0*3.0/2.0, 2.0, 1.0, 0.5}                                            
                  quantmenuSel = gfx.showmenu("#Set rate at ALL nodes to:|1/32|1/16 triplet|1/16|1/8 triplet|1/8|1/4 triplet|1/4|1/2 triplet|1/2|Whole note|Two whole notes||Custom note length (beats)||Custom frequency (time)")
                  userNoteFound = false
                  userFreqFound = false
                  if quantmenuSel >= 2 and quantmenuSel <= #tableNoteRates then 
                      --local tableNoteRates = {nil, (1/64)*(2/3), (1/64), (1/32)*(2/3), (1/32), (1/16)*(2/3), (1/16), (1/8)*(2/3), (1/8), (1/4)*(2/3), (1/4), (1/2)*(2/3), (1/2), 1}
                      userNote = tableNoteRates[quantmenuSel]
                      userNoteFound = true
                  elseif quantmenuSel == #tableNoteRates + 1 then
                      repeat
                          retval, userNote = reaper.GetUserInputs("Set rate at all nodes", 1, "Periods per whole note", "")
                          userNote = tonumber(userNote)
                          if type(userNote) == "number" and userNote > 0 then -- >= beatBaseMin and userNote <= beatBaseMax  then 
                              userNoteFound = true 
                          end
                      until retval == false or userNoteFound == true
                  elseif quantmenuSel == #tableNoteRates + 2 then
                      repeat
                          retval, userFreq = reaper.GetUserInputs("Set rate at all nodes", 1, "Frequency in Hz"
                                                                                             --[[
                                                                                             .. " ("
                                                                                             .. tostring(timeBaseMin) 
                                                                                             .. "-" 
                                                                                             .. tostring(timeBaseMax)
                                                                                             .. ")"
                                                                                             ]]
                                                                                             , "")
                          userFreq = tonumber(userFreq)
                          if type(userFreq) == "number" and userFreq > 0 then -- >= timeBaseMin and userFreq <= timeBaseMax then 
                              userFreqFound = true 
                          end
                      until retval == false or userFreqFound == true
                  end
                    
                  if userNoteFound == true and egsliders[slidNum_timebase].value == 0 
                      and type(time_end) == "number" and type(time_start) == "number" and time_start<=time_end then
                      for i = 1, #tempcontrol.envelope do
                          local bpm = getBPM(time_start + tempcontrol.envelope[i][1]*(time_end-time_start))
                          local userFreq = (1.0/240) * userNote * bpm
                          tempcontrol.envelope[i][2] = math.min(1, math.max(0, ((1.0/(timeBaseMax - timeBaseMin)) * (userFreq-timeBaseMin))^(0.5)))
                      end
                      dogenerate = true
                  elseif userFreqFound == true and egsliders[slidNum_timebase].value == 0 then
                      local normalizedValue = ((1.0/(timeBaseMax - timeBaseMin)) * (userFreq-timeBaseMin))^(0.5)
                      for i = 1, #tempcontrol.envelope do
                          tempcontrol.envelope[i][2] = math.min(1, math.max(0, normalizedValue))
                      end
                      dogenerate = true
                  elseif userNoteFound == true and egsliders[slidNum_timebase].value == 1 then
                      local normalizedValue = ((1.0/(beatBaseMax - beatBaseMin)) * (userNote-beatBaseMin))^(0.5)
                      for i = 1, #tempcontrol.envelope do
                          tempcontrol.envelope[i][2] = math.min(1, math.max(0, normalizedValue))
                      end
                      dogenerate = true
                  elseif userFreqFound == true and egsliders[slidNum_timebase].value == 1 
                      and type(time_end) == "number" and type(time_start) == "number" and time_start<=time_end then
                      for i = 1, #tempcontrol.envelope do
                          local timeStartQN = reaper.TimeMap_timeToQN(time_start)
                          local timeEndQN = reaper.TimeMap_timeToQN(time_end)
                          local timeAtNode = reaper.TimeMap_QNToTime(timeStartQN + tempcontrol.envelope[i][1]*(timeEndQN-timeStartQN))
                          local bpm = getBPM(timeAtNode)
                          local userNote = (1.0/bpm) * 240.0 * userFreq
                          tempcontrol.envelope[i][2] = math.min(1, math.max(0, ((1.0/(beatBaseMax - beatBaseMin)) * (userNote-beatBaseMin))^(0.5)))
                      end
                      dogenerate = true
                  end 
                                          
              end -- if tempcontrol.name == "Rate" and gfx.mouse_cap==CTRLKEY+RIGHTBUTTON
              
              
              -- If Rate and right-click on hotpoint: Quantize period of hotpoint
              if tempcontrol.name == "Rate" and tempcontrol.hotpoint>0 and gfx.mouse_cap==RIGHTBUTTON then
                  gfx.x = gfx.mouse_x; gfx.y = gfx.mouse_y
                  local tableNoteRates = {nil, 32.0, 16.0*3.0/2.0, 16.0, 8.0*3.0/2.0, 8.0, 4.0*3.0/2.0, 4.0, 2.0*3.0/2.0, 2.0, 1.0, 0.5}                                            
                  quantmenuSel = gfx.showmenu("#Set rate at node to:|1/32|1/16 triplet|1/16|1/8 triplet|1/8|1/4 triplet|1/4|1/2 triplet|1/2|Whole note|Two whole notes||Custom note length (beats)||Custom frequency (time)")
                  userNoteFound = false
                  userFreqFound = false
                  if quantmenuSel >= 2 and quantmenuSel <= #tableNoteRates then 
                      --local tableNoteRates = {nil, (1/64)*(2/3), (1/64), (1/32)*(2/3), (1/32), (1/16)*(2/3), (1/16), (1/8)*(2/3), (1/8), (1/4)*(2/3), (1/4), (1/2)*(2/3), (1/2), 1}
                      userNote = tableNoteRates[quantmenuSel]
                      userNoteFound = true
                  elseif quantmenuSel == #tableNoteRates + 1 then
                      repeat
                          retval, userNote = reaper.GetUserInputs("Set rate at node", 1, "Periods per whole note", "")
                          userNote = tonumber(userNote)
                          if type(userNote) == "number" and userNote > 0 then -- >= beatBaseMin and userNote <= beatBaseMax  then 
                              userNoteFound = true 
                          end
                      until retval == false or userNoteFound == true
                  elseif quantmenuSel == #tableNoteRates + 2 then
                      repeat
                          retval, userFreq = reaper.GetUserInputs("Set rate at node", 1, "Frequency in Hz"
                                                                                      --[[
                                                                                      .. " ("
                                                                                      .. tostring(timeBaseMin) 
                                                                                      .. "-" 
                                                                                      .. tostring(timeBaseMax)
                                                                                      .. ")"
                                                                                      ]]
                                                                                      , "")
                          userFreq = tonumber(userFreq)
                          if type(userFreq) == "number" and userFreq > 0 then -- >= timeBaseMin and userFreq <= timeBaseMax then 
                              userFreqFound = true 
                          end
                      until retval == false or userFreqFound == true
                  end
                  
                  if userNoteFound == true and egsliders[slidNum_timebase].value == 0 
                      and type(time_end) == "number" and type(time_start) == "number" and time_start<=time_end then
                      local bpm = getBPM(time_start + tempcontrol.envelope[tempcontrol.hotpoint][1]*(time_end-time_start))
                      local userFreq = (1.0/240.0) * userNote * bpm
                      tempcontrol.envelope[tempcontrol.hotpoint][2] = math.min(1, math.max(0, ((1.0/(timeBaseMax - timeBaseMin)) * (userFreq-timeBaseMin))^(0.5)))
                      dogenerate = true                                            
                  elseif userFreqFound == true and egsliders[slidNum_timebase].value == 0 then
                      tempcontrol.envelope[tempcontrol.hotpoint][2] = math.min(1, math.max(0, ((1.0/(timeBaseMax - timeBaseMin)) * (userFreq-timeBaseMin))^(0.5)))
                      dogenerate = true
                  elseif userNoteFound == true and egsliders[slidNum_timebase].value == 1 then
                      tempcontrol.envelope[tempcontrol.hotpoint][2] = math.min(1, math.max(0, ((1.0/(beatBaseMax - beatBaseMin)) * (userNote-beatBaseMin))^(0.5)))
                      dogenerate = true
                  elseif userFreqFound == true and egsliders[slidNum_timebase].value == 1 
                      and type(time_end) == "number" and type(time_start) == "number" and time_start<=time_end then
                      local timeStartQN = reaper.TimeMap_timeToQN(time_start)
                      local timeEndQN = reaper.TimeMap_timeToQN(time_end)
                      local timeAtNode = reaper.TimeMap_QNToTime(timeStartQN + tempcontrol.envelope[tempcontrol.hotpoint][1]*(timeEndQN-timeStartQN))
                      local bpm = getBPM(timeAtNode)
                      local userNote = (1.0/bpm) * 240.0 * userFreq
                      tempcontrol.envelope[tempcontrol.hotpoint][2] = math.min(1, math.max(0, ((1.0/(beatBaseMax - beatBaseMin)) * (userNote-beatBaseMin))^(0.5)))
                      dogenerate = true
                  end              
              end -- if tempcontrol.name == "Rate" and tempcontrol.hotpoint>0 and gfx.mouse_cap==RIGHTBUTTON
              
              
              -- If Amplitude or Center and rightclick on hotpoint: Set to precise custom value
              if (tempcontrol.name == "Amplitude" or tempcontrol.name == "Center") 
                  and tempcontrol.hotpoint>0 
                  and gfx.mouse_cap==RIGHTBUTTON 
                  then
                  repeat
                          retval, userVal = reaper.GetUserInputs("Set node value", 1, "Node value (normalized)", "")
                          userVal = tonumber(userVal)
                  until retval == false or (retval == true and type(userVal)=="number" and userVal >= 0 and userVal <= 1)
                  
                  if retval == true then
                      tempcontrol.envelope[tempcontrol.hotpoint][2] = userVal
                      dogenerate = true
                  end 
              end
              
              
              -- If Amplitude or Center and Ctrl-rightclick: Set ALL nodes to precise custom value
              if (tempcontrol.name == "Amplitude" or tempcontrol.name == "Center") 
                  and gfx.mouse_cap==CTRLKEY+RIGHTBUTTON 
                  then
                  repeat
                          retval, userVal = reaper.GetUserInputs("Set value of all nodes", 1, "Node value (normalized)", "")
                          userVal = tonumber(userVal)
                  until retval == false or (retval == true and type(userVal)=="number" and userVal >= 0 and userVal <= 1)
                  
                  if retval == true then                  
                      for i = 1, #tempcontrol.envelope do
                          tempcontrol.envelope[i][2] = math.min(1, math.max(0, userVal))
                      end                 
                      dogenerate = true        
                  end
              end              
                            
          end -- if tempcontrol.type=="Envelope"
                  
      end -- if is_in_rect
      
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
      end -- if captured_control~=nil
      
      draw_slider(tempcontrol)
      draw_envelope(tempcontrol,env_enabled)
    end -- for key,tempcontrol in pairs(egsliders)
  
  ---------------------------------------------
  -- If right-click, show save/load/delete menu
  -- (But not if in envelope drawing area)
  if gfx.mouse_cap == RIGHTBUTTON and not is_in_rect(gfx.mouse_x,
                                                     gfx.mouse_y,
                                                     0, --egsliders[100].x(),
                                                     egsliders[100].y(),
                                                     gfx.w, --egsliders[100].w(),
                                                     gfx.h - egsliders[100].y()) --egsliders[100].h()) 
                                                     then
  
      --reaper.DeleteExtState("LFO generator", "savedCurves", true) -- delete the ExtState
  
      -------------------------------
      -- First, try to load all saved curves
      getSavedCurvesAndNames()
      
      local gotSavedNames
      loadStr = ""
      if savedNames ~= nil and type(savedNames) == "table" and #savedNames > 0 then

          gotSavedNames = true
          loadStr = ">Load curve"
          for i = 1, #savedNames do
              loadStr = loadStr .. "|" .. savedNames[i]
          end
          
          loadStr = loadStr .. "|<||>Delete curve"
          for i = 1, #savedNames do
              loadStr = loadStr .. "|" .. savedNames[i] 
          end
          loadStr = loadStr .. "|<||"           
      else
          gotSavedNames = false
          loadStr = "#Load curve||#Delete curve||"
      end
      
      saveLoadString = "Save curve||" .. loadStr .. "Reset curve"     
      
      
      ----------------------------------------
      -- Show save/load/delete menu
      gfx.x = gfx.mouse_x; gfx.y = gfx.mouse_y
      menuSel = gfx.showmenu(saveLoadString)
      
      if menuSel == 0 then  
          -- do nothing
          
      --------------   
      -- Reset curve
      elseif (gotSavedNames == true and menuSel == 2 + 2*#savedNames)
          or (gotSavedNames == false and menuSel == 4)
          then
          egsliders[slidNum_rate].envelope = {{0,0.5}, {1,0.5}}
          egsliders[slidNum_amp].envelope = {{0,0.5}, {1,0.5}}
          egsliders[slidNum_center].envelope = {{0,0.5}, {1,0.5}}
          dogenerate = true
          
          -------------------------------------------------------
          -- Draw the newly loaded envelope
          if egsliders[100].name == egsliders[1].name then -- "Rate"
              egsliders[100]=make_envelope(borderWidth, envYpos, 0, envHeight, egsliders[1])
          elseif egsliders[100].name == egsliders[2].name then -- "Amplitude"
              egsliders[100]=make_envelope(borderWidth, envYpos, 0, envHeight, egsliders[2])
          else -- "Center"
              egsliders[100]=make_envelope(borderWidth, envYpos, 0, envHeight, egsliders[3])
          end

      ------------------------
      -- Save curve
      elseif menuSel == 1 then
          repeat
              retval, curveName = reaper.GetUserInputs("Save curve", 1, "Curve name (no | or ,)", "")
          until retval == false or (curveName:find("|") == nil and curveName:find(",") == nil and curveName:len()>0)
          
          if retval ~= false then
              saveString = curveName
              for i = 0, 11 do
                  if egsliders[i] == nil then -- skip
                  elseif egsliders[i].name == "LFO shape?" then saveString = saveString .. ",LFO shape?," .. tostring(shapeSelected)
                  --elseif egsliders[i].name == "Real-time copy to CC?" then saveString = saveString .. ",Real-time copy to CC?," .. tostring(egsliders[i].enabled) 
                  elseif egsliders[i].name == "Phase step" then saveString = saveString .. ",Phase step," .. tostring(egsliders[i].value)
                  elseif egsliders[i].name == "Randomness" then saveString = saveString .. ",Randomness," .. tostring(egsliders[i].value)
                  elseif egsliders[i].name == "Quant steps" then saveString = saveString .. ",Quant steps," .. tostring(egsliders[i].value)
                  elseif egsliders[i].name == "Bezier shape" then saveString = saveString .. ",Bezier shape," .. tostring(egsliders[i].value)
                  elseif egsliders[i].name == "Fade in duration" then saveString = saveString .. ",Fade in duration," .. tostring(egsliders[i].value)
                  elseif egsliders[i].name == "Fade out duration" then saveString = saveString .. ",Fade out duration," .. tostring(egsliders[i].value)
                  elseif egsliders[i].name == "Timebase?" then saveString = saveString .. ",Timebase?," .. tostring(egsliders[i].value)
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
      --if egsliders[10].value>0.5 then use_note_rates=true else use_note_rates=false end 
      generate(egsliders[1].value, -- freq
             egsliders[2].value, -- amp
             egsliders[3].value, -- center
             egsliders[4].value, -- phase
             egsliders[5].value, -- randomness
             egsliders[6].value, -- quansteps
             egsliders[7].value, -- tilt
             egsliders[8].value, -- fadindur
             egsliders[9].value, -- fadoutdur
             egsliders[10].value, -- timebase (aka ratemode)
             clip)      
      was_changed=true
      -- Julian's mod: Real-time copy to CC
      if egsliders[slidNum_copyCC].value == 1 then
          editor = reaper.MIDIEditor_GetActive()
          reaper.MIDIEditor_OnCommand(editor, commandID)    
      end
  end
  last_mouse_cap=gfx.mouse_cap
  
  reaper.defer(update)
end

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
        -- For compatibility with previous version that only has timebase=time, timebase is set to 0 by default
        egsliders[slidNum_timebase].value = 0
        
        for i = 0, 11 do
            --reaper.ShowConsoleMsg("\nsliderName = ")
            sliderName = nextStr()
            if sliderName == nil then -- do nothing
            elseif sliderName  == "LFO shape?" then shapeSelected = tonumber(nextStr())
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
            elseif sliderName == "Timebase?" then egsliders[slidNum_timebase].value = tonumber(nextStr())
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
        
        generate(egsliders[1].value, -- freq
               egsliders[2].value, -- amp
               egsliders[3].value, -- center
               egsliders[4].value, -- phase
               egsliders[5].value, -- randomness
               egsliders[6].value, -- quansteps
               egsliders[7].value, -- tilt
               egsliders[8].value, -- fadindur
               egsliders[9].value, -- fadoutdur
               egsliders[10].value, -- timebase (aka ratemode)
               clip)
               was_changed=true
                      
    end -- savedCurves ~= nil and #savedCurves ~= nil and

end -- loadCurve()

-------------------------------
function showErrorMsg(errorMsg)
    if verbose == true and type(errorMsg) == "string" then
        reaper.ShowConsoleMsg("\n\nERROR:\n" 
                              .. errorMsg 
                              .. "\n\n"
                              .. "(To prevent future error messages, set 'verbose' to 'false' in the USER AREA near the beginning of the script.)"
                              .. "\n\n")
    end
end -- showErrorMsg(errorMsg)


---------------------------------------------------
-- Here the main part of the code starts execution
---------------------------------------------------
if type(defaultCurveName) ~= "string" then
    reaper.ShowMessageBox("The setting 'defaultCurveName' must be a string.", "ERROR", 0) return(false) end
if type(backgroundColor) ~= "table" 
    or type(foregroundColor) ~= "table" 
    or type(textColor) ~= "table" 
    or type(buttonColor) ~= "table" 
    or type(hotbuttonColor) ~= "table"
    or #backgroundColor ~= 4 
    or #foregroundColor ~= 4 
    or #textColor ~= 4 
    or #buttonColor ~= 4 
    or #hotbuttonColor ~= 4 
    then
    reaper.ShowMessageBox("The custom interface colors must each be a table of four values between 0 and 1.", "ERROR", 0) 
    return(false) 
    end
if type(shadows) ~= "boolean" then 
    reaper.ShowMessageBox("The setting 'shadows' must be either 'true' of 'false'.", "ERROR", 0) return(false) end
if type(fineAdjust) ~= "number" or fineAdjust < 0 or fineAdjust > 1 then
    reaper.ShowMessageBox("The setting 'fineAdjust' must be a number between 0 and 1.", "ERROR", 0) return(false) end
if type(preserveExistingEnvelope) ~= "boolean" then 
    reaper.ShowMessageBox("The setting 'preserveExistingEnvelope' must be either 'true' of 'false'.", "ERROR", 0) return(false) end
if type(phaseStepsDefault) ~= "number" or phaseStepsDefault % 4 ~= 0 or phaseStepsDefault <= 0 then
    reaper.ShowMessageBox("The setting 'phaseStepsDefault' must be a positive multiple of 4.", "ERROR", 0) return(false) end
    
if not reaper.APIExists("CountAutomationItems") then
    reaper.ShowMessageBox("Versions 1.30 and higher of the script requires REAPER v5.50 or higher.", "ERROR", 0) return(false) end
if not reaper.APIExists("BR_EnvAlloc") then
    reaper.ShowMessageBox("This script requires the SWS/SNM extension.\n\nThe extension can be downloaded from \nwww.sws-extension.com.", "ERROR", 0) return(false) end

_, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
    reaper.SetToggleCommandState(sectionID, cmdID, 1)
    reaper.RefreshToolbar2(sectionID, cmdID)
end  
reaper.atexit(exit)

time_start, time_end = reaper.GetSet_LoopTimeRange(false, false, 0.0, 0.0, false)

-- The GUI window will be opened at the last-used coordinates
local coordinatesExtState = reaper.GetExtState("LFO generator", "Last coordinates (env version)") -- Returns an empty string if the ExtState does not exist
xPos, yPos = coordinatesExtState:match("(%d+),(%d+)") -- Will be nil if cannot match
if xPos and yPos then
    gfx.init("LFO tool",initXsize, initYsize, 0, tonumber(xPos), tonumber(yPos)) -- Interesting, this function can accept xPos and yPos strings, without tonumber
else
    gfx.init("LFO tool",initXsize, initYsize, 0)
end
    
gfx.setfont(1,"Ariel", 15)
for i=0,10 do
  --local buttonkey=(i+200)
  --new_button=make_button(655,12+i*25,20,20,nil)
  --egsliders[buttonkey]=new_button
end
egsliders[1]=make_radiobutton(borderWidth,borderWidth,0,0,0.5,"Rate", function(nx) end)
slidNum_rate = 1
egsliders[2]=make_radiobutton(borderWidth,borderWidth+sliderHeight*1,0,0,0.5,"Amplitude",function(nx) end)
slidNum_amp = 2
egsliders[3]=make_radiobutton(borderWidth,borderWidth+sliderHeight*2,0,0,0.5,"Center",function(nx) end)
slidNum_center = 3
egsliders[10]=make_question(borderWidth,borderWidth+sliderHeight*3,0,0,0.0,"Timebase?",function(nx) end, "Beats", "Time")
slidNum_timebase = 10
egsliders[0]=make_menubutton(borderWidth,borderWidth+sliderHeight*4,0,0,0.0,"LFO shape?",function(nx) end)
slidNum_shape = 0
egsliders[11]=make_question(borderWidth,borderWidth+sliderHeight*5,0,0,0.0,"Real-time copy to CC?",function(nx) end, "Enabled", "Disabled")
slidNum_copyCC = 11
-- The following slider was originally named "Phase"
egsliders[4]=make_slider(borderWidth,borderWidth+sliderHeight*6,0,0,0.0,"Phase step",function(nx) end)
slidNum_phase = 4
egsliders[5]=make_slider(borderWidth,borderWidth+sliderHeight*7,0,0,0.0,"Randomness",function(nx) end)
slidNum_random = 5
egsliders[6]=make_slider(borderWidth,borderWidth+sliderHeight*8,0,0,1.0,"Quant steps",function(nx) end)
slidNum_quant = 6
egsliders[7]=make_slider(borderWidth,borderWidth+sliderHeight*9,0,0,0.7,"Bezier shape",function(nx) end)
slidNum_Bezier = 7
egsliders[8]=make_slider(borderWidth,borderWidth+sliderHeight*10,0,0,0.0,"Fade in duration",function(nx) end)
slidNum_fadein = 8
egsliders[9]=make_slider(borderWidth,borderWidth+sliderHeight*11,0,0,0.0,"Fade out duration",function(nx) end)
slidNum_fadeout = 9
egsliders[100]=make_envelope(borderWidth, envYpos, 0, envHeight,egsliders[1])
slidNum_env = 100 --315-30

--[[for key,tempcontrol in pairs(egsliders) do
  reaper.ShowConsoleMsg(key.." "..tempcontrol.type.." "..tempcontrol.name.."\n")
end]]

-- Load default curve, if any
if getSavedCurvesAndNames() ~= false then
    if savedNames ~= nil and type(savedNames) == "table" and #savedNames > 0 then
        for i = 1, #savedNames do
            if savedNames[i] == defaultCurveName then
                loadCurve(i)
            end
        end
    end
end

update()

--[[ Archive of changelog
 * v0.?
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
    + Saving and loading of curves
    + New interface look
 * v0.91 (2016-05-25)
    + Fixed "attempt to get length of a nil value (global 'savedNames')" bug
 * v0.99 (2016-05-27)
    + The MIDI editor version now available!!
    + Envelope area now resizeable (allowing finer resolution).
    + Alt-drag for quick delete of multiple nodes.
    + Accurate interpolation of Fast start, Fast end shapes.
    + Curve named "default" will be loaded on startup.
 * v0.997 (2016-06-13)
    + Mousewheel can be used for super fine adjustment of node values.
    + Rightclick in envelope area to set the LFO period to precise note lengths.
    + Envelope value displayed above hotpoint.
 * v0.999 (2016-06-13)
    + Changed Rate interpolation between nodes from linear to parabolic.
 * v0.9999 (2016-06-15)
    + Timebase: Beats option
 * v1.0 (2016-06-16)
    + Points at edges of time selection will be preserved, to avoid affecting envelope outside time selection.
 * v1.01 (2016-06-16)
    + Fixed regression in handling of take envelopes.
 * v1.02 (2016-06-17)
    + Envelope outside time selection will be preserved by default, even if no points at edges of time selection.
    + Leftclick only adds a single node point; Shift + Left-drag to add multiple points.
 * v1.03 (2016-06-18)
    + Fixed regression in fade out.
    + Added "Reset curve" option in Save/Load menu.
    + Added optional display of hotpoint time position (in any of REAPER's time formats).
    + Improved sensitivity of nodes at edges of envelope drawing area.
]]

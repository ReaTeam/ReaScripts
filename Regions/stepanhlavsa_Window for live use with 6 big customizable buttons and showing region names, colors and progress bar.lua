-- @description Window for live use with 6 big customizable buttons and showing region names, colors and progress bar
-- @author Stepan Hlavsa
-- @version 1.0
-- @provides [windows] .
-- @screenshot Main window http://stepan.ac-usti.cz/regionnames.png
-- @about
--   Window for live use with 6 big customizable buttons showing region names, colors and progress bar
--
--   - Created for live use with backing tracks
--   - Simple operation even with touch screen devices (like tablets running remote desktop of main computer)
--   - 6 big clickable areas with any assignable Reaper actions
--   - Showing region names and next region during playback
--   - Showing main window with color of current region and progress bar with color of next region (easy visual clues for song parts like chorus or bridge)
--   - All elements are bright and super big, even on small mobile displays.
--
--   - User can change at the begining of the script following parameters: window starting size, font size, size of play/stop sign, height of progress bar, names and IDs of 6 actions.

-- Script by Stepan Hlavsa
-- hlavsa@seznam.cz
-- Version 1.0

-- Window starting position, width and height
x = -8
y = 0
w = 1920
h = 1050

-- Font size of text
fsize=200

-- Size of play triangle and stop rectangle
psize=100

-- Size of rectangle showing progress in the middle of the window
rsize=200

-- IDs and titles of actions for 6 regions
actionArr = {}
aTitleArr = {}

actionArr[1]=40862
aTitleArr[1]="Previous tab"

actionArr[2]=40044
aTitleArr[2]="Play / stop"

actionArr[3]=40861
aTitleArr[3]="Next tab"

actionArr[4]="_SWS_SELPREVMORR"
aTitleArr[4]="Previous region"

actionArr[5]=41175
aTitleArr[5]="Reset MIDI"

actionArr[6]="_SWS_SELNEXTMORR"
aTitleArr[6]="Next Region"

-- Should the window give the focus back to track view after start?
-- If "true", the window will lost focus after start so you can continue
-- using track view hot keys for example. If "false" the window will
-- keep focus after start.
focusOff=true

-------------------------------------------------------------------------------------

stop = false

local function rgb2num(red, green, blue)  
  green = green * 256
  blue = blue * 256 * 256
  
  return red + green + blue
end

local function num2rgb(RGB)  
   local R = RGB & 255
   local G = (RGB >> 8) & 255
   local B = (RGB >> 16) & 255
   R = R/255
   G = G/255
   B = B/255
   return R,G,B
end

local function TextOut(txt,color,alpha,idx,size)
  local __,x,y,w,h = gfx.dock(-1,0,0,0,0)
  
  gfx.setfont(1, "Arial", fsize*size)
  
  local str_w, str_h = gfx.measurestr(txt)
       
  local r,g,b = num2rgb(color)
  
  gfx.set(r,g,b,alpha)
    
  gfx.x = ((gfx.w - str_w) / 2)
  gfx.y = ((gfx.h - (str_h*3)) / 2)+(str_h*idx)
  gfx.drawstr(txt)
end

local function RectOut(Recpos,Reccolor)
  local Ry = gfx.h/2-(rsize/2)
  local r,g,b = num2rgb(Reccolor)
  gfx.set(r,g,b)  
  gfx.rect(0,Ry,gfx.w*Recpos,rsize,1)
end

local function GetRgnName(regionidx)
  local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(nil, regionidx)
  return name,color,pos,rgnend
end

local function GetCurRegion(position)
  local markeridx, regionidx = reaper.GetLastMarkerAndCurRegion(nil,position)
  return regionidx
end

local function GetNextRegion(position)
  local markeridx, regionidx = reaper.GetLastMarkerAndCurRegion(nil,position)
  local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(nil, regionidx)
  local markeridx, nregionidx = reaper.GetLastMarkerAndCurRegion(nil,rgnend)
  return nregionidx
end

local function WriteText()
  local Apos 
  if reaper.GetPlayState() == 1 then
      Apos = reaper.GetPlayPosition()
    else
      Apos = reaper.GetCursorPosition() 
  end
  
  local RgnIdx1 = GetCurRegion(Apos)
  local name1, color1,pos1,rgnend1  = GetRgnName(RgnIdx1)
  local RgnIdx2 = GetNextRegion(Apos)
  local name2, color2,pos2,rgnend2  = GetRgnName(RgnIdx2)
     
  if name1=="" then
    local ret,filename=reaper.EnumProjects(-1, "")    
    name1=string.match(filename, "([^\\]-)$")
  end
     
  -- Background
  gfx.clear = color1

  -- 3 lines to divide 6 regions
  gfx.set(1,1,1,0.8)
  gfx.line(gfx.w/3,0,gfx.w/3,gfx.h)
  gfx.line(gfx.w/3*2,0,gfx.w/3*2,gfx.h)
  gfx.line(0,gfx.h/2,gfx.w,gfx.h/2)
  
  gfx.setfont(1, "Arial", 20)
    
  local i
  local j
    
  -- 6 titles for 6 regions
  for j=1,2 do
    for i=1,3 do
      gfx.x=gfx.w/3*i-gfx.w/6
      gfx.y=gfx.h/2+j*20-40
      gfx.drawstr(aTitleArr[(j-1)*3+i])
    end
  end
  
  
  -- Progress barr
  local rpos = (Apos-pos1)/(rgnend1-pos1)
  if color2==color1 then
      RectOut(rpos,(256*256*256)-1-color2)
    else
      RectOut(rpos,color2)
  end

  -- Region names
  TextOut(name1,(256*256*256)-1-color1,1,0,1)
  TextOut(">>"..name2,(256*256*256)-1-color1,rpos,2,0.8)
  
  -- Play stop sign
  gfx.set(255,0,0)
  if reaper.GetPlayState() == 1 then gfx.triangle(10,10,10+psize,10+(psize/2),10,10+psize)
    elseif reaper.GetPlayState() == 0 then gfx.rect(10,10,psize,psize)
    elseif reaper.GetPlayState() == 2 then 
      gfx.rect(10,10,psize/4,psize) 
      gfx.rect(10+psize/4*2,10,psize/4,psize)  
    elseif reaper.GetPlayState() == 5 then gfx.circle(30,30,20,1) 
  end 
    
  -- Close sign
  gfx.set(255,0,0)
  gfx.line(gfx.w-psize-10,10,gfx.w-10,10+psize)
  gfx.line(gfx.w-10,10,gfx.w-psize-10,10+psize)

  gfx.line(gfx.w-10-psize,10,gfx.w-10,10)
  gfx.line(gfx.w-10,10,gfx.w-10,10+psize)
  gfx.line(gfx.w-10,10+psize,gfx.w-psize-10,10+psize)
  gfx.line(gfx.w-psize-10,10+psize,gfx.w-psize-10,10)
    
end
  
-- Are these coordinates inside the given area?
local function IsInside(ix, iy, iw, ih)
  
  local mouse_x, mouse_y = gfx.mouse_x, gfx.mouse_y
  
  local inside = 
    mouse_x >= ix and mouse_x < (ix + iw) and 
    mouse_y >= iy and mouse_y < (iy + ih)
    
  return inside
  
end

local function CallAction(aID)
  if type(aID)=='number' then 
      reaper.Main_OnCommand(aID,0)
    else
      reaper.Main_OnCommand(reaper.NamedCommandLookup(aID),0)
  end
end 

local function Main()
    
  -- If the left button is down
  if gfx.mouse_cap & 1 == 1 then
        
    -- If the cursor is inside the rectangle AND the button wasn't down before
      if not mouse_btn_down then
        if IsInside(gfx.w-psize-10, 10,gfx.w-10, 10+psize) then stop=true
          elseif
            IsInside(0, 0,gfx.w/3, gfx.h/2) then CallAction(actionArr[1])
          elseif
            IsInside(gfx.w/3, 0, gfx.w/3, gfx.h/2) then  CallAction(actionArr[2])
          elseif
            IsInside(gfx.w/3*2, 0, gfx.w/3, gfx.h/2) then  CallAction(actionArr[3])
          elseif
            IsInside(0, gfx.h/2, gfx.w/3, gfx.h) then CallAction(actionArr[4])
          elseif
            IsInside(gfx.w/3, gfx.h/2, gfx.w/3, gfx.h) then  CallAction(actionArr[5])
          elseif
            IsInside(gfx.w/3*2, gfx.h/2, gfx.w/3, gfx.h) then  CallAction(actionArr[6])
        end
        mouse_btn_down = true
      end
  
    -- If the left button is up
    else
      mouse_btn_down = false
    end
  
  WriteText()
  gfx.update()  

  if stop==false then
      if char ~= 27 and char ~= -1 and char ~= 48 and char ~=13
    then
      reaper.defer(Main)
    end
  end

end

mouse_btn_down=false
gfx.init("Region names", w, h, 0, x, y)

if focusOff then reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_FOCUS_TRACKS"),0) end

Main()


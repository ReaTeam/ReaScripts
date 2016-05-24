--[[
 * ReaScript Name: Live recording take commenter
 * Description: A way to mark audio files during recording
 * Instructions: Run
 * Screenshot: https://www.dropbox.com/s/kp329zcy6jhrumf/TakeCommenterDemo1.gif?dl=1
 * Author: Daxliniere, Heda, Eugen2777, spk77
 * Author URI: forum.cockos.com
 * Repository: ReaTeam > ReaScripts
 * Repository URI: https://github.com/ReaTeam/ReaScripts/
 * Licence: GPL v3
 * Forum Thread: Take Commenter - a way to mark audio files during recording (DONE!)
 * Forum Thread URI: http://forum.cockos.com/showthread.php?p=1677692
 * REAPER: 5.0
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2016-05-17)
	+ Initial Release
--]]

--------------------------------------------------------------------------------
---   Take Commenter.lua  ---   2016-05-17   --------------------------------
--------------------------------------------------------------------------------
---   GUI code by Eugen2777  ---------------------------------------------------
---   Marker writing code by spk77/HeDa  ---------------------------------------
---   Operate during stop-mode code by HeDa  -----------------------------------
---   Hotkey code by HeDa   ----------------------------------------------------
---   Return focus to Arrange Window (pass keystrokes through) by spk77  -------
---   Concept by Dax Liniere  --------------------------------------------------

local Element = {}
function Element:new(x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, norm_val)
    local elm = {}
    elm.def_xywh = {x,y,w,h,fnt_sz} -- its default coord,used for Zoom etc
    elm.x, elm.y, elm.w, elm.h = x, y, w, h
    elm.r, elm.g, elm.b, elm.a = r, g, b, a
    elm.lbl, elm.fnt, elm.fnt_sz  = lbl, fnt, fnt_sz
    elm.norm_val = norm_val
    ------
    setmetatable(elm, self)
    self.__index = self 
    return elm
end
--------------------------------------------------------------
--- Function for Child Classes(args = Child,Parent Class) ----
--------------------------------------------------------------
function extended(Child, Parent)
  setmetatable(Child,{__index = Parent}) 
end
--------------------------------------------------------------
---   Element Class Methods(Main Methods)   ------------------
--------------------------------------------------------------
function Element:update_xywh()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  if Z_w>0.5 and Z_w<3 then  
   self.x, self.w = math.ceil(self.def_xywh[1]* Z_w) , math.ceil(self.def_xywh[3]* Z_w) --upd x,w
  end
  if Z_h>0.5 and Z_h<3 then
   self.y, self.h = math.ceil(self.def_xywh[2]* Z_h) , math.ceil(self.def_xywh[4]* Z_h) --upd y,h
  end
  if Z_w>0.5 or Z_h>0.5  then --fix it!--
     self.fnt_sz = math.max(9,self.def_xywh[5]* (Z_w+Z_h)/2)
     self.fnt_sz = math.min(22,self.fnt_sz)
  end       
end
--------
function Element:pointIN(p_x, p_y)
  return p_x >= self.x and p_x <= self.x + self.w and p_y >= self.y and p_y <= self.y + self.h
end
--------
function Element:mouseIN()
  return gfx.mouse_cap&1==0 and self:pointIN(gfx.mouse_x,gfx.mouse_y)
end
--------
function Element:mouseDown()
  return gfx.mouse_cap&1==1 and self:pointIN(mouse_ox,mouse_oy)
end
--------
function Element:mouseClick()
  return gfx.mouse_cap&1==0 and last_mouse_cap&1==1 and
  self:pointIN(gfx.mouse_x,gfx.mouse_y) and self:pointIN(mouse_ox,mouse_oy)         
end
--------
function Element:draw_frame()
  local x,y,w,h  = self.x,self.y,self.w,self.h
  gfx.rect(x, y, w, h, 0)--frame1
  gfx.roundrect(x, y, w-1, h-1, 3, true)--frame2         
end
--------------------------------------------------------------------------------
---   Create Element Child Classes(Button,Slider,Knob)   -----------------------
--------------------------------------------------------------------------------
local Button ={}; local Knob ={}; local Slider ={}; 
  extended(Button, Element)
  extended(Knob,   Element)
  extended(Slider, Element)
---Create Slider Child Classes(V_Slider,H_Slider)----
local H_Slider ={}; local V_Slider ={};
  extended(H_Slider, Slider)
  extended(V_Slider, Slider)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---   Button Class Methods   ---------------------------------------------------
--------------------------------------------------------------------------------
function Button:draw_lbl()
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local fnt,fnt_sz = self.fnt, self.fnt_sz
    --Draw btn lbl(text)--
      gfx.set(0.7, 1, 0, 1)--set label color
      gfx.setfont(1, fnt, fnt_sz);--set label fnt
        local lbl_w, lbl_h = gfx.measurestr(self.lbl)
        gfx.x = x+(w-lbl_w)/2; gfx.y = y+(h-lbl_h)/2
        gfx.drawstr(self.lbl)
end
---------------------
function Button:draw()
    self:update_xywh()--Update xywh(if wind changed)
    local x,y,w,h  = self.x,self.y,self.w,self.h
    local r,g,b,a  = self.r,self.g,self.b,self.a
    ---Get L_mouse state--
          --in element--
          if self:mouseIN() then a=a+0.1 end
          --in elm L_down--
          if self:mouseDown() then a=a+0.2 end
          --in elm L_up(released and was previously pressed)--
          if self:mouseClick() then self.onClick() end
    --Draw btn(body,frame)--
    gfx.set(r,g,b,a)--set btn color
    gfx.rect(x,y,w,h,true)--body
    self:draw_frame()
    ------------------------
    self:draw_lbl()
end

 reaper.CountTracks(0)
----------------------------------------------------------------------------------------------------
---   START   --------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
local btn1 = Button:new(10,10,70,70, 0.2,0.2,1.0,0.5, "PERFECT","Arial",15, 0 )
local btn2 = Button:new(90,10,70,70, 0.0,1.0,0.0,0.5, "good","Arial",15, 0 )
local btn3 = Button:new(170,10,70,70, 0.0,1.0,0.0,0.5, "not bad","Arial",15, 0 )
local btn4 = Button:new(10,90,70,70, 0.0,1.0,0.0,0.5, "okay","Arial",15, 0 )
local btn5 = Button:new(90,90,70,70, 1.0,0.0,0.0,0.5, "sharp","Arial",15, 0 )
local btn6 = Button:new(170,90,70,70, 1.0,0.0,0.0,0.5, "flat","Arial",15, 0 )
local btn7 = Button:new(10,170,70,70, 1.0,0.0,0.0,0.5, "early","Arial",15, 0 )
local btn8 = Button:new(90,170,70,70, 1.0,0.0,0.0,0.5, "late","Arial",15, 0 )
local btn9 = Button:new(170,170,70,70, 0.5,0.3,0.4,1.0, "double\n check","Arial",15, 0 )

local Button_TB = {btn1,btn2,btn3,btn4,btn5,btn6,btn7,btn8,btn9}


add_marker_to_play_pos =  function(name, r,g,b)
                            local play_state = reaper.GetPlayState()
                            local floor = math.floor
                            r = floor(r*255+0.5)
                            g = floor(g*255+0.5)
                            b = floor(b*255+0.5)                            
                            local int_col=reaper.ColorToNative(r, g, b)|0x1000000
                            reaper.Undo_BeginBlock()
							if play_state == 0 or play_state&2 == 2 then position=reaper.GetCursorPosition() else position=reaper.GetPlayPosition() end
                            idx = reaper.AddProjectMarker2(0, false, position, 0, name, -1, int_col)
                            reaper.Undo_EndBlock("Take Commenter - add marker", -1)
							if reaper.GetPlayState()&4==4 then if not Markers then Markers={} end; table.insert(Markers, idx) end
                          end 
                          
-- Add "on click function" for each button
for i=1, #Button_TB do
  local curr_btn = Button_TB[i]
  curr_btn.onClick = function()
                        add_marker_to_play_pos(curr_btn.lbl, curr_btn.r, curr_btn.g, curr_btn.b)
						-- Set focus to arrange view when button is released
                        reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_FOCUS_ARRANGE_WND"),0)
                      
                      end
curr_btn.onClickKey =
                      function()
                        add_marker_to_play_pos(curr_btn.lbl, curr_btn.r, curr_btn.g, curr_btn.b)
                      
                      end					  
end
----------------------------------------------------------------------------------------------------
---   Main DRAW function   -------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function DRAW()
    for key,btn  in pairs(Button_TB) do btn:draw()  end 
end

--------------------------------------------------------------------------------
--   INIT   --------------------------------------------------------------------
--------------------------------------------------------------------------------
function Init()
	is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
		reaper.SetToggleCommandState(sectionID, cmdID, 1)
		reaper.RefreshToolbar2(sectionID, cmdID)
    --Some gfx Wnd Default Values--------------
    local R,G,B = 20,20,20        --0..255 form
    Wnd_bgd = R + G*256 + B*65536 --red+green*256+blue*65536  
    Wnd_Title,Wnd_W,Wnd_H,Wnd_Dock,Wnd_X,Wnd_Y = "Take Commenter", 250,250, 0,100,320
    --Init window------------------------------
    gfx.clear = Wnd_bgd         
    gfx.init( Wnd_Title, Wnd_W,Wnd_H, Wnd_Dock, Wnd_X,Wnd_Y )
    --Mouse--------------
    last_mouse_cap = 0
    last_x, last_y = 0, 0
end
----------------------------------------
--   Mainloop   ------------------------
----------------------------------------
function mainloop()
    Z_w,Z_h = gfx.w/Wnd_W, gfx.h/Wnd_H
    if gfx.mouse_cap&1==1 and last_mouse_cap&1==0 then 
       mouse_ox, mouse_oy = gfx.mouse_x, gfx.mouse_y 
    end
    Ctrl  = gfx.mouse_cap&4==4
    Shift = gfx.mouse_cap&8==8
    -----------------------
    --DRAW,MAIN functions--
      DRAW()--Main() 
    -----------------------
    -----------------------
    last_mouse_cap = gfx.mouse_cap
    last_x, last_y = gfx.mouse_x, gfx.mouse_y
  
  hotkey = gfx.getchar() 
  if hotkey>=49 and hotkey <=57 then -- numkeys
	Button_TB[hotkey-48].onClickKey()
  end
  if hotkey == 32 then  -- spacebar
      reaper.Main_OnCommand("40044",0) -- play stop
  end
  if hotkey == 42 then  -- * in numpad
	reaper.Main_OnCommand("1013",0) -- record
  end
	
	-- remove the markers added while recording, when it stops
	playstate = reaper.GetPlayState() 
	if playstate&1==0 and prevplaystate&4==4 then
		RemoveMarkers()
	end
	prevplaystate = playstate
	 
    if hotkey~=-1 then reaper.defer(mainloop) end --defer
    -----------  
    gfx.update()
    -----------
end


-- function to remove markers -------------------------
prevplaystate=0
function RemoveMarkers()
	if Markers then
		for f,g in ipairs(Markers) do
			reaper.DeleteProjectMarker(0, g, false)
		end
		Markers=nil
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function exitnow()
  is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
  reaper.SetToggleCommandState(sectionID, cmdID, 0)
  reaper.RefreshToolbar2(sectionID, cmdID)
end
reaper.atexit(exitnow)
Init()
mainloop()

-- @noindex


-- @description TimecodeInput_Module_AZ
-- @version 1.0
-- @author Claudiohbsantos - AZ

---------------------------------------------------------------------------------------


local leftArrow = 1818584692
local upArrow = 30064
local rightArrow = 1919379572
local downArrow = 1685026670
local deleteKey = 6579564
local backspace = 8
local minus = 45
local plus = 43
local spacebar = 32
local enter = 13

local time_mode = 116  -- t button
local beat_mode = 98  -- b button
local ruler_mode = 114  -- r button
local toggle_offset = 111  -- o button

local minusMode = false
local plusMode = false
local resetAutoCompletedTimecode = false

local persistentDefaultTimeInSeconds = nil

---------------------------------------------------------------------------------------


function msg(s) reaper.ShowConsoleMsg(tostring(s)..'\n') end


---------------------------------------------------------------------------------------
--[[
function set_offset()
    offs_mainW = boxWidth
    offs_mainH = 195
    --obj_offs = 10
  
    --gui_aa = 1
    offs_fontname = 'Calibri'
    offs_fontsize = 40      
    local gui_OS = reaper.GetOS()
    if gui_OS == "OSX32" or gui_OS == "OSX64" then offs_fontsize = offs_fontsize - 7 end
    
  mouse = {}
    textbox_t = {}  
    
    gfx.init('Set time offset in sec', offs_mainW, offs_mainH, 0, 300, 300)
    --Lokasenna_WindowAtCenter (offs_mainW,offs_mainH,'Set time offset in sec')
end
]]
---------------------------------------------------------------------------------------

function TextBox(char)
    if not textbox_t.active_char then textbox_t.active_char = 0 end
    if not textbox_t.text        then textbox_t.text = '' end

if  -- numbers input
    (
      ( char >= 48 -- 0
      and char <= 57) -- 9
      )
    then        
    textbox_t.text = textbox_t.text:sub(0,textbox_t.active_char)..
    string.char(char)..
    textbox_t.text:sub(textbox_t.active_char+1)
    textbox_t.active_char = textbox_t.active_char + 1
end

if char == backspace then
    textbox_t.text = textbox_t.text:sub(0,textbox_t.active_char-1)..
    textbox_t.text:sub(textbox_t.active_char+1)
    textbox_t.active_char = textbox_t.active_char - 1
end

if char == deleteKey then
    textbox_t.text = textbox_t.text:sub(0,textbox_t.active_char)..
    textbox_t.text:sub(textbox_t.active_char+2)
    textbox_t.active_char = textbox_t.active_char
end

if char == leftArrow then
    textbox_t.active_char = textbox_t.active_char - 1
end

if char == rightArrow then
    textbox_t.active_char = textbox_t.active_char + 1
end

if char == minus then
    minusMode = not minusMode
    resetAutoCompletedTimecode = not resetAutoCompletedTimecode
    if plusMode then 
      plusMode = false
      resetAutoCompletedTimecode = not resetAutoCompletedTimecode
    end

end

if 
char == plus then
    plusMode = not plusMode
    resetAutoCompletedTimecode = not resetAutoCompletedTimecode
    if minusMode then 
      minusMode = false
      resetAutoCompletedTimecode = not resetAutoCompletedTimecode 
  end
end

if char == spacebar and not minusMode and not plusMode then
    resetAutoCompletedTimecode = not resetAutoCompletedTimecode
end

if char == time_mode then
  parse_mode = 5
  reaper.gmem_write(1,parse_mode )
  
  if offset == 1 then
    real_cur_shift = cur_shift
  else
    real_cur_shift = 0
  end
  
  --set_offset = false
end

if char == beat_mode then
  parse_mode = 2
  reaper.gmem_write(1,parse_mode )
  real_cur_shift = 0
  --set_offset = false
end

if char == ruler_mode then
  parse_mode = -1
  reaper.gmem_write(1,parse_mode )
  real_cur_shift = 0
  --set_offset = false
end


if char == toggle_offset then
  
  if real_cur_shift == 0 then
    real_cur_shift = cur_shift
    offset = 1
  else
    real_cur_shift = 0
    offset = 0
  end
  
  --reaper.gmem_write(0, offset)
  reaper.SetExtState( "GoToTimecode_AZ", "o", offset, false )
end



if textbox_t.active_char < 0 then textbox_t.active_char = 0 end
if textbox_t.active_char > textbox_t.text:len()  then textbox_t.active_char = textbox_t.text:len() end
end


function drawParseMode (parse_mode)
--real_cur_shift = reaper.gmem_read(0 )
print_offset = real_cur_shift-- .." sec offset"
--[[
if real_cur_shift == 0 then
  print_offset = ""
end
]]

  if parse_mode == -1 then
    parseStr = "Ruler"
  else
    if parse_mode == 2 then
      parseStr = "Beat"
    else
      if parse_mode == 5 then
        parseStr = "Timecode ".. print_offset .." sec offset"
      else
        parseStr = "Other"
      end
    end
  end
  
  
  if set_offset == true then
    set_mode = " set offset"
  else
    set_mode = ""
  end
  

gfx.setfont(1, gui_fontname, gui_fontsize - 12)
wordLen = string.len(parseStr..set_mode)*gfx.texth*0.5
gfx.x = obj_mainW/2 - wordLen/3
gfx.y = gui_fontsize/2 - gfx.texth/2 -5 
  gfx.set(   0.6,0.6,1.0,  0.8,  0) -- blue
  gfx.drawstr(parseStr..set_mode)
end 
    



function drawModeSymbol(minusMode,plusMode)

  if minusMode then
  gfx.setfont(1, gui_fontname, gui_fontsize)
  gfx.x = TC_Xplace - gfx.texth/2.8
  gfx.y = obj_offs + gui_fontsize/2 - gfx.texth/2  +20
    gfx.set(   1.0 ,0.6,0.6,  0.8,  0) -- red
    gfx.drawstr("-")
  end 

  if plusMode then
  gfx.setfont(1, gui_fontname, gui_fontsize -8)
  gfx.x = TC_Xplace - gfx.texth/1.9
  gfx.y = obj_offs + gui_fontsize/2 - gfx.texth/2 +20
    gfx.set(   0.6,0.6,1.0,  0.8,  0) -- blue
    gfx.drawstr("+")
  end
end


function drawTimeInputPreview(preview)
  gfx.setfont(1, gui_fontname, gui_fontsize)
  if textbox_t.timeArgPreview then
    TClen = preview:len()

        gfx.x = obj_offs*4  --obj_mainW/2 - TClen*gfx.texth/5.5
        gfx.y = obj_offs*1.15 + gui_fontsize/2 - gfx.texth/2 +20
        TC_Xplace = gfx.x

    gfx.set(  0.5,0.5,0.5,  0.5,  0) -- grey
    gfx.drawstr(preview)

    if not minusMode and not plusMode then
     gfx.set(   0.6,1,0.6,  0.8,  0) -- green
    else 
      if minusMode then
        gfx.set(   1.0 ,0.6,0.6,  0.8,  0) -- red  
      else
        gfx.set(   0.6,0.6,1.0,  0.8,  0) -- blue
      end

    end


    gfx.drawstr(textbox_t.userEnteredDigits)

    textbox_t.timeArgPreview = nil
    textbox_t.drawCursor = false  
  end


end


--------------------------------------------------------------------------------------- 

function combineUserInputWithAutoComplete(arguments,zeroString)
    local formatedInput,autoComplete = "",""
    for char in string.gmatch(zeroString:reverse(),".") do
        if arguments:len() > 0 then
          if string.match(char,"%d") then  
            formatedInput = arguments:sub(-1)..formatedInput
            arguments = arguments:sub(1,-2)
          else
            formatedInput = char..formatedInput
          end
        else
          autoComplete = char..autoComplete
        end    
    end
    if arguments:len() > 0 then formatedInput = arguments..formatedInput end
    local newTimeString = autoComplete .. formatedInput
    return newTimeString,formatedInput,autoComplete
end

function getEditCurInfo(proj)
  local editCurInfo = {}
  editCurInfo.projOffset = reaper.GetProjectTimeOffset(proj,false)
  editCurInfo.relPosition = reaper.GetCursorPositionEx(proj)
  editCurInfo.absPosition = editCurInfo.relPosition + editCurInfo.projOffset 
  parse_mode = reaper.gmem_read(1 )
  editCurInfo.posString = reaper.format_timestr_pos(editCurInfo.relPosition,"",parse_mode)
  if parse_mode == 5 then
    editCurInfo.posString = editCurInfo.posString:sub(1,editCurInfo.posString:len()-3) --remove frames
  end
  return editCurInfo
end

function getInput(arguments,defaultTimeInSeconds)
    if arguments and defaulTimeInSeconds then
        local posInfo = getEditCurInfo(0)
        local zeroString = string.gsub(posInfo.posString,"%d","0")
        local autocompletedDigits = resetAutoCompletedTimecode and zeroString or posInfo.posString
        local newTimeString,userInputString,autoCompletedToDisplay = combineUserInputWithAutoComplete(arguments,autocompletedDigits)
        parse_mode = reaper.gmem_read(1 )
        if parse_mode == 5 then
          newTimeString = newTimeString..":00"  -- add frames
        end
        local userInput = reaper.parse_timestr_len(newTimeString,0,parse_mode)

        if char == enter then
            if minusMode then
                return posInfo.absPosition - userInput - posInfo.projOffset
            elseif plusMode then
                return posInfo.absPosition + userInput - posInfo.projOffset
            else
                return userInput  - posInfo.projOffset
            end
        end
        textbox_t.timeArgPreview = autoCompletedToDisplay
        textbox_t.userEnteredDigits = userInputString
    end
end

function runTimecodeInputBox() 
  char  = gfx.getchar()
  textbox_t.drawCursor = true
  
  TextBox(char) -- perform typing
  
  inputInSeconds = getInput(textbox_t.text,defaulTimeInSeconds)
  
--  draw back
    gfx.set(  1,1,1,  0.2,  0) --rgb a mode
    main_rectH = (gui_fontsize+obj_offs/2+obj_offs*2+20)
    gfx.rect(0,0,obj_mainW, main_rectH, 1) --  draw frame
    gfx.set(  1,1,1,  0.1,  0) --rgb a mode
    gfx.rect(obj_offs, obj_offs+20,  obj_mainW-obj_offs*2,  gui_fontsize+obj_offs/2 ,1)
    
    -- draw describe
    descStr_0= "press"
    descStr_1= "  t  - for h:s:m + offset"
    descStr_2= "  b - for beats"
    descStr_3= "  r  - for use ruler format"
    descStr_4= "  o - for toggle offset"
    gfx.setfont(1, gui_fontname, gui_fontsize - 16)
    wordLen = math.max( descStr_0:len(), descStr_1:len(), descStr_2:len(), descStr_3:len()) * gfx.texth*0.5
    gfx.x = obj_offs*2
    gfx.y = main_rectH + obj_offs/2
      gfx.set(   0.8,0.9,0.7,  0.8,  0) -- soft yellow
      gfx.drawstr(descStr_0.."\n"..descStr_1.."\n"..descStr_2.."\n"..descStr_3.."\n"..descStr_4)
    -----

    drawParseMode (parse_mode)
    drawTimeInputPreview(textbox_t.timeArgPreview)
    drawModeSymbol(minusMode,plusMode)

    if textbox_t.active_char ~= nil then
      alpha  = math.abs((os.clock()%1) -0.5)
      gfx.set(  1,1,1, alpha,  0) --rgb a mode
      
      gfx.x = obj_offs*1.5 + gfx.measurestr(textbox_t.text:sub(0,textbox_t.active_char)) + 2
      gfx.y = obj_offs*1.15 + gui_fontsize/2 - gfx.texth/2 +20
      if textbox_t.drawCursor then gfx.drawstr('|') end
    end
     

  gfx.update()
  last_char = char
  if char ~= -1 and char ~= 27 and char ~= 13  then 
    reaper.defer(runTimecodeInputBox) 
  else 
  
  --[[
    if set_offset == true then
      --real_cur_shift = inputInSeconds
      reaper.gmem_write(0,real_cur_shift )
      reaper.defer(runTimecodeInputBox) 
    else
   ]]
    
    querystate,window_x_position, window_y_position = gfx.dock( -1, 0, 0)

    reaper.SetExtState( "GoToTimecode_AZ", "x", window_x_position, true )
    reaper.SetExtState( "GoToTimecode_AZ", "y", window_y_position, true )
      gfx.quit()
      reaper.atexit(onSuccessfulInput(inputInSeconds)) 
    --end
  end

end 


---------------------------------------------------------------------------------------


function Lokasenna_WindowAtCenter (w, h,windowName)
  
-- thanks to Lokasenna 
  
-- http://forum.cockos.com/showpost.php?p=1689028&postcount=15    

local x = reaper.GetExtState(  "GoToTimecode_AZ", "x" )
local y = reaper.GetExtState(  "GoToTimecode_AZ", "y" )

if x == "" and y == "" then
  local l, t, r, b = 0, 0, w, h    
  local __, __, screen_w, screen_h = reaper.my_getViewport(l, t, r, b, l, t, r, b, 1)
  local xM,yM = reaper.GetMousePosition()
  local screenX = 1
  local screenY = 1
  if xM < 0 then screenX = -1 end
  if yM < 0 then screenY = -1 end
   x, y = screenX*(screen_w - screenX*w) / 2, screenY*(screen_h - screenY*h) / 2 
elseif tonumber(x) == 0 and tonumber(y) == 0 then
  local l, t, r, b = 0, 0, w, h    
  local __, __, screen_w, screen_h = reaper.my_getViewport(l, t, r, b, l, t, r, b, 1)
  local xM,yM = reaper.GetMousePosition()
  local screenX = 1
  local screenY = 1
  if xM < 0 then screenX = -1 end
  if yM < 0 then screenY = -1 end
   x, y = screenX*(screen_w - screenX*w) / 2, screenY*(screen_h - screenY*h) / 2 
end
  gfx.init(windowName, w, h, 0, x, y)  

end


function initGUI(boxWidth,windowName)
  obj_mainW = boxWidth
  obj_mainH = 220
  obj_offs = 10

  gui_aa = 1
  gui_fontname = 'Calibri'
  gui_fontsize = 40      
  local gui_OS = reaper.GetOS()
  if gui_OS == "OSX32" or gui_OS == "OSX64" then gui_fontsize = gui_fontsize - 7 end
  
mouse = {}
  textbox_t = {}  

  Lokasenna_WindowAtCenter (obj_mainW,obj_mainH,windowName)
end

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------




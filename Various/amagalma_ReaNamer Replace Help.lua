-- @noindex

local change = false
------------------------------------------------------------------------------------------------------
local info = {
"--- SINGLE LETTER CLASSES ------------------------------------------------------------------------",
"",
"• x  : (where x is not one of the magic characters ().%+-*?[]^$ represents the character x itself",
"• .  : (a dot) represents all characters",
"• %a : represents all letters",
"• %c : represents all control characters",
"• %d : represents all digits",
"• %l : represents all lowercase letters",
"• %p : represents all punctuation characters",
"• %s : represents all space characters",
"• %u : represents all uppercase letters",
"• %w : represents all alphanumeric characters",
"• %x : represents all hexadecimal digits",
"• %z : represents the character with representation 0",
"• %x : (where x is any non-alphanumeric character) represents the character x",
"",
"• To escape the magic characters preceed by a %",
"",
"• For all classes represented by single letters (%a , %c , etc.), the corresponding uppercase",
"  letter represents the complement of the class.",
"",
"--- SETS -----------------------------------------------------------------------------------------",
"",
"• [set]:  represents the class which is the union of all characters in set",
"• [^set]: represents the complement of set",
"",
"• A range of characters can be specified with a - (for example, [0-7]",
"• All classes %x described above can also be used in set",
"• All other characters in set represent themselves",
"",
"--- MAIN PATTERNS --------------------------------------------------------------------------------",
"",
"• a single character class followed by * matches 0 or more repetitions of characters (longest",
"  possible sequence)",
"• a single character class followed by + matches 1 or more repetitions of characters in the",
"  class (longest sequence)",
"• a single character class followed by - is like * but matches the shortest possible sequence",
"• a single character class followed by ? matches 0 or 1 occurrence of a character in the class",
"",
"• ^ in the beggining anchors the pattern to the beginning of the string.",
"• $ at the end anchors the match at the end of the subject string."
}

------------------------------------------------------------------------------------------------------

local function setposition(y)
  gfx.x = 10
  gfx.y = y
  gfx.a = 1
end

------------------------------------------------------------------------------------------------------

local function MousewheelToFontsize()
  local wheel = gfx.mouse_wheel
  if wheel > 0 then
    fontsize = fontsize + 1
    if fontsize > 22 then
      fontsize = 22
      change = false
    else
      change = true
      reaper.SetExtState("Track-Item Name Manipulation", "Replace Help Font Size", fontsize, 1)
    end
    gfx.mouse_wheel = 0
  elseif wheel < 0 then
    fontsize = fontsize -1
    if fontsize < 17 then
      fontsize = 17
      change = false
    else
      change = true
      reaper.SetExtState("Track-Item Name Manipulation", "Replace Help Font Size", fontsize, 1)
    end
    gfx.mouse_wheel = 0
  end
end

------------------------------------------------------------------------------------------------------

local function Main()
  for i = 1, #info do
    if i == 1 or i == 22 or i == 31 then
      gfx.set(1,.6,.25,1) -- titles color
    else
      gfx.set(.75,.75,.8,1)  -- main text color
    end
    setposition(fontsize*(i-1)*1.05 + 10)
    gfx.printf("%s", info[i])
  end 
  gfx.update()
  MousewheelToFontsize()
  if change == true then
    gfx.quit()
    initialize()
    Main()
    change = false
  elseif change == false then
    local char = gfx.getchar()
    if char ~= 27 and char ~= -1 and change == false then
      reaper.defer(Main)
    else
      reaper.SetExtState("Track-Item Name Manipulation", "Replace Help Is open", "0", 1)
   end
  end
end

------------------------------------------------------------------------------------------------------

function initialize()
   HasState = reaper.HasExtState("Track-Item Name Manipulation", "Replace Help Font Size")
  if not HasState then
    fontsize = 20
  else
    fontsize = tonumber(reaper.GetExtState("Track-Item Name Manipulation", "Replace Help Font Size"))
  end
  gfx.setfont(1, "Courier New", fontsize)
  gfx.clear = reaper.ColorToNative( 4, 15, 47 ) -- background color
  width, height = gfx.measurestr(info[1])
  local title = "ReaNamer   -   Replace Help"
  gfx.init(title, width + fontsize, (fontsize*1.05*(#info)+20), 0, 0, 0)
  change = false
end

------------------------------------------------------------------------------------------------------

reaper.SetExtState("Track-Item Name Manipulation", "Replace Help Is open", "1", 1)
initialize()
Main()

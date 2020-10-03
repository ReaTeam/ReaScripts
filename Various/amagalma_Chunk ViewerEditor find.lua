-- @noindex

local editor_hwnd = reaper.JS_Window_Find( "Chunk Viewer / Editor   -   v", false )
if not editor_hwnd then return end

loadfile(reaper.GetExtState("Lokasenna_GUI", "lib_path_v2") .. "Core.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Options.lua")()

------------------------------------------------------------------------

local function SendKey(nr)
  reaper.JS_WindowMessage_Post(editor_hwnd, "WM_KEYDOWN", nr, 0,0,0)
  reaper.JS_WindowMessage_Post(editor_hwnd, "WM_KEYUP", nr, 0,0,0)
end


local function FindNext()
  if GUI.Val("Direction") == 1 then -- Previous, F2, Up
    SendKey(0x71)
  else -- Next, F3, Down
    SendKey(0x72)
  end
end


function GUI.Textbox:ontype()
  local char = GUI.char
  if self.keys[char] then
    local shift = GUI.mouse.cap & 8 == 8
    if shift and not self.sel_s then
      self.sel_s = self.caret
    end
    local bypass = self.keys[char](self)
    if shift and char ~= GUI.chars.BACKSPACE then
      self.sel_e = self.caret
    elseif not bypass then
      self.sel_s, self.sel_e = nil, nil
    end
  elseif GUI.clamp(32, char, 254) == char then
    if self.sel_s then self:deleteselection() end
    self:insertchar(char)
  end
  self:windowtocaret()
  self.retval = tostring(self.retval)
  self.blink = 0
  reaper.SetExtState("amagalma_Chunk Viewer-Editor", "Find", self.retval, 0)
end


function GUI.Checklist:onmouseup()
  local mouseopt = GUI.mouse.y - (self.y + self.cap_h)
  mouseopt = mouseopt / ((20 + self.pad) * #self.optarray)
  mouseopt = GUI.clamp( math.floor(mouseopt * #self.optarray) + 1 , 1, #self.optarray )
  self.optsel[mouseopt] = not self.optsel[mouseopt] 
  GUI.redraw_z[self.z] = true
  reaper.SetExtState("amagalma_Chunk Viewer-Editor", "MatchCase", self.optsel[1] and 1 or 0, 0)
end


function Quit()
  GUI.quit = true
  gfx.quit()
	reaper.JS_Window_SetFocus( editor_hwnd )
end

reaper.atexit(Quit)

------------------------------------------------------------------------

GUI.name = "Chunk Viewer / Editor Find"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 400, 120
GUI.anchor, GUI.corner = "screen", "C"

GUI.New("FindWhat", "Textbox", {
    z = 1, 
    x = 75,
    y = 12,
    w = GUI.w - 84,
    h = 22,
    caption = "Find what :",
    cap_pos = "left",
    font_a = 3,
    font_b = "monospace",
    color = "txt",
    bg = "wnd_bg",
    shadow = true,
    pad = 8,
    undo_limit = 20
})
GUI.Val("FindWhat", reaper.GetExtState("amagalma_Chunk Viewer-Editor", "Find") or "")

GUI.New("MatchCase", "Checklist", {
    z = 1,
    x = 3,
    y = 56,
    w = 100,
    h = 30,
    caption = "",
    optarray = {"Match case"},
    dir = "v",
    pad = 4,
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = true,
    swap = true,
    opt_size = 20
})

GUI.New("Direction", "Radio", {
    z = 1,
    x = 122,
    y = 51,
    w = 72,
    h = 64,
    caption = "Direction",
    optarray = {"Up     ", "Down"},
    dir = "v",
    font_a = 3,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = true,
    swap = true,
    opt_size = 20
})
GUI.Val("Direction", 2)

GUI.New("Find Next", "Button", {
    z = 1,
    x = GUI.w - 184,
    y = 62,
    w = 80,
    h = 24,
    caption = "Find Next",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = FindNext
})

GUI.New("Cancel", "Button", {
    z = 1,
    x = GUI.w - 90,
    y = 62,
    w = 80,
    h = 24,
    caption = "Cancel",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = Quit
})

------------------------------------------------------------------------

local fonts = GUI.get_OS_fonts()
GUI.fonts.monospace = {fonts.mono, 16}
GUI.colors.txt = {220, 220, 220, 255}


GUI.fonts.version = {fonts.sans, 13, "i"}
GUI.Draw_Version = function ()
  local str = "Chunk Viewer / Editor"
  GUI.font("version")
  GUI.color("gray")
  local str_w, str_h = gfx.measurestr(str)
  gfx.x = gfx.w - str_w - 11
  gfx.y = gfx.h - str_h - 6
  gfx.drawstr(str)
end


local function Checking()
  if GUI.char == GUI.chars.F2 then
    --reaper.ShowConsoleMsg"F2"
    SendKey(0x71)
  elseif GUI.char == GUI.chars.F3 then
    --reaper.ShowConsoleMsg"F3"
    SendKey(0x72)
  end
end


GUI.func = Checking
GUI.freq = 0

reaper.SetExtState("amagalma_Chunk Viewer-Editor", "MatchCase", "0", 0)

GUI.Init()
GUI.elms.FindWhat.focus = true
GUI.Main()

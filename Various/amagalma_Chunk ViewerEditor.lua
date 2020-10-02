-- @description Chunk Viewer/Editor
-- @author amagalma
-- @version 1.21
-- @changelog
--   - Fullscreen mode: real fullscreen mode (instead of previous maximized). Now retains top attach pin when restored
-- @provides amagalma_Chunk ViewerEditor find.lua
-- @link https://forum.cockos.com/showthread.php?t=194369
-- @screenshot https://i.ibb.co/DfZFx9z/amagalma-Chunk-Viewer-Editor.gif
-- @donation https://www.paypal.me/amagalma
-- @about
--   Displays/edits the state chunk of the selected track/item/envelope. Intended for use by developers/scripters.
--
--   - Chunks are automatically indented
--   - Size of indentation set inside the script in User Settings area (default: 2 spaces)
--   - When it loads, the last clicked context (track/item/envelope) is automatically set
--   - Automatic line numbering
--   - Fully re-sizable
--   - Remembers last size & position
--   - Search/Find ability (Ctrl+F)
--   - "Go to next" (F3 key) and "Go to previous" (F2 key)
--   - When Setting chunk, the appropriate and correctly named undo is created
--   - Requires Lokasenna GUI v2 and JS_ReaScriptAPI
--   - Lokasenna GUI v2 is automatically installed if it is not already
--   - Prompt to install JS_ReaScriptAPI if not installed
--   - Fullscreen/Maximize button (Windows only)
--
--   * Inspired by previous works by eugen2777 and sonictim (TJF) *


-- USER SETTINGS ---------------------------------
local number_of_spaces = 2 -- used for indentation
--------------------------------------------------


local version = "1.21"


-- Check if JS_ReaScriptAPI is installed
if not reaper.APIExists("JS_Window_Find") then
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "JS_ReaScriptAPI Installation", 0 )
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then
    reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else
    reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
end


-- Check Lokasenna_GUI library availability --
local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" or not reaper.file_exists(lib_path .. "Core.lua") then
  local not_installed = false
  local Core_library = {reaper.GetResourcePath(), "Scripts", "ReaTeam Scripts", "Development", "Lokasenna_GUI v2", "Library", "Core.lua"}
  local sep = reaper.GetOS():find("Win") and "\\" or "/"
  Core_library = table.concat(Core_library, sep)
  if reaper.file_exists(Core_library) then
    local cmdID = reaper.NamedCommandLookup( "_RS1c6ad1164e1d29bb4b1f2c1acf82f5853ce77875" )
    if cmdID > 0 then
          reaper.MB("Lokasenna's GUI path will be set now. Please, re-run the script", "Lokasenna GUI v2 Installation", 0)
      -- Set Lokasenna_GUI v2 library path.lua
      reaper.Main_OnCommand(cmdID, 0)
      return reaper.defer(function() end)
    else
      not_installed = true
    end
  else
    not_installed = true
  end
  if not_installed then
    reaper.MB("Please right-click and install 'Lokasenna's GUI library v2 for Lua' in the next window. Then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List. After all is set, you can run this script again. Thanks!", "Install Lokasenna GUI v2", 0)
    reaper.ReaPack_BrowsePackages( "Lokasenna GUI library v2 for Lua" )
    return reaper.defer(function() end)
  end
end

-- Load GUI
loadfile(lib_path .. "Core.lua")()
GUI.req("Classes/Class - Menubar.lua")()
GUI.req("Classes/Class - TextEditor.lua")()
GUI.req("Classes/Class - Menubox.lua")()
GUI.req("Classes/Class - Button.lua")()

local _, path, section, cmdID = reaper.get_action_context()
reaper.SetToggleCommandState( section, cmdID, 1 ) -- Set ON
reaper.RefreshToolbar2( section, cmdID )


-- Functions -------------------------------------------------------

local function IndentChunk(chunk)
  if not number_of_spaces then number_of_spaces = 2 end
  local t = {}
  local equilibrium = 0
  local add = false
  local l = 0
  for line in chunk:gmatch("[^\n]+") do
    l = l + 1
    if add then
      equilibrium = equilibrium + 1
      add = false
    end
    if line:find("^<") then
      add = true
    elseif line == ">" then
      equilibrium = equilibrium - 1
    end
    t[l] = (string.rep(string.rep(" ", number_of_spaces), equilibrium) or "") .. line
  end
  return table.concat(t, "\n")
end

local function GetChunk()
  local sorry = "Sorry! Could not get chunk..."
  if GUI.Val("ChooseObj") == 1 then
    local track = reaper.GetSelectedTrack(0,0)
    if track then
      local _, chunk = reaper.GetTrackStateChunk(track, "", false )
      GUI.Val("TextEditor", IndentChunk(chunk) )
    else
      reaper.MB( "No track is selected!", sorry, 0 )
    end
  elseif GUI.Val("ChooseObj") == 2 then
    local item = reaper.GetSelectedMediaItem(0,0)
    if item then
      local _, chunk = reaper.GetItemStateChunk(item, "", false )
      GUI.Val("TextEditor", IndentChunk(chunk) )
    else
      reaper.MB( "No item is selected!", sorry, 0 )
    end
  elseif GUI.Val("ChooseObj") == 3 then
    local env = reaper.GetSelectedEnvelope(0)
    if env then
      local _, chunk = reaper.GetEnvelopeStateChunk( env, "", false )
      GUI.Val("TextEditor", IndentChunk(chunk) )
    else
      reaper.MB( "No envelope is selected!", sorry, 0 )
    end
  end
end

local function SetChunk()
  local ok
  if GUI.Val("TextEditor") == "" then
    reaper.MB( "Empty chunk...", "Can not set chunk!", 0 )
    return
  end
  local success
  if GUI.Val("ChooseObj") == 1 then
    local track = reaper.GetSelectedTrack(0,0)
    if track then
      success = reaper.SetTrackStateChunk( track, GUI.Val("TextEditor"), false )
    end
  elseif GUI.Val("ChooseObj") == 2 then
    local item = reaper.GetSelectedMediaItem(0,0)
    if item then
      success = reaper.SetItemStateChunk( item, GUI.Val("TextEditor"), false )
    end
  elseif GUI.Val("ChooseObj") == 3 then
    local env = reaper.GetSelectedEnvelope(0)
    if env then
      success = reaper.SetEnvelopeStateChunk( env, GUI.Val("TextEditor"), false )
    end
  end
  local A = GUI.Val("ChooseObj")
  local what = A == 1 and "Track" or (A == 2 and "Item" or "Envelope" )
  if success then
    local state = A == 1 and 7 or (A == 2 and 4 or 1 )
    reaper.Undo_OnStateChangeEx2( 0, "Set " .. what .. " Chunk", state, -1 )
  else
    reaper.MB( "Probably, the chunk is not valid...", "Could not set " .. what .. " chunk!", 0 )
  end
end

local TextDigits, TextPad = 2

local function Checking()
  if gfx.w ~= GUI.w or gfx.h ~= GUI.h then
    GUI.w, GUI.h = gfx.w, gfx.h
    GUI.elms.SetChunk_.x = GUI.w - 344
    GUI.elms.SetChunk_:init()
    GUI.elms.SetChunk_:redraw()
    GUI.elms.GetChunk_.x = GUI.w - 241
    GUI.elms.GetChunk_:init()
    GUI.elms.GetChunk_:redraw()
    GUI.elms.TextEditor.w = GUI.w - 4
    GUI.elms.TextEditor.h = GUI.h - 46
    GUI.elms.TextEditor:init()
    GUI.elms.TextEditor:redraw()
    GUI.elms.TextEditor:wnd_recalc()
    GUI.elms.ChooseObj.x = GUI.w - 138
    GUI.elms.ChooseObj:init()
    GUI.elms.ChooseObj:redraw()
  end
  if GUI.elms.TextEditor then
    local cur_digits = #(tostring(#GUI.elms.TextEditor.retval))
    cur_digits = cur_digits > 2 and cur_digits or 2
    if cur_digits ~= TextDigits then
      TextDigits = cur_digits
      TextPad = gfx.measurestr(string.rep("0", TextDigits))
      GUI.elms.TextEditor:init()
      GUI.elms.TextEditor:drawtext()
    end
  end
end

function GUI.TextEditor:init()
  -- Process the initial string; split it into a table by line
  if type(self.retval) == "string" then self:val(self.retval) end
  local x, y, w, h = self.x, self.y, self.w, self.h
  self.buff = GUI.GetBuffer()
  gfx.dest = self.buff
  gfx.setimgdim(self.buff, -1, -1)
  gfx.setimgdim(self.buff, 2*w, h)
  GUI.color(self.bg)
  gfx.rect(0, 0, 2*w, h, 1)
  GUI.color("elm_frame")
  gfx.rect(0, 0, w, h, 0)
  GUI.color("elm_fill")
  gfx.rect(w, 0, w, h, 0)
  gfx.rect(w + 1, 1, w - 2, h - 2, 0)
  local digits = #tostring(#self.retval)
  digits = digits > 2 and digits or 2
  GUI.font(self.font_b)
  self.pad = 6 + gfx.measurestr(string.rep("0", digits))
end

function GUI.TextEditor:getcaret(x, y)
  local tmp = {}
  tmp.x = math.floor(((x - TextPad - self.x) / self.w ) * self.wnd_w) + self.wnd_pos.x
  tmp.y = math.floor((y - (self.y + self.pad)) /  self.char_h) + self.wnd_pos.y
  tmp.y = GUI.clamp(1, tmp.y, #self.retval)
  tmp.x = GUI.clamp(0, tmp.x, #(self.retval[tmp.y] or ""))
  return tmp
end

GUI.TextEditor.keys[6] = function (self) -- Ctrl + F
  local find_hwnd = reaper.JS_Window_Find( "Chunk Viewer / Editor Find", true )
  if find_hwnd then
    reaper.JS_Window_SetFocus( find_hwnd )
  else
    local find_path = GUI.script_path .. "amagalma_Chunk ViewerEditor find.lua"
    local cmd_id = reaper.AddRemoveReaScript( true, 0, find_path, true )
    reaper.Main_OnCommand(cmd_id, 0)
    reaper.AddRemoveReaScript( false, 0, find_path, true )
  end
end

local function esc(s)
  local matches =
  {
    ["^"] = "%^";
    ["$"] = "%$";
    ["("] = "%(";
    [")"] = "%)";
    ["%"] = "%%";
    ["."] = "%.";
    ["["] = "%[";
    ["]"] = "%]";
    ["*"] = "%*";
    ["+"] = "%+";
    ["-"] = "%-";
    ["?"] = "%?";
    ["\0"] = "%z";
  }
  return (s:gsub(".", matches))
end

local function GetString()
  return reaper.GetExtState("amagalma_Chunk Viewer-Editor", "Find"),
  reaper.GetExtState("amagalma_Chunk Viewer-Editor", "MatchCase") == "1"
end


GUI.TextEditor.keys[GUI.chars.F3] = function (self) -- F3 Find next
  local str, MatchCase = GetString()
  if #self.retval == 0 or str == "" or not str then return end
  local name = (#str < 16 and str or str:sub(1, 15) .. "..") .. "'"
  str = MatchCase and str or str:upper()
  local line, character = 1, 1
  if self.caret.x + 1 > #self.retval[self.caret.y] then
    line, character = self.caret.y + 1, 1
  else
    line, character = self.caret.y, self.caret.x + 1
  end
  if line <= #self.retval then
    for i = line, #self.retval do
      local txt = i ~= line and self.retval[i] or self.retval[line]:sub(character)
      txt = MatchCase and txt or txt:upper()
      local pos1, pos2 = txt:find(esc(str))
      if pos1 and pos2 then
        --reaper.ShowConsoleMsg(string.format("Found in line %i from %i to %i\n", i, pos1, pos2))
        pos1 = i ~= line and pos2 or pos2+character-1
        -- Adjust scroll position
        if i > self.wnd_pos.y + self.wnd_h then
          local adjust_scroll = math.floor(self.wnd_h/3)
          local len = self:getwndlength()
          if i + self.wnd_h > len then
            adjust_scroll = i - len + self.wnd_h
          end
          self.wnd_pos.y = i - adjust_scroll
          self:redraw()
        end
        -- Place caret
        self.caret.y, self.caret.x = i, pos1
        self.blink = 0
        -- Make selection (not working ?)
        self.sel_s = {x = pos1 - #str, y = i}
        self.sel_e = {x = pos1, y = i}
        self:drawselection()
        return
      end
    end
  end
  local focus = reaper.JS_Window_GetFocus()
  reaper.MB( "No occurences after current position.", "Can't find '" .. name, 0 )
  reaper.JS_Window_SetFocus( focus )
  return
end

GUI.TextEditor.keys[GUI.chars.F2] = function (self) -- F2 Find previous
  local str, MatchCase = GetString()
  if #self.retval == 0 or str == "" or not str then return end
  local name = (#str < 16 and str or str:sub(1, 15) .. "..") .. "'"
  str = MatchCase and str or str:upper()
  str = str:reverse()
  local line, character = self.caret.y, 1
  if self.caret.x == 0 then
    line, character = self.caret.y - 1, #self.retval[self.caret.y - 1]
  else
    line, character = self.caret.y, self.caret.x + 1
  end
  if line >= 1 then
    for i = line, 1, -1 do
      local txt = i ~= line and self.retval[i] or self.retval[line]:sub(1, character)
      txt = (MatchCase and txt or txt:upper()):reverse()
      local pos1, pos2 = txt:find(esc(str))
      if pos1 and pos2 then
        pos1 = (i ~= line and #txt-pos2 or character-pos2) - 
                            (self.caret.x == #self.retval[self.caret.y] and 1 or 0)
        -- Adjust scroll position
        if i < self.wnd_pos.y then
          local adjust_scroll = math.floor(self.wnd_h/3)
          if i - adjust_scroll < 1 then
            adjust_scroll = 0
          end
          self.wnd_pos.y = i - adjust_scroll
          self:redraw()
        end
        -- Place caret
        self.caret.y, self.caret.x = i, pos1
        self.blink = 0
        -- Make selection (not working ?)
        self.sel_s = {x = pos1 - #str, y = i}
        self.sel_e = {x = pos1, y = i}
        self:drawselection()
        return
      end
    end
  end
  local focus = reaper.JS_Window_GetFocus()
  reaper.MB( "No occurences before current position.", "Can't find '" .. name, 0 )
  reaper.JS_Window_SetFocus( focus )
  return
end

local Maximized = false
local prev_dock, prev_x, prev_y, prev_w, prev_h
local script_hwnd
local win_style

local function Fullscreen()
  Maximized = not Maximized
  GUI.elms.Fullscreen.col_fill = Maximized and "maroon" or "elm_bg"
  GUI.elms.Fullscreen:init()
  GUI.elms.Fullscreen:redraw()
  local _, _, rright = reaper.my_getViewport(0,0,0,0,0,0,0,0, false )
  if Maximized then
    if not win_style then
      win_style = reaper.JS_Window_GetLong( script_hwnd, "STYLE" )
    end
    local _, l, t = reaper.JS_Window_GetClientRect( script_hwnd )
    prev_dock, prev_x, prev_y, prev_w, prev_h = GUI.dock or 0 , l, t, gfx.w, gfx.h
    reaper.JS_Window_SetStyle( script_hwnd, "MAXIMIZE" )
    reaper.JS_Window_Move( script_hwnd, l <= rright and 0 or rright, 0 )
    --reaper.JS_WindowMessage_Send(script_hwnd, "WM_SYSCOMMAND", 0xF030, 0, 0, 0)
  else
    reaper.JS_Window_Show( script_hwnd, "RESTORE" )
    --reaper.JS_Window_SetStyle( script_hwnd, "THICKFRAME|CAPTION|SYSMENU" )
    reaper.JS_Window_Move( script_hwnd, prev_x, prev_y )
    if win_style then
      reaper.JS_Window_SetLong( script_hwnd, "STYLE", win_style )
    end
  end
end

-- Create GUI ------------------------------------------------------

GUI.name = "Chunk Viewer / Editor   -   v" .. version
local Settings = reaper.GetExtState("amagalma_Chunk Viewer-Editor", "Settings")
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 800, 700
GUI.anchor, GUI.corner = "screen", "C"
if Settings and Settings ~= "" then
  local a,b,c,d,e = Settings:match("(%d-) (%-?%d-) (%-?%d-) (%d-) (%d+)")
  GUI.dock, GUI.x, GUI.y, GUI.w, GUI.h = a,b,c,d,e
  GUI.anchor, GUI.corner = "screen", "TL"
end

GUI.freq = 0.5
GUI.func = Checking

GUI.New("TextEditor", "TextEditor", {
    z = 1,
    x = 2,
    y = 30,
    w = GUI.w - 4,
    h = GUI.h - 46,
    caption = "",
    font_a = 3,
    font_b = "monospace",
    color = "txt",
    col_fill = "elm_frame",
    cap_bg = "wnd_bg",
    bg = "black", --"elm_bg",
    shadow = true,
    undo_limit = 24
})

GUI.New("ChooseObj", "Menubox", {
    z = 1,
    x = GUI.w - 138,
    y = 2,
    w = 125,
    h = 26,
    caption = "",
    optarray = {"Track", "Item", "Envelope"},
    retval = reaper.GetCursorContext2( true ) + 1,
    font_a = 3,
    font_b = 2,
    col_txt = "txt",
    col_cap = "txt",
    bg = "wnd_bg",
    pad = 0,
    noarrow = false,
    align = 5
})

GUI.New("SetChunk_", "Button", {
    z = 1,
    x = GUI.w - 344,
    y = 2,
    w = 95,
    h = 25,
    caption = "Set Chunk",
    font = 2,
    col_txt = "txt",
    col_fill = "olive", --"elm_bg",
    func = SetChunk
})

GUI.New("GetChunk_", "Button", {
    z = 1,
    x = GUI.w - 241,
    y = 2,
    w = 95,
    h = 25,
    caption = "Get Chunk",
    font = 2,
    col_txt = "txt",
    col_fill = "green", -- "elm_bg",
    func = GetChunk
})

if reaper.GetOS():find("Win") then
  GUI.New("Fullscreen", "Button", {
      z = 2,
      x = 12,
      y = 2,
      w = 95,
      h = 25,
      caption = "Fullscreen",
      font = 2,
      col_txt = "txt",
      col_fill = "elm_bg",
      func = Fullscreen
  })
end


-- Modified Functions ----------------------------------------------

function GUI.TextEditor:drawtext()
  GUI.font(self.font_b)
  local digits = #tostring(#self.retval)
  digits = digits > 2 and digits or 2
  TextDigits = digits
  TextPad = gfx.measurestr(string.rep("0", digits))
  self.pad = 6 + TextPad
  local tmp = {}
  local numbers = {}
  local n = 0
  for i = self.wnd_pos.y, math.min(self:wnd_bottom() - 1, #self.retval) do
    n = n + 1
    local str = tostring(self.retval[i]) or ""
    tmp[n] = string.sub(str, self.wnd_pos.x + 1, self:wnd_right() - 1 - TextDigits)
    numbers[n] = string.format("%" .. TextDigits .. "i", i)
  end
  GUI.color("gray")
  gfx.x, gfx.y = self.x + self.pad - TextPad, self.y + self.pad
  gfx.drawstr(table.concat(numbers, "\n"))
  GUI.color(self.color)
  gfx.x, gfx.y = self.x + self.pad, self.y + self.pad
  gfx.drawstr( table.concat(tmp, "\n") )
end


local fonts = GUI.get_OS_fonts()
GUI.fonts.monospace = {fonts.mono, 16}
GUI.colors.txt = {220, 220, 220, 255}
GUI.colors.black = {30, 30, 30, 255}
GUI.colors.green = {10, 85, 10, 255}
GUI.colors.olive = {100, 100, 0, 255}

GUI.fonts.version = {fonts.sans, 13, "i"}
GUI.Draw_Version = function ()
  if not GUI.version then return 0 end
  local str = "Script by amagalma  -  using modified Lokasenna_GUI " .. GUI.version
  GUI.font("version")
  GUI.color("txt")
  local str_w, str_h = gfx.measurestr(str)
  gfx.x = (gfx.w - str_w)/2
  gfx.y = gfx.h - str_h - 2
  gfx.drawstr(str)
end

function Exit()
  if not Maximized then
    reaper.SetExtState("amagalma_Chunk Viewer-Editor", "Settings",
                    string.format("%i %i %i %i %i", gfx.dock(-1, 0, 0, 0, 0)), 1)
  else
    reaper.SetExtState("amagalma_Chunk Viewer-Editor", "Settings",
      string.format("%i %i %i %i %i", prev_dock, prev_x, prev_y, prev_w, prev_h), 1)
  end
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
  local find_hwnd = reaper.JS_Window_Find( "Chunk Viewer / Editor Find", true )
  if find_hwnd then
    reaper.JS_WindowMessage_Post(find_hwnd, "WM_KEYDOWN", 0x1B, 0,0,0)
    reaper.JS_WindowMessage_Post(find_hwnd, "WM_KEYUP", 0x1B, 0,0,0)
  end
end

reaper.atexit(Exit)

-- Run -------------------------------------------------------------


GUI.Init()
script_hwnd = reaper.JS_Window_Find( GUI.name, true )
reaper.JS_Window_AttachTopmostPin( script_hwnd )
GUI.Main()

-- @description Chunk Viewer/Editor
-- @author amagalma
-- @version 1.55
-- @changelog
--   - add: navigate to start of previous/next word with Ctrl + left/right arrows
--   - fix: crash when using arrow keys with an empty editor
-- @provides amagalma_Chunk ViewerEditor find.lua
-- @link https://forum.cockos.com/showthread.php?t=194369
-- @screenshot https://i.ibb.co/DfZFx9z/amagalma-Chunk-Viewer-Editor.gif
-- @donation https://www.paypal.me/amagalma
-- @about
--   Displays/edits the state chunk of the selected track/item/envelope. Intended for use by developers/scripters.
--
--   - Dual mode with two editors
--   - Enable Dual mode inside the script (defaults to true)
--   - Chunks are automatically indented
--   - Size of indentation set inside the script in User Settings area (default: 2 spaces)
--   - Ctrl + mousewheel changes font size (Click question mark for all shortcuts)
--   - When it loads, the last clicked context (track/item/envelope) is automatically set
--   - Automatic line numbering
--   - Fully re-sizable
--   - Remembers last window position and window/font size
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
local dual_chunk_editor = true -- enable 2 chunk editors (true or false)
--------------------------------------------------


local version = "1.55"


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

local last_chunk_obj
local LastEditorFocus = 1

local function IfSameObjThenStoreWindow(obj)
  if obj == last_chunk_obj then
  local editor = LastEditorFocus == 1 and "TextEditor" or "TextEditor2"
    return GUI.elms[editor].caret, GUI.elms[editor].wnd_pos
  end
end

local function RestoreWindow(caret, wnd_pos)
  local editor = LastEditorFocus == 1 and "TextEditor" or "TextEditor2"
  GUI.settooltip( "Got chunk" )
  if caret and wnd_pos then
    GUI.elms[editor].wnd_pos = wnd_pos
    GUI.elms[editor].caret = caret
  end
  GUI.elms[editor].focus = true -- does not always work
end

local function GetChunk()
  local sorry = "Sorry! Could not get chunk..."
  local editor = LastEditorFocus == 1 and "TextEditor" or "TextEditor2"
  if GUI.Val("ChooseObj") == 1 then
    local track = reaper.GetSelectedTrack2(0,0,true)
    if track then
      local caret, wnd_pos = IfSameObjThenStoreWindow(track)
      last_chunk_obj = track
      local _, chunk = reaper.GetTrackStateChunk(track, "", false )
      GUI.Val(editor, IndentChunk(chunk) )
      RestoreWindow(caret, wnd_pos)
    else
      reaper.MB( "No track is selected!", sorry, 0 )
    end
  elseif GUI.Val("ChooseObj") == 2 then
    local item = reaper.GetSelectedMediaItem(0,0)
    if item then
      local caret, wnd_pos = IfSameObjThenStoreWindow(item)
      last_chunk_obj = item
      local _, chunk = reaper.GetItemStateChunk(item, "", false )
      GUI.Val(editor, IndentChunk(chunk) )
      RestoreWindow(caret, wnd_pos)
    else
      reaper.MB( "No item is selected!", sorry, 0 )
    end
  elseif GUI.Val("ChooseObj") == 3 then
    local env = reaper.GetSelectedEnvelope(0)
    if env then
      local caret, wnd_pos = IfSameObjThenStoreWindow(env)
      last_chunk_obj = env
      local _, chunk = reaper.GetEnvelopeStateChunk( env, "", false )
      GUI.Val(editor, IndentChunk(chunk) )
      RestoreWindow(caret, wnd_pos)
    else
      reaper.MB( "No envelope is selected!", sorry, 0 )
    end
  end
end

local function SetChunk()
  local ok
  local editor = LastEditorFocus == 1 and "TextEditor" or "TextEditor2"
  if GUI.Val(editor) == "" then
    reaper.MB( "Empty chunk...", "Can not set chunk!", 0 )
    return
  end
  local success
  if GUI.Val("ChooseObj") == 1 then
    local track = reaper.GetSelectedTrack(0,0)
    if track then
      success = reaper.SetTrackStateChunk( track, GUI.Val(editor), false )
    end
  elseif GUI.Val("ChooseObj") == 2 then
    local item = reaper.GetSelectedMediaItem(0,0)
    if item then
      success = reaper.SetItemStateChunk( item, GUI.Val(editor), false )
    end
  elseif GUI.Val("ChooseObj") == 3 then
    local env = reaper.GetSelectedEnvelope(0)
    if env then
      success = reaper.SetEnvelopeStateChunk( env, GUI.Val(editor), false )
    end
  end
  local A = GUI.Val("ChooseObj")
  local what = A == 1 and "Track" or (A == 2 and "Item" or "Envelope" )
  if success then
    local where = LastEditorFocus == 1 and "left editor)" or "right editor)"
    GUI.settooltip( "Set chunk (from " .. where )
    local state = A == 1 and 7 or (A == 2 and 4 or 1 )
    reaper.Undo_OnStateChangeEx2( 0, "Set " .. what .. " Chunk", state, -1 )
  else
    reaper.MB( "Probably, the chunk is not valid...", "Could not set " .. what .. " chunk!", 0 )
  end
end

local function Checking()
  if dual_chunk_editor then
    LastEditorFocus =
        GUI.elms.TextEditor2.focus and 2 or
       (GUI.elms.TextEditor.focus and 1 or LastEditorFocus)
  end
  if gfx.w ~= GUI.w or gfx.h ~= GUI.h then
    GUI.w, GUI.h = gfx.w, gfx.h
    GUI.elms.SetChunk_.x = GUI.w - 344
    GUI.elms.SetChunk_:init()
    GUI.elms.SetChunk_:redraw()
    GUI.elms.GetChunk_.x = GUI.w - 241
    GUI.elms.GetChunk_:init()
    GUI.elms.GetChunk_:redraw()
    if dual_chunk_editor then
      GUI.elms.TextEditor.w = GUI.w/2 - 4
      
      GUI.elms.TextEditor2.x = GUI.w/2 + 2
      GUI.elms.TextEditor2.w = GUI.w/2 - 4
      GUI.elms.TextEditor2.h = GUI.h - 46
      GUI.elms.TextEditor2:init()
      GUI.elms.TextEditor2:redraw()
      GUI.elms.TextEditor2:wnd_recalc()
    else
      GUI.elms.TextEditor.w = GUI.w - 4
    end
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
    if cur_digits ~= GUI.elms.TextEditor.digits then
      GUI.elms.TextEditor.digits = cur_digits
      GUI.elms.TextEditor.textpad = gfx.measurestr(string.rep("0", cur_digits))
      GUI.elms.TextEditor.pad = 6 + GUI.elms.TextEditor.textpad
      GUI.elms.TextEditor:init()
      GUI.elms.TextEditor:drawtext()
    end
  end
  if GUI.elms.TextEditor2 then
    local cur_digits = #(tostring(#GUI.elms.TextEditor2.retval))
    cur_digits = cur_digits > 2 and cur_digits or 2
    if cur_digits ~= GUI.elms.TextEditor2.digits then
      GUI.elms.TextEditor2.digits = cur_digits
      GUI.elms.TextEditor2.textpad = gfx.measurestr(string.rep("0", cur_digits))
      GUI.elms.TextEditor2.pad = 6 + GUI.elms.TextEditor2.textpad
      GUI.elms.TextEditor2:init()
      GUI.elms.TextEditor2:drawtext()
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
  self.digits = digits > 2 and digits or 2
  GUI.font(self.font_b)
  self.textpad = gfx.measurestr(string.rep("0", digits))
  self.pad = 6 + self.textpad
end

function GUI.TextEditor:getcaret(x, y)
  local tmp = {}
  tmp.x = math.floor(((x - self.textpad - self.x) / self.w ) * self.wnd_w) + self.wnd_pos.x
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


function GUI.TextEditor:getwndlength()
  return #self.retval
end


function GUI.TextEditor:onwheel(inc)
  -- Ctrl -- Change font size
  if GUI.mouse.cap & 4 == 4 then
    GUI.fonts.monospace[2] = GUI.fonts.monospace[2] + (inc > 0 and 1 or -1)
    if dual_chunk_editor then
      GUI.elms.TextEditor2:init()
      GUI.elms.TextEditor2:redraw()
      GUI.elms.TextEditor2:wnd_recalc()
    end
    GUI.elms.TextEditor:init()
    GUI.elms.TextEditor:redraw()
    GUI.elms.TextEditor:wnd_recalc()
  -- Shift -- Horizontal scroll
  elseif GUI.mouse.cap & 8 == 8 then
    local len = self:getmaxlength()
    if len <= self.wnd_w then return end
    -- Scroll right/left
    local dir = inc > 0 and 3 or -3
    self.wnd_pos.x = GUI.clamp(0, self.wnd_pos.x + dir, len - self.wnd_w + 4)
  -- Vertical scroll
  else
    local len = self:getwndlength()
    if len <= self.wnd_h then return end
    -- Scroll up/down
    local dir = inc > 0 and -3 or 3
    self.wnd_pos.y = GUI.clamp(1, self.wnd_pos.y + dir, len - self.wnd_h + 1)
  end
  self:redraw()
end


GUI.TextEditor.keys[GUI.chars.F3] = function (self) -- F3 Find next
  local str, MatchCase = GetString()
  if #self.retval == 0 or str == "" or not str then return end
  local name = (#str < 16 and str or str:sub(1, 15) .. "..") .. "'"
  str = MatchCase and str or str:upper()
  local line, character = 1, 1
  if self.sel_s and self.sel_e and self.sel_s.y == self.sel_e.y and self.sel_e.y ==
     self.caret.y and self.caret.x >= self.sel_s.x and self.caret.x <= self.sel_e.x
  then
    self.caret.x = self.sel_e.x
  end
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
        -- Make selection
        self.sel_s = {x = pos1 - #str, y = i}
        self.sel_e = {x = pos1, y = i}
        self:drawselection()
        return true
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
  if self.sel_s and self.sel_e and self.sel_s.y == self.sel_e.y and self.sel_e.y ==
     self.caret.y and self.caret.x >= self.sel_s.x and self.caret.x <= self.sel_e.x
  then
    self.caret.x = self.sel_s.x
  end
  if self.caret.x == 0 and self.caret.y - 1 > 0 then
    line, character = self.caret.y - 1, #self.retval[self.caret.y - 1]
  else
    line, character = self.caret.y, self.caret.x
  end
  if line >= 1 then
    for i = line, 1, -1 do
      local txt = i ~= line and self.retval[i] or self.retval[line]:sub(1, character)
      txt = (MatchCase and txt or txt:upper()):reverse()
      local pos1, pos2 = txt:find(esc(str))
      if pos1 and pos2 then
        pos1 = (i ~= line and #txt-pos2 or character-pos2 - 
                              (self.caret.x == #self.retval[self.caret.y] and 1 or 0))
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
        -- Make selection
        self.sel_s = {x = pos1, y = i}
        self.sel_e = {x = pos1 + #str, y = i}
        self:drawselection()
        return true
      end
    end
  end
  local focus = reaper.JS_Window_GetFocus()
  reaper.MB( "No occurences before current position.", "Can't find '" .. name, 0 )
  reaper.JS_Window_SetFocus( focus )
  return
end


GUI.TextEditor.keys[GUI.chars.LEFT] = function(self)
  if #self.retval ~= 0 then
    if GUI.mouse.cap == 4 or GUI.mouse.cap == 12 then -- CTRL (CTRL|SHIFT)
      local line = self.retval[self.caret.y] or ""
      local cnt = 0
      local prev_char = " "
      for i = self.caret.x, 1, -1 do
        cnt = cnt + 1
        local char = self.retval[self.caret.y]:sub(i, i)
        if char == " " and prev_char ~= " " then
          self.caret.x = self.caret.x - cnt + 1
          break
        end
        prev_char = char
      end
    else
      if self.caret.x < 1 and self.caret.y > 1 then
        self.caret.y = self.caret.y - 1
        self.caret.x = self:carettoend()
      else
        self.caret.x = math.max(self.caret.x - 1, 0)
      end
    end
  end
end


GUI.TextEditor.keys[GUI.chars.RIGHT] = function(self)
  if #self.retval ~= 0 then
    if GUI.mouse.cap == 4 or GUI.mouse.cap == 12 then -- CTRL (CTRL|SHIFT)
      local line = self.retval[self.caret.y] or ""
      local cnt = 0
      local prev_char
      for i = self.caret.x + 1, #line do
        cnt = cnt + 1
        local char = self.retval[self.caret.y]:sub(i, i)
        if char ~= " " and prev_char == " " then
          self.caret.x = self.caret.x + cnt -1
          break
        end
        prev_char = char
      end
    else
      if self.caret.x == self:carettoend() and self.caret.y < self:getwndlength() then
        self.caret.y = self.caret.y + 1
        self.caret.x = 0
      else
        self.caret.x = math.min(self.caret.x + 1, self:carettoend() )
      end
    end
  end
end


GUI.TextEditor.keys[GUI.chars.UP] = function(self)
  if #self.retval ~= 0 then
    if self.caret.y == 1 then
      self.caret.x = 0
    else
      self.caret.y = math.max(1, self.caret.y - 1)
      self.caret.x = math.min(self.caret.x, self:carettoend() )
    end
  end
end


GUI.TextEditor.keys[GUI.chars.DOWN] = function(self)
  if #self.retval ~= 0 then
    if self.caret.y == self:getwndlength() then
      self.caret.x = string.len(self.retval[#self.retval])
    else
      self.caret.y = math.min(self.caret.y + 1, #self.retval)
      self.caret.x = math.min(self.caret.x, self:carettoend() )
    end
  end
end


local Maximized = false
local prev_dock, prev_x, prev_y, prev_w, prev_h
local win_style
local script_hwnd

local function Fullscreen()
  Maximized = not Maximized
  GUI.elms.Fullscreen.col_fill = Maximized and "maroon" or "elm_bg"
  GUI.elms.Fullscreen:init()
  GUI.elms.Fullscreen:redraw()
  if gfx.dock(-1) ~= 0 then
    GUI.dock = 0
    gfx.quit()
    gfx.init(GUI.name, GUI.w, GUI.h, GUI.dock, GUI.x, GUI.y)
    script_hwnd = reaper.JS_Window_Find( GUI.name, true )
    reaper.JS_Window_AttachTopmostPin( script_hwnd )
    win_style = false
  end
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

local msg = [[=========  amagalma Chunk Viewer / Editor help  =========

Click on Get/Set Chunk to get/set the chunk of the first selected object
specified in the Menubox.
  
Click on, or mousewheel over, the Menubox to change object type.
  
Fullscreen toggles between fullscreen or last size. (Windows only)
  
When the Text-Editor has focus the following keyboard shortcuts apply :

Ctrl + A  : Select all
Ctrl + C  : Copy
Ctrl + X  : Cut
Ctrl + V  : Paste
Ctrl + Z  : Undo
Ctrl + Y  : Redo
Ctrl + F  : Find (opens new window)
Ctrl + ←  : Go to start of previous word (non-space)
Ctrl + →  : Go to start of next word (non-space)
F2        : Go to previous search occurence
F3        : Go to next search occurence
Home      : Go to chunk start
End       : Go to chunk end
Page-Up   : self-explanatory
Page-Down : self-explanatory
Insert    : Toggles between overwrite text and normal text insertion
Ctrl + Mousewheel to change font size

Number of spaces used for identation are set inside the script.
(current identation is set to ]] .. number_of_spaces .. [[ spaces)

** Dual mode with two editors is set inside the script **

https://www.paypal.me/amagalma
=========================================================

]]
local function Help()
  reaper.ClearConsole()
  reaper.ShowConsoleMsg(msg)
end

-- Create GUI ------------------------------------------------------

GUI.name = "Chunk Viewer / Editor   -   v" .. version
local Settings = reaper.GetExtState("amagalma_Chunk Viewer-Editor", "Settings")
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, dual_chunk_editor and 1200 or 800, 700
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
    w = (dual_chunk_editor and GUI.w/2 or GUI.w ) - 4,
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

if dual_chunk_editor then
  GUI.New("TextEditor2", "TextEditor", {
    z = 1,
    x = GUI.w/2 + 2,
    y = 30,
    w = GUI.w/2 - 4,
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
end

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

GUI.New("Help", "Button", {
    z = 2,
    x = 115,
    y = 2,
    w = 18,
    h = 25,
    caption = "?",
    font = 2,
    col_txt = "txt",
    col_fill = "elm_bg",
    func = Help
})

-- Modified Functions ----------------------------------------------

function GUI.TextEditor:drawtext()
  GUI.font(self.font_b)
  local digits = #tostring(#self.retval)
  self.digits = digits > 2 and digits or 2
  self.textpad = gfx.measurestr(string.rep("0", digits))
  self.pad = 6 + self.textpad
  local tmp = {}
  local numbers = {}
  local n = 0
  for i = self.wnd_pos.y, math.min(self:wnd_bottom() - 1, #self.retval) do
    n = n + 1
    local str = tostring(self.retval[i]) or ""
    tmp[n] = string.sub(str, self.wnd_pos.x + 1, self:wnd_right() - 1 - digits)
    numbers[n] = string.format("%" .. digits .. "i", i)
  end
  GUI.color("gray")
  gfx.x, gfx.y = self.x + self.pad - self.textpad, self.y + self.pad
  gfx.drawstr(table.concat(numbers, "\n"))
  GUI.color(self.color)
  gfx.x, gfx.y = self.x + self.pad, self.y + self.pad
  gfx.drawstr( table.concat(tmp, "\n") )
end


local fonts = GUI.get_OS_fonts()
GUI.fonts.monospace = {fonts.mono, tonumber(reaper.GetExtState("amagalma_Chunk Viewer-Editor", "FontSize")) or 16}
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
  reaper.SetExtState("amagalma_Chunk Viewer-Editor", "FontSize", GUI.fonts.monospace[2], true)
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

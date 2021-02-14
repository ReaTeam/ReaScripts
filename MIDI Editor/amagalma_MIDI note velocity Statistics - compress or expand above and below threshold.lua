-- @description MIDI note velocity Statistics - compress or expand above and below threshold
-- @author amagalma
-- @version 1.01
-- @changelog
--   - If JS_ReaScriptAPI is present then a topmost pin is attached to the script's window
--   - Registered script in Midi Editor and Main
-- @provides [main=main,midi_editor] .
-- @link https://forum.cockos.com/showthread.php?t=249525
-- @screenshot https://i.ibb.co/NyH3yQ0/Velocity-statistics.jpg
-- @donation https://www.paypal.me/amagalma
-- @about
--   Returns the average, median and statistical mode of all note velocities in current take (open ME window or selected item in Arrange). You can choose one of them to set as a threshold (or set your own value) and compress/expand differently the notes that their velocities are above the threshold, and those that are below.
--   Values 1 to 100 bring note velocities towards the threshold (compress) and values -1 to -100 move them away (expand).
--
--   - Requires Lokasenna GUI v2
--   - If JS_ReaScriptAPI is present then a topmost pin is attached to the script's window


local version = "1.01"

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
loadfile(lib_path .. "Core.lua")()
GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Label.lua")()
GUI.req("Classes/Class - Options.lua")()
if missing_lib then
  reaper.MB("Please re-install 'Lokasenna's GUI library v2 for Lua'", "Missing library!", 0)
  return reaper.defer(function() end)
end

local JS_API = reaper.APIExists( "JS_Window_Find", "title" )
local script_hwnd


local _, _, section, cmdID = reaper.get_action_context()
reaper.SetToggleCommandState( section, cmdID, 1 ) -- Set ON
reaper.RefreshToolbar2( section, cmdID )


-----------------------------------------------------------------------------
local Vels, Take, Threshold, Stats = {}, false, -1, {}
local VelsAbove, VelsBelow = {}, {}
local AboveVal, BelowVal = 0, 0
local floor = math.floor

GUI.exit = function()
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
  if Take and AboveVal ~= 0 or BelowVal ~= 0 then
    reaper.Undo_OnStateChange_Item( 0, "Changed MIDI note velocities",
    reaper.GetMediaItemTake_Item( Take ) )
  end
end

local function GetTake()
  local midi_editor = reaper.MIDIEditor_GetActive()
  local take = reaper.MIDIEditor_GetTake( midi_editor )
  if not take then
    local item = reaper.GetSelectedMediaItem( 0 , 0 )
    if not item then return end
    take = reaper.GetActiveTake( item )
    if not take or not reaper.TakeIsMIDI( take ) then return end
  end
  return take
end

local function HasMIDIChanged()
  if not Vels or not Take then return end
  local _, notecnt = reaper.MIDI_CountEvts( Take )
  if notecnt ~= Stats.cnt then return true end
  for n = 0, notecnt-1 do
    local _, _, _, _, _, _, _, vel = reaper.MIDI_GetNote( Take, n )
    if Vels[n+1] ~= vel then
      return true
    end
  end
  return false
end

local function Statistics()
  if not Vels then Vels = {} end
  if not Take then return {} end
  local _, notecnt = reaper.MIDI_CountEvts( Take )
  if notecnt == 0 then return {} end
  local m = {}
  local h = {}
  local avg = -1
  local mode, mode_cnt = -1, 0
  local max, min = 0, 127
  for n = 0, notecnt-1 do
    local _, _, _, _, _, _, _, vel = reaper.MIDI_GetNote( Take, n )
    if vel < min then min = vel end
    if vel > max then max = vel end
    Vels[n+1] = vel
    m[n+1] = vel
    avg = avg + vel
    if not h[vel] then h[vel] = 0 end
    h[vel] = h[vel] + 1
    if h[vel] > mode_cnt then
      mode_cnt = h[vel]
      mode = vel
    end
  end
  avg = floor(avg/notecnt + 0.5)
  table.sort(m, function(a,b) return a<b end)
  local median = notecnt/2
  if notecnt % 2 == 0 then -- even
    median = floor((m[median] + m[median+1])/2 + 0.5)
  else
    median = m[math.ceil(median)]
  end
  local stats = {
    cnt = notecnt,
    avg = avg,
    med = median,
    mod = mode,
    min = min,
    max = max
  }
  return stats
end


Take = GetTake()
if Take then
  Stats = Statistics()
  Threshold = Stats.avg and Stats.avg
end

function GUI.Label:new(name, z, x, y, caption, shadow, font, color, bg)
  local label = (not x and type(z) == "table") and z or {}
  label.name = name
  label.type = "Label"
  label.z = label.z or z
  label.x = label.x or x
  label.y = label.y or y
  label.w, label.h = 0, 0
  if type(label.caption) == "number" then
    label.caption = string.format("%i", label.caption)
  end
  label.caption = label.caption   or caption
  label.shadow =  label.shadow    or shadow   or false
  label.font =    label.font      or font     or 2
  label.color =   label.color     or color    or "txt"
  label.bg =      label.bg        or bg       or "wnd_bg"
  GUI.redraw_z[label.z] = true
  setmetatable(label, self)
  self.__index = self
  return label
end

local function force_size()
    gfx.quit()
    gfx.init(GUI.name, GUI.w, GUI.h, GUI.dock, GUI.x, GUI.y)
    GUI.cur_w, GUI.cur_h = GUI.w, GUI.h
end
GUI.onresize = force_size

local Chk = {"ChkAvg","ChkMedian","ChkMode","ChkCustom"}
function GUI.Checklist:onmouseup()
  if self.name == "ChkCustom" then
    local ok, val = reaper.GetUserInputs("Enter Velocity Threshold", 1, "Enter (1-127) :", self.Val)
    if ok then
      val = tonumber(val)
      if val and val >= 1 and val <= 127 then
        self.Val = val
        Threshold = val
        self.optarray = {val}
      end
    else
      return
    end
  end
  local mouseopt = self:getmouseopt()
  if not mouseopt then return end
  self.optsel[mouseopt] = not self.optsel[mouseopt]
  self.focus = false
  self:redraw()
  for i = 1, 4 do
    if GUI.elms[Chk[i]].name ~= self.name then
      GUI.Val(Chk[i],false)
    else
      Threshold = self.Val
    end
  end
end

local function Change_Above()
  if not Take then return end
  reaper.MIDI_DisableSort( Take )
  if #VelsAbove == 0 then -- Memoize
    local abv = 0
    for n = 1, Stats.cnt do
      if Vels[n] > Threshold then
        abv = abv + 1
        VelsAbove[abv] = {n-1, Vels[n]}
        local vel
        if AboveVal > 0 then
          vel = floor(Vels[n] - (Vels[n] - Threshold)*AboveVal*0.01 + 0.5)
        elseif AboveVal == 0 then
          vel = Vels[n]
        else -- if AboveVal < 0
          vel = floor(Vels[n] - (127 - Vels[n])*AboveVal*0.01 + 0.5)
        end
        reaper.MIDI_SetNote( Take, n-1, nil, nil, nil, nil, nil, nil, vel, true )
      end
    end
  else
    for n = 1, #VelsAbove do
      local vel
      if AboveVal > 0 then
        vel = floor(VelsAbove[n][2] - (VelsAbove[n][2] - Threshold)*AboveVal*0.01 + 0.5)
      elseif AboveVal == 0 then
        vel = VelsAbove[n][2]
      else -- if AboveVal < 0
        vel = floor(VelsAbove[n][2] - (127 - VelsAbove[n][2])*AboveVal*0.01 + 0.5)
      end
      reaper.MIDI_SetNote( Take, VelsAbove[n][1], nil, nil, nil, nil, nil, nil, vel, true )
    end
  end
  reaper.MIDI_Sort( Take )
end

local function Change_Below()
  if not Take then return end
  reaper.MIDI_DisableSort( Take )
  if #VelsBelow == 0 then -- Memoize
    local blw = 0
    for n = 1, Stats.cnt do
      if Vels[n] < Threshold then
        blw = blw + 1
        VelsBelow[blw] = {n-1, Vels[n]}
        local vel
        if BelowVal > 0 then
          vel = floor(Vels[n] + (Threshold - Vels[n])*BelowVal*0.01 + 0.5)
        elseif BelowVal == 0 then
          vel = Vels[n]
        else -- if BelowVal < 0
          vel = floor(Vels[n] + Vels[n]*BelowVal*0.01 + 0.5)
        end
        if vel == 0 then vel = 1 end
        reaper.MIDI_SetNote( Take, n-1, nil, nil, nil, nil, nil, nil, vel, true )
      end
    end
  else
    for n = 1, #VelsBelow do
      local vel
      if BelowVal > 0 then
        vel = floor(VelsBelow[n][2] + (Threshold - VelsBelow[n][2])*BelowVal*0.01 + 0.5)
      elseif BelowVal == 0 then
        vel = VelsBelow[n][2]
      else -- if BelowVal < 0
        vel = floor(VelsBelow[n][2] + VelsBelow[n][2]*BelowVal*0.01 + 0.5)
      end
      if vel == 0 then vel = 1 end
      reaper.MIDI_SetNote( Take, VelsBelow[n][1], nil, nil, nil, nil, nil, nil, vel, true )
    end
  end
  reaper.MIDI_Sort( Take )
end

function GUI.Slider:drawslidervalue(x, y, sldr) -- better alignment
  local output = self.handles[sldr].retval
  local num = tonumber(output)
  local adj = 0
  if num >= 0 then
    if num < 10 then
      adj = -2
    elseif num == 100 then
      adj = -10
    else
      adj = -6
    end
  else
    if num > -10 then
      adj = -6
    elseif num == -100 then
      adj = -12
    else
      adj = -9
    end
  end
  gfx.x, gfx.y = x + adj, y
  GUI.text_bg(output, self.bg, self.align_values + 256)
  gfx.drawstr(output, self.align_values + 256, gfx.x, gfx.y)
end

-----------------------------------------------------------------------------

GUI.name = "MIDI velocity Statistics - v" .. version
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 250, 437
GUI.anchor, GUI.corner = "screen", "C"
GUI.colors.txt = {225,225,225,255}
GUI.colors.lime[4] = 210
local no_data = "(no data)"

GUI.New("Statistics", "Label", {
    z = 1,
    x = 75,
    y = 10,
    caption = "Statistics:",
    font = 1,
    color = "txt",
    bg = "wnd_bg",
    shadow = false
})

GUI.New("Notecountlbl", "Label", {
    z = 1,
    x = 25,
    y = 50,
    caption = "Note count :",
    font = 2,
    color = "txt",
    bg = "wnd_bg",
    shadow = false
})

GUI.New("Notecount", "Label", {
    z = 1,
    x = 175,
    y = 50,
    caption = Stats.cnt and Stats.cnt or no_data,
    font = 2,
    color = "lime",
    bg = "wnd_bg",
    shadow = false
})

GUI.New("Avg_lbl", "Label", {
    z = 1,
    x = 25,
    y = 80,
    caption = "Average velocity :",
    font = 2,
    color = "txt",
    bg = "wnd_bg",
    shadow = false
})

GUI.New("Avg", "Label", {
    z = 1,
    x = 175,
    y = 80,
    caption = Stats.avg and Stats.avg or no_data,
    font = 2,
    color = "lime",
    bg = "wnd_bg",
    shadow = false
})

GUI.New("Median_lbl", "Label", {
    z = 1,
    x = 25,
    y = 110,
    caption = "Median velocity :",
    font = 2,
    color = "txt",
    bg = "wnd_bg",
    shadow = false
})

GUI.New("Median", "Label", {
    z = 1,
    x = 175,
    y = 110,
    caption = Stats.med and Stats.med or no_data,
    font = 2,
    color = "lime",
    bg = "wnd_bg",
    shadow = false
})

GUI.New("Mode_lbl", "Label", {
    z = 1,
    x = 25,
    y = 140,
    caption = "Mode velocity :",
    font = 2,
    color = "txt",
    bg = "wnd_bg",
    shadow = false
})

GUI.New("Mode", "Label", {
    z = 1,
    x = 175,
    y = 140,
    caption = Stats.mod and Stats.mod or no_data,
    font = 2,
    color = "lime",
    bg = "wnd_bg",
    shadow = false
})

GUI.New("MinMax_lbl", "Label", {
    z = 1,
    x = 25,
    y = 170,
    caption = "Min  -  Max :",
    font = 2,
    color = "txt",
    bg = "wnd_bg",
    shadow = false
})

GUI.New("MinMax", "Label", {
    z = 1,
    x = 148,
    y = 170,
    caption = Stats.min and string.format("%i  -  %i",Stats.min,Stats.max) or no_data,
    font = 2,
    color = "lime",
    bg = "wnd_bg",
    shadow = false
})

GUI.New("Threshold_lbl", "Label", {
    z = 1,
    x = 38,
    y = 200,
    caption = [[
Move note velocities towards to
or away from chosen threshold :]],
    font = 3,
    color = "txt",
    bg = "wnd_bg",
    shadow = false
})

local chk_y = 255
GUI.New("ChkAvg", "Checklist", {
    z = 1,
    x = 25,
    y = chk_y,
    w = 35,
    h = 35,
    caption = "",
    optarray = {"Average"},
    dir = "h",
    pad = 5,
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = true,
    swap = nil,
    opt_size = 25,
    Val = Stats.avg and Stats.avg or 0
})

GUI.New("ChkMedian", "Checklist", {
    z = 1,
    x = 80,
    y = chk_y,
    w = 35,
    h = 35,
    caption = "",
    optarray = {"Median"},
    dir = "h",
    pad = 5,
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = true,
    swap = nil,
    opt_size = 25,
    Val = Stats.med and Stats.med or 0
})

GUI.New("ChkMode", "Checklist", {
    z = 1,
    x = 135,
    y = chk_y,
    w = 35,
    h = 35,
    caption = "",
    optarray = {"Mode"},
    dir = "h",
    pad = 5,
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = true,
    swap = nil,
    opt_size = 25,
    Val = Stats.mod and Stats.mod or 0
})

GUI.New("ChkCustom", "Checklist", {
    z = 1,
    x = 190,
    y = chk_y,
    w = 35,
    h = 35,
    caption = "",
    optarray = {"Custom"},
    dir = "h",
    pad = 5,
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = false,
    shadow = true,
    swap = nil,
    opt_size = 25,
    Val = 100
})


GUI.New("Above", "Slider", {
    z = 1,
    x = 25,
    y = 325,
    w = 200,
    caption = "Notes with vel ABOVE threshold (%)",
    min = -100,
    max = 100,
    defaults = {100},
    inc = 1,
    dir = "h",
    font_a = 3,
    font_b = 4,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = 0,
    cap_y = 0
})

GUI.New("Below", "Slider", {
    z = 1,
    x = 25,
    y = 385,
    w = 200,
    caption = "Notes with vel BELOW threshold (%)",
    min = -100,
    max = 100,
    defaults = {100},
    inc = 1,
    dir = "h",
    font_a = 3,
    font_b = 4,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = 0,
    cap_y = 0
})

-----------------------------------------------------------------------------

local function ResetValues()
  local a = {"Notecount","Avg","Median","Mode","MinMax"}
  for i = 1, 5 do
    GUI.Val(a[i], no_data)
    GUI.elms[a[i]]:init()
    GUI.elms[a[i]]:redraw()
  end
  a = {"ChkAvg","ChkMedian","ChkMode"}
  for i = 1, 3 do
    GUI.elms[a[i]].Val = 0
  end
end

local function ShowValues()
  local a = {"Notecount","Avg","Median","Mode"}
  local s = {"cnt","avg","med","mod"}
  for i = 1, 4 do
    GUI.elms[a[i]].caption = string.format("%i", Stats[s[i]])
    GUI.elms[a[i]]:init()
    GUI.elms[a[i]]:redraw()
  end
  GUI.elms.MinMax.caption = string.format("%i  -  %i",Stats.min,Stats.max)
  GUI.elms.MinMax:init()
  a = {"ChkAvg","ChkMedian","ChkMode"}
  for i = 1, 3 do
    GUI.elms[a[i]].Val = Stats[s[i+1]]
  end
end


local prev_checktime = reaper.time_precise()
GUI.freq = 0
GUI.func = function()
  if GUI.last_time >= prev_checktime + 0.25 then
    prev_checktime = GUI.last_time
    local cur_take = GetTake()
    if cur_take ~= Take then
      if AboveVal ~= 0 or BelowVal ~= 0 then
        reaper.Undo_OnStateChange_Item( 0, "Changed MIDI note velocities",
        reaper.GetMediaItemTake_Item( Take ) )
      end
      Vels = {}
      VelsAbove, VelsBelow = {}, {}
      Take = cur_take
      if Take then
        Stats = Statistics()
        if Stats.cnt then
          ShowValues()
          for i = 1, 4 do
            if GUI.Val(Chk[i]) then
              Threshold = GUI.elms[Chk[i]].Val
              break
            end
          end
        else
          ResetValues()
          Threshold = -1
        end
      else
        Stats = {}
        ResetValues()
      end
    elseif HasMIDIChanged() then
      Stats = Statistics()
      if Stats.cnt then
        ShowValues()
        for i = 1, 4 do
          if GUI.Val(Chk[i]) then
            Threshold = GUI.elms[Chk[i]].Val
            break
          end
        end
      else
        ResetValues()
        Threshold = -1
      end
    end
  end

  if GUI.Val("Below") ~= BelowVal then
    BelowVal = GUI.Val("Below")
    Change_Below()
  end
  if GUI.Val("Above") ~= AboveVal then
    AboveVal = GUI.Val("Above")
    Change_Above()
  end
end

local fonts = GUI.get_OS_fonts()
GUI.fonts.version = {fonts.sans, 13, "i"}
GUI.colors.gray = {225, 225, 225, 180}
GUI.Draw_Version = function ()
  if not GUI.version then return 0 end
  local str = "Script by amagalma  -  using Lokasenna_GUI " .. GUI.version
  GUI.font("version")
  GUI.color("gray")
  local str_w, str_h = gfx.measurestr(str)
  gfx.x = gfx.w/2 - str_w/2
  gfx.y = gfx.h - str_h - 4
  gfx.drawstr(str)
end

GUI.Val("ChkAvg", true)
GUI.Init()
if JS_API then
  script_hwnd = reaper.JS_Window_Find( GUI.name, true )
  if script_hwnd then
    reaper.JS_Window_AttachTopmostPin( script_hwnd )
  end
end
GUI.Main()

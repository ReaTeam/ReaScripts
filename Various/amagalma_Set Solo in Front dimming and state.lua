-- @description Set Solo in Front dimming and state
-- @author amagalma
-- @version 1.01
-- @changelog Automatically enable Solo in Front when opening and disable it when closing script
-- @donation https://www.paypal.me/amagalma
-- @about Button and slider to set the value and state of Solo in Front.

local slider_size <const> = 260
local maxval <const> = -6
local minval <const> = -27
local font_size <const> = 14
local font_type <const> = "Arial"

-------------------------------------------------------------------------

local reaper, math = reaper, math

local solodimdb10 = reaper.SNM_GetIntConfigVar("solodimdb10",666);
if solodimdb10 == 666 then return end
solodimdb10 = solodimdb10 / 10

local solo_in_front = reaper.GetToggleCommandState(40745)

if solo_in_front == 0 then
  solo_in_front = 1
  reaper.Main_OnCommand(40745, 0)
end

local prev_state = solo_in_front
local btn_color, btn_txt
local btn_w = (slider_size*0.6)//1

local function SetButton()
  if solo_in_front == 1 then
    btn_color = 0x0F87FAFF
    btn_txt = "Solo in Front enabled"
  else
    btn_color = 0x4296FA66
    btn_txt = "Solo in Front disabled"
  end
end
SetButton()

local _, _, section, cmdID = reaper.get_action_context()
reaper.SetToggleCommandState( section, cmdID, 1 ) -- Set ON
reaper.RefreshToolbar2( section, cmdID )

reaper.atexit(function()
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
  if reaper.GetToggleCommandState( 40745 ) == 1 then
    reaper.Main_OnCommand(40745, 0)
  end
end)

local function SetSoloInFront( val )
  reaper.SNM_SetIntConfigVar( "solodimdb10", (val*10)//1 )
end


-------------------------------------------------------------------------

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.10.0.2'
local ctx = ImGui.CreateContext('Solo in front dimming')
local font = ImGui.CreateFont(font_type)
local window_flags <const> = ImGui.WindowFlags_NoDocking | ImGui.WindowFlags_NoCollapse |
                             ImGui.WindowFlags_AlwaysAutoResize | ImGui.WindowFlags_NoSavedSettings
local slider_flags <const> = ImGui.SliderFlags_Logarithmic

local x,y = reaper.GetMousePosition()
x = x - slider_size//2
ImGui.SetNextWindowPos(ctx, x > 0 and x or 0, y > 0 and y or 0 )

-------------------------------------------------------------------------

local v, retval = solodimdb10
local counter = 0

local function loop()
  ImGui.PushFont(ctx, font, font_size)
  local visible, open = ImGui.Begin(ctx, 'Dim Solo in Front', true, window_flags)
  if visible then
    counter = counter + 1
    if counter == 8 then
      solo_in_front = reaper.GetToggleCommandState(40745)
      counter = 0
    end
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), btn_color)
    if reaper.ImGui_Button(ctx, btn_txt, btn_w) then
      solo_in_front = math.abs(solo_in_front-1)
      reaper.Main_OnCommand(40745, 0)
      SetButton()
      prev_state = solo_in_front
    elseif prev_state ~= solo_in_front then
      SetButton()
      prev_state = solo_in_front
    end
    reaper.ImGui_PopStyleColor(ctx)

    ImGui.PushItemWidth(ctx, slider_size)
    retval, v = ImGui.SliderDouble(ctx, 'dB', v, minval, maxval, "%.1f", slider_flags)
    ImGui.PopItemWidth(ctx)
    if retval then
      SetSoloInFront( v )
    end
    if ImGui.IsItemHovered(ctx) then
      local wheel = ImGui.GetMouseWheel(ctx)
      if wheel ~= 0 then
        v = v + wheel * (ImGui.GetKeyMods(ctx) == ImGui.Mod_Ctrl and 0.1 or 0.5)
        v = math.max(minval, math.min(maxval, v))
        SetSoloInFront( v )
      end
    end
    ImGui.End(ctx)
    ImGui.PopFont(ctx)
  end
  if open then
    reaper.defer(loop)
  end
end

reaper.defer(loop)

-- @description Insert time signature changes Tool
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about Inserts a time signature change at the closest start of measure position to the edit cursor

local font_size = 16

-------------------------------------------------------------

local button_width = math.floor(font_size*2)
local radio_space = math.floor(font_size*1.25)
local Denominator, _ = tonumber(reaper.GetExtState( "amagalma_timesig_tool", "denom" )) or 4

reaper.atexit( function()
  reaper.SetExtState( "amagalma_timesig_tool", "denom", Denominator, false )
end)

-------------------------------------------------------------

local function AddSignature( num )
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  -- Bring cursor to closest measure start
  local cur_pos = reaper.GetCursorPosition()
  if reaper.GetToggleCommandState( 1157 ) == 0 then
    reaper.Main_OnCommand(40754, 0) -- Enable snap
    restore_snap = true
  end
  reaper.Main_OnCommand(40725, 0) -- Toggle measure grid
  local snaped_pos = reaper.SnapToGrid( 0, cur_pos )
  if restore_snap then
    reaper.Main_OnCommand(40753, 0) -- Disable snap
  end
  reaper.Main_OnCommand(40725, 0) -- Toggle measure grid

  -- Get info of time signature in effect
  local _, measures = reaper.TimeMap2_timeToBeats( 0, snaped_pos )
  local ptx_in_effect = reaper.FindTempoTimeSigMarker( 0, snaped_pos )

  -- Add num/denom measure
  reaper.SetTempoTimeSigMarker( 0, -1, -1, measures, 0, -1, num, Denominator, true )
  reaper.GetSetTempoTimeSigMarkerFlag( 0, ptx_in_effect+1, 1|2|16, true )

  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock( string.format("Change to %i/%i",num,Denominator), 1|4|8 )
  reaper.SetCursorContext( 1 )
end

-------------------------------------------------------------

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9.3.2'
local ctx = ImGui.CreateContext('amagalma_Insert time signature changes Tool')
local font = ImGui.CreateFont('sans-serif', font_size)
ImGui.Attach(ctx, font)

local window_flags = ImGui.WindowFlags_NoCollapse | ImGui.WindowFlags_AlwaysAutoResize

local function loop()
  ImGui.PushFont(ctx, font)
  local visible, open = ImGui.Begin(ctx, 'Time Signature Tool', true, window_flags)
  if visible then
    ImGui.Text(ctx, 'Insert Time Signature with Nominator :')
    if ImGui.Button(ctx, '2',button_width) then AddSignature(2) end ; ImGui.SameLine(ctx)
    if ImGui.Button(ctx, '3',button_width) then AddSignature(3) end ; ImGui.SameLine(ctx)
    if ImGui.Button(ctx, '4',button_width) then AddSignature(4) end ; ImGui.SameLine(ctx)
    if ImGui.Button(ctx, '5',button_width) then AddSignature(5) end ; ImGui.SameLine(ctx)
    if ImGui.Button(ctx, '6',button_width) then AddSignature(6) end ; ImGui.SameLine(ctx)
    if ImGui.Button(ctx, '7',button_width) then AddSignature(7) end ; ImGui.SameLine(ctx)
    if ImGui.Button(ctx, '8',button_width) then AddSignature(8) end
    if ImGui.Button(ctx, '9',button_width) then AddSignature(9) end ; ImGui.SameLine(ctx)
    if ImGui.Button(ctx, '10',button_width) then AddSignature(10) end ; ImGui.SameLine(ctx)
    if ImGui.Button(ctx, '11',button_width) then AddSignature(11) end ; ImGui.SameLine(ctx)
    if ImGui.Button(ctx, '12',button_width) then AddSignature(12) end ; ImGui.SameLine(ctx)
    if ImGui.Button(ctx, '13',button_width) then AddSignature(13) end ; ImGui.SameLine(ctx)
    if ImGui.Button(ctx, '14',button_width) then AddSignature(14) end ; ImGui.SameLine(ctx)
    if ImGui.Button(ctx, '15',button_width) then AddSignature(15) end

    ImGui.Spacing(ctx)

    ImGui.Text(ctx, 'Denominator :')
    _,Denominator = ImGui.RadioButtonEx(ctx, '1/16', Denominator, 16); ImGui.SameLine(ctx,nil,radio_space)
    _,Denominator = ImGui.RadioButtonEx(ctx, '1/8', Denominator, 8); ImGui.SameLine(ctx,nil,radio_space)
    _,Denominator = ImGui.RadioButtonEx(ctx, '1/4', Denominator, 4); ImGui.SameLine(ctx,nil,radio_space)
    _,Denominator = ImGui.RadioButtonEx(ctx, '1/2', Denominator, 2)

    ImGui.End(ctx)
  end
  ImGui.PopFont(ctx)

  if open then
    reaper.defer(loop)
  end
end

reaper.defer(loop)

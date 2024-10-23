-- @description FXD - Vertical FX list
-- @author Bryan Chi
-- @version 0.8.1
-- @changelog
--   - Fix master track panes height maximized when master track is hidden in TCP and shown in MCP
--   -Fix top alignment.
--   -Fix incorrect install path for functions and images
-- @provides
--   bryanchi_FXD - Vertical FX list/Images/starHollow.png
--   bryanchi_FXD - Vertical FX list/Images/star.png
--   bryanchi_FXD - Vertical FX list/Images/send.png
--   bryanchi_FXD - Vertical FX list/Images/receive.png
--   bryanchi_FXD - Vertical FX list/Images/show.png
--   bryanchi_FXD - Vertical FX list/Images/hide.png
--   bryanchi_FXD - Vertical FX list/Images/link.png
--   bryanchi_FXD - Vertical FX list/Functions/General Functions.Lua
--   bryanchi_FXD - Vertical FX list/Functions/FX Adder.Lua
-- @about
--   See forum post for details : 
--   https://forum.cockos.com/showthread.php?t=282282

local r = reaper

local FunctionFolder = r.GetResourcePath() ..
    '/Scripts/ReaTeam Scripts/Tracks Properties/bryanchi_FXD - Vertical FX List/Functions/'

dofile(FunctionFolder .. 'General functions.lua')
dofile(FunctionFolder .. 'FX Adder.lua')

--[[ arrange_hwnd  = reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 0x3E8) -- client position

_, Top_Arrang = reaper.JS_Window_ClientToScreen(arrange_hwnd, 0, 0)         -- convert to screen position (where clients x,y is actually on the screen)
 ]]

WetDryKnobSz         = 6
SpaceBtwnFXs         = 1
ShowFXNum            = true
Show_FX_Drag_Preview = true
MovFX                = { ToPos = {}, FromPos = {}, Lbl = {}, Copy = {}, FromTrack = {}, ToTrack = {} }
FX                   = { Enable = {} }
FxBtn                = {}
SendValSize          = 40
SendsLineHeight      = 12
HelpHint             = {}
HideBtnSz            = 10
Patch_Thick          = 4



local function msg(str)
  r.ShowConsoleMsg(str)
end
local function Change_Clr_Alpha(CLR, HowMuch)
  local R, G, B, A = r.ImGui_ColorConvertU32ToDouble4(CLR)
  local A = SetMinMax(A + HowMuch, 0, 1)
  return r.ImGui_ColorConvertDouble4ToU32(R, G, B, A)
end
function Convert_Val2Fader(rea_val)
  if not rea_val then return end
  local rea_val = SetMinMax(rea_val, 0, 4)
  local val
  local gfx_c, coeff = 0.8, 30
  local real_dB = 20 * math.log(rea_val, 10)
  local lin2 = 10 ^ (real_dB / coeff)
  if lin2 <= 1 then val = lin2 * gfx_c else val = gfx_c + (real_dB / 12) * (1 - gfx_c) end
  if val > 1 then val = 1 end
  return SetMinMax(val, 0.0001, 1)
end

function emptyStrToNil(str)
  if str == '' then return nil else return str end
end

function ColorChangeAnimation(frame, endframe, color, endClr)
  local A, outCLR
  if frame < endframe / 2 then
    A = (frame / endframe) * 2
    outCLR = Change_Clr_Alpha(color, A)
  else
    A = (endframe - frame) * 2 / 100
    outCLR = Change_Clr_Alpha(color, A)
  end
  --msg('frame ' .. frame .. 'A ' .. A .. '\n')

  return outCLR
end

function riseDropAnimation(frame, endframe)
  if frame < endframe / 2 then
    A = (frame / endframe) * 2
  else
    A = (endframe - frame) * 2 / 100
  end
  return A
end

function riseAnimation(frame, endframe, begin, End)
  A = (endframe / frame)
  return A
end

function FindFXFromFxGUID(FxID_To_Find)
  local out = { fx = {}, trk = {} }

  for t = 0, TrackCount - 1 do
    local trk = r.GetTrack(0, t)
    local FX_Ct = r.TrackFX_GetCount(trk)
    for fx = 0, FX_Ct - 1, 1 do
      local FxID = r.TrackFX_GetFXGUID(trk, fx)
      if FxID_To_Find == FxID then
        table.insert(out.fx, fx)
        table.insert(out.trk, trk)
      end
    end
  end


  return out
end

function ToggleTrackSendFav(Track, ID)
  if not ID then ID = TrkID end
  if Trk[ID].SendFav then
    Trk[ID].SendFav = false
    r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Track is Send Fav', '', true)
  else
    Trk[ID].SendFav = true
    r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Track is Send Fav', 'true', true)
  end
end

function Generate_Active_And_Hvr_CLRs(Clr)
  local ActV, HvrV
  local R, G, B, A = r.ImGui_ColorConvertU32ToDouble4(Clr)
  local H, S, V = r.ImGui_ColorConvertRGBtoHSV(R, G, B)


  if V then
    if V > 0.9 then
      ActV = V - 0.2
      HvrV = V - 0.1
    end
  end
  local R, G, B = r.ImGui_ColorConvertHSVtoRGB(H, S, SetMinMax(ActV or V + 0.2, 0, 1))
  local ActClr = r.ImGui_ColorConvertDouble4ToU32(R, G, B, A)
  local R, G, B = r.ImGui_ColorConvertHSVtoRGB(H, S, HvrV or V + 0.1)
  local HvrClr = r.ImGui_ColorConvertDouble4ToU32(R, G, B, A)
  return ActClr, HvrClr
end

RecvClr            = 0x569CD6ff
RecvClr1, RecvClr2 = Generate_Active_And_Hvr_CLRs(RecvClr)
SendClr            = 0xC586C0ff
SendClr1, SendClr2 = Generate_Active_And_Hvr_CLRs(SendClr)



local function getTrackPosAndHeight(track)
  if track then
    assert(track, "getTrackPosAndHeight: invalid parameter - track")

    local height = r.GetMediaTrackInfo_Value(track, "I_WNDH") -- current TCP window height in pixels including envelopes
    local posy = r.GetMediaTrackInfo_Value(track, "I_TCPY")   -- current TCP window Y-position in pixels relative to top of arrange view
    return posy, height
  end
end -- getTrackPosAndHeight()

function DB2VAL(x) return math.exp((x) * 0.11512925464970228420089957273422) end

function VAL2DB(x)
  if not x or x < 0.0000000298023223876953125 then return -150.0 end
  local v = math.log(x) * 8.6858896380650365530225783783321
  return math.max(v, -150)
end

function DragVol(ctx, V, Dir, scale, VOLorPan)
  if Mods == Shift then scale = scale * 0.185 end
  local DtX, DtY = r.ImGui_GetMouseDelta(ctx)
  if Dir == 'Horiz' then Dt = -DtX else Dt = DtY end
  if VOLorPan ~= 'Pan' then
    local adj = VAL2DB(V) - Dt * scale
    out = SetMinMax(DB2VAL(adj), 0, 4)
  else -- if it's pan
    out = SetMinMax(V - Dt * scale, -1, 1)
  end
  return out
end

function ToggleSolo(Trk)
  if r.GetMediaTrackInfo_Value(Trk, 'I_SOLO') == 0 then
    r.SetMediaTrackInfo_Value(Trk, 'I_SOLO', 1)
  else
    r.SetMediaTrackInfo_Value(Trk, 'I_SOLO', 0)
  end
end

----------------------------------------------------------------------------------------
local ctx = r.ImGui_CreateContext('FX List', r.ImGui_ConfigFlags_DockingEnable())
----------------------------------------------------------------------------------------



Font_Andale_Mono      = r.ImGui_CreateFont('andale mono', 13)
Font_Andale_Mono_6    = r.ImGui_CreateFont('andale mono', 6)
Font_Andale_Mono_7    = r.ImGui_CreateFont('andale mono', 7)
Font_Andale_Mono_8    = r.ImGui_CreateFont('andale mono', 8)
Font_Andale_Mono_9    = r.ImGui_CreateFont('andale mono', 9)
Font_Andale_Mono_10   = r.ImGui_CreateFont('andale mono', 10)
Font_Andale_Mono_11   = r.ImGui_CreateFont('andale mono', 11)
Font_Andale_Mono_12   = r.ImGui_CreateFont('andale mono', 12)
Font_Andale_Mono_13   = r.ImGui_CreateFont('andale mono', 13)
Font_Andale_Mono_14   = r.ImGui_CreateFont('andale mono', 14)
Font_Andale_Mono_15   = r.ImGui_CreateFont('andale mono', 15)
Font_Andale_Mono_16   = r.ImGui_CreateFont('andale mono', 16)

Font_Andale_Mono_10_B = r.ImGui_CreateFont('andale mono', 10, r.ImGui_FontFlags_Bold())

r.ImGui_Attach(ctx, Font_Andale_Mono)
r.ImGui_Attach(ctx, Font_Andale_Mono_6)
r.ImGui_Attach(ctx, Font_Andale_Mono_7)
r.ImGui_Attach(ctx, Font_Andale_Mono_8)
r.ImGui_Attach(ctx, Font_Andale_Mono_9)
r.ImGui_Attach(ctx, Font_Andale_Mono_10)
r.ImGui_Attach(ctx, Font_Andale_Mono_10_B)
r.ImGui_Attach(ctx, Font_Andale_Mono_11)
r.ImGui_Attach(ctx, Font_Andale_Mono_12)
r.ImGui_Attach(ctx, Font_Andale_Mono_13)
r.ImGui_Attach(ctx, Font_Andale_Mono_14)
r.ImGui_Attach(ctx, Font_Andale_Mono_15)
r.ImGui_Attach(ctx, Font_Andale_Mono_16)

function attachImages()
  local imageFolder = r.GetResourcePath() ..
      '/Scripts/ReaTeam Scripts/Tracks Properties/bryanchi_FXD - Vertical FX List/Images/'
  Img = {
    StarHollow = r.ImGui_CreateImage(imageFolder .. 'starHollow.png'),
    Star = r.ImGui_CreateImage(imageFolder .. 'star.png'),
    Send = r.ImGui_CreateImage(imageFolder .. 'send.png'),
    Recv = r.ImGui_CreateImage(imageFolder .. 'receive.png'),
    Show = r.ImGui_CreateImage(imageFolder .. 'show.png'),
    Hide = r.ImGui_CreateImage(imageFolder .. 'hide.png'),
    Link = r.ImGui_CreateImage(imageFolder .. 'link.png'),

  }
  r.ImGui_Attach(ctx, Img.Star)
  r.ImGui_Attach(ctx, Img.StarHollow)
  r.ImGui_Attach(ctx, Img.Send)
  r.ImGui_Attach(ctx, Img.Recv)
  r.ImGui_Attach(ctx, Img.Show)
  r.ImGui_Attach(ctx, Img.Hide)
  r.ImGui_Attach(ctx, Img.Link)
end

attachImages()


VP = {}



Alt   = r.ImGui_Mod_Alt()
Shift = r.ImGui_Mod_Shift()
Super = r.ImGui_Mod_Super()
Ctrl  = r.ImGui_Mod_Ctrl()
Trk   = {}


function RefreshUI_HideTrack()
  r.DockWindowRefresh()
  r.TrackList_AdjustWindows(false)
end

function ttp(A)
  r.ImGui_BeginTooltip(ctx)
  r.ImGui_SetTooltip(ctx, A)
  r.ImGui_EndTooltip(ctx)
end

function getClr(f)
  return r.ImGui_GetStyleColor(ctx, f)
end

function DeleteFX(fx, Track)
  r.TrackFX_Delete(Track, fx)
end

function SetHelpHint(L1, L2, L3, L4, L5, L6)
  if r.ImGui_IsItemHovered(ctx) then
    HelpHint[1] = L1
    HelpHint[2] = L2
    HelpHint[3] = L3
    HelpHint[4] = L4
    HelpHint[5] = L5
    HelpHint[6] = L6
  else
    HelpHint = {}
  end
end

function HighlightSelectedItem(FillClr, OutlineClr, Padding, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, GetItemRect,
                               Foreground, Thick)
  if GetItemRect == 'GetItemRect' then
    L, T = r.ImGui_GetItemRectMin(ctx); R, B = r.ImGui_GetItemRectMax(ctx); w, h = r.ImGui_GetItemRectSize(ctx)
    --Get item rect
  end
  local P = Padding; local HSC = H_OutlineSc or 4; local VSC = V_OutlineSc or 4
  if Foreground == 'Foreground' then
    WinDrawList = Foreground or FDL or r.ImGui_GetForegroundDrawList(ctx)
  else
    WinDrawList = Foreground
  end
  if not WinDrawList then WinDrawList = r.ImGui_GetWindowDrawList(ctx) end
  if FillClr then r.ImGui_DrawList_AddRectFilled(WinDrawList, L, T, R, B, FillClr) end

  if OutlineClr then
    r.ImGui_DrawList_AddLine(WinDrawList, L - P, T - P, L - P, T + h / VSC - P, OutlineClr, Thick);
    r.ImGui_DrawList_AddLine(WinDrawList, R + P, T - P, R + P, T + h / VSC - P, OutlineClr, Thick)
    r.ImGui_DrawList_AddLine(WinDrawList, L - P, B + P, L - P, B + P - h / VSC, OutlineClr, Thick);
    r.ImGui_DrawList_AddLine(WinDrawList, R + P, B + P, R + P, B - h / VSC + P, OutlineClr, Thick)
    r.ImGui_DrawList_AddLine(WinDrawList, L - P, T - P, L - P + w / HSC, T - P, OutlineClr, Thick);
    r.ImGui_DrawList_AddLine(WinDrawList, R + P, T - P, R + P - w / HSC, T - P, OutlineClr, Thick)
    r.ImGui_DrawList_AddLine(WinDrawList, L - P, B + P, L - P + w / HSC, B + P, OutlineClr, Thick);
    r.ImGui_DrawList_AddLine(WinDrawList, R + P, B + P, R + P - w / HSC, B + P, OutlineClr, Thick)
  end
  if GetItemRect == 'GetItemRect' then return L, T, R, B, w, h end
end

function HighlightItem(FillClr, WDL)
  L, T = r.ImGui_GetItemRectMin(ctx); R, B = r.ImGui_GetItemRectMax(ctx); w, h = r.ImGui_GetItemRectSize(ctx)
  --Get item rect
  r.ImGui_DrawList_AddRectFilled(WDL, L, T, R, B, FillClr)
end

function Add_WetDryKnob(ctx, label, labeltoShow, p_value, v_min, v_max, FX_Idx, Track)
  r.ImGui_SetNextItemWidth(ctx, 40)
  local radius_outer = WetDryKnobSz
  local pos = { reaper.ImGui_GetCursorScreenPos(ctx) }
  local center = { pos[1] + radius_outer, pos[2] + radius_outer }

  local line_height = reaper.ImGui_GetTextLineHeight(ctx)
  local draw_list = reaper.ImGui_GetWindowDrawList(ctx)
  local item_inner_spacing = { reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_ItemInnerSpacing()) }
  local mouse_delta = { reaper.ImGui_GetMouseDelta(ctx) }

  local ANGLE_MIN = 3.141592 * 0.75
  local ANGLE_MAX = 3.141592 * 2.25
  --  reaper.ImGui_InvisibleButton(ctx, label, radius_outer * 2, radius_outer * 2 + line_height - 10 + item_inner_spacing[2])

  reaper.ImGui_InvisibleButton(ctx, label, radius_outer * 2, line_height --[[ + item_inner_spacing[2] ]])
  local value_changed = false
  local is_active = reaper.ImGui_IsItemActive(ctx)
  local is_hovered = reaper.ImGui_IsItemHovered(ctx)
  if is_active and mouse_delta[2] ~= 0.0 then
    local step = (v_max - v_min) / 200.0

    if r.ImGui_GetKeyMods(ctx) == r.ImGui_Mod_Shift() then step = step / 5 end
    p_value = p_value + ((-mouse_delta[2]) * step)
    if p_value < v_min then p_value = v_min end
    if p_value > v_max then p_value = v_max end
  end







  if ActiveAny == true then
    if IsLBtnHeld == false then ActiveAny = false end
  end

  local t = (p_value - v_min) / (v_max - v_min)
  local angle = ANGLE_MIN + (ANGLE_MAX - ANGLE_MIN) * t
  local angle_cos, angle_sin = math.cos(angle), math.sin(angle)
  local radius_inner = radius_outer * 0.40

  local circleClr = getClr(r.ImGui_Col_FrameBgHovered())
  if p_value == 0 then
    circleClr = getClr(r.ImGui_Col_TextDisabled())
  elseif p_value ~= 1 then
    circleClr = getClr(r.ImGui_Col_FrameBgActive())
  end


  if is_active then
    --r.JS_Mouse_SetPosition(integer x, integer y)

    lineClr = r.ImGui_GetColor(ctx, r.ImGui_Col_SliderGrabActive())
    value_changed = true
    ActiveAny = true
    local P_Num = r.TrackFX_GetParamFromIdent(Track, FX_Idx, ':wet')
    r.TrackFX_SetParamNormalized(Track, FX_Idx, P_Num, p_value)
    HideCursorTillMouseUp(0, ctx)
    r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_None())
  else
    lineClr = circleClr
  end

  r.ImGui_DrawList_AddCircle(draw_list, center[1], center[2], radius_outer, circleClr)
  r.ImGui_DrawList_AddLine(draw_list, center[1], center[2], center[1] + angle_cos * (radius_outer - 2),
    center[2] + angle_sin * (radius_outer - 2), lineClr, 2.0)
  r.ImGui_DrawList_AddText(draw_list, pos[1], pos[2] + radius_outer * 2 + item_inner_spacing[2],
    reaper.ImGui_GetColor(ctx, reaper.ImGui_Col_Text()), labeltoShow)


  if is_active or is_hovered then
    local window_padding = { reaper.ImGui_GetStyleVar(ctx, reaper.ImGui_StyleVar_WindowPadding()) }
    reaper.ImGui_SetNextWindowPos(ctx, pos[1] + radius_outer * 3,
      pos[2] - 8)

    reaper.ImGui_BeginTooltip(ctx)
    reaper.ImGui_Text(ctx, ('%.f'):format(p_value * 100) .. '%')
    reaper.ImGui_EndTooltip(ctx)
  end

  return ActiveAny, value_changed, p_value
end

function AddSpacing(Rpt)
  for i = 1, Rpt, 1 do
    r.ImGui_Spacing(ctx)
  end
end

function MyText(text, font, color, WrapPosX)
  if WrapPosX then r.ImGui_PushTextWrapPos(ctx, WrapPosX) end

  if font then r.ImGui_PushFont(ctx, font) end
  if color then
    reaper.ImGui_TextColored(ctx, color, text)
  else
    reaper.ImGui_Text(ctx, text)
  end

  if font then r.ImGui_PopFont(ctx) end
  if WrapPosX then r.ImGui_PopTextWrapPos(ctx) end
end

function SL(x, w)
  r.ImGui_SameLine(ctx, x, w)
end

function MoveFX(DragFX_ID, FX_Idx, isMove, AddLastSpace, FromTrack, ToTrack)
  local AltDest, AltDestLow, AltDestHigh, DontMove

  if SpcInPost then SpcIsInPre = false end

  if SpcIsInPre then
    if not tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]) then -- if fx is not in pre fx
      if SpaceIsBeforeRackMixer == 'End of PreFX' then
        table.insert(Trk[TrkID].PreFX, #Trk[TrkID].PreFX + 1, FXGUID[DragFX_ID])
        r.TrackFX_CopyToTrack(Track, DragFX_ID, Track, FX_Idx + 1, true)
        DontMove = true
      else
        table.insert(Trk[TrkID].PreFX, FX_Idx + 1, FXGUID[DragFX_ID])
      end
    else -- if fx is in pre fx
      local offset = 0
      if r.TrackFX_AddByName(Track, 'FXD Macros', 0, 0) ~= -1 then offset = -1 end
      if FX_Idx < DragFX_ID then -- if drag towards left
        table.remove(Trk[TrkID].PreFX, DragFX_ID + 1 + offset)
        table.insert(Trk[TrkID].PreFX, FX_Idx + 1 + offset, FXGUID[DragFX_ID])
      elseif SpaceIsBeforeRackMixer == 'End of PreFX' then
        table.insert(Trk[TrkID].PreFX, #Trk[TrkID].PreFX + 1, FXGUID[DragFX_ID])
        table.remove(Trk[TrkID].PreFX, DragFX_ID + 1 + offset)
        --move fx down
      else
        table.insert(Trk[TrkID].PreFX, FX_Idx + 1 + offset, FXGUID[DragFX_ID])
        table.remove(Trk[TrkID].PreFX, DragFX_ID + 1 + offset)
      end
    end

    for i, v in pairs(Trk[TrkID].PreFX) do
      r.GetSetMediaTrackInfo_String(Track, 'P_EXT: PreFX ' ..
        i, v, true)
    end
    if tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]) then
      table.remove(Trk[TrkID].PostFX, tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]))
    end
    FX.InLyr[FXGUID[DragFX_ID]] = nil
  elseif SpcInPost then
    local offset

    if r.TrackFX_AddByName(Track, 'FXD Macros', 0, 0) == -1 then offset = -1 else offset = 0 end

    if not tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]) then -- if fx is not yet in post-fx chain
      InsertToPost_Src = DragFX_ID + offset + 1

      InsertToPost_Dest = SpcIDinPost


      if tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]) then
        table.remove(Trk[TrkID].PreFX, tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]))
      end
    else                              -- if fx is already in post-fx chain
      local IDinPost = tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID])
      if SpcIDinPost <= IDinPost then -- if drag towards left
        table.remove(Trk[TrkID].PostFX, IDinPost)
        table.insert(Trk[TrkID].PostFX, SpcIDinPost, FXGUID[DragFX_ID])
        table.insert(MovFX.ToPos, FX_Idx + 1)
      else
        table.insert(Trk[TrkID].PostFX, SpcIDinPost, Trk[TrkID].PostFX[IDinPost])
        table.remove(Trk[TrkID].PostFX, IDinPost)
        table.insert(MovFX.ToPos, FX_Idx)
      end
      DontMove = true
      table.insert(MovFX.FromPos, DragFX_ID)
    end
    FX.InLyr[FXGUID[DragFX_ID]] = nil
    --[[ else -- if space is not in pre or post
    r.GetSetMediaTrackInfo_String(Track, 'P_EXT: PreFX ' .. DragFX_ID, '', true)
    if not MoveFromPostToNorm then
      if tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]) then
        table.remove(Trk[TrkID].PreFX,
          tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]))
      end
    end
    if tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]) then
      table.remove(Trk[TrkID].PostFX,
        tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]))
    end ]]
  end
  --[[ for i = 1, #Trk[TrkID].PostFX + 1, 1 do
    r.GetSetMediaTrackInfo_String(Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '', true)
  end
  for i = 1, #Trk[TrkID].PreFX + 1, 1 do --remove from pre FX
    r.GetSetMediaTrackInfo_String(Track, 'P_EXT: PreFX ' .. i, Trk[TrkID].PreFX[i] or '', true)
  end ]]
  if not DontMove then
    --[[ if FX_Idx ~= RepeatTimeForWindows and SpaceIsBeforeRackMixer ~= 'End of PreFX' then

      if (FX.Win_Name_S[FX_Idx] or ''):find('Pro%-C 2') then
        AltDestHigh = FX_Idx - 1
      end
      FX_Idx = tonumber(FX_Idx)
      DragFX_ID = tonumber(DragFX_ID)

      if FX_Idx > DragFX_ID then offset = 1 end


      table.insert(MovFX.ToPos, AltDestLow or FX_Idx - (offset or 0))
      table.insert(MovFX.FromPos, DragFX_ID)
    elseif FX_Idx == RepeatTimeForWindows and AddLastSpace == 'LastSpc' or SpaceIsBeforeRackMixer == 'End of PreFX' then
      local offset

      if Trk[TrkID].PostFX[1] then offset = #Trk[TrkID].PostFX end
      table.insert(MovFX.ToPos, FX_Idx - (offset or 0))
      table.insert(MovFX.FromPos, DragFX_ID)
    else ]]
    table.insert(MovFX.ToPos, FX_Idx - (offset or 0))
    table.insert(MovFX.FromPos, DragFX_ID)
    table.insert(MovFX.ToTrack, ToTrack)
    table.insert(MovFX.FromTrack, FromTrack)

    --[[ end
  end ]]
    if isMove == false then
      NeedCopyFX = true
      DropPos = FX_Idx
    end
  end
end

outlineClr = Change_Clr_A(getClr(r.ImGui_Col_FrameBg()), 1)




------------Recall Stored Info before Loop --------------------
TrackCount = r.GetNumTracks()
for t = 0, TrackCount - 1 do
  local Track = r.GetTrack(0, t)
  local ID = r.GetTrackGUID(Track)
  Trk[ID] = Trk[ID] or {}
  Trk[ID].SendFav = StringToBool[select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Track is Send Fav', '', false))]
  local Fx_Ct = r.TrackFX_GetCount(Track)
  for fx = 0, Fx_Ct - 1, 1 do
    local fxID = r.TrackFX_GetFXGUID(Track, fx)
    FX[fxID] = FX[fxID] or {}
    FX[fxID].Link = emptyStrToNil(select(2,
      r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. fxID .. 'Link to ', '', false)))
  end
end






----------====================================================================================================
function loop()
  Top_Arrang = tonumber(select(2, r.BR_Win32_GetPrivateProfileString("REAPER", "toppane", "", r.get_ini_file()))) + 5

  visible, open = r.ImGui_Begin(ctx, 'My window', true,
    r.ImGui_WindowFlags_NoScrollWithMouse() + r.ImGui_WindowFlags_NoScrollbar() + r.ImGui_WindowFlags_MenuBar())


  if HelpHint then
    r.ImGui_PushFont(ctx, Font_Andale_Mono_10)

    for i, v in ipairs(HelpHint) do
      r.ImGui_Text(ctx, v)
    end
    r.ImGui_PopFont(ctx)
  end


  VP.vp = r.ImGui_GetWindowViewport(ctx)
  VP.w, VP.h = r.ImGui_Viewport_GetSize(VP.vp)
  LBtnDC = r.ImGui_IsMouseDoubleClicked(ctx, 0)

  Mods = r.ImGui_GetKeyMods(ctx)
  if not FDL then FDL = r.ImGui_GetForegroundDrawList(ctx) end
  if visible then
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(), 0, SpaceBtwnFXs)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 0, 1)


    local TrackCount = r.GetNumTracks()

    ----move fx -----
    if MovFX.FromPos[1] then
      local UndoLbl
      --r.Undo_BeginBlock()
      for i, v in ipairs(MovFX.FromPos) do
        if NeedCopyFX then
          local offset = 0
          if MovFX.FromTrack[i] == MovFX.ToTrack[i] then
            if v >= DropPos then offset = 0 else offset = -1 end
          end
          local topos = math.max(MovFX.ToPos[i] - (offset or 0), 0)

          r.TrackFX_CopyToTrack(MovFX.FromTrack[i], v, MovFX.ToTrack[i], topos, false)
          if NeedLinkFXsID then
            --, FxName = r.TrackFX_GetFXName(MovFX.ToTrack[i], topos)
            local Ct = r.TrackFX_GetCount(MovFX.ToTrack[i]) - 1
            local ID = r.TrackFX_GetFXGUID(MovFX.ToTrack[i], math.min(topos, Ct))

            FX[ID] = FX[ID] or {}
            FX[ID].Link = NeedLinkFXsID
            FX[NeedLinkFXsID].Link = ID
            r.GetSetMediaTrackInfo_String(MovFX.FromTrack[i], 'P_EXT: FX' .. NeedLinkFXsID .. 'Link to ', ID, true)
            r.GetSetMediaTrackInfo_String(MovFX.ToTrack[i], 'P_EXT: FX' .. ID .. 'Link to ', NeedLinkFXsID, true)



            --FX[NeedLinkFXsID].Link =
          end
        end
      end

      if not NeedCopyFX then
        for i, v in ipairs(MovFX.FromPos) do
          r.TrackFX_CopyToTrack(MovFX.FromTrack[i], v, MovFX.ToTrack[i], MovFX.ToPos[i], true)
        end
      end




      --r.Undo_EndBlock(MovFX.Lbl[i] or (UndoLbl or 'Move' .. 'FX'), 0)
      MovFX = { FromPos = {}, ToPos = {}, Lbl = {}, Copy = {}, FromTrack = {}, ToTrack = {} }
      NeedCopyFX = nil
      DropPos = nil


      --[[  MovFX.ToPos = {}
      MovFX.Lbl = {} ]]
    end

    if Mods == Ctrl + Shift + Alt then
      DebugMode = true
    else
      DebugMode = false
    end

    for t = -1, TrackCount - 1, 1 do
      Trk[t] = Trk[t] or {}

      local T = Trk[t]
      if t == -1 then
        Track = r.GetMasterTrack(0)
      else
        Track = r.GetTrack(0, t)
      end


      TrkID      = r.GetTrackGUID(Track)
      Trk[TrkID] = Trk[TrkID] or {}

      local hide = 0

      if t == -1 then
        Trk[t].PosY, Trk[t].H = getTrackPosAndHeight(Track)
        r.ImGui_SetCursorPosY(ctx, Top_Arrang + Trk[t].PosY)
        local masterVisibility = r.GetMasterTrackVisibility()
        if masterVisibility == 2 or masterVisibility == 0 then hide = 0 else hide = 1 end
      else
        hide = r.GetMediaTrackInfo_Value(Track, 'B_SHOWINTCP')
      end



      WheelV = r.ImGui_GetMouseWheel(ctx)
      if WheelV ~= 0 then
        local windowHWND = r.GetMainHwnd()
        retval, position, pageSize, min, max, trackPos = r.JS_Window_GetScrollInfo(windowHWND, 'v')

        r.JS_Window_SetScrollPos(windowHWND, 'VERT', math.ceil(position + WheelV))
        r.UpdateArrange()
      end

      if Track and hide ~= 0 then
        Trk[t].PosY, Trk[t].H = getTrackPosAndHeight(Track)
        Trk[t].H = Trk[t].H - 1

        FXPane_W = FXPane_W or 200
        r.ImGui_PushFont(ctx, Font_Andale_Mono_10)

        if r.ImGui_BeginChildFrame(ctx, 'Track' .. t, FXPane_W, Trk[t].H, r.ImGui_WindowFlags_NoScrollbar() + r.ImGui_WindowFlags_NoScrollWithMouse()) then
          --r.ImGui_Text(ctx, 'track' .. t .. '     ' .. Trk[t].PosY)
          if not WDL then WDL = r.ImGui_GetWindowDrawList(ctx) end
          --------------------------------------------
          ------Repeat for Every fx-------------------
          --------------------------------------------
          function FXBtns(Track, BtnSz)
            FX_Ct = r.TrackFX_GetCount(Track)
            local AutoSize
            if BtnSz == 'Auto Size' then
              local A = {}
              for fx = 0, FX_Ct - 1, 1 do
                local rv, Name = r.TrackFX_GetFXName(Track, fx)
                w, h = r.ImGui_CalcTextSize(ctx, Name)

                table.insert(A, w)
              end
              if A[1] then
                AutoSize = math.max(table.unpack(A)) - WetDryKnobSz * 2.5
              end
            end

            BtnSz = BtnSz or FXPane_W - WetDryKnobSz * 2.5
            if BtnSz == 'Auto Size' then BtnSz = AutoSize end


            -- Repeat for every fx
            for fx = 0, FX_Ct - 1, 1 do
              local rv, Name = r.TrackFX_GetFXName(Track, fx)
              local FX_Is_Open
              Trk[t][fx] = Trk[t][fx] or {}
              local F = Trk[t][fx]


              if r.TrackFX_GetOpen(Track, fx) then
                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), getClr(r.ImGui_Col_ButtonActive()))

                FX_Is_Open = true
              end

              if r.ImGui_IsMouseDown(ctx, 0) then
                Dur = r.ImGui_GetMouseDownDuration(ctx, 0)
                DragX, DragY = r.ImGui_GetMouseDragDelta(ctx, DragX, DragY)
                if not MouseDragDir then
                  if DragX > 5 or DragX < -5 then
                    MouseDragDir = 'Horiz'
                  elseif DragY > 5 or DragY < -5 then
                    MouseDragDir = 'Vert'
                  end
                end
              else
                MouseDragDir = nil
              end

              local ShownName = ChangeFX_Name(Name)
              local fxID = r.TrackFX_GetFXGUID(Track, fx)
              if fxID then FX[fxID] = FX[fxID] or {} end
              if DebugMode then
                ShownName = fxID
              end
              local offset = 0
              if FX[fxID] and FX[fxID].Link then
                if r.ImGui_ImageButton(ctx, '##Link' .. fxID, Img.Link, HideBtnSz, HideBtnSz, nil, nil, nil, nil, nil, tintClr) then
                  local out = FindFXFromFxGUID(FX[fxID].Link)
                  r.GetSetMediaTrackInfo_String(out.trk[1], 'P_EXT: FX' .. FX[fxID].Link .. 'Link to ', '', true)
                  r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. fxID .. 'Link to ', '', true)
                  FX[FX[fxID].Link].Link = nil
                  FX[fxID].Link = nil
                end
                offset = HideBtnSz
                SL(nil, 1)
                if HoveredLinkedFXID then
                  if FX[HoveredLinkedFXID].Link == fxID then
                    local x, y = r.ImGui_GetCursorScreenPos(ctx)
                    local x = x - HideBtnSz / 2
                    local y2
                    if LinkCablePosY > y then
                      y = y + HideBtnSz * 1.3
                      y2 = LinkCablePosY - HideBtnSz * 1.5
                    else
                      y2 = LinkCablePosY
                    end
                    r.ImGui_DrawList_AddLine(FDL, LinkCablePosX, y2, LinkCablePosX, y, 0xffffffff, Patch_Thick)
                  end
                end
              end


              if r.ImGui_Button(ctx, ShownName .. '##' .. fx, BtnSz - offset) and Dur < 0.15 then
                if Mods == 0 then
                  if FX_Is_Open then
                    r.TrackFX_Show(Track, fx, 2)
                  else
                    --[[ if r.ImGui_IsPopupOpen(ctx, 'SendDestTrackWin' .. OpenedDestTrkWin, r.ImGui_PopupFlags_AnyPopup()) then
                      r.Main_OnCommandEx(r.NamedCommandLookup('SWS/BR: Focus arrange'), 0, 0)


                      openSendWinPop = Track
                    end ]]

                    r.TrackFX_Show(Track, fx, 3)

                    --r.TrackFX_SetOpen(Track, fx, true)
                  end
                elseif Mods == Alt then
                  DeleteFX(fx, Track)
                  HoveredLinkedFXID = nil
                elseif Mods == Shift then
                  ToggleBypassFX(Track, fx)
                end
              end

              --Show link cable if hovered ---
              if FX[fxID] and FX[fxID].Link then
                if r.ImGui_IsItemHovered(ctx) then
                  local x, y        = r.ImGui_GetCursorScreenPos(ctx)
                  LinkCablePosX     = x + HideBtnSz / 2
                  LinkCablePosY     = y
                  HoveredLinkedFXID = fxID
                else
                  if HoveredLinkedFXID == fxID then
                    LinkCablePosX, LinkCablePosY, HoveredLinkedFXID = nil
                  end
                end
              end



              FxBtn.H = FxBtn.H or select(2, r.ImGui_GetItemRectSize(ctx))


              FX.Enable[fx] = r.TrackFX_GetEnabled(Track, fx)

              if FX.Enable[fx] == false then -- add a shade to show it's bypassed
                local L, T = r.ImGui_GetItemRectMin(ctx)
                r.ImGui_DrawList_AddRectFilled(WDL, L, T, L + BtnSz, T + FxBtn.H, 0x000000aa)
                --HighlightSelectedItem(0x00000088, nil, 0, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', WDL)
              end



              if MouseDragDir == 'Vert' then
                if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_AcceptNoDrawDefaultRect()) then
                  DraggingTrack = t
                  DraggingTrack_Data = Track

                  r.ImGui_SetDragDropPayload(ctx, 'DragFX', fx)
                  if Show_FX_Drag_Preview then
                    r.ImGui_BeginTooltip(ctx)
                    r.ImGui_Button(ctx, Name .. '##' .. fx, BtnSz)
                    r.ImGui_EndTooltip(ctx)
                  end
                  r.ImGui_EndDragDropSource(ctx)
                end
              end

              if r.ImGui_BeginDragDropTarget(ctx) then
                dropped, draggedFX = r.ImGui_AcceptDragDropPayload(ctx, 'DragFX') --

                rv, type, draggedFX, is_preview, is_delivery = r.ImGui_GetDragDropPayload(ctx)
                local draggedFX = tonumber(draggedFX)
                if t == DraggingTrack then    -- if drag to same track
                  if fx <= draggedFX - 1 then -- if destination is one slot above dragged FX
                    local L, T = r.ImGui_GetItemRectMin(ctx); w, h = r.ImGui_GetItemRectSize(ctx)
                    r.ImGui_DrawList_AddLine(WDL, L, T, L + FXPane_W, T, 0xffffffff)
                  else
                    local L, T = r.ImGui_GetItemRectMin(ctx); local R, B = r.ImGui_GetItemRectMax(ctx);
                    local w, h = r.ImGui_GetItemRectSize(ctx)
                    r.ImGui_DrawList_AddLine(WDL, L, B, L + FXPane_W, B, 0xffffffff)
                  end
                else
                  local L, T = r.ImGui_GetItemRectMin(ctx); w, h = r.ImGui_GetItemRectSize(ctx)
                  r.ImGui_DrawList_AddLine(WDL, L, T, L + FXPane_W, T, 0xffffffff)
                end

                if dropped then
                  if Mods == 0 then
                    MoveFX(draggedFX, fx, true, nil, DraggingTrack_Data, Track)
                  elseif Mods == Super then
                    MoveFX(draggedFX, fx, false, nil, DraggingTrack_Data, Track)
                  elseif Mods == Ctrl then --Pool FX
                    MoveFX(draggedFX, fx, false, nil, DraggingTrack_Data, Track)
                    local ID = r.TrackFX_GetFXGUID(DraggingTrack_Data, draggedFX)
                    NeedLinkFXsID = ID
                    FX[ID] = FX[ID] or {}
                  end
                end



                r.ImGui_EndDragDropTarget(ctx)
              end

              F.Wet_PNum = F.Wet_PNum or r.TrackFX_GetParamFromIdent(Track, fx, ':wet')

              if r.ImGui_IsItemActive(ctx) and MouseDragDir == 'Horiz' then
                --F.Wet = F.Wet + r.ImGui_GetMouseDelta(ctx) * 0.01

                local Val = r.TrackFX_GetParamNormalized(Track, fx, F.Wet_PNum)
                local Scale = 0.01
                if r.ImGui_GetKeyMods(ctx) == r.ImGui_Mod_Shift() then Scale = 0.002 end
                local Delta = r.ImGui_GetMouseDelta(ctx) * Scale

                r.TrackFX_SetParamNormalized(Track, fx, F.Wet_PNum, Val + Delta)
                F.Wet = Val
                r.ImGui_BeginTooltip(ctx)
                r.ImGui_Text(ctx, ('%.f'):format(Val * 100) .. '%')
                r.ImGui_EndTooltip(ctx)
              elseif r.ImGui_IsItemActive(ctx) and MouseDragDir == 'Vert' then
                HighlightSelectedItem(0xffffff22, 0xffffffff, 0, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                  'GetItemRect',
                  WDL)
              end

              if FX_Is_Open then r.ImGui_PopStyleColor(ctx) end
              r.ImGui_SameLine(ctx, 0, 0)
              F.ActiveAny, F.Active, F.Wet = Add_WetDryKnob(ctx, 'WD' .. fx, '',
                F.Wet or r.TrackFX_GetParamNormalized(Track, fx, F.Wet_PNum), 0, 1, fx, Track)
            end
          end

          FXBtns(Track)
          --[[ if openSendWinPop == Track then

            for i = 0, NumSends - 1, 1 do
              if i == OpenedDestTrkWin then
                if not r.ImGui_IsPopupOpen(ctx, 'SendDestTrackWin' .. OpenedDestTrkWin) then
                  --consider using open window instead
                  --r.Main_OnCommandEx(r.NamedCommandLookup('SWS/BR: Focus arrange'), 0, 0)
                  r.ImGui_OpenPopup(ctx, 'SendDestTrackWin' .. OpenedDestTrkWin)
                else

                end
              end
            end
          end ]]

          --if FX_Ct == 0 then -- if there's no fx on track
          r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), getClr(r.ImGui_Col_ChildBg()))
          r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), getClr(r.ImGui_Col_FrameBgHovered()))

          if r.ImGui_Button(ctx, ' ##empty', FXPane_W, T.H) then
            if Mods == 0 then
              --FilterBox(fx, LyrID, SpaceIsBeforeRackMixer, FxGUID_Container, SpcIsInPre, SpcInPost, SpcIDinPost) -- Add FX Window
            end
          end
          r.ImGui_PopStyleColor(ctx, 2)


          if r.ImGui_BeginDragDropTarget(ctx) then
            dropped, draggedFX = r.ImGui_AcceptDragDropPayload(ctx, 'DragFX') --

            rv, type, draggedFX, is_preview, is_delivery = r.ImGui_GetDragDropPayload(ctx)
            local draggedFX = tonumber(draggedFX)
            local L, T = r.ImGui_GetItemRectMin(ctx); w, h = r.ImGui_GetItemRectSize(ctx)
            r.ImGui_DrawList_AddLine(WDL, L, T, L + FXPane_W, T, 0xffffffff)

            if dropped then
              if Mods == 0 then
                MoveFX(draggedFX, FX_Ct, true, nil, DraggingTrack_Data, Track)
              elseif Mods == Super then
                MoveFX(draggedFX, FX_Ct, false, nil, DraggingTrack_Data, Track)
              elseif Mods == Ctrl then --Pool FX
                MoveFX(draggedFX, FX_Ct, false, nil, DraggingTrack_Data, Track)
                local ID = r.TrackFX_GetFXGUID(DraggingTrack_Data, draggedFX)
                NeedLinkFXsID = ID
                FX[ID] = FX[ID] or {}
              end
            end
            r.ImGui_EndDragDropTarget(ctx)
          end
          --end
          r.ImGui_EndChildFrame(ctx)
        end
        r.ImGui_PopFont(ctx)

        --------------------------------------------
        ------Make child frame for sends -----------
        --------------------------------------------
        r.ImGui_SameLine(ctx, nil, 0)
        --SeparateX = r.ImGui_CursorPos(ctx)
        local Send_W = VP.w - FXPane_W
        r.ImGui_PushFont(ctx, Font_Andale_Mono_10)

        --r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), getClr(r.ImGui_Col_ButtonActive()))

        local Sep_H = Trk[t].H
        if t == TrackCount - 1 then
          Sep_H = Trk[t].H
        end
        r.ImGui_Button(ctx, '##Separator' .. t, 3, Sep_H)

        if r.ImGui_IsItemActive(ctx) then
          HighlightSelectedItem(getClr(r.ImGui_Col_ButtonActive()), OutlineClr, Padding, L, T, R, B, h, w, H_OutlineSc,
            V_OutlineSc, 'GetItemRect')
          if Mods == 0 then
            local DtX = r.ImGui_GetMouseDelta(ctx)
            FXPane_W = FXPane_W + DtX
          end
        end

        if r.ImGui_IsItemHovered(ctx) or r.ImGui_IsItemActive(ctx) then
          r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_ResizeEW())
          Sep_Hvr = t
        end
        if Sep_Hvr then
          HighlightSelectedItem(getClr(r.ImGui_Col_ButtonHovered()), OutlineClr, Padding, L, T, R, B, h, w, H_OutlineSc,
            V_OutlineSc, 'GetItemRect')
        end
        if Sep_Hvr == t then
          if not r.ImGui_IsItemHovered(ctx) then Sep_Hvr = nil end
        end
        r.ImGui_SameLine(ctx, nil, 0)

        local WDL = r.ImGui_GetWindowDrawList(ctx)
        if r.ImGui_BeginChildFrame(ctx, 'Sends' .. t, Send_W, Trk[t].H, r.ImGui_WindowFlags_NoScrollbar() + r.ImGui_WindowFlags_NoScrollWithMouse()) then
          ------ Repeat for Sends------
          NumSends = r.GetTrackNumSends(Track, 0)

          local BtnSize = Send_W - SendValSize - 20
          if t > -1 then
            for i = 0, NumSends, 1 do
              local BtnSizeOffset = 0
              local rv, SendName  = r.GetTrackSendName(Track, i)
              local Vol           = r.GetTrackSendInfo_Value(Track, 0, i, 'D_VOL')
              if SendName ~= '' then
                r.ImGui_AlignTextToFramePadding(ctx)
                local BP = {}
                local HoverEyes
                --Get Send Bypass State
                local Bypass = r.GetTrackSendInfo_Value(Track, 0, i, 'B_MUTE')
                local RemoveSend
                local DestTrk = r.GetTrackSendInfo_Value(Track, 0, i, 'P_DESTTRACK')
                local Dest_Hidden

                if HoverSend == i .. TrkID then
                  PatchX, PatchY = r.ImGui_GetCursorScreenPos(ctx)
                  HoverSend_Dest = DestTrk
                  HoverSend_Src = Track
                end

                -- if Send Destination Track is hidden
                if r.GetMediaTrackInfo_Value(DestTrk, 'B_SHOWINTCP') == 0 then
                  Dest_Hidden = true
                  if r.ImGui_ImageButton(ctx, '##HideBtn', Img.Hide, HideBtnSz, HideBtnSz, nil, nil, nil, nil, nil, 0xffff00ff) then
                    r.SetMediaTrackInfo_Value(DestTrk, 'B_SHOWINTCP', 1)
                    RefreshUI_HideTrack()
                  end
                  SL()
                  BtnSizeOffset = -HideBtnSz
                end

                -- if hovering send, show Hide Track icon
                if HoverSend == i .. TrkID and not Dest_Hidden then
                  if r.ImGui_ImageButton(ctx, '##HideBtn', Img.Show, HideBtnSz, HideBtnSz, nil, nil, nil, nil, nil, 0xffff00ff) then
                    r.SetMediaTrackInfo_Value(DestTrk, 'B_SHOWINTCP', 0)
                    RefreshUI_HideTrack()
                  end
                  if r.ImGui_IsItemHovered(ctx) then
                    HoverEyes = true
                  end
                  SL()
                end
                -- if hovering send, show solo icon
                if HoverSend == i .. TrkID then
                  r.ImGui_PushFont(ctx, Font_Andale_Mono_10_B)
                  if r.ImGui_Button(ctx, 'S', 12, 12) then -- Solo Button
                    if Mods == 0 then
                      ToggleSolo(DestTrk)
                      ToggleSolo(Track)
                    elseif Mods == Ctrl then
                      local unmute
                      if NumSends > 1 then
                        -- mute all sends except the one clicked
                        Trk[TrkID].alreadyMutedSend = Trk[TrkID].alreadyMutedSend or {}
                        for S = 0, NumSends - 1, 1 do
                          if i ~= S then
                            Trk[TrkID].alreadyMutedSend[S] = Trk[TrkID].alreadyMutedSend[S] or
                                r.GetTrackSendInfo_Value(Track, 0, S, 'B_MUTE')
                          end
                        end

                        for S = 0, NumSends - 1, 1 do
                          if i ~= S then
                            if r.GetTrackSendInfo_Value(Track, 0, S, 'B_MUTE') == 1 and Trk[TrkID].alreadyMutedSend[S] == 0 then --- if send is muted
                              r.SetTrackSendInfo_Value(Track, 0, S, 'B_MUTE', 0)                                                 --unmute
                              unmute = true
                            else                                                                                                 --if send is not muted
                              r.SetTrackSendInfo_Value(Track, 0, S, 'B_MUTE', 1)                                                 --mute
                            end
                          end
                        end

                        if unmute then Trk[TrkID].alreadyMutedSend = {} end
                      end
                    end
                  end

                  if r.ImGui_IsItemHovered(ctx) then
                    HoverEyes = true
                  end
                  SetHelpHint('LMB = Toggle Send Track Solo', 'Ctrl+LMB = Toggle Send Solo')
                  r.ImGui_PopFont(ctx)
                  SL()
                  BtnSizeOffset = -20
                end
                r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ButtonTextAlign(), 0.1, 0.5)

                local SendNameClick = r.ImGui_Button(ctx, SendName .. '##', BtnSize + BtnSizeOffset, SendsLineHeight)
                r.ImGui_PopStyleVar(ctx)
                if SendNameClick then
                  r.ImGui_OpenPopup(ctx, 'SendDestTrackWin' .. i)
                  OpenedDestTrkWin = Track
                  OpenedDestSendWin = i


                  --x, y = r.ImGui_GetCursorScreenPos(ctx)
                  --r.ImGui_SetNextWindowPos(ctx,  ,y)
                end

                --[[ if openSendWinPop then
                  r.ImGui_OpenPopup(ctx, 'SendDestTrackWin' .. OpenedDestTrkWin)
                  openSendWinPop = nil
                end ]]



                r.ImGui_SameLine(ctx, nil, 1)


                if r.ImGui_IsItemHovered(ctx) or HoverEyes then
                  HoverSend = i .. TrkID
                else
                  if HoverSend == i .. TrkID then
                    HoverSend = nil
                    HoverSend_Dest = nil
                  end
                end
                if Bypass == 1 then
                  BP.L, BP.T = r.ImGui_GetItemRectMin(ctx)
                  BP.R, BP.B = r.ImGui_GetItemRectMax(ctx)
                end

                if r.ImGui_IsItemClicked(ctx) then
                  if Mods == Shift then
                    if Bypass == 0 then
                      r.SetTrackSendInfo_Value(Track, 0, i, 'B_MUTE', 1)
                    else
                      r.SetTrackSendInfo_Value(Track, 0, i, 'B_MUTE', 0)
                    end
                  elseif Mods == Alt then
                    RemoveSend = true
                  end
                end

                retval, volume, pan = r.GetTrackSendUIVolPan(Track, i)
                local ShownVol
                if volume < 0.0001 then
                  ShownVol = '-inf'
                else
                  ShownVol = ('%.1f'):format(VAL2DB(volume))
                end

                --r.ImGui_Image(ctx, Img.Send, 10, 10)

                local CurX, CurY = r.ImGui_GetCursorScreenPos(ctx)

                r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ButtonTextAlign(), 1, 0.5)

                local SendBtnClick = r.ImGui_Button(ctx, ShownVol .. '##Send', SendValSize, SendsLineHeight)
                r.ImGui_PopStyleVar(ctx)


                r.ImGui_DrawList_AddImage(WDL, Img.Send, CurX, CurY, CurX + 10, CurY + 10)


                if r.ImGui_IsItemClicked(ctx) then
                  draggingSend = 'Track' .. t .. 'Send' .. i
                  if Mods == Alt then
                    RemoveSend = true
                  end
                end

                if draggingSend == 'Track' .. t .. 'Send' .. i and r.ImGui_IsMouseDown(ctx, 0) then
                  if Mods == 0 or Mods == Shift then
                    local DtX, DtY = r.ImGui_GetMouseDelta(ctx)

                    local scale = 0.8
                    if Mods == Shift then scale = 0.15 end
                    local adj = VAL2DB(volume) - DtY * scale
                    local out = SetMinMax(DB2VAL(adj), 0, 4)
                    r.BR_GetSetTrackSendInfo(Track, 0, i, 'D_VOL', true, out)
                  end
                end

                if LBtnDC and r.ImGui_IsItemHovered(ctx) then
                  r.SetTrackSendUIVol(Track, i, 1, 0)
                  r.BR_GetSetTrackSendInfo(Track, 0, i, 'D_VOL', true, 1)
                end


                if not r.ImGui_IsMouseDown(ctx, 0) then
                  draggingSend = nil
                end


                if RemoveSend then
                  r.RemoveTrackSend(Track, 0, i)
                end

                --[[ if r.ImGui_IsItemActive(ctx) then
                  if Mods == 0 then
                    local DtX, DtY = r.ImGui_GetMouseDelta(ctx)

                    r.BR_GetSetTrackSendInfo(Track, 0, i, 'D_VOL', true, volume + DtY * 0.1)
                  end
                end ]]
                if Bypass == 1 then
                  r.ImGui_DrawList_AddRectFilled(WDL, BP.L, BP.T, BP.L + Send_W, BP.B, 0x000000aa)
                end
                local x = r.ImGui_GetItemRectMax(ctx)
                local y = select(2, r.ImGui_GetItemRectMin(ctx))
                x = x + 2
                y = y - 2
                local FXCt = r.TrackFX_GetCount(DestTrk)

                local rectH = 100 + 10 * FXCt
                local LineAtLeft = 30
                local Top = y - rectH * 0.1
                local Btm = y + rectH * 0.9
                local LineThick = 8
                local WinPad = 0
                r.ImGui_SetNextWindowPos(ctx, x + 2, Top)
                --r.ImGui_SetNextWindowSize(ctx, FXPane_W + LineAtLeft + LineThick, rectH + LineThick)
                r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(), LineThick + WinPad, LineThick)
                if OpenedDestSendWin == i and OpenedDestTrkWin == Track then
                  local resize = r.ImGui_WindowFlags_AlwaysAutoResize()
                  local notitle = r.ImGui_WindowFlags_NoTitleBar()


                  r.ImGui_Begin(ctx, 'SendDestTrackWin' .. (OpenedDestSendWin or ''), true, resize + notitle)
                  --if r.ImGui_BeginPopup(ctx, 'SendDestTrackWin' .. i, r.ImGui_WindowFlags_NoBackground()) then
                  local L = x + LineAtLeft
                  local Y_Mid = y + 8
                  local WDL = r.ImGui_GetWindowDrawList(ctx)

                  r.ImGui_DrawList_AddLine(WDL, x, Y_Mid, L, Y_Mid, outlineClr, LineThick)

                  r.ImGui_Indent(ctx, LineAtLeft + 2)


                  MyText(SendName, Font_Andale_Mono_14, 0xffffffff, WrapPosX, ctx)

                  local Vol = r.GetMediaTrackInfo_Value(DestTrk, 'D_VOL')
                  local ShownVol = roundUp(VAL2DB(r.GetMediaTrackInfo_Value(DestTrk, 'D_VOL')), 0.1)

                  rv, VolAdj = r.ImGui_DragDouble(ctx, '##TrackVol', 0, 0.1, min, max, '', r.ImGui_SliderFlags_NoInput())
                  if r.ImGui_IsItemClicked(ctx) then AdjDestTrkVol = DestTrk end
                  if AdjDestTrkVol then
                    out = DragVol(ctx, Vol, 'Horiz', 0.7)
                    r.SetMediaTrackInfo_Value(DestTrk, 'D_VOL', out)
                    if not r.ImGui_IsMouseDown(ctx, 0) then AdjDestTrkVol = nil end
                    if LBtnDC then r.SetMediaTrackInfo_Value(DestTrk, 'D_VOL', 1) end
                  end

                  local VolL, VolT = r.ImGui_GetItemRectMin(ctx)
                  local VolW, VolH = r.ImGui_GetItemRectSize(ctx)
                  local FaderV = Convert_Val2Fader(Vol)

                  r.ImGui_DrawList_AddRectFilled(WDL, VolL, VolT, VolL + VolW * FaderV, VolT + VolH, 0xffffff33)
                  SL()
                  r.ImGui_Text(ctx, '  ' .. ShownVol)

                  local Pan = r.GetMediaTrackInfo_Value(DestTrk, 'D_PAN')
                  local rv, TrackPan = r.ImGui_DragDouble(ctx, '##TrackPan', 0, 0.01, 0, 1, '',
                    r.ImGui_SliderFlags_NoInput())

                  if r.ImGui_IsItemClicked(ctx) then AdjustDestTrkPan = DestTrk end
                  if AdjustDestTrkPan then
                    local out = DragVol(ctx, Pan, 'Horiz', 0.01, 'Pan')
                    r.SetMediaTrackInfo_Value(DestTrk, 'D_PAN', out)
                    if not r.ImGui_IsMouseDown(ctx, 0) then AdjustDestTrkPan = nil end
                    if LBtnDC then r.SetMediaTrackInfo_Value(DestTrk, 'D_PAN', 0) end
                  end
                  local PanL, PanT = r.ImGui_GetItemRectMin(ctx)
                  local PanW, PanH = r.ImGui_GetItemRectSize(ctx)
                  local PanSZ = 5
                  local PanC = PanL + PanW / 2 + Pan * ((PanW - PanSZ) / 2)

                  r.ImGui_DrawList_AddRectFilled(WDL, PanC - PanSZ, PanT, PanC + PanSZ, PanT + PanH, 0xffffff33)
                  SL()
                  local ShownPan
                  if Pan < 0.01 and Pan > -0.01 then
                    ShownPan = 'Center'
                  elseif Pan >= 1 then
                    ShownPan = ('%.0f'):format(Pan * 100) .. '% R'
                  else
                    ShownPan = ('%.0f'):format(Pan * -100) .. '% L'
                  end

                  r.ImGui_Text(ctx, '  ' .. ShownPan)
                  SL(VolW, 30)
                  r.ImGui_Text(ctx, '              ')
                  local SliderSz = r.ImGui_GetItemRectSize(ctx)


                  -- for adding frame on the right side


                  AddSpacing(10)
                  FXBtns(DestTrk, 'Auto Size')
                  SL()
                  r.ImGui_Text(ctx, '  ')

                  local W, H = r.ImGui_GetWindowSize(ctx)
                  local x, y = r.ImGui_GetWindowPos(ctx)

                  local R = x + W - LineThick - WinPad

                  r.ImGui_DrawList_AddRect(WDL, L, y, R, y + H, outlineClr, 0, nil, LineThick / 2)
                  local BDL = r.ImGui_GetBackgroundDrawList(ctx)

                  r.ImGui_DrawList_AddRectFilled(BDL, L, y, R, y + H, 0x000000ff, 0,
                    nil)

                  local x, y = r.ImGui_GetWindowPos(ctx)
                  local w, h = r.ImGui_GetWindowSize(ctx)





                  if not r.ImGui_IsMouseHoveringRect(ctx, L, y, L + w, y + h, r.ImGui_HoveredFlags_RectOnly())
                      or r.BR_GetMouseCursorContext() ~= 'unknown'
                  then
                    if r.JS_Mouse_GetState(1) == 1 then -- get mouse click state, works even outside of ImGui window
                      OpenedDestSendWin, OpenedDestTrkWin = nil, nil
                    end
                  end
                  --r.ImGui_EndPopup(ctx)
                  r.ImGui_End(ctx)
                end





                r.ImGui_PopStyleVar(ctx)
              end
            end
          end


          ------ Repeat for Receives ------
          --[[ r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), SendClr)
          r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), SendClr1)
          r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), SendClr2) ]]
          NumRecv = r.GetTrackNumSends(Track, -1)
          for i = 0, NumRecv - 1, 1 do
            local rv, RecvName = r.GetTrackReceiveName(Track, i)
            local Bypass = r.GetTrackSendInfo_Value(Track, -1, i, 'B_MUTE')
            local BP = {}
            local RemoveRecv
            local SrcTrack = r.GetTrackSendInfo_Value(Track, -1, i, 'P_SRCTRACK')
            local HoverEyes
            local BtnSizeOffset = 0
            local Src_Hidden

            if HoverSend_Src == SrcTrack and SrcTrack and Track == HoverSend_Dest then
              RecvTrk = r.GetTrack(0, t)
              local rv, Name = r.GetTrackName(RecvTrk)
              local EndX, EndY = r.ImGui_GetCursorScreenPos(ctx)
              local L = PatchX - Patch_Thick
              r.ImGui_DrawList_AddLine(FDL, L, PatchY, L, EndY, 0xffffffff, Patch_Thick)
              HighlightSelectedItem(0xffffff22, nil, 0, L, EndY, L + 150, EndY + SendsLineHeight,
                SendsLineHeight, FXPane_W, 1, 1, getitmrect, FDL, Patch_Thick / 2)
              r.ImGui_DrawList_AddRect(FDL, L, EndY, PatchX + Send_W - 15, EndY + SendsLineHeight, 0xffffffff, nil, nil,
                Patch_Thick / 2)
            end
            -- if Send Destination Track is hidden
            if SrcTrack and r.GetMediaTrackInfo_Value(SrcTrack, 'B_SHOWINTCP') == 0 then
              Src_Hidden = true
              if r.ImGui_ImageButton(ctx, '##HideBtn', Img.Hide, HideBtnSz, HideBtnSz, nil, nil, nil, nil, nil, 0xffff00ff) then
                r.SetMediaTrackInfo_Value(SrcTrack, 'B_SHOWINTCP', 1)
                RefreshUI_HideTrack()
              end
              SL()
              BtnSizeOffset = -HideBtnSz
            end

            -- if hovering send, show Hide Track icon
            if HoverRecv == i .. TrkID and not Src_Hidden then
              if r.ImGui_ImageButton(ctx, '##HideBtn', Img.Show, HideBtnSz, HideBtnSz, nil, nil, nil, nil, nil, 0xffff00ff) then
                r.SetMediaTrackInfo_Value(SrcTrack, 'B_SHOWINTCP', 0)
                RefreshUI_HideTrack()
              end
              if r.ImGui_IsItemHovered(ctx) then
                HoverEyes = true
              end
              SL()
              BtnSizeOffset = -HideBtnSz
            end

            if RecvName ~= '' then
              r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ButtonTextAlign(), 0.1, 0.5)
              r.ImGui_Button(ctx, RecvName .. '##', BtnSize + BtnSizeOffset, SendsLineHeight)
              r.ImGui_PopStyleVar(ctx)
            end
            r.ImGui_SameLine(ctx, nil, 1)

            if r.ImGui_IsItemHovered(ctx) or HoverEyes then
              HoverRecv = i .. TrkID
            else
              if HoverRecv == i .. TrkID then
                HoverRecv = nil
              end
            end


            r.ImGui_SetNextItemWidth(ctx, SendValSize)
            if Bypass == 1 then
              BP.L, BP.T = r.ImGui_GetItemRectMin(ctx)
              BP.R, BP.B = r.ImGui_GetItemRectMax(ctx)
            end
            if r.ImGui_IsItemClicked(ctx) then
              if Mods == Shift then
                if Bypass == 0 then
                  r.SetTrackSendInfo_Value(Track, -1, i, 'B_MUTE', 1)
                else
                  r.SetTrackSendInfo_Value(Track, -1, i, 'B_MUTE', 0)
                end
              elseif Mods == Alt then
                RemoveRecv = true
              end
            end

            if rcvTrk ~= 0.0 then
              local volume = r.GetTrackSendInfo_Value(Track, -1, i, 'D_VOL')

              local ShownVol
              if volume < 0.0001 then
                ShownVol = '-inf'
              else
                ShownVol = ('%.1f'):format(VAL2DB(volume))
              end

              local CurX, CurY = r.ImGui_GetCursorScreenPos(ctx)

              r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ButtonTextAlign(), 1, 1)
              r.ImGui_Button(ctx, ShownVol .. '##Recv', SendValSize, SendsLineHeight)
              r.ImGui_PopStyleVar(ctx)
              r.ImGui_DrawList_AddImage(WDL, Img.Recv, CurX, CurY, CurX + 10, CurY + 10)

              if r.ImGui_IsItemClicked(ctx) then
                draggingRecv = 'Track' .. t .. 'Recv' .. i
                if Mods == Alt then
                  RemoveRecv = true
                end
              end

              if draggingRecv == 'Track' .. t .. 'Recv' .. i and r.ImGui_IsMouseDown(ctx, 0) then
                if Mods == 0 or Mods == Shift then
                  out = DragVol(ctx, volume, nil, 0.4)

                  r.BR_GetSetTrackSendInfo(Track, -1, i, 'D_VOL', true, out)
                end
              end
              if LBtnDC and r.ImGui_IsItemHovered(ctx) then
                r.SetTrackSendUIVol(Track, i, 1, 0)
                r.BR_GetSetTrackSendInfo(Track, -1, i, 'D_VOL', true, 1)
              end

              if not r.ImGui_IsMouseDown(ctx, 0) then
                draggingRecv = nil
              end
              if RemoveRecv then
                r.RemoveTrackSend(Track, -1, i)
              end
            end



            if Bypass == 1 then
              r.ImGui_DrawList_AddRectFilled(WDL, BP.L, BP.T, BP.L + Send_W, BP.B, 0x000000aa)
            end
          end
          --r.ImGui_PopStyleColor(ctx, 3)

          -------Empty Area below sends ------
          r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), getClr(r.ImGui_Col_ChildBg()))
          r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), getClr(r.ImGui_Col_FrameBgHovered()))
          r.ImGui_PushStyleColor(ctx, r.ImGui_Col_DragDropTarget(), 0xffffffff)


          if r.ImGui_Button(ctx, ' ##emptySend', Send_W, T.H) then
            Dur = r.ImGui_GetMouseDownDuration(ctx, 0)
            if Dur or 1 < 0.15 then
              r.ImGui_OpenPopup(ctx, 'SendWindow')
            end
          end
          r.ImGui_PopStyleColor(ctx)
          -- r.ImGui_SetNextWindowSize(ctx, 120, 180)
          if r.ImGui_BeginPopup(ctx, 'SendWindow') then
            local rv, ThisTrkName = r.GetTrackName(Track)

            if Trk[TrkID].SendFav then
              if r.ImGui_ImageButton(ctx, ThisTrkName .. '##ThisTrack' .. t, Img.Star, 10, 10) then
                Trk[TrkID].SendFav = false
              end
            else
              if r.ImGui_ImageButton(ctx, '##' .. t, Img.StarHollow, 10, 10, nil, nil, nil, nil) then
                ToggleTrackSendFav(Track, TrkID) -- currently selected track
              end
            end
            r.ImGui_SameLine(ctx)
            r.ImGui_AlignTextToFramePadding(ctx)

            r.ImGui_Text(ctx, ThisTrkName)

            TrkName = TrkName or {}
            AddSpacing(3)
            r.ImGui_Separator(ctx)
            AddSpacing(3)

            r.ImGui_Text(ctx, 'Find Tracks:')
            _, AddSend_FILTER = r.ImGui_InputText(ctx, '##input', AddSend_FILTER, r.ImGui_InputTextFlags_AutoSelectAll())
            SendWin_W = r.ImGui_GetWindowSize(ctx)

            if r.ImGui_IsWindowAppearing(ctx) then
              for t = 0, TrackCount - 1, 1 do
                local Track    = r.GetTrack(0, t)
                local rv, Name = r.GetTrackName(Track)
                TrkName[t]     = Name
              end
              r.ImGui_SetKeyboardFocusHere(ctx, -1)
            end
            r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ButtonTextAlign(), 0, 0)

            ------Starred Tracks --------
            for t = 0, TrackCount - 1, 1 do
              local SrcTrk = Track
              local Track = r.GetTrack(0, t)
              local ID = r.GetTrackGUID(Track)

              if ThisTrkName ~= TrkName[t] then
                if Trk[ID].SendFav then
                  if r.ImGui_ImageButton(ctx, '##' .. t, Img.Star, 10, 10) then
                    ToggleTrackSendFav(Track, ID)
                  end
                  r.ImGui_SameLine(ctx)
                  if r.ImGui_Button(ctx, TrkName[t] .. '##', SendWin_W - 30) then
                    r.CreateTrackSend(SrcTrk, Track)
                    r.ImGui_CloseCurrentPopup(ctx)
                  end
                end
              end
            end


            if AddSend_FILTER ~= '' and AddSend_FILTER then
              for t = 0, TrackCount - 1, 1 do
                if ThisTrkName ~= TrkName[t] then
                  local SrcTrk = Track
                  local Track = r.GetTrack(0, t)
                  local ID = r.GetTrackGUID(Track)
                  if string.lower(TrkName[t]):find(string.lower(AddSend_FILTER)) and not Trk[ID].SendFav then
                    if r.ImGui_ImageButton(ctx, '##' .. t, Img.StarHollow, 10, 10, nil, nil, nil, nil) then
                      ToggleTrackSendFav(Track, ID)
                    end
                    r.ImGui_SameLine(ctx)
                    if r.ImGui_Button(ctx, TrkName[t] .. '##', SendWin_W - 30) then
                      r.CreateTrackSend(SrcTrk, Track)
                    end
                  end
                end
              end
              --[[ elseif AddSend_FILTER == '' then
              for t = 0, TrackCount - 1, 1 do
                local Track = r.GetTrack(0, t)
                local ID = r.GetTrackGUID(Track)
                if Trk[ID].SendFav then
                  if r.ImGui_ImageButton(ctx, '##' .. t, Img.Star, 10, 10) then
                    Trk[ID].SendFav = false
                  end
                else
                  if r.ImGui_ImageButton(ctx, '##' .. t, Img.StarHollow, 10, 10, nil, nil, nil, nil) then
                    Trk[ID].SendFav = true
                  end
                end
                r.ImGui_SameLine(ctx)
                r.ImGui_Button(ctx, TrkName[t] .. '##', SendWin_W - 30)
              end ]]
            end
            r.ImGui_PopStyleVar(ctx)
            r.ImGui_EndPopup(ctx)
          end

          local function AddPreview(Name, x, y)
            if not x then x, y = r.ImGui_GetItemRectMin(ctx) end
            r.ImGui_DrawList_AddText(FDL, x + BtnSize * 0.09, y, 0xffffff88, Name)
            r.ImGui_DrawList_AddRect(FDL, x, y, x + BtnSize, y + SendsLineHeight, 0xffffff88)
            r.ImGui_DrawList_AddText(FDL, x + Send_W - 36, y, 0xffffff88, '0.0')
            r.ImGui_DrawList_AddRect(FDL, x + BtnSize, y, x + Send_W - 18, y + SendsLineHeight, 0xffffff88)
          end

          if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_AcceptNoDrawDefaultRect() + r.ImGui_DragDropFlags_SourceNoPreviewTooltip()
              ) then
            DraggingTrack = t
            DraggingTrack_Data = Track
            r.ImGui_SetDragDropPayload(ctx, 'DragSend', t)
            r.ImGui_EndDragDropSource(ctx)
            local cur = r.JS_Mouse_LoadCursor(7)
            r.JS_Mouse_SetCursor(cur)
            SendSrcPreview_X, SendSrcPreview_Y = r.ImGui_GetItemRectMin(ctx)
          end

          if r.ImGui_BeginDragDropTarget(ctx) then
            local dropped, SrcTrk = r.ImGui_AcceptDragDropPayload(ctx, 'DragSend') --
            local SrcTrk = r.GetTrack(0, DraggingTrack)
            HighlightItem(0xffffff33, WDL)
            local _, Name = r.GetTrackName(DraggingTrack_Data)
            AddPreview(Name)

            local _, Name = r.GetTrackName(Track)
            AddPreview(Name, SendSrcPreview_X, SendSrcPreview_Y)
            x, y = r.ImGui_GetItemRectMin(ctx)

            r.ImGui_DrawList_AddLine(FDL, x, y, SendSrcPreview_X, SendSrcPreview_Y, 0xffffff88, 4)

            if dropped then
              r.CreateTrackSend(SrcTrk, Track)
              DoAnimation = Track
            end
            r.ImGui_EndDragDropTarget(ctx)
          end

          if DoAnimation == Track then
            Frame = (Frame or 0) + 1
            local EndFrame = 20


            Clr = ColorChangeAnimation(Frame, EndFrame, 0xffffff88, 0xffffff00)

            r.ImGui_DrawList_AddRect(FDL, x, y, x + BtnSize, y + SendsLineHeight, Clr)
            r.ImGui_DrawList_AddRect(FDL, x + BtnSize, y, x + Send_W - 18, y + SendsLineHeight, Clr)
            local x, y = SendSrcPreview_X, SendSrcPreview_Y
            r.ImGui_DrawList_AddRect(FDL, x, y, x + BtnSize, y + SendsLineHeight, Clr)
            r.ImGui_DrawList_AddRect(FDL, x + BtnSize, y, x + Send_W - 18, y + SendsLineHeight, Clr)
            if Frame > EndFrame then
              DoAnimation = nil
              Frame = 0
            end
          end

          r.ImGui_PopStyleColor(ctx, 2)


          r.ImGui_EndChildFrame(ctx)
        end


        r.ImGui_PopFont(ctx)
      end
    end





    r.ImGui_PopStyleVar(ctx)

    r.ImGui_PopStyleVar(ctx)

    r.ImGui_End(ctx)
  end --end for Visible


  -- Linked Plugin parameters ---------

  rv, tracknumber, fxnumber, paramnumber = r.GetLastTouchedFX()

  -- if there's a focused fx
  if tracknumber then
    local trk = r.GetTrack(0, math.max(tracknumber - 1, 0))
    local FxID = r.TrackFX_GetFXGUID(trk, fxnumber)


    if FxID and FX[FxID].Link then
      Sync = FindFXFromFxGUID(FX[FxID].Link)

      local PrmV = r.TrackFX_GetParamNormalized(trk, fxnumber, paramnumber)

      if Sync then
        for i, v in ipairs(Sync.fx) do
          r.TrackFX_SetParamNormalized(Sync.trk[i], v, paramnumber, PrmV)
        end
      end
    end
  end


  if open then
    r.defer(loop)
  else --on script close
    r.ImGui_DestroyContext(ctx)
  end
end

r.defer(loop)

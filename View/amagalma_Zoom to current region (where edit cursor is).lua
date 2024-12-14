-- @description Zoom to current region (where edit cursor is)
-- @author amagalma
-- @version 1.00
-- @about Requires JS_ReaScriptAPI

local pixels=20 -- Set how many pixels of clearance you want
local A1a,A2a,A3a,A4a,A5a,A6a,A7a=reaper.GetSet_ArrangeView2, reaper.GetCursorPosition,reaper.EnumProjectMarkers,reaper.JS_Window_FindChildByID,reaper.GetLastMarkerAndCurRegion,reaper.GetMainHwnd,reaper.JS_Window_GetClientRect if A4a then local _,hfbn=A5a(0,A2a())if hfbn~=-1 then local retval,sra,HHs,ojdJ,ojS,sojJ=A3a(hfbn) local uh3HH=A4a(A6a(),0x3E8)if uh3HH then local ppp,qq2,kkk3,dxx,uuU3=A7a(uh3HH)if ppp then A1a(0,1,qq2+pixels,dxx-pixels,HHs,ojdJ) end end end end reaper.defer(function()end)

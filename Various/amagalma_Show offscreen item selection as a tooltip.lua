-- @description Show offscreen item selection as a tooltip
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about
--   Shows as a tooltip where offscreen selected items are located. (B = bottom, L = left, R = right, T = top)
--
--   - Requires SWS and Reaper v7 and above
--   - Extremely light-weight

local prev_flags, flags, _ = 0
local bottom <const> = reaper.NamedCommandLookup('_S&M_TOOLBAR_ITEM_SEL3') -- (bottom)
local left <const> = reaper.NamedCommandLookup('_S&M_TOOLBAR_ITEM_SEL0') -- (left)
local right <const> = reaper.NamedCommandLookup('_S&M_TOOLBAR_ITEM_SEL1') -- (right)
local top <const> = reaper.NamedCommandLookup('_S&M_TOOLBAR_ITEM_SEL2') -- (top)

if bottom == 0 then
  reaper.MB("SWS is required for this script to function.", "SWS not installed!", 0)
  return reaper.defer(function() end)
end -- SWS not installed

if tonumber(reaper.GetAppVersion():sub(1,1)) < 7 then
  reaper.MB("This script requires at least Reaper version 7.", "Previous Reaper version!", 0)
  return reaper.defer(function() end)
end


local function Check()
  local x, y = reaper.GetMousePosition()
  _, _, flags = reaper.GetItemEditingTime2()
  if flags ~= prev_flags then
    prev_flags = flags
    if flags ~= 0 then
      if flags == 2 then -- fade change
        local b = reaper.GetToggleCommandState( bottom ) == 1
        local t = reaper.GetToggleCommandState( top ) == 1
        if b or t then
          local msg = (t and "T" or "") .. (b and "B" or "")
          if msg ~= "" then
            reaper.TrackCtl_SetToolTip("selected offscreen items: " .. msg, x-40, y-40, true)
          end
        end
      else -- edge resizing / item move / item slip edit
        local l = reaper.GetToggleCommandState( left ) == 1
        local r = reaper.GetToggleCommandState( right ) == 1
        local b = reaper.GetToggleCommandState( bottom ) == 1
        local t = reaper.GetToggleCommandState( top ) == 1
        local msg = (l and "L" or "") .. (t and "T" or "") .. (b and "B" or "") .. (r and "R" or "")
        if msg ~= "" then
          reaper.TrackCtl_SetToolTip( "selected offscreen items: " .. msg, x-40, y-40, true )
        end
      end
    end
  end
  reaper.defer(Check)
end

local _, _, section, cmdID = reaper.get_action_context()
reaper.SetToggleCommandState( section, cmdID, 1 ) -- Set ON
reaper.RefreshToolbar2( section, cmdID )

reaper.atexit(function()
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
end)

Check()

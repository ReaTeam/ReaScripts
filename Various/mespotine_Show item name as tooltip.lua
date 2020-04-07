-- @description Show item name as tooltip
-- @author Meo-Ada Mespotine
-- @version 1.0
-- @about Shows the Item-Takename as tooltip, when hovering above it with the mouse
-- @donate https://www.paypal.me/mespotine

--[[
 * Licence: MIT
 * REAPER: 6.0+
 * Extensions: SWS required
--]]

-- Show Item-Take-Name as tooltip, when mouse hovering above an item-take
-- Meo Mespotine, 7th of April 2020 - licensed under MIT-license

if reaper.BR_Win32_GetWindowText==nil then 
  reaper.MB("Sorry, SWS 2.10.0 or higher must be installed to use this script!", "Error: SWS missing", 0) 
else
  local OldTake
  function main()
    local X,Y=reaper.GetMousePosition()
    local MediaItem, MediaItem_Take = reaper.GetItemFromPoint(X, Y, true)
    local A=reaper.GetTooltipWindow()
    local retval, A2 = reaper.BR_Win32_GetWindowText(A)
    if MediaItem_Take~=nil and (OldTake==nil or A2=="") then
      local PCM_Source=reaper.GetMediaItemTake_Source(MediaItem_Take)
      reaper.TrackCtl_SetToolTip(reaper.GetMediaSourceFileName(PCM_Source, ""), X-20, Y+30, false)
    end
    OldTake=MediaItem_Take
    reaper.defer(main)
  end
  
  main()
end

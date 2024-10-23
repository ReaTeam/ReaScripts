-- @description Set color gradient to children tracks starting from parent color
-- @author ICio
-- @version 1.4
-- @screenshot https://i.ibb.co/0VLtZXz/gradient2.gif
-- @about
--   - This script sets a color gradient to children tracks based on Parent color
--   - Gradient step is proportional to the amount of children tracks
--   - Gradient step can be changed in the script 
--   - Multiple track or folder selections are allowed
--   - Items are forced to track color
--
--   Enjoy color gradients!


------------------------------------?:^) written by 80icio thanks to Poulhoi -------------------------------------
----------------------------------------------------------------------------------------------------------


local r = reaper
local verifysws = r.APIExists( 'CF_GetSWSVersion' )------- my easy way to check if SWS extensions are installed

-----------------------------------------------------------------------------------------------------------
if  verifysws then  

local selchildren = r.NamedCommandLookup("_SWS_SELCHILDREN")
local colchildren = r.NamedCommandLookup("_SWS_COLCHILDREN")
local itemtotrkcolor = r.NamedCommandLookup("_SWS_ITEMTRKCOL")

---Gradient Step ---- positive numbers will gradient to white // negative numbers will gradient to black
local gradientstep = -15 ---- 0 = no gradient 
local coloritem = true -----if true = force to color items/takes with track color
local trktbl = {}

function getseltracktable()
  local trackCount = r.CountSelectedTracks(0)
  if trackCount ~= 0 then 
    for i = 1, trackCount, 1 do
    trktbl[i] = r.GetSelectedTrack(0, i-1)
    end
  end
end

function seltracktable()
    for i = 1, #trktbl, 1 do
    r.SetTrackSelected( trktbl[i], true )
    end
end

function main()
track = r.GetSelectedTrack(0, 0)
ColorNative = r.GetTrackColor(track)
if ColorNative ~= 0 then
r.Main_OnCommandEx(colchildren, 0, 0)
r.Main_OnCommandEx(selchildren, 0, 0)
local trackCount = r.CountSelectedTracks(0)
local gradientstep =  math.ceil((gradientstep*10)/(trackCount+1)) ----dependent on track count
 for i = 0, trackCount - 2, 1 do
    local track = r.GetSelectedTrack(0, i)
    local nexttrack = r.GetSelectedTrack(0, i+1)
    local prevColorNative = r.GetTrackColor(track)
    local prevColorR, prevColorG, prevColorB = r.ColorFromNative(prevColorNative)
    if prevColorR + gradientstep < 0 then prevColorR = 0 else prevColorR = prevColorR + gradientstep end
    if prevColorG + gradientstep < 0 then prevColorG = 0 else prevColorG = prevColorG + gradientstep end
    if prevColorB + gradientstep < 0 then prevColorB = 0 else prevColorB = prevColorB + gradientstep end
    local newColorR = math.min(prevColorR, 255)
    local newColorG = math.min(prevColorG, 255)
    local newColorB = math.min(prevColorB, 255)
    local newColorNative = r.ColorToNative(newColorR, newColorG, newColorB)
    r.SetTrackColor(nexttrack, newColorNative)
       if coloritem == true then
          r.Main_OnCommandEx(40421, 0, 0)
          r.Main_OnCommandEx(itemtotrkcolor, 0, 0)
      end
  end
  end
end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

getseltracktable()

if #trktbl ~=0 then
for c = 1, #trktbl, 1 do
r.Main_OnCommandEx(40289, 0, 0)
r.Main_OnCommandEx(40769, 0, 0)
r.SetTrackSelected( trktbl[c], true )
main()
end
r.Main_OnCommandEx(40769, 0, 0)
seltracktable()
end

r.PreventUIRefresh(-1)
r.Undo_EndBlock( "folder Color Gradient", 0)

else

reaper.ShowMessageBox( "This script requires the SWS/S&M extension.\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org.", "ERROR", 0)
end

-- @description Set size of Vertical Zoom presets
-- @author amagalma
-- @version 1.0
-- @donation https://www.paypal.me/amagalma
-- @about Sets the sizes of amagalma_Vertical Zoom preset bundle

local presets = reaper.GetExtState( "amagalma_Vertical zoom presets", "sizes" )
local pr = {}
if presets ~= "" then
  for n in presets:gmatch("%S+") do
    pr[#pr+1] = n
  end
end

::AGAIN::
local ok, retval = reaper.GetUserInputs( "Set vertical zoom preset sizes (0-40, 0 = zoomed out)", 5, 
"Preset 1 :,Preset 2 :,Preset 3 :,Preset 4 :,Preset 5 :,separator=\n",
(#pr == 5 and table.concat(pr,"\n") or "0\n10\n20\n30\n40") )

if ok then
  local p = 0
  for n in retval:gmatch("[^\n]+") do
    n = tonumber(n)
    if n and n >= 0 and n <= 40 then
      p = p + 1
      pr[p] = n
    else
      goto AGAIN
    end
  end
  if #pr ~= 5 then goto AGAIN
  else
    reaper.SetExtState( "amagalma_Vertical zoom presets", "sizes", table.concat(pr," "), true )
    return
  end
else
  return
end

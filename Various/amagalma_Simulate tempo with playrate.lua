-- @description amagalma_Simulate tempo with playrate
-- @author amagalma
-- @version 1.11
-- @about
--   # Sets the playrate to simulate a tempo entered by the user
--   - Playrate has effect as long as the script window is open
--   - Left-click the script window to start again
--   - Upon window closure, the playrate returns to 1
--   - "preserve pitch in audio items" is enabled as long as the script runs
--   - Manual changes in the playrate show the resulting tempo in the script's window

--[[
 * Changelog:
 * v1.11 (2017-09-27)
  + Manual changes in the playrate show the resulting tempo in the script's window
--]]

-------------------------------------------------------------------------------------------

local reaper, math = reaper, math
local newtempo, tempo, newplayrate, msg1, msg2, w, h, w1, h1, w2, h2, preserve
local btn_down = false

-------------------------------------------------------------------------------------------

function main()
  local LeftClick = false
  gfx.x, gfx.y = 10, 10
  gfx.drawstr(msg1)
  w2, h2 = gfx.measurestr(msg2)
  gfx.x = w - w2 + 10
  gfx.drawstr(msg2)
  local int, fra = math.modf(newtempo)
  if fra == 0 then newtempo = int end
  local wt, ht = gfx.measurestr(newtempo)
  gfx.x = w1 + 10 + (w - w2 - w1 - wt)/2
  gfx.drawstr(newtempo)  
  if gfx.mouse_cap & 1 == 1 and not btn_down then
      btn_down = true
    elseif gfx.mouse_cap & 1 == 0 and btn_down then
      btn_down = false
      LeftClick = true
    end
  if LeftClick then
    gfx.quit()
    reaper.CSurf_OnPlayRateChange(1)
    init()
  end
  local playrate = reaper.Master_GetPlayRate(0)
  if playrate ~= newplayrate then
    newplayrate = playrate
    newtempo = tempo*newplayrate
  end
  if gfx.getchar() ~= 27 and gfx.getchar() >= 0 then
    reaper.defer(main) 
  else
    reaper.CSurf_OnPlayRateChange(1)
    if preserve == 0 then
      reaper.Main_OnCommand(40671,0) -- do not preserve pitch in audio items when changing master playrate
    end
    gfx.quit()
  end
  gfx.update()
end

-------------------------------------------------------------------------------------------

preserve = reaper.GetToggleCommandStateEx(0, 40671) -- preserve pitch in audio items when changing master playrate
function init()
  tempo = reaper.Master_GetTempo()
  local ok, retvals = reaper.GetUserInputs("Simulate tempo with playrate", 1, "Enter desired tempo (bpm):", "" )
  newtempo = tonumber(retvals)
  if ok and type(newtempo) == "number" and newtempo >= 1 and newtempo <= 960 then
    newplayrate = newtempo/tempo
    if newplayrate < 0.25 then
      newplayrate = 0.25
      newtempo = tempo*newplayrate
    elseif newplayrate > 4 then
      newplayrate = 4
      newtempo = tempo*newplayrate
    end
    reaper.CSurf_OnPlayRateChange( newplayrate )
    if preserve == 0 then
      reaper.Main_OnCommand(40671,0) -- preserve pitch in audio items when changing master playrate
    end
    gfx.setfont(1, "Arial", 22)
    msg1 = "Playrate simulates a global tempo of : "
    msg2 = " bpm"
    w1, h1 = gfx.measurestr(msg1)
    local dummy = "000.00"
    w, h = gfx.measurestr(msg1..dummy..msg2)
    gfx.init("Simulate tempo with playrate" , w+20, h+20, false, 0, 0)
    main()
  end
end

-------------------------------------------------------------------------------------------

init()

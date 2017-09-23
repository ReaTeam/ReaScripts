-- @description amagalma_Simulate tempo with playrate
-- @author amagalma
-- @version 1.0
-- @about
--   # Sets the playrate to simulate a tempo entered by the user
--   - Playrate has effect as long as the script window is open
--   - Upon window closure, the playrate returns to 1
--   - "preserve pitch in audio items" is enabled as long as the script runs

-------------------------------------------------------------------------------------------

local reaper = reaper
local newtempo, newplayrate, msg, w, h, preserve

-------------------------------------------------------------------------------------------

function main()
  gfx.x, gfx.y = 10, 10
  gfx.drawstr(msg)  
  gfx.update()
  if gfx.getchar() >= 0 and gfx.getchar() ~= 27 and reaper.Master_GetPlayRate(0) == newplayrate then
    reaper.defer(main) 
  elseif reaper.Master_GetPlayRate(0) ~= newplayrate then
    if preserve == 0 then
      reaper.Main_OnCommand(40671,0) -- do not preserve pitch in audio items when changing master playrate
    end
    gfx.quit()
  elseif gfx.getchar() < 0 or gfx.getchar() == 27 then
    reaper.CSurf_OnPlayRateChange(1)
    if preserve == 0 then
      reaper.Main_OnCommand(40671,0) -- do not preserve pitch in audio items when changing master playrate
    end
    gfx.quit()
  end
end

-------------------------------------------------------------------------------------------

preserve = reaper.GetToggleCommandStateEx(0, 40671) -- preserve pitch in audio items when changing master playrate
local tempo = reaper.Master_GetTempo()
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
  msg = "Playrate simulates a global tempo of "..newtempo.." bpm"
  w, h = gfx.measurestr(msg)
  gfx.init("Simulate tempo with playrate" , w+20, h+20, false, 0, 0)
  main()
end

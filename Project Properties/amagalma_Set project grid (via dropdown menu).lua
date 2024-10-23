-- @description Set project grid (via dropdown menu)
-- @author amagalma
-- @version 1.10
-- @changelog
--   - Swapped JS_ReaScriptAPI dependency for SWS
--   - Added Frame, Measure and Metronome options
-- @link https://forum.cockos.com/showthread.php?t=239556
-- @donation https://www.paypal.com/paypalme/amagalma
-- @about
--   # Set project grid (via dropdown menu)
--
--   - Displays a dropdown menu at mouse cursor position where you can choose a grid setting
--   - Requires SWS Extensions


local m =
{
  {1, "1/1    -  whole note"},
  {-1/2, ">1/2    -  half note"},
  {1/2, "1/2  -  half note"},
  {1/3, "1/3  -  half note triplet"},
  {3/4, "<3/4  -  dotted half note"},
  {-1/4, ">1/4    -  quarter note"},
  {1/4, "1/4  -  quarter note"},
  {1/6, "1/6  -  quarter note triplet"},
  {3/8, "<3/8  -  dotted quarter note"},
  {-1/8, ">1/8    -  eighth note"},
  {1/8, "1/8    -  eighth note"},
  {1/12, "1/12  -  eighth note triplet"},
  {3/16, "<3/16  -  dotted eighth note"},
  {-1/16, ">1/16  -  sixteenth note"},
  {1/16, "1/16  -  sixteenth note"},
  {1/24, "1/24  -  sixteenth note triplet"},
  {3/32, "<3/32  -  dotted sixteenth note"},
  {-1/32, ">1/32  -  thirty-second note"},
  {1/32, "1/32  -  thirty-second note"},
  {1/48, "1/48  -  thirty-second note triplet"},
  {3/64, "<3/64  -  dotted thirty-second note"},
  {-1/64, ">1/64  -  sixty-fourth note"},
  {1/64, "1/64    -  sixty-fourth note"},
  {1/96, "1/96    -  sixty-fourth note triplet"},
  {3/128, "<3/128  -  dotted sixty-fourth note"},
}

local projgridframe = reaper.SNM_GetIntConfigVar( "projgridframe", -8888 )
local metronome_grid = projgridframe & 256 == 256
local frame_grid = reaper.GetToggleCommandState( 41885 ) == 1
local measure_grid = reaper.GetToggleCommandState( 40725 ) == 1
local other_grid_not_set = not (metronome_grid or frame_grid or measure_grid)

local m2 = {
  (frame_grid and "!" or "") .. "Frame",
  (measure_grid and "!" or "") .. "Measure",
  (metronome_grid and "!" or "") .. "Metronome"
}


local _, division = reaper.GetSetProjectGrid( 0, 0, 0, 0, 0 )
-- check if Use the same grid division in arrange view and MIDI editor
local mode = reaper.GetToggleCommandState( 42010 )
mode = mode == 0 and "arrange" or "project"

local menu = "#Set " .. mode .. " grid to :||"
for i = 1, #m do
  local togglestate
  if m[i][1] < 0 then
    local d = -m[i][1]
    if other_grid_not_set and (d * 1.5 == division or division == d * (2/3) or d == division) then
      togglestate = "!"
    else
      togglestate = ""
    end
  else
    togglestate = (other_grid_not_set and m[i][1] == division) and "!" or ""
  end
  menu = menu .. togglestate .. m[i][2] .. "|"
end
menu = menu .. table.concat(m2, "|")


gfx.x, gfx.y = gfx.mouse_x-40, gfx.mouse_y-40
local selection = gfx.showmenu(menu)
gfx.quit()


if selection > 0 then
  if selection == 21 then
    reaper.Main_OnCommand(40904, 0) -- Set framerate grid
  elseif selection == 22 then
    reaper.Main_OnCommand(40923, 0) -- Set measure grid
  elseif selection == 23 then
    reaper.SNM_SetIntConfigVar( "projgridframe", (projgridframe & ~(1 | (1 << 6))) | (1 << 8) )
  else
    if selection < 3 then
      selection = 1
    else
      selection = selection + math.floor(selection/3) - 1
    end
    if not other_grid_not_set then
      reaper.SNM_SetIntConfigVar( "projgridframe", projgridframe & (~(1 | (1 << 6) | (1 << 8))) )
    end
    reaper.SetProjectGrid( 0, m[selection][1] )
  end
end
reaper.defer(function() end)

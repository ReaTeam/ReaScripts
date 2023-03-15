-- @description Grid Settings button
-- @author amagalma
-- @version 1.03
-- @changelog Display correctly dotted and triplet when changing grid via actions
-- @provides
--   . > amagalma_Grid Settings button/amagalma_Grid Settings button.lua
--   amagalma_Grid Settings button/amagalma_triplet.png
--   amagalma_Grid Settings button/amagalma_sixtyfourth_note.png
--   amagalma_Grid Settings button/amagalma_thirtysecond_note.png
--   amagalma_Grid Settings button/amagalma_sixteenth_note.png
--   amagalma_Grid Settings button/amagalma_dot.png
--   amagalma_Grid Settings button/amagalma_half_note.png
--   amagalma_Grid Settings button/amagalma_whole_note.png
--   amagalma_Grid Settings button/amagalma_eighth_note.png
--   amagalma_Grid Settings button/amagalma_quarter_note.png
--   amagalma_Grid Settings button/amagalma_grid_button.png
-- @screenshot https://i.ibb.co/C5Mrc4G/amagalma-Grid-Settings-button.gif
-- @donation https://www.paypal.me/amagalma
-- @link https://forum.cockos.com/showthread.php?t=241918
-- @about
--   Displays a window/button with the active grid settings.
--
--   - You can change settings either using the mousewheel or by left-clicking to show a menu.
--   - When menu is shown, you can see the setting of "Use the same grid division in arrange view and MIDI editor" ("arrange" or "project")
--   - Right click to dock/undock script
--   - Drag window sides to change button size
--   - Script remembers last position, size and dock settings
--   - Setting to brighten/darken the button inside the script
--   - Requires SWS Extension


-- USER Setting ------------------------------------------
local darken = 0.18-- Dim colors (0-0.55, default: 0.18)
----------------------------------------------------------


if reaper.GetToggleCommandState( reaper.NamedCommandLookup( "_SWS_AWTOGGLEDOTTED" ) ) == -1 then
  reaper.MB("This script requires SWS Extension installed!", "Aborted loading script...", 0)
  return
end

local notes = {
  [1] = "amagalma_whole_note.png",
  [1/2] = "amagalma_half_note.png",
  [1/4] = "amagalma_quarter_note.png",
  [1/8] = "amagalma_eighth_note.png",
  [1/16] = "amagalma_sixteenth_note.png",
  [1/32] = "amagalma_thirtysecond_note.png",
  [1/64] = "amagalma_sixtyfourth_note.png"
}

local m = {
  {1, "m.     -  Measure"},
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


local dotted, triplet, grid, measure, division
local function get_grid()
  measure = reaper.GetToggleCommandState( 40725 )
  if measure == 0 then
    grid = ({reaper.GetSetProjectGrid( 0, false, 0, 0, 0 )})[2]
    division = grid
    if not notes[grid] then
      dotted = reaper.GetToggleCommandState( reaper.NamedCommandLookup( "_SWS_AWTOGGLEDOTTED" ) ) == 1
      triplet = reaper.GetToggleCommandState( reaper.NamedCommandLookup( "_SWS_AWTOGGLETRIPLET" ) ) == 1
      grid = triplet and grid * 1.5 or (dotted and grid * 2/3)
      if not notes[grid] then grid = -1 end
    else
      dotted, triplet = nil, nil
    end
  else
    grid = 0
  end
end

get_grid()
local old_division = division

local function Str2Num(str, def)
  if str == "" then
    return def
  else
    return tonumber(str)
  end
end

gfx.setfont(1, "Arial", string.find(reaper.GetOS(), "OSX") and 13 or 18)
local size = reaper.GetExtState("amagalma_Grid Settings", "size")
local show_x = reaper.GetExtState( "amagalma_Grid Settings", "x" )
local show_y = reaper.GetExtState( "amagalma_Grid Settings", "y" )
local dock = reaper.GetExtState( "amagalma_Grid Settings", "dock" )
local cx, cy
dock = Str2Num(dock, 0)
size = Str2Num(size, 50)
local size_w = size*1.8 -- (9/5)
show_x = Str2Num(show_x, 400)
show_y = Str2Num(show_y, 400)
darken = darken > 0.55 and 0.55 or (darken < 0 and 0 or darken)
gfx.init("Current grid setting", size_w, size, dock, show_x, show_y)
local _, path, section, cmdID = reaper.get_action_context()
reaper.SetToggleCommandState( section, cmdID, 1 ) -- Set ON
reaper.RefreshToolbar2( section, cmdID )
path = path:match(".+[/\\]")
gfx.loadimg( 1, path .. "amagalma_triplet.png" )
gfx.loadimg( 2, path .. "amagalma_dot.png" )
gfx.loadimg( 3, path .. "amagalma_grid_button.png")
local oldw, oldh = gfx.w, gfx.h
local scw, sch = 90, 50


local function Sc(percentage, middle)
  if middle then
    return math.floor((percentage + 0.55)*size + 0.5)
  else
    return math.floor(percentage*size + 0.5)
  end
end

local function draw_grid()
  gfx.blit(3, 1, 0, 0, 0, 70, 50, 0, 0, size_w, size)
  gfx.set(0, 0, 0)
  gfx.rect(0,0,size_w, size, 0 )
  if measure == 1 then
    gfx.set(1,1,1)
    local str_w, str_h = gfx.measurestr( "Measure" )
    gfx.x = (size_w - str_w) / 2
    gfx.y = (size - str_h) / 2
    gfx.drawstr( "Measure" )
  elseif grid == -1 then
    gfx.set(1,1,1)
    local str_w, str_h = gfx.measurestr( "unknown" )
    gfx.x = (size_w - str_w) / 2
    gfx.y = (size - str_h) / 2
    gfx.drawstr( "unknown" )
  else
    if dotted then
      local w, h = gfx.getimgdim( 2 )
      local destx = grid < 1/8 and Sc(0.69, not triplet) or Sc(0.58, not triplet)
      gfx.blit(2, 1, 0, 0, 0, w, h, destx, Sc(0.74), (size_w/scw)*w, (size_w/scw)*h)
    elseif triplet then
      local w, h = gfx.getimgdim( 1 )
      gfx.blit(1, 1, 0, 0, 0, w, h, Sc(0.69), Sc(0.34), (size_w/scw)*w, (size_w/scw)*h)
    end
    gfx.loadimg( 0, path .. notes[grid] )
    local w, h = gfx.getimgdim( 0 )
    local destx = Sc(0.16, not triplet)
    local desty = Sc(0.1)
    if grid < 1/2 then
      if grid == 1/16 then
        desty = Sc(0.14)
      elseif grid == 1/32 then
        desty = Sc(0.078)
      elseif grid == 1/64 then
        desty = Sc(0.09)
      end
    elseif grid == 1/2 then
      destx = Sc(0.14, not triplet)
    elseif grid == 1 then
      destx = Sc(0.125, not triplet)
      desty = Sc(0.66)
    end
    gfx.blit(0, 1, 0, 0, 0, w, h, destx, desty, (size_w/scw)*w, (size_w/scw)*h)
  end
  gfx.set(0,0,0,darken)
  gfx.rect(0,0,size_w, size, 1)
end


draw_grid()

function Exit()
  local dock, x, y = gfx.dock(-1, 0, 0)
  reaper.SetExtState("amagalma_Grid Settings", "x", x, 1)
  reaper.SetExtState("amagalma_Grid Settings", "y", y, 1)
  reaper.SetExtState("amagalma_Grid Settings", "size", size, 1)
  reaper.SetExtState("amagalma_Grid Settings", "dock", dock, 1)
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
end

reaper.atexit(Exit)

local time = reaper.time_precise()
function main()
  if gfx.mouse_cap & 1 == 1 then
    -- amagalma_Set project grid (via dropdown menu) equivalent code
    local division = ({reaper.GetSetProjectGrid( 0, 0, 0, 0, 0 )})[2]
    local mode = reaper.GetToggleCommandState( 42010 ) == 0 and "arrange" or "project"
    local menu = "#Set " .. mode .. " grid to :||"
    for i = 1, #m do
      local togglestate = ""
      if i == 1 and measure == 1 then
        togglestate = "!"
      elseif measure == 0 and i > 1 then
        if m[i][1] < 0 then
          local d = -m[i][1]
          if d * 1.5 == division or division == d * (2/3) or d == division then
            togglestate = "!"
          end
        else
          togglestate = m[i][1] == division and "!" or ""
        end
      end
      menu = menu .. togglestate .. m[i][2] .. "|"
    end
    gfx.x, gfx.y = gfx.mouse_x-40, gfx.mouse_y-40
    local selection = gfx.showmenu(menu)
    if selection > 0 then
      if selection < 3 and measure == 0 then
        reaper.Main_OnCommand(40923, 0) -- Set measure grid
      else
        if measure == 1 then
          reaper.Main_OnCommand(40725, 0) -- Toggle measure grid
        end
        if selection == 3 then
          selection = 2
        else
          selection = selection + math.floor((selection-4)/3)
        end
        reaper.SetProjectGrid( 0, m[selection][1] )
      end
      get_grid()
      draw_grid()
      old_division = division
    end
  elseif gfx.mouse_cap & 2 == 2 then
    dock = gfx.dock(-1)
    local want_dock = gfx.showmenu((dock & 1 == 1 and "#Undock script?" or "#Dock script?") .. "||Yes|Cancel")
    if want_dock == 2 then
      dock = gfx.dock(dock ~ 1,show_x,show_y,size_w,size)
      get_grid()
      draw_grid()
      old_division = division
    end
  end
  if gfx.mouse_wheel ~= 0 then
    local _, division, swingmode, swingamt = reaper.GetSetProjectGrid( 0, 0, 0, 0, 0 )
    local change
    if grid == -1 then
      reaper.GetSetProjectGrid( 0, 1, 0.25, swingmode, swingamt )
      get_grid()
      draw_grid()
      old_division = division
    elseif grid == 1 and gfx.mouse_wheel > 0 then
      reaper.Main_OnCommand(40923, 0) -- Set measure grid
      get_grid()
      draw_grid()
      old_division = division
    else
      if grid == 0 then
        if gfx.mouse_wheel < 0 then
          change = 1
        end
      elseif grid < 1 and gfx.mouse_wheel > 0 then
        change = division >= 1 and 1 or division * 2
      elseif grid > 1/64 and gfx.mouse_wheel < 0 then
        change = division <= 1/64 and 1/64 or division / 2
      end
      if change then
        if measure == 1 then
          reaper.Main_OnCommand(40725, 0) -- Toggle measure grid
        end
        reaper.GetSetProjectGrid( 0, 1, change, swingmode, swingamt )
        get_grid()
        draw_grid()
        old_division = division
      end
    end
    gfx.mouse_wheel = 0
  end
  local now = reaper.time_precise()
  if now - time > 0.4 then
    time = now
    get_grid()
    dock, cx, cy = gfx.dock(-1, 0, 0, 0, 0 )
    if gfx.w ~= oldw or gfx.h ~= oldh then
      size = gfx.w ~= oldw and 5/9*gfx.w or gfx.h
      size = size > 150 and 150 or (size < 50 and 50 or size)
      size_w = size*1.8
      gfx.quit()
      gfx.init("Current grid setting",size_w,size,dock,cx,cy)
      draw_grid()
      oldw, oldh = gfx.w, gfx.h
    end
    if division ~= old_division then
      draw_grid()
      old_division = division
    end
  end
  reaper.defer(main)
end

main()

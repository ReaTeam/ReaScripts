-- @description GFX Input Inspector
-- @author cfillion
-- @version 2.0
-- @changelog
--   Previously named "GFX Keyboard Inspector"
--
--   - Added mouse button analysis.
--   - Display values in hexadecimal
--   - Enhance data presentation

last_char = 0
ismacos = reaper.GetOS():find('OSX') ~= nil

function modifiers()
  local mods = {}

  if gfx.mouse_cap & 4 ~= 0 then
    if ismacos then
      table.insert(mods, 'Cmd')
    else
      table.insert(mods, 'Ctrl')
    end
  end
  if ismacos and gfx.mouse_cap & 32 ~= 0 then
    table.insert(mods, 'Ctrl')
  end
  if gfx.mouse_cap & 16 ~= 0 then
    if ismacos then
      table.insert(mods, 'Opt')
    else
      table.insert(mods, 'Alt')
    end
  end
  if gfx.mouse_cap & 8 ~= 0 then
   table.insert(mods, 'Shift')
  end

  return table.concat(mods, '+')
end

function buttons()
  local btns = {}

  if gfx.mouse_cap & 1 ~= 0 then
   table.insert(btns, 'left')
  end
  if gfx.mouse_cap & 64 ~= 0 then
   table.insert(btns, 'middle')
  end
  if gfx.mouse_cap & 2 ~= 0 then
   table.insert(btns, 'right')
  end

  return table.concat(btns, '+')
end

function drawline(str)
  gfx.x = 10
  gfx.drawstr(str)
  nl()
end

function nl()
  gfx.y = gfx.y + 15
end

function loop()
  local char = gfx.getchar()

  if char < 0 then
    gfx.quit()
    return
  elseif char > 0 then
    last_char = char
  end

  gfx.y = 10

  drawline(string.format("gfx.mouse_cap => 0x%02x (%d)",
    gfx.mouse_cap, gfx.mouse_cap))
  drawline(string.format("    modifiers => %s",   modifiers()))
  drawline(string.format("      buttons => %s",   buttons()))
  nl()
  drawline(string.format("gfx.getchar() => 0x%08x", last_char))

  gfx.update()
  reaper.defer(loop)
end

gfx.init("GFX Input Inspector", 320, 100)
reaper.defer(loop)

-- @description GFX Keyboard Inspector
-- @author cfillion
-- @version 1.0

function iswindows()
  return reaper.GetOS():find('Win') ~= nil
end

function ismacos()
  return reaper.GetOS():find('OSX') ~= nil
end

function modifiers()
  local mods = {}

  if gfx.mouse_cap & 4 ~= 0 then
    if ismacos() then
      table.insert(mods, 'Cmd')
    else
      table.insert(mods, 'Ctrl')
    end
  end
  if ismacos() and gfx.mouse_cap & 32 ~= 0 then
    table.insert(mods, 'Ctrl')
  end
  if gfx.mouse_cap & 16 ~= 0 then
    if ismacos() then
      table.insert(mods, 'Opt')
    else
      table.insert(mods, 'Alt')
    end
  end
  if gfx.mouse_cap & 8 ~= 0 then
   table.insert(mods, 'Shift')
  end

  if #mods == 0 then
    return 'No modifiers!'
  else
    return table.concat(mods, '+')
  end
end

function loop()
  local char = gfx.getchar()

  if char < 0 then
    gfx.quit()
    return
  elseif char > 0 then
    last_char = char
  end

  gfx.x, gfx.y = 10, 10
  gfx.drawstr(modifiers())

  gfx.x, gfx.y = 10, 25
  gfx.drawstr(string.format("%d %d", gfx.mouse_cap, last_char or 0))

  gfx.update()
  reaper.defer(loop)
end

gfx.init("GFX KB Inspector", 200, 50)
reaper.defer(loop)

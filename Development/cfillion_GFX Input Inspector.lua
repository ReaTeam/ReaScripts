-- @description GFX input inspector
-- @author cfillion
-- @version 2.1
-- @changelog Add REAPER 6.65's gfx.char second return value

local last_char, last_codepoint, last_printchar = 0, 0, ''
local ismacos = reaper.GetOS():find('OSX') ~= nil

local function modifiers()
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

local function buttons()
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

local function nl()
  gfx.y = gfx.y + 15
end

local function drawline(str)
  gfx.x = 10
  gfx.drawstr(str)
  nl()
end

local function loop()
  local char, codepoint = gfx.getchar()

  if char < 0 then
    gfx.quit()
    return
  end

  if char > 0 then
    last_char = char
  end
  if codepoint and codepoint > 0 then
    last_codepoint = codepoint
    last_printchar = utf8.char(codepoint)
  end

  gfx.y = 10

  drawline(('gfx.mouse_cap => 0x%02x (%d)'):format(gfx.mouse_cap, gfx.mouse_cap))
  drawline(('    modifiers => %s'):format(modifiers()))
  drawline(('      buttons => %s'):format(buttons()))
  nl()
  drawline(('gfx.getchar() => 0x%08x'):format(last_char))
  drawline(("              => 0x%08x ('%s')"):format(last_codepoint, last_printchar))

  gfx.update()
  reaper.defer(loop)
end

gfx.init('GFX input inspector', 320, 110)
reaper.defer(loop)

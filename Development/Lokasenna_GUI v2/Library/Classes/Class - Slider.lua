-- NoIndex: true

--[[	Lokasenna_GUI - Slider class

    For documentation, see this class's page on the project wiki:
    https://github.com/jalovatt/Lokasenna_GUI/wiki/Slider

    Creation parameters:
  name, z, x, y, w, caption, min, max, defaults[, inc, dir]

]]--


if not GUI then
  reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
  missing_lib = true
  return 0
end

GUI.Slider = GUI.Element:new()

function GUI.Slider:new(name, z, x, y, w, caption, min, max, defaults, inc, dir)

  local Slider = (not x and type(z) == "table") and z or {}

  Slider.name = name
  Slider.type = "Slider"

  Slider.z = Slider.z or z

  Slider.x = Slider.x or x
    Slider.y = Slider.y or y

  Slider.dir = Slider.dir or dir or "h"

    Slider.w, Slider.h = table.unpack(Slider.dir ~= "v"
                        and {Slider.w or w, 8}
                        or  {8, Slider.w or w} )

  Slider.caption = Slider.caption or caption
  Slider.bg = Slider.bg or "wnd_bg"

  Slider.font_a = Slider.font_a or 3
  Slider.font_b = Slider.font_b or 4

  Slider.col_txt = Slider.col_txt or "txt"
  Slider.col_hnd = Slider.col_hnd or "elm_frame"
  Slider.col_fill = Slider.col_fill or "elm_fill"

  if Slider.show_handles == nil then
      Slider.show_handles = true
  end
  if Slider.show_values == nil then
      Slider.show_values = true
  end

  Slider.cap_x = Slider.cap_x or 0
  Slider.cap_y = Slider.cap_y or 0

  local min = Slider.min or min
  local max = Slider.max or max

  if min > max then
      min, max = max, min
  elseif min == max then
      max = max + 1
  end

  if Slider.dir == "v" then
    min, max = max, min
  end

  Slider.align_values = Slider.align_values or 0

  Slider.min, Slider.max = min, max
  Slider.inc = Slider.inc or inc or 1

  function Slider:formatretval(val)

      local decimal = tonumber(string.match(val, "%.(.*)") or 0)
      local places = decimal ~= 0 and string.len( decimal) or 0
      return string.format("%." .. places .. "f", val)

  end

  Slider.defaults = Slider.defaults or defaults

  -- If the user only asked for one handle
  if type(Slider.defaults) == "number" then Slider.defaults = {Slider.defaults} end

  function Slider:init_handles()

    self.steps = math.abs(self.max - self.min) / self.inc

      -- Make sure the handles are all valid
      for i = 1, #self.defaults do
          self.defaults[i] = math.floor( GUI.clamp(0, tonumber(self.defaults[i]), self.steps) )
      end

      self.handles = {}
      local step
      for i = 1, #self.defaults do

          step = self.defaults[i]

          self.handles[i] = {}
          self.handles[i].default = (self.dir ~= "v" and step or (self.steps - step))
          self.handles[i].curstep = step
          self.handles[i].curval = step / self.steps
          self.handles[i].retval = self:formatretval( ((self.max - self.min) / self.steps)
                                                      * step + self.min)

      end

  end

  Slider:init_handles(defaults)

  GUI.redraw_z[Slider.z] = true

  setmetatable(Slider, self)
  self.__index = self
  return Slider

end


function GUI.Slider:init()

  self.buffs = self.buffs or GUI.GetBuffer(2)

    -- In case we were given a new set of handles without involving GUI.Val
    if not self.handles[1].default then self:init_handles() end

    local w, h = self.w, self.h

    -- Track
    gfx.dest = self.buffs[1]
    gfx.setimgdim(self.buffs[1], -1, -1)
    gfx.setimgdim(self.buffs[1], w + 4, h + 4)

  GUI.color("elm_bg")
  GUI.roundrect(2, 2, w, h, 4, 1, 1)
  GUI.color("elm_outline")
  GUI.roundrect(2, 2, w, h, 4, 1, 0)


    -- Handle
  local hw, hh = table.unpack(self.dir == "h" and {8, 16} or {16, 8})

  gfx.dest = self.buffs[2]
  gfx.setimgdim(self.buffs[2], -1, -1)
  gfx.setimgdim(self.buffs[2], 2 * hw + 4, hh + 2)

  GUI.color(self.col_hnd)
  GUI.roundrect(1, 1, hw, hh, 2, 1, 1)
  GUI.color("elm_outline")
  GUI.roundrect(1, 1, hw, hh, 2, 1, 0)

  local r, g, b, a = table.unpack(GUI.colors["shadow"])
  gfx.set(r, g, b, 1)
  GUI.roundrect(hw + 2, 1, hw, hh, 2, 1, 1)
  gfx.muladdrect(hw + 2, 1, hw + 2, hh + 2, 1, 1, 1, a, 0, 0, 0, 0 )

end


function GUI.Slider:ondelete()

  GUI.FreeBuffer(self.buffs)

end


function GUI.Slider:draw()

    local x, y, w, h = self.x, self.y, self.w, self.h

  -- Draw track
    gfx.blit(self.buffs[1], 1, 0, 1, 1, w + 2, h + 2, x - 1, y - 1)

    -- To avoid a LOT of copy/pasting for vertical sliders, we can
    -- just swap x-y and w-h to effectively "rotate" all of the math
    -- 90 degrees. 'horz' is here to help out in a few situations where
    -- the values need to be swapped back for drawing stuff.

    self. horz = self.dir ~= "v"
    if not self.horz then x, y, w, h = y, x, h, w end

    -- Limit everything to be drawn within the square part of the track
    x, w = x + 4, w - 8

    -- Size of the handle
    self.handle_w, self.handle_h = 8, h * 2
    local inc = w / self.steps
    local handle_y = y + (h - self.handle_h) / 2

    -- Get the handles' coordinates and the ends of the fill bar
    local min, max = self:updatehandlecoords(x, handle_y, inc)

    self:drawfill(x, y, h, min, max, inc)

    self:drawsliders()
    if self.caption and self.caption ~= "" then self:drawcaption() end

end


function GUI.Slider:val(newvals)

  if newvals then

    if type(newvals) == "number" then newvals = {newvals} end

    for i = 1, #self.handles do

            self:setcurstep(i, newvals[i])

    end

    self:redraw()

  else

    local ret = {}
    for i = 1, #self.handles do
      --[[
      table.insert(ret, (self.dir ~= "v" 	and (self.handles[i].curstep + self.min)
                        or	(self.steps - self.handles[i].curstep)))
      ]]--
            table.insert(ret, tonumber(self.handles[i].retval))

    end

    if #ret == 1 then
      return ret[1]
    else
      table.sort(ret)
      return ret
    end

  end

end




------------------------------------
-------- Input methods -------------
------------------------------------


function GUI.Slider:onmousedown()

  -- Snap the nearest slider to the nearest value

  local mouse_val = self.dir == "h"
          and (GUI.mouse.x - self.x) / self.w
          or  (GUI.mouse.y - self.y) / self.h

    self.cur_handle = self:getnearesthandle(mouse_val)

  self:setcurval(self.cur_handle, GUI.clamp(mouse_val, 0, 1) )

  self:redraw()

end


function GUI.Slider:ondrag()

  local mouse_val, n, ln = table.unpack(self.dir == "h"
          and {(GUI.mouse.x - self.x) / self.w, GUI.mouse.x, GUI.mouse.lx}
          or  {(GUI.mouse.y - self.y) / self.h, GUI.mouse.y, GUI.mouse.ly}
  )

  local cur = self.cur_handle or 1

  -- Ctrl?
  local ctrl = GUI.mouse.cap&4==4

  -- A multiplier for how fast the slider should move. Higher values = slower
  --						Ctrl							Normal
  local adj = ctrl and math.max(1200, (8*self.steps)) or 150
  local adj_scale = (self.dir == "h" and self.w or self.h) / 150
  adj = adj * adj_scale

    self:setcurval(cur, GUI.clamp( self.handles[cur].curval + ((n - ln) / adj) , 0, 1 ) )

  self:redraw()

end


function GUI.Slider:onwheel()

  local mouse_val = self.dir == "h"
          and (GUI.mouse.x - self.x) / self.w
          or  (GUI.mouse.y - self.y) / self.h

  local inc = GUI.round( self.dir == "h" and GUI.mouse.inc
                      or -GUI.mouse.inc )

    local cur = self:getnearesthandle(mouse_val)

  local ctrl = GUI.mouse.cap&4==4

  -- How many steps per wheel-step
  local fine = 1
  local coarse = math.max( GUI.round(self.steps / 30), 1)

  local adj = ctrl and fine or coarse

    self:setcurval(cur, GUI.clamp( self.handles[cur].curval + (inc * adj / self.steps) , 0, 1) )

  self:redraw()

end


function GUI.Slider:ondoubleclick()

    -- Ctrl+click - Only reset the closest slider to the mouse
  if GUI.mouse.cap & 4 == 4 then

    local mouse_val = (GUI.mouse.x - self.x) / self.w
    local small_diff, small_idx
    for i = 1, #self.handles do

      local diff = math.abs( self.handles[i].curval - mouse_val )
      if not small_diff or diff < small_diff then
        small_diff = diff
        small_idx = i
      end

    end

        self:setcurstep(small_idx, self.handles[small_idx].default)

    -- Reset all sliders
  else

    for i = 1, #self.handles do

            self:setcurstep(i, self.handles[i].default)

    end

  end

  self:redraw()

end




------------------------------------
-------- Drawing helpers -----------
------------------------------------


function GUI.Slider:updatehandlecoords(x, handle_y, inc)

    local min, max

    for i = 1, #self.handles do

        local center = x + inc * self.handles[i].curstep
        self.handles[i].x, self.handles[i].y = center - (self.handle_w / 2), handle_y

        if not min or center < min then min = center end
        if not max or center > max then max = center end

    end

    return min, max

end


function GUI.Slider:drawfill(x, y, h, min, max, inc)

    -- Get the color
  if (#self.handles > 1)
    or self.handles[1].curstep ~= self.handles[1].default then

        self:setfill()

    end

    -- Cap for the fill bar
    if #self.handles == 1 then
        min = x + inc * self.handles[1].default

        _ = self.horz and gfx.circle(min, y + (h / 2), h / 2 - 1, 1, 1)
                      or  gfx.circle(y + (h / 2), min, h / 2 - 1, 1, 1)

    end

    if min > max then min, max = max, min end

    _ = self.horz and gfx.rect(min, y + 1, max - min, h - 1, 1)
                  or  gfx.rect(y + 1, min, h - 1, max - min, 1)

end


function GUI.Slider:setfill()

    -- If the user has given us two colors to make a gradient with
    if self.col_fill_a and #self.handles == 1 then

        -- Make a gradient,
        local col_a = GUI.colors[self.col_fill_a]
        local col_b = GUI.colors[self.col_fill_b]
        local grad_step = self.handles[1].curstep / self.steps

        local r, g, b, a = GUI.gradient(col_a, col_b, grad_step)

        gfx.set(r, g, b, a)

    else
        GUI.color(self.col_fill)
    end

end


function GUI.Slider:drawsliders()

    GUI.color(self.col_txt)
    GUI.font(self.font_b)

    -- Drawing them in reverse order so overlaps match the shadow direction
    for i = #self.handles, 1, -1 do

        local handle_x, handle_y = GUI.round(self.handles[i].x) - 1, GUI.round(self.handles[i].y) - 1

        if self.show_values then

            local x = handle_x
            local y = self.y + self.h + self.h

            if self.horz then
                self:drawslidervalue(handle_x + self.handle_w/2, handle_y + self.handle_h + 4, i)
            else
                self:drawslidervalue(handle_y + self.handle_h + self.handle_h, handle_x, i)
            end

        end

        if self.show_handles then

            if self.horz then
                self:drawsliderhandle(handle_x, handle_y, self.handle_w, self.handle_h)
            else
                self:drawsliderhandle(handle_y, handle_x, self.handle_h, self.handle_w)
            end

        end

    end

end


function GUI.Slider:drawslidervalue(x, y, sldr)

    local output = self.handles[sldr].retval

    if self.output then
        local t = type(self.output)

        if t == "string" or t == "number" then
            output = self.output
        elseif t == "table" then
            output = self.output[output]
        elseif t == "function" then
            output = self.output(output)
        end
    end

    gfx.x, gfx.y = x, y

    GUI.text_bg(output, self.bg, self.align_values + 256)
    gfx.drawstr(output, self.align_values + 256, gfx.x, gfx.y)

end


function GUI.Slider:drawsliderhandle(hx, hy, hw, hh)

    for j = 1, GUI.shadow_dist do

        gfx.blit(self.buffs[2], 1, 0, hw + 2, 0, hw + 2, hh + 2, hx + j, hy + j)

    end

    --gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs] )

    gfx.blit(self.buffs[2], 1, 0, 0, 0, hw + 2, hh + 2, hx, hy)

end


function GUI.Slider:drawcaption()

  GUI.font(self.font_a)

  local str_w, str_h = gfx.measurestr(self.caption)

  gfx.x = self.x + (self.w - str_w) / 2 + self.cap_x
  gfx.y = self.y - (self.dir ~= "v" and self.h or self.w) - str_h + self.cap_y
  GUI.text_bg(self.caption, self.bg)
  GUI.shadow(self.caption, self.col_txt, "shadow")

end




------------------------------------
-------- Slider helpers ------------
------------------------------------


function GUI.Slider:getnearesthandle(val)

  local small_diff, small_idx

  for i = 1, #self.handles do

    local diff = math.abs( self.handles[i].curval - val )

    if not small_diff or (diff < small_diff) then
      small_diff = diff
      small_idx = i

    end

  end

    return small_idx

end


function GUI.Slider:setcurstep(sldr, step)

    self.handles[sldr].curstep = step
    self.handles[sldr].curval = self.handles[sldr].curstep / self.steps
    self:setretval(sldr)


end


function GUI.Slider:setcurval(sldr, val)

    self.handles[sldr].curval = val
    self.handles[sldr].curstep = GUI.round(val * self.steps)
    self:setretval(sldr)

end


function GUI.Slider:setretval(sldr)

    local val = self.dir == "h" and self.inc * self.handles[sldr].curstep + self.min
                                or self.min - self.inc * self.handles[sldr].curstep

    self.handles[sldr].retval = self:formatretval(val)

end

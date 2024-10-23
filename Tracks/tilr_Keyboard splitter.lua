-- @description Keyboard splitter
-- @author tilr
-- @version 1.1
-- @changelog
--   Region shortcuts
--   Colored pitch key
--   Pitch key follows note transpose
-- @provides
--   tilr_Keyboard splitter/rtk.lua
--   [effect] tilr_Keyboard splitter/MIDI Keyvel Filter.jsfx
-- @screenshot https://raw.githubusercontent.com/tiagolr/keyboard-splitter/master/doc/keyboard-splitter.gif
-- @about
--   # Keyboard splitter
--
--   Manage tracks keyboard splitting using a visual keymap.

function log(t)
  reaper.ShowConsoleMsg(t .. '\n')
end
function logtable(table)
  log(tostring(table))
  for index, value in pairs(table) do -- print table
    log('    ' .. tostring(index) .. ' : ' .. tostring(value))
  end
end
function clone_table(table)
  local copy = {}
  for key, val in pairs(table) do
    copy[key] = val
  end
  return copy
end

local sep = package.config:sub(1, 1)
local script_folder = debug.getinfo(1).source:match("@?(.*[\\|/])")
rtk = dofile(script_folder .. 'tilr_Keyboard splitter' .. sep .. 'rtk.lua')

globals = {
  win_x = nil,
  win_y = nil,
  win_w = 768,
  win_h = 370,
  key_h = 30,
  key_w = 6,
  region_h = 254,
  vel_h = 2,
  drag_margin = 10,
}
g = globals

-- init globals from project config
local exists, win_x = reaper.GetProjExtState(0, 'keyboard_splitter', 'win_x')
if exists ~= 0 then globals.win_x = tonumber(win_x) end
local exists, win_y = reaper.GetProjExtState(0, 'keyboard_splitter', 'win_y')
if exists ~= 0 then globals.win_y = tonumber(win_y) end

_notes = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
notes = {}
for i = 0, 127 do notes[i+1] = _notes[i % 12 + 1] .. (math.floor(i/12) - 1) end
colors = {'cyan', 'coral', 'dodgerblue', 'chartreuse', 'deeppink', 'floralwhite', 'yellow', 'floralwhite', 'lightcyan', 'lightgreen', 'violet', 'teal', 'salmon', 'paleturquoise', 'lawngreen', 'mintcream'}
sel_tracks = {}
keyvel_count = 0
widget_drag = {
  active = false,
  wideg = nil,
  start_y = 0,
  start_val = 0
}

sel_key = nil
regions = {}
mouse = {
  down = false,
  toggled = false,
  double_click_timer = 0,
  drag = {
    active = false,
    start_x = 0,
    start_y = 0,
    region = nil,
    margin = nil,
  }
}

function make_region(keymin, keymax, velmin, velmax)
  return {
    id = rtk.uuid4(),
    keymin = keymin,
    keymax = keymax,
    velmin = velmin,
    velmax = velmax,
    x = keymin * g.key_w,
    y = g.win_h - (velmax * g.vel_h + g.key_h),
    w = (keymax - keymin) * g.key_w + g.key_w,
    h = (velmax - velmin) * g.vel_h + g.vel_h,
    transpose = 0,
    hover = false,
    selected = false,
    updated = false,
    track = 0,
    fxid = '',
    file = '',
  }
end

function draw_keyboard()
  function draw_key (x, y, w, h, black_key)
    if black_key then
      gfx.set(0, 0, 0)
      gfx.rect(x, y, w, h, 1)
    else
      gfx.set(1, 1, 1)
      gfx.rect(x, y, w, h, 1)
    end
  end
  for i=0, 127 do
    local pitch = i % 12
    local is_black_key = pitch == 1 or pitch == 3 or pitch == 6 or pitch == 8 or pitch == 10
    draw_key(i * globals.key_w, globals.win_h - globals.key_h, globals.key_w, globals.key_h, is_black_key)
  end
end

function draw_pitch_key()
  for _, reg in ipairs(regions) do
    local red, green, blue, _ = rtk.color.rgba(colors[(reg.track % #colors) + 1])
    gfx.set(red, green, blue, 1)
    gfx.rect(reg.keymin * g.key_w + (reg.transpose * g.key_w), g.win_h - g.key_h, g.key_w, g.key_h)
  end
end

function draw_guides()
  for i=0, 127, 12 do
    gfx.set(1, 1, 1, .25)
    gfx.line(i * g.key_w, g.win_h - g.region_h - g.key_h, i*g.key_w, g.win_h - g.key_h)
    gfx.x = i * g.key_w + 5
    gfx.y = g.win_h - g.key_h - g.region_h
    gfx.drawstr('C'..(math.floor(i/12) - 1))
  end
end

function draw_regions()
  local helper_w = 6
  for _, reg in ipairs(regions) do
    local r, g, b, _ = rtk.color.rgba(colors[(reg.track % #colors) + 1])
    gfx.set(r, g, b, reg.selected and 0.5 or 0.25)
    gfx.rect(reg.x, reg.y, reg.w, reg.h, 1)
    gfx.set(r, g, b, (reg.hover or reg.selected) and 0.75 or 0.5)
    gfx.rect(reg.x, reg.y, reg.w, reg.h, 0)
    if reg.hover then -- draw drag helpers
      gfx.rect(reg.x, reg.y + reg.h / 2 - helper_w / 2, helper_w, helper_w, 1) -- left
      gfx.rect(reg.x + reg.w - helper_w, reg.y + reg.h / 2 - helper_w / 2, helper_w, helper_w, 1) -- right
      gfx.rect(reg.x + reg.w / 2 - helper_w / 2, reg.y, helper_w, helper_w, 1) -- top
      gfx.rect(reg.x + reg.w / 2 - helper_w / 2, reg.y + reg.h - helper_w, helper_w, helper_w, 1) -- bottom
    end
  end
end

function draw_region_shortcuts()
  local regs = {}
  for _, reg in ipairs(regions) do table.insert(regs, reg) end
  table.sort(regs, function (a,b)
    return a.track < b.track
  end)
  for i, reg in ipairs(regs) do
    local red, green, blue, _ = rtk.color.rgba(colors[(reg.track % #colors) + 1])
    gfx.set(red, green, blue, reg.selected and 0.75 or 0.5)
    local w = 18
    local x = (i - 1) * w
    local y = g.win_h - g.key_h - g.region_h - w
    gfx.rect(x, y, w, w, 1)
    gfx.set(red, green, blue, reg.selected and 1 or 0)
    gfx.rect(x, y, w, w, 0)
    if mouse.toggled and rtk.point_in_box(rtk.mouse.x, rtk.mouse.y, x, y, w, w) then
      select_region(reg)
    end
  end
end

-- recalc regions after window resize
function recalc_regions ()
  for _, reg in ipairs(regions) do
    rr = make_region(reg.keymin, reg.keymax, reg.velmin, reg.velmax)
    reg.x = rr.x
    reg.y = rr.y
    reg.w = rr.w
    reg.h = rr.h
  end
end

function select_region(reg)
  local index = -1
  for i,r in ipairs(regions) do
    r.selected = r == reg
    if r.selected then index = i end
  end
  if index > -1 then -- move region to top of the list
    table.remove(regions, index)
    table.insert(regions, reg)
  end
end

function is_keyvel(tr, nfx)
  local ret, pname = reaper.TrackFX_GetParamName(tr, nfx, 0)
  local ret2, pname2 = reaper.TrackFX_GetParamName(tr, nfx, 4)
  return ret and ret2 and pname == 'Note min' and pname2 == 'Transpose'
end

function has_keyvel (tr)
  for i = 1, reaper.TrackFX_GetCount(tr) do
    if is_keyvel(tr, i - 1) then
      return true
    end
  end
  return false
end

-- create regions/keyvel for selected tracks without keyvel control
function create_regions ()
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  for i = 1, reaper.GetNumTracks() do
    local track = reaper.GetTrack(0, i - 1)
    if reaper.IsTrackSelected(track) and not has_keyvel(track) then
      local fxi = reaper.TrackFX_AddByName(track, 'MIDI Keyvel Filter', false, -1000)
      if fxi == -1 then
        reaper.PreventUIRefresh(-1)
        reaper.MB('MIDI Keyvel Filter JSFX is missing. Please reinstall this package.', '', 0)
        reaper.Undo_EndBlock('keysplitter - create_regions', 0)
        return
      end
      reaper.TrackFX_Show(track, fxi, 0)
      reaper.TrackFX_Show(track, fxi, 2)
    end
  end
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('keysplitter - create_regions', 0)
end

function update_region_from_fx(reg, track, nfx, ntrack)
  local _, keymin = reaper.TrackFX_GetFormattedParamValue(track, nfx, 0)
  local _, keymax = reaper.TrackFX_GetFormattedParamValue(track, nfx, 1)
  local _, velmin = reaper.TrackFX_GetFormattedParamValue(track, nfx, 2)
  local _, velmax = reaper.TrackFX_GetFormattedParamValue(track, nfx, 3)
  local _, transpose = reaper.TrackFX_GetFormattedParamValue(track, nfx, 4)
  local rr = make_region(tonumber(keymin), tonumber(keymax), tonumber(velmin), tonumber(velmax))
  reg.keymin = rr.keymin
  reg.keymax = rr.keymax
  reg.velmin = rr.velmin
  reg.velmax = rr.velmax
  reg.x = rr.x
  reg.y = rr.y
  reg.w = rr.w
  reg.h = rr.h
  reg.transpose = transpose
  reg.track = ntrack
  reg.updated = true
end

function create_region_from_fx(track, nfx, ntrack)
  local _, keymin = reaper.TrackFX_GetFormattedParamValue(track, nfx, 0)
  local _, keymax = reaper.TrackFX_GetFormattedParamValue(track, nfx, 1)
  local _, velmin = reaper.TrackFX_GetFormattedParamValue(track, nfx, 2)
  local _, velmax = reaper.TrackFX_GetFormattedParamValue(track, nfx, 3)
  local _, transpose = reaper.TrackFX_GetFormattedParamValue(track, nfx, 4)
  local fxid = reaper.TrackFX_GetFXGUID(track, nfx)
  local reg = make_region(tonumber(keymin), tonumber(keymax), tonumber(velmin), tonumber(velmax))
  reg.track = ntrack
  reg.fxid = fxid
  reg.transpose = transpose
  local _, trackname = reaper.GetTrackName(track)
  reg.trackname = trackname
  return reg
end

function fetch_regions()
  sel_tracks = {}
  keyvel_count = 0
  local regions_map = {}
  local new_regions = {}
  for _, reg in ipairs(regions) do
    reg.updated = false
    regions_map[reg.fxid] = reg
  end
  for i = 1, reaper.GetNumTracks() do
    local track = reaper.GetTrack(0, i - 1)
    if reaper.IsTrackSelected(track) then
      table.insert(sel_tracks, track)
      for j = 1, reaper.TrackFX_GetCount(track) do
        if is_keyvel(track, j - 1) then
          keyvel_count = keyvel_count + 1
          local fxid = reaper.TrackFX_GetFXGUID(track, j - 1)
          local reg = regions_map[fxid]
          if reg then
            update_region_from_fx(regions_map[fxid], track, j - 1, i - 1)
          else
            reg = create_region_from_fx(track, j - 1, i - 1)
            table.insert(new_regions, reg)
          end
          goto continue
        end
      end
      :: continue ::
    end
  end
  for _, reg in ipairs(regions) do
    if reg.updated then
      table.insert(new_regions, reg)
    end
  end
  regions = new_regions
end

function update_keyvel_from_reg(reg)
  for i = 1, reaper.GetNumTracks() do
    local track = reaper.GetTrack(0, i - 1)
    for j = 1, reaper.TrackFX_GetCount(track) do
      local fxid = reaper.TrackFX_GetFXGUID(track, j - 1)
      if fxid == reg.fxid then
        reaper.TrackFX_SetParam(track, j - 1, 0, reg.keymin)
        reaper.TrackFX_SetParam(track, j - 1, 1, reg.keymax)
        reaper.TrackFX_SetParam(track, j - 1, 2, reg.velmin)
        reaper.TrackFX_SetParam(track, j - 1, 3, reg.velmax)
        reaper.TrackFX_SetParam(track, j - 1, 4, reg.transpose)
        return
      end
    end
  end
end

function start_drag(region, margin)
  mouse.drag.active = true
  mouse.drag.region = clone_table(region) -- region copy
  mouse.drag.start_x = rtk.mouse.x
  mouse.drag.start_y = rtk.mouse.y
  mouse.drag.margin = margin
end

function stop_drag()
  mouse.drag.active = false
  mouse.drag.region = nil
  mouse.drag.margin = nil
end

function update_drag()
  if not mouse.drag.active then return end
  local reg = mouse.drag.region
  local delta_x = rtk.mouse.x - mouse.drag.start_x
  local delta_y = rtk.mouse.y - mouse.drag.start_y
  local keymin = mouse.drag.region.keymin
  local keymax = mouse.drag.region.keymax
  local velmin = mouse.drag.region.velmin
  local velmax = mouse.drag.region.velmax
  if mouse.drag.margin == 'left' then
    keymin = mouse.drag.region.keymin + math.floor(delta_x / g.key_w)
  elseif mouse.drag.margin == 'right' then
    keymax = mouse.drag.region.keymax + math.floor(delta_x / g.key_w)
  elseif mouse.drag.margin == 'top' then
    velmax = velmax - math.floor(delta_y / g.vel_h)
  elseif mouse.drag.margin == 'bottom' then
    velmin = velmin - math.floor(delta_y / g.vel_h)
  else
    keymin = keymin + math.floor(delta_x / g.key_w)
    keymax = keymax + math.floor(delta_x / g.key_w)
    velmin = velmin - math.floor(delta_y / g.vel_h)
    velmax = velmax - math.floor(delta_y / g.vel_h)
  end
  if keymin > keymax then
    local tmp = keymin
    keymin = keymax
    keymax = tmp
  end
  if velmin > velmax then
    local tmp = velmin
    velmin = velmax
    velmax = tmp
  end
  if keymin < 0 then -- fix out of bounds drag
    if not mouse.drag.margin then keymax = keymax - keymin end
    keymin = 0
  end
  if keymax > 127 then -- fix out of bounds drag
    if not mouse.drag.margin then keymin = keymin + 127 - keymax end
    keymax = 127
  end
  if velmin < 0 then --
    if not mouse.drag.margin then velmax = velmax - velmin end
    velmin = 0
  end
  if velmax > 127 then --
    if not mouse.drag.margin then velmin = velmin + 127 - velmax end
    velmax = 127
  end
  local newreg = make_region(keymin, keymax, velmin, velmax)
  for _, rr in ipairs(regions) do
    if rr.id == reg.id then
        rr.keymin = newreg.keymin
        rr.keymax = newreg.keymax
        rr.x = newreg.x
        rr.w = newreg.w
        rr.velmin = newreg.velmin
        rr.velmax = newreg.velmax
        rr.y = newreg.y
        rr.h = newreg.h
        update_keyvel_from_reg(rr)
    end
  end
end

function update_mouse()
  if rtk.mouse.down == 1 then
    if not mouse.down then
      mouse.toggled = true
    end
    mouse.down = true
  else
    mouse.down = false
  end
  local hover_margin = nil
  local hover = false
  local selected = false
  if mouse.drag.active then
    goto continue
  end
  for i = #regions, 1, -1 do
    local reg = regions[i]
		reg.hover = false
    if not hover and rtk.point_in_box(rtk.mouse.x, rtk.mouse.y, reg.x, reg.y, reg.w, reg.h) then -- mouse in region
      reg.hover = true
      hover = true
      if mouse.toggled then
        selected = reg
      end
      if rtk.point_in_box(rtk.mouse.x, rtk.mouse.y, reg.x, reg.y + reg.h / 2 - g.drag_margin / 2, g.drag_margin, g.drag_margin) then -- mouse in left drag
        hover_margin = 'left'
      elseif rtk.point_in_box(rtk.mouse.x, rtk.mouse.y, reg.x + reg.w - g.drag_margin, reg.y + reg.h / 2 - g.drag_margin / 2, g.drag_margin, g.drag_margin) then -- mouse in right drag
        hover_margin = 'right'
      elseif rtk.point_in_box(rtk.mouse.x, rtk.mouse.y, reg.x + reg.w / 2 - g.drag_margin / 2, reg.y, g.drag_margin, g.drag_margin) then -- mouse in top drag
        hover_margin = 'top'
      elseif rtk.point_in_box(rtk.mouse.x, rtk.mouse.y, reg.x + reg.w / 2 - g.drag_margin / 2, reg.y + reg.h - g.drag_margin, g.drag_margin, g.drag_margin) then -- mouse in bottom drag
        hover_margin = 'bottom'
      end
    end
	end
  ::continue::
  if selected then
    select_region(selected)
    start_drag(selected, hover_margin)
  end
  if not hover and not mouse.drag.margin then
    window:request_mouse_cursor(rtk.mouse.cursors.POINTER)
  end
  if mouse.drag.margin or hover_margin then -- if its dragging or hovering margins draw cursor
    if mouse.drag.margin == 'left' or hover_margin == 'left' or mouse.drag.margin == 'right' or hover_margin == 'right' then
      window:request_mouse_cursor(rtk.mouse.cursors.SIZE_EW)
    elseif mouse.drag.margin == 'top' or hover_margin == 'top' or mouse.drag.margin == 'bottom' or hover_margin == 'bottom' then
      window:request_mouse_cursor(rtk.mouse.cursors.SIZE_NS)
    end
  end
  if mouse.drag.active and not mouse.down then
    stop_drag()
  end
  if not selected and mouse.toggled and rtk.point_in_box(rtk.mouse.x, rtk.mouse.y, 0, g.win_h - g.region_h - g.key_h - 50, g.win_w, g.win_h) then -- mouse in regions area
    select_region(nil)
  end
end

function popup_fx(fxid, show_first_instrument)
  for i = 1, reaper.GetNumTracks() do
    local track = reaper.GetTrack(0, i - 1)
    for j = 1, reaper.TrackFX_GetCount(track) do
      local _fxid = reaper.TrackFX_GetFXGUID(track, j - 1)
      if _fxid == fxid then
        if show_first_instrument then
          local inst = reaper.TrackFX_GetInstrument(track)
          reaper.TrackFX_Show(track, inst > -1 and inst or j - 1, 1)
        else
          reaper.TrackFX_Show(track, j - 1, 1)
        end
        goto continue
      end
    end
  end
  :: continue ::
end

function on_double_click()
  for i = #regions, 1, -1 do
    local reg = regions[i]
    if rtk.point_in_box(rtk.mouse.x, rtk.mouse.y, reg.x, reg.y, reg.w, reg.h) then
      popup_fx(reg.fxid, true)
      goto continue
    end
  end
  :: continue ::
end

function start_widget_drag(widget)
  local reg
  for _, r in ipairs(regions) do
    if (r.selected) then reg = r end
  end
  if not reg then return end
  widget_drag.active = true
  widget_drag.widget = widget
  widget_drag.start_y = rtk.mouse.y
  widget_drag.start_val = reg[widget]
end

function update_widget_drag()
  if not widget_drag.active then return end
  if not mouse.down then
    widget_drag.active = false
    return
  end
  local offset_y = math.floor((widget_drag.start_y - rtk.mouse.y) / 2)
  local val = widget_drag.start_val + offset_y
  if widget_drag.widget == 'transpose' then
    if val < -60 then val = -60 end
    if val > 60 then val = 60 end
  else
    if val < 0 then val = 0 end
    if val > 127 then val = 127 end
  end
  local reg
  for _, r in ipairs(regions) do
    if (r.selected) then reg = r end
  end
  if not reg then return end
  if widget_drag.widget == 'velmin' and val > reg.velmax then val = reg.velmax end
  if widget_drag.widget == 'velmax' and val < reg.velmin then val = reg.velmin end
  if widget_drag.widget == 'keymin' and val > reg.keymax then val = reg.keymax end
  if widget_drag.widget == 'keymax' and val < reg.keymin then val = reg.keymin end
  reg[widget_drag.widget] = val
  update_keyvel_from_reg(reg)
end

function draw()
  fetch_regions()
  update_mouse()
  update_drag()
  draw_keyboard()
  draw_pitch_key()
  draw_guides()
  draw_regions()
  draw_region_shortcuts()
  draw_ui()
  update_widget_drag()
  if mouse.toggled then
    local time = reaper.time_precise()
    if time - mouse.double_click_timer < 0.25 then
      on_double_click()
    end
    mouse.double_click_timer = reaper.time_precise()
  end
  mouse.toggled = false
end

function draw_ui()
  local sel_region
  for _, reg in ipairs(regions) do
    if reg.selected then sel_region = reg end
  end
  if not sel_region then
    ui_controls:attr('visible', false)
    ui_helpbox:attr('visible', true)
    local help_text = ''
    if #sel_tracks == 0 then
      help_text = 'No tracks selected'
    elseif keyvel_count == 0 then
      help_text = 'No regions found'
    end
    ui_helpbox:attr('text', help_text)
  else
    ui_controls:attr('visible', true)
    ui_helpbox:attr('visible', false)
    ui_note_start:attr('text', math.floor(sel_region.keymin) .. ' ' .. notes[sel_region.keymin + 1])
    ui_note_end:attr('text', math.floor(sel_region.keymax) .. ' ' .. notes[sel_region.keymax + 1])
    ui_vel_min:attr('text', math.floor(sel_region.velmin))
    ui_vel_max:attr('text', math.floor(sel_region.velmax))
    ui_transpose:attr('text', math.floor(sel_region.transpose))
    ui_track_name:attr('text', sel_region.trackname)
  end
  ui_btn_create_regions:attr('disabled', #sel_tracks <= keyvel_count)
end

function init()
  window = rtk.Window{ w=globals.win_w, h=globals.win_h, title='Keyboard splitter'}
  window.onmove = function (self)
    reaper.SetProjExtState(0, 'keyboard_splitter', 'win_x', self.x)
    reaper.SetProjExtState(0, 'keyboard_splitter', 'win_y', self.y)
  end
  window.onupdate = function ()
    window:queue_draw()
  end
  window.ondraw = draw

  window.onresize = function ()
    globals.win_w = window.w
    globals.win_h = window.h
    globals.key_w = window.w / 128
    recalc_regions()
  end

  ui_controls = window:add(rtk.VBox{ padding=10, spacing=10 })
  ui_hbox = ui_controls:add(rtk.HBox{ spacing=10 })
  ui_hbox:add(rtk.Text{'Vel min'})
  ui_vel_min = ui_hbox:add(rtk.Text{'', w=40, cursor=rtk.mouse.cursors.SIZE_NS })
  ui_vel_min.onmousedown = function () start_widget_drag('velmin') end
  ui_hbox:add(rtk.Text{'Vel max'})
  ui_vel_max = ui_hbox:add(rtk.Text{'', w=40, cursor=rtk.mouse.cursors.SIZE_NS })
  ui_vel_max.onmousedown = function () start_widget_drag('velmax') end
  ui_hbox:add(rtk.Text{'Note start'})
  ui_note_start = ui_hbox:add(rtk.Text{'', w=60, cursor=rtk.mouse.cursors.SIZE_NS })
  ui_note_start.onmousedown = function () start_widget_drag('keymin') end
  ui_hbox:add(rtk.Text{'Note end'})
  ui_note_end = ui_hbox:add(rtk.Text{'', w=60, cursor=rtk.mouse.cursors.SIZE_NS })
  ui_note_end.onmousedown = function () start_widget_drag('keymax') end
  ui_track_name = ui_controls:add(rtk.Text{''})
  ui_hbox:add(rtk.Text{'Transpose'})
  ui_transpose = ui_hbox:add(rtk.Text{'', w=60, cursor=rtk.mouse.cursors.SIZE_NS })
  ui_transpose.onmousedown = function () start_widget_drag('transpose') end

  ui_helpbox = window:add(rtk.Text{'No region selected', padding=10})

  ui_right_side = window:add(rtk.HBox{w=g.win_w, padding=10})
  ui_right_side:add(rtk.Box.FLEXSPACE)
  ui_btn_create_regions = ui_right_side:add(rtk.Button{'Create regions'})
  ui_btn_create_regions.onclick = create_regions

  window:open{align='center'}
  if globals.win_x and globals.win_y then
    window:attr('x', globals.win_x)
    window:attr('y', globals.win_y)
  end

end

init()

-- @description Lua profiler
-- @author cfillion
-- @version 1.0
-- @link Forum thread https://forum.cockos.com/showthread.php?t=283461
-- @screenshot https://i.imgur.com/cCe6fBB.png
-- @donation https://reapack.com/donate
-- @about
--   # Lua profiler
--
--   This is a library for helping the development of Lua ReaScript. See the [forum thread](https://forum.cockos.com/showthread.php?t=283461) for usage information. A summary of the provided API is at the top of the source code.

-- Public API summary:
-- * profiler.attachTo(string var, nil|table opts)
-- * profiler.detachFrom(string var, nil|table opts)
-- * profiler.attachToLocals(nil|table opts)
-- * profiler.detachFromLocals(nil|table opts)
-- * profiler.attachToWorld()
-- * profiler.detachFromWorld()
-- * profiler.reset()
-- * profiler.start()
-- * profiler.enter(string what)
-- * profiler.leave()
-- * profiler.stop()
-- * profiler.frame()
-- * profiler.showWindow(ImGui_Context* ctx, nil|bool p_open, nil|integer flags)
-- * profiler.showProfile(ImGui_Context* ctx, string label, nil|number width, nil|number height)
-- * profiler.defer(function callback)
-- * profiler.run()
-- * profiler.reset()
--
-- * nil|bool|integer profiler.auto_start

local ImGui = (function()
  local host_reaper = reaper
  reaper = {}
  for k,v in pairs(host_reaper) do reaper[k] = v end
  dofile(reaper.GetResourcePath() ..
    '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.8.7')
  local ImGui = {}
  for name, func in pairs(reaper) do
    name = name:match('^ImGui_(.+)$')
    if name then ImGui[name] = func end
  end
  reaper = host_reaper
  return ImGui
end)()

local SCRIPT_NAME, EXT_STATE_ROOT = 'Lua profiler', 'cfillion_Lua profiler'
local FLT_MIN = ImGui.NumericLimits_Float()
local PROFILES_SIZE = 8

-- 'active' is not in 'state' for faster access
local profiler, profiles, active, state = {}, {}, false, {
  current = 1, auto_active = 0, sort = {},
}
local attachments, wrappers, locations = {}, {}, {}
local getTime = reaper.time_precise -- faster than os.clock
local profile, profile_cur -- references to profiles[current] for quick access
local options, options_cache, options_default = {}, {}, {
  tree_view = true,
}

-- weak references to have the garbage collector auto-clear the caches
setmetatable(attachments, { __mode = 'kv' })
setmetatable(wrappers,    { __mode = 'kv' })
setmetatable(locations,   { __mode = 'k'  })

-- cache stdlib constants and funcs to not break if the host script changes them
-- + don't count the profiler's own use of them in measurements
local assert, error, select, tostring = assert, error, select, tostring
local type, getmetatable, next, print = type, getmetatable, next, print
local select, pairs, ipairs           = select, pairs, ipairs
local collectgarbage, reaper          = collectgarbage, {
  defer              = reaper.defer,
  get_action_context = reaper.get_action_context,
  HasExtState        = reaper.HasExtState,
  GetExtState        = reaper.GetExtState,
  SetExtState        = reaper.SetExtState,
  CF_ShellExecute    = reaper.CF_ShellExecute,
}
local debug, math, string, table, utf8 = (function(...)
  local vars = {}
  for i = 1, select('#', ...) do
    local copy = {}
    for k, v in pairs(_G[select(i, ...)]) do copy[k] = v end
    vars[#vars + 1] = copy
  end
  return table.unpack(vars)
end)('debug', 'math', 'string', 'table', 'utf8')

assert(debug.getinfo(debug.getlocal, 'S').what == 'C',
  'global environment is tainted, stack depths will be incorrect')

setmetatable(options, {
  __index = function(options, key)
    local v = options_cache[key]
    if v ~= nil then return v end
    v = options_default[key]
    assert(v ~= nil, 'option does not exist')
    if not reaper.HasExtState(EXT_STATE_ROOT, key) then
      reaper.SetExtState(EXT_STATE_ROOT, key, tostring(v), true)
    else
      local t = type(v)
      v = reaper.GetExtState(EXT_STATE_ROOT, key)
      if t == 'boolean' then
        v = v == 'true'
      elseif t ~= 'string' then
        error('unsupported type')
      end
    end
    options_cache[key] = v
    return v
  end,
  __newindex = function(options, key, value)
    assert(type(value) == type(options_default[key]), 'unexpected value type')
    reaper.SetExtState(EXT_STATE_ROOT, key, tostring(value), true)
    options_cache[key] = value
  end,
})

local function makeAttachOpts(opts)
  if not opts then opts = {} end

  local defaults = {
    recursive    = true,
    search_above = true,
    metatable    = true,
  }
  for key, value in pairs(defaults) do
    if opts[key] == nil then opts[key] = value end
  end

  return opts
end

local function formatTime(time, pad)
  if pad == nil then pad = true end
  local units, unit = { 's', 'ms', 'us', 'ns' }, 1
  while time < 0.1 and unit < #units do
    time, unit = time * 1000, unit + 1
  end
  return string.format(pad and '%5.02f%-2s' or '%.02f%s', time, units[unit])
end

local function formatNumber(num)
  repeat
    local matches
    num, matches = string.gsub(num, '^(%d+)(%d%d%d)', '%1,%2')
  until matches < 1
  return num
end

function utf8.sub(s, i, j)
  i = utf8.offset(s, i)
  if not i then return '' end -- i is out of bounds

  if j and (j > 0 or j < -1) then
    j = utf8.offset(s, j + 1)
    if j then j = j - 1 end
  end

  return string.sub(s, i, j)
end

local function ellipsis(ctx, text, length)
  local avail = ImGui.GetContentRegionAvail(ctx)
  if avail >= ImGui.CalcTextSize(ctx, text) then return text end

  local steps = 0
  local fit, l, r, m = '...', 0, utf8.len(text) - 1
  while l <= r do
    m = (l + r) // 2
    local cut = '...' .. utf8.sub(text, -m)
    if ImGui.CalcTextSize(ctx, cut) > avail then
      r = m - 1
    else
      l = m + 1
      fit = cut
    end
  end
  return fit
end

local function basename(filename)
  return string.match(filename, '[^/\\]+$') or filename
end

local function centerNextWindow(ctx)
  local center_x, center_y = ImGui.Viewport_GetCenter(ImGui.GetWindowViewport(ctx))
  ImGui.SetNextWindowPos(ctx, center_x, center_y, ImGui.Cond_Appearing(), 0.5, 0.5)
end

local function alignNextItemRight(ctx, label, spacing)
  local item_spacing_w = spacing and
    ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing()) or 0
  local want_pos_x = ImGui.GetScrollX(ctx) +
    ImGui.GetContentRegionMax(ctx) - item_spacing_w -
    ImGui.CalcTextSize(ctx, label, nil, nil, true)
  if want_pos_x > ImGui.GetCursorPosX(ctx) then
    ImGui.SetCursorPosX(ctx, want_pos_x)
  end
end

local function alignGroupRight(ctx, callback)
  local pos_x, right_x = ImGui.GetCursorPosX(ctx), ImGui.GetContentRegionMax(ctx)

  ImGui.BeginGroup(ctx)
  ImGui.PushID(ctx, 'width')
  ImGui.PushClipRect(ctx, 0, 0, 1, 1, false)
  callback()
  ImGui.PopClipRect(ctx)
  ImGui.PopID(ctx)
  ImGui.EndGroup(ctx)

  local want_pos = right_x - ImGui.GetItemRectSize(ctx)
  if want_pos >= pos_x then
    ImGui.SameLine(ctx)
    ImGui.SetCursorPosX(ctx, want_pos)
  end

  ImGui.BeginGroup(ctx)
  callback()
  ImGui.EndGroup(ctx)
end

local function tooltip(ctx, text)
  if not ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_DelayShort()) or
    not ImGui.BeginTooltip(ctx) then return end
  ImGui.PushTextWrapPos(ctx, ImGui.GetFontSize(ctx) * 42)
  ImGui.Text(ctx, text)
  ImGui.PopTextWrapPos(ctx)
  ImGui.EndTooltip(ctx)
end

local function textCell(ctx, value, right_align, custom_tooltip)
  if right_align ~= false then alignNextItemRight(ctx, value) end
  ImGui.Text(ctx, value)
  if (custom_tooltip and custom_tooltip ~= value) or
      ImGui.GetItemRectSize(ctx) > ImGui.GetContentRegionAvail(ctx) then
    tooltip(ctx, custom_tooltip or value)
  end
end

local function progressBar(ctx, value)
  ImGui.ProgressBar(ctx, value, nil, nil, string.format('%.02f%%', value * 100))
end

local report_columns = (function()
  local def_sort_desc = ImGui.TableColumnFlags_PreferSortDescending()
  local def_hide = ImGui.TableColumnFlags_DefaultHide()
  local frac_flags = def_sort_desc | ImGui.TableColumnFlags_WidthStretch()
  return {
    { name = 'Name',   field = 'name', width = 227 },
    { name = 'Source', field = 'src',  width = 132 },
    { name = 'Line',   field = 'src_line', func = textCell, },
    { name = '% of total',  field = 'time_frac',
      func = progressBar, flags = frac_flags            },
    { name = '% of parent', field = 'time_frac_parent',
      func = progressBar, flags = frac_flags | def_hide },
    { name = 'Time',   field = 'time', func = textCell, fmt   = formatTime,
      flags = def_sort_desc | ImGui.TableColumnFlags_DefaultSort()            },
    { name = 'Calls',  field = 'count',
      func = textCell, fmt   = formatNumber, flags = def_sort_desc            },
    { name = 'MinT/c', field = 'time_per_call_min',
      func = textCell, fmt   = formatTime,   flags = def_sort_desc | def_hide },
    { name = 'AvgT/c', field = 'time_per_call_avg',
      func = textCell, fmt   = formatTime,   flags = def_sort_desc | def_hide },
    { name = 'MaxT/c', field = 'time_per_call_max',
      func = textCell, fmt   = formatTime,   flags = def_sort_desc            },
    { name = 'Frames', field = 'frames',
      func = textCell, fmt   = formatNumber, flags = def_sort_desc | def_hide },
    { name = 'MinT/f', field = 'time_per_frame_min',
      func = textCell, fmt   = formatTime,   flags = def_sort_desc | def_hide },
    { name = 'AvgT/f', field = 'time_per_frame_avg',
      func = textCell, fmt   = formatTime,   flags = def_sort_desc | def_hide },
    { name = 'MaxT/f', field = 'time_per_frame_max',
      func = textCell, fmt   = formatTime,   flags = def_sort_desc            },
    { name = 'MinC/f', field = 'calls_per_frame_min',
      func = textCell, fmt   = formatNumber, flags = def_sort_desc | def_hide },
    { name = 'AvgC/f', field = 'calls_per_frame_avg',
      func = textCell, fmt   = formatNumber, flags = def_sort_desc | def_hide },
    { name = 'MaxC/f', field = 'calls_per_frame_max',
      func = textCell, fmt   = formatNumber, flags = def_sort_desc | def_hide },
  }
end)()

local function enter(what, alias)
  profile.dirty = true

  local line = profile_cur.children[what]
  if not line then
    line = {
      parent = profile_cur, children = {},
      name = alias, count = 0, time = 0, enter_time = 0,
      frames = 0, prev_count = 0, prev_time = 0,
      time_per_call = {}, time_per_frame = {}, calls_per_frame = {},
    }
    profile_cur.children[what] = line
  end
  profile_cur = line

  if not locations[what] then
    local location
    if type(what) == 'function' then
      location = debug.getinfo(what, 'S')
    else -- user-provided name
      location = debug.getinfo(3, 'Sl')
      location.linedefined = location.currentline
    end
    locations[what] = location
  end

  line.count = line.count + 1
  line.enter_time = getTime()
end

local function leave()
  local now = getTime()
  if profile_cur == profile then
    error('unbalanced leave (missing call to enter)')
  end

  local time = now - profile_cur.enter_time
  local time_per_call = profile_cur.time_per_call
  if not time_per_call.min or time < time_per_call.min then
    time_per_call.min = time
  end
  if not time_per_call.max or time > time_per_call.max then
    time_per_call.max = time
  end
  profile_cur.time, profile_cur.enter_time = profile_cur.time + time, now
  profile_cur = profile_cur.parent
end

local function isAnyActive()
  return active or state.auto_active ~= 0
end

local function setActive(frame_count, force_auto)
  if frame_count == true then frame_count = -1
  elseif not frame_count then frame_count = 0 end
  assert(type(frame_count) == 'number',
    'value must be nil, a boolean, or an integer')
  frame_count = math.floor(frame_count)

  if frame_count ~= 0 then
    if state.defer_called or force_auto then
      state.auto_active = frame_count
      profile.user_start_time = getTime()
    else
      profiler.start()
      profile.user_start_time = profile.start_time
    end
  else
    if active and not force_auto then
      profiler.stop()
    else
      state.auto_active = 0
    end
  end
end

local function setActiveFromUI(frame_count)
  if not state.defer_called and frame_count and frame_count ~= 0 then
    state.want_activate = frame_count
  else
    -- profiler might be active now if showWindow called from profiler.defer
    -- waiting a defer cycle to ensure auto_active is properly unset
    -- rather than calling `stop` directly (which would happen twice = error)
    reaper.defer(function() setActive(frame_count) end)
  end
end

local function setCurrentProfile(i)
  local now = getTime()

  state.current = i
  if not profiles[i] then
    profiler.reset()
  else
    profile, profile_cur = profiles[i], profiles[i]
  end

  if active then
    profile.start_time, profile.user_start_time = now, now
  elseif state.auto_active ~= 0 then
    profile.user_start_time = now
  end

  state.scroll_to_top = true
end

local function eachDeep(tbl)
  local key_stack, depth = {}, 1
  return function()
    local v
    if not tbl then return end
    if key_stack[depth] and tbl.children[key_stack[depth]] then
      tbl = tbl.children[key_stack[depth]]
      depth = depth + 1
    end
    repeat
      key_stack[depth], v = next(tbl.children, key_stack[depth])
      if key_stack[depth] then return key_stack[depth], v, depth end
      depth = depth - 1
      tbl = tbl.parent
    until not tbl
  end
end

local function updateTime()
  if not isAnyActive() then return end

  local now = getTime()

  if active then
    profile.time = profile.time + (now - profile.start_time)
    profile.start_time, profile.dirty = now, true
  end

  local total_time = profile.total_time
  if total_time then
    profile.total_time = total_time + (now - profile.user_start_time)
  else
    -- don't include defer timer interval in single-shot reports
    profile.total_time = profile.time
  end
  profile.user_start_time = now
end

local function sortReport()
  local field = report_columns[state.sort.col + 1].field

  table.sort(profile.report, function(a, b)
    for i = 1, math.max(#a.parents, #b.parents) do
      local l, r = a.parents[i], b.parents[i]
      if not l then return true  end
      if not r then return false end
      if l ~= r then
        -- table.sort is not stable: using id to preserve relative positions
        if l[field] == r[field] then return l.id < r.id end
        if state.sort.dir == ImGui.SortDirection_Ascending() then
          return l[field] < r[field]
        else
          return l[field] > r[field]
        end
      end
    end
    -- assert(a == b)
  end)
end

local function updateReport()
  assert(profile_cur == profile, 'unbalanced enter (missing call to leave)')

  profile.report = { max_depth = 1 }

  local id, parents, flatten = 1, {}, not options.tree_view and {}
  for key, line, depth in eachDeep(profile) do
    if flatten then depth = 1 end
    if depth > profile.report.max_depth then
      profile.report.max_depth = depth
    end

    local frame_source = flatten and profile.frames[key] or line
    local report, is_new = flatten and flatten[key], false
    if report then
      report.count = report.count + line.count
      report.time  = report.time + line.time
      report.time_per_call_min =
        math.min(report.time_per_call_min, line.time_per_call.min)
      report.time_per_call_max =
        math.max(report.time_per_call_max, line.time_per_call.max)
    else
      local location = locations[key]
      local src, src_short, src_line = '<unknown>',  '<unknown>', -1
      if location then
        src = string.gsub(location.source, '^[@=]', '')
        src_short = basename(location.short_src)
        src_line = location.linedefined
      end

      id, report = id + 1, {
        id = id, name = line.name, key = tostring(key), children = 0,
        src = src, src_short = src_short, src_line = src_line,
        time = line.time, count = line.count,
        time_per_call_min = line.time_per_call.min,
        time_per_call_max = line.time_per_call.max,
      }

      parents[depth] = report
      for i = #parents, depth + 1, -1 do parents[i] = nil end
      report.parents = { table.unpack(parents) }

      for i = 1, depth - 1 do
        parents[i].children = parents[i].children + 1
      end

      if flatten then flatten[key] = report end
      profile.report[#profile.report + 1] = report
    end

    local parent = parents[depth - 1]
    local parent_time = parent and parent.time ~= 0 and parent.time or profile.time

    report.time_frac           = report.time / profile.time
    report.time_frac_parent    = report.time / parent_time
    report.time_per_call_avg   = report.time / report.count
    report.frames = frame_source.frames > 0 and frame_source.frames
    report.time_per_frame_min  = frame_source.time_per_frame.min
    report.time_per_frame_max  = frame_source.time_per_frame.max
    report.time_per_frame_avg  = report.frames and report.time / report.frames
    report.calls_per_frame_min = frame_source.calls_per_frame.min
    report.calls_per_frame_max = frame_source.calls_per_frame.max
    report.calls_per_frame_avg = report.frames and report.count // report.frames
  end

  if state.sort.col then sortReport() end
end

local function callLeave(func, ...)
  -- faster than capturing func's return values in a table + table.unpack
  leave(func)
  return ...
end

local function makeWrapper(name, func)
  -- prevent double attachments from showing the wrapper in measurements
  if attachments[func] then return func end
  -- reuse already created wrappers
  local wrapper = wrappers[func]
  if wrapper then return wrapper end

  wrapper = function(...)
    if not active then return func(...) end
    enter(func, name)
    return callLeave(func, func(...))
  end

  attachments[wrapper], wrappers[func] = func, wrapper

  return wrapper
end

local function eachLocals(level, search_above)
  level = level + 1
  local i = 1
  return function()
    while debug.getinfo(level, '') do
      local name, value = debug.getlocal(level, i)
      if name then
        i = i + 1
        return level - 1, i - 1, name, value
      elseif not search_above then
        return
      end
      level, i = level + 1, 1
    end
  end
end

local function getHostVar(path, level)
  assert(type(path) == 'string', 'variable name must be a string')

  local off, sep = 1, string.find(path, '[%.`]')
  local seg = string.sub(path, off, sep and sep - 1)
  local match, local_idx, parent

  for l, i, name, value in eachLocals(level, true) do
    if name == seg then
      level, local_idx, match = l, i, value
      break
    end
  end

  if not match then parent, match = _G, _G[seg] end

  while match and sep do
    local is_special = string.sub(path, sep, sep) ~= '.'

    off = sep + 1
    sep = string.find(path, '[%.`]', off)
    seg = string.sub(path, off, sep and sep - 1)
    local_idx = nil

    if is_special then
      if seg == 'meta' then
        parent, match = nil, getmetatable(match)
      else
        match = nil
        break
      end
    else
      assert(type(match) == 'table',
        string.format('%s is not a table', string.sub(path, 1, sep and sep - 1)))
      parent, match = match, match[seg]
    end
  end

  assert(match, string.format('variable not found: %s',
    string.sub(path, 1, sep and sep - 1)))

  return match, level - 1, local_idx, parent, seg
end

local attachToTable

local function attach(is_attach, name, value, opts, depth, in_metatable)
  -- prevent infinite recursion
  for k, v in pairs(profiler) do
    if value == v then return end
  end

  if opts.metatable then
    local metatable = getmetatable(value)
    if metatable then
      attachToTable(is_attach, name .. '`meta', metatable, opts, depth, true)
    end
  end

  local t = type(value)
  if t == 'function' then
    if is_attach then
      return true, makeWrapper(name, value)
    else
      local original = attachments[value]
      if original then return true, original end
    end
  elseif t == 'table' and depth < 8 and not in_metatable and
      (depth == 0 or (opts.recursive and value ~= _G)) then
    -- don't dig into metatables to avoid listing (for example) string.byte
    -- as some_string_value`meta.__index.byte
    attachToTable(is_attach, name, value, opts, depth + 1)
    return true
  end

  return false
end

attachToTable = function(is_attach, prefix, array, opts, depth, in_metatable)
  assert(type(array) == 'table', string.format('%s is not a table', prefix))

  if array == package.loaded then return end

  for name, value in pairs(array) do
    local path = name
    if prefix then path = string.format('%s.%s', prefix, name) end
    local ok, wrapper = attach(is_attach, path, value, opts, depth, in_metatable)
    if wrapper then array[name] = wrapper end
  end
end

local function attachToLocals(is_attach, opts)
  for level, idx, name, value in eachLocals(3, opts.search_above) do
    local ok, wrapper = attach(is_attach, name, value, opts, 1)
    if wrapper then debug.setlocal(level, idx, wrapper) end
  end
end

local function attachToVar(is_attach, var, opts)
  local val, level, idx, parent, parent_key = getHostVar(var, 4)
  -- start at depth=0 to attach to tables by name with opts.recursion=false
  local ok, wrapper = attach(is_attach, var, val, opts, 0)
  assert(ok, string.format('%s is not %s',
    var, is_attach and 'attachable' or 'detachable'))
  if wrapper then
    if idx then debug.setlocal(level, idx, wrapper) end
    if parent then parent[parent_key] = wrapper end
  end
end

function profiler.attachTo(var, opts)
  attachToVar(true, var, makeAttachOpts(opts))
end

function profiler.detachFrom(var, opts)
  attachToVar(false, var, makeAttachOpts(opts))
end

function profiler.attachToLocals(opts)
  attachToLocals(true, makeAttachOpts(opts))
end

function profiler.detachFromLocals(opts)
  attachToLocals(false, makeAttachOpts(opts))
end

function profiler.attachToWorld()
  local opts = makeAttachOpts()
  attachToLocals(true, opts)
  attachToTable(true, nil, _G, opts, 1)
end

function profiler.detachFromWorld()
  local opts = makeAttachOpts()
  attachToLocals(false, opts)
  attachToTable(false, nil, _G, opts, 1)
end

function profiler.reset()
  profiles[state.current] = {
    time     = 0,
    children = {},
    frames   = {},
    report   = {},
    start_time = active and getTime(),
    -- no need to initialize user_start_time because total_time isn't initialized
  }
  profile, profile_cur = profiles[state.current], profiles[state.current]
end

function profiler.start()
  assert(not active, 'profiler is already active')
  active = true

  -- prevent the garbage collector from affecting measurement repeatability
  collectgarbage('stop')

  local now = getTime()
  profile.start_time = now
  if not profile.user_start_time then
    profile.user_start_time = now
  end
end

function profiler.enter(what)
  if not active then return end
  what = tostring(what)
  enter(what, what)
end

function profiler.leave()
  if active then leave() end
end

function profiler.stop()
  assert(active, 'profiler is not active')
  updateTime() -- before setting active to false
  active = false

  collectgarbage('restart')
end

local function updateFrame(line)
  line.frames = line.frames + 1

  local count = line.count - line.prev_count
  line.prev_count = line.count
  if not line.calls_per_frame.min or count < line.calls_per_frame.min then
    line.calls_per_frame.min = count
  end
  if not line.calls_per_frame.max or count > line.calls_per_frame.max then
    line.calls_per_frame.max = count
  end

  local time = line.time - line.prev_time
  line.prev_time = line.time
  if not line.time_per_frame.min or time < line.time_per_frame.min then
    line.time_per_frame.min = time
  end
  if not line.time_per_frame.max or time > line.time_per_frame.max then
    line.time_per_frame.max = time
  end

  return count, time
end

function profiler.frame()
  assert(not active, 'profiler must be stopped before calling frame')

  for key, line in eachDeep(profile) do
    if line.count > line.prev_count then
      local merged = profile.frames[key]
      if not merged then
        merged = {
          frames = 0,
          count = 0, prev_count = 0,
          time  = 0, prev_time  = 0,
          time_per_frame = {}, calls_per_frame = {},
        }
        profile.frames[key] = merged
      end

      local count, time = updateFrame(line)
      merged.count, merged.time = merged.count + count, merged.time + time
    end
  end

  for key, line in pairs(profile.frames) do
    if line.count > line.prev_count then
      updateFrame(line)
    end
  end

  if state.auto_active > 0 then
    state.auto_active = state.auto_active - 1
  end
end

function profiler.showWindow(ctx, p_open, flags)
  flags = (flags or 0) |
    ImGui.WindowFlags_MenuBar()

  ImGui.SetNextWindowSize(ctx, 850, 500, ImGui.Cond_FirstUseEver())

  local host = select(2, reaper.get_action_context())
  local self = string.sub(debug.getinfo(1, 'S').source, 2)
  local title = string.format('%s - %s', SCRIPT_NAME, basename(host))
  local label = string.format('%s###%s', title, SCRIPT_NAME)

  local can_close, visible = p_open ~= nil
  visible, p_open = ImGui.Begin(ctx, label, p_open, flags)
  if not visible then return p_open end

  if ImGui.BeginMenuBar(ctx) then
    if ImGui.BeginMenu(ctx, 'File') then
      if ImGui.MenuItem(ctx, 'Close', nil, nil, can_close) then
        p_open = false
      end
      ImGui.EndMenu(ctx)
    end
    if ImGui.BeginMenu(ctx, 'Acquisition') then
      local is_active = isAnyActive()
      if ImGui.MenuItem(ctx, 'Start', nil, nil, not is_active) then
        setActiveFromUI(-1)
      end
      if ImGui.BeginMenu(ctx, 'Start for', not is_active) then
        local fps, pattern = 30, { 1, 2, 5 }
        if ImGui.MenuItem(ctx, '    1 frame') then
          setActiveFromUI(1)
        end
        for decade = 0, 1 do
          for i, v in ipairs(pattern) do
            local n = v * (10 ^ decade) * fps | 0
            if ImGui.MenuItem(ctx, ('%5s frames'):format(formatNumber(n))) then
              setActiveFromUI(n)
            end
          end
        end
        ImGui.EndMenu(ctx)
      end
      if ImGui.MenuItem(ctx, 'Stop', nil, nil, is_active) then
        setActiveFromUI(false)
      end
      ImGui.EndMenu(ctx)
    end
    if ImGui.BeginMenu(ctx, 'Profile') then
      local has_data = profile.start_time ~= nil
      if ImGui.MenuItem(ctx, 'Tree view', nil, options.tree_view) then
        options.tree_view, profile.dirty = not options.tree_view, true
      end
      if ImGui.MenuItem(ctx, 'Reset', nil, nil, has_data) then
        profiler.reset()
      end
      ImGui.EndMenu(ctx)
    end
    if ImGui.BeginMenu(ctx, 'Help', reaper.CF_ShellExecute ~= nil) then
      if ImGui.MenuItem(ctx, 'Donate...') then
        reaper.CF_ShellExecute('https://reapack.com/donate')
      end
      if ImGui.MenuItem(ctx, 'Forum thread') then
        reaper.CF_ShellExecute('https://forum.cockos.com/showthread.php?t=283461')
      end
      ImGui.EndMenu(ctx)
    end
    local fps = string.format('%04.01f FPS##fps', ImGui.GetFramerate(ctx))
    alignNextItemRight(ctx, fps, true)
    state.show_metrics =
      select(2, ImGui.MenuItem(ctx, fps, nil, state.show_metrics))
    ImGui.EndMenuBar(ctx)
  end

  if state.show_metrics then
    state.show_metrics = ImGui.ShowMetricsWindow(ctx, true)
  end

  if state.want_activate then
    ImGui.OpenPopup(ctx, 'Frame measurement')
  end
  centerNextWindow(ctx)
  if ImGui.BeginPopupModal(ctx, 'Frame measurement', true,
      ImGui.WindowFlags_AlwaysAutoResize()) then
    ImGui.Text(ctx,
      'Frame measurement requires usage of a proxy defer function.')
    ImGui.Spacing(ctx)

    ImGui.Text(ctx, 'The following measurements are affected:')
    ImGui.Bullet(ctx); ImGui.Text(ctx, 'Active time')
    ImGui.Bullet(ctx); ImGui.Text(ctx, 'Frame count')
    ImGui.Bullet(ctx); ImGui.Text(ctx, 'Time per frame (min/avg/max)')
    ImGui.Bullet(ctx); ImGui.Text(ctx, 'Calls per frame (min/avg/max)')
    ImGui.Spacing(ctx)

    ImGui.Text(ctx,
      'Add the following snippet to the host script:')
    if ImGui.IsWindowAppearing(ctx) then
      ImGui.SetKeyboardFocusHere(ctx)
    end
    local snippet = 'reaper.defer = profiler.defer'
    ImGui.InputTextMultiline(ctx, '##snippet', snippet,
      -FLT_MIN, ImGui.GetFontSize(ctx) * 3, ImGui.InputTextFlags_ReadOnly())
    ImGui.Spacing(ctx)

    ImGui.Text(ctx, 'Do you wish to enable acquisition anyway?')
    ImGui.Spacing(ctx)

    ImGui.BeginDisabled(ctx, state.want_activate > 0)
    if ImGui.Button(ctx, 'Continue') then
      setActive(state.want_activate)
      state.want_activate = nil
      ImGui.CloseCurrentPopup(ctx)
    end
    ImGui.EndDisabled(ctx)
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Inject proxy and continue') then
      _G['reaper'].defer, state.defer_called = profiler.defer, true
      setActive(state.want_activate)
      state.want_activate = nil
      ImGui.CloseCurrentPopup(ctx)
    end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Cancel') then
      state.want_activate = nil
      ImGui.CloseCurrentPopup(ctx)
    end
    ImGui.EndPopup(ctx)
  end

  if ImGui.IsWindowFocused(ctx) then
    ImGui.SetNextWindowFocus(ctx)
  end
  profiler.showProfile(ctx, 'report', 0, 0)

  ImGui.End(ctx)
  return p_open
end

function profiler.showProfile(ctx, label, width, height)
  if not ImGui.BeginChild(ctx, label, width, height) then return end

  if ImGui.IsWindowAppearing(ctx) then
    ImGui.SetKeyboardFocusHere(ctx)
  end
  if ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_ChildWindows()) then
    local key_0, pad_0 = ImGui.Key_0(), ImGui.Key_Keypad0()
    for i = 1, PROFILES_SIZE do
      if ImGui.IsKeyPressed(ctx, key_0 + i) or
          ImGui.IsKeyPressed(ctx, pad_0 + i) then
        setCurrentProfile(i)
      end
    end
  end

  updateTime() -- may set dirty
  if profile.dirty then
    updateReport()
    profile.dirty = false
  end

  local summary = string.format('Active time / wall time: %s / %s (%.02f%%)',
    formatTime(profile.time, false), formatTime(profile.total_time or 0, false),
    (profile.time / (profile.total_time or 1)) * 100)
  ImGui.Text(ctx, summary)
  if isAnyActive() then
    ImGui.SameLine(ctx, nil, 0)
    ImGui.Text(ctx, string.format('%-3s',
      string.rep('.', ImGui.GetTime(ctx) // 1 % 3 + 1)))
  end
  ImGui.SameLine(ctx)

  local export = false
  alignGroupRight(ctx, function()
    for i = 1, PROFILES_SIZE do
      if i > 1 then ImGui.SameLine(ctx, nil, 4) end
      local was_current = i == state.current
      if was_current then
        ImGui.PushStyleColor(ctx, ImGui.Col_Button(),
          ImGui.GetStyleColor(ctx, ImGui.Col_HeaderActive()))
      end
      if ImGui.SmallButton(ctx, i) then
        setCurrentProfile(i)
      end
      if was_current then
        ImGui.PopStyleColor(ctx)
      end
    end
    ImGui.SameLine(ctx)
    if ImGui.SmallButton(ctx, 'Copy to clipboard') then
      export = true
      ImGui.LogToClipboard(ctx)
      ImGui.LogText(ctx, summary .. '\n\n')
    end
  end, true)
  ImGui.Spacing(ctx)

  if state.scroll_to_top then
    ImGui.SetNextWindowScroll(ctx, 0, 0)
    state.scroll_to_top = false
  end
  local flags = ImGui.TableFlags_SizingFixedFit()                 |
    ImGui.TableFlags_Resizable() | ImGui.TableFlags_Reorderable() |
    ImGui.TableFlags_Hideable()  | ImGui.TableFlags_Sortable()    |
    ImGui.TableFlags_ScrollX()   | ImGui.TableFlags_ScrollY()     |
    ImGui.TableFlags_Borders()   | ImGui.TableFlags_RowBg()
  if not ImGui.BeginTable(ctx, 'table', 17, flags) then
    return ImGui.EndChild(ctx)
  end

  ImGui.TableSetupScrollFreeze(ctx, 0, 1)
  for i, column in ipairs(report_columns) do
    ImGui.TableSetupColumn(ctx, column.name, column.flags, column.width)
  end
  ImGui.TableHeadersRow(ctx)

  if ImGui.TableNeedSort(ctx) then
    local ok, id, col, order, dir =
      ImGui.TableGetColumnSortSpecs(ctx, 0)
    if ok and (col ~= state.sort.col or dir ~= state.sort.dir) then
      state.sort = { col = col, dir = dir }
      sortReport()
    end
  end

  local tree_node_flags = ImGui.TreeNodeFlags_SpanFullWidth() |
    ImGui.TreeNodeFlags_DefaultOpen() | ImGui.TreeNodeFlags_FramePadding()
  local tree_node_leaf_flags = tree_node_flags |
    ImGui.TreeNodeFlags_Leaf() | ImGui.TreeNodeFlags_NoTreePushOnOpen()

  local i, prev_depth, cut_src_cache = 1, 1, {}
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding(), 1, 1)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_IndentSpacing(), 12)
  while i <= #profile.report do
    local line = profile.report[i]

    for i = #line.parents, prev_depth - 1 do ImGui.TreePop(ctx) end
    prev_depth = #line.parents

    ImGui.TableNextRow(ctx)

    ImGui.TableNextColumn(ctx)
    if profile.report.max_depth > 1 then
      if line.children > 0 then
        if not ImGui.TreeNodeEx(ctx, line.key, line.name, tree_node_flags) then
          i = i + line.children
        end
        tooltip(ctx, string.format('%s (%d children)',
          line.name, formatNumber(line.children)))
      else
        ImGui.TreeNodeEx(ctx, line.key, line.name, tree_node_leaf_flags)
        tooltip(ctx, line.name)
      end
    else
      ImGui.AlignTextToFramePadding(ctx)
      textCell(ctx, line.name, false)
    end

    ImGui.TableNextColumn(ctx)
    local src_short = cut_src_cache[line.src_short]
    if not src_short then
      src_short = ellipsis(ctx, line.src_short)
      cut_src_cache[line.src_short] = src_short
    end
    textCell(ctx, src_short, false, line.src)

    for j, col in ipairs(report_columns) do
      local v = line[col.field]
      if v and col.func then
        ImGui.TableNextColumn(ctx)
        local flags = ImGui.TableGetColumnFlags(ctx)
        if flags & ImGui.TableColumnFlags_IsVisible() ~= 0 then
          col.func(ctx, col.fmt and col.fmt(v) or v)
        end
      end
    end

    i = i + 1
  end
  for i = 2, prev_depth do ImGui.TreePop(ctx) end
  ImGui.PopStyleVar(ctx, 2)
  ImGui.EndTable(ctx)

  if export then ImGui.LogFinish(ctx) end

  ImGui.EndChild(ctx)
end

function profiler.defer(callback)
  state.defer_called = true

  return reaper.defer(function()
    if state.auto_active == 0 then return callback() end
    state.defer_called = false
    profiler.start()
    callback()
    profiler.stop()
    profiler.frame()
  end)
end

function profiler.run()
  if state.run_called then return end
  state.run_called = true
  local ctx = ImGui.CreateContext(SCRIPT_NAME)
  local function loop()
    if profiler.showWindow(ctx, true) then
      reaper.defer(loop)
    else
      state.run_called = false
    end
  end
  reaper.defer(loop)
end

setmetatable(profiler, {
  __index = function(profiler, key)
    if key == 'auto_start' then
      return state.auto_active
    end
  end,
  __newindex = function(profiler, key, value)
    if key == 'auto_start' then
      setActive(value, true)
    else
      rawset(profiler, key, value)
    end
  end,
})

profiler.reset()

-- if not CF_PROFILER_SELF then
--   CF_PROFILER_SELF = true
--   local self_profile = dofile(debug.getinfo(1, 'S').source:sub(2))
--   CF_PROFILER_SELF = nil
--   reaper.defer = self_profile.defer
--   self_profile.attachToLocals({ search_above = false })
--   self_profile.run()
-- end

return profiler

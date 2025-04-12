-- @description Lua profiler
-- @author cfillion
-- @version 1.1.5
-- @changelog • Fix tree display mode when there are over 999 children
-- @provides [nomain] .
-- @link Forum thread https://forum.cockos.com/showthread.php?t=283461
-- @screenshot
--   https://i.imgur.com/cCe6fBB.png
--   https://i.imgur.com/FjbZ6VB.gif
-- @donation https://reapack.com/donate
-- @about
--   # Lua profiler
--
--   This is a library for helping the development of Lua ReaScript. See the [forum thread](https://forum.cockos.com/showthread.php?t=283461) for usage information. A summary of the provided API is at the top of the source code.

-- Public API summary:
--
-- local profiler = dofile(reaper.GetResourcePath() ..
--   '/Scripts/ReaTeam Scripts/Development/cfillion_Lua profiler.lua')
--
-- # General
-- * profiler.clear()
-- * profiler.defer(function callback) and alias profiler.runloop
-- * profiler.run()
--
-- # Instrumentation (see `makeAttachOpts` for supported options)
-- * profiler.attachTo(string var, nil|table opts)
-- * profiler.detachFrom(string var, nil|table opts)
-- * profiler.attachToLocals(nil|table opts)
-- * profiler.detachFromLocals(nil|table opts)
-- * profiler.attachToWorld()
-- * profiler.detachFromWorld()
--
-- # Acquisition
-- * profiler.start()
-- * profiler.stop()
-- * nil|bool|integer profiler.auto_start
--
-- # Measurement
-- * profiler.enter(string what)
-- * profiler.leave()
-- * profiler.frame()
--
-- # Embedding
-- * profiler.showWindow(ImGui_Context* ctx, nil|bool p_open, nil|integer window_flags)
-- * profiler.showProfile(ImGui_Context* ctx, string label, nil|number width, nil|number height, nil|integer child_flags)

local ImGui = (function()
  local host_reaper = reaper
  reaper = {}
  for k,v in pairs(host_reaper) do reaper[k] = v end
  local ImGui = dofile(reaper.ImGui_GetBuiltinPath() .. '/imgui.lua') '0.9'
  reaper = host_reaper
  return ImGui
end)()

local SCRIPT_NAME, EXT_STATE_ROOT = 'Lua profiler', 'cfillion_Lua profiler'
local FLT_MIN = ImGui.NumericLimits_Float()
local PROFILES_SIZE = 8

-- 'active' is not in 'state' for faster access
local profiler, profiles, active, state = {}, {}, false, {
  current = 1, auto_active = 0, sort = {}, zoom = 1,
}
local attachments, wrappers, locations = {}, {}, {}
local getTime = reaper.time_precise -- faster than os.clock
local profile, profile_cur -- references to profiles[current] for quick access
local options, options_cache, options_default = {}, {}, {
  view = 1, -- tree view
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
    if v == nil then error('option does not exist', 2) end
    if not reaper.HasExtState(EXT_STATE_ROOT, key) then
      reaper.SetExtState(EXT_STATE_ROOT, key, tostring(v), true)
    else
      local t = type(v)
      v = reaper.GetExtState(EXT_STATE_ROOT, key)
      if t == 'boolean' then
        v = v == 'true'
      elseif t == 'number' then
        v = tonumber(v) or 0
      elseif t ~= 'string' then
        error('unsupported type', 2)
      end
    end
    options_cache[key] = v
    return v
  end,
  __newindex = function(options, key, value)
    if type(value) ~= type(options_default[key]) then
      error('unexpected value type', 2)
    end
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
  ImGui.SetNextWindowPos(ctx, center_x, center_y, ImGui.Cond_Appearing, 0.5, 0.5)
end

local function alignNextItemRight(ctx, label, spacing)
  local item_spacing_w = spacing and
    ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing) or 0
  local want_pos_x = ImGui.GetScrollX(ctx) +
    ImGui.GetContentRegionMax(ctx) - item_spacing_w -
    ImGui.CalcTextSize(ctx, label, nil, nil, true)
  if want_pos_x > ImGui.GetCursorPosX(ctx) then
    ImGui.SetCursorPosX(ctx, want_pos_x)
  end
end

local function alignGroupRight(ctx, callback)
  local pos_x, right_x = ImGui.GetCursorPosX(ctx), ImGui.GetContentRegionMax(ctx)

  ImGui.SetCursorPosX(ctx, 0)
  ImGui.BeginGroup(ctx)
  ImGui.PushID(ctx, 'width')
  ImGui.PushClipRect(ctx, 0, 0, 1, 1, false)
  callback()
  ImGui.PopClipRect(ctx)
  ImGui.PopID(ctx)
  ImGui.EndGroup(ctx)

  local want_x = right_x - ImGui.GetItemRectSize(ctx)
  if want_x >= pos_x then
    ImGui.SameLine(ctx)
    ImGui.SetCursorPosX(ctx, want_x)
  end

  ImGui.BeginGroup(ctx)
  callback()
  ImGui.EndGroup(ctx)
end

local function tooltip(ctx, text)
  if not ImGui.BeginItemTooltip(ctx) then return end
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
  local no_hide       = ImGui.TableColumnFlags_NoHide
  local def_sort_desc = ImGui.TableColumnFlags_PreferSortDescending
  local def_hide      = ImGui.TableColumnFlags_DefaultHide
  local frac_flags    = def_sort_desc | ImGui.TableColumnFlags_WidthStretch
  return {
    { name = 'Name',   field = 'name', width = 227, flags = no_hide },
    { name = 'Source', field = 'src',  width = 132 },
    { name = 'Line',   field = 'src_line', func = textCell, },
    { name = '% of total',  field = 'time_frac',
      func = progressBar, flags = frac_flags            },
    { name = '% of parent', field = 'time_frac_parent',
      func = progressBar, flags = frac_flags | def_hide },
    { name = 'Time',   field = 'time', func = textCell, fmt   = formatTime,
      flags = def_sort_desc | ImGui.TableColumnFlags_DefaultSort              },
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
    error('unbalanced leave (missing call to enter)', 3)
  end

  local time = now - profile_cur.enter_time
  local time_per_call = profile_cur.time_per_call
  if not time_per_call.min or time < time_per_call.min then
    time_per_call.min = time
  end
  if not time_per_call.max or time > time_per_call.max then
    time_per_call.max = time
  end
  profile_cur.time = profile_cur.time + time
  profile_cur = profile_cur.parent
end

local function isAnyActive()
  return active or state.auto_active ~= 0
end

local function setActive(frame_count, force_auto)
  if frame_count == true then frame_count = -1
  elseif not frame_count then frame_count = 0 end
  if type(frame_count) ~= 'number' then
    error('value must be nil, a boolean, or an integer', 3)
  end
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
        if state.sort.dir == ImGui.SortDirection_Ascending then
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

  if profile.dirty then
    profile.dirty = false
  else
    return
  end

  profile.report = { max_depth = 1 }

  local id, parents, flatten = 1, {}, options.view == 0 and {}
  local flame_graph = options.view == 2
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

      local subtree
      if flame_graph then
        subtree = profile.report[depth]
        if not subtree then
          subtree = {}
          profile.report[depth] = subtree
        end
      else
        subtree = profile.report
      end

      subtree[#subtree + 1] = report
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

  if flame_graph then
    local field = 'time_frac'
    for i = 1, #profile.report do
      table.sort(profile.report[i], function(a, b)
        if i > 1 then
          local parent_a, parent_b = a.parents[i - 1], b.parents[i - 1]
          if parent_a[field] < parent_b[field] then
            return false
          elseif parent_a[field] > parent_b[field] then
            return true
          end
        end
        if parent_a == parent_b then
          if a[field] == b[field] then return a.id < b.id end -- for stability
          return a[field] > b[field]
        end
      end)
    end
  elseif state.sort.col then
    sortReport()
  end
end

local function setCurrentProfile(i)
  local now = getTime()

  state.current = i
  if not profiles[i] then
    profiler.clear()
  else
    profile, profile_cur = profiles[i], profiles[i]
  end

  if active then
    profile.start_time, profile.user_start_time = now, now
  elseif state.auto_active ~= 0 then
    profile.user_start_time = now
  end

  profile.dirty = true -- always refresh to apply new display and sort options
  updateReport()       -- refresh now to avoid 1-frame flicker

  state.set_scroll, state.zoom = { 0, 0 }, 1
end

local function callLeave(...)
  -- faster than capturing func's return values in a table + table.unpack
  leave()
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
    return callLeave(func(...))
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
  if type(path) ~= 'string' then
    error('variable name must be a string', level)
  end

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
    elseif type(match) ~= 'table' then
      error(string.format('%s is not a table', string.sub(path, 1, off - 2)), level)
    else
      parent, match = match, match[seg]
    end
  end

  if not match then
    error(string.format('variable not found: %s',
      string.sub(path, 1, sep and sep - 1)), level)
  end

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
  elseif t == 'table' and #depth < 8 and not in_metatable and
      (#depth == 0 or (opts.recursive and value ~= _G)) then
    -- don't dig into metatables to avoid listing (for example) string.byte
    -- as some_string_value`meta.__index.byte
    depth[#depth + 1] = value
    attachToTable(is_attach, name, value, opts, depth)
    depth[#depth] = nil
    return true
  end

  return false
end

attachToTable = function(is_attach, prefix, array, opts, depth, in_metatable)
  assert(type(array) == 'table', string.format('%s is not a table', prefix))

  if array == package.loaded then return end

  for name, value in pairs(array) do
    -- prevent `foo.bar = foo` from displaying foo.bar.bar.bar.bar.bar.bar.baz
    local is_repeat = false
    for i, parent in ipairs(depth) do
      if parent == value then
        is_repeat = true
        break
      end
    end
    if not is_repeat then
      local path = name
      if prefix then path = string.format('%s.%s', prefix, name) end
      local ok, wrapper = attach(is_attach, path, value, opts, depth, in_metatable)
      if wrapper then array[name] = wrapper end
    end
  end
end

local function attachToLocals(is_attach, opts)
  for level, idx, name, value in eachLocals(3, opts.search_above) do
    local ok, wrapper = attach(is_attach, name, value, opts, {value})
    if wrapper then debug.setlocal(level, idx, wrapper) end
  end
end

local function attachToVar(is_attach, var, opts)
  local val, level, idx, parent, parent_key = getHostVar(var, 4)
  -- start at #depth==0 to attach to tables by name with opts.recursion=false
  local ok, wrapper = attach(is_attach, var, val, opts, {})
  if not ok then
    error(string.format('%s is not %s',
      var, is_attach and 'attachable' or 'detachable'), 3)
  end
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
  attachToTable(true, nil, _G, opts, {_G})
end

function profiler.detachFromWorld()
  local opts = makeAttachOpts()
  attachToLocals(false, opts)
  attachToTable(false, nil, _G, opts, {_G})
end

function profiler.clear()
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
  if active then
    error('profiler is already active', 2)
  end
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
  if profile_cur ~= profile then
    error('unbalanced enter (missing call to leave)', 2)
  elseif not active then
    error('profiler is not active', 2)
  end
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
  if active then
    error('profiler must be stopped before calling frame', 2)
  end

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
  flags = (flags or 0) | ImGui.WindowFlags_MenuBar

  ImGui.SetNextWindowSize(ctx, 850, 500, ImGui.Cond_FirstUseEver)

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
      if ImGui.MenuItem(ctx, 'Flat list', nil, options.view == 0) then
        options.view, profile.dirty = 0, true
      end
      if ImGui.MenuItem(ctx, 'Tree view', nil, options.view == 1) then
        options.view, profile.dirty = 1, true
      end
      if ImGui.MenuItem(ctx, 'Flame graph', nil, options.view == 2) then
        options.view, profile.dirty = 2, true
      end
      ImGui.Separator(ctx)
      if ImGui.MenuItem(ctx, 'Clear', nil, nil, has_data) then
        profiler.clear()
      end
      ImGui.EndMenu(ctx)
    end
    if ImGui.BeginMenu(ctx, 'Help', reaper.CF_ShellExecute ~= nil) then
      if ImGui.MenuItem(ctx, 'Forum thread') then
        reaper.CF_ShellExecute('https://forum.cockos.com/showthread.php?t=283461')
      end
      if ImGui.MenuItem(ctx, 'Donate...') then
        reaper.CF_ShellExecute('https://reapack.com/donate')
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
      ImGui.WindowFlags_AlwaysAutoResize) then
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
    local snippet = '\z
      reaper.defer   = profiler.defer\n\z
      reaper.runloop = profiler.runloop'
    ImGui.InputTextMultiline(ctx, '##snippet', snippet,
      -FLT_MIN, ImGui.GetFontSize(ctx) * 3, ImGui.InputTextFlags_ReadOnly)
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
      _G['reaper'].defer, _G['reaper'].runloop = profiler.defer, profiler.runloop
      state.defer_called = true
      setActive(state.want_activate) -- reads defer_called and sets want_activate
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

local function tableView(ctx)
  local flags = ImGui.TableFlags_SizingFixedFit               |
    ImGui.TableFlags_Resizable | ImGui.TableFlags_Reorderable |
    ImGui.TableFlags_Hideable  | ImGui.TableFlags_Sortable    |
    ImGui.TableFlags_ScrollX   | ImGui.TableFlags_ScrollY     |
    ImGui.TableFlags_Borders   | ImGui.TableFlags_RowBg
  if not ImGui.BeginTable(ctx, 'table', 17, flags) then return end

  ImGui.TableSetupScrollFreeze(ctx, 0, 1)
  for i, column in ipairs(report_columns) do
    ImGui.TableSetupColumn(ctx, column.name, column.flags, column.width)
  end
  ImGui.TableHeadersRow(ctx)

  if ImGui.TableNeedSort(ctx) then
    local ok, col, user_col, dir = ImGui.TableGetColumnSortSpecs(ctx, 0)
    if ok and (col ~= state.sort.col or dir ~= state.sort.dir) then
      state.sort = { col = col, dir = dir }
      sortReport()
    end
  end

  local tree_node_flags = ImGui.TreeNodeFlags_SpanAllColumns |
    ImGui.TreeNodeFlags_DefaultOpen | ImGui.TreeNodeFlags_FramePadding
  local tree_node_leaf_flags = tree_node_flags |
    ImGui.TreeNodeFlags_Leaf | ImGui.TreeNodeFlags_NoTreePushOnOpen

  local i, prev_depth, cut_src_cache = 1, 1, {}
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 1, 1)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_IndentSpacing, 12)
  while i <= #profile.report do
    local line = profile.report[i]

    for j = #line.parents, prev_depth - 1 do ImGui.TreePop(ctx) end
    prev_depth = #line.parents

    ImGui.TableNextRow(ctx)

    ImGui.TableNextColumn(ctx)
    if profile.report.max_depth > 1 then
      local tooltip_text
      if line.children > 0 then
        if not ImGui.TreeNodeEx(ctx, line.key, line.name, tree_node_flags) then
          i = i + line.children
        end
        tooltip_text = string.format('%s (%s children)',
          line.name, formatNumber(line.children))
      else
        ImGui.TreeNodeEx(ctx, line.key, line.name, tree_node_leaf_flags)
        tooltip_text = line.name
      end
      local flags = ImGui.TableGetColumnFlags(ctx)
      if (flags & ImGui.TableColumnFlags_IsHovered) ~= 0 then
        tooltip(ctx, tooltip_text)
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
        if flags & ImGui.TableColumnFlags_IsVisible ~= 0 then
          col.func(ctx, col.fmt and col.fmt(v) or v)
        end
      end
    end

    i = i + 1
  end
  for i = 2, prev_depth do ImGui.TreePop(ctx) end
  ImGui.PopStyleVar(ctx, 2)
  ImGui.EndTable(ctx)
end

local function setZoom(ctx, zoom, scroll_x, avail_w)
  zoom = math.max(1, math.min(512, zoom))
  if state.zoom == zoom then return end

  if avail_w then
    local new_w = (avail_w * zoom) // 1
    state.set_content_size = { new_w, 0 }
  end

  if type(scroll_x) == 'number' then
    scroll_x = scroll_x * zoom
  elseif scroll_x then
    local mouse_x = ImGui.GetMousePos(ctx) -
      ImGui.GetWindowPos(ctx) - ImGui.GetCursorStartPos(ctx)
    scroll_x = ImGui.GetScrollX(ctx) + ((mouse_x * (zoom / state.zoom)) - mouse_x)
  end
  if scroll_x then
    state.set_scroll = { scroll_x // 1, -1 }
  end

  state.zoom = zoom
end

local function reportLineTooltip(ctx, line)
  ImGui.SetNextWindowSize(ctx, 300, 0)
  if not ImGui.BeginItemTooltip(ctx) then return end
  if not ImGui.BeginTable(ctx, 'tooltip', 2) then
    ImGui.EndTooltip(ctx)
    return
  end

  local stats = {}
  ImGui.TableSetupColumn(ctx, 'key', ImGui.TableColumnFlags_WidthFixed)
  ImGui.TableSetupColumn(ctx, 'value', ImGui.TableColumnFlags_WidthStretch)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 0, 0)
  for j, col in ipairs(report_columns) do
    local stat_which, stat_name = col.name:match('^(.-)(./.-)$')
    local v, show = nil, false
    if col.field == 'src' then
      v, show = line.src_short .. ':' .. line.src_line, true
    elseif stat_which then
      local stat = stats[#stats]
      if not stat or stat.name ~= stat_name then
        stat = { name = stat_name }
        stats[#stats + 1] = stat
      end
      stat[#stat + 1] = { which = stat_which, line = line, col = col }
    elseif col.field ~= 'src_line' then
      v, show = line[col.field], true
    end
    if show then
      ImGui.TableNextRow(ctx)
      ImGui.TableNextColumn(ctx)
      textCell(ctx, col.name .. ':')
      if v then
        ImGui.TableNextColumn(ctx)
        if col.fmt then v = col.fmt(v) end
        (col.func or ImGui.TextWrapped)(ctx, v)
      end
    end
  end

  ImGui.TableNextRow(ctx)
  ImGui.TableSetColumnIndex(ctx, 1)
  if ImGui.BeginTable(ctx, 'stats', 3,
      ImGui.TableFlags_Borders | ImGui.TableFlags_SizingStretchSame) then
    for _, val in ipairs(stats[1]) do
      ImGui.TableSetupColumn(ctx, val.which)
    end
    ImGui.TableHeadersRow(ctx)
    for _, stat in ipairs(stats) do
      ImGui.TableNextRow(ctx)
      stat.y = ImGui.GetCursorPosY(ctx)
      for _, val in ipairs(stat) do
        ImGui.TableNextColumn(ctx)
        local v = val.line[val.col.field]
        if v then
          val.col.func(ctx, val.col.fmt(v))
        else
          ImGui.NewLine(ctx)
        end
      end
    end
    ImGui.EndTable(ctx)
  end
  ImGui.TableNextColumn(ctx)
  for _, stat in ipairs(stats) do
    ImGui.SetCursorPosY(ctx, stat.y)
    textCell(ctx, stat.name .. ':')
  end

  ImGui.PopStyleVar(ctx)
  ImGui.EndTable(ctx)
  ImGui.EndTooltip(ctx)
end

local function flameGraph(ctx)
  local is_zooming = ImGui.GetKeyMods(ctx) & ~ImGui.Mod_Shift ~= 0
  local window_flags = ImGui.WindowFlags_HorizontalScrollbar
  if is_zooming then
    window_flags = window_flags | ImGui.WindowFlags_NoScrollWithMouse
  end

  if not ImGui.BeginChild(ctx, 'graph', 0, 0,
    ImGui.ChildFlags_Border, window_flags) then return end
  local draw_list, border_color = ImGui.GetWindowDrawList(ctx), 0x566683FF
  local tiny_w, avail_w, zoom = 2, ImGui.GetContentRegionAvail(ctx), state.zoom
  if state.did_set_content_size then avail_w = math.ceil(avail_w / zoom) end
  ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0x23446CFF)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)
  if state.prev_flame_w and state.prev_flame_w ~= avail_w and state.zoom > 1 then
    local want_zoom = state.zoom * (state.prev_flame_w / avail_w)
    setZoom(ctx, want_zoom)
    zoom = state.zoom
    if zoom ~= want_zoom then
      local scroll_x = ImGui.GetScrollX(ctx)
      local new_scroll = scroll_x * (zoom / want_zoom)
      ImGui.SetScrollX(ctx, new_scroll) -- unavoidable flicker
    end
  end
  state.prev_flame_w = avail_w
  for i = 1, #profile.report do
    local level = profile.report[i]
    local first_of_line, prev_parent = true, nil
    local x, start_x = 0, ImGui.GetCursorPosX(ctx)
    local visible_x = ImGui.GetScrollX(ctx) + start_x
    for j = 1, #level do
      local item = level[j]
      ImGui.PushID(ctx, item.id)

      if first_of_line then
        first_of_line = false
      else
        ImGui.SameLine(ctx)
      end

      local parent = item.parents[i - 1]
      local parent_w = parent and parent.w or avail_w
      if parent and prev_parent ~= parent then x = parent.x end
      item.x, item.w = x, parent_w * item.time_frac_parent

      local display_x = start_x + (x * zoom) // 1
      local display_w = math.max(1, item.w * zoom) // 1

      -- move the labels at the center of the view
      if display_x <= visible_x then
        local old_display_x = display_x
        display_x = math.max(display_x, visible_x - start_x)
        display_w = math.max(1, display_w - (display_x - old_display_x))
      end
      if display_x + display_w >= visible_x + avail_w then
        local offset_x = math.max(0, display_x - visible_x)
        display_w = math.min(display_w, (avail_w - offset_x) + (start_x * 2))
        display_w = math.max(1, display_w)
      end

      ImGui.SetCursorPosX(ctx, display_x)
      if display_w < tiny_w then
        ImGui.PushStyleColor(ctx, ImGui.Col_Button, border_color)
        ImGui.SetNextItemAllowOverlap(ctx)
      end
      if ImGui.Button(ctx, item.name, display_w) then
        setZoom(ctx, avail_w / item.w, item.x, avail_w)
        ImGui.SetScrollHereY(ctx, 0)
      end
      if display_w < tiny_w then
        ImGui.PopStyleColor(ctx)
      else
        -- not using StyleVar_FrameBorderSize to collapse borders
        -- border color cannot have alpha because it's partially over buttons
        local x1, y1 = ImGui.GetItemRectMin(ctx)
        local x2, y2 = ImGui.GetItemRectMax(ctx)
        ImGui.DrawList_AddRect(draw_list, x1, y1, x2 + 1, y2 + 1, border_color)
      end

      reportLineTooltip(ctx, item)

      prev_parent = parent
      x = x + item.w
      ImGui.PopID(ctx)
    end

    if i == 1 then
      local full_w = (avail_w * zoom) // 1
      local idle_w = full_w - (x * zoom) // 1
      if idle_w > 0 then
        ImGui.SameLine(ctx)
        ImGui.SetCursorPosX(ctx, start_x + (x * zoom) // 1)
        ImGui.Dummy(ctx, idle_w, 1)
      end
    end
  end
  ImGui.PopStyleVar(ctx)
  ImGui.PopStyleColor(ctx)

  if is_zooming and ImGui.IsWindowHovered(ctx) then
    local mouse_wheel = ImGui.GetMouseWheel(ctx) / 48
    if mouse_wheel ~= 0 then
      setZoom(ctx, zoom * (1 + mouse_wheel), true, avail_w)
    end
  end

  ImGui.EndChild(ctx)
end

function profiler.showProfile(ctx, label, width, height, child_flags)
  if not ImGui.BeginChild(ctx, label, width, height, child_flags) then return end

  updateTime() -- may set dirty
  updateReport()

  if ImGui.IsWindowAppearing(ctx) then
    ImGui.SetKeyboardFocusHere(ctx)
  end
  if ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_ChildWindows) then
    local key_0, pad_0 = ImGui.Key_0, ImGui.Key_Keypad0
    for i = 1, PROFILES_SIZE do
      if ImGui.IsKeyPressed(ctx, key_0 + i) or
          ImGui.IsKeyPressed(ctx, pad_0 + i) then
        setCurrentProfile(i)
      end
    end
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
        ImGui.PushStyleColor(ctx, ImGui.Col_Button,
          ImGui.GetStyleColor(ctx, ImGui.Col_HeaderActive))
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
  end)
  ImGui.Spacing(ctx)

  if state.set_content_size then
    ImGui.SetNextWindowContentSize(ctx, table.unpack(state.set_content_size))
    state.set_content_size = nil
    state.did_set_content_size = true
  elseif state.did_set_content_size then
    state.did_set_content_size = false
  end
  if state.set_scroll then
    ImGui.SetNextWindowScroll(ctx, table.unpack(state.set_scroll))
    state.set_scroll = nil
  end

  (options.view == 2 and flameGraph or tableView)(ctx)

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

profiler.runloop = profiler.defer

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

profiler.clear()

-- if not CF_PROFILER_SELF then
--   CF_PROFILER_SELF = true
--   local self_profiler = dofile(debug.getinfo(1, 'S').source:sub(2))
--   CF_PROFILER_SELF = nil
--   reaper.defer = self_profiler.defer
--   self_profiler.attachToLocals({ search_above = false })
--   self_profiler.run()
-- end

return profiler

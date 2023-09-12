-- @description Snapshooter
-- @author tilr
-- @version 1.0
-- @provides
--   tilr_Snapshooter/rtk.lua
--   [main] tilr_Snapshooter/tilr_Snapshooter apply snap 1.lua
--   [main] tilr_Snapshooter/tilr_Snapshooter apply snap 2.lua
--   [main] tilr_Snapshooter/tilr_Snapshooter apply snap 3.lua
--   [main] tilr_Snapshooter/tilr_Snapshooter apply snap 4.lua
--   [main] tilr_Snapshooter/tilr_Snapshooter save snap 1.lua
--   [main] tilr_Snapshooter/tilr_Snapshooter save snap 2.lua
--   [main] tilr_Snapshooter/tilr_Snapshooter save snap 3.lua
--   [main] tilr_Snapshooter/tilr_Snapshooter save snap 4.lua
--   [main] tilr_Snapshooter/tilr_Snapshooter write snap 1.lua
--   [main] tilr_Snapshooter/tilr_Snapshooter write snap 2.lua
--   [main] tilr_Snapshooter/tilr_Snapshooter write snap 3.lua
--   [main] tilr_Snapshooter/tilr_Snapshooter write snap 4.lua
-- @screenshot https://raw.githubusercontent.com/tiagolr/snapshooter/master/doc/snapshooter.gif
-- @about
--   # Snapshooter
--
--   https://github.com/tiagolr/snapshooter
--
--   Snapshooter allows to create param snapshots and recall or write them to the playlist creating patch morphs.
--   Different from SWS snapshots, only the params changed are written to the playlist as automation points.
--
--   Features:
--     * Stores and retrieves FX params
--     * Stores and retrieves mixer states for track Volume, Pan, Mute and Sends
--     * Writes only changed params by diffing the current state and selected snapshot
--     * Transition snapshots using tween and ease functions
--     * Tested with hundreds of params with minimal overhead
--
--   Tips:
--     * Set global automation to _READ_ to save current song snapshot
--     * Set global automation to other value than _READ_ to save snapshots from mixer state
--     * If params are not writing make sure they have a different current value from the snapshot

function log(t)
  reaper.ShowConsoleMsg(t .. '\n')
end
function logtable(table, indent)
  log(tostring(table))
  for index, value in pairs(table) do -- print table
    log('    ' .. tostring(index) .. ' : ' .. tostring(value))
  end
end

globals = {
  ui_checkbox_seltracks = false,
  ui_checkbox_volume = true,
  ui_checkbox_pan = true,
  ui_checkbox_mute = true,
  ui_checkbox_sends = true,
  tween = 'none',
  ease = 'linear'
}

-- init globals from project config
local exists, seltracks = reaper.GetProjExtState(0, 'snapshooter', 'ui_checkbox_seltracks')
if exists ~= 0 then globals.ui_checkbox_seltracks = seltracks == 'true' end
local exists, volume = reaper.GetProjExtState(0, 'snapshooter', 'ui_checkbox_volume')
if exists ~= 0 then globals.ui_checkbox_volume = volume == 'true' end
local exists, pan = reaper.GetProjExtState(0, 'snapshooter', 'ui_checkbox_pan')
if exists ~= 0 then globals.ui_checkbox_pan = pan == 'true' end
local exists, mute = reaper.GetProjExtState(0, 'snapshooter', 'ui_checkbox_mute')
if exists ~= 0 then globals.ui_checkbox_mute = mute == 'true' end
local exists, sends = reaper.GetProjExtState(0, 'snapshooter', 'ui_checkbox_sends')
if exists ~= 0 then globals.ui_checkbox_sends = sends == 'true' end
local exists, tween = reaper.GetProjExtState(0, 'snapshooter', 'ui_tween_menu')
if exists ~= 0 then globals.tween = tween end
local exists, ease = reaper.GetProjExtState(0, 'snapshooter', 'ui_ease_menu')
if exists ~= 0 then globals.ease = ease end

function makesnap()
  local numtracks = reaper.GetNumTracks()
  local entries = {}
  for i = 0, numtracks - 1 do
    -- vol,send,mute
    local tr = reaper.GetTrack(0, i)
    local ret, vol, pan = reaper.GetTrackUIVolPan(tr)
    local ret, mute = reaper.GetTrackUIMute(tr)
    table.insert(entries, { tr, 'Volume', vol })
    table.insert(entries, { tr, 'Pan', pan })
    table.insert(entries, { tr, 'Mute', mute and 1 or 0 })
    -- sends
    local sendcount = {} -- aux send counter
    for send = 0, reaper.GetTrackNumSends(tr, 0) do
      local src = reaper.GetTrackSendInfo_Value(tr, 0, send, 'P_SRCTRACK')
      local dst = reaper.GetTrackSendInfo_Value(tr, 0, send, 'P_DESTTRACK')
      local ret, svol, span = reaper.GetTrackSendUIVolPan(tr, send)
      local ret, smute = reaper.GetTrackSendUIMute(tr, send)
      key = tostring(src)..tostring(dst)
      count = sendcount[key] and sendcount[key] + 1 or 1
      table.insert(entries, { tr, 'Send', count, key, svol, span, smute and 1 or 0 })
      sendcount[key] = count
    end
    -- fx params
    local fxcount = reaper.TrackFX_GetCount(tr)
    for j = 0, fxcount - 1 do
      fxid = reaper.TrackFX_GetFXGUID(tr, j)
      paramcount = reaper.TrackFX_GetNumParams(tr, j)
      for k = 0, paramcount - 1 do
        param = reaper.TrackFX_GetParam(tr, j, k)
        table.insert(entries, { tr, fxid , k, param })
      end
    end
  end
  return entries
end

function difference (s1, s2)
  diff = {}
  hashmap = {}
  -- create snap2 hashmap
  for i, line2 in pairs(s2) do
    if #line2 == 3 then
      hashmap[line2[1]..line2[2]] = line2
    elseif #line2 == 4 then -- fx param
      hashmap[line2[1]..line2[2]..line2[3]] = line2
    elseif #line2 == 7 then -- sends
      hashmap[line2[1]..line2[2]..line2[3]..line2[4]] = line2
    end
  end
  -- compare s1 with s2 entries
  for i, line1 in pairs(s1) do
    if #line1 == 3 then -- volpanmute
      local line2 = hashmap[line1[1]..line1[2]]
      if line2 and line1[3] ~= line2[3] then
        table.insert(diff, line1)
      end
    elseif #line1 == 4 then -- params
      local line2 = hashmap[line1[1]..line1[2]..line1[3]]
      if line2 and line1[3] ~= line2[3] then
        table.insert(diff, line1)
      elseif line2 and line1[4] ~= line2[4] then
        table.insert(diff, line1)
      end
    elseif #line1 == 7 then -- sends
      local line2 = hashmap[line1[1]..line1[2]..line1[3]..line1[4]]
      if line2 and (line1[5] ~= line2[5] or line1[6] ~= line2[6] or line1[7] ~= line2[7]) then
        if line1[5] == line2[5] then line1[5] = 'unchanged' end
        if line1[6] == line2[6] then line1[6] = 'unchanged' end
        if line1[7] == line2[7] then line1[7] = 'unchanged' end
        table.insert(diff, line1)
      end
    end
  end
  return diff
end

-- stringify/parse snapshot for mem storage
function stringify(snap)
  local entries = {}
  for i, line in ipairs(snap) do
    for j, col in ipairs(line) do
      line[j] = tostring(col)
    end
    table.insert(entries, table.concat(line, ','))
  end
  return table.concat(entries, '\n')
end

function parse(snapstr)
  function splitline(line)
    local split = {}
    for word in string.gmatch(line, '([^,]+)') do
      table.insert(split, word)
    end
    return split
  end
  local lines = {}
  for line in string.gmatch(snapstr, '([^\n]+)') do
    table.insert(lines, splitline(line))
  end
  return lines
end

function insertSendEnvelopePoint(track, key, count, value, type)
  local count = 0
  local cursor = reaper.GetCursorPosition()
  for send = 0, reaper.GetTrackNumSends(track, 0) do
    local src = reaper.GetTrackSendInfo_Value(track, 0, send, 'P_SRCTRACK')
    local dst = reaper.GetTrackSendInfo_Value(track, 0, send, 'P_DESTTRACK')
    if tostring(src)..tostring(dst) == key then
      count = count + 1
      if count == cnt then
        local envelope = reaper.GetTrackSendInfo_Value(track, 0, send, 'P_ENV:<'..type)
        local scaling = reaper.GetEnvelopeScalingMode(envelope)
        reaper.InsertEnvelopePoint(envelope, cursor, reaper.ScaleToEnvelopeMode(scaling, value), 0, 0, true)
        br_env = reaper.BR_EnvAlloc(envelope, false)
        active, visible, armed, inLane, laneHeight, defaultShape, minValue, maxValue, centerValue, type, faderScaling = reaper.BR_EnvGetProperties(br_env)
        reaper.BR_EnvSetProperties(br_env, true, true, true, inLane, laneHeight, defaultShape, faderScaling)
        reaper.BR_EnvFree(br_env, 1)
      end
    end
  end
end

-- show Volume/Pan/Mute envelopes for track
function showTrackEnvelopes(track, envtype)
  if envtype == 'Volume' then
    if not reaper.GetTrackEnvelopeByName(track, 'Volume') then
      reaper.SetOnlyTrackSelected(track)
      reaper.Main_OnCommand(40406, 0) -- Set track volume visible
    end
  elseif envtype == 'Pan' then
    if not reaper.GetTrackEnvelopeByName(track, 'Pan') then
      reaper.SetOnlyTrackSelected(track)
      reaper.Main_OnCommand(40407, 0) -- Set track pan visible
    end
  elseif envtype == 'Mute' then
    if not reaper.GetTrackEnvelopeByName(track, 'Mute') then
      reaper.SetOnlyTrackSelected(track)
      reaper.Main_OnCommand(40867, 0) -- Set track mute visible
    end
  end
end

-- apply snapshot to params or write to timeline
function applydiff(diff, write, tween)
  local numtracks = reaper.GetNumTracks()
  local cursor = reaper.GetCursorPosition()
  -- tracks hashmap
  local tracks = {}
  for i = 0, numtracks - 1 do
    tracks[tostring(reaper.GetTrack(0, i))] = i
  end
  -- fxs hashmap
  local fxs = {}
  for guid, tr in pairs(tracks) do
    track = reaper.GetTrack(0, tr)
    fxcount = reaper.TrackFX_GetCount(track)
    for j = 0, fxcount - 1 do
      fxs[reaper.TrackFX_GetFXGUID(track, j)] = j
    end
  end
  -- sends hashmap
  local sends = {}
  for i = 0, numtracks - 1 do
    track = reaper.GetTrack(0, i)
    local sendscount = {}
    for i = 0, reaper.GetTrackNumSends(track, 0) do
      local src = reaper.GetTrackSendInfo_Value(track, 0, i, 'P_SRCTRACK')
      local dst = reaper.GetTrackSendInfo_Value(track, 0, i, 'P_DESTTRACK')
      key = tostring(src)..tostring(dst)
      count = sendscount[key] and sendscount[key] + 1 or 1
      sendscount[key] = count
      sends[key..tostring(count)] = i
    end
  end

  -- apply diff lines
  for i,line in ipairs(diff) do
    tr = tracks[tostring(line[1])]
    if tr ~= nil then
      local track = reaper.GetTrack(0, tr)
      if not globals.ui_checkbox_seltracks or reaper.IsTrackSelected(track) then
        if #line == 3 then -- vol/pan/mute
          param = line[2]
          value = tonumber(line[3])
          if param == 'Volume' and globals.ui_checkbox_volume or
            param == 'Pan' and globals.ui_checkbox_pan or
            param == 'Mute' and globals.ui_checkbox_mute then
            if write then
              showTrackEnvelopes(track, line[2])
              env = reaper.GetTrackEnvelopeByName(track, param)
              if param == 'Volume' then
                local scaling = reaper.GetEnvelopeScalingMode(env)
                reaper.InsertEnvelopePoint(env, cursor, reaper.ScaleToEnvelopeMode(scaling, value), 0, 0, true)
              else
                -- FIX flip mute value before writting to playlist
                if param == 'Mute' and value == 1 then value = 0
                elseif param == 'Mute' and value == 0 then value = 1 end
                -- FIX flip pan value before writting to playlist
                if param == 'Pan' then value = -value end
                --
                reaper.InsertEnvelopePoint(env, cursor, value, 0, 0, true)
              end
            elseif line[2] == 'Volume' then
              if tween then
                local ret, vol, pan = reaper.GetTrackUIVolPan(track)
                table.insert(params_to_tween, { track, 'Volume', null, null, vol, value })
              else
                reaper.SetMediaTrackInfo_Value(track, "D_VOL", value)
              end
            elseif line[2] == 'Pan' then
              if tween then
                local ret, vol, pan = reaper.GetTrackUIVolPan(track)
                table.insert(params_to_tween, { track, 'Pan', null, null, pan, value })
              else
                reaper.SetMediaTrackInfo_Value(track, "D_PAN", value)
              end
            elseif line[2] == 'Mute' then
              reaper.SetMediaTrackInfo_Value(track, "B_MUTE", value)
            end
          end
        elseif #line == 4 then -- fx params
          fxid = fxs[tostring(line[2])]
          param = tonumber(line[3])
          value = tonumber(line[4])
          if fxid ~= nil then
            if write then
              env = reaper.GetFXEnvelope(track, fxid, param, true)
              reaper.InsertEnvelopePoint(env, cursor, value, 0, 0, true)
            else
              if tween then
                local val = reaper.TrackFX_GetParam(track, fxid, param)
                table.insert(params_to_tween, { track, param, fxid, null, val, value })
              else
                reaper.TrackFX_SetParam(track, fxid, param, value)
              end
            end
          else
            log('fx not found '..tostring(line))
            logtable(line)
          end
        elseif #line == 7 then -- sends
          local key = line[4]
          local count = line[3]
          send = sends[key..count]
          if send and globals.ui_checkbox_sends then
            cnt = tonumber(line[3])
            key = line[4]
            vol = line[5]
            pan = line[6]
            mut = line[7]
            if vol ~= 'unchanged' then
              if write then insertSendEnvelopePoint(track, key, cnt, tonumber(vol), 'VOLENV')
              else
                if tween then
                  local ret, svol, span = reaper.GetTrackSendUIVolPan(track, send)
                  table.insert(params_to_tween, { track, 'Volume', null, send, tonumber(svol), tonumber(vol) })
                else
                  reaper.SetTrackSendUIVol(track, send, tonumber(vol), -1)
                end
              end
            end
            if pan ~= 'unchanged' then
              if write then
                pan = -pan -- FIX flip pan before writting to playlist
                insertSendEnvelopePoint(track, key, cnt, tonumber(pan), 'PANENV')
              else
                if tween then
                  local ret, svol, span = reaper.GetTrackSendUIVolPan(track, send)
                  table.insert(params_to_tween, { track, 'Pan', null, send, tonumber(span), tonumber(pan) })
                else
                  reaper.SetTrackSendUIPan(track, send, tonumber(pan), -1)
                end
              end
            end
            -- TODO send mute
            -- if mut ~= 'unchanged' then
              -- if write then insertSendEnvelopePoint(track, key, cnt, tonumber(vol), 'MUTEENV')
              -- else reaper.SetTrackSendUIMute(track, send, tonumber(mut), -1) end
              -- else reaper.SetTrackSendInfo_Value(track, 0, cnt, 'B_MUTE', tonumber(mut)) end
            -- end
          end
        end
      end
    end
  end
end

function savesnap(slot)
  slot = slot or 1
  snap = makesnap()
  reaper.SetProjExtState(0, 'snapshooter', 'snap'..slot, stringify(snap))
  reaper.SetProjExtState(0, 'snapshooter', 'snapdate'..slot, os.date())
end

function applysnap(slot, write)
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  seltracks = {}
  for i = 0, reaper.CountSelectedTracks(0) do
    table.insert(seltracks, reaper.GetSelectedTrack(0, i))
  end
  -- local globaloverride = reaper.GetGlobalAutomationOverride()
  -- reaper.SetGlobalAutomationOverride(6)
  exists, snap1 = reaper.GetProjExtState(0, 'snapshooter', 'snap'..slot)
  if exists then
    snap2 = makesnap()
    snap2 = parse(stringify(snap2)) -- normalize
    diff = difference(parse(snap1), snap2)
    use_tween = globals.tween ~= 'none'
    if use_tween then
      params_to_tween = {}
    end
    applydiff(diff, write, use_tween)
    reaper.defer(reaper.UpdateArrange)
    if use_tween then
      bpm, bpi = reaper.GetProjectTimeSignature()
      duration = 60 / bpm * bpi
      if (globals.tween == '1/4bar') then duration = duration / 4 end
      if (globals.tween == '1/2bar') then duration = duration / 2 end
      if (globals.tween == '2bar') then duration = duration * 2 end
      if (globals.tween == '4bar') then duration = duration * 4 end
      ease_fn = tween_fns.linear
      if (globals.ease == 'easein') then ease_fn = tween_fns.ease_in end
      if (globals.ease == 'easeout') then ease_fn = tween_fns.ease_out end
      if (globals.ease == 'easeinout') then ease_fn = tween_fns.ease_in_out end
      tween_params(reaper.time_precise(), duration, ease_fn)
    end
  else
    log('could not find snap'..slot)
  end
  reaper.Main_OnCommand(40297, 0) -- Track: Unselect (clear selection of) all tracks
  for i, track in ipairs(seltracks) do
    reaper.SetTrackSelected(track, 1) -- restore selected tracks
  end
  -- reaper.SetGlobalAutomationOverride(globaloverride)
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('apply snapshot', 0)
end

function clearsnap(slot)
  reaper.SetProjExtState(0, 'snapshooter', 'snap'..slot, '')
  reaper.SetProjExtState(0, 'snapshooter', 'snapdate'..slot, '')
end

--------------------------------------------------------------------------------
-- Tween
--------------------------------------------------------------------------------
tween_fns = {}
function tween_fns.linear (t, b, _c, d) -- t: current time, b: beginning value, _c: final value, d: total duration
  local c = _c - b;
  return c * t / d + b;
end
function tween_fns.ease_in (t, b, _c, d)
  local c = _c - b;
  t = t / d
  return c * t * t + b;
end
function tween_fns.ease_out (t, b, _c, d)
  local var c = _c - b;
  t = t / d
  return -c * t * (t - 2) + b;
end
function tween_fns.ease_in_out (t, b, _c, d)
  local c = _c - b;
  t = t / (d / 2)
  if ((t) < 1) then
    return c / 2 * t * t + b;
  else
    t = t - 1
    return -c / 2 * (t * (t - 2) - 1) + b;
  end
end

params_to_tween = {} -- {{ track, param, fxid, send, from, to }}
function apply_tween (track, param, fxid, send, value)
  if send then
    if param == 'Volume' then
      reaper.SetTrackSendUIVol(track, send, value, -1)
    end
    if param == 'Pan' then
      reaper.SetTrackSendUIPan(track, send, value, -1)
    end
  elseif fxid then
    reaper.TrackFX_SetParam(track, fxid, param, value)
  elseif param == 'Volume' then
    reaper.SetMediaTrackInfo_Value(track, "D_VOL", value)
  elseif param == 'Pan' then
    reaper.SetMediaTrackInfo_Value(track, "D_PAN", value)
  end
end

function tween_params(start, duration, ease_fn)
  local delta = reaper.time_precise() - start
  if (delta >= duration) then
    for i, entry in ipairs(params_to_tween) do
      apply_tween(entry[1], entry[2], entry[3], entry[4], entry[6])
    end
    return
  end
  for i, entry in ipairs(params_to_tween) do
    local val = ease_fn(delta, entry[5], entry[6], duration)
    apply_tween(entry[1], entry[2], entry[3], entry[4], val)
  end
  reaper.defer(function () tween_params(start, duration, ease_fn) end)
end

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------

ui_snaprows = {}
function ui_refresh_buttons()
  for i, row in ipairs(ui_snaprows) do
    hassnap = reaper.GetProjExtState(0, 'snapshooter', 'snap'..i) ~= 0
    row.children[1][1]:attr('color', hassnap and 0x99BD13 or 0x999999) -- savebtn
    row.children[2][1]:attr('color', hassnap and 0xffffff or 0x777777) -- savetxt
    row.children[3][1]:attr('color', hassnap and 0x999999 or 0x555555) -- applybtn
    row.children[4][1]:attr('color', hassnap and 0xffffff or 0x777777) -- applytxt
    row.children[5][1]:attr('color', hassnap and 0x999999 or 0x555555) -- writebtn
    row.children[6][1]:attr('color', hassnap and 0xffffff or 0x777777) -- writetxt
    row.children[7][1]:attr('color', hassnap and 0x999999 or 0x555555) -- delbtn
    row.children[8][1]:attr('color', hassnap and 0xffffff or 0x777777) -- deltxt

    status, datestr = reaper.GetProjExtState(0, 'snapshooter', 'snapdate'..i)
    row.children[2][1]:attr('text', hassnap and ' '..datestr or ' Empty')
  end
end

function ui_start()
  -- package.path = reaper.GetResourcePath() .. '/Scripts/rtk/1/?.lua'
  -- local rtk = require('rtk')
  local sep = package.config:sub(1, 1)
  local script_folder = debug.getinfo(1).source:match("@?(.*[\\|/])")
  local rtk = dofile(script_folder .. 'tilr_Snapshooter' .. sep .. 'rtk.lua')
  local window = rtk.Window{w=470, h=425}
  window:open{align='center'}
  local box = window:add(rtk.VBox{margin=10})
  box:add(rtk.Heading{'Snapshooter', bmargin=10})

  for i = 1, 12 do
    local row = box:add(rtk.HBox{bmargin=5})
    local button = row:add(rtk.Button{circular=true})
    local text = row:add(rtk.Text{string.format("%02d",i)..' Empty', w=230, textalign='center', lmargin=10})
    button.onclick = function ()
      savesnap(i)
      ui_refresh_buttons()
    end
    local button = row:add(rtk.Button{circular=true, lmargin=5})
    local text = row:add(rtk.Text{'Apply ', lmargin=5})
    button.onclick = function ()
      applysnap(i, false)
    end
    local button = row:add(rtk.Button{circular=true, lmargin=5})
    local text = row:add(rtk.Text{'Write ', lmargin=5})
    button.onclick = function ()
      applysnap(i, true)
    end
    local button = row:add(rtk.Button{circular=true, lmargin=5})
    local text = row:add(rtk.Text{'Del ', lmargin=5, lmargin=5})
    button.onclick = function()
      clearsnap(i)
      ui_refresh_buttons()
    end
    table.insert(ui_snaprows, row)
  end

  -- checkboxes
  local row = box:add(rtk.HBox{tmargin=10})
  local ui_checkbox_seltracks = row:add(rtk.CheckBox{'Selected tracks'})
  local ui_checkbox_volume = row:add(rtk.CheckBox{'Vol', lmargin=15})
  local ui_checkbox_pan = row:add(rtk.CheckBox{'Pan',lmargin=15})
  local ui_checkbox_mute = row:add(rtk.CheckBox{'Mute', lmargin=15})
  local ui_checkbox_sends = row:add(rtk.CheckBox{'Sends', lmargin=15})

  if globals.ui_checkbox_seltracks then
    ui_checkbox_seltracks:toggle()
  end
  if globals.ui_checkbox_volume then
    ui_checkbox_volume:toggle()
  end
  if globals.ui_checkbox_pan then
    ui_checkbox_pan:toggle()
  end
  if globals.ui_checkbox_mute then
    ui_checkbox_mute:toggle()
  end
  if globals.ui_checkbox_sends then
    ui_checkbox_sends:toggle()
  end

  ui_checkbox_seltracks.onchange = function(self)
    reaper.SetProjExtState(0, 'snapshooter', 'ui_checkbox_seltracks', tostring(self.value))
    globals.ui_checkbox_seltracks = self.value
  end
  ui_checkbox_volume.onchange = function(self)
    reaper.SetProjExtState(0, 'snapshooter', 'ui_checkbox_volume', tostring(self.value))
    globals.ui_checkbox_volume = self.value
  end
  ui_checkbox_pan.onchange = function(self)
    reaper.SetProjExtState(0, 'snapshooter', 'ui_checkbox_pan', tostring(self.value))
    globals.ui_checkbox_pan = self.value
  end
  ui_checkbox_mute.onchange = function(self)
    reaper.SetProjExtState(0, 'snapshooter', 'ui_checkbox_mute', tostring(self.value))
    globals.ui_checkbox_mute = self.value
  end
  ui_checkbox_sends.onchange = function(self)
    reaper.SetProjExtState(0, 'snapshooter', 'ui_checkbox_sends', tostring(self.value))
    globals.ui_checkbox_sends = self.value
  end

  -- tweening controls
  row = box:add(rtk.HBox{tmargin=10})
  row:add(rtk.Text{'Tween', rmargin=5, tmargin=5})
  local tween_menu = row:add(rtk.OptionMenu{
    menu = {
        { 'None', id='none' },
        { '1/4 Bar', id='1/4bar' },
        { '1/2 Bar', id='1/2bar' },
        { '1 Bar', id='1bar'},
        { '2 Bar', id='2bar'},
        { '4 Bar', id='4bar'},
    }
  })
  tween_menu:select(globals.tween)
  tween_menu.onchange = function (self)
    reaper.SetProjExtState(0, 'snapshooter', 'ui_tween_menu', self.selected)
    globals.tween = self.selected
  end

  row:add(rtk.Text{'Ease', lmargin=20, rmargin=5, tmargin=5})
  local ease_menu = row:add(rtk.OptionMenu{
    menu = {
        { 'Linear', id='linear' },
        { 'In', id='easein' },
        { 'Out', id='easeout' },
        { 'InOut', id='easeinout' },
    }
  })
  ease_menu:select(globals.ease)
  ease_menu.onchange = function (self)
    reaper.SetProjExtState(0, 'snapshooter', 'ui_ease_menu', self.selected)
    globals.ease = self.selected
  end

  ui_refresh_buttons()
end

if not skip_init then -- skip_init set from other scripts
  ui_start()
end

return {
  savesnap = savesnap,
  applysnap = applysnap
}
-- interactive dev:
  -- reaper.showConsoleMsg(¨chars¨) // show console output
  -- reaper.NamedCommandLookup('_RSad7acd2e5dbd41ab15aa68ffdb01c4c5fc82c446',0)
  -- reaper.Main_OnCommand(55863, 0)

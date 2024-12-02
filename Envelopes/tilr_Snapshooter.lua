-- @description Snapshooter
-- @author tilr
-- @version 1.4
-- @changelog
--   Fix nasty bug where snapshots tracks were identified by userdata.
--   This caused failure to find the tracks on reaper restart.
--   Fixed by using tracks GUID instead.
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
-- @screenshot https://raw.githubusercontent.com/tiagolr/reaper_scripts/master/doc/snapshooter.gif
-- @about
--   # Snapshooter
--
--   https://github.com/tiagolr/reaper_scripts
--
--   Snapshooter allows to create param snapshots and recall or write them to the playlist creating patch morphs.
--   Different from SWS snapshots, only the params changed are written to the playlist as automation points.
--
--   Features:
--     * Stores and retrieves FX params
--     * Stores and retrieves mixer states for track Volume, Pan, Mute and Sends
--     * Writes only changed params by diffing the current state and selected snapshot
--     * Transition snapshots using tween and ease functions
--     * Writes transitions into time selection from current state to snapshot
--
--   Tips:
--     * Grab time selections and click write to write transitions into timeline
--     * Set global automation to READ to write snapshot from current state
--     * Use global automation BYPASS to write transitions when automation already exists on the playlist
--     * Snapshots can be written directly into cursor when there is no time selection
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
  win_x = null,
  win_y = null,
  ui_checkbox_seltracks = false,
  ui_checkbox_volume = true,
  ui_checkbox_pan = true,
  ui_checkbox_mute = true,
  ui_checkbox_sends = true,
  ui_checkbox_fx = true,
  ui_page_index = 1,
  ui_last_applied = -1, -- last applied snapshot
  write_transition = true,
  preserve_edges = false,
  invert_transition = false,
  points_shape = 0,
  points_tension = 0,
  tween_custom_duration = 1000,
  tween = 'none',
  ease = 'linear'
}

-- init globals from project config
local exists, win_x = reaper.GetProjExtState(0, 'snapshooter', 'win_x')
if exists ~= 0 then globals.win_x = tonumber(win_x) end
local exists, win_y = reaper.GetProjExtState(0, 'snapshooter', 'win_y')
if exists ~= 0 then globals.win_y = tonumber(win_y) end
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
local exists, fx = reaper.GetProjExtState(0, 'snapshooter', 'ui_checkbox_fx')
if exists ~= 0 then globals.ui_checkbox_fx = fx == 'true' end
local exists, index = reaper.GetProjExtState(0, 'snapshooter', 'ui_page_index')
if exists ~= 0 then globals.ui_page_index = tonumber(index) end
local exists, sindex = reaper.GetProjExtState(0, 'snapshooter', 'ui_last_applied')
if exists ~= 0 then globals.ui_last_applied = tonumber(sindex) end
local exists, edges = reaper.GetProjExtState(0, 'snapshooter', 'preserve_edges')
if exists ~= 0 then globals.preserve_edges = edges == 'true' end
local exists, tween = reaper.GetProjExtState(0, 'snapshooter', 'ui_tween_menu')
if exists ~= 0 then globals.tween = tween end
local exists, ease = reaper.GetProjExtState(0, 'snapshooter', 'ui_ease_menu')
if exists ~= 0 then globals.ease = ease end
local exists, shape = reaper.GetProjExtState(0, 'snapshooter', 'points_shape')
if exists ~= 0 then globals.points_shape = tonumber(shape) end
local exists, duration = reaper.GetProjExtState(0, 'snapshooter', 'tween_custom_duration')
if exists ~= 0 then globals.tween_custom_duration = tonumber(duration) end
local exists, tension = reaper.GetProjExtState(0, 'snapshooter', 'points_tension')
if exists ~= 0 then globals.points_tension = tonumber(tension) end
local exists, invert = reaper.GetProjExtState(0, 'snapshooter', 'invert_transition')
if exists ~= 0 then globals.invert_transition = invert == 'true' end

function makesnap()
  local numtracks = reaper.GetNumTracks()
  local entries = {}
  for i = 0, numtracks - 1 do
    -- vol,send,mute
    local tr = reaper.GetTrack(0, i)
    local guid = reaper.GetTrackGUID(tr)
    local ret, vol, pan = reaper.GetTrackUIVolPan(tr)
    local ret, mute = reaper.GetTrackUIMute(tr)
    table.insert(entries, { guid, 'Volume', vol })
    table.insert(entries, { guid, 'Pan', pan })
    table.insert(entries, { guid, 'Mute', mute and 1 or 0 })
    -- sends
    local sendcount = {} -- aux send counter
    for send = 0, reaper.GetTrackNumSends(tr, 0) do
      local src = reaper.GetTrackSendInfo_Value(tr, 0, send, 'P_SRCTRACK')
      local dst = reaper.GetTrackSendInfo_Value(tr, 0, send, 'P_DESTTRACK')
      local ret, svol, span = reaper.GetTrackSendUIVolPan(tr, send)
      local ret, smute = reaper.GetTrackSendUIMute(tr, send)
      key = tostring(src)..tostring(dst)
      count = sendcount[key] and sendcount[key] + 1 or 1
      table.insert(entries, { guid, 'Send', count, key, svol, span, smute and 1 or 0 })
      sendcount[key] = count
    end
    -- fx params
    local fxcount = reaper.TrackFX_GetCount(tr)
    for j = 0, fxcount - 1 do
      fxid = reaper.TrackFX_GetFXGUID(tr, j)
      paramcount = reaper.TrackFX_GetNumParams(tr, j)
      for k = 0, paramcount - 1 do
        param = reaper.TrackFX_GetParam(tr, j, k)
        table.insert(entries, { guid, fxid , k, param })
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

function insertSendEnvelopePoint(track, key, cnt, value, type, shape, tension)
  local count = 0
  local cursor = reaper.GetCursorPosition()
  for send = 0, reaper.GetTrackNumSends(track, 0) do
    local src = reaper.GetTrackSendInfo_Value(track, 0, send, 'P_SRCTRACK')
    local dst = reaper.GetTrackSendInfo_Value(track, 0, send, 'P_DESTTRACK')
    if tostring(src)..tostring(dst) == key and key ~= '0.00.0' then
      count = count + 1
      if count == cnt then
        local envelope = reaper.GetTrackSendInfo_Value(track, 0, send, 'P_ENV:<'..type)
        local scaling = reaper.GetEnvelopeScalingMode(envelope)
        reaper.InsertEnvelopePoint(envelope, cursor, reaper.ScaleToEnvelopeMode(scaling, value), shape, tension, true)
        br_env = reaper.BR_EnvAlloc(envelope, false)
        active, visible, armed, inLane, laneHeight, defaultShape, minValue, maxValue, centerValue, _, faderScaling = reaper.BR_EnvGetProperties(br_env)
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

-- apply snapshot to params or write diff points to cursor
function applydiff(diff, write, tween)
  local points_shape = globals.invert_transition and globals.points_shape or 0
  local points_tension = globals.invert_transition and globals.points_tension or 0
  local numtracks = reaper.GetNumTracks()
  local cursor = reaper.GetCursorPosition()
  -- tracks hashmap
  local tracks = {}
  for i = 0, numtracks - 1 do
    tracks[reaper.GetTrackGUID(reaper.GetTrack(0, i))] = i
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
    tr = tracks[line[1]]
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
                reaper.InsertEnvelopePoint(env, cursor, reaper.ScaleToEnvelopeMode(scaling, value), points_shape, points_tension, true)
              else
                -- FIX flip mute value before writting to playlist
                if param == 'Mute' and value == 1 then value = 0
                elseif param == 'Mute' and value == 0 then value = 1 end
                -- FIX flip pan value before writting to playlist
                if param == 'Pan' then value = -value end
                --
                reaper.InsertEnvelopePoint(env, cursor, value, points_shape, points_tension, true)
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
              reaper.InsertEnvelopePoint(env, cursor, value, points_shape, points_tension, true)
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
        elseif #line == 7 and globals.ui_checkbox_fx then -- sends
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
              if write then insertSendEnvelopePoint(track, key, cnt, tonumber(vol), 'VOLENV', points_shape, points_tension)
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
                insertSendEnvelopePoint(track, key, cnt, tonumber(pan), 'PANENV', points_shape, points_tension)
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

-- Writes current state points to beggining of time selection
function clearEnvelopesAndAddStartingPoint(diff, starttime, endtime)
  if globals.preserve_edges then
    _starttime = starttime + 0.000000001
    _endtime = endtime - 0.000000001
  else
  _starttime = starttime - 0.000000001
  _endtime = endtime + 0.000000001
  end
  if globals.invert_transition then
    starttime = endtime -- writes points to endtime instead
  end
  points_shape = not globals.invert_transition and globals.points_shape or 0
  points_tension = not globals.invert_transition and globals.points_tension or 0
  -- tracks hashmap
  local tracks = {}
  local numtracks = reaper.GetNumTracks()
  for i = 0, numtracks - 1 do
    tracks[reaper.GetTrackGUID(reaper.GetTrack(0, i))] = i
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

  for i,line in ipairs(diff) do
    local track = tracks[line[1]]
    if track ~= null then
      track = reaper.GetTrack(0, track)
      local env_count = reaper.CountTrackEnvelopes(track)
      if not globals.ui_checkbox_seltracks or reaper.IsTrackSelected(track) then
        if #line == 3 then -- vol/pan/mute
          local param = line[2]
          if param == 'Volume' and globals.ui_checkbox_volume or
            param == 'Pan' and globals.ui_checkbox_pan or
            param == 'Mute' and globals.ui_checkbox_mute
          then
            if param == 'Volume' then
              _, value, _ = reaper.GetTrackUIVolPan(track)
            elseif param == 'Pan' then
              _, _, value = reaper.GetTrackUIVolPan(track)
              value = -value
            elseif param == 'Mute' then
              _, value =  reaper.GetTrackUIMute(track)
              if value then value = 0
              else value = 1
              end
            end
            showTrackEnvelopes(track, param)
            env = reaper.GetTrackEnvelopeByName(track, param)
            local scaling = reaper.GetEnvelopeScalingMode(env)
            reaper.DeleteEnvelopePointRange(env, _starttime, _endtime)
            reaper.InsertEnvelopePoint(env, starttime, reaper.ScaleToEnvelopeMode(scaling, value), points_shape, points_tension, true)
          end
        elseif #line == 4 and globals.ui_checkbox_fx then -- params
          fxid = fxs[tostring(line[2])]
          param = tonumber(line[3])
          env = reaper.GetFXEnvelope(track, fxid, param, true)
          value = reaper.TrackFX_GetParam(track, fxid, param)
          reaper.DeleteEnvelopePointRange(env, _starttime, _endtime)
          reaper.InsertEnvelopePoint(env, starttime, value, points_shape, points_tension, true)
        elseif #line == 7 and globals.ui_checkbox_sends then -- sends
          local cnt = tonumber(line[3])
          local count = 0
          for send = 0, reaper.GetTrackNumSends(track, 0) do
            src = reaper.GetTrackSendInfo_Value(track, 0, send, 'P_SRCTRACK')
            dst = reaper.GetTrackSendInfo_Value(track, 0, send, 'P_DESTTRACK')
            if tostring(src)..tostring(dst) == line[4] then
              count = count + 1
              if count == cnt then
                vol = line[5]
                pan = line[6]
                mut = line[7]
                if vol ~= 'unchanged' then
                  env = reaper.GetTrackSendInfo_Value(track, 0, send, 'P_ENV:<VOLENV')
                  local _, value, _ = reaper.GetTrackSendUIVolPan(track, send)
                  local scaling = reaper.GetEnvelopeScalingMode(env)
                  reaper.DeleteEnvelopePointRange(env, _starttime, _endtime)
                  reaper.InsertEnvelopePoint(env, starttime, reaper.ScaleToEnvelopeMode(scaling, value), points_shape, points_tension, true)
                end
                if pan ~= 'unchanged' then
                  env = reaper.GetTrackSendInfo_Value(track, 0, send, 'P_ENV:<PANENV')
                  local _, _, value = reaper.GetTrackSendUIVolPan(track, send)
                  local scaling = reaper.GetEnvelopeScalingMode(env)
                  reaper.DeleteEnvelopePointRange(env, _starttime, _endtime)
                  reaper.InsertEnvelopePoint(env, starttime, reaper.ScaleToEnvelopeMode(scaling, -value), points_shape, points_tension, true)
                end
              end
            end
          end
        end
      end
    end
  end
end

function applysnap(slot, write)
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  seltracks = {}
  for i = 0, reaper.CountSelectedTracks(0) do
    table.insert(seltracks, reaper.GetSelectedTrack(0, i))
  end
  exists, snap1 = reaper.GetProjExtState(0, 'snapshooter', 'snap'..slot)
  if exists then
    snap2 = makesnap()
    snap2 = parse(stringify(snap2)) -- normalize
    diff = difference(parse(snap1), snap2)
    use_tween = globals.tween ~= 'none'
    if use_tween then
      params_to_tween = {}
    end

    local cursor = reaper.GetCursorPosition()
    start_loop, end_loop = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
    write_transition = globals.write_transition and write and start_loop ~= end_loop
    if write_transition then
      clearEnvelopesAndAddStartingPoint(diff, start_loop, end_loop)
      if globals.invert_transition then
        reaper.SetEditCurPos(start_loop, false, false)
      else
        reaper.SetEditCurPos(end_loop, false, false)
      end
    end

    applydiff(diff, write, use_tween)

    if write_transition then
      reaper.SetEditCurPos(cursor, false, false)
    end
    reaper.defer(reaper.UpdateArrange)
    if use_tween then
      bpm, bpi = reaper.GetProjectTimeSignature()
      duration = 60 / bpm * bpi
      if (globals.tween == '1/4bar') then duration = duration / 4 end
      if (globals.tween == '1/2bar') then duration = duration / 2 end
      if (globals.tween == '2bar') then duration = duration * 2 end
      if (globals.tween == '4bar') then duration = duration * 4 end
      if (globals.tween == 'custom') then duration = globals.tween_custom_duration / 1000 end
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
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('apply snapshot', 0)
end

function savesnap(slot)
  slot = slot or 1
  snap = makesnap()
  isNewsnap = reaper.GetProjExtState(0, 'snapshooter', 'snap'..slot) == 0
  if isNewsnap then
    reaper.SetProjExtState(0, 'snapshooter', 'snapname'..slot, os.date('%c'))
  else
    _, snapname = reaper.GetProjExtState(0, 'snapshooter', 'snapname'..slot)
    _, snapdate = reaper.GetProjExtState(0, 'snapshooter', 'snapdate'..slot)
    if (snapname == snapdate or snapname == '') then
      reaper.SetProjExtState(0, 'snapshooter', 'snapname'..slot, os.date('%c'))
    end
  end
  reaper.SetProjExtState(0, 'snapshooter', 'snap'..slot, stringify(snap))
  reaper.SetProjExtState(0, 'snapshooter', 'snapdate'..slot, os.date('%c'))
end

function clearsnap(slot)
  reaper.SetProjExtState(0, 'snapshooter', 'snap'..slot, '')
  reaper.SetProjExtState(0, 'snapshooter', 'snapname'..slot, '')
  reaper.SetProjExtState(0, 'snapshooter', 'snapdate'..slot, '')
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

function write_all_params ()
  local snap = makesnap()
  snap = parse(stringify(snap)) -- normalize/stringify
  applydiff(snap, true, false)
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

ui_nsnaps = 12
ui_snaprows = {}
ui_page_text = nil

function ui_refresh_buttons()
  for i, row in ipairs(ui_snaprows) do
    local nsnap = i + (globals.ui_page_index - 1) * ui_nsnaps
    local lapplied = globals.ui_last_applied == nsnap
    hassnap = reaper.GetProjExtState(0, 'snapshooter', 'snap'..nsnap) ~= 0
    row.children[1][1]:attr('color', hassnap and 0x99BD13 or 0x999999) -- savebtn
    row.children[2][1]:attr('textcolor', hassnap and 0xffffff or 0x777777) -- savetxt
    row.children[3][1]:attr('color', hassnap and 0x999999 or 0x555555) -- applybtn
    row.children[4][1]:attr('color', hassnap and (lapplied and 0x99bd13 or 0xffffff) or 0x777777) -- applytxt
    row.children[5][1]:attr('color', hassnap and 0x999999 or 0x555555) -- writebtn
    row.children[6][1]:attr('color', hassnap and 0xffffff or 0x777777) -- writetxt
    row.children[7][1]:attr('color', hassnap and 0x999999 or 0x555555) -- delbtn
    row.children[8][1]:attr('color', hassnap and 0xffffff or 0x777777) -- deltxt

    _, snapname = reaper.GetProjExtState(0, 'snapshooter', 'snapname'..nsnap)
    row.children[2][1]:attr('value', hassnap and snapname or 'Slot '..nsnap)

    ui_page_text:attr('text', 'Page '..string.format("%02d", globals.ui_page_index))
  end
end

function set_page(i)
  reaper.SetProjExtState(0, 'snapshooter', 'ui_page_index', tostring(i))
  globals.ui_page_index = i
  ui_refresh_buttons()
end

function ui_start()
  local sep = package.config:sub(1, 1)
  local script_folder = debug.getinfo(1).source:match("@?(.*[\\|/])")
  local rtk = dofile(script_folder .. 'tilr_Snapshooter' .. sep .. 'rtk.lua')
  local window = rtk.Window{ w=470, h=553, title='Snapshooter'}
  window.onmove = function (self)
    reaper.SetProjExtState(0, 'snapshooter', 'win_x', self.x)
    reaper.SetProjExtState(0, 'snapshooter', 'win_y', self.y)
  end
  window:open{align='center'}
  if globals.win_x and globals.win_y then
    window:attr('x', globals.win_x)
    window:attr('y', globals.win_y)
  end

  local box = rtk.VBox{padding=10, tpadding=50}
  local vp = rtk.Viewport{box, smoothscroll=true,  scrollbar_size=3}
  window:add(vp)

  local toolbar = box:add(rtk.HBox({ tmargin=-40, bmargin=10 }))
  toolbar:add(rtk.Heading{'Snapshooter'})
  toolbar:add(rtk.Box.FLEXSPACE)

  -- local row = box:add(rtk.HBox{tmargin=10, spacing=0})
  local button = toolbar:add(rtk.Button{'«', flat=true, textcolor2='#999999'})
  button.onclick = function () set_page(1) end
  local button = toolbar:add(rtk.Button{'<', flat=true, textcolor2='#999999'})
  button.onclick = function () set_page(math.max(1, globals.ui_page_index - 1)) end
  ui_page_text = toolbar:add(rtk.Text{'Page 01', tmargin=6, w=70, halign='center', color='#999999'})
  local button = toolbar:add(rtk.Button{'>', flat=true, textcolor2='#999999'})
  button.onclick = function () set_page(math.min(10, globals.ui_page_index + 1)) end
  local button = toolbar:add(rtk.Button{'»', flat=true, textcolor2='#999999'})
  button.onclick = function () set_page(10) end

  -- box:add(rtk.Heading{'Snapshooter', tmargin=-30, bmargin=10})

  for i = 1, ui_nsnaps do
    local row = box:add(rtk.HBox{bmargin=5})
    local button = row:add(rtk.Button{circular=true})
    local inputtext = row:add(rtk.Entry{value='Empty', w=230, bmargin=-5, tmargin=-2, lmargin=10, lpadding=0, bg=0x333333, border_hover='#333333', border_focused='#333333'})
    inputtext.onchange = function (self)
      local nsnap = i + (globals.ui_page_index - 1) * ui_nsnaps
      local hassnap = reaper.GetProjExtState(0, 'snapshooter', 'snap'..nsnap) ~= 0
      if hassnap then
        reaper.SetProjExtState(0, 'snapshooter', 'snapname'..nsnap, self.value)
      end
    end
    button.onclick = function ()
      local nsnap = i + (globals.ui_page_index - 1) * ui_nsnaps
      savesnap(nsnap)
      ui_refresh_buttons()
    end
    local button = row:add(rtk.Button{circular=true, lmargin=5})
    local text = row:add(rtk.Text{'Apply ', lmargin=5})
    button.onclick = function ()
      local nsnap = i + (globals.ui_page_index - 1) * ui_nsnaps
      applysnap(nsnap, false)
      globals.ui_last_applied = nsnap
      reaper.SetProjExtState(0, 'snapshooter', 'ui_last_applied', tostring(nsnap))
      ui_refresh_buttons()
    end
    local button = row:add(rtk.Button{circular=true, lmargin=5})
    local text = row:add(rtk.Text{'Write ', lmargin=5})
    button.onclick = function ()
      local nsnap = i + (globals.ui_page_index - 1) * ui_nsnaps
      applysnap(nsnap, true)
    end
    local button = row:add(rtk.Button{circular=true, lmargin=5})
    local text = row:add(rtk.Text{'Del ', lmargin=5})
    button.onclick = function()
      local nsnap = i + (globals.ui_page_index - 1) * ui_nsnaps
      clearsnap(nsnap)
      if globals.ui_last_applied == nsnap then
        reaper.SetProjExtState(0, 'snapshooter', 'ui_last_applied', tostring(-1))
        globals.ui_last_applied = -1
      end
      ui_refresh_buttons()
    end
    table.insert(ui_snaprows, row)
  end

  -- checkboxes
  local row = box:add(rtk.HBox{tmargin=10, spacing=10})
  local ui_checkbox_seltracks = row:add(rtk.CheckBox{'Selected tracks'})
  local ui_checkbox_volume = row:add(rtk.CheckBox{'Vol'})
  local ui_checkbox_pan = row:add(rtk.CheckBox{'Pan'})
  local ui_checkbox_mute = row:add(rtk.CheckBox{'Mute'})
  local ui_checkbox_fx = row:add(rtk.CheckBox{'FX'})
  local ui_checkbox_sends = row:add(rtk.CheckBox{'Sends'})

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
  if globals.ui_checkbox_fx then
    ui_checkbox_fx:toggle()
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
  ui_checkbox_fx.onchange = function(self)
    reaper.SetProjExtState(0, 'snapshooter', 'ui_checkbox_fx', tostring(self.value))
    globals.ui_checkbox_fx = self.value
  end

  -- Transition controls
  row = box:add(rtk.HBox{tmargin=10, bmargin=10})
  row:add(rtk.Text{'Write settings', color=0x777777})
  row:add(rtk.Box.FLEXSPACE)
  local button = row:add(rtk.Button{'Write all params', bmargin=-50, tmargin=-5, flat=true, textcolor2='#999999'})
  button.onclick = write_all_params
  row = box:add(rtk.HBox{tmargin=5, spacing=10})

  local ui_checkbox_preserve_edges = row:add(rtk.CheckBox{'Preserve edges'})
  if globals.preserve_edges then
    ui_checkbox_preserve_edges:toggle()
  end
  ui_checkbox_preserve_edges.onchange = function(self)
    reaper.SetProjExtState(0, 'snapshooter', 'preserve_edges', tostring(self.value))
    globals.preserve_edges = self.value
  end
  local ui_checkbox_invert = row:add(rtk.CheckBox{'Invert'})
  if globals.invert_transition then
    ui_checkbox_invert:toggle()
  end
  ui_checkbox_invert.onchange = function(self)
    reaper.SetProjExtState(0, 'snapshooter', 'invert_transition', tostring(self.value))
    globals.invert_transition = self.value
  end

  row = box:add(rtk.HBox{tmargin=5, spacing=10})
  row:add(rtk.Text{'Points shape', tmargin=5})
  local shape_menu = row:add(rtk.OptionMenu{
    menu = {
        { 'Linear' },
        { 'Square' },
        { 'Slow start/end' },
        { 'Fast start' },
        { 'Fast end' },
        { 'Bezier' },
    }
  })
  shape_menu.onchange = function (self)
    reaper.SetProjExtState(0, 'snapshooter', 'points_shape', self.selected - 1)
    globals.points_shape = self.selected - 1
    tension_text:attr('visible', self.selected == 6)
    tension_slider:attr('visible', self.selected == 6)
  end

  tension_text = row:add(rtk.Text{'Tension', tmargin=5})
  tension_slider = row:add(rtk.Slider{min=-1, max=1, tmargin=8, value=globals.points_tension})
  tension_slider.onchange = function (self)
    reaper.SetProjExtState(0, 'snapshooter', 'points_tension', self.value)
    globals.points_tension = self.value
  end
  shape_menu:select(globals.points_shape + 1)

  -- Tweening controls
  row = box:add(rtk.HBox{tmargin=10})
  row:add(rtk.Text{'Apply settings', color=0x777777})
  row = box:add(rtk.HBox{tmargin=10})
  row:add(rtk.Text{'Tween', rmargin=5, tmargin=5})
  local tween_menu = row:add(rtk.OptionMenu{
    menu = {
        { 'None', id='none' },
        { '1/4 Bar', id='1/4bar' },
        { '1/2 Bar', id='1/2bar' },
        { '1 Bar', id='1bar' },
        { '2 Bar', id='2bar' },
        { '4 Bar', id='4bar' },
        { 'Custom', id='custom' }
    }
  })

  row:add(rtk.Text{'Ease', lmargin=10, rmargin=5, tmargin=5})
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

  local duration_text = row:add(rtk.Text{'Duration', lmargin=10, tmargin=5})
  local duration_entry = row:add(rtk.Entry{value=globals.tween_custom_duration, lmargin=10, w=70})

  duration_entry.onchange = function (self)
    local value = tonumber(self.value) or 0
    globals.tween_custom_duration = value
    reaper.SetProjExtState(0, 'snapshooter', 'tween_custom_duration', value)
  end

  tween_menu.onchange = function (self)
    reaper.SetProjExtState(0, 'snapshooter', 'ui_tween_menu', self.selected)
    globals.tween = self.selected
    duration_text:attr('visible', self.selected == 'custom')
    duration_entry:attr('visible', self.selected == 'custom')
  end
  tween_menu:select(globals.tween)

  ui_refresh_buttons()
end

if not skip_init then -- skip_init set from other scripts
  ui_start()
end

return {
  savesnap = savesnap,
  applysnap = applysnap
}

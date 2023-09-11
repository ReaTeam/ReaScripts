-- @description Snapshooter
-- @author tilr
-- @version 1.0
-- @provides tilr_Snapshooter/rtk.lua
-- @screenshot https://raw.githubusercontent.com/tiagolr/snapshooter/master/doc/snapshooter.gif
-- @about
--   Snapshooter allows to create param snapshots and recall them or write them to the playlist creating patch morphs.
--   Different from SWS snapshots, only the params changed are written to the playlist as automation points.
--
--   Features:
--     * Stores and retrieves FX params
--     * Stores and retrieves mixer states for track Volume, Pan, Mute and Sends
--     * Writes only changed params by diffing the current state and selected snapshot
--     * Tested with hundreds of params with minimal overhead
--
--   Tips:
--     * Set global automation to __READ__ to save current song snapshot
--     * Set global automation to other value than __READ__ to save snapshots from mixer state
--     * If params are not writing make sure they have a different current value from the snapshot

function logmsg(t)
  reaper.ShowConsoleMsg(t .. '\n')
end
function logtable(table, indent)
  logmsg(tostring(table))
  for index, value in pairs(table) do -- print table
    logmsg('    ' .. tostring(index) .. ' : ' .. tostring(value))
  end
end

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
        reaper.InsertEnvelopePoint(envelope, cursor, reaper.ScaleToEnvelopeMode(scaling, vol), 0, 0, true)
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
function applydiff(diff, write)
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
  local exists, seltracks_chkbox = reaper.GetProjExtState(0, 'snapshooter', 'ui_checkbox_seltracks')
  local exists, vol_chkbox = reaper.GetProjExtState(0, 'snapshooter', 'ui_checkbox_volume')
  local exists, pan_chkbox = reaper.GetProjExtState(0, 'snapshooter', 'ui_checkbox_pan')
  local exists, mute_chkbox = reaper.GetProjExtState(0, 'snapshooter', 'ui_checkbox_mute')
  local exists, sends_chkbox = reaper.GetProjExtState(0, 'snapshooter', 'ui_checkbox_sends')

  -- apply diff lines
  for i,line in ipairs(diff) do
    tr = tracks[tostring(line[1])]
    if tr ~= nil then
      local track = reaper.GetTrack(0, tr)
      if seltracks_chkbox ~= 'true' or reaper.IsTrackSelected(track) then
        if #line == 3 then -- vol/pan/mute
          param = line[2]
          value = tonumber(line[3])
          if param == 'Volume' and vol_chkbox == 'true' or
            param == 'Pan' and vol_chkbox == 'true' or
            param == 'Mute' and vol_chkbox == 'true' then
            if write then
              showTrackEnvelopes(track, line[2])
              env = reaper.GetTrackEnvelopeByName(track, param)
              if param == 'Volume' then
                local scaling = reaper.GetEnvelopeScalingMode(env)
                reaper.InsertEnvelopePoint(env, cursor, reaper.ScaleToEnvelopeMode(scaling, value), 0, 0, true)
              else
                reaper.InsertEnvelopePoint(env, cursor, value, 0, 0, true)
              end
            elseif line[2] == 'Volume' then
              reaper.SetMediaTrackInfo_Value(track, "D_VOL", value)
            elseif line[2] == 'Pan' then
              reaper.SetMediaTrackInfo_Value(track, "D_PAN", value)
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
              reaper.TrackFX_SetParam(track, fxid, param, value)
            end
          else
            logmsg('fx not found '..tostring(line))
            logtable(line)
          end
        elseif #line == 7 then -- sends
          local key = line[4]
          local count = line[3]
          send = sends[key..count]
          if send and sends_chkbox == 'true' then
            cnt = tonumber(line[3])
            key = line[4]
            vol = line[5]
            pan = line[6]
            mut = line[7]
            if vol ~= 'unchanged' then
              if write then insertSendEnvelopePoint(track, key, cnt, tonumber(vol), 'VOLENV')
              else
                reaper.SetTrackSendUIVol(track, send, tonumber(vol), -1)
              end
            end
            if pan ~= 'unchanged' then
              if write then insertSendEnvelopePoint(track, key, cnt, tonumber(pan), 'PANENV')
              else reaper.SetTrackSendUIPan(track, send, tonumber(pan), -1) end
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
    applydiff(diff, write)
    rtk.callafter(1, reaper.UpdateArrange)
  else
    logmsg('could not find snap'..slot)
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
  local window = rtk.Window{w=470, h=390}
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

  row = box:add(rtk.HBox{tmargin=10})
  ui_checkbox_seltracks = row:add(rtk.CheckBox{'Selected tracks'})
  ui_checkbox_volume = row:add(rtk.CheckBox{'Vol', lmargin=15})
  ui_checkbox_pan = row:add(rtk.CheckBox{'Pan',lmargin=15})
  ui_checkbox_mute = row:add(rtk.CheckBox{'Mute', lmargin=15})
  ui_checkbox_sends = row:add(rtk.CheckBox{'Sends', lmargin=15})

  ui_checkbox_seltracks.onchange = function(self)
    reaper.SetProjExtState(0, 'snapshooter', 'ui_checkbox_seltracks', tostring(self.value))
  end
  ui_checkbox_volume.onchange = function(self)
    reaper.SetProjExtState(0, 'snapshooter', 'ui_checkbox_volume', tostring(self.value))
  end
  ui_checkbox_pan.onchange = function(self)
    reaper.SetProjExtState(0, 'snapshooter', 'ui_checkbox_pan', tostring(self.value))
  end
  ui_checkbox_mute.onchange = function(self)
    reaper.SetProjExtState(0, 'snapshooter', 'ui_checkbox_mute', tostring(self.value))
  end
  ui_checkbox_sends.onchange = function(self)
    reaper.SetProjExtState(0, 'snapshooter', 'ui_checkbox_sends', tostring(self.value))
  end

  local exists, seltracks_chk = reaper.GetProjExtState(0, 'snapshooter', 'ui_checkbox_seltracks')
  if exists and seltracks_chk == 'true' then
    ui_checkbox_seltracks:toggle()
  end
  local exists, vol_chk = reaper.GetProjExtState(0, 'snapshooter', 'ui_checkbox_volume')
  if exists and vol_chk == 'true' or exists == 0 then
    ui_checkbox_volume:toggle()
  end
  local exists, pan_chk = reaper.GetProjExtState(0, 'snapshooter', 'ui_checkbox_pan')
  if exists and pan_chk == 'true' or exists == 0 then
    ui_checkbox_pan:toggle()
  end
  local exists, mute_chk = reaper.GetProjExtState(0, 'snapshooter', 'ui_checkbox_mute')
  if exists and mute_chk == 'true' or exists == 0 then
    ui_checkbox_mute:toggle()
  end
  local exists, sends_chk = reaper.GetProjExtState(0, 'snapshooter', 'ui_checkbox_sends')
  if exists and sends_chk == 'true' or exists == 0 then
    ui_checkbox_sends:toggle()
  end

  ui_refresh_buttons()
end

ui_start()

-- interactive dev:
  -- reaper.showConsoleMsg(¨chars¨) // show console output
  -- reaper.NamedCommandLookup('_RSad7acd2e5dbd41ab15aa68ffdb01c4c5fc82c446',0)
  -- reaper.Main_OnCommand(55863, 0)

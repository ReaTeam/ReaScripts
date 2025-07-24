-- @description Group selected tracks sends
-- @author José M Muñoz (J-WalkMan)
-- @version 0.9.3
-- @changelog
--   - Fix script crashing when creating or removing sends while having more than one track selected
-- @about
--   Temporarily groups sends (not hardware outputs) along the selected tracks.
--
--   I recommend setting it up as a startup action using SWS/S&M Extension.
--
--   ---
--
--   Try activating "allow snap/grid/routing windows to stay open" on the Advanced UI/System Tweaks. This gives you the option of having a permanent window to create alternate mixes using the receives on the routing window of your "Aux", "FX", or "Output tracks".


-- Check REAPER version
local version = tonumber(reaper.GetAppVersion():match('[%d.]+'))
if version >= 7.03 then reaper.set_action_options(1) end

local _, _, sec, cmd = reaper.get_action_context()

-- ========================= FUNCTIONS ==============================

function Msg(msg)
  reaper.ClearConsole()
  reaper.ShowConsoleMsg(msg)
end

function tobool(val)
  if val == 1 then return true
  elseif val == 0 then return false
  else return nil end
end

function toint(val)
  if val then
    return 1 
  else 
    return 0 
  end
end 

function todB(Amp)
  if Amp < 6.3095734448019e-008 then
    return -1000
  end
  return 20*math.log(Amp, 10)
end

function toAmp(Lvl)
  if Lvl < -144 then
    return 1e-50
  end
  return 10^(Lvl/20)
end

function dump(o)
   if type(o) == 'table' then
      local s = ''
      for k,v in pairs(o) do
        
        if type(k) == 'number' then
          k = tostring(k)
        elseif type(k) == 'userdata' then -- if it's a track
          -- local ret, track_name = reaper.GetTrackName(k)
          k = 'track: '..tostring(k)..' name: '..track2name(k)
        elseif k == 'P_DESTTRACK' then
          k = tostring(k)
          v = track2name(v)
        elseif k == 'D_VOL' then
          v = tostring(v)..' = '..tostring(todB(v))..' dB'
        end

        if type(v) == 'table' then
          s = s..'['..k..'] = {\n'..dump(v)..'}, \n \n'
        else
          s = s..'['..k..'] = '..dump(v)..', \n' 
        end
      end
      return s
   else
      return tostring(o)
   end
end

function areTablesEqual(t1, t2, path)
    path = path or {} -- Start with an empty array to track coordinates

    if type(t1) ~= "table" or type(t2) ~= "table" then
        if t1 ~= t2 then
            return false, table.unpack(path) -- Return unpacked coordinates
        end
        return true
    end

    for k, v in pairs(t1) do
        local newPath = {table.unpack(path)} -- Copy current path
        table.insert(newPath, k) -- Append current key to the path

        local isEqual, coord1, coord2, coord3 = areTablesEqual(v, t2[k], newPath)
        if not isEqual then
            return false, coord1, coord2, coord3 -- Return the first mismatch coordinates
        end
    end

    for k, v in pairs(t2) do
        if t1[k] == nil then
            local newPath = {table.unpack(path)}
            table.insert(newPath, k)
            return false, table.unpack(newPath)
        end
    end

    return true
end

function track2name(track)
  local ret, track_name = reaper.GetTrackName(track)
  return tostring(track_name)
end

function GetSelectedTrackSends(num)
  local updated_track, updated_send, updated_param, value_diff
  local table = {}

  for tr_idx = 1, num do
    local track = reaper.GetSelectedTrack(proj, tr_idx-1)
    local n_sends = reaper.GetTrackNumSends(track, category)
    -- reaper.ShowConsoleMsg(track2name(track)..'\n')
    
    table[track] = {}
    -- reaper.ShowConsoleMsg('sel track id: '..tostring(tr_idx)..' track: '..tostring(track)..'\n content: '..tostring(table[track]))
    
    for snd_idx = 1, n_sends do
      local __, send_name = reaper.GetTrackSendName(track, snd_idx-1)
      -- reaper.ShowConsoleMsg(' >'..tostring(snd_idx)..' '..tostring(send_name)..'\n')
      
      table[track][snd_idx] = {
        ['P_DESTTRACK'] = 0; 
        ['D_VOL'] = 0; 
        ['D_PAN'] = 0; 
        ['B_MUTE'] = 0; 
        ['B_MONO'] = 0; 
        ['I_SENDMODE'] = 0; 
      }
      
      for i = 1, #send_params do
        local param_value = reaper.GetTrackSendInfo_Value( track, category, snd_idx-1, send_params[i])
        table[track][snd_idx][send_params[i]] = param_value
        
        -- reaper.ShowConsoleMsg('  -'..tostring(send_params[i])..' '..tostring(table[track][snd_idx][send_params[i]])..'\n')
      end
      -- reaper.ShowConsoleMsg('\n')
    end
    -- print('=============\n')
  end
  
  return table
end

function sendClassFormat(new, ref, prev, param)
  local value_to_write
  if param == 'D_VOL' then
    new = todB(new)
    ref = todB(ref)
    prev = todB(prev)
    value_to_write = new - (prev - ref)
    -- if value_to_write > 12 then
    --   value_to_write = 12
    -- elseif value_to_write < -144 then
    --   value_to_write = -1000
    -- end
    value_to_write = toAmp(value_to_write)
  
  elseif param == 'D_PAN' then
    value_to_write = (new + (ref - new))

    if value_to_write > 1 then
      value_to_write = 1
    elseif value_to_write < -1 then
      value_to_write = -1
    end

  elseif param == 'B_MUTE' or param == 'B_MONO' then
    value_to_write = toint( not tobool(new) )
    
  elseif param == 'I_SENDMODE' then
    value_to_write = ref
  end
  return value_to_write
end

-- ======================== INITIAL VALUES ===============================

Proj = 0 --current project
category = 0 --Only works for sends

send_params = {'P_DESTTRACK', 'D_VOL', 'D_PAN', 'B_MUTE', 'B_MONO', 'I_SENDMODE'}
send_mute = {'active', 'muted'}
send_mono = {'Stereo', 'Mono'}
send_mode = {'post-fader', 'pre-fx', nil, 'pre-fader'}

sends_table = {}
prev_sends_table = {}

function Main()
  --reaper.ClearConsole()

  local sel_tracks_num = reaper.CountSelectedTracks(0)
  -- local mod_keys, mod_has_alt = ModifiersPressed()
  -- reaper.ShowConsoleMsg(tostring(sel_tracks_num)..' selected tracks: \n')

  --if sel_tracks_num > 0 and not mod_has_alt then
  
  if sel_tracks_num > 0 then -- Only activate if there are multiple selected tracks and Alt/Opt is not pressed
    
    sends_table = GetSelectedTrackSends(sel_tracks_num)
    local are_tables_equal, moved_tr, moved_snd_idx, moved_param = areTablesEqual(sends_table, prev_sends_table)
    -- reaper.ShowConsoleMsg(dump(sends_table))

    if not are_tables_equal and moved_param~=nil and moved_param~='P_DESTTRACK' then
      --reaper.ShowConsoleMsg('Moving: '..track2name(moved_tr)..', '..track2name(sends_table[moved_tr][moved_snd_idx]['P_DESTTRACK'])..', '..moved_param..'\n')

      for tr, snd_list in pairs(sends_table) do
        -- reaper.ShowConsoleMsg('track: '..track2name(tr)..', '..#snd_list..' sends \n')
        
        if #snd_list > 0 then
          for snd_idx, snd_param in pairs(snd_list) do
            local moved_send = sends_table[moved_tr][moved_snd_idx]
            local prev_moved_send = prev_sends_table[moved_tr][moved_snd_idx]
            local send_to_write = sends_table[tr][snd_idx]
            
            local is_send_equal = send_to_write['P_DESTTRACK'] == moved_send['P_DESTTRACK']

            if is_send_equal and tr~=moved_tr then
              local new_value = sendClassFormat(send_to_write[moved_param], moved_send[moved_param], prev_moved_send[moved_param], moved_param)
              -- reaper.ShowConsoleMsg('  Track: '..track2name(tr)..'\n')
              -- reaper.ShowConsoleMsg('  - Send moved: '..track2name(moved_send['P_DESTTRACK'])..'\n')
              -- reaper.ShowConsoleMsg('  - Send to update: '..track2name(send_to_write['P_DESTTRACK'])..'\n')
              -- reaper.ShowConsoleMsg('    - Moved parameter is: '..moved_param..'\n')
              -- reaper.ShowConsoleMsg('    -> Old Value is: '..send_to_write[moved_param]..'\n')
              -- reaper.ShowConsoleMsg('    -> New Value is: '..new_value..'\n')
              
              reaper.SetTrackSendInfo_Value(tr, category, snd_idx-1, moved_param, new_value)
            end
          end
        end
      end
    end

    prev_sends_table = GetSelectedTrackSends(sel_tracks_num)
  else
    prev_sends_table = {}
  end
  reaper.defer(Main)
end
reaper.SetToggleCommandState(sec, cmd, 1)
reaper.RefreshToolbar2(sec, cmd)

function Exit()
    reaper.SetToggleCommandState(sec, cmd, 0)
    reaper.RefreshToolbar2(sec, cmd)
end

reaper.atexit(Exit)
reaper.defer(Main)

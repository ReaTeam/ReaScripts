-- @description Route selected tracks to new Channel Selector track above them
-- @author amagalma
-- @version 1.1
-- @changelog
--   - Fix: remove the channel selector track when action is run with only that track selected
--   - Fix: no JSFX file is left over if the channel selector track is removed manually
--   - SWS not required any more
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Routes the selected tracks to a new track above them so you can A/B between them
--   - A custom JSFX is added with the names of the routed tracks
--   - Smooth audio transition between tracks (code by geraintluff)
--   - If track is deleted or JSFX is removed from the channel, then the initially selected tracks return to their initial state
--   - If script is run with only the channel selector track selected, then it gets removed and everything gets back to initial state
--   - If you are prompted by Reaper when running the script, choose New Istance and Remember
--    
--   JSFX code for the JS smooth channel selector by geraintluff - thanks!! :)

--------------------------------------------------------------------------------------------------

local sep = reaper.GetOS():find("Win") and "\\" or "/"
local path
local _, projfn = reaper.EnumProjects( -1, "" )
local saved_project = false
if projfn == "" then
  path = reaper.GetResourcePath() .. sep .."Effects" .. sep .. "custom channel selector"
else
  saved_project = true
  path = string.match(projfn, ".+" .. sep) .. "Effects"
end

--------------------------------------------------------------------------------------------------

local tr_cnt = reaper.CountSelectedTracks( 0 )
local sel_track = reaper.GetSelectedTrack( 0, 0 )
local SelectorTrack

if tr_cnt == 1 then
  -- remove channel selector if exists
  local ok, tr_name = reaper.GetTrackName( sel_track )
  local selector_nr
  
  if ok and tr_name == "Channel selector" then
    for fx = 0,  reaper.TrackFX_GetCount( sel_track )-1 do
      local ok, name = reaper.TrackFX_GetFXName( sel_track, fx )
      if ok then
        selector_nr = name:match("^Custom channel selector(%d*)")
        break
      end
    end
    if selector_nr then
      reaper.Undo_BeginBlock2( 0 )
      local filepath = path .. sep .. "chan_select" .. selector_nr
      if reaper.file_exists( filepath ) then
        os.remove(filepath)
      end
      local receives_cnt = reaper.GetTrackNumSends( sel_track, -1 )
      for i = 0, receives_cnt-1 do
        local track = reaper.GetTrackSendInfo_Value( sel_track, -1 , i, "P_SRCTRACK" )
        reaper.SetMediaTrackInfo_Value( track, 'B_MAINSEND', 1 )
        reaper.SetMediaTrackInfo_Value( track, 'I_SELECTED', 1 )
      end
      reaper.DeleteTrack( sel_track )
      reaper.Undo_EndBlock2( 0, "Remove channel selector" , 1|2 )
    end
  else
    return reaper.defer(function() end)
  end
  
elseif tr_cnt > 1 then

  -- add channel selector
  reaper.Undo_BeginBlock2( 0 )
  reaper.PreventUIRefresh( 1 )
  local sel_tr_names = {}
  local sel_tr = {}
  local sel_tr_guid = {}
  for i = 0, tr_cnt-1 do
    local tr = reaper.GetSelectedTrack( 0, i )
    sel_tr[#sel_tr+1] = tr
    sel_tr_guid[reaper.GetTrackGUID( tr )] = true
    local _, name = reaper.GetSetMediaTrackInfo_String( tr, "P_NAME", "", false )
    local number = reaper.GetMediaTrackInfo_Value( tr, "IP_TRACKNUMBER" ) + 1
    if name == "" or not name then name = "Track " .. math.floor(number) end
    sel_tr_names[#sel_tr_names+1] = name
    reaper.SetMediaTrackInfo_Value( tr, 'B_MAINSEND', 0 )
  end
  local first_track_id = reaper.GetMediaTrackInfo_Value( sel_track, "IP_TRACKNUMBER" )
  reaper.InsertTrackAtIndex(  first_track_id - 1, false )
  SelectorTrack = reaper.GetTrack( 0, first_track_id-1 )
  reaper.SetOnlyTrackSelected( SelectorTrack )
  for i = 1, #sel_tr do
    reaper.CreateTrackSend( sel_tr[i], SelectorTrack )
  end
  reaper.SetMediaTrackInfo_Value( SelectorTrack, "I_NCHAN", tr_cnt*2 )
  reaper.SetTrackColor( SelectorTrack, reaper.ColorToNative(201,227,227) )
  reaper.GetSetMediaTrackInfo_String( SelectorTrack, "P_NAME" , "Channel selector", true )
  for i = 1, tr_cnt-1 do
    reaper.SetTrackSendInfo_Value( SelectorTrack, -1, i, "I_DSTCHAN", 2*i )
  end
  local track_names = table.concat(sel_tr_names, ",")
  
  reaper.RecursiveCreateDirectory( path, 0 )
  
  local JSFX_name, number = "chan_select"
  local directory = {}
  local i = -1
  while true do
    i = i + 1
    local filename = reaper.EnumerateFiles( path, i )
    if not filename then break
    else directory[#directory+1] = filename
    end
  end
  local biggest = 0
  for i = 1, #directory do
    if string.match(directory[i], "chan_select%d+") then
      number = tonumber(string.match(directory[i], "chan_select(%d+)"))
      if number > biggest then biggest = number end
    end
  end
  number = math.ceil(biggest + 1)
  JSFX_name = "chan_select" .. number
  
  local file = io.open(path .. sep .. JSFX_name, "w")
  file:write([[
desc:Custom Channel Selector

]] .. "slider1:target_channel_combo=0<0," .. tr_cnt .. ",1{" .. track_names .. "}>Track to audition\n" ..
[[
out_pin:Left
out_pin:Right

@init

function update_target_channel() (
  target_channel_combo < ]] .. tr_cnt+1 .. [[ ? (
    channel_target0 = target_channel_combo*2;
    channel_target1 = target_channel_combo*2 + 1;
  );
);

function update_fade_channel() (
  channel_fade_from0 = channel_fade_to0;
  channel_fade_from1 = channel_fade_to1;
  channel_fade_to0 = channel_target0;
  channel_fade_to1 = channel_target1;
  
  channel_fade_from0 != channel_fade_to0 || channel_fade_from1 != channel_fade_to1 ? (
    fade_ratio = 1;
  ) : (
    fade_ratio = 0;
  )
);

update_target_channel();
update_fade_channel();
update_fade_channel();

@slider

fade_samples = srate*0.035;
fade_step = -1/fade_samples;
update_target_channel();
fade_ratio <= 0 ? (
  update_fade_channel();
);

@sample

function fade_sample(from, to) (
  spl(to) + (spl(from) - spl(to))*fade_ratio;
);

fade_ratio ? (
  spl0 = fade_sample(channel_fade_from0, channel_fade_to0);
  spl1 = fade_sample(channel_fade_from1, channel_fade_to1);
  fade_ratio += fade_step;
  fade_ratio <= 0 ? (
    update_fade_channel();
  );
) : (
  spl0 = spl(channel_target0);
  spl1 = spl(channel_target1);
);]])
  file:close()
  
  -- add FX and float it at the center of the screen
  local _, chunk = reaper.GetTrackStateChunk( SelectorTrack, '' )
  local ch_t = {}
  for line in chunk:gmatch('[^\r\n]+') do
    if line:find("FXCHAIN") or line:find(">") then break
    else ch_t[#ch_t+1] = line
    end
  end
  chunk = table.concat(ch_t, '\n')
  local _, _, scr_w, scr_h = reaper.my_getViewport(0,0,0,0,0,0,0,0, true)
  local Xpos = math.ceil((scr_w - 505) /2)
  local Ypos = math.ceil((scr_h - 120) /2)
  local fxchunk = "\n" ..
[[<FXCHAIN
SHOW 0
LASTSEL 0
DOCKED 0
BYPASS 0 0 0
<JS ]] ..
( not saved_project and ('"' .. JSFX_name .. '"')
or ("<Project>/" .. JSFX_name) ) .. ' "Custom channel selector' .. number .. [["
0.000000 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
>
FLOAT ]] .. Xpos .. " " .. Ypos .. " 505 120\n>\n>"
  chunk = chunk .. fxchunk
  reaper.SetTrackStateChunk( SelectorTrack, chunk )
  
      local function ReenableMainSends()
        for i = 0, reaper.GetNumTracks()-1 do
          local track = reaper.GetTrack( 0, i )
          if sel_tr_guid[reaper.GetTrackGUID(track)] then -- track still exists
            reaper.SetMediaTrackInfo_Value( track, 'B_MAINSEND', 1 )
            reaper.SetMediaTrackInfo_Value( track, 'I_SELECTED', 1 )
          end
        end
      end

  local NAME = "Custom channel selector" .. number
  
      local function main()
        if not reaper.ValidatePtr2( 0, SelectorTrack, "MediaTrack*" ) then
          -- track was deleted
          ReenableMainSends()
          os.remove(path .. sep .. JSFX_name)
          return
        elseif reaper.TrackFX_GetByName( SelectorTrack, NAME, false ) < 0 then
          -- FX was deleted
          reaper.Undo_BeginBlock2( 0 )
          reaper.PreventUIRefresh( 1 )
          reaper.DeleteTrack( SelectorTrack )
          ReenableMainSends()
          reaper.PreventUIRefresh( -1 )
          reaper.Undo_EndBlock2( 0, "Remove channel selector" , 1|2 )
          os.remove(path .. sep .. JSFX_name)
          return
        else
          reaper.defer( main )
        end
      end
  
  reaper.PreventUIRefresh( -1 )
  reaper.TrackList_AdjustWindows( true )
  reaper.Undo_EndBlock2( 0, "Add channel selector" , 1|2 )
  main()
  
else

  -- do nothing
  return reaper.defer(function() end)
  
end

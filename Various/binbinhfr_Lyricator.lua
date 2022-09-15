-- @description Lyricator
-- @author binbinhfr
-- @version 1.0
-- @changelog 1.0 : initial release
-- @about
--   --   + displays lyrics in a separate window.
--   --   + use the context menu (mouse right click)
--   --   + lyrics are imported from a TEXT file (one sentence per line, can contain empty lines) in the form of media items 
--   --     in a dedicated lyrics track, named "Lyrics" (not case sensitive)
--   --   + if not existing, this track is created.
--   --   + by default, the TEXT file is searched into the project directory.
--   --   + during import, lyrics can be added at the end of the existing lyrics as new items, or can replace the existing ones
--   --   + after import, you can move and resize items to synchronize currently displayed lyrics with the underlying music.
--   --   + the currently displayed lyric lines depend on the edit or play cursor on the timeline.
--   --   + by default, the size of the lyrics window is bigger when the project is playing, 
--   --     to easily read the lyrics from your recording position
--   --   + when the project is stopped, the window is smaller to allow easy editing of the tracks underneath.
--   --   + you can change this behaviour with the "auto size" option
--   --   + you can also change the fonts sizes
--   --   + you can change the position and size of the window in both playing/stopped modes. It will be retained for next reaper session.
--   --   + you can change the default duration of a lyric item, and the default duration of the gap between lyric items.
--   --   + note that the first track called "lyrics" is taken into account, so you can have several of them,
--   --     and put the active one in the first place.
--   --   + to avoid useless cpu work, note that, if you modify the lyric track during playback, the display is not updated.
--   --     you have to stop and resume playback.

-- @description Lyricator
-- @version 1.0
-- @author binbinhfr
-- @website http://forum.cockos.com/showthread.php?t=
-- @changelog
--    + v1.0 initial release
-- @license GPL v3
-- @reaper 6.6x
-- @about
--   + displays lyrics in a separate window.
--   + use the context menu (mouse right click)
--   + lyrics are imported from a TEXT file (one sentence per line, can contain empty lines) in the form of media items 
--     in a dedicated lyrics track, named "Lyrics" (not case sensitive)
--   + if not existing, this track is created.
--   + by default, the TEXT file is searched into the project directory.
--   + during import, lyrics can be added at the end of the existing lyrics as new items, or can replace the existing ones
--   + after import, you can move and resize items to synchronize currently displayed lyrics with the underlying music.
--   + the currently displayed lyric lines depend on the edit or play cursor on the timeline.
--   + by default, the size of the lyrics window is bigger when the project is playing, 
--     to easily read the lyrics from your recording position
--   + when the project is stopped, the window is smaller to allow easy editing of the tracks underneath.
--   + you can change this behaviour with the "auto size" option
--   + you can also change the fonts sizes
--   + you can change the position and size of the window in both playing/stopped modes. It will be retained for next reaper session.
--   + you can change the default duration of a lyric item, and the default duration of the gap between lyric items.
--   + note that the first track called "lyrics" is taken into account, so you can have several of them,
--     and put the active one in the first place.
--   + to avoid useless cpu work, note that, if you modify the lyric track during playback, the display is not updated.
--     you have to stop and resume playback.

----------------------------------------------------------------------------------------------------------
do_debug = false

extension = "lyricator"
win_title = "Lyricator"

lyric_duration = 2.0
lyric_gap = 1.0
win_dock = 0
win_w = {500,1000}
win_h = {115,290}
win_x = {200,250}
win_y = {200,250}
win_font_size = {18,48}
win_font_height = {18,48}
win_auto_resize = 1
win_idx = 1
last_win_idx = 2

track_lyrics = nil
track_lyrics_name = "Lyrics"

count_loops = 0
playstate = -1
last_playstate = -1
is_playing = false
ask_reset = false

lyrics = {}
starts = {}
ends = {}
nb_lyrics = -1

----------------------------------------------------------------------------------------------------------
if do_debug then
  function print(s)
    gfx.x = 10
    gfx.y = gfx.y + 10
    gfx.printf("%s", s)  
  end 
  
  function msg(param, clr) 
    if clr then reaper.ClearConsole() end 
    reaper.ShowConsoleMsg(tostring(param).."\n") 
  end
else
  function print(s)
  end 
  
  function msg(param, clr) 
  end
end

-----------------------------------------------------------------------------------------
function test(cond,val1,val2)
  if cond then return val1 else return val2 end
end

-----------------------------------------------------------------------------------------
function focus_to_reaper()
  reaper.JS_Window_SetForeground( reaper.GetMainHwnd() )
end

-----------------------------------------------------------------------------------------
function set_font(n,font_size)
  win_font_size[n] = font_size
  gfx.setfont(n,"verdana",font_size)
  win_font_height[n] = gfx.texth
end

-----------------------------------------------------------------------------------------
function msg_wins(title)
  msg(title)
  msg("dur " .. lyric_duration .. " gap " .. lyric_gap)
  msg("dock " .. win_dock .. " auto_resize " .. win_auto_resize)
  msg("win[1] ".. win_w[1] .. "," .. win_h[1] .. " " .. win_x[1] .. "," .. win_y[1] )
  msg("font[1] " .. win_font_size[1])
  msg("win[2] ".. win_w[2] .. "," .. win_h[2] .. " " .. win_x[2] .. "," .. win_y[2] )
  msg("font[2] " .. win_font_size[2])
end

-----------------------------------------------------------------------------------------
function get_ext_states()
  lyric_duration = tonumber(reaper.GetExtState(extension,"lyric_duration")) or lyric_duration
  lyric_gap = tonumber(reaper.GetExtState(extension,"lyric_gap")) or lyric_gap

  win_dock = tonumber(reaper.GetExtState(extension,"win_dock")) or win_dock
  win_auto_resize = tonumber(reaper.GetExtState(extension,"win_auto_resize")) or win_auto_resize

  win_w[1] = tonumber(reaper.GetExtState(extension,"win_w1")) or win_w[1]
  win_h[1] = tonumber(reaper.GetExtState(extension,"win_h1")) or win_h[1]
  win_x[1] = tonumber(reaper.GetExtState(extension,"win_x1")) or win_x[1]
  win_y[1] = tonumber(reaper.GetExtState(extension,"win_y1")) or win_y[1]
    
  win_w[2] = tonumber(reaper.GetExtState(extension,"win_w2")) or win_w[2]
  win_h[2] = tonumber(reaper.GetExtState(extension,"win_h2")) or win_h[2]
  win_x[2] = tonumber(reaper.GetExtState(extension,"win_x2")) or win_x[2]
  win_y[2] = tonumber(reaper.GetExtState(extension,"win_y2")) or win_y[2]
    
  set_font(1,tonumber(reaper.GetExtState(extension,"win_font_size1")) or win_font_size[1])
  set_font(2,tonumber(reaper.GetExtState(extension,"win_font_size2")) or win_font_size[2])
  
  msg_wins("init")
end

-----------------------------------------------------------------------------------------
function quit()
  if( ask_reset ) then
    raz_extstate()
  else
    local d,x,y,w,h = gfx.dock(-1, 0, 0, 0, 0)
  
    win_dock = d
    if(win_dock == 0) then
      win_x[win_idx], win_y[win_idx], win_w[win_idx], win_h[win_idx] = x,y,w,h
    end
    
    reaper.SetExtState(extension,"lyric_duration",lyric_duration,true)
    reaper.SetExtState(extension,"lyric_gap",lyric_gap,true)
    
    reaper.SetExtState(extension,"win_dock",win_dock,true)
    reaper.SetExtState(extension,"win_auto_resize",win_auto_resize,true)
    
    reaper.SetExtState(extension,"win_w1",win_w[1],true)
    reaper.SetExtState(extension,"win_h1",win_h[1],true)
    reaper.SetExtState(extension,"win_x1",win_x[1],true)
    reaper.SetExtState(extension,"win_y1",win_y[1],true) 
    
    reaper.SetExtState(extension,"win_w2",win_w[2],true)
    reaper.SetExtState(extension,"win_h2",win_h[2],true)
    reaper.SetExtState(extension,"win_x2",win_x[2],true)   
    reaper.SetExtState(extension,"win_y2",win_y[2],true) 
    
    reaper.SetExtState(extension,"win_font_size1",win_font_size[1],true)
    reaper.SetExtState(extension,"win_font_size2",win_font_size[2],true)
  end
  
  msg_wins("quit")  
  
  gfx.quit()
end

-----------------------------------------------------------------------------------------
function raz_extstate()
  reaper.DeleteExtState(extension,"lyric_duration",true)
  reaper.DeleteExtState(extension,"lyric_gap",true)
  
  reaper.DeleteExtState(extension,"win_dock",true)
  reaper.DeleteExtState(extension,"win_auto_resize",true)

  reaper.DeleteExtState(extension,"win_w1",true)
  reaper.DeleteExtState(extension,"win_h1",true)
  reaper.DeleteExtState(extension,"win_x1",true)
  reaper.DeleteExtState(extension,"win_y1",true)  
  
  reaper.DeleteExtState(extension,"win_w2",true)
  reaper.DeleteExtState(extension,"win_h2",true)
  reaper.DeleteExtState(extension,"win_x2",true)
  reaper.DeleteExtState(extension,"win_y2",true)  
  
  reaper.DeleteExtState(extension,"win_font_name",true)
  reaper.DeleteExtState(extension,"win_font_size",true)
  reaper.DeleteExtState(extension,"win_font_size1",true)
  reaper.DeleteExtState(extension,"win_font_size2",true)
  
  reaper.SetProjExtState(0,extension,"","")
end

-----------------------------------------------------------------------------------------
function find_lyrics_track()
  local track_idx, retval, track_name
  
  for track_idx = 0, reaper.CountTracks(0) - 1 do
    track = reaper.GetTrack(0, track_idx)
    retval, track_name = reaper.GetTrackName(track, "")
    if( retval and string.lower(track_name) == string.lower(track_lyrics_name) ) then
      return track
    end
  end
  
  return null
end

-----------------------------------------------------------------------------------------
function select_lyrics_track()
  local track_idx, retval, track_name
  
  for track_idx = 0, reaper.CountTracks(0) - 1 do
    track = reaper.GetTrack(0, track_idx)
    retval, track_name = reaper.GetTrackName(track, "")
    reaper.SetTrackSelected(track, (retval and string.lower(track_name) == string.lower(track_lyrics_name)) )
  end
end

-----------------------------------------------------------------------------------------
function read_lyrics_from_items()
  local n_item, item

  track_lyrics = find_lyrics_track()
  
  lyrics = {}
  starts = {}
  ends = {}
  nb_lyrics = 0
  
  if(track_lyrics) then
    nb_lyrics =  reaper.CountTrackMediaItems(track_lyrics)
    
    for n_item = 0, nb_lyrics-1 do
      item = reaper.GetTrackMediaItem(track_lyrics, n_item)
      if item ~= nil then
        lyrics[n_item] = reaper.ULT_GetMediaItemNote(item)
        starts[n_item] = reaper.GetMediaItemInfo_Value(item, "D_POSITION" )
        ends[n_item] =  starts[n_item] + reaper.GetMediaItemInfo_Value(item, "D_LENGTH" )
      end
    end
  else
    nb_lyrics = 0
  end
end

-----------------------------------------------------------------------------------------
function find_lyrics_track_end()
  local item
  local t_end = 0

  if(track_lyrics) then
    nb_lyrics =  reaper.CountTrackMediaItems(track_lyrics)
    
    if(nb_lyrics > 0) then
      item = reaper.GetTrackMediaItem(track_lyrics, nb_lyrics-1)
      if item ~= nil then
        t_end = reaper.GetMediaItemInfo_Value(item, "D_POSITION" ) + reaper.GetMediaItemInfo_Value(item, "D_LENGTH" )
      end
    end
  end
  
  msg(t_end)
  
  return( t_end )
end

-----------------------------------------------------------------------------------------
function import_lyrics(do_add)
  local item, n_item
  local t = 0
  local track_created = false
  
  path = ""
  retval, filename = reaper.EnumProjects(-1, '')
  
  if(retval) then
    if(filename == "") then
      path = reaper.GetResourcePath()
    else
      msg("project:" .. filename)
      path = filename:match("^(.+[\\/])") 
    end
    msg("dir:" .. path)
  end
  
  retval, filename = reaper.GetUserFileNameForRead(path, "Open a lyrics text file", "*.txt" )
  --retval, filename = true, "E:\\Reaper\\Test07lyrics\\lyrics.txt"
  
  if(retval) then
    reaper.Undo_BeginBlock()

    track_lyrics = find_lyrics_track()
    
    if( not track_lyrics ) then
      reaper.InsertTrackAtIndex(0,false)
      track_lyrics = reaper.GetTrack(0,0)
      reaper.GetSetMediaTrackInfo_String(track_lyrics,"P_NAME",track_lyrics_name,true)
      if(track_lyrics) then track_created = true end
    end
    
    if(track_lyrics) then
      msg("importing:" .. filename)
      
      io.input(filename)
      
      local lyrics_file = {}
  
      for line in io.lines() do
        if(line == "") then line = " " end
        table.insert(lyrics_file, line)
      end
      
      io.close()
      
      if(do_add) then
        -- add after last item
        t = find_lyrics_track_end()
        if( t > 0 ) then t = t + lyric_gap end
        msg(t)
        
        for i, l in ipairs(lyrics_file) do 
          msg("[" .. l .. "]")
        
          item = reaper.AddMediaItemToTrack(track_lyrics)
          reaper.SetMediaItemPosition(item,t,true)
          reaper.SetMediaItemLength(item,lyric_duration,true)
          reaper.ULT_SetMediaItemNote(item,l)
          t = t + lyric_duration + lyric_gap
        end
      else
        -- replace existing items and complete with new items if needed
        nb_lyrics =  reaper.CountTrackMediaItems(track_lyrics)
        n_item = 0
  
        for i, l in ipairs(lyrics_file) do 
          msg("[" .. l .. "]")
          
          if( n_item < nb_lyrics ) then
            item = reaper.GetTrackMediaItem(track_lyrics, n_item)
            if item ~= nil then
              reaper.ULT_SetMediaItemNote(item,l)
              t = reaper.GetMediaItemInfo_Value(item, "D_POSITION" ) + reaper.GetMediaItemInfo_Value(item, "D_LENGTH" ) + lyric_gap
            end
          else
            item = reaper.AddMediaItemToTrack(track_lyrics)
            reaper.SetMediaItemPosition(item,t,true)
            reaper.SetMediaItemLength(item,lyric_duration,true)
            reaper.ULT_SetMediaItemNote(item,l)
            t = t + lyric_duration + lyric_gap
          end
          
          n_item = n_item + 1
        end      
      end
    end
    
    reaper.Undo_EndBlock("Import lyrics", test(track_created,1,0) & 4)
  end
  
  reaper.UpdateArrange()
end

-----------------------------------------------------------------------------------------
function menu_ctx()
  menu = ""
  --menu = menu .. "#LYRICATOR"
  menu = menu .. "Import lyrics text file (add)"
  menu = menu .. "|Import lyrics text file (replace)"
  menu = menu .. "||Lyric media duration (" .. lyric_duration .. "s)"
  menu = menu .. "|Gap between lyric medias (" .. lyric_gap .. "s)"
  menu = menu .. "||" .. test(is_playing,"#","") .. test(win_auto_resize,"!","") .. "Auto resize (stopped/playing)"
  menu = menu .. "|Font size while stopped (" .. win_font_size[1] .. "px)" 
  menu = menu .. "|Font size while playing (" .. win_font_size[2] .. "px)" 
  menu = menu .. "||Reset"

  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  t = gfx.showmenu(menu)
  
  msg("choice ".. t)
  
  if t == 1 then
    import_lyrics(true)
    
  elseif t == 2 then
    import_lyrics(false)
    
  elseif t == 3 then
    retval, value = reaper.GetUserInputs("Lyric media duration", 1, "Duration", tostring(lyric_duration))
    if(retval) then 
      value = tonumber(value) or lyric_duration
      if(value < 0.1) then value = 0.1 end
      if(value > 20.0) then value = 20.0 end
      lyric_duration = value
    end
    
  elseif t == 4 then
    retval, value = reaper.GetUserInputs("Gap between lyric medias", 1, "Duration", tostring(lyric_gap))
    if(retval) then 
      value = tonumber(value) or lyric_gap
      if(value < 0.1) then value = 0.1 end
      if(value > 20.0) then value = 20.0 end
      lyric_gap = value
    end
    
  elseif t == 5 then
    if( not is_playing ) then
      win_auto_resize = test( win_auto_resize,0,1)
    end
    
  elseif t == 6 then
    retval, value = reaper.GetUserInputs("Font size while stopped", 1, "font size", tostring(win_font_size[1]))
    if(retval) then 
      value = tonumber(value) or win_font_size[1]
      if(value < 8) then value = 8 end
      if(value > 100) then value = 100 end
      set_font(1,value)
    end
    
  elseif t == 7 then
    retval, value = reaper.GetUserInputs("Font size while playing", 1, "font size", tostring(win_font_size[2]))
    if(retval) then 
      value = tonumber(value) or win_font_size[2]
      if(value < 8) then value = 8 end
      if(value > 100) then value = 100 end
      set_font(2,value)
    end  
    
  elseif t == 8 then
    ask_reset = true
  end
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
function main()
  count_loops = count_loops + 1
  if(count_loops == 15) then count_loops = 0 end
  
  playstate = reaper.GetPlayState()
  is_playing = (playstate & 1 ~= 0)
  
  last_win_idx = win_idx
  
  if( is_playing ) then
    -- song running
    cursor = reaper.GetPlayPosition()
    if(nb_lyrics < 0) then
      read_lyrics_from_items()
    end    
    win_idx = test(win_auto_resize, 2, 1)
  else
    -- song stopped 
    cursor = reaper.GetCursorPosition()
    if(count_loops == 0 or nb_lyrics <= 0) then
      read_lyrics_from_items()
    end
    win_idx = 1
  end
  
  if(count_loops == 0) then
    --focus_to_reaper()
  end

  if( last_playstate ~= playstate ) then
    if(last_playstate == -1) then
      gfx.init(win_title,win_w[win_idx],win_h[win_idx],win_dock,win_x[win_idx],win_y[win_idx])
    else
      if(last_win_idx ~= win_idx ) then
        win_dock, win_x[last_win_idx], win_y[last_win_idx], win_w[last_win_idx], win_h[last_win_idx] = gfx.dock(-1, 0, 0, 0, 0)
        gfx.init("",win_w[win_idx],win_h[win_idx],win_dock,win_x[win_idx],win_y[win_idx])
      end
    end
    gfx.setfont(win_idx)
    --focus_to_reaper()
    last_playstate = playstate
  end
  
  if( do_debug ) then
    gfx.x = win_w[win_idx] - 6 * win_font_size[win_idx]
    gfx.y = 10
    
    if( playstate & 1 == 0 ) then
      -- song stopped
      gfx.set(0.9,0.9,0.9)
      gfx.printf("S")
    else
      -- song running
      if(playstate & 4 == 0) then
        gfx.set(0.2,1,0.2)
        gfx.printf("P")
      else
        gfx.set(1,0.2,0.2)
        gfx.printf("R")
      end
    end
    
    gfx.printf("%d", count_loops)
  end
  
  if( nb_lyrics > 0 ) then
    local n_item, n_item_cur, start1, start2, end1 
 
    gfx.x = 10
    gfx.y = -win_font_height[win_idx]
    
    n_item_cur = nb_lyrics-1
    start1 = starts[n_item_cur]
    end1 = ends[n_item_cur]
    start2 = start1+end1
    
    for n_item = 0, nb_lyrics-1 do
      if( cursor <= starts[n_item] ) then
        n_item_cur = n_item-1
        if( n_item_cur < 0 ) then
          start1 = 0
          end1 = 0
        else
          start1 = starts[n_item_cur]
          end1 = ends[n_item_cur]
        end
        start2 = starts[n_item]
        break
      end
    end       
    
    if( start1 < start2) then
      gfx.y = gfx.y + win_font_height[win_idx] * (start2 - cursor) / (start2-start1)
    else
      gfx.y = gfx.y + win_font_height[win_idx]
    end 
     
    for n_item = n_item_cur-3, n_item_cur+3 do
      if(n_item == n_item_cur and cursor <= end1) then
        gfx.set(1,1,1)
      else
        gfx.set(0.6,0.6,0.6)
      end

      if(n_item < 0) then
        gfx.x = 10
        gfx.y = gfx.y + win_font_height[win_idx]
      elseif(n_item < nb_lyrics) then
        gfx.printf( "%s", lyrics[n_item] )
        gfx.x = 10
        gfx.y = gfx.y + win_font_height[win_idx]
      end
    end
  else
    gfx.x = 10
    gfx.y = 10
    gfx.printf( "No lyrics found..." )

    gfx.x = 10
    gfx.y = gfx.y + win_font_height[win_idx]
    gfx.printf( "Please import a lyrics text file (right mouse click for menu).")
  end
  
  if( gfx.mouse_cap & 2 ~= 0 ) then
    menu_ctx()
  end

  local c = gfx.getchar()
  if (c >= 0) and (not ask_reset) then
    reaper.defer(main)
  end  
  
  gfx.update()
end

-----------------------------------------------------------------------------------------

msg("",true)

reaper.atexit(quit)

get_ext_states()

focus_to_reaper()

main()



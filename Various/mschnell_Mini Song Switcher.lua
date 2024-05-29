-- @description Mini Song Switcher
-- @author mschnell
-- @version 1.0
-- @changelog Initial Release
-- @provides . > mschnell_Song Switcher.eel
-- @about
--   # Mini Song Switcher
--    ## Description
--      The mschnell_Song Switcher is inspired by the cfillion_Song Switcher.
--
--      It is a lot less versatile and only features a single script and no GUI
--
--      Other than the cfillion_Song Switcher is dies not work on the foregrounmd Project (Tab) but on the first project (Tab) that holds a project with the string _song_ in it's name.
--
--      If such is not found, it works on the foreground poject (Tab). Don't forget to enable  all three background project playing options !
--
--      It uses the same track structure as the cfillion_Song Switcher (Description see there)
--
--      When a CC action is received it unmutes the track named according to the CC value (e.g. 1. XYZ or 23. Hello)
--
--      It  then start playback (from the location pf the play cursor) 
--
--      When a value of 0 is found or no appropriate track is fond the playback is stopped.

   #tab_name = "*_song_*";
   get_action_context(#filename, sectionID, cmdID, mode, resolution, val);
   
   tab = 0;
   while (
     proj = EnumProjects(tab, #proj_name);
     p = proj;
     n = match("*_song_*", #proj_name);
     n ? (
       p = 0;
     );
     tab += 1;
     p;
   );

   running = GetPlayState();
   val != 0  ? (

     track_count = CountTracks(proj);
     
     song_found = 0;
     track_index = 0;
     loop (track_count,
       track = GetTrack(proj, track_index);
       has_name = GetTrackName(track, #track_name);
       has_name ? (
         
         c0 = str_getchar(#track_name, 0);
         c1 = str_getchar(#track_name, 1);
         c2 = str_getchar(#track_name, 2);
         song_no = -1;
         c1 == '.' ? (
           (c0 >= '0') && (c0 <= '9') ? song_no = c0 - '0';
         );
         c2 == '.' ? (
           (c0 >= '0') && (c0 <= '9') || (c1 >= '0') && (c1 <= '9') ? (
              song_no = (c0 - '0') * 10 + (c1 -'0');
           );   
         );

         song_no != -1 ? ( 
           song_no == val ? (
             mute = 0;
             song_found = 1;
             #play_name = #track_name;
            ) : ( 
             mute = 1;
           ); 
           SetMediaTrackInfo_Value(track, "B_MUTE", mute);        // set unmute 
         );         
       );
       track_index += 1;
     );
     CSurf_OnStop();
     song_found != 0 ? (
       CSurf_OnPlay();
       sprintf(#s, "Song Started: %s\r\n", #play_name); 
       ShowConsoleMsg(#s);
      ) : (
       sprintf(#s, "Song does not exist: %d\r\n", val);
       ShowConsoleMsg(#s);
     )
    ) : (
     running ? (
       CSurf_OnStop();
       ShowConsoleMsg("Song Stopped\r\n");
     );  
   )

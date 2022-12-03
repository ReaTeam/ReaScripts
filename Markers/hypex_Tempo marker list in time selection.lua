-- @description Tempo marker list in time selection
-- @author Hypex
-- @version 1.0
-- @screenshot https://github.com/Hypexed/Reaper-Scripts/blob/main/TempoList/TempoList.png
-- @about
--   ### Tempo Marker List
--
--   Displays a list of tempo markers within time selection.
--
--   Will show table with Marker, Time, Meter, BPM, Bar, Beat and Linear setting.
--
--   Marker: Index in list.  
--   Time: On timeline.  
--   Meter: Time signature if set.  
--   BPM: Tempo at time.  
--   Bar: Bar set at time.  
--   Beat: Beat count at time.  
--   Linear: Set if gradual change.


function List()
(
    Markers = CountTempoTimeSigMarkers(0);
 
    Markers ?
    (
        #List = "Legend: Marker, Time, Meter, BPM, Bar, Beat, Linear\n\n";

        GetSet_LoopTimeRange(0, 0, RangeStart, RangeEnd, 0);
        RangeStart ?
        (
            Marker = FindTempoTimeSigMarker(0, RangeStart);
            Start = RangeStart;
            End = RangeEnd;
        )
        :
        (
            Marker = 0;
            Start = 0;
            End = GetProjectLength(0);
        );
        
        
        Count = 0;
        
        while(Marker < Markers)
        (
            GetTempoTimeSigMarker(0, Marker, Time, Bar, Beat, BPM, Note, Size, Linear);
            
            (Time >= RangeStart) && (Time <= RangeEnd) ? 
            (
                format_timestr(Time, #Time);
                
                (Note == -1) && (Size == -1) ?
                (
                    #Meter = "-/-";
                )
                :
                (
                    sprintf(#Meter, "%d/%d", Note, Size);
                );
                
                sprintf(#Info, "%d, %s, %s, %.9f, %d, %.9f, %d\n", Marker, #Time, #Meter, BPM, Bar, Beat, Linear);
                #List += #Info;
                Count += 1;
            );
            
            Marker += 1;
        );
        
        Count ?
        (
            ShowMessageBox(#List, #Title, 0);
        )
        :
        (
            ShowMessageBox("Info: No tempo markers found within time selection.", #Title, 0);
        );
    )
    :
    (
        ShowMessageBox("Info: No tempo markers exist in current project.", #Title, 0);
    );
);

function main()
(
    #Title="Tempo Marker List";

    List();
);

main();

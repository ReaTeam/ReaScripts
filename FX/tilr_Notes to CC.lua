-- @description Notes to CC
-- @author tilr
-- @version 1.0
-- @about
--   # Notes to CC
--
--   Sends CC events on midi notes, note pitch is mapped to CC value, useful to create keyboard param modulations or keytracking.
--   Includes controls for CC param, note min, note max and param range values.

desc:Notes to CC

slider1:0<0, 127, 1>Note min
slider2:127<0, 127, 1>Note max
slider3:0<0, 127, 1>Param min
slider4:127<0, 127, 1>Param max
slider5:0<0,15,1{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16>Channel
slider6:60<0,127,1{0 Bank Sel M,1 Mod Wheel M,2 Breath M,3,4 Foot P M,5 Porta M,6 Data Entry M,7 Vol M,8 Balance M,9,10 Pan M,11 Expression M,12 Ctrl 1 M,13 Ctrl 2 M,14,15,16 GP Slider 1,17 GP Slider 2,18 GP Slider 3,19 GP Slider 4,20,21,22,23,24,25,26,27,28,29,30,31,32 Bank Sel L,33 Mod Wheel L,34 Breath L,35,36 Foot P L,37 Porta L,38 Data Entry L,39 Vol L,40 Balance L,41,42 Pan L,43 Expression L,44 Ctrl 1 L,45 Ctrl 2 L,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64 Hold P sw,65 Porta sw,66 Sustenuto sw,67 Soft P sw,68 Legato P sw,69 Hold 2 P sw,70 S.Variation,71 S.Timbre,72 S.Release,73 S.Attack,74 S.Brightness,75 S.Ctrl 6,76 S.Ctrl 7,77 S.Ctrl 8,78 S.Ctrl 9,79 S.Ctrl 10,80 GP B.1 sw,81 GP B.2 sw,82 GP B.3 sw,83 GP B.4 sw,84,85,86,87,88,89,90,91 Effects Lv,92 Trem Lv,93 Chorus Lv,94 Celeste Lv,95 Phaser Lv,96 Data B. Inc,97 Data B. Dec,98 NRP L,99 NRP M,100 RP L,101 RP M,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127}>Param
slider7:1<0,1,1{No, Yes}>Send Notes

////////////////////////////////////////////////////////////////////////////////
@init
statNoteOn = $x90;
statNoteOff = $x80;

////////////////////////////////////////////////////////////////////////////////
@slider
slider1 > slider2 ? slider2 = slider1;
slider3 > slider4 ? slider3 = slider4;
noteMin = slider1;
noteMax = slider2;
paramMin = slider3;
paramMax = slider4;
sendNote = slider7;

////////////////////////////////////////////////////////////////////////////////
@block

while
(

  midirecv(offset,msg1,note,vel) ?
  (

    send = 1;

    // Extract message type and channel
    status = msg1 & $xF0;
    channel = msg1 & $x0F;

    // Is it a note event?
    status == statNoteOn || status == statNoteOff ?
    (

        send = 0; // Don't send MIDI

        status == statNoteOn ? ( // Send Only if Note On

          msg2 = slider6;
          note > noteMax ? note = noteMax;
          note < noteMin ? note = noteMin;
          // linear mapping
          scale = (paramMax-paramMin) / (noteMax-noteMin);
          _offset = (-noteMin * (paramMax - paramMin)) / (noteMax - noteMin) + paramMin;
          value = note * scale + _offset;
          msg23 = (msg2 + 256*ceil(value))|0;
          midisend(offset, 11*16 + slider5, msg23); // send CC

        );

        sendNote == 1 ? midisend(offset, msg1, note, vel); // send note

      );

    send == 1 ? midisend(offset,msg1,note,vel); // passthrough

    1; // Force loop to continue until all messages have been processed

  );

);

-- @description Midi Strummer
-- @author Phillip Cartwright
-- @version 1.0
-- @provides [main=main] .

// This effect Copyright (C) 2017 and later by Phillip Cartwright
// License: GPL - http://www.gnu.org/licenses/gpl.html

desc: MIDI Strummer
slider1:1<1,16,1>MIDI Chord Channel
slider2:1<1,16,1>MIDI Strum Channel
slider3:.5<0,1,.01>Vel. Ratio (0 = 100% Chord, 1 = 100% Strum)
slider4:15<0,200,.01>Time between each note (ms)
slider5:36<0,127,1{0: C0,1: C#0,2: D0,3: Eb0,4: E0,5: F0,6: F#0,7: G0,8: G#0,9: A0,10: Bb0,11: B0,12: C1,13: C#1,14: D1,15: Eb1,16: E1,17: F1,18: F#1,19: G1,20: G#1,21: A1,22: Bb1,23: B1,24: C2,25: C#2,26: D2,27: Eb2,28: E2,29: F2,30: F#2,31: G2,32: G#2,33: A2,34: Bb2,35: B2,36: C3,37: C#3,38: D3,39: Eb3,40: E3,41: F3,42: F#3,43: G3,44: G#3,45: A3,46: Bb3,47: B3,48: C4,49: C#4,50: D4,51: Eb4,52: E4,53: F4,54: F#4,55: G4,56: G#4,57: A4,58: Bb4,59: B4,60: C5,61: C#5,62: D5,63: Eb5,64: E5,65: F5,66: F#5,67: G5,68: G#5,69: A5,70: Bb5,71: B5,72: C6,73: C#6,74: D6,75: Eb6,76: E6,77: F6,78: F#6,79: G6,80: G#6,81: A6,82: Bb6,83: B6,84: C7,85: C#7,86: D7,87: Eb7,88: E7,89: F7,90: F#7,91: G7,92: G#7,93: A7,94: Bb7,95: B7,96: C8,97: C#8,98: D8,99: Eb8,100: E8,101: F8,102: F#8,103: G8,104: G#8,105: A8,106: Bb8,107: B8,108: C9,109: C#9,110: D9,111: Eb9,112: E9,113: F9,114: F#9,115: G9,116: G#9,117: A9,118: Bb9,119: B9,120: C10,121: C#10,122: D10,123: Eb10,124: E10,125: F10,126: F#10,127: G10}>Down strum
slider6:38<0,127,1{0: C0,1: C#0,2: D0,3: Eb0,4: E0,5: F0,6: F#0,7: G0,8: G#0,9: A0,10: Bb0,11: B0,12: C1,13: C#1,14: D1,15: Eb1,16: E1,17: F1,18: F#1,19: G1,20: G#1,21: A1,22: Bb1,23: B1,24: C2,25: C#2,26: D2,27: Eb2,28: E2,29: F2,30: F#2,31: G2,32: G#2,33: A2,34: Bb2,35: B2,36: C3,37: C#3,38: D3,39: Eb3,40: E3,41: F3,42: F#3,43: G3,44: G#3,45: A3,46: Bb3,47: B3,48: C4,49: C#4,50: D4,51: Eb4,52: E4,53: F4,54: F#4,55: G4,56: G#4,57: A4,58: Bb4,59: B4,60: C5,61: C#5,62: D5,63: Eb5,64: E5,65: F5,66: F#5,67: G5,68: G#5,69: A5,70: Bb5,71: B5,72: C6,73: C#6,74: D6,75: Eb6,76: E6,77: F6,78: F#6,79: G6,80: G#6,81: A6,82: Bb6,83: B6,84: C7,85: C#7,86: D7,87: Eb7,88: E7,89: F7,90: F#7,91: G7,92: G#7,93: A7,94: Bb7,95: B7,96: C8,97: C#8,98: D8,99: Eb8,100: E8,101: F8,102: F#8,103: G8,104: G#8,105: A8,106: Bb8,107: B8,108: C9,109: C#9,110: D9,111: Eb9,112: E9,113: F9,114: F#9,115: G9,116: G#9,117: A9,118: Bb9,119: B9,120: C10,121: C#10,122: D10,123: Eb10,124: E10,125: F10,126: F#10,127: G10}>Up Strum
slider7:1<0,1,1{No,Yes}>Send note-off before re-strum?
slider8:0<-15,15,1>Decrease or Increase Velocity

@init

k = 0;
tmp = -1;
activeNotes = 1000;
activeVel = 2000;
activeNotes[-1] = -1;
activeVel[-1] = -1;
countNotes = 0;
buf = 5000;



i = 0;
loop(128,
    activeNotes[i] = -1;
    activeVel[i] = -1;
    i += 1;
);

@slider 

cChan = slider1 - 1;
mChan = slider2 - 1;
cVel = 1 - slider3;
mVel = slider3;
strm = srate*slider4*.001;
dnst = slider5;
upst = slider6;
noteOffStrum = slider7;
newVel = slider8;

@block

function ResetArray() local (i)
(
    tmp = -1;
    i = 0;
    loop(128,
	   activeNotes[i] = -1;
	   i += 1;
    );
);

function SortNotes() local (i j)
(
    swap = 0;
    i = 0;
    while (i <= countNotes)(
	   activeNotes[i] < activeNotes[i+1] ? (
		  tmp = activeNotes[i];
		  activeNotes[i] = activeNotes[i+1];
		  activeNotes[i+1] = tmp;
		  tmp = activeVel[i];
		  activeVel[i] = activeVel[i+1];
		  activeVel[i+1] = tmp;
		  i = 0;
		  swap = 1;
	   );
	   swap == 0 ? i += 1;
	   swap = 0;
    );
);

function AddNote(msg2, msg3) local (i j)
(
	i = 0;
	j = 0;
	while ((j == 0) && (i < 128)) (
		activeNotes[i] == -1 ? (
			j = 1;
			activeNotes[i] = msg2;
			activeVel[i] = msg3;               
		): i += 1;
	);
);

function RemoveNote(msg2) local (i j)
(
    i = 0;
    loop(128,
	   activeNotes[i] == msg2 ? (
		  activeNotes[i] = -1;
		  activeVel[i] = -1;
	   );
	   i += 1;
    );
);

function IsStrumDown()
(
	((msg1 == (0x90 + mChan)) && (msg2 == dnst) && (msg3 > 0)) ? (1) : 0;
	
);

function IsStrumUp()
(
	((msg1 == (0x90 + mChan)) && (msg2 == upst) && (msg3 > 0)) ? (1) : 0;
	
);
function IsStrumDownEnd()
(
	((msg1 == (0x90 + mChan)) && (msg2 == dnst) && (msg3 == 0)) ||
	((msg1 == (0x80 + mChan)) && (msg2 == dnst)) ? (1) : 0;     
);

function IsStrumUpEnd()
(
	((msg1 == (0x90 + mChan)) && (msg2 == upst) && (msg3 == 0)) ||
	((msg1 == (0x80 + mChan)) && (msg2 == upst)) ? (1) : 0;
	
);

function sendNoteOff()
(
	i = 0;
	j = activeNotes[i];
	// send all active chord note off
	while((i < countNotes) && (j != -1)) (
		midisend(os, 0x80 + cChan, activeNotes[i], activeVel[i]);
		i += 1;
		j = activeNotes[i];
	);
);

while (midirecv(os,msg1,msg2,msg3)) (
	// if CC 64
	(msg1 == (0xB0 + mChan)) && (msg2 == 64) && (msg3 >= 64) ? (
		latch = 1;
		latchTgl = 0;
		midisend(os, msg1, msg2, msg3);
	) : (msg1 == (0xB0 + mChan)) && (msg2 == 64) && (msg3 < 64) ? (
		latch = 0;
		midisend(os, msg1, msg2, msg3);
	// if note-on and if carrier channel AND not mod and note
	) : (msg1 == (0x90 + cChan)) && (msg3 > 0) && !(IsStrumUp() || IsStrumDown()) ? (
		countNotes += 1;
		AddNote(msg2, msg3);
		SortNotes();
		(strumUp + strumDown > 0) ? (
			midisend(os, msg1, msg2, msg3);
		);
	// else if note off and carrier channel and not mod and note
	) : (((msg1 == (0x90 + cChan)) && (msg3 == 0)) || (msg1 == (0x80 + cChan)) && !(IsStrumUpEnd() || IsStrumDownEnd())) ? (
		countNotes -= 1;
		RemoveNote(msg2);
		SortNotes();
		// send note off (prevents stuck MIDI notes)
		midisend(os, msg1, msg2, msg3);
	) : IsStrumUp() ? (
		(((strumUp + strumDown + latch > 0)) && (noteOffStrum == 1)) ? (
			sendNoteOff();
		);
		i = 0;
		j = activeNotes[i];
		n = 0;
		// add all chord notes to buffer
		while(i < countNotes) (
			j != -1 ? (
				buf[k + 0] = os + (n*strm);
				buf[k + 1] = 0x90 + cChan;
				buf[k + 2] = activeNotes[i];
				buf[k + 3] = max(min(127,((cVel * activeVel[i]) + (mVel * msg3)))+(n*newVel),1);
				k += 4;
				n += 1;
			);
			i += 1;
			j = activeNotes[i];      
		);
		strumUp = 1;  
	) : IsStrumDown() ? (
		(((strumUp + strumDown + latch > 0)) && (noteOffStrum == 1)) ? (
			sendNoteOff();
		);
		i = countNotes;
		j = activeNotes[i];
		n = 0;
		// add all chord notes to buffer
		while(i >= 0) (
			j != -1 ? (
				buf[k + 0] = os + (n*strm);
				buf[k + 1] = 0x90 + cChan;
				buf[k + 2] = activeNotes[i];
				buf[k + 3] = max(min(127,((cVel * activeVel[i]) + (mVel * msg3)))+(n*newVel),1);
				k += 4;
				n += 1;
			);
			i -= 1;
			j = activeNotes[i];
		);
		strumDown = 1;   
	) : IsStrumDownEnd() ? (
		((strumUp * strumDown) == 0) && (latch == 0) ? (
			sendNoteOff();
		);
		strumDown = 0;
	) :  IsStrumUpEnd() ? (
		((strumUp * strumDown) == 0) && (latch == 0) ? (
			sendNoteOff();
		);
		strumUp = 0;
	) :  midisend(os, msg1, msg2, msg3);
	
	((latch == 0) && (strumUp + strumDown == 0) && (latchTgl == 0)) ? (
		sendNoteOff();
		latchTgl = 1;
	);
);

i = 0;
while (i < k)  (
    os = buf[i + 0];
    os < samplesblock ? (
	   midisend(os, buf[i + 1], buf[i + 2], buf[i + 3]);
	   memcpy(buf + i, buf + i + 4, k - i);
	   k -= 4;
    ) : (
	   buf[i + 0] -= samplesblock;
	   i += 4;
    );
);


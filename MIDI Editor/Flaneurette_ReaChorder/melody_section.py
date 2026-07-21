try:
    from reaper_python import *
except ImportError:
    pass
try:
    import tkinter
    from tkinter import ttk
except ImportError:
    pass
try:
    from rs_midi import RSMidi
except ImportError:
    pass
try:
    from random import randint
except ImportError:
    pass
try:
    import reaChord_data
except ImportError:
    pass
try:
    from rs_statemanager import RSStateManager
except ImportError:
    pass

class MelodySection(RSStateManager):

    #rc = reaChord_functions.RC() # comment out - for autocomplete

    def __init__(self, parent, rc):

        self.settings = {
            "draw": 0, "channel": 2, "velocity": 96, "highlight": 1, "harmony": 1, "extranoteprobability" : 50
        }
        self.msg("Chords __init__  Enter")
        self.stateManager_Start("MelodySection", self.settings)

        self.parent = parent
        self.rc = rc
        self.init_widgets()
        self.msg("Chords __init__  Exit")

    def draw(self, midiTake, song, sectionLength):
        if not(self.drawOrNot.get()): return
        currentPos = 0

        melodyType = self.MelodyTypeSel.current()
        for i, sect in enumerate(song["Structure"]):
            chords = song[str(sect)]
            chordLength = sectionLength / len(chords)
            for chord in chords:
                self.drawMelody(midiTake, chord, currentPos, chordLength)
                currentPos += chordLength
        return currentPos

    def drawMelody(self,midiTake, chord, currentPos, chordLength):
        self.msg('drawMelody - Enter')
        harmony1 = self.harmony.get()
        melodyType = self.MelodyTypeSel.current()
        harmony2 = False # if True, add "harmony2"
        randNote = randint(1, 3)
        randPos = [0,480,960]
        randLength = [0.5, 1, 2]

        velocity = self.velocity.get()
        selectNote = self.highlight.get()
        channel = self.channel.get()


        for j, vm in enumerate(self.rc.ChordDict[chord]):
            self.msg(str(j) + str(vm) + str(self.rc.ChordDict[chord]))
            if j % randNote == 0:
                rpos = randPos[randint(0,2)]
                rlen = randLength[randint(0,2)]
                # this is the original melody
                firstNotePosInChord = randint(0, 2)
                # harmony for "3 note chords"
                if firstNotePosInChord == 0:
                    secondNotePosInChord = 1
                    thirdNotePosInChord = 2

                elif firstNotePosInChord == 1:
                    secondNotePosInChord = 2
                    thirdNotePosInChord = 0
                else:
                    secondNotePosInChord = 1
                    thirdNotePosInChord = 2

                r = randint(0, 100)
                if r < int(self.extraNoteProb.get()):
                    randExtraNote = False
                else:
                    randExtraNote = False

                # draw melody

                # melodyType = int(self.MelodyTypeSel.current())
                melodyType = 0
				# Circle of fifths
                if melodyType == 0:
                    RSMidi.addNote(midiTake, int(channel), int(velocity), int(currentPos + rpos), int(self.rc.ChordDict[chord][firstNotePosInChord]), int(self.rc.quartNoteLength * rlen), selectNote)
                    currentPos += rpos + (self.rc.quartNoteLength * rlen)
				# Markov
                if melodyType == 1:
                    chain = self.rc.ChordDictMnamed[chord][randint(1,11)];
                    RSMidi.addNote(midiTake, int(channel), int(velocity), int(currentPos + rpos), int(self.rc.ChordDict[chord][firstNotePosInChord]), int(self.rc.quartNoteLength * rlen), selectNote)
                    currentPos += rpos + (self.rc.quartNoteLength * rlen)
                # Primes				
                if melodyType == 2:
                    primenote = self.rc.PrimeChain[0][randint(1,11)]
                    RSMidi.addNote(midiTake, int(channel), int(velocity), int(currentPos), int(self.rc.ChordDict[chord][firstNotePosInChord]), int(self.rc.quartNoteLength * rlen), selectNote)
                    currentPos += rpos + (self.rc.quartNoteLength * rlen)				
				
                if harmony1 == 1:
                    # "humanize"
                    harmony1Pos = rpos + randint(-60, 60)
                    if harmony1Pos < 0:
                        harmony1Pos = 0
                    velocity1 = velocity * 0.8
                    # draw "harmony"1
                    RSMidi.addNote(midiTake, int(channel), int(velocity1), int(currentPos + harmony1Pos), int(self.rc.ChordDict[chord][secondNotePosInChord]),\
                                        int(self.rc.quartNoteLength * rlen), selectNote)
                
                if harmony2 == 1:
                    # "humanize"
                    harmony2Pos = rpos + randint(-60, 60)
                    if harmony2Pos < 0:
                        harmony2Pos = 0
                    velocity2 = velocity * 0.8
                    # draw "harmony" 2
                    RSMidi.addNote(midiTake, int(channel), int(velocity2), int(currentPos + harmony2Pos), int(self.rc.ChordDict[chord][thirdNotePosInChord]),\
                                        int(self.rc.quartNoteLength * rlen), selectNote)
                
                if randExtraNote:
                    RSMidi.addNote(midiTake, int(channel), int(velocity), int(currentPos + rpos), int(self.rc.ChordDict[chord][randint(0, 2)]), int(self.rc.quartNoteLength * rlen), selectNote)
            else:
                RSMidi.addNote(midiTake, int(channel), int(velocity), int(currentPos), int(vm), int(self.rc.quartNoteLength), selectNote)
                currentPos += self.rc.quartNoteLength

        return currentPos

    def init_widgets(self):
        self._label_1 = tkinter.Label(self.parent,
            text = "Draw:",
        )
        self._label_2 = tkinter.Label(self.parent,
            text = "Highlight:",
        )
        self._label_3 = tkinter.Label(self.parent,
            text = "Channel:",
        )
        self._label_4 = tkinter.Label(self.parent,
            text = "Velocity:",
        )
        ''''
        self._label_5 = tkinter.Label(self.parent,
            text = "Seed:",
        )
        '''
        self._label_6 = tkinter.Label(self.parent,
            text = "Random:",
        )
        self._label_7 = tkinter.Label(self.parent,
            text = "Harmony:",
        )
        
        self._label_8 = tkinter.Label(self.parent,
            text = "Melody type:",
        )		
        
        self.drawOrNot = self.newControlIntVar("draw", 1)
        self.cDrawOrNot = tkinter.Checkbutton(self.parent, variable=self.drawOrNot)
        self.highlight = self.newControlIntVar("highlight", 0)
        self.cHighlight = tkinter.Checkbutton(self.parent, variable=self.highlight)
        self.channel = self.newControlIntVar("channel", 2)
        self.sChannel = tkinter.Scale(self.parent, from_=1, to=16, resolution=1, showvalue=0, orient="horizontal", variable=self.channel)
        self.scaleTxt1 = ttk.Label(self.parent, textvariable=self.channel)
		
        self.velocity = self.newControlIntVar("velocity", 96)
        self.sVelocity = tkinter.Scale(self.parent, from_=1, to=127, resolution=1, showvalue=0, orient="horizontal", variable=self.velocity)
        self.scaleTxt2 = ttk.Label(self.parent, textvariable=self.velocity)
		
        self.harmony = self.newControlIntVar("harmony", 0)
        self.cHarmony = tkinter.Checkbutton(self.parent, variable=self.harmony)
	
        self.extraNoteProb = self.newControlIntVar("extranoteprob", 50)
        self.sExtraNoteProb = tkinter.Scale(self.parent, from_=0, to=100, resolution=1, showvalue=0, orient="horizontal", variable=self.extraNoteProb)
        self.scaleTxt3 = ttk.Label(self.parent, textvariable=self.extraNoteProb)
        self.MelodyTypeSel = ttk.Combobox(self.parent, values=self.rc.MelodyType, state='readonly', width=13)
        self.MelodyTypeSel.current(0)

        # Geometry Management
        self._label_1.grid(
            in_    = self.parent,
            column = 1,
            row    = 1,
            columnspan = 1,
            ipadx = 10,
            ipady = 5,
            padx = 0,
            pady = 5,
            rowspan = 1,
            sticky = "w"
        )
        self._label_2.grid(
            in_    = self.parent,
            column = 1,
            row    = 2,
            columnspan = 1,
            ipadx = 10,
            ipady = 5,
            padx = 0,
            pady = 5,
            rowspan = 1,
            sticky = "w"
        )
        self._label_3.grid(
            in_    = self.parent,
            column = 1,
            row    = 3,
            columnspan = 1,
            ipadx = 10,
            ipady = 5,
            padx = 0,
            pady = 5,
            rowspan = 1,
            sticky = "w"
        )
        self._label_4.grid(
            in_    = self.parent,
            column = 1,
            row    = 4,
            columnspan = 1,
            ipadx = 10,
            ipady = 5,
            padx = 0,
            pady = 5,
            rowspan = 1,
            sticky = "w"
        )
 
        '''
        self._label_5.grid(
            in_    = self.parent,
            column = 1,
            row    = 5,
            columnspan = 1,
            ipadx = 10,
            ipady = 0,
            padx = 0,
            pady = 10,
            rowspan = 1,
            sticky = "w"
        )
        '''
        self._label_6.grid(
            in_    = self.parent,
            column = 1,
            row    = 5,
            columnspan = 1,
            ipadx = 10,
            ipady = 5,
            padx = 0,
            pady = 5,
            rowspan = 1,
            sticky = "w"
        )
        self._label_7.grid(
            in_    = self.parent,
            column = 3,
            row    = 6,
            columnspan = 1,
            ipadx = 10,
            ipady = 5,
            padx = 0,
            pady = 0,
            rowspan = 1,
            sticky = "w"
        )
        
        self._label_8.grid(
            in_    = self.parent,
            column = 1,
            row    = 6,
            columnspan = 1,
            ipadx = 10,
            ipady = 5,
            padx = 0,
            pady = 0,
            rowspan = 1,
            sticky = "w"
        )
        	
        self.scaleTxt1.grid(
            in_    = self.parent,
            column = 2,
            row    = 3,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 2,
            pady = 0,
            rowspan = 1,
            sticky = "e"
        )
        self.scaleTxt2.grid(
            in_    = self.parent,
            column = 2,
            row    = 4,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 2,
            pady = 0,
            rowspan = 1,
            sticky = "e"
        )
        self.scaleTxt3.grid(
            in_    = self.parent,
            column = 2,
            row    = 5,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 2,
            pady = 0,
            rowspan = 1,
            sticky = "e"
        )

        self.cDrawOrNot.grid(
            in_    = self.parent,
            column = 2,
            row    = 1,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 0,
            pady = 0,
            rowspan = 1,
            sticky = "w"
        )
        self.cHighlight.grid(
            in_    = self.parent,
            column = 2,
            row    = 2,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 0,
            pady = 0,
            rowspan = 1,
            sticky = "w"
        )

        
        self.MelodyTypeSel.grid(
            in_    = self.parent,
            column = 2,
            row    = 6,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 0,
            pady = 0,
            rowspan = 1,
            sticky = "w"
        )
        
        self.sVelocity.grid(
            in_    = self.parent,
            column = 2,
            row    = 4,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 0,
            pady = 0,
            rowspan = 1,
            sticky = "w"
        )		
        self.sChannel.grid(
            in_    = self.parent,
            column = 2,
            row    = 3,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 0,
            pady = 0,
            rowspan = 1,
            sticky = "w"
        )
        self.sExtraNoteProb.grid(
            in_    = self.parent,
            column = 2,
            row    = 5,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 0,
            pady = 0,
            rowspan = 1,
            sticky = "w"
        )
        self.cHarmony.grid(
            in_    = self.parent,
            column = 4,
            row    = 6,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 0,
            pady = 0,
            rowspan = 1,
            sticky = "w"
        )
        self.parent.grid_rowconfigure(1, weight = 0, minsize = 22, pad = 0)
        self.parent.grid_rowconfigure(2, weight = 0, minsize = 22, pad = 0)
        self.parent.grid_rowconfigure(3, weight = 0, minsize = 22, pad = 0)
        self.parent.grid_rowconfigure(4, weight = 0, minsize = 22, pad = 0)
        self.parent.grid_rowconfigure(5, weight = 0, minsize = 22, pad = 0)
        self.parent.grid_rowconfigure(6, weight = 0, minsize = 22, pad = 0)
        self.parent.grid_columnconfigure(1, weight = 0, minsize = 80, pad = 0)
        self.parent.grid_columnconfigure(2, weight = 0, minsize = 135, pad = 0)

    def msg(self, m):
        if (reaChord_data.debug):
            RPR_ShowConsoleMsg(str(m)+'\n')
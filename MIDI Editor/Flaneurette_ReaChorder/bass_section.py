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
    import reaChord_data
except ImportError:
    pass
try:
    from rs_statemanager import RSStateManager
except ImportError:
    pass

class BassSection(RSStateManager):

    #rc = reaChord_functions.RC() # comment out - for autocomplete
    def __init__(self, parent, rc):
        self.settings = {
            "draw": 0, "channel": 3, "velocity": 96, "highlight": 1, "invert_above": 6
        }
        self.stateManager_Start("BassSection", self.settings)
        self.parent = parent
        self.rc = rc
        self.init_widgets()

    def draw(self, midiTake, song, sectionLength):
        if not(self.drawOrNot.get()): return
        currentPos = 0
        for i, sect in enumerate(song["Structure"]):
            chords = song[str(sect)]
            chordLength = sectionLength / len(chords)
            for chord in chords:
                self.drawBass(midiTake, chord, currentPos, chordLength)
                currentPos += chordLength
        return currentPos

    def drawBass(self,midiTake, chord, currentPos, chordLength):

        velocity = self.velocity.get()
        selectNote = self.highlight.get()
        channel = self.channel.get()
        bassTechnique = self.bassPick.get()
        bassOctaves = self.bassOct.get()

        alternateLength = chordLength / 2

        if bassOctaves == 'One octave': 
            drop = 24
        elif bassOctaves == 'Two octaves':
            drop = 36
        else:
            drop = 24

        if bassTechnique == 'Whole': 
            RSMidi.addNote(midiTake, channel, int(velocity), int(currentPos), int(self.rc.ChordDict[chord][0])-drop, int(chordLength), selectNote)
        elif bassTechnique == 'Quarter': 
            RSMidi.addNote(midiTake, channel, int(velocity), int(currentPos), int(self.rc.ChordDict[chord][0])-drop, int(960), selectNote)     
            RSMidi.addNote(midiTake, channel, int(velocity), int(currentPos)+960, int(self.rc.ChordDict[chord][0])-drop, int(960), selectNote)
            currentPos +=960
            RSMidi.addNote(midiTake, channel, int(velocity), int(currentPos)+960, int(self.rc.ChordDict[chord][0])-drop, int(960), selectNote)
            currentPos +=960            
            RSMidi.addNote(midiTake, channel, int(velocity), int(currentPos)+960, int(self.rc.ChordDict[chord][0])-drop, int(960), selectNote)             
        elif bassTechnique == 'Half': 
            RSMidi.addNote(midiTake, channel, int(velocity), int(currentPos), int(self.rc.ChordDict[chord][0])-drop, int(1920), selectNote)     
            RSMidi.addNote(midiTake, channel, int(velocity), int(currentPos)+1920, int(self.rc.ChordDict[chord][0])-drop, int(1920), selectNote)
            currentPos +=1920            
        else:
            RSMidi.addNote(midiTake, channel, int(velocity), int(currentPos), int(self.rc.ChordDict[chord][0])-drop, int(chordLength), selectNote)
            
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
        self._label_5= tkinter.Label(self.parent,
            text = "Octave:",
        )
        self._label_6= tkinter.Label(self.parent,
            text = "Picking:",
        )
        self.drawOrNot = self.newControlIntVar("draw", 1)
        self.cDrawOrNot = tkinter.Checkbutton(self.parent, variable=self.drawOrNot)
        self.highlight = self.newControlIntVar("highlight", 0)
        self.cHighlight = tkinter.Checkbutton(self.parent, variable=self.highlight)
        self.channel = self.newControlIntVar("channel", 3)
        self.sChannel = tkinter.Scale(self.parent, from_=1, to=16, resolution=1, showvalue=0, orient="horizontal", variable=self.channel)
        self.scaleTxt1 = ttk.Label(self.parent, textvariable=self.channel)
        self.velocity = self.newControlIntVar("velocity", 96)
        self.sVelocity = tkinter.Scale(self.parent, from_=1, to=127, resolution=1, showvalue=0, orient="horizontal", variable=self.velocity)
        self.scaleTxt2 = ttk.Label(self.parent, textvariable=self.velocity)
        
       
        self.bassOct = self.newControlStrVar("bassoctave", self.rc.bassOct[1])
        self.cbbassOctave = ttk.Combobox(self.parent, values=self.rc.bassOct, state='readonly', width=13, textvariable=self.bassOct)
        
        self.bassPick = self.newControlStrVar("basspick", self.rc.bassPick[1])
        self.cbbassPick = ttk.Combobox(self.parent, values=self.rc.bassPick, state='readonly', width=13, textvariable=self.bassPick)

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
        self._label_5.grid(
            in_    = self.parent,
            column = 1,
            row    = 5,
            columnspan = 2,
            ipadx = 10,
            ipady = 0,
            padx = 0,
            pady = 10,
            rowspan = 1,
            sticky = "w"
        )   
        self._label_6.grid(
            in_    = self.parent,
            column = 1,
            row    = 6,
            columnspan = 2,
            ipadx = 10,
            ipady = 0,
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
        self.cbbassOctave.grid(
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
        self.cbbassPick.grid(
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
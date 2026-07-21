try:
    import tkinter
    from tkinter import ttk, font, RAISED
except ImportError:
    pass
try:
    import reaChord_data
except ImportError:
    pass
try:
    from random import randint
except ImportError:
    pass
try:
    import re
except ImportError:
    pass

class Wizard:

    #rc = reaChord_functions.RC() #comment out - for  autocomplete
    def __init__(self, parent, rc, song):
        self.frameWizard = parent
        self.rc = rc
        self.song = song
        self.initWidgets()

    def initWidgets(self):
        self.txt2 = tkinter.Text(self.frameWizard, width='50', height='1')
        self.txt = tkinter.Text(self.frameWizard, width='50', height='9')
        self.txt.config(state="disabled") #set read-only

        comboWidth = 21

        self.cbMoods = ttk.Combobox(self.frameWizard, values=self.rc.Moods, state='readonly', width=13)
        self.cbMoods.current(0)
        self.cbMoodsCust = ttk.Entry(self.frameWizard,width=7)
        self.cbInKey = ttk.Combobox(self.frameWizard, values=self.rc.InKey, state='readonly', width=comboWidth)
        self.cbInKey.current(0)
        self.cbScales = ttk.Combobox(self.frameWizard, values=self.rc.Scales, state='readonly', width=comboWidth)
        self.cbScales.current(0)
        self.cbStructure = ttk.Combobox(self.frameWizard, values=self.rc.entriesStructures, state='readonly', width=comboWidth)
        self.cbStructure.current(0)
        self.btns1 = ttk.Button(self.frameWizard, text='Propose progression', width='22')
        self.btns1.bind('<Button-1>', lambda event: self.getVals())

        # Geometry Management
        self.txt2.grid(
            in_    = self.frameWizard,
            column = 2,
            row    = 1,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 0,
            pady = 0,
            rowspan = 1,
            sticky = "ew"
        )
        self.txt.grid(
            in_    = self.frameWizard,
            column = 2,
            row    = 2,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 0,
            pady = 0,
            rowspan = 7,
            sticky = "nsew"
        )
        self.cbMoodsCust.grid(
            in_    = self.frameWizard,
            column = 1,
            row    = 1,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 5,
            pady = 0,
            rowspan = 1,
            sticky = "e"
        )
        self.cbMoods.grid(
            in_    = self.frameWizard,
            column = 1,
            row    = 1,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 10,
            pady = 0,
            rowspan = 1,
            sticky = "w"
        )
        self.cbInKey.grid(
            in_    = self.frameWizard,
            column = 1,
            row    = 2,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 10,
            pady = 0,
            rowspan = 1,
            sticky = "new"
        )
        self.cbScales.grid(
            in_    = self.frameWizard,
            column = 1,
            row    = 3,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 10,
            pady = 0,
            rowspan = 1,
            sticky = "new"
        )
        self.cbStructure.grid(
            in_    = self.frameWizard,
            column = 1,
            row    = 4,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 10,
            pady = 0,
            rowspan = 1,
            sticky = "new"
        )

        self.btns1.grid(
            in_    = self.frameWizard,
            column = 1,
            row    = 5,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 10,
            pady = 0,
            rowspan = 1,
            sticky = "new"
        )

        # Resize Behavior
        self.frameWizard.grid_rowconfigure(1, weight = 0, minsize = 40, pad = 0)
        self.frameWizard.grid_rowconfigure(2, weight = 0, minsize = 30, pad = 0)
        self.frameWizard.grid_rowconfigure(3, weight = 0, minsize = 30, pad = 0)
        self.frameWizard.grid_rowconfigure(4, weight = 0, minsize = 30, pad = 0)
        self.frameWizard.grid_rowconfigure(5, weight = 0, minsize = 30, pad = 0)
        self.frameWizard.grid_rowconfigure(6, weight = 0, minsize = 30, pad = 0)
        self.frameWizard.grid_rowconfigure(7, weight = 0, minsize = 30, pad = 0)
        self.frameWizard.grid_columnconfigure(1, weight = 0, minsize = 60, pad = 0)
        self.frameWizard.grid_columnconfigure(2, weight = 0, minsize = 60, pad = 0)

        # Start with the 'Propose progression'
        self.getVals()

    def cleanbox(self):
        self.txt2.delete('1.0', '20.0')
        self.txt.delete('1.0', '90.0')

    def getVals(self):
        self.txt.config(state="normal") #set read-write
        self.cleanbox()

        mood = self.cbMoods.current()
        moodList = ''

        if self.cbMoodsCust.get() != '':
            moodList +=  re.sub(r'\s+', '', self.cbMoodsCust.get())

        self.txt.insert(tkinter.INSERT, self.drawChordText(str(self.cbMoods.current()), str(self.cbInKey.current()), str(self.cbScales.get()),str(self.cbStructure.current()),str(moodList)))
        self.txt2.insert(tkinter.INSERT, self.drawChordTextKey(str(self.cbMoods.current()), str(self.cbInKey.current()), str(self.cbScales.get()),str(self.cbStructure.current())))
        self.txt.config(state="disabled") #set read-only

    def drawChordTextKey(self,mood,inKey,scale,structure):
        inKey = (int(inKey) + 3) % 12
        if scale == 'Major':
            chartselect = self.rc.KeyChartMajor[int(inKey)-1]
            ret = 'Chords in key: '
            for i, val in enumerate(chartselect):
                if i >=1:
                    self.msg('--- i>=1')
                    ret += str(self.rc.Chords[int(val)][self.rc.pChordName]) + ' '
            return ret
        elif scale == 'Minor': #if minor
            chartselect = self.rc.KeyChartMinor[int(inKey)-1]
            ret = 'Chords in key: '
            for i, val in enumerate(chartselect):
                if i >=1:
                    ret += str(self.rc.Chords[int(val)][self.rc.pChordName]) + ' '
            return ret

    def drawChordText(self,mood,inKey,scale,structure,mList):
        inKey = (int(inKey) + 3) % 12
        rand = randint(0, 2)
        structure = int(structure)

        if scale == 'Major':
            chartselect = self.rc.KeyChartMajor[int(inKey)-1]
            useCircle = self.rc.circleFifthsOuter[int(inKey)-1][int(rand)]
        else: #minor
            chartselect = self.rc.KeyChartMinor[int(inKey)-1]
            useCircle = self.rc.circleFifthsInner[int(inKey)-1][int(rand)]

        verse = '\n--------------------------------------------------\n'
        verse += 'Verse:  '

        #here we put an empty list in the "V" key in the dictionary, ready
        #for the chord names...
        self.song["V"]=[]

        if mList != '':
            newList = [int(x) for x in mList.split(',')]
            self.msg(newList)
            moodArr = newList
        else:
            moodArr = self.rc.progressions[int(mood)-1]

        for i, val in enumerate(moodArr):
            if isinstance(val, str): break
            x = int(chartselect[int(val)])
            chord_name = str(self.rc.Chords[x][self.rc.pChordName])
            #... and we add them
            self.song["V"].append(chord_name)
            verse += chord_name + '  '

        chorus = '\n--------------------------------------------------\n'
        chorus += 'Chorus: '

        #init "C"horus list...
        self.song["C"]=[]
        for i, val in enumerate(moodArr):
            if isinstance(val, str): break
            x = int(useCircle[int(val)])
            chord_name = str(self.rc.Chords[x][self.rc.pChordName])
            self.song["C"].append(chord_name)
            chorus += chord_name + '  '
            data=""
            #here we put the song structure into the song dictionary....
            if structure == 0:
                data = verse
                self.song["Structure"] = "V"
            else:
                self.song["Structure"] = self.rc.Structures[structure-1][self.rc.pStructureChars]
                #... and now it is ready to be passed around
                # remember that when we pass it to here from the ReaChord class, we are just
                # passing a reference to it so this updates that one, the only one, ready for passing
                # to the other sections.
                for i, val in enumerate(self.rc.Structures[structure-1][self.rc.pStructureChars]):
                    if val == 'V':
                        data+=verse
                    else:
                        data+=chorus
        return 'Proposed chord progression for a song' + data

    def msg(self,m):
        reaChord_data.msg(m)

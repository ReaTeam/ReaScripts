try:
    from reaper_python import *
except ImportError:
    pass
try:
    import sys
    sys.argv=["Main"]
    if  sys.hexversion >= 0x03000000:
        import tkinter
        from tkinter import ttk, Tk, StringVar, TclError, Button, Spinbox, Label
        from tkinter import *
        from tkinter.ttk import Combobox as ttkCombobox
        from tkinter.ttk import Button as ttkButton
    else:
        from Tkinter import Tk, StringVar, TclError, Button, Spinbox, Label
        from ttk import Combobox as ttkCombobox
        from ttk import Button as ttkButton
except:
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
try:
    from sws_python import *
except:
    pass


class GuitarSection(RSStateManager):

    #rc = reaChord_functions.RC() # comment out - for autocomplete
    def __init__(self, parent, rc):
        self.settings = {
            "draw": 0, "channel": 3, "velocity": 96, "highlight": 1, "invert_above": 6
        }
        self.stateManager_Start("GuitarSection", self.settings)
        self.parent = parent
        self.rc = rc
        self.init_widgets()

        entriesStructuresA = ('A:',)
        entriesStructuresB = ('B:',)
        entriesStructuresC = ('C:',)
        entriesStructuresD = ('D:',)
        entriesStructuresE = ('E:',)
        entriesStructuresF = ('F:',)
        entriesStructuresG = ('G:',)
        pStructureNameA = 0
        pStructureNameB = 0
        pStructureNameC = 0
        pStructureNameD = 0
        pStructureNameE = 0
        pStructureNameF = 0
        pStructureNameG = 0

        for i, val in enumerate(self.rc.GuitarChordsA):
            entriesStructuresA+=(val[pStructureNameA],)

        for i, val in enumerate(self.rc.GuitarChordsB):
            entriesStructuresB+=(val[pStructureNameB],)

        for i, val in enumerate(self.rc.GuitarChordsC):
            entriesStructuresC+=(val[pStructureNameC],)

        for i, val in enumerate(self.rc.GuitarChordsD):
            entriesStructuresD+=(val[pStructureNameD],)

        for i, val in enumerate(self.rc.GuitarChordsE):
            entriesStructuresE+=(val[pStructureNameE],)

        for i, val in enumerate(self.rc.GuitarChordsF):
            entriesStructuresF+=(val[pStructureNameF],)

        for i, val in enumerate(self.rc.GuitarChordsG):
            entriesStructuresG+=(val[pStructureNameG],)

    def draw(self, midiTake, song, sectionLength):
    
        channel = 1
        velocity = 96
        length = 1920
        steps = 1920
        selected = 1
        position = 0
        barlen = 1
        
        #try:
        #    selAllNotesTselection()
        #    deleteSelectedNotes()
        #except:
        #    self.selAllNotesTselection()
        #    self.deleteSelectedNotes()       
        
        try:
            take = getActTakeInEditor()
            midiTake = allocateMIDITake(take)
        except:
            take = self.getActTakeInEditor()
            midiTake = self.allocateMIDITake(take)        
        
        try:
            patAtt1 = int(self.Pat1.current())
        except TypeError:
            patAtt1 = 0      
        try:
            patAtt2 = int(self.Pat2.current())
        except TypeError:
            patAtt2 = 0  
        try:
            patAtt3 = int(self.Pat3.current())
        except TypeError:
            patAtt3 = 0  
        try:
            patAtt4 = int(self.Pat4.current())
        except TypeError:
            patAtt4 = 0  
        try:
            patAtt5 = int(self.Pat5.current())
        except TypeError:
            patAtt5 = 0  
        try:
            patAtt6 = int(self.Pat6.current())
        except TypeError:
            patAtt6 = 0  
        try:
            patAtt7 = int(self.Pat7.current())
        except TypeError:
            patAtt7 = 0  
            
 
        try:
            chordA = int(self.ChordA1.current())
        except TypeError:
            chordA = 0 
        try:
            chordB = int(self.ChordB1.current())
        except TypeError:
            chordB = 0 
        try:
            chordC = int(self.ChordC1.current())
        except TypeError:
            chordC = 0 
        try:
            chordD = int(self.ChordD1.current())
        except TypeError:
            chordD = 0            
        try:
            chordE = int(self.ChordE1.current())
        except TypeError:
            chordE = 0            
        try:
            chordF = int(self.ChordF1.current())
        except TypeError:
            chordF = 0 
        try:
            chordG = int(self.ChordG1.current())
        except TypeError:
            chordG = 0 
            
            
        try:
            posA = int(self.PosA1.get())
        except TypeError:
            posA = 0
        try:
            posB = int(self.PosB1.get())
        except TypeError:
            posB = 0
        try:
            posC = int(self.PosC1.get())
        except TypeError:
            posC = 0
        try:
            posD = int(self.PosD1.get())
        except TypeError:
            posD = 0            
        try:
            posE = int(self.PosE1.get())
        except TypeError:
            posE = 0
        try:
            posF = int(self.PosF1.get())
        except TypeError:
            posF = 0            
        try:
            posG = int(self.PosG1.get())
        except TypeError:
            posG = 0             
            

        if chordA > 0 and chordA is not None:
            barlen+=1
        if chordB > 0 and chordB is not None:
            barlen+=1
        if chordC > 0 and chordC is not None:
            barlen+=1
        if chordD > 0 and chordD is not None:
            barlen+=1
        if chordE > 0 and chordE is not None:
            barlen+=1
        if chordF > 0 and chordF is not None:
            barlen+=1
        if chordG > 0 and chordG is not None:
            barlen+=1
            
        for j in range(1,barlen):
                     
        
            if j == posA :
                if chordA > 0:
                
                    if patAtt1 == 1: 
                       step = 240 # slow down
                       direction = 0
                    elif patAtt1 == 2: 
                       step = 120 # fast down
                       direction = 0
                    elif patAtt1 == 3: 
                       step = 240 # strum UP slow 
                       direction = 1
                    elif patAtt1 == 4: 
                       step = 120 # strum UP fast 
                       direction = 1
                    elif patAtt1 == 5: 
                       ArrIdx = fingerPick[0]
                    elif patAtt1 == 6: 
                       ArrIdx = fingerPick[1]  
                    elif patAtt1 == 7: 
                       ArrIdx = fingerPick[2]                       
                    elif patAtt1 == 8: 
                       ArrIdx = fingerPick[3]
                    elif patAtt1 == 9: 
                       ArrIdx = fingerPick[4]
                    elif patAtt1 == 10: 
                       ArrIdx = fingerPick[5]
                    elif patAtt1 == 11: 
                       ArrIdx = fingerPick[6]
                    elif patAtt1 == 12: 
                       ArrIdx = fingerPick[7]                      
                    elif patAtt1 == 13: 
                       ArrIdx = fingerPick[8]
                    elif patAtt1 == 14: 
                       ArrIdx = fingerPick[9]
                    elif patAtt1 == 15: 
                       ArrIdx = fingerPick[10]                       
                    elif patAtt1 == 16: 
                       ArrIdx = fingerPick[11]                   
                       
                    else:
                       step = 0 #normal 
                       direction = 0  
                       
                    if patAtt1 >= 5:
                       step = 240
                       direction = 2 
                
                    if direction == 0:
                        chordArray = GuitarChordsA[chordA-1]
                        rangeStart = 1
                        rangeEnd = 0
                    elif direction == 2:
                        rangeStart = 1
                        rangeEnd = 0
                        chordArray1 = GuitarChordsA[chordA-1]   
                        chordArray = [chordArray1[idx-1] for idx in ArrIdx ]
                    else:
                        tmp = GuitarChordsA[chordA-1]
                        chordArray = tmp[::-1]
                        rangeStart = 0
                        rangeEnd = 1
                    for i in range(rangeStart,len(chordArray)-rangeEnd):
                        if i == rangeStart:
                            note = addNote(midiTake,channel,velocity,position,int(chordArray[i]),length,selected)
                        else:
                            note = addNote(midiTake,channel,velocity, int(position + (step * i)),int(chordArray[i]), int(length -(step * i)),selected)
                            
                position = position + steps
        
            if j == posB :
                if chordB > 0:
                
                    if patAtt2 == 1: 
                       step = 240 # slow down
                       direction = 0
                    elif patAtt2 == 2: 
                       step = 120 # fast down
                       direction = 0
                    elif patAtt2 == 3: 
                       step = 240 # strum UP slow 
                       direction = 1
                    elif patAtt2 == 4: 
                       step = 120 # strum UP fast 
                       direction = 1
                    elif patAtt2 == 5: 
                       ArrIdx = fingerPick[0]
                    elif patAtt2 == 6: 
                       ArrIdx = fingerPick[1]  
                    elif patAtt2 == 7: 
                       ArrIdx = fingerPick[2]                       
                    elif patAtt2 == 8: 
                       ArrIdx = fingerPick[3]
                    elif patAtt2 == 9: 
                       ArrIdx = fingerPick[4]
                    elif patAtt2 == 10: 
                       ArrIdx = fingerPick[5]
                    elif patAtt2 == 11: 
                       ArrIdx = fingerPick[6]
                    elif patAtt2 == 12: 
                       ArrIdx = fingerPick[7]                      
                    elif patAtt2 == 13: 
                       ArrIdx = fingerPick[8]
                    elif patAtt2 == 14: 
                       ArrIdx = fingerPick[9]
                    elif patAtt2 == 15: 
                       ArrIdx = fingerPick[10]                       
                    elif patAtt2 == 16: 
                       ArrIdx = fingerPick[11]                   
                       
                    else:
                       step = 0 #normal 
                       direction = 0  
                       
                    if patAtt2 >= 5:
                       step = 240
                       direction = 2 
                       
                    if direction == 0:
                        chordArray = GuitarChordsB[chordB-1]
                        rangeStart = 1
                        rangeEnd = 0
                    elif direction == 2:
                        rangeStart = 1
                        rangeEnd = 0
                        chordArray1 = GuitarChordsB[chordB-1]   
                        chordArray = [chordArray1[idx-1] for idx in ArrIdx ]
                    else:
                        tmp = GuitarChordsB[chordB-1]
                        chordArray = tmp[::-1]
                        rangeStart = 0
                        rangeEnd = 1
                    for i in range(rangeStart,len(chordArray)-rangeEnd):
                        if i == rangeStart:
                            note = addNote(midiTake,channel,velocity,position,int(chordArray[i]),length,selected)
                        else:
                            note = addNote(midiTake,channel,velocity, int(position + (step * i)),int(chordArray[i]), int(length -(step * i)),selected)
                position = position + steps 
            
            if j == posC :
                if chordC > 0:
                
                    if patAtt3 == 1: 
                       step = 240 # slow down
                       direction = 0
                    elif patAtt3 == 2: 
                       step = 120 # fast down
                       direction = 0
                    elif patAtt3 == 3: 
                       step = 240 # strum UP slow 
                       direction = 1
                    elif patAtt3 == 4: 
                       step = 120 # strum UP fast 
                       direction = 1
                    elif patAtt3 == 5: 
                       ArrIdx = fingerPick[0]
                    elif patAtt3 == 6: 
                       ArrIdx = fingerPick[1]  
                    elif patAtt3 == 7: 
                       ArrIdx = fingerPick[2]                       
                    elif patAtt3 == 8: 
                       ArrIdx = fingerPick[3]
                    elif patAtt3 == 9: 
                       ArrIdx = fingerPick[4]
                    elif patAtt3 == 10: 
                       ArrIdx = fingerPick[5]
                    elif patAtt3 == 11: 
                       ArrIdx = fingerPick[6]
                    elif patAtt3 == 12: 
                       ArrIdx = fingerPick[7]                      
                    elif patAtt3 == 13: 
                       ArrIdx = fingerPick[8]
                    elif patAtt3 == 14: 
                       ArrIdx = fingerPick[9]
                    elif patAtt3 == 15: 
                       ArrIdx = fingerPick[10]                       
                    elif patAtt3 == 16: 
                       ArrIdx = fingerPick[11]                   
                       
                    else:
                       step = 0 #normal 
                       direction = 0  
                       
                    if patAtt3 >= 5:
                       step = 240
                       direction = 2 
                       
                    if direction == 0:
                        chordArray = GuitarChordsC[chordC-1]
                        rangeStart = 1
                        rangeEnd = 0
                    elif direction == 2:
                        rangeStart = 1
                        rangeEnd = 0
                        chordArray1 = GuitarChordsC[chordC-1]   
                        chordArray = [chordArray1[idx-1] for idx in ArrIdx ]                       
                    else:
                        tmp = GuitarChordsC[chordC-1]
                        chordArray = tmp[::-1]
                        rangeStart = 0
                        rangeEnd = 1
                    for i in range(rangeStart,len(chordArray)-rangeEnd):
                        if i == rangeStart:
                            note = addNote(midiTake,channel,velocity,position,int(chordArray[i]),length,selected)
                        else:
                            note = addNote(midiTake,channel,velocity, int(position + (step * i)),int(chordArray[i]), int(length -(step * i)),selected)
                position = position + steps
            
            if j == posD :
                if chordD > 0:
                
                    if patAtt4 == 1: 
                       step = 240 # slow down
                       direction = 0
                    elif patAtt4 == 2: 
                       step = 120 # fast down
                       direction = 0
                    elif patAtt4 == 3: 
                       step = 240 # strum UP slow 
                       direction = 1
                    elif patAtt4 == 4: 
                       step = 120 # strum UP fast 
                       direction = 1
                    elif patAtt4 == 5: 
                       ArrIdx = fingerPick[0]
                    elif patAtt4 == 6: 
                       ArrIdx = fingerPick[1]  
                    elif patAtt4 == 7: 
                       ArrIdx = fingerPick[2]                       
                    elif patAtt4 == 8: 
                       ArrIdx = fingerPick[3]
                    elif patAtt4 == 9: 
                       ArrIdx = fingerPick[4]
                    elif patAtt4 == 10: 
                       ArrIdx = fingerPick[5]
                    elif patAtt4 == 11: 
                       ArrIdx = fingerPick[6]
                    elif patAtt4 == 12: 
                       ArrIdx = fingerPick[7]                      
                    elif patAtt4 == 13: 
                       ArrIdx = fingerPick[8]
                    elif patAtt4 == 14: 
                       ArrIdx = fingerPick[9]
                    elif patAtt4 == 15: 
                       ArrIdx = fingerPick[10]                       
                    elif patAtt4 == 16: 
                       ArrIdx = fingerPick[11]                   
                       
                    else:
                       step = 0 #normal 
                       direction = 0  
                       
                    if patAtt4 >= 5:
                       step = 240
                       direction = 2 
                       
                    if direction == 0:
                        chordArray = GuitarChordsD[chordD-1]
                        rangeStart = 1
                        rangeEnd = 0
                    elif direction == 2:
                        rangeStart = 1
                        rangeEnd = 0
                        chordArray1 = GuitarChordsD[chordD-1]   
                        chordArray = [chordArray1[idx-1] for idx in ArrIdx ]                        
                    else:
                        tmp = GuitarChordsD[chordD-1]
                        chordArray = tmp[::-1]
                        rangeStart = 0
                        rangeEnd = 1
                    for i in range(rangeStart,len(chordArray)-rangeEnd):
                        if i == rangeStart:
                            note = addNote(midiTake,channel,velocity,position,int(chordArray[i]),length,selected)
                        else:
                            note = addNote(midiTake,channel,velocity, int(position + (step * i)),int(chordArray[i]), int(length -(step * i)),selected)
                position = position + steps  
            
            if j == posE :
                if chordE > 0:
                
                    if patAtt5 == 1: 
                       step = 240 # slow down
                       direction = 0
                    elif patAtt5 == 2: 
                       step = 120 # fast down
                       direction = 0
                    elif patAtt5 == 3: 
                       step = 240 # strum UP slow 
                       direction = 1
                    elif patAtt5 == 4: 
                       step = 120 # strum UP fast 
                       direction = 1
                    elif patAtt5 == 5: 
                       ArrIdx = fingerPick[0]
                    elif patAtt5 == 6: 
                       ArrIdx = fingerPick[1]  
                    elif patAtt5 == 7: 
                       ArrIdx = fingerPick[2]                       
                    elif patAtt5 == 8: 
                       ArrIdx = fingerPick[3]
                    elif patAtt5 == 9: 
                       ArrIdx = fingerPick[4]
                    elif patAtt5 == 10: 
                       ArrIdx = fingerPick[5]
                    elif patAtt5 == 11: 
                       ArrIdx = fingerPick[6]
                    elif patAtt5 == 12: 
                       ArrIdx = fingerPick[7]                      
                    elif patAtt5 == 13: 
                       ArrIdx = fingerPick[8]
                    elif patAtt5 == 14: 
                       ArrIdx = fingerPick[9]
                    elif patAtt5 == 15: 
                       ArrIdx = fingerPick[10]                       
                    elif patAtt5 == 16: 
                       ArrIdx = fingerPick[11]                   
                       
                    else:
                       step = 0 #normal 
                       direction = 0  
                       
                    if patAtt5 >= 5:
                       step = 240
                       direction = 2 
                       
                    if direction == 0:
                        chordArray = GuitarChordsE[chordE-1]
                        rangeStart = 1
                        rangeEnd = 0
                    elif direction == 2:
                        rangeStart = 1
                        rangeEnd = 0
                        chordArray1 = GuitarChordsE[chordE-1]   
                        chordArray = [chordArray1[idx-1] for idx in ArrIdx ]
                    else:
                        tmp = GuitarChordsE[chordE-1]
                        chordArray = tmp[::-1]
                        rangeStart = 0
                        rangeEnd = 1
                    for i in range(rangeStart,len(chordArray)-rangeEnd):
                        if i == rangeStart:
                            note = addNote(midiTake,channel,velocity,position,int(chordArray[i]),length,selected)
                        else:
                            note = addNote(midiTake,channel,velocity, int(position + (step * i)),int(chordArray[i]), int(length -(step * i)),selected)
                position = position + steps 
            
            if j == posF :
                if chordF > 0:
                
                    if patAtt6 == 1: 
                       step = 240 # slow down
                       direction = 0
                    elif patAtt6 == 2: 
                       step = 120 # fast down
                       direction = 0
                    elif patAtt6 == 3: 
                       step = 240 # strum UP slow 
                       direction = 1
                    elif patAtt6 == 4: 
                       step = 120 # strum UP fast 
                       direction = 1
                    elif patAtt6 == 5: 
                       ArrIdx = fingerPick[0]
                    elif patAtt6 == 6: 
                       ArrIdx = fingerPick[1]  
                    elif patAtt6 == 7: 
                       ArrIdx = fingerPick[2]                       
                    elif patAtt6 == 8: 
                       ArrIdx = fingerPick[3]
                    elif patAtt6 == 9: 
                       ArrIdx = fingerPick[4]
                    elif patAtt6 == 10: 
                       ArrIdx = fingerPick[5]
                    elif patAtt6 == 11: 
                       ArrIdx = fingerPick[6]
                    elif patAtt6 == 12: 
                       ArrIdx = fingerPick[7]                      
                    elif patAtt6 == 13: 
                       ArrIdx = fingerPick[8]
                    elif patAtt6 == 14: 
                       ArrIdx = fingerPick[9]
                    elif patAtt6 == 15: 
                       ArrIdx = fingerPick[10]                       
                    elif patAtt6 == 16: 
                       ArrIdx = fingerPick[11]                   
                       
                    else:
                       step = 0 #normal 
                       direction = 0  
                       
                    if patAtt6 >= 5:
                       step = 240
                       direction = 2 
                       
                    if direction == 0:
                        chordArray = GuitarChordsF[chordF-1]
                        rangeStart = 1
                        rangeEnd = 0
                    elif direction == 2:
                        rangeStart = 1
                        rangeEnd = 0
                        chordArray1 = GuitarChordsF[chordF-1]   
                        chordArray = [chordArray1[idx-1] for idx in ArrIdx ]
                    else:
                        tmp = GuitarChordsF[chordF-1]
                        chordArray = tmp[::-1]
                        rangeStart = 0
                        rangeEnd = 1
                    for i in range(rangeStart,len(chordArray)-rangeEnd):
                        if i == rangeStart:
                            note = addNote(midiTake,channel,velocity,position,int(chordArray[i]),length,selected)
                        else:
                            note = addNote(midiTake,channel,velocity, int(position + (step * i)),int(chordArray[i]), int(length -(step * i)),selected)
                position = position + steps 
            
            if j == posG :
                if chordG > 0:
                
                    if patAtt7 == 1: 
                       step = 240 # slow down
                       direction = 0
                    elif patAtt7 == 2: 
                       step = 120 # fast down
                       direction = 0
                    elif patAtt7 == 3: 
                       step = 240 # strum UP slow 
                       direction = 1
                    elif patAtt7 == 4: 
                       step = 120 # strum UP fast 
                       direction = 1
                    elif patAtt7 == 5: 
                       ArrIdx = fingerPick[0]
                    elif patAtt7 == 6: 
                       ArrIdx = fingerPick[1]  
                    elif patAtt7 == 7: 
                       ArrIdx = fingerPick[2]                       
                    elif patAtt7 == 8: 
                       ArrIdx = fingerPick[3]
                    elif patAtt7 == 9: 
                       ArrIdx = fingerPick[4]
                    elif patAtt7 == 10: 
                       ArrIdx = fingerPick[5]
                    elif patAtt7 == 11: 
                       ArrIdx = fingerPick[6]
                    elif patAtt7 == 12: 
                       ArrIdx = fingerPick[7]                      
                    elif patAtt7 == 13: 
                       ArrIdx = fingerPick[8]
                    elif patAtt7 == 14: 
                       ArrIdx = fingerPick[9]
                    elif patAtt7 == 15: 
                       ArrIdx = fingerPick[10]                       
                    elif patAtt7 == 16: 
                       ArrIdx = fingerPick[11]                   
                       
                    else:
                       step = 0 #normal 
                       direction = 0  
                       
                    if patAtt7 >= 5:
                       step = 240
                       direction = 2 
                       
                    if direction == 0:
                        chordArray = GuitarChordsG[chordG-1]
                        rangeStart = 1
                        rangeEnd = 0
                    elif direction == 2:
                        rangeStart = 1
                        rangeEnd = 0
                        chordArray1 = GuitarChordsG[chordG-1]   
                        chordArray = [chordArray1[idx-1] for idx in ArrIdx ]
                    else:
                        tmp = GuitarChordsG[chordG-1]
                        chordArray = tmp[::-1]
                        rangeStart = 0
                        rangeEnd = 1
                    for i in range(rangeStart,len(chordArray)-rangeEnd):
                        if i == rangeStart:
                            note = addNote(midiTake,channel,velocity,position,int(chordArray[i]),length,selected)
                        else:
                            note = addNote(midiTake,channel,velocity, int(position + (step * i)),int(chordArray[i]), int(length -(step * i)),selected)
                position = position + steps
        return position

    def drawGuitar(self,midiTake, chord, currentPos, chordLength):
        velocity = self.velocity.get()
        selectNote = self.highlight.get()
        channel = self.channel.get()
        drop = 1
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
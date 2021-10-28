# @description ReaChorder
# @author Flaneurette
# @version 2.2
# @changelog update
# @provides
#   [main=midi_editor,midi_inlineeditor windows] .
#   [main=midi_editor,midi_inlineeditor linux] .
try:
    from reaper_python import *
except ImportError:
    RPR_ShowConsoleMsg('Could not import Reaper Python.\n')
    pass
try:
    import sys
    sys.path.append(RPR_GetResourcePath() + '/Scripts')
    sys.path.append('./ReaChorder')
except ImportError:
    RPR_ShowConsoleMsg('Could not import SYS.\n')
    pass
try:
    from sws_python import *
except ImportError:
    RPR_ShowConsoleMsg('Could not import SWS Python.\n')
    pass
try:
    apitest = RPR_APIExists("CF_GetSWSVersion")
    if apitest == 0:
        RPR_ShowConsoleMsg('Your SWS version does not allow versioning. Please visit: https://www.sws-extension.org/ and update SWS.')
    else:		
        (sws_version,build) = CF_GetSWSVersion('',5)
        if sws_version < '2.12':
            RPR_ShowConsoleMsg('Your SWS version ('+sws_version+') is not supported. Please visit: https://www.sws-extension.org/ and update SWS.')
except:
    RPR_ShowConsoleMsg('Your SWS version is (probably) not supported. Please visit: https://www.sws-extension.org/ and update SWS.')
try:
    import platform
except ImportError:
    RPR_ShowConsoleMsg('Could not import platform.\n')
    pass
try:
    import os
except ImportError:
    RPR_ShowConsoleMsg('Could not import OS.\n')
    pass
try:
    import tkinter
    from tkinter import ttk, Y, BOTH, RAISED
except ImportError:
    RPR_ShowConsoleMsg('Could not import tkinter.\n')
    pass
try:
    import rs_statemanager
    from rs_statemanager import RSStateManager
except ImportError:
    RPR_ShowConsoleMsg('Could not import rs_statemanager.\n')
    pass
try:
    from contextlib import contextmanager
except ImportError:
    RPR_ShowConsoleMsg('Could not import contextlib.\n')
    pass
try:
    from reaChord_data import RC, msg
except ImportError:
    RPR_ShowConsoleMsg('Could not import reaChord_data.\n')
    pass
try:
    from rs_midi import RSMidi
except ImportError:
    RPR_ShowConsoleMsg('Could not import rs_midi.\n')
    pass
try:
    from reaper_track import Track, Item
except ImportError:
    RPR_ShowConsoleMsg('Could not import reaper_track.\n')
    pass

sys.argv=["Main"]

try:
    from wizard_section import Wizard
    from chord_section import ChordSection
    from bass_section import BassSection
    from drum_section import DrumSection
    from melody_section import MelodySection
except ImportError:
    RPR_ShowConsoleMsg('Could not import sections.\n')
    pass

class ReaChord(RSStateManager):

    def __init__(self, root):
        RSStateManager.appname = "ReaChorder"
        #create the empty song dictionary
        self.song = {}
        self.msg('__init__')
        self.stateManager_Start("Main", self.song)
        self.root = root
        self.root.title('ReaChorder')
        self.root.wm_attributes("-topmost", 1)
        self.img = None
        frame_height = 310

        try:
            osVersion = platform.release()
            if osVersion == 'XP':
                frame_width = 570 # WinXP
            else:
                frame_width = 610 # Win7+
        except:
            frame_width = 610 # Win7+

        self.mainFrame = ttk.Frame(self.root, width=frame_width, borderwidth=0, height=frame_height)
        self.mainFrame.pack(fill=BOTH, expand=1, padx=10, pady=5)

        self.mainFrame1 = ttk.Frame(self.root, width=frame_width, borderwidth=0, height=30)
        self.mainFrame1.pack(fill=BOTH, expand=Y, padx=10, pady=0)

        self.rc = RC()  #init this b4 widgets so they can get tuples from it

        self.tabs = ttk.Notebook(self.mainFrame)
        self.tabs.pack(fill=BOTH, expand=Y, padx=0, pady=0)
        self.frameWizard = ttk.Frame(self.tabs, borderwidth=0, width=frame_width, height=frame_height)
        self.tabs.add(self.frameWizard, text="Wizard")
        self.wizard = Wizard(self.frameWizard, self.rc, self.song)

        #self.frameSongEditor = ttk.Frame(self.tabs, borderwidth=0, relief="sunken", width=740,height=255)
        #self.tabs.add(self.frameSongEditor, text="Song Editor")
        #TODO:  create song editor

        self.btns = ttk.Button(self.mainFrame1,  text='Draw into MIDI take...', width='20')
        self.btns.bind('<Button-1>', lambda event: self.drawMidi())

        self.btns.grid(
            column = 8,
            row    = 1,
            columnspan = 1,
            ipadx = 0,
            ipady = 0,
            padx = 460,
            pady = 0,
            rowspan = 1,
            sticky = "e"
        )

        self.sections = []
        self.frameChords = ttk.Frame(self.tabs, borderwidth=0, width=740,height=225)
        self.tabs.add(self.frameChords, text="Chords")
        self.chords = ChordSection(self.frameChords, self.rc)
        self.sections.append(self.chords)

        self.frameBass = ttk.Frame(self.tabs, borderwidth=0, width=740,height=225)
        self.tabs.add(self.frameBass, text="Bass")
        self.bass = BassSection(self.frameBass, self.rc)
        self.sections.append(self.bass)

        self.frameMelody = ttk.Frame(self.tabs, borderwidth=0, width=740,height=225)
        self.tabs.add(self.frameMelody, text="Melody")
        self.melody = MelodySection(self.frameMelody, self.rc)
        self.sections.append(self.melody)

        self.frameDrum = ttk.Frame(self.tabs, borderwidth=0, width=740,height=225)
        self.tabs.add(self.frameDrum , text="Drum")
        self.drum = DrumSection(self.frameDrum, self.rc)
        self.sections.append(self.drum)

        # center the window
        w = frame_width
        h = 310
        sw = self.root.winfo_screenwidth()
        sh = self.root.winfo_screenheight()
        x = (sw - w)/2
        y = (sh - h)/2
        self.root.geometry('%dx%d+%d+%d' % (w, h, x, y))

    def close(self):
        global root
        root.destroy()

    def drawMidi(self):
        quartNoteLength = 960
        self.msg('ReaChorder - drawMidi - Enter')
        p, bpm, bpi = RPR_GetProjectTimeSignature2(0, 0, 0)
        bps = bpm/60
        beatsInBar = bpi
        barsPerSection = 4
        RSMidi.selAllNotes()
        RSMidi.deleteSelectedNotes()
        sectionLength = quartNoteLength * beatsInBar * barsPerSection

        take = RSMidi.getActTakeInEditor()

        if take == "(MediaItem_Take*)0x00000000" or take == "(MediaItem_Take*)0x0000000000000000":
            RPR_ShowConsoleMsg("ReaChorder: Please open an item in the MIDI Editor first.\n")
        else:
            item = Item()   # init Item class
            itemId = RPR_GetMediaItemTake_Item(take)    # get parent item
            songLength = sectionLength * len(self.song["Structure"])    # works (currently) :)
            item.setMidiItemLength(itemId, songLength, bps, quartNoteLength)
            item.setName(itemId, "ReaChorder Song")

            midiTake = RSMidi.allocateMIDITake(take)

            #go throught the sections, calling the draw() methods
            for obj in self.sections:
                p = obj.draw(midiTake, self.song, sectionLength)

            RSMidi.freeMIDITake(midiTake)

    def msg(self, m):
        msg(m)


if __name__ == '__main__':
    root = tkinter.Tk()
    ReaChord(root)
    root.mainloop()

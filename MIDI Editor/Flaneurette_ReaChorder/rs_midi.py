try:
    from reaper_python import *
except ImportError:
    pass
try:
    from sws_python import *
except ImportError:
    pass

class MIDIEvent:
    def __init__(self):
        self.type
        self.channel
        self.value1
        self.value2

class RSMidi:

    """
    Requires SWS/S&M extensions.
    All static methods so we don't need to create an object to use them.
    just:  from rs_midi import *    and then:   RSMidi.cmdME(bling, blong)
    """

    @staticmethod
    def cmdME(actME, cmd):
        RPR_MIDIEditor_OnCommand(actME,cmd)

    @staticmethod
    def getActTakeInEditor():
        return RPR_MIDIEditor_GetTake(RPR_MIDIEditor_GetActive())

    @staticmethod
    def allocateMIDITake(midiTake):
        return FNG_AllocMidiTake(midiTake)

    @staticmethod
    def freeMIDITake(midiTake):
        FNG_FreeMidiTake(midiTake)

    @staticmethod
    def countNotes(midiTake):
        return FNG_CountMidiNotes(midiTake)

    @staticmethod
    def getMidiNote(midiTake, index):
        return FNG_GetMidiNote(midiTake, index)

    @staticmethod
    def getMidiNoteIntProperty(midiNote, prop):
        return FNG_GetMidiNoteIntProperty(midiNote, prop)

    @staticmethod
    def setMidiNoteIntProperty(midiNote, prop, value):
        FNG_SetMidiNoteIntProperty(midiNote, prop, value)

    @staticmethod
    def selAllNotes(command_id=40003, islistviewcommand=0):
        RPR_MIDIEditor_LastFocused_OnCommand(command_id, islistviewcommand)

    @staticmethod
    def selAllNotesTselection(command_id=40746, islistviewcommand=0):
        RPR_MIDIEditor_LastFocused_OnCommand(command_id, islistviewcommand)

    @staticmethod
    def deleteSelectedNotes(command_id=40002, islistviewcommand=0):
        RPR_MIDIEditor_LastFocused_OnCommand(command_id, islistviewcommand)

    @staticmethod
    def addNote(midiTake, ch, vel, pos, pitch, length, sel):
        midiNote = FNG_AddMidiNote(midiTake)
        FNG_SetMidiNoteIntProperty(midiNote, "CHANNEL", ch)
        FNG_SetMidiNoteIntProperty(midiNote, "VELOCITY", vel)
        FNG_SetMidiNoteIntProperty(midiNote, "POSITION", pos)
        FNG_SetMidiNoteIntProperty(midiNote, "PITCH", pitch)
        FNG_SetMidiNoteIntProperty(midiNote, "LENGTH", length)
        FNG_SetMidiNoteIntProperty(midiNote, "SELECTED", sel)
        #return midiNote


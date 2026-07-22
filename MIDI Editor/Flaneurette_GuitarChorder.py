# @description GuitarChorder
# @author Flaneurette
# @version 2.1
# @changelog de-duplicated per-letter GUI/logic code
# @provides
#   [main=midi_editor,midi_inlineeditor windows] .
#   [main=midi_editor,midi_inlineeditor linux] .
# @about
#   GuitarChorder gives you access to all guitarchords. With it, you can draw MIDI guitar chords, with many attack styles from fingerpicking to strumming. 

try:
    from reaper_python import *
except:
    RPR_ShowConsoleMsg('Could not load reaper_python!')
try:
    sys.path.append(RPR_GetResourcePath() + '/Scripts')
    from sws_python import *
except:
    RPR_ShowConsoleMsg('Could not load sws_python!')
try:
    import sys
    sys.argv = ["Main"]
    if sys.hexversion >= 0x03000000:
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
    RPR_ShowConsoleMsg('Could not import SYS!')


# Fingerpick patterns

fingerPick = [
    [2,2,5,4,3,2,5],
    [2,2,3,4,5,4,3],
    [2,2,2,4,2,4,5],
    [2,4,2,4,2,5,4],
    [2,2,4,5,4,3,5],
    [2,2,5,4,3,2,4],
    [2,2,5,2,4,2,4],
    [2,2,4,5,3,4,5],
    [2,2,5,4,3,5,4],
    [2,2,4,2,4,3,2],
    [2,2,4,5,4,5,4],
    [2,2,5,3,4,5,4]
]

GuitarChordsA = [
    ['Am',45,52,57,60,64],
    ['Amaj',45,52,57,61,64],
    ['A6',52,57,61,66],
    ['A7',45,52,55,61,64],
    ['A7b5',45,55,61,63],
    ['A7b9',45,52,58,61,67],
    ['A9',45,52,59,61,67],
    ['A11',49,52,59,62,67],
    ['A13',45,55,61,66,69],
    ['A69',45,49,54,59,64],
    ['Aadd9',45,52,57,59,64],
    ['Aaug',45,53,57,61,65],
    ['Ab6',53,60,63,68,72],
    ['Ab7#5',51,56,60,66],
    ['Ab7',51,56,60,66],
    ['Ab7b5',44,54,60,62],
    ['Ab7b9',44,48,54,57],
    ['Ab9',42,46,51,56,60],
    ['Ab11',44,51,54,61,63],
    ['Ab13',44,48,54,56,60],
    ['Ab69',44,48,53,58,63],
    ['Abadd9',46,51,56,60],
    ['Abaug',40,48,52,56,60],
    ['Abdim',50,56,59,65],
    ['Abdim7',47,50,56,59,65],
    ['Abm',44,51,56,59,63],
    ['Abm6',51,56,59,65],
    ['Abm7',54,59,63,68],
    ['Abm7b5',56,62,66,71],
    ['Abm9',42,46,51,56,59],
    ['Abm11',44,47,54,59,61],
    ['Abmaj',0,74],
    ['Abmaj7',51,56,60,67],
    ['Abmaj9',44,48,55,58,63],
    ['Absus2',46,51,56],
    ['Absus4',51,56,61],
    ['Adim',45,51,57,60],
    ['Adim7',51,57,60,66],
    ['Am6',45,52,57,60,66],
    ['Am7',45,52,57,60,67],
    ['Am7b5',51,57,60,67],
    ['Am9',45,55,60,64,71],
    ['Am11',45,48,55,60,62],
    ['Amaj7',45,52,56,61,64],
    ['Amaj9',45,52,59,61,68],
    ['Asus2',45,52,56,59,64],
    ['Asus4',45,52,57,62,64],
    ['A#',46,53,58,62,65],
    ['A#6',46,53,58,62,67],
    ['A#7#5',46,56,62,66],
    ['A7#5',45,52,55,61,64],
    ['A#7',53,58,62,68],
    ['A#7b5',46,56,62,64],
    ['A#7b9',58,62,68,71],
    ['A#9',41,46,50,56,60],
    ['A#11',58,62,68,70,75],
    ['A#13',46,50,56,62,67],
    ['A#69',46,50,55,60,65],
    ['A#add9',41,46,50,58,60],
    ['A#aug',42,46,50,58,62],
    ['A#dim',52,58,61,67],
    ['A#dim7',52,58,61,67],
    ['A#m',46,53,58,61,65],
    ['A#m6',46,53,55,61],
    ['A#m7',46,53,56,61,65],
    ['A#m7b5',46,56,61,64],
    ['A#m9',61,65,72],
    ['A#m11',46,49,56,61,63],
    ['A#maj',46,53,58,62,65],
    ['A#maj7',46,53,57,62],
    ['A#maj9',46,50,57,60,65],
    ['A#sus2',41,46,53,58,60],
    ['A#sus4',53,58,63,65]
]

GuitarChordsB = [
    ['Bm',47,54,59,62,66],
    ['Bmaj',47,54,59,63,66],
    ['B6',54,59,63,68],
    ['B7',47,51,57,59,66],
    ['B7b5',47,57,63,65],
    ['B7b9',47,51,57,60,66],
    ['B9',47,54,57,63,66],
    ['B11',47,54,59,63],
    ['B13',47,51,57,59,68],
    ['B69',47,51,56,61,66],
    ['Badd9',47,54,59,61,66],
    ['Baug',47,51,55,59],
    ['Bb6',53,58,62,67],
    ['Bb7#5',53,58,62,68],
    ['B7#5',47,51,57,59,66],
    ['Bb7',53,58,62,68],
    ['Bb7b5',46,56,62,64],
    ['Bb7b9',58,62,68,71],
    ['Bb9',46,53,56,62,65],
    ['Bb11',46,53,56,63,68],
    ['Bb13',46,50,56,62,67],
    ['Bb69',46,50,55,60,65],
    ['Bbadd9',41,46,50,58,60],
    ['Bbaug',42,46,50,58,62],
    ['Bbdim',52,58,61,67],
    ['Bbdim7',46,52,55,61,64],
    ['Bbm',41,46,53,58,61],
    ['Bbm6',46,53,55,61],
    ['Bbm7',46,53,56,61,65],
    ['Bbm7b5',46,56,61,64],
    ['Bbm9',61,65,72],
    ['Bbm11',46,49,56,61,63],
    ['Bbmaj',46,53,58,62,65],
    ['Bbmaj7',46,53,57,62],
    ['Bbmaj9',48,53,58,62,69],
    ['Bbsus2',53,58,60,65],
    ['Bbsus4',53,58,63,65],
    ['Bdim',47,53,59,62],
    ['Bdim7',50,56,59,65],
    ['Bm6',54,59,62,68],
    ['Bm7',47,54,57,62,66],
    ['Bm7b5',41,47,53,57,62],
    ['Bm9',47,50,57,61,66],
    ['Bm11',47,50,57,59,64],
    ['Bmaj7',47,54,58,63],
    ['Bmaj9',47,51,58,61,66],
    ['Bsus2',49,54,59,66],
    ['Bsus4',54,59,64,66]
]

GuitarChordsC = [
    ['Cm',48,55,60,63,67],
    ['Cmaj',48,52,55,60,64],
    ['C6',45,52,57,60,67],
    ['C7',48,52,58,60,64],
    ['C7b5',48,54,58,64],
    ['C7b9',48,52,58,61,64],
    ['C9',48,55,58,64,67],
    ['C11',48,55,58,65,67],
    ['C13',48,55,58,64,69],
    ['C69',48,52,57,62,67],
    ['Cadd9',48,52,55,62,64],
    ['Caug',52,56,60,68],
    ['Cdim',51,57,60,66],
    ['Cdim7',51,57,60,66],
    ['Cm6',51,57,60,67],
    ['Cm7',48,55,58,63,67],
    ['Cm7b5',48,54,58,63],
    ['Cm9',48,51,58,62,67],
    ['Cm11',48,55,58,65],
    ['Cmaj7',48,52,55,59,64],
    ['Cmaj9',48,50,55,59,64],
    ['Csus2',48,50,55,60],
    ['Csus4',53,55,60,67],
    ['C#',53,56,61,65],
    ['C#6',53,58,61,68],
    ['C#7#5',49,53,57,59],
    ['C7#5',48,52,58,60,64],
    ['C#7',53,59,61,68],
    ['C#7b5',43,53,59,61],
    ['C#7b9',49,53,59,62,68],
    ['C#9',49,56,61,63,68],
    ['C#11',49,53,59,61,66],
    ['C#13',49,56,59,65,70],
    ['C#69',49,53,58,63,68],
    ['C#add9',41,51,56,61,65],
    ['C#aug',49,53,57,61],
    ['C#dim',52,58,61,67],
    ['C#dim7',52,58,61,67],
    ['C#m',52,56,61,64],
    ['C#m6',49,52,58,61,68],
    ['C#m7',52,59,61,68],
    ['C#m7b5',47,52,55,61,64],
    ['C#m9',40,47,51,56,61],
    ['C#m11',49,52,59,63,66],
    ['C#maj',53,56,61,65],
    ['C#maj7',49,53,56,60,65],
    ['C#maj9',49,51,56,60,65],
    ['C#sus2',51,56,61],
    ['C#sus4',56,61,66,68]
]

GuitarChordsD = [
    ['Dm',50,57,62,65],
    ['Dmaj',50,57,62,66],
    ['D6',45,50,57,59,66],
    ['D7',50,57,60,66],
    ['D7b5',50,56,60,66],
    ['D7b9',50,54,60,63,69],
    ['D9',50,57,60,66,69],
    ['D11',50,54,60,61,66],
    ['D13',50,57,60,66,71],
    ['D69',50,54,59,64,69],
    ['Dadd9',50,57,62,64],
    ['Daug',50,58,62,66],
    ['Db6',46,53,56,61,65],
    ['Db7#5',53,59,61,68],
    ['Db7',53,59,61,68],
    ['Db7b5',43,53,59,61],
    ['Db7b9',49,53,59,62,68],
    ['Db9',41,47,51,56,61],
    ['Db11',49,53,59,61,66],
    ['Db13',49,56,59,65,70],
    ['Db69',49,53,58,63,68],
    ['Dbadd9',41,51,56,61,65],
    ['Dbaug',41,45,53,57,61],
    ['Dbdim',52,58,61,67],
    ['Dbdim7',46,52,55,61,64],
    ['Dbm',52,56,61,64],
    ['Dbm6',49,52,58,61,68],
    ['Dbm7',52,59,61,68],
    ['Dbm7b5',47,52,55,61,64],
    ['Dbm9',40,47,51,56,61],
    ['Dbm11',49,52,59,63,66],
    ['Dbmaj',53,56,61,65],
    ['Dbmaj7',49,53,56,60,65],
    ['Dbmaj9',49,51,56,60,65],
    ['Dbsus2',56,61,63,68],
    ['Dbsus4',56,61,66,68],
    ['Ddim',50,56,59,65],
    ['Ddim7',47,50,56,59,65],
    ['Dm6',47,50,57,59,65],
    ['Dm7',50,57,60,65],
    ['Dm7b5',50,56,60,65],
    ['Dm9',53,57,60,64],
    ['Dm11',50,53,60,62,67],
    ['Dmaj7',50,57,61,66],
    ['Dmaj9',50,52,57,61,66],
    ['Dsus2',40,45,50,57,62],
    ['Dsus4',50,57,62,67],
    ['D#',55,58,63,67],
    ['D#6',48,55,58,63,67],
    ['D#7#5',51,59,61,67],
    ['D7#5',50,57,60,66],
    ['D#7',51,58,61,67],
    ['D#7b5',51,57,61,68],
    ['D#7b9',51,55,61,64],
    ['D#9',43,46,51,55,61],
    ['D#11',51,55,61,63,68],
    ['D#13',51,55,61,67,72],
    ['D#69',51,55,60,65],
    ['D#add9',43,46,51,55,65],
    ['D#aug',43,47,51,55,59],
    ['D#dim',51,57,60,66],
    ['D#dim7',51,57,60,66],
    ['D#m',54,58,63,66],
    ['D#m6',51,58,60,66],
    ['D#m7',51,58,61,66],
    ['D#m7b5',51,57,61,66],
    ['D#m9',42,46,51,58,61],
    ['D#m11',51,54,61,65,68],
    ['D#maj',55,58,63,67],
    ['D#maj7',51,58,62,67],
    ['D#maj9',51,55,62,65],
    ['D#sus2',41,46,51,58,65],
    ['D#sus4',51,58,63,68]
]

GuitarChordsE = [
    ['Em',40,47,52,55,59],
    ['Emaj',40,47,52,56,59],
    ['E6',61,66,70,75],
    ['E7',40,47,52,56,62],
    ['E7b5',46,50,56,62,64],
    ['E7b9',40,47,50,56,59],
    ['E9',52,59,62,68,71],
    ['E11',41,46,51,56,61],
    ['E13',40,47,50,56,61],
    ['E69',47,52,56,61,66],
    ['Eadd9',40,54,56,59,64],
    ['Eaug',40,48,52,56],
    ['Eb6',48,55,58,63,67],
    ['Eb7#5',51,58,61,67],
    ['E7#5',40,47,52,56,62],
    ['Eb7',51,58,61,67],
    ['Eb7b5',51,57,61,67],
    ['Eb7b9',51,55,61,64],
    ['Eb9',46,51,58,63,65],
    ['Eb11',51,55,61,63,68],
    ['Eb13',51,55,61,67,72],
    ['Eb69',51,55,60,65],
    ['Ebadd9',43,46,51,55,65],
    ['Ebaug',43,47,51,55,59],
    ['Ebdim',42,45,51,57,66],
    ['Ebdim7',51,57,60,66],
    ['Ebm',54,58,63,66],
    ['Ebm6',51,58,60,66],
    ['Ebm7',51,58,61,66],
    ['Ebm7b5',51,57,61,66],
    ['Ebm9',42,46,51,58,61],
    ['Ebm11',51,54,61,65,68],
    ['Ebmaj',55,58,63,67],
    ['Ebmaj7',51,58,62,67],
    ['Ebmaj9',51,55,62,65],
    ['Ebsus2',41,46,51,58,65],
    ['Ebsus4',51,58,63,68],
    ['Edim',52,58,61,67],
    ['Edim7',46,52,55,61,64],
    ['Em6',40,47,52,55,61],
    ['Em7',40,47,52,55,62],
    ['Em7b5',52,58,62,67],
    ['Em9',40,47,54,55,59],
    ['Em11',40,47,50,57,59],
    ['Emaj7',40,47,51,56,59],
    ['Emaj9',40,47,51,56,59],
    ['Esus2',47,54,59,64],
    ['Esus4',40,47,52,57,59]
]

GuitarChordsF = [
    ['Fm',41,48,53,56,60],
    ['Fmaj',45,53,57,60,65],
    ['F7',41,48,51,57,60],
    ['F7b5',41,51,57,59],
    ['F7b9',53,57,63,66],
    ['F9',43,45,53,57,60],
    ['F11',41,48,51,58,60],
    ['F13',41,45,51,58,62],
    ['F69',41,45,50,55,60],
    ['Fadd9',43,53,57,60,65],
    ['Faug',53,61,65,69],
    ['Fdim',50,56,59,65],
    ['Fdim7',47,50,56,59,65],
    ['Fm6',50,56,60,65],
    ['Fm7',41,48,51,56,60],
    ['Fm7b5',53,59,63,68],
    ['Fm9',51,56,60,67],
    ['Fm11',53,58,63,68],
    ['Fmaj7',48,53,57,60,64],
    ['Fmaj9',40,45,53,55,60],
    ['Fsus2',48,53,55,60,65],
    ['Fsus4',53,58,60,65],
    ['F#',42,49,54,58,61],
    ['F#6',51,58,61,66],
    ['F#7#5',42,52,58,62],
    ['F#7',54,58,61,64],
    ['F#7b5',42,52,58,60],
    ['F#7b9',42,46,52,55,61],
    ['F#9',42,49,52,58,61],
    ['F#11',42,49,52,59,61],
    ['F#13',42,49,52,58,63],
    ['F#69',42,46,51,56,61],
    ['F#add9',42,46,56,61,66],
    ['F#aug',42,46,50,58,62],
    ['F#dim',51,57,60,66],
    ['F#dim7',51,57,60,66],
    ['F#m',42,49,54,57,61],
    ['F#m6',51,57,61,66],
    ['F#m7',52,57,61,66],
    ['F#m7b5',52,57,60,66],
    ['F#m9',43,45,53,56,61],
    ['F#m11',42,45,52,57,59],
    ['F#maj',42,49,54,58,61],
    ['F#maj7',54,58,61,65],
    ['F#maj9',42,53,58,68],
    ['F#sus2',42,56,61,66],
    ['F#sus4',54,59,61,66],
    ['F6',48,53,57,62],
    ['F7#5',41,48,51,57,60]
]

GuitarChordsG = [
    ['Gm',43,50,55,58,62],
    ['Gmaj',43,47,50,55,59],
    ['G7',43,47,50,55,59],
    ['G7b5',43,53,59,61],
    ['G7b9',43,47,50,56,59],
    ['G9',43,50,57,59,65],
    ['G11',43,50,57,60,65],
    ['G13',43,47,53,55,59],
    ['G69',43,50,57,59,64],
    ['Gadd9',43,50,59,62,69],
    ['Gaug',55,63,67,71],
    ['Gb6',51,58,61,66],
    ['Gb7#5',54,58,61,64],
    ['Gb7',54,58,61,64],
    ['Gb7b5',42,52,58,60],
    ['Gb7b9',42,46,52,55,61],
    ['Gb9',46,52,56,61,66],
    ['Gb11',42,46,52,56,59],
    ['Gb13',42,49,52,58,63],
    ['Gb69',42,46,51,56,61],
    ['Gbadd9',42,46,56,61,66],
    ['Gbaug',42,46,50,58,62],
    ['Gbdim',51,57,60,66],
    ['Gbdim7',51,57,60,66],
    ['Gbm',42,49,54,57,61],
    ['Gbm6',42,51,57,61,66],
    ['Gbm7',52,57,61,66],
    ['Gbm7b5',45,52,57,60,66],
    ['Gbm9',42,45,52,56,61],
    ['Gbm11',42,45,52,57,59],
    ['Gbmaj',42,49,54,58,61],
    ['Gbmaj7',54,58,61,65],
    ['Gbmaj9',42,53,58,68],
    ['Gbsus2',42,56,61,66],
    ['Gbsus4',54,59,61,66],
    ['Gdim',55,61,64,67],
    ['Gdim7',46,52,55,61,64],
    ['G6',43,50,55,59,64],
    ['Gm6',52,58,62,67],
    ['Gm7',43,50,53,58,62],
    ['Gm7b5',55,61,65,70],
    ['Gm9',43,50,53,58,62],
    ['Gm11',43,46,53,58,60],
    ['Gmaj7',55,59,62,66],
    ['Gmaj9',42,47,55,57,62],
    ['Gsus2',45,50,55,62,67],
    ['Gsus4',43,50,55,60,62],
    ['G#',44,51,56,60,63],
    ['G#6',51,56,60,65],
    ['G#7#5',44,54,60,64],
    ['G#7',51,56,60,66],
    ['G#7b5',44,54,60,62],
    ['G#7b9',44,48,54,57],
    ['G#9',42,46,51,56,60],
    ['G#11',44,48,51,56,61],
    ['G#13',44,48,54,56,60],
    ['G#69',44,48,53,58,63],
    ['G#add9',46,51,56,60],
    ['G#aug',40,48,52,56,60],
    ['G#dim',43,47,50,55,59],
    ['G#dim7',50,56,59,65],
    ['G#m',44,51,56,59,63],
    ['G#m6',51,56,59,65],
    ['G#m7',54,59,63,68],
    ['G#m7b5',56,62,66,71],
    ['G#m9',42,46,51,56,59],
    ['G#m11',44,47,54,59,61],
    ['G#maj',44,51,56,60,63],
    ['G#maj7',51,56,60,67],
    ['G#maj9',44,48,55,58,63],
    ['G#sus2',46,51,56],
    ['G#sus4',51,56,61,68],
    ['G7#5',43,47,50,55,59]
]

strumPat = ('Even','DOWN Slow','DOWN Fast','UP Slow','UP Fast','Fingerpick 1','Fingerpick 2','Fingerpick 3','Fingerpick 4','Fingerpick 5','Fingerpick 6','Fingerpick 7','Fingerpick 8','Fingerpick 9','Fingerpick 10','Fingerpick 11','Fingerpick 12')

# --- Consolidated per-letter data (replaces 7x near-identical blocks) ---
LETTERS = ('A', 'B', 'C', 'D', 'E', 'F', 'G')
CHORD_LISTS = (GuitarChordsA, GuitarChordsB, GuitarChordsC, GuitarChordsD,
               GuitarChordsE, GuitarChordsF, GuitarChordsG)
ENTRY_STRUCTURES = [
    (letter + ':',) + tuple(entry[0] for entry in chords)
    for letter, chords in zip(LETTERS, CHORD_LISTS)
]


def pattern_step(pat_index):
    """Return (step, direction, fingerpick_indices) for a strum-pattern index."""
    if pat_index == 1:
        return 240, 0, None      # DOWN Slow
    if pat_index == 2:
        return 120, 0, None      # DOWN Fast
    if pat_index == 3:
        return 240, 1, None      # UP Slow
    if pat_index == 4:
        return 120, 1, None      # UP Fast
    if 5 <= pat_index <= 16:
        return 240, 2, fingerPick[pat_index - 5]   # Fingerpick 1-12
    return 0, 0, None            # Even / unrecognized


def build_chord_array(chord_entry, direction, arr_idx):
    """Return (notes, range_start, range_end) for a chord entry + strum direction."""
    if direction == 0:                     # forward (skip index 0 = chord name)
        return chord_entry, 1, 0
    if direction == 2:                     # fingerpicked reorder
        return [chord_entry[idx - 1] for idx in arr_idx], 1, 0
    return chord_entry[::-1], 0, 1         # reversed (name ends up last)


def write_chord_notes(midi_take, channel, velocity, position, length, selected,
                       chord_array, range_start, range_end, step):
    for i in range(range_start, len(chord_array) - range_end):
        if i == range_start:
            addNote(midi_take, channel, velocity, position, int(chord_array[i]), length, selected)
        else:
            addNote(midi_take, channel, velocity,
                    int(position + step * i), int(chord_array[i]),
                    int(length - step * i), selected)


class G(object):

    def __init__(self, root):

        self.root = root
        self.root.title('Guitar Chorder')
        self.root.wait_visibility(self.root)
        self.root.wm_attributes("-topmost", 1)

        if sys.platform == 'win32' or sys.platform.startswith('win') or sys.platform == 'cygwin':
            paddOS = 30
            h = 300
            w = 270
            try:
                style = ttk.Style()
                style.theme_use('default')
            except:
                h = 310
                w = 275
                pass

        elif sys.platform == "mac" or sys.platform == "darwin" or sys.platform.startswith('mac'):
            paddOS = 44
            h = 390
            w = 340
            self.root.resizable(width=FALSE, height=FALSE)
            try:
                style = ttk.Style()
                style.theme_use('alt')
            except:
                style = ttk.Style()
                style.theme_use('default')
        else:
            paddOS = 30
            h = 330
            w = 295
            try:
                style = ttk.Style()
                style.theme_use('default')
            except:
                style = ttk.Style()
                style.theme_use('alt')

        # center the window
        sw = self.root.winfo_screenwidth()
        sh = self.root.winfo_screenheight()
        x = (sw - w) / 2
        y = (sh - h) / 2
        self.root.geometry('%dx%d+%d+%d' % (w, h, x, y))

        # Widget Initialization
        root.configure(background='#c9cfcf')

        self.fram = tkinter.LabelFrame(root)

        self._label_2 = tkinter.Label(self.fram, text="Pos")
        self._label_3 = tkinter.Label(self.fram, text="Chord")
        self._label_4 = tkinter.Label(self.fram, text="Attack")

        s = ttk.Style()
        s.configure('TCombobox', fieldbackground='#ffffff')
        self._label_2.configure(background='#dee4e4')
        self._label_3.configure(background='#dee4e4')
        self._label_4.configure(background='#dee4e4')
        self.fram.configure(background='#dee4e4')

        self._label_2.grid(in_=self.fram, column=1, row=2, padx=0, pady=7, sticky="")
        self._label_3.grid(in_=self.fram, column=2, row=2, padx=0, pady=7, sticky="")
        self._label_4.grid(in_=self.fram, column=3, row=2, padx=0, pady=7, sticky="")

        # One row of widgets per letter (A-G), built in a loop instead of
        # being declared and gridded seven times over.
        self.pos_spins = []
        self.chord_combos = []
        self.pat_combos = []

        for i, entry_values in enumerate(ENTRY_STRUCTURES):
            row = 3 + i

            pos_spin = tkinter.Spinbox(root, from_=0, to=7, width=2)
            chord_combo = ttk.Combobox(root, width=8, height=8, values=entry_values)
            chord_combo.current(0)
            pat_combo = ttk.Combobox(root, width=12, height=8, values=strumPat)
            pat_combo.current(0)

            pos_spin.grid(in_=self.fram, column=1, row=row, padx=10, pady=5, sticky="")
            chord_combo.grid(in_=self.fram, column=2, row=row, padx=10, pady=5, sticky="w")
            pat_combo.grid(in_=self.fram, column=3, row=row, padx=10, pady=5, sticky="")

            self.pos_spins.append(pos_spin)
            self.chord_combos.append(chord_combo)
            self.pat_combos.append(pat_combo)

        self._button_1 = ttk.Button(root, text="Draw chords", command=self._draw_midi)

        # Geometry Management
        self.fram.grid(in_=root, column=1, row=1, columnspan=4, padx=10, pady=10, rowspan=9, sticky="news")

        self._button_1.grid(in_=self.fram, column=1, row=10, columnspan=3, padx=10, pady=5, sticky="")

        # Resize Behavior
        root.grid_rowconfigure(1, weight=0, minsize=5, pad=0)
        root.grid_rowconfigure(2, weight=0, minsize=24, pad=0)
        for r in range(3, 11):
            root.grid_rowconfigure(r, weight=0, minsize=paddOS, pad=0)
        root.grid_columnconfigure(1, weight=0, minsize=50, pad=0)
        root.grid_columnconfigure(2, weight=0, minsize=80, pad=0)
        root.grid_columnconfigure(3, weight=0, minsize=80, pad=0)

    def _draw_midi(self):

        channel = 1
        velocity = 96
        length = 1920
        steps = 1920
        selected = 1
        position = 0

        selAllNotesTselection()
        deleteSelectedNotes()

        take = getActTakeInEditor()
        midiTake = allocateMIDITake(take)

        # Read the state of all seven letter-rows up front.
        slots = []
        for chords, chord_combo, pos_spin, pat_combo in zip(
                CHORD_LISTS, self.chord_combos, self.pos_spins, self.pat_combos):
            try:
                chord_index = int(chord_combo.current())
            except TypeError:
                chord_index = 0
            try:
                pos = int(pos_spin.get())
            except TypeError:
                pos = 0
            try:
                pat_index = int(pat_combo.current())
            except TypeError:
                pat_index = 0
            slots.append({
                'chords': chords,
                'chord_index': chord_index,
                'pos': pos,
                'pat_index': pat_index,
            })

        barlen = 1 + sum(1 for s in slots if s['chord_index'] > 0)

        for j in range(1, barlen):
            for s in slots:
                if j != s['pos']:
                    continue
                if s['chord_index'] > 0:
                    step, direction, arr_idx = pattern_step(s['pat_index'])
                    chord_entry = s['chords'][s['chord_index'] - 1]
                    chord_array, range_start, range_end = build_chord_array(chord_entry, direction, arr_idx)
                    write_chord_notes(midiTake, channel, velocity, position, length, selected,
                                       chord_array, range_start, range_end, step)
                position = position + steps

        freeMIDITake(midiTake)


def getActTakeInEditor():
    return RPR_MIDIEditor_GetTake(RPR_MIDIEditor_GetActive())

def allocateMIDITake(midiTake):
    return FNG_AllocMidiTake(midiTake)

def freeMIDITake(midiTake):
    FNG_FreeMidiTake(midiTake)

def countNotes(midiTake):
    return FNG_CountMidiNotes(midiTake)

def getMidiNote(midiTake, index):
    return FNG_GetMidiNote(midiTake, index)

def getMidiNoteIntProperty(midiNote, prop):
    return FNG_GetMidiNoteIntProperty(midiNote, prop)

def setMidiNoteIntProperty(midiNote, prop, value):
    FNG_SetMidiNoteIntProperty(midiNote, prop, value)

def selAllNotesTselection(command_id=40746, islistviewcommand=0):
    RPR_MIDIEditor_LastFocused_OnCommand(command_id, islistviewcommand)

def deleteSelectedNotes(command_id=40002, islistviewcommand=0):
    RPR_MIDIEditor_LastFocused_OnCommand(command_id, islistviewcommand)

def selAllNotes(command_id=40003, islistviewcommand=0):
    RPR_MIDIEditor_LastFocused_OnCommand(command_id, islistviewcommand)

def addNote(midiTake, ch, vel, pos, pitch, length, sel):
    try:
        midiNote = FNG_AddMidiNote(midiTake)
        FNG_SetMidiNoteIntProperty(midiNote, "CHANNEL", ch)
        FNG_SetMidiNoteIntProperty(midiNote, "VELOCITY", vel)
        FNG_SetMidiNoteIntProperty(midiNote, "POSITION", pos)
        FNG_SetMidiNoteIntProperty(midiNote, "PITCH", pitch)
        FNG_SetMidiNoteIntProperty(midiNote, "LENGTH", length)
        FNG_SetMidiNoteIntProperty(midiNote, "SELECTED", sel)
        return midiNote
    except:
        RPR_ShowConsoleMsg('Could not draw notes!')
        return

def guiLoop():
    try:
        root.update()
    except tkinter.TclError:
        return  # window was closed
    RPR_defer("guiLoop()")

if __name__ == '__main__':
    root = tkinter.Tk()
    demo = G(root)
    guiLoop()
@description JRT_Navigate-Previous Note OR Measure
@author JRTaylorMusic
@version 1.0
@provides . > JRT_Navigate-Previous Note OR Measure
@about For streamlined MIDI Editor Navigation – includes OPTION TO AUTOSELECT IF NOTE(S) UNDER CURSOR (see line 18) pairs well with JRT_Navigate-Next Note OR Measure.lua

-- Main function
function main()
    --Needed Variables
    snac = reaper.NamedCommandLookup('_kawa_MIDI2_Select_OnEditCursorNotes', 0) --Select Note(s) At Cursor
    take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive()) -- Get current take being edited in MIDI Editor
    retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take) -- Get idx for last note in take
    sel_note = reaper.MIDI_EnumSelNotes(take, -1) -- Get idx for selected note
    if sel_note <= 0 then
        reaper.MIDIEditor_LastFocused_OnCommand(40684, 0) --Navigate: Move edit cursor to start of measure
        reaper.MIDIEditor_LastFocused_OnCommand(40683, 0) --Navigate: Move edit cursor left one measure
--== OPTION TO AUTOSELECT IF NOTE(S) UNDER CURSOR ==--
        --reaper.MIDIEditor_LastFocused_OnCommand(snac, 0)

    else
        reaper.MIDIEditor_LastFocused_OnCommand(40414, 0)  --Navigate: Select previous note
        reaper.MIDIEditor_LastFocused_OnCommand(40872, 0)  --Navigate: Move edit cursor to start of selected events in active MIDI media item
    end
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main()

reaper.Undo_EndBlock("JRT_Navigate-Previous Note OR Measure", -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)


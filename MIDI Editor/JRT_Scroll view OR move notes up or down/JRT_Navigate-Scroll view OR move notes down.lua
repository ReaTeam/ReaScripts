-- @noindex

-- Main function
function main()
    take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive()) -- Get current take being edited in MIDI Editor
    retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take) -- Get idx for last note in take
    sel_note = reaper.MIDI_EnumSelNotes(take, -1) -- Get idx for selected note

    if sel_note == -1 then
        reaper.MIDIEditor_LastFocused_OnCommand(40139, 0) --View: Scroll view down
    else
        reaper.MIDIEditor_LastFocused_OnCommand(40178, 0)  --Edit: Move notes down one semitone
    end
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main()

reaper.Undo_EndBlock("JRT_Navigate-Scroll View OR Move Notes Down", -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)

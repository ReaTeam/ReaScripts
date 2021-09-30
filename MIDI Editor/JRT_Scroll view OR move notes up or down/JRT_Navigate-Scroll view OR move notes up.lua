-- @noindex

-- Main function
function main()
    take = reaper.MIDIEditor_GetTake(reaper.MIDIEditor_GetActive()) -- Get current take being edited in MIDI Editor
    retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take) -- Get idx for last note in take
    sel_note = reaper.MIDI_EnumSelNotes(take, -1) -- Get idx for selected note

    if sel_note == -1 then
        reaper.MIDIEditor_LastFocused_OnCommand(40138, 0) --View: Scroll view up
    else
        reaper.MIDIEditor_LastFocused_OnCommand(40177, 0)  --Edit: Move notes up one semitone
    end
end

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main()

reaper.Undo_EndBlock("JRT_Navigate-Scroll View OR Move Notes Up", -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)

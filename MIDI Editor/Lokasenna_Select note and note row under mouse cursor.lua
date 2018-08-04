--[[
    Description: Select note and note row under mouse cursor
    Version: 1.0.0
    Author: Lokasenna
    Donation: https://paypal.me/Lokasenna
    Changelog:
        Initial Release
    Links:
        Lokasenna's Website http://forum.cockos.com/member.php?u=10417
]]--



local function Msg(str)
   reaper.ShowConsoleMsg(tostring(str) .. "\n")
end


local hwnd, take


local function get_note_row_at_mouse()

    local pitch = ({reaper.BR_GetMouseCursorContext_MIDI()})[3]

    return pitch

end

local function get_ppqpos_at_mouse()

    local time = reaper.BR_GetMouseCursorContext_Position()
    return reaper.MIDI_GetPPQPosFromProjTime(take, time)

end


local function iterAllMIDINotes(take, idx)

    if not idx then return iterAllMIDINotes, take, 0 end

    local note = {}
    note.retval, note.selected, note.muted, note.startppqpos, note.endppqpos, 
    note.chan, note.pitch, note.vel = reaper.MIDI_GetNote(take, idx)

    idx = idx + 1

    if note.retval then return idx, note end

end


local function get_note_at_mouse()

    local mouseppqpos = get_ppqpos_at_mouse()

    for idx, note in iterAllMIDINotes(take) do

        if  note.startppqpos <= mouseppqpos 
        and note.endppqpos >= mouseppqpos
        and note.pitch == get_note_row_at_mouse() then

            return idx, note

        end

    end

end


local function select_only_note(idx, note)

    -- Unselect all notes
    reaper.MIDIEditor_OnCommand(hwnd, 40214)
    -- reaper.MIDI_SetNote( take, noteidx, selectedIn, mutedIn, startppqposIn, endppqposIn, chanIn, pitchIn, velIn, noSortIn )
    reaper.MIDI_SetNote(take, idx - 1, true, note.muted, note.startppqpos, note.endppqpos, note.chan, note.pitch, note.vel, false)

end


local function select_note_row(pitch)

    if not pitch then return end

    -- 40049 - Edit: Increase pitch cursor one semitone
    -- 40050 - Edit: Decrease pitch cursor one semitone
    local cur_row = reaper.MIDIEditor_GetSetting_int(hwnd, "active_note_row")
    local off = pitch - cur_row
    if off == 0 then return end

    for i = 1, math.abs(off) do

        reaper.MIDIEditor_OnCommand(hwnd, off > 0 and 40049 or 40050)

    end

end

local function Main()

    hwnd = reaper.MIDIEditor_GetActive()
    if not hwnd then return end

    take = reaper.MIDIEditor_GetTake(hwnd)
    if not take then return end

    reaper.BR_GetMouseCursorContext()

    local idx, note = get_note_at_mouse()
    if not (idx and note.retval) then return end

    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    select_only_note(idx, note)
    select_note_row(note.pitch)

    reaper.Undo_EndBlock("Select note and note row under mouse cursor", -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()

end

Main()

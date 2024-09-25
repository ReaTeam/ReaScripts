-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local MU  = require "lib/MIDIUtils"
local S   = require "modules/settings"

local TEXT_CHANNEL = 1  -- This is the one which is called "Text", I hesitate with "Program", which is 8

local function UpdateArticulationTextEventsIfNeeded(track, take)

    if not track or not take then
        return
    end

    if not S.getTrackSetting(track, "OSSArticulationManagerEnabled") then
        return
    end

    MU.MIDI_InitializeTake(take)
    MU.MIDI_OpenWriteTransaction(take)

    local _, nc, _, tsc = MU.MIDI_CountEvts(take)
    for ti = tsc, 1, -1 do
        local _, _, _, _, type, msg = MU.MIDI_GetTextSysexEvt(take, ti - 1)

        -- Avoid destroying texts from other tool/people, we're not alone here
        -- Beware, we use an unicode diamond char and string.sub is picky
        if type == TEXT_CHANNEL and string.sub(msg,1,4) == "◈ " then
            MU.MIDI_DeleteTextSysexEvt(take, ti - 1)
        end
    end

    for ni = 1, nc do
        local _, _, _, startppqpos, _, chan, pitch, _ = MU.MIDI_GetNote(take, ni - 1)

        local note_name = reaper.GetTrackMIDINoteNameEx(0, track, pitch, chan)

        if note_name ~= nil and note_name ~= "" then
            MU.MIDI_InsertTextSysexEvt(take, false, false, startppqpos, 1, "◈ " .. note_name)
        end
    end

    MU.MIDI_CommitWriteTransaction(take);
end

return {
    UpdateArticulationTextEventsIfNeeded= UpdateArticulationTextEventsIfNeeded
}

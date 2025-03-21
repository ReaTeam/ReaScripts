-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local TakeWatcher = {}
TakeWatcher.__index = TakeWatcher

-- sample_rate is the sample rate of the signal to anayse
function TakeWatcher:new(take, cb)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(take, cb)
    return instance
end

function TakeWatcher:_initialize(take, cb)
    self.take = take
    self.cb   = cb
end

function TakeWatcher:hasChanged()
    if not self.take then return false end

    if not reaper.ValidatePtr(self.take, "MediaItem_Take*") then
        self.take = nil
        self:onChange()
        return true
    end

    local _, hash = reaper.MIDI_GetHash(self.take, false)

    if not (hash == self.last_hash) then

        local is_first = (self.last_state == nil)

        self.last_hash  = hash
        self.last_state = self.last_state or {}

        -- Possible change, need to investigate further
        local state = {}
        local i = 0

        local identical = true
        while true do
            -- Parse each event and compare to what we new
            local b, sel, muted, ppqpos, str = reaper.MIDI_GetEvt(self.take,i)
            if not b then break end

            if not (self.last_state[#state+1] == ppqpos) then identical = false end
            if not (self.last_state[#state+2] == str)    then identical = false end

            state[#state+1] = ppqpos
            state[#state+1] = str

            i = i + 1
        end

        -- Avoid notifying change on first loop
        identical = identical or is_first

        -- Save new state
        self.last_state = state

        if not identical then
            self:onChange()
        end

        return not identical
    end

    return false
end

function TakeWatcher:onChange()
    if not self.cb then return end
    self.cb()
end

return TakeWatcher

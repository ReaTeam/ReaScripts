-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local MouseObserver = {}
MouseObserver.__index = MouseObserver

function MouseObserver:new(stable_time)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(stable_time)
    return instance
end

function MouseObserver:_initialize(stable_time)
    self.stable_time = stable_time
    self.x              = -1
    self.y              = -1
    self.stable         = false
    self.stable_at      = nil
    self.stabilizing_at = nil
end

function MouseObserver:observe()
    local x,y = reaper.GetMousePosition()

    if (x == self.x) and (y == self.y) then
        local now = reaper.time_precise()
        self.stabilizing    = true
        self.stable_x       = self.stable_x or x
        self.stable_y       = self.stable_y or y
        self.stabilizing_at = self.stabilizing_at or now

        if not self.stable and (now - self.stabilizing_at > self.stable_time) then
            self.stable     = true
            self.stable_at  = self.stabilizing_at
            self.stable_x   = x
            self.stable_y   = y
            if self.onStable then
                self.onStable(self)
            end
        end
    else
        if self.onUnstable then
            self.onUnstable(self)
        end
        self.stable         = false
        self.stabilizing    = false
        self.stabilizing_at = nil
        self.stable_x       = nil
        self.stable_y       = nil
    end

    self.x = x
    self.y = y
end

return MouseObserver

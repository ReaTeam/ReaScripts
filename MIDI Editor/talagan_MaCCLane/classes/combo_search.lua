-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local MACCLContext    = require "modules/context"
local UTILS           = require "modules/utils"

local ImGui           = MACCLContext.ImGui

------

local ComboSearch = {}
ComboSearch.__index = ComboSearch

function ComboSearch:new(cb)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(cb)
    return instance
end

function ComboSearch:_initialize(cb)
    self.str = ''
    self.num = nil
    self.frame_count = 0
end

function ComboSearch:clear()
    self.str = ''
    self.num = nil
end

function ComboSearch:_trySearch(ctx, search_callback)
    local newcandidate = search_callback(self.str)
    if newcandidate then self.num = newcandidate end
    if utf8.len(self.str) == 0 then self.num = nil end
    self.should_scroll_to = self.num
end

function ComboSearch:apply(ctx, search_callback)
    self.frame_count = self.frame_count + 1

    -- Avoid treating enter on first frame
    if self.frame_count <= 1 then return end

    local ci = 0
    while true do
        local b, cuni = ImGui.GetInputQueueCharacter(ctx, ci)
        if not b then break end

        self.str = self.str .. utf8.char(cuni)
        self:_trySearch(ctx, search_callback)

        ci = ci + 1
    end

    if ImGui.IsKeyPressed(ctx, ImGui.Key_Backspace, true) then
        self.str = UTILS.utf8sub(self.str, 1, utf8.len(self.str) - 1)
        self:_trySearch(ctx, search_callback)
    end

    if ImGui.IsKeyPressed(ctx, ImGui.Key_Enter) then
        ImGui.CloseCurrentPopup(ctx)
        return self.num
    end

    if ImGui.IsKeyPressed(ctx, ImGui.Key_Escape) then
        ImGui.CloseCurrentPopup(ctx)
        return nil
    end

    return nil
end

function ComboSearch:scrollUpdate(ctx, i)
    if self.should_scroll_to == i then
        ImGui.SetKeyboardFocusHere(ctx,-1)
        ImGui.SetScrollHereY(ctx)
        self.should_scroll_to = nil
    end
end

return ComboSearch
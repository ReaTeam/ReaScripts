-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local Tab             = require "classes/tab"
local MACCLContext    = require "modules/context"

local AddTabTab = {}
AddTabTab.__index = AddTabTab
setmetatable(AddTabTab, Tab)

function AddTabTab:new(mec)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize()
    instance.mec = mec
    return instance
end

function AddTabTab:_initialize()
    -- Super
    Tab._initialize(self)

    self.owner      = nil
    self.owner_type = Tab.Types.PLUS_TAB

    self.params.title = "+"
end

function AddTabTab:width()
    -- Square button
    return MACCLContext.TABBAR_HEIGHT
end

function AddTabTab:isRound()
    return true
end

function AddTabTab:callableByAction()
    return false
end
function AddTabTab:onLeftClick(mec, click_params)
    mec:openEditorForNewTab(self)
end

function AddTabTab:onRightClick(mec)
    mec:openTabContextMenuOn(self)
end


return AddTabTab

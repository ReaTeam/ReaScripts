-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local GlobalScopeRepo = {}
GlobalScopeRepo.__index = GlobalScopeRepo

function GlobalScopeRepo:new()
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize()
    return instance
end

function GlobalScopeRepo:_initialize()
    self:restore()
end

function GlobalScopeRepo:path()
    return reaper.GetResourcePath() .. "/Data/MaCCLane/_global.mccg"
end

function GlobalScopeRepo:restore()
    local file, err  = io.open(self:path(), "rb")

    self.content = ""
    if not file then return end
    self.content = file:read("*all")
    file:close()
end

function GlobalScopeRepo:backup()
    local file, err  = io.open(self:path(), "wb")
    if file then
        file:write(self.content or "")
        io.close(file)
    else
        -- Euuuhhhh
    end
end

function GlobalScopeRepo:getContent()
    return self.content
end

function GlobalScopeRepo:setContent(content)
    self.content = content
    self:backup()
end

function GlobalScopeRepo:isGlobalScopeRepo()
    return true
end

local _instance = nil
function GlobalScopeRepo.instance()
    if not _instance then _instance = GlobalScopeRepo:new() end
    return _instance
end

return GlobalScopeRepo
-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local Notes = require 'classes/notes'

local MemCache = {}
MemCache.__index = MemCache

function MemCache:new()
  local instance = {}
  setmetatable(instance, self)
  instance:_initialize()
  return instance
end

function MemCache:_initialize()
  self._repo = {}

  MemCache.__singleton = self
end

function MemCache.GetObjectGUID(object)
  local guid = ''
  if type(object) == "table" then
    if object.t == 'region' then
      guid = object.guid
    else
      error("Unhandled custom type " .. object.t .. " for object")
    end
  elseif reaper.ValidatePtr(object, "MediaTrack*") then
    local tguid = reaper.GetTrackGUID(object)
    guid = tguid
  elseif reaper.ValidatePtr(object,"MediaItem*") then
    local _, tguid = reaper.GetSetMediaItemInfo_String(object, "GUID", "", false)
    guid = tguid
  elseif reaper.ValidatePtr(object, "TrackEnvelope*") then
    local _, tguid = reaper.GetSetEnvelopeInfo_String(object, "GUID", "", false)
    guid = tguid
  elseif reaper.ValidatePtr(object, "ReaProject*") then
    local _, tguid = reaper.GetSetProjectInfo_String(object, "PROJECT_NAME", "", false)
    guid = tguid
  else
    error("Unhandled type for object")
  end
  return guid
end

function MemCache:getObjectCache(object)

  local guid = MemCache.GetObjectGUID(object)

  if not self._repo[guid] then
    -- Build object cache

    local name = ''
    local kind = ''
    if type(object) == "table" then
      if object.t == 'region' then
        name = object.n or ''
        kind = object.t
      else
        error("Unhandled custom type " .. object.t .. " for object")
      end
    elseif reaper.ValidatePtr(object, "MediaTrack*") then
      local _, tname = reaper.GetTrackName(object)
      name = tname
      kind = 'track'
    elseif reaper.ValidatePtr(object,"MediaItem*") then
      local take = reaper.GetActiveTake(object)
      if take then
        name = reaper.GetTakeName(take)
      end
      kind = 'item'
    elseif reaper.ValidatePtr(object, "TrackEnvelope*") then
      local _, ename = reaper.GetEnvelopeName(object)
      name = ename
      kind = 'env'
    elseif reaper.ValidatePtr(object, "ReaProject*") then
      name = "Project"
      kind = 'project'
    else
      error("Unhandled type for object")
    end

    -- Cache miss, pull info from object
    self._repo[guid] = {
      guid    = guid,
      object  = object,
      name    = name,
      type    = kind,
      -- Notes cache
      notes   = Notes:new(object)
    }
  end

  return self._repo[guid]
end

function MemCache.instance()
  if not MemCache.__singleton then
    MemCache.__singleton = MemCache:new()
  end

  return MemCache.__singleton
end

return MemCache

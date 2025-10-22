-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local JSON = require "ext/json"
local S    = require "modules/settings"

local TT_DEFAULT_W = 300
local TT_DEFAULT_H = 100
local MAX_SLOTS    = 8 -- Slot 0 is counted

local function normalizeNotes(str)
    return str:gsub("\r","")
end

local function normalizeCoordinate(c, default_val)
    if (not c) or (type(c) ~= "number") then c = default_val end
    return c
end

local function normalizeReannotateData(data)

    if not data.tt_sizes    then data.tt_sizes   = {} end
    if not data.slots       then data.slots   = {} end

    for i=1, MAX_SLOTS-1 do
        data.tt_sizes[i]    = data.tt_sizes[i] or {}
        data.tt_sizes[i].w  = normalizeCoordinate(data.tt_sizes[i].w, TT_DEFAULT_W)
        data.tt_sizes[i].h  = normalizeCoordinate(data.tt_sizes[i].h, TT_DEFAULT_H)
        data.slots[i]       = data.slots[i] or ""
    end

    -- Special treatment for slot 0
    data.sws_reaper_tt_size = data.sws_reaper_tt_size or {}
    data.sws_reaper_tt_size.w = normalizeCoordinate(data.sws_reaper_tt_size.w, TT_DEFAULT_W)
    data.sws_reaper_tt_size.h = normalizeCoordinate(data.sws_reaper_tt_size.h, TT_DEFAULT_H)

    return data
end

local function activeProject()
    local p, _ = reaper.EnumProjects(-1)
    return p
end

local function AttributeGetterSetter(object)
    local getter = nil
    if reaper.ValidatePtr(object, "MediaTrack*") then
        getter = reaper.GetSetMediaTrackInfo_String
    elseif reaper.ValidatePtr(object, "TrackEnvelope*") then
        getter = reaper.GetSetEnvelopeInfo_String
    elseif reaper.ValidatePtr(object,"MediaItem*") then
        getter = reaper.GetSetMediaItemInfo_String
    elseif reaper.ValidatePtr(object, "ReaProject*") then
        -- We'll use the master track with a different key
        getter = reaper.GetSetMediaTrackInfo_String
    else
        error("Unhandled type for object")
    end
    return getter
end

local function StoreKey(object)
    if reaper.ValidatePtr(object, "ReaProject*") then
        return "P_EXT:Reannotate_ProjectNotes"
    else
        return "P_EXT:Reannotate_Notes"
    end
end

local function StoreObject(object)
    if reaper.ValidatePtr(object, "ReaProject*") then
        return reaper.GetMasterTrack(activeProject())
    else
        return object
    end
end

local function GetObjectNotes_Reannotate(object)
    local getter        = AttributeGetterSetter(object)
    local store_object  = StoreObject(object)
    local store_key     = StoreKey(object)

    local ret           = {}
    local b, v          = getter(store_object, store_key, "", false)
    if b then
        ret = JSON.decode(v)
    end
    ret = normalizeReannotateData(ret)
    return b, ret
end

local function SetObjectNotes_Reannotate(object, data)
    local setter        = AttributeGetterSetter(object)
    local store_object  = StoreObject(object)
    local store_key     = StoreKey(object)

    data                = normalizeReannotateData(data)
    local data_str      = JSON.encode(data)

    return setter(store_object, store_key, data_str, true)
end

----------
-- ITEM --
----------
local function GetItemNotes_SWS_Reaper(item)
    local b, v = reaper.GetSetMediaItemInfo_String(item, "P_NOTES", "", false)
    v = normalizeNotes(v)
    b = (b and not (v == ""))
    return b, v
end

local function SetItemNotes_SWS_Reaper(item, str)
    str = str:gsub("\r\n","\n")
    return reaper.GetSetMediaItemInfo_String(item, "P_NOTES", str, true)
end

-----------
-- TRACK --
-----------
local function GetTrackNotes_SWS_Reaper(track)
    local v = reaper.NF_GetSWSTrackNotes(track) or ""
    v = normalizeNotes(v)
    local b = (v ~= "")
    return b, v
end
local function SetTrackNotes_SWS_Reaper(track, str)
    return reaper.NF_SetSWSTrackNotes(track, str)
end

-----------
-- ENVELOPE --
-----------
local function GetEnvelopeNotes_SWS_Reaper(track)
    -- Not handled by SWS
    return true, ""
end
local function SetEnvelopeNotes_SWS_Reaper(envelope, str)
    -- Not handled by SWS
    return true, ""
end

-------------
-- PROJECT --
-------------

local function GetActiveProjectNotes_SWS_Reaper()
    local v = reaper.GetSetProjectNotes(activeProject(), false, "")
    --reaper.JB_GetSWSExtraProjectNotes(activeProject())
    v = normalizeNotes(v)
    local b = (v ~= "")
    return b, v
end
local function SetActiveProjectNotes_SWS_Reaper(str)
    local project = activeProject()
    local notes   = normalizeNotes(str)
    -- reaper.JB_SetSWSExtraProjectNotes(project, notes)
    return reaper.GetSetProjectNotes(project, true, notes)
end

local function GetObjectNotes_SWS_Reaper(object)
    if reaper.ValidatePtr(object, "MediaTrack*") then
        return GetTrackNotes_SWS_Reaper(object)
    elseif reaper.ValidatePtr(object, "TrackEnvelope*") then
        return GetEnvelopeNotes_SWS_Reaper(object)
    elseif reaper.ValidatePtr(object,"MediaItem*") then
        return GetItemNotes_SWS_Reaper(object)
    elseif reaper.ValidatePtr(object, "ReaProject*") then
        return GetActiveProjectNotes_SWS_Reaper()
    else
        error("Unhandled type for object")
    end
end

local function SetObjectNotes_SWS_Reaper(object, str)
    if reaper.ValidatePtr(object, "MediaTrack*") then
        return SetTrackNotes_SWS_Reaper(object, str)
    elseif reaper.ValidatePtr(object,"TrackEnvelope*") then
        return SetEnvelopeNotes_SWS_Reaper(object, str)
    elseif reaper.ValidatePtr(object,"MediaItem*") then
        return SetItemNotes_SWS_Reaper(object, str)
    elseif reaper.ValidatePtr(object, "ReaProject*") then
        return SetActiveProjectNotes_SWS_Reaper(str)
    else
        error("Unhandled type for object")
    end
end

--------------

local Notes = {}
Notes.__index = Notes

Notes.MAX_SLOTS = MAX_SLOTS

Notes.POST_IT_COLORS = {
    0xFFFFFF, -- WHITE      Slot 0
    0x40acff, -- BLUE
    0x753ffc, -- VIOLET
    0xff40e5, -- PINK
    0xffe240, -- YELLOW
    0x3cf048, -- GREEN
    0xff9640, -- ORANGE
    0xff4040, -- RED        Slot 7
}


function Notes:new(object, should_pull)
  local instance = {}
  setmetatable(instance, self)
  instance:_initialize(object, should_pull)
  return instance
end

function Notes:_initialize(object, should_pull)
    self._object = object

    if should_pull == true or should_pull == nil then
        self:pull()
    end
end

function Notes:pull()
    local b, v  = GetObjectNotes_Reannotate(self._object)
    self.reannotate_notes = v
    b, v        = GetObjectNotes_SWS_Reaper(self._object)
    self.sws_reaper_notes = v
end

function Notes:commit()
    SetObjectNotes_Reannotate(self._object, self.reannotate_notes)
    SetObjectNotes_SWS_Reaper(self._object, self.sws_reaper_notes)
end

function Notes:tooltipSize(slot)
    if slot == 0 then
        return self.reannotate_notes.sws_reaper_tt_size.w, self.reannotate_notes.sws_reaper_tt_size.h
    else
        return self.reannotate_notes.tt_sizes[slot].w, self.reannotate_notes.tt_sizes[slot].h
    end
end


function Notes:setTooltipSize(slot, w, h)
    w = normalizeCoordinate(w, TT_DEFAULT_W)
    h = normalizeCoordinate(h, TT_DEFAULT_H)

    if slot == 0 then
        self.reannotate_notes.sws_reaper_tt_size = { w = w, h = h }
    else
        self.reannotate_notes.tt_sizes[slot] = { w = w, h = h }
    end
end

function Notes:isBlank()
    local ret = true
    if self.sws_reaper_notes and self.sws_reaper_notes ~= "" then return false end
    for k,v in pairs(self.reannotate_notes.slots) do
        if v and v~= "" then return false end
    end
    return ret
end

function Notes:slot(slot)
    if slot == 0 then
        return self.sws_reaper_notes or ""
    else
        return self.reannotate_notes.slots[slot] or ""
    end
end

function Notes:setSlot(slot, str)
    if slot == 0 then
        self.sws_reaper_notes = str or ""
    else
        self.reannotate_notes.slots[slot] = str or ""
    end
end

function Notes.RetrieveProjectSlotLabels()
    local _, str = reaper.GetSetMediaTrackInfo_String(reaper.GetMasterTrack(activeProject()), "P_EXT:Reannotate_ProjectSlotLabels", "", false)
    local slot_labels = {}
    if str == "" or str == nil then
    else
        slot_labels = JSON.decode(str)
    end

    -- Ensure labels have names by defaulting to global setting
    for i = 0, Notes.MAX_SLOTS -1 do
        slot_labels[i+1] = slot_labels[i+1] or S.getSetting("SlotLabel_" .. i)
    end

    Notes.slot_labels = slot_labels
end

function Notes.CommitProjectSlotLabels()
    if not Notes.slot_labels_dirty  then return end
    if not Notes.slot_labels        then Notes.RetrieveProjectSlotLabels() end

    local str = JSON.encode(Notes.slot_labels)
    reaper.GetSetMediaTrackInfo_String(reaper.GetMasterTrack(activeProject()), "P_EXT:Reannotate_ProjectSlotLabels", str, true)
    Notes.slot_labels_dirty = false
end


function Notes.SlotColor(slot)
    return Notes.POST_IT_COLORS[slot+1]
end

function Notes.SlotLabel(slot)
    if not Notes.slot_labels then Notes.RetrieveProjectSlotLabels() end
    return Notes.slot_labels[slot+1]
end

function Notes.SetSlotLabel(slot, label)
    if not Notes.slot_labels then Notes.RetrieveProjectSlotLabels() end
    Notes.slot_labels[slot+1] = label
    Notes.slot_labels_dirty = true
    Notes.CommitProjectSlotLabels()
end

function Notes.defaultTooltipSize()
    return TT_DEFAULT_W, TT_DEFAULT_H
end

return Notes

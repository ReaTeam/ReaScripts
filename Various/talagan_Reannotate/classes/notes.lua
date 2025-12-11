-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local JSON              = require "ext/json"
local CheckboxHelper    = require "modules/checkbox_helper"
local Sticker           = require "classes/sticker"
local D                 = require "modules/defines"
local PS                = require "modules/project_settings"

local function normalizeNotes(str)
    return str:gsub("\r","")
end

local function normalizeCoordinate(c, default_val)
    if (not c) or (type(c) ~= "number") then c = default_val end
    return c
end

local function normalizeReannotateData(data)

    if not data.tt_sizes    then data.tt_sizes      = {} end
    if not data.slots       then data.slots         = {} end
    if not data.stickers    then data.stickers      = {} end
    if not data.cb          then data.cb            = {} end
    if not data.posters     then data.posters       = {} end

    for i=1, D.MAX_SLOTS-1 do
        data.slots[i]       = data.slots[i] or "" -- Stored text
        data.tt_sizes[i]    = data.tt_sizes[i] or {}
        data.tt_sizes[i].w  = normalizeCoordinate(data.tt_sizes[i].w, D.TT_DEFAULT_W)
        data.tt_sizes[i].h  = normalizeCoordinate(data.tt_sizes[i].h, D.TT_DEFAULT_H)
        data.stickers[i]    = data.stickers[i] or {} -- List or empty list of packed stickers
        data.cb[i]          = data.cb[i] or {} -- Checkbox cache
        data.posters[i]     = data.posters[i] or {}
        data.posters[i].t   = data.posters[i].t or D.POSTER_TYPES.PROJECT_DEFAULT
        data.posters[i].s   = data.posters[i].s or ""
    end

    -- Special treatment for slot 0
    data.sws_reaper_tt_size     = data.sws_reaper_tt_size or {}
    data.sws_reaper_tt_size.w   = normalizeCoordinate(data.sws_reaper_tt_size.w, D.TT_DEFAULT_W)
    data.sws_reaper_tt_size.h   = normalizeCoordinate(data.sws_reaper_tt_size.h, D.TT_DEFAULT_H)
    data.sws_reaper_stickers    = data.sws_reaper_stickers or {}
    data.sr_cb                  = data.sr_cb or {}
    data.sws_reaper_poster      = data.sws_reaper_poster or {}
    data.sws_reaper_poster.t    = data.sws_reaper_poster.t or D.POSTER_TYPES.PROJECT_DEFAULT
    data.sws_reaper_poster.s    = data.sws_reaper_poster.s or ""
    -- data.sws_reaper_text <-- stored in reaper / SWS
    return data
end

local function AttributeGetterSetter(object)
    local getter = nil
    if type(object) == 'table' then
        if object.t == 'region' then
            -- We'll store on the master track with a different ke
            getter = reaper.GetSetMediaTrackInfo_String
        else
            error("Unhandled custom type " .. object.t .. " for object ")
        end
    elseif reaper.ValidatePtr(object, "MediaTrack*") then
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
    if type(object) == 'table' then
        if object.t == 'region' then
            return "P_EXT:Reannotate_RegionNotes:" .. object.guid
        else
            error("Unhandled custom type " .. object.t .. " for object ")
        end
    elseif reaper.ValidatePtr(object, "ReaProject*") then
        return "P_EXT:Reannotate_ProjectNotes"
    else
        return "P_EXT:Reannotate_Notes"
    end
end

local function StoreObject(object)
    if type(object) == 'table' then
        if object.t == 'region' then
            return reaper.GetMasterTrack(D.ActiveProject())
        else
            error("Unhandled custom type " .. object.t .. " for object ")
        end
    elseif reaper.ValidatePtr(object, "ReaProject*") then
        return reaper.GetMasterTrack(D.ActiveProject())
    else
        return object
    end
end

local function GetObjectNotes_Reannotate(notes)
    local object        = notes._object
    local getter        = AttributeGetterSetter(object)
    local store_object  = StoreObject(object)
    local store_key     = StoreKey(object)

    local ret           = {}
    local b, v          = getter(store_object, store_key, "", false)
    if b then
        ret = JSON.decode(v)
    end
    ret = normalizeReannotateData(ret)

    -- Deserialize sitckers
    for slot, packed_stickers in ipairs(ret.stickers) do
        ret.stickers[slot] = Sticker.UnpackCollection(packed_stickers, notes, slot)
    end
    ret.sws_reaper_stickers = Sticker.UnpackCollection(ret.sws_reaper_stickers, notes, 0)

    return b, ret
end

local function SetObjectNotes_Reannotate(object, data)
    local setter        = AttributeGetterSetter(object)
    local store_object  = StoreObject(object)
    local store_key     = StoreKey(object)

    -- Clone the data before storing, because there are objects here (stickers)
    local new_data          = {
        -- SWS/Reaper additional
        sws_reaper_tt_size  = data.sws_reaper_tt_size,
        sr_cb               = data.sr_cb,
        sws_reaper_stickers = {},
        sws_reaper_poster   = D.deepCopy(data.sws_reaper_poster),
        -- Reannotate structures
        tt_sizes            = data.tt_sizes,
        slots               = data.slots,
        cb                  = data.cb,
        stickers            = {},
        posters             = D.deepCopy(data.posters)
    }

    -- Serialize stickers
    for slot, unpacked_stickers in ipairs(data.stickers) do
        new_data.stickers[slot] = Sticker.PackCollection(unpacked_stickers)
    end
    new_data.sws_reaper_stickers = Sticker.PackCollection(data.sws_reaper_stickers)

    -- Normalize before packing
    new_data  = normalizeReannotateData(new_data)

    local data_str      = JSON.encode(new_data)
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
    local v = reaper.GetSetProjectNotes(D.ActiveProject(), false, "")
    --reaper.JB_GetSWSExtraProjectNotes(activeProject())
    v = normalizeNotes(v)
    local b = (v ~= "")
    return b, v
end
local function SetActiveProjectNotes_SWS_Reaper(str)
    local project = D.ActiveProject()
    local notes   = normalizeNotes(str)
    -- reaper.JB_SetSWSExtraProjectNotes(project, notes)
    return reaper.GetSetProjectNotes(project, true, notes)
end

-------------
-- REGION --
-------------

local function GetRegionNotes_SWS_Reaper(object)
    -- Not handled by SWS
    return true, ""
end
local function SetRegionNotes_SWS_Reaper(object, str)
    -- Not handled by SWS
    return true, ""
end

local function GetObjectNotes_SWS_Reaper(notes)
    local object = notes._object
    if type(object) == 'table' then
        if object.t == 'region' then
            return GetRegionNotes_SWS_Reaper(object)
        else
            error("Unhandled custom type " .. object.t .. " for object ")
        end
    elseif reaper.ValidatePtr(object, "MediaTrack*") then
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
    if type(object) == 'table' then
        if object.t == 'region' then
            return SetRegionNotes_SWS_Reaper(object, str)
        else
            error("Unhandled custom type " .. object.t .. " for object ")
        end
    elseif reaper.ValidatePtr(object, "MediaTrack*") then
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
    local b, v  = GetObjectNotes_Reannotate(self)
    self.reannotate_notes = v
    b, v        = GetObjectNotes_SWS_Reaper(self)
    self.sws_reaper_notes = v
end

function Notes:commit()
    SetObjectNotes_Reannotate(self._object, self.reannotate_notes)
    SetObjectNotes_SWS_Reaper(self._object, self.sws_reaper_notes)
end

function Notes:isSlotNoteBlank(slot)
    if slot == 0 then
        if self.sws_reaper_notes and self.sws_reaper_notes ~= "" then return false end
    else
        if self.reannotate_notes.slots[slot] and self.reannotate_notes.slots[slot] ~= '' then return false end
    end
    return true
end

function Notes:isSlotStickersBlank(slot)
    if slot == 0 then
        if #self.reannotate_notes.sws_reaper_stickers > 0 then return false end
    else
        if #self.reannotate_notes.stickers[slot] > 0 then return false end
    end
    return true
end

function Notes:isSlotPosterBlank(slot)
    local type = self:resolvedSlotPosterType(slot)
    if type == D.POSTER_TYPES.NO_POSTER then
        return true
    elseif type == D.POSTER_TYPES.CUSTOM_PLAIN_POSTER or type == D.POSTER_TYPES.CUSTOM_MARKDOWN_POSTER then
        -- If in custom mode, check custom poster
        if slot == 0 then
            if self.reannotate_notes.sws_reaper_poster and self.reannotate_notes.sws_reaper_poster.s ~= "" then return false end
        else
            if self.reannotate_notes.posters[slot] and self.reannotate_notes.posters[slot].s ~= '' then return false end
        end
        return true
    else
        -- If not in custom mode, check note
        return self:isSlotNoteBlank(slot)
    end
end

function Notes:isSlotBlank(slot)
    if not self:isSlotNoteBlank(slot) then return false end
    if not self:isSlotStickersBlank(slot) then return false end
    if not self:isSlotPosterBlank(slot) then return false end

    return true
end

function Notes:isBlank()
    for slot=0, D.MAX_SLOTS -1 do
        if not self:isSlotBlank(slot) then return false end
    end
    return true
end

function Notes:tooltipSize(slot)
    if slot == 0 then
        return self.reannotate_notes.sws_reaper_tt_size.w, self.reannotate_notes.sws_reaper_tt_size.h
    else
        return self.reannotate_notes.tt_sizes[slot].w, self.reannotate_notes.tt_sizes[slot].h
    end
end
function Notes:setTooltipSize(slot, w, h)
    w = normalizeCoordinate(w, D.TT_DEFAULT_W)
    h = normalizeCoordinate(h, D.TT_DEFAULT_H)

    if slot == 0 then
        self.reannotate_notes.sws_reaper_tt_size = { w = w, h = h }
    else
        self.reannotate_notes.tt_sizes[slot] = { w = w, h = h }
    end
end

function Notes:slotText(slot)
    if slot == 0 then
        return self.sws_reaper_notes or ""
    else
        return self.reannotate_notes.slots[slot] or ""
    end
end
function Notes:setSlotText(slot, str)
    if slot == 0 then
        self.sws_reaper_notes = str or ""
    else
        self.reannotate_notes.slots[slot] = str or ""
    end

    -- Cache checkbox counts
    local counts = CheckboxHelper.CountCheckboxes(str)
    if slot == 0 then
        self.reannotate_notes.sr_cb = counts
    else
        self.reannotate_notes.cb[slot] = counts
    end
end

function Notes:resolvedSlotPosterType(slot)
    local type = self:slotPosterType(slot)
    if type == D.POSTER_TYPES.PROJECT_DEFAULT then
        return PS.ProjectPosterDefaultType()
    end
    return type
end

function Notes:slotCustomPoster(slot)
    if slot == 0 then
        self.reannotate_notes.sws_reaper_poster      = self.reannotate_notes.sws_reaper_poster or { t = D.POSTER_TYPES.PROJECT_DEFAULT, s = '' }
        return self.reannotate_notes.sws_reaper_poster.s
    else
        self.reannotate_notes.posters[slot]     = self.reannotate_notes.posters[slot] or { t = D.POSTER_TYPES.PROJECT_DEFAULT, s = '' }
        return self.reannotate_notes.posters[slot].s
    end
end
function Notes:setSlotCustomPoster(slot, str)
    if slot == 0 then
        self.reannotate_notes.sws_reaper_poster      = self.reannotate_notes.sws_reaper_poster or { t = D.POSTER_TYPES.PROJECT_DEFAULT, s = '' }
        self.reannotate_notes.sws_reaper_poster.s    = str
    else
        self.reannotate_notes.posters[slot]     = self.reannotate_notes.posters[slot] or { t = D.POSTER_TYPES.PROJECT_DEFAULT, s = '' }
        self.reannotate_notes.posters[slot].s   = str
    end
end


function Notes:slotPosterType(slot)
    if slot == 0 then
        self.reannotate_notes.sws_reaper_poster      = self.reannotate_notes.sws_reaper_poster or { t = D.POSTER_TYPES.PROJECT_DEFAULT, s = '' }
        return self.reannotate_notes.sws_reaper_poster.t
    else
        self.reannotate_notes.posters[slot]     = self.reannotate_notes.posters[slot] or { t = D.POSTER_TYPES.PROJECT_DEFAULT, s = '' }
        return self.reannotate_notes.posters[slot].t
    end
end
function Notes:setSlotPosterType(slot, type)
    if slot == 0 then
        self.reannotate_notes.sws_reaper_poster      = self.reannotate_notes.sws_reaper_poster or { t = D.POSTER_TYPES.PROJECT_DEFAULT, s = '' }
        self.reannotate_notes.sws_reaper_poster.t    = type
    else
        self.reannotate_notes.posters[slot]     = self.reannotate_notes.posters[slot] or { t = D.POSTER_TYPES.PROJECT_DEFAULT, s = '' }
        self.reannotate_notes.posters[slot].t   = type
    end
end


function Notes:slotStickers(slot)
    if slot == 0 then
        return self.reannotate_notes.sws_reaper_stickers or {}
    else
        return self.reannotate_notes.stickers[slot] or {}
    end
end
function Notes:setSlotStickers(slot, stickers)
    if slot == 0 then
        self.reannotate_notes.sws_reaper_stickers = stickers
    else
        self.reannotate_notes.stickers[slot] = stickers
    end
end

function Notes:slotCheckboxCache(slot)
    local ret = {}
    if slot == 0 then
        ret = self.reannotate_notes.sr_cb or {}
    else
        ret = self.reannotate_notes.cb[slot] or {}
    end

    ret.t = ret.t or 0
    ret.c = ret.c or 0
    return ret
end

------------------------------------

return Notes

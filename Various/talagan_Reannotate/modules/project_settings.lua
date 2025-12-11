-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local S       = require "modules/settings"
local D       = require "modules/defines"
local JSON    = require "ext/json"

local PS = {}


-- Use a cache for slot labels to avoid constant JSON serialization / deserialization
PS.slot_labels = nil
PS.slot_labels_dirty = nil

PS.poster_default_type = nil

-- Not edited directly because we want preview / save features.
function PS.RetrieveProjectMarkdownStyle()
    local _, str            = reaper.GetSetMediaTrackInfo_String(D.ActiveProjectMasterTrack(), "P_EXT:Reannotate_ProjectMarkdownStyle", "", false)

    local markdown_style = nil
    local fallback       = false

    if str == "" or str == nil then
        fallback = true
    else
        pcall(function()
            markdown_style = JSON.decode(str)
        end)

        if not markdown_style then
            fallback = true
        end
    end

    if fallback then
        -- Use new project markdown style
        markdown_style = D.deepCopy(S.getSetting("NewProjectMarkdown"))
        -- Commit it in project
        PS.CommitProjectMarkdownStyle(markdown_style)
    end

    -- TODO : Normalize markdown_style after checkout for backward comp

    return markdown_style
end

function PS.CommitProjectMarkdownStyle(markdown_style)
    -- TODO : Normalize markdown_style before commit for backward comp

    local str = JSON.encode(markdown_style)

    reaper.GetSetMediaTrackInfo_String(D.ActiveProjectMasterTrack(),"P_EXT:Reannotate_ProjectMarkdownStyle", str, true)
end



function PS.RetrieveProjectStickerSize()
    local _, str =  reaper.GetSetMediaTrackInfo_String(D.ActiveProjectMasterTrack(), "P_EXT:Reannotate_ProjectStickerSize", "", false)
    local fallback = false
    local size = nil
    if str == "" or str == nil then
        fallback = true
    else
        size = tonumber(str)
    end

    if fallback then
        size = S.getSetting("NewProjectStickerSize")
        PS.CommitProjectStickerSize(size)
    end

    return size
end

function PS.CommitProjectStickerSize(size)
    reaper.GetSetMediaTrackInfo_String(D.ActiveProjectMasterTrack(),"P_EXT:Reannotate_ProjectStickerSize", "" .. size, true)
end


function PS.RetrieveProjectPosterDefaultType()
    local _, str =  reaper.GetSetMediaTrackInfo_String(D.ActiveProjectMasterTrack(), "P_EXT:Reannotate_PosterDefaultType", "", false)
    local fallback = false
    local type = nil
    if str == "" or str == nil then
        fallback = true
    else
        type = tonumber(str)
    end

    if fallback then
        type = S.getSetting("NewProjectPosterDefaultType")
        PS.CommitProjectPosterDefaultType(type)
    end

    return type
end

function PS.CommitProjectPosterDefaultType(type)
    reaper.GetSetMediaTrackInfo_String(D.ActiveProjectMasterTrack(),"P_EXT:Reannotate_PosterDefaultType", "" .. type, true)
end

function PS.ProjectPosterDefaultType()
    if not PS.poster_default_type then
        PS.poster_default_type = PS.RetrieveProjectPosterDefaultType()
    end
    return PS.poster_default_type
end

function PS.SetProjectPosterDefaultType(type)
    PS.poster_default_type = type
    PS.CommitProjectPosterDefaultType(type)
end



function PS.RetrieveProjectSlotLabels()
    local _, str = reaper.GetSetMediaTrackInfo_String(D.ActiveProjectMasterTrack(), "P_EXT:Reannotate_ProjectSlotLabels", "", false)
    local slot_labels = {}
    if str == "" or str == nil then
    else
        slot_labels = JSON.decode(str)
    end

    -- Ensure labels have names by defaulting to global setting
    for i = 0, D.MAX_SLOTS -1 do
        slot_labels[i+1] = slot_labels[i+1] or S.getSetting("SlotLabel_" .. i)
    end

    PS.slot_labels = slot_labels
end

function PS.CommitProjectSlotLabels()
    if not PS.slot_labels_dirty  then return end
    if not PS.slot_labels        then PS.RetrieveProjectSlotLabels() end

    local str = JSON.encode(PS.slot_labels)
    reaper.GetSetMediaTrackInfo_String(D.ActiveProjectMasterTrack(), "P_EXT:Reannotate_ProjectSlotLabels", str, true)
    PS.slot_labels_dirty = false
end



function PS.SlotLabel(slot)
    if not PS.slot_labels then PS.RetrieveProjectSlotLabels() end
    return PS.slot_labels[slot+1]
end

function PS.SetSlotLabel(slot, label)
    if not PS.slot_labels then PS.RetrieveProjectSlotLabels() end
    PS.slot_labels[slot+1] = label
    PS.slot_labels_dirty = true
    PS.CommitProjectSlotLabels()
end

return PS

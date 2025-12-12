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

-- ====== STYLES ======

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

-- ====== LABELS ======

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



function PS.CommitProjectSetting(project_key, value)
    reaper.GetSetMediaTrackInfo_String(D.ActiveProjectMasterTrack(),"P_EXT:" .. project_key, "" .. value, true)
end
function PS.RetrieveProjectSettingWithFallback(project_key, global_setting_key)
    local _, str    =  reaper.GetSetMediaTrackInfo_String(D.ActiveProjectMasterTrack(), "P_EXT:" .. project_key, "", false)
    local fallback  = false
    local value     = nil
    if str == "" or str == nil then
        fallback = true
    else
        value = tonumber(str)
    end

    if fallback then
        value = S.getSetting(global_setting_key)
        PS.CommitProjectSetting(project_key, value)
    end

    return value
end


function PS.RetrieveProjectStickerSize()
    return PS.RetrieveProjectSettingWithFallback("Reannotate_ProjectStickerSize","NewProjectStickerSize")
end
function PS.CommitProjectStickerSize(size)
    PS.CommitProjectSetting("Reannotate_ProjectStickerSize", size)
end


function PS.RetrieveProjectPosterDefaultType()
    return PS.RetrieveProjectSettingWithFallback("Reannotate_PosterDefaultType", "NewProjectPosterDefaultType")
end
function PS.CommitProjectPosterDefaultType(type)
    PS.CommitProjectSetting("Reannotate_PosterDefaultType", type)
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


function PS.RetrieveProjectStickerPositioning()
    return PS.RetrieveProjectSettingWithFallback("Reannotate_StickerPositioning", "NewProjectStickerPositioning")
end
function PS.CommitProjectStickerPositioning(val)
    PS.CommitProjectSetting("Reannotate_StickerPositioning", val)
end
function PS.ProjectStickerPositioning()
    if not PS.sticker_positioning then
        PS.sticker_positioning = PS.RetrieveProjectStickerPositioning()
    end
    return PS.sticker_positioning
end
function PS.SetProjectStickerPositioning(val)
    PS.sticker_positioning = val
    PS.CommitProjectStickerPositioning(val)
end



return PS

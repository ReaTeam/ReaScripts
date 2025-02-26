-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local Tab       = require "classes/tab"
local JSON      = require "lib/json"

Serializing = {}

-- Load tabs contained in entity
Serializing.loadTabsFromEntity = function(etype, entity)
    local succ, v = false, ''

    if not entity and not (etype == 'project') then
        return {}
    end

    if etype == "project" then
        -- Allow to pass nil
        local master_track = reaper.GetMasterTrack()
        succ, v = reaper.GetSetMediaTrackInfo_String(master_track, "P_EXT:MACCLANE", '', false)
    elseif etype == "track" then
        succ, v = reaper.GetSetMediaTrackInfo_String(entity, "P_EXT:MACCLANE", '', false)
    else
        succ, v = reaper.GetSetMediaItemInfo_String(entity, "P_EXT:MACCLANE", '', false)
    end

    local json_tabs = {}
    if succ then
        json_tabs = JSON.decode(v)
    end

    local tabs = {}
    for uuid, tab_params in pairs(json_tabs) do
        local tab   = Tab:new(entity, tab_params)
        -- Use saved uuid
        tab.uuid        = uuid
        tab.new_record  = false

        tabs[tab:UUID()] = tab
    end

    return tabs
end

Serializing.saveTabsToEntitity = function(etype, entity, tabs)
    local succ, v = false, ''

    if not entity and not (etype == 'project') then
        return { success=false, errors={ 'No entity given !'} }
    end

    local tab_params_array = {}
    for uuid, t in pairs(tabs) do
        tab_params_array[uuid] = t.params
    end

    local json = JSON.encode(tab_params_array)

    if etype == "project" then
        -- Allow to pass nil
        local master_track = reaper.GetMasterTrack()
        succ = reaper.GetSetMediaTrackInfo_String(master_track, "P_EXT:MACCLANE", json, true)
    elseif etype == "track" then
        succ = reaper.GetSetMediaTrackInfo_String(entity, "P_EXT:MACCLANE", json, true)
    else
        succ = reaper.GetSetMediaItemInfo_String(entity, "P_EXT:MACCLANE", json, true)
    end

    return {success=true, errors={}}
end

Serializing.loadTabTemplate = function(templatePath)
    local file = io.open(templatePath, "rb")
    local ret  = {}

    if not file then
        return ret
    end

    local json = file:read("*all")
    file:close()

    if not json then
        return ret
    end

    local succ, err = pcall(function()
        -- Bypass exceptions. Return nil if failing.
        ret = JSON.decode(json)
    end)

    return ret
end

function Serializing.serializeTabForTemplate(tab)
    return JSON.encode({
        owner_type = tab.owner_type,
        params     = tab.params
    })
end


function Serializing.createTabFromTemplate(mec, templatePath)
    local json        = Serializing.loadTabTemplate(templatePath)

    if not json or not json.params then
        reaper.MB("Failed to load template. Wrong format ?", "Oops.", 0)
        return nil
    end


    -- Set owner dependning on the clue saved in the template
    local owner = nil
    local take  = reaper.MIDIEditor_GetTake(mec.me)
    local item  = nil
    local track = nil

    if take then
        track = reaper.GetMediaItemTake_Track(take)
        item  = reaper.GetMediaItemTake_Item(take)
    end

    if json.owner_type == nil then
        owner = nil
    elseif json.owner_type == Tab.Types.TRACK then
        owner = track
    elseif json.owner_type == Tab.Types.ITEM then
        owner = item
    end

    local tab = Tab:new(owner, json.params)

    return tab
end


return Serializing

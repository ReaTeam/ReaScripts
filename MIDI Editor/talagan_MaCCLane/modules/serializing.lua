-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local Tab               = require "classes/tab"
local GlobalScopeRepo   = require "classes/global_scope_repo"
local JSON              = require "lib/json"

Serializing = {}

-- Load tabs contained in entity
Serializing.loadTabsFromEntity = function(mec, etype, entity)
    local succ, v = false, ''

    if not entity and not (etype == Tab.Types.PROJECT) then
        return {}
    end

    if etype == Tab.Types.GLOBAL then
        succ, v = true, GlobalScopeRepo.instance():getContent()
    elseif etype == Tab.Types.PROJECT then
        -- Allow to pass nil
        local master_track = reaper.GetMasterTrack()
        succ, v = reaper.GetSetMediaTrackInfo_String(master_track, "P_EXT:MACCLANE", '', false)
    elseif etype == Tab.Types.TRACK then
        succ, v = reaper.GetSetMediaTrackInfo_String(entity, "P_EXT:MACCLANE", '', false)
    elseif etype == Tab.Types.ITEM then
        succ, v = reaper.GetSetMediaItemInfo_String(entity, "P_EXT:MACCLANE", '', false)
    else
        succ, v = false, ''
    end

    local json_tabs = {}
    if succ then
        pcall(function()
            json_tabs = JSON.decode(v)
        end)
    end

    local tabs = {}
    for uuid, json_tab in pairs(json_tabs) do

        local params = {}
        local state  = nil
        if json_tab.version == 1 then
            -- New format. We save the params and the state, so that when reloading the project it works.
            params = json_tab.params
            state  = json_tab.state
        else
            -- Old format, the full json for this tab was the params (the state was not there at all)
            params = json_tab
        end

        local tab   = Tab:new(mec, entity, params, state)
        -- Use saved uuid
        tab.uuid        = uuid
        tab.new_record  = false

        tabs[tab:UUID()] = tab
    end

    return tabs
end

Serializing.saveTabsToEntitity = function(etype, entity, tabs, with_undo)
    local succ, v = false, ''

    if not entity and not (etype == Tab.Types.PROJECT) then
        return { success=false, errors={ 'No entity given !'} }
    end

    local tab_params_array = {}
    for uuid, t in pairs(tabs) do
        tab_params_array[uuid] = { version=1, params=t.params, state=t.state }
    end

    local json = JSON.encode(tab_params_array)

    if with_undo then
        reaper.Undo_BeginBlock()
    end

    local master_track = reaper.GetMasterTrack()
    if etype == Tab.Types.GLOBAL then
        GlobalScopeRepo.instance():setContent(json)
    elseif etype == Tab.Types.PROJECT then
        -- Allow to pass nil
        succ = reaper.GetSetMediaTrackInfo_String(master_track, "P_EXT:MACCLANE", json, true)
    elseif etype == Tab.Types.TRACK then
        succ = reaper.GetSetMediaTrackInfo_String(entity, "P_EXT:MACCLANE", json, true)
    elseif etype == Tab.Types.ITEM then
        succ = reaper.GetSetMediaItemInfo_String(entity, "P_EXT:MACCLANE", json, true)
    else
        succ = false
    end

    if with_undo then
        if with_undo == true then with_undo = "saved tabs" end
        -- Set UNDO flag on the master track, so we can track undo/redo operaqtions and refresh mecs
        reaper.GetSetMediaTrackInfo_String(master_track, "P_EXT:MACCLANE_UNDO" , "" .. reaper.time_precise(), true)
        reaper.Undo_EndBlock("MaCCLane : " .. with_undo, 0xFFFFFFFF)
    end

    return {success=true, errors={}}
end

Serializing.loadTabTemplate = function(templatePath)
    local file = io.open(templatePath, "rb")

    if not file then
        return false, {}
    end

    local json = file:read("*all")
    file:close()

    if not json then
        return false, {}
    end

    local ret = {}
    local succ, err = pcall(function()
        -- Bypass exceptions. Return nil if failing.
        ret = JSON.decode(json)
    end)

    if not ret then return false, {} end

    if ret.params then
        -- Old version with one tab
        ret = { version = "0", tabs = { ret } }
    end

    if not ret.version or (ret.version ~= "0" and ret.version ~= "1") or not ret.tabs then
        return false, {}
    end

    return true, ret
end

function Serializing.tabToSer(tab)
    return {
        owner_type = tab.owner_type,
        params     = tab.params
    }
end

function Serializing.serializeTabForTemplate(tab)
    return JSON.encode({
        version     = "1",
        tabs        = { Serializing.tabToSer(tab) }
    })
end

function Serializing.serializeTabsForTemplate(tabs)
    local to_exp = {}

    for _, t in ipairs(tabs) do
        to_exp[#to_exp+1] = Serializing.tabToSer(t)
    end

    return JSON.encode({
        version     = "1",
        tabs        = to_exp
    })
end


function Serializing.createTabsFromTemplate(mec, templatePath)
    local valid, json = Serializing.loadTabTemplate(templatePath)

    if not valid then
        reaper.MB("Failed to load template. Wrong format ?", "Oops.", 0)
        return nil
    end

    local tabs        = {}

    for _, tjson in ipairs(json.tabs) do
        -- Set owner dependning on the clue saved in the template
        local owner = nil
        local take  = reaper.MIDIEditor_GetTake(mec.me)
        local item  = nil
        local track = nil

        if take then
            track = reaper.GetMediaItemTake_Track(take)
            item  = reaper.GetMediaItemTake_Item(take)
        end

        if (tjson.owner_type) == nil or (tjson.owner_type == Tab.Types.PROJECT) then
            owner = nil
        elseif tjson.owner_type == Tab.Types.GLOBAL then
            owner = GlobalScopeRepo.instance()
        elseif tjson.owner_type == Tab.Types.TRACK then
            owner = track
        elseif tjson.owner_type == Tab.Types.ITEM then
            owner = item
        end

        local tab = Tab:new(mec, owner, tjson.params, nil)

        tabs[#tabs+1] = tab
    end

    return tabs
end

return Serializing

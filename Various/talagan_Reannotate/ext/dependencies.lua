-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local function CheckReapack(type, arg, api_name, search_string)

    local ok = true
    if type == "API" then
        if not reaper.APIExists(arg) then
            ok = false
        end
    elseif type == "script" then
        ok, _ = pcall(require, arg)
    end

    if not ok then
        reaper.MB( api_name .. " is required and you need to install it.\n\n\z
            Right-click the entry in the next window and choose to install.",
        api_name .. " not installed",
        0 )

        -- Open reapack's package window
        reaper.ReaPack_BrowsePackages( search_string )
        return false
    end

    return true
end

local function checkDependencies()
    if not CheckReapack("API",    "JS_ReaScriptAPI_Version",    "JS_ReaScriptAPI",   "js_ReaScriptAPI")      then return false end
    if not CheckReapack("API",    "ImGui_CreateContext",        "ReaImGUI",          "ReaImGui:")            then return false end
    if not CheckReapack("API",    "CF_ShellExecute",            "SWS",               "SWS/S&M Extension")    then return false end
    if not CheckReapack("script", reaper.GetResourcePath() .. "/Scripts/ReaTeam Scripts/Development/talagan_ReaImGui Markdown/reaimgui_markdown", "ReaImGui Markdown", "ReaImGui Markdown") then return false end

    return true
end

return {
    checkDependencies   = checkDependencies
}


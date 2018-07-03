--[[
Description: Toggle take FX envelope visibility for all selected items
Version: 1.02
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
    Initial release
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
Provides:
    [main] .
    [main] . > Lokasenna_Show all take FX envelopes for selected items.lua
    [main] . > Lokasenna_Hide all take FX envelopes for selected items.lua
About:
    Provides actions for managing large numbers of take FX envelopes. Toggle,
    Show, and Hide actions are installed.
--]]


-- Licensed under the GNU GPL v3

local script_name = ({reaper.get_action_context()})[2]:match("([^/\\]+)$")
script_name = string.match(script_name, "Lokasenna_(.*)%.lua")

local function Msg(str)
    reaper.ShowConsoleMsg(tostring(str) .. "\n")
end


local function get_state_from_fn()
    
    return string.match(script_name, "(%a+)%s")
    
end

local states = {
    Show = function() return true end,
    Hide = function() return false end,
    Toggle = function(state) return not state end,
}

local function get_new_state(state)
    
    local new = get_state_from_fn()
    if not new and not abort then
        reaper.MB("Error reading script filename. Please make sure it has *not* been changed.", "Whoops!", 0)
        abort = true
        return
    end

    return states[get_state_from_fn()](state)
    
end

local function toggle_env_visibility(take, fx, param)
    
    local env = reaper.TakeFX_GetEnvelope(take, fx, param, false)
    if not env then return end
    
    local env = reaper.BR_EnvAlloc(env, false)
    
    --active, visible, armed, inLane, laneHeight, defaultShape, minValue, maxValue, centerValue, type, faderScaling = reaper.BR_EnvGetProperties( envelope )
    local props = {reaper.BR_EnvGetProperties(env)}
    local new = get_new_state(props[2])
    
    if new ~= props[2] then
        reaper.BR_EnvSetProperties( env, props[1], new, props[3], props[4], props[5], props[6], props[11] )
    end

    local ret = reaper.BR_EnvFree(env, true)
    
end


local function iterate_FX_params(take, fx)

    local num_params = reaper.TakeFX_GetNumParams(take, fx)
    
    for i = 0, num_params - 1 do
        
        toggle_env_visibility(take, fx, i)        
        
    end    
    
end

local function iterate_take_FX(take)
    
    local num_FX = reaper.TakeFX_GetCount(take)
    if num_FX == 0 then return end
    
    for i = 0, num_FX - 1 do
        
        iterate_FX_params(take, i)
        
    end    
    
end

local function iterate_items()

    -- Get sel. item count
    local num_items = reaper.CountSelectedMediaItems()
    if num_items == 0 then return end

    -- For each sel. item
    for i = 0, num_items - 1 do
        
        local item = reaper.GetSelectedMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        
        iterate_take_FX(take)

    end        
    
end

local function Main()
    
    if not reaper.BR_EnvAlloc then
        reaper.MB("This script requires the SWS extension for Reaper.", "Whoops!", 0)
        return
    end
    
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    
    iterate_items()
    
    reaper.PreventUIRefresh(-1)
    reaper.UpdateTimeline()
    reaper.Undo_EndBlock(script_name, -1)
    
end

Main()
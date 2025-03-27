-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Legatool

-- Functions and defines
local S                   = require "modules/settings"
local UTILS               = require "modules/utils"
local LTContext           = require "modules/context"
local SNAP                = require "modules/snap"

local ImGui               = require "ext/imgui"
local ctx                 = nil

LTContext.snap_piano_roll = S.getSetting("PinToMidiEditor")
_,_,LTContext.sectionID, LTContext.cmdID,_,_,_ = reaper.get_action_context()

-----------------------

local function needsImGuiContext()
    return #LTContext.notes == 2
end

local function app()

    -- Watch tool status
    local current_state = reaper.GetToggleCommandStateEx(LTContext.sectionID, LTContext.cmdID)
    if current_state == 0 then
        LTContext.shouldQuit = true
        return
    end

    local me = reaper.MIDIEditor_GetActive()
    if not me then ctx = nil ; return end

    local take = reaper.MIDIEditor_GetTake(me)
    if not take then ctx = nil; return end

    local item = reaper.GetMediaItemTake_Item(take)
    local track = reaper.GetMediaItemTake_Track(take)

    LTContext.take = take

    local _, th = reaper.MIDI_GetHash(take, true)
    if th ~= LTContext.last_hash then
        LTContext.last_hash = th

        local ni = 0
        local notes = {}
        while true do
            local b, sel, _, startppq, endppq, _, _, _ = reaper.MIDI_GetNote(take, ni)

            if not b then break end

            if sel then
                notes[#notes+1] = {
                    ni        = ni,
                    startppq  = startppq,
                    endppq    = endppq
                }
            end

            ni = ni + 1
        end

        LTContext.notes = notes
    end

    if needsImGuiContext() then

        if not ctx then
            ctx = ImGui.CreateContext("Legatool", ImGui.ConfigFlags_NoKeyboard)
        end

        ImGui.SetNextWindowSizeConstraints(ctx,200,35,2000,35)

        local flags = ImGui.WindowFlags_NoDocking | ImGui.WindowFlags_NoTitleBar
        local dock  = UTILS.GetHwndDock(me)

        if not dock then
            -- Hack if windowed. Could not find a better way to ensure that the z-index of legatool is higher than the ME's one... :( :(
            -- We need to bring the window front by setting it topmost, but not always (we don't want it to be in front of other contextual windows for example)
            -- ImGui.SetNextWindowFocus is not sufficient, it does not work here
            local focused = reaper.JS_Window_GetFocus()
            if me == focused  or reaper.JS_Window_IsChild(me, focused) then
                flags = flags|ImGui.WindowFlags_TopMost
            end
        end

        if LTContext.snap_piano_roll then
            local piano_roll_hwnd   = reaper.JS_Window_FindChildByID(me, 1001)
            local pr_bounds         = UTILS.JS_Window_GetBounds(piano_roll_hwnd, true)
            local x,y = ImGui.PointConvertNative(ctx, pr_bounds.l, pr_bounds.t)
            ImGui.SetNextWindowSize(ctx, pr_bounds.w, 35)
            ImGui.SetNextWindowPos(ctx, x, y-2)
            flags = flags | ImGui.WindowFlags_NoResize
        end

        local visible, open = ImGui.Begin(ctx, "Legatool", true, flags)
        if visible then
            -- The next part is mandatory when using Legatool and editing stuff
            -- Because Legatool's window will take focus on mouse click and we want to give
            -- It back to the ME so that we can press "space"/play or any other editing shortcut
            -- and be sure it is interpreted by the ME
            if ImGui.IsWindowFocused(ctx) then
                if not LTContext.focustimer or ImGui.IsAnyMouseDown(ctx) then
                    -- create or reset the timer when there's activity in the window
                    LTContext.focustimer = reaper.time_precise()
                end

                if (reaper.time_precise() - LTContext.focustimer > 0.1) then
                    -- Give back focus to MIDI editor as soon as we have finished
                    -- So that the ME can have kb focus
                    reaper.JS_Window_SetFocus(reaper.MIDIEditor_GetActive())
                end
            else
                LTContext.focustimer = nil
            end

            local act_col = LTContext.snap_piano_roll

            if act_col then
                ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0x0091fbff)
            end

            if ImGui.Button(ctx, "P") then
                if (LTContext.snap_piano_roll == true) then
                    LTContext.snap_piano_roll = false
                else
                    LTContext.snap_piano_roll = true
                end
                S.setSetting("PinToMidiEditor", LTContext.snap_piano_roll)
            end

            if act_col then ImGui.PopStyleColor(ctx) end

            if ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_DelayNormal) then
                ImGui.SetTooltip(ctx, "Pin to the top of the MIDI Editor")
            end

            ImGui.SameLine(ctx)

            local w, _ = ImGui.GetContentRegionAvail(ctx)
            ImGui.SetNextItemWidth(ctx, w - 70)

            local n1, n2            = LTContext.notes[1], LTContext.notes[2]
            local s                 = reaper.MIDI_GetProjTimeFromPPQPos(take, n1.startppq)
            local e                 = reaper.MIDI_GetProjTimeFromPPQPos(take, n2.endppq)
            local vs                = reaper.MIDI_GetProjTimeFromPPQPos(take, n1.endppq)
            local ve                = reaper.MIDI_GetProjTimeFromPPQPos(take, n2.startppq)
            local p                 = (vs+ve) * 0.5
            local lowbound          = s + 0.00001
            local highbound         = e - 0.00001
            local lowbound_ppq      = reaper.MIDI_GetPPQPosFromProjTime(take, lowbound)
            local highbound_ppq     = reaper.MIDI_GetPPQPosFromProjTime(take, highbound)

            local str     = ''

            local snap_key_down = ((reaper.JS_Mouse_GetState(8)) ~= 0)

            if snap_key_down and LTContext.snap_info and LTContext.snap_info.best then
                local sf       = LTContext.snap_info.best
                local tstr     = reaper.format_timestr_pos(sf.pos, '', 0)
                local bstr     = reaper.format_timestr_pos(sf.pos, '', 2)

                str = "[SNAP] " .. sf.label .. " : " .. bstr .. " / " .. tstr
            else
                local tstr     = reaper.format_timestr_pos(p, '', 0)
                local bstr     = reaper.format_timestr_pos(p, '', 2)

                str  =  "Mid : " .. bstr .. " / " .. tstr
            end

            local b, v          = ImGui.SliderDouble(ctx, " Legatool##slider", p, lowbound, highbound, str)
            if b then
                if not LTContext.startState then
                    -- Start of operation : save current state for referrence
                    LTContext.startState = { notes = UTILS.deepcopy(LTContext.notes), v = p }

                    -- Calculate starting intervals
                    local l = n1.endppq
                    local r = n2.startppq
                    local m = 0.5 * (l + r)

                    LTContext.startState.ldiff_ppq = m - l
                    LTContext.startState.rdiff_ppq = m - r
                    LTContext.startState.ppq_span  = r - l

                    reaper.MIDI_DisableSort(take)
                end

                -- Handle drag and drop
                local n1, n2    = LTContext.notes[1], LTContext.notes[2]
                local vppq      = reaper.MIDI_GetPPQPosFromProjTime(take, v)
                local lppq      = vppq - LTContext.startState.ldiff_ppq
                local rppq      = vppq - LTContext.startState.rdiff_ppq

                if snap_key_down then
                    local cd        = {}
                    -- Calculate the direction in which the user is moving the slider
                    local last_v    = (LTContext.snap_info and LTContext.snap_info.last_v) or LTContext.startState.v
                    local sign      = 0

                    if ( v - last_v > 0 ) then sign = 1  end -- Moving right
                    if ( v - last_v < 0 ) then sign = -1 end -- Moving left

                    local function addCandidate(type, val, dir)
                        local pos  = SNAP.nextSnap(take, dir, val)
                        local diff = pos.time - val

                        if pos.time < lowbound   then return end
                        if pos.time > highbound  then return end

                        if sign * diff <= 0 then return end

                        local label = "Mid"
                        if type == "l" then label = "Left End" end
                        if type == "r" then label = "Right Start end" end

                        local ll, mm, rr    = pos.ppq, pos.ppq, pos.ppq
                        local half_span_ppq = 0.5 * LTContext.startState.ppq_span

                        if type == "l" then mm = ll + half_span_ppq; rr = mm + half_span_ppq end
                        if type == "m" then ll = mm - half_span_ppq; rr = mm + half_span_ppq end
                        if type == "r" then mm = rr - half_span_ppq; ll = mm - half_span_ppq end

                        if ll < lowbound_ppq  then return end
                        if rr > highbound_ppq then return end

                        cd[#cd+1] = { type=type, label=label, dir=dir, pos=pos.time, diff=diff, l = ll, m = mm, r = rr }
                    end

                    local l = reaper.MIDI_GetProjTimeFromPPQPos(take, lppq)
                    local r = reaper.MIDI_GetProjTimeFromPPQPos(take, rppq)

                    addCandidate("m", v,  1)
                    addCandidate("l", l,  1)
                    addCandidate("r", r,  1)
                    addCandidate("m", v, -1)
                    addCandidate("l", l, -1)
                    addCandidate("r", r, -1)

                    table.sort(cd, function(c1,c2) return math.abs(c1.diff) < math.abs(c2.diff) end)

                    LTContext.snap_info             = LTContext.snap_info or {}
                    LTContext.snap_info.last_v      = v
                    LTContext.snap_info.last_sign   = sign

                    local best_candidate        = cd[1]
                    if best_candidate then
                        -- if sign == 0 we may not have a best_candidate
                        LTContext.snap_info.best = best_candidate
                    end
                else
                    LTContext.snap_info = nil
                end

                if LTContext.snap_info and LTContext.snap_info.best then
                    lppq = LTContext.snap_info.best.l
                    rppq = LTContext.snap_info.best.r
                end

                reaper.MIDI_SetNote(take, n1.ni, nil, nil, nil,  lppq, nil, nil, nil, true)
                reaper.MIDI_SetNote(take, n2.ni, nil, nil, rppq, nil,  nil, nil, nil, true)
            else
                if LTContext.startState then
                    LTContext.startState = nil
                    reaper.Undo_BeginBlock()
                    reaper.MIDI_Sort(take)
                    reaper.UpdateItemInProject(item)
                    reaper.MarkTrackItemsDirty(track, item)
                    reaper.Undo_EndBlock("Legatool - Adjusted two notes", -1)
                end
            end

            ImGui.End(ctx)
        end

        if not open then
            LTContext.shouldQuit = true
        end

    else
        ctx = nil
    end
end

local function _app()

    -- Performances on my imac when idle, for reference
    --    Averages during one second (perf.sec1)
    --    - total_ms        : 4.5ms
    --    - usage_perc      : 0.45 % (same value *1000 (ms->s) /100 (perc) )
    --    - frames skipped  : 31/34
    --    - forced redraws  : 1-2 (redraw at low pace or when needed only)
    aaa_perf = UTILS.perf_ms(
        function()
            app()
        end
    )

    if not LTContext.shouldQuit then
        reaper.defer(_app)
    end
end

local function run(args)

    local current_state = reaper.GetToggleCommandStateEx(LTContext.sectionID, LTContext.cmdID)
    current_state = (current_state == 1) and (0) or (1)

    reaper.SetToggleCommandState(LTContext.sectionID, LTContext.cmdID, current_state)

    -- Define cleanup callbacks
    reaper.atexit(function()
        -- On exit, always clear the state
        reaper.SetToggleCommandState(LTContext.sectionID, LTContext.cmdID, 0)
    end)

    reaper.defer(_app)
end

return {
    run = run
}

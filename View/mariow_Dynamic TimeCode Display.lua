-- @description Dynamic TimeCode Display
-- @author mariow
-- @version 1.0
-- @provides . > Display TC.lua
-- @screenshot https://github.com/Maginch/Reaper_Scripts-Mariow/blob/2dfcf5e3d518938f7eb44a793583d09aeca91ccc/Interactive%20TC%20Display

-- Auteur : Mariow (co-auteur)

local ctx = reaper.ImGui_CreateContext('Affichage Timecode')
local font_regular = reaper.ImGui_CreateFont('Comic Sans MS', 16)
local font_large = reaper.ImGui_CreateFont('sans-serif', 22, reaper.ImGui_FontFlags_Bold())
reaper.ImGui_Attach(ctx, font_regular)
reaper.ImGui_Attach(ctx, font_large)

local function format_timecode_hhmmssff(time)
local fps = reaper.TimeMap_curFrameRate(0)
local hours = math.floor(time / 3600)
local minutes = math.floor((time % 3600) / 60)
local seconds = math.floor(time % 60)
local frames = math.floor((time - math.floor(time)) * fps + 0.5)
return string.format("%02d:%02d:%02d:%02d", hours, minutes, seconds, frames)
end

local function get_take_name(item)
local take = reaper.GetActiveTake(item)
if not take then return "(Sans take)" end
local _, name = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
name = name:match("(.+)%..-$") or name
return name
end

local function main()
local play_state = reaper.GetPlayState()
local is_recording = (play_state & 4) == 4
local bg_color = is_recording and 0xFF0000FF or 0x000000FF -- Rouge si recording, sinon noir

reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), bg_color)
local visible, open = reaper.ImGui_Begin(ctx, 'Affichage Timecode', true, reaper.ImGui_WindowFlags_AlwaysAutoResize())

if visible then
local item_count = reaper.CountSelectedMediaItems(0)
local start_ts, end_ts = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

if item_count > 0 then
reaper.ImGui_PushFont(ctx, font_regular)
for i = 0, item_count - 1 do
local item = reaper.GetSelectedMediaItem(0, i)
local name = get_take_name(item)
local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
local tc = format_timecode_hhmmssff(pos)
reaper.ImGui_TextColored(ctx, 0x00FF00FF, name .. " : " .. tc)
end
reaper.ImGui_PopFont(ctx)

elseif start_ts ~= end_ts then
local duration = end_ts - start_ts
local duration_str = format_timecode_hhmmssff(duration)
reaper.ImGui_PushFont(ctx, font_regular)
reaper.ImGui_TextColored(ctx, 0xFFFF00FF, "Durée Time Selection : " .. duration_str)
reaper.ImGui_PopFont(ctx)

else
local pos = (play_state & 1) == 1 and reaper.GetPlayPosition() or reaper.GetCursorPosition()
local label = is_recording and "REC" or ((play_state & 1) == 1 and "Play" or "Position")
local remaining = reaper.GetProjectLength(0) - pos
local pos_str = format_timecode_hhmmssff(pos)
local dur_str = format_timecode_hhmmssff(remaining)

reaper.ImGui_PushFont(ctx, font_large)
reaper.ImGui_TextColored(ctx, 0xFFFFFFFF, label .. " : " .. pos_str)
reaper.ImGui_TextColored(ctx, 0xFFFFFFFF, "Durée jusqu'à fin : " .. dur_str)
reaper.ImGui_PopFont(ctx)
end

reaper.ImGui_End(ctx)
end

reaper.ImGui_PopStyleColor(ctx)

if open then
reaper.defer(main)
else
reaper.ImGui_DestroyContext(ctx)
end
end

reaper.defer(main)

-- @description TimeShift as Protools
-- @author mariow
-- @version 1.0
-- @provides [nomain] .
-- @about
--   Enter a TimeValue in TC, Milliseconds or Sample
--   Then precisely Shift items or Timeselection or CursorBefore or After


-- ReaImGui : Convertisseur temporel (samples -> hh:mm:ss:ff)
local ctx = reaper.ImGui_CreateContext('Convertisseur temporel')

local project_sr = reaper.GetSetProjectInfo(0, 'PROJECT_SRATE', 0, false)
local fps = 25 -- Framerate pour le timecode

-- Fonction de formatage personnalisé du timecode
local function format_timecode(samples, sample_rate, fps)
local total_seconds = samples / sample_rate
local hours = math.floor(total_seconds / 3600)
local minutes = math.floor((total_seconds % 3600) / 60)
local seconds = math.floor(total_seconds % 60)
local frames = math.floor((total_seconds - math.floor(total_seconds)) * fps + 0.5)

return string.format("%02d:%02d:%02d:%02d", hours, minutes, seconds, frames)
end

-- Valeur centrale
local sample_pos = math.floor(project_sr) -- 1 seconde par défaut

-- Champs d'affichage
local timecode_str = { format_timecode(sample_pos, project_sr, fps) }
local milliseconds_val = { math.floor((sample_pos / project_sr) * 1000 + 0.5) }
local samples_val = { sample_pos }

local direction = "En Avant"
local cible = "Item"

-- Conversion inverse : timecode -> samples
local function parse_timecode_to_samples(tc)
local h, m, s, f = tc:match("(%d+):(%d+):(%d+):(%d+)")
if h and m and s and f then
local total_seconds = tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) + tonumber(f) / fps
return math.floor(total_seconds * project_sr + 0.5)
else
return nil
end
end

-- Mise à jour des champs d'affichage depuis la valeur centrale (samples)
local function updateFieldsFromSamples()
local sec = sample_pos / project_sr
timecode_str[1] = format_timecode(sample_pos, project_sr, fps)
milliseconds_val[1] = math.floor(sec * 1000 + 0.5)
samples_val[1] = sample_pos
end

-- Appliquer le déplacement
local function appliquer_deplacement()
local delta_sec = sample_pos / project_sr
if direction == "En Arrière" then delta_sec = -delta_sec end

reaper.Undo_BeginBlock()

if cible == "Item" then
for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
local item = reaper.GetSelectedMediaItem(0, i)
if item then
local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
reaper.SetMediaItemInfo_Value(item, "D_POSITION", pos + delta_sec)
end
end

elseif cible == "Time Selection" then
local start_time, end_time = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
if end_time > start_time then
reaper.GetSet_LoopTimeRange(true, false, start_time + delta_sec, end_time + delta_sec, false)
else
reaper.ShowMessageBox("Aucune time selection active", "Erreur", 0)
end

elseif cible == "CursorPos" then
local cur_pos = reaper.GetCursorPosition()
reaper.SetEditCurPos(cur_pos + delta_sec, true, false)
end

reaper.Undo_EndBlock("Déplacement temporel", -1)
reaper.UpdateArrange()
end

-- Boucle ImGui
local function loop()
local visible, open = reaper.ImGui_Begin(ctx, 'Convertisseur temporel (samples)', true, reaper.ImGui_WindowFlags_AlwaysAutoResize())

if visible then
-- Timecode
local changed_tc, new_tc = reaper.ImGui_InputText(ctx, 'Timecode (hh:mm:ss:ff)', timecode_str[1], 256)
if changed_tc then
local s = parse_timecode_to_samples(new_tc)
if s then
sample_pos = s
updateFieldsFromSamples()
end
end

-- Millisecondes
local changed_ms, new_ms = reaper.ImGui_InputInt(ctx, 'Millisecondes', milliseconds_val[1])
if changed_ms then
sample_pos = math.floor((new_ms / 1000) * project_sr + 0.5)
updateFieldsFromSamples()
end

-- Samples
local changed_samples, new_samples = reaper.ImGui_InputInt(ctx, 'Samples', samples_val[1])
if changed_samples then
sample_pos = new_samples
updateFieldsFromSamples()
end

-- Options
reaper.ImGui_Separator(ctx)
reaper.ImGui_Text(ctx, "Déplacement")

if reaper.ImGui_RadioButton(ctx, 'En Avant', direction == "En Avant") then direction = "En Avant" end
reaper.ImGui_SameLine(ctx)
if reaper.ImGui_RadioButton(ctx, 'En Arrière', direction == "En Arrière") then direction = "En Arrière" end

if reaper.ImGui_RadioButton(ctx, 'Item sélectionné', cible == "Item") then cible = "Item" end
reaper.ImGui_SameLine(ctx)
if reaper.ImGui_RadioButton(ctx, 'Time Selection', cible == "Time Selection") then cible = "Time Selection" end
reaper.ImGui_SameLine(ctx)
if reaper.ImGui_RadioButton(ctx, 'CursorPos', cible == "CursorPos") then cible = "CursorPos" end

reaper.ImGui_Separator(ctx)
if reaper.ImGui_Button(ctx, 'Appliquer le déplacement', -1) then
appliquer_deplacement()
end

reaper.ImGui_End(ctx)
end

if open then
reaper.defer(loop)
else
if reaper.ImGui_DestroyContext then
reaper.ImGui_DestroyContext(ctx)
end
end
end

reaper.defer(loop)

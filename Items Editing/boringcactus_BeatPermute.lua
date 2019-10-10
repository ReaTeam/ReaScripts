-- @description Beat Permute (swap/delete/duplicate)
-- @author Melody Horn
-- @version 1.0
-- @link Tutorial video https://youtu.be/qEfYe5BUm6w
-- @about
--   # Beat Permute
--
--   You know those YouTube videos that are like "\<this song\> except beats 2 and 4 are swapped" 
--   or "\<this song\> but every other beat is missing" or whatever?
--   This script lets you make those really easily once you've got a song imported and correctly aligned to your project's BPM.
--   If you can turn on the metronome and have it line up *perfectly* with the song, then you should be good.

function script () -- indentation is a fuck
project = reaper.EnumProjects(-1, "")

if reaper.CountSelectedMediaItems(project) ~= 1 then
  reaper.ShowMessageBox("Please select the original audio to permute, and nothing else.", "Error", 0)
  return
end

markers = reaper.CountTempoTimeSigMarkers(project)
if markers ~= 0 then
  reaper.ReaScriptError("Probably can't currently handle variable tempo / time signature")
  return
end
length = reaper.GetProjectLength(project)
_, num_measures, beats_per_measure = reaper.TimeMap2_timeToBeats(project, length)
num_measures = num_measures + 1

local template = "1"
for i = 2, beats_per_measure do
  template = string.format('%s,%d', template, i)
end
reaper.ShowMessageBox(string.format("For the original song, enter \"%s\" on the next screen, and to swap some beats, swap those numbers.", template), "Pattern Help", 0)
valid, pattern = reaper.GetUserInputs("Beat Permute", 1, "Pattern", "")

if not valid then return end

desired_beats = {}
for i in pattern:gmatch("%d+") do
  desired_beat = tonumber(i)
  if desired_beat > beats_per_measure then
    reaper.ShowMessageBox(string.format("Can't use beat %d with current time signature", desired_beat), "Pattern Error", 0)
    return
  else
    table.insert(desired_beats, tonumber(i))
  end
end

reaper.Undo_BeginBlock()

local media = reaper.GetSelectedMediaItem(project, 0)
  
-- set up the permuted track
reaper.InsertTrackAtIndex(1, true)
local dest_track = reaper.GetTrack(project, 1)
reaper.GetSetMediaTrackInfo_String(dest_track, "P_NAME", "Permuted Version", true)
reaper.SetMediaTrackInfo_Value(dest_track, "I_SOLO", 1)

-- clear media selection
reaper.SelectAllMediaItems(project, false)

-- do the processing
next_global_beat = 1
for measure = 1, num_measures do
  local this_measure = {}
  for beat = 2, beats_per_measure + 1 do
    local target = string.format('%d.%d', measure, beat)
    local pos = reaper.parse_timestr_pos(target, 2)
    this_measure[beat - 1] = media
    local new_media = reaper.SplitMediaItem(media, pos)
    if new_media ~= nil then
      media = new_media
    end
  end
  for idx, target_beat in ipairs(desired_beats) do
    local target = string.format('1.%d', next_global_beat)
    local pos = reaper.parse_timestr_pos(target, 2)
    reaper.SetMediaItemSelected(this_measure[target_beat], true)
    -- "duplicate items" action
    reaper.Main_OnCommand(41295, 0)
    -- this ends with the new item selected, which works out alright
    local beat = reaper.GetSelectedMediaItem(project, 0)
    reaper.SetMediaItemSelected(beat, false)
    reaper.MoveMediaItemToTrack(beat, dest_track)
    reaper.SetMediaItemPosition(beat, pos, false)
    next_global_beat = next_global_beat + 1
  end
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("beat permute", -1)
end

script()

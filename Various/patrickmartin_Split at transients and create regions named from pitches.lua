-- @description Split at transients and create regions named from pitches
-- @author Patrick Martin
-- @version 1.0beta
-- @changelog Initial
-- @link Forum thread https://forum.cockos.com/showthread.php?p=2149215
-- @screenshot
--   Before https://i.imgur.com/YDCV27K.png
--   After https://i.imgur.com/t60lGmm.png
-- @about
--   ## Split at transients and create regions named from pitches
--
--   ### Overview
--   I created this script to assist me in chopping and exporting samples of pitched instruments for importing into Kontakt or hardware sampler synths.
--
--   In a nutshell, you can record a bunch of notes from your source into one, long audio file and this script will split the recording at the transients.
--
--   Next, it will shorten each part by the amount you specify, and apply a logarithmic fade-out to each part of the duration you specify.
--
--   But wait, there's more: it will then bounce each audio part to a MIDI take at high-speed and "de-noise" the resulting MIDI part by deleting any notes that are shorter than the duration you specify. This prepares the groundwork for the next processing phase...
--
--   ...wherein a region is created for each note part, with the region name consisting of the note name and an ordinal number. For example, if you recorded three C#'s in the 2nd octave and an F# in the 3rd octave, the regions would be named **C#2_1**, **C#2_2**, **C#2_3** and **F#3_1**.
--
--   Finally, it will automatically enable these regions in the Render Matrix for the parent track.
--
--   All of these actions are encapsulated in a single undo point so that you can easily try different settings until you achieve the desired results.
--
--   At this point, you can go into the Region Render Matrix and render out your individual sample files, all named according to pitch.
--
--
--   ### Dependencies
--   [SWS Extension](http://sws-extension.org/) (used for splitting at transients)
--
--   ### Setup
--   1. **Required:** Ensure you have a saved ReaTune preset with the **Send MIDI events when pitch changes** box checked. Leave all the other options in ReaTune at their default values. (This step will be required until such time as the API allows ReaTune parameters to be set at run-time).
--   2. **Recommended**: Create a Render Matrix preset to name your rendered files using wild cards, for example: $project\\$track\\$region
--
--   ### Configuration
--   You can change the values of the following constants in the USER CONFIG AREA section of the script to achieve optimum results:
--
--   ```
--   uc_reatune_midi_out_preset_name = "NoCorrection_OutputPitchMIDI"
--   uc_autofade_seconds = 1
--   uc_trim_end_seconds = 1
--   uc_note_min_seconds = 1
--   ```
--   ### Instructions
--   1. Ensure **Setup** is complete
--   2. Drag your audio file into Arrange Window to create a track
--   3. Select the audio item
--   4. Run the script
--   5. Go to **View/Region Render Matrix**
--   6. Click **Render**
--   7. Select your render preset or enter desired settings
--   8. Click **Render xx files..** button

-- API CONSTANTS ------------------------------------------------------------

c_msgbox_type_ok = 0
c_action_item_unselect_all_items = 40289
c_action_select_all = 40035
c_action_select_all_track_items = 40421
c_action_markers_insert_sep_regions = 41664
c_fx_instantiate_if_none = 1
c_action_transport_goto_project_start = 40042
c_action_item_apply_fx_midi = 40436
c_action_render_matrix_selected_track_all_regions = 41892
c_render_region_add = 1
c_render_region_remove = -1

-------------------------------------------------------- END OF API CONSTANTS

-- GLOBAL VARIABLES ---------------------------------------------------------

gv_note_name_counts = {}
gc_script_display_name = "Split at transients and create regions named from pitches"
----------------------------------------------------- END OF GLOBAL VARIABLES

-- USER CONFIG AREA ---------------------------------------------------------

console = false -- true/false: display debug messages in the console

uc_reatune_midi_out_preset_name = "NoCorrection_OutputPitchMIDI" --name of ReaTune preset with MIDI output on pitch change enabled (REQUIRED)
uc_autofade_seconds = 1 --duration for split part fade-outs
uc_trim_end_seconds = 1 --duration to trim from ends of split parts
uc_note_min_seconds = 1 --minimum duration for a note to be considered valid

----------------------------------------------------- END OF USER CONFIG AREA
-- Display a message in the console for debugging
function Msg(value)
  if console then
    reaper.ShowConsoleMsg(tostring(value) .. "\n")
  end
end

function EnsureSelection()
  if reaper.CountSelectedMediaItems(0) == 0 then
    reaper.ShowMessageBox("No media item selected", gc_script_display_name, c_msgbox_type_ok)
    return false
  end
  return true
end

function AddReaTuneToItem(item, preset)
  local take = reaper.GetTake(item, 0)
  local fxid = reaper.TakeFX_AddByName(take, "ReaTune", c_fx_instantiate_if_none)

  --Select the MIDI output preset
  reaper.TakeFX_SetPreset(take, 0, preset)
end

function BounceToMIDITake(item)
  --select the media item
  reaper.SetMediaItemSelected(item,true)

  --Capture ReaTune MIDI output to new take
  reaper.Main_OnCommandEx(c_action_item_apply_fx_midi, 0, 0)

  local midi_take = reaper.GetTake(item, 1)

  --revert the active take to the audio take
  reaper.SetMediaItemInfo_Value(item, "I_CURTAKE", 0)

  return midi_take
end

function RunExtensionCommand(command_name)
  local id = reaper.NamedCommandLookup(command_name)
  reaper.Main_OnCommandEx(id, 0, 0)
end

function DeleteFirstItemOnTrack(track)
  Msg("Begin: DeleteFirstItemOnTrack")

  local first_item = reaper.GetTrackMediaItem(track, 0)
  if first_item then
    local pos = reaper.GetMediaItemInfo_Value(first_item, "D_POSITION")
    local count = reaper.GetTrackNumMediaItems(track)
    Msg("\tFound " .. count .. " items on track")
    Msg("\tFirst item is at pos " .. pos)
    reaper.DeleteTrackMediaItem(track, first_item)
  end
  Msg("End: DeleteFirstItemOnTrack")
end

function ShortenAllTrackItems(track, seconds)
  Msg("Begin: ShortenAllTrackItems(" .. seconds .. "s)")

  --Select the track
  reaper.SetTrackSelected(track, true)

  --Select all items on track
  reaper.Main_OnCommandEx(c_action_select_all_track_items, 0, 0)
  local count = reaper.CountSelectedMediaItems(0)

  --iterate each item
  for i = 0, count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    --Get current length
    local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    Msg("\tItem " .. i .. " before=" .. length .. " after=" .. length - seconds)
    --Set length to current - amount
    reaper.SetMediaItemLength(item, length - seconds, true)
  end
  Msg("End: ShortenAllTrackItems")
end

function FadeOutAllTrackItems(track, seconds)
  --Select track
  reaper.SetTrackSelected(track, true)

  --Select all items on track
  reaper.Main_OnCommandEx(c_action_select_all_track_items, 0, 0)
  local count = reaper.CountSelectedMediaItems(0)

  --iterate each item
  for i = 0, count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    --set fade out
    reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO", seconds)
  end
end

function CalculateNoteDurationInSeconds(bpm, ppqStart, ppqEnd, take)
  local start_seconds = reaper.MIDI_GetProjTimeFromPPQPos(take, ppqStart)
  local end_seconds = reaper.MIDI_GetProjTimeFromPPQPos( take, ppqEnd)
  local ret = end_seconds - start_seconds
  return ret
end

function GetNotePitchAtIndex(take, note_index)
  local retval
  local selected
  local muted
  local startppqpos
  local endppqpos
  local chan
  local pitch
  local vel
  --Get the note properties
  retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, note_index)

  return pitch
end

function GetIndexOfNextNoteShorterThan(bpm, min_length, take)
  --get event counts
  local retval
  local notecnt
  local ccevtcnt
  local textsyxevtcnt
  retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take)

  --For each note in the take
  for i = 0, notecnt - 1 do
    local retval
    local selected
    local muted
    local startppqpos
    local endppqpos
    local chan
    local pitch
    local vel
    --Get the note properties
    retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)

    --Calculate note duration from PPQs
    local len = CalculateNoteDurationInSeconds(bpm, startppqpos, endppqpos, take)

    if len < min_length then
      --return this index
      return i
    end
  end
  return -1
end

function DeleteNotesShorterThanValue(bpm, min_length, take)
  --get event counts
  local retval
  local notecnt
  local ccevtcnt
  local textsyxevtcnt
  retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take)

  --Delete undesired until none remain
  local deleted_count = 0
  local next_delete_index =  GetIndexOfNextNoteShorterThan(bpm, min_length, take)
  while next_delete_index > -1 do
    reaper.MIDI_DeleteNote(take, next_delete_index)
    deleted_count = deleted_count + 1
    next_delete_index =  GetIndexOfNextNoteShorterThan(bpm, min_length, take)
  end

  return deleted_count
end

function CleanMIDINotes(track, min_length)
  Msg("Begin: CleanMIDINotes")
  --Select track
  reaper.SetTrackSelected(track, true)

  --Select all items on track
  reaper.Main_OnCommandEx(c_action_select_all_track_items, 0, 0)
  local count = reaper.CountSelectedMediaItems(0)

  --Get project BPM for calculating note lengths
  local bpm = 0
  local bpi = 0
  bpm, bpi = reaper.GetProjectTimeSignature2(0)

  --iterate each item
  for i = 0, count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    --get the midi take for this item
    local take = reaper.GetTake(item, 1)
    --Delete qualifying notes
    local count = DeleteNotesShorterThanValue(bpm, min_length, take)
    Msg("\tItem " .. i .. ": " .. count .. " notes deleted")
  end
  Msg("End: CleanMIDINotes")
end

function GetItemStartEnd(item)
  local start = reaper.GetMediaItemInfo_Value( item, "D_POSITION")
  local length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH")
  return start, (start + length)
end

function CreatePitchNamedRegions(track)
  Msg("Begin: CreatePitchNamedRegions")

  local ret = {}

  --Select track
  reaper.SetTrackSelected(track, true)
  --select all splits on track
  reaper.Main_OnCommandEx(c_action_select_all_track_items, 0, 0)
  --Get split count
  local count = reaper.CountSelectedMediaItems(0)

  --iterate each item
  for i = 0, count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    --get midi take for this item
    local take = reaper.GetTake(item, 1)
    --Get pitch of first note in midi take
    local pitch = GetNotePitchAtIndex(take, 0)
    local note_name = GetNoteName(pitch)
    Msg("\tItem " .. i .. ": note#=" .. pitch .. ", name=" .. note_name)
    --Keep track of note names/counts for sequential naming of regions with same notes
    if gv_note_name_counts[note_name] then
      gv_note_name_counts[note_name] = gv_note_name_counts[note_name] + 1
    else
      gv_note_name_counts[note_name] = 1
    end

    --create a region named note_n, i.e. F#5_1, C#4_2
    local region_name = note_name .. "_" ..  gv_note_name_counts[note_name]
    local region_color = 0
    local region_start = 0
    local region_end = 0
    local wantidx = -1  --use next avail index
    local is_region = true
    region_start, region_end = GetItemStartEnd(item)

    --Create region and capture index for rendering
    ret[#ret + 1] = reaper.AddProjectMarker2(0, is_region, region_start, region_end, region_name, wantidx, region_color)
  end
  Msg("End: CreatePitchNamedRegions\n")

  return ret
end

function GetNoteName(noteNumber)
    local notes = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#","B"}
    local name = notes[(noteNumber % 12) + 1]
    local octave = math.floor(noteNumber / 12) - 1
    return name .. ("" .. octave)
end

function EnableRegionsForRender(track, indices)
  for k,v in pairs(indices) do
    reaper.SetRegionRenderMatrix(0, v, track, c_render_region_add)
  end
end

-- Main function
function main()
  if EnsureSelection() then
    --capture ref to original pre-split item
    local orig_item = reaper.GetSelectedMediaItem(0, 0)

    --capture ref to parent track
    local track = reaper.GetMediaItemInfo_Value(orig_item, "P_TRACK")

    --Add REATune plugin
    AddReaTuneToItem(orig_item, uc_reatune_midi_out_preset_name)

    --Render REATune MIDI output to new MIDI take
    BounceToMIDITake(orig_item)

    --Create splits at transients
    RunExtensionCommand("_XENAKIOS_SPLIT_ITEMSATRANSIENTS")

    --Delete first split
    DeleteFirstItemOnTrack(track)

    --Shorten all splits
    ShortenAllTrackItems(track, uc_trim_end_seconds)

    --Fade out all splits
    FadeOutAllTrackItems(track, uc_autofade_seconds)

    --Remove MIDI notes shorter than specified duration
    CleanMIDINotes(track, uc_note_min_seconds)

    --Create pitch_named regions
    local region_indices = CreatePitchNamedRegions(track)

    --Render region matrix to export samples
    EnableRegionsForRender(track, region_indices)
  end
end

-- INIT ---------------------------------------------------------------------

-- Here: your conditions to avoid triggering main without reason.

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main()

reaper.Undo_EndBlock(gc_script_display_name, -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)
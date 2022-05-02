-- @noindex

-- module requirements for all actions
-- doesn't provide any action by itself, so don't map any shortcut to it or run this action

-- fixing script path for correct require calls
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"

-- constants

local activeProjectIndex = 0

local function print(message)

  reaper.ShowConsoleMsg("IntelliFreeze: "..tostring(message).."\n")
end

local function speak(text)
  if reaper.osara_outputMessage ~= nil then
    reaper.osara_outputMessage(text)
  end
end

-- we retrieve all selected tracks recursively
-- all folders get resolved if param tracks is nil
-- recursiveness can be disabled too
local function getSelectedTracks(tracks, recursive)

  recursive = recursive or false

  if tracks == nil or tracks == {} then

    if reaper.CountSelectedTracks(activeProjectIndex) == 0 then
      return {}
    end

    tracks = {}

    local i

    for i = 0, reaper.CountSelectedTracks(activeProjectIndex) - 1 do

      table.insert(tracks, reaper.GetSelectedTrack(activeProjectIndex, i))

    end

  end

  if recursive == true then

    for _, track in ipairs(tracks) do

      local is_folder = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")

      if is_folder == 1 then

        -- the track is a folder
        -- in order to find the children tracks, we need to iterate over all existing tracks
        -- and check if the track is the child of this track
        local i
        local sub_tracks = {}
      
        for i = 0, reaper.CountTracks(activeProjectIndex) - 1 do

          local sub_track = reaper.GetTrack(activeProjectIndex, i)

          if sub_track ~= track and reaper.GetParentTrack(sub_track) == track then
              table.insert(sub_tracks, sub_track)
          end

        end

        if #sub_tracks > 0 then

          sub_tracks = getSelectedTracks(sub_tracks, true)
        
          for i = 1, #tracks do
            table.insert(sub_tracks, tracks[i])
          end

          tracks = sub_tracks

        end
      
      end

    end

  end

  return tracks
end

-- we consider a track with FX freezeable
local function getTrackRequiresFreezing(track)

  local fxCount = reaper.TrackFX_GetCount(track)

  return fxCount > 0
end

-- copied from https://stackoverflow.com/questions/49709998/how-to-filter-a-lua-array-inplace
local function filterArrayInplace(arr, func)
  local new_index = 1
  local size_orig = #arr
  for old_index, v in ipairs(arr) do
    if func(v, old_index) then
      arr[new_index] = v
      new_index = new_index + 1
    end
  end
  for i = new_index, size_orig do arr[i] = nil end
end

-- modes
-- mode 0 = mono
-- mode 1 = stereo
-- mode 2 = multi-channel
-- mode 3 = unfreeze
local function freezeTracks(tracks, mode)

  mode = mode or 0

  -- save currently selected tracks first
  local _, track
  local selected_tracks = getSelectedTracks()

  -- unselect those
  for _, track in ipairs(selected_tracks) do
    reaper.SetTrackSelected(track, false)
  end

  -- and select the tracks to be frozen
  for _, track in ipairs(tracks) do
    reaper.SetTrackSelected(track, true)
  end

  -- run the freeze command
  local command_id
  
  if mode == 0 then
    command_id = 40901
  elseif mode == 1 then
    command_id = 41223
  elseif mode == 2 then
    command_id = 40877
  else
    command_id = 41644
  end
  
  reaper.Main_OnCommand(command_id, 0)

  -- unselect and select the correct tracks again
  for _, track in ipairs(tracks) do
    reaper.SetTrackSelected(track, false)
  end

  for _, track in ipairs(selected_tracks) do
    reaper.SetTrackSelected(track, true)
  end
end

return {
  filterArrayInplace = filterArrayInplace,
  freezeTracks = freezeTracks,
  getSelectedTracks = getSelectedTracks,
  getTrackRequiresFreezing = getTrackRequiresFreezing,
  print = print,
  speak = speak
}

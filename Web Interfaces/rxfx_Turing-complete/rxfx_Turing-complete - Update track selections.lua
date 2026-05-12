-- @noindex
local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function UpdateSelectedTracks()
  local count = reaper.CountSelectedTracks(0)
  local finalstring = ""
  local trax = {}
  if count ~= 0 then
    for i=1, count do
      trax[i] = reaper.GetSelectedTrack(0, i-1)
    end
    local count2 = reaper.CountTracks(0)
    for i=1, count2 do
      if has_value(trax, reaper.GetTrack(0,i-1)) then
        finalstring = finalstring .. tostring(i) .. ","
      end
    end
    reaper.SetExtState("Fanciest","TrackSelections",finalstring,false)
  else
    reaper.SetExtState("Fanciest","TrackSelections","",false)
  end
end

UpdateSelectedTracks()

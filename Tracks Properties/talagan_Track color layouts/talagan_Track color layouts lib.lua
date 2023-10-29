--[[
@noindex
@author Talagan
@license MIT
@about
  This is the lib file for the Track Color Layout feature.
  See the companion action file for details.
--]]

_DEBUG=false
function DBG(txt)
  if _DEBUG then
    reaper.ShowConsoleMsg(txt);
  end
end

function getProjectCurrentLayoutNum()
  local mtrack    = reaper.GetMasterTrack();
  local succ, str = reaper.GetSetMediaTrackInfo_String(mtrack,
    "P_EXT:talagan_track_color_layout_current",
    '',
    false
  );

  if not succ or str == nil or str == '' then
    str = "1"
  end

  return tonumber(str);
end

function getTrackCurrentLayoutNum(track)
  local succ, str = reaper.GetSetMediaTrackInfo_String(track,
    "P_EXT:talagan_track_color_layout_current",
    '',
    false
  );

  -- If there's no info of the current track's layer
  -- It's probably a new track that has not yet been committed.
  -- Use the project's current layout then.

  if not succ or str == nil or str == '' then
    return getProjectCurrentLayoutNum();
  end

  return tonumber(str);
end

function setCurrentLayoutNum(layout)
  local mtrack    = reaper.GetMasterTrack();
  local succ, str = reaper.GetSetMediaTrackInfo_String(mtrack,
    "P_EXT:talagan_track_color_layout_current",
    tostring(layout),
    true
  );

  local tc      = reaper.GetNumTracks();
  local ti      = 0;
  for ti = 0, tc - 1, 1 do
    local track = reaper.GetTrack(0, ti);

    -- Also commit on tracks individually, for later sanity checks
    local succ, str = reaper.GetSetMediaTrackInfo_String(track,
      "P_EXT:talagan_track_color_layout_current",
      tostring(layout),
      true
    );
  end
end

function commitCurrentLayout()

  local tc      = reaper.GetNumTracks();
  local layout  = getProjectCurrentLayoutNum();

  local ti = 0;
  for ti = 0, tc - 1, 1 do
    local track       = reaper.GetTrack(0, ti);

    local trackLayout = getTrackCurrentLayoutNum(track);

    if trackLayout == layout then
      -- Get current col
      local col   = reaper.GetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR");

      -- Commit into the track's layer slot
      local succ, str = reaper.GetSetMediaTrackInfo_String(track,
        "P_EXT:talagan_track_color_layout_" .. layout,
        tostring(col),
        true
      );
    else
      -- There's an incoherency ! The track was not in sync with the project.
      -- It probably means that it's an imported template, we want to avoid breaking things
    end

  end

end

function restoreLayout(layout)
  local tc      = reaper.GetNumTracks();

  local ti = 0;
  for ti = 0, tc - 1, 1 do
    local track = reaper.GetTrack(0, ti);

    -- Commit into the track's layer slot
    local succ, str = reaper.GetSetMediaTrackInfo_String(track,
      "P_EXT:talagan_track_color_layout_" .. layout,
      '',
      false
    );

    local col = 0;
    if succ then
       col = tonumber(str);
    end

    -- Set current col
    reaper.SetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR", col);

  end

  setCurrentLayoutNum(layout);
end

function switchToTrackColorLayout(layout)
  commitCurrentLayout();
  restoreLayout(layout);
end

function extractTrackLayoutNumFromActionName()
  local _, sfname = reaper.get_action_context()

  -- Get the param inside parenthesis
  return sfname.match(sfname,"([0-9]+).lua$")
end

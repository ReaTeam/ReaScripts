-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description Shared code for "Find overlapping notes" actions

local function findOverlappingNotesInTake(take, should_select)
  local lookup = {}

  local errocount = 0

  local _, nc = reaper.MIDI_CountEvts(take);
  for i=0, nc-1 do
    ret, sel, muted, sppq, eppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i);
    if not lookup[chan] then lookup[chan] = {} end

    -- Deselect all notes
    if should_select then
      reaper.MIDI_SetNote(take, i, false, nil,nil,nil,nil,nil,nil,false)
    end

    local existing = lookup[chan][pitch]
    if not existing then
    else
      if existing.ep > sppq then
        errocount = errocount + 1;
        if should_select then
          reaper.MIDI_SetNote(take, existing.idx, true, nil,nil,nil,nil,nil,nil,false)
        end
      end
    end

    lookup[chan][pitch] = { sp = sppq, ep = eppq, idx = i }
  end

  return errocount
end

local function findOverlappingNotesInCurrentMETake()
  local me = reaper.MIDIEditor_GetActive();
  if not me then return end

  local take = reaper.MIDIEditor_GetTake(me);
  if not take then return end

  local err_count = findOverlappingNotesInTake(take, true)

  if err_count > 0 then
    reaper.MB(err_count .. " overlapping notes found ! "," Ouch!",0)
  else
    reaper.MB("No overlapping notes in current take !", "Cool!", 0)
  end
end

local function findOverlappinNotesInAlltakes()
  local report = ''
  local ic = reaper.CountMediaItems();
  local tec = 0;

  for i=0, ic-1 do
    local item = reaper.GetMediaItem(0,i);
    local tc = reaper.CountTakes(item);

    for ti=0, tc-1 do
      local take  = reaper.GetMediaItemTake(item,ti);
      local track = reaper.GetMediaItemTrack(item);
      local ec = findOverlappingNotesInTake(take, false);
      local _,trname = reaper.GetTrackName(track)
      if ec > 0 then
        tec    = tec + ec;
        report = report .. trname  .. " : " .. reaper.GetTakeName(take) .. " : " .. ec .. "\n"
      end
    end
  end

  if not (report == '') then
    reaper.MB(report, "Found " .. tec .. " overlapping notes !! \n", 0)
  else
    reaper.MB("No overlapping notes found in project !", "Cool!", 0)
  end
end

return {
  findOverlappingNotesInTake = findOverlappingNotesInTake,
  findOverlappinNotesInAlltakes = findOverlappinNotesInAlltakes,
  findOverlappingNotesInCurrentMETake = findOverlappingNotesInCurrentMETake
}

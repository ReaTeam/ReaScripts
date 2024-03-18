-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local MU  = require "lib/MIDIUtils"
local T   = require "modules/time"
local S   = require "modules/settings"

-- Read/Manipulate notes as objects

local function GetNote(take, ni, use_mu)

  local selected, muted, startPPQ, endPPQ, chan, pitch, vel, offvel

  if use_mu then
    _, selected, muted, startPPQ, endPPQ, chan, pitch, vel, offvel = MU.MIDI_GetNote(take, ni)
  else
    _, selected, muted, startPPQ, endPPQ, chan, pitch, vel = reaper.MIDI_GetNote(take, ni)
    offvel = 0
  end

  return  {
    index     = ni,
    selected  = selected,
    muted     = muted,
    pitch     = pitch,
    chan      = chan,
    vel       = vel,
    startPPQ  = startPPQ,
    startQN   = reaper.MIDI_GetProjQNFromPPQPos(take, startPPQ),
    endPPQ    = endPPQ,
    endQN     = reaper.MIDI_GetProjQNFromPPQPos(take, endPPQ),
    offvel    = offvel
  }
end

local function SetNewNoteBounds(note, take, startPPQ, endPPQ)
  note.startPPQ = T.PPQRound(startPPQ)
  note.endPPQ   = T.PPQRound(endPPQ)
  note.startQN  = reaper.MIDI_GetProjQNFromPPQPos(take, note.startPPQ)
  note.endQN    = reaper.MIDI_GetProjQNFromPPQPos(take, note.endPPQ)
end

local function CountEvts(take, use_mu)
  if use_mu then
    return MU.MIDI_CountEvts(take)
  else
    return reaper.MIDI_CountEvts(take)
  end
end

local function BuildFromManager(note_from_manager, take, startPPQ, endPPQ)
  local n = {
    index     = nil,
    selected  = S.getSetting("SelectInputNotes"),
    muted     = false,
    chan      = note_from_manager.chan,
    pitch     = note_from_manager.pitch,
    vel       = note_from_manager.vel
  }
  SetNewNoteBounds(n, take, startPPQ, endPPQ)
  return n
end

return {
  GetNote           = GetNote,
  SetNewNoteBounds  = SetNewNoteBounds,
  CountEvts         = CountEvts,
  BuildFromManager  = BuildFromManager
}

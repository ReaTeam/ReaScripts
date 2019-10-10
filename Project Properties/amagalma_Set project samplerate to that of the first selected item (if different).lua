-- @description amagalma_Set project samplerate to that of the first selected item (if different)
-- @author amagalma
-- @version 1.0
-- @about
--   # Sets the project samplerate to be as that of the first selected item (if different)
--   # Thanks to cfillion for introducing me to the Audio_Init & Quit functions!

local reaper = reaper
local item = reaper.GetSelectedMediaItem(0, 0)
if item then
  local take = reaper.GetActiveTake( item )
  if take and not reaper.TakeIsMIDI( take ) then
    local source = reaper.GetMediaItemTake_Source( take )
    local samplerate = reaper.GetMediaSourceSampleRate( source )
    local projsrate = reaper.SNM_GetIntConfigVar( "projsrate", 0 )
    if samplerate ~= projsrate then
      reaper.SNM_SetIntConfigVar( "projsrate", samplerate )
      reaper.Audio_Quit()
      reaper.Audio_Init()
      reaper.UpdateTimeline()
      reaper.MB( string.format("Samplerate changed from %qkHz to %qkHz",projsrate,samplerate ), "Samplerate changed", 0 )
    end
  end
end
reaper.defer(function () end )

script_title = "Render inversed midi"

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
reaper.Main_OnCommand(40153, 0) -- open editor
MIDI_editor = reaper.MIDIEditor_GetActive()
reaper.MIDIEditor_OnCommand(MIDI_editor, 40003) -- sel all notes
reaper.MIDIEditor_OnCommand(MIDI_editor, 40019) -- reversemidi
reaper.Main_OnCommand(40290, 0) -- time sel to items
reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_AWRENDERSTEREOSMART"),0) -- render to new take
reaper.MIDIEditor_OnCommand(MIDI_editor, 40019) -- reverse midi
reaper.Main_OnCommand(40716, 0) -- close editor
item1 = reaper.GetSelectedMediaItem(0, 0)
itempos1 = reaper.GetMediaItemInfo_Value(item1, "D_POSITION")
track = reaper.GetMediaItem_Track(item1)
tracknum = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 1

countitems = reaper.CountMediaItems(0)
for i = 1, countitems, 1 do
item2 = reaper.GetMediaItem(0, i-1)
if item2 ~= nil then
  itempos2 = reaper.GetMediaItemInfo_Value(item2, "D_POSITION")
   if itempos1 == itempos2 then
    track2 = reaper.GetMediaItem_Track(item2)
    if track2 ~= nil then
     tracknum2 = reaper.GetMediaTrackInfo_Value(track2, "IP_TRACKNUMBER")
      if tracknum2 == tracknum then
        reaper.SetMediaItemInfo_Value(item2, "B_UISEL", 1)
        reaper.Main_OnCommand(41051, 0) -- reverse audio
      end
     end
     end
   end
end
reaper.SetMediaItemInfo_Value(item1, "B_UISEL", 0)
reaper.Undo_EndBlock(script_title, 0)
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)

-- @description Zero crossing loop maker for items
-- @version 1.2
-- @author JerContact
-- @about
--   # zero-crossing-loop-maker-for-items
--   This script is similar to X-Raym's script for making a seemless loop.  But, for this it's specifically only for an item.
--   This script is intended for sound designers who have the bounced or rendered or "subproject" asset already and they just
--   want to click the item and make a loop.  This is how a lot of sound designers create their loops, so thought I would
--   cut down on that work and make it in one click.  The script asks you for the amount of seconds you would like the crossfade
--   to happen in.  So, it's dynamic depending on the source and what the user wants.  It also does the split at a zero crossing,
--   so perfect loops here we come!
-- @changelog
--   + 1.2 Fixing error with different paste setting setup (cursor position fixed)

reaper.Undo_BeginBlock()

item = reaper.GetSelectedMediaItem(0, 0)

if item~=nil then

numitems = reaper.CountSelectedMediaItems(0)

if numitems==1 then

  item = reaper.GetSelectedMediaItem(0, 0)
  track = reaper.GetMediaItem_Track(item)
  reaper.Main_OnCommand(40286, 0) --go to previous track
  temptrack = reaper.GetSelectedTrack(0, 0)
  command=40286
  while temptrack~=track do
    reaper.Main_OnCommand(command, 0) --go to previous track
    temptrack2 = reaper.GetSelectedTrack(0, 0)
    if temptrack2==temptrack then
      command=40285
    end
    temptrack=temptrack2
  end
  
  reaper.Main_OnCommand(40913, 0) --zoom vertically

retval, time = reaper.GetUserInputs("Crossfade Time", 1, "Input Crossfade Time (in secs)", "4")

if retval then

--reaper.Main_OnCommand(41295, 0) --duplicate item

pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

posend = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

posend = pos+posend

edit = pos+((posend-pos)/2)

if tonumber(time)<(posend-pos)/2 then

reaper.SetEditCurPos(pos+((posend-pos)/2), 1, 0)

--commandID = reaper.NamedCommandLookup(
reaper.Main_OnCommand(40792, 0) --split item

--curpos = reaper.GetCursorPosition()

item = reaper.GetSelectedMediaItem(0, 0)

reaper.Main_OnCommand(40289, 0)

reaper.SetMediaItemSelected(item, 1)

reaper.Main_OnCommand(40699, 0) --cut left item

reaper.SetEditCurPos(posend-tonumber(time), 1, 0)

curpos = reaper.GetCursorPosition()

reaper.Main_OnCommand(40058, 0) --paste left item

reaper.GetSet_LoopTimeRange(true, false, curpos-tonumber(time), curpos+tonumber(time), false)

reaper.Main_OnCommand(40718, 0) -- select items

reaper.GetSet_LoopTimeRange(true, false, curpos, curpos+tonumber(time), false)

reaper.Main_OnCommand(40916, 0) -- crossfade

reaper.Main_OnCommand(40699, 0)

reaper.SetEditCurPos(pos, 1, 0)

reaper.Main_OnCommand(40058, 0)

reaper.Main_OnCommand(40635, 0)

reaper.SetEditCurPos(pos, 1, 0)

else
  
  reaper.ShowMessageBox("The crossfade length is too large for a good loop, choose a smaller crossfade length","Error",0)

end

end

else
  reaper.ShowMessageBox("Can Only Loop 1 Item at a Time","Error",0)
end

end

reaper.Undo_EndBlock("Zero Crossing Loop Maker for Items", 0)

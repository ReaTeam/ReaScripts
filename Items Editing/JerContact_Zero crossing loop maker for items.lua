-- @description Zero crossing loop maker for items
-- @version 1.4
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
--   + 1.4 adding functionality that the cursor goes to the closest item to the beginning of the session after the loops are made

reaper.Undo_BeginBlock()

reaper.PreventUIRefresh(1)

item = reaper.GetSelectedMediaItem(0, 0)

if item~=nil then

items=reaper.CountSelectedMediaItems(0)

itemarray={}

selarray={}

x=0

while x<items do

  itemarray[x]=reaper.GetSelectedMediaItem(0, x)
  x=x+1

end

original_position = reaper.GetMediaItemInfo_Value(itemarray[0], "D_POSITION")

x=0

y=0

while x<items do

z=0

reaper.Main_OnCommand(40289, 0) --deselect all items

reaper.SetMediaItemSelected(itemarray[x], 1)

item_length = reaper.GetMediaItemInfo_Value(itemarray[x], "D_LENGTH")

item_position = reaper.GetMediaItemInfo_Value(itemarray[x], "D_POSITION")

item_center = item_position + item_length/2

item_end = item_position + item_length 

time = item_length/10

if item_length > 40 then

  time = 4
  end



reaper.SetEditCurPos(item_center, false, false)

reaper.Main_OnCommand(41196, 0) --Disable default fadein/fadeout

reaper.Main_OnCommand(41995, 0) --Move edit cursor to nearest zero crossing in items

reaper.Main_OnCommand(40757, 0) --Item: Split items at edit cursor (no change selection)

reaper.SetMediaItemInfo_Value(itemarray[x], "D_POSITION", item_end - time)

reaper.Main_OnCommand(41059, 0) --Crossfade any overlapping items

reaper.SetEditCurPos(item_position, false, false)

reaper.Main_OnCommand(41205, 0) --Move position of item to edit cursor

reaper.Main_OnCommand(40635, 0) --remove time selection

items2=reaper.CountSelectedMediaItems(0)

while z<items2 do

  selarray[y]=reaper.GetSelectedMediaItem(0, z)
  y=y+1
  z=z+1

end

x=x+1
end

reaper.Main_OnCommand(40289, 0) --deselect all items

p=0

arraysort={}

while p<y do

  arraysort[p] = reaper.GetMediaItemInfo_Value(selarray[p], "D_POSITION")
  p=p+1

end

i=0
ar=0
arraytemp={}
  
while(i<y) do
  
  m=0
  ar=0
  
  while (m<y) do
  
    if y==1 then
    break
    else
      if m+1==y then
      break
      end
    end
      
    if arraysort[ar]<arraysort[ar+1] then

    else
      arraytemp[0] = arraysort[ar]
      arraysort[ar] = arraysort[ar+1]
      arraysort[ar+1] = arraytemp[0]
    end
    ar=ar+1
    m=m+1
  
  end
  
  i=i+1

end

original_position = arraysort[0]

reaper.SetEditCurPos(original_position, false, false)

b=0

while b<y do

  reaper.SetMediaItemSelected(selarray[b], 1)
  b=b+1

end

end

reaper.PreventUIRefresh(-1)

reaper.Undo_EndBlock("Zero Crossing Item Loop", 0)

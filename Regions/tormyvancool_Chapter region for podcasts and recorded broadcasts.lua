-- @description Chapter region for podcasts and recorded broadcasts
-- @author Tormy Van Cool
-- @version 1.0
-- @screenshot Example: ChapterRegion.lua in action https://i.imgur.com/lnlAMab.gif
-- @about
--   # Chapter Region for Podcasts and Recorded Broadcasts
--
--   It's an ideal feature for Podcasts and Recorded Broadcasts
--   It enables the user to highlight all the embedded songs by just a click.
--
--   By selecting the item of a song, a pop up windows asks to enter: Title and Performer of the song.
--   Automatically the script calculates the duration of the song in second, rounding it up to the 2nd decimal, based on the duration of the item.
--
--   It creates a region with the following line preceded by the ID3 Tag "CHAP="
--   "CHAP=Title:title_of_the_song|Performer:Performer_of_the_song|Duration:Duration_in_seconds"
--
--   This can be used by any decoder, to get all the CHAP tags inside the Podcast, getting out all the required information to be sent to Collecting Societies for the Rights collection.
--
--   Key features:
--   - It can work also as Armed Action
--   - It creates a region that contains the required Tags without sintaxis errors.
--   - It embeds the ID3 tags while Reaper is rendering the MP3s with Metadata, in automatic way.

reaper.Main_OnCommand(40290,0)
retval, InputString=reaper.GetUserInputs("Name", 2, "Song Title,separator=\n,Performer", "")
if retval==false then return end
if retval then
  t = {}
  i = 0
  for line in InputString:gmatch("[^" .. "\n" .. "]*") do
      i = i + 1
      t[i] = line
  end
end
function create_region(region_name)
  local color = 0
  local ts_start, ts_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if ts_start == ts_end then return end
  reaper.AddProjectMarker2(0, true, ts_start, ts_end, region_name, -1, color)
  reaper.Undo_OnStateChangeEx("Create region with predefined name", -1, -1)
end
function get_item_lengths()
    local A
    local item = reaper.GetSelectedMediaItem(0, 0)
    if item ~= nil then
      A = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    end
  return A
end
itemduration ='Duration:'..math.floor(get_item_lengths() * 100) / 100
InputString_TITLE='Title:'..t[1]:upper()
InputString_PERFORMER='Performer:'..t[2]:upper()
local name = "CHAP="..InputString_TITLE..'|'..InputString_PERFORMER..'|'..itemduration
create_region(name)
reaper.Main_OnCommand(40020,0)

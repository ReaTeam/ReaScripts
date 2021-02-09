-- @description Chapter Region for Podcasts and Recorded Broadcasts
-- @author Tormy Van Cool
-- @version 1.1
-- @changelog
--   Labeled mandatory fields
--   Added fields: Production Year, Label
--   Horizontally enhanced text fields for better visibility
--   Creation of  an "append"-type "PROJECT_NAME.PodcastSideCar.txt" file into the Project Folder containing:
--   - Start of the song in seconds from the beginning of the Podcast
--   - Standard Flag for some Radio-Automation software
--   - Song's fields separated by Hyphens and contained between " "
--   Duration of each song round up to the 1st decimal
--   Better renamed the Main script's Window
--   Better renamed the Undo point
-- @screenshot Example: ChapterRegion.lua in action https://i.imgur.com/x6jgTqm.gif
-- @about
--   # Chapter Region for Podcasts and Recorded Broadcasts
--
--   It's an ideal feature for Podcasts and Recorded Broadcasts
--   It enables the user to highlight all the embedded songs by just a click.
--
--   By selecting the item of a song, a pop up windows asks to enter: Title, Performer of the song,and some optional field.
--   Automatically the script calculates the duration of the song in second, rounding it up to the 1st decimal, based on the duration of the item.
--
--   It creates a region with the following line preceded by the ID3 Tag "CHAP=" with this content:
--   "CHAP=Title:title_of_the_song|Performer:Performer_of_the_song|Year:Year_of_production(optional)|Label:Labels_(optional)|Duration:Duration_in_seconds_(automatically calculated)"
--
--   This can be used by any decoder, to get all the CHAP tags inside the Podcast, getting out all the required information to be sent to Collecting Societies for the Rights collection.
--
--   Key features:
--   - It can work also as Armed Action
--   - It creates a region that contains the required Tags without sintaxis errors.
--   - It embeds the ID3 tags while Reaper is rendering the MP3s with Metadata, in automatic way.
--   - it creates a Podcast's SideCar file (TXT type) into the project directory

reaper.Main_OnCommand(40290,0)

local pj_name=reaper.GetProjectName(0, "")
local pj_path = reaper.GetProjectPathEx(0 , '' ):gsub("(.*)\\.*$","%1")
pj_name = string.gsub(string.gsub(pj_name, ".rpp", ""), ".RPP", "")..'.PodcastSideCar.txt'

SideCar = io.open(pj_path..'\\'..pj_name, "a")

retval, InputString=reaper.GetUserInputs("PODCAST/BROADCAST: SONG DATA", 4, "Song Title (Mandatory),separator=\n,extrawidth=400,Performer (Mandatory),Production Year,Label", "")

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
  reaper.Undo_OnStateChangeEx("PODCAST/BROADCAST: SONG DATA", -1, -1)
end

function get_item_lengths()
    local A
    local item = reaper.GetSelectedMediaItem(0, 0)
    if item ~= nil then
      A = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      item_start = math.floor(math.abs(reaper.GetMediaItemInfo_Value(item, "D_POSITION")))
    end
  return A
end

local roundup = math.floor(get_item_lengths() * 10) / 10
itemduration ='Duration:'..roundup
InputString_TITLE='Title:'..t[1]:upper()
InputString_PERFORMER='Performer:'..t[2]:upper()

-- CHECK PRESENCE OF DATA IN NOT MANDATORY FIELDS
if t[3] ~= "" then
    InputString_PRODUCTION_YEAR = '|'..'Year:'..t[3]:upper()
    InputString_PRODUCTION_YEAR_SideCar = ' - '..t[3]:upper()
  else
   InputString_PRODUCTION_YEAR = ""
    InputString_PRODUCTION_YEAR_SideCar = ""
end

if t[4] ~= "" then
    InputString_PRODUCTION_LABEL = '|'..'Label:'..t[4]:upper()
    InputString_PRODUCTION_LABEL_SideCar = ' - '..t[4]:upper()
   else
    InputString_PRODUCTION_LABEL = ""
    InputString_PRODUCTION_LABEL_SideCar = ""
end
local song = "CHAP="..InputString_TITLE..'|'..InputString_PERFORMER..InputString_PRODUCTION_YEAR..InputString_PRODUCTION_LABEL..'|'..itemduration
local SideCar_ = item_start..',1,'..'"'..t[1]:upper()..' - '..t[2]:upper()..InputString_PRODUCTION_YEAR_SideCar..InputString_PRODUCTION_LABEL_SideCar..' - '..roundup..'"'
create_region(song)
reaper.Main_OnCommand(40020,0)

SideCar:write( SideCar_.."\n" )
SideCar:close()


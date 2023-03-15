--[[
ReaScript name: Create pitch-rate (vari-speed) take envelope and render to new take
Author: BenK-msx, BuyOne, Phazma
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.1
Changelog: #Added a temporary bypass for 'Options: Toggle trim content behind media items when editing'
	   in case it's enabled so it doesn't intefere
	   #Added support for negative range only for users only interested in tape stop effect
	   #Added option to obey note-offs for scenarios where playback time of the original media in Arrange 
	   is shorter than that of the portion imported into ReaSamplomatic5000
	   #Added 2 ms of 'Release' in ReaSamplomatic5000 to prevent clicks
	   #Added a setting to replace original media with a rendered one
Licence: WTFPL
REAPER: at least v5.962
About:	This is a ported to ReaScript method of creating a take pitch envelope 
	which affects take rate, originally suggested by user BenK-msx on the 
	Cockos forum at  
	https://forum.cockos.com/showthread.php?t=155233  
	This allows creating such effects as tape stop or playback acceleration 
	where pitch changes along with playrate.  
	The solution which allows controlling pitch by exact semitones using 
	ReaperBlog Macro controller JSFX plugin was borrowed from Phazma, who shared 
	their method at  
	https://forum.cockos.com/showthread.php?p=2394001
		
	HOW IT WORKS
		
	The script adds to selected item(s) a MIDI take whose FX chain contains 
	'Macro controller' JS plugin (a modified version of the one by ReaperBlog 
	available via ReaPack), ReaControlMIDI and ReaSamplomatic5000 or only 
	Macro controller and ReaSamplmatic5000, depending on the USER SETTIGS below. 
	In both cases pitch/rate is controlled by sliders of 'Macro controller' plugin
	whose take FX parameter envelope is exposed in the MIDI take.
		
	In the first case pitch/rate is controlled by 'Macro controller' plugin 
	'Pitch wheel' slider linked to ReaControlMIDI 'Pitch wheel' control via 
	Parameter modulation, in the second it's controlled by 'Macro controller' 
	plugin 'Pitch offest' slider linked to ReaSamplomatic5000 'Pitch offset' control. 

	In both cases ReaSamplomatic5000 will contain the media item source file which 
	will be triggered from the MIDI take and affected by the automation drawn 
	in the exposed 'Macro controller' parameter envelope.
		
	When the pitch/rate is controlled with Macro controller 'Pitch wheel' slider 
	envelope the pitch range can be managed manually with ReaSamplomatic5000 
	'Pitch bend' parameter or pre-defined in the USER SETTINGS below.  
	If the pitch/rate is controlled with Macro controller 'Pitch offset' slider the 
	range can be pre-defined in the USER SETTINGS below. Doing it manually is too 
	involved as it's not straightforward requires making calculations.

	The Macro controller plugin is meant to make pitch/rate envelope range and 
	resolution more meainingful and allow snapping them to semitones.  
	ReaControlMIDI 'Pitch wheel' control isn't based on semitones while 
	ReaSamplomatic5000 'Pitch offset' control default range is -80 to 80 semitones.

	The 'Macro controller' plugin file will be placed in the \Effects\utility\ folder 
	in the REAPER resource directory the first time the script is run, and then 
	will be loaded from there unless deleted, in which case it will be subsequently 
	recreated on the next script run.


	HOW TO USE

	Hover mouse cursor over a single media item or select media item(s) (or their copies) 
	which you'd like to process with the effect and run the script.  
	A MIDI take containing an envelope will be added to the item.  
	Draw automation in the envelope, select the item(s) and run the script again, 
	this time a new media take will be added to the item with the effect the 
	parameter automation creates printed.  
	Run the script again and you'll be able to add another such take optionally 
	replacing all previously rendered ones.

	When there's no MIDI take with the envelope the script will add it, and when there's
	one, the script will render it to new take.

	Be aware that when pitch is increased with automation, the media file 
	triggered from the MIDI take becomes shorter and, if not compensated by subsequent 
	decrease in pitch (which is not required as it depends on the user objectives), 
	its playback will stop earlier than that of the original media item.

	In take FX, parameter modulation only works during playback. Without playback, 
	movements of a modulating control are not translated to the modulated control.

]]

-------------------------------------------------------------------------------------
---------------------------------- USER SETTINGS ------------------------------------
-------------------------------------------------------------------------------------
-- To enable any setting save for PITCH_BEND_RANGE and PITCH_OFFSET_RANGE insert any 
-- alphanumeric character between the quotation marks.

-- This setting determines the parameter which controls sample pitch;
-- If empty, the pitch is controlled by the pitch bend message sent to RS5k
-- by ReaControlMIDI inserted upstream whose 'Pitch wheel' slider is in turn controlled
-- by 'Macro controller' plugin 'Pitch wheel' slider envelope.
-- In this case maximum pitch range is -12 to 12 st depending on the 'Pitch bend'
-- setting of RS5k which can be pre-defined with PITCH_BEND_RANGE setting below.
-- If any alphanumeric character is inserted between the quotation marks
-- the pitch will be contolled by RS5k 'Pitch offset' parameter instead, which in turn
-- is controlled by 'Macro controller' plugin 'Pitch offset' slider envelope;
-- In this case maximum range is -80 to 80 st but can be changed with PITCH_OFFSET_RANGE 
-- setting below.
PITCH_OFFSET = ""


-- Only relevant when PITCH_OFFSET setting above is DISabled;
-- empty defaults to 12 (i.e. -12 to 12 st) which is a maximum range
-- of the corresponing control in RS5k;
-- if exceeds 12 will be clamped to 12;
-- if happens to be a decimal number will be rounded down.
PITCH_BEND_RANGE = ""


-- Only relevant when PITCH_OFFSET setting above is ENabled;
-- empty defaults to 80 (i.e. -80 to 80 st) which is a maximum range
-- of the corresponding control in RS5k;
-- the rest is as PITCH_BEND_RANGE setting mutatis mutandis.
PITCH_OFFSET_RANGE = ""


-- Enable if you only need tape-stop effect, i.e. vari-speed downwards,
-- in which case the envelope range will start at 0 and go down to the negative
-- value set as PITCH_BEND_RANGE or PITCH_OFFSET_RANGE above.
NEGATIVE_RANGE = ""


-- Orginal pitch control step in ReaControlMIDI and RS5k plugins is not semitone,
-- which makes it difficult to automate pitch based on semitones due to envelopes
-- not being snapped to them;
-- If this setting is enabled, slider step value in 'Macro Controller' plugin
-- inserted in the MIDI take FX chain will be set to 1 (semitone) and the slider envelope
-- exposed in the MIDI item will allow automating pitch by exact semitones;
-- The envelope point values can still be decimal, nonetheless the pitch will change by
-- exact semitones; values up to a whole value and a half are rounded down, values
-- greater than a whole value and a half (including) are rounded up, e.g. 1 semitone up
-- from the root corresponds to envelope point values between 0.5 and 1.499,
-- 1 semitone down from the root to values between -0.501 and -1.500, and so forth.
SNAP_TO_SEMITONE = ""


-- The setting ensures that the sample is cut off in RS5k in case the original media
-- was shortened AFTER creation of the vari-speed envelope which would result in its
-- being shorter than the portion imported into the RS5k, or when the sample is slowed
-- down which makes it longer than the original, that's to prevent sample playback  
-- extending beyond the media item end.
OBEY_NOTE_OFFS = ""


-- Before the script runs action 'Item: Render items to new take' it displays
-- a prompt asking if the user wants previously rendered takes deleted;
-- if the user assents to the prompt, along with previous takes their source files
-- will be (irriversibly) deleted as well, provided this setting is enabled.
DELETE_TAKE_SRC = ""


-- The script will automatically enable option 'Options: Show all takes in lanes (when room)'
-- if it's OFF, so the addition of the MIDI take with the vari-speed envelope and subsequently
-- rendered takes is apparent and doesn't look as if the original item was deleted;
-- If you still prefer to have take lanes collapsed, feel free to enable this setting.
DO_NOT_SWITCH_TAKE_LANES_ON = ""


-- If enabled, all media takes are deleted from the selected item(s), including 
-- the original media take, MIDI vari-speed take is rendered to a new media take 
-- which is placed at the top and locked, so that the item ends up only containing 
-- two takes: the MIDI vari-speed envelope take and the rendered media take;
-- if option DELETE_TAKE_SRC is enabled above the source files of all previously 
-- rendered takes (if any) are deleted from the disk as well, save for the source 
-- file of the original media.
DELETE_RENDER_LOCK = ""

-------------------------------------------------------------------------------------
------------------------------ END OF USER SETTINGS ---------------------------------
-------------------------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function ACT(comm_ID) -- both string and integer work
local act = comm_ID and r.Main_OnCommand(r.NamedCommandLookup(comm_ID),0)
end


function Delete_Take_Src(take)
ACT(40440) -- Item: Set selected media temporarily offline
local src = r.GetMediaItemTake_Source(take)
local src = r.GetMediaSourceParent(src) or src -- in case the item is a section or a reversed source
local file_name = r.GetMediaSourceFileName(src, '')
os.remove(file_name)
os.remove(file_name..'.reapeaks')
ACT(40439) -- Item: Set selected media online
-- Thanks to cfillion and MPL
-- https://forum.cockos.com/showthread.php?t=211250 file rename
-- https://forum.cockos.com/showthread.php?p=1889202 file rename
end


function Get_Take_Portion_Props_for_RS5k(item) -- if item is trimmed whether as a section or not

local take = r.GetActiveTake(item)
-- get origial media source to calculate unit for convertion of item boundaries into region boundaries within RS5k
local src = r.GetMediaItemTake_Source(take)
local src = r.GetMediaSourceParent(src) or src -- in case the item is a section or a reversed source; if item is a section the next function will return actual item length rather than the source's, hence unsuitable for unit calculation (for which full source length is required) and parent source must be retrieved
local len_src, is_lengthInQN = r.GetMediaSourceLength(src)
-- convert source length to sample region units used in rs5k (0 - 1)
local unit = 1/len_src
local is_source_looped = r.GetMediaItemInfo_Value(item, 'B_LOOPSRC') == 1

local src = r.GetMediaItemTake_Source(take) -- re-initialize to get the actual length of the section in Arrange, if any, rather than the source's which was retrieved above for the sake of unit calculation
local is_sect, start_offset_sect, len_sect, is_reversed = r.PCM_Source_GetSectionInfo(src) -- works for both section and full source
local start_offset_take = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS') -- negative if start is extended beyond a non-looped source
local take_playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
local len_item = r.GetMediaItemInfo_Value(item, 'D_LENGTH')*take_playrate

-- When item is looped only the very first iteration, which can be partial due to trim, is translated into RS5k sample area
-- Enabling reverse in Item Properties turns item into section even when Section option isn't explicitly checkmarked
-- After import into RS5k of a reversed item, section or not, trimmed or not, looped or not, the sample region accurately reflects boundaries of the non-reversed source; for original section boundaries to be respected special calculations are required which are pointless because the sample area won't match item playback anyway due to reverse

-- If a non-looped item is untrimmed from the left, start_offset_take value is negative throwing the region start position off in RS5k since RS5k respects the negative offset, so it must be ignored
local neg_offset = start_offset_take < 0

-- start is either Section: (first field) or 'Start in source' value in the Media Item Properties window; len is either Length (under Position) or Section: Length in Media Item Properties window; accounting for left and right edges trim
local start = start_offset_take >= 0 and start_offset_sect + start_offset_take or start_offset_sect -- accounting for extension or trim of the left edge; when item source is looped item's left (and right for that matter) edge can't be extended beyond source, otherwise extension is ignored
local len = is_source_looped and len_item > len_sect - start_offset_take and len_sect - start_offset_take -- item is looped in Arrange
or start_offset_take < 0 and len_item + start_offset_take > len_sect and len_sect -- item is extended beyond its source at the start and at the end
or start_offset_take >= 0 and len_item > len_sect - start_offset_take and len_sect - start_offset_take -- item is extended beyond its source at the end
or start_offset_take < 0 and len_item + start_offset_take -- item is extended beyond its source at the start
or len_sect >= len_item and len_item -- item is or isn't trimmed at either end

return unit, start, len, neg_offset

end


function Set_MIDI_Item_Chunk(item_chunk, pos, len, rs5k_idx)

local midi_item = r.GetSelectedMediaItem(0,0)
local ret, chunk = r.GetItemStateChunk(midi_item, '', false) -- isundo false
local chunk_new = item_chunk:gsub('POSITION\nSNAPOFFS 0\nLENGTH', 'POSITION '..pos..'\nSNAPOFFS 0\nLENGTH '..len)
local chunk_new = chunk_new:gsub('LASTSEL 1', 'LASTSEL '..rs5k_idx) -- set RS5k UI active within the FX chain using its actual idx which depends on the USER SETTINGS

r.SetItemStateChunk(midi_item, chunk_new, false) -- isundo false
r.SetEditCurPos(pos+len+.01, false, false) -- moveview and seekplay false
ACT(41311) -- Item edit: Trim right edge of item to edit cursor // after chunk setting or unsetting 'Loop source' option the MIDI item is left with a single loop notch which can only be removed either by opening its Item Properties dialogue and dry saving the settings, manually wiggling the item's right edge or by trimming it with the action but from the script trimming only works if it extends the item
r.SetMediaItemInfo_Value(midi_item, 'D_LENGTH', len) -- restore length
r.SetEditCurPos(pos+len, false, false) -- moveview and seekplay false

end


local comment = [[
<COMMENT
aHR0cHM6Ly9mb3J1bS5jb2Nrb3MuY29tL3Nob3d0aHJlYWQucGhwP3Q9MTU1MjMz
>
]] -- contains forum thread URL

PITCH_OFFSET = #PITCH_OFFSET:gsub(' ','') > 0

function Get_Pitch_Range(user_range, type)
local default = type:lower() == 'bend' and 12 or type:lower() == 'offset' and 80
	if not default then return end
user_range = user_range:gsub(' ','')
user_range = #user_range == 0 and default or tonumber(user_range)
return user_range and math.abs(user_range) > default and default or user_range and math.floor(user_range)
end

PITCH_BEND_RANGE = Get_Pitch_Range(PITCH_BEND_RANGE, 'bend')
PITCH_OFFSET_RANGE = Get_Pitch_Range(PITCH_OFFSET_RANGE, 'offset')

NEGATIVE_RANGE = #NEGATIVE_RANGE:gsub(' ','') > 0
SNAP_TO_SEMITONE = #SNAP_TO_SEMITONE:gsub(' ','') > 0

local pitch_wheel = [[
<PROGRAMENV 3 0
PARAMBASE 0
LFO 0
LFOWT 1 1
AUDIOCTL 0
AUDIOCTLWT 1 1
PLINK 1 0:-1 0 0
>
]] -- parameter link to macro slider // values stay as they are, range is controlled by RS5k 'Pitch bend' control; could have been included in the next chunk

local Scale = NEGATIVE_RANGE and 0.5 or 1 -- if negative, range goes from 0 downwards hence it's only half of the range which spans both negative and positive values
local pitch_wheel = pitch_wheel:gsub('PLINK 1', 'PLINK '..Scale) -- PLINK fleld 1 value (Scale)

local pitch_wheel = [[BYPASS 0 0 0
<VST "VST: ReaControlMIDI (Cockos)" reacontrolMIDI.vst.dylib 0 "Pitch wheel" 1919118692 ""
ZG1jcu5e7f4AAAAAAAAAAN4AAAABAAAAAAAQAA==
/////wAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAgAABAAAAAQAAAAAAAAAAtAAAARjpcUHJvZ3JhbSBGaWxlc1xSRUFQRVIgKHg2NClcRGF0YVxHTS5yZWFiYW5rAAAA
AAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGAAAATWFqb3IADQAAADEwMjAzNDA1MDYwNwABAAAAAAAA
AAABAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAQAAAA
>
FLOATPOS 0 0 0 0
FXID {D908D367-F083-0344-8500-C9CAD3566E32}
]]
.. pitch_wheel ..
[[
WAK 0 0
]]
.. comment ..
[[BYPASS 0 0 0
<VST "VSTi: ReaSamplOmatic5000 (Cockos)" reasamplomatic.vst.dylib 0 "Pitch bend knob affects range" 1920167789 ""
bW9zcu5e7f4AAAAAAgAAAAEAAAAAAAAAAgAAAAAAAABSAQAAAQAAAAAAEAA=
QzpcVXNlcnNcTUVcRGVza3RvcFxDaG9yZHNcYXVkaW9cb2xkLXNjaG9vbC10eXBlLWRydW0tbG9vcC1tYWRsaXAubXAzAAAAAAAAAPA/AAAAAAAA4D8AAAAAAADwPwAA
AAAAAAAAAAAAAAAA8D+amZmZmZmxP83MzMzMzOs/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAdXlwf+uH7z4AAAAAAAAAAAAAAAAAAAAAAAAAYP9/5z8AAACgqkrvPwAA
AAAAAOA/AQAAAAAAAAAAAAAAAAAAAAAA8D9AAAAAAAAAAAAA8D//////AAAAAAAAAAAAAAAAAADwPwAAAAAAAPA/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AADOpCEhGmWQPwAAAAAAAPA/TU+vKaEqMD8AAAAAAAAAAAAAAAAAAPA/AAAAAAAAAAA=AAAQAAAA
>
FLOAT 0 0 0 0
FXID {1863C847-5057-224E-A924-AECD86ADA4C5}
WAK 0 0
]] .. comment



local pitch_offset = [[
<PROGRAMENV 15 0
PARAMBASE 0.5
LFO 0
LFOWT 1 1
AUDIOCTL 0
AUDIOCTLWT 1 1
PLINK 1 0:-1 1 -0.5
>
]] -- parameter link to macro slider // PARAMBASE and PLINK field 4 (Offset) values are required for scaling the range if user chooses so, they remain constant while PLINK fleld 1 value (Scale) may change


local Scale = PITCH_OFFSET_RANGE*1.25/100 -- 1 semitone of RS5k's 'Pitch offset' control corresponds to 1.25% (potitive) of Parameter modulation 'Scale' control; divided by 100 because in PLINK parameter 'Scale' control values are normalized, range between 0 to 1
local Scale = NEGATIVE_RANGE and Scale/2 or Scale -- if negative, range goes from 0 downwards hence it's only half of the range which spans both negative and positive values
local pitch_offset = pitch_offset:gsub('PLINK 1', 'PLINK '..Scale)
local pitch_offset = NEGATIVE_RANGE and pitch_offset:gsub('%-0.5', '-1') or pitch_offset -- if negative, Offset val is -100%


local pitch_offset = [[
BYPASS 0 0 0
<VST "VSTi: ReaSamplOmatic5000 (Cockos)" reasamplomatic.dll 0 "Pitch offset knob" 1920167789<56535472736F6D72656173616D706C6F> ""
bW9zcu5e7f4AAAAAAgAAAAEAAAAAAAAAAgAAAAAAAABSAQAAAQAAAAAAEAA=
QzpcVXNlcnNcTUVcRGVza3RvcFxDaG9yZHNcYXVkaW9cb2xkLXNjaG9vbC10eXBlLWRydW0tbG9vcC1tYWRsaXAubXAzAAAAAAAAAPA/AAAAAAAA4D8AAAAAAADwPwAA
AAAAAAAAAAAAAAAA8D+amZmZmZmxP83MzMzMzOs/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAdXlwf+uH7z4AAAAAAAAAAAAAAAAAAAAAAAAAYP9/5z8AAACgqkrvPwAA
AAAAAOA/AQAAAAAAAAAAAAAAAAAAAAAA8D9AAAAAAAAAAAAA8D//////AAAAAAAAAAAAAAAAAADwPwAAAAAAAPA/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AADOpCEhGmWQPwAAAAAAAPA/TU+vKaEqMD8AAAAAAAAAAAAAAAAAAPA/AAAAAAAAAAA=AAAQAAAA
>
FLOAT 484 140 511 0
FXID {182CBE41-7185-41DD-B12F-75A4FBD4F10F}
]]
.. pitch_offset ..
[[
WAK 0 0
]] .. comment

local macro_controller_jsfx =
[[
BYPASS 0 0 0
<JS "ReaperBlog_Macro Controller (vari-speed mod).jsfx" ""
0 - 0 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
>
FLOATPOS 0 0 0 0
FXID {EC59E0DA-328E-47ED-8D3F-77F3BB275DD1}
]]


local macro_controller_jsfx = not PITCH_OFFSET and macro_controller_jsfx ..
[[
<PARMENV 0 -12 12 0
EGUID {3BA1AEF8-748C-4D9C-BC56-7993B183F974}
ACT 1 -1
VIS 1 1 1
LANEHEIGHT 0 0
ARM 1
DEFSHAPE 0 -1 -1
PT 0 0 0
>
WAK 0 0
]] -- via Pitch wheel
or PITCH_OFFSET and macro_controller_jsfx ..
[[
<PARMENV 1 -80 80 0
EGUID {D6E80563-51D5-4179-A7C9-E6C7277C2E40}
ACT 1 -1
VIS 1 1 1
LANEHEIGHT 0 0
ARM 1
DEFSHAPE 0 -1 -1
PT 0 0 0
>
WAK 0 0
]] -- via Pitch offset


local midi_item_chunk = [[
<ITEM {6784C7E1-BB0E-BA40-BDE9-00DAF859495A}
POSITION
SNAPOFFS 0
LENGTH
LOOP 0
ALLTAKES 0
FADEIN 1 0 0 1 0 0
FADEOUT 1 0 0 1 0 0
MUTE 0
SEL 1
YPOS 0.5 0.5
IGUID {6784C7E1-BB0E-BA40-BDE9-00DAF859495A}
IID 5
NAME "pitch/rate (vari-speed) envelope"
VOLPAN 1 0 1 -1
SOFFS 0 0
PLAYRATE 1 1 0 -1 0 0.0025
CHANMODE 0
GUID {3B346501-05D2-104C-8C06-3B5B0D947CE1}
<SOURCE MIDI
HASDATA 1 960 QN
CCINTERP 32
POOLEDEVTS {899CC621-9E82-49CC-B862-3111AA0539F7}
e 0 90 30 7f
e 109 80 30 00
E 8051 b0 7b 00
CCINTERP 32
GUID {E9EB6C9A-6699-4A58-9196-911C53E372C7}
IGNTEMPO 0 120 4 4
SRCCOLOR 1612
VELLANE -1 9 0
CFGEDITVIEW 0 0.956055 61 12 0 -1 0 0 0 0.5
KEYSNAP 0
TRACKSEL 0
EVTFILTER 0 -1 -1 -1 -1 0 0 0 0 -1 -1 -1 -1 0 -1 0 -1 -1
CFGEDIT 1 0 0 1 0 0 1 1 1 1 1 0.125 20 57 1368 683 0 0 0 0 0 0 0 0 0 0.5 0 0 1 64
>
<TAKEFX
WNDRECT 601 158 800 591
SHOW 0
LASTSEL 1
DOCKED 0
>
TAKE_FX_HAVE_NEW_PDC_AUTOMATION_BEHAVIOR 1
>
]]

local chunk_pt1, chunk_pt2 = midi_item_chunk:match('(.+DOCKED 0\n)(.+)') -- split chunk
local midi_item_chunk = not PITCH_OFFSET and (chunk_pt1..macro_controller_jsfx..pitch_wheel..chunk_pt2) or (chunk_pt1..macro_controller_jsfx..pitch_offset..chunk_pt2) -- parentheses aren't necessary, just for clarity

local macro_controller_jsfx =
[[
/**
* JSFX Name: Macro controller
* About:
* Dummy controls to use with Parameter link/modulation
* Author: The REAPER Blog
* Licence: GPL v3
* REAPER: 5.0
* Version: 1.0
*/

/**
* Changelog:
* v1.0 (2018-03-14)
+ Initial Release
*/

/*
To be used with the script:
'BuyOne_Create pitch-rate (vari-speed) take envelope and render to new take.lua'
available via ReaPack
If you have this file, the script either is or was installed on your machine
If using the script settings you change pitch range and/or step to other than default, the start, end and step slider values
(those between smaller/greater <> signs below) will change
*/

desc:Macro Controller (vari-speed mod)

// Controls ReaControlMIDI 'Pitch Wheel' parameter
slider1:0<-12, 12, 1>Pitch wheel
// Controls ReaSamplomatic5000 'Pitch offset' parameter
slider2:0<-80, 80, 1>Pitch offset

//slider3:50<0, 100, 1>Macro 3
//slider4:50<0, 100, 1>Macro 4
//slider5:50<0, 100, 1>Macro 5

]]


function Delete_Render_Lock(item)
	-- delete all media takes from the item
	for i = r.CountTakes(item)-1, 0, -1 do -- or r.GetMediaItemNumTakes(item)-1 // in reverse since takes will be getting deleted
	local take = r.GetTake(item, i) -- or r.GetMediaItemTake(item, i)
	local midi_take = r.TakeIsMIDI(take)		
		if not midi_take then
		local retval, tag = r.GetSetMediaItemTakeInfo_String(take, 'P_EXT:varispeed', '', false) -- setNewValue false
			if tag == 'varispeed_rend' and DELETE_TAKE_SRC then -- only delete rendered take source files, keep the original media source file
			Delete_Take_Src(take)
			end
		r.SetMediaItemInfo_Value(item, 'I_CURTAKE', i) -- set take active
		ACT(40129) -- Take: Delete active take from items
		end
	end
-- render new, move to top and lock
ACT(41999) -- Item: Render items to new take
local retval, tag = r.GetSetMediaItemTakeInfo_String(r.GetActiveTake(item), 'P_EXT:varispeed', 'varispeed_rend', true) -- setNewValue true // add tag to the newly rendered take
ACT(41380) -- Item: Move active takes to top lane
ACT(41340) -- Item properties: Lock to active take (mouse click will not change active take)
end


function Create_JSFX_if_None_or_Update(macro_controller_jsfx)

local sep = r.GetResourcePath():match('[\\/]')
local file_path = r.GetResourcePath()..sep..'Effects'..sep..'utility'..sep..'ReaperBlog_Macro Controller (vari-speed mod).jsfx'
	if not r.file_exists(file_path) then
	local f = io.open(file_path, 'w')
	f:write(macro_controller_jsfx)
	f:close()
	return end

local f = io.open(file_path, 'r')
local cont = f:read('*a')
f:close()
local pitch_bend_range, pitch_bend_range_strt, pitch_bend_step = cont:match('slider1:0<%-(%d+), (%d+), (.-)>') -- pitch offset slider range, pitch range start in case negative range is selected by the user & step
local pitch_offset_range, pitch_offset_range_strt, pitch_offset_step = cont:match('slider2:0<%-(%d+), (%d+), (.-)>') -- same

local cont_new
	if not PITCH_OFFSET and (PITCH_BEND_RANGE ~= tonumber(pitch_bend_range) or NEGATIVE_RANGE and pitch_bend_range_strt ~= '0' or not NEGATIVE_RANGE and pitch_bend_range_strt == '0' or SNAP_TO_SEMITONE and #pitch_bend_step ~= 1 or not SNAP_TO_SEMITONE and #pitch_bend_step ~= 4) then -- 4 refers to 0.01
	local pitch_bend_slid = cont:match('slider1.->'):gsub('-','%%%0') -- escape all minuses for replacement below
	local PITCH_BEND_RANGE_STRT = NEGATIVE_RANGE and 0 or PITCH_BEND_RANGE
	local pitch_bend_slid_new = 'slider1:0<-'..PITCH_BEND_RANGE..', '..PITCH_BEND_RANGE_STRT..', '..(SNAP_TO_SEMITONE and '1>' or '0.01>')
	cont_new = cont:gsub(pitch_bend_slid, pitch_bend_slid_new)
	elseif PITCH_OFFSET and (PITCH_OFFSET_RANGE ~= tonumber(pitch_offset_range) or NEGATIVE_RANGE and pitch_offset_range_strt ~= '0' or not NEGATIVE_RANGE and pitch_offset_range_strt == '0' or SNAP_TO_SEMITONE and #pitch_offset_step ~= 1 or not SNAP_TO_SEMITONE and #pitch_offset_step ~= 4) then -- 4 refers to 0.01
	local pitch_offset_slid = cont:match('slider2.->'):gsub('-','%%%0') -- escape all minuses for replacement below
	local PITCH_OFFSET_RANGE_STRT = NEGATIVE_RANGE and 0 or PITCH_OFFSET_RANGE
	local pitch_offset_slid_new = 'slider2:0<-'..PITCH_OFFSET_RANGE..', '..PITCH_OFFSET_RANGE_STRT..', '..(SNAP_TO_SEMITONE and '1>' or '0.01>')
	cont_new = cont:gsub(pitch_offset_slid, pitch_offset_slid_new)
	end
	if cont_new then
	local f = io.open(file_path, 'w')
	f:write(cont_new)
	f:close()
	end

end

function Extend_MIDI_Note(item)
local media_take = r.GetTake(item,0)
local media_take_src = r.GetMediaItemTake_Source(media_take)
local is_sect, start_offset_sect, len_sect, reversed = r.PCM_Source_GetSectionInfo(media_take_src)
local src_fin = r.GetMediaItemInfo_Value(item, 'D_POSITION') + len_sect - r.GetMediaItemTakeInfo_Value(media_take, 'D_STARTOFFS') -- source of the media item is used in case it's looped so only end of the first loop iteration is respected
local midi_take = r.GetTake(item,1)
local src_fin_PPQ = r.MIDI_GetPPQPosFromProjTime(midi_take, src_fin)
local retval, sel, muted, startppqpos, endppqpos, chan, pitch, vel = r.MIDI_GetNote(midi_take, 0)
r.MIDI_SetNote(midi_take, 0, selectedIn, mutedIn, startppqpos, endppqpos + (src_fin_PPQ - endppqpos), pitchIn, velIn, noSortIn) -- selectedIn, mutedIn, chanIn, pitchIn, velIn, noSortIn nil
end


----------------------- WARNING MESSAGES -------------------

function space(n) -- number of repeats, integer
return string.rep(' ',n)
end

local x, y = r.GetMousePosition()
local item, take = r.GetItemFromPoint(x, y, true) -- allow_locked true
local select = item and r.SetMediaItemSelected(item, true)
local item = item or r.GetSelectedMediaItem(0,0)
local invalid = r.CountSelectedMediaItems(0) == 1 and (r.CountTakes(item) == 1 and r.TakeIsMIDI(r.GetActiveTake(item)) -- a MIDI item
or item and r.CountTakes(item) == 0) -- an empty item

	if not item or invalid then r.MB(not item and 'No item under mouse or selected.' or invalid and 'No selected media items.', 'WARNING', 0)
	return r.defer(function() do return end end) end

local sel_item_t = {} -- collect sel items because they will be deselected during the main routine

	if item then -- if at least one item is selected generate warning messages

	-- Placed outside to be accessible to r.MB() function in case the loop or the warning message sequence below don't start
	local mes_playrate = ''
	local mes_pitch_shift = ''
	local mes_pitch_env = ''
	local mes_trim_loop = ''
	local mes_reversed = ''

	local warning

		for i = 0, r.CountSelectedMediaItems(0)-1 do -- the item loop will continue to the end to collect all the items
		local item = r.GetSelectedMediaItem(0,i)
		local empty_item = r.CountTakes(item) == 0
		local midi_item = r.CountTakes(item) == 1 and r.TakeIsMIDI(r.GetActiveTake(item))
		local valid = not empty_item and not midi_item

			if valid then sel_item_t[#sel_item_t+1] = item end

		local take
			for i = 0, r.CountTakes(item)-1 do
			take = r.GetTake(item, i)
			retval, tag = take and r.GetSetMediaItemTakeInfo_String(take, 'P_EXT:varispeed', '', false) -- setNewValue false
				if tag == 'varispeed_env' then break end
			end

			if tag ~= 'varispeed_env' and not warning and valid then -- only display warning messages once, when 'warning' var is false, made true at the end of warning messages sequence below

			local inset = 'It\'s recommeded first gluing the item\n'..space(13)..'so it becomes an independent source.\n'
			local pitch_inset = ' due to RS5k pitch shift algo\n'..space(20)..'the sample length will differ.\n\n'

			mes_playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE') ~= 1 and 'Take playrate won\'t be reflected in RS5k after import\n'..space(13)..'which will result in playback mismatch.\n'..space(13)..inset..'\n' or mes_playrate

			mes_pitch_shift = r.GetMediaItemTakeInfo_Value(take, 'D_PITCH') ~= 0 and 'Take current pitch shift value will be reflected in RS5k,\n'..space(14)..'however'..pitch_inset or mes_pitch_shift

			-- take pitch envelope is active
			local env = r.GetTakeEnvelopeByName(take, 'Pitch')
			-- only account for the pitch envelope if it's active
			local retval, env_chunk = table.unpack(env and {r.GetEnvelopeStateChunk(env, '', false)} or {x, x}) -- isundo false
			local active = env and env_chunk:match('ACT 1')
				if env and active then
				retval, time, env_pitch_val, shape, tens, is_sel = r.GetEnvelopePointEx(env, -1, 0) -- autoitem_idx -1 // env_pitch_val is used in the main routine hence global
				mes_pitch_env = env_pitch_val ~= 0 and space(14)..'If pitch envelope affects take pitch\n'..space(9)..'only pitch value of the 1st envelope point\n'..space(20)..'will be reflected in the RS5k,\n'..space(17)..'but'..pitch_inset or mes_pitch_env
				end

			-- item is looped in Arrange and trimmed from the start
			is_source_looped = r.GetMediaItemInfo_Value(item, 'B_LOOPSRC') == 1 -- will be used in the main routine hence global
			start_offset_take = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
			local len_item = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
			local src = r.GetMediaItemTake_Source(take)
			local is_sect, start_offset_sect, len_sect, is_reversed = r.PCM_Source_GetSectionInfo(src)
			mes_trim_loop = is_source_looped and start_offset_take > 0 and len_item > len_sect - start_offset_take and space(8)..' If item is looped and trimmed from the start\n   only the first loop iteration will be reflected in RS5k.\n'..space(18)..'The MIDI take will not be looped.\n'..space(15)..inset..'\n' or mes_trim_loop

			-- item source is reversed
			local src = r.GetMediaItemTake_Source(take)
			local is_sect, start_offset_sect, len_sect, is_reversed = r.PCM_Source_GetSectionInfo(src)
			mes_reversed = is_reversed and space(5)..'Reversed take source won\'t be reflected in RS5k\n'..space(6)..'after import and will result in playback mismatch.\n'..space(15)..inset..space(9)..'Or using "Item: Reverse items to new take".\n\n' or mes_reversed -- the item is imported without reverse maintaining correct boundaries of the non-reversed state

			warning = #mes_playrate + #mes_pitch_shift + #mes_pitch_env + #mes_trim_loop + #mes_reversed > 0 and 1 -- only display warning messages once, when 'warning' var is false

			end

		end

		if #mes_playrate + #mes_pitch_shift + #mes_pitch_env + #mes_trim_loop + #mes_reversed > 0 then
		local mess = mes_playrate .. mes_pitch_shift .. mes_pitch_env .. mes_trim_loop .. mes_reversed
		local resp = r.MB(mess, 'WARNING', 1)
			if resp == 2 then return r.defer(function() do return end end) end
		end

	end

----------------------- END OF WARNING MESSAGES ------------------------


DELETE_TAKE_SRC = #DELETE_TAKE_SRC:gsub(' ','') > 0
OBEY_NOTE_OFFS = #OBEY_NOTE_OFFS:gsub(' ','') > 0

--------------------------- MAIN ROUTINE -------------------------------

	if #sel_item_t == 0 then r.MB('No selected media items.', 'WARNING', 0);
	return r.defer(function() do return end end) end

r.PreventUIRefresh(1)
r.Undo_BeginBlock()

-- Temporarily disable trim content option if enabled because it will cause deletion of the media item when a MIDI item is inserted
local trim_content = r.GetToggleCommandStateEx(0, 41117) == 1 -- Options: Toggle trim content behind media items when editing
local off = trim_content and ACT(41117) -- Options: Toggle trim content behind media items when editing

local delete_prev_takes

	for _, item in ipairs(sel_item_t) do

	local render

		-- find if item contains varispeed MIDI take
		for i = 0, r.CountTakes(item)-1 do -- or r.GetMediaItemNumTakes(item)-1
		local take = r.GetTake(item, i) -- or r.GetMediaItemTake(item, i)
		retval, tag = r.GetSetMediaItemTakeInfo_String(take, 'P_EXT:varispeed', '', false) -- setNewValue false
			if tag == 'varispeed_env' then render = 1
			break end
		end

		if render then		
		undo = 'Render vari-speed take(s) in items'
			if DELETE_RENDER_LOCK then Delete_Render_Lock(item)
			else
				-- find if item already contains rendered takes and condition their deletion
				for i = 0, r.CountTakes(item)-1 do -- or r.GetMediaItemNumTakes(item)-1
				local take = r.GetTake(item, i) -- or r.GetMediaItemTake(item, i)
				local retval, tag = r.GetSetMediaItemTakeInfo_String(take, 'P_EXT:varispeed', '', false) -- setNewValue false
					if tag == 'varispeed_rend' and not delete_prev_takes then
					local resp = r.MB('The item already contains varispeed take(s) rendered earlier.\n\n'..space(15)..'Should they be replaced with the new take?\n\n'..(DELETE_TAKE_SRC and '' or space(11)..'If "YES", take source files will remain on the disk.\n\n')..(#sel_item_t > 1 and space(12)..'(The choice will apply to all subsequent items).' or ''), 'PROMPT', 3)
						if resp == 2 then return r.defer(function() do return end end) -- abort
						elseif resp == 6 then delete_prev_takes = 1; break -- proceed with deleting
						else delete_prev_takes = 2; break -- proceed without deleting
						end
					end
				end
			-- required since ACT(41999) -- 'Item: Render items to new take' applies to all currently selected items
			-- placed here so selection is maintained while the prompt above is displayed and when script is aborted
			r.SelectAllMediaItems(0, false) -- deselect all items
			r.SetMediaItemSelected(item, true) -- select item
				if delete_prev_takes == 1 then
					for i = r.CountTakes(item)-1, 0, -1 do -- or r.GetMediaItemNumTakes(item)-1 // in reverse since takes will be getting deleted
					local take = r.GetTake(item, i) -- or r.GetMediaItemTake(item, i)
					local retval, tag = r.GetSetMediaItemTakeInfo_String(take, 'P_EXT:varispeed', '', false) -- setNewValue false
						if tag == 'varispeed_rend' then
						local del_src = DELETE_TAKE_SRC and Delete_Take_Src(take)
						r.SetMediaItemInfo_Value(item, 'I_CURTAKE', i) -- set take active
						ACT(40129) -- Take: Delete active take from items
						end
					end
				end
				-- set MIDI take active
				for i = 0, r.CountTakes(item)-1 do -- or r.GetMediaItemNumTakes(item)-1
				local take = r.GetTake(item, i) -- or r.GetMediaItemTake(item, i)
				local retval, tag = r.GetSetMediaItemTakeInfo_String(take, 'P_EXT:varispeed', '', false) -- setNewValue false
					if tag == 'varispeed_env' then r.SetMediaItemInfo_Value(item, 'I_CURTAKE', i) break end
				end
			ACT(41999) -- Item: Render items to new take
			local retval, tag = r.GetSetMediaItemTakeInfo_String(r.GetActiveTake(item), 'P_EXT:varispeed', 'varispeed_rend', true) -- setNewValue true // add tag to the newly rendered take
			end
			
		elseif tag ~= 'varispeed_env' then -- insert MIDI item with varispeed envelope if there's none

		undo = 'Insert vari-speed envelope in items'

		Create_JSFX_if_None_or_Update(macro_controller_jsfx)

		local pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
		local item_len = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
		local take = r.GetActiveTake(item)

		local pitch = r.GetMediaItemTakeInfo_Value(take, 'D_PITCH')	-- in semitones
		local vol_take = r.GetMediaItemTakeInfo_Value(take, 'D_VOL')
		local pitch = env_pitch_val and pitch + env_pitch_val or pitch -- add value of the 1st pitch env in the take, if any
		local src = r.GetMediaItemTake_Source(take) -- r.GetMediaItemTakeInfo_Value(r.GetActiveTake(item), 'P_SOURCE') -- this one returns number, not a pointer
		local src = r.GetMediaSourceParent(src) or src -- in case the item is a section or a reversed source
		local file_name = r.GetMediaSourceFileName(src, '')
		local unit, start, len, neg_offset = Get_Take_Portion_Props_for_RS5k(item) -- len here is sample area length for RS5k which may differ from item length if one is looped

		local start_time, end_time = r.GetSet_ArrangeView2(0, false, 0, 0) -- isSet false
		ACT(41173) -- Item navigation: Move cursor to start of items
		ACT(40214) -- Insert new MIDI item...
		ACT(41173) -- Item navigation: Move cursor to start of items // restores view or at least brings item back into view when the item is zoomed out, otherwise it's moved out of sight at 'Insert new MIDI item' due to cursor movement if the option 'Move edit cursor when pasing/inserting media' is enabled at Preferences -> Editing behavior which is its default state

		-- find index of RS5k in the FX chain
		local rs5k_idx = not PITCH_OFFSET and 2 or 1

		Set_MIDI_Item_Chunk(midi_item_chunk, pos, len, rs5k_idx) -- when the media item is looped the MIDI item becomes looped as well unless there's media item start offset which makes looping MIDI item pointless because only the 1st trimmed loop iteration will be imported from the Arrange and not the complete iteration

		local midi_item = r.GetSelectedMediaItem(0,0)
		local midi_take = r.GetActiveTake(midi_item)

		local retval, tag = r.GetSetMediaItemTakeInfo_String(midi_take, 'P_EXT:varispeed', 'varispeed_env', true) -- setNewValue true

			if neg_offset then -- if a non-looped item left edge is extended beyond source, move note to the section/source start from the item start
			local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE') -- affects take start offset
			local start_offset_take = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS') -- media item start offset // when take playrate is not 1 this value doesn't change even though the source shifts within the take hence must be adjusted
			local retval, sel, muted, startppqpos, endppqpos, chan, pitch, vel = r.MIDI_GetNote(midi_take, 0)
			local startppqpos_new = r.MIDI_GetPPQPosFromProjTime(midi_take, pos - start_offset_take/playrate)
			r.MIDI_SetNote(midi_take, 0, selectedIn, mutedIn, startppqpos_new, startppqpos_new + (endppqpos - startppqpos), pitchIn, velIn, noSortIn) -- selectedIn, mutedIn, chanIn, pitchIn, velIn, noSortIn nil
			end

		r.TakeFX_SetNamedConfigParm(midi_take, rs5k_idx, 'FILE0', file_name)
		local set_inf = vol_take < 1 and r.TakeFX_SetParam(midi_take, rs5k_idx, 2, 0) -- 2 'Gain for minimum velocity' aka Min vol // set to -inf if item/take voulume < 0 so negative vol can be set
		r.TakeFX_SetParam(midi_take, rs5k_idx, 0, vol_take) -- 'Volume' // Normalized type of function must not be used since take (and item) volume scale isn't linear
		-- no difference between the result of using functions below with or without Normalized
	--	r.TakeFX_SetParam(midi_take, rs5k_idx, 13, start*unit) -- 13 'Sample start offset'
		r.TakeFX_SetParamNormalized(midi_take, rs5k_idx, 13, start*unit) -- 13 'Sample start offset'
	--	r.TakeFX_SetParam(midi_take, rs5k_idx, 14, (start+len)*unit) -- 14 'Sample end offset'
		r.TakeFX_SetParamNormalized(midi_take, rs5k_idx, 14, (start+len)*unit)-- 14 'Sample end offset'
		r.TakeFX_SetParam(midi_take, rs5k_idx, 15, 0.5+pitch*1/160) -- 15 'Pitch offset' aka Pitch adjust // 160 is the max range: -80 + 80; 0.5 is 'Pitch offset' at 0
	--	r.TakeFX_SetParamNormalized(midi_take, rs5k_idx, 15, 0.5+pitch*1/160) -- 15 'Pitch offset' aka Pitch adjust
		r.TakeFX_SetParamNormalized(midi_take, rs5k_idx, 10, 1/1625*2) -- 10 'Release' // set to 2 ms to prevent clicks; 1625 is the max val
		local set = OBEY_NOTE_OFFS and r.TakeFX_SetParamNormalized(midi_take, rs5k_idx, 11, 1) -- 11 'Obey note-offs'
			if PITCH_BEND_RANGE and not PITCH_OFFSET then
			r.TakeFX_SetParam(midi_take, rs5k_idx, 16, 1/12*PITCH_BEND_RANGE) -- 16 'Pitchbend range'
			end
			if is_source_looped and start_offset_take == 0 then -- is_source_looped var is initialized in WARNING MESSAGES routine
			ACT(40698) -- Edit: Copy items // copy midi item
			r.SelectAllMediaItems(0, false) -- deselect all items
			r.SetMediaItemSelected(item, true) -- select media item
			-- pasting a MIDI item with a note as take to a media item looped in Arrange with full first loop iteration results in slight drift of the MIDI item loop period relative to the media item one; this is remedied by shortening the media item down to its source (first loop iteration), pasting the MIDI item, toggling 'Loop source' option and restoring the media item original length; this works if done manually and via API only if done with actions, corresponding functions don't produce this effect
			r.SetMediaItemInfo_Value(item, 'D_LENGTH', len) -- shorten media item
			ACT(40603) -- Take: Paste as takes in items // paste midi item
			ACT(40636) -- Item properties: Loop item source // disable
			ACT(40636) -- Item properties: Loop item source // re-enable
			r.SetMediaItemInfo_Value(item, 'D_LENGTH', item_len) -- restore length
			r.SelectAllMediaItems(0, false) -- deselect all items
			r.SetMediaItemSelected(midi_item, true) -- select orig MIDI item
			ACT(40006) -- Item: Remove items // remove orig MIDI item
			else -- prevent MIDI item looping in case the media item is looped and is trimmed from the start, so only the first loop iteration is reflected in the MIDI item
			r.SetMediaItemInfo_Value(midi_item, 'D_LENGTH', item_len)
			-- get rid of the loop notch created in the MIDI item after changing length
			ACT(40636) -- Item properties: Loop item source // enable
			ACT(40636) -- Item properties: Loop item source // disable
			ACT(40699) -- Edit: Cut items // cut midi item
			r.SelectAllMediaItems(0, false) -- deselect all items
			r.SetMediaItemSelected(item, true) -- select media item
			ACT(40603) -- Take: Paste as takes in items // paste midi item
			end
		local extend = OBEY_NOTE_OFFS and Extend_MIDI_Note(item)	
		end
	end

	for _, item in ipairs(sel_item_t) do -- restore all valid items selection
	r.SetMediaItemSelected(item, true)
	end

	local show_takes_in_lanes = #DO_NOT_SWITCH_TAKE_LANES_ON:gsub(' ','') + r.GetToggleCommandStateEx(0, 40435) == 0 -- Options: Show all takes in lanes (when room)
	and ACT(40435) -- Options: Show all takes in lanes (when room)


local on = trim_content and ACT(41117) -- Options: Toggle trim content behind media items when editing // re-enable because it was disabled at the start of the routine
	
r.Undo_EndBlock(undo, -1)
r.PreventUIRefresh(-1)





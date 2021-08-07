-- @description Read tags (for plugin tag system)
-- @author Will Develop
-- @version 2.0
-- @link Forum https://forum.cockos.com/showthread.php?p=2300953#post2300953

--[[
  INFO:
    - ReaScript Name: Read Tags
    - Author: Will Develop 
    - REAPER: 6.33
    - Version: 2.0
  
  LINKS:
    YOUTUBE-TUTORIAL: https://youtu.be/V65LA_Q6EaU
	FORUM: https://forum.cockos.com/showthread.php?p=2300953#post2300953
	GITHUB: https://github.com/Will-Develop/plugin_tag_system_in_reaper

    
   INTRODUCTION:
      1.Run the Script
      2.Select the reaper-vstplugins64.ini File
      3.Select the reaper-fxfolders.ini File
      
]]--


--++THE SCRIPT FOR FIND,SORT,DELETE DUPLICATE PLUGIN-TAGS FILE++

--open the reaper-vstplugins64.ini
retval, filepath = reaper.GetUserFileNameForRead(reaper.GetResourcePath("").."\\reaper-vstplugins64.ini", "Import reaper.ini Files (reaper-vstplugins64.ini):", "")
plugin_datei = io.input(filepath);


allcompare = {} --cobind alltags and allfolders to delete the duplicate values
zeilen = {}
alltags = {} --save all tags from the (plugin_datei)-file

for line in plugin_datei:lines() do
  zeilen[line] = line
  
  if zeilen[line]:match("//") and zeilen[line]:match("#") then

    for string in line:gmatch("#%S+") do
    
    table.insert(alltags, string)
      --reaper.ShowConsoleMsg(string .. "\n")
    end
  
  end

end



--REMOVE DOUBLE VALUES FROM ARRAY alltags
local hash = {}
local res = {}

reaper.ShowConsoleMsg("ALL PLUGIN TAGS:" .. "\n" .. "\n")
table.sort(alltags)

for _,v in ipairs(alltags) do
   if (not hash[v]) then
      reaper.ShowConsoleMsg(v .. "\n")    -- res[#res+1] = v -- you could print here instead of saving to result table if you wanted
      table.insert(allcompare, v)
       hash[v] = true
   end

end
--////////////////////////////////////////////////////////////////////////////////////
--++///////////////////////////////////////////////////////////////////////////////////++





--++THE CLEANING SCRIPT FOR PLUGIN-FOLDER FILE++

--open the reaper-vstplugins64.ini
retval, filepath = reaper.GetUserFileNameForRead(reaper.GetResourcePath("").."\\reaper-fxfolders.ini", "Import reaper.ini Files (reaper-fxfolders.ini):", "")
folder_datei = io.input(filepath);

zeilen = {}
allfolders = {} --save all tags from the (plugin_datei)-file

for line in folder_datei:lines() do
  zeilen[line] = line
  
  if zeilen[line]:match("Item0=") and zeilen[line]:match("#") then

    for string in line:gmatch("#%S+") do
    
    table.insert(allfolders, string)
      --reaper.ShowConsoleMsg(string .. "\n")
    end
  
  end

end



--REMOVE DOUBLE VALUES FROM ARRAY allfolders
local hash = {}
local res = {}

reaper.ShowConsoleMsg("\n".."ALL FOLDERS:" .. "\n".."\n")
table.sort(allfolders)
for _,v in ipairs(allfolders) do
   if (not hash[v]) then
      table.insert(allcompare, v)
      reaper.ShowConsoleMsg(v .. "\n")    -- res[#res+1] = v -- you could print here instead of saving to result table if you wanted
      hash[v] = true
   end

end
--////////////////////////////////////////////////////////////////////////////////////
--++///////////////////////////////////////////////////////////////////////////////////++


--remove all double values from array allcompare
reaper.ShowConsoleMsg("\n".."CREATE FOLDER FOR:" .. "\n".."\n")
table.sort(allcompare)
for _,v in ipairs(allcompare) do
   if (not hash[v]) then
	if(not v:match("!!!VSTi"))then
      reaper.ShowConsoleMsg(v .. "\n")    -- res[#res+1] = v -- you could print here instead of saving to result table if you wanted
       hash[v] = true
       end
   end

end

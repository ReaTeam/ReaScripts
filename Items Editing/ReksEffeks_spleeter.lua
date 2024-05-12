-- @description Spleeter: Split audio item into stems
-- @author Rek's Effeks
-- @version 1.0.1
-- @changelog Fixed a bug that would cause the resulting files to skip occasionally and go out of sync with the original
-- @metapackage
-- @provides
--   [linux main] ReksEffeks_spleeter/Spleeter2.lua
--   [linux main] ReksEffeks_spleeter/Spleeter4.lua
--   [linux main] ReksEffeks_spleeter/Spleeter5.lua
-- @link
--   Spleeter https://github.com/deezer/spleeter
--   Click here for a Windows/Mac version made by someone else https://forum.cockos.com/showthread.php?t=239365
-- @about
--   I saw that someone had made Lua scripts for running Spleeter on MacOS and Windows, but there was no Linux version. This will work on Linux and perhaps MacOS as well, but I cannot test that. It definitely won't work on Windows. 
--   This script assumes you have Spleeter installed and are able to run it from the command line as documented on the Spleeter Github. I've adapted it from the Windows/Mac version made by ReaTrak.



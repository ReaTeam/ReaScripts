-- @description Adjust selected tracks sends via send window (or fader volume if no send window)
-- @author Triode
-- @version 1
-- @metapackage
-- @provides
--   [main] triode_Adjust selected tracks sends via send window (or fader volume if no send window)/triode_Add 1db to selected tracks sends via send window (or fader volume if no send window).lua
--   [main] triode_Adjust selected tracks sends via send window (or fader volume if no send window)/triode_Subtract 1db from selected tracks sends via send window (or fader volume if no send window).lua
-- @donation https://www.paypal.me/outoftheboxsounds
-- @about This script will adjust the relative level of all the selected tracks sends named in an open REAPER send window. If no send window is open, the selected tracks fader volume will be adjusted.  You can edit the db value that the script uses inside the script.  It works on regular tracks as well as the master track, can target sends as well as hardware outs and will distinguish between mono and stereo sends.  It requires js_ReaScriptAPI extension by juliansader.  Thanks to Edgemeal for the code at the start.  NOTE: THIS SCRIPT REQUIRES ITS KEY COMMAND SCOPE SET TO "GLOBAL + TEXT FIELDS"


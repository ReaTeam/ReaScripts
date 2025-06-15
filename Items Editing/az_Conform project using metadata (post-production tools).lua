-- @description Conform project using metadata (post-production tools)
-- @author AZ
-- @version 0.7
-- @changelog
--   - New improved EDL parser that can cover different EDL text formatting more wider.
--   - Better handling overlapped items.
-- @provides
--   az_Conform project using metadata (post-production tools)/az_Conform project_Core.lua
--   [main] az_Conform project using metadata (post-production tools)/az_Rename takes with last used settings (post-production tools).lua
-- @link Forum thread https://forum.cockos.com/showthread.php?t=300182
-- @donation Donate via PayPal https://www.paypal.me/AZsound
-- @about
--   # Conform project using metadata
--
--   This script has various features for comfortable work when you get a project from video editor
--
--   - Conform project using EDL CMX 3600 files
--   - Link source files
--   - Expand channels from field recorder poly-wave files
--   - and more in the feature


function get_script_path()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  --script_path = script_path:gsub('[^/\\]*[/\\]*$','') --one level up
  return script_path
end

---------------------------

local script_path = get_script_path()
local file = script_path .. 'az_Conform project using metadata (post-production tools)/'
..'az_Conform project_Core.lua'
dofile(file)

--------------START----------------

MainWindow({}, 'Conform project using metadata | Post-production tools')

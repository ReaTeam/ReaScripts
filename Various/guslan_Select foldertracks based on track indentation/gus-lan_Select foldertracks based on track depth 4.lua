-- @noindex

--────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
--        ::::::::  :::    :::  ::::::::                :::            :::     ::::    :::          ::::::::   ::::::::  :::::::::  ::::::::::: ::::::::: ::::::::::: ::::::::  --
--      :+:    :+: :+:    :+: :+:    :+:               :+:          :+: :+:   :+:+:   :+:         :+:    :+: :+:    :+: :+:    :+:     :+:     :+:    :+:    :+:    :+:    :+:  --
--     +:+        +:+    +:+ +:+                      +:+         +:+   +:+  :+:+:+  +:+         +:+        +:+        +:+    +:+     +:+     +:+    +:+    +:+    +:+          --
--    :#:        +#+    +:+ +#++:++#++  ++:++#++:++  +#+        +#++:++#++: +#+ +:+ +#+         +#++:++#++ +#+        +#++:++#:      +#+     +#++:++#+     +#+    +#++:++#++    --
--   +#+   +#+# +#+    +#+        +#+               +#+        +#+     +#+ +#+  +#+#+#                +#+ +#+        +#+    +#+     +#+     +#+           +#+           +#+     --  
--  #+#    #+# #+#    #+# #+#    #+#               #+#        #+#     #+# #+#   #+#+#         #+#    #+# #+#    #+# #+#    #+#     #+#     #+#           #+#    #+#    #+#      --
--  ########   ########   ########                ########## ###     ### ###    ####          ########   ########  ###    ### ########### ###           ###     ########        --
--────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

--[[
  * ReaScript Name: gus-lan_Select foldertracks at trackdepth 4.lua
  
  * About:
      A script that selects tracks that are folders and at a specific track depth throughout the current project.
      Useful for large templates that utlize folder systems for grouping.
      
  * Instructions:
      Set which track depth the script should use in the user input section. 
      Execute script.

  * Author: Gustav Landerholm
  * Repository: GitHub > glan > reaper_scripts
  * Repository URL:https://github.com/gus-lan/reaper_scripts.git 
  * Licence: GPL v3
  * Version: 1.0
  * Version Date: 2022-07-11
  * REAPER: v6.63
  * Extensions:
--]]

--[[
* Changelog:
* v1.0 (2022-07-11)
+ Initial Release
--]]


--──── USER INPUT ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────  

  user_trackdepth_value = 4 -- Change this value from 0-> to select foldertracks at different trackdepths. 0 = no parents. 

--──── END USER INPUT ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  
  local i = 0 
  while i < reaper.CountTracks(0) do
    local current_track = reaper.GetTrack (0, i)
    
    local track_depth = reaper.GetTrackDepth(current_track)
    local track_folder_depth = reaper.GetMediaTrackInfo_Value(current_track, 'I_FOLDERDEPTH')
  
    if track_depth == user_trackdepth_value and track_folder_depth == 1 then
      reaper.SetMediaTrackInfo_Value(current_track, 'I_SELECTED', 1)
    end
    i = i + 1
  end

  

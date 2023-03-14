-- @description Select foldertracks based on track indentation
-- @author gus-lan
-- @version 1.0
-- @provides
--   [main] guslan_Select foldertracks based on track indentation/gus-lan_Select foldertracks based on track indentation (trackdepth) (settings inside).lua
--   [main] guslan_Select foldertracks based on track indentation/gus-lan_Select foldertracks based on track depth 1.lua
--   [main] guslan_Select foldertracks based on track indentation/gus-lan_Select foldertracks based on track depth 2.lua
--   [main] guslan_Select foldertracks based on track indentation/gus-lan_Select foldertracks based on track depth 3.lua
--   [main] guslan_Select foldertracks based on track indentation/gus-lan_Select foldertracks based on track depth 4.lua
--   [main] guslan_Select foldertracks based on track indentation/gus-lan_Select foldertracks based on track depth 5.lua
-- @about
--   Select Foldertracks based on track indentation (property - track depth)
--
--   Adds tracks to selection if it follows the criteria that it is a folder track, and at the track depth that the user has chosen.

--────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
--        ::::::::  :::    :::  ::::::::                :::            :::     ::::    :::          ::::::::   ::::::::  :::::::::  ::::::::::: ::::::::: ::::::::::: ::::::::  --
--      :+:    :+: :+:    :+: :+:    :+:               :+:          :+: :+:   :+:+:   :+:         :+:    :+: :+:    :+: :+:    :+:     :+:     :+:    :+:    :+:    :+:    :+:  --
--     +:+        +:+    +:+ +:+                      +:+         +:+   +:+  :+:+:+  +:+         +:+        +:+        +:+    +:+     +:+     +:+    +:+    +:+    +:+          --
--    :#:        +#+    +:+ +#++:++#++  ++:++#++:++  +#+        +#++:++#++: +#+ +:+ +#+         +#++:++#++ +#+        +#++:++#:      +#+     +#++:++#+     +#+    +#++:++#++    --
--   +#+   +#+# +#+    +#+        +#+               +#+        +#+     +#+ +#+  +#+#+#                +#+ +#+        +#+    +#+     +#+     +#+           +#+           +#+     --  
--  #+#    #+# #+#    #+# #+#    #+#               #+#        #+#     #+# #+#   #+#+#         #+#    #+# #+#    #+# #+#    #+#     #+#     #+#           #+#    #+#    #+#      --
--  ########   ########   ########                ########## ###     ### ###    ####          ########   ########  ###    ### ########### ###           ###     ########        --
--────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

--──── USER INPUT ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────  

  user_trackdepth_value = 1 -- Change this value from 0-> to select foldertracks at different trackdepths. 0 = no parents. 

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

  

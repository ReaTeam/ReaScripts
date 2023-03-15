-- @description Select folder tracks of depth X
-- @author gus-lan
-- @version 1.0
-- @provides
--   [main] . > gus-lan_Select folder tracks of depth 0.lua
--   [main] . > gus-lan_Select folder tracks of depth 1.lua
--   [main] . > gus-lan_Select folder tracks of depth 2.lua
--   [main] . > gus-lan_Select folder tracks of depth 3.lua
--   [main] . > gus-lan_Select folder tracks of depth 4.lua
--   [main] . > gus-lan_Select folder tracks of depth 5.lua
-- @about
--   Select Foldertracks based on track indentation (property - track depth)
--
--   Adds tracks to selection if it follows the criteria that it is a folder track, and at the track depth that the user has chosen.
--   Enhanced by X-Raym

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


script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

user_trackdepth_value = script_name:match("(%d+)")
if user_trackdepth_value then
  user_trackdepth_value = tonumber(user_trackdepth_value)
  if user_trackdepth_value then
    user_trackdepth_value = math.max(math.min(64, user_trackdepth_value), 1)
  end
end

if not user_trackdepth_value then user_trackdepth_value = 0 end

  -- user_trackdepth_value = 1 -- Change this value from 0-> to select foldertracks at different trackdepths. 0 = no parents. 

--──── END USER INPUT ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  reaper.PreventUIRefresh(1)
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
  reaper.PreventUIRefresh(-1)

  

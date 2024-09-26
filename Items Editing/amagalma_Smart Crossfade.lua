-- @description Smart Crossfade
-- @author amagalma
-- @version 1.73
-- @changelog
--   - set default for User Setting for maximum gap allowance between two selected items that will crossfade (fill-in gaps) to the default split crossfade length
-- @link https://forum.cockos.com/showthread.php?t=195490
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Crossfades 2 items per track inside a Razor Edit area OR selected items
--
--   - If there is a Razor Edit area then the script works on the RE like my "amagalma_Crossfade items in Razor Edit area.lua" script, else works on the selected items
--   - If any two items are adjacent then it creates a crossfade on the left side of the items' touch point
--   - If any two items are almost adjacent and their gap is less or equal to the default crossfade time then a crossfade is created
--   - If items overlap then it creates a crossfade at the overlapping area
--   - If there is a time selection covering part of both items, then it crossfades at the time selection area (items do not have to touch - closes the gap)
--   - Can be used with as many items in different tracks as you like
--   - Smart undo point creation (only if there has been at least one change)
--   - You can set inside the script if you want to keep the time selection or remove it (default: remove)
--   - You can set inside the script if you want to keep selected the previously selected items or not (default: keep selected)
--   - Default crossfade length and type are gotten automatically from Reaper Preferences ("Overlap and crossfade items when splitting, length" and "Default crossfade shape")
--   - Fade shape can be specified inside the script (overrides the one set in the Preferences)


----------------------------------- USER SETTINGS -------------------------------------------------
                                                                                                 --
local xfadeshape = -1    -- enter 0 to 7 or -1 to apply the shape set in the Reaper Preferences  --
                                                                                                 --
-- Time selection settings                                                                       --
local keep_selected  = 1 -- Set to 1 if you want to keep the items selected (else unselect all)  --
local remove_timesel = 1 -- Set to 1 if you want to remove the time selection (else keep it)     --
                                                                                                 --
-- Razor Edit area settings                                                                      --
local remove_RE_area = 1 -- Set to 1 if you want to remove the Razor Edit area (else keep it)    --
                                                                                                 --
-- Maximum gap between two selected items (not in time selection or RE area) that can crossfade  --
-- (set it to -1, if you want it to be equal to the default split crossfade length)              --
local maximum_gap = -1  -- in ms.                                                                --
                                                                                                 --
---------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------

local debug = false
if debug then reaper.ClearConsole() end
local function Msg(...)
  if debug then 
    local args = {...}
    for i = 1, #args do
      args[i] = tostring(args[i])
    end
    reaper.ShowConsoleMsg(table.concat(args,"\t").."\n")
  end
end

local xfadetime = tonumber(({reaper.get_config_var_string( "defsplitxfadelen" )})[2]) or 0.01
if xfadeshape < 0 or xfadeshape > 7 then
  xfadeshape = tonumber(({reaper.get_config_var_string( "defxfadeshape" )})[2]) or 7
end

maximum_gap = maximum_gap > -1 and maximum_gap/1000 or xfadetime


-- Razor Edit
--------------------------------
--------------------------------

local track_cnt = reaper.CountTracks(0)
if track_cnt == 0 then return reaper.defer(function() end) end

local tracks_with_RE, tr = {}, 0

local began_block = false
local reenableTrim = false

for t = 0, track_cnt - 1 do
  local track = reaper.GetTrack(0, t)
  local ok, area = reaper.GetSetMediaTrackInfo_String( track, "P_RAZOREDITS_EXT", "", false )
  if ok and area ~= "" then
    local areaS, areaE, env, lanetop, lanebtm = area:match("(%S+) (%S+) (%S+) (%S+) (%S+)")
    areaS, areaE, lanetop, lanebtm = tonumber(areaS), tonumber(areaE), tonumber(lanetop), tonumber(lanebtm)
    if env == '""' and areaS and areaE and lanetop and lanebtm then
      lanetop = lanetop - 0.000001
      lanebtm = lanebtm + 0.000001
      local item_cnt = reaper.CountTrackMediaItems(track)
      local items = {}
      local i = 0
      while i ~= item_cnt do
        local item = reaper.GetTrackMediaItem(track, i)
        local Start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local End = Start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local item_top = reaper.GetMediaItemInfo_Value( item, "F_FREEMODE_Y" )
        local item_btm = item_top + reaper.GetMediaItemInfo_Value( item, "F_FREEMODE_H" )
        if (item_top >= lanetop and item_btm <= lanebtm) and
           ( 
            (Start >= areaS and Start < areaE) or 
             (End >= areaS and Start < areaE) or
            (Start <= areaS and End >= areaE)
           )
        then
          items[#items+1] = {item, Start, End}
        end
        if Start >= areaE or #items > 2 then break end
        i = i + 1
      end
      if #items == 2 then
        if not began_block then
          reaper.Undo_BeginBlock()
          reaper.PreventUIRefresh( 1 )
          began_block = true
          if reaper.GetToggleCommandState( 41117 ) == 1 then
            reaper.Main_OnCommand(41117, 0) -- Trim content behind media items when editing
            reenableTrim = true
          end
        end
        tr = tr + 1
        tracks_with_RE[tr] = track
        reaper.BR_SetItemEdges( items[1][1], items[1][2], areaE )
        reaper.SetMediaItemInfo_Value( items[1][1], "D_FADEOUTLEN_AUTO", areaE - areaS )
        reaper.SetMediaItemInfo_Value(items[1][1], "C_FADEOUTSHAPE", xfadeshape)
        reaper.BR_SetItemEdges( items[2][1], areaS, items[2][3] )
        reaper.SetMediaItemInfo_Value( items[2][1], "D_FADEINLEN_AUTO", areaE - areaS )
        reaper.SetMediaItemInfo_Value(items[2][1], "C_FADEINSHAPE", xfadeshape)
      end
    end
  end
end

if began_block then
  remove_RE_area = remove_RE_area == 1
  if remove_RE_area then
    for i = 1, tr do
      reaper.GetSetMediaTrackInfo_String(tracks_with_RE[i], "P_RAZOREDITS", "", true)
    end
  end
  
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
  reaper.Undo_EndBlock( "Smart crossfade items in RE area", (remove_RE_area and 1 or 0)|4 )
  if reenableTrim then
    reaper.Main_OnCommand(41117, 0) -- Trim content behind media items when editing
  end
  return
end


-- Time Selection
--------------------------------
--------------------------------

local item_cnt = reaper.CountSelectedMediaItems(0)
if item_cnt < 2 then return reaper.defer(function() end) end

local abs = math.abs
local categorized_item = {}
local sel_item = {}
local sel_start, sel_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
local change = false -- to be used for undo point creation
local timeselexists

local function eq( a, b ) -- equal
  return (abs( a - b ) < 0.00001)
end

local function leq( a, b ) -- a less than or equal to b
  return a < b + 0.00001
end

local function geq( a, b ) -- a greater than or equal to b
  return a + 0.00001 > b 
end

---------------------------------------------------------------------------------------------------

local function FadeIn(item, value)
  reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO", value)
  reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", xfadeshape)
end

local function FadeOut(item, value)
  reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO", value)
  reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", xfadeshape)
end

local function FadeInOK(item, value)
  if eq( reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO"), value) and
     reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE") == xfadeshape
  then
    return true
  end
end

local function FadeOutOK(item, value)
  if eq( reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO"), value) and
     reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE") == xfadeshape
  then
    return true
  end
end

local function CrossfadeOK(item, prev_item, second_start, first_end)
  local prev_fadelen = reaper.GetMediaItemInfo_Value(prev_item, "D_FADEOUTLEN_AUTO")
  local next_fadelen = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO")
  if prev_fadelen > 0 and eq( next_fadelen, prev_fadelen ) and
     eq( first_end - prev_fadelen, second_start )
  then
    return true
  end
end

---------------------------------------------------------------------------------------------------

reaper.PreventUIRefresh(1)

local trimstate = reaper.GetToggleCommandStateEx( 0, 41117) -- get Options: Toggle trim behind items state
if trimstate == 1 then
  reaper.Main_OnCommand(41121, 0) -- Options: Disable trim behind items when editing
end


-- Store Selected items
local track_nr, prev_track = 0, 0

for i = 1, item_cnt do
  local item = reaper.GetSelectedMediaItem(0, 0)
  sel_item[i] = item
  local track = reaper.GetMediaItemTrack( item )
  local lane = math.tointeger(reaper.GetMediaItemInfo_Value( item, "I_FIXEDLANE" )) + 1
  if track ~= prev_track then
    track_nr = track_nr + 1
    prev_track = track
    categorized_item[track_nr] = {}
  end
  if not categorized_item[track_nr][lane] then
    categorized_item[track_nr][lane] = {n = 0}
  end
  categorized_item[track_nr][lane].n = categorized_item[track_nr][lane].n + 1
  categorized_item[track_nr][lane][(categorized_item[track_nr][lane].n)] = item
  reaper.SetMediaItemSelected(item, false)
end


for tr = 1, #categorized_item do -- tracks
  for lan in pairs(categorized_item[tr]) do -- lanes
    if categorized_item[tr][lan].n > 1 then -- work on lanes with more than one items
      for i = 2, categorized_item[tr][lan].n do -- items
        local item = categorized_item[tr][lan][i]
        local prev_item = categorized_item[tr][lan][i-1]
        -- check if item and previous item are on the same track
        if reaper.GetMediaItem_Track(item) == reaper.GetMediaItem_Track(prev_item) then
          local second_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
          local second_end = second_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
          local first_start = reaper.GetMediaItemInfo_Value(prev_item, "D_POSITION")
          local first_end = first_start + reaper.GetMediaItemInfo_Value(prev_item, "D_LENGTH")
          if first_end < second_start - maximum_gap and (sel_start == sel_end or (first_end < sel_start and second_start > sel_end)) then
            -- items do not touch and there is no time selection covering parts of both items
            -- do nothing
            Msg("not touch - gap greater than maximum_gap")
            Msg(string.format("Gap is %f seconds", second_start - first_end))
          --[[elseif geq( second_start - first_end, xfadetime) then
          --leq( first_start, second_start) and geq( first_end, second_end) then
            -- one item encloses the other
            -- do nothing
            Msg("enclosure")--]]
          elseif sel_start ~= sel_end and geq(sel_end, second_start) and leq(sel_end, second_end) and leq(sel_start, first_end) and geq(sel_start, first_start) then
            -- time selection exists and covers parts of both items
            Msg("inside time selection")
            timeselexists = 1
            local timesel = sel_end - sel_start
            if not FadeInOK(item, timesel) or not FadeOutOK(prev_item, timesel) then
              -- previous item
              reaper.SetMediaItemSelected(prev_item, true)
              reaper.ApplyNudge(0, 1, 3, 1, sel_end, 0, 0)
              FadeOut(prev_item, timesel)
              reaper.SetMediaItemSelected(prev_item, false)
              -- item
              reaper.SetMediaItemSelected(item, true)
              reaper.ApplyNudge(0, 1, 1, 1, sel_start, 0, 0)
              FadeIn(item, timesel)
              reaper.SetMediaItemSelected(item, false)
              change = true
            end
          elseif geq(second_start, first_end) and leq(second_start, first_end + maximum_gap)
            then -- items are adjacent (or there is a gap smaller or equal to the crossfade time)
            Msg("adjacent - gap: " .. second_start - first_end)
            if not CrossfadeOK(item, prev_item, second_start, first_end) then
              -- previous item (ensure it ends exactly at the start of the next item)
              local groupid = reaper.GetMediaItemInfo_Value( prev_item, "I_GROUPID" )
              if groupid ~= 0 then
                reaper.SetMediaItemInfo_Value( prev_item, "I_GROUPID", 0 )
              end
              reaper.SetMediaItemSelected(prev_item, true)
              reaper.ApplyNudge(0, 1, 3, 1, second_start, 0, 0)
              FadeOut(prev_item, maximum_gap)
              reaper.SetMediaItemSelected(prev_item, false)
              if groupid ~= 0 then
                reaper.SetMediaItemInfo_Value( prev_item, "I_GROUPID", groupid )
              end
              -- item
              groupid = reaper.GetMediaItemInfo_Value( item, "I_GROUPID" )
              if groupid ~= 0 then
                reaper.SetMediaItemInfo_Value( item, "I_GROUPID", 0 )
              end
              reaper.SetMediaItemSelected(item, true)
              reaper.ApplyNudge(0, 1, 1, 1, second_start - maximum_gap, 0, 0)
              Msg(maximum_gap)
              FadeIn(item, maximum_gap)
              reaper.SetMediaItemSelected(item, false)
              if groupid ~= 0 then
                reaper.SetMediaItemInfo_Value( item, "I_GROUPID", groupid )
              end
              change = true
            end
          elseif first_end > second_start then -- items are overlapping
            local overlap = first_end - second_start
            Msg("overlap")
            if overlap > xfadetime then
              Msg("overlap > xfadetime")
              if not FadeInOK(item, overlap) or not FadeOutOK(prev_item, overlap) then
                FadeIn(item, overlap)
                FadeOut(prev_item, overlap)
                change = true
              end
            else
              Msg("overlap <= xfadetime")
              if not CrossfadeOK(item, prev_item, second_start, first_end) then
                -- previous item (fade out xfadetime)
                reaper.SetMediaItemSelected(prev_item, true)
                FadeOut(prev_item, xfadetime)
                reaper.SetMediaItemSelected(prev_item, false)
                -- extend second item so that it overlaps with previous one
                reaper.SetMediaItemSelected(item, true)
                reaper.ApplyNudge(0, 1, 1, 1, second_start - xfadetime + overlap, 0, 0)
                FadeIn(item, xfadetime)
                reaper.SetMediaItemSelected(item, false)
                change = true
              end
            end
          end
        end
      end
    end
  end
end

-- Re-enable trim behind items (if it was enabled)
if trimstate == 1 then
  reaper.Main_OnCommand(41120,0)
end

-- Undo point creation ----------------------------------------------------------------------------
if change then
  Msg("done")
  if keep_selected == 1 then -- keep selected the previously selected items
    for i = 1, item_cnt do
      reaper.SetMediaItemSelected(sel_item[i], true)
    end
  end
  local timesel_removed = 0
  if remove_timesel == 1 and timeselexists == 1 then -- remove time selection
    reaper.GetSet_LoopTimeRange(true, false, sel_start, sel_start, false)
    timesel_removed = 8
  end
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_OnStateChangeEx("Smart Crossfade selected items", 4|timesel_removed, -1)
else -- No undo
  Msg("nothing done")
  -- restore item selection
  for i = 1, item_cnt do
    reaper.SetMediaItemSelected(sel_item[i], true)
  end
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.defer(function() end)
end

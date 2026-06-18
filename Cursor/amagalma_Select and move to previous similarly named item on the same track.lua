-- @description Select and move to previous similarly named item on the same track
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma

local item = reaper.GetSelectedMediaItem( 0, 0 )
if not item then return end

local take = reaper.GetActiveTake( item )
local wanted_name = take and reaper.GetTakeName( take ) or ({reaper.GetSetMediaItemInfo_String( item, "P_NOTES", "", false )})[2]

local track = reaper.GetMediaItemTrack( item )
local previous_item_ip = reaper.GetMediaItemInfo_Value( item, "IP_ITEMNUMBER" ) - 1
if previous_item_ip < 0 then return end

local min, max = math.min, math.max

local function levenshtein_similarity(str1, str2) -- got it from Google Gemini
  if str1 == str2 then return 1 end
  local str1_len, str2_len = #str1, #str2
  if str1_len == 0 or str2_len == 0 then return 0 end

  local matrix = {}
  for i = 0, str1_len do
    matrix[i] = { [0] = i }
  end
  for j = 0, str2_len do
    matrix[0][j] = j
  end

  for i = 1, str1_len do
    for j = 1, str2_len do
      local cost = (str1:sub(i, i) == str2:sub(j, j)) and 0 or 1
      matrix[i][j] = min(
        matrix[i - 1][j] + 1,       -- deletion
        matrix[i][j - 1] + 1,       -- insertion
        matrix[i - 1][j - 1] + cost -- substitution
      )
    end
  end

  local distance = matrix[str1_len][str2_len]
  local max_len = max(str1_len, str2_len)
  
  -- Convert distance into a similarity percentage (0.0 to 1.0)
  return 1.0 - (distance / max_len)
end

for i = previous_item_ip, 0, -1 do
  local it = reaper.GetTrackMediaItem( track, i )
  local tk = reaper.GetActiveTake( it )
  local name = tk and reaper.GetTakeName( tk ) or ({reaper.GetSetMediaItemInfo_String( it, "P_NOTES", "", false )})[2]
  if levenshtein_similarity(wanted_name, name) >= 0.5 then
    reaper.Undo_BeginBlock2( 0 )
    reaper.PreventUIRefresh( 1 )
    reaper.SetEditCurPos( reaper.GetMediaItemInfo_Value( it, "D_POSITION" ), true, false )
    reaper.SelectAllMediaItems( 0 , 0 )
    reaper.SetMediaItemSelected( it, true )
    reaper.PreventUIRefresh( -1 )
    reaper.UpdateArrange()
    reaper.Undo_EndBlock2( 0, "Select previous similarly named item", 4 )
    break
  end
end

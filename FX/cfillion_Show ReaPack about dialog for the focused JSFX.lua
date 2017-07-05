-- @description Show ReaPack about dialog for the focused JSFX
-- @author cfillion
-- @version 0.1beta
-- @link https://cfillion.ca
-- @donation https://www.paypal.me/cfillion

local script = ({reaper.get_action_context()})[2]:match('([^/\\_]+).lua$')

function ShowMsg(msg)
  reaper.MB(msg, script, 0);
end

if not reaper.ReaPack_AboutInstalledPackage then
  return ShowMsg('ReaPack v1.2+ is required to use this script.')
end

local fxtype, trackidx, itemidx, fxidx = reaper.GetFocusedFX()

local getchunk = ({
  function()
    local track
    if trackidx == 0 then
      track =  reaper.GetMasterTrack(0)
    else
      track = reaper.GetTrack(0, trackidx - 1)
    end

    return reaper.GetTrackStateChunk(track, '')
  end,
  function()
    local track = reaper.GetTrack(0, trackidx - 1)
    local item = reaper.GetTrackMediaItem(track, itemidx)
    return reaper.GetItemStateChunk(item, '', false)
  end,
})[fxtype]
if not getchunk then return end

local ok, chunk = getchunk()
if not ok then return end

local name, type = ({function()
  local index = 0
  for type, file in chunk:gmatch("BYPASS %d+ %d+ %d+\n<([^%s]+) ([^\n]+)") do
    if index == fxidx then
      if type == 'JS' then
        if file:sub(1, 1) == '"' then
          return file:match('^"([^"]+)"'), type
        else
          return file:match('^[^%s]+'), type
        end
      else
        return nil, type
      end
    end
    
    index = index + 1
  end
end})[1]()
if not name then
  return ShowMsg(string.format('Documentation for %s plugins is not supported. Try again with a JSFX focused.', type))
end

local owner = reaper.ReaPack_GetOwner(string.format('Effects/%s', name))
if not owner then
  return ShowMsg(string.format("Documentation cannot be found because ReaPack does not know about the JSFX at '%s'.", name))
end

reaper.ReaPack_AboutInstalledPackage(owner)
reaper.ReaPack_FreeEntry(owner)

--[[
Description: Snap time selection or loop points to grid
Version: 1.0.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
  Initial release
Links:
  Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
  Provides actions for snapping the time selection or loop points to the grid.
  Requires the SWS extension.
Metapackage: true
Provides:
    [main] . > Lokasenna_Snap time selection to grid.lua
    [main] . > Lokasenna_Snap time selection start to grid.lua
    [main] . > Lokasenna_Snap time selection end to grid.lua
    [main] . > Lokasenna_Snap loop points to grid.lua
    [main] . > Lokasenna_Snap loop point start to grid.lua
    [main] . > Lokasenna_Snap loop point end to grid.lua
    [main] . > Lokasenna_Snap time selection to visible grid.lua
    [main] . > Lokasenna_Snap time selection start to visible grid.lua
    [main] . > Lokasenna_Snap time selection end to visible grid.lua
    [main] . > Lokasenna_Snap loop points to visible grid.lua
    [main] . > Lokasenna_Snap loop point start to visible grid.lua
    [main] . > Lokasenna_Snap loop point end to visible grid.lua
--]]

local function parseScriptName(scriptName)
  local isLoop = not not scriptName:match("loop point")
  local snapStart = not scriptName:match("end")
  local snapEnd = not scriptName:match("start")
  local useVisible = not not scriptName:match("visible")

  return isLoop, snapStart, snapEnd, useVisible
end

local function snapPosition(pos, useVisible)
  if useVisible then return reaper.SnapToGrid(0, pos) end

  if reaper.BR_GetClosestGridDivision then
    return reaper.BR_GetClosestGridDivision(pos)
  else
    reaper.MB("Sorry, this script requires the SWS extension for Reaper.", "Oops!", 0)
    return -1
  end
end

local function Main()
  local scriptName = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
  local isLoop, snapStart, snapEnd, useVisible = parseScriptName(scriptName)

  local startIn, endIn = reaper.GetSet_LoopTimeRange(false, isLoop, 0, 0, false)

  local startOut = snapStart and snapPosition(startIn, useVisible) or startIn
  local endOut = snapEnd and snapPosition(endIn, useVisible) or endIn

  if startOut == -1 or endOut == -1 then return end

  reaper.Undo_BeginBlock()
  reaper.GetSet_LoopTimeRange(true, isLoop, startOut, endOut, false)
  reaper.Undo_EndBlock(scriptName, 0)
end

Main()

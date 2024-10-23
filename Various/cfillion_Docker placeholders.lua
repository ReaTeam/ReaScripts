-- @description Docker placeholders
-- @author cfillion
-- @version 1.0
-- @link Request thread https://forum.cockos.com/showthread.php?p=2693350
-- @screenshot https://i.imgur.com/UxnT1pp.gif
-- @donation https://reapack.com/donate
-- @about
--   # Docker placeholders
--
--   Open a placeholder window in any of REAPER's 16 dockers.

local positions, placeholders = {
  [-1]='not found',
  [ 0]='bottom',
  [ 1]='left',
  [ 2]='top',
  [ 3]='right',
  [ 4]='floating'
}, {}

dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.8')

local ImGui = {}
for name, func in pairs(reaper) do
  name = name:match('^ImGui_(.+)$')
  if name then ImGui[name] = func end
end

local ctx = ImGui.CreateContext('Docker placeholder')

local function checkbox(id)
  local pos, toggled = positions[reaper.DockGetPosition(id)]
  local label = ('Docker %02d: %s'):format(id + 1, pos)
  toggled, placeholders[id] = ImGui.Checkbox(ctx, label, placeholders[id])
end

local function placeholder(id)
  ImGui.SetNextWindowDockID(ctx, ~id)
  local label = ('Docker %d'):format(id + 1)
  local visible, open = ImGui.Begin(ctx, label, true,
    ImGui.WindowFlags_NoSavedSettings() |
    ImGui.WindowFlags_NoFocusOnAppearing())
  if visible then
    ImGui.Text(ctx, label)
    ImGui.End(ctx)
  end
  if not open then
    placeholders[id] = false
  end
end

function loop()
  local visible, open = ImGui.Begin(ctx, 'Docker placeholders', true,
    ImGui.WindowFlags_AlwaysAutoResize())
  if visible then
    ImGui.PushTextWrapPos(ctx, 160)
    ImGui.Text(ctx, 'Click on a docker in the list below to open a placeholder window in that docker.')
    ImGui.PopTextWrapPos(ctx)
    ImGui.Spacing(ctx)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding(), 0, 0)
    for i=0,15 do checkbox(i) end
    ImGui.PopStyleVar(ctx)
    ImGui.End(ctx)
  end

  for id, checked in pairs(placeholders) do
    if checked then placeholder(id) end
  end

  if open then
    reaper.defer(loop)
  end
end

reaper.defer(loop)

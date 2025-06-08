-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

-- Functions and defines
local UTILS               = require "modules/utils"
local ACTIONS             = require "modules/actions"

-- Core
local MACCLContext        = require "modules/context"

-- Applicative
local MEContext           = require "classes/midi_editor_context"
local TabEditor           = require "classes/tab_editor"
local TabPopupMenu        = require "classes/tab_popup_menu"
local SettingsWindow      = require "classes/settings_window"
local MultiExportWindow   = require "classes/multi_export_window"

-- Redefine this global callback to avoid recursive require problems
MACCLContext.notifySettingsChange = function()
  MEContext.notifySettingsChange()
end

-----------------------

local function isMacclaneBitmap(identifier)
  local w = reaper.JS_LICE_GetWidth(identifier)
  return (reaper.JS_LICE_GetPixel(identifier, w-1, 0) == MACCLContext.MACCLANE_MAGIC_PIXEL)
end

-- We try to find if instances of macclane haven't left some bitmaps in the UI
-- Find them with the bottom right pixel, which should be equal to 0xDEADBEEF
local function LastChanceCleanupMaccLaneBitmaps()
  local delcount = 0
  local a, b = reaper.JS_LICE_ListAllBitmaps()
  for token in string.gmatch(b, "[^,]+") do
    local addr    = tonumber(token) or 0
    local subhwnd = reaper.JS_Window_HandleFromAddress(addr)
    if isMacclaneBitmap(subhwnd) then
      reaper.JS_LICE_DestroyBitmap(subhwnd)
      delcount = delcount + 1
    end
  end
  return delcount
end

local function hasPendingMouseEvents()
  for addr, mec in pairs(MEContext.all()) do
    if mec:hasPendingMouseEvents() then return true end
  end
  return false
end

local function hasPendingDrawOperations()
  for addr, mec in pairs(MEContext.all()) do
    if mec:hasPendingDrawOperations() then return true end
  end
  return false
end

local function tabsNeedReload()
  -- This flag is set on tab operations (save etc)
  for addr, mec in pairs(MEContext.all()) do
    if mec:tabsNeedReload() then return true end
  end
  return false
end

local function isHoveringAWidget()
  for addr, mec in pairs(MEContext.all()) do
    if mec.hovered then return true end
  end
  return false
end

local function needsImGuiContext()
  return TabEditor.needsImGuiContext() or TabPopupMenu.needsImGuiContext() or SettingsWindow.needsImGuiContext() or MultiExportWindow.needsImGuiContext()
end

local function ImGuiLoop()
  -- It takes like 1% CPU to maintain the ImGui ctx alive without any windows open
  -- So we will create it only if needed and close it only if needed
  if needsImGuiContext() then
    MACCLContext.EnsureImGuiCtx()
  else
    MACCLContext.DropImGuiCtx()
  end

  -- Show all tab editors
  TabEditor.processAll() -- Does nothing if no tab editor is open
  TabPopupMenu.process() -- Does nothing if no popu menu is open
  SettingsWindow.process() -- Does nothing if the settings window is not open
  MultiExportWindow.process() -- ' ' ' '
end

local function inputEventLoop()
  local mx, my                  = reaper.GetMousePosition()

  MACCLContext.mouse_stalled    = (mx == MACCLContext.last_mouse_x) and (my == MACCLContext.last_mouse_y)
  MACCLContext.last_mouse_x     = mx
  MACCLContext.last_mouse_y     = my
  MACCLContext.frame_time       = reaper.time_precise()

  for addr, mec in pairs(MEContext.all()) do
    mec:inputEventLoop()
  end
end

local function macclane()
  -- If first launch, force tab reloading by simulating a tab save
  if not MACCLContext.lastTabSavedAt then
    MACCLContext.lastTabSavedAt = reaper.time_precise()
  end

  -- First be sure that we get rid of non valid midi editor contexts
  MEContext.cleanupObsolete()

  -- Since we intercept the mouse events of the midi editor, we should run the mouse event loop
  -- every frame to be sure to repost non intercepted mouse events as soon as possible
  -- This is the only thing that we cannot skip
  inputEventLoop()

  -- Low CPU strategy, save the planet (and the user)
  -- Be less agressive when redraw is not really needed
  local reactivity = 0.3

  if isHoveringAWidget() or hasPendingMouseEvents() or hasPendingDrawOperations() or tabsNeedReload() then
    reactivity = -1
  elseif not MACCLContext.mouse_stalled then
    -- We want to be reactive when the mouse approaches the widget
    -- Maybe we can do something even more clever (like proximity detection)
    -- But hey, the main features are prior
    reactivity = 0.001
  else
    -- Be friendly on CPU.
  end

  -- Check if the current active ME has a context
  local cme  = reaper.MIDIEditor_GetActive()
  local cmec = MEContext.getContextForME(cme)

  -- This is were we create a context for a MIDI editor
  if not cmec then
    cmec = MEContext.createForME(cme)
    reactivity = -1
  end

  -- If the current midi editor changes its display mode (list view/piano/score/etc), fast update is needed
  local me_view_mode = reaper.MIDIEditor_GetMode(cmec.me)
  if me_view_mode ~= cmec.last_redraw_me_view_mode then
    reactivity = -1
  end

  local redraw_reactivity = 0.49

  if (not MACCLContext.last_processing) or not (MACCLContext.frame_time - MACCLContext.last_processing < reactivity) then
    MACCLContext.redrawn_widgets = 0

    -- Processing / Redraw pre-states. For a redraw if not redrawn till too long
    if not MACCLContext.last_forced_redraw or (MACCLContext.frame_time - MACCLContext.last_forced_redraw > redraw_reactivity) then
      MACCLContext.force_redraw         = true
      MACCLContext.last_forced_redraw   = MACCLContext.frame_time
      UTILS.perf_accum().forced_redraws = UTILS.perf_accum().forced_redraws + 1
    end

    -- Refresh MIDI editors
    -- Multiple MEs may be open at the same time and visible on the screen
    for addr, mec in pairs(MEContext.all()) do
      -- Check each midi editor's visibility before redrawing
      if reaper.JS_Window_IsVisible(mec.me) then
        MEContext.getCreateOrUpdate(mec.me)
        MACCLContext.redrawn_widgets = MACCLContext.redrawn_widgets + 1
      end
    end

    MACCLContext.force_redraw    = false
    MACCLContext.last_processing = MACCLContext.frame_time
  else
    -- Monitor frame skip
    UTILS.perf_accum().skipped = UTILS.perf_accum().skipped + 1
  end

  ImGuiLoop()

  ACTIONS.ProcessIncomingAction()
end

local function _macclane()

  -- Performances on my imac when idle, for reference
  --    Averages during one second (perf.sec1)
  --    - total_ms        : 4.5ms
  --    - usage_perc      : 0.45 % (same value *1000 (ms->s) /100 (perc) )
  --    - frames skipped  : 31/34
  --    - forced redraws  : 1-2 (redraw at low pace or when needed only)
  --
  ---@diagnostic disable-next-line: lowercase-global
  aaa_perf = UTILS.perf_ms(
  function()
    macclane()
  end
)
reaper.defer(_macclane)
end

local function UpdateToolbarButtonState(v)
  local _,_,sectionID,cmdID,_,_,_ = reaper.get_action_context()
  reaper.SetToggleCommandState(sectionID,cmdID,v)
  reaper.RefreshToolbar2(sectionID, cmdID)
end


local function run(args)
  UpdateToolbarButtonState(1)

  -- Define cleanup callbacks
  reaper.atexit(function()
    UpdateToolbarButtonState(0)
    MACCLContext.destroyFont()
    for addr, mec in pairs(MEContext.all()) do
      mec:implode()
    end
  end)

  -- Pre-clean possible leaked bitmaps, probably obsolete now
  LastChanceCleanupMaccLaneBitmaps()

  -- Pre-clean possible queued action
  ACTIONS.ClearQueuedAction()

  reaper.defer(_macclane)
end

return {
  run = run
}

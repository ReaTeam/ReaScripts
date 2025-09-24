-- @description Open associated editor/properties/subproject (respecting source type, multi-selection safe)
-- @author BIXI DOX & ChatGPT
-- @version 1.0
-- @about
--   # Open Items Explicit
--   This script reproduces and improves REAPER’s media item's “double-click item” default action:
--   - MIDI items → opened in the built-in MIDI editor (multi-selection consolidated automatically)
--   - Audio items → opened in the Media Item Properties dialog (multi-selection consolidated automatically)
--   - Subprojects → opened in new project tabs (multi-selection handled automatically by REAPER)
--
--   Unlike REAPER’s native double-click behavior, this script:
--   - Does not mess with current selection state
--   - Can be assigned to any key, toolbar button, or controller
--   - Runs as efficiently as possible (no redundant loops or reselection).


function open_items_explicit()
  local sel_count = reaper.CountSelectedMediaItems(0)
  if sel_count == 0 then return end

  local has_midi, has_subproj, has_audio = false, false, false

  -- Scan selected items for types
  for i = 0, sel_count-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    if take then
      local src = reaper.GetMediaItemTake_Source(take)
      local srctype = reaper.GetMediaSourceType(src, "")
      if srctype == "MIDI" or srctype == "MIDIPOOL" then
        has_midi = true
      elseif srctype == "RPP_PROJECT" then
        has_subproj = true
      else
        has_audio = true
      end
    end
  end

  -- MIDI: one call handles all selected MIDI
  if has_midi then
    reaper.Main_OnCommand(40153, 0) -- Open in built-in MIDI editor
  end

  -- Subprojects: one call handles all selected subprojects
  if has_subproj then
    reaper.Main_OnCommand(41816, 0) -- Open project(s) in new tab(s)
  end

  -- Audio: one call handles all selected audio items
  if has_audio then
    reaper.Main_OnCommand(40009, 0) -- Item properties: Show media item properties
  end
end

reaper.Undo_BeginBlock()
open_items_explicit()
reaper.Undo_EndBlock("Open selected items in appropriate editors/properties", -1)


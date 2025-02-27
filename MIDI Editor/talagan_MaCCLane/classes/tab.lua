-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local S               = require "modules/settings"
local UTILS           = require "modules/utils"
local MACCLContext    = require "modules/context"
local VELLANE         = require "modules/vellane"
local CHUNK           = require "modules/chunk"
local EXT             = require "ext/dependencies"
local DOCKING_LIB     = require (EXT.DOCKING_TOOLS_PATH)

local PIANOROLL       = require "modules/piano_roll"

local TabParams       = require "modules/tab_params"

local Tab = {}
Tab.__index = Tab

Tab.Types = {
  TRACK     = "track",
  ITEM      = "item",
  PROJECT   = "project",
  PLUS_TAB  = "__add_tab__"
}

function Tab:new(owner, params)
  local instance = {}
  setmetatable(instance, self)
  instance:_initialize(owner, params)
  return instance
end

function Tab:_initialize(owner, params)
  self:setOwner(owner)

  -- Ensure that we don't go gardening into someone else's territory
  params = UTILS.deepcopy(params)

  self.new_record     = true
  self.uuid           = UTILS.drawUUID()
  self.params         = params or { title = "New Tab" }

  self:_sanitize()

  self:undirty()
end

-- Make sure a tab is initialized correctly
-- This function is always call when creating a new tab
-- Or loading it from a serialized description
-- So all backward compatibility should be handled here
-- As well as default value assignments
function Tab:_sanitize()

  self.params.title             = self.params.title or "???"

  self.params.priority          = self.params.priority or 0

  self.params.color             = self.params.color or {}
  self.params.color.mode        = self.params.color.mode or 'bypass'
  self.params.color.color       = self.params.color.color or 0xFFFFFFFF

  self.params.margin            = self.params.margin or {}
  self.params.margin.mode       = self.params.margin.mode or 'bypass'
  self.params.margin.margin     = self.params.margin.margin or 10

  -- Dimensions / Position
  self.params.docking           = self.params.docking or {}
  self.params.docking.mode      = self.params.docking.mode or 'bypass'

  self.params.docking.if_docked      = self.params.docking.if_docked or {}
  self.params.docking.if_docked.mode = self.params.docking.if_docked.mode or 'bypass'
  self.params.docking.if_docked.size = self.params.docking.if_docked.size or 500

  self.params.docking.if_windowed        = self.params.docking.if_windowed or {}
  self.params.docking.if_windowed.mode   = self.params.docking.if_windowed.mode or 'bypass'
  self.params.docking.if_windowed.coords = self.params.docking.if_windowed.coords or { x=0, y=0, w=800, h=600 }

  -- CC Lanes
  self.params.cc_lanes          = self.params.cc_lanes          or {}
  self.params.cc_lanes.mode     = self.params.cc_lanes.mode     or 'bypass'
  self.params.cc_lanes.entries  = self.params.cc_lanes.entries  or {}

  for i,v in pairs(self.params.cc_lanes.entries) do
    v.height           = v.height or 0
    v.inline_ed_height = v.inline_ed_height or 0
    v.zoom_factor      = v.zoom_factor or 1
    v.zoom_offset      = v.zoom_offset or 0
  end

  -- Piano Roll
  self.params.piano_roll                  = self.params.piano_roll or {}
  self.params.piano_roll.mode             = self.params.piano_roll.mode or 'bypass'
  self.params.piano_roll.low_note         = self.params.piano_roll.low_note or 0
  self.params.piano_roll.high_note        = self.params.piano_roll.high_note or 127
  self.params.piano_roll.fit_time_scope   = self.params.piano_roll.fit_time_scope or 'visible'
  self.params.piano_roll.fit_owner_scope  = self.params.piano_roll.fit_owner_scope or 'track'
  self.params.piano_roll.fit_chan_scope   = self.params.piano_roll.fit_chan_scope or -2

  -- Midi Chans
  self.params.midi_chans            = self.params.midi_chans or {}
  self.params.midi_chans.mode       = self.params.midi_chans.mode or 'bypass'
  self.params.midi_chans.bits       = self.params.midi_chans.bits or 0
  self.params.midi_chans.current    = self.params.midi_chans.current or 'bypass'

  -- Actions
  self.params.actions               = self.params.actions or {}
  self.params.actions.mode          = self.params.actions.mode or 'bypass'
  self.params.actions.entries       = self.params.actions.entries  or {}

  for i,v in pairs(self.params.actions.entries) do
    v.section = v.section or 'main'
    v.id      = v.id or 0
    v.when    = v.when or 'after'
  end
end

-- Mark the record as non dirty
-- and snapshot clean states
function Tab:undirty()
  self.owner_before_save      = self.owner
  self.owner_type_before_save = self.owner_type
end

function Tab:UUID()
  return self.uuid
end

function Tab:setOwner(entity)
  if entity == nil or entity == 0 then
    self.owner      = nil
    self.owner_type = Tab.Types.PROJECT
  elseif reaper.ValidatePtr(entity, "MediaItem*") then
    self.owner      = entity
    self.owner_type = Tab.Types.ITEM
  elseif reaper.ValidatePtr(entity, 'MediaTrack*') then
    self.owner      = entity
    self.owner_type = Tab.Types.TRACK
  else
    error("Trying to set wrong owner to tab")
  end
end


function Tab:isOwnerStillValid()
  if self.owner_type == Tab.Types.PROJECT then return true end
  if self.owner_type == Tab.Types.ITEM    then return reaper.ValidatePtr(self.owner, "MediaItem*") end
  if self.owner_type == Tab.Types.TRACK   then return reaper.ValidatePtr(self.owner, "MediaTrack*") end

  return false
end

function Tab:ownerInfo()

  if self.owner_type == Tab.Types.PROJECT then
    return {
      type = self.owner_type,
      desc = "Project"
    }
  elseif self.owner_type == Tab.Types.ITEM    then
    local track = reaper.GetMediaItemTrack(self.owner)
    local _, tname = reaper.GetTrackName(track)
    -- TODO : Items don't have names !
    return {
      type = self.owner_type,
      desc = "Project > Track " .. tname .. " > Item"
    }
  elseif self.owner_type == Tab.Types.TRACK   then
    local track     = self.owner
    local _, tname  = reaper.GetTrackName(track)
    return {
      type = self.owner_type,
      desc = "Project > Track " .. tname
    }
  end

  return nil
end

function Tab:afterSave()
  self.new_record              = false
  MACCLContext.lastTabSavedAt  = reaper.time_precise()
  self:undirty()
end

function Tab:removeFromOwner(owner_type, owner)
  local all_owner_tabs = Serializing.loadTabsFromEntity(owner_type, owner)
  all_owner_tabs[self:UUID()] = nil
  Serializing.saveTabsToEntitity(owner_type, owner, all_owner_tabs)
end

function Tab:save()
  -- Maybe we should do more than fail silently
  if not self:isOwnerStillValid() then return { success=false, errors={"Tab's owner is not valid anymore"}} end

  -- TODO : Validate ?

  -- If owner is changing, it should be removed from precedent owner !
  if not (self.owner_before_save == self.owner) then
    self:removeFromOwner(self.owner_type_before_save, self.owner_before_save)
  end

  -- Perform read/modify/write on owner
  local all_owner_tabs = Serializing.loadTabsFromEntity(self.owner_type, self.owner)
  all_owner_tabs[self:UUID()] = { uuid=self:UUID(), params=self.params }
  Serializing.saveTabsToEntitity(self.owner_type, self.owner, all_owner_tabs)

  self:afterSave()

  return { success=true, errors={} }
end

function Tab:destroy()
  -- Maybe we should do more than fail silently
  if not self:isOwnerStillValid() then return { success=false, errors={"Tab's owner does not valid anymore"}} end

  local all_owner_tabs = Serializing.loadTabsFromEntity(self.owner_type, self.owner)
  all_owner_tabs[self:UUID()] = nil
  Serializing.saveTabsToEntitity(self.owner_type, self.owner, all_owner_tabs)

  self:afterSave()
  return { success=true, errors={} }
end

function Tab:textWidth()
  -- Memoize the tab width to avoid recaclulations
  if not (self._last_text_for_metrics) or not (self._last_text_for_metrics == self.params.title) then
    -- Could observe the same bug as FTC in lilchordbox with JS_LICE_MeasureText
    -- Thanks @FeedTheCat for the workaround

    self._last_text_for_metrics = self.params.title

    local use_gfx = true
    if use_gfx then
      -- gfx.setfont(1, MACCLContext.FONT_FACE, MACCLContext.FONT_SIZE)
      self._precalc_text_width = gfx.measurestr(self._last_text_for_metrics)
    else
      local tw, th  = reaper.JS_LICE_MeasureText(self._last_text_for_metrics)
      self._precalc_text_width = tw
    end
  end

  return self._precalc_text_width
end

function Tab:width()
  local margin = S.getSetting("TabMargin")
  if self.params.margin.mode == 'overload' then
    margin = self.params.margin.margin
  end
  return 2 * margin + self:textWidth()
end

function Tab:height()
  return MACCLContext.TABBAR_HEIGHT
end

function Tab:textHeight()
  return 15
end

function Tab:colors(mec, is_hovered)
  local alpha     = (is_hovered and 1.0 or 0.5)
  local tab_type  = self.owner_type
  local tabcol    = 0xFFFFFFFF -- reaper.GetThemeColor("docker_unselface") | 0xFF000000

  if self.params.color.mode == 'overload' then
    tabcol = self.params.color.color | 0xFF00000000
  else
    if tab_type == Tab.Types.TRACK then
      local  take = reaper.MIDIEditor_GetTake(mec.me)
      if take then
        local track = reaper.GetMediaItemTake_Track(take)
        tabcol = reaper.GetTrackColor(track) | 0xFF000000
      end
    elseif tab_type == Tab.Types.ITEM then
      local  take = reaper.MIDIEditor_GetTake(mec.me)
      if take then
        local item = reaper.GetMediaItemTake_Item(take)
        tabcol = reaper.GetMediaItemInfo_Value(item, "I_CUSTOMCOLOR") | 0xFF000000
      end
    elseif tab_type == Tab.Types.PLUS_TAB then
      tabcol = 0xFFFFFFFF
    else
      -- Project or __special__
    end
  end

  local bgluma =  0.299 * ((tabcol & 0x00FF0000) >> 16) +
  0.587 * ((tabcol & 0x0000FF00) >> 8) +
  0.114 * ((tabcol & 0x000000FF)) * alpha

  local fontcol = (bgluma > 127) and 0xFF000000 or 0xFFFFFFFF

  return tabcol, alpha, fontcol
end

function Tab:isRound()
  return false
end

function Tab:pointIntab(_x, _y)
  local mec = self.mec

  if not mec          then return false end
  if not self.last_x  then return false end
  if not self.last_y  then return false end
  if not mec.xpos     then return false end

  local xinwin = self.last_x + mec.xpos
  local yinwin = self.last_y + mec.ypos

  local fullh   = self:height()
  local fullw   = self:width()

  _x = _x + mec.scrollOffset

  return (_x >= xinwin) and
  (_x <= xinwin + fullw - 1) and
  (_y >= yinwin) and
  (_y <= yinwin + fullh - 1)
end

function Tab:update(mec, x)
  self.mec      = mec
  self.last_x   = x
  self.last_y   = 0

  self.fullh   = self:height()
  self.fullw   = self:width()
end


function Tab:draw(mec, x)

  self:update(mec, x)

  local mec     = self.mec
  local text    = self.params.title

  local th      = self:textHeight()
  local tw      = self:textWidth()

  local fullw   = self.fullw
  local fullh   = self.fullh

  -- Position for drawing text
  local tx, ty  = self.last_x + math.floor(0.5 * (fullw - tw)), 3

  local tlen    = #text
  local font    = MACCLContext.lice_font

  self.last_draw_global_x, self.last_draw_global_y = reaper.JS_Window_ClientToScreen(mec.me, self.last_x + mec.xpos - mec.scrollOffset, self.last_y + mec.ypos)

  local is_hovering             = self:pointIntab(mec.mouse_x, mec.mouse_y)
  local tabcol, alpha, fontcol  = self:colors(mec, is_hovering)

  if self:isRound() then
    local rad = math.floor(fullw/2)
    reaper.JS_LICE_FillCircle(mec.bitmap, self.last_x + rad,  self.last_y + rad,  rad - 2, tabcol, alpha, "COPY", false)
  else
    reaper.JS_LICE_FillRect(mec.bitmap,   self.last_x,        self.last_y,        fullw, fullh, tabcol, alpha, "COPY")
  end

  -- Font color
  reaper.JS_LICE_SetFontColor(font, fontcol)

  -- It looks like rawtext needs a bit more latitude than what is given ... empiric values for w/h
  reaper.JS_LICE_DrawText(mec.bitmap, font, text, tlen , tx, ty, tx+tw+5, ty+th*2)

  -- Handle left click
  local pc = mec.pending_left_click
  if pc and self:pointIntab(mec.pending_left_click.x, mec.pending_left_click.y) then
    pc.handled = true
    self:onLeftClick(mec, mec.pending_left_click.x, mec.pending_left_click.y)
  end

  -- Handle right click
  local prc = mec.pending_right_click
  if prc and self:pointIntab(mec.pending_right_click.x, mec.pending_right_click.y) then
    prc.handled = true
    self:onRightClick(mec, mec.pending_right_click.x, mec.pending_right_click.y)
  end

  return fullw
end

-- Use VELLANE.readVellanesFromChunk to get the current context for an item's chunk
function Tab:patchVellaneEntriesForItem(item_vellane_ctx)
  local existing_entries  = item_vellane_ctx.entries
  local new_entries       = self.params.cc_lanes.entries

  -- TODO : Better logic (here we simply replace all stuff ...)
  item_vellane_ctx.entries = new_entries
end

function Tab:_executeActions(when)
  local mec = self.mec
  for _, entry in ipairs(self.params.actions.entries) do
    if entry.when == when then
      local id    = reaper.NamedCommandLookup(entry.id)
      if id then
        if entry.section == 'main' then
          reaper.ShowConsoleMsg("MAIN")
          reaper.Main_OnCommand(id, 0)
        else
          reaper.MIDIEditor_OnCommand(mec.me, id)
        end
      end
    end
  end
end

function Tab:_processLayouting()
  local mec = self.mec
  local me_section = TabParams.ActionSection:entryByName('midi_editor').v
  local is_docked  = (reaper.GetToggleCommandStateEx(me_section, 40018) == 1)

  if self.params.docking.mode == 'docked' then
    if not is_docked then
      reaper.MIDIEditor_OnCommand(mec.me, 40018)
    end
  elseif self.params.docking.mode == 'windowed' then
    if is_docked then
      reaper.MIDIEditor_OnCommand(mec.me, 40018)
    end
  end
  is_docked  = (reaper.GetToggleCommandStateEx(me_section, 40018) == 1)

  if is_docked then
    local dock = DOCKING_LIB.findDockThatContainsWindow(mec.me)
    if self.params.docking.if_docked.mode == 'maximize' then
      DOCKING_LIB.resizeDock(dock, 'max')
    elseif self.params.docking.if_docked.mode == 'minimize' then
      DOCKING_LIB.resizeDock(dock, 'min')
    elseif self.params.docking.if_docked.mode == 'custom' then
      local size = self.params.docking.if_docked.size
      if size ~= 'min' and size ~= 'max' and not tonumber(size) then
      else
        DOCKING_LIB.resizeDock(dock, size)
      end
    end
  end

  local is_windowed = not is_docked
  if is_windowed then
    local coords = self.params.docking.if_windowed.coords
    if self.params.docking.if_windowed.mode == 'custom' then
      if MACCLContext.is_windows then
        local truey = coords.y - coords.h
        reaper.JS_Window_SetPosition(self.mec.me, coords.x, truey, coords.w, coords.h)
      else
        reaper.JS_Window_SetPosition(self.mec.me, coords.x, coords.y, coords.w, coords.h)
      end
    end
  end
end

function Tab:_processVellanes()
  local mec = self.mec
  if self.params.cc_lanes.mode == 'custom' then
    local item_chunk    = CHUNK.getItemChunk(mec.item)
    local vellane_ctx   = VELLANE.readVellanesFromChunk(item_chunk)

    self:patchVellaneEntriesForItem(vellane_ctx)

    VELLANE.applyNewVellanes(vellane_ctx)

    reaper.SetItemStateChunk(mec.item, vellane_ctx.chunk, false)
  end
end

function Tab:_processMidiChans()
  local mec = self.mec
  if self.params.midi_chans.current ~= 'bypass' then
    -- "Set channel for new events on channel X"
    reaper.MIDIEditor_OnCommand(mec.me, 40482 + self.params.midi_chans.current)
  end

  local ACTION_SHOW_ALL_MIDI_CHANS = 40217
  local ACTION_TOGGLE_MIDI_CHAN    = 40643
  if self.params.midi_chans.mode == 'custom' then
    -- Show all channels : this clears all bits and set the "all" flag
    -- we can then set things individually
    reaper.MIDIEditor_OnCommand(mec.me, ACTION_SHOW_ALL_MIDI_CHANS)

    -- Then untoggle those that should not be here
    for i=0, 15 do
      local is_chan_available = not ((self.params.midi_chans.bits & (1 << i)) == 0)
      if is_chan_available then
        reaper.MIDIEditor_OnCommand(mec.me, ACTION_TOGGLE_MIDI_CHAN + i) -- i starts at 0 so it's ok
      end
    end
  end
end

function Tab:_processPianoRoll()
  local mec = self.mec

  if self.params.piano_roll.mode == 'custom' then
    PIANOROLL.setRange(mec.me, self.params.piano_roll.low_note, self.params.piano_roll.high_note)
  elseif self.params.piano_roll.mode == 'fit' then

    local me_start, me_end, _ = UTILS.GetMIDIEditorHBounds(mec.me)
    local h                   = nil
    local l                   = nil
    local chan_bits           = self:getActiveChanBits()

    local function noteOk(take, muted, start, stop, chan)
      local muteok = (not muted)
      local posok  = true

      local chanok = false

      if self.params.piano_roll.fit_chan_scope == -1 then        -- All chans
        chanok = true
      elseif self.params.piano_roll.fit_chan_scope == -2 then  -- All VISIBLE chans
        -- Chans are numbered from 0 to 15 and stored as such in chan_bits
        chanok = (chan_bits & (1 << chan) ~= 0)
      else
        -- Individual chan. Beware, fit_chan_scope stores chans from 1 to 16
        chanok = (chan == self.params.piano_roll.fit_chan_scope)
      end

      if self.params.piano_roll.fit_time_scope == 'visible' then
        start = reaper.MIDI_GetProjTimeFromPPQPos(take, start)
        stop  = reaper.MIDI_GetProjTimeFromPPQPos(take, stop)
        posok = (start >= me_start and start <= me_end) or (stop >= me_start and stop <= me_end) or (start <= me_start and stop >= me_end)
      end

      return muteok and posok and chanok
    end

    local function itemElligible(item)
      if self.params.piano_roll.fit_time_scope == 'everywhere' then return true end
      local ts = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local te = ts + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      return (ts >= me_start and ts <= me_end) or (te >= me_start and te <= me_end) or (ts <= me_start and te >= me_end)
    end

    local function processTake(take)
      local i = 0
      while true do
        local b, _, muted, start, stop, chan, pitch, _ = reaper.MIDI_GetNote(take, i)
        if (not b) then break end

        if noteOk(take, muted, start, stop, chan) then
          if (not h) or (pitch > h) then h = pitch end
          if (not l) or (pitch < l) then l = pitch end
        end
        i = i + 1
      end
    end

    if self.params.piano_roll.fit_owner_scope == 'take' then
      if itemElligible(mec.item) then
        processTake(mec.take)
      end
    elseif self.params.piano_roll.fit_owner_scope == 'track' then
      -- Iterate over track > all items > all takes
      local it_count = reaper.CountTrackMediaItems(mec.track)
      for i=0, it_count-1 do
        local item = reaper.GetTrackMediaItem(mec.track, i)
        if itemElligible(item) then
          local tk_count = reaper.CountTakes(item)
          for ti=0, tk_count-1 do
            local take = reaper.GetTake(item, ti)
            processTake(take)
          end
        end
      end
    elseif self.params.piano_roll.fit_owner_scope == 'takes' then
      -- Iterate over all tracks > all items > all takes
      local i = 0
      while true do
        local take = reaper.MIDIEditor_EnumTakes(mec.me, i, false)
        if not take then break end

        local item = reaper.GetMediaItemTake_Item(take)

        -- Check bounds
        if itemElligible(item) then
          processTake(take)
        end

        i = i + 1
      end
    end

    if h and l then PIANOROLL.setRange(mec.me, l - 1, h + 1) end
  end
end

function Tab:_protectedLeftClick(mec, x, y)
  -- Start by executing pre-actions
  if self.params.actions.mode == 'custom' then
    self:_executeActions('before')
  end

  -- Order is important
  self:_processLayouting()
  self:_processVellanes()
  self:_processMidiChans()
  self:_processPianoRoll()

  -- Execute post-actions
  if self.params.actions.mode == 'custom' then
    self:_executeActions('after')
  end
end

function Tab:onLeftClick(mec, x, y)
  if not mec.item then return end

  local tab = self

  local b, err = pcall(Tab._protectedLeftClick, self, mec, x, y)
  if not b then
    -- Unfortunately, pcall is not sufficient if the crash happens inside Main_OnCommand
    -- The problem is that call subssequent calls to reaper will fail, so afterwards
    -- MaCCLane will quit silently and I don't have a solution yet
    reaper.MB("Something nasty happend with this tab. Please check the console for more info", "Ouch !", 0)
    reaper.ShowConsoleMsg(err .. '\n\nTrace :\n\n' .. debug.traceback())
  end
end

function Tab:onRightClick(mec, x, y)
  --  mec:openTabEditorOn(self)
  mec:openTabContextMenuOn(self)
end

function Tab:readCurrentPianoRollLowNote()
  local mec    = self.mec
  local params = self.params.piano_roll
  local l, h = PIANOROLL.range(mec.me)
  if l and h then
    params.low_note  = l
  end
end

function Tab:readCurrentPianoRollHighNote()
  local mec    = self.mec
  local params = self.params.piano_roll
  local l, h = PIANOROLL.range(mec.me)
  if l and h then
    params.high_note  = h
  end
end

function Tab:getActiveChanBits()
  local ACTION_TOGGLE_MIDI_CHAN = 40643
  local bits = 0
  for i=0, 15 do
    local res = reaper.GetToggleCommandStateEx(TabParams.ActionSection:entryByName('midi_editor').v, ACTION_TOGGLE_MIDI_CHAN + i) -- i starts at 0 so it's ok
    if res == 1 then                      -- Set the bit
      bits = bits | (1 << (i))
    end
  end

  -- Reaper does not allow to have zero active chans.
  if bits == 0 then
    bits = 0xFFFF
  end

  return bits
end

function Tab:readMidiChans()
  local params = self.params.midi_chans
  params.bits  = self:getActiveChanBits()
end

function Tab:readWindowBounds()
  local bounds = UTILS.JS_Window_GetBounds(self.mec.me, true)
  self.params.docking.if_windowed.coords.x = bounds.l
  self.params.docking.if_windowed.coords.y = bounds.b
  self.params.docking.if_windowed.coords.w = bounds.w
  self.params.docking.if_windowed.coords.h = bounds.h
end

function Tab:readDockHeight()
  local bounds = UTILS.JS_Window_GetBounds(self.mec.me, false)
  self.params.docking.if_docked.size = bounds.h + 20 -- For the bottom tab bar
end

----------------------

function Tab.ownerTypePriority(type)
  if type == Tab.Types.PROJECT then
    return 0
  elseif type == Tab.Types.TRACK then
    return 1
  elseif type == Tab.Types.ITEM then
    return 2
  else
    return 42
  end
end

function Tab.sort_pti_prio(tabs)
  return table.sort(tabs, function(t1, t2)
    if t1.owner_type == t2.owner_type then
      if t1.params.priority == t2.params.priority then
        -- Alphabetically
        return t1.params.title:lower() < t2.params.title:lower()
      else
        -- Priority
        return t1.params.priority < t2.params.priority
      end
    else
      -- Tab type
      return Tab.ownerTypePriority(t1.owner_type) < Tab.ownerTypePriority(t2.owner_type)
    end
  end)
end

function Tab.sort_pti_alpha(tabs)
  return table.sort(tabs, function(t1, t2)
    if t1.owner_type == t2.owner_type then
      if t1.params.title:lower() == t2.params.title:lower() then
        return t1.params.priority < t2.params.priority
      else
        return t1.params.title:lower() < t2.params.title:lower()
      end
    else
      -- Tab type
      return Tab.ownerTypePriority(t1.owner_type) < Tab.ownerTypePriority(t2.owner_type)
    end
  end)
end

function Tab.sort_mixed_prio(tabs)
  return table.sort(tabs, function(t1, t2)
    if t1.params.priority == t2.params.priority then
      -- Alphabetically
      return t1.params.title:lower() < t2.params.title:lower()
    else
      -- Priority
      return t1.params.priority < t2.params.priority
    end
  end)
end

function Tab.sort_mixed_alpha(tabs)
  return table.sort(tabs, function(t1, t2)
    if t1.params.title:lower() == t2.params.title:lower() then
      -- Priority
      return t1.params.priority < t2.params.priority
    else
      -- Alphabetically
      return t1.params.title:lower() < t2.params.title:lower()
    end
  end)
end


function Tab.sort(tabs)
  local strat = S.getSetting("SortStrategy")

  if strat == 'mixed_prio' then
    return Tab.sort_mixed_prio(tabs)
  elseif strat == 'mixed_alpha' then
    return Tab.sort_mixed_alpha(tabs)
  elseif strat == 'pti_alpha' then
    return Tab.sort_pti_alpha(tabs)
  elseif strat == 'pti_prio' then
    return Tab.sort_pti_prio(tabs)
  else
    -- Case default ???
    return Tab.sort_pti_prio(tabs)
  end

end

return Tab

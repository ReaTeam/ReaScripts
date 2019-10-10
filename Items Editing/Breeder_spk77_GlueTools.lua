-- @description Glue Tools
-- @version 1.01
-- @author Breeder, spk77
-- @website http://forum.cockos.com/showthread.php?t=160061
-- @changelog:
--      + Save XY position (saved after click anywhere in the script)
--      + Save checkbox states (http://github.com/ReaTeam/ReaScripts/issues/125)

-- (C) 2015, Dominik Martin Drzic

local conf = {}  
local glue_btn = {}
-- Misc functions ------------------------------------------------------------------------------------------------------
local function SetToBounds (val, min, max)
  if min > max then
    min, max = max, min
  end

  if      val < min then return min
  elseif  val > max then return max
  else                   return val
  end
end

local function CheckBounds (val, min, max)
  return (val >= min and val <= max)
end

local function AreOverlapped (start1, end1, start2, end2)
  if start1 > end1 then start1, end1 = end1, start1 end
  if start2 > end2 then start2, end2 = end2, start2 end
  return (start1 <= end2 and start2 <= end1)
end

-- Save/restore muted MIDI events --------------------------------------------------------------------------------------
local function SaveMutedNotesToTable (table, take, itemStartPPQ, itemEndPPQ, sourceLenPPQ, looped)
  local id        = #table
  local noteCount = ({reaper.MIDI_CountEvts(take, 0, 0, 0)})[2]

  for i = 0, noteCount-1 do
    local _, _, muted, startPos, endPos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    if muted then
      while (startPos <= itemEndPPQ) do
        id = id + 1
        table[id] = {}
        table[id].type     = "Note"
        table[id].startPos = reaper.MIDI_GetProjTimeFromPPQPos(take, SetToBounds(startPos, itemStartPPQ, itemEndPPQ))
        table[id].endPos   = reaper.MIDI_GetProjTimeFromPPQPos(take, SetToBounds(endPos,   itemStartPPQ, itemEndPPQ))
        table[id].chan     = chan
        table[id].pitch    = pitch
        table[id].vel      = vel
        if looped then
          startPos, endPos = startPos + sourceLenPPQ, endPos + sourceLenPPQ
        else
          break
        end
      end
    end
  end
end

local function SaveMutedCCToTable (table, take, itemStartPPQ, itemEndPPQ, sourceLenPPQ, looped)
  local id      = #table
  local ccCount = ({reaper.MIDI_CountEvts(take, 0, 0, 0)})[3]

  for i = 0, ccCount-1 do
    local _, _, muted, startPos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, i)
    if muted then
      while (startPos <= itemEndPPQ) do
        id = id + 1
        table[id] = {}
        table[id].type     = "CC"
        table[id].startPos = reaper.MIDI_GetProjTimeFromPPQPos(take, SetToBounds(startPos, itemStartPPQ, itemEndPPQ))
        table[id].chanmsg  = chanmsg
        table[id].chan     = chan
        table[id].msg2     = msg2
        table[id].msg3     = msg3
        if looped then
          startPos = startPos + sourceLenPPQ
        else
          break
        end
      end
    end
  end
end

local function SaveMutedSysTextToTable (table, take, itemStartPPQ, itemEndPPQ, sourceLenPPQ, looped)
  local id           = #table
  local sysTextCount = ({reaper.MIDI_CountEvts(take, 0, 0, 0)})[4]

  for i = 0, sysTextCount-1 do
    local _, _, muted, startPos, sysType, string = reaper.MIDI_GetTextSysexEvt(take, i)
    if muted then
      while (startPos <= itemEndPPQ) do
        id = id + 1
        table[id] = {}
        table[id].type     = "TextSys"
        table[id].startPos = reaper.MIDI_GetProjTimeFromPPQPos(take, SetToBounds(startPos, itemStartPPQ, itemEndPPQ))
        table[id].sysType  = sysType
        table[id].string   = string
        if looped then
          startPos = startPos + sourceLenPPQ
        else
          break
        end
      end
    end
  end
end

local function SaveMutedEventsToTable (table, take)
  if reaper.BR_IsTakeMidi(take, 0) then
    local item  = reaper.GetMediaItemTake_Item(take)
    local itemStartPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.GetMediaItemInfo_Value(item, "D_POSITION"))
    local itemEndPPQ   = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_LENGTH"))
    local sourceLenPPQ = reaper.BR_GetMidiSourceLenPPQ(take)
    local looped       = reaper.GetMediaItemInfo_Value(item, "B_LOOPSRC") == 1

    local track = reaper.GetMediaItemTake_Track(take)
    if (table[track] == nil) then table[track] = {} end

    -- Muted events are saved regardless of item mix behavior in case of overlapping items
    SaveMutedNotesToTable(table[track], take, itemStartPPQ, itemEndPPQ, sourceLenPPQ, looped)
    SaveMutedCCToTable(table[track], take, itemStartPPQ, itemEndPPQ, sourceLenPPQ, looped)
    SaveMutedSysTextToTable(table[track], take, itemStartPPQ, itemEndPPQ, sourceLenPPQ, looped)
  end
end

local function SaveMutedEventsInSelectedItems (table)
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    local item = reaper.GetSelectedMediaItem(0, i)

    if reaper.GetMediaItemInfo_Value(item, "B_ALLTAKESPLAY") == 1 then
      for j = 0, reaper.CountTakes(item)-1 do
        SaveMutedEventsToTable(table, reaper.GetTake(item, j))
      end
    else
      SaveMutedEventsToTable(table, reaper.GetActiveTake(item))
    end
  end
end

local function RestoreMutedMidiEventsToSelectedItems (table)
  for i = 0, reaper.CountTracks(0)-1 do
    local track = reaper.GetTrack(0, i)
    if table[track] ~= nill and #table[track] > 0 then

      -- Get all selected items in a track first (so we don't have to iterate through table multiple times for each item)
      local items = {}
      local itemsSize = 0
      for j = 0, reaper.CountTrackMediaItems(track)-1 do
        local item = reaper.GetTrackMediaItem(track, j)
        local take = reaper.GetActiveTake(item)
        if reaper.GetMediaItemInfo_Value(item, "B_UISEL") == 1 and reaper.BR_IsTakeMidi(take, 0) then
          items[itemsSize+1] = {}
          items[itemsSize+1].activeTake   = take
          items[itemsSize+1].startTime    = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
          items[itemsSize+1].endTime      = reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
          items[itemsSize+1].needsSorting = false
          itemsSize = itemsSize + 1
        end
      end

      -- Insert muted events in all selected items in track
      local events   = table[track]
      for id in ipairs(events) do
        for index, _ in ipairs(items) do

          -- Check if event fits into current item (in case of MIDI note, if part of the note fits, bound it to item end position)
          local validForInsertion = false
          local startPos = events[id].startPos
          local endPos   = 0
          local take     = items[index].activeTake
          if reaper.BR_IsTakeMidi(take, 0) and startPos <= items[index].endTime then
            local itemStartTime = items[index].startTime
            local itemEndTime   = items[index].endTime
            if events[id].type == "Note" then
              startPos = SetToBounds(startPos,          itemStartTime, itemEndTime)
              endPos   = SetToBounds(events[id].endPos, itemStartTime, itemEndTime)
              validForInsertion = (endPos - startPos) > 0
            else
              validForInsertion = CheckBounds(startPos, itemStartTime, itemEndTime)
            end
          end

          -- Insert event
          if validForInsertion then
            startPos = reaper.MIDI_GetPPQPosFromProjTime(take, startPos)
            if events[id].type == "Note" then
              reaper.MIDI_InsertNote(take, false, true, startPos, reaper.MIDI_GetPPQPosFromProjTime(take, endPos), events[id].chan, events[id].pitch, events[id].vel, true)
            elseif events[id].type == "CC" then
              reaper.MIDI_InsertCC(take, false, true, startPos, events[id].chanmsg, events[id].chan, events[id].msg2, events[id].msg3)
            elseif events[id].type == "TextSys" then
              reaper.MIDI_InsertTextSysexEvt(take, false, true, startPos, events[id].sysType, events[id].string)
            end
            items[index].needsSorting = true
          end
        end
      end

      -- Make sure events are sorted after inserting
      for index in ipairs(items) do
        if items[index].needsSorting then
          reaper.MIDI_Sort(items[index].activeTake)
        end
      end
    end
  end
end

-- Save/restore item selection -----------------------------------------------------------------------------------------
local function SaveSelectedItemsToTable (table)
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    table[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
end

local function RestoreSelectedItemsFromTable (table)
  for _, item in ipairs(table) do
    reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
  end
end

local function UnselectAllItems ()
  while (reaper.CountSelectedMediaItems(0) > 0) do
    reaper.SetMediaItemSelected(reaper.GetSelectedMediaItem(0, 0), false)
  end
end

local function SetItemSelected (item, unselectOthers)
  if unselectOthers then UnselectAllItems() end
  reaper.SetMediaItemSelected(item, true)
end

-- Save/restore items name,color and notes -----------------------------------------------------------------------------
local function SaveSelectedItemsData (table, saveNames, saveColors, saveSnapOffset, saveItemNotes)
  if saveNames or saveColors or saveItemNotes then
    for i = 0, reaper.CountTracks(0)-1 do

      local track = reaper.GetTrack(0, i)

      if (table[track] == nil) then table[track] = {} end
      local id = #table[track]

      for j = 0, reaper.CountTrackMediaItems(track)-1 do
        local item = reaper.GetTrackMediaItem(track, j)
        if reaper.GetMediaItemInfo_Value(item, "B_UISEL") == 1 then
          id = id + 1
          table[track][id] = {}
          local take  = reaper.GetActiveTake(item)
          local track = reaper.GetMediaItemTrack(item)

          table[track][id].startTime = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
          table[track][id].endTime   = table[track][id].startTime + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

           -- REAPER always glues to either MIDI or audio (so video item will end up as audio item)
          table[track][id].type = "MIDI"
          if not reaper.BR_IsTakeMidi(take, 0) then table[track][id].type = "AUDIO" end

          if saveNames then
            table[track][id].itemName = ({reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)})[2]
          end

          if saveColors then
            table[track][id].itemColor = reaper.GetMediaItemInfo_Value(item, "I_CUSTOMCOLOR")
            table[track][id].takeColor = reaper.GetMediaItemTakeInfo_Value(take, "I_CUSTOMCOLOR")
          end

          if saveSnapOffset then
            table[track][id].snapOffset = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET");
          end

          if saveItemNotes then
            table[track][id].itemNotes = reaper.ULT_GetMediaItemNote(item)
            if table[track][id].itemNotes == "" then table[track][id].itemNotes = nil end
            local imageValid, itemImage, itemImageFlags = reaper.BR_GetMediaItemImageResource(item, 0)
            if imageValid then
              table[track][id].itemImage      = itemImage;
              table[track][id].itemImageFlags = itemImageFlags;
            end
          end
        end
      end
    end
  end
end

local function RestoreItemDataToSelectedItems (table, restoreNames, restoreColors, restoreSnapOffset, restoreItemNotes)
  if restoreNames or restoreColors or restoreItemNotes then
    for i = 0, reaper.CountTracks(0)-1 do
      local track = reaper.GetTrack(0, i)
      if table[track] ~= nill and #table[track] > 0 then

        for j = 0, reaper.CountTrackMediaItems(track)-1 do
          local item = reaper.GetTrackMediaItem(track, j)
          local take = reaper.GetActiveTake(item)
          if reaper.GetMediaItemInfo_Value(item, "B_UISEL") == 1 then

            local startTime = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local endTime   = startTime + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

            -- REAPER always glues to either MIDI or audio (so video item will end up as audio item)
            local currentType = "MIDI"
            if not reaper.BR_IsTakeMidi(take, 0) then currentType = "AUDIO" end

            -- Find id of saved item data that is best suited to be restored to current item (gluing can lower count of items
            -- so always prioritize first saved...except with item notes - we put item notes of multiple items into one item)
            local currentId = 0
            for index, object in ipairs(table[track]) do
              if object and object.type == currentType and AreOverlapped(startTime, endTime, object.startTime, object.endTime) then
                currentId = index
                break
              end
            end

            if table[track][currentId] then
              if restoreNames and table[track][currentId].itemName then
                reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", table[track][currentId].itemName, true)
              end

              if restoreColors then
                if table[track][currentId].itemColor then
                  reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", table[track][currentId].itemColor)
                end
                if table[track][currentId].takeColor then
                  reaper.SetMediaItemTakeInfo_Value(take, "I_CUSTOMCOLOR", table[track][currentId].takeColor)
                end
              end

              if restoreSnapOffset and table[track][currentId].snapOffset then
                reaper.SetMediaItemInfo_Value(item, "D_SNAPOFFSET", table[track][currentId].snapOffset)
              end

              if restoreItemNotes then
                local newItemNote    = nil
                local itemImage      = nil
                local itemImageFlags = nil
                for h=1, #table[track] do
                  local object = table[track][h]
                  if object and (object.itemNotes or object.itemImage) and object.type == currentType and AreOverlapped(startTime, endTime, object.startTime, object.endTime) then
                    if newItemNote == nil then
                      newItemNote = object.itemNotes
                    else
                      newItemNote = newItemNote .. "\r\n" .. object.itemNotes
                    end

                    if itemImage == nil then
                      itemImage      = object.itemImage
                      itemImageFlags = object.itemImageFlags
                    end
                  end
                end
                if newItemNote ~= nill then reaper.ULT_SetMediaItemNote(item, newItemNote) end
                if itemImage ~= nill and itemImageFlags ~= nill then reaper.BR_SetMediaItemImageResource(item, itemImage, itemImageFlags) end
              end
            end
          end
        end
      end
    end
  end
end

-- Glue functionality --------------------------------------------------------------------------------------------------
local function GetUndoStringAndCmd (processItemsSeparately, ignoreTimeSel, includeFades, preserveMutedMidiEvents, preserveColor, preserveNames, preserveSnapOffset, preserveItemNotes)
  local undoString = nil
  local cmd        = 0

  if         ignoreTimeSel and     includeFades then cmd = 40257 undoString = ", ignoring time selection, including leading fade-in and trailing fade-out"
  elseif     ignoreTimeSel and not includeFades then cmd = 40362 undoString = ", ignoring time selection"
  elseif not ignoreTimeSel and     includeFades then cmd = 40606 undoString = ", including leading fade-in and trailing fade-out"
  else                                               cmd = 41588 undoString = "" end

  if   processItemsSeparately then undoString = "Glue items separately" .. undoString
  else                             undoString = "Glue items"            .. undoString end

  local mutedMidiString = nil
  if preserveMutedMidiEvents then mutedMidiString = "muted MIDI events" end

  local itemDataStr     = nil
  if preserveColor or preserveNames or preserveSnapOffset or preserveItemNotes then
    local strings = {}
    if preserveColor      then strings[#strings + 1] = "color" end
    if preserveNames      then strings[#strings + 1] = "name"  end
    if preserveSnapOffset then strings[#strings + 1] = "snap offset" end
    if preserveItemNotes  then strings[#strings + 1] = "notes" end

    if #strings > 0 then
      for index, string in ipairs(strings) do
        if      index == 1        then itemDataStr = "item "     .. string
        else if index == #strings then itemDataStr = itemDataStr .. " and " .. string
        else                           itemDataStr = itemDataStr .. ", "    .. string end
        end
      end
    end
  end

  if         mutedMidiString and     itemDataStr then undoString = undoString .. " (preserve " .. mutedMidiString .. " and " .. itemDataStr .. ")"
  elseif     mutedMidiString and not itemDataStr then undoString = undoString .. " (preserve " .. mutedMidiString .. ")"
  elseif not mutedMidiString and     itemDataStr then undoString = undoString .. " (preserve " .. itemDataStr     .. ")" end
  return undoString, cmd
end

local function PerformGlue (cmd, preserveMutedMidiEvents, preserveColor, preserveNames, preserveSnapOffset, preserveItemNotes)
  local savedMutedEvents = {}
  local savedItemsData   = {}
  if preserveMutedMidiEvents then SaveMutedEventsInSelectedItems(savedMutedEvents) end
  SaveSelectedItemsData(savedItemsData, preserveNames, preserveColor, preserveSnapOffset, preserveItemNotes)

  reaper.Main_OnCommand(cmd, 0)
  if preserveMutedMidiEvents then RestoreMutedMidiEventsToSelectedItems(savedMutedEvents) end
  RestoreItemDataToSelectedItems(savedItemsData, preserveNames, preserveColor, preserveSnapOffset, preserveItemNotes)
end

local function GlueItems (doUndo, processItemsSeparately, ignoreTimeSel, includeFades, preserveMutedMidiEvents, preserveColor, preserveNames, preserveSnapOffset, preserveItemNotes)
  local processed = false

  local gluableItemCount = reaper.CountSelectedMediaItems(0)
  local emptyItems = {}
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    if take == nil then
      gluableItemCount = gluableItemCount - 1
      emptyItems[#emptyItems + 1] = item
    end
  end

  if gluableItemCount > 0 then

    -- Prepare stuff
    local undoString, cmd = GetUndoStringAndCmd(processItemsSeparately, ignoreTimeSel, includeFades, preserveMutedMidiEvents, preserveColor, preserveNames, preserveSnapOffset, preserveItemNotes)
    if doUndo then reaper.Undo_BeginBlock() end
    reaper.PreventUIRefresh(1)

    -- Unselect all empty items (no point in gluing them)
    for _, item in ipairs(emptyItems) do
      reaper.SetMediaItemInfo_Value(item, "B_UISEL", 0)
    end

    -- Perform glue
    if processItemsSeparately then
      local savedItems = {}
      SaveSelectedItemsToTable(savedItems)
      for index, item in ipairs(savedItems) do
        SetItemSelected(item, true)
        PerformGlue(cmd, preserveMutedMidiEvents, preserveColor, preserveNames, preserveSnapOffset, preserveItemNotes)
        savedItems[index] = reaper.GetSelectedMediaItem(0, 0) -- just in case item pointer changes
      end
      UnselectAllItems()
      RestoreSelectedItemsFromTable(savedItems)
    else
      PerformGlue(cmd, preserveMutedMidiEvents, preserveColor, preserveNames, preserveSnapOffset, preserveItemNotes)
    end

    -- Restore empty items selection
    for _, item in ipairs(emptyItems) do
      reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
    end

    -- Finish up
    reaper.PreventUIRefresh(-1)
    if doUndo then reaper.Undo_EndBlock(undoString, -1) end
    processed = true
  end
  return processed
end


-----------------
-- Mouse table --
-----------------

local mouse = {  
                  -- Constants
                  LB = 1,
                  RB = 2,
                  CTRL = 4,
                  SHIFT = 8,
                  ALT = 16,
                  
                  -- "cap" function
                  cap = function (mask)
                          if mask == nil then
                            return gfx.mouse_cap end
                          return gfx.mouse_cap&mask == mask
                        end,
                          
                  uptime = 0,
                  
                  last_x = -1, last_y = -1,
                 
                  dx = 0,
                  dy = 0,
                  
                  ox_l = 0, oy_l = 0,    -- left click position
                  ox_r = 0, oy_r = 0,    -- right click position
                  capcnt = 0,
                  last_LMB_state = false
               }
              
--////////////////////////////////////////////////////////////////


---------------
-- class.lua --
---------------
-- base class for all elements

------------- "class.lua" is copied from http://lua-users.org/wiki/SimpleLuaClasses -----------

-- class.lua
-- Compatible with Lua 5.1 (not 5.0).
function class(base, init)
   local c = {}    -- a new class instance
   if not init and type(base) == 'function' then
      init = base
      base = nil
   elseif type(base) == 'table' then
    -- our new class is a shallow copy of the base class!
      for i,v in pairs(base) do
         c[i] = v
      end
      c._base = base
   end
   -- the class will be the metatable for all its objects,
   -- and they will look up their methods in it.
   c.__index = c

   -- expose a constructor which can be called by <classname>(<args>)
   local mt = {}
   mt.__call = function(class_tbl, ...)
   local obj = {}
   setmetatable(obj,c)
   if init then
      init(obj,...)
   else 
      -- make sure that any stuff from the base class is initialized!
      if base and base.init then
      base.init(obj, ...)
      end
   end
   return obj
   end
   c.init = init
   c.is_a = function(self, klass)
      local m = getmetatable(self)
      while m do 
         if m == klass then return true end
         m = m._base
      end
      return false
   end
   setmetatable(c, mt)
   return c
end
----------------------------------------------------------------------------------------


-----------------------
-- Check box class --
-----------------------

local Created_checkboxes = {} -- All created checkboxes are automatically collected to this table.

-----------------------
-- "class variables" --
-----------------------

local Checkbox_settings = 
  {
    horizontal_spacing = 5,       -- default horizontal spacing between checkboxes
    vertical_spacing = 5,         -- default vertical spacing between checkboxes
    name_horizontal_spacing = 5,  -- default spacing between checkbox and its name
    rightmost_pos = -1,           -- current rightmost x coordinate is stored to this variable
    topmost_pos = -1,             -- current topmost y coordinate is stored to this variable
    
    -- for auto-positioning
    default_x = 10,               -- if x1 is "nil", drawing starts at this x position
    default_y = 10                -- if y1 is "nil", drawing starts at this y position
  }


local Checkbox = class(
                 function(cb, x1, y1, size, state, name)
                   if #Created_checkboxes == 0 then
                     cb.x1     = x1 or Checkbox_settings.default_x
                     cb.y1     = y1 or Checkbox_settings.default_y
                     cb.size   = size or gfx.texth
                     cb.state  = state or false
                     cb.name   = name or "1"
                     cb.id     = 1
                     Created_checkboxes[1] = cb
                     
                   else -- at least one checkbox is created ("Created_checkboxes" is not empty)
                     cb.x1 = x1 or Created_checkboxes[#Created_checkboxes].x1
                     cb.y1 = y1 or Created_checkboxes[#Created_checkboxes].y1 + 
                                   Created_checkboxes[#Created_checkboxes].size + 
                                   Checkbox_settings.vertical_spacing
                             
                     cb.size  = size or gfx.texth
                     cb.state = state or false
                     cb.name = name or #Created_checkboxes + 1
                     cb.id = id or #Created_checkboxes + 1
                     Created_checkboxes[#Created_checkboxes + 1] = cb -- append current instance to "Created_checkboxes" -table
                   end
                   
                  
                   cb.name_w, cb.name_h = gfx.measurestr(cb.name)
                   cb.name_x = cb.x1 + cb.size + Checkbox_settings.name_horizontal_spacing
                   cb.name_y = cb.y1 + 0.5*(cb.size) - 0.5*cb.name_h

                   cb._mouse_on = false
                   cb._clicked = false
                     
                 end
)


-------------
-- Methods --
-------------

function Checkbox:get_checkbox_table()
  return Created_checkboxes
end


function Checkbox:get_settings_table()
  return Checkbox_settings
end


function Checkbox:get_name_state_table()
  local t = {}
  local cbs = Created_checkboxes
  for i=1, #cbs do
    t[i] = {}
    t[i].name = cbs[i].name
    t[i].state = cbs[i].state
  end
  return t
end


-- Set vertical spacing
function Checkbox:set_vert_spacing(new_spacing)
  Checkbox_settings.vertical_spacing = new_spacing
end


-- Set horizontal spacing for checkbox name (between checkbox and its name)
function Checkbox:set_horiz_spacing_for_name(new_spacing)
  Checkbox_settings.name_horizontal_spacing = new_spacing
end


-- Check "mouse on checkbox" state
function Checkbox:mouse_on()
  if gfx.mouse_x > self.x1 and gfx.mouse_x < self.x1 + self.size and gfx.mouse_y > self.y1 and gfx.mouse_y < self.y1 + self.size then
    self._mouse_on = true
    return true
  else
    self._mouse_on = false
    return false
  end
end


function Checkbox:create_from_name_state_table(name_state_table)
  local t = {}
  local nst = name_state_table
  for i=1, #nst do
    t[i] = Checkbox(start_x, start_y, nil, tonumber(nst[i].state)==1, nst[i].name)
  end
  return t
end
  

-- Update and draw all created checkboxes
function Checkbox:update_all()
  
  local cbs = Created_checkboxes
  for i=1, #cbs do
    if cbs[i]:mouse_on() and mouse.last_LMB_state == false and mouse.cap(mouse.LB) then
      local key = cbs[i].name:gsub('%s','_')
      conf[key] = math.abs(conf[key]-1)
      MPL_ExtState_Save()
      cbs[i]._clicked = true
    end
    
    local x1,y1,size = cbs[i].x1, cbs[i].y1, cbs[i].size
    local state, name = cbs[i].state, cbs[i].name
    gfx.set(0.8,0.8,0.8,1)
    gfx.rect(x1, y1, size, size, 0)
    
    -- Checkbox is checked
    if cbs[i].state then
      gfx.set(0.8,0.8,0.8,1)
      -- Inner rectangle
      gfx.rect(x1+3, y1+3, size-6, size-6, 1) -- smaller rectangle
    end
    
    -- Draw name
    gfx.x = cbs[i].name_x
    gfx.y = cbs[i].name_y
    gfx.drawstr(name)
    
    ----if not mouse.cap(mouse.LB) then -- (change state when LMB is released)
      if cbs[i]._clicked then -- and cbs[i]._mouse_on then
        if cbs[i].on_click ~= nil then cbs[i]:on_click()
          --cbs[i]:on_click()
        end
        cbs[i].state = not cbs[i].state
      end
      cbs[i]._clicked = false
    ----end
  end
end


---------------------------------------------------------------------------------


------------------
-- Button class --
------------------

--NOTE: This is old, but...well..working

local Button = class(
                      function(btn,x1,y1,w,h,state_count,state,visual_state,lbl,help_text)
                        btn.x1 = x1
                        btn.y1 = y1
                        btn.w = w
                        btn.h = h
                        btn.x2 = x1+w
                        btn.y2 = y1+h
                        btn.state = state
                        btn.state_count = state_count - 1
                        btn.vis_state = visual_state
                        btn.label = lbl
                        btn.help_text = help_text
                        btn.__mouse_state = 0
                        btn.label_w, btn.label_h = gfx.measurestr(btn.label)
                        btn.__state_changing = false
                        btn.r = 0.7
                        btn.g = 0.7
                        btn.b = 0.7
                        btn.a = 0.2
                        btn.lbl_r = 1
                        btn.lbl_g = 1
                        btn.lbl_b = 1
                        btn.lbl_a = 1
                      end
                    )


-------------
-- Methods --
-------------

-- returns true if "mouse on element"
function Button:__is_mouse_on()
  return(gfx.mouse_x > self.x1 and gfx.mouse_x < self.x2 and gfx.mouse_y > self.y1 and gfx.mouse_y < self.y2)
end


function Button:__lmb_down()
  return(mouse.last_LMB_state == false and gfx.mouse_cap & 1 == 1 and self.__mouse_state == 0)
  --return(last_mouse_state == 0 and self.mouse_state == 1)
end


function Button:set_help_text()
  if self.help_text == "" then return false end
    gfx.set(1,1,1,1)
    gfx.x = 10
    gfx.y = 10
    gfx.printf(self.help_text)
end


function Button:set_color(r,g,b,a)
  self.r = r
  self.g = g
  self.b = b
  self.a = a
end


function Button:set_label_color(r,g,b,a)
  self.lbl_r = r
  self.lbl_g = g
  self.lbl_b = b
  self.lbl_a = a
end


function Button:draw_label()
  -- Draw button label
  if self.label ~= "" then
    gfx.x = self.x1 + math.floor(0.5*self.w - 0.5 * self.label_w) -- center the label
    gfx.y = self.y1 + 0.5*self.h - 0.5*gfx.texth

    if self.__mouse_state == 1 then 
      gfx.y = gfx.y + 1
      gfx.a = self.lbl_a*0.5
    elseif self.__mouse_state == 0 then
      gfx.a = self.lbl_a
    end
  
    gfx.set(self.lbl_r,self.lbl_g,self.lbl_b,self.lbl_a)
    
    gfx.printf(self.label)
    if self.__mouse_state == 1 then gfx.y = gfx.y - 1 end
  end
end


-- Draw element (+ mouse handling)
function Button:draw()
  
  -- lmb released (and was clicked on element)
  if mouse.cap(mouse.LB) == false and self.__mouse_state == 1 then self.__mouse_state = 0 end
  
  
  -- Mouse is on element -----------------------
  if self:__is_mouse_on() then 
    if self:__lmb_down() then -- Left mouse btn is pressed on button
    --if last_mouse_state == 0 and gfx.mouse_cap & 1 == 1 and self.mouse_state == 0 then
      self.__mouse_state = 1
      if self.__state_changing == false then
        self.__state_changing = true
      else self.__state_changing = true
      end
    end
    
    self:set_help_text() -- Draw info/help text (if 'help_text' is not "")
    
    if mouse.last_LMB_state == false and gfx.mouse_cap & 1 == 0 and self.__state_changing == true then
      if self.onClick ~= nil then self:onClick()
        self.__state_changing = false
      else self.__state_changing = false
      end
    end
  
  -- Mouse is not on element -----------------------
  else
    if mouse.last_LMB_state == false and self.__state_changing == true then
      self.__state_changing = false
    end
  end  
  --gfx.a = self.a
  
  if self.__mouse_state == 1 or self.vis_state == 1 or self.__state_changing then
    --self.a = math.max(self.a - 0.2, 0.2)
    --gfx.set(0.8,0,0.8,self.a)
    gfx.set(0.8*self.r,0.8*self.g,0.8*self.b,math.max(self.a - 0.2, 0.2)*0.8)
    gfx.rect(self.x1, self.y1, self.w, self.h)

  -- Button is not pressed
  elseif not self.state_changing or self.vis_state == 0 or self.__mouse_state == 0 then
    gfx.set(self.r+0.2,self.g+0.2,self.b+0.2,self.a)
    gfx.rect(self.x1, self.y1, self.w, self.h)
   
    gfx.a = math.max(0.4*self.a, 0.6)
    -- light - left
    gfx.line(self.x1, self.y1, self.x1, self.y2-1)
    gfx.line(self.x1+1, self.y1+1, self.x1+1, self.y2-2)
    -- light - top
    gfx.line(self.x1+1, self.y1, self.x2-1, self.y1)
    gfx.line(self.x1+2, self.y1+1, self.x2-2, self.y1+1)

    --gfx.set(0.4,0,0.4,1)
    gfx.set(0.3*self.r,0.3*self.g,0.3*self.b,math.max(0.9*self.a,0.8))
    -- shadow - bottom
    gfx.line(self.x1+1, self.y2-1, self.x2-2, self.y2-1)
    gfx.line(self.x1+2, self.y2-2, self.x2-3, self.y2-2)
    -- shadow - right
    gfx.line(self.x2-1, self.y2-1, self.x2-1, self.y1+1)
    gfx.line(self.x2-2, self.y2-2, self.x2-2, self.y1+2)
  end
 
  self:draw_label()
end



---------------------------
-- Mouse event handling  --
-- (Schwa's GUI example) --
---------------------------

function OnMouseDown(x, y)
  MPL_ExtState_Save()
  mouse.capcnt = 0
  mouse.ox_l, mouse.oy_l = x, y
end


function OnMouseUp(x, y)
  mouse.uptime = os.clock()
  mouse.dx = 0
  mouse.dy = 0
  mouse.last_LMB_state = false
end


function OnMouseDoubleClick(x, y)
  -- handle mouse double click here
end


function OnMouseMove(x, y)
  -- handle mouse move here, use mouse.down and mouse.capcnt
  mouse.last_x, mouse.last_y = x, y
  mouse.dx = gfx.mouse_x - mouse.ox_l
  mouse.dy = gfx.mouse_y - mouse.oy_l
  mouse.capcnt = mouse.capcnt + 1
end


--------------
-- Mainloop --
--------------

function mainloop()
    
  -- (Schwa's GUI example)
  local mx, my = gfx.mouse_x, gfx.mouse_y
  if mouse.cap(mouse.LB) then              -- LMB pressed down?
    if mouse.last_LMB_state == false then  -- prevent "polling"...
      OnMouseDown(mx, my)                  --   ...run this once per LMB click
      if mouse.uptime and os.clock() - mouse.uptime < 0.20 then
        OnMouseDoubleClick(mx, my)
      end
    elseif mx ~= mouse.last_x or my ~= mouse.last_y then
      OnMouseMove(mx, my)
    end
  elseif mouse.last_LMB_state then
    OnMouseUp(mx, my)
  end

  --------------
  -- Draw GUI --
  --------------
  
  -- Draw all created checkboxes from "Created_checkboxes" -table
  -- (see "checkbox class.lua")
  Checkbox:update_all()
  
  -- draw/update button
  glue_btn:draw()
  
  if mouse.cap(mouse.LB) and mouse.last_LMB_state == false then
    mouse.last_LMB_state = true
  end
  
  gfx.update()
  if gfx.getchar() >= 0 then reaper.defer(mainloop) end
end


----------
-- Init --
----------

local gui = {}

function init()
  -- GUI table --------------------------------------------
  --   contains GUI related settings (some basic user definable settings), initial values etc.
  ---------------------------------------------------------
  
  -- Add "settings" table to "gui" table              
  gui.settings = {}
  gui.settings.font_size = 15      -- font size
  gui.settings.docker_id = 256      -- try 0, 1, 257, 513, 1027 etc.
  
  
  --------------------
  -- Initialize GUI --
  --------------------
  
  gfx.init("Breeder - Glue tool", conf.wind_w, conf.wind_h, gui.settings.docker_id, conf.wind_x, conf.wind_y)
  gfx.setfont(1,"Arial", gui.settings.font_size)
  gfx.clear = 3355443  -- matches with "FUSION: Pro&Clean Theme :: BETA 01" http://forum.cockos.com/showthread.php?t=155329
  -- (Double click in ReaScript IDE to open the link)
    
    
  -----------------------
  -- Create checkboxes --
  -----------------------
  
  -- Checkboxes are later created from this table 
  local glue_items_settings = {
                                {name = "Process items separately",   state = conf.Process_items_separately},
                                {name = "Ignore time selection",      state = conf.Ignore_time_selection},
                                {name = "Include fades",              state = conf.Include_fades},
                                {name = "Preserve muted MIDI events", state = conf.Preserve_muted_MIDI_events},
                                {name = "Preserve color",             state = conf.Preserve_color},
                                {name = "Preserve names",             state = conf.Preserve_names},
                                {name = "Preserve snap offset",       state = conf.Preserve_snap_offset},
                                {name = "Preserve item notes",        state = conf.Preserve_item_notes}
                              }
                        
                                           -- (see "Checkbox_settings" in "checkbox class")
  Checkbox:set_vert_spacing(5)             -- Optional vertical spacing between checkboxes
  Checkbox:set_horiz_spacing_for_name(5)   -- Optional horizontal spacing between checkbox and its name
  
  
  ---------------------------------------------------------
  -- Create checkboxes from "glue_items_settings" -table --
  ---------------------------------------------------------
  
  Checkbox:create_from_name_state_table(glue_items_settings)
   
   
  --------------------------
  -- Create "Glue" button --
  --------------------------
  
  -- update y position to last checkbox 
  local y = Created_checkboxes[#Created_checkboxes].y1
            + Created_checkboxes[#Created_checkboxes].size
            + gui.settings.font_size*2
            
  glue_btn = Button(10, y, 60, gui.settings.font_size + 4, 2, 0, 0, "Glue", "")
  
  -- execute "glue.GlueItems" when the Glue -button is pressed
  glue_btn.onClick = 
    function()
      local cb = Checkbox:get_name_state_table() -- (see "checkbox class")
      GlueItems(true, 
                     cb[1].state, -- Process items separately
                     cb[2].state, -- Ignore time selection
                     cb[3].state, -- Include fades
                     cb[4].state, -- Preserve muted MIDI events
                     cb[5].state, -- Preserve color
                     cb[6].state, -- Preserve names
                     cb[7].state, -- Preserve snap offset
                     cb[8].state  -- Preserve item notes
                    )
    end

  mainloop()
end

--  MPL mod ------------------------------------------------- 

  ---------------------------------------------------
  function MPL_ExtState_Load()
    local def = MPL_ExtState_Def()
    for key in pairs(def) do 
      local es_str = reaper.GetExtState(def.ES_key, key)
      if es_str == '' then conf[key] = def[key] else conf[key] = tonumber(es_str) or es_str end
    end    
  end  
  ---------------------------------------------------
  function MPL_ExtState_Save()
    conf.dock , conf.wind_x, conf.wind_y, conf.wind_w, conf.wind_h= gfx.dock(-1, 0,0,0,0)
    for key in pairs(conf) do reaper.SetExtState(conf.ES_key, key, conf[key], true)  end
  end
  ---------------------------------------------------
  function MPL_ExtState_Def()  
    local t= {
            -- globals
            ES_key = 'BR_SPK_GlueTools',
            wind_x =  20,
            wind_y =  20,
            wind_w =  220,
            wind_h =  250,
            dock =    0,
            
            Process_items_separately = 0,
            Ignore_time_selection = 0,
            Include_fades = 0,
            Preserve_muted_MIDI_events = 0,
            Preserve_color = 0,
            Preserve_names = 0,
            Preserve_snap_offset = 0,
            Preserve_item_notes = 0
            }
    return t
  end
  ---------------------------------------------------
  
MPL_ExtState_Load()  
init()

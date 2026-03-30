-- @description Replace with an empty item
-- @author ilovemedia
-- @version 2.0
-- @changelog
--   Added support for replacing multiple selected items simultaneously.
--   Generate MIDI items via API (CreateNewMIDIItemInProj) instead of action commands.
--   Prevent alteration of the user's loop/time selection.
--   Preserve item Mute state.
--   Preserve all fade properties (fade in/out lengths, shapes, and curves).
--   Added proper Undo/Redo block support.
--   Enhanced stability by buffering item data before modifying the project.
-- @about
--   # Replace with an empty item
--
--   Replace selected items with empty MIDI items (Keep names, position, length, fades, mute, color)


function ReplaceSelected()
    -- Get the number of selected media items
    local selectedCount = reaper.CountSelectedMediaItems(0)
    if selectedCount == 0 then return end

    reaper.Undo_BeginBlock()

    -- 1. Store data from all selected items into a table
    local itemsData = {}
    for i = 0, selectedCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if item then
            local take = reaper.GetActiveTake(item)
            local data = {
                item = item, -- Save exact object reference
                track = reaper.GetMediaItem_Track(item),
                name = take and reaper.GetTakeName(take) or "", -- The name they want to keep!
                start = reaper.GetMediaItemInfo_Value(item, "D_POSITION"),
                len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH"),
                color = reaper.GetMediaItemInfo_Value(item, "I_CUSTOMCOLOR"),
                mute = reaper.GetMediaItemInfo_Value(item, "B_MUTE"),
                fi = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN"),
                fo = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN"),
                fis = reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE"),
                fos = reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE"),
                fidir = reaper.GetMediaItemInfo_Value(item, "D_FADEINDIR"),
                fodir = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTDIR")
            }
            table.insert(itemsData, data)
        end
    end

    -- 2. Process the list: Always create a new empty MIDI item (regardless of original type).
    for _, d in ipairs(itemsData) do
        local newItem
        local newTake
        
        -- Always create an empty MIDI item, even if the original was audio.
        newItem = reaper.CreateNewMIDIItemInProj(d.track, d.start, d.start + d.len, false)
        newTake = reaper.GetActiveTake(newItem)
        
        -- Apply the original "Take Name" seamlessly
        if d.name and d.name ~= "" and newTake then
            reaper.GetSetMediaItemTakeInfo_String(newTake, "P_NAME", d.name, true)
        end
        
        -- Apply captured properties and fades to the new empty item
        reaper.SetMediaItemInfo_Value(newItem, "I_CUSTOMCOLOR", d.color)
        reaper.SetMediaItemInfo_Value(newItem, "B_MUTE", d.mute)
        reaper.SetMediaItemInfo_Value(newItem, "D_FADEINLEN", d.fi)
        reaper.SetMediaItemInfo_Value(newItem, "D_FADEOUTLEN", d.fo)
        reaper.SetMediaItemInfo_Value(newItem, "C_FADEINSHAPE", d.fis)
        reaper.SetMediaItemInfo_Value(newItem, "C_FADEOUTSHAPE", d.fos)
        reaper.SetMediaItemInfo_Value(newItem, "D_FADEINDIR", d.fidir)
        reaper.SetMediaItemInfo_Value(newItem, "D_FADEOUTDIR", d.fodir)
        
        -- Re-select the new item so the user stays with the same selection range visually
        reaper.SetMediaItemInfo_Value(newItem, "I_SELECTED", 1)
        
        -- Delete the original item safely using its exact memory pointer
        if reaper.ValidatePtr(d.item, "MediaItem*") then
            reaper.DeleteTrackMediaItem(d.track, d.item)
        end
    end

    reaper.Undo_EndBlock("Replace with empty MIDI items (Keep Take Names & Sources)", -1)
    reaper.UpdateArrange()
end

ReplaceSelected()

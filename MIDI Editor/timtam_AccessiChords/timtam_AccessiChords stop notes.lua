-- @noindex

-- fixing script path for correct require calls
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"

local AccessiChords = require('timtam_AccessiChords')

local function run()

  local noteTable = AccessiChords.deserializeTable(AccessiChords.getValue('playing_notes', AccessiChords.serializeTable({})))
  local deferCount = tonumber(AccessiChords.getValue('playing_notes_defer_count', 0))
  
  if #noteTable == 0 then
    
    AccessiChords.setValue('playing_notes_defer_count', 0)
    AccessiChords.setValue('playing_notes', AccessiChords.serializeTable({}))
    return

  end

  deferCount = deferCount + 1

  local i = 1  
  local notes = {}

  repeat

    if noteTable[i]['time'] <= deferCount then
      table.insert(notes, noteTable[i]['note'])
      table.remove(noteTable, i)
    else
      i = i + 1
    end

  until (i > #noteTable)

  if #notes > 0 then
    AccessiChords.stopNotes(table.unpack(notes))
  end

  AccessiChords.setValue('playing_notes', AccessiChords.serializeTable(noteTable))
  AccessiChords.setValue('playing_notes_defer_count', deferCount)
  
  reaper.defer(run)
  
end

reaper.defer(run)

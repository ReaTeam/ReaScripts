-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local D   = require "modules/defines"
local S   = require "modules/settings"
local MK  = require "modules/markers"
local AT  = require "modules/action_triggers"
local MOD = require "modules/modifiers"

local function ResolveOperationMode(look_for_action_triggers)
  local mode                = S.getSetting("EditMode")
  local triggered_by_action = false

  local editModes = {
      { name = "Write",     prio = 4    },
      { name = "Navigate",  prio = 3    },
      { name = "Insert",    prio = 2    },
      { name = "Repitch",   prio = 2.5  },
      { name = "Replace",   prio = 1    },
  }

  -- List of modes that are active through modifier keys
  local activemodes = {}
  for k, editmode in ipairs(editModes) do
    local setting = S.getSetting(editmode.name .. "ModifierKeyCombination")
    local combi   = D.ModifierKeyCombinationLookup[setting]
    local pressed = MOD.IsModifierKeyCombinationPressed(combi.id)
    if pressed then
      activemodes[#activemodes + 1] = { mode = editmode.name, combi = combi, prio = editmode.prio  }
    end
  end

  -- Sort modes by priority
  table.sort(activemodes, function(e1,e2)
    local l1 = #e1.combi.vkeys
    local l2 = #e2.combi.vkeys

    if l1 == l2 then
      return e1.prio < e2.prio
    end

    return l1 > l2;
  end)

  if #activemodes > 0 then
    mode = activemodes[1].mode
  end

  if look_for_action_triggers then
    for k, v in pairs(D.ActionTriggers) do
      local has_triggered = AT.getActionTrigger(k)
      if has_triggered then
        if v.action ~= "Commit" then
          -- If it's a commit, use current mode, else use the mode linked to the trigger
          mode = v.action
        end
        triggered_by_action = true
        break
      end
    end
  end

  -- Finally, if the op marker is set, override the mode if needed
  local use_alt = nil
  if D.ActionTriggers[mode].markerAlternate and MK.findOperationMarker() then
    use_alt = true
  end

  return {
    mode      = mode,
    alternate = D.ActionTriggers[mode].markerAlternate,
    use_alt   = use_alt
  }
end

return {
  ResolveOperationMode    = ResolveOperationMode
}

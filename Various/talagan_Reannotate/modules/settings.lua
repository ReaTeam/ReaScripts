-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local os                            = reaper.GetOS()
local is_windows                    = os:match('Win')

local SettingDefs = {
  UseDebugger               = { type = "bool",    default = false },
  UseProfiler               = { type = "bool",    default = false },

  SlotLabel_0               = { type = "string", default = "SWS/Reaper" },
  SlotLabel_1               = { type = "string", default = "Description"},
  SlotLabel_2               = { type = "string", default = "Comments"},
  SlotLabel_3               = { type = "string", default = "Other"},
  SlotLabel_4               = { type = "string", default = "Todos"},
  SlotLabel_5               = { type = "string", default = "Completed"},
  SlotLabel_6               = { type = "string", default = "Warnings"},
  SlotLabel_7               = { type = "string", default = "Problems"},
};

local function unsafestr(str)
  if str == "" then
    return nil
  end
  return str
end

local function serializedStringToValue(str, spec)
  local val = unsafestr(str);

  if val == nil then
    val = spec.default;
  else
    if spec.type == 'bool' then
      val = (val == "true");
    elseif spec.type == 'int' then
      val = tonumber(val)
      if val then val = math.floor(val) end
    elseif spec.type == 'double' then
      val = tonumber(val);
    elseif spec.type == 'string' then
      -- No conversion needed
    end
  end

  return val
end

local function valueToSerializedString(val, spec)
  local str = ''
  if spec.type == 'bool' then
    str = (val == true) and "true" or "false";
  elseif spec.type == 'int' then
    str = tostring(val);
  elseif spec.type == 'double' then
    str = tostring(val);
  elseif spec.type == "string" then
    -- No conversion needed
    str = val
  end
  return str
end

local function getSetting(setting)
  local spec  = SettingDefs[setting];

  if spec == nil then
    error("Trying to get unknown setting " .. setting);
  end

  local str = reaper.GetExtState("MaCCLane", setting)

  return serializedStringToValue(str, spec)
end

local function setSetting(setting, val)
  local spec  = SettingDefs[setting];

  if spec == nil then
    error("Trying to set unknown setting " .. setting);
  end

  if val == nil then
    reaper.DeleteExtState("MaCCLane", setting, true);
  else
    local str = valueToSerializedString(val, spec);
    reaper.SetExtState("MaCCLane", setting, str, true);
  end
end

local function resetSetting(setting)
  setSetting(setting, SettingDefs[setting].default)
end
local function getSettingSpec(setting)
  return SettingDefs[setting]
end

return {
  SettingDefs                 = SettingDefs,

  getSetting                  = getSetting,
  setSetting                  = setSetting,
  resetSetting                = resetSetting,
  getSettingSpec              = getSettingSpec,
}


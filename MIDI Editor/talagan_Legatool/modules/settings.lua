-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Legatool

local ExtStateKey = "Legatool"

local SettingDefs = {
  UseDebugger               = { type = "bool",    default = false },
  UseProfiler               = { type = "bool",    default = false },
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

  local str = reaper.GetExtState(ExtStateKey, setting)

  return serializedStringToValue(str, spec)
end

local function setSetting(setting, val)
  local spec  = SettingDefs[setting];

  if spec == nil then
    error("Trying to set unknown setting " .. setting);
  end

  if val == nil then
    reaper.DeleteExtState(ExtStateKey, setting, true);
  else
    local str = valueToSerializedString(val, spec);
    reaper.SetExtState(ExtStateKey, setting, str, true);
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


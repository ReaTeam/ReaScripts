-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

-- Settings helpers, to store/restore settings or manage them during the app's life.

local AppName         = 'Spectracular!'
local ExtstateRootKey = "TalaganSpectracular"

local SettingDefs = {
  UseDebugger         = { type = "bool",    default = false },
  UseProfiler         = { type = "bool",    default = false },
  DbMin               = { type = "int",     default = -45 },
  DbMax               = { type = "int",     default = 0 },
  RMSDbMin            = { type = "int",     default = -45 },
  RMSDbMax            = { type = "int",     default = 0 },
  TimeResolution      = { type = "int",     default = 15 },
  FFTSize             = { type = "int",     default = 8192 },
  ZeroPaddingPercent  = { type = "int",     default = 0 },
  RMSWindow           = { type = "int",     default = 1024},
  KeepTimeSelection   = { type = "bool",    default = false },
  KeepTrackSelection  = { type = "bool",    default = false },
  AutoRefresh         = { type = "bool",    default = false}
};

local function unsafestr(str)
  if str == "" then
    return nil
  end
  return str
end

--- @return integer|number|boolean|unknown result
local function serializedStringToValue(str, spec)
  local val = unsafestr(str);

  if val == nil then
    val = spec.default;
  else
    if spec.type == 'bool' then
      val = (val == "true");
    elseif spec.type == 'int' then
      val = tonumber(val);
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

  local str = reaper.GetExtState(ExtstateRootKey, setting)

  return serializedStringToValue(str, spec)
end

local function setSetting(setting, val)
  local spec  = SettingDefs[setting];

  if spec == nil then
    error("Trying to set unknown setting " .. setting);
  end

  if val == nil then
    reaper.DeleteExtState(ExtstateRootKey, setting, true);
  else
    local str = valueToSerializedString(val, spec);
    reaper.SetExtState(ExtstateRootKey, setting, str, true);
  end
end

local function resetSetting(setting)
  setSetting(setting, SettingDefs[setting].default)
end
local function getSettingSpec(setting)
  return SettingDefs[setting]
end

local instance_params = {
  launch_time         = reaper.time_precise(),
  chan_mode           = 0,
  channel_mode        = "stereo",
  low_octava          = 1,
  high_octava         = 8,
  lr_balance          = 0.5,
  zero_padding_percent = getSetting("ZeroPaddingPercent"),
  keep_time_selection  = getSetting("KeepTimeSelection"),
  keep_track_selection = getSetting("KeepTrackSelection"),
  dbmin               = getSetting("DbMin"),
  dbmax               = getSetting("DbMax"),
  rms_dbmin           = getSetting("RMSDbMin"),
  rms_dbmax           = getSetting("RMSDbMax"),
  time_resolution_ms  = getSetting("TimeResolution"),
  fft_size            = getSetting("FFTSize"),
  rms_window          = getSetting("RMSWindow"),
  auto_refresh        = getSetting("AutoRefresh")
}

return {
  AppName                     = AppName,
  SettingDefs                 = SettingDefs,

  getSetting                  = getSetting,
  setSetting                  = setSetting,
  resetSetting                = resetSetting,
  getSettingSpec              = getSettingSpec,

  instance_params             = instance_params
}


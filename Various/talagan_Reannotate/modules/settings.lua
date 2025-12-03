-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local JSON = require "ext/json"

local DefaultMarkdownStyle = {
    default     = { font_family = "Arial", base_color = "#CCCCCC", bold_color = "white", autopad = 5 --[[font_size = 13, ]] },

    h1          = { font_family = "Arial", font_size = 23, padding_left = 0,        padding_top = 0, padding_bottom = 0,      line_spacing = 0, base_color = "#288efa", bold_color = "#288efa" },
    h2          = { font_family = "Arial", font_size = 21, padding_left = 5,        padding_top = 0, padding_bottom = 0,      line_spacing = 0, base_color = "#4da3ff", bold_color = "#4da3ff" },
    h3          = { font_family = "Arial", font_size = 19, padding_left = 10,       padding_top = 0, padding_bottom = 0,      line_spacing = 0, base_color = "#65acf7", bold_color = "#65acf7" },
    h4          = { font_family = "Arial", font_size = 17, padding_left = 15,       padding_top = 0, padding_bottom = 0,      line_spacing = 0, base_color = "#85c0ff", bold_color = "#85c0ff" },
    h5          = { font_family = "Arial", font_size = 15, padding_left = 20,       padding_top = 0, padding_bottom = 0,      line_spacing = 0, base_color = "#9ecdff", bold_color = "#9ecdff" },

    paragraph   = { font_family = "Arial", font_size = 13, padding_left = 30,       padding_top = 2, padding_bottom = 2,      line_spacing = 0, padding_in_blockquote = 6 },
    list        = { font_family = "Arial", font_size = 13, padding_left = 40,       padding_top = 2, padding_bottom = 2,      line_spacing = 0, padding_indent = 5 },

    table       = { font_family = "Arial", font_size = 13, padding_left = 30,       padding_top = 2, padding_bottom = 2,      line_spacing = 0 },

    code        = { font_family = "monospace", font_size = 13, padding_left = 30,   padding_top = 2, padding_bottom = 2,      line_spacing = 4, padding_in_blockquote = 6 },
    blockquote  = { font_family = "Arial", font_size = 13, padding_left = 0,        padding_top = 2, padding_bottom = 2,      line_spacing = 2, padding_indent = 10 },

    link        = { base_color = "orange", bold_color = "tomato"},

    separator   = { padding_top = 3, padding_bottom = 7 }
}

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

  -- Styling
  UIFontSize                = { type = "int",  default = 12 },
  NewProjectMarkdown        = { type = "json", default = DefaultMarkdownStyle },
  NewProjectStickerSize     = { type = "int",  default = 12 }
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
    elseif spec.type == 'json' then
      local succ, _ ,_ = pcall(function()
        val = JSON.decode(val)
      end)
      -- Fallback on the default if decoding explodes
      if not succ then val = spec.default end
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
  elseif spec.type == 'json' then
    str = JSON.encode(val)
  end
  return str
end

local function getSetting(setting)
  local spec  = SettingDefs[setting];

  if spec == nil then
    error("Trying to get unknown setting " .. setting);
  end

  local str = reaper.GetExtState("Reannotate", setting)

  return serializedStringToValue(str, spec)
end

local function setSetting(setting, val)
  local spec  = SettingDefs[setting];

  if spec == nil then
    error("Trying to set unknown setting " .. setting);
  end

  if val == nil then
    reaper.DeleteExtState("Reannotate", setting, true);
  else
    local str = valueToSerializedString(val, spec);
    reaper.SetExtState("Reannotate", setting, str, true);
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


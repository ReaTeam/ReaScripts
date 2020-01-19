--[[
Description: Scythe library v3
Version: 3.0.0alpha1
Author: Lokasenna
Links:
  Forum Thread https://forum.cockos.com/showthread.php?t=177772
  Scythe Website http://jalovatt.github.io/scythe
Donation: https://paypal.me/Lokasenna
About:
  Provides a framework allowing Lua scripts to use a graphical interface, since
  Reaper has no ability to do so natively, as well as standalone modules to
  simplify many repetitive or difficult tasks.

  SETUP: After installing this package, you _must_ tell Reaper where to find the
  library. In the Action List, find and run:

  "Script: Scythe_Set v3 library path.lua"
Changelog:
  None
Metapackage: true
Provides:
  [main] Lokasenna_Scythe library v3/library/Scythe_Set v3 library path.lua raw.githubusercontent.com/jalovatt/scythe/master/library/Scythe_Set v3 library path.lua
  [nomain] Lokasenna_Scythe library v3/library/scythe.lua raw.githubusercontent.com/jalovatt/scythe/master/library/scythe.lua
  [nomain] Lokasenna_Scythe library v3/library/public/color.lua raw.githubusercontent.com/jalovatt/scythe/master/library/public/color.lua
  [nomain] Lokasenna_Scythe library v3/library/public/string.lua raw.githubusercontent.com/jalovatt/scythe/master/library/public/string.lua
  [nomain] Lokasenna_Scythe library v3/library/public/sprite.lua raw.githubusercontent.com/jalovatt/scythe/master/library/public/sprite.lua
  [nomain] Lokasenna_Scythe library v3/library/public/gfx.lua raw.githubusercontent.com/jalovatt/scythe/master/library/public/gfx.lua
  [nomain] Lokasenna_Scythe library v3/library/public/message.lua raw.githubusercontent.com/jalovatt/scythe/master/library/public/message.lua
  [nomain] Lokasenna_Scythe library v3/library/public/menu.lua raw.githubusercontent.com/jalovatt/scythe/master/library/public/menu.lua
  [nomain] Lokasenna_Scythe library v3/library/public/error.lua raw.githubusercontent.com/jalovatt/scythe/master/library/public/error.lua
  [nomain] Lokasenna_Scythe library v3/library/public/math.lua raw.githubusercontent.com/jalovatt/scythe/master/library/public/math.lua
  [nomain] Lokasenna_Scythe library v3/library/public/table.lua raw.githubusercontent.com/jalovatt/scythe/master/library/public/table.lua
  [nomain] Lokasenna_Scythe library v3/library/public/buffer.lua raw.githubusercontent.com/jalovatt/scythe/master/library/public/buffer.lua
  [nomain] Lokasenna_Scythe library v3/library/public/file.lua raw.githubusercontent.com/jalovatt/scythe/master/library/public/file.lua
  [nomain] Lokasenna_Scythe library v3/library/public/text.lua raw.githubusercontent.com/jalovatt/scythe/master/library/public/text.lua
  [nomain] Lokasenna_Scythe library v3/library/public/font.lua raw.githubusercontent.com/jalovatt/scythe/master/library/public/font.lua
  [nomain] Lokasenna_Scythe library v3/library/public/image.lua raw.githubusercontent.com/jalovatt/scythe/master/library/public/image.lua
  [nomain] Lokasenna_Scythe library v3/library/public/const.lua raw.githubusercontent.com/jalovatt/scythe/master/library/public/const.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/core.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/core.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/theme.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/theme.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/layer.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/layer.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/element.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/element.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/config.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/config.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/window.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/window.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/elements/Knob.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/elements/Knob.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/elements/Frame.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/elements/Frame.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/elements/ColorPicker.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/elements/ColorPicker.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/elements/Tabs.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/elements/Tabs.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/elements/Label.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/elements/Label.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/elements/Menubar.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/elements/Menubar.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/elements/Slider.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/elements/Slider.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/elements/Textbox.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/elements/Textbox.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/elements/Radio.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/elements/Radio.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/elements/TextEditor.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/elements/TextEditor.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/elements/Button.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/elements/Button.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/elements/Checklist.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/elements/Checklist.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/elements/Menubox.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/elements/Menubox.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/elements/Listbox.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/elements/Listbox.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/elements/shared/option.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/elements/shared/option.lua
  [nomain] Lokasenna_Scythe library v3/library/gui/elements/shared/text.lua raw.githubusercontent.com/jalovatt/scythe/master/library/gui/elements/shared/text.lua
]]--
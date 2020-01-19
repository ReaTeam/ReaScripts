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
  [main] /Lokasenna_Scythe library v3/library/Scythe_Set v3 library path.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/Scythe_Set v3 library path.lua
  [nomain] /Lokasenna_Scythe library v3/library/scythe.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/scythe.lua
  [nomain] /Lokasenna_Scythe library v3/library/public/color.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/public/color.lua
  [nomain] /Lokasenna_Scythe library v3/library/public/string.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/public/string.lua
  [nomain] /Lokasenna_Scythe library v3/library/public/sprite.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/public/sprite.lua
  [nomain] /Lokasenna_Scythe library v3/library/public/gfx.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/public/gfx.lua
  [nomain] /Lokasenna_Scythe library v3/library/public/message.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/public/message.lua
  [nomain] /Lokasenna_Scythe library v3/library/public/menu.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/public/menu.lua
  [nomain] /Lokasenna_Scythe library v3/library/public/error.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/public/error.lua
  [nomain] /Lokasenna_Scythe library v3/library/public/math.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/public/math.lua
  [nomain] /Lokasenna_Scythe library v3/library/public/table.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/public/table.lua
  [nomain] /Lokasenna_Scythe library v3/library/public/buffer.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/public/buffer.lua
  [nomain] /Lokasenna_Scythe library v3/library/public/file.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/public/file.lua
  [nomain] /Lokasenna_Scythe library v3/library/public/text.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/public/text.lua
  [nomain] /Lokasenna_Scythe library v3/library/public/font.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/public/font.lua
  [nomain] /Lokasenna_Scythe library v3/library/public/image.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/public/image.lua
  [nomain] /Lokasenna_Scythe library v3/library/public/const.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/public/const.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/core.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/core.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/theme.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/theme.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/layer.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/layer.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/element.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/element.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/config.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/config.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/window.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/window.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/elements/Knob.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/elements/Knob.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/elements/Frame.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/elements/Frame.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/elements/ColorPicker.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/elements/ColorPicker.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/elements/Tabs.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/elements/Tabs.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/elements/Label.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/elements/Label.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/elements/Menubar.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/elements/Menubar.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/elements/Slider.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/elements/Slider.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/elements/Textbox.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/elements/Textbox.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/elements/Radio.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/elements/Radio.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/elements/TextEditor.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/elements/TextEditor.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/elements/Button.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/elements/Button.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/elements/Checklist.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/elements/Checklist.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/elements/Menubox.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/elements/Menubox.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/elements/Listbox.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/elements/Listbox.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/elements/shared/option.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/elements/shared/option.lua
  [nomain] /Lokasenna_Scythe library v3/library/gui/elements/shared/text.lua https://github.com/jalovatt/scythe/raw/daf7f8f5a325ac062fda161031c0bbae8f949d17/library/gui/elements/shared/text.lua
]]--
--[[
@description ReaImGui Markdown : A Markdown rendering library for ReaImGui
@version 0.1.14
@author Ben 'Talagan' Babut
@license MIT
@donation https://www.paypal.com/donate/?business=3YEZMY9D6U8NC&no_recurring=1&currency_code=EUR
@links
  Forum Thread https://forum.cockos.com/showthread.php?t=301055
@changelog
  - [Feature] Better handling of consecutive empty lines
  - [Rework] Reworked default style
  - [Bug Fix] List bullet not sized accordingly to list entry
  - [Bug Fix] Code block would always add empty line at the end
@metapackage
@provides
  [nomain] talagan_ReaImGui Markdown/reaimgui_markdown/**/*.lua
  [nomain] talagan_ReaImGui Markdown/reaimgui_markdown.lua
  [main] talagan_ReaImGui Markdown/actions/talagan_ReaImGui Markdown Demo.lua > .
@about
  # Purpose

    This library targets developers who want to add markdown support to their ReaImGui applications. It will provide a child widget that has markdown rendering abilities.

    It has basic support for headers, bold, italic, blockquotes, links, lists (unordered or ordered), tables, and also adds non-standard coloring features.

    It can be styled to one's will (colors, padding, line spacing, fonts, etc).

    See the dedicated forum thread for more info.
--]]

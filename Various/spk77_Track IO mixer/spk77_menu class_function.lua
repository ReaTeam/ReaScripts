--[[
   * Lua script for Cockos REAPER
   * Author: spk77
   * Author URI: http://forum.cockos.com/member.php?u=49553
   * Forum Thread URI: http://forum.cockos.com/showthread.php?t=168777
   * Licence: GPL v3
   * Version: 0.2015.12.18
   * NoIndex: true
  ]]
	
local Menu_class = {}

------------------------------------------------------------------------------
-- Get script path func
------------------------------------------------------------------------------
function get_script_path()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  return script_path
end


------------------------------------------------------------------------------
-- Import modules and initialize tables --
------------------------------------------------------------------------------
-- get "script path"
local script_path = get_script_path()
--msg(script_path)

-- modify "package.path"
package.path = package.path .. ";" .. script_path .. "?.lua"
--msg(package.path)

-- Import files ("classes", functions etc.)-----------------
require "spk77_class_function" -- import "base class"

----------------
-- Menu class --
----------------

-- To create a new menu instance, call this function like this:
--   menu_name = Menu("menu_name")
local Menu = 
  class(
    function(menu, id)
      menu.id = id    
      menu.items = {}       -- Menu items are collected to this table
      menu.items_str = ""
      menu.curr_item_pos = 1
    end
  )

Menu_class.create_menu = Menu


------------------
-- Menu methods --
------------------

--[[
-- True if menu item label starts with "prefix"
function Menu:label_starts_with(label, prefix)
  return string.sub(label, 1, string.len(prefix)) == prefix
end
--]]


-- Returns "menu item table" (or false if "id" not found)
function Menu:get_item_from_id(id)
  for i=1, #self.items do
    if self.items[i].id == id then
      return self.items[i]
    end
  end
  return false
end


-- Updates "menu item type" variables (_has_submenu, _last_item_in_submenu etc.)
function Menu:update_item(item_table)
  local t = item_table
  t._has_submenu = false
  t._last_item_in_submenu = false
  t.id = self.curr_item_pos
  
  if string.sub(t.label, 1, 1) == ">" or
     string.sub(t.label, 1, 2) == "<>" or
     string.sub(t.label, 1, 2) == "><" then
    t._has_submenu = true
    t.id = -1
    self.curr_item_pos = self.curr_item_pos - 1
  --end
  elseif string.sub(t.label, 1, 1) == "<" then
    t._has_submenu = false
    t._last_item_in_submenu = true
  end
  --t.id = self.curr_item_pos
  if string.sub(t.label, 1, 1) ~= "|" then
    self.curr_item_pos = self.curr_item_pos + 1
  end
end


-- Returns the created table and table index in "menu_obj.items"
function Menu:add_item(...)
  local t = ... or {}
  self.items[#self.items+1] = t -- add new menu item at the end of menu
  
  -- Parse arguments
  for i,v in pairs(t) do
    --msg(i .. " = " .. tostring(v))
    if i == "label" then
      t.label = v
    elseif i == "selected" then
      t.selected = v
    elseif i == "active" then
      t.active = v
    elseif i == "toggleable" then
      t.toggleable = v
    elseif i == "command" then
      t.command = v
    end
  end
  
  -- Default values for menu items
  -- (Edit these)
  if t.label == nil or t.label == "" then
    t.label = tostring(#self.items) -- if label is nil or "" -> label is set to "table index in menu_obj.items"
  end
  
  if t.selected == nil then
    t.selected = false   -- edit
  end
  
  if t.active == nil then
    t.active = true      -- edit
  end
  
  if t.toggleable == nil then
    t.toggleable = false -- edit
  end

  return t, #self.items
end


-- Get menu item table at index
function Menu:get_item(index)
  if self.items[index] == nil then
    return false
  end
  return self.items[index]
end


-- Show menu at mx, my
function Menu:show(mx, my)
  gfx.x = mx
  gfx.y = my
  
  -- Check which items has a function to call when a menu is about to be shown
  for i=1, #self.items do
    if self.items[i].on_menu_show ~= nil then
      self.items[i].on_menu_show()
    end
    -- Update item
    self:update_item(self.items[i])
  end
  
  -- Convert menu item tables to string
  self.items_str = self:table_to_string() or ""
  self.val = gfx.showmenu(self.items_str)
  if self.val > 0 then
    self:update(self.val)
  end
  self.curr_item_pos = 1 -- set "menu item position counter" back to the initial value
  return self.val
end


function Menu:update(menu_item_index)
  -- check which "menu item id" matches with "menu_item_index"
  for i=1, #self.items do
    if self.items[i].id == menu_item_index then
      menu_item_index = i
      break
    end
  end
  local i = menu_item_index 
  -- if menu item is "toggleable" then toggle "selected" state
  if self.items[i].toggleable then
    self.items[i].selected = not self.items[i].selected
  end
  -- if menu item has a "command" (function), then call that function
  if self.items[i].command ~= nil then
    self.items[i].command()
  end
end


-- Convert "Menu_obj.items" to string
function Menu:table_to_string()
  if self.items == nil then
    return
  end
  self.items_str = ""
  
  for i=1, #self.items do
    local temp_str = ""
    local menu_item = self.items[i]
    if menu_item.selected then
      temp_str = "!"
    end
    
    if not menu_item.active then
      temp_str = temp_str .. "#"
    end
    
    if menu_item.label ~= "" then
      temp_str = temp_str .. menu_item.label .. "|"
    end

    self.items_str = self.items_str .. temp_str
  end
  
  return self.items_str
end

--END of Menu class----------------------------------------------------

return Menu_class

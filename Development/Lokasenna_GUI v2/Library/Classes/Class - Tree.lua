--[[	Lokasenna_GUI - Tree class

	A tree class for the ReaScript Lokasenna_GUI/Scythe module
	Tested in Lokasenna_GUI v2

    For documentation, see this class's page on the project wiki:
    https://github.com/jkooks/Lokasenna_GUI-Tree/
    
    Creation parameters:
	name, z, x, y, w, h, list, header, caption, pad

]]----


if not GUI then
	reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
	missing_lib = true
	return 0
end





--controls how the index of an item in the list is figured out
GUI.ClampMode = {
	none = 0,
	force = 1,
	ignore = 2,
}

--controls position of the text - can be combined with | operator
GUI.AlignMode = {
	left = 0,
	horizontal = 1,
	right = 2,

	top = 4,
	center = 8,
	bottom = 16,

	ignore = 256,
}


--controls where you need to click within the tree in order to select an item
GUI.SelectionMode = {
	row = 1,		--selecting anywhere on the row selects the item
	text = 2,		--only selecting the text selects the item
	text_space = 3,	--selecting the text or empty space to the left selects the item
}


--controls the order that the tool sorts with
GUI.SortMode = {
	ascending = 1,	--a -> z, 1 -> 10
	descending = 2, --z -> a, 10 -> 1
	ignore = 3,		--don't sort unless specifically told to in script
}





function GUI.EscapeString(str)
	--[[
		escapes any special characters in the passed string
		
		param str: (string) the string that you want to escape
		
		return: (string) the escaped string
	]]--

	local all_escape_chars = {"%%", "[", "]", "(", ")", ".", "-", "+", "*", "?", "^", "$"} --make sure % is first, otherwise everything breaks
	
	for index, char in ipairs(all_escape_chars) do
		if char == "%%" then str = str:gsub(char, "%%" .. char)
		else str = str:gsub("%" .. char, "%%" .. char) end
	end

	return str
end


function GUI.ExpandTable(table1, table2, is_reverse)
	--[[
		combines two number based tables into a new table (makes a shallow copy)
		
		param table1: (table) the first table you want to combine
		param table2: (table) the second table that you want to combine
		param is_reverse: (optional bool) true if you want table2 to be added in a reversed manner
		
		return: (table) the combined table
	]]--

	local new_table = {}
	for i = 1, #table1 do table.insert(new_table, table1[i]) end

	local length = #table2

	if is_reverse then
		for i = length, 1, -1 do table.insert(table1, table2[i]) end
	else
		for i = 1, length do table.insert(table1, table2[i]) end
	end

	return table1
end


function GUI.CheckInTable(table1, object)
	--[[
		checks to see if the object you pass is within the table (shallow scan)
		
		param table1: (table) the table that you want to check if the item is in
		param object: (any type) the object that you want to see if the table includes
		
		return: (number) the index that the object is located in or 0 if not found
	]]--

	local length = #table1
	for i = 1, length do
		if table1[i] == object then
			return i
		end
	end

	return 0
end


function GUI.IsTreeItem(object)
	--[[
		checks to see if the object is a TreeItem
		
		param object: (table) the table you want to check to see if it is a TreeItem
		
		return: (bool) true if the object is a TreeItem, otherwise false
	]]--

	if type(object) ~= "table" then
		return false
	elseif object.type == "TreeItem" then
		return true
	else
		return false
	end
end










---------------------
---- Tree -----------
---------------------

GUI.Tree = GUI.Element:new()
GUI.Tree.__version__ = "0.1.0"

GUI.Tree.indent = "    "			--indent of each item depth, default 4 spaces
GUI.Tree.expanded_symbol = "▼"		--the symbol you want the parent item to have when expanded
GUI.Tree.collapsed_symbol = "►"		--the symbol you want the parent item to have when collapsed


function GUI.Tree:new(name, z, x, y, w, h, list, header, caption, pad)
	--[[
		creates a new tree element
		this is what GUI.New(..., "Tree", ...) calls to create a new tree

		param name: (string) the name that you want the element to be named
		param z: (table or int)	if passed a table, it will take the place of all the other params you want to pass to the tree, otherwise it is the z layer
		other params are defined below where they are initialized

		return: the new Tree element table
	]]--

	local tree = (not x and type(z) == "table") and z or {}

	tree.name = name
	tree.type = "Tree"
	
	tree.z = tree.z or z	
	
	tree.x = tree.x or x
    tree.y = tree.y or y
    tree.w = tree.w or w
    tree.h = tree.h or h

	tree.list = tree.list or {}						--passed list of all the stuff you want to be on the top level (string in CSV form or a table)

    tree.top_items = tree.top_items or {}			--holds the top level items in the tree after init
    tree.selected_items = {}						--holds all the items that are currently selected
    tree.showing_items = {}							--holds the items that are currently displayed in the window's view

	tree.caption = tree.caption or caption or ""
	tree.pad = tree.pad or pad or 4

	tree.shadow = tree.shadow or true

	tree.bg = tree.bg or "elm_bg"
    tree.cap_bg = tree.cap_bg or "wnd_bg"
	tree.color = tree.color or "txt"

	tree.col_fill = tree.col_fill or "elm_fill" -- Scrollbar fill
	
	tree.font_a = tree.font_a or 3
	tree.font_b = tree.font_b or 4

	tree.header = tree.header or header or nil --header text, table, or element that you want to use as the tree's header

	--various bool settings on how the tree handles operations
	tree.is_doubleclick_expand = tree.is_doubleclick_expand or true 				--if the user can expand a parent on doubleclick, default true
	tree.is_expandable = (tree.is_expandable == nil or tree.is_expandable) or false --if the user can expand any parent items in the tree, default true
	
	tree.is_multi = tree.is_multi or is_multi or false 								--if the user can select multiple items at once, default false

	tree.is_arrangeable = tree.is_arrangeable or false 								--if the user can re-arrange the items in the tree by dragging, default false
	tree.is_selectable = (tree.is_selectable == nil or tree.is_selectable) or false --if the user can select any items in the tree, default true

	tree.selection_mode = tree.selection_mode or GUI.SelectionMode.row 				--where the user needs to click on in the GUI in order to select an item

	tree.is_sortable = (tree.is_sortable == nil or tree.is_sortable) or false 		--if the user can sort the table or not (mainly by clicking on the header), default true

	--internal stuff from here down, used to check states of the GUI
	tree.is_clamp = tree.is_clamp or false
	tree.current_sort = tree.current_sort or GUI.SortMode.ignore 					--the mode that the tree is currently sorted in

	tree.wnd_x, tree.wnd_y = 1, 1
	tree.wnd_h, tree.wnd_w, tree.char_w = nil, nil, nil

	tree.max_w = 0 -- length of the largest tree/depth

	tree.has_vscrollbar = false
	tree.has_hscrollbar = false

	tree.down_position = {x=tree.x, y=tree.y} --store y position on mouse y (used for drawing drag)

	tree.up_item = nil
	tree.down_item = nil

	tree.is_dragging = false

	tree.needs_format = false --lets the tree know it needs to re-format the list

	--ADDED: Used for the auto resize functionality
	tree.w_scale = tree.w/GUI.w
	tree.x_scale = tree.x/GUI.w
	tree.h_scale = tree.h/GUI.h
	tree.y_scale = tree.y/GUI.h

	GUI.redraw_z[tree.z] = true

	setmetatable(tree, self)
	self.__index = self

	return tree
end


function GUI.Tree:init()
	--[[
		initialized the tree and figures out the basic info/gets it ready to be drawn
	]]--

	--create a header for the tree if one was given
	if self.header then
		if type(self.header) ~= "table" or self.header.type ~= "Header" then --don't add a header if the header already exists, just re-init it
			self:setheader(self.header)
		end

		self.header:init()
	end

	-- If we were given a CSV, process it into a table
	if type(self.list) == "string" then self.list = self:CSVtotable(self.list) end

	local x, y, w, h = self.x, self.y, self.w, self.h

	self.buff = GUI.GetBuffer()

	--does some init stuff when you pass the items to the "New" function
	self.top_items = {}
	local stack = GUI.ExpandTable({}, self.list, true)
	while #stack > 0 do
		local item = table.remove(stack)

		--create an item out of whatever is passed if it isn't a table/TreeItem
		if not GUI.IsTreeItem(item) then
			item = GUI.TreeItem:new(tostring(item))
			item:updatedisplaytext()
		end

		item.tree = self

		if #item.children > 0 then
			stack = GUI.ExpandTable(stack, item.children, true)
		end

		if item.depth == 0 then table.insert(self.top_items, item) end
	end

	if self.current_sort ~= GUI.SortMode.ignore then self:sortitems(self.current_sort) end

	self:formatlist()

	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)
	gfx.setimgdim(self.buff, w, h)
	
	GUI.color(self.bg)
	gfx.rect(0, 0, w, h, 1)
	
	GUI.color("elm_frame")
	gfx.rect(0, 0, w, h, 0)
end





---------------------------------
-------- Drawing ----------------
---------------------------------

function GUI.Tree:draw()
	--[[
		draws the element in the window and any other addtional elements (TreeItems, scroll bars, etc) 
	]]--

	local x, y, w, h = self.x, self.y, self.w, self.h

	self.has_vscrollbar, self.has_hscrollbar = false, false

	local caption = self.caption
	local pad = self.pad
	
	-- Some values can't be set in :init() because the window isn't
	-- open yet - measurements won't work.
	if not self.wnd_h then self:wnd_recalc() end	

	--re-format the list to know what is hidden/showing before re-drawing
	if self.needs_format then
		self:formatlist()
		self.needs_format = false
	end

	if #self.list > self.wnd_h then self.has_vscrollbar = true else self.has_vscrollbar = false end
	if self.max_w > self.wnd_w then self.has_hscrollbar = true else self.has_hscrollbar = false end

	-- Draw the caption
	if caption and caption ~= "" then self:drawcaption() end
	
	-- Draw the background and frame
	gfx.blit(self.buff, 1, 0, 0, 0, w, h, x, y)

	-- Draw the text
	self:drawtext()
	
	-- Highlight any selected items
	self:drawselection()
	if self.is_dragging and (self.is_arrangeable or self.is_multi) then self:drawdrag() end

	if self.has_vscrollbar then self:drawverticalscrollbar() end 	-- Vertical scrollbar
	if self.has_hscrollbar then self:drawhorizontalscrollbar() end	-- Horizontal scrollbar
    
end


function GUI.Tree:drawcaption()
	--[[
		draws the caption for the element, if there is one
	]]--
		
	local str = self.caption
	
	GUI.font(self.font_a)
	local str_w, str_h = gfx.measurestr(str)
	gfx.x = self.x - str_w - self.pad
	gfx.y = self.y + self.pad
	GUI.text_bg(str, self.cap_bg)
	
	if self.shadow then 
		GUI.shadow(str, self.color, "shadow") 
	else
		GUI.color(self.color)
		gfx.drawstr(str)
	end
	
end


function GUI.Tree:drawdrag()
	--[[
		draws the UI to show that you are dragging a selection or re-arranging the elements
	]]--

	local outside_position = self:wnd_outside()

	--if there is a scroll, move the views when the mouse if clicked down outside of the element
	if self.has_vscrollbar then
		if outside_position.top then
			self:verticalscroll(-1)
		elseif outside_position.bottom then
			self:verticalscroll(1)
		end
	end

	if self.has_hscrollbar then
		if outside_position.left then
			self:horizontalscroll(-1)
		elseif outside_position.right then
			self:horizontalscroll(1)
		end
	end	

	local right = self.x + self.w - self.pad
	local bottom = self.y + self.h - self.pad

	if self.has_vscrollbar then right = right - 8 end
	if self.has_hscrollbar then bottom = bottom - 8 end

	--draw a line displaying where you want to drag the item
	if self.is_arrangeable then
		local x1, x2, y

		GUI.color(GUI.colors["white"])
		gfx.a = 0.75
		gfx.mode = 1

		--make the full line at the base of the item and adjust the scroll wheel if needed
		if GUI.mouse.y <= self.y + self.pad then
			x1 = self.x + self.pad
			x2 = (self.x + self.w) - self.pad

			y = self.y + self.pad
		else
			local showing_index = math.floor((GUI.mouse.y - (self.y + self.pad)) / self.char_h) -- +1 so it appears on the bottom of the item
			local all_index = self:getindex(GUI.mouse.y, GUI.ClampMode.force)

			--if you are past all fo the items then just have it extend to the base of the frame at the last item
			if showing_index >= #self.list then
				x1 = self.x + self.pad
				x2 = (self.x + self.w) - self.pad
				y = (self.y + self.pad) + (#self.list) * self.char_h

			else
				local item = self:getitem(GUI.mouse.y, GUI.ClampMode.force)

				--if mouse is between top and half point of the item, parent it as long as that item is_parentable
				if item.is_parentable and self:estimatemouseposition(GUI.mouse.y, all_index) then
					x1 = self.x + self.pad + self:wnd_item(item) + 15
					
				--otherwise move it below the item (add to top level if item not parented, otherwise add to that index in the parent)
				else

					-- if item.parent and 
					x1 = self.x + self.pad + self:wnd_item(item)
				end

				x2 = (self.w + self.x) - self.pad
				y = (self.y + self.pad) + (showing_index + 1) * self.char_h

				if y > bottom then y = bottom end
			end
		end

		gfx.line(x1, y, x2, y)
	
	--draw a square around the items you are selecting
	elseif self.is_multi then
		GUI.color(self.col_fill)
		gfx.a = 0.5
		gfx.mode = 1

		local position = {}

		--figure out bounds of drag selection's left/right side
		if GUI.mouse.x < self.x then
			position.x = self.x
			position.w = self.down_position.x - self.x
		elseif GUI.mouse.x >= right then
			position.x = self.down_position.x
			position.w = right - self.down_position.x
		elseif self.down_position.x < GUI.mouse.x then
			position.x = self.down_position.x
			position.w = GUI.mouse.x - self.down_position.x
		else
			position.x = GUI.mouse.x
			position.w = self.down_position.x - GUI.mouse.x
		end

		--figure out bounds of drag selection's top/bottom side
		if GUI.mouse.y <= self.y then
			position.y = self.y
			position.h = self.down_position.y - self.y
		elseif GUI.mouse.y >= bottom then
			position.y = self.down_position.y
			position.h = bottom - self.down_position.y
		elseif self.down_position.y < GUI.mouse.y then
			position.y = self.down_position.y
			position.h = GUI.mouse.y - self.down_position.y
		else
			position.y = GUI.mouse.y
			position.h = self.down_position.y - GUI.mouse.y
		end

		gfx.rect(position.x, position.y, position.w, position.h, true)
	end

	gfx.mode = 0
	gfx.a = 1		

	return true
end


function GUI.Tree:drawtext()
	--[[
		draws the text elements for the list
		compiles all of the showing TreeItems and displays their info in a table
	]]--

	GUI.color(self.color)
	GUI.font(self.font_b)

	local tmp = {} --stores the strings to print
	for i = self.wnd_y, math.min(self:wnd_bottom() - 1, #self.list) do
		local item = self.list[i]
		local str = tostring(item.display) or ""

		--if horzontal scrollbar moved then split letters off from the front/if they are shorter than the wnd_x make them an empty string
		if self.wnd_x > 1 then
			if self.wnd_x > utf8.len(str) then
				str = ""
			else
				str = str:sub(utf8.offset(str, self.wnd_x) or 1)
			end
		end

        tmp[#tmp + 1] = str
	end

	gfx.x, gfx.y = self.x + self.pad, self.y + self.pad
    local r = gfx.x + self.w - 2*self.pad
    local b = gfx.y + self.h - 2*self.pad
	gfx.drawstr(table.concat(tmp, "\n"), 0, r, b)

end


function GUI.Tree:drawselection()
	--[[
		draws the UI that shows which items are selected
	]]--

	local off_x, off_y = self.x + self.pad, self.y + self.pad

	local off_w = self.w + self.x - 0.5

	GUI.color(self.col_fill) --changed this from being static to allowing it to change based off of scroll bar color
	gfx.a = 0.5
	gfx.mode = 1

	for i, item in ipairs(self.showing_items) do
		if item.selected and i >= self.wnd_y and i < self:wnd_bottom() then
			local x = off_x
			local w = off_w
			local y = off_y + (i - self.wnd_y) * self.char_h

			--have selection start at the beginning of the item's text if that is what the user wants
			if self.selection_mode ~= GUI.SelectionMode.row then
				x = x + self:wnd_item(item)
				w = w - x
			end

			gfx.rect(x, y, w, self.char_h, true)
		end
	
	end	
	
	gfx.mode = 0
	gfx.a = 1
	
end


function GUI.Tree:drawverticalscrollbar()
	--[[
		draws the vertical scrollbar and the bar within it
	]]--

	local x, y, w, h = self.x, self.y, self.w, self.h
	local sx, sy, sw, sh = x + w - 8 - 4, y + 4, 8, h - 12
	
	if self.has_hscrollbar then sh = sh - 8 end

	-- Draw a gradient to fade out the last ~16px of text
	GUI.color("elm_bg")
	for i = 0, 15 do
		gfx.a = i/15
		gfx.line(sx + i - 15, y + 2, sx + i - 15, y + h - 4)
	end	
	
	gfx.rect(sx, y + 2, sw + 2, h - 4, true)
	
	-- Draw slider track
	GUI.color("tab_bg")
	GUI.roundrect(sx, sy, sw, sh, 4, 1, 1)
	GUI.color("elm_outline")
	GUI.roundrect(sx, sy, sw, sh, 4, 1, 0)
		
	-- Draw slider fill
	local fh = (self.wnd_h / #self.list) * sh - 4
	if fh < 4 then fh = 4 end
	local fy = sy + ((self.wnd_y - 1) / #self.list) * sh + 2
	
	GUI.color(self.col_fill)
	GUI.roundrect(sx + 2, fy, sw - 4, fh, 2, 1, 1)

	self.has_vscrollbar = true
end


function GUI.Tree:drawhorizontalscrollbar()
	--[[
		draws the horizontal scrollbar and the bar within it
	]]--

	local x, y, w, h = self.x, self.y, self.w, self.h
	local sx, sy, sw, sh = x + 4, y + h - 8 - 4, w - 12, 8

	if self.has_vscrollbar then sw = sw - 8 end	

	-- Draw a gradient to fade out the last ~16px of text
	GUI.color("elm_bg")
	for i = 0, 15 do
		gfx.a = i/15
		gfx.line(x + 2, sy + i - 15, x + w - 4, sy + i - 15)
	end
	
	gfx.rect(x + 2, sy, w - 4, sh + 2, true)
	
	-- Draw slider track
	GUI.color("tab_bg")
	GUI.roundrect(sx, sy, sw, sh, 4, 1, 1)
	GUI.color("elm_outline")
	GUI.roundrect(sx, sy, sw, sh, 4, 1, 0)
		
	-- Draw slider fill

	local fw = (self.wnd_w / self.max_w) * sw - 4
	if fw < 4 then fw = 4 end
	local fx = sx + ((self.wnd_x - 1) / self.max_w) * sw + 2

	GUI.color(self.col_fill)
	GUI.roundrect(fx, sy + 2, fw, sh - 4, 2, 1, 1)

	self.has_hscrollbar = true
end


function GUI.Tree:redraw(skip_format)
	--[[
		triggers a redraw of the tree

		param skip_format: (optional bool) true if you don't need to redraw the text that is displayed, saves the script some work if only selection has changed

		return: (bool) true on success
	]]--

	if not skip_format and not self.needs_format then self.needs_format = true end

	GUI.Element.redraw(self)

	return true
end





---------------------------------
------ Input --------------------
---------------------------------

function GUI.Tree:onmouseup()
	--[[
		controls the bulk of user interaction and what happens when the user releases a mouse click within the element
		signals in here so they aren't triggered when using functions from script (callback protection)

		return: (TreeItem) the item that the user released on, or nil if no item was clicked
	]]--

	if not self:oververticalscrollbar() and not self:overhorizontalscrollbar() then
		local item = self:getitem(GUI.mouse.y)
		
		local last_up = self.up_item
		self.up_item = item

		-- do things if you are dragging stuff
		if self.is_dragging then
			self.is_dragging = false

			if not self.down_item then self.down_item = self:getitem(self.down_position.y, GUI.ClampMode.force) end
			if not item then item = self:getitem(GUI.mouse.y, GUI.ClampMode.force) end

			--re-arrange items on drag
			if self.is_arrangeable then
				local index = self:getindex(GUI.mouse.y, GUI.ClampMode.ignore)

				local moved_items = {}
				for i, selected_item in ipairs(self.selected_items) do
					if not selected_item.parent or not selected_item.parent.selected then --don't need to move children (they go with the parent)
						table.insert(moved_items, selected_item)
					end
				end

				--set sort mode to ignore if user is rearranging items
				if self.is_sortable and self.current_sort ~= GUI.SortMode.ignore then self.current_sort = GUI.SortMode.ignore end

				if index <= 0 then
					self:addtoplevelitems(moved_items, 1, true)
					self:verticalscroll(-1)
				else
					local above_half = false

					--check to see if the mouse if above/below the item if it isn't way past the list
					if index and index < #self.list then
						above_half = self:estimatemouseposition(GUI.mouse.y, index)
					end

					--adds the moved items above/below the up_item's index
					if not above_half then

						--add the item to the top level tree
						if not item.parent or index > #self.list then
							local temp_index = GUI.CheckInTable(self.top_items, item)
							if temp_index > 0 then index = temp_index + 1 else index = nil end

							self:addtoplevelitems(moved_items, index, true)
						
						--if the item is parented then insert it in that index of the parent
						elseif item.parent and item.parent.is_parentable then
							local temp_index = GUI.CheckInTable(item.parent.children, item)
							if temp_index > 0 then index = temp_index + 1 else index = nil end

							item.parent:addchildren(moved_items, index, true)
							item:setexpanded(true)
							self:onexpand(item)
						end
					
					--add items parent to the selected one
					elseif above_half and item.is_parentable then
						item:addchildren(moved_items, 1, true) --this will always run when you are dropping it in the first index
						item:setexpanded(true)
						self:onexpand(item)
					end
				end

				self:onrearrange(moved_items, self.up_item)

			--selects the dragged range of items
			elseif self.is_multi and self.is_selectable then

				local items = {}

				--if shift not held down then clear old selection
				if GUI.mouse.cap & 8 ~= 8 then items = self:clearselection() end
				local dragged_items = self:selectrange(self.down_item, item, not self.down_item.selected)

				self:onselection(GUI.ExpandTable(items, dragged_items))
			end

		--un-selects whatever is selected if you click past the list box entries (i.e. in blank space underneath options)
		elseif not item then
			self:clearselection()
			self:onselection({})

		--expands the item if you clicked over the symbol
		elseif self:oversymbol(item) and self.is_expandable then
				local state = not item.expanded
				local retval = item:setexpanded(state)

				if retval then
					if not state then
						self:oncollapse(item)
					else
						self:onexpand(item)
					end
				end
			
		--select the item
		elseif self:overitem(item) and self.is_selectable and item.is_selectable then
			local items

			if self.is_multi then

				-- Ctrl toggles selected line on/off
				if GUI.mouse.cap & 4 == 4 then
					items = self:toggleselected(item)

				-- Shift extends selection
				elseif last_up and GUI.mouse.cap & 8 == 8 then
					items = self:selectrange(last_up, item) --select range between the last item that the mouse was let up on and this one
			
				--toggle item if it is already selected
				elseif item.selected then
					items = self:toggleselected(item)

				--select only that item
				else
					items = self:selectonly(item)
				end

			else
				
				--if you click on the already selected item then just flip it, otherwise make the new item the only selection
				if last_up == item then
					items = self:toggleselected(item)
				else
					items = self:selectonly(item)
				end
			end

			if GUI.IsTreeItem(items) then items = {items} end --convert to a table for simplicity
			if #items > 0 then self:onselection(items) end
		end

		self:redraw(true)
		return self.up_item
	else
		self:redraw(true)
		return
	end
end


function GUI.Tree:onmousedown(scroll)
	--[[
		records when the user clicks on the mouse button, tells the list to scroll if that is what the user is doing 
	]]--

	if self.is_dragging then self.is_dragging = false end --flip bool that tells tool that the last mouse down was from is_dragging

	-- If over the scrollbar, or we came from :ondrag with an origin point
	-- that was over the scrollbar...

	if (scroll and GUI.mouse.cap == 0) or self:oververticalscrollbar() then
		
		self:verticalscroll()

	elseif (scroll and GUI.mouse.cap == 8) or self:overhorizontalscrollbar() then

		self:horizontalscroll()

	else
		self.down_item = self:getitem(GUI.mouse.y)
		self.down_position = {x=GUI.mouse.x, y=GUI.mouse.y}
	end
end


function GUI.Tree:ondoubleclick()
	--[[
		expand the item that you doubleclick (if it has children) and only select that item
	]]--

	if self.is_doubleclick_expand and self.is_expandable then
		
		local item = self:getitem(GUI.mouse.y)

		if not item then return end

		if #item.children > 0 then
			local state = not item.expanded

			local retval = item:setexpanded(state)

			if retval then
				if state then
					self:onexpand(item)
				else
					self:oncollapse(item)
				end
			end
		end 

		self:selectonly(item)

		self:redraw()
	end
end


function GUI.Tree:ondrag()
	--[[
		control when the user starts dragging
		start the drawing for selection/arranging UI
	]]--

	if self:oververticalscrollbar(GUI.mouse.ox) or self:overhorizontalscrollbar(GUI.mouse.oy) then 
		
		self:onmousedown(true)
		
	elseif not self.is_dragging then

		self.is_dragging = true

		--select the down pressed item if it isn't already and you are dragging it
		if self.is_arrangeable and self.down_item and not self.down_item.selected and GUI.CheckInTable(self.selected_items, self.down_item) == 0 then
			self:selectitem(self.down_item)
			self:onselection(self.down_item)
		end
	end

	self:redraw()
	
end


function GUI.Tree:onwheel(inc)
	--[[
		scroll up/down/left/right when the user interacts with the mouse wheel
	]]--

	local dir = inc > 0 and -1 or 1

	-- Scroll up/down one line
	if GUI.mouse.cap == 0 then
		self:verticalscroll(dir)
	elseif GUI.mouse.cap == 8 then
		self:horizontalscroll(dir * 10)
	end

	self:onscroll()

	self:redraw()
end


function GUI.Tree:ontype()
	--[[
		copies the selected item text when cntrl + c is hit
	]]--

	if GUI.char == 3 and GUI.mouse.cap == 4 then
		self:copyitemtext(self.selected_items)
	end
end





------------------------
-------- Window --------
------------------------

function GUI.Tree:estimatemouseposition(y, index, clamp_mode)
	--[[
		figures out whether or not the mouse position is hovering over the top half or bottom half of the TreeItem
		used for figuring out arranging

		param y: (number) the mouse position
		param index: (optional number) the item that the mouse is hovering over
		param clamp_mode: (optional GUI.ClampMode) used to determine what TreeItem is clicked on

		return: (bool) true if the mouse if hovering over the top half of the item, false if on the lower half
	]]--

	if not index then index = self:getindex(y, clamp_mode) end

	local top = ((index - 1) * self.char_h) + self.y + self.pad
	local half = top + (self.char_h / 2)

	return y <= half
end


function GUI.Tree:getindex(y, clamp_mode)
	--[[
		finds the index of the item that is at the position

		param y: (number) the mouse position
		param clamp_mode: (optional GUI.ClampMode) used to determine what TreeItem is clicked on

		return: (number) the index at the positions
	]]--

	if not clamp_mode then clamp_mode = GUI.ClampMode.none end

	GUI.font(self.font_b)

	local index = math.floor(	(y - (self.y + self.pad))
								/	self.char_h)
				+ self.wnd_y

	if (clamp_mode ~= GUI.ClampMode.ignore and self.is_clamp) or clamp_mode == GUI.ClampMode.force then
		index = GUI.clamp(1, index, #self.list)
	end

	return index
end


function GUI.Tree:getitem(y, clamp_mode)
	--[[
		determine which item the user clicked on

		param y: (number) the mouse position
		param clamp_mode: (optional GUI.ClampMode) used to determine what TreeItem is clicked on

		return: (TreeItem) the item that the user clicked on, or nil if index is past the list
	]]--

	local index = self:getindex(y, clamp_mode)

	if index > #self.list then
		return nil
	else
		return self.list[index]
	end
end


function GUI.Tree:oververticalscrollbar(x)
	--[[
		determines if the mouse is over the vertical scrollbar or not

		return: (bool) true if it is over the scrollbar, false if not
	]]--

	return (#self.list > self.wnd_h and (x or GUI.mouse.x) >= (self.x + self.w - 12))
end


function GUI.Tree:overhorizontalscrollbar(y)
	--[[
		determines if the mouse is over the horizontal scrollbar or not

		return: (bool) true if it is over the scrollbar, false if not
	]]--

	return ((y or GUI.mouse.y) >= (self.y + self.h - 12))
end


--return true if the mouse is over the expansion/collapse symbol
function GUI.Tree:oversymbol(item)
	if #item.children == 0 then return false end

	local expand_string = item.display:gsub(GUI.EscapeString(item.text), "")

	--return true if the user selected the symbol
	if self:wnd_mouse() <= gfx.measurestr(expand_string) then
		return true
	else
		return false
	end
end


function GUI.Tree:overitem(item)
	--[[
		figures out if the passed item is being selected based off of the selection mode

		param item: (TreeItem) the item you want to determine if it is being selected or not

		return: (bool) true if the item is being selected, otherwise false
	]]--

	if self.selection_mode == GUI.SelectionMode.row then
		return true
	elseif self.selection_mode == GUI.SelectionMode.text or self.selection_mode == GUI.SelectionMode.text_space then
		return self:overtext(item)
	end

	return false
end


--return true if the mouse if over the item's text
function GUI.Tree:overtext(item)
	--[[
		determine's if the mouse is over the item's text based off of selection mode

		param item: (TreeItem) the item that you are trying to figure things out for

		return: (bool) true if the mouse is over the item's text, otherwise false
	]]--

	GUI.font(self.font_b)

	local pad_w, text_w = self:wnd_item(item)
	local mouse_x = self:wnd_mouse()
	
	if pad_w > mouse_x then 									--return false if the mouse is over and space to the left of the text
		return false
	else
		if self.selection_mode == GUI.SelectionMode.text then 	--return true if mouse is over the text exactly (no space) and that is the selection mode
			return mouse_x <= pad_w + text_w + 5 					--give it an extra pad
		else
			return true 										--return true if the mouse isn't to the left of the text/over the pad
		end
	end
end

 
function GUI.Tree:wnd_recalc()
	--[[
		updates internal values for the window size
	]]--
	
	GUI.font(self.font_b)
    
    self.char_w, self.char_h = gfx.measurestr("_")
	self.wnd_h = math.floor((self.h - 2*self.pad) / self.char_h)
	self.wnd_w = math.floor((self.w + 2*self.pad) / self.char_w)

end


function GUI.Tree:wnd_bottom()
	--[[
		get the bottom edge of the window (in rows)

		return: (number) the bottom edge of the window
	]]--

	return self.wnd_y + self.wnd_h
end


function GUI.Tree:wnd_right()
	--[[
		get the right edge of the window

		return: (number) the right edge of the window
	]]--

	return self.wnd_x + self.wnd_w
end


function GUI.Tree:wnd_mouse()
	--[[
		gets the position of mouse x and y relative to the window

		return: (number) the relative x position of the mouse in the window
		return: (number) the relative y position of the mouse in the window
	]]--

	return GUI.round(GUI.mouse.x - self.x), GUI.round(GUI.mouse.y - self.y)
end


function GUI.Tree:wnd_item(item)
	--[[
		determines the width of the item's pad (spacing) and text - i.e. the width before where the item's text starts and width until it ends

		param item: (TreeItem) the item you want to check

		return: (number) the width of the item's pad
		return: (number) the width of the item's text
	]]--

	local pad_match, text_match = item.display:match("(.-)(" .. GUI.EscapeString(item.text) .. ")")
	if not pad_match or not text_match then return 0, 0 end

	GUI.font(self.font_b)
	local pad_w = gfx.measurestr(pad_match)
	local text_w = gfx.measurestr(text_match)

	return pad_w, text_w
end


function GUI.Tree:wnd_outside()
	--[[
		determines if the mouse is outside of the element
		used for scrolling on drag

		return: (table) where the mouse is relative to the element - true if in that quadrant, false otherwise
	]]--
	
	local position = {left=false, right=false, top=false, bottom=false}

	local x, y = GUI.mouse.x, GUI.mouse.y

	if x <= self.x then
		position.left = true
	elseif self:oververticalscrollbar(x) then
		position.right = true
	end

	if y <= self.y then
		position.top = true
	elseif self:overhorizontalscrollbar(y) then
		position.bottom = true
	end

	return position
end





---------------------------------
-------- Selection --------------
---------------------------------

function GUI.Tree:selectrange(item1, item2, state)
	--[[
		changes the first item to the second item to the selection state that is passed

		param item1: (TreeItem) the first item
		param item2: (TreeItem) the second item
		param state: (bool) true if the item should be selected, false is unselected
	]]--

	if not self.is_selectable then return {} end 

	local started, finished = false, false
	
	--pass a state in if the item hasn't already been flipped (i.e. on drag)
	if state == nil then
		state = item1.selected
	end

	local items = {}

	local start_index, end_index, counter

	if item1.index < item2.index then
		start_index = 1
		end_index = #self.showing_items
		counter = 1
	else
		start_index = #self.showing_items
		end_index = 1
		counter = -1
	end

	for i = start_index, end_index, counter do
		local item = self.showing_items[i]
		local is_select = false

		if item == item1 or item == item2 then
			is_select = true

			if not started then
				started = true
			elseif not finished then
				finished = true
			end

		elseif started then
			is_select = true
		end

		if is_select then
			if item.is_selectable then
				if item.selected ~= state then
					if state then
						self:selectitem(item)
					else
						self:unselectitem(item)
					end
				end

				table.insert(items, item)
			end

			--exit loop when you hit the second item
			if finished then
				break
			end
		end
	end

	self:redraw(true)

	return items
end


function GUI.Tree:selectitem(item)
	--[[
		sets the item to be selected

		param item: (TreeItem) the item you want to be selected

		return: (TreeItem) the item
	]]--

	if not self.is_selectable or not item.is_selectable then return end

	item.selected = true
	table.insert(self.selected_items, item)

	self.up_item = item

	self:sortselected()

	self:redraw(true)

	return item
end


function GUI.Tree:unselectitem(item)
	--[[
		sets the item to be unselected

		param item: (TreeItem) the item you want to be unselected

		return: (TreeItem) the item
	]]--

	local index = GUI.CheckInTable(self.selected_items, item)

	if index > 0 then
		self.selected_items[index].selected = false
		table.remove(self.selected_items, index)
	end

	self:redraw(true)

	return item
end


function GUI.Tree:toggleselected(item)
	--[[
		toggles the selection status of the item

		param item: (TreeItem) the item you want to be selected

		return: (TreeItem) the item
	]]--

	if not self.is_selectable or not item.is_selectable then return end

	item.selected = not item.selected

	if item.selected then
		table.insert(self.selected_items, item)
	else
		self:unselectitem(item)
	end

	self.up_item = item

	self:sortselected()

	self:redraw(true)

	return item
end


function GUI.Tree:selectonly(item)
	--[[
		sets the item to be selected and unselects any other selected items

		param item: (TreeItem) the item you want to be selected

		return: (TreeItem) the item
	]]--

	if not self.is_selectable or not item.is_selectable then return end

	self:clearselection()

	self:selectitem(item)

	self:redraw(true)

	return item
end


function GUI.Tree:clearselection()
	--[[
		unselects all selected items

		return: (table) the items that were unselected
	]]--

	for i, item in ipairs(self.selected_items) do
		item.selected = false
	end

	local items = self.selected_items

	self.selected_items = {}

	self:redraw(true)

	return items
end


function GUI.Tree:sortselected(is_reverse)
	--[[
		sorts the selected items so the ones lower in the list are first (i.e. the first one displayed is also first in selected_items, unless set to reverse)

		param is_reverse: (optional bool) if the order of the selected items should be reversed or not

		return: (bool) true on success
	]]--

	if #self.selected_items > 1 then
		local sort_func = nil
		if is_reverse then
			sort_func = function(item1, item2) return item1.index > item2.index end
		else
			sort_func = function(item1, item2) return item1.index < item2.index end
		end

		table.sort(self.selected_items, sort_func)
	end

	return true
end





---------------------------------
-------- Parenting --------------
---------------------------------

function GUI.Tree:addtoplevelitems(items, index)
	--[[
		adds the TreeItems passed to the top, base layer of the list

		param items: (table or TreeItem) the item(s) that you want to add to the top layer
		param index: (optional number) the spot where you want to add it to in the list, defualt is the end of the list
		
		return: (table) the items that were added on success
	]]--

	if GUI.IsTreeItem(items) then items = {items} end

	if index then
		if index > #self.top_items then
			index = nil
		elseif index < 1 then 
			index = 1
		end
	end

	for i, item in ipairs(items) do

		--decrease index in case the item you are adding is already a top level item and going after its current spot (removing from array will lower index)
		if index then
			local existing_index = GUI.CheckInTable(self.top_items, item)
			if existing_index > 0 and existing_index <= index then index = index - 1 end
		end

		--remove the item from current spot
		if item.parent then
			item.parent:removechildren(item)
		elseif item.tree and GUI.CheckInTable(self.top_items, item) then
			self:removetoplevelitems({item}) 
		end

		if index and index <= #self.top_items then
			table.insert(self.top_items, index, item)
			index = index + 1
		else
			table.insert(self.top_items, item)
		end

		item.tree = self

		item:updateitem(true)
	end

	--sort added top level items if stuff is set appropriately
	if self.is_sortable and self.current_sort ~= GUI.SortMode.ignore then self:sortitems(self.current_sort, self.top_items) end

	self:onitemadd(items)

	self:redraw()

	return items
end


function GUI.Tree:removetoplevelitems(items)
	--[[
		removes the TreeItems if they are on the top, base layer of the list

		param items: (table, TreeItem, or number) the item(s) that you want to remove from the top layer, if a number is provided it will remove the item at that spot in the top_items list
		
		return: (table) the items that were removed on success, nil on failure
	]]--

	if type(items) == "number" then
		if #self.top_items < items then return nil end
		local item = table.remove(self.top_items, items)

		item.tree = nil
		item:updateitem(true)

		items = {item}

	else
		if GUI.IsTreeItem(items) then
			items = {items}

		elseif type(items) == "table" then --make a shallow copy in case someone is passing self.top_items
			local temp = {}
			for i, item in ipairs(items) do
				table.insert(temp, item)
			end

			items = temp
			
		else
			return nil
		end

		for i, item in ipairs(items) do
			local remove_index

			for index, value in ipairs(self.top_items) do
				if value == item then
					remove_index = index
					break
				end
			end

			if remove_index then
				table.remove(self.top_items, remove_index)

				item.tree = nil
				item:updateitem(true)
			end
		end
	end

	self:onitemremove(items)

	self:redraw()

	return items
end


function GUI.Tree:clear()
	--[[
		clears the entire list of TreeItems that were part of the tree

		return: (table) the items that were removed on success
	]]--
	
	local items = self.top_items

	self.top_items = {}
	self.list = {}

	self.selected_items = {}
	self.showing_items = {}

	self:onitemremove(items)

	self:redraw()

	return items
end





---------------------------------
-------- Scroll -----------------
---------------------------------

function GUI.Tree:verticalscroll(dir)
	--[[
		scrolls the list vertically by dir

		param dir: (number) which direction the list should scroll by
	]]--

	if dir then
		self.wnd_y = GUI.clamp(1, self.wnd_y + dir, math.max(#self.list - self.wnd_h + 2, 1))
	else
		local wnd_c = GUI.round( ((GUI.mouse.y - self.y) / self.h) * #self.list  )
		self.wnd_y = math.floor( GUI.clamp(1, wnd_c - (self.wnd_h / 2), #self.list - self.wnd_h + 2) )
	end

	self:onscroll()

	self:redraw()
end


function GUI.Tree:horizontalscroll(dir)
	--[[
		scrolls the list horizontally by dir

		param dir: (number) which direction the list should scroll by
	]]--

	if dir then
		self.wnd_x = GUI.clamp(1, math.max(self.max_w - self.wnd_w + 2, 1), self.wnd_x + dir)
	else
		local wnd_c = GUI.round( ((GUI.mouse.x - self.x) / self.w) * self.max_w )
		self.wnd_x = math.floor( GUI.clamp(1, wnd_c - (self.wnd_w / 2), self.max_w - self.wnd_w + 2) )
	end

	self:onscroll()

	self:redraw()
end





---------------------------------
-------- SETTERS ----------------
---------------------------------

function GUI.Tree:setheader(new_header)
	--[[
		creates a new header with the info that you passed it
		requires a reinitialization of the tree element, so other things may be lost - must call this manually after creating the header

		param new_header: (table) the information you want to give to the new header

		return: (table/Header) the header table information
	]]--

	local has_old_header = (self.header and type(self.header) == "table" and self.header.type == "Header") and true or false

	--prevents potential stack overflow
	if not new_header or (has_old_header and new_header == self.header) then return end

	--remove the old header
	if has_old_header then
		self.header:delete()
		self.header = nil
	end

	if type(new_header) == "string" or not new_header.type then
		local header_name = new_header.name or self.name .. "-Header"

		local header_info = type(new_header) == "string" and {caption=new_header} or new_header

		header_info.z = header_info.z or self.z
		header_info.x = header_info.x or self.x
		header_info.y = header_info.y or self.y - 18
		header_info.w = header_info.w or self.w
		header_info.h = header_info.h or 18

		header_info.color = header_info.color or self.bg
		header_info.bg = header_info.bg or self.color

		--create header and store it
		GUI.New(header_name, "Header", header_info)
		self.header = GUI.elms[header_name]
	end

	--reimplement the header onmouseup function to sort the tree when clicked
	if self.is_sortable then

		--reimplement so tree is sorted when header is clicked
		self.header.onmouseup = function()
			GUI.Header.onmouseup(self.header)
			self:sortitems()
		end

		--reimplemented so that sort order gets ignored on right mouse up
		self.header.onmouser_up = function()
			GUI.Header.ondoubleclick(self.header)
			self.current_sort = GUI.SortMode.ignore
		end
	end

	self.header.tree = self --associate the header with the tree that it is for

	return self.header
end

function GUI.Tree:setdoubleclickexpand(state)
	self.is_doubleclick_expand = state
end

function GUI.Tree:setarrangeable(state)
	self.is_arrangeable = state
end

function GUI.Tree:setexpandable(state)
	self.is_expandable = state
end

function GUI.Tree:setmulti(state)
	self.is_multi = state
end

function GUI.Tree:setselectable(state)
	self.is_selectable = state
end

function GUI.Tree:setsortable(state)
	self.is_sortable = state
end

function GUI.Tree:setcurrentsort(sort_mode)
	self.current_sort = sort_mode
	self:sortitems(self.current_sort)
end

function GUI.Tree:setselectionmode(selection_mode)
	self.selection_mode = selection_mode
end





---------------------------------
-------- Helpers ----------------
---------------------------------

function GUI.Tree:copyitemtext(items)
	--[[
		writes the text of all the items passed to the clipboard, each item's text separated by a new line
		need SWS for this functionality

		param items: (table or TreeItem) the items that you want to copy

		return: (string) the text that was copied to the clipboard
	]]--

	if not items or not GUI.SWS_exists then return nil end

	if GUI.IsTreeItem(items) then items = {items} end

	local text = ""

	for i, item in ipairs(items) do
		text = text .. item.text .. "\n"
	end

	reaper.CF_SetClipboard(text)

	return text
end


function GUI.Tree:CSVtotable(str)
	--[[
		split a CSV into a table

		param str: (string) the CSV that you want to convert

		return: (table) the split up CSV
	]]--
	
	local tmp = {}
	for line in string.gmatch(str, "([^,]+)") do
		table.insert(tmp, line)
	end
	
	return tmp	
	
end


--formats the showing items into the list for display
function GUI.Tree:formatlist()
	--[[
		formats the items that are showing in the Tree into a table that gets converted to a string for display
	]]--

	for i = 1, #self.showing_items do self.showing_items[i].showing = false end --unselects any items that were showing

	--make a shallow copy of the items table and iterate through it backwards (so I'm not constantly rearranging the table)
	self.showing_items = {}
	self.list = {}
	local stack = GUI.ExpandTable({}, self.top_items, true)
	
	local index = 1

	self.max_w = 0 --reset max width when you have to reformat the list

	--make a one layer, deep copy list of all the items
	while #stack > 0 do
		item = table.remove(stack)

		if not item.is_hidden then
			table.insert(self.list, item)

			if item.expanded then
				stack = GUI.ExpandTable(stack, item.children, true)
			end

			self:updatestringwidth(item)

			item.showing = true
			table.insert(self.showing_items, item)

			item.index = index
			index = index + 1
		end
	end
end


function GUI.Tree:finditem(text, is_partial, ignore_case)
	--[[
		finds the item that matches the passed text

		param text: (string) the text you want to search for
		param is_partial: (optional bool) true if the match should be partial, default is false
		param ignore_case: (optional bool) true if the match can ignore case, default is false

		return: (TreeItem) the item that it matched with, or nil if nothing matched
	]]--	

	local match_func

	if is_partial then
		match_func = function(pattern, str) return str:find(GUI.EscapeString(pattern)) and true or false end
	else
		match_func = function(pattern, str) return pattern == str end
	end

	if ignore_case then text = text:lower() end

	local stack = GUI.ExpandTable({}, self.top_items, true)
	local item

	while #stack > 0 do
		item = table.remove(stack)
		
		local item_text = ignore_case and item.text:lower() or item.text

		--return item, otherwise extend the stack
		if match_func(text, item_text) then
			return item
		elseif #item.children > 0 then
			stack = GUI.ExpandTable(stack, item.children, true)
		end
	end

	return item
end


function GUI.Tree:sortitems(sort_mode, items)
	--[[
		controls sorting the tree items depending on the sort mode that is passed
		reimplement if you want to sort things in a different manner

		param sort_mode: (optional GUI.SortMode) the sort mode that you want to sort the tree by, otherwise it toggles the existing one
		param items: (optional table) if you want to sort specific items instead of the whole tree then pass a table, default is sorting the whole tree

		return: (table) the newly sorted top level items
	]]--

	local function sort(sort_table, is_reverse)
		if #sort_table > 1 then
			local sort_func = nil
			if is_reverse then
				sort_func = function(item1, item2)
					local num1, num2 = tonumber(item1.text), tonumber(item2.text)

					if num1 and num2 then
						return num1 > num2
					else
						return item1.text > item2.text
					end
				end
			else
				sort_func = function(item1, item2)
					local num1, num2 = tonumber(item1.text), tonumber(item2.text)

					if num1 and num2 then
						return num1 < num2
					else
						return item1.text < item2.text
					end
				end
			end

			table.sort(sort_table, sort_func)
		end
	end

	--main code that runs through all the lists

	--toggle the sorting mode if none was directly passed
	if not sort_mode then sort_mode = self:togglesortmode() end

	local is_reverse = false
	if sort_mode == GUI.SortMode.descending then is_reverse = true end

	--if passed a table of items then only sort that table
	if items and type(items) == "table" and #items > 1 and not GUI.IsTreeItem(items) then
		sort(items, is_reverse)

		self:redraw()

		return items

	--otherwise, sort the entire tree
	else
		sort(self.top_items, is_reverse) --sort the initial top level items

		local stack = GUI.ExpandTable({}, self.top_items)

		while #stack > 0 do
			local item = table.remove(stack)

			--if the item has children then sort them and make sure their children are sorted
			if #item.children > 0 then
				sort(item.children, is_reverse)
				stack = GUI.ExpandTable(stack, item.children)
			end
		end

		self:redraw()

		return self.top_items
	end
end


function GUI.Tree:togglesortmode()
	--[[
		toggles the sort mode for the tree (helper function if you want to reimplement sortitems and need toggle to work)

		return: (int) the toggled current sort mode
	]]


	local sort_mode

	if self.current_sort == GUI.SortMode.descending or self.current_sort == GUI.SortMode.ignore then
		sort_mode = GUI.SortMode.ascending
	else
		sort_mode = GUI.SortMode.descending
	end

	self.current_sort = sort_mode

	return sort_mode
end



function GUI.Tree:updatestringwidth(str)
	--[[
		records an internal value used to figure out when a horizontal scrollbar is needed

		param str: (string) the string that it needs to calculate against

		return: (number) the longest string's width
	]]--
	
	if GUI.IsTreeItem(str) then str = str.display end
	
	local str_w = str:len()
	if str_w > self.max_w then
		self.max_w = str_w + 1
	end

	return self.max_w
end


function GUI.Tree:val(newval)
	--[[
		deprecated - use GUI.Tree:clear() and GUI.Tree:addtoplevelitems() instead
		used to either get or set the top level items of the tree

		param newval: (optional table) the items that you want to replace the top layer with

		return: (bool or table) if newval returns on true on success, if not newval returns the top level items of the tree
	]]--


	if newval then
		self.list = newval
		
		self:init()

		self:redraw()

		return true
	else
		return self.top_items
	end
end


function GUI.Tree:ondelete()
	--[[
		function that runs when the element is deleted in order to free its buffer
	]]--

	GUI.FreeBuffer(self.buff)
end





---------------------------------
------ Signals ------------------
---------------------------------

function GUI.Tree:onscroll()
	--[[
		function that you can reimplement if you want something to happen on scroll
	]]--

end


function GUI.Tree:onitemadd(items)
	--[[
		function that you can reimplement if you want something to happen when a TreeItem is added

		param items: (table) the items that were just added
		
		return: table of the items that were added
	]]--

	return items
end

function GUI.Tree:onitemremove(items)
	--[[
		function that you can reimplement if you want something to happen when a TreeItem is removed

		param items: (table) the items that were just removed
	]]--

	return items
end


function GUI.Tree:onexpand(item)
	--[[
		function that you can reimplement if you want something to happen when a TreeItem is expanded

		param item: (TreeItem) the item that was expanded
	]]--
	
	return item
end

function GUI.Tree:oncollapse(item)
	--[[
		function that you can reimplement if you want something to happen when a TreeItem is collapsed

		param item: (TreeItem) the item that was collapsed
	]]--

	return item
end


function GUI.Tree:onrearrange(moved_items, up_item)
	--[[
		function that you can reimplement if you want something to happen when items get re-arranged
		*only sent when the user rearranges something by dragging*
	
		param moved_items: (table) the items that are being rearranged
		param up_item: (TreeItem) the item that the mouse was released on (the one that they are being moved it) - can be nil if moving to the top of the tree
	]]--

	return moved_items, up_item
end


function GUI.Tree:onselection(items)
	--[[
		function that you can reimplement if you want something to happen when items are selected
		*only sent when the user selects something - manually call when doing something programatically*

		param items: (table or TreeItem) single TreeItem that was selected if Tree is not set to multi select, otherwise table of all the items that were selected
	]]--
	
	if self.is_multi then
		return items[1]
	else
		return items
	end
end










---------------------
---- Item -----------
---------------------

GUI.TreeItem = {}
function GUI.TreeItem:new(text, info)
	--[[
		the element that each row in a tree is

		param text: (string) the caption/text for the item
		param info: (optional table) the info that should be passed to the TreeItem

		return: (TreeItem) the item that was created
	]]--
	
	local item = type(info) == "table" and info or {}

	item.type = "TreeItem"

	item.text = tostring(item.text or text) or '' 		--the caption for the item

	item.expanded = false 		--if the item is expanded/collapsed (false = collapse, true = expanded)
	item.selected = false 		--if the item is currently selected (false = unselected, true = selected)
	item.showing = false 		--if the item is currently being displayed (false = out of view, true = in view)

	item.is_hidden = false 		--if the item is not supposed to be displayed at all (false = show, true = hide), default false
	item.is_selectable = true 	--if the item is able to be selected (false = not selectable, true = selectable), default true
	item.is_expandable = true 	--if the item is able to be expanded/collapsed (false = not expandable, true = expandable), default true
	item.is_parentable = true	--set to false if you don't want the item to be able to be a parent on rearrange, default is true

	item.data = nil 			--any info that the item should hold reference to (useful when comparing things, accessing info later on, etc)

	--internal stuff that used to remeber states and whatnot
	item.display = item.text 	--formatted version of the text for internal use

	item.parent = nil 			--the item that this one is directly nested under, if any
	item.children = {} 			--the items that are directly nested under this one, if any

	item.tree = nil 			--the tree that this one is in

	item.depth = 0 				--base level items have a depth of 0, otherwise increments of 1
	item.index = 0

	setmetatable(item, self)
	self.__index = self

	GUI.TreeItem.init(item) --initializes the item on creation so you don't need to init every item

	return item
end


function GUI.TreeItem:init()
	--[[
		initializes the item and values for it

		return: (bool) true on success
	]]--

	if not self.parent then
		self.depth = 0

	else
		self.depth = self.parent.depth + 1
		self.tree = self.parent.tree
	end

	self:updatedisplaytext()

	return true
end


function GUI.TreeItem:updateitem()
	--[[
		helper function that does some clean up code whenever an item has been added/removed from the parent

		return: (bool) true on success
	]]--

	self:init()

	--change the depth for all of the other items that are within
	local stack = GUI.ExpandTable({}, self.children)
	while #stack > 0 do
		local item = table.remove(stack)
		item:init()

		if #item.children > 0 then
			stack = GUI.ExpandTable(stack, item.children)
		end
	end

	self:redrawtree()

	return true
end





---------------------
---- Parenting ------
---------------------

function GUI.TreeItem:addchildren(children, index) --index can be nil
	--[[
		adds children TreeItem's to the item

		param children: (table or TreeItem) the TreeItem(s) you want to add as children of this item
		param index: (optional number) the spot that you want to add the children to, default is at the end of the existing children
			
		return: (bool) true on success
	]]--

	if GUI.IsTreeItem(children) then children = {children} end

	if index then
		if index > #self.children then
			index = nil
		elseif index < 1 then
			index = 1
		end
	end

	for i, child in ipairs(children) do
		if child == self then --make sure you aren't trying to parent the parent to itself
			table.remove(children, i)

		else --re-adjust the index if the child is already parented to the parent (removing it would cause the index to get messed up)
		
			if index and child:inhierarchy(self) then
				local place = 0
				for j, temp in ipairs(self.children) do
					if temp == child then
						place = j
						break
					end
				end

				if place < index then index = index - 1 end
			end

			--if adding a parent to its child, remove the child from it and add it to the parent's parent or the tree's top level
			if self:inhierarchy(child) then
				child:removechildren({self})

				if child.parent then
					child.parent:addchildren({self}, nil, true)
				elseif child.tree then
					child.tree:addtoplevelitems(self, nil, true)
				end
			end

			--else if the child is already parented remove it from that parent
			if child.parent then
				child.parent:removechildren({child}, true)

			--else if the child is a top level item then remove it from the tree's top level
			elseif child.tree and GUI.CheckInTable(child.tree.top_items, child) then
				child.tree:removetoplevelitems(child, true)
			end

			--insert in the appropriate spot if index provided, otherwise add it to the end
			if index and index <= #self.children then
				table.insert(self.children, index, child)
				index = index + 1
			else
				table.insert(self.children, child)
			end

			child.parent = self
			child:updateitem(true)
		end
	end

	self:updatedisplaytext()

	if self.tree then

		--sort the children that you added if the tree is sortable
		if self.tree.is_sortable and self.tree.current_sort ~= GUI.SortMode.ignore then self.tree:sortitems(self.tree.current_sort, self.children) end

		self.tree:onitemadd(children)

		self:redrawtree()
	end

	return true
end


function GUI.TreeItem:removechildren(children)
	--[[
		removes the children from being parented to this item (if they are)

		param chldren: (table, TreeItem, or number) the TreeItem(s) you want to remove, if a number is provided it will remove the child at that index
		
		return: (table) the removed children on success, nil on failure
	]]--

	

	if type(children) == "number" then
		if #self.children < children then return nil end
		local child = table.remove(self.children, children)

		child.parent = nil
		child.tree = nil

		child:updateitem(true)

		children = {child}

	else
		if GUI.IsTreeItem(children) then
			children = {children}
		elseif type(children) == "table" then --make a shallow copy in case someone is passing self.children
			local temp = {}
			for i, item in ipairs(children) do
				table.insert(temp, item)
			end

			children = temp

		else
			return nil
		end

		for i, child in ipairs(children) do
			if child ~= self then --make sure you aren't trying to remove the parent from itself (although you never should be able to?)
				index = self:getindex(child)

				if index and index <= #self.children then
					table.remove(self.children, index)

					child.parent = nil
					child.tree = nil

					child:updateitem(true)
				end
			end
		end
	end

	self:updatedisplaytext()

	if self.tree then
		self.tree:onitemremove(children)

		self:redrawtree()
	end

	return children
end


--removes all children from the list
function GUI.TreeItem:clearchildren()
	--[[
		removes all children from being parented to the item

			
		return: (bool) true on success
	]]--

	local old_children = self.children

	self:removechildren(self.children)

	return old_children
end




----------------------
---- SETTERS ---------
----------------------

function GUI.TreeItem:setdata(data)
	--[[
		adds the data that the item holds to be that of the passed value

		param data: (object) the info that the item should hold as a reference

		return: (boolean) returns true on success
	]]--

	self.data = data

	return true
end


function GUI.TreeItem:setexpanded(state)
	--[[
		expands or collapses the item as long as it is expandable, must have children items in order to work

		param state: (bool) true if you want the item to expand, false if you want it to collapse
		
		return: (bool) returns true on success
	]]--

	if not self.is_expandable or #self.children == 0 then return false end

	self.expanded = state
	self:updatedisplaytext()

	--make sure no children items are still selected when collapsed
	if not state and #self.children > 0 then
		local stack = GUI.ExpandTable({}, self.children)
		while #stack > 0 do
			local item = table.remove(stack)
			
			if item.selected then
				item:setselected(false)
			end

			if #item.children > 0 then
				stack = GUI.ExpandTable(stack, item.children)
			end
		end
	end

	--send expand/collapse signal if the item is part of a tree
	if self.tree then
		if state then
			self.tree:onexpand(self)
		else
			self.tree:oncollapse(self)
		end
	end

	if self.tree then
		self:redrawtree()
	end

	return true
end


function GUI.TreeItem:sethidden(state)
	--[[
		sets the item as being visible or hidden so it will respectively appear, or not appear, in the tree

		param state: (bool) true if you want the item to be hidden, false if it is visible
		
		return: (bool) returns true on success
	]]--

	self.is_hidden = state
	self:redrawtree()

	return true
end


function GUI.TreeItem:setselected(state)
	--[[
		sets the item as being selected or not if the item is selectable
		doesn't take into account the tree's is_multi variable, which is only user facing

		param state: (bool) true if the item should be selected, false is unselected
		
		return: (bool) returns true on success
	]]--

	if not self.is_selectable then return false end

	self.selected = state

	self:redrawtree(true)

	return true
end


function GUI.TreeItem:settext(text)
	--[[
		sets the item's text/changes it depending on what you want it to be
		pass an empty string if you want to clear the item's text

		param text: (stirng) the new text that the item should display in the tree
		
		return: (bool) returns true on success
	]]--

	if not text then
		text = ""
	elseif type(text) ~= "string" then
		text = tostring(text)
	end

	self.text = text
	self:updatedisplaytext()

	self:redrawtree()

	return true
end


function GUI.TreeItem:setexpandable(state)
	--[[
		sets the item as being expandable, either programatically or by the user

		param state: (bool) true if it should be expandable, false if it should't be
		
		return: (bool) returns true on success
	]]--

	self.is_expandable = state

	return true
end


function GUI.TreeItem:setparentable(state)
	--[[
		tells the item whether it can have children items assigned to it or not
		setting this to false doesn't remove any current children items, it only prevents new ones from being added by re-arrangement

		param state: (bool) true if item can be a parent, false if not

		return: (bool) returns true on success
	]]--

	self.is_parentable = state

	return true
end


function GUI.TreeItem:setselectable(state)
	--[[
		sets the item as being selectable, either programatically or by the user

		param state: (bool) true if it should be selectable, false if it shouldn't be
		
		return: (bool) returns true on success
	]]--

	self.is_selectable = state

	self:redrawtree(true)

	return true
end





---------------------
---- Helpers --------
---------------------

function GUI.TreeItem:getindex(child)
	--[[
		returns the index that the given child is at in the item's children table

		param child: (TreeItem) the item that you want to check for

		return: (number or nil) the index that the item is at, if found, or nil
	]]--

	for index, value in ipairs(self.children) do
		if value == child then
			return index
		end
	end

	return nil
end


function GUI.TreeItem:getgrandparent()
	--[[
		finds the highest/base level parent in the item's hierarchy

		return: (TreeItem) the base level parent item
	]]--

	local item = self

	--loop through the hierarchy until there are no parents left
	while item do
		local parent = item.parent
		
		if parent then
			item = parent
		else
			break
		end
	end

	return item
end


function GUI.TreeItem:inhierarchy(check_item)
	--[[
		checks to see if the passed item is in the hierarchy above this item

		param check_item: (TreeItem) the item that you want to look for in the hierarchy

		return: (bool) true if the item is in the same hierarchy as the item, false if it isn't
	]]--

	local item = self

	while item do
		if item == check_item then
			return true
		else
			item = item.parent
		end
	end

	return false
end


function GUI.TreeItem:redrawtree(skip_format)
	--[[
		triggers a redrawing of the tree for actions that require it to be redrawn to be displayed (i.e. setting selected, adding children, etc)

		param skip_format: (bool) true if the tree doesn't need to redraw its displayed text on redraw - i.e. only selection changed

		return: (bool) true on success, false on failure
	]]--

	if not self.tree then
		return false
	elseif GUI.gfx_open and not GUI.elms_hide[self.tree.z]then
		self.tree:redraw(skip_format)
		return true
	end
end


function GUI.TreeItem:updatedisplaytext()
	--[[
		formats the displayed text to include the proper indentation and expand/collapse symbol so it looks parented in the tree
		may need to be reimplemented if you change the expand/collapse symbol

		return: (string) the formatted display text
	]]--

	self.display = ""

	if #self.children > 0 then
		local symbol = ""
		if self.expanded then symbol = GUI.Tree.expanded_symbol else symbol = GUI.Tree.collapsed_symbol end

		self.display = symbol .. "  " .. self.text
	else
		self.display = "      " .. self.text --adds a space if it isn't a parent so it can be inline with any parents next to it (symbol takes space)
	end

	--adds the indent in front of the display text
	if self.depth > 0 then
		for i = 1, self.depth do self.display = GUI.Tree.indent .. self.display end
	end

	return self.display
end










--------------------------------
------ Header ------------------
--------------------------------

GUI.Header = GUI.Element:new()

GUI.Header.ascending_symbol = "▲"	--the symbol for when the tree is in an ascending sort mode
GUI.Header.descending_symbol = "▼"	--the symbol for when the tree is in a descending sort mode


function GUI.Header:new(name, z, x, y, w, h, caption, alignment, tree, text_font, symbol_font, color, bg)
	--[[
		creates a new header element, which is a display of the tree that is clickable

		param name: (string) the name that you want the element to be named
		param z: (table or int)	if passed a table, it will take the place of all the other params you want to pass to the header, otherwise it is the z layer
		other params are defined below where they are initialized

		return: the new header element table
	]]--

	local header = (not x and type(z) == "table") and z or {}

	header.name = name
	header.type = "Header"
	header.tree = header.tree or tree or nil --the tree that the header is associated with - must be associated with a tree in order for sort to work

	header.z = header.z or z	
	
	header.x = header.x or x
    header.y = header.y or y
    header.w = header.w or w
    header.h = header.h or h

    header.caption = header.caption or caption or "" --the text that the header should display

	header.color = header.color or color or "elm_bg"
	header.bg = header.bg or bg or "txt"
	
	header.text_font = header.text_font or text_font or 2
	header.symbol_font = header.symbol_font or symbol_font or 3

	header.alignment = header.alignment or alignment or GUI.AlignMode.center|GUI.AlignMode.horizontal

	GUI.redraw_z[header.z] = true

	setmetatable(header, self)
	self.__index = self

	return header

end


function GUI.Header:init()
	--[[
		initializes the header
	]]--

	local x, y, w, h = self.x, self.y, self.w, self.h

	self.buff = self.buff or GUI.GetBuffer()

	gfx.dest = self.buff
	gfx.setimgdim(self.buff, -1, -1)
	gfx.setimgdim(self.buff, w, h)

	GUI.color(self.bg)
	gfx.rect(0, 0, w, h, 1)

	GUI.color("elm_frame")
	gfx.rect(0, 0, w, h, 0)
end


function GUI.Header:draw()
	--[[
		draws the header
	]]--

	local x, y, w, h = self.x, self.y, self.w, self.h

	local str = self.caption
    
    GUI.color(self.bg)
        
    gfx.rect(x, y, w, h, true)
    
    gfx.x, gfx.y = x, y
    
    gfx.set(r, g, b, a)	


    if self.tree and self.tree.is_sortable then
		local sort_symbol = ""
		if self.tree.current_sort == GUI.SortMode.ascending then
			sort_symbol = GUI.Header.ascending_symbol
		elseif self.tree.current_sort == GUI.SortMode.descending then
			sort_symbol = GUI.Header.descending_symbol
		end

		--draws the sort symbol (if there is one)
		if sort_symbol ~= "" then
			GUI.font(self.symbol_font)
			GUI.color(self.color)
			gfx.drawstr(sort_symbol, GUI.AlignMode.left | GUI.AlignMode.center, x+w, y+h)
		end
	end

	GUI.font(self.text_font)

    GUI.color(self.color)
	gfx.drawstr(str, self.alignment, x+w, y+h)
end


function GUI.Header:setalignment(alignment)
	--[[
		used to change the alignment of the header

		param alignment: (int) the new alignment that the header should have
	]]--

	self.alignment = alignment

	self:redraw()

	return self.alignment
end


function GUI.Header:setcaption(caption)
	--[[
		used to change the caption of the header

		param caption: (string) the new text that the header should display
	]]--

	self.caption = tostring(caption)

	self:redraw()

	return self.caption
end


function GUI.Header:onmouseup()

	self:redraw()

end

function GUI.Header:ondoubleclick()

	self:redraw()

end


function GUI.Header:ondelete()
	--[[
		removes this element from the window's buffer
	]]--

	GUI.FreeBuffer(self.buff)
end

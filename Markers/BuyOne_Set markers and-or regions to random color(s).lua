--[[
ReaScript name: Set markers and/or regions to random color(s) (7 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
Metapackage: true
Provides: [main] . > BuyOne_Set markers and-or regions to random color(s)/BuyOne_Set markers and-or regions to random color(s) (all in one).lua
		      [main] . > BuyOne_Set markers and-or regions to random color(s)/BuyOne_Set markers to random colors (respecting time sel.).lua
		      [main] . > BuyOne_Set markers and-or regions to random color(s)/BuyOne_Set markers to 1 random color (respecting time sel.).lua
		      [main] . > BuyOne_Set markers and-or regions to random color(s)/BuyOne_Set regions to random colors (respecting time sel.).lua
		      [main] . > BuyOne_Set markers and-or regions to random color(s)/BuyOne_Set regions to 1 random color (respecting time sel.).lua
		      [main] . > BuyOne_Set markers and-or regions to random color(s)/BuyOne_Set markers + regions to random colors (respecting time sel.).lua
		      [main] . > BuyOne_Set markers and-or regions to random color(s)/BuyOne_Set markers + regions to 1 random color (respecting time sel.).lua
About: Sets project markers and/or regions to random colors obeying time selection, if any.
	   The script comes in 7 instances, 1 includes all available options as a menu and the 
	   other 6 specialize in one type of operation only, being suitable to be included 
	   in custom actions.  
	   
	   In the script 'BuyOne_Set markers and-or regions to random color(s) (all in one)' 
	   which contains all available options in a menu, a menu item can be run with a numeric
	   keyboard shortcut corresponding to the number of such menu item.	 
	   
	   Other available scripts with some or all functionalities of this one:  
	   X-Raym_Color current region or regions in time selection randomly with same color.lua  
	   X-Raym_Color current region or regions in time selection randomly.lua  
	   zaibuyidao_Random Marker Color.lua  
	   zaibuyidao_Random Marker Region Color.lua  
	   zaibuyidao_Random Region Color.lua

]]


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = scr_name:match('([^\\/_]+)%.%w+')

local retval, mrkr_cnt, rgn_cnt = r.CountProjectMarkers(0)
local obj = scr_name:match('markers') and scr_name:match('regions') and 'markers or regions' or scr_name:match('markers') and 'markers' or 'regions'

	if retval == 0 then r.MB('There\'re no '..obj..'.','ALERT',0) return r.defer(function() do return end end) end


	if scr_name:match('all in one') then

	gfx.init('',0,0)

	-- sets menu position to mouse
	-- https://www.reaper.fm/sdk/reascript/reascripthelp.html#lua_gfx_variables
	gfx.x = gfx.mouse_x
	gfx.y = gfx.mouse_y
	menu = {'&1: Set MARKERS to random colors','||&2: Set MARKERS to 1 random color','||&3: Set REGIONS to random colors','||&4: Set REGIONS to 1 random color','||&5: Set markers + regions to random colors','||&6: Set markers + regions to 1 random color','||#            TIME SELECTION IS RESPECTED|#       IF NO MARKER OR REGION IS WITHIN|#TIME SELECTION — A MESSAGE IS GENERATED'} -- to be used for undo point naming as well
	output = gfx.showmenu(table.concat(menu))

	gfx.quit()

	else

	-------------- FOR INDIVIDUAL SCRIPTS ---------------
	scr_name = scr_name:match('(.+) %(res')
	menu = {['Set markers to random colors'] = 1, ['Set markers to 1 random color'] = 2, ['Set regions to random colors'] = 3, ['Set regions to 1 random color'] = 4, ['Set markers + regions to random colors'] = 5, ['Set markers + regions to 1 random color'] = 6}
	output = menu[scr_name]
	-----------------------------------------------------

	end


function RANDOM_RGB_COLOR()
math.randomseed(math.floor(r.time_precise()*1000)) -- seems to facilitate greater randomization at fast rate thanks to milliseconds count
local RGB = {r = 0, g = 0, b = 0}
	for k in pairs(RGB) do -- adds randomization (i think) thanks to pairs which traverses in no particular order // once it picks up a particular order it keeps at it throughout the entire main repeat loop when multiple colors are being set
	RGB[k] = math.random(1,256)-1 -- seems to produce 2 digit numbers more often than (0,255), but could be my imagination
	end
return RGB
end


local start, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false
local time_sel = start ~= fin

	if output > 0 then

	local RGB = RANDOM_RGB_COLOR()
	local both = output == 5 or output == 6

	local double_obj = scr_name:match('markers') and scr_name:match('regions')

	local x, y = r.GetMousePosition()
	
	-- If objects tergeted by selected option don't exist in the project; presence in time selection is evaluated further below
	local obj = both and double_obj and mrkr_cnt == 0 and 'MARKERS' or both and double_obj and rgn_cnt == 0 and 'REGIONS'
		if obj then
		local x, y = r.GetMousePosition()
		r.TrackCtl_SetToolTip(('\n\n THERE\'RE NO '..obj..' \n\n     IN THE PROJECT \n\n '):gsub('.', '%0 '), x, y, true) -- topmost true
		end

	r.Undo_BeginBlock()

	local i = 0
	local mrkr_cnt = 0
	local rgn_cnt = 0
		repeat
		local retval, isrgn, pos, rgnend, name, markrgnidx, color = r.EnumProjectMarkers3(0, i)
		local mrkr_cond = not isrgn and (output == 1 or output == 2 or both) and (not time_sel or time_sel and pos >= start and pos <= fin)
		local rgn_cond = isrgn and (output == 3 or output == 4 or both) and (not time_sel or time_sel and (pos >= start and pos <= fin or rgnend >= start and rgnend <= fin))
			if mrkr_cond or rgn_cond then
			-- count markers/regions within time selection when it's there to generate an alert message or tooltip below
			mrkr_cnt = mrkr_cond and mrkr_cnt + 1 or mrkr_cnt
			rgn_cnt = rgn_cond and rgn_cnt + 1 or rgn_cnt
			local time = r.time_precise()
				repeat -- gives the API time to process the following expression, otherwise one color ends up being applied regardless of the selected option
				until r.time_precise() - time >= .001
			RGB = output%2 == 0 and RGB or RANDOM_RGB_COLOR() -- one color or many
			r.SetProjectMarker3(0, markrgnidx, isrgn, pos, rgnend, '', r.ColorToNative(RGB.r,RGB.g,RGB.b)|0x1000000) -- isrgn as rgn_cond which is true or false
			end
		i = i+1
		until time_sel and pos > fin or retval == 0

		local obj = both and mrkr_cnt == 0 and rgn_cnt == 0 and 'markers or regions' or (output == 1 or output == 2) and mrkr_cnt == 0 and 'markers' or (output == 3 or output == 4) and rgn_cnt == 0 and 'regions' or both and mrkr_cnt == 0 and 'markers' or both and rgn_cnt == 0 and 'regions'
			if obj and not both or obj == 'markers or regions' then r.MB('There\'re no '..obj..' in time selection.', 'ALERT', 0) -- if none of the targeted objects is found within time selection
			return r.defer(function() do return end end)
			elseif obj then -- if one of the targeted objects isn't found within time selection
			r.TrackCtl_SetToolTip(('\n\n THERE\'RE NO '..string.upper(obj)..' \n\n   IN TIME SELECTION \n\n '):gsub('.', '%0 '), x, y, true) -- topmost true
			undo = menu[output] and menu[output]:match('Set.+') or scr_name -- excluding numbers and separators
			undo = obj == 'markers' and undo:gsub(obj..' %+ ', '') or undo:gsub(' %+ '..obj, '') -- exclude from undo point name mention of the object absent in time selection
			end

	r.Undo_EndBlock(undo or menu[output] and menu[output]:match('Set.+') or scr_name, -1) -- excluding numbers and separators

	end




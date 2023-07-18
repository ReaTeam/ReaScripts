    ------------------------------------------------------
    -----------Style Editor ------------------------------
    ------------------------------------------------------
        function demo.HelpMarker(desc)
            r.ImGui_TextDisabled(ctx, '(?)')
            if r.ImGui_IsItemHovered(ctx) then
            r.ImGui_BeginTooltip(ctx)
            r.ImGui_PushTextWrapPos(ctx, r.ImGui_GetFontSize(ctx) * 35.0)
            r.ImGui_Text(ctx, desc)
            r.ImGui_PopTextWrapPos(ctx)
            r.ImGui_EndTooltip(ctx)
            end
        end

        function demo.PopStyle()
            if app.style_editor and app.style_editor.push_count > 0 then
                app.style_editor.push_count = app.style_editor.push_count - 1
                r.ImGui_PopStyleColor(ctx, #cache['Col'])
                --r.ImGui_PopStyleVar(ctx, #cache['StyleVar'])
            elseif NeedtoPopStyle then 
                for i in demo.EachEnum('Col') do
                    r.ImGui_PopStyleColor(ctx)
                end
            elseif DefaultThemeActive then 
                r.ImGui_PopStyleColor(ctx,DefaultStylePop)
            end
        end

        function demo.PushStyle()
            if app.style_editor then
                app.style_editor.push_count = app.style_editor.push_count + 1
                --[[ for i, value in pairs(app.style_editor.style.vars) do
                        if type(value) == 'table' then
                            r.ImGui_PushStyleVar(ctx, i, table.unpack(value))
                        else
                            r.ImGui_PushStyleVar(ctx, i, value)
                        end
                end ]]
                for i, value in pairs(app.style_editor.style.colors) do
                        r.ImGui_PushStyleColor(ctx, i, value)
                end
            else 
                local file_path = ConcatPath(reaper.GetResourcePath(), 'Scripts', 'ReaTeam Scripts', 'FX', 'BryanChi_FX Devices', 'ThemeColors.ini')
                local file = io.open(file_path, 'r')

                
                
                if file then 
                    local content = file:read("a+")



                    
                    for i, v in pairs (CustomColors) do 
                        _G[v] =  RecallGlobInfo(content, v..' = ', 'Num')
                    end

                    
                end
                    DefaultThemeActive = true 
                    ------------------- Default Color Theme --------------------
                    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_FrameBg(), 0x48484837)
                    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_FrameBgHovered(), 0x49494966)
                    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_FrameBgActive(), 0x3F3F3FAB)
                    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Button(),0x57575786)
                    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonHovered(),0x6F6F6F86)
                    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonActive(),0x90909086)
                    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonActive(),0x57575786)
                    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_SliderGrab(),0x616161FF)
                    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_SliderGrabActive(),0xD1D1D1AC)
                    DefaultStylePop = 9

        
            end
        end

        


        function demo.EachEnum(enum)
            local enum_cache = cache[enum]
            if not enum_cache then
            enum_cache = {}
            cache[enum] = enum_cache
        
            for func_name, func in pairs(reaper) do
                local enum_name = func_name:match(('^ImGui_%s_(.+)$'):format(enum))
                if enum_name then
                table.insert(enum_cache, { func(), enum_name })
                end
            end
            table.sort(enum_cache, function(a, b) return a[1] < b[1] end)
            end
        
            local i = 0
            return function()
            i = i + 1
            if not enum_cache[i] then return end
            return table.unpack(enum_cache[i])
            end
        end
        

        function CallFile(mode, filename, folder)
            local dir_path
            if folder then 
                dir_path = ConcatPath(r.GetResourcePath(),'Scripts', 'ReaTeam Scripts', 'FX', 'BryanChi_FX Devices' , folder)
            else 
                dir_path = ConcatPath(r.GetResourcePath(),'Scripts', 'ReaTeam Scripts', 'FX', 'BryanChi_FX Devices' )
            end
            local file_path = ConcatPath(dir_path, filename)
            
            -- Create directory for file if it doesn't exist
            r.RecursiveCreateDirectory(dir_path, 0)
            local file = io.open(file_path,  mode)
            return file, file_path
        end

        function PushStyle_AtScriptStart()
            local file, file_path = CallFile('r', 'ThemeColors.ini')
            if file then 
                local Lines = get_lines(file_path)
                for i in demo.EachEnum('Col') do
                    r.ImGui_PushStyleColor(ctx,1,0x372837ff)
                end
            else 
                ----- Default Color theme ---------------
            end

        end
        --PushStyle_AtScriptStart()

        

        function demo.GetStyleData()
            local data = { vars={}, colors={} }
            local vec2 = {
            'ButtonTextAlign', 'SelectableTextAlign', 'CellPadding', 'ItemSpacing',
            'ItemInnerSpacing', 'FramePadding', 'WindowPadding', 'WindowMinSize',
            'WindowTitleAlign','SeparatorTextAlign', 'SeparatorTextPadding'
            }
        
            for i, name in demo.EachEnum('StyleVar') do
            local rv = {r.ImGui_GetStyleVar(ctx, i)}
            local is_vec2 = false
            for _, vec2_name in ipairs(vec2) do
                if vec2_name == name then
                is_vec2 = true
                break
                end
            end
            data.vars[i] = is_vec2 and rv or rv[1]
            end
            for i in demo.EachEnum('Col') do
            data.colors[i] = r.ImGui_GetStyleColor(ctx, i)
            end
            return data
        end


        
        function demo.CopyStyleData(source, target)
            for i, value in pairs(source.vars) do
            if type(value) == 'table' then
                target.vars[i] = {table.unpack(value)}
            else
                target.vars[i] = value
            end
            end
            for i, value in pairs(source.colors) do
            target.colors[i] = value
            end
        end

        function ShowStyleEditor()
            local rv
            

            if not ctx then  ctx = r.ImGui_CreateContext('Style Editor 2') end 
            if not styleEditorIsOpen then r.ImGui_SetNextWindowSize(ctx,500, 800) end 
            open,OpenStyleEditor = r.ImGui_Begin(ctx, 'FX Devices Style Editor', OpenStyleEditor, r.ImGui_WindowFlags_TopMost()+r.ImGui_WindowFlags_NoCollapse()+r.ImGui_WindowFlags_NoDocking()--[[ +r.ImGui_WindowFlags_AlwaysAutoResize() ]])


            if open  then 
                styleEditorIsOpen = true 
                if not app.style_editor then
                app.style_editor = {
                    style  = demo.GetStyleData(),
                    ref    = demo.GetStyleData(),
                    output_dest = 0,
                    output_only_modified = false,
                    push_count = 0,
                }
                end
            
                r.ImGui_PushItemWidth(ctx, r.ImGui_GetWindowWidth(ctx) * 0.50)
            
                local FrameRounding, GrabRounding = r.ImGui_StyleVar_FrameRounding(),
                                                    r.ImGui_StyleVar_GrabRounding()
                --[[ rv,app.style_editor.style.vars[FrameRounding] = r.ImGui_SliderDouble(ctx, 'FrameRounding', app.style_editor.style.vars[FrameRounding], 0.0, 12.0, '%.0f')
                if rv then
                app.style_editor.style.vars[GrabRounding] = app.style_editor.style.vars[FrameRounding] -- Make GrabRounding always the same value as FrameRounding
                end ]]

                r.ImGui_PushItemWidth(ctx, r.ImGui_GetFontSize(ctx) * 8)
            
                local Alpha, DisabledAlpha = r.ImGui_StyleVar_Alpha(), r.ImGui_StyleVar_DisabledAlpha()
                rv,app.style_editor.style.vars[Alpha] = r.ImGui_DragDouble(ctx, 'Global Alpha', app.style_editor.style.vars[Alpha], 0.005, 0.20, 1.0, '%.2f') -- Not exposing zero here so user doesn't "lose" the UI (zero alpha clips all widgets). But application code could have a toggle to switch between zero and non-zero.
                r.ImGui_SameLine(ctx)
                rv,app.style_editor.style.vars[DisabledAlpha] = r.ImGui_DragDouble(ctx, 'Disabled Alpha', app.style_editor.style.vars[DisabledAlpha], 0.005, 0.0, 1.0, '%.2f'); r.ImGui_SameLine(ctx); demo.HelpMarker('Additional alpha multiplier for disabled items (multiply over current value of Alpha).')
                r.ImGui_PopItemWidth(ctx)


                



            
                local borders = { 'WindowBorder', 'FrameBorder', 'PopupBorder' }
                for i, name in ipairs(borders) do
                local var = r[('ImGui_StyleVar_%sSize'):format(name)]()
                local enable = app.style_editor.style.vars[var] > 0
                if i > 1 then r.ImGui_SameLine(ctx) end
                rv, enable = r.ImGui_Checkbox(ctx, name, enable)
                if rv then app.style_editor.style.vars[var] = enable and 1 or 0 end
                end
            
                -- Save/Revert button
                --[[ if r.ImGui_Button(ctx, 'Save Ref') then
                demo.CopyStyleData(app.style_editor.style, app.style_editor.ref)
                end
                r.ImGui_SameLine(ctx)
                if r.ImGui_Button(ctx, 'Revert Ref') then
                demo.CopyStyleData(app.style_editor.ref, app.style_editor.style)
                end
                r.ImGui_SameLine(ctx) ]]
                
                --[[ r.ImGui_SameLine(ctx)
                demo.HelpMarker(
                'Save/Revert in local non-persistent storage. Default Colors definition are not affected. \z
                Use "Export" below to save them somewhere.')
                r.ImGui_SameLine(ctx)
                ]]

                --[[ if r.ImGui_Button(ctx, 'Factory Reset Color Theme') then
                    DltClrTheme = true  
                end
                if DltClrTheme then 

                    local file, file_path = CallFile('a', 'ThemeColors.ini')
                    if r.ImGui_BeginPopup( ctx, 'You Sure you want to delete color theme?',r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_NoResize() ) then 

                        if r.ImGui_Button(ctx, 'No') then DltClrTheme = false  r.ImGui_CloseCurrentPopup(ctx)    end 
                        if r.ImGui_Button(ctx, 'Yes') then file:close() file:remove(file_path) DltClrTheme=false  end 
                        r.ImGui_EndPopup(ctx)
                    end
                end  ]]
            
                local export = function(enumName, funcSuffix, curTable, refTable, isEqual, formatValue)
                local lines, name_maxlen = {}, 0
                for i, name in demo.EachEnum(enumName) do
                    if not app.style_editor.output_only_modified or not isEqual(curTable[i], refTable[i]) then
                    table.insert(lines, { name, curTable[i] })
                    name_maxlen = math.max(name_maxlen, name:len())
                    end
                end
            
                if app.style_editor.output_dest == 0 then
                    r.ImGui_LogToClipboard(ctx)
                else
                    r.ImGui_LogToTTY(ctx)
                end
                for _, line in ipairs(lines) do
                    local pad = string.rep('\x20', name_maxlen - line[1]:len())
                    r.ImGui_LogText(ctx, ('reaper.ImGui_Push%s(ctx, reaper.ImGui_%s_%s(),%s %s)\n')
                    :format(funcSuffix, enumName, line[1], pad, formatValue(line[2])))
                end
                if #lines == 1 then
                    r.ImGui_LogText(ctx, ('\nreaper.ImGui_Pop%s(ctx)\n'):format(funcSuffix))
                elseif #lines > 1 then
                    r.ImGui_LogText(ctx, ('\nreaper.ImGui_Pop%s(ctx, %d)\n'):format(funcSuffix, #lines))
                end
                r.ImGui_LogFinish(ctx)
                end
            
                --[[  if r.ImGui_Button(ctx, 'Export Vars') then
                    --- for enum
                    export('StyleVar', 'StyleVar', app.style_editor.style.vars, app.style_editor.ref.vars,
                    function(a, b) if type(a) == 'table' then return a[1] == b[1] and a[2] == b[2] else return a == b end end,
                    function(val) if type(val) == 'table' then return ('%g, %g'):format(table.unpack(val)) else return ('%g'):format(val) end end)
                end
                r.ImGui_SameLine(ctx) ]]
                if r.ImGui_Button(ctx, 'Export Colors') then
                    -- for each enum
                    local file = CallFile('w', 'ThemeColors.ini')

                    if file then 
                        --[[ for i, name in demo.EachEnum('Col') do
                            if r.ImGui_TextFilter_PassFilter(app.style_editor.colors.filter.inst, name) then
                                file:write(name, ' - ', r.ImGui_GetStyleColor(ctx, )'\n')
                            end
                        end ]]

                        for i, value in pairs(app.style_editor.style.colors) do
                            --[[ if i == 0 then 
                                file:write(55, ' = ', r.ImGui_GetStyleColor(ctx,r.ImGui_Col_ModalWindowDimBg() ),'\n')
                            elseif i > 0 then 
                                file:write(i, ' = ', app.style_editor.style.colors[i-1],'\n')
                            end ]]

                        end
                        --[[ for i, name in demo.EachEnum('Col') do 
                            file:write(name..' = '.. r.ImGui_GetStyleColor(ctx,r.ImGui_Col_ModalWindowDimBg() ))
                        end  ]]





                        for i, v in pairs(CustomColors) do 
                            file:write(v, ' = ', _G[v],'\n')
                        end
                    end
                    --[[ export('Col', 'StyleColor', app.style_editor.style.colors, app.style_editor.ref.colors, ]]
                    --[[ function(a, b) return a == b end, function(val) return ('0x%08X'):format(val & 0xffffffff) end) ]]


                end

                
        





                r.ImGui_Separator(ctx)
            
                --if r.ImGui_BeginTabBar(ctx, '##tabs', r.ImGui_TabBarFlags_None()) then
                --[[  if r.ImGui_BeginTabItem(ctx, 'Sizes') then
                    local slider = function(varname, min, max, format)
                    local func = r['ImGui_StyleVar_' .. varname]
                    assert(func, ('%s is not exposed as a StyleVar'):format(varname))
                    local var = func()
                    if type(app.style_editor.style.vars[var]) == 'table' then
                        local rv,val1,val2 = r.ImGui_SliderDouble2(ctx, varname, app.style_editor.style.vars[var][1], app.style_editor.style.vars[var][2], min, max, format)
                        if rv then app.style_editor.style.vars[var] = { val1, val2 } end
                    else
                        local rv,val = r.ImGui_SliderDouble(ctx, varname, app.style_editor.style.vars[var], min, max, format)
                        if rv then app.style_editor.style.vars[var] = val end
                    end
                    end
            
                    r.ImGui_Text(ctx, 'Main')
                    slider('WindowPadding',     0.0, 20.0, '%.0f')
                    slider('FramePadding',      0.0, 20.0, '%.0f')
                    slider('CellPadding',       0.0, 20.0, '%.0f')
                    slider('ItemSpacing',       0.0, 20.0, '%.0f')
                    slider('ItemInnerSpacing',  0.0, 20.0, '%.0f')
                    -- slider('TouchExtraPadding', 0.0, 10.0, '%.0f')
                    slider('IndentSpacing',     0.0, 30.0, '%.0f')
                    slider('ScrollbarSize',     1.0, 20.0, '%.0f')
                    slider('GrabMinSize',       1.0, 20.0, '%.0f')
                    r.ImGui_Text(ctx, 'Borders')
                    slider('WindowBorderSize', 0.0, 1.0, '%.0f')
                    slider('ChildBorderSize',  0.0, 1.0, '%.0f')
                    slider('PopupBorderSize',  0.0, 1.0, '%.0f')
                    slider('FrameBorderSize',  0.0, 1.0, '%.0f')
                    -- slider('TabBorderSize',    0.0, 1.0, '%.0f')
                    r.ImGui_Text(ctx, 'Rounding')
                    slider('WindowRounding',    0.0, 12.0, '%.0f')
                    slider('ChildRounding',     0.0, 12.0, '%.0f')
                    slider('FrameRounding',     0.0, 12.0, '%.0f')
                    slider('PopupRounding',     0.0, 12.0, '%.0f')
                    slider('ScrollbarRounding', 0.0, 12.0, '%.0f')
                    slider('GrabRounding',      0.0, 12.0, '%.0f')
                    -- slider('LogSliderDeadzone', 0.0, 12.0, '%.0f')
                    slider('TabRounding',       0.0, 12.0, '%.0f')
                    r.ImGui_Text(ctx, 'Alignment')
                    slider('WindowTitleAlign', 0.0, 1.0, '%.2f')
                    -- int window_menu_button_position = app.style_editor.style.WindowMenuButtonPosition + 1
                    -- if (ctx, r.ImGui_Combo(ctx, 'WindowMenuButtonPosition', (ctx, int*)&window_menu_button_position, "None\0Left\0Right\0"))
                    --     app.style_editor.style.WindowMenuButtonPosition = window_menu_button_position - 1
                    -- r.ImGui_Combo(ctx, 'ColorButtonPosition', (ctx, int*)&app.style_editor.style.ColorButtonPosition, "Left\0Right\0")
                    slider('ButtonTextAlign', 0.0, 1.0, '%.2f')
                    r.ImGui_SameLine(ctx); demo.HelpMarker('Alignment applies when a button is larger than its text content.')
                    slider('SelectableTextAlign', 0.0, 1.0, '%.2f')
                    r.ImGui_SameLine(ctx); demo.HelpMarker('Alignment applies when a selectable is larger than its text content.')
                    -- r.ImGui_Text(ctx, 'Safe Area Padding')
                    -- r.ImGui_SameLine(ctx); demo.HelpMarker('Adjust if you cannot see the edges of your screen (ctx, e.g. on a TV where scaling has not been configured).')
                    -- slider('DisplaySafeAreaPadding', 0.0, 30.0, '%.0f')
                    r.ImGui_EndTabItem(ctx)
                end ]]
            
                --[[ if r.ImGui_BeginTabItem(ctx, 'Colors') then ]]
                    if not app.style_editor.colors then
                    app.style_editor.colors = {
                        filter = { inst=nil, text = '' },
                        alpha_flags = r.ImGui_ColorEditFlags_AlphaPreviewHalf(),
                    }
                    end





                    -- the filter object is destroyed once unused for one or more frames
                    if not r.ImGui_ValidatePtr(app.style_editor.colors.filter.inst, 'ImGui_TextFilter*') then
                    app.style_editor.colors.filter.inst = r.ImGui_CreateTextFilter(app.style_editor.colors.filter.text)
                    end
            
                    if r.ImGui_TextFilter_Draw(app.style_editor.colors.filter.inst, ctx, 'Filter colors', r.ImGui_GetFontSize(ctx) * 16) then
                    app.style_editor.colors.filter.text = r.ImGui_TextFilter_Get(app.style_editor.colors.filter.inst)
                    end
            
                    if r.ImGui_RadioButton(ctx, 'Opaque', app.style_editor.colors.alpha_flags == r.ImGui_ColorEditFlags_None()) then
                    app.style_editor.colors.alpha_flags = r.ImGui_ColorEditFlags_None()
                    end
                    r.ImGui_SameLine(ctx)
                    if r.ImGui_RadioButton(ctx, 'Alpha',  app.style_editor.colors.alpha_flags == r.ImGui_ColorEditFlags_AlphaPreview()) then
                    app.style_editor.colors.alpha_flags = r.ImGui_ColorEditFlags_AlphaPreview()
                    end
                    r.ImGui_SameLine(ctx)
                    if r.ImGui_RadioButton(ctx, 'Both',   app.style_editor.colors.alpha_flags == r.ImGui_ColorEditFlags_AlphaPreviewHalf()) then
                    app.style_editor.colors.alpha_flags = r.ImGui_ColorEditFlags_AlphaPreviewHalf()
                    end
                    r.ImGui_SameLine(ctx)
                    demo.HelpMarker(
                    'In the color list:\n\z
                    Left-click on color square to open color picker,\n\z
                    Right-click to open edit options menu.')
                    
                    if r.ImGui_BeginChild(ctx, '##colors', 0, 0, true,
                                        r.ImGui_WindowFlags_AlwaysVerticalScrollbar()   |
                                        
                                    -- r.ImGui_WindowFlags_NavFlattened()) TODO: BETA/INTERNAL, not exposed yet
                                        0) then
                        r.ImGui_PushItemWidth(ctx, -160)
                        local inner_spacing = r.ImGui_GetStyleVar(ctx, r.ImGui_StyleVar_ItemInnerSpacing())

                        -- @todo  add custom colors here
                        function addClr(str)
                            rv, _G[str] = r.ImGui_ColorEdit4(ctx, '##'..str, _G[str] , r.ImGui_ColorEditFlags_AlphaBar() | app.style_editor.colors.alpha_flags)
                            r.ImGui_SameLine(ctx, 0.0, inner_spacing)
                            r.ImGui_Text(ctx, str)
                        end
                        r.ImGui_Text(ctx,'Specific Colors')  AddSpacing(2) 
                        
                        for i, v in pairs(CustomColors) do 
                            if r.ImGui_TextFilter_PassFilter(app.style_editor.colors.filter.inst, v) then

                                rv, _G[v] = r.ImGui_ColorEdit4(ctx, '##'..v, _G[v] or CustomColorsDefault[v] , r.ImGui_ColorEditFlags_AlphaBar() | app.style_editor.colors.alpha_flags)
                                r.ImGui_SameLine(ctx, 0.0, inner_spacing)
                                local name = string.gsub(v,'_', ' ')
                                r.ImGui_Text(ctx, name)
                            end
                        end




                        --[[ for i, name in demo.EachEnum('Col') do
                            if r.ImGui_TextFilter_PassFilter(app.style_editor.colors.filter.inst, name) then
                                r.ImGui_PushID(ctx, i)
                                rv, app.style_editor.style.colors[i] = r.ImGui_ColorEdit4(ctx, '##color', app.style_editor.style.colors[i], r.ImGui_ColorEditFlags_AlphaBar() | app.style_editor.colors.alpha_flags)
                                if app.style_editor.style.colors[i] ~= app.style_editor.ref.colors[i] then
                                    -- Tips: in a real user application, you may want to merge and use an icon font into the main font,
                                    -- so instead of "Save"/"Revert" you'd use icons!
                                    -- Read the FAQ and docs/FONTS.md about using icon fonts. It's really easy and super convenient!
                                    r.ImGui_SameLine(ctx, 0.0, inner_spacing)
                                    if r.ImGui_Button(ctx, 'Save') then
                                    app.style_editor.ref.colors[i] = app.style_editor.style.colors[i]
                                    end
                                    r.ImGui_SameLine(ctx, 0.0, inner_spacing)
                                    if r.ImGui_Button(ctx, 'Revert') then
                                    app.style_editor.style.colors[i] = app.style_editor.ref.colors[i]
                                    end
                                end
                                r.ImGui_SameLine(ctx, 0.0, inner_spacing)
                                r.ImGui_Text(ctx, name)
                                r.ImGui_PopID(ctx)
                            end
                        end ]]

                        



                    r.ImGui_PopItemWidth(ctx)
                    r.ImGui_EndChild(ctx)
                    end
            
                    --r.ImGui_EndTabItem(ctx)
                --[[ end ]]
            
                
            
                --r.ImGui_EndTabBar(ctx)
                --end
            
                r.ImGui_PopItemWidth(ctx)
                r.ImGui_End(ctx)
            else styleEditorIsOpen = false     
            end

        end


        function Show_KBShortcutEditor()   local rv

            if not ctx then  ctx = r.ImGui_CreateContext('Shortcut Editor') end 
            if not KBEditorIsOpen then r.ImGui_SetNextWindowSize(ctx,500, 800) end 
            open,OpenKBEditor = r.ImGui_Begin(ctx, 'FX Devices Shortcut Editor', OpenKBEditor, r.ImGui_WindowFlags_NoCollapse()+r.ImGui_WindowFlags_NoDocking()--[[ +r.ImGui_WindowFlags_AlwaysAutoResize() ]])


            if open  then 
                KBEditorIsOpen=true
                --[[ rv = r.ImGui_BeginTable(ctx, 'Keyboard Shortcut Table',  1 ,nil  ,  outer_size_w ,  outer_size_h, inner_width )
                r.ImGui_Text(ctx, 'adfafd')
                r.ImGui_EndTable(ctx) ]]

                local HoverKeyTime = HoverKeyTime or 0

                if r.ImGui_Button(ctx,'+') then 
                    local  x,  y = r.ImGui_GetWindowPos( ctx)
                    local  w,  h = r.ImGui_GetWindowSize( ctx)
                    
                    r.ImGui_SetNextWindowPos(ctx, x+w/3.5, y+h/2)
                    r.ImGui_OpenPopup(ctx, '##Type Key Popup') 
                end
                SL()

                if r.ImGui_Button(ctx, 'Save') then 
                    local file = CallFile('w', 'Keyboard Shortcuts.ini')
                    for i , v in pairs(KB_Shortcut) do 
                        file:write(v, ' = ', Command_ID[i],'\n')
                        
    
                    end
                end 


                SL()
                MyText('(?)', nil, 0xffffff66) 
                if r.ImGui_IsItemHovered(ctx) then 
                    HintToolTip('Start by click on the + and entering a key or key combination \nLeft click on a shortcut key to swap assigned actions \nAlt+Left click to remove shortcut')
                end
 

                if   r.ImGui_BeginPopupModal(ctx, '##Type Key Popup',nil,r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_AlwaysAutoResize()) then 
                    r.ImGui_Text(ctx, 'Type Key or mouse-click to cancel')

                    for i, v in pairs(AllAvailableKeys) do 
                        if r.ImGui_IsKeyPressed( ctx, v ) then 
                            local function GetFinalTxt (i) local txt 
                                if Mods == 0 then   txt = i 
                                elseif Mods == Alt then txt = 'Alt + '..i
                                elseif Mods == Ctrl then txt =  'Ctrl + '..i
                                elseif Mods == Shift then  txt =  'Shift + '..i
                                elseif Mods == Apl then txt = 'Cmd + '..i
                                elseif Mods == Alt + Ctrl then  txt =  'Alt + Ctrl + '.. i
                                elseif Mods == Ctrl + Shift then txt =  'Ctrl + Shift + '.. i
                                elseif Mods == Alt + Shift then txt =  'Alt + Shift + '..i
                                elseif Mods == Alt + Apl then txt =  'Alt + Cmd + '..i
                                elseif Mods == Shift + Apl then txt =  'Shift + Cmd + '..i
                                elseif Mods == Ctrl + Apl then txt = 'Ctrl + Cmd'..i

                                end
                                return  txt 

                            end
                            
                            if ShortCutKeyToSwitch then 

                                if not tablefind (KB_Shortcut, GetFinalTxt(i)) then 
                                    KB_Shortcut[ShortCutKeyIndex] =  GetFinalTxt(i)

                                end

                                AlreadyAddedKey = GetFinalTxt(i)

                                ShortCutKeyToSwitch = nil 
                                ShortCutKeyIndex=nil


                            elseif not tablefind (KB_Shortcut, GetFinalTxt(i)) then 

                                table.insert(KB_Shortcut, GetFinalTxt(i))
                            end



                            r.ImGui_CloseCurrentPopup(ctx)  

                        end
                    end

                    if r.ImGui_IsMouseClicked(ctx,0) then 
                        r.ImGui_CloseCurrentPopup(ctx)  
                    end

                    r.ImGui_EndPopup(ctx)
                end

                
                for i , v in ipairs(KB_Shortcut) do 
                    if r.ImGui_Button(ctx, v ) then 
                        ShortCutKeyToSwitch = v 
                        ShortCutKeyIndex = i 
                        r.ImGui_OpenPopup(ctx, '##Type Key Popup') 

                    end 

                    if r.ImGui_IsItemClicked(ctx) and Mods == Alt then 
                        table.remove(KB_Shortcut,i)
                    end


                    if AlreadyAddedKey == v   then 
                        r.ImGui_SetScrollHereY( ctx)
                        _, stop = BlinkItem(0.3,3.5)
                        if stop == 'Stop' then  AlreadyAddedKey = nil end 
                    end

                    SL() r.ImGui_Text(ctx, ' : ') SL()
                    local CmdTxt ,commandID


                    if Command_ID[i] then 
                         commandID = r.NamedCommandLookup(Command_ID[i])
                         CmdTxt = r.CF_GetCommandText(0, commandID)
                    end
                    if CmtTxt == '' then CmdTxt=nil end 

                    if r.ImGui_Button(ctx, (CmdTxt or ' Click to Paste Command ID')..'##'..i)   then 
                        Command_ID[i] = r.ImGui_GetClipboardText(ctx) 
                    end 
                    
                    if AlreadyAddedKey == v   then 
                        _, stop = BlinkItem(0.3,3.5)

                    end
                        
                    

                    --rv, Command_ID[i] = r.ImGui_InputText(ctx, '##'..i , Command_ID[i] or 'Paste Command ID Here...', r.ImGui_InputTextFlags_AutoSelectAll())

                    r.ImGui_Separator(ctx)
                end







                r.ImGui_End(ctx)

            else 
                KBEditorIsOpen = false     
            end
        end

    ------------------------------------------------------
    -----------END OF Style Editor -----------------------
    ------------------------------------------------------
 

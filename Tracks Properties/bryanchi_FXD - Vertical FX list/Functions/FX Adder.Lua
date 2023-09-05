-- @noindex



-------------------FX List by Sexan--------------------

local max = math.max
local MAX_FX_SIZE = 0

function FX_NAME(str, i)
    local vst_name
    if str then
        if str:find('=<.+>') then -- if it's AU
            local maker = str:sub(0, str:find(':%s') - 1)
            local ActualName = str:sub(str:find(':%s') + 2, str:find('=<.+>') - 1)
            --vst_name = 'AU:'.. ActualName..' ('.. maker..')'
            vst_name = 'AU:' .. str:gsub('=<.+>', '')
            --[[ elseif str:find('.vst=') or str:find('.vst<') then
                    local nm = str
                    vst_name= 'VST:'..nm:sub( 0, (nm:find('%.vst=') or nm:find('%.vst<')) +3 )
                    vst_name= vst_name:gsub('_', ' ')
                    Manufacturer =  (nm:sub(nm:find('%(') or 0, nm:find('/n')) or 0) ]]
        elseif str:find('.vst=') or str:find('.vst<') then
            local comma = 1

            for i = 1, 2 do                                     -- Since there are 2 comma's in each line
                comma = string.find(str, ",", (comma or 0) + 1) -- find 'next' comma
            end

            if comma then
                vst_name = "VST:" .. str:sub(comma + 1, str:find('\n'))
            end
            --[[  for nm in str:gmatch('[^%,]+')  do  --- Split Line into segments spearated by comma
                        vst_name = nm:match("(%S+ .-%))") and "VST:" .. (nm:match("(%S+ .-%))") or '')
                        Manufacturer =  (nm:sub(nm:find('%(') or 0, nm:find('/n')) or 0)

                    end  ]]
        elseif str:find('.vst3=') or str:find('.vst3<') then
            local comma = 1

            for i = 1, 2 do                                     -- Since there are 2 comma's in each line
                comma = string.find(str, ",", (comma or 0) + 1) -- find 'next' comma
            end

            if comma then
                vst_name = "VST3:" .. str:sub(comma + 1, str:find('\n'))
            end
        else
            for name_segment in str:gmatch('[^%,]+') do --- Split Line into segments spearated by comma
                if name_segment:match("(%S+) ") then    -- if segment has space in it
                    if name_segment:match('"(JS: .-)"') then
                        vst_name = name_segment:match('"JS: (.-)"') and "JS:" .. name_segment:match('"JS: (.-)"') or nil
                        --[[ elseif name_segment:find('=<.+>') then   -- AU Plugins
                                vst_name = 'AU:'.. name_segment:gsub('=<.+>', '') ]]
                    else
                        vst_name = name_segment:match("(%S+ .-%))") and "VST:" .. name_segment:match("(%S+ .-%))") or nil
                    end
                elseif name_segment:find('%.vst=') then -- if it's vst
                    local nm = name_segment
                    vst_name = 'VST:' .. nm:sub(0, nm:find('%.vst=') - 1)
                    vst_name = vst_name:gsub('_', ' ')
                elseif name_segment:find('%.vst3=') then -- if it's vst3
                    local nm = name_segment
                    vst_name = 'VST3:' .. nm:sub(0, nm:find('%.vst3=') - 1)
                    vst_name = vst_name:gsub('_', ' ')
                elseif name_segment:find('%.vst.dylib=') then
                    local nm = name_segment -- Reaper Native plugins
                    vst_name = 'VST:' .. nm:sub(0, nm:find('%.vst.dylib=') - 1)
                end
            end
        end
        if vst_name then vst_name = vst_name:gsub('!!!VSTi', '') end
        if vst_name == 'VST:<SHELL>' or vst_name == 'VST3:<SHELL>' then vst_name = nil end
        if vst_name then return vst_name end
    end
end

function GetFileContext(fp)
    local str = "\n"
    local f = io.open(fp, 'r')
    if f then
        str = f:read('a')
        f:close()
    end
    return str
end

-- Fill function with desired database
function Fill_fx_list()
    local tbl_list   = {}
    local tbl        = {}

    local vst_path   = r.GetResourcePath() .. "/reaper-vstplugins64.ini"
    local vst_str    = GetFileContext(vst_path)

    local vst_path32 = r.GetResourcePath() .. "/reaper-vstplugins.ini"
    local vst_str32  = GetFileContext(vst_path32)

    local jsfx_path  = r.GetResourcePath() .. "/reaper-jsfx.ini"
    local jsfx_str   = GetFileContext(jsfx_path)

    local au_path    = r.GetResourcePath() .. "/reaper-auplugins_arm64.ini"
    local au_str     = GetFileContext(au_path)

    local plugins    = vst_str .. vst_str32 .. jsfx_str .. au_str

    for line in plugins:gmatch('[^\r\n]+') do tbl[#tbl + 1] = line end

    -- CREATE NODE LIST
    for i = 1, #tbl do
        local fx_name = FX_NAME(tbl[i])
        if fx_name then
            tbl_list[#tbl_list + 1] = fx_name
        end
    end
    return tbl_list
end

local function Lead_Trim_ws(s) return s:match '^%s*(.*)' end

local function Filter_actions(filter_text)
    --filter_text = Lead_Trim_ws(filter_text)
    local t = {}
    if filter_text == "" or not filter_text then return t end
    for i = 1, #FX_LIST do
        local action = FX_LIST[i]
        local name = action:lower()
        local found = true
        for word in filter_text:gmatch("%S+") do
            if not name:find(word:lower(), 1, true) then
                found = false
                break
            end
        end

        if found then t[#t + 1] = action end
    end
    return t
end


function FilterBox(FX_Idx, LyrID, SpaceIsBeforeRackMixer, FxGUID_Container, SpcIsInPre, SpcInPost, SpcIDinPost)
    local FX_Idx_For_AddFX, close
    if AddLastSPCinRack then FX_Idx_For_AddFX = FX_Idx - 1 end
    local MAX_FX_SIZE = 250
    local FxGUID = FXGUID[FX_Idx_For_AddFX or FX_Idx]


    r.ImGui_AlignTextToFramePadding(ctx)
    r.ImGui_Text(ctx, 'Add FX:')
    SL()
    r.ImGui_SetNextItemWidth(ctx, 180)
    _, ADDFX_FILTER = r.ImGui_InputText(ctx, '##input', ADDFX_FILTER, r.ImGui_InputTextFlags_AutoSelectAll())

    if r.ImGui_IsWindowAppearing(ctx) then
        local tb = Fill_fx_list()
        r.ImGui_SetKeyboardFocusHere(ctx, -1)
    end

    local filtered_fx = Filter_actions(ADDFX_FILTER)
    --r.ImGui_SetNextWindowPos(ctx, r.ImGui_GetItemRectMin(ctx), ({ r.ImGui_GetItemRectMax(ctx) })[2])
    local filter_h = #filtered_fx == 0 and 2 or (#filtered_fx > 40 and 20 * 17 or (17 * #filtered_fx))
    local function InsertFX(Name)
        local FX_Idx = FX_Idx
        --- CLICK INSERT
        if SpaceIsBeforeRackMixer == 'End of PreFX' then FX_Idx = FX_Idx + 1 end
        r.TrackFX_AddByName(LT_Track, Name, false, -1000 - FX_Idx)

        -- if Inserted into Layer
        local FxID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

        if FX.InLyr[FxGUID] == FXGUID_RackMixer and FX.InLyr[FxGUID] then
            DropFXtoLayerNoMove(FXGUID_RackMixer, LyrID, FX_Idx)
        end
        if SpaceIsBeforeRackMixer == 'SpcInBS' then
            DropFXintoBS(FxID, FxGUID_Container, FX[FxGUID_Container].Sel_Band, FX_Idx + 1, FX_Idx)
        end
        if SpcIsInPre then
            local inspos = FX_Idx + 1
            if SpaceIsBeforeRackMixer == 'End of PreFX' then
                table.insert(Trk[TrkID].PreFX, FxID)
            else
                table.insert(Trk[TrkID].PreFX, FX_Idx + 1, FxID)
            end
            for i, v in pairs(Trk[TrkID].PreFX) do r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, v, true) end
        elseif SpcInPost then
            if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then offset = -1 else offset = 0 end
            table.insert(Trk[TrkID].PostFX, SpcIDinPost + offset + 1, FxID)
            -- InsertToPost_Src = FX_Idx + offset+2
            for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '', true)
            end
        end

        ADDFX_FILTER = nil
    end
    if ADDFX_FILTER ~= '' and ADDFX_FILTER then
        SL()
        r.ImGui_SetNextWindowSize(ctx, MAX_FX_SIZE, filter_h + 20)
        local x, y = r.ImGui_GetCursorScreenPos(ctx)

        ParentWinPos_x, ParentWinPos_y = r.ImGui_GetWindowPos(ctx)
        local VP_R = VP.X + VP.w
        if x + MAX_FX_SIZE > VP_R then x = ParentWinPos_x - MAX_FX_SIZE end

        r.ImGui_SetNextWindowPos(ctx, x, y - filter_h / 2)
        if r.ImGui_BeginPopup(ctx, "##popupp", r.ImGui_WindowFlags_NoFocusOnAppearing() --[[ MAX_FX_SIZE, filter_h ]]) then
            ADDFX_Sel_Entry = SetMinMax(ADDFX_Sel_Entry or 1, 1, #filtered_fx)
            for i = 1, #filtered_fx do
                local ShownName
                if filtered_fx[i]:find('VST:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(5, (fx:find('.vst') or 999) - 1)
                    local clr = FX_Adder_VST or CustomColorsDefault.FX_Adder_VST
                    MyText('VST', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                elseif filtered_fx[i]:find('VST3:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(6) .. '##vst3'
                    local clr = FX_Adder_VST3 or CustomColorsDefault.FX_Adder_VST3
                    MyText('VST3', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                elseif filtered_fx[i]:find('JS:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(4)
                    local clr = FX_Adder_JS or CustomColorsDefault.FX_Adder_JS
                    MyText('JS', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                elseif filtered_fx[i]:find('AU:') then
                    local fx = filtered_fx[i]
                    ShownName = fx:sub(4)
                    local clr = FX_Adder_AU or CustomColorsDefault.FX_Adder_AU
                    MyText('AU', nil, clr)
                    SL()
                    HighlightSelectedItem(nil, clr, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                end

                if r.ImGui_Selectable(ctx, (ShownName or filtered_fx[i]) .. '##emptyName', DRAG_FX == i) then
                    if filtered_fx[i] then
                        InsertFX(filtered_fx[i])
                        r.ImGui_CloseCurrentPopup(ctx)
                        close = true
                    end
                end
                if i == ADDFX_Sel_Entry then
                    HighlightSelectedItem(0xffffff11, nil, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                end
                -- DRAG AND DROP
                if r.ImGui_IsItemActive(ctx) and r.ImGui_IsMouseDragging(ctx, 0) then
                    -- HIGHLIGHT DRAGGED FX
                    DRAG_FX = i
                    AddFX_Drag(filtered_fx[i])
                end
            end

            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Enter()) then
                InsertFX(filtered_fx[ADDFX_Sel_Entry])
                ADDFX_Sel_Entry = nil
            elseif r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_UpArrow()) then
                ADDFX_Sel_Entry = ADDFX_Sel_Entry - 1
            elseif r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_DownArrow()) then
                ADDFX_Sel_Entry = ADDFX_Sel_Entry + 1
            end
            --r.ImGui_EndChild(ctx)
            r.ImGui_EndPopup(ctx)
        end


        r.ImGui_OpenPopup(ctx, "##popupp")
        r.ImGui_NewLine(ctx)
    end


    if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Escape()) then
        r.ImGui_CloseCurrentPopup(ctx)
        ADDFX_FILTER = nil
    end
    return close
end

function AddFX_Drag(name)
    if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_AcceptNoDrawDefaultRect()) then
        r.ImGui_SetDragDropPayload(ctx, 'AddFX_Sexan', tostring(name))
        r.ImGui_Text(ctx, name)
        r.ImGui_EndDragDropSource(ctx)
    end
end

function AddFX_drop(FX_Idx)
    if r.ImGui_BeginDragDropTarget(ctx) then
        local ret, payload = r.ImGui_AcceptDragDropPayload(ctx, 'AddFX_Sexan', nil)
        r.ImGui_EndDragDropTarget(ctx)
        if ret then
            local fx_name = payload
            r.TrackFX_AddByName(LT_Track, fx_name, false, -1000 - FX_Idx)
            DRAG_FX = nil
        end
    end
end

local function frame()
    OPEN_FILTER = r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_A())

    if OPEN_FILTER and not r.ImGui_IsAnyItemActive(ctx) then
        OPEN_FILTER = nil
        if not r.ImGui_IsPopupOpen(ctx, "FILTER LIST") then
            ADDFX_FILTER = ''
            r.ImGui_OpenPopup(ctx, "FILTER LIST")
        end
    end
    -- OPEN FX LIST
    if r.ImGui_BeginPopup(ctx, "FILTER LIST") then
        if FilterBox(FX_Idx) then r.ImGui_CloseCurrentPopup(ctx) end
        r.ImGui_EndPopup(ctx)
    end

    -- DRAG AND DROP HERE
    for i = 1, 5 do
        reaper.ImGui_Selectable(ctx, "TRACK " .. i, false, nil, 50, size_hIn)
        AddFX_drop(i)
    end
end


FX_LIST = Fill_fx_list()
-------- End Of FX List



function AddFX_Sexan(Dest)
    dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'AddFX_Sexan')
    Dvdr.Clr[ClrLbl] = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_Button())
    Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width
    if dropped then
        local FX_Idx = FX_Idx
        if SpaceIsBeforeRackMixer == 'End of PreFX' then FX_Idx = FX_Idx + 1 end
        r.TrackFX_AddByName(LT_Track, payload, false, -1000 - FX_Idx, false)
        local FxID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
        local _, nm = r.TrackFX_GetFXName(LT_Track, FX_Idx)

        --if in layer
        if FX.InLyr[FXGUID_To_Check_If_InLayer] == FXGUID_RackMixer and SpaceIsBeforeRackMixer == false or AddLastSPCinRack == true then
            DropFXtoLayerNoMove(FXGUID_RackMixer, LyrID, FX_Idx)
        end
        Dvdr.Clr[ClrLbl], Dvdr.Width[TblIdxForSpace] = nil, 0

        if SpcIsInPre then
            if SpaceIsBeforeRackMixer == 'End of PreFX' then
                table.insert(Trk[TrkID].PreFX, FxID)
            else
                table.insert(Trk[TrkID].PreFX, FX_Idx + 1, FxID)
            end
            for i, v in pairs(Trk[TrkID].PreFX) do r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, v, true) end
        elseif SpcInPost then
            if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then offset = -1 else offset = 0 end
            table.insert(Trk[TrkID].PostFX, SpcIDinPost + offset + 1, FxID)
            -- InsertToPost_Src = FX_Idx + offset+2
            for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '', true)
            end
        elseif SpaceIsBeforeRackMixer == 'SpcInBS' then
            DropFXintoBS(FxID, FxGUID_Container, FX[FxGUID_Container].Sel_Band, FX_Idx, Dest + 1)
        end



        FX_Idx_OpenedPopup = nil
    end
end

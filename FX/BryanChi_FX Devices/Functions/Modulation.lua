-- @noindex
MacroNums = { 1, 2, 3, 4, 5, 6, 7, 8, }



function Link_Param_to_CC(TrackNumToBeMod, FX_Slt_Indx_ToBeMod, PARAM_Num, parmlink, MIDIPLINK, Category, CC_or_Note_Num,
                          Baseline_V, Scale)
    --NOTE : ALL Numbers here are NOT zero-based, things start from 1 , hence the +1 in function
    --('TrackNumToBeMod'..TrackNumToBeMod.. '\n FX_Slt_Indx_ToBeMod'..FX_Slt_Indx_ToBeMod..'\n PARAM_Num'..PARAM_Num..'\n'..'CC_or_Note_Num'..CC_or_Note_Num..'\n')
    ParmModTable                                        = ultraschall.CreateDefaultParmModTable()

    ParmModTable["PARMLINK"]                            = parmlink

    ParmModTable["MIDIPLINK"]                           = MIDIPLINK
    ParmModTable["PARAM_TYPE"]                          = ""

    ParmModTable["WINDOW_ALTERED"]                      = false
    ParmModTable["PARMLINK_LINKEDPLUGIN"]               = -100
    ParmModTable["MIDIPLINK_BUS"]                       = 16
    ParmModTable["MIDIPLINK_CHANNEL"]                   = 16
    ParmModTable["MIDIPLINK_MIDICATEGORY"]              = Category      -- 176 is CC
    ParmModTable["MIDIPLINK_MIDINOTE"]                  = CC_or_Note_Num
    ParmModTable["PARAM_NR"]                            = PARAM_Num + 1 --Param Number to be modulated
    ParmModTable["PARAMOD_ENABLE_PARAMETER_MODULATION"] = true
    if Baseline_V then ParmModTable["PARAMOD_BASELINE"] = Baseline_V end
    if Scale then ParmModTable["PARMLINK_SCALE"] = Scale end


    whetherValid = ultraschall.IsValidParmModTable(ParmModTable)


    retval, TrackStateChunk = ultraschall.GetTrackStateChunk_Tracknumber(TrackNumToBeMod)
    FXStateChunk = ultraschall.GetFXStateChunk(TrackStateChunk)
    alteredFXStateChunk = ultraschall.AddParmMod_ParmModTable(FXStateChunk, FX_Slt_Indx_ToBeMod + 1, ParmModTable)
    retval, TrackStateChunk = ultraschall.SetFXStateChunk(TrackStateChunk, alteredFXStateChunk)
    retval = ultraschall.SetTrackStateChunk_Tracknumber(TrackNumToBeMod, TrackStateChunk)

    tab = ultraschall.GetParmModTable_FXStateChunk(FXStateChunk, FX_Slt_Indx_ToBeMod + 1, PARAM_Num + 1)
end

function SetPrmAlias(TrkNum, fxid, parmidx, AliasName)
    local u = ultraschall

    retval, TrackStateChunk = u.GetTrackStateChunk_Tracknumber(TrkNum)
    FXStateChunk = u.GetFXStateChunk(TrackStateChunk)
    retval, alteredFXStateChunk = ultraschall.AddParmAlias_FXStateChunk(FXStateChunk, fxid, parmidx, AliasName) --rv, alteredFXStateChunk = u.AddParmAlias_FXStateChunk( FXStateChunk, fxid, parmalias)

    _, TrackStateChunk = u.SetFXStateChunk(TrackStateChunk, alteredFXStateChunk)
    _ = u.SetTrackStateChunk_Tracknumber(TrkNum, TrackStateChunk)
end

function GetParmModTable(TrkNum, FX_Idx, P_Num, TableIndex_Str)
    local TblIDReturn
    retval, TrackStateChunk = ultraschall.GetTrackStateChunk_Tracknumber(TrkNum)
    FXStateChunk = ultraschall.GetFXStateChunk(TrackStateChunk)
    if FXStateChunk then
        tab = ultraschall.GetParmModTable_FXStateChunk(FXStateChunk, FX_Idx + 1, P_Num + 1)
    end
    if tab then TblIDReturn = tab[TableIndex_Str or 'PARAM_TYPE'] end
    return TblIDReturn, TrackStateChunk, FXStateChunk, tab
end

function Unlink_Parm(TrackNumToBeMod, FX_Slt_Indx_ToBeMod, PARAM_Num)
    --NOTE : ALL Numbers here are NOT zero-based, things start from 1 , hence the +1 in function

    --ParmModTable = ultraschall.CreateDefaultParmModTable()
    --[[ParmModTable["PARAM_NR"]                    =PARAM_Num
        ParmModTable["PARAM_TYPE"]                  = ""
        ParmModTable["WINDOW_ALTERED"]              =true

        ParmModTable["PARAMOD_ENABLE_PARAMETER_MODULATION"]  = false
        ParmModTable["MIDIPLINK"]              = false
        ParmModTable["PARMLINK"]               =false
        ParmModTable["MIDIPLINK_BUS"]          =nil
        ParmModTable["MIDIPLINK_CHANNEL"]      =nil
        ParmModTable["MIDIPLINK_MIDICATEGORY"] =nil
        ParmModTable["MIDIPLINK_MIDINOTE"]     =nil ]]
    whetherValidUnlink = ultraschall.IsValidParmModTable(ParmModTable)
    retval, TrackStateChunk = ultraschall.GetTrackStateChunk_Tracknumber(TrackNumToBeMod)
    FXStateChunk = ultraschall.GetFXStateChunk(TrackStateChunk)
    --ParmModTable["WINDOW_ALTERED"]              =true
    --alteredFXStateChunk = ultraschall.AddParmMod_ParmModTable(FXStateChunk, FX_Slt_Indx_ToBeMod+1, ParmModTable)

    alteredFXStateChunk = ultraschall.DeleteParmModFromFXStateChunk(FXStateChunk, FX_Slt_Indx_ToBeMod + 1, PARAM_Num + 1)

    retval, TrackStateChunk = ultraschall.SetFXStateChunk(TrackStateChunk, alteredFXStateChunk)
    retval = ultraschall.SetTrackStateChunk_Tracknumber(TrackNumToBeMod, TrackStateChunk)
end

function Link_Macros_to_ImGui_Sliders(trackNumber)
    ParmModTable = ultraschall.CreateDefaultParmModTable()
    retval, TrackStateChunk = ultraschall.GetTrackStateChunk_Tracknumber(TrackNumber)
    FXStateChunk = ultraschall.GetFXStateChunk(TrackStateChunk)
    alteredFXStateChunk = ultraschall.AddParmMod_ParmModTable(FXStateChunk, 1, ParmModTable) --Always Link 1st FX, which is macros
end

function PrepareFXforModulation(FX_Idx, P_Num, FxGUID)
    local ParamValue_Modding = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
    AssignMODtoFX = FX_Idx
    r.gmem_attach('ParamValues')
    if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 and r.TrackFX_AddByName(LT_Track, 'Macros', 0, 0) == -1 then
        r.gmem_write(1, PM.DIY_TrkID[TrkID]) --gives jsfx a guid when it's being created, this will not change becuase it's in the @init.
        AddMacroJSFX()
        AssignMODtoFX = AssignMODtoFX + 1
    end


    r.gmem_write(2, PM.DIY_TrkID[TrkID]) --Sends Trk GUID for jsfx to determine track
    r.gmem_write(11000 + Trk.Prm.Assign, ParamValue_Modding)
end

function MakeModulationPossible(FxGUID, Fx_P, FX_Idx, P_Num, p_value, Sldr_Width, Type)
    local FP = FX[FxGUID][Fx_P]
    local CC = FP.WhichCC

    if --[[Link CC back when mouse is up]] Tweaking == P_Num .. FxGUID and IsLBtnHeld == false then
        if FX[FxGUID][Fx_P].WhichCC then
            local CC = FX[FxGUID][Fx_P].WhichCC

            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation',
                FX[FxGUID][Fx_P].V, true)

            r.gmem_write(7, CC) --tells jsfx to retrieve P value
            PM.TimeNow = r.time_precise()
            r.gmem_write(11000 + CC, p_value)
            Link_Param_to_CC(LT_TrackNum, LT_FX_Number, P_Num, true, true, 176, CC)
        end

        Tweaking = nil
    end


    if r.ImGui_IsItemClicked(ctx, 1) and FP.ModAMT and AssigningMacro == nil and Mods == 0 then
        if #FP.ModAMT == 1 then -- if there's only one Modulation assigned to param..
            for M, v in ipairs(MacroNums) do
                if FP.ModAMT[M] then
                    Trk.Prm.Assign = FP.WhichCC
                    AssigningMacro = M

                    r.gmem_write(5, AssigningMacro) --tells jsfx which macro is user tweaking
                    r.gmem_write(6, FP.WhichCC)
                end
                PM.DragOnModdedPrm = true
            end
        end
    elseif r.ImGui_IsItemClicked(ctx, 1) and FP.ModAMT and Mods == Shift then
        for M, v in ipairs(MacroNums) do
            if FP.ModAMT[M] then
                Trk.Prm.Assign = FP.WhichCC
                BypassingMacro = M
                r.gmem_write(5, BypassingMacro) --tells jsfx which macro is user tweaking
                r.gmem_write(6, FP.WhichCC)
            end
        end
        DecideShortOrLongClick = FP
        Dur = r.ImGui_GetMouseDownDuration(ctx, 1)
    end

    if DecideShortOrLongClick == FP and Dur then
        if r.ImGui_IsMouseReleased(ctx, 1) then
            if Dur < 0.14 then                      ---- if short right click
                if FP.ModBypass then
                    r.gmem_write(5, BypassingMacro) --tells jsfx which macro is user tweaking
                    r.gmem_write(6, FP.WhichCC)
                    r.gmem_write(1000 * BypassingMacro + Trk.Prm.Assign, FP.ModAMT[BypassingMacro])
                    r.gmem_write(3, Trk[TrkID].ModPrmInst)
                    FP.ModBypass = nil
                else
                    FP.ModBypass = BypassingMacro
                    r.gmem_write(5, BypassingMacro)                         --tells jsfx which macro is user tweaking
                    r.gmem_write(6, FP.WhichCC)
                    r.gmem_write(1000 * BypassingMacro + Trk.Prm.Assign, 0) -- set mod amount to 0
                    r.gmem_write(3, Trk[TrkID].ModPrmInst)
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Mod bypass',
                        BypassingMacro, true)
                end
            else

            end


            DecideShortOrLongClick = nil
        end
        Dur = r.ImGui_GetMouseDownDuration(ctx, 1)
    end


    if --[[Assign Mod]] AssigningMacro and r.ImGui_IsItemClicked(ctx, 1) then
        local _, ValBeforeMod
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation', '',
            false)
        if not ValBeforeMod then
            r.GetSetMediaTrackInfo_String(LT_Track,
                'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Value before modulation', FX[FxGUID][Fx_P].V, true)
        end


        Trk.Prm.Assign = FP.WhichCC


        --store which param has which Macros assigned
        if FP.WhichMODs == nil then -- if This prm don't have a modulation assigned yet..
            FP.WhichMODs = tostring(AssigningMacro)

            FX[FxGUID][Fx_P].ModAMT = FX[FxGUID][Fx_P].ModAMT or {}
            Trk[TrkID].ModPrmInst = (Trk[TrkID].ModPrmInst or 0) + 1
            FX[FxGUID][Fx_P].WhichCC = Trk[TrkID].ModPrmInst
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'WhichCC' .. P_Num, FP.WhichCC, true)
            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: ModPrmInst', Trk[TrkID].ModPrmInst, true)

            Trk.Prm.Assign = Trk[TrkID].ModPrmInst
        elseif FP.WhichMODs and string.find(FP.WhichMODs, tostring(AssigningMacro)) == nil then --if there's more than 1 macro assigned, and the assigning macro is new to this param.
            FP.WhichMODs = FP.WhichMODs .. tostring(AssigningMacro)
        end
        local CC = FP.WhichCC


        if not Trk.Prm.WhichMcros[CC .. TrkID] then
            Trk.Prm.WhichMcros[CC .. TrkID] = tostring(AssigningMacro)
        elseif Trk.Prm.WhichMcros[CC .. TrkID] and not string.find(Trk.Prm.WhichMcros[CC .. TrkID], tostring(AssigningMacro)) then --if there's more than 1 macro assigned, and the assigning macro is new to this param.
            Trk.Prm.WhichMcros[CC .. TrkID] = Trk.Prm.WhichMcros[CC .. TrkID] .. tostring(AssigningMacro)
        end
        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Linked to which Mods',
            FP.WhichMODs, true)

        --r.SetProjExtState(0, 'FX Devices', 'Prm'..F_Tp..'Has Which Macro Assigned, TrkID ='..TrkID, Trk.Prm.WhichMcros[F_Tp..TrkID])
        r.gmem_write(7, CC) --tells jsfx to retrieve P value
        r.gmem_write(11000 + CC, p_value)

        r.gmem_write(6, CC)


        AssignToPrmNum = P_Num

        r.gmem_write(5, AssigningMacro) --tells jsfx which macro is user tweaking
        PrepareFXforModulation(FX_Idx, P_Num, FxGUID)
        Link_Param_to_CC(LT_TrackNum, AssignMODtoFX, AssignToPrmNum, true, true, 176, CC)
        r.gmem_write(3, Trk[TrkID].ModPrmInst)

        r.gmem_write(7, CC) --tells jsfx to rfetrieve P value
        r.gmem_write(11000 + CC, p_value)
    end




    if PM.DragOnModdedPrm == true and r.ImGui_IsMouseDown(ctx, 1) ~= true then
        AssigningMacro = nil
        PM.DragOnModdedPrm = nil
    end
    if TrkID ~= TrkID_End then
        r.gmem_write(3, Trk[TrkID].ModPrmInst or 0)
        if FP.ModAMT then
            for M = 1, 8, 1 do
                r.gmem_write(1000 * M + CC, FP.ModAMT[M] or 0)
            end
        end
    end

    local Vertical
    if Type == 'Vert' then Vertical = 'Vert' end

    -- msg(AssigningMacro or 'nil')
    if --[[Right Dragging to adjust Mod Amt]] Trk.Prm.Assign and FP.WhichCC == Trk.Prm.Assign and AssigningMacro then
        local Id = FxGUID .. Trk.Prm.Assign
        local M = AssigningMacro
        local IdM = 'Param:' .. tostring(Trk.Prm.Assign) .. 'Macro:' .. AssigningMacro


        local sizeX, sizeY = r.ImGui_GetItemRectSize(ctx)

        --[[
            PosX_End_Of_Slider= Prm.Pos_L[Id]+sizeX
            Prm.SldrGrabXPos[Id]=(PosX_End_Of_Slider-Prm.Pos_L[Id])*p_value
            SliderCurPos=Prm.Pos_L[Id]+Prm.SldrGrabXPos[Id] ]]

        local RightBtnDragX, RightBtnDragY = reaper.ImGui_GetMouseDragDelta(ctx, x, y, 1); local MouseDrag
        if Vertical == 'Vert' or Type == 'knob' then MouseDrag = -RightBtnDragY else MouseDrag = RightBtnDragX end


        FX[FxGUID][Fx_P].ModAMT[M] = ((MouseDrag / 100) or 0) + (FX[FxGUID][Fx_P].ModAMT[M] or 0)

        if FP.ModAMT[M] + p_value > 1 then FP.ModAMT[M] = 1 - p_value end
        if FP.ModAMT[M] + p_value < 0 then FP.ModAMT[M] = -p_value end

        if not IsLBtnHeld then r.gmem_write(4, 1) end --tells jsfx that user is changing Macro Mod Amount
        r.gmem_write(1000 * AssigningMacro + Trk.Prm.Assign, FP.ModAMT[M])
        r.ImGui_ResetMouseDragDelta(ctx, 1)

        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Macro' .. M .. 'Mod Amt',
            FP.ModAMT[M], true)
    end



    if Type ~= 'knob' and FP.ModAMT then
        for M, v in ipairs(MacroNums) do
            if FP.ModAMT[M] then
                --if Modulation has been assigned to params
                local sizeX, sizeY = r.ImGui_GetItemRectSize(ctx)
                local P_V_Norm = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)

                --- indicator of where the param is currently
                if not FX[FxGUID][Fx_P].V then FX[FxGUID][Fx_P].V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num) end

                DrawModLines(M, true, Trk[TrkID].Mod[M].Val, FxGUID, FP.WhichCC, ModLineDir or Sldr_Width,
                    FX[FxGUID][Fx_P].V, Vertical, FP)
                Mc.V_Out[M] = (FP.ModAMT[M] * p_value)
                ParamHasMod_Any = true
            end
        end -- of reapeat for every macro
    end

    return Tweaking
end

function RemoveModulationIfDoubleRClick(FxGUID, Fx_P, P_Num, FX_Idx)
    if r.ImGui_IsMouseDoubleClicked(ctx, 1) and r.ImGui_IsItemClicked(ctx, 1) then
        if FX[FxGUID][Fx_P].ModAMT then
            for Mc = 1, 8, 1 do
                if FX[FxGUID][Fx_P].ModAMT[Mc] then
                    Unlink_Parm(LT_TrackNum, FX_Idx, P_Num)
                    FX[FxGUID][Fx_P].ModAMT[Mc] = 0
                end
            end
        end
    end
end

-- @noindex

  function DropFXtoLayerNoMove(FXGUID_RackMixer , LayerNum, DragFX_ID)
        DragFX_ID = math.max(DragFX_ID,0)
        local function SetPinMappings(i)
            r.TrackFX_SetPinMappings(LT_Track, i, 0, 0, 2^(LayerNum*2-2), 0) --sets input channel 
            r.TrackFX_SetPinMappings(LT_Track, i, 0, 1, 2^(LayerNum*2-1), 0)
            --sets Output 
            r.TrackFX_SetPinMappings(LT_Track, i, 1, 0, 2^(LayerNum*2-2), 0)
            r.TrackFX_SetPinMappings(LT_Track, i, 1, 1, 2^(LayerNum*2-1), 0)
        end
        if Lyr.FX_Ins[FXGUID_RackMixer]== nil then Lyr.FX_Ins[FXGUID_RackMixer]=0 end
        local guid = reaper.TrackFX_GetFXGUID(LT_Track, DragFX_ID)

        if FX.InLyr[guid] ~= FXGUID_RackMixer then 
            Lyr.FX_Ins[FXGUID_RackMixer] = Lyr.FX_Ins[FXGUID_RackMixer]+1
        elseif FX.InLyr[guid] == FXGUID_RackMixer then 
        end

        FX.InLyr[guid] = FXGUID_RackMixer
        r.SetProjExtState(0, 'FX Devices', 'FXLayer - '.. 'is FX' ..guid..'in layer',  FXGUID_RackMixer )
        FX.LyrNum[guid] = LayerNum
        r.SetProjExtState(0, 'FX Devices', 'FXLayer ' ..guid..'LayerNum',  LayerNum )

        FX[guid]= FX[guid]  or {}
        FX[guid].inWhichLyr = FX[FXGUID_RackMixer].LyrID[LayerNum]
        r.SetProjExtState(0, 'FX Devices', 'FXLayer - ' ..guid..'is in Layer ID',  FX[FXGUID_RackMixer].LyrID[LayerNum] )

        
      
        --@todo if this is the 2nd + FX in Layer, receive from layer channels (layer 2 = 3-4, layer 3 = 5-6 etc)


        r.SetProjExtState(0, 'FX Devices', 'FX Inst in Layer'.. FXGUID_RackMixer, Lyr.FX_Ins[FXGUID_RackMixer])
        for i=1,  RepeatTimeForWindows,1 do
            local FXGUID = reaper.TrackFX_GetFXGUID( LT_Track, i )
            if FX.LyrNum[FXGUID] == LayerNum and FX.InLyr[FXGUID] == FXGUID_RackMixer then 

                _, FXName  = reaper.TrackFX_GetFXName( LT_Track, i )
                SetPinMappings(i)

                local rv,  inputPins,  outputPins = reaper.TrackFX_GetIOSize(LT_Track, i)
                if outputPins > 2 then 
                    for P=2, outputPins, 1 do 
                        r.TrackFX_SetPinMappings(LT_Track, i ,1--[[IsOutput]] , P, 0,0)
                    end 
                end
                if inputPins > 2 then 
                    for P=2, inputPins, 1 do 
                        r.TrackFX_SetPinMappings(LT_Track, i ,0--[[IsOutput]] , P, 0,0)
                    end 
                end
            end
        end

        
    end

    function DropFXtoLayer(FX_Idx , LayerNum, AltDragSrc) --fxIdx == the position in chain it's dropped to 
        DragFX_ID = DragFX_ID or  AltDragSrc  or FX_Idx
        local function SetPinMappings(i)
            r.TrackFX_SetPinMappings(LT_Track, i, 0, 0, 2^(LayerNum*2-2), 0) --sets input channel 
            r.TrackFX_SetPinMappings(LT_Track, i, 0, 1, 2^(LayerNum*2-1), 0)
            --sets Output 
            r.TrackFX_SetPinMappings(LT_Track, i, 1, 0, 2^(LayerNum*2-2), 0)
            r.TrackFX_SetPinMappings(LT_Track, i, 1, 1, 2^(LayerNum*2-1), 0)
        end

        if Lyr.FX_Ins[FXGUID_RackMixer]== nil then Lyr.FX_Ins[FXGUID_RackMixer]=0 end
        local guid 
        if Payload_Type == 'AddFX_Sexan' then  
            guid = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
            FX[guid] = FX[guid] or {}
        else 
            guid = r.TrackFX_GetFXGUID(LT_Track, DragFX_ID)
        end 

        if FX[FXGUID[DragFX_ID]].InWhichBand then 
            MoveFX_Out_Of_BS ()
        end


        if FX.InLyr[guid] ~= FXGUID_RackMixer then 
            Lyr.FX_Ins[FXGUID_RackMixer] = Lyr.FX_Ins[FXGUID_RackMixer]+1
        elseif FX.InLyr[guid] == FXGUID_RackMixer then 
        end

        FX.InLyr[guid] = FXGUID_RackMixer
        r.SetProjExtState(0, 'FX Devices', 'FXLayer - '.. 'is FX' ..guid..'in layer',  FXGUID_RackMixer )
        FX.LyrNum[guid] = LayerNum
        r.SetProjExtState(0, 'FX Devices', 'FXLayer ' ..guid..'LayerNum',  LayerNum )


        FX[guid].inWhichLyr = FX[FXGUID_RackMixer].LyrID[LayerNum]
        r.SetProjExtState(0, 'FX Devices', 'FXLayer - ' ..guid..'is in Layer ID',  FX[FXGUID_RackMixer].LyrID[LayerNum] )

        
      
        --@todo if this is the 2nd + FX in Layer, receive from layer channels (layer 2 = 3-4, layer 3 = 5-6 etc)


        r.SetProjExtState(0, 'FX Devices', 'FX Inst in Layer'.. FXGUID_RackMixer, Lyr.FX_Ins[FXGUID_RackMixer])
        

        MoveFX(DragFX_ID,FX_Idx,true)

          


        --[[ for i=1,  RepeatTimeForWindows,1 do
            local FXGUID = reaper.TrackFX_GetFXGUID( LT_Track, i )
            ]]
            if FX.LyrNum[guid] == LayerNum and FX.InLyr[guid] == FXGUID_RackMixer then 
                local FX_Idx 
                --_, FXName  = r.TrackFX_GetFXName( LT_Track, i )
                for i=1,  RepeatTimeForWindows,1 do
                    local FXGUID = reaper.TrackFX_GetFXGUID( LT_Track, i )
                    if FXGUID ==guid then FX_Idx = i end 
                end

                SetPinMappings(DragFX_ID)

                local rv,  inputPins,  outputPins = reaper.TrackFX_GetIOSize(LT_Track, DragFX_ID)
                if outputPins > 2 then 
                    for P=2, outputPins, 1 do 
                        r.TrackFX_SetPinMappings(LT_Track, DragFX_ID ,1--[[IsOutput]] , P, 0,0)
                    end 
                end
                if inputPins > 2 then 
                    for P=2, inputPins, 1 do 
                        r.TrackFX_SetPinMappings(LT_Track, DragFX_ID ,0--[[IsOutput]] , P, 0,0)
                    end 
                end
            end
        --[[ end ]]
    end



            function RepositionFXsInContainer(FX_Idx)
                r.Undo_BeginBlock()
                local FX_Idx = FX_Idx
                local FX_Count = r.TrackFX_GetCount(LT_Track)
                if AddLastSpace == 'LastSpc' and Trk[TrkID].PostFX[1] then 
                    FX_Idx = FX_Idx-#Trk[TrkID].PostFX
                end


                -- Move the Head of Container
                if  FX_Idx > Payload  or (FX_Idx == RepeatTimeForWindows and AddLastSpace == 'LastSpc' ) then
                    --table.insert(MovFX.FromPos,DragFX_ID) table.insert(MovFX.ToPos, FX_Idx-1)
                    reaper.TrackFX_CopyToTrack( LT_Track, Payload, LT_Track, FX_Idx-1, true )

                elseif Payload > FX_Idx and FX_Idx ~= RepeatTimeForWindows then

                    reaper.TrackFX_CopyToTrack( LT_Track, Payload, LT_Track, FX_Idx, true )
                    --table.insert(MovFX.FromPos,DragFX_ID) table.insert(MovFX.ToPos, FX_Idx)
                end 



                -- Move all FXs inside
                if Payload_Type == 'FX Layer Repositioning' then 
                    local DropDest=nil
                    for i=0 , FX_Count, 1 do 

                        if DragFX_ID < FX_Idx then 
                            if  DropDest == nil  then  DropDest = 0 end
                            local ID = reaper.TrackFX_GetFXGUID(LT_Track, DropDest)

                            if FX.InLyr[ID] == FXGUID_RackMixer  or tablefind(FX[FXGUID[Payload]].FXsInBS, ID) then 

                                if  FX_Idx > DropDest and FX_Idx ~= RepeatTimeForWindows or (FX_Idx == RepeatTimeForWindows and AddLastSpace == 'LastSpc' ) then
                                    reaper.TrackFX_CopyToTrack( LT_Track, DropDest, LT_Track, FX_Idx-2, true )
                                    --table.insert(MovFX.FromPos,DropDest) table.insert(MovFX.ToPos, FX_Idx-2)



                                elseif DropDest > FX_Idx and FX_Idx ~= RepeatTimeForWindows then
                                    reaper.TrackFX_CopyToTrack( LT_Track, DropDest, LT_Track, FX_Idx, true )
                                    --table.insert(MovFX.FromPos,DropDest) table.insert(MovFX.ToPos, FX_Idx)
                                end
                            else 
                                DropDest = DropDest+1
                            end

                        elseif DragFX_ID > FX_Idx then 
                            if  DropDest == nil  then  DropDest = 1 end
                            local ID = reaper.TrackFX_GetFXGUID(LT_Track, DropDest)
                            if FX.InLyr[ID] == FXGUID_RackMixer or tablefind(FX[FXGUID[Payload]].FXsInBS, ID) then
                                reaper.TrackFX_CopyToTrack( LT_Track, DropDest, LT_Track, FX_Idx, true )
                                --table.insert(MovFX.FromPos,DropDest) table.insert(MovFX.ToPos, FX_Idx)

                                DropDest = DropDest+1
                            else 
                                DropDest = DropDest+1
                            end
                        end
                    end
                elseif Payload_Type == 'BS_Drag' then
                    
                    for i, v in ipairs(FX[FXGUID[Payload]].FXsInBS) do 
                        if  FX_Idx > Payload  or (FX_Idx == RepeatTimeForWindows and AddLastSpace == 'LastSpc' ) then
                            reaper.TrackFX_CopyToTrack( LT_Track, Payload, LT_Track, FX_Idx-1, true )
                        elseif Payload > FX_Idx and FX_Idx ~= RepeatTimeForWindows then
                            reaper.TrackFX_CopyToTrack( LT_Track, Payload+i, LT_Track, FX_Idx+i, true )
                        end
                    end

                    --Move Joiner
                    if  FX_Idx > Payload  or (FX_Idx == RepeatTimeForWindows and AddLastSpace == 'LastSpc' ) then
                        reaper.TrackFX_CopyToTrack( LT_Track, Payload, LT_Track, FX_Idx-1, true )
                    elseif Payload > FX_Idx and FX_Idx ~= RepeatTimeForWindows then 
                        reaper.TrackFX_CopyToTrack( LT_Track, Payload + #FX[FXGUID[Payload]].FXsInBS+1, LT_Track, FX_Idx + #FX[FXGUID[Payload]].FXsInBS+1, true )
                    end
                    
                end 
                if Payload_Type == 'FX Layer Repositioning' then 
                    for i=0 , FX_Count, 1 do  -- Move Splitter
                        local FXGUID = reaper.TrackFX_GetFXGUID(LT_Track, i)
                        
                        if  Lyr.SplitrAttachTo[FXGUID] == FXGUID_RackMixer then 
                            SplitrGUID = FXGUID
                            if FX_Idx ==0 then 
                                r.TrackFX_CopyToTrack( LT_Track, i , LT_Track, 0 , true )
                            elseif i > FX_Idx then -- FX_Idx = drop to fx position
                                if Lyr.FrstFXPos[FXGUID_RackMixer]~= nil then 
                                    r.TrackFX_CopyToTrack( LT_Track, i , LT_Track, FX_Idx , true )
                                    -- table.insert(MovFX.FromPos,i) table.insert(MovFX.ToPos, FX_Idx)

                                end
                            elseif i < FX_Idx then 
                                --table.insert(MovFX.FromPos,i) table.insert(MovFX.ToPos, FX_Idx)

                                r.TrackFX_CopyToTrack( LT_Track, i, LT_Track, DropDest or FX_Idx, true )
                            end
                        end
                    end

                end

                local UndoName
                if Payload_Type == 'BS_Drag' then UndoName = 'Move Band Split and all contained FXs' 
                elseif Payload_Type == 'FX Layer Repositioning' then  UndoName =  'Move FX Layer and all contained FXs'
                end 

                r.Undo_EndBlock(UndoName or 'Undo',0)


            end

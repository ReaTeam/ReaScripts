--[[
 * ReaScript Name: TrackFXs Routing Matrix (Kawa mod)
 * Screenshot: https://stash.reaper.fm/30683/TrackFxRouting_Mod_1.gif
 * Links:
 *    Forum https://forum.cockos.com/showthread.php?t=173867
 *    Doc https://stash.reaper.fm/v/28892/TrackFXs_Routing_Matrix_DS_KW.lua
 * Author: Eugen2777, DarkStar, Kawa
 * Author URI: http://kawa.works
 * Repository: ReaTeam ReaScripts
 * Licence: GPL v3
 * Version: 1.0
--]]

--[[
 * Changelog:
 * v1.0 (2018-09-07)
	# Reapack Release by X-Raym from version c01
--]]

--====================================================================
--[[--
    eugen2777: http://forum.cockos.com/showthread.php?t=173867
    DarkStar:  mods, for connector pin colours, 
               pin numbers (Alt_click) and wire (Alt_right_click)
--]]--
--====================================================================

-- OPTIONS 
--====================================================================
local FONTNAME                   = "Calibri" 
-- local FONTNAME                = "Courie New"
-- local FONTNAME                = "Arial"
local IS_DOCKSTART               = true   -- or false
local IS_DRAWBORDER_TOP          = false  -- or false
local IS_DRAWBORDER_BOTTOM       = false  -- or false
local BORDER_HEIGHT              = 2
local IS_ENABLE_COLOR_MODULATION = true   -- on selected chenge
--====================================================================
local START_ZOOM_LEVEL_OFFSET    =  0     -- -10 ~ 10 ( default 0)
-- local START_ZOOMLEVEL_OFFSET  = -4     -- example -4 zoom out
-- local START_ZOOMLEVEL_OFFSET  =  2     -- example +2 zoom in
--====================================================================

-- ** added option 17/03/21 **
--====================================================================
local IS_CH_NUMBER_MODE          = true;  -- true or false ( replace verticle line and arrow with ch number)
local ARROW_LINE_WIDTH           = 1;     -- pixel ( 0 ~ 4 ?)
local ARROW_SIZE                 = 3.5;   -- 1 ~ 10
--====================================================================

-- ** added option 17/10/29 **
--====================================================================
local IS_USE_AUTOFIT             = true   -- true or false 
                                          -- if this option is false , you can adjust size by "START_ZOOM_LEVEL_OFFSET" option
--====================================================================

--====================================================================
function HSBtoRGB (hue_, saturation_ , value) --hue_: 0~360 ,saturation_:0.0~1.0 value: 0.0~1.0 brightness ,return 255/..
    --================================================================
    local r,g,b,h,f,v,p,q,t
    local hue = hue_
    local saturation =saturation_
    --================================================================
    if    (hue > 360)  then hue = hue - 360;
    elseif(hue < 0)    then hue = hue + 360;  end
    --================================================================
    if     (saturation > 1)  then saturation = 1.0;
    elseif ( saturation < 0) then saturation = 0.0; end
    --================================================================
    v = math.floor( 255 * value)
    --================================================================
    if    (v > 255)then v = 255;
    elseif(v < 0)  then v = 0  ; end
    --================================================================
    if(saturation == 0)
    then
        r = v ; g = v; b = v;
    else
        --============================================================
        h = math.floor( hue / 60)
        f = hue / 60-h
        p = math.floor( v * (1-saturation))
        --============================================================
        if    ( p < 0)  then p = 0;
        elseif( p > 255)then p = 255; end
        --============================================================
        q = math.floor( v * (1-f * saturation))
        --============================================================
        if    ( q < 0 )  then  q = 0;
        elseif( q > 255 )then  q = 255;  end
        --============================================================
        t=math.floor( v * (1-(1-f) * saturation))
        --============================================================
        if    ( t < 0 )  then t = 0;
        elseif( t > 255 )then t = 255; end
        --============================================================
        if     (h==0)then r=v;g=t;b=p;
        elseif (h==1)then r=q;g=v;b=p;
        elseif (h==2)then r=p;g=v;b=t;
        elseif (h==3)then r=p;g=q;b=v;
        elseif (h==4)then r=t;g=p;b=v;
        elseif (h==5)then r=v;g=p;b=q;
        else              r=v;g=t;b=p; 
        end
        --============================================================
    end
    --================================================================
    return r,g,b
end
--====================================================================
function checkScriptColor(modeName) -- if need 
    --================================================================
    if ( modeName =="track")
    then
        gfx.clear = 3355443;
        --============================================================
        COLORS.EvenBox                 = {0.90, 0.50, 0.00};
        COLORS.oddBox                  = {0.00, 1.00, 0.90};
        COLORS.TextPinNumberColor      = {0.00, 0.00, 0.00};
        COLORS.TextLabelColor          = {0.90, 0.80, 0.00};
        COLORS.TextTrackOrTakeName     = {0.90, 0.80, 0.00,1};
        COLORS.AddFxButtonOffMouse     = {0.90, 0.80, 0.00,1};
        COLORS.AddFxButtonOnMouse      = {0.40, 0.40, 0.90,1};
        COLORS.FxEngaleButtonOn        = {0.90, 0.20, 0.20,1};
        COLORS.FxEngaleButtonOff       = {0.90, 0.80, 0.00,1};
        COLORS.FxEngaleButtonOnMouse   = {0.20, 0.90, 0.90,1};
        COLORS.TextInOutName           = {0.90, 0.80, 0.00,1};
        COLORS.TextInOutNameOnMouse    = {0.90, 0.80, 0.60,1};
        COLORS.TrackOnlyButtonOn       = {0.90, 0.20, 0.20,1};
        COLORS.TrackOnlyButtonOff      = {0.90, 0.80, 0.00,1};
        COLORS.TrackOnlyButtonOnMouse  = {0.40, 0.40, 0.90,1};
        COLORS.btAddSubChan            = {0.90, 0.80, 0.50};
        COLORS.InOutEvenBox            = {0.60, 0.60, 0.60,1};
        COLORS.InOutOddBox             = {0.40, 0.40, 0.40,1};
        COLORS.black                   = {0.00, 0.00, 0.00,1};
        --============================================================
        COLORS.TopBarColorHue = 360*math.random();
        COLORS.TopBarColorHueWidth = 160;
        COLORS.TopBarColorSat = 1;
        COLORS.TopBarColorVal = 1;
        --============================================================
    elseif ( modeName =="take")
    then
        -- gfx.clear = reaper.ColorToNative(30,120,30);
        gfx.clear = 3355443;
        --============================================================
        COLORS.EvenBox                 = {0.90, 0.50, 0.00};
        COLORS.oddBox                  = {0.00, 1.00, 0.90};
        COLORS.TextPinNumberColor      = {0.00, 0.00, 0.00};
        COLORS.TextLabelColor          = {0.90, 0.80, 0.00};
        COLORS.TextTrackOrTakeName     = {0.90, 0.80, 0.00,1};
        COLORS.AddFxButtonOffMouse     = {0.90, 0.80, 0.20,1};
        COLORS.AddFxButtonOnMouse      = {0.40, 0.40, 0.90,1};
        COLORS.FxEngaleButtonOn        = {0.90, 0.20, 0.20,1};
        COLORS.FxEngaleButtonOff       = {0.90, 0.80, 0.00,1};
        COLORS.FxEngaleButtonOnMouse   = {0.20, 0.90, 0.20,1};
        COLORS.TrackOnlyButtonOn       = {0.90, 0.20, 0.20,1};
        COLORS.TrackOnlyButtonOff      = {0.90, 0.80, 0.00,1};
        COLORS.TrackOnlyButtonOnMouse  = {0.40, 0.40, 0.90,1};
        COLORS.TextInOutName           = {0.90, 0.80, 0.00,1};
        COLORS.TextInOutNameOnMouse    = {0.90, 0.80, 0.60,1};
        COLORS.btAddSubChan            = {0.90, 0.80, 0.50};
        COLORS.InOutEvenBox            = {0.60, 0.60, 0.60,1};
        COLORS.InOutOddBox             = {0.40, 0.40, 0.40,1};
        COLORS.black                   = {0.00, 0.00, 0.00,1};
        --============================================================
        COLORS.TopBarColorHue = 360*math.random();
        COLORS.TopBarColorHueWidth = 160;
        COLORS.TopBarColorSat = 1;
        COLORS.TopBarColorVal = 1;
    else
        gfx.clear = 3355443;
        --============================================================
        COLORS.EvenBox                 = {0.90, 0.50, 0.00};
        COLORS.oddBox                  = {0.00, 1.00, 0.90};
        COLORS.TextPinNumberColor      = {0.00, 0.00, 0.00};
        COLORS.TextLabelColor          = {0.90, 0.80, 0.00};
        COLORS.TextTrackOrTakeName     = {0.90, 0.80, 0.00,1};
        COLORS.AddFxButtonOffMouse     = {0.90, 0.20, 0.20,1};
        COLORS.AddFxButtonOnMouse      = {0.40, 0.40, 0.90,1};
        COLORS.FxEngaleButtonOn        = {0.90, 0.20, 0.20,1};
        COLORS.FxEngaleButtonOff       = {0.90, 0.80, 0.00,1};
        COLORS.FxEngaleButtonOnMouse   = {0.20, 0.90, 0.20,1};
        COLORS.TextInOutName           = {0.90, 0.80, 0.00,1};
        COLORS.TextInOutNameOnMouse    = {0.90, 0.80, 0.60,1};
        COLORS.TrackOnlyButtonOn       = {0.90, 0.20, 0.20,1};
        COLORS.TrackOnlyButtonOff      = {0.90, 0.80, 0.00,1};
        COLORS.TrackOnlyButtonOnMouse  = {0.40, 0.40, 0.90,1};
        COLORS.btAddSubChan            = {0.90, 0.80, 0.50};
        COLORS.InOutEvenBox            = {0.60, 0.60, 0.60,1};
        COLORS.InOutOddBox             = {0.40, 0.40, 0.40,1};
        COLORS.black                   = {0.00, 0.00, 0.00,1};
        --============================================================
        COLORS.TopBarColorHue = 360*math.random();
        COLORS.TopBarColorHueWidth = 160;
        COLORS.TopBarColorSat = 1;
        COLORS.TopBarColorVal = 1;
    end
    --================================================================
end
--====================================================================
function setUp_ChansOutputProperty()
    --================================================================
    -- setUp Chans_outPropety
    --================================================================
    for i=1,32
    do
        local temp = {};
        temp.chan= i;
        temp.isOutRouting = true;
        --============================================================
        table.insert (Chans_outPropety,temp );
    end
    --================================================================
end
--====================================================================
function string:split(sep_)
    local sep,fields = sep_ or ":",{}
    local pattern = string.format("([^%s]+)",sep)
    self:gsub(pattern,function(c) fields[#fields+1]=c end )
    return fields
end
--====================================================================

--====================================================================
function pointIN(x,y,w,h)
  return mouse_ox >= x and mouse_ox <= x + w and mouse_oy >= y and mouse_oy <= y + h and
         gfx.mouse_x >= x and gfx.mouse_x <= x + w and gfx.mouse_y  >= y and gfx.mouse_y <= y + h
end
--====================================================================
function mouseClick()
    return gfx.mouse_cap&1==0 and last_mouse_cap&1==1
end
--====================================================================
function mouseRightClick()
    return gfx.mouse_cap&2==0 and last_mouse_cap&2==2
end
--====================================================================

--====================================================================
function draw_pin_number(x,y,w,h,i)
    --================================================================
    local stringWidth = gfx.measurestr( tostring(i));
    --================================================================
    local centerW = x+w/2;
    local centerH= y+h/2;
    --================================================================
    gfx.x = centerW - stringWidth/2;
    gfx.y = centerH -gfx.texth/2-1;
    
    --================================================================
    gfx.set(table.unpack(COLORS.TextPinNumberColor))--set id color
    gfx.printf("%d",i)
    --================================================================
end
--====================================================================
function set_colour(i)
    --================================================================
    -- red / cyan
    if i %2 == 0 then gfx.set(table.unpack(COLORS.EvenBox))
                 else gfx.set(table.unpack(COLORS.oddBox))
    end
    --================================================================
end
--====================================================================
function set_greys(i)
    --================================================================
    if i%2==0 then gfx.set(table.unpack(COLORS.InOutEvenBox)) 
              else gfx.set(table.unpack(COLORS.InOutOddBox))
    end
    --================================================================
end
--====================================================================

--====================================================================
function draw_pin(target,fx,isOut,pin,chans, x,y,w,h,modeName)
    --================================================================
    local FX_GetPinMappings = nil;
    local FX_SetPinMappings = nil;
    local FX_GetEnabled     = nil;
    --================================================================
    if ( modeName =="track")
    then
        FX_GetPinMappings = reaper.TrackFX_GetPinMappings;
        FX_SetPinMappings = reaper.TrackFX_SetPinMappings;
        FX_GetEnabled     = reaper.TrackFX_GetEnabled;
        --============================================================
    elseif ( modeName =="take")
    then
        FX_GetPinMappings = reaper.TakeFX_GetPinMappings;
        FX_SetPinMappings = reaper.TakeFX_SetPinMappings;
        FX_GetEnabled     = reaper.TakeFX_GetEnabled;
        --============================================================
    end
    --================================================================
    local Low32,Hi32 = FX_GetPinMappings(target, fx, isOut, pin)--Get current pin
    local bit,val,y0
    local Click = mouseClick()
    --================================================================
    set_colour(pin+1);
    y0 =y-w*2;
    --================================================================
    
    -- draw(and change val if Clicked)
    for i = 1, chans 
    do
        --============================================================
        bit = 2^(i-1)       --cuurent bit
        val = (Low32&bit)>0 --current bit(aka channel value as booleen)
        --============================================================
        
        --============================================================
        if (     Click 
             and pointIN(x,y,w,h-1) 
            )
        then
            --========================================================
            if  ( val )
            then 
                Low32 = Low32 - bit;
            else 
                Low32 = Low32 + bit;
            end
            --========================================================
            FX_SetPinMappings(target, fx, isOut , pin, Low32, Hi32)--Set pin 
            --========================================================
        end
        --============================================================
        if  (     val 
              and FX_GetEnabled(target,fx) 
            )
        then 
            gfx.a = 1;   -- set gfx.a
        else 
            gfx.a = 0.3; -- set gfx.a
        end 
        --============================================================
        gfx.rect(x,y,w-2,h-2, val) --bool = val      
        --============================================================
       
        --============================================================
        -- DarkStar (pin numbers and wires)
        --============================================================
        if (     val 
             and FX_GetEnabled(target,fx) 
            )
        then
            --========================================================
            if ( show_pins > 0 )
            then 
                draw_pin_number(x,y,w-2,h-2,pin+1) 
            end
            --========================================================
            set_colour(i);
            --========================================================
            if ( show_wires > 0 )
            then
                if ( grey_wires > 0 )
                then 
                    set_greys(i) 
                end
                --====================================================
                local allowWidth  = w/(ARROW_SIZE*2)
                local allowLength = w/(ARROW_SIZE)
                --====================================================
                if ( isOut == 0 )
                then 
                    --================================================
                    -- draw horizontal Arrow
                    --================================================
                    local rectThickness = ARROW_LINE_WIDTH;
                    local _w =  ( x-1 ) - (last_in[i-1]+w-2)
                    local _h = rectThickness;
                    gfx.rect( last_in[i-1]+w-2 , y+h/2 -_h/2
                            , _w-allowLength/2 , _h    );
                    --================================================
                    if ( show_allow >0)
                    then 
                        gfx.triangle ( x             , y+h/2 -_h/2
                                      ,x -allowLength, y+h/2-allowWidth -_h/6
                                      ,x -allowLength, y+h/2+allowWidth -_h/6
                                      );
                    end
                    --================================================
                    
                    --================================================
                    local function drawVertcleArrow()
                        --============================================
                        local rectThickness = ARROW_LINE_WIDTH;
                        local _w = rectThickness 
                        local _h = (y-1)-y0;
                        --============================================
                        gfx.rect( x+w/2 - _w/2 , y0+rectThickness
                                , _w           , _h ) ;
                        --============================================
                        if ( show_allow >0)
                        then 
                             gfx.triangle ( x+w/2 -_w/2              , y0
                                          , x+w/2-allowWidth -1 -_w/8 , y0 +allowLength+1
                                          , x+w/2+allowWidth +1 -_w/8 , y0 +allowLength+1
                                    );
                        end
                        --============================================
                    end
                    --================================================
                    
                    --================================================
                    if ( IS_CH_NUMBER_MODE ==false)
                    then 
                        drawVertcleArrow();
                    end
                    --================================================  
                else
                    --================================================
                    if ( IS_CH_NUMBER_MODE ==false)
                    then 
                        --============================================
                        local rectThickness = ARROW_LINE_WIDTH;
                        local _w = rectThickness 
                        local _h = (y-1)-y0;
                        --============================================
                        gfx.rect( x+w/2 - _w/2 , y0
                                , _w           , _h ) ;
                        --============================================
                        if ( show_allow >0)
                        then 
                            gfx.triangle ( x+w/2 -_w/2              , y-1
                                          ,x+w/2-allowWidth-1 -_w/8 , y -allowLength-1
                                          ,x+w/2+allowWidth-1 -_w/8 , y -allowLength-1
                                        );
                            --========================================
                        end
                    end
                    --================================================
                end
                --====================================================
            end
            --========================================================
            last_in[i-1] = x
        end
        --============================================================
        y = y + h;--next y
    end 
    --================================================================
    return y;
end
--====================================================================
function draw_FX_head(target,fx,in_Pins,out_Pins, x,y,w,h,modeName)
    --================================================================
    local FX_GetPreset_func  =  nil;
    local FX_GetFXName_func  =  nil;
    local FX_GetEnabled_func =  nil;
    local FX_SetOpen_func    =  nil;
    local FX_GetOpen_func    =  nil;
    --================================================================
    if ( modeName =="track")
    then
        FX_GetPreset_func  =  reaper.TrackFX_GetPreset;
        FX_GetFXName_func  =  reaper.TrackFX_GetFXName;
        FX_GetEnabled_func =  reaper.TrackFX_GetEnabled;
        FX_SetOpen_func    =  reaper.TrackFX_SetOpen;
        FX_GetOpen_func    =  reaper.TrackFX_GetOpen;
        --============================================================
    elseif ( modeName =="take")
    then
        FX_GetPreset_func  =  reaper.TakeFX_GetPreset;
        FX_GetFXName_func  =  reaper.TakeFX_GetFXName;
        FX_GetEnabled_func =  reaper.TakeFX_GetEnabled;
        FX_SetOpen_func    =  reaper.TakeFX_SetOpen;
        FX_GetOpen_func    =  reaper.TakeFX_GetOpen;
        --============================================================
    end
    --================================================================
    
    --================================================================
    local _, ps_name = FX_GetPreset_func(target, fx, "")
    local _, fx_name = FX_GetFXName_func(target, fx, ""); 
    
    -- fx_name = fx_name:match(" %P+")
    if (fx_name:find(":") ~= nil) -- check case of not containe ":" (when plugin name has been renamed)
    then 
        fx_name = fx_name:match(".-:(.*)")  or fx_name; -- safty
        fx_name = fx_name:gsub("%[.-%]","") or fx_name;
    end
    --================================================================
   
    
    --draw head and name----------
    --================================================================
    y,w,h = y-w ,w*(in_Pins+out_Pins+1.2)-2,h-1 --correct values for head position
    gfx.set(table.unpack(COLORS.TextLabelColor))--set head color
    --================================================================
    
    if ( in_Pins+out_Pins == 0)
    then 
        w = w*2
    end
    --================================================================
    local tempName = fx_name
    local count = 0
    --================================================================
    gfx.setfont(1,FONTNAME,Z*0.8);
    --================================================================
    while (  gfx.measurestr(fx_name) >= w -1 )
    do
        --============================================================
        fx_name = string.sub(fx_name,1,#fx_name-1);
    end
    --================================================================
    
    --if FX enabled/disabled
    --================================================================
    if  ( FX_GetEnabled_func(target,fx) )
    then 
        gfx.a = 1 
    else 
        gfx.a = 0.3 
    end 
    --================================================================
    
    gfx.x, gfx.y = x, y+(h-gfx.texth)/2
    --================================================================
    gfx.rect(x,y,w,h,false) 
    gfx.printf("%s",fx_name) -- was %.12s
    --================================================================
    
    gfx.setfont(1,FONTNAME,Z*0.6);
    gfx.x = x
    gfx.y = y -gfx.texth
    gfx.a = 1 
    gfx.drawstr("# ".. tostring(fx+1))
    --================================================================
    gfx.setfont(1,FONTNAME,Z);
    --Open-Close FX on click-- 
    --================================================================
    if  (     mouseClick() 
          and pointIN(x,y,w,h)
        )
    then
        FX_SetOpen_func(target, fx, not FX_GetOpen_func(target, fx) )--not bool for change state
    end
    --================================================================
end
--====================================================================
function draw_FX_ID_addSub(target,fxid, x,y, w, h,modeName,isRight)
    --================================================================
    local text = "←";
    --================================================================
    if ( isRight ==true)
    then
        text = "→";
    end
    --================================================================
    local s_w, s_h = gfx.measurestr(text)
    x = x
    y = y+2
    gfx.x = x-2
    gfx.y = y-2
    --================================================================
    -- gfx.y = y-2*w
    if ( pointIN(x,y,s_w,s_h) )
    then 
        gfx.set(table.unpack(COLORS.AddFxButtonOnMouse))
    else
        gfx.set(table.unpack(COLORS.AddFxButtonOffMouse))
    end
    --================================================================
    gfx.rect(x,y,w,h-2, 1);
    gfx.set(table.unpack(COLORS.black))
    gfx.x = x+2
    gfx.y = gfx.y-2
    gfx.printf(text)
    --================================================================
    if (     mouseClick() 
         and pointIN(x,y,s_w,s_h)
        )
    then
        --============================================================
        if ( modeName == "track" )
        then
            --========================================================
            local _, chunk = reaper.GetTrackStateChunk(target, "",false);
            local fxChunkTable = {};
            local fxCount = 1;
            --========================================================
            local i=1;
            local fxChainState = ""
            --========================================================
            for title,word,d in string.gmatch(chunk, "(<FXCHAIN\n)(.-)(WAK %d+\n>\n)") 
            do 
                fxChainState = title..word..d;
            end
            --========================================================
            for title,word,d in string.gmatch(fxChainState, "(BYPASS)(.-)(WAK %d+\n)") 
            do 
                local fxStateChunk ={};
                fxStateChunk.index = fxCount;
                fxStateChunk.text  = title..word..d;
                table.insert ( fxChunkTable,fxStateChunk);
                fxCount = fxCount+1;
            end
            --========================================================
            
            --========================================================
            local targetFxid = fxid+1;
            --========================================================
            if ( isRight ==true)
            then
                if ( targetFxid < #fxChunkTable  and #fxChunkTable >=2)
                then
                    fxChunkTable[targetFxid].index   = fxChunkTable[targetFxid].index+1;
                    fxChunkTable[targetFxid+1].index = fxChunkTable[targetFxid+1].index-1;
                end
                --====================================================
            else
                --====================================================
                if ( targetFxid > 1 and #fxChunkTable >=2)
                then
                    fxChunkTable[targetFxid].index = fxChunkTable[targetFxid].index-1;
                    fxChunkTable[targetFxid-1].index = fxChunkTable[targetFxid-1].index+1;
                end
                --====================================================
            end
            --========================================================
            table.sort (fxChunkTable,function (a,b) return ( a.index < b.index); end );
            --========================================================
            
            local newFXStateChunk = "";
            newFXStateChunk = string.match( fxChainState ,"<FXCHAIN.*DOCKED %d\n");
            --========================================================
            
            --========================================================
            for i,v in ipairs (fxChunkTable)
            do
                newFXStateChunk = newFXStateChunk ..v.text.."\n";
                --====================================================
            end
            newFXStateChunk = newFXStateChunk ..">\n";
            --========================================================
            
            --========================================================
            local newStateChunk = string.gsub(chunk, "<FXCHAIN(.-)WAK %d+\n>\n",newFXStateChunk)
            reaper.SetTrackStateChunk(target, newStateChunk,false);
            --========================================================
        elseif(modeName == "take")
        then
            --========================================================
            local item     = reaper.GetMediaItemTake_Item(target);
            local takeIdx  = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE");
            local _,chunk  = reaper.GetItemStateChunk(item, "", false);
            --========================================================
            local fxChunkTable = {};
            local fxCount = 1;
            --========================================================
            local fxChainState = ""
            --========================================================
            for title,word,d in string.gmatch(chunk, "(<TAKEFX\n)(.-)(WAK %d+\n>\n)") 
            do 
                fxChainState = title..word..d;
            end
            --========================================================
            for title,word,d in string.gmatch(fxChainState, "(BYPASS)(.-)(WAK %d+\n)") 
            do 
                local fxStateChunk ={};
                fxStateChunk.index = fxCount;
                fxStateChunk.text  = title..word..d;
                table.insert ( fxChunkTable,fxStateChunk);
                fxCount = fxCount+1;
            end
            --========================================================
            
            --========================================================
            local targetFxid = fxid+1;
            --========================================================
            if ( isRight ==true)
            then
                if ( targetFxid < #fxChunkTable  and #fxChunkTable >=2)
                then
                    fxChunkTable[targetFxid].index   = fxChunkTable[targetFxid].index+1;
                    fxChunkTable[targetFxid+1].index = fxChunkTable[targetFxid+1].index-1;
                end
                --====================================================
            else
                --====================================================
                if ( targetFxid > 1 and #fxChunkTable >=2)
                then
                    fxChunkTable[targetFxid].index = fxChunkTable[targetFxid].index-1;
                    fxChunkTable[targetFxid-1].index = fxChunkTable[targetFxid-1].index+1;
                end
                --====================================================
            end
            --========================================================
            table.sort (fxChunkTable,function (a,b) return ( a.index < b.index); end );
            --========================================================
            
            local newFXStateChunk = "";
            newFXStateChunk = string.match( fxChainState ,"<TAKEFX.*DOCKED %d\n");
            --========================================================
            
            --========================================================
            for i,v in ipairs (fxChunkTable)
            do
                newFXStateChunk = newFXStateChunk ..v.text.."\n";
                --====================================================
            end
            newFXStateChunk = newFXStateChunk ..">\n";
            --========================================================
            local newStateChunk = string.gsub(chunk, "<TAKEFX(.-)WAK %d+\n>\n",newFXStateChunk)
            --========================================================
            reaper.SetItemStateChunk(item, newStateChunk,true)
            --========================================================
        end
        --============================================================
    end
    --================================================================
end
--====================================================================
function draw_FX_ToggleEnable(target,fxid, x,y, w, h,modeName)
    --================================================================
    local func_GetEnable = nil;
    local func_SetEnable = nil;
    --================================================================
    if ( modeName == "track" )
    then
        func_GetEnable = reaper.TrackFX_GetEnabled;
        func_SetEnable = reaper.TrackFX_SetEnabled;
    elseif(modeName == "take" )
    then
        func_GetEnable = reaper.TakeFX_GetEnabled;
        func_SetEnable = reaper.TakeFX_SetEnabled;;
    end
    --================================================================
    local text = " ON ";
    --================================================================
    local s_w, s_h = gfx.measurestr(text)
    x = x
    y = y+2
    gfx.x = x-2
    gfx.y = y-2
    --================================================================
    -- gfx.y = y-2*w
    if ( pointIN(x,y,w,h) )
    then 
        gfx.set(table.unpack(COLORS.FxEngaleButtonOnMouse))
    end
    --================================================================
    if ( func_GetEnable(target,fxid) ==false)
    then
        gfx.set(table.unpack(COLORS.FxEngaleButtonOff))
        --============================================================
        if ( pointIN(x,y,w,h) )
        then 
            gfx.set(table.unpack(COLORS.FxEngaleButtonOnMouse))
        end
        --============================================================
        text = " OFF ";
        gfx.a = 0.3;
        gfx.rect(x,y,w,s_h-4, func_GetEnable(target,fxid));
        --============================================================
        local countMul = 1;
        while ( gfx.measurestr( text) > w-1  )
        do
            gfx.setfont(1,FONTNAME,Z*countMul);
            countMul = countMul -0.1;
            --========================================================
            if ( countMul < 0.1)
            then
                break
            end
        end
        --============================================================
        gfx.x = x +w/2 - gfx.measurestr(text)/2
        gfx.y = y +(s_h-4)/2 - gfx.texth/2
        gfx.printf(text)
        gfx.setfont(1,FONTNAME,Z);
        --============================================================
    else
        gfx.set(table.unpack(COLORS.FxEngaleButtonOn))
        --============================================================
        if ( pointIN(x,y,w,h) )
        then 
            gfx.set(table.unpack(COLORS.FxEngaleButtonOnMouse))
        end
        --============================================================
        text = " ON ";
        gfx.a = 1;
        gfx.rect(x,y,w,s_h-4, func_GetEnable(target,fxid));
        gfx.set(table.unpack(COLORS.black))
        --============================================================
        local countMul = 1;
        while ( gfx.measurestr( text) > w-1  )
        do
            gfx.setfont(1,FONTNAME,Z*countMul);
            countMul = countMul -0.1
            if ( countMul < 0.1)
            then
                break
            end
        end
        --============================================================
        gfx.x = x +w/2 - gfx.measurestr(text)/2
        gfx.y = y +(s_h-4)/2 - gfx.texth/2
        gfx.printf(text)
        gfx.setfont(1,FONTNAME,Z);
        --============================================================
    end
    --================================================================
    
    --================================================================
    if (     mouseClick() 
         and pointIN(x,y,w,h)
        )
    then
        --============================================================
        func_SetEnable( target
                      , fxid
                      , func_GetEnable(target,fxid) ==false
                      );
        --============================================================
    end
    --================================================================
end
--====================================================================
function draw_FX(target,fx,chans, x,y,w,h,modeName)
    --================================================================
    local _  = nil;
    in_Pins  = nil;
    out_Pins = nil;
    --================================================================
    
    --================================================================
    if ( modeName =="track")
    then
        _, in_Pins,out_Pins  = reaper.TrackFX_GetIOSize(target,fx);
        --============================================================
    elseif ( modeName =="take")
    then
         _, in_Pins,out_Pins  = reaper.TakeFX_GetIOSize(target,fx);
        --============================================================
    end
    --================================================================
    
    --for some JS-plug-ins--------------------------------------------
    if   out_Pins==-1 and in_Pins~=-1 
    then 
        out_Pins=in_Pins ;--in some JS outs ret "-1" 
    end 
    --================================================================

    --================================================================
    draw_FX_head(target,fx,in_Pins,out_Pins, x,y,w,h,modeName)
   
    local startX = x;
    local endY   = y;
    local endX   = x;
    --================================================================
    --Draw FX pins,chans etc-- 
    --input pins---
    local isOut=0
    --================================================================
    for i=1,in_Pins 
    do
        --============================================================
        if ( IS_CH_NUMBER_MODE==true)
        then 
            gfx.set(table.unpack(COLORS.TextLabelColor));
            -- draw channel #
            --========================================================
            local y0 =y-w*2+ZZ;
            local chanNum = i   ;
            --========================================================
            gfx.setfont(1,FONTNAME, Z/1.5)
            --========================================================
            gfx.x = ( x +w/3);
            gfx.y = (y0 );
            gfx.drawstr(tostring(chanNum) );
            --========================================================
            gfx.setfont(1,FONTNAME, Z)--revert
        end 
        --============================================================
        
        --============================================================
        endY = draw_pin(target,fx,isOut, i-1,chans, x,y+ZZ,w,h,modeName)--(track,fx,isOut, pin,chans, x,y,  w,h)
        x = x + w --next x
        endX = x;
    end
    ---------------
    x = x + 1.2*w --Gap between FX in-out pins
    ---------------
    --output pins--
    isOut=1 
    for i=1,out_Pins 
    do
        --============================================================
        if ( IS_CH_NUMBER_MODE==true)
        then 
            gfx.set(table.unpack(COLORS.TextLabelColor));
            -- draw channel #
            --========================================================
            local y0 =y-w*2+ZZ;
            local chanNum = i   ;
            --========================================================
            gfx.setfont(1,FONTNAME, Z/1.5)
            --========================================================
            gfx.x = ( x +w/3);
            gfx.y = (y0 );
            gfx.drawstr(tostring(chanNum) );
            --========================================================
            gfx.setfont(1,FONTNAME, Z)--revert
        end 
        --============================================================
        
        --============================================================
        endY = draw_pin(target,fx,isOut, i-1,chans, x,y+ZZ,w,h,modeName)--(track,fx,isOut, pin,chans, x,y,  w,h)
        x = x + w --next x
        endX = x;
    end   
    --================================================================
    
    --================================================================
    if( in_Pins < 1
        and out_Pins <1)
    then
        --============================================================
        local areaWidth =(w*(in_Pins+out_Pins+1.2)-2)*2;
        local endWW =  startX + areaWidth-w +w;
        local toggleBtWidth = endWW-startX
        draw_FX_ID_addSub   (target,fx, startX                   ,endY+h/2    , w-2, h-2,modeName,false)
        draw_FX_ID_addSub   (target,fx, startX + areaWidth -w    ,endY+h/2    , w, h-2,modeName,true)
        draw_FX_ToggleEnable(target,fx, startX                   ,endY+h/2+h  , toggleBtWidth, h,modeName)
        --============================================================
    elseif ( out_Pins    <= 1 and in_Pins <= 1)
    then
        --============================================================
        local areaWidth =w*(in_Pins+out_Pins+1.2)
        local toggleBtWidth = areaWidth -w-2
        --============================================================
        draw_FX_ID_addSub   (target,fx, startX                 ,endY+h/2, w-2, h-2,modeName,false)
        draw_FX_ID_addSub   (target,fx, startX +areaWidth  ,endY+h/2, w-2, h-2,modeName,true)
        draw_FX_ToggleEnable(target,fx, startX +w              ,endY+h/2, toggleBtWidth, h,modeName)
        --============================================================
    else
        draw_FX_ID_addSub   (target,fx, startX     ,endY+h/2, w-2, h-2,modeName,false)
        draw_FX_ID_addSub   (target,fx, endX -w    ,endY+h/2, w-2, h-2,modeName,true)
        draw_FX_ToggleEnable(target,fx, startX+w   ,endY +h/2     , endX-startX-w*2-2, h,modeName)
        --============================================================
    end
    --================================================================
    return x --return x value for next FX position
end
--====================================================================
function draw_track_chan_add_sub(target,chans, x,y,w,h,modeName)
    --================================================================
    -- "-" button
    --================================================================
    gfx.set(table.unpack(COLORS.btAddSubChan) )
    x = x+1.5*w ; 
    y = y + h*(chans-1.5)
    y = y + h*2
    w, h = w-2, h-2
    --================================================================
    local s_w = gfx.measurestr("-")
    local s_h =gfx.texth;
    --================================================================
    local centerW = x+w/2;
    local centerH = y+h/2-1;
    --================================================================
    gfx.x = centerW - (s_w)/2 
    gfx.y = centerH - (s_h)/2 
    gfx.rect(x,y,w,h, 0);  gfx.printf("-")
    local text = "   Remove last 2 channels"
    gfx.printf(text)
    local offsetX = gfx.measurestr(text )
    --================================================================
    if (     mouseClick() 
         and pointIN(x,y,w,h) 
        )
    then
        --============================================================
        if ( modeName =="track")
        then
            reaper.SetMediaTrackInfo_Value(target, "I_NCHAN", math.max(chans-2,2));
            --========================================================
        elseif ( modeName =="take")
        then
            -- takeFX
            --========================================================
            local item     = reaper.GetMediaItemTake_Item(target);
            local takeIdx  = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE");
            local _,chunk  = reaper.GetItemStateChunk(item, "", false);
            --========================================================
            local takes    = reaper.GetMediaItemNumTakes(item);
            local channels = 2;
            local  newChunk = "";
            --========================================================
            if ( false or takes == 1 )
            then
                channels = chunk:match("TAKEFX_NCH (%d+)") ;
                if( channels ~= nil)
                then 
                    newChunk = string.gsub( chunk
                                          , "TAKEFX_NCH ".. tostring(channels)
                                          , "TAKEFX_NCH ".. tostring( math.max(channels-2,2) )
                                      );
                else
                    channels = 2;
                end
                --====================================================
            else
                -- have to cut out the part of the chunk regarding this take
                local pattern = ""
                local takeChunkTable ={}
                --====================================================
                for title,word in string.gmatch(chunk, "(\nNAME)(.-)\nTAKE[^FV]") 
                do 
                    local takeChunk = {}
                    takeChunk.text = title..word .."\n";;
                    --================================================
                    table.insert ( takeChunkTable,takeChunk);
                end
                --====================================================
                local lines_ =  string.match(chunk, "\nNAME.-(\nTAKE.*)"):split("\n");
                --====================================================
                for i=1,#lines_
                do
                    if (   lines_[i] == "TAKE"
                        or lines_[i] == "TAKE SEL"
                       )
                    then
                        local takeChunkText ="";
                        --============================================
                        while (     i < #lines_)
                        do
                            takeChunkText = takeChunkText..lines_[i].."\n";
                            --========================================
                            if(    lines_[i+1] =="TAKE"
                                or lines_[i+1] =="TAKE SEL" 
                               )
                            then 
                                break;
                            end
                            --========================================
                            i =i+1;
                        end
                        --============================================
                        local takeChunk = {}
                        takeChunk.text = takeChunkText;;
                        --============================================
                        table.insert ( takeChunkTable,takeChunk);
                    end
                end
                --====================================================
                channels = takeChunkTable[takeIdx+1].text:match("TAKEFX_NCH (%d+)") ;
                --====================================================
                -- change channnel
                --====================================================
                if( channels ~= nil)
                then 
                    local newTAKE_chunk =  string.gsub( takeChunkTable[takeIdx+1].text
                                                      , "TAKEFX_NCH (%d+)"
                                                      , "TAKEFX_NCH ".. tostring( math.min(channels-2,32) )
                                                      );
                    takeChunkTable[takeIdx+1].text = newTAKE_chunk;
                else
                    -- nothing to do.
                end
                --====================================================
                -- gen and apply new Chunk
                --====================================================
                newChunk = string.match(chunk, "(.-)\nNAME")  ;
                newChunk = newChunk .."\n";
                --====================================================
                for i=1,#takeChunkTable
                do
                    newChunk = newChunk ..takeChunkTable[i].text .."\n"
                end
                --====================================================
            end
            --========================================================
            reaper.SetItemStateChunk(item, newChunk,true);
        end
        --============================================================
    end 
    --================================================================
    -- "+" button
    --================================================================
    -- y = y+h+8; 
    x = x +offsetX+w;
    s_w, s_h = gfx.measurestr("+")
    gfx.x = x + (w-(s_w ))/2;
    gfx.y = y + (h-s_h)/2
    gfx.set(table.unpack(COLORS.btAddSubChan) )
    gfx.rect(x,y,w,h, 0); gfx.printf("+")
    gfx.printf("   Add 2 more channels")
    --================================================================
    if (     mouseClick() 
        and  pointIN(x,y,w,h) 
        )
    then
        --============================================================
        if ( modeName =="track")
        then
            reaper.SetMediaTrackInfo_Value(target, "I_NCHAN", math.min(chans+2,32));
            --========================================================
        elseif ( modeName =="take")
        then
            -- takeFX
            --========================================================
            local item     = reaper.GetMediaItemTake_Item(target);
            local takeIdx  = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE");
            local _,chunk  = reaper.GetItemStateChunk(item, "", false);
            --========================================================
            local takes    = reaper.GetMediaItemNumTakes(item);
            local channels = 2;
            local  newChunk = "";
            --========================================================
            if ( false or takes == 1 )
            then
                channels = chunk:match("TAKEFX_NCH (%d+)") ;
                --====================================================
                if( channels ~= nil)
                then 
                    newChunk = string.gsub( chunk
                                          , "TAKEFX_NCH ".. tostring(channels)
                                          , "TAKEFX_NCH ".. tostring( math.min(channels+2,32) )
                                      );
                else
                    channels = 2;
                    local fxChainState = ""
                    --================================================
                    for title,word,d in string.gmatch(chunk, "(<TAKEFX\n)(.-)(WAK %d+\n>\n)") 
                    do 
                        fxChainState = title..word..d;
                    end
                    --================================================
                    newChunk = string.gsub( chunk
                                          , "<TAKEFX(.-)WAK %d+\n>\n"
                                          ,fxChainState .."TAKEFX_NCH 4" 
                                          );
                    --================================================
                end
                --====================================================
            else
                -- have to cut out the part of the chunk regarding this take
                --====================================================
                local pattern = ""
                local takeChunkTable ={}
                --====================================================
                for title,word in string.gmatch(chunk, "(\nNAME)(.-)\nTAKE[^FV]") 
                do 
                    local takeChunk = {}
                    takeChunk.text = title..word .."\n";;
                    --================================================
                    table.insert ( takeChunkTable,takeChunk);
                end
                --====================================================
                local lines_ =  string.match(chunk, "\nNAME.-(\nTAKE.*)"):split("\n");
                --====================================================
                for i=1,#lines_
                do
                    if (   lines_[i] == "TAKE"
                        or lines_[i] == "TAKE SEL"
                       )
                    then
                        local takeChunkText ="";
                        --============================================
                        while (     i < #lines_)
                        do
                            takeChunkText = takeChunkText..lines_[i].."\n";
                            --========================================
                            if(    lines_[i+1] =="TAKE"
                                or lines_[i+1] =="TAKE SEL" 
                               )
                            then 
                                break;
                            end
                            --========================================
                            i =i+1;
                        end
                        --============================================
                        local takeChunk = {}
                        takeChunk.text = takeChunkText;;
                        --============================================
                        table.insert ( takeChunkTable,takeChunk);
                    end
                end
                --====================================================
                -- change channel
                --====================================================
                channels = takeChunkTable[takeIdx+1].text:match("TAKEFX_NCH (%d+)") ;
                --====================================================
                if( channels ~= nil)
                then 
                    local newTAKE_chunk =  string.gsub( takeChunkTable[takeIdx+1].text
                                                      , "TAKEFX_NCH (%d+)"
                                                      , "TAKEFX_NCH ".. tostring( math.min(channels+2,32) )
                                                      );
                    takeChunkTable[takeIdx+1].text = newTAKE_chunk;
                else
                    channels = 2;
                    local fxChainState = ""
                    --================================================
                    for title,word,d in string.gmatch(takeChunkTable[takeIdx+1].text, "(<TAKEFX\n)(.-)(WAK %d+\n>\n)") 
                    do 
                        fxChainState = title..word..d;
                    end
                    --================================================
                    takeChunkTable[takeIdx+1].text =  takeChunkTable[takeIdx+1].text  .."TAKEFX_NCH 4\n" ;
                    --================================================
                end
                --====================================================
                -- gen and apply new Chunk
                --====================================================
                newChunk = string.match(chunk, "(.-)\nNAME")  ;
                newChunk = newChunk .."\n";
                --====================================================
                for i=1,#takeChunkTable
                do
                    newChunk = newChunk ..takeChunkTable[i].text .."\n"
                end
                --====================================================
            end
            --========================================================
            reaper.SetItemStateChunk(item, newChunk,true);
        end
        --============================================================
    end 
    --================================================================
end
--====================================================================
function draw_track_in_out(type,track,chans, x,y,w,h)
    --================================================================
    if type == "IN" then for i=0,chans do last_in[i] =x end end
    --================================================================
    
    --================================================================
    gfx.x, gfx.y = x, y-2*w
    --================================================================
    gfx.set(table.unpack(COLORS.btAddSubChan) )
    --================================================================
    gfx.printf(type)
    --================================================================
    for i=1,chans
    do 
        --============================================================
        if (      pointIN(x,y,w,h)
             and  mouseClick()
             and  type =="OUT"
            )
        then 
            Chans_outPropety[i].isOutRouting = (Chans_outPropety[i].isOutRouting == false );
        end
        --============================================================
        
        if (     pointIN(x,y,w,h) ==true
            and  type =="OUT" )
        then
            gfx.set(table.unpack( COLORS.TextInOutNameOnMouse));
        else
            set_greys(i)
        end
        --============================================================
        if (Chans_outPropety[i].isOutRouting == false
            and type =="OUT")
        then 
            gfx.a = 0.1
        else
            gfx.a =1;
        end
        --============================================================
        gfx.rect(x,y,w-2,h-2, 1)
        --============================================================
        if show_pins > 0
        then 
            draw_pin_number(x,y,w-2,h-2,i) 
        end
        --============================================================
        y = y + h;
        --============================================================
    end
    --================================================================
end
--====================================================================
function draw_FX_add(target, x,y, w, h,modeName)
    --================================================================
    local text = " Add FX "
    --================================================================
    if (modeName == "take" )
    then
        text = " Show Take FX  "
    end
    --================================================================
    local s_w, s_h = gfx.measurestr(text)
    x = x
    y= y+2
    gfx.x = x
    gfx.y = y
    --================================================================
    -- gfx.y = y-2*w
    if ( pointIN(x,y,s_w,s_h) )
    then 
        gfx.set(table.unpack(COLORS.AddFxButtonOnMouse))
    else
        gfx.set(table.unpack(COLORS.AddFxButtonOffMouse))
    end
    --================================================================
    gfx.rect(x,y,s_w,s_h, 1);
    gfx.set(table.unpack(COLORS.black))
    gfx.printf(text)
    --================================================================
    if (     mouseClick() 
         and pointIN(x,y,s_w,s_h)
        )
    then
        -- open FX browser
        if ( modeName == "track" )
        then
            -- reaperCMD(40271)
            reaper.Main_OnCommandEx(40271, 1,0);
        elseif(modeName == "take")
        then
            -- FX_Show(target,0,1)
            reaper.TakeFX_Show(target,0,1)
        end
        --============================================================
    end
    --================================================================
end
--====================================================================
function draw_TrackOnlyButton( x,y, w, h)
    local text = " Track And Take "
    --================================================================
    if (isTrackOnly  == true )
    then
        text = " Track Only "
    end
    --================================================================
    local s_w, s_h = gfx.measurestr(text)
    x = x
    y= y+2
    gfx.x = x
    gfx.y = y
    --================================================================
    -- gfx.y = y-2*w
    if ( pointIN(x,y,s_w,s_h) )
    then 
        gfx.set(table.unpack(COLORS.TrackOnlyButtonOnMouse))
    else
        if (isTrackOnly  == true )
        then
            gfx.set(table.unpack(COLORS.TrackOnlyButtonOn))
        else
            gfx.set(table.unpack(COLORS.TrackOnlyButtonOff))
        end
    end
    --================================================================
    gfx.rect(x,y,s_w,s_h, 1);
    gfx.set(table.unpack(COLORS.black))
    gfx.printf(text)
    --================================================================
    if (     mouseClick() 
         and pointIN(x,y,s_w,s_h)
        )
    then
        isTrackOnly = (isTrackOnly== false);
        --============================================================
    end
    --================================================================
end
--====================================================================

--====================================================================
function checkWhetherTrackOrTake()
    --================================================================
    local target = nil;
    local modeName = "";
    --================================================================
    if (     reaper.GetCursorContext2(true) == 1 
         and reaper.CountSelectedMediaItems(0)>0 
         and isTrackOnly == false
       )
    then
        local item = reaper.GetSelectedMediaItem(0,0);
        local take = reaper.GetActiveTake(item);
        --============================================================
        if ( take ~=nil  ) -- check whether empty item or .
        then
            target = take
            --setFxContext("item")
            modeName = "take";
        end
        --============================================================
    else
        target   = reaper.GetSelectedTrack(0, 0);
        modeName = "track";
        --============================================================
        if (    reaper.CountSelectedTracks2(0, true) >0
            and target == nil
           )
        then 
            target = reaper.GetMasterTrack( 0 );
        end
        --============================================================
    end
    --================================================================
    return target,modeName;
end
--====================================================================
function getTakeFX_channnels( targetTake)
    --================================================================
    local item     = reaper.GetMediaItemTake_Item(targetTake);
    local takeIdx  = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE");
    local _,chunk  = reaper.GetItemStateChunk(item, "", false);
    local takes    = reaper.GetMediaItemNumTakes(item);
    local channels = 2;
    --================================================================
    if ( false or takes == 1 )
    then
        channels = chunk:match("TAKEFX_NCH (%d+)") or 2;
    else
        -- have to cut out the part of the chunk regarding this take
        local pattern = ""
        --============================================================
        for i=0,takeIdx-1 do
            pattern = "\nNAME .+" .. pattern
        end
        --============================================================
        pattern = pattern .. "\n+NAME (.+)"
        for i=takeIdx+1,takes-1 do
            pattern = pattern .. "\n+NAME .+"
        end
        --============================================================
        local chunkPart = chunk:match(pattern)
        channels = chunkPart:match("TAKEFX_NCH (%d+)") or 2;
    end
    --================================================================
    return math.min(tonumber(channels),32);
    --================================================================
end
--====================================================================
function drawBorder(barNum_)
    --================================================================
    local barNum = barNum_;
    local oneBarWidth = gfx.w / barNum
    --================================================================
    local colDt = 1.0/barNum;
    --================================================================
    for i =1, barNum
    do
        local r,g,b = HSBtoRGB(   COLORS.TopBarColorHue 
                                + COLORS.TopBarColorHueWidth *(i/barNum)
                                , COLORS.TopBarColorSat 
                                , COLORS.TopBarColorVal)
        gfx.set(r/255,g/255,b/255,1)
        --============================================================
        if (   IS_DRAWBORDER_TOP    == true)
        then
            gfx.rect( oneBarWidth * (i-1) -1
                    , 0
                    , oneBarWidth +5
                    , BORDER_HEIGHT,true)
        end
        --============================================================
        if ( IS_DRAWBORDER_BOTTOM == true)
        then
            gfx.rect( oneBarWidth * (i-1) -1
                    , gfx.h-BORDER_HEIGHT
                    , oneBarWidth +5
                    , BORDER_HEIGHT,true)
        end
        --============================================================
    end
    --================================================================
end
--====================================================================
function DRAW()
    --================================================================
    local w,h = Z,Z --its only one chan(rectangle) w and h (but it used in all calculation)
    local x,y = 3.5*w, 3.5*h  --its first pin of first FX    x and y (but it used in all calculation) 
    local M_Wheel 
    local y0 = w
    --================================================================
    local target,modeName = checkWhetherTrackOrTake();
    --================================================================
    local preFixName = "";
    --================================================================
    local maxY = 0
    --================================================================
    if (   last_selectedTrack ~= target 
        and IS_ENABLE_COLOR_MODULATION ==true)
    then
        checkScriptColor(modeName);
    end
    --================================================================
    local offset_X = 0
    local offset_Y = 0
    --================================================================
    if (IS_DRAWBORDER_TOP ==false)
    then
        offset_Y = 0;
    end
    --================================================================
    if ( target ~= nil )
    then
        --============================================================
        local targetName = nil;
        local fx_count   = nil;
        local chans      = nil;
        --============================================================
        if (modeName=="track" )
        then
            --========================================================
            _, targetName = reaper.GetSetMediaTrackInfo_String(target, "P_NAME", "", false);
            fx_count      = reaper.TrackFX_GetCount(target);
            chans         = math.min( reaper.GetMediaTrackInfo_Value(target, "I_NCHAN"), 32 );
            --========================================================
            preFixName = "Track : ";
            if ( target == reaper.GetMasterTrack( 0 ))
            then
                preFixName = "Master Track: ";
            end
            --========================================================
        elseif (modeName=="take" )
        then
            --========================================================
            targetName = reaper.GetTakeName(target);
            fx_count   = reaper.TakeFX_GetCount(target);
            chans      =getTakeFX_channnels( target); ;
            --========================================================
            preFixName = "Take : ";
            --========================================================
        end
        --============================================================
        
        --============================================================
        ---Zoom------
        if Ctrl and not Shift 
        then 
            M_Wheel = gfx.mouse_wheel;gfx.mouse_wheel = 0 
            --========================================================  
            if ( M_Wheel > 0 )
            then 
                zoomMultiply = zoomMultiply +0.1
                -- Z = math.min(Z+1, 30)
            elseif (M_Wheel<0 ) 
            then 
                zoomMultiply = zoomMultiply -0.1
                -- Z = math.max(Z-1, 8)
            end
            --========================================================
            -- Z  =(gfx.h / maxYBlock)
            -- ZZ = Z *2
            --========================================================
            zoomMultiply = math.max( 0.1 ,zoomMultiply);
        end
        --============================================================
        local maxYBlockNum = chans +9 --14
        if ( IS_DRAWBORDER_TOP == false   )then maxYBlockNum = maxYBlockNum-0.5 end
        if ( IS_DRAWBORDER_BOTTOM ==false )then maxYBlockNum = maxYBlockNum-0.5 end
        --============================================================
        -- apply Z
        if (IS_DRAWBORDER_TOP ==false)
        then
            offset_Y = 0;
            maxYBlockNum =maxYBlockNum +1;
        end
        --============================================================
        
        --============================================================
        local _target_YNum ;
        local _target_YHeight;
        --============================================================
        if( IS_USE_AUTOFIT == true )
        then
            _target_YNum = maxYBlockNum
            _target_YHeight = math.max(gfx.h,1)
        else
            _target_YNum = 20
            _target_YHeight = 400
        end
        --============================================================
        Z  =( _target_YHeight / _target_YNum) * zoomMultiply 
        --============================================================
        ZZ = Z *2
        --============================================================
       
        --============================================================
        ---Rewind---
        M_Wheel = gfx.mouse_wheel;gfx.mouse_wheel = 0
        if M_Wheel<0 then R = math.min(R+1, fx_count) 
        elseif M_Wheel>0 then R = math.max(R-1, 1) end
        gfx.setfont(1,FONTNAME, Z)
        --============================================================
        
        -- mouse button rewind
        --============================================================
        if (    ( Ctrl ==false and  Alt ==false and gfx.mouse_cap & 2)  == 2
             or ( gfx.mouse_cap & 64) == 64
             or ( Shift and ( gfx.mouse_cap & 1)  == 1)
            )
        then
            if (   ( gfx.mouse_x - last_x) > 0
                )
            then 
                R =  math.max(R-0.35, 1) ;  
                --====================================================
            elseif (    ( gfx.mouse_x - last_x) < 0
                    )
            then
                R =  math.min(R+0.35, fx_count);
                --====================================================
            end
            --========================================================
        end
        --============================================================

        -- 
        --============================================================
        if (    -- ( Ctrl==true  and ( gfx.mouse_cap & 2)  == 2 )
                ( Ctrl==true  and ( gfx.mouse_cap & 1)  == 1 )
             or ( last_selectedTrack ~= target )
             or ( last_selectedTrackFxCount ~= fx_count )
           )
        then 
            --========================================================
            local isExistEnable =false;
            for i=1, fx_count 
            do 
                local check_ =nil;
                --====================================================
                if     ( modeName == "track" )
                then
                    check_ = reaper.TrackFX_GetEnabled(target,i-1);
                elseif ( modeName == "take"  )
                then
                    check_ = reaper.TakeFX_GetEnabled(target,i-1);
                end
                --====================================================
                if ( check_ ==true)
                then
                    R = i;
                    isExistEnable = true;
                    --================================================
                    break ;
                end
                --====================================================
            end
            --========================================================
            if ( isExistEnable ==false)
            then
                R =1;
            end
            --========================================================
            last_selectedTrackFxCount = fx_count;
        end
        --============================================================
        
        --============================================================
        -- DarkStar mods
        ---Display / hide the pin numbers and wires ---
        if Alt and mouseClick()      then show_pins  = 1 - show_pins  end
        if Alt and mouseRightClick() then show_wires = 1 - show_wires end
        if Ctrl  and mouseRightClick()    then show_allow = 1 - show_allow end
        
        --============================================================
        
        --============================================================
        -- draw track info(name,fx count etc)
        --============================================================
        gfx.set( table.unpack(COLORS.TextTrackOrTakeName));
        gfx.x = x  +offset_X;
        gfx.y = h/2+offset_Y;
        gfx.printf( preFixName .. targetName .."  FXs: "..fx_count )
        --============================================================
        draw_FX_add(target,   gfx.x+w/2+offset_X, h/2.5+offset_Y, w, h-2,modeName);
        draw_TrackOnlyButton( gfx.x+w/2+offset_X, h/2.5+offset_Y, w, h-2);

        --============================================================
        --draw track in,chan_add_sub----------
        draw_track_in_out("IN", target,chans, w+offset_X,y+ZZ+offset_Y,w,h);
        draw_track_chan_add_sub(target,chans, w+offset_X,y+ZZ+h*1.5+offset_Y,w,h,modeName) ;
        --============================================================
        --draw each FX(pins,chans etc)--------------------------------
        for i=math.floor(R), fx_count 
        do
            --R = 1-st drawing FX(used for rewind FXs)
            x = draw_FX(target, i-1,chans, x+offset_X,y+offset_Y,w,h,modeName) + w*2 -- offset for next FX
        end 
        --============================================================
        -- draw track out --------------------------------------------
        draw_track_in_out("OUT",target,chans, x+offset_X,y+ZZ+offset_Y,w,h)
        
        --============================================================
        if ( show_wires > 0 )
        then
            --========================================================
            y = y+ZZ +h/2+offset_Y
            x = x+offset_X
            --========================================================
            for i= 1, chans
            do
                if ( grey_wires > 0 )
                then 
                    set_greys(i) 
                else 
                    set_colour(i) 
                end
                --====================================================
                local allowWidth  = w/(ARROW_SIZE*2)
                local allowLength = w/(ARROW_SIZE)
                --====================================================
                if (    last_in[i-1] > y0
                    and Chans_outPropety[i].isOutRouting ==true)
                then
                    --================================================
                    local rectThickness = ARROW_LINE_WIDTH;
                    local _w =  ( x-1 ) - (last_in[i-1]+w-2)
                    local _h = rectThickness;
                    gfx.rect( last_in[i-1]+w-2 , y  -_h/2
                            , _w-allowLength/2 , _h    );
                    --================================================
                    if ( show_allow >0)
                    then 
                        --============================================
                        gfx.triangle (  x-1, y -_h/2
                                       ,x -allowLength, y-allowWidth-_h/6
                                       ,x -allowLength, y+allowWidth-_h/6
                                     );
                    end
                    --================================================
                end
                --====================================================
                y =y+h;
                --====================================================
            end
            --========================================================
        end
        --============================================================
    else 
        --============================================================
        gfx.setfont(1,FONTNAME, Z)
        gfx.set(table.unpack(COLORS.TextTrackOrTakeName)); gfx.x, gfx.y = 4*w, h; gfx.printf("Track:  " .. "None selected!") 
        --============================================================
    end
    --================================================================
    last_selectedTrack = target;
    --================================================================
    if (   IS_DRAWBORDER_BOTTOM == true
        or IS_DRAWBORDER_TOP    == true)
    then
        drawBorder(10);
    end
    --================================================================
end
--====================================================================

---INIT---------------------------------------------------------------
function init()
    --================================================================
    -- global variables
    --================================================================
    Z  = 20 --used as cell w,h(and for change zoom level etc)
    ZZ = 40
    R = 1  --used for rewind FXs
    
    gfx.init( "Track / FX Pins", 850,355 )
    gfx.setfont(1,FONTNAME, Z)
    last_mouse_cap=0
    mouse_dx, mouse_dy =0,0
    --================================================================
    show_pins  = 1
    show_wires = 1
    grey_wires = 0
    show_allow = 1
    --================================================================
    if ( IS_DOCKSTART == true)
    then 
        gfx.dock(0x801);
    end
    --================================================================
    COLORS ={}; -- color setting
    Chans_outPropety ={};-- output wire property
    --================================================================
    last_in = {} -- used to store that previous node used on each channel
    last_x,last_y = gfx.mouse_x,gfx.mouse_y;
    last_selectedTrack = nil;
    last_selectedTrackFxCount = 0;
    --================================================================
    checkScriptColor("");
    setUp_ChansOutputProperty();
    isTrackOnly = true;
    local _offsetV = math.min( math.max( -10,START_ZOOM_LEVEL_OFFSET),10 )
    zoomMultiply = math.max(0.1,1 + _offsetV * 0.1);
    --================================================================
    ARROW_LINE_WIDTH = math.max(ARROW_LINE_WIDTH,0);
    ARROW_SIZE = ( 10.1-math.min(10,math.max(ARROW_SIZE,1)) )/2;
    --================================================================
end
--====================================================================

--====================================================================
local function mainloop()
    --================================================================
    gfx.update();
    --================================================================
    mouse_ox = gfx.mouse_x;
    mouse_oy = gfx.mouse_y;
    --================================================================
    Ctrl  = gfx.mouse_cap&4==4
    Shift = gfx.mouse_cap&8==8
    Alt   = gfx.mouse_cap&16==16
    --================================================================
    
    -- MAIN DRAW function
    --================================================================
    DRAW()
    --================================================================
    
    -- store mouse state or
    --================================================================
    last_mouse_cap = gfx.mouse_cap
    last_x,last_y  = gfx.mouse_x,gfx.mouse_y
    last_InputChar =  gfx.getchar();
   
    -- defer
    --================================================================
    if     ( last_InputChar == 27) -- ESC key
    then
        gfx.quit(); -- close
        --============================================================
    elseif ( last_InputChar ~=-1 )
    then 
        reaper.defer(mainloop); --defer
        --============================================================
    end
    --================================================================
end
--====================================================================
init();
mainloop();
--====================================================================

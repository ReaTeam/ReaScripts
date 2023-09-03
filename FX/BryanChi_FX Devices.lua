-- @description FX Devices
-- @author Bryan Chi
-- @version 1.0beta9.6.7
-- @changelog
--   FX Devices 9.6.6-4
--   - New : Shift+ RMB to bypass a modulation.
--   - Fix Slider default width shows as 0 , and inputting values by typing don’t work.
--   - Fix unable to RMB drag to adjust modulation range without choosing a source when there’s only one modulation on the parameter.
--   - Add Clap plugins support for FX adder !!! Thanks to Suzuki’s contribution !!!!
-- @provides
--   [effect] BryanChi_FX Devices/FXD Macros.jsfx
--   [effect] BryanChi_FX Devices/FXD ReSpectrum.jsfx
--   [effect] BryanChi_FX Devices/FXD Gain Reduction Scope.jsfx
--   [effect] BryanChi_FX Devices/FXD Split to 32 Channels.jsfx
--   [effect] BryanChi_FX Devices/FXD Split To 4 Channels.jsfx
--   [effect] BryanChi_FX Devices/cookdsp.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/analysis.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/buffer.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/delay.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/dynamics.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/effects.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/fft-mono-template
--   [effect] BryanChi_FX Devices/cookdsp/fft-stereo-template
--   [effect] BryanChi_FX Devices/cookdsp/fftobjects.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/filters.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/granulator.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/list.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/memalloc.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/midi.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/mmath.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/oscil.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/pobjects.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/pv-mono-template
--   [effect] BryanChi_FX Devices/cookdsp/pv-stereo-template
--   [effect] BryanChi_FX Devices/cookdsp/pvocobjects.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/pvtrans-example
--   [effect] BryanChi_FX Devices/cookdsp/random.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/scaling.jsfx-inc
--   [effect] BryanChi_FX Devices/firhalfband.jsfx-inc
--   [effect] BryanChi_FX Devices/spectrum.jsfx-inc
--   [effect] BryanChi_FX Devices/svf_filter.jsfx-inc
--   BryanChi_FX Devices/IconFont1.ttf
--   [effect] BryanChi_FX Devices/FXD (Mix)RackMixer.jsfx
--   BryanChi_FX Devices/FX Layouts/ValhallaFreqEcho (Valhalla DSP, LLC).ini
--   BryanChi_FX Devices/FX Layouts/ValhallaShimmer (Valhalla DSP, LLC).ini
--   BryanChi_FX Devices/FX Layouts/ValhallaVintageVerb (Valhalla DSP, LLC).ini
--   BryanChi_FX Devices/FX Layouts/ValhallaSupermassive (Valhalla DSP, LLC).ini
--   BryanChi_FX Devices/FX Layouts/ValhallaDelay (Valhalla DSP, LLC).ini
--   [effect] BryanChi_FX Devices/FXD Saike BandSplitter.jsfx
--   [effect] BryanChi_FX Devices/FXD Band Joiner.jsfx
--   BryanChi_FX Devices/Images/Analog Knob 1.png
--   BryanChi_FX Devices/Functions/EQ functions.lua
--   BryanChi_FX Devices/Functions/General Functions.lua
--   BryanChi_FX Devices/Functions/FX Layering.lua
--   BryanChi_FX Devices/Functions/FX Adder.lua
--   BryanChi_FX Devices/Functions/Layout Editor functions.lua
--   BryanChi_FX Devices/Functions/Modulation.lua
--   BryanChi_FX Devices/Functions/Theme Editor Functions.lua
-- @about
--   Please check the forum post for info:
--   https://forum.cockos.com/showthread.php?t=263622

-- @description FX Devices
-- @author Bryan Chi
-- @version 1.0beta9.6.6-3
-- @changelog
--   - Fix Theme editor saving empty entry crashes
--   - Fix Pro-C 2 crash
-- @provides
--   [effect] BryanChi_FX Devices/FXD Macros.jsfx
--   [effect] BryanChi_FX Devices/FXD ReSpectrum.jsfx
--   [effect] BryanChi_FX Devices/FXD Gain Reduction Scope.jsfx
--   [effect] BryanChi_FX Devices/FXD Split to 32 Channels.jsfx
--   [effect] BryanChi_FX Devices/FXD Split To 4 Channels.jsfx
--   [effect] BryanChi_FX Devices/cookdsp.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/analysis.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/buffer.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/delay.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/dynamics.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/effects.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/fft-mono-template
--   [effect] BryanChi_FX Devices/cookdsp/fft-stereo-template
--   [effect] BryanChi_FX Devices/cookdsp/fftobjects.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/filters.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/granulator.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/list.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/memalloc.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/midi.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/mmath.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/oscil.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/pobjects.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/pv-mono-template
--   [effect] BryanChi_FX Devices/cookdsp/pv-stereo-template
--   [effect] BryanChi_FX Devices/cookdsp/pvocobjects.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/pvtrans-example
--   [effect] BryanChi_FX Devices/cookdsp/random.jsfx-inc
--   [effect] BryanChi_FX Devices/cookdsp/scaling.jsfx-inc
--   [effect] BryanChi_FX Devices/firhalfband.jsfx-inc
--   [effect] BryanChi_FX Devices/spectrum.jsfx-inc
--   [effect] BryanChi_FX Devices/svf_filter.jsfx-inc
--   BryanChi_FX Devices/IconFont1.ttf
--   [effect] BryanChi_FX Devices/FXD (Mix)RackMixer.jsfx
--   BryanChi_FX Devices/FX Layouts/ValhallaFreqEcho (Valhalla DSP, LLC).ini
--   BryanChi_FX Devices/FX Layouts/ValhallaShimmer (Valhalla DSP, LLC).ini
--   BryanChi_FX Devices/FX Layouts/ValhallaVintageVerb (Valhalla DSP, LLC).ini
--   BryanChi_FX Devices/FX Layouts/ValhallaSupermassive (Valhalla DSP, LLC).ini
--   BryanChi_FX Devices/FX Layouts/ValhallaDelay (Valhalla DSP, LLC).ini
--   [effect] BryanChi_FX Devices/FXD Saike BandSplitter.jsfx
--   [effect] BryanChi_FX Devices/FXD Band Joiner.jsfx
--   BryanChi_FX Devices/Images/Analog Knob 1.png
--   BryanChi_FX Devices/Functions/EQ functions.lua
--   BryanChi_FX Devices/Functions/General Functions.lua
--   BryanChi_FX Devices/Functions/FX Layering.lua
--   BryanChi_FX Devices/Functions/FX Adder.lua
--   BryanChi_FX Devices/Functions/Layout Editor functions.lua
--   BryanChi_FX Devices/Functions/Modulation.lua
--   BryanChi_FX Devices/Functions/Theme Editor Functions.lua
-- @about
--   Please check the forum post for info:
--   https://forum.cockos.com/showthread.php?t=263622

--------------------------==  declare Initial Variables & Functions  ------------------------
VersionNumber = 'V1.0beta9.6.7 '
FX_Add_Del_WaitTime = 2
r = reaper






function msg(A)
    r.ShowConsoleMsg(A)
end

dofile(r.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')
('0.6')

dofile(r.GetResourcePath() .. '/Scripts/ReaTeam Scripts/FX/BryanChi_FX Devices/Functions/EQ functions.lua')






VP = {}
demo = {}
app = {}
enum_cache = {}
cache = {}
Draw = {
    Rect = {},
    DrawMode = {},
    ItemInst = {},
    L = {},
    R = {},
    Y = {},
    T = {},
    B = {},
    FxGUID = {},
    Time = 0,
    Df_EdgeRound = {}
}
AddFX = { Pos = {}, Name = {}, GUID = {} }
DelFX = { Pos = {}, Name = {} }
MovFX = { ToPos = {}, FromPos = {}, Lbl = {}, Copy = {} }
ClrPallet = {}
Glob = {};
Sel_Cross = {}
ToDef = {}
DraggingFXs = {}; DraggingFXs_Idx = {}
DefaultWidth = 200
--Sequencer -----
StepSEQ_W = 20
StepSEQ_H = 100
SEQ_Default_Num_of_Steps = 8
SEQ_Default_Denom = 1




----------- Custom Colors-------------------
CustomColors = { 'Window_BG', 'FX_Devices_Bg', 'FX_Layer_Container_BG', 'Space_Between_FXs', 'Morph_A', 'Morph_B',
    'Layer_Solo', 'Layer_Mute', 'FX_Adder_VST', 'FX_Adder_VST3', 'FX_Adder_JS', 'FX_Adder_AU' }
CustomColorsDefault = {
    Window_BG = 0x000000ff,
    FX_Devices_Bg = 0x151515ff,
    FX_Layer_Container_BG = 0x262626ff,
    Space_Between_FXs = 0x131313ff,
    Morph_A = 0x22222266,
    Morph_B = 0x78787877,
    Layer_Solo = 0xDADF3775,
    Layer_Mute = 0xBE01015C,
    FX_Adder_VST = 0x6FB74BFF,
    FX_Adder_VST3 = 0xC3DC5CFF,
    FX_Adder_JS = 0x9348A9FF,
    FX_Adder_AU = 0x526D97FF,
    FX_Adder_CLAP = 0xB62424FF

}



----------Parameters --------------------
Prm = {
    McroModAmt = {},
    McroModAmt_Norm = {},
    Pos_L = {},
    Pos_T = {},
    Pos_R = {},
    Pos_B = {},
    ModAngle = {},
    SldrGrabXPos = {},
    Val = {},
    NameS = {},
    FXGUID = {},
    InstAdded = {},
    Init_Val = {},
    Num = {},
    TrkID = {},
    Deletable = {},
    Name = {}
}

-----------------------------------------
-----Param Modulations
-----------------------------------------
PM = { Ins = {}, FXGUID = {}, Corres_Glob_ID = {}, HasMod = {}, Final_V = {}, DIY_TrkID = {} }
waitForGmem = 0


-----------------------------------------
-----FX layering
-----------------------------------------
Lyr = {
    Selected = {},
    title = {},
    ProgBarClick = {},
    Title = {},
    ProgBarVal = {},
    SpltrID = {},
    Count = {},
    Solo = {},
    Mute = {},
    Rename = {},
    FX_Ins = {},
    ProgBarDrag = {},
    EditingTitle = {},
    LastFXPos = {},
    FrstFXPos = {},
    SplitrAttachTo = {},
    PrevFX = {},
    TitleToShow = {},
}

Spltr = {}


LE = { GridSize = 10, Sel_Items = {}, ChangeR_Bound = {} }
----Preset Morph--------------
PresetMorph = { timer = 0 }

--- FX Chain -----------------------------
FXchain = { FxGUID = {}, wait = 0, }


----track--------------------------------
Trk = {
    GUID = {},
    Prm = { FXGUID = {}, Inst = {}, AssignWhich = {}, V = {}, O_V = {}, Num = {}, WhichMcros = {} },
    FxGUID = {},
    PreFX = {}
}

------------------Divider---------------
Dvdr = { Width = {}, Clr = {}, Spc_Hover = {}, RestoreNormWidthWait = 0, RestoreNormWidthWait = {}, JustDrop = {}, }

-----------------FX State-----------------
FX = {
    Enable = {},
    InLyr = {},
    Width = {},
    Collapse = {},
    LyrNum = {},
    Win = {},
    Win_Name = {},
    Def_Type = {},
    Win_Name_S = {},
    TitleWidth = {},
    Sldr_W = {},
    WidthCollapse = {},
    Round = {},
    GrbRound = {},
    BgClr = {},
    Def_Sldr_W = {},
    Prm = {
        V_Round = {},
        V_FontSize = {},
        ShowCondition = {},
        ConditionPrm = {},
        ConditionPrm_V = {},
        Switch_W = {},
        Combo_W = {},
        Options = {},
        BgClrHvr = {},
        BgClrAct = {},
        Lbl_Clr = {},
        V_Clr = {},
        DragDir = {},
        Lbl_Pos = {},
        V_Pos = {},
        Style = {},
        GrbClr = {},
        BgClr = {},
        Count = {},
        Name = {},
        Num = {},
        V = {},
        InitV = {},
        AssignWhichParam = {},
        ToTrkPrm = {},
        Lbl = {},
        PosX = {},
        PosY = {},
        VertSldr = {},
        Type = {},
        CustomLbl = {},
        FontSize = {},
        Sldr_H = {}
    }
}


Knob_DefaultFontSize = 10
LBL_DefaultFontSize = 10
Df = { V_Sldr_W = 15, KnobRadius = 18, KnobSize = 15 * 3, Sldr_W = 160, Dvdr_Width = 15, Dvdr_Hvr_W = 0 }


-----------ShortCut-----------
AllAvailableKeys = {
    ['0'] = r.ImGui_Key_0(),
    ['1'] = r.ImGui_Key_1(),
    ['2'] = r.ImGui_Key_2(),
    ['3'] = r.ImGui_Key_3(),
    ['4'] = r.ImGui_Key_4(),
    ['5'] = r.ImGui_Key_5(),
    ['6'] = r.ImGui_Key_6(),
    ['7'] = r.ImGui_Key_7(),
    ['8'] = r.ImGui_Key_8(),
    ['9'] = r.ImGui_Key_9(),
    A = r.ImGui_Key_A(),
    B = r.ImGui_Key_B(),
    C = r.ImGui_Key_C(),
    D = r.ImGui_Key_D(),
    E = r.ImGui_Key_E(),
    F = r.ImGui_Key_F(),
    G = r.ImGui_Key_G(),
    H = r.ImGui_Key_H(),
    I = r.ImGui_Key_I(),
    J = r.ImGui_Key_J(),
    K = r.ImGui_Key_K(),
    L = r.ImGui_Key_L(),
    M = r.ImGui_Key_M(),
    N = r.ImGui_Key_N(),
    O = r.ImGui_Key_O(),
    P = r.ImGui_Key_P(),
    Q = r.ImGui_Key_Q(),
    R = r.ImGui_Key_R(),
    S = r.ImGui_Key_S(),
    T = r.ImGui_Key_T(),
    U = r.ImGui_Key_U(),
    V = r.ImGui_Key_V(),
    W = r.ImGui_Key_W(),
    X = r.ImGui_Key_X(),
    Y = r.ImGui_Key_Y(),
    Z = r.ImGui_Key_Z(),
    Esc = r.ImGui_Key_Escape(),
    F1 = r.ImGui_Key_F1(),
    F2 = r.ImGui_Key_F2(),
    F3 = r.ImGui_Key_F3(),
    F4 = r.ImGui_Key_F4(),
    F5 = r.ImGui_Key_F5(),
    F6 = r.ImGui_Key_F6(),
    F7 = r.ImGui_Key_F7(),
    F8 = r.ImGui_Key_F8(),
    F9 = r.ImGui_Key_F9(),
    F10 = r.ImGui_Key_F10(),
    F11 = r.ImGui_Key_F11(),
    F12 = r.ImGui_Key_F12(),
    Apostrophe = r.ImGui_Key_Apostrophe(),
    Backslash = r.ImGui_Key_Backslash(),
    Backspace = r.ImGui_Key_Backspace(),
    Comma = r.ImGui_Key_Comma(),
    Delete = r.ImGui_Key_Delete(),
    DownArrow = r.ImGui_Key_DownArrow(),
    Enter = r.ImGui_Key_Enter(),
    End = r.ImGui_Key_End(),
    Equal = r.ImGui_Key_Equal(),
    GraveAccent = r.ImGui_Key_GraveAccent(),
    Home = r.ImGui_Key_Home(),
    ScrollLock = r.ImGui_Key_ScrollLock(),
    Insert = r.ImGui_Key_Insert(),
    Minus = r.ImGui_Key_Minus(),
    LeftArrow = r.ImGui_Key_LeftArrow(),
    LeftBracket = r.ImGui_Key_LeftBracket(),
    Period = r.ImGui_Key_Period(),
    PageDown = r.ImGui_Key_PageDown(),
    PageUp = r.ImGui_Key_PageUp(),
    Pause = r.ImGui_Key_Pause(),
    RightBracket = r.ImGui_Key_RightBracket(),
    RightArrow = r.ImGui_Key_RightArrow(),
    SemiColon = r.ImGui_Key_Semicolon(),
    Slash = r.ImGui_Key_Slash(),
    Space = r.ImGui_Key_Space(),
    Tab = r.ImGui_Key_Tab(),
    UpArrow = r.ImGui_Key_UpArrow(),
    Pad0 = r.ImGui_Key_Keypad0(),
    Pad1 = r.ImGui_Key_Keypad1(),
    Pad2 = r.ImGui_Key_Keypad2(),
    Pad3 = r.ImGui_Key_Keypad3(),
    Pad4 = r.ImGui_Key_Keypad4(),
    Pad5 = r.ImGui_Key_Keypad5(),
    Pad6 = r.ImGui_Key_Keypad6(),
    Pad7 = r.ImGui_Key_Keypad7(),
    Pad8 = r.ImGui_Key_Keypad8(),
    Pad9 = r.ImGui_Key_Keypad9(),
    PadAdd = r.ImGui_Key_KeypadAdd(),
    PadDecimal = r.ImGui_Key_KeypadDecimal(),
    PadDivide = r.ImGui_Key_KeypadDivide(),
    PadEnter = r.ImGui_Key_KeypadEnter(),
    PadEqual = r.ImGui_Key_KeypadEqual(),
    PadMultiply = r.ImGui_Key_KeypadMultiply(),
    PadSubtract = r.ImGui_Key_KeypadSubtract(),
}

KB_Shortcut = {}
Command_ID = {}


--------Pro C ------------------------
ProC = { Width = 280, Pt = { R = { m = {}, M = {} }, L = { m = {}, M = {} } } }












-------------------Macros --------------------------
Mc = { Val_Trk = {}, V_Out = { 0, 0, 0, 0, 0, 0, 0, 0, 0 }, Name = {} }
Wet = { DragLbl = {}, Val = {}, P_Num = {} }
r.gmem_attach('gmemForSpectrum')

-- FXs listed here will not have a fx window in the script UI
BlackListFXs = { 'Macros', 'JS: Macros .+', 'Frequency Spectrum Analyzer Meter', 'JS: FXD Split to 32 Channels',
    'JS: FXD (Mix)RackMixer .+', 'FXD (Mix)RackMixer', 'JS: FXD Macros', 'FXD Macros',
    'JS: FXD ReSpectrum', 'AU: AULowpass (Apple)', 'AU: AULowpass', 'VST: FabFilter Pro C 2 ', 'Pro-C 2', 'Pro C 2',
    'JS: FXD Split to 4 channels', 'JS: FXD Gain Reduction Scope',
    'JS: FXD Saike BandSplitter', 'JS: FXD Band Joiner', 'FXD Saike BandSplitter', 'FXD Band Joiner',
    'FXD Split to 32 Channels'
}
UtilityFXs = { 'Macros', 'JS: Macros /[.+', 'Frequency Spectrum Analyzer Meter', 'JS: FXD Split to 32 Channels',
    'JS: FXD (Mix)RackMixer .+', 'FXD (Mix)RackMixer', 'JS: FXD Macros', 'FXD Macros',
    'JS: FXD ReSpectrum', 'JS: FXD Split to 4 channels', 'JS: FXD Gain Reduction Scope', 'JS: FXD Band Joiner',
    'FXD Split to 32 Channels'
}

SpecialLayoutFXs = { 'VST: FabFilter Pro C 2 ', 'Pro Q 3', 'VST: FabFilter Pro Q 3 ', 'VST3: Pro Q 3 FabFilter',
    'VST3: Pro C 2 FabFilter', 'AU: Pro C 2 FabFilter' }







Sel_Track = r.GetSelectedTrack(0, 0)
if Sel_Track ~= nil then Sel_Track_FX_Count = reaper.TrackFX_GetCount(Sel_Track) end


FX_DeviceWindow_NoScroll = 0
FXGUID = {}
FirstLoop = true



------- ==  Colors ----------

Clr = {
    SliderGrab = 0x309D89ff,
    Dvdr = {
        Active = 0x777777aa,
        In_Layer = 0x131313ff,
        outline = 0x444444ff
    }

}

CLR_BtwnFXs_Btn_Hover = 0x77777744
CLR_BtwnFXs_Btn_Active = 0x777777aa
FX_Window_Clr_When_Dragging = 0x44444433
FX_Window_Clr_Default = 0x262626ff
Btns_Hover_DefaultColor = 0x2d3b3aff

Btns_DefaultColor = 0x333333ff
Btns_ClickedColor = 0x358f8fff
BGColor_FXLayeringWindow = 0x262626ff

Macro1Color = 0xff2121ff
Macro2Color = 0xff5521ff
Macro3Color = 0xff8921ff
Macro4Color = 0xffd321ff
Macro5Color = 0xf4ff21ff
Macro6Color = 0xb9ff21ff
Macro7Color = 0x6fff21ff
Macro8Color = 0x21ff6bff

EightColors = {
    LowMidSat = {},
    LowSat = {},
    MidSat = {},
    Bright = {},
    Bright_HighSat = {},
    HighSat_MidBright = {},
    bgWhenAsgnMod = {},
    bgWhenAsgnModAct = {},
    bgWhenAsgnModHvr = {}
}
for a = 1, 8, 1 do
    colors = reaper.ImGui_ColorConvertHSVtoRGB(0.08 * (a - 1), 0.25, 0.33, 0.25)
    table.insert(EightColors.LowSat, colors)
    colors = reaper.ImGui_ColorConvertHSVtoRGB(0.08 * (a - 1), 0.25, 0.33, 0.5)
    table.insert(EightColors.LowMidSat, colors)
    colors = reaper.ImGui_ColorConvertHSVtoRGB(0.08 * (a - 1), 0.5, 0.5, 0.5)
    table.insert(EightColors.MidSat, colors)
    colors = reaper.ImGui_ColorConvertHSVtoRGB(0.08 * (a - 1), 1, 0.5, 0.2)
    table.insert(EightColors.Bright, colors)
    colors = reaper.ImGui_ColorConvertHSVtoRGB(0.08 * (a - 1), 1, 1, 0.9)
    table.insert(EightColors.Bright_HighSat, colors)
    colors = reaper.ImGui_ColorConvertHSVtoRGB(0.08 * (a - 1), 1, 0.5, 0.5)
    table.insert(EightColors.HighSat_MidBright, colors)
    colors = reaper.ImGui_ColorConvertHSVtoRGB(0.08 * (a - 0.7), 0.7, 0.6, 0.15)
    table.insert(EightColors.bgWhenAsgnMod, colors)
    colors = reaper.ImGui_ColorConvertHSVtoRGB(0.08 * (a - 0.7), 0.8, 0.7, 0.9)
    table.insert(EightColors.bgWhenAsgnModAct, colors)
    colors = reaper.ImGui_ColorConvertHSVtoRGB(0.08 * (a - 0.7), 1, 0.2, 0.5)
    table.insert(EightColors.bgWhenAsgnModHvr, colors)
end
-----end of colors--------

Array_Macro_Colors = {
    frameBgColor          = {},
    frameBgHoveredColor   = {},
    frameBgActiveColor    = {},
    sliderGrabColor       = {},
    sliderGrabActiveColor = {}
}


x = 0.5

Cont_Param_Add_Mode = false

Array = {}







-----------------Script Testing Area---------------------------























----------------------------End declare Initial Variables   ------------------------

--------------------------==  Before GUI (No Loop) ----------------------------


function GetLTParam()
    LT_Track = reaper.GetLastTouchedTrack()
    retval, LT_Prm_TrackNum, LT_FXNum, LT_ParamNum = reaper.GetLastTouchedFX()
    --GetTrack_LT_Track = reaper.GetTrack(0,LT_TrackNum)
    if LT_Track ~= nil then
        retval, LT_FXName = reaper.TrackFX_GetFXName(LT_Track, LT_FXNum)
        retval, LT_ParamName = reaper.TrackFX_GetParamName(LT_Track, LT_FXNum, LT_ParamNum)
    end
end

GetLTParam()

ctx = r.ImGui_CreateContext('FX Device', r.ImGui_ConfigFlags_DockingEnable())
dofile(reaper.GetResourcePath() .. "/UserPlugins/ultraschall_api.lua")

Show_H_ScrollBar = reaper.ImGui_WindowFlags_HorizontalScrollbar()
AlwaysHScroll = reaper.ImGui_WindowFlags_AlwaysHorizontalScrollbar()




dofile(r.GetResourcePath() .. '/Scripts/ReaTeam Scripts/FX/BryanChi_FX Devices/Functions/General functions.lua')

dofile(r.GetResourcePath() .. '/Scripts/ReaTeam Scripts/FX/BryanChi_FX Devices/Functions/Layout Editor functions.lua')

dofile(r.GetResourcePath() .. '/Scripts/ReaTeam Scripts/FX/BryanChi_FX Devices/Functions/FX Layering.lua')

dofile(r.GetResourcePath() .. '/Scripts/ReaTeam Scripts/FX/BryanChi_FX Devices/Functions/Modulation.lua')












Font_Andale_Mono      = reaper.ImGui_CreateFont('andale mono', 13)
Font_Andale_Mono_6    = r.ImGui_CreateFont('andale mono', 6)
Font_Andale_Mono_7    = r.ImGui_CreateFont('andale mono', 7)
Font_Andale_Mono_8    = reaper.ImGui_CreateFont('andale mono', 8)
Font_Andale_Mono_9    = r.ImGui_CreateFont('andale mono', 9)
Font_Andale_Mono_10   = reaper.ImGui_CreateFont('andale mono', 10)
Font_Andale_Mono_11   = reaper.ImGui_CreateFont('andale mono', 11)
Font_Andale_Mono_12   = r.ImGui_CreateFont('andale mono', 12)
Font_Andale_Mono_13   = r.ImGui_CreateFont('andale mono', 13)
Font_Andale_Mono_14   = r.ImGui_CreateFont('andale mono', 14)
Font_Andale_Mono_15   = r.ImGui_CreateFont('andale mono', 15)
Font_Andale_Mono_16   = r.ImGui_CreateFont('andale mono', 16)
Font_Andale_Mono_20_B = reaper.ImGui_CreateFont('andale mono', 20, r.ImGui_FontFlags_Bold())
Font_Andale_Mono_20   = reaper.ImGui_CreateFont('andale mono', 20)

local script_folder   = select(2, r.get_action_context()):match('^(.+)[\\//]')
script_folder         = script_folder .. '/BryanChi_FX Devices'
FontAwesome           = r.ImGui_CreateFont(script_folder .. '/IconFont1.ttf', 30)

function attachImages()
    Img = {
        Analog1 = r.ImGui_CreateImage(r.GetResourcePath() ..
            '/Scripts/ReaTeam Scripts/FX/BryanChi_FX Devices/Images/Analog Knob 1.png'),

    }
    r.ImGui_Attach(ctx, Img.Analog1)
end

attachImages()


r.ImGui_AttachFont(ctx, Font_Andale_Mono)
r.ImGui_AttachFont(ctx, Font_Andale_Mono_6)
r.ImGui_AttachFont(ctx, Font_Andale_Mono_7)
r.ImGui_AttachFont(ctx, Font_Andale_Mono_8)
r.ImGui_AttachFont(ctx, Font_Andale_Mono_9)
r.ImGui_AttachFont(ctx, Font_Andale_Mono_10)
r.ImGui_AttachFont(ctx, Font_Andale_Mono_11)
r.ImGui_AttachFont(ctx, Font_Andale_Mono_12)
r.ImGui_AttachFont(ctx, Font_Andale_Mono_13)
r.ImGui_AttachFont(ctx, Font_Andale_Mono_14)
r.ImGui_AttachFont(ctx, Font_Andale_Mono_15)
r.ImGui_AttachFont(ctx, Font_Andale_Mono_16)
r.ImGui_AttachFont(ctx, Font_Andale_Mono_20_B)
r.ImGui_AttachFont(ctx, Font_Andale_Mono_20)
r.ImGui_AttachFont(ctx, FontAwesome)

Arial = r.ImGui_CreateFont('Arial', 12)
Arial_10 = r.ImGui_CreateFont('Arial', 10)
Arial_9 = r.ImGui_CreateFont('Arial', 9)
Arial_8 = r.ImGui_CreateFont('Arial', 8)
Arial_7 = r.ImGui_CreateFont('Arial', 7)
Arial_6 = r.ImGui_CreateFont('Arial', 6)
Arial_12 = r.ImGui_CreateFont('Arial', 12)
Arial_11 = r.ImGui_CreateFont('Arial', 11)
Arial_13 = r.ImGui_CreateFont('Arial', 13)
Arial_14 = r.ImGui_CreateFont('Arial', 14)
Arial_15 = r.ImGui_CreateFont('Arial', 15)
Arial_16 = r.ImGui_CreateFont('Arial', 16)

r.ImGui_AttachFont(ctx, Arial_6)
r.ImGui_AttachFont(ctx, Arial_7)
r.ImGui_AttachFont(ctx, Arial_8)
r.ImGui_AttachFont(ctx, Arial_9)
r.ImGui_AttachFont(ctx, Arial_10)
r.ImGui_AttachFont(ctx, Arial_11)
r.ImGui_AttachFont(ctx, Arial_12)
r.ImGui_AttachFont(ctx, Arial_13)
r.ImGui_AttachFont(ctx, Arial_14)
r.ImGui_AttachFont(ctx, Arial_15)
r.ImGui_AttachFont(ctx, Arial_16)
r.ImGui_AttachFont(ctx, Arial)




















dofile(r.GetResourcePath() .. '/Scripts/ReaTeam Scripts/FX/BryanChi_FX Devices/Functions/Theme Editor functions.lua')
dofile(r.GetResourcePath() .. '/Scripts/ReaTeam Scripts/FX/BryanChi_FX Devices/Functions/FX Adder.lua')







NumOfTotalTracks = reaper.CountTracks(0)
-- Repeat for every track, at the beginning of script
for Track_Idx = 0, NumOfTotalTracks - 1, 1 do
    local Track = reaper.GetTrack(0, Track_Idx)
    local TrkID = r.GetTrackGUID(Track)

    Trk[TrkID] = Trk[TrkID] or {}
    Trk[TrkID].Mod = {}
    Trk[TrkID].SEQL = Trk[TrkID].SEQL or {}
    Trk[TrkID].SEQ_Dnom = Trk[TrkID].SEQ_Dnom or {}
    for i = 1, 8, 1 do -- for every modulator
        Trk[TrkID].Mod[i] = {}
        Trk[TrkID].Mod[i].ATK = tonumber(select(2,
            r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro ' .. i .. ' Atk', '', false)))
        Trk[TrkID].Mod[i].REL = tonumber(select(2,
            r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro ' .. i .. ' Rel', '', false)))
        Trk[TrkID].SEQL[i] = tonumber(select(2,
            r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro ' .. i .. ' SEQ Length', '', false)))
        Trk[TrkID].SEQ_Dnom[i] = tonumber(select(2,
            r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro ' .. i .. ' SEQ Denominator', '', false)))

        Trk[TrkID].Mod[i].SEQ = Trk[TrkID].Mod[i].SEQ or {}
        --Get Seq Steps
        if Trk[TrkID].SEQL[i] then
            for St = 1, Trk[TrkID].SEQL[i], 1 do
                Trk[TrkID].Mod[i].SEQ[St] = tonumber(select(2,
                    r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St .. ' Val', '',
                        false)))
            end
        end
    end



    local FXCount = reaper.TrackFX_GetCount(Track)
    Trk[TrkID] = Trk[TrkID] or {}
    Trk[TrkID].PreFX = Trk[TrkID].PreFX or {}
    Trk[TrkID].PostFX = Trk[TrkID].PostFX or {}
    RetrieveFXsSavedLayout(FXCount)

    Trk[TrkID].ModPrmInst = tonumber(select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ModPrmInst', '', false)))
    for CC = 1, Trk[TrkID].ModPrmInst or 0, 1 do
        _, Trk.Prm.WhichMcros[CC .. TrkID] = r.GetSetMediaTrackInfo_String(Track,
            'P_EXT: CC Linked to which Modulation' .. CC, '', false)
    end

    _, PM.DIY_TrkID[TrkID] = r.GetProjExtState(0, 'FX Devices', 'Track GUID Number for jsfx' .. TrkID)
    PM.DIY_TrkID[TrkID] = tonumber(PM.DIY_TrkID[TrkID])

    _, Trk.Prm.Inst[TrkID] = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Trk Prm Count', '', false)
    Trk.Prm.Inst[TrkID] = tonumber(Trk.Prm.Inst[TrkID])

    i = 1
    while i do
        local rv, str = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: PreFX ' .. i, '', false)
        if rv then
            Trk[TrkID].PreFX[i] = str; i = i + 1
        else
            i = nil
        end
    end

    i = 1
    while i do
        local rv, str = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: PostFX ' .. i, '', false)
        if rv then
            Trk[TrkID].PostFX[i] = str; i = i + 1
        else
            i = nil
        end
    end



    if Trk[TrkID].PreFX == {} then Trk[TrkID].PreFX = nil end
    for P = 1, Trk.Prm.Inst[TrkID] or 0, 1 do
        _, Trk.Prm.Num[P .. TrkID] = r.GetProjExtState(0, 'FX Devices', 'Track' .. TrkID .. ' P =' .. P)
        _, Trk.Prm.WhichMcros[P .. TrkID] = r.GetProjExtState(0, 'FX Devices',
            'Prm' .. P .. 'Has Which Macro Assigned, TrkID =' .. TrkID)
        if Trk.Prm.WhichMcros[P .. TrkID] == '' then Trk.Prm.WhichMcros[P .. TrkID] = nil end

        Trk.Prm.Num[P .. TrkID] = tonumber(Trk.Prm.Num[P .. TrkID])

        for FX_Idx = 0, FXCount - 1, 1 do --repeat as many times as fx instances
            local FxGUID = r.TrackFX_GetFXGUID(Track, FX_Idx)
            _, Trk.Prm.FXGUID[P .. TrkID] = r.GetProjExtState(0, 'FX Devices', 'P_Trk :' .. P .. 'Trk-' .. TrkID)
        end
    end

    for FX_Idx = 0, FXCount - 1, 1 do --repeat as many times as fx instances
        local FxGUID = r.TrackFX_GetFXGUID(Track, FX_Idx)
        local _, FX_Name = r.TrackFX_GetFXName(Track, FX_Idx)




        local _, DefaultSldr_W = r.GetProjExtState(0, 'FX Devices', 'Default Slider Width for FX:' .. FxGUID)
        if DefaultSldr_W ~= '' then FX.Def_Sldr_W[FxGUID] = DefaultSldr_W end
        local _, Def_Type = r.GetProjExtState(0, 'FX Devices', 'Default Param type for FX:' .. FxGUID)
        if Def_Type ~= '' then FX.Def_Type[FxGUID] = Def_Type end

        if FxGUID ~= nil then
            GetProjExt_FxNameNum(FxGUID)

            _, FX.InLyr[FxGUID]          = r.GetProjExtState(0, 'FX Devices', 'FXLayer - ' .. 'is FX' ..
                FxGUID .. 'in layer')
            --FX.InLyr[FxGUID] = StringToBool[FX.InLyr[FxGUID]]
            _, FX.LyrNum[FxGUID]         = r.GetProjExtState(0, 'FX Devices', 'FXLayer ' .. FxGUID .. 'LayerNum')
            _, FX[FxGUID].inWhichLyr     = r.GetProjExtState(0, 'FX Devices', 'FXLayer - ' .. FxGUID .. 'is in Layer ID')
            _, FX[FxGUID].ContainerTitle = r.GetProjExtState(0, 'FX Devices - ',
                'FX' .. FxGUID .. 'FX Layer Container Title ')
            if FX[FxGUID].ContainerTitle == '' then FX[FxGUID].ContainerTitle = nil end

            FX[FxGUID].inWhichLyr = tonumber(FX[FxGUID].inWhichLyr)
            FX.LyrNum[FxGUID] = tonumber(FX.LyrNum[FxGUID])
            _, Lyr.SplitrAttachTo[FxGUID] = r.GetProjExtState(0, 'FX Devices', 'SplitrAttachTo' .. FxGUID)
            _, Prm.InstAdded[FxGUID] = r.GetProjExtState(0, 'FX Devices', 'FX' .. FxGUID .. 'Params Added')
            if Prm.InstAdded[FxGUID] == 'true' then Prm.InstAdded[FxGUID] = true end

            if FX.InLyr[FxGUID] == "" then FX.InLyr[FxGUID] = nil end
            FX[FxGUID].Morph_ID = tonumber(select(2,
                r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FXs Morph_ID' .. FxGUID, '', false)))
            _, FX[FxGUID].Unlink = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FXs Morph_ID' .. FxGUID .. 'Unlink', '',
                false)
            if FX[FxGUID].Unlink == 'Unlink' then FX[FxGUID].Unlink = true elseif FX[FxGUID].Unlink == '' then FX[FxGUID].Unlink = nil end

            if FX[FxGUID].Morph_ID then
                Trk[TrkID].Morph_ID = Trk[TrkID].Morph_ID or {}
                Trk[TrkID].Morph_ID[FX[FxGUID].Morph_ID] = FxGUID
            end

            local rv, ProC_ID = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: ProC_ID ' .. FxGUID, '', false)
            if rv then FX[FxGUID].ProC_ID = tonumber(ProC_ID) end

            if FX[FxGUID].Unlink == 'Unlink' then FX[FxGUID].Unlink = true elseif FX[FxGUID].Unlink == '' then FX[FxGUID].Unlink = nil end

            for Fx_P = 1, #FX[FxGUID] or 0, 1 do
                FX[FxGUID][Fx_P].V = tonumber(select(2,
                    r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' ..
                        Fx_P .. 'Value before modulation', '', false)))


                local ParamX_Value = 'Param' ..
                    tostring(FX[FxGUID][Fx_P].Name) .. 'On  ID:' .. tostring(Fx_P) .. 'value' .. FxGUID
                ParamValue_At_Script_Start = r.TrackFX_GetParamNormalized(Track, FX_Idx, FX[FxGUID][Fx_P].Num or 0)
                _G[ParamX_Value] = ParamValue_At_Script_Start
                _, FX.Prm.ToTrkPrm[FxGUID .. Fx_P] = r.GetProjExtState(0, 'FX Devices',
                    'FX' .. FxGUID .. 'Prm' .. Fx_P .. 'to Trk Prm')
                FX.Prm.ToTrkPrm[FxGUID .. Fx_P] = tonumber(FX.Prm.ToTrkPrm[FxGUID .. Fx_P])

                local F_Tp = FX.Prm.ToTrkPrm[FxGUID .. Fx_P]

                _G[ParamX_Value] = FX[FxGUID][Fx_P].V or 0
                FX[FxGUID][Fx_P].WhichCC = tonumber(select(2,
                    r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'WhichCC' ..
                        (FX[FxGUID][Fx_P].Num or 0), '', false)))
                _, FX[FxGUID][Fx_P].WhichMODs = r.GetSetMediaTrackInfo_String(Track,
                    'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Linked to which Mods', '', false)
                if FX[FxGUID][Fx_P].WhichMODs == '' then FX[FxGUID][Fx_P].WhichMODs = nil end
                FX[FxGUID][Fx_P].ModAMT = {}


                local CC = FX[FxGUID][Fx_P].WhichCC
                local HasModAmt
                for m, v in ipairs(MacroNums) do
                    local FP = FX[FxGUID][Fx_P]
                    FX[FxGUID][Fx_P].ModAMT[m] = tonumber(select(2,
                        r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' ..
                            Fx_P .. 'Macro' .. m .. 'Mod Amt', '', false)))
                    if FX[FxGUID][Fx_P].ModAMT[m] then HasModAmt = true end

                    Trk[TrkID].Mod = Trk[TrkID].Mod or {}
                    Trk[TrkID].Mod[m] = Trk[TrkID].Mod[m] or {}
                    Trk[TrkID].Mod[m].Val = tonumber(select(2,
                        r.GetProjExtState(0, 'FX Devices', 'Macro' .. m .. 'Value of Track' .. TrkID)))

                    FP.ModBypass = RemoveEmptyStr(select(2,
                        r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX' .. FxGUID .. 'Prm' .. Fx_P .. 'Mod bypass', '',
                            false)))




                    if Prm.McroModAmt[IdM] ~= nil then
                        local width = FX.Width[FxGUID] or DefaultWidth or 270
                        Prm.McroModAmt_Norm[IdM] = Prm.McroModAmt --[[ [IdM]/(width*0.65) ]]
                    end
                end

                if not HasModAmt then FX[FxGUID][Fx_P].ModAMT = nil end
            end

            FX[FxGUID] = FX[FxGUID] or {}
            if r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX Morph A' .. '1' .. FxGUID, '', false) then
                FX[FxGUID].MorphA = FX[FxGUID].MorphA or {}
                FX[FxGUID].MorphB = FX[FxGUID].MorphB or {}
                FX[FxGUID].PrmList = {}
                local PrmCount = r.TrackFX_GetNumParams(Track, FX_Idx)

                RestoreBlacklistSettings(FxGUID, FX_Idx, Track, PrmCount)

                for i = 0, PrmCount - 4, 1 do
                    _, FX[FxGUID].MorphA[i] = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX Morph A' .. i .. FxGUID, '',
                        false)
                    FX[FxGUID].MorphA[i] = tonumber(FX[FxGUID].MorphA[i])
                    _, FX[FxGUID].MorphB[i] = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX Morph B' .. i .. FxGUID, '',
                        false)
                    FX[FxGUID].MorphB[i] = tonumber(FX[FxGUID].MorphB[i])
                end

                _, FX[FxGUID].MorphA_Name = r.GetSetMediaTrackInfo_String(Track,
                    'P_EXT: FX Morph A' .. FxGUID .. 'Preset Name', '', false)
                if FX[FxGUID].MorphA_Name == '' then FX[FxGUID].MorphA_Name = nil end
                _, FX[FxGUID].MorphB_Name = r.GetSetMediaTrackInfo_String(Track,
                    'P_EXT: FX Morph B' .. FxGUID .. 'Preset Name', '', false)
                if FX[FxGUID].MorphB_Name == '' then FX[FxGUID].MorphB_Name = nil end
            end
        end

        _, FX_Name = r.TrackFX_GetFXName(Track, FX_Idx)
        if string.find(FX_Name, 'FXD %(Mix%)RackMixer') or string.find(FX_Name, 'FXRack') then
            local FXGUIDofRackMixer = r.TrackFX_GetFXGUID(Track, FX_Idx)
            FX[FXGUIDofRackMixer].LyrID = FX[FXGUIDofRackMixer].LyrID or {}
            FX[FXGUIDofRackMixer].LyrTitle = FX[FXGUIDofRackMixer].LyrTitle or {}
            FX[FXGUIDofRackMixer].ActiveLyrCount = 0

            for i = 1, 8, 1 do
                _, FX[FXGUIDofRackMixer].LyrID[i] = r.GetProjExtState(0, 'FX Devices',
                    'FX' .. FXGUIDofRackMixer .. 'Layer ID ' .. i)
                _, FX[FXGUIDofRackMixer].LyrTitle[i] = r.GetProjExtState(0, 'FX Devices - ',
                    'FX' .. FXGUIDofRackMixer .. 'Layer Title ' .. i)
                if FX[FXGUIDofRackMixer].LyrTitle[i] == '' then FX[FXGUIDofRackMixer].LyrTitle[i] = nil end
                FX[FXGUIDofRackMixer].LyrID[i] = tonumber(FX[FXGUIDofRackMixer].LyrID[i])
                if FX[FXGUIDofRackMixer].LyrID[i] ~= -1 and FX[FXGUIDofRackMixer].LyrID[i] then
                    FX[FXGUIDofRackMixer].ActiveLyrCount =
                        FX[FXGUIDofRackMixer].ActiveLyrCount + 1
                end
            end


            _, Lyr.FX_Ins[FXGUIDofRackMixer] = r.GetProjExtState(0, 'FX Devices', 'FX Inst in Layer' .. FxGUID)
            if Lyr.FX_Ins[FXGUIDofRackMixer] == "" then Lyr.FX_Ins[FXGUIDofRackMixer] = nil end
            Lyr.FX_Ins[FXGUIDofRackMixer] = tonumber(Lyr.FX_Ins[FXGUIDofRackMixer])
        elseif FX_Name:find('FXD Saike BandSplitter') then
            FX[FxGUID].BandSplitID = tonumber(select(2,
                r.GetSetMediaTrackInfo_String(Track, 'P_EXT: BandSplitterID' .. FxGUID, '', false)))
            _, FX[FxGUID].AttachToJoiner = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Splitter\'s Joiner FxID ' ..
                FxGUID, '', false)

            for FX_Idx = 0, FXCount - 1, 1 do --repeat as many times as fx instances
                --Restore Band Split
                local FxID = r.TrackFX_GetFXGUID(Track, FX_Idx)
                if select(2, r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX is in which BS' .. FxID, '', false)) == FxGUID then
                    --local _, Guid_FX_In_BS = r.GetSetMediaTrackInfo_String(LT_Track,'P_EXT: FX is in which BS'..FxID, '', false  )
                    FX[FxID] = FX[FxID] or {}
                    FX[FxID].InWhichBand = tonumber(select(2,
                        r.GetSetMediaTrackInfo_String(Track, 'P_EXT: FX is in which Band' .. FxID, '', false)))

                    FX[FxGUID].FXsInBS = FX[FxGUID].FXsInBS or {}
                    table.insert(FX[FxGUID].FXsInBS, FxID)
                end
            end
        end



        if Track == LT_Track and string.find(FX_Name, 'Pro%-Q 3') ~= nil then
            _, ProQ3.DspRange[FX_Idx] = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, 331)
            ProQ3['scaleLabel' .. ' ID' .. FxGUID] = ProQ3.DspRange[FX_Idx]
            ProQ3['scale' .. ' ID' .. FxGUID] = syncProQ_DispRange(ProQ3.DspRange[FX_Idx])
        end
    end

    for m = 1, 8, 1 do
        _, Trk[TrkID].Mod[m].Name = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Macro' .. m .. 's Name' .. TrkID, '',
            false)
        if Trk[TrkID].Mod[m].Name == '' then Trk[TrkID].Mod[m].Name = nil end
        _, Trk[TrkID].Mod[m].Type = r.GetSetMediaTrackInfo_String(Track, 'P_EXT: Mod' .. m .. 'Type', '', false)
        if Trk[TrkID].Mod[m].Type == '' then Trk[TrkID].Mod[m].Type = nil end
    end
end


---------------------------------------------------------------
-----------Retrieve Keyboard Shortcut Settings ----------------
---------------------------------------------------------------
if CallFile('r', 'Keyboard Shortcuts.ini') then
    local file, filepath = CallFile('r', 'Keyboard Shortcuts.ini')
    Content = file:read('*a')
    local L = get_lines(filepath)
    for i, v in ipairs(L) do
        KB_Shortcut[i] = v:sub(0, v:find(' =') - 1)
        Command_ID[i] = v:sub(v:find(' =') + 3, nil)
    end
end





---------------------------- End For Before GUI ----------------------------

function loop()
    GetLT_FX_Num()
    GetLTParam()

    if Dock_Now then
        r.ImGui_SetNextWindowDockID(ctx, -1)
    end
    Dock_Now = nil
    ProC.ChanSplit = nil





    if LT_Track then TrkClr = r.ImGui_ColorConvertNative(r.GetTrackColor(LT_Track)) end
    TrkClr = ((TrkClr or 0) << 8) | 0x66 -- shift 0x00RRGGBB to 0xRRGGBB00 then add 0xFF for 100% opacity

    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_MenuBarBg(), TrkClr or 0x00000000)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(), Window_BG or CustomColorsDefault.Window_BG)
    --------------------------==  BEGIN GUI----------------------------------------------------------------------------
    local visible, open = r.ImGui_Begin(ctx, 'FX Device', true,
        r.ImGui_WindowFlags_NoScrollWithMouse() + r.ImGui_WindowFlags_NoScrollbar() + r.ImGui_WindowFlags_MenuBar() +
        r.ImGui_WindowFlags_NoCollapse())
    r.ImGui_PopStyleColor(ctx, 2) -- for menu  bar and window BG


    local Viewport = r.ImGui_GetWindowViewport(ctx)

    VP.w, VP.h     = r.ImGui_Viewport_GetSize(Viewport)
    VP.x, VP.y     = r.ImGui_GetCursorScreenPos(ctx)

    ----------------------------------------------------------------------------
    -- ImGUI Variables-----------------------------------------------------------
    ----------------------------------------------------------------------------
    Mods           = r.ImGui_GetKeyMods(ctx)
    Alt            = r.ImGui_ModFlags_Alt()
    Ctrl           = r.ImGui_ModFlags_Ctrl()
    Shift          = r.ImGui_ModFlags_Shift()
    Apl            = r.ImGui_ModFlags_Super()





    if visible then
        VP.w, VP.h = r.ImGui_Viewport_GetSize(Viewport)
        VP.FDL = VP.FDL or r.ImGui_GetForegroundDrawList(ctx)
        VP.X, VP.Y = r.ImGui_GetCursorScreenPos(ctx)

        ----------------- Keyboard Shortcuts ---------------
        if not r.ImGui_IsAnyItemActive(ctx) then
            for i, v in pairs(KB_Shortcut) do
                if not v:find('+') then --if shortcut has no modifier
                    if r.ImGui_IsKeyPressed(ctx, AllAvailableKeys[v]) and Mods == 0 then
                        --[[ local commandID = r.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND')
                        local CommandTxt =  r.CF_GetCommandText(0, commandID) -- 0 prob means arrange window, it's the section drop down from action window's top right corner
                        r.Main_OnCommand(commandID, 0) ]]
                        if Command_ID[i] then
                            local Cmd_Num = r.NamedCommandLookup(Command_ID[i])
                            r.Main_OnCommand(Cmd_Num, 0)
                        end
                    end
                else
                    local Mod = 0
                    if v:find('Shift') then Mod = Mod + r.ImGui_ModFlags_Shift() end
                    if v:find('Alt') then Mod = Mod + r.ImGui_ModFlags_Alt() end
                    if v:find('Ctrl') then Mod = Mod + r.ImGui_ModFlags_Ctrl() end
                    if v:find('Cmd') then Mod = Mod + r.ImGui_ModFlags_Super() end


                    local rev = v:reverse()
                    local lastPlus = rev:find('+')
                    local Ltr = rev:sub(1, rev:find('+') - 2)
                    local AftrLastPlus = Ltr:reverse()


                    if Mods == Mod and r.ImGui_IsKeyPressed(ctx, AllAvailableKeys[AftrLastPlus]) then
                        if Command_ID[i] then
                            local Cmd_Num = r.NamedCommandLookup(Command_ID[i])
                            r.Main_OnCommand(Cmd_Num, 0)
                        end
                    end
                end
            end
        end



        if LT_Track == nil then
            local Viewport = r.ImGui_GetWindowViewport(ctx)

            r.ImGui_DrawList_AddTextEx(VP.FDL, Font_Andale_Mono_20_B, 20, VP.X, VP.Y + VP.h / 2, 0xffffffff,
                'Select a track to start')
        else
            HintMessage = nil
            ------- Add FX ---------
            for i, v in ipairs(AddFX.Name) do
                if v:find('FXD Gain Reduction Scope') then
                    local FxGUID = ProC.GainSc_FXGUID

                    FX[FxGUID] = FX[FxGUID] or {}
                    FX[FxGUID].ProC_ID = math.random(1000000, 9999999)
                    r.gmem_attach('CompReductionScope')
                    r.gmem_write(2002, FX[FxGUID].ProC_ID)
                    r.gmem_write(FX[FxGUID].ProC_ID, AddFX.Pos[i])
                    r.gmem_write(2000, PM.DIY_TrkID[TrkID])
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: ProC_ID ' .. FxGUID, FX[FxGUID].ProC_ID, true)
                elseif v:find('FXD Saike BandSplitter') then
                    r.gmem_attach('FXD_BandSplit')
                    BandSplitID = BandSplitID or math.random(1000000, 9999999)
                    r.gmem_write(0, BandSplitID)
                elseif v:find('FXD Band Joiner') then

                end



                AddFX_HideWindow(LT_Track, v, -1000 - AddFX.Pos[i])
                if v:find('FXD Band Joiner') then
                    local SplittrID = r.TrackFX_GetFXGUID(LT_Track, AddFX.Pos[i] - 1)
                    local JoinerID = r.TrackFX_GetFXGUID(LT_Track, AddFX.Pos[i])
                    FX[SplittrID] = FX[SplittrID] or {}
                    FX[SplittrID].AttachToJoiner = JoinerID
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Splitter\'s Joiner FxID ' .. SplittrID, JoinerID,
                        true)
                elseif v:find('FXD Gain Reduction Scope') then
                    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, AddFX.Pos[i])

                    SyncAnalyzerPinWithFX(AddFX.Pos[i], AddFX.Pos[i] - 1, FX_Name)
                end
            end


            --[[ if AddFX.Name[1] then
                AddFX_HideWindow(LT_Track,AddFX.Name[1],-1000-AddFX.Pos[1])
                table.remove(AddFX.Pos,1)
            end ]]
            AddFX.Name = {}
            AddFX.Pos = {}
            ProC.GainSc_FXGUID = nil

            ----- Del FX ------
            if Sel_Track_FX_Count then
                for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do
                    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx or 0)

                    if FX_Name == 'JS: FXD Gain Reduction Scope' then
                        local _, FX_Name_Before = r.TrackFX_GetFXName(LT_Track, FX_Idx - 1)
                        if string.find(FX_Name_Before, 'Pro%-C 2') == nil then
                            r.TrackFX_Delete(LT_Track, FX_Idx)
                        end
                    end
                    if FX_Name == 'JS: FXD Split to 4 channels' then
                        local _, FX_Name_After = r.TrackFX_GetFXName(LT_Track, FX_Idx + 1)
                        if string.find(FX_Name_After, 'Pro%-C 2') == nil and not AddFX.Name[1] then
                            r.TrackFX_Delete(LT_Track, FX_Idx)
                        end
                        local ProC_pin = r.TrackFX_GetPinMappings(LT_Track, FX_Idx + 1, 0, 0)
                        local SplitPin = r.TrackFX_GetPinMappings(LT_Track, FX_Idx, 0, 0)

                        if ProC_pin ~= SplitPin then
                            r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, 0, ProC_pin, 0) -- input L
                            local R = r.TrackFX_GetPinMappings(LT_Track, FX_Idx + 1, 0, 1)
                            r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, 1, R, 0)        -- input R

                            r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, 0, ProC_pin, 0) -- out L
                            r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, 1, R, 0)        -- out R
                            r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, 2, 2 * R, 0)    -- out L Compare
                            r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, 3, 4 * R, 0)    -- out R Compare
                        end
                    end
                end
            end

            ----- Move FX -----
            if MovFX.FromPos[1] then
                local UndoLbl
                r.Undo_BeginBlock()
                for i, v in ipairs(MovFX.FromPos) do
                    if NeedCopyFX then
                        if v >= DropPos then offset = 1 else offset = 0 end
                        MovFX.ToPos[i] = math.max(MovFX.ToPos[i] - (offset or 0), 0)
                        r.TrackFX_CopyToTrack(LT_Track, v, LT_Track, v, false)
                    end
                end

                for i, v in ipairs(MovFX.FromPos) do
                    r.TrackFX_CopyToTrack(LT_Track, v, LT_Track, MovFX.ToPos[i], true)
                end
                r.Undo_EndBlock(MovFX.Lbl[i] or (UndoLbl or 'Move' .. 'FX'), 0)
                MovFX = { FromPos = {}, ToPos = {}, Lbl = {}, Copy = {} }
                NeedCopyFX = nil
                DropPos = nil
                --[[  MovFX.ToPos = {}
                MovFX.Lbl = {} ]]
            end

            ----- Double click to revert to default value --------
            --[[ if ToDef.ID then
                r.TrackFX_SetParamNormalized(LT_Track,  ToDef.ID , ToDef.P, ToDef.V)
                ToDef={}
            end ]]



            ----- Duplicating FX to Layer -------
            if DragFX_Dest then
                MoveFX(DragFX_Src, DragFX_Src + 1, false)
                DropFXtoLayerNoMove(DroptoRack, DropToLyrID, DragFX_Src)
                MoveFX(DragFX_Src, DragFX_Dest + 1, true)

                DragFX_Src, DragFX_Dest, DropToLyrID = nil
            end






            demo.PushStyle()
            --MouseCursorBusy(true , 'My Window')


            --[[ r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonHovered(), Btns_Hover_DefaultColor)
            r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Button(), Btns_DefaultColor)
            r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonActive(), Btns_ClickedColor)
            r.ImGui_PushStyleColor(ctx,r.ImGui_Col_SliderGrabActive(), Clr.SliderGrab) ]]
            --Clr.poptimes= 4

            r.gmem_attach('ParamValues')
            LT_FXGUID = r.TrackFX_GetFXGUID(LT_Track or r.GetTrack(0, 0), LT_FX_Number or 0)
            TrkID = reaper.GetTrackGUID(LT_Track or r.GetTrack(0, 0))
            Sel_Track_FX_Count = reaper.TrackFX_GetCount(LT_Track)
            LBtnDrag = r.ImGui_IsMouseDragging(ctx, 0)
            LBtnDC = r.ImGui_IsMouseDoubleClicked(ctx, 0)

            _, TrkName = r.GetTrackName(LT_Track)


            if PM.DIY_TrkID[TrkID] == nil then
                PM.DIY_TrkID[TrkID] = math.random(100000000, 999999999)
                r.SetProjExtState(0, 'FX Devices', 'Track GUID Number for jsfx' .. TrkID, PM.DIY_TrkID[TrkID])
            end

            if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_D()) and Mods == Shift + Alt then
                DebugMode = true
            end



            -- if user switch selected track...
            if TrkID ~= TrkID_End then
                if TrkID_End ~= nil and TrkID ~= nil then
                    NumOfTotalTracks = reaper.CountTracks(0)
                    --[[  r.gmem_attach('TrackNameForMacro')
                    reaper .gmem_write(0,NumOfTotalTracks )]]
                end
                for P = 1, Trk.Prm.Inst[TrkID] or 0, 1 do
                    for m = 1, 8, 1 do
                        r.gmem_write(1000 * m + P, 0)
                    end
                end
                RetrieveFXsSavedLayout(Sel_Track_FX_Count)
                SyncTrkPrmVtoActualValue()
                LT_TrackNum = math.floor(r.GetMediaTrackInfo_Value(LT_Track, 'IP_TRACKNUMBER'))
            end

            if RepeatTimeForWindows ~= r.TrackFX_GetCount(LT_Track) then
                RetrieveFXsSavedLayout(Sel_Track_FX_Count)
            end



            ----Functions & Variables -------------
            Glob.FDL = r.ImGui_GetForegroundDrawList(ctx)


            TimeEachFrame = r.ImGui_GetDeltaTime(ctx)
            if ImGUI_Time == nil then ImGUI_Time = 0 end
            ImGUI_Time = ImGUI_Time + TimeEachFrame


            Wheel_V, Wheel_H = reaper.ImGui_GetMouseWheel(ctx)
            LT_Track = reaper.GetLastTouchedTrack()






            IsAnyMouseDown         = reaper.ImGui_IsAnyMouseDown(ctx)

            LBtn_MousdDownDuration = reaper.ImGui_GetMouseDownDuration(ctx, 0)
            LBtnRel                = r.ImGui_IsMouseReleased(ctx, 0)
            RBtnRel                = r.ImGui_IsMouseReleased(ctx, 1)
            if IsLBtnClicked then Max_L_MouseDownDuration = nil end
            if IsLBtnHeld then
                Max_L_MouseDownDuration = math.max(LBtn_MousdDownDuration or -1,
                    Max_L_MouseDownDuration or -1)
            end

            IsRBtnClicked = r.ImGui_IsMouseClicked(ctx, 1)


            if r.ImGui_IsKeyDown(ctx, 49) then -- if number 1 is pressed
                ShowKeyCode = true
            end

            -- if ShowKeyCode then
            if ShowKeyCode then
                for keynum = 0, 300, 1 do --
                    KeyDown = reaper.ImGui_IsKeyDown(ctx, keynum)
                    if KeyDown then
                        tooltip(tostring(keynum))
                    end
                end
            end
            IsLBtnClicked = r.ImGui_IsMouseClicked(ctx, 0)
            LBtnClickCount = r.ImGui_GetMouseClickedCount(ctx, 0)
            IsLBtnHeld = reaper.ImGui_IsMouseDown(ctx, 0)
            IsRBtnHeld = r.ImGui_IsMouseDown(ctx, 1)
            Mods = reaper.ImGui_GetKeyMods(ctx) -- Alt = 4  shift =2  ctrl = 1  Command=8


            -- end

            ----Colors & Font ------------
            --[[ reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), 0xaaaaaa44)
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x474747ff)
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), 0x6e6e6eff) --Use Hex + FF in the end
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(), 0x808080ff)
                reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(), 0x808080ff) ]]
            reaper.ImGui_PushFont(ctx, Font_Andale_Mono)




            ------------------------------
            ------Menu Bar---------------
            ------------------------------



            r.ImGui_BeginMenuBar(ctx)
            BarR, BarB = r.ImGui_GetItemRectMax(ctx)

            if r.ImGui_BeginMenu(ctx, 'Settings') then
                if select(2, r.ImGui_MenuItem(ctx, 'Style Editor', shoirtcutIn, p_selected, enabledIn)) then
                    OpenStyleEditor = toggle(OpenStyleEditor)
                end

                if select(2, r.ImGui_MenuItem(ctx, 'Keyboard Shortcut Editor', shoirtcutIn, p_selected, enabledIn)) then
                    OpenKBEditor = toggle(OpenKBEditor)
                end
                if r.ImGui_GetWindowDockID(ctx) ~= -1 then
                    if select(2, r.ImGui_MenuItem(ctx, 'Dock script', shoirtcutIn, p_selected, enabledIn)) then
                        Dock_Now = true
                    end
                end

                MyText('Version : ' .. VersionNumber, font, 0x777777ff, WrapPosX)
                r.ImGui_EndMenu(ctx)
            end

            if OpenStyleEditor then ShowStyleEditor() end
            if OpenKBEditor then Show_KBShortcutEditor() end
            ------------------------------
            ------Record Last Touch---------------
            ------------------------------

            if r.ImGui_Button(ctx, 'Record Last Touch') then
                GetLTParam()
                local FX_Count = reaper.TrackFX_GetCount(LT_Track); local RptPrmFound
                local F = FX[LT_FXGUID] or {}

                if F then
                    for i, v in ipairs(F) do
                        if FX[LT_FXGUID][i].Num == LT_ParamNum then
                            RptPrmFound = true
                            TryingToAddExistingPrm = i .. LT_FXGUID
                            TimeNow = r.time_precise()
                        end
                    end
                    if not RptPrmFound and LT_FXGUID then
                        StoreNewParam(LT_FXGUID, LT_ParamName, LT_ParamNum, LT_FXNum,
                            true --[[ , nil, #F+1  ]])
                    end
                end
            end

            --[[ if r.ImGui_IsItemClicked(ctx,1) and Cont_Param_Add_Mode==false  then
                    Cont_Param_Add_Mode = true
                    --DeltaTime = reaper.ImGuif_GetDeltaTime(ctx)
                    TimeAfter_ContAdd=0
                    deltatime= reaper.ImGui_GetTime(ctx)

                elseif r.ImGui_IsItemClicked(ctx,1) and  Cont_Param_Add_Mode==true and TimeAfter_ContAdd >10 then
                    TimeAfter_ContAdd=0
                    Cont_Param_Add_Mode = false
                end ]]

            if r.ImGui_IsItemClicked(ctx, 1) then Cont_Param_Add_Mode = toggle(Cont_Param_Add_Mode) end







            if FX.LayEdit then
                local FxGUID = FX.LayEdit
                if #LE.Sel_Items > 1 then
                    SL()
                    if r.ImGui_Button(ctx, 'Align Y-Axis') then
                        for i, v in ipairs(LE.Sel_Items) do FX[FxGUID][v].PosX = FX[FxGUID][LE.Sel_Items[1]].PosX end
                    elseif r.ImGui_Button(ctx, 'Align X-Axis') then
                        for i, v in ipairs(LE.Sel_Items) do FX[FxGUID][v].PosY = FX[FxGUID][LE.Sel_Items[1]].PosY end
                    end
                end
                if #LE.Sel_Items > 2 then
                    if r.ImGui_Button(ctx, 'Equalize X Spacing') then
                        local Spc, max, min
                        local tab = {}
                        for i, v in ipairs(LE.Sel_Items) do
                            table.insert(tab, FX[FxGUID][v].PosX)
                        end

                        max = math.max(table.unpack(tab))
                        min = math.min(table.unpack(tab))
                        Spc = (max - min) / (#LE.Sel_Items - 1)
                        for i, v in ipairs(LE.Sel_Items) do
                            FX[FxGUID][v].PosX = min + Spc * (i - 1)
                        end
                    elseif r.ImGui_Button(ctx, 'Equalize Y Spacing') then
                        local Spc, max, min
                        local tab = {}
                        for i, v in ipairs(LE.Sel_Items) do
                            table.insert(tab, FX[FxGUID][v].PosY)
                        end
                        max = math.max(table.unpack(tab))
                        min = math.min(table.unpack(tab))
                        Spc = (max - min) / (#LE.Sel_Items - 1)
                        for i, v in ipairs(LE.Sel_Items) do
                            FX[FxGUID][v].PosY = min + Spc * (i - 1)
                        end
                    end
                end
            end




            r.ImGui_Text(ctx, TrkName)

            TxtSz = r.ImGui_CalcTextSize(ctx, TrkName)
            r.ImGui_SameLine(ctx, VP.w - TxtSz - 20, nil) --r.ImGui_SetCursorPosX( ctx, BarR-50)




            r.ImGui_EndMenuBar(ctx)




            function DeleteAllParamOfFX(FXGUID, TrkID)
                for p, v in pairs(Trk.Prm.FXGUID) do
                    if Trk.Prm.FXGUID[p] == FXGUID and FXGUID ~= nil then
                        Trk.Prm.Inst[TrkID] = Trk.Prm.Inst[TrkID] - 1
                        Prm.Num[p] = nil
                        PM.HasMod[p] = nil

                        r.SetProjExtState(0, 'FX Devices', 'Params fxGUID of Param Inst' .. p, '')
                    elseif Trk.Prm.FXGUID[p] == nil and FXGUID == nil then

                    end
                end
            end

            if Cont_Param_Add_Mode == true then
                --TimeAfter_ContAdd= TimeAfter_ContAdd+1

                GetLT_FX_Num()
                GetLTParam()
                tooltip('Continuously Adding Last Touched Parameters..')

                local F = FX[LT_FXGUID] or {}; local RptPrmFound
                if LT_FXGUID and type(F) == 'table' then
                    for i, v in ipairs(F) do
                        F[i] = F[i] or {}
                        if F[i].Num == LT_ParamNum then
                            RptPrmFound = true
                            TryingToAddExistingPrm_Cont = i .. LT_FXGUID; TryingToAddExistingPrm = nil
                            TimeNow = r.time_precise()
                        end
                    end
                    if not RptPrmFound then StoreNewParam(LT_FXGUID, LT_ParamName, LT_ParamNum, LT_FXNum, true) end
                end
            else
                TryingToAddExistingPrm_Cont = nil
            end

            local FLT_MIN, FLT_MAX = r.ImGui_NumericLimits_Float()

            ------------------------------
            ------Layout Editing ---------
            ------------------------------


            ------------------Help Tips-------------------




            -----------==  Create Macros (Headers)-------------
            MacroNums = { 1, 2, 3, 4, 5, 6, 7, 8, }
            r.ImGui_BeginTable(ctx, 'table1', 16, r.ImGui_TableFlags_NoPadInnerX())

            Trk[TrkID] = Trk[TrkID] or {}
            Trk[TrkID].Mod = Trk[TrkID].Mod or {}
            for m = 1, 16, 1 do
                if m == 1 or m == 3 or m == 5 or m == 7 or m == 9 or m == 11 or m == 13 or m == 15 then
                    r.ImGui_TableSetupColumn(ctx, '', r.ImGui_TableColumnFlags_WidthStretch(), 2)
                elseif m == 2 or m == 4 or m == 6 or m == 8 or m == 10 or m == 12 or m == 14 or m == 16 then
                    local weight, flag
                    if Trk[TrkID].Mod[m / 2] then
                        if Trk[TrkID].Mod[m / 2].Type == 'Step' then
                            weight, flag = 0,
                                r.ImGui_TableColumnFlags_WidthFixed()
                        end
                    end
                    r.ImGui_TableSetupColumn(ctx, '', flag or r.ImGui_TableColumnFlags_WidthStretch(), weight or 1)
                end
            end

            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(), 0x373737ff)

            reaper.ImGui_TableHeadersRow(ctx) --create header row
            r.gmem_attach('ParamValues')
            ModulatorR, ModulatorB = r.ImGui_GetItemRectMax(ctx)
            Trk[TrkID] = Trk[TrkID] or {}
            Trk[TrkID].Mod = Trk[TrkID].Mod or {}







            for i, v in ipairs(MacroNums) do --Do 8 Times
                Mcro_Asgn_Md_Idx            = 'Macro' .. tostring(MacroNums[i])

                Trk[TrkID].Mod[i]           = Trk[TrkID].Mod[i] or {}
                local I, Name, CurX         = Trk[TrkID].Mod[i], nil, r.ImGui_GetCursorPosX(ctx)
                local frameBgColor          = reaper.ImGui_ColorConvertHSVtoRGB((i - 1) / 7.0, 0.5, 0.5, 0.2)
                local frameBgHoveredColor   = reaper.ImGui_ColorConvertHSVtoRGB((i - 1) / 7.0, 0.6, 0.5, 0.2)
                local frameBgActiveColor    = reaper.ImGui_ColorConvertHSVtoRGB((i - 1) / 7.0, 0.7, 0.5, 0.2)
                local sliderGrabColor       = reaper.ImGui_ColorConvertHSVtoRGB((i - 1) / 7.0, 0.9, 0.9, 0.2)
                local sliderGrabActiveColor = reaper.ImGui_ColorConvertHSVtoRGB((i - 1) / 7.0, 0.9, 0.9, 0.8)
                r.ImGui_PushID(ctx, i)
                local function PushClr(AssigningMacro)
                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), EightColors.LowMidSat[i])
                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(), EightColors.MidSat[i])
                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgActive(), EightColors.Bright[i])
                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_SliderGrab(), EightColors.HighSat_MidBright[i])
                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_SliderGrabActive(), EightColors.Bright_HighSat[i])

                    if AssigningMacro == i then
                        reaper.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), EightColors.HighSat_MidBright[i])
                        reaper.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(), EightColors.bgWhenAsgnModAct[i])
                        PopColorTime = 2
                    end
                    clrPop = 6
                    return PopColorTime
                end



                Trk[TrkID].Mod[i].Type = Trk[TrkID].Mod[i].Type or 'Macro'
                if Trk[TrkID].Mod[i].Type == 'Macro' then
                    PopColorTime = PushClr(AssigningMacro)

                    r.ImGui_TableSetColumnIndex(ctx, (MacroNums[i] - 1) * 2)
                    MacroX_Label = 'Macro' .. tostring(MacroNums[i])


                    MacroValueLBL = TrkID .. 'Macro' .. MacroNums[i]

                    r.ImGui_PushItemWidth(ctx, -FLT_MIN)

                    IsMacroSlidersEdited, I.Val = reaper.ImGui_SliderDouble(ctx, i .. '##', I.Val, Slider1Min or 0,
                        Slider1Max or 1)
                    IsMacroActive = r.ImGui_IsItemActive(ctx)
                    if IsMacroActive == true then Mc.AnyActive = true end
                    R_ClickOnMacroSliders = reaper.ImGui_IsItemClicked(ctx, 1)
                    -- if r.ImGui_IsItemClicked( ctx,1) ==true and Mods==nil then R_ClickOnMacroSliders = true end
                    if r.ImGui_IsItemClicked(ctx, 1) == true and Mods == Ctrl then
                        r.ImGui_OpenPopup(ctx, 'Macro' .. i .. 'Menu')
                    end




                    --- Macro Label
                    reaper.ImGui_TableSetColumnIndex(ctx, MacroNums[i] * 2 - 1)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), EightColors.LowSat[i])
                    r.ImGui_PushItemWidth(ctx, -FLT_MIN)
                    MacroNameEdited, I.Name = reaper.ImGui_InputText(ctx, '##', I.Name or 'Macro ' .. i)
                    if MacroNameEdited then
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro' .. i .. 's Name' .. TrkID, I.Name, true)
                    end

                    if IsMacroActive then
                        if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then
                            r.TrackFX_SetParamNormalized(LT_Track, 0, v - 1, I.Val)
                            r.SetProjExtState(0, 'FX Devices', 'Macro' .. i .. 'Value of Track' .. TrkID, I.Val)
                        end
                    else
                    end


                    if AssigningMacro == i then r.ImGui_PopStyleColor(ctx, PopColorTime) end

                    if R_ClickOnMacroSliders and AssigningMacro == nil and Mods == 0 then
                        AssigningMacro = i
                    elseif R_ClickOnMacroSliders and AssigningMacro ~= nil then
                        AssigningMacro = nil
                    end

                    r.ImGui_PopStyleColor(ctx, clrPop)
                elseif Trk[TrkID].Mod[i].Type == 'env' then
                    if Mods == Shift then DragSpeed = 0.001 else DragSpeed = 0.01 end
                    PopColorTime = PushClr(AssigningMacro)
                    r.ImGui_TableSetColumnIndex(ctx, (i - 1) * 2)
                    r.ImGui_PushItemWidth(ctx, -FLT_MIN)
                    r.ImGui_SetNextItemWidth(ctx, 60)
                    local Mc = Trk[TrkID].Mod[i]

                    local atk, rel = Mc.atk, Mc.rel
                    at, Mc.ATK = r.ImGui_DragDouble(ctx, '## atk' .. i, Mc.ATK, DragSpeed, 0.001, 1, '',
                        r.ImGui_SliderFlags_NoInput())
                    SL(nil, 0)
                    RCat = r.ImGui_IsItemClicked(ctx, 1)
                    local L, T = r.ImGui_GetItemRectMin(ctx)
                    local W, H = r.ImGui_GetItemRectSize(ctx)
                    local R, B = L + W, T + H
                    local Atk = Mc.atk
                    if at then
                        Mc.atk = 0.001 ^ (1 - Mc.ATK)
                        r.gmem_write(4, 2)                      -- tells jsfx user is adjusting atk
                        r.gmem_write(9 + ((i - 1) * 2), Mc.atk) -- tells atk value
                        r.gmem_write(5, i)                      -- tells which macro is being tweaked
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' Atk', Mc.ATK, true)
                    end
                    if r.ImGui_IsItemActive(ctx) then
                        r.ImGui_SetNextWindowPos(ctx, L, T - H - 10)
                        r.ImGui_BeginTooltip(ctx)
                        local f = '%.3f'
                        if Mods == Alt then f = '%.5f' end
                        r.ImGui_Text(ctx, (f):format(Mc.atk or 0.001) * 1000)
                        r.ImGui_EndTooltip(ctx)
                    end
                    local WDL = r.ImGui_GetWindowDrawList(ctx)
                    r.ImGui_DrawList_AddLine(WDL, L + W * Mc.ATK, T, R, T, 0xffffffff)
                    r.ImGui_DrawList_AddLine(WDL, L, B, L + W * Mc.ATK, T, 0xffffffff)

                    if AssigningMacro == i then
                        BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink)
                    end

                    r.ImGui_SetNextItemWidth(ctx, 60)

                    re, Mc.REL  = r.ImGui_DragDouble(ctx, '## rel' .. i, Mc.REL, DragSpeed, 0.001, 1, '',
                        r.ImGui_SliderFlags_NoInput())
                    local RCrel = r.ImGui_IsItemClicked(ctx, 1)
                    if re then
                        --Mc.rel = 10^(rel or 0.001) /10
                        Mc.rel = 0.001 ^ (1 - Mc.REL)
                        r.gmem_write(4, 3)                       -- tells jsfx user is adjusting rel
                        r.gmem_write(10 + ((i - 1) * 2), Mc.rel) -- tells rel value
                        r.gmem_write(5, i)                       -- tells which macro is being tweaked
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' Rel', Mc.REL, true)
                    end
                    if r.ImGui_IsItemActive(ctx) then
                        r.ImGui_SetNextWindowPos(ctx, L, T - H - 30)
                        r.ImGui_BeginTooltip(ctx)
                        r.ImGui_Text(ctx, ('%.3f'):format(Mc.rel or 0.001))
                        r.ImGui_EndTooltip(ctx)
                    end
                    local L, T = r.ImGui_GetItemRectMin(ctx)
                    local W, H = r.ImGui_GetItemRectSize(ctx)
                    local R, B = L + W, T + H
                    local Rel = Mc.rel or 0.001
                    --r.ImGui_DrawList_AddLine(Glob.FDL, L ,T,L+W*Rel,T, 0xffffffff)
                    r.ImGui_DrawList_AddLine(WDL, L, T, L + W * Mc.REL, B, 0xffffffff)
                    if AssigningMacro == i then
                        BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink)
                    end
                    r.ImGui_TableSetColumnIndex(ctx, i * 2 - 1)
                    r.ImGui_PushItemWidth(ctx, -FLT_MIN)
                    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), EightColors.LowSat[i])
                    if I.Name == 'Macro ' .. i then I.Name = 'Env ' .. i end
                    MacroNameEdited, I.Name = reaper.ImGui_InputText(ctx, '##', I.Name or 'Env ' .. i)
                    if MacroNameEdited then
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro' .. i .. 's Name' .. TrkID, I.Name, true)
                    end
                    if (r.ImGui_IsItemClicked(ctx, 1) or RCat or RCrel) and Mods == Ctrl then
                        r.ImGui_OpenPopup(ctx, 'Env' .. i .. 'Menu')
                    end



                    if AssigningMacro == i then r.ImGui_PopStyleColor(ctx, 2) end

                    if (RCat or RCrel) and not AssigningMacro and Mods == 0 then
                        AssigningMacro = i
                    elseif (RCat or RCrel) and AssigningMacro then
                        AssigningMacro = nil
                    end

                    if LBtnREl then
                        for i = 1, 16, 1 do
                            r.gmem_write(8 + i, 0)
                        end
                    end
                    r.ImGui_PopStyleColor(ctx, clrPop)
                elseif Trk[TrkID].Mod[i].Type == 'Step' then
                    Macros_WDL = Macros_WDL or r.ImGui_GetWindowDrawList(ctx)
                    r.ImGui_TableSetColumnIndex(ctx, (i - 1) * 2) --r.ImGui_PushItemWidth( ctx, -FLT_MIN)

                    r.gmem_attach('ParamValues')
                    local CurrentPos       = r.gmem_read(120 + i) + 1

                    --r.ImGui_SetNextItemWidth(ctx, 20)
                    Trk[TrkID].Mod[i].SEQ  = Trk[TrkID].Mod[i].SEQ or {}
                    local S                = Trk[TrkID].Mod[i].SEQ

                    Trk[TrkID].SEQL        = Trk[TrkID].SEQL or {}
                    Trk[TrkID].SEQ_Dnom    = Trk[TrkID].SEQ_Dnom or {}

                    local HoverOnAnyStep
                    local SmallSEQActive
                    local HdrPosL, HdrPosT = r.ImGui_GetCursorScreenPos(ctx)
                    for St = 1, Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, 1 do -- create all steps
                        local W = (VP.w - 10) / 12
                        local L, T = r.ImGui_GetCursorScreenPos(ctx)
                        if St == 1 and AssigningMacro == i then
                            local H = 20
                            local W = (VP.w - 10) / 12
                            BlinkItem(0.3, nil, nil, highlightEdge, EdgeNoBlink, L, T, L + W, T + H, H, W)

                            --HighlightSelectedItem(0xffffff77,0xffffff33, 0, L,T,L+W,T+H,H,W, 1, 1,GetItemRect, Foreground)
                        end
                        --_, S[St]= r.ImGui_DragDouble(ctx, '##SEQ '..St ,  S[St], 0 ,0, 1, ' ',r.ImGui_SliderFlags_NoInput())
                        r.ImGui_InvisibleButton(ctx, '##SEQ' .. St .. TrkID, W / 8, 20)
                        local L, T = r.ImGui_GetItemRectMin(ctx); local R, B = r.ImGui_GetItemRectMax(ctx); local w, h =
                            r.ImGui_GetItemRectSize(ctx)
                        local FillClr = 0x00000000



                        SEQ_Popup_L = SEQ_Popup_L or L
                        SEQ_Popup_T = SEQ_Popup_T or T

                        if r.ImGui_IsMouseHoveringRect(ctx, L, T, R, B) then
                            HoverOnAnyStep = true
                        end
                        if HoverOnAnyStep then WhichMacroIsHovered = i end


                        if r.ImGui_IsItemHovered(ctx) then FillClr = 0xffffff22 end
                        HighlightSelectedItem(FillClr, 0xffffff33, 0, L - 1, T, R - 1, B, h, w, 1, 1, GetItemRect,
                            Foreground)



                        S[St] = SetMinMax(S[St] or 0, 0, 1)
                        if r.ImGui_IsItemActive(ctx) then
                            local _, v = r.ImGui_GetMouseDelta(ctx, nil, nil)

                            if Mods == Shift then DrgSpdMod = 4 end
                            if v ~= 0 then
                                v = v * (-1)
                                if not (S[St] == 1 and v > 0) and not (S[St] == 0 and v < 0) then
                                    S[St] = S[St] + v / 100
                                    r.gmem_write(4, 7)                                   -- tells jsfx user is changing a step's value
                                    r.gmem_write(5, i)                                   -- tells which macro user is tweaking
                                    r.gmem_write(112, SetMinMax(S[St], 0, 1) * (-1) + 1) -- tells the step's value
                                    r.gmem_write(113, St)                                -- tells which step
                                end
                                r.ImGui_ResetMouseDragDelta(ctx)
                            end
                            SmallSEQActive = true
                        elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == 0 then
                            if AssigningMacro then AssigningMacro = nil else AssigningMacro = i end
                        elseif r.ImGui_IsItemDeactivated(ctx) then
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St ..
                                ' Val', S[St], true)
                        end


                        local W, H = r.ImGui_GetItemRectSize(ctx)
                        local Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.5)
                        if r.ImGui_IsItemActive(ctx) then
                            Clr = EightColors.Bright_HighSat[i]
                        elseif r.ImGui_IsItemHovered(ctx) then
                            Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.3)
                        end

                        r.ImGui_DrawList_AddRectFilled(Macros_WDL, L, T + H, L + W - 1, math.max(B - H * (S[St] or 0), T),
                            Clr)
                        if CurrentPos == St then -- if Step SEQ 'playhead' is now on current step
                            r.ImGui_DrawList_AddRect(Macros_WDL, L, T + H, L + W - 1, T, 0xffffff99)
                        end
                        SL(nil, 0)
                        if (r.ImGui_IsItemClicked(ctx, 1)) and Mods == Ctrl then
                            r.ImGui_OpenPopup(ctx, 'Step' .. i .. 'Menu')
                        end
                    end



                    r.ImGui_SetNextWindowPos(ctx, HdrPosL, VP.y - StepSEQ_H - 100)

                    function openSEQWin(Track, i)
                        if r.ImGui_Begin(ctx, 'SEQ Window' .. i, true, r.ImGui_WindowFlags_NoResize() + r.ImGui_WindowFlags_NoDocking() + r.ImGui_WindowFlags_NoCollapse() + r.ImGui_WindowFlags_NoTitleBar() + r.ImGui_WindowFlags_AlwaysAutoResize()) then
                            local WDL = r.ImGui_GetWindowDrawList(ctx)
                            r.ImGui_Text(ctx, 'Sequence Length : ')
                            local function writeSEQDNom()
                                if AddMacroJSFX() then
                                    r.gmem_write(4, 8) --[[tells JSFX user is tweaking seq length or DNom]]
                                    r.gmem_write(5, i) --[[tells JSFX the macro]]
                                    r.gmem_write(111, Trk[TrkID].SEQ_Dnom[i])
                                    r.gmem_write(110, Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps)
                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Denominator',
                                        Trk[TrkID].SEQ_Dnom[i], true)
                                end
                            end

                            local function writeSEQGmem()
                                if AddMacroJSFX() then
                                    r.gmem_write(4, 8)
                                    r.gmem_write(5, i)
                                    r.gmem_write(110, Trk[TrkID].SEQL[i])
                                    r.gmem_write(111, Trk[TrkID].SEQ_Dnom[i] or SEQ_Default_Denom)
                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Length',
                                        Trk[TrkID].SEQL[i], true)
                                end
                            end



                            Trk[TrkID].SEQL        = Trk[TrkID].SEQL or {}
                            rv, Trk[TrkID].SEQL[i] = r.ImGui_SliderInt(ctx, '##' .. 'Macro' .. i .. 'SEQ Length',
                                Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, 2, 64)
                            if r.ImGui_IsItemActive(ctx) then writeSEQGmem() end
                            SL()
                            if r.ImGui_Button(ctx, 'x2##' .. i) then
                                Trk[TrkID].SEQL[i] = math.floor((Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps) * 2)
                                writeSEQGmem()
                            end
                            SL()
                            if r.ImGui_Button(ctx, '/2##' .. i) then
                                Trk[TrkID].SEQL[i] = math.floor((Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps) / 2)
                                writeSEQGmem()
                            end

                            r.ImGui_Text(ctx, 'Step Length : ')
                            if r.ImGui_Button(ctx, '2 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                                Trk[TrkID].SEQ_Dnom[i] = 0.125
                                writeSEQDNom()
                            end
                            if Trk[TrkID].SEQ_Dnom[i] == 0.125 then
                                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T,
                                    R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                            end
                            SL()
                            if r.ImGui_Button(ctx, '1 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                                Trk[TrkID].SEQ_Dnom[i] = 0.25
                                writeSEQDNom()
                            end
                            if Trk[TrkID].SEQ_Dnom[i] == 0.25 then
                                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T,
                                    R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                            end
                            SL()
                            if r.ImGui_Button(ctx, '1/2 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                                Trk[TrkID].SEQ_Dnom[i] = 0.5
                                writeSEQDNom()
                            end
                            if Trk[TrkID].SEQ_Dnom[i] == 0.5 then
                                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T,
                                    R, B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                            end
                            SL()
                            if r.ImGui_Button(ctx, '1/4 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                                Trk[TrkID].SEQ_Dnom[i] = 1
                                writeSEQDNom()
                            end
                            if Trk[TrkID].SEQ_Dnom[i] == 1 then
                                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                    B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                            end
                            SL()
                            if r.ImGui_Button(ctx, '1/8 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                                Trk[TrkID].SEQ_Dnom[i] = 2
                                writeSEQDNom()
                            end
                            if Trk[TrkID].SEQ_Dnom[i] == 2 then
                                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                    B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                            end
                            SL()
                            if r.ImGui_Button(ctx, '1/16 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                                Trk[TrkID].SEQ_Dnom[i] = 4
                                writeSEQDNom()
                            end
                            if Trk[TrkID].SEQ_Dnom[i] == 4 then
                                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                    B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                            end
                            SL()
                            if r.ImGui_Button(ctx, '1/32 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                                Trk[TrkID].SEQ_Dnom[i] = 8
                                writeSEQDNom()
                            end
                            SL()
                            if Trk[TrkID].SEQ_Dnom[i] == 8 then
                                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                    B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                            end
                            if r.ImGui_Button(ctx, '1/64 ##' .. 'Macro' .. i .. 'SEQ Denom') then
                                Trk[TrkID].SEQ_Dnom[i] = 16
                                writeSEQDNom()
                            end
                            if Trk[TrkID].SEQ_Dnom[i] == 16 then
                                HighlightSelectedItem(0xffffff22, 0xffffff77, 0, L, T, R,
                                    B, h, w, H_OutlineSc, V_OutlineSc, 'GetItemRect', Foreground)
                            end



                            for St = 1, Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, 1 do
                                r.ImGui_InvisibleButton(ctx, '##SEQ' .. St .. TrkID, StepSEQ_W, StepSEQ_H)
                                local L, T = r.ImGui_GetItemRectMin(ctx); local R, B = r.ImGui_GetItemRectMax(ctx); local w, h =
                                    r.ImGui_GetItemRectSize(ctx)
                                r.ImGui_DrawList_AddText(WDL, L + StepSEQ_W / 2 / 2, B - 15, 0x999999ff, St)
                                SL(nil, 0)
                                local FillClr = 0x00000000
                                if IsLBtnHeld and r.ImGui_IsMouseHoveringRect(ctx, L, T, R, B) and not SmallSEQActive then
                                    --Calculate Value at Mouse pos
                                    local MsX, MsY = r.ImGui_GetMousePos(ctx)

                                    S[St] = ((B - MsY) / StepSEQ_H) --[[ *(-1) ]]
                                    r.gmem_write(4, 7)                        -- tells jsfx user is changing a step's value
                                    r.gmem_write(5, i)                        -- tells which macro user is tweaking
                                    r.gmem_write(112, SetMinMax(S[St], 0, 1)) -- tells the step's value
                                    r.gmem_write(113, St)                     -- tells which step

                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                        'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St .. ' Val', S[St], true)
                                elseif IsRBtnHeld and r.ImGui_IsMouseHoveringRect(ctx, L, T, R, B) and not SmallSEQActive then
                                    SEQ_RMB_Val = 0
                                    S[St] = SEQ_RMB_Val
                                    r.gmem_write(4, 7)             -- tells jsfx user is changing a step's value
                                    r.gmem_write(5, i)             -- tells which macro user is tweaking
                                    r.gmem_write(112, SEQ_RMB_Val) -- tells the step's value
                                    r.gmem_write(113, St)          -- tells which step
                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                        'P_EXT: Macro ' .. i .. ' SEQ Step = ' .. St .. ' Val', SEQ_RMB_Val, true)
                                end
                                local Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.5)

                                if r.ImGui_IsItemHovered(ctx, r.ImGui_HoveredFlags_RectOnly()) and not SmallSEQActive then
                                    FillClr = 0xffffff22
                                    Clr = Change_Clr_A(EightColors.Bright_HighSat[i], -0.3)
                                end
                                HighlightSelectedItem(FillClr, 0xffffff33, 0, L - 1, T, R - 1, B, h, w, 1, 1, GetItemRect,
                                    Foreground)



                                r.ImGui_DrawList_AddRectFilled(WDL, L, T + StepSEQ_H, L + StepSEQ_W - 1,
                                    math.max(B - StepSEQ_H * (S[St] or 0), T), Clr)

                                if CurrentPos == St then
                                    r.ImGui_DrawList_AddRect(WDL, L, B, L + StepSEQ_W - 1, T, 0xffffff88)
                                end
                            end




                            local x, y = r.ImGui_GetWindowPos(ctx)
                            local w, h = r.ImGui_GetWindowSize(ctx)


                            if r.ImGui_IsMouseHoveringRect(ctx, x, y, x + w, y + h) then notHoverSEQ_Time = 0 end

                            r.ImGui_End(ctx)
                        end
                    end

                    if WhichMacroIsHovered == i and HoverOnAnyStep or SmallSEQActive then
                        openSEQWin(Track, i)
                        notHoverSEQ_Time = 0
                    end

                    if WhichMacroIsHovered == i and not HoverOnAnyStep and not SmallSEQActive then
                        notHoverSEQ_Time = math.min((notHoverSEQ_Time or 0), 11) + 1
                        if notHoverSEQ_Time < 10 then
                            openSEQWin(Track, i)
                        else
                            WhichMacroIsHovered = nil
                            notHoverSEQ_Time = 0
                        end
                    end
                elseif Trk[TrkID].Mod[i].Type == 'Follower' then
                    r.ImGui_TableSetColumnIndex(ctx, (i - 1) * 2)

                    r.ImGui_Text(ctx, 'Follower     ')
                    if r.ImGui_IsItemClicked(ctx, 1) and Mods == Ctrl then
                        r.ImGui_OpenPopup(ctx, 'Follower' .. i .. 'Menu')
                    end
                    function openFollowerWin(Track, i)
                        if r.ImGui_Begin(ctx, 'Follower Window' .. i, true, r.ImGui_WindowFlags_NoResize() + r.ImGui_WindowFlags_NoDocking() + r.ImGui_WindowFlags_NoCollapse() + r.ImGui_WindowFlags_NoTitleBar() + r.ImGui_WindowFlags_AlwaysAutoResize()) then
                            r.ImGui_Text(ctx, 'Smoothness : ')
                            SL()
                            retval, v = r.ImGui_DragDouble(ctx, '##Smoothness', v, 1, 1, 100, formatIn, flagsIn)
                            if r.ImGui_IsItemHovered(ctx) or r.ImGui_IsItemActive(ctx) then
                                HoveringSmoothness = true
                                WhichMacroIsHovered = i
                            else
                                HoveringSmoothness = false
                            end
                            local x, y = r.ImGui_GetWindowPos(ctx)
                            local w, h = r.ImGui_GetWindowSize(ctx)


                            if r.ImGui_IsMouseHoveringRect(ctx, x, y, x + w, y + h) then
                                WhichMacroIsHovered = i
                                notHoverFOL_Time = 0
                                HoveringSmoothness = true
                            end


                            r.ImGui_End(ctx)
                        end
                    end

                    HdrPosL, HdrPosT = r.ImGui_GetCursorScreenPos(ctx)
                    r.ImGui_SetNextWindowPos(ctx, HdrPosL, VP.y - 35)

                    if r.ImGui_IsItemHovered(ctx) or HoveringSmoothness then
                        WhichMacroIsHovered = i

                        openFollowerWin(Track, i)
                        notHoverFOL_Time = 0
                    end
                    if WhichMacroIsHovered == i and not HoveringSmoothness and not r.ImGui_IsItemHovered(ctx) then
                        notHoverFOL_Time = math.min((notHoverFOL_Time or 0), 11) + 1
                        if notHoverFOL_Time < 10 then
                            openFollowerWin(Track, i)
                        else
                            WhichMacroIsHovered = nil
                            notHoverFOL_Time = 0
                        end
                    end
                end




                --check if there's envelope
                --[[  IsThereEnvOnMacro[i] = reaper.GetFXEnvelope(LT_Track, 0, i-1, false)
                    Str_IsThereEnvOnMacro = tostring(IsThereEnvOnMacro[i])
                    if Str_IsThereEnvOnMacro ~= 'nil'  then     --if theres env on macros, Sync Macro on Gui to Actual Values

                        Mc.Val_Trk[MacroValueLBL]= reaper.TrackFX_GetParamNormalized( LT_Track, 0, i-1  )
                        PosX_Left, PosY_Top = reaper.ImGui_GetItemRectMin(ctx)
                        Array_Parameter.PosX_Left[i]=PosX_Left
                        Array_Parameter.PosY_Top[i]=PosY_Top
                        drawlist=reaper.ImGui_GetForegroundDrawList(ctx)
                        MacroColor= 'Macro'..i..'Color'
                        reaper.ImGui_DrawList_AddCircleFilled(drawlist, Array_Parameter.PosX_Left[i], Array_Parameter.PosY_Top[i],4,_G[MacroColor])
                    else IsThereEnvOnMacro[i]=0
                    end ]]
                local function SetTypeToEnv()
                    if r.ImGui_Selectable(ctx, 'Set Type to Envelope') then
                        Trk[TrkID].Mod[i].Type = 'env'
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'env', true)
                        r.gmem_write(4, 4) -- tells jsfx macro type = env
                        r.gmem_write(5, i) -- tells jsfx which macro
                    end
                end

                local function SetTypeToStepSEQ()
                    if r.ImGui_Selectable(ctx, 'Set Type to Step Sequencer') then
                        Trk[TrkID].Mod[i].Type = 'Step'
                        r.gmem_write(4, 6) -- tells jsfx macro type = step seq
                        r.gmem_write(5, i)
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'Step', true)
                        Trk[TrkID].SEQL = Trk[TrkID].SEQL or {}
                        Trk[TrkID].SEQ_Dnom = Trk[TrkID].SEQ_Dnom or {}
                        Trk[TrkID].SEQL[i] = Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps
                        Trk[TrkID].SEQ_Dnom[i] = Trk[TrkID].SEQ_Dnom[i] or SEQ_Default_Denom

                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Length',
                            Trk[TrkID].SEQL[i] or SEQ_Default_Num_of_Steps, true)
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Macro ' .. i .. ' SEQ Denominator',
                            Trk[TrkID].SEQ_Dnom[i] or SEQ_Default_Denom, true)

                        if I.Name == 'Env ' .. i or I.Name == 'Macro ' .. i then I.Name = 'Step ' .. i end
                    end
                end

                local function SetTypeToFollower()
                    if r.ImGui_Selectable(ctx, 'Set Type to Audio Follower') then
                        r.gmem_write(4, 9) -- tells jsfx macro type = Follower
                        r.gmem_write(5, i) -- tells jsfx which macro
                        Trk[TrkID].Mod[i].Type = 'Follower'
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'Follower', true)
                    end
                end
                local function SetTypeToMacro()
                    if r.ImGui_Selectable(ctx, 'Set Type to Macro') then
                        Trk[TrkID].Mod[i].Type = 'Macro'
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: Mod' .. i .. 'Type', 'Macro', true)
                        r.gmem_write(4, 5) -- tells jsfx macro type = Macro
                        r.gmem_write(5, i) -- tells jsfx which macro
                        if I.Name == 'Env ' .. i then I.Name = 'Macro ' .. i end
                    end
                end


                if r.ImGui_BeginPopup(ctx, 'Macro' .. i .. 'Menu') then
                    if r.ImGui_Selectable(ctx, 'Automate') then
                        AddMacroJSFX()
                        -- Show Envelope for Morph Slider
                        local env = r.GetFXEnvelope(LT_Track, 0, i - 1, true)
                        SetPrmAlias(LT_TrackNum, 1, i, Trk[TrkID].Mod[i].Name or ('Macro' .. i)) --don't know what this line does, but without it Envelope won't show....
                        local active, visible, armed, inLane, laneHeight, defaultShape, minValue, maxValue, centerValue, Tp, faderScaling =
                            r.BR_EnvGetProperties(env)
                        r.BR_EnvSetProperties(env, true, true, armed, inLane, laneHeight, defaultShape, faderScaling)
                        r.UpdateArrange()
                        r.ImGui_CloseCurrentPopup(ctx)
                    end
                    SetTypeToEnv()
                    SetTypeToStepSEQ()
                    SetTypeToFollower()
                    r.ImGui_EndPopup(ctx)
                elseif r.ImGui_BeginPopup(ctx, 'Env' .. i .. 'Menu') then
                    SetTypeToMacro()
                    SetTypeToStepSEQ()
                    SetTypeToFollower()
                    r.ImGui_EndPopup(ctx)
                elseif r.ImGui_BeginPopup(ctx, 'Step' .. i .. 'Menu') then
                    SetTypeToMacro()
                    SetTypeToEnv()
                    SetTypeToFollower()
                    r.ImGui_EndPopup(ctx)
                elseif r.ImGui_BeginPopup(ctx, 'Follower' .. i .. 'Menu') then
                    SetTypeToMacro()
                    SetTypeToEnv()
                    SetTypeToStepSEQ()
                    r.ImGui_EndPopup(ctx)
                end


                r.ImGui_PopID(ctx)
            end

            if not FX_Dvs_BgDL then FX_Dvs_BgDL = r.ImGui_GetWindowDrawList(ctx) end
            r.ImGui_PopStyleColor(ctx, 1)
            r.ImGui_EndTable(ctx)
            ---------------End Of header-----------------------

            --[[
            r.gmem_attach('ParamValues')
            TrkID= reaper.GetTrackGUID(LT_Track)

            r.gmem_write(2 ,  PM.DIY_TrkID[TrkID])  ]]
            if ImGUI_Time > 3 then
                CompareFXCount = r.TrackFX_GetCount(LT_Track);
                ImGUI_Time = 0
            end

            if not r.ImGui_IsPopupOpen(ctx, '', r.ImGui_PopupFlags_AnyPopup()) then
                FX_Idx_OpenedPopup = nil
            end



            --------------==  Space between FXs--------------------
            function AddSpaceBtwnFXs(FX_Idx, SpaceIsBeforeRackMixer, AddLastSpace, LyrID, SpcIDinPost, FxGUID_Container,
                                     AdditionalWidth)
                local SpcIsInPre, Hide, SpcInPost, MoveTarget


                if FX_Idx == 0 and r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then FX_Idx = 1 end
                --if FX_Idx == 1 and r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then FX_Idx=FX_Idx-1 else FX_Idx =FX_Idx end
                TblIdxForSpace = FX_Idx .. tostring(SpaceIsBeforeRackMixer)
                FXGUID_To_Check_If_InLayer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                if Trk[TrkID].PreFX[1] then
                    local offset
                    if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then offset = 1 else offset = 0 end
                    if SpaceIsBeforeRackMixer == 'End of PreFX' then
                        SpcIsInPre = true
                        if Trk[TrkID].PreFX_Hide then Hide = true end
                        MoveTarget = FX_Idx + 1
                    elseif FX_Idx + 1 - offset <= #Trk[TrkID].PreFX and SpaceIsBeforeRackMixer ~= 'End of PreFX' then
                        SpcIsInPre = true; if Trk[TrkID].PreFX_Hide then Hide = true end
                    end
                end
                if SpaceIsBeforeRackMixer == 'SpcInPost' or SpaceIsBeforeRackMixer == 'SpcInPost 1st spc' then
                    SpcInPost = true
                    if PostFX_LastSpc == 30 then Dvdr.Spc_Hover[TblIdxForSpace] = 30 end
                end
                local ClrLbl = FX_Idx .. (tostring(SpaceIsBeforeRackMixer) or '')


                Dvdr.Clr[ClrLbl] = Space_Between_FXs
                Dvdr.Width[TblIdxForSpace] = Dvdr.Width[TblIdxForSpace] or 0
                if FX_Idx == 0 and DragDroppingFX and not SpcIsInPre then
                    if r.ImGui_IsMouseHoveringRect(ctx, Cx_LeftEdge + 10, Cy_BeforeFXdevices, Cx_LeftEdge + 25, Cy_BeforeFXdevices + 220) and DragFX_ID ~= 0 then
                        Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width
                    end
                end

                if FX_Idx == RepeatTimeForWindows then
                    Dvdr.Width[TblIdxForSpace] = 15
                end

                if FX_Idx_OpenedPopup == (FX_Idx or 0) .. (tostring(SpaceIsBeforeRackMixer) or '') then
                    Dvdr.Clr[ClrLbl] =
                        Clr.Dvdr.Active
                else
                    Dvdr.Clr[ClrLbl] = Dvdr.Clr[ClrLbl] or Clr.Dvdr.In_Layer
                end

                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), Dvdr.Clr[ClrLbl])

                -- StyleColor For Space Btwn Fx Windows
                if not Hide then
                    if r.ImGui_BeginChildFrame(ctx, '##SpaceBetweenWindows' .. FX_Idx .. tostring(SpaceIsBeforeRackMixer) .. 'Last SPC in Rack = ' .. tostring(AddLastSPCinRack), 10 + Dvdr.Width[TblIdxForSpace] + (Dvdr.Spc_Hover[TblIdxForSpace] or 0) + (AdditionalWidth or 0), 220, r.ImGui_WindowFlags_NoScrollbar()|r.ImGui_WindowFlags_NoScrollWithMouse()|r.ImGui_WindowFlags_NoNavFocus()|r.ImGui_WindowFlags_NoNav()) then
                        --HOVER_RECT = reaper.ImGui_IsWindowHovered(ctx,  reaper.ImGui_HoveredFlags_RectOnly())
                        HoverOnWindow = r.ImGui_IsWindowHovered(ctx, r.ImGui_HoveredFlags_AllowWhenBlockedByActiveItem())

                        if HoverOnWindow == true and Dragging_TrueUntilMouseUp ~= true and DragDroppingFX ~= true and AssignWhichParam == nil and Is_ParamSliders_Active ~= true and Wet.ActiveAny ~= true and Knob_Active ~= true and not Dvdr.JustDroppedFX and LBtn_MousdDownDuration < 0.2 then
                            Dvdr.Spc_Hover[TblIdxForSpace] = Df.Dvdr_Hvr_W
                            if DebugMode then
                                tooltip('FX_Idx :' ..
                                    FX_Idx ..
                                    '\n Pre/Post/Norm : ' ..
                                    tostring(SpaceIsBeforeRackMixer) .. '\n SpcIDinPost: ' .. tostring(SpcIDinPost))
                            end
                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), CLR_BtwnFXs_Btn_Hover)
                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), CLR_BtwnFXs_Btn_Active)
                            local x, y = r.ImGui_GetCursorScreenPos(ctx)
                            r.ImGui_SetCursorScreenPos(ctx, x, Glob.WinT)
                            BTN_Btwn_FXWindows = r.ImGui_Button(ctx, '##Button between Windows', 99, 217)
                            FX_Insert_Pos = FX_Idx

                            if BTN_Btwn_FXWindows then
                                FX_Idx_OpenedPopup = FX_Idx .. (tostring(SpaceIsBeforeRackMixer) or '')

                                r.ImGui_OpenPopup(ctx, 'Btwn FX Windows' .. FX_Idx)
                            end
                            r.ImGui_PopStyleColor(ctx, 2)
                            Dvdr.RestoreNormWidthWait[FX_Idx] = 0
                        else
                            Dvdr.RestoreNormWidthWait[FX_Idx] = (Dvdr.RestoreNormWidthWait[FX_Idx] or 0) + 1
                            if Dvdr.RestoreNormWidthWait[FX_Idx] >= 8 then
                                Dvdr.Spc_Hover[TblIdxForSpace] = Dvdr_Hvr_W
                                Dvdr.RestoreNormWidthWait[FX_Idx] = 0
                            end
                        end



                        if HoverOnWindow then
                            -- tooltip ('fx idx = ' .. tostring (FX_Idx) .. 'space is before mixer- '.. tostring (SpaceIsBeforeRackMixer).. 'AddLastSPCinRack - '.. tostring(AddLastSPCinRack))
                        end

                        if r.ImGui_BeginPopup(ctx, 'Btwn FX Windows' .. FX_Idx) then
                            FX_Idx_OpenedPopup = FX_Idx .. (tostring(SpaceIsBeforeRackMixer) or '')

                            FilterBox(FX_Idx, LyrID, SpaceIsBeforeRackMixer, FxGUID_Container, SpcIsInPre, SpcInPost,
                                SpcIDinPost) -- Add FX Window
                            if r.ImGui_Selectable(ctx, 'Add FX Layering') then
                                local FX_Idx = FX_Idx
                                --[[ if FX_Name:find('Pro%-C 2') then FX_Idx = FX_Idx-1 end ]]
                                local val = r.SNM_GetIntConfigVar("fxfloat_focus", 0)
                                if val & 4 ~= 0 then
                                    r.SNM_SetIntConfigVar("fxfloat_focus", val & (~4))
                                end

                                if r.GetMediaTrackInfo_Value(LT_Track, 'I_NCHAN') < 16 then
                                    r.SetMediaTrackInfo_Value(LT_Track, 'I_NCHAN', 16)
                                end
                                FXRack = r.TrackFX_AddByName(LT_Track, 'FXD (Mix)RackMixer', 0, -1000 - FX_Idx)
                                local RackFXGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

                                ChanSplitr = r.TrackFX_AddByName(LT_Track, 'FXD Split to 32 Channels', 0, -1000 - FX_Idx)
                                local SplitrGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                                Lyr.SplitrAttachTo[SplitrGUID] = RackFXGUID
                                r.SetProjExtState(0, 'FX Devices', 'SplitrAttachTo' .. SplitrGUID, RackFXGUID)
                                _, ChanSplitFXName = r.TrackFX_GetFXName(LT_Track, FX_Idx - 1)

                                FX[RackFXGUID] = FX[RackFXGUID] or {}
                                FX[RackFXGUID].LyrID = FX[RackFXGUID].LyrID or {}
                                table.insert(FX[RackFXGUID].LyrID, 1)
                                table.insert(FX[RackFXGUID].LyrID, 2)

                                r.SetProjExtState(0, 'FX Devices', 'FX' .. RackFXGUID .. 'Layer ID 1', 1)
                                r.SetProjExtState(0, 'FX Devices', 'FX' .. RackFXGUID .. 'Layer ID 2', 2)
                                FX[RackFXGUID].ActiveLyrCount = 2

                                FX_Layr_Inst = 0
                                for F = 0, Sel_Track_FX_Count, 1 do
                                    local FXGUID = r.TrackFX_GetFXGUID(LT_Track, F)
                                    local _, FX_Name = reaper.TrackFX_GetFXName(LT_Track, F)
                                    if string.find(FX_Name, 'FXD Split to 32 Channels') ~= nil then
                                        FX_Layr_Inst                       = FX_Layr_Inst + 1
                                        Lyr.SpltrID[FX_Layr_Inst .. TrkID] = r.TrackFX_GetFXGUID(LT_Track, FX_Idx - 1)
                                    end
                                end

                                Spltr[SplitrGUID] = Spltr[SplitrGUID] or {}
                                Spltr[SplitrGUID].New = true


                                if FX_Layr_Inst == 1 then
                                    --sets input channels to 1 and 2
                                    r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 0, 0, 1, 0)
                                    r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 0, 1, 2, 0)
                                    r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 0, 2, 1, 0)
                                    r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 0, 3, 2, 0)
                                    for i = 2, 16, 1 do
                                        r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 0, i, 0, 0)
                                    end
                                    --sets Output to all channels
                                    r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 1, 0, 21845, 0)
                                    r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 1, 1, 43690, 0)
                                    for i = 2, 16, 1 do
                                        r.TrackFX_SetPinMappings(LT_Track, FX_Idx - 1, 1, i, 0, 0)
                                    end
                                elseif FX_Layr_Inst > 1 then

                                end




                                FX_Idx_OpenedPopup = nil
                                r.ImGui_CloseCurrentPopup(ctx)
                                if val & 4 ~= 0 then
                                    reaper.SNM_SetIntConfigVar("fxfloat_focus", val|4) -- re-enable Auto-float
                                end
                            elseif r.ImGui_Selectable(ctx, 'Add Band Split') then
                                r.gmem_attach('FXD_BandSplit')
                                table.insert(AddFX.Name, 'FXD Saike BandSplitter')
                                table.insert(AddFX.Pos, FX_Idx)
                                table.insert(AddFX.Name, 'FXD Band Joiner')
                                table.insert(AddFX.Pos, FX_Idx + 1)
                                if r.GetMediaTrackInfo_Value(LT_Track, 'I_NCHAN') < 12 then -- Set track channels to 10 if it's lower than 10
                                    r.SetMediaTrackInfo_Value(LT_Track, 'I_NCHAN', 12)
                                end

                                FX_Idx_OpenedPopup = nil
                                --r.TrackFX_AddByName(LT_Track, 'FXD Bandjoiner', 0, -1000-FX_Idx)
                            end


                            Dvdr.Spc_Hover[TblIdxForSpace] = Dvdr_Hvr_W
                            --Dvdr.Clr[ClrLbl] = 0x999999ff

                            if IsLBtnClicked then FX_Idx_OpenedPopup = nil end
                            r.ImGui_EndPopup(ctx)
                        else
                            Dvdr.Clr[ClrLbl] = 0x131313ff
                        end


                        reaper.ImGui_EndChildFrame(ctx)
                    end
                end
                r.ImGui_PopStyleColor(ctx)
                local FXGUID_FX_Idx = r.TrackFX_GetFXGUID(LT_Track, FX_Idx - 1)

                function MoveFX(DragFX_ID, FX_Idx, isMove, AddLastSpace)
                    local AltDest, AltDestLow, AltDestHigh, DontMove

                    if SpcInPost then SpcIsInPre = false end

                    if SpcIsInPre then
                        if not tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]) then -- if fx is not in pre fx
                            if SpaceIsBeforeRackMixer == 'End of PreFX' then
                                table.insert(Trk[TrkID].PreFX, #Trk[TrkID].PreFX + 1, FXGUID[DragFX_ID])
                                r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, FX_Idx + 1, true)
                                DontMove = true
                            else
                                table.insert(Trk[TrkID].PreFX, FX_Idx + 1, FXGUID[DragFX_ID])
                            end
                        else -- if fx is in pre fx
                            local offset = 0
                            if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then offset = -1 end
                            if FX_Idx < DragFX_ID then -- if drag towards left
                                table.remove(Trk[TrkID].PreFX, DragFX_ID + 1 + offset)
                                table.insert(Trk[TrkID].PreFX, FX_Idx + 1 + offset, FXGUID[DragFX_ID])
                            elseif SpaceIsBeforeRackMixer == 'End of PreFX' then
                                table.insert(Trk[TrkID].PreFX, #Trk[TrkID].PreFX + 1, FXGUID[DragFX_ID])
                                table.remove(Trk[TrkID].PreFX, DragFX_ID + 1 + offset)
                                --move fx down
                            else
                                table.insert(Trk[TrkID].PreFX, FX_Idx + 1 + offset, FXGUID[DragFX_ID])
                                table.remove(Trk[TrkID].PreFX, DragFX_ID + 1 + offset)
                            end
                        end

                        for i, v in pairs(Trk[TrkID].PreFX) do
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' ..
                                i, v, true)
                        end
                        if tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]) then
                            table.remove(Trk[TrkID].PostFX, tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]))
                        end
                        FX.InLyr[FXGUID[DragFX_ID]] = nil
                    elseif SpcInPost then
                        local offset

                        if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then offset = -1 else offset = 0 end

                        if not tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]) then -- if fx is not yet in post-fx chain
                            InsertToPost_Src = DragFX_ID + offset + 1

                            InsertToPost_Dest = SpcIDinPost


                            if tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]) then
                                table.remove(Trk[TrkID].PreFX, tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]))
                            end
                        else                                -- if fx is already in post-fx chain
                            local IDinPost = tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID])
                            if SpcIDinPost <= IDinPost then -- if drag towards left
                                table.remove(Trk[TrkID].PostFX, IDinPost)
                                table.insert(Trk[TrkID].PostFX, SpcIDinPost, FXGUID[DragFX_ID])
                                table.insert(MovFX.ToPos, FX_Idx + 1)
                            else
                                table.insert(Trk[TrkID].PostFX, SpcIDinPost, Trk[TrkID].PostFX[IDinPost])
                                table.remove(Trk[TrkID].PostFX, IDinPost)
                                table.insert(MovFX.ToPos, FX_Idx)
                            end
                            DontMove = true
                            table.insert(MovFX.FromPos, DragFX_ID)
                        end
                        FX.InLyr[FXGUID[DragFX_ID]] = nil
                    else -- if space is not in pre or post
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. DragFX_ID, '', true)
                        if not MoveFromPostToNorm then
                            if tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]) then
                                table.remove(Trk[TrkID].PreFX,
                                    tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]))
                            end
                        end
                        if tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]) then
                            table.remove(Trk[TrkID].PostFX,
                                tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]))
                        end
                    end
                    for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '', true)
                    end
                    for i = 1, #Trk[TrkID].PreFX + 1, 1 do
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, Trk[TrkID].PreFX[i] or '', true)
                    end
                    if not DontMove then
                        if FX_Idx ~= RepeatTimeForWindows and SpaceIsBeforeRackMixer ~= 'End of PreFX' then
                            --[[ if ((FX.Win_Name_S[FX_Idx]or''):find('Pro%-Q 3') or (FX.Win_Name_S[FX_Idx]or''):find('Pro%-C 2')) and not tablefind (Trk[TrkID].PreFX, FXGUID[FX_Idx]) then
                                AltDestLow = FX_Idx-1
                            end ]]
                            if (FX.Win_Name_S[FX_Idx] or ''):find('Pro%-C 2') then
                                AltDestHigh = FX_Idx - 1
                            end
                            FX_Idx = tonumber(FX_Idx)
                            DragFX_ID = tonumber(DragFX_ID)

                            if FX_Idx > DragFX_ID then offset = 1 end


                            table.insert(MovFX.ToPos, AltDestLow or FX_Idx - (offset or 0))
                            table.insert(MovFX.FromPos, DragFX_ID)
                        elseif FX_Idx == RepeatTimeForWindows and AddLastSpace == 'LastSpc' or SpaceIsBeforeRackMixer == 'End of PreFX' then
                            local offset

                            if Trk[TrkID].PostFX[1] then offset = #Trk[TrkID].PostFX end
                            table.insert(MovFX.ToPos, FX_Idx - (offset or 0))
                            table.insert(MovFX.FromPos, DragFX_ID)
                        else
                            table.insert(MovFX.ToPos, FX_Idx - (offset or 0))
                            table.insert(MovFX.FromPos, DragFX_ID)
                        end
                    end
                    if isMove == false then
                        NeedCopyFX = true
                        DropPos = FX_Idx
                    end
                end

                function MoveFXwith1PreFXand1PosFX(DragFX_ID, FX_Idx, Undo_Lbl)
                    r.Undo_BeginBlock()
                    table.remove(Trk[TrkID].PreFX, tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]))
                    for i = 1, #Trk[TrkID].PreFX + 1, 1 do
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, Trk[TrkID].PreFX[i] or '', true)
                    end
                    table.remove(Trk[TrkID].PostFX, tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]))
                    for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '', true)
                    end
                    if FX_Idx ~= RepeatTimeForWindows then
                        if DragFX_ID > FX_Idx then
                            table.insert(MovFX.FromPos, DragFX_ID)
                            table.insert(MovFX.ToPos, FX_Idx)
                            table.insert(MovFX.FromPos, DragFX_ID)
                            table.insert(MovFX.ToPos, FX_Idx)
                            table.insert(MovFX.FromPos, DragFX_ID + 1)
                            table.insert(MovFX.ToPos, FX_Idx + 2)


                            --[[ r.TrackFX_CopyToTrack( LT_Track, DragFX_ID, LT_Track, FX_Idx, true )
                            r.TrackFX_CopyToTrack( LT_Track, DragFX_ID, LT_Track, FX_Idx, true )
                            r.TrackFX_CopyToTrack( LT_Track, DragFX_ID+1, LT_Track, FX_Idx+2, true ) ]]
                        elseif FX_Idx > DragFX_ID then
                            table.insert(MovFX.FromPos, DragFX_ID)
                            table.insert(MovFX.ToPos, FX_Idx - 1)
                            table.insert(MovFX.FromPos, DragFX_ID - 1)
                            table.insert(MovFX.ToPos, FX_Idx - 2)
                            table.insert(MovFX.FromPos, DragFX_ID - 1)
                            table.insert(MovFX.ToPos, FX_Idx - 1)

                            --[[ r.TrackFX_CopyToTrack( LT_Track, DragFX_ID, LT_Track, FX_Idx-1 , true )
                            r.TrackFX_CopyToTrack( LT_Track, DragFX_ID-1, LT_Track, FX_Idx-2 , true )
                            r.TrackFX_CopyToTrack( LT_Track, DragFX_ID-1, LT_Track, FX_Idx-1 , true ) ]]
                        end
                    else
                        if AddLastSpace == 'LastSpc' then
                            r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, FX_Idx, true)
                            r.TrackFX_CopyToTrack(LT_Track, DragFX_ID - 1, LT_Track, FX_Idx - 2, true)
                        end
                    end
                    r.Undo_EndBlock(Undo_Lbl, 0)
                end

                function MoveFXwith1PreFX(DragFX_ID, FX_Idx, Undo_Lbl)
                    r.Undo_BeginBlock()
                    if FX_Idx ~= RepeatTimeForWindows then
                        if payload > FX_Idx then
                            r.TrackFX_CopyToTrack(LT_Track, payload, LT_Track, FX_Idx, true)
                            r.TrackFX_CopyToTrack(LT_Track, payload, LT_Track, FX_Idx, true)
                        elseif FX_Idx > payload then
                            r.TrackFX_CopyToTrack(LT_Track, payload, LT_Track, FX_Idx - 1, true)
                            r.TrackFX_CopyToTrack(LT_Track, payload - 1, LT_Track, FX_Idx - 2, true)
                        end
                    else
                        if AddLastSpace == 'LastSpc' then
                            r.TrackFX_CopyToTrack(LT_Track, payload, LT_Track, FX_Idx, true)
                            r.TrackFX_CopyToTrack(LT_Track, payload - 1, LT_Track, FX_Idx - 2, true)
                        end
                    end
                    r.Undo_EndBlock(Undo_Lbl, 0)
                end

                ---  if the space is in FX layer
                if FX.InLyr[FXGUID_To_Check_If_InLayer] == FXGUID_RackMixer and SpaceIsBeforeRackMixer == false or AddLastSPCinRack == true then
                    Dvdr.Clr[ClrLbl] = Clr.Dvdr.In_Layer
                    FXGUID_of_DraggingFX = r.TrackFX_GetFXGUID(LT_Track, DragFX_ID or 0)

                    if DragFX_ID == FX_Idx or DragFX_ID == FX_Idx - 1 and FX.InLyr[FXGUID_of_DraggingFX] == FXGUID[FX_Idx] then
                        Dvdr.Width[TblIdxForSpace] = 0
                    else
                        if r.ImGui_BeginDragDropTarget(ctx) then
                            FxDroppingTo = FX_Idx
                            ----- Drag Drop FX -------
                            dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                            if FxGUID == FXGUID[DragFX_ID] then
                                Dvdr.Width[TblIdxForSpace] = 0
                            else
                                Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width
                            end

                            r.ImGui_SameLine(ctx, 100, 10)


                            if dropped and Mods == 0 then
                                DropFXtoLayer(FX_Idx, LyrID)
                                Dvdr.Width[TblIdxForSpace] = 0
                                FxDroppingTo = nil
                            elseif dropped and Mods == Apl then
                                DragFX_Src = DragFX_ID

                                if DragFX_ID > FX_Idx then DragFX_Dest = FX_Idx - 1 else DragFX_Dest = FX_Idx end
                                DropToLyrID = LyrID
                                DroptoRack = FXGUID_RackMixer
                                --MoveFX(DragFX_Src, DragFX_Dest ,false )

                                Dvdr.Width[TblIdxForSpace] = 0
                                FxDroppingTo = nil
                            end
                            ----------- Add FX ---------------
                            if Payload_Type == 'AddFX_Sexan' then
                                AddFX_Sexan()
                            end

                            r.ImGui_EndDragDropTarget(ctx)
                        else
                            Dvdr.Width[TblIdxForSpace] = 0
                            FxDroppingTo = nil
                        end
                    end
                    r.ImGui_SameLine(ctx, 100, 10)
                elseif SpaceIsBeforeRackMixer == 'SpcInBS' then
                    if DragFX_ID == FX_Idx or DragFX_ID == FX_Idx - 1 and FX.InLyr[FXGUID_of_DraggingFX] == FXGUID[FX_Idx] then
                        Dvdr.Width[TblIdxForSpace] = 0
                    else
                        if r.ImGui_BeginDragDropTarget(ctx) then
                            FxDroppingTo = FX_Idx
                            dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                            if FxGUID == FXGUID[DragFX_ID] then
                                Dvdr.Width[TblIdxForSpace] = 0
                            else
                                Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width
                            end

                            r.ImGui_SameLine(ctx, 100, 10)
                            local ContainerIdx = tablefind(FXGUID, FxGUID_Container)
                            local InsPos = math.min(FX_Idx - ContainerIdx + 1, #FX[FxGUID_Container].FXsInBS)


                            if dropped and Mods == 0 then
                                local ContainerIdx = tablefind(FXGUID, FxGUID_Container)
                                local InsPos = SetMinMax(FX_Idx - ContainerIdx + 1, 1, #FX[FxGUID_Container].FXsInBS)



                                DropFXintoBS(FXGUID[DragFX_ID], FxGUID_Container, FX[FxGUID_Container].Sel_Band,
                                    DragFX_ID, FX_Idx, 'DontMove')
                                Dvdr.Width[TblIdxForSpace] = 0
                                FxDroppingTo = nil

                                MoveFX(Payload, FX_Idx + 1, true)
                            elseif dropped and Mods == Apl then
                                DragFX_Src = DragFX_ID

                                if DragFX_ID > FX_Idx then DragFX_Dest = FX_Idx - 1 else DragFX_Dest = FX_Idx end
                                DropToLyrID = LyrID
                                DroptoRack = FXGUID_RackMixer
                                --MoveFX(DragFX_Src, DragFX_Dest ,false )

                                Dvdr.Width[TblIdxForSpace] = 0
                                FxDroppingTo = nil
                            end
                            -- Add from Sexan Add FX
                            if Payload_Type == 'AddFX_Sexan' then
                                AddFX_Sexan(FX_Idx)
                            end

                            r.ImGui_EndDragDropTarget(ctx)
                        else
                            Dvdr.Width[TblIdxForSpace] = 0
                            FxDroppingTo = nil
                        end
                    end
                else -- if Space is not in FX Layer
                    function MoveFX_Out_Of_BS()
                        for i = 0, Sel_Track_FX_Count - 1, 1 do
                            if FX[FXGUID[i]].FXsInBS then -- i is Band Splitter
                                table.remove(FX[FXGUID[i]].FXsInBS, tablefind(FX[FXGUID[i]].FXsInBS, FXGUID[DragFX_ID]))
                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which BS' .. FXGUID[DragFX_ID],
                                    '', true)
                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which Band' .. FXGUID
                                    [DragFX_ID], '', true)
                            end
                        end
                        FX[FXGUID[DragFX_ID]].InWhichBand = nil
                    end

                    if r.ImGui_BeginDragDropTarget(ctx) then
                        if Payload_Type == 'FX_Drag' then
                            local allowDropNext, MoveFromPostToNorm, DontAllowDrop
                            local FX_Idx = FX_Idx
                            if Mods == Apl then allowDropNext = true end



                            if tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]) and (not SpcIsInPre or SpaceIsBeforeRackMixer == 'End of PreFX') then allowDropNext = true end
                            if tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]) and (not SpcInPost or AddLastSpace == 'LastSpc') then
                                allowDropNext = true; MoveFromPostToNorm = true
                            end
                            if FX[FXGUID[DragFX_ID]].InWhichBand then allowDropNext = true end
                            if not FX[FXGUID[DragFX_ID]].InWhichBand and SpaceIsBeforeRackMixer == 'SpcInBS' then allowDropNext = true end
                            --[[  if (FX.Win_Name_S[DragFX_ID]or''):find('Pro%-C 2') then
                                FX_Idx = FX_Idx-1
                                if (DragFX_ID  == FX_Idx +1) or (DragFX_ID == FX_Idx-1)  then DontAllowDrop = true end
                            end  ]]

                            if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) ~= -1 then offset = 0 else offset = 0 end

                            if (DragFX_ID + offset == FX_Idx or DragFX_ID + offset == FX_Idx - 1) and SpaceIsBeforeRackMixer ~= true and FX.InLyr[FXGUID[DragFX_ID]] == nil and not SpcInPost and not allowDropNext
                                or (Trk[TrkID].PreFX[#Trk[TrkID].PreFX] == FXGUID[DragFX_ID] and SpaceIsBeforeRackMixer == 'End of PreFX') or DontAllowDrop then
                                r.ImGui_SameLine(ctx, nil, 0)

                                Dvdr.Width[TblIdxForSpace] = 0
                                r.ImGui_EndDragDropTarget(ctx)
                            else
                                HighlightSelectedItem(0xffffff22, nil, 0, L, T, R, B, h, w, 0, 0, 'GetItemRect',
                                    Foreground)


                                Dvdr.Clr[ClrLbl] = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_Button())
                                Dvdr.Width[TblIdxForSpace] = Df.Dvdr_Width

                                dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                                FXGUID_To_Check_If_InLayer = r.TrackFX_GetFXGUID(LT_Track, DragFX_ID)
                                if dropped and Mods == 0 then
                                    payload = tonumber(payload)
                                    r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 0, 0, 1, 0)
                                    r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 0, 1, 2, 0)

                                    r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 1, 0, 1, 0)
                                    r.TrackFX_SetPinMappings(LT_Track, DragFX_ID, 1, 1, 2, 0)


                                    if FX.Win_Name_S[payload]:find('Pro%-Q 3') and not tablefind(Trk[TrkID].PostFX, FXGUID[payload]) and not SpcInPost and not SpcIsInPre and not tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]) then
                                        MoveFXwith1PreFX(DragFX_ID, FX_Idx, 'Move Pro-Q 3 and it\'s analyzer')
                                        --[[ elseif FX.Win_Name_S[payload]:find('Pro%-C 2') and not tablefind(Trk[TrkID].PostFX, FXGUID[payload])and not SpcInPost and not SpcIsInPre then
                                        MoveFXwith1PreFXand1PosFX(DragFX_ID,FX_Idx, 'Move Pro-C 2 and it\'s analyzer') ]]
                                    else
                                        MoveFX(payload, FX_Idx, true, nil)
                                    end

                                    -- Move FX Out of BandSplit
                                    if FX[FXGUID[DragFX_ID]].InWhichBand then
                                        for i = 0, Sel_Track_FX_Count - 1, 1 do
                                            if FX[FXGUID[i]].FXsInBS then -- i is Band Splitter
                                                table.remove(FX[FXGUID[i]].FXsInBS,
                                                    tablefind(FX[FXGUID[i]].FXsInBS, FXGUID[DragFX_ID]))
                                                r.GetSetMediaTrackInfo_String(LT_Track,
                                                    'P_EXT: FX is in which BS' .. FXGUID[DragFX_ID], '', true)
                                                r.GetSetMediaTrackInfo_String(LT_Track,
                                                    'P_EXT: FX is in which Band' .. FXGUID[DragFX_ID], '', true)
                                            end
                                        end
                                        FX[FXGUID[DragFX_ID]].InWhichBand = nil
                                    end


                                    -- Move FX Out of Layer
                                    if Lyr.FX_Ins[FX.InLyr[FXGUID_To_Check_If_InLayer]] ~= nil then
                                        Lyr.FX_Ins[FX.InLyr[FXGUID_To_Check_If_InLayer]] = Lyr.FX_Ins
                                            [FX.InLyr[FXGUID_To_Check_If_InLayer]] - 1
                                    end
                                    r.SetProjExtState(0, 'FX Devices',
                                        'FXLayer - ' .. 'is FX' .. FXGUID_To_Check_If_InLayer .. 'in layer', "")
                                    FX.InLyr[FXGUID_To_Check_If_InLayer] = nil
                                    Dvdr.JustDroppedFX = true
                                elseif dropped and Mods == Apl then
                                    local copypos = FX_Idx + 1
                                    payload = tonumber(payload)

                                    if FX_Idx == 0 then copypos = 0 end
                                    MoveFX(payload, copypos, false)
                                end
                                r.ImGui_SameLine(ctx, nil, 0)
                            end
                        elseif Payload_Type == 'FX Layer Repositioning' then -- FX Layer Repositioning
                            local FXGUID_RackMixer = r.TrackFX_GetFXGUID(LT_Track, DragFX_ID)

                            local lyrFxInst
                            if Lyr[FXGUID_RackMixer] then
                                lyrFxInst = Lyr[FXGUID_RackMixer].HowManyFX
                            else
                                lyrFxInst = 0
                            end


                            if (DragFX_ID - (math.max(lyrFxInst, 1)) <= FX_Idx and FX_Idx <= DragFX_ID + 1) or DragFX_ID - lyrFxInst == FX_Idx then
                                DontAllowDrop = true
                                reaper.ImGui_SameLine(ctx, nil, 0)
                                Dvdr.Width[TblIdxForSpace] = 0
                                r.ImGui_EndDragDropTarget(ctx)

                                --[[  ]]
                                Dvdr.Width[FX_Idx] = 0
                            else --if dragging to an adequate space
                                Dvdr.Clr[ClrLbl] = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_Button())
                                dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX Layer Repositioning')
                                Dvdr.Width[TblIdxForSpace] = 30

                                if dropped then
                                    RepositionFXsInContainer(FX_Idx)
                                    --r.Undo_EndBlock('Undo for moving FX layer',0)
                                end
                            end
                        elseif Payload_Type == 'BS_Drag' then
                            local Pl = tonumber(Payload)


                            if SpaceIsBeforeRackMixer == 'SpcInBS' or FX_Idx == Pl or Pl + (#FX[FXGUID[Pl]].FXsInBS or 0) + 2 == FX_Idx then
                                Dvdr.Width[TblIdxForSpace] = 0
                            else
                                dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'BS_Drag')
                                Dvdr.Width[TblIdxForSpace] = 30
                                if dropped then
                                    RepositionFXsInContainer(FX_Idx, Payload)
                                end
                            end
                        elseif Payload_Type == 'AddFX_Sexan' then
                            AddFX_Sexan()
                            r.ImGui_EndDragDropTarget(ctx)
                        end
                    else
                        Dvdr.Width[TblIdxForSpace] = 0
                        Dvdr.Clr[ClrLbl] = 0x131313ff
                        reaper.ImGui_SameLine(ctx, nil, 0)
                    end
                    r.ImGui_SameLine(ctx, nil, 0)
                end
                return 10 + Dvdr.Width[TblIdxForSpace] + (Dvdr.Spc_Hover[TblIdxForSpace] or 0)
            end

            RepeatTimeForWindows = Sel_Track_FX_Count

            MaxX, MaxY = reaper.ImGui_GetContentRegionMax(ctx)
            framepadding = reaper.ImGui_StyleVar_FramePadding()
            BorderSize = reaper.ImGui_StyleVar_FrameBorderSize()
            FrameRounding = reaper.ImGui_StyleVar_FrameRounding()
            BtnTxtAlign = reaper.ImGui_StyleVar_ButtonTextAlign()

            r.ImGui_PushStyleVar(ctx, framepadding, 0, 3) --StyleVar#1 (Child Frame for all FX Devices)
            --r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x121212ff)


            for FX_Idx = 0, RepeatTimeForWindows - 1, 1 do
                FXGUID[FX_Idx] = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx)

                if string.find(FX_Name, 'FXD %(Mix%)RackMixer') or string.find(FX_Name, 'FXRack') then
                    FXGUID_RackMixer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                end
            end


            if FXGUID_RackMixer ~= nil then
                Lyr.FX_Ins[FXGUID_RackMixer] = 0
                for FX_Idx = 0, RepeatTimeForWindows - 1, 1 do
                    if FX.InLyr[FXGUID[FX_Idx]] == FXGUID_RackMixer then
                        Lyr.FX_Ins[FXGUID_RackMixer] = Lyr.FX_Ins[FXGUID_RackMixer] + 1
                    end
                end
            end


            Glob.WDL = r.ImGui_GetWindowDrawList(ctx)
            Glob.FDL = r.ImGui_GetForegroundDrawList(ctx)
            if Dvdr.JustDroppedFX then
                if not Dvdr.JustDrop.X then
                    Dvdr.JustDrop.X, Dvdr.JustDrop.Y = r.ImGui_GetMousePos(ctx)
                end
                local X, Y = r.ImGui_GetMousePos(ctx)

                if X > Dvdr.JustDrop.X + 15 or X < Dvdr.JustDrop.X - 15 then
                    Dvdr.JustDroppedFX = nil
                    Dvdr.JustDrop.X = nil
                    Dvdr.JustDrop.Y = nil
                end
            end


            Trk[TrkID] = Trk[TrkID] or {}
            Trk[TrkID].PreFX = Trk[TrkID].PreFX or {}


            r.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_ChildBorderSize(), 0)
            Cx_LeftEdge, Cy_BeforeFXdevices = r.ImGui_GetCursorScreenPos(ctx)
            MouseAtLeftEdge = r.ImGui_IsMouseHoveringRect(ctx, Cx_LeftEdge - 50, Cy_BeforeFXdevices, Cx_LeftEdge + 5,
                Cy_BeforeFXdevices + 220)
            --MouseAtRightEdge = r.ImGui_IsMouseHoveringRect( ctx, VP.X+VP.w-40, Cy_BeforeFXdevices,  VP.X+VP.w, Cy_BeforeFXdevices+220)
            if MouseAtLeftEdge and not Trk[TrkID].PreFX[1] and string.len(Payload_Type) > 1 then
                rv = r.ImGui_Button(ctx, 'P\nr\ne\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
                SL(nil, 0)
                HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                    'GetItemRect', WDL)

                if Payload_Type == 'FX_Drag' then
                    dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                    r.ImGui_SameLine(ctx, nil, 0)
                elseif Payload_Type == 'AddFX_Sexan' then
                    dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'AddFX_Sexan') --
                end
            end


            if Trk[TrkID].PreFX[1] then
                rv = r.ImGui_Button(ctx, (#Trk[TrkID].PreFX or '') .. '\n\n' .. 'P\nr\ne\n \nF\nX\n \nC\nh\na\ni\nn', 20,
                    220)
                r.ImGui_SameLine(ctx, nil, 0)
                if r.ImGui_IsItemClicked(ctx, 1) then
                    if Trk[TrkID].PreFX_Hide then Trk[TrkID].PreFX_Hide = false else Trk[TrkID].PreFX_Hide = true end
                end
            end

            if r.ImGui_BeginDragDropTarget(ctx) then
                if Payload_Type == 'FX_Drag' then
                    rv, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                    HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                        'GetItemRect', WDL)

                    if rv then
                        if not tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]) then
                            table.insert(Trk[TrkID].PreFX, FXGUID[DragFX_ID])
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. #Trk[TrkID].PreFX,
                                FXGUID[DragFX_ID], true)
                        end

                        -- move fx out of post chain
                        local IDinPost = tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID])
                        if IDinPost then MoveFX_Out_Of_Post(IDinPost) end

                        --Move FX out of layer
                        if FX.InLyr[FXGUID[DragFX_ID]] then
                            FX.InLyr[FXGUID[DragFX_ID]] = nil
                            r.SetProjExtState(0, 'FX Devices', 'FXLayer - ' .. 'is FX' .. FXGUID[DragFX_ID] .. 'in layer',
                                '')
                        end
                        RemoveFXfromBS()
                    end
                elseif Payload_Type == 'AddFX_Sexan' then
                    dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'AddFX_Sexan') --
                    if dropped then
                        r.TrackFX_AddByName(LT_Track, payload, false, -1000)
                        local FxID = r.TrackFX_GetFXGUID(LT_Track, 0)
                        table.insert(Trk[TrkID].PreFX, FxID)
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. #Trk[TrkID].PreFX, FxID, true)

                        for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do
                            FXGUID[FX_Idx] = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                        end
                    end
                end



                r.ImGui_EndDragDropTarget(ctx)
            end



            Trk[TrkID].PostFX = Trk[TrkID].PostFX or {}
            if ((DragDroppingFX and MouseAtRightEdge) and not Trk[TrkID].PostFX[1]) then
                if Trk[TrkID].PreFX[1] then MakeSpaceForPostFX = 30 else MakeSpaceForPostFX = 0 end
            elseif Trk[TrkID].PostFX_Hide and Trk[TrkID].PreFX[1] then
                MakeSpaceForPostFX = 20
            else
                MakeSpaceForPostFX = 0
            end



            MacroPos = r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0)
            local ReSpectrumPos = r.TrackFX_AddByName(LT_Track, 'FXD ReSpectrum', 0, 0)
            if MacroPos ~= -1 and MacroPos ~= 0 then                                                                        -- if macro exists on track, and Macro is not the 1st fx
                if FX.Win_Name[0] ~= 'JS: FXD Macros' then r.TrackFX_CopyToTrack(LT_Track, MacroPos, LT_Track, 0, true) end -- move it to 1st slot
            end



            if MacroPos ~= -1 or ReSpectrumPos == 0 then offset = 0 else offset = 1 end -- if no Macros is found


            for i, v in pairs(Trk[TrkID].PreFX or {}) do
                if FXGUID[i - offset] ~= v then
                    if not AddFX.Name[1] then
                        table.insert(MovFX.FromPos, tablefind(FXGUID, v))
                        table.insert(MovFX.ToPos, i - offset)
                        table.insert(MovFX.Lbl, 'Move FX into Pre-Chain')
                    end
                end
            end
            offset = nil
            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(), Window_BG or CustomColorsDefault.Window_BG)

            local spaceIfPreFX = 0
            if Trk[TrkID].PreFX[1] and Trk[TrkID].PostFX[1] and not Trk[TrkID].PostFX_Hide then spaceIfPreFX = 20 end
            if Wheel_V ~= 0 and not DisableScroll then r.ImGui_SetNextWindowScroll(ctx, -CursorStartX + Wheel_V * 10, 0) end

            if r.ImGui_BeginChild(ctx, 'fx devices', MaxX - (PostFX_Width or 0) - spaceIfPreFX, 240, nil, r.ImGui_WindowFlags_HorizontalScrollbar() + FX_DeviceWindow_NoScroll) then
                ------------------------------------------------------
                ----- Loop for every FX on the track -----------------
                ------------------------------------------------------
                CursorStartX = r.ImGui_GetCursorStartPos(ctx)
                Glob.WinL, Glob.WinT = r.ImGui_GetCursorScreenPos(ctx)
                Glob.Height = 220
                Glob.WinB = Glob.WinT + Glob.Height
                AnySplitBandHvred = false


                local ViewPort_DL = r.ImGui_GetWindowDrawList(ctx)
                r.ImGui_DrawList_AddLine(ViewPort_DL, 0, 0, 0, 0, Clr.Dvdr.outline) -- Needed for drawlist to be active

                for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do
                    retval, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx) --i used to be i-1
                    FXGUID[FX_Idx] = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)


                    local FxGUID = FXGUID[FX_Idx]
                    FX.Win_Name[FX_Idx] = FX_Name
                    focusedFXState, trackNumOfFocusFX, _, FX_Index_FocusFX = reaper.GetFocusedFX2()

                    if FXGUID[FX_Idx] then
                        FX[FxGUID] = FX[FxGUID] or {}
                    end


                    function GetFormatPrmV(V, OrigV, i)
                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i, V)
                        local _, RV = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, i)
                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i, OrigV)
                        return RV
                    end

                    FXGUID_To_Check_If_InLayer = reaper.TrackFX_GetFXGUID(LT_Track, FX_Idx)

                    if not tablefind(Trk[TrkID].PostFX, FxGUID) and FXGUID[FX_Idx] ~= FXGUID[FX_Idx - 1] then
                        if FX.InLyr[FXGUID_To_Check_If_InLayer] == nil           --not in layer
                            and FindStringInTable(BlackListFXs, FX_Name) ~= true -- not blacklisted
                            and string.find(FX_Name, 'RackMixer') == nil
                            and FX_Idx ~= RepeatTimeForWindows                   --not last fx
                            and not FX[FxGUID].InWhichBand --[[Not in Band Split]] then
                            local Idx = FX_Idx
                            if FX_Idx == 1 then
                                local Nm = FX.Win_Name[0]
                                if Nm == 'JS: FXD Macros' or FindStringInTable(BlackListFXs, Nm) then Idx = 0 end
                            end
                            AddSpaceBtwnFXs(Idx)
                        elseif FX.InLyr[FXGUID_To_Check_If_InLayer] == FXGUID[FX_Idx] and FXGUID[FX_Idx] then
                            AddSpaceBtwnFXs(FX_Idx, true)
                        elseif FX_Idx == RepeatTimeForWindows then
                        end
                    end


                    ------------END Space between FXs--------------------



                    ---------------==  FX Devices--------------------

                    DragFX_ID = DragFX_ID or -1000
                    if DragDroppingFX == true and DragFX_ID == FX_Idx then
                        BGColor_FXWindow = FX_Window_Clr_When_Dragging
                    else
                        BGColor_FXWindow = FX_Window_Clr_Default
                    end
                    BGColor_FXWindow = BGColor_FXWindow or 0x434343ff


                    function createFXWindow(FX_Idx)
                        local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

                        if FXGUID[FX_Idx] ~= FXGUID[FX_Idx - 1] --[[  findDuplicates(FXGUID) ]] and FxGUID then
                            r.ImGui_BeginGroup(ctx)

                            FX.Enable[FX_Idx] = reaper.TrackFX_GetEnabled(LT_Track, FX_Idx)
                            local _, FX_Name = r.TrackFX_GetFXName(LT_Track, FX_Idx); local FxGUID = FXGUID[FX_Idx];
                            local FxNameS = FX.Win_Name_S[FX_Idx]
                            local Hide
                            FX.DL = r.ImGui_GetWindowDrawList(ctx)


                            FX_Name = string.sub(FX_Name, 1, (string.find(FX_Name, '%(') or 30) - 1)
                            FX_Name = string.gsub(FX_Name, '-', ' ')
                            WDL = FX.DL
                            FX[FxGUID] = FX[FxGUID] or {}
                            if FX[FxGUID].MorphA and not FX[FxGUID].MorphHide then
                                local OrigCurX, OrigCurY = r.ImGui_GetCursorPos(ctx)

                                DefClr_A_Act = Morph_A or CustomColorsDefault.Morph_A
                                DefClr_A = Change_Clr_A(DefClr_A_Act, -0.2)
                                DefClr_A_Hvr = Change_Clr_A(DefClr_A_Act, -0.1)
                                DefClr_B_Act = Morph_B or CustomColorsDefault.Morph_B
                                DefClr_B = Change_Clr_A(DefClr_B_Act, -0.2)
                                DefClr_B_Hvr = Change_Clr_A(DefClr_B_Act, -0.1)


                                function StoreAllPrmVal(AB, DontStoreCurrentVal, LinkCC)
                                    local PrmCount = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                                    for i = 0, PrmCount - 4, 1 do
                                        local _, name = r.TrackFX_GetParamName(LT_Track, FX_Idx, i)
                                        local Prm_Val, minval, maxval = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                                        if AB == 'A' then
                                            if DontStoreCurrentVal ~= 'Dont' then FX[FxGUID].MorphA[i] = Prm_Val end
                                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX Morph A' .. i .. FxGUID,
                                                FX[FxGUID].MorphA[i], true)
                                            if LinkCC then
                                                Link_Param_to_CC(LT_TrackNum, FX_Idx, i, true, true, 160,
                                                    LinkCC, Prm_Val, FX[FxGUID].MorphB[i])
                                            end
                                        else
                                            if DontStoreCurrentVal ~= 'Dont' then FX[FxGUID].MorphB[i] = Prm_Val end
                                            if FX[FxGUID].MorphB[i] then
                                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX Morph B' .. i ..
                                                    FxGUID, FX[FxGUID].MorphB[i], true)
                                                if LinkCC then
                                                    Link_Param_to_CC(LT_TrackNum, FX_Idx, i, true, true, 160,
                                                        LinkCC, FX[FxGUID].MorphA[i], Prm_Val - FX[FxGUID].MorphA[i])
                                                end
                                            end
                                        end
                                    end
                                    if DontStoreCurrentVal ~= 'Dont' then
                                        local rv, presetname = r.TrackFX_GetPreset(LT_Track, FX_Idx)
                                        if rv and AB == 'A' then
                                            FX[FxGUID].MorphA_Name = presetname
                                            r.GetSetMediaTrackInfo_String(LT_Track,
                                                'P_EXT: FX Morph A' .. FxGUID .. 'Preset Name', presetname, true)
                                        elseif rv and AB == 'B' then
                                            FX[FxGUID].MorphB_Name = presetname
                                            r.GetSetMediaTrackInfo_String(LT_Track,
                                                'P_EXT: FX Morph B' .. FxGUID .. 'Preset Name', presetname, true)
                                        end
                                    end
                                end

                                r.ImGui_SetNextItemWidth(ctx, 20)
                                local x, y = r.ImGui_GetCursorPos(ctx)
                                x = x - 2
                                local SCx, SCy = r.ImGui_GetCursorScreenPos(ctx)
                                SCx = SCx - 2
                                r.ImGui_SetCursorPosX(ctx, x)

                                --r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),DefClr_A) r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), DefClr_A_Hvr) r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), DefClr_A_Act)

                                if r.ImGui_Button(ctx, 'A##' .. FxGUID, 20, 20) then
                                    StoreAllPrmVal('A', nil, FX[FxGUID].Morph_ID)
                                end
                                --r.ImGui_PopStyleColor(ctx,3)


                                if r.ImGui_IsItemHovered(ctx) and FX[FxGUID].MorphA_Name then
                                    if FX[FxGUID].MorphA_Name ~= '' then
                                        HintToolTip(FX[FxGUID].MorphA_Name)
                                    end
                                end

                                local H = 180
                                r.ImGui_SetCursorPos(ctx, x, y + 20)

                                r.ImGui_InvisibleButton(ctx, '##Morph' .. FxGUID, 20, H)

                                local BgClrA, isActive, V_Pos, DrgSpdMod, SldrActClr, BtnB_TxtClr, ifHvr
                                local M = PresetMorph


                                if r.ImGui_IsItemActive(ctx) then
                                    BgClr = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_FrameBgActive())
                                    isActive = true
                                    BgClrA = DefClr_A_Act
                                    BgClrB =
                                        DefClr_B_Act -- shift 0x00RRGGBB to 0xRRGGBB00 then add 0xFF for 100% opacity
                                elseif r.ImGui_IsItemHovered(ctx) then
                                    ifHvr = true
                                    BgClrA = DefClr_A_Hvr
                                    BgClrB = DefClr_B_Hvr
                                else
                                    BgClr = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_FrameBg())
                                    BgClrA = DefClr_A
                                    BgClrB = DefClr_B
                                end
                                if --[[Ctrl + R click]] r.ImGui_IsItemClicked(ctx, 1) and Mods == Ctrl then
                                    r.ImGui_OpenPopup(ctx, 'Morphing menu' .. FX_Idx)
                                end




                                local L, T = r.ImGui_GetItemRectMin(ctx)
                                local R, B = r.ImGui_GetItemRectMax(ctx)
                                r.ImGui_DrawList_AddRectFilledMultiColor(WDL, L, T, R, B, BgClrA, BgClrA, DefClr_B,
                                    DefClr_B)

                                r.ImGui_SameLine(ctx, nil, 0)

                                if isActive then
                                    local _, v = r.ImGui_GetMouseDelta(ctx, nil, nil)
                                    if Mods == Shift then DrgSpdMod = 4 end
                                    DraggingMorph = FxGUID
                                    FX[FxGUID].MorphAB_Sldr = SetMinMax(
                                        (FX[FxGUID].MorphAB_Sldr or 0) + v / (DrgSpdMod or 2), 0, 100)
                                    SldrActClr = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_SliderGrabActive())
                                    if FX[FxGUID].MorphB[1] ~= nil then
                                        local M_ID
                                        if FX[FxGUID].Morph_ID then
                                            r.TrackFX_SetParamNormalized(LT_Track, 0 --[[Macro.jsfx]],
                                                7 + FX[FxGUID].Morph_ID, FX[FxGUID].MorphAB_Sldr / 100)
                                        else
                                            for i, v in ipairs(FX[FxGUID].MorphA), FX[FxGUID].MorphA, -1 do
                                                if v ~= FX[FxGUID].MorphB[i] then
                                                    if FX[FxGUID].PrmList[i] then
                                                        if FX[FxGUID].PrmList[i].BL ~= true then
                                                            Fv = v +
                                                                (FX[FxGUID].MorphB[i] - v) *
                                                                (FX[FxGUID].MorphAB_Sldr / 100)
                                                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i, Fv)
                                                        end
                                                    else
                                                        Fv = v + (FX[FxGUID].MorphB[i] - v) *
                                                            (FX[FxGUID].MorphAB_Sldr / 100)
                                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i, Fv)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end

                                --[[ if ifHvr   then

                                    --r.ImGui_SetNextWindowPos(ctx,SCx+20, SCy+20)
                                    r.ImGui_OpenPopup(ctx, 'Hover On Preset Morph Drag')

                                    M.JustHvrd = true
                                end
                                if M.JustHvrd then

                                    M.JustHvrd = nil
                                end ]]

                                if r.ImGui_BeginPopup(ctx, 'Morphing menu' .. FX_Idx) then
                                    local Disable
                                    MorphingMenuOpen = true
                                    if not FX[FxGUID].MorphA[1] or not FX[FxGUID].MorphB[1] then
                                        r.ImGui_BeginDisabled(
                                            ctx)
                                    end

                                    if not FX[FxGUID].Morph_ID or FX[FxGUID].Unlink then
                                        if r.ImGui_Selectable(ctx, 'Automate') then
                                            r.gmem_attach('ParamValues')

                                            if not Trk[TrkID].Morph_ID then
                                                Trk[TrkID].Morph_ID = {} -- Morph_ID is the CC number jsfx sends
                                                Trk[TrkID].Morph_ID[1] = FxGUID
                                                FX[FxGUID].Morph_ID = 1
                                            else
                                                if not FX[FxGUID].Morph_ID then
                                                    table.insert(Trk[TrkID].Morph_ID, FxGUID)
                                                    FX[FxGUID].Morph_ID = tablefind(Trk[TrkID].Morph_ID, FxGUID)
                                                end
                                            end

                                            if --[[Add Macros JSFX if not found]] r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 and r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then
                                                r.gmem_write(1, PM.DIY_TrkID[TrkID]) --gives jsfx a guid when it's being created, this will not change becuase it's in the @init.
                                                AddMacroJSFX()
                                            end
                                            for i, v in ipairs(FX[FxGUID].MorphA), FX[FxGUID].MorphA, -1 do
                                                local Scale = FX[FxGUID].MorphB[i] - v

                                                if v ~= FX[FxGUID].MorphB[i] then
                                                    local function LinkPrm()
                                                        Link_Param_to_CC(LT_TrackNum, FX_Idx, i, true, true, 160,
                                                            FX[FxGUID].Morph_ID, v, Scale)
                                                        FX[FxGUID][i] = FX[FxGUID][i] or {}
                                                        r.GetSetMediaTrackInfo_String(LT_Track,
                                                            'P_EXT: FXs Morph_ID' .. FxGUID, FX[FxGUID].Morph_ID, true)
                                                    end

                                                    if FX[FxGUID].PrmList[i] then
                                                        if FX[FxGUID].PrmList[i].BL ~= true then
                                                            LinkPrm()
                                                        end
                                                    else
                                                        LinkPrm()
                                                    end
                                                end
                                            end


                                            -- Show Envelope for Morph Slider
                                            r.GetFXEnvelope(LT_Track, 0, 7 + FX[FxGUID].Morph_ID, true)


                                            FX[FxGUID].Unlink = false
                                            r.GetSetMediaTrackInfo_String(LT_Track,
                                                'P_EXT: FXs Morph_ID' .. FxGUID .. 'Unlink', '', true)

                                            SetPrmAlias(LT_TrackNum, 1, 8 + FX[FxGUID].Morph_ID,
                                                FX.Win_Name_S[FX_Idx]:gsub("%b()", "") .. ' - Morph AB ')
                                        end
                                    elseif FX[FxGUID].Morph_ID or not FX[FxGUID].Unlink then
                                        if r.ImGui_Selectable(ctx, 'Unlink Parameters to Morph Automation') then
                                            for i, v in ipairs(FX[FxGUID].MorphA), FX[FxGUID].MorphA, -1 do
                                                Unlink_Parm(LT_TrackNum, FX_Idx, i)
                                            end
                                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FXs Morph_ID' .. FxGUID,
                                                FX[FxGUID].Morph_ID, true)
                                            FX[FxGUID].Unlink = true
                                            r.GetSetMediaTrackInfo_String(LT_Track,
                                                'P_EXT: FXs Morph_ID' .. FxGUID .. 'Unlink', 'Unlink', true)
                                        end
                                    end

                                    if FX[FxGUID].Morph_Value_Edit then
                                        if r.ImGui_Selectable(ctx, 'EXIT Edit Preset Value Mode') then
                                            FX[FxGUID].Morph_Value_Edit = false
                                        end
                                    else
                                        if Disable then r.ImGui_BeginDisabled(ctx) end
                                        if r.ImGui_Selectable(ctx, 'ENTER Edit Preset Value Mode') then
                                            FX[FxGUID].Morph_Value_Edit = true
                                        end
                                    end
                                    if not FX[FxGUID].MorphA[1] or not FX[FxGUID].MorphB[1] then r.ImGui_EndDisabled(ctx) end

                                    if r.ImGui_Selectable(ctx, 'Morphing Blacklist Settings') then
                                        if OpenMorphSettings then
                                            OpenMorphSettings = FxGUID
                                        else
                                            OpenMorphSettings =
                                                FxGUID
                                        end
                                        local Ct = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                                        FX[FxGUID].PrmList = FX[FxGUID].PrmList or {}
                                        for i = 0, Ct - 4, 1 do --get param names
                                            FX[FxGUID].PrmList[i]      = FX[FxGUID].PrmList[i] or {}
                                            local rv, name             = r.TrackFX_GetParamName(LT_Track, FX_Idx, i)
                                            FX[FxGUID].PrmList[i].Name = name
                                        end
                                    end

                                    if r.ImGui_Selectable(ctx, 'Hide Morph Slider') then
                                        FX[FxGUID].MorphHide = true
                                    end

                                    r.ImGui_EndPopup(ctx)
                                else
                                    MorphingMenuOpen = false
                                end




                                if not ifHvr and M.JustHvrd then
                                    M.timer = M.timer + 1
                                else
                                    M.timer = 0
                                end





                                V_Pos = T + (FX[FxGUID].MorphAB_Sldr or 0) / 100 * H * 0.95
                                r.ImGui_DrawList_AddRectFilled(WDL, L, V_Pos, R, V_Pos + 10, 0xffffff22)
                                r.ImGui_DrawList_AddRect(WDL, L, V_Pos, R, V_Pos + 10, 0xffffff44)


                                r.ImGui_SameLine(ctx)
                                r.ImGui_SetCursorPos(ctx, x, y + 200)
                                if not FX[FxGUID].MorphB[1] then
                                    BtnB_TxtClr = r.ImGui_GetStyleColor(ctx,
                                        r.ImGui_Col_TextDisabled())
                                end

                                if BtnB_TxtClr then
                                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),
                                        r.ImGui_GetStyleColor(ctx, r.ImGui_Col_TextDisabled()))
                                end
                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), DefClr_B)
                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), DefClr_B_Hvr)
                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), DefClr_B_Act)

                                if r.ImGui_Button(ctx, 'B##' .. FxGUID, 20, 20) then
                                    StoreAllPrmVal('B', nil, FX[FxGUID].Morph_ID)
                                    local rv, presetname = r.TrackFX_GetPreset(LT_Track, FX_Idx)
                                    if rv then FX[FxGUID].MorphB_Name = presetname end
                                end
                                if r.ImGui_IsItemHovered(ctx) and FX[FxGUID].MorphB_Name then
                                    HintToolTip(FX[FxGUID]
                                        .MorphB_Name)
                                end
                                r.ImGui_PopStyleColor(ctx, 3)

                                if BtnB_TxtClr then r.ImGui_PopStyleColor(ctx) end
                                if FX.Enable[FX_Idx] == false then
                                    r.ImGui_DrawList_AddRectFilled(WDL, L, T - 20, R, B +
                                        20, 0x00000088)
                                end

                                r.ImGui_SetCursorPos(ctx, OrigCurX + 19, OrigCurY)
                            end

                            local FX_Devices_Bg = FX_Devices_Bg
                            if string.find(FX_Name, 'Pro Q 3') then FX_Devices_Bg = 0x000000ff end

                            -- FX window color

                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(),
                                FX.BgClr[FxGUID] or FX_Devices_Bg or 0x151515ff); local poptimes = 1


                            FX[FxGUID] = FX[FxGUID] or {}

                            local PrmCount = tonumber(select(2, r.GetProjExtState(0, 'FX Devices', 'Prm Count' .. FxGUID))) or
                                0
                            local Def_Sldr_W = 160
                            if FX.Def_Sldr_W[FxGUID] then Def_Sldr_W = FX.Def_Sldr_W[FxGUID] end

                            if FX.Def_Type[FxGUID] == 'Slider' or FX.Def_Type[FxGUID] == 'Drag' or not FX.Def_Type[FxGUID] then
                                local DF = (FX.Def_Sldr_W[FxGUID] or Df.Sldr_W)
                                if PrmCount < 7 then
                                    DefaultWidth = DF + 10
                                elseif PrmCount >= 7 and PrmCount <= 12 then
                                    DefaultWidth = 10 + DF * 2 + 25
                                elseif PrmCount >= 13 and PrmCount <= 18 then
                                    DefaultWidth = 10 + DF * 3 + 25
                                elseif PrmCount >= 19 and PrmCount <= 24 then
                                    DefaultWidth = 10 + DF * 4 + 25
                                else
                                    DefaultWidth = DF + 10
                                end
                            elseif FX.Def_Type[FxGUID] == 'Knob' then
                                if PrmCount <= 6 then
                                    DefaultWidth = Df.KnobSize * 3
                                elseif PrmCount > 6 and PrmCount <= 9 then
                                    DefaultWidth = Df.KnobSize * 4
                                elseif PrmCount > 9 and PrmCount <= 12 then
                                    DefaultWidth = (Df.KnobSize + 10) * 4
                                elseif PrmCount > 16 and PrmCount <= 20 then
                                    DefaultWidth = Df.KnobSize * 5
                                elseif PrmCount > 20 and PrmCount <= 24 then
                                    DefaultWidth = Df.KnobSize * 6
                                else
                                    DefaultWidth = Df.Sldr_W + 10
                                end
                            end

                            if string.find(FX_Name, 'Pro Q 3') then
                                FX.Width[FxGUID] = 340
                            elseif string.find(FX_Name, 'Pro C 2') then
                                FX.Width[FxGUID] = ProC.Width
                            elseif FindStringInTable(BlackListFXs, FX_Name) then
                                Hide = true
                            elseif FX.Width[FxGUID] == 340 then
                                FX.Width[FxGUID] = nil
                            end

                            if Trk[TrkID].PreFX_Hide then
                                if FindStringInTable(Trk[TrkID].PreFX, FxGUID) then
                                    Hide = true
                                end
                                if Trk[TrkID].PreFX[FX_Idx + 1] == FxGUID then
                                    Hide = true
                                end
                            end
                            if not Hide then
                                local CurPosX
                                if FxGUID == FXGUID[(tablefind(Trk[TrkID].PostFX, FxGUID) or 0) - 1] then
                                    --[[ CurPosX = r.ImGui_GetCursorPosX(ctx)
                                    r.ImGui_SetCursorPosX(ctx,VP.X+VP.w- (FX[FxGUID].PostWin_SzX or 0)) ]]
                                end

                                if r.ImGui_BeginChild(ctx, FX_Name .. FX_Idx, FX.WidthCollapse[FxGUID] or FX.Width[FXGUID[FX_Idx]] or DefaultWidth, 220, nil, r.ImGui_WindowFlags_NoScrollWithMouse() |r.ImGui_WindowFlags_NoScrollbar()) and not Hide then ----START CHILD WINDOW------
                                    if Draw[FxNameS] ~= nil then
                                        local D = Draw[FxNameS]
                                    end

                                    Glob.FDL = r.ImGui_GetForegroundDrawList(ctx)

                                    WDL = r.ImGui_GetWindowDrawList(ctx)
                                    Win_L, Win_T = r.ImGui_GetItemRectMin(ctx); Win_W, Win_H = r.ImGui_GetItemRectSize(
                                        ctx)
                                    Win_R, _ = r.ImGui_GetItemRectMax(ctx); Win_B = Win_T + 220

                                    if Draw.DrawMode[FxGUID] == true then
                                        local D = Draw[FxNameS]
                                        r.ImGui_DrawList_AddRectFilled(WDL, Win_L, Win_T, Win_R, Win_B, 0x00000033)
                                        for i = 0, 220, LE.GridSize do
                                            r.ImGui_DrawList_AddLine(WinDrawList, Win_L,
                                                Win_T + i, Win_R, Win_T + i, 0x44444411)
                                        end
                                        for i = 0, FX.Width[FXGUID[FX_Idx]] or DefaultWidth, LE.GridSize do
                                            r
                                                .ImGui_DrawList_AddLine(WinDrawList, Win_L + i, Win_T, Win_L + i, Win_B,
                                                    0x44444411)
                                        end
                                        if r.ImGui_IsMouseHoveringRect(ctx, Win_L, Win_T, Win_R, Win_B) and HvringItmSelector == nil and not Draw.SelItm and Draw.Time == 0 then
                                            if Draw.Type == 'Text' then
                                                r.ImGui_SetMouseCursor(ctx,
                                                    r.ImGui_MouseCursor_TextInput())
                                            end
                                            if IsLBtnClicked and Mods == 0 then
                                                MsX_Start, MsY_Start = r.ImGui_GetMousePos(ctx); CurX, CurY = r
                                                    .ImGui_GetCursorScreenPos(ctx)
                                                Win_MsX_Start = MsX_Start - CurX; Win_MsY_Start = MsY_Start - CurY + 3
                                            end


                                            if IsLBtnHeld and Mods == 0 then
                                                MsX, MsY   = r.ImGui_GetMousePos(ctx)
                                                CurX, CurY = r.ImGui_GetCursorScreenPos(ctx)
                                                Win_MsX    = MsX - CurX; Win_MsY = MsY - CurY

                                                Rad        = MsX - MsX_Start
                                                if Rad < 0 then Rad = Rad * (-1) end
                                                if Draw.Type == 'line' then
                                                    r.ImGui_DrawList_AddLine(WDL, MsX_Start, MsY_Start, MsX, MsY_Start,
                                                        Draw.clr)
                                                elseif Draw.Type == 'V-line' then
                                                    r.ImGui_DrawList_AddLine(WDL, MsX_Start, MsY_Start, MsX_Start, MsY,
                                                        Draw.clr)
                                                elseif Draw.Type == 'rectangle' then
                                                    r.ImGui_DrawList_AddRect(WDL, MsX_Start, MsY_Start, MsX, MsY,
                                                        Draw.clr, Draw.Df_EdgeRound[FxGUID] or 0)
                                                elseif Draw.Type == 'rect fill' then
                                                    r.ImGui_DrawList_AddRectFilled(WDL, MsX_Start, MsY_Start, MsX, MsY,
                                                        Draw.clr, Draw.Df_EdgeRound[FxGUID] or 0)
                                                elseif Draw.Type == 'circle' then
                                                    reaper.ImGui_DrawList_AddCircle(WDL, MsX_Start, MsY_Start, Rad,
                                                        Draw.clr)
                                                elseif Draw.Type == 'circle fill' then
                                                    r.ImGui_DrawList_AddCircleFilled(WDL, MsX_Start, MsY_Start, Rad,
                                                        Draw.clr)
                                                elseif Draw.Type == 'Text' then
                                                    --r.ImGui_DrawList_AddTextEx(WDL, Font_Andale_Mono_20, 20 , MsX, MsY  , Draw.clr, D.Txt)
                                                    r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_TextInput())
                                                end
                                            end

                                            if LBtnRel and Mods == 0 then
                                                local D = Draw[FxNameS]
                                                LE.BeenEdited = true
                                                --find the next available slot in table
                                                if Draw.Type == 'Text' then AddText = true end

                                                if Draw.Type == 'circle' or Draw.Type == 'circle fill' then
                                                    table.insert(D.R, Rad)
                                                else
                                                    table.insert(D.R, Win_MsX)
                                                end

                                                table.insert(D.L, Win_MsX_Start); table.insert(D.T, Win_MsY_Start);; table
                                                    .insert(D.Type, Draw.Type)
                                                table.insert(D.B, Win_MsY)
                                                table.insert(D.clr, Draw.clr or 0xffffffff)
                                            end
                                        end
                                        HvringItmSelector = nil
                                        if AddText == true then
                                            r.ImGui_OpenPopup(ctx, 'Drawlist Add Text Menu')
                                        end

                                        if r.ImGui_BeginPopup(ctx, 'Drawlist Add Text Menu') then
                                            enter, NewDrawTxt = r.ImGui_InputText(ctx, '##' .. 'DrawTxt', NewDrawTxt)


                                            if r.ImGui_IsItemDeactivatedAfterEdit(ctx) then
                                                table.insert(D.Txt, NewDrawTxt); AddText = nil; r
                                                    .ImGui_CloseCurrentPopup(ctx)
                                            end

                                            r.ImGui_SetItemDefaultFocus(ctx)



                                            r.ImGui_EndPopup(ctx)
                                        end


                                        if r.ImGui_IsMouseHoveringRect(ctx, Win_L, Win_T, Win_R, Win_B) and HvringItmSelector == nil then
                                            if IsLBtnClicked then
                                                Draw.SelItm = nil
                                                Draw.Time = 1
                                                AddText = nil
                                            end
                                        end
                                        if Draw.Time > 0 then Draw.Time = Draw.Time + 1 end
                                        if Draw.Time > 6 then Draw.Time = 0 end


                                        for i, Type in pairs(D.Type) do
                                            local ID = FX_Name .. i
                                            local CircleX, CircleY = Win_L + D.L[i], Win_T + D.T[i]
                                            local FDL = r.ImGui_GetForegroundDrawList(ctx)
                                            r.ImGui_DrawList_AddCircle(FDL, CircleX, CircleY, 7, 0x99999999)
                                            r.ImGui_DrawList_AddText(FDL, Win_L + D.L[i] - 2, Win_T + D.T[i] - 7,
                                                0x999999ff, i)


                                            if Draw.SelItm == i then
                                                r.ImGui_DrawList_AddCircleFilled(WDL, CircleX,
                                                    CircleY, 7, 0x99999955)
                                            end


                                            --if hover on item node ...
                                            if r.ImGui_IsMouseHoveringRect(ctx, CircleX - 5, CircleY - 5, CircleX + 5, CircleY + 10) then
                                                HvringItmSelector = true
                                                r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_ResizeAll())
                                                if DragItm == nil then
                                                    r.ImGui_DrawList_AddCircle(WDL, CircleX, CircleY,
                                                        9, 0x999999ff)
                                                end
                                                if IsLBtnClicked and Mods == 0 then
                                                    Draw.SelItm = i
                                                    DragItm = i
                                                end
                                                if LBtnRel then DragItm = nil end

                                                if IsLBtnClicked and Mods == Alt then
                                                    table.remove(D.Type, i)
                                                    table.remove(D.L, i)
                                                    table.remove(D.R, i)
                                                    table.remove(D.T, i)
                                                    table.remove(D.B, i)
                                                    if D.Txt[i] then table.remove(D.Txt, i) end
                                                    if D.clr[i] then table.remove(D.clr, i) end
                                                    if r.ImGui_BeginPopup(ctx, 'Drawlist Add Text Menu') then
                                                        r.ImGui_CloseCurrentPopup(ctx)
                                                        r.ImGui_EndPopup(ctx)
                                                    end
                                                end
                                            end
                                            if LBtnDrag and DragItm == i then --- Drag node to reposition
                                                r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_ResizeAll())
                                                r.ImGui_DrawList_AddCircleFilled(WDL, CircleX, CircleY, 7, 0x00000033)
                                                local Dx, Dy = r.ImGui_GetMouseDelta(ctx)
                                                if D.Type[DragItm] ~= 'circle' and D.Type[DragItm] ~= 'circle fill' then
                                                    D.R[i] = D.R[i] + Dx -- this is circle's radius
                                                end
                                                D.L[i] = D.L[i] + Dx
                                                D.T[i] = D.T[i] + Dy
                                                D.B[i] = D.B[i] + Dy
                                            end
                                        end
                                    end

                                    if Draw[FX.Win_Name_S[FX_Idx]] and not FX[FxGUID].Collapse then
                                        local D = Draw[FX.Win_Name_S[FX_Idx]]
                                        for i, Type in pairs(D.Type) do
                                            if D.Type[i] == 'line' then
                                                r.ImGui_DrawList_AddLine(WDL, Win_L + D.L[i], Win_T + D.T[i],
                                                    Win_L + D.R[i], Win_T + D.T[i], D.clr[i] or 0xffffffff)
                                            end
                                            if D.Type[i] == 'V-line' then
                                                r.ImGui_DrawList_AddLine(WDL, Win_L + D.L[i], Win_T + D.T[i],
                                                    Win_L + D.L[i], Win_T + D.B[i], D.clr[i] or 0xffffffff)
                                            end


                                            if D.Type[i] == 'rectangle' then
                                                r.ImGui_DrawList_AddRect(WDL, Win_L + D.L[i], Win_T + D.T[i],
                                                    Win_L + D.R[i], Win_T + D.B[i], D.clr[i] or 0xffffffff,
                                                    Draw.Df_EdgeRound[FxGUID] or 0)
                                            end
                                            if D.Type[i] == 'rect fill' then
                                                r.ImGui_DrawList_AddRectFilled(WDL, Win_L + D.L[i], Win_T + D.T[i],
                                                    Win_L + D.R[i], Win_T + D.B[i], D.clr[i] or 0xffffffff,
                                                    Draw.Df_EdgeRound[FxGUID] or 0)
                                            end
                                            if D.Type[i] == 'circle' then
                                                r.ImGui_DrawList_AddCircle(WDL, Win_L + D.L[i], Win_T + D.T[i], D.R[i],
                                                    D.clr[i] or 0xffffffff)
                                            end
                                            if D.Type[i] == 'circle fill' then
                                                r.ImGui_DrawList_AddCircleFilled(WDL, Win_L + D.L[i], Win_T + D.T[i],
                                                    D.R[i], D.clr[i] or 0xffffffff)
                                            end


                                            if D.Type[i] == 'Text' and D.Txt[i] then
                                                r.ImGui_DrawList_AddTextEx(WDL, Font_Andale_Mono_12, 12, Win_L + D.L[i],
                                                    Win_T + D.T[i], D.clr[i] or 0xffffffff, D.Txt[i])
                                            end
                                        end
                                    end



                                    if FX.LayEdit == FxGUID and Draw.DrawMode[FxGUID] ~= true then -- Resize FX or title btn
                                        MouseX, MouseY = r.ImGui_GetMousePos(ctx)
                                        Win_L, Win_T = r.ImGui_GetItemRectMin(ctx)
                                        Win_R, _ = r.ImGui_GetItemRectMax(ctx); Win_B = Win_T + 220
                                        WinDrawList = r.ImGui_GetWindowDrawList(ctx)
                                        r.ImGui_DrawList_AddRectFilled(WinDrawList, Win_L or 0, Win_T or 0, Win_R or 0,
                                            Win_B, 0x00000055)
                                        --draw grid

                                        if r.ImGui_IsKeyPressed(ctx, 189) then
                                            LE.GridSize = LE.GridSize + 5
                                        elseif r.ImGui_IsKeyPressed(ctx, 187) then
                                            LE.GridSize = LE.GridSize - 5
                                        end

                                        for i = 0, FX.Width[FXGUID[FX_Idx]] or DefaultWidth, LE.GridSize do
                                            r
                                                .ImGui_DrawList_AddLine(WinDrawList, Win_L + i, Win_T, Win_L + i, Win_B,
                                                    0x44444455)
                                        end
                                        for i = 0, 220, LE.GridSize do
                                            r.ImGui_DrawList_AddLine(WinDrawList, Win_L,
                                                Win_T + i, Win_R, Win_T + i, 0x44444455)
                                        end

                                        r.ImGui_DrawList_AddLine(WinDrawList, Win_R - 3, Win_T, Win_R - 3, Win_B,
                                            0x66666677, 1)


                                        if r.ImGui_IsMouseHoveringRect(ctx, Win_R - 5, Win_T, Win_R + 5, Win_B) then
                                            r.ImGui_DrawList_AddLine(WinDrawList, Win_R - 3, Win_T, Win_R - 3, Win_B,
                                                0xffffffff, 3)
                                            r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_ResizeEW())

                                            if IsLBtnClicked then
                                                LE.ResizingFX = FX_Idx --@Todo change fxidx to fxguid
                                            end
                                        end


                                        if LE.ResizingFX == FX_Idx and IsLBtnHeld then
                                            r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_ResizeEW())

                                            r.ImGui_DrawList_AddRectFilled(WinDrawList, Win_L or 0, Win_T or 0,
                                                Win_R or 0, Win_B, 0x00000055)
                                            local MsDragDeltaX, MsDragDeltaY = r.ImGui_GetMouseDragDelta(ctx); local Dx, Dy =
                                                r.ImGui_GetMouseDelta(ctx)
                                            if not FX.Width[FXGUID[FX_Idx]] then FX.Width[FXGUID[FX_Idx]] = DefaultWidth end
                                            FX.Width[FXGUID[FX_Idx]] = FX.Width[FXGUID[FX_Idx]] + Dx; LE.BeenEdited = true
                                        end
                                        if not IsLBtnHeld then LE.ResizingFX = nil end
                                    end


                                    if FX.Enable[FX_Idx] == nil then
                                        FX.Enable[FX_Idx] = reaper.TrackFX_GetEnabled(LT_Track, FX_Idx)
                                    end

                                    reaper.ImGui_SameLine(ctx, nil, 0)
                                    if FX.LayEdit == FxGUID and Draw.DrawMode[FxGUID] ~= true then
                                        r.ImGui_BeginDisabled(ctx); R, T = r.ImGui_GetItemRectMax(ctx)
                                    end

                                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), FX[FxGUID].TitleClr or 0x22222233)
                                    if FX[FxGUID].TitleClr then
                                        WinbtnClrPop = 3
                                        if not FX[FxGUID].TitleClrHvr then
                                            FX[FxGUID].TitleClrAct, FX[FxGUID].TitleClrHvr = Generate_Active_And_Hvr_CLRs(
                                                FX[FxGUID].TitleClr)
                                        end
                                        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(),
                                            FX[FxGUID].TitleClrHvr or 0x22222233)
                                        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),
                                            FX[FxGUID].TitleClrAct or 0x22222233)
                                    else
                                        WinbtnClrPop = 1
                                    end

                                    local WindowBtn
                                    --[[ r.ImGui_PushStyleColor(ctx, ) ]]
                                    if FX[FxGUID].Collapse ~= true then
                                        if string.find(FX_Name, 'Pro Q 3') ~= nil then
                                            WindowBtn = r.ImGui_Button(ctx, 'Pro-Q 3' .. '##', 60, 20) -- create window name button
                                            ProQ_TitlePosX_L, ProQ_TitlePosY_T = reaper.ImGui_GetItemRectMin(ctx)
                                            ProQ_TitlePosX_R, ProQ_TitlePosY_B = reaper.ImGui_GetItemRectMax(ctx)
                                        elseif string.find(FX_Name, 'Pro C 2') ~= nil then
                                            WindowBtn = reaper.ImGui_Button(ctx, 'Pro-C 2' .. '##', 60, 20) -- create window name button
                                        else
                                            if DebugMode then
                                                FX.Win_Name[FX_Idx] = FxGUID
                                                WindowBtn = reaper.ImGui_Button(ctx, FxGUID .. '## ',
                                                    FX.TitleWidth[FxGUID] or DefaultWidth - 30, 20) -- create window name button
                                            else
                                                WindowBtn = r.ImGui_Button(ctx,
                                                    (FX[FxGUID].CustomTitle or FX.Win_Name[FX_Idx] or '') .. '## ',
                                                    FX.TitleWidth[FxGUID] or DefaultWidth - 30, 20) -- create window name button
                                            end
                                        end
                                        if r.ImGui_IsItemHovered(ctx) and FindStringInTable(SpecialLayoutFXs, FX_Name) == false then
                                            FX[FxGUID].TtlHvr = true
                                            TtlR, TtlB = r.ImGui_GetItemRectMax(ctx)
                                            if r.ImGui_IsMouseHoveringRect(ctx, TtlR - 20, TtlB - 20, TtlR, TtlB) then
                                                r.ImGui_DrawList_AddRectFilled(WDL, TtlR, TtlB, TtlR - 20, TtlB - 20,
                                                    getClr(r.ImGui_Col_ButtonHovered()))
                                                r.ImGui_DrawList_AddRect(WDL, TtlR, TtlB, TtlR - 20, TtlB - 19,
                                                    getClr(r.ImGui_Col_Text()))
                                                r.ImGui_DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 20, TtlR - 15,
                                                    TtlB - 20, getClr(r.ImGui_Col_Text()), '+')
                                                if IsLBtnClicked then
                                                    r.ImGui_OpenPopup(ctx, 'Add Parameter' .. FxGUID)
                                                    r.ImGui_SetNextWindowPos(ctx, TtlR, TtlB)
                                                    AddPrmPopupOpen = FxGUID
                                                end
                                            end
                                        else
                                            FX[FxGUID].TtlHvr = nil
                                        end
                                    else -- if collapsed
                                        FX.WidthCollapse[FxGUID] = 27

                                        local Name = ChangeFX_Name(FX_Name)

                                        local Name = Name:gsub('%S+', { ['Valhalla'] = "", ['FabFilter'] = "" })
                                        local Name = Name:gsub('-', '|')
                                        --if Name:find('FabFilter Pro%-C 2')  then Name = 'Pro|C 2' end
                                        local Name_V = Name:gsub("(.)", "%1\n")
                                        local Name_V_NoManuFacturer = Name_V:gsub("%b()", "")
                                        reaper.ImGui_PushStyleVar(ctx, BtnTxtAlign, 0.5, 0.2) --StyleVar#3
                                        r.ImGui_SameLine(ctx, nil, 0)

                                        WindowBtn = r.ImGui_Button(ctx, Name_V_NoManuFacturer, 25, 220)


                                        r.ImGui_PopStyleVar(ctx)             --StyleVar#3 POP
                                    end
                                    r.ImGui_PopStyleColor(ctx, WinbtnClrPop) -- win btn clr
                                    HighlightSelectedItem(nil, 0xffffff11, -1, L, T, R, B, h, w, 1, 1, 'GetItemRect', WDL,
                                        FX.Round[FxGUID] --[[rounding]])


                                    r.ImGui_SetNextWindowSizeConstraints(ctx, AddPrmWin_W or 50, 50, 9999, 500)
                                    local R_ClickOnWindowBtn = r.ImGui_IsItemClicked(ctx, 1)
                                    local L_ClickOnWindowBtn = r.ImGui_IsItemClicked(ctx)

                                    if R_ClickOnWindowBtn and Mods == Ctrl then
                                        r.ImGui_OpenPopup(ctx, 'Fx Module Menu')
                                    elseif R_ClickOnWindowBtn and Mods == 0 then
                                        FX[FxGUID].Collapse = toggle(FX[FxGUID].Collapse)
                                        if not FX[FxGUID].Collapse then FX.WidthCollapse[FxGUID] = nil end
                                    elseif R_ClickOnWindowBtn and Mods == Alt then
                                        -- check if all are collapsed


                                        BlinkFX = ToggleCollapseAll()
                                    elseif WindowBtn and Mods == 0 then
                                        openFXwindow(LT_Track, FX_Idx)
                                    elseif WindowBtn and Mods == Shift then
                                        ToggleBypassFX(LT_Track, FX_Idx)
                                    elseif WindowBtn and Mods == Alt then
                                        DeleteFX(FX_Idx)
                                    end

                                    if r.ImGui_IsItemHovered(ctx) then
                                        HintMessage =
                                        'Mouse: L=Open FX Window | Shift+L = Toggle Bypass | Alt+L = Delete | R = Collapse | Alt+R = Collapse All'
                                    end


                                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Border(), getClr(r.ImGui_Col_FrameBg()))


                                    -- Add Prm popup
                                    PrmFilter = r.ImGui_CreateTextFilter(PrmFilterTxt)
                                    if r.ImGui_BeginPopup(ctx, 'Add Parameter' .. FxGUID, r.ImGui_WindowFlags_AlwaysVerticalScrollbar()) then
                                        AddPrmPopupOpen = FxGUID
                                        if not PrmFilterTxt then AddPrmWin_W, AddPrmWin_H = r.ImGui_GetWindowSize(ctx) end
                                        r.ImGui_SetWindowSize(ctx, 500, 500, condIn)

                                        local Ct = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                                        local CheckBox, rv = {}, {}

                                        r.ImGui_SetNextItemWidth(ctx, 60)

                                        if not FX[FxGUID].NotFirstOpenPrmWin then
                                            r.ImGui_SetKeyboardFocusHere(ctx,
                                                offsetIn)
                                        end

                                        if r.ImGui_TextFilter_Draw(PrmFilter, ctx, '##PrmFilterTxt', -1 - (SpaceForBtn or 0)) then
                                            PrmFilterTxt = r.ImGui_TextFilter_Get(PrmFilter)
                                            r.ImGui_TextFilter_Set(PrmFilter, PrmFilterTxt)
                                        end

                                        for i = 1, Ct, 1 do
                                            if FX[FxGUID][i] then
                                                CheckBox[FX[FxGUID][i].Num] = true
                                            end
                                        end

                                        for i = 1, Ct, 1 do
                                            local P_Name = select(2, r.TrackFX_GetParamName(LT_Track, FX_Idx, i - 1))
                                            if r.ImGui_TextFilter_PassFilter(PrmFilter, P_Name) then
                                                rv[i], CheckBox[i - 1] = r.ImGui_Checkbox(ctx, (i - 1) .. '. ' .. P_Name,
                                                    CheckBox[i - 1])
                                                if rv[i] then
                                                    local RepeatPrmFound

                                                    for I = 1, Ct, 1 do
                                                        if FX[FxGUID][I] then
                                                            if FX[FxGUID][I].Num == i - 1 then RepeatPrmFound = I end
                                                        end
                                                    end
                                                    if RepeatPrmFound then
                                                        DeletePrm(FxGUID, RepeatPrmFound, FX_Idx)
                                                    else
                                                        StoreNewParam(FxGUID, P_Name, i - 1, FX_Idx, true)
                                                        SyncTrkPrmVtoActualValue()
                                                    end
                                                end
                                            end
                                        end
                                        FX[FxGUID].NotFirstOpenPrmWin = true
                                        r.ImGui_EndPopup(ctx)
                                    elseif AddPrmPopupOpen == FxGUID then
                                        PrmFilterTxt = nil
                                        FX[FxGUID].NotFirstOpenPrmWin = nil
                                    end


                                    r.ImGui_PopStyleColor(ctx)


                                    if FX.LayEdit == FxGUID and Draw.DrawMode[FxGUID] ~= true then
                                        local L, T = r.ImGui_GetItemRectMin(ctx); local R, _ = r.ImGui_GetItemRectMax(
                                            ctx); B = T + 20
                                        r.ImGui_DrawList_AddCircleFilled(WinDrawList, R, T + 10, 3, 0x999999ff)
                                        r.ImGui_DrawList_AddRect(WinDrawList, L, T, R, T + 20, 0x999999ff)

                                        if MouseX > L and MouseX < R and MouseY > T and MouseY < B then
                                            r.ImGui_DrawList_AddRectFilled(WinDrawList, L, T, R, T + 20, 0x99999955)
                                            if IsLBtnClicked then
                                                LE.SelectedItem = 'Title'
                                                LE.ChangingTitleSize = true
                                                LE.MouseX_before, _ = r.ImGui_GetMousePos(ctx)
                                            elseif IsRBtnClicked then
                                                r.ImGui_OpenPopup(ctx, 'Fx Module Menu')
                                            end
                                        end

                                        if LE.SelectedItem == 'Title' then
                                            r.ImGui_DrawList_AddRect(WinDrawList, L, T, R,
                                                T + 20, 0x999999ff)
                                        end

                                        if MouseX > R - 5 and MouseX < R + 5 and MouseY > T and MouseY < B then --if hover on right edge
                                            if IsLBtnClicked then LE.ChangingTitleSize = true end
                                        end

                                        if LBtnDrag and LE.ChangingTitleSize then
                                            r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_ResizeEW())
                                            DeltaX, DeltaY = r.ImGui_GetMouseDelta(ctx)
                                            local AddedDelta = AddedDelta or 0 + DeltaX
                                            LE.MouseX_after, _ = r.ImGui_GetMousePos(ctx)
                                            local MouseDiff = LE.MouseX_after - LE.MouseX_before

                                            if FX.TitleWidth[FxGUID] == nil then
                                                FX.TitleWidth[FxGUID] = DefaultWidth -
                                                    30
                                            end
                                            if Mods == 0 then
                                                if MouseDiff > LE.GridSize then
                                                    FX.TitleWidth[FxGUID] = FX.TitleWidth[FxGUID] + LE.GridSize; LE.MouseX_before =
                                                        r.ImGui_GetMousePos(ctx); LE.BeenEdited = true
                                                elseif MouseDiff < -LE.GridSize then
                                                    FX.TitleWidth[FxGUID] = FX.TitleWidth[FxGUID] - LE.GridSize; LE.MouseX_before =
                                                        r.ImGui_GetMousePos(ctx); LE.BeenEdited = true
                                                end
                                            end
                                            if Mods == Shift then
                                                FX.TitleWidth[FxGUID] = FX.TitleWidth[FxGUID] + DeltaX; LE.BeenEdited = true
                                            end
                                        end
                                        if IsLBtnHeld == false then LE.ChangingTitleSize = nil end

                                        r.ImGui_EndDisabled(ctx)
                                    end








                                    if DebugMode and r.ImGui_IsItemHovered(ctx) then tooltip(FX_Idx) end
                                    if DebugMode and r.ImGui_IsKeyDown(ctx, 84) then tooltip(TrkID) end





                                    --r.Undo_OnStateChangeEx(string descchange, integer whichStates, integer trackparm) -- @todo Detect FX deletion






                                    if r.ImGui_BeginPopup(ctx, 'Fx Module Menu') then
                                        if not FX[FxGUID].MorphA then
                                            if r.ImGui_Button(ctx, 'Preset Morphing', 160) then
                                                FX[FxGUID].MorphA = {}
                                                FX[FxGUID].MorphB = {}
                                                local PrmCount = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                                                for i = 0, PrmCount - 4, 1 do
                                                    local Prm_Val, minval, maxval = reaper.TrackFX_GetParamNormalized(
                                                        LT_Track, FX_Idx, i)
                                                    FX[FxGUID].MorphA[i] = Prm_Val
                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                        'P_EXT: FX Morph A' .. i .. FxGUID, Prm_Val, true)
                                                end
                                                RestoreBlacklistSettings(FxGUID, FX_Idx, LT_Track, PrmCount)
                                                --[[ r.SetProjExtState(r0oj, 'FX Devices', string key, string value) ]]

                                                r.ImGui_CloseCurrentPopup(ctx)
                                            end
                                        else
                                            if not FX[FxGUID].MorphHide then
                                                if r.ImGui_Button(ctx, 'Hide Morph Slider', 160) then
                                                    FX[FxGUID].MorphHide = true
                                                    r.ImGui_CloseCurrentPopup(ctx)
                                                end
                                            else
                                                if r.ImGui_Button(ctx, 'Show Morph Slider', 160) then
                                                    FX[FxGUID].MorphHide = nil
                                                    r.ImGui_CloseCurrentPopup(ctx)
                                                end
                                            end
                                        end

                                        r.ImGui_SameLine(ctx)
                                        if not FX[FxGUID].MorphA then
                                            r.ImGui_BeginDisabled(ctx)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),
                                                getClr(r.ImGui_Col_TextDisabled()))
                                        end
                                        if IconBtn(20, 20, 'Y') then -- settings icon
                                            if OpenMorphSettings then
                                                OpenMorphSettings = FxGUID
                                            else
                                                OpenMorphSettings =
                                                    FxGUID
                                            end
                                            local Ct = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                                            FX[FxGUID].PrmList = FX[FxGUID].PrmList or {}
                                            for i = 0, Ct - 4, 1 do --get param names
                                                FX[FxGUID].PrmList[i]      = FX[FxGUID].PrmList[i] or {}
                                                local rv, name             = r.TrackFX_GetParamName(LT_Track, FX_Idx, i)
                                                FX[FxGUID].PrmList[i].Name = name
                                            end
                                            r.ImGui_CloseCurrentPopup(ctx)
                                        end
                                        if not FX[FxGUID].MorphA then
                                            r.ImGui_EndDisabled(ctx)
                                            r.ImGui_PopStyleColor(ctx)
                                        end



                                        if r.ImGui_Button(ctx, 'Layout Edit mode', -FLT_MIN) then
                                            if not FX.LayEdit then
                                                FX.LayEdit = FxGUID
                                            else
                                                FX.LayEdit = false
                                            end
                                            CloseLayEdit = nil
                                            r.ImGui_CloseCurrentPopup(ctx)
                                            if Draw.DrawMode[FxGUID] then Draw.DrawMode[FxGUID] = nil end
                                        end


                                        if r.ImGui_Button(ctx, 'Save all values as default', -FLT_MIN) then
                                            local dir_path = ConcatPath(reaper.GetResourcePath(), 'Scripts',
                                                'ReaTeam Scripts', 'FX', 'BryanChi_FX Devices')
                                            local file_path = ConcatPath(dir_path, 'FX Default Values.ini')
                                            local file = io.open(file_path, 'a+')

                                            if file then
                                                local FX_Name = ChangeFX_Name(FX_Name)
                                                Content = file:read('*a')
                                                local Ct = Content

                                                local pos = Ct:find(FX_Name)
                                                if pos then
                                                    file:seek('set', pos - 1)
                                                else
                                                    file:seek('end')
                                                end

                                                file:write(FX_Name, '\n')
                                                local PrmCount = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                                                PrmCount = PrmCount - 4
                                                file:write('Number of Params: ', PrmCount, '\n')

                                                local function write(i, name, Value)
                                                    file:write(i, '. ', name, ' = ', Value or '', '\n')
                                                end

                                                for i = 0, PrmCount, 1 do
                                                    local V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                                                    local _, N = r.TrackFX_GetParamName(LT_Track, FX_Idx, i)
                                                    write(i, N, V)
                                                end

                                                file:write('\n')


                                                file:close()
                                            end
                                            r.ImGui_CloseCurrentPopup(ctx)
                                        end



                                        if FX.Def_Type[FxGUID] ~= 'Knob' then
                                            r.ImGui_Text(ctx, 'Default Sldr Width:')
                                            r.ImGui_SameLine(ctx)
                                            local SldrW_DrgSpd
                                            if Mods == Shift then SldrW_DrgSpd = 1 else SldrW_DrgSpd = LE.GridSize end
                                            r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)


                                            Edited, FX.Def_Sldr_W[FxGUID] = r.ImGui_DragInt(ctx,
                                                '##' .. FxGUID .. 'Default Width', FX.Def_Sldr_W[FxGUID] or 160,
                                                LE.GridSize, 50, 300)


                                            if Edited then
                                                r.SetProjExtState(0, 'FX Devices',
                                                    'Default Slider Width for FX:' .. FxGUID, FX.Def_Sldr_W[FxGUID])
                                            end
                                        end



                                        r.ImGui_Text(ctx, 'Default Param Type:')
                                        r.ImGui_SameLine(ctx)
                                        r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)


                                        if r.ImGui_BeginCombo(ctx, '## P type', FX.Def_Type[FxGUID] or 'Slider', r.ImGui_ComboFlags_NoArrowButton()) then
                                            if r.ImGui_Selectable(ctx, 'Slider') then
                                                FX.Def_Type[FxGUID] = 'Slider'
                                                r.SetProjExtState(0, 'FX Devices', 'Default Param type for FX:' .. FxGUID,
                                                    FX.Def_Type[FxGUID])
                                            elseif r.ImGui_Selectable(ctx, 'Knob') then
                                                FX.Def_Type[FxGUID] = 'Knob'
                                                r.SetProjExtState(0, 'FX Devices', 'Default Param type for FX:' .. FxGUID,
                                                    FX.Def_Type[FxGUID])
                                            elseif r.ImGui_Selectable(ctx, 'Drag') then
                                                FX.Def_Type[FxGUID] = 'Drag'
                                                r.SetProjExtState(0, 'FX Devices', 'Default Param type for FX:' .. FxGUID,
                                                    FX.Def_Type[FxGUID])
                                            end
                                            r.ImGui_EndCombo(ctx)
                                        end
                                        r.ImGui_EndPopup(ctx)
                                    end
                                    FXModuleMenu_W, FXModuleMenu_H = r.ImGui_GetItemRectSize(ctx)


                                    if OpenMorphSettings then
                                        Open, Oms = r.ImGui_Begin(ctx, 'Preset Morph Settings ', Oms,
                                            r.ImGui_WindowFlags_NoCollapse() + r.ImGui_WindowFlags_NoDocking())
                                        if Oms then
                                            if FxGUID == OpenMorphSettings then
                                                r.ImGui_Text(ctx, 'Set blacklist parameters here: ')
                                                local SpaceForBtn
                                                Filter = r.ImGui_CreateTextFilter(FilterTxt)
                                                r.ImGui_Text(ctx, 'Filter :')
                                                r.ImGui_SameLine(ctx)
                                                if FilterTxt then SpaceForBtn = 170 end
                                                if r.ImGui_TextFilter_Draw(Filter, ctx, '##', -1 - (SpaceForBtn or 0)) then
                                                    FilterTxt = r.ImGui_TextFilter_Get(Filter)
                                                    reaper.ImGui_TextFilter_Set(Filter, Txt)
                                                end
                                                if FilterTxt then
                                                    SL()
                                                    BL_All = r.ImGui_Button(ctx, 'Blacklist all results')
                                                end

                                                r.ImGui_Text(ctx, 'Save morphing settings to : ')
                                                SL()
                                                local Save_FX = r.ImGui_Button(ctx, 'FX Instance', 80)
                                                SL()
                                                local Save_Proj = r.ImGui_Button(ctx, 'Project', 80)
                                                SL()
                                                local Save_Glob = r.ImGui_Button(ctx, 'Global', 80)
                                                SL()
                                                local FxNam = FX.Win_Name_S[FX_Idx]:gsub("%b()", "")
                                                demo.HelpMarker(
                                                    'FX Instance: \nBlacklist will only apply to the current instance of' ..
                                                    FxNam ..
                                                    '\n\nProject:\nBlacklist will apply to all instances of ' ..
                                                    FxNam ..
                                                    'in the current project\n\nGlobal:\nBlacklist will be applied to all instances of ' ..
                                                    FxNam ..
                                                    ' across all projects.\n\nOrder of precedence goes from: FX Instance -> Project -> Global')



                                                if Save_FX or Save_Proj or Save_Glob then
                                                    Tooltip_Timer = r.time_precise()
                                                    TTP_x, TTP_y = r.ImGui_GetMousePos(ctx)
                                                    r.ImGui_OpenPopup(ctx, '## Successfully saved preset morph')
                                                end

                                                if Tooltip_Timer then
                                                    if r.ImGui_BeginPopupModal(ctx, '## Successfully saved preset morph', nil, r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_NoResize()) then
                                                        r.ImGui_Text(ctx, 'Successfully saved ')
                                                        if r.ImGui_IsMouseClicked(ctx, 0) then
                                                            r.ImGui_CloseCurrentPopup(
                                                                ctx)
                                                        end
                                                        r.ImGui_EndPopup(ctx)
                                                    end

                                                    if Tooltip_Timer + 3 < r.time_precise() then
                                                        Tooltip_Timer = nil
                                                        TTP_x = nil
                                                        TTP_y = nil
                                                    end
                                                end

                                                --


                                                if not FX[FxGUID].PrmList[1].Name then
                                                    FX[FxGUID].PrmList = FX[FxGUID].PrmList or {}
                                                    --[[ local Ct = r.TrackFX_GetNumParams(LT_Track, FX_Idx)
                                                    for i=0, Ct-4, 1 do
                                                        FX[FxGUID].PrmList[i]=FX[FxGUID].PrmList[i] or {}
                                                        local rv, name = r.TrackFX_GetParamName(LT_Track, FX_Idx, i)
                                                        FX[FxGUID].PrmList[i].Name  = name
                                                    end ]]

                                                    RestoreBlacklistSettings(FxGUID, FX_Idx, LT_Track,
                                                        r.TrackFX_GetNumParams(LT_Track, FX_Idx), FX_Name)
                                                else
                                                    r.ImGui_BeginTable(ctx, 'Parameter List', 5,
                                                        r.ImGui_TableFlags_Resizable())
                                                    --r.ImGui_TableSetupColumn( ctx, 'BL',  flagsIn, 20,  user_idIn)

                                                    r.ImGui_TableHeadersRow(ctx)
                                                    r.ImGui_SetNextItemWidth(ctx, 20)
                                                    r.ImGui_TableSetColumnIndex(ctx, 0)

                                                    IconBtn(20, 20, 'M', 0x00000000)

                                                    r.ImGui_TableSetColumnIndex(ctx, 1)
                                                    r.ImGui_AlignTextToFramePadding(ctx)
                                                    r.ImGui_Text(ctx, 'Parameter Name ')
                                                    r.ImGui_TableSetColumnIndex(ctx, 2)
                                                    r.ImGui_AlignTextToFramePadding(ctx)
                                                    r.ImGui_Text(ctx, 'A')
                                                    r.ImGui_TableSetColumnIndex(ctx, 3)
                                                    r.ImGui_AlignTextToFramePadding(ctx)
                                                    r.ImGui_Text(ctx, 'B')
                                                    r.ImGui_TableNextRow(ctx)
                                                    r.ImGui_TableSetColumnIndex(ctx, 0)




                                                    if --[[Last Touch]] LT_ParamNum and LT_FXGUID == FxGUID then
                                                        local P = FX[FxGUID].PrmList
                                                        local N = math.max(LT_ParamNum, 1)
                                                        r.ImGui_TableSetBgColor(ctx, 1,
                                                            getClr(r.ImGui_Col_TabUnfocused()))
                                                        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 0, 9)

                                                        rv, P[N].BL = r.ImGui_Checkbox(ctx, '##' .. N, P[N].BL)
                                                        if P[N].BL then r.ImGui_BeginDisabled(ctx) end

                                                        r.ImGui_TableSetColumnIndex(ctx, 1)
                                                        r.ImGui_Text(ctx, N .. '. ' .. (P[N].Name or ''))


                                                        ------- A --------------------
                                                        r.ImGui_TableSetColumnIndex(ctx, 2)
                                                        r.ImGui_Text(ctx, 'A:')
                                                        SL()
                                                        r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)

                                                        local i = LT_ParamNum or 0
                                                        local OrigV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                                                        if not P.FormatV_A and FX[FxGUID].MorphA[1] then
                                                            P.FormatV_A =
                                                                GetFormatPrmV(FX[FxGUID].MorphA[i], OrigV, i)
                                                        end


                                                        P.Drag_A, FX[FxGUID].MorphA[i] = r.ImGui_DragDouble(ctx,
                                                            '## MorphVal_A' .. i, FX[FxGUID].MorphA[i], 0.01, 0, 1,
                                                            P.FormatV_A or '')
                                                        if P.Drag_A then
                                                            P.FormatV_A = GetFormatPrmV(FX[FxGUID].MorphA[i], OrigV, i)
                                                        end

                                                        SL()
                                                        --------- B --------------------
                                                        r.ImGui_TableSetColumnIndex(ctx, 3)
                                                        r.ImGui_Text(ctx, 'B:')
                                                        SL()

                                                        local OrigV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                                                        r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
                                                        if not P.FormatV_B and FX[FxGUID].MorphB[1] then
                                                            P.FormatV_B = GetFormatPrmV(FX[FxGUID].MorphB[i], OrigV, i)
                                                        end


                                                        P.Drag_B, FX[FxGUID].MorphB[i] = r.ImGui_DragDouble(ctx,
                                                            '## MorphVal_B' .. i, FX[FxGUID].MorphB[i], 0.01, 0, 1,
                                                            P.FormatV_B)
                                                        if P.Drag_B then
                                                            P.FormatV_B = GetFormatPrmV(FX[FxGUID].MorphB[i], OrigV, i)
                                                        end


                                                        if P[N].BL then r.ImGui_EndDisabled(ctx) end
                                                        --HighlightSelectedItem( 0xffffff33 , OutlineClr, 1, L,T,R,B,h,w, H_OutlineSc, V_OutlineSc,'GetItemRect', Foreground)

                                                        r.ImGui_PopStyleVar(ctx)
                                                        r.ImGui_TableNextRow(ctx)
                                                        r.ImGui_TableSetColumnIndex(ctx, 0)
                                                    end
                                                    local Load_FX_Proj_Glob
                                                    local _, FXsBL = r.GetSetMediaTrackInfo_String(LT_Track,
                                                        'P_EXT: Morph_BL' .. FxGUID, '', false)
                                                    if FXsBL == 'Has Blacklist saved to FX' then -- if there's FX-specific BL settings
                                                        Load_FX_Proj_Glob = 'FX'
                                                    else
                                                        local _, whether = r.GetProjExtState(0,
                                                            'FX Devices - Preset Morph',
                                                            'Whether FX has Blacklist' .. (FX.Win_Name_S[FX_Idx] or ''))
                                                        if whether == 'Yes' then Load_FX_Proj_Glob = 'Proj' end
                                                    end

                                                    local TheresBL = TheresBL or {}
                                                    local hasBL
                                                    for i, v in ipairs(FX[FxGUID].PrmList) do
                                                        local P = FX[FxGUID].PrmList[i - 1]
                                                        local prm = FX[FxGUID].PrmList

                                                        if r.ImGui_TextFilter_PassFilter(Filter, P.Name) --[[ and (i~=LT_ParamNum and LT_FXGUID==FxGUID) ]] then
                                                            i = i - 1
                                                            if prm[i].BL == nil then
                                                                if Load_FX_Proj_Glob == 'FX' then
                                                                    local _, V = r.GetSetMediaTrackInfo_String(LT_Track,
                                                                        'P_EXT: Morph_BL' .. FxGUID .. i, '', false)
                                                                    if V == 'Blacklisted' then prm[i].BL = true end
                                                                end
                                                                --[[  elseif Load_FX_Proj_Glob== 'Proj' then
                                                                    local rv, BLprm  = r.GetProjExtState(0,'FX Devices - Preset Morph', FX.Win_Name_S[FX_Idx]..' Blacklist '..i)
                                                                    if BLprm~='' and BLprm then  BLpm = tonumber(BLprm)
                                                                        if BLprm then prm[1].BL = true  end
                                                                    end
                                                                end ]]
                                                            end
                                                            if BL_All --[[BL all filtered params ]] then if P.BL then P.BL = false else P.BL = true end end
                                                            rv, prm[i].BL = r.ImGui_Checkbox(ctx, '## BlackList' .. i,
                                                                prm[i].BL)

                                                            r.ImGui_TableSetColumnIndex(ctx, 1)
                                                            if P.BL then
                                                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),
                                                                    getClr(r.ImGui_Col_TextDisabled()))
                                                            end


                                                            r.ImGui_Text(ctx, i .. '. ' .. (P.Name or ''))



                                                            ------- A --------------------
                                                            r.ImGui_TableSetColumnIndex(ctx, 2)
                                                            r.ImGui_Text(ctx, 'A:')
                                                            SL()

                                                            local OrigV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                                i)
                                                            r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
                                                            if not P.FormatV_A and FX[FxGUID].MorphA[1] then
                                                                P.FormatV_A =
                                                                    GetFormatPrmV(FX[FxGUID].MorphA[i + 1], OrigV, i)
                                                            end


                                                            P.Drag_A, FX[FxGUID].MorphA[i] = r.ImGui_DragDouble(ctx,
                                                                '## MorphVal_A' .. i, FX[FxGUID].MorphA[i], 0.01, 0, 1,
                                                                P.FormatV_A or '')
                                                            if P.Drag_A then
                                                                P.FormatV_A = GetFormatPrmV(FX[FxGUID].MorphA[i], OrigV,
                                                                    i)
                                                                --[[ r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,i, FX[FxGUID].MorphA[i])
                                                                _,P.FormatV_A = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,i)
                                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,i, OrigV)  ]]
                                                            end

                                                            SL()

                                                            --------- B --------------------
                                                            r.ImGui_TableSetColumnIndex(ctx, 3)
                                                            r.ImGui_Text(ctx, 'B:')
                                                            SL()

                                                            local OrigV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                                i)
                                                            r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
                                                            if not P.FormatV_B and FX[FxGUID].MorphB[1] then
                                                                P.FormatV_B = GetFormatPrmV(FX[FxGUID].MorphB[i] or 0,
                                                                    OrigV, i)
                                                            end

                                                            P.Drag_B, FX[FxGUID].MorphB[i] = r.ImGui_DragDouble(ctx,
                                                                '## MorphVal_B' .. i, FX[FxGUID].MorphB[i], 0.01, 0, 1,
                                                                P.FormatV_B)
                                                            if P.Drag_B then
                                                                P.FormatV_B = GetFormatPrmV(FX[FxGUID].MorphB[i], OrigV,
                                                                    i)
                                                            end


                                                            if Save_FX then
                                                                if P.BL then
                                                                    hasBL = true
                                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                                        'P_EXT: Morph_BL' .. FxGUID .. i, 'Blacklisted',
                                                                        true)
                                                                else
                                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                                        'P_EXT: Morph_BL' .. FxGUID .. i, '', true)
                                                                end
                                                                if hasBL then
                                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                                        'P_EXT: Morph_BL' .. FxGUID,
                                                                        'Has Blacklist saved to FX', true)
                                                                else
                                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                                        'P_EXT: Morph_BL' .. FxGUID, '', true)
                                                                end
                                                            elseif Save_Proj then
                                                                if P.BL then table.insert(TheresBL, i) end
                                                            elseif Save_Glob then
                                                                if P.BL then table.insert(TheresBL, i) end
                                                            end

                                                            r.ImGui_SetNextItemWidth(ctx, -1)

                                                            if P.BL then r.ImGui_PopStyleColor(ctx) end

                                                            r.ImGui_TableNextRow(ctx)
                                                            r.ImGui_TableSetColumnIndex(ctx, 0)
                                                        end
                                                    end

                                                    if Save_Proj then
                                                        if TheresBL[1] then
                                                            r.SetProjExtState(0, 'FX Devices - Preset Morph',
                                                                'Whether FX has Blacklist' .. FX.Win_Name_S[FX_Idx],
                                                                'Yes')
                                                        else
                                                            r.SetProjExtState(0, 'FX Devices - Preset Morph',
                                                                'Whether FX has Blacklist' .. FX.Win_Name_S[FX_Idx], 'No')
                                                        end
                                                        for i, V in ipairs(FX[FxGUID].MorphA) do
                                                            local PrmBLed
                                                            for I, v in ipairs(TheresBL) do
                                                                if i == v then PrmBLed = v end
                                                            end
                                                            if PrmBLed then
                                                                r.SetProjExtState(0, 'FX Devices - Preset Morph',
                                                                    FX.Win_Name_S[FX_Idx] .. ' Blacklist ' .. i, PrmBLed)
                                                            else
                                                                r.SetProjExtState(0, 'FX Devices - Preset Morph',
                                                                    FX.Win_Name_S[FX_Idx] .. ' Blacklist ' .. i, '')
                                                            end
                                                        end
                                                        --else r.SetProjExtState(0,'FX Devices - Preset Morph','Whether FX has Blacklist'..FX.Win_Name_S[FX_Idx], '')
                                                    elseif TheresBL[1] and Save_Glob then
                                                        file, file_path = CallFile('w', FX.Win_Name_S[FX_Idx] .. '.ini',
                                                            'Preset Morphing')
                                                        if file then
                                                            for i, V in ipairs(TheresBL) do
                                                                file:write(i, ' = ', V, '\n')
                                                            end
                                                            file:close()
                                                        end
                                                    end

                                                    r.ImGui_EndTable(ctx)
                                                end
                                            end
                                            r.ImGui_End(ctx)
                                        else
                                            r.ImGui_End(ctx)
                                            OpenMorphSettings = false
                                        end
                                    end

                                    ------------------------------------------
                                    ------ Collapse Window
                                    ------------------------------------------

                                    if FX_Idx == nil then FX_Idx = 1 end


                                    if R_Click_WindowBtnVertical then
                                        FX[FXGUID[FX_Idx]].Collapse = false
                                    end



                                    r.gmem_attach('ParamValues')
                                    FX.Win_Name_S[FX_Idx] = ChangeFX_Name(FX.Win_Name[FX_Idx])

                                    FX_Name = string.sub(FX_Name, 1, (string.find(FX_Name, '%(') or 30) - 1)
                                    FX_Name = string.gsub(FX_Name, '%-', ' ')





                                    ----==  Drag and drop----
                                    if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_AcceptNoDrawDefaultRect()) then
                                        DragFX_ID = FX_Idx
                                        r.ImGui_SetDragDropPayload(ctx, 'FX_Drag', FX_Idx)
                                        r.ImGui_EndDragDropSource(ctx)

                                        DragDroppingFX = true
                                        if IsAnyMouseDown == false then DragDroppingFX = false end
                                        HighlightSelectedItem(0xffffff22, 0xffffffff, 0, L, T, R, B, h, w, H_OutlineSc,
                                            V_OutlineSc, 'GetItemRect', WDL)
                                        Post_DragFX_ID = tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID])
                                    end

                                    if IsAnyMouseDown == false and DragDroppingFX == true then
                                        DragDroppingFX = false
                                    end

                                    ----Drag and drop END----

                                    r.ImGui_SameLine(ctx)

                                    --------------------------------
                                    ----Area right of window title
                                    --------------------------------
                                    function SyncWetValues()
                                        --when track change
                                        if Wet.Val[FX_Idx] == nil or TrkID ~= TrkID_End or FXCountEndLoop ~= Sel_Track_FX_Count then -- if it's nil
                                            SyncWetValues = true
                                        end

                                        if SyncWetValues == true then
                                            Wet.P_Num[FX_Idx] = reaper.TrackFX_GetParamFromIdent(LT_Track, FX_Idx, ':wet')
                                            Wet.Get = reaper.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                Wet.P_Num[FX_Idx])
                                            Wet.Val[FX_Idx] = Wet.Get
                                        end
                                        if SyncWetValues == true and FX_Idx == Sel_Track_FX_Count - 1 then
                                            SyncWetValues = false
                                        end
                                        if LT_ParamNum == Wet.P_Num[FX_Idx] and focusedFXState == 1 then
                                            Wet.Get = reaper.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                Wet.P_Num[FX_Idx])
                                            Wet.Val[FX_Idx] = Wet.Get
                                        elseif LT_ParamNum == FX[FxGUID].DeltaP then
                                            FX[FxGUID].DeltaP_V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                FX[FxGUID].DeltaP)
                                        end
                                    end

                                    if FindStringInTable(SpecialLayoutFXs, FX_Name) == false then
                                        SyncWetValues()

                                        if FX[FXGUID[FX_Idx]].Collapse ~= true then
                                            Wet.ActiveAny, Wet.Active, Wet.Val[FX_Idx] = Add_WetDryKnob(ctx, 'a', '',
                                                Wet.Val[FX_Idx] or 0, 0, 1, FX_Idx)
                                        end

                                        if r.ImGui_BeginDragDropTarget(ctx) then
                                            rv, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                                            if rv then
                                            end
                                            r.ImGui_EndDragDropTarget(ctx)
                                        end
                                    elseif string.find(FX_Name, 'Pro Q 3') ~= nil then
                                        if BandColor == nil then BandColor = 0x69B45D55 end
                                        _, _, color = determineBandColor(ProQ3.LT_EQBand[FXGUID[FX_Idx]])
                                        if color == nil then color = 0xffffffff end
                                        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), color)

                                        if ProQ3.LT_EQBand[FXGUID[FX_Idx]] ~= nil then
                                            Freq_LTBandNorm = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                13 * (ProQ3.LT_EQBand[FXGUID[FX_Idx]] - 1) + 2)
                                            Freq_LTBand = math.floor(x_to_freq(Freq_LTBandNorm * 340)) -- width
                                            ProQ3['Freq_LTBand - ' .. FXGUID[FX_Idx]] = Freq_LTBand
                                            local Gain = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                13 * (ProQ3.LT_EQBand[FXGUID[FX_Idx]] - 1) + 3)
                                            --Gain = tonumber(Gain)
                                            Gain = -30 + Gain * 60
                                            FreqValueDrag[FX_Idx] = Freq_LTBandNorm
                                            if Gain ~= nil then
                                                ProQ3['Gain_LTBand - ' .. FXGUID[FX_Idx]] = round(Gain, 1)
                                            end
                                        end



                                        r.ImGui_SetNextItemWidth(ctx, 60)
                                        if ProQ3['Freq_LTBand - ' .. FXGUID[FX_Idx]] ~= nil and ProQ3['Freq_LTBand - ' .. FXGUID[FX_Idx]] < 1000 then
                                            FreqLbl = ProQ3['Freq_LTBand - ' .. FXGUID[FX_Idx]] .. ' Hz'
                                        elseif ProQ3['Freq_LTBand - ' .. FXGUID[FX_Idx]] ~= nil and ProQ3['Freq_LTBand - ' .. FXGUID[FX_Idx]] > 1000 then
                                            FreqLbl = round(ProQ3['Freq_LTBand - ' .. FXGUID[FX_Idx]] / 1000, 2) ..
                                                ' kHz'
                                        end
                                        if ProQ3['Freq_LTBand - ' .. FXGUID[FX_Idx]] ~= nil then
                                            if Mods == Shift then
                                                DragSpeed = 0.003
                                            else
                                                DragSpeed = 0.008
                                            end
                                            FreqDragging, FreqValueDrag[FX_Idx] = r.ImGui_DragDouble(ctx, '##FreqDrag',
                                                FreqValueDrag[FX_Idx], DragSpeed, -1, 1, FreqLbl)
                                            ProQ3.FreqDragging = r.ImGui_IsItemActive(ctx)
                                            if FreqDragging then
                                                -- r.TrackFX_SetParamNormalized(LT_Track,FX_Idx,13*(ProQ3.LT_EQBand[FXGUID[FX_Idx]]-1) +2,FreqValueDrag[FX_Idx]  )
                                            end
                                        end

                                        r.ImGui_SameLine(ctx)
                                        r.ImGui_SetNextItemWidth(ctx, 60)
                                        if ProQ3['Gain_LTBand - ' .. FXGUID[FX_Idx]] ~= nil then
                                            _, ProQ3.GainDrag[FX_Idx] = r.ImGui_DragDouble(ctx, '##GainDrag',
                                                ProQ3.GainDrag[FX_Idx] or 0, 0.01, 0, 1,
                                                ProQ3['Gain_LTBand - ' .. FXGUID[FX_Idx]] .. 'dB')
                                            ProQ3.GainDragging = r.ImGui_IsItemActive(ctx)
                                        end

                                        r.ImGui_SameLine(ctx, 340 - 50)
                                        r.ImGui_SetNextItemWidth(ctx, 50)
                                        if ProQ3['scaleLabel' .. ' ID' .. FXGUID[FX_Idx]] ~= nil then
                                            DispRangeBtnClicked = r.ImGui_Button(ctx,
                                                '±' .. ProQ3['scaleLabel' .. ' ID' .. FXGUID[FX_Idx]] .. 'dB##' ..
                                                FX_Idx, 50, 20)
                                        end
                                        if DispRangeBtnClicked then
                                            r.ImGui_OpenPopup(ctx, 'ProQ Display Range ##' .. FX_Idx)
                                            local L, T = r.ImGui_GetItemRectMin(ctx)
                                            local W, H = r.ImGui_GetItemRectSize(ctx)
                                            r.ImGui_SetNextWindowPos(ctx, L, T + H)
                                            r.ImGui_SetNextWindowSize(ctx, W, H)
                                        end

                                        if focusedFXState == 1 and FX_Index_FocusFX == FX_Idx and LT_ParamNum == 331 then
                                            _, ProQ3.DspRange[FX_Idx] = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,
                                                331)
                                            ProQ3.DspRange[FX_Idx] = ProQ3.DspRange[FX_Idx]:gsub('dB', '')
                                            ProQ3.DspRange[FX_Idx] = tonumber(ProQ3.DspRange[FX_Idx])
                                            ProQ3['scaleLabel' .. ' ID' .. FXGUID[FX_Idx]] = ProQ3.DspRange[FX_Idx]
                                            ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] = syncProQ_DispRange(ProQ3
                                                .DspRange[FX_Idx])
                                        end



                                        if r.ImGui_BeginPopup(ctx, 'ProQ Display Range ##' .. FX_Idx) then
                                            if r.ImGui_Selectable(ctx, '±30dB') then
                                                ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] = 1
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 331, 1)
                                                r.ImGui_CloseCurrentPopup(ctx)
                                            end
                                            if r.ImGui_Selectable(ctx, '±12dB') then
                                                ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] = 2.5
                                                r.TrackFX_SetParam(LT_Track, FX_Idx, 331, 0.7)
                                                r.ImGui_CloseCurrentPopup(ctx)
                                            end
                                            if r.ImGui_Selectable(ctx, '±6 dB') then
                                                ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] = 5
                                                r.TrackFX_SetParam(LT_Track, FX_Idx, 331, 0.3)
                                                r.ImGui_CloseCurrentPopup(ctx)
                                            end
                                            if r.ImGui_Selectable(ctx, '±3 dB') then
                                                ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] = 10
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 331, 0)
                                                r.ImGui_CloseCurrentPopup(ctx)
                                            end

                                            reaper.ImGui_EndPopup(ctx)
                                        end
                                        if ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] == 1 then
                                            ProQ3['scaleLabel' .. ' ID' .. FXGUID[FX_Idx]] = 30
                                        elseif ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] == 2.5 then
                                            ProQ3['scaleLabel' .. ' ID' .. FXGUID[FX_Idx]] = 12
                                        elseif ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] == 5 then
                                            ProQ3['scaleLabel' .. ' ID' .. FXGUID[FX_Idx]] = 6
                                        elseif ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] == 10 then
                                            ProQ3['scaleLabel' .. ' ID' .. FXGUID[FX_Idx]] = 3
                                        else
                                            ProQ3['scaleLabel' .. ' ID' .. FXGUID[FX_Idx]] = 12
                                        end



                                        r.ImGui_PopStyleColor(ctx)
                                    elseif string.find(FX_Name, 'Pro C 2') ~= nil then
                                        Rounding = 3
                                        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameRounding(), Rounding)
                                        if not FX[FXGUID[FX_Idx]].Collapse then
                                            if not OverSampleValue then
                                                _, OverSampleValue = r
                                                    .TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, 40)
                                            end
                                            r.ImGui_SetNextItemWidth(ctx, 10)
                                            r.ImGui_PushFont(ctx, Font_Andale_Mono_10)
                                            MyText('Over:', nil, 0x818181ff)


                                            r.ImGui_SameLine(ctx, 96, nil)
                                            r.ImGui_SetNextItemWidth(ctx, 27)
                                            local Oversampling_Options = { 'Off', '2x', '4x' }
                                            local OS_V = { 0, 0.5, 1 }
                                            AddCombo(ctx, LT_Track, FX_Idx, 'OverSample##', 40, Oversampling_Options, 18,
                                                'Pro C 2', FxGUID, Fx_P or 1, OS_V)
                                            --r.ImGui_SameLine(ctx)
                                            --AddDrag(ctx,'##'..12,  Trk.Prm.V[F_Tp(12,FXGUID[FX_Idx])..TrkID] or '', Trk.Prm.V[F_Tp(12,FXGUID[FX_Idx])..TrkID] or 0, 0, 1, 12,FX_Idx, 34, 'style', 10)

                                            reaper.ImGui_PopFont(ctx)
                                            r.ImGui_SameLine(ctx, ProC.Width - 25)

                                            SyncWetValues()
                                            Wet.ActiveAny, Wet.Active, Wet.Val[FX_Idx] = Add_WetDryKnob(ctx, 'a', '',
                                                Wet.Val[FX_Idx] or 0, 0, 1, FX_Idx)
                                        end
                                        r.ImGui_PopStyleVar(ctx)
                                    end
                                    -- r.ImGui_PopStyleVar(ctx) --StyleVar#4  POP (Things in the header of FX window)

                                    ------------------------------------------
                                    ------ Generic FX's knobs and sliders area
                                    ------------------------------------------
                                    if not FX[FXGUID[FX_Idx]].Collapse and FindStringInTable(BlackListFXs, FX_Name) ~= true and FindStringInTable(SpecialLayoutFXs, FX_Name) == false then
                                        local WinP_X; local WinP_Y;
                                        --_, foo = AddKnob(ctx, 'test', foo or 0  , 0, 100 )
                                        if FX.Enable[FX_Idx] == true then
                                            -- Params Colors-----
                                            --[[ reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x32403aff)
                                            reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(), 0x44444488)

                                            times = 2 ]]
                                        else
                                            --[[ r.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x17171744)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), 0x66666644)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_SliderGrab(), 0x66666644)
                                            r.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(), 0x66666622)
                                            r.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), 0x44444422)
                                            times = 5 ]]
                                        end

                                        if FX.Round[FxGUID] then
                                            r.ImGui_PushStyleVar(ctx,
                                                r.ImGui_StyleVar_FrameRounding(), FX.Round[FxGUID])
                                        end
                                        if FX.GrbRound[FxGUID] then
                                            r.ImGui_PushStyleVar(ctx,
                                                r.ImGui_StyleVar_GrabRounding(), FX.GrbRound[FxGUID])
                                        end

                                        if FX.LayEdit == FxGUID or Draw.DrawMode[FxGUID] == true then
                                            r
                                                .ImGui_BeginDisabled(ctx, true)
                                        end
                                        if FX.LayEdit then
                                            LE.DragX, LE.DragY = r.ImGui_GetMouseDragDelta(ctx, 0)
                                        end

                                        ------------------------------------------------------
                                        -- Repeat as many times as stored Param on FX -------------
                                        ------------------------------------------------------
                                        --[[ for Fx_P, v in ipairs(FX[FxGUID])    do
                                            if not FX[FxGUID][Fx_P].Name then table.remove(FX[FxGUID],Fx_P) end
                                        end ]]
                                        for Fx_P, v in ipairs(FX[FxGUID]) do --parameter faders
                                            --FX[FxGUID][Fx_P]= FX[FxGUID][Fx_P] or {}

                                            local FP = FX[FxGUID][Fx_P]

                                            local F_Tp = FX.Prm.ToTrkPrm[FXGUID[FX_Idx] .. Fx_P]; local ID = FxGUID ..
                                                Fx_P
                                            Rounding = 0.5

                                            ParamX_Value = 'Param' ..
                                                tostring(FP.Name) .. 'On  ID:' .. tostring(Fx_P) .. 'value' .. FxGUID

                                            ----Default Layouts
                                            if not FP.PosX and not FP.PosY then
                                                if FP.Type == 'Slider' or (not FP.Type and not FX.Def_Type[FxGUID]) or FX.Def_Type[FxGUID] == 'Slider' or FP.Type == 'Drag' or (FX.Def_Type[FxGUID] == 'Drag' and FP.Type == nil) then
                                                    if Fx_P < 7 then
                                                        r.ImGui_SetCursorPos(ctx, 0, 30 * Fx_P)
                                                    elseif Fx_P > 6 and Fx_P <= 12 then
                                                        r.ImGui_SetCursorPos(ctx,
                                                            10 +
                                                            (FX[FxGUID][Fx_P - 6].Sldr_W or FX.Def_Sldr_W[FxGUID] or 160),
                                                            30 * (Fx_P - 6))
                                                    elseif Fx_P > 12 and Fx_P <= 18 then
                                                        r.ImGui_SetCursorPos(ctx,
                                                            20 +
                                                            (FX[FxGUID][Fx_P - 6].Sldr_W or FX.Def_Sldr_W[FxGUID] or 160) *
                                                            2, 30 * (Fx_P - 12))
                                                    elseif Fx_P > 18 then
                                                        r.ImGui_SetCursorPos(ctx,
                                                            30 +
                                                            (FX[FxGUID][Fx_P - 6].Sldr_W or FX.Def_Sldr_W[FxGUID] or 160) *
                                                            3, 30 * (Fx_P - 18))
                                                    end
                                                elseif FP.Type == 'V-Slider' or (FX.Def_Type[FxGUID] == 'V-Slider' and FP.Type == nil) then
                                                    r.ImGui_SetCursorPos(ctx, 17 * (Fx_P - 1), 30)
                                                elseif FP.Type == 'Knob' or (FX.Def_Type[FxGUID] == 'Knob' and FP.Type == nil) then
                                                    local KSz = Df.KnobSize
                                                    local G = 15
                                                    if Fx_P <= 3 then
                                                        r.ImGui_SetCursorPos(ctx, 0, 26 + (KSz + G) * (Fx_P - 1))
                                                    elseif Fx_P > 3 and Fx_P <= 6 then
                                                        r.ImGui_SetCursorPos(ctx, KSz, (26 + (KSz + G) * (Fx_P - 4)))
                                                    elseif Fx_P > 6 and Fx_P <= 9 then
                                                        r.ImGui_SetCursorPos(ctx, KSz * 2, 26 + (KSz + G) * (Fx_P - 7))
                                                    elseif Fx_P > 9 and Fx_P <= 12 then
                                                        r.ImGui_SetCursorPos(ctx, KSz * 3, 26 + (KSz + G) * (Fx_P - 10))
                                                    elseif Fx_P > 12 and Fx_P <= 15 then
                                                        r.ImGui_SetCursorPos(ctx, KSz * 4, 26 + KSz * (Fx_P - 13))
                                                    elseif Fx_P > 15 and Fx_P <= 18 then
                                                        r.ImGui_SetCursorPos(ctx, KSz * 5, 26 + KSz * (Fx_P - 16))
                                                    end
                                                end
                                            end

                                            if FP.PosX then r.ImGui_SetCursorPosX(ctx, FP.PosX) end
                                            if FP.PosY then r.ImGui_SetCursorPosY(ctx, FP.PosY) end

                                            rectminX, RectMinY = r.ImGui_GetItemRectMin(ctx)
                                            curX, CurY = r.ImGui_GetCursorPos(ctx)
                                            if CurY > 210 then
                                                r.ImGui_SetCursorPosY(ctx, 210)
                                                CurY = 210
                                            end
                                            if curX < 0 then
                                                r.ImGui_SetCursorPosX(ctx, 0)
                                            elseif curX > (FX.Width[FxGUID] or DefaultWidth) then
                                                r.ImGui_SetCursorPosX(ctx, (FX.Width[FxGUID] or DefaultWidth) - 10)
                                            end

                                            -- if prm has clr set, calculate colors for active and hvr clrs
                                            if FP.BgClr then
                                                local R, G, B, A = r.ImGui_ColorConvertU32ToDouble4(FP.BgClr)
                                                local HSV, _, H, S, V = r.ImGui_ColorConvertRGBtoHSV(R, G, B)
                                                local HvrV, ActV
                                                if V > 0.9 then
                                                    HvrV = V - 0.1
                                                    ActV = V - 0.5
                                                end
                                                local RGB, _, R, G, B = r.ImGui_ColorConvertHSVtoRGB(H, S, HvrV or V +
                                                    0.1)
                                                local HvrClr = r.ImGui_ColorConvertDouble4ToU32(R, G, B, A)
                                                local RGB, _, R, G, B = r.ImGui_ColorConvertHSVtoRGB(H, S,
                                                    ActV or V + 0.2)
                                                local ActClr = r.ImGui_ColorConvertDouble4ToU32(R, G, B, A)
                                                FP.BgClrHvr = HvrClr
                                                FP.BgClrAct = ActClr
                                            end


                                            --- if there's condition for parameters --------
                                            local CreateParam, ConditionPrms, Pass = nil, {}, {}
                                            local function CheckIfCreate(ConditionPrm, ConditionPrm_PID,
                                                                         ConditionPrm_V_Norm, ConditionPrm_V)
                                                local Pass
                                                if FP[ConditionPrm] then
                                                    if not FX[FxGUID][Fx_P][ConditionPrm_PID] then
                                                        for i, v in ipairs(FX[FxGUID]) do
                                                            if v.Num == FX[FxGUID][Fx_P][ConditionPrm] then
                                                                FX[FxGUID][Fx_P][ConditionPrm_PID] =
                                                                    i
                                                            end
                                                        end
                                                    end
                                                    local PID = FP[ConditionPrm_PID]

                                                    if FX[FxGUID][PID].ManualValues then
                                                        local V = round(
                                                            r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                                FP[ConditionPrm]),
                                                            3)
                                                        if FP[ConditionPrm_V_Norm] then
                                                            for i, v in ipairs(FP[ConditionPrm_V_Norm]) do
                                                                if V == round(v, 3) then Pass = true end
                                                            end
                                                        end
                                                    else
                                                        local _, V = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,
                                                            FP[ConditionPrm])
                                                        for i, v in ipairs(FP[ConditionPrm_V]) do
                                                            if V == v then Pass = true end
                                                        end
                                                    end
                                                else
                                                    Pass = true
                                                end
                                                return Pass
                                            end

                                            if FP['ConditionPrm'] then
                                                if CheckIfCreate('ConditionPrm', 'ConditionPrm_PID', 'ConditionPrm_V_Norm', 'ConditionPrm_V') then
                                                    local DontCretePrm
                                                    for i = 2, 5, 1 do
                                                        if CheckIfCreate('ConditionPrm' .. i, 'ConditionPrm_PID' .. i, 'ConditionPrm_V_Norm' .. i, 'ConditionPrm_V' .. i) then
                                                        else
                                                            DontCretePrm = true
                                                        end
                                                    end
                                                    if not DontCretePrm then CreateParam = true end
                                                end
                                            end




                                            if CreateParam or not FP.ConditionPrm then
                                                local Prm = FP
                                                local F_Tp = FX.Prm.ToTrkPrm[FxGUID .. Fx_P]
                                                if Prm then
                                                    --Prm.V = Prm.V or r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, Prm.Num)
                                                    --- Add Parameter controls ---------
                                                    if Prm.Type == 'Slider' or (not Prm.Type and not FX.Def_Type[FxGUID]) or FX.Def_Type[FxGUID] == 'Slider' then
                                                        AddSlider(ctx, '##' .. (Prm.Name or Fx_P), Prm.CustomLbl,
                                                            Prm.V or 0, 0, 1, Fx_P, FX_Idx, Prm.Num, Style,
                                                            Prm.Sldr_W or FX.Def_Sldr_W[FxGUID], 0, Disable, Vertical,
                                                            GrabSize, Prm.Lbl, 8)
                                                        MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Sldr', curX, CurY)
                                                    elseif FP.Type == 'Knob' or (FX.Def_Type[FxGUID] == 'Knob' and Prm.Type == nil) then
                                                        AddKnob(ctx, '##' .. Prm.Name, Prm.CustomLbl, Prm.V, 0, 1, Fx_P,
                                                            FX_Idx, Prm.Num, Prm.Style, Prm.Sldr_W or Df.KnobRadius, 0,
                                                            Disabled, Prm.FontSize, Prm.Lbl_Pos or 'Bottom', Prm.V_Pos)
                                                        MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Knob', curX, CurY)
                                                    elseif Prm.Type == 'V-Slider' or (FX.Def_Type[FxGUID] == 'V-Slider') then
                                                        AddSlider(ctx, '##' .. Prm.Name, Prm.CustomLbl, Prm.V or 0, 0, 1,
                                                            Fx_P, FX_Idx, Prm.Num, Style, Prm.Sldr_W or 15, 0, Disable,
                                                            'Vert', GrabSize, Prm.Lbl, nil, Prm.Sldr_H or 160)
                                                        MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'V-Slider', curX, CurY)
                                                    elseif Prm.Type == 'Switch' then
                                                        AddSwitch(LT_Track, FX_Idx, Prm.V or 0, Prm.Num, Prm.BgClr,
                                                            Prm.CustomLbl or 'Use Prm Name as Lbl', Fx_P, F_Tp,
                                                            Prm.FontSize, FxGUID)
                                                        MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Switch', curX, CurY)
                                                    elseif Prm.Type == 'Drag' or (FX.Def_Type[FxGUID] == 'Drag') then
                                                        AddDrag(ctx, '##' .. Prm.Name, Prm.CustomLbl or Prm.Name,
                                                            Prm.V or 0, 0, 1, Fx_P, FX_Idx, Prm.Num, Prm.Style,
                                                            Prm.Sldr_W or FX.Def_Sldr_W[FxGUID] or Df.Sldr_W, -1, Disable,
                                                            Lbl_Clickable, Prm.Lbl_Pos, Prm.V_Pos, Prm.DragDir)
                                                        MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Drag', curX, CurY)
                                                    elseif Prm.Type == 'Selection' then
                                                        AddCombo(ctx, LT_Track, FX_Idx, Prm.Name .. FxGUID, Prm.Num,
                                                            FP.ManualValuesFormat or 'Get Options', Prm.Sldr_W, Prm
                                                            .Style, FxGUID, Fx_P, FP.ManualValues)
                                                        MakeItemEditable(FxGUID, Fx_P, Prm.Sldr_W, 'Selection', curX,
                                                            CurY)
                                                    end

                                                    if r.ImGui_IsItemClicked(ctx) and LBtnDC then
                                                        local dir_path = ConcatPath(r.GetResourcePath(), 'Scripts',
                                                            'ReaTeam Scripts', 'FX', 'BryanChi_FX Devices')
                                                        local file_path = ConcatPath(dir_path, 'FX Default Values.ini')
                                                        local file = io.open(file_path, 'r')

                                                        if file then
                                                            local FX_Name = ChangeFX_Name(FX_Name)
                                                            Content = file:read('*a')
                                                            local Ct = Content
                                                            local P_Num = Prm.Num
                                                            local _, P_Nm = r.TrackFX_GetParamName(LT_Track, FX_Idx,
                                                                P_Num)
                                                            local Df = RecallGlobInfo(Ct, P_Num .. '. ' .. P_Nm .. ' = ',
                                                                'Num')
                                                            if Df then
                                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, Df)
                                                                ToDef = { ID = FX_Idx, P = P_Num, V = Df }
                                                            end
                                                        end
                                                    end

                                                    if ToDef.ID and ToDef.V then
                                                        r.TrackFX_SetParamNormalized(LT_Track, ToDef.ID, ToDef.P, ToDef
                                                            .V)
                                                        if Prm.WhichCC then
                                                            if Trk.Prm.WhichMcros[Prm.WhichCC .. TrkID] then
                                                                Unlink_Parm(LT_TrackNum, ToDef.ID, ToDef.P)
                                                                r.TrackFX_SetParamNormalized(LT_Track, ToDef.ID, ToDef.P,
                                                                    ToDef.V)
                                                                r.GetSetMediaTrackInfo_String(LT_Track,
                                                                    'P_EXT: FX' ..
                                                                    FxGUID ..
                                                                    'Prm' .. ToDef.P .. 'Value before modulation',
                                                                    ToDef.V, true)
                                                                r.gmem_write(7, Prm.WhichCC) --tells jsfx to retrieve P value
                                                                PM.TimeNow = r.time_precise()
                                                                r.gmem_write(11000 + Prm.WhichCC, ToDef.V)
                                                                Link_Param_to_CC(LT_TrackNum, ToDef.ID, ToDef.P, true,
                                                                    true, 176, Prm.WhichCC)
                                                            end
                                                        end
                                                        Prm.V = ToDef.V

                                                        ToDef = {}
                                                    end

                                                    --Try another method: use undo history to detect if user has changed a preset, if so, unlink all params
                                                    --[[ if r.TrackFX_GetOpen(LT_Track, FX_Idx) and focusedFXState==1 and FX_Index_FocusFX==FX_Idx then

                                                        if FX[FxGUID].Morph_ID and not FP.UnlinkedModTable then
                                                            _,TrackStateChunk, FXStateChunk, FP.UnlinkedModTable= GetParmModTable(LT_TrackNum, FX_Idx, Prm.Num, TableIndex_Str)
                                                            Unlink_Parm (trackNumOfFocusFX, FX_Idx, Prm.Num )
                                                            FocusedFX = FX_Idx
                                                        end
                                                    elseif focusedFXState==0 and UnlinkedModTable then

                                                    end --FX_Index_FocusFX
                                                    if FP.UnlinkedModTable then
                                                        if not r.TrackFX_GetOpen(LT_Track, FocusedFX) then -- if the fx is closed
                                                            Link_Param_to_CC(LT_TrackNum, FocusedFX, Prm.Num, true, true, 160, FX[FxGUID].Morph_ID, UnlinkedModTable['PARAMOD_BASELINE'], UnlinkedModTable['PARMLINK_SCALE'])
                                                            FocusedFX=nil      FP.UnlinkedModTable = nil
                                                        end
                                                    end ]]
                                                end

                                                if r.ImGui_IsItemClicked(ctx, 1) and Mods == Ctrl then
                                                    r.ImGui_OpenPopup(ctx, '##prm Context menu' .. FP.Num)
                                                end
                                                if r.ImGui_BeginPopup(ctx, '##prm Context menu' .. FP.Num) then
                                                    if r.ImGui_Selectable(ctx, 'Add Parameter to Envelope') then
                                                        local env = r.GetFXEnvelope(LT_Track, 0, FP.Num, true)
                                                        local active, visible, armed, inLane, laneHeight, defaultShape, minValue, maxValue, centerValue, Tp, faderScaling =
                                                            r.BR_EnvGetProperties(env)

                                                        r.BR_EnvSetProperties(env, true, true, armed, inLane, laneHeight,
                                                            defaultShape, faderScaling)
                                                        r.UpdateArrange()
                                                    end
                                                    r.ImGui_BeginPopupContextItem(ctx, 'optional string str_idIn')
                                                    r.ImGui_EndPopup(ctx)
                                                end
                                            end
                                        end -- Rpt for every param


                                        if FX.LayEdit then
                                            if LE.DragY > LE.GridSize or LE.DragX > LE.GridSize or LE.DragY < -LE.GridSize or LE.DragX < -LE.GridSize then
                                                r.ImGui_ResetMouseDragDelta(ctx)
                                            end
                                        end


                                        if r.ImGui_IsMouseHoveringRect(ctx, Win_L, Win_T, Win_R, Win_B) then
                                            if ClickOnAnyItem == nil and LBtnRel and AdjustPrmWidth ~= true and Mods == 0 and not SaveEditingPopupModal then
                                                LE.Sel_Items = {}; ClickOnAnyItem = nil; SaveEditingPopupModal = nil
                                            elseif ClickOnAnyItem and LBtnRel then
                                                ClickOnAnyItem = nil
                                            elseif AdjustPrmWidth == true then
                                                AdjustPrmWidth = nil
                                            end
                                        end

                                        if FX.Round[FxGUID] then r.ImGui_PopStyleVar(ctx) end
                                        if FX.GrbRound[FxGUID] then r.ImGui_PopStyleVar(ctx) end

                                        if FX.LayEdit == FxGUID or Draw.DrawMode[FxGUID] == true then
                                            r
                                                .ImGui_EndDisabled(ctx)
                                        end

                                        --r.ImGui_PopStyleColor(ctx, times)
                                    end --if there are params stored




                                    --------------------------------------------------------------------------------------
                                    --------------------------------------Pro C --------------------------------------
                                    --------------------------------------------------------------------------------------
                                    if string.find(FX_Name, 'Pro C 2') and not FX[FxGUID].Collapse then
                                        if Prm.InstAdded[FXGUID[FX_Idx]] ~= true and FX.Win_Name[FX_Idx]:find('Pro%-C 2') then
                                            --- number in green represents FX Prm Index
                                            StoreNewParam(FXGUID[FX_Idx], 'Knee', 3, FX_Idx, false, 'AddingFromExtState',
                                                1, FX_Idx)                       --1. Knee
                                            StoreNewParam(FXGUID[FX_Idx], 'Range', 4, FX_Idx, false, 'AddingFromExtState',
                                                2, FX_Idx)                       --2. Range
                                            StoreNewParam(FXGUID[FX_Idx], 'Lookahead', 8, FX_Idx, false,
                                                'AddingFromExtState', 3, FX_Idx) --3. Lookahead
                                            StoreNewParam(FXGUID[FX_Idx], 'Hold', 9, FX_Idx, false, 'AddingFromExtState',
                                                4, FX_Idx)                       --4. Hold

                                            StoreNewParam(FXGUID[FX_Idx], 'Ratio', 2, FX_Idx, false, 'AddingFromExtState',
                                                5, FX_Idx)                       --5. Ratio
                                            StoreNewParam(FXGUID[FX_Idx], 'Attack', 5, FX_Idx, false,
                                                'AddingFromExtState', 6, FX_Idx) --6. Attack
                                            StoreNewParam(FXGUID[FX_Idx], 'Release', 6, FX_Idx, false,
                                                'AddingFromExtState', 7, FX_Idx) --7. release

                                            StoreNewParam(FXGUID[FX_Idx], 'Gain', 10, FX_Idx, false, 'AddingFromExtState',
                                                8, FX_Idx)                        --8. Gain
                                            StoreNewParam(FXGUID[FX_Idx], 'Dry', 12, FX_Idx, false, 'AddingFromExtState',
                                                9, FX_Idx)                        --9. Dry Gain
                                            StoreNewParam(FXGUID[FX_Idx], 'Thresh', 1, FX_Idx, false,
                                                'AddingFromExtState', 10, FX_Idx) -- 10. Thresh

                                            StoreNewParam(FXGUID[FX_Idx], 'Mix', 34, FX_Idx, false, 'AddingFromExtState',
                                                11, FX_Idx)                       -- 11. Mix
                                            StoreNewParam(FXGUID[FX_Idx], 'Input Gain', 35, FX_Idx, false,
                                                'AddingFromExtState', 12, FX_Idx) -- 12. Input Gain
                                            StoreNewParam(FXGUID[FX_Idx], 'Output Gain', 37, FX_Idx, false,
                                                'AddingFromExtState', 13, FX_Idx) -- 13. Output Gain



                                            Prm.InstAdded[FXGUID[FX_Idx]] = true
                                            r.SetProjExtState(0, 'FX Devices', 'FX' .. FXGUID[FX_Idx] .. 'Params Added',
                                                'true')
                                        end
                                        function F_Tp(FX_P)
                                            return FX.Prm.ToTrkPrm[FxGUID .. FX_P]
                                        end

                                        if FX[FxGUID][1].Num and FX[FxGUID][8] then
                                            r.ImGui_Indent(ctx, 20)

                                            Rounding = 3
                                            r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameRounding(), Rounding)
                                            r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_GrabMinSize(), 0)
                                            r.ImGui_PushFont(ctx, Font_Andale_Mono_10)
                                            IIS = 2
                                            reaper.gmem_attach('CompReductionScope')
                                            local SpX, SpY = r.ImGui_GetCursorScreenPos(ctx)
                                            local SpY = SpY - 9; local C = SpY + 50; local B = SpY + 100

                                            local Drawlist = r.ImGui_GetWindowDrawList(ctx)
                                            DspScale = { 2, 4, 6 }; --2=3dB, 4=6dB, 6=9dB, 8=12dB
                                            --
                                            if Sel_Scale == 1 then
                                                ScaleLbl = '± 3dB'
                                            elseif Sel_Scale == 2 then
                                                ScaleLbl = '± 6dB'
                                            elseif Sel_Scale == 3 then
                                                ScaleLbl = '± 9dB'
                                            end

                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x444444ff)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), 0xffffffff)
                                            r.ImGui_SetNextItemWidth(ctx, 30)
                                            if r.ImGui_BeginCombo(ctx, '##' .. tostring(Label), ScaleLbl, r.ImGui_ComboFlags_NoArrowButton()) then
                                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Header(), 0x44444433)
                                                local AccentClr = reaper.ImGui_GetColor(ctx,
                                                    reaper.ImGui_Col_SliderGrabActive())
                                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderHovered(), AccentClr)
                                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(), 0xbbbbbbff)


                                                if r.ImGui_Selectable(ctx, '± 3dB', i) then
                                                    Sel_Scale = 1
                                                end
                                                if r.ImGui_Selectable(ctx, '± 6dB', i) then
                                                    Sel_Scale = 2
                                                end
                                                if r.ImGui_Selectable(ctx, '± 9dB', i) then
                                                    Sel_Scale = 3
                                                end



                                                r.ImGui_PopStyleColor(ctx, 3)

                                                ScaleActive = true
                                                r.ImGui_EndCombo(ctx)
                                                local L, T = r.ImGui_GetItemRectMin(ctx); local R, B = r
                                                    .ImGui_GetItemRectMax(ctx)
                                                local lineheight = reaper.ImGui_GetTextLineHeight(ctx)
                                                local drawlist = r.ImGui_GetForegroundDrawList(ctx)

                                                r.ImGui_DrawList_AddRectFilled(drawlist, L, T + lineheight / 8, R,
                                                    B - lineheight / 8, 0x88888844, Rounding)
                                                r.ImGui_DrawList_AddRect(drawlist, L, T + lineheight / 8, R,
                                                    B - lineheight / 8, 0x88888877, Rounding)
                                            else
                                                ScaleActive = nil
                                            end
                                            r.ImGui_PopStyleColor(ctx, 2)
                                            local HvrOnScale = r.ImGui_IsItemHovered(ctx)

                                            if not Sel_Scale then Sel_Scale = 3 end

                                            if LT_ParamNum == 41 then
                                                Lookahead = r.TrackFX_GetParamNormalized(LT_Track,
                                                    FX_Idx, 41)
                                            end



                                            MousePosX, MousePosY = r.ImGui_GetMousePos(ctx)





                                            r.ImGui_SameLine(ctx)

                                            ---Gain Reduction Spectrum------
                                            for i = 1, 180, 1 do -- do once for each pixel
                                                local Clr = 0xFF8181cc
                                                ProC.Pt.L.m[i] = r.gmem_read(i)
                                                ProC.Pt.L.M[i] = r.gmem_read(i + 200 + 10000 * FX_Idx)

                                                ProC.Pt.L.M[i + 1] = r.gmem_read(i + 201 + 10000 * FX_Idx)
                                                local Min = ProC.Pt.L.m[i]
                                                local Max = (ProC.Pt.L.M[i] - 347) / DspScale[Sel_Scale] + 50
                                                local MaxNext = (ProC.Pt.L.M[i + 1] - 347) / DspScale[Sel_Scale] + 50




                                                --r.ImGui_DrawList_AddLine(Drawlist, SpX+i, math.min(math.max(B-Max,SpY),B)+1 , SpX+i-1, math.min(math.max(B-Max,SpY),B), Clr,2)
                                                r.ImGui_DrawList_AddLine(Drawlist, SpX + i,
                                                    math.min(math.max(B - Max, SpY), B), SpX + i + 1,
                                                    math.min(math.max(B - MaxNext, SpY), B), 0xFF8181cc, 2)
                                                if B - Max <= SpY or B - Max >= B then
                                                    r.ImGui_DrawList_AddLine(Drawlist, SpX + i,
                                                        math.min(math.max(B - Max, SpY), B), SpX + i + 1,
                                                        math.min(math.max(B - MaxNext, SpY), B), 0xff4517cc, 2)
                                                end
                                            end



                                            -- Change Display scale if mouseclick on spectrum

                                            MouseX, MouseY = r.ImGui_GetMousePos(ctx)

                                            if MouseX > SpX and MouseX < SpX + 180 and MouseY > SpY and MouseY < SpY + 100 and not HvrOnScale and not ScaleActive then
                                                r.ImGui_DrawList_AddRectFilled(Drawlist, SpX, SpY, SpX + 180, SpY + 100,
                                                    0x88888810, nil)
                                                local AnyActive = reaper.ImGui_IsAnyItemActive(ctx)

                                                if IsLBtnClicked and AnyActive == false and not ProC.ChoosingStyle then
                                                    r.ImGui_DrawList_AddRectFilled(Drawlist, SpX, SpY, SpX + 180, SpY +
                                                        100, 0x88888866, nil)
                                                    ShowDpRange = true
                                                    TimeNow = r.time_precise()
                                                    Sel_Scale = math.max(Sel_Scale - 1, 1)
                                                end
                                                if IsRBtnClicked then
                                                    r.ImGui_DrawList_AddRectFilled(Drawlist, SpX, SpY, SpX + 180, SpY +
                                                        100, 0x88888866, nil)
                                                    ShowDpRange = true
                                                    TimeNow = r.time_precise()
                                                    Sel_Scale = math.min(Sel_Scale + 1, 3)
                                                end


                                                if Wheel_V ~= 0 then
                                                    HoverOnScrollItem = true
                                                    r.ImGui_SetScrollX(ctx, 0)
                                                    local OV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx + 1, 0)
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx + 1, 0, OV + Wheel_V /
                                                        50)
                                                    TimeNow = r.time_precise()
                                                    FX[FxGUID].ShowMsecRange = true
                                                    FX[FxGUID].MsecRange = tonumber(select(2,
                                                        r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx + 1, 0)))
                                                    if FX[FxGUID].MsecRange then
                                                        if FX[FxGUID].MsecRange > 999 then
                                                            FX[FxGUID].MsecRange = round((FX[FxGUID].MsecRange / 1000), 2) ..
                                                                's'
                                                        else
                                                            FX[FxGUID].MsecRange = math.floor(FX[FxGUID].MsecRange) ..
                                                                'ms'
                                                        end
                                                    end
                                                end
                                            end
                                            if ShowDpRange then
                                                TimeAfter = r.time_precise()
                                                if TimeAfter < TimeNow + 0.5 then
                                                    r.ImGui_DrawList_AddTextEx(Drawlist, Font_Andale_Mono_20_B, 20,
                                                        SpX + 90, SpY + 40, 0xffffffff, '±' .. Sel_Scale * 3)
                                                else
                                                    ShowDpRange = false
                                                end
                                            elseif FX[FxGUID].ShowMsecRange then
                                                TimeAfter = r.time_precise()
                                                if TimeAfter < TimeNow + 0.5 then
                                                    r.ImGui_DrawList_AddTextEx(Drawlist, Font_Andale_Mono_20_B, 20,
                                                        SpX + 70, SpY + 40, 0xffffffff, FX[FxGUID].MsecRange)
                                                else
                                                    FX[FxGUID].ShowMsecRange = false
                                                end
                                            end


                                            -- Draw Grid
                                            r.ImGui_DrawList_AddLine(Drawlist, SpX, SpY + 95, SpX + 180, SpY + 95,
                                                0x99999955, 1) --- -3dB
                                            r.ImGui_DrawList_AddText(Drawlist, SpX + 185, SpY + 90, 0x999999bb,
                                                '-' .. 3 * Sel_Scale)
                                            r.ImGui_DrawList_AddLine(Drawlist, SpX, SpY + 72, SpX + 180, SpY + 72,
                                                0x99999933, 1) --- -1.5dB
                                            r.ImGui_DrawList_AddText(Drawlist, SpX + 185, SpY + 70, 0x999999aa,
                                                '-' .. 1.5 * Sel_Scale)

                                            r.ImGui_DrawList_AddLine(Drawlist, SpX, SpY + 50, SpX + 180, SpY + 50,
                                                0x99999955, 1) --- 0dB
                                            r.ImGui_DrawList_AddText(Drawlist, SpX + 185, SpY + 45, 0x999999bb, ' 0')

                                            r.ImGui_DrawList_AddLine(Drawlist, SpX, SpY + 27, SpX + 180, SpY + 27,
                                                0x99999933, 1) --- -1.5dB
                                            r.ImGui_DrawList_AddText(Drawlist, SpX + 185, SpY + 20, 0x999999aa,
                                                '+' .. 1.5 * Sel_Scale)

                                            r.ImGui_DrawList_AddLine(Drawlist, SpX, SpY + 4, SpX + 180, SpY + 4,
                                                0x99999955, 1) --- +3dB
                                            r.ImGui_DrawList_AddText(Drawlist, SpX + 185, SpY - 5, 0x999999bb,
                                                '+' .. 3 * Sel_Scale)

                                            -- r.ImGui_DrawList_PathStroke(Drawlist,0xFF8181cc)


                                            r.ImGui_SameLine(ctx)



                                            local Fx_P = 1
                                            --for i=1, 13, 1 do FX[FxGUID][i]=FX[FxGUID][i] or {} end


                                            reaper.ImGui_Indent(ctx, 210)
                                            AddKnob(ctx, '##Gain', 'Gain', FX[FxGUID][8].V or 0, 0, 1, 8, FX_Idx, 10,
                                                'Pro C', 15, IIS, Disabled, LblTextSize, 'Bottom')
                                            AddKnob(ctx, '##Dry', 'Dry', FX[FxGUID][9].V or 0, 0, 1, 9, FX_Idx, 12,
                                                'Pro C', 15, IIS, Disabled, LblTextSize, 'Bottom')
                                            local OrigPosX, OrigPosY = r.ImGui_GetCursorPos(ctx)
                                            r.ImGui_SetCursorScreenPos(ctx, SpX - 20, SpY + 20)
                                            AddSlider(ctx, '##Threshold', ' ', FX[FxGUID][10].V or 0, 0, 1, 10, FX_Idx, 1,
                                                'Pro C Thresh', 18, IIS, nil, 'Vert', 4, nil, nil, 180)
                                            r.ImGui_SetCursorPos(ctx, OrigPosX, OrigPosY)

                                            ---Meter on the right-----
                                            r.gmem_attach('CompReductionScope')

                                            local MtrPreL = r.gmem_read(1002); if not MtrPreL then MtrPreL = 0 end
                                            local MtrPreR = r.gmem_read(1003); if not MtrPreR then MtrPreR = 0 end
                                            local MtrPoL = r.gmem_read(1001); if not MtrPoL then MtrPoL = 0 end
                                            local MtrPoR = r.gmem_read(1000); if not MtrPoR then MtrPoR = 0 end
                                            local MtrB = SpY + 190; local MtrT = SpY + 20
                                            local SegL = 0 * ((MtrB - MtrT) / 30)
                                            local MtrW = 5;

                                            --r.ImGui_DrawList_AddRectFilled(Drawlist, SpX+249, MtrT, SpX+267, MtrB , 0x55555544)

                                            local HowManySeg = 63
                                            for i = 0, HowManySeg, 1 do --do once for every pixel so you can get different color
                                                local SegL = i * ((MtrB - MtrT) / HowManySeg); local Clr

                                                local _, _, RR, GG, BB = r.ImGui_ColorConvertHSVtoRGB(
                                                    0.4 - (0.3 / HowManySeg) * i, 0.6, 0.5)
                                                local MtrClr = r.ImGui_ColorConvertDouble4ToU32(RR, GG, BB, 1)
                                                local MtrClrDim = r.ImGui_ColorConvertDouble4ToU32(RR, GG, BB, 0.4)

                                                if MtrT - (20 * MtrPreL) < MtrB - SegL then
                                                    r.ImGui_DrawList_AddLine(
                                                        Drawlist, SpX - 15, MtrB - SegL, SpX - 15, MtrB - SegL - 1,
                                                        MtrClr,
                                                        MtrW)
                                                end
                                                if MtrT - (20 * MtrPreR) < MtrB - SegL then
                                                    r.ImGui_DrawList_AddLine(
                                                        Drawlist, SpX - 15 + MtrW + 2, MtrB - SegL, SpX - 15 + MtrW + 2,
                                                        MtrB - SegL - 1, MtrClr, MtrW)
                                                end
                                                if MtrT - (20 * MtrPoL) < MtrB - SegL then
                                                    r.ImGui_DrawList_AddLine(
                                                        Drawlist, SpX + 250, MtrB - SegL, SpX + 250, MtrB - SegL - 1,
                                                        MtrClr,
                                                        MtrW)
                                                end
                                                if MtrT - (20 * MtrPoR) < MtrB - SegL then
                                                    r.ImGui_DrawList_AddLine(
                                                        Drawlist, SpX + 250 + MtrW + 2, MtrB - SegL, SpX + 250 + MtrW + 2,
                                                        MtrB - SegL - 1, MtrClr, MtrW)
                                                end

                                                r.ImGui_DrawList_AddLine(Drawlist, SpX - 15, MtrB - SegL, SpX - 15,
                                                    MtrB - SegL - 1, MtrClrDim, MtrW)
                                                r.ImGui_DrawList_AddLine(Drawlist, SpX - 15 + MtrW + 2, MtrB - SegL,
                                                    SpX - 15 + MtrW + 2, MtrB - SegL - 1, MtrClrDim, MtrW)
                                                r.ImGui_DrawList_AddLine(Drawlist, SpX + 250, MtrB - SegL, SpX + 250,
                                                    MtrB - SegL - 1, MtrClrDim, MtrW)
                                                r.ImGui_DrawList_AddLine(Drawlist, SpX + 250 + MtrW + 2, MtrB - SegL,
                                                    SpX + 250 + MtrW + 2, MtrB - SegL - 1, MtrClrDim, MtrW)
                                            end

                                            if MtrPreL > 0 then
                                                PreLPeak = true; PlayStateWhenPeak = r.GetPlayState()
                                            end
                                            if MtrPreR > 0 then
                                                PreRPeak = true; PlayStateWhenPeak = r.GetPlayState()
                                            end
                                            if MtrPoL > 0 then
                                                PoLPeak = true; PlayStateWhenPeak = r.GetPlayState()
                                            end
                                            if MtrPoR > 0 then
                                                PoRPeak = true; PlayStateWhenPeak = r.GetPlayState()
                                            end

                                            if PreLPeak then
                                                r.ImGui_DrawList_AddRectFilled(Drawlist, SpX - 16, MtrT - 2,
                                                    SpX - 13, MtrT + 3, 0xf20000ff)
                                            end
                                            if PreRPeak then
                                                r.ImGui_DrawList_AddRectFilled(Drawlist, SpX + 250 + MtrW +
                                                    2, MtrT - 2, SpX + 250 + MtrW + 5, MtrT + 3, 0xf20000ff)
                                            end
                                            if PoLPeak then
                                                r.ImGui_DrawList_AddRectFilled(Drawlist, SpX + 250 + MtrW * 3 +
                                                    12, MtrT - 2, SpX + 250 + MtrW * 3 + 15, MtrT + 3, 0xf20000ff)
                                            end
                                            if PoRPeak then
                                                r.ImGui_DrawList_AddRectFilled(Drawlist, SpX + 250 + MtrW * 4 +
                                                    14, MtrT - 2, SpX + 250 + MtrW * 4 + 17, MtrT + 3, 0xf20000ff)
                                            end



                                            if PreLPeak or PreRPeak or PoLPeak or PoRPeak then
                                                if r.GetPlayState() == 0 then StoppedPlyaing = true end
                                                if StoppedPlyaing and r.GetPlayState() ~= 0 then
                                                    PreLPeak = nil; PreRPeak = nil; PoLPeak = nil; PoRPeak = nil; StoppedPlyaing = nil;
                                                end
                                            end
                                            -------- End of Meter





                                            r.ImGui_Unindent(ctx, 210)
                                            reaper.ImGui_Indent(ctx, 5)


                                            AddKnob(ctx, '##Ratio', 'RATIO', FX[FxGUID][5].V or 0, 0, 1, 5, FX_Idx, 2,
                                                'Pro C', 20, IIS, 'Pro C Ratio Disabled', LblTextSize, 'Bottom')
                                            local KneePosX, KneePosY = r.ImGui_GetCursorPos(ctx)

                                            r.ImGui_SameLine(ctx)
                                            local X, Y = r.ImGui_GetCursorPos(ctx)

                                            StyleOptions = { 'Clean', 'Classic', 'Opto', 'Vocal', 'Master', 'Bus',
                                                'Punch', 'Pump' }
                                            r.ImGui_SetCursorPos(ctx, X + 25, Y + 15)

                                            AddCombo(ctx, LT_Track, FX_Idx, 'CompStyle##', 0, StyleOptions, 40, 'Pro C 2',
                                                FxGUID, Fx_P)
                                            r.ImGui_SetCursorPos(ctx, X + 25, Y + 35)

                                            MyText('STYLE', nil, 0xbbbbbbff)


                                            r.ImGui_SetCursorPos(ctx, X + 90, Y)


                                            AddKnob(ctx, 'Attack##Attack', 'Attack', FX[FxGUID][6].V or 0, 0, 1, 6,
                                                FX_Idx, 5, 'Pro C', 20, IIS, Disabled, LblTextSize, 'Bottom')


                                            r.ImGui_SetCursorPos(ctx, X + 145, Y)
                                            AddKnob(ctx, '##Release', 'Release', FX[FxGUID][7].V or 0, 0, 1, 7, FX_Idx, 6,
                                                'Pro C', 20, IIS, Disabled, 2, 'Bottom')



                                            r.ImGui_SetCursorPos(ctx, KneePosX - 3, KneePosY + 4)
                                            for Fx_p = 1, 4, 1 do
                                                r.ImGui_SetCursorPosY(ctx, KneePosY + 4)
                                                local F_Tp = FX.Prm.ToTrkPrm[FxGUID .. Fx_p]
                                                local P_Num = FX[FxGUID][Fx_p].Num
                                                SliderStyle = 'Pro C'
                                                if FX[FxGUID][Fx_P].V == nil then
                                                    FX[FxGUID][Fx_P].V = r
                                                        .TrackFX_GetParamNormalized(LT_Track, FX_Idx, P_Num)
                                                end

                                                if P_Num == 8 then
                                                    if Lookahead == 0 then
                                                        AddDrag(ctx, '##' .. Fx_p, FX[FxGUID][3].Name,
                                                            FX[FxGUID][Fx_p].V or 0, 0, 1, Fx_p, FX_Idx, P_Num,
                                                            'Pro C Lookahead', (ProC.Width - 60) / 4, IIS, 'Disabled',
                                                            'Lbl_Clickable')
                                                    else
                                                        AddDrag(ctx, '##' .. Fx_p, FX[FxGUID][3].Name,
                                                            FX[FxGUID][Fx_p].V or 0, 0, 1, Fx_p, FX_Idx, P_Num,
                                                            'Pro C Lookahead', (ProC.Width - 60) / 4, IIS, nil,
                                                            'Lbl_Clickable')
                                                    end
                                                else
                                                    AddDrag(ctx, '##' .. Fx_p, FX[FxGUID][Fx_p].Name,
                                                        FX[FxGUID][Fx_p].V or 0, 0, 1, Fx_p, FX_Idx, P_Num, 'Pro C',
                                                        (ProC.Width - 60) / 4, IIS, nil)
                                                    --r.ImGui_SameLine(ctx)
                                                end
                                                r.ImGui_SameLine(ctx)
                                            end
                                            r.ImGui_PopFont(ctx)
                                            r.ImGui_PopStyleVar(ctx, 2)


                                            if not FX.Win_Name[math.max(FX_Idx - 1, 0)]:find('JS: FXD Split to 4 channels') and not tablefind(Trk[TrkID].PreFX, FxGUID) and not tablefind(Trk[TrkID].PostFX, FxGUID) then
                                                table.insert(AddFX.Pos, FX_Idx)
                                                table.insert(AddFX.Name, 'FXD Split to 4 channels')
                                                if r.GetMediaTrackInfo_Value(LT_Track, 'I_NCHAN') < 4 then
                                                    rv = r.SetMediaTrackInfo_Value(LT_Track, 'I_NCHAN', 4)
                                                end
                                            else
                                                r.TrackFX_Show(LT_Track, FX_Idx - 1, 2)
                                            end
                                            -- r.TrackFX_Show( LT_Track, FX_Idx-1, 2 ) --hide fx window

                                            local _, NextFX = r.TrackFX_GetFXName(LT_Track, FX_Idx + 1)

                                            if not NextFX:find('JS: FXD Gain Reduction Scope') and not tablefind(Trk[TrkID].PreFX, FxGUID) and not tablefind(Trk[TrkID].PostFX, FxGUID) then
                                                table.insert(AddFX.Pos, FX_Idx + 1)
                                                table.insert(AddFX.Name, 'FXD Gain Reduction Scope')
                                                ProC.GainSc_FXGUID = FxGUID

                                                function WriteGmemToGainReductionScope(FxGUID)

                                                end

                                                if not GainReductionWait then GainReductionWait = 0 end
                                                GainReductionWait = GainReductionWait + 1
                                                --[[ if GainReductionWait> FX_Add_Del_WaitTime then
                                                    FX[FxGUID] = FX[FxGUID] or {}
                                                    FX[FxGUID].ProC_ID =  math.random(1000000, 9999999 )
                                                    r.gmem_attach('CompReductionScope')
                                                    r.gmem_write(2002, FX[FxGUID].ProC_ID)
                                                    r.gmem_write(FX[FxGUID].ProC_ID, FX_Idx)
                                                    r.gmem_write(2000, PM.DIY_TrkID[TrkID])
                                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: ProC_ID '..FxGUID, FX[FxGUID].ProC_ID, true)
                                                    AddFX_HideWindow(LT_Track,'FXD Gain Reduction Scope.jsfx',-1000-FX_Idx-1)

                                                    GainReductionWait = nil
                                                end ]]
                                            else
                                                r.TrackFX_Show(LT_Track, FX_Idx + 1, 2)
                                                SyncAnalyzerPinWithFX(FX_Idx + 1, FX_Idx)
                                            end
                                        end
                                        r.gmem_attach('CompReductionScope'); r.gmem_write(2000, PM.DIY_TrkID[TrkID])
                                    end



                                    --------------------------------------------------------------------------------------
                                    --------------------------------------Pro Q --------------------------------------
                                    --------------------------------------------------------------------------------------
                                    if string.find(FX_Name, 'Pro Q 3') ~= nil and FX[FxGUID].Collapse ~= true then -- ==  Pro Q Graph
                                        r.gmem_attach('gmemReEQ_Spectrum')




                                        if FirstLoop == true then
                                            _, ProQ3.DspRange[FX_Idx] = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,
                                                331)
                                            ProQ3['scaleLabel' .. ' ID' .. FXGUID[FX_Idx]] = ProQ3.DspRange[FX_Idx]
                                            ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] = syncProQ_DispRange(ProQ3
                                                .DspRange[FX_Idx])
                                        end

                                        _, ProQ3.Format = r.TrackFX_GetNamedConfigParm(LT_Track, FX_Idx, 'fx_type')

                                        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x090909ff)

                                        ProQ3.H = 200

                                        r.ImGui_SetNextWindowPos(ctx, ProQ_TitlePosX_L, ProQ_TitlePosY_B)


                                        if r.ImGui_BeginChildFrame(ctx, '##EQ Spectrum' .. FX_Idx, ProQ3.Width, ProQ3.H, nil) then
                                            if ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] == nil then ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] = 2.5 end
                                            if ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] == 10 then
                                                ProQ3['DragGainScale' .. ' ID' .. FXGUID[FX_Idx]] = 100
                                            elseif ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] == 5 then
                                                ProQ3['DragGainScale' .. ' ID' .. FXGUID[FX_Idx]] = 20
                                            elseif ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] == 2.5 then
                                                ProQ3['DragGainScale' .. ' ID' .. FXGUID[FX_Idx]] = 5
                                            elseif ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] == 1 then
                                                ProQ3['DragGainScale' .. ' ID' .. FXGUID[FX_Idx]] = 1
                                            end
                                            --   10 = 3dB | 5 = 6dB | 2.5 = 12 dB | 1 = 30 dB

                                            --DragGain
                                            ---THIS SETS THE SCALE
                                            --- Need to also scale nodes dragging
                                            local ShelfGain_Node = 0
                                            local Q_Node = {}
                                            local E = 2.71828182845904523
                                            ProQ_Xpos_L, ProQ_Ypos_T = reaper.ImGui_GetItemRectMin(ctx)
                                            ProQ_Xpos_R, ProQ_Ypos_B = reaper.ImGui_GetItemRectMax(ctx)
                                            --ProQ_Ypos_B= ProQ_Ypos_T+340
                                            local B = ProQ_Ypos_B + 340
                                            floor = -80; ly = 0; lx = -1;

                                            sc = (ProQ3.Width - 20) * 20 /
                                                (floor * math.log(10)) --      200 = width of window
                                            Foreground = r.ImGui_GetWindowDrawList(ctx)
                                            SpectrumX = 0
                                            SpectrumY = 0
                                            r.gmem_attach('gmemReEQ_Spectrum')
                                            if FX[FxGUID].ProQ_ID then
                                                r.gmem_write(FX[FxGUID].ProQ_ID, FX_Idx)
                                            end

                                            ----Get spectrum info
                                            -- attach a DIYFXGUID to each PRO Q and use that for spectrums
                                            if TrkID ~= TrkID_End then
                                                for i = 2, 249, 1 do
                                                    r.gmem_write(i + ((FX_Idx + 1) * 1000), 0)
                                                    r.gmem_write(i + 300 + ((FX_Idx + 1) * 1000), 0)
                                                end
                                            end


                                            for i = 2, 249, 1 do
                                                BinY = r.gmem_read(i + ((FX_Idx + 1) * 1000))
                                                tx = r.gmem_read(i + 300 + ((FX_Idx + 1) * 1000))




                                                tx = freq_to_x_MyOwn(tx)

                                                ty = spectrum1_to_y(BinY)
                                                ty = ProQ_Ypos_T + ty

                                                tx = tx + ProQ_Xpos_L
                                                if lx == nil then lx = tx end

                                                tx = round(tx, 0)


                                                if lx ~= tx and i ~= 2 then
                                                    r.ImGui_DrawList_AddQuadFilled(Foreground, lx, B, lx, ly, tx, ty, tx,
                                                        B, 0x003535ff)
                                                elseif i == 2 then
                                                    r.ImGui_DrawList_AddQuadFilled(Foreground, lx, B, lx, ty, tx, ty, tx,
                                                        B, 0x003535ff)
                                                end

                                                lx = tx; ly = ty;
                                            end



                                            Freq = {}
                                            Gain = {}
                                            Q = {}
                                            Slope = {}
                                            Band_Used = {}
                                            pts = {}

                                            local Band_Enabled = {}
                                            local Y_Mid = ProQ_Ypos_B + ProQ3.H / 2
                                            local y = Y_Mid


                                            FXGUID_ProQ = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

                                            for Band = 1, 24, 1 do
                                                paramOfUsed = 13 * (Band - 1)
                                                paramOfEnabled = 13 * (Band - 1) + 1
                                                if FXGUID_ProQ == nil then FXGUID_ProQ = 0 end
                                                ProQ3.Band_UseState[Band] = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                    paramOfUsed)
                                                Band_Enabled[Band .. FXGUID_ProQ] = r.TrackFX_GetParamNormalized(
                                                    LT_Track, FX_Idx, paramOfEnabled)
                                                local x = ProQ_Xpos_L
                                                local y = Y_Mid
                                                if ProQ3.Band_UseState[Band] == 1 then
                                                    Freq[Band] = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                        paramOfUsed + 2)
                                                    Slope[Band] = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                        9 + 13 * (Band - 1))
                                                    Gain[Band] = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                        paramOfUsed + 3)
                                                    _, ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] = r
                                                        .TrackFX_GetFormattedParamValue(LT_Track, FX_Idx, paramOfUsed + 8)
                                                    NodeFreq['B-' .. Band .. 'GUID-' .. FXGUID_ProQ] = x_to_freq(Freq
                                                        [Band] * ProQ3.Width)
                                                    if ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Low Shelf' or ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'High Shelf' then
                                                        Gain[Band] = -30 + Gain[Band] * 60
                                                        ShelfGain_Node = Gain[Band] * 1.3


                                                        Gain[Band] = db_to_gain(Gain[Band])
                                                    else
                                                        Gain[Band] = -30 + Gain[Band] * 60
                                                    end
                                                    FreqToActualFreq = x_to_freq((Freq[Band] * ProQ3.Width))



                                                    if ProQ3.Format == 'AU' then
                                                        Q[Band] = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                            paramOfUsed + 7)
                                                    else
                                                        if ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Low Cut' or ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'High Cut' then
                                                            _, Q[Band] = r.TrackFX_GetFormattedParamValue(LT_Track,
                                                                FX_Idx, paramOfUsed + 7)
                                                        else
                                                            Q[Band] = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                                paramOfUsed + 7)
                                                        end
                                                    end

                                                    Q_Node[Band] = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                        paramOfUsed + 7)
                                                    Q_Node[Band] = (-1 + Q_Node[Band] * 2) * 50

                                                    if Q_Node[Band] > 37 then
                                                        Q_Node[Band] = 37
                                                    elseif Q_Node[Band] < -37 then
                                                        Q_Node[Band] = -37
                                                    end
                                                end

                                                function FillClr_LT_Band(iteration, y1)
                                                    if ProQ3.LT_EQBand[FXGUID_ProQ] == Band then
                                                        X2 = x + 2
                                                        BandColor = determineBandColor(ProQ3.LT_EQBand[FXGUID_ProQ])
                                                        i = iteration
                                                        if i ~= 1 then
                                                            r.ImGui_DrawList_AddLine(Foreground, x, y1, X2,
                                                                Y_Mid - pts[i .. 'B-' .. Band .. FXGUID_ProQ], BandColor,
                                                                1.7)
                                                        end
                                                        x = X2
                                                    end
                                                end

                                                function TiltShelf(Minimum_Q, Maximum_Q, Q_range, Q_Value)
                                                    Min_Q = Minimum_Q
                                                    Max_Q = Maximum_Q
                                                    Q[Band] = per_to_q(Q[Band] * Q_range, 100)
                                                    --local Gain = db_to_gain(Gain[Band] )
                                                    local gain = Gain[Band]
                                                    if Q_Value ~= nil then Q[Band] = Q_Value end

                                                    svf_st(FreqToActualFreq, Q[Band], gain)

                                                    local x = ProQ_Xpos_L
                                                    local y = Y_Mid
                                                    if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                                                        for i = 1, ProQ3.Width, 1 do -- do 340 times
                                                            iToFreq = x_to_freq(i)
                                                            mag = zdf_magnitude(iToFreq)
                                                            mag = 20 * math.log(mag, 10)
                                                            mag = db_to_y(mag)
                                                            pts[i .. 'B-' .. Band .. FXGUID_ProQ] = mag
                                                        end
                                                    end

                                                    --[[  local Gain2 = 10^(-(gain) / 21);
                                                    local Gain2 = 1 ]]

                                                    local x = ProQ_Xpos_L
                                                    local y = Y_Mid
                                                    if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                                                        for i = 1, ProQ3.Width, 2 do -- do 340 times
                                                            iToFreq = x_to_freq(i)
                                                            mag = zdf_magnitude(iToFreq)
                                                            mag = 20 * math.log(mag, 10)
                                                            mag = db_to_y(mag)
                                                            pts[i .. 'B-' .. Band .. FXGUID_ProQ] = ((pts[i .. 'B-' .. Band .. FXGUID_ProQ] + mag) / 2) *
                                                                ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]]
                                                            FillClr_LT_Band(i, y)
                                                            if ProQ3.LT_EQBand[FXGUID_ProQ] == Band then
                                                                X2 = x + 2
                                                                BandColor = determineBandColor(ProQ3.LT_EQBand
                                                                    [FXGUID_ProQ])
                                                                if i ~= 1 then
                                                                    r.ImGui_DrawList_AddLine(Foreground, x,
                                                                        Y_Mid, X2, Y_Mid -
                                                                        pts[i .. 'B-' .. Band .. FXGUID_ProQ], BandColor,
                                                                        1.7)
                                                                end
                                                                x = X2
                                                            end
                                                        end
                                                    end
                                                end

                                                ---------------------
                                                -- BELL
                                                ---------------------
                                                if ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Bell' then
                                                    Freq_Math = Freq[Band] * ProQ3.Width
                                                    Gain_Math = (Gain[Band] * (ProQ3.H / 2)) / 30

                                                    if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                                                        for i = 1, ProQ3.Width, 2 do
                                                            local xscale                          = 800 /
                                                                (ProQ3.Width - 4);
                                                            Q_Math                                = ((Q[Band] ^ 3.2) * 0.55) /
                                                                2 + 0.005
                                                            pts[i .. 'B-' .. Band .. FXGUID_ProQ] = (Gain_Math * Euler ^ -(Q_Math * (i - Freq_Math)) ^ 2) *
                                                                ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]]
                                                            FillClr_LT_Band(i, Y_Mid)
                                                        end

                                                        reaper.ImGui_DrawList_PathFillConvex(Foreground, 0xffffffff)
                                                    end
                                                elseif ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'High Cut' then
                                                    if Slope[Band] < 0.2 then
                                                        MIN_Q = 0.1; MAX_Q = 200
                                                    elseif Slope[Band] > 0.2 and Slope[Band] < 0.3 then
                                                        MIN_Q = 0.1; MAX_Q = 120
                                                    elseif Slope[Band] > 0.3 and Slope[Band] < 0.4 then
                                                        MIN_Q = 0.1; MAX_Q = 40
                                                    elseif Slope[Band] > 0.4 and Slope[Band] < 0.5 then
                                                        MIN_Q = 0.1; MAX_Q = 21
                                                    elseif Slope[Band] > 0.5 and Slope[Band] < 0.6 then
                                                        MIN_Q = 0.26; MAX_Q = 7
                                                    elseif Slope[Band] > 0.6 and Slope[Band] < 0.7 then
                                                        MIN_Q = 0.3; MAX_Q = 5
                                                    elseif Slope[Band] > 0.7 and Slope[Band] < 0.8 then
                                                        MIN_Q = 0.5; MAX_Q = 2.6
                                                    elseif Slope[Band] > 0.8 and Slope[Band] < 0.9 then
                                                        MIN_Q = 0.4; MAX_Q = 2.7
                                                    elseif Slope[Band] == 1 then
                                                        MIN_Q = 0.7; MAX_Q = 0.7
                                                    end
                                                    Slope_HighCut = Slope[Band] * 20

                                                    Q[Band]       = Q[Band] * 100
                                                    Q_HC          = per_to_q(Q[Band], 100)

                                                    if ProQ3.Format == 'VST' or ProQ3.Format == 'VST3' then
                                                        Q_HC = Q[Band] / 100 / 1.4
                                                    else
                                                    end

                                                    local x = ProQ_Xpos_L
                                                    local y = Y_Mid


                                                    zdf_lp(FreqToActualFreq, Q_HC, Slope_HighCut)

                                                    for i = 1, ProQ3.Width, 2 do -- do 340 times
                                                        iToFreq = x_to_freq(i)
                                                        local mag = zdf_magnitude(iToFreq)

                                                        mag = 20 * math.log(mag, 10)
                                                        mag = db_to_y(mag)

                                                        if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                                                            if Slope[Band] ~= 1 then
                                                                pts[i .. 'B-' .. Band .. FXGUID_ProQ] = mag *
                                                                    ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]]
                                                            elseif Slope[Band] == 1 then --if Slope = brickwall
                                                                if iToFreq > FreqToActualFreq then
                                                                    magForBrickwall = db_to_y(-100)
                                                                elseif iToFreq < FreqToActualFreq then
                                                                    magForBrickwall = db_to_y(0)
                                                                end
                                                                pts[i .. 'B-' .. Band .. FXGUID_ProQ] = magForBrickwall
                                                            end

                                                            if ProQ3.LT_EQBand[FXGUID_ProQ] == Band then
                                                                BandColor = determineBandColor(ProQ3.LT_EQBand
                                                                    [FXGUID_ProQ])
                                                                local X2 = x + 2
                                                                if i ~= 1 then
                                                                    r.ImGui_DrawList_AddLine(Foreground, x,
                                                                        Y_Mid + 100, X2,
                                                                        Y_Mid - pts[i .. 'B-' .. Band .. FXGUID_ProQ],
                                                                        BandColor, 2)
                                                                end
                                                                x = X2
                                                            end
                                                        end
                                                    end
                                                elseif ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Low Cut' then
                                                    if Slope[Band] < 0.2 then
                                                        MIN_Q = 0.1; MAX_Q = 200
                                                    elseif Slope[Band] > 0.2 and Slope[Band] < 0.3 then
                                                        MIN_Q = 0.1; MAX_Q = 120
                                                    elseif Slope[Band] > 0.3 and Slope[Band] < 0.4 then
                                                        MIN_Q = 0.1; MAX_Q = 40
                                                    elseif Slope[Band] > 0.4 and Slope[Band] < 0.5 then
                                                        MIN_Q = 0.1; MAX_Q = 21
                                                    elseif Slope[Band] > 0.5 and Slope[Band] < 0.6 then
                                                        MIN_Q = 0.26; MAX_Q = 7
                                                    elseif Slope[Band] > 0.6 and Slope[Band] < 0.7 then
                                                        MIN_Q = 0.3; MAX_Q = 6
                                                    elseif Slope[Band] > 0.7 and Slope[Band] < 0.8 then
                                                        MIN_Q = 0.5; MAX_Q = 2.6
                                                    elseif Slope[Band] > 0.8 and Slope[Band] < 0.9 then
                                                        MIN_Q = 0.4; MAX_Q = 2.7
                                                    elseif Slope[Band] == 1 then
                                                        MIN_Q = 0.7; MAX_Q = 0.7
                                                    end



                                                    Q[Band] = Q[Band] * 100
                                                    if ProQ3.Format == 'VST' or ProQ3.Format == 'VST3' then
                                                        Q_LC = Q[Band] / 100 / 1.4
                                                    elseif ProQ3.Format == 'AU' then
                                                        Q_LC = per_to_q(Q[Band], 100)
                                                    end


                                                    ProQ3['Slope' .. ' FXID-' .. FXGUID[FX_Idx]] = Slope[Band] * 20
                                                    svf_hp(FreqToActualFreq, Q_LC,
                                                        ProQ3['Slope' .. ' FXID-' .. FXGUID[FX_Idx]])

                                                    local x = ProQ_Xpos_L
                                                    local y = Y_Mid
                                                    if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                                                        for i = 1, ProQ3.Width, 1 do -- do 340 times
                                                            iToFreq = x_to_freq(i)
                                                            local mag = zdf_magnitude(iToFreq)
                                                            mag = 20 * math.log(mag, 10)
                                                            mag = db_to_y(mag)

                                                            if Slope[Band] ~= 1 then
                                                                pts[i .. 'B-' .. Band .. FXGUID_ProQ] = mag *
                                                                    ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]]
                                                            elseif Slope[Band] == 1 then --if Slope = brickwall
                                                                local magForBrickwall;
                                                                if iToFreq > FreqToActualFreq then
                                                                    magForBrickwall = db_to_y(0)
                                                                elseif iToFreq < FreqToActualFreq then
                                                                    magForBrickwall = db_to_y(-100)
                                                                end
                                                                pts[i .. 'B-' .. Band .. FXGUID_ProQ] = magForBrickwall
                                                            end

                                                            if ProQ3.LT_EQBand[FXGUID_ProQ] == Band then
                                                                BandColor = determineBandColor(ProQ3.LT_EQBand
                                                                    [FXGUID_ProQ])
                                                                local X2 = x + 1
                                                                if i ~= 1 then
                                                                    r.ImGui_DrawList_AddLine(Foreground, x,
                                                                        Y_Mid + 100, X2,
                                                                        Y_Mid - pts[i .. 'B-' .. Band .. FXGUID_ProQ],
                                                                        BandColor, 2)
                                                                end
                                                                x = X2
                                                            end
                                                        end
                                                    end
                                                elseif ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Low Shelf' then --@todo Pro Q -- No support for different slopes
                                                    MIN_Q = 0.1; MAX_Q = 100
                                                    Q[Band] = per_to_q(Q[Band] * 100, 100)



                                                    svf_ls(FreqToActualFreq, Q[Band], Gain[Band])
                                                    local x = ProQ_Xpos_L
                                                    local y = Y_Mid
                                                    if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                                                        for i = 1, ProQ3.Width, 1 do -- do 340 times
                                                            iToFreq = x_to_freq(i)
                                                            mag = zdf_magnitude(iToFreq)
                                                            mag = 20 * math.log(mag, 10)
                                                            mag = db_to_y(mag)
                                                            pts[i .. 'B-' .. Band .. FXGUID_ProQ] = mag *
                                                                ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]]

                                                            if ProQ3.LT_EQBand[FXGUID_ProQ] == Band then
                                                                local X2 = x + 1
                                                                BandColor = determineBandColor(ProQ3.LT_EQBand
                                                                    [FXGUID_ProQ])
                                                                if i ~= 1 then
                                                                    r.ImGui_DrawList_AddLine(Foreground, x, y,
                                                                        X2, Y_Mid - pts
                                                                        [i .. 'B-' .. Band .. FXGUID_ProQ],
                                                                        BandColor)
                                                                end
                                                                x = X2
                                                            end
                                                        end
                                                    end
                                                elseif ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'High Shelf' then
                                                    MIN_Q = 0.1; MAX_Q = 100
                                                    Q[Band] = per_to_q(Q[Band] * 100, 100)

                                                    svf_hs(FreqToActualFreq, Q[Band], Gain[Band])
                                                    local x = ProQ_Xpos_L
                                                    local y = Y_Mid
                                                    if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                                                        for i = 1, ProQ3.Width, 1 do -- do 340 times
                                                            iToFreq = x_to_freq(i)
                                                            mag = zdf_magnitude(iToFreq)
                                                            mag = 20 * math.log(mag, 10)
                                                            mag = db_to_y(mag)
                                                            pts[i .. 'B-' .. Band .. FXGUID_ProQ] = mag *
                                                                ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]]
                                                            if ProQ3.LT_EQBand[FXGUID_ProQ] == Band then
                                                                local X2 = x + 1
                                                                BandColor = determineBandColor(ProQ3.LT_EQBand
                                                                    [FXGUID_ProQ])
                                                                if i ~= 1 then
                                                                    r.ImGui_DrawList_AddLine(Foreground, x, y,
                                                                        X2, Y_Mid - pts
                                                                        [i .. 'B-' .. Band .. FXGUID_ProQ],
                                                                        BandColor)
                                                                end
                                                                x = X2
                                                            end
                                                        end
                                                    end
                                                elseif ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Band Pass' then
                                                    MIN_Q = 0.04; MAX_Q = 3000
                                                    Q[Band] = per_to_q(Q[Band] * 100, 100)
                                                    svf_bp(FreqToActualFreq, Q[Band])
                                                    local x = ProQ_Xpos_L
                                                    local y = Y_Mid
                                                    if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                                                        for i = 1, ProQ3.Width, 1 do -- do 340 times
                                                            iToFreq = x_to_freq(i)
                                                            mag = zdf_magnitude(iToFreq)
                                                            mag = 20 * math.log(mag, 10)
                                                            mag = db_to_y(mag)
                                                            pts[i .. 'B-' .. Band .. FXGUID_ProQ] = mag *
                                                                ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]]
                                                            if ProQ3.LT_EQBand[FXGUID_ProQ] == Band then
                                                                local X2 = x + 1
                                                                BandColor = determineBandColor(ProQ3.LT_EQBand
                                                                    [FXGUID_ProQ])
                                                                if i ~= 1 then
                                                                    r.ImGui_DrawList_AddLine(Foreground, x,
                                                                        Y_Mid + 100, X2,
                                                                        Y_Mid - pts[i .. 'B-' .. Band .. FXGUID_ProQ],
                                                                        BandColor)
                                                                end
                                                                x = X2
                                                            end
                                                        end
                                                    end
                                                elseif ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Notch' then
                                                    MIN_Q = 0.005; MAX_Q = 400
                                                    Q[Band] = per_to_q(Q[Band] * 100, 100)
                                                    svf_bs(FreqToActualFreq, Q[Band])
                                                    local x = ProQ_Xpos_L
                                                    local y = Y_Mid
                                                    if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                                                        for i = 1, ProQ3.Width, 2 do -- do 340 times
                                                            iToFreq = x_to_freq(i)
                                                            mag = zdf_magnitude(iToFreq)
                                                            mag = 20 * math.log(mag, 10)
                                                            mag = db_to_y(mag)
                                                            pts[i .. 'B-' .. Band .. FXGUID_ProQ] = mag *
                                                                ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]]
                                                            if ProQ3.LT_EQBand[FXGUID_ProQ] == Band then
                                                                local X2 = x + 2
                                                                BandColor = determineBandColor(ProQ3.LT_EQBand
                                                                    [FXGUID_ProQ])
                                                                if i ~= 1 then
                                                                    r.ImGui_DrawList_AddLine(Foreground, x, y,
                                                                        X2, Y_Mid - pts
                                                                        [i .. 'B-' .. Band .. FXGUID_ProQ],
                                                                        BandColor)
                                                                end
                                                                x = X2
                                                            end
                                                        end
                                                    end
                                                elseif ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Tilt Shelf' then
                                                    TiltShelf(0.1, 100, 77)
                                                elseif ProQ3.Band_UseState[Band] == 1.0 and ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Flat Tilt' then
                                                    TiltShelf(0.000001, 0.0001, 100, 0.08)
                                                end
                                            end



                                            ----------------------
                                            --==Draw Sum of all EQ
                                            ----------------------
                                            local x = ProQ_Xpos_L
                                            for i = 1, ProQ3.Width, 2 do
                                                pts[i .. FXGUID_ProQ] = 0
                                                for Band = 1, 24, 1 do --Add up the sum of all eq
                                                    if ProQ3.Band_UseState[Band] == 1 then
                                                        if pts[i .. 'B-' .. Band .. FXGUID_ProQ] ~= nil and Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                                                            pts[i .. FXGUID_ProQ] = pts[i .. FXGUID_ProQ] +
                                                                pts[i .. 'B-' .. Band .. FXGUID_ProQ]
                                                        end
                                                    end
                                                end
                                                pts[i .. FXGUID_ProQ] = pts[i .. FXGUID_ProQ]
                                                local X2 = x + 2
                                                if i ~= 1 then
                                                    r.ImGui_DrawList_AddLine(Foreground, x, y, X2,
                                                        Y_Mid - pts[i .. FXGUID_ProQ], 0xFFC43488, 2.5)
                                                end


                                                local Y_Mid = (ProQ_Ypos_T + ProQ3.H / 2)
                                                y = Y_Mid - pts[i .. FXGUID_ProQ]
                                                x = X2
                                            end



                                            r.ImGui_DrawList_AddTextEx(Foreground, Font_Andale_Mono, 9.5,
                                                ProQ_Xpos_L + iPos50 - 3, Y_Mid + 86, 0x78787899, '50')
                                            r.ImGui_DrawList_AddTextEx(Foreground, Font_Andale_Mono, 9.5,
                                                ProQ_Xpos_L + iPos100 - 5, Y_Mid + 86, 0x78787899, '100')
                                            r.ImGui_DrawList_AddTextEx(Foreground, Font_Andale_Mono, 9.5,
                                                ProQ_Xpos_L + iPos200 - 5, Y_Mid + 86, 0x78787899, '200')
                                            r.ImGui_DrawList_AddTextEx(Foreground, Font_Andale_Mono, 9.5,
                                                ProQ_Xpos_L + iPos500 - 5, Y_Mid + 86, 0x78787899, '500')
                                            r.ImGui_DrawList_AddTextEx(Foreground, Font_Andale_Mono, 9.5,
                                                ProQ_Xpos_L + iPos1k - 5, Y_Mid + 86, 0x78787899, '1k')
                                            r.ImGui_DrawList_AddTextEx(Foreground, Font_Andale_Mono, 9.5,
                                                ProQ_Xpos_L + iPos2k - 5, Y_Mid + 86, 0x78787899, '2k')
                                            r.ImGui_DrawList_AddTextEx(Foreground, Font_Andale_Mono, 9.5,
                                                ProQ_Xpos_L + iPos5k - 5, Y_Mid + 86, 0x78787899, '5k')
                                            r.ImGui_DrawList_AddTextEx(Foreground, Font_Andale_Mono, 9.5,
                                                ProQ_Xpos_L + iPos10k - 5, Y_Mid + 86, 0x78787899, '10k')

                                            r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L + iPos50, ProQ_Ypos_B,
                                                ProQ_Xpos_L + iPos50, ProQ_Ypos_T + 300, 0x78787822)
                                            r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L + iPos100, ProQ_Ypos_B,
                                                ProQ_Xpos_L + iPos100, ProQ_Ypos_T + 300, 0x78787844)
                                            r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L + iPos200, ProQ_Ypos_B,
                                                ProQ_Xpos_L + iPos200, ProQ_Ypos_T + 300, 0x78787822)
                                            r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L + iPos500, ProQ_Ypos_B,
                                                ProQ_Xpos_L + iPos500, ProQ_Ypos_T + 300, 0x78787822)
                                            r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L + iPos1k, ProQ_Ypos_B,
                                                ProQ_Xpos_L + iPos1k, ProQ_Ypos_T + 300, 0x78787844)
                                            r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L + iPos2k, ProQ_Ypos_B,
                                                ProQ_Xpos_L + iPos2k, ProQ_Ypos_T + 300, 0x78787822)
                                            r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L + iPos5k, ProQ_Ypos_B,
                                                ProQ_Xpos_L + iPos5k, ProQ_Ypos_T + 300, 0x78787822)
                                            r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L + iPos10k, ProQ_Ypos_B,
                                                ProQ_Xpos_L + iPos10k, ProQ_Ypos_T + 300, 0x78787844)

                                            r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid, ProQ_Xpos_R, Y_Mid,
                                                0x78787844)

                                            if ProQ3['scaleLabel' .. ' ID' .. FXGUID[FX_Idx]] == 30 or ProQ3['scaleLabel' .. ' ID' .. FXGUID[FX_Idx]] == 3 then
                                                local Gain10 = Y_Mid + (ProQ_Ypos_T - Y_Mid) / 3
                                                local Gain20 = Y_Mid + ((ProQ_Ypos_T - Y_Mid) / 3) * 2
                                                local GainMinus10 = Y_Mid - (ProQ_Ypos_T - Y_Mid) / 3
                                                local GainMinus20 = Y_Mid - ((ProQ_Ypos_T - Y_Mid) / 3) * 2

                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Gain10, ProQ_Xpos_R,
                                                    Gain10, 0x78787822)
                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Gain20, ProQ_Xpos_R,
                                                    Gain20, 0x78787822)
                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, GainMinus10,
                                                    ProQ_Xpos_R, GainMinus10, 0x78787822)
                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, GainMinus20,
                                                    ProQ_Xpos_R, GainMinus20, 0x78787822)
                                            elseif ProQ3['scaleLabel' .. ' ID' .. FXGUID[FX_Idx]] == 12 then
                                                local Gain3 = (ProQ_Ypos_T - Y_Mid) / 4
                                                local Gain6 = ((ProQ_Ypos_T - Y_Mid) / 4) * 2
                                                local Gain9 = ((ProQ_Ypos_T - Y_Mid) / 4) * 3

                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid + Gain3,
                                                    ProQ_Xpos_R, Y_Mid + Gain3, 0x78787822)
                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid + Gain6,
                                                    ProQ_Xpos_R, Y_Mid + Gain6, 0x78787822)
                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid + Gain9,
                                                    ProQ_Xpos_R, Y_Mid + Gain9, 0x78787822)
                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid - Gain3,
                                                    ProQ_Xpos_R, Y_Mid - Gain3, 0x78787822)
                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid - Gain6,
                                                    ProQ_Xpos_R, Y_Mid - Gain6, 0x78787822)
                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid - Gain9,
                                                    ProQ_Xpos_R, Y_Mid - Gain9, 0x78787822)
                                            elseif ProQ3['scaleLabel' .. ' ID' .. FXGUID[FX_Idx]] == 6 then
                                                local Gain1 = (ProQ_Ypos_T - Y_Mid) / 6
                                                local Gain2 = Gain1 * 2
                                                local Gain3 = Gain1 * 3
                                                local Gain4 = Gain1 * 4
                                                local Gain5 = Gain1 * 5

                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid + Gain1,
                                                    ProQ_Xpos_R, Y_Mid + Gain1, 0x78787822)
                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid + Gain2,
                                                    ProQ_Xpos_R, Y_Mid + Gain2, 0x78787822)
                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid + Gain3,
                                                    ProQ_Xpos_R, Y_Mid + Gain3, 0x78787822)
                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid + Gain4,
                                                    ProQ_Xpos_R, Y_Mid + Gain4, 0x78787822)
                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid + Gain5,
                                                    ProQ_Xpos_R, Y_Mid + Gain5, 0x78787822)


                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid - Gain1,
                                                    ProQ_Xpos_R, Y_Mid - Gain1, 0x78787822)
                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid - Gain2,
                                                    ProQ_Xpos_R, Y_Mid - Gain2, 0x78787822)
                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid - Gain3,
                                                    ProQ_Xpos_R, Y_Mid - Gain3, 0x78787822)
                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid - Gain4,
                                                    ProQ_Xpos_R, Y_Mid - Gain4, 0x78787822)
                                                r.ImGui_DrawList_AddLine(Foreground, ProQ_Xpos_L, Y_Mid - Gain5,
                                                    ProQ_Xpos_R, Y_Mid - Gain5, 0x78787822)
                                            end


                                            ----------------------
                                            --Draw Nodes
                                            ----------------------
                                            NodeY_Pos = {}
                                            NodeHvr = {}
                                            NodeHasbeenHovered = nil
                                            MousePosX, MousePosY = r.ImGui_GetMousePos(ctx)

                                            for Band = 1, 24, 1 do
                                                if ProQ3.Band_UseState[Band] == 1 then
                                                    NodeFreq['B-' .. Band .. 'GUID-' .. FXGUID_ProQ] = x_to_freq(Freq
                                                        [Band] * ProQ3.Width)
                                                    XposNode[Band] = freq_to_scx(NodeFreq
                                                        ['B-' .. Band .. 'GUID-' .. FXGUID_ProQ])
                                                    _, ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] = r
                                                        .TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,
                                                            8 + 13 * (Band - 1))

                                                    determineBandColor(Band)
                                                    if ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Bell' then
                                                        NodeY_Pos[Band] = Y_Mid -
                                                            (Gain[Band] * 3.2) *
                                                            ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]];
                                                    elseif ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Low Cut' then
                                                        NodeY_Pos[Band] = Y_Mid -
                                                            (Q_Node[Band]) * ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]]
                                                    elseif ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'High Cut' then
                                                        NodeY_Pos[Band] = Y_Mid -
                                                            (Q_Node[Band]) * ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]]
                                                    elseif ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Low Shelf' then
                                                        NodeY_Pos[Band] = Y_Mid -
                                                            (ShelfGain_Node) * ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]]
                                                    elseif ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'High Shelf' then
                                                        NodeY_Pos[Band] = Y_Mid -
                                                            (ShelfGain_Node) * ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]]
                                                    elseif ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Band Pass' then
                                                        NodeY_Pos[Band] = Y_Mid
                                                    elseif ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Notch' then
                                                        NodeY_Pos[Band] = Y_Mid
                                                    elseif ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Tilt Shelf' then
                                                        NodeY_Pos[Band] = Y_Mid -
                                                            (Gain[Band] * 1.4) *
                                                            ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]]
                                                    elseif ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Flat Tilt' then
                                                        NodeY_Pos[Band] = Y_Mid -
                                                            (0.08 * 1.4) * ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]]
                                                    end


                                                    if Band_Enabled[Band .. FXGUID_ProQ] == 1 then
                                                        r.ImGui_DrawList_AddCircleFilled(Foreground,
                                                            ProQ_Xpos_L + XposNode[Band], NodeY_Pos[Band], 6,
                                                            Clr_FullAlpha)
                                                    else
                                                        r.ImGui_DrawList_AddCircleFilled(Foreground,
                                                            ProQ_Xpos_L + (XposNode[Band] or 0), NodeY_Pos[Band] or 0, 6,
                                                            Clr_HalfAlpha)
                                                    end
                                                    if ProQ_Xpos_L and XposNode[Band] and NodeY_Pos[Band] then
                                                        if Band <= 9 then
                                                            r.ImGui_DrawList_AddTextEx(Foreground,
                                                                Font_Andale_Mono, 12, ProQ_Xpos_L + XposNode[Band] - 2.5,
                                                                NodeY_Pos[Band] - 4.5, 0x000000ff, Band)
                                                        end
                                                        if Band > 9 then
                                                            r.ImGui_DrawList_AddTextEx(Foreground,
                                                                Font_Andale_Mono, 10, ProQ_Xpos_L + XposNode[Band] - 5,
                                                                NodeY_Pos[Band] - 4, 0x000000ff, Band)
                                                        end
                                                    end

                                                    local NodeHoverArea = 10
                                                    if MousePosX > ProQ_Xpos_L + XposNode[Band] - NodeHoverArea and MousePosX < ProQ_Xpos_L + XposNode[Band] + NodeHoverArea and MousePosY > NodeY_Pos[Band] - NodeHoverArea and MousePosY < NodeY_Pos[Band] + NodeHoverArea then
                                                        ProQ3['NodeHvr' .. Band .. 'FXID-' .. FXGUID[FX_Idx]] = true
                                                        HvringNode = Band
                                                    else
                                                        ProQ3['NodeHvr' .. Band .. 'FXID-' .. FXGUID[FX_Idx]] = false
                                                    end

                                                    if ProQ3['NodeHvr' .. Band .. 'FXID-' .. FXGUID[FX_Idx]] == true then
                                                        NodeHasbeenHovered = true
                                                        FX_DeviceWindow_NoScroll = r.ImGui_WindowFlags_NoScrollWithMouse()
                                                        r.ImGui_DrawList_AddCircle(Foreground, ProQ_Xpos_L +
                                                            XposNode[Band], NodeY_Pos[Band], 7.7, 0xf0f0f0ff)
                                                        if IsLBtnHeld then
                                                            r.ImGui_DrawList_AddCircleFilled(Foreground,
                                                                ProQ_Xpos_L + XposNode[Band], NodeY_Pos[Band], 7.7,
                                                                Clr_HalfAlpha)
                                                            if IsLBtnClicked then ProQ3['NodeDrag' .. Band .. ' ID-' .. FXGUID[FX_Idx]] = true end
                                                        end

                                                        local QQ = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                            ((Band - 1) * 13) + 7)
                                                        if Wheel_V ~= 0 then --if wheel is moved
                                                            HoverOnScrollItem = true
                                                            MousePosX_AdjustingQ, Y = reaper.GetMousePosition()
                                                            ProQ3['AdjustingQ' .. FXGUID[FX_Idx]] = true
                                                            BandforQadjusting = Band
                                                        end
                                                        if IsLBtnClicked and Mods == Alt then -- delete node
                                                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                                ((Band - 1) * 13),
                                                                0)
                                                            ProQ3['NodeHvr' .. Band .. 'FXID-' .. FXGUID[FX_Idx]] = false
                                                            HvringNode = nil
                                                        end

                                                        if LBtnClickCount == 2 then
                                                            local OnOff = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                                ((Band - 1) * 13) + 1)

                                                            if OnOff == 1 then
                                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                                    ((Band - 1) * 13) + 1, 0)
                                                            else
                                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                                    ((Band - 1) * 13) + 1, 1)
                                                            end
                                                        end
                                                        if IsRBtnClicked == true then
                                                            r.ImGui_OpenPopup(ctx, 'Pro-Q R Click')
                                                        end
                                                    else
                                                        FX_DeviceWindow_NoScroll = 0
                                                    end




                                                    if ProQ3['AdjustingQ' .. FXGUID[FX_Idx]] then
                                                        local MousePosX_AdjustingQ_CheckXpos, Y = reaper
                                                            .GetMousePosition()
                                                        if Mods == Shift then
                                                            WheelQFineAdj = 20
                                                        else
                                                            WheelQFineAdj = 1
                                                        end
                                                        if MousePosX_AdjustingQ_CheckXpos < MousePosX_AdjustingQ + 7 and MousePosX_AdjustingQ_CheckXpos > MousePosX_AdjustingQ - 7 then
                                                            local QQ = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                                ((BandforQadjusting - 1) * 13) + 7)

                                                            Q_Output = SetMinMax(QQ - ((Wheel_V / 50) / WheelQFineAdj), 0,
                                                                1)

                                                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                                ((BandforQadjusting - 1) * 13) + 7, Q_Output)
                                                        else
                                                            ProQ3['AdjustingQ' .. FXGUID[FX_Idx]] = false
                                                        end
                                                    end


                                                    if ProQ3['NodeDrag' .. Band .. ' ID-' .. FXGUID[FX_Idx]] == true then
                                                        MouseDeltaX, MouseDeltaY = r.ImGui_GetMouseDelta(ctx)
                                                        local Freq = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                            ((Band - 1) * 13) + 2)
                                                        local Gain = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                            ((Band - 1) * 13) + 3)
                                                        local Q = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                            ((Band - 1) * 13) + 7)

                                                        if IsLBtnHeld == false then
                                                            ProQ3['NodeDrag' .. Band .. ' ID-' .. FXGUID[FX_Idx]] = false
                                                        end
                                                        -- finetune if shift is held
                                                        if Mods == Shift then
                                                            HorizDragScale = 1000
                                                        else
                                                            HorizDragScale = 400
                                                        end
                                                        if Mods == Shift then
                                                            QDragScale = 400
                                                        else
                                                            QDragScale = 120
                                                        end

                                                        if ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'Low Cut' or ProQ3['Shape of Band' .. Band .. 'ID' .. FXGUID_ProQ] == 'High Cut' then
                                                            Q_Output = Q +
                                                                (-MouseDeltaY / QDragScale) *
                                                                (ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] / ProQ3['DragGainScale' .. ' ID' .. FXGUID[FX_Idx]])
                                                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                                ((Band - 1) * 13) + 7, Q_Output)

                                                            if Freq > 1 and MouseDeltaX > 0 then
                                                                FreqOutput = 1
                                                            elseif Freq < 0 and MouseDeltaX < 0 then
                                                                FreqOutput = 0
                                                            else
                                                                FreqOutput = Freq + MouseDeltaX / HorizDragScale
                                                            end
                                                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                                ((Band - 1) * 13) + 2, FreqOutput)
                                                        else
                                                            if Gain > 1 and MouseDeltaY < 0 then
                                                                GainOutput = 1
                                                            elseif Gain < 0 and MouseDeltaY > 0 then
                                                                GainOutput = 0
                                                            else
                                                                GainOutput = Gain +
                                                                    (-MouseDeltaY / 270) *
                                                                    (ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] / ProQ3['DragGainScale' .. ' ID' .. FXGUID[FX_Idx]])
                                                            end

                                                            if Freq > 1 and MouseDeltaX > 0 then
                                                                FreqOutput = 1
                                                            elseif Freq < 0 and MouseDeltaX < 0 then
                                                                FreqOutput = 0
                                                            else
                                                                FreqOutput = Freq + MouseDeltaX / HorizDragScale
                                                            end

                                                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                                ((Band - 1) * 13) + 2, FreqOutput)
                                                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                                ((Band - 1) * 13) + 3, GainOutput)
                                                        end
                                                    end







                                                    -- if i == iPos10k then r.ImGui_DrawList_AddTextEx(Foreground, Font_Andale_Mono, 12, ProQ_Xpos_L+XposNode[Band],  Y_Mid- (Gain[B]*3.2)  , 0x78787899, '10K') end
                                                    if LT_ParamNum ~= nil then
                                                        local m = m;
                                                        _, tracknumber, fxnumber, paramnumber = reaper.GetLastTouchedFX()
                                                        proQ_LT_GUID = reaper.TrackFX_GetFXGUID(LT_Track, fxnumber)

                                                        for i = 1, RepeatTimeForWindows, 1 do
                                                            GUIDtoCompare = reaper.TrackFX_GetFXGUID(LT_Track, fxnumber)
                                                            if proQ_LT_GUID == GUIDtoCompare and proQ_LT_GUID ~= nil then
                                                                for i = 1, 24, 1 do
                                                                    if LT_ParamNum > 13 * (i - 1) and LT_ParamNum < 13 * i then
                                                                        ProQ3.LT_EQBand[proQ_LT_GUID] = i
                                                                    end
                                                                end
                                                            end
                                                        end
                                                        if ProQ3.GainDragging == true then
                                                            MouseDeltaX, MouseDeltaY = r.ImGui_GetMouseDelta(ctx)

                                                            local Gain = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                                ((ProQ3.LT_EQBand[proQ_LT_GUID] - 1) * 13) + 3)

                                                            if Gain > 1 and MouseDeltaY < 0 then
                                                                GainOutput = 1
                                                            elseif Gain < 0 and MouseDeltaY > 0 then
                                                                GainOutput = 0
                                                            else
                                                                GainOutput = Gain +
                                                                    (-MouseDeltaY / 270) *
                                                                    (ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] / ProQ3['DragGainScale' .. ' ID' .. FXGUID[FX_Idx]])
                                                            end
                                                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                                ((ProQ3.LT_EQBand[proQ_LT_GUID] - 1) * 13) + 3,
                                                                GainOutput)
                                                        end
                                                        if ProQ3.FreqDragging == true then
                                                            MouseDeltaX, MouseDeltaY = r.ImGui_GetMouseDelta(ctx)
                                                            if Mods == Shift then
                                                                HorizDragScale = 1300
                                                            else
                                                                HorizDragScale = 400
                                                            end
                                                            local Freq = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                                ((ProQ3.LT_EQBand[proQ_LT_GUID] - 1) * 13) + 2)

                                                            if Freq > 1 and MouseDeltaX > 0 then
                                                                FreqOutput = 1
                                                            elseif Freq < 0 and MouseDeltaX < 0 then
                                                                FreqOutput = 0
                                                            else
                                                                FreqOutput = Freq + MouseDeltaX / HorizDragScale
                                                            end
                                                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                                ((ProQ3.LT_EQBand[proQ_LT_GUID] - 1) * 13) + 2,
                                                                FreqOutput)
                                                        end
                                                    end
                                                end --end for repeat every active  band
                                            end     --end for repeat every band
                                            if NodeHasbeenHovered then HoverOnScrollItem = true end



                                            if r.ImGui_BeginPopup(ctx, 'Pro-Q R Click') then
                                                local LTBand = ProQ3.LT_EQBand[FXGUID[FX_Idx]]
                                                if r.ImGui_Button(ctx, 'Bell') then
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8,
                                                        0)
                                                    r.ImGui_CloseCurrentPopup(ctx)
                                                end
                                                if r.ImGui_Button(ctx, 'Low Shelf') then
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8,
                                                        0.11)
                                                    r.ImGui_CloseCurrentPopup(ctx)
                                                end
                                                if r.ImGui_Button(ctx, 'Low Cut') then
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8,
                                                        0.22)
                                                    r.ImGui_CloseCurrentPopup(ctx)
                                                end
                                                if r.ImGui_Button(ctx, 'High Shelf') then
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8,
                                                        0.33)
                                                    r.ImGui_CloseCurrentPopup(ctx)
                                                end
                                                if r.ImGui_Button(ctx, 'High Cut') then
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8,
                                                        0.44)
                                                    r.ImGui_CloseCurrentPopup(ctx)
                                                end
                                                if r.ImGui_Button(ctx, 'Notch') then
                                                    r.TrackFX_SetParam(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8, 0.60)
                                                    r.ImGui_CloseCurrentPopup(ctx)
                                                end
                                                if r.ImGui_Button(ctx, 'Band Pass') then
                                                    r.TrackFX_SetParam(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8, 0.72)
                                                    r.ImGui_CloseCurrentPopup(ctx)
                                                end
                                                if r.ImGui_Button(ctx, 'Tilt Shelf') then
                                                    r.TrackFX_SetParam(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8, 0.86)
                                                    r.ImGui_CloseCurrentPopup(ctx)
                                                end
                                                if r.ImGui_Button(ctx, 'Flat Tilt') then
                                                    r.TrackFX_SetParam(LT_Track, FX_Idx, 13 * (LTBand - 1) + 8, 1)
                                                    r.ImGui_CloseCurrentPopup(ctx)
                                                end
                                                reaper.ImGui_EndPopup(ctx)
                                            end


                                            ------------------------------------------
                                            --Add new node by double click
                                            ------------------------------------------

                                            if ProQ3['HvrGUI' .. FXGUID[FX_Idx]] and LBtnClickCount == 2 then
                                                if HvringNode == nil or ProQ3['NodeHvr' .. HvringNode .. 'FXID-' .. FXGUID[FX_Idx]] ~= true then
                                                    UnusedBandFound = false
                                                    local Band = 1
                                                    while (UnusedBandFound == false) do
                                                        if ProQ3.Band_UseState[Band] ~= 1 then
                                                            UnusedBandFound = true
                                                            BandNotInUse = Band
                                                        end
                                                        Band = Band + 1
                                                    end
                                                    reaper.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                        13 * (BandNotInUse - 1), 1)
                                                    MouseX_AddNode, MouseY_AddNode = reaper.ImGui_GetMousePos(ctx)

                                                    local FreqToAddNode = (MouseX_AddNode - ProQ_Xpos_L) / ProQ3.Width
                                                    reaper.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                        13 * (BandNotInUse - 1) + 2, FreqToAddNode)
                                                    local GainToAddNode = ((((Y_Mid - MouseY_AddNode) - 100) / 100 + 1) / ProQ3['scale' .. ' ID' .. FXGUID[FX_Idx]] + 1) /
                                                        2
                                                    reaper.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                        13 * (BandNotInUse - 1) + 3, GainToAddNode)
                                                    if FreqToAddNode > 0.9 then
                                                        reaper.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                            13 * (BandNotInUse - 1) + 8, 0.5)
                                                    elseif FreqToAddNode < 0.1 then
                                                        reaper.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                            13 * (BandNotInUse - 1) + 8, 0.25)
                                                    else
                                                        reaper.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                            13 * (BandNotInUse - 1) + 8, 0.02)
                                                    end
                                                end
                                            end

                                            stopp = true

                                            step = ProQ3.Width / 200

                                            r.ImGui_DrawList_PathStroke(Foreground, 0x99999988, nil, 3)



                                            r.ImGui_EndChildFrame(ctx)
                                        end ---- End of if begin pro-Q frame then

                                        ProQ3['HvrGUI' .. FXGUID[FX_Idx]] = reaper.ImGui_IsItemHovered(ctx)
                                        --if ProQ3['HvrGUI'..FXGUID[FX_Idx]] then FX_DeviceWindow_NoScroll= 0--[[ r.ImGui_WindowFlags_NoScrollWithMouse() ]] end

                                        r.ImGui_PopStyleColor(ctx, 1)

                                        if FX.Enable[FX_Idx] == false then
                                            local drawlist = reaper.ImGui_GetForegroundDrawList(ctx)
                                            r.ImGui_DrawList_AddRectFilled(drawlist, ProQ_Xpos_L, ProQ_Ypos_T - 20,
                                                ProQ_Xpos_L + ProQ3.Width, ProQ_Ypos_T + ProQ3.H, 0x00000077)
                                        end


                                        if FX.Win_Name[math.max(FX_Idx - 1, 0)]:find('FXD ReSpectrum') then
                                            r.TrackFX_Show(LT_Track, FX_Idx - 1, 2)
                                            if tablefind(Trk[TrkID].PreFX, FxGUID) then
                                                r.TrackFX_Delete(LT_Track,
                                                    FX_Idx - 1)
                                            end
                                            SyncAnalyzerPinWithFX(FX_Idx - 1, FX_Idx,
                                                FX.Win_Name[math.max(FX_Idx - 1, 0)])
                                        else -- if no spectrum is before pro-Q 3
                                            FX[FxGUID].AddEQSpectrumWait = (FX[FxGUID].AddEQSpectrumWait or 0) + 1
                                            if FX[FxGUID].AddEQSpectrumWait > FX_Add_Del_WaitTime then
                                                r.gmem_attach('gmemReEQ_Spectrum')
                                                r.gmem_write(1, PM.DIY_TrkID[TrkID])
                                                FX[FxGUID].ProQ_ID = FX[FxGUID].ProQ_ID or math.random(1000000, 9999999)
                                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: ProQ_ID ' .. FxGUID,
                                                    FX[FxGUID].ProQ_ID, true)
                                                r.gmem_write(2, FX[FxGUID].ProQ_ID)
                                                local AnyPopupOpen
                                                if r.ImGui_IsPopupOpen(ctx, 'Delete FX Layer ', r.ImGui_PopupFlags_AnyPopupId() + r.ImGui_PopupFlags_AnyPopupLevel()) then AnyPopupOpen = true end

                                                if not tablefind(Trk[TrkID].PostFX, FxGUID) and not tablefind(Trk[TrkID].PreFX, FxGUID) and not AnyPopupOpen then
                                                    r.gmem_attach('gmemReEQ_Spectrum')
                                                    r.gmem_write(1, PM.DIY_TrkID[TrkID])
                                                    FX[FxGUID].ProQ_ID = FX[FxGUID].ProQ_ID or
                                                        math.random(1000000, 9999999)
                                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: ProQ_ID ' .. FxGUID,
                                                        FX[FxGUID].ProQ_ID, true)
                                                    r.gmem_write(2, FX[FxGUID].ProQ_ID)
                                                    rv = r.TrackFX_AddByName(LT_Track, 'FXD ReSpectrum', 0, -1000 -
                                                        FX_Idx)
                                                end
                                                FX[FxGUID].AddEQSpectrumWait = 0
                                                r.TrackFX_Show(LT_Track, FX_Idx - 1, 2)
                                                for i = 0, 16, 1 do
                                                    --r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, i,0,0)
                                                    r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 1, i, 0, 0)
                                                end
                                            end
                                        end

                                        r.gmem_attach('gmemReEQ_Spectrum')
                                        r.gmem_write(1, PM.DIY_TrkID[TrkID])
                                        --  r.gmem_write(0, FX_Idx)
                                    end --------------- End of Pro - Q


                                    if FX.Enable[FX_Idx] == false then
                                        r.ImGui_DrawList_AddRectFilled(WDL, Win_L, Win_T,
                                            Win_R, Win_B, 0x00000088)
                                    end


                                    r.ImGui_EndChild(ctx)
                                end
                            end


                            --------------------------------------------------------------------------------------
                            --------------------------------------Draw Mode --------------------------------------
                            --------------------------------------------------------------------------------------

                            --------------------FX Devices--------------------

                            reaper.ImGui_PopStyleColor(ctx, poptimes) -- -- PopColor #1 FX Window
                            reaper.ImGui_SameLine(ctx, nil, 0)








                            r.ImGui_EndGroup(ctx)
                        end
                        if BlinkFX == FX_Idx then BlinkFX = BlinkItem(0.2, 2, BlinkFX) end
                    end --of Create fx window function

                    if --[[Normal Window]] (not string.find(FX_Name, 'FXD %(Mix%)RackMixer')) and FX.InLyr[FXGUID[FX_Idx]] == nil and FX_Idx ~= RepeatTimeForWindows and FindStringInTable(BlackListFXs, FX_Name) ~= true then
                        --FX_IdxREAL =  FX_Idx+Lyr.FX_Ins[FXGUID[FX_Idx]]

                        if not tablefind(Trk[TrkID].PostFX, FxGUID) and not FX[FxGUID].InWhichBand then
                            createFXWindow(FX_Idx)
                            local rv, inputPins, outputPins = r.TrackFX_GetIOSize(LT_Track, FX_Idx)
                        end
                        if FX.LayEdit == FXGUID[FX_Idx] then
                            if not ctx then ctx = r.ImGui_CreateContext('Layout Editor') end
                            --r.ImGui_BeginTooltip( ctx)

                            --attachfonts(ctx)



                            rv, LayEdProp_Open = r.ImGui_Begin(ctx, 'LayoutEdit Propertiess', true,
                                r.ImGui_WindowFlags_MenuBar() + r.ImGui_WindowFlags_NoCollapse() +
                                r.ImGui_WindowFlags_NoTitleBar() + r.ImGui_WindowFlags_NoDocking())
                            --r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x191919ff ) ;
                            local FxGUID = FXGUID[FX_Idx]

                            if rv and LayEdProp_Open then
                                --if not CloseLayEdit   then    ----START CHILD WINDOW------
                                -- Add Drawings ----
                                if not LE.Sel_Items[1] then
                                    if Draw.DrawMode[FxGUID] ~= true then
                                        r.ImGui_TextWrapped(ctx, 'Select an item to start editing')
                                        AddSpacing(15)



                                        if r.ImGui_Button(ctx, 'Enter Draw Mode ') then
                                            Draw.DrawMode[FxGUID] = true
                                            if Draw[FX.Win_Name_S[FX_Idx]] == nil then
                                                Draw[FX.Win_Name_S[FX_Idx]] = {
                                                    Rect = {},
                                                    clr = {},
                                                    ItemInst = {},
                                                    L = {},
                                                    R = {},
                                                    Y = {},
                                                    T = {},
                                                    B = {},
                                                    Type = {},
                                                    FxGUID = {},
                                                    Txt = {}
                                                }
                                            end
                                        end
                                    else
                                        if r.ImGui_Button(ctx, 'Exit Draw Mode ') then Draw.DrawMode[FxGUID] = false end
                                        r.ImGui_Text(ctx, 'Type:')
                                        r.ImGui_SameLine(ctx)
                                        r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), 0x99999933)
                                        local D = Draw[FX.Win_Name_S[FX_Idx]]
                                        local typelbl; local It = Draw.SelItm
                                        if Draw.SelItm then typelbl = D.Type[Draw.SelItm] end
                                        if Draw.Type == nil then Draw.Type = 'line' end
                                        if r.ImGui_BeginCombo(ctx, '##', typelbl or Draw.Type or 'line', r.ImGui_ComboFlags_NoArrowButton()) then
                                            if r.ImGui_Selectable(ctx, 'line') then
                                                if Draw.SelItm then D.Type[Draw.SelItm] = 'line' end
                                                Draw.Type = 'line'
                                            end
                                            if r.ImGui_Selectable(ctx, 'V-Line') then
                                                if It then D.Type[It] = 'V-line' end
                                                Draw.Type = 'V-line'
                                            end
                                            if r.ImGui_Selectable(ctx, 'rectangle') then
                                                if It then D.Type[It] = 'rectangle' end
                                                Draw.Type = 'rectangle'
                                            end
                                            if r.ImGui_Selectable(ctx, 'rect fill') then
                                                if It then D.Type[It] = 'rect fill' end
                                                Draw.Type = 'rect fill'
                                            end
                                            if r.ImGui_Selectable(ctx, 'circle') then
                                                if It then D.Type[It] = 'circle' end
                                                Draw.Type = 'circle'
                                            end
                                            if r.ImGui_Selectable(ctx, 'circle fill') then
                                                if It then D.Type[It] = 'circle fill' end
                                                Draw.Type = 'circle fill'
                                            end
                                            if r.ImGui_Selectable(ctx, 'Text') then
                                                if It then D.Type[It] = 'Text' end
                                                Draw.Type = 'Text'
                                            end

                                            r.ImGui_EndCombo(ctx)
                                        end
                                        r.ImGui_Text(ctx, 'Color :')
                                        r.ImGui_SameLine(ctx)
                                        if Draw.SelItm and D.clr[Draw.SelItm] then
                                            clrpick, D.clr[Draw.SelItm] = r.ImGui_ColorEdit4(ctx, '##',
                                                D.clr[Draw.SelItm] or 0xffffffff,
                                                r.ImGui_ColorEditFlags_NoInputs()|
                                                r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                                reaper.ImGui_ColorEditFlags_AlphaBar())
                                        else
                                            clrpick, Draw.clr = r.ImGui_ColorEdit4(ctx, '##', Draw.clr or 0xffffffff,
                                                r.ImGui_ColorEditFlags_NoInputs()|
                                                r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                                reaper.ImGui_ColorEditFlags_AlphaBar())
                                        end
                                        r.ImGui_Text(ctx, 'Default edge rounding :')
                                        r.ImGui_SameLine(ctx)
                                        r.ImGui_SetNextItemWidth(ctx, 40)
                                        EditER, Draw.Df_EdgeRound[FxGUID] = r.ImGui_DragDouble(ctx, '##' .. FxGUID,
                                            Draw.Df_EdgeRound[FxGUID], 0.05, 0, 30, '%.2f')

                                        if Draw.SelItm then
                                            r.ImGui_Text(ctx, 'Start Pos X:')
                                            r.ImGui_SameLine(ctx)
                                            _, D.L[It] = r.ImGui_DragDouble(ctx, '##' .. Draw.SelItm .. 'L',
                                                D.L[Draw.SelItm], 1, 0, Win_W, '%.0f')
                                            if D.Type[It] ~= 'V-line' and D.Type[It] ~= 'circle' and D.Type[It] ~= 'circle fill' then
                                                r.ImGui_Text(ctx, 'End Pos X:')
                                                r.ImGui_SameLine(ctx)
                                                _, D.R[It] = r.ImGui_DragDouble(ctx, '##' .. Draw.SelItm .. 'R',
                                                    D.R[Draw.SelItm], 1, 0, Win_W, '%.0f')
                                            end

                                            if D.Type[It] == 'circle' or D.Type[It] == 'circle fill' then
                                                r.ImGui_Text(ctx, 'Radius:')
                                                r.ImGui_SameLine(ctx)
                                                _, D.R[It] = r.ImGui_DragDouble(ctx, '##' .. Draw.SelItm .. 'R',
                                                    D.R[Draw.SelItm], 1, 0, Win_W, '%.0f')
                                            end


                                            r.ImGui_Text(ctx, 'Start Pos Y:')
                                            r.ImGui_SameLine(ctx)
                                            _, D.T[Draw.SelItm] = r.ImGui_DragDouble(ctx, '##' .. Draw.SelItm .. 'T',
                                                D.T[Draw.SelItm], 1, 0, Win_W, '%.0f')


                                            if D.Type[It] ~= 'line' and D.Type[It] ~= 'circle fill' and D.Type[It] ~= 'circle' then
                                                r.ImGui_Text(ctx, 'End Pos Y:')
                                                r.ImGui_SameLine(ctx)
                                                _, D.B[It] = r.ImGui_DragDouble(ctx, '##' .. It .. 'B', D.B[It], 1, 0,
                                                    Win_W, '%.0f')
                                            end

                                            if D.Type[It] == 'Text' then
                                                r.ImGui_Text(ctx, 'Text:')
                                                r.ImGui_SameLine(ctx)
                                                _, D.Txt[It] = r.ImGui_InputText(ctx, '##' .. It .. 'Txt', D.Txt[It])
                                            end
                                        end



                                        r.ImGui_PopStyleColor(ctx)
                                    end
                                elseif LE.Sel_Items[1] then
                                    local ID, TypeID; local FrstSelItm = FX[FxGUID][LE.Sel_Items[1]]; local FItm = LE
                                        .Sel_Items[1]
                                    local R_ofs = 50
                                    if LE.Sel_Items[1] and not LE.Sel_Items[2] then
                                        ID       = FxGUID .. LE.Sel_Items[1]
                                        WidthID  = FxGUID .. LE.Sel_Items[1]
                                        ClrID    = FxGUID .. LE.Sel_Items[1]
                                        GrbClrID = FxGUID .. LE.Sel_Items[1]
                                        TypeID   = FxGUID .. LE.Sel_Items[1]
                                    elseif LE.Sel_Items[2] then
                                        local Diff_Types_Found, Diff_Width_Found, Diff_Clr_Found, Diff_GrbClr_Found
                                        for i, v in pairs(LE.Sel_Items) do
                                            local lastV
                                            if i > 1 then
                                                local frst = LE.Sel_Items[1]; local other = LE.Sel_Items[i];
                                                if FX[FxGUID][1].Type ~= FX[FxGUID][v].Type then Diff_Types_Found = true end
                                                --if FX[FxGUID][frst].Sldr_W ~= FX[FxGUID][v].Sldr_W then  Diff_Width_Found = true    end
                                                --if FX[FxGUID][frst].BgClr  ~= FX[FxGUID][v].BgClr  then Diff_Clr_Found = true       end
                                                --if FX[FxGUID][frst].GrbClr ~= FX[FxGUID][v].GrbClr then Diff_GrbClr_Found = true end
                                            end
                                        end
                                        if Diff_Types_Found then
                                            TypeID = 'Group'
                                        else
                                            TypeID = FxGUID .. LE.Sel_Items
                                                [1]
                                        end
                                        if Diff_Width_Found then
                                            WidthID = 'Group'
                                        else
                                            WidthID = FxGUID ..
                                                LE.Sel_Items[1]
                                        end
                                        if Diff_Clr_Found then ClrID = 'Group' else ClrID = FxGUID .. LE.Sel_Items[1] end
                                        if Diff_GrbClr_Found then
                                            GrbClrID = 'Group'
                                        else
                                            GrbClrID = FxGUID ..
                                                LE.Sel_Items[1]
                                        end
                                        ID = FxGUID .. LE.Sel_Items[1]
                                    else
                                        ID = FxGUID .. LE.Sel_Items[1]
                                    end
                                    local function FreeValuePosSettings()
                                        if FrstSelItm.V_Pos == 'Free' then
                                            r.ImGui_Text(ctx, 'X:')
                                            SL()
                                            r.ImGui_SetNextItemWidth(ctx, 50)
                                            local EditPosX, PosX = r.ImGui_DragDouble(ctx,
                                                ' ##EditValuePosX' .. FxGUID .. LE.Sel_Items[1], FrstSelItm.V_Pos_X or 0,
                                                0.25, nil, nil, '%.2f')
                                            SL()
                                            if EditPosX then
                                                for i, v in pairs(LE.Sel_Items) do FrstSelItm.V_Pos_X = PosX end
                                            end
                                            r.ImGui_Text(ctx, 'Y:')
                                            SL()
                                            r.ImGui_SetNextItemWidth(ctx, 50)
                                            local EditPosY, PosY = r.ImGui_DragDouble(ctx,
                                                ' ##EditValuePosY' .. FxGUID .. LE.Sel_Items[1], FrstSelItm.V_Pos_Y or 0,
                                                0.25, nil, nil, '%.2f')
                                            SL()
                                            if EditPosY then
                                                for i, v in pairs(LE.Sel_Items) do FrstSelItm.V_Pos_Y = PosY end
                                            end
                                        end
                                    end
                                    local function FreeLblPosSettings()
                                        if FrstSelItm.Lbl_Pos == 'Free' then
                                            r.ImGui_Text(ctx, 'X:')
                                            SL()
                                            r.ImGui_SetNextItemWidth(ctx, 50)
                                            local EditPosX, PosX = r.ImGui_DragDouble(ctx,
                                                ' ##EditLblPosX' .. FxGUID .. LE.Sel_Items[1], FrstSelItm.Lbl_Pos_X or 0,
                                                0.25, nil, nil, '%.2f')
                                            SL()
                                            if EditPosX then
                                                for i, v in pairs(LE.Sel_Items) do FrstSelItm.Lbl_Pos_X = PosX end
                                            end
                                            r.ImGui_Text(ctx, 'Y:')
                                            SL()
                                            r.ImGui_SetNextItemWidth(ctx, 50)
                                            local EditPosY, PosY = r.ImGui_DragDouble(ctx,
                                                ' ##EditLblPosY' .. FxGUID .. LE.Sel_Items[1], FrstSelItm.Lbl_Pos_Y or 0,
                                                0.25, nil, nil, '%.2f')
                                            SL()
                                            if EditPosY then
                                                for i, v in pairs(LE.Sel_Items) do FrstSelItm.Lbl_Pos_Y = PosY end
                                            end
                                        end
                                    end
                                    local function AddOption(Name, TargetVar, TypeCondition)
                                        if FrstSelItm.Type == TypeCondition or not TypeCondition then
                                            if r.ImGui_Selectable(ctx, Name) then
                                                for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v][TargetVar] = Name end
                                            end
                                        end
                                    end

                                    -----Type--------

                                    local PrmTypeLbl

                                    if TypeID == 'Group' then
                                        PrmTypeLbl = 'Multiple Values'
                                    else
                                        PrmTypeLbl = FrstSelItm
                                            .Type or ''
                                    end
                                    if not FrstSelItm.Type then FrstSelItm.Type = FX.Def_Type[FxGUID] end
                                    r.ImGui_Text(ctx, 'Type : '); r.ImGui_SameLine(ctx); r.ImGui_PushStyleColor(ctx,
                                        r.ImGui_Col_FrameBg(), 0x444444aa)
                                    r.ImGui_SetNextItemWidth(ctx, -R_ofs)
                                    if r.ImGui_BeginCombo(ctx, '##', PrmTypeLbl, r.ImGui_ComboFlags_NoArrowButton()) then
                                        local function SetItemType(Type)
                                            for i, v in pairs(LE.Sel_Items) do
                                                FX[FxGUID][v].Sldr_W = nil
                                                FX[FxGUID][v].Type = Type
                                            end
                                        end

                                        if r.ImGui_Selectable(ctx, 'Slider') then
                                            SetItemType('Slider')
                                        elseif r.ImGui_Selectable(ctx, 'Knob') then
                                            SetItemType('Knob')
                                        elseif r.ImGui_Selectable(ctx, 'V-Slider') then
                                            SetItemType('V-Slider')
                                        elseif r.ImGui_Selectable(ctx, 'Drag') then
                                            SetItemType('Drag')
                                        elseif r.ImGui_Selectable(ctx, 'Switch') then
                                            SetItemType('Switch')
                                        elseif r.ImGui_Selectable(ctx, 'Selection') then
                                            SetItemType('Selection')
                                        end
                                        r.ImGui_EndCombo(ctx)
                                    end

                                    ---Label    Show only when there's one item selected-----
                                    if LE.Sel_Items[1] and not LE.Sel_Items[2] then
                                        r.ImGui_Text(ctx, 'Label: '); r.ImGui_SameLine(ctx)
                                        r.ImGui_SetNextItemWidth(ctx, -R_ofs)
                                        local LblEdited, buf = r.ImGui_InputText(ctx,
                                            ' ##Edit Title' .. FxGUID .. LE.Sel_Items[1], FrstSelItm.CustomLbl or buf)
                                        if r.ImGui_IsItemActivated(ctx) then EditingPrmLbl = LE.Sel_Items[1] end
                                        if r.ImGui_IsItemDeactivatedAfterEdit(ctx) then FrstSelItm.CustomLbl = buf end
                                    end

                                    --Label Pos
                                    r.ImGui_Text(ctx, 'Label Pos: '); r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(
                                        ctx, 100)
                                    if r.ImGui_BeginCombo(ctx, '## Lbl Pos' .. LE.Sel_Items[1], FrstSelItm.Lbl_Pos or 'Default', r.ImGui_ComboFlags_NoArrowButton()) then
                                        if FrstSelItm.Type == 'Knob' or FrstSelItm.Type == 'V-Slider' then
                                            AddOption('Top', 'Lbl_Pos')
                                            AddOption('Bottom', 'Lbl_Pos')
                                        elseif FrstSelItm.Type == 'Slider' or FrstSelItm.Type == 'Drag' then
                                            AddOption('Left', 'Lbl_Pos')
                                            AddOption('Bottom', 'Lbl_Pos')
                                        elseif FrstSelItm.Type == 'Selection' or FrstSelItm.Type == 'Switch' then
                                            AddOption('Top', 'Lbl_Pos')
                                            AddOption('Left', 'Lbl_Pos')
                                            if FrstSelItm.Type == 'Switch' then AddOption('Within', 'Lbl_Pos') end
                                            AddOption('Bottom', 'Lbl_Pos')
                                            AddOption('Right', 'Lbl_Pos')
                                            AddOption("None", 'Lbl_Pos')
                                        end
                                        AddOption('Free', 'Lbl_Pos')
                                        r.ImGui_EndCombo(ctx)
                                    end
                                    r.ImGui_SameLine(ctx)
                                    FreeLblPosSettings()
                                    -- Label Color
                                    DragLbl_Clr_Edited, Lbl_V_Clr = r.ImGui_ColorEdit4(ctx, '##Lbl Clr' ..
                                        LE.Sel_Items[1], FrstSelItm.Lbl_Clr or r.ImGui_GetColor(ctx, r.ImGui_Col_Text()),
                                        r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                        r.ImGui_ColorEditFlags_AlphaBar())
                                    if DragLbl_Clr_Edited then
                                        for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Lbl_Clr = Lbl_V_Clr end
                                    end


                                    r.ImGui_Text(ctx, 'Value Pos: '); r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(
                                        ctx, 100)
                                    if r.ImGui_BeginCombo(ctx, '## V Pos' .. LE.Sel_Items[1], FrstSelItm.V_Pos or 'Default', r.ImGui_ComboFlags_NoArrowButton()) then
                                        if FrstSelItm.Type == 'V-Slider' then
                                            AddOption('Bottom', 'V_Pos')
                                            AddOption('Top', 'V_Pos')
                                        elseif FrstSelItm.Type == 'Knob' then
                                            AddOption('Bottom', 'V_Pos')
                                            AddOption('Within', 'V_Pos')
                                        elseif FrstSelItm.Type == 'Switch' or FrstSelItm.Type == 'Selection' then
                                            AddOption('Within', 'V_Pos')
                                        elseif FrstSelItm.Type == 'Drag' then
                                            AddOption('Right', 'V_Pos')
                                            AddOption('Within', 'V_Pos')
                                        elseif FrstSelItm.Type == 'Slider' then
                                            AddOption('Right', 'V_Pos')
                                        end
                                        if FrstSelItm.Type ~= 'Selection' then AddOption('None', 'V_Pos') end

                                        AddOption('Free', 'V_Pos')

                                        r.ImGui_EndCombo(ctx)
                                    end
                                    r.ImGui_SameLine(ctx)

                                    FreeValuePosSettings()
                                    DragV_Clr_edited, Drag_V_Clr = r.ImGui_ColorEdit4(ctx, '##V  Clr' .. LE.Sel_Items[1],
                                        FrstSelItm.V_Clr or r.ImGui_GetColor(ctx, r.ImGui_Col_Text()),
                                        r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                        r.ImGui_ColorEditFlags_AlphaBar())
                                    if DragV_Clr_edited then
                                        for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].V_Clr = Drag_V_Clr end
                                    end

                                    if FrstSelItm.Type == 'Drag' then
                                        r.ImGui_Text(ctx, 'Direction: ')
                                        r.ImGui_SameLine(ctx)
                                        r.ImGui_SetNextItemWidth(ctx, -R_ofs)
                                        if r.ImGui_BeginCombo(ctx, '## Drag Dir' .. LE.Sel_Items[1], FrstSelItm.DragDir or '', r.ImGui_ComboFlags_NoArrowButton()) then
                                            if r.ImGui_Selectable(ctx, 'Right') then
                                                for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].DragDir = 'Right' end
                                            elseif r.ImGui_Selectable(ctx, 'Left-Right') then
                                                for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].DragDir = 'Left-Right' end
                                            elseif r.ImGui_Selectable(ctx, 'Left') then
                                                for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].DragDir = 'Left' end
                                            end
                                            r.ImGui_EndCombo(ctx)
                                        end
                                    end








                                    if FrstSelItm.Type == 'Switch' then
                                        local Momentary, Toggle
                                        if FrstSelItm.SwitchType == 'Momentary' then
                                            Momentary = true
                                        else
                                            Toggle = true
                                        end
                                        EdT, Tg = r.ImGui_Checkbox(ctx, 'Toggle##' .. FxGUID .. LE.Sel_Items[1], Toggle)
                                        r.ImGui_SameLine(ctx);
                                        EdM, Mt = r.ImGui_Checkbox(ctx, 'Momentary##' .. FxGUID .. LE.Sel_Items[1],
                                            Momentary)
                                        if EdT then
                                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].SwitchType = 'Toggle' end
                                        elseif EdM then
                                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].SwitchType = 'Momentary' end
                                        end
                                    end



                                    -- set base and target value
                                    if FrstSelItm.SwitchType == 'Momentary' and FrstSelItm.Type == 'Switch' then
                                        r.ImGui_Text(ctx, 'Base Value: ')
                                        r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(ctx, 80)
                                        local Drag, Bv = r.ImGui_DragDouble(ctx,
                                            '##EditBaseV' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                            FX[FxGUID][LE.Sel_Items[1]].SwitchBaseV or 0, 0.05, 0, 1, '%.2f')
                                        if Drag then
                                            for i, v in pairs(LE.Sel_Items) do
                                                FX[FxGUID][LE.Sel_Items[1]].SwitchBaseV =
                                                    Bv
                                            end
                                        end
                                        r.ImGui_Text(ctx, 'Target Value: ')
                                        r.ImGui_SameLine(ctx); r.ImGui_SetNextItemWidth(ctx, 80)
                                        local Drag, Tv = r.ImGui_DragDouble(ctx,
                                            '##EditTargV' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                            FX[FxGUID][LE.Sel_Items[1]].SwitchTargV or 1, 0.05, 0, 1, '%.2f')
                                        if Drag then
                                            for i, v in pairs(LE.Sel_Items) do
                                                FX[FxGUID][LE.Sel_Items[1]].SwitchTargV =
                                                    Tv
                                            end
                                        end
                                    end









                                    local FLT_MIN, FLT_MAX = r.ImGui_NumericLimits_Float()
                                    ----Font Size-----


                                    r.ImGui_Text(ctx, 'Label Font Size: '); r.ImGui_SameLine(ctx)
                                    r.ImGui_SetNextItemWidth(ctx, 50)
                                    Drag, ft = r.ImGui_DragDouble(ctx, '##EditFontSize' .. FxGUID ..
                                        (LE.Sel_Items[1] or ''),
                                        FX[FxGUID][LE.Sel_Items[1]].FontSize or Knob_DefaultFontSize, 0.25, 6, 16, '%.2f')
                                    if Drag then
                                        for i, v in pairs(LE.Sel_Items) do
                                            FX[FxGUID][v].FontSize = ft
                                        end
                                    end






                                    SL()
                                    r.ImGui_Text(ctx, 'Value Font Size: '); r.ImGui_SameLine(ctx)
                                    r.ImGui_SetNextItemWidth(ctx, 50)
                                    local Drag, ft = r.ImGui_DragDouble(ctx,
                                        '##EditV_FontSize' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                        FX[FxGUID][LE.Sel_Items[1]].V_FontSize or Knob_DefaultFontSize, 0.25, 6, 16,
                                        '%.2f')
                                    if Drag then
                                        for i, v in pairs(LE.Sel_Items) do
                                            FX[FxGUID][v].V_FontSize = ft
                                        end
                                    end








                                    ----Width -------
                                    r.ImGui_Text(ctx, 'Width: '); r.ImGui_SameLine(ctx)
                                    r.ImGui_SetNextItemWidth(ctx, -R_ofs)
                                    local DefaultW, MaxW, MinW
                                    if FrstSelItm.Type == 'Knob' then
                                        DefaultW = Df.KnobRadius
                                        MaxW = 30
                                        MinW = 7.5
                                    elseif FrstSelItm.Type == 'Slider' or FrstSelItm.Type == 'Drag' or not FrstSelItm.Type then
                                        DefaultW = Df.Sldr_W
                                        MaxW = 300
                                        MinW = 40
                                    elseif FrstSelItm.Type == 'Selection' then
                                        DefaultW = FrstSelItm.Combo_W
                                        MaxW = 300
                                        MinW = 20
                                    elseif FrstSelItm.Type == 'Switch' then
                                        DefaultW = FrstSelItm.Switch_W
                                        MaxW = 300
                                        MinW = 15
                                    elseif FrstSelItm.Type == 'V-Slider' then
                                        DefaultW = FrstSelItm.V_Sldr_W
                                        MaxW = 60
                                        MinW = 7
                                    end
                                    local DragSpeed = 5



                                    local _, W = r.ImGui_DragDouble(ctx,
                                        '##EditWidth' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                        FX[FxGUID][LE.Sel_Items[1] or ''].Sldr_W or DefaultW, LE.GridSize / 4, MinW, MaxW,
                                        '%.1f')

                                    if r.ImGui_IsItemEdited(ctx) then
                                        for i, v in pairs(LE.Sel_Items) do
                                            FX[FxGUID][v].Sldr_W = W
                                        end
                                    end

                                    if FrstSelItm.Type == 'Knob' or FrstSelItm.Type == 'Drag' or FrstSelItm.Type == 'Slider' then
                                        r.ImGui_Text(ctx, 'Value Decimal Places: '); r.ImGui_SameLine(ctx)
                                        r.ImGui_SetNextItemWidth(ctx, 80)
                                        if not FX[FxGUID][LE.Sel_Items[1]].V_Round then
                                            local _, FormatV = r.TrackFX_GetFormattedParamValue(LT_Track, FX_Idx,
                                                FX[FxGUID][LE.Sel_Items[1]].Num)
                                            local _, LastNum = FormatV:find('^.*()%d')
                                            local dcm = FormatV:find('%.')
                                            if dcm then
                                                rd = LastNum - dcm
                                            end
                                        end

                                        local Edit, rd = r.ImGui_InputInt(ctx,
                                            '##EditValueDecimals' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                            FrstSelItm.V_Round or rd, 1)
                                        if Edit then
                                            for i, v in pairs(LE.Sel_Items) do
                                                FX[FxGUID][v].V_Round = math.max(
                                                    rd, 0)
                                            end
                                        end
                                    end

                                    r.ImGui_Text(ctx, 'Value to Note Length: '); r.ImGui_SameLine(ctx)
                                    r.ImGui_SetNextItemWidth(ctx, 80)
                                    local Edit = r.ImGui_Checkbox(ctx,
                                        '##Value to Note Length' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                        FrstSelItm.ValToNoteL or nil)
                                    if Edit then
                                        for i, v in pairs(LE.Sel_Items) do
                                            if not FX[FxGUID][v].ValToNoteL then
                                                FX[FxGUID][v].ValToNoteL = true
                                            else
                                                FX[FxGUID][v].ValToNoteL = false
                                            end
                                        end
                                    end
                                    if FrstSelItm.Type == 'Selection' then --r.ImGui_Text(ctx,'Edit Values Manually: ') ;r.ImGui_SameLine(ctx)
                                        local Itm = LE.Sel_Items[1]
                                        local FP = FX[FxGUID][Itm]

                                        --[[ if not FX[FxGUID][Itm].EditValuesManual then if FX[FxGUID][Itm].ManualValues then FX[FxGUID][Itm].EditValuesManual = true end end

                                            EDIT, FX[FxGUID][Itm].EditValuesManual = r.ImGui_Checkbox( ctx, '##Edit Values Manually'..FxGUID..(Itm or''), FX[FxGUID][Itm].EditValuesManual)
                                            if FX[FxGUID][Itm].EditValuesManual then    ]]

                                        if r.ImGui_TreeNode(ctx, 'Edit Values Manually') then
                                            FX[FxGUID][Itm].ManualValues = FX[FxGUID][Itm].ManualValues or {}
                                            FX[FxGUID][Itm].ManualValuesFormat = FX[FxGUID][Itm].ManualValuesFormat or {}
                                            if r.ImGui_Button(ctx, 'Get Current Value##' .. FxGUID .. (Itm or '')) then
                                                local Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, FP.Num)
                                                if not tablefind(FP.ManualValues, Val) then
                                                    table.insert(FX[FxGUID][Itm].ManualValues, Val)
                                                end
                                            end
                                            for i, V in ipairs(FX[FxGUID][Itm].ManualValues) do
                                                r.ImGui_AlignTextToFramePadding(ctx)
                                                r.ImGui_Text(ctx, i .. ':' .. (round(V, 2) or 0))
                                                SL()
                                                r.ImGui_SetNextItemWidth(ctx, -R_ofs)
                                                rv, FX[FxGUID][Itm].ManualValuesFormat[i] = r.ImGui_InputText(ctx,
                                                    '##' .. FxGUID .. "Itm=" .. (Itm or '') .. 'i=' .. i,
                                                    FX[FxGUID][Itm].ManualValuesFormat[i])
                                                SL()
                                                local LH = r.ImGui_GetTextLineHeight(ctx)
                                                if IconBtn(20, 20, 'T', BgClr, 'center', '##' .. FxGUID .. "Itm=" .. (Itm or '') .. 'i=' .. i) then
                                                    table.remove(FX[FxGUID][Itm].ManualValuesFormat, i)
                                                    table.remove(FX[FxGUID][Itm].ManualValues, i)
                                                end
                                            end
                                            --FX[FxGUID][Itm].EditValuesManual = true
                                            r.ImGui_TreePop(ctx)
                                        end
                                    end



                                    local FLT_MIN, FLT_MAX = r.ImGui_NumericLimits_Float()

                                    --- Style ------
                                    r.ImGui_Text(ctx, 'Style: '); r.ImGui_SameLine(ctx)
                                    w = r.ImGui_CalcTextSize(ctx, 'Style: ')
                                    local stylename
                                    if FrstSelItm.Style == 'Pro C' then stylename = 'Minimalistic' end
                                    if r.ImGui_Button(ctx, (stylename or FrstSelItm.Style or 'Choose Style') .. '##' .. (LE.Sel_Items[1] or 'Style'), 155) then
                                        r.ImGui_OpenPopup(ctx, 'Choose style window')
                                    end

                                    --[[ if  r.ImGui_BeginCombo( ctx, '##'..(LE.Sel_Items[1] or 'Style') , FrstSelItm.Style or 'Choose Style', nil) then
                                            local function AddStyle (Name, Style)
                                                if r.ImGui_Selectable(ctx, Name) then
                                                    for i, v in pairs (LE.Sel_Items) do
                                                        FX[FxGUID][v].Style = Style ;   r.ImGui_CloseCurrentPopup(ctx)
                                                    end
                                                end
                                            end
                                            local T = {Name ={}; Style = {}}
                                            T.Name={'Default', 'Minimalistic', 'Analog 1'}
                                            T.Style = {'Default', 'Pro C', 'Analog 1'}

                                            for i, v in ipairs(T.Name) do
                                                AddStyle(v, T.Style[i])
                                            end

                                            r.ImGui_EndCombo(ctx)

                                        end ]]


                                    if r.ImGui_BeginPopup(ctx, 'Choose style window') then
                                        r.ImGui_BeginDisabled(ctx)

                                        local function setItmStyle(Style)
                                            for i, v in pairs(LE.Sel_Items) do
                                                FX[FxGUID][v].Style = Style; r.ImGui_CloseCurrentPopup(ctx)
                                            end
                                        end
                                        if FrstSelItm.Type == 'Slider' or (not FrstSelItm.Type and FX.Def_Type[FxGUID] == 'Slider') then -- if all selected itms are Sliders
                                            --AddSlider(ctx, '##'..FrstSelItm.Name , 'Default', 0, 0, 1, v,FX_Idx, FrstSelItm.Num ,Style, FrstSelItm.Sldr_W or FX.Def_Sldr_W[FxGUID]  ,0, Disable, Vertical, GrabSize,     FrstSelItm.Lbl, 8)
                                            --AddSlider(ctx, '##'..FrstSelItm.Name , 'Default', 0, 0, 1, v,FX_Idx, FrstSelItm.Num ,Style, FrstSelItm.Sldr_W or FX.Def_Sldr_W[FxGUID]  ,0, Disable, Vertical, GrabSize, FrstSelItm.Lbl, 8)
                                        end

                                        if FrstSelItm.Type == 'Knob' or (not FrstSelItm.Type and FX.Def_Type[FxGUID] == 'Knob') then -- if all selected itms are knobs
                                            local function SetStyle(Name, Style)
                                                r.ImGui_Text(ctx, Name)
                                                AddKnob(ctx, '##' .. FrstSelItm.Name, '', 0, 0, 1, FItm, FX_Idx,
                                                    FrstSelItm.Num, Style, 15, 0, Disabled, 12)
                                                if HighlightHvredItem() then --if clicked on highlighted itm
                                                    setItmStyle(Style)
                                                    r.ImGui_CloseCurrentPopup(ctx)
                                                end
                                                AddSpacing(6)
                                            end

                                            SetStyle('Default', Style)
                                            SetStyle('Minimalistic', 'Pro C')
                                            SetStyle('Analog 1', 'Analog 1')
                                        end

                                        if FrstSelItm.Type == 'Selection' then
                                            local function SetStyle(Name, Style, Width, CustomLbl)
                                                AddCombo(ctx, LT_Track, FX_Idx, Name .. '##' .. FrstSelItm.Name,
                                                    FrstSelItm.Num, Options, Width, Style, FxGUID, LE.Sel_Items[1],
                                                    OptionValues, 'Options', CustomLbl)
                                                if HighlightHvredItem() then
                                                    setItmStyle(Style)
                                                    r.ImGui_CloseCurrentPopup(ctx)
                                                end
                                                AddSpacing(3)
                                            end
                                            local w = 60
                                            SetStyle('Default', nil, w, 'Default: ')

                                            SetStyle('up-down arrow', 'up-down arrow', w + 20, 'up-down arrow: ')
                                        end

                                        r.ImGui_EndDisabled(ctx)
                                        r.ImGui_EndPopup(ctx)
                                    end
                                    ---Pos  -------

                                    r.ImGui_Text(ctx, 'Pos-X: '); r.ImGui_SameLine(ctx)
                                    r.ImGui_SetNextItemWidth(ctx, 80)
                                    local EditPosX, PosX = r.ImGui_DragDouble(ctx, ' ##EditPosX' ..
                                        FxGUID .. LE.Sel_Items[1], PosX or FrstSelItm.PosX, LE.GridSize, 0, Win_W - 10,
                                        '%.0f')
                                    if EditPosX then
                                        for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].PosX = PosX end
                                    end
                                    SL()
                                    r.ImGui_Text(ctx, 'Pos-Y: '); r.ImGui_SameLine(ctx)
                                    r.ImGui_SetNextItemWidth(ctx, 80)
                                    local EditPosY, PosY = r.ImGui_DragDouble(ctx, ' ##EditPosY' ..
                                        FxGUID .. LE.Sel_Items[1], PosY or FrstSelItm.PosY, LE.GridSize, 20, 210, '%.0f')
                                    if EditPosY then for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].PosY = PosY end end

                                    ---Color -----

                                    r.ImGui_Text(ctx, 'Color: ')
                                    r.ImGui_SameLine(ctx)
                                    ClrEdited, PrmBgClr = r.ImGui_ColorEdit4(ctx, '##Clr' .. ID,
                                        FrstSelItm.BgClr or r.ImGui_GetColor(ctx, r.ImGui_Col_FrameBg()),
                                        r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                        reaper.ImGui_ColorEditFlags_AlphaBar())
                                    if not FX[FxGUID][LE.Sel_Items[1]].BgClr or FX[FxGUID][LE.Sel_Items[1]] == r.ImGui_GetColor(ctx, r.ImGui_Col_FrameBg()) then
                                        HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, w, 0, 0, 'GetItemRect')
                                    end
                                    if ClrEdited then
                                        for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].BgClr = PrmBgClr end
                                    end


                                    if FrstSelItm.Type ~= 'Switch' and FrstSelItm.Type ~= 'Selection' then
                                        r.ImGui_Text(ctx, 'Grab Color: ')
                                        r.ImGui_SameLine(ctx)
                                        GrbClrEdited, GrbClr = r.ImGui_ColorEdit4(ctx, '##GrbClr' .. ID,
                                            FrstSelItm.GrbClr or r.ImGui_GetColor(ctx, r.ImGui_Col_SliderGrab()),
                                            r.ImGui_ColorEditFlags_NoInputs()|    r
                                            .ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                            reaper.ImGui_ColorEditFlags_AlphaBar())
                                        if not FX[FxGUID][LE.Sel_Items[1]].GrbClr or FX[FxGUID][LE.Sel_Items[1]].GrbClr == r.ImGui_GetColor(ctx, r.ImGui_Col_SliderGrab()) then
                                            HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, w, 0, 0,
                                                'GetItemRect')
                                        end
                                        if GrbClrEdited then
                                            for i, v in pairs(LE.Sel_Items) do
                                                FX[FxGUID][v].GrbClr =
                                                    GrbClr
                                            end
                                        end
                                    end

                                    if FrstSelItm.Type == 'Knob' then
                                        SL()
                                        r.ImGui_Text(ctx, 'Thickness : ')
                                        SL()
                                        r.ImGui_SetNextItemWidth(ctx, 40)
                                        local TD, Thick = r.ImGui_DragDouble(ctx,
                                            '##EditValueFontSize' .. FxGUID .. (LE.Sel_Items[1] or ''),
                                            FX[FxGUID][LE.Sel_Items[1] or ''].Value_Thick or 2, 0.1, 0.5, 8, '%.1f')
                                        if TD then
                                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Value_Thick = Thick end
                                        end
                                    end


                                    if FrstSelItm.Type == 'Selection' then
                                        r.ImGui_SameLine(ctx)
                                        r.ImGui_Text(ctx, 'Text Color: ')
                                        r.ImGui_SameLine(ctx)
                                        local DragLbl_Clr_Edited, V_Clr = r.ImGui_ColorEdit4(ctx,
                                            '##V Clr' .. LE.Sel_Items[1],
                                            FX[FxGUID][LE.Sel_Items[1] or ''].V_Clr or
                                            r.ImGui_GetColor(ctx, r.ImGui_Col_Text()),
                                            r.ImGui_ColorEditFlags_NoInputs()|    r
                                            .ImGui_ColorEditFlags_AlphaPreviewHalf()|r.ImGui_ColorEditFlags_AlphaBar())
                                        if DragLbl_Clr_Edited then
                                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].V_Clr = V_Clr end
                                        end
                                    elseif FrstSelItm.Type == 'Switch' then
                                        SL()
                                        r.ImGui_Text(ctx, 'On Color: ')
                                        r.ImGui_SameLine(ctx)
                                        local DragLbl_Clr_Edited, V_Clr = r.ImGui_ColorEdit4(ctx,
                                            '##Switch on Clr' .. LE.Sel_Items[1],
                                            FX[FxGUID][LE.Sel_Items[1] or ''].Switch_On_Clr or
                                            r.ImGui_GetColor(ctx, r.ImGui_Col_Text()),
                                            r.ImGui_ColorEditFlags_NoInputs()|    r
                                            .ImGui_ColorEditFlags_AlphaPreviewHalf()|r.ImGui_ColorEditFlags_AlphaBar())
                                        if DragLbl_Clr_Edited then
                                            for i, v in pairs(LE.Sel_Items) do FX[FxGUID][v].Switch_On_Clr = V_Clr end
                                        end
                                    end

                                    ----- Condition to show ------

                                    local P = LE.Sel_Items[1]





                                    local function Condition(ConditionPrm, ConditionPrm_PID, ConditionPrm_V,
                                                             ConditionPrm_V_Norm, BtnTitle, ShowCondition)
                                        if r.ImGui_Button(ctx, BtnTitle) then
                                            if Mods == 0 then
                                                for i, v in pairs(LE.Sel_Items) do
                                                    if not FX[FxGUID][v][ShowCondition] then FX[FxGUID][v][ShowCondition] = true else FX[FxGUID][v][ShowCondition] = nil end
                                                    FX[FxGUID][v][ConditionPrm_V] = FX[FxGUID][v][ConditionPrm_V] or {}
                                                end
                                            elseif Mods == Alt then
                                                for i, v in pairs(FX[FxGUID][P][ConditionPrm_V]) do
                                                    FX[FxGUID][P][ConditionPrm_V][i] = nil
                                                end
                                                FX[FxGUID][P][ConditionPrm] = nil
                                                FrstSelItm[ShowCondition] = nil
                                                DeleteAllConditionPrmV = nil
                                            end
                                        end

                                        if r.ImGui_IsItemHovered(ctx) then
                                            HintToolTip(
                                                'Alt-Click to Delete All Conditions')
                                        end



                                        if FrstSelItm[ShowCondition] or FX[FxGUID][P][ConditionPrm] then
                                            SL()
                                            if not FX[FxGUID][P][ConditionPrm_PID] then
                                                for i, v in ipairs(FX[FxGUID]) do
                                                    if FX[FxGUID][i].Num == FrstSelItm[ConditionPrm] then
                                                        FrstSelItm[ConditionPrm_PID] =
                                                            i
                                                    end
                                                end
                                            end
                                            local PID = FX[FxGUID][P][ConditionPrm_PID] or 1

                                            if r.ImGui_Button(ctx, 'Prm:##' .. ConditionPrm) then
                                                FX[FxGUID][P].ConditionPrm = LT_ParamNum
                                                for i, v in ipairs(FX[FxGUID]) do
                                                    if FX[FxGUID][i].Num == FrstSelItm[ConditionPrm] then
                                                        FrstSelItm[ConditionPrm_PID] =
                                                            i
                                                    end
                                                end
                                                --GetParamOptions ('get', FxGUID,FX_Idx, LE.Sel_Items[1],LT_ParamNum)
                                            end
                                            if r.ImGui_IsItemHovered(ctx) then
                                                tooltip(
                                                    'Click to set to last touched parameter')
                                            end

                                            r.ImGui_SameLine(ctx)
                                            r.ImGui_SetNextItemWidth(ctx, 80)
                                            local PrmName, PrmValue
                                            --if ConditionPrm then  _,  PrmName =  r.TrackFX_GetParamName(LT_Track, FX_Idx, ConditionPrm) end

                                            local Edit, Cond = r.ImGui_InputInt(ctx,
                                                '##' .. ConditionPrm .. LE.Sel_Items[1] .. FxGUID,
                                                FX[FxGUID][P][ConditionPrm] or 0)

                                            if FX[FxGUID][P][ConditionPrm] then
                                                _, PrmName = r.TrackFX_GetParamName(
                                                    LT_Track, FX_Idx, FX[FxGUID][P][ConditionPrm])
                                            end

                                            if Edit then
                                                FX[FxGUID][P][ConditionPrm] = Cond
                                                for i, v in ipairs(FX[FxGUID]) do
                                                    if FX[FxGUID][i].Num == FrstSelItm[ConditionPrm] then
                                                        FrstSelItm[ConditionPrm_PID] =
                                                            i
                                                    end
                                                end
                                            end



                                            r.ImGui_SameLine(ctx)
                                            r.ImGui_Text(ctx, PrmName or '')
                                            r.ImGui_AlignTextToFramePadding(ctx)
                                            r.ImGui_Text(ctx, 'is at Value:')

                                            r.ImGui_SameLine(ctx)
                                            local FP = FX[FxGUID][LE.Sel_Items[1]]
                                            local CP = FX[FxGUID][P][ConditionPrm]
                                            --!!!!!! LE.Sel_Items[1] = Fx_P -1 !!!!!! --
                                            Value_Selected, V_Formatted = AddCombo(ctx, LT_Track, FX_Idx,
                                                ConditionPrm .. (PrmName or '') .. '1', FX[FxGUID][P][ConditionPrm] or 0,
                                                FX[FxGUID][PID].ManualValuesFormat or 'Get Options', Width, Style, FxGUID,
                                                PID, FX[FxGUID][PID].ManualValues,
                                                FX[FxGUID][P][ConditionPrm_V][1] or 'Unassigned', nil, 'No Lbl')

                                            if Value_Selected then
                                                for i, v in pairs(LE.Sel_Items) do
                                                    FX[FxGUID][v][ConditionPrm] = Cond
                                                    FX[FxGUID][v][ConditionPrm_V] = FX[FxGUID][v][ConditionPrm_V] or {}
                                                    FX[FxGUID][v][ConditionPrm_V_Norm] = FX[FxGUID][v]
                                                        [ConditionPrm_V_Norm] or {}
                                                    FX[FxGUID][v][ConditionPrm_V][1] = V_Formatted
                                                    FX[FxGUID][v][ConditionPrm_V_Norm][1] = r.TrackFX_GetParamNormalized(
                                                        LT_Track, FX_Idx, FX[FxGUID][P][ConditionPrm])
                                                end
                                            end
                                            if not FX[FxGUID][P][ConditionPrm_V][1] then
                                                FX[FxGUID][P][ConditionPrm_V][1] =
                                                ''
                                            end

                                            if FX[FxGUID][P][ConditionPrm_V] then
                                                if FX[FxGUID][P][ConditionPrm_V][2] then
                                                    for i, v in pairs(FX[FxGUID][P][ConditionPrm_V]) do
                                                        if i > 1 then
                                                            r.ImGui_Text(ctx, 'or at value:')
                                                            r.ImGui_SameLine(ctx)
                                                            local Value_Selected, V_Formatted = AddCombo(ctx, LT_Track,
                                                                FX_Idx, 'CondPrmV' .. (PrmName or '') .. v ..
                                                                ConditionPrm, FX[FxGUID][P][ConditionPrm] or 0,
                                                                FX[FxGUID][PID].ManualValuesFormat or 'Get Options',
                                                                Width, Style, FxGUID, PID, FX[FxGUID][PID].ManualValues,
                                                                v, nil, 'No Lbl')
                                                            if Value_Selected then
                                                                for I, v in pairs(LE.Sel_Items) do
                                                                    FX[FxGUID][v][ConditionPrm_V][i] = V_Formatted
                                                                    FX[FxGUID][v][ConditionPrm_V_Norm][i] = r
                                                                        .TrackFX_GetParamNormalized(LT_Track, FX_Idx,
                                                                            FX[FxGUID][P][ConditionPrm])
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                            if r.ImGui_Button(ctx, ' + or at value:##' .. ConditionPrm) then
                                                FX[FxGUID][P][ConditionPrm_V] = FX[FxGUID][P][ConditionPrm_V] or {}
                                                table.insert(FX[FxGUID][P][ConditionPrm_V], '')
                                            end
                                            r.ImGui_SameLine(ctx)
                                            r.ImGui_SetNextItemWidth(ctx, 120)
                                            if r.ImGui_BeginCombo(ctx, '##- delete value ' .. ConditionPrm, '- delete value', r.ImGui_ComboFlags_NoArrowButton()) then
                                                for i, v in pairs(FX[FxGUID][P][ConditionPrm_V]) do
                                                    if r.ImGui_Selectable(ctx, v or '', i) then
                                                        table.remove(FX[FxGUID][P][ConditionPrm_V], i)
                                                        if not FX[FxGUID][P][ConditionPrm_V][1] then
                                                            FX[FxGUID][P][ConditionPrm] = nil
                                                        end
                                                    end
                                                end
                                                r.ImGui_EndCombo(ctx)
                                            end
                                        end
                                    end

                                    Condition('ConditionPrm', 'ConditionPrm_PID', 'ConditionPrm_V', 'ConditionPrm_V_Norm',
                                        'Show only if:', 'ShowCondition')
                                    if FrstSelItm.ConditionPrm then
                                        Condition('ConditionPrm2', 'ConditionPrm_PID2',
                                            'ConditionPrm_V2', 'ConditionPrm_V_Norm2', 'And if:', 'ShowCondition2')
                                    end
                                    if FrstSelItm.ConditionPrm2 then
                                        Condition('ConditionPrm3', 'ConditionPrm_PID3',
                                            'ConditionPrm_V3', 'ConditionPrm_V_Norm3', 'And if:', 'ShowCondition3')
                                    end
                                    if FrstSelItm.ConditionPrm3 then
                                        Condition('ConditionPrm4', 'ConditionPrm_PID4',
                                            'ConditionPrm_V4', 'ConditionPrm_V_Norm4', 'And if:', 'ShowCondition4')
                                    end
                                    if FrstSelItm.ConditionPrm4 then
                                        Condition('ConditionPrm5', 'ConditionPrm_PID5',
                                            'ConditionPrm_V5', 'ConditionPrm_V_Norm5', 'And if:', 'ShowCondition5')
                                    end




                                    r.ImGui_PopStyleColor(ctx)
                                end -------------------- End of Repeat for every selected item
                                if LE.SelectedItem == 'Title' then
                                    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgActive(), 0x66666688)

                                    r.ImGui_Text(ctx, 'Edge Round:')
                                    r.ImGui_SameLine(ctx)
                                    Edited, FX.Round[FxGUID] = r.ImGui_DragDouble(ctx, '##' .. FxGUID .. 'Round',
                                        FX.Round[FxGUID], 0.01, 0, 40, '%.2f')

                                    r.ImGui_Text(ctx, 'Grab Round:')
                                    r.ImGui_SameLine(ctx)
                                    Edited, FX.GrbRound[FxGUID] = r.ImGui_DragDouble(ctx, '##' .. FxGUID .. 'GrbRound',
                                        FX.GrbRound[FxGUID], 0.01, 0, 40, '%.2f')

                                    r.ImGui_Text(ctx, 'Background Color:')
                                    r.ImGui_SameLine(ctx)
                                    _, FX.BgClr[FxGUID] = r.ImGui_ColorEdit4(ctx, '##' .. FxGUID .. 'BgClr',
                                        FX.BgClr[FxGUID] or FX_Devices_Bg or 0x151515ff,
                                        r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                        r.ImGui_ColorEditFlags_AlphaBar())
                                    if FX.BgClr[FxGUID] == r.ImGui_GetColor(ctx, r.ImGui_Col_FrameBg()) then
                                        HighlightSelectedItem(nil, 0xffffffdd, 0, L, T, R, B, h, w, 1, 1, 'GetItemRect')
                                    end

                                    r.ImGui_Text(ctx, 'FX Title Color:')
                                    r.ImGui_SameLine(ctx)
                                    _, FX[FxGUID].TitleClr = r.ImGui_ColorEdit4(ctx, '##' .. FxGUID .. 'Title Clr',
                                        FX[FxGUID].TitleClr or 0x22222233,
                                        r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                        r.ImGui_ColorEditFlags_AlphaBar())

                                    r.ImGui_Text(ctx, 'Custom Title:')
                                    r.ImGui_SameLine(ctx)
                                    local _, CustomTitle = r.ImGui_InputText(ctx, '##CustomTitle' .. FxGUID,
                                        FX[FxGUID].CustomTitle or FX_Name)
                                    if r.ImGui_IsItemDeactivatedAfterEdit(ctx) then
                                        FX[FxGUID].CustomTitle = CustomTitle
                                    end

                                    r.ImGui_PopStyleColor(ctx)
                                end






                                if Draw.DrawMode[FxGUID] == true then
                                    if not CheckIfDrawingHasBeenMade(FX_Idx) then r.ImGui_BeginDisabled(ctx) end

                                    if r.ImGui_Button(ctx, 'Save Drawings') then
                                        SaveDrawings(FX_Idx, FxGUID)
                                        Draw.DrawMode[FxGUID] = nil
                                    end

                                    if not CheckIfDrawingHasBeenMade(FX_Idx) then r.ImGui_EndDisabled(ctx) end



                                    r.ImGui_SameLine(ctx, nil, 30)
                                    if r.ImGui_Button(ctx, 'Exit') then
                                        if CheckIfDrawingHasBeenMade(FX_Idx) then
                                            local Modalw, Modalh = 300, 80
                                            r.ImGui_SetNextWindowPos(ctx, VP.x + VP.w / 2 - Modalw / 2,
                                                VP.y + VP.h / 2 - Modalh / 2)
                                            r.ImGui_SetNextWindowSize(ctx, Modalw, Modalh)
                                            r.ImGui_OpenPopup(ctx, 'Save Draw Editing?')
                                        else
                                            Draw.DrawMode[FxGUID] = nil
                                        end
                                    end
                                else
                                    --if not CheckIfLayoutEditHasBeenMade(FxGUID, FX_Name)  then Disabled= true  r.ImGui_BeginDisabled(ctx) end







                                    if r.ImGui_Button(ctx, 'Save') then
                                        SaveLayoutEditings(FX_Name, ID or 1, FXGUID[FX_Idx])
                                        CloseLayEdit = true; FX.LayEdit = nil
                                    end


                                    -- if not  CheckIfLayoutEditHasBeenMade(FxGUID, FX_Name) and Disabled  then r.ImGui_EndDisabled(ctx) Disabled=nil  end
                                    r.ImGui_SameLine(ctx, nil, 30)

                                    if r.ImGui_Button(ctx, 'Exit') then
                                        --if CheckIfLayoutEditHasBeenMade(FxGUID, FX_Name) then
                                        local Modalw, Modalh = 300, 80
                                        r.ImGui_SetNextWindowPos(ctx, VP.x + VP.w / 2 - Modalw / 2,
                                            VP.y + VP.h / 2 - Modalh / 2)
                                        r.ImGui_SetNextWindowSize(ctx, Modalw, Modalh)
                                        r.ImGui_OpenPopup(ctx, 'Save Editing?')
                                        --[[ else
                                                CloseLayEdit = true ;FX.LayEdit= nil
                                            end ]]
                                    end

                                    r.ImGui_SameLine(ctx, nil, 30)
                                    if r.ImGui_Button(ctx, 'Delete') then
                                        local tb = {}

                                        for i, v in pairs(LE.Sel_Items) do
                                            tb[i] = v
                                        end
                                        table.sort(tb)

                                        for i = #tb, 1, -1 do
                                            DeletePrm(FxGUID, tb[i])
                                        end

                                        if not FX[FxGUID][1] then FX[FxGUID].AllPrmHasBeenDeleted = true else FX[FxGUID].AllPrmHasBeenDeleted = nil end


                                        LE.Sel_Items = {}
                                    end
                                end



                                if r.ImGui_BeginPopupModal(ctx, 'Save Editing?') then
                                    SaveEditingPopupModal = true
                                    r.ImGui_Text(ctx, 'Would you like to save the editings?')
                                    if r.ImGui_Button(ctx, '(n) No') or r.ImGui_IsKeyPressed(ctx, 78) then
                                        RetrieveFXsSavedLayout(Sel_Track_FX_Count)
                                        r.ImGui_CloseCurrentPopup(ctx)
                                        FX.LayEdit = nil
                                        LE.SelectedItem = nil
                                        CloseLayEdit = true
                                    end
                                    r.ImGui_SameLine(ctx)

                                    if r.ImGui_Button(ctx, '(y) Yes') or r.ImGui_IsKeyPressed(ctx, 89) then
                                        SaveLayoutEditings(FX_Name, ID, FXGUID[FX_Idx])
                                        r.ImGui_CloseCurrentPopup(ctx)
                                        FX.LayEdit = nil
                                        LE.SelectedItem = nil
                                        CloseLayEdit = true
                                    end
                                    r.ImGui_SameLine(ctx)

                                    if r.ImGui_Button(ctx, '(c) Cancel') or r.ImGui_IsKeyPressed(ctx, 67) or r.ImGui_IsKeyPressed(ctx, 27) then
                                        r.ImGui_CloseCurrentPopup(ctx)
                                    end



                                    r.ImGui_EndPopup(ctx)
                                end

                                if r.ImGui_BeginPopupModal(ctx, 'Save Draw Editing?') then
                                    r.ImGui_Text(ctx, 'Would you like to save the Drawings?')
                                    if r.ImGui_Button(ctx, '(n) No') then
                                        local FxNameS = FX.Win_Name_S[FX_Idx]
                                        local HowManyToDelete
                                        for i, Type in pairs(Draw[FxNameS].Type) do
                                            HowManyToDelete = i
                                        end

                                        for Del = 1, HowManyToDelete, 1 do
                                            local D = Draw[FxNameS]
                                            table.remove(D.Type, i)
                                            table.remove(D.L, i)
                                            table.remove(D.R, i)
                                            table.remove(D.T, i)
                                            table.remove(D.B, i)
                                            if D.Txt[i] then table.remove(D.Txt, i) end
                                            if D.clr[i] then table.remove(D.clr, i) end
                                        end
                                        RetrieveFXsSavedLayout(Sel_Track_FX_Count)
                                        r.ImGui_CloseCurrentPopup(ctx)
                                        Draw.DrawMode[FxGUID] = nil
                                    end
                                    r.ImGui_SameLine(ctx)

                                    if r.ImGui_Button(ctx, '(y) Yes') then
                                        SaveDrawings(FX_Idx, FxGUID)
                                        r.ImGui_CloseCurrentPopup(ctx)
                                        Draw.DrawMode[FxGUID] = nil
                                    end
                                    r.ImGui_EndPopup(ctx)
                                end

                                if CloseLayEdit then
                                    FX.LayEdit = nil
                                end
                                local w, h = r.ImGui_GetWindowSize(ctx)
                                r.ImGui_SetCursorPos(ctx, w - 24, 20)

                                for Pal = 1, NumOfColumns or 1, 1 do
                                    if not CloseLayEdit and r.ImGui_BeginChildFrame(ctx, 'Color Palette' .. Pal, 30, h - 30, r.ImGui_WindowFlags_NoScrollbar()) then
                                        local NumOfPaletteClr = 9

                                        for i, v in ipairs(FX[FxGUID]) do
                                            local function CheckClr(Clr)
                                                if Clr and not r.ImGui_IsPopupOpen(ctx, '', r.ImGui_PopupFlags_AnyPopupId()) then
                                                    if not tablefind(ClrPallet, Clr) and ClrPallet then
                                                        local R, G, B, A = r.ImGui_ColorConvertU32ToDouble4(Clr)
                                                        if A ~= 0 then
                                                            table.insert(ClrPallet, Clr)
                                                        end
                                                    end
                                                end
                                            end
                                            CheckClr(v.Lbl_Clr)
                                            CheckClr(v.V_Clr)
                                            CheckClr(v.BgClr)
                                            CheckClr(v.GrbClr)
                                        end

                                        if FX.Win_Name_S[FX_Idx] then
                                            if Draw[FX.Win_Name_S[FX_Idx]] then
                                                for i, v in ipairs(Draw[FX.Win_Name_S[FX_Idx]].clr) do
                                                    local Clr = v
                                                    if Clr and not r.ImGui_IsPopupOpen(ctx, '', r.ImGui_PopupFlags_AnyPopupId()) then
                                                        if not tablefind(ClrPallet, Clr) and ClrPallet then
                                                            table.insert(ClrPallet, Clr)
                                                        end
                                                    end
                                                end
                                            end
                                        end

                                        for i, v in ipairs(ClrPallet) do
                                            clrpick, LblColor1 = r.ImGui_ColorEdit4(ctx, '##ClrPalette' .. Pal ..
                                                i .. FxGUID, v,
                                                r.ImGui_ColorEditFlags_NoInputs()|
                                                r.ImGui_ColorEditFlags_AlphaPreviewHalf()|
                                                r.ImGui_ColorEditFlags_AlphaBar())
                                            if r.ImGui_IsItemClicked(ctx) and Mods == Alt then
                                                table.remove(ClrPallet, tablefind(v))
                                            end
                                        end


                                        --[[ for i=1, NumOfPaletteClr , 1 do
                                            PaletteClr= 'PaletteClr'..Pal..i..FxGUID
                                            local DefaultClr        = r.ImGui_ColorConvertHSVtoRGB((i-0.5)*(NumOfColumns or 1) / 7.0, 0.5, 0.5, 1)
                                            clrpick,  _G[PaletteClr] = r.ImGui_ColorEdit4( ctx, '##ClrPalette'..Pal..i..FxGUID,  _G[PaletteClr] or  DefaultClr , r.ImGui_ColorEditFlags_NoInputs()|    r.ImGui_ColorEditFlags_AlphaPreviewHalf()|r.ImGui_ColorEditFlags_AlphaBar())
                                            if r.ImGui_IsItemDeactivatedAfterEdit(ctx) and i==NumOfPaletteClr  then NumOfColumns=(NumOfColumns or 1 )   +1    end
                                            if r.ImGui_BeginDragDropTarget( ctx) then HighlightSelectedItem(0x00000000 ,0xffffffff, 0, L,T,R,B,h,w, 1, 1,'GetItemRect', 'Foreground') end
                                        end  ]]
                                        r.ImGui_EndChildFrame(ctx)
                                    end
                                    if NumOfColumns or 1 > 1 then
                                        for i = 1, NumOfColumns, 1 do r.ImGui_SameLine(ctx, nil, 0) end
                                    end
                                end

                                if r.ImGui_IsKeyPressed(ctx, 65) and (Mods == Apl or Mods == Alt) then
                                    for Fx_P = 1, #FX[FxGUID] or 0, 1 do table.insert(LE.Sel_Items, Fx_P) end
                                end
                                r.ImGui_End(ctx)
                            end





                            r.ImGui_SameLine(ctx, nil, 0)
                            --r.ImGui_PushStyleVar( ctx,r.ImGui_StyleVar_WindowPadding(), 0,0)
                            --r.ImGui_PushStyleColor(ctx, r.ImGui_Col_DragDropTarget(), 0x00000000)



                            --if ctrl+A or Command+A is pressed


                            --r.ImGui_EndTooltip(ctx)

                            -- r.ImGui_PopStyleVar(ctx)
                            --r.ImGui_PopStyleColor(ctx,2 )
                        end

                        if AdjustDrawRectPos and IsLBtnHeld then
                            local DtX, DtY = r.ImGui_GetMouseDelta(ctx)
                            Mx, My = r.ImGui_GetMousePos(ctx)
                            FDL = r.ImGui_GetForegroundDrawList(ctx)

                            r.ImGui_DrawList_AddRectFilled(FDL, Draw.Rect.L, Draw.Rect.T, Draw.Rect.R, Draw.Rect.B,
                                0xbbbbbb66)
                        else
                            AdjustDrawRectPos = nil
                        end

                        if Draw.Rect.L then
                            r.ImGui_DrawList_AddRectFilled(FDL, Draw.Rect.L, Draw.Rect.T, Draw.Rect.R,
                                Draw.Rect.B, 0xbbbbbb66, Draw.Df_EdgeRound[FxGUID] or 0)
                        end
                    elseif --[[FX Layer Window ]] string.find(FX_Name, 'FXD %(Mix%)RackMixer') or string.find(FX_Name, 'FXRack') then --!!!!  FX Layer Window
                        if not FX[FxGUID].Collapse then
                            FXGUID_RackMixer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                            r.TrackFX_Show(LT_Track, FX_Idx, 2)

                            r.ImGui_SameLine(ctx, nil, 0)
                            --Gives the index of the specific MixRack
                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(),
                                FX_Layer_Container_BG or BGColor_FXLayeringWindow)
                            FXLayeringWin_X = 240; local Pad = 3
                            if r.ImGui_BeginChildFrame(ctx, '##FX Layer at' .. FX_Idx .. 'OnTrack ' .. TrkID, FXLayeringWin_X + Pad, 220, r.ImGui_WindowFlags_NoScrollbar()) then
                                local WDL = r.ImGui_GetWindowDrawList(ctx)
                                FXLayerFrame_PosX_L, FXLayerFrame_PosY_T = r.ImGui_GetItemRectMin(ctx)
                                FXLayerFrame_PosX_R, FXLayerFrame_PosY_B = r.ImGui_GetItemRectMax(ctx); FXLayerFrame_PosY_B =
                                    FXLayerFrame_PosY_B + 220

                                local clrhdrhvr = r.ImGui_GetColor(ctx, r.ImGui_Col_ButtonHovered())
                                local clrhdrAct = r.ImGui_GetColor(ctx, r.ImGui_Col_ButtonActive())

                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderHovered(), clrhdrhvr)
                                local clrhdr = r.ImGui_GetColor(ctx, r.ImGui_Col_Button())
                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_TableHeaderBg(), clrhdr)

                                r.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FramePadding(), 0, 0)


                                r.ImGui_BeginTable(ctx, '##FX Layer' .. FX_Idx, 1)
                                r.ImGui_TableHeadersRow(ctx)


                                if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_AcceptNoDrawDefaultRect()) then
                                    DragFX_ID = FX_Idx
                                    r.ImGui_SetDragDropPayload(ctx, 'FX Layer Repositioning', FX_Idx)
                                    r.ImGui_EndDragDropSource(ctx)
                                    DragDroppingFX = true
                                    if IsAnyMouseDown == false then DragDroppingFX = false end
                                end
                                if r.ImGui_IsItemClicked(ctx, 0) and Mods == Alt then
                                    FX[FxGUID].DeleteFXLayer = true
                                elseif r.ImGui_IsItemClicked(ctx, 1) then
                                    FX[FxGUID].Collapse = true
                                    FX[FxGUID].CollapseWidth = 27
                                elseif r.ImGui_IsItemClicked(ctx) and Mods == Shift then
                                    local Spltr, FX_Inst
                                    if FX[FxGUID].LyrDisable == nil then FX[FxGUID].LyrDisable = false end
                                    FX[FxGUID].AldreadyBPdFXs = FX[FxGUID].AldreadyBPdFXs or {}





                                    for i = 0, Sel_Track_FX_Count, 1 do
                                        if FX.InLyr[FXGUID[i]] == FXGUID[FX_Idx] then
                                            if not FX[FxGUID].LyrDisable then
                                                if r.TrackFX_GetEnabled(LT_Track, i) == false then
                                                    if FX[FxGUID].AldreadyBPdFXs == {} then
                                                        table.insert(FX[FxGUID].AldreadyBPdFXs,
                                                            r.TrackFX_GetFXGUID(LT_Track, i))
                                                    elseif not FindStringInTable(FX[FxGUID].AldreadyBPdFXs, r.TrackFX_GetFXGUID(LT_Track, i)) then
                                                        table.insert(FX[FxGUID].AldreadyBPdFXs,
                                                            r.TrackFX_GetFXGUID(LT_Track, i))
                                                    end
                                                else
                                                end
                                                r.TrackFX_SetEnabled(LT_Track, i, false)
                                            else
                                                r.TrackFX_SetEnabled(LT_Track, i, true)
                                            end

                                            for ii, v in pairs(FX[FxGUID].AldreadyBPdFXs) do
                                                if v == FXGUID[i] then r.TrackFX_SetEnabled(LT_Track, i, false) end
                                            end
                                        end
                                    end


                                    if not FX[FxGUID].LyrDisable then
                                        r.TrackFX_SetEnabled(LT_Track, FX_Idx, false)
                                    else
                                        r.TrackFX_SetEnabled(LT_Track, FX_Idx, true)
                                        FX[FxGUID].AldreadyBPdFXs = {}
                                    end

                                    if FX[FxGUID].LyrDisable then FX[FxGUID].LyrDisable = false else FX[FxGUID].LyrDisable = true end
                                end


                                if not FXLayerRenaming then
                                    if LBtnClickCount == 2 and r.ImGui_IsItemActivated(ctx) then
                                        FX[FxGUID].RenameFXLayering = true
                                    elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == Alt then
                                        BlinkFX = ToggleCollapseAll()
                                    end
                                end


                                r.ImGui_SameLine(ctx)
                                r.ImGui_AlignTextToFramePadding(ctx)
                                if not FX[FxGUID].RenameFXLayering then
                                    r.ImGui_SetNextItemWidth(ctx, 10)
                                    local TitleShort
                                    if string.len(FX[FxGUID].ContainerTitle or '') > 27 then
                                        TitleShort = string.sub(FX[FxGUID].ContainerTitle, 1, 27)
                                    end
                                    r.ImGui_Text(ctx, TitleShort or FX[FxGUID].ContainerTitle or 'FX Layering')
                                else -- If Renaming
                                    local Flag
                                    r.ImGui_SetNextItemWidth(ctx, 180)
                                    if FX[FxGUID].ContainerTitle == 'FX Layering' then
                                        Flag = r
                                            .ImGui_InputTextFlags_AutoSelectAll()
                                    end
                                    _, FX[FxGUID].ContainerTitle = r.ImGui_InputText(ctx, '##' .. FxGUID,
                                        FX[FxGUID].ContainerTitle or 'FX Layering', Flag)

                                    r.ImGui_SetItemDefaultFocus(ctx)
                                    r.ImGui_SetKeyboardFocusHere(ctx, -1)

                                    if r.ImGui_IsItemDeactivated(ctx) then
                                        FX[FxGUID].RenameFXLayering = nil
                                        r.SetProjExtState(0, 'FX Devices - ', 'FX' .. FxGUID ..
                                            'FX Layer Container Title ', FX[FxGUID].ContainerTitle)
                                    end
                                end

                                --r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Button(), 0xffffff10)

                                r.ImGui_SameLine(ctx, FXLayeringWin_X - 25, 0)
                                r.ImGui_AlignTextToFramePadding(ctx)
                                if not FX[FxGUID].SumMode then
                                    FX[FxGUID].SumMode = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 40)
                                end
                                local Lbl
                                if FX[FxGUID].SumMode == 0 then Lbl = 'Avg' else Lbl = 'Sum' end
                                if r.ImGui_Button(ctx, (Lbl or '') .. '##FX Lyr Mode' .. FxGUID, 30, r.ImGui_GetTextLineHeight(ctx)) then
                                    FX[FxGUID].SumMode = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 40)

                                    if FX[FxGUID].SumMode == 0 then
                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 40, 1)
                                        FX[FxGUID].SumMode = 1
                                    else
                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 40, 0)
                                        FX[FxGUID].SumMode = 0
                                    end
                                end

                                --r.ImGui_PopStyleColor(ctx)
                                r.ImGui_PopStyleVar(ctx)

                                r.ImGui_EndTable(ctx)
                                r.ImGui_PopStyleColor(ctx, 2) --Header Clr
                                r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameRounding(), 0)
                                --r.ImGui_PushStyleColor(ctx,r.ImGui_Col_FrameBgActive(), 0x99999999)
                                local StyleVarPop = 1
                                local StyleClrPop = 1


                                local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)



                                local MaxChars

                                if FX[FxGUID].ActiveLyrCount <= 4 then
                                    LineH = 4; Spacing = 0; Inner_Spacing = 2; BtnSizeManual = 34; MaxChars = 15
                                elseif FX[FxGUID].ActiveLyrCount == 5 then
                                    LineH, Spacing, Inner_Spacing = 3, -5, 0; BtnSizeManual = 30; MaxChars = 18
                                elseif FX[FxGUID].ActiveLyrCount == 6 then
                                    LineH, Spacing, Inner_Spacing = 5.5, -5, -8; BtnSizeManual = 24; MaxChars = 20
                                elseif FX[FxGUID].ActiveLyrCount >= 7 then
                                    LineH, Spacing, Inner_Spacing = 3, -5, -8; BtnSizeManual = 19; MaxChars = 23
                                end



                                r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(), 1, Spacing)
                                r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 4, LineH)

                                local BtnSize, AnySoloChan
                                for LayerNum, LyrID in pairs(FX[FxGUID].LyrID) do
                                    if Lyr.Solo[LyrID .. FxGUID] == 1 then
                                        FX[FxGUID].AnySoloChan = true
                                        AnySoloChan = true
                                    end
                                end
                                if not AnySoloChan then FX[FxGUID].AnySoloChan = nil end


                                for LayerNum, LyrID in pairs(FX[FxGUID].LyrID) do
                                    if Lyr.Solo[LyrID .. FxGUID] == nil then
                                        Lyr.Solo[LyrID .. FxGUID] = reaper
                                            .TrackFX_GetParamNormalized(LT_Track, FX_Idx, 4 + (5 * (LyrID - 1)))
                                    end
                                    if Lyr.Solo[LyrID .. FxGUID] == 1 then FX[FxGUID].AnySoloChan = true end
                                    if Lyr.Mute[LyrID .. FxGUID] == nil then
                                        Lyr.Mute[LyrID .. FxGUID] = reaper
                                            .TrackFX_GetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1))
                                    end
                                    if Lyr.Mute[LyrID .. FxGUID] == 1 then FX[FxGUID].AnyMuteChan = true end

                                    if Lyr.ProgBarVal[LyrID .. FxGUID] == nil then
                                        Layer1Vol = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 1)
                                        Lyr.ProgBarVal[LyrID .. FxGUID] = Layer1Vol
                                    end

                                    LyrFX_Inst = math.max(LyrFX_Inst or 0, LyrID)
                                    local HowManyFXinLyr = 0
                                    for i = 0, Sel_Track_FX_Count, 1 do
                                        if FX.InLyr[FXGUID[i]] == FXGUID_RackMixer and FX[FXGUID[i]].inWhichLyr == LyrID then
                                            HowManyFXinLyr = HowManyFXinLyr + 1
                                        end
                                    end


                                    local Fx_P = (LyrID * 2) - 1

                                    local CurY = r.ImGui_GetCursorPosY(ctx)
                                    if FX[FxGUID][Fx_P] then
                                        LyrCurX, LyrCurY = r.ImGui_GetCursorScreenPos(ctx)

                                        if Lyr.Rename[LyrID .. FxGUID] ~= true and Fx_P then
                                            --r.ImGui_ProgressBar(ctx, Lyr.ProgBarVal[LyrID..FxGUID], FXLayeringWin_X-60, 30, '##Layer'.. LyrID)
                                            local P_Num = 1 + (5 * (LyrID - 1))
                                            local ID = LyrID
                                            FX[FxGUID].LyrTitle = FX[FxGUID].LyrTitle or {}

                                            local labeltoShow = FX[FxGUID].LyrTitle[ID] or LyrID

                                            if string.len(labeltoShow or '') > MaxChars then
                                                labeltoShow = string.sub(FX[FxGUID].LyrTitle[ID], 1, MaxChars)
                                            end
                                            local Fx_P = LyrID * 2 - 1
                                            local Label = '##' .. LyrID .. FxGUID
                                            FX[FxGUID][Fx_P] = FX[FxGUID][Fx_P] or {}
                                            FX[FxGUID][Fx_P].V = FX[FxGUID][Fx_P].V or 0.5
                                            local p_value = FX[FxGUID][Fx_P].V or 0
                                            --[[ r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 0, BtnSizeManual/3) ]]
                                            --[[ r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(), getClr(r.ImGui_Col_Button())) ]]
                                            SliderStyle = nil; Rounding = 0
                                            local CurY = r.ImGui_GetCursorPosY(ctx)
                                            AddDrag(ctx, Label, labeltoShow, p_value, 0, 1, Fx_P, FX_Idx, P_Num,
                                                'FX Layering', FXLayeringWin_X - BtnSizeManual * 3 - 23, Inner_Spacing,
                                                Disable, Lbl_Clickable, 'Bottom', 'Bottom', DragDir, 'NoInput')
                                            --[[ r.ImGui_PopStyleColor(ctx)  r.ImGui_PopStyleVar(ctx) ]]

                                            local L, T = r.ImGui_GetItemRectMin(ctx); B = T + BtnSizeManual
                                            BtnSize = B - T
                                            r.ImGui_SameLine(ctx, nil, 10)
                                            r.ImGui_SetCursorPosY(ctx, CurY)

                                            if Lyr.Selected[FXGUID_RackMixer] == LyrID then
                                                local R = L + FXLayeringWin_X
                                                r.ImGui_DrawList_AddLine(WDL, L, T - 2, R - 2 + Pad, T - 2, 0x99999999)
                                                r.ImGui_DrawList_AddLine(WDL, L, B, R - 2 + Pad, B, 0x99999999)
                                                r.ImGui_DrawList_AddRectFilled(WDL, L, T - 2, R + Pad, B, 0xffffff09)
                                                FX[FxGUID].TheresFXinLyr = nil
                                                for FX_Idx = 1, Sel_Track_FX_Count - 1, 1 do
                                                    if FX[FXGUID[FX_Idx]] then
                                                        if FX[FXGUID[FX_Idx]].inWhichLyr == LyrID and FX.InLyr[FXGUID[FX_Idx]] == FXGUID_RackMixer then
                                                            r.ImGui_DrawList_AddLine(WDL, R - 2 + Pad, T, R - 2 + Pad,
                                                                FXLayerFrame_PosY_T, 0x99999999)
                                                            r.ImGui_DrawList_AddLine(WDL, R - 2 + Pad, B, R - 2 + Pad,
                                                                FXLayerFrame_PosY_B, 0x99999999)
                                                            FX[FxGUID].TheresFXinLyr = true
                                                        end
                                                    end
                                                end
                                                if not FX[FxGUID].TheresFXinLyr then
                                                    r.ImGui_DrawList_AddLine(WDL, R, T, R, B, 0x99999999)
                                                else
                                                end
                                            end

                                            if r.ImGui_IsItemClicked(ctx) and Mods == Alt then
                                                local TheresFXinLyr
                                                for FX_Idx = 1, Sel_Track_FX_Count - 1, 1 do
                                                    if FX[FXGUID[FX_Idx]].inWhichLyr == FX[FXGUID_RackMixer].LyrID[LyrID] and FX.InLyr[FXGUID[FX_Idx]] == FXGUID_RackMixer then
                                                        TheresFXinLyr = true
                                                    end
                                                end

                                                FX_Idx_RackMixer = FX_Idx
                                                function DeleteOneLayer(LyrID, FxGUID, FX_Idx, LT_Track)
                                                    FX[FxGUID].LyrID[LyrID] = -1
                                                    FX[FxGUID].LyrTitle[LyrID] = nil
                                                    FX[FxGUID].ActiveLyrCount = math.max(FX[FxGUID].ActiveLyrCount - 1, 1)
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1), 0) -- turn channel power off
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx,
                                                        1 + (5 * (LyrID - 1) + 1),
                                                        0.5) -- set pan to center
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 1 + (5 * (LyrID - 1)),
                                                        0.5) -- set Vol to 0
                                                    r.SetProjExtState(0, 'FX Devices', 'FX' .. FxGUID ..
                                                        'Layer ID ' .. LyrID, '-1')
                                                    r.SetProjExtState(0, 'FX Devices - ',
                                                        'FX' .. FxGUID .. 'Layer Title ' .. LyrID, '')
                                                end

                                                if not TheresFXinLyr then
                                                    DeleteOneLayer(LyrID, FxGUID, FX_Idx, LT_Track)
                                                else
                                                    local Modalw, Modalh = 225, 70
                                                    r.ImGui_SetNextWindowPos(ctx, VP.x + VP.w / 2 - Modalw / 2,
                                                        VP.y + VP.h / 2 - Modalh / 2)
                                                    r.ImGui_SetNextWindowSize(ctx, Modalw, Modalh)
                                                    r.ImGui_OpenPopup(ctx, 'Delete FX Layer ' .. LyrID .. '? ##' ..
                                                        FxGUID)
                                                end
                                            elseif r.ImGui_IsItemClicked(ctx) and LBtnDC then
                                                FX[FxGUID][Fx_P].V = 0.5
                                                local rv = r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, 0.5)
                                            elseif r.ImGui_IsItemClicked(ctx) and Mods == Ctrl and not FXLayerRenaming then
                                                Lyr.Rename[LyrID .. FxGUID] = true
                                            elseif r.ImGui_IsItemClicked(ctx) and Mods == 0 then
                                                Lyr.Selected[FXGUID_RackMixer] = LyrID
                                            end
                                        elseif Lyr.Rename[LyrID .. FxGUID] == true then
                                            for i = 1, 8, 1 do -- set all other layer's rename to false
                                                if LyrID ~= i then Lyr.Rename[i .. FxGUID] = false end
                                            end
                                            FXLayerRenaming = true
                                            reaper.ImGui_SetKeyboardFocusHere(ctx)
                                            r.ImGui_SetNextItemWidth(ctx, FXLayeringWin_X - BtnSizeManual * 3 - 23)
                                            local ID = FX[FxGUID].LyrID[LyrID]
                                            FX[FxGUID].LyrTitle = FX[FxGUID].LyrTitle or {}
                                            _, FX[FxGUID].LyrTitle[ID] = r.ImGui_InputText(ctx, '##' .. LyrID,
                                                FX[FxGUID].LyrTitle[ID])

                                            if r.ImGui_IsItemDeactivatedAfterEdit(ctx) then
                                                Lyr.Rename[LyrID .. FxGUID] = false
                                                FXLayerRenaming = nil
                                                r.SetProjExtState(0, 'FX Devices - ', 'FX' ..
                                                    FxGUID .. 'Layer Title ' .. LyrID, FX[FxGUID].LyrTitle[ID])
                                            elseif r.ImGui_IsItemDeactivated(ctx) then
                                                Lyr.Rename[LyrID .. FxGUID] = false
                                                FXLayerRenaming = nil
                                            end
                                            SL(nil, 10)
                                        end

                                        ------------ Confirm delete layer ---------------------
                                        if r.ImGui_BeginPopupModal(ctx, 'Delete FX Layer ' .. LyrID .. '? ##' .. FxGUID, true, r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_NoResize()) then
                                            r.ImGui_Text(ctx, 'Delete all FXs in layer ' .. LyrID .. '?')
                                            r.ImGui_Text(ctx, ' ')

                                            if r.ImGui_Button(ctx, '(n) No (or Esc)') or r.ImGui_IsKeyPressed(ctx, 78) or r.ImGui_IsKeyPressed(ctx, 27) then
                                                r.ImGui_CloseCurrentPopup(ctx)
                                            end
                                            r.ImGui_SameLine(ctx, nil, 20)
                                            if r.ImGui_Button(ctx, '(y) Yes') or r.ImGui_IsKeyPressed(ctx, 89) then
                                                r.Undo_BeginBlock()
                                                local L, H, HowMany = 999, 0, 0

                                                for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do
                                                    if FX[FXGUID[FX_Idx]].inWhichLyr == FX[FXGUID_RackMixer].LyrID[LyrID] and FX.InLyr[FXGUID[FX_Idx]] == FXGUID_RackMixer then
                                                        HowMany = HowMany + 1
                                                        L = math.min(FX_Idx, L)
                                                        H = math.max(FX_Idx, H)
                                                    end
                                                end

                                                for i = 1, HowMany, 1 do
                                                    if FX[FXGUID[L]].inWhichLyr == FX[FXGUID_RackMixer].LyrID[LyrID] and FX.InLyr[FXGUID[L]] == FXGUID_RackMixer then
                                                        r.TrackFX_Delete(LT_Track, L)
                                                    end
                                                end
                                                DeleteOneLayer(LyrID, FXGUID_RackMixer, FX_Idx_RackMixer, LT_Track)

                                                diff = H - L + 1
                                                r.Undo_EndBlock('Delete Layer ' .. LyrID, 0)
                                            end
                                            r.ImGui_EndPopup(ctx)
                                        end




                                        ProgBar_Pos_L, ProgBar_PosY_T = r.ImGui_GetItemRectMin(ctx)
                                        ProgBar_Pos_R, ProgBar_PosY_B = r.ImGui_GetItemRectMax(ctx)





                                        if Lyr.Selected[FXGUID_RackMixer] == LyrID and Lyr.Rename[LyrID .. FxGUID] ~= true then
                                            r.ImGui_DrawList_AddRect(drawlist, ProgBar_Pos_L, ProgBar_PosY_T,
                                                FXLayerFrame_PosX_R, ProgBar_PosY_B, 0xffffffff)
                                        end

                                        drawlistInFXLayering = r.ImGui_GetForegroundDrawList(ctx)


                                        if r.ImGui_BeginDragDropTarget(ctx) then
                                            dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag') --

                                            if dropped and Mods == 0 then
                                                DropFXtoLayer(FX_Idx, LayerNum)
                                            elseif dropped and Mods == Apl then
                                                DragFX_Src = DragFX_ID
                                                if DragFX_ID > FX_Idx then
                                                    DragFX_Dest = FX_Idx - 1
                                                else
                                                    DragFX_Dest =
                                                        FX_Idx
                                                end
                                                DropToLyrID = LyrID
                                                DroptoRack = FXGUID_RackMixer
                                            end
                                            if Payload_Type == 'AddFX_Sexan' then
                                                dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'AddFX_Sexan') --
                                                if dropped then
                                                    r.TrackFX_AddByName(LT_Track, payload, false, -1000 - FX_Idx)

                                                    DropFXtoLayer(FX_Idx, LyrID)
                                                end
                                            end

                                            HighlightSelectedItem(0x88888844, 0xffffffff, 0, L, T, R, B, h, w,
                                                H_OutlineSc, V_OutlineSc, 'GetItemRect')
                                            r.ImGui_EndDragDropTarget(ctx)
                                        end

                                        local Label = '##Pan' .. LyrID .. FxGUID

                                        local P_Num = 1 + (5 * (LyrID - 1) + 1)
                                        local Fx_P_Knob = LyrID * 2
                                        local Label = '## Pan' .. LyrID .. FxGUID
                                        local p_value_Knob = FX[FxGUID][Fx_P_Knob].V
                                        local labeltoShow = HowManyFXinLyr



                                        AddKnob(ctx, Label, labeltoShow, p_value_Knob, 0, 1, Fx_P_Knob, FX_Idx, P_Num,
                                            'FX Layering', BtnSizeManual / 2, 0, Disabled, 9, 'Within', 'None')
                                        r.ImGui_SameLine(ctx, nil, 10)

                                        if LBtnDC and reaper.ImGui_IsItemClicked(ctx, 0) then
                                            FX[FxGUID][Fx_P_Knob].V = 0.5
                                            local rv = r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, P_Num, 0.5)
                                        end

                                        r.ImGui_SetCursorPosY(ctx, CurY)

                                        if Lyr.Solo[LyrID .. FxGUID] == 1 then
                                            local Clr = Layer_Solo or CustomColorsDefault.Layer_Solo
                                            local Act, Hvr = Generate_Active_And_Hvr_CLRs(Clr)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), Clr)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), Act)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), Hvr)

                                            SoloBtnClrPop = 3
                                        end

                                        ClickOnSolo = r.ImGui_Button(ctx, 'S##' .. LyrID, BtnSizeManual, BtnSizeManual) -- ==  lyr solo

                                        if Lyr.Solo[LyrID .. FxGUID] == 1 then r.ImGui_PopStyleColor(ctx, SoloBtnClrPop) end


                                        if ClickOnSolo then
                                            Lyr.Solo[LyrID .. FxGUID] = reaper.TrackFX_GetParamNormalized(LT_Track,
                                                FX_Idx, 4 + (5 * (LyrID - 1)))
                                            if Lyr.Solo[LyrID .. FxGUID] == 1 then
                                                Lyr.Solo[LyrID .. FxGUID] = 0
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 4 + (5 * (LyrID - 1)),
                                                    Lyr.Solo[LyrID .. FxGUID])
                                                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0x9ed9d3ff)
                                                r.ImGui_PopStyleColor(ctx)
                                            elseif Lyr.Solo[LyrID .. FxGUID] == 0 then
                                                Lyr.Solo[LyrID .. FxGUID] = 1
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 4 + (5 * (LyrID - 1)),
                                                    Lyr.Solo[LyrID .. FxGUID])
                                            end
                                        end
                                        if Lyr.Solo[LyrID .. FxGUID] == nil then
                                            Lyr.Solo[LyrID .. FxGUID] = reaper
                                                .TrackFX_GetParamNormalized(LT_Track, FX_Idx, 4 + (5 * (LyrID - 1)))
                                        end

                                        r.ImGui_SameLine(ctx, nil, 3)
                                        r.ImGui_SetCursorPosY(ctx, CurY)
                                        if Lyr.Mute[LyrID .. FxGUID] == 0 then
                                            local Clr = Layer_Mute or CustomColorsDefault.Layer_Mute
                                            local Act, Hvr = Generate_Active_And_Hvr_CLRs(Clr)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), Clr)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), Act)
                                            r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), Hvr)
                                            LyrMuteClrPop = 3
                                        end
                                        ClickOnMute = r.ImGui_Button(ctx, 'M##' .. LyrID, BtnSizeManual, BtnSizeManual)
                                        if Lyr.Mute[LyrID .. FxGUID] == 0 then r.ImGui_PopStyleColor(ctx, LyrMuteClrPop) end



                                        if Lyr.Mute[LyrID .. FxGUID] == nil then
                                            Lyr.Mute[LyrID .. FxGUID] = reaper
                                                .TrackFX_GetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1))
                                        end

                                        if ClickOnMute then
                                            Lyr.Mute[LyrID .. FxGUID] = reaper.TrackFX_GetParamNormalized(LT_Track,
                                                FX_Idx, 5 * (LyrID - 1))
                                            if Lyr.Mute[LyrID .. FxGUID] == 1 then
                                                Lyr.Mute[LyrID .. FxGUID] = 0
                                                reaper.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1),
                                                    Lyr.Mute[LyrID .. FxGUID])
                                            elseif Lyr.Mute[LyrID .. FxGUID] == 0 then
                                                Lyr.Mute[LyrID .. FxGUID] = 1
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 5 * (LyrID - 1),
                                                    Lyr.Mute[LyrID .. FxGUID])
                                            end
                                        end




                                        MuteBtnR, MuteBtnB = r.ImGui_GetItemRectMax(ctx)

                                        if FX[FxGUID].AnySoloChan then
                                            if Lyr.Solo[LyrID .. FxGUID] ~= 1 then
                                                r.ImGui_DrawList_AddRectFilled(WDL, LyrCurX, LyrCurY, MuteBtnR, MuteBtnB,
                                                    0x00000088)
                                            end
                                        end
                                        if Lyr.Mute[LyrID .. FxGUID] == 0 then
                                            r.ImGui_DrawList_AddRectFilled(WDL, LyrCurX, LyrCurY, MuteBtnR, MuteBtnB,
                                                0x00000088)
                                        end
                                    end
                                end




                                if FX[FxGUID].ActiveLyrCount ~= 8 then
                                    AddNewLayer = r.ImGui_Button(ctx, '+', FXLayeringWin_X, 25)
                                    if AddNewLayer then
                                        local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)

                                        if FX[FxGUID].ActiveLyrCount <= 8 then
                                            local EmptyChan, chan1, chan2, chan3; local lastnum = 0
                                            for i, v in ipairs(FX[FxGUID].LyrID) do
                                                if not EmptyChan then
                                                    if v == -1 then EmptyChan = i end
                                                end
                                            end

                                            if not EmptyChan then EmptyChan = FX[FxGUID].ActiveLyrCount + 1 end
                                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 5 * (EmptyChan - 1), 1)
                                            FX[FxGUID].ActiveLyrCount = math.min(FX[FxGUID].ActiveLyrCount + 1, 8)
                                            FX[FxGUID][EmptyChan * 2 - 1].V = 0.5 -- init val for Vol
                                            FX[FxGUID][EmptyChan * 2].V = 0.5     -- init val for Pan

                                            FX[FxGUID].LyrID[EmptyChan] = EmptyChan

                                            r.SetProjExtState(0, 'FX Devices', 'FX' .. FxGUID .. 'Layer ID ' .. EmptyChan,
                                                EmptyChan)
                                        end
                                    end
                                end
                                r.ImGui_PopStyleVar(ctx, StyleVarPop)
                                r.ImGui_PopStyleVar(ctx, 2)

                                r.ImGui_EndChildFrame(ctx)
                            end
                            r.ImGui_PopStyleColor(ctx, StyleClrPop)
                        else -- if collapsed
                            if r.ImGui_BeginChildFrame(ctx, '##FX Layer at' .. FX_Idx .. 'OnTrack ' .. TrkID, 27, 220, r.ImGui_WindowFlags_NoScrollbar()) then
                                L, T = r.ImGui_GetItemRectMin(ctx)
                                local DL = r.ImGui_GetWindowDrawList(ctx)
                                local title = (FX[FxGUID].ContainerTitle or 'FX Layering'):gsub("(.)", "%1\n")

                                WindowBtnVertical = reaper.ImGui_Button(ctx, title .. '##Vertical', 25, 220) -- create window name button
                                if WindowBtnVertical and Mods == 0 then
                                elseif WindowBtnVertical == true and Mods == Shift then
                                    ToggleBypassFX()
                                elseif r.ImGui_IsItemClicked(ctx) and Mods == Alt then
                                    FX[FxGUID].DeleteFXLayer = true
                                elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == 0 then
                                    FX[FxGUID].Collapse = nil
                                elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == Alt then
                                    BlinkFX = ToggleCollapseAll()
                                end

                                if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_None()) then
                                    DragFX_ID = FX_Idx
                                    r.ImGui_SetDragDropPayload(ctx, 'FX Layer Repositioning', FX_Idx)
                                    r.ImGui_EndDragDropSource(ctx)
                                    DragDroppingFX = true
                                    if IsAnyMouseDown == false then DragDroppingFX = false end
                                end

                                r.ImGui_DrawList_AddRectFilled(WDL, L, T + 2, L + 25, T, 0x999999aa)
                                r.ImGui_DrawList_AddRectFilled(WDL, L, T + 4, L + 25, T + 6, 0x999999aa)
                                r.ImGui_DrawList_AddRect(WDL, L, T + 2, L + 25, T + 218, 0x99999977)


                                r.ImGui_EndChildFrame(ctx)
                            end
                        end

                        FX[FxGUID].DontShowTilNextFullLoop = true

                        if not FX[FxGUID].Collapse then --Create FX windows inside rack
                            local Sel_LyrID
                            drawlist = r.ImGui_GetBackgroundDrawList(ctx)


                            Lyr.FrstFXPos[FXGUID_RackMixer] = nil
                            local HowManyFXinLyr = 0
                            for FX_Idx_InLayer = 0, Sel_Track_FX_Count - 1, 1 do
                                local FXisInLyr

                                for LayerNum, LyrID in pairs(FX[FxGUID].LyrID) do
                                    FXGUID_To_Check_If_InLayer = r.TrackFX_GetFXGUID(LT_Track, FX_Idx_InLayer)

                                    if FX.InLyr[FXGUID_To_Check_If_InLayer] == FXGUID[FX_Idx] then --if fx is in rack mixer
                                        if FindStringInTable(BlackListFXs, FX.Win_Name[FX_Idx_InLayer]) then end

                                        if Lyr.Selected[FXGUID_RackMixer] == nil then Lyr.Selected[FXGUID_RackMixer] = 1 end
                                        local FXGUID_LayerCheck = r.TrackFX_GetFXGUID(LT_Track, FX_Idx_InLayer)
                                        if FX[FXGUID[FX_Idx_InLayer]].inWhichLyr == FX[FXGUID_RackMixer].LyrID[LyrID] and LyrID == Lyr.Selected[FXGUID_RackMixer] and not FindStringInTable(BlackListFXs, FX.Win_Name[FX_Idx_InLayer]) then
                                            r.ImGui_SameLine(ctx, nil, 0)

                                            AddSpaceBtwnFXs(FX_Idx_InLayer, false, nil, LyrID)
                                            Xpos_Left, Ypos_Top = reaper.ImGui_GetItemRectMin(ctx)
                                            r.ImGui_SameLine(ctx, nil, 0)
                                            if not FindStringInTable(BlackListFXs, FX.Win_Name[FX_Idx_InLayer]) then
                                                createFXWindow(FX_Idx_InLayer)
                                            else
                                            end
                                            Sel_LyrID = LyrID

                                            Xpos_Right, Ypos_Btm = r.ImGui_GetItemRectMax(ctx)

                                            r.ImGui_DrawList_AddLine(ViewPort_DL, Xpos_Left, Ypos_Top, Xpos_Right,
                                                Ypos_Top, Clr.Dvdr.outline)
                                            r.ImGui_DrawList_AddLine(ViewPort_DL, Xpos_Left, Ypos_Btm, Xpos_Right,
                                                Ypos_Btm, Clr.Dvdr.outline)
                                        end
                                        FXisInLyr = true
                                    end
                                end
                                if FXisInLyr == true then HowManyFXinLyr = HowManyFXinLyr + 1 end

                                if FX.InLyr[FXGUID_To_Check_If_InLayer] == FXGUID[FX_Idx] then
                                    if Lyr.FrstFXPos[FXGUID_RackMixer] == nil then
                                        Lyr.FrstFXPos[FXGUID_RackMixer] = FX_Idx_InLayer
                                    else
                                        Lyr.FrstFXPos[FXGUID_RackMixer] = math.min(Lyr.FrstFXPos[FXGUID_RackMixer],
                                            FX_Idx_InLayer)
                                    end
                                    Lyr.LastFXPos[FXGUID_RackMixer] = FX_Idx_InLayer
                                end

                                r.ImGui_SameLine(ctx, nil, 0)
                            end


                            Lyr[FXGUID_RackMixer] = Lyr[FXGUID_RackMixer] or {}
                            Lyr[FXGUID_RackMixer].HowManyFX = HowManyFXinLyr



                            if HowManyFXinLyr > 0 and FX[FxGUID].TheresFXinLyr then -- ==  Add and theres fx in selected layer
                                --if there's fx in the rack

                                AddLastSPCinRack = true

                                AddSpaceBtwnFXs(FX_Idx, nil, nil, Sel_LyrID)
                                AddLastSPCinRack = false
                                Xpos_Right, Ypos_Btm = reaper.ImGui_GetItemRectMax(ctx)
                                Xpos_Left, Ypos_Top = reaper.ImGui_GetItemRectMin(ctx)


                                local TheresFXinLyr
                                for FX_Idx = 1, Sel_Track_FX_Count - 1, 1 do
                                    if FX[FXGUID[FX_Idx]] then
                                        if FX[FXGUID[FX_Idx]].inWhichLyr == FX[FXGUID_RackMixer].LyrID[Lyr.Selected[FXGUID_RackMixer]] and FX.InLyr[FXGUID[FX_Idx]] == FXGUID_RackMixer then
                                            TheresFXinLyr = true
                                        end
                                    end
                                end


                                if TheresFXinLyr then --==  lines to enclose fx layering
                                    r.ImGui_DrawList_AddLine(ViewPort_DL, Xpos_Left, Ypos_Top, Xpos_Right, Ypos_Top,
                                        Clr.Dvdr.outline)
                                    r.ImGui_DrawList_AddLine(ViewPort_DL, Xpos_Left, Ypos_Btm, Xpos_Right, Ypos_Btm,
                                        Clr.Dvdr.outline)
                                    r.ImGui_DrawList_AddLine(ViewPort_DL, Xpos_Right, Ypos_Top, Xpos_Right, Ypos_Btm,
                                        Clr.Dvdr.outline, 14)
                                end
                            end
                        end







                        if FX[FxGUID].DeleteFXLayer then
                            local FXinRack = 0
                            --count number of fxs in layer
                            for FX_Idx_InLayer = 0, Sel_Track_FX_Count - 1, 1 do
                                for LayerNum, LyrID in pairs(FX[FxGUID].LyrID) do
                                    local GUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx_InLayer)
                                    if FX.InLyr[GUID] == FXGUID[FX_Idx] then
                                        FXinRack = FXinRack + 1
                                    end
                                end
                            end

                            if FXinRack == 0 then -- if no fx just delete
                                r.TrackFX_Delete(LT_Track, FX_Idx - 1)
                                r.TrackFX_Delete(LT_Track, FX_Idx - 1)
                                FX[FxGUID].DeleteFXLayer = nil
                            else -- else prompt user
                                local Modalw, Modalh = 270, 55
                                r.ImGui_SetNextWindowPos(ctx, VP.x + VP.w / 2 - Modalw / 2, VP.y + VP.h / 2 - Modalh / 2)
                                r.ImGui_SetNextWindowSize(ctx, Modalw, Modalh)
                                r.ImGui_OpenPopup(ctx, 'Delete FX Layer? ##' .. FxGUID)
                            end
                        end

                        if r.ImGui_BeginPopupModal(ctx, 'Delete FX Layer? ##' .. FxGUID, nil, r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_NoResize()) then
                            r.ImGui_Text(ctx, 'Delete the FXs in layers altogether?')
                            if r.ImGui_Button(ctx, '(n) No') or r.ImGui_IsKeyPressed(ctx, 78) then
                                for i = 0, Sel_Track_FX_Count, 1 do
                                    if FX.InLyr[FXGUID[i]] == FXGUID[FX_Idx] then
                                        --sets input channel
                                        r.TrackFX_SetPinMappings(LT_Track, i, 0, 0, 1, 0)
                                        r.TrackFX_SetPinMappings(LT_Track, i, 0, 1, 2, 0)
                                        --sets Output
                                        r.TrackFX_SetPinMappings(LT_Track, i, 1, 0, 1, 0)
                                        r.TrackFX_SetPinMappings(LT_Track, i, 1, 1, 2, 0)
                                        FX.InLyr[FXGUID[i]] = nil
                                        r.SetProjExtState(0, 'FX Devices',
                                            'FXLayer - ' .. 'is FX' .. FXGUID[i] .. 'in layer', "")
                                    end
                                end

                                for i = 0, Sel_Track_FX_Count, 1 do
                                    if FXGUID[FX_Idx] == Lyr.SplitrAttachTo[FXGUID[i]] then
                                        r.TrackFX_Delete(LT_Track, FX_Idx)
                                        r.TrackFX_Delete(LT_Track, i)
                                    end
                                end

                                FX[FxGUID].DeleteFXLayer = nil
                            end
                            r.ImGui_SameLine(ctx)

                            if r.ImGui_Button(ctx, '(y) Yes') or r.ImGui_IsKeyPressed(ctx, 89) then
                                local Spltr, FX_Inst
                                for i = 0, Sel_Track_FX_Count, 1 do
                                    if FXGUID[FX_Idx] == Lyr.SplitrAttachTo[FXGUID[i]] then
                                        Spltr = i
                                    end
                                end
                                r.Undo_BeginBlock()

                                for i = 0, Sel_Track_FX_Count, 1 do
                                    if FX.InLyr[FXGUID[i]] == FXGUID[FX_Idx] then
                                        FX_Inst = (FX_Inst or 0) + 1
                                        r.SetProjExtState(0, 'FX Devices',
                                            'FXLayer - ' .. 'is FX' .. FXGUID[i] .. 'in layer', "")
                                    end
                                end

                                for i = 0, FX_Inst, 1 do
                                    r.TrackFX_Delete(LT_Track, Spltr)
                                end



                                FX[FxGUID].DeleteFXLayer = nil
                                r.Undo_EndBlock('Delete Layer Container', 0)
                            end
                            r.ImGui_SameLine(ctx)

                            if r.ImGui_Button(ctx, '(c) Cancel  (or Esc)') or r.ImGui_IsKeyPressed(ctx, 67) or r.ImGui_IsKeyPressed(ctx, 27) then
                                FX[FxGUID].DeleteFXLayer = nil
                                r.ImGui_CloseCurrentPopup(ctx)
                            end
                            r.ImGui_SameLine(ctx)

                            r.ImGui_EndPopup(ctx)
                        end

                        r.ImGui_SameLine(ctx, nil, 0)
                        FX[FXGUID[FX_Idx]].DontShowTilNextFullLoop = true
                    elseif FX_Name:find('FXD ReSpectrum') then
                        local _, FX_Name_After = r.TrackFX_GetFXName(LT_Track, FX_Idx + 1)
                        --if FX below is not Pro-Q 3
                        if string.find(FX_Name_After, 'Pro%-Q 3') == nil then
                            ProQ3.SpectrumDeleteWait = (ProQ3.SpectrumDeleteWait or 0) + 1
                            if ProQ3.SpectrumDeleteWait > FX_Add_Del_WaitTime then
                                if FX_Idx == Sel_Track_FX_Count then
                                    r.TrackFX_Delete(LT_Track, FX_Idx)
                                else
                                    r.TrackFX_Delete(LT_Track, FX_Idx)
                                end
                                ProQ3.SpectrumDeleteWait = 0
                            end
                        else
                            if FX.InLyr[FXGUID[FX_Idx + 1]] then -- if in layering
                                SyncAnalyzerPinWithFX(FX_Idx, FX_Idx + 1, FX.Win_Name[math.max(FX_Idx - 1, 0)])
                                FX.InLyr[FxGUID] = FX.InLyr[FXGUID[FX_Idx + 1]]
                            else
                                FX.InLyr[FxGUID] = nil
                            end
                        end
                    elseif FX_Name:find('FXD Split to 4 channels') then
                        local _, FX_Name_After = r.TrackFX_GetFXName(LT_Track, FX_Idx + 1)
                        --if FX below is not Pro-C 2
                        if FX_Name_After then
                            if string.find(FX_Name_After, 'Pro%-C 2') then
                                if FX.InLyr[FXGUID[FX_Idx + 1]] then -- if in layering
                                    SyncAnalyzerPinWithFX(FX_Idx, FX_Idx + 1, FX_Name)
                                end
                            end
                        end
                    elseif FX_Name:find('FXD Gain Reduction Scope') then
                        r.gmem_attach('CompReductionScope')
                        if FX[FXGUID[FX_Idx - 1]] then
                            r.gmem_write(FX[FXGUID[FX_Idx - 1]].ProC_ID or 0, FX_Idx - 1)
                        end
                        local _, FX_Name_Before = r.TrackFX_GetFXName(LT_Track, FX_Idx - 1)


                        --if FX above is not Pro-C 2
                        FX[FxGUID].ProC_Scope_Del_Wait = (FX[FxGUID].ProC_Scope_Del_Wait or 0) + 1

                        if FX[FxGUID].ProC_Scope_Del_Wait > FX_Add_Del_WaitTime + 10 then
                            if string.find(FX_Name_Before, 'Pro%-C 2') then
                                if FX.InLyr[FXGUID[FX_Idx - 1]] then -- if in layering
                                    SyncAnalyzerPinWithFX(FX_Idx, FX_Idx - 1, FX_Name)
                                end
                            end
                            FX[FxGUID].ProC_Scope_Del_Wait = 0
                        end

                        if FX.InLyr[FXGUID[FX_Idx - 1]] then
                            FX.InLyr[FxGUID] = FX.InLyr[FXGUID[FX_Idx - 1]]
                        else
                            FX.InLyr[FxGUID] = nil
                        end
                    elseif string.find(FX_Name, 'FXD Split to 32 Channels') ~= nil then
                        r.TrackFX_Show(LT_Track, FX_Idx, 2)
                        AddSpaceBtwnFXs(FX_Idx, true)
                        Spltr[FxGUID] = Spltr[FxGUID] or {}
                        Lyr[Lyr.SplitrAttachTo[FxGUID]] = Lyr[Lyr.SplitrAttachTo[FxGUID]] or {}
                        if Lyr[Lyr.SplitrAttachTo[FxGUID]].HowManyFX == 0 then
                            if FXGUID[FX_Idx + 1] ~= Lyr.SplitrAttachTo[FxGUID] then
                                for i = 0, Sel_Track_FX_Count - 1, 1 do
                                    if FXGUID[i] == Lyr.SplitrAttachTo[FxGUID] then
                                        r.TrackFX_CopyToTrack(LT_Track, FX_Idx, LT_Track, i - 1, true)
                                    end
                                end
                            end
                        end

                        if Spltr[FxGUID].New == true then
                            for i = 0, 16, 2 do
                                r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, i, 1, 0)
                            end

                            for i = 1, 16, 2 do
                                r.TrackFX_SetPinMappings(LT_Track, FX_Idx, 0, i, 2, 0)
                            end

                            local FxGUID_Rack = Lyr.SplitrAttachTo[FxGUID]
                            for i = 1, 8, 1 do
                                local P_Num = 1 + (5 * (i - 1))
                                local Fx_P = i * 2 - 1
                                local P_Name = 'Chan ' .. i .. ' Vol'
                                StoreNewParam(FxGUID_Rack, P_Name, P_Num, FX_Idx, IsDeletable, 'AddingFromExtState', Fx_P,
                                    FX_Idx) -- Vol
                                local P_Num = 1 + (5 * (i - 1) + 1)
                                local Fx_P_Pan = i * 2
                                local P_Name = 'Chan ' .. i .. ' Pan'
                                StoreNewParam(FxGUID_Rack, P_Name, P_Num, FX_Idx, IsDeletable, 'AddingFromExtState',
                                    Fx_P_Pan, FX_Idx) -- Pan
                            end
                            Spltr[FxGUID].New = false
                        end

                        if FX.InLyr[FXGUID[FX_Idx + 1] or ''] then
                            FX.InLyr[FxGUID] = FX.InLyr[FXGUID[FX_Idx + 1]]
                        else
                            FX.InLyr[FxGUID] = nil
                        end

                        pin = r.TrackFX_GetPinMappings(LT_Track, FX_Idx, 0, 0)
                    elseif FX_Name:find('FXD Saike BandSplitter') then
                        local Width, BtnWidth = 65, 25
                        local WinL, WinT, H, WinR
                        local WDL = WDL or r.ImGui_GetWindowDrawList(ctx)

                        if BandSplitID and not FX[FxGUID].BandSplitID then
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: BandSplitterID' .. FxGUID, BandSplitID, true)
                            FX[FxGUID].BandSplitID = BandSplitID
                            BandSplitID = nil
                        end
                        FX[FxGUID].FXsInBS = FX[FxGUID].FXsInBS or {}
                        local JoinerID
                        for i, v in ipairs(FXGUID) do
                            if FX[FxGUID].AttachToJoiner == v then JoinerID = i end
                        end
                        local BsID = FX[FxGUID].BandSplitID
                        if FX[FxGUID].Collapse then Width = 35 end


                        if r.ImGui_BeginChild(ctx, 'FXD Saike BandSplitter' .. FxGUID, Width, 220) then
                            local SpcW = AddSpaceBtwnFXs(FX_Idx, 'SpaceBeforeBS', nil, nil, 1, FxGUID)
                            SL(nil, 0)

                            local btnTitle = string.gsub('Band Split', "(.)", "%1\n")
                            local btn = r.ImGui_Button(ctx, btnTitle .. '##Vertical', BtnWidth, 220) -- create window name button   Band Split button


                            if btn and Mods == 0 then
                                openFXwindow(LT_Track, FX_Idx)
                            elseif btn and Mods == Shift then
                                ToggleBypassFX(LT_Track, FX_Idx)
                            elseif btn and Mods == Alt then
                                FX[FxGUID].DeleteBandSplitter = true
                            elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == 0 then
                                FX[FxGUID].Collapse = toggle(FX[FxGUID].Collapse)
                            elseif r.ImGui_IsItemClicked(ctx, 1) and Mods == Alt then -- check if all are collapsed
                                local All_Collapsed
                                for i = 0, Sel_Track_FX_Count - 1, 1 do
                                    if not FX[FXGUID[i]].Collapse then All_Collapsed = false end
                                end
                                if All_Collapsed == false then
                                    for i = 0, Sel_Track_FX_Count - 1, 1 do
                                        FX[FXGUID[i]].Collapse = true
                                    end
                                else -- if all is collapsed
                                    for i = 0, Sel_Track_FX_Count - 1, 1 do
                                        FX[FXGUID[i]].Collapse = false
                                        FX.WidthCollapse[FXGUID[i]] = nil
                                    end
                                    BlinkFX = FX_Idx
                                end
                            elseif r.ImGui_IsItemActive(ctx) then
                                DraggingFX_L_Pos = r.ImGui_GetCursorScreenPos(ctx) + 10
                                if r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_AcceptNoDrawDefaultRect()) then
                                    --DragFX_ID = FX_Idx
                                    r.ImGui_SetDragDropPayload(ctx, 'BS_Drag', FX_Idx)
                                    r.ImGui_EndDragDropSource(ctx)

                                    DragDroppingFX = true
                                    if IsAnyMouseDown == false then DragDroppingFX = false end
                                end

                                --HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L,T,R,B,h,w, H_OutlineSc, V_OutlineSc,'GetItemRect',WDL )
                            end
                            SL(nil, 0)
                            r.gmem_attach('FXD_BandSplit')




                            --r.gmem_write(1,0) --[[1 is MouseR Click Position]]
                            --r.gmem_write(2,0)--[[tells if user R-Click BETWEEN a band]]
                            --r.gmem_write(3,0)--[[tells if user R-Click ON a band]]


                            local function f_trafo(freq)
                                return math.exp((1 - freq) * math.log(20 / 22050))
                            end
                            FX[FxGUID].Cross = FX[FxGUID].Cross or {}
                            local Cuts = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 0)
                            FX[FxGUID].Cross.Cuts = Cuts
                            WinL, WinT = r.ImGui_GetCursorScreenPos(ctx)
                            H, WinR = 220, WinL + Width - BtnWidth - SpcW


                            if FX[FxGUID].Collapse then
                                local L, T = WinL - BtnWidth, WinT
                                r.ImGui_DrawList_AddRectFilled(WDL, L, T + 2, L + 25, T, 0x999999aa)
                                r.ImGui_DrawList_AddRectFilled(WDL, L, T + 4, L + 25, T + 6, 0x999999aa)
                                r.ImGui_DrawList_AddRect(WDL, L, T + 2, L + 25, T + 218, 0x99999977)
                            else
                                for i = 1, Cuts * 4, 1 do ----------[Repeat for Bands]----------
                                    local TxtClr = getClr(r.ImGui_Col_Text())
                                    FX[FxGUID].Cross[i] = FX[FxGUID].Cross[i] or {}
                                    local X = FX[FxGUID].Cross[i]
                                    -- r.gmem_attach('FXD_BandSplit')
                                    local WDL = r.ImGui_GetWindowDrawList(ctx)
                                    local BsID = BsID or 0

                                    X.Val = r.gmem_read(BsID + i)
                                    X.NxtVal = r.gmem_read(BsID + i + 1)
                                    X.Pos = SetMinMax(WinT + H - H * X.Val, WinT, WinT + H)


                                    --FX[FxGUID].Cross[i].Val = r.TrackFX_GetParamNormalized(LT_Track,FX_Idx, i)

                                    local Cross_Pos = SetMinMax(WinT + H - H * X.Val, WinT, WinT + H)
                                    local NxtCrossPos = SetMinMax(WinT + H - H * X.NxtVal, WinT, WinT + H)


                                    if --[[Hovering over a band]] r.ImGui_IsMouseHoveringRect(ctx, WinL, Cross_Pos - 3, WinR, Cross_Pos + 3) then
                                        FX[FxGUID].Cross.HoveringBand = i
                                        FX[FxGUID].Cross.HoveringBandPos = Cross_Pos

                                        if IsLBtnClicked then
                                            table.insert(Sel_Cross, i)
                                            Sel_Cross.FxID = FxGUID
                                        elseif IsRBtnClicked then
                                            --[[ if Cuts * 4 == i then  -- if deleting the top band
                                                r.TrackFX_SetParamNormalized(LT_Track,FX_Idx, 0, math.max(Cuts-0.25,0)) --simply delete top band only, leave others untouched.
                                            else ]]
                                            --delete band
                                            local Rpt = Cuts * 4 - i
                                            local Bd = i + 1
                                            if FX[FxGUID].Sel_Band == i then FX[FxGUID].Sel_Band = nil end

                                            local NxtBd_V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, Bd)
                                            local _, Name = r.TrackFX_GetParamName(LT_Track, FX_Idx, Bd)
                                            r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 0, math.max(Cuts - 0.25, 0)) -- Delete Band
                                            for T = 1, Rpt, 1 do
                                                local NxtBd_V = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i + T)

                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i - 1 + T, NxtBd_V) --adjust band Freq
                                            end
                                            for I, v in ipairs(FX[FxGUID].FXsInBS) do
                                                if FX[v].InWhichBand >= i then
                                                    FX[v].InWhichBand = FX[v].InWhichBand - 1

                                                    local Fx = tablefind(FXGUID, v)
                                                    --sets input channel
                                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 0, 0,
                                                        2 ^ ((FX[v].InWhichBand + 1) * 2 - 2), 0)
                                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 0, 1,
                                                        2 ^ ((FX[v].InWhichBand + 1) * 2 - 1), 0)
                                                    --sets Output +1
                                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 1, 0,
                                                        2 ^ ((FX[v].InWhichBand + 1) * 2 - 2), 0)
                                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 1, 1,
                                                        2 ^ ((FX[v].InWhichBand + 1) * 2 - 1), 0)
                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                        'P_EXT: FX is in which Band' .. v, FX[v].InWhichBand, true)
                                                end
                                            end
                                        end
                                        --[[ if not IsLBtnHeld then
                                            r.ImGui_SetNextWindowPos(ctx,WinR, FX[FxGUID].Cross[i].Pos -14)
                                            r.ImGui_BeginTooltip(ctx)
                                            r.ImGui_Text(ctx, roundUp(r.gmem_read(BsID+4+i),1)..' Hz')
                                            r.ImGui_EndTooltip(ctx)
                                        end  ]]
                                    end

                                    BD1 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 1)
                                    BD2 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 2)
                                    BD3 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 3)
                                    BD4 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 4)
                                    --ttp('BD1='..BD1..'\nBD2='..BD2..'\nBD3='..BD3..'\nBD4='..BD4)
                                    if --[[Mouse is between bands]] r.ImGui_IsMouseHoveringRect(ctx, WinL, X.Pos, WinR, NxtCrossPos) then
                                        if Payload_Type == 'FX_Drag' then

                                        end
                                    end



                                    if r.ImGui_IsMouseHoveringRect(ctx, WinL, WinT, WinR, WinT + H) and IsRBtnClicked then

                                    end

                                    if Sel_Cross[1] == i and Sel_Cross.FxID == FxGUID then
                                        if IsLBtnHeld then
                                            FX[FxGUID].Cross.DraggingBand = i
                                            local PrmV = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i)
                                            DragDeltaX, DragDeltaY = r.ImGui_GetMouseDragDelta(ctx)
                                            if DragDeltaY > 0 or DragDeltaY < 0 then
                                                local B = Sel_Cross.TweakingBand
                                                if #Sel_Cross > 1 then
                                                    if DragDeltaY > 0 then -- if drag upward
                                                        B = math.min(Sel_Cross[1], Sel_Cross[2])
                                                        table.remove(Sel_Cross,
                                                            tablefind(Sel_Cross, math.max(Sel_Cross[1], Sel_Cross[2])))
                                                    else
                                                        B = math.max(Sel_Cross[1], Sel_Cross[2])
                                                        table.remove(Sel_Cross,
                                                            tablefind(Sel_Cross, math.min(Sel_Cross[1], Sel_Cross[2])))
                                                    end
                                                else
                                                    B = Sel_Cross[1]
                                                end
                                                local LowestV = 0.02
                                                --r.gmem_write(100, B)
                                                --r.gmem_write(101, -DragDeltaY*10)
                                                --if B==1 and B==i then  -- if B ==1
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, B,
                                                    PrmV - DragDeltaY / 250 --[[Val of moving Freq]])

                                                for i = 1, 4 - B, 1 do
                                                    if PrmV - DragDeltaY / 250 > r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, B + i) then
                                                        r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, B + i,
                                                            PrmV - DragDeltaY / 250 --[[Val of moving Freq]])
                                                    end
                                                end

                                                --local PrmV_New= r.TrackFX_GetParamNormalized(LT_Track,FX_Idx, i)
                                                --[[ local NextF = r.gmem_read(111+B)
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, B+1, SetMinMax( (NextF - PrmV_New) /(1-PrmV_New) ,LowestV,1) ) ]]

                                                --elseif B <4 and B >1 and B==i then --if B == 2~4

                                                --end

                                                --[[ if B <4 and B >0 and B==i then
                                                    local PrmV_New= r.TrackFX_GetParamNormalized(LT_Track,FX_Idx, i)
                                                    --local PrmV_NextB= r.TrackFX_GetParamNormalized(LT_Track,FX_Idx, i+1)
                                                    local ThisF = r.gmem_read(110+B)




                                                    local NextF = r.gmem_read(111+B)
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, B+1, SetMinMax( (NextF - PrmV_New) /(1-PrmV_New) ,LowestV,1) )
                                                end ]]
                                                --r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, MovingBand+2, r.gmem_read(112)--[[Val of moving Freq + 1]] )


                                                --r.TrackFX_SetParamNormalized(LT_Track,FX_Idx, i, math.max(PrmV-DragDeltaY/250,0.02))
                                                r.ImGui_ResetMouseDragDelta(ctx)
                                                --r.gmem_write(101,0)
                                            end
                                            if Sel_Cross[1] == i then
                                                r.ImGui_SetNextWindowPos(ctx, WinR, FX[FxGUID].Cross[i].Pos - 14)
                                                r.ImGui_BeginTooltip(ctx)
                                                r.ImGui_Text(ctx, roundUp(r.gmem_read(BsID + 4 + i), 1) .. ' Hz')
                                                r.ImGui_EndTooltip(ctx)
                                                --r.ImGui_DrawList_AddText(Glob.FDL, WinL, Cross_Pos, getClr(r.ImGui_Col_Text()) , roundUp(r.gmem_read(10+i),1)..' Hz')
                                            end
                                        else
                                            Sel_Cross = {} --r.gmem_write(100, 0)
                                        end
                                    else
                                    end


                                    --[[ -- Draw Bands
                                    r.ImGui_DrawList_AddLine(WDL, WinL, X.Pos , WinR, X.Pos, TxtClr )
                                    r.ImGui_DrawList_AddText(WDL, WinL, X.Pos, TxtClr , roundUp(r.gmem_read(BsID+4+i),1)) ]]
                                end


                                function DropFXintoBS(FxID, FxGUID_BS, Band, Pl, DropDest, DontMove) --Pl is payload    --!!!! Correct drop dest!!!!
                                    FX[FxID] = FX[FxID] or {}

                                    if FX.InLyr[FxID] then --- move fx out of Layer
                                        FX.InLyr[FXGUID[DragFX_ID]] = nil
                                        r.SetProjExtState(0, 'FX Devices',
                                            'FXLayer - ' .. 'is FX' .. FXGUID[DragFX_ID] .. 'in layer', '')
                                    end



                                    if FX[FxID].InWhichBand then
                                        table.remove(FX[FxGUID_BS].FXsInBS, tablefind(FX[FxGUID_BS].FXsInBS, FxID))
                                    end



                                    if TABinsertPos then
                                        table.insert(FX[FxGUID_BS].FXsInBS, TABinsertPos, FxID)
                                    else
                                        table.insert(FX[FxGUID_BS].FXsInBS, FxID)
                                    end

                                    FX[FxID].InWhichBand = Band

                                    if not DontMove then
                                        table.insert(MovFX.FromPos, Pl)
                                        if Pl > FX_Idx and not DropDest then DropDest = FX_Idx + 1 end



                                        local _, Nm = r.TrackFX_GetFXName(LT_Track, DropDest)


                                        table.insert(MovFX.ToPos, DropDest or FX_Idx)

                                        table.insert(MovFX.Lbl, 'Move FX into Band ' .. Band)
                                    end



                                    local function Set_In_Out(FX, Band, ChanL, ChanR)
                                        r.TrackFX_SetPinMappings(LT_Track, FX, 0, ChanL or 0, 2 ^ ((Band + 1) * 2 - 2), 0) -- inputs
                                        r.TrackFX_SetPinMappings(LT_Track, FX, 0, ChanR or 1, 2 ^ ((Band + 1) * 2 - 1), 0)

                                        r.TrackFX_SetPinMappings(LT_Track, FX, 1, ChanL or 0, 2 ^ ((Band + 1) * 2 - 2), 0) --outputs
                                        r.TrackFX_SetPinMappings(LT_Track, FX, 1, ChanR or 1, 2 ^ ((Band + 1) * 2 - 1), 0)
                                    end

                                    Set_In_Out(Pl, Band)

                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which BS' .. FxID, FxGUID_BS,
                                        true)
                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which Band' .. FxID, Band,
                                        true)



                                    --- account for fxs with analyzers
                                    local _, FX_Name = r.TrackFX_GetFXName(LT_Track, Pl)
                                    if FX_Name:find('Pro%-C 2') then
                                        --Set_In_Out(Pl+1, Band+1, 2,3)
                                        --r.TrackFX_SetPinMappings(LT_Track, Pl+1, 0, 2, 2^((Band+1)*2-2)*2, 0) -- inputs 3
                                        --[[ r.TrackFX_SetPinMappings(LT_Track, Pl+1, 0, 3, 2^((Band+1)*2-2)*2, 0) -- inputs 4 ]]
                                    end

                                    local IDinPost = tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID])
                                    if IDinPost then MoveFX_Out_Of_Post(IDinPost) end

                                    local IDinPre = tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID])
                                    if IDinPre then MoveFX_Out_Of_Pre(IDinPre) end
                                end

                                -- Count numbeer of FXs in bands
                                local FXCountForBand = {}
                                FX[FxGUID].FXCheckWait = (FX[FxGUID].FXCheckWait or 0) + 1
                                if FX[FxGUID].FXCheckWait > 10 then
                                    for i, v in ipairs(FX[FxGUID].FXsInBS) do
                                        if not tablefind(FXGUID, v) then
                                            table.remove(FX[FxGUID].FXsInBS, tablefind(FX[FxGUID].FXsInBS, v))
                                        end
                                    end
                                    FX[FxGUID].FXCheckWait = 0
                                end

                                for i, v in ipairs(FX[FxGUID].FXsInBS) do
                                    if FX[v].InWhichBand == 0 then
                                        FXCountForBand[0] = (FXCountForBand[0] or 0) + 1
                                    elseif FX[v].InWhichBand == 1 then
                                        FXCountForBand[1] = (FXCountForBand[1] or 0) + 1
                                    elseif FX[v].InWhichBand == 2 then
                                        FXCountForBand[2] = (FXCountForBand[2] or 0) + 1
                                    elseif FX[v].InWhichBand == 3 then
                                        FXCountForBand[3] = (FXCountForBand[3] or 0) + 1
                                    elseif FX[v].InWhichBand == 4 then
                                        FXCountForBand[4] = (FXCountForBand[4] or 0) + 1
                                    end
                                end

                                for i = 0, 5, 1 do FX[FxGUID].Cross[i] = FX[FxGUID].Cross[i] or {} end
                                for i = 0, Cuts * 4, 1 do ------- Rpt for Spaces between band splits
                                    local CrossPos, Nxt_CrossPos
                                    local Pl = tonumber(Payload)

                                    if i == 0 then
                                        CrossPos = WinT + H
                                    else
                                        CrossPos = FX[FxGUID].Cross[math.min(i, 4)]
                                            .Pos
                                    end
                                    if i == Cuts * 4 then
                                        Nxt_CrossPos = WinT
                                    else
                                        Nxt_CrossPos = FX[FxGUID].Cross[i + 1]
                                            .Pos
                                    end
                                    local HvrOnBand = r.ImGui_IsMouseHoveringRect(ctx, WinL, CrossPos - 3, WinR,
                                        CrossPos + 3)
                                    local HvrOnNxtBand = r.ImGui_IsMouseHoveringRect(ctx, WinL, Nxt_CrossPos - 3, WinR,
                                        Nxt_CrossPos + 3)

                                    if --[[Hovering over a band]] r.ImGui_IsMouseHoveringRect(ctx, WinL, Nxt_CrossPos, WinR, CrossPos) and not (HvrOnBand or HvrOnNxtBand) then
                                        local function Find_InsPos()
                                            local InsPos
                                            for I, v in ipairs(FX[FxGUID].FXsInBS) do
                                                if FX[v].InWhichBand == i then InsPos = tablefind(FXGUID, v) end
                                            end
                                            Pl = Pl or InsPos
                                            if not InsPos then
                                                InsPos = FX_Idx
                                            elseif Pl > FX_Idx then
                                                InsPos = InsPos or (FX_Idx)
                                            elseif Pl < FX_Idx then
                                                InsPos = (InsPos or (FX_Idx - 1)) - 1
                                            end
                                            return InsPos
                                        end

                                        if Payload_Type == 'FX_Drag' then --Drop fx into a band
                                            if FX[FXGUID[Pl]].InWhichBand ~= i then
                                                r.ImGui_DrawList_AddRectFilled(WDL, WinL, CrossPos, WinR, Nxt_CrossPos,
                                                    0xffffff66)
                                                if r.ImGui_IsMouseReleased(ctx, 0) then
                                                    local DropDest = FX_Idx
                                                    local InsPos = Find_InsPos()
                                                    DropFXintoBS(FXGUID[Pl], FxGUID, i, Pl, InsPos + 1)
                                                end
                                            end
                                        elseif Payload_Type == 'AddFX_Sexan' then
                                            r.ImGui_DrawList_AddRectFilled(WDL, WinL, CrossPos, WinR, Nxt_CrossPos,
                                                0xffffff66)

                                            if r.ImGui_IsMouseReleased(ctx, 0) then
                                                local InsPos = Find_InsPos()
                                                local rv, type, payload, is_preview, is_delivery = r
                                                    .ImGui_GetDragDropPayload(ctx)
                                                r.TrackFX_AddByName(LT_Track, payload, false, -1000 - InsPos - 1)
                                                local FXid = r.TrackFX_GetFXGUID(LT_Track, InsPos + 1)
                                                DropFXintoBS(FXid, FxGUID, i, InsPos, FX_Idx, 'DontMove')
                                            end
                                        end
                                        AnySplitBandHvred = true
                                        FX[FxGUID].PreviouslyMutedBand = FX[FxGUID].PreviouslyMutedBand or {}
                                        FX[FxGUID].PreviouslySolodBand = FX[FxGUID].PreviouslySolodBand or {}

                                        --Mute Band
                                        if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_M()) and Mods == 0 then
                                            local Solo = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 4 + 5 * i)
                                            if Solo == 0 then
                                                local OnOff = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 5 * i)
                                                local V
                                                if OnOff == 1 then V = 0 else V = 1 end
                                                r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 5 * i, V)
                                                FX[FxGUID].PreviouslyMutedBand = {}
                                            end
                                            --Solo Band
                                        elseif r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_S()) and Mods == 0 then
                                            local Mute = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 5 * i)
                                            if Mute == 1 then
                                                local OnOff = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 4 + 5 * i)
                                                local V
                                                if OnOff == 1 then V = 0 else V = 1 end
                                                r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 4 + 5 * i, V)
                                                FX[FxGUID].PreviouslySolodBand = {}
                                            end
                                        elseif r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_M()) and Mods == Shift then
                                            local AnyMutedBand

                                            for i = 0, Cuts * 4, 1 do
                                                local OnOff = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 5 * i)

                                                if OnOff == 0 then AnyMutedBand = true end
                                                if OnOff == 0 then table.insert(FX[FxGUID].PreviouslyMutedBand, i) end
                                                if tablefind(FX[FxGUID].PreviouslyMutedBand, i) and OnOff == 1 then
                                                    r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 5 * i, 0)
                                                else
                                                    r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 5 * i, 1)
                                                end
                                            end

                                            if not AnyMutedBand then FX[FxGUID].PreviouslyMutedBand = {} end
                                        elseif r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_S()) and Mods == Shift then
                                            local AnySolodBand

                                            for i = 0, Cuts * 4, 1 do
                                                local OnOff = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 4 + 5 * i)

                                                if OnOff == 1 then AnySolodBand = true end
                                                if OnOff == 1 then table.insert(FX[FxGUID].PreviouslySolodBand, i) end
                                                if tablefind(FX[FxGUID].PreviouslySolodBand, i) and OnOff == 0 then
                                                    r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 4 + 5 * i, 1)
                                                else
                                                    r.TrackFX_SetParamNormalized(LT_Track, JoinerID, 4 + 5 * i, 0)
                                                end
                                            end

                                            if not AnySolodBand then FX[FxGUID].PreviouslySolodBand = {} end
                                        end
                                        FX[FxGUID].PreviouslyMutedBand = FX[FxGUID].PreviouslyMutedBand or {}



                                        if IsLBtnClicked and (Mods == 0 or Mods == Apl) then
                                            FX[FxGUID].Sel_Band = i
                                            FX[FxGUID].StartCount = true
                                        elseif IsRBtnClicked and Cuts ~= 1 then
                                            local _, ClickPos = r.ImGui_GetMousePos(ctx, 1)
                                            local H = 213
                                            local Norm_V = (WinT - ClickPos + 3) / H + 1


                                            local X = FX[FxGUID].Cross

                                            local Seg -- determine which band it's clicked

                                            X[1].Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 1);
                                            X[2].Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 2);
                                            X[3].Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 3);
                                            X[4].Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, 4);

                                            if Norm_V < X[1].Val then
                                                Seg = 1
                                            elseif Norm_V > X[4].Val and Cuts == 0.75 then
                                                Seg = 5
                                            elseif Norm_V > X[1].Val and Norm_V < X[2].Val then
                                                Seg = 2
                                            elseif Norm_V > X[2].Val and Norm_V < X[3].Val then
                                                Seg = 3
                                            elseif Norm_V > X[3].Val and Norm_V < X[4].Val then
                                                Seg = 4
                                            end


                                            if Cuts == 0.75 then
                                                if Norm_V > X[3].Val then Seg = 5 end
                                            elseif Cuts == 0.5 then
                                                if Norm_V > X[2].Val then Seg = 5 end
                                            elseif Cuts == 0.25 then
                                                if Norm_V > X[1].Val then Seg = 5 end
                                            end





                                            if Seg == 5 then
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i + 1, Norm_V)
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 0, Cuts + 0.25)
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i + 1, Norm_V)
                                            elseif Seg < 5 then
                                                local BandFreq = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i + 1)
                                                local BandFreq2
                                                if Seg == 1 then
                                                    BandFreq2 = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i + 2)
                                                end

                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, 0, Cuts + 0.25)
                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i + 1, Norm_V)

                                                r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i + 2, BandFreq)

                                                if Seg == 1 then
                                                    r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, i + 3, BandFreq2)
                                                end


                                                --[[ for T=1, Cuts*4-Seg+1, 1 do
                                                end ]]
                                            end
                                        elseif IsLBtnClicked and Mods == Alt then
                                            if FXCountForBand[i] or 0 > 0 then
                                                FX[FxGUID].PromptDeleteBand = i
                                                local Modalw, Modalh = 270, 55
                                                r.ImGui_SetNextWindowPos(ctx, VP.x + VP.w / 2 - Modalw / 2,
                                                    VP.y + VP.h / 2 - Modalh / 2)
                                                r.ImGui_SetNextWindowSize(ctx, Modalw, Modalh)
                                                r.ImGui_OpenPopup(ctx, 'Delete Band' .. i .. '? ##' .. FxGUID)
                                            end
                                        elseif LBtn_MousdDownDuration > 0.06 and (Mods == 0 or Mods == Apl) and not DraggingFXs.SrcBand and FX[FxGUID].StartCount then
                                            --Drag FXs to different bands
                                            for I, v in ipairs(FX[FxGUID].FXsInBS) do
                                                if FX[v].InWhichBand == i then
                                                    table.insert(DraggingFXs, v)
                                                    table.insert(DraggingFXs_Idx, tablefind(FXGUID, v))
                                                end
                                            end
                                            DraggingFXs.SrcBand = i
                                            DraggingFXs.SrcFxID = FxGUID
                                        elseif DraggingFXs.SrcBand and DraggingFXs[1] and IsLBtnHeld or Payload_Type == 'FX_Drag' then
                                            FX[FxGUID].Sel_Band = i
                                        end



                                        if DraggingFXs[1] and DraggingFXs.SrcBand ~= i then
                                            HighlightSelectedItem(0xffffff25, 0xffffff66, 0, WinL, CrossPos - 1, WinR - 1,
                                                Nxt_CrossPos + 1, Nxt_CrossPos - CrossPos, WinR - WinL, 1, 1,
                                                NoGetItemRect, NoForeground, NOrounding)
                                            if not IsLBtnHeld and Mods == 0 then -- if Dropped FXs
                                                for I, v in ipairs(DraggingFXs) do
                                                    FX[v].InWhichBand = i
                                                    local Fx = tablefind(FXGUID, v)
                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                        'P_EXT: FX is in which Band' .. v, i, true)
                                                    --sets input channel
                                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 0, 0, 2 ^ ((i + 1) * 2 - 2), 0)
                                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 0, 1, 2 ^ ((i + 1) * 2 - 1), 0)
                                                    --sets Output +1
                                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 1, 0, 2 ^ ((i + 1) * 2 - 2), 0)
                                                    r.TrackFX_SetPinMappings(LT_Track, Fx, 1, 1, 2 ^ ((i + 1) * 2 - 1), 0)
                                                end
                                            elseif not IsLBtnHeld and Mods == Apl then
                                                local Ofs = 0
                                                for I, v in ipairs(DraggingFXs) do
                                                    local offset
                                                    local srcFX = DraggingFXs_Idx[I] + Ofs
                                                    local TrgFX = srcFX + #DraggingFXs
                                                    if not FXCountForBand[i] then -- if theres no fx in the band
                                                    elseif FXCountForBand[i] > 0 then
                                                        for FxInB, v in ipairs(FX[FxGUID].FXsInBS) do
                                                            if FX[v].InWhichBand == i and tablefind(FXGUID, v) then
                                                                offset =
                                                                    tablefind(FXGUID, v)
                                                            end
                                                        end
                                                        TrgFX = offset + I
                                                    end


                                                    if srcFX >= TrgFX then Ofs = I end


                                                    r.TrackFX_CopyToTrack(LT_Track, srcFX, LT_Track, TrgFX, false)
                                                    local ID = r.TrackFX_GetFXGUID(LT_Track, TrgFX)

                                                    if not tablefind(FX[FxGUID].FXsInBS, ID) then
                                                        table.insert(
                                                            FX[FxGUID].FXsInBS, ID)
                                                    end
                                                    FX[ID] = FX[ID] or {}
                                                    FX[ID].InWhichBand = i
                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                        'P_EXT: FX is in which Band' .. ID, i, true)
                                                    r.GetSetMediaTrackInfo_String(LT_Track,
                                                        'P_EXT: FX is in which BS' .. ID, FxGUID, true)


                                                    --sets input channel
                                                    r.TrackFX_SetPinMappings(LT_Track, TrgFX, 0, 0, 2 ^ ((i + 1) * 2 - 2),
                                                        0)
                                                    r.TrackFX_SetPinMappings(LT_Track, TrgFX, 0, 1, 2 ^ ((i + 1) * 2 - 1),
                                                        0)
                                                    --sets Output +1
                                                    r.TrackFX_SetPinMappings(LT_Track, TrgFX, 1, 0, 2 ^ ((i + 1) * 2 - 2),
                                                        0)
                                                    r.TrackFX_SetPinMappings(LT_Track, TrgFX, 1, 1, 2 ^ ((i + 1) * 2 - 1),
                                                        0)
                                                end


                                                --[[ for I, v in ipairs(DraggingFXs) do
                                                    local srcFX = tablefind(FXGUID, v)
                                                    r.TrackFX_CopyToTrack(LT_Track, srcFX, LT_Track, )
                                                end  ]]
                                            end
                                        end



                                        WDL = WDL or r.ImGui_GetWindowDrawList(ctx)
                                        -- Highligh Hovered Band
                                        if not IsLBtnHeld then
                                            r.ImGui_DrawList_AddRectFilled(WDL, WinL, Nxt_CrossPos, WinR, CrossPos,
                                                0xffffff19)
                                        end
                                    end
                                    if FX[FxGUID].Sel_Band == i then
                                        HighlightSelectedItem(0xffffff25, 0xffffff66, 0, WinL, CrossPos - 1, WinR - 1,
                                            Nxt_CrossPos + 1, Nxt_CrossPos - CrossPos, WinR - WinL, 1, 1, NoGetItemRect,
                                            NoForeground, NOrounding)
                                    end


                                    local Solo, Pwr
                                    if JoinerID then
                                        Pwr = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 5 * i)

                                        local Clr = Layer_Mute or CustomColorsDefault.Layer_Mute
                                        if Pwr == 0 then
                                            r.ImGui_DrawList_AddRectFilled(WDL, WinL, Nxt_CrossPos, WinR,
                                                CrossPos, Clr)
                                        end

                                        Solo = r.TrackFX_GetParamNormalized(LT_Track, JoinerID, 4 + 5 * i)
                                        local Clr = Layer_Solo or CustomColorsDefault.Layer_Solo
                                        if Solo == 1 then
                                            r.ImGui_DrawList_AddRectFilled(WDL, WinL, Nxt_CrossPos, WinR,
                                                CrossPos, Clr)
                                        end
                                    end
                                end

                                if r.ImGui_BeginPopupModal(ctx, 'Delete Band' .. (FX[FxGUID].PromptDeleteBand or '') .. '? ##' .. FxGUID, nil, r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_NoResize()) then
                                    r.ImGui_Text(ctx, 'Delete the FXs in band ' .. FX[FxGUID].PromptDeleteBand .. '?')
                                    if r.ImGui_Button(ctx, '(y) Yes') or r.ImGui_IsKeyPressed(ctx, 89) then
                                        r.Undo_BeginBlock()
                                        for i = 0, Sel_Track_FX_Count, 1 do
                                            if tablefind(FX[FxGUID].FXsInBS, FXGUID[i]) then
                                            end
                                        end
                                        local DelFX = {}
                                        for i, v in ipairs(FX[FxGUID].FXsInBS) do
                                            if FX[v].InWhichBand == FX[FxGUID].PromptDeleteBand then
                                                table.insert(DelFX, v)
                                                --delete FXs
                                            end
                                        end
                                        for i, v in ipairs(DelFX) do
                                            r.TrackFX_Delete(LT_Track, tablefind(FXGUID, v) - i + 1)
                                        end


                                        r.Undo_EndBlock('Delete all FXs in Band ' .. FX[FxGUID].PromptDeleteBand, 0)
                                        FX[FxGUID].PromptDeleteBand = nil
                                        r.ImGui_CloseCurrentPopup(ctx)
                                    end
                                    SL()
                                    if r.ImGui_Button(ctx, '(n) No') or r.ImGui_IsKeyPressed(ctx, 78) then
                                        r.ImGui_CloseCurrentPopup(ctx)
                                    end
                                    r.ImGui_EndPopup(ctx)
                                end






                                -- draw bands

                                for i = 1, Cuts * 4, 1 do
                                    local X = FX[FxGUID].Cross[i]
                                    if IsRBtnHeld then
                                        X.Val = r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, i);

                                        X.Pos = SetMinMax(WinT + H - H * X.Val, WinT, WinT + H)
                                    end
                                    local BsID = FX[FxGUID].BandSplitID
                                    local TxtClr = getClr(r.ImGui_Col_Text())

                                    r.ImGui_DrawList_AddLine(WDL, WinL, X.Pos, WinR, X.Pos, TxtClr)
                                    if FX[FxGUID].Cross.DraggingBand ~= i then
                                        r.ImGui_DrawList_AddText(WDL, WinL, X.Pos, TxtClr,
                                            roundUp(r.gmem_read(BsID + 4 + i), 1))
                                    end
                                    if FX[FxGUID].Cross.HoveringBand == i or FX[FxGUID].Cross.DraggingBand == i then
                                        if not FX[FxGUID].Cross.DraggingBand == i then
                                            r.ImGui_DrawList_AddText(WDL, WinL, X.Pos, TxtClr,
                                                roundUp(r.gmem_read(BsID + 4 + i), 1))
                                        end
                                        r.ImGui_DrawList_AddLine(WDL, WinL, X.Pos + 1, WinR, X.Pos, TxtClr)

                                        if not r.ImGui_IsMouseHoveringRect(ctx, WinL, FX[FxGUID].Cross.HoveringBandPos - 3, WinR, FX[FxGUID].Cross.HoveringBandPos + 3)
                                            or (FX[FxGUID].Cross.DraggingBand == i and not IsLBtnHeld) then
                                            FX[FxGUID].Cross.HoveringBandPos = 0
                                            FX[FxGUID].Cross.HoveringBand = nil
                                            FX[FxGUID].Cross.DraggingBand = nil
                                        end
                                    end
                                end

                                -- Display Number of FXs in Band
                                for i = 0, Cuts * 4, 1 do
                                    if FXCountForBand[i] or 0 > 0 then
                                        local This_B_Pos, nxt_X_Pos
                                        if i == 4 or (i == 3 and Cuts == 0.75) or (i == 2 and Cuts == 0.5) or (i == 1 and Cuts == 0.25) then
                                            nxt_X_Pos = WinT
                                            This_B_Pos = FX[FxGUID].Cross[i].Pos
                                        elseif i == 0 then
                                            This_B_Pos = WinT + H
                                            nxt_X_Pos = FX[FxGUID].Cross[1].Pos
                                        else
                                            nxt_X_Pos = FX[FxGUID].Cross[i + 1].Pos or 0
                                            This_B_Pos = FX[FxGUID].Cross[i].Pos
                                        end


                                        if This_B_Pos - nxt_X_Pos > 28 and not DraggingFXs[1] then
                                            r.ImGui_DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 14, WinL + 10,
                                                nxt_X_Pos + (This_B_Pos - nxt_X_Pos - 10) / 2, 0xffffff66,
                                                FXCountForBand[i] or '')
                                        elseif DraggingFXs[1] then
                                            if DraggingFXs.SrcBand == i then
                                                MsX, MsY = r.ImGui_GetMousePos(ctx)
                                                r.ImGui_DrawList_AddLine(Glob.FDL, MsX, MsY, WinL + 15,
                                                    nxt_X_Pos + (This_B_Pos - nxt_X_Pos - 10) / 2, 0xffffff99)
                                            else
                                                r.ImGui_DrawList_AddTextEx(WDL, Font_Andale_Mono_20_B, 14, WinL + 10,
                                                    nxt_X_Pos + (This_B_Pos - nxt_X_Pos - 10) / 2, 0xffffff66,
                                                    FXCountForBand[i] or '')
                                            end
                                        end
                                    end
                                end

                                -- Draw Background
                                r.ImGui_DrawList_AddRectFilled(WDL, WinL, Glob.WinT, WinR, Glob.WinB, 0xffffff33)

                                local Copy

                                if DraggingFXs[1] and FXCountForBand[DraggingFXs.SrcBand] then
                                    local MsX, MsY = r.ImGui_GetMousePos(ctx)
                                    if Mods == Apl then Copy = 'Copy' end
                                    r.ImGui_DrawList_AddTextEx(Glob.FDL, Font_Andale_Mono_20_B, 14, MsX + 20, MsY,
                                        0xffffffaa, (Copy or '') .. ' ' .. FXCountForBand[DraggingFXs.SrcBand] .. ' FXs')
                                end
                            end


                            if not IsLBtnHeld then FX[FxGUID].StartCount = nil end


                            r.ImGui_EndChild(ctx)
                        end

                        if not FX[FxGUID].Collapse then
                            local LastFX_XPos
                            local FrstFX
                            local ofs = 0



                            for FX_ID = 0, Sel_Track_FX_Count, 1 do
                                for i, v in ipairs(FX[FxGUID].FXsInBS) do
                                    local _, FxName = r.TrackFX_GetFXName(LT_Track, FX_ID)

                                    if FXGUID[FX_ID] == v and FX[FxGUID].Sel_Band == FX[v].InWhichBand then
                                        if FxName:find('FXD ReSpectrum') then ofs = ofs + 1 end

                                        if not FrstFX then
                                            SL(nil, 0)
                                            AddSpaceBtwnFXs(FX_ID - 1, 'SpcInBS', nil, nil, nil, FxGUID)
                                            FrstFX = true
                                        end
                                        --if i == 1 then  SL(nil,0)  AddSpaceBtwnFXs(FX_Idx,'SpcInBS',nil,nil,1, FxGUID) end
                                        SL(nil, 0)

                                        I = tablefind(FXGUID, v)
                                        if I then
                                            createFXWindow(I)
                                            SL(nil, 0)
                                            AddSpaceBtwnFXs(I - ofs, 'SpcInBS', nil, nil, nil, FxGUID)
                                            SL(nil, 0)
                                            --[[ if i == #FX[FxGUID].FXsInBS then  ]]
                                            LastFX_XPos = r.ImGui_GetCursorScreenPos(ctx)
                                        end
                                    end
                                end
                            end


                            if LastFX_XPos then
                                local Sel_B_Pos, NxtB_Pos, AddTopLine
                                local Cuts = FX[FxGUID].Cross.Cuts
                                FX[FxGUID].Sel_Band = FX[FxGUID].Sel_Band or 0
                                if FX[FxGUID].Sel_Band == 0 then
                                    Sel_B_Pos = WinT + H
                                else
                                    Sel_B_Pos = FX[FxGUID].Cross[FX[FxGUID].Sel_Band].Pos
                                end


                                if FX[FxGUID].Sel_Band == 4
                                    or (FX[FxGUID].Sel_Band == 3 and Cuts == 0.75)
                                    or (FX[FxGUID].Sel_Band == 2 and Cuts == 0.5)
                                    or (FX[FxGUID].Sel_Band == 1 and Cuts == 0.25)
                                then
                                    NxtB_Pos = WinT
                                    AddTopLine = true
                                else
                                    NxtB_Pos = FX[FxGUID].Cross[FX[FxGUID].Sel_Band + 1].Pos or 0
                                end

                                local Clr = getClr(r.ImGui_Col_Text())
                                WinT = Glob.WinT
                                H = Glob.Height or 0
                                WinR = WinR or 0
                                NxtB_Pos = NxtB_Pos or 0
                                WinL = WinL or 0
                                r.ImGui_DrawList_AddLine(WDL, WinR, WinT + H, LastFX_XPos, WinT + H, Clr)
                                r.ImGui_DrawList_AddLine(WDL, WinR, Sel_B_Pos, WinR, WinT + H, Clr)

                                r.ImGui_DrawList_AddLine(WDL, WinR, NxtB_Pos, WinR, WinT, Clr)
                                r.ImGui_DrawList_AddLine(WDL, WinR, WinT, LastFX_XPos, WinT, Clr)
                                r.ImGui_DrawList_AddLine(WDL, LastFX_XPos - 1, WinT, LastFX_XPos - 1, WinT + H, Clr)
                                if AddTopLine then r.ImGui_DrawList_AddLine(WDL, WinL, WinT, WinR, WinT, Clr) end
                                if FX[FxGUID].Sel_Band == 0 then
                                    r.ImGui_DrawList_AddLine(WDL, WinL, WinT + H, WinR,
                                        WinT + H, Clr)
                                end

                                if DraggingFX_L_Pos then
                                    local W = LastFX_XPos - DraggingFX_L_Pos
                                    HighlightSelectedItem(0xffffff22, 0xffffffff, -1, DraggingFX_L_Pos, WinT, LastFX_XPos,
                                        WinT + H, H, W, H_OutlineSc, V_OutlineSc, NoGetItemRect, WDL)
                                    if not IsLBtnHeld then DraggingFX_L_Pos = nil end
                                end
                            else
                                if DraggingFX_L_Pos then
                                    local W = Width - 10
                                    HighlightSelectedItem(0xffffff22, 0xffffffff, -1, DraggingFX_L_Pos, WinT,
                                        DraggingFX_L_Pos + W, WinT + H, H, W, H_OutlineSc, V_OutlineSc, NoGetItemRect,
                                        WDL)
                                    if not IsLBtnHeld then DraggingFX_L_Pos = nil end
                                end
                            end
                        end
                        if FX[FxGUID].DeleteBandSplitter then
                            if #FX[FxGUID].FXsInBS == 0 then
                                r.TrackFX_Delete(LT_Track, FX_Idx + 1)
                                r.TrackFX_Delete(LT_Track, FX_Idx)
                                FX[FxGUID].DeleteBandSplitter = nil
                            else
                                local Modalw, Modalh = 320, 55
                                r.ImGui_SetNextWindowPos(ctx, VP.x + VP.w / 2 - Modalw / 2, VP.y + VP.h / 2 - Modalh / 2)
                                r.ImGui_SetNextWindowSize(ctx, Modalw, Modalh)
                                r.ImGui_OpenPopup(ctx, 'Delete Band Splitter? ##' .. FxGUID)
                            end
                        end

                        if r.ImGui_BeginPopupModal(ctx, 'Delete Band Splitter? ##' .. FxGUID, nil, r.ImGui_WindowFlags_NoTitleBar()|r.ImGui_WindowFlags_NoResize()) then
                            r.ImGui_Text(ctx, 'Delete the FXs in band splitter altogether?')
                            if r.ImGui_Button(ctx, '(n) No') or r.ImGui_IsKeyPressed(ctx, 78) then
                                r.Undo_BeginBlock()
                                r.TrackFX_Delete(LT_Track, FX_Idx)
                                r.TrackFX_Delete(LT_Track, FX_Idx + #FX[FxGUID].FXsInBS)
                                for i = 0, Sel_Track_FX_Count, 1 do
                                    if tablefind(FX[FxGUID].FXsInBS, FXGUID[i]) then
                                        --sets input channel
                                        r.TrackFX_SetPinMappings(LT_Track, i, 0, 0, 1, 0)
                                        r.TrackFX_SetPinMappings(LT_Track, i, 0, 1, 2, 0)
                                        --sets Output
                                        r.TrackFX_SetPinMappings(LT_Track, i, 1, 0, 1, 0)
                                        r.TrackFX_SetPinMappings(LT_Track, i, 1, 1, 2, 0)

                                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which BS' .. FXGUID[i],
                                            '', true)
                                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which Band' .. FXGUID
                                            [i], '', true)
                                        FX[FXGUID[i]].InWhichBand = nil
                                    end
                                end
                                FX[FxGUID].FXsInBS = nil
                                r.ImGui_CloseCurrentPopup(ctx)
                                FX[FxGUID].DeleteBandSplitter = nil
                                r.Undo_EndBlock('Delete Band Split and put enclosed FXs back into channel one', 0)
                            end
                            SL()

                            if r.ImGui_Button(ctx, '(y) Yes') or r.ImGui_IsKeyPressed(ctx, 89) then
                                r.Undo_BeginBlock()
                                r.TrackFX_Delete(LT_Track, FX_Idx)
                                r.TrackFX_Delete(LT_Track, FX_Idx + #FX[FxGUID].FXsInBS)
                                local DelFX = {}
                                for i = 0, Sel_Track_FX_Count, 1 do
                                    if tablefind(FX[FxGUID].FXsInBS, FXGUID[i]) then
                                        table.insert(DelFX, FXGUID[i])
                                    end
                                end

                                for i, v in ipairs(DelFX) do
                                    FX[v].InWhichBand = nil
                                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which Band' .. v, '', true)
                                    r.TrackFX_Delete(LT_Track, tablefind(FXGUID, v) - i)
                                end


                                r.Undo_EndBlock('Delete Band Split and all enclosed FXs', 0)
                            end
                            SL()
                            if r.ImGui_Button(ctx, '(esc) Cancel') or r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Escape()) then
                                FX[FxGUID].DeleteBandSplitter = nil
                                r.ImGui_CloseCurrentPopup(ctx)
                            end
                            r.ImGui_EndPopup(ctx)
                        end
                    end --  for if FX_Name ~='JS: FXD (Mix)RackMixer'
                    r.ImGui_SameLine(ctx, nil, 0)






                    ------- Pre FX Chain --------------
                    local FXisInPreChain, offset = nil, 0
                    if MacroPos == 0 then offset = 1 end --else offset = 0
                    if Trk[TrkID].PreFX[1] then
                        if Trk[TrkID].PreFX[FX_Idx + 1 - offset] == FXGUID[FX_Idx] then
                            FXisInPreChain = true
                        end
                    end

                    if Trk[TrkID].PreFX[1] and not Trk[TrkID].PreFX_Hide and FX_Idx == #Trk[TrkID].PreFX - 1 + offset then
                        AddSpaceBtwnFXs(FX_Idx, 'End of PreFX', nil)
                    end

                    if FXisInPreChain then
                        if FX_Idx + 1 - offset == #Trk[TrkID].PreFX and not Trk[TrkID].PreFX_Hide then
                            local R, B = r.ImGui_GetItemRectMax(ctx)
                            r.ImGui_DrawList_AddRect(FX_Dvs_BgDL, Cx_LeftEdge, Cy_BeforeFXdevices, R, B,
                                r.ImGui_GetColor(ctx, r.ImGui_Col_Button()))
                            r.ImGui_DrawList_AddRectFilled(FX_Dvs_BgDL, Cx_LeftEdge, Cy_BeforeFXdevices, R, B, 0xcccccc10)
                        end
                    end
                    ------------------------------------------
                    if FX_Idx + 1 == RepeatTimeForWindows and not Trk[TrkID].PostFX[1] then -- add last space
                        AddSpaceBtwnFXs(FX_Idx + 1, nil, 'LastSpc')
                    elseif FX_Idx + 1 == RepeatTimeForWindows and Trk[TrkID].PostFX[1] then
                        AddSpaceBtwnFXs(Sel_Track_FX_Count - #Trk[TrkID].PostFX, nil, 'LastSpc', nil, nil, nil, 20)
                    end
                end --for repeat as many times as FX instances


                for i = 0, #FXGUID do
                    local FXid = r.TrackFX_GetFXGUID(LT_Track, i)

                    if FXid ~= FXGUID[i] then
                    end
                    --Detects if any FX is deleted
                    if FXid == nil then
                        --Deleted_FXGUID = FXGUID[i]

                        --DeleteAllParamOfFX(Deleted_FXGUID, TrkID)
                        FXGUID[i] = nil
                    else
                    end
                end

                if Sel_Track_FX_Count == 0 and DeletePrms == nil then --if it's the only fx
                    DeleteAllParamOfFX(FXGUID[0], TrkID, 0)
                    FXGUID[0] = nil
                    DeletePrms = true
                elseif Sel_Track_FX_Count ~= 0 then
                    DeletePrms = nil
                end


                if Sel_Track_FX_Count == 0 then AddSpaceBtwnFXs(0, false, true) end



                --when user switch selected track...
                if TrkID ~= TrkID_End and TrkID_End ~= nil and Sel_Track_FX_Count > 0 then
                    Sendgmems = nil
                    waitForGmem = 0

                    if Sendgmems == nil then
                        r.gmem_attach('ParamValues')
                        for P = 1, 100, 1 do
                            r.gmem_write(1000 + P, 0)
                        end
                        --[[ if Trk[TrkID].ModPrmInst then
                            for P=1, Trk[TrkID].ModPrmInst , 1 do
                                for m =1 , 8, 1 do

                                    local ParamMacroMod_Label= 'Param:'..P..'Macro:'..m


                                    if Prm.McroModAmt[ParamMacroMod_Label] ~= nil then
                                        r.gmem_write( 1000*m+P  ,Prm.McroModAmt[ParamMacroMod_Label])
                                    end

                                end
                            end
                        end ]]

                        for FX_Idx = 0, Sel_Track_FX_Count, 1 do
                            local FxGUID = r.TrackFX_GetFXGUID(LT_Track, FX_Idx)
                            if FxGUID then
                                for P, v in ipairs(FX[FxGUID]) do
                                    local FP = FX[FxGUID][P]
                                    if FP.WhichCC then
                                        for m = 1, 8, 1 do
                                            if FP.ModAMT[m] then r.gmem_write(1000 * m + P, FP.ModAMT[m]) end
                                        end
                                    end
                                end
                            end
                        end




                        r.gmem_write(2, PM.DIY_TrkID[TrkID] or 0)

                        Sendgmems = true
                    end
                end



                r.ImGui_EndChild(ctx)
                if HoverOnScrollItem then DisableScroll = true else DisableScroll = nil end

                if AnySplitBandHvred then
                    HintMessage =
                    'Mouse: Alt=Delete All FXs in Layer | Shift=Bypass FXs    Keys: M=mute band   Shift+M=Toggle all muted band | S=solo band  Shift+S=Toggle all solo\'d band'
                end
            end
            Pos_Devices_R, Pos_Devices_B = r.ImGui_GetItemRectMax(ctx)

            function MoveFX_Out_Of_Post(IDinPost)
                table.remove(Trk[TrkID].PostFX, IDinPost or tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]))
                for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '', true)
                end
            end

            function MoveFX_Out_Of_Pre(IDinPre)
                table.remove(Trk[TrkID].PreFX, IDinPre or tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID]))
                for i = 1, #Trk[TrkID].PreFX + 1, 1 do
                    r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PreFX ' .. i, Trk[TrkID].PreFX[i] or '', true)
                end
            end

            function RemoveFXfromBS()
                for FX_Idx = 0, Sel_Track_FX_Count - 1, 1 do -- check all fxs and see if it's a band splitter
                    if FX[FXGUID[FX_Idx]].FXsInBS then
                        local FxID = tablefind(FX[FXGUID[FX_Idx]].FXsInBS, FXGUID[DragFX_ID])
                        if FxID then
                            table.remove(FX[FXGUID[FX_Idx]].FXsInBS, FxID)
                            FX[FXGUID[DragFX_ID]].InWhichBand = nil
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which BS' .. FXGUID[DragFX_ID], '',
                                true)
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: FX is in which Band' .. FXGUID[DragFX_ID], '',
                                true)
                        end
                    end
                end
            end

            _, Payload_Type, Payload, is_preview, is_delivery = r.ImGui_GetDragDropPayload(ctx)
            Payload = tonumber(Payload)
            MouseAtRightEdge = r.ImGui_IsMouseHoveringRect(ctx, VP.X + VP.w - 25, VP.y, VP.X + VP.w, VP.y + VP.h)

            if (Payload_Type == 'FX_Drag' and MouseAtRightEdge) and not Trk[TrkID].PostFX[1] then
                r.ImGui_SameLine(ctx, nil, -5)
                dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                rv               = r.ImGui_Button(ctx, 'P\no\ns\nt\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
                HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                    'GetItemRect', WDL)
                if r.ImGui_BeginDragDropTarget(ctx) then -- if drop to post fx chain
                    Drop, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                    HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                        'GetItemRect', WDL)

                    if Drop and not tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]) then
                        table.insert(Trk[TrkID].PostFX, FXGUID[DragFX_ID])
                        r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. #Trk[TrkID].PostFX, FXGUID
                            [DragFX_ID], true)
                        r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, 999, true)

                        local IDinPre = tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID])
                        if IDinPre then MoveFX_Out_Of_Pre(IDinPre) end
                    end

                    if --[[Move FX out of layer]] Drop and FX.InLyr[FXGUID[DragFX_ID]] then
                        FX.InLyr[FXGUID[DragFX_ID]] = nil
                        r.SetProjExtState(0, 'FX Devices', 'FXLayer - ' .. 'is FX' .. FXGUID[DragFX_ID] .. 'in layer', '')
                    end

                    if Drop then
                        RemoveFXfromBS()
                        --Remove FX from BS if it's in BS
                    end



                    r.ImGui_EndDragDropTarget(ctx)
                else
                    begindrop = false
                end
            end


            PostFX_Width = math.min(
                (MakeSpaceForPostFX or 0) + ((Trk[TrkID].MakeSpcForPostFXchain or 0) + (PostFX_LastSpc or 0)) + 30,
                VP.w / 2)

            --ttp('PostFX_Width = '..PostFX_Width..'\n MakeSpaceForPostFX = '.. (MakeSpaceForPostFX or 0 )..'\n   MakeSpcForPostFXchain = '.. (Trk[TrkID].MakeSpcForPostFXchain or  0 ).. '\n  PostFX_LastSpc = '.. (PostFX_LastSpc or 0))


            if not Trk[TrkID].PostFX[1] then
                Trk[TrkID].MakeSpcForPostFXchain = 0
            end

            if Trk[TrkID].PostFX[1] then
                r.ImGui_SameLine(ctx, nil, 0)
                Line_L, Line_T = r.ImGui_GetCursorScreenPos(ctx)
                rv             = r.ImGui_Button(ctx,
                    (#Trk[TrkID].PostFX or '') .. '\n\n' .. 'P\no\ns\nt\n \nF\nX\n \nC\nh\na\ni\nn', 20, 220)
                if r.ImGui_IsItemClicked(ctx, 1) then
                    if Trk[TrkID].PostFX_Hide then Trk[TrkID].PostFX_Hide = false else Trk[TrkID].PostFX_Hide = true end
                end
                if r.ImGui_BeginDragDropTarget(ctx) then -- if drop to post fx chain Btn
                    if Payload_Type == 'FX_Drag' then
                        Drop, payload = r.ImGui_AcceptDragDropPayload(ctx, 'FX_Drag')
                        HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                            'GetItemRect', WDL)

                        if Drop and not tablefind(Trk[TrkID].PostFX, FXGUID[DragFX_ID]) then
                            --r.TrackFX_CopyToTrack(LT_Track, DragFX_ID, LT_Track, 999, true)
                            table.insert(Trk[TrkID].PostFX, FXGUID[DragFX_ID])
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. #Trk[TrkID].PostFX,
                                FXGUID[DragFX_ID], true)


                            local IDinPre = tablefind(Trk[TrkID].PreFX, FXGUID[DragFX_ID])
                            if IDinPre then MoveFX_Out_Of_Pre(IDinPre) end
                        end
                    elseif Payload_Type == 'AddFX_Sexan' then
                        dropped, payload = r.ImGui_AcceptDragDropPayload(ctx, 'AddFX_Sexan')
                        HighlightSelectedItem(0xffffff22, 0xffffffff, -1, L, T, R, B, h, w, H_OutlineSc, V_OutlineSc,
                            'GetItemRect', WDL)
                        if dropped then
                            r.TrackFX_AddByName(LT_Track, payload, false, -1000 - Sel_Track_FX_Count)
                            local FXid = r.TrackFX_GetFXGUID(LT_Track, Sel_Track_FX_Count)
                            local _, Name = r.TrackFX_GetFXName(LT_Track, Sel_Track_FX_Count)
                            table.insert(Trk[TrkID].PostFX, FXid)
                            r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. #Trk[TrkID].PostFX, FXid, true)
                        end
                    end

                    r.ImGui_EndDragDropTarget(ctx)
                end

                r.ImGui_SameLine(ctx, nil, 0)
                r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(), 0xffffff11)
                local PostFX_Extend_W = 0
                if PostFX_Width == VP.w / 2 then PostFX_Extend_W = 20 end
                if not Trk[TrkID].PostFX_Hide then
                    if r.ImGui_BeginChild(ctx, 'Post FX chain', PostFX_Width - PostFX_Extend_W, 220) then
                        local clr = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_Button())
                        r.ImGui_DrawList_AddLine(Glob.FDL, Line_L, Line_T - 1, Line_L + VP.w, Line_T - 1, clr)
                        r.ImGui_DrawList_AddLine(Glob.FDL, Line_L, Line_T + 220, Line_L + VP.w, Line_T + 220, clr)



                        Trk[TrkID].MakeSpcForPostFXchain = 0

                        if r.TrackFX_AddByName(LT_Track, 'FXD Macros', 0, 0) == -1 then offset = 0 else offset = 1 end

                        for FX_Idx, V in pairs(Trk[TrkID].PostFX) do
                            local I = --[[ tablefind(FXGUID, Trk[TrkID].PostFX[#Trk[TrkID].PostFX+1-FX_Idx])  ]]
                                tablefind(FXGUID, V)

                            local Spc
                            if FX_Idx == 1 and I then AddSpaceBtwnFXs(I - 1, 'SpcInPost', nil, nil, 1) end
                            if I then
                                createFXWindow(I)
                                r.ImGui_SameLine(ctx, nil, 0)

                                FX[FXGUID[I]].PostWin_SzX, _ = r.ImGui_GetItemRectSize(ctx)
                                Trk[TrkID].MakeSpcForPostFXchain = (Trk[TrkID].MakeSpcForPostFXchain or 0) +
                                    (FX.WidthCollapse[FXGUID[I]] or FX.Width[FXGUID[I]] or (DefaultWidth)) +
                                    10 -- 10 is space btwn fxs

                                if FX_Idx == #Trk[TrkID].PostFX then
                                    AddSpaceBtwnFXs(I, 'SpcInPost', nil, nil, #Trk[TrkID].PostFX + 1)
                                else
                                    AddSpaceBtwnFXs(I, 'SpcInPost', nil, nil, FX_Idx + 1)
                                end
                                if FX_Idx == #Trk[TrkID].PostFX and r.ImGui_IsItemHovered(ctx, r.ImGui_HoveredFlags_RectOnly()) then
                                    MouseAtRightEdge = true --[[ else MouseAtRightEdge = nil ]]
                                end
                            end
                        end




                        offset = nil


                        if InsertToPost_Src then
                            table.insert(Trk[TrkID].PostFX, InsertToPost_Dest, FXGUID[InsertToPost_Src])
                            for i = 1, #Trk[TrkID].PostFX + 1, 1 do
                                r.GetSetMediaTrackInfo_String(LT_Track, 'P_EXT: PostFX ' .. i, Trk[TrkID].PostFX[i] or '',
                                    true)
                            end
                            InsertToPost_Src = nil
                            InsertToPost_Dest = nil
                        end
                        r.ImGui_EndChild(ctx)
                    end
                else
                    Trk[TrkID].MakeSpcForPostFXchain = 0
                end


                for FX_Idx, V in pairs(Trk[TrkID].PostFX) do
                    local I = tablefind(FXGUID, V)
                    local P = Sel_Track_FX_Count - #Trk[TrkID].PostFX + (FX_Idx - 1)


                    if I ~= P then
                        r.Undo_BeginBlock()
                        if not MovFX.FromPos[1] then
                            table.insert(MovFX.FromPos, I)
                            table.insert(MovFX.ToPos, P)
                            table.insert(MovFX.Lbl, 'Move FX into Post-FX Chain')
                        end
                        --r.TrackFX_CopyToTrack(LT_Track, I, LT_Track, P, true)
                        r.Undo_EndBlock('Move FX out of Post-FX Chain', 0)
                    end
                end
                r.ImGui_PopStyleColor(ctx)
            end

            -- When Add or Delete Fx.....if  add fx or delete fx
            if Sel_Track_FX_Count ~= CompareFXCount then
                for i in ipairs(FX.Win_Name) do

                end
                if FX.Win_Name then
                    local rv, tab = FindStringInTable(FX.Win_Name, 'FX Devices Gain Reduction')
                    if tab then
                        for i, v in ipairs(tab) do
                            r.gmem_attach('CompReductionScope')
                            r.gmem_write(2001, v - 1)
                        end
                    end
                end

                CompareFXCount = Sel_Track_FX_Count
            end


            r.ImGui_PopStyleColor(ctx)
            --[[  r.ImGui_PopStyleColor(ctx)  --  For Menu Bar Color
                r.ImGui_PopStyleColor(ctx)  --  For WindowBg ]]

            r.ImGui_PopStyleVar(ctx) --(Border Size for all fx devices)
            r.ImGui_PopStyleVar(ctx) --StyleVar#1 (Child Frame for all FX Devices)

            r.ImGui_PopFont(ctx)
            --r.ImGui_PopStyleColor(ctx,Clr.poptimes)
            Track_Fetch_At_End = reaper.GetLastTouchedTrack()
            TrkID_End = r.GetTrackGUID(Track_Fetch_At_End)

            FirstLoop = false
            ProQ3.SpecWait = ProQ3.SpecWait + 1


            demo.PopStyle()

            --[[ HintPos = HintPost or r.ImGui_GetCursorPosY(ctx)
            r.ImGui_SetCursorPosY(ctx, HintPos) ]]
            if HintMessage then
                r.ImGui_Text(ctx, ' !')
                SL()
                MyText(HintMessage, Font_Andale_Mono_13, 0xffffff88)
            end
            if not IsLBtnHeld then
                DraggingFXs = {}
                DraggingFXs_Idx = {}
            end
        end -- end for if LT_Track ~= nil





        r.ImGui_SetNextWindowSize(ctx, 500, 440, r.ImGui_Cond_FirstUseEver())
        if LT_Track then FXCountEndLoop = r.TrackFX_GetCount(LT_Track) end
        r.ImGui_End(ctx)
    end --end for Visible


    if open then
        reaper.defer(loop)
    else --on script close
        NumOfTotalTracks = r.GetNumTracks()
        for T = 0, NumOfTotalTracks - 1, 1 do
            local track = r.GetTrack(0, T)
            local TrkID = r.GetTrackGUID(track)
            for i, v in ipairs(MacroNums) do
                if Trk[TrkID].Mod[i].Val ~= nil then
                    r.SetProjExtState(0, 'FX Devices', 'Macro' .. i .. 'Value of Track' .. TrkID, Trk[TrkID].Mod[i].Val)
                end
            end
        end
        r.ImGui_DestroyContext(ctx)
    end
    Track_Fetch_At_End = reaper.GetLastTouchedTrack()
    waitForGmem = waitForGmem + 1
end --end for loop

reaper.defer(loop)

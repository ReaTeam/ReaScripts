-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local lst = {
    [-1]= "Velocity",
    [0]="Bank Select MSB",
    [1]="Mod Wheel MSB",
    [2]="Breath MSB",
    [3]="",
    [4]="Foot Pedal MSB",
    [5]="Portamento MSB",
    [6]="Data Entry MSB",
    [7]="Volume MSB",
    [8]="Balance MSB",
    [9]="",
    [10]="Pan Position MSB",
    [11]="Expression MSB",
    [12]="Control 1 MSB",
    [13]="Control 2 MSB",
    [14]="",
    [15]="",
    [16]="GP Slider 1",
    [17]="GP Slider 2",
    [18]="GP Slider 3",
    [19]="GP Slider 4",
    [20]="",
    [21]="",
    [22]="",
    [23]="",
    [24]="",
    [25]="",
    [26]="",
    [27]="",
    [28]="",
    [29]="",
    [30]="",
    [31]="",
    [32]="Bank Select LSB",
    [33]="Mod Wheel LSB",
    [34]="Breath LSB",
    [35]="",
    [36]="Foot Pedal LSB",
    [37]="Portamento LSB",
    [38]="Data Entry LSB",
    [39]="Volume LSB",
    [40]="Balance LSB",
    [41]="",
    [42]="Pan Position LSB",
    [43]="Expression LSB",
    [44]="Control 1 LSB",
    [45]="Control 2 LSB",
    [46]="",
    [47]="",
    [48]="",
    [49]="",
    [50]="",
    [51]="",
    [52]="",
    [53]="",
    [54]="",
    [55]="",
    [56]="",
    [57]="",
    [58]="",
    [59]="",
    [60]="",
    [61]="",
    [62]="",
    [63]="",
    [64]="Hold Pedal (on/off)",
    [65]="Portamento (on/off)",
    [66]="Sostenuto (on/off)",
    [67]="Soft Pedal (on/off)",
    [68]="Legato Pedal (on/off)",
    [69]="Hold 2 Pedal (on/off)",
    [70]="Sound Variation",
    [71]="Timbre/Resonance",
    [72]="Sound Release",
    [73]="Sound Attack",
    [74]="Brightness/Cutoff Freq",
    [75]="Sound Control 6",
    [76]="Sound Control 7",
    [77]="Sound Control 8",
    [78]="Sound Control 9",
    [79]="Sound Control 10",
    [80]="GP Button 1 (on/off)",
    [81]="GP Button 2 (on/off)",
    [82]="GP Button 3 (on/off)",
    [83]="GP Button 4 (on/off)",
    [84]="",
    [85]="",
    [86]="",
    [87]="",
    [88]="",
    [89]="",
    [90]="",
    [91]="Effects Level",
    [92]="Tremolo Level",
    [93]="Chorus Level",
    [94]="Celeste Level",
    [95]="Phaser Level",
    [96]="Data Button Inc",
    [97]="Data Button Dec",
    [98]="Non-Reg Parm LSB",
    [99]="Non-Reg Parm MSB",
    [100]="Reg Parm LSB",
    [101]="Reg Parm MSB",
    [102]="",
    [103]="",
    [104]="",
    [105]="",
    [106]="",
    [107]="",
    [108]="",
    [109]="",
    [110]="",
    [111]="",
    [112]="",
    [113]="",
    [114]="",
    [115]="",
    [116]="",
    [117]="",
    [118]="",
    [119]="",
    [120]="",
    [121]="",
    [122]="",
    [123]="",
    [124]="",
    [125]="",
    [126]="",
    [127]="",
    [128]="Pitch Bend",
    [129]="Program",
    [130]="Channel Pressure",
    [131]="Bank Program/Select",
    [132]="Text Events",
    [133]="Sysex",
    [134]="00/32 Bank Select 14-bit",
    [135]="01/33 Mod Wheel 14-bit",
    [136]="02/34 Breath 14-bit",
    [137]="03/35 14-bit",
    [138]="04/36 Foot Pedal 14-bit",
    [139]="05/37 Portamento 14-bit",
    [140]="06/38 Data Entry 14-bit",
    [141]="07/39 Volume 14-bit",
    [142]="08/40 Balance 14-bit",
    [143]="09/41 14-bit",
    [144]="10/42 Pan Position 14-bit",
    [145]="11/43 Expression 14-bit",
    [146]="12/44 Control 1 14-bit",
    [147]="13/45 Control 2 14-bit",
    [148]="14/46 14-bit",
    [149]="15/47 14-bit",
    [150]="16/48 GP Slider 1 14-bit",
    [151]="17/49 GP Slider 2 14-bit",
    [152]="18/50 GP Slider 3 14-bit",
    [153]="19/51 GP Slider 4 14-bit",
    [154]="20/52 14-bit",
    [155]="21/53 14-bit",
    [156]="22/54 14-bit",
    [157]="23/55 14-bit",
    [158]="24/56 14-bit",
    [159]="25/57 14-bit",
    [160]="26/58 14-bit",
    [161]="27/59 14-bit",
    [162]="28/60 14-bit",
    [163]="29/61 14-bit",
    [164]="30/62 14-bit",
    [165]="31/63 14-bit",
    [166]="Notation Events",
    [167]="Off Velocity",
}

local function ccname(ccnum, mec)
    local e = lst[ccnum] or ""
    --if track then
        --if reaper.GetTrackMIDINoteNameEx(0, track, 128 + ccnum, 0) then
        --end
    --end
    if not e then
        return "CC " .. ccnum
    else
        local prefix = ""
        if (ccnum >= 0 and ccnum <= 9) then
            prefix = "CC 0" .. ccnum .. " "
        elseif ccnum >= 10 and ccnum <= 127 then
            prefix = "CC " .. ccnum .. " "
        else
            prefix = ""
        end

        if mec.track and (ccnum >= 0 and ccnum <= 127) then
            local chan      = reaper.MIDIEditor_GetSetting_int(mec.me, "default_note_chan")
            local username  = reaper.GetTrackMIDINoteNameEx(0, mec.track, 128 + ccnum, chan )
            if username then
                e = username
            end
        end

        return prefix .. e
    end
end

local function comboEntry(ccnum, mec)
  return  { num=ccnum, text=ccname(ccnum, mec)}
end

local function comboForMec(mec)
    local cb = {}

    cb[#cb+1] = comboEntry(-1,mec) -- Velocity
    cb[#cb+1] = comboEntry(167,mec) -- Off Velocity

    cb[#cb+1] = comboEntry(128,mec) -- Pitch
    cb[#cb+1] = comboEntry(129,mec) -- Program
    cb[#cb+1] = comboEntry(130,mec) -- CP
    cb[#cb+1] = comboEntry(131,mec) -- Bank
    cb[#cb+1] = comboEntry(132,mec) -- Text
    cb[#cb+1] = comboEntry(166,mec) -- Notation Events
    cb[#cb+1] = comboEntry(133,mec) -- Sysex

    for i=0,127,1 do
        cb[#cb+1] =  comboEntry(i,mec)
    end

    for i=134,165,1 do
        cb[#cb+1] =  comboEntry(i,mec)
    end

    return cb
end

return {
    comboEntry=comboEntry,
    comboForMec=comboForMec,
    hasPitchBendSnap=hasPitchBendSnap
}

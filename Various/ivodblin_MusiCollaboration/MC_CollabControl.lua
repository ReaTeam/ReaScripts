-- @noindex

function main()
--[[==================================================
Author: Ivo Düblin, Laufen, Switzerland
Do not copy or distribute without permission.
www.MuCol.ch
------------------------------------------------------
Script that controls:
- Copy of tracks from a main-project to instrument 
projects
- Create instrument project in subdirectory of MAIN-
project if it doesn't exist
- Create stems to be provided to all projects as 
backtracks
- Copy tracks from instrument projects to main for 
mixing purposes

Works on MS Windows and MacOS. Requires Cockos' Reaper.
------------------------------------------------------
Variable naming convention:

S = String
N = ID
MT = MediaTrack
B = Boolean
P = Function parameter 
I = Index (can be combined with the ones above)
C = Constant (combined also)
A = Array (combined also)
==================================================--]]

  --------------------------------------------------------
  --Constants
  --------------------------------------------------------
  CS_MCPPVer = "v1.2.1"

  --"Parameters" handed over via name of temporary track
  CS_MCFunc_TI = "MC_TI" --Toggle Indicator in track names
  CS_MCFunc_PP = "MC_PP" --Process current Project

  --Reaper commands
  CN_CmdCloseAllButCurrent = 41922
  CN_ReaCmdCopySelTr = 40210
  CN_ReaCmdPaste = 40058
  CN_ReaCmdCut = 40337
  CN_ReaCmdUnselAllTr = 40297
  CN_ReaCmdCloseCurProj = 40860
  CN_ReaCmdLastTouched = 40914
  CN_ReaCmdSelAllItemsInTr = 40421
  CN_ReaCmdCopyItems = 40698
  CN_ReaCmdMoveCursorToStartOfItems = 41173
  CN_ReaCmdDelSelTr = 40184
  CN_ReaCmdSaveCurProj = 40026
  CN_ReaCmdStemTr = 40892
  CN_ReaCmdUnselAll = 40297
  CN_ReaCmdNewProjTab = 40859
  CN_ReaCmdCloseProjTab = 40860

  --OS identifiers
  CS_WinOS = "Win"
  CS_MacOS = "OSX"
  CS_DirSep = "\\"
  CS_CurOS = DetermineOS()

  --Name pre- and suffixes
  CS_PrefixMC = "#MC-"
  CS_FileExtReaper = ".rpp"
  CS_FileExtReaperBak = "-bak"
  CS_SuffixStem = " - stem"
  CS_SuffixTmpStem = " - _tem"
  CS_SuffixTmp = "-TMP"
  CS_SuffixTmpl = "TEMPL"
  CS_NameSync = "SYNC"
  CS_NameRec = "RECORDINGS"
  CS_NameBt = "BACKTRACKS"
  CS_NameMix = "MIX"
  CS_NameMain = "MAIN"
  CS_McNameSync = CS_PrefixMC .. CS_NameSync
  CS_McNameRec = CS_PrefixMC .. CS_NameRec
  CS_McNameBt = CS_PrefixMC .. CS_NameBt
  CS_McNameMix = CS_PrefixMC .. CS_NameMix
  CS_McNameMain = CS_PrefixMC .. CS_NameMain
  

  --Name of projects of current instrument
  CS_NameCurInstr = GetNameCurInstr()
  CS_McNameCurInstr = CS_PrefixMC .. CS_NameCurInstr
  CS_NameFileBtProj = CS_McNameBt .. "-" .. CS_NameCurInstr .. CS_FileExtReaper
  CS_NameFileRecProj = CS_McNameRec .. "-" .. CS_NameCurInstr .. CS_FileExtReaper
  CS_NameFileMixProj = CS_McNameMix .. "-" .. CS_NameCurInstr .. CS_FileExtReaper
  CS_NameFileTmplProj = CS_PrefixMC .. CS_SuffixTmpl .. CS_FileExtReaper

  --Pathes
  CS_PathDirCurProj = reaper.GetProjectPath("")
  CS_PathFileCurProj = CS_PathDirCurProj .. CS_DirSep .. reaper.GetProjectName(0, "")

  CS_PathDirSync = CS_PathDirCurProj .. CS_DirSep .. CS_McNameSync 
  CS_PathDirSyncBt = CS_PathDirSync .. CS_DirSep .. CS_McNameBt
  CS_PathDirSyncBtInstr = CS_PathDirSyncBt .. CS_DirSep .. CS_McNameCurInstr
  CS_PathDirSyncRec = CS_PathDirSync .. CS_DirSep .. CS_McNameRec
  CS_PathDirSyncMix = CS_PathDirSync .. CS_DirSep .. CS_McNameMix

  CS_RelPathDirSyncBt = CS_McNameSync  .. CS_DirSep .. CS_McNameBt
  CS_RelPathDirSyncRec = CS_McNameSync  .. CS_DirSep .. CS_McNameRec
  CS_RelPathDirSyncMix = CS_McNameSync  .. CS_DirSep .. CS_McNameMix

  CS_PathFileTmplProj = CS_PathDirSync .. CS_DirSep .. CS_NameFileTmplProj
  CS_PathFileBtProj = CS_PathDirSyncBtInstr .. CS_DirSep .. CS_NameFileBtProj
  

  --Gets list of participating instruments
  CAS_Instr = {}

  --General names
  CS_IndicBt = " >B"
  CS_IndicTf = " >C"
  CS_IndicBtTf = " >B>C"

  CS_TrNameMix = "*MIX"
  CS_TrNameBckTr = "*BACKTRACKS"
  CS_TrNameBckTrTmp = CS_TrNameBckTr .. CS_SuffixTmp
  CS_TrNameRec = "*REC"

  --Message titles and standard phrases
  CS_MsgTitle = "MuCol - Collaboration Control " .. CS_MCPPVer
  CS_ErrorHeader = "SORRY, BUT ..." .. "\n\n"
  CS_ErrorFooter = "\n\n" .. "Please correct the problem and re-launch the script."
  CS_ProceedPhrase = "\n\n" .. "DO YOU WANT TO PROCEED?"

  --Confirmation/Completion
  CS_MsgConfirmProcMain = "This script will: " .. "\n\n" .. 
  "- Copy tracks under " .. '"' .. CS_TrNameRec .. '"' .. " and " .. '"' .. CS_TrNameMix .. '"' .. " marked with " .. '"' .. string.sub(CS_IndicTf, 2) .. '"' .. " to the respective instrument-projects" .. "\n\n" .. 
  "- Create new instrument-projects in case they do not yet exist" .. "\n\n" .. 
  "- Create backtracks for tracks under " .. '"' .. CS_TrNameRec .. '"' .. " and " .. '"' .. CS_TrNameMix .. '"' .. " marked with " .. '"' .. string.sub(CS_IndicBt, 2) .. '"' .. "\n\n" .. 
  "- Collect backtracks from all the instrument-projects" .. CS_ProceedPhrase
  
  CS_MsgConfirmProcInstr = "This script will: " .. "\n\n" .. 
  "- Add tracks from main-project to " .. '"' .. CS_TrNameRec .. '"' .. "\n\n" ..  
  "- Create backtracks for tracks under " .. '"' .. CS_TrNameRec .. '"' .. " marked with " .. '"' .. string.sub(CS_IndicBt, 2) .. '"' .. "\n\n" .. 
  "- Collect backtracks from all other projects" .. "\n\n" .. 
  "- Copy tracks under " .. '"' .. CS_TrNameRec .. '"' .. " marked with " .. '"' .. string.sub(CS_IndicTf, 2) .. '"' .. " to main-project for mixing purposes" .. CS_ProceedPhrase
  
  CS_MsgConfirmCopyMix = "Do you want to copy the tracks marked with " .. '"' .. string.sub(CS_IndicTf, 2) .. '"' .. " from the instrument projects to " .. '"' .. CS_TrNameMix .. '"' .. "?"
  CS_MsgComplProc = "The processing has been completed:"

  --Error messages
  CS_MsgErrInvalidProj = CS_ErrorHeader .. "The current project seems to be an invalid project and can not be processed!" .. CS_ErrorFooter 
  
  CS_MsgErrToggleTrWrongFld =  "Tracks outside the folders " .. '"' .. CS_TrNameRec .. '"' .. " and " .. '"' .. CS_TrNameMix .. '"' .. " can not be marked." .. "\n\n" .. "Indicators could not be added to the following tracks: " .. "\n"
  
  CS_MsgErrToggleTrSubProj = "Tracks containing subprojects or with child-tracks containing subprojects can not be copied to other projects - please stem those tracks first." .. "\n\n" .. "The indicator has been removed from the following tracks:" .. "\n"
  
  CS_MsgErrDplTr = CS_ErrorHeader .. "Amongst the tracks with the indicator " .. '"' .. string.sub(CS_IndicBt, 2) .. '"' .. " there duplicate track names which is not possible. The tracks in question are:" .. "\n\n"
  
  CS_MsgMoreThanOneProj = CS_ErrorHeader .. "Besides the current project there are other Reaper projects currently open. All except the current project will be closed."

  --Log-file
  CS_NameFileLog = CS_PrefixMC .. "Log.TXT"
  CS_PathFileLog = CS_PathDirCurProj .. CS_DirSep .. CS_NameFileLog
  
  
  --------------------------------------------------------
  --Test area
  --------------------------------------------------------
  CB_DebugToLog = true
  --CB_DebugToLog = false
  
  --Msg(CS_SuffixStem)
  --Msg(CS_SuffixTmpStem)
  --Msg(string.gsub("xyz - stem", CS_SuffixStem, CS_SuffixTmpStem))
  
  --do return end

  
  --------------------------------------------------------
  --Local variables
  --------------------------------------------------------
  local N_IdLastTr
  local N_NumOfInstr = 0

  local N_NumOfInstrTrCopied = 0
  local N_NumOfInstrCreated = 0
  local N_NumOfInstrTrCopied2 = 0
  local N_NumOfInstrCreated2 = 0
  local N_NumOfTrCopiedToMix = 0

  local N_NumOfBckTrCreated = 0
  local N_NumOfBckTrInstr = 0
  local N_NumOfBckTrStems = 0
  local N_NumOfInstrForMix = 0
  local N_NumOfCopiedMixTr = 0
  local S_DplTrRec, S_DplTrMix
  local B_MoreThanOneOpenProj = false

  local S_ToggleTrWrongFldTr, S_ToggleTrSubProjTr
  local S_ToggleTrErrMsg = ""
  local S_CurFunc

  --------------------------------------------------------
  --Check temporary track's name which controls
  --further execution of script
  --------------------------------------------------------
  N_IdLastTr = reaper.CountTracks(0) - 1
  S_NameTmpTr = GetTrName(N_IdLastTr)
  reaper.DeleteTrack(reaper.GetTrack(0, N_IdLastTr))

  --------------------------------------------------------
  --Toggle indicator
  --------------------------------------------------------
  if S_NameTmpTr == CS_MCFunc_TI then

    S_ToggleTrWrongFldTr, S_ToggleTrSubProjTr = ToggleIndicatorSelTr()

    if S_ToggleTrWrongFldTr ~= "" then
      S_ToggleTrErrMsg = CS_MsgErrToggleTrWrongFld .. S_ToggleTrWrongFldTr
    end

    if S_ToggleTrSubProjTr ~= "" then
      
      if S_ToggleTrErrMsg ~= "" then
        S_ToggleTrErrMsg = S_ToggleTrErrMsg .. "\n\n"
      end

      S_ToggleTrErrMsg = S_ToggleTrErrMsg .. CS_MsgErrToggleTrSubProj .. S_ToggleTrSubProjTr
    end

    if S_ToggleTrErrMsg ~= "" then
      reaper.ShowMessageBox(CS_ErrorHeader .. S_ToggleTrErrMsg .. CS_ErrorFooter, CS_MsgTitle, 0)
      do return end
    end
  
  elseif S_NameTmpTr == CS_MCFunc_PP then

    --Used for debugging
    HandleLogFile("CREATE")
    reaper.ClearConsole()
    S_CurFunc = "Main (MMuCol-Script "  .. CS_MCPPVer .. ")"
    DebugMsg(S_CurFunc)

    --Validate current project
    if CurProjIsSyncProj() == false or CS_NameCurInstr == "" then
      reaper.ShowMessageBox(CS_MsgErrInvalidProj, CS_MsgTitle, 0)
      do
        return
      end
    end

    --Check if more than one project is open,
    --true if under ProjID=1 no project is found
    N_RetVal, S_ProjName = reaper.EnumProjects(1, "")
    
    if N_RetVal ~= nil then
      
      --Set a flag, because closure action is done after 
      --confirmation of called functions
      B_MoreThanOneOpenProj = true
    end

    --Check for duplicate track names amongst tracks that are to be sent to
    --the backtracks as those would be dropped during the matching process
    S_DplTrRec = DuplicatesInFld_ByName(CS_TrNameRec)
    if S_DplTrRec ~= "" then
      CS_MsgErrDplTr = CS_MsgErrDplTr .. "Under " .. CS_TrNameRec .. ": " .. "\n" .. S_DplTrRec .. "\n\n"
    end

    S_DplTrMix = DuplicatesInFld_ByName(CS_TrNameMix)
    if S_DplTrMix ~= "" then
      CS_MsgErrDplTr = CS_MsgErrDplTr .. "Under " .. CS_TrNameMix .. ": " .. "\n" .. S_DplTrMix
    end

    if S_DplTrRec ~= "" or S_DplTrMix ~= "" then
      reaper.ShowMessageBox(CS_MsgErrDplTr .. CS_ErrorFooter, CS_MsgTitle, 0)
      do return end
    end

    if CS_NameCurInstr == CS_NameMain then
      --------------------------------------------------------
      --MAIN
      --------------------------------------------------------
      if reaper.ShowMessageBox(CS_MsgConfirmProcMain, CS_MsgTitle, 4) == 6 then
        
        if B_MoreThanOneOpenProj == true then

          if reaper.ShowMessageBox(CS_MsgMoreThanOneProj, CS_MsgTitle, 1) ~= 2 then
            --Close all but current project (if there are unsaved projects,
            --user is prompted to save them)
            reaper.Main_OnCommand(41922, 0)
          else
            do return end
          end
        end

        N_NumOfInstr = GetInstr()
        PrepareDirStruct(CS_NameMain)
        ManageProjTempl(CS_NameMain)

        --Copy recordings
        N_NumOfInstrTrCopied, N_NumOfInstrCreated = ProcessMainRecs(CS_TrNameRec)
        N_NumOfInstrTrCopied2, N_NumOfInstrCreated2 = ProcessMainRecs(CS_TrNameMix)
        N_NumOfInstrTrCopied = N_NumOfInstrTrCopied + N_NumOfInstrTrCopied2
        N_NumOfInstrCreated = N_NumOfInstrCreated + N_NumOfInstrCreated2

        N_NumOfInstr = GetInstr()

        --Manage backtracks - the BT-subdirectory for the current instrument is emptied first
        EmptyInstrBt()
        N_NumOfBckTrCreated = CreateBckTr(CS_TrNameRec)
        N_NumOfBckTrCreated = N_NumOfBckTrCreated + CreateBckTr(CS_TrNameMix)

        DistributeBckTrDirs()
        N_NumOfBckTrInstr, N_NumOfBckTrStems = CollectBckTr()

        --Collect tracks for mix
        if reaper.ShowMessageBox(CS_MsgConfirmCopyMix, CS_MsgTitle, 4) == 6 then
          N_NumOfInstrForMix, N_NumOfCopiedMixTr = CopyTrFromSyncMix()
        end

        reaper.ShowMessageBox(CS_MsgComplProc .. "\n\n" .. 
        "Tracks copied to instrument projects: " .. tostring(N_NumOfInstrTrCopied) .. "\n" .. 
        "New instrument projects created: " .. tostring(N_NumOfInstrCreated) .. "\n\n" .. 
        "Tracks transferred to backtracks: " .. tostring(N_NumOfBckTrCreated) .. "\n" .. 
        "Projects (incl. main) with backtracks: " .. tostring(N_NumOfBckTrInstr) .. "\n" .. 
        "Number of received backtracks: " .. tostring(N_NumOfBckTrStems) .. "\n\n" .. 
        "Instrument projects for mix: " .. tostring(N_NumOfInstrForMix) .. "\n" .. 
        "Number of tracks for mix: " .. tostring(N_NumOfCopiedMixTr), CS_MsgTitle, 0)
      end
    else
      --------------------------------------------------------
      --Instrument
      --------------------------------------------------------
      if reaper.ShowMessageBox(CS_MsgConfirmProcInstr, CS_MsgTitle, 4) == 6 then

        if B_MoreThanOneOpenProj == true then

          if reaper.ShowMessageBox(CS_MsgMoreThanOneProj, CS_MsgTitle, 1) ~= 2 then
            --Close all but current project (if there are unsaved projects,
            --user is prompted to save them)
            reaper.Main_OnCommand(41922, 0)
          else
            do return end
          end
        end

        N_NumOfInstrTrCopied = GetRecsFromSync()
        N_NumOfTrCopiedToMix = ProcessInstrRecs()

        EmptyInstrBt()
        N_NumOfBckTrCreated = CreateBckTr(CS_TrNameRec)
        N_NumOfBckTrInstr, N_NumOfBckTrStems = CollectBckTr()

        reaper.ShowMessageBox(CS_MsgComplProc .. "\n\n" .. 
        "Tracks copied from main-project: " .. tostring(N_NumOfInstrTrCopied) .. "\n\n" .. 
        "Tracks transferred to backtracks: " .. tostring(N_NumOfBckTrCreated) .. "\n" .. 
        "Projects (incl. main) with backtracks: " .. tostring(N_NumOfBckTrInstr) .. "\n" .. 
        "Number of received backtracks: " .. tostring(N_NumOfBckTrStems) .. "\n\n" .. 
        "Tracks copied to main-project for mix: " .. tostring(N_NumOfTrCopiedToMix), CS_MsgTitle, 0)
      end
    end
    DebugMsg("End of script!")
    HandleLogFile("CLOSE")
  end
  reaper.Main_OnCommand(CN_ReaCmdSaveCurProj, 0)
end


--[[==================================================
Conversion functions found here:
https://stackoverflow.com/questions/41855842/converting-utf-8-string-to-ascii-in-pure-lua
====================================================]]
local char, byte, pairs, floor = string.char, string.byte, pairs, math.floor
local table_insert, table_concat = table.insert, table.concat
local unpack = table.unpack or unpack

local function unicode_to_utf8(code)
   -- converts numeric UTF code (U+code) to UTF-8 string
   local t, h = {}, 128
   while code >= h do
      t[#t+1] = 128 + code%64
      code = floor(code/64)
      h = h > 32 and 32 or h/2
   end
   t[#t+1] = 256 - 2*h + code
   return char(unpack(t)):reverse()
end

local function utf8_to_unicode(utf8str, pos)
   -- pos = starting byte position inside input string (default 1)
   pos = pos or 1
   local code, size = utf8str:byte(pos), 1
   if code >= 0xC0 and code < 0xFE then
      local mask = 64
      code = code - 128
      repeat
         local next_byte = utf8str:byte(pos + size) or 0
         if next_byte >= 0x80 and next_byte < 0xC0 then
            code, size = (code - mask - 2) * 64 + next_byte, size + 1
         else
            code, size = utf8str:byte(pos), 1
         end
         mask = mask * 32
      until code < mask
   end
   -- returns code, number of bytes in this utf8 char
   return code, size
end

local map_1252_to_unicode = {
   [0x80] = 0x20AC,
   [0x81] = 0x81,
   [0x82] = 0x201A,
   [0x83] = 0x0192,
   [0x84] = 0x201E,
   [0x85] = 0x2026,
   [0x86] = 0x2020,
   [0x87] = 0x2021,
   [0x88] = 0x02C6,
   [0x89] = 0x2030,
   [0x8A] = 0x0160,
   [0x8B] = 0x2039,
   [0x8C] = 0x0152,
   [0x8D] = 0x8D,
   [0x8E] = 0x017D,
   [0x8F] = 0x8F,
   [0x90] = 0x90,
   [0x91] = 0x2018,
   [0x92] = 0x2019,
   [0x93] = 0x201C,
   [0x94] = 0x201D,
   [0x95] = 0x2022,
   [0x96] = 0x2013,
   [0x97] = 0x2014,
   [0x98] = 0x02DC,
   [0x99] = 0x2122,
   [0x9A] = 0x0161,
   [0x9B] = 0x203A,
   [0x9C] = 0x0153,
   [0x9D] = 0x9D,
   [0x9E] = 0x017E,
   [0x9F] = 0x0178,
   [0xA0] = 0x00A0,
   [0xA1] = 0x00A1,
   [0xA2] = 0x00A2,
   [0xA3] = 0x00A3,
   [0xA4] = 0x00A4,
   [0xA5] = 0x00A5,
   [0xA6] = 0x00A6,
   [0xA7] = 0x00A7,
   [0xA8] = 0x00A8,
   [0xA9] = 0x00A9,
   [0xAA] = 0x00AA,
   [0xAB] = 0x00AB,
   [0xAC] = 0x00AC,
   [0xAD] = 0x00AD,
   [0xAE] = 0x00AE,
   [0xAF] = 0x00AF,
   [0xB0] = 0x00B0,
   [0xB1] = 0x00B1,
   [0xB2] = 0x00B2,
   [0xB3] = 0x00B3,
   [0xB4] = 0x00B4,
   [0xB5] = 0x00B5,
   [0xB6] = 0x00B6,
   [0xB7] = 0x00B7,
   [0xB8] = 0x00B8,
   [0xB9] = 0x00B9,
   [0xBA] = 0x00BA,
   [0xBB] = 0x00BB,
   [0xBC] = 0x00BC,
   [0xBD] = 0x00BD,
   [0xBE] = 0x00BE,
   [0xBF] = 0x00BF,
   [0xC0] = 0x00C0,
   [0xC1] = 0x00C1,
   [0xC2] = 0x00C2,
   [0xC3] = 0x00C3,
   [0xC4] = 0x00C4,
   [0xC5] = 0x00C5,
   [0xC6] = 0x00C6,
   [0xC7] = 0x00C7,
   [0xC8] = 0x00C8,
   [0xC9] = 0x00C9,
   [0xCA] = 0x00CA,
   [0xCB] = 0x00CB,
   [0xCC] = 0x00CC,
   [0xCD] = 0x00CD,
   [0xCE] = 0x00CE,
   [0xCF] = 0x00CF,
   [0xD0] = 0x00D0,
   [0xD1] = 0x00D1,
   [0xD2] = 0x00D2,
   [0xD3] = 0x00D3,
   [0xD4] = 0x00D4,
   [0xD5] = 0x00D5,
   [0xD6] = 0x00D6,
   [0xD7] = 0x00D7,
   [0xD8] = 0x00D8,
   [0xD9] = 0x00D9,
   [0xDA] = 0x00DA,
   [0xDB] = 0x00DB,
   [0xDC] = 0x00DC,
   [0xDD] = 0x00DD,
   [0xDE] = 0x00DE,
   [0xDF] = 0x00DF,
   [0xE0] = 0x00E0,
   [0xE1] = 0x00E1,
   [0xE2] = 0x00E2,
   [0xE3] = 0x00E3,
   [0xE4] = 0x00E4,
   [0xE5] = 0x00E5,
   [0xE6] = 0x00E6,
   [0xE7] = 0x00E7,
   [0xE8] = 0x00E8,
   [0xE9] = 0x00E9,
   [0xEA] = 0x00EA,
   [0xEB] = 0x00EB,
   [0xEC] = 0x00EC,
   [0xED] = 0x00ED,
   [0xEE] = 0x00EE,
   [0xEF] = 0x00EF,
   [0xF0] = 0x00F0,
   [0xF1] = 0x00F1,
   [0xF2] = 0x00F2,
   [0xF3] = 0x00F3,
   [0xF4] = 0x00F4,
   [0xF5] = 0x00F5,
   [0xF6] = 0x00F6,
   [0xF7] = 0x00F7,
   [0xF8] = 0x00F8,
   [0xF9] = 0x00F9,
   [0xFA] = 0x00FA,
   [0xFB] = 0x00FB,
   [0xFC] = 0x00FC,
   [0xFD] = 0x00FD,
   [0xFE] = 0x00FE,
   [0xFF] = 0x00FF,
}
local map_unicode_to_1252 = {}
for code1252, code in pairs(map_1252_to_unicode) do
   map_unicode_to_1252[code] = code1252
end

function string.fromutf8(utf8str)
   local pos, result_1252 = 1, {}
   while pos <= #utf8str do
      local code, size = utf8_to_unicode(utf8str, pos)
      pos = pos + size
      code = code < 128 and code or map_unicode_to_1252[code] or ('?'):byte()
      table_insert(result_1252, char(code))
   end
   return table_concat(result_1252)
end

function string.toutf8(str1252)
   local result_utf8 = {}
   for pos = 1, #str1252 do
      local code = str1252:byte(pos)
      table_insert(result_utf8, unicode_to_utf8(map_1252_to_unicode[code] or code))
   end
   return table_concat(result_utf8)
end
--[[Conversion functions end]]


function CurProjIsSyncProj()
  local S_CurFunc = "CurProjIsSyncProj"
  DebugMsg(S_CurFunc)
--[[==================================================
Validate current project, return false if current 
project is a SYNC-project or from a SYNC-directory.
==================================================--]]
  local S_CurProjName = reaper.GetProjectName(0, "")
  local S_CurProjDir = ExtractNameDirOrFile(reaper.GetProjectPath(""))
  local B_IsSyncProj = true

  --Check if project is from a SYNC-directory
  if S_CurProjDir == CS_McNameSync or S_CurProjDir == CS_McNameRec or S_CurProjDir == CS_McNameBt then
    B_IsSyncProj = false
  end

  --Check if project is a SYNC-project
  if
    string.sub(S_CurProjName, 1, string.len(CS_McNameBt)) == CS_McNameBt or
      string.sub(S_CurProjName, 1, string.len(CS_McNameRec)) == CS_McNameRec
   then
    B_IsSyncProj = false
  end

  return B_IsSyncProj
end


function CollectBckTr()
  local S_CurFunc = "CollectBckTr"
  DebugMsg(S_CurFunc)
--[[==================================================
Executed from MAIN or instrument project:
- Collect stem tracks from all BT-projects of
all instruments residing in BT-directory of instrument
or MAIN
- Match content with existing backtracks
==================================================--]]
  local AS_Instr = {}
  local AS_TmpInstr = {}
  local N_StemTrCtr = 0

  local S_CurDir
  local N_DirCtr = 0
  local N_InstrCtr = 0
  local N_TrIDBtTmp, N_TrIDBt, N_TrCtr, N_StartTr, N_EndTr, S_TrName, B_RemBt
  local N_LoopCtr = 1
  
  local S_PathFileCurBt

  --If *BACKTRACKS don't exist, it is created
  N_TrIDBt = GetTrID(CS_TrNameBckTr, "")
  if N_TrIDBt == -1 then
    InsertNewTr_byID(CS_TrNameBckTr, reaper.CountTracks(0))
  end

  --If "BACKTRACKS-TMP exists, it is deleted and re-created
  N_TrIDBtTmp = GetTrID(CS_TrNameBckTrTmp, "")

  while N_TrIDBtTmp ~= -1 and N_LoopCtr < 100 do
    DebugMsg(S_CurFunc, "Delete tmp-backtracks: " .. tostring(N_TrIDBtTmp))
    DeleteTracks_byID(N_TrIDBtTmp, N_TrIDBtTmp)
    N_TrIDBtTmp = GetTrID(CS_TrNameBckTrTmp, "")
    N_LoopCtr = N_LoopCtr + 1
  end
  
  DebugMsg(S_CurFunc, "Recreate tmp-backtracks: " .. tostring(reaper.CountTracks(0)))
  InsertNewTr_byID(CS_TrNameBckTrTmp, reaper.CountTracks(0))
  N_TrIDBtTmp = GetTrID(CS_TrNameBckTrTmp, "")

  --Loop through BT-directory of current instrument or MAIN
  DebugMsg(S_CurFunc, "Read BT-directory: " .. CS_PathDirSyncBt)
  S_CurDir = reaper.EnumerateSubdirectories(CS_PathDirSyncBt, N_DirCtr)

  while S_CurDir ~= nil do
    
    --If current dir is an instrument directory
    if string.sub(S_CurDir, 1, string.len(CS_PrefixMC)) == CS_PrefixMC then
      S_CurInstr = string.sub(S_CurDir, string.len(CS_PrefixMC) + 1)

      DebugMsg(S_CurFunc, "Instrument being processed: " .. S_CurInstr)

      --Open instrument SYNC-project
      S_PathFileCurBt = CS_PathDirSyncBt .. CS_DirSep .. S_CurDir .. CS_DirSep .. CS_McNameBt .. "-" .. S_CurInstr .. CS_FileExtReaper
      
      if reaper.file_exists(S_PathFileCurBt) == true then
        DebugMsg(S_CurFunc, "Open BT-project: " .. S_PathFileCurBt)

        reaper.Main_OnCommand(CN_ReaCmdSaveCurProj, 0)
        OpenProj("", "", S_PathFileCurBt)

        --Copy all tracks
        if reaper.CountTracks(0) > 0 then
          SelTr_byIDs(0, reaper.CountTracks(0) - 1)
          reaper.Main_OnCommand(CN_ReaCmdCopySelTr, 0)

          --Go back to original project and paste tracks
          DebugMsg(S_CurFunc, "Open original project, paste tracks at last track under: " .. tostring(N_TrIDBtTmp))
          CloseCurProj()
          N_StartTr = PasteAtFldBtm_byID(N_TrIDBtTmp)
          N_EndTr = GetIDLastTrInFld_byID(N_TrIDBtTmp)

          --Go through the pasted tracks
          DebugMsg(S_CurFunc, "Go through pasted tracks: " .. tostring(N_StartTr) .. "-" .. tostring(N_EndTr))

          for N_TrCtr = N_StartTr, N_EndTr do

            --Rename folder tracks to include instrument name
            S_TrName = GetTrName(N_TrCtr)

            if string.sub(S_TrName, string.len(CS_SuffixTmp) * -1) == CS_SuffixTmp then
              N_InstrCtr = N_InstrCtr + 1
              AS_TmpInstr[N_InstrCtr] = S_CurInstr .. "-" .. S_TrName
              RenameTr_byID(N_TrCtr, AS_TmpInstr[N_InstrCtr])
              AS_Instr[N_InstrCtr] = string.sub(AS_TmpInstr[N_InstrCtr], 1, string.len(AS_TmpInstr[N_InstrCtr]) - string.len(CS_SuffixTmp))
            end
          end
        else
          CloseCurProj()
        end
      end
    end

    N_DirCtr = N_DirCtr + 1
    S_CurDir = reaper.EnumerateSubdirectories(CS_PathDirSyncBt, N_DirCtr)
  end

  N_TrIDBt = GetTrID(CS_TrNameBckTr, "")

  --Delete instrument-folders from BT that don't exist in BT-tmp
  DebugMsg(S_CurFunc, "Delete instrument folders from BT that don't exist in BT-tmp")

  N_StartTr = N_TrIDBt + 1
  N_EndTr = GetIDLastTrInFld_byID(N_TrIDBt)
  if N_TrIDBt < N_EndTr then

    --Loop through existing backtracks
    N_TrCtr = N_StartTr
    while N_TrCtr <= N_EndTr do
      S_TrName = GetTrName(N_TrCtr)

      --If current track is not an instrument/REC-folder
      if string.sub(S_TrName, string.len(CS_TrNameRec) * (-1)) == CS_TrNameRec or CS_SuffixStem and string.sub(S_TrName, string.len(CS_TrNameMix) * (-1)) == CS_TrNameMix then
        B_RemBt = true
        
        for N_InstrCtr = 1, #AS_Instr do
          if S_TrName == AS_Instr[N_InstrCtr] then
            B_RemBt = false
            break
          end
        end

        if B_RemBt == true then
          N_EndTr = N_EndTr - (GetIDLastTrInFld_byID(N_TrCtr) - N_TrCtr + 1)
          DeleteTracks_byID(N_TrCtr, N_TrCtr)
          N_TrCtr = N_TrCtr - 1
        end
      end
      N_TrCtr = N_TrCtr + 1
    end
  end

  --Match backtrack folders
  DebugMsg(S_CurFunc, "Match BT-tmp with BT")

  for N_InstrCtr = 1, #AS_TmpInstr do

    --Check if corresponing instrument exists under "BACKTRACKS
    if GetTrID(AS_Instr[N_InstrCtr], CS_TrNameBckTr) == -1 then
      InsertNewTrAtFldBtm_byID(AS_Instr[N_InstrCtr], N_TrIDBt)
    end

    MatchBckTrFolders(AS_TmpInstr[N_InstrCtr], AS_Instr[N_InstrCtr])
  end

  --Delete *BACKTRACKS-TMP
  DebugMsg(S_CurFunc, "Delete temporary backtracks: " .. tostring(N_TrIDBtTmp))
  N_TrIDBtTmp = GetTrID(CS_TrNameBckTrTmp, "")
  DeleteTracks_byID(N_TrIDBtTmp, N_TrIDBtTmp)

  --Copy media items to project folder of stem-tracks
  N_StartTr = N_TrIDBt + 1
  N_EndTr = GetIDLastTrInFld_byID(N_TrIDBt)
  for N_TrCtr = N_StartTr, N_EndTr do
    S_TrName = GetTrName(N_TrCtr)

    if string.sub(S_TrName, string.len(CS_SuffixStem) * -1) == CS_SuffixStem then
      ManageMediaItems_byID(N_TrCtr, "GETMEDIAFILES")
      N_StemTrCtr = N_StemTrCtr + 1
    end

  end

  return #AS_Instr, N_StemTrCtr
end


function DistributeBckTrDirs()
  local S_CurFunc = "DistributeBckTrDirs"
  DebugMsg(S_CurFunc)
--[[==================================================
Executed from MAIN only:
Distribute backtracks directories of all 
instruments (incl. MAIN) to the backtrack directories
of all instruments (incl. MAIN).
==================================================--]]
  local N_InstrCtr1, N_InstrCtr2

  --Delete all backtrack directories except
  --the ones created from the instrument (or MAIN)
  --projects. This way left overs from e.g. deleted
  --instrument projects are removed.
  --The removal of the directories only works reliably,
  --when the MAIN-project is closed first.
  reaper.Main_OnCommand(CN_ReaCmdSaveCurProj, 0)
  reaper.Main_OnCommand(CN_ReaCmdCloseProjTab, 0)
  EmptyBckTrDir(CS_NameMain)
  OpenProj(CS_NameMain, "", "")

  for N_InstrCtr1 = 1, #CAS_Instr do
    EmptyBckTrDir(CAS_Instr[N_InstrCtr1])
  end

  --Distribute backtrack instrument specific backtrack directories
  for N_InstrCtr1 = 1, #CAS_Instr do
    
    --MAIN to instrument(1)
    OSCmd("COPYDIR", CS_PathDirSyncBt .. CS_DirSep .. CS_McNameMain,
      CS_PathDirCurProj .. CS_DirSep .. CS_PrefixMC .. CAS_Instr[N_InstrCtr1] .. CS_DirSep .. CS_RelPathDirSyncBt .. CS_DirSep .. CS_McNameMain)

    --Instrument(1) to instrument(2)
    for N_InstrCtr2 = 1, #CAS_Instr do
      
      if N_InstrCtr1 ~= N_InstrCtr2 then
        OSCmd("COPYDIR", CS_PathDirCurProj .. CS_DirSep .. CS_PrefixMC .. CAS_Instr[N_InstrCtr1] .. CS_DirSep .. CS_RelPathDirSyncBt .. CS_DirSep .. CS_PrefixMC .. CAS_Instr[N_InstrCtr1],
          CS_PathDirCurProj .. CS_DirSep .. CS_PrefixMC .. CAS_Instr[N_InstrCtr2] .. CS_DirSep .. CS_RelPathDirSyncBt .. CS_DirSep .. CS_PrefixMC .. CAS_Instr[N_InstrCtr1])
      end

    end

    --Instrument(1) to MAIN
    OSCmd("COPYDIR", CS_PathDirCurProj .. CS_DirSep .. CS_PrefixMC .. CAS_Instr[N_InstrCtr1] .. CS_DirSep .. CS_RelPathDirSyncBt .. CS_DirSep .. CS_PrefixMC .. CAS_Instr[N_InstrCtr1],
      CS_PathDirSyncBt .. CS_DirSep .. CS_PrefixMC .. CAS_Instr[N_InstrCtr1])
  end

end


function EmptyBckTrDir(PS_CurInstr)
  local S_CurFunc = "EmptyBckTrDir(" .. PS_CurInstr .. ")"
  DebugMsg(S_CurFunc)
--[[==================================================
Delete all backtrack directories of all instruments
or MAIN except the one from the current instrument or
MAIN.
==================================================--]]
  local S_CurDir
  local N_DirCtr = 0
  local S_PathDirBtCurInstr

  if PS_CurInstr == CS_NameMain then
    S_PathDirBtCurInstr = CS_PathDirSyncBt
  else
    S_PathDirBtCurInstr = CS_PathDirCurProj .. CS_DirSep .. CS_PrefixMC .. PS_CurInstr .. CS_DirSep .. CS_RelPathDirSyncBt
  end

  S_CurDir = reaper.EnumerateSubdirectories(S_PathDirBtCurInstr, N_DirCtr)

  while S_CurDir ~= nil do
    if S_CurDir ~= CS_PrefixMC .. PS_CurInstr then
      DebugMsg(S_CurFunc, "Remove: " .. S_PathDirBtCurInstr .. CS_DirSep .. S_CurDir)
      --OSCmd("EMPTYDIR", S_PathDirBtCurInstr .. CS_DirSep .. S_CurDir)
      OSCmd("REMOVEDIR", S_PathDirBtCurInstr .. CS_DirSep .. S_CurDir)
    else
      N_DirCtr = N_DirCtr + 1
    end
    S_CurDir = reaper.EnumerateSubdirectories(S_PathDirBtCurInstr, N_DirCtr)
  end
end


function CreateBckTr(PS_SrcFld)
  local S_CurFunc = "CreateBckTr(" .. PS_SrcFld .. ")"
  DebugMsg(S_CurFunc)
--[[==================================================
- Copy the indicated tracks from source folder 
to the SYNC-BT-project
- The destination folder is added the instrument name
in case of instrument tracks
- Stem the copied tracks, copied tracks are deleted

Returns
- Number of stemmed backtracks
==================================================--]]
  local N_IDBckTr
  local S_DestFld, N_IDDestFld
  local N_NumOfBckTr = 0

  --Check if there are any indicated tracks in given folder
  N_NumOfBckTr = SelectIndicTr_byID(GetTrID(PS_SrcFld, ""), CS_IndicBt)

  if N_NumOfBckTr > 0 then
    
    --Copy selected tracks
    reaper.Main_OnCommand(CN_ReaCmdCopySelTr, 0)

    --Open backtracks-project of current instrument or MAIN
    reaper.Main_SaveProject(0)
    OpenProj("", "BT", "")

    --If folder analised is the REC-folder:
    --Delete all existing tracks
    --(if it is the MIX-folder
    --the respective tracks shall be added)
    if PS_SrcFld == CS_TrNameRec then
      DeleteTracks_byID(0, reaper.CountTracks(0) - 1)
    end
    
    --Create destination folder
    S_DestFld = PS_SrcFld .. CS_SuffixTmp
    InsertNewTr_byID(S_DestFld, reaper.CountTracks(0))

    --If it's the second source folder (i.e. *MIX) that is
    --beeing processed, the tracks have to be reordered
    if PS_SrcFld ~= CS_TrNameRec and reaper.CountTracks(0) > 1 then
      --Move new folder track to the top in order
      --to move it to the top level in hierarchy
      N_IDDestFld = GetTrID(S_DestFld, "")
      SelTr_byIDs(N_IDDestFld, N_IDDestFld)
      reaper.ReorderSelectedTracks(0, 1)
      --Move existing folder track to the top
      --to restore track order 
      SelTr_byIDs(1, 1)
      reaper.ReorderSelectedTracks(0, 1)
    end

    N_IDDestFld = GetTrID(S_DestFld, "")

    --Paste tracks
    PasteAtFldBtm_byID(N_IDDestFld)

    --Rename stem-tracks so that they are not 
    --accidently considered to be backtracks
    RenStemTr(S_DestFld, true)

    --Remove indicator and "Render tracks to multichannel post-fader stem tracks"
    SelectIndicTr_byID(N_IDDestFld, CS_IndicBt)
    RemoveIndicatorSelTr("")
    ShortenNameSelTr(34)

    DebugMsg(S_CurFunc, "Stem backtracks")
    reaper.Main_OnCommand(CN_ReaCmdStemTr, 0)

    DebugMsg(S_CurFunc, "Delete all but stem tracks from track: " .. tostring(N_IDDestFld))
    DelNonStemTrInFld_byID(N_IDDestFld)

    --Go back to original project file
    CloseCurProj()
  end

  if N_NumOfBckTr == -1 then
    return 0
  else
    return N_NumOfBckTr
  end
end


function DuplicatesInFld_ByName(PS_Fld)
  local S_CurFunc = "DuplicatesInFld_ByName(" .. PS_Fld .. ")"
  DebugMsg(S_CurFunc)
--[[==================================================
Check if there are douplicate instrument names in the
given folder. 
Returns instrument name if duplicate is found, 
otherwise returns empty string.
==================================================--]]
  local S_DuplicateName = ""

  local N_TrID
  local N_TrID2
  local S_TrName

  local N_IDFldTr
  local N_IDLstTr

  local S_CurInd

  --Get IDs of first/last track of given folder
  N_IDFldTr = GetTrID(PS_Fld, "")

  if N_IDFldTr ~= -1 then
    N_IDLstTr = GetIDLastTrInFld_byID(N_IDFldTr)

    --Loop through tracks in given folder
    for N_TrID = N_IDFldTr + 1, N_IDLstTr do
      S_TrName = GetTrName(N_TrID)
      S_CurInd = GetIndicator_byName(S_TrName)

      --If current track has a BT-indicator
      if S_CurInd == CS_IndicBt or S_CurInd == CS_IndicBtTf then
        --Remove indicator
        --S_TrName = string.gsub(S_TrName, GetIndicator_byName(S_TrName), "")

        --Inner loop - compare current name to all others
        for N_TrID2 = N_TrID + 1, N_IDLstTr do
          S_TrName2 = GetTrName(N_TrID2)
          S_TrName2 = string.gsub(S_TrName2, GetIndicator_byName(S_TrName2), "")

          --If a duplicate is found it is added to the return value
          if S_TrName == S_TrName2 then
            if S_DuplicateName ~= "" then

              --If track is not already part of the list
              if string.find(S_DuplicateName, EscapeStr(S_TrName)) == nil then
                S_DuplicateName = S_DuplicateName .. "\n" .. '"' .. S_TrName .. '"'
              end
            else
              S_DuplicateName = '"' .. S_TrName .. '"'
            end

            break
          end
        end
      end
    end
  end

  return S_DuplicateName
end


function DelNonStemTrInFld_byID(PN_FldID)
--[[==================================================
Delete tracks from a folder the name of which 
doesn't end with " - stem".
==================================================--]]
  local N_TrCtr = GetIDLastTrInFld_byID(PN_FldID)
  local N_NumStemTr 

  N_NumStemTr = SelectStemTr_byID(PN_FldID)
  reaper.Main_OnCommand(CN_ReaCmdCut, 0)
  SelTr_byIDs(PN_FldID, PN_FldID)
  reaper.Main_OnCommand(CN_ReaCmdPaste, 0)
  DeleteTracks_byID(PN_FldID + N_NumStemTr + 1, GetIDLastTrInFld_byID(PN_FldID))
end


function CopyTrFromSyncMix()
  local S_CurFunc = "CopyTrFromSyncMix"
  DebugMsg(S_CurFunc)
--[[==================================================
Used in MAIN-project:
Copy the tracks that have been made available in the 
SYNC-MIX-projects of all instruments and paste them
in the original (MAIN) project into and instrument
specific folder under *MIX.

Returns total number of copied tracks.
==================================================--]]
  local N_CtrInstr
  local N_TotNumOfTr = 0
  local N_NumOfTr = 0
  local N_NumOfInstr = 0
  local S_NameNewImportTr, S_NameNewInstrTr
  local N_IDNewImportTr, N_IDNewInstrTr
  local N_FirstTr, N_LastTr, N_TrID
  local N_IDMixTr = GetTrID(CS_TrNameMix, "")
  local S_CurMixProj

  --If *MIX don't exist, it is created
  if N_IDMixTr == -1 then
    InsertNewTr_byID(CS_TrNameMix, reaper.CountTracks(0))
    N_IDMixTr = GetTrID(CS_TrNameMix, "")
  end

  S_NameNewImportTr = "Tracks received " .. os.date("%c")
  N_IDNewImportTr = InsertNewTrAtFldBtm_byID(S_NameNewImportTr, N_IDMixTr)

  for N_CtrInstr = 1, #CAS_Instr do
    
    --Open SYNC-MIX-project for current instrument
    S_CurMixProj = CS_PathDirCurProj .. CS_DirSep .. CS_PrefixMC .. CAS_Instr[N_CtrInstr] .. CS_DirSep .. CS_RelPathDirSyncMix .. CS_DirSep .. CS_McNameMix .. "-" .. CAS_Instr[N_CtrInstr] .. CS_FileExtReaper
    DebugMsg(S_CurFunc, "Current SYNC-MIX-Project: " .. S_CurMixProj)

    if reaper.file_exists(S_CurMixProj) == true then
      reaper.Main_OnCommand(CN_ReaCmdSaveCurProj, 0)
      OpenProj(CAS_Instr[N_CtrInstr], "", S_CurMixProj)

      --Select tracks under MIX-folder
      N_NumOfTr = SelectAllTrInFld_byID(GetTrID(CS_TrNameMix, ""))

      if N_NumOfTr > 0 then
        N_NumOfInstr = N_NumOfInstr + 1
        N_TotNumOfTr = N_TotNumOfTr + N_NumOfTr
        reaper.Main_OnCommand(CN_ReaCmdCopySelTr, 0)

        --In original project: Create instrument-specific track
        CloseCurProj()
        S_NameNewInstrTr = "Instrument: " .. CAS_Instr[N_CtrInstr]
        N_IDNewInstrTr = InsertNewTrAtFldBtm_byID(S_NameNewInstrTr, N_IDNewImportTr)

        PasteAtFldBtm_byID(N_IDNewInstrTr)

        --Copy files of media items for all media in all pasted tracks
        N_FirstTr = N_IDNewInstrTr + 1
        N_LastTr = GetIDLastTrInFld_byID(N_IDNewInstrTr)

        for N_TrID = N_FirstTr, N_LastTr do
          ManageMediaItems_byID(N_TrID, "GETMEDIAFILES")
        end

      else
        CloseCurProj()
      end
    end
  end

  --Remove all indicators
  RemoveAllIndicatorsInFld_byID(N_IDNewImportTr)

  return N_NumOfInstr, N_TotNumOfTr
end


function GetRecsFromSync()
  local S_CurFunc = "GetRecsFromSync"
  DebugMsg(S_CurFunc)
--[[==================================================
Used in instrument-project:
Move all tracks in *REC of SYNC-projects (located
in versioned directories) of 
current instrument project and add them to
*REC-folder in instrument project.

Returns number of copied tracks.
==================================================--]]
  local N_IDFirstTr, N_IDLastTr, N_TrID, N_IDRec
  local N_NumOfRecTr
  local N_TotNumOfRecTr = 0
  local S_CurDir 
  local N_DirIdx = 0
  local S_PathFileCurRecFile

  --If *REC don't exist, it is created
  N_IDRec = GetTrID(CS_TrNameRec, "")

  if N_IDRec == -1 then
    InsertNewTr_byID(CS_TrNameRec, 0)
    N_IDRec = GetTrID(CS_TrNameRec, "")
  end

  --Go through subdirectories in SYNC-REC-directory
  S_CurDir = reaper.EnumerateSubdirectories(CS_PathDirSyncRec, N_DirIdx)

  while S_CurDir ~= nil do
    DebugMsg(S_CurFunc, "Processing directory: " .. S_CurDir)
    S_PathFileCurRecFile = CS_PathDirSyncRec .. CS_DirSep .. S_CurDir .. CS_DirSep .. CS_NameFileRecProj
    
    --If current directory is an SYNC-REC-subdirectory and it contains a REC-project
    if string.find(S_CurDir, EscapeStr(CS_McNameRec)) == 1 and reaper.file_exists(S_PathFileCurRecFile) == true then
      OpenProj("", "", S_PathFileCurRecFile)

      --Get tracks under *REC
      N_NumOfRecTr = SelectAllTrInFld_byID(N_IDRec)

      if N_NumOfRecTr > 0 then
        N_TotNumOfRecTr = N_TotNumOfRecTr + N_NumOfRecTr
        reaper.Main_OnCommand(CN_ReaCmdCopySelTr, 0)

        --Go back to instrument project and paste tracks
        CloseCurProj()
        N_IDFirstTr = PasteAtFldBtm_byID(N_IDRec)
        N_IDLastTr = GetIDLastTrInFld_byID(N_IDRec)

        --Copy files of media items
        for N_TrID = N_IDFirstTr, N_IDLastTr do
          ManageMediaItems_byID(N_TrID, "GETMEDIAFILES")
        end
      else
        CloseCurProj()
      end
    end

    --Delete SYNC-REC-subdirectory
    --OSCmd("EMPTYDIR", CS_PathDirSyncRec .. CS_DirSep .. S_CurDir)
    OSCmd("REMOVEDIR", CS_PathDirSyncRec .. CS_DirSep .. S_CurDir)
    
    S_CurDir = reaper.EnumerateSubdirectories(CS_PathDirSyncRec, N_DirIdx)
  end

  return N_TotNumOfRecTr
end


function ProcessMainRecs(PS_NameFld)
  local S_CurFunc = "ProcessMainRecs(" .. PS_NameFld .. ")"
  DebugMsg(S_CurFunc)
--[[==================================================
Used in MAIN-project:
- Loop through tracks under given folder (*REC)
- Copy indicated tracks to new SYNC-project of respective 
instrument track - i.e. to versioned directory
- If instrument project
does not exist, it is created.

Returns
- Number of copied instrument tracks
- Number of created instrument projects
==================================================--]]
  local N_IDFldTr = GetTrID(PS_NameFld, "")
  local N_IDFirstTr
  local N_IDLastTr
  local N_TrID, N_TrID2, N_IDRec
  local S_TrName
  local N_CtrTrCopied = 0
  local N_CtrInstProjCreated = 0
  local S_CurIndic

  --Check if folder track exists
  if N_IDFldTr ~= -1 then
    N_IDFirstTr = N_IDFldTr + 1
    N_IDLastTr = GetIDLastTrInFld_byID(N_IDFldTr)

    --Loop through tracks under given folder
    for N_TrID = N_IDFirstTr, N_IDLastTr do
      S_TrName = GetTrName(N_TrID)
      S_CurIndic = GetIndicator_byName(S_TrName)

      if S_CurIndic == CS_IndicTf or S_CurIndic == CS_IndicBtTf then
        --Remove indicator so that it is not copied
        RemoveIndicator_byID(N_TrID, "")

        --Remember track name (without indicators)
        S_TrName = GetTrName(N_TrID)

        --Copy indicated track
        SelTr_byIDs(N_TrID, N_TrID)
        reaper.Main_OnCommand(CN_ReaCmdCopySelTr, 0)

        --If indicator included Bt, Bt is restored
        if S_CurIndic == CS_IndicBtTf then
          AddIndicator_byID(N_TrID, CS_IndicBt)
        end

        if PrepareDirStruct(S_TrName) == true then
          ManageProjTempl(S_TrName)
          N_CtrInstProjCreated = N_CtrInstProjCreated + 1
        end

        --Open session specific SYNC-REC-project
        OpenProj("", "", PrepSyncRec(S_TrName))

        --If *REC-folder does not exists
        --it is inserted at the top of the project
        N_IDRec = GetTrID(CS_TrNameRec, "")

        if N_IDRec == -1 then
          InsertNewTr_byID(CS_TrNameRec, 0)
          N_IDRec = GetTrID(CS_TrNameRec, "")
        end

        --Paste tracks, rename top level track
        N_PastedTr = PasteAtFldBtm_byID(N_IDRec)
        RenameTr_byID(N_PastedTr, S_TrName .. " (" .. os.date("%x") .. ")")

        --Remove any indicators 
        RemoveAllIndicatorsInFld_byID(N_PastedTr)

        --Copy files of media items
        for N_TrID2 = N_PastedTr, reaper.CountTracks(0) - 1 do
          ManageMediaItems_byID(N_TrID2, "GETMEDIAFILES")
        end

        N_CtrTrCopied = N_CtrTrCopied + reaper.CountTracks(0) - N_PastedTr
        CloseCurProj()
      end
    end 
  end

  return N_CtrTrCopied, N_CtrInstProjCreated
end


function ProcessInstrRecs()
  local S_CurFunc = "ProcessInstrRecs"
  DebugMsg(S_CurFunc)
--[[==================================================
Used in instrument-project:
- Loop through tracks under *REC
- Copy indicated tracks to SYNC(MIX)-project of respective 
instrument

Returns
- Number of copied instrument tracks
==================================================--]]
  local N_IDRecFld
  local N_IDFirstTr
  local N_IDLastTr
  local N_TrID, N_IDMix
  local S_TrName
  local N_CtrTrCopied = 0
  local S_CurIndic
  local S_CurMixProj = CS_PathDirSyncMix .. CS_DirSep .. CS_NameFileMixProj

  --Emtpy SYNC-MIX-directory
  if DirExists(CS_PathDirSync, CS_McNameMix) == true then
    OSCmd("EMPTYDIR", CS_PathDirSyncMix)
  else
    OSCmd("MAKEDIR", CS_PathDirSyncMix)
  end

  --Check if folder track exists
  N_IDRecFld = GetTrID(CS_TrNameRec, "")
  if N_IDRecFld ~= -1 then
    
    if SelectIndicTr_byID(N_IDRecFld, CS_IndicTf) > 0 then
      reaper.Main_OnCommand(CN_ReaCmdCopySelTr, 0)

      --Copy project template
      OSCmd("COPYFILE", CS_PathFileTmplProj, S_CurMixProj)

      --Open instrument specific SYNC-MIX-project
      OpenProj("", "", S_CurMixProj)

      --Insert MIX-folder-track
      InsertNewTr_byID(CS_TrNameMix, 0)
      N_IDMix = GetTrID(CS_TrNameMix, "")

      --Paste tracks
      N_PastedTr = PasteAtFldBtm_byID(N_IDMix)

      --Copy files of media items
      for N_TrID = N_PastedTr, reaper.CountTracks(0) - 1 do
        ManageMediaItems_byID(N_TrID, "GETMEDIAFILES")
      end
      
      RemoveAllIndicatorsInFld_byID(N_IDMix)
      N_CtrTrCopied = N_CtrTrCopied + reaper.CountTracks(0) - 1
      CloseCurProj()
    end
  end
  return N_CtrTrCopied
end


function ManageMediaItems_byID(PN_TrID, PS_Func)
  local S_CurFunc = "ManageMediaItems_byID(" .. tostring(PN_TrID) .. ", " .. PS_Func .. ")"
  DebugMsg(S_CurFunc)

--[[==================================================
PS_Func:
"GETMEDIAFILES" - copy the media files to current directory 
and change references of the takes

"SENDMEDIAFILES" - media files are copied to the directory 
of the original project

"DELITEMS" - delete all media items

"CONTAINSSUB" - check if one of the media items is a 
subproject, if so true is returned
==================================================--]]
  local AS_MediaItems = {}
  local AS_MediaTake = {}
  local AS_MediaSrc = {}
  local AS_MediaFile = {}

  local N_CurMediaItem, N_CurMediaTake, N_CurMediaSrc, S_CurMediaFile 

  local S_DestPath
  local S_PCMSrcOLD, S_PCMSrcNEW
  
  local N_MediaCtr = 0
  local N_ItemCtr = 0
  local N_TakeIdx

  local N_RetVal = false

  --Select track and all media items
  SelTr_byIDs(PN_TrID, PN_TrID)
  reaper.Main_OnCommand(CN_ReaCmdSelAllItemsInTr, 0)

  --Get filenames of media source
  N_CurMediaItem = reaper.GetSelectedMediaItem(0, N_ItemCtr)

  while N_CurMediaItem ~= nil do
    for N_TakeIdx = 0,  reaper.GetMediaItemNumTakes(N_CurMediaItem) - 1 do
      N_CurMediaTake = reaper.GetTake(N_CurMediaItem, N_TakeIdx)

      if N_CurMediaTake ~= nil then
        N_CurMediaSrc = reaper.GetMediaItemTake_Source(N_CurMediaTake)
        S_CurMediaFile = reaper.GetMediaSourceFileName(N_CurMediaSrc, "")

        if S_CurMediaFile ~= "" then
          N_MediaCtr = N_MediaCtr + 1
          AS_MediaItems[N_MediaCtr] = N_CurMediaItem
          AS_MediaTake[N_MediaCtr] = N_CurMediaTake
          AS_MediaSrc[N_MediaCtr] = N_CurMediaSrc
          AS_MediaFile[N_MediaCtr] = S_CurMediaFile
        end
      end
      N_CurMediaTake = reaper.GetTake(N_CurMediaItem, N_TakeIdx)
    end

    N_ItemCtr = N_ItemCtr + 1
    N_CurMediaItem = reaper.GetSelectedMediaItem(0, N_ItemCtr)
  end

  DebugMsg(S_CurFunc, "Number of found media items: " .. tostring(N_MediaCtr))

  if PS_Func == "GETMEDIAFILES" then
    S_DestPath = reaper.GetProjectPath("")

    for N_MediaCtr = 1, #AS_MediaFile do
      
      --Copy media file
      OSCmd("COPYFILE", AS_MediaFile[N_MediaCtr], S_DestPath)

      --Change media source of each take
      S_PCMSrcOLD = reaper.GetMediaItemTake_Source(AS_MediaTake[N_MediaCtr])
      
      S_PCMSrcNEW = reaper.PCM_Source_CreateFromFile(S_DestPath .. CS_DirSep .. ExtractNameDirOrFile(AS_MediaFile[N_MediaCtr]))

      reaper.SetMediaItemTake_Source(AS_MediaTake[N_MediaCtr], S_PCMSrcNEW)

      reaper.PCM_Source_Destroy(S_PCMSrcOLD)
    end

  elseif PS_Func == "SENDMEDIAFILES" then
    S_DestPath = CS_PathDirCurProj

    for N_MediaCtr = 1, #AS_MediaFile do
      
      --Copy media file
      OSCmd("COPYFILE", AS_MediaFile[N_MediaCtr], S_DestPath)
    end

  elseif PS_Func == "DELITEMS" then
    for N_MediaCtr = 1, #AS_MediaFile do
      reaper.DeleteTrackMediaItem(reaper.GetTrack(0, PN_TrID), AS_MediaItems[N_MediaCtr])
    end

  elseif PS_Func == "CONTAINSSUB" then
    for N_MediaCtr = 1, #AS_MediaFile do
      if  string.sub(AS_MediaFile[N_MediaCtr], string.len(AS_MediaFile[N_MediaCtr]) - string.len(CS_FileExtReaper) + 1) == CS_FileExtReaper then
        N_RetVal = true
      end
    end
  
  end

  reaper.UpdateArrange()
  return N_RetVal
end


function PrepSyncRec(PS_Instr)
  local S_CurFunc = "PrepSyncRec(" .. PS_Instr .. ")"
  DebugMsg(S_CurFunc)
--[[==================================================
Called from MAIN:
- Determine free order number in SYNC-REC-directory
of given instrument (used to version SYNC-REC-subdirectories)
- Create new subdirectory and copy template

Returns path of new SYNC-REC-file.
==================================================--]]
  local S_PathDirCurSyncRec = CS_PathDirCurProj .. CS_DirSep .. CS_PrefixMC .. PS_Instr .. CS_DirSep .. CS_RelPathDirSyncRec
  local S_PrefixRecHyphen = CS_McNameRec .. "-"
  local S_PathFileInstrTmpl = CS_PathDirCurProj .. CS_DirSep .. CS_PrefixMC .. PS_Instr .. CS_DirSep .. CS_McNameSync .. CS_DirSep .. CS_NameFileTmplProj
  
  local S_CurDir
  local N_IdxFile = 0
  local S_PathDirNewSyncRec, S_PathFileNewSyncRec
  local A_CurOrderNum = {}
  local N_CtrOrderNum = 0
  local N_NewOrderNum = 0
  local B_FreOrderNumFound = false

  --Go through subdirectories in SYNC-REC-directory
  S_CurDir = reaper.EnumerateSubdirectories(S_PathDirCurSyncRec, N_IdxFile)

  while S_CurDir ~= nil do

    --If current directory is an SYNC-REC-subdirectory
    if string.find(S_CurDir, EscapeStr(S_PrefixRecHyphen)) == 1 then
    
      --Fill array of existing order numbers
      N_CtrOrderNum = N_CtrOrderNum + 1
      A_CurOrderNum[N_CtrOrderNum] = tonumber(string.sub(S_CurDir, string.len(S_PrefixRecHyphen) + 1))
    end

    N_IdxFile = N_IdxFile + 1
    S_CurDir = reaper.EnumerateSubdirectories(S_PathDirCurSyncRec, N_IdxFile)
  end

  --Find a free number
  if N_CtrOrderNum > 0 then
    while B_FreOrderNumFound == false do
      N_NewOrderNum = N_NewOrderNum + 1
      B_FreOrderNumFound = true

      for N_CtrOrderNum = 1, #A_CurOrderNum do
        if A_CurOrderNum[N_CtrOrderNum] == N_NewOrderNum then
          B_FreOrderNumFound = false
          break
        end
      end
    end
  else
    N_NewOrderNum = 1
  end

  --Create new subdirectory with found number and copy (template of ) SYNC-project
  S_PathDirNewSyncRec = S_PathDirCurSyncRec .. CS_DirSep .. S_PrefixRecHyphen .. tostring(N_NewOrderNum)
  S_PathFileNewSyncRec = S_PathDirNewSyncRec .. CS_DirSep .. S_PrefixRecHyphen .. PS_Instr .. CS_FileExtReaper
  OSCmd("MAKEDIR", S_PathDirNewSyncRec)
  OSCmd("COPYFILE", S_PathFileInstrTmpl, S_PathFileNewSyncRec)

  return S_PathFileNewSyncRec
end


function OpenProj(PS_Instr, PS_Sync, PS_Proj)
  local S_CurFunc = "OpenProj(" .. PS_Instr .. ", " .. PS_Sync .. ", " .. PS_Proj .. ")"
  DebugMsg(S_CurFunc)

--[[==================================================
Open project

Values for PS_Instr:
- "" (corresponds to current project)
- <instrument>
 
Values for PS_Sync:
- "BT": Corresponding backtrack-project
- "": The MAIN or instrument project itsself

Values for PS_Proj:
In case e.g. a REC-project is opened

Returns -1 if the searched file can not be found
==================================================--]]
  local S_PathProjFile = ""
  local N_RetVal = -1
  local S_NameFileInstrBt = CS_McNameBt .. "-" .. PS_Instr .. CS_FileExtReaper
  local S_MCNameInstr = CS_PrefixMC .. PS_Instr
  local N_EnumVal, S_ProjName

  if PS_Proj == "" then
  
    --BT of current project
    if PS_Instr == "" and PS_Sync == "BT" then
      S_PathProjFile = CS_PathFileBtProj
    
    --Project of given instrument (assuming current project is MAIN-project)
    elseif PS_Instr ~= CS_NameMain and PS_Sync == "" then
      S_PathProjFile = CS_PathDirCurProj .. CS_DirSep .. S_MCNameInstr .. CS_DirSep .. S_MCNameInstr .. CS_FileExtReaper
    
    elseif PS_Instr ~= CS_NameMain and PS_Sync == "BT" then 
      S_PathProjFile = CS_PathDirCurProj .. CS_DirSep .. S_MCNameInstr .. CS_DirSep .. CS_RelPathDirSyncBt .. CS_DirSep .. S_MCNameInstr .. CS_DirSep .. S_NameFileInstrBt
    elseif (PS_Instr == "" or PS_Instr == CS_NameMain) and PS_Sync == "" then
      S_PathProjFile = CS_PathFileCurProj
    end

  else
    S_PathProjFile = PS_Proj
  end

  if reaper.file_exists(S_PathProjFile) == true then
    N_RetVal = 0
    
    --Save current project, but only if there is one open
    N_EnumVal, S_ProjName = reaper.EnumProjects(1, "")
    if N_EnumVal ~= nil then
      reaper.Main_OnCommand(CN_ReaCmdSaveCurProj, 0)
    end

    reaper.Main_OnCommand(CN_ReaCmdNewProjTab, 0)
    reaper.Main_openProject(S_PathProjFile)
  end

  return N_RetVal
end


function CloseCurProj()
local S_CurFunc = "Close current project: " .. reaper.GetProjectName(0, "")
DebugMsg(S_CurFunc)
--[[==================================================
Close current project (go back to original project).
==================================================--]]
  local N_RetVal, S_ProjName

  N_RetVal, S_ProjName = reaper.EnumProjects(1, "")
      
  if N_RetVal ~= nil then
    reaper.Main_OnCommand(CN_ReaCmdSaveCurProj, 0)
    reaper.Main_OnCommand(CN_ReaCmdCloseProjTab, 0)
  end

end


function InstrProjExists(PS_NameInstr)
--[[==================================================
Check if project to given instrument name exists.

Returns
- true if it exists
- false if it doesn't
==================================================--]]
  local N_CtrInstr
  local S_NameInstrProj
  local B_ProjExists = false

  for N_CtrInstr = 1, #CAS_Instr do
    if S_NameInstrProj == PS_NameInstr then
      B_ProjExists = true
      break
    end
  end

  return B_ProjExists
end


function PrepareDirStruct(PS_NameInstr)
  local S_CurFunc = "PrepareDirStruct(" .. PS_NameInstr .. ")"
  DebugMsg(S_CurFunc)
--[[==================================================
Create all necessary SYNC-directories for given
instrument or MAIN (parameter is mandatory).

Returns true if directory for new instrument had
to be created.
==================================================--]]
  local B_InstrDirCreated = false
  local S_PathRoot
  local S_MCNameInstr = CS_PrefixMC .. PS_NameInstr

  --Determine SYNC-directories
  --Case: New instrument and its directories are to be created
  if CS_NameCurInstr == CS_NameMain and PS_NameInstr ~= CS_NameMain then
    S_PathRoot = CS_PathDirCurProj .. CS_DirSep .. S_MCNameInstr

    if DirExists(CS_PathDirCurProj, S_MCNameInstr) == false then
      OSCmd("MAKEDIR", S_PathRoot)
      B_InstrDirCreated = true
    end

  else
    S_PathRoot = CS_PathDirCurProj
  end      
    
  --Determine SYNC-directories
  S_PathDirSync = S_PathRoot .. CS_DirSep .. CS_McNameSync 
  S_PathDirBt = S_PathRoot .. CS_DirSep .. CS_RelPathDirSyncBt
  S_PathDirBtInstr = S_PathDirBt .. CS_DirSep .. S_MCNameInstr
  S_PathDirRec = S_PathRoot .. CS_DirSep .. CS_RelPathDirSyncRec
  S_PathDirMix = S_PathRoot .. CS_DirSep .. CS_RelPathDirSyncMix
  
  --Create Sync-directory
  if DirExists(S_PathRoot, CS_McNameSync ) == false then
    OSCmd("MAKEDIR", S_PathDirSync)
    --OSCmd("HIDE", S_PathDirSync)
  end

  --BT-directory
  if DirExists(S_PathDirSync, CS_McNameBt) == false then
    OSCmd("MAKEDIR", S_PathDirBt)
  end

  --Create instrument-subdirectory in BT
  if DirExists(S_PathDirBt, S_MCNameInstr) == false then
    OSCmd("MAKEDIR", S_PathDirBtInstr)
  end

  --REC-and MIX-directory only required for instruments, not for MAIN
  if PS_NameInstr ~= CS_NameMain then
    if DirExists(S_PathDirSync, CS_McNameRec) == false then
      OSCmd("MAKEDIR", S_PathDirRec)
    end
  end

  return B_InstrDirCreated
end


function EmptyInstrBt()
  local S_CurFunc = "EmptyInstrBt"
  DebugMsg(S_CurFunc)
--[[==================================================
Empty backtrack subdirectory of given instrument
in order to get rid of any void data as backtracks
are recreated each time.
==================================================--]]
  if DirExists(CS_PathDirSyncBt, CS_McNameCurInstr) == true then
    OSCmd("EMPTYDIR", CS_PathDirSyncBtInstr)
  end

  OSCmd("COPYFILE", CS_PathFileTmplProj, CS_PathFileBtProj)
end


function ManageProjTempl(PS_NameInstr)
  local S_CurFunc = "ManageProjTempl(" .. PS_NameInstr .. ")"
  DebugMsg(S_CurFunc)
--[[==================================================
Create project template for MAIN or given 
instrument.
==================================================--]]
  local S_MCNameInstr = CS_PrefixMC .. PS_NameInstr
  local S_NameFileInstr = S_MCNameInstr .. CS_FileExtReaper
  local S_PathFileInstrProj, S_PathFileInstrProjTmpl

  local S_PathFileTmplProj, S_PathFileTmplProjBak, S_PathFileTmpTmplProj, S_PathFileTmpTmplProjBak

  S_PathFileTmplProj = CS_PathDirSync .. CS_DirSep .. CS_NameFileTmplProj
  S_PathFileTmpTmplProj = CS_PathDirCurProj .. CS_DirSep .. CS_NameFileTmplProj

  --Prepare template
  if CS_NameCurInstr == CS_NameMain then

    --Create MAIN-template from MAIN-project
    if reaper.file_exists(S_PathFileTmplProj) == false then
      OSCmd("COPYFILE", CS_PathFileCurProj, S_PathFileTmpTmplProj)
      EmptyProj(S_PathFileTmpTmplProj)
      OSCmd("COPYFILE", S_PathFileTmpTmplProj, S_PathFileTmplProj)
      OSCmd("DELFILE", S_PathFileTmpTmplProj)
    end
    
    if PS_NameInstr ~= CS_NameMain then

      --Check if instrument project exists (is the case when a new instrument project is created)
      S_PathFileInstrProj = CS_PathDirCurProj .. CS_DirSep .. S_MCNameInstr .. CS_DirSep .. S_NameFileInstr
      if reaper.file_exists(S_PathFileInstrProj) == false then
        OSCmd("COPYFILE", S_PathFileTmplProj, S_PathFileInstrProj)
      end
    
      --Create template within SYNC of instrument project
      S_PathFileInstrProjTmpl = CS_PathDirCurProj .. CS_DirSep .. S_MCNameInstr .. CS_DirSep .. CS_McNameSync .. CS_DirSep .. CS_NameFileTmplProj
      if reaper.file_exists(S_PathFileInstrProjTmpl) == false then
        OSCmd("COPYFILE", S_PathFileTmplProj, S_PathFileInstrProjTmpl)
      end

    end
  end
end


function GetNameCurInstr()
--[[==================================================
Extract instrument name from current project name.

Returns "MAIN" if current project is the main-project.
Returns "" if identification is not unambiguous  
==================================================--]]
  local S_NameInstr

  local S_NameCurProj = reaper.GetProjectName(0, "")
  local S_NameCurDir = reaper.GetProjectPath("")
  
  --Cut off extension
  S_NameCurProj = string.sub(S_NameCurProj, 1, string.len(S_NameCurProj) - string.len(CS_FileExtReaper))

  --Extract dir name from path
  S_NameCurDir = ExtractNameDirOrFile(S_NameCurDir)

  --Check if name of project contains #MC-prefix and if name of dir and project match
  if string.sub(S_NameCurDir, 1, string.len(CS_PrefixMC)) == CS_PrefixMC and S_NameCurProj ~= S_NameCurDir then
    S_NameInstr = ""
  elseif string.sub(S_NameCurDir, 1, string.len(CS_PrefixMC)) == CS_PrefixMC and S_NameCurProj == S_NameCurDir then
    S_NameInstr = string.sub(S_NameCurProj, string.len(CS_PrefixMC) + 1)
  else
    S_NameInstr = CS_NameMain
  end

  return S_NameInstr
end


function DirExists(PS_Path, PS_Dir)
--[[==================================================
Check if given directory exists in given path.
==================================================--]]
  local N_Idx = 0
  local B_Found = false
  local S_CurDir = ""

  while B_Found == false and S_CurDir ~= nil do
    S_CurDir = reaper.EnumerateSubdirectories(PS_Path, N_Idx)

    if S_CurDir == PS_Dir then
      B_Found = true
      break
    end

    N_Idx = N_Idx + 1
  end

  return B_Found
end


function OSCmd(PS_Cmd, PS_Source, PS_Dest)
  if PS_Dest == nil then
    PS_Dest = ""
  end
  local S_CurFunc = "OSCmd(" .. PS_Cmd .. ", " .. PS_Source .. ", " .. PS_Dest .. ")"
  DebugMsg(S_CurFunc)
--[[==================================================
Executes OS-command:

"MAKEDIR" (2nd parameter is ignored)
"REMOVEDIR" (2nd parameter is ignored)
"EMPTYDIR" (2nd parameter is ignored)
"COPYFILE"
"COPYDIR"
"DELFILE" (2nd parameter is ignored)
"RENAME"
"HIDE"
"UNHIDE"
"OPENTXT"
==================================================--]]
  local S_MakeDir, S_CopyFile, S_CopyDir, S_RemoveDir, S_CopyDirParam, S_EmtpyDir, S_Hide, S_Unhide, S_HideUnhideParam
  local S_CmdStr = ""

  local S_CurFile, N_FileIdx, N_LoopCtr
  
  if CS_CurOS == CS_WinOS then
    S_MakeDir = "md"
    S_RemoveDir = "rd /S /Q"
    S_CopyFile = "copy /Y"
    S_CopyDir = "xcopy"
    S_CopyDirParam = " /I /Q /E"
    S_EmtpyDir = "del /F /Q /S"
    S_Hide = "attrib +H"
    S_Unhide = "attrib -H"
    S_HideUnhideParam = " /S"
    S_OpenTxt = "notepad"

    if PS_Cmd == "MAKEDIR" then
      S_CmdStr = S_MakeDir .. " " .. '"' .. PS_Source .. '"'
    
    elseif PS_Cmd == "REMOVEDIR" then
      S_CmdStr = S_RemoveDir .. " " .. '"' .. PS_Source .. '"'

    --In cases where the destination file could also be a directory,
    --xcopy displays a confirmation, copy doesn't - but copy can't copy 
    --hidden files which is why the hidden attribute is to be removed and
    --restored in the main function
    elseif PS_Cmd == "COPYFILE" then
      S_CmdStr = S_CopyFile .. " " .. '"' .. PS_Source .. '"' .. " " .. '"' .. PS_Dest .. '"'

    elseif PS_Cmd == "COPYDIR" then
      S_CmdStr = S_CopyDir .. " " .. '"' .. PS_Source .. '"' .. " " .. '"' .. PS_Dest .. '"' .. S_CopyDirParam

    elseif PS_Cmd == "EMPTYDIR" then
      S_CmdStr = S_EmtpyDir .. " " .. '"' .. PS_Source .. CS_DirSep .. "*.*" .. '"'
    
    elseif PS_Cmd == "OPENTXT" then
      S_CmdStr = S_OpenTxt .. " " .. '"' .. PS_Source .. '"'
    
    elseif PS_Cmd == "HIDE" then
      S_CmdStr = S_Hide .. " " .. '"' .. PS_Source .. '"' .. S_HideUnhideParam

    elseif PS_Cmd == "UNHIDE" then
      S_CmdStr = S_Unhide .. " " .. '"' .. PS_Source .. '"' .. S_HideUnhideParam

    end

    if S_CmdStr ~= "" then
      DebugMsg(S_CurFunc, S_CmdStr)
      os.execute(string.fromutf8(S_CmdStr), -1)
    end

  elseif CS_CurOS == CS_MacOS then
    S_MakeDir = "mkdir -p"
    S_RemoveDir = "rm -d -R"
    S_CopyFile = "cp -f"
    S_CopyDir = "cp -R"
    S_EmtpyDir = "rm -f -R"
    S_Hide = "chflags hidden"
    S_Unhide = "chflags nohidden"
    S_OpenTxt = "open"

    if PS_Cmd == "MAKEDIR" then
      S_CmdStr = S_MakeDir .. " " .. '"' .. PS_Source .. '"'
    
    elseif PS_Cmd == "REMOVEDIR" then
      S_CmdStr = S_RemoveDir .. " " .. '"' .. PS_Source .. '"'

    elseif PS_Cmd == "COPYFILE" then
      S_CmdStr = S_CopyFile .. " " .. '"' .. PS_Source .. '"' .. " " .. '"' .. PS_Dest .. '"'

    elseif PS_Cmd == "COPYDIR" then
      S_CmdStr = S_CopyDir .. " " .. '"' .. PS_Source .. '"' .. " " .. '"' .. PS_Dest .. '"'

    elseif PS_Cmd == "EMPTYDIR" then
      S_CmdStr = S_EmtpyDir .. " " .. '"' .. PS_Source .. CS_DirSep .. "*.*" .. '"'

    elseif PS_Cmd == "OPENTXT" then
      S_CmdStr = S_OpenTxt .. " " .. '"' .. PS_Source .. '"'
  
    elseif PS_Cmd == "HIDE" then
      S_CmdStr = S_Hide .. " " .. '"' .. PS_Source .. '"'

    elseif PS_Cmd == "UNHIDE" then
      S_CmdStr = S_Unhide .. " " .. '"' .. PS_Source .. '"'

    end

    if S_CmdStr ~= "" then
      DebugMsg(S_CurFunc, S_CmdStr)
      os.execute(S_CmdStr, -1)
    end
  end

  if PS_Cmd == "DELFILE" then
    os.remove(PS_Source)
  
  elseif PS_Cmd == "RENAME" then
    os.rename(PS_Source, PS_Dest)
  end
end


function EmptyProj(PS_PathProjFile)
  local S_CurFunc = "EmptyProj(" .. PS_PathProjFile .. ")"
  DebugMsg(S_CurFunc)
--[[==================================================
Deletes
- all tracks
- all effects on master track
of given file.

Returns 0 on success.
Returns -1 if file is not found. or FX can not be
deleted. 
==================================================--]]
  local N_RetVal = -1
  local N_NumOfFx
  local MT_Master

  if reaper.file_exists(PS_PathProjFile) == true then
    N_RetVal = 0
    OpenProj("", "", PS_PathProjFile)

    --Delete all tracks
    DeleteTracks_byID(0, reaper.CountTracks(0) - 1)

    --Delete FX from master track
    MT_Master = reaper.GetMasterTrack(0)
    N_NumOfFx = reaper.TrackFX_GetCount(MT_Master)

    while N_NumOfFx > 0 do
      if reaper.TrackFX_Delete(MT_Master, 0) == false then
        N_RetVal = -1
      end

      N_NumOfFx = reaper.TrackFX_GetCount(MT_Master)
    end

    CloseCurProj()
  end

  return N_RetVal
end


function SelectAllTrInFld_byID(PN_IDFld)
--[[==================================================
Select all tracks that are under a given folder track.

Returns:
- -1 if folder is not found
- Number of selected tracks
==================================================--]]
  local N_IDFirstTr
  local N_IDLastTr
  local N_TrID
  local N_CtrTr = -1

  --Check if folder track exists
  if PN_IDFld ~= -1 then
    N_IDFirstTr = PN_IDFld + 1
    N_IDLastTr = GetIDLastTrInFld_byID(PN_IDFld)
    N_CtrTr = 0

    --Loop through tracks under given folder
    for N_TrID = N_IDFirstTr, N_IDLastTr do
      reaper.SetTrackSelected(reaper.GetTrack(0, N_TrID), true)
      N_CtrTr = N_CtrTr + 1
    end
  end

  return N_CtrTr
end


function DetermineOS()
--[[==================================================
Determine current OS.

Returns
- "Win" if Windows
- "OSX" if MacOS
- "" if OS can not be determined
==================================================--]]
  local S_RetVal = ""

  if string.find(reaper.GetOS(), CS_WinOS, 1, true) ~= nil then
    S_RetVal = CS_WinOS
    CS_DirSep = "\\"
  elseif string.find(reaper.GetOS(), CS_MacOS, 1, true) ~= nil then
    S_RetVal = CS_MacOS
    CS_DirSep = "/"
  end

  return S_RetVal
end


function AdaptWinPath(PS_Path, PB_Lua)
--[[==================================================
Adapts given path to lua (when 2nd parameter is true),
i.e. backslashes are doubled, double quotes are
removed - or vice versa (when 2n parameter is false).
==================================================--]]
  if PB_Lua == true then
    PS_Path = string.gsub(PS_Path, "\\", "\\\\")
    PS_Path = string.gsub(PS_Path, '"', "")
  else
    PS_Path = string.gsub(PS_Path, "\\\\", "\\")
    PS_Path = '"' .. PS_Path .. '"'
  end

  return PS_Path
end


function GetInstr()
--[[==================================================
Take instrument names from the names of the
subdirectories of the current MAIN-project directory.

Returns number of found instruments.
==================================================--]]
  local N_InstrCtr = 0
  local N_DirCtr = 0
  local S_CurDir

  S_CurDir = reaper.EnumerateSubdirectories(CS_PathDirCurProj, N_DirCtr)

  while S_CurDir ~= nil do

    --If current dir is an instrument directory
    if string.sub(S_CurDir, 1, string.len(CS_PrefixMC)) == CS_PrefixMC and S_CurDir ~= CS_McNameSync  then
      N_InstrCtr = N_InstrCtr + 1
      CAS_Instr[N_InstrCtr] = string.sub(S_CurDir, string.len(CS_PrefixMC) + 1)
    end

    N_DirCtr = N_DirCtr + 1
    S_CurDir = reaper.EnumerateSubdirectories(CS_PathDirCurProj, N_DirCtr)
  end

  return N_InstrCtr
end


function SyncHide(PS_Hide)
  --[[==================================================
  Hide or unhide all SYNC-directories.
  Has to be done centrally, because the Windows-copy 
  command can not copy hidden files.

  Parameters: "HIDE" or "UNHIDE"
  ==================================================--]]
    local S_CurDir
    local N_DirCtr = 0
  
    if CS_NameCurInstr == CS_NameMain then
      S_CurDir = reaper.EnumerateSubdirectories(CS_PathDirCurProj, N_DirCtr)
    
      while S_CurDir ~= nil do
    
        --If current dir is an instrument directory
        if string.sub(S_CurDir, 1, string.len(CS_PrefixMC)) == CS_PrefixMC and S_CurDir ~= CS_McNameSync then
          OSCmd(PS_Hide, CS_PathDirCurProj .. CS_DirSep .. S_CurDir .. CS_DirSep .. CS_McNameSync) 

        --If it's the SYNC-directory of the main-project
        elseif S_CurDir == CS_McNameSync then
          OSCmd(PS_Hide, CS_PathDirCurProj .. CS_DirSep .. S_CurDir)
        end
    
        N_DirCtr = N_DirCtr + 1
        S_CurDir = reaper.EnumerateSubdirectories(CS_PathDirCurProj, N_DirCtr)
      end
    
    else
      OSCmd(PS_Hide, CS_PathDirCurProj .. CS_DirSep .. S_CurDir .. CS_DirSep .. CS_McNameSync)
    end

  end
  
  
function ExtractNameDirOrFile(PS_Path)
--[[==================================================
Return name of file or directory at the end of 
given path.
2nd return value: Position of first character of 
file or directory.
3rd return value: Remainder of path
==================================================--]]
  local N_PosLastDirSep

  N_PosLastDirSep = string.len(PS_Path) - 1
  while string.sub(PS_Path, N_PosLastDirSep, N_PosLastDirSep) ~= CS_DirSep and N_PosLastDirSep > 0 do
    N_PosLastDirSep = N_PosLastDirSep - 1
  end

  return string.sub(PS_Path, N_PosLastDirSep + 1), N_PosLastDirSep + 1, string.sub(PS_Path, 1, N_PosLastDirSep - 1)
end


function DeleteTracks_byID(PN_IDStartTr, PN_IDEndTr)
--[[==================================================
Delete given track or track range.
==================================================--]]
  local N_CurTr
  local N_InitNumOfTr = reaper.CountTracks(0)
  local N_TrToBeDel = PN_IDEndTr - PN_IDStartTr + 1
  local N_Ctr

  N_CurTr = GetIDLastTrInFld_byID(PN_IDEndTr)
  while N_CurTr >= PN_IDStartTr do
    reaper.DeleteTrack(reaper.GetTrack(0, N_CurTr))
    N_CurTr = N_CurTr - 1
  end
end


function GetIndicator_byName(PS_TrName)
--[[==================================================
Returns indicator of given track name (or "" if 
there is no indicator.
==================================================--]]
  local S_RetVal

  if string.sub(PS_TrName, string.len(CS_IndicBt) * -1) == CS_IndicBt then
    S_RetVal = CS_IndicBt
  elseif string.sub(PS_TrName, string.len(CS_IndicTf) * -1) == CS_IndicTf then
    S_RetVal = CS_IndicTf
  elseif string.sub(PS_TrName, string.len(CS_IndicBtTf) * -1) == CS_IndicBtTf then
    S_RetVal = CS_IndicBtTf
  else
    S_RetVal = ""
  end

  return S_RetVal
end


function RemoveIndicator_byID(PN_TrID, PS_Indic)
--[[==================================================
Removes given indicator from name of given track.
==================================================--]]
  local S_TrNameNew
  local S_TrName = GetTrName(PN_TrID)
  local S_CurIndic = GetIndicator_byName(S_TrName)

  if PS_Indic == CS_IndicTf then
    if S_CurIndic == CS_IndicTf then
      S_TrNameNew = string.sub(S_TrName, 1, string.len(S_TrName) - string.len(CS_IndicTf))
    elseif S_CurIndic == CS_IndicBtTf then
      S_TrNameNew = string.sub(S_TrName, 1, string.len(S_TrName) - string.len(CS_IndicBtTf)) .. CS_IndicBt
    end
  elseif PS_Indic == CS_IndicBt then
    if S_CurIndic == CS_IndicBt then
      S_TrNameNew = string.sub(S_TrName, 1, string.len(S_TrName) - string.len(CS_IndicBt))
    elseif S_CurIndic == CS_IndicBtTf then
      S_TrNameNew = string.sub(S_TrName, 1, string.len(S_TrName) - string.len(CS_IndicBtTf)) .. CS_IndicTf
    end
  elseif PS_Indic == CS_IndicBtTf or PS_Indic == "" then
    if S_CurIndic == CS_IndicTf then
      S_TrNameNew = string.sub(S_TrName, 1, string.len(S_TrName) - string.len(CS_IndicTf))
    elseif S_CurIndic == CS_IndicBt then
      S_TrNameNew = string.sub(S_TrName, 1, string.len(S_TrName) - string.len(CS_IndicBt))
    elseif S_CurIndic == CS_IndicBtTf then
      S_TrNameNew = string.sub(S_TrName, 1, string.len(S_TrName) - string.len(CS_IndicBtTf))
    else
      S_TrNameNew = S_TrName
    end
  end

  RenameTr_byID(PN_TrID, S_TrNameNew)
end


function RemoveAllIndicatorsInFld_byID(PN_TrID)
--[[==================================================
Removes any indicators from given track and all
tracks underneath it (assuming that given track is
a folder track).
==================================================--]]
  local N_TrCtr

  for N_TrCtr = PN_TrID, GetIDLastTrInFld_byID(PN_TrID) do
    RemoveIndicator_byID(N_TrCtr, "")
  end

end


function RemoveIndicatorSelTr(PS_Indic)
--[[==================================================
Remove given indicator from selected tracks.
==================================================--]]
  local N_TotNumOfTr = reaper.CountTracks(0)
  local N_TrID

  --Loop through all tracks
  for N_TrID = 0, N_TotNumOfTr - 1 do
    if reaper.IsTrackSelected(reaper.GetTrack(0, N_TrID)) == true then
      RemoveIndicator_byID(N_TrID, PS_Indic)
    end
  end
end


function ShortenNameSelTr(PN_LenName)
--[[==================================================
Shorten name of selected tracks to given number of 
characters.
==================================================--]]
  local N_TotNumOfTr = reaper.CountTracks(0)
  local N_TrID, S_NewName

  --Loop through all tracks
  for N_TrID = 0, N_TotNumOfTr - 1 do
    if reaper.IsTrackSelected(reaper.GetTrack(0, N_TrID)) == true then
      S_NewName = string.sub(GetTrName(N_TrID), 1, PN_LenName)
      RenameTr_byID(N_TrID, S_NewName)
    end
  end
end
  
  
function AddIndicator_byID(PN_TrID, PS_Indic)
--[[==================================================
Add an indicator to given track.
==================================================--]]
  local S_TrName = GetTrName(PN_TrID)
  local S_CurIndic = GetIndicator_byName(S_TrName)

  if S_CurIndic ~= "" then
    RemoveIndicator_byID(PN_TrID, "")
    S_TrName = GetTrName(PN_TrID)
  end

  RenameTr_byID(PN_TrID, S_TrName .. PS_Indic)
end


function SelectStemTr_byID(PN_FldID)
--[[==================================================
Select all stem-tracks. 
Returns number of selected tracks,
Returns -1 if folder is not found 
==================================================--]]
local N_IDFirstTr
local N_IDLastTr
local N_TrID
local S_TrName
local N_SelTrCount = -1

--Check if given folder exists
if reaper.GetTrack(0, PN_FldID) ~= nil then
  N_IDFirstTr = PN_FldID + 1
  N_IDLastTr = GetIDLastTrInFld_byID(PN_FldID)
  UnselectAllTracks()
  N_SelTrCount = 0

  --Loop through tracks of given folder
  for N_TrID = N_IDFirstTr, N_IDLastTr do

    --Get track name
    S_TrName = GetTrName(N_TrID)

    --If track name ends with "- stem", track is selected
    if string.sub(S_TrName, string.len(CS_SuffixStem) * -1)  == CS_SuffixStem then
      reaper.SetTrackSelected(reaper.GetTrack(0, N_TrID), true)
      N_SelTrCount = N_SelTrCount + 1
    end
  end
end

  return N_SelTrCount
end


function SelectIndicTr_byID(PN_IDFld, PS_Indic)
--[[==================================================
Select all tracks with a indicator within given folder. 

If Bt or Tf are given, tracks with BtTf are selected
also.

Returns number of selected tracks,

Returns -1 if folder is not found 
==================================================--]]
  local N_IDFirstTr
  local N_IDLastTr
  local N_TrID
  local S_TrName
  local S_CurIndic
  local B_Sel
  local N_SelTrCount = -1

  --Check if given folder exists
  if reaper.GetTrack(0, PN_IDFld) ~= nil then
    N_IDFirstTr = PN_IDFld + 1
    N_IDLastTr = GetIDLastTrInFld_byID(PN_IDFld)
    N_SelTrCount = 0
    UnselectAllTracks()

    --Loop through tracks of given folder
    for N_TrID = N_IDFirstTr, N_IDLastTr do
      B_Sel = false

      --Get track name
      S_TrName = GetTrName(N_TrID)

      --Match given indication with track indication
      S_CurIndic = GetIndicator_byName(S_TrName)

      if PS_Indic == CS_IndicTf then
        if S_CurIndic == CS_IndicTf or S_CurIndic == CS_IndicBtTf then
          B_Sel = true
        end
      elseif PS_Indic == CS_IndicBt then
        if S_CurIndic == CS_IndicBt or S_CurIndic == CS_IndicBtTf then
          B_Sel = true
        end
      elseif PS_Indic == CS_IndicBtTf then
        if S_CurIndic == CS_IndicBtTf then
          B_Sel = true
        end
      end

      --Select current track if indications match
      if B_Sel == true then
        reaper.SetTrackSelected(reaper.GetTrack(0, N_TrID), true)
        N_SelTrCount = N_SelTrCount + 1
      end
    end
  end

  return N_SelTrCount
end


function ToggleIndicatorSelTr()
--[[==================================================
Toggle through possible indicators:

">B": Track is stemmed to backtracks

">C": Track will be transferred 
- to instrument track
- to MAIN under *MIX-folder given 
- indicator is removed after processing

">B>C": Both of the above

Tracknames are returned if:
- Track is not in *REC or *MIX
- Track contains subproject
==================================================--]]
  local N_TrID
  local S_CurTrName
  local S_RetNamesWrongFld = ""
  local S_RetNamesSubProj = ""
  local S_NewTrName
  local S_CurIndic
  local A_SelTr = {}
  local N_SelTrCtr = 0

  --Rename tracks
  for N_TrID = 0, reaper.CountTracks(0) - 1 do
    if reaper.IsTrackSelected(reaper.GetTrack(0, N_TrID)) == true then
      S_CurTrName = GetTrName(N_TrID)
      S_CurIndic = GetIndicator_byName(S_CurTrName)
      N_SelTrCtr = N_SelTrCtr + 1
      A_SelTr[N_SelTrCtr]= N_TrID

      if S_CurIndic == CS_IndicBt then
        S_NewTrName = string.sub(S_CurTrName, 1, string.len(S_CurTrName) - string.len(CS_IndicBt)) .. CS_IndicTf
      elseif S_CurIndic == CS_IndicTf then
        S_NewTrName = string.sub(S_CurTrName, 1, string.len(S_CurTrName) - string.len(CS_IndicTf)) .. CS_IndicBtTf
      elseif S_CurIndic == CS_IndicBtTf then
        S_NewTrName = string.sub(S_CurTrName, 1, string.len(S_CurTrName) - string.len(CS_IndicBtTf))
      else
        S_NewTrName = S_CurTrName .. CS_IndicBt
      end

      RenameTr_byID(N_TrID, S_NewTrName)
    end
  end

  --Validate tracks and if track is invalid, reverse renaming
  for N_TrID = 0, reaper.CountTracks(0) - 1 do
    S_CurTrName = GetTrName(N_TrID)
    S_CurIndic = GetIndicator_byName(S_CurTrName)
    
    if S_CurIndic ~= "" then
      
      -- No markings are allowed outside *MIX- or *REC-folders
      if TrInValidFld_byID(N_TrID) == false then
        RemoveIndicator_byID(N_TrID, "")
        
        if S_RetNamesWrongFld ~= "" then
          S_RetNamesWrongFld = S_RetNamesWrongFld .. "\n"
        end
        S_RetNamesWrongFld = S_RetNamesWrongFld .. tostring(N_TrID + 1) .. ": " .. GetTrName(N_TrID)
      
      --">C" is not allowed when track (or child-tracks) contain subproject
      elseif (S_CurIndic == CS_IndicTf or S_CurIndic == CS_IndicBtTf) and TrContainsSubProj_byID(N_TrID) == true then
        RemoveIndicator_byID(N_TrID, "")
        
        if S_RetNamesSubProj ~= "" then
          S_RetNamesSubProj = S_RetNamesSubProj .. "\n"
        end
        S_RetNamesSubProj = S_RetNamesSubProj .. tostring(N_TrID + 1) .. ": " .. GetTrName(N_TrID)
      end
    end
  end

  --Reselect tracks that user has selected because
  --function ManageMediaItems_byID selects given track only
  UnselectAllTracks()
  for N_SelTrCtr = 1, #A_SelTr do
    reaper.SetTrackSelected(reaper.GetTrack(0, A_SelTr[N_SelTrCtr]), true)
  end

  return S_RetNamesWrongFld, S_RetNamesSubProj
end


function TrContainsSubProj_byID(PN_TrID)
--[[==================================================
Track or tracks below track (in case of folder track)
must not contain a subproject.
==================================================--]]
  local B_ContainsSub = false
  local N_LastTr
  
  N_LastTr = GetIDLastTrInFld_byID(PN_TrID)
  for N_TrCtr = PN_TrID, N_LastTr do
    B_ContainsSub = ManageMediaItems_byID(N_TrCtr, "CONTAINSSUB")

    if B_ContainsSub == true then
      break
    end
  end
  
  return B_ContainsSub
end


function TrInValidFld_byID(PN_TrID)
--[[==================================================
Track to be indicated must be in *MIX- or "REC-folder.
==================================================--]]
  local B_ValidFldFound = false
  local N_TopRec, N_BtmRec, N_TopMix, N_BtmMix

  N_TopRec = GetTrID(CS_TrNameRec, "")
  N_BtmRec = GetIDLastTrInFld_byID(N_TopRec)
  N_TopMix = GetTrID(CS_TrNameMix, "")
  N_BtmMix = GetIDLastTrInFld_byID(N_TopMix)

  if N_TopRec ~= -1 and PN_TrID > N_TopRec and PN_TrID <= N_BtmRec then
    B_ValidFldFound = true
  end

  if N_TopMix ~= -1 and PN_TrID > N_TopMix and PN_TrID <= N_BtmMix then
    B_ValidFldFound = true
  end

  return B_ValidFldFound
end


function MatchBckTrFolders(PS_FldMaster, PS_FldClone)
  local S_CurFunc = "MatchBckTrFolders: " .. PS_FldMaster .. " with " .. PS_FldClone
  DebugMsg(S_CurFunc)
--[[==================================================
--Match content of two BACKTRACK-type folders
--(master and clone).
==================================================--]]
  local N_IDFldMaster = GetTrID(PS_FldMaster, "")
  local N_IDFldClone = GetTrID(PS_FldClone, "")
  local N_IDFirstTrFldMaster = N_IDFldMaster + 1
  local N_IDFirstTrFldClone = N_IDFldClone + 1
  local N_IDLastTrFldMaster = GetIDLastTrInFld_byID(N_IDFldMaster)
  local N_IDLastTrFldClone = GetIDLastTrInFld_byID(N_IDFldClone)

  local N_IDCtrFldMaster
  local N_IDCtrFldClone
  local S_TrNameFldMaster
  local S_TrNameFldClone
  local B_TrNameMatch

  --Loop through master folder
  N_IDCtrFldMaster = N_IDFirstTrFldMaster
  DebugMsg(S_CurFunc .. " - Loop master tracks, start-ID: " .. N_IDFirstTrFldMaster)

  while N_IDCtrFldMaster <= N_IDLastTrFldMaster do
    S_TrNameFldMaster = GetTrName(N_IDCtrFldMaster)

    --Check if it is a stemmed  track
    if string.sub(S_TrNameFldMaster, string.len(CS_SuffixStem) * -1) == CS_SuffixStem then
      B_TrNameMatch = false

      --Loop through clone folder
      N_IDCtrFldClone = N_IDFirstTrFldClone
      while N_IDCtrFldClone <= N_IDLastTrFldClone and B_TrNameMatch == false do
        S_TrNameFldClone = GetTrName(N_IDCtrFldClone)
        DebugMsg(S_CurFunc .. " - Master-/clone-track: " .. S_TrNameFldMaster .. "/" .. S_TrNameFldClone)

        if S_TrNameFldMaster == S_TrNameFldClone then
          B_TrNameMatch = true
        end

        N_IDCtrFldClone = N_IDCtrFldClone + 1
      end

      --Correct counter
      N_IDCtrFldClone = N_IDCtrFldClone - 1

      --If clone track is found, items are copied from master
      if B_TrNameMatch == true then
        DebugMsg(S_CurFunc .. " - Copy items")

        --Entire track is copied to clone folder
        SelTr_byIDs(N_IDCtrFldMaster, N_IDCtrFldMaster)

        --Select all items in track
        reaper.Main_OnCommand(CN_ReaCmdSelAllItemsInTr, 0)
        --Copy items
        reaper.Main_OnCommand(CN_ReaCmdCopyItems, 0)
        --Move cursor to start of items
        reaper.Main_OnCommand(CN_ReaCmdMoveCursorToStartOfItems, 0)

        SelTr_byIDs(N_IDCtrFldClone, N_IDCtrFldClone)

        --Delete all items on selected track
        ManageMediaItems_byID(N_IDCtrFldClone, "DELITEMS")

        --Paste items
        reaper.Main_OnCommand(CN_ReaCmdPaste, 0)
      else
        DebugMsg(S_CurFunc .. " - Copy track")

        --Copy/paste master track
        SelTr_byIDs(N_IDCtrFldMaster, N_IDCtrFldMaster)
        reaper.Main_OnCommand(CN_ReaCmdCopySelTr, 0)
        PasteAtFldBtm_byID(N_IDFldClone)
        N_IDLastTrFldClone = N_IDLastTrFldClone + 1

        if N_IDFldMaster > N_IDFldClone then
          N_IDCtrFldMaster = N_IDCtrFldMaster + 1
          N_IDFirstTrFldMaster = N_IDFirstTrFldMaster + 1
          N_IDLastTrFldMaster = N_IDLastTrFldMaster + 1
        end
      end
    end

    N_IDCtrFldMaster = N_IDCtrFldMaster + 1
  end

  --Loop through clone folder
  N_IDCtrFldClone = N_IDFirstTrFldClone
  DebugMsg(S_CurFunc .. " - Loop clone tracks, start-ID: " .. N_IDCtrFldClone)

  while N_IDCtrFldClone <= N_IDLastTrFldClone do
    S_TrNameFldClone = GetTrName(N_IDCtrFldClone)

    --Check if it is a stemmed track
    if string.find(S_TrNameFldClone, CS_SuffixStem, 1, true) ~= nil then
      B_TrNameMatch = false

      --Loop through master folder
      N_IDCtrFldMaster = N_IDFirstTrFldMaster
      while N_IDCtrFldMaster <= N_IDLastTrFldMaster and B_TrNameMatch == false do
        S_TrNameFldMaster = GetTrName(N_IDCtrFldMaster)
        DebugMsg(S_CurFunc .. " - Clone-/master-track: " .. S_TrNameFldClone .. "/" .. S_TrNameFldMaster)

        if S_TrNameFldMaster == S_TrNameFldClone then
          B_TrNameMatch = true
        end

        N_IDCtrFldMaster = N_IDCtrFldMaster + 1
      end

      --Correct counter
      N_IDCtrFldMaster = N_IDCtrFldMaster - 1

      --If master track is not found,
      --clone track is deleted
      if B_TrNameMatch == false then
        DebugMsg(S_CurFunc .. " - Delete track")

        SelTr_byIDs(N_IDCtrFldClone, N_IDCtrFldClone)
        reaper.Main_OnCommand(CN_ReaCmdDelSelTr, 0)

        N_IDCtrFldClone = N_IDCtrFldClone - 1
        N_IDLastTrFldClone = N_IDLastTrFldClone - 1

        if N_IDFldMaster > N_IDFldClone then
          N_IDFirstTrFldMaster = N_IDFirstTrFldMaster - 1
          N_IDLastTrFldMaster = N_IDLastTrFldMaster - 1
        end
      end
    end

    N_IDCtrFldClone = N_IDCtrFldClone + 1
  end
end


function RenameTr_byID(PN_IDTr, PS_NewName)
--[[==================================================
Rename track specified by given ID and with given name.

Return -1 if track is not found
==================================================--]]
  local N_RetVal = -1

  if reaper.GetTrack(0, PN_IDTr) ~= nil then
    N_RetVal = 0
    reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0, PN_IDTr), "P_NAME", PS_NewName, true)
  end

  return N_RetVal
end


--[[==================================================
Rename all stem-tracks in given folder from "- stem"
to "- $tem" (if 2nd parameter=true) or vice versa. 
Used so that generation of backtracks excludes 
existing stem-tracks.

Returns or number of renamed tracks.
==================================================--]]
function RenStemTr(PS_FldName, PB_TmpStem)
  local N_TrCtr, N_TrIDStart, N_TrIDEnd, S_TrName
  local N_FndTr = 0

  N_TrIDStart = GetTrID(PS_FldName, "") 
  N_TrIDEnd = GetIDLastTrInFld_byID(N_TrIDStart)

  for N_TrCtr = N_TrIDStart + 1, N_TrIDEnd do
    S_TrName = GetTrName(N_TrCtr)
    
    if string.sub(S_TrName, string.len(CS_SuffixStem) * -1) == CS_SuffixStem then
      N_FndTr = N_FndTr + 1

      if PB_TmpStem == true then
        RenameTr_byID(N_TrCtr, string.gsub(S_TrName, CS_SuffixStem, CS_SuffixTmpStem))
      else
        RenameTr_byID(N_TrCtr, string.gsub(S_TrName, CS_SuffixTmpStem, CS_SuffixStem))
      end
    end
  end

  return N_FndTr
end


function GetTrID(PS_TrName, PS_FldName)
--[[==================================================
Get track ID of given track (0-based) - first occurance.
If folder is specified, just this folder is searched.

Returns -1 if track is not found.
==================================================--]]
  local N_IDLastTr
  local N_TrID
  local S_TrName
  local N_RetID = -1
  local B_FldFound = false
  local S_NameOfLastTrInFld

  if reaper.CountTracks(0) > 0 then

    --Determine to which track search shall be executed
    --depending on if foldername has bee specified
    if PS_FldName ~= "" then
      S_NameOfLastTrInFld, N_IDLastTr = GetLastTrInFld_byName(PS_FldName)
    else
      N_IDLastTr = reaper.CountTracks(0) - 1
    end

    --Loop through all tracks
    for N_TrID = 0, N_IDLastTr do
      S_TrName = GetTrName(N_TrID)

      --If folder is found
      if S_TrName == PS_FldName then
        B_FldFound = true
      end

      --If track name is found and there is no folder name
      if S_TrName == PS_TrName and PS_FldName == "" then
        N_RetID = N_TrID
        break
      end

      --If track name is found and the folder has been found
      if S_TrName == PS_TrName and B_FldFound == true then
        N_RetID = N_TrID
        break
      end
    end
  end
  return N_RetID
end


function GetTrName(PN_TrID)
--[[==================================================
Return track name based on given track ID.
Returns "" if track is not found.
==================================================--]]
  local N_RetVat
  local S_TrName = ""

  if reaper.GetTrack(0, PN_TrID) ~= nil then
    N_RetVal, S_TrName = reaper.GetTrackName(reaper.GetTrack(0, PN_TrID), "")
  end

  return S_TrName
end


function GetIDLastTrInFld_byID(PN_FldID)
--[[==================================================
Find last track in given folder and return ID. 

If folder is empty, the ID of the folder is returned.
If folder is not found, -1 is returned.
==================================================--]]
  local N_TrID
  local N_CountTr = reaper.CountTracks(0) - 1
  local N_FirstTr = PN_FldID + 1
  local N_IDLstTr = -1

  --Check if given folder exists
  if reaper.GetTrack(0, PN_FldID) ~= nil then
    --Loop until track with same depth as given folder is found
    for N_TrID = N_FirstTr, N_CountTr do
      if reaper.GetTrackDepth(reaper.GetTrack(0, N_TrID)) <= reaper.GetTrackDepth(reaper.GetTrack(0, PN_FldID)) then
        N_IDLstTr = N_TrID - 1
        break
      end
    end

    --If no track on same level is found
    --bottom of project must have been reached
    if N_IDLstTr == -1 then
      N_IDLstTr = N_CountTr
    end
  end

  return N_IDLstTr
end


function GetLastTrInFld_byName(PS_FldName)
--[[==================================================
Find last track in given folder and return name and ID.
 
Returns:
- Name of folder and its ID, if folder is empty
--Emtpy string and -1, if folder is not found
==================================================--]]
  local N_TotNumOfTr
  local N_TrID
  local S_TrName
  local MT_Tr
  local S_RetTrName = ""
  local N_RetTrID = -1
  local N_DepthPFolder

  N_TotNumOfTr = reaper.CountTracks(0)

  --Loop through all tracks
  for N_TrID = 0, N_TotNumOfTr - 1 do
    MT_Tr = reaper.GetTrack(0, N_TrID)
    S_TrName = GetTrName(N_TrID)

    --If folder track is found
    if S_TrName == PS_FldName then
      --Save depth of folder
      N_DepthPFolder = reaper.GetTrackDepth(MT_Tr)

      --Find bottom track of folder
      N_TrID = N_TrID + 1

      if N_TrID < N_TotNumOfTr then
        MT_Tr = reaper.GetTrack(0, N_TrID)
      end

      --Loop until track with same depth as given folder is found
      while N_TrID < N_TotNumOfTr and reaper.GetTrackDepth(MT_Tr) > N_DepthPFolder do
        N_TrID = N_TrID + 1
        MT_Tr = reaper.GetTrack(0, N_TrID)
      end

      --Get back to previous, i.e. last track of given folder
      N_TrID = N_TrID - 1
      S_RetTrName = GetTrName(N_TrID)
      N_RetTrID = N_TrID
      break
    end
  end

  return S_RetTrName, N_RetTrID
end


function SelTr_byIDs(PN_FirstTr, PN_LastTr)
--[[==================================================
Select range of tracks.
==================================================--]]
  local N_TrID

  reaper.SetOnlyTrackSelected(reaper.GetTrack(0, PN_FirstTr))
  reaper.Main_OnCommand(CN_ReaCmdLastTouched, 0)

  for N_TrID = PN_FirstTr + 1, PN_LastTr do
    reaper.SetTrackSelected(reaper.GetTrack(0, N_TrID), true)
    reaper.Main_OnCommand(CN_ReaCmdLastTouched, 0)
  end
end


function PasteAtFldBtm_byID(PN_FldID)
--[[==================================================
Tracks in clipboard are pasted at the bottom of
specifiedfolder-track. 
If the folder does not exist, it is created.

Returns ID at which tracks have been pasted.
==================================================--]]
  local N_IDOfFirstTr
  local N_IDOfLastTr
  local N_IDOfAboveFld = -1
  local N_TotNumOfTr
  local N_NumOfInsTr = 0
  local N_LoopCtr = 1
  local N_LoopIter = 10

  --Get total number of tracks
  N_TotNumOfTr = reaper.CountTracks(0)

  --Get first track in folder
  N_IDOfFirstTr = PN_FldID + 1

  --Get last track in folder
  N_IDOfLastTr = GetIDLastTrInFld_byID(PN_FldID)

  --If there are no tracks in folder-track,
  --select folder-track, paste tracks
  --and move tracks under folder-track
  if N_IDOfLastTr == PN_FldID then
    SelTr_byIDs(PN_FldID, PN_FldID)

    --Paste in loops because this function does not always work reliably
    N_LoopCtr = 1
    while N_LoopCtr < N_LoopIter and N_NumOfInsTr == 0 do
      reaper.Main_OnCommand(CN_ReaCmdPaste, 0)
      N_NumOfInsTr = (reaper.CountTracks(0) - N_TotNumOfTr)
      N_LoopCtr = N_LoopCtr + 1
    end

    reaper.ReorderSelectedTracks(PN_FldID + 1, 1)
  end

  --If there are existing tracks,
  --select last track track,
  --paste tracks and move tracks under folder-track
  if N_IDOfLastTr > PN_FldID then
    SelTr_byIDs(N_IDOfLastTr, N_IDOfLastTr)

    --Paste in loops because this function does not always work reliably
    N_LoopCtr = 1
    while N_LoopCtr < N_LoopIter and N_NumOfInsTr == 0 do
      reaper.Main_OnCommand(CN_ReaCmdPaste, 0)
      N_NumOfInsTr = (reaper.CountTracks(0) - N_TotNumOfTr)
      N_LoopCtr = N_LoopCtr + 1
    end

    reaper.ReorderSelectedTracks(PN_FldID + 1, 1)

    --Select tracks that have previously existed and reorder them
    --because reordering puts tracks directly under referenced track
    SelTr_byIDs(N_IDOfFirstTr + N_NumOfInsTr, N_IDOfLastTr + N_NumOfInsTr)
    reaper.ReorderSelectedTracks(PN_FldID + 1, 1)
  end

  UnselectAllTracks()
  return N_IDOfLastTr + 1
end


function InsertNewTr_byID(PS_TrName, PN_TrID)
--[[==================================================
Insert new track at specified track ID and
name according to the specified name.
==================================================--]]
  local N_RetVal
  local S_RetStr

  reaper.InsertTrackAtIndex(PN_TrID, false)
  N_RetVal, S_RetStr = reaper.GetSetMediaTrackInfo_String(reaper.GetTrack(0, PN_TrID), "P_NAME", PS_TrName, true)
end


function InsertNewTrAtFldBtm_byID(PS_TrName, PN_FldID)
--[[==================================================
Insert new track at bottom of given folder.

Returns ID at which track is inserted.
Returns -1 if folder is not found.
==================================================--]]
  local N_RetVal
  local S_RetStr
  local N_IDLastTr, N_IDNewTr, N_IDFld
  local N_RetVal = -1

  if PN_FldID ~= -1 then
    N_IDLastTr = GetIDLastTrInFld_byID(PN_FldID)
    N_IDNewTr = N_IDLastTr + 1
    InsertNewTr_byID(PS_TrName, N_IDNewTr)
    N_RetVal = N_IDNewTr

    --Depending on if there are existing tracks under folder,
    --reordering works differently
    if N_IDLastTr == PN_FldID then
      SelTr_byIDs(N_IDNewTr, N_IDNewTr)
      reaper.ReorderSelectedTracks(N_IDNewTr + 1, 1)
    else
      SelTr_byIDs(N_IDNewTr, N_IDNewTr)
      reaper.ReorderSelectedTracks(PN_FldID + 1, 1)
      SelTr_byIDs(PN_FldID + 2, N_IDNewTr)
      reaper.ReorderSelectedTracks(PN_FldID + 1, 1)
    end
  end

  UnselectAllTracks()
  return N_RetVal
end


function ReplaceStrInStr(PS_OrgStr, PS_WhatStr, PS_WithStr)
--[[==================================================
Replace special characters in strings for replacement
to work.
Solution found here: 
https://stackoverflow.com/questions/29072601/lua-string-gsub-with-a-hyphen
==================================================--]]
  PS_WhatStr = string.gsub(PS_WhatStr, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1") -- escape pattern
  PS_WithStr = string.gsub(PS_WithStr, "[%%]", "%%%%") -- escape replacement
  return string.gsub(PS_OrgStr, PS_WhatStr, PS_WithStr)
end


function EscapeStr(PS_Str)
  local S_RetStr

  S_RetStr = string.gsub(PS_Str, "%.", "%%.")
  S_RetStr = string.gsub(S_RetStr, "%-", "%%-")
  S_RetStr = string.gsub(S_RetStr, "%(", "%%(")
  S_RetStr = string.gsub(S_RetStr, "%)", "%%)")

  return S_RetStr
end


function UnselectAllTracks()
--[[==================================================
Unselect all tracks in current project.
==================================================--]]
  reaper.Main_OnCommand(CN_ReaCmdUnselAll, 0)  
end


function Msg(PS_Msg)
--[[==================================================
Used for ad hoc messages during error analysis.
==================================================--]]
  reaper.ShowConsoleMsg(PS_Msg .. "\n")
end


function DebugMsg(PS_Func, PS_Msg)
--[[==================================================
Show, print debug message.
==================================================--]]
  local S_LogLine

  if PS_Msg == nil then
    S_LogLine = "***" .. PS_Func .. "\n"
    if CB_DebugToLog == false then
      reaper.ShowConsoleMsg(S_LogLine)
    else
      HandleLogFile("ADDLINE", S_LogLine)
    end
  else
    S_LogLine = "   " .. PS_Func .. ": " .. PS_Msg .. "\n"
    if CB_DebugToLog == false then
      reaper.ShowConsoleMsg(S_LogLine)
    else
      HandleLogFile("ADDLINE", S_LogLine)
    end
  end
end


function HandleLogFile(PS_Func, PS_Line)
  --[[==================================================
  Controls opening, adding text and closing of
  log file.
  ==================================================--]]
  
  if CB_DebugToLog == true and S_NameTmpTr ~= CS_MCFunc_TI then
    if PS_Func == "CREATE" then
      CF_Log = io.open (CS_PathFileLog, "w")
    
    elseif PS_Func == "ADDLINE" then
      CF_Log:write(PS_Line)
    
    elseif PS_Func == "CLOSE" then
      CF_Log:close()
    end
  end
end
  
main()

  

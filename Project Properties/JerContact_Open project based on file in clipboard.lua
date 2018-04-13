-- @description Open project based on file in clipboard
-- @version 1.2
-- @author JerContact
-- @about
--   # open-project-based-on-file-in-clipboard
--   If you copy the full pathname of the file, this script will open the corresponding reaper project associated with that file based
--   on the bwf metadata inside the .wav file (to get to this to work you'll need to render out .wav files from reaper and have
--   the "Include project filename in BWF data" checked.  This script first figures out the timecode location of that file imbedded
--   inside the .wav file, and tries to find the item around that location.  If the file is in the project but has moved timecode there
--   will be a warning message box telling you so.  If the project is opened but the item is not longer in the project, you'll get
--   and error saying the item is no longer there.  If there is no metadata in you .wav file, no project will be loaded.
-- @changelog
--   + 1.2 - couldn't render out files immediately b/c the file was still in use after running this script, fixed this issue

weallgood=0
filetxt = reaper.CF_GetClipboard("")

m, n = string.find(filetxt, ".wav")
  
  if m~= nil then
    
    test = string.find(filetxt, '"')
    if test==1 then
      testlength = string.len(filetxt)
      test = string.sub(filetxt, testlength)
      test = string.find(filetxt, '"')
      if test==1 then
        filetxt = string.sub(filetxt, 2, testlength-1)
      end
    end
    
    --reaper.ShowMessageBox(filetxt, "", 1)
    
    filetxt = string.sub(filetxt, 1, (m+3))
    filetxt = tostring(filetxt)
    wavfile = filetxt

    f = io.input(filetxt)
    
    a=f:read()
    
    n1 = a
    
    m, n = string.find(n1, "RPP:")
    
    f:close()
    
    if m~=nil then
    
      n1 = string.sub(n1, (m+4))
      
      m, n = string.find(n1, ".RPP")
      
      n1 = string.sub(n1, 1, n)
      
      filenametemp=n1
      
      m=0

        m, n = string.find(filenametemp, ".rpp")
        if m~=nil then
          filenametemp = string.sub(filenametemp, 1, n)
        end

      n1=filenametemp
      
      
      open=1
      proj=0
      subproj=0
      while subproj do
        subproj, projname = reaper.EnumProjects(proj, "NULL")
        
        if projname==n1 then
          project=subproj
          open=0
          break
        end
        proj=proj+1
      end
      
      if open==1 then
        reaper.Main_OnCommand(40859, 0) --new project tab
        reaper.Main_openProject(n1)
      else
        reaper.SelectProjectInstance(project)
      end
      
      m=0
      
      if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
          separator = "\\"
        else
          separator = "/"
        end
      
      while (m~=nil) do
        m, n = string.find(filetxt, separator)
        if m==nil then
          break
        end
        filetxt = string.sub(filetxt, m+1)
      end
      
      m, n = string.find(filetxt, ".wav")
      
      filetxt = string.sub(filetxt, 1, m-1)
      
      
      
--function get_path_bwf_data(var_path)
--retval, var_path = reaper.GetUserFileNameForRead("", "Select SRT file", "wav")
var_path = wavfile
pcm_source = reaper.PCM_Source_CreateFromFile(var_path)
pcm = reaper.GetMediaSourceSampleRate(pcm_source)
local fo=0, opchn
opchn = io.open(var_path, "rb") -- open take's source file to read binary
bext_found =false
if opchn ~= false then
riff_header = opchn:read(4) -- file header
file_size_buf = opchn:read(4) -- file_size as string
file_size = string.unpack ("<I4", file_size_buf) -- unpack file_size as unsigned integer, LE
fo=fo+8
wave_header = opchn:read(4)
fo=fo+4

while not bext_found and fo< file_size do
chunk_header = opchn:read(4) 
chunk_size_buf = opchn:read(4)
chunk_size = string.unpack ("<I4", chunk_size_buf) -- unpack chunk_size as unsigned integer, LE
fo=fo+8
if chunk_header ~="bext" then 
opchn:seek ("cur", chunk_size) -- seek beyond chunk
else
-- gfx.printf("chunk header:<%s> chunk size:<%s>", chunk_header, chunk_size)
-- gfx.x=10 gfx.y=gfx.y+gfx.texth
bext_found =true -- *set to flat var, calling functions set to tables*
chunk_data_buf = opchn:read(chunk_size) -- import chunk data as string
-- process chunk_data_buf
bext_Description = string.sub(chunk_data_buf, 1, 256)
bext_Originator = string.sub(chunk_data_buf, 256+1, 256+32)
bext_OriginatorReference = string.sub(chunk_data_buf, 256+32+1, 256+32+32)
bext_OriginationDate = string.sub(chunk_data_buf, 256+32+32+1, 256+32+32+10)
bext_OriginationTime = string.sub(chunk_data_buf, 256+32+32+10+1, 256+32+32+10+8) -- left these "open" to show the obvious structure
bext_TimeRefLow_buf = string.sub(chunk_data_buf, 256+32+32+10+8+1, 256+32+32+10+8+4) -- SMPTE codes and LUFS data follow these
bext_TimeRefHigh_buf = string.sub(chunk_data_buf, 256+32+32+10+8+4+1, 256+32+32+10+8+4+4) -- see EBU Tech 3285 v2 etc for more details.
bext_VersionNum_buf = string.sub(chunk_data_buf, 256+32+32+10+8+4+4+1, 256+32+32+10+8+4+4+2) --
--gfx.printf("LCDbuf:%d LD:%s OD:%s OT:%s LTRLbuf:%d LTRHbuf:%d", #chunk_data_buf, #bext_Description, bext_OriginationDate, bext_OriginationTime, #bext_TimeRefLow_buf, #bext_TimeRefHigh_buf)
--gfx.x=10 gfx.y=gfx.y+gfx.texth
-- I stopped here, but the full set of bext metadata can be retrieved -PM me for further details/help -planetnin
bext_TimeRefLow = string.unpack ("<I4", bext_TimeRefLow_buf) -- unpack chunk_size as unsigned integer (4-bytes)
bext_TimeRefHigh = string.unpack ("<I4", bext_TimeRefHigh_buf) -- unpack chunk_size as unsigned integer (4-bytes)
bext_VersionNum = string.unpack ("<i2", bext_VersionNum_buf) -- unpack chunk_size as signed integer (2-bytes)
-- combine high & low bytes & sample rate, save offset to table for this bwf_take
ret_bso = ((bext_TimeRefHigh*4294967295) + bext_TimeRefLow)/pcm--/reaper.GetMediaSourceSampleRate(reaper.GetMediaItemTake_Source(var_path)) --==> for offset in seconds
--ret_bso = reaper.format_timestr_pos(ret_bso, chunk_data_buf, 4)

-- *inner function returns to flat variables, "take" and "render" function add to table*
end
fo=fo+chunk_size
end
opchn:close() -- close file
else
bext_found = false
ret_bso = 0
end
    
reaper.PCM_Source_Destroy(pcm_source)

ret_bso = reaper.parse_timestr_pos(ret_bso, 5)
reaper.SetEditCurPos(ret_bso, true, true)

commandID = reaper.NamedCommandLookup("_SWS_AWSELTOEND")

reaper.Main_OnCommand(commandID, 0) --time selection to end of project

reaper.Main_OnCommand(40717, 0) --select all items in time selection

x = reaper.CountSelectedMediaItems(0)
      
      i=0
      
      while (i<x) do
      
        item = reaper.GetSelectedMediaItem(0, i)
        take = reaper.GetMediaItemTake(item, 0)
        
        
        if take ~= nil then
          retval, stringNeedBig = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
        
          if stringNeedBig == filetxt then
        
            pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            reaper.GetSet_LoopTimeRange(true, false, ret_bso, ret_bso, false)
            reaper.Main_OnCommand(40289, 0) --unselect all items
            reaper.SetMediaItemSelected(item, true)
            reaper.SetEditCurPos(pos, true, true)
            reaper.adjustZoom(1000, 1, true, -1)

            track = reaper.GetMediaItem_Track(item)
            reaper.Main_OnCommand(40286, 0) --go to previous track
            temptrack = reaper.GetSelectedTrack(0, 0)
            command=40286
            while temptrack~=track do
              reaper.Main_OnCommand(command, 0) --go to previous track
              temptrack2 = reaper.GetSelectedTrack(0, 0)
              if temptrack2==temptrack then
                command=40285
              end
              temptrack=temptrack2
            end
            
            commandID = reaper.NamedCommandLookup("_WOL_SETVZOOMC_LASTSELTRACK")
                   
            reaper.Main_OnCommand(40913, 0) --zoom vertically
            weallgood=1
          
          break
          end
        
        end
        
        i=i+1
        
      end
      
      
      if weallgood==0 then
      reaper.SelectAllMediaItems(0, true)
      x = reaper.CountSelectedMediaItems(0)
      i=0
      
      while (i<x) do
      
        item = reaper.GetSelectedMediaItem(0, i)
        take = reaper.GetMediaItemTake(item, 0)
        
        if take ~= nil then
          retval, stringNeedBig = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
        
          if stringNeedBig == filetxt then
        
          pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
          reaper.Main_OnCommand(40289, 0) --unselect all items
          reaper.SetMediaItemSelected(item, true)
          reaper.SetEditCurPos(pos, true, true)
          reaper.adjustZoom(1000, 1, false, -1)
          
          --commandID = reaper.NamedCommandLookup("_WOL_SETVZOOMC_LASTSELTRACK")
                   
          reaper.Main_OnCommand(40913, 0) --zoom vertically
          reaper.GetSet_LoopTimeRange(true, false, ret_bso, ret_bso, false)
          weallgood=1
          reaper.ShowMessageBox("Timecode Offset doesn't match the file selected, but a clip in this session has the same filename, so perhaps this is the correct one...","Possible Error",0)
          break
          end
        
        end
        
        i=i+1
        
      end
      end
      
      if weallgood==0 then
        reaper.Main_OnCommand(40289, 0) --unselect all items
        reaper.GetSet_LoopTimeRange(true, false, ret_bso, ret_bso, false)
        reaper.adjustZoom(1000, 1, false, -1)
        reaper.Main_OnCommand(40913, 0) --zoom vertically
        reaper.ShowMessageBox("Couldn't Find That Filename in the Session...Sorry...","ERROR!!!!!!!",0) 
      end
      
    end
    
  end

    
    

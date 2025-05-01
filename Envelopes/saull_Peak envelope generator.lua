-- @description Peak envelope generator
-- @author saul-l
-- @version 1.01
-- @changelog Removed console message, which was accidently left for autogen
-- @about
--   # Peak envelope generator
--
--   Generates envelope based on audio item peaks.
--   You can think of it as an offline audio source parameter baker.
--
--   Requires ReaImGui, but will prompt you to install it and provide ReaPack repo,
--   if you don't already have it.
--
--   Contains built-in documentation in UI.
--
--   Only works with FX envelopes at the moment

if not reaper.ImGui_GetBuiltinPath then
  reaper.MB("ReaImGui required. Please install it.", "Install ReaImGui", 0)
  if not pcall(function() reaper.ReaPack_BrowsePackages( "ReaImGui: ReaScript binding for Dear ImGui" ) end) then
    reaper.MB("Attempting to open ReaPack failed. Visit https://reapack.com/", "No ReaPack found", 0)
    if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
      os.execute('start https://reapack.com')
    elseif reaper.GetOS() == "OSX32" or reaper.GetOS() == "OSX64" or reaper.GetOS() == "macOS-arm64" then
      os.execute('open https://reapack.com')
    else
      os.execute('xdg-open https://reapack.com')
    end
  end
return
end
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9.2'
local ctx = ImGui.CreateContext('Peak Envelope')

envChanged = false
envString = 'None'
applyString = ''
env = nil
prevEnv = nil
smooth = false
smoothPrev = false
invert = false
invertPrev = false
offset = 0.0
offsetPrev = 0.0
scaling = 1.0
scalingPrev = 1.0
peakrate = 10
peakratePrev = 10
autoGenerate = true
autoScale = true
selectedItems  = {}
numchannels = 1
extratype = 0 -- ???
min = 0
max = 1.0

function EnvChange()
  if env == nil then
    if prevEnv ~= nil then
      env = prevEnv
    else
      envString = 'None'
    end
  end
     
  if env ~= nil then
    if pcall(function() local envName = reaper.GetEnvelopeName(env) end) then
      if env ~= prevEnv then 
        retval, envString = reaper.GetEnvelopeName(env)
        SetParamMinMaxCenter(env)
        envChanged = true
      end
      prevEnv = env
    else
      env = nil
      envString = 'None'
    end
  end
end

function SaveSelectedItems()
  local t = t or {}
  for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    t[i+1] = reaper.GetSelectedMediaItem(0, i)
  end
  return t
end
 
function CalculateEnvelope()
    
    local lpeakrate = 0
    
    if smooth then
      lpeakrate = peakrate*2 
    else
      lpeakrate = peakrate
    end

    for i, item in ipairs(selectedItems) do
        local peaks = {}
        local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local starttime = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local numsamples = math.floor(len*lpeakrate + 0.5)
        local ticklen = len/numsamples
        local buf = reaper.new_array(2*numsamples)
        buf.clear()
        local retval = reaper.GetMediaItemTake_Peaks(reaper.GetActiveTake(item), lpeakrate, starttime, numchannels, numsamples, extratype, buf)
        local samplecount  = (retval & 0xfffff)
        local outmode = (retval & 0xf00000)>>20
        if samplecount > 0  then
            for k = 1, numsamples, 1 do
              local p = #peaks
              peaks[p+1] = buf[k]
              peaks[p+2] = buf[numsamples+k]
            end
        end
        
        reaper.DeleteEnvelopePointRange(env, starttime, starttime + len)
        
      --  reaper.ShowConsoleMsg('maxpeak ' .. maxPeak .. '\n' .. 'max Y ' .. envMaxY .. '\n' .. 'scaling ' .. scaling .. '\n')
        local scaleFunc;
        if invert then
          scaleFunc = function (x) return max - (scaling * math.abs(x)) +offset end
        else
          scaleFunc = function (x) return scaling * math.abs(x) + offset end
        end
      
        for k, peak in ipairs(peaks) do
           reaper.InsertEnvelopePoint(env, starttime + (k-1)*ticklen*.5, scaleFunc(peak), 0,  0, true) 
        end
        
        if smooth then reaper.Main_OnCommand(42208,0) end
    end
 end
  
  
 -- INIT
 function Apply()
    countSelectedItems = reaper.CountSelectedMediaItems(0)
    reaper.PreventUIRefresh(1) 
    reaper.Undo_BeginBlock()
    if smooth then reaper.Main_OnCommand(40331,0) end
    selectedItems = SaveSelectedItems()
    CalculateEnvelope()
    reaper.Undo_EndBlock("Peak envelope generator", -1)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
 end
 
function SetParamMinMaxCenter(env)
  -- built-in non-fx envelopes will need special handling later
  if envString == 'Tempo map' or
     envString == 'Playrate' or
     envString == 'Volume (Pre-FX)' or
     envString == 'Volume' or
     envString == 'Pan' or
     envString == 'Width (Pre-FX)' or
     envString == 'Trim Volume' or
     envString == 'Mute'
     then return end
  
  -- Get envelope min and max
  retval, chunk = reaper.GetEnvelopeStateChunk(env, "", false)
  
 -- reaper.ShowConsoleMsg(chunk)
    
  local parmenv = string.match(chunk, "PARMENV.-%d+%.%d+%s+%d+%.%d+%s+%d+%.%d+")
  local parts = {}
  for word in parmenv:gmatch("%S+")
  do
    table.insert(parts,word)
  end
  min = parts[3]
  max = parts[4]
  if(autoScale) then
    offset = parts[3]
    scaling = math.abs(tonumber(min)-tonumber(max))
  end
end


 -- autogenerate
 -- if mouse down disable auto generate
 -- if value change -> enable autogenerate
 local function loop()
   local flags = ImGui.WindowFlags_NoDocking | ImGui.WindowFlags_AlwaysAutoResize
   local visible, open = ImGui.Begin(ctx, 'Peak Envelope', true, flags)
   if visible then
     local applyAutoGen = false
     
     env = reaper.GetSelectedEnvelope(0)
     if env ~= prevEnv then EnvChange() end    
     ImGui.Text(ctx, 'Active envelope: ' .. envString)
     ImGui.Separator(ctx)
     retval, invert = ImGui.Checkbox(ctx, 'Invert', invert )
     ImGui.SameLine(ctx)
     retval, smooth = ImGui.Checkbox(ctx, 'Smooth', smooth)
     ImGui.SameLine(ctx)
     retval, autoGenerate = ImGui.Checkbox(ctx, 'Auto-generate', autoGenerate)
     ImGui.SameLine(ctx)
     retval, autoScale = ImGui.Checkbox(ctx, 'Auto-scale', autoScale)
         ImGui.Separator(ctx)
     ImGui.SetNextItemWidth(ctx, 300.0)
     retval, peakrate = ImGui.DragInt(ctx, 'Points', peakrate, 1, 1, 100)   
     ImGui.SetNextItemWidth(ctx, 300.0)
     retval, scaling = ImGui.DragDouble(ctx, 'Scale', scaling, 0.1, 0.0, 1000.0)
     ImGui.SetNextItemWidth(ctx, 300.0)
     retval, offset = ImGui.DragDouble(ctx, 'Offset', offset, 0.05, -100.0, 100.0)
     ImGui.SetNextItemWidth(ctx, 300.0)

     if autoGenerate then
       if invertPrev ~= invert or
          smoothPrev ~= smooth or
          peakratePrev ~= peakrate or
          scalingPrev ~= scaling or
          offsetPrev ~= offset then
            if envChanged == false then
            -- reaper.ShowConsoleMsg("autogen values changed \n")
            applyAutoGen = true
            end
       end  
     end       
       invertPrev = invert
       smoothPrev = smooth
       peakratePrev = peakrate
       scalingPrev = scaling
       offsetPrev = offset
     
     if ImGui.Button(ctx, 'Generate') or applyAutoGen then
       local applySuccess = true
       
       countSelectedItems = reaper.CountSelectedMediaItems(0)
       if countSelectedItems == 0 then 
         applySuccess = false
         applyString = 'No selected items'
       end
       if env == nil then
         applySuccess = false
         applyString = 'No active envelope'
       end
       if applySuccess then
         applyString = 'Envelope generated'
         Apply()
       end
     end
     ImGui.SameLine(ctx)
     ImGui.Text(ctx, applyString)
     if ImGui.CollapsingHeader(ctx, 'Help') then
       ImGui.SeparatorText(ctx, 'Usage')
       ImGui.Text(ctx, '-Click an envelope to set it as an active envelope')
       ImGui.Text(ctx, '-Select audio item(s) used for envelope generation')
       ImGui.Text(ctx, '-Press Generate to generate envelopes')
       ImGui.Text(ctx, '-Generated envelope will overwrite existing points')
       ImGui.SeparatorText(ctx, 'Non-self-explanatory things')    
       ImGui.Text(ctx, '-Points is amount of points per second')
       ImGui.Text(ctx, '-Auto-generate generates new envelope after value change')
       ImGui.Text(ctx, '-Auto-scale sets scale and offset based on new envelope')
       ImGui.Text(ctx, ' minimum and maximum values when envelope is changed')
       
       

     end
     ImGui.End(ctx)
     
     envChanged = false
   end
   if open then
  
   
     reaper.defer(loop)
   end
 end
 
 reaper.defer(loop)

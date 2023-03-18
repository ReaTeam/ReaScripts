-- @description FX chain A-B
-- @author Thomas Dahl
-- @version 1.03
-- @changelog
--   Added visual feedback on loaded A and B buttons (white border)
--   Added target platform: All (tested on Windows and Ubuntu linux)
--
--   Removed in description about copying to another track - waiting for 
--   a solution on possible bug in ultraschall.SetFXStateChunk.
-- @about
--   # tompad_FX_chain_AB
--   Reascript for A/B-ing FX chains in Reaper DAW 
--
--   Use tompad_FX_chain_AB to compare different fx chains you create on a track.
--
--
--   How to use:
--   1. Create a fx chain on a track.
--   2. Run tompad_FXchain_AB.
--   3. Make sure the track with the fx chain is selected and press Inject A-button.
--   4. Make a new fx chain on track OR make some adjustments to the fx chain and press Inject B-button.
--   5. Its now possible to compare the two fx chains by pressing the two big buttons A and B.
--
--   Requirements (from ReaPack):
--
--   Reaper Tool Kit (rtk) from https://reapertoolkit.dev/index.xml 
--
--   Ultraschall API package from https://github.com/Ultraschall/ultraschall-lua-api-for-reaper/raw/master/ultraschall_api_index.xml



-- Setup package path locations to find rtk via ReaPack
local entrypath = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = string.format('%s/Scripts/rtk/1/?.lua;%s?.lua;', reaper.GetResourcePath(), entrypath)

--Loads ultrashall API
ultraschall_path = reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua"
if reaper.file_exists( ultraschall_path ) then
  dofile( ultraschall_path )
end

if not ultraschall or not ultraschall.GetApiVersion then -- If ultraschall loading failed of if it doesn't have the functions you want to use
  reaper.MB("Please install Ultraschall API, available via Reapack. Check online doc of the script for more infos.\nhttps://github.com/Ultraschall/ultraschall-lua-api-for-reaper", "Error", 0)
  return
end

-- Loads rtk in the global scope, and, if missing, attempts to install using
-- ReaPack APIs.
local function init(attempts)
    local ok
    ok, rtk = pcall(function() return require('rtk') end)
    if ok then
        -- Import worked. We can invoke the main function.
        local log = rtk.log
        return main()
    end
    local installmsg = 'Visit https://reapertoolkit.dev for installation instructions.'
    if not attempts then
        -- This is our first failed attempt, so prompt the user if they want us to install
        -- rtk via ReaPack automatically.
        if not reaper.ReaPack_AddSetRepository then
            -- The ReaPack extension isn't installed, so inform the user they need to do a
            -- manual install.
            return reaper.MB(
                'This script requires the REAPER Toolkit ReaPack. ' .. installmsg,
                'Missing Library',
                0 -- Ok
            )
        end
        -- Ask the user if they want us to install rtk
        local response = reaper.MB(
            'This script requires the REAPER Toolkit ReaPack. Would you like to automatically install it?',
            'Automatically install REAPER Toolkit ReaPack?',
            4 -- Yes/No
        )
        if response ~= 6 then
            -- User said no, we're done.
            return reaper.MB(installmsg, 'Automatic Installation Refused', 0)
        end
        -- User said yes, so add the ReaPack repository.
        local ok, err = reaper.ReaPack_AddSetRepository('rtk', 'https://reapertoolkit.dev/index.xml', true, 1)
        if not ok then
            return reaper.MB(
                string.format('Automatic install failed: %s.\n\n%s', err, installmsg),
                'ReaPack installation failed',
                0 -- Ok
            )
        end
        reaper.ReaPack_ProcessQueue(true)
    elseif attempts > 150 then
        -- After about 5 seconds we still couldn't find rtk, so give up.
        return reaper.MB(
            'Installation took too long. Assuming a ReaPack error occurred and giving up. ' .. installmsg,
            'ReaPack installation failed',
            0 -- Ok
        )
    end
    -- If we've made it this far we keep trying to load rtk
    reaper.defer(function() init((attempts or 0) + 1) end)
end

-- Invoked by init() when rtk has successfully been loaded.  Your script's main content
-- goes here.
function main()

--local rtk = require('rtk')
--local log = rtk.log

-- Set the current log level to INFO
--log.level = log.DEBUG


-- Global variables to store the FX chains
fx_chain1 = nil
fx_chain2 = nil

    -- Create an rtk.Window object that is to be the main application window   
 local window = rtk.Window{w=235, h=215, borderless=true, resizable=false, opacity=0.90, border='black'}

    local hbox1 = window:add(rtk.HBox{spacing=20,  margin=20})

        local btn_a = hbox1:add(rtk.Button{"A",fontscale=7, h=140, w=86, color='red',border='black',})
            btn_a.onclick = function() 
            loadFXChain1()
            end

            local btn_b = hbox1:add(rtk.Button{"B",fontscale=7,h=140, w=86, color='blue',border='black',})
            btn_b.onclick = function()
             loadFXChain2()
            end

local hbox2 = window:add(rtk.HBox{spacing=40, tmargin=170, lmargin=30})  
        local btn_inject_a = hbox2:add(rtk.Button{"Inject A"})
            btn_inject_a.onclick = function()
               saveFXChain1()
               btn_a:attr('border', 'white')
            end

            local btn_inject_b = hbox2:add(rtk.Button{"Inject B"})
            btn_inject_b.onclick = function()
              saveFXChain2()
                btn_b:attr('border', 'white')
            end
 
-- Save the current FX chain to a string variable (Inject)
function saveFXChain()
    local track = reaper.GetSelectedTrack(0, 0)  
    local retval1,StateChunk = reaper.GetTrackStateChunk(track,"",false)
    local fx_chain, linenumber = ultraschall.GetFXStateChunk(StateChunk)
    local count_of_fx= ultraschall.CountFXFromFXStateChunk(fx_chain)
      if count_of_fx == nil then
          reaper.ShowMessageBox( "You need a FX chain on track before you can inject it!", "Error", 0)
      else
        return fx_chain
      end       
end

-- Load an FX chain from a string variable
function loadFXChain(fx_chain)
    local track = reaper.GetSelectedTrack(0, 0)  
    local retval1,StateChunk = reaper.GetTrackStateChunk(track,"",false)
    local retval2, newStateChunk = ultraschall.SetFXStateChunk(StateChunk, fx_chain)
     reaper.SetTrackStateChunk(track, newStateChunk, false) 
end

-- Save the current FX chain to fx_chain1 variable
function saveFXChain1()
    local antalTrack = reaper.CountSelectedTracks(0)
    if antalTrack == 1 then
        fx_chain1 = saveFXChain()
    else
        reaper.ShowMessageBox( "You need to select one track!", "Error", 0) 
   end
end

-- Save the current FX chain to fx_chain2 variable
function saveFXChain2()
 local antalTrack = reaper.CountSelectedTracks(0)
    if antalTrack == 1 then
        fx_chain2 = saveFXChain()
    else
        reaper.ShowMessageBox( "You need to select one track!", "Error", 0) 
   end
end

-- Load the first FX chain
function loadFXChain1()
 local antalTrack = reaper.CountSelectedTracks(0)
   if antalTrack == 1 then
        if fx_chain1 == nil then
             reaper.ShowMessageBox( "You need to inject a FX chain in A before you can load it!", "Error", 0)
        else
        loadFXChain(fx_chain1)
        end
   else
      reaper.ShowMessageBox( "You need to select one track!", "Error", 0)    
   end
end

-- Load the second FX chain
function loadFXChain2()
 local antalTrack = reaper.CountSelectedTracks(0)
  if antalTrack == 1 then
    if fx_chain2 == nil then
        reaper.ShowMessageBox( "You need to inject a FX chain in B before you can load it!", "Error", 0)
    else
      loadFXChain(fx_chain2)
    end
  else
      reaper.ShowMessageBox( "You need to select one track!", "Error", 0)    
  end
end
    
    window:open{align='center'}
end
init()

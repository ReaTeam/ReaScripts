  --[[
   * ReaScript Name: Cubase AB floating FX
   * Description: implementation of "AB" button in Cubase 7+ plugin window
   * Instructions: float FX, changes params, run script, change params again and run script again. 
   It will change plugin parameters beetween two states. Use mpl_Cubase AB floating FX make equal to make two states same.
   * Author: Michael Pilyavskiy
   * Author URl: http://forum.cockos.com/member.php?u=70694
   * Repository: 
   * Repository URl: 
   * File URl:
   * Licence: GPL v3
   * Forum Thread: Script: 
   * Forum Thread URl: 
   * REAPER: 5.0 
   * Extensions: 
   --]]
   
 --[[
  * Changelog:
  * v1.0 (2015-08-28)
   + Initial Release
  --]] 
     
  retval, track, item, fxnum = reaper.GetFocusedFX()
  track = reaper.GetTrack(0, track-1)
  if retval == 1 then -- if track fx
  
      -- get current config  
      config_t = {}
      fx_guid = reaper.TrackFX_GetFXGUID(track, fxnum)    
      count_params = reaper.TrackFX_GetNumParams(track, fxnum)
      if count_params ~= nil then        
        for i = 1, count_params do
          value = reaper.TrackFX_GetParam(track, fxnum, i-1)
          tostring(value)
          table.insert(config_t, i, value)
        end  
      end              
      config_t_s = table.concat(config_t,"_")


    -- check memory -- 
    ret, config_t_ret = reaper.GetProjExtState(0, "AB_fx_tables", fx_guid)    
    if config_t_ret == "" then
    
      -- if nothing in memory just store current config
      reaper.SetProjExtState(0, "AB_fx_tables", fx_guid, config_t_s)
     
     else
      -- if config is already in memory
      
        -- form table from string stored in memory
        config_formed_t = {}        
        for match in string.gmatch(config_t_ret, "([^_]+)") do tonumber(match) table.insert(config_formed_t, match) end
        
        -- set values
        for i = 1, #config_formed_t do
          fx_value = config_formed_t[i]
          reaper.TrackFX_SetParam(track, fxnum, i-1, fx_value)
        end        
              
        -- store current config
        reaper.SetProjExtState(0, "AB_fx_tables", fx_guid, config_t_s)
    end  
  end 

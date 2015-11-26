-- set grid value for mpl Quantize tool

is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
val_ret=val/resolution
if val_ret > 0.99 then val_ret = 0.99 end
value = tostring(val_ret)
reaper.SetExtState("mplQT_settings", "Grid", value, false)

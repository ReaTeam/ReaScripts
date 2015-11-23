function Get_table_from_file(filename)
  local t = {}
  file = io.open(filename, "r")
  content = file:read("*all")
  for line in io.lines(filename) do table.insert(t, line) end
  file:close()
  return t
end
  
retval, filename = reaper.GetUserInputs("Get CommandID from filename", 1, "Filename", "")
 if  retval == true and filename~= nil and filename ~= "" then
  reaper.ShowConsoleMsg("")
  path = reaper.GetExePath()
  is_path_ins1, is_path_ins2 = string.find(filename, path)
  if is_path_ins1 ~= nil then filename = string.sub(filename, is_path_ins2+10) end
  kb_shortcuts_t = Get_table_from_file(path.."\\".."reaper-kb.ini")
  if kb_shortcuts_t ~= nil then
    for i=1, #kb_shortcuts_t do
      kb_shortcuts_item = kb_shortcuts_t[i]
      if string.find(kb_shortcuts_item, filename)~= nil and string.find(kb_shortcuts_item, "KEY") == nil then
        kb_shortcuts_item_t = {}
        st=0
        for i = 1, 7 do
          if st~= nil then
            st=string.find(kb_shortcuts_item, '"', st+1)
            table.insert(kb_shortcuts_item_t, st)        
          end  
        end 
        reaper.ShowConsoleMsg( "Command Id: ".. string.sub(kb_shortcuts_item, kb_shortcuts_item_t[1]+ 1,kb_shortcuts_item_t[2]-1 ) .."\n"..
          "REAPER action name: ".. string.sub(kb_shortcuts_item, kb_shortcuts_item_t[3]+ 1,kb_shortcuts_item_t[4]-1) )
        break
      end
    end
  end
 end 

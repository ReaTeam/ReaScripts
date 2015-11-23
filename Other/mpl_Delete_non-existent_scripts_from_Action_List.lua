    
  ret = reaper.MB('Delete non-existent scripts from Action List - NO UNDO!'..'\n'..
    'If you have non-unicode characters in script address, script will be ALSO DELETED!',
     'Delete non-existent scripts', 1)
  
  if ret == 1 then  
    filename = reaper.GetResourcePath()..'/'..'reaper-kb.ini'
    
    --get table from kb ini
    
    kb_table = {}
    file = io.open(filename, "r")
    content = file:read("*all")
    for line in io.lines(filename) do table.insert(kb_table, line) end
    file:close()
    
    -- delete not existed script from table
    for i = 1, #kb_table do
      if string.find(kb_table[i], 'SCR') ~= nil then
        temp_t = {}
        for num in kb_table[i]:gmatch("%g+") do table.insert(temp_t, num) end
        scr_filename = temp_t[#temp_t]
        file = io.open(scr_filename, "r")
        file2 = io.open(reaper.GetResourcePath()..'/Scripts/'..scr_filename, "r")
        if file ~= nil or file2 ~= nil then ex = true  else ex = false end 
        if not ex then kb_table[i] = '' end
      end
    end
    
    -- return table to kb ini
    file = io.open(filename, "w+")
    content = file:write(table.concat(kb_table, '\n'))
    file:close()
    
    reaper.MB('Reload REAPER to affect changes', '',0)
  end

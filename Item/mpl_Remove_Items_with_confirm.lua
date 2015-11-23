 reaper.Undo_BeginBlock()
limit = 1 -- message displayed after this items quantity 
script_title = 'Remove Items (confirm if > '..limit..')'

c_selitems = reaper.CountSelectedMediaItems(0) 
if c_selitems > limit then
  script_title = 'Remove '..c_selitems .. ' Items'
  ret = reaper.MB('Do you wanna remove '..c_selitems ..' items?',     'Removing items', 4)
  if ret == 6 then reaper.Main_OnCommand(40006,0) end
 else 
  reaper.Main_OnCommand(40006,0)
end

reaper.Undo_EndBlock(script_title,0)

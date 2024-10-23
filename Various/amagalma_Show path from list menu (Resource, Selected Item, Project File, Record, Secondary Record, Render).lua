-- @description Show path from list menu (Resource, Selected Item, Project File, Record, Secondary Record, Render)
-- @author amagalma
-- @version 1.12
-- @changelog - Fix for Render Path
-- @link https://forum.cockos.com/showthread.php?t=239556
-- @screenshot https://i.ibb.co/vhMDkZn/Show-path-from-list-menu.gif
-- @donation https://www.paypal.me/amagalma
-- @about
--   Shows the chosen item's path from the list:
--   - Reaper Resources path
--   - Selected Item path
--   - Project File path
--   - Record path
--   - Secondary Record path
--   - Render path
--   - First selected script's path in the Actions List
--
--   - Requires JS_ReaScriptAPI and SWS extensions


if not reaper.APIExists( "JS_Window_Find" ) then
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "You need to install the JS_ReaScriptAPI", 0 )
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
end

local proj_file = ({reaper.EnumProjects( -1 )})[2]

local function OpenRenderPath()
  if proj_file ~= "" then
    local match = string.match
    local projpath = proj_file:match(".+[/\\]")
    local render_path = ({reaper.GetSetProjectInfo_String( 0, "RENDER_FILE", "", false )})[2]
    if render_path == "" then
      local file = io.open(reaper.get_ini_file())
      io.input(file)
      for line in io.lines() do
        local path = line:match("defrenderpath=([^\n\r]+)")
        if path then
          render_path = path
          break
        end
      end
      file:close()
    end
    if render_path ~= "" then
      local absolute
      if match(reaper.GetOS(), "Win") then
        if render_path:match("^%a:\\") or render_path:match("^\\\\") then
          absolute = true
        end
      else -- unix
        absolute = render_path:match("^/")
      end
      render_path = absolute and render_path or projpath .. render_path
      local ok = reaper.CF_ShellExecute( render_path )
      if not ok then
        reaper.MB(render_path .. "\n\nPath has not been created yet!", "Can't open path", 0 )
      end
    else
      reaper.CF_ShellExecute( projpath )
    end
  else
    reaper.MB("Project is not saved.", "No render path!", 0 )
  end
end

local t = {
      {"#Show path in explorer/finder|"},
      {"Reaper Resources path", 40027},
      {"Selected Item path", '_S&M_OPEN_ITEM_PATH'},
      {"Project File path", '_S&M_OPEN_PRJ_PATH'},
      {"Record path", 40024},
      {"Secondary Record path", 40028},
      {"Render path", false},
      {"First selected script in Actions List", false}
}

local menu = ""
for i = 1, #t do
  menu = menu .. t[i][1] .. "|"
end

local title = "hidden " .. reaper.genGuid()
gfx.init( title, 0, 0, 0, 0, 0 )
local hwnd = reaper.JS_Window_Find( title, true )
if hwnd then
  reaper.JS_Window_Show( hwnd, "HIDE" )
end
gfx.x, gfx.y = gfx.mouse_x-52, gfx.mouse_y-70
local selection = gfx.showmenu(menu)
gfx.quit()

if selection > 0 then
  if selection == 4 and proj_file ~= "" then --------------
  
    reaper.CF_LocateInExplorer( proj_file )
    
  elseif selection == 7 then --------------------
  
    OpenRenderPath()
    
  elseif selection == 8 then --------------------
  
    if reaper.GetToggleCommandState( 40605 ) ~= 1 then
      return reaper.defer(function() end)
    end
    
    local hWnd_action = reaper.JS_Window_Find("Actions", true)
    
    local function SendMsg( number )
      reaper.JS_WindowMessage_Send(hWnd_action, "WM_COMMAND", number, 0, 0, 0)
    end
    
    local hWnd_LV = reaper.JS_Window_FindChildByID(hWnd_action, 1323)
    -- get selected count & selected indexes
    local sel_count, sel_indexes = reaper.JS_ListView_ListAllSelItems(hWnd_LV)
    if sel_count == 0 then
      return reaper.defer(function() end)
    end
    
    local path
    local fisrt_sel_index = tonumber(sel_indexes:match("[^,]+"))
    local lv_header = reaper.JS_Window_HandleFromAddress(reaper.JS_WindowMessage_Send(hWnd_LV, "0x101F", 0,0,0,0)) -- 0x101F = LVM_GETHEADER
    local lv_column_count = reaper.JS_WindowMessage_Send(lv_header, "0x1200" ,0,0,0,0) -- 0x1200 = HDM_GETITEMCOUNT
    
    if lv_column_count == 3 then
      SendMsg(41170) -- show Command ID column
      SendMsg(41387) -- show Command Paths column
      path = reaper.JS_ListView_GetItemText(hWnd_LV, fisrt_sel_index, 4)
      SendMsg(41170)
      SendMsg(41387)
    elseif lv_column_count == 4 then
      last_item = reaper.JS_ListView_GetItemText(hWnd_LV, 0, 3)
      if last_item:match("^_") or last_item:match("%d+") then
        -- show Command Paths column
        SendMsg(41387)
        path = reaper.JS_ListView_GetItemText(hWnd_LV, fisrt_sel_index, 4)
        SendMsg(41387)
      end
    else
      path = reaper.JS_ListView_GetItemText(hWnd_LV, fisrt_sel_index, 4)
    end
    
    if path and path ~= "" then
      local absolute
      local name = reaper.JS_ListView_GetItemText(hWnd_LV, fisrt_sel_index, 1):gsub(".+: ", "", 1)
      local sep = package.config:sub(1,1)
      if string.match(reaper.GetOS(), "Win") then
        if path:match("^%a:\\") or path:match("^\\\\") then
          absolute = true
        end
      else -- unix
        absolute = path:match("^/")
      end
      reaper.CF_LocateInExplorer( (absolute and "" or reaper.GetResourcePath() .. sep .. "Scripts" .. sep) ..
      path .. sep .. name )
    end
    
  else ---------------------
  
    reaper.Main_OnCommand(reaper.NamedCommandLookup(t[selection][2]), 0)
    
  end
end
reaper.defer(function() end)

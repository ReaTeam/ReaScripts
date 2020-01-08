-- @description Track Tags (based on Tracktion 6 track tags)
-- @version 0.4.1
-- @author spk77
-- @changelog
--   - More fixes to auto-deleting obsolete buttons
--   - Fix: store/restore user-definable button width
--   - Fix: store/restore button toggle states
--   - Replaced all "table.remove" functions (table.remove does unnecessary sorting and it's really slow)
--   - Left mouse button now activates one button at a time
--   - CTRL + left mouse button allows activating multiple buttons at a time
--   - Layouts: Don't move selection-type buttons to new row: all buttons can be on a single (first) row
--   - Store/restore initial track visibility states when starting/closing the script
-- @links
--   Forum Thread https://forum.cockos.com/showthread.php?t=203446
-- @donation https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=5NUK834ZGR5NU&lc=FI&item_name=SPK77%20scripts%20for%20REAPER&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted
-- @screenshot https://forum.cockos.com/showpost.php?p=1956530&postcount=1
-- @about
--   # Track Tags
--
--   This script is based on Tracktion 6 track tags
--
--   ## Screenshot
--
--   https://forum.cockos.com/showpost.php?p=1956530&postcount=1
--
--   ## Main Features
--
--   - Show and hide tagged track groups from TCP/MCP
--
--   ## Known Issues/Limitations
--
--   - This is an alpha version

local script =  {
                  version = "0.4.1",
                  title = "Track Tags",
                  project_filename = "",
                  project_id = nil,
                  win_id = -1,
                  debug = false
                }
script.os = reaper.GetOS()


local GUI = {
              last_hovered_element = {},
              dock = 0,
              x = 0,
              y = 0,
              w = 0,
              h = 0,
              win_x = 0,
              win_y = 0,
              win_w = 0,
              win_h = 0,
              bg_col_int = 3355443,
              bg_col_r = 0,
              bg_col_g = 0,
              bg_col_b = 0,
              drag = false,
              drag_start_offset = 10,
              safe_remove_btn_by_index = {},
              safe_remove_track_from_tag = {},        -- remove tagged track from button
              safe_remove_all_tags = false,
              focus_arrange_view = true,
              
              --show_titlebar = true
            }

-- Drag and drop docking
if script.os == "OSX32" or script.os == "OSX64" then
  GUI.reaper_titlebar_h = 22+8 -- reaper's title bar height on macOS is 22 pixels?
else
  GUI.reaper_titlebar_h = 0 -- other OSes: dock when window is at the top of screen
end       
            
GUI.elements =  {
                  buttons = {folder_type = {}, selection_type = {}},
                  panes = {folder_btns = {0,0,0,0}, selection_btns = {0,0,0,0}}
                }
            

local Element = {}

local main_menu =  {
                str = "",
                quit = false,
                button_layout = 1,
                dock_pos_left = (256+1),
                dock_pos_top_left = (2*256+1),
                dock_pos_top_right = (3*256+1),
                dock_pos_right = (0*256+1),
                show_only_tagged_tracks = true,
                button_layout =  1, -- 1=fit to window, 2=horizontal, 3=vertical
                button_ordering = 1, -- 1=by track index, 2=alphabetically
                use_track_color = true,
                show_closest_parent = false
              }


local button_menu = {
                      str = "",
                      show_in_tcp = true,
                      show_in_mcp = true
                    }

local mouse = {
                cap = 0,
                last_cap = 0,
                x = -1,
                y = -1,
                last_x = -1,
                last_y = -1,
                x_screen = -1,
                y_screen = -1,
                last_x_screen = -1,
                last_y_screen = -1,
                ctrl = false,
                shift = false,
                alt = false,
                lmb_down = false,
                lmb_down_time = 0,  
                rmb_down = false,
                rmb_down_time = 0,
                lmb_up_time = 0,
                rmb_up_time = 0,
                ox = -1,
                oy = -1,
                ox_screen = -1,
                oy_screen = -1     
              }

local gui_w, last_gui_w = -1, -1
local gui_h, last_gui_h = -1, -1
local char
local GetProjectStateChangeCount = reaper.GetProjectStateChangeCount
local proj_change_count, last_proj_change_count = -1, -1
local tooltip_text, last_tooltip_text = "", ""


local default_values = {}
default_values.buttons =  {
                            font = "Verdana",
                            font_size = 14,
                      
                            start_x = 8,
                            start_y = 8,
                            w = 80,
                            h = 1.2,              -- times font_size
                            min_w = 48,
                            pad_x = 5,            -- x space between buttons
                            pad_y = 5,            -- y space between buttons
                            edge_radius = 100,
                            edge_thickness = 2,
                      
                            -- Tracktion 6 track tags colors
                            off_bg_col_r = 112/255,
                            off_bg_col_g = 124/255,
                            off_bg_col_b = 137/255,
                            off_bg_col_a = 1,
                      
                            on_bg_col_r = 255/255,
                            on_bg_col_g = 255/255,
                            on_bg_col_b = 26/255,
                            on_bg_col_a = 1
                          }

--default_values.buttons.start_y = default_values.buttons.font_size + 2
--default_values.buttons.h = default_values.buttons.font_size*default_values.buttons.h

local properties = {}
properties.buttons = {} -- will have the same keys as "default_values.buttons" (see "init" function)

local initial_track_visibility_states = {} -- store initial track visibility states (populated in "init" function)

local abs = math.abs
local floor = math.floor
local max = math.max
local sqrt = math.sqrt
local reaper = reaper
local EnumProjects = reaper.EnumProjects
local screen_left, screen_top, screen_right, screen_bottom = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)


local Pickle = { clone = function (t) local nt={}; for i, v in pairs(t) do nt[i]=v end return nt end }

function pickle(t)
  return Pickle:clone():pickle_(t)
end

------------------------------------PICKLE------------------------------------

function Pickle:pickle_(root)
  if type(root) ~= "table" then error("can only pickle tables, not ".. type(root).."s") end
  self._tableToRef = {}
  self._refToTable = {}
  local savecount = 0
  self:ref_(root)
  local s = ""
  
  while #self._refToTable > savecount do
    savecount = savecount + 1
    local t = self._refToTable[savecount]
    s = s.."{\n"
    
    for i, v in pairs(t) do
        s = string.format("%s[%s]=%s,\n", s, self:value_(i), self:value_(v))
    end
    s = s.."},\n"
  end

  return string.format("{%s}", s)
end

function Pickle:value_(v)
  local vtype = type(v)
  if     vtype == "string" then return string.format("%q", v)
  elseif vtype == "number" then return v
  elseif vtype == "boolean" then return tostring(v)
  elseif vtype == "table" then return "{"..self:ref_(v).."}"
  else error("pickle a "..type(v).." is not supported")
  end  
end

function Pickle:ref_(t)
  local ref = self._tableToRef[t]
  if not ref then 
    if t == self then error("can't pickle the pickle class") end
    table.insert(self._refToTable, t)
    ref = #self._refToTable
    self._tableToRef[t] = ref
  end
  return ref
end
----------------------------------------------
-- unpickle
----------------------------------------------
function unpickle(s)
  if type(s) ~= "string" then error("can't unpickle a "..type(s)..", only strings") end
  local gentables = load("return "..s)
  local tables = gentables()
  for tnum = 1, #tables do
    local t = tables[tnum]
    local tcopy = {}; for i, v in pairs(t) do tcopy[i] = v end
    for i, v in pairs(tcopy) do
      local ni, nv
      if type(i) == "table" then ni = tables[i[1]] else ni = i end
      if type(v) == "table" then nv = tables[v[1]] else nv = v end
      t[i] = nil
      t[ni] = nv
    end
  end
  return tables[1]
end
-----------------------------------/PICKLE------------------------------------

------------------------------------------------------------
function shallow_copy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in pairs(orig) do
      copy[orig_key] = orig_value
    end
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end

------------------------------------------------------------
function get_table_size(t)
  local count = 0
  for _, _ in pairs(t) do
    count = count + 1
  end
  return count
end

------------------------------------------------------------
function get_project_filename(proj)
  local ret, proj_filename = reaper.EnumProjects(-1, "")
  if ret then
    return proj_filename
  end
  return ret
end

------------------------------------------------------------
function msg(m)
  if script.debug then
    reaper.ShowConsoleMsg(tostring(m) .. "\n")
  end
end
------------------------------------------------------------
function scroll_to_track(track_id, relative_y_pos, include_envelopes)
  relative_y_pos = relative_y_pos or 0 -- default position is "top"
  local p = "I_WNDH"
  if not include_envelopes then -- include envelope lane heights
    p = "I_TCPH"
  end
  
---[[
  if main_menu.show_only_tagged_tracks then
    return
  end
  if not reaper.ValidatePtr(track_id, "MediaTrack*") then
    return
  end
--]]
  if not reaper.IsTrackVisible(track_id, true) then
    return false
  end
  local tcp_y = reaper.GetMediaTrackInfo_Value(track_id, "I_TCPY")
  local tcp_h = reaper.GetMediaTrackInfo_Value(track_id, p)
  local arrange_id = reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 0x3E8)
  local ok, ar_vsb_position, ar_vsb_page, ar_vsb_min, ar_vsb_max, ar_vsb_trackPos = reaper.JS_Window_GetScrollInfo(arrange_id, "v")
  if ok then
    ok = reaper.JS_Window_SetScrollPos(arrange_id, "v", tcp_y + ar_vsb_position - floor(relative_y_pos*(ar_vsb_page-tcp_h) + 0.5))
  end
  return ok
end

------------------------------------------------------------
function get_track_visibility_states()
  local t = {}
  for i=1, reaper.CountTracks(0) do
    local tr = reaper.GetTrack(0, i-1)
    if tr then
      local tr_guid = reaper.GetTrackGUID(tr)
      reaper.IsTrackVisible(tr, false)
      local show_in_tcp = reaper.GetMediaTrackInfo_Value(tr, "B_SHOWINTCP")
      local show_in_mcp = reaper.GetMediaTrackInfo_Value(tr, "B_SHOWINMIXER")
      t[#t+1] = {
                  tr_guid = tr_guid,
                  show_in_tcp = show_in_tcp,
                  show_in_mcp = show_in_mcp
                }
                
    end
  end
  msg("funtion call: get_track_visibility_states()")
  return t
end

------------------------------------------------------------
function restore_initial_track_visibility_states()
  local t = initial_track_visibility_states
  for i=1, #t do
    local tr = reaper.BR_GetMediaTrackByGUID(0, t[i].tr_guid)
    if reaper.ValidatePtr(tr, "MediaTrack*") then
      reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINTCP", t[i].show_in_tcp)
      reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINMIXER", t[i].show_in_mcp)
    end
  end
  reaper.TrackList_AdjustWindows(false)
  msg("funtion call: restore_initial_track_visibility_states()")
end

------------------------------------------------------------
function setCursorContext()
  local selectedEnv = nil
  local lastCursorContext = reaper.GetCursorContext2(true) -- 0=TCP, 1=items (arrange view), 2=envelopes, -1=unknown
  if lastCursorContext < 0 then -- unknown
    lastCursorContext = 1 -- if unknown, focus will be set to arrange view
  elseif lastCursorContext == 2 then -- envelope
    selectedEnv = reaper.GetSelectedEnvelope(0)
  end
  reaper.SetCursorContext(lastCursorContext, selectedEnv)
end

------------------------------------------------------------
function set_all_tracks_visible(visibility) -- 1 -> show all, 0 -> hide all
  visibility = visibility or 1
  reaper.PreventUIRefresh(1)
  for i=1, reaper.CountTracks(0) do
    local tr = reaper.GetTrack(0, i-1)
    if tr then
      reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINTCP", visibility)
      reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINMIXER", visibility)
    end
  end
  reaper.PreventUIRefresh(-1)
  reaper.TrackList_AdjustWindows(false)
end

------------------------------------------------------------
function sort_buttons()
  local order = ""
  if main_menu.button_ordering == 1 then
    order = "track index"
  else
    order = "alphabetical"
  end
  local btns = GUI.elements.buttons
  local f_btns = btns.folder_type
  local s_btns = btns.selection_type
  if #f_btns < 2 and #s_btns < 2 then
    return
  end

  if #f_btns > 1 then
    local tr
    for i=1, #f_btns do
      tr = f_btns[i].tracks[1] -- parent track
      if not tr then
        break
      end
    end
    if tr then
      if order == "track index" then
        table.sort(f_btns, function(a,b) if reaper.GetMediaTrackInfo_Value(a.tracks[1], "IP_TRACKNUMBER") < reaper.GetMediaTrackInfo_Value(b.tracks[1], "IP_TRACKNUMBER") then return true end end)
      elseif order == "alphabetical" then
        table.sort(f_btns, function(a,b) if string.lower(a.lbl) < string.lower(b.lbl) then return true end end) 
      end
    end
  end
---[[  
  if #s_btns > 1 then
    local tr
    for i=1, #s_btns do
      tr = s_btns[i].tracks[1] -- parent track
      if not tr then
        break
      end
    end
    if tr then
      if order == "track index" then
        table.sort(s_btns, function(a,b) if reaper.GetMediaTrackInfo_Value(a.tracks[1], "IP_TRACKNUMBER") < reaper.GetMediaTrackInfo_Value(b.tracks[1], "IP_TRACKNUMBER") then return true end end)  
      elseif order == "alphabetical" then
        table.sort(s_btns, function(a,b) if string.lower(a.lbl) < string.lower(b.lbl) then return true end end) 
      end
    end
  end
--]]
end



------------------------------------------------------------
function update_visibility()
  msg("update_visibility")
  local btns = GUI.elements.buttons
  --if #btns == 0 then return end
  reaper.PreventUIRefresh(1)
  if main_menu.show_only_tagged_tracks then
    local all_btns_off = true
    local tr_count = reaper.CountTracks(0)
    set_all_tracks_visible(0) -- hide all
    
    for _,v in pairs(btns) do
      for i=1, #v do
        local b = v[i]
        --b.show_mixer = true
        if b.toggle_state then
          reaper.CSurf_OnScroll(0, -100000)
          if all_btns_off then
            all_btns_off = false
          end
          for t=1, #b.tracks do
            local tr = b.tracks[t]
            
            if reaper.ValidatePtr(tr, "MediaTrack*") then
---[[ Show closest parent track
              if main_menu.show_closest_parent and t == 1 and b.type == "folder parent" then
                local par_tr = reaper.GetParentTrack(tr)
                if par_tr then
                  reaper.SetMediaTrackInfo_Value(par_tr, "B_SHOWINTCP", 1)
                  reaper.SetMediaTrackInfo_Value(par_tr, "B_SHOWINMIXER", 1)
                end
              end
--]]
              reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINTCP", 1)
              reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINMIXER", 1)
            else
              --GUI.safe_remove_track_from_tag[#GUI.safe_remove_track_from_tag + 1] = {i, t} -- i = button index, t = track index
            end
          end
        end
      end
    end
    

    if all_btns_off then
      set_all_tracks_visible(1)
    else
      -- Unselected items in hidden tracks (if hidden from TCP)
      for i=1, tr_count do
        local tr = reaper.GetTrack(0, i-1)
        if not reaper.GetMediaTrackInfo_Value(tr, "B_SHOWINTCP") then
          local item_count = reaper.CountTrackMediaItems(tr)
          for j=1, item_count do
            local item = reaper.GetTrackMediaItem(tr, j-1)
            if item and reaper.IsMediaItemSelected(item) then
              reaper.SetMediaItemSelected(item, false)
            end
          end
        end      
      end
    end
  else -- main_menu.show_only_tagged_tracks is false
    set_all_tracks_visible(1)
  end
  reaper.PreventUIRefresh(-1)
  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()
  store_btns()
end

------------------------------------------------------------
function show_main_menu(x, y)
  gfx.x, gfx.y = x or gfx.mouse_x, y or gfx.mouse_y
  local m = main_menu
  --m.str = "Create new tag|"
  m.str = ">Create new tag(s) from...|"
  if reaper.CountSelectedTracks(0) > 0 then
    m.str = m.str .. "Track selection|"
  else
    m.str = m.str .. "#Track selection|"
  end
  m.str = m.str .."<Folder parent tracks|"

  m.str = m.str .. "Dock||" 
  
  m.str =  m.str .. ">Options|"
  
  m.str = m.str .. ">Layout|"
  if m.button_layout == 1 then
    m.str = m.str .. "!Fit to window - fill rows first|"
    m.str = m.str .. "Horizontal|"
    m.str = m.str .. "<Vertical||"
  elseif m.button_layout == 2 then
      m.str = m.str .. "Fit to window - fill rows first|"
      m.str = m.str .. "!Horizontal|"
      m.str = m.str .. "<Vertical||"
  elseif m.button_layout == 3 then
    m.str = m.str .. "Fit to window - fill rows first|"
    m.str = m.str .. "Horizontal|"
    m.str = m.str .. "!<Vertical||"
  end
  
  m.str =  m.str .. ">Sort buttons...|"
  if main_menu.button_ordering == 1 then
    m.str =  m.str .. "!by track index|"
    m.str =  m.str .. "<alphabetically|"
  else
    m.str =  m.str .. "by track index|"
    m.str =  m.str .. "<!alphabetically|"
  end
 
  if m.fixed_sized_buttons then
    m.str =  m.str .. "!Use fixed-sized buttons|"
  else
    m.str =  m.str .. "Use fixed-sized buttons|"
  end
  
  m.str =  m.str .. "Set button properties||"
  
  m.str =  m.str .. ">'Drag and drop docking'|"
  if gfx.dock(-1) > 0 then
    m.str =  m.str .. "Store current dock position as 'Left'|"
    m.str =  m.str .. "Store current dock position as 'Top-Left'|"
    m.str =  m.str .. "Store current dock position as 'Top-Right'|"
    m.str =  m.str .. "<Store current dock position as 'Right'|"
  else
    m.str =  m.str .. "#Store current dock position as 'Left'|"
    m.str =  m.str .. "#Store current dock position as 'Top-Left'|"
    m.str =  m.str .. "#Store current dock position as 'Top-Right'|"
    m.str =  m.str .. "<#Store current dock position as 'Right'|"
  end
 
  m.str = m.str .. "><Remove|"
  m.str = m.str .. "<All tags||"
  
  m.str =  m.str .. ">Folder tags|"
  if main_menu.show_closest_parent then
    m.str =  m.str .. "<!Show closest parent track||"
  else
    m.str =  m.str .. "<Show closest parent track||"
  end
  
  m.str =  m.str .. "Quit||"
  m.str =  m.str .. "#Track Tags v." .. script.version
   menu_ret = gfx.showmenu(m.str)

  -- Handle menu return values
  if menu_ret == 1 then
    create_button_from_selection()
  elseif menu_ret == 2 then
    create_buttons_from_folder_parents(false)
  elseif menu_ret == 3 then
    local dock_state = gfx.dock(-1)
    if dock_state&1 == 0 then
      gfx.dock(dock_state+1)
    else
      gfx.dock(dock_state-1)
    end
    GUI.dock = dock_state
    
  elseif menu_ret == 4 then
    m.button_layout = 1
    update_button_positions()
  elseif menu_ret == 5 then
    m.button_layout = 2
    update_button_positions()
  elseif menu_ret == 6 then
    m.button_layout = 3
    update_button_positions()
  
  elseif menu_ret == 7 then
    main_menu.button_ordering = 1
    sort_buttons()
    update_button_positions()
  elseif menu_ret == 8 then
    main_menu.button_ordering = 2
    sort_buttons()
    update_button_positions()
    
  elseif menu_ret == 9 then
    m.fixed_sized_buttons = not m.fixed_sized_buttons
    update_all_buttons_w()
    update_button_positions()

    
  elseif menu_ret == 10 then
    get_user_inputs()
  elseif menu_ret == 11 then
    main_menu.dock_pos_left = gfx.dock(-1)
  elseif menu_ret == 12 then
    main_menu.dock_pos_top_left = gfx.dock(-1)
  elseif menu_ret == 13 then
    main_menu.dock_pos_top_right = gfx.dock(-1)
  elseif menu_ret == 14 then
    main_menu.dock_pos_right = gfx.dock(-1)
  elseif menu_ret == 15 then
    ----GUI.safe_remove_all_tags = true
    GUI.elements.buttons = {folder_type = {}, selection_type = {}}
    update_visibility()
  elseif menu_ret == 16 then
    main_menu.show_closest_parent = not main_menu.show_closest_parent
    update_folder_type_tag_buttons()
    update_visibility()
  elseif menu_ret == 17 then
    --exit()
    main_menu.quit = true
  end
end

------------------------------------------------------------
function get_user_inputs()
  local p = properties.buttons
  local default_vals =  tostring(p.start_x) .."," .. 
                        tostring(p.start_y) .. "," ..
                        tostring(p.w) .. "," ..
                        tostring(p.h) .. "," ..
                        tostring(p.pad_x) .. "," ..
                        tostring(p.pad_y) .. "," ..
                        tostring(p.edge_radius) .. "," ..
                        tostring(p.edge_thickness)
  local captions = "Margin-left,Margin-top,Width,Height (1-2) * font height,Horizontal spacing,Vertical spacing,Edge radius (0-100),Edge thickness (1-5),extrawidth=200"
  local retval, retvals_csv = reaper.GetUserInputs("Button settings (leave empty for default values)", 8, captions, default_vals)
  if not retval then return end
  local i = 1
  for word in retvals_csv:gmatch("([^,]*)") do
    if word ~= "" and tonumber(word) == nil then
      return
    end
    if word == "" then
      if i==1 then
        properties.buttons.start_x = default_values.buttons.start_x
      elseif
        i==2 then
        properties.buttons.start_y = default_values.buttons.start_y
      elseif
        i==3 then
        properties.buttons.w = default_values.buttons.w
      elseif
        i==4 then
        properties.buttons.h = default_values.buttons.h
      elseif
        i==5 then
        properties.buttons.pad_x = default_values.buttons.pad_x
      elseif
        i==6 then
        properties.buttons.pad_y = default_values.buttons.pad_y
      elseif
        i==7 then
        properties.buttons.edge_radius = default_values.buttons.edge_radius
      elseif
        i==8 then
        properties.buttons.edge_thickness = default_values.buttons.edge_thickness
      end
    else
      local val = tonumber(word)
      if i==1 then
        properties.buttons.start_x = val
      elseif
        i==2 then
        properties.buttons.start_y = val
      elseif
        i==3 then
        properties.buttons.w = val
      elseif
        i==4 then
        if val < 1 then val = 1 elseif val > 2 then val = 2 end
        properties.buttons.h = val
      elseif
        i==5 then
        properties.buttons.pad_x = val
      elseif
        i==6 then
        properties.buttons.pad_y = val
      elseif
        i==7 then
        if val < 0 then val = 0 elseif val > 100 then val = 100 end
        properties.buttons.edge_radius = val
      elseif
        i==8 then
        if val < 1 then val = 1 elseif val > 5 then val = 5 end
        properties.buttons.edge_thickness = val
      end
    end
    i = i+1
  end
  update_all_buttons_w()
  update_button_positions()
end


------------------------------------------------------------
local function roundrect(x, y, w, h, r, fill, antialias)
  --[[
    Wrapper for gfx.roundrect() with optional fill,
    adapted from mwe's EEL example on the forum.
    
    by Lokasenna
  ]]--
  r = floor(r)
  local aa = antialias or 1
  -- If we aren't filling it in, the original function is fine
  if fill == 0 or false then
    gfx.roundrect(x, y, w, h, r, aa)
    
  else
    
    -- Corners
    gfx.circle(x + r, y + r, r, 1, aa)
    gfx.circle(x + w - r, y + r, r, 1, aa)
    gfx.circle(x + w - r, y + h - r, r , 1, aa)
    gfx.circle(x + r, y + h - r, r, 1, aa)
    
    -- Ends
    gfx.rect(x, y + r, r, h - r * 2)
    gfx.rect(x + w - r, y + r, r + 1, h - r * 2)
      
    -- Body + sides
    gfx.rect(x + r, y, w - r * 2, h + 1)
  end  
  
end

------------------------------------------------------------
function Element:new(x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, lbl_r, lbl_g, lbl_b, lbl_a, norm_val, toggle_state)
    local elm = {}
    --elm.def_xywh = {x,y,w,h,fnt_sz}
    elm.x, elm.y, elm.w, elm.h = x or 0, y or 0, w or 100, h or 20
    elm.r, elm.g, elm.b, elm.a = r or 1, g or 1, b or 1, a or 1
    elm.lbl, elm.fnt, elm.fnt_sz  = lbl or "label", fnt or "Verdana", fnt_sz or 14
    elm.lbl_r, elm.lbl_g, elm.lbl_b, elm.lbl_a = lbl_r or 0.5, lbl_g or 0.5, lbl_b or 0.5, lbl_a or 1
    elm.norm_val = norm_val
    elm.toggle_state = toggle_state or false
    setmetatable(elm, self)
    self.__index = self 
    return elm
end

------------------------------------------------------------
function extended(Child, Parent)
  setmetatable(Child,{__index = Parent})
end

------------------------------------------------------------
function Element:pointIN(p_x, p_y)
  return p_x >= self.x and p_x <= self.x + self.w and p_y >= self.y and p_y <= self.y + self.h
end

------------------------------------------------------------
function Element:mouseIN()
  --return gfx.mouse_cap & 1 == 0 and gfx.mouse_cap & 2 == 0 and self:pointIN(gfx.mouse_x,gfx.mouse_y)
  return self:pointIN(mouse.x, mouse.y)
end

------------------------------------------------------------
function Element:mouseLDown()
  return gfx.mouse_cap & 1 == 1 and self:pointIN(mouse.ox, mouse.oy)
end

------------------------------------------------------------
function Element:mouseRDown()
  return gfx.mouse_cap & 2 == 2 and self:pointIN(mouse.ox, mouse.oy)
end

------------------------------------------------------------
function Element:mouseLmbRelease()
  return mouse.cap & 1 == 0 and mouse.last_cap & 1 == 1 and
  self:pointIN(mouse.x, mouse.y)-- and self:pointIN(mouse.ox, mouse.oy)         
end

------------------------------------------------------------
function Element:mouseRmbRelease()
  return mouse.cap & 2 == 0 and mouse.last_cap & 2 == 2 and
  self:pointIN(mouse.x, mouse.y)-- and self:pointIN(mouse.ox, mouse.oy)         
end

------------------------------------------------------------
function Element:mouseUp()
  --return gfx.mouse_cap & 1 == 0 and self:pointIN(mouse_ox, mouse_oy)
  return mouse.last_cap&1 == 1 and self:pointIN(mouse.click_pos_x, mouse.click_pos_y)
end


------------------------------------------------------------
local Button = {}
extended(Button, Element)
------------------------------------------------------------
local Pane = {}
extended(Pane, Element)

------------------------------------------------------------
function Button:set_lbl_color(r,g,b,a)
  self.lbl_r = r or 1
  self.lbl_g = g or 1
  self.lbl_b = b or 1
  self.lbl_a = a or 1
end

------------------------------------------------------------
function Button:set_color(r,g,b,a)
  self.r = r or 1
  self.g = g or 1
  self.b = b or 1
  self.a = a or 1
end

------------------------------------------------------------
function Button:set_to_default_color()
  local d = default_values.buttons
  if self.toggle_state then
    self:set_color(d.on_bg_col_r, d.on_bg_col_g, d.on_bg_col_b, d.on_bg_col_a)
    self:set_lbl_color(0,0,0,1)
  else
    self:set_color(d.off_bg_col_r, d.off_bg_col_g, d.off_bg_col_b, d.off_bg_col_a)
    self:set_lbl_color(1,1,1,1)
  end
end

------------------------------------------------------------
function Button:set_color_to_track_color()
  local tr = self.tracks[1]
  if not main_menu.use_track_color or not tr then
    self:set_to_default_color()
  else
    --if not tr then return end
    local tr_color = reaper.GetTrackColor(tr)
    if tr_color == 0 then 
      self:set_to_default_color()
    else
      self.r, self.g, self.b = color_int_to_rgb(tr_color)
      local r,g,b = self.r*255, self.g*255, self.b*255
      if self.toggle_state then
        local brightness = sqrt(0.241*r*r + 0.691*g*g + 0.068*b*b)
        -- if brightness < 130
        if brightness < 146.8 then
          r,g,b = 1,1,1
        else
          r,g,b = 0,0,0
        end
      else
        r,g,b = 1,1,1
      end
      self:set_lbl_color(r, g, b, 1)
    end
  end
end

------------------------------------------------------------
function update_buttons_color()
  msg("function call: update_buttons_color()")
  local btns = GUI.elements.buttons
  for k, v in pairs(btns) do
    for i=1, #v do
      local btn = v[i]
      btn:set_color_to_track_color()
    end
  end
end

------------------------------------------------------------
function color_int_to_rgb(color_int)
  local r,g,b = reaper.ColorFromNative(color_int)
  --r = color_int & 255
  --g = (color_int >> 8) & 255
  --b = (color_int >> 16) & 255
  r = r/255
  g = g/255
  b = b/255
  return r, g, b
end

------------------------------------------------------------
function update_all_buttons_w()
  local btns = GUI.elements.buttons
  for _,v in pairs(btns) do
    for i=1, #v do 
      local b = v[i]
      b:update_lbl_size()
      --b.lbl_w, b.lbl_h = gfx.measurestr(b.lbl)
      if main_menu.fixed_sized_buttons then
        b.w = properties.buttons.w
      else
        --b.w = math.max(b.lbl_w+10, default_values.buttons.min_w)
        b.w = floor(max(b.lbl_w + 20, properties.buttons.min_w))
      end
      if properties.buttons.h < 1 then properties.buttons.h = 1
      elseif properties.buttons.h > 2 then properties.buttons.h = 2 end
      b.h = floor(b.lbl_h*properties.buttons.h+0.5)--+properties.buttons.h
    end
  end
end

------------------------------------------------------------
function Button:set_other_buttons_off(btn_index)
  local btns = GUI.elements.buttons
  local is_other_buttons_active = false
  for _,v in pairs(btns) do
    for i=1, #v do 
      local b = v[i]
      if i ~= btn_index then
        if not is_other_buttons_active and b.toggle_state then
          is_other_buttons_active = true
        end 
        b.toggle_state = false
        b:set_color_to_track_color()
      end
    end
  end
  if is_other_buttons_active then
    -- keep button active (behaves the same way as when clicking on a track on TCP or MCP)
    self.toggle_state = true 
  end
end

------------------------------------------------------------
function Button:create_tracks_table_from_guids_table()
  self.tracks = {}
  if #self.track_guids == 0 then
    return
  end
  local n = #self.tr_guids
  for i = 1, n do
    local guid = self.track_guids[i]
    local tr = reaper.BR_GetMediaTrackByGUID(0, guid)
    if reaper.ValidatePtr(tr, "MediaTrack*") then
      self.tracks[self.tracks + 1] = tr -- collect valid track pointers
    end
  end
end


------------------------------------------------------------
-- Checks if tracks (guids) are still valid, removes invalid guids and
--   possible gaps from "track_guids" -table
-- Also creates a table from track pointers
-- Returns guids and track pointers in separate tables
function validate_track_guids(guid_table)
  msg("function call: validate_track_guids()")
  guid_table = guid_table or {}
  local track_ids = {}
  local new_index = 1
  local n = #guid_table
  for old_index = 1, n do
    local guid = guid_table[old_index]
    local tr = reaper.BR_GetMediaTrackByGUID(0, guid)
    if reaper.ValidatePtr(tr, "MediaTrack*") then
      track_ids[#track_ids + 1] = tr
      -- Move old_index's kept value to new_index's position, if it's not already there.
      if old_index ~= new_index then
        guid_table[new_index] = guid_table[old_index]
        guid_table[old_index] = nil
      end
      new_index = new_index + 1 -- Increment position of where we'll place the next kept value.
    else
      guid_table[old_index] = nil
    end
  end
  return guid_table, track_ids
end

------------------------------------------------------------
-- Checks if tracks (guids) are still valid, removes invalid guids and
-- removes gaps from button's "track_guids" and "tracks" -tables
-- Returns "track_guids" and "tracks" -tables
function Button:validate_track_guids()
  self.track_guids, self.tracks = validate_track_guids(self.track_guids)
--[[
  if #self.track_guids == 0 then
    return
  end
  local new_tr_index = 1
  local n = #self.track_guids
  self.tracks = {}
  for old_tr_index = 1, n do
    local guid = self.track_guids[old_tr_index]
    local tr = reaper.BR_GetMediaTrackByGUID(proj_id, guid)
    if reaper.ValidatePtr(tr, "MediaTrack*") then
      self.tracks[#self.tracks + 1] = tr -- collect valid track pointers
      -- Move old_tr_index's kept value to new_tr_index's position, if it's not already there.
      if old_tr_index ~= new_tr_index then
        self.track_guids[new_tr_index] = self.track_guids[old_tr_index]
        self.track_guids[old_tr_index] = nil
      end
      new_tr_index = new_tr_index + 1; -- Increment position of where we'll place the next kept value.
    else
      self.track_guids[old_tr_index] = nil
    end
  end
  return self.track_guids, self.tracks
--]]
end
      
------------------------------------------------------------
function Button:update_lbl_size(w, h)
  local w, h = gfx.measurestr(self.lbl)
  self.lbl_w, self.lbl_h = w or self.w, h or self.h
end

------------------------------------------------------------
function Button:update_w_by_lbl_w(min_w, max_w)
  --self.lbl_w, self.lbl_h = gfx.measurestr(self.lbl)
  if main_menu.fixed_sized_buttons then
    --self.w = default_values.buttons.w
    self.w = properties.buttons.w
  else
    self.w = floor(max(self.lbl_w + 20, properties.buttons.min_w))
  end
  if properties.buttons.h < 1 then properties.buttons.h = 1
  elseif properties.buttons.h > 2 then properties.buttons.h = 2 end
  self.h = floor(self.lbl_h*properties.buttons.h+0.5)--+properties.buttons.h
end

------------------------------------------------------------
function Button:draw_lbl()
  local x, y, w, h = self.x, self.y, self.w, self.h
  local fnt, fnt_sz = self.fnt, self.fnt_sz
  local r, g, b, a = self.lbl_r, self.lbl_g, self.lbl_b, self.lbl_a
  gfx.set(r, g, b, a)
  gfx.x = x
  gfx.y = y
  if self.lbl_w > self.w then -- or main_menu.use_track_color then
    gfx.drawstr(self.lbl, 0|4, x+w, y+h)
  else
    gfx.drawstr(self.lbl, 1|4, x+w, y+h)
  end
end

------------------------------------------------------------
function Button:draw(index)
  local x,y,w,h  = self.x, self.y, self.w, self.h
  local tr = self.tracks[1]
  -- Draw info string
  if self:mouseIN() then
  -- Button info text
  --[[
    gfx.set(1,1,1,1)
    gfx.x = properties.buttons.start_x
    gfx.y = 0
    
    gfx.drawstr(self.lbl)
    --gfx.drawstr(self.lbl, 0|4, gfx.w, gfx.texth)
  --]]
    if self.onMouseOver then
    end
  end
  
  local r,g,b,a  = self.r,self.g,self.b,self.a
  gfx.set(r,g,b,a)
  
  local edge_thickness = properties.buttons.edge_thickness
  local radius = properties.buttons.edge_radius/100*0.5*h

  if self.toggle_state then
    roundrect(x,y,w,h,radius,1)
  else
    roundrect(x,y,w,h,radius,1)
    --local bg_col_int = 3355443
    local r = GUI.bg_col_r
    local g = GUI.bg_col_g
    local b = GUI.bg_col_b
    gfx.set(r,g,b)
    radius = radius - edge_thickness
    if radius < 0 then
      radius = 0
    end
    roundrect(x+edge_thickness,y+edge_thickness,w-2*edge_thickness,h-2*edge_thickness,radius,1)
  end
  self:draw_lbl()
  return x,y,w,h
end

------------------------------------------------------------
function Pane:handle_mouse_events(pane_index)
  if self:mouseLDown() then
    self.y = mouse.y
    if GUI.drag then
      GUI.drag = false
    end
  end
  if self:mouseLmbRelease() then
    --self.toggle_state = not self.toggle_state
    if self.toggle_state then
    else
    end
    self.onLmbRelease()
  elseif self:mouseRmbRelease() then
    self.onRmbRelease(btn_index)
  else
 end
end

------------------------------------------------------------
function Button:handle_mouse_events(btn_index)
  local tr = self.tracks[1]
  self:set_color_to_track_color()
  if self:mouseLmbRelease() then
    if main_menu.show_only_tagged_tracks then
      self.toggle_state = not self.toggle_state
      if not mouse.ctrl then-- and self.toggle_state then
        self:set_other_buttons_off(btn_index)
      end
    else
      scroll_to_track(tr)
    end
    if self.toggle_state then
    else
    end
    
    self.onLmbRelease()
  elseif self:mouseRmbRelease() then
    self.onRmbRelease(btn_index)
  else
  end
end

------------------------------------------------------------
function update_button_positions(w, h)
  msg("function call: update_button_positions()")
  local btns = GUI.elements.buttons
  local f_btns = btns.folder_type
  local s_btns = btns.selection_type
  local len_f_btns = #f_btns
  local len_s_btns = #s_btns
  if len_f_btns == 0 and len_s_btns == 0 then
    return
  end
  --local max_r, max_b = 0, 0
  local p = properties.buttons

  local w, h = w or gfx.w, h or gfx.h
  local x = p.start_x
  local y = p.start_y
  local layout = main_menu.button_layout
  local curr_row = 1
  local curr_col = 1

  for i=1, len_f_btns do
    local b = f_btns[i]
    -- fit to window - fill rows first
    if layout == 1 then
      if x + b.w > w then
        x = p.start_x
        if curr_col > 1 then
          y = y + b.h + p.pad_y
          curr_row = curr_row + 1
        end
      end
    -- horizontal
    elseif layout == 2 then
    -- vertical
    elseif layout == 3 then  
      y = p.start_y + (curr_row-1)*(b.h + p.pad_y)
      curr_row = curr_row + 1
    end
    
    b.x = x
    b.y = y
    
    if layout < 3 then
      x = x + b.w + p.pad_x
      curr_col = curr_col + 1
    end
    if b.w < p.min_w then
      p.min_w = b.w
    end
  end
  
  if #f_btns == 0 then
    x = p.start_x
    y = p.start_y
    curr_row = 1
    curr_col = 1
  end

  for i=1, len_s_btns do
    local b = s_btns[i]
    -- fit to window - fill rows first
    if layout == 1 then
      if x + b.w > w then
        x = p.start_x
        if curr_col > 1 then
          y = y + b.h + p.pad_y
          curr_row = curr_row + 1
        end
      end
    -- horizontal
    elseif layout == 2 then
    -- vertical
    elseif layout == 3 then  
      y = p.start_y + (curr_row-1)*(b.h + p.pad_y)
      curr_row = curr_row + 1
    end
    
    b.x = x
    b.y = y
    
    if layout < 3 then --or (i>1 and layout == 4 and y+b.h > h) then
      x = x + b.w + p.pad_x
      curr_col = curr_col + 1
    end
    if b.w < p.min_w then
      p.min_w = b.w
    end
  end
  return x,y
end

------------------------------------------------------------
function on_gui_resize(w, h)
  GUI.dock, GUI.x, GUI.y, GUI.w, GUI.h = gfx.dock(-1,0,0,0,0)
  update_button_positions(w, h)
end

---[[
------------------------------------------------------------                       
function draw_and_update_buttons()
  local button_count = 0
  --local x,y,w,h
  for _,v in pairs(GUI.elements.buttons) do
    for i=1, #v do
      local t = v[i]
      --x,y,w,h = t:draw(i)
      t:draw(i)
      button_count = button_count+1
    end
  end
  if button_count == 0 then
    gfx.x, gfx.y = 8,8
    gfx.set(1,1,1,1)
    gfx.drawstr("No tags assigned\nRight click to open the menu") 
    return gfx.x, gfx.y, gfx.w, gfx.h
  end
end

------------------------------------------------------------                       
function draw_panes(tbl)
  local p = GUI.elements.panes
  local l = #p
  for i=1, l do
    local pane = p[i]
    pane:draw(i)
  end
  local x = p[l].x or gfx.x
  local y = p[l].y or gfx.y
  local w = p[l].w or properties.buttons.w
  local h = p[l].h or properties.buttons.h
  return x, y, w, h
end


------------------------------------------------------------
function create_button(btn_type)
  --local btns = GUI.elements.buttons
  local folder_type_btns = GUI.elements.buttons.folder_type
  local selection_type_btns = GUI.elements.buttons.selection_type
  local d = default_values.buttons
  local btn = Button:new(   
                          0,                    --  x
                          0,                    --  y 
                          d.w,                  --  w
                          d.h,                  --  h
                          0.5,                  --  r
                          0.5,                  --  g
                          0.5,                  --  b
                          1.0,                  --  a
                          "Tag " .. #GUI.elements.buttons.selection_type + 1,  --  lbl (button name)
                          "Arial",              --  label font
                          14,                   --  label font size
                          1,                    -- label color r
                          1,                    -- label color g
                          1,                    -- label color b
                          1,                    -- label color a
                          0,                    -- norm_val
                          false                 -- toggle state
                        )
  
  ----btn:set_color(112/255, 124/255, 137/255, 1)
  btn.tracks = {}
  btn.track_guids = {} -- from version 0.2.6 ->
  btn.type = btn_type or ""
  btn.tooltip_text = ""
  btn.lbl_w, btn.lbl_h = gfx.measurestr(btn.lbl)
  --btn:update_lbl_size()
  btn.track_color = {r=0,g=0,b=0}

  btn.onLmbRelease =  function()
                        update_visibility()
                        --store_btns()
                      end
                  
  btn.onRmbRelease =  
                  function(buttonindex)
                    gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
                    local m = button_menu
                    --m.str = "#" .. "Button type: " .. btn.type .. "||"
                    m.str = "Rename tag|"
                    m.str = m.str .. "Remove tag|"
                    m.str = m.str .. "Update tag||"
                    if btn.type == "selection" then
                      m.str = m.str .. "#"
                    elseif btn.type == "folder parent" then
                      if btn.show_only_parent then 
                        m.str = m.str .. "!"
                      end
                      
                    end
                    m.str = m.str .. "Show only parent track|"
                    --[[
                    m.str = m.str .. ">Options|"
                    if button_menu.show_in_tcp then
                      m.str = m.str .. "Show in TCP|"
                    else
                      m.str = m.str .. "!Show in TCP|"
                    end
                    
                    if button_menu.show_in_mcp then
                      m.str = m.str .. "Show in TCP|"
                    else
                      m.str = m.str .. "!Show in TCP|"
                    end
                    m.str = m.str .. "Show Mixer|"
                    --]]
                    local ret = gfx.showmenu(m.str)
                    if ret == 1 then
                      local retval, retvals_csv = reaper.GetUserInputs("Rename", 1, "Set new tag name:", btn.lbl)
                      if retval then
                        btn.lbl = retvals_csv
                        btn:update_lbl_size(w, h)
                        btn:update_w_by_lbl_w()
                        --btn:update_lbl_size()
                        --update_all_buttons_w()
                      end
                      sort_buttons()
                      update_button_positions()
                    elseif ret == 2 then
                      btn.tracks = {}
                      btn.track_guids = {}
-- TODO: remove by index
                      -- button is automatically removed if button's "tracks" -table is empty
                      remove_obsolete_buttons()
                      update_button_positions()
                      --update_folder_type_tag_buttons()
                    elseif ret == 3 then
                      -- X-Raym mod
                      btn.type = "selection"
                      btn.tracks = {}
                      btn.track_guids = {}
                      local sel_tr_count = reaper.CountSelectedTracks(0)
                      for i=1, sel_tr_count do
                        local tr = reaper.GetSelectedTrack(0, i-1)
                        local retval, tr_name = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
                        btn.tracks[#btn.tracks+1] = tr
                        btn.track_guids[#btn.track_guids+1] = reaper.GetTrackGUID(tr) -- from version 0.2.6 ->
                        btn.tooltip_text = btn.tooltip_text .. tr_name .. "\n"
                      end
                    elseif ret == 4 then
                      btn.show_only_parent = not btn.show_only_parent
                      update_folder_type_tag_buttons()
                      update_visibility()
                    end
                  end
  
  btn.onMouseOver = function()
                    end
  

  btn.id = reaper.genGuid()
  if btn.type == "folder parent" then
    folder_type_btns[#folder_type_btns+1] = btn
  elseif  btn.type == "selection" then
    selection_type_btns[#selection_type_btns+1] = btn
  end
  
  --btns[#btns + 1] = btn
  --btn:update_w_by_lbl_w()
  
  update_button_positions()
  sort_buttons()
  
  btn.tooltip_text = ""--btn.lbl
  --msg(btn.lbl)
  return btn
end

------------------------------------------------------------
function create_button_from_selection()
  local sel_tr_count = reaper.CountSelectedTracks(0)
  if sel_tr_count == 0 then
    return
  end
  
  local def_name = "Tag"
  local tr = reaper.GetSelectedTrack(0, 0)
  if tr then
    local retval, tr_name = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if retval and tr_name ~= "" then
      def_name = tr_name
    end
      
  end
  
  local retval, retvals_csv = reaper.GetUserInputs("New tag from selection", 1, "Tag name:", def_name)
  if not retval then
    return
  end
  local btns = GUI.elements.buttons
  local btn = create_button("selection")
  btn.lbl = retvals_csv
  --btn.type = "selection"
  for i=1, sel_tr_count do
    local tr = reaper.GetSelectedTrack(0, i-1)
    local retval, tr_name = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    btn.tracks[#btn.tracks+1] = tr
    btn.track_guids[#btn.track_guids+1] = reaper.GetTrackGUID(tr) -- from version 0.2.6 ->
    btn.tooltip_text = btn.tooltip_text .. tr_name .. "\n"
  end
  --btn:update_w_by_lbl_w()
  update_all_buttons_w()
  sort_buttons()
  update_button_positions()
  update_buttons_color()
  ----store_btns()
end

------------------------------------------------------------
function update_child_tracks(parent_tr, tag_button, tag_button_index)
  if not reaper.ValidatePtr(parent_tr, "MediaTrack*") then
    GUI.safe_remove_btn_by_index[#GUI.safe_remove_btn_by_index+1] = {tag_button_index, "folder parent"}
    return
  end
  local parent_tr_index = reaper.CSurf_TrackToID(parent_tr, false) - 1
  local depth = 1
  local tr_count = reaper.CountTracks(0)
  for i=2, #tag_button.tracks do -- remove all child tracks
    tag_button.tracks[i] = nil
    tag_button.track_guids[i] = nil -- from version 0.2.6 ->
  end
  if tag_button.show_only_parent then
    return
  end
  
  -- "Tag" child tracks
  for j=parent_tr_index+1, tr_count-1 do
    local child_tr = reaper.GetTrack(0, j)
    local retval, tr_name = reaper.GetSetMediaTrackInfo_String(child_tr, "P_NAME", "", false)
    if retval then
      tag_button.tooltip_text = tag_button.tooltip_text .. tr_name .. "\n"
      if tr_name == "" then
        tr_name = "Track " .. tostring(floor(reaper.GetMediaTrackInfo_Value(child_tr, "IP_TRACKNUMBER")))
      end
    end
    depth = depth + reaper.GetMediaTrackInfo_Value(child_tr, "I_FOLDERDEPTH")
    tag_button.tracks[#tag_button.tracks + 1] = child_tr
    tag_button.track_guids[#tag_button.track_guids+1] = reaper.GetTrackGUID(child_tr)
    if depth <= 0 then
      break
    end
  end
end

------------------------------------------------------------
function update_folder_type_tag_buttons()
  msg("Function call: update_folder_type_tag_buttons()")
  local btns = GUI.elements.buttons.folder_type
  local len_btns = #btns
  for i = 1, len_btns do
    local btn = btns[i]
    btn:validate_track_guids()
    if #btn.tracks > 0 then
      local tr = btn.tracks[1] -- parent track is the first track in "tracks" -table
      if reaper.GetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH") == 1 then -- still a folder parent?
        btn:set_color_to_track_color()
        update_child_tracks(tr, btn, i)
      else
        btn.tracks = {}
        btn.track_guids = {}
      end
    end
  end
  --store_btns()
end

------------------------------------------------------------
function update_custom_type_tag_buttons()
  msg("Function call: update_custom_type_tag_buttons()")
  local btns = GUI.elements.buttons.selection_type
  local len_btns = #btns
  for i = 1, len_btns do
    local btn = btns[i]
    btn:validate_track_guids()
  end
end

------------------------------------------------------------
function create_buttons_from_folder_parents()
  local btns = GUI.elements.buttons.folder_type
  local tr_count = reaper.CountTracks(0)
  for i=1, tr_count do
    local tr = reaper.GetTrack(0, i-1)
    local depth_change = reaper.GetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH")
    if depth_change == 1 then -- folder parent found
      local btn
      local btn_index
      local is_parent_tagged = false
      for i=1, #btns do
        btn = btns[i]
        -- Folder parent track is always the first track
        if btn.tracks[1] == tr and btn.type == "folder parent" then
          is_parent_tagged = true -- Tag-button is already created
          btn_index = i
          break 
        end
      end
      
      -- Not tagged yet? (button doesn't exist)
      if not is_parent_tagged then
         --Create tag-button
        btn = create_button("folder parent")
        btn.tracks[#btn.tracks+1] = tr -- Tag parent track
        btn.track_guids[#btn.track_guids+1] = reaper.GetTrackGUID(tr)
        btn_index = #btn.tracks
        --btn.type = "folder parent"
        local retval, tr_name = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
        if retval then
          btn.tooltip_text = btn.tooltip_text .. tr_name .. "\n"
          if tr_name == "" then
            tr_name = "Track " .. tostring(floor(reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")))
          end
          btn.lbl = tr_name
          --btn:update_w_by_lbl_w()
        end
        --local r,g,b = reaper.ColorFromNative(reaper.GetTrackColor(tr))
        --btn.track_color = {r=r,g=g,b=b}
        update_child_tracks(tr, btn, btn_index)
      end
    end    
  end
  sort_buttons()
  update_all_buttons_w()
  update_button_positions()
  update_buttons_color()
  ----store_btns()
end

------------------------------------------------------------
function create_pane(x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, lbl_r, lbl_g, lbl_b, lbl_a, norm_val, toggle_state)
  local panes = GUI.elements.panes
  x = x or 0
  y = y or 0
  w = w or gfx.w
  h = h or gfx.h
  local p = Pane:new(x,y,w,h)
  p.onLmbRelease =  function()
                    end
  p.onRmbRelease =  function()
                    end
  p.id = reaper.genGuid()
  panes[#panes + 1] = p    
  return p
end

------------------------------------------------------------
function Pane:draw(index)
  local x,y,w,h  = self.x, self.y, self.w, self.h
  if self:mouseIN() then
    if self.onMouseOver then
    end
  end
  
  local r,g,b,a  = self.r,self.g,self.b,self.a
  gfx.set(r,g,b,a)
  local text = self.lbl
  local t_w, t_h = gfx.measurestr(text)
  
  --if self.toggle_state then

  --else
    gfx.line(0,y,gfx.w, y)
    local bg_col_int = 3355443
    local r = bg_col_int & 255
    local g = (bg_col_int >> 8) & 255
    local b = (bg_col_int >> 16) & 255
    r = r/255
    g = g/255
    b = b/255
    gfx.set(r,1,b,1)
    --gfx.rect(0.5*gfx.w - 0.5*t_w-5, 0.5*gfx.texth,t_w,gfx.texth)
    gfx.set(1,1,1,0.5)
    gfx.x, gfx.y = x, y
    gfx.drawstr(text, 1, w,gfx.h)
    
    --gfx.line(8,y+h+10,gfx.w, y+h+10)
    --roundrect(x+border_size,y+border_size,w-2*border_size,h-2*border_size,0.5*(h-2*border_size),1)
    
  --end
  --roundrect(x,y,w,h,0.5*h,0)
  --self:draw_lbl()
end

------------------------------------------------------------
function on_track_list_change(last_action_undo_str)
  update_folder_type_tag_buttons()
  update_custom_type_tag_buttons()
  local removed_btns_count = remove_obsolete_buttons()
  if removed_btns_count > 0 then
    update_button_positions()
    update_visibility()
  end
end

--[[ needs JS reascript API
------------------------------------------------------------
function set_window_style(style, attach_resize_grip)
  if gfx.dock(-1)&1 == 0 then
    local hWnd_array = reaper.new_array({}, 20)
    local num_script_windows = reaper.JS_Window_ArrayFind(script.title, true, hWnd_array)
    local handles = hWnd_array.table()
    for i=1, num_script_windows do
      local hwnd = reaper.JS_Window_HandleFromAddress(handles[i])
      if attach_resize_grip then
        reaper.JS_Window_AttachResizeGrip(hwnd)
      end
      reaper.JS_Window_SetStyle(hwnd, style)
    end
  end
end
--]]

------------------------------------------------------------
function init()
  initial_track_visibility_states = get_track_visibility_states()
  local dock, x, y, w, h = 0, 0, 0, 0, 0
   --reaper.SetProjExtState(0, "spk77 Track Tags", "script state", "") -- delete data
  local ok, state = reaper.GetProjExtState(0, "spk77 Track Tags", "script state")
  
  if ok == 1 and state ~= "" then
    state = unpickle(state)
    dock = state.GUI.dock
    x = state.GUI.x
    y = state.GUI.y
    w = state.GUI.w
    h = state.GUI.h

    if state.main_menu ~= nil then
      main_menu.button_layout = state.main_menu.button_layout or 1
      main_menu.dock_pos_left = state.main_menu.dock_pos_left or (256+1)
      main_menu.dock_pos_top_left = state.main_menu.dock_pos_top_left or (2*256+1)
      main_menu.dock_pos_top_right = state.main_menu.dock_pos_top_right or (3*256+1)
      main_menu.dock_pos_right = state.main_menu.dock_pos_right or (0*256+1)
      main_menu.show_only_tagged_tracks = state.main_menu.show_only_tagged_tracks or true
      main_menu.button_layout = state.main_menu.button_layout or 1 -- 1=fit to window, 2=horizontal, 3=vertical
      main_menu.button_ordering = state.main_menu.button_ordering or 1 -- 1=by track index, 2=alphabetically
      main_menu.fixed_sized_buttons = state.main_menu.fixed_sized_buttons or false
      main_menu.show_closest_parent = state.main_menu.show_closest_parent or false
    end

    if state.properties ~= nil then
      local sp = state.properties
      local d = default_values.buttons
      for d_key, d_val in pairs(d) do
        properties.buttons[d_key] = state.properties.buttons[d_key] or d_val
      end
    else
      properties.buttons = shallow_copy(default_values.buttons)
    end
  else
    properties.buttons = shallow_copy(default_values.buttons)
    local left, top, right, bottom = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, 0)
    w = 0.1*(right-left)
    h = w -- 0.1*(bottom-top)
    x = 0.5*(right-left) - 0.5*w
    y = 0.5*(bottom-top) - 0.5*h
    
  end

  gfx.clear = 3355443  -- matches with "FUSION: Pro&Clean Theme :: BETA 01" http://forum.cockos.com/showthread.php?t=155329
                       -- (Double click in ReaScript IDE to open the link)   
  
  
  gfx.init(script.title, w, h, dock , x, y)
  GUI.dock = dock
  GUI.x = x
  GUI.y = y
  GUI.w = w
  GUI.h = h
  GUI.bg_col_r, GUI.bg_col_g, GUI.bg_col_b = color_int_to_rgb(GUI.bg_col_int)
  gfx.setfont(1, properties.buttons.font, properties.buttons.font_size)
  gui_w, gui_h = gfx.w, gfx.h
  last_gui_w, last_gui_h = gui_w, gui_h
  
  last_proj_change_count = reaper.GetProjectStateChangeCount(0)
  script.project_id, script.project_filename = EnumProjects(-1, "")
  -- Restore buttons
  restore()
  --[[
  if GUI.show_titlebar then
    set_window_style("", true)
  else
    set_window_style("WS_BORDER", true)
  end
  --]]
  on_track_list_change()
  
end

--[[ needs JS reascript API
------------------------------------------------------------
function move_window(mx_screen, my_screen)
  if gfx.dock(-1)&1 == 1 then
    gfx.dock(0)
    if GUI.show_titlebar then
    --  set_window_style("", true)
    else
     -- set_window_style("WS_BORDER", true)
    end
  elseif gfx.dock(-1)&1 == 0 then
    script.win_id = reaper.JS_Window_Find(script.title, 1)
    --_,GUI.left_scr, GUI.top_scr, GUI.right_scr, GUI.bottom_scr = reaper.BR_Win32_GetWindowRect(script.win_id)
   -- GUI.w_scr, GUI.h_scr = GUI.right_scr - GUI.left_scr, GUI.bottom_scr - GUI.top_scr
    local l, t, w, h = GUI.left_scr, GUI.top_scr, GUI.w_scr, GUI.h_scr
    gfx.init("", w, h, 0,  l-mouse.click_pos_x_screen+mx_screen, t-mouse.click_pos_y_screen+my_screen)
    --reaper.JS_Window_SetPosition(script.win_id, l-mouse.click_pos_x_screen+mx_screen, t-mouse.click_pos_y_screen+my_screen, w, h)
  end
end
--]]

------------------------------------------------------------
function on_lmb_down()
  if mouse.last_cap&1 == 0 then
    local curr_time = os.clock()
    mouse.lmb_down_time = curr_time
    mouse.ox, mouse.oy = mouse.x, mouse.y -- click position on script window
    mouse.ox_screen, mouse.oy_screen = mouse.x_screen, mouse.y_screen -- click position on screen
    _, GUI.win_x, GUI.win_y, GUI.win_w, GUI.win_h = gfx.dock(-1,0,0,0,0)
    if curr_time - mouse.lmb_up_time < 0.25 then
      on_lmb_double_click()
    end
  elseif mouse.moved and (mouse.x_screen ~= mouse.ox_screen or mouse.y_screen ~= mouse.oy_screen) then
    --on_lmb_drag()
    if not GUI.drag and(abs(mouse.x_screen - mouse.ox_screen) > GUI.drag_start_offset or
                        abs(mouse.y_screen - mouse.oy_screen) > GUI.drag_start_offset) then
      GUI.drag = true
      -- update mouse click positions (to prevent the window from jumping by "GUI.drag_start_offset" pixels)
      mouse.ox_screen = mouse.x_screen
      mouse.oy_screen = mouse.y_screen
    end
    if GUI.drag then
      if gfx.dock(-1)&1 == 1 then
      gfx.dock(0) -- ...undock it
        -- move the undocked window to mouse position (centered to mouse cursor)
        GUI.win_x, GUI.win_y = mouse.x_screen-0.5*GUI.win_w, mouse.y_screen-0.5*GUI.win_h
        gfx.init("", GUI.win_w, GUI.win_h, 0, GUI.win_x, GUI.win_y) -- move window to new position
        --set_window_style(style, false)
      elseif gfx.dock(-1)&1 == 0 then
        -- calculate new window position
        local new_x = GUI.win_x-mouse.ox_screen+mouse.x_screen
        local new_y = GUI.win_y-mouse.oy_screen+mouse.y_screen
        gfx.init("", GUI.win_w, GUI.win_h, 0, new_x, new_y) -- move window to new position
        -- move_window(mouse.x_screen, mouse.y_screen) -- needs JS reascript API
      end
    end
  end
end

------------------------------------------------------------
function on_lmb_up()
  mouse.lmb_up_time = os.clock()
  local dock, x, y, w, h =  gfx.dock(-1,0,0,0,0)
  if GUI.drag and gfx.dock(-1)&1 == 0 then
    local left, top, right, bottom = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)
    if script.os == "OSX32" or script.os == "OSX64" then
      y = bottom-h-y-GUI.reaper_titlebar_h -- reaper's title bar height on macOS is 22 pixels?
    else
      y = y - GUI.reaper_titlebar_h
    end
    if x <= 0 and y > 0 then
      gfx.dock(main_menu.dock_pos_left) -- left
    elseif x <= 0.5*(right-left) and y <= 0 then
      gfx.dock(main_menu.dock_pos_top_left) -- top left
    elseif x > 0.5*(right-left) and y <= 0 then
      gfx.dock(main_menu.dock_pos_top_right) -- top right
    elseif
      x + w >= right and y > 0 then
      gfx.dock(main_menu.dock_pos_right) -- right
    end
    store_state()
  end
  if GUI.drag then
    GUI.drag = false
  end
  if GUI.focus_arrange_view then
    setCursorContext()
  end
  if GUI.active_element then
    --GUI.active_element = nil
  end
end

------------------------------------------------------------
function on_lmb_double_click()
  -- Toggle "Show all tracks" when left clicking on empty area
  if not GUI.active_element then
    main_menu.show_only_tagged_tracks = not main_menu.show_only_tagged_tracks
    update_visibility()
  end
end

------------------------------------------------------------
function on_lmb_drag()
end

------------------------------------------------------------
function on_rmb_down()
  if mouse.last_cap&2 == 0 then
    mouse.rmb_down_time = os.clock()
    mouse.ox, mouse.oy = mouse.x, mouse.y
    mouse.ox_screen, mouse.ox_screen = mouse.x, mouse.y
  end
end

------------------------------------------------------------
function on_rmb_up()
  mouse.rmb_up_time = os.clock()
  if GUI.drag then
    GUI.drag = false
  end
  if not GUI.active_element then
    show_main_menu(x, y)
  end
  if GUI.focus_arrange_view then
    setCursorContext()
  end
end

------------------------------------------------------------
function on_mouse_wheel_up()
---[[
  local p = properties.buttons
  p.font_size = p.font_size + 1
  if p.font_size > 60 then
    p.font_size = 60
  end
  gfx.setfont(1, p.font, p.font_size)
  ----p.start_y = p.font_size + 2
  update_all_buttons_w()
  update_button_positions()
--]]
end

------------------------------------------------------------
function on_mouse_wheel_down()
---[[
  local p = properties.buttons
  p.font_size = p.font_size - 1
  if p.font_size < 14 then
    p.font_size = 14
  end
  gfx.setfont(1, p.font, p.font_size)
  ----p.start_y = p.font_size + 2
  update_all_buttons_w()
  update_button_positions()
--]]
end

------------------------------------------------------------
function get_mod_keys()
  mouse.ctrl = mouse.cap&4==4
  mouse.shift = mouse.cap&8==8
  mouse.alt = mouse.cap&16==16
end

------------------------------------------------------------
function get_mouse_btn_states()
  get_mod_keys()
  --     left btn down   right btn down  middle btn down
  return mouse.cap&1==1, mouse.cap&2==2, mouse.cap&64==64
end

------------------------------------------------------------
function get_mouse_cursor_context()
  if GUI.drag then return nil end
  local ft = GUI.elements.buttons.folder_type
  local st = GUI.elements.buttons.selection_type
  --local t = GUI.elements.buttons
  for i=1, #ft do
    local btn = ft[i]
    if btn:mouseIN() then
      --GUI.last_hovered_element = btn
      return btn, i
    end
  end
  
  for i=1, #st do
    local btn = st[i]
    if btn:mouseIN() then
      --GUI.last_hovered_element = btn
      return btn, i
    end
  end
  return nil
end

------------------------------------------------------------
function get_mouse_state()
  mouse.cap = gfx.mouse_cap
  mouse.x, mouse.y = gfx.mouse_x, gfx.mouse_y
  mouse.x_screen, mouse.y_screen = reaper.GetMousePosition()
  mouse.wheel = gfx.mouse_wheel
  mouse.moved = mouse.x_screen ~= mouse.last_x_screen or mouse.y_screen ~= mouse.last_y_screen
  local lmb_down, rmb_down = get_mouse_btn_states()
  if lmb_down then
    on_lmb_down()
  elseif mouse.last_cap&1 == 1 then
    on_lmb_up()
  elseif rmb_down then
    on_rmb_down()
  elseif mouse.last_cap&2 == 2 then
    on_rmb_up()
  elseif mouse.wheel ~= 0 then
    if mouse.wheel > 0 then
      on_mouse_wheel_up()
    else
      on_mouse_wheel_down()
    end
  end
end

------------------------------------------------------------
function mainloop()
  
  --if mouse.cap == 0 then
    GUI.active_element, GUI.active_element_index = get_mouse_cursor_context()
  --end
  get_mouse_state()
  
  if GUI.active_element then
    GUI.active_element:handle_mouse_events(GUI.active_element_index)
  end
  
  local f_btns = GUI.elements.buttons.folder_type
  local s_btns = GUI.elements.buttons.selection_type

  local curr_proj_id, curr_proj_file_name = EnumProjects(-1, "")
  proj_change_count = GetProjectStateChangeCount(curr_proj_id)
  
  -- if project tab has changed...
  if curr_proj_id ~= script.project_id then
    -- call "init" to create buttons from stored state for current project (if state exists) 
    -- (last_last_proj_change_count is set to proj_change_count in "init" -function)
    msg("proj_id changed - update_visibility")
    exit()  
    init()
    on_track_list_change(last_action)
  -- if project tab hasn't changed but RPP-file has changed...
  elseif curr_proj_id == script.project_id and curr_proj_file_name ~= script.project_filename then
    msg("same proj_id, filename changed")
    --exit()
    init()
    on_track_list_change(last_action)
  end
    
  if proj_change_count ~= last_proj_change_count then
    if reaper.CountTracks(0) == 0 then -- New empty project probably created
      --GUI.safe_remove_all_tags = true
      GUI.elements.buttons = {folder_type = {}, selection_type = {}}
    end
    
    msg("proj_change_count ~= last_proj_change_count")
    local last_action = reaper.Undo_CanUndo2(0)
    -- try to catch changes in track list
    if last_action ~= nil then
      if last_action:lower():find("color") then
        update_buttons_color()
      elseif (last_action:lower():find("track") or 
        last_action:lower():find("tracks")) and not last_action:lower():find("select") then
        msg("on_track_list_change")
        on_track_list_change(last_action)
      end
    end
    last_proj_change_count = proj_change_count
  end
  
  --draw_and_update_buttons(btns)
  if GUI.drag then
    _, GUI.x, GUI.y, GUI.w, GUI.h = gfx.dock(-1,0,0,0,0)
    local x, y, w, h = GUI.x, GUI.y, GUI.w, GUI.h
    local screen_left, screen_top, screen_right, screen_bottom = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)
    if script.os == "OSX32" or script.os == "OSX64" then
      y = screen_bottom-h-y-GUI.reaper_titlebar_h -- reaper's title bar height on macOS is 22 pixels?
    else
      y = y - GUI.reaper_titlebar_h
    end
    gfx.set(1,1,1,1)
    gfx.x, gfx.y = 0, 0
    if x <= 0 and y > 0 then
      gfx.drawstr("Dock to 'Left'", 1|4, gfx.w, gfx.h)
    elseif x <= 0.5*(screen_right-screen_left) and y <= 0 then
      gfx.drawstr("Dock to 'Top-Left'", 1|4, gfx.w, gfx.h)
    elseif x > 0.5*(screen_right-screen_left) and y <= 0 then
      gfx.drawstr("Dock to 'Top-Right'", 1|4, gfx.w, gfx.h)
    elseif x + w >= screen_right and y > 0 then
      gfx.drawstr("Dock to 'Right'", 1|4, gfx.w, gfx.h)
    else
      draw_and_update_buttons()
      --draw_and_update_buttons(tbl)
    end
  else
    draw_and_update_buttons()
    --[[
    if mouse.ctrl and GUI.active_element then
      local e = GUI.active_element
      local x, y, h = e.x, e.y, e.h
      gfx.set(0.3,0.3,0.3,0.9)
      local str_w, str_h = gfx.measurestr(e.tooltip_text)
      gfx.rect(x, y+h, str_w, str_h)
      gfx.x, gfx.y = x, y+h
      gfx.set(1,1,1,1)
      gfx.drawstr(e.tooltip_text)
    end
    --]]
  end
 
  if not main_menu.show_only_tagged_tracks then -- if bypassed
    gfx.set(0.1,0.1,0.1,0.4)
    gfx.rect(0,0,gfx.w, gfx.h)
    --gfx.update()
  end
  
  char = gfx.getchar()

  -- GUI is resized?
  if gfx.w ~= last_gui_w or gfx.h ~= last_gui_h then
    on_gui_resize(gfx.w, gfx.h)
    last_gui_w, last_gui_h = gfx.w, gfx.h
  end

  mouse.last_cap = mouse.cap
  mouse.last_x = mouse.x
  mouse.last_y = mouse.y
  mouse.last_x_screen = mouse.x_screen
  mouse.last_y_screen = mouse.y_screen
  gfx.mouse_wheel = 0

  if char == 32 then reaper.Main_OnCommand(40044, 0) end -- play/stop
  if char~=-1 and not main_menu.quit then reaper.defer(mainloop) end
  gfx.update()
end

------------------------------------------------------------
function remove_obsolete_buttons()
---[[
  local removed_btns_count = 0
  -- Remove "empty" folder_type buttons
  local t = GUI.elements.buttons.folder_type
  local j, n = 1, #t
  for index=1, n do
    local btn = t[index]
    if #btn.tracks > 0 then
      -- Move i's kept value to j's position, if it's not already there.
      if index ~= j then
        t[j] = t[index]
        t[index] = nil
      end
      j = j + 1; -- Increment position of where we'll place the next kept value.
    else
      t[index] = nil
      removed_btns_count = removed_btns_count + 1
    end
  end
  
  -- Remove "empty" selection_type buttons
  local t = GUI.elements.buttons.selection_type
  local j, n = 1, #t
  for index=1, n do
    local btn = t[index]
    if #btn.tracks > 0 then
      -- Move i's kept value to j's position, if it's not already there.
      if (index ~= j) then
        t[j] = t[index]
        t[index] = nil
      end
      j = j + 1; -- Increment position of where we'll place the next kept value.
    else
      t[index] = nil
      removed_btns_count = removed_btns_count + 1
    end
  end
  return removed_btns_count
end

------------------------------------------------------------
function exit()
  msg("function call: exit()")
  store_btns(script.project_id)
  local dock, x, y, w, h = gfx.dock(-1,0,0,0,0)
  local script_state = {}
  script_state.GUI =  {
                        dock = dock,
                        x = x,
                        y = y,
                        h = h,
                        w = w
                      }
                      
  script_state.main_menu = main_menu
  script_state.properties = properties
  if reaper.ValidatePtr(script.project_id, "ReaProject*") then
    local size = reaper.SetProjExtState(script.project_id, "spk77 Track Tags", "script state", pickle(script_state))
  else
    reaper.ShowConsoleMsg("Couldn't store GUI data - invalid ReaProject ID\n")
  end
  gfx.quit()
  restore_initial_track_visibility_states()
end

------------------------------------------------------------
function store_state(proj_id)
  proj_id = proj_id or 0
  local dock, x, y, w, h = gfx.dock(-1,0,0,0,0)
  local script_state = {}
  script_state.GUI =  {
                        dock = dock,
                        x = x,
                        y = y,
                        h = h,
                        w = w
                      }
                      
  script_state.main_menu = main_menu
  script_state.properties = properties
  if reaper.ValidatePtr(script.project_id, "ReaProject*") then
    local size = reaper.SetProjExtState(script.project_id, "spk77 Track Tags", "script state", pickle(script_state))
  else
    reaper.ShowConsoleMsg("Couldn't store GUI data - invalid ReaProject ID\n")
  end
end
  
------------------------------------------------------------
function store_btns(proj_id)
  msg("function call: store_btns")
  local proj_id = proj_id or EnumProjects(-1, "")
  local btns = GUI.elements.buttons
  local btn_data = {}
    for _,v in pairs(btns) do
      for i=1, #v do
        local btn = v[i]
        btn_data[#btn_data+1] = {
                                  lbl = btn.lbl,
                                  --tracks = btn.tracks,
                                  tracks = btn.track_guids,
                                  type = btn.type,
                                  toggle_state = btn.toggle_state,
                                  show_only_parent = btn.show_only_parent
                                }
      end
    end

  --msg(reaper.ValidatePtr(proj_id, "ReaProject*"))
  if reaper.ValidatePtr(proj_id, "ReaProject*") then
    local size = reaper.SetProjExtState(proj_id, "spk77 Track Tags", "buttons", pickle(btn_data))
  else
    reaper.ShowConsoleMsg("Couldn't store button data - invalid ReaProject ID\n")
  end
end

------------------------------------------------------------
function restore(proj_id)
  msg("function call: restore()")
  local proj_id = proj_id or 0
  GUI.elements.buttons = nil
  GUI.elements.buttons = {folder_type = {}, selection_type = {}}
  --local btns = GUI.elements.buttons
  local ok, buttons = reaper.GetProjExtState(proj_id, "spk77 Track Tags", "buttons")
  if buttons ~= "" then
    buttons = unpickle(buttons)
    msg("Button count:" .. tostring(#buttons))
    for i = 1, #buttons do
      local tr_guids_table, tr_pointer_table = validate_track_guids(buttons[i].tracks)
      msg("tr_guids_table length:" .. tostring(#tr_guids_table))
      -- Create button only if it has tagged tracks
      if #tr_guids_table > 0 then
        local btn_type = buttons[i].type
        local btn = create_button(btn_type)
        btn.track_guids = tr_guids_table
        btn.tracks = tr_pointer_table
        local tr = btn.tracks[1] -- parent track or first track in selection
        -- Create button's tooltip text
        local retval, tr_name = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
        if retval then
          btn.tooltip_text = btn.tooltip_text .. tr_name .. "\n"
          if tr_name == "" then
            tr_name = "Track " .. tostring(floor(reaper.GetMediaTrackInfo_Value(tr, "IP_TRACKNUMBER")))
          end
        end
        btn.lbl = buttons[i].lbl
        btn.lbl_w, btn.lbl_h = gfx.measurestr(btn.lbl)
        btn.toggle_state = buttons[i].toggle_state
        btn.show_only_parent = buttons[i].show_only_parent or false
        --btn:set_color_to_track_color() 
        btn:update_w_by_lbl_w()
      end
    end
  end

---[[
  sort_buttons()
  --update_all_buttons_w()
  update_button_positions()
  update_buttons_color()
  update_visibility()
--]]
end

------------------------------------------------------------

if not reaper.APIExists("JS_Window_Find") then
  reaper.ShowConsoleMsg("Missing API - JS_ReaScript extension\nCopy and paste this URL in Extensions > ReaPack > Import a repository:\nhttps://github.com/ReaTeam/Extensions/raw/master/index.xml")
else
  reaper.atexit(exit)
  init()
  mainloop()
end

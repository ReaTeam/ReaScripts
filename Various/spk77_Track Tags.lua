-- @description Track Tags (based on Tracktion 6 track tags)
-- @version 0.4.6
-- @author spk77
-- @changelog
--   - Allow dragging the window across screen boundaries (to the right). Thanks amagalma!
--   - Layout: fix overlapping elements. Thanks todoublez!
--   - Items in hidden tracks: (Fix) unselect items when they are hid by the script
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
                  version = "0.4.6",
                  title = "Track Tags",
                  project_filename = "",
                  project_id = nil,
                  win_id = -1,
                  guid = "",
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
              --safe_remove_btn_by_index = {},
              --safe_remove_track_from_tag = {},        -- remove tagged track from button
              --safe_remove_all_tags = false,
              focus_arrange_view = true,
              edit_box_has_focus = false
              
            }

-- Drag and drop docking
if script.os == "OSX32" or script.os == "OSX64" then
  GUI.reaper_titlebar_h = 22+8 -- reaper's title bar height on macOS is 22 pixels?
else
  GUI.reaper_titlebar_h = 0 -- other OSes: dock when window is at the top of screen
end       
            
GUI.elements =  {
                  buttons = {folder_type = {}, selection_type = {}},
                  panes = {folder_btns = {0,0,0,0}, selection_btns = {0,0,0,0}},
                  extra_buttons = {}, edit_boxes = {}, frames = {}
                }
            

local Element = {}

local main_menu =  {
                str = "",
                quit = false,
                button_layout = 1,
                --dock_pos_left = (256+1),
                --dock_pos_top_left = (2*256+1),
                --dock_pos_top_right = (3*256+1),
                --dock_pos_right = (0*256+1),
                show_only_tagged_tracks = true,
                button_layout =  1, -- 1=fit to window, 2=horizontal, 3=vertical
                button_ordering = 1, -- 1=by track index, 2=alphabetically
                use_track_color = true,
                show_closest_parent = false,
                auto_create_folder_tags = true,
                show_titlebar = false,
                hide_and_disable_all_buttons = false,
                show_search_box = false
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
                moved = false,
                down = false,
                click_outside = false,
                
                ox = -1,
                oy = -1,
                ox_screen = -1,
                oy_screen = -1  
              }

local gui_w, last_gui_w = -1, -1
local gui_h, last_gui_h = -1, -1
local char
local GetProjectStateChangeCount = reaper.GetProjectStateChangeCount
local curr_proj_id, curr_proj_file_name
local proj_change_count, last_proj_change_count = -1, -1
local tooltip_text, last_tooltip_text = "", ""
local first_selected_track = -1
local last_selected_track = -1



local default_values = {}
default_values.buttons =  {
                            font = "Verdana",
                            font_size = 14,
                      
                            start_x = 8,
                            start_y = 8,
                            w = 80,
                            h = 1.2,              -- times font_size
                            min_w = 48,
                            min_h = 14,
                            pad_x = 5,            -- x space between buttons
                            pad_y = 5,            -- y space between buttons
                            edge_radius = 30,
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
local string_len = string.len
local string_sub = string.sub
local string_gsub = string.gsub
local string_find = string.find
local reaper = reaper
local EnumProjects = reaper.EnumProjects
local screen_left, screen_top, screen_right, screen_bottom = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)

-- Static elements
local search_box = {}
local main_frame = {}

------------------------------------------------------------
--Track related functions
------------------------------------------------------------
local Tracks = {}
------------------------------------------------------------
function Tracks:get_first_selected()
  local tr = reaper.GetSelectedTrack(0, 0)
  return tr
end

------------------------------------------------------------
function Tracks:get_name(track, default_name)
-- Returns:
--   track name (if the track is named)
--   default_name (if default_name is passed to the function and the track isn't named)
--   track number (if default_name is not passed to the function and the track isn't named)
  if track then
    local retval, tr_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    if retval then
      tr_name = tr_name ~= "" and tr_name or default_name or "Track " .. tostring(floor(reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")))
    return tr_name
    end
  end
  return default_name or ""
end

------------------------------------------------------------
function Tracks:get_visibility_states()
  msg("Function call: Tracks:get_visibility_states()")
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
  return t
end

------------------------------------------------------------
function Tracks:restore_initial_visibility_states()
msg("Function call: Tracks:restore_initial_visibility_states()")
  local t = initial_track_visibility_states
  for i=1, #t do
    local tr = reaper.BR_GetMediaTrackByGUID(0, t[i].tr_guid)
    if reaper.ValidatePtr(tr, "MediaTrack*") then
      reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINTCP", t[i].show_in_tcp)
      reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINMIXER", t[i].show_in_mcp)
    end
  end
  reaper.TrackList_AdjustWindows(false)
end

------------------------------------------------------------
function Tracks:show_or_hide(track, show_in_TCP, show_in_MCP)
  --msg("Function call: Tracks:show(show_in_TCP, show_in_MCP)")
  --[[
  if not reaper.ValidatePtr(track, "MediaTrack*") then
    return false
  end
  --]]
  show_in_TCP = show_in_TCP and 1 or 0
  show_in_MCP = show_in_MCP and 1 or 0
  reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", show_in_TCP)
  reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", show_in_MCP)
end


------------------------------------PICKLE------------------------------------

local Pickle = { clone = function (t) local nt={}; for i, v in pairs(t) do nt[i]=v end return nt end }

function pickle(t)
  return Pickle:clone():pickle_(t)
end

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
  msg("Function call: get_project_filename(proj)")
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
  local mcp_x = reaper.GetMediaTrackInfo_Value(track_id, "I_MCPX")
  local mcp_w = reaper.GetMediaTrackInfo_Value(track_id, "I_MCPW")
  
  
  local arrange_id = reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 0x3E8)
  local ok, ar_vsb_position, ar_vsb_page, ar_vsb_min, ar_vsb_max, ar_vsb_trackPos = reaper.JS_Window_GetScrollInfo(arrange_id, "v")
  if ok then
    ok = reaper.JS_Window_SetScrollPos(arrange_id, "v", tcp_y + ar_vsb_position - floor(relative_y_pos*(ar_vsb_page-tcp_h) + 0.5))
  end
  
  --local mixer_id = reaper.JS_Window_FindChild(reaper.GetMainHwnd(), "Mixer", true)
  --local mcp_id = reaper.JS_Window_FindChild(mixer_id, "", true)
  local mixer_id, is_docked = reaper.BR_Win32_GetMixerHwnd()
  local mcp_id = reaper.JS_Window_FindChild(mixer_id, "", true)
  local ok, pos, page, min, max, trackPos = reaper.JS_Window_GetScrollInfo(mcp_id, "h")
  if ok then
    local relative_x_pos = relative_y_pos
    ok = reaper.JS_Window_SetScrollPos(mcp_id, "h", mcp_x + pos - floor(relative_x_pos*(page-mcp_w) + 0.5))
  end
  --return ok
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
  msg("Function call: sort_buttons()")
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
  msg("Function call: update_visibility()")
  local btns = GUI.elements.buttons
  --if #btns == 0 then return end
  reaper.PreventUIRefresh(1)
  if main_menu.show_only_tagged_tracks then
    local all_btns_off = true
    local tr_count = reaper.CountTracks(0)
    set_all_tracks_visible(0) -- hide all
    
    for _,v in pairs(btns) do
      --msg(#v)
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
              -- Show closest parent track
              if main_menu.show_closest_parent and t == 1 and b.type == "folder parent" then
                local par_tr = reaper.GetParentTrack(tr)
                if par_tr then
                  Tracks:show_or_hide(par_tr, true, true)
                end
              end          
              Tracks:show_or_hide(tr, true, true)
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
      -- Unselect items in hidden tracks (if hidden from TCP)
      for i=1, tr_count do
        local tr = reaper.GetTrack(0, i-1)
        if reaper.GetMediaTrackInfo_Value(tr, "B_SHOWINTCP") == 0 then
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
  ----store_btns()
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
  
  m.str = m.str .. "Set button properties|"
  if not main_menu.show_search_box then 
    m.str = m.str .. "#"
  end
  if m.hide_and_disable_all_buttons then
    m.str =  m.str .. "!Hide and disable all buttons||"
  else
    m.str =  m.str .. "Hide and disable all buttons||"
  end
--[[  
  m.str =  m.str .. ">'Drag and drop docking'|"
  if gfx.dock(-1) > 0 then
    m.str =  m.str .. "Store current dock position as 'Left'|"
    m.str =  m.str .. "Store current dock position as 'Top-Left'|"
    m.str =  m.str .. "Store current dock position as 'Top-Right'|"
    m.str =  m.str .. "<Store current dock position as 'Right'||"
  else
    m.str =  m.str .. "#Store current dock position as 'Left'|"
    m.str =  m.str .. "#Store current dock position as 'Top-Left'|"
    m.str =  m.str .. "#Store current dock position as 'Top-Right'|"
    m.str =  m.str .. "<#Store current dock position as 'Right'||"
  end
--]]  

  if m.show_titlebar then
    m.str =  m.str .. "!Show title bar||"
  else
    m.str =  m.str .. "Show title bar||"
  end

 
  m.str = m.str .. "><Remove|"
  m.str = m.str .. "<All tags||"
  
  m.str =  m.str .. ">Folder tags|"
  if main_menu.auto_create_folder_tags then
    m.str =  m.str .. "!Auto-create|"
  else
    m.str =  m.str .. "Auto-create|"
  end
 
  if main_menu.show_closest_parent then
    m.str =  m.str .. "<!Show closest parent track||"
  else
    m.str =  m.str .. "<Show closest parent track||"
  end
  
  m.str =  m.str .. ">Search box|"
  if m.hide_and_disable_all_buttons then
    m.str = m.str .. "#"
  end
  if main_menu.show_search_box then
    m.str =  m.str .. "<!Show||"
  else
    m.str =  m.str .. "<Show||"
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
    if main_menu.show_titlebar then
      set_window_style("", true)
    else
      set_window_style("WS_BORDER", true)
    end
    
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
--[[
  elseif menu_ret == 11 then
    main_menu.dock_pos_left = gfx.dock(-1)
  elseif menu_ret == 12 then
    main_menu.dock_pos_top_left = gfx.dock(-1)
  elseif menu_ret == 13 then
    main_menu.dock_pos_top_right = gfx.dock(-1)
  elseif menu_ret == 14 then
    main_menu.dock_pos_right = gfx.dock(-1)
--]]
  elseif menu_ret == 11 then
    m.hide_and_disable_all_buttons = not m.hide_and_disable_all_buttons
    if m.hide_and_disable_all_buttons then
      set_all_tracks_visible(1)
    else
      update_button_positions()
      update_visibility()
    end
  elseif menu_ret == 12 then
    main_menu.show_titlebar = not main_menu.show_titlebar
    if main_menu.show_titlebar then
      set_window_style("", true)
    else
      set_window_style("WS_BORDER", true)
    end
  elseif menu_ret == 13 then
    ----GUI.safe_remove_all_tags = true
    GUI.elements.buttons = {folder_type = {}, selection_type = {}}
    --update_visibility()
    update_button_positions(w, h)
    if main_menu.auto_create_folder_tags then
      create_buttons_from_folder_parents()
      --update_folder_type_tag_buttons()
      --GUI.elements.buttons.selection_type = {}
      update_visibility()
    end
  elseif menu_ret == 14 then
    main_menu.auto_create_folder_tags = not main_menu.auto_create_folder_tags
    if main_menu.auto_create_folder_tags then
      create_buttons_from_folder_parents()
      update_folder_type_tag_buttons()
      update_visibility()
    end
  elseif menu_ret == 15 then
    main_menu.show_closest_parent = not main_menu.show_closest_parent
    update_folder_type_tag_buttons()
    update_visibility()
  elseif menu_ret == 16 then
    main_menu.show_search_box = not main_menu.show_search_box
    if main_menu.show_search_box then
      
      search_box.toggle_state = true
      search_box.is_focused = true
      GUI.edit_box_has_focus = true
      reaper.JS_Window_SetFocus(script.win_id)
    end
    update_button_positions()
    update_visibility()
  elseif menu_ret == 17 then
    --exit()
    gfx.quit()
    main_menu.quit = true
  end
---[[  
  if menu_ret > 0 then
    store_state()
    store_btns()
  end
--]]
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
  store_state()
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
  elm.type = ""
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
local Frame = {}
extended(Frame, Element)
local Frames = {}
------------------------------------------------------------

function Frames:create_new()
  msg("Function call: Frames:create_new()")
  local frames = GUI.elements.frames
  local f = Frame:new(   
                          ---[[
                          0,                    --  x
                          0,                    --  y 
                          gfx.w,                  --  w
                          gfx.h,                  --  h
                          0.5,                  --  r
                          0.5,                  --  g
                          0.5,                  --  b
                          1.0,                  --  a
                          "Frame",               --  lbl
                          "Verdana",            --  label font
                          14,                   --  label font size
                          1,                    -- label color r
                          1,                    -- label color g
                          1,                    -- label color b
                          1,                    -- label color a
                          0,                    -- norm_val
                          false                 -- toggle state
                          --]]
                        )

  f.is_focused = false
  
  f.tooltip_text = ""
  f.lbl_w, f.lbl_h = gfx.measurestr(f.lbl)

  f.onLmbRelease =  function()
                      if not f.is_focused then
                        f.is_focused = true
                      end
                    end
                  
  f.onRmbRelease =  function(index)
                    end
  
  f.onMouseOver = function()
                    end
  

  f.id = reaper.genGuid()
  frames[#frames+1] = f
  return f
end

------------------------------------------------------------
function Frame:handle_mouse_events(frame_index)
  if self:mouseLDown() and gfx.mouse_cap & 1 == 0 then
    self.lmb_down_time = os.clock()
    msg("self.lmb_down_time")
  end
 
  if self:mouseLmbRelease() then
    self.onLmbRelease()
    
  elseif self:mouseRmbRelease() then
    self.onRmbRelease(frame_index)
  end
end


------------------------------------------------------------
local Button = {}
extended(Button, Element)
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
  msg("Function call: Button:set_color_to_track_color()")
  local tr = self.tracks[1]
  if not reaper.ValidatePtr(tr, "MediaTrack*") then
    return
  end
  
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
      if self.toggle_state then
        self:set_lbl_color(r, g, b, 1)
      else
        self:set_lbl_color(1, 1, 1, 1)
      end
    end
  end
end

------------------------------------------------------------
function update_buttons_color()
  msg("Function call: update_buttons_color()")
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
  local btn_create_new = GUI.elements.extra_buttons[1]
  btn_create_new:update_lbl_size()
  btn_create_new:update_w_by_lbl_w()
end

------------------------------------------------------------
function Button:set_other_buttons_off(btn_index)
  local btns = GUI.elements.buttons
  local is_other_buttons_active = false
  for _,v in pairs(btns) do
    for i=1, #v do 
      local b = v[i]
      ----if i ~= btn_index then
      if v ~= self then
        if not is_other_buttons_active and b.toggle_state then
          is_other_buttons_active = true
        end
        if b.toggle_state then
          b.toggle_state = false
          b:set_color_to_track_color()
        end
        --b:set_color_to_track_color()
        
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
  msg("Function call: validate_track_guids()")
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
function Button:validate_track_guids()
  self.track_guids, self.tracks = validate_track_guids(self.track_guids)
end
      
------------------------------------------------------------
function Button:update_lbl_size(w, h)
  local w, h = gfx.measurestr(self.lbl)
  self.lbl_w = w
  if w < properties.buttons.min_w then
    self.lbl_w = properties.buttons.min_w
  end
  self.lbl_h = h
  if h < properties.buttons.min_h then
    self.lbl_h = properties.buttons.min_h
  end
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
  self.h = floor(self.lbl_h*properties.buttons.h+0.5)
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
  local edge_thickness = properties.buttons.edge_thickness
  local radius = properties.buttons.edge_radius/100*0.5*h
  local r, g, b, a = self.r, self.g, self.b, self.a
  gfx.set(r,g,b,a)
  if self == GUI.elements.extra_buttons[1] then
    if self:mouseIN() then
      self.a = 0.6
      self.lbl_a = 0.6
    else
      self.a = 0.4
      self.lbl_a = 0.4
    end
    roundrect(x,y,w,h,radius,0)
    --roundrect(x+edge_thickness,y+edge_thickness,w-2*edge_thickness,h-2*edge_thickness,radius,1)

    self:draw_lbl()
    return
  end
--[[
  -- Draw info string
  if self:mouseIN() then
  -- Button info text
  
    gfx.set(1,1,1,1)
    gfx.x = properties.buttons.start_x
    gfx.y = 0
    
    gfx.drawstr(self.lbl)
    --gfx.drawstr(self.lbl, 0|4, gfx.w, gfx.texth)
  
    if self.onMouseOver then
    end
  end
--]]
  
  if self == GUI.elements.extra_buttons[1] then
    return
  end
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
function Button:handle_mouse_events(btn_index)
  if GUI.edit_box_has_focus then
    return
  end
  if self.type == "" then
    if self:mouseLmbRelease() then
      self.onLmbRelease()
      return
    end
  end
  local tr = self.tracks[1]
  
  if self:mouseLmbRelease() then
    if main_menu.show_only_tagged_tracks then
      self.toggle_state = not self.toggle_state
      if not mouse.ctrl then-- and self.toggle_state then
        self:set_other_buttons_off(btn_index)
      end
      self:set_color_to_track_color()
    else
      scroll_to_track(tr)
    end
    self.onLmbRelease()
    store_btns(proj_id)
  elseif self:mouseRmbRelease() then
    self.onRmbRelease(btn_index)
    store_btns()
  else
  end
end

------------------------------------------------------------
-- Button related functions
------------------------------------------------------------
local Buttons = {}
------------------------------------------------------------
function Buttons:create_new(btn_type)
  msg("Function call: Buttons:create_new(btn_type)")
--function create_button(btn_type)
  --local btns = GUI.elements.buttons
  local folder_type_btns = GUI.elements.buttons.folder_type
  local selection_type_btns = GUI.elements.buttons.selection_type
  local extra_btns = GUI.elements.extra_buttons
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
                          "Verdana",              --  label font
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
                    if btn.type ~= "folder parent" and btn.type ~= "selection" then
                      return
                    end
                    gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
                    local m = button_menu
                    --m.str = "#" .. "Button type: " .. btn.type .. "||"
                    m.str = "Rename tag|"
                    m.str = m.str .. "Remove tag|"
                    if btn.type == "folder parent" then
                      m.str = m.str .. "#"
                    end
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
                        if retvals_csv == "" then
                          retvals_csv = "Tag"
                        end
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
                      update_visibility()
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
  elseif  btn.type == "" then
    extra_btns[#extra_btns+1] = btn
  end
  
  --btns[#btns + 1] = btn
  --btn:update_w_by_lbl_w()
  
  ----update_button_positions()
  ----sort_buttons()
  
  btn.tooltip_text = ""--btn.lbl
  --msg(btn.lbl)
  
  return btn
end

------------------------------------------------------------
function update_button_positions(w, h)
  msg("function call: update_button_positions()")
  local btns = GUI.elements.buttons
  local search_box = GUI.elements.edit_boxes[1]
  local f_btns = btns.folder_type
  local s_btns = btns.selection_type
  local extra_btn = GUI.elements.extra_buttons[1]


  local len_f_btns = #f_btns
  local len_s_btns = #s_btns
  if len_f_btns == 0 and len_s_btns == 0 then
    --return
  end
  --local max_r, max_b = 0, 0
  local p = properties.buttons

  local w, h = w or gfx.w, h or gfx.h
  local x = p.start_x
  local y = p.start_y
  local layout = main_menu.button_layout
  local curr_row = 1
  local curr_col = 1
  
  main_frame.w, main_frame.h = gfx.w, gfx.h
  
  if main_menu.show_search_box then
    curr_row = 2
    search_box.x = p.start_x
    search_box.y = p.start_y
    search_box.w = (gfx.w > 100 and gfx.w or 100) - 2*p.start_x
    if main_menu.hide_and_disable_all_buttons then
      return
    end
    x = p.start_x
    y = p.start_y + search_box.h + p.pad_y
  end
  
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
--[[  
  if #f_btns == 0 then
    x = p.start_x
    y = p.start_y
    curr_row = 1
    curr_col = 1
  end
--]]
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
  
  
  
  
  local b = extra_btn
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
  
  return x,y
end


------------------------------------------------------------
local Pane = {}
extended(Pane, Element)
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
function on_gui_resize(w, h)
  msg("Function call: on_gui_resize(w, h)")
  GUI.dock, GUI.x, GUI.y, GUI.w, GUI.h = gfx.dock(-1,0,0,0,0)
  update_button_positions(w, h)
  --store_state()
end

---[[
------------------------------------------------------------                       
function draw_btn_create_new()
  if main_menu.hide_and_disable_all_buttons then
    return
  end
  local btn_create_new = GUI.elements.extra_buttons[1]
  if btn_create_new then
    first_selected_track = reaper.GetSelectedTrack(0, 0)
    if first_selected_track then
      if first_selected_track ~= last_selected_track then
        local tr_name = "+ " .. Tracks:get_name(first_selected_track)
        if tr_name ~= btn_create_new.lbl then
          btn_create_new.lbl =  tr_name
          btn_create_new:update_lbl_size()
          btn_create_new:update_w_by_lbl_w()
        end
        last_selected_track = first_selected_track
      end
      btn_create_new:draw(1)
    end
  end
end

------------------------------------------------------------                       
function draw_and_update_buttons()
  if main_menu.hide_and_disable_all_buttons then
    return
  end
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

---[[  
  if button_count == 0 and not first_selected_track then
    gfx.x, gfx.y = 8,8
    gfx.set(1,1,1,1)
    --gfx.drawstr("No tags assigned\n\nRight click to open the menu" , 1|4, gfx.w, gfx.h) 
    return gfx.x, gfx.y, gfx.w, gfx.h
  end
--]]
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
function create_new_from_selection_shortcut_btn()
  local btn = Buttons:create_new()
  local tr = reaper.GetSelectedTrack(0, 0)
  btn.lbl = "+ " .. Tracks:get_name(tr)
  btn:update_lbl_size(w, h)
  btn:update_w_by_lbl_w()
  btn.a = 0.4
  btn.lbl_a = 0.4
  btn.onLmbRelease =  function()
                        create_button_from_selection()
                      end
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
  local btn = Buttons:create_new("selection")
  btn.lbl = retvals_csv or def_name
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
  store_btns()
end

------------------------------------------------------------
function update_child_tracks(parent_tr, tag_button, tag_button_index)
  if not reaper.ValidatePtr(parent_tr, "MediaTrack*") then
    --GUI.safe_remove_btn_by_index[#GUI.safe_remove_btn_by_index+1] = {tag_button_index, "folder parent"}
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
  store_btns()
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
  store_btns()
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
  store_btns()
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
        btn = Buttons:create_new("folder parent")
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
  store_btns()
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
function starts_with(str, start)
   return str:sub(1, #start) == start
end

------------------------------------------------------------
function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

------------------------------------------------------------
local Edit_box = {}
extended(Edit_box, Element)
------------------------------------------------------------
function Edit_box:handle_mouse_events(eb_index)
  if self:mouseLmbRelease() then
    if self.toggle_state and not self.is_focused then
      self.is_focused = true
      return
    end
    self.toggle_state = not self.toggle_state
    if not self.toggle_state then
      self.is_focused = false
      GUI.edit_box_has_focus = false
      update_visibility()
    else
      GUI.edit_box_has_focus = true
      if self.text and self.text ~= "" then
        self:find_tracks()
      end
    end
    self.onLmbRelease()
  elseif self:mouseRmbRelease() then
    self.onRmbRelease(eb_index)
  else
  end
end

------------------------------------------------------------
function Edit_box:set_h_by_font_size()
  self.h = floor(self.fnt_sz*properties.buttons.h+0.5)
end

------------------------------------------------------------
function Edit_box:draw(index)
  if not main_menu.show_search_box then
    return
  end
  local x,y,w,h = self.x, self.y, self.w, self.h
  local r,g,b,a = self.r, self.g, self.b, self.a
  gfx.set(r,g,b,a)
  if self:mouseIN() then
    if self.onMouseOver then
    end
  else
  end
  if self.toggle_state and self.is_focused then
    gfx.set(0,1,1,0.8)
  else
    gfx.set(1,1,1,0.5)
  end
  gfx.rect(x, y, w, h, 0)
  local col = 43/255
  if self.is_focused then
    gfx.set(col,col,col,1)
    --gfx.set(1,1,1,0.1)
  else
    --gfx.set(1,1,1,0.1)
    gfx.set(col,col,col,1)
  end
  gfx.rect(x+1, y+1, w-2, h-2, 1)
  gfx.x, gfx.y = x,y
  gfx.set(1,1,1,1)
  local w, h = gfx.measurestr(self.text)
  
  if self.toggle_state and self.is_focused then
    
    if self.cursor_state < 8 then 
      local str_w = gfx.measurestr(string.sub(self.text, 0, self.caret))    
      --setcolor(self.curscol)
      gfx.set(1,1,1,1)
      gfx.line(self.x + 4 + str_w, self.y + 4, self.x + 4 + str_w, self.y + self.h - 4)
    end
    self.cursor_state = (self.cursor_state+1)%16
  else
    gfx.set(1,1,1,0.5)
  end
  gfx.drawstr(self.text, 1|4, x+8+w, y+h)
  --gfx.drawstr(self.text)
end

------------------------------------------------------------
function Edit_box:onchar(c)
  msg("Function call: Edit_box:onchar(c)")
  msg("Char: " .. tostring(c))
--[[
  if e.sel ~= 0 then
    local sc,ec=e.caret,e.caret+e.sel
    if sc > ec then sc,ec=ec,sc end
    e.text=string.sub(e.text,1,sc)..string.sub(e.text,ec+1)
    e.sel=0
  end
--]]
  if c == 13 then -- return
    self.toggle_state = false
    self.is_focused = false
    GUI.edit_box_has_focus = false
    update_visibility()
    return
  elseif c == 37 then -- % char
    return
  elseif c == 0x6C656674 then -- left arrow
    if self.caret > 0 then self.caret=self.caret-1 end
  elseif c == 0x72676874 then -- right arrow
    if self.caret < string.len(self.text) then self.caret=self.caret+1 end
  elseif c == 8 then -- backspace
    if self.caret > 0 then 
      self.text=string.sub(self.text,1,self.caret-1)..string.sub(self.text,self.caret+1)
      self.caret=self.caret-1
    end
  --elseif c >= 32 and c <= 125 and  string.len(self.text) < self.maxlen then
  elseif c >= 32 and c <= 125 and string.len(self.text) < self.maxlen then
    self.text = string.format("%s%c%s", 
      string.sub(self.text,1,self.caret), c, string.sub(self.text,self.caret+1))
    self.caret=self.caret+1
  end
  if self.text ~= "" then
    self:find_tracks()
  else
    update_visibility()
  end
end

------------------------------------------------------------
function Edit_box:getcaret()
  local len = string.len(self.text)
  for i=1,len do
    local w = gfx.measurestr(string.sub(self.text, 1, i))
    if mouse.x < self.x + self.l + w then return i-1 end
  end
  return len
end

------------------------------------------------------------
function Edit_box:find_tracks()
  msg("Function call: Edit_box:find_tracks()")
  msg(self.text)
  local search_string = self.text
  local text_len = string_len(self.text)
  local search_receives = starts_with(self.text, "#r")
  local search_sends = starts_with(self.text, "#s")
  local search_instruments = starts_with(self.text, "#i")
  local search_fxs = starts_with(self.text, "#fx")
  local apply_pre_filter = search_receives or search_sends or search_instruments or search_fxs
  local first_visible_tr = false
  
  reaper.PreventUIRefresh(1)
  for i = 1, reaper.CountTracks(0) do
    local track = reaper.GetTrack(0,i-1)
    if track then
      local show_track = false
      if search_receives then
        if reaper.GetTrackNumSends(track, -1) > 0 then
          search_string = string_sub(self.text, 3)
          show_track = true
        end
      elseif search_sends then
        if reaper.GetTrackNumSends(track, 0) > 0 then
          search_string = string.sub(self.text, 3)
          show_track = true
        end
      elseif search_instruments then
        if reaper.TrackFX_GetInstrument(track) > -1 then
          search_string = string.sub(self.text, 3)
          show_track = true
        end
      elseif search_fxs then
        local fx_count = reaper.TrackFX_GetCount(track)
        if fx_count > 0 then
          search_string = string.sub(self.text, 4)
          search_string = search_string:gsub("^%s*", "")
          if text_len > 3 then
            for fx_index=1, fx_count do
              local retval, fx_name = reaper.TrackFX_GetFXName(track, fx_index-1, "")
              if retval then
                fx_name = fx_name:gsub("(.-):", ""):gsub("%b()", "") -- remove "vst:" and manufacturer
                if fx_name:lower():find(search_string) then
                  show_track = true
                  break
                end
              end 
            end
          else
            show_track = true -- show all tracks that have FXs
          end
        end
      end
      
      search_string = search_string:gsub("^%s*", "")
      if (not search_fxs and apply_pre_filter) or not apply_pre_filter and string.len(search_string) > 0 then
        local _, tr_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        if tr_name:lower():find(search_string) then
          show_track = true
        else
          show_track = false
        end
      end
      
      if show_track then
        if not first_visible_tr then
          first_visible_tr = track
        end
        -- Tracks:show_or_hide(track, show_in_TCP, show_in_MCP)
        Tracks:show_or_hide(track, true, true)
      else
        Tracks:show_or_hide(track, false, false)
      end
    end
  end
  reaper.PreventUIRefresh(-1)
  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()
  if first_visible_tr then
    scroll_to_track(first_visible_tr)
  end
end



------------------------------------------------------------
-- Edit box related functions
------------------------------------------------------------
local Edit_boxes = {}
------------------------------------------------------------
function Edit_boxes:create_new()
  msg("Function call: Edit_boxes:create_new()")
  local e_boxes = GUI.elements.edit_boxes
  local e = Edit_box:new(   
                          --[[
                          0,                    --  x
                          0,                    --  y 
                          0,                  --  w
                          e.h,                  --  h
                          0.5,                  --  r
                          0.5,                  --  g
                          0.5,                  --  b
                          1.0,                  --  a
                          "Text",               --  lbl
                          "Verdana",            --  label font
                          14,                   --  label font size
                          1,                    -- label color r
                          1,                    -- label color g
                          1,                    -- label color b
                          1,                    -- label color a
                          0,                    -- norm_val
                          false                 -- toggle state
                          --]]
                        )
  e.text = ""
  e.is_focused = false
  e.caret = 0
  e.sel = 0
  e.cursor_state = 0
  e.maxlen = 20
  e.type = "edit box"
  
  
  e.tooltip_text = ""
  e.lbl_w, e.lbl_h = gfx.measurestr(e.lbl)

  e.onLmbRelease =  function()
                      if not e.is_focused then
                        e.is_focused = true
                      end
                    end
                  
  e.onRmbRelease =  function(buttonindex) 
                    end
  
  e.onMouseOver = function()
                    end
  

  e.id = reaper.genGuid()
  e_boxes[#e_boxes+1] = e
  return e
end

------------------------------------------------------------             
function draw_edit_boxes()
  if not main_menu.show_search_box then
    return
  end
  local sb = GUI.elements.edit_boxes[1]
  sb:draw(1)
end

------------------------------------------------------------
function Edit_boxes:remove_focus()
  local e = GUI.elements.edit_boxes
  for i=1, #e do
    local eb = e[i]
    eb.is_focused = false
  end
end

------------------------------------------------------------
function Edit_boxes:set_toggle_state(state)
  local e = GUI.elements.edit_boxes
  for i=1, #e do
    local eb = e[i]
    eb.toggle_state = state or false
  end
end


------------------------------------------------------------
function on_track_list_change(last_action_undo_str)
  msg("Function call: on_track_list_change()")
  update_folder_type_tag_buttons()
  update_custom_type_tag_buttons()
  if main_menu.auto_create_folder_tags then
    create_buttons_from_folder_parents()
  end
  local removed_btns_count = remove_obsolete_buttons()
  if removed_btns_count > 0 then
    update_button_positions()
    update_visibility()
  end
end

---[[ needs JS reascript API
------------------------------------------------------------
function set_window_style(style, attach_resize_grip)
  
  if gfx.dock(-1)&1 == 0 then
    script.win_id = reaper.JS_Window_FindTop(script.title, 1)
    if attach_resize_grip then
      reaper.JS_Window_AttachResizeGrip(script.win_id)
    end
    reaper.JS_Window_SetStyle(script.win_id, style)
  end
end
--]]

------------------------------------------------------------
function init()
  reaper.ClearConsole()
  msg("-------------------------------------------------") 
  msg("Function call: init()")
  msg("script.project_id: " .. tostring(script.project_id))
  msg("Current project ID: " .. tostring(EnumProjects(-1, "")))
  msg("script.project_filename: " .. tostring(script.project_filename))
  msg("curr_proj_file_name: " .. tostring(curr_proj_file_name))
  GUI.elements.buttons = {folder_type = {}, selection_type = {}}
  initial_track_visibility_states = Tracks:get_visibility_states()
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
    --msg("state.GUI.dock: " .. tostring(state.GUI.dock))
    --msg("gfx.dock(-1): " .. tostring(gfx.dock(-1)))
    --msg("dock: " .. tostring(dock))

    if state.main_menu ~= nil then
      main_menu.button_layout = state.main_menu.button_layout or 1
    --[[
      main_menu.dock_pos_left = state.main_menu.dock_pos_left or (256+1)
      main_menu.dock_pos_top_left = state.main_menu.dock_pos_top_left or (2*256+1)
      main_menu.dock_pos_top_right = state.main_menu.dock_pos_top_right or (3*256+1)
      main_menu.dock_pos_right = state.main_menu.dock_pos_right or (0*256+1)
    --]]
      main_menu.show_only_tagged_tracks = state.main_menu.show_only_tagged_tracks or true
      main_menu.button_layout = state.main_menu.button_layout or 1 -- 1=fit to window, 2=horizontal, 3=vertical
      main_menu.button_ordering = state.main_menu.button_ordering or 1 -- 1=by track index, 2=alphabetically
      main_menu.fixed_sized_buttons = state.main_menu.fixed_sized_buttons or false
      main_menu.show_closest_parent = state.main_menu.show_closest_parent or false
      main_menu.auto_create_folder_tags = state.main_menu.auto_create_folder_tags or false
      main_menu.show_titlebar = state.main_menu.show_titlebar or false
      main_menu.hide_and_disable_all_buttons = state.main_menu.hide_and_disable_all_buttons or false
      main_menu.show_search_box = state.main_menu.show_search_box or false
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
  
  gfx.init(script.title, w, h, dock, x, y) -- Start undocked to get window/client size
  script.win_id = reaper.JS_Window_FindTop(script.title, 1)
  --gfx.dock(dock)
  --msg("gfx.dock(-1): " .. tostring(gfx.dock(-1)))
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
  
  main_frame = Frames:create_new()
  main_frame.type = "main frame"
  search_box = Edit_boxes:create_new()
  search_box.fnt_sz = properties.buttons.font_size
  search_box:set_h_by_font_size()
  create_new_from_selection_shortcut_btn()
  
  -- Restore buttons
  local button_count = restore_button_states()
  ----store_btns(script.project_id)
---[[
  if main_menu.show_titlebar then
    --reaper.JS_Window_AttachTopmostPin(script.win_id)
    set_window_style("", true)
  else
    --reaper.JS_Window_AttachTopmostPin(script.win_id)
    set_window_style("WS_BORDER", true)
    _, GUI.win_x, GUI.win_y, GUI.win_w, GUI.win_h = gfx.dock(-1,0,0,0,0)
  end
--]]
  if button_count > 0 then
    update_button_positions()
  end
end

------------------------------------------------------------
function on_lmb_down()
  local act_elem = GUI.active_element
  if mouse.last_cap&1 == 0 then
    local curr_time = os.clock()
    mouse.lmb_down_time = curr_time
    mouse.ox, mouse.oy = mouse.x, mouse.y -- click position on script window
    mouse.ox_screen, mouse.oy_screen = mouse.x_screen, mouse.y_screen -- click position on screen
    _, GUI.win_x, GUI.win_y, GUI.win_w, GUI.win_h = gfx.dock(-1,0,0,0,0)
    if curr_time - mouse.lmb_up_time < 0.25 then
      on_lmb_double_click()
    end
    --msg(GUI.active_element.type)
  elseif act_elem and (act_elem.type == "main frame" or act_elem.type == "edit box") and mouse.moved and (mouse.x_screen ~= mouse.ox_screen or mouse.y_screen ~= mouse.oy_screen) then
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
        GUI.win_x, GUI.win_y = floor(mouse.x_screen-0.5*GUI.win_w + 0.5), floor(mouse.y_screen-0.5*GUI.win_h + 0.5)
        --gfx.init("", GUI.win_w, GUI.win_h, 0, GUI.win_x, GUI.win_y) -- move window to new position
        if not main_menu.show_titlebar then
          set_window_style("WS_BORDER", true)
        else
-- Fix this: docked default style -window doesn't move without this...
          set_window_style("", true)
        end
      elseif gfx.dock(-1)&1 == 0 then
        -- calculate new window position
        local new_x = GUI.win_x-mouse.ox_screen+mouse.x_screen
        local new_y = GUI.win_y-mouse.oy_screen+mouse.y_screen
        --gfx.init("", GUI.win_w, GUI.win_h, 0, new_x, new_y) -- move window to new position
        reaper.JS_Window_Move(script.win_id, new_x, new_y)
      end
    end
  end
end

------------------------------------------------------------
function on_lmb_up()
  mouse.lmb_up_time = os.clock()
  local dock, x, y, w, h =  gfx.dock(-1,0,0,0,0)
  --dock_ID = reaper.GetConfigWantsDock("spk77_Track Tags.lua")
  --dock_pos = reaper.DockGetPosition(dock_ID)
  if GUI.drag and gfx.dock(-1)&1 == 0 then
    reaper.PreventUIRefresh(1)
    local left, top, right, bottom = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)
    if script.os == "OSX32" or script.os == "OSX64" then
      y = bottom-h-y-GUI.reaper_titlebar_h -- reaper's title bar height on macOS is 22 pixels?
    else
      y = y - GUI.reaper_titlebar_h
    end
    if x <= 0 and y > 0 then
      gfx.dock(1*256+1)
      reaper.Main_OnCommand(41599, 0) -- Docker: Show in left of main window
    elseif y <= 0 then
      gfx.dock(2*256+1)
      reaper.Main_OnCommand(41600, 0) --Docker: Show in top of main window
    --elseif x + w >= right and y > 0 then
    elseif x + w >= right and x <= right and y > 0 then
      gfx.dock(3*256+1)
      reaper.Main_OnCommand(41601, 0) -- Docker: Show in right of main window
-- bottom
    --elseif then
    --reaper.Main_OnCommand(41598, 0) -- Docker: Show in bottom of main window
    end
    reaper.PreventUIRefresh(-1)
    --reaper.DockWindowRefresh()
    local dock_state, x, y, w, h = gfx.dock(-1,0,0,0,0)
    if dock_state > -1 then
      GUI.dock = dock_state
    end
    store_state()
  end
  if GUI.drag then
    GUI.drag = false
  end
  if GUI.focus_arrange_view then
    if not search_box.is_focused and not GUI.edit_box_has_focus and GUI.active_element.type ~= "edit box" then
      setCursorContext()
    end
  end
  if GUI.active_element then
    --GUI.active_element = nil
  end
end

------------------------------------------------------------
function on_lmb_double_click()
  -- Toggle "Show all tracks" when left clicking on empty area
  if GUI.active_element.type == "main frame" then
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
  if GUI.active_element.type == "main frame" then
    show_main_menu(x, y)
  --else
   -- GUI.active_element = nil
  end
  if GUI.focus_arrange_view then
    if not search_box.is_focused and not GUI.edit_box_has_focus and GUI.active_element.type ~= "edit box" then
      setCursorContext()
    end
  end
end

------------------------------------------------------------
function on_mouse_wheel_up()
---[[
  local p = properties.buttons
  p.font_size = p.font_size + 1
  if p.font_size > 40 then
    p.font_size = 40
  end
  gfx.setfont(1, p.font, p.font_size)
  ----p.start_y = p.font_size + 2
  update_all_buttons_w()
  search_box.fnt_sz = p.font_size
  search_box:set_h_by_font_size()
  update_button_positions()
  store_state()
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
  search_box.fnt_sz = p.font_size
  search_box:set_h_by_font_size()
  update_button_positions()
  store_state()
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
  --if GUI.drag then return nil end
  if GUI.active_element then
    --return GUI.active_element
  end
  if main_menu.show_search_box then
    local sb = GUI.elements.edit_boxes
    for i=1, #sb do
      local eb = sb[i]
      if eb:mouseIN() then
        --GUI.last_hovered_element = btn
        return eb, i
      end
    end
  end
  if not main_menu.hide_and_disable_all_buttons then
  
    local ft = GUI.elements.buttons.folder_type
    local st = GUI.elements.buttons.selection_type
    local btn_add_new = GUI.elements.extra_buttons[1]
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
    if btn_add_new:mouseIN() then
      return btn_add_new, 1
    end
  end

  if main_frame:mouseIN() then
    return main_frame, 1
  end
  return nil
end

------------------------------------------------------------
function get_mouse_state()
  --mouse.click_on_GUI = reaper.JS_Mouse_GetState(1)==1 or reaper.JS_Mouse_GetState(2)==2 and
  --mouse.cap = reaper.JS_Mouse_GetState(1) --gfx.mouse_cap
  mouse.x_screen, mouse.y_screen = reaper.GetMousePosition()
  mouse.cap = reaper.JS_Mouse_GetState(0xFF)
  if mouse.cap ~= gfx.mouse_cap then
    mouse.click_outside = true
    mouse.cap = 0
    Edit_boxes:remove_focus()
    Edit_boxes:set_toggle_state(false)
    return
  else
    mouse.click_outside = false
  end
  mouse.x, mouse.y = gfx.mouse_x, gfx.mouse_y
  
  mouse.wheel = gfx.mouse_wheel
  mouse.moved = mouse.x_screen ~= mouse.last_x_screen or mouse.y_screen ~= mouse.last_y_screen
  mouse.lmb_down, mouse.rmb_down = get_mouse_btn_states()
  mouse.down = mouse.lmb_down or mouse.rmb_down
  if mouse.lmb_down then
    on_lmb_down()
  elseif mouse.last_cap&1 == 1 then
    on_lmb_up()
  elseif mouse.rmb_down then
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
  get_mouse_state()
  if mouse.last_cap == 0 and mouse.down then
    msg("mouse.last_cap&1 == 0 and mouse.down")
    GUI.active_element, GUI.active_element_index = get_mouse_cursor_context()
  end
  if GUI.active_element then
    ---[[
    if GUI.active_element.type ~= "edit box" and GUI.active_element.type ~= "main frame" and GUI.edit_box_has_focus then
      GUI.edit_box_has_focus = false
      Edit_boxes:set_toggle_state(false)
    end
    --]]
    GUI.active_element:handle_mouse_events(GUI.active_element_index)
  end
 
  local f_btns = GUI.elements.buttons.folder_type
  local s_btns = GUI.elements.buttons.selection_type
  
  curr_proj_id, curr_proj_file_name = EnumProjects(-1, "")
  proj_change_count = GetProjectStateChangeCount(curr_proj_id)
  
  -- if project tab has changed...
  if curr_proj_id ~= script.project_id then
    -- call "init" to create buttons from stored state for current project (if state exists) 
    -- (last_last_proj_change_count is set to proj_change_count in "init" -function)
    msg("PROJECT ID CHANGED")
    exit()
    init()
    on_track_list_change(last_action)
  -- If project tab hasn't changed but RPP-file has changed...
  elseif curr_proj_id == script.project_id and curr_proj_file_name ~= script.project_filename then
    msg("Same proj_id, filename changed")
    msg(" Old filename: " .. tostring(script.project_filename))
    msg(" New filename: " .. tostring(curr_proj_file_name))
    --exit() -- don't store buttons here
    --script.project_filename = curr_proj_file_name
    gfx.quit()
    Tracks:restore_initial_visibility_states()
    return
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
    else
      --on_track_list_change(last_action)
    end
    last_proj_change_count = proj_change_count
  end
  
  --draw_and_update_buttons(btns)
  if GUI.drag then
    _, GUI.x, GUI.y, GUI.w, GUI.h = gfx.dock(-1,0,0,0,0)
    local x, y, w, h = GUI.x, GUI.y, GUI.w, GUI.h
    --local screen_left, screen_top, screen_right, screen_bottom = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)
    if script.os == "OSX32" or script.os == "OSX64" then
      y = screen_bottom-h-y-GUI.reaper_titlebar_h -- reaper's title bar height on macOS is 22 pixels?
    else
      y = y - GUI.reaper_titlebar_h
    end
    gfx.set(1,1,1,1)
    gfx.x, gfx.y = 0, 0
    if x <= 0 and y > 0 then
      gfx.drawstr("Dock to left of main window", 1|4, gfx.w, gfx.h)
    elseif y <= 0 then
      gfx.drawstr("Dock to top of main window", 1|4, gfx.w, gfx.h)
    --elseif x + w >= screen_right and y > 0 then
    elseif x + w >= screen_right and x <= screen_right and y > 0 then
      gfx.drawstr("Dock to right of main window", 1|4, gfx.w, gfx.h)
    else
      draw_and_update_buttons()
      draw_btn_create_new()
      draw_edit_boxes()
    end
  else
    draw_and_update_buttons()
    draw_btn_create_new()
    draw_edit_boxes()
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
  -- Searchbox
  if char > 0 then
    local sb = GUI.elements.edit_boxes[1]
    if sb.toggle_state and sb.is_focused then 
      GUI.elements.edit_boxes[1]:onchar(char)
    end
  end

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

  if char == 32 and not GUI.edit_box_has_focus then reaper.Main_OnCommand(40044, 0) end -- play/stop
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
  msg("-------------------------------------------------") 
  msg("Function call: exit()")
  msg("script.project_id: " .. tostring(script.project_id))
  msg("Current project ID: " .. tostring(EnumProjects(-1, "")))
  msg("script.project_filename: " .. tostring(script.project_filename))
  msg("curr_proj_file_name: " .. tostring(curr_proj_file_name))
  
  store_btns(script.project_id)
  set_window_style("", true)
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
    reaper.MarkProjectDirty(script.project_id)
  else
    reaper.ShowConsoleMsg("Couldn't store GUI data - invalid ReaProject ID\n")
  end
  gfx.quit()
  Tracks:restore_initial_visibility_states()
end

------------------------------------------------------------
function store_state(proj_id)
  msg("Function call: store_state()")
  proj_id = proj_id or EnumProjects(-1, "")
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
    reaper.MarkProjectDirty(script.project_id)
  else
    reaper.ShowConsoleMsg("Couldn't store GUI data - invalid ReaProject ID\n")
  end
end
  
------------------------------------------------------------
function store_btns(proj_id)
  msg("Function call: store_btns(" .. tostring(script.project_id) .. ")")
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
    reaper.MarkProjectDirty(script.project_id)
  else
    reaper.ShowConsoleMsg("Couldn't store button data - invalid ReaProject ID\n")
  end
end

------------------------------------------------------------
function restore_button_states(proj_id)
  --msg("Function call: restore_button_states(proj_id)")
  local proj_id = proj_id or EnumProjects(-1, "")
  msg("Function call: restore_button_states(" .. tostring(proj_id) .. ")")
  GUI.elements.buttons = nil
  GUI.elements.buttons = {folder_type = {}, selection_type = {}}
  local button_count = 0
  --local btns = GUI.elements.buttons
  local ok, buttons = reaper.GetProjExtState(proj_id, "spk77 Track Tags", "buttons")
  if buttons ~= "" then
    buttons = unpickle(buttons)
    button_count = #buttons
    for i = 1, button_count do
      local tr_guids_table, tr_pointer_table = validate_track_guids(buttons[i].tracks)
      msg("tr_guids_table length:" .. tostring(#tr_guids_table))
      -- Create button only if it has tagged tracks
      if #tr_guids_table > 0 then
        local btn_type = buttons[i].type
        local btn = Buttons:create_new(btn_type)
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
        if btn.lbl == "" then
          btn.lbl = "Tag"
        end
        btn.lbl_w, btn.lbl_h = gfx.measurestr(btn.lbl)
        btn.toggle_state = buttons[i].toggle_state
        btn.show_only_parent = buttons[i].show_only_parent or false
        --btn:set_color_to_track_color() 
        btn:update_w_by_lbl_w()
      end
    end
  end

---[[
  msg("Button count:" .. tostring(button_count))
  if button_count > 0 then
    sort_buttons()
    --update_all_buttons_w()
    update_button_positions()
    update_buttons_color()
    update_visibility()
  end
  return button_count
--]]
end

------------------------------------------------------------

---[[
if not reaper.APIExists("JS_Window_Find") then
  reaper.ShowConsoleMsg("Missing API - JS_ReaScript extension\nCopy and paste this URL in Extensions > ReaPack > Import a repository:\nhttps://github.com/ReaTeam/Extensions/raw/master/index.xml")
else
  --reaper.atexit(exit)
  init()
  mainloop()
end
--]]






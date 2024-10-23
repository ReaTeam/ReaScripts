-- @description Lil FX Slot Homie
-- @author Sexan
-- @version 1.2.1
-- @link https://forum.cockos.com/showthread.php?p=2680992#post2680992
-- @changelog
--  Scroll to selected items if they are not in view
--  Fix ESC Clear/close script

local SLOT = 1

local r = reaper
local reaper_path = r.GetResourcePath()

local fx_browser_script_path = reaper_path .. "/Scripts/Sexan_Scripts/FX/Sexan_FX_Browser_ParserV7.lua"

function ThirdPartyDeps()
    local reapack_process
    local repos = {
        { name = "Sexan_Scripts", url = 'https://github.com/GoranKovac/ReaScripts/raw/master/index.xml' },
    }

    for i = 1, #repos do
        local retinfo, url, enabled, autoInstall = r.ReaPack_GetRepositoryInfo(repos[i].name)
        if not retinfo then
            retval, error = r.ReaPack_AddSetRepository(repos[i].name, repos[i].url, true, 0)
            reapack_process = true
        end
    end

    -- ADD NEEDED REPOSITORIES
    if reapack_process then
        --r.ShowMessageBox("Added Third-Party ReaPack Repositories", "ADDING REPACK REPOSITORIES", 0)
        r.ReaPack_ProcessQueue(true)
        reapack_process = nil
    end
end

local function CheckDeps()
    ThirdPartyDeps()
    local deps = {}

    if not r.ImGui_GetVersion then
        deps[#deps + 1] = '"Dear Imgui"'
    end
    if not r.file_exists(fx_browser_script_path) then
        deps[#deps + 1] = '"FX Browser Parser V7"'
    end
    if #deps ~= 0 then
        r.ShowMessageBox("Need Additional Packages.\nPlease Install it in next window", "MISSING DEPENDENCIES", 0)
        r.ReaPack_BrowsePackages(table.concat(deps, " OR "))
        return true
    end
end
if CheckDeps() then return end

dofile(r.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.8.7')
if r.file_exists(fx_browser_script_path) then
    dofile(fx_browser_script_path)
end

local ctx = r.ImGui_CreateContext('Lil FX Slot Homie')

local FX_LIST = ReadFXFile()

if not FX_LIST then
    FX_LIST = MakeFXFiles()
end

local function Lead_Trim_ws(s) return s:match '^%s*(.*)' end

local tsort = table.sort
function SortTable(tab, val1, val2)
    tsort(tab, function(a, b)
        if (a[val1] < b[val1]) then
            -- primary sort on position -> a before b
            return true
        elseif (a[val1] > b[val1]) then
            -- primary sort on position -> b before a
            return false
        else
            -- primary sort tied, resolve w secondary sort on rank
            return a[val2] < b[val2]
        end
    end)
end

local old_t = {}
local old_filter = ""
local function Filter_actions(filter_text)
    if old_filter == filter_text then return old_t end
    filter_text = Lead_Trim_ws(filter_text)
    local t = {}
    if filter_text == "" or not filter_text then return t end
    for i = 1, #FX_LIST do
        local name = FX_LIST[i]:lower() --:gsub("(%S+:)", "")
        local found = true
        for word in filter_text:gmatch("%S+") do
            if not name:find(word:lower(), 1, true) then
                found = false
                break
            end
        end
        if found then t[#t + 1] = { score = FX_LIST[i]:len() - filter_text:len(), name = FX_LIST[i] } end
    end
    if #t >= 2 then
        SortTable(t, "score", "name") -- Sort by key priority
    end
    old_t = t
    old_filter = filter_text
    return t
end

local function SetMinMax(Input, Min, Max)
    if Input >= Max then
        Input = Max
    elseif Input <= Min then
        Input = Min
    else
        Input = Input
    end
    return Input
end

FILTER = ''
local function AddFxToTracks(fx)
    if r.CountTracks(0) == 1 and r.CountSelectedTracks(0) == 0 then
        local track = r.GetTrack(0, 0)
        r.TrackFX_AddByName(track, fx, false, -1000 - (SLOT - 1))
        return
    end
    for t = 1, r.CountSelectedTracks(0, 0) do
        r.TrackFX_AddByName(r.GetSelectedTrack(0, t - 1), fx, false, -1000 - (SLOT - 1))
    end
end

local keys = {
    r.ImGui_Key_1(),
    r.ImGui_Key_2(),
    r.ImGui_Key_3(),
    r.ImGui_Key_4(),
    r.ImGui_Key_5(),
    r.ImGui_Key_6(),
    r.ImGui_Key_7(),
    r.ImGui_Key_8(),
    r.ImGui_Key_9(),
    r.ImGui_Key_GraveAccent(),
    r.ImGui_Key_0()
}

local function CheckKeyNumbers()
    CTRL = r.ImGui_IsKeyDown(ctx, r.ImGui_Key_LeftCtrl())
    if not CTRL then return end
    for i = 1, #keys do
        if r.ImGui_IsKeyPressed(ctx, keys[i]) then
            SLOT = i < 10 and i or 100
        end
    end
end

local function AllowChildFocus(i)
    if ALLOW_IN_LIST and not PASS_FOCUS then
        if i == 1 then
            r.ImGui_SetKeyboardFocusHere(ctx)
            PASS_FOCUS = true
        end
    end
end

function SetMinMax(Input, Min, Max)
    if Input >= Max then
        Input = Max
    elseif Input <= Min then
        Input = Min
    else
        Input = Input
    end
    return Input
end

local function scroll(pos)
    if not reaper.ImGui_IsItemVisible(ctx) then
      reaper.ImGui_SetScrollHereY(ctx,pos)
    end

end

local filter_h = 60
local MAX_FX_SIZE = 300
function FilterBox()
    CheckKeyNumbers()
    r.ImGui_SetNextWindowSize(ctx, 0, filter_h)
    if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Escape()) then
      if #FILTER == 0 then
        CLOSE = true
      else
        FOCUS = true
      end
    end
    if r.ImGui_BeginPopup(ctx, "popup") then
        r.ImGui_Text(ctx, "ADD TO SLOT : " .. (SLOT < 100 and tostring(SLOT) or "LAST"))
        r.ImGui_SameLine(ctx, 0, 20)
        if r.ImGui_Selectable(ctx, "RESCAN FX", false, 0, 65) then
            FX_LIST = MakeFXFiles()
        end
        r.ImGui_PushItemWidth(ctx, MAX_FX_SIZE)
        if r.ImGui_IsWindowAppearing(ctx) then r.ImGui_SetKeyboardFocusHere(ctx) end
        if FOCUS then
          r.ImGui_SetKeyboardFocusHere(ctx)
          FOCUS = nil
        end
        if CLOSE then
          r.ImGui_CloseCurrentPopup(ctx) 
        end
        _, FILTER = r.ImGui_InputText(ctx, '##input', FILTER) 

        local filtered_fx = Filter_actions(FILTER)
        ADDFX_Sel_Entry = SetMinMax(ADDFX_Sel_Entry or 1, 1, #filtered_fx)
        filter_h = #filtered_fx == 0 and 60 or (#filtered_fx > 40 and 20 * 17 or (17 * #filtered_fx) + 55)
        
          if r.ImGui_BeginChild(ctx, "aaaaa") then
              for i = 1, #filtered_fx do
                  r.ImGui_PushID(ctx, i)
                  if r.ImGui_Selectable(ctx, filtered_fx[i].name, i == ADDFX_Sel_Entry, nil, MAX_FX_SIZE) then
                      AddFxToTracks(filtered_fx[i].name) 
                  end 
                  r.ImGui_PopID(ctx)
                  if i == ADDFX_Sel_Entry then
                    scroll(scroll_pos)
                  end
              end
              if r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_Enter()) then
                  AddFxToTracks(filtered_fx[ADDFX_Sel_Entry].name)
                  ADDFX_Sel_Entry = nil
              elseif r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_UpArrow()) then
                  ADDFX_Sel_Entry = ADDFX_Sel_Entry - 1
              elseif r.ImGui_IsKeyPressed(ctx, r.ImGui_Key_DownArrow()) then
                  ADDFX_Sel_Entry = ADDFX_Sel_Entry + 1
              end
              r.ImGui_EndChild(ctx)
          end
       
        
        r.ImGui_EndPopup(ctx)
        r.defer(FilterBox)
    end
end

local function loop()
    r.ImGui_OpenPopup(ctx, 'popup')
    r.ImGui_SetNextWindowPos(ctx, r.ImGui_PointConvertNative(ctx, r.GetMousePosition()))
    FilterBox()
end

r.defer(loop)

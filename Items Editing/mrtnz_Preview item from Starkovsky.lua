-- @description Preview item from Starkovsky
-- @author mrtnz
-- @version 1.0
-- @provides . > mrtnz_Reverse preview item from mouse cursor (perform until shortcut released) from Starkovsky.lua
-- @screenshot https://i.imgur.com/YFmQuAq.gif
-- @about # Playback reverse from Starkovsky

local r = reaper
local reverse = true
local preview 
local data = {}
local p = debug.getinfo(1, "S").source:match [[^@?(.*[\/])[^\/]-$]]
local start_time = r.time_precise()
local key_state, KEY = r.JS_VKeys_GetState(start_time - 2), nil

r.BR_GetMouseCursorContext()

local function get_item_under_mouse()
    local _, _, details = r.BR_GetMouseCursorContext()
    if details == "item" then
        return r.BR_GetMouseCursorContext_Item()
    end
    return nil
end

local function main()
    local item = get_item_under_mouse()
    if not item then
        --r.ShowConsoleMsg(getLocalizedMessage("item_not_found"))
        return nil
    end

    local take = r.GetActiveTake(item)
    if not take then
        --r.ShowConsoleMsg(getLocalizedMessage("active_take_failed"))
        return nil
    end

    local track = r.GetMediaItem_Track(item)
    if not track then
        --r.ShowConsoleMsg(getLocalizedMessage("track_failed"))
        return nil
    end

    -- Получаем различные параметры айтема
    local item_info = {
        track = track,
        playrate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE"),
        volume = r.GetMediaItemInfo_Value(item, "D_VOL"),
        bppitch = r.GetMediaItemInfo_Value(item, "B_PPITCH"),
        pitch = r.GetMediaItemTakeInfo_Value(take, "D_PITCH"),
        ipitchmode = r.GetMediaItemInfo_Value(item, "I_PITCHMODE"),
        take_offset = r.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS"),
        length = r.GetMediaItemInfo_Value(item, "D_LENGTH"),
        item_start = r.GetMediaItemInfo_Value(item, "D_POSITION"),
        item = item
    }

    local take_source = r.GetMediaItemTake_Source(take)
    if not take_source then
        --r.ShowConsoleMsg(getLocalizedMessage("take_source_failed"))
        return nil
    end
    item_info.take_file_path = r.GetMediaSourceFileName(take_source, "")

    item_info.cursor_pos = r.BR_GetMouseCursorContext_Position()
    local source_length = r.GetMediaSourceLength(take_source) / item_info.playrate
    local preview_area = math.abs((item_info.cursor_pos - item_info.item_start))
    item_info.end_length = (source_length - preview_area) - item_info.take_offset / item_info.playrate

    return item_info
end

local function createPreview(item_info, reverse)
    local source = r.PCM_Source_CreateFromFile(item_info.take_file_path)
    if not source then
        --r.ShowConsoleMsg(getLocalizedMessage("pcm_source_failed"))
        return nil
    end

    if reverse then
        local section = r.PCM_Source_CreateFromType('SECTION')
        if not section then
            --r.ShowConsoleMsg(getLocalizedMessage("pcm_section_failed"))
            r.PCM_Source_Destroy(source)
            return nil
        end
        r.CF_PCM_Source_SetSectionInfo(section, source, 0, 0, true)
        r.PCM_Source_Destroy(source)
        source = section
    end

    local preview = r.CF_CreatePreview(source)
    if not preview then
        --r.ShowConsoleMsg(getLocalizedMessage("preview_failed"))
        r.PCM_Source_Destroy(source)
        return nil
    end

    local preview_settings = {
        {'D_POSITION', item_info.end_length},
        {'D_VOLUME', item_info.volume},
        {'D_PLAYRATE', item_info.playrate},
        {'D_PITCH', item_info.pitch},
        {'I_PITCHMODE', item_info.ipitchmode},
        {'B_LOOP', 0}
    }

    for _, setting in ipairs(preview_settings) do
        r.CF_Preview_SetValue(preview, setting[1], setting[2])
    end

    r.CF_Preview_SetOutputTrack(preview, r.EnumProjects(-1), item_info.track)
    r.CF_Preview_Play(preview)
    
    -- Уничтожаем источник, чтобы освободить память
    r.PCM_Source_Destroy(source)

    return preview
end

local function PrintTraceback(err)
    local byLine = "([^\r\n]*)\r?\n?"
    local trimPath = "[\\/]([^\\/]-:%d+:.+)$"
    local stack = {}
    for line in string.gmatch(err, byLine) do
        local str = string.match(line, trimPath) or line
        stack[#stack + 1] = str
    end
    r.ShowConsoleMsg(
        "Error: " .. stack[1] .. "\n\n" ..
        "Stack traceback:\n\t" .. table.concat(stack, "\n\t", 3) .. "\n\n" ..
        "Reaper:       \t" .. r.GetAppVersion() .. "\n" ..
        "Platform:     \t" .. r.GetOS()
    )
end

local function Release()
    if data and data.is_track_solo == 0.0 then
        r.SetMediaTrackInfo_Value(data.track, "I_SOLO", 0)
    end
    --r.JS_Mouse_SetCursor(r.JS_Mouse_LoadCursor(32512))
    if original_edit_cursor_pos then
        r.SetEditCurPos(original_edit_cursor_pos, false, false)
    end
    r.JS_VKeys_Intercept(KEY, -1)
    r.CF_Preview_StopAll()
end

local function PDefer(func)
    r.defer(function()
        local status, err = xpcall(func, debug.traceback)
        if not status then
            PrintTraceback(err)
            Release() -- Очистка ресурсов
        end
    end)
end

for i = 1, 255 do
    if key_state:byte(i) ~= 0 then
        KEY = i
        r.JS_VKeys_Intercept(KEY, 1)
        break
    end
end
if not KEY then return end

local function Key_held()
    key_state = r.JS_VKeys_GetState(start_time - 2)
    return key_state:byte(KEY) == 1
end

local function CheckPreview(preview)
    if not Key_held() then return end
    if preview then
        local _, _, position = pcall(r.CF_Preview_GetValue, preview, 'D_POSITION')
        local success, length = pcall(select, 2, r.CF_Preview_GetValue(preview, 'D_LENGTH'))
        
        if success then
            -- Ограничиваем значение edit_cursor_value, чтобы оно не могло быть меньше data.item_start
            local edit_cursor_value = math.max(data.item_start, data.item_start + (length - position) - data.take_offset / data.playrate)
            r.SetEditCurPos(edit_cursor_value, false, false)
            --local cursor = r.JS_Mouse_LoadCursorFromFile(p..'/speaker.cur')
            --r.JS_Mouse_SetCursor(cursor)
            if edit_cursor_value <= data.item_start then
                r.CF_Preview_StopAll()
                return
            end
        else
            --r.ShowConsoleMsg("error value\n")
        end
        
    end
    PDefer(function() CheckPreview(preview) end)
end

local function Main()
    if not Key_held() then return end
    if not main_executed then
        main_executed = true
        original_edit_cursor_pos = r.GetCursorPosition()

        data = main(reverse)
        if not data then return end
        data.is_track_solo = r.GetMediaTrackInfo_Value(data.track, "I_SOLO")
            
        if data.is_track_solo == 0.0 then
            r.SetMediaTrackInfo_Value(data.track, "I_SOLO", 1)
        end

        
        r.CF_Preview_StopAll()

        r.BR_GetMouseCursorContext()
        r.SetEditCurPos(r.BR_GetMouseCursorContext_Position(), false, false)

        preview = createPreview(data, reverse)
        if not preview then return end
        

        CheckPreview(preview)
    end
    PDefer(Main)
end


PDefer(Main)
r.atexit(Release)

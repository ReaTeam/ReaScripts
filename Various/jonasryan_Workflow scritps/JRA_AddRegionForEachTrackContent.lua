-- @noindex


-- MAIN STUFF

local function add_regions(individual, addToRender)
    local numTracks = reaper.GetNumTracks()

    for i = 0, numTracks - 1 do
        local track = reaper.GetTrack(0, i)
        local numTrackItems = reaper.GetTrackNumMediaItems(track)

        if numTrackItems > 0 then
            -- first item
            local startItem = reaper.GetTrackMediaItem(track, 0)
            local posStart = reaper.GetMediaItemInfo_Value(startItem, "D_POSITION")

            -- last item
            local endItem = reaper.GetTrackMediaItem(track, numTrackItems - 1)
            local posEnd = reaper.GetMediaItemInfo_Value(endItem, "D_POSITION")
                         + reaper.GetMediaItemInfo_Value(endItem, "D_LENGTH")

            -- create region
            local regionID = reaper.AddProjectMarker(0, true, posStart, posEnd, "", -1)

            if addToRender == true then
                -- region render matrix:
                if individual == true then
                    -- track-specific rendering
                    reaper.SetRegionRenderMatrix(0, regionID, track, 1)
                else
                    -- master track
                    local master = reaper.GetMasterTrack(0)
                    reaper.SetRegionRenderMatrix(0, regionID, master, 1)
                end
            end
        end
    end
end

-- GUI SYSTEM

-- window
local win_w, win_h = 550, 200
local btn_w, btn_h = 180, 40

-- button
local btn1_label = "Create Regions"
local btn_pos_x, btn_pos_y = 30, 120
local btn1_down = false

-- checkbox 1 (individual mode)
local cb_across_tracks = false
local cb_x, cb_y = 30, 70
local cb_size = 20

-- checkbox 2 (future feature)
local cb_add_to_render = true
local cb2_x, cb2_y = 30, 40

-- checkbox drawing
local function draw_checkbox()
    -- checkbox 1
    gfx.set(0.9, 0.9, 0.9, 1)
    gfx.rect(cb_x, cb_y, cb_size, cb_size, 0)
    if cb_across_tracks then
        gfx.set(0.2, 0.8, 0.2, 1)
        gfx.rect(cb_x + 4, cb_y + 4, cb_size - 8, cb_size - 8, 1)
    end
    gfx.set(1, 1, 1, 1)
    gfx.x, gfx.y = cb_x + cb_size + 8, cb_y + 2
    gfx.drawstr("Render matrix: [x] = Individual tracks, [ ] = via master")

    -- checkbox 2
    gfx.set(0.9, 0.9, 0.9, 1)
    gfx.rect(cb2_x, cb2_y, cb_size, cb_size, 0)
    if cb_add_to_render then
        gfx.set(0.2, 0.8, 0.2, 1)
        gfx.rect(cb2_x + 4, cb2_y + 4, cb_size - 8, cb_size - 8, 1)
    end
    gfx.set(1, 1, 1, 1)
    gfx.x, gfx.y = cb2_x + cb_size + 8, cb2_y + 2
    gfx.drawstr("Add reagions to Render Matrix")
end

-- checkbox input
local function handle_checkbox(mx, my, mouse_click)
    if mouse_click then
        -- checkbox 1
        if mx >= cb_x and mx <= cb_x + cb_size
        and my >= cb_y and my <= cb_y + cb_size then
            cb_across_tracks = not cb_across_tracks
        end

        -- checkbox 2
        if mx >= cb2_x and mx <= cb2_x + cb_size
        and my >= cb2_y and my <= cb2_y + cb_size then
            cb_add_to_render = not cb_add_to_render
        end
    end
end

-- GUI LOOP

local prev_lb = 0

local function gui_loop()
    local mx, my = gfx.mouse_x, gfx.mouse_y
    local lb = gfx.mouse_cap & 1
    local mouse_click = (lb == 1 and prev_lb == 0)
    prev_lb = lb

    -- header
    gfx.set(1, 1, 1, 1)
    gfx.x, gfx.y = 30, 5
    gfx.drawstr("Region Maker")

    -- button background
    gfx.set(0.7, 0.7, 0.7, 1)
    gfx.rect(btn_pos_x, btn_pos_y, btn_w, btn_h, 1)

    -- button label
    gfx.set(0, 0, 0, 1)
    gfx.x, gfx.y = btn_pos_x + 10, btn_pos_y + 10
    gfx.drawstr(btn1_label)

    -- button logic
    if mx >= btn_pos_x and mx <= btn_pos_x + btn_w
    and my >= btn_pos_y and my <= btn_pos_y + btn_h then
        if lb == 1 and not btn1_down then
            btn1_down = true

            -- RUN CORE FUNCTION
            reaper.Undo_BeginBlock()
            add_regions(cb_across_tracks, cb_add_to_render)
            reaper.Undo_EndBlock("Make regions for each track", -1)

        elseif lb == 0 then
            btn1_down = false
        end
    end

    -- checkboxes
    handle_checkbox(mx, my, mouse_click)
    draw_checkbox()

    gfx.update()
    if gfx.getchar() >= 0 then
        reaper.defer(gui_loop)
    end
end

gfx.init("Region Maker", win_w, win_h)
gui_loop()

